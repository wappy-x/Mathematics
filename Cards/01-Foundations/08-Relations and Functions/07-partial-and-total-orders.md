# Orders: rankings where some pairs may be incomparable, drawn as a Hasse diagram

[Syllabus](../../../SYLLABUS.md) → [Foundations](../README.md) → [Relations and Functions](../README.md#s08) → Orders

---

## General Overview

Twelve people, split into equal teams with nobody left over. The sizes that work are the six divisors of 12: 1, 2, 3, 4, 6, 12. Say **a divides b** when b splits into whole a's — 2 divides 12, because 12 is six 2s. 5 does not.

Stack those six by "divides": 2 divides 4, and 4 divides 12, a run of three. Now ask about 2 and 3. Neither divides the other. Call such a pair **incomparable**. Line the same six up by "less than or equal to" and nothing is left over: one queue, 1 up to 12.

**An order is a rule that passes three tests. Pass a fourth — every pair compares — and it is total as well.**

**What kind of fact this is:** a definition. The counts on the divisors of 12 are checked by both programs.

### The picture: the six divisors of 12, under "divides"

```mermaid
flowchart BT
  n1["1"] --> n2["2"]
  n1 --> n3["3"]
  n2 --> n4["4"]
  n2 --> n6["6"]
  n3 --> n6
  n4 --> n12["12"]
  n6 --> n12
```

Up the page means "divides into". Only the 7 short steps are drawn; the rest you walk, so 1 to 2 to 4 to 12 says 1 divides 12. That is a **Hasse diagram**. 2 and 3 sit side by side with no upward path either way.

---

## The formula

Three tests, on the six divisors of 12 with "divides" as the rule. Let a, b and c be numbers from the six.

**Reflexive: every number divides itself. Antisymmetric: if a divides b and b divides a, then a and b are the same number. Transitive: if a divides b and b divides c, then a divides c.**

**Read it aloud:** every number is below or equal to itself, two different numbers are never below each other, and below-then-below means below.

Pass all three and it is a **partial order**; a set with one on it is a **poset**, short for partially ordered set. A fourth test says which kind:

**Comparability: for every a and b, either a divides b or b divides a.**

Divides fails that one at 2 and 3. A rule passing all four is a **total order**; "less than or equal to" on these six is one.

| Piece | Plain meaning | In our example |
| --- | --- | --- |
| a divides b | b divided by a leaves no remainder | 3 divides 12; 3 does not divide 4 |
| a partial order | passes the first three tests | divides: 18 pairs |
| comparable | one of the two is below the other | 2 and 6 yes, 2 and 3 no |
| a total order | every pair compares as well | less than or equal to: 21 pairs |
| a cover | a step up with nothing in between | 2 up to 6, not 1 up to 6 |

### When it holds

- **Each number is paired with itself.** Without the self-pairs, divides has 12 pairs and fails the reflexive test.
- **No loops.** If 4 were below 6 and 6 below 4, the antisymmetric test fails.
- **No gaps.** If 1 is below 2 and 2 below 4, then 1 must be below 4, or the transitive test fails.
- **Every pair compares, for a total order.** Divides misses 3 of the 15 pairs.
- **A finite set, for the Hasse diagram.** On the number line, any two points have another between them, so there are no covers.

---

## Why it works

### The three tests are three things a ranking must not do

Reflexive fills in the easy pairs, so "below or equal to" is one rule, not two. Antisymmetric bans the loop: if 4 were below 6 and 6 below 4, "below" would mean nothing. Transitive bans the gap: 2 below 6 and 6 below 12 must force 2 below 12, or the diagram lies.

Divides passes all three: 12 is one 12; if each of two numbers is a whole number of the other, neither is smaller, so they are equal; 12 is two 6s and 6 is two 3s, so 12 is four 3s.

### Comparability is a fourth demand, and nothing forces it

No test mentions a pair with no link. 2 and 3 have none, and no test complains — a fact about them, not a fault in the rule. Add comparability and the six lie in one queue, as "less than or equal to" does.

### Only the short steps need drawing

A cover is a step with nothing strictly in between. Draw covers only and 7 arrows carry what the 12 different-number pairs say. Put the six self-pairs back, link the arrows over and over — 1 to 2 and 2 to 4 gives 1 to 4 — and all 18 pairs return. The queue is called a **chain**; it takes 5 arrows, each number to the next.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| pairs where the first divides the second | 6 + 4 + 3 + 2 + 2 + 1 | **18** |
| of those, two different divisors | 18 − 6 | 12 |
| two different divisors in all | 6 × 5 ÷ 2 | 15 |
| pairs that never compare | 15 − 12 | **3** |
| where the first is less than or equal | 6 + 5 + 4 + 3 + 2 + 1 | **21** |

That first count runs down the list: 1 divides 6 of them, 2 divides 4 of them, 3 divides 3, 4 and 6 divide 2 each, 12 divides only itself. The 3 that never compare are 2 and 3, 3 and 4, 4 and 6: why divides has 18 pairs and the queue 21.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Drawing every link, not only the covers | 12 arrows, not 7 | The 5 long ones read off as paths |
| Using "divides and is not equal" | 12 pairs, reflexive no | The self-pairs go, so the first test fails |

---

## Code, from first principles, and it actually runs

The six divisors go through the four tests twice: as "divides", then as "less than or equal to". Then the divides order is rebuilt from its 7 covers alone: a second road to the same 18 pairs. A rule with a gap in it fails transitivity.

### Python

```python
# Orders -- the check behind the card.  Nothing is imported.  The six divisors of 12 under "divides",
# and the same six under "less than or equal": three order tests each, then comparability, then covers.
D, NAMES = [1, 2, 3, 4, 6, 12], ["reflexive", "antisymmetric", "transitive", "all pairs compare"]
DIV, LEQ = {(a, b) for a in D for b in D if b % a == 0}, {(a, b) for a in D for b in D if a <= b}
def tests(R):                  # the three order tests, then the extra one that makes it total
    return (all((a, a) in R for a in D), all(a == b for a, b in R if (b, a) in R),
            all((a, c) in R for a, b in R for c in D if (b, c) in R),
            all((a, b) in R or (b, a) in R for a in D for b in D))
def covers(R):                 # a step up with nothing strictly in between: the Hasse edges
    return sorted((a, b) for a, b in R if a != b and not any((a, m) in R and (m, b) in R for m in D if m != a and m != b))
def rebuild(edges):            # the loops, then chain the edges over and over: the second road
    R = {(a, a) for a in D} | set(edges)
    while any((a, c) not in R for a, b in R for x, c in R if b == x):
        R |= {(a, c) for a, b in R for x, c in R if b == x}
    return R
COV, LCOV = covers(DIV), covers(LEQ)
INCOMP = sorted((a, b) for a in D for b in D if a < b and (a, b) not in DIV and (b, a) not in DIV)
STRICT, GAPPY = {(a, b) for a, b in DIV if a != b}, {(a, a) for a in D} | {(1, 2), (2, 4)}   # loops dropped; 1 to 2 and 2 to 4, no 1 to 4
print(f"the six divisors of 12: {', '.join(map(str, D))} -- {len(D) * len(D)} ordered pairs to ask about")
print("divides pairs, counting multiples: " + " + ".join(str(sum(1 for b in D if b % a == 0)) for a in D) + f" = {len(DIV)}")
print("less than or equal pairs:          " + " + ".join(str(sum(1 for b in D if a <= b)) for a in D) + f" = {len(LEQ)}")
print(f"{'test':<20}{'divides':<9}less than or equal")
for n, x, y in zip(NAMES, tests(DIV), tests(LEQ)): print(f"{n:<20}{('yes' if x else 'no'):<9}{'yes' if y else 'no'}")
print(f"incomparable under divides: {', '.join(f'({a}, {b})' for a, b in INCOMP)} -- {len(INCOMP)} of the {len(D) * (len(D) - 1) // 2} pairs")
print(f"Hasse edges: divides {len(COV)} ({', '.join(f'{a}-{b}' for a, b in COV)}), the chain {len(LCOV)}")
print(f"rebuilt from those {len(COV)} edges plus loops: {len(rebuild(COV))} pairs, the same list; strict divides: {len(STRICT)} pairs, reflexive {'yes' if tests(STRICT)[0] else 'no'}")
assert len(DIV) == 18 and len(LEQ) == 21 and len(STRICT) == 12 and INCOMP == [(2, 3), (3, 4), (4, 6)]
assert tests(DIV) == (True, True, True, False) and tests(LEQ) == (True, True, True, True) and not tests(STRICT)[0] and tests(GAPPY) == (True, True, False, False)
assert rebuild(COV) == DIV and COV == [(1, 2), (1, 3), (2, 4), (2, 6), (3, 6), (4, 12), (6, 12)] and LCOV == [(1, 2), (2, 3), (3, 4), (4, 6), (6, 12)]
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
the six divisors of 12: 1, 2, 3, 4, 6, 12 -- 36 ordered pairs to ask about
divides pairs, counting multiples: 6 + 4 + 3 + 2 + 2 + 1 = 18
less than or equal pairs:          6 + 5 + 4 + 3 + 2 + 1 = 21
test                divides  less than or equal
reflexive           yes      yes
antisymmetric       yes      yes
transitive          yes      yes
all pairs compare   no       yes
incomparable under divides: (2, 3), (3, 4), (4, 6) -- 3 of the 15 pairs
Hasse edges: divides 7 (1-2, 1-3, 2-4, 2-6, 3-6, 4-12, 6-12), the chain 5
rebuilt from those 7 edges plus loops: 18 pairs, the same list; strict divides: 12 pairs, reflexive no
ALL CHECKS PASS
```

### Rust

Same numbers, built with `rustc --edition 2021 -O`.

```rust
// Orders -- the same check as partial_and_total_orders_check.py, in Rust.  No crates.  The six divisors of 12 under "divides", and the same six under "less than or equal": three order tests each, then covers.
use std::collections::BTreeSet; type Rel = BTreeSet<(i64, i64)>;
const D: [i64; 6] = [1, 2, 3, 4, 6, 12]; const NAMES: [&str; 4] = ["reflexive", "antisymmetric", "transitive", "all pairs compare"];
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn build(f: fn(i64, i64) -> bool) -> Rel {
    let mut r = Rel::new(); for &a in D.iter() { for &b in D.iter() { if f(a, b) { r.insert((a, b)); } } } r
}
fn tests(r: &Rel) -> [bool; 4] {   // the three order tests, then the extra one that makes it total
    [D.iter().all(|&a| r.contains(&(a, a))), r.iter().all(|&(a, b)| a == b || !r.contains(&(b, a))),
     r.iter().all(|&(a, b)| D.iter().all(|&c| !r.contains(&(b, c)) || r.contains(&(a, c)))),
     D.iter().all(|&a| D.iter().all(|&b| r.contains(&(a, b)) || r.contains(&(b, a))))]
}
fn covers(r: &Rel) -> Vec<(i64, i64)> {   // a step up with nothing strictly in between: the Hasse edges
    r.iter().filter(|&&(a, b)| a != b && !D.iter().any(|&m| m != a && m != b && r.contains(&(a, m)) && r.contains(&(m, b)))).cloned().collect()
}
fn rebuild(edges: &[(i64, i64)]) -> Rel {   // the loops, then chain the edges over and over: the second road
    let mut r: Rel = D.iter().map(|&a| (a, a)).collect(); for &e in edges { r.insert(e); }
    loop { let mut more = r.clone();
        for &(a, b) in r.iter() { for &(x, c) in r.iter() { if b == x { more.insert((a, c)); } } }
        if more == r { return r; } r = more; }
}
fn main() {
    let (div, leq) = (build(|a, b| b % a == 0), build(|a, b| a <= b));
    let (cov, lcov, strict, gappy) = (covers(&div), covers(&leq), div.iter().filter(|&&(a, b)| a != b).cloned().collect::<Rel>(), D.iter().map(|&a| (a, a)).chain([(1, 2), (2, 4)]).collect::<Rel>());   // gappy: 1 to 2 and 2 to 4, no 1 to 4
    let mut incomp: Vec<(i64, i64)> = Vec::new();   for &a in D.iter() { for &b in D.iter() { if a < b && !div.contains(&(a, b)) && !div.contains(&(b, a)) { incomp.push((a, b)); } } }
    let count = |f: fn(i64, i64) -> bool| D.iter().map(|&a| D.iter().filter(|&&b| f(a, b)).count().to_string()).collect::<Vec<String>>().join(" + ");
    let pairs = |v: &[(i64, i64)], sep: &str, br: bool| v.iter().map(|(a, b)| if br { format!("({}{}{})", a, sep, b) } else { format!("{}{}{}", a, sep, b) }).collect::<Vec<String>>().join(", ");
    println!("the six divisors of 12: {} -- {} ordered pairs to ask about", D.iter().map(|x| x.to_string()).collect::<Vec<String>>().join(", "), D.len() * D.len());
    println!("divides pairs, counting multiples: {} = {}", count(|a, b| b % a == 0), div.len());
    println!("less than or equal pairs:          {} = {}", count(|a, b| a <= b), leq.len());
    let (td, tl) = (tests(&div), tests(&leq)); println!("{:<20}{:<9}{}", "test", "divides", "less than or equal");
    for i in 0..4 { println!("{:<20}{:<9}{}", NAMES[i], yn(td[i]), yn(tl[i])); }
    println!("incomparable under divides: {} -- {} of the {} pairs", pairs(&incomp, ", ", true), incomp.len(), D.len() * (D.len() - 1) / 2);
    println!("Hasse edges: divides {} ({}), the chain {}", cov.len(), pairs(&cov, "-", false), lcov.len());
    println!("rebuilt from those {} edges plus loops: {} pairs, the same list; strict divides: {} pairs, reflexive {}", cov.len(), rebuild(&cov).len(), strict.len(), yn(tests(&strict)[0]));
    assert!(div.len() == 18 && leq.len() == 21 && strict.len() == 12 && incomp == [(2, 3), (3, 4), (4, 6)]);
    assert!(td == [true, true, true, false] && tl == [true, true, true, true] && !tests(&strict)[0] && tests(&gappy) == [true, true, false, false]);
    assert!(rebuild(&cov) == div && cov == [(1, 2), (1, 3), (2, 4), (2, 6), (3, 6), (4, 12), (6, 12)] && lcov == [(1, 2), (2, 3), (3, 4), (4, 6), (6, 12)]);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
the six divisors of 12: 1, 2, 3, 4, 6, 12 -- 36 ordered pairs to ask about
divides pairs, counting multiples: 6 + 4 + 3 + 2 + 2 + 1 = 18
less than or equal pairs:          6 + 5 + 4 + 3 + 2 + 1 = 21
test                divides  less than or equal
reflexive           yes      yes
antisymmetric       yes      yes
transitive          yes      yes
all pairs compare   no       yes
incomparable under divides: (2, 3), (3, 4), (4, 6) -- 3 of the 15 pairs
Hasse edges: divides 7 (1-2, 1-3, 2-4, 2-6, 3-6, 4-12, 6-12), the chain 5
rebuilt from those 7 edges plus loops: 18 pairs, the same list; strict divides: 12 pairs, reflexive no
ALL CHECKS PASS
```

### Lean

Lean proves the three tests for divides on every number's divisors, the Hasse diagram facts in general, and the card's numbers for 12.

- Divides is reflexive, antisymmetric and transitive on the divisors of every whole number, not just 12.
- On any finite set, the self-pairs plus the covers, linked over and over, give back exactly the pairs of the order.
- On the number line no step up is a cover, so there is no Hasse diagram to draw.
- On the six divisors of 12, divides has 18 pairs, 12 of them two different divisors. Less than or equal to has 21.
- Of the 15 pairs of different divisors, exactly 3 never compare under divides: 2 and 3, 3 and 4, 4 and 6.
- So divides is partial and not total on these six, while less than or equal to is total.
- Divides has exactly the 7 covers in the picture, and the chain has 5 arrows.
- Under divides, the divisors of 8 all compare: one queue.

The yes-no test table, the rules that fail a test, and adding 5 are left to the Python and Rust checks.

```lean
-- Orders: divides is a partial order on the divisors of any number, a finite order is rebuilt from its covers, and on the divisors of 12 divides is partial but not total while less-than-or-equal is total.
import Mathlib.NumberTheory.Divisors
import Mathlib.Order.Cover
import Mathlib.Order.Interval.Finset.Basic
import Mathlib.Logic.Relation
import Mathlib.Basic.Real.Basic

open Relation

/-- "Divides" passes the three order tests on the divisors of any whole number n:
every divisor divides itself (reflexive); if a divides b and b divides a then a = b
(antisymmetric); if a divides b and b divides c then a divides c (transitive).
So divides is a partial order on the divisors of n. -/
theorem dvd_is_partial_order_on_divisors (n : ℕ) :
    (∀ a ∈ n.divisors, a ∣ a) ∧
    (∀ a ∈ n.divisors, ∀ b ∈ n.divisors, a ∣ b → b ∣ a → a = b) ∧
    (∀ a ∈ n.divisors, ∀ b ∈ n.divisors, ∀ c ∈ n.divisors, a ∣ b → b ∣ c → a ∣ c) := by
  refine ⟨fun a _ => dvd_refl a, fun a _ b _ h1 h2 => Nat.dvd_antisymm h1 h2,
    fun a _ b _ c _ h1 h2 => dvd_trans h1 h2⟩

/-- The Hasse diagram carries the whole order on a finite set: put back the self-pairs
and chain the covers (steps up with nothing strictly in between) over and over, and
you get exactly the pairs a ≤ b. -/
theorem finite_order_rebuilt_from_covers {α : Type*} [PartialOrder α] [Finite α] (a b : α) :
    a ≤ b ↔ ReflTransGen (· ⋖ ·) a b := by
  classical
  haveI := Fintype.ofFinite α
  haveI : LocallyFiniteOrder α := Fintype.toLocallyFiniteOrder
  exact le_iff_reflTransGen_covBy

/-- On the number line there are no covers: between any two points there is another,
so no step up has nothing in between, and there is no Hasse diagram to draw. -/
theorem number_line_has_no_covers (a b : ℝ) : ¬ a ⋖ b := by
  exact not_covBy_of_denselyOrdered

/-! ### The card's worked numbers on the six divisors of 12 -/

-- The six divisors of 12.
example : Nat.divisors 12 = {1, 2, 3, 4, 6, 12} := by decide

-- 6 + 4 + 3 + 2 + 2 + 1 = 18 pairs where the first divides the second.
example : ((Nat.divisors 12 ×ˢ Nat.divisors 12).filter (fun p => p.1 ∣ p.2)).card = 18 := by
  decide

-- Of those, 18 − 6 = 12 pairs of two different divisors (strict divides; it fails reflexivity).
example : ((Nat.divisors 12 ×ˢ Nat.divisors 12).filter
    (fun p => p.1 ∣ p.2 ∧ p.1 ≠ p.2)).card = 12 := by
  decide

-- 6 + 5 + 4 + 3 + 2 + 1 = 21 pairs where the first is less than or equal to the second.
example : ((Nat.divisors 12 ×ˢ Nat.divisors 12).filter (fun p => p.1 ≤ p.2)).card = 21 := by
  decide

-- 6 × 5 ÷ 2 = 15 pairs of two different divisors in all.
example : ((Nat.divisors 12 ×ˢ Nat.divisors 12).filter (fun p => p.1 < p.2)).card = 15 := by
  decide

-- The 3 pairs that never compare under divides: 2 and 3, 3 and 4, 4 and 6.
example : (Nat.divisors 12 ×ˢ Nat.divisors 12).filter
    (fun p => p.1 < p.2 ∧ ¬ p.1 ∣ p.2 ∧ ¬ p.2 ∣ p.1) = {(2, 3), (3, 4), (4, 6)} := by
  decide

-- Divides fails comparability on the divisors of 12: it is not a total order there.
example : ¬ ∀ a ∈ Nat.divisors 12, ∀ b ∈ Nat.divisors 12, a ∣ b ∨ b ∣ a := by
  decide

-- Less than or equal passes comparability on the same six: a total order.
example : ∀ a ∈ Nat.divisors 12, ∀ b ∈ Nat.divisors 12, a ≤ b ∨ b ≤ a := by
  decide

-- The Hasse diagram of divides: exactly the 7 covers 1-2, 1-3, 2-4, 2-6, 3-6, 4-12, 6-12.
example : (Nat.divisors 12 ×ˢ Nat.divisors 12).filter
    (fun p => p.1 ∣ p.2 ∧ p.1 ≠ p.2 ∧
      ∀ m ∈ Nat.divisors 12, m ≠ p.1 → m ≠ p.2 → ¬ (p.1 ∣ m ∧ m ∣ p.2)) =
    {(1, 2), (1, 3), (2, 4), (2, 6), (3, 6), (4, 12), (6, 12)} := by
  decide

-- The chain under less than or equal takes 5 arrows, each number to the next.
example : (Nat.divisors 12 ×ˢ Nat.divisors 12).filter
    (fun p => p.1 < p.2 ∧ ∀ m ∈ Nat.divisors 12, ¬ (p.1 < m ∧ m < p.2)) =
    {(1, 2), (2, 3), (3, 4), (4, 6), (6, 12)} := by
  decide

-- Try changing: the divisors of 8 stack in one queue under divides.
example : ∀ a ∈ Nat.divisors 8, ∀ b ∈ Nat.divisors 8, a ∣ b ∨ b ∣ a := by
  decide

#print axioms dvd_is_partial_order_on_divisors
#print axioms finite_order_rebuilt_from_covers
#print axioms number_line_has_no_covers
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'dvd_is_partial_order_on_divisors' depends on axioms: [propext, Classical.choice, Quot.sound]
'finite_order_rebuilt_from_covers' depends on axioms: [propext, Classical.choice, Quot.sound]
'number_line_has_no_covers' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts are pinned to these numbers, so expect one to fire.
> - **Swap 12 for 8.** Use 1, 2, 4, 8: divides passes all four tests — the divisors of 8 stack in one queue, nothing incomparable.
> - **Add 5.** Divides gains 5 with itself and 1 with 5. 5 shares nothing with 2, 3, 4, 6 or 12, so pairs that never compare go from 3 to 8.

---

## The usual mistake

> [!warning]
> **Reading "incomparable" as "tied".** 2 and 3 are not equal, not level. The rule says nothing about them. A tie would need 2 to divide 3 and 3 to divide 2, and antisymmetry would make them the same number.
>
> - Assuming every order is a queue. Divides passes all three tests and is no queue: 3 of the 15 pairs never compare.
> - Reading a missing arrow as "unrelated". 2 and 3 share 1 below and 6 above, on different branches.

---

## Where you meet it in real life

- **Build tools.** In `make`, some tasks must come before others; the rest run in any order. Flattening that partial order into one list is a topological sort.
- **Version history.** In git, "is an ancestor of" passes the three tests. Two branch tips are incomparable; that is when a merge is needed.
- **Sorting.** A sort needs a total order: a comparison must answer for every pair. Reflexive, antisymmetric and transitive are three of the four tests in [Relations](01-relations.md); an order swaps out symmetric.

> **Say it back**
> An order is a rule passing three tests: everything is below or equal to itself, two things below each other are the same thing, below-then-below means below. The six divisors of 12 under "divides" pass all three, 18 pairs — but 3 of the 15 pairs never compare, so it is partial and not total. The same six under "less than or equal to" make one queue, 21 pairs. Draw only the covers and you have a Hasse diagram: 7 arrows that, with the six self-pairs, rebuild all 18.

---

## What this builds on

- [Equivalence relations and partitions](06-equivalence-relations-and-partitions.md): reflexive, symmetric and transitive is a sameness rule cutting a set into blocks. Swap symmetric for antisymmetric and it ranks instead.
- [The number line and inequalities](../02-The%20Number%20Line/02-number-line-and-inequalities.md): "less than or equal to" on the number line, the total order everything else is judged against.

## Where this goes next

- [Boolean algebra](../../03-Algebra/10-For%20the%20Curious/05-boolean-algebra-and-lattices.md): given two incomparable things, is there a nearest thing above both, and a nearest below? Lattices answer that.

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Hammack, Richard. *Book of Proof*, 3rd ed., 2018. [Book page](https://richardhammack.github.io/BookOfProof/). Chapter 11, relations and their properties.
- Velleman, Daniel J. *How to Prove It*, 3rd ed. Cambridge University Press, 2019. [doi:10.1017/9781108539890](https://doi.org/10.1017/9781108539890). Chapter 4, partial against total.
- Davey, B. A., and H. A. Priestley. *Introduction to Lattices and Order*, 2nd ed. Cambridge University Press, 2002. [doi:10.1017/CBO9780511809088](https://doi.org/10.1017/CBO9780511809088). Chapter 1, covers and Hasse diagrams.
