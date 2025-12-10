// supabase/functions/mp-webhook-receiver/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.8';

const corsHeaders = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type' };

// --- CONFIGURACIÓN ---
const SENDER_EMAIL = "soporte@assistify.lat"; 
const ADMIN_EMAIL = "manunv97@gmail.com"; 
const WHATSAPP_NUMBER = "5491134272488"; 

// --- PALETA DE COLORES PROFESIONAL ---
const COLOR_BRAND = "#000000";       // Negro Puro (Apple Style)
const COLOR_ACCENT = "#25D366";      // WhatsApp Green
const COLOR_ERROR = "#D32F2F";       // Rojo Error
const COLOR_BG_LIGHT = "#F5F5F7";    // Gris muy suave de fondo
const COLOR_Warning_BG = "#FFF8E1";  // Fondo Amarillo suave
const COLOR_Warning_TXT = "#F57F17"; // Texto Naranja oscuro

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

function formatPrice(amount: any) {
  return Number(amount).toFixed(2);
}

// --- GENERADOR DE HTML PREMIUM (CLIENTE) ---
function generateClientHtml(type: 'approved' | 'rejected', orderData: any, paymentId: string, trackingNumber: string | null, carrier: string | null) {
  
  // Tabla de productos minimalista
  const itemsHtml = orderData.order_items.map((item: any) => `
    <tr>
      <td style="padding: 12px 0; border-bottom: 1px solid #eaeaea;">
        <span style="font-weight: 600; font-size: 14px; color: #1d1d1f;">${item.title || item.name}</span>
        <div style="font-size: 12px; color: #86868b;">Cant: ${item.quantity}</div>
      </td>
      <td style="padding: 12px 0; border-bottom: 1px solid #eaeaea; text-align: right;">
        <span style="font-weight: 500; font-size: 14px; color: #1d1d1f;">$${formatPrice(item.price)}</span>
      </td>
    </tr>
  `).join('');

  let headerColor = COLOR_BRAND;
  let title = "";
  let message = "";
  let actionArea = "";
  let showSummary = false;

  // --- ESCENARIO 1: RECHAZADO ---
  if (type === 'rejected') {
    headerColor = COLOR_ERROR;
    title = "El pago no pudo completarse";
    message = "Hubo un problema con la transacción. Por favor, intenta nuevamente con otro método de pago.";
    showSummary = false;
    actionArea = `
      <div style="text-align: center; margin: 35px 0;">
        <a href="https://migue-iphones.vercel.app/" style="display: inline-block; padding: 14px 32px; background-color: ${COLOR_ERROR}; color: #ffffff; text-decoration: none; border-radius: 8px; font-weight: 600; font-size: 14px; box-shadow: 0 4px 6px rgba(211, 47, 47, 0.2);">
          Intentar Nuevamente
        </a>
      </div>
    `;
  } 
  // --- ESCENARIOS 2 Y 3: APROBADO ---
  else {
    showSummary = true;
    
    // CASO A: CON TRACKING (Todo perfecto)
    if (trackingNumber) {
      title = "¡Tu pedido está en camino!";
      message = "Hemos preparado tu paquete y ya tiene etiqueta de envío asignada.";
      
      let trackUrl = `https://envia.com/rastreo?label=${trackingNumber}&cntry_code=ar`;
      let carrierName = "Correo";
      if (carrier && carrier.toLowerCase().includes('andreani')) {
         trackUrl = `https://www.andreani.com/#!/informacionEnvio/${trackingNumber}`;
         carrierName = "Andreani";
      } else { carrierName = "Correo Argentino"; }

      actionArea = `
        <div style="background-color: #fafafa; border-radius: 12px; padding: 30px; text-align: center; margin: 30px 0; border: 1px solid #eaeaea;">
          <p style="margin: 0 0 8px 0; font-size: 11px; color: #86868b; text-transform: uppercase; letter-spacing: 1px; font-weight: 600;">CÓDIGO DE SEGUIMIENTO</p>
          <p style="margin: 0 0 25px 0; font-size: 22px; font-family: monospace; font-weight: 700; color: #1d1d1f; letter-spacing: 1px;">${trackingNumber}</p>
          
          <a href="${trackUrl}" target="_blank" style="display: inline-block; padding: 14px 32px; background-color: ${COLOR_BRAND}; color: #ffffff; text-decoration: none; border-radius: 8px; font-weight: 600; font-size: 14px; box-shadow: 0 4px 10px rgba(0,0,0,0.15);">
            Seguir Envío (${carrierName})
          </a>
        </div>
      `;
    } 
    // CASO B: SIN TRACKING (Gestión Manual)
    else {
      title = "Pago Aprobado";
      message = "Tu compra está confirmada y segura. Estamos gestionando tu etiqueta de envío manualmente debido a una demora en el sistema de correo.";
      
      const wppLink = `https://wa.me/${WHATSAPP_NUMBER}?text=Hola%20MNL,%20mi%20pedido%20${orderData.id.toString().substring(0,8).toUpperCase()}%20fue%20aprobado%20y%20necesito%20info%20del%20envio.`;

      actionArea = `
        <div style="background-color: ${COLOR_Warning_BG}; border-radius: 12px; padding: 25px; text-align: center; margin: 30px 0; border: 1px solid #ffeeba;">
          <p style="margin: 0 0 20px 0; font-size: 15px; color: ${COLOR_Warning_TXT}; font-weight: 600;">
            ⚠️ Finalicemos tu envío por WhatsApp
          </p>
          <a href="${wppLink}" target="_blank" style="display: inline-block; padding: 14px 28px; background-color: ${COLOR_ACCENT}; color: #ffffff; text-decoration: none; border-radius: 50px; font-weight: 700; font-size: 14px; box-shadow: 0 4px 10px rgba(37, 211, 102, 0.2);">
            <span style="font-size: 18px; vertical-align: middle; margin-right: 6px;">📞</span> Contactar Ahora
          </a>
        </div>
      `;
    }
  }

  // --- HTML FINAL ---
  return `
    <!DOCTYPE html>
    <html>
    <head><meta charset="utf-8"></head>
    <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: ${COLOR_BG_LIGHT}; margin: 0; padding: 0;">
      
      <div style="max-width: 600px; margin: 40px auto; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 40px rgba(0,0,0,0.08);">
        
        <div style="height: 6px; background-color: ${headerColor}; width: 100%;"></div>

        <div style="padding: 40px 40px 30px 40px;">
          <div style="text-align: center; margin-bottom: 25px;">
            <h1 style="margin: 0; font-size: 28px; font-weight: 800; letter-spacing: -0.5px; color: ${headerColor};">MNL Tecno</h1>
          </div>

          <h2 style="text-align: center; font-size: 22px; color: #1d1d1f; margin-top: 0; font-weight: 700;">${title}</h2>
          <p style="text-align: center; font-size: 15px; line-height: 1.6; color: #515154; margin-bottom: 20px;">
            ${message}
          </p>

          ${actionArea}

          ${showSummary ? `
          <div style="margin-top: 35px;">
            <p style="margin: 0 0 15px 0; font-weight: 700; font-size: 13px; color: #86868b; text-transform: uppercase; letter-spacing: 0.5px;">Resumen del pedido</p>
            <table style="width: 100%; border-collapse: collapse;">
              <tbody>${itemsHtml}</tbody>
              <tfoot>
                <tr>
                  <td style="padding-top: 18px; text-align: right; font-weight: 600; color: #1d1d1f; font-size: 14px;">Total</td>
                  <td style="padding-top: 18px; text-align: right; font-weight: 800; font-size: 18px; color: #1d1d1f;">$${formatPrice(orderData.total_amount)}</td>
                </tr>
              </tfoot>
            </table>
          </div>
          ` : ''}
        </div>

        <div style="background-color: #fafafa; padding: 30px 40px; text-align: center; border-top: 1px solid #eaeaea;">
          
          ${showSummary ? `
          <div style="margin-bottom: 20px;">
            <a href="https://wa.me/${WHATSAPP_NUMBER}" style="display: inline-block; background-color: #ffffff; border: 1px solid #d1d1d6; color: ${COLOR_ACCENT}; padding: 10px 20px; border-radius: 50px; text-decoration: none; font-weight: 700; font-size: 13px; transition: all 0.2s;">
              <span style="font-size: 16px; vertical-align: middle; margin-right: 5px;">📞</span> Soporte WhatsApp
            </a>
          </div>
          ` : ''}

          <p style="margin: 0 0 5px 0; color: #86868b; font-size: 11px;">ID de Referencia: ${paymentId}</p>
          <p style="margin: 0; color: #86868b; font-size: 11px;">&copy; 2025 MNL Tecno. Buenos Aires, Argentina.</p>
        </div>

      </div>
    </body>
    </html>
  `;
}

// --- PLANTILLA ADMIN (Técnica) ---
function generateAdminHtml(orderData: any, paymentId: string, trackingNumber: string | null) {
  const addr = orderData.shipping_address || {};
  const itemsHtml = orderData.order_items.map((item: any) => 
    `<li><strong>${item.title || item.name}</strong> (x${item.quantity}) - $${formatPrice(item.price)}</li>`
  ).join('');

  return `
    <!DOCTYPE html>
    <html>
    <head><meta charset="utf-8"></head>
    <body style="font-family: monospace; background-color: #eeeeee; padding: 20px;">
      <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; padding: 20px; border: 1px solid #ccc;">
        <h2 style="margin-top: 0; color: #000;">💰 Nueva Venta: $${formatPrice(orderData.total_amount)}</h2>
        <hr>
        <h3>👤 Cliente</h3>
        <p>${orderData.payer_email}<br>${addr.name || 'Sin nombre'}</p>
        <h3>📍 Envío</h3>
        <p>${addr.street_name || ''} ${addr.street_number || ''}, ${addr.city || ''} (${addr.zip_code})</p>
        <div style="background: #e3f2fd; padding: 10px; border: 1px solid #90caf9;">
          <strong>Tracking:</strong> ${trackingNumber || "⚠️ NO GENERADO (Verificar Envia.com)"}
        </div>
        <h3>🛒 Items</h3>
        <ul>${itemsHtml}</ul>
        <p>Ref Pago: ${paymentId}</p>
      </div>
    </body>
    </html>
  `;
}

// --- ENVÍOS ---
async function sendClientEmail(status: 'approved' | 'rejected', orderData: any, paymentId: string, trackingNumber: string | null, carrierSlug: string | null) {
  const apiKey = Deno.env.get('RESEND_API_KEY');
  if (!apiKey) return;

  const htmlContent = generateClientHtml(status, orderData, paymentId, trackingNumber, carrierSlug);
  
  let subject = "";
  if (status === 'rejected') subject = "Problema con tu pago en MNL Tecno";
  else if (trackingNumber) subject = `Tu pedido #${orderData.id.toString().substring(0,8).toUpperCase()} está en camino 🚀`;
  else subject = `Confirmación de Pedido #${orderData.id.toString().substring(0,8).toUpperCase()} (Acción Requerida)`;

  await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${apiKey}` },
    body: JSON.stringify({
      from: `MNL Tecno <${SENDER_EMAIL}>`,
      to: [orderData.payer_email], 
      subject: subject,
      html: htmlContent
    })
  });
}

async function sendAdminNotification(orderData: any, paymentId: string, trackingNumber: string | null) {
  const apiKey = Deno.env.get('RESEND_API_KEY');
  if (!apiKey) return;

  await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${apiKey}` },
    body: JSON.stringify({
      from: `MNL Bot <${SENDER_EMAIL}>`,
      to: [ADMIN_EMAIL], 
      subject: `[VENTA] $${formatPrice(orderData.total_amount)} - ${orderData.payer_email}`,
      html: generateAdminHtml(orderData, paymentId, trackingNumber)
    })
  });
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
    
    const { data: orderData, error: updateError } = await supabase
      .from('orders_pulpiprint')
      .update({ status: newStatus, mp_payment_id: Number(paymentId) })
      .eq('id', externalReference)
      .select()
      .single();

    if (updateError) throw new Error("DB Error");

    let finalTrackingNumber: string | null = orderData.tracking_number;
    let finalCarrier: string | null = orderData.carrier_slug;

    if (newStatus === 'rejected' || newStatus === 'cancelled') {
        await sendClientEmail('rejected', orderData, paymentId, null, null);
        return new Response(JSON.stringify({ message: 'Rejected Processed' }), { status: 200, headers: corsHeaders });
    }

    if (newStatus === 'approved') {
        const needsShipping = orderData.delivery_type === 'envio';
        
        if (needsShipping && !finalTrackingNumber) {
          const { data: lockData } = await supabase.from('orders_pulpiprint').update({ tracking_number: 'PROCESANDO...' }).eq('id', externalReference).is('tracking_number', null).select().maybeSingle();

          if (lockData) {
            console.log("🔒 Generando etiqueta...");
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

                const enviaRawText = await enviaRes.text();
                let enviaData;
                try { enviaData = JSON.parse(enviaRawText); } catch(e) { }

                if (enviaData && enviaData.meta === 'generate') {
                  finalTrackingNumber = enviaData.data[0].trackingNumber;
                  console.log(`🎉 TRACKING CREADO: ${finalTrackingNumber}`);
                  await supabase.from('orders_pulpiprint').update({ tracking_number: finalTrackingNumber }).eq('id', externalReference);
                } else {
                  console.error("❌ Falló Envia:", enviaRawText);
                  await supabase.from('orders_pulpiprint').update({ tracking_number: null }).eq('id', externalReference);
                }
            } catch (err) {
                console.error("⚠️ Error envío:", err);
                await supabase.from('orders_pulpiprint').update({ tracking_number: null }).eq('id', externalReference);
            }
          } else {
             console.log("🛑 Hilo duplicado detenido.");
             return new Response(JSON.stringify({ message: 'Already Processed' }), { status: 200, headers: corsHeaders });
          }
        }

        finalCarrier = finalCarrier || (orderData.delivery_type === 'envio' ? 'correoArgentino' : null);
        console.log("📧 Enviando emails...");
        await sendClientEmail('approved', orderData, paymentId, finalTrackingNumber, finalCarrier);
        await sendAdminNotification(orderData, paymentId, finalTrackingNumber);
    }

    return new Response(JSON.stringify({ message: 'OK' }), { status: 200, headers: corsHeaders });

  } catch (error) {
    console.error('💥 CRASH:', error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: corsHeaders });
  }
});