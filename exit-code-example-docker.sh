#!/bin/bash -l

# Docker Container action entrypoint script
# The -l flag sources login shell configuration files (.bashrc, .bash_profile, .profile, etc.)
# This is useful when the action needs:
#   - Access to shell aliases or functions defined in login configs
#   - Proper PATH configuration from shell startup files
#   - Environment variables set in shell profiles
#   - Consistent shell behavior across different container environments
# Without -l, the shell runs as a non-login shell and skips these configuration files

# Setting environment variables that persist across steps in the workflow
# $GITHUB_ENV is a special GitHub Actions environment file
# Variables written here will be available to all subsequent steps in the same job
echo "API_KEY=abc123" >> $GITHUB_ENV

# Running a test script and capturing its exit code
# The exit code indicates whether the tests passed (0) or failed (non-zero)
./run-tests.sh
exit_status=$?

# Check if the test script failed (exit code is not 0)
if [ $exit_status -ne 0 ]; then
    # Report an error message to GitHub Actions using the error annotation format
    # This will display prominently in the workflow run logs and UI
    echo "::error ::Tests failed"
    
    # Exit with the same exit code as the failed test command
    # This signals to the workflow that the action failed
    exit $exit_status
fi

# Setting output parameters for the action
# $GITHUB_OUTPUT is a special GitHub Actions file used to define outputs
# The format is: name=value
# This output can be referenced by other steps using: ${{ steps.<step-id>.outputs.test-result }}
echo "test-result=passed" >> $GITHUB_OUTPUT

# Print a success message to the workflow logs
# This is informational and helps users see that the action completed without errors
echo "Action completed successfully"

# Implicit exit with code 0 (success) when the script completes
# Exit code 0 signals that the action completed successfully