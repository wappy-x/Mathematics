-- Birch-Swinnerton-Dyer: a whole number n above 0 is the area of a right triangle with fraction sides exactly when the curve y² = x³ − n²x has a rational point with y ≠ 0, the curve's point counts mod p obey the twist rule and give a_p = 0 for p ≡ 3 mod 4, and the card's triangles, points, counts mod p and Tunnell counts check out.
import Mathlib.AlgebraicGeometry.EllipticCurve.Affine.Basic
import Mathlib.NumberTheory.LegendreSymbol.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Int.Interval
import Mathlib.Algebra.Order.Ring.Int
import Mathlib.Tactic.NormNum

namespace BirchSwinnertonDyerCongruentNumber

open Finset

/-- `n` is a congruent number: the area of a right triangle whose three sides are positive
fractions (legs `a`, `b`, long side `c`). -/
def IsCongruent (n : ℕ) : Prop :=
  ∃ a b c : ℚ, 0 < a ∧ 0 < b ∧ 0 < c ∧ a ^ 2 + b ^ 2 = c ^ 2 ∧ a * b / 2 = n

/-- The curve `E_n : y² = x³ − n²x`, as a Mathlib Weierstrass curve over a commutative ring `R`
(coefficients `a₁ = a₂ = a₃ = a₆ = 0`, `a₄ = −n²`). -/
def E (R : Type*) [CommRing R] (n : ℤ) : WeierstrassCurve R :=
  ⟨0, 0, 0, -((n : R) ^ 2), 0⟩

/-- `N_p` for `E_n`: the number of pairs `(x, y)` mod `p` with `y² = x³ − n²x`, plus 1 for the
zero point `O`. Then `a_p = p + 1 − N_p`. -/
def Np (p : ℕ) [NeZero p] (n : ℤ) : ℕ :=
  #(univ.filter (fun q : ZMod p × ZMod p => q.2 ^ 2 = q.1 ^ 3 - (n : ZMod p) ^ 2 * q.1)) + 1

/-- The whole numbers `x` with `|x| ≤ m` and `a x² ≤ m`: the only values a coordinate with
coefficient `a ≥ 1` can take in a solution of `a x² + b y² + c z² = m`. -/
def coordRange (a m : ℕ) : Finset ℤ :=
  (Icc (-(m : ℤ)) m).filter (fun x => (a : ℤ) * x ^ 2 ≤ m)

/-- The number of whole solutions `(x, y, z)` of `a x² + b y² + c z² = m`, for `a, b, c ≥ 1`.
Every solution has each coordinate in its `coordRange`, so searching those ranges counts them all. -/
def formCount (a b c m : ℕ) : ℕ :=
  #((coordRange a m ×ˢ coordRange b m ×ˢ coordRange c m).filter
    (fun t : ℤ × ℤ × ℤ => (a : ℤ) * t.1 ^ 2 + b * t.2.1 ^ 2 + c * t.2.2 ^ 2 = m))

/-- Tunnell's count `A_n`: solutions of `2x² + y² + 8z² = n` for odd `n`; for even `n`,
of `4x² + y² + 8z² = n/2`. -/
def tunnellA (n : ℕ) : ℕ := if n % 2 = 1 then formCount 2 1 8 n else formCount 4 1 8 (n / 2)

/-- Tunnell's count `B_n`: solutions of `2x² + y² + 32z² = n` for odd `n`; for even `n`,
of `4x² + y² + 32z² = n/2`. -/
def tunnellB (n : ℕ) : ℕ := if n % 2 = 1 then formCount 2 1 32 n else formCount 4 1 32 (n / 2)

theorem point_of_triangle (n a b c : ℚ) (hb0 : b ≠ 0) (habc : a ^ 2 + b ^ 2 = c ^ 2)
    (hab : a * b = 2 * n) :
    (2 * n ^ 2 * (a + c) / b ^ 2) ^ 2 = (n * (a + c) / b) ^ 3 - n ^ 2 * (n * (a + c) / b) := by
  field_simp
  linear_combination (n ^ 3 * (a + c) * b) * habc - (2 * n ^ 3 * (a + c) ^ 2) * hab

#print axioms point_of_triangle

theorem Np_eq_sum (p : ℕ) [Fact p.Prime] (hp2 : p ≠ 2) (n : ℤ) :
    (Np p n : ℤ) = p + 1 + ∑ x : ZMod p, quadraticChar (ZMod p) (x ^ 3 - (n : ZMod p) ^ 2 * x) := by
  have hF : ringChar (ZMod p) ≠ 2 := (ZMod.ringChar_zmod_n p).substr hp2
  have h1 : #(univ.filter (fun q : ZMod p × ZMod p => q.2 ^ 2 = q.1 ^ 3 - (n : ZMod p) ^ 2 * q.1))
      = ∑ x : ZMod p, #(univ.filter (fun y : ZMod p => y ^ 2 = x ^ 3 - (n : ZMod p) ^ 2 * x)) := by
    rw [Finset.card_filter, Fintype.sum_prod_type]
    simp only [Finset.card_filter]
  unfold Np
  rw [h1]
  push_cast
  have h2 : ∀ x : ZMod p, ((#(univ.filter (fun y : ZMod p => y ^ 2 = x ^ 3 - (n : ZMod p) ^ 2 * x)) : ℕ) : ℤ)
      = quadraticChar (ZMod p) (x ^ 3 - (n : ZMod p) ^ 2 * x) + 1 := by
    intro x
    rw [← quadraticChar_card_sqrts hF]
    congr 2
    ext y; simp
  simp only [h2, Finset.sum_add_distrib, Finset.sum_const, Finset.card_univ, ZMod.card]
  simp
  ring

#print axioms Np_eq_sum

/-- Step 0 and Step 1 of the card: a whole number `n > 0` is congruent (the area of a right
triangle with fraction sides) exactly when the curve `E_n : y² = x³ − n²x` has a rational point
with `y ≠ 0`. The triangle `a, b, c` gives the point with `x = (c/2)²`, and the point gives the
triangle back. -/
theorem congruent_iff_exists_point_with_y_ne_zero (n : ℕ) (hn : 0 < n) :
    IsCongruent n ↔ ∃ x y : ℚ, (E ℚ n).toAffine.Equation x y ∧ y ≠ 0 := by
  have hnq : (0 : ℚ) < n := by exact_mod_cast hn
  constructor
  · rintro ⟨a, b, c, ha, hb, hc, habc, harea⟩
    refine ⟨n * (a + c) / b, 2 * n ^ 2 * (a + c) / b ^ 2, ?_, ?_⟩
    · rw [WeierstrassCurve.Affine.equation_iff]
      simp only [E]
      push_cast
      have hab : a * b = 2 * n := by linarith
      have hb0 : b ≠ 0 := hb.ne'
      have key := point_of_triangle (n : ℚ) a b c hb0 habc hab
      linear_combination key
    · positivity
  · rintro ⟨x, y, hxy, hy⟩
    rw [WeierstrassCurve.Affine.equation_iff] at hxy
    simp only [E] at hxy
    push_cast at hxy
    have hxy' : y ^ 2 = x * (x ^ 2 - n ^ 2) := by linear_combination hxy
    have hx0 : x ≠ 0 := by rintro rfl; simp at hxy'; exact hy hxy'
    have hx2 : x ^ 2 - n ^ 2 ≠ 0 := by
      intro h; rw [h, mul_zero] at hxy'; exact hy (pow_eq_zero_iff (by norm_num) |>.mp hxy')
    refine ⟨|(x ^ 2 - n ^ 2) / y|, |2 * n * x / y|, |(x ^ 2 + n ^ 2) / y|, ?_, ?_, ?_, ?_, ?_⟩
    · exact abs_pos.mpr (div_ne_zero hx2 hy)
    · exact abs_pos.mpr (div_ne_zero (mul_ne_zero (mul_ne_zero two_ne_zero hnq.ne') hx0) hy)
    · exact abs_pos.mpr (div_ne_zero (by positivity) hy)
    · rw [sq_abs, sq_abs, sq_abs]
      field_simp
      ring
    · rw [← abs_mul]
      have : (x ^ 2 - n ^ 2) / y * (2 * n * x / y) = 2 * n := by
        rw [div_mul_div_comm, div_eq_iff (mul_ne_zero hy hy)]
        linear_combination (-2 * (n : ℚ)) * hxy'
      rw [this, abs_of_pos (by positivity)]
      ring

/-- The pattern in the card's table: for every prime `p ≡ 3 mod 4`, the curve `y² = x³ − n²x`
has exactly `p + 1` points mod `p` counting `O`, so `a_p = 0`. -/
theorem a_p_eq_zero_of_prime_three_mod_four (p : ℕ) [Fact p.Prime] (hp : p % 4 = 3) (n : ℤ) :
    Np p n = p + 1 := by
  have hp2 : p ≠ 2 := by omega
  have hF : ringChar (ZMod p) ≠ 2 := (ZMod.ringChar_zmod_n p).substr hp2
  have hneg : quadraticChar (ZMod p) (-1) = -1 := by
    rw [quadraticChar_neg_one hF, ZMod.card]
    exact ZMod.χ₄_nat_three_mod_four hp
  set S := ∑ x : ZMod p, quadraticChar (ZMod p) (x ^ 3 - (n : ZMod p) ^ 2 * x) with hS
  have hS2 : S = -S := by
    conv_lhs => rw [hS, ← Equiv.sum_comp (Equiv.neg (ZMod p))]
    rw [hS, ← Finset.sum_neg_distrib]
    refine Finset.sum_congr rfl (fun x _ => ?_)
    have : (-x) ^ 3 - (n : ZMod p) ^ 2 * (-x) = (-1) * (x ^ 3 - (n : ZMod p) ^ 2 * x) := by ring
    simp only [Equiv.neg_apply, this, map_mul, hneg]
    ring
  have hS0 : S = 0 := by linarith
  have := Np_eq_sum p hp2 n
  rw [← hS, hS0] at this
  exact_mod_cast this

/-- The twist rule of Step 2: putting `x = n t` turns `E_n` into `E_1` with every value
multiplied by `n³`, so for a good odd prime `p` (one not dividing `2n`),
`a_p(E_n) = (n/p) · a_p(E_1)`, with `(n/p)` the Legendre symbol. -/
theorem a_p_twist_rule (p : ℕ) [Fact p.Prime] (hp2 : p ≠ 2) (n : ℤ) (hpn : ¬ (p : ℤ) ∣ n) :
    (p : ℤ) + 1 - Np p n = legendreSym p n * ((p : ℤ) + 1 - Np p 1) := by
  have hn : (n : ZMod p) ≠ 0 := by
    rwa [Ne, ZMod.intCast_zmod_eq_zero_iff_dvd]
  rw [Np_eq_sum p hp2 n, Np_eq_sum p hp2 1]
  have hsq : quadraticChar (ZMod p) (n : ZMod p) ^ 2 = 1 := quadraticChar_sq_one hn
  have key : ∑ x : ZMod p, quadraticChar (ZMod p) (x ^ 3 - (n : ZMod p) ^ 2 * x)
      = quadraticChar (ZMod p) (n : ZMod p) *
        ∑ x : ZMod p, quadraticChar (ZMod p) (x ^ 3 - ((1 : ℤ) : ZMod p) ^ 2 * x) := by
    rw [← Equiv.sum_comp (Equiv.mulLeft₀ (n : ZMod p) hn), Finset.mul_sum]
    refine Finset.sum_congr rfl (fun x _ => ?_)
    have : ((n : ZMod p) * x) ^ 3 - (n : ZMod p) ^ 2 * ((n : ZMod p) * x)
        = (n : ZMod p) * ((n : ZMod p) ^ 2 * (x ^ 3 - ((1 : ℤ) : ZMod p) ^ 2 * x)) := by
      push_cast; ring
    simp only [Equiv.mulLeft₀_apply, this, map_mul, map_pow, hsq, one_mul]
  rw [key]
  unfold legendreSym
  ring

/-! ## The card's worked numbers -/

-- The 3-4-5 triangle: area 6, so 6 is congruent.
example : (3 : ℚ) ^ 2 + 4 ^ 2 = 5 ^ 2 ∧ (3 : ℚ) * 4 / 2 = 6 := by norm_num
example : IsCongruent 6 := ⟨3, 4, 5, by norm_num⟩

-- Three squares spaced 6 apart: 25/4 − 6, 25/4, 25/4 + 6 are (1/2)², (5/2)², (7/2)².
example : (25 / 4 : ℚ) - 6 = (1 / 2) ^ 2 ∧ (25 / 4 : ℚ) = (5 / 2) ^ 2 ∧ (25 / 4 : ℚ) + 6 = (7 / 2) ^ 2 := by
  norm_num

-- Their product is 1225/64 = (35/8)², so P = (25/4, 35/8) lies on y² = x³ − 36x.
example : (1 / 4 : ℚ) * (25 / 4) * (49 / 4) = 1225 / 64 ∧ (1225 / 64 : ℚ) = (35 / 8) ^ 2 := by norm_num
example : (E ℚ 6).toAffine.Equation (25 / 4) (35 / 8) := by
  norm_num [E, WeierstrassCurve.Affine.equation_iff]

-- 2P = (1442401/19600, −1726556399/2744000) lies on E_6, and x(2P) = (1201/140)².
example : (E ℚ 6).toAffine.Equation (1442401 / 19600) (-1726556399 / 2744000) := by
  norm_num [E, WeierstrassCurve.Affine.equation_iff]
example : (1442401 / 19600 : ℚ) = (1201 / 140) ^ 2 := by norm_num

-- The triangle read back from 2P: legs 7/10 and 120/7, long side 1201/70, area 6.
example : (7 / 10 : ℚ) ^ 2 + (120 / 7) ^ 2 = (1201 / 70) ^ 2 ∧ (7 / 10 : ℚ) * (120 / 7) / 2 = 6 := by
  norm_num

-- 5 is congruent: sides 3/2, 20/3, 41/6.
example : IsCongruent 5 := ⟨3 / 2, 20 / 3, 41 / 6, by norm_num⟩

-- 23 is congruent: sides 80155/20748, 41496/3485, 905141617/72306780.
example : IsCongruent 23 := ⟨80155 / 20748, 41496 / 3485, 905141617 / 72306780, by norm_num⟩

-- 24 is congruent through 6-8-10, though 24 is not square-free.
example : IsCongruent 24 := ⟨6, 8, 10, by norm_num⟩

-- 34 is congruent: the point (−16, 120) lies on E_34.
example : (E ℚ 34).toAffine.Equation (-16) 120 := by
  norm_num [E, WeierstrassCurve.Affine.equation_iff]

-- The table of N_p for E_6.
example : Np 5 6 = 8 := by decide
example : Np 7 6 = 8 := by decide
example : Np 11 6 = 12 := by decide
example : Np 13 6 = 20 := by decide
example : Np 17 6 = 20 := by decide
example : Np 19 6 = 20 := by decide
example : Np 23 6 = 24 := by decide
example : Np 29 6 = 40 := by decide
example : Np 31 6 = 32 := by decide
example : Np 37 6 = 36 := by decide

-- Hasse's bound a_p² ≤ 4p on the table: (p, a_p) for p = 5, ..., 37.
example : [((5 : ℤ), (-2 : ℤ)), (7, 0), (11, 0), (13, -6), (17, -2), (19, 0), (23, 0), (29, -10),
    (31, 0), (37, 2)].all (fun q => q.2 ^ 2 ≤ 4 * q.1) = true := by decide

-- Tunnell's counts (A_n, B_n) from the card's table and its "What breaks".
example : tunnellA 1 = 2 ∧ tunnellB 1 = 2 := by decide
example : tunnellA 2 = 2 ∧ tunnellB 2 = 2 := by decide
example : tunnellA 3 = 4 ∧ tunnellB 3 = 4 := by decide
example : tunnellA 5 = 0 ∧ tunnellB 5 = 0 := by decide
example : tunnellA 6 = 0 ∧ tunnellB 6 = 0 := by decide
example : tunnellA 11 = 12 ∧ tunnellB 11 = 4 := by decide
example : tunnellA 17 = 16 ∧ tunnellB 17 = 4 := by decide
example : tunnellA 34 = 8 ∧ tunnellB 34 = 4 := by decide
example : tunnellA 24 = 8 ∧ tunnellB 24 = 0 := by decide

#print axioms congruent_iff_exists_point_with_y_ne_zero
#print axioms a_p_eq_zero_of_prime_three_mod_four
#print axioms a_p_twist_rule

end BirchSwinnertonDyerCongruentNumber
