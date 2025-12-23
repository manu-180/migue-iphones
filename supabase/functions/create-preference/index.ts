// supabase/functions/create-preference/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { MercadoPagoConfig, Preference } from 'npm:mercadopago';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.8';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Usamos SERVICE_ROLE_KEY para poder escribir en la DB sin restricciones de RLS desde el backend
const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, 
  { auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false } }
);

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { items, shipping_cost, shipping_address, payer_email, carrier_slug, service_level } = await req.json()
    console.log("📦 [CreatePref] Procesando compra para:", payer_email);

    // 1. Preparar Items para guardar en la columna JSONB 'order_items'
    // Asegúrate de guardar todos los datos necesarios para el recibo aquí
    const orderItemsDb = items.map((item: any) => ({
      id: item.id,
      title: item.title,
      quantity: item.quantity,
      price: item.price || item.unit_price, // Manejo de fallback por si cambia el nombre del campo
      picture_url: item.picture_url || item.image_url,
      selected_size: item.selected_size || item.description,
    }));

    const itemsTotal = items.reduce((sum: number, item: any) => sum + (Number(item.price || item.unit_price) * Number(item.quantity)), 0);
    const totalAmount = itemsTotal + (shipping_cost || 0);
    
    const hasAddress = shipping_address && (shipping_address.street_name || shipping_address.address);
    const deliveryType = hasAddress ? 'envio' : 'retiro';

    // 2. Insertar en DB (CORRECCIÓN AQUÍ: orders_pulpiprint)
    const { data: newOrder, error: orderError } = await supabase
      .from('orders_pulpiprint') // <--- AQUÍ ESTABA EL ERROR
      .insert({
        status: 'pending',
        total_amount: totalAmount,
        shipping_cost: shipping_cost || 0,
        payer_email: payer_email,
        delivery_type: deliveryType, 
        shipping_address: shipping_address || {},
        order_items: orderItemsDb,
        carrier_slug: carrier_slug || 'correo-argentino', 
        service_level: service_level || 'standard'
      })
      .select('id')
      .single();

    if (orderError) {
      console.error("Error insertando orden:", orderError);
      throw new Error(`Error DB: ${orderError.message}`);
    }

    console.log("✅ Orden creada en DB con ID:", newOrder.id);

    // 3. Mercado Pago Preference
    const client = new MercadoPagoConfig({ accessToken: Deno.env.get('MP_ACCESS_TOKEN') || '' });
    const preference = new Preference(client);

    const mpItems = items.map((item: any) => ({
      id: item.id.toString(),
      title: item.title,
      quantity: Number(item.quantity),
      unit_price: Number(item.price || item.unit_price),
      currency_id: 'ARS',
      picture_url: item.picture_url || item.image_url
    }));

    if (shipping_cost && Number(shipping_cost) > 0) {
      mpItems.push({ id: 'shipping', title: 'Costo de Envío', quantity: 1, unit_price: Number(shipping_cost), currency_id: 'ARS' });
    }

    // Recuerda el '#' si no usas vercel.json, o quítalo si ya configuraste rewrites.
    // Asumiendo la config de MNL que funcionaba:
    const baseUrl = 'https://mnltecno.com/#'; 
    const webhookUrl = `${Deno.env.get('SUPABASE_URL')}/functions/v1/mp-webhook-receiver`;

    const result = await preference.create({
      body: {
        items: mpItems,
        payer: { email: payer_email },
        external_reference: newOrder.id, // Vinculamos la preferencia con el ID de Supabase
        back_urls: {
          success: `${baseUrl}/success`,
          failure: `${baseUrl}/failure`,
          pending: `${baseUrl}/pending`,
        },
        auto_return: 'approved',
        notification_url: webhookUrl
      }
    });

    return new Response(
      JSON.stringify({ order_id: newOrder.id, preference_id: result.id, init_point: result.init_point }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    console.error("💥 Error General:", error);
    return new Response(JSON.stringify({ error: error.message }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 })
  }
});