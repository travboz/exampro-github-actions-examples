#!/bin/bash

USERNAME=travboz
REPO_NAME=exampro-github-actions-examples
ENDPOINT=https://api.github.com/repos/$USERNAME/$REPO_NAME/dispatches

if [ -z "$API_KEY" ]; then
  read -s -p "Enter GitHub token: " API_KEY
  echo
fi

echo "The workflow is looking for a repository_dispatch with an [event_type] = \"pizza\"."

curl --request POST \
    --url "$ENDPOINT" \
    --header "Accept: application/vnd.github+json" \
    --header "Authorization: token $API_KEY" \
    --data '{"event_type": "pizza", "client_payload": {"name": "Travis"}}'