#!/usr/bin/env bash
set -eu
set -o pipefail

readonly PROGDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function main() {
    pushd "${PROGDIR}/terraform" > /dev/null
        terraform apply
        terraform output ssh_private_key > /tmp/key
        chmod 600 /tmp/key

        ssh-keygen -f "${HOME}/.ssh/known_hosts" -R "$(terraform output vm_ip)"

        echo "waiting for vm"
        while ! ping -c 1 -n -w 1 "$(terraform output vm_ip)" &> /dev/null
        do
            printf "%c" "."
        done

        ssh -i /tmp/key "ubuntu@$(terraform output vm_ip)" <<'ENDSSH'
pushd "${HOME}" > /dev/null
    git clone https://github.com/joshzarrabi/workstation
    pushd workstation/dotfiles > /dev/null
        sudo ./install.sh
    popd > /dev/null
popd > /dev/null
ENDSSH
    popd
}

main
