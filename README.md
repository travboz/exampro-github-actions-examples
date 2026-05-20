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

## Expressions for reference:

| Function | Signature | Example |
|----------|-----------|---------|
| `contains` | `contains(search, item)` | `contains('Hello world', 'llo')` |
| `startsWith` | `startsWith(searchString, searchValue)` | `startsWith('Hello world', 'He')` |
| `endsWith` | `endsWith(searchString, searchValue)` | `endsWith('Hello world', 'ld')` |
| `format` | `format(string, replaceValue0, replaceValue1, ..., replaceValueN)` | `format('Hello {0} {1} {2}', 'Mona', 'the', 'Octocat')` |
| `join` | `join(array, optionalSeparator)` | `join(github.event.issue.labels.*.name, ', ')` |
| `toJSON` | `toJSON(value)` | `toJSON(job)` |
| `fromJSON` | `fromJSON(value)` | — |
| `hashFiles` | `hashFiles(path)` | `hashFiles('**/package-lock.json', '**/Gemfile.lock')` |

| Status Check Function | Description |
|-----------------------|-------------|
| `success()` | Returns `true` when none of the previous steps have failed or been cancelled |
| `always()` | Always returns `true`, even if cancelled |
| `cancelled()` | Returns `true` if the workflow was cancelled |
| `failure()` | Returns `true` when any previous step of a job fails |