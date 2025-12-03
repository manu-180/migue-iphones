import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { MercadoPagoConfig, Payment } from 'npm:mercadopago';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.8';

const corsHeaders = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type' };

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, 
  { auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false } }
);

const client = new MercadoPagoConfig({ accessToken: Deno.env.get('MP_ACCESS_TOKEN') || '' });

serve(async (req)=>{
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const body = await req.json();
    const { transaction_amount, token, description, payment_method_id, issuer_id, external_reference, installments, payer } = body;
    const payerEmail = payer?.email || body.email || 'unknown@pulpiprint.com';
    
    const payment = new Payment(client);
    const webhookUrl = 'https://ilwxrxcpwbzwhpmyeyln.supabase.co/functions/v1/mp-webhook-receiver';

    const paymentData = {
      transaction_amount: Number(transaction_amount),
      token: token,
      description: description || 'Compra en PulpiPrint',
      installments: Number(installments),
      payment_method_id: payment_method_id,
      issuer_id: issuer_id,
      payer: { email: payerEmail },
      external_reference: external_reference,
      notification_url: webhookUrl 
    };

    const result = await payment.create({ body: paymentData });

    if (external_reference) {
      await supabase.from('orders_pulpiprint').update({
        status: result.status === 'approved' ? 'approved' : 'pending',
        mp_payment_id: Number(result.id)
      }).eq('id', external_reference);
    }

    return new Response(JSON.stringify({ status: result.status, id: result.id }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 });
  }
});