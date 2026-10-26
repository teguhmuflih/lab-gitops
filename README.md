# lab-gitops

Manifest Kubernetes yang ditarik Argo CD di K3s homelab (`https://argocd.apps.lab.internal`).

```
argocd/apps/*.yaml        satu Application per aplikasi/lingkungan — dibaca Application `root`
                          (app-of-apps, di-bootstrap oleh proxmox-server: ansible/roles/argocd)
apps/lab-app/base         Deployment, Service, Ingress
apps/lab-app/overlays/dev   namespace lab-app-dev, sync OTOMATIS, tag diubah CI lab-app
apps/lab-app/overlays/prod  namespace lab-app-prod, sync MANUAL
apps/ai                   namespace ai: LiteLLM (gateway model, ≈ Bedrock) + Phoenix (trace LLM), sync otomatis
apps/lab-status           namespace lab-status: halaman status (web 2 replica + checker 1 replica), sync otomatis,
                          tag diubah CI lab-status, target cek di targets.yaml (ConfigMap)
apps/jenkins              namespace jenkins: chart resmi 5.9.64 (multi-source) + secret admin; modul belajar
```

Jenkins (fase 8) bersifat sementara: matikan dengan menghapus `argocd/apps/jenkins.yaml` (PVC ikut terhapus).
Job `lab-app` dibuat JCasC/Job DSL dan menjalankan `Jenkinsfile` di repo lab-app.

Promosi ke prod: Actions → **promote-prod** → Run workflow (tag kosong = tag dev saat ini).
Workflow memeriksa image ada di GHCR, lalu meng-commit tag ke overlay prod. Deploy baru terjadi
setelah `lab-app-prod` di-sync manual di Argo CD.

Secret dienkripsi **sops + age** (`*.enc.yaml`, hanya `data`/`stringData`). Argo CD mendekripsi
lewat KSOPS di repo-server. Membuat ulang secret DB: jalankan `scripts/seal-db-secret.sh dev|prod`
di 402 runner (kunci age & password DB hanya ada di sana). Secret AI (master key LiteLLM,
basic auth Phoenix, `lab-app-llm` untuk dev/prod): `scripts/seal-ai-secrets.sh` di runner. Admin Jenkins:
`scripts/seal-jenkins-secret.sh`. DB lab-status: `scripts/seal-status-secret.sh`.

| Lingkungan | URL |
|---|---|
| dev | https://lab-app-dev.apps.lab.internal |
| prod | https://lab-app.apps.lab.internal |
| LiteLLM (API OpenAI-compatible, master key) | https://litellm.apps.lab.internal |
| Phoenix (user `admin`, password di runner `~/.secrets/ansible/phoenix_password`) | https://phoenix.apps.lab.internal |
| Status lab (lab-status) | https://status.apps.lab.internal |
| Jenkins (user `admin`, password di runner `~/.secrets/ansible/jenkins_admin_password`) | https://jenkins.apps.lab.internal |
