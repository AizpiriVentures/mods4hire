// Mods4Hire — Job listing CRUD and rendering
import { supabase, escapeHtml } from './supabase.js';

export async function getListings({ page = 0, pageSize = 12, platform, compensation } = {}) {
  let q = supabase
    .from('job_listings')
    .select('id, title, platform, hours_per_week, compensation_type, community_type, deadline, created_at, profiles:hirer_id(username)')
    .eq('status', 'open')
    .order('created_at', { ascending: false })
    .range(page * pageSize, (page + 1) * pageSize - 1);

  if (platform) q = q.contains('platform', [platform]);
  if (compensation) q = q.eq('compensation_type', compensation);

  const { data, error } = await q;
  if (error) throw error;
  return data;
}

export async function getListing(id) {
  const { data, error } = await supabase
    .from('job_listings')
    .select('*, profiles:hirer_id(id, username, rating_avg, rating_count)')
    .eq('id', id)
    .single();
  if (error) throw error;
  return data;
}

export async function createListing(listing) {
  const { data, error } = await supabase.from('job_listings').insert(listing).select().single();
  if (error) throw error;
  return data;
}

const COMP_LABELS = { paid_hourly: 'Paid (Hourly)', monthly_retainer: 'Monthly Retainer', volunteer: 'Volunteer' };
const COMP_COLORS = { paid_hourly: 'text-green-700 bg-green-50', monthly_retainer: 'text-blue-700 bg-blue-50', volunteer: 'text-gray-600 bg-gray-100' };

export function renderListingCard(listing) {
  const div = document.createElement('div');
  div.className = 'listing-card bg-white border border-gray-200 rounded-xl p-5 cursor-pointer';
  div.innerHTML = `
    <div class="flex items-start justify-between mb-2">
      <h3 class="font-semibold text-gray-900 text-base">${escapeHtml(listing.title)}</h3>
      <span class="ml-2 shrink-0 text-xs px-2 py-0.5 rounded ${COMP_COLORS[listing.compensation_type] || ''}">${COMP_LABELS[listing.compensation_type] || listing.compensation_type}</span>
    </div>
    <div class="flex flex-wrap gap-1 mb-3">
      ${(listing.platform||[]).map(p=>`<span class="text-xs bg-sky-50 text-sky-700 px-2 py-0.5 rounded">${escapeHtml(p)}</span>`).join('')}
    </div>
    <div class="flex items-center justify-between text-xs text-gray-400">
      <span>${listing.hours_per_week ? listing.hours_per_week + ' hrs/week' : ''}</span>
      <span>by ${escapeHtml(listing.profiles?.username || '—')}</span>
    </div>
  `;
  div.addEventListener('click', () => { window.location.href = `/listing.html?id=${listing.id}`; });
  return div;
}
