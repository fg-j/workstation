#!/usr/bin/env bash
set -eu
set -o pipefail

readonly PROGDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function main() {
    local vm_name
    local service_account_json

    while [[ "${#}" != 0 ]]; do
        case "${1}" in
          --help|-h)
            usage
            exit 0
            ;;

          --service-account-json|-s)
            service_account_json="${2}"
            shift 2
            ;;

          *)
            usage
            echo "unknown argument \"${1}\""
            exit 1
        esac
    done

    workstation::list "${service_account_json}"
}

function usage() {
  cat <<-USAGE
list.sh [OPTIONS]

OPTIONS
  --help, -h                                                prints the command usage
  --service-account-json, -s <path/to/service/account/json> path to gcp service account json to authenticate with

USAGE
}

function workstation::list(){
  local service_account_json

  service_account_json="${1}"

  gcloud auth activate-service-account --key-file="${service_account_json}"

  printf "You can ssh onto the following vms:\n"
  gsutil ls "gs://cf-buildpacks-workstations/" | xargs -I{} echo {} | cut -d'/' -f4
}

main "${@:-}"
