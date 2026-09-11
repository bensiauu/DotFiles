# Vendored zellij plugins (pinned)

These `.wasm` files are pinned to specific releases for reproducibility. To update,
download the new release asset, bump the version here, and commit.

| Plugin | Version | Source | Asset |
|--------|---------|--------|-------|
| zjstatus | v0.24.0 | https://github.com/dj95/zjstatus | zjstatus.wasm |
| vim-zellij-navigator | 0.3.0 | https://github.com/hiasr/vim-zellij-navigator | vim-zellij-navigator.wasm |
| zellij-autolock | 0.2.2 | https://github.com/fresh2dev/zellij-autolock | zellij-autolock.wasm |
| zellij-forgot | 0.4.2 | https://github.com/karimould/zellij-forgot | zellij_forgot.wasm |

## Re-download command

```bash
cd ~/.config/zellij/plugins
curl -fL -o zjstatus.wasm              https://github.com/dj95/zjstatus/releases/download/v0.24.0/zjstatus.wasm
curl -fL -o vim-zellij-navigator.wasm  https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm
curl -fL -o zellij-autolock.wasm       https://github.com/fresh2dev/zellij-autolock/releases/download/0.2.2/zellij-autolock.wasm
curl -fL -o zellij_forgot.wasm         https://github.com/karimould/zellij-forgot/releases/download/0.4.2/zellij_forgot.wasm
```

Note: `zellij_forgot.wasm` uses an underscore (matches the upstream release asset name).
