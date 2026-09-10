# Octen Search for Hermes

Use [Octen](https://octen.ai) as the backend for Hermes' existing `web_search` and `web_extract` tools. Search results include query-focused highlights; extraction returns page content in Markdown or plain text.

This is a standalone [Hermes web-search provider plugin](https://hermes-agent.nousresearch.com/docs/developer-guide/web-search-provider-plugin), using the same provider interface as Exa and Tavily. It does not add tool names or modify Hermes core.

## Install and configure

Requires a current Hermes installation with web-search provider plugins, Python 3.11 or newer, and an Octen API key. The plugin uses `httpx`, already included in Hermes.

```sh
hermes plugins install Octen-Team/hermes-octen-plugin
hermes plugins enable web-octen
hermes tools
```

In the web tools setup, select **Octen** and enter your API key. Hermes stores credentials in the active profile; the plugin also honors an exported `OCTEN_API_KEY`. Never put your key in a URL or commit it to a repository.

For manual configuration, set the existing keys in your active Hermes profile's `config.yaml`:

```yaml
plugins:
  enabled:
    - web-octen
web:
  search_backend: octen
  extract_backend: octen
```

Merge these entries with your existing configuration, preserving other enabled plugins. Alternatively, `web.backend: octen` selects Octen for both capabilities. Start a new Hermes session after changing providers.

Ask Hermes to search for a topic, then read a result URL. You can also pair Octen search with another extraction provider by changing only `web.search_backend`.

## Behavior

- Search calls `POST https://api.octen.ai/search`, maps Hermes' `limit` to Octen's `count` (1–100), and requests highlights without full-page content. Hermes may bucket/cache the request and return only the requested number of hits.
- Extract calls `POST https://api.octen.ai/extract` in batches of at most 20 URLs. Successful pages and per-URL failures retain input order. No query is sent, so Octen returns full page content.
- Search timeout is 30 seconds; extraction timeout is 45 seconds per batch. Failed requests are returned as errors, not empty successes. A failed extraction batch does not discard successful pages from other batches.
- Hermes continues to handle provider selection, caching, private/credential-bearing URL checks, and truncation of large pages.
- Missing keys, invalid credentials, account access/balance errors, rate limits, network errors, and invalid API responses are reported through the existing tools. Raw error bodies and credentials are not included in these messages.

Only the standard search/extract provider interface is exposed. Octen's other API capabilities can be used through the [Octen CLI, SDK, or MCP server](https://docs.octen.ai).

## Development and verification

Clone Hermes and prepare its development environment using the [contribution guide](https://hermes-agent.nousresearch.com/docs/developer-guide/contributing). Keep the Python virtual environment outside both source trees.

Run the plugin tests through Hermes' canonical test runner:

```sh
export HERMES_SOURCE=/path/to/hermes-agent
export HERMES_PYTHON=/path/to/hermes-dev-venv/bin/python
bash scripts/test.sh
```

The tests load the plugin through real discovery in disposable profiles and replace only the HTTP transport. They cover configuration, tool dispatch, request/response contracts, failures, and extraction batching.

For a live check, export `OCTEN_API_KEY` in your shell, then run:

```sh
"$HERMES_PYTHON" scripts/smoke.py
```

This makes a real search and extraction call through Hermes' registered tool handlers, uses a disposable profile, and prints a receipt without the key. Octen API usage applies; no LLM request is made.

From the Hermes checkout, also run:

```sh
"$HERMES_PYTHON" -m hermes_cli.main plugins validate /path/to/hermes-octen-plugin --json
"$HERMES_PYTHON" -m hermes_cli.main plugins doctor /path/to/hermes-octen-plugin --ci
```

API behavior follows the [Octen OpenAPI contract](https://docs.octen.ai/api-reference/openapi.json). Report discrepancies between that contract and the live service instead of introducing undocumented client workarounds.

## Distribution

Installation by repository URL does not require Hermes catalog admission. The [official catalog policy](https://github.com/NousResearch/hermes-agent/blob/main/plugin-catalog/README.md) requires maintainer review, a full commit SHA, and a pinned release at least two weeks old. This plugin is not endorsed by Nous Research merely because it implements the provider interface.

## License

MIT. See [LICENSE](LICENSE).
