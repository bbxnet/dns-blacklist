#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEMPLATE="db.blacklist.template"

readonly CGREEN='\033[0;32m'
readonly CRED='\033[0;31m'
readonly CRESET='\033[0m'

function usage() {
    cat >&2 <<EOHELP
Usage:  $0 ZONEFILE PRIMARYDNS SECONDARYDNS HOSTMASTER
Generate blacklist zone file from template '${TEMPLATE}'.
EOHELP
    exit 1
}

function generate_zonefile() {
    local zonefile="$1"; shift
    local primary="$1"; shift
    local secondary="$1"; shift
    local hostmaster="$1"; shift

    if [ ! -f "${TEMPLATE}" ]; then
        >&2 echo "Zone file template '${TEMPLATE}' not found!"
        return 1
    fi

    if [ -f "${zonefile}" ]; then
        >&2 echo "Named zone file '${zonefile}' already exists!"
        return 1
    fi

    echo -n "Generating zonefile '${zonefile}' "

    PRIMARY_DNS="${primary}" \
    SECONDARY_DNS="${secondary}" \
    HOSTMASTER="${hostmaster}" \
    envsubst '${PRIMARY_DNS} ${SECONDARY_DNS} ${HOSTMASTER}' \
        <"${TEMPLATE}" \
        >"${zonefile}"

    if ! named-checkzone -q dummy.local "${zonefile}"; then
        echo -e "[${CRED}FAIL${CRESET}]"
        exit 1
    fi

    echo -e "[${CGREEN}OK${CRESET}]"
}

if [ $# -eq 1 -a "--help" == "${1:-}" ] || [ $# -ne 4 ]; then
    usage
fi

generate_zonefile "$@"

