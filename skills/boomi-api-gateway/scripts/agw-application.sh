#!/usr/bin/env bash
# Application operations (consumer identities that hold API keys).
#
# Without --gateway, create/list use the REST Application object (account-level, unchanged).
# With --gateway <id|name>, create/list use GraphQL DeployedApiApplication, which is the only
# surface that records a gateway. Both paths write the same consumer identity.

source "$(dirname "$0")/agw-common.sh"

usage() {
  cat <<'EOF'
Usage: agw-application.sh <subcommand> [args]

Subcommands:
  list [--applicationName <n>] [--companyName <n>] [--deleted true|false] [--enabled true|false]
  list --gateway <id|name>            applications targeted at one gateway (GraphQL)
  get <application-id>
  create [--gateway <id|name>] <json-file|json-string>
                                      required: applicationName; optional: companyName, companyWebsite, contactName, contactEmail, contactPhone, description, notes, enabled
                                      --gateway targets the application at one gateway (GraphQL); omit for the account-level REST create
  update <application-id> <json-file|json-string>
  delete <application-id>

Credentials from .env: BOOMI_USERNAME, BOOMI_API_TOKEN, BOOMI_ACCOUNT_ID; BOOMI_API_URL optional.
EOF
}
[[ -z "${1:-}" ]] && { usage; exit 0; }
help_requested "$@"

sub="$1"; shift
agw_init

# Creates a gateway-scoped application via GraphQL. Maps the REST-style JSON onto
# DeployedApiApplicationCreateInput. Prints the created object and exits.
create_gateway_application() {
  local gw="$1" json_arg="$2" gwid input vars data
  gwid=$(agw_resolve_gateway "$gw") || exit 1

  json_body "$json_arg"
  input=$(jq -c --arg g "$gwid" '{
      name: .applicationName,
      gatewayId: $g,
      status: (if .enabled == false then "SUSPENDED" else "ENABLED" end),
      ownerName: .contactName,
      ownerEmail: .contactEmail,
      contactPhone: .contactPhone,
      companyName: .companyName,
      companyWebsite: .companyWebsite,
      description: .description,
      notes: .notes
    } | with_entries(select(.value != null and .value != ""))' "$BODY_FILE") || exit 1
  jq -e '.name' >/dev/null <<<"$input" || { echo "ERROR: applicationName is required." >&2; exit 1; }

  vars=$(jq -cn --argjson i "$input" '{input: $i}')
  data=$(agw_graphql 'mutation($input: DeployedApiApplicationCreateInput!) {
      deployedApiApplicationCreate(deployedApiApplication: $input) { id name status gateway { id name } }
    }' "$vars") || exit 1
  echo "$data" | jq '.deployedApiApplicationCreate'
  exit 0
}

# Lists applications targeted at one gateway via GraphQL. Prints the array and exits.
list_gateway_applications() {
  local gwid data vars
  gwid=$(agw_resolve_gateway "$1") || exit 1
  vars=$(jq -cn --arg g "$gwid" '{filter: {gatewayId: $g}}')
  data=$(agw_graphql 'query($filter: DeployedApiApplicationFilter) {
      deployedApiApplications(filter: $filter) { id name status gateway { id name } }
    }' "$vars") || exit 1
  echo "$data" | jq '.deployedApiApplications'
  exit 0
}

case "$sub" in
  list)
    if [[ "${1:-}" == "--gateway" ]]; then
      need "${2:-}" "--gateway needs <id|name>"
      list_gateway_applications "$2"
    fi
    filter=$(agw_filter_from_args "$@")
    agw_query Application "$filter" ; exit 0 ;;
  get)
    need "${1:-}" "Need <application-id>"
    agw_api "$(agw_url "Application/$1")" ;;
  create)
    if [[ "${1:-}" == "--gateway" ]]; then
      need "${2:-}" "--gateway needs <id|name>"
      need "${3:-}" "Need <json-file|json-string>"
      create_gateway_application "$2" "$3"
    fi
    need "${1:-}" "Need <json-file|json-string>"
    json_body "$1"
    agw_api -X POST -H "Content-Type: application/json" --data-binary "@$BODY_FILE" "$(agw_url "Application/")" ;;
  update)
    need "${2:-}" "Need <application-id> <json-file|json-string>"
    json_body "$2"
    agw_api -X POST -H "Content-Type: application/json" --data-binary "@$BODY_FILE" "$(agw_url "Application/$1/update")" ;;
  delete)
    need "${1:-}" "Need <application-id>"
    agw_api -X DELETE "$(agw_url "Application/$1")" ;;
  *) usage >&2; exit 1 ;;
esac

finish
