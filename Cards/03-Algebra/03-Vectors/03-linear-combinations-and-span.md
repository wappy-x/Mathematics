# Linear combinations and span: everything you can reach by mixing a few vectors

[Syllabus](../../../SYLLABUS.md) → [Algebra](../README.md) → [Vectors](../README.md#s03) → Linear combinations and span

---

## General Overview

A garden centre stocks two fertiliser blends. Bag A holds 10 kg of nitrogen and 5 kg of phosphorus. As a vector — a list of numbers in round brackets ([Vectors](01-vectors.md)) — that is A = (10, 5). Bag B holds 2 kg of nitrogen and 8 kg of phosphorus: B = (2, 8).

A lawn needs 14 kg of nitrogen and 21 kg of phosphorus. Can these two bags supply it?

Buy one bag of A and two bags of B. Nitrogen: 10 + 2 × 2 = 14. Phosphorus: 5 + 2 × 8 = 21. Exact, with nothing left over.

That mix — so much of one vector, so much of another, added together — is a **linear combination**. The set of every target such mixes can reach is the **span** of those vectors.

The span here is generous. Ask for (14, 22) instead and you get that too, using 34/35 of a bag of A and 15/7 bags of B. Fractions of a bag are allowed, and so are negative amounts: taking a bag back out. With these two blends nothing in the plane — the flat sheet of every pair of numbers you could name — is out of reach.

**A linear combination is one mix: this vector scaled, plus that vector scaled, added up. The span is the whole set of targets those mixes can reach.**

**What kind of fact this is:** linear combination and span are definitions; that a span is always a subspace, and that two vectors reach the whole plane exactly when their cross-number is not zero, are theorems proved on this card in Why it works.

### The picture: one bag of A, then adding bags of B

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "One bag of A, plus 0 to 3 bags of B"
    x-axis "Bags of B in the mix" [0, 1, 2, 3]
    y-axis "Kilograms in the mix" 0 --> 32
    line [10, 12, 14, 16]
    line [5, 13, 21, 29]
```

The flatter line is nitrogen, the steeper one phosphorus. Each extra bag of B lifts phosphorus by 8 and nitrogen by 2. At two bags of B they read 14 and 21: the target.

---

## The formula

Two names first, in words. The number of bags of the first blend is the unknown x, the number of bags of the second is y. Those two numbers are the **coefficients** of the mix: the amounts each vector is multiplied by.

Call the two bags $a$ and $b$ — lower case, the same two bags — and the target $t$. A linear combination of $a$ and $b$ is:

$$x\,a + y\,b$$

The target sits in the span exactly when some pair of numbers makes that combination land on it:

$$x\,a + y\,b = t$$

**Read it aloud:** some amount of the first bag, plus some amount of the second, added together, has to land exactly on what the lawn needs.

The span is the whole collection of those mixes, written span{$a$, $b$}:

$$\mathrm{span}\{a, b\} = \{\, x\,a + y\,b \ :\ x \text{ and } y \text{ any numbers} \,\}$$

Read the colon as "such that". Three vectors would mean a third amount and a third scaled term; nothing else changes.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $a$ | the first vector: a list of numbers in round brackets | bag A = (10, 5): 10 kg nitrogen, 5 kg phosphorus | raise a slot and the mix leans that way |
| $b$ | the second vector | bag B = (2, 8) | the mix leans further towards phosphorus |
| $x$ | the coefficient on $a$: how many bags of it the mix uses | 1 bag | every slot of $a$ contributes more |
| $y$ | the coefficient on $b$ | 2 bags | every slot of $b$ contributes more |
| $t$ | the target you are trying to land on | (14, 21) | the amounts needed grow with it |
| span{$a$, $b$} | every target the mixes can reach | the whole flat plane | — |
| the cross-number | one number saying whether the two vectors reach everything | 70 | nothing changes; only zero versus not-zero matters |

The cross-number of two vectors in the plane: the first slot of $a$ times the second slot of $b$, minus the first slot of $b$ times the second slot of $a$. Here, 10 × 8 − 2 × 5 = 70. Not zero, and that is the whole test: $a$ and $b$ span the entire plane. That number's real name is the **determinant**, taken further in [Determinants](../05-Solving%20Systems/04-determinants.md).

### When it holds

- **Any amounts are allowed, fractions and negatives included.** The span counts every such mix. A shop that sells only whole bags reaches far fewer targets: (14, 22) needs 34/35 of a bag of A and 15/7 bags of B, so it is in the span but not on the shelf.
- **Every vector has the same slots, in the same order.** Mixing adds slot by slot. Put phosphorus first in one bag and nitrogen first in the other, and the sums mean nothing.
- **The cross-number test needs two vectors with two slots each.** For three vectors, or vectors with more slots, it does not apply as written: write out the slot equations and solve them.
- **The two vectors point different ways.** If one is a multiple of the other, as C = (20, 10) is of A, the cross-number is 0 and the span shrinks to one line. Then (14, 21) is out of reach.

---

## Why it works

### Step 0: a vector equation is really one equation per slot

Two lists are equal when they agree slot by slot. So $x\,a + y\,b = t$ is not one equation. It is two — one for nitrogen, one for phosphorus — sharing the same two unknowns.

### Step 1: write the two slot equations out

Nitrogen: 10x + 2y = 14. Phosphorus: 5x + 8y = 21.

Two equations, two unknowns: the shape solved on [Two equations, two unknowns](../01-Letters%20and%20Equations/04-two-equations-two-unknowns.md).

### Step 2: solve, and the solution is the verdict

The answer is x = 1, y = 2. A pair of numbers exists, so (14, 21) is in the span. Had the two equations contradicted each other, the target would sit outside the span.

Membership in a span is a solve, not a squint.

### Step 3: the cross-number decides whether everything is reachable

Multiply the nitrogen equation by 5 and the phosphorus equation by 10, so both start with the same amount of x:

- 50x + 10y = 5 × 14 = 70
- 50x + 80y = 10 × 21 = 210

Subtract the first from the second: 70y = 140, so y = 2.

Look at what sits in front of the y: 80 − 10, which is 10 × 8 − 2 × 5 — the cross-number. No part of the target went into it. It came only from the two bags.

That number is the divisor for every target you will ever try. Divide by it and you have y; back-substitute and you have x. The only way it fails is a cross-number of 0, which happens exactly when one bag is a multiple of the other, adding no new direction. Bag C = (20, 10) is two bags of A: its cross-number with A is 10 × 10 − 20 × 5 = 0. Pair A with C and every mix stays stuck on the single line through (10, 5).

### Step 4: a span always closes up

Add two mixes and the result is a mix: add the amounts. Scale a mix and the result is a mix: scale the amounts. Set both amounts to zero and you get the zero vector, (0, 0), so the span always contains it.

Those three facts are precisely the test for a subspace ([Vector spaces and subspaces](02-vector-spaces-and-subspaces.md)). So the span of any list of vectors is a subspace — and the smallest one containing them: any subspace holding $a$ and $b$ must hold every mix of them too.

### The shapes a span takes

Any one vector but the zero one: its span is a line through the origin, the point (0, 0), made of every scaling of it. Two vectors pointing different ways: a flat plane. Three vectors in space, none of them a mix of the other two: all of space. A vector already a mix of the others adds nothing — the question [Linear independence](04-linear-independence.md) answers.

Once matrices exist this shortens to one line: stack the bags as the columns of a matrix and ask whether the matrix times some list of amounts hits the target ([Matrix times vector](../04-Matrices/02-matrix-times-vector.md)).

---

## Worked numbers, by hand

The lawn target, one step at a time.

| Step | Arithmetic | Value |
| --- | --- | --- |
| the nitrogen equation | 10x + 2y | 14 |
| the phosphorus equation | 5x + 8y | 21 |
| halve the nitrogen equation | 5x + 1y | 7 |
| subtract it from the phosphorus one | (8 − 1)y = 21 − 7 | 7y = 14 |
| bags of B | 14 ÷ 7 | **y = 2** |
| bags of A, with y put back in | (14 − 2 × 2) ÷ 10 | **x = 1** |
| rebuild the mix | 1 × (10, 5) + 2 × (2, 8) | **(14, 21)** |

Now ask for (14, 22) — one extra kilogram of phosphorus. The same steps run again: 22 − 7 = 15, so 7y = 15 and y = 15/7, then x = (14 − 2 × 15/7) ÷ 10 = 34/35. Both are fractions of a bag, so (14, 22) is in the span too. The span does not care whether the answer is tidy.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Buying bag A alone | (14, 7) | One vector spans a line, not a plane. 1.4 bags fixes the nitrogen and leaves the phosphorus far short. |
| One of each bag | (12, 13) | The amounts are 1 and 2, not 1 and 1. |
| Two of A and one of B | (22, 18) | The right pair of amounts, on the wrong bags. |
| Pairing A with C = (20, 10) | cross-number 0 | C is two bags of A, so the span is one line, and (14, 21) is not on it. |

The code prints the first three, and the cross-number of the fourth.

---

## Code, from first principles, and it actually runs

Nothing is imported. Every amount is reached twice. Road one is elimination in decimals, the same steps as the table above. Road two never leaves whole numbers: each amount is one cross-number divided by another, so no rounding can hide in it. Both targets go down both roads, and the amounts are multiplied back out to confirm they land.

### Python

```python
# Linear combinations and span -- the check behind the card.  Nothing is
# imported.  Fertiliser bag A = (10, 5) and bag B = (2, 8), counted in kg of
# nitrogen and kg of phosphorus.  Which targets can a mix of the two bags hit?
A, B, C = (10, 5), (2, 8), (20, 10)     # C is two bags of A, so no new direction

def mix(x, y):                          # x bags of A plus y bags of B
    return (x * A[0] + y * B[0], x * A[1] + y * B[1])

def cross(u, v):                        # the cross-number of two vectors
    return u[0] * v[1] - v[0] * u[1]

def eliminate(t):                       # road one: elimination, in decimals
    f = A[1] / A[0]                     # scale the nitrogen row by this to kill x
    y = (t[1] - f * t[0]) / (B[1] - f * B[0])
    x = (t[0] - B[0] * y) / A[0]        # back-substitute
    return x, y

def gcd(a, b):
    while b: a, b = b, a % b
    return abs(a)

def frac(n, d):                         # a whole-number fraction, tidied
    g = gcd(n, d)
    n, d = n // g, d // g
    return str(n) if d == 1 else f"{n}/{d}"

def rule(t):                            # road two: the cross-number rule, exact
    return cross(t, B), cross(A, t)     # both divided by cross(A, B)

d = cross(A, B)
print(f"bag A = {A} and bag B = {B}, in kg of nitrogen and kg of phosphorus")
print(f"{'the cross-number of A and B':<52}{d:>10}")
for t in ((14, 21), (14, 22)):
    x, y = eliminate(t)
    nx, ny = rule(t)
    g = mix(x, y)
    print(f"target {t}: elimination gives x = {x:.4f}, y = {y:.4f}")
    print(f"target {t}: the cross-number rule gives x = {frac(nx, d)}, y = {frac(ny, d)}")
    print(f"target {t}: rebuilt, {x:.4f} x A + {y:.4f} x B = ({g[0]:.4f}, {g[1]:.4f}) -> in the span")
grid = [mix(1, b) for b in (0, 1, 2, 3)]
print("one bag of A with 0, 1, 2 and 3 bags of B")
print("  nitrogen, kg    " + ", ".join(str(p[0]) for p in grid))
print("  phosphorus, kg  " + ", ".join(str(p[1]) for p in grid))
print(f"bag C = {C} is two bags of A: the cross-number of A and C is {cross(A, C)}")
m1, m2, m3 = mix(1.4, 0), mix(1, 1), mix(2, 1)
print(f"the three mistakes come out at ({m1[0]:.4f}, {m1[1]:.4f}), {m2} and {m3}")
assert rule((14, 21)) == (70, 140) and d == 70      # 14x8-2x21, 10x21-14x5, 10x8-2x5
assert rule((14, 22)) == (68, 150) and cross(A, C) == 0
assert abs(eliminate((14, 21))[0] - 1) < 1e-12 and abs(eliminate((14, 21))[1] - 2) < 1e-12
assert m2 == (12, 13) and m3 == (22, 18) and abs(m1[0] - 14) < 1e-9 and abs(m1[1] - 7) < 1e-9
print("ALL CHECKS PASS")
```

**Ran 2026-09-07 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
bag A = (10, 5) and bag B = (2, 8), in kg of nitrogen and kg of phosphorus
the cross-number of A and B                                 70
target (14, 21): elimination gives x = 1.0000, y = 2.0000
target (14, 21): the cross-number rule gives x = 1, y = 2
target (14, 21): rebuilt, 1.0000 x A + 2.0000 x B = (14.0000, 21.0000) -> in the span
target (14, 22): elimination gives x = 0.9714, y = 2.1429
target (14, 22): the cross-number rule gives x = 34/35, y = 15/7
target (14, 22): rebuilt, 0.9714 x A + 2.1429 x B = (14.0000, 22.0000) -> in the span
one bag of A with 0, 1, 2 and 3 bags of B
  nitrogen, kg    10, 12, 14, 16
  phosphorus, kg  5, 13, 21, 29
bag C = (20, 10) is two bags of A: the cross-number of A and C is 0
the three mistakes come out at (14.0000, 7.0000), (12, 13) and (22, 18)
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Linear combinations and span -- the same check as the Python, in Rust.  No
// crates.  Fertiliser bag A = (10, 5) and bag B = (2, 8), counted in kg of
// nitrogen and kg of phosphorus.  Which targets can a mix of the two bags hit?
const A: (i64, i64) = (10, 5);
const B: (i64, i64) = (2, 8);
const C: (i64, i64) = (20, 10);         // C is two bags of A, so no new direction

fn mix_i(x: i64, y: i64) -> (i64, i64) { (x * A.0 + y * B.0, x * A.1 + y * B.1) }

fn mix_f(x: f64, y: f64) -> (f64, f64) {          // x bags of A plus y bags of B
    (x * A.0 as f64 + y * B.0 as f64, x * A.1 as f64 + y * B.1 as f64)
}

fn cross(u: (i64, i64), v: (i64, i64)) -> i64 { u.0 * v.1 - v.0 * u.1 }

fn eliminate(t: (i64, i64)) -> (f64, f64) {       // road one: elimination, in decimals
    let f = A.1 as f64 / A.0 as f64;              // scale the nitrogen row by this to kill x
    let y = (t.1 as f64 - f * t.0 as f64) / (B.1 as f64 - f * B.0 as f64);
    let x = (t.0 as f64 - B.0 as f64 * y) / A.0 as f64;   // back-substitute
    (x, y)
}

fn gcd(mut a: i64, mut b: i64) -> i64 {
    while b != 0 { let t = a % b; a = b; b = t; }
    a.abs()
}

fn frac(n: i64, d: i64) -> String {               // a whole-number fraction, tidied
    let g = gcd(n, d);
    let (n, d) = (n / g, d / g);
    if d == 1 { format!("{}", n) } else { format!("{}/{}", n, d) }
}

fn rule(t: (i64, i64)) -> (i64, i64) { (cross(t, B), cross(A, t)) }   // over cross(A, B)

fn tup(v: (i64, i64)) -> String { format!("({}, {})", v.0, v.1) }

fn main() {
    let d = cross(A, B);
    println!("bag A = {} and bag B = {}, in kg of nitrogen and kg of phosphorus", tup(A), tup(B));
    println!("{:<52}{:>10}", "the cross-number of A and B", d);
    for t in [(14_i64, 21_i64), (14, 22)] {
        let (x, y) = eliminate(t);
        let (nx, ny) = rule(t);
        let g = mix_f(x, y);
        println!("target {}: elimination gives x = {:.4}, y = {:.4}", tup(t), x, y);
        println!("target {}: the cross-number rule gives x = {}, y = {}", tup(t), frac(nx, d), frac(ny, d));
        println!("target {}: rebuilt, {:.4} x A + {:.4} x B = ({:.4}, {:.4}) -> in the span",
                 tup(t), x, y, g.0, g.1);
    }
    let grid: Vec<(i64, i64)> = (0..4).map(|b| mix_i(1, b)).collect();
    println!("one bag of A with 0, 1, 2 and 3 bags of B");
    let n: Vec<String> = grid.iter().map(|p| p.0.to_string()).collect();
    let p: Vec<String> = grid.iter().map(|p| p.1.to_string()).collect();
    println!("  nitrogen, kg    {}", n.join(", "));
    println!("  phosphorus, kg  {}", p.join(", "));
    println!("bag C = {} is two bags of A: the cross-number of A and C is {}", tup(C), cross(A, C));
    let (m1, m2, m3) = (mix_f(1.4, 0.0), mix_i(1, 1), mix_i(2, 1));
    println!("the three mistakes come out at ({:.4}, {:.4}), {} and {}", m1.0, m1.1, tup(m2), tup(m3));
    assert!(rule((14, 21)) == (70, 140) && d == 70);   // 14x8-2x21, 10x21-14x5, 10x8-2x5
    assert!(rule((14, 22)) == (68, 150) && cross(A, C) == 0);
    assert!((eliminate((14, 21)).0 - 1.0).abs() < 1e-12 && (eliminate((14, 21)).1 - 2.0).abs() < 1e-12);
    assert!(m2 == (12, 13) && m3 == (22, 18) && (m1.0 - 14.0).abs() < 1e-9 && (m1.1 - 7.0).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-07 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
bag A = (10, 5) and bag B = (2, 8), in kg of nitrogen and kg of phosphorus
the cross-number of A and B                                 70
target (14, 21): elimination gives x = 1.0000, y = 2.0000
target (14, 21): the cross-number rule gives x = 1, y = 2
target (14, 21): rebuilt, 1.0000 x A + 2.0000 x B = (14.0000, 21.0000) -> in the span
target (14, 22): elimination gives x = 0.9714, y = 2.1429
target (14, 22): the cross-number rule gives x = 34/35, y = 15/7
target (14, 22): rebuilt, 0.9714 x A + 2.1429 x B = (14.0000, 22.0000) -> in the span
one bag of A with 0, 1, 2 and 3 bags of B
  nitrogen, kg    10, 12, 14, 16
  phosphorus, kg  5, 13, 21, 29
bag C = (20, 10) is two bags of A: the cross-number of A and C is 0
the three mistakes come out at (14.0000, 7.0000), (12, 13) and (22, 18)
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the cross-number test for any two vectors with two slots, and the span facts for any list of vectors.

- Two vectors with two slots reach the whole plane exactly when their cross-number is not zero.
- The mixes of any list of vectors, with any amounts, fractions and negatives included, are exactly its span.
- That span is the smallest subspace holding the vectors: any subspace holding them holds every mix of them.
- Bags A and B reach (14, 21) and (14, 22), but bags A and C cannot reach (14, 21).
- The worked numbers, the chart's numbers and the three mistakes come out as the tables say.

The decimal amounts, such as 0.9714 bags of A, are left to the Python and Rust checks.

```lean
-- Linear combinations and span: two vectors in the plane reach every point exactly when their cross-number is not zero, the mixes of any list of vectors form the smallest subspace holding them, and the lawn target (14, 21) is reached by bags A and B but not by bags A and C.
import Mathlib.LinearAlgebra.Span.Defs
import Mathlib.Data.Real.Basic
import Mathlib.Algebra.Module.Pi
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.LinearAlgebra.Finsupp.LinearCombination
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring

/-! A vector with two slots is a function `Fin 2 → ℝ`: `a 0` is its first slot and `a 1` its
second, and `![10, 5]` is the pair (10, 5). Amounts are real numbers, so fractions and negatives
are allowed. Mathlib's `Submodule.span ℝ s` is the span of the set `s`, and `⊤` is the whole
space. A list of `k` vectors is a function `v : Fin k → V`, and a mix of them with amounts
`c : Fin k → ℝ` is `∑ i, c i • v i`. -/

/-- The cross-number test. Two vectors `a` and `b` with two slots each, mixed with any real
amounts, reach every point of the plane exactly when their cross-number, the first slot of `a`
times the second slot of `b` minus the first slot of `b` times the second slot of `a`, is not
zero. -/
theorem two_vectors_span_plane_iff_cross_number_ne_zero (a b : Fin 2 → ℝ) :
    Submodule.span ℝ ({a, b} : Set (Fin 2 → ℝ)) = ⊤ ↔ a 0 * b 1 - b 0 * a 1 ≠ 0 := by
  constructor
  · intro h
    have h0 : (Pi.single 0 1 : Fin 2 → ℝ) ∈ Submodule.span ℝ ({a, b} : Set (Fin 2 → ℝ)) := by
      rw [h]; exact Submodule.mem_top
    have h1 : (Pi.single 1 1 : Fin 2 → ℝ) ∈ Submodule.span ℝ ({a, b} : Set (Fin 2 → ℝ)) := by
      rw [h]; exact Submodule.mem_top
    rw [Submodule.mem_span_pair] at h0 h1
    obtain ⟨x, y, hxy⟩ := h0
    obtain ⟨z, w, hzw⟩ := h1
    have e1 := congrFun hxy 0
    have e2 := congrFun hxy 1
    have e3 := congrFun hzw 0
    have e4 := congrFun hzw 1
    simp at e1 e2 e3 e4
    intro hd
    have : (a 0 * b 1 - b 0 * a 1) * (x * w - y * z) = 1 := by
      linear_combination (z * a 1 + w * b 1) * e1 + e4 - (x * a 1 + y * b 1) * e3
    rw [hd] at this
    norm_num at this
  · intro hd
    rw [eq_top_iff]
    intro v _
    rw [Submodule.mem_span_pair]
    refine ⟨(v 0 * b 1 - b 0 * v 1) / (a 0 * b 1 - b 0 * a 1),
      (a 0 * v 1 - v 0 * a 1) / (a 0 * b 1 - b 0 * a 1), ?_⟩
    refine funext (Fin.forall_fin_two.mpr ⟨?_, ?_⟩)
    · simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]
      rw [div_mul_eq_mul_div, div_mul_eq_mul_div, ← add_div, div_eq_iff hd]
      ring
    · simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]
      rw [div_mul_eq_mul_div, div_mul_eq_mul_div, ← add_div, div_eq_iff hd]
      ring

/-- A span always closes up. For any list of vectors in any real vector space, the set of all
their mixes (every choice of real amounts, scaled and added up) is a subspace, it is the span
of the list, and it is the smallest subspace holding the vectors: any subspace holding every
vector of the list holds every mix of them. -/
theorem mixes_form_smallest_subspace {V : Type*} [AddCommGroup V] [Module ℝ V] {k : ℕ}
    (v : Fin k → V) :
    ((Submodule.span ℝ (Set.range v) : Set V) = {t | ∃ c : Fin k → ℝ, ∑ i, c i • v i = t}) ∧
      ∀ W : Submodule ℝ V, (∀ i, v i ∈ W) → ∀ c : Fin k → ℝ, ∑ i, c i • v i ∈ W := by
  refine ⟨?_, ?_⟩
  · ext t
    rw [SetLike.mem_coe, Submodule.mem_span_range_iff_exists_fun]
    rfl
  · intro W hW c
    exact Submodule.sum_mem _ fun i _ => W.smul_mem _ (hW i)

/-- The card's bags. With bag A = (10, 5) and bag B = (2, 8), both the lawn target (14, 21)
and the target (14, 22) are in the span. Paired with bag C = (20, 10), two bags of A, the span
shrinks to a line and (14, 21) is out of reach. -/
theorem lawn_target_in_span_of_A_and_B_not_of_A_and_C :
    (![14, 21] : Fin 2 → ℝ) ∈ Submodule.span ℝ ({![10, 5], ![2, 8]} : Set (Fin 2 → ℝ)) ∧
    (![14, 22] : Fin 2 → ℝ) ∈ Submodule.span ℝ ({![10, 5], ![2, 8]} : Set (Fin 2 → ℝ)) ∧
    (![14, 21] : Fin 2 → ℝ) ∉ Submodule.span ℝ ({![10, 5], ![20, 10]} : Set (Fin 2 → ℝ)) := by
  refine ⟨?_, ?_, ?_⟩
  · rw [Submodule.mem_span_pair]
    refine ⟨1, 2, ?_⟩
    funext i
    fin_cases i <;> norm_num
  · rw [Submodule.mem_span_pair]
    refine ⟨34 / 35, 15 / 7, ?_⟩
    funext i
    fin_cases i <;> norm_num
  · rw [Submodule.mem_span_pair]
    rintro ⟨x, y, hxy⟩
    have e1 := congrFun hxy 0
    have e2 := congrFun hxy 1
    simp at e1 e2
    linarith

-- One bag of A = (10, 5) and two bags of B = (2, 8) land exactly on the lawn target (14, 21).
example : (1 : ℤ) • (![10, 5] : Fin 2 → ℤ) + (2 : ℤ) • ![2, 8] = ![14, 21] := by decide
-- The slot equations: nitrogen 10 × 1 + 2 × 2 = 14, phosphorus 5 × 1 + 8 × 2 = 21.
example : (10 : ℤ) * 1 + 2 * 2 = 14 ∧ (5 : ℤ) * 1 + 8 * 2 = 21 := by norm_num
-- The cross-number of A and B: 10 × 8 − 2 × 5 = 70.
example : (10 : ℤ) * 8 - 2 * 5 = 70 := by norm_num
-- Step 3: 5 × 14 = 70 and 10 × 21 = 210, then 70y = 210 − 70 = 140, so y = 2.
example : (5 : ℤ) * 14 = 70 ∧ (10 : ℤ) * 21 = 210 ∧ (80 : ℤ) - 10 = 70 ∧ (70 : ℤ) * 2 = 210 - 70 := by
  norm_num
-- The worked table: 7y = 21 − 7 = 14 gives y = 2, then x = (14 − 2 × 2) ÷ 10 = 1.
example : (7 : ℤ) * 2 = 21 - 7 ∧ ((14 : ℤ) - 2 * 2) / 10 = 1 := by norm_num
-- The cross-number rule numerators for (14, 21): 14 × 8 − 2 × 21 = 70 and 10 × 21 − 14 × 5 = 140.
example : (14 : ℤ) * 8 - 2 * 21 = 70 ∧ (10 : ℤ) * 21 - 14 * 5 = 140 := by norm_num
-- (14, 22): numerators 68 and 150 over 70, which is 34/35 of a bag of A and 15/7 bags of B.
example : (14 : ℤ) * 8 - 2 * 22 = 68 ∧ (10 : ℤ) * 22 - 14 * 5 = 150 := by norm_num
example : (68 / 70 : ℚ) = 34 / 35 ∧ (150 / 70 : ℚ) = 15 / 7 := by norm_num
example : (34 / 35 : ℚ) • (![10, 5] : Fin 2 → ℚ) + (15 / 7 : ℚ) • ![2, 8] = ![14, 22] := by
  ext i; fin_cases i <;> norm_num
-- With whole bags only, (14, 22) is not on the shelf: no whole amounts x and y reach it.
example : ¬ ∃ x y : ℤ, 10 * x + 2 * y = 14 ∧ 5 * x + 8 * y = 22 := by omega
-- One bag of A with 0, 1, 2 and 3 bags of B: nitrogen 10, 12, 14, 16 and phosphorus 5, 13, 21, 29.
example : (List.range 4).map (fun y : ℕ => (10 + 2 * y, 5 + 8 * y)) =
    [(10, 5), (12, 13), (14, 21), (16, 29)] := by decide
-- Bag C = (20, 10) is two bags of A, and the cross-number of A and C is 10 × 10 − 20 × 5 = 0.
example : (2 : ℤ) • (![10, 5] : Fin 2 → ℤ) = ![20, 10] := by decide
example : (10 : ℤ) * 10 - 20 * 5 = 0 := by norm_num
-- The mistakes: 7/5 of a bag of A alone gives (14, 7); one of each gives (12, 13);
-- two of A and one of B gives (22, 18).
example : (7 / 5 : ℚ) • (![10, 5] : Fin 2 → ℚ) = ![14, 7] := by
  ext i; fin_cases i <;> norm_num
example : (1 : ℤ) • (![10, 5] : Fin 2 → ℤ) + (1 : ℤ) • ![2, 8] = ![12, 13] := by decide
example : (2 : ℤ) • (![10, 5] : Fin 2 → ℤ) + (1 : ℤ) • ![2, 8] = ![22, 18] := by decide

#print axioms two_vectors_span_plane_iff_cross_number_ne_zero
#print axioms mixes_form_smallest_subspace
#print axioms lawn_target_in_span_of_A_and_B_not_of_A_and_C
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'two_vectors_span_plane_iff_cross_number_ne_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'mixes_form_smallest_subspace' depends on axioms: [propext, Classical.choice, Quot.sound]
'lawn_target_in_span_of_A_and_B_not_of_A_and_C' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. An assert is a line that stops the program when a number comes out wrong; these are pinned to the two bags and the two targets.
> - **Move the target.** In the loop, change the second target from `(14, 22)` to `(14, 20)`. The two printed amounts change but stay ordinary numbers: still in the span. Every assert passes, because each names its own target.
> - **Make the second bag a copy of the first.** Set `B` to `(20, 10)`, two bags of A. The cross-number falls to 0, the elimination divides by zero, and the Python stops before printing an answer. Two bags pointing the same way span a line.
> - **Nudge one number in bag B.** Set `B` to `(2, 9)`. The cross-number is no longer 70, but still not zero, so the plane is still covered. The amounts move, and the first assert stops the run.

---

## The usual mistake

> [!warning]
> **Treating the span as the handful of vectors you were given, or as a short list of mixes.** It is the entire set of mixes, and it is infinite. Two bags pointing different ways reach every point of the plane — (14, 22) included — using fractional and negative amounts.
>
> - Adding the bags instead of scaling them. One of each gives (12, 13), not (14, 21).
> - Getting the amounts the wrong way round. Two of A and one of B gives (22, 18).
> - Assuming a longer list means a bigger span. Bag C = (20, 10) is two bags of A, so adding it changes nothing: cross-number 0, still one line.
> - Matching one slot and stopping. 1.4 bags of A alone hits 14 kg of nitrogen exactly and delivers (14, 7). The other slot decides.

---

## Where you meet it in real life

- **Mixing anything to a specification.** Fertiliser, paint, animal feed, concrete, alloy. Each ingredient is a vector of contents, the recipe is a linear combination, the specification is the target.
- **Portfolios.** Two funds, each with a known split across assets, blended to hit a chosen split. The span says which splits are available at all.
- **Balancing a chemical reaction.** Each compound is a vector of atom counts. Balancing hunts for a combination that lands on the target; it either exists or the equation cannot be balanced.
- **Solving equations.** Asking whether two equations in two unknowns have a solution is the same question as asking whether the target is in the span of the two columns ([Two equations, two unknowns](../01-Letters%20and%20Equations/04-two-equations-two-unknowns.md)).

> **Say it back**
> A linear combination is a mix: so much of one vector, so much of another, added together. The span is every target those mixes reach. Bag A = (10, 5) and bag B = (2, 8): one A and two B land exactly on (14, 21), so (14, 21) is in the span. To test any target, match slot by slot and solve the two equations you get. The cross-number here is 70, not zero, so these bags reach the whole plane — (14, 22) too, with fractions of a bag. One vector spans a line, two spread-out vectors a plane, three a whole space.

---

## What this builds on

- [Vector spaces and subspaces](02-vector-spaces-and-subspaces.md): what it means for a collection to be closed under adding and scaling. A span is always one of those.
- [Two equations, two unknowns](../01-Letters%20and%20Equations/04-two-equations-two-unknowns.md): the elimination that turns "can these bags reach that target?" into two numbers.

## Where this goes next

- [Linear independence](04-linear-independence.md): whether any vector in the list was redundant — already a mix of the others, adding nothing to the span.
- [Matrix times vector](../04-Matrices/02-matrix-times-vector.md): the same mix written as a matrix times a list of amounts, which shortens everything here.

Left open: when a target is in the span, is the mix that reaches it the only one?

---

## Sources

Verified 7 Sep 2026; every link below resolves to the publisher's page.

- Axler, Sheldon. *Linear Algebra Done Right*, 4th ed. Springer, 2024. [Springer](https://link.springer.com/book/10.1007/978-3-031-41026-0); open-access author edition at [linear.axler.net](https://linear.axler.net/). Defines the span of a list and proves it is the smallest subspace containing it.
- Strang, Gilbert. *Introduction to Linear Algebra*, 6th ed. Wellesley-Cambridge Press, 2023. [Author's edition page at MIT](https://math.mit.edu/~gs/linearalgebra/ila6/indexila6.html). Treats a combination of columns as the basic object, and the column span as where a target must live.
- Hefferon, Jim. *Linear Algebra*, 4th ed. Free and openly licensed. [hefferon.net](https://hefferon.net/linearalgebra/). Works membership in a span as an elimination problem, with the same arithmetic used here.
- *18.06SC Linear Algebra*. MIT OpenCourseWare, Fall 2011. [Course page](https://ocw.mit.edu/courses/18-06sc-linear-algebra-fall-2011/). Lectures and notes on the column space and when a target is reachable.
