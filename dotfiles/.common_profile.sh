parse_git_branch() {
	git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

kubernetes_context() {
	kubectl config current-context 2> /dev/null
}

cps () { echo "export `env | grep SSH_AUTH_SOCK | head -n1`" > /tmp/so; }
pts () { source /tmp/so; }

# Locale
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# For colors during ls, git etc.
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

alias ls='ls --color'
# Love gnu coreutils and hate bsd bins but whatever
if ! ls --color > /dev/null 2>&1; then
	alias ls='ls -G'
fi
alias grep='grep --color'
alias k=kubectl
alias nbrew='HOMEBREW_NO_AUTO_UPDATE=1 brew'

# History stuff
export HISTSIZE=9999 HISTFILESIZE=$HISTSIZE
# Don't store lines starting with space
export HISTCONTROL=ignorespace

. ~/z.sh

PS1="$blue$presentwd \$(parse_git_branch )$nocolor$newline$ "
if [ `uname` = Darwin ]; then
	[ `whoami` = 'pivotal' ] && unset currentuser
	# PS1="[\$(currshell )$currentuser $basename$green\$(parse_git_branch ) $blue\$(kubernetes_context )$nocolor]$ "
	PS1="\$(currshell )$currentuser@$hostname $presentwd$green\$(parse_git_branch )$nocolor$newline$ "
  [ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion
else
	source ~/.git-completion.bash
fi

export GIT_PS1_SHOWDIRTYSTATE=true
[ ! -f $HOME/.fzf/bin/fzf ] && [ -f $HOME/.fzf/install ] && \
echo installing fzf.. && $HOME/.fzf/install
