// Mods4Hire — Ratings
import { supabase } from './supabase.js';

export async function submitRating({ rateeId, reliability, communication, judgment, professionalism, comment }) {
  const { data, error } = await supabase.from('ratings').insert({
    ratee_id: rateeId,
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
