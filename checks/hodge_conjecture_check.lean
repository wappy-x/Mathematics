-- The Hodge conjecture: this file proves the exact whole-number and algebraic facts behind the card, namely which codimensions Lefschetz's theorems leave open, that the Fermat cubic fourfold contains its 405 planes, and the card's worked counts.
import Mathlib.RingTheory.RootsOfUnity.PrimitiveRoots
import Mathlib.Data.Complex.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Finset

/-- Lefschetz's (1, 1) theorem and hard Lefschetz settle the codimensions p = 0, 1, n − 1 and n
in every dimension n. These four values cover every codimension p from 0 to n exactly when the
dimension n is at most 3; so every variety of dimension at most 3 satisfies the conjecture, and
dimension 4 is the first with an open case. -/
theorem lefschetz_cases_cover_all_codimensions_iff (n : ℕ) :
    (∀ p ≤ n, p = 0 ∨ p = 1 ∨ p = n - 1 ∨ p = n) ↔ n ≤ 3 := by
  constructor
  · intro h
    by_contra hn
    have := h 2 (by omega)
    omega
  · intro hn p hp
    omega

/-- The codimensions p from 0 to n that the Lefschetz cases (p = 0, 1, n − 1, n) leave open
are exactly 2, 3, …, n − 2. -/
theorem lefschetz_open_codimensions (n : ℕ) :
    (range (n + 1)).filter (fun p => p ≠ 0 ∧ p ≠ 1 ∧ p ≠ n - 1 ∧ p ≠ n) = Icc 2 (n - 2) := by
  ext p
  simp only [mem_filter, mem_range, mem_Icc]
  omega

/-- Each plane x₀ = a x₁, x₂ = b x₃, x₄ = c x₅, with a³ = b³ = c³ = −1, lies on the Fermat cubic
fourfold x₀³ + x₁³ + x₂³ + x₃³ + x₄³ + x₅³ = 0: every point of the plane satisfies the equation. -/
theorem plane_lies_on_fermat_cubic {R : Type*} [CommRing R] (a b c : R)
    (ha : a ^ 3 = -1) (hb : b ^ 3 = -1) (hc : c ^ 3 = -1) (x₁ x₃ x₅ : R) :
    (a * x₁) ^ 3 + x₁ ^ 3 + (b * x₃) ^ 3 + x₃ ^ 3 + (c * x₅) ^ 3 + x₅ ^ 3 = 0 := by
  rw [mul_pow, mul_pow, mul_pow, ha, hb, hc]
  ring

#print axioms lefschetz_cases_cover_all_codimensions_iff
#print axioms lefschetz_open_codimensions
#print axioms plane_lies_on_fermat_cubic

-- The card's table of open codimensions: dimensions 1 to 6.
example : (range 4).filter (fun p => p ≠ 0 ∧ p ≠ 1 ∧ p ≠ 3 - 1 ∧ p ≠ 3) = ∅ := by decide
example : (range 5).filter (fun p => p ≠ 0 ∧ p ≠ 1 ∧ p ≠ 4 - 1 ∧ p ≠ 4) = {2} := by decide
example : (range 6).filter (fun p => p ≠ 0 ∧ p ≠ 1 ∧ p ≠ 5 - 1 ∧ p ≠ 5) = {2, 3} := by decide
example : (range 7).filter (fun p => p ≠ 0 ∧ p ≠ 1 ∧ p ≠ 6 - 1 ∧ p ≠ 6) = {2, 3, 4} := by decide

-- Monomials of degree 3 in 6 variables with every exponent at most 1: choose 3 of 6.
example : Nat.choose 6 3 = 20 := by decide
-- Hodge numbers in degree 4 add up to b₄ = 23.
example : 0 + 1 + (20 + 1) + 1 + 0 = 23 := by norm_num
-- Euler number: 3 × (sum of C(6, i) (−3)^(4 − i) for i = 0..4) = 3 × 9 = 27, so b₄ = 27 − 4 = 23.
example : (∑ i ∈ range 5, (Nat.choose 6 i : ℤ) * (-3) ^ (4 - i)) = 9 := by decide
example : (3 : ℤ) * 9 - 4 = 23 := by norm_num
-- Pontryagin classes p₁ = 6 − 9 = −3, p₂ = 15 − 6 × 9 + 81 = 42, and the signature 3 × (7 × 42 − 9) / 45 = 19.
example : (6 : ℤ) - 3 ^ 2 = -3 ∧ (15 : ℤ) - 6 * 3 ^ 2 + 3 ^ 4 = 42 := by norm_num
example : (3 : ℤ) * (7 * 42 - (-3) ^ 2) = 19 * 45 := by norm_num
-- The same signature from the Hodge numbers 0, 1, 21, 1, 0 and h^(k,k) = 1 for k = 0, 1, 3, 4.
example : ((0 : ℤ) - 1 + 21 - 1 + 0) + (1 - 1 - 1 + 1) = 19 := by norm_num
-- So H⁴ has 21 positive and 2 negative directions.
example : (23 + 19) / 2 = 21 ∧ (23 - 19) / 2 = 2 := by norm_num
-- 15 pairings of the six coordinates times 3³ choices of a, b, c: 405 planes.
example : 15 * 3 ^ 3 = 405 := by norm_num
-- h² · h² = 3 × 3 + 6 × (−1) = 3, the degree of the cubic.
example : (3 : ℤ) * 3 + 6 * (-1) = 3 := by norm_num
