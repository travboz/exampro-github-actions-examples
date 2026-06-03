# Directory structure for Custom Actions

## JavaScript Actions

```bash
/your-action-name
    /node_modules
    action.yml
    index.js
    package.json
    README.md
```

The repo containing the action should contain a `root directory` that is **named after the action**.
Inside this directory lives all of our source code and config files.

Example `action.yml`:

```yaml
name: My Custom JavaScript Action
description: A description for the action
inputs:
    my-input:
        description: Example input to use in the action
        required: true
        default: 'some default value for the input'
outputs:
    my-output:
        description: Example output from the action
runs:
    using: 'node12'
    main: 'index.js' # entrypoint for action
```

## Required files for the custom action: JavaScript actions

In the repo containing the custom JavaScript action, the following files are required:

| File | Description |
| -- | -- |
| `action.yml` | Defines the action's inputs, outputs, and main entry point |
| `index.js` | The main JavaScript file that runs when the action is executed. Required if a JavaScript action. |
| `package.json` | Required for dependencies of a JavaScript application, so it's required here too. This also **indicates that the action is a JavaScript action**. |
| `README.md` | Documentation on how to use the action. |

## Docker Container Actions

```bash
/your-docker-action-name
    Dockerfile
    entrypoint.sh
    action.yml
    README.md
```

## Required files for the custom action: Docker Container actions

| File | Description |
| -- | -- |
| `action.yml` | Defines the action's inputs, outputs, and main entry point. This is the metadata file required for all action types. |
| `Dockerfile` | Defines the Docker container image that will be used to execute the action. This is required for Docker container actions. |
| `entrypoint.sh` | The shell script that serves as the entry point for the container. Required if you use the exec form of `ENTRYPOINT` in your Dockerfile to handle arguments from the metadata file. |
| `README.md` | Documentation on how to use the action. |

**Key differences from JavaScript actions:**

- Docker container actions require a `Dockerfile` instead of `index.js` and `package.json`
- Docker container actions may require an `entrypoint.sh` shell script (especially when using exec form `ENTRYPOINT`)
- Docker container actions **only run** on `Linux runners`, whereas JavaScript actions run on Linux, macOS, and Windows
