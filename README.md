# GitHub Actions Demo Repo

This repo is used to explore and follow along with:

[GitHub Actions FreeCodeCamp](https://www.youtube.com/watch?v=Tz7FsunBbfQ)

as a means of attaining the GitHub Actions Certification.

## Script library for reference:

### Manual Trigger using endpoint

```sh
gh workflow run workflow-dispatch-manual-trigger.yaml -f name=Travis -f greeting=Hello -F data=@mydata
echo '{"name":"Travis", "greeting":"Hello"}' | gh workflow run workflow-dispatch-manual-trigger.yaml --json
```

## Repository Dispatch and Webhook event types: `repository_dispatch` and `types`

### What is `repository_dispatch`?

`repository_dispatch` is a GitHub Actions event trigger that allows an **external service** to trigger a workflow by sending a POST request to the GitHub API.

The external service hits this endpoint:

```http
POST /repos/{owner}/{repo}/dispatches
```

With a JSON body that includes an `event_type`:

```json
{
  "event_type": "pizza"
}
```

---

### What are `types`?

`types` is a filter under `repository_dispatch`. It's a list of **custom strings you define yourself** — they have no special meaning to GitHub. The workflow will only trigger if the `event_type` in the incoming POST request **exactly matches** one of the strings listed under `types`.

---

### Example

If we have this workflow:

```yaml
name: "Food Order Workflow"

on:
  repository_dispatch:
    types:
      - pizza
```

#### ✅ This WILL trigger the workflow:

```json
{
  "event_type": "pizza"
}
```

The `event_type` matches `pizza` — workflow fires.

#### ❌ This will NOT trigger the workflow:

```json
{
  "event_type": "chicken-wings"
}
```

The `event_type` doesn't match any listed type — workflow is ignored.

---

### Handling multiple types

You can list multiple types if you want the workflow to respond to more than one event:

```yaml
on:
  repository_dispatch:
    types:
      - pizza
      - chicken-wings
      - burger
```

Now all three `event_type` values will trigger the workflow. Anything else (e.g. `"tacos"`) will still be ignored.

---

### Full example

```yaml
name: "Food Order Workflow"

on:
  repository_dispatch:
    types:
      - pizza
      - chicken-wings

jobs:
  handle-order:
    runs-on: ubuntu-latest
    steps:
      - name: Print the order type
        run: echo "Received order: ${{ github.event.action }}"
```

> **Note:** `github.event.action` holds the `event_type` value from the POST request body — so you can use it inside your workflow steps to know which event fired.

### Webhook Event Script


```sh
curl -X POST \
-H "Accept: application/vnd.github+json" \
-H "Authorization: token {PAT} \
-d '{"event_type": "webhook", "client_payload": {"key": "value"} }' \
https://api.github.com/repos/{owner}/{repo}/dispatches
```

### Token permissions for using `repository_dispatch`

When triggering a `workflow_dispatch` or `repository_dispatch`, we're essentially telling GitHub to **create a new workflow run** on the repository.

So, add these permissions to a PAT token:

>- Actions: **Read** and **Write**
>- Contents: **Read** and **Write**

![Permissions required on a PAT for workflow_dispatch and repository_dispatch](perms-dispatch-requirements.png)

## Conditionals

We can use:

```yaml
jobs:
  build:
    if: github.repository == 'travboz/exampro-github-actions-examples'
    runs-on: ubuntu-latest
    steps:
      - name: True - so say hello
        run: |
          echo "Hello ${{ github.actor }}"
```

the conditional `if: github.repository == 'travboz/exampro-github-actions-examples'` to run a job if/if-not a statement is true or false.

Just be aware that to `negate` or reverse a conditional, we do:

`if: ${{ !(github.repository == 'travboz/exampro-github-actions-examples') }}`

We can also use `!=` as well. See [expressions](https://docs.github.com/en/actions/reference/workflows-and-actions/expressions) in the docs.

![ExamPro slide on conditionals](conditionals.png)

## Expressions for reference:

| Function | Signature | Example |
|----------|-----------|---------|
| `contains` | `contains(search, item)` | `contains('Hello world', 'llo')` |
| `startsWith` | `startsWith(searchString, searchValue)` | `startsWith('Hello world', 'He')` |
| `endsWith` | `endsWith(searchString, searchValue)` | `endsWith('Hello world', 'ld')` |
| `format` | `format(string, replaceValue0, replaceValue1, ..., replaceValueN)` | `format('Hello {0} {1} {2}', 'Mona', 'the', 'Octocat')` |
| `join` | `join(array, optionalSeparator)` | `join(github.event.issue.labels.*.name, ', ')` |
| `toJSON` | `toJSON(value)` | `toJSON(job)` |
| `fromJSON` | `fromJSON(value)` | — |
| `hashFiles` | `hashFiles(path)` | `hashFiles('**/package-lock.json', '**/Gemfile.lock')` |

| Status Check Function | Description |
|-----------------------|-------------|
| `success()` | Returns `true` when none of the previous steps have failed or been cancelled |
| `always()` | Always returns `true`, even if cancelled |
| `cancelled()` | Returns `true` if the workflow was cancelled |
| `failure()` | Returns `true` when any previous step of a job fails |

### Single trigger vs. Multiple trigger events

If we there are **multiple event triggers** in a workflow then, if any of those events are triggered, a workflow run starts for that trigger.

<blockquote>So, we could have <strong>multiple workflows</strong> running at once.</blockquote>

#### If we have a `single` trigger: example

```yaml
name: CI on Single **Event**

on:
    push:
        branches: [ main ]

jobs:
    build:
        runs-on: ubuntu-latest
        steps:
            - name: Checkout repository code
              uses: actions/checkout@v6
            
            - name: Run echo to say hello
              run: echo "Hello, ${{ github.actor }}"
```

We have only **one** trigger: a **push** to the **main** branch of the repo.

#### If we have `multiple` triggers: example

```yaml
name: CI on Multiple Events

on:
    push:
        branches:
            - main
    pull_request:
        branches:
            - main
    release:
        types:
            - published
            - created

jobs:
    build-and-test:
        runs-on: ubuntu-latest
        steps:
            - name: Checkout repository code
              uses: actions/checkout@v6
```

We have **three** triggers:

1. a **push** to **main**
2. a **pull request** into **main**
3. a **release** of the code with types **published** and **created**

If **ANY** of these triggers were to occur simultaneously then:

- **MULTIPLE** workflow runs would occur.

## What is a `Runner`?

- we run our workflows on `runners`
- so, it's the underlying compute and OS that's executing our workflow

### Types of `Runner`s

- GitHub-hosted runners
  - linux
  - windows
  - macos
- Self-hosted runners

GitHub runners come in two flavour sizes:

1. standard sized - regular, average systems for simple workflows
2. larger sized - beefier, more RAM, CPU, and disk space for these runners (as well as other features)

> `Larger sized` runners are **`only`** available for organisations and enterprises using GitHub Team or GitHub Enterprise Cloud plans

We specify the `runs-on` within a job in a workflow like this:

```yaml

# specify a specific GitHub-hosted runner
runs-on: ubuntu-latest
runs-on: windows-latest
runs-on: macos-latest

# specify multiple possible runners
runs-on: [ macos-14, macos-13, macos-12 ]s

# use a self-hosted runner
runs-on: self-hosted
```

`jobs.<job_id>.runs-on` can take an array when you want the job to run only on a runner that matches all of the values you list.

So instead of a single runner name, you can combine:

- runner labels, OR
- variables that resolve to labels, OR
- a mix of both

Example:

```yaml
jobs:
  test:
    runs-on: [ubuntu-latest, x64]
    steps:
      - run: echo "Running on a 64-bit Ubuntu runner"
```

In this example, GitHub looks for a runner that matches both `ubuntu-latest` and `x64`.

You can also mix a variable with a string:

```yaml
jobs:
  test:
    runs-on: [${{ vars.RUNNER_OS }}, x64]
    steps:
      - run: echo "Runner selected from a variable"
```

This uses the value stored in `vars.RUNNER_OS` **plus** `x64`, and the job runs on a runner that matches both.

> Be aware of the following:
This is not a fallback list, this is a stupid example and requires a runner to have os 12, 13, AND 14 all installed at the same time.

```yaml
runs-on: [macos-14, macos-13, macos-12]
```

`Copilot` says this:

> No — runs-on: `[macos-14, macos-13, macos-12]` is not a fallback list.
>> In GitHub Actions, when you specify an array in runs-on, the job is queued on runners that have all the labels you list. So this would only work if a runner had macos-14, macos-13, and macos-12 at the same time."

For a single GitHub-hosted runner, use one label, like:

```yaml
runs-on: macos-14
```

If we want to run on multiple machines, use `jobs.<job_id>.strategy` instead (and then use `matrix`).

## Self-hosted runners

Self-hosted runners can run on:

- **Physical hardware** — e.g. your own MacBook or a bare-metal server in your office
- **Virtual machines** — e.g. a VM running on your MacBook via UTM/Parallels, or a cloud VM (AWS EC2, DigitalOcean Droplet)
- **Containers** — e.g. a Docker container (useful for ephemeral, reproducible environments)
- **On-premises infrastructure** — servers inside a private network, behind a firewall
- **Cloud services** — e.g. provisioned dynamically on AWS, GCP, or Azure

Self-hosted runners can be **added at various levels** in a management hierarchy:

1. **`repository-level`** — dedicated to a single repo

   ```yaml
   # Settings > Actions > Runners (within the repo)
   runs-on: [self-hosted, linux, x64]
   ```

2. **`organisation-level`** — shared across multiple repos in an organisation

   ```yaml
   # Settings > Actions > Runners (within the org)
   runs-on: [self-hosted, linux]
   ```

3. **`enterprise-level`** — shared across multiple organisations in an enterprise account

   ```yaml
   # Enterprise settings > Actions > Runners
   runs-on: [self-hosted, linux]
   ```

### How about routing preferences?

GitHub first looks for an:

- a self-hosted runner that's waiting to be given a job (it's `online` and `idle`) - so it's online but not doing anything right now
- the runner's group matches the job's
- the runner's labels matches the job's

Routing behavior:

- If a matching runner is online and idle, the job is assigned to it.
- If the runner doesn't pick up the job within 60 seconds, the job is re-queued.
- If no matching runner is available, the job stays queued until one comes online.
- If it stays queued for more than 24 hours, it fails.

### Default labels

A self-hosted runner automatically receives certain labels when added to GitHub Actions, indicating its OS and hardware platform: `self-hosted` (always applied), `linux`/`windows`/`macOS` (depending on OS), and `x64`/`ARM`/`ARM64` (depending on hardware architecture).

You can also define **custom labels** to target specific runners (e.g. `gpu`, `high-memory`, `production`):

```yaml
jobs:
  train:
    runs-on: [self-hosted, linux, gpu]   # only runs on runners tagged 'gpu'
    steps:
      - uses: actions/checkout@v4
      - run: python train.py --use-gpu
```

### How to become a self-hosted runner

Install the **GitHub Actions Runner** application on your machine and register it with GitHub.

**Repo-level setup** (Settings → Actions → Runners → New self-hosted runner):

```bash
# Download and configure the runner
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-2.x.x.tar.gz -L https://github.com/actions/runner/releases/download/...
tar xzf ./actions-runner-linux-x64-2.x.x.tar.gz

# Register with your repo
./config.sh --url https://github.com/your-org/your-repo --token YOUR_TOKEN

# Start listening for jobs
./run.sh
```

> For production, install it as a **system service** (`./svc.sh install`) so it starts on boot and restarts on failure — rather than running `./run.sh` manually in a terminal.

## Workflow Commands

Workflow commands are how your steps talk back to the runner. When a step runs, the runner watches its output — if it sees a workflow command, it acts on it rather than just logging it.

This lets your shell scripts do things beyond just returning an exit code, such as passing data to later steps, masking sensitive values, or annotating logs with errors and warnings.

There are two forms:

- **Shell commands** — the `::command::` syntax, written to stdout via `echo`
- **Environment files** — writing to special files like `$GITHUB_OUTPUT`, `$GITHUB_ENV`, and `$GITHUB_PATH`

We can do things like this:

- Set environment variables for later steps
- Add directories to PATH
- Set step outputs
- Mask sensitive values
- Annotate logs with errors, warnings, or notices
- Group log lines into collapsible sections

### Setting Env Vars

Set an `environment variable` that's available to all the steps after that in a job.

Example:

```yaml
steps:
  - name: Set up some environment variables
    run: echo "ACTION_ENV=production" >> $GITHUB_ENV
```

Using `>> $GITHUB_ENV` appends `KEY=VALUE` to the special env file, making it available to all subsequent steps in the job (not the current step).

Then we use it like this:

```yaml
steps:
  ...steps in between...
  - name: Using the environment variable
    run: |
      echo "$ACTIONS_ENV"
```

### Adding to the System Path

Add a directory to the system `PATH` for steps following in the job.

Example:

```yaml
steps:
  - name: Add directory to PATH
    run: echo "/path/to/some/dir" >> $GITHUB_PATH
```

Example of practical use:

```yaml
steps:
  - name: Install custom tool
    run: |
      mkdir -p $HOME/tools
      # download or build your binary into $HOME/tools
      echo "$HOME/tools" >> $GITHUB_PATH

  - name: Use the tool
    run: my-tool --version  # works because $HOME/tools is now on PATH
```

`jq` example:

```yaml
steps:
  - name: Install jq to custom path
    run: |
      mkdir -p $HOME/tools
      curl -L https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64 -o $HOME/tools/jq
      chmod +x $HOME/tools/jq
      echo "$HOME/tools" >> $GITHUB_PATH

  - name: Use jq
    run: jq --version
```

>Now this PATH (or tool in this example) will only last the duration of the job.

Common real-world uses:

- Adding a custom Go binary you just built
- Pointing to a specific version of a tool you downloaded manually
- Adding a script directory so your scripts are callable by name

### Setting Output Parameters

Set an output parameter to pass data from one step to later steps in the same job.

Example:

```yaml
steps:
  - name: Set output parameter
    id: my-step
    run: echo "my-key=my-value" >> $GITHUB_OUTPUT
```

Example of practical use:

```yaml
steps:
  - name: Generate build version
    id: versioning
    run: echo "version=1.0.${{ github.run_number }}" >> $GITHUB_OUTPUT

  - name: Use the version
    run: echo "Building version ${{ steps.versioning.outputs.version }}"
```

`git` short SHA example:

```yaml
steps:
  - name: Get short SHA
    id: sha # note this `id` attribute here, it MUST be set so we can reference the step properly
    run: echo "short=${{ github.sha }}" | cut -c1-8 >> $GITHUB_OUTPUT  # first 8 chars of commit SHA

  - name: Use short SHA
    run: echo "Deploying commit ${{ steps.sha.outputs.short }}"
```

> Output parameters are only available within the same job. To pass data between jobs, use job-level `outputs` combined with `needs`.

Common real-world uses:

- Passing a computed version string to a later build or tag step
- Capturing a generated filename so a later step knows what to upload
- Extracting a value from an API response to use in a subsequent step

### Creating Debugging Messages

Create debug messages that appear in the logs of the action logs.

```yaml
steps:
  - name: Create a debug message
    run: echo "::debug::This a debug message - hey, look! A pie in the sky!"
```

### Group Log Messages

We can make logs easier to read by grouping them together.

```yaml

steps:
  - name: Grouping log messages
    run: |
      echo "::group::The Best Group"
      echo "Message 1 into the best group"
      echo "Message 2 into the best grup"
      echo "::endgroup::"
      echo "No more best group"
```

### Masking Values in Logs

Prevent sensitive information from appearing in logs by masking values. Any subsequent occurrence of that value in logs will be replaced with `***`.

> Secrets stored in GitHub Actions are masked automatically. `::add-mask::` is for sensitive values fetched or computed at runtime that GitHub has no prior knowledge of.

Example:

```yaml
steps:
  - name: Mask a value
    run: echo "::add-mask::my-sensitive-value"
```

Example of practical use:

```yaml
steps:
  - name: Fetch and mask API token
    run: |
      TOKEN=$(curl -s https://auth.example.com/token)
      echo "::add-mask::$TOKEN"
      echo "TOKEN=$TOKEN" >> $GITHUB_ENV

  - name: Use token
    run: curl -H "Authorization: $TOKEN" https://api.example.com  # token masked in logs
```

Common real-world uses:

- Masking a dynamically fetched token that isn't stored as a secret
- Masking a derived or computed value that contains sensitive data
- Preventing accidental exposure of sensitive values echoed during debugging

## Workflow Contexts

These are all `objects` that we use to **access information** about:

- workflow runs
- variables
- runner environments
- jobs
- steps
- etc.

We can access a context using expression syntax: `${{ <some_context> }}`

Example:

```yaml
name: CI
on: push
jobs:
  prod-check:
    if: ${{ github.ref == 'refs/heads/main' }} # we're access the 'github' context here
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying to production server on branch $GITHUB_REF"

```

the `if` statement checks the `github` context's `ref` property to determine the current branch name.

See the [contexts reference](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts) page in the docs for an exhaustive list of available contexts.

