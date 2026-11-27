# Checks

The programs and proofs that check the cards. Every number on a card is printed by the programs in this folder.

Each card has up to three files here:

- `<name>_check.py` is a Python program that works out every number on the card.
- `<name>_check.rs` is a Rust program that works out the same numbers a second time. Its output must match the Python output exactly.
- `<name>_check.lean` is a proof of the card's main result, checked by Lean (a computer proof checker). A few cards have no Lean proof yet.

## How the files are named

`<name>` is the card's file name without its number, with hyphens turned into underscores. The card `01-place-value.md` has `place_value_check.py`, `place_value_check.rs` and `place_value_check.lean`.

Where two wings have a card with the same name, one of them starts with its wing number, as in `w10_central_limit_theorem_check.py`.

GitHub lists only the first 1,000 files of this folder. To open a file that is not listed, press `t` on GitHub and type its name.

## Run a check

From the top folder of the repository:

```bash
python3 checks/place_value_check.py
rustc --edition 2021 -O checks/place_value_check.rs -o /tmp/check && /tmp/check
```

Each program prints its steps and says whether every check passed.

To check a Lean proof, see [`lean/`](../lean).

## License

The code in this folder is under the [Apache 2.0](LICENSE) license. The writing on the cards is under [CC BY 4.0](../LICENSE).
