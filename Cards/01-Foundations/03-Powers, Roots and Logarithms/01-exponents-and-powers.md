# Exponents: repeated multiplication, and why zero and negative powers make sense

[Syllabus](../../../SYLLABUS.md) → [Foundations](../README.md) → [Powers, Roots and Logarithms](../README.md#s03) → Exponents

---

## General Overview

A chain message starts with one person. She sends it to 3 friends. Each of those sends it to 3 more. Nobody gets it twice.

Round 1 reaches 3 people, round 2 reaches 9, round 5 reaches **243**. With the woman who started it: 1 + 3 + 9 + 27 + 81 + 243 = **364** people hold the message.

Writing 3 × 3 × 3 × 3 × 3 gets old fast, so it has a shorthand: **3^5**, said "three to the fifth" — the ^ means the 5 sits raised. The 3 is the **base**, the number doing the multiplying. The 5 is the **exponent**, how many copies of the base are multiplied. The answer, 243, is the **power**.

**An exponent counts copies of the base. Once counts can be added and taken away, an exponent of zero and a negative exponent each have only one possible meaning.**

**What kind of fact this is:** a definition, then three rules that follow from counting, shown in Why it works. The meanings of 3^0 and 3^-3 are the only ones that keep those rules true.

### The picture: five rounds

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "The chain message, one person telling 3 friends a round"
    x-axis "Round" [0, 1, 2, 3, 4, 5]
    y-axis "People" 0 --> 400
    line [1, 3, 9, 27, 81, 243]
    line [1, 4, 13, 40, 121, 364]
```

Lower line: new people that round, ending at 243. Upper line: everyone holding it, ending at 364. Both crawl along the bottom for three rounds, then shoot up.

---

## The formula

The written-out multiplication **is** the definition:

**3^5 = 3 × 3 × 3 × 3 × 3 = 243**

**Read it aloud:** three to the fifth is five 3s multiplied together, and that is 243.

Three moves do the rest, on our numbers:

- **3^2 × 3^3 = 3^5.** Multiplying powers of the same base adds the exponents.
- **3^5 ÷ 3^2 = 3^3.** Dividing subtracts them.
- **(3^2)^3 = 3^6.** A power of a power multiplies them.

| Piece | Plain meaning | In our example |
| --- | --- | --- |
| the base | the number being multiplied | 3, the friends each tells |
| the exponent | how many copies of the base are multiplied | 5, the rounds |
| the power | the answer | 243, reached in round 5 |
| an exponent of 0 | no copies at all, which is 1 | round 0, the woman who started it |
| a negative exponent | 1 divided by the power | 3^-3 is 1 ÷ 27 |

### When it holds

- **The same base on both sides.** 3^2 × 3^3 joins into 3^5 because every copy is a 3. With two different bases there is no single count to add, and the adding rule fails.
- **An exponent that is a whole number or its negative.** Half a round is not a count, so this card gives it no meaning; [Roots](03-roots-and-fractional-exponents.md) does.
- **A base that is not 0.** 3^0 = 1 and 3^-3 = 1/27 come from dividing by the base. You cannot divide by 0, so 0^0 and negative powers of 0 get no meaning.

---

## Why it works

### The exponent is a count, so it behaves like one

3^2 × 3^3 is two 3s times three 3s. Push them into one line: 3 × 3 × 3 × 3 × 3. Five 3s, so it is 3^5. The 2 + 3 = 5 is not a rule you learned; it is a count you just did.

In the chain: round 2 has reached 9 people. Let each of those 9 run 3 more rounds and each grows to 27. 9 × 27 = 243, which is round 5.

Dividing takes copies away. 3^5 ÷ 3^2 is five 3s over two 3s; cancel two pairs and three 3s are left, which is 27. Round 5 is 27 times round 2, three rounds apart.

Stacking is that count again. (3^2)^3 is three copies of 3 × 3: six 3s, so 3^6, which is 729.

### Zero copies has to be 1

Compare round 5 with itself: 243 ÷ 243 = 1. The subtraction rule says that division is 3 to the (5 − 5), which is 3^0. Two answers to one question, so **3^0 = 1**.

The ladder says it too. Read the rounds backwards: 243, 81, 27, 9, 3. Every step divides by 3. One more step and 3 ÷ 3 = 1 — round 0, the woman who started it. Zero is where the ladder was already going.

### Going below zero flips the number over

The other way. Round 2 against round 5: 9 ÷ 243 = 1/27. The subtraction rule says it is 3 to the (2 − 5), which is 3^-3. So **3^-3 = 1 ÷ 27**: a negative exponent means 1 divided by the matching power.

It does not make the answer negative; it flips the number into a fraction.

<details>
<summary>Why 0 is the one base left out here</summary>

0^3 is fine: it is 0. The other end is the problem. 3^0 was forced by dividing 3 by 3, and with a base of 0 you can never divide — dividing by 0 has no answer. Nothing forces an answer, so 0^0 is left undefined.

</details>

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| round 1 | 3 | 3 |
| round 2 | 3 × 3 | 9 |
| round 5, written 3^5 | 3 × 3 × 3 × 3 × 3 | **243** |
| everyone holding it | 1 + 3 + 9 + 27 + 81 + 243 | **364** |
| round 5, the other road | 3^2 × 3^3, or 9 × 27 | 243 |
| a power of a power, (3^2)^3 | 9 × 9 × 9, or 3^6 | 729 |
| round 5 ÷ round 2 | 243 ÷ 9, or 3^3 | 27 |
| round 5 ÷ round 5 | 243 ÷ 243, or 3^0 | 1 |
| round 2 ÷ round 5 | 9 ÷ 243, or 3^-3 | 1/27 |

One person, five rounds: 364 people hold the message.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Multiplying the exponents in 3^2 × 3^3, not adding | 729 | That is (3^2)^3, a different question |
| Reading 3^5 as 3 × 5 | 15 | The 5 counts copies of the 3 |
| Reading 3^-3 as a negative number | −27 | It flips instead: 1/27 |

The code below prints all three, and every number on this card.

---

## Code, from first principles, and it actually runs

Nothing is imported. Round 5 is built one multiplication at a time, then reached again by 3^2 × 3^3 and by (3^2)^3. Then the ratios, including 3^0 and 3^-3.

### Python

```python
# Exponents -- the check behind the card.  Nothing imported.  A chain message:
# 3 friends each, five rounds; then 243 by a second road, and the ladder of ratios.
def power(base, rounds):            # 3, 5 -> 3 x 3 x 3 x 3 x 3 -> 243
    result = 1
    for _ in range(rounds):
        result = result * base
    return result

def line(name, value):
    print(f"{name:<44}{value:>6}")

new = [power(3, r) for r in range(6)]
running = [sum(new[:r + 1]) for r in range(6)]
flip = new[5] // new[2]             # 9 x 27 = 243, so 9 / 243 is 1/27
print(f"{'round':<22}" + "".join(f"{v:>5}" for v in range(6)))
print(f"{'new people this round':<22}" + "".join(f"{v:>5}" for v in new))
print(f"{'everyone who has it':<22}" + "".join(f"{v:>5}" for v in running))
line("3 x 3 x 3 x 3 x 3 = 3^5", new[5])
line("3^2 x 3^3, the two halves multiplied", power(3, 2) * power(3, 3))
line("(3^2)^3 = 3^6, a power of a power", power(power(3, 2), 3))
line("3^5 / 3^2 = 3^3, five rounds against two", new[5] // new[2])
line("3^5 / 3^5 = 3^0, five rounds against five", new[5] // new[5])
line("3^2 / 3^5 = 3^-3, two rounds against five", f"1/{flip}")
print(f"the three mistakes come out at {power(3, 6)}, {3 * 5} and {-power(3, 3)}")

assert new[5] == 243 and power(3, 2) * power(3, 3) == new[5]
assert running[5] == 1 + 3 + 9 + 27 + 81 + 243 and new[0] == 1
assert new[2] == 9 and flip == 27 and new[2] * flip == new[5] and new[5] // new[5] == 1
assert power(power(3, 2), 3) == power(3, 6) == 729
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
round                     0    1    2    3    4    5
new people this round     1    3    9   27   81  243
everyone who has it       1    4   13   40  121  364
3 x 3 x 3 x 3 x 3 = 3^5                        243
3^2 x 3^3, the two halves multiplied           243
(3^2)^3 = 3^6, a power of a power              729
3^5 / 3^2 = 3^3, five rounds against two        27
3^5 / 3^5 = 3^0, five rounds against five        1
3^2 / 3^5 = 3^-3, two rounds against five     1/27
the three mistakes come out at 729, 15 and -27
ALL CHECKS PASS
```

### Rust

Same numbers, built with `rustc --edition 2021 -O`.

```rust
// Exponents -- the same check as the Python, in Rust.  No crates.  A chain
// message: 3 friends each, five rounds; then 243 by a second road, and the ratios.
fn power(base: i64, rounds: u32) -> i64 {   // 3, 5 -> 3 x 3 x 3 x 3 x 3 -> 243
    let mut result = 1i64;
    for _ in 0..rounds { result = result * base; }
    result
}

fn line(name: &str, value: &str) { println!("{:<44}{:>6}", name, value); }

fn main() {
    let new: Vec<i64> = (0..6).map(|r| power(3, r)).collect();
    let mut running: Vec<i64> = Vec::new();
    let mut total = 0i64;
    for n in &new { total += n; running.push(total); }
    let flip = new[5] / new[2];             // 9 x 27 = 243, so 9 / 243 is 1/27
    let mut head = format!("{:<22}", "round");
    for v in 0..6 { head.push_str(&format!("{:>5}", v)); }
    println!("{}", head);
    let mut fresh = format!("{:<22}", "new people this round");
    for v in &new { fresh.push_str(&format!("{:>5}", v)); }
    println!("{}", fresh);
    let mut all = format!("{:<22}", "everyone who has it");
    for v in &running { all.push_str(&format!("{:>5}", v)); }
    println!("{}", all);
    line("3 x 3 x 3 x 3 x 3 = 3^5", &new[5].to_string());
    line("3^2 x 3^3, the two halves multiplied", &(power(3, 2) * power(3, 3)).to_string());
    line("(3^2)^3 = 3^6, a power of a power", &power(power(3, 2), 3).to_string());
    line("3^5 / 3^2 = 3^3, five rounds against two", &(new[5] / new[2]).to_string());
    line("3^5 / 3^5 = 3^0, five rounds against five", &(new[5] / new[5]).to_string());
    line("3^2 / 3^5 = 3^-3, two rounds against five", &format!("1/{}", flip));
    println!("the three mistakes come out at {}, {} and {}", power(3, 6), 3 * 5, -power(3, 3));

    assert!(new[5] == 243 && power(3, 2) * power(3, 3) == new[5]);
    assert!(running[5] == 1 + 3 + 9 + 27 + 81 + 243 && new[0] == 1);
    assert!(new[2] == 9 && flip == 27 && new[2] * flip == new[5] && new[5] / new[5] == 1);
    assert!(power(power(3, 2), 3) == power(3, 6) && power(3, 6) == 729);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
round                     0    1    2    3    4    5
new people this round     1    3    9   27   81  243
everyone who has it       1    4   13   40  121  364
3 x 3 x 3 x 3 x 3 = 3^5                        243
3^2 x 3^3, the two halves multiplied           243
(3^2)^3 = 3^6, a power of a power              729
3^5 / 3^2 = 3^3, five rounds against two        27
3^5 / 3^5 = 3^0, five rounds against five        1
3^2 / 3^5 = 3^-3, two rounds against five     1/27
the three mistakes come out at 729, 15 and -27
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the rules for every base that is not 0, and every exponent that is a whole number or its negative.

- Multiplying powers of the same base adds the exponents. Dividing subtracts them. A power of a power multiplies them.
- If an exponent of 1 or more counts copies and the subtraction rule holds, an exponent of 0 must give 1.
- Under the same rule, a negative exponent must mean 1 divided by the matching power. So 3^-3 is 1/27.
- Every number on the card comes out exactly: the rounds, the 364 total, the ratios and the three mistakes.

Building each power one multiplication at a time, and printing the table, are left to the Python and Rust checks.

```lean
-- Exponents: for a nonzero base and whole-number or negative exponents, multiplying powers adds the exponents, dividing subtracts them and a power of a power multiplies them; the subtraction rule forces a zero exponent to give 1 and a negative exponent to give 1 over the matching power; and the card's chain-message numbers come out exactly as it says.
import Mathlib.Algebra.GroupWithZero.Units.Basic
import Mathlib.Algebra.Field.Basic
import Mathlib.Algebra.Field.Rat
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic.NormNum

/-- The three rules of exponents. Take a base `a` that is not 0 and exponents `m`, `n` that
are whole numbers or their negatives. Multiplying powers of the same base adds the exponents,
`a^m × a^n = a^(m + n)`; dividing subtracts them, `a^m ÷ a^n = a^(m − n)`; and a power of a
power multiplies them, `(a^m)^n = a^(m × n)`. -/
theorem exponent_rules_add_subtract_multiply {K : Type*} [Field K] (a : K) (ha : a ≠ 0)
    (m n : ℤ) :
    a ^ m * a ^ n = a ^ (m + n) ∧ a ^ m / a ^ n = a ^ (m - n) ∧ (a ^ m) ^ n = a ^ (m * n) := by
  refine ⟨(zpow_add₀ ha m n).symm, (zpow_sub₀ ha m n).symm, (zpow_mul a m n).symm⟩

/-- Zero and negative powers have only one possible meaning. Take a base `a` that is not 0,
and any way `f` of giving a value to every whole-number or negative exponent. Suppose it agrees
with repeated multiplication for every count of 1 or more (`f n = a × a × ⋯ × a`, `n` copies),
and keeps the subtraction rule, `f (m − n) = f m ÷ f n`, for all whole numbers `m`, `n`. Then
the zero power must be 1, and the power `−n` must be 1 divided by the matching power `a^n`. -/
theorem zero_and_negative_powers_are_forced {K : Type*} [Field K] (a : K) (ha : a ≠ 0)
    (f : ℤ → K)
    (h_count : ∀ n : ℕ, 0 < n → f n = a ^ n)
    (h_sub : ∀ m n : ℕ, f ((m : ℤ) - n) = f m / f n) :
    f 0 = 1 ∧ ∀ n : ℕ, f (-(n : ℤ)) = 1 / a ^ n := by
  have h1 : f 1 = a := by simpa using h_count 1 (by norm_num)
  have h0 : f 0 = 1 := by
    have := h_sub 1 1
    simp only [Nat.cast_one, sub_self] at this
    rw [this, h1]
    exact div_self ha
  refine ⟨h0, fun n => ?_⟩
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp [h0]
  · have := h_sub 0 n
    simp only [Nat.cast_zero, zero_sub] at this
    rw [this, h0, h_count n hn]

-- The definition: 3^5 is five 3s multiplied together, round 5 of the chain.
example : (3 : ℚ) ^ 5 = 3 * 3 * 3 * 3 * 3 := by norm_num
example : (3 : ℚ) ^ 5 = 243 := by norm_num
example : (3 : ℚ) ^ 1 = 3 := by norm_num
example : (3 : ℚ) ^ 2 = 3 * 3 := by norm_num
example : (3 : ℚ) ^ 2 = 9 := by norm_num
-- The six rounds, and everyone holding the message.
example : (List.range 6).map (fun r => 3 ^ r) = [1, 3, 9, 27, 81, 243] := by decide
example : (1 : ℕ) + 3 + 9 + 27 + 81 + 243 = 364 := by norm_num
example : ∑ r ∈ Finset.range 6, (3 : ℕ) ^ r = 364 := by decide
example : (List.range 6).map (fun r => ∑ i ∈ Finset.range (r + 1), (3 : ℕ) ^ i) =
    [1, 4, 13, 40, 121, 364] := by decide
-- Round 5 by the other road: 3^2 × 3^3, or 9 × 27.
example : (3 : ℚ) ^ 2 * 3 ^ 3 = 3 ^ 5 := by norm_num
example : (9 : ℚ) * 27 = 243 := by norm_num
-- A power of a power: (3^2)^3 is 9 × 9 × 9, or 3^6.
example : ((3 : ℚ) ^ 2) ^ 3 = 3 ^ 6 := by norm_num
example : (9 : ℚ) * 9 * 9 = 729 := by norm_num
example : (3 : ℚ) ^ 6 = 729 := by norm_num
-- The ratios: 3^5 ÷ 3^2, 3^5 ÷ 3^5 and 3^2 ÷ 3^5, as plain fractions and as integer powers.
example : (243 : ℚ) / 9 = 27 := by norm_num
example : (3 : ℚ) ^ (5 : ℤ) / 3 ^ (2 : ℤ) = 3 ^ (3 : ℤ) := by norm_num
example : (243 : ℚ) / 243 = 1 := by norm_num
example : (3 : ℚ) ^ (0 : ℤ) = 1 := by norm_num
example : (9 : ℚ) / 243 = 1 / 27 := by norm_num
example : (3 : ℚ) ^ (-3 : ℤ) = 1 / 27 := by norm_num
example : (3 : ℚ) ^ (2 : ℤ) / 3 ^ (5 : ℤ) = 3 ^ (-3 : ℤ) := by norm_num
-- The ladder read backwards ends at round 0: 3 ÷ 3 = 1.
example : (3 : ℚ) / 3 = 1 := by norm_num
-- The three mistakes come out at 729, 15 and −27, none of them the right answer.
example : (3 : ℚ) ^ 6 = 729 ∧ (3 : ℚ) ^ 6 ≠ 3 ^ 2 * 3 ^ 3 := by norm_num
example : (3 : ℚ) * 5 = 15 ∧ (3 : ℚ) * 5 ≠ 3 ^ 5 := by norm_num
example : -((3 : ℚ) ^ 3) = -27 ∧ -((3 : ℚ) ^ 3) ≠ 3 ^ (-3 : ℤ) := by norm_num
-- Different bases: 3^2 × 5^2 is not 15^4.
example : (3 : ℚ) ^ 2 * 5 ^ 2 ≠ 15 ^ 4 := by norm_num
-- Try changing: a sixth round adds 729, not another 243.
example : (3 : ℕ) ^ 6 = 729 := by norm_num

#print axioms exponent_rules_add_subtract_multiply
#print axioms zero_and_negative_powers_are_forced
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'exponent_rules_add_subtract_multiply' depends on axioms: [propext, Classical.choice, Quot.sound]
'zero_and_negative_powers_are_forced' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Add a sixth round.** Change all three `range(6)` to `range(7)` — in the Rust, both `0..6`. Leave `power(3, 6)` and the `:>6` widths alone. Round 6 adds 729, not another 243.
> - **Make the base 1.** Everyone tells one friend. Every round reaches 1 person, the chain never grows, and the first assert fires.

---

## The usual mistake

> [!warning]
> **Reading 3^5 as 3 × 5, which is 15.** The raised number does not multiply the base; it counts copies of it. 3^5 is 243, and 15 is not close.
>
> - **Thinking 3^0 is 0.** It is 1.
> - **Expecting a negative exponent to give a negative answer.** 3^-3 is 1/27, not −27.
> - **Multiplying the exponents instead of adding them.** 3^2 × 3^3 is 3^5, which is 243, not 729.
> - **Different bases.** 3^2 × 5^2 is not 15^4; the adding rule needs the same base both sides.

---

## Where you meet it in real life

- **Anything that spreads.** Rumours, viruses, forwarded posts: each step multiplies instead of adding, which is why they look flat and then do not: [Linear versus exponential growth](02-linear-vs-exponential-growth.md).
- **Compound interest.** A balance growing a fixed percentage a year is a chain message with a small base.
- **Huge and tiny numbers.** Star distances and virus sizes are a number times a power of ten: [Scientific notation](04-scientific-notation.md).

> **Say it back**
> An exponent counts copies. 3^5 means five 3s multiplied together, which is 243; the 3 is the base, the 5 is the exponent. Multiplying powers of the same base adds those counts, dividing subtracts them. Stacking, (3^2)^3, multiplies them. That settles the odd cases: 243 ÷ 243 is 1 and is also 3^0; 9 ÷ 243 is 1/27 and is also 3^-3.

---

## What this builds on

- [Multiplying and dividing](../01-Everyday%20Arithmetic/03-multiplying-and-dividing.md): repeated multiplication, and cancelling factors.
- [Negative numbers](../01-Everyday%20Arithmetic/06-negative-numbers.md): what a minus sign on the exponent means.
- [Fractions](../01-Everyday%20Arithmetic/07-fractions.md): where 3^-3 lands, one twenty-seventh.

## Where this goes next

- [Linear versus exponential growth](02-linear-vs-exponential-growth.md): this chain against one that adds 3 people a round.
- [Roots](03-roots-and-fractional-exponents.md): what half a round would mean, and why it is a root.
- [Scientific notation](04-scientific-notation.md): powers of ten, for very big and very small numbers.
- [Logarithms](05-logarithms.md): this card backwards — given 243 and base 3, what power got me here?

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Euler, Leonhard. *Elements of Algebra*, trans. John Hewlett. Longman, Rees, Orme, 1828. [Internet Archive](https://archive.org/details/elementsofalgebr00eule). Powers from the pattern, zero and negative exponents included.
- Cajori, Florian. *A History of Mathematical Notations*, vol. 1. Open Court, 1928. [Internet Archive](https://archive.org/details/b29980343_0001). Where the raised number came from.
- Weisstein, Eric W. "Power." *MathWorld*. [mathworld.wolfram.com](https://mathworld.wolfram.com/Power.html). The modern statement of the three rules.
