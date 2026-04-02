// Mods4Hire — Edge Function: notify hirer when moderator applies
// Deploy: supabase functions deploy send-application-email

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';

serve(async (req) => {
  try {
    const { record } = await req.json();
    const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');
    if (!RESEND_API_KEY) throw new Error('RESEND_API_KEY not set');
    // TODO: look up hirer email and send via Resend API
    console.log('New application:', record.id);
    return new Response(JSON.stringify({ ok: true }), { headers: { 'Content-Type': 'application/json' } });
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: { 'Content-Type': 'application/json' } });
  }
});
