#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

IMAGE="flask-demo"
BAD_TAG="bad"
GOOD_TAG="good"

BAD_DOCKERFILE="Dockerfile.bad"
GOOD_DOCKERFILE="Dockerfile"

OUT_DIR="reports"
mkdir -p "$OUT_DIR"

BAD_TAR="${OUT_DIR}/flask-bad.tar"
GOOD_TAR="${OUT_DIR}/flask-good.tar"
BAD_JSON="${OUT_DIR}/trivy-bad.json"
GOOD_JSON="${OUT_DIR}/trivy-good.json"
MD_OUT="Scan_Trivy.md"

echo "[+] Building images..."
docker build -f "$BAD_DOCKERFILE"  -t "${IMAGE}:${BAD_TAG}"  .
docker build -f "$GOOD_DOCKERFILE" -t "${IMAGE}:${GOOD_TAG}" .

echo "[+] Exporting images to tar..."
docker save "${IMAGE}:${BAD_TAG}"  -o "$BAD_TAR"
docker save "${IMAGE}:${GOOD_TAG}" -o "$GOOD_TAR"

echo "[+] Scanning with Trivy (JSON)..."
trivy image --scanners vuln --input "$BAD_TAR"  --format json --output "$BAD_JSON"
trivy image --scanners vuln --input "$GOOD_TAR" --format json --output "$GOOD_JSON"

size_of () {
  local tag="$1"
  docker images --format '{{.Repository}}:{{.Tag}} {{.Size}}' \
    | awk -v t="${IMAGE}:${tag}" '$1==t {print $2}'
}

count_sev () {
  local sev="$1"
  local file="$2"
  jq -r --arg S "$sev" '[ .Results[].Vulnerabilities[]? | select(.Severity==$S) ] | length' "$file"
}

BAD_SIZE="$(size_of "$BAD_TAG")"
GOOD_SIZE="$(size_of "$GOOD_TAG")"

BAD_CRIT="$(count_sev CRITICAL "$BAD_JSON")"
BAD_HIGH="$(count_sev HIGH "$BAD_JSON")"
BAD_MED="$(count_sev MEDIUM "$BAD_JSON")"
BAD_LOW="$(count_sev LOW "$BAD_JSON")"

GOOD_CRIT="$(count_sev CRITICAL "$GOOD_JSON")"
GOOD_HIGH="$(count_sev HIGH "$GOOD_JSON")"
GOOD_MED="$(count_sev MEDIUM "$GOOD_JSON")"
GOOD_LOW="$(count_sev LOW "$GOOD_JSON")"

cat > "$MD_OUT" <<EOF
# Report Trivy - Comparaison des images Docker

Fichiers générés :
- $BAD_TAR
- $GOOD_TAR
- $BAD_JSON
- $GOOD_JSON

| Image | Taille | CRITICAL | HIGH | MEDIUM | LOW |
|------:|:------:|---------:|-----:|-------:|----:|
| ${IMAGE}:${BAD_TAG} | ${BAD_SIZE:-NA} | $BAD_CRIT | $BAD_HIGH | $BAD_MED | $BAD_LOW |
| ${IMAGE}:${GOOD_TAG} | ${GOOD_SIZE:-NA} | $GOOD_CRIT | $GOOD_HIGH | $GOOD_MED | $GOOD_LOW |
EOF

echo "[+] Done -> $MD_OUT"
cat "$MD_OUT"
