# Adding Scripts to a Workflow

We can execute bash scripts within a workflow like this:

```yaml

jobs:
    example-job:
        runs-on: ubuntu-latest
        defaults:
            run:
                working-directory: ./scripts
        steps:
            - name: Checkout the repository
              uses: actions/checkout@v6
            
            - name: Run a script from our ./scripts directory
              run: ./say-hello.sh

            - name: Run another script from the dir
              run: ./say-hello-in-french.sh

```

See the docs for [adding scripts to a workflow](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/add-scripts?versionId=free-pro-team%40latest&productId=actions&restPage=how-tos%2Cwrite-workflows%2Cchoose-what-workflows-do%2Cuse-variables).