#!/usr/bin/env zsh
# md2pdf installer — copies assets to ~/.config/md2pdf and wires the shell
# function into your shell startup file.
#
# Copyright (C) 2026 Grant DeFayette - CavebatSoftware LLC
# Licensed under the GNU General Public License v3 or later.
#
# Usage: ./install.zsh                    # install for the current shell
#        ./install.zsh --author "Name"    # set the default PDF author
#        ./install.zsh --uninstall
#
# The default author is also taken from $MD2PDF_AUTHOR, then `git config
# user.name`, then $USER. A markdown file's own frontmatter always wins.
set -eu

# Resolve the directory this script lives in (the source checkout).
SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/md2pdf"
MARKER="# >>> md2pdf >>>"
MARKER_END="# <<< md2pdf <<<"

say()  { printf '%s\n' "$*"; }
warn() { printf '\033[33m%s\033[0m\n' "$*" >&2; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# --- Pick the shell startup file to modify --------------------------------
# md2pdf.zsh is written in zsh syntax; zsh is the supported shell. We still
# offer to wire bash in case the user runs zsh interactively from bash.
detect_rc() {
    shell=$(basename -- "${SHELL:-}")
    case "$shell" in
        zsh)  printf '%s\n' "${ZDOTDIR:-$HOME}/.zshrc" ;;
        bash) printf '%s\n' "$HOME/.bashrc" ;;
        *)    printf '%s\n' "${ZDOTDIR:-$HOME}/.zshrc" ;;
    esac
}

uninstall() {
    rc=$(detect_rc)
    if [ -f "$rc" ] && grep -qF "$MARKER" "$rc"; then
        tmp=$(mktemp)
        sed "/^${MARKER}$/,/^${MARKER_END}$/d" "$rc" > "$tmp" && mv "$tmp" "$rc"
        say "removed md2pdf block from $rc"
    fi
    if [ -d "$CONFIG" ]; then
        rm -rf "$CONFIG"
        say "removed $CONFIG"
    fi
    say "md2pdf uninstalled. Restart your shell."
    exit 0
}

# --- Parse arguments ------------------------------------------------------
AUTHOR="${MD2PDF_AUTHOR:-}"
AUTHOR_EXPLICIT=""
[ -n "$AUTHOR" ] && AUTHOR_EXPLICIT=1
while [ $# -gt 0 ]; do
    case "$1" in
        --uninstall)  uninstall ;;
        --author)     [ $# -ge 2 ] || die "--author needs a value"
                      AUTHOR="$2"; AUTHOR_EXPLICIT=1; shift 2 ;;
        --author=*)   AUTHOR="${1#--author=}"; AUTHOR_EXPLICIT=1; shift ;;
        *)            die "unknown option: $1" ;;
    esac
done

# Fall back to git identity, then the login name, when no author was given.
if [ -z "$AUTHOR" ]; then
    AUTHOR=$(git config user.name 2>/dev/null || true)
    [ -z "$AUTHOR" ] && AUTHOR="${USER:-}"
fi

# --- Dependency check (warn, don't fail) ----------------------------------
for dep in pandoc weasyprint; do
    command -v "$dep" >/dev/null 2>&1 || \
        warn "missing dependency: '$dep' is not on your PATH — md2pdf needs it to run."
done

# --- Copy assets into ~/.config/md2pdf ------------------------------------
say "installing assets to $CONFIG"
mkdir -p "$CONFIG"
cp -- "$SRC/base.css" "$CONFIG/base.css"
cp -- "$SRC/highlight.css" "$CONFIG/highlight.css"
cp -- "$SRC/template.html" "$CONFIG/template.html"
cp -- "$SRC/md2pdf.zsh" "$CONFIG/md2pdf.zsh"
rm -rf "$CONFIG/themes" "$CONFIG/fonts"
cp -R -- "$SRC/themes" "$CONFIG/themes"
cp -R -- "$SRC/fonts"  "$CONFIG/fonts"

# --- Write default document metadata --------------------------------------
# metadata.yaml supplies the default PDF author; a markdown file's own
# frontmatter (author:/title:/date:) overrides it via --metadata-file at
# render time. On reinstall, keep a customized file unless --author was given.
metafile="$CONFIG/metadata.yaml"
if [ -f "$metafile" ] && [ -z "$AUTHOR_EXPLICIT" ]; then
    say "keeping existing $metafile"
elif [ -n "$AUTHOR" ]; then
    esc=$(printf '%s' "$AUTHOR" | sed 's/\\/\\\\/g; s/"/\\"/g')
    printf 'author: "%s"\n' "$esc" > "$metafile"
    say "set default PDF author to \"$AUTHOR\""
else
    warn "no author found (set one later with --author or edit $metafile)"
fi

# --- Wire the function into the shell startup file ------------------------
rc=$(detect_rc)
[ "$(basename -- "${SHELL:-}")" = "bash" ] && \
    warn "note: md2pdf.zsh uses zsh syntax and will only work under zsh."

touch "$rc"
if grep -qF "$MARKER" "$rc"; then
    say "shell startup already wired in $rc — leaving it as-is"
else
    {
        printf '%s\n' "$MARKER"
        printf '%s\n' "[ -f \"$CONFIG/md2pdf.zsh\" ] && source \"$CONFIG/md2pdf.zsh\""
        printf '%s\n' "$MARKER_END"
    } >> "$rc"
    say "added md2pdf to $rc"
fi

say ""
say "done. Restart your shell or run:  source \"$rc\""
say "then try:  md2pdf --list-themes"
