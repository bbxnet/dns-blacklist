#!/bin/bash 

set -o errexit
set -o nounset
set -o pipefail
shopt -s compat42

readonly CBLUE='\033[0;34m'
readonly CGREEN='\033[0;32m'
readonly CRED='\033[0;31m'
readonly CRESET='\033[0m'

readonly SOURCE="https://www.financnasprava.sk/sk/elektronicke-sluzby/verejne-sluzby/zoznamy/prikazy-sudu-k-zakazanym-ponuk"
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

function get_source_list() {
    local src="$1"; shift

    if ! wget -q "${src}" -O "${WORKDIR}/source.html"; then
        >&2 echo 'Source download failed!'
        return 1
    fi

    grep 'Príkaz súdu 6Ntn' "${WORKDIR}/source.html" \
        | sed -n 's/.*href="\([^"]*\).*/\1/p'
}

function download_source() {
    local src="$1"; shift
    local dest="$( mktemp -p "${WORKDIR}" source.XXXXXXXX )"
    
    if ! wget -q "${src}" -O "${dest}"; then
        >&2 echo 'Source pdf download failed!'
        return 1
    fi

    echo "${dest}"
}

function extract_website() {
    local src="$1"; shift

    if ! pdftotext -f 1 -l 1 "${src}" "${WORKDIR}/transformed"; then
        >&2 echo 'Source pdf to text transformation failed!'
        return 1
    fi
    
    if ! grep -q 'Vydanie príkazu na zamedzenie prístupu k webovému sídlu' "${WORKDIR}/transformed"; then
        return 64
    fi

    cat "${WORKDIR}/transformed" \
        | tr '\n' ' ' \
        | sed -n -r 's!.*pod doménou (.+) z územia ([Ss]lovenskej republiky|[Ss][Rr]) vrátane všetkých príslušných domén nižšej úrovne.*!\1!p'
}

function update_source() {
    local blacklist="$1"; shift

    if [ -f "${blacklist}" ]; then
        >&2 echo "Blacklist '${blacklist}' already exists!"
        return 1
    fi

    local domain_list=()
    local court_order source_file extracted
    while read court_order; do
        echo -n "$( basename "${court_order}" ) "
    
        source_file="$( download_source "https://www.financnasprava.sk/${court_order}" )"
        
        set +o errexit
        extracted="$( extract_website "${source_file}" )"; ret=$?
        set -o errexit
        if [ ${ret} -eq 64 ]; then
            echo -e "[${CBLUE}SKIP${CRESET}]"
            continue
        elif [ ${ret} -gt 0 ]; then
            exit ${ret}
        fi
        
        if [ -n "${extracted}" ]; then
            domain_list+=("${extracted}")
            echo -e "[${CGREEN}OK${CRESET}]"
        else
            echo -e "[${CRED}FAIL${CRESET}]"
        fi
    done <<<"$( get_source_list "${SOURCE}" )"

    printf "%s\n" "${domain_list[@]}" > "${blacklist}"

    echo "$( cat "${blacklist}" | wc -l ) site(s) extracted!"
}

if [ $# -eq 1 -a "--help" == "${1:-}" ] || [ $# -ne 1 ]; then
    usage
fi

update_source "$@"

