// Mods4Hire — Job listing CRUD and rendering
import { supabase, escapeHtml } from './supabase.js';

export async function getListings({ page = 0, pageSize = 12, platform, compensation, minRating, maxHours, hasDeadline, sortBy = 'newest' } = {}) {
  const orderMap = {
    newest:   { col: 'created_at', asc: false },
    oldest:   { col: 'created_at', asc: true },
    deadline: { col: 'deadline',   asc: true },
  };
  const { col, asc } = orderMap[sortBy] || orderMap.newest;

  let q = supabase
    .from('job_listings')
    .select('id, title, platform, hours_per_week, compensation_type, community_type, deadline, created_at, profiles:hirer_id(username, rating_avg, rating_count)')
    .eq('status', 'open')
    .order(col, { ascending: asc })
    .range(page * pageSize, (page + 1) * pageSize - 1);

  if (platform)    q = q.contains('platform', [platform]);
  if (compensation) q = q.eq('compensation_type', compensation);
  if (maxHours)    q = q.lte('hours_per_week', parseInt(maxHours));
  if (hasDeadline) q = q.not('deadline', 'is', null);

  const { data, error } = await q;
  if (error) throw error;

  // Rating filter applied client-side (can't filter on joined column server-side)
  if (minRating) {
    return (data || []).filter(l => (l.profiles?.rating_avg ?? 0) >= parseFloat(minRating));
  }
  return data || [];
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

const COMP_LABELS = { paid_hourly: 'Hourly', monthly_retainer: 'Monthly Retainer', salary: 'Salary', volunteer: 'Volunteer Mods' };
const COMP_COLORS = { paid_hourly: 'text-green-700 bg-green-50', monthly_retainer: 'text-blue-700 bg-blue-50', salary: 'text-emerald-700 bg-emerald-50', volunteer: 'text-gray-600 bg-gray-100' };

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
      <span>
        by ${escapeHtml(listing.profiles?.username || '—')}
        ${listing.profiles?.rating_count > 0 ? `<span class="ml-1 text-yellow-500">⭐ ${Number(listing.profiles.rating_avg).toFixed(1)}</span>` : ''}
      </span>
    </div>
  `;
  div.addEventListener('click', () => { window.location.href = `/listing.html?id=${listing.id}`; });
  return div;
}
