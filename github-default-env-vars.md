# Default Env Vars set by GitHub

There are a bunch of environment variables set by GitHub by default.

Here is the exhaustive list of [Default environment variables](https://docs.github.com/en/actions/reference/workflows-and-actions/variables#default-environment-variables).

Here's an example of how to access them:

```yaml
name: Example Workflow using the Default Env Vars set by GitHub

on: [push]

jobs:
    example_job:
        runs_on: ubuntu-latest
        steps: 
            - name: Checkout repo code
              uses: actions/checkout@v6

            - name: Print GitHub Environment Variables
              run: |
                echo "Repository name: $GITHUB_REPOSITORY"
                echo "Workflow: $GITHUB_WORKFLOW"
                echo "Action: $GITHUB_ACTION"
                echo "Actor name: $GITHUB_ACTOR"
```
