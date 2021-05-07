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

    tfstate::download "${vm_name}" "${service_account_json}"
    terraform::update_version "${vm_name}"
    workstation::ssh "${vm_name}"
}

function usage() {
  cat <<-USAGE
ssh.sh [OPTIONS]

OPTIONS
  --help, -h                                                prints the command usage
  --name, -n <name of vm>                                   specify the name of this workstation
  --service-account-json, -s <path/to/service/account/json> path to gcp service account json to authenticate with

USAGE
}

function tfstate::download(){
  local vm_name
  local service_account_json

  vm_name="${1}"
  service_account_json="${2}"

  gcloud auth activate-service-account --key-file="${service_account_json}"
  gsutil cp "gs://cf-buildpacks-workstations/${vm_name}/default.tfstate" "/tmp/${vm_name}.tfstate"
}

function terraform::update_version(){
  local vm_name

  echo "Updating terraform version to match VM creator's version..."
  vm_name="${1}"
  version=$(cat "/tmp/${vm_name}.tfstate" | jq -r .terraform_version)
  tfenv install "${version}"
  tfenv use "${version}"
}

function workstation::ssh() {
  local vm_name
  vm_name="${1}"

  terraform output -state "/tmp/${vm_name}.tfstate" --json | jq -r .ssh_private_key.value > /tmp/key
  chmod 600 /tmp/key

  ssh -i /tmp/key ubuntu@"$(terraform output -state "/tmp/${vm_name}.tfstate" --json | jq -r .vm_ip.value)"
}

main "${@:-}"
