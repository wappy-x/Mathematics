# Division with a remainder: the quotient and the leftover are unique, and the leftover is smaller than the divisor

[Syllabus](../../../SYLLABUS.md) → [Number theory](../README.md) → [Divisibility and Primes](../README.md#s01) → Division with a remainder

---

## General Overview

Your birthday is 6 September. In 2026 it falls on a Sunday. In 2027, a Monday.

A year is 365 days. A week is 7 days. Pack whole weeks into the year and 52 fit, using 364 days. One day is left over. That spare day is the shift.

Then a 29 February turns up. September 2027 to September 2028 runs 366 days: still 52 whole weeks, now 2 days over. The birthday jumps two, Monday to Wednesday.

Splitting a count into whole helpings plus what will not fill another is **division with a remainder**. The **quotient** counts the whole helpings. The **remainder** is the leftover. The **divisor** is one helping's size, 7 days here.

The count is a whole number, 0 or more. The divisor is a whole number, 1 or more.

**Every division has exactly one answer of this shape: so many whole copies of the divisor, plus a leftover too small to make one more copy.**

**What kind of fact this is:** a theorem, proved on this card in Why it works: a leftover under the divisor always exists, and only one does.

Textbooks call this the division algorithm, or the division theorem. It is one step, not [Euclid's algorithm](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/03-euclidean-algorithm.md), which repeats it.

### The picture: where the birthday has drifted to

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "A 6 September birthday, drifting through the week"
    x-axis "Year" [2026, 2027, 2028, 2029]
    y-axis "Weekdays later than it fell in 2026" 0 --> 5
    line [0, 1, 3, 4]
```

The line is how many weekdays later the birthday falls than in 2026. Ordinary years lift it one, the leftover day. The step into 2028 is two: a 29 February.

---

## The formula

The year, written out, is the statement:

**365 = 52 × 7 + 1, and 1 is smaller than 7**

**Read it aloud:** 365 days is 52 whole weeks plus 1 day that cannot fill another week.

The leap year, same shape:

**366 = 52 × 7 + 2, and 2 is smaller than 7**

In general: **the number you started with = the quotient × the divisor + the remainder, where the remainder is at least 0 and smaller than the divisor.**

Later cards write it short: b = q × a + r, with r below a — b what you started with, a the divisor, q the quotient, r the remainder. Books often swap the letters; the shape is what matters.

| Piece | Plain meaning | In our example |
| --- | --- | --- |
| the number you started with, b | the count being split | 365 days |
| the divisor, a | the size of one helping, 1 or more | 7 days, a week |
| the quotient, q | how many whole helpings fit | 52 weeks |
| the remainder, r | what is left, too small for another helping | 1 day |
| the rule on r | at least 0, under the divisor | 1 is under 7 |

### When it holds

- **The divisor is 1 or more.** Take away a divisor of 0 and the pile never shrinks, so the long way never stops.
- **The leftover is under the divisor.** Drop this rule and the answer is no longer one: 51 × 7 + 8 is also 365.
- **Whole helpings only.** Allow part of a week and nothing is left over: the spare day becomes a fraction of a week.
- **A count of 0 or more.** Count days back before 2026 and Python and Rust disagree on the leftover. [Congruence](../03-Clock%20Arithmetic/01-congruence-mod-n.md) settles which one to keep.

---

## Why it works

### Take a week away until you cannot

Start with 365 days. Take 7 away: 358 left, one week counted. Again: 351, two weeks. The pile drops by 7 each time, so it cannot drop forever. It stops after 52 goes, with 1 day standing.

A pencil can do it, and it always ends. The code does this too, by subtraction.

### The leftover has to be smaller than the divisor

If 7 or more were left, another week would still fit, so you would not have stopped. A leftover of 8 is an unfinished job, not an answer: 365 = 51 × 7 + 8 is true arithmetic in the wrong shape.

### There is only one answer

Two people split 365 days into weeks plus a leftover and disagree. Different week counts differ by a whole week at least, so their leftovers must differ by 7 or more. But both leftovers sit between 0 and 6. So they cannot disagree: one quotient, one remainder. That is what makes it safe to say *the* remainder.

The code checks that bluntly: it tries every week count from 0 to 99 and keeps the ones whose leftover lands under 7. One survives.

---

## Worked numbers, by hand

The birthday, 2026 to 2029. A birthday after February sees the 366-day stretch in the year ending in the leap year.

| Step | Arithmetic | Value |
| --- | --- | --- |
| whole weeks in a year | 52 × 7 | 364 |
| days over, ordinary year | 365 − 364 | 1 |
| days over, leap year | 366 − 364 | 2 |
| 2026 to 2027, ordinary | Sunday + 1 | Monday |
| 2027 to 2028, leap | Monday + 2 | Wednesday |
| 2028 to 2029, ordinary | Wednesday + 1 | **Thursday** |

Three years, four weekdays of drift.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Calling 52 weeks the whole year | 364 days | The spare day does the work |
| Stopping at 51 weeks, 8 days over | 51 weeks | 8 is not under 7, so a week still fits |
| Giving every year 365 days | Wednesday in 2029 | A leap year shifts it two, not one |

The code prints all three.

---

## Code, from first principles, and it actually runs

Nothing is imported. The year is divided the plain way, then again by taking 7 away over and over. Every week count is tried, to show one pair fits. The birthday walks to 2029.

### Python

```python
# Division with a remainder -- the check behind the card.  Nothing is imported.
# A 365-day year measured in 7-day weeks, then a 366-day leap year, then the
# weekday a 6 September birthday lands on, 2026 to 2029.
DAYS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

def strip(total, size):            # the long way: take 7 away until under 7 is left
    q = 0
    while total >= size:
        total, q = total - size, q + 1
    return q, total

def row(name, total, q, r):
    print(f"{name:<30}{total:>7}{q:>7}{r:>11}")

print(f"{'what':<30}{'total':>7}{'weeks':>7}{'days over':>11}")
row("ordinary year", 365, 365 // 7, 365 % 7)   # // whole weeks, % days over
row("leap year", 366, 366 // 7, 366 % 7)
row("by taking 7 away over and over", 365, *strip(365, 7))
pairs = [(q, 365 - 7 * q) for q in range(100) if 0 <= 365 - 7 * q < 7]
print(f"quotient-and-leftover pairs with the leftover under 7: {len(pairs)}")
moved = [0]
for length in (365, 366, 365):
    moved.append((moved[-1] + length % 7) % 7)
print("6 September: " + ", ".join(f"{y} {DAYS[m]}" for y, m in zip(range(2026, 2030), moved)))
print("weekdays moved since 2026: " + ", then ".join(str(m) for m in moved))
print(f"the three mistakes come out at {52 * 7} days, 51 weeks with {365 - 51 * 7} days over, and {DAYS[3]}")
assert (365 // 7, 365 % 7) == (52, 1) and 52 * 7 + 1 == 365
assert (366 // 7, 366 % 7) == (52, 2) and strip(365, 7) == (52, 1)
assert pairs == [(52, 1)] and moved == [0, 1, 3, 4]
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
what                            total  weeks  days over
ordinary year                     365     52          1
leap year                         366     52          2
by taking 7 away over and over    365     52          1
quotient-and-leftover pairs with the leftover under 7: 1
6 September: 2026 Sunday, 2027 Monday, 2028 Wednesday, 2029 Thursday
weekdays moved since 2026: 0, then 1, then 3, then 4
the three mistakes come out at 364 days, 51 weeks with 8 days over, and Wednesday
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Division with a remainder -- the same check as division_with_remainder_check.py,
// in Rust.  No crates.  A 365-day year measured in 7-day weeks, then a 366-day
// leap year, then a 6 September birthday's weekday, 2026 to 2029.
const DAYS: [&str; 7] = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

fn strip(total: i64, size: i64) -> (i64, i64) {   // the long way: take 7 away until under 7 is left
    let (mut t, mut q) = (total, 0);
    while t >= size { t -= size; q += 1; }
    (q, t)
}
fn row(name: &str, total: i64, q: i64, r: i64) {
    println!("{:<30}{:>7}{:>7}{:>11}", name, total, q, r);
}

fn main() {
    println!("{:<30}{:>7}{:>7}{:>11}", "what", "total", "weeks", "days over");
    row("ordinary year", 365, 365 / 7, 365 % 7);   // / whole weeks, % days over
    row("leap year", 366, 366 / 7, 366 % 7);
    let (q, r) = strip(365, 7);
    row("by taking 7 away over and over", 365, q, r);
    let mut pairs: Vec<(i64, i64)> = Vec::new();
    for k in 0..100 { if 365 - 7 * k >= 0 && 365 - 7 * k < 7 { pairs.push((k, 365 - 7 * k)); } }
    println!("quotient-and-leftover pairs with the leftover under 7: {}", pairs.len());
    let mut moved: Vec<usize> = vec![0];
    for length in [365usize, 366, 365] { moved.push((moved[moved.len() - 1] + length % 7) % 7); }
    let mut line = String::from("6 September: ");
    for (i, m) in moved.iter().enumerate() {
        if i > 0 { line.push_str(", "); }
        line.push_str(&format!("{} {}", 2026 + i, DAYS[*m]));
    }
    println!("{}", line);
    let steps: Vec<String> = moved.iter().map(|m| m.to_string()).collect();
    println!("weekdays moved since 2026: {}", steps.join(", then "));
    println!("the three mistakes come out at {} days, 51 weeks with {} days over, and {}",
             52 * 7, 365 - 51 * 7, DAYS[3]);
    assert!((365 / 7, 365 % 7) == (52, 1) && 52 * 7 + 1 == 365);
    assert!((366 / 7, 366 % 7) == (52, 2) && strip(365, 7) == (52, 1));
    assert!(pairs == vec![(52, 1)] && moved == vec![0, 1, 3, 4]);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
what                            total  weeks  days over
ordinary year                     365     52          1
leap year                         366     52          2
by taking 7 away over and over    365     52          1
quotient-and-leftover pairs with the leftover under 7: 1
6 September: 2026 Sunday, 2027 Monday, 2028 Wednesday, 2029 Thursday
weekdays moved since 2026: 0, then 1, then 3, then 4
the three mistakes come out at 364 days, 51 weeks with 8 days over, and Wednesday
ALL CHECKS PASS
```

The two outputs match line for line: whole days, nothing to round.

### Lean

Lean proves the theorem for every count of 0 or more and every divisor of 1 or more, not just 365 and 7.

- Exactly one quotient and one remainder fit, with the remainder under the divisor.
- That one pair is the whole weeks and days over that the code's // and % give.
- Drop the rule that the leftover is under the divisor, and two different answers fit once the count reaches the divisor.
- The card's numbers check out: 365 and 366 days, 51 weeks with 8 over, the birthday drift, 365 split by 5, and the clock.

The printed table, the taking-7-away loop and the weekday names stay with the Python and Rust checks.

<details>
<summary>The Lean proof, 74 lines</summary>

```lean
-- Division with a remainder: for a whole number b and a divisor a of 1 or more, exactly one pair of whole numbers q and r gives b = q × a + r with r smaller than a, that pair is b / a and b % a, and without the rule r < a the answer is no longer one.
import Mathlib.Basic.ExistsUnique
import Mathlib.Data.Nat.Init

theorem aux_div_mod_unique (b a q r : ℕ) (ha : 1 ≤ a)
    (h : b = q * a + r) (hr : r < a) :
    q = b / a ∧ r = b % a := by
  have hpos : 0 < a := ha
  have hq : b / a = q := by
    rw [h, Nat.add_comm, Nat.add_mul_div_right _ _ hpos, Nat.div_eq_of_lt hr, Nat.zero_add]
  have hm := Nat.div_add_mod' b a
  refine ⟨hq.symm, ?_⟩
  rw [hq] at hm
  omega

#print axioms aux_div_mod_unique

/-- Division with a remainder. Take a whole number b (0 or more) and a divisor a (1 or more).
There is exactly one pair of whole numbers, a quotient q and a remainder r, with
b = q × a + r and r smaller than a. -/
theorem quotient_and_remainder_exist_and_are_unique (b a : ℕ) (ha : 1 ≤ a) :
    ∃! p : ℕ × ℕ, b = p.1 * a + p.2 ∧ p.2 < a := by
  refine ⟨(b / a, b % a), ⟨(Nat.div_add_mod' b a).symm, Nat.mod_lt _ ha⟩, ?_⟩
  rintro ⟨q, r⟩ ⟨h, hr⟩
  obtain ⟨h1, h2⟩ := aux_div_mod_unique b a q r ha h hr
  simp only [Prod.mk.injEq]
  exact ⟨h1, h2⟩

/-- The one pair is what whole-number division gives: if b = q × a + r with r smaller than a,
then q is b / a (whole copies, Python's //) and r is b % a (the leftover, Python's %). -/
theorem quotient_and_remainder_are_div_and_mod (b a q r : ℕ) (ha : 1 ≤ a)
    (h : b = q * a + r) (hr : r < a) :
    q = b / a ∧ r = b % a := by
  exact aux_div_mod_unique b a q r ha h hr

/-- Drop the rule that the leftover is under the divisor and the answer is no longer one:
whenever b is at least a, two different pairs (q, r) give b = q × a + r. -/
theorem without_leftover_rule_answer_is_not_unique (b a : ℕ) (ha : 1 ≤ a) (hb : a ≤ b) :
    ∃ p p' : ℕ × ℕ, p ≠ p' ∧ b = p.1 * a + p.2 ∧ b = p'.1 * a + p'.2 := by
  have hpos : 0 < a := ha
  have hq : 1 ≤ b / a := (Nat.le_div_iff_mul_le hpos).2 (by omega)
  obtain ⟨k, hk⟩ : ∃ k, b / a = k + 1 := ⟨b / a - 1, by omega⟩
  have hm := Nat.div_add_mod' b a
  rw [hk] at hm
  refine ⟨(k + 1, b % a), (k, b % a + a), ?_, ?_, ?_⟩
  · simp
  · simp only; omega
  · simp only; rw [Nat.add_mul] at hm; omega

-- An ordinary year: 365 = 52 × 7 + 1, and 1 is smaller than 7.
example : 365 = 52 * 7 + 1 ∧ 1 < 7 := by decide
-- A leap year: 366 = 52 × 7 + 2, and 2 is smaller than 7.
example : 366 = 52 * 7 + 2 ∧ 2 < 7 := by decide
-- The code's // and %: 52 weeks with 1 day over, then 52 weeks with 2 days over.
example : 365 / 7 = 52 ∧ 365 % 7 = 1 ∧ 366 / 7 = 52 ∧ 366 % 7 = 2 := by decide
-- Whole weeks in a year, and the days over.
example : 52 * 7 = 364 ∧ 365 - 364 = 1 ∧ 366 - 364 = 2 := by decide
-- Stopping at 51 weeks: 365 = 51 × 7 + 8 is true arithmetic, but 8 is not under 7.
example : 365 = 51 * 7 + 8 ∧ ¬ (8 < 7) := by decide
-- Trying every week count from 0 to 99: only 52 leaves a leftover under 7, and that leftover is 1.
example : (List.range 100).filter (fun q => 7 * q ≤ 365 ∧ 365 - 7 * q < 7) = [52] ∧
    365 - 7 * 52 = 1 := by decide
-- The birthday drifts 0, then 1, then 3, then 4 weekdays (Sunday, Monday, Wednesday, Thursday).
example : (0 + 365 % 7) % 7 = 1 ∧ (1 + 366 % 7) % 7 = 3 ∧ (3 + 365 % 7) % 7 = 4 := by decide
-- Giving every year 365 days lands on 3 (Wednesday) in 2029, not 4.
example : (0 + 3 * (365 % 7)) % 7 = 3 := by decide
-- Taking 5 away instead of 7: a quotient of 73, nothing over.
example : 365 / 5 = 73 ∧ 365 % 5 = 0 ∧ 365 = 73 * 5 + 0 := by decide
-- Clocks: 100 minutes is 1 hour and 40 minutes.
example : 100 / 60 = 1 ∧ 100 % 60 = 40 := by decide

#print axioms quotient_and_remainder_exist_and_are_unique
#print axioms quotient_and_remainder_are_div_and_mod
#print axioms without_leftover_rule_answer_is_not_unique
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'aux_div_mod_unique' depends on axioms: [propext, Quot.sound]
'quotient_and_remainder_exist_and_are_unique' depends on axioms: [propext, Quot.sound]
'quotient_and_remainder_are_div_and_mod' depends on axioms: [propext, Quot.sound]
'without_leftover_rule_answer_is_not_unique' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts are pinned to the house numbers.
> - **Give every year 366 days.** Change the three year lengths to 366, 366, 366. The birthday moves two weekdays a year, and the last assert fires.
> - **Take 5 away instead of 7.** Call `strip(365, 5)`: a quotient of 73, nothing over, because 5 goes into 365 exactly. A remainder of 0 is the [Divides](01-divides.md) case. This one runs clean.

---

## The usual mistake

> [!warning]
> **Reading the leftover as a piece of a helping.** A calculator dividing 365 by 7 runs past the decimal point; that tail is a fraction of a week. This card wants whole things: 52 whole weeks and 1 whole day.
>
> - Letting the leftover reach the divisor: 51 weeks with 8 days over is not an answer.
> - Swapping the words: the quotient counts the whole copies, the remainder what did not fill one.
> - Dividing a negative count. Which way the leftover goes is a separate rule, in [Congruence](../03-Clock%20Arithmetic/01-congruence-mod-n.md).

---

## Where you meet it in real life

- **Calendars.** Any day-of-the-week question is a leftover after dividing by 7: [Day of the week for any date](../05-Check%20Digits%2C%20Calendars%20and%20Cycles/03-day-of-the-week.md).
- **Clocks.** 100 minutes is 1 hour and 40 minutes: divide by 60, keep the leftover.
- **Loading a van.** 365 chairs into vans holding 7 needs 52 full vans plus one carrying a single chair. The leftover still costs a van.

> **Say it back**
> Take a whole count and a divisor, 1 or more. Fit in as many whole copies of the divisor as you can: that is the quotient. What is left is the remainder, smaller than the divisor — otherwise another copy would fit. Only one such pair works. A year is 52 weeks and 1 day, so a birthday walks one weekday a year, two across a 29 February.

---

## What this builds on

- [Multiplying and dividing](../../01-Foundations/01-Everyday%20Arithmetic/03-multiplying-and-dividing.md): whole-number division, and the 52 × 7 that dividing 365 by 7 undoes.
- [Divides](01-divides.md): the case where nothing is left over. This card covers the rest.

## Where this goes next

- [Primes and composites](05-primes-and-composites.md): testing for a prime asks for remainders, caring only whether one is 0.
- [Euclid's algorithm](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/03-euclidean-algorithm.md): this step run again on each leftover, to find the largest number dividing two numbers.
- [Congruence](../03-Clock%20Arithmetic/01-congruence-mod-n.md): keeping the remainder and throwing the quotient away, negative counts included.
- [Day of the week for any date](../05-Check%20Digits%2C%20Calendars%20and%20Cycles/03-day-of-the-week.md): this drift, built into a rule for any date.

The question this card leaves open: what is the remainder when the count is negative?

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Euclid. *Elements*, Book VII, Propositions 1 and 2, in David E. Joyce's edition, Clark University. [Book VII](https://mathcs.clarku.edu/~djoyce/elements/bookVII/bookVII.html). The oldest written form of it.
- Graham, Ronald L., Donald E. Knuth and Oren Patashnik. *Concrete Mathematics*, 2nd ed. Addison-Wesley, 1994. [Publisher page](https://www.informit.com/store/concrete-mathematics-a-foundation-for-computer-science-9780201558029). Chapter 3, quotients and remainders, negative counts included.
- United States Naval Observatory. *Introduction to Calendars*. [aa.usno.navy.mil](https://aa.usno.navy.mil/faq/calendars). Where the 365 and 366 come from.
