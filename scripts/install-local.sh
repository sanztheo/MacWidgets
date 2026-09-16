#!/bin/bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 MacWidgets-unsigned.zip signing-identity-sha1 apple-team-id" >&2
  exit 2
fi

archive="$1"
identity="$2"
team="$3"
if [[ ! "$team" =~ ^[A-Z0-9]{10}$ ]]; then
  echo "Expected a ten-character Apple team identifier." >&2
  exit 2
fi
if [[ ! "$identity" =~ ^[A-Fa-f0-9]{40}$ ]]; then
  echo "Expected a code-signing identity SHA-1 fingerprint." >&2
  exit 2
fi

cd "$(dirname "$0")/.."
mkdir -p .local
staging="$(mktemp -d "$PWD/.local/install.XXXXXX")"
trap 'rm -rf "$staging"' EXIT

python3 - "$identity" "$staging/signing.pem" <<'PY'
import base64
import hashlib
import re
import subprocess
import sys
from pathlib import Path

certificates = subprocess.check_output(['security', 'find-certificate', '-a', '-p'], text=True)
for certificate in re.findall(r'-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----', certificates, re.S):
    body = certificate.replace('-----BEGIN CERTIFICATE-----', '').replace('-----END CERTIFICATE-----', '')
    fingerprint = hashlib.sha1(base64.b64decode(body)).hexdigest()
    if fingerprint.lower() == sys.argv[1].lower():
        Path(sys.argv[2]).write_text(certificate + '\n')
        break
else:
    raise SystemExit('The selected signing certificate was not found.')
PY

# Ordinary codesign verification does not reliably check certificate revocation.
# Require a positive online OCSP response before copying anything into Applications.
if ! security verify-cert -p codeSign -R ocsp -R require -c "$staging/signing.pem" -q; then
  echo "Certificate revoked or revocation status unconfirmed. Nothing was installed." >&2
  exit 1
fi
python3 - "$staging/signing.pem" "$team" <<'PY'
import re
import subprocess
import sys

subject = subprocess.check_output([
    'openssl', 'x509', '-in', sys.argv[1], '-noout', '-subject', '-nameopt', 'RFC2253'
], text=True)
match = re.search(r'(?:^|,)OU=([A-Z0-9]{10})(?:,|$)', subject.replace('subject=', '').strip())
if not match or match.group(1) != sys.argv[2]:
    raise SystemExit('The signing certificate does not belong to the requested Apple team.')
PY
ditto -x -k "$archive" "$staging"
app="$staging/MacWidgets.app"
extension="$app/Contents/PlugIns/MacWidgetsExtension.appex"
test -d "$extension"
test -d "$extension/Contents/Resources/Metadata.appintents"

python3 - "$app" "$team" "$staging" <<'PY'
import plistlib
import sys
from pathlib import Path

app = Path(sys.argv[1])
team = sys.argv[2]
staging = Path(sys.argv[3])
extension = app / 'Contents/PlugIns/MacWidgetsExtension.appex'
for bundle in (app, extension):
    info_path = bundle / 'Contents/Info.plist'
    info = plistlib.loads(info_path.read_bytes())
    info['SharedAppGroup'] = team + '.com.sanztheo.MacWidgets'
    info.pop('SharedKeychainGroup', None)
    info_path.write_bytes(plistlib.dumps(info))
    entitlements = {
        'com.apple.security.app-sandbox': True,
        'com.apple.security.network.client': True,
        'com.apple.security.application-groups': [info['SharedAppGroup']],
    }
    if bundle == app:
        entitlements['com.apple.security.network.server'] = True
        entitlements['com.apple.security.files.user-selected.read-only'] = True
    (staging / (bundle.name + '.entitlements')).write_bytes(plistlib.dumps(entitlements))
PY

while IFS= read -r library; do
  codesign --force --sign "$identity" --options runtime "$library"
done < <(find "$app" -name '*.dylib' -type f)
codesign --force --sign "$identity" --options runtime \
  --entitlements "$staging/MacWidgetsExtension.appex.entitlements" "$extension"
codesign --force --sign "$identity" --options runtime \
  --entitlements "$staging/MacWidgets.app.entitlements" "$app"
codesign --verify --deep --strict --verbose=2 "$app"

if [ -e /Applications/MacWidgets.app ]; then
  echo "MacWidgets is already installed. Quit it and move the previous app aside before reinstalling." >&2
  exit 1
fi
ditto "$app" /Applications/MacWidgets.app
codesign --verify --deep --strict --verbose=2 /Applications/MacWidgets.app
echo "Installed /Applications/MacWidgets.app. Local development signing only; not a notarized public release."
