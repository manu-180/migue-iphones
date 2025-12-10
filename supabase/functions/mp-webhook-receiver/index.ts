// supabase/functions/mp-webhook-receiver/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.8';

const corsHeaders = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type' };

const SENDER_EMAIL = "soporte@assistify.lat"; 
const BRAND_COLOR = "#000000"; // Negro elegante estilo Apple/MNL

// --- DATOS FIJOS ---
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

const PARCEL_DATA = { content: "Accesorios", amount: 1, type: "box", dimensions: { length: 15, width: 10, height: 5 }, weight: 0.5, weightUnit: "KG", lengthUnit: "CM" };

// --- HELPERS ---
function getStateCode(stateName: string) {
  if (!stateName) return "B"; 
  const lower = stateName.toLowerCase();
  if (lower.includes("capital") || lower.includes("caba") || lower.includes("autonoma")) return "C"; 
  return "B"; 
}

// --- GENERADOR DE HTML PROFESIONAL ---
function generateHtmlEmail(orderData: any, paymentId: string, trackingNumber: string | null, carrier: string | null) {
  const itemsHtml = orderData.order_items.map((item: any) => `
    <tr>
      <td style="padding: 12px 0; border-bottom: 1px solid #eeeeee;">
        <span style="font-weight: 600; font-size: 14px; color: #333;">${item.title || item.name}</span>
        <div style="font-size: 12px; color: #888;">Cant: ${item.quantity}</div>
      </td>
      <td style="padding: 12px 0; border-bottom: 1px solid #eeeeee; text-align: right;">
        <span style="font-weight: 600; font-size: 14px; color: #333;">$${item.price}</span>
      </td>
    </tr>
  `).join('');

  // Lógica de Link de Rastreo
  let trackingHtml = '';
  if (trackingNumber) {
    let trackUrl = `https://envia.com/rastreo?label=${trackingNumber}&cntry_code=ar`;
    let carrierName = "Correo";
    
    if (carrier && carrier.toLowerCase().includes('andreani')) {
       trackUrl = `https://www.andreani.com/#!/informacionEnvio/${trackingNumber}`;
       carrierName = "Andreani";
    } else {
       carrierName = "Correo Argentino";
    }

    trackingHtml = `
      <div style="background-color: #f9f9f9; border-radius: 8px; padding: 20px; text-align: center; margin: 25px 0;">
        <p style="margin: 0 0 10px 0; font-size: 14px; color: #666;">Tu paquete ya tiene etiqueta asignada (${carrierName})</p>
        <a href="${trackUrl}" target="_blank" style="display: inline-block; padding: 12px 24px; background-color: ${BRAND_COLOR}; color: #ffffff; text-decoration: none; border-radius: 6px; font-weight: bold; font-size: 14px;">
          SEGUIR ENVÍO
        </a>
        <p style="margin: 10px 0 0 0; font-size: 11px; color: #999;">Tracking: ${trackingNumber}</p>
      </div>
    `;
  } else {
    trackingHtml = `
      <div style="background-color: #fff8e1; border-radius: 8px; padding: 15px; text-align: center; margin: 25px 0;">
        <p style="margin: 0; font-size: 13px; color: #f57f17;">Estamos preparando tu envío. Recibirás el tracking en breve.</p>
      </div>
    `;
  }

  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }</style>
    </head>
    <body style="margin: 0; padding: 0; background-color: #f4f4f4;">
      <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; padding: 40px; border-radius: 8px; margin-top: 20px; box-shadow: 0 4px 6px rgba(0,0,0,0.05);">
        
        <div style="text-align: center; margin-bottom: 30px;">
          <h1 style="margin: 0; font-size: 24px; font-weight: 800; letter-spacing: -1px;">MNL Tecno</h1>
          <p style="color: #888; font-size: 14px; margin-top: 5px;">Confirmación de Compra</p>
        </div>

        <p style="font-size: 16px; line-height: 1.5; color: #333;">Hola,</p>
        <p style="font-size: 16px; line-height: 1.5; color: #555;">
          ¡Gracias por tu compra! Tu pago ha sido aprobado correctamente. Aquí tienes los detalles de tu pedido.
        </p>

        ${trackingHtml}

        <table style="width: 100%; border-collapse: collapse; margin-top: 20px;">
          <thead>
            <tr>
              <th style="text-align: left; font-size: 12px; text-transform: uppercase; color: #999; padding-bottom: 10px; border-bottom: 2px solid #eee;">Producto</th>
              <th style="text-align: right; font-size: 12px; text-transform: uppercase; color: #999; padding-bottom: 10px; border-bottom: 2px solid #eee;">Precio</th>
            </tr>
          </thead>
          <tbody>
            ${itemsHtml}
          </tbody>
          <tfoot>
            <tr>
              <td style="padding-top: 15px; text-align: right; font-weight: bold; color: #333;">Total Pagado:</td>
              <td style="padding-top: 15px; text-align: right; font-weight: bold; font-size: 18px; color: #333;">$${orderData.total_amount}</td>
            </tr>
          </tfoot>
        </table>

        <div style="margin-top: 40px; border-top: 1px solid #eee; padding-top: 20px; text-align: center; color: #aaa; font-size: 12px;">
          <p>ID de Pago: ${paymentId}</p>
          <p>Si tienes dudas, responde a este correo.</p>
          <p>&copy; 2025 MNL Tecno. Todos los derechos reservados.</p>
        </div>

      </div>
    </body>
    </html>
  `;
}

// --- FUNCIÓN DE ENVÍO ---
async function sendOrderEmail(orderData: any, paymentId: string, trackingNumber: string | null, carrierSlug: string | null) {
  console.log("📧 Enviando Email Profesional...");
  const apiKey = Deno.env.get('RESEND_API_KEY');

  if (!apiKey) return;

  const htmlContent = generateHtmlEmail(orderData, paymentId, trackingNumber, carrierSlug);

  try {
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${apiKey}` },
      body: JSON.stringify({
        from: `MNL Tecno <${SENDER_EMAIL}>`,
        to: [orderData.payer_email], 
        subject: `Tu pedido #${orderData.id.toString().substring(0,8).toUpperCase()} está confirmado`,
        html: htmlContent
      })
    });
    console.log("✅ Email enviado:", await res.json());
  } catch (error) {
    console.error("💥 Error Email:", error);
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  console.log("🔔 [Webhook PROD] Recibido");

  try {
    const url = new URL(req.url);
    let paymentId = url.searchParams.get('id') || url.searchParams.get('data.id');
    if (!paymentId) { try { const rawBody = await req.text(); if (rawBody) { const payload = JSON.parse(rawBody); paymentId = payload.data?.id || payload.id; } } catch (e) { } }
    if (!paymentId) return new Response(JSON.stringify({ message: 'Ignored' }), { status: 200 });

    const mpAccessToken = Deno.env.get('MP_ACCESS_TOKEN');
    const mpResponse = await fetch(`https://api.mercadopago.com/v1/payments/${paymentId}`, { headers: { 'Authorization': `Bearer ${mpAccessToken}` } });
    if (!mpResponse.ok) return new Response(JSON.stringify({ error: 'Invalid ID MP' }), { status: 200 }); 

    const paymentDetails = await mpResponse.json();
    const newStatus = paymentDetails.status;
    const externalReference = paymentDetails.external_reference;
    const payerDni = paymentDetails.payer?.identification?.number || "20301234567"; 

    console.log(`ℹ️ Pago: ${paymentId} | Status: ${newStatus}`);
    if (!externalReference) return new Response(JSON.stringify({ message: 'No Ref' }), { status: 200 });

    const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
    
    // 1. Actualizamos estado de pago
    const { data: orderData, error: updateError } = await supabase
      .from('orders_pulpiprint')
      .update({ status: newStatus, mp_payment_id: Number(paymentId) })
      .eq('id', externalReference)
      .select()
      .single();

    if (updateError) throw new Error("DB Error");

    // VARIABLES PARA EL EMAIL
    let finalTrackingNumber: string | null = orderData.tracking_number;
    let finalCarrier: string | null = orderData.carrier_slug;

    // 2. INTENTAMOS GENERAR ETIQUETA (Solo si es envío y no tiene tracking)
    const needsShipping = newStatus === 'approved' && orderData.delivery_type === 'envio';
    
    if (needsShipping && !finalTrackingNumber) {
      
      // BLOQUEO OPTIMISTA
      const { data: lockData } = await supabase
        .from('orders_pulpiprint')
        .update({ tracking_number: 'PROCESANDO...' }) 
        .eq('id', externalReference)
        .is('tracking_number', null) 
        .select()
        .maybeSingle();

      if (lockData) {
        console.log("🔒 Intentando generar etiqueta antes del email...");
        try {
            const enviaToken = Deno.env.get('ENVIA_ACCESS_TOKEN'); 
            const addr = orderData.shipping_address || {};
            const destName = orderData.payer_email ? orderData.payer_email.split('@')[0] : "Cliente";
            
            let carrierSlug = orderData.carrier_slug || 'correo-argentino';
            let serviceCode = "standard_dom"; 

            if (carrierSlug.includes('andreani')) { carrierSlug = 'andreani'; serviceCode = 'ground'; }
            else { carrierSlug = 'correoArgentino'; serviceCode = 'standard_dom'; }

            let destState = getStateCode(addr.state || "Buenos Aires");
            let originState = ORIGIN_DATA.state; 
            
            if (carrierSlug === 'correoArgentino') {
                if (originState === 'C') originState = "DF"; 
                if (destState === 'B') destState = "BA";     
            }

            const shippingBody = {
              origin: { ...ORIGIN_DATA, state: originState },
              destination: {
                name: destName,
                email: orderData.payer_email,
                phone: "5491155556666", 
                street: addr.street_name || "Calle", 
                number: addr.street_number || "0", 
                district: addr.city || "Buenos Aires", 
                city: addr.city || "Buenos Aires",      
                state: destState, 
                country: "AR",
                postalCode: addr.zip_code || "1000",
                identification_number: payerDni 
              },
              packages: [PARCEL_DATA],
              shipment: { carrier: carrierSlug, service: serviceCode, type: 1 },
              settings: { currency: "ARS", labelFormat: "pdf", printFormat: "PDF", printSize: "PAPER_8.5X11" }
            };

            const enviaRes = await fetch('https://api.envia.com/ship/generate/', { 
              method: 'POST',
              headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${enviaToken}` },
              body: JSON.stringify(shippingBody)
            });

            const enviaData = await enviaRes.json();

            if (enviaData && enviaData.meta === 'generate') {
              finalTrackingNumber = enviaData.data[0].trackingNumber;
              console.log(`🎉 TRACKING CREADO: ${finalTrackingNumber}`);
              await supabase.from('orders_pulpiprint').update({ tracking_number: finalTrackingNumber }).eq('id', externalReference);
            } else {
              console.error("❌ Falló Envia, pero enviamos email igual.");
              await supabase.from('orders_pulpiprint').update({ tracking_number: null }).eq('id', externalReference);
            }
        } catch (err) {
            console.error("⚠️ Error envío:", err);
            await supabase.from('orders_pulpiprint').update({ tracking_number: null }).eq('id', externalReference);
        }
      }
    }

    // 3. ENVIAMOS EL EMAIL AL FINAL (Con o sin tracking)
    if (newStatus === 'approved') {
        // Obtenemos carrier actualizado si no estaba definido
        finalCarrier = finalCarrier || (orderData.delivery_type === 'envio' ? 'correoArgentino' : null);
        await sendOrderEmail(orderData, paymentId, finalTrackingNumber, finalCarrier); 
    }

    return new Response(JSON.stringify({ message: 'OK' }), { status: 200, headers: corsHeaders });

  } catch (error) {
    console.error('💥 CRASH:', error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: corsHeaders });
  }
});