# Lean settings

There are no proofs in this folder. The proofs are in [`checks/`](../checks), one file per card, named `<name>_check.lean`.

This folder holds the settings that fix which version of Lean (the computer proof checker) and of Mathlib (Lean's math library) every proof is checked with. A proof that passes today will pass again tomorrow, because the versions do not move.

- `lean-toolchain` names the Lean version.
- `lakefile.toml` names the Mathlib version and the checking options.
- `lake-manifest.json` records the exact copy of Mathlib and of the packages Mathlib needs.
- `.gitignore` keeps the downloaded Mathlib files out of this repository.

## Check a proof

Install [elan](https://github.com/leanprover/elan) (Lean's installer). Then, from the top folder of the repository:

```bash
cd lean
lake exe cache get                          # fetch Mathlib, already compiled
lake env lean ../checks/place_value_check.lean
```

Lean prints the axioms (the basic assumptions) that each theorem rests on. A complete proof rests only on `propext`, `Classical.choice` and `Quot.sound`.
