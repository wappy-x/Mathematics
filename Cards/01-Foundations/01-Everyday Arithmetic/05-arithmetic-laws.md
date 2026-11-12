# The three rearranging laws: swapping, regrouping, and spreading multiplication over addition

[Syllabus](../../../SYLLABUS.md) → [Foundations](../README.md) → [Everyday Arithmetic](../README.md#s01) → The three rearranging laws

---

## General Overview

Twelve apples, 75 cents each. You hand over a ten-dollar bill, 1000 cents. Then four friends split the lot.

Nobody works out 12 × 75 the way school taught. You do twelve lots of 70 cents, 840, then twelve lots of 5 cents, 60. Together, 900 cents. Nine dollars. Or: four friends taking three apples each is the same twelve apples, so price one friend's three at 225 cents and take four of those. 900 again.

Both shortcuts shoved the numbers around and neither changed the answer. That is not luck: adding and multiplying obey three rules, and the rules say which shoves are safe.

- **Swapping**, real name **commutative**. 12 × 75 and 75 × 12 come to the same thing. Same for adding.
- **Regrouping**, real name **associative**. In an all-plus or all-times chain, the brackets do not matter.
- **Spreading**, real name **distributive**. A multiplier outside a bracket hits everything inside: 12 × (70 + 5) is 12 × 70 plus 12 × 5.

**Adding and multiplying let you swap, regroup and spread the numbers without changing the answer.**

**What kind of fact this is:** three laws, true for every whole number; Why it works shows why by counting.

### The picture: turn the tray

```
Twelve apples, four rows of three.   Turn it a quarter turn: three rows of four.

        o o o                                 o o o o
        o o o                                 o o o o
        o o o                                 o o o o
        o o o
```

Nothing was added, nothing taken away, so 4 × 3 and 3 × 4 are the same twelve apples.

---

## The formula

Let $a$, $b$ and $c$ stand for any three whole numbers. Each law, with the apples underneath.

$$a + b = b + a \qquad\qquad a \times b = b \times a$$

12 × 75 = 75 × 12 = 900.

$$(a + b) + c = a + (b + c) \qquad\qquad (a \times b) \times c = a \times (b \times c)$$

(4 × 3) × 75 = 4 × (3 × 75) = 900.

$$a \times (b + c) = a \times b + a \times c$$

12 × (70 + 5) = 12 × 70 + 12 × 5 = 840 + 60 = 900.

**Read it aloud:** order does not matter, grouping does not matter, and a multiplier outside a bracket hits every piece inside it, not just the first. Only the third law has both operations in it, and it does the real work.

| Symbol | Plain meaning | In 12 × (70 + 5) |
| --- | --- | --- |
| $a$ | any whole number; here, outside the bracket | 12, the apples |
| $b$ | any whole number; here, the first piece inside | 70 |
| $c$ | any whole number; here, the second piece | 5 |

### When it holds

- **Adding or multiplying only.** Swap or regroup across a minus or a divide and the answer moves: 1000 − (900 − 100) comes out at 200 cents you never had.
- **An all-plus or all-times chain, for regrouping.** Mix the two and the brackets carry meaning: 12 × (70 + 5) is 900, but 12 × 70 + 5 is 845.
- **Whole numbers, for this argument.** Why it works counts apples, so it covers whole numbers only. The laws stay true for minus numbers and fractions, but those need their own argument on later cards.

---

## Why it works

A number is a count, and moving things around does not change how many there are. That is the whole argument, and the tray is it: turn the tray, the apples do not care. Each of the three laws is that move, a new way of describing a pile you never touched.

Spreading is the one worth slowing down for, because it is the one you use. 75 cents is awkward; 70 and 5 are not. So cut the price, not the apples. Each apple is charged twice, 70 cents on one bill and 5 cents on another, and the two bills add back to the real one: 840 + 60 = 900. Cut the price anywhere and the pieces rebuild the same 900.

Where it stops: subtraction and division neither swap nor regroup, and the tables below count the damage.

---

## Worked numbers, by hand

Everything in cents, so the arithmetic stays whole. Cut the price, 75 = 70 + 5.

| Step | Arithmetic | Value |
| --- | --- | --- |
| twelve lots of 70 | 12 × 70 | 840 |
| twelve lots of 5 | 12 × 5 | 60 |
| add the pieces back | 840 + 60 | **900 cents** |
| swap, as a check | 75 × 12 | 900 |
| regroup, as a check | 4 × (3 × 75) | 900 |
| change from the bill | 1000 − 900 | 100 |
| each friend's share | 900 ÷ 4 | 225 |
| each friend, other road | 3 × 75 | 225 |

The last two lines are the reverse check. Splitting the bill four ways and pricing the three apples one friend walks off with are different sums, and they agree because regrouping says they must.

### What breaks if you drop a piece

| Mistake | Comes out at | Why |
| --- | --- | --- |
| Half a spread: 12 × 70 + 5 | 845, not 900 | The 5 never got its twelve apples. |
| Regroup a subtraction: 1000 − (900 − 100) | 200, not 0 | Minus does not regroup. The 100 you spent got *added* to your money. |

Both are printed below, beside the right answers.

---

## Code, from first principles, and it actually runs

Nothing is imported. The bill is worked out the obvious way, then by a second route, and the three laws are checked on those numbers.

### Python

```python
# The three rearranging laws -- the check behind the card.  No imports.
# Twelve apples at 75 cents, a ten-dollar bill (1000 cents), four friends.
# The bill is done the obvious way, then by a second route; then the three laws.
APPLES, PRICE, BILL, FRIENDS = 12, 75, 1000, 4

def show(label, value):
    print(f"{label:<33}{value:>6}")

bill = APPLES * PRICE                    # obvious way: 12 lots of 75 cents
bill_again = FRIENDS * (3 * PRICE)       # second route: 4 friends, 3 apples each
first, second = APPLES * 70, APPLES * 5  # spreading: the 75 cut into 70 and 5
change = BILL - bill
share = bill // FRIENDS
half = APPLES * 70 + 5                   # a spread that missed the second piece
bad_minus = BILL - (bill - 100)          # a minus that was wrongly regrouped
show("bill, 12 x 75", bill)
show("bill again, 4 x (3 x 75)", bill_again)
show("swap, 75 x 12", PRICE * APPLES)
show("regroup, (4 x 3) x 75", (FRIENDS * 3) * PRICE)
show("spread, 12 x 70", first)
show("spread, 12 x 5", second)
show("spread, 840 + 60", first + second)
show("change, 1000 - 900", change)
show("each friend, 900 / 4", share)
show("wrong, 12 x 70 + 5", half)
show("wrong, 1000 - (900 - 100)", bad_minus)
assert bill == 900 and bill_again == bill and PRICE * APPLES == bill, "swap and regroup hold"
assert first + second == bill and change == 100 and share == 225, "spread, change, share"
assert half == 845 and bad_minus == 200, "the two traps"
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
bill, 12 x 75                       900
bill again, 4 x (3 x 75)            900
swap, 75 x 12                       900
regroup, (4 x 3) x 75               900
spread, 12 x 70                     840
spread, 12 x 5                       60
spread, 840 + 60                    900
change, 1000 - 900                  100
each friend, 900 / 4                225
wrong, 12 x 70 + 5                  845
wrong, 1000 - (900 - 100)           200
ALL CHECKS PASS
```

### Rust

```rust
// The three rearranging laws -- the same check as arithmetic_laws_check.py, in Rust.
// Standard library only, no crates.  Same numbers, same labels, same output.
// Compile: rustc --edition 2021 -O arithmetic_laws_check.rs -o arithmetic_laws_check
const APPLES: i64 = 12;   // apples
const PRICE: i64 = 75;    // cents each
const BILL: i64 = 1000;   // cents handed over
const FRIENDS: i64 = 4;   // people

fn show(label: &str, value: i64) {
    println!("{:<33}{:>6}", label, value);
}

fn main() {
    let bill = APPLES * PRICE;                        // obvious way: 12 lots of 75 cents
    let bill_again = FRIENDS * (3 * PRICE);           // second route: 4 friends, 3 apples each
    let (first, second) = (APPLES * 70, APPLES * 5);  // spreading: the 75 cut into 70 and 5
    let change = BILL - bill;
    let share = bill / FRIENDS;
    let half = APPLES * 70 + 5;                       // a spread that missed the second piece
    let bad_minus = BILL - (bill - 100);              // a minus that was wrongly regrouped
    show("bill, 12 x 75", bill);
    show("bill again, 4 x (3 x 75)", bill_again);
    show("swap, 75 x 12", PRICE * APPLES);
    show("regroup, (4 x 3) x 75", (FRIENDS * 3) * PRICE);
    show("spread, 12 x 70", first);
    show("spread, 12 x 5", second);
    show("spread, 840 + 60", first + second);
    show("change, 1000 - 900", change);
    show("each friend, 900 / 4", share);
    show("wrong, 12 x 70 + 5", half);
    show("wrong, 1000 - (900 - 100)", bad_minus);
    assert!(bill == 900 && bill_again == bill && PRICE * APPLES == bill, "swap and regroup hold");
    assert!(first + second == bill && change == 100 && share == 225, "spread, change, share");
    assert!(half == 845 && bad_minus == 200, "the two traps");
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
bill, 12 x 75                       900
bill again, 4 x (3 x 75)            900
swap, 75 x 12                       900
regroup, (4 x 3) x 75               900
spread, 12 x 70                     840
spread, 12 x 5                       60
spread, 840 + 60                    900
change, 1000 - 900                  100
each friend, 900 / 4                225
wrong, 12 x 70 + 5                  845
wrong, 1000 - (900 - 100)           200
ALL CHECKS PASS
```

Identical, line for line.

### Lean

Lean proves the three laws for every whole number, and proves that minus and divide break them.

- Swapping, regrouping and spreading hold for any three whole numbers $a$, $b$ and $c$.
- Minus and divide neither swap nor regroup. This stays true with minus numbers and fractions allowed, so it is not a whole-number quirk.
- The apple numbers come out as the card says: the 900-cent bill both ways, the 100 change, the 225 shares and both traps.

Printing the table and running the bill as a program are left to the Python and Rust checks.

```lean
-- The three rearranging laws: for every three whole numbers, adding and multiplying both swap and regroup freely and a multiplier spreads over a sum, subtraction and division neither swap nor regroup, and the card's apple-bill numbers come out as it says.
import Mathlib.Data.Rat.Defs
import Mathlib.Tactic.NormNum

/-- The three rearranging laws, for any three whole numbers `a`, `b`, `c`.
Swapping: `a + b = b + a` and `a × b = b × a`.
Regrouping: `(a + b) + c = a + (b + c)` and `(a × b) × c = a × (b × c)`.
Spreading: `a × (b + c) = a × b + a × c`, the multiplier outside the bracket hits every piece. -/
theorem swap_regroup_spread_whole_numbers (a b c : ℕ) :
    (a + b = b + a ∧ a * b = b * a) ∧
      ((a + b) + c = a + (b + c) ∧ (a * b) * c = a * (b * c)) ∧
      a * (b + c) = a * b + a * c := by
  exact ⟨⟨Nat.add_comm a b, Nat.mul_comm a b⟩, ⟨Nat.add_assoc a b c, Nat.mul_assoc a b c⟩,
    Nat.mul_add a b c⟩

/-- Where the laws stop: subtraction and division neither swap nor regroup. For each, some
numbers give a different answer once swapped, and some give a different answer once the
brackets move (the card's trap is `1000 − (900 − 100)`, which is not `(1000 − 900) − 100`).
Subtraction is stated on the integers and division on the rationals, so that neither failure
comes from whole-number subtraction stopping at zero or whole-number division dropping a
remainder. -/
theorem minus_and_divide_neither_swap_nor_regroup :
    (¬ ∀ a b : ℤ, a - b = b - a) ∧ (¬ ∀ a b c : ℤ, a - (b - c) = (a - b) - c) ∧
      (¬ ∀ a b : ℚ, a / b = b / a) ∧ (¬ ∀ a b c : ℚ, a / (b / c) = (a / b) / c) := by
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro h
    have := h 0 1
    norm_num at this
  · intro h
    have := h 1 1 1
    norm_num at this
  · intro h
    have := h 1 2
    norm_num at this
  · intro h
    have := h 1 1 2
    norm_num at this

-- The apple bill in cents: twelve apples at 75 cents.
example : 12 * 75 = 900 := by decide
-- Swap, as a check.
example : 75 * 12 = 900 := by decide
-- Regroup: four friends with three apples each.
example : (4 * 3) * 75 = 900 := by decide
example : 4 * (3 * 75) = 900 := by decide
-- Spread: cut the price, 75 = 70 + 5.
example : 12 * (70 + 5) = 12 * 70 + 12 * 5 := by decide
example : 12 * 70 = 840 := by decide
example : 12 * 5 = 60 := by decide
example : 840 + 60 = 900 := by decide
-- Change from the bill, and each friend's share two ways.
example : 1000 - 900 = 100 := by decide
example : 900 / 4 = 225 ∧ 900 % 4 = 0 := by decide
example : 3 * 75 = 225 := by decide
-- The turned tray: four rows of three is three rows of four.
example : 4 * 3 = 3 * 4 := by decide
-- Half a spread: the 5 never got its twelve apples.
example : 12 * 70 + 5 = 845 := by decide
example : 12 * 70 + 5 ≠ 12 * (70 + 5) := by decide
-- Regrouping a subtraction: 200 cents you never had, against the true 0.
example : 1000 - (900 - 100) = 200 := by decide
example : (1000 - 900) - 100 = 0 := by decide

#print axioms swap_regroup_spread_whole_numbers
#print axioms minus_and_divide_neither_swap_nor_regroup
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'swap_regroup_spread_whole_numbers' depends on axioms: [propext]
'minus_and_divide_neither_swap_nor_regroup' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Move the price.** Set `PRICE` to any other number of cents. Both roads to the bill move together, though the labels and asserts, still nailed to 75, will complain.
> - **Un-break the trap.** Change `half` to `APPLES * 70 + APPLES * 5`. Instead of 845 it comes out at **900**. That one missing 12 was the whole error.

---

## The usual mistake

> [!warning]
> **Assuming the three laws cover all four operations.** They do not. Swapping and regrouping are claims about adding and multiplying only. Move something across a minus or a divide and you need a separate argument: spend 900 on apples and 100 on the bus, and 1000 − (900 − 100) hands you 200 cents that are not there.
>
> Two smaller ones:
> - **Spreading to only the first piece.** 12 × (70 + 5) written as 12 × 70 + 5 gives 845, not 900. The multiplier is outside the bracket, so it applies to everything in it.
> - **Confusing these laws with order of operations.** [Order of operations](04-order-of-operations.md) tells you what an expression means; these three tell you which rewrites keep its value. One is reading, the other is moving.

---

## Where you meet it in real life

- **Mental arithmetic.** Every trick is one of these three: 12 × 75 becomes 840 + 60. You already do it, the card only names it.
- **Long multiplication.** The part-products you stack in columns are the pieces of a spread done twice. The algorithm is this law with ruled lines.
- **Splitting a bill.** Four friends, 900 cents, 225 each, everyone checking it a different way.

> **Say it back**
> Adding and multiplying obey three rules. Swapping: the order does not matter. Regrouping: in an all-plus or all-times chain, the brackets do not matter. Spreading: a multiplier outside a bracket hits everything inside, so 12 × (70 + 5) is 840 + 60, which is 900. Subtraction and division obey neither of the first two: 1000 − (900 − 100) hands you 200 cents you never had.

---

## What this builds on

- [Order of operations](04-order-of-operations.md): what an expression means before you touch it. That card sets the reading, this one the legal rewrites.
- [Multiplying and dividing](03-multiplying-and-dividing.md): the grid picture of a product, here turned a quarter turn and cut in two.

## Where this goes next

- [Negative numbers](06-negative-numbers.md): where subtraction stops being a fourth operation. Once minus numbers exist, $a - b$ is $a + (-b)$, an addition in disguise, and swapping and regrouping cover it after all.

The question this card leaves open: what does subtraction become, so that the three laws reach it too?

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Euclid. *Elements*, Book II, Proposition 1, in David E. Joyce's edition. [Clark University](https://mathcs.clarku.edu/~djoyce/elements/bookII/propII1.html). Spreading, around 300 BC, as rectangles: cut one side into pieces and the rectangle is the sum of the small ones.

- O'Connor, J. J., and E. F. Robertson. "François-Joseph Servois." *MacTutor History of Mathematics Archive*, University of St Andrews. [MacTutor](https://mathshistory.st-andrews.ac.uk/Biographies/Servois/). Servois coined "commutative" and "distributive" in 1814.
- Lang, Serge. *Basic Mathematics*. Springer New York, 1988. [doi:10.1007/978-1-4612-1027-6](https://doi.org/10.1007/978-1-4612-1027-6). States these rules for numbers before any algebra appears.
