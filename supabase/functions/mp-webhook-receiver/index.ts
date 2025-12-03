// supabase/functions/mp-webhook-receiver/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.8';

const corsHeaders = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type' };

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

// Función para convertir la provincia del Dropdown al código de Envia
function getStateCode(stateName: string) {
  if (!stateName) return "B"; // Default Provincia
  const lower = stateName.toLowerCase();
  if (lower.includes("capital") || lower.includes("caba")) return "C"; // Capital Federal
  return "B"; // Todo lo demás en este ejemplo lo tratamos como Provincia BsAs (simplificado para prueba)
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  console.log("🔔 [Webhook] RECIBIDO");

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

    const mpAccessToken = Deno.env.get('MP_ACCESS_TOKEN');
    const mpResponse = await fetch(`https://api.mercadopago.com/v1/payments/${paymentId}`, {
      headers: { 'Authorization': `Bearer ${mpAccessToken}` }
    });

    if (!mpResponse.ok) return new Response(JSON.stringify({ error: 'Invalid ID MP' }), { status: 200 });

    const paymentDetails = await mpResponse.json();
    const newStatus = paymentDetails.status;
    const externalReference = paymentDetails.external_reference;

    if (!externalReference) return new Response(JSON.stringify({ message: 'No Ref' }), { status: 200 });

    // Actualizar DB
    const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

    const { data: orderData, error: updateError } = await supabase
      .from('orders_pulpiprint')
      .update({ status: newStatus, mp_payment_id: Number(paymentId) })
      .eq('id', externalReference)
      .select()
      .single();

    if (updateError) throw new Error("DB Error");

    const needsShipping = newStatus === 'approved' && orderData.delivery_type === 'envio' && !orderData.tracking_number;
    
    if (needsShipping) {
      console.log("🚚 Generando etiqueta (Datos Estructurados)...");
      const enviaToken = Deno.env.get('ENVIA_ACCESS_TOKEN'); 
      
      const addr = orderData.shipping_address || {};
      
      // DATOS LIMPIOS DEL FRONTEND
      const street = addr.street_name || "Calle Desconocida";
      const number = addr.street_number || "0";
      const city = addr.city || "Buenos Aires";
      const stateCode = getStateCode(addr.state);
      const zip = addr.zip_code || "1000";

      const destName = orderData.payer_email ? orderData.payer_email.split('@')[0] : "Cliente";

      const shippingBody = {
        origin: ORIGIN_DATA,
        destination: {
          name: destName,
          email: orderData.payer_email || "email@unknown.com",
          phone: "5491100000000",
          street: street,
          number: number,
          district: city, // En Argentina, District suele ser el Barrio/Localidad
          city: city,     // City el Partido/Departamento
          state: stateCode,
          country: "AR",
          postalCode: zip
        },
        packages: [PARCEL_DATA],
        shipment: { 
            carrier: "andreani", 
            service: "standard", 
            type: 1 
        },
        settings: { 
            currency: "ARS", 
            labelFormat: "pdf", 
            printFormat: "PDF", 
            printSize: "STOCK_4X6"
        }
      };

      console.log("📤 Payload Limpio:", JSON.stringify(shippingBody));

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
        console.log(`🎉 TRACKING: ${trackingNumber}`);
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