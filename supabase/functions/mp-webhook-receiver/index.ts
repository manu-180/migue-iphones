// supabase/functions/mp-webhook-receiver/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.8';

const corsHeaders = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type' };

// --- CONFIGURACIÓN ---
const SENDER_EMAIL = "soporte@assistify.lat"; 
const ADMIN_EMAIL = "geimul@gmail.com"; 
const WHATSAPP_NUMBER = "5491131390974"; 

// --- BRANDING MNL TECNO ---
const COLOR_BRAND = "#000000";       
const COLOR_ACCENT = "#25D366";      
const COLOR_ERROR = "#D32F2F";       
const COLOR_BG_LIGHT = "#F5F5F7";    
const COLOR_CARD_BG = "#FFFFFF";

// --- ORIGEN MNL (Fray Castaneda) ---
const ORIGIN_DATA = {
  name: "Miguel Navarro", 
  company: "MNL Tecno",
  email: "geimul@gmail.com", 
  phone: "5491131390974",      
  street: "Fray Castaneda", 
  number: "2488",             
  district: "Ricardo Rojas",        
  city: "Tigre",
  state: "B", 
  country: "AR",
  postalCode: "1610"           
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
  return new Intl.NumberFormat('es-AR', { style: 'currency', currency: 'ARS' }).format(Number(amount));
}

function formatDate(dateString: string) {
  if (!dateString) return new Date().toLocaleDateString('es-AR');
  const date = new Date(dateString);
  return new Intl.DateTimeFormat('es-AR', {
    dateStyle: 'full',
    timeStyle: 'medium',
    timeZone: 'America/Argentina/Buenos_Aires',
  }).format(date);
}

// --- HTML CLIENTE (Confirmación + Estado Envío) ---
function generateClientHtml(type: 'approved' | 'rejected', orderData: any, paymentId: string, trackingNumber: string | null, carrier: string | null) {
  
  const purchaseDate = formatDate(orderData.created_at || new Date().toISOString());

  const itemsHtml = (orderData.order_items || []).map((item: any) => `
    <tr>
      <td style="padding: 16px 0; border-bottom: 1px solid #f0f0f0;">
        <div style="display: flex; align-items: center;">
          ${item.image_url || item.picture_url ? `<img src="${item.image_url || item.picture_url}" alt="Prod" style="width: 50px; height: 50px; border-radius: 8px; object-fit: cover; margin-right: 15px; border: 1px solid #eaeaea;">` : ''}
          <div>
            <span style="display: block; font-weight: 700; font-size: 14px; color: #1d1d1f;">${item.title || item.name}</span>
            <span style="display: block; font-size: 12px; color: #86868b; margin-top: 4px;">Cant: ${item.quantity} ${item.selected_size ? `(${item.selected_size})` : ''}</span>
          </div>
        </div>
      </td>
      <td style="padding: 16px 0; border-bottom: 1px solid #f0f0f0; text-align: right; vertical-align: middle;">
        <span style="font-weight: 600; font-size: 14px; color: #1d1d1f;">${formatPrice(item.price || item.unit_price)}</span>
      </td>
    </tr>
  `).join('');

  const addr = orderData.shipping_address || {};
  const shippingAddressHtml = `
    <div style="margin-top: 25px; padding: 20px; background-color: #f9f9fa; border-radius: 12px; border: 1px solid #eaeaea;">
      <p style="margin: 0 0 10px 0; font-size: 11px; font-weight: 700; color: #86868b; text-transform: uppercase; letter-spacing: 0.5px;">📍 Dirección de Entrega</p>
      <p style="margin: 0; font-size: 14px; color: #1d1d1f; line-height: 1.5;">
        ${addr.street_name || addr.address || ''} ${addr.street_number || addr.number || ''}<br>
        ${addr.city || ''}, ${addr.state || ''} (C.P. ${addr.zip_code || ''})
      </p>
    </div>
  `;

  let headerColor = COLOR_BRAND;
  let iconStatus = "✅";
  let title = "";
  let message = "";
  let actionArea = "";
  let showSummary = false;

  if (type === 'rejected') {
    headerColor = COLOR_ERROR;
    iconStatus = "❌";
    title = "Pago Rechazado";
    message = "No pudimos procesar tu pago. Por favor, intenta nuevamente.";
    showSummary = false;
    actionArea = `
      <div style="text-align: center; margin: 40px 0;">
        <a href="https://migue-iphones.vercel.app/" style="display: inline-block; padding: 14px 32px; background-color: ${COLOR_ERROR}; color: #ffffff; text-decoration: none; border-radius: 50px; font-weight: 700; font-size: 14px; box-shadow: 0 4px 15px rgba(211, 47, 47, 0.3);">
          Reintentar Pago
        </a>
      </div>
    `;
  } else {
    showSummary = true;
    
    // CASO A: TRACKING GENERADO OK
    if (trackingNumber) {
      title = "¡Pedido en Camino!";
      message = "Tu paquete ya tiene etiqueta y está listo para ser despachado.";
      
      let trackUrl = `https://envia.com/rastreo?label=${trackingNumber}&cntry_code=ar`;
      let carrierName = "Correo";
      if (carrier && carrier.toLowerCase().includes('andreani')) {
         trackUrl = `https://www.andreani.com/#!/informacionEnvio/${trackingNumber}`;
         carrierName = "Andreani";
      } else { carrierName = "Correo Argentino"; }

      actionArea = `
        <div style="background: linear-gradient(135deg, #111 0%, #333 100%); border-radius: 16px; padding: 30px; text-align: center; margin: 35px 0; color: white; box-shadow: 0 10px 30px rgba(0,0,0,0.15);">
          <p style="margin: 0 0 10px 0; font-size: 11px; text-transform: uppercase; letter-spacing: 2px; opacity: 0.8;">Código de Seguimiento</p>
          <p style="margin: 0 0 25px 0; font-size: 26px; font-family: monospace; font-weight: 700; letter-spacing: 2px;">${trackingNumber}</p>
          
          <a href="${trackUrl}" target="_blank" style="display: inline-block; padding: 12px 28px; background-color: white; color: black; text-decoration: none; border-radius: 50px; font-weight: 700; font-size: 14px;">
            Rastrear en ${carrierName}
          </a>
        </div>
      `;
    } 
    // CASO B: SIN TRACKING (Retiro o Error/Demora en Etiqueta)
    else {
      title = "¡Gracias por tu compra!";
      message = "Tu pago fue exitoso. Estamos procesando tu pedido.";
      
      const wppLink = `https://wa.me/${WHATSAPP_NUMBER}?text=Hola%20MNL,%20consulto%20por%20mi%20pedido%20${orderData.id}`;
      
      if (orderData.delivery_type === 'retiro') {
         message = "Te avisaremos cuando tu pedido esté listo para retirar.";
      } else {
         // Mensaje específico si falló la etiqueta: Tranquilizamos al cliente
         message = "Estamos generando tu etiqueta de envío. Te enviaremos el código de seguimiento en un próximo correo a la brevedad.";
      }

      actionArea = `
        <div style="background-color: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 12px; padding: 20px; text-align: center; margin: 30px 0;">
          <p style="margin: 0; font-size: 14px; color: #166534;">
            <strong>Estado: Preparando Envío</strong><br>
            Tu pedido está confirmado y seguro.
          </p>
        </div>
      `;
    }
  }

  const total = Number(orderData.total_amount) || 0;
  const shippingCost = Number(orderData.shipping_cost) || 0;
  const subtotal = total - shippingCost;

  return `
    <!DOCTYPE html>
    <html>
    <head><meta charset="utf-8"></head>
    <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: ${COLOR_BG_LIGHT}; margin: 0; padding: 0;">
      <div style="max-width: 600px; margin: 0 auto; background-color: ${COLOR_CARD_BG}; overflow: hidden;">
        <div style="background-color: ${COLOR_BRAND}; padding: 30px 40px; text-align: center;">
           <h1 style="margin: 0; color: white; font-size: 24px; font-weight: 800; letter-spacing: -0.5px;">MNL Tecno</h1>
        </div>
        <div style="padding: 40px;">
          <div style="text-align: center; margin-bottom: 30px;">
            <div style="font-size: 48px; margin-bottom: 10px;">${iconStatus}</div>
            <h2 style="margin: 0 0 10px 0; font-size: 26px; font-weight: 800; color: #1d1d1f; letter-spacing: -0.5px;">${title}</h2>
            <p style="margin: 0; font-size: 14px; color: #86868b;">${purchaseDate}</p>
          </div>
          <p style="text-align: center; font-size: 16px; line-height: 1.6; color: #424245; margin-bottom: 20px;">
            ${message}
          </p>
          ${actionArea}
          ${showSummary ? `
          <div style="margin-top: 40px;">
            <h3 style="font-size: 16px; font-weight: 700; color: #1d1d1f; border-bottom: 2px solid #f0f0f0; padding-bottom: 15px; margin-bottom: 0;">Resumen de Compra</h3>
            <table style="width: 100%; border-collapse: collapse;"><tbody>${itemsHtml}</tbody></table>
          </div>
          <div style="margin-top: 0; padding-top: 15px;">
            <table style="width: 100%; border-collapse: collapse;">
              <tr><td style="padding: 5px 0; color: #86868b; font-size: 14px;">Subtotal</td><td style="padding: 5px 0; text-align: right; color: #1d1d1f; font-size: 14px; font-weight: 500;">${formatPrice(subtotal)}</td></tr>
              <tr><td style="padding: 5px 0; color: #86868b; font-size: 14px;">Envío</td><td style="padding: 5px 0; text-align: right; color: #1d1d1f; font-size: 14px; font-weight: 500;">${formatPrice(shippingCost)}</td></tr>
              <tr><td style="padding: 15px 0 0 0; color: #1d1d1f; font-size: 16px; font-weight: 700;">Total</td><td style="padding: 15px 0 0 0; text-align: right; color: ${COLOR_BRAND}; font-size: 24px; font-weight: 800;">${formatPrice(total)}</td></tr>
            </table>
          </div>
          ${shippingAddressHtml}
          ` : ''}
        </div>
        <div style="background-color: #f5f5f7; padding: 40px; text-align: center; border-top: 1px solid #eaeaea;">
          <div style="color: #86868b; font-size: 11px; line-height: 1.6;">
            <p style="margin: 0;">Referencia: <strong>${paymentId}</strong></p>
            <p style="margin: 0;">Pedido: <strong>#${orderData.id.toString().substring(0,8).toUpperCase()}</strong></p>
            <p style="margin: 15px 0 0 0;">&copy; 2025 MNL Tecno. Buenos Aires.</p>
          </div>
        </div>
      </div>
    </body>
    </html>
  `;
}

// --- HTML ADMIN (Reporte de Venta + Alerta de Error) ---
function generateAdminHtml(orderData: any, paymentId: string, trackingNumber: string | null, shippingErrorMsg: string | null) {
  const addr = orderData.shipping_address || {};
  const isShipping = orderData.delivery_type === 'envio';
  const date = formatDate(orderData.created_at || new Date().toISOString());
  
  const itemsRows = (orderData.order_items || []).map((item: any) => `
    <tr>
      <td style="padding: 8px; border-bottom: 1px solid #eee;">
        <strong>${item.title || item.name}</strong>
        ${item.selected_size ? `<br><span style="color: #666; font-size: 11px;">Variante: ${item.selected_size}</span>` : ''}
      </td>
      <td style="padding: 8px; border-bottom: 1px solid #eee; text-align: center;">${item.quantity}</td>
      <td style="padding: 8px; border-bottom: 1px solid #eee; text-align: right;">$${formatPrice(item.price || item.unit_price)}</td>
    </tr>
  `).join('');

  const total = Number(orderData.total_amount) || 0;
  const shippingCost = Number(orderData.shipping_cost) || 0;
  const subtotal = total - shippingCost;

  // BLOQUE DE ALERTA DE ERROR
  let trackingBlock = "";
  if (isShipping) {
      if (trackingNumber) {
          trackingBlock = `<p style="margin: 5px 0; font-size: 13px;"><strong>Tracking:</strong> <span style="background-color: #e0f7fa; padding: 2px 5px; border-radius: 4px;">${trackingNumber}</span></p>`;
      } else if (shippingErrorMsg) {
          // ESTO ES LO NUEVO: Alerta roja si falló Envia
          trackingBlock = `
            <div style="margin-top: 10px; background-color: #ffebee; border: 1px solid #ffcdd2; padding: 10px; border-radius: 4px; color: #b71c1c;">
                <strong>⚠️ ERROR CRÍTICO: NO SE GENERÓ ETIQUETA</strong><br>
                <span style="font-size: 12px;">Razón: ${shippingErrorMsg}</span><br>
                <span style="font-size: 12px; text-decoration: underline;">Acción: Generar manualmente en Envia.com y actualizar DB.</span>
            </div>
          `;
      } else {
          trackingBlock = `<p style="margin: 5px 0; font-size: 13px;"><strong>Tracking:</strong> Pendiente</p>`;
      }
  }

  return `
    <!DOCTYPE html>
    <html>
    <head><meta charset="utf-8"></head>
    <body style="font-family: 'Courier New', Courier, monospace; background-color: #f4f4f4; padding: 20px;">
      <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border: 1px solid #ccc; box-shadow: 0 4px 10px rgba(0,0,0,0.1);">
        <div style="background-color: #333; color: #fff; padding: 15px; text-align: center;">
          <h2 style="margin: 0; font-size: 20px;">💰 NUEVA VENTA CONFIRMADA</h2>
          <p style="margin: 5px 0 0 0; font-size: 12px;">ID: #${orderData.id.toString().substring(0,8).toUpperCase()}</p>
        </div>
        <div style="padding: 20px;">
          <div style="margin-bottom: 20px; text-align: right; font-size: 12px; color: #666;">📅 ${date}</div>
          <div style="margin-bottom: 20px; border: 1px solid #eee; padding: 15px; background-color: #fafafa;">
            <h3 style="margin-top: 0; font-size: 14px; border-bottom: 1px solid #ddd; padding-bottom: 5px;">👤 DATOS DEL CLIENTE</h3>
            <p style="margin: 5px 0; font-size: 13px;"><strong>Email:</strong> ${orderData.payer_email}</p>
            <p style="margin: 5px 0; font-size: 13px;"><strong>Nombre:</strong> ${addr.name || 'No especificado'}</p>
            <p style="margin: 5px 0; font-size: 13px;"><strong>DNI/CUIT:</strong> ${addr.identification_number || 'No especificado'}</p>
            <p style="margin: 5px 0; font-size: 13px;"><strong>Teléfono:</strong> ${addr.phone || 'No especificado'}</p>
          </div>
          <div style="margin-bottom: 20px; border: 1px solid #eee; padding: 15px; background-color: #fafafa;">
            <h3 style="margin-top: 0; font-size: 14px; border-bottom: 1px solid #ddd; padding-bottom: 5px;">📦 LOGÍSTICA: ${isShipping ? 'ENVÍO' : 'RETIRO'}</h3>
            ${isShipping ? `
              <p style="margin: 5px 0; font-size: 13px;"><strong>Dirección:</strong> ${addr.street_name || ''} ${addr.street_number || ''}</p>
              <p style="margin: 5px 0; font-size: 13px;"><strong>Localidad:</strong> ${addr.city || ''}, ${addr.state || ''} (CP: ${addr.zip_code})</p>
              ${trackingBlock}
            ` : `<p style="margin: 5px 0; font-size: 13px; color: #d32f2f;">⚠️ Cliente retira por local.</p>`}
          </div>
          <h3 style="font-size: 14px; border-bottom: 2px solid #333; padding-bottom: 5px;">🛒 PRODUCTOS</h3>
          <table style="width: 100%; border-collapse: collapse; font-size: 13px;">
            <thead><tr style="background-color: #eee;"><th style="padding: 8px; text-align: left;">Producto</th><th style="padding: 8px; text-align: center;">Cant</th><th style="padding: 8px; text-align: right;">Total</th></tr></thead>
            <tbody>${itemsRows}</tbody>
          </table>
          <div style="margin-top: 20px; text-align: right;">
            <p style="margin: 5px 0; font-size: 13px;">Subtotal: $${formatPrice(subtotal)}</p>
            <p style="margin: 5px 0; font-size: 13px;">Envío: $${formatPrice(shippingCost)}</p>
            <p style="margin: 10px 0; font-size: 18px; font-weight: bold; color: #2e7d32;">TOTAL: $${formatPrice(total)}</p>
          </div>
          <div style="font-size: 11px; color: #999; margin-top: 20px;"><p>Ref. Pago: ${paymentId}</p></div>
        </div>
      </div>
    </body>
    </html>
  `;
}

// --- ENVÍOS DE MAIL ---
async function sendClientEmail(status: 'approved' | 'rejected', orderData: any, paymentId: string, trackingNumber: string | null, carrierSlug: string | null) {
  const apiKey = Deno.env.get('RESEND_API_KEY');
  if (!apiKey) return;
  const htmlContent = generateClientHtml(status, orderData, paymentId, trackingNumber, carrierSlug);
  let subject = `Pedido Confirmado #${orderData.id.toString().substring(0,8).toUpperCase()}`;
  if (trackingNumber) subject = `¡Tu pedido #${orderData.id.toString().substring(0,8).toUpperCase()} está en camino! 🚀`;
  if (status === 'rejected') subject = "Problema con tu pago en MNL Tecno";

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

// --- NOTIFICACIÓN ADMIN (Ahora recibe el errorMsg) ---
async function sendAdminNotification(orderData: any, paymentId: string, trackingNumber: string | null, shippingErrorMsg: string | null) {
  const apiKey = Deno.env.get('RESEND_API_KEY');
  if (!apiKey) return;
  
  // Asunto especial si falló la etiqueta
  let subject = `[VENTA] $${formatPrice(orderData.total_amount)} - ${orderData.payer_email}`;
  if (shippingErrorMsg) subject = `⚠️ [ERROR ETIQUETA] Venta $${formatPrice(orderData.total_amount)}`;

  await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${apiKey}` },
    body: JSON.stringify({
      from: `MNL Bot <${SENDER_EMAIL}>`,
      to: [ADMIN_EMAIL], 
      subject: subject,
      html: generateAdminHtml(orderData, paymentId, trackingNumber, shippingErrorMsg)
    })
  });
}

// --- LOGICA PRINCIPAL ---
serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const url = new URL(req.url);
    let paymentId = url.searchParams.get('id') || url.searchParams.get('data.id');
    if (!paymentId) { try { const body = await req.json(); paymentId = body.data?.id || body.id; } catch(e){} }
    if (!paymentId) return new Response(JSON.stringify({msg: 'Ignored'}), {status: 200});

    const mpToken = Deno.env.get('MP_ACCESS_TOKEN');
    const mpRes = await fetch(`https://api.mercadopago.com/v1/payments/${paymentId}`, { headers: {'Authorization': `Bearer ${mpToken}`} });
    if (!mpRes.ok) return new Response('MP Error', {status: 200});
    
    const paymentData = await mpRes.json();
    const paymentStatus = paymentData.status; 
    const refId = paymentData.external_reference;
    const payerDni = paymentData.payer?.identification?.number || "20301234567";

    if (!refId) return new Response('No Ref', {status: 200});

    const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
    
    const { data: currentOrder } = await supabase.from('orders_pulpiprint').select('tracking_number').eq('id', refId).single();
    const alreadyHadTracking = currentOrder?.tracking_number && currentOrder.tracking_number !== 'PROCESANDO...';

    const { data: orderData, error: dbError } = await supabase
        .from('orders_pulpiprint')
        .update({ status: paymentStatus, mp_payment_id: Number(paymentId) })
        .eq('id', refId)
        .select()
        .single();

    if (dbError) throw new Error("DB Error");

    let finalTracking = orderData.tracking_number;
    let finalCarrier = orderData.carrier_slug;
    let shouldSendEmail = false;
    let shippingErrorMsg = null; // Variable para guardar el error de Envia

    // --- RECHAZADO ---
    if (paymentStatus === 'rejected' || paymentStatus === 'cancelled') {
        shouldSendEmail = true;
    }

    // --- APROBADO ---
    if (paymentStatus === 'approved') {
        const needsShipping = orderData.delivery_type === 'envio';
        
        if (alreadyHadTracking) {
            shouldSendEmail = false; 
        } else if (!needsShipping) {
            shouldSendEmail = true; 
        } else if (needsShipping && !finalTracking) {
            
            const { data: lockData } = await supabase.from('orders_pulpiprint').update({ tracking_number: 'PROCESANDO...' }).eq('id', refId).is('tracking_number', null).select().maybeSingle();

            if (lockData) {
                console.log("🔒 Generando etiqueta Envia...");
                try {
                    const enviaToken = Deno.env.get('ENVIA_ACCESS_TOKEN');
                    const addr = orderData.shipping_address || {};
                    const destName = orderData.payer_email ? orderData.payer_email.split('@')[0] : "Cliente";
                    
                    let carrierSlug = 'correoArgentino';
                    let serviceCode = 'standard_dom';
                    if (orderData.carrier_slug && orderData.carrier_slug.includes('andreani')) {
                        carrierSlug = 'andreani';
                        serviceCode = 'ground';
                    }

                    let destState = getStateCode(addr.state || "Buenos Aires");
                    let originState = ORIGIN_DATA.state; 
                    
                    if (carrierSlug === 'correoArgentino') {
                        if (originState === 'C') originState = "DF";
                        if (originState === 'B') originState = "BA";
                        if (destState === 'B') destState = "BA";
                    }

                    const shippingBody = {
                        origin: { ...ORIGIN_DATA, state: originState },
                        destination: {
                            name: destName,
                            email: orderData.payer_email,
                            street: addr.street_name || "Calle",
                            number: addr.street_number || "0",
                            district: addr.city || "Buenos Aires",
                            city: addr.city || "Buenos Aires",
                            state: destState, 
                            country: "AR",
                            postalCode: addr.zip_code || "1000",
                            phone: "5491155556666",
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

                    const enviaText = await enviaRes.text();
                    let enviaData; try { enviaData = JSON.parse(enviaText); } catch(e){}

                    if (enviaData && enviaData.meta === 'generate') {
                        finalTracking = enviaData.data[0].trackingNumber;
                        console.log(`✅ TRACKING: ${finalTracking}`);
                        await supabase.from('orders_pulpiprint').update({ tracking_number: finalTracking }).eq('id', refId);
                        shouldSendEmail = true;
                    } else {
                        // AQUÍ ESTÁ EL CAMBIO CLAVE:
                        const apiError = enviaData?.error?.message || "Error desconocido en API";
                        console.error("❌ Falló Envia:", apiError);
                        shippingErrorMsg = apiError; // Guardamos el error
                        
                        await supabase.from('orders_pulpiprint').update({ tracking_number: null }).eq('id', refId);
                        
                        // FORZAMOS EL ENVÍO DEL MAIL AUNQUE FALLE EL TRACKING
                        shouldSendEmail = true; 
                    }
                } catch (err) {
                    console.error("Excepción:", err);
                    shippingErrorMsg = err.message || "Error de conexión con Envia";
                    await supabase.from('orders_pulpiprint').update({ tracking_number: null }).eq('id', refId);
                    shouldSendEmail = true; // Forzamos envío
                }
            } else {
                shouldSendEmail = false;
            }
        }
    }

    if (shouldSendEmail) {
        finalCarrier = finalCarrier || (orderData.delivery_type === 'envio' ? 'correoArgentino' : null);
        console.log("📧 Enviando emails...");
        await sendClientEmail(paymentStatus === 'rejected' ? 'rejected' : 'approved', orderData, paymentId, finalTracking, finalCarrier);
        // Pasamos el error de envío a la notificación del admin
        await sendAdminNotification(orderData, paymentId, finalTracking, shippingErrorMsg);
    }

    return new Response(JSON.stringify({ message: 'OK' }), { status: 200, headers: corsHeaders });

  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: corsHeaders });
  }
});