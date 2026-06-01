# Publish a GitHub Package Using a Workflow

## What is a GitHub Package?

A GitHub Package is an artifact you publish to **GitHub Packages** — GitHub's built-in registry for hosting things your code produces or depends on.

Think of it like npm, Docker Hub, or PyPI, but living right next to your repo on GitHub. Supported registries include:

- **Container registry** — Docker/OCI images (`ghcr.io`)
- **npm** — JavaScript packages
- **Maven/Gradle** — Java packages
- **NuGet** — .NET packages
- **RubyGems** — Ruby gems

## Publishing a Go API as a Container Image

The most common use case for a Go API is publishing a container image to `ghcr.io` — GitHub's container registry.

### The Flow

1. Write a `Dockerfile` that builds your Go binary and packages it into a minimal image
2. A GitHub Actions workflow builds that image and pushes it to `ghcr.io`

The published package ends up at:

```
ghcr.io/your-username/your-repo:latest
ghcr.io/your-username/your-repo:a3f9c12   ← tagged with the commit SHA
```

### Running the Published Image

Anywhere you want to run it — a DigitalOcean droplet, a VPS, locally — you just pull and run:

```bash
docker pull ghcr.io/your-username/your-repo:latest
docker run -p 8080:8080 ghcr.io/your-username/your-repo:latest
```

No need to clone the repo, install Go, or build anything. The runnable artifact is self-contained.

## Example Workflow

```yaml
name: Publish Docker Image

on:
  push:
    branches:
      - main

jobs:
  publish:
    runs-on: ubuntu-latest

    permissions:
      contents: read
      packages: write  # required to push to ghcr.io

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Log in to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          push: true
          tags: |
            ghcr.io/${{ github.repository }}:latest
            ghcr.io/${{ github.repository }}:${{ github.sha }}
```

### Key Points

- `permissions.packages: write` — the `GITHUB_TOKEN` needs this scope to push to `ghcr.io`
- `github.repository` — expands to `your-username/your-repo`, so the image path is built automatically
- `github.sha` — tags the image with the commit SHA for traceability; you always know exactly what code is inside
- No external credentials needed — `GITHUB_TOKEN` handles auth within the same repo/org

## Attestations

### What is an attestation? (simple version)

Imagine you bake a cake and put it in a box. Someone opens the box later and asks: *"did you actually bake this, or did someone tamper with it on the way here?"*

An attestation is a **signed note stapled to the box** that says: *"this cake was baked by Travis, in this kitchen, using this recipe, at 3pm on Tuesday."* The note is signed in a way that can't be faked — so anyone can check it and trust it.

In software terms: when your workflow builds and publishes a Docker image, an attestation is a cryptographically signed record that says *"this image was built by this workflow, from this exact commit, on this date."* Anyone who downloads your image can verify that record and confirm it hasn't been tampered with.

### Why do we need one?

Without an attestation, there's no way to prove that the image sitting on `ghcr.io` actually came from your source code. Someone with access to the registry could theoretically swap it out, and nobody would know.

Attestations solve a **supply chain security** problem — the risk that software gets tampered with *between* the source code and the thing that actually runs in production. They're increasingly expected in professional and open source projects.

### What does it contain?

The signed record includes:

- The repo it was built from
- The exact commit SHA
- The workflow that ran
- The GitHub Actions runner environment
- A timestamp

### Adding an attestation to the workflow

Add this step after your build-and-push step:

```yaml
- name: Attest build provenance
  uses: actions/attest-build-provenance@v1
  with:
    subject-name: ghcr.io/${{ github.repository }}
    subject-digest: ${{ steps.build.outputs.digest }}
```

You'll also need to add `id-token: write` to your job permissions so GitHub can sign the attestation:

```yaml
permissions:
  contents: read
  packages: write
  id-token: write  # required for attestation signing
```

### Verifying an attestation

Anyone can verify the attestation later using the `gh` CLI:

```bash
gh attestation verify oci://ghcr.io/your-username/your-repo:latest
```

If it passes, you know the image is exactly what was built by the workflow — untouched.

## Publishing a package using an action

We can use GitHub Actions to automatically **publish packages** as part of our **CI workflow**.

For example:

- We could create a workflow that runs CI tests every time I push code to a particular branch.
- If the tests **`pass`**, the workflow can publish a new package version to GitHub Packages.


### Actual example time

The [following example](https://docs.github.com/en/packages/managing-github-packages-using-github-actions-workflows/publishing-and-installing-a-package-with-github-actions#publishing-a-package-using-an-action) demonstrates how:

- to use GitHub Actions to build my app
- then automatically create a Docker image and publish it to GitHub Packages

```yaml
#
name: Create and publish a Docker image

# Configures this workflow to run every time a change is pushed to the branch called `release`.
on:
  push:
    branches: ['release']

# Defines two custom environment variables for the workflow. These are used for the Container registry domain, and a name for the Docker image that this workflow builds.
env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

# There is a single job in this workflow. It's configured to run on the latest available version of Ubuntu.
jobs:
  build-and-push-image:
    runs-on: ubuntu-latest
    # Sets the permissions granted to the `GITHUB_TOKEN` for the actions in this job.
    permissions:
      contents: read        # Allows the workflow to read repository contents
      packages: write       # Allows the workflow to upload and publish packages
      attestations: write   # Allows the workflow to generate an artifact attestation for a build
      id-token: write       # Allows the workflow to fetch an OpenID Connect (OIDC) token
      #
    steps:
      - name: Checkout repository
        uses: actions/checkout@v6
      # Uses the `docker/login-action` action to log in to the Container registry using the account and password that will publish the packages. Once published, the packages are scoped to the account defined here.
      - name: Log in to the Container registry
        uses: docker/login-action@65b78e6e13532edd9afa3aa52ac7964289d1a9c1
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      # This step uses [docker/metadata-action](https://github.com/docker/metadata-action#about) to extract tags and labels that will be applied to the specified image. The `id` "meta" allows the output of this step to be referenced in a subsequent step. The `images` value provides the base name for the tags and labels.
      - name: Extract metadata (tags, labels) for Docker
        id: meta
        uses: docker/metadata-action@9ec57ed1fcdbf14dcef7dfbe97b2010124a938b7
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
      # This step uses the `docker/build-push-action` action to build the image, based on your repository's `Dockerfile`. If the build succeeds, it pushes the image to GitHub Packages.
      # It uses the `context` parameter to define the build's context as the set of files located in the specified path. For more information, see [Usage](https://github.com/docker/build-push-action#usage) in the README of the `docker/build-push-action` repository.
      # It uses the `tags` and `labels` parameters to tag and label the image with the output from the "meta" step.
      - name: Build and push Docker image
        id: push
        uses: docker/build-push-action@f2a1d5e99d037542a71f64918e516c093c6f3fc4
        with: # inputs defined by the action - see docker/build-push-action's action.yml for list of inputs
          context: . # literally the same as the context argument passed to a docker build command
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
      
      # This step generates an artifact attestation for the image, which is an unforgeable statement about where and how it was built. It increases supply chain security for people who consume the image. For more information, see [Using artifact attestations to establish provenance for builds](/actions/security-guides/using-artifact-attestations-to-establish-provenance-for-builds).
      - name: Generate artifact attestation
        uses: actions/attest@v4
        with:
          subject-name: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME}}
          subject-digest: ${{ steps.push.outputs.digest }}
          push-to-registry: true
```
