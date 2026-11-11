-- Newton's method: near a root where the slope is not zero, the tangent-line step x - f(x)/f'(x) keeps every guess close, never meets a flat tangent, and squares the error each round; for the tile, x^2 - 2, the new error is exactly the old one squared over 2x; and a residual divided by the smallest slope size bounds the error.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.ContDiff.RCLike
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.Calculus.ContDiff.Deriv

open Filter Topology

/-- Helper: by the mean value theorem, slopes of size at least m force a rise of at least m
times the run. -/
theorem mvt_lower (f : ℝ → ℝ) (a b m u v : ℝ)
    (hdiff : ∀ y ∈ Set.Icc a b, DifferentiableAt ℝ f y)
    (hslope : ∀ y ∈ Set.Icc a b, m ≤ |deriv f y|)
    (hu : u ∈ Set.Icc a b) (hv : v ∈ Set.Icc a b) (huv : u < v) :
    m * (v - u) ≤ |f v - f u| := by
  have hsub : Set.Icc u v ⊆ Set.Icc a b := Set.Icc_subset_Icc hu.1 hv.2
  obtain ⟨c, hc, hcd⟩ := exists_deriv_eq_slope f huv
    (fun y hy => (hdiff y (hsub hy)).continuousAt.continuousWithinAt)
    (fun y hy => (hdiff y (hsub (Set.Ioo_subset_Icc_self hy))).differentiableWithinAt)
  have hm := hslope c (hsub (Set.Ioo_subset_Icc_self hc))
  rw [hcd, abs_div, abs_of_pos (sub_pos.mpr huv), le_div_iff₀ (sub_pos.mpr huv)] at hm
  exact hm

#print axioms mvt_lower

/-- Local quadratic convergence of Newton's method. Let f have a continuous second derivative
near a root r (f(r) = 0) where the slope is not zero (f'(r) ≠ 0). Then there is a distance
δ > 0 and a constant K such that from any start x₀ within δ of r, every Newton guess
x_{n+1} = x_n - f(x_n)/f'(x_n) stays within δ of r, never lands on a flat point, has an error
at most K times the last error squared and at most half the last error, and the guesses tend
to r. -/
theorem newton_quadratic_convergence (f : ℝ → ℝ) (r : ℝ)
    (hf : ContDiffAt ℝ 2 f r) (hr : f r = 0) (hd : deriv f r ≠ 0) :
    ∃ δ > 0, ∃ K ≥ 0, ∀ x₀ : ℝ, |x₀ - r| ≤ δ →
      (∀ n : ℕ,
        |(fun x => x - f x / deriv f x)^[n] x₀ - r| ≤ δ ∧
        deriv f ((fun x => x - f x / deriv f x)^[n] x₀) ≠ 0 ∧
        |(fun x => x - f x / deriv f x)^[n + 1] x₀ - r|
          ≤ K * |(fun x => x - f x / deriv f x)^[n] x₀ - r| ^ 2 ∧
        |(fun x => x - f x / deriv f x)^[n + 1] x₀ - r|
          ≤ |(fun x => x - f x / deriv f x)^[n] x₀ - r| / 2) ∧
      Tendsto (fun n : ℕ => (fun x => x - f x / deriv f x)^[n] x₀) atTop (𝓝 r) := by
  set N : ℝ → ℝ := fun x => x - f x / deriv f x with hN
  have h1 : ContDiffAt ℝ 1 (deriv f) r := hf.derivWithin (by norm_num)
  obtain ⟨L, t, ht, hL⟩ := h1.exists_lipschitzOnWith
  have hev : ∀ᶠ y in 𝓝 r, ContDiffAt ℝ 2 f y := hf.eventually (by simp)
  set c := |deriv f r| / 2 with hc_def
  have hc : 0 < c := by positivity
  have hev2 : ∀ᶠ y in 𝓝 r, c < |deriv f y| :=
    (continuous_abs.continuousAt.comp h1.continuousAt).eventually
      (lt_mem_nhds (show c < |deriv f r| by rw [hc_def]; linarith [abs_pos.mpr hd]))
  obtain ⟨ε, hε, hball⟩ := Metric.eventually_nhds_iff.mp ((hev.and hev2).and ht)
  set ε' := ε / 2 with hε'
  have hε'pos : 0 < ε' := by positivity
  have hP : ∀ y, |y - r| ≤ ε' →
      DifferentiableAt ℝ f y ∧ c < |deriv f y| ∧ y ∈ t := by
    intro y hy
    have := hball (y := y) (by rw [Real.dist_eq]; linarith)
    exact ⟨this.1.1.differentiableAt (by norm_num), this.1.2, this.2⟩
  have Lnn : (0 : ℝ) ≤ L := L.2
  have key : ∀ x, |x - r| ≤ ε' →
      deriv f x ≠ 0 ∧ |N x - r| ≤ (L / c) * |x - r| ^ 2 := by
    intro x hx
    obtain ⟨hxd, hxc, hxt⟩ := hP x hx
    have hfx0 : deriv f x ≠ 0 := by
      intro h0; rw [h0, abs_zero] at hxc; linarith
    refine ⟨hfx0, ?_⟩
    have hmem : ∀ y ∈ Set.uIcc x r, |y - r| ≤ |x - r| ∧ |y - x| ≤ |x - r| := by
      intro y hy
      have h1 := Set.abs_sub_right_of_mem_uIcc hy
      have h2 := Set.abs_sub_left_of_mem_uIcc hy
      rw [abs_sub_comm r y, abs_sub_comm r x] at h1
      rw [abs_sub_comm r x] at h2
      exact ⟨h1, h2⟩
    set g : ℝ → ℝ := fun y => f y - deriv f x * y with hg
    have hgd : ∀ y ∈ Set.uIcc x r, HasDerivWithinAt g (deriv f y - deriv f x) (Set.uIcc x r) y := by
      intro y hy
      have hyP := hP y (le_trans (hmem y hy).1 hx)
      have := hyP.1.hasDerivAt.sub ((hasDerivAt_id' y).const_mul (deriv f x))
      rw [mul_one] at this
      exact this.hasDerivWithinAt
    have hbound : ∀ y ∈ Set.uIcc x r, ‖deriv f y - deriv f x‖ ≤ L * |x - r| := by
      intro y hy
      have hyP := hP y (le_trans (hmem y hy).1 hx)
      have := hL.dist_le_mul y hyP.2.2 x hxt
      rw [Real.dist_eq, Real.dist_eq] at this
      rw [Real.norm_eq_abs]
      calc |deriv f y - deriv f x| ≤ L * |y - x| := this
        _ ≤ L * |x - r| := mul_le_mul_of_nonneg_left (hmem y hy).2 Lnn
    have hmvt := (convex_uIcc x r).norm_image_sub_le_of_norm_hasDerivWithin_le hgd hbound
      Set.left_mem_uIcc Set.right_mem_uIcc
    simp only [hg, Real.norm_eq_abs, hr] at hmvt
    have hNx : N x - r = (0 - deriv f x * r - (f x - deriv f x * x)) / deriv f x := by
      simp only [hN]; field_simp; ring
    rw [hNx, abs_div, div_le_iff₀ (abs_pos.mpr hfx0)]
    rw [abs_sub_comm r x] at hmvt
    calc |0 - deriv f x * r - (f x - deriv f x * x)| ≤ L * |x - r| * |x - r| := hmvt
      _ = L * |x - r| ^ 2 := by ring
      _ = (L / c) * |x - r| ^ 2 * c := by field_simp
      _ ≤ (L / c) * |x - r| ^ 2 * |deriv f x| := by
        apply mul_le_mul_of_nonneg_left hxc.le; positivity
  set K : ℝ := L / c with hK
  have hKnn : 0 ≤ K := by positivity
  set δ : ℝ := min ε' (c / (2 * L + 1)) with hδ
  have hδpos : 0 < δ := lt_min hε'pos (by positivity)
  have step : ∀ x, |x - r| ≤ δ →
      deriv f x ≠ 0 ∧ |N x - r| ≤ K * |x - r| ^ 2 ∧ |N x - r| ≤ |x - r| / 2 := by
    intro x hx
    obtain ⟨h0, hq⟩ := key x (le_trans hx (min_le_left _ _))
    refine ⟨h0, hq, le_trans hq ?_⟩
    have hKd : K * |x - r| ≤ 1 / 2 := by
      calc K * |x - r| ≤ K * (c / (2 * L + 1)) :=
            mul_le_mul_of_nonneg_left (le_trans hx (min_le_right _ _)) hKnn
        _ = L / (2 * L + 1) := by rw [hK]; field_simp
        _ ≤ 1 / 2 := by rw [div_le_div_iff₀ (by positivity) (by norm_num)]; linarith
    have := abs_nonneg (x - r)
    calc K * |x - r| ^ 2 = (K * |x - r|) * |x - r| := by ring
      _ ≤ (1 / 2) * |x - r| := mul_le_mul_of_nonneg_right hKd this
      _ = |x - r| / 2 := by ring
  refine ⟨δ, hδpos, K, hKnn, fun x₀ hx₀ => ?_⟩
  have hiter : ∀ n : ℕ, |N^[n] x₀ - r| ≤ δ ∧ |N^[n] x₀ - r| ≤ |x₀ - r| * (1 / 2) ^ n := by
    intro n
    induction n with
    | zero => simp [hx₀]
    | succ n ih =>
      rw [Function.iterate_succ_apply']
      obtain ⟨_, _, h2⟩ := step _ ih.1
      refine ⟨by linarith [abs_nonneg (N^[n] x₀ - r)], ?_⟩
      rw [pow_succ]; linarith [ih.2]
  refine ⟨fun n => ?_, ?_⟩
  · obtain ⟨h0, h1, h2⟩ := step _ (hiter n).1
    refine ⟨(hiter n).1, h0, ?_, ?_⟩
    · rw [Function.iterate_succ_apply']; exact h1
    · rw [Function.iterate_succ_apply']; exact h2
  · rw [tendsto_iff_norm_sub_tendsto_zero]
    refine squeeze_zero (fun n => norm_nonneg _) (fun n => (hiter n).2) ?_
    simpa using (tendsto_pow_atTop_nhds_zero_of_lt_one (by norm_num : (0:ℝ) ≤ 1 / 2)
      (by norm_num)).const_mul |x₀ - r|

/-- The tile's exact error rule. For f(x) = x^2 - 2, with slope 2x, one Newton step from a
positive guess x gives x' = x - (x^2 - 2)/(2x), and its error from the root √2 is exactly the old
error squared over 2x. So the new error is never negative (the guess sits at or above √2), and
when the old guess was at or above √2 the new error is at most half the old one. -/
theorem tile_newton_error_squared (x : ℝ) (hx : 0 < x) :
    (x - (x ^ 2 - 2) / (2 * x)) - Real.sqrt 2 = (x - Real.sqrt 2) ^ 2 / (2 * x) ∧
    0 ≤ (x - (x ^ 2 - 2) / (2 * x)) - Real.sqrt 2 ∧
    (Real.sqrt 2 ≤ x → (x - (x ^ 2 - 2) / (2 * x)) - Real.sqrt 2 ≤ (x - Real.sqrt 2) / 2) := by
  have hs : Real.sqrt 2 ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  have heq : (x - (x ^ 2 - 2) / (2 * x)) - Real.sqrt 2 = (x - Real.sqrt 2) ^ 2 / (2 * x) := by
    field_simp
    linear_combination (-1) * hs
  refine ⟨heq, ?_, ?_⟩
  · rw [heq]; positivity
  · intro h
    rw [heq, div_le_div_iff₀ (by positivity) (by norm_num)]
    nlinarith [Real.sqrt_nonneg 2]

/-- A small residual bounds the error through the slope. On a bracket [a, b] where f has a
slope at every point and every slope has size at least m > 0, if r in the bracket is a root,
then any x in the bracket is within |f(x)|/m of r. -/
theorem residual_div_min_slope_bounds_error (f : ℝ → ℝ) (a b m x r : ℝ)
    (hdiff : ∀ y ∈ Set.Icc a b, DifferentiableAt ℝ f y)
    (hm : 0 < m) (hslope : ∀ y ∈ Set.Icc a b, m ≤ |deriv f y|)
    (hx : x ∈ Set.Icc a b) (hrI : r ∈ Set.Icc a b) (hr : f r = 0) :
    |x - r| ≤ |f x| / m := by
  rw [le_div_iff₀ hm]
  rcases lt_trichotomy x r with h | h | h
  · have := mvt_lower f a b m x r hdiff hslope hx hrI h
    rw [hr, zero_sub, abs_neg] at this
    rw [abs_of_neg (sub_neg.mpr h)]; linarith
  · subst h; simp
  · have := mvt_lower f a b m r x hdiff hslope hrI hx h
    rw [hr, sub_zero] at this
    rw [abs_of_pos (sub_pos.mpr h)]; linarith

-- The bracket: f(1) = 1 - 2 = -1 and f(2) = 4 - 2 = 2, so the signs differ.
example : (1 : ℚ) ^ 2 - 2 = -1 ∧ (2 : ℚ) ^ 2 - 2 = 2 := by norm_num
-- Step 1 by the tangent line: f(1) = -1, f'(1) = 2, so the line y = 2x - 3 meets the axis at 3/2.
example : (1 : ℚ) - ((1 : ℚ) ^ 2 - 2) / (2 * 1) = 3 / 2 ∧ 2 * (3 / 2 : ℚ) - 3 = 0 := by norm_num
-- The four tile steps, averaging the guess with 2 divided by the guess.
example : (1 / 2 : ℚ) * (1 + 2 / 1) = 3 / 2 := by norm_num
example : (1 / 2 : ℚ) * (3 / 2 + 2 / (3 / 2)) = 17 / 12 := by norm_num
example : (1 / 2 : ℚ) * (17 / 12 + 2 / (17 / 12)) = 577 / 408 := by norm_num
example : (1 / 2 : ℚ) * (577 / 408 + 2 / (577 / 408)) = 665857 / 470832 := by norm_num
-- The residual after step 4 is exactly 1/470832^2, below the stop of 1/10^10, and the
-- error bound residual ÷ 2 is below 1/10^11.
example : (665857 / 470832 : ℚ) ^ 2 - 2 = 1 / 470832 ^ 2 := by norm_num
example : (665857 / 470832 : ℚ) ^ 2 - 2 < 1 / 10 ^ 10 := by norm_num
example : ((665857 / 470832 : ℚ) ^ 2 - 2) / 2 < 1 / 10 ^ 11 := by norm_num
-- Bisection from [1, 2]: 33 halvings leave a width of at least 1/10^10, 34 get under it.
example : (1 : ℚ) / 2 ^ 34 < 1 / 10 ^ 10 ∧ 1 / 10 ^ 10 ≤ (1 : ℚ) / 2 ^ 33 := by norm_num
-- Failure 1: from 0 the tile's slope 2 * 0 is 0, so the tangent is flat.
example : (2 : ℚ) * 0 = 0 := by norm_num
-- Failure 2: x^3 - 2x + 2 from 0 goes to 1, and from 1 straight back to 0.
example : (0 : ℚ) - (0 ^ 3 - 2 * 0 + 2) / (3 * 0 ^ 2 - 2) = 1 := by norm_num
example : (1 : ℚ) - (1 ^ 3 - 2 * 1 + 2) / (3 * 1 ^ 2 - 2) = 0 := by norm_num
-- Failure 3: the tile equation times 1/10^12 has residual 1/10^12 at the start 1, below the
-- stop, while the honest bound residual ÷ smallest slope (2/10^12) is 1/2.
example : |(1 / 10 ^ 12 : ℚ) * (1 ^ 2 - 2)| < 1 / 10 ^ 10 ∧
    |(1 / 10 ^ 12 : ℚ) * (1 ^ 2 - 2)| / (2 / 10 ^ 12) = 1 / 2 := by norm_num

#print axioms newton_quadratic_convergence
#print axioms tile_newton_error_squared
#print axioms residual_div_min_slope_bounds_error
