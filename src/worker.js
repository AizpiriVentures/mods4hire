// Mods4Hire — Cloudflare Worker
export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === '/api/contact' && request.method === 'POST') {
      try {
        const { name, email, message } = await request.json();
        if (!name || !email || !message) {
          return new Response(JSON.stringify({ error: 'All fields required' }), {
            status: 400, headers: { 'Content-Type': 'application/json' }
          });
        }

        const res = await fetch('https://api.resend.com/emails', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${env.RESEND_API_KEY}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            from: 'no-reply@fasttracklaunch.com',
            to: env.CONTACT_EMAIL || 'contact@fasttracklaunch.com',
            subject: `Mods4Hire contact from ${name}`,
            html: `<p><strong>Name:</strong> ${name}</p><p><strong>Email:</strong> ${email}</p><p><strong>Message:</strong></p><p>${message.replace(/\n/g,'<br>')}</p><hr><p style="font-size:12px;color:#888;">Powered by FastTrackLaunch, helping bring ideas to life!</p>`
          })
        });

        if (!res.ok) {
          return new Response(JSON.stringify({ error: 'Failed to send' }), {
            status: 500, headers: { 'Content-Type': 'application/json' }
          });
        }

        return new Response(JSON.stringify({ ok: true }), {
          status: 200, headers: { 'Content-Type': 'application/json' }
        });
      } catch (e) {
        return new Response(JSON.stringify({ error: e.message }), {
          status: 500, headers: { 'Content-Type': 'application/json' }
        });
      }
    }

    return env.ASSETS.fetch(request);
  }
};
