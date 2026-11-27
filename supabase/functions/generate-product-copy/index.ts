import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "https://ajesencias.github.io",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Método no permitido." }, 405);

  try {
    const authHeader = req.headers.get("Authorization") || "";
    const token = authHeader.replace(/^Bearer\s+/i, "");
    if (!token) return json({ error: "Inicia sesión para usar el generador." }, 401);

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const openaiKey = Deno.env.get("OPENAI_API_KEY");
    if (!supabaseUrl || !anonKey || !openaiKey) {
      return json({ error: "Falta configurar la función o la clave privada de IA en Supabase." }, 503);
    }

    const supabase = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: `Bearer ${token}` } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user || String(user.email || "").toLowerCase() !== "ambardilone06@gmail.com") {
      return json({ error: "No tienes autorización para generar textos." }, 403);
    }

    const body = await req.json();
    const name = String(body.name || "").trim().slice(0, 160);
    const category = String(body.category || "").trim().slice(0, 120);
    const description = String(body.description || "").trim().slice(0, 1200);
    const notes = String(body.notes || "").trim().slice(0, 1200);
    if (!name) return json({ error: "El producto necesita un nombre." }, 400);

    const prompt = `Eres redactor experto en perfumería y cosmética para AJ ESENCIAS, tienda de República Dominicana. Redacta en español natural y tono comercial refinado. Devuelve exclusivamente un JSON válido con las claves "description" y "olfactoryNotes". La descripción debe tener máximo 55 palabras y explicar qué es el producto usando solo información sustentada. Las notas olfativas deben tener máximo 40 palabras. Producto: ${name}. Categoría: ${category || "No especificada"}. Descripción/datos aportados: ${description || "No suministrados"}. Notas conocidas: ${notes || "No suministradas"}. No inventes ingredientes, beneficios, composición, concentración, notas olfativas ni afirmaciones del fabricante. Si no hay datos fiables para notas, indica "Notas por confirmar". Si no aplica por ser un producto no perfumado, indica "No aplica".`;

    const aiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${openaiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        temperature: 0.5,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: "Responde únicamente con JSON válido. No inventes datos de producto." },
          { role: "user", content: prompt },
        ],
      }),
    });

    const result = await aiResponse.json();
    if (!aiResponse.ok) {
      console.error("OpenAI API error", result?.error?.type || aiResponse.status);
      return json({ error: "El servicio de IA no pudo generar el texto. Verifica la clave y el saldo del servicio." }, 502);
    }
    const content = result?.choices?.[0]?.message?.content;
    if (!content) return json({ error: "La IA no devolvió una propuesta. Inténtalo de nuevo." }, 502);
    const parsed = JSON.parse(content);
    return json({
      description: String(parsed.description || "").slice(0, 1200),
      olfactoryNotes: String(parsed.olfactoryNotes || "").slice(0, 1200),
    });
  } catch (error) {
    console.error("generate-product-copy failed", error);
    return json({ error: "Ocurrió un error al generar el texto. Inténtalo nuevamente." }, 500);
  }
});
