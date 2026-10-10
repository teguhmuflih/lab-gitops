#!/usr/bin/env bash
# Buat/ulang secret AI terenkripsi (sops+age). JALANKAN DI 402 RUNNER sebagai user runner,
# dari root repo ini: kunci age & rahasia (dibuat sekali, dipakai ulang) hanya ada di runner.
#   ./scripts/seal-ai-secrets.sh
# Menulis:
#   apps/ai/secret.enc.yaml                         ai-secrets: LITELLM_MASTER_KEY
#   apps/ai/phoenix-auth.enc.yaml                   phoenix-auth: users (htpasswd; Traefik basicAuth butuh secret 1 key)
#   apps/lab-app/overlays/{dev,prod}/llm.enc.yaml   lab-app-llm: LITELLM_URL, LITELLM_API_KEY
# LiteLLM belum memakai database → belum ada virtual key; lab-app memakai master key.
set -euo pipefail
S=~/.secrets/ansible
umask 077

gen() {  # gen <file> <panjang> → buat sekali, lalu selalu dipakai ulang
  [ -s "$S/$1" ] || python3 -c "import secrets,string; a=string.ascii_letters+string.digits; print(''.join(secrets.choice(a) for _ in range($2)))" > "$S/$1"
  tr -d '\n' < "$S/$1"
}
master="sk-$(gen litellm_master_key 40)"
phoenix_pw=$(gen phoenix_password 24)
htpasswd=$(PW="$phoenix_pw" python3 -c 'import bcrypt,os; print("admin:" + bcrypt.hashpw(os.environ["PW"].encode(), bcrypt.gensalt(12)).decode())')

seal() {  # seal <file-tujuan>  (YAML polos dari stdin)
  SOPS_AGE_KEY_FILE=~/.secrets/age/lab.key sops --encrypt --filename-override "$1" \
    --input-type yaml --output-type yaml /dev/stdin > "$1"
  echo "ditulis: $1"
}

seal apps/ai/secret.enc.yaml <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: ai-secrets
type: Opaque
stringData:
  LITELLM_MASTER_KEY: ${master}
YAML

seal apps/ai/phoenix-auth.enc.yaml <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: phoenix-auth
type: Opaque
stringData:
  users: '${htpasswd}'
YAML

for env in dev prod; do
  seal "apps/lab-app/overlays/${env}/llm.enc.yaml" <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: lab-app-llm
type: Opaque
stringData:
  LITELLM_URL: http://litellm.ai.svc:4000
  LITELLM_API_KEY: ${master}
YAML
done
echo "Password UI Phoenix (user admin): runner ${S}/phoenix_password"
