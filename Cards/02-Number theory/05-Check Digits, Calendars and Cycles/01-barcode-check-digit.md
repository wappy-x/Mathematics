# Barcode check digits: the last digit of an EAN-13 makes a weighted sum land on a multiple of 10

[Syllabus](../../../SYLLABUS.md) → [Number theory](../README.md) → [Check Digits, Calendars and Cycles](../README.md#s05) → Barcode check digits

---

## General Overview

A pack on the shop counter. Under the black stripes, a row of digits: **5901234123457**. Thirteen of them.

Twelve are the product's name in numbers. The thirteenth is not information — it is a receipt for the other twelve.

The scanner reads all thirteen and does one small sum. On a multiple of 10, good read. Anywhere else a digit was misread, and the till stays quiet. That thirteenth is the **check digit**: a digit that lets the number test itself. The code is an **EAN-13** — International Article Number, thirteen digits (GS1 calls the number a GTIN-13).

**The last digit is chosen so that a weighted sum of all thirteen digits lands exactly on a multiple of 10, and anything else means a misread.**

**What kind of fact this is:** a rule set by the GS1 standard, plus a theorem proved in Why it works: it catches every single wrong digit, but not every swap.

### The picture: every digit with its weight under it

```
5901234123457, the weight under each digit, the product under that

  5   9   0   1   2   3   4   1   2   3   4   5  |  7
  1   3   1   3   1   3   1   3   1   3   1   3  |  1
  5  27   0   3   2   9   4   3   2   9   4  15  |  7
```

The twelve products left of the bar add to 83. Add the check digit's own 7 and you have 90.

---

## The formula

Weights run 1, 3, 1, 3 from the left. Multiply each digit by its weight and add:

**5 × 1 + 9 × 3 + 0 × 1 + 1 × 3 + 2 × 1 + 3 × 3 + 4 × 1 + 1 × 3 + 2 × 1 + 3 × 3 + 4 × 1 + 5 × 3 = 83**

The next multiple of 10 above 83 is 90, so:

**check digit = 90 − 83 = 7**

**Read it aloud:** weight the twelve digits, add them up, and the check digit is how far short of the next multiple of 10 you landed.

| Piece | Plain meaning | In our barcode |
| --- | --- | --- |
| the weights | 1, 3, 1, 3, … from the left | 1 for the 5, 3 for the 9 |
| the weighted sum | each digit times its weight, added | 83 |
| the check digit | how far short of the next multiple of 10 | 7 |
| the whole code | all thirteen weighted, check digit at weight 1 | 90 |

### When it holds

- **One wrong digit at a time.** One wrong digit always moves the total off a multiple of 10. Two wrong digits can cancel each other and pass.
- **Swapped neighbours that are not 5 apart.** Swap a 0 and a 5 and the total stays on a multiple of 10: 5950234123455 still comes to 90.
- **A weight of 3, which shares no factor with 10.** Make every weight 1 and every swap of neighbours turns invisible.

---

## Why it works

### Step 0: zero is the only leftover the scanner accepts

Thirteen is odd, so the check digit sits in an odd position and carries weight 1. Whatever the twelve leave over, it pays off — 10 minus that leftover. A good code therefore leaves nothing over on a 10-hour clock ([Adding and multiplying on the clock](../03-Clock%20Arithmetic/02-modular-addition-and-multiplication.md)): the remainder after dividing by 10 is 0. One number to look at, one value allowed.

The same in remainders: 83 leaves 3, and 10 − 3 is the 7.

### Step 1: one wrong digit can never hide

At weight 1 the total moves by the size of the change, 1 to 9 — never a multiple of 10, so it steps off. At weight 3 the move is 3 times the change. And 3 and 10 share no factor ([Coprime numbers](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/05-coprime-numbers.md)). So the total lands on a multiple of 10 only when the change does — and the change is 1 to 9.

Mistype our fifth digit, the 2, as an 8: 5901834123457, total 96. Rejected.

### Step 2: five pairs of neighbours slip through

Neighbours carry weights 1 and 3, one each. Swap them and the total moves by twice the gap between the digits — a multiple of 10 only when that gap is 5, or 0, and 0 means the digits matched.

Swap the 9 and the 0 at the front of ours: gap 9, total 72. Rejected.

Now put a 0 and a 5 side by side. Change our fourth digit from 1 to 5 and redo the check digit: **5905234123455**, total 100, valid. Swap that 0 and 5: **5950234123455**, total 90, still a multiple of 10, accepted, wrong product. Five pairs are blind like this: 0 with 5, 1 with 6, on to 4 with 9.

<details>
<summary>The credit card version, folded</summary>

A bank card uses **Luhn's rule**, patented by Hans Peter Luhn in 1960: double every second digit from the right, fold anything past 9 by adding its two digits — double 7 for 14, then 1 + 4 = 5 — and land on a multiple of 10. The fold is what closes the swap hole, all but one pair.

</details>

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| the twelve digits, weighted | 5 + 27 + 0 + 3 + 2 + 9 + 4 + 3 + 2 + 9 + 4 + 15 | 83 |
| the next multiple of 10 | 90 | 90 |
| what is missing | 90 − 83 | **7** |
| the digit printed on the pack | last mark of 5901234123457 | **7** |
| all thirteen weighted | 83 + 7 | **90** |

Computed and printed agree, so nothing was misread.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| One digit mistyped, 5901834123457 | 96 | Not a multiple of 10; refused |
| Two neighbours swapped, 5091234123457 | 72 | Not a multiple of 10; refused |
| Neighbours 5 apart swapped, 5950234123455 | 90 | A multiple of 10; gets through |

---

## Code, from first principles, and it actually runs

Nothing is imported. The twelve digits are weighted and added the plain way; the check digit comes by the remainder on a 10-hour clock, then is matched against the printed digit. Then four codes: two caught, one valid, one that hides.

### Python

```python
# EAN-13 check digits -- the check behind the card.  Nothing is imported.  The
# barcode 5901234123457: weights 1, 3, 1, 3, ... left to right, and all
# thirteen weighted digits must add to a multiple of 10.
CODE = "5901234123457"
def weighted(code):                 # 1, 3, 1, 3, ... starting at 1 on the left
    return [int(d) * (1 if i % 2 == 0 else 3) for i, d in enumerate(code)]

def total(code):
    return sum(weighted(code))

def row(name, value, tail=""):
    print(f"{name:<38}{value:>4}{tail}")

first12 = total(CODE[:12])
check = (10 - first12 % 10) % 10                      # the second road: no search
print("the twelve digits, weighted:  " + " ".join(str(v) for v in weighted(CODE[:12])))
row("weighted sum of the first twelve", first12)
row("the multiple of 10 it lands on", first12 + check)
row("what is missing, the check digit", check)
row(f"all thirteen weighted, {first12} + {check}", total(CODE))
for name, code in (("one digit wrong, 5901834123457", "5901834123457"),
                   ("neighbours swapped, 5091234123457", "5091234123457"),
                   ("a 0 and a 5 side by side, valid", "5905234123455"),
                   ("those two swapped, 5950234123455", "5950234123455")):
    row(name, total(code), "  passes" if total(code) % 10 == 0 else "  fails")
print(f"a Luhn double folds: 2 x 7 = {2 * 7}, then {14 // 10} + {14 % 10} = {14 // 10 + 14 % 10}")
assert check == 7 and int(CODE[12]) == check and first12 == 83
assert total(CODE) == 90 and total("5901834123457") == 96 and total("5091234123457") == 72
assert total("5905234123455") == 100 and total("5950234123455") == 90
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
the twelve digits, weighted:  5 27 0 3 2 9 4 3 2 9 4 15
weighted sum of the first twelve        83
the multiple of 10 it lands on          90
what is missing, the check digit         7
all thirteen weighted, 83 + 7           90
one digit wrong, 5901834123457          96  fails
neighbours swapped, 5091234123457       72  fails
a 0 and a 5 side by side, valid        100  passes
those two swapped, 5950234123455        90  passes
a Luhn double folds: 2 x 7 = 14, then 1 + 4 = 5
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// EAN-13 check digits -- the same check as barcode_check_digit_check.py, in
// Rust.  No crates.  The barcode 5901234123457: weights 1, 3, 1, 3, ... left
// to right, and all thirteen weighted digits must add to a multiple of 10.
const CODE: &str = "5901234123457";

fn weighted(code: &str) -> Vec<i64> {   // 1, 3, 1, 3, ... starting at 1 on the left
    code.bytes().enumerate()
        .map(|(i, b)| ((b - b'0') as i64) * if i % 2 == 0 { 1 } else { 3 })
        .collect()
}

fn total(code: &str) -> i64 { weighted(code).iter().sum() }

fn row(name: &str, value: i64, tail: &str) { println!("{:<38}{:>4}{}", name, value, tail); }

fn main() {
    let first12 = total(&CODE[..12]);
    let check = (10 - first12 % 10) % 10;             // the second road: no search
    let parts: Vec<String> = weighted(&CODE[..12]).iter().map(|v| v.to_string()).collect();
    println!("the twelve digits, weighted:  {}", parts.join(" "));
    row("weighted sum of the first twelve", first12, "");
    row("the multiple of 10 it lands on", first12 + check, "");
    row("what is missing, the check digit", check, "");
    row(&format!("all thirteen weighted, {} + {}", first12, check), total(CODE), "");
    for (name, code) in [("one digit wrong, 5901834123457", "5901834123457"),
                         ("neighbours swapped, 5091234123457", "5091234123457"),
                         ("a 0 and a 5 side by side, valid", "5905234123455"),
                         ("those two swapped, 5950234123455", "5950234123455")] {
        row(name, total(code), if total(code) % 10 == 0 { "  passes" } else { "  fails" });
    }
    println!("a Luhn double folds: 2 x 7 = {}, then {} + {} = {}",
             2 * 7, 14 / 10, 14 % 10, 14 / 10 + 14 % 10);
    assert!(check == 7 && (CODE.as_bytes()[12] - b'0') as i64 == check && first12 == 83);
    assert!(total(CODE) == 90 && total("5901834123457") == 96 && total("5091234123457") == 72);
    assert!(total("5905234123455") == 100 && total("5950234123455") == 90);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
the twelve digits, weighted:  5 27 0 3 2 9 4 3 2 9 4 15
weighted sum of the first twelve        83
the multiple of 10 it lands on          90
what is missing, the check digit         7
all thirteen weighted, 83 + 7           90
one digit wrong, 5901834123457          96  fails
neighbours swapped, 5091234123457       72  fails
a 0 and a 5 side by side, valid        100  passes
those two swapped, 5950234123455        90  passes
a Luhn double folds: 2 x 7 = 14, then 1 + 4 = 5
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the card's three claims for every EAN-13 code, not just 5901234123457.

- Any twelve digits have exactly one check digit that works: 10 minus their leftover, or 0 if nothing is left over.
- In a good code, one wrong digit always moves the total off a multiple of 10.
- Swap two neighbours in a good code, and it still passes exactly when the two digits are equal or 5 apart.
- The card's own totals come out the same: 83, 90, 96, 72, 100 and 90 again.

Reading a barcode as text and printing the table of totals stay with the Python and Rust checks.

<details>
<summary>The Lean proof, 86 lines</summary>

```lean
-- Barcode check digits: weighting the digits 1, 3, 1, 3 from the left, exactly one last digit puts an EAN-13's total on a multiple of 10, every single wrong digit is then caught, and a swap of neighbours slips through only when the two digits are equal or 5 apart.
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Fin.Tuple.Basic
import Mathlib.Logic.Equiv.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.Ring

open Finset

/-- The EAN weight of the digit in position `i`, counting from 0 at the left: 1, 3, 1, 3, ... -/
def eanWeight (i : ℕ) : ℕ := if i % 2 = 0 then 1 else 3

/-- The weighted sum of a row of digits: each digit times its weight, added up. -/
def eanTotal {n : ℕ} (c : Fin n → ℕ) : ℕ := ∑ i, eanWeight i.val * c i

/-- Helper: the total of thirteen digits written out term by term. -/
theorem eanTotal13 (f : Fin 13 → ℕ) : eanTotal f = f 0 + 3 * f 1 + f 2 + 3 * f 3 + f 4 + 3 * f 5 + f 6
    + 3 * f 7 + f 8 + 3 * f 9 + f 10 + 3 * f 11 + f 12 := by
  unfold eanTotal
  simp [Fin.sum_univ_succ, eanWeight]
  omega

#print axioms eanTotal13

/-- The check digit. Take any twelve digits and put a digit `d` from 0 to 9 after them. The
total of all thirteen lands on a multiple of 10 exactly when `d` is how far short of the next
multiple of 10 the twelve landed: 10 minus their remainder, or 0 if there is no remainder. So
there is one and only one check digit that works. -/
theorem check_digit_is_unique_and_lands_on_multiple_of_ten (x : Fin 12 → ℕ) (d : ℕ)
    (hd : d < 10) :
    10 ∣ eanTotal (Fin.snoc (α := fun _ => ℕ) x d) ↔ d = (10 - eanTotal x % 10) % 10 := by
  have h : eanTotal (Fin.snoc (α := fun _ => ℕ) x d) = eanTotal x + d := by
    unfold eanTotal
    rw [Fin.sum_univ_castSucc]
    have : Fin.snoc (α := fun _ => ℕ) x d (12 : Fin 13) = d := Fin.snoc_last _ _
    simp [eanWeight, this]
  rw [h]
  omega

/-- One wrong digit can never hide. Start from a good code: thirteen digits from 0 to 9 whose
total is a multiple of 10. Change one digit to a different digit from 0 to 9. The new total is
not a multiple of 10, so the scanner refuses it. -/
theorem one_wrong_digit_is_always_caught (c : Fin 13 → ℕ) (hc : ∀ i, c i < 10)
    (hvalid : 10 ∣ eanTotal c) (j : Fin 13) (d : ℕ) (hd : d < 10) (hne : d ≠ c j) :
    ¬ 10 ∣ eanTotal (Function.update c j d) := by
  have h0 := hc 0; have h1 := hc 1; have h2 := hc 2; have h3 := hc 3; have h4 := hc 4
  have h5 := hc 5; have h6 := hc 6; have h7 := hc 7; have h8 := hc 8; have h9 := hc 9
  have h10 := hc 10; have h11 := hc 11; have h12 := hc 12
  rw [eanTotal13] at hvalid ⊢
  fin_cases j <;> simp [Function.update] at hne ⊢ <;> omega

/-- The swap hole. Start from a good code of thirteen digits from 0 to 9 and swap two neighbours.
The swapped code still lands on a multiple of 10 exactly when the two digits are equal or 5
apart. -/
theorem swapped_neighbours_pass_iff_equal_or_five_apart (c : Fin 13 → ℕ) (hc : ∀ i, c i < 10)
    (hvalid : 10 ∣ eanTotal c) (i : Fin 12) :
    10 ∣ eanTotal (c ∘ Equiv.swap i.castSucc i.succ) ↔
      (c i.castSucc = c i.succ ∨ c i.castSucc + 5 = c i.succ ∨ c i.succ + 5 = c i.castSucc) := by
  have h0 := hc 0; have h1 := hc 1; have h2 := hc 2; have h3 := hc 3; have h4 := hc 4
  have h5 := hc 5; have h6 := hc 6; have h7 := hc 7; have h8 := hc 8; have h9 := hc 9
  have h10 := hc 10; have h11 := hc 11; have h12 := hc 12
  rw [eanTotal13] at hvalid ⊢
  fin_cases i <;> simp [Equiv.swap_apply_def] <;> omega

-- The card's barcode 5901234123457: the twelve weigh in at 83, the check digit is 7, all thirteen make 90.
example : eanTotal ![5, 9, 0, 1, 2, 3, 4, 1, 2, 3, 4, 5] = 83 := by decide
example : (10 - 83 % 10) % 10 = 7 ∧ 90 - 83 = 7 := by decide
example : eanTotal ![5, 9, 0, 1, 2, 3, 4, 1, 2, 3, 4, 5, 7] = 90 := by decide
-- One digit mistyped, 5901834123457: 96, refused.
example : eanTotal ![5, 9, 0, 1, 8, 3, 4, 1, 2, 3, 4, 5, 7] = 96 ∧ ¬ 10 ∣ 96 := by decide
-- The 9 and the 0 swapped, 5091234123457: 72, refused.
example : eanTotal ![5, 0, 9, 1, 2, 3, 4, 1, 2, 3, 4, 5, 7] = 72 ∧ ¬ 10 ∣ 72 := by decide
-- A 0 and a 5 side by side, 5905234123455: 100, valid. Swapped, 5950234123455: 90, still passes.
example : eanTotal ![5, 9, 0, 5, 2, 3, 4, 1, 2, 3, 4, 5, 5] = 100 := by decide
example : eanTotal ![5, 9, 5, 0, 2, 3, 4, 1, 2, 3, 4, 5, 5] = 90 := by decide
-- Try changing: the 9 made a 4 drops the total by 15, from 90 to 75.
example : eanTotal ![5, 4, 0, 1, 2, 3, 4, 1, 2, 3, 4, 5, 7] = 75 := by decide
-- Flattened weights: the twelve digits add to 39, and the check digit would be 1.
example : [5, 9, 0, 1, 2, 3, 4, 1, 2, 3, 4, 5].sum = 39 ∧ (10 - 39 % 10) % 10 = 1 := by decide
-- Luhn's fold: double 7 for 14, then 1 + 4 = 5.
example : 2 * 7 = 14 ∧ 14 / 10 + 14 % 10 = 5 := by decide

#print axioms check_digit_is_unique_and_lands_on_multiple_of_ten
#print axioms one_wrong_digit_is_always_caught
#print axioms swapped_neighbours_pass_iff_equal_or_five_apart
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'eanTotal13' depends on axioms: [propext, Classical.choice, Quot.sound]
'check_digit_is_unique_and_lands_on_multiple_of_ten' depends on axioms: [propext, Classical.choice, Quot.sound]
'one_wrong_digit_is_always_caught' depends on axioms: [propext, Classical.choice, Quot.sound]
'swapped_neighbours_pass_iff_equal_or_five_apart' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it; an assert will fire.
> - **Break a digit.** Change the 9 in `CODE` to a 4. It carries weight 3 and the gap is 5, so the total drops 15: 90 becomes 75, and the first assert, on the check digit, fires.
> - **Flatten the weights.** Make every weight 1. The twelve digits add to 39, the check digit comes out 1, and every neighbouring swap turns invisible.

---

## The usual mistake

> [!warning]
> **Thinking a check digit says the number is correct.** It says the number is *consistent with itself*. Anyone can compute a valid check digit for a product that never existed. It catches accidents, not lies.
>
> - **Taking 10 for the check digit.** If the twelve already land on a multiple of 10, the digit is 0.
> - **Weighting from the wrong end.** The standard counts from the right. Thirteen is odd, so both ends agree here; on the twelve digits of a UPC (the Universal Product Code used in North America) they do not.

---

## Where you meet it in real life

- **Every till.** Scanners misread smudged stripes all day. The check digit is why the wrong tin almost never rings up at the wrong price; you just pass the pack again.
- **Bank cards and phone IMEI numbers.** An IMEI is the serial number every phone carries. Luhn's rule: why a site rejects a mistyped card before it reaches the bank.
- **Older books.** An ISBN-10 checks on an 11-hour clock, catching every swap this card misses: [ISBN-10 and the prime modulus 11](02-isbn-check-digit.md). Today's 13-digit ISBN is an EAN-13 and shares the hole.

> **Say it back**
> A barcode's last digit is not information, it is a test. Weight the digits 1, 3, 1, 3 and add them up; the last digit is picked to push the total onto a multiple of 10. Ours comes to 83, 7 short of 90, so the check digit is 7. Any single wrong digit shifts the total off the multiple and is caught. A swap of neighbours shifts it by twice their gap, so neighbours 5 apart slip through — the hole in the rule for swapped neighbours.

---

## What this builds on

- [Place value](../../01-Foundations/01-Everyday%20Arithmetic/01-place-value.md): a numeral is digits in columns, which is what lets a barcode be read a digit at a time.
- [Divisibility rules](../01-Divisibility%20and%20Primes/03-divisibility-rules.md): testing a number by weighting its digits, the move made here.
- [Adding and multiplying on the clock](../03-Clock%20Arithmetic/02-modular-addition-and-multiplication.md): only what a total leaves on a clock matters.
- [Coprime numbers](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/05-coprime-numbers.md): two numbers sharing no factor, which is why weight 3 hides nothing.

## Where this goes next

- [ISBN-10 and the prime modulus 11](02-isbn-check-digit.md): the same trick on an 11-hour clock, where a prime modulus closes the swap hole this card leaves open.

Left open: can a check digit catch every swap of neighbours, not just most of them?

---

## Sources

Verified 6 Sep 2026: every link below resolves to the publisher's page.

- GS1. *GS1 General Specifications*. [Standard page](https://ref.gs1.org/standards/genspecs/). Defines EAN-13, its weights and its check digit.
- Luhn, Hans Peter. *Computer for Verifying Numbers*. US Patent 2,950,048, 1960. [Patent page](https://patents.google.com/patent/US2950048A/en). The folded variant on bank cards.
