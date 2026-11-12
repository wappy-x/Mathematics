-- Forward and backward error: near a simple root, the forward error equals the absolute condition number 1/|f'(x*)| times the backward error |f(x̂)| to first order, and is at most |f(x̂)|/m when every slope on the way has size at least m.
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Filter Topology Set

/-- Helper: on `[a, b]` with every slope of size at least `m`, the change in `f` over the
interval is at least `m (b - a)`. -/
theorem forward_backward_helper_mvt
    {f f' : ℝ → ℝ} {a b m : ℝ} (hab : a < b)
    (hderiv : ∀ x ∈ Icc a b, HasDerivAt f (f' x) x)
    (hslope : ∀ x ∈ Icc a b, m ≤ |f' x|) :
    m * (b - a) ≤ |f b - f a| := by
  have hcont : ContinuousOn f (Icc a b) := fun x hx => (hderiv x hx).continuousAt.continuousWithinAt
  obtain ⟨c, hc, hfc⟩ := exists_hasDerivAt_eq_slope f f' hab hcont
    (fun x hx => hderiv x (Ioo_subset_Icc_self hx))
  have hba : 0 < b - a := sub_pos.mpr hab
  have hm := hslope c (Ioo_subset_Icc_self hc)
  have heq : f b - f a = f' c * (b - a) := by
    rw [hfc]; field_simp
  rw [heq, abs_mul, abs_of_pos hba]
  exact mul_le_mul_of_nonneg_right hm hba.le

/-- The rule of thumb, for a root: forward error ≈ condition number × backward error.
Let `x*` be a root of `f` (`f x* = 0`) where the slope `f'(x*)` is not zero. For a
computed root `x̂`, the forward error is `|x̂ - x*|`, the backward error (the change to
the constant term that makes `x̂` exact) is the residual `|f x̂|`, and the absolute
condition number is `κ_abs = 1 / |f'(x*)|`. Then the ratio
`forward error / (κ_abs × backward error)` tends to 1 as `x̂` tends to `x*`:
the rule is a first-order theorem. -/
theorem forward_error_approx_condition_number_mul_backward_error
    {f : ℝ → ℝ} {f'xstar xstar : ℝ}
    (hroot : f xstar = 0) (hderiv : HasDerivAt f f'xstar xstar) (hslope : f'xstar ≠ 0) :
    Tendsto (fun xhat => |xhat - xstar| / ((1 / |f'xstar|) * |f xhat|))
      (𝓝[≠] xstar) (𝓝 1) := by
  have hT := hasDerivAt_iff_tendsto_slope.mp hderiv
  have hlim : Tendsto (fun xhat => |f'xstar| / |slope f xstar xhat|) (𝓝[≠] xstar)
      (𝓝 (|f'xstar| / |f'xstar|)) :=
    tendsto_const_nhds.div hT.abs (abs_ne_zero.mpr hslope)
  rw [div_self (abs_ne_zero.mpr hslope)] at hlim
  refine hlim.congr' ?_
  filter_upwards [self_mem_nhdsWithin] with xhat hx
  have hx' : xhat - xstar ≠ 0 := sub_ne_zero.mpr hx
  simp only [slope_def_field, hroot, sub_zero, abs_div, one_div]
  rw [div_div_eq_mul_div, div_mul_eq_div_div, div_inv_eq_mul]
  ring

/-- The guarantee: forward error ≤ backward error / smallest slope.
Let `f` have a continuous derivative `f'` on the interval between the computed root `x̂`
and the true root `x*`, with `f x* = 0` and `|f'| ≥ m > 0` there. Then
`|x̂ - x*| ≤ |f x̂| / m`. -/
theorem forward_error_le_backward_error_div_min_slope
    {f f' : ℝ → ℝ} {xhat xstar m : ℝ}
    (hderiv : ∀ x ∈ uIcc xhat xstar, HasDerivAt f (f' x) x)
    (hcont : ContinuousOn f' (uIcc xhat xstar))
    (hroot : f xstar = 0) (hm : 0 < m)
    (hslope : ∀ x ∈ uIcc xhat xstar, m ≤ |f' x|) :
    |xhat - xstar| ≤ |f xhat| / m := by
  rcases lt_trichotomy xhat xstar with h | h | h
  · rw [uIcc_of_le h.le] at hderiv hslope
    have := forward_backward_helper_mvt h hderiv hslope
    rw [hroot, zero_sub, abs_neg] at this
    rw [le_div_iff₀ hm, abs_sub_comm, abs_of_pos (sub_pos.mpr h), mul_comm]
    exact this
  · subst h
    simp only [sub_self, abs_zero]
    exact div_nonneg (abs_nonneg _) hm.le
  · rw [uIcc_of_ge h.le] at hderiv hslope
    have := forward_backward_helper_mvt h hderiv hslope
    rw [hroot, sub_zero] at this
    rw [le_div_iff₀ hm, abs_of_pos (sub_pos.mpr h), mul_comm]
    exact this

/-- For a root, the backward error is the residual: when the data `c` enters as
`f x = g x - c`, the computed `x̂` is an exact root of the changed problem
`g x - (c + Δc)` exactly when `Δc = f x̂ = g x̂ - c`. So that change is the only one that
works, and its size `|f x̂|` is the backward error. -/
theorem backward_error_eq_residual (g : ℝ → ℝ) (c xhat Δc : ℝ) :
    g xhat - (c + Δc) = 0 ↔ Δc = g xhat - c := by
  constructor <;> intro h <;> linarith

/-! ## The card's mine, in exact fractions

The NPV at year two is `f(x) = -100 x² + 230 x - c` with bill `c = 132.24 = 13224/100`.
The bisection's computed root is `x̂ = 1.159375 = 371/320`. -/

-- The true roots are 1.14 and 1.16 (rates 14% and 16%).
example : -100 * (114 / 100 : ℚ) ^ 2 + 230 * (114 / 100) - 13224 / 100 = 0 := by norm_num
example : -100 * (116 / 100 : ℚ) ^ 2 + 230 * (116 / 100) - 13224 / 100 = 0 := by norm_num

-- NPV at the peak, rate 15%, is one cent.
example : -100 * (115 / 100 : ℚ) ^ 2 + 230 * (115 / 100) - 13224 / 100 = 1 / 100 := by norm_num

-- The computed root 1.159375 has residual (backward error) 0.0012109375 dollars = 31/25600,
-- which is under half a cent, so the stop test passes.
example : -100 * (371 / 320 : ℚ) ^ 2 + 230 * (371 / 320) - 13224 / 100 = 31 / 25600 := by
  norm_num
example : (31 / 25600 : ℚ) < 1 / 200 := by norm_num

-- 1.159375 is the exact root for the changed bill 132.2412109375 = 132.24 + 31/25600.
example : -100 * (371 / 320 : ℚ) ^ 2 + 230 * (371 / 320) - (13224 / 100 + 31 / 25600) = 0 := by
  norm_num
example : (13224 / 100 + 31 / 25600 : ℚ) = 1322412109375 / 10000000000 := by norm_num

-- Forward error: 1.16 - 1.159375 = 0.000625.
example : (116 / 100 : ℚ) - 371 / 320 = 625 / 1000000 := by norm_num

-- Slope at the root: -200 × 1.16 + 230 = -2, so κ_abs = 1/2.
example : -200 * (116 / 100 : ℚ) + 230 = -2 := by norm_num

-- Slope at the computed root: size 1.875, the smallest on the way.
example : -200 * (371 / 320 : ℚ) + 230 = -(15 / 8) := by norm_num

-- Estimate 0.5 × 0.0012109375, guarantee 0.0012109375 / 1.875, true error 0.000625 between.
example : (1 / 2 : ℚ) * (31 / 25600) ≤ 625 / 1000000 ∧
    (625 / 1000000 : ℚ) ≤ (31 / 25600) / (15 / 8) := by norm_num

-- κ_rel = 0.5 × 132.24 / 1.16 = 57.
example : (1 / 2 : ℚ) * (13224 / 100) / (116 / 100) = 57 := by norm_num

-- With bill 132.25 the two roots merge at 1.15: f(x) = -(10x - 11.5)², slope 0 there.
example (x : ℚ) : -100 * x ^ 2 + 230 * x - 13225 / 100 = -(10 * x - 23 / 2) ^ 2 := by ring
example : -200 * (115 / 100 : ℚ) + 230 = 0 := by norm_num

#print axioms forward_backward_helper_mvt
#print axioms forward_error_approx_condition_number_mul_backward_error
#print axioms forward_error_le_backward_error_div_min_slope
#print axioms backward_error_eq_residual
