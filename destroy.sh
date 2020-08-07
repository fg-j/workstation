#!/usr/bin/env bash
set -eu
set -o pipefail

readonly PROGDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function main(){
    pushd "${PROGDIR}/terraform" > /dev/null
        GOOGLE_APPLICATION_CREDENTIALS=/tmp/bbl-key.json terraform destroy
    popd > /dev/null
}

main

