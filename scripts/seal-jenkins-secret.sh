#!/usr/bin/env bash
# Buat/ulang secret admin Jenkins terenkripsi (sops+age). JALANKAN DI 402 RUNNER (user runner),
# dari root repo ini. Password dibuat sekali di ~/.secrets/ansible/jenkins_admin_password.
#   ./scripts/seal-jenkins-secret.sh
set -euo pipefail
S=~/.secrets/ansible
umask 077
[ -s "$S/jenkins_admin_password" ] || python3 -c "import secrets,string; a=string.ascii_letters+string.digits; print(''.join(secrets.choice(a) for _ in range(24)))" > "$S/jenkins_admin_password"
pw=$(tr -d '\n' < "$S/jenkins_admin_password")
out=apps/jenkins/secret.enc.yaml
cat <<YAML | SOPS_AGE_KEY_FILE=~/.secrets/age/lab.key sops --encrypt --filename-override "$out" --input-type yaml --output-type yaml /dev/stdin > "$out"
apiVersion: v1
kind: Secret
metadata:
  name: jenkins-admin
type: Opaque
stringData:
  jenkins-admin-user: admin
  jenkins-admin-password: ${pw}
YAML
echo "ditulis: $out (password: runner $S/jenkins_admin_password)"
