---
name: add-argocd-app
description: Use this skill when the user wants to "add a new app to <cluster>", "deploy a service via ArgoCD", "wire up X to <namespace>", "create an ArgoCD Application for Y", or otherwise add a brand-new workload to an ArgoCD app-of-apps cluster. Discovers the cluster's gitops conventions from existing apps, handles stateless and stateful workloads, and delegates secret sealing to `add-sealed-secret`. Not for image bumps (edit the manifest directly) or new-cluster onboarding (use `gitops-onboard`).
version: 0.1.0
---

# Add a workload to an ArgoCD app-of-apps cluster

## When to use
The cluster is already ArgoCD-managed under an app-of-apps pattern (a root Application reconciles a directory of child Applications). The user wants to add a brand-new workload. Phrasing: "add memory-service-v2 to aimfg-dev", "deploy a new redis on simtech-prod", "wire up service-X to gitops".

- For image bumps or env tweaks: edit the manifest directly. Don't invoke this skill.
- For onboarding an existing cluster: use `gitops-onboard`.
- For ad-hoc sealed secrets unrelated to a new app: use `add-sealed-secret` directly.

## Inputs to gather
Ask the user for these if not supplied:
1. **Target cluster** — kubectl context name (e.g., `aimfg-dev`, `simtech-prod`).
2. **Gitops repo paths on disk** — usually one "apps repo" and optionally one "platform repo" for stateful infra.
3. **App name** — drop project-specific prefixes if sibling apps in the same namespace are unprefixed.
4. **Stateless or stateful?** — PVC needed?
5. **Needs a NEW sealed secret?** — vs just consuming existing shared secrets (postgres, mysql, azure-openai, etc.).
6. **Externally exposed?** — needs an HTTPRoute/Ingress rule?

## Steps

### A. Discover the cluster's gitops conventions
Don't hard-code paths or project names — learn from existing apps. Read 1-2 representative siblings:

```bash
# Apps repo layout
ls <apps-repo>/argocd/                       # ArgoCD Application files
ls <apps-repo>/                              # app-tier manifest dirs
cat <apps-repo>/argocd/<sibling>.yaml        # template for new Application

# Platform repo layout (if stateful)
ls <platform-repo>/<site>/base/              # cluster-agnostic component bases
ls <platform-repo>/<site>/overlays/<env>/    # per-cluster overlays

# Cluster-side: project allowances
kubectl --context=<argocd-ctx> -n argocd get appproject <project> -o yaml | yq '.spec.{destinations,sourceRepos,sourceNamespaces}'
```

Capture from the read:
- ArgoCD destination `name:` (e.g., `aimfg-development`)
- Target namespace (e.g., `aimie-common-model`)
- AppProject name (usually matches the namespace)
- App-of-apps name (the parent reconciling `<apps-repo>/argocd/`)
- Sealed-secret bundle path (e.g., `<apps-repo>/sealed-secrets/<env>.yaml`)
- Ingress file path (e.g., `<apps-repo>/ingress/<env>.yaml`)

### B. Apps-repo additions (always)

**ArgoCD Application file `<apps-repo>/argocd/<name>.yaml`** — mirror a sibling. Key fields:
```yaml
metadata:
  name: <name>-<env>
  namespace: <target-namespace>   # MUST be in the project's sourceNamespaces
spec:
  project: <project>
  destination:
    name: <argocd-cluster-name>
    namespace: <target-namespace>
  source:
    repoURL: <apps-repo URL>      # OR platform-repo URL for stateful workloads
    targetRevision: main
    path: <name>                  # OR aimfg/overlays/<env>/<name> for platform stateful
    directory:                    # OMIT if path is a Kustomize dir
      include: "<env>.yaml"
  syncPolicy:
    automated: { prune: true, selfHeal: true, allowEmpty: false }
    syncOptions: [Validate=true, PrunePropagationPolicy=foreground, PruneLast=true, ApplyOutOfSyncOnly=true]
```

**For stateless workloads — app manifest `<apps-repo>/<name>/<env>.yaml`:**
Deployment + ConfigMap + Service in one file, separated by `---`. Mirror a sibling. Image tag is a placeholder (e.g., `:d0`) that CI patches via `sed`.

### C. Platform-repo additions (stateful only)

Two directories:
- `<platform-repo>/<site>/base/<name>/` — StatefulSet, Service, `kustomization.yaml`. Cluster-agnostic.
- `<platform-repo>/<site>/overlays/<env>/<name>/` — `kustomization.yaml` listing `../../../base/<name>` + `sealed-secret.yaml` placeholder.

**Critical for stateful workloads** — set `enableServiceLinks: false` on the pod spec:
```yaml
spec:
  enableServiceLinks: false
  containers: ...
```
Kubernetes injects legacy `<SERVICE_NAME>_PORT_<port>_TCP_PORT` env vars for every Service in the namespace. If the Service name is `neo4j`, the injected `NEO4J_PORT_7687_TCP_PORT` collides with Neo4j's "env vars are config" convention (it tries to interpret `PORT.7687.TCP.PORT` as a setting and rejects under strict validation). Same trap for Postgres, MariaDB, anything that treats env as config. Set this preemptively for any stateful workload.

### D. Sealed secret (if a NEW one is needed)
Invoke `add-sealed-secret` skill. Pass:
- target cluster context
- target Secret `name` + `namespace`
- key/value pairs (or a pass-store path like `<env>/<name>-admin`)

It returns the sealed `encryptedData` values. Paste them into the placeholder file you authored in step C (for stateful) or in `<apps-repo>/sealed-secrets/<env>.yaml` (for stateless workloads consuming a new app-tier secret).

### E. Ingress rule (if externally exposed)
Append a `rules:` entry to the existing HTTPRoute file — one HTTPRoute per host, multiple rules. Don't create a new file. Common pattern:
```yaml
    - matches:
        - path: { type: PathPrefix, value: /<route> }
      filters:
        - type: URLRewrite
          urlRewrite:
            path: { type: ReplacePrefixMatch, replacePrefixMatch: / }
      backendRefs:
        - { name: <service>, port: <port> }
```
Verify no path collision: `grep "value: /" <ingress-file>` should show distinct prefixes.

### F. Commit, push, verify
1. Apps repo branch + PR + merge.
2. Platform repo branch + PR + merge if applicable.
3. The app-of-apps reconciles and creates the new child Application.

Verification:
```bash
# Application appears under the parent
kubectl --context=<argocd-ctx> get applications -A | grep <name>

# Workload appears in the target cluster
kubectl --context=<target-cluster> -n <namespace> get pods,svc,sealedsecret -l app=<name>

# For stateful workloads, PVC bound
kubectl --context=<target-cluster> -n <namespace> get pvc | grep <name>
```

If the new Application doesn't appear within ~60s, force the app-of-apps to refresh:
```bash
kubectl --context=<argocd-ctx> -n argocd annotate application <app-of-apps> argocd.argoproj.io/refresh=hard --overwrite
```

## House style
- **Mirror existing apps as templates** — copy a sibling and edit, don't author from scratch.
- **Application `metadata.namespace` must satisfy the project's `sourceNamespaces`** — typically the target app namespace, NOT `argocd`.
- **Application files always live in the apps repo**, even when the manifests are in the platform repo.
- **Drop project-specific prefixes from in-cluster resource names** if sibling apps in the same namespace are unprefixed. Use prefixes only for platform-repo path organisation, not for in-cluster identifiers.
- **`enableServiceLinks: false` on stateful pods** — preemptive, not reactive.
- **Default to placeholder-then-paste for sealed-secret content** — never let plaintext enter the conversation transcript.

## Common pitfalls
- **ArgoCD Application stuck `OutOfSync` with "one or more synchronization tasks are not valid"** — Application's `metadata.namespace` or `project` isn't permitted by the project's `destinations`/`sourceNamespaces`. Re-check the project spec.
- **Application created in `argocd` namespace doesn't show under the parent's `aimie-common-model` tree** — Apps-in-any-Namespace must live in the namespace the project's `sourceNamespaces` lists. Move to the right namespace; deletion + recreation, since `metadata.namespace` is immutable.
- **Renaming a StatefulSet = new PVC name = orphan storage.** PVC name is `<vctName>-<stsName>-<ordinal>`. Pre-plan migration or accept data reset.
- **`context not found` from kubectl/kubeseal** — `KUBECONFIG` doesn't include the target cluster's kubeconfig file.
- **Kubeconfig cluster-name collisions** (multiple files with `name: kubernetes`) — silently route to the first match in `KUBECONFIG` order. Rename per cluster: `cluster.name: <cluster>`, `user.name: <cluster>-admin`, update the context's `cluster:`/`user:` refs.
- **Stateful pod CrashLoopBackOff with config errors** referencing port-shaped env vars — missing `enableServiceLinks: false`.
- **Service-link injection from the StatefulSet's own Service** clobbers the pod's intentional env vars on every pod restart. Always disable.

## Reporting
After completion, summarize:
- Files added/changed per repo (group by repo)
- Pre-flight items the user still owns (re-seal if `(name, namespace)` changes, GH_PAT/imagePullSecret if CI/CD-bound, namespace creation if not pre-existing)
- The two verification commands (Application appears, workload runs)
- Cleanup steps if migrating from a renamed predecessor (orphan PVCs, old Applications)
