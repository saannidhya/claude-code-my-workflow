# Preambles

Shared LaTeX/Beamer preamble for lectures in this project.

## Usage in a lecture

```latex
\documentclass{beamer}
\input{header}   % resolves via TEXINPUTS=../Preambles:$TEXINPUTS

\title{Your Lecture}
\author{You}
\date{\today}

\begin{document}
\frame{\titlepage}
% ...
\end{document}
```

Compile with `/compile-latex <file>` — the skill sets `TEXINPUTS` for you. For manual compilation:

```bash
cd projects/01_<slug>/slides
TEXINPUTS=../../../Preambles:$TEXINPUTS xelatex -interaction=nonstopmode seminar.tex
```

## The palette

The palette block in `header.tex` defines 11 named colors (`primary-blue`, `primary-gold`, `highlight-yellow`, `light-bg`, `jet`, `positive`, `negative`, `neutral`, `hi-slate`, `hi-green`, `hi-red`) for the Beamer theme. To customize, edit the HEX values in that block.

## What's inside

- **Palette** — 11 named colors matching the SCSS.
- **Beamer theme assignments** — structure, titles, itemize, alert, blocks, minimal footer. Applied only under Beamer (`\@ifundefined{beamertemplate}`).
- **TikZ libraries** — `arrows.meta, positioning, calc, decorations.pathreplacing, fit, shapes.geometric, backgrounds`.
- **Shared TikZ styles** — `dag-node`, `decision-node`, `observed-edge`, `counterfactual-edge`, `confound-edge`, `observed-dot`, `counterfactual-dot`. Reusable in hand-written diagrams.
- **Convenience macros** — `\muted{...}`, `\key{...}`, `\good{...}`, `\bad{...}`, `\transitionslide{...}`.

## Extending

Add packages your lectures need *after* your `\input{header}` in each lecture, not in this file — that keeps the preamble small and auditable. Only add to `header.tex` if you are certain every lecture in the project needs it.

For a lecture-specific preamble (rare), create `Preambles/lectureN-addon.tex` and `\input` it after `header.tex`.
