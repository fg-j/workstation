#!/bin/bash -exu

readonly PROGDIR="$(cd "$(dirname "${0}")" && pwd)"
readonly WORKSPACE="${HOME}/workspace"
readonly GOPATH="${HOME}/go"

function main() {
	ln -sf "${PROGDIR}/.bash_profile" "${HOME}/.bash_profile"
	ln -sf "${PROGDIR}/.gitconfig" "${HOME}/.gitconfig"
	ln -sf "${PROGDIR}/.inputrc" "${HOME}/.inputrc"
	mkdir -pv "${WORKSPACE}"

	if [[ ! -d "${HOME}/.config/colorschemes" ]]; then
		git clone https://github.com/chriskempson/base16-shell.git "${HOME}/.config/colorschemes"
	fi

	install::packages
	install::go
	install::docker
	install::neovim

	go get -u github.com/ryanmoran/faux
	go get -u github.com/onsi/ginkgo/ginkgo
	go get -u github.com/onsi/gomega

	echo "Success!"
}

function install::neovim() {
	wget --quiet https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage --output-document nvim
	chmod +x nvim
	chown root:root nvim
	mv nvim /usr/bin

	pip3 install --upgrade pip
	pip3 install --user neovim
	chown -R $USER:$USER /home/ubuntu/.local

	curl -fLo "${HOME}/.local/share/nvim/site/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	mkdir -p "${HOME}/.config/nvim"
	ln -sf "${PROGDIR}/init.vim" "${HOME}/.config/nvim/init.vim"
	nvim -c "PlugInstall" -c "PlugUpdate" -c "qall" --headless
	nvim -c "GoInstallBinaries" -c "GoUpdateBinaries" -c "qall!" --headless
}

function install::go() {
	curl -L -o /tmp/golang.tgz "https://dl.google.com/go/$(curl https://golang.org/VERSION?m=text).linux-amd64.tar.gz"
	tar -C /usr/local -xzf /tmp/golang.tgz
	export PATH=$PATH:/usr/local/go/bin
	rm -rf /tmp/golang.tgz

}

function install::docker() {
	DEBIAN_FRONTEND=noninteractive apt-get install -y \
		apt-transport-https \
		ca-certificates \
		curl \
		gnupg-agent \
		software-properties-common

	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	apt-key fingerprint 0EBFCD88

	add-apt-repository \
		"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
		$(lsb_release -cs) stable"

	DEBIAN_FRONTEND=noninteractive apt-get -y update
	DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io
}

function install::packages() {
	DEBIAN_FRONTEND=noninteractive apt-get -y update
	DEBIAN_FRONTEND=noninteractive apt-get -y upgrade

	DEBIAN_FRONTEND=noninteractive apt-get install -y bash-completion
	DEBIAN_FRONTEND=noninteractive apt-get install -y jq
	DEBIAN_FRONTEND=noninteractive apt-get install -y neovim
	DEBIAN_FRONTEND=noninteractive apt-get install -y gcc

	curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
	DEBIAN_FRONTEND=noninteractive sudo apt-get install -y nodejs

	DEBIAN_FRONTEND=noninteractive apt-get install -y shellcheck
	DEBIAN_FRONTEND=noninteractive apt-get install -y silversearcher-ag
	DEBIAN_FRONTEND=noninteractive apt-get install -y python3-pip
}

main
