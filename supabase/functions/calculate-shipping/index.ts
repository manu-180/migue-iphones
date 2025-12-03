// supabase/functions/calculate-shipping/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};
serve(async (req)=>{
  // 1. Manejo de CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: corsHeaders
    });
  }
  try {
    console.log(`📨 Método recibido: ${req.method}`);
    // 2. Leer el cuerpo como TEXTO primero para evitar el crash
    const bodyText = await req.text();
    if (!bodyText) {
      console.error("❌ Error: El cuerpo de la petición llegó vacío.");
      return new Response(JSON.stringify({
        error: "El cuerpo de la petición está vacío"
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    // Ahora sí parseamos el JSON de forma segura
    const { zip_code, province, packages } = JSON.parse(bodyText);
    console.log(`📦 Datos recibidos - CP: ${zip_code}, Paquetes: ${packages?.length}`);
    // ---------------------------------------------------------
    // MOCK DE COTIZACIÓN (Igual que antes)
    // ---------------------------------------------------------
    await new Promise((resolve)=>setTimeout(resolve, 500));
    let totalWeight = 0;
    // Validación segura por si packages es undefined
    if (packages && Array.isArray(packages)) {
      packages.forEach((p)=>{
        totalWeight += p.weight * p.quantity;
      });
    }
    const basePrice = 4500;
    const pricePerKg = 500;
    const finalPrice = basePrice + totalWeight * pricePerKg;
    const rates = [
      {
        correo: "Correo Argentino",
        servicio: "Clásico a Domicilio",
        precio: finalPrice,
        horas_min: 72,
        horas_max: 144
      },
      {
        correo: "Andreani",
        servicio: "Estándar",
        precio: finalPrice * 1.2,
        horas_min: 48,
        horas_max: 96
      },
      {
        correo: "Andreani",
        servicio: "Urgente",
        precio: finalPrice * 1.6,
        horas_min: 24,
        horas_max: 48
      }
    ];
    // 3. Devolver respuesta
    return new Response(JSON.stringify({
      rates
    }), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      },
      status: 200
    });
  } catch (error) {
    console.error("❌ Error general en la función:", error);
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
