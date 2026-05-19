# HelloWorld Compile Smoke Tests

Minimal Beamer + Quarto files for verifying the shared `Preambles/header.tex`
and `Quarto/theme-template.scss` compile correctly.

These are not lecture material — they're plumbing tests. Originally lived at
`Slides/HelloWorld.tex` and `Quarto/HelloWorld.qmd` in the upstream template
fork; relocated here when this repo transitioned from lecture-template to
research-codebase mode (2026-05-18).

## Usage

```bash
# Beamer compile test
cd templates/hello_world_test && TEXINPUTS=../../Preambles:$TEXINPUTS xelatex HelloWorld.tex

# Quarto render test
quarto render templates/hello_world_test/HelloWorld.qmd
```

If both succeed, the shared LaTeX preamble and Quarto theme are healthy.
