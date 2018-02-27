#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

readonly OWNER="root"
readonly GROUP="bind"
readonly MODE="0644"
readonly NAMEDCONF="named.conf"

function usage() {
    cat >&2 <<EOHELP
Usage:  $0 CONFDIR NAMEDCONF ZONEFILE
Deploy named blacklist conf and zone files.
EOHELP
    exit 1
}

function fixpermissions() {
    local filename="$1"; shift
    chown ${OWNER}:${GROUP} "${filename}"
    chmod ${MODE} "${filename}"
}

function deploy_namedconf() {
    local confdir="$1"; shift
    local namedconf="$1"; shift
    local dest="${confdir}/$( basename "${namedconf}" )"

    if [ ! -f "${namedconf}" ]; then
        >&2 echo "Source named conf file '${namedconf}' does not exists!"
        return 1
    fi

    if [ -f "${dest}" ]; then
        >&2 echo "Destination named conf file '${dest}' already exists!"
        return 1
    fi

    cp "${namedconf}" "${dest}"
    fixpermissions "${dest}"
}

function deploy_zonefile() {
    local confdir="$1"; shift
    local zonefile="$1"; shift
    local dest="${confdir}/$( basename "${zonefile}" )"

    if [ ! -f "${zonefile}" ]; then
        >&2 echo "Source named zone file '${zonefile}' does not exists!"
        return 1
    fi

    if [ -f "${dest}" ]; then
        >&2 echo "Destination named zone file '${dest}' already exists!"
        return 1
    fi

    cp "${zonefile}" "${dest}"
    fixpermissions "${dest}"
}

function check_named_include() {
    local confdir="$1"; shift
    local namedconf="$1"; shift

    if ! grep -q "include \".*$( basename "${namedconf}" )\";" "${confdir}/${NAMEDCONF}"; then
        >&2 echo "Named blacklist conf file is not included in named.conf!"
        >&2 echo "include \"${confdir}/$( basename "${namedconf}" )\";"
        return 1
    fi
}

function deploy() {
    local confdir="$1"; shift
    local namedconf="$1"; shift
    local zonefile="$1"; shift

    deploy_namedconf "${confdir}" "${namedconf}"
    deploy_zonefile "${confdir}" "${zonefile}"
    check_named_include "${confdir}" "${namedconf}" || true
}

if [ $# -eq 1 -a "--help" == "${1:-}" ] || [ $# -ne 3 ]; then
    usage
fi

deploy "$@"

