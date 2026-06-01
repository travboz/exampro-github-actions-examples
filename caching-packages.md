# Using Caching to store dependencies

We can make our workflows faster and more efficient by creating and using:

`Caches`

We can store our dependencies and other commonly used files in the cache.

Many `setup` actions have caching built in — you just need to enable it.

## Package Manager → Action Cheat Sheet

| Package Manager | Action |
|---|---|
| npm, Yarn, pnpm | `setup-node` |
| pip, pipenv, Poetry | `setup-python` |
| Gradle, Maven | `setup-java` |
| RubyGems (Bundler) | `setup-ruby` |
| Go (`go.sum`) | `setup-go` |

## How to enable it

Each action has its own cache flag. For example, with Ruby:

```yaml
- uses: ruby/setup-ruby@v1
  with:
    bundler-cache: true
```

For Go it looks like:

```yaml
- uses: actions/setup-go@v5
  with:
    cache: true
```

The pattern is the same across the board — use the relevant setup action and flip on its cache option.

Example that caches go dependencies:

```yaml
name: Go CI with cache

on:
  push:
    branches: [main]
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      # Check out your repository so the workflow can access your code.
      - uses: actions/checkout@v6

      # Set up Go and enable the built-in Go dependency cache.
      # This caches dependencies based on `go.sum` by default.
      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.25.x'

      # Use actions/cache to cache build output as well as any extra files
      # you want to reuse between workflow runs.
      #
      # `key` identifies the cache. If `go.sum` changes, the key changes.
      # `restore-keys` lets GitHub fall back to a partial match if the exact
      # key is not found.
      - name: Cache Go build output
        uses: actions/cache@v4
        with:
          path: |
            ~/go/pkg/mod
            ~/.cache/go-build
          key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
          restore-keys: |
            ${{ runner.os }}-go-

      # Download module dependencies.
      - name: Download dependencies
        run: go mod download

      # Build your project.
      - name: Build
        run: go build -v ./...

      # Run tests.
      - name: Test
        run: go test ./...
```

`actions/setup-go` caches Go dependencies by default using `go.sum`, and `actions/cache` gives finer control for caching dependency and build files.
