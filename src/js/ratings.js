// Mods4Hire — Ratings (only unlocked after confirmed engagement — enforced by DB policy)
import { supabase } from './supabase.js';

export async function submitRating({ rateeId, listingId, reliability, communication, judgment, professionalism, comment }) {
  const { data, error } = await supabase.from('ratings').insert({
    ratee_id: rateeId,
    listing_id: listingId,
    reliability,
    communication,
    judgment,
    professionalism,
    comment: comment?.trim().slice(0, 500) || '',
  }).select().single();
  if (error) throw error;
  return data;
}

export async function getRatingsForUser(userId) {
  const { data, error } = await supabase
    .from('ratings')
    .select('*, rater:rater_id(username)')
    .eq('ratee_id', userId)
    .order('created_at', { ascending: false });
  if (error) throw error;
  return data;
}
