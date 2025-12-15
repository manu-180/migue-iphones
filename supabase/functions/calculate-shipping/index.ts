// supabase/functions/calculate-shipping/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type' };

const ORIGIN_DATA = {
  name: "MNL Tecno", 
  company: "MNL Tecno",
  phone: "5491134272488",      
  street: "Av. Cabildo",      
  number: "2040",             
  district: "Belgrano",        
  city: "Ciudad Autónoma de Buenos Aires",
  state: "DF", 
  country: "AR",
  postalCode: "1428"           
};

const DEFAULT_PARCEL = { content: "Productos Varios", amount: 1, type: "box", dimensions: { length: 15, width: 10, height: 5 }, weight: 0.5, weightUnit: "KG", lengthUnit: "CM" };

function mapStateCode(stateName: string) {
  if (!stateName) return "B"; 
  const lower = stateName.toLowerCase();
  if (lower.includes("capital") || lower.includes("caba") || lower.includes("autonoma")) return "DF"; 
  if (lower.includes("buenos aires")) return "BA";
  return stateName; 
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { zipCode, city, state, weight } = await req.json();
    
    if (!zipCode) throw new Error("Falta el Código Postal");
    if (!city) throw new Error("Falta la Ciudad");

    const finalWeight = weight && weight > 0 ? Number(weight) : 0.5;
    const finalDestState = mapStateCode(state || "Buenos Aires");
    
    console.log(`🚚 Cotizando CP: ${zipCode}, Ciudad: ${city}, Peso: ${finalWeight}`);
    
    const enviaToken = Deno.env.get('ENVIA_ACCESS_TOKEN');
    const carriers = ['andreani', 'correoArgentino'];
    let rawRates: any[] = [];

    // --- TRADUCTOR MAESTRO (ORDEN CORREGIDO) ---
    const formatServiceName = (rawName: string) => {
        const lower = rawName.toLowerCase();
        
        // 1. PRIORIDAD ABSOLUTA: SUCURSAL
        // Detecta "sucursal", "branch", o códigos técnicos como "standard_suc"
        if (lower.includes('sucursal') || lower.includes('branch') || lower.includes('_suc')) {
             return 'Retiro en Sucursal';
        }

        // 2. PRIORIDAD MEDIA: RÁPIDOS
        if (lower.includes('prioritario') || lower.includes('priority') || lower.includes('urgente')) {
             return 'Prioritario a Domicilio';
        }

        // 3. RESTO: ESTÁNDAR A DOMICILIO
        // Aquí caen "standard", "ground", "clasico", "paq.ar" (si no es sucursal)
        return 'Estándar a Domicilio';
    };

    const estimateDays = (serviceName: string, apiMin: any, apiMax: any) => {
        if (apiMin && apiMax) return { min: apiMin, max: apiMax };
        const lower = serviceName.toLowerCase();
        if (lower.includes('prioritario')) return { min: 1, max: 3 };
        if (lower.includes('sucursal')) return { min: 2, max: 4 };
        return { min: 3, max: 6 };
    };

    const addRate = (carrierName: string, serviceObj: any) => {
        if (!serviceObj || typeof serviceObj.totalPrice === 'undefined') return;

        let rawName = serviceObj.description || serviceObj.service || serviceObj.name || "";
        let prettyName = formatServiceName(rawName);
        let days = estimateDays(prettyName, serviceObj.deliveryEstimate?.min, serviceObj.deliveryEstimate?.max);

        rawRates.push({
            carrier_name: carrierName === 'correoArgentino' ? 'Correo Argentino' : 'Andreani',
            service_level: prettyName,
            total_price: serviceObj.totalPrice,
            min_days: days.min,
            max_days: days.max
        });
    };

    const dynamicPackage = { 
        content: "Accesorios Celular", 
        amount: 1, type: "box", dimensions: { length: 15, width: 10, height: 5 }, 
        weight: finalWeight, weightUnit: "KG", lengthUnit: "CM" 
    };

    const promises = carriers.map(async (carrier) => {
        const body = {
          origin: ORIGIN_DATA,
          destination: { country: "AR", postalCode: zipCode, city: city, state: finalDestState },
          packages: [dynamicPackage],
          shipment: { carrier: carrier, type: 1 }
        };

        try {
            const res = await fetch('https://api.envia.com/ship/rate/', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${enviaToken}` },
                body: JSON.stringify(body)
            });
            const rawText = await res.text();
            let data; try { data = JSON.parse(rawText); } catch(e) { return; }
            
            // MANEJO DE ERROR DE DIRECCIÓN
            if (data.meta === 'error') {
                const errorMsg = data.error?.message?.toLowerCase() || "";
                // Si el error menciona "postal code" o "city", es un error de validación
                if (errorMsg.includes("postal") || errorMsg.includes("city") || errorMsg.includes("service")) {
                    console.warn(`⚠️ Error validación dirección (${carrier}):`, errorMsg);
                    // No lanzamos error global todavía, probamos el otro carrier.
                    // Pero si ambos fallan, el array 'rates' quedará vacío.
                }
                return;
            }

            let itemsToIterate = [];
            if (Array.isArray(data.data)) itemsToIterate = data.data;
            else if (data.data) itemsToIterate = [data.data];

            for (const item of itemsToIterate) {
                if (item.services && Array.isArray(item.services)) {
                    for (const service of item.services) addRate(carrier, service);
                } else if (item.totalPrice !== undefined) {
                    addRate(carrier, item);
                }
            }
        } catch (err) { console.error(err); }
    });

    await Promise.all(promises);

    // DEDUPLICACIÓN
    const uniqueRatesMap = new Map();
    for (const rate of rawRates) {
        const key = `${rate.carrier_name}-${rate.service_level}`;
        if (!uniqueRatesMap.has(key)) {
            uniqueRatesMap.set(key, rate);
        } else {
            const existing = uniqueRatesMap.get(key);
            if (rate.total_price < existing.total_price) uniqueRatesMap.set(key, rate);
        }
    }
    
    const finalRates = Array.from(uniqueRatesMap.values());
    finalRates.sort((a: any, b: any) => a.total_price - b.total_price);

    // Si no encontramos nada, puede ser error de dirección
    if (finalRates.length === 0) {
        // Devolvemos lista vacía, el Frontend mostrará el mensaje de error personalizado
        return new Response(JSON.stringify([]), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    console.log(`✅ Enviando ${finalRates.length} tarifas.`);
    return new Response(JSON.stringify(finalRates), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: corsHeaders });
  }
});