#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

readonly ZONEFILE="/etc/bind/db.blacklist"

readonly CGREEN='\033[0;32m'
readonly CRED='\033[0;31m'
readonly CRESET='\033[0m'

function usage() {
    cat >&2 <<EOHELP
Usage:  $0 BLACKLIST NAMEDCONF
Create named blacklist conf file.
EOHELP
    exit 1
}

function generate_zone() {
    local site="$1"; shift

    if [ ${BLACKLIST_STRIP_WWW:-0} -eq 1 ]; then
        site="${site#www.}"
    fi

    echo "zone \"${site}\" { type master; file \"${ZONEFILE}\"; };"
}

function generate_blacklist() {
    local blacklist="$1"; shift
    local namedconf="$1"; shift

    if [ ! -f "${blacklist}" ]; then
        >&2 echo "Blacklist '${blacklist}' not found!"
        return 1
    fi

    if [ -f "${namedconf}" ]; then
        >&2 echo "Named conf file '${namedconf}' already exists!"
        return 1
    fi

    local count=0
    while read site; do
        echo -n "Blocking site '${site}' "
        generate_zone "${site}" >> "${namedconf}"

        if ! named-checkconf "${namedconf}"; then
            echo -e "[${CRED}FAIL${CRESET}]"
            exit 1
        fi

        echo -e "[${CGREEN}OK${CRESET}]"
        count=$((count + 1))
    done <"${blacklist}"

    echo
    echo "${count} site(s) blacklisted!"
}

if [ $# -eq 1 -a "--help" == "${1:-}" ] || [ $# -ne 2 ]; then
    usage
fi

generate_blacklist "$@"

