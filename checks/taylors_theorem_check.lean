-- Taylor's theorem: a function equals its degree-n Taylor polynomial plus a next term with the next derivative read strictly between anchor and target, so a ceiling on that derivative bounds the error, and four terms trap e^(1/10) in the card's window.
import Mathlib.Analysis.Calculus.Taylor
import Mathlib.Analysis.SpecialFunctions.Exponential

open Set Nat

/-- **Taylor's theorem, Lagrange's form of the remainder.** If f has n + 1 derivatives strictly
between the anchor a and the target x, with the n-th continuous up to both ends, then for x ≠ a
there is a point ξ strictly between a and x with
f(x) = Σ_{k=0}^{n} f^(k)(a)/k! · (x − a)^k + f^(n+1)(ξ)/(n+1)! · (x − a)^(n+1).
Derivatives are taken within the closed stretch from a to x, so at the anchor they are one-sided. -/
theorem taylor_lagrange_remainder (f : ℝ → ℝ) (a x : ℝ) (n : ℕ) (hx : a ≠ x)
    (hf : ContDiffOn ℝ n f (uIcc a x))
    (hf' : DifferentiableOn ℝ (iteratedDerivWithin n f (uIcc a x)) (uIoo a x)) :
    ∃ ξ ∈ uIoo a x,
      f x = (∑ k ∈ Finset.range (n + 1),
              iteratedDerivWithin k f (uIcc a x) a / (k ! : ℝ) * (x - a) ^ k)
            + iteratedDerivWithin (n + 1) f (uIcc a x) ξ / ((n + 1) ! : ℝ) * (x - a) ^ (n + 1) := by
  obtain ⟨ξ, hξ, h⟩ := taylor_mean_remainder_lagrange hx hf hf'
  refine ⟨ξ, hξ, ?_⟩
  rw [taylor_within_apply] at h
  have hs : (∑ k ∈ Finset.range (n + 1),
        ((k ! : ℝ)⁻¹ * (x - a) ^ k) • iteratedDerivWithin k f (uIcc a x) a)
      = ∑ k ∈ Finset.range (n + 1),
          iteratedDerivWithin k f (uIcc a x) a / (k ! : ℝ) * (x - a) ^ k := by
    refine Finset.sum_congr rfl fun k _ => ?_
    rw [smul_eq_mul]; ring
  rw [hs] at h
  have : iteratedDerivWithin (n + 1) f (uIcc a x) ξ * (x - a) ^ (n + 1) / ((n + 1)! : ℝ)
      = iteratedDerivWithin (n + 1) f (uIcc a x) ξ / ((n + 1)! : ℝ) * (x - a) ^ (n + 1) := by
    ring
  linarith

/-- **The error bound.** Under the same hypotheses, if the (n+1)-th derivative stays within M
everywhere between a and x, then the gap between f(x) and its degree-n Taylor polynomial is at
most M · |x − a|^(n+1) / (n+1)!. -/
theorem taylor_remainder_bound (f : ℝ → ℝ) (a x M : ℝ) (n : ℕ) (hx : a ≠ x)
    (hf : ContDiffOn ℝ n f (uIcc a x))
    (hf' : DifferentiableOn ℝ (iteratedDerivWithin n f (uIcc a x)) (uIoo a x))
    (hM : ∀ y ∈ uIoo a x, |iteratedDerivWithin (n + 1) f (uIcc a x) y| ≤ M) :
    |f x - ∑ k ∈ Finset.range (n + 1),
        iteratedDerivWithin k f (uIcc a x) a / (k ! : ℝ) * (x - a) ^ k|
      ≤ M * |x - a| ^ (n + 1) / ((n + 1) ! : ℝ) := by
  obtain ⟨ξ, hξ, h⟩ := taylor_lagrange_remainder f a x n hx hf hf'
  rw [h, add_sub_cancel_left, abs_mul, abs_div, abs_pow, Nat.abs_cast]
  have hpos : (0 : ℝ) < ((n + 1)! : ℝ) := by exact_mod_cast Nat.factorial_pos _
  rw [div_mul_eq_mul_div]
  apply div_le_div_of_nonneg_right _ hpos.le
  exact mul_le_mul_of_nonneg_right (hM ξ hξ) (by positivity)

/-- **The card's example: e^0.1 caught from both sides.** With four terms
P₃ = 1 + 0.1 + 0.1²/2! + 0.1³/3! and remainder e^ξ · 0.1⁴/4! with 0 < ξ < 0.1, the low side uses
e^ξ ≥ 1 and the high side uses e^ξ ≤ e^0.1, solved for e^0.1. No value of e is assumed. -/
theorem exp_one_tenth_window :
    (1 + 1/10 + (1/10 : ℝ) ^ 2 / 2 + (1/10 : ℝ) ^ 3 / 6) + (1/10 : ℝ) ^ 4 / 24 ≤ Real.exp (1/10) ∧
    Real.exp (1/10) ≤
      (1 + 1/10 + (1/10 : ℝ) ^ 2 / 2 + (1/10 : ℝ) ^ 3 / 6) / (1 - (1/10 : ℝ) ^ 4 / 24) := by
  have h1 := Real.sum_le_exp_of_nonneg (x := (1/10 : ℝ)) (by norm_num) 5
  have h2 := Real.exp_bound' (x := (1/10 : ℝ)) (by norm_num) (by norm_num) (n := 5) (by norm_num)
  simp only [Finset.sum_range_succ, Finset.sum_range_zero, Nat.factorial] at h1 h2
  norm_num at h1 h2 ⊢
  constructor
  · linarith
  · rw [le_div_iff₀ (by norm_num)]
    nlinarith

-- Step 1: differentiating (x − a)^3 three times leaves 3! = 3 × 2 × 1 = 6; and 0! = 1.
example : (3 : ℕ)! = 3 * 2 * 1 := by decide
example : (3 : ℕ)! = 6 := by decide
example : (0 : ℕ)! = 1 := by decide
example : (4 : ℕ)! = 24 := by decide

-- The four terms of P₃(0.1), exactly: 1 + 1/10 + 1/200 + 1/6000 = 6631/6000 (the card's 1.105166667).
example : (1 + 1/10 + (1/10 : ℚ) ^ 2 / 2 + (1/10 : ℚ) ^ 3 / 6) = 6631 / 6000 := by norm_num
example : (1/10 : ℚ) ^ 2 / 2 = 1 / 200 := by norm_num
example : (1/10 : ℚ) ^ 3 / 6 = 1 / 6000 := by norm_num

-- The remainder factor 0.1^4 / 4! = 1/240000 (the card's 0.000004167).
example : (1/10 : ℚ) ^ 4 / 24 = 1 / 240000 := by norm_num

-- The window's ends, exactly: low = 265241/240000, high = 265240/239999.
example : (6631/6000 : ℚ) + 1/240000 = 265241 / 240000 := by norm_num
example : (6631/6000 : ℚ) / (1 - 1/240000) = 265240 / 239999 := by norm_num

-- Both ends round to 1.105171 at six decimals.
example : (11051705/10000000 : ℚ) ≤ 265241 / 240000 ∧ (265240 / 239999 : ℚ) < 11051715/10000000 := by
  norm_num

-- What breaks, no factorials: 1 + 0.1 + 0.01 + 0.001 = 1.111.
example : (1 + 1/10 + (1/10 : ℚ) ^ 2 + (1/10 : ℚ) ^ 3) = 1111 / 1000 := by norm_num

-- What breaks, the corner |x − 0.05| with anchor 0, n = 1: remainder f(0.1) − (f(0) − 0.1) = 1/10,
-- and Lagrange would need f'' = 2 · (1/10) / (1/10)^2 = 20.
example : |(1/10 : ℚ) - 1/20| - (|(0 : ℚ) - 1/20| - 1/10) = 1/10 := by norm_num [abs_of_pos, abs_of_neg]
example : 2 * (1/10 : ℚ) / (1/10) ^ 2 = 20 := by norm_num

#print axioms taylor_lagrange_remainder
#print axioms taylor_remainder_bound
#print axioms exp_one_tenth_window
