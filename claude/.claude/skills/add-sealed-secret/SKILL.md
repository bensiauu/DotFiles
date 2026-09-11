---
name: add-sealed-secret
description: Use this skill when the user wants to "create a sealed secret", "seal a secret for <cluster>", "kubeseal X", or "add a SealedSecret for Y". Discovers the target cluster's sealed-secrets controller, fetches/generates the plaintext, seals with explicit `--context`, validates, and surfaces the encryptedData without leaking plaintext into the transcript. Can be invoked standalone or delegated from `add-argocd-app`.
version: 0.1.0
---

# Author a SealedSecret for a Kubernetes cluster

## When to use
The user needs a SealedSecret CRD (`bitnami.com/v1alpha1`) for a cluster running the bitnami-labs sealed-secrets controller. Standalone use, or invoked by `add-argocd-app` for the secret-sealing step of a new-app rollout.

## Inputs to gather
1. **Target cluster** — kubectl context name (the same name appears in `~/.kube/<cluster>.yaml`).
2. **Target Secret** — `name` + `namespace` exactly as the consumers will reference it.
3. **Keys + values** — for each key, one of:
   - Literal value (the user pastes it — avoid; shell history captures it)
   - Recipe (e.g., `pass show <path>`, `openssl rand -base64 32`)
   - "Generate one for me" (skill creates + stashes in `pass`)

## Steps

### A. Pre-flight

1. **`KUBECONFIG` includes the cluster's kubeconfig file:**
   ```bash
   echo "$KUBECONFIG" | tr ':' '\n' | grep <cluster>.yaml
   ```
   If missing, instruct the user to add it (typically in `~/.zshrc`):
   ```bash
   export KUBECONFIG="$KUBECONFIG:$HOME/.kube/<cluster>.yaml"
   ```

2. **Cluster reachable + context resolves:**
   ```bash
   kubectl --context=<ctx> cluster-info | head -2
   ```

3. **Discover the controller — DO NOT assume `kube-system`.** Sealed-secrets is often deployed in a dedicated `sealed-secrets` namespace.
   ```bash
   kubectl --context=<ctx> get pods -A -l app.kubernetes.io/name=sealed-secrets
   # Capture the namespace from the output
   kubectl --context=<ctx> -n <controller-ns> get svc
   # Capture the Service name — typically `sealed-secrets-controller` or `sealed-secrets`
   ```

4. **Smoke-test cert fetch** (verifies controller reachable and `kubeseal` configured):
   ```bash
   kubeseal --context <ctx> \
       --controller-namespace <controller-ns> \
       --controller-name <controller-svc> \
       --fetch-cert > /tmp/<cluster>-cert
   ```
   File should be ~1KB of PEM. If this fails, every later step fails.

### B. Get the plaintext into a shell var

**From `pass`:**
```bash
VAL=$(pass show <path> | tr -d '\n\r')
test -n "$VAL" || { echo "VAL empty — aborting"; return 1; }
echo "length: ${#VAL}"   # sanity-check, NOT the value
```
The `tr -d '\n\r'` is load-bearing — some pass setups append a newline; the trailing whitespace ends up in the sealed value and breaks Bolt/HTTP auth in subtle ways.

**Generate a fresh one and stash:**
```bash
VAL=$(openssl rand -base64 32 | tr -d '/+=' | head -c 24)
echo "$VAL" | pass insert -e <path>
```

**User-supplied literal:**
Discouraged. If the user insists, they paste it directly into the heredoc, not into a shell var (so it doesn't end up in shell history).

### C. Seal

```bash
cat <<EOF | kubeseal --context <ctx> \
    --controller-namespace <controller-ns> \
    --controller-name <controller-svc> \
    --format yaml \
    > /tmp/<name>-sealed.yaml
apiVersion: v1
kind: Secret
metadata:
  name: <name>
  namespace: <target-ns>
type: Opaque
stringData:
  KEY1: "${VAL}"
  # KEY2: "another-value"
EOF
```

Multi-key secrets: list all `stringData` entries in one heredoc. All keys must be sealed in the same invocation if any of them reference the same `$VAL` — re-running with `unset VAL` between gives mismatched values.

### D. Validate

```bash
kubeseal --validate \
  --context <ctx> \
  --controller-namespace <controller-ns> \
  --controller-name <controller-svc> \
  < /tmp/<name>-sealed.yaml && echo OK
```

`--validate` round-trips the sealed YAML against the controller's cert. Silent exit 0 = OK. Any failure means the seal can't be unsealed on apply, so don't commit.

### E. Deliver

**If invoked from another skill** (e.g., `add-argocd-app`): surface only the `spec.encryptedData.*` values for the caller to paste into a placeholder file. Don't ever echo the plaintext.

**If standalone**: write the full SealedSecret YAML to the user's target path, with a self-documenting leading comment block:

```yaml
# <name> — <one-line purpose>
#
# Sealed against the <cluster> cluster's sealed-secrets controller.
# Lives in <repo>/<path> so it's deployed alongside its consumers.
#
# Plaintext source: pass show <path>
# To rotate: re-run the kubeseal recipe below with a new value.
#
#   VAL=$(pass show <path> | tr -d '\n\r')
#   cat <<EOF | kubeseal --context <cluster> \
#                        --controller-namespace <controller-ns> \
#                        --controller-name <controller-svc> \
#                        --format yaml > <name>-sealed.yaml
#   apiVersion: v1
#   kind: Secret
#   metadata:
#     name: <name>
#     namespace: <target-ns>
#   type: Opaque
#   stringData:
#     KEY1: "${VAL}"
#   EOF
#
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: <name>
  namespace: <target-ns>
spec:
  encryptedData:
    KEY1: <base64-encrypted-blob>
  template:
    metadata:
      name: <name>
      namespace: <target-ns>
    type: Opaque
```

### F. Clean up

```bash
rm /tmp/<name>-sealed.yaml /tmp/<cluster>-cert
unset VAL
```

The sealed blob is in git (or about to be); the plaintext should live in `pass` only.

## House style
- **SealedSecret encryption is bound to `(name, namespace, cluster's controller key)`.** Any change to those means re-seal.
- **Always pass `--context <ctx>` explicitly.** Never rely on `current-context` — it changes when you switch terminals and is the source of half the "sealed against wrong cluster" outages.
- **Discover the controller namespace + name.** Don't hard-code `kube-system` — it's wrong on most installs that follow the helm chart's default.
- **Self-document the YAML** with a leading kubeseal recipe so the next rotation is one paste, not an archaeological dig.
- **Placeholder-then-paste workflow** — write the SealedSecret YAML with `REPLACE_ME_WITH_KUBESEAL_OUTPUT` placeholders first, then paste sealed values in. Plaintext never enters the conversation.

## Common pitfalls
- **`error: invalid configuration: context was not found for specified context: <name>, cluster has no server defined`** — `KUBECONFIG` doesn't include the file holding that context. Fix the KUBECONFIG export, don't pass `--kubeconfig`.
- **`cannot get sealed secret service: services "<name>" not found`** — wrong `--controller-namespace` or `--controller-name`. Re-discover (`kubectl get pods -A -l app.kubernetes.io/name=sealed-secrets`).
- **SealedSecret status `Failed to unseal`** after apply — sealed against the wrong cluster's controller, OR the `(name, namespace)` in the sealed metadata doesn't match the consumer's reference. Re-seal with the right context and matching metadata.
- **Sealed value contains a newline** — happens when `pass show` returns a trailing newline and `tr -d '\n\r'` wasn't used. Symptom: app auth fails with no apparent reason, plaintext "looks" right. Always strip whitespace.
- **Empty sealed value** — `pass show` returned empty (gpg unlock failed silently?) or `$VAL` was already `unset` from a previous cleanup. Always `test -n "$VAL"` before sealing.
- **Multi-key seal with mismatched values** — `$VAL` was reset between keys. Seal all keys in one heredoc with one `$VAL`.

## Reporting
- Name + namespace of the sealed secret, target cluster (kubectl context)
- Where the sealed YAML was written (file path, or "delivered to caller skill")
- Validation result (OK / failure)
- Reminder: `unset VAL && rm /tmp/*-sealed.yaml /tmp/*-cert`
- If a new password was generated: confirm it's stashed in `pass` (with the path)
