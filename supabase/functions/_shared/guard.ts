// Fetching URLs that users send: only http(s) on public hosts — no
// localhost, private networks, cloud metadata or bare internal names like
// `kong` or `db` — with every redirect checked the same way, and only so
// many bytes read.

export class UnsafeUrl extends Error {}

function ipv4Private(ip: string): boolean {
  const p = ip.split(".").map(Number);
  if (p.length !== 4 || p.some((n) => !Number.isInteger(n) || n < 0 || n > 255)) return false;
  const [a, b] = p;
  return a === 0 || a === 10 || a === 127 || a >= 224 ||
    (a === 100 && b >= 64 && b <= 127) ||
    (a === 169 && b === 254) ||
    (a === 172 && b >= 16 && b <= 31) ||
    (a === 192 && b === 168) ||
    (a === 192 && b === 0) ||
    (a === 198 && (b === 18 || b === 19));
}

function ipv6Private(ip: string): boolean {
  const v = ip.toLowerCase();
  if (v === "::" || v === "::1") return true;
  const mapped = v.match(/^::ffff:(\d+\.\d+\.\d+\.\d+)$/);
  if (mapped) return ipv4Private(mapped[1]);
  return /^f[cd]/.test(v) || /^fe[89ab]/.test(v) || v.startsWith("ff");
}

function isIpv4(h: string) {
  return /^\d+\.\d+\.\d+\.\d+$/.test(h);
}

async function assertPublic(url: URL): Promise<void> {
  if (url.protocol !== "https:" && url.protocol !== "http:") throw new UnsafeUrl("scheme");
  if (url.username || url.password) throw new UnsafeUrl("credentials");
  const host = url.hostname.replace(/^\[|\]$/g, "").toLowerCase();
  if (!host.includes(".") && !host.includes(":")) throw new UnsafeUrl("internal host");
  if (host === "localhost" || /\.(localhost|local|internal|lan|home|corp)$/.test(host)) {
    throw new UnsafeUrl("internal host");
  }
  if (isIpv4(host)) {
    if (ipv4Private(host)) throw new UnsafeUrl("private address");
    return;
  }
  if (host.includes(":")) {
    if (ipv6Private(host)) throw new UnsafeUrl("private address");
    return;
  }
  // A public name can still point inside; check where it resolves when the
  // runtime lets us (best effort: the fetch fails anyway if it can't resolve).
  for (const type of ["A", "AAAA"] as const) {
    let addrs: string[] = [];
    try {
      addrs = await Deno.resolveDns(host, type);
    } catch {
      continue;
    }
    if (addrs.some((a) => (type === "A" ? ipv4Private(a) : ipv6Private(a)))) {
      throw new UnsafeUrl("resolves to a private address");
    }
  }
}

/** Like fetch, for a URL from a user: checked, and each redirect too. */
export async function safeFetch(
  raw: string,
  init: RequestInit = {},
  maxRedirects = 4,
): Promise<Response> {
  let url = new URL(raw);
  for (let hop = 0; ; hop++) {
    await assertPublic(url);
    const res = await fetch(url, { ...init, redirect: "manual" });
    const location = res.headers.get("location");
    if (res.status >= 300 && res.status < 400 && location) {
      await res.body?.cancel();
      if (hop >= maxRedirects) throw new UnsafeUrl("too many redirects");
      url = new URL(location, url);
      continue;
    }
    return res;
  }
}

/** The body as text, stopping after [maxBytes]. */
export async function readText(res: Response, maxBytes = 2_000_000): Promise<string> {
  if (!res.body) return "";
  const reader = res.body.getReader();
  const chunks: Uint8Array[] = [];
  let size = 0;
  try {
    while (size < maxBytes) {
      const { done, value } = await reader.read();
      if (done) break;
      chunks.push(value);
      size += value.byteLength;
    }
  } finally {
    await reader.cancel().catch(() => {});
  }
  const all = new Uint8Array(Math.min(size, maxBytes));
  let at = 0;
  for (const c of chunks) {
    const take = Math.min(c.byteLength, all.length - at);
    all.set(c.subarray(0, take), at);
    at += take;
    if (at >= all.length) break;
  }
  return new TextDecoder().decode(all);
}
