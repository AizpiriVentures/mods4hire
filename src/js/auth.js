// Mods4Hire — Auth helpers
import { supabase } from './supabase.js';

export async function getUser() {
  const { data: { user } } = await supabase.auth.getUser();
  return user;
}

export async function requireAuth() {
  const user = await getUser();
  if (!user) { window.location.href = '/login.html'; return null; }
  return user;
}

export async function signIn(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw error;
  return data;
}

export async function signUp(email, password, username, role) {
  const { data: existing } = await supabase.from('profiles').select('id').eq('username', username).maybeSingle();
  if (existing) throw new Error('Username already taken');

  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: { data: { username, role } }
  });
  if (error) throw error;
  return data;
}

export async function signOut() {
  await supabase.auth.signOut();
  window.location.href = '/login.html';
}

export async function updateNavAuth() {
  const user = await getUser();
  const el = document.getElementById('auth-links');
  if (!el) return;
  if (user) {
    el.innerHTML = `<a href="/dashboard.html" class="text-sm text-sky-600 hover:underline">Dashboard</a>
      <button id="sign-out-btn" class="text-sm text-red-500 hover:text-red-700">Sign Out</button>`;
    document.getElementById('sign-out-btn')?.addEventListener('click', signOut);
  } else {
    el.innerHTML = `<a href="/login.html" class="text-sm text-gray-600 hover:text-sky-600 transition-colors">Log In</a>
      <a href="/login.html#register" class="text-sm text-gray-600 hover:text-sky-600 transition-colors">Sign Up</a>`;
  }
}
