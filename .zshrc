autoload -Uz compinit
zmodload zsh/complist
_comp_options+=(globdots)
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

compinit

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS

# PROMPT='%n@%m [%~] 
# %(!.#.$) '

PROMPT='%F{#83bff3}%n%f%F{250}@%f%F{#83bff3}%m%f %F{#83bff3}[%~]%f 
%F{#83bff3}%(!.#.$)%f '

export PATH="$PATH:/home/kintarou/.local/bin"
export LS_COLORS="$(vivid generate catppuccin-macchiato | sed 's/=\(0\)\?4;/=00;/g')"
export LF_FZF_OPTS="--ansi"
if [ -f "$HOME/.config/lf/icons" ]; then
    export LF_ICONS=$(sed -e 's/  */=/g' -e 's/$/:/g' "$HOME/.config/lf/icons" | tr -d '\n')
fi
alias ls='lsd'
alias l='ls -la'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
alias ida='/home/kintarou/tools/ida-pro-9.0/ida &'
alias mt='unimatrix -n -c blue -s 96'
alias cl='tty-clock -c -C 4 -b -D'
alias wstart='sudo systemctl start waydroid-container && waydroid show-full-ui'
alias wstop='waydroid session stop && sudo systemctl stop waydroid-container'
alias passkee='wl-copy < /home/kintarou/Documents/AnyDesk/passkey'
getytmusic() {
    if [ -z "$1" ]; then
        echo "Usage: getytmusic <YouTube Music URL>"
        return 1
    fi
    yt-dlp -f "ba[ext=m4a]" \
    --embed-metadata \
    --embed-thumbnail \
    --parse-metadata "title:%(title)s" \
    --parse-metadata "artist:%(artist)s" \
    --remote-components ejs:github \
    -o "%(title)s.%(ext)s" \
    "$1" \
	&& mpc update
}

getspotifymusic() {
	if [ -z "$1" ]; then
		echo "Usage: getspotifymusic <Spotify URL>"
		return 1
	fi
	spotdl "$1" \
	&& mpc update
}

pwninit() {
    if [ -z "$1" ]; then
        command pwninit
    else
        command pwninit --bin "$1" --libc libc.so.6
    fi
}

# lf() {
#     alacritty msg config window.padding.x=5 window.padding.y=5 &!
#     local tmp="$(mktemp)"
#     command lf -last-dir-path="$tmp" "$@"
#     alacritty msg config window.padding.x=25 window.padding.y=25 &! 
#     if [ -f "$tmp" ]; then
#         local dir="$(cat "$tmp")"
#         rm -f "$tmp"
#         if [ -d "$dir" ]; then
#             if [ "$dir" != "$(pwd)" ]; then
#                 cd "$dir"
#             fi
#         fi
#     fi
# }

# lf() {
#     kitty @ set-spacing padding=3 &!
#     local tmp="$(mktemp)"
#     command lf -last-dir-path="$tmp" "$@"
#     kitty @ set-spacing padding=20 &!
#     if [ -f "$tmp" ]; then
#         local dir="$(cat "$tmp")"
#         rm -f "$tmp"
#         if [ -d "$dir" ] && [ "$dir" != "$(pwd)" ]; then
#             cd "$dir"
# 			clear
#         fi
#     fi
# }

lf() {
    local tmp="$(mktemp)"
    command lf -last-dir-path="$tmp" "$@"
    if [ -f "$tmp" ]; then
        local dir="$(cat "$tmp")"
        rm -f "$tmp"
        if [ -d "$dir" ] && [ "$dir" != "$(pwd)" ]; then
            cd "$dir"
			clear
        fi
    fi
}

function doc2pdf() {
    if [ $# -eq 0 ]; then echo "Input file missing!"; return 1; fi
    for file in "$@"; do
        echo "Converting .doc to .pdf ..."
        soffice --headless --convert-to pdf "$file"
        echo "CONVERTED SUCCESSFULLY: ${file%.*}.pdf"
    done
}

function docx2pdf() {
    if [ $# -eq 0 ]; then echo "Input file missing!"; return 1; fi
    for file in "$@"; do
        echo "Converting .docx to .pdf ..."
        soffice --headless --convert-to pdf "$file"
        echo "CONVERTED SUCCESSFULLY: ${file%.*}.pdf"
    done
}

function pdf2doc() {
    if [ $# -eq 0 ]; then echo "Input file missing!"; return 1; fi
    for file in "$@"; do
        echo "Converting .pdf to .doc ..."
        soffice --headless --infilter="writer_pdf_import" --convert-to doc "$file"
        echo "CONVERTED SUCCESSFULLY: ${file%.*}.doc"
    done
}

function pdf2docx() {
    if [ $# -eq 0 ]; then echo "Input file missing!"; return 1; fi
    for file in "$@"; do
        echo "Converting .pdf to .docx ..."
        soffice --headless --infilter="writer_pdf_import" --convert-to docx "$file"
        echo "CONVERTED SUCCESSFULLY: ${file%.*}.docx"
    done
}

function png2jpg() {
    if [ $# -eq 0 ]; then echo "Input file missing!"; return 1; fi
    for file in "$@"; do
        filename="${file%.*}"
        echo "Converting .png to .jpg ..."
        magick "$file" "$filename.jpg"
        echo "CONVERTED SUCCESSFULLY: $filename.jpg"
    done
}

function jpg2png() {
    if [ $# -eq 0 ]; then echo "Input file missing!"; return 1; fi
    for file in "$@"; do
        filename="${file%.*}"
        echo "Converting .jpg to .png ..."
        magick "$file" "$filename.png"
        echo "CONVERTED SUCCESSFULLY: $filename.png"
    done
}

g++() {
    if [[ "$#" -eq 1 && "${1: -4}" == ".cpp" ]]; then
        command g++ "$1" -o "${1:r}" && ./"${1:r}"
    else
        command g++ "$@"
    fi
}

gcc() {
    if [[ "$#" -eq 1 && "${1: -2}" == ".c" ]]; then
        command gcc "$1" -o "${1:r}" && ./"${1:r}"
    else
        command gcc "$@"
    fi
}

cve_search() {
    local SCRIPT_PATH="$HOME/dung_hoc/current_ctf/cve_collector.py"
    if [ ! -f "$SCRIPT_PATH" ]; then
        echo -e "${RED}[ERROR]${RESET} File python ${YELLOW}$SCRIPT_PATH${RESET} đéo tồn tại. Check lại đi tml."
        return 1
    fi
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo -e "${RED}[ERROR]${RESET} Gõ thiếu rồi. Usage: ${CYAN}cve_search <vendor> <product>${RESET}"
        return 1
    fi
    echo -e "${GREEN}[*]${RESET} Đi săn CVE cho ${BOLD}$1 $2${RESET}..."
    python3 "$SCRIPT_PATH" "$1" "$2"
}

cve_view() {
    if [ -z "$1" ]; then
        echo -e "\033[1;31m[NGU] Thiếu ID. Usage: cve_view <CVE-ID>\033[0m"
        return 1
    fi
    echo -e "\033[1;32m[*] Mở hồ sơ con hàng $1 trên NVD...\033[0m"
    xdg-open "https://nvd.nist.gov/vuln/detail/$1" > /dev/null 2>&1
}

poc_view() {
    if [ -z "$1" ]; then
        echo -e "\033[1;31m[NGU] Muốn tìm exploit con nào? Usage: poc_view <CVE-ID>\033[0m"
        return 1
    fi
    echo -e "\033[1;32m[*] Đang lùng sục PoC/Exploit cho $1...\033[0m"
    xdg-open "http://localhost:8080/search?q=\"$1\"+(PoC+OR+exploit)+site:github.com+OR+site:exploit-db.com" > /dev/null 2>&1
}

wu() {
    if [ -z "$1" ]; then
        echo "Error: No writeup name provided."
        return 1
    fi
    BLOG_DIR="$HOME/dung_hoc/dung_hoang_blog/my-blog"
    cd "$BLOG_DIR" || return
    hugo new content --kind writeups "writeups/$1.md"
    nvim "content/writeups/$1.md"
}

source <(fzf --zsh)
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
ZSH_HIGHLIGHT_STYLES[path]='fg=white'
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=white'
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search
export WLR_DRM_DEVICES=/dev/dri/card1:/dev/dri/card2
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export LIBVA_DRIVER_NAME=nvidia
export NVD_BACKEND=direct
export MOZ_DISABLE_RDD_SANDBOX=1
export BROWSER=librewolf
/home/kintarou/.config/rmpc/wrapped-reminder.sh

# bun completions
[ -s "/home/kintarou/.bun/_bun" ] && source "/home/kintarou/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
