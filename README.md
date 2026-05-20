# GitHub Actions Demo Repo

This repo is used to explore and follow along with:

[GitHub Actions FreeCodeCamp](https://www.youtube.com/watch?v=Tz7FsunBbfQ)

as a means of attaining the GitHub Actions Certification.

## Script library for reference:

### Manual Trigger using endpoint

```sh
gh workflow run workflow-dispatch-manual-trigger.yaml -f name=Travis -f greeting=Hello -F data=@mydata
echo '{"name":"Travis", "greeting":"Hello"}' | gh workflow run workflow-dispatch-manual-trigger.yaml --json
```

### Webhook Event
 
```sh
curl -X POST \
-H "Accept: application/vnd.github+json" \
-H "Authorization: token {PAT} \
-d '{"event_type": "webhook", "client_payload": {"key": "value"} }' \
https://api.github.com/repos/{owner}/{repo}/dispatches
```