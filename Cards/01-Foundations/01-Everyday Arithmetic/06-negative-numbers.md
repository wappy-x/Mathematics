# Negative numbers: the number line runs both ways

[Syllabus](../../../SYLLABUS.md) → [Foundations](../README.md) → [Everyday Arithmetic](../README.md#s01) → Negative numbers

---

## General Overview

The account is empty. You pay in $40. A bill for $65 goes out. The app shows **−$25**.

Nothing broke. The counting numbers cannot answer 40 take away 65, so the numbers keep going past zero.

Picture a road with zero in the middle. Walk right and count 1, 2, 3. Walk left and count the same distances the other way, each wearing a minus sign: −1, −2, −3.

The road is **the number line**; everything left of zero is a **negative number**. −25 is not a damaged 25. It is a place, twenty-five steps the far side of zero. Whole numbers of either sign, zero included, are the **integers**, written ℤ.

A thermometer reads the same road: 3 below zero is −3, and after a 5-degree drop it reads −8.

**A minus sign names the opposite: the same distance from zero, the other way. Once opposites exist, subtracting is adding an opposite.**

**What kind of fact this is:** a definition and two theorems. The opposite of a number is a definition. The two sign rules for multiplying are theorems, proved on this card in Why it works from the spreading law.

### The picture: the account as the story runs

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "One account, in dollars, as the story runs"
    x-axis "What just happened" ["start", "paid in 40", "bill of 65", "three fees", "fees cancelled"]
    y-axis "Balance, in dollars" -120 --> 60
    line [0, 40, -25, -100, -25]
```

Below zero is more map, not the edge of it.

---

## The formula

First, taking away more than you have:

**40 − 65 = 40 + (−65) = −25**

Then multiplying: three $25 fees charged, then all three cancelled.

**3 × (−25) = −75  and  (−3) × (−25) = 75**

**Read it aloud:** to subtract, add the opposite; and when multiplying, same signs give a plus, different signs a minus.

| Piece | Plain meaning | In our example |
| --- | --- | --- |
| a minus sign in front | the opposite: as far from zero, other side | −25, $25 in the red |
| zero | the middle of the line, neither side | the empty account |
| subtracting | adding the opposite | 40 − 65 is 40 + (−65) |
| the size | how far from zero, sign ignored | −25 sits 25 from zero |
| two signs multiplied | same signs a plus, different signs a minus | 3 × (−25) = −75 |

### When it holds

- **Every number has an opposite.** Without −65, the counting numbers have no answer for 40 − 65.
- **The spreading law holds.** It is the only thing that forces the sign rules. Drop it, cancel the fees as −3 × 25, and the account ends at −175, not −25.
- **A minus sign points the same way every time.** A bill, a fee and a colder day all move left. Move right for "5 colder" and −3 gives 2, not −8.
- **You divide by a number other than 0.** −75 ÷ 3 = −25 undoes 3 × (−25). No number times 0 gives −75, so −75 ÷ 0 has no answer.

---

## Why it works

### Step 0: every number gets an opposite

The opposite of 65 is −65: the number that cancels it. 65 + (−65) = 0. That is the whole definition.

### Step 1: subtracting is adding the opposite

Taking $65 out of an account and adding a $65 debt to it leave the same balance, so 40 − 65 and 40 + (−65) are one sum: −25. The thermometer agrees: −3 − 5 is −3 + (−5) = −8.

Subtraction is now a kind of adding, so the laws on [The three rearranging laws](05-arithmetic-laws.md) cover it.

### Step 2: a plus times a minus is a minus

Two facts do the rest. Three lots of nothing is nothing: 3 × 0 = 0. And spreading, from [The three rearranging laws](05-arithmetic-laws.md), sends a multiplier outside a bracket into everything inside. Aim it at a bracket worth zero.

- 25 + (−25) = 0, so 3 × (25 + (−25)) = 3 × 0 = 0.
- Spread it: 3 × 25 + 3 × (−25) = 0, that is 75 + 3 × (−25) = 0.
- Only −75 cancels 75. So **3 × (−25) = −75**: three fees, $75 further down.

### Step 3: a minus times a minus is a plus

The same move, minus three lots.

- (−3) × (25 + (−25)) = (−3) × 0 = 0.
- Spread it: (−3) × 25 + (−3) × (−25) = 0.
- (−3) × 25 is −75, by step 2 and the swapping law (order does not matter when you multiply).
- Only 75 cancels −75. So **(−3) × (−25) = 75**.

Nobody chose it. Once spreading holds, plus is the only answer that fits: cancel three $25 charges and you are $75 better off.

Dividing undoes multiplying, so the rule holds there: −75 ÷ 3 = −25 and −75 ÷ (−25) = 3.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| paid in, then the bill | 40 − 65 | −25 |
| the same, adding the opposite | 40 + (−65) | −25 |
| three below, five colder | −3 − 5 | −8 |
| three fees of 25 | 3 × (−25) | −75 |
| all three cancelled | (−3) × (−25) | **75** |
| that debt over three months | −75 ÷ 3 | −25 |
| how many fees make that debt | −75 ÷ (−25) | 3 |

The running balance printed below is the chart: 0, 40, −25, −100, −25.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Cancelling the fees as −3 × 25 | −175, not −25 | Two minus signs give a plus |
| Reading 40 − 65 as 65 − 40 | 25 | Order matters here |
| Reading "5 colder" as −3 + 5 | 2, above zero | Colder moves left: −3 + (−5) |

All three are printed below.

---

## Code, from first principles, and it actually runs

Nothing is imported. The bill is worked twice, 40 − 65 then 40 + (−65), and the sign rules are checked against spreading.

### Python

```python
# Negative numbers -- the check behind the card.  Nothing is imported.
# One bank account, in whole dollars: $40 paid in, a $65 bill out, then three
# $25 fees, then the bank cancels all three.  Plus a thermometer, in degrees.
def row(name, value):
    print(f"{name:<37}{value:>5}")

paid_in, bill, fee, months = 40, 65, 25, 3
balance = paid_in - bill                     # take the bill away: 40 - 65
opposite = paid_in + (-bill)                 # second route: add the opposite of 65
cold = -3 - 5                                # 3 below zero, 5 degrees colder
charged = months * (-fee)                    # three fees of 25 in the red
cancelled = (-months) * (-fee)               # those same three fees taken back off
run = [0, paid_in, balance, balance + charged, balance + charged + cancelled]
row("paid in 40, then a bill of 65", balance)
row("the same, as 40 + (-65)", opposite)
row("3 below zero, 5 degrees colder", cold)
row("three fees, 3 x (-25)", charged)
row("the bank cancels them, (-3) x (-25)", cancelled)
row("that debt over 3 months, -75 / 3", charged // months)
row("how many -25 fees make -75", charged // (-fee))
print("running balance " + " ".join(str(v) for v in run))
print(f"the three mistakes come out at {balance + charged + (-months * fee)}, "
      f"{bill - paid_in} and {-3 + 5}")
assert months * fee + months * (-fee) == 0 and charged == -75    # spreading fixes the sign
assert (-months) * fee + cancelled == 0 and cancelled == 75      # spreading again
assert balance == -25 and opposite == balance and cold == -8
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
paid in 40, then a bill of 65          -25
the same, as 40 + (-65)                -25
3 below zero, 5 degrees colder          -8
three fees, 3 x (-25)                  -75
the bank cancels them, (-3) x (-25)     75
that debt over 3 months, -75 / 3       -25
how many -25 fees make -75               3
running balance 0 40 -25 -100 -25
the three mistakes come out at -175, 25 and 2
ALL CHECKS PASS
```

### Rust

Same labels, built with `rustc --edition 2021 -O`.

```rust
// Negative numbers -- the same check as negative_numbers_check.py, in Rust.
// Standard library only, no crates.  Same numbers, same labels, same output.
// One bank account, in whole dollars: $40 paid in, a $65 bill out, then three
// $25 fees, then the bank cancels all three.  Plus a thermometer, in degrees.
// Compile: rustc --edition 2021 -O negative_numbers_check.rs -o negative_numbers_check
fn row(name: &str, value: i64) {
    println!("{:<37}{:>5}", name, value);
}

fn main() {
    let (paid_in, bill, fee, months) = (40i64, 65i64, 25i64, 3i64);
    let balance = paid_in - bill;               // take the bill away: 40 - 65
    let opposite = paid_in + (-bill);           // second route: add the opposite of 65
    let cold: i64 = -3 - 5;                     // 3 below zero, 5 degrees colder
    let charged = months * (-fee);              // three fees of 25 in the red
    let cancelled = (-months) * (-fee);         // those same three fees taken back off
    let run = [0, paid_in, balance, balance + charged, balance + charged + cancelled];
    row("paid in 40, then a bill of 65", balance);
    row("the same, as 40 + (-65)", opposite);
    row("3 below zero, 5 degrees colder", cold);
    row("three fees, 3 x (-25)", charged);
    row("the bank cancels them, (-3) x (-25)", cancelled);
    row("that debt over 3 months, -75 / 3", charged / months);
    row("how many -25 fees make -75", charged / (-fee));
    let parts: Vec<String> = run.iter().map(|v| v.to_string()).collect();
    println!("running balance {}", parts.join(" "));
    println!("the three mistakes come out at {}, {} and {}",
             balance + charged + (-months * fee), bill - paid_in, -3 + 5);
    assert!(months * fee + months * (-fee) == 0 && charged == -75); // spreading fixes the sign
    assert!((-months) * fee + cancelled == 0 && cancelled == 75);   // spreading again
    assert!(balance == -25 && opposite == balance && cold == -8);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
paid in 40, then a bill of 65          -25
the same, as 40 + (-65)                -25
3 below zero, 5 degrees colder          -8
three fees, 3 x (-25)                  -75
the bank cancels them, (-3) x (-25)     75
that debt over 3 months, -75 / 3       -25
how many -25 fees make -75               3
running balance 0 40 -25 -100 -25
the three mistakes come out at -175, 25 and 2
ALL CHECKS PASS
```

Identical, line for line.

### Lean

Lean proves the sign rules and subtracting for any numbers with opposites and the spreading law, and dividing for integers.

- Subtracting a number is the same as adding its opposite, so 40 − 65 is 40 + (−65).
- A plus times a minus is a minus, and so is a minus times a plus.
- A minus times a minus is a plus.
- For integers, dividing by a number other than 0 undoes multiplying by it.
- Every worked number on the card is checked too, from 40 − 65 = −25 to the three mistakes.

Printing the account story line by line, and the Try changing experiments, are left to the Python and Rust checks.

<details>
<summary>The Lean proof, 62 lines</summary>

```lean
-- Negative numbers: wherever every number has an opposite and the spreading law holds, subtracting is adding the opposite, same signs multiply to a plus and different signs to a minus, and in the integers dividing by a number other than 0 undoes multiplying by it.
import Mathlib.Algebra.Ring.Defs
import Mathlib.Algebra.Group.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.NormNum.DivMod

/-- The sign rules for multiplying, as the card proves them from the spreading law: in any number
system where every number has an opposite and multiplying spreads over adding (a ring), a plus
times a minus is a minus, a minus times a plus is a minus, and a minus times a minus is a plus. -/
theorem sign_rules_for_multiplying {R : Type*} [Ring R] (a b : R) :
    a * -b = -(a * b) ∧ -a * b = -(a * b) ∧ -a * -b = a * b := by
  refine ⟨mul_neg a b, neg_mul a b, ?_⟩
  rw [neg_mul, mul_neg, neg_neg]

/-- Subtracting is adding the opposite: once every number has an opposite, taking `b` away from
`a` gives the same answer as adding the opposite of `b` (40 − 65 is 40 + (−65)). -/
theorem subtracting_is_adding_the_opposite {R : Type*} [Ring R] (a b : R) :
    a - b = a + -b := by
  exact sub_eq_add_neg a b

/-- Dividing undoes multiplying, for whole numbers of either sign: when you divide by a number
other than 0, multiplying by it and then dividing by it gets you back where you started
(3 × (−25) = −75, and −75 ÷ 3 = −25). -/
theorem dividing_undoes_multiplying (a b : ℤ) (hb : b ≠ 0) :
    a * b / b = a := by
  exact Int.mul_ediv_cancel a hb

-- The opposite of 65 cancels it.
example : (65 : ℤ) + -65 = 0 := by norm_num
-- Paid in 40, then a bill of 65: −25, the same both ways.
example : (40 : ℤ) - 65 = -25 := by norm_num
example : (40 : ℤ) + -65 = -25 := by norm_num
-- Three below zero, five degrees colder: −8.
example : (-3 : ℤ) - 5 = -8 := by norm_num
example : (-3 : ℤ) + -5 = -8 := by norm_num
-- Step 2: three lots of a bracket worth zero, spread out, forces 3 × (−25) = −75.
example : (3 : ℤ) * 25 + 3 * -25 = 0 := by norm_num
example : (3 : ℤ) * -25 = -75 := by norm_num
-- Step 3: the same move, minus three lots, forces (−3) × (−25) = 75.
example : (-3 : ℤ) * 25 + -3 * -25 = 0 := by norm_num
example : (-3 : ℤ) * -25 = 75 := by norm_num
-- Dividing undoes it: −75 ÷ 3 = −25 and −75 ÷ (−25) = 3.
example : (-75 : ℤ) / 3 = -25 := by norm_num
example : (-75 : ℤ) / -25 = 3 := by norm_num
-- The running balance: 0, 40, −25, −100, −25.
example : (0 : ℤ) + 40 = 40 ∧ (40 : ℤ) - 65 = -25 ∧ (-25 : ℤ) + 3 * -25 = -100 ∧
    (-100 : ℤ) + -3 * -25 = -25 := by norm_num
-- Taking the fees back off: −100 − (−75) = −100 + 75 = −25.
example : (-100 : ℤ) - -75 = -25 ∧ (-100 : ℤ) + 75 = -25 := by norm_num
-- The three mistakes: −175, 25 and 2.
example : (-25 : ℤ) + 3 * -25 + -3 * 25 = -175 := by norm_num
example : (-100 : ℤ) - 75 = -175 := by norm_num
example : (65 : ℤ) - 40 = 25 := by norm_num
example : (-3 : ℤ) + 5 = 2 := by norm_num
-- A bigger debt is a smaller number: −100 sits left of −25.
example : (-100 : ℤ) < -25 := by norm_num
-- Lifts: two floors up from −1 is 1.
example : (-1 : ℤ) + 2 = 1 := by norm_num

#print axioms sign_rules_for_multiplying
#print axioms subtracting_is_adding_the_opposite
#print axioms dividing_undoes_multiplying
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'sign_rules_for_multiplying' depends on axioms: [propext]
'subtracting_is_adding_the_opposite' depends on axioms: [propext]
'dividing_undoes_multiplying' depends on axioms: [propext]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Make the bill smaller.** Set `bill` to 30. The balance is 10, above zero, the first two rows still agree, and the last assert fires: it is pinned to −25.
> - **Break the sign rule.** Change `cancelled` to `months * (-fee)`. It prints −75 and the second assert fires: the bank is charging you again, not paying you back.

---

## The usual mistake

> [!warning]
> **Reading a minus sign as damage instead of a direction.** A bigger debt is a smaller number: −100 sits left of −25 on the line, though further from zero.
>
> - **Subtracting a negative and keeping the minus.** Taking the fees back off is −100 − (−75) = −100 + 75 = −25, same as adding (−3) × (−25) above. As −100 − 75 it gives −175.
> - **Two minuses made into a minus.** Cancelling as −3 × 25 gives −75, and the account ends at −175.
> - **Facing the wrong way.** Five colder than −3 is −3 + (−5) = −8. Written −3 + 5 it gives 2, above zero.

---

## Where you meet it in real life

- **Bank accounts.** A balance is a position on the line, not a pile of cash, so it can sit below zero.
- **Temperature.** −3 dropping 5 is −8, and a 5-degree drop is the same size either side of zero.
- **Lifts.** The ground floor is zero, so the button under it says −1; two floors up from −1 is 1.

> **Say it back**
> Counting numbers stop at zero; life does not. A minus sign names the opposite: as far from zero, the other way. So subtracting is adding the opposite, and 40 − 65 is 40 + (−65) = −25. Same signs multiply to a plus, different signs to a minus, forced by spreading over a bracket worth zero — which is why cancelling three $25 charges hands you $75 back.

---

## What this builds on

- [The three rearranging laws](05-arithmetic-laws.md): the spreading law, which at a bracket worth zero is the whole argument for the sign rules here.

## Where this goes next

- [The number families](../02-The%20Number%20Line/01-number-families.md): each family of numbers named by the sum the one before could not do.
- [Absolute value](../02-The%20Number%20Line/05-absolute-value-and-distance.md): the "size, sign ignored" row above, made into its own tool.
- [Exponents](../03-Powers%2C%20Roots%20and%20Logarithms/01-exponents-and-powers.md): a minus sign moved up into the count of the multiplications.

This card leaves one question open: −75 shares evenly over 3 months, but what number is 25 shared between 3?

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Euler, Leonhard. *Elements of Algebra*, trans. John Hewlett, 1828. [Internet Archive](https://archive.org/details/elementsofalgebr00eule). Euler's own argument that a minus times a minus must be a plus.
- O'Connor, J. J., and E. F. Robertson. "Brahmagupta." *MacTutor History of Mathematics Archive*, University of St Andrews. [MacTutor](https://mathshistory.st-andrews.ac.uk/Biographies/Brahmagupta/). Brahmagupta wrote the sign rules in 628 AD, as fortunes and debts.
- Lang, Serge. *Basic Mathematics*. Springer New York, 1988. [Publisher page](https://link.springer.com/book/9780387967875). The same rules from the same laws.
