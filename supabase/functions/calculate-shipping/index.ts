import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
const corsHeaders = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type' };

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  const rates = [
      { correo: "Correo Argentino", servicio: "Clásico", precio: 4500, horas_min: 72, horas_max: 144 },
      { correo: "Andreani", servicio: "Estándar", precio: 5800, horas_min: 48, horas_max: 96 }
  ];
  return new Response(JSON.stringify({ rates }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 });
});