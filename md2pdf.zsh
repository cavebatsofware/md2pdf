# md2pfd is a small shell function that uses pandoc and weasyprint to
# produce styled pdfs from markdown including 16 existing colorways
# Copyright (C) 2026 Grant DeFayette - CavebatSoftware LLC

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# Render a markdown file to a Riposte-branded PDF (pandoc + weasyprint).
# Usage: md2pdf [--theme <colorway>] [--dark] <input.md> [output.pdf]
#        md2pdf --list-themes
#   --dark selects the dark variant of the colorway (also: --theme <name>-dark).
#   output defaults to the input name with a .pdf extension.
md2pdf() {
    local dir="$HOME/.config/md2pdf" theme=forest dark=""
    while [[ $1 == -* ]]; do
        case $1 in
            --list-themes|-l) print -l $dir/themes/*.css(:t:r); return 0 ;;
            --theme) theme=$2; shift 2 ;;
            --dark|-d) dark=1; shift ;;
            *) echo "md2pdf: unknown option '$1'" >&2; return 1 ;;
        esac
    done
    [[ -n $dark ]] && theme="${theme%-dark}-dark"
    local in=$1 out=$2
    if [[ -z "$in" || ! -f "$in" ]]; then
        echo "usage: md2pdf [--theme <colorway>] [--dark] <input.md> [output.pdf]" >&2
        echo "       md2pdf --list-themes" >&2
        return 1
    fi
    local themecss="$dir/themes/$theme.css"
    if [[ ! -f "$themecss" ]]; then
        echo "md2pdf: unknown theme '$theme'. choices: ${dir}/themes/*.css ->" >&2
        print -l $dir/themes/*.css(:t:r) >&2
        return 1
    fi
    : ${out:=${in:r}.pdf}
    pandoc "$in" -o "$out" \
        -f gfm+hard_line_breaks -t html5 --standalone \
        --pdf-engine=weasyprint \
        --highlight-style=tango \
        --css="$dir/base.css" --css="$themecss" \
        --metadata title="${in:t:r}" \
        && echo "wrote $out ($theme)"
}

