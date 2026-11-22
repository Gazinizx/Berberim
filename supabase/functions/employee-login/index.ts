import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}

function serverKey(): string {
  const encoded = Deno.env.get("SUPABASE_SECRET_KEYS");
  if (encoded) {
    try {
      const parsed = JSON.parse(encoded);
      if (typeof parsed.default === "string") return parsed.default;
    } catch { /* use legacy injected key below */ }
  }
  return Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
}

function publishableKey(): string {
  const encoded = Deno.env.get("SUPABASE_PUBLISHABLE_KEYS");
  if (encoded) {
    try {
      const parsed = JSON.parse(encoded);
      if (typeof parsed.default === "string") return parsed.default;
    } catch { /* use legacy injected key below */ }
  }
  return Deno.env.get("SUPABASE_ANON_KEY") ?? "";
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    const url = Deno.env.get("SUPABASE_URL") ?? "";
    const secret = serverKey();
    const publicKey = publishableKey();
    if (!url || !secret || !publicKey) return json({ error: "Giriş hizmeti şu anda kullanılamıyor" }, 503);

    const body = await request.json().catch(() => ({}));
    const username = typeof body.username === "string" ? body.username.trim().normalize("NFC").toLocaleLowerCase("tr-TR") : "";
    const password = typeof body.password === "string" ? body.password : "";
    if (!username.includes("@") || username.length > 100 || /[%_\\s]/u.test(username) || password.length < 1 || password.length > 72) {
      return json({ error: "Kullanıcı adı veya şifre hatalı" }, 401);
    }

    const admin = createClient(url, secret, { auth: { persistSession: false, autoRefreshToken: false } });
    const { data: account, error: accountError } = await admin.from("employee_login_accounts")
      .select("employee_id,auth_email").eq("login_username", username).maybeSingle();
    if (accountError) throw accountError;

    let email = crypto.randomUUID().replaceAll("-", "") + "@invalid.staff.berberim.app";
    if (account) {
      const { data: employee, error: employeeError } = await admin.from("employees")
        .select("id,is_active,user_id").eq("id", account.employee_id).maybeSingle();
      if (employeeError) throw employeeError;
      if (employee?.is_active === true && employee.user_id) email = account.auth_email;
    }

    const auth = createClient(url, publicKey, { auth: { persistSession: false, autoRefreshToken: false } });
    const { data, error } = await auth.auth.signInWithPassword({ email, password });
    if (error || !data.session) return json({ error: "Kullanıcı adı veya şifre hatalı" }, 401);

    return json({ access_token: data.session.access_token, refresh_token: data.session.refresh_token });
  } catch (error) {
    console.error("Berberim employee login failed:", error);
    return json({ error: "Giriş yapılamadı. Tekrar dene." }, 500);
  }
});
