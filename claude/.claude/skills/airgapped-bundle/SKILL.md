---
name: airgapped-bundle
description: Use this skill when the user wants to "package for airgap", "move to production network", "bundle for SMB transfer", or build an offline artifact set. Delegates to the airgap-deployer agent for the actual transfer mechanics.
version: 0.1.0
---

# Build an airgap transfer bundle

## When to use
The user is preparing to move artifacts from an internet-connected environment to an offline production network. Common signals: "airgap", "SMB share", "internal registry", "production cannot reach the internet".

## Inputs to gather
1. **Bundle name** (short, dated): `<purpose>-<YYYYMMDD>`
2. **What to include**:
   - Container images: list of `<registry>/<repo>:<tag>` references
   - Helm charts: list of `<chart>:<version>` references
   - Terraform providers: list of `<source>` references (need `os_arch` set)
   - Python wheels: a `requirements.txt` and target `--python-version`
   - npm packages: a `package-lock.json`
3. **Target internal registry**: e.g. `internal.registry.lan:5000`
4. **SMB share path** used to cross the airgap (for documentation in `MANIFEST.md`)

## Output layout
```
bundle-<name>/
  MANIFEST.md          # what, why, smb path, expected checksums
  SHA256SUMS
  images/              # docker save tarballs, one per image
  charts/              # helm packages .tgz
  terraform/
    providers/<os>_<arch>/
  python/              # pip wheelhouse
  npm/                 # offline tarballs
  scripts/
    01-verify-checksums.sh
    02-load-images.sh
    03-push-to-internal-registry.sh
    04-helm-push.sh
```

## Recipes

### Container images
Source (online):
```bash
for img in $IMAGES; do
  name=$(echo "$img" | tr '/:' '__')
  docker pull "$img"
  docker save -o "images/${name}.tar" "$img"
done
```
Destination (offline) — generated `02-load-images.sh` does:
```bash
for tar in images/*.tar; do docker load -i "$tar"; done
```
And `03-push-to-internal-registry.sh`:
```bash
for img in $IMAGES; do
  internal="${INTERNAL_REGISTRY}/$(echo "$img" | cut -d/ -f2-)"
  docker tag "$img" "$internal"
  docker push "$internal"
done
```

### Helm
```bash
helm pull <chart> --version <ver> -d charts/
```
Destination: `helm push charts/<chart>-<ver>.tgz oci://${INTERNAL_REGISTRY}/charts`.

### Terraform providers
Source:
```bash
terraform providers mirror -platform=linux_amd64 terraform/providers/
```
Destination — `~/.terraformrc` on the offline host needs:
```hcl
provider_installation {
  filesystem_mirror { path = "/path/to/bundle/terraform/providers" }
  direct { exclude = ["*/*"] }
}
```

### Python wheels
```bash
pip download -r requirements.txt -d python/ --platform manylinux2014_x86_64 \
  --python-version 311 --only-binary=:all:
```
Destination: `pip install --no-index --find-links python/ -r requirements.txt`.

## Steps
1. Gather inputs (above).
2. Create the directory tree.
3. Run the source-side downloads in parallel where safe.
4. Compute checksums: `find . -type f \! -name SHA256SUMS -exec sha256sum {} \; | sort > SHA256SUMS`
5. Write `MANIFEST.md` with: bundle name, contents inventory, SMB path, target registry, total size, build timestamp, who built it.
6. Generate the four destination-side scripts.
7. Hand off to `airgap-deployer` agent for the actual transfer + destination-side execution if needed.

## Hard rules
- Never bundle secrets, PATs, or credentials.
- Image references in production manifests after promotion must point at `${INTERNAL_REGISTRY}`, not the public source.
- The destination side must verify `SHA256SUMS` before running anything else (script `01-verify-checksums.sh`).
