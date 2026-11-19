-- The zero-free region: zeta has no zero on the edge line σ = 1 away from the pole, because 3 + 4 cos θ + cos 2θ = 2(1 + cos θ)² is never negative and so ζ(σ)³ |ζ(σ + it)|⁴ |ζ(σ + 2it)| ≥ 1 for every σ > 1.
import Mathlib.NumberTheory.LSeries.Nonvanishing
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic

open Complex

/-- No zero on the edge line. For every real height t other than 0, zeta does not vanish at the
point 1 + it on the edge of the critical strip. -/
theorem riemannZeta_ne_zero_on_edge_line (t : ℝ) (ht : t ≠ 0) :
    riemannZeta (1 + t * I) ≠ 0 := by
  clear ht
  have h : (1 : ℝ) ≤ (1 + t * I : ℂ).re := by simp
  exact riemannZeta_ne_zero_of_one_le_re h

/-- The three-four-one product inequality. For every real part σ > 1 and every real height t,
ζ(σ)³ |ζ(σ + it)|⁴ |ζ(σ + 2it)| is at least 1. -/
theorem three_four_one_product_ge_one (σ : ℝ) (hσ : 1 < σ) (t : ℝ) :
    1 ≤ ‖riemannZeta σ‖ ^ 3 * ‖riemannZeta (σ + t * I)‖ ^ 4 *
      ‖riemannZeta (σ + 2 * t * I)‖ := by
  have hx : 0 < σ - 1 := by linarith
  have H := DirichletCharacter.norm_LFunction_product_ge_one (N := 1)
    (1 : DirichletCharacter ℂ 1) hx t
  have e0 : ((1 : ℂ) + ((σ - 1 : ℝ) : ℂ)) = (σ : ℂ) := by push_cast; ring
  have e1' : (σ : ℂ) + I * t = (σ : ℂ) + t * I := by ring
  have e2' : (σ : ℂ) + 2 * I * t = (σ : ℂ) + 2 * t * I := by ring
  rw [e0, e1', e2', one_pow, DirichletCharacter.LFunctionTrivChar,
    DirichletCharacter.LFunction_modOne_eq] at H
  simpa [norm_mul, norm_pow] using H

/-- The three-four-one weights are never negative. For every angle θ,
3 + 4 cos θ + cos 2θ equals 2(1 + cos θ)², and so is at least 0. -/
theorem three_four_one_weight_eq_two_mul_sq_nonneg (θ : ℝ) :
    3 + 4 * Real.cos θ + Real.cos (2 * θ) = 2 * (1 + Real.cos θ) ^ 2 ∧
      0 ≤ 3 + 4 * Real.cos θ + Real.cos (2 * θ) := by
  have h : 3 + 4 * Real.cos θ + Real.cos (2 * θ) = 2 * (1 + Real.cos θ) ^ 2 := by
    rw [Real.cos_two_mul]; ring
  exact ⟨h, by rw [h]; positivity⟩

-- The weights' smallest value, 0, comes at θ = 180 degrees.
example : 3 + 4 * Real.cos Real.pi + Real.cos (2 * Real.pi) = 0 := by norm_num
-- The weights 1 + 2 cos θ dip to −1 at θ = 180 degrees.
example : 1 + 2 * Real.cos Real.pi = -1 := by norm_num
-- The zero's power 4 beats the pole's power 3: the product shrinks like (σ − 1)^(−3 + 4) = (σ − 1)^1.
example : (-3 : ℤ) + 4 = 1 := by norm_num
-- With weights 1 + cos θ the powers tie: −1 + 1 = 0, and no contradiction follows.
example : (-1 : ℤ) + 1 = 0 := by norm_num

#print axioms riemannZeta_ne_zero_on_edge_line
#print axioms three_four_one_product_ge_one
#print axioms three_four_one_weight_eq_two_mul_sq_nonneg
