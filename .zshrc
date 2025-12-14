# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

export ZSH="$HOME/.oh-my-zsh"

#ZSH_THEME="powerlevel10k/powerlevel10k"

PROMPT='%n@%m [%~] 
%(!.#.$) '

plugins=(
    git
    archlinux
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# Check archlinux plugin commands here
# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/archlinux

# Display Pokemon-colorscripts
# Project page: https://gitlab.com/phoneybadger/pokemon-colorscripts#on-other-distros-and-macos
#pokemon-colorscripts --no-title -s -r #without fastfetch
#pokemon-colorscripts --no-title -s -r | fastfetch -c $HOME/.config/fastfetch/config-pokemon.jsonc --logo-type file-raw --logo-height 10 --logo-width 5 --logo -

# fastfetch. Will be disabled if above colorscript was chosen to install
#fastfetch -c $HOME/.config/fastfetch/config-compact.jsonc

# Set-up icons for files/directories in terminal using lsd
alias ls='lsd'
alias l='ls -la'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
alias ida='/home/kintarou/tools/ida-pro-9.0/ida &'
alias pwninit
# Set-up FZF key bindings (CTRL R for fuzzy history finder)
source <(fzf --zsh)

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
typeset -g POWERLEVEL9K_DIR_SHOW_WRITABLE=true
typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=false
typeset -g POWERLEVEL9K_DIR_FOREGROUND=4
typeset -g POWERLEVEL9K_DIR_UNDERLINE=false  
alias mt='unimatrix -n -c blue -s 96'
alias cl='tty-clock -c -C 4 -b'
export PATH="$PATH:/home/kintarou/.local/bin"
#export PATH="$HOME/tools/node-v14.15.4-linux-x64/bin:$PATH"
if [ -f "$HOME/.config/lf/icons" ]; then
    export LF_ICONS=$(sed -e 's/  */=/g' -e 's/$/:/g' "$HOME/.config/lf/icons" | tr -d '\n')
fi
#export LS_COLORS="$(vivid generate catppuccin-mocha)"
export LS_COLORS="$(vivid generate catppuccin-macchiato | sed 's/=\(0\)\?4;/=00;/g')"

pwninit() {
    if [ -z "$1" ]; then
        command pwninit
    else
        command pwninit --bin "$1" --libc libc.so.6
    fi
}

lf() {
    alacritty msg config window.padding.x=5 window.padding.y=5 &!
    local tmp="$(mktemp)"
    command lf -last-dir-path="$tmp" "$@"
    alacritty msg config window.padding.x=20 window.padding.y=20 &!
    if [ -f "$tmp" ]; then
        local dir="$(cat "$tmp")"
        rm -f "$tmp"
        if [ -d "$dir" ]; then
            if [ "$dir" != "$(pwd)" ]; then
                cd "$dir"
            fi
        fi
    fi
}

alias wstart='sudo systemctl start waydroid-container && waydroid show-full-ui'
alias wstop='waydroid session stop && sudo systemctl stop waydroid-container'

ZSH_HIGHLIGHT_STYLES[path]='fg=#89CFF0'
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=#89CFF0'
