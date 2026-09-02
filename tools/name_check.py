#!/usr/bin/env python3
"""Check an app-name candidate against the App Store, Google Play, and DNS.

Usage:  python3 name_check.py "Name One" "Name Two" ...
        python3 name_check.py --json "Name"
        python3 name_check.py --pace 3 "Name"      # seconds between iTunes calls
        python3 name_check.py --no-ios "Name"      # Play + domains only (Apple throttling)

For each name it reports:
  * App Store  : exact / near-exact title matches (iTunes Search API, US + GB + DE)
  * Google Play: titles on the first search page that exactly or nearly match
  * Domain     : whether <name>.com and <name>app.com are registered (RDAP) / resolve

Apple rate-limits the iTunes Search API aggressively. This script backs off and retries;
if it still cannot get an answer it reports UNKNOWN for that storefront rather than
silently treating a refusal as "no matches found".
"""
import json, re, sys, time, unicodedata, urllib.parse, urllib.request, urllib.error, socket

UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
PACE = 2.0          # seconds between iTunes calls
SKIP_IOS = False    # --no-ios: skip the App Store pass (use when Apple is rate-limiting)
STOREFRONTS = ("us", "gb", "de")


def norm(s):
    s = unicodedata.normalize("NFKD", s or "").lower()
    return re.sub(r"[^a-z0-9]", "", s)


def head(title):
    """The part of a store title before its tagline separator."""
    return norm(re.split(r"[:\-–—|(]", title)[0])


def get(url, timeout=25):
    req = urllib.request.Request(url, headers={"User-Agent": UA,
                                               "Accept-Language": "en-US,en;q=0.9"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read().decode("utf-8", "replace")


def get_retry(url, tries=4, wait=8):
    """GET with backoff on 403/429/5xx. Returns (body, None) or (None, reason)."""
    last = "unknown"
    for i in range(tries):
        try:
            return get(url), None
        except urllib.error.HTTPError as e:
            last = "HTTP %d" % e.code
            if e.code not in (403, 429) and e.code < 500:
                return None, last
        except Exception as e:
            last = str(e)
        if i < tries - 1:
            time.sleep(wait * (i + 1))
    return None, last


def itunes(name, country):
    q = urllib.parse.quote(name)
    url = (f"https://itunes.apple.com/search?term={q}&entity=software"
           f"&limit=50&country={country}")
    body, err = get_retry(url)
    time.sleep(PACE)
    if body is None:
        return {"status": "UNKNOWN", "reason": err, "hits": []}
    try:
        data = json.loads(body)
    except Exception as e:
        return {"status": "UNKNOWN", "reason": "unparseable: %s" % e, "hits": []}
    n = norm(name)
    hits = []
    for r in data.get("results", []):
        t = r.get("trackName", "")
        if norm(t) == n or norm(t).startswith(n) or head(t) == n:
            hits.append({"title": t, "seller": r.get("sellerName"),
                         "genre": r.get("primaryGenreName"),
                         "url": r.get("trackViewUrl"), "exact": norm(t) == n})
    return {"status": "OK", "scanned": data.get("resultCount", 0), "hits": hits}


def play(name):
    q = urllib.parse.quote(name)
    url = f"https://play.google.com/store/search?q={q}&c=apps&hl=en&gl=US"
    body, err = get_retry(url, tries=3, wait=5)
    if body is None:
        return {"status": "UNKNOWN", "reason": err, "hits": [], "top_titles": []}
    titles = re.findall(r'class="[^"]*\bDdYX5\b[^"]*"[^>]*>([^<]{1,80})<', body)
    titles = [t.replace("&amp;", "&").replace("&#39;", "'").strip() for t in titles]
    n = norm(name)
    hits = [{"title": t, "exact": norm(t) == n}
            for t in titles if norm(t) == n or head(t) == n or norm(t).startswith(n)]
    return {"status": "OK", "top_titles": titles[:12], "hits": hits}


def domain(host):
    out = {"host": host}
    try:
        socket.gethostbyname(host)
        out["resolves"] = True
    except Exception:
        out["resolves"] = False
    try:
        d = json.loads(get(f"https://rdap.verisign.com/com/v1/domain/{host}", timeout=15))
        out["registered"] = True
        for e in d.get("events", []):
            if e.get("eventAction") == "registration":
                out["registered_on"] = e.get("eventDate", "")[:10]
    except urllib.error.HTTPError as e:
        out["registered"] = False if e.code == 404 else "unknown(%d)" % e.code
    except Exception as e:
        out["registered"] = "unknown"
        out["error"] = str(e)
    return out


def check(name):
    slug = norm(name)
    res = {"name": name}
    res["app_store"] = ({} if SKIP_IOS else {c: itunes(name, c) for c in STOREFRONTS})
    res["google_play"] = play(name)
    res["domains"] = [domain(f"{slug}.com"), domain(f"{slug}app.com")]
    stores = list(res["app_store"].values())
    unknown = any(s["status"] == "UNKNOWN" for s in stores) or res["google_play"]["status"] == "UNKNOWN"
    exact = (any(h["exact"] for s in stores for h in s["hits"])
             or any(h["exact"] for h in res["google_play"]["hits"]))
    near = (any(s["hits"] for s in stores) or bool(res["google_play"]["hits"]))
    res["verdict"] = ("TAKEN" if exact else "CROWDED" if near
                      else "PARTIAL" if unknown else "CLEAR")
    return res


def human(r):
    print(f"\n=== {r['name']}  ->  {r['verdict']} ===")
    for c, d in r["app_store"].items():
        if d["status"] == "UNKNOWN":
            print(f"  iOS[{c}] : UNKNOWN — Apple refused ({d['reason']})")
        elif d["hits"]:
            for h in d["hits"]:
                print(f"  iOS[{c}] {'EXACT' if h['exact'] else 'near '}: {h['title']}"
                      f"  — {h['seller']} ({h['genre']})")
        else:
            print(f"  iOS[{c}] : clear — no title match in {d['scanned']} results")
    p = r["google_play"]
    if p["status"] == "UNKNOWN":
        print(f"  Play    : UNKNOWN — {p['reason']}")
    elif p["hits"]:
        for h in p["hits"]:
            print(f"  Play    {'EXACT' if h['exact'] else 'near '}: {h['title']}")
    else:
        print(f"  Play    : clear. nearest: {', '.join(p['top_titles'][:5])}")
    for d in r["domains"]:
        reg = d.get("registered")
        print(f"  domain  : {d['host']:<28} {'REGISTERED' if reg is True else 'FREE' if reg is False else reg}"
              f"  resolves={d.get('resolves')}  since={d.get('registered_on', '-')}")


if __name__ == "__main__":
    args = sys.argv[1:]
    as_json = "--json" in args
    if "--pace" in args:
        i = args.index("--pace")
        PACE = float(args[i + 1])
        del args[i:i + 2]
    if "--no-ios" in args:
        SKIP_IOS = True
        args = [a for a in args if a != "--no-ios"]
    names = [a for a in args if a != "--json"]
    out = []
    for nm in names:
        try:
            r = check(nm)
        except Exception as e:
            r = {"name": nm, "verdict": "ERROR", "error": str(e)}
        out.append(r)
        if not as_json:
            human(r)
            sys.stdout.flush()
    if as_json:
        print(json.dumps(out, indent=1))
