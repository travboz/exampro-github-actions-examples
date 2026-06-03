#!/bin/bash

# This script is used as the entrypoint.sh for a Docker container custom action.
# It demonstrates how to handle build processes, report errors to GitHub Actions,
# and set output variables that can be used by subsequent steps in a workflow.

# The name of this script, in a real repository, would be: entrypoint.sh

# Example command - runs the build process
make build
exit_status=$?

# Check if the build command failed (exit code is not 0)
if [ $exit_status -ne 0 ]; then
    # Report an error message to GitHub Actions using the error annotation format
    # This will display prominently in the workflow run logs and UI
    echo "::error ::Build failed with exit code $exit_status"
    
    # Exit with the same exit code as the failed build command
    # This signals to the workflow that the action failed (exit code > 0)
    exit $exit_status
fi

# Set an output variable named "status" with the value "success"
# This output can be referenced by other steps in the workflow using: ${{ steps.<step-id>.outputs.status }}
echo "::set-output name=status::success"

# Exit with code 0 to indicate the action completed successfully
# Exit code 0 means the workflow step succeeded
exit 0