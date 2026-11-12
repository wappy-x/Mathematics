-- The standard convex problem: a problem that keeps convex functions at or below zero and affine functions at exactly zero has a convex set of allowed points, a local bottom of a convex objective on it is the global bottom, and the card's coffee blend costs at least 93/10 - 3√2/5 pounds a kilo, a bound one allowed blend meets.
import Mathlib.Analysis.Convex.Function
import Mathlib.Analysis.Convex.Extrema
import Mathlib.LinearAlgebra.AffineSpace.AffineMap
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Order.Bounds.Basic
import Mathlib.Tactic.NormNum

open Set

/-- A problem in standard form has a convex feasible set. The choice is `x`, a list of `n`
real numbers. Keep `m` convex functions `f i` at or below zero and `p` affine functions `h j`
(a weighted sum plus a constant) at exactly zero. Then the allowed points have no dents: any mix
of two allowed points is allowed. -/
theorem standard_form_feasible_set_is_convex {n m p : ℕ}
    (f : Fin m → (Fin n → ℝ) → ℝ) (h : Fin p → (Fin n → ℝ) →ᵃ[ℝ] ℝ)
    (hf : ∀ i, ConvexOn ℝ univ (f i)) :
    Convex ℝ {x : Fin n → ℝ | (∀ i, f i x ≤ 0) ∧ ∀ j, h j x = 0} := by
  intro x hx y hy a b ha hb hab
  refine ⟨fun i => ?_, fun j => ?_⟩
  · have key := (hf i).2 (mem_univ x) (mem_univ y) ha hb hab
    simp only [smul_eq_mul] at key
    have h1 := hx.1 i
    have h2 := hy.1 i
    nlinarith [mul_nonpos_of_nonneg_of_nonpos ha h1, mul_nonpos_of_nonneg_of_nonpos hb h2]
  · rw [Convex.combo_affine_apply hab, hx.2 j, hy.2 j]
    simp

/-- No false bottoms. Minimise a convex objective `f₀` over the feasible set of a standard-form
problem (convex `f i` at or below zero, affine `h j` at zero). If an allowed point `x` is lowest
among the allowed points near it, then it is lowest among all allowed points. -/
theorem standard_form_local_minimum_is_global {n m p : ℕ}
    (f₀ : (Fin n → ℝ) → ℝ) (f : Fin m → (Fin n → ℝ) → ℝ) (h : Fin p → (Fin n → ℝ) →ᵃ[ℝ] ℝ)
    (hf₀ : ConvexOn ℝ univ f₀) (hf : ∀ i, ConvexOn ℝ univ (f i)) (x : Fin n → ℝ)
    (hx : x ∈ {y : Fin n → ℝ | (∀ i, f i y ≤ 0) ∧ ∀ j, h j y = 0})
    (hloc : IsLocalMinOn f₀ {y : Fin n → ℝ | (∀ i, f i y ≤ 0) ∧ ∀ j, h j y = 0} x) :
    IsMinOn f₀ {y : Fin n → ℝ | (∀ i, f i y ≤ 0) ∧ ∀ j, h j y = 0} x := by
  have hS : Convex ℝ {y : Fin n → ℝ | (∀ i, f i y ≤ 0) ∧ ∀ j, h j y = 0} := by
    intro x hx y hy a b ha hb hab
    refine ⟨fun i => ?_, fun j => ?_⟩
    · have key := (hf i).2 (mem_univ x) (mem_univ y) ha hb hab
      simp only [smul_eq_mul] at key
      have h1 := hx.1 i
      have h2 := hy.1 i
      nlinarith [mul_nonpos_of_nonneg_of_nonpos ha h1, mul_nonpos_of_nonneg_of_nonpos hb h2]
    · rw [Convex.combo_affine_apply hab, hx.2 j, hy.2 j]
      simp
  exact IsMinOn.of_isLocalMinOn_of_convexOn hx hloc (hf₀.subset (subset_univ _) hS)

/-- The certificate for the blend. Shares `x 0, x 1, x 2` of Brazil, Colombia and Robusta that
add to one kilo, are never negative, give at least 1.6 percent caffeine (1.2, 1.4 and 2.4 percent
per bean) and stay within squared distance 0.04 of the house recipe (0.5, 0.3, 0.2). Their cost,
9, 12 and 6 pounds a kilo per bean, is never below 9.30 - 0.2 × √18 = 93/10 - 3√2/5 (about
£8.4515), and the blend (0.5, 0.3 - √2/10, 0.2 + √2/10) is allowed and costs exactly that. So the
optimal value p⋆ is 93/10 - 3√2/5. -/
theorem blend_optimal_value :
    IsLeast ((fun x : Fin 3 → ℝ => 9 * x 0 + 12 * x 1 + 6 * x 2) ''
      {x : Fin 3 → ℝ | x 0 + x 1 + x 2 = 1 ∧
        8 / 5 ≤ 6 / 5 * x 0 + 7 / 5 * x 1 + 12 / 5 * x 2 ∧
        (x 0 - 1 / 2) ^ 2 + (x 1 - 3 / 10) ^ 2 + (x 2 - 1 / 5) ^ 2 ≤ 1 / 25 ∧
        0 ≤ x 0 ∧ 0 ≤ x 1 ∧ 0 ≤ x 2})
      (93 / 10 - 3 * Real.sqrt 2 / 5) := by
  have hs0 : 0 ≤ Real.sqrt 2 := Real.sqrt_nonneg 2
  have hs2 : Real.sqrt 2 ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  have hs1 : 1 ≤ Real.sqrt 2 := by nlinarith
  have hs3 : Real.sqrt 2 < 3 / 2 := by nlinarith
  constructor
  · refine ⟨![1 / 2, 3 / 10 - Real.sqrt 2 / 10, 1 / 5 + Real.sqrt 2 / 10], ?_, ?_⟩
    · simp only [Set.mem_ofPred_eq, Matrix.cons_val_zero, Matrix.cons_val_one,
        Matrix.cons_val_two, Matrix.head_cons, Matrix.tail_cons]
      refine ⟨by ring, by nlinarith, by nlinarith, by norm_num, by nlinarith, by nlinarith⟩
    · simp only [Matrix.cons_val_zero, Matrix.cons_val_one,
        Matrix.cons_val_two, Matrix.head_cons, Matrix.tail_cons]
      ring
  · rintro c ⟨x, ⟨hsum, -, hdist, -, -, -⟩, rfl⟩
    show 93 / 10 - 3 * Real.sqrt 2 / 5 ≤ 9 * x 0 + 12 * x 1 + 6 * x 2
    have ht : ((x 2 - 1 / 5) - (x 1 - 3 / 10)) ^ 2 ≤ 2 / 25 := by
      nlinarith [sq_nonneg (x 1 - 3 / 10 + (x 2 - 1 / 5)), sq_nonneg (x 0 - 1 / 2)]
    have hle : (x 2 - 1 / 5) - (x 1 - 3 / 10) ≤ Real.sqrt 2 / 5 := by
      nlinarith [sq_nonneg ((x 2 - 1 / 5) - (x 1 - 3 / 10) - Real.sqrt 2 / 5)]
    nlinarith

-- The house recipe 50/30/20: cost £9.30 a kilo, caffeine 1.5 percent, short of 1.6.
example : (9 : ℚ) * (1 / 2) + 12 * (3 / 10) + 6 * (1 / 5) = 93 / 10 := by norm_num
example : (6 / 5 : ℚ) * (1 / 2) + 7 / 5 * (3 / 10) + 12 / 5 * (1 / 5) = 3 / 2 := by norm_num
example : (3 / 2 : ℚ) < 8 / 5 := by norm_num
-- The house recipe adds to one kilo and has taste 0.
example : (1 / 2 : ℚ) + 3 / 10 + 1 / 5 = 1 := by norm_num
-- Average price 9; prices minus the average are (0, 3, -3), whose squared length is 18.
example : ((9 : ℤ) + 12 + 6) / 3 = 9 := by decide
example : ((9 : ℤ) - 9, (12 : ℤ) - 9, (6 : ℤ) - 9) = (0, 3, -3) := by decide
example : (0 : ℤ) ^ 2 + 3 ^ 2 + (-3) ^ 2 = 18 := by decide
-- The ratio mistake: Brazil 7.5, Colombia 60/7, half and half 105/13, above their average 225/28.
example : (9 : ℚ) / (6 / 5) = 15 / 2 := by norm_num
example : (12 : ℚ) / (7 / 5) = 60 / 7 := by norm_num
example : ((9 + 12) / 2 : ℚ) / ((6 / 5 + 7 / 5) / 2) = 105 / 13 := by norm_num
example : ((15 / 2 : ℚ) + 60 / 7) / 2 = 225 / 28 := by norm_num
example : (225 / 28 : ℚ) < 105 / 13 := by norm_num

#print axioms standard_form_feasible_set_is_convex
#print axioms standard_form_local_minimum_is_global
#print axioms blend_optimal_value
