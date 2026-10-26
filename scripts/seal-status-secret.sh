#!/usr/bin/env bash
# Buat/ulang secret DATABASE_URL lab-status terenkripsi (sops+age). JALANKAN DI 402 RUNNER sebagai user runner:
# kunci age & password DB (dibuat Ansible, pg_apps: lab_status) hanya ada di sana.
#   ./scripts/seal-status-secret.sh
set -euo pipefail
db=lab_status
pass=$(cat ~/.secrets/ansible/pg_${db})
out=apps/lab-status/secret.enc.yaml
cat <<YAML | SOPS_AGE_KEY_FILE=~/.secrets/age/lab.key sops --encrypt --filename-override "$out" --input-type yaml --output-type yaml /dev/stdin > "$out"
apiVersion: v1
kind: Secret
metadata:
  name: lab-status-db
type: Opaque
stringData:
  DATABASE_URL: postgresql://${db}:${pass}@db.lab.internal:5432/${db}
YAML
echo "ditulis: $out"
