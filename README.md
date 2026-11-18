# Octen Search for Hermes

Use [Octen](https://octen.ai) as the backend for Hermes' existing `web_search` and `web_extract` tools. Search results include query-focused highlights; extraction returns page content as Markdown.

This is a standalone [Hermes web-search provider plugin](https://hermes-agent.nousresearch.com/docs/developer-guide/web-search-provider-plugin), using the same provider interface as Exa and Tavily. It does not add tool names or modify Hermes core.

## Install and configure

Requires a current Hermes installation with web-search provider plugins, Python 3.11 or newer, and an Octen API key. The plugin uses `httpx`, already included in Hermes.

```sh
hermes plugins install Octen-Team/hermes-octen-plugin
hermes plugins enable web-octen
hermes tools
```

In the web tools setup, select **Octen** and enter your API key, which you can create in the [Octen API Platform](https://octen.ai/platform/api-keys). Hermes stores credentials in the active profile; the plugin also honors an exported `OCTEN_API_KEY`. Never put your key in a URL or commit it to a repository.

If you have never selected a web provider, Hermes picks one on its own from those that are set up. With this plugin enabled and `OCTEN_API_KEY` set, that can be Octen. Once a provider is selected, Hermes always uses that selection.

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

- Search calls `POST https://api.octen.ai/search` and requests highlights without full-page content. Hermes rounds the number of results it asks for up to 10, 20, 50, or 100, the plugin sends that number to Octen as `count`, and Hermes returns only as many results as were requested.
- Extract calls `POST https://api.octen.ai/extract` and requests Markdown. Hermes' `web_extract` tool passes at most 5 URLs per call; the plugin splits larger inputs into requests of at most 20 URLs. Successful pages and per-URL failures retain input order, and a failed request does not discard pages that succeeded. No query is sent, so Octen returns full page content.
- Search timeout is 30 seconds; extraction timeout is 45 seconds per request.
- The plugin reports every failure to Hermes as a failed call, never as an empty success: missing keys, invalid credentials, account access or balance errors, rate limits, network errors, and invalid API responses. Messages are short, for example `Octen returned HTTP 401. Check OCTEN_API_KEY.`, and never include raw error bodies or credentials.
- Hermes continues to handle provider selection, caching, private/credential-bearing URL checks, and truncation of large pages.

By default, Hermes does not pass a failed Octen call on as an error. It retries that call on its keyless free tier and, if that works, returns those results instead. Search results served this way carry `rescued_from: octen`, and `backend_error` holds the plugin's message. The next call goes to Octen again. To get the error instead, run:

```sh
hermes config set web.keyless_rescue false
```

Only the standard search/extract provider interface is exposed. Octen's other API capabilities can be used through the [Octen CLI, SDK, or MCP server](https://docs.octen.ai).

## Stop using Octen

Hermes keeps using the selected provider even after its plugin is gone. Select another provider first, in `hermes tools` or with:

```sh
hermes config set web.backend <provider>
```

If `web.search_backend` or `web.extract_backend` is set to `octen`, remove it so the new selection covers both tools:

```sh
hermes config unset web.search_backend
hermes config unset web.extract_backend
```

Then disable or remove the plugin:

```sh
hermes plugins disable web-octen
hermes plugins remove web-octen
```

`hermes config get web.backend` and `hermes doctor` should both name the provider you selected. If the plugin is disabled or removed while `octen` is still selected, `hermes doctor` lists another provider, but `web_search` fails with `no registered web search provider has that name`.

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
