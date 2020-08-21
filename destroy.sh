#!/usr/bin/env bash
set -eu
set -o pipefail

readonly PROGDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function main() {
    local vm_name
    local gcp_project
    local service_account_json

    while [[ "${#}" != 0 ]]; do
        case "${1}" in
          --help|-h)
            usage
            exit 0
            ;;

          --name|-n)
            vm_name="${2}"
            shift 2
            ;;

          --gcp-project|-p)
            gcp_project="${2}"
            shift 2
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

    workstation::delete "${vm_name}" "${service_account_json}"
    tfstate::delete "${vm_name}" "${service_account_json}"
}

function usage() {
  cat <<-USAGE
delete.sh [OPTIONS]

OPTIONS
  --help, -h                                                prints the command usage
  --name, -n <name of vm>                                   specify the name of this workstation
  --gcp-project, -p <gcp-project>                           name of gcp project to place the vm in
  --service-account-json, -s <path/to/service/account/json> path to gcp service account json to authenticate with

USAGE
}

function workstation::delete() {
  local vm_name
  local gcp_project
  local service_account_json

  vm_name="${1}"
  gcp_project="${2}"
  service_account_json="${2}"

  pushd "${PROGDIR}/terraform" > /dev/null
      GOOGLE_APPLICATION_CREDENTIALS="${service_account_json}" terraform init \
          -backend-config="bucket=cf-buildpacks-workstations" \
          -backend-config="prefix=${vm_name}"

      GOOGLE_APPLICATION_CREDENTIALS="${service_account_json}" terraform destroy \
          -var "vm_name=${vm_name}" \
          -var "project=${gcp_project}"

  popd > /dev/null
}

function tfstate::delete() {
  local vm_name
  local service_account_json

  vm_name="${1}"
  service_account_json="${2}"

  gcloud auth activate-service-account --key-file="${service_account_json}"
  gsutil rm -rf "gs://cf-buildpacks-workstations/${vm_name}"
}

main "${@:-}"
