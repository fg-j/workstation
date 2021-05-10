#!/usr/bin/env bash
set -eu
set -o pipefail

readonly PROGDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
vm_ip=""

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
            [ "${2}" != "${2#/}" ] && service_account_json="${2}" || service_account_json="${PWD}/${2}"
            shift 2
            ;;

          *)
            usage
            echo "unknown argument \"${1}\""
            exit 1
        esac
    done

    terraform::update
    workstation::create "${vm_name}" "${gcp_project}" "${service_account_json}"
    workstation::setup
}

function usage() {
  cat <<-USAGE
setup.sh [OPTIONS]

OPTIONS
  --help, -h                                                prints the command usage
  --name, -n <name of vm>                                   specify the name of this workstation
  --gcp-project, -p <gcp-project>                           name of gcp project to place the vm in
  --service-account-json, -s <path/to/service/account/json> path to gcp service account json to authenticate with

USAGE
}

function terraform::update(){
  echo "Upgrading to the latest version of terraform"
  tfenv install latest
  tfenv use latest
}

function workstation::create() {
    local vm_name
    local gcp_project
    local service_account_json

    vm_name="${1}"
    gcp_project="${2}"
    service_account_json="${3}"

    pushd "${PROGDIR}/terraform" > /dev/null
    GOOGLE_APPLICATION_CREDENTIALS="${service_account_json}" terraform init -reconfigure \
            -backend-config="bucket=cf-buildpacks-workstations" \
            -backend-config="prefix=${vm_name}"

        GOOGLE_APPLICATION_CREDENTIALS="${service_account_json}" terraform apply \
            -var "vm_name=${vm_name}" \
            -var "project=${gcp_project}"

        GOOGLE_APPLICATION_CREDENTIALS="${service_account_json}" terraform output --json | jq -r .ssh_private_key.value > /tmp/key
        chmod 600 /tmp/key

        vm_ip="$(GOOGLE_APPLICATION_CREDENTIALS="${service_account_json}" terraform output --json | jq -r .vm_ip.value)"

        ssh-keygen -f "${HOME}/.ssh/known_hosts" -R "${vm_ip}"

        echo "waiting for vm to become available"
        while ! nc -z "${vm_ip}" 22 > /dev/null
        do
            sleep 1
            printf "%c" "."
        done

        sleep 1
    popd > /dev/null
}

function workstation::setup(){
    pushd "${PROGDIR}/terraform" > /dev/null
    ssh -i /tmp/key "ubuntu@${vm_ip}" <<'ENDSSH'
pushd "${HOME}" > /dev/null
    git clone https://github.com/fg-j/workstation
    pushd workstation > /dev/null
      git checkout improve-onboarding
    popd > /dev/null
    pushd workstation/dotfiles
        sudo ./install.sh
    popd > /dev/null
popd > /dev/null
ENDSSH
    popd > /dev/null
}

main "${@:-}"
