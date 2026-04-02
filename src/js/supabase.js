// Mods4Hire — Supabase client (anon key only — never expose service role key client-side)
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const SUPABASE_URL = window.__ENV__?.SUPABASE_URL || 'REPLACE_WITH_YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = window.__ENV__?.SUPABASE_ANON_KEY || 'REPLACE_WITH_YOUR_SUPABASE_ANON_KEY';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

export function showToast(message, type = 'success') {
  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.textContent = message;
  document.body.appendChild(toast);
  setTimeout(() => toast.remove(), 3500);
}

export function setLoading(btn, isLoading) {
  if (isLoading) {
    btn.dataset.originalText = btn.textContent;
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner"></span>';
  } else {
    btn.disabled = false;
    btn.textContent = btn.dataset.originalText || '';
  }
}

export function escapeHtml(str) {
  if (!str) return '';
  return String(str).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');
}
