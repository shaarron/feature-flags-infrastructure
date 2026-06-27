apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-${env_name}
  namespace: argocd

spec:
  project: default

  source:
    repoURL: https://github.com/shaarron/feature-flags-resources.git
    targetRevision: ${target_revision}
    path: argocd/chart
    helm:
      valueFiles:
        - ../environments/values.yaml
        - ../environments/${env_name}/values.yaml

  destination:
    server: https://kubernetes.default.svc
    namespace: argocd

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ApplyOutOfSyncOnly=true
