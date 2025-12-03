import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.8';

const corsHeaders = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type' };

// DATOS DE ORIGEN (Tus datos reales)
const ORIGIN_DATA = {
  name: "Manuel Navarro", 
  company: "MNL Tecno",
  email: "manunv97@gmail.com", 
  phone: "5491134272488",     
  street: "Av. Cabildo",      
  number: "2040",             
  district: "Belgrano",       
  city: "Ciudad Autónoma de Buenos Aires",
  state: "C",                 
  country: "AR",
  postalCode: "1428"          
};

const PARCEL_DATA = { content: "Accesorios", amount: 1, type: "box", dimensions: { length: 15, width: 10, height: 5 }, weight: 0.5 };

// Helper simple para código de provincia
function getStateCode(stateName: string) {
  if (!stateName) return "B"; 
  const lower = stateName.toLowerCase();
  if (lower.includes("capital") || lower.includes("caba") || lower.includes("autonoma")) return "C"; 
  return "B"; 
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  console.log("🔔 [Webhook PROD] Recibido");

  try {
    const url = new URL(req.url);
    let paymentId = url.searchParams.get('id') || url.searchParams.get('data.id');
    
    if (!paymentId) {
       try {
        const rawBody = await req.text();
        if (rawBody) {
          const payload = JSON.parse(rawBody);
          paymentId = payload.data?.id || payload.id;
        }
      } catch (e) { }
    }

    if (!paymentId) return new Response(JSON.stringify({ message: 'Ignored' }), { status: 200 });

    // 2. Verificar MP
    const mpAccessToken = Deno.env.get('MP_ACCESS_TOKEN');
    const mpResponse = await fetch(`https://api.mercadopago.com/v1/payments/${paymentId}`, {
      headers: { 'Authorization': `Bearer ${mpAccessToken}` }
    });

    if (!mpResponse.ok) return new Response(JSON.stringify({ error: 'Invalid ID MP' }), { status: 200 }); 

    const paymentDetails = await mpResponse.json();
    const newStatus = paymentDetails.status;
    const externalReference = paymentDetails.external_reference;

    console.log(`ℹ️ Pago: ${paymentId} | Estado: ${newStatus} | Ref: ${externalReference}`);

    if (!externalReference) return new Response(JSON.stringify({ message: 'No Ref' }), { status: 200 });

    // 3. Actualizar DB
    const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

    const { data: orderData, error: updateError } = await supabase
      .from('orders_pulpiprint')
      .update({ status: newStatus, mp_payment_id: Number(paymentId) })
      .eq('id', externalReference)
      .select()
      .single();

    if (updateError) throw new Error("DB Error");

    // 4. GENERAR ETIQUETA REAL (Solo si es envio y no tiene tracking)
    const needsShipping = newStatus === 'approved' && orderData.delivery_type === 'envio' && !orderData.tracking_number;
    
    if (needsShipping) {
      console.log("🚚 Generando etiqueta REAL...");
      const enviaToken = Deno.env.get('ENVIA_ACCESS_TOKEN'); 
      
      const addr = orderData.shipping_address || {};
      const destName = orderData.payer_email ? orderData.payer_email.split('@')[0] : "Cliente";
      
      // AQUI USAMOS TUS CAMPOS LIMPIOS DE FLUTTER
      const shippingBody = {
        origin: ORIGIN_DATA,
        destination: {
          name: destName,
          email: orderData.payer_email || "email@unknown.com",
          phone: "5491100000000",
          street: addr.street_name || addr.address || "Calle Desconocida", 
          number: addr.street_number || "0", // Número separado
          district: addr.city || "Buenos Aires",
          city: addr.city || "Buenos Aires",
          state: getStateCode(addr.state || "Buenos Aires"), 
          country: "AR",
          postalCode: addr.zip_code || "1000"
        },
        packages: [PARCEL_DATA],
        // Usamos ANDREANI que es robusto
        shipment: { carrier: "andreani", service: "standard", type: 1 },
        settings: { currency: "ARS", labelFormat: "pdf", printFormat: "PDF", printSize: "STOCK_4X6" }
      };

      console.log("📤 Payload:", JSON.stringify(shippingBody));

      // URL DE PRODUCCIÓN
      const enviaRes = await fetch('https://api.envia.com/ship/generate/', { 
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${enviaToken}` },
        body: JSON.stringify(shippingBody)
      });

      const enviaRawText = await enviaRes.text();
      console.log(`📥 Respuesta Envia: ${enviaRawText}`);

      let enviaData;
      try { enviaData = JSON.parse(enviaRawText); } catch(e) { }

      if (enviaData && enviaData.meta === 'generate') {
        const trackingNumber = enviaData.data[0].trackingNumber;
        console.log(`🎉 TRACKING CREADO: ${trackingNumber}`);
        await supabase.from('orders_pulpiprint').update({ tracking_number: trackingNumber }).eq('id', externalReference);
      } else {
        console.error("❌ Falló Envia");
      }
    }

    return new Response(JSON.stringify({ message: 'OK' }), { status: 200, headers: corsHeaders });

  } catch (error) {
    console.error('💥 CRASH:', error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: corsHeaders });
  }
});