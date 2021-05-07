#!/bin/bash
set -eu

readonly PROGDIR="$(cd "$(dirname "${0}")" && pwd)"
readonly WORKSPACE="${HOME}/workspace"
readonly GOPATH="${HOME}/go"

function main() {
	ln -sf "${PROGDIR}/.bash_profile" "${HOME}/.bash_profile"
	ln -sf "${PROGDIR}/.gitconfig" "${HOME}/.gitconfig"
	ln -sf "${PROGDIR}/.inputrc" "${HOME}/.inputrc"
	ln -sf "${PROGDIR}/.tmux.conf" "${HOME}/.tmux.conf"
	mkdir -pv "${WORKSPACE}"

	if [[ ! -d "${HOME}/.config/colorschemes" ]]; then
		git clone https://github.com/chriskempson/base16-shell.git "${HOME}/.config/colorschemes"
	fi

	install::packages
	install::go
	install::docker
	install::neovim
	install::lpass
  install::git-duet
  install::gcloud
  install::pack
  install::jam
  install::fly
  install::bosh
  install::tfenv
  install::terraform
  install::bbl
  install::credhub
  install::cf

	go get -u github.com/ryanmoran/faux
	go get -u github.com/onsi/ginkgo/ginkgo
	go get -u github.com/onsi/gomega

	chown -R ubuntu:ubuntu "${HOME}"

	echo "Success!"
}

function install::neovim() {
	echo "* Installing neovim"

	wget --quiet https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage --output-document nvim
	chmod +x nvim
	chown root:root nvim
	mv nvim /usr/bin

	pip3 install --upgrade pip
	pip3 install --user neovim
	chown -R $USER:$USER /home/ubuntu/.local

	curl -sfLo "${HOME}/.local/share/nvim/site/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	mkdir -p "${HOME}/.config/nvim"
	ln -sf "${PROGDIR}/init.vim" "${HOME}/.config/nvim/init.vim"
	nvim -c "PlugInstall" -c "PlugUpdate" -c "qall" --headless
	nvim -c "GoInstallBinaries" -c "GoUpdateBinaries" -c "qall!" --headless
}

function install::go() {
	echo "* Installing go"

	curl -sL -o /tmp/golang.tgz "https://dl.google.com/go/$(curl https://golang.org/VERSION?m=text).linux-amd64.tar.gz"
	tar -C /usr/local -xzf /tmp/golang.tgz
	export PATH=$PATH:/usr/local/go/bin
	rm -rf /tmp/golang.tgz

}

function install::docker() {
	echo "* Installing docker"

	apt-get install -y \
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

	apt-get -y update
	apt-get install -y docker-ce docker-ce-cli containerd.io

	usermod -aG docker ubuntu
}

function install::packages() {
	echo "* Installing some useful programs"

	apt-get -y update
	apt-get -y upgrade

	apt-get install -y bash-completion
	apt-get install -y jq
	apt-get install -y gcc

	curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
	sudo apt-get install -y nodejs

	apt-get install -y shellcheck
	apt-get install -y silversearcher-ag
	apt-get install -y python3-pip
	apt-get install -y tig
  apt-get install -y tree
  apt-get install -y unzip
}

function install::gcloud() {
	echo "* Installing gcloud cli"

  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
  apt-get -y update && apt-get -y install google-cloud-sdk
}

function install::lpass() {
	echo "* Installing the lastpass cli"

	apt-get --no-install-recommends -yqq install \
		build-essential \
		cmake \
		libcurl4  \
		libcurl4-openssl-dev  \
		libssl-dev  \
		libxml2 \
		libxml2-dev  \
		libssl1.1 \
		pkg-config \
		ca-certificates \
		xclip

	curl -sL -o /tmp/lpass.tgz "https://github.com/lastpass/lastpass-cli/releases/download/v1.3.3/lastpass-cli-1.3.3.tar.gz"
	mkdir -p /tmp/lpass
	tar -xvf /tmp/lpass.tgz -C /tmp/lpass
	pushd /tmp/lpass > /dev/null
		make
	popd > /dev/null
	chmod +x /tmp/lpass/build/lpass
	mv /tmp/lpass/build/lpass /usr/local/bin

	rm -rf /tmp/lpass
	rm -rf /tmp/lpass.tgz
}

function install::git-duet() {
	echo "* Installing git-duet"

  curl -sL -o /tmp/git-duet.tgz "https://github.com/git-duet/git-duet/releases/download/0.7.0/linux_amd64.tar.gz"
  tar -xvf /tmp/git-duet.tgz -C /usr/local/bin/
  rm -rf /tmp/git-duet
}

function install::pack() {
  local version
  version="$(
    curl "https://raw.githubusercontent.com/paketo-buildpacks/github-config/main/implementation/scripts/.util/tools.json"\
      --silent \
      --location \
    | jq -r .pack
  )"
  curl -sSL "https://github.com/buildpacks/pack/releases/download/${version}/pack-${version}-linux.tgz" | sudo tar -C /usr/local/bin/ --no-same-owner -xzv pack
}

function install::jam() {
  local version
  version="$(
    curl "https://raw.githubusercontent.com/paketo-buildpacks/github-config/main/implementation/scripts/.util/tools.json"\
      --silent \
      --location \
    | jq -r .jam
  )"
  curl "https://github.com/paketo-buildpacks/packit/releases/download/${version}/jam-linux" \
      --silent \
      --location \
      --output /tmp/jam
    chmod +x /tmp/jam
    sudo mv /tmp/jam /usr/local/bin/jam
}

function install::fly(){
  curl "https://buildpacks.ci.cf-app.com/api/v1/cli?arch=amd64&platform=linux" \
    --silent \
    --location \
    --output /tmp/fly
  chmod +x /tmp/fly
  sudo mv /tmp/fly /usr/local/bin/fly
}

function install::bosh(){
  curl "https://github.com/cloudfoundry/bosh-cli/releases/download/v6.4.3/bosh-cli-6.4.3-linux-amd64" \
    --silent \
    --location \
    --output /tmp/bosh
  chmod +x /tmp/bosh
  sudo mv /tmp/bosh /usr/local/bin/bosh
}

function install::bbl(){
  curl "https://github.com/cloudfoundry/bosh-bootloader/releases/download/v8.4.40/bbl-v8.4.40_linux_x86-64"\
    --silent \
    --location \
    --output /tmp/bbl
  chmod +x /tmp/bbl
  sudo mv /tmp/bbl /usr/local/bin/bbl
}

function install::credhub(){
  curl -sSL "https://github.com/cloudfoundry-incubator/credhub-cli/releases/download/2.9.0/credhub-linux-2.9.0.tgz" | sudo tar -C /usr/local/bin/ --no-same-owner -xzv credhub
}

function install::cf(){
  curl -sSL "https://packages.cloudfoundry.org/stable?release=linux64-binary&source=github&version=v6"| sudo tar -C /usr/local/bin/ --no-same-owner -xzv cf
}

function install::tfenv(){
  git clone https://github.com/tfutils/tfenv.git ~/.tfenv
  sudo ln -s ~/.tfenv/bin/* /usr/local/bin
  tfenv init
}

function install::terraform(){
  tfenv install latest
  tfenv use latest
}

main
