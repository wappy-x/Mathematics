# Roots: the fractional exponents that undo powers

[Syllabus](../../../SYLLABUS.md) → [Foundations](../README.md) → [Powers, Roots and Logarithms](../README.md#s03) → Roots

---

## General Overview

You are building a square raised bed for vegetables that must cover 50 square metres. Beside it goes a cube-shaped water tank holding 8,000 litres. One question covers both: how long is a side?

Multiplying is the easy direction: 7 metres a side covers 49 square metres, nearly enough. Here you are handed the 50 and asked for the 7-and-a-bit — the backwards move, a **root**.

The bed's side is the **square root** of 50: the number that, times itself, gives 50. The tank's side is the **cube root** of 8, since 8,000 litres is 8 cubic metres: the number that, in three copies, gives 8. As powers, in the notation from [Exponents](01-exponents-and-powers.md), they are 50^(1/2) and 8^(1/3); the old sign for the first is √50. The bottom of the fraction says how many copies: 2 for the bed, 3 for the tank.

**A root is a power run backwards, and written as the exponent 1/2 or 1/3 it obeys every law powers already obey.**

**What kind of fact this is:** a definition, and Why it works shows the power laws force it.

### The picture: where the curve crosses 50

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Ground a square bed covers, against the length of its side"
    x-axis "Side of the bed, in metres" [4, 5, 6, 7, 8]
    y-axis "Ground it covers, in square metres" 0 --> 70
    line [16, 25, 36, 49, 64]
    line [50, 50, 50, 50, 50]
```

The climbing line is the ground the bed covers; the flat line is the 50 needed. They cross between 7 metres and 8.

---

## The formula

The question, written down, defines the answer:

**side × side = 50, so side = 50^(1/2) ≈ 7.071067811865**

**side × side × side = 8, so side = 8^(1/3) = 2**

**Read it aloud:** the bed's side is fifty to the power one half; the tank's side is eight to the power one third, which is 2.

| Piece | Plain meaning | In our example |
| --- | --- | --- |
| the base | what the root is taken of | 50 the bed, 8 the tank |
| the exponent 1/2 | square root: what, times itself, is the base | 50^(1/2) ≈ 7.071067811865 |
| the exponent 1/3 | cube root: what, in three copies, is the base | 8^(1/3) = 2 |
| the exponent 2/3 | cube root, then times itself | 8^(2/3) = 4, a tank face |
| the minus twin | the other number squaring to the base | ≈ −7.071067811865 |

### When it holds

- **A base of zero or more, for a square root.** Nothing times itself lands on a minus, so a negative base has none.
- **The plus answer, for a length.** −7.071067811865 also squares to 50, but no side is negative.
- **One unit for the base.** Read 8,000 litres as cubic metres and the side comes out at 20 metres, ten times too big.

---

## Why it works

### Step 0: a root is not a new operation

The same multiplication read from the other end. "Seven times seven is forty-nine" and "the square root of forty-nine is seven" are one fact, two ways.

### Step 1: why the exponent is one half

[Exponents](01-exponents-and-powers.md) gives the law: multiplying two powers of one base adds their exponents. Multiply 50^(1/2) by 50^(1/2) and the exponents add to 1 — and 50 to the power 1 is 50. So 50^(1/2) is a number that, times itself, gives 50: the square root, word for word. Which of the two, Step 3 settles.

Thirds work the same: one third, three times, adds to 1, so three copies of 8^(1/3) multiply to 8. And 8^(2/3) means cube root, then times itself: 2 times 2 is 4, a tank face.

### Step 2: finding it by hand

Guess 7. Divide 50 by the guess. A right guess hands back itself; this one does not, so one is too small, the other too big, and the side sits between. Average them: 7.071428571429.

Again, with that as the guess: 7.071067821068. Once more: 7.071067811865, and a fourth round does not move it. Each round roughly doubles the digits you can trust; the value it lands on sits on a Babylonian clay tablet 3,800 years old, for the square root of 2. Cube roots weight the guess two to one against 8 ÷ (guess × guess) — same idea, three copies.

### Step 3: the minus twin, and a second road

Two minus signs multiplied make a plus, so −7.071067811865 times itself is also 50. The equation "side × side = 50" has two answers; the bed has one, since a length cannot be negative.

Nothing times itself lands on a minus, so a negative number has no square root here. Three minus signs stay minus, so a cube keeps the sign of its side, and every ordinary number has exactly one cube root.

The tank needs no cube root at all. A litre is a cube one decimetre on a side, a tenth of a metre. Stack 8,000 into one big cube: each edge takes 20, since 20 times 20 times 20 is 8,000. Twenty decimetres is 2 metres — the code's second road, no root in it.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| the bed, first guess | 7 × 7 | 49 |
| divide and average | (7 + 50 ÷ 7) ÷ 2 | 7.071428571429 |
| round two | same again | 7.071067821068 |
| round three, settled | same again | **7.071067811865** |
| the check | that side, times itself | 50.000000000000 |
| the tank, litre way | 20 litre cubes to an edge | 2.000000000000 |
| the tank, root way | 8^(1/3) | **2.000000000000** |
| one face | 8^(2/3) | 4.000000000000 |

The bed is a shade over 7 metres a side; the tank 2 metres, its faces 4 square metres.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Halving 50 instead of rooting it | 25 | A 25-metre bed covers 625 square metres |
| Reading 8,000 litres as cubic metres | 20 | The volume is 8 cubic metres, not 8,000; 20 metres is ten times too big |
| Keeping the minus answer | −7.071067811865 | Both squares are 50; only one is a length |

---

## Code, from first principles, and it actually runs

Nothing is imported, no square-root routine called. The bed's side comes from dividing and averaging, then squared to check it lands back on 50. The tank's side comes twice over: by cube root, and by counting litre cubes.

### Python

```python
# Roots -- the check behind the card.  Nothing is imported.  A square bed that
# must cover 50 square metres, and a cube tank that must hold 8,000 litres.
# Each root is found by dividing and averaging, then multiplied back.
def sqroot(a, guess):            # divide and average: guess, a/guess, meet in the middle
    out = []
    for _ in range(4):          # a fourth round, to show it no longer moves
        guess = (guess + a / guess) / 2
        out.append(guess)
    return out
def cuberoot(a):                 # same idea, weighted: two parts old guess, one part a/(guess x guess)
    x = a
    for _ in range(60):
        x = (2 * x + a / (x * x)) / 3
    return x
steps = sqroot(50.0, 7.0)
bed, tank = steps[2], cuberoot(8.0)
litre = 20.0 / 10                # no root: 20 litre cubes to an edge, a tenth of a metre each
face = tank * tank               # 8 to the 2/3: cube root first, then multiplied by itself
print(f"{'squares of sides 4 to 8 metres':<36}" + "".join(f"{s * s:>5.0f}" for s in [4, 5, 6, 7, 8]))
for name, v in [("guess 7, divide and average", steps[0]), ("round two, closer", steps[1]),
                ("round three, and it settles", bed), ("that side squared, back to 50", bed * bed),
                ("the minus twin", -bed), ("the minus twin squared", (-bed) * (-bed)),
                ("tank side, cube root of 8", tank), ("tank side the litre way, 20 dm", litre),
                ("one face of the tank, 8 to the 2/3", face)]:
    print(f"{name:<36}{v:>18.12f}")
print(f"mistakes: 25 metres a side covers {25 * 25}; 8,000 cubic metres gives a side of {cuberoot(8000.0):.0f}")
assert abs(bed * bed - 50.0) < 1e-9 and abs((-bed) * (-bed) - 50.0) < 1e-9 and steps[3] == bed
assert abs(tank - litre) < 1e-9 and abs(tank * tank * tank - 8.0) < 1e-9 and 20 * 20 * 20 == 8000
assert abs(face - 4.0) < 1e-9 and abs(steps[0] - 7.071428571428571) < 1e-15
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
squares of sides 4 to 8 metres         16   25   36   49   64
guess 7, divide and average             7.071428571429
round two, closer                       7.071067821068
round three, and it settles             7.071067811865
that side squared, back to 50          50.000000000000
the minus twin                         -7.071067811865
the minus twin squared                 50.000000000000
tank side, cube root of 8               2.000000000000
tank side the litre way, 20 dm          2.000000000000
one face of the tank, 8 to the 2/3      4.000000000000
mistakes: 25 metres a side covers 625; 8,000 cubic metres gives a side of 20
ALL CHECKS PASS
```

### Rust

Built with `rustc --edition 2021 -O`.

```rust
// Roots -- the same check as the Python, in Rust.  No crates.  A square bed
// that must cover 50 square metres, and a cube tank that must hold 8,000
// litres.  Each root is found by dividing and averaging, then squared or
// cubed back to see whether it lands on what was asked for.
fn sqroot(a: f64, mut guess: f64) -> [f64; 4] {   // divide and average, four rounds
    let mut out = [0.0f64; 4];
    for i in 0..4 { guess = (guess + a / guess) / 2.0; out[i] = guess; }
    out
}
fn cuberoot(a: f64) -> f64 {     // same idea, weighted: two parts old guess, one part a/(guess x guess)
    let mut x = a;
    for _ in 0..60 { x = (2.0 * x + a / (x * x)) / 3.0; }
    x
}
fn main() {
    let steps = sqroot(50.0, 7.0);
    let (bed, tank) = (steps[2], cuberoot(8.0));
    let litre = 20.0 / 10.0;               // no root: 20 litre cubes to an edge, a tenth of a metre each
    let face = tank * tank;                // 8 to the 2/3: cube root, then multiplied by itself
    let mut head = format!("{:<36}", "squares of sides 4 to 8 metres");
    for s in [4.0f64, 5.0, 6.0, 7.0, 8.0] { head.push_str(&format!("{:>5.0}", s * s)); }
    println!("{}", head);
    for (name, v) in [("guess 7, divide and average", steps[0]), ("round two, closer", steps[1]),
                      ("round three, and it settles", bed), ("that side squared, back to 50", bed * bed),
                      ("the minus twin", -bed), ("the minus twin squared", (-bed) * (-bed)),
                      ("tank side, cube root of 8", tank), ("tank side the litre way, 20 dm", litre),
                      ("one face of the tank, 8 to the 2/3", face)] {
        println!("{:<36}{:>18.12}", name, v);
    }
    println!("mistakes: 25 metres a side covers {}; 8,000 cubic metres gives a side of {:.0}",
             25 * 25, cuberoot(8000.0));
    assert!((bed * bed - 50.0).abs() < 1e-9 && ((-bed) * (-bed) - 50.0).abs() < 1e-9 && steps[3] == bed);
    assert!((tank - litre).abs() < 1e-9 && (tank * tank * tank - 8.0).abs() < 1e-9 && 20 * 20 * 20 == 8000);
    assert!((face - 4.0).abs() < 1e-9 && (steps[0] - 7.071428571428571).abs() < 1e-15);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
squares of sides 4 to 8 metres         16   25   36   49   64
guess 7, divide and average             7.071428571429
round two, closer                       7.071067821068
round three, and it settles             7.071067811865
that side squared, back to 50          50.000000000000
the minus twin                         -7.071067811865
the minus twin squared                 50.000000000000
tank side, cube root of 8               2.000000000000
tank side the litre way, 20 dm          2.000000000000
one face of the tank, 8 to the 2/3      4.000000000000
mistakes: 25 metres a side covers 625; 8,000 cubic metres gives a side of 20
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the card's three root facts for every base, not just 50 and 8.

- For a base of zero or more, the exponent 1/2 gives a number of zero or more. Times itself, it is the base, and no other such number is.
- The same holds for 1/3 with three copies, and for any number of copies.
- For a base of zero or more, the numbers that square to it are exactly its square root and the minus twin. A negative base has none.
- Every ordinary number, plus or minus, has exactly one cube root.
- The tank's side, 8^(1/3), is exactly 2, and one face, 8^(2/3), is exactly 4.
- The worked sums come out exact: the squares of 4 to 8, rounds one and two from the guess 7, and the litre cubes.

The twelve-digit decimals, and the rounds that settle on them, are left to the Python and Rust checks.

```lean
-- Roots: for a base of zero or more, the power with exponent 1/n is the one number of zero or more whose n-th power is the base, a positive base has exactly two square roots and a negative one none, every real number has exactly one cube root, and the card's bed and tank numbers come out exactly as it says.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum

/-- A root is a power run backwards. For a base `a` of zero or more and a count `n` of
copies (1 or more), the power `a ^ (1/n)` is zero or more, its `n` copies multiply back to
`a`, and it is the only number of zero or more that does: the plus answer. With `n = 2`
this is the square root, with `n = 3` the cube root. -/
theorem root_is_power_run_backwards (a : ℝ) (ha : 0 ≤ a) (n : ℕ) (hn : 1 ≤ n) :
    0 ≤ a ^ ((1 : ℝ) / n) ∧ (a ^ ((1 : ℝ) / n)) ^ n = a ∧
      ∀ x : ℝ, 0 ≤ x → x ^ n = a → x = a ^ ((1 : ℝ) / n) := by
  have hn0 : n ≠ 0 := by omega
  have hinv : ((1 : ℝ) / n) = (n : ℝ)⁻¹ := one_div _
  rw [hinv]
  refine ⟨Real.rpow_nonneg ha _, ?_, ?_⟩
  · exact Real.rpow_inv_natCast_pow ha hn0
  · intro x hx hxa
    rw [← hxa]
    exact (Real.pow_rpow_inv_natCast hx hn0).symm

/-- The minus twin, and no root for a minus. For a base `a` of zero or more, the numbers
that times themselves give `a` are exactly `a ^ (1/2)` and its negative. For a negative base,
no number times itself gives it. -/
theorem square_root_has_minus_twin (a : ℝ) :
    (0 ≤ a → ∀ x : ℝ, x * x = a ↔ x = a ^ ((1 : ℝ) / 2) ∨ x = -a ^ ((1 : ℝ) / 2)) ∧
      (a < 0 → ∀ x : ℝ, x * x ≠ a) := by
  have key : ∀ b : ℝ, 0 ≤ b → b ^ ((1 : ℝ) / 2) * b ^ ((1 : ℝ) / 2) = b := by
    intro b hb
    rw [← Real.sqrt_eq_rpow]
    exact Real.mul_self_sqrt hb
  refine ⟨fun ha x => ?_, fun ha x hx => ?_⟩
  · constructor
    · intro h
      have h2 := key a ha
      have : (x - a ^ ((1 : ℝ) / 2)) * (x + a ^ ((1 : ℝ) / 2)) = 0 := by nlinarith
      rcases mul_eq_zero.mp this with h3 | h3
      · left; linarith
      · right; linarith
    · rintro (h | h)
      · rw [h]; exact key a ha
      · rw [h]; have := key a ha; nlinarith
  · nlinarith [mul_self_nonneg x]

/-- A cube keeps the sign of its side, so every number, plus or minus, has exactly one
cube root: exactly one number whose three copies multiply to it. -/
theorem every_number_has_one_cube_root (a : ℝ) : ∃! x : ℝ, x * x * x = a := by
  have inj : ∀ x y : ℝ, x * x * x = y * y * y → x = y := by
    intro x y h
    have h1 : x ^ 3 = y ^ 3 := by nlinarith
    exact (Odd.strictMono_pow (by decide : Odd 3)).injective h1
  have ex0 : ∀ b : ℝ, 0 ≤ b → ∃ x : ℝ, x * x * x = b := by
    intro b hb
    refine ⟨b ^ (((3 : ℕ) : ℝ)⁻¹), ?_⟩
    have := Real.rpow_inv_natCast_pow hb (n := 3) (by norm_num)
    calc b ^ (((3 : ℕ) : ℝ)⁻¹) * b ^ (((3 : ℕ) : ℝ)⁻¹) * b ^ (((3 : ℕ) : ℝ)⁻¹)
        = (b ^ (((3 : ℕ) : ℝ)⁻¹)) ^ 3 := by ring
      _ = b := this
  have ex : ∃ x : ℝ, x * x * x = a := by
    rcases le_or_gt 0 a with h | h
    · exact ex0 a h
    · obtain ⟨x, hx⟩ := ex0 (-a) (by linarith)
      exact ⟨-x, by nlinarith⟩
  obtain ⟨x, hx⟩ := ex
  exact ⟨x, hx, fun y hy => inj y x (by rw [hy, hx])⟩

-- The picture: squares of sides 4 to 8 metres, and 50 falls between 7 and 8 metres a side.
example : ((4 : ℕ) * 4, 5 * 5, 6 * 6, 7 * 7, 8 * 8) = (16, 25, 36, 49, 64) := by decide
example : 7 * 7 < 50 ∧ 50 < 8 * 8 := by decide
-- Divide and average, from the guess 7, in exact fractions: 7.071428571429 and 7.071067821068.
example : ((7 : ℚ) + 50 / 7) / 2 = 99 / 14 := by norm_num
example : ((99 / 14 : ℚ) + 50 / (99 / 14)) / 2 = 19601 / 2772 := by norm_num
-- Round two squares to just over 50.
example : (19601 / 2772 : ℚ) * (19601 / 2772) = 50 + 1 / (2772 * 2772) := by norm_num
-- The tank: 8,000 litres is 8 cubic metres; 20 litre cubes to an edge is 2 metres.
example : (8000 : ℚ) / 1000 = 8 := by norm_num
example : 20 * 20 * 20 = 8000 := by decide
example : (20 : ℚ) / 10 = 2 := by norm_num
example : 2 * 2 * 2 = 8 := by decide
-- The tank side as a root, and one face as 8 to the 2/3.
example : (8 : ℝ) ^ ((1 : ℝ) / 3) = 2 := by
  have h : (8 : ℝ) = 2 ^ 3 := by norm_num
  rw [h, show ((1 : ℝ) / 3) = ((3 : ℕ) : ℝ)⁻¹ by norm_num]
  exact Real.pow_rpow_inv_natCast (by norm_num) (by norm_num)
example : (8 : ℝ) ^ ((2 : ℝ) / 3) = 4 := by
  have h : (8 : ℝ) = 2 ^ (3 : ℕ) := by norm_num
  have h1 : (8 : ℝ) ^ ((1 : ℝ) / 3) = 2 := by
    rw [h, show ((1 : ℝ) / 3) = ((3 : ℕ) : ℝ)⁻¹ by norm_num]
    exact Real.pow_rpow_inv_natCast (by norm_num) (by norm_num)
  have h2 : (8 : ℝ) ^ ((2 : ℝ) / 3) = (8 : ℝ) ^ ((1 : ℝ) / 3 * 2) := by norm_num
  rw [h2, Real.rpow_mul (by norm_num), h1]
  norm_num
example : 2 * 2 = 4 := by decide
-- The mistakes: halving 50 gives a 25-metre bed covering 625; 8,000 read as cubic metres gives 20.
example : (50 : ℚ) / 2 = 25 ∧ (25 : ℚ) * 25 = 625 := by norm_num
-- A bed of 49: the first guess 7 is exact, and the minus twin squares to the same.
example : (7 : ℤ) * 7 = 49 ∧ (-7 : ℤ) * (-7) = 49 := by decide

#print axioms root_is_power_run_backwards
#print axioms square_root_has_minus_twin
#print axioms every_number_has_one_cube_root
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'root_is_power_run_backwards' depends on axioms: [propext, Classical.choice, Quot.sound]
'square_root_has_minus_twin' depends on axioms: [propext, Classical.choice, Quot.sound]
'every_number_has_one_cube_root' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts are pinned to bed and tank, so expect one to fire.
> - **A hopeless starting guess.** Set it to 1 instead of 7: four rounds still fall short, and the asserts fire.
> - **A bed of 49.** Round one lands exact, and the first assert fires against 50.

---

## The usual mistake

> [!warning]
> **Treating a root as a division.** The square root of 50 is not 50 halved. Halving asks what you *add* to itself to get 50; rooting asks what you *multiply*. Halving gives 25, and a 25-metre bed covers 625 square metres.
>
> - **Losing the minus twin.** Both 7.071067811865 and −7.071067811865 square to 50. The situation picks the length.
> - **Rooting the number, not the unit.** The cube root of 8,000 litres is 20 decimetres — 2 metres, not 20.
> - **Expecting a tidy answer.** The tank's side is exactly 2; the bed's never finishes: [Irrational numbers](../02-The%20Number%20Line/03-irrational-numbers.md).

---

## Where you meet it in real life

- **Sizing anything square or cubic.** Tanks, floors, crates, beds: you have the capacity and need the edge.
- **A sheet of A4 paper.** Long side divided by short side is the square root of 2 — which is why folding it in half keeps the shape: [Irrational numbers](../02-The%20Number%20Line/03-irrational-numbers.md).
- **The square-root key.** No calculator looks the answer up. It runs a few rounds of divide-and-average and stops when the digits settle.

> **Say it back**
> A root runs a power backwards: you have the result and want the number multiplied. The bed covering 50 square metres is about 7.071067811865 metres a side; the tank holding 8,000 litres is exactly 2. As the exponents 1/2 and 1/3 they obey the power laws. By hand: guess, divide, average, repeat. Two numbers square to 50; only the plus one is a length.

---

## What this builds on

- [Exponents](01-exponents-and-powers.md): exponent notation, and the law that multiplying powers of one base adds their exponents — what forces 1/2 to mean a square root.
- [Irrational numbers](../02-The%20Number%20Line/03-irrational-numbers.md): why the bed's side never stops in digits, and the tank's is exactly 2.

## Where this goes next

- [Logarithms](05-logarithms.md): a root runs a power backwards for the base; a logarithm runs it backwards for the exponent — "what power got me here?"

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Fowler, David, and Eleanor Robson. "Square Root Approximations in Old Babylonian Mathematics: YBC 7289 in Context." *Historia Mathematica* 25, no. 4 (1998): 366–378. [doi:10.1006/hmat.1998.2209](https://doi.org/10.1006/hmat.1998.2209). The clay tablet, and what it does not show.
- Stillwell, John. *Mathematics and Its History*, 3rd ed. Springer, 2010. [doi:10.1007/978-1-4419-6053-5](https://doi.org/10.1007/978-1-4419-6053-5). Where roots came from.
