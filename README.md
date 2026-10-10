# lab-gitops

Manifest Kubernetes yang ditarik Argo CD di K3s homelab (`https://argocd.apps.lab.internal`).

```
argocd/apps/*.yaml        satu Application per aplikasi/lingkungan — dibaca Application `root`
                          (app-of-apps, di-bootstrap oleh proxmox-server: ansible/roles/argocd)
apps/lab-app/base         Deployment, Service, Ingress
apps/lab-app/overlays/dev   namespace lab-app-dev, sync OTOMATIS, tag diubah CI lab-app
apps/lab-app/overlays/prod  namespace lab-app-prod, sync MANUAL (promosi = salin tag dev lewat PR)
```

Secret dienkripsi **sops + age** (`*.enc.yaml`, hanya `data`/`stringData`). Argo CD mendekripsi
lewat KSOPS di repo-server. Membuat ulang secret DB: jalankan `scripts/seal-db-secret.sh dev|prod`
di 402 runner (kunci age & password DB hanya ada di sana).

| Lingkungan | URL |
|---|---|
| dev | https://lab-app-dev.apps.lab.internal |
| prod | https://lab-app.apps.lab.internal |
