#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

readonly CGREEN='\033[0;32m'
readonly CRED='\033[0;31m'
readonly CRESET='\033[0m'

function usage() {
    cat >&2 <<EOHELP
Usage:  $0 BLACKLIST
Test site blacklist using ping.
EOHELP
    exit 1
}

function test_site() {
    local site="$1"; shift

    echo -n "Testing site '${site}' "

    if ping -q -c 2 "${site}" 1>/dev/null 2>/dev/null; then
        echo -e "[${CRED}FAIL${CRESET}]"
        return 1
    fi

    echo -e "[${CGREEN}OK${CRESET}]"
    return 0
}

function test_blacklist() {
    local blacklist="$1"; shift

    if [ ! -f "${blacklist}" ]; then
        >&2 echo "Blacklist '${blacklist}' not found!"
        return 1
    fi

    local count=0
    while read site; do
        test_site "${site}" || count=$((count + 1))
    done <"${blacklist}"

    echo
    if [ ${count} -gt 0 ]; then
        echo -e "${CRED}${count} site(s) not blocked!${CRESET}"
        return 1
    fi

    echo -e "${CGREEN}All sites on blacklist are blocked!${CRESET}"
}

if [ $# -eq 1 -a "--help" == "${1:-}" ] || [ $# -ne 1 ]; then
    usage
fi

test_blacklist "$@"

