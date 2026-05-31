# `runs-on` Array Syntax in GitHub Actions

The `runs-on` key accepts either a single string or an **array of strings**. When you provide an array, GitHub uses every label as a filter — a runner must satisfy **all** of them to be selected for the job.

---

## The Core Rule: AND, Not OR

This is the most important thing to understand:

```yaml
# ✅ This means: "find a runner that has BOTH the 'linux' label AND the 'gpu' label"
runs-on: [linux, gpu]

# ❌ This does NOT mean: "run on linux, or if not available, run on a gpu runner"
runs-on: [linux, gpu]  # NOT an OR — NOT a fallback chain
```

GitHub looks for a **single runner** that is registered with every label in the array simultaneously. If no runner has all of them, the job queues indefinitely.

---

## Visual: How Label Matching Works

Given these registered runners in your organisation:

| Runner Name | Registered Labels |
|---|---|
| runner-01 | `linux`, `gpu`, `staging` |
| runner-02 | `linux`, `gpu`, `production` |
| runner-03 | `linux`, `cpu-only`, `staging` |
| runner-04 | `windows`, `cpu-only`, `staging` |

Here is how different `runs-on` arrays resolve:

```yaml
runs-on: [linux, gpu]
# ✅ Matches: runner-01, runner-02  (both have linux AND gpu)
# ❌ Skips:   runner-03             (no gpu label)
# ❌ Skips:   runner-04             (no linux label, no gpu label)

runs-on: [linux, gpu, staging]
# ✅ Matches: runner-01 only        (only one with all three labels)
# ❌ Skips:   runner-02             (missing staging)
# ❌ Skips:   runner-03             (missing gpu)

runs-on: [linux, gpu, production]
# ✅ Matches: runner-02 only
```

---

## Practical Example: Targeting by Environment and Capability

Without arrays, you'd have to create compound label names like `gpu-staging` and `gpu-production`. With arrays, you label each dimension independently and combine them at the workflow level.

```yaml
jobs:
  # Route to a GPU runner in the staging environment
  train-model-staging:
    runs-on: [linux, gpu, staging]
    steps:
      - uses: actions/checkout@v4
      - name: Train model (staging data)
        run: python train.py --env staging --epochs 5

  # Route to a GPU runner in the production environment
  train-model-production:
    runs-on: [linux, gpu, production]
    steps:
      - uses: actions/checkout@v4
      - name: Train model (production data)
        run: python train.py --env production --epochs 50

  # Route to a CPU-only runner in staging (cheaper, for quick checks)
  lint-and-test:
    runs-on: [linux, cpu-only, staging]
    steps:
      - uses: actions/checkout@v4
      - name: Run linter
        run: golangci-lint run ./...
```

Each job lands on exactly the right runner without any compound label names.

---

## Combining with a Matrix

The array syntax becomes very powerful combined with a `matrix`. You can fan out jobs across runner dimensions without writing separate job blocks.

```yaml
jobs:
  integration-tests:
    strategy:
      matrix:
        env: [staging, production]
        arch: [x64, arm64]
    # Produces 4 jobs, each routed to the matching runner:
    #   [linux, staging, x64]
    #   [linux, staging, arm64]
    #   [linux, production, x64]
    #   [linux, production, arm64]
    runs-on: [linux, "${{ matrix.env }}", "${{ matrix.arch }}"]
    steps:
      - uses: actions/checkout@v4
      - name: Run integration tests
        run: ./scripts/integration-test.sh
```

Without the array syntax you'd need four separate job definitions to achieve the same routing.

---

## Common Misconceptions

### ❌ Misconception 1: Arrays work like OR / fallbacks

```yaml
# ❌ WRONG mental model:
# "Use ubuntu-latest, or windows-latest if ubuntu isn't available"
runs-on: [ubuntu-latest, windows-latest]

# What this ACTUALLY does:
# "Find a runner registered with BOTH labels" → no such runner exists
# → job queues forever
```

If you want OR behaviour, use a matrix:

```yaml
# ✅ CORRECT way to run the same job on multiple runner types
strategy:
  matrix:
    os: [ubuntu-latest, windows-latest]
runs-on: ${{ matrix.os }}
```

---

### ❌ Misconception 2: You can add labels to GitHub-hosted runners

```yaml
# ❌ This will NOT give you an Ubuntu runner with a GPU
runs-on: [ubuntu-latest, gpu]
```

GitHub-hosted runners (`ubuntu-latest`, `windows-latest`, `macos-latest`, etc.) have fixed, predefined label sets you cannot extend. Adding extra labels to the array just means no runner will match.

The array syntax is primarily useful when you **control the runner registration** — i.e. self-hosted runners or GitHub's larger hosted runners that you configure with custom labels.

For standard GitHub-hosted runners, a single label is almost always what you want:

```yaml
# ✅ Correct for GitHub-hosted runners
runs-on: ubuntu-latest
```

---

### ❌ Misconception 3: Order matters

```yaml
# These are identical — order has no effect on matching
runs-on: [linux, gpu, staging]
runs-on: [staging, gpu, linux]
runs-on: [gpu, staging, linux]
```

The array is an **unordered set of required labels**. There is no priority order, no "try first", no fallback based on position.

---

### ❌ Misconception 4: A single-element array does something special

```yaml
# This is valid YAML but functionally identical to: runs-on: ubuntu-latest
runs-on: [ubuntu-latest]
```

A one-element array doesn't unlock any behaviour. If you find yourself writing this, just use the string form.

---

## Summary

| Behaviour | Correct? |
|---|---|
| Array means ALL labels must match (AND) | ✅ |
| Array means any label can match (OR) | ❌ |
| Array is a fallback/priority list | ❌ |
| Order of labels in the array matters | ❌ |
| Works well with custom/self-hosted runner labels | ✅ |
| Can extend GitHub-hosted runner capabilities with extra labels | ❌ |
| Combines well with `matrix` for multi-dimension routing | ✅ |

> Note: This was generated by `Claude` after a bit of prompting - this helped to elucidate the docs because they weren't that helpful.
