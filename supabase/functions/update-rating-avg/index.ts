// Mods4Hire — Edge Function: manual rating avg recalculation (DB trigger handles realtime)
// Deploy: supabase functions deploy update-rating-avg

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req) => {
  try {
    const { user_id } = await req.json();
    const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
    const { data: ratings } = await supabase.from('ratings').select('reliability,communication,judgment,professionalism').eq('ratee_id', user_id);
    if (!ratings?.length) return new Response(JSON.stringify({ ok: true }), { headers: { 'Content-Type': 'application/json' } });
    const avg = ratings.reduce((s, r) => s + (r.reliability + r.communication + r.judgment + r.professionalism) / 4, 0) / ratings.length;
    await supabase.from('profiles').update({ rating_avg: avg.toFixed(2), rating_count: ratings.length }).eq('id', user_id);
    return new Response(JSON.stringify({ ok: true, avg }), { headers: { 'Content-Type': 'application/json' } });
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: { 'Content-Type': 'application/json' } });
  }
});
