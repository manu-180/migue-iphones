import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { MercadoPagoConfig, Payment } from 'npm:mercadopago';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.8';

const corsHeaders = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type' };

// CONFIGURACIÓN ENVIA.COM (Origen Fijo - Tu local)
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

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, 
  { auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false } }
);

const client = new MercadoPagoConfig({ accessToken: Deno.env.get('MP_ACCESS_TOKEN') || '' });

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const body = await req.json();
    const { transaction_amount, token, description, payment_method_id, issuer_id, external_reference, installments, payer } = body;
    const payerEmail = payer?.email || body.email || 'unknown@email.com';
    
    // 1. PROCESAR PAGO EN MERCADO PAGO
    console.log(`💳 Procesando pago para orden: ${external_reference}`);
    const payment = new Payment(client);
    
    const paymentData = {
      transaction_amount: Number(transaction_amount),
      token: token,
      description: description || 'Compra en Migue iPhones',
      installments: Number(installments),
      payment_method_id: payment_method_id,
      issuer_id: issuer_id,
      payer: { email: payerEmail },
      external_reference: external_reference,
    };

    const result = await payment.create({ body: paymentData });
    const isApproved = result.status === 'approved';
    console.log(`Result MP: ${result.status} | ID: ${result.id}`);

    let labelData = { tracking_number: null, label_url: null };

    // 2. SI ESTÁ APROBADO -> GENERAR TICKET DE ENVÍO
    if (isApproved && external_reference) {
      
      // A. Buscar datos de envío en la BD
      const { data: orderData, error: dbError } = await supabase
        .from('orders') // IMPORTANTE: Tabla corregida a 'orders'
        .select('*')
        .eq('id', external_reference)
        .single();

      if (!dbError && orderData && orderData.delivery_type === 'envio') {
        console.log("🚚 Generando etiqueta en Envia.com...");
        
        try {
          const ticket = await generateEnviaLabel(orderData);
          if (ticket) {
            labelData = ticket;
            console.log(`✅ Ticket Generado: ${ticket.tracking_number}`);
          }
        } catch (shippingError) {
          console.error("❌ Error generando ticket:", shippingError);
          // No fallamos el pago si falla el envío, pero lo logueamos.
        }
      }
    }

    // 3. ACTUALIZAR BASE DE DATOS
    if (external_reference) {
        await supabase.from('orders').update({
          status: result.status, // approved, rejected, etc
          mp_payment_id: Number(result.id),
          tracking_number: labelData.tracking_number,
          label_url: labelData.label_url
        }).eq('id', external_reference);
    }

    // 4. RESPONDER AL FRONTEND
    return new Response(JSON.stringify({ 
      status: result.status, 
      id: result.id,
      ticket: labelData 
    }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 });

  } catch (error) {
    console.error("Critical Error:", error);
    return new Response(JSON.stringify({ error: error.message }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 });
  }
});

// --- FUNCIÓN AUXILIAR PARA LLAMAR A ENVIA.COM ---
async function generateEnviaLabel(order: any) {
  const enviaToken = Deno.env.get('ENVIA_ACCESS_TOKEN');
  
  // Mapeo simple de carriers (ajustar según lo que devuelve tu calculador)
  let carrierName = "correo-argentino"; 
  if (order.carrier_slug && order.carrier_slug.includes('andreani')) carrierName = "andreani";

  // Payload para Envia
  const shippingBody = {
    origin: ORIGIN_DATA,
    destination: {
      name: "Cliente Migue iPhones", // Podrías guardar el nombre en la orden también
      email: order.payer_email,
      phone: "1100000000", // Idealmente pedir teléfono en checkout
      street: order.shipping_address.street_name || order.shipping_address.street,
      number: order.shipping_address.street_number || order.shipping_address.number || "0",
      district: order.shipping_address.city, // A veces district es barrio
      city: order.shipping_address.city,
      state: order.shipping_address.state_code || "DF", // Necesitas asegurar el código de provincia
      country: "AR",
      postalCode: order.shipping_address.zip_code || order.shipping_address.zipCode
    },
    packages: [{
      content: "Celular/Accesorio",
      amount: 1,
      type: "box",
      dimensions: { length: 15, width: 10, height: 5 },
      weight: 0.5,
      weightUnit: "KG", lengthUnit: "CM"
    }],
    shipment: {
      carrier: carrierName,
      service: "standard", // O mapping según order.service_level
      type: 1
    }
  };

  const res = await fetch('https://api.envia.com/ship/generate/', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${enviaToken}` },
    body: JSON.stringify(shippingBody)
  });

  const data = await res.json();
  
  if (data.meta === 'generate') {
    return {
      tracking_number: data.data[0].trackingNumber,
      label_url: data.data[0].label
    };
  } else {
    console.error("Envia Error Response:", JSON.stringify(data));
    return null;
  }
}