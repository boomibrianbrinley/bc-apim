#!/usr/bin/env bash
# Gateway lookups (read-only). Gateways are listed through the platform GraphQL endpoint.

source "$(dirname "$0")/agw-common.sh"

usage() {
  cat <<'EOF'
Usage: agw-gateway.sh <subcommand> [args]

Subcommands:
  list [--all]        active gateways (id, name, gatewayType); --all includes deleted
  get <gateway-id>    one gateway's details
  environments <gateway-id|name>
                      environments attached to one gateway (id, name, classification)

Credentials from .env: BOOMI_USERNAME, BOOMI_API_TOKEN, BOOMI_ACCOUNT_ID; BOOMI_API_URL optional.
EOF
}
[[ -z "${1:-}" ]] && { usage; exit 0; }
help_requested "$@"

sub="$1"; shift
agw_init

case "$sub" in
  list)
    data=$(agw_graphql 'query { gateways { id name deleted gatewayType } }') || exit 1
    if [[ "${1:-}" == "--all" ]]; then
      echo "$data" | jq '.gateways'
    else
      echo "$data" | jq '[.gateways[] | select(.deleted != true)] | unique_by(.id)'
    fi ;;
  get)
    need "${1:-}" "Need <gateway-id>"
    data=$(agw_graphql 'query($id: ID!) { gateway(id: $id) { id name deleted gatewayType externalUrl effectivePublicUrl version } }' \
      "$(jq -cn --arg id "$1" '{id: $id}')") || exit 1
    echo "$data" | jq '.gateway' ;;
  environments)
    need "${1:-}" "Need <gateway-id|name>"
    gwid=$(agw_resolve_gateway "$1") || exit 1
    # The environments query takes no arguments; each Environment carries its gateway, so filter here.
    data=$(agw_graphql 'query { environments { id name classification gateway { id name } } }') || exit 1
    echo "$data" | jq --arg g "$gwid" '[.environments[] | select(.gateway.id == $g) | {id, name, classification}] | unique_by(.id)' ;;
  *) usage >&2; exit 1 ;;
esac
