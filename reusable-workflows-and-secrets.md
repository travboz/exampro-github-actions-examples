# GitHub Actions Reusable Workflows and Environment Secrets: A Complete Guide

## Overview

When working with GitHub Actions reusable workflows (workflows that use `on: workflow_call`), there is a common source of confusion around how environment secrets are handled. This guide explains the scoping rules, the limitations, and practical workarounds in plain English with examples.

## The Core Problem

When you call a reusable workflow, **you cannot pass environment secrets from the caller workflow to the reusable workflow**. This is a deliberate design limitation of GitHub Actions, and understanding why requires understanding how secrets are scoped in GitHub.

### The Official Warning

From the [GitHub Actions documentation](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows):

> Environment secrets cannot be passed from the caller workflow as `on.workflow_call` does not support the environment keyword. If you include environment in the reusable workflow at the job level, the environment secret will be used, and not the secret passed from the caller workflow.

## Key Concept: Scoping, Not Shadowing

The behavior of environment secrets in reusable workflows is **scoping**, similar to how environment variables work in programming languages. It is not simple shadowing or precedence—it's about **which secrets are accessible in which execution context**.

### Understanding Scoping

Just like in programming:

- **Repository-level secrets** are accessible to all workflows in that repository
- **Environment-level secrets** are only accessible when a job specifies that environment
- **Job-level variables** only exist within that job's context
- **Step-level variables** only exist within that step's context

Environment secrets follow the same scoping rules. **When a job specifies `environment: production`, it enters a new scope where only that environment's secrets are accessible.**

## Why Can't Environment Secrets Be Passed?

This is the fundamental technical constraint:

1. **Environment secrets are stored credentials**, not workflow values. They exist in GitHub's database, encrypted and tied to a specific environment.

2. **Reusable workflows with `on: workflow_call` can only accept specific input types**: `secrets`, `inputs`, `jobs`, etc. These are designed to be passed as workflow-level values.

3. **The caller workflow cannot specify `environment:`** at the job level when calling a reusable workflow. The `on: workflow_call` keyword explicitly does not support the `environment` keyword on the caller side.

4. **Environment secrets cannot be "piped" or forwarded** between workflows because:
   - They are repository-level constructs, not values that exist in the workflow context
   - Allowing this would break the security model (you could leak a production secret to a non-production workflow)
   - GitHub's design intentionally isolates environment contexts

**In short**: Environment secrets are scoped to their environment. Once you enter a job with `environment: production`, you get that environment's secrets. You can't inject different secrets from outside that scope.

## Secret Syntax: The Hidden Distinction

Here's where it gets confusing: **there is no syntactic difference between accessing a repository secret and accessing an environment secret**.

Both use identical syntax:

```yaml
${{ secrets.API_KEY }}
```

**The only indicator of which secret you're getting is the presence or absence of the `environment:` keyword in the job definition.**

### Example 1: Repository-Level Secret (No Environment)

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying with ${{ secrets.API_KEY }}"
        # This accesses the REPOSITORY-level API_KEY
```

In this example, `${{ secrets.API_KEY }}` refers to the secret stored in **Settings > Secrets and variables > Actions > Repository secrets**.

### Example 2: Environment-Level Secret (With Environment)

```yaml
jobs:
  deploy:
    environment: production  # 👈 This changes which secret you get
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying with ${{ secrets.API_KEY }}"
        # This accesses the PRODUCTION ENVIRONMENT's API_KEY
```

In this example, even though the syntax is identical, `${{ secrets.API_KEY }}` now refers to the secret stored in **Settings > Environments > production > Environment secrets**.

### Example 3: Both Secrets Exist (Scoping in Action)

```yaml
jobs:
  deploy:
    environment: production  # 👈 This specifies an environment scope
    runs-on: ubuntu-latest
    steps:
      - run: echo "API Key: ${{ secrets.API_KEY }}"
        # Output: Uses the PRODUCTION environment's API_KEY
        # If the repo also has an API_KEY, it is NOT used—the environment scope takes precedence
```

If both a repository-level `API_KEY` and a production-environment-level `API_KEY` exist, **the environment-level secret wins**. The environment scope shadows the repository scope.

## The Reusable Workflow Problem

Now combine this scoping rule with reusable workflows:

### Setup: Two Workflows

**Caller workflow (`.github/workflows/main.yml`):**

```yaml
name: Main Workflow
on: push

jobs:
  call-reusable:
    uses: ./.github/workflows/deploy.yml
    secrets:
      API_KEY: ${{ secrets.PROD_API_KEY }}
```

**Reusable workflow (`.github/workflows/deploy.yml`):**

```yaml
on:
  workflow_call:
    secrets:
      API_KEY:
        required: true

jobs:
  deploy:
    environment: production
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying with ${{ secrets.API_KEY }}"
```

### What Happens

1. The caller workflow tries to pass `secrets.PROD_API_KEY` to the reusable workflow
2. The reusable workflow specifies `environment: production` on its job
3. **Result**: The reusable workflow uses the `production` environment's `API_KEY`, NOT the one passed by the caller

The caller's secret is essentially ignored because the reusable workflow is now in the `production` environment scope, and only that environment's secrets are accessible.

### Why This Happens

- The caller cannot specify `environment:` at the job level (not supported by `on: workflow_call`)
- The reusable workflow CAN specify `environment:` and creates its own scope
- Once you enter that environment scope, only that environment's secrets are available
- The passed secret never enters that scope

## The Workaround: Use Repository Secrets

The key to the workaround is understanding that **repository-level secrets can be passed to reusable workflows, but environment-level secrets cannot**.

### Workaround 1: Store Secrets at Repository Level

Instead of storing secrets in an environment, store them in the repository:

**Store the secret here:**

- Go to **Settings > Secrets and variables > Actions > Repository secrets**
- Add `PROD_API_KEY` at the repository level

**Caller workflow:**

```yaml
jobs:
  call-reusable:
    uses: ./.github/workflows/deploy.yml
    secrets:
      API_KEY: ${{ secrets.PROD_API_KEY }}  # ✅ This works
```

**Reusable workflow:**

```yaml
on:
  workflow_call:
    secrets:
      API_KEY:
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest  # ❌ No environment specified
    steps:
      - run: echo "Deploying with ${{ secrets.API_KEY }}"
        # This receives the API_KEY passed from the caller
```

The key difference: **The reusable workflow does NOT specify `environment:`**, so it stays in the repository scope where the passed secret is accessible.

### Workaround 2: Access Environment Secrets Directly in Reusable Workflow

If you need environment-specific secrets, have the reusable workflow specify the environment and access those secrets directly:

**Caller workflow:**

```yaml
jobs:
  call-reusable:
    uses: ./.github/workflows/deploy.yml
    # ❌ Don't try to pass environment secrets
```

**Reusable workflow:**

```yaml
on:
  workflow_call:

jobs:
  deploy:
    environment: production  # 👈 The reusable workflow specifies its environment
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying with ${{ secrets.API_KEY }}"
        # This accesses the PRODUCTION environment's API_KEY directly
```

In this approach, the reusable workflow is responsible for knowing which environment to use. The caller doesn't need to (and can't) specify it.

### Workaround 3: Mix Both Approaches

Use repository secrets for generic values and environment secrets for environment-specific values:

**Caller workflow:**

```yaml
jobs:
  call-reusable:
    uses: ./.github/workflows/deploy.yml
    secrets:
      GENERIC_TOKEN: ${{ secrets.GITHUB_TOKEN }}  # Repository secret
```

**Reusable workflow:**

```yaml
on:
  workflow_call:
    secrets:
      GENERIC_TOKEN:
        required: true

jobs:
  deploy:
    environment: production  # Environment-level secrets
    runs-on: ubuntu-latest
    steps:
      - run: |
          echo "Generic token: ${{ secrets.GENERIC_TOKEN }}"
          echo "Environment key: ${{ secrets.PROD_API_KEY }}"
          # GENERIC_TOKEN comes from the caller (repository secret)
          # PROD_API_KEY comes from the production environment
```

## Complete Examples

### Example 1: Simple Passing of Repository Secrets

**`.github/workflows/main.yml` (Caller):**

```yaml
name: Deploy Application
on:
  push:
    branches: [main]

jobs:
  call-deploy:
    uses: ./.github/workflows/deploy.yml
    secrets:
      DATABASE_URL: ${{ secrets.DATABASE_URL }}
      API_KEY: ${{ secrets.API_KEY }}
```

**`.github/workflows/deploy.yml` (Reusable):**

```yaml
on:
  workflow_call:
    secrets:
      DATABASE_URL:
        required: true
      API_KEY:
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy
        run: |
          echo "Using database: ${{ secrets.DATABASE_URL }}"
          echo "Using API key: ${{ secrets.API_KEY }}"
```

**Result:** ✅ Works. Both secrets are repository-level and successfully passed.

---

### Example 2: Environment Secrets in Reusable Workflow (No Passing)

**`.github/workflows/main.yml` (Caller):**

```yaml
name: Production Deploy
on:
  push:
    branches: [main]

jobs:
  call-prod-deploy:
    uses: ./.github/workflows/deploy-prod.yml
```

**`.github/workflows/deploy-prod.yml` (Reusable):**

```yaml
on:
  workflow_call:

jobs:
  deploy:
    environment: production
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to Production
        run: |
          echo "Using production API key: ${{ secrets.PROD_API_KEY }}"
          # PROD_API_KEY is stored in the production environment
          # It's accessed directly, not passed from caller
```

**Result:** ✅ Works. The reusable workflow uses its own environment's secrets.

---

### Example 3: Attempting to Pass Environment Secrets (Fails)

**`.github/workflows/main.yml` (Caller):**

```yaml
name: Deploy Application
on:
  push:
    branches: [main]

jobs:
  call-deploy:
    # ❌ This doesn't work
    environment: production
    uses: ./.github/workflows/deploy.yml
    secrets:
      API_KEY: ${{ secrets.PROD_API_KEY }}
```

**Error:** `environment` is not supported in `workflow_call` jobs. The caller cannot specify an environment.

---

### Example 4: Scoping in Action (Same Secret Name, Different Values)

**Repository setup:**

- Repository secret: `API_KEY` = `repo-secret-123`
- Production environment secret: `API_KEY` = `prod-secret-456`

**`.github/workflows/main.yml`:**

```yaml
jobs:
  test-repo-secret:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Repo API Key: ${{ secrets.API_KEY }}"
        # Output: Repo API Key: repo-secret-123

  test-prod-secret:
    environment: production
    runs-on: ubuntu-latest
    steps:
      - run: echo "Prod API Key: ${{ secrets.API_KEY }}"
        # Output: Prod API Key: prod-secret-456
```

**Result:** Same variable name, different values based on scope. The `environment: production` keyword determines which scope you're in.

---

### Example 5: The Tricky Reusable Workflow Scenario

**Setup:**

- Repository secret: `API_KEY` = `repo-value`
- Production environment secret: `API_KEY` = `prod-value`

**`.github/workflows/main.yml` (Caller):**

```yaml
jobs:
  call-deploy:
    uses: ./.github/workflows/deploy.yml
    secrets:
      API_KEY: ${{ secrets.API_KEY }}  # Passes the repo-level API_KEY
```

**`.github/workflows/deploy.yml` (Reusable):**

```yaml
on:
  workflow_call:
    secrets:
      API_KEY:
        required: true

jobs:
  deploy:
    environment: production
    runs-on: ubuntu-latest
    steps:
      - run: echo "API Key: ${{ secrets.API_KEY }}"
        # Output: API Key: prod-value
        # NOT: repo-value
```

**What happened:**

1. The caller tried to pass `repo-value` (the repository-level secret)
2. The reusable workflow specified `environment: production`
3. Result: The production environment scope takes over, and the production `API_KEY` is used instead
4. The passed secret is ignored

This is the core issue the warning is about.

## Summary Table

| Scenario | Syntax | Secret Source | Works in Reusable Workflows? |
|----------|--------|----------------|------------------------------|
| Repository secret, no environment | `${{ secrets.KEY }}` | Repository | ✅ Yes, can be passed |
| Environment secret, with environment | `${{ secrets.KEY }}` | Environment | ❌ No, cannot be passed |
| Same secret name, both exist | `${{ secrets.KEY }}` | Depends on `environment:` keyword | Environment scope wins if specified |
| Reusable workflow with environment | `${{ secrets.KEY }}` | The reusable workflow's environment | ✅ Yes, but caller can't override |

## Key Takeaways

1. **Syntax is identical, but scoping matters**: `${{ secrets.API_KEY }}` can refer to either a repository secret or an environment secret. The `environment:` keyword in the job definition determines which one.

2. **The `environment:` keyword creates a scope boundary**: Once a job specifies `environment: production`, only that environment's secrets are accessible. Repository-level secrets are shadowed.

3. **Reusable workflows can't receive environment secrets**: The caller cannot specify `environment:` when calling a reusable workflow, so environment-level secrets cannot be passed.

4. **Repository secrets are passable, environment secrets are not**: Store secrets at the repository level if you need to pass them to reusable workflows. Store them at the environment level if the reusable workflow itself will use them directly.

5. **It's scoping, not simple precedence**: This follows standard programming language scoping rules. Inner scopes (environments) take precedence over outer scopes (repository).

## References

- [GitHub Actions: Reuse workflows](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows)
- [GitHub Actions: Managing environments for deployment](https://docs.github.com/en/actions/deployment/targeting-different-environments/managing-environments-for-deployment)
- [GitHub Actions: Workflow syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
