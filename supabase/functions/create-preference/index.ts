// supabase/functions/create-preference/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { MercadoPagoConfig, Preference } from 'npm:mercadopago';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.8';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, 
  { auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false } }
);

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { items, shipping_cost, shipping_address, payer_email } = await req.json()
    console.log("📦 [CreatePref] Iniciando para:", payer_email);

    // 1. Preparar Items DB
    const orderItemsDb = items.map((item: any) => ({
      id: item.id,
      title: item.title,
      quantity: item.quantity,
      price: item.price,
      selected_size: item.selected_size,
    }));

    const itemsTotal = items.reduce((sum: number, item: any) => sum + (Number(item.price) * Number(item.quantity)), 0);
    const totalAmount = itemsTotal + (shipping_cost || 0);
    
    // Lógica Envío: Si hay dirección con calle, es envío.
    const hasAddress = shipping_address && shipping_address.street_name;
    const deliveryType = hasAddress ? 'envio' : 'retiro';

    // 2. Crear Orden Supabase
    const { data: newOrder, error: orderError } = await supabase
      .from('orders_pulpiprint')
      .insert({
        status: 'pending',
        total_amount: totalAmount,
        shipping_cost: shipping_cost || 0,
        payer_email: payer_email,
        delivery_type: deliveryType, 
        shipping_address: shipping_address || {},
        order_items: orderItemsDb,
      })
      .select('id')
      .single();

    if (orderError) throw new Error(`Error DB: ${orderError.message}`);
    console.log(`✅ [CreatePref] Orden creada: ${newOrder.id} (Tipo: ${deliveryType})`);

    // 3. Mercado Pago
    const client = new MercadoPagoConfig({ accessToken: Deno.env.get('MP_ACCESS_TOKEN') || '' });
    const preference = new Preference(client);

    const mpItems = items.map((item: any) => ({
      id: item.id.toString(),
      title: item.title,
      quantity: Number(item.quantity),
      unit_price: Number(item.price),
      currency_id: 'ARS',
    }));

    if (shipping_cost && Number(shipping_cost) > 0) {
      mpItems.push({ id: 'shipping', title: 'Envío', quantity: 1, unit_price: Number(shipping_cost), currency_id: 'ARS' });
    }

    const baseUrl = 'https://migue-iphones.vercel.app/#'; 
    const webhookUrl = 'https://ilwxrxcpwbzwhpmyeyln.supabase.co/functions/v1/mp-webhook-receiver';

    const result = await preference.create({
      body: {
        items: mpItems,
        payer: { email: payer_email },
        external_reference: newOrder.id,
        back_urls: {
          success: `${baseUrl}/success`,
          failure: `${baseUrl}/failure`,
          pending: `${baseUrl}/pending`,
        },
        auto_return: 'approved',
        notification_url: webhookUrl // VITAL
      }
    });

    return new Response(
      JSON.stringify({ order_id: newOrder.id, preference_id: result.id, init_point: result.init_point }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    console.error("💥 [CreatePref] Error:", error);
    return new Response(JSON.stringify({ error: error.message }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 })
  }
});