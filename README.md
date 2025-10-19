````markdown
# ⚙️ TerminalConfig: My Complete WSL + VS Code Developer Setup

**Author:** [Eric (“nandocodes”)](https://github.com/HeyNaNd0)  
**Repo:** [HeyNaNd0/TerminalConfig](https://github.com/HeyNaNd0/terminal-setup)

---

## 🧩 Overview

When I switched to **Ubuntu on WSL 2** for development, I wanted a **fast, beautiful, and reliable terminal** that played nicely with **VS Code** and **GitHub**.

What started as “install Oh My Posh” turned into a deep cleanup of shell configs, fonts, Git remotes, and VS Code behavior.  
This document records everything I did, the problems I faced, how I solved them, and why each fix works.

---

## 🎯 Goals

- Modern, themed shell with daily-rotating Oh My Posh prompt  
- Clean Fish configuration without syntax errors  
- Automatic SSH agent (no more passphrase prompts)  
- Fast Git operations using WSL-native `/usr/bin/git`  
- VS Code terminal defaulting to Ubuntu 24.04  
- Isolated repos (no more OneDrive interference)

---

## 🚧 Problems Faced

| Problem | Symptom | Root Cause |
|----------|----------|------------|
| Missing icons | Squares or blank glyphs | Nerd font not installed |
| Syntax errors | `case` or `$()` errors in Fish | Bash syntax in Fish config |
| Passphrase prompts | Every `git push` asked for password | SSH agent not persisting |
| Slow Git | 20-30 s pushes | Working from OneDrive Windows path |
| VS Code using PowerShell | Wrong terminal profile | Default profile not set to WSL |
| “Embedded repo” warning | Git confusion | Extra `.git` folder in parent dir |

---

## 🪄 Step 1 – Install Oh My Posh and Themes

```bash
sudo wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 \
  -O /usr/local/bin/oh-my-posh
sudo chmod +x /usr/local/bin/oh-my-posh

mkdir -p ~/.poshthemes
wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip \
  -O ~/.poshthemes/themes.zip
unzip ~/.poshthemes/themes.zip -d ~/.poshthemes
chmod u+rw ~/.poshthemes/*.json
rm ~/.poshthemes/themes.zip
````

**Why it works:** installs the latest Oh My Posh binary and extracts all official themes locally.

---

## 💅 Step 2 – Fix Missing Icons (Meslo LGS NF)

```bash
oh-my-posh font install meslo
```

Then in **Windows Terminal → Settings → Profiles → Ubuntu → Appearance**, enable
**Use custom font → Meslo LGS NF**.

**Why it works:** Oh My Posh depends on *Nerd Fonts* for icons; Meslo LGS NF is the recommended default.

---

## 🐟 Step 3 – Switch to Fish Shell with Random Daily Theme

`~/.config/fish/config.fish`:

```fish
if status is-interactive
    set THEMES_DIR "$HOME/.poshthemes"
    set CACHE_FILE "$THEMES_DIR/.today_theme"
    mkdir -p $THEMES_DIR
    set TODAY (date +%Y-%m-%d)

    if not test -f $CACHE_FILE
        set THEME (find $THEMES_DIR -type f -name "*.omp.json" | shuf -n 1)
        echo $TODAY > $CACHE_FILE; echo $THEME >> $CACHE_FILE
    else if test (head -n 1 $CACHE_FILE) != $TODAY
        set THEME (find $THEMES_DIR -type f -name "*.omp.json" | shuf -n 1)
        echo $TODAY > $CACHE_FILE; echo $THEME >> $CACHE_FILE
    else
        set THEME (tail -n 1 $CACHE_FILE)
    end

    if test -f $THEME
        set -x POSH_PATH_STYLE agnoster_short
        set -x POSH_SIMPLE_ICONS true
        oh-my-posh init fish --config $THEME | source
    end
end
```

**Why it works:** Fish uses `(command)` instead of `$()`.
The cache file ensures one random theme per day instead of per tab.

---

## 🔐 Step 4 – Persistent SSH Agent

```fish
if not set -q SSH_AUTH_SOCK
    eval (ssh-agent -c) > /dev/null
    if test -f ~/.ssh/id_ed25519
        ssh-add ~/.ssh/id_ed25519 >/dev/null 2>&1
    end
end
```

**Why it works:** starts an SSH agent for the session and pre-loads your key, avoiding repeated passphrase prompts.

---

## 🧠 Step 5 – VS Code + WSL Integration

Edit **User Settings (JSON)** → *Preferences → Open Settings (JSON)*

```json
{
  "terminal.integrated.defaultProfile.windows": "Ubuntu-24.04",
  "terminal.integrated.profiles.windows": {
    "Ubuntu-24.04": {
      "path": "C:\\Windows\\System32\\wsl.exe",
      "args": ["-d", "Ubuntu-24.04"],
      "icon": "terminal-ubuntu",
      "color": "terminal.ansiGreen"
    }
  },
  "terminal.integrated.cwd": "\\\\wsl$\\Ubuntu-24.04\\home\\nandocodes\\src\\myRepos",

  "git.path": "\\\\wsl$\\Ubuntu-24.04\\usr\\bin\\git",
  "git.autoRepositoryDetection": "openEditors",
  "git.scanRepositories": [
    "\\\\wsl$\\Ubuntu-24.04\\home\\nandocodes\\src\\myRepos"
  ]
}
```

**Why it works:** forces VS Code to use the WSL Ubuntu 24.04 shell and Git executable, and to start in the Linux repos directory.

---

## 🧹 Step 6 – Clean Up OneDrive Git Conflicts

Remove stray `.git` from the Windows root folder:

```bash
rm -rf "/mnt/c/Users/justE/OneDrive/Desktop/myRepos/.git"
```

**Why it works:**
That accidental `.git` caused every nested repo to be treated as a submodule and slowed down all Git commands.
Working under `~/src/myRepos` ensures isolation and avoids OneDrive file-locking delays.

---

## ✅ Step 7 – Verify Everything

```bash
pwd         # /home/nandocodes/src/myRepos
which git   # /usr/bin/git
git status  # works instantly
```

When both match, your setup is clean and WSL-native.

---

## 🪶 Bonus Tips

### LazyGit UI

```bash
sudo apt install lazygit
lazygit
```

### Pretty Diffs

```bash
git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
```

### Ignore Virtual Envs

```bash
echo ".venv/" >> .gitignore
git rm -r --cached .venv 2>/dev/null || true
```

---

## ⚡ Results

| Before                 | After                      |
| ---------------------- | -------------------------- |
| 25 s `git push`        | 2–3 s push                 |
| PowerShell default     | Ubuntu 24.04 (WSL) default |
| Missing icons          | Full Nerd Font icons       |
| Passphrase every push  | SSH agent auto-loaded      |
| Embedded repo warnings | Clean isolated repos       |

---

## 🧭 Why It Works

1. **WSL 2** provides a true Linux kernel.
2. **Fish + Oh My Posh** offer a modern, modular shell.
3. **VS Code Remote WSL** bridges Windows UI with Linux tools.
4. **WSL Git** eliminates Windows path and line-ending issues.
5. Removing OneDrive `.git` stopped recursive repo scans.

---

## 🧰 Repository Purpose

This repo stores my:

* Fish configuration (`config.fish`)
* Oh My Posh setup and fonts
* VS Code settings.json snippets
* Scripts for automating setup on a new system

Clone it, tweak it, and make your own terminal shine.

```bash
git clone git@github.com:HeyNaNd0/terminal-setup.git
cd terminal-setup
```

---

## 🪄 License

MIT License © Eric (“nandocodes”) 2025

---

## 🏁 Final Thoughts

If you develop on Windows 11 with WSL 2, take an hour to follow these steps.
You’ll end up with a **fast, beautiful, Linux-native workflow** that just works.

Next time you open VS Code and see a new Oh My Posh theme, smile — your terminal’s as polished as your code.

````

---

### ✅ Instructions to add this to your repo

From your WSL terminal:

```bash
cd ~/src/myRepos/TerminalConfig
nano README.md
# (paste the entire content above)
git add README.md
git commit -m "add detailed WSL + VSCode setup guide"
git push origin main
````
