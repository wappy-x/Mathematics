# Divisibility rules: reading the digits to see whether 2, 3, 4, 5, 6, 8, 9 or 10 divides a number

[Syllabus](../../../SYLLABUS.md) → [Number theory](../README.md) → [Divisibility and Primes](../README.md#s01) → Divisibility rules

---

## General Overview

Dinner for a big table. The bill is **$1,236**, and everyone wants to pay the same whole number of dollars. Can three of you split it? Four? Eight?

Nobody divides 1,236 to find out. Add the digits: 1 + 2 + 3 + 6 = 12, a multiple of 3, so three ways works. The last two digits, 36, are a multiple of 4, so four ways works. The last three, 236, are not a multiple of 8, so eight people cannot.

Those are **divisibility rules**: tests that read a few digits instead of dividing.

**Every rule reads a small number — a tail, or the digit sum — and ignores the rest, because the rest is a multiple of the number you are testing.**

**What kind of fact this is:** a theorem for each divisor, proved on this card in Why it works; the 7 and 11 tests in the fold are stated without proof.

### The picture: where the rules cut

```
1,236 dollars, cut between the place-value columns

    1230 + 6      1230 is a whole number of tens, so 2, 5 and 10 read only the 6
    1200 + 36     1200 is a whole number of hundreds, so 4 reads only the 36
    1000 + 236    1000 is a whole number of thousands, so 8 reads only the 236
```

Only the right piece decides.

---

## The formula

The **digit sum** is the digits added up, 1 + 2 + 3 + 6 = 12. **The last digits**, or the tail, are read off the right end: 6, 36, 236.

| Divisor | The test | 1,236 is |
| --- | --- | --- |
| 2 | last digit even | yes: 2 × 618 |
| 3 | digit sum divides by 3 | yes: 3 × 412 |
| 4 | last two digits divide by 4 | yes: 4 × 309 |
| 5 | last digit 0 or 5 | no: 5 × 247 + 1 |
| 6 | the 2 test and the 3 test | yes: 6 × 206 |
| 8 | last three digits divide by 8 | no: 8 × 154 + 4 |
| 9 | digit sum divides by 9 | no: 9 × 137 + 3 |
| 10 | last digit 0 | no: 10 × 123 + 6 |

**Read it aloud:** tail for 2, 4, 5, 8 and 10; digit sum for 3 and 9; both of those for 6.

### When it holds

- **Ordinary tens columns.** The tail rules need 10 = 2 × 5, 100 = 4 × 25 and 1000 = 8 × 125. Count in columns of anything but ten and those splits fail, so the rules change.
- **A tail long enough for the divisor.** 100 is not a whole number of 8s, so 8 needs three digits. Two digits say no on a $1,136 bill, but 1,136 = 8 × 142.
- **The digit sum only for 3 and 9.** Every column is a row of 9s plus 1, and only 3 and 9 go evenly into 9. For any other divisor the sum can give the wrong answer.
- **For 6, two tests with no shared factor.** 2 and 3 share none, so together they test 6. The 2 and 4 tests are no test for 8: 12 passes both and fails 8.

---

## Why it works

### Why the tail is enough

Ten is two 5s, so any number of whole tens splits two, five and ten ways. The bill is 1230 + 6, so only the 6 decides: even, so 2 divides; not 0 or 5, so 5 and 10 do not.

A hundred is four 25s: the bill is 1200 + 36, and 36 splits four ways. A thousand is eight 125s: the bill is 1000 + 236, and 236 is 4 over — the bill's own leftover, 1,236 = 8 × 154 + 4.

### Why the digits add up for 3 and 9

Every column is one more than a row of 9s: 10 is 9 + 1, 100 is 99 + 1, 1000 is 999 + 1. So the bill is one 999 plus 1, two 99s plus 2, three 9s plus 3, and 6.

Sweep the nines together: 1 × 999 + 2 × 99 + 3 × 9 = 1224, which is 9 × 136. What is left is the digit sum, 12. So 1,236 = 1224 + 12.

1224 is a multiple of 9, so also of 3 (9 is three 3s). It cannot change either verdict. Only the digit sum, 12, can: 12 is a multiple of 3, so 1,236 = 3 × 412; 12 runs 3 past 9, so 1,236 = 9 × 137 + 3.

### Six is 2 and 3 together

Six is 2 × 3, and 2 and 3 share no factor above 1, so splitting two and three ways means splitting six ways: 1,236 = 6 × 206. The pairing needs testers with no shared factor. The 2 and 4 tests together are no test for 8 — 12 passes 2 and 4, but fails 8.

<details>
<summary>7 and 11, if you want them</summary>

**11:** add every other digit, then the ones you skipped; if the totals match or differ by a multiple of 11, 11 divides.
**7:** chop off the last digit, double it, subtract it from the rest, and repeat.
The 7 test is slower than dividing.

</details>

The alternative is the division itself: [Division with a remainder](04-division-with-remainder.md).

---

## Worked numbers, by hand

The bill, test by test.

| Step | Arithmetic | Value |
| --- | --- | --- |
| add the digits | 1 + 2 + 3 + 6 | 12 |
| three ways: 12 divides by 3 | 1236 ÷ 3 | **412** |
| four ways: 36 does too | 1236 ÷ 4 | **309** |
| eight ways: 236 does not | 1236 ÷ 8 | 154, **4 left** |
| nine ways: 12 does not | 1236 ÷ 9 | 137, 3 left |

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| 4 tested on the last digit | "no", 6 is not | 1,236 = 4 × 309 |
| digit sum 12 as a pass for 9 | "yes" | 1,236 = 9 × 137 + 3 |
| 8 tested on the last two digits | "no" on a $1,136 bill | 1,136 = 8 × 142 |

---

## Code, from first principles, and it actually runs

Each rule is decided from the digits alone. The real division is the second road; an assert makes the two agree.

### Python

```python
# Divisibility rules -- the check behind the card.  Nothing is imported.  The
# $1,236 restaurant bill: every rule is decided from the digits alone, then
# checked against the real division, a second road to the same verdict.
BILL = 1236                                     # the restaurant bill, in dollars
SUM = 1 + 2 + 3 + 6                             # the digit sum, 12
NINES = 1 * 999 + 2 * 99 + 3 * 9                # the pile of nines under the digits
LOOK = {2: BILL % 10, 5: BILL % 10, 10: BILL % 10, 4: BILL % 100,
        8: BILL % 1000, 3: SUM, 9: SUM}         # the little number each rule reads
WORDS = {2: "last digit 6", 3: "digit sum 12", 4: "last two digits 36",
         5: "last digit 6", 6: "passes 2 and 3", 8: "last three digits 236",
         9: "digit sum 12", 10: "last digit 6"}

def rule(d):                        # the verdict from the digits, never dividing 1236
    return rule(2) and rule(3) if d == 6 else LOOK[d] % d == 0

for d in (2, 3, 4, 5, 6, 8, 9, 10):
    q, r = BILL // d, BILL % d
    done = f"1236 = {d} x {q}" + (f" + {r}" if r else "")
    print(f"{d:<4}{WORDS[d]:<23}{'yes' if rule(d) else 'no':<6}{done}")
    assert rule(d) == (r == 0)      # the digits and the division must agree
print(f"splits  1236 = {BILL - BILL % 10} + {BILL % 10} = {BILL - BILL % 100} + {BILL % 100}"
      f" = {BILL - BILL % 1000} + {BILL % 1000}; 10 = 2 x {10 // 2}, 100 = 4 x {100 // 4}, 1000 = 8 x {1000 // 8}")
print(f"nines   1236 = 1 x 999 + 2 x 99 + 3 x 9 + {SUM} = {NINES} + {SUM}, and {NINES} = 9 x {NINES // 9}")
print(f"mistakes  last digit for 4 says no (truth 4 x {BILL // 4}); sum 12 for 9 says yes "
      f"(truth 9 x {BILL // 9} + {BILL % 9}); last two digits for 8 says no on 1136 (truth 8 x {1136 // 8})")
assert BILL % 9 == SUM % 9 == 3 and BILL % 3 == SUM % 3 == 0
assert BILL % 8 == (BILL % 1000) % 8 == 4 and NINES % 9 == 0 and NINES + SUM == BILL
assert 1136 % 8 == 0 and (1136 % 100) % 8 != 0  # the rule that is not a rule
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
2   last digit 6           yes   1236 = 2 x 618
3   digit sum 12           yes   1236 = 3 x 412
4   last two digits 36     yes   1236 = 4 x 309
5   last digit 6           no    1236 = 5 x 247 + 1
6   passes 2 and 3         yes   1236 = 6 x 206
8   last three digits 236  no    1236 = 8 x 154 + 4
9   digit sum 12           no    1236 = 9 x 137 + 3
10  last digit 6           no    1236 = 10 x 123 + 6
splits  1236 = 1230 + 6 = 1200 + 36 = 1000 + 236; 10 = 2 x 5, 100 = 4 x 25, 1000 = 8 x 125
nines   1236 = 1 x 999 + 2 x 99 + 3 x 9 + 12 = 1224 + 12, and 1224 = 9 x 136
mistakes  last digit for 4 says no (truth 4 x 309); sum 12 for 9 says yes (truth 9 x 137 + 3); last two digits for 8 says no on 1136 (truth 8 x 142)
ALL CHECKS PASS
```

### Rust

Same numbers, built with `rustc --edition 2021 -O`.

```rust
// Divisibility rules -- the same check as divisibility_rules_check.py, in Rust.
// No crates.  The $1,236 restaurant bill: every rule is decided from the digits
// alone, then checked against the real division, a second road to the verdict.
const BILL: i64 = 1236;                        // the restaurant bill, in dollars
const SUM: i64 = 1 + 2 + 3 + 6;                // the digit sum, 12
const NINES: i64 = 1 * 999 + 2 * 99 + 3 * 9;   // the pile of nines under the digits

fn look(d: i64) -> i64 {           // the little number the rule for d reads
    match d { 2 | 5 | 10 => BILL % 10, 4 => BILL % 100, 8 => BILL % 1000, _ => SUM }
}

fn rule(d: i64) -> bool {          // the verdict from the digits, never dividing 1236
    if d == 6 { rule(2) && rule(3) } else { look(d) % d == 0 }
}

fn main() {
    let words = [(2, "last digit 6"), (3, "digit sum 12"), (4, "last two digits 36"),
                 (5, "last digit 6"), (6, "passes 2 and 3"), (8, "last three digits 236"),
                 (9, "digit sum 12"), (10, "last digit 6")];
    for (d, w) in words {
        let (q, r) = (BILL / d, BILL % d);
        let mut done = format!("1236 = {} x {}", d, q);
        if r != 0 { done.push_str(&format!(" + {}", r)); }
        println!("{:<4}{:<23}{:<6}{}", d, w, if rule(d) { "yes" } else { "no" }, done);
        assert!(rule(d) == (r == 0));   // the digits and the division must agree
    }
    println!("splits  1236 = {} + {} = {} + {} = {} + {}; 10 = 2 x {}, 100 = 4 x {}, 1000 = 8 x {}",
             BILL - BILL % 10, BILL % 10, BILL - BILL % 100, BILL % 100,
             BILL - BILL % 1000, BILL % 1000, 10 / 2, 100 / 4, 1000 / 8);
    println!("nines   1236 = 1 x 999 + 2 x 99 + 3 x 9 + {} = {} + {}, and {} = 9 x {}",
             SUM, NINES, SUM, NINES, NINES / 9);
    println!("mistakes  last digit for 4 says no (truth 4 x {}); sum 12 for 9 says yes \
              (truth 9 x {} + {}); last two digits for 8 says no on 1136 (truth 8 x {})",
             BILL / 4, BILL / 9, BILL % 9, 1136 / 8);
    assert!(BILL % 9 == SUM % 9 && SUM % 9 == 3 && BILL % 3 == 0 && SUM % 3 == 0);
    assert!(BILL % 8 == (BILL % 1000) % 8 && BILL % 8 == 4 && NINES % 9 == 0 && NINES + SUM == BILL);
    assert!(1136 % 8 == 0 && (1136 % 100) % 8 != 0);   // the rule that is not a rule
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
2   last digit 6           yes   1236 = 2 x 618
3   digit sum 12           yes   1236 = 3 x 412
4   last two digits 36     yes   1236 = 4 x 309
5   last digit 6           no    1236 = 5 x 247 + 1
6   passes 2 and 3         yes   1236 = 6 x 206
8   last three digits 236  no    1236 = 8 x 154 + 4
9   digit sum 12           no    1236 = 9 x 137 + 3
10  last digit 6           no    1236 = 10 x 123 + 6
splits  1236 = 1230 + 6 = 1200 + 36 = 1000 + 236; 10 = 2 x 5, 100 = 4 x 25, 1000 = 8 x 125
nines   1236 = 1 x 999 + 2 x 99 + 3 x 9 + 12 = 1224 + 12, and 1224 = 9 x 136
mistakes  last digit for 4 says no (truth 4 x 309); sum 12 for 9 says yes (truth 9 x 137 + 3); last two digits for 8 says no on 1136 (truth 8 x 142)
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves every rule on this card for every whole number, not just the $1,236 bill.

- 2, 5 and 10 are decided by the last digit, 4 by the last two digits, and 8 by the last three.
- 3 and 9 are decided by the digit sum.
- 6 divides a number exactly when it passes the 2 test and the 3 test.
- Among the card's divisors, the digit sum gives the right answer every time only for 3 and 9.
- Two digits are not enough for 8: 1,136 is a multiple of 8, but 36 is not.
- The 2 and 4 tests are no test for 8: 12 passes both and fails 8.
- The bill's own numbers come out right: each row of the table, the cuts, and the sweep of nines.

The printed table, and each rule run against the real division, stay with the Python and Rust checks.

```lean
-- Divisibility rules: for every whole number, 2, 4, 5, 8 and 10 are decided by its last one, two or three digits, 3 and 9 by its digit sum, and 6 by the 2 test and the 3 test together, while the digit sum works for no other divisor on the card.
import Mathlib.Data.Nat.Digits.Div
import Mathlib.Tactic.NormNum

/-- The card's table, for every whole number `n`. The last digit is `n % 10`, the last two
digits are `n % 100`, the last three are `n % 1000`, and the digit sum is the sum of the base-ten
digits of `n`.
- 2 divides `n` exactly when the last digit is even.
- 3 divides `n` exactly when 3 divides the digit sum.
- 4 divides `n` exactly when 4 divides the last two digits.
- 5 divides `n` exactly when the last digit is 0 or 5.
- 6 divides `n` exactly when `n` passes the 2 test and the 3 test.
- 8 divides `n` exactly when 8 divides the last three digits.
- 9 divides `n` exactly when 9 divides the digit sum.
- 10 divides `n` exactly when the last digit is 0. -/
theorem divisibility_rules_read_the_tail_or_the_digit_sum (n : ℕ) :
    (2 ∣ n ↔ Even (n % 10)) ∧
    (3 ∣ n ↔ 3 ∣ (Nat.digits 10 n).sum) ∧
    (4 ∣ n ↔ 4 ∣ n % 100) ∧
    (5 ∣ n ↔ n % 10 = 0 ∨ n % 10 = 5) ∧
    (6 ∣ n ↔ Even (n % 10) ∧ 3 ∣ (Nat.digits 10 n).sum) ∧
    (8 ∣ n ↔ 8 ∣ n % 1000) ∧
    (9 ∣ n ↔ 9 ∣ (Nat.digits 10 n).sum) ∧
    (10 ∣ n ↔ n % 10 = 0) := by
  have h3 := Nat.three_dvd_iff n
  have h9 := Nat.nine_dvd_iff n
  simp only [Nat.even_iff]
  refine ⟨by omega, h3, by omega, by omega, ?_, by omega, h9, by omega⟩
  rw [← h3]
  omega

/-- The digit sum only for 3 and 9. Among the card's divisors 2, 3, 4, 5, 6, 8, 9 and 10, the
digit-sum test gives the right answer for every whole number exactly when the divisor is 3 or 9.
For every other one, some number gets the wrong answer. -/
theorem digit_sum_test_works_only_for_three_and_nine (d : ℕ)
    (hd : d ∈ ({2, 3, 4, 5, 6, 8, 9, 10} : Finset ℕ)) :
    (∀ n : ℕ, d ∣ n ↔ d ∣ (Nat.digits 10 n).sum) ↔ d = 3 ∨ d = 9 := by
  simp only [Finset.mem_insert, Finset.mem_singleton] at hd
  constructor
  · intro h
    rcases hd with rfl | rfl | rfl | rfl | rfl | rfl | rfl | rfl
    · have := (h 11).mpr (by norm_num); omega
    · simp
    · have := (h 22).mpr (by norm_num); omega
    · have := (h 14).mpr (by norm_num); omega
    · have := (h 39).mpr (by norm_num); omega
    · have := (h 44).mpr (by norm_num); omega
    · simp
    · have := (h 19).mpr (by norm_num); omega
  · rintro (rfl | rfl)
    · exact Nat.three_dvd_iff
    · exact Nat.nine_dvd_iff

/-- The two ways to get the 8 test wrong. Two tail digits are not enough for 8: some number
is a multiple of 8 although its last two digits are not. And the 2 test and the 4 test together
are no test for 8: some number passes both and still is not a multiple of 8. -/
theorem eight_needs_three_digits_and_not_two_and_four :
    (∃ n : ℕ, ¬ (8 ∣ n ↔ 8 ∣ n % 100)) ∧
    (∃ n : ℕ, 2 ∣ n ∧ 4 ∣ n ∧ ¬ 8 ∣ n) := by
  exact ⟨⟨1136, by decide⟩, ⟨12, by decide, by decide, by decide⟩⟩

/-! The card's worked numbers for the $1,236 bill. -/

-- The digit sum: 1 + 2 + 3 + 6 = 12.
example : (Nat.digits 10 1236).sum = 12 := by norm_num

-- The table, row by row.
example : 1236 = 2 * 618 := by norm_num
example : 1236 = 3 * 412 := by norm_num
example : 1236 = 4 * 309 := by norm_num
example : 1236 = 5 * 247 + 1 := by norm_num
example : 1236 = 6 * 206 := by norm_num
example : 1236 = 8 * 154 + 4 := by norm_num
example : 1236 = 9 * 137 + 3 := by norm_num
example : 1236 = 10 * 123 + 6 := by norm_num

-- The verdicts: 2, 3, 4 and 6 divide the bill; 5, 8, 9 and 10 do not.
example : 2 ∣ 1236 ∧ 3 ∣ 1236 ∧ 4 ∣ 1236 ∧ 6 ∣ 1236 := by decide
example : ¬ 5 ∣ 1236 ∧ ¬ 8 ∣ 1236 ∧ ¬ 9 ∣ 1236 ∧ ¬ 10 ∣ 1236 := by decide

-- Where the rules cut: 1236 = 1230 + 6 = 1200 + 36 = 1000 + 236,
-- and 10 = 2 × 5, 100 = 4 × 25, 1000 = 8 × 125.
example : 1236 = 1230 + 6 ∧ 1236 = 1200 + 36 ∧ 1236 = 1000 + 236 := by norm_num
example : 10 = 2 * 5 ∧ 100 = 4 * 25 ∧ 1000 = 8 * 125 := by norm_num

-- The tails: 36 splits four ways; 236 leaves 4 over on 8, the bill's own leftover.
example : 1236 % 100 = 36 ∧ 36 = 4 * 9 := by norm_num
example : 1236 % 1000 = 236 ∧ 236 % 8 = 4 ∧ 1236 % 8 = 4 := by norm_num

-- Sweeping the nines: 1 × 999 + 2 × 99 + 3 × 9 = 1224 = 9 × 136, and 1236 = 1224 + 12.
example : 1 * 999 + 2 * 99 + 3 * 9 = 1224 ∧ 1224 = 9 * 136 ∧ 1236 = 1224 + 12 := by norm_num

-- The digit sum 12 is a multiple of 3 and runs 3 past 9.
example : 12 = 3 * 4 ∧ 12 = 9 + 3 := by norm_num

-- Two digits say no on a $1,136 bill, but 1,136 = 8 × 142.
example : 1136 = 8 * 142 ∧ ¬ 8 ∣ 1136 % 100 := by decide

-- 12 passes the 2 test and the 4 test, but fails 8.
example : 2 ∣ 12 ∧ 4 ∣ 12 ∧ ¬ 8 ∣ 12 := by decide

#print axioms divisibility_rules_read_the_tail_or_the_digit_sum
#print axioms digit_sum_test_works_only_for_three_and_nine
#print axioms eight_needs_three_digits_and_not_two_and_four
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'divisibility_rules_read_the_tail_or_the_digit_sum' depends on axioms: [propext, Classical.choice, Quot.sound]
'digit_sum_test_works_only_for_three_and_nine' depends on axioms: [propext, Classical.choice, Quot.sound]
'eight_needs_three_digits_and_not_two_and_four' depends on axioms: [propext]
```

> [!TIP]
> **Try changing**
> Guess first, then run. The asserts are pinned to this bill, so one will fire.
> - **Make it a $1,232 bill.** Set `BILL` to 1232 and `SUM` to 1 + 2 + 3 + 2. Now 3 and 6 turn to no, and 8 turns to yes. The `WORDS` labels are pinned too: change 6 to 2 and 12 to 8, or ignore them.
> - **Break the 8 rule.** Give 8 the entry `BILL % 100` in `LOOK` — two digits, not three. It still prints no here and every assert passes, right by luck. Point it at a $1,136 bill: `BILL` 1136, `SUM` 1 + 1 + 3 + 6, `NINES` 1 * 999 + 1 * 99 + 3 * 9. The 8 row is the one that fails.

---

## The usual mistake

> [!warning]
> **Using the digit sum for everything.** It works for 3 and 9, nothing else. This bill's digit sum, 12, is a multiple of 4, and 4 does divide the bill, so the wrong method looks right by accident. The 4 test is the last two digits, 36.
>
> - **Mixing 3 with 9.** Digit sum 12 passes for 3 and fails for 9. Read it as a pass for both and you claim nine can split the bill: 1,236 = 9 × 137 + 3.

---

## Where you meet it in real life

- **Splitting a bill.** Whole dollars a head: does one number divide another? [Divides](01-divides.md)
- **Check digits.** A barcode's last digit makes a weighted total land on a multiple of 10 — a rule run backwards: [Barcode check digits](../05-Check%20Digits%2C%20Calendars%20and%20Cycles/01-barcode-check-digit.md).
- **Factoring by hand.** The rules for 2, 3 and 5 strip out the easy primes: [Prime factorisation](07-prime-factorisation.md).

> **Say it back**
> A rule reads a small number — a tail, or the digit sum — and ignores the rest, which is already a multiple of the number being tested. Last digit for 2, 5 and 10; last two for 4; last three for 8. Digit sum for 3 and 9, since every column is one more than a row of 9s. For 6, pass 2 and 3 both.

---

## What this builds on

- [Place value](../../01-Foundations/01-Everyday%20Arithmetic/01-place-value.md): that 1,236 means one thousand, two hundreds, three tens and six ones.
- [The three rearranging laws](../../01-Foundations/01-Everyday%20Arithmetic/05-arithmetic-laws.md): cutting 1,236 into 1200 + 36 without changing it.
- [Divides](01-divides.md): what "divides" means, and that a multiple of 9 is a multiple of 3.

## Where this goes next

- [Barcode check digits](../05-Check%20Digits%2C%20Calendars%20and%20Cycles/01-barcode-check-digit.md): the same digit-reading, used to build a number that must pass a test for 10.

Left open: 236 leaves 4 over on 8 and 12 leaves 3 over on 9, the same leftovers as the bill. Can you work with the leftovers alone? That is [Congruence](../03-Clock%20Arithmetic/01-congruence-mod-n.md).

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Burton, David M. *Elementary Number Theory*, 7th ed. McGraw-Hill, 2011. [Publisher page](https://www.mheducation.com/highered/product/elementary-number-theory-burton/M9780073383149.html). Chapter 4 proves them.
- Knuth, Donald E. *The Art of Computer Programming, Volume 2*, 3rd ed. Addison-Wesley, 1997. [Publisher page](https://www.informit.com/store/art-of-computer-programming-volume-2-seminumerical-9780201896848). Section 4.1: the columns these rules read.
- Conway, John H., and Richard K. Guy. *The Book of Numbers*. Springer, 1996. [doi:10.1007/978-1-4612-4072-3](https://doi.org/10.1007/978-1-4612-4072-3). How numbers are written.
