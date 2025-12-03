// supabase/functions/send-email/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { Resend } from "npm:resend";
const resend = new Resend(Deno.env.get('RESEND_API_KEY'));
const SENDER_EMAIL = 'soporte@assistify.lat' // Tu mail verificado
;
const SENDER_NAME = 'PulpiPrint';
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};
// Función para generar el HTML
const generateEmailHtml = (orderId, items, total, deliveryType, shippingData)=>{
  const itemsHtml = items.map((item)=>`
    <tr>
      <td style="padding: 8px; border-bottom: 1px solid #eee;">${item.title} ${item.selected_size ? `(${item.selected_size})` : ''}</td>
      <td style="padding: 8px; border-bottom: 1px solid #eee;">x${item.quantity}</td>
      <td style="padding: 8px; border-bottom: 1px solid #eee; text-align: right;">$${item.price}</td>
    </tr>
  `).join('');
  let deliveryHtml = '';
  if (deliveryType === 'envio') {
    deliveryHtml = `
      <div style="background-color: #f9f9f9; padding: 15px; border-radius: 8px; margin-top: 20px;">
        <h3 style="color: #555; margin-top: 0;">📦 Envío a Domicilio</h3>
        <p style="margin: 5px 0; color: #333;">
          Estamos preparando tu paquete para enviarlo a:<br>
          <strong>${shippingData.address}, ${shippingData.city} (${shippingData.cp})</strong><br>
          Provincia: ${shippingData.province}
        </p>
        <p style="color: #777; font-size: 12px;">Te enviaremos el código de seguimiento en un próximo correo.</p>
      </div>
    `;
  } else {
    deliveryHtml = `
      <div style="background-color: #f9f9f9; padding: 15px; border-radius: 8px; margin-top: 20px;">
        <h3 style="color: #555; margin-top: 0;">🏪 Retiro por el Local</h3>
        <p style="margin: 5px 0; color: #333;">
          ¡Tu pedido ya está registrado! Por favor, coordiná el retiro con nosotros.
        </p>
        <p style="margin-top: 10px;">
          <a href="https://wa.me/5491168930600?text=Hola,%20tengo%20el%20pedido%20${orderId}%20y%20quiero%20coordinar%20retiro" 
             style="background-color: #25D366; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; font-weight: bold;">
             Coordinar por WhatsApp
          </a>
        </p>
      </div>
    `;
  }
  return `
    <!DOCTYPE html>
    <html>
    <body style="font-family: sans-serif; color: #333; line-height: 1.6;">
      <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
        <h1 style="color: #6D28D9; text-align: center;">¡Gracias por tu compra!</h1>
        <p style="text-align: center; font-size: 16px;">Tu orden <strong>#${orderId}</strong> ha sido confirmada.</p>
        
        <h3>Resumen del pedido:</h3>
        <table style="width: 100%; border-collapse: collapse;">
          ${itemsHtml}
          <tr>
            <td colspan="2" style="padding: 10px; text-align: right; font-weight: bold;">Total:</td>
            <td style="padding: 10px; text-align: right; font-weight: bold; font-size: 18px;">$${total}</td>
          </tr>
        </table>

        ${deliveryHtml}

        <hr style="border: 0; border-top: 1px solid #eee; margin: 30px 0;">
        
        <div style="text-align: center; color: #999; font-size: 12px;">
          <p>Cualquier duda, contactanos a este mail o por WhatsApp.</p>
          <p>PulpiPrint - Impresiones 3D</p>
        </div>
      </div>
    </body>
    </html>
  `;
};
serve(async (req)=>{
  if (req.method === 'OPTIONS') return new Response('ok', {
    headers: corsHeaders
  });
  try {
    // Recibimos todos los datos necesarios
    const { to, order_id, items, total_price, delivery_type, shipping_address } = await req.json();
    const html = generateEmailHtml(order_id, items, total_price, delivery_type, shipping_address);
    const data = await resend.emails.send({
      from: `${SENDER_NAME} <${SENDER_EMAIL}>`,
      to: [
        to
      ],
      subject: `Confirmación de Orden #${order_id} - PulpiPrint`,
      html: html
    });
    return new Response(JSON.stringify(data), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      },
      status: 200
    });
  } catch (error) {
    return new Response(JSON.stringify({
      error: error.message
    }), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      },
      status: 400
    });
  }
});
