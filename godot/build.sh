#!/bin/sh
# Export the web build and add a strict Content-Security-Policy.
set -e
GODOT=${GODOT:-../Godot_v4.5.2-stable_linux.x86_64}
PRESET=${1:-Web}
OUT=export
[ "$PRESET" = "Web Next" ] && OUT=export_next
mkdir -p $OUT
touch $OUT/.gdignore # keep the editor from importing the exported pngs
"$GODOT" --headless --export-release "$PRESET" $OUT/index.html
OUT=$OUT python3 - <<'PYBUILD'
import re, hashlib, base64, os
from pathlib import Path

out = Path(os.environ.get('OUT', 'export'))
p = out / 'index.html'
h = p.read_text()
h = h.replace('<title>KIN</title>', '<title>KIN | Living goldfish pond</title>\n\t\t<meta name="description" content="A quiet living goldfish pond. Watch, feed and meet the fish.">', 1)
if "setStatusNotice(err.message);" not in h or "displayFailureNotice(missingMsg + missing.join('\\n'));" not in h:
    raise SystemExit("Godot error template changed; review its failure UI before exporting")
h = h.replace("setStatusNotice(err.message);", "setStatusNotice('The pond could not start. Please reload and try again.');")
h = h.replace("setStatusNotice(err);", "setStatusNotice('The pond could not start. Please reload and try again.');")
h = h.replace("displayFailureNotice(missingMsg + missing.join('\\n'));", "displayFailureNotice('This browser cannot run the pond. Please try a browser with WebGL 2.');")
if "setStatusNotice(err.message)" in h or "setStatusNotice(err);" in h or "displayFailureNotice(missingMsg" in h:
    raise SystemExit('Godot error template changed; review its failure UI before exporting')
# CSP hashes are derived from the final inline script, after the sanitizing edit.
hashes = []
for m in re.finditer(r'<script(?![^>]*\bsrc=)[^>]*>(.*?)</script>', h, re.S):
    hashes.append("'sha256-" + base64.b64encode(hashlib.sha256(m.group(1).encode()).digest()).decode() + "'")
csp = ("default-src 'none'; script-src 'self' 'wasm-unsafe-eval' " + " ".join(hashes) +
       "; connect-src 'self'; img-src 'self' data: blob:; style-src 'self' 'unsafe-inline'; "
       "worker-src 'self' blob:; media-src 'self' blob:; manifest-src 'self'; base-uri 'none'; form-action 'none'")
meta = '<meta http-equiv="Content-Security-Policy" content="' + csp + '">\n<meta name="referrer" content="no-referrer">\n'
if '<head>' not in h or '<title>KIN | Living goldfish pond</title>' not in h:
    raise SystemExit('Godot HTML template changed; metadata not applied')
h = h.replace('<head>', '<head>\n' + meta, 1)
p.write_text(h)
(out / "404.html").write_text(Path("404.html").read_text())
print('CSP script hashes:', len(hashes))
PYBUILD
