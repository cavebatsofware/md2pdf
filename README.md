# md2pdf - styled PDFs from Markdown, in one command

`md2pdf` is a tiny zsh function that turns a Markdown file into a nicely
typeset PDF, with 16 built-in colorways (8 hues × light/dark). Just two
command-line tools and a bit of CSS.

```sh
md2pdf notes.md                    # -> notes.pdf (default "forest" theme)
md2pdf --theme plum --dark spec.md # dark plum colorway
md2pdf --list-themes               # see all colorways
```

## How it works

Under the hood it's a two-stage pipeline:

1. **pandoc** converts the Markdown (GitHub-flavored, with hard line breaks)
   into a standalone HTML5 document and applies syntax highlighting.
2. **weasyprint** renders that HTML plus two stylesheets into a PDF.

The styling is split the way a real design system splits its tokens:

- `base.css` - theme-agnostic layer: typography, spacing, structure, and the
  bundled **Inter** and **JetBrains Mono** fonts.
- `themes/<colorway>.css` - just the color variables for one palette.

`base.css` is passed first, then the chosen theme file overrides the color
tokens, so every colorway shares one consistent layout. Fonts are bundled and
referenced directly because fontconfig otherwise substitutes a variable Noto
Sans that weasyprint mis-renders (digits and `#` silently drop out).

All assets live in `~/.config/md2pdf/`, so the function itself stays a short,
readable shell script.

## Dependencies

- **[pandoc](https://pandoc.org/)** - Markdown -> HTML conversion
- **[weasyprint](https://weasyprint.org/)** - HTML/CSS -> PDF rendering
- **zsh** - the function uses zsh syntax

Install pandoc and weasyprint from your package manager (both are in most
distro repos and Homebrew).

## Install

```sh
git clone https://github.com/CavebatSoftware/md2pdf
cd md2pdf
./install.zsh

# Pass --author <name> to install.zsh to include author metadata in the
# output PDF
```

The installer copies `base.css`, `themes/`, `fonts/`, and the function into
`~/.config/md2pdf/`, then sources it from your `~/.zshrc`. Restart your shell
and run `md2pdf --list-themes` to confirm. To remove everything, run
`./install.zsh --uninstall`.
