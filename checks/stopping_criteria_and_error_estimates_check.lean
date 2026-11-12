-- When to stop: a residual divided by the flattest slope bounds the error, the last step of a contraction times q/(1 - q) bounds the error, and Aitken's value beats the guess it came from.
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Tactic.NormNum

open Filter Topology Set

/-! The root is `xstar`, a guess is `x`, its error is `x - xstar`, and the residual is `f x`.
For a fixed-point iteration `x_k = g x_(k-1)`, the step is `x_k - x_(k-1)`.
Aitken's value from three guesses `x_k, x_(k+1), x_(k+2)` with steps
`d₁ = x_(k+1) - x_k` and `d₂ = x_(k+2) - x_(k+1)` is `x_(k+2) - d₂ ^ 2 / (d₂ - d₁)`. -/

/-- Helper: mean value theorem lower bound on an interval. -/
theorem mvt_lower_bound (f : ℝ → ℝ) (a b m : ℝ) (hab : a < b)
    (hd : ∀ ξ ∈ Icc a b, DifferentiableAt ℝ f ξ)
    (hs : ∀ ξ ∈ Icc a b, m ≤ |deriv f ξ|) : m * (b - a) ≤ |f b - f a| := by
  obtain ⟨c, hc, hcd⟩ := exists_deriv_eq_slope f hab
    (fun ξ hξ => (hd ξ hξ).continuousAt.continuousWithinAt)
    (fun ξ hξ => (hd ξ (Ioo_subset_Icc_self hξ)).differentiableWithinAt)
  have hba : 0 < b - a := sub_pos.mpr hab
  have : f b - f a = deriv f c * (b - a) := by rw [hcd]; field_simp
  rw [this, abs_mul, abs_of_pos hba]
  exact mul_le_mul_of_nonneg_right (hs c (Ioo_subset_Icc_self hc)) hba.le

#print axioms mvt_lower_bound

/-- Helper: Aitken's error ratio in terms of the two error ratios. -/
theorem aitken_pointwise (e a b : ℝ) (hD : a * b - 2 * a + 1 ≠ 0) :
    |((b * (a * e)) - ((b * (a * e)) - a * e) ^ 2 /
        (((b * (a * e)) - a * e) - (a * e - e))) / (a * e)| ≤ |(b - a) / (a * b - 2 * a + 1)| := by
  by_cases hae : a * e = 0
  · rw [hae, div_zero, abs_zero]; exact abs_nonneg _
  · have ha : a ≠ 0 := left_ne_zero_of_mul hae
    have he : e ≠ 0 := right_ne_zero_of_mul hae
    have hden : ((b * (a * e)) - a * e) - (a * e - e) = e * (a * b - 2 * a + 1) := by ring
    rw [hden]
    have key : b * (a * e) - (b * (a * e) - a * e) ^ 2 / (e * (a * b - 2 * a + 1)) =
        a * e * ((b - a) / (a * b - 2 * a + 1)) := by
      generalize hG : a * b - 2 * a + 1 = D at hD ⊢
      field_simp
      rw [← hG]
      ring
    rw [key, mul_div_cancel_left₀ _ hae]

#print axioms aitken_pointwise

/-- Residual to error, through the slope (mean value theorem): if the root `xstar` has
`f xstar = 0`, `f` has a slope at every point between the guess `x` and the root, and that
slope is never flatter than `m > 0` there, then the error of the guess is at most the
residual divided by `m`: `|x - xstar| ≤ |f x| / m`. -/
theorem error_le_residual_div_flattest_slope (f : ℝ → ℝ) (x xstar m : ℝ)
    (hroot : f xstar = 0) (hm : 0 < m)
    (hdiff : ∀ ξ ∈ uIcc x xstar, DifferentiableAt ℝ f ξ)
    (hslope : ∀ ξ ∈ uIcc x xstar, m ≤ |deriv f ξ|) :
    |x - xstar| ≤ |f x| / m := by
  rcases lt_trichotomy x xstar with h | h | h
  · rw [uIcc_of_le h.le] at hdiff hslope
    have := mvt_lower_bound f x xstar m h hdiff hslope
    rw [hroot, zero_sub, abs_neg] at this
    rw [le_div_iff₀ hm, abs_sub_comm, abs_of_pos (sub_pos.mpr h)]; linarith
  · subst h; simp only [sub_self, abs_zero]; positivity
  · rw [uIcc_of_ge h.le] at hdiff hslope
    have := mvt_lower_bound f xstar x m h hdiff hslope
    rw [hroot, sub_zero] at this
    rw [le_div_iff₀ hm, abs_of_pos (sub_pos.mpr h)]; linarith

/-- The corrected step test (geometric-sum bound): if `g` shrinks distances by at most
`q < 1` on a set holding the previous guess and the root, and the root is a fixed point,
then the error of the new guess `g x` is at most `q / (1 - q)` times the last step. -/
theorem error_le_q_div_one_sub_q_mul_step (g : ℝ → ℝ) (S : Set ℝ) (q x xstar : ℝ)
    (hq0 : 0 ≤ q) (hq1 : q < 1)
    (hcontr : ∀ a ∈ S, ∀ b ∈ S, |g a - g b| ≤ q * |a - b|)
    (hx : x ∈ S) (hstar : xstar ∈ S) (hfix : g xstar = xstar) :
    |g x - xstar| ≤ q / (1 - q) * |g x - x| := by
  have h1 := hcontr x hx xstar hstar
  rw [hfix] at h1
  have h2 := abs_sub_le x (g x) xstar
  rw [abs_sub_comm x (g x)] at h2
  rw [div_mul_eq_mul_div, le_div_iff₀ (by linarith)]
  nlinarith [mul_le_mul_of_nonneg_left h2 hq0]

/-- Aitken's value beats the guess it came from: if each error is `q + δ_k` times the one
before, with `0 < |q| < 1` and `δ_k → 0`, then Aitken's value from `x_k, x_(k+1), x_(k+2)`
has an error that is a vanishing fraction of the error `x_(k+1) - xstar`. -/
theorem aitken_error_vanishing_fraction (x δ : ℕ → ℝ) (xstar q : ℝ)
    (hq0 : 0 < |q|) (hq1 : |q| < 1)
    (hratio : ∀ k, x (k + 1) - xstar = (q + δ (k + 1)) * (x k - xstar))
    (hδ : Tendsto δ atTop (𝓝 0)) :
    Tendsto (fun k => (x (k + 2) - (x (k + 2) - x (k + 1)) ^ 2 /
        ((x (k + 2) - x (k + 1)) - (x (k + 1) - x k)) - xstar) / (x (k + 1) - xstar))
      atTop (𝓝 0) := by
  have hA : Tendsto (fun k => q + δ (k + 1)) atTop (𝓝 q) := by
    simpa using tendsto_const_nhds.add (hδ.comp (tendsto_add_atTop_nat 1))
  have hB : Tendsto (fun k => q + δ (k + 2)) atTop (𝓝 q) := by
    simpa using tendsto_const_nhds.add (hδ.comp (tendsto_add_atTop_nat 2))
  have hq1' : q < 1 := lt_of_le_of_lt (le_abs_self q) hq1
  have hlimD : (1 - q) ^ 2 ≠ 0 := by
    have : 1 - q ≠ 0 := by linarith
    positivity
  have hD : Tendsto (fun k => (q + δ (k + 1)) * (q + δ (k + 2)) - 2 * (q + δ (k + 1)) + 1)
      atTop (𝓝 ((1 - q) ^ 2)) := by
    have := ((hA.mul hB).sub (hA.const_mul 2)).add_const 1
    convert this using 2; ring
  have hN : Tendsto (fun k => (q + δ (k + 2)) - (q + δ (k + 1))) atTop (𝓝 0) := by
    simpa using hB.sub hA
  have hlim := (hN.div hD hlimD).abs
  rw [zero_div, abs_zero] at hlim
  refine squeeze_zero_norm' ?_ hlim
  filter_upwards [hD.eventually_ne hlimD] with k hk
  rw [Real.norm_eq_abs]
  have h1 := hratio k
  have h2 := hratio (k + 1)
  have e1 : x (k + 1) = xstar + (q + δ (k + 1)) * (x k - xstar) := by linarith
  have e2 : x (k + 2) = xstar + (q + δ (k + 2)) * ((q + δ (k + 1)) * (x k - xstar)) := by
    rw [← h1]; linarith
  have := aitken_pointwise (x k - xstar) (q + δ (k + 1)) (q + δ (k + 2)) hk
  convert this using 3
  have d2 : x (k + 2) - x (k + 1) = (q + δ (k + 2)) * ((q + δ (k + 1)) * (x k - xstar)) -
      (q + δ (k + 1)) * (x k - xstar) := by rw [e2, e1]; ring
  have d1 : x (k + 1) - x k = (q + δ (k + 1)) * (x k - xstar) - (x k - xstar) := by
    rw [e1]; ring
  have t2 : x (k + 2) - xstar = (q + δ (k + 2)) * ((q + δ (k + 1)) * (x k - xstar)) := by
    rw [e2]; ring
  rw [sub_right_comm, d2, d1, t2]

/-! The card's exact worked numbers: the 7-day bill paying 100, with `t = 7/365` years.
Rates are written as fractions: 4 percent is `1/25`, 3.75 percent is `3/80`. -/

-- Bisection on 0 to 10 percent: guesses 5, 2.5 and 3.75 percent.
example : ((0 : ℚ) + 1 / 10) / 2 = 1 / 20 ∧ ((0 : ℚ) + 1 / 20) / 2 = 1 / 40 ∧
    ((1 : ℚ) / 40 + 1 / 20) / 2 = 3 / 80 := by norm_num
-- The closed form (100 - Q) / Q / t gives back the 4 percent yield behind the quote Q.
example : (100 - 100 / (1 + 1 / 25 * (7 / 365 : ℚ))) / (100 / (1 + 1 / 25 * (7 / 365 : ℚ)))
    / (7 / 365) = 1 / 25 := by norm_num
-- At 3.75 percent the price is within one cent of the quote, so the residual test stops.
example : |100 / (1 + 3 / 80 * (7 / 365 : ℚ)) - 100 / (1 + 1 / 25 * (7 / 365 : ℚ))|
    ≤ 1 / 100 := by norm_num [abs_le]
-- Yet the yield is a quarter of a percentage point wrong.
example : (1 : ℚ) / 25 - 3 / 80 = 1 / 400 := by norm_num

#print axioms error_le_residual_div_flattest_slope
#print axioms error_le_q_div_one_sub_q_mul_step
#print axioms aitken_error_vanishing_fraction
