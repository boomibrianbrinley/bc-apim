# bc-apim

Boomi Companion plugin for Boomi API management.

> **Important:** Boomi Companion is a publicly available developer offering, not an officially supported Boomi product. It is provided as-is and is not covered by Boomi support agreements or SLAs. Boomi curates and maintains this tool on a best-effort basis — treat it as a self-service resource. Boomi reserves the right to modify or discontinue it at any time without notice.

This project is licensed under the [BSD-2-Clause License](LICENSE). If you fork or modify this code, you should not use the name "Boomi" for your version.

## Install this fork

This fork adds optional gateway targeting to `boomi-api-gateway` (see the Changelog). It's not on the public marketplace, so install it from a local clone. We tested these steps against Claude Code's plugin CLI in an isolated config.

1. **Remove the upstream plugin**, if you have it installed. Both copies use the plugin name `bc-apim`, so they clash.

   ```
   claude plugin uninstall bc-apim@boomi-companion
   ```

2. **Clone this repo** to a folder you'll keep. Claude Code reads the plugin from this path, so don't move it later.

   ```
   git clone https://github.com/boomi-internal/bc-apim-forked.git
   ```

3. **Add the repo as a local marketplace.** The repo ships its own `.claude-plugin/marketplace.json`, so the folder is the marketplace.

   ```
   claude plugin marketplace add /path/to/bc-apim-forked
   ```

4. **Install the plugin** from that marketplace.

   ```
   claude plugin install bc-apim@bc-apim-forked
   ```

5. **Confirm it loaded.** `claude plugin list` should show `bc-apim@bc-apim-forked` at version `0.0.3`, enabled.

To pick up later changes, run `git pull` in the clone, then `claude plugin marketplace update bc-apim-forked`.

Credentials and environment variables are the same as upstream (see below). Put them in the workspace `.env`, not in the repo.

## Feedback & Issues

Found a bug or have a feature idea? Email developer-offerings@boomi.com with a clear description, steps to reproduce, and any relevant error messages.

## Skills

| Skill | Covers |
|---|---|
| `boomi-api-gateway` | Boomi API Gateway, plans, applications, subscriptions, Developer Portal |
| `boomi-cloud-api-management` | Cloud API Management (CAM), formerly Mashery |
| `boomi-api-control-plane` | API Control Plane (ACP), formerly APIIDA |

## Environment variables

Scripts read these from the workspace `.env`. Never pass them as arguments.

A workspace that already holds Boomi Platform credentials (`BOOMI_USERNAME`, `BOOMI_API_TOKEN`, `BOOMI_ACCOUNT_ID`, as set up by bc-integration) needs nothing more for `boomi-api-gateway` or `boomi-api-control-plane`. Every `ACP_*` variable below is optional, and `boomi-api-gateway` defines no skill-specific variables at all.

| Variable | Used by | Purpose |
|---|---|---|
| `BOOMI_USERNAME`, `BOOMI_API_TOKEN`, `BOOMI_ACCOUNT_ID` | `boomi-api-gateway`, `boomi-api-control-plane` | Boomi Platform credentials, shared with bc-integration. `boomi-api-gateway` sends them as HTTP Basic Auth on every call; `boomi-api-control-plane` exchanges them for a short-lived platform JWT on each script run. |
| `ACP_BASE_URL` | `boomi-api-control-plane` | Optional. API Control Plane tenant backend, `https://<subdomain>.backend.<region>.controlplane.boomi.com`. Derived from the account ID (lowercased, `_` to `-`) on the `na` region when unset; other regions set it explicitly. |
| `ACP_TOKEN` | `boomi-api-control-plane` | Optional. Personal Access Token from the API Control Plane admin portal (Account Settings); replaces the platform JWT when set. |
| `BOOMI_API_URL` | `boomi-api-gateway`, `boomi-api-control-plane` | Optional. Boomi Platform API base (`https://api.boomi.com`). `boomi-api-gateway` calls it directly; `boomi-api-control-plane` uses it for the JWT exchange. |
| `CAM_API_KEY`, `CAM_API_SECRET` | `boomi-cloud-api-management` | "Mashery API: V2 + V3" key and secret from developer.mashery.com. |
| `CAM_USERNAME`, `CAM_PASSWORD` | `boomi-cloud-api-management` | CAM area user, such as the area service account. |
| `CAM_AREA_UUID` | `boomi-cloud-api-management` | Control Center → **?** (top right) → Area Information. |
| `CAM_API_URL` | `boomi-cloud-api-management` | Optional. Defaults to `https://api.mashery.com`. |
| `CAM_QPS` | `boomi-cloud-api-management` | Optional. Management API calls per second (2). |
| `BOOMI_TIMEOUT`, `BOOMI_VERIFY_SSL` | `boomi-api-gateway`, `boomi-api-control-plane` | Optional. Request timeout in seconds (60) and `false` to skip TLS verification. |
