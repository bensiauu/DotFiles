---
name: terraform-module-scaffold
description: Use this skill when the user asks to "scaffold a terraform module", "new terraform module", "create a tf module for X", or starts authoring a new module from scratch. Produces a HashiCorp-standard module layout with all the files the user's house style requires. Delegate to the terraform-engineer agent for the substantive resource definitions.
version: 0.1.0
---

# Scaffold a Terraform module

## When to use
The user wants a fresh Terraform module — typical phrasing: "new tf module for an S3 bucket", "scaffold a vpc module", "create a module that…". If they're editing an existing module instead, use the terraform-engineer agent directly without this skill.

## Output layout (HashiCorp standard)
```
<module-name>/
  main.tf          # resources + module blocks
  variables.tf     # `variable` blocks, all with `description` + `type` + sensible default or `nullable = false`
  outputs.tf       # `output` blocks, `sensitive = true` where needed
  versions.tf      # required_version + required_providers (pinned)
  README.md        # generated-friendly: title, usage example, inputs/outputs tables
  examples/
    basic/
      main.tf
      versions.tf
  tests/
    basic.tftest.hcl   # native terraform test file
```

## House style (matches the user's global CLAUDE.md)
- Pin `required_version = ">= 1.6"` and every provider with a `~>` constraint.
- Surface a single `var.tags` (map(string)) and merge with resource-specific tags.
- Prefer `for_each` over `count` for keyed sets.
- Sensitive outputs marked `sensitive = true`.
- README usage block must show the minimum-viable invocation.

## Steps
1. Ask the user for:
   - module name
   - cloud provider (aws / azurerm / google / kubernetes / null)
   - one-sentence purpose (becomes the README intro)
2. Create the directory tree above.
3. Write `versions.tf` with pinned versions.
4. Write `variables.tf` with at minimum `name`, `tags`, and one or two provider-typical inputs (e.g. `region` for AWS).
5. Write a stub `main.tf` with a TODO comment showing where resource blocks go, and the resource-specific tag-merge pattern.
6. Write `outputs.tf` with at least `id` and `arn`/`self_link` placeholders.
7. Write the `examples/basic/` invocation.
8. Write a `tests/basic.tftest.hcl` plan-only test.
9. Generate `README.md` with the inputs/outputs tables (note: `terraform-docs` will refresh these automatically if installed).
10. Hand off the substantive resource definitions to the `terraform-engineer` agent.

## Reporting
List the tree created, the pinned versions chosen, and the next prompt for `terraform-engineer`.
