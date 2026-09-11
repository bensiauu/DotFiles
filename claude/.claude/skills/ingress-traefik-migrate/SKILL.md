---
name: ingress-traefik-migrate
description: Use this skill when the user wants to "migrate ingress to traefik", "switch from nginx-ingress to traefik", or plan a Traefik cutover for a Kubernetes cluster. Produces an inventory, migration plan, and executes the cutover with full OAuth2/ForwardAuth support. Delegate to ingress-traefik-migrator for substantive work.
version: 0.1.0
---

# Migrate nginx-ingress to Traefik

## When to use
User wants to replace nginx-ingress with Traefik on a Kubernetes cluster. This covers the full lifecycle: inventory, install, cutover, patching, OAuth2 ForwardAuth, and cleanup.

## Inputs to gather
1. **Cluster name / kube context** — which cluster is being migrated?
2. **Target Traefik chart version** — default to latest 39.x unless user specifies otherwise (avoid 40.x unless ready for breaking changes)
3. **MetalLB IP** — the IP currently assigned to nginx that Traefik will take over
4. **ClusterIssuer name and wildcard domain** — e.g. `route53` for `*.aimfg.sg`, or `cloudflare` for `*.modelfactory.sg`
5. **Deployment mode** — GitOps (ArgoCD manages Traefik) or Manual (helm install directly)?
6. **Access** — is the user on local machine (company wifi) or remote build server? (determines whether they can run kubectl directly or need guidance to paste output)

## Steps

### Phase 1: Inventory
1. List all Ingress resources: `kubectl get ingress -A -o wide`
2. Identify regex paths: `kubectl get ingress -A -o json | python3 -c "..."` filtering for `ImplementationSpecific` pathType
3. Identify OAuth2-proxy stacks: search for `auth-url` annotations
4. Identify TLS secrets referenced and check which namespaces have them
5. Check for catch-all Ingress resources (path `/` on shared hosts — e.g. Jenkins)
6. Classify each Ingress into tiers (1=simple host, 2=path-based, 3=OAuth2, 4=heavy custom)

### Phase 2: Install Traefik
1. Build the combined Helm values file (merge base + cluster-specific overrides)
2. `helm install traefik traefik/traefik -n traefik --create-namespace --version <version> -f values.yaml`
3. Apply wildcard Certificate resource
4. Verify: pods Running, cert Ready, Gateway exists, LoadBalancer Pending

### Phase 3: Cutover
1. **Delete** the nginx Service (not scale to 0) — MetalLB tracks Services
2. **Delete** the nginx admission webhook: `kubectl delete validatingwebhookconfiguration ingress-nginx-admission`
3. Verify Traefik LoadBalancer gets the IP
4. Quick smoke test on host-based routes

### Phase 4: Patch Ingress resources
1. Patch all regex `ImplementationSpecific` paths to `Prefix` pathType
2. Copy TLS secrets to namespaces that need them
3. Configure app rootpaths for services that used `rewrite-target` (ArgoCD, SonarQube, etc.)
4. Smoke test all path-based routes

### Phase 5: OAuth2 ForwardAuth
For each namespace with oauth2-proxy:
1. Change `--upstream` to `static://202` in oauth2-proxy Deployment
2. Create Middleware CRDs: trailing-slash redirect, ForwardAuth, StripPrefix
3. Create chain Middleware combining the three
4. Switch mlflow Ingress `ingressClassName` to `traefik`
5. Annotate Ingress with middleware chain reference
6. Test auth flow end-to-end in browser (Keycloak redirect → login → callback → app loads with static assets)

### Phase 6: Cleanup
After soak period:
1. Uninstall nginx Helm release or delete resources manually
2. Delete ingress namespace if empty

## Hard rules
- Always confirm `kubectl config current-context` before any mutation
- Never delete the nginx Service until Traefik is installed and LoadBalancer is Pending
- Never assume TLS secrets exist in all namespaces — check first
- ForwardAuth must use the Service port (typically 80), not the container port (4180)
- ForwardAuth address must be the oauth2-proxy root path `/`, not `/auth` (root returns 302 redirect; `/auth` returns bare 401)
- The middleware chain order matters: trailing-slash → forwardAuth → stripPrefix
- For ArgoCD-managed Ingress resources, warn that patches will be reverted on next sync — source repos need updating too

## Reporting
After completion, produce a numbered summary of all issues encountered and their fixes. The user uses this to update migration documentation. Include: what was patched, which TLS secrets were copied, which oauth2-proxy deployments were updated, and any remaining manual steps.
