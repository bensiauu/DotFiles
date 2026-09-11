---
name: gitops-onboard
description: Use this skill when the user wants to "onboard to gitops", "bring a cluster under argocd", "adopt existing workloads into argocd", "convert cluster to app-of-apps", or migrate a manually-managed Kubernetes cluster to GitOps. Guides through discovery, classification, and manifest generation without direct cluster access. Delegate to gitops-onboarder agent for substantive work.
version: 0.1.0
---

# Onboard existing Kubernetes workloads into ArgoCD GitOps

## When to use
The user has a Kubernetes cluster with workloads already running (installed manually via helm install, kubectl apply, or operators) and wants to bring them under ArgoCD-managed GitOps using the mks-platform-gitops app-of-apps pattern.

## Inputs to gather
1. **Site name** — the top-level directory (e.g., `simtech`, `aimfg`). New sites get a new directory.
2. **Cluster name** — the cluster identifier (e.g., `tools`, `prod`, `dev`)
3. **Cluster API server URL** — e.g., `https://172.20.105.163:6443` or `https://kubernetes.default.svc` if ArgoCD runs on the same cluster
4. **Git repo URL** — the gitops repo (e.g., `https://github.com/ASTAR-AIMFG/mks-platform-gitops`)
5. **ArgoCD location** — does ArgoCD already run on this cluster, a hub cluster, or does it need to be installed?
6. **SealedSecrets availability** — is sealed-secrets-controller running? If not, it will be included in the onboarding.
7. **Existing Helm repos** — any private/non-standard chart repositories in use?

## Steps

### Phase 1: Discovery (interactive — no direct cluster access)
The agent emits kubectl/helm commands in batches. The user runs them and pastes the output.

**Batch 1 — Cluster overview:**
```bash
kubectl get nodes -o wide
kubectl get namespaces
helm list -A
kubectl get crd --no-headers | wc -l
```

**Batch 2 — Workload inventory:**
```bash
kubectl get deploy,sts,ds,job,cronjob -A -o wide
kubectl get svc -A -o wide
kubectl get ingress -A -o wide 2>/dev/null; kubectl get httproute -A -o wide 2>/dev/null
```

**Batch 3 — Helm release details** (for each release from Batch 1):
```bash
helm get values <release> -n <namespace> -a -o yaml
helm get metadata <release> -n <namespace>
```

**Batch 4 — Storage and secrets overview:**
```bash
kubectl get sc
kubectl get pv
kubectl get pvc -A
kubectl get secrets -A --field-selector type!=kubernetes.io/service-account-token -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,TYPE:.type
```

**Batch 5 — CRDs and custom resources:**
```bash
kubectl get crd -o name
```
Then for each relevant CRD group:
```bash
kubectl get <resource> -A 2>/dev/null
```

**Batch 6 — RBAC and infrastructure:**
```bash
kubectl get clusterrole --no-headers | grep -v system: | head -30
kubectl get clusterrolebinding --no-headers | grep -v system: | head -30
kubectl get storageclass
```

### Phase 2: Classification
Process all pasted output and classify every workload into one of:

| Category | Detection signal | ArgoCD pattern |
|----------|-----------------|----------------|
| Helm infrastructure | In `helm list`, system namespace | Pattern A (inline values) or B (multi-source) |
| Helm application | In `helm list`, app namespace | Pattern B (multi-source with overlays) |
| Operator + CRs | CRDs present, operator deployment found | Operator = A/B, CRs = C (separate Application) |
| Raw manifests | Not in `helm list` | Pattern C (Kustomize) |
| System/excluded | kube-system core (coredns, kube-proxy) | Skip — kubeadm-managed |

Present the classification table to the user for review and adjustment before proceeding.

### Phase 3: Sync wave planning
Assign sync waves based on dependency analysis:
- 0: CNI (Calico/Cilium)
- 1: SealedSecrets
- 2: LoadBalancer provider (MetalLB), storage provisioners, MetalLB config CRs
- 3: cert-manager, secret reflector
- 4: Ingress controller (Traefik/nginx)
- 5: ClusterIssuers, metrics-server
- 6-7: Database operators, heavyweight operators (gpu-operator)
- 7-8: Operator CRs (database clusters, etc.)
- 8-9: Application workloads
- 9-10: Application ingress/routing

### Phase 4: Manifest generation
Generate all files following the mks-platform-gitops conventions:

1. **`<site>/projects/platform-<cluster>.yaml`** — AppProject with cluster RBAC
2. **`<site>/clusters/<cluster>/root-app.yaml`** — root Application scanning `apps/`
3. **`<site>/clusters/<cluster>/apps/<component>.yaml`** — one per workload
4. **`base/<component>/values.yaml`** — shared Helm values (reuse existing base/ entries where they match)
5. **`<site>/overlays/<cluster>/<component>-values.yaml`** — cluster-specific overrides
6. **`<site>/overlays/<cluster>/<component>/kustomization.yaml`** — for Kustomize-managed resources
7. **`<site>/argocd-repos/`** — Helm repo Secrets + kustomization.yaml (for non-standard repos)
8. **`<site>/secrets/`** — SealedSecret placeholders with sealing instructions

### Phase 5: Adoption plan
For each workload, specify the adoption strategy:

- **Helm releases**: `helm uninstall --keep-history` then ArgoCD sync. Must match releaseName if different from Application name.
- **Raw manifests**: `Replace=true` or `ServerSideApply=true` syncOption
- **Stateful workloads**: `prune: false` initially, flip after verification
- **PVs**: Always `Prune=false` annotation or separate no-prune Application
- **Secrets**: Seal with kubeseal, or exclude from GitOps scope

### Phase 6: Rollout checklist
Produce a step-by-step execution plan:
1. Create feature branch in gitops repo
2. Commit all generated files
3. For Helm-managed workloads (wave order): `helm uninstall <release> -n <ns> --keep-history`
4. Apply AppProject: `kubectl apply -f <site>/projects/`
5. Apply root Application: `kubectl apply -f <site>/clusters/<cluster>/root-app.yaml`
6. Monitor: `watch kubectl get applications -n argocd`
7. Seal secrets: kubeseal commands for each secret
8. Verify: all Applications Synced+Healthy, no orphaned resources

## Hard rules
- NEVER generate manifests without completing discovery first — incomplete knowledge of the cluster causes data loss
- NEVER set `prune: true` on Applications containing PersistentVolumes without explicit user consent
- NEVER commit plain Secrets — always use SealedSecrets or exclude from GitOps
- NEVER assume Helm release names — always ask the user to provide `helm list -A` output
- ALWAYS capture live Helm values (`helm get values -a`) before generating base values files
- ALWAYS use `ServerSideApply=true` for CRD-heavy operators (cert-manager, cloudnative-pg, gpu-operator)
- ALWAYS place CRD-installing Applications at a lower sync wave than CR-creating Applications
- ALWAYS check for existing `base/<component>/` entries before creating duplicates — reuse shared bases
- For ArgoCD hub-spoke: remote cluster Applications must use the VIP in `destination.server`, not `https://kubernetes.default.svc`
- Match the existing naming convention: `<component>-<cluster>` for Application names
- The `platform-<cluster>` AppProject must list the correct `destination.server` in its `destinations` array
- For ArgoCD-managed resources that already exist, warn that first sync may show drift — this is expected and correct

## Reporting
After completion, produce:
1. **File inventory** — every file created in the gitops repo, grouped by directory
2. **Sync wave table** — component, wave, pattern, dependencies
3. **Adoption checklist** — ordered helm-uninstall and kubectl commands for the user to execute
4. **Secrets to seal** — kubeseal commands for each secret that needs encryption
5. **Excluded resources** — anything deliberately left outside GitOps with rationale
6. **Risk register** — PVs, stateful sets, or resources that need extra care during adoption
