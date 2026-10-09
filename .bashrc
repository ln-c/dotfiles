#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# Activate starship
eval "$(starship init bash)"

fastfetch


# Added by Antigravity CLI installer
export PATH="/home/ln/.local/bin:$PATH"
