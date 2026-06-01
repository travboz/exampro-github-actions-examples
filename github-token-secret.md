# GITHUB_TOKEN

At the start of each workflow job, GitHub automatically creates a unique `GITHUB_TOKEN` secret for that job. It can be used to authenticate against the GitHub API without needing to create a personal access token.

Under the hood, when you enable GitHub Actions, GitHub installs a GitHub App on your repository. `GITHUB_TOKEN` is that app's installation access token — it expires when the job completes.

It's accessed via `${{ secrets.GITHUB_TOKEN }}` and is typically passed to tools like the `gh` CLI via an env var:

```yaml
jobs:
  open-issue:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      issues: write
    steps:
      - run: |
          gh issue --repo ${{ github.repository }} \
            create --title "Issue title" --body "Issue body"
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

The `permissions:` block scopes what the token is allowed to do for that job — always grant the minimum needed.

## GITHUB_TOKEN Permissions

> its permissions are limited to the repository that contains the workflow.

### How it works

- GitHub creates a unique GITHUB_TOKEN for each job.
- The token expires when the job finishes, or after its max lifetime.
- Its permissions come from the default setting for the enterprise, organization, or repository, then are adjusted by the workflow file.
- If a workflow is triggered from a forked repo or Dependabot PR, write permissions are typically reduced to read-only.

### How to add or change permissions

- In your workflow YAML, add a `permissions` key at whatever level (`workflow` or `job`)
- Set permissions at the workflow level or job level
- Use `read`, `write`, or `none` for specific scopes

## How Permissions are set

`GITHUB_TOKEN` permissions are set in layers:

1. Default permissions come from the enterprise, organization, or repository setting.
2. Workflow file permissions can override them with permissions at the top of the workflow.
3. Job-level permissions can override the workflow-level settings for a specific job.
4. For forked pull requests, GitHub may reduce any write permissions to read-only unless the repository setting Send write tokens to workflows from pull requests is enabled.
5. For Dependabot pull requests, the workflow runs as if it came from a forked repo, so the `GITHUB_TOKEN` is read-only and cannot access secrets.
