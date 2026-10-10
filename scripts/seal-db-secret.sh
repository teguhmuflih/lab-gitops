#!/usr/bin/env bash
# Buat/ulang secret DATABASE_URL lab-app terenkripsi (sops+age). JALANKAN DI 402 RUNNER sebagai user runner:
# kunci age & password DB (dibuat Ansible) hanya ada di sana.
#   ./scripts/seal-db-secret.sh dev|prod
set -euo pipefail
env=${1:?pakai: $0 dev|prod}
db=lab_app_${env}
pass=$(cat ~/.secrets/ansible/pg_${db})
out=apps/lab-app/overlays/${env}/secret.enc.yaml
cat <<YAML | SOPS_AGE_KEY_FILE=~/.secrets/age/lab.key sops --encrypt --filename-override "$out" --input-type yaml --output-type yaml /dev/stdin > "$out"
apiVersion: v1
kind: Secret
metadata:
  name: lab-app-db
type: Opaque
stringData:
  DATABASE_URL: postgresql://${db}:${pass}@db.lab.internal:5432/${db}
YAML
echo "ditulis: $out"
