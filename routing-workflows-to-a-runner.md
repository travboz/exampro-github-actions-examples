# Getting a workflow to run on a runner: Routing

## Self-Hosted Runner Labels

When you add a self-hosted runner to GitHub Actions, it automatically gets a set of default labels based on what machine it is. You can also add your own custom labels on top of those.

---

### Default Labels (Auto-assigned)

Every self-hosted runner gets three default labels:

1. **`self-hosted`** — always applied, marks it as a self-hosted runner (not GitHub-hosted)
2. **OS label** — `linux`, `windows`, or `macos` depending on the machine's operating system
3. **Architecture label** — `x64`, `ARM`, or `ARM64` depending on the hardware

So a Linux machine on an ARM64 chip would automatically get: `self-hosted`, `linux`, `ARM64`.

```yaml
runs-on: [self-hosted, linux, ARM64]
```

---

### Custom Labels (You define them)

You can create and assign your own labels to self-hosted runners at any time. Custom labels let you route specific jobs to specific runners — for example, sending GPU-heavy jobs only to machines that have a GPU.

```yaml
runs-on: [self-hosted, linux, x64, gpu]
# "gpu" is a custom label — the rest are default
```

---

### The Key Thing to Remember: Labels Are Cumulative

When you list multiple labels in `runs-on`, GitHub Actions requires the runner to have **all** of them. It's an AND, not an OR.

So `[self-hosted, linux, x64, gpu]` means: find me a runner that is self-hosted **and** Linux **and** x64 **and** has the gpu label. A runner missing any one of those four won't pick up the job.

## Runner Groups: controlling access to runners (organisations using GitHub Team Plan)

Runner groups are used to collect sets of runners and create a security boundary around them.

`MUST BE` using `GitHub Team Plan` as an `Organisation`.

### What is a runner group?

A runner group is just a named bucket that holds a collection of self-hosted runners. The main reason to use one is **access control** — you can decide which repositories inside your organisation are allowed to use which runners.

Think of it like this: you have a pool of powerful machines, and you don't want every repo in your org sending jobs to them. Runner groups let you say "only these repos can use these runners."

> **Heads up:** Runner groups are a **GitHub Team plan feature** (and above). They're not available on free plans.

---

### The key things to know

**Every runner belongs to exactly one group.**
A runner can't be in two groups at once, but you can move it from one group to another whenever you want.

**New runners land in the default group.**
When you register a new self-hosted runner, it automatically goes into the default group unless you tell it otherwise.

**Access is set at the organisation level.**
You manage runner groups in your org's runner settings. Once a group exists, you can configure which repositories are allowed to send jobs to it — from "all repositories" down to a specific list.

---

### Why would you use this?

A few practical scenarios:

- You have a beefy GPU machine registered as a self-hosted runner. You only want your ML repo to be able to use it, not every repo in the org.
- You have production deployment runners that should only be accessible from your deploy repo, not from random feature branches in other projects.
- You want to separate runners used for internal tools from runners used for public-facing projects.

---

### How jobs target a runner group

In your workflow, you can route a job to a specific runner group using the `group` key under `runs-on`:

```yaml
jobs:
  build:
    runs-on:
      group: my-runner-group # so this job is sent to ANY AVAILABLE runner in the group.
```

You can also combine a group with labels to be more specific:

```yaml
runs-on:
  group: my-runner-group
  labels: [linux, x64] # Now, we're being more selective and targeting only runners in the group that have ALL of these labels.
```

This means: find a runner that is in `my-runner-group` **and** has both the `linux` and `x64` labels.

---

## Summary of Runner Groups

| Concept | Plain English |
|---|---|
| Runner group | A named collection of runners with access controls |
| Default group | Where new runners land automatically |
| Access policy | Which repos in the org can use that group's runners |
| One group per runner | A runner can't be in multiple groups simultaneously |
| Plan requirement | GitHub Team or higher |
