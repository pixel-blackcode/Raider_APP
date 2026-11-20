// Rider Group — envoi des notifications push (Firebase Cloud Messaging v1).
//
// Appelée par la base (pg_net) avec { kind: 'notification' | 'sos', id } et
// l'en-tête x-push-secret. Lit la notification ou l'alerte avec la clé
// service_role (fournie par Supabase à la fonction, jamais au téléphone),
// construit le texte en français et envoie aux téléphones concernés.
// Les jetons refusés par Firebase (application désinstallée) sont supprimés.
//
// Secrets de la fonction (Supabase → Edge Functions → Secrets) :
//   FIREBASE_SERVICE_ACCOUNT  JSON du compte de service Firebase
// Le secret partagé (en-tête x-push-secret) est vérifié dans Vault par la
// fonction SQL push_secret_ok : il n'est stocké qu'à un seul endroit.
import { createClient } from "jsr:@supabase/supabase-js@2";

type Payload = { kind: "notification" | "sos"; id: string };
type Message = { title: string; body: string; route: string; sos: boolean };

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false } },
);

// --- Jeton d'accès Google (JWT signé RS256 avec le compte de service) -------
let cachedToken: { value: string; exp: number } | null = null;

function b64url(data: Uint8Array | string): string {
  const bytes = typeof data === "string" ? new TextEncoder().encode(data) : data;
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function accessToken(sa: { client_email: string; private_key: string }) {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.exp - 60 > now) return cachedToken.value;
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const pem = sa.private_key.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8", der, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"],
  );
  const sig = new Uint8Array(await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(`${header}.${claims}`),
  ));
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${header}.${claims}.${b64url(sig)}`,
    }),
  });
  if (!res.ok) throw new Error(`oauth ${res.status}`);
  const json = await res.json();
  cachedToken = { value: json.access_token, exp: now + json.expires_in };
  return cachedToken.value;
}

// --- Textes ------------------------------------------------------------------
const TEXTS: Record<string, (d: Record<string, string>) => [string, string]> = {
  ride_join_request: (d) => ["Demande de participation", `${d.who} veut rejoindre « ${d.ride} »`],
  ride_joined: (d) => ["Nouveau participant", `${d.who} participe à « ${d.ride} »`],
  ride_request_approved: (d) => ["Demande acceptée", `Vous participez à « ${d.ride} »`],
  ride_request_rejected: (d) => ["Demande refusée", `Votre demande pour « ${d.ride} » n'a pas été acceptée`],
  ride_invitation: (d) => ["Invitation à une balade", `${d.who} vous invite à « ${d.ride} »`],
  ride_started: (d) => ["Balade démarrée", `« ${d.ride} » a démarré`],
  ride_cancelled: (d) => ["Balade annulée", `« ${d.ride} » est annulée`],
  ride_finished: (d) => ["Balade terminée", `« ${d.ride} » est terminée`],
  club_join_request: (d) => ["Demande d'adhésion", `${d.who} veut rejoindre ${d.club}`],
  club_request_approved: (d) => ["Bienvenue !", `Vous avez rejoint ${d.club}`],
  club_invitation: (d) => ["Invitation", `${d.who} vous invite dans ${d.club}`],
  post_comment: (d) => ["Nouveau commentaire", `${d.who} a commenté votre publication`],
  post_reaction: (d) => ["Nouvelle réaction", `${d.who} a réagi à votre publication`],
  event_coorganizer_invitation: (d) => ["Co-organisation", `${d.who} invite ${d.club} à co-organiser « ${d.title} »`],
  event_cancelled: (d) => ["Événement annulé", `« ${d.title} » est annulé`],
  club_deletion_requested: (d) => ["Suppression demandée", `${d.who} demande la suppression de ${d.club}`],
};

async function forNotification(id: string): Promise<[string[], Message] | null> {
  const { data: n } = await supabase.from("notifications")
    .select("user_id, kind, actor_id, ride_id, club_id, post_id, ref_id, data")
    .eq("id", id).maybeSingle();
  if (!n) return null;
  const [actor, ride, club] = await Promise.all([
    n.actor_id ? supabase.from("profiles").select("display_name").eq("id", n.actor_id).maybeSingle() : null,
    n.ride_id ? supabase.from("rides").select("title").eq("id", n.ride_id).maybeSingle() : null,
    n.club_id ? supabase.from("clubs").select("name").eq("id", n.club_id).maybeSingle() : null,
  ]);
  const d: Record<string, string> = {
    who: actor?.data?.display_name ?? "Un motard",
    ride: ride?.data?.title ?? "",
    club: club?.data?.name ?? (n.data?.name ?? ""),
    title: n.data?.title ?? "",
  };
  const [title, body] = TEXTS[n.kind]?.(d) ?? ["Rider Group", "Vous avez une nouvelle notification"];
  const route = n.post_id ? `/publications/${n.post_id}`
    : n.ride_id ? `/balades/${n.ride_id}`
    : n.data?.event_id ? `/evenements/${n.data.event_id}`
    : n.club_id ? `/clubs/${n.club_id}`
    : "/notifications";
  return [[n.user_id], { title, body, route, sos: false }];
}

async function forSos(id: string): Promise<[string[], Message] | null> {
  const { data: a } = await supabase.from("sos_alerts")
    .select("ride_id, user_id, kind, message").eq("id", id).maybeSingle();
  if (!a) return null;
  const [{ data: who }, { data: ride }, { data: parts }] = await Promise.all([
    supabase.from("profiles").select("display_name").eq("id", a.user_id).maybeSingle(),
    supabase.from("rides").select("title, organizer_id").eq("id", a.ride_id).maybeSingle(),
    supabase.from("ride_participants").select("user_id")
      .eq("ride_id", a.ride_id).eq("status", "confirmed"),
  ]);
  const users = new Set<string>((parts ?? []).map((p: { user_id: string }) => p.user_id));
  if (ride?.organizer_id) users.add(ride.organizer_id);
  users.delete(a.user_id);
  const name = who?.display_name ?? "Un motard";
  return [[...users], {
    title: `🚨 SOS — ${name}`,
    body: a.message ? `${a.message} (« ${ride?.title ?? ""} »)` : `Alerte pendant « ${ride?.title ?? ""} ». Ouvrez Rider Group.`,
    route: `/balades/${a.ride_id}/sos`,
    sos: true,
  }];
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("method", { status: 405 });
  const { data: ok } = await supabase.rpc("push_secret_ok", {
    p_secret: req.headers.get("x-push-secret") ?? "",
  });
  if (ok !== true) return new Response("forbidden", { status: 403 });
  let payload: Payload;
  try {
    payload = await req.json();
  } catch {
    return new Response("bad json", { status: 400 });
  }
  if (!/^[0-9a-f-]{36}$/.test(payload.id ?? "")) return new Response("bad id", { status: 400 });

  const target = payload.kind === "sos" ? await forSos(payload.id)
    : payload.kind === "notification" ? await forNotification(payload.id) : null;
  if (!target || target[0].length === 0) return Response.json({ sent: 0 });
  const [userIds, msg] = target;

  const { data: tokens } = await supabase.from("push_tokens")
    .select("token, platform").in("user_id", userIds);
  if (!tokens?.length) return Response.json({ sent: 0 });

  const sa = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ?? "{}");
  const bearer = await accessToken(sa);
  let sent = 0;
  const stale: string[] = [];
  await Promise.all(tokens.map(async ({ token }: { token: string }) => {
    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
      {
        method: "POST",
        headers: { Authorization: `Bearer ${bearer}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          message: {
            token,
            notification: { title: msg.title, body: msg.body },
            data: { route: msg.route, sos: String(msg.sos) },
            android: {
              priority: "high",
              notification: {
                channel_id: msg.sos ? "rider_sos" : "rider_general",
                sound: "default",
              },
            },
            apns: {
              headers: { "apns-priority": "10" },
              payload: { aps: { sound: "default", ...(msg.sos ? { "interruption-level": "time-sensitive" } : {}) } },
            },
          },
        }),
      },
    );
    if (res.ok) {
      sent++;
    } else if (res.status === 404 || res.status === 400) {
      const txt = await res.text();
      if (/UNREGISTERED|INVALID_ARGUMENT/.test(txt)) stale.push(token);
    }
  }));
  if (stale.length) await supabase.from("push_tokens").delete().in("token", stale);
  return Response.json({ sent, removed: stale.length });
});
