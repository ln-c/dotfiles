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

__run_fastfetch_once() {
    PROMPT_COMMAND="${PROMPT_COMMAND/__run_fastfetch_once;/}"
    unset -f __run_fastfetch_once

    local rows cols
    for _ in {1..20}; do
        read -r rows cols < <(stty size 2>/dev/null)
        [[ "$cols" -ne 80 || "$rows" -ne 24 ]] && break
        sleep 0.01
    done
    fastfetch
}
PROMPT_COMMAND="__run_fastfetch_once; ${PROMPT_COMMAND:-}"


# Added by Antigravity CLI installer
export PATH="/home/ln/.local/bin:$PATH"

export PATH="$HOME/.local/bin:$PATH"
. "$HOME/.cargo/env"

# SSH passphrases (git commit signing included) ask in a desktop window
export SSH_ASKPASS="$HOME/.local/bin/ln-askpass"
export SSH_ASKPASS_REQUIRE=prefer
