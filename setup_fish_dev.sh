bash -c '
set -euo pipefail

# 1) Packages
sudo apt update
sudo apt install -y git curl wget unzip neofetch fastfetch btop fzf ripgrep fd-find exa bat tldr dust tree lazygit git-delta

# 2) Ensure folders
mkdir -p "$HOME/.poshthemes" "$HOME/.config/fish"

# 3) Download OMP themes if none present
if [ -z "$(ls -1 "$HOME"/.poshthemes/*.omp.json 2>/dev/null)" ]; then
  echo "Downloading Oh My Posh themes..."
  wget -q https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip -O "$HOME/.poshthemes/themes.zip"
  unzip -q "$HOME/.poshthemes/themes.zip" -d "$HOME/.poshthemes"
  chmod u+rw "$HOME"/.poshthemes/*.omp.json || true
  rm -f "$HOME/.poshthemes/themes.zip"
fi

# 4) Prepare Fish config file
FISH_CFG="$HOME/.config/fish/config.fish"
if [ ! -f "$FISH_CFG" ]; then
  printf "%s\n" "if status is-interactive" "end" > "$FISH_CFG"
fi

# 5) Remove prior managed block if present
START="# >>> managed by elite_dev_terminal >>>"
END="# <<< managed by elite_dev_terminal <<<"
sed -i "/$START/,/$END/d" "$FISH_CFG"

# 6) Append new managed block
cat >> "$FISH_CFG" <<'"'"'FISHBLOCK'"'"'
# >>> managed by elite_dev_terminal >>>
if status is-interactive
    # Oh My Posh: pick or reuse a daily theme
    set THEMES_DIR "$HOME/.poshthemes"
    set CACHE_FILE "$HOME/.poshthemes/.today_theme"
    mkdir -p $THEMES_DIR
    set TODAY (date +%Y-%m-%d)
    if not test -f $CACHE_FILE
        set THEME (find $THEMES_DIR -type f -name "*.omp.json" | shuf -n 1)
        echo $TODAY > $CACHE_FILE
        echo $THEME >> $CACHE_FILE
    else if test (head -n 1 $CACHE_FILE) != $TODAY
        set THEME (find $THEMES_DIR -type f -name "*.omp.json" | shuf -n 1)
        echo $TODAY > $CACHE_FILE
        echo $THEME >> $CACHE_FILE
    else
        set THEME (tail -n 1 $CACHE_FILE)
    end
    if test -f $THEME
        oh-my-posh init fish --config $THEME | source
    end

    # Prompt tweaks
    set -x POSH_PATH_STYLE agnoster_short
    set -x POSH_SIMPLE_ICONS true

    # Fisher plugin manager
    if not type -q fisher
        curl -sL https://git.io/fisher | source
        fisher install jorgebucaran/fisher
    end

    # Plugins
    if not functions -q z
        fisher install jethrokuan/z
    end
    if not functions -q _fish_autosuggest_bindings
        fisher install PatrickF1/fish_autosuggestions
    end
    if not type -q fzf_configure_bindings
        fisher install PatrickF1/fzf.fish
    end
    if not set -q __done_min_cmd_duration
        fisher install franciscolourenco/done
        set -U __done_min_cmd_duration 5000
        set -U __done_notification_position top-right
    end

    # Fish functions and abbr
    function ll --wraps="exa -lah --color=auto" --description "List long, human, all"
        exa -lah --color=auto $argv
    end
    function pserv --description "Start simple HTTP server on :8000"
        python3 -m http.server $argv
    end
    abbr -a gs "git status"
    abbr -a gc "git commit -m "
    abbr -a gp "git push"
    abbr -a gl "git log --oneline --graph --decorate --all"
    abbr -a update "sudo apt update && sudo apt upgrade -y"
    abbr -a cat "bat"
    abbr -a ls "exa"
    abbr -a du "dust"
    abbr -a man "tldr"
    abbr -a lt "tree -L 2"

    # Git pretty pager
    if test (git config --global --get core.pager) = ""
        git config --global core.pager "delta"
        git config --global interactive.diffFilter "delta --color-only"
    end

    # Project shortcut example
    if not set -q DEV
        set -U DEV "$HOME/OneDrive/Desktop/myRepos"
    end
    abbr -a cddev "cd \$DEV"

    # Startup info
    if type -q fastfetch
        fastfetch
    else if type -q neofetch
        neofetch
    end
end
# <<< managed by elite_dev_terminal <<<
FISHBLOCK

# 7) Make Fish the default shell if available
if command -v fish >/dev/null 2>&1; then
  CURR_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
  case "$CURR_SHELL" in
    */fish) : ;;
    *) if [ -x /usr/bin/fish ]; then chsh -s /usr/bin/fish "$USER" || true; elif [ -x /bin/fish ]; then chsh -s /bin/fish "$USER" || true; fi ;;
  esac
fi

echo
echo "Done. Open a new Ubuntu tab or run: source ~/.config/fish/config.fish"
'
