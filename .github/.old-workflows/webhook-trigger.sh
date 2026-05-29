#!/bin/bash

# curl -X POST \
#   -H "Authorization: token YOUR_GITHUB_TOKEN" \
#   -H "Accept: application/vnd.github+json" \
#   https://api.github.com/repos/YOUR_ORG/YOUR_REPO/dispatches \
#   -d '{"event_type": "webhook", "client_payload": {"key": "value"}}'

if [ -z "$API_KEY" ]; then
  read -s -p "Enter GitHub token: " API_KEY
  echo
fi

curl -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $API_KEY" \
  https://api.github.com/repos/travboz/exampro-github-actions-examples/dispatches \
  -d '{"event_type": "trigger-workflow", "client_payload": {"name": "Travis"}}'
