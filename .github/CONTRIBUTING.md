# Contributing

Thank you for helping. There are three ways in, from a two-minute fix to a whole shelf of new cards.

- [Report a mistake](#report-a-mistake)
- [Improve a card](#improve-a-card)
- [Build new cards](#build-new-cards)
- [What happens to your pull request](#what-happens-to-your-pull-request)
- [Ground rules](#ground-rules)

## Report a mistake

Open an issue and include:

- the card, as a link or its path;
- what is wrong, quoting the line;
- why: a calculation, a counterexample or a source.

If you're confident of the fix, send a pull request instead.

## Improve a card

Typos, unclear sentences, a better example, a sharper check: send a pull request that changes one card, plus its two checks if the maths changes. Before you send it:

- keep the card's shape, with the same sections in the same order (the [agent brief](AGENTS.md#the-card-format) spells it out);
- if any number changes, update both checks, run them, and paste the new output under the card's two "Ran …" lines with today's date and your platform;
- leave `status` as it is; the maintainers update it after their own re-run.

## Build new cards

1,866 cards are planned and 1,087 are written. The [syllabus](../SYLLABUS.md) lists every card still to write, shelf by shelf, marked `·`. Building a shelf is the biggest help there is, and an AI agent can do most of the work if you give it the [agent brief](AGENTS.md). It's the same brief the library is built with.

### 1. Claim a shelf

Open an issue titled, for example, **Claim: wing 13, shelf 04**. The maintainers reply with that shelf's card specs: each card's file name, title, job, worked example, links to earlier and later cards, and the notation it may use. Wait for the reply before you start. That way two people never build the same shelf, and every card slots into the plan.

Shelves are built in order inside a wing, because later cards lean on earlier ones. The [agent brief](AGENTS.md#example-the-next-shelf) shows the next shelf and its first spec.

### 2. Set up

You need:

- git and a GitHub account, with your own fork of this repository;
- Python 3.10 or newer, standard library only;
- Rust, installed with [rustup](https://rustup.rs), standard library only;
- an AI coding agent that can read and write files and run commands in a terminal. Any capable one works.

```bash
git clone https://github.com/<you>/Mathematics.git
cd Mathematics
git switch -c wing13-shelf04
```

### 3. Write, then check in a separate pass

Every card is built in two passes by two separate agent sessions, and the second pass matters most. Work through the shelf's cards in order.

**Write.** Start a fresh agent session in the repository folder and tell it:

> Read `.github/AGENTS.md`, then do Job 1: write the card described by this spec. *(paste the card's spec)*

**Check.** Start a *new* session, so it reads the card cold, and tell it:

> Read `.github/AGENTS.md`, then do Job 2: check and fix `Cards/…/01-….md` against this spec. *(paste the same spec)*

**Read it yourself.** Run both checks (below), then read the card once as a newcomer would and fix anything that makes you stall.

If your agent can run several sub-agents at once, you can do a whole shelf in one go: a writer per card, then a checker per card. That's how the library is built in batches.

### 4. Run the checks

```bash
python3 -B checks/<slug>_check.py
rustc --edition 2021 -O checks/<slug>_check.rs -o /tmp/check && /tmp/check
```

Both programs must finish cleanly and print identical output, and that output must match what is pasted on the card.

### 5. Send it

One shelf per pull request:

```bash
git add Cards checks
git commit -m "Wing 13, shelf 04: State Space and Optimal Control"
git push -u origin wing13-shelf04
```

Then open a pull request against `main`. The template has a short checklist.

## What happens to your pull request

1. The maintainers re-run every check from a clean folder and compare the output with what is pasted on the card.
2. They run the house linter, which checks shape, sizes, links, symbols and sources, and an independent review that recomputes the numbers and reads the proofs.
3. They send back anything that needs fixing, or merge it. A card is marked `status: verified` only after it passes all of that.

Small fixes are usually quick. A new shelf gets a careful read.

## Ground rules

- **Nothing typed by hand.** Every number on a card is printed by both programs.
- **Real sources only.** Open every link and confirm it names the cited work. No Wikipedia.
- **Your own words.** Don't paste text from books or websites.
- **AI help is welcome.** You are responsible for what you send, so check it as if you'd written every line.
- **Licences.** By sending a pull request you agree that your writing is released under [CC BY 4.0](../LICENSE) and your code under [Apache 2.0](../checks/LICENSE), like the rest of the library.
