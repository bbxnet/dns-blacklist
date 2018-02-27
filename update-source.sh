#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

readonly SOURCE="https://www.financnasprava.sk/sk/infoservis/priklady-hazardne-hry"
readonly WORKDIR="$( mktemp -d -t dnsbl.XXXXXXXX )"

function usage() {
    cat >&2 <<EOHELP
Usage:  $0 BLACKLIST
Update blacklist file from remote source.
${SOURCE}
EOHELP
    exit 1
}

function cleanup() {
    if [ -n "${WORKDIR}" ] && [ -d "${WORKDIR}" ]; then
        rm -r "${WORKDIR}"
    fi
}
trap cleanup EXIT

function download_source() {
    local src="$1"; shift

    if ! wget -q "${src}" -O "${WORKDIR}/source.html"; then
        >&2 echo 'Source download failed!'
        return 1
    fi

    local realsrc; realsrc="https://www.financnasprava.sk/$( grep 'Zoznam zak' "${WORKDIR}/source.html" | sed -n 's/.*href="\([^"]*\).*/\1/p' )"

    if ! wget -q "${realsrc}" -O "${WORKDIR}/source.pdf"; then
        >&2 echo 'Source pdf download failed!'
        return 1
    fi

    echo "${WORKDIR}/source.pdf"
}

function extract_list() {
    local src="$1"; shift

    if ! pdftotext -bbox "${src}" "${WORKDIR}/transformed.html"; then
        >&2 echo 'Source pdf to text transformation failed!'
        return 1
    fi

    grep 'xMin=\"226.1' "${WORKDIR}/transformed.html" | sed -n -r 's!.+>(https?://)?(.+)<.+!\2!p'
}

function update_source() {
    local blacklist="$1"; shift

    if [ -f "${blacklist}" ]; then
        >&2 echo "Blacklist '${blacklist}' already exists!"
        return 1
    fi

    local src; src="$( download_source "${SOURCE}" )"
    extract_list "${src}" > "${blacklist}"

    echo "$( cat "${blacklist}" | wc -l ) site(s) extracted!"
}

if [ $# -eq 1 -a "--help" == "${1:-}" ] || [ $# -ne 1 ]; then
    usage
fi

update_source "$@"

