// Rider Group — tableau de bord web de l'équipe (Mission 11).
//
// Site statique (GitHub Pages). Toutes les données passent par les fonctions
// Supabase réservées aux administrateurs Rider Group : la protection est côté
// serveur (private.is_platform_admin), jamais dans ce fichier. Seule la clé
// publique (publishable) est utilisée ici.
// Tout texte venant de la base est inséré avec textContent (jamais innerHTML).
'use strict';

const cfg = window.RIDER_CONFIG || {};
const db = window.supabase.createClient(cfg.url, cfg.key, {
  auth: { persistSession: true, autoRefreshToken: true },
});

// --- Petits outils -----------------------------------------------------------
function h(tag, attrs, ...children) {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs || {})) {
    if (v === null || v === undefined || v === false) continue;
    if (k.startsWith('on')) el.addEventListener(k.slice(2), v);
    else if (k === 'class') el.className = v;
    else if (v === true) el.setAttribute(k, '');
    else el.setAttribute(k, v);
  }
  for (const c of children.flat()) {
    if (c === null || c === undefined || c === false) continue;
    el.append(c instanceof Node ? c : document.createTextNode(String(c)));
  }
  return el;
}
const $ = (sel) => document.querySelector(sel);
const fmtDate = (v) => (v ? new Date(v).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' }) : '—');
const fmtDateTime = (v) => (v ? new Date(v).toLocaleString('fr-FR', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' }) : '—');
const fmtNum = (v) => (v === null || v === undefined ? '—' : Number(v).toLocaleString('fr-FR'));
const MONTHS = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
const monthLabel = (p) => `${MONTHS[Number(p.slice(5, 7)) - 1]} ${p.slice(0, 4)}`;

const ERRORS = {
  not_allowed: "Action non autorisée (compte non administrateur ?).",
  invalid_input: 'Vérifiez les informations saisies.',
  already_exists: 'Déjà fait pour cette période.',
  not_authenticated: 'Session expirée : reconnectez-vous.',
};
function errorText(e) {
  const msg = (e && (e.message || e.error_description)) || String(e);
  for (const [code, text] of Object.entries(ERRORS)) if (msg.includes(code)) return text;
  return msg;
}
let toastTimer;
function toast(text) {
  const t = $('#toast');
  t.textContent = text;
  t.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => t.classList.remove('show'), 3500);
}
async function rpc(fn, params) {
  const { data, error } = await db.rpc(fn, params || {});
  if (error) throw error;
  return data;
}
// Lance une action ; bouton désactivé pendant l'appel ; message et rafraîchissement.
async function act(button, fn, done) {
  if (button) button.disabled = true;
  try {
    await fn();
    if (done) toast(done);
    await refreshCounts();
    await render();
  } catch (e) {
    toast(errorText(e));
    if (button) button.disabled = false;
  }
}
const ask = (text, value) => window.prompt(text, value ?? '');

// --- Connexion ---------------------------------------------------------------
async function start() {
  if (!cfg.url || !cfg.key) {
    document.body.textContent = 'Configuration manquante (config.js).';
    return;
  }
  const { data } = await db.auth.getSession();
  if (data.session) await enter(data.session);
  else showLogin();
}
function showLogin(message) {
  $('#app').hidden = true;
  $('#login').hidden = false;
  $('#login-error').textContent = message || '';
}
$('#login-form').addEventListener('submit', async (ev) => {
  ev.preventDefault();
  $('#login-error').textContent = '';
  const { data, error } = await db.auth.signInWithPassword({
    email: $('#login-email').value.trim(),
    password: $('#login-password').value,
  });
  if (error) return showLogin('Adresse ou mot de passe incorrect.');
  await enter(data.session);
});
$('#logout').addEventListener('click', async () => {
  await db.auth.signOut();
  showLogin();
});
async function enter(session) {
  let admin = false;
  try { admin = await rpc('am_i_platform_admin'); } catch (_) { admin = false; }
  if (!admin) {
    await db.auth.signOut();
    return showLogin("Ce compte n'est pas administrateur Rider Group.");
  }
  $('#login').hidden = true;
  $('#app').hidden = false;
  $('#who').textContent = session.user.email || '';
  await refreshCounts();
  await render();
}

// --- Navigation --------------------------------------------------------------
const VIEWS = {};
const currentView = () => (location.hash.slice(1) || 'vue');
window.addEventListener('hashchange', () => render());
async function render() {
  const name = VIEWS[currentView()] ? currentView() : 'vue';
  document.querySelectorAll('.sidebar a').forEach((a) => {
    if (a.dataset.view === name) a.setAttribute('aria-current', 'page');
    else a.removeAttribute('aria-current');
  });
  const main = $('#main');
  main.replaceChildren(h('p', { class: 'muted' }, 'Chargement…'));
  try {
    const content = await VIEWS[name]();
    main.replaceChildren(...[content].flat(Infinity).filter(Boolean));
  } catch (e) {
    main.replaceChildren(h('div', { class: 'card' }, h('h2', {}, 'Erreur'), h('p', { class: 'error' }, errorText(e))));
  }
}
let stats = {};
async function refreshCounts() {
  try { stats = await rpc('admin_stats'); } catch (_) { stats = {}; }
  const set = (k, n) => { const el = document.querySelector(`[data-count="${k}"]`); if (el) el.textContent = n > 0 ? n : ''; };
  set('verifications', (stats.pending_club_verifications || 0) + (stats.pending_rider_verifications || 0));
  set('signalements', stats.open_reports || 0);
  set('suppressions', stats.pending_club_deletions || 0);
  set('retours', stats.open_feedback || 0);
}
const header = (title, sub) => h('header', {}, h('h1', {}, title), sub ? h('p', { class: 'muted' }, sub) : null);
const empty = (text) => h('p', { class: 'empty' }, text);

// --- Vue d'ensemble ----------------------------------------------------------
VIEWS.vue = async () => {
  const s = stats;
  const stat = (label, value, sub, danger) =>
    h('div', { class: `card stat${danger ? ' danger' : ''}` }, h('span', { class: 'muted' }, label), h('strong', {}, fmtNum(value)), sub ? h('span', { class: 'muted' }, sub) : null);
  const todo = (label, n, view, extra) =>
    h('div', { class: 'list-item' }, h('span', { class: 'grow' }, h('strong', {}, `${n} ${label}`), extra ? ` · ${extra}` : ''),
      h('a', { class: 'btn dark', href: `#${view}`, style: 'display:flex;align-items:center;text-decoration:none' }, 'Examiner'));
  return [
    header("Vue d'ensemble", 'Chiffres réels de la base, à l\'ouverture.'),
    h('section', { class: 'grid', 'aria-label': 'Chiffres clés' },
      stat('Motards inscrits', s.riders_total, `+${fmtNum(s.riders_new_7d)} en 7 jours`),
      stat('Connectés sur 7 jours', s.active_7d),
      stat('Balades ce mois-ci', s.rides_month, `dont ${fmtNum(s.rides_finished_month)} terminées`),
      stat('Alertes SOS ce mois-ci', s.sos_month, `${fmtNum(s.sos_active)} active(s) en ce moment`, s.sos_active > 0),
      stat('Défis en cours', s.active_challenges),
      stat('Comptes suspendus', s.suspended_accounts)),
    h('section', { class: 'card' }, h('h2', {}, 'À traiter'),
      todo('signalement(s)', s.open_reports || 0, 'signalements'),
      todo('demande(s) de vérification', (s.pending_club_verifications || 0) + (s.pending_rider_verifications || 0), 'verifications',
        `${s.pending_club_verifications || 0} club(s), ${s.pending_rider_verifications || 0} motard(s)`),
      todo('suppression(s) de club vérifié', s.pending_club_deletions || 0, 'suppressions'),
      todo('retour(s) de motards', s.open_feedback || 0, 'retours')),
  ];
};

// --- Vérifications -------------------------------------------------------------
async function docLinks(paths) {
  const out = [];
  for (const p of paths || []) {
    const { data } = await db.storage.from('verification-docs').createSignedUrl(p, 600);
    if (data) out.push(h('a', { href: data.signedUrl, target: '_blank', rel: 'noopener' }, `Document ${out.length + 1}`));
  }
  return out.length ? h('div', { class: 'row' }, out) : null;
}
function durationPicker() {
  const sel = h('select', { 'aria-label': 'Durée du badge' },
    h('option', { value: '1' }, '1 mois'), h('option', { value: '6' }, '6 mois'), h('option', { value: '12', selected: true }, '12 mois'));
  sel.until = () => { const d = new Date(); d.setMonth(d.getMonth() + Number(sel.value)); return d.toISOString(); };
  return sel;
}
VIEWS.verifications = async () => {
  const [clubs, riders] = await Promise.all([rpc('verification_queue'), rpc('rider_verification_queue')]);
  const clubCards = await Promise.all(clubs.filter((r) => r.status === 'pending').map(async (r) => {
    const dur = durationPicker();
    return h('article', { class: 'card' },
      h('div', { class: 'row' }, h('span', { class: 'tag blue' }, 'Club / regroupement'), h('span', { class: 'muted' }, fmtDateTime(r.created_at))),
      h('h3', {}, r.club_name), h('p', {}, `Nom officiel : ${r.official_name || '—'} · Responsable : ${r.contact_name || '—'} · WhatsApp : ${r.contact_phone || '—'} · ${r.club_city || ''}`),
      r.message ? h('blockquote', {}, r.message) : null, await docLinks(r.document_paths),
      h('div', { class: 'row' }, dur,
        h('button', { class: 'btn primary', type: 'button', onclick: (e) => act(e.target, () => rpc('review_club_verification', { p_request_id: r.request_id, p_approve: true, p_valid_until: dur.until() }), 'Club vérifié.') }, 'Valider'),
        h('button', { class: 'btn', type: 'button', onclick: (e) => { const note = ask('Raison du refus (envoyée au club) :'); if (note) act(e.target, () => rpc('review_club_verification', { p_request_id: r.request_id, p_approve: false, p_note: note }), 'Demande refusée.'); } }, 'Refuser')));
  }));
  const riderCards = await Promise.all(riders.filter((r) => r.status === 'pending').map(async (r) => {
    const dur = durationPicker();
    return h('article', { class: 'card' },
      h('div', { class: 'row' }, h('span', { class: 'tag' }, 'Motard'), h('span', { class: 'muted' }, fmtDateTime(r.created_at))),
      h('h3', {}, `${r.display_name} (@${r.username})`), h('p', {}, `Nom réel : ${r.real_name || '—'} · WhatsApp : ${r.contact_phone || '—'}`),
      r.message ? h('blockquote', {}, r.message) : null, await docLinks(r.document_paths),
      h('div', { class: 'row' }, dur,
        h('button', { class: 'btn primary', type: 'button', onclick: (e) => act(e.target, () => rpc('review_rider_verification', { p_request_id: r.request_id, p_approve: true, p_valid_until: dur.until() }), 'Motard vérifié.') }, 'Valider'),
        h('button', { class: 'btn', type: 'button', onclick: (e) => { const note = ask('Raison du refus (envoyée au motard) :'); if (note) act(e.target, () => rpc('review_rider_verification', { p_request_id: r.request_id, p_approve: false, p_note: note }), 'Demande refusée.'); } }, 'Refuser')));
  }));
  return [header('Vérifications', 'Clubs, regroupements et motards. Aucun paiement dans l\'application.'),
    h('h2', {}, 'Clubs et regroupements'), clubCards.length ? clubCards : empty('Aucune demande.'),
    h('h2', {}, 'Motards'), riderCards.length ? riderCards : empty('Aucune demande.')];
};

// --- Signalements ------------------------------------------------------------
const TARGETS = { post: 'Publication', comment: 'Commentaire', message: 'Message', user: 'Profil', listing: 'Annonce' };
const REASONS = { spam: 'Spam', harassment: 'Harcèlement', hate: 'Haine', violence: 'Violence', nudity: 'Nudité', scam: 'Arnaque', other: 'Autre' };
function suspendButton(userId, name) {
  return h('button', { class: 'btn danger', type: 'button', onclick: (e) => suspendFlow(e.target, userId, name) }, 'Suspendre le compte…');
}
function suspendFlow(button, userId, name) {
  const days = ask(`Suspendre ${name} : durée en jours (7, 30…) ou « 0 » pour sans fin :`);
  if (days === null) return;
  const n = Number(days);
  if (!Number.isInteger(n) || n < 0) return toast('Durée invalide.');
  const reason = ask('Raison (envoyée au motard, 3 caractères au moins) :');
  if (!reason) return;
  act(button, () => rpc('admin_suspend_user', { p_user_id: userId, p_days: n === 0 ? null : n, p_reason: reason }), 'Compte suspendu.');
}
VIEWS.signalements = async () => {
  const items = await rpc('moderation_queue');
  const cards = items.map((r) => h('article', { class: 'card' },
    h('div', { class: 'row' }, h('span', { class: 'tag' }, TARGETS[r.target_type] || r.target_type),
      h('span', { class: 'muted' }, `${r.report_count} signalement(s) · ${(r.reasons || []).map((x) => REASONS[x] || x).join(', ')} · ${fmtDateTime(r.last_reported_at)}`),
      r.moderation === 'hidden' ? h('span', { class: 'tag red' }, 'Masqué') : null),
    r.preview ? h('blockquote', {}, r.preview) : null,
    h('p', { class: 'muted' }, `Auteur : ${r.author_name || '—'}`),
    h('div', { class: 'row' },
      r.target_type !== 'user' && r.moderation !== 'hidden'
        ? h('button', { class: 'btn dark', type: 'button', onclick: (e) => act(e.target, () => rpc('moderate_content', { p_target: r.target_type, p_target_id: r.target_id, p_action: 'hide' }), 'Contenu masqué.') }, 'Masquer') : null,
      r.moderation === 'hidden'
        ? h('button', { class: 'btn', type: 'button', onclick: (e) => act(e.target, () => rpc('moderate_content', { p_target: r.target_type, p_target_id: r.target_id, p_action: 'restore' }), 'Contenu rétabli.') }, 'Rétablir') : null,
      r.author_id ? suspendButton(r.author_id, r.author_name || 'ce motard') : null,
      h('button', { class: 'btn', type: 'button', onclick: (e) => act(e.target, () => rpc('moderate_content', { p_target: r.target_type, p_target_id: r.target_id, p_action: 'dismiss' }), 'Signalement classé.') }, 'Rien à signaler'))));
  return [header('Signalements', 'Publications, commentaires, messages, annonces et profils signalés.'), cards.length ? cards : empty('Aucun signalement à traiter.')];
};

// --- Comptes -----------------------------------------------------------------
VIEWS.comptes = async () => {
  const suspended = await rpc('admin_suspended_users');
  const results = h('div', {});
  const input = h('input', { type: 'search', placeholder: 'Pseudo ou nom (2 lettres au moins)', 'aria-label': 'Chercher un compte' });
  let timer;
  input.addEventListener('input', () => {
    clearTimeout(timer);
    timer = setTimeout(async () => {
      try {
        const rows = await rpc('admin_search_users', { p_query: input.value });
        results.replaceChildren(...(rows.length ? rows.map((u) => h('div', { class: 'list-item' },
          h('span', { class: 'grow' }, h('strong', {}, u.display_name), ` @${u.username} · ${u.city || '—'} · inscrit le ${fmtDate(u.created_at)}`,
            u.verified ? h('span', { class: 'tag green', style: 'margin-left:8px' }, 'Vérifié') : null,
            u.suspended ? h('span', { class: 'tag red', style: 'margin-left:8px' }, 'Suspendu') : null),
          u.suspended
            ? h('button', { class: 'btn', type: 'button', onclick: (e) => act(e.target, () => rpc('admin_unsuspend_user', { p_user_id: u.id }), 'Suspension levée.') }, 'Lever la suspension')
            : suspendButton(u.id, u.display_name))) : [empty('Aucun compte.')]));
      } catch (e) { toast(errorText(e)); }
    }, 300);
  });
  return [header('Comptes', 'Un compte suspendu peut lire et utiliser le SOS, mais pas publier, écrire ni rejoindre de balade.'),
    h('section', { class: 'card' }, h('h2', {}, 'Chercher un compte'), input, results),
    h('section', { class: 'card' }, h('h2', {}, 'Comptes suspendus'),
      suspended.length ? suspended.map((u) => h('div', { class: 'list-item' },
        h('span', { class: 'grow' }, h('strong', {}, u.display_name), ` @${u.username} · ${u.until ? `jusqu'au ${fmtDate(u.until)}` : 'sans fin'} · ${u.reason}`),
        h('button', { class: 'btn', type: 'button', onclick: (e) => act(e.target, () => rpc('admin_unsuspend_user', { p_user_id: u.user_id }), 'Suspension levée.') }, 'Lever la suspension'))) : empty('Aucun compte suspendu.'))];
};

// --- Suppressions de clubs ---------------------------------------------------
VIEWS.suppressions = async () => {
  const items = await rpc('club_deletion_queue');
  return [header('Suppressions de clubs vérifiés', 'Sans décision, le club est supprimé automatiquement à la date indiquée.'),
    items.length ? items.map((r) => h('article', { class: 'card' },
      h('h3', {}, r.club_name), h('p', { class: 'muted' }, `${r.is_regroupement ? 'Regroupement' : 'Club'} · ${r.club_city || ''} · ${r.member_count} membre(s) · demandé par ${r.requester_name || '—'} le ${fmtDate(r.created_at)}`),
      h('blockquote', {}, r.reason), h('p', {}, h('strong', {}, `Suppression automatique le ${fmtDate(r.due_at)}`)),
      h('div', { class: 'row' },
        h('button', { class: 'btn danger', type: 'button', onclick: (e) => { if (confirm(`Supprimer définitivement ${r.club_name} ?`)) act(e.target, () => rpc('review_club_deletion', { p_request_id: r.request_id, p_approve: true }), 'Club supprimé.'); } }, 'Supprimer'),
        h('button', { class: 'btn', type: 'button', onclick: (e) => { const note = ask('Raison du refus (envoyée aux administrateurs du club) :'); if (note) act(e.target, () => rpc('review_club_deletion', { p_request_id: r.request_id, p_approve: false, p_note: note }), 'Demande refusée.'); } }, 'Refuser')))) : empty('Aucune demande.')];
};

// --- Boutiques ---------------------------------------------------------------
VIEWS.boutiques = async () => {
  const shops = await rpc('list_shops', { p_limit: 100 });
  return [header('Boutiques', 'Suspendre une boutique la retire de la recherche ; son propriétaire est prévenu.'),
    h('section', { class: 'card' }, shops.length ? shops.map((s) => h('div', { class: 'list-item' },
      h('span', { class: 'grow' }, h('strong', {}, s.name), ` · ${s.city || '—'} · ${s.owner_name || '—'} · ${s.listing_count} annonce(s)`,
        s.suspended ? h('span', { class: 'tag red', style: 'margin-left:8px' }, 'Suspendue') : null),
      s.suspended
        ? h('button', { class: 'btn', type: 'button', onclick: (e) => act(e.target, () => rpc('set_shop_suspended', { p_shop_id: s.id, p_suspended: false }), 'Boutique rétablie.') }, 'Rétablir')
        : h('button', { class: 'btn danger', type: 'button', onclick: (e) => { const note = ask('Raison (envoyée au propriétaire) :'); if (note) act(e.target, () => rpc('set_shop_suspended', { p_shop_id: s.id, p_suspended: true, p_note: note }), 'Boutique suspendue.'); } }, 'Suspendre'))) : empty('Aucune boutique.'))];
};

// --- Défis -------------------------------------------------------------------
const METRICS = {
  rides_finished: 'Balades terminées',
  rides_organized: 'Balades organisées',
  ride_distance: 'Plus longue balade (km)',
  distance_total: 'Kilomètres cumulés en balade',
  maintenance: 'Entretiens notés',
  solo_arrived: 'Trajets solo arrivés',
  events: 'Événements (« J\'y vais »)',
  posts: 'Publications',
};
const TEMPLATES = [
  { title: 'Rouler ensemble', description: 'Participez à 3 balades terminées ce mois-ci.', metric: 'rides_finished', target: 3 },
  { title: 'Plus longue balade du mois', description: 'Faites une balade d\'au moins 300 km ce mois-ci.', metric: 'ride_distance', target: 300 },
  { title: 'Grand voyage', description: 'Cumulez 1 000 km en balades ce mois-ci.', metric: 'distance_total', target: 1000 },
  { title: 'Moto en forme', description: 'Notez un entretien dans votre garage.', metric: 'maintenance', target: 1 },
  { title: 'Rentrer en sécurité', description: 'Faites un trajet en mode solo jusqu\'à « Je suis arrivé ».', metric: 'solo_arrived', target: 1 },
  { title: 'Organisateur du mois', description: 'Organisez une balade et menez-la jusqu\'au bout.', metric: 'rides_organized', target: 1 },
];
const isoDay = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
VIEWS.defis = async () => {
  const list = await rpc('admin_challenges');
  const now = new Date();
  const f = {
    title: h('input', { maxlength: '80', required: true }),
    description: h('textarea', { rows: '2', maxlength: '300' }),
    metric: h('select', {}, Object.entries(METRICS).map(([k, v]) => h('option', { value: k }, v))),
    target: h('input', { type: 'number', min: '1', value: '3' }),
    starts: h('input', { type: 'date', value: isoDay(now) }),
    ends: h('input', { type: 'date', value: isoDay(new Date(now.getFullYear(), now.getMonth() + 1, 0)) }),
    notify: h('input', { type: 'checkbox', checked: true }),
  };
  const fill = (t) => { f.title.value = t.title; f.description.value = t.description; f.metric.value = t.metric; f.target.value = t.target; };
  const submit = h('button', { class: 'btn primary', type: 'submit' }, 'Lancer le défi');
  const form = h('form', { class: 'card', onsubmit: (ev) => {
    ev.preventDefault();
    act(submit, () => rpc('admin_create_challenge', {
      p_title: f.title.value, p_description: f.description.value, p_metric: f.metric.value,
      p_target: Number(f.target.value), p_starts_on: f.starts.value, p_ends_on: f.ends.value, p_notify: f.notify.checked,
    }), 'Défi lancé.');
  } },
  h('h2', {}, 'Créer un défi'),
  h('label', {}, 'Titre', f.title), h('label', {}, 'Description', f.description),
  h('div', { class: 'form-grid' }, h('label', {}, 'Ce qui compte', f.metric), h('label', {}, 'Objectif', f.target),
    h('label', {}, 'Début', f.starts), h('label', {}, 'Fin', f.ends)),
  h('label', { class: 'check' }, f.notify, 'Prévenir tous les motards au lancement'),
  h('p', { class: 'muted' }, 'Les défis ne comptent jamais la vitesse. Les distances sont celles des balades terminées (trajet du chef de convoi ou départ → arrivée).'),
  submit,
  h('h3', {}, 'Modèles prêts à l\'emploi'),
  h('div', { class: 'row' }, TEMPLATES.map((t) => h('button', { class: 'btn', type: 'button', onclick: () => fill(t) }, t.title))));
  const rows = list.map((c) => {
    const ended = c.cancelled_at || c.ends_on < isoDay(now);
    const winners = c.winners || [];
    return h('div', { class: 'list-item' },
      h('span', { class: 'grow' }, h('strong', {}, c.title), ` · ${METRICS[c.metric] || c.metric} : ${fmtNum(c.target)} · du ${fmtDate(c.starts_on)} au ${fmtDate(c.ends_on)} · ${c.completed_count} réussi(s)`,
        c.cancelled_at ? h('span', { class: 'tag red', style: 'margin-left:8px' }, 'Annulé') : ended ? h('span', { class: 'tag blue', style: 'margin-left:8px' }, 'Terminé') : h('span', { class: 'tag green', style: 'margin-left:8px' }, 'En cours')),
      c.completed_count > 0 ? h('button', { class: 'btn', type: 'button', onclick: (e) => {
        const text = ask('Texte publié dans le fil :', '');
        const body = text || `Défi « ${c.title} » : ${c.completed_count} motard(s) l'ont réussi${winners.length ? ` (${winners.slice(0, 10).join(', ')}${winners.length > 10 ? '…' : ''})` : ''}. Bravo ! Le prochain défi arrive bientôt.`;
        if (confirm(`Publier dans le fil ?\n\n${body}`)) act(e.target, () => rpc('admin_publish_announcement', { p_body: body }), 'Annonce publiée.');
      } }, 'Publier les résultats') : null,
      !c.cancelled_at && !ended ? h('button', { class: 'btn', type: 'button', onclick: (e) => { if (confirm(`Annuler le défi « ${c.title} » ?`)) act(e.target, () => rpc('admin_cancel_challenge', { p_id: c.id }), 'Défi annulé.'); } }, 'Annuler') : null);
  });
  return [header('Défis', 'Créés par l\'équipe ; un défi réussi donne un badge au motard.'), form,
    h('section', { class: 'card' }, h('h2', {}, 'Tous les défis'), rows.length ? rows : empty('Aucun défi.'))];
};

// --- Meilleure balade du mois ---------------------------------------------------
VIEWS['balade-du-mois'] = async () => {
  const now = new Date();
  const prev = new Date(now.getFullYear(), now.getMonth() - 1, 1);
  const period = h('input', { type: 'month', value: `${prev.getFullYear()}-${String(prev.getMonth() + 1).padStart(2, '0')}`, 'aria-label': 'Mois' });
  const box = h('div', {});
  async function load() {
    box.replaceChildren(h('p', { class: 'muted' }, 'Chargement…'));
    try {
      const rows = await rpc('admin_ride_of_month_candidates', { p_period: period.value });
      if (!rows.length) return box.replaceChildren(empty('Aucune balade terminée ce mois-là.'));
      if (rows[0].already_awarded) box.replaceChildren(h('p', {}, h('strong', {}, `La meilleure balade de ${monthLabel(period.value)} est déjà désignée.`)));
      else box.replaceChildren();
      rows.forEach((r, i) => box.append(h('div', { class: 'list-item' },
        h('span', { class: 'grow' }, h('strong', {}, `${i + 1}. ${r.title}`), ` · ${r.distance_km ? `${fmtNum(r.distance_km)} km` : 'distance inconnue'} · ${r.club_name || 'sans club'} · organisée par ${r.organizer_name} · ${r.participant_count} participant(s) · ${fmtDate(r.finished_at)}`),
        r.already_awarded ? null : h('button', { class: 'btn primary', type: 'button', onclick: (e) => {
          const msg = ask(`Message publié dans le fil (laisser vide pour le texte automatique) :`, '');
          if (msg === null) return;
          act(e.target, () => rpc('admin_award_ride_of_month', { p_ride_id: r.ride_id, p_period: period.value, p_publish: true, p_message: msg || null }),
            `« ${r.title} » : meilleure balade de ${monthLabel(period.value)}.`);
        } }, 'Désigner et publier'))));
    } catch (e) { box.replaceChildren(h('p', { class: 'error' }, errorText(e))); }
  }
  period.addEventListener('change', load);
  await load();
  return [header('Meilleure balade du mois', 'Les participants reçoivent le badge « Meilleure balade du mois · <mois> », et l\'annonce est publiée dans le fil.'),
    h('section', { class: 'card' }, h('div', { class: 'row' }, h('label', {}, 'Mois', period)), box)];
};

// --- Annonce -----------------------------------------------------------------
VIEWS.annonce = async () => {
  const body = h('textarea', { rows: '6', maxlength: '2000', placeholder: 'Ex. : Bravo au club … pour la plus longue balade du mois !' });
  const submit = h('button', { class: 'btn primary', type: 'submit' }, 'Publier dans le fil');
  return [header('Annonce officielle', 'Publiée dans le fil de tous les motards, signée « Équipe Rider Group ».'),
    h('form', { class: 'card', onsubmit: (ev) => { ev.preventDefault(); if (confirm('Publier cette annonce pour tous les motards ?')) act(submit, () => rpc('admin_publish_announcement', { p_body: body.value }), 'Annonce publiée.'); } },
      h('label', {}, 'Texte', body), submit)];
};

// --- Retours -----------------------------------------------------------------
VIEWS.retours = async () => {
  const items = await rpc('feedback_queue');
  return [header('Retours des motards', 'Problèmes et suggestions envoyés depuis l\'application.'),
    items.length ? items.map((f) => h('article', { class: 'card' },
      h('div', { class: 'row' }, h('span', { class: f.kind === 'problem' ? 'tag red' : 'tag blue' }, f.kind === 'problem' ? 'Problème' : 'Suggestion'),
        h('span', { class: 'muted' }, `${f.display_name || '—'} (@${f.username || '—'}) · ${f.platform || ''} ${f.app_version || ''} · ${fmtDateTime(f.created_at)}`)),
      h('blockquote', {}, f.message),
      h('div', { class: 'row' }, h('button', { class: 'btn', type: 'button', onclick: (e) => act(e.target, () => rpc('mark_feedback_handled', { p_id: f.id }), 'Marqué comme traité.') }, 'Traité')))) : empty('Aucun retour à traiter.')];
};

start();
