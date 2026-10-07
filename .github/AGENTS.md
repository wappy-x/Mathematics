# Agent brief

Instructions for an AI agent that writes or checks cards for this library. People can read it too: it is the standard every card meets.

Read the whole file before touching anything. Then do exactly one job, **write a card** or **check a card**, as your prompt says.

- [The reader](#the-reader)
- [What you are given](#what-you-are-given)
- [Files you may touch](#files-you-may-touch)
- [The card format](#the-card-format)
- [Size limits](#size-limits)
- [The checks](#the-checks)
- [Pictures](#pictures)
- [Sources](#sources)
- [Job 1: write a card](#job-1-write-a-card)
- [Job 2: check a card](#job-2-check-a-card)
- [Done means](#done-means)
- [Example: the next shelf](#example-the-next-shelf)

## The reader

An intelligent, well-educated adult who never trained in mathematics and is now learning it properly, aiming to become genuinely capable. They want to know *why* a formula exists, not just what it is, and they prefer concise writing.

- Short sentences, one idea each. If a paragraph needs a second read, rewrite it.
- Define every symbol the moment it appears, in plain words, and keep the plain words beside the symbol afterwards.
- Something concrete on the first screen: a named thing, a price, a count, a date.
- A metaphor may introduce an idea, then hands over to the real term, which carries the rest of the card.
- Gloss every technical word in the same sentence, in brackets or after a colon.
- Never condescend ("simply", "obviously"), never pad, never use chat voice ("let me", "you asked"). Nothing on a card describes or addresses a particular reader.

## What you are given

A **spec** for each card. The maintainers post the specs for a shelf when someone claims it (see the [contributing guide](CONTRIBUTING.md)).

| Field | What it tells you |
| --- | --- |
| `wing_dir`, `shelf_dir`, `number`, `slug` | where the card goes: `Cards/<wing_dir>/<shelf_dir>/<NN>-<slug>.md` |
| `title` | the card's title: plain English, with a colon |
| `job` | what the card must do |
| `example` | the concrete example worked all the way through the card |
| `house_example` | the shelf's shared example, for cross-checking numbers between cards |
| `tier` | the size limits, below |
| `needs_first`, `next` | links to the earlier and later cards, ready to paste |
| `siblings` | the other cards on the shelf: link to them, never re-teach them |
| `common_style` | the wing's notation: what already exists, and what this card may introduce |
| `notes` | anything else the card must do, such as handling an overlap with another card |

## Files you may touch

- The card: `Cards/<wing_dir>/<shelf_dir>/<NN>-<slug>.md`.
- Its two checks: `checks/<slug>_check.py` and `checks/<slug>_check.rs`, with the slug's hyphens turned into underscores (for `place-value`: `checks/place_value_check.py`). If the spec says the slug is shared with a card in another wing, prefix the wing: `checks/w13_<slug>_check.py`.
- A figure, only where the spec allows one: `Cards/<wing_dir>/figures/<slug>.svg`.

Nothing else. Scratch work goes in a temporary folder of your own, outside the repository.

## The card format

Copy the shape of these finished cards, and read all three before writing:

- short, tier A: [compound interest](../Cards/01-Foundations/04-Compound%20Growth%20and%20Discounting/03-compound-interest.md)
- middle, tier B: [cosets and Lagrange's theorem](../Cards/03-Algebra/08-Groups/04-cosets-and-lagranges-theorem.md)
- the ceiling, tier C: [the Black–Scholes call](../Cards/12-Financial%20mathematics/08-The%20Black-Scholes%20call%20and%20put/01-black-scholes-call.md)

### The layout

A card starts straight away with its title; there is no frontmatter block. Under the title comes the path line: links back to the syllabus, the wing's page and the shelf on it, then the card's short title (the part of its title before the colon). Then come these headings, in this order, spelled exactly. Sections are separated by `---` and sub-sections use `###`.

```
# <the spec's title>

[Syllabus](../../../SYLLABUS.md) → [<Wing>](../README.md) → [<Shelf>](../README.md#s<MM>) → <short title>

## General Overview
## The formula
## Why it works
## Worked numbers, by hand
## <a "how it moves" section, only if the idea changes with time or state>
## Code, from first principles, and it actually runs
## The usual mistake
## Where you meet it in real life
## What this builds on
## Where this goes next
## Sources
```

- **General Overview.** Open on the concrete example in two or three short paragraphs, and say what the idea *does* before any symbol. End with the whole idea in one bold sentence, then a line starting `**What kind of fact this is:**`, for example "a theorem, proved on this card in Why it works", "a model: an assumption that fits well enough, not a law", or "a conjecture, unproved as of 2026-10-07". The first picture goes here.
- **The formula.** The formula in display maths, then `**Read it aloud:**` and one sentence of English. A table `Symbol | Plain meaning | In our example | Push it up and the answer…` with a row for every symbol on the card. Then `### When it holds`: three to five bullets, each pairing an assumption with what goes wrong when it fails.
- **Why it works.** `### Step 0`, `### Step 1` and so on, each titled by what it achieves. Step 0 is the idea that makes the result possible, in words. Give a real derivation. Heavy algebra or a long proof goes in a fold (below) while the body keeps the proof's shape in words, and a theorem stated without proof names the card that proves it.
- **Worked numbers, by hand.** A table `Step | Arithmetic | Value` on the example, ending in the answer in bold, then one sentence on what the answer means. Then `### What breaks if you drop a piece`: a table `Mistake | Comes out at | What went wrong`, whose wrong answers are computed by the checks.
- **How it moves** (optional). The puzzle in words, one story traced through a table, one force at a time as ASCII bars, then the combined picture as a chart.
- **Code, from first principles.** One paragraph on what the code does and how many independent roads it takes to the answer. `### Python`: the whole script, the provenance line, the output. `### Rust`: the same. Then the "Try changing" box: three or four experiments, each with "guess first", the setting to change and the answer.
- **The usual mistake.** A warning box. The biggest trap first, in bold, with why it is wrong, then three or four smaller traps, each with the wrong number it produces.
- **Where you meet it in real life.** Bullets, each opening with a bold place name, then one or two sentences. End with the "Say it back" box: the whole card in four or five plain sentences, nothing new.
- **What this builds on** and **Where this goes next.** The `needs_first` and `next` cards as bullets, with one line each on what the other card contributes or adds. "Where this goes next" ends with one sentence on the question this card leaves open.
- **Sources.** Open with "Verified <date>: every link below resolves to the publisher's page.", then one line per source on what it contributes.

### Boxes and folds

These forms all render on GitHub.

A fold, for proofs and optional deep-dives. Keep the blank lines, so the maths inside renders:

```
<details>
<summary>Detailed proof: the response is the free part plus a convolution</summary>

The proof, in ordinary Markdown.

</details>
```

"Try changing":

```
> [!TIP]
> **Try changing**
> - Guess first: …
```

The usual mistake is `> [!warning]` followed by the text. "Say it back" is `> **Say it back**` followed by the recap. Every line of a box starts with `> `.

### Links

- **To a written card**, use a relative link whose text is that card's short title (its title before the colon), for example `[Logarithms](../../01-Foundations/03-Powers%2C%20Roots%20and%20Logarithms/05-logarithms.md)`, with spaces written `%20` and commas `%2C`. The spec gives every link ready-made.
- **A card not written yet** is named in plain text by its planned short title, without a link.
- A matrix or nested list written in prose goes in backticks, so `[[2, 1], [1, 1]]` can't be mistaken for a link.

## Size limits

| Tier | Wings | Python | Rust | Each pasted output | Words outside code | Also |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| A | 01–02 | 30 lines | 40 lines | 12 lines | 1,550 | One picture at most, a symbol table of six rows, a what-breaks table of three rows, three sources |
| B | 03–08 | 60 lines | 80 lines | 20 lines | 2,500 | One or two pictures, symbol table up to eight rows, what-breaks up to four, four sources |
| C | 09–25 | 140 lines | 170 lines | 55 lines | 4,800 | Up to three pictures, symbol table up to twelve rows, five sources |

The limits are ceilings, not targets: a card is as big as its idea. Tier A cards also use no notation the reader hasn't met yet: no exponents before the powers shelf, no letters standing for numbers before the rearranging card, and no sigma, subscripts or `\frac`.

## The checks

- Python uses the standard library only. Rust uses `std` only, no crates. If the maths needs a normal CDF, an integrator, a root finder or random numbers, the script writes its own. Nothing imported may already contain the answer.
- Every number on the card is printed by both programs with the same labels: the text, the tables, every chart point and every bar. The two outputs are identical.
- There are at least two independent roads to the answer, such as a formula against brute force, a simulation, a tree or an identity.
- The asserts can fail. At least three compare against an independently computed value. Never compare a computation with itself (`abs(x - x) < tol`, `a <= a`), compare constants (`3 == 3`), or chain fixed arithmetic onto a real assert with `and`.
- Each script runs in under a minute and ends by printing `ALL CHECKS PASS`.
- The code on the card is byte-for-byte the code in `checks/`, and the output on the card is byte-for-byte a real run.

The provenance lines take exactly this shape, with your own date, platform and versions:

```
**Ran 2026-10-07 on Linux, Python 3.12.3, standard library only. All checks passed. Output, pasted from the run:**
**Ran 2026-10-07 on Linux, rustc 1.81.0, no crates. All checks passed. Output, pasted from the run:**
```

Run the checks from a temporary folder:

```bash
python3 -B checks/<slug>_check.py
rustc --edition 2021 -O checks/<slug>_check.rs -o /tmp/<slug> && /tmp/<slug>
```

## Pictures

- **Curves:** a Mermaid `xychart-beta` chart with a title, axis titles with units, and a caption under it naming each line. Start the block with this line, so the chart reads in light and dark mode:

  ```
  %%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
  ```

- **One-dimensional comparisons:** ASCII horizontal bars in a code block, with the label on the left and the value on the right.
- **Chains and decisions:** Mermaid flowcharts.
- **Drawn figures** (geometry, or where the spec allows): an SVG file in `Cards/<wing_dir>/figures/`, drawn to scale from the example's numbers. It has a `viewBox`, a `<title>`, and dark lines on a white panel (a white `<rect>` covering the viewBox), with no scripts and no external references. Both checks print its key coordinates on a line starting `figure,`. Show it on the card with `<p align="center"><img src="../figures/<slug>.svg" alt="<what it shows>" width="420"></p>`.
- **Never:** ASCII line drawings, raster images, or pictures taken from elsewhere.

## Sources

- Cite only works you have opened. Fetch each link and confirm the page names the cited work. A 200 status alone is not proof, because some publishers answer 200 for any product number.
- For each DOI, fetch `https://api.crossref.org/works/<doi>` and confirm the title and first author.
- Cite papers with DOI links and books with publisher pages, one line each on what the source contributes. No Wikipedia. Never invent a citation.

## Job 1: write a card

1. Read the spec, this brief, the three model cards, and the cards listed in `needs_first`.
2. Write the card in the format above, using the spec's title, job and example throughout.
3. Write both checks and run them. Paste the real outputs under the provenance lines, and copy the code onto the card byte for byte.
4. Measure the card against its tier's limits.
5. Open every source and check every DOI.
6. Read the card once, as the reader, and cut anything that doesn't earn its place.
7. Report the card's path, whether both checks pass, the independent roads you used, and anything you could not do.

## Job 2: check a card

You are a hostile checker who also fixes what it finds. You did not write this card, so read it cold.

1. **Read it as the reader.** Mark every stall: a symbol used before it is defined, a word without a gloss, a sentence that needs a second read, padding.
2. **Read it as a mathematician.** Is it correct and complete for this level? Do the overview, the formula, "When it holds", the worked numbers and the code use the same inputs and agree? Look for sign, unit and off-by-one errors and for false claims. Is "What kind of fact this is" true?
3. **Run both checks** in a fresh temporary folder. Confirm the pasted outputs equal your run and the code on the card equals the files.
4. **Mutation-test.** Copy the Python check, break the maths three different ways, and confirm an assert fails each time. A tautological assert is a blocker.
5. **Check the sources**: open every link and check every DOI as above. Replace or drop anything that fails.
6. **Check the links.** Every link opens an existing card, uses that card's short title, and matches the spec; the path line under the title leads to the right wing and shelf.
7. **Fix it.** Classify each finding as a blocker (wrong maths, or a claim the checks contradict), major (the reader would be misled or lost) or minor (polish). Fix every blocker and major, and every minor that is a one-line change, keeping the shape, the size limits, the example and the voice.
8. **Re-run** both checks, re-paste the outputs, re-copy the code, and report what you found and what you changed.

## Done means

- [ ] Every heading is present, in order, spelled exactly.
- [ ] Every symbol on the card has a row in the symbol table.
- [ ] Both checks pass and print identical output, matching what is pasted, and the code on the card equals the files.
- [ ] Every number on the card, in the text, tables, charts and bars, is printed by both checks.
- [ ] At least three asserts can fail, and a mutation test made one fail each time.
- [ ] The card is within its tier's limits.
- [ ] Every source was opened and confirmed, and every DOI was checked.
- [ ] Links match the spec: written cards linked by their short titles, planned cards in plain text, and the path line under the title points at the right wing and shelf.

## Example: the next shelf

At the time of writing, the next shelf in the build is **wing 13, shelf 04: State Space and Optimal Control**. It has ten cards sharing one house example, a cart balancing an inverted pendulum, watched by one noisy encoder. The spec for its first card looks like this:

```json
{
  "wing_dir": "13-Engineering mathematics",
  "shelf_dir": "04-State Space and Optimal Control",
  "number": 1,
  "slug": "state-space-models-and-the-matrix-exponential",
  "title": "State space: a list of internal numbers that steps forward, pushed by the input",
  "job": "Write a plant as first-order vector equations and solve it by the matrix exponential plus a convolution term.",
  "example": "Cart and pendulum: four states; one motor input",
  "house_example": "A cart balancing an inverted pendulum, watched by one noisy encoder",
  "tier": "C",
  "needs_first": [
    "[Transfer functions](../02-Linear%20Systems%20and%20Transforms/02-impulse-response-and-transfer-functions.md)",
    "[Poles and zeros](../02-Linear%20Systems%20and%20Transforms/03-poles-zeros-and-stability.md)",
    "[The matrix exponential](../../08-Differential%20equations%20and%20dynamics/04-Systems%20and%20the%20Matrix%20Exponential/04-the-matrix-exponential.md)",
    "[Forced systems](../../08-Differential%20equations%20and%20dynamics/04-Systems%20and%20the%20Matrix%20Exponential/06-forced-systems-and-variation-of-constants.md)"
  ],
  "next": [
    "Linearisation (planned)",
    "Stability of a state-space model (planned)"
  ],
  "siblings": ["the shelf's other nine cards, as links"],
  "common_style": "Wing 13, tier C. An applied wing: each card turns a physical system into equations, solves or simulates them, and reads the answer back as a number an engineer would act on, with units. This card introduces state x, input u, output y and the matrices (A, B, C, D); the Laplace variable s comes from wing 08 and the transfer function G(s) from shelf 02.",
  "notes": "The differential-equations wing already defines and computes the matrix exponential. State it in one line with the link; spend this card on state-space models: inputs, outputs, the (A, B, C, D) form and the response to an input."
}
```

To build the shelf, work through its cards in order. For each one, run Job 1 in a fresh agent session and Job 2 in a second fresh session, then run the checks yourself and read the card once before moving on.
