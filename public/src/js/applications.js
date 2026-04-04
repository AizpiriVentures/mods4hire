// Mods4Hire — Application handling
import { supabase } from './supabase.js';

export async function applyToListing(listingId, pitch) {
  const { data, error } = await supabase.from('applications').insert({
    listing_id: listingId,
    pitch: pitch?.trim().slice(0, 1000) || '',
  }).select().single();
  if (error) throw error;
  return data;
}

export async function getMyApplications() {
  const { data, error } = await supabase
    .from('applications')
    .select('*, job_listings(id, title, status)')
    .order('applied_at', { ascending: false });
  if (error) throw error;
  return data;
}

export async function updateApplicationStatus(applicationId, status) {
  const { error } = await supabase.from('applications').update({ status }).eq('id', applicationId);
  if (error) throw error;
}
