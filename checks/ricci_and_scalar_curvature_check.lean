-- Ricci and scalar curvature: on a surface smooth at its centre, a small geodesic disc's area is π r² (1 − S r²/24) up to terms in r⁶, with S = 2K the scalar curvature; on the 30 m dome the error is pinned between 0 and π r⁶/(360 R⁴), and averaging the cone factor over directions gives ω_n r^n (1 − S r²/(6(n+2))) in every dimension.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.Analysis.Asymptotics.Defs
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Shift
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Asymptotics.Lemmas
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus

open Real Set Filter Asymptotics intervalIntegral
open scoped Topology

/-! A surface is written in geodesic polar coordinates about a centre point: `ρ` is the distance
from the centre measured inside the surface, `θ` the angle around it, and the length rule is
`ds² = dρ² + f(ρ)² dθ²`. The ring at distance `ρ` has length `2π f(ρ)`, so the disc of all points
within distance `r` has area `2π ∫₀ʳ f(ρ) dρ`. The Gaussian curvature at distance `ρ > 0` is
`K(ρ) = -f''(ρ)/f(ρ)`, and on a surface the scalar curvature is `S = 2K`. The metric is smooth at
the centre exactly when `f` extends to a smooth odd function with `f'(0) = 1` (a cone tip has
`f'(0) < 1`). -/

/-- If `g 0 = 0` and `g' = O(x^k)` from the right at `0`, then `g = O(x^(k+1))` there. -/
lemma ricci_bigO_succ_of_deriv (g g' : ℝ → ℝ) (k : ℕ) (hg0 : g 0 = 0)
    (hd : ∀ x, HasDerivAt g (g' x) x) (hb : g' =O[𝓝[≥] 0] (fun x => x ^ k)) :
    g =O[𝓝[≥] 0] (fun x => x ^ (k + 1)) := by
  obtain ⟨C, hC, hCb⟩ := hb.exists_pos
  rw [IsBigOWith_def] at hCb
  obtain ⟨δ, hδ, hsub⟩ := mem_nhdsGE_iff_exists_Ico_subset.mp hCb
  refine IsBigO.of_bound C ?_
  filter_upwards [Ico_mem_nhdsGE hδ] with x hx
  have hx0 : 0 ≤ x := hx.1
  have key := norm_image_sub_le_of_norm_deriv_le_segment' (f := g) (a := 0) (b := x)
    (C := C * x ^ k) (fun y _ => (hd y).hasDerivWithinAt) (fun y hy => by
      have hyδ : y ∈ Ico (0 : ℝ) δ := ⟨hy.1, lt_trans hy.2 hx.2⟩
      have h1 : ‖g' y‖ ≤ C * ‖y ^ k‖ := hsub hyδ
      rw [norm_pow, Real.norm_of_nonneg hy.1] at h1
      calc ‖g' y‖ ≤ C * y ^ k := h1
        _ ≤ C * x ^ k := by
          gcongr
          exacts [hy.1, hy.2.le]) x ⟨hx0, le_rfl⟩
  rw [hg0, sub_zero, sub_zero] at key
  rw [norm_pow, Real.norm_of_nonneg hx0, pow_succ, ← mul_assoc]
  exact key

#print axioms ricci_bigO_succ_of_deriv

/-- If `g 0 = 0` and `0 ≤ g'` on `[0, ∞)`, then `0 ≤ g` on `[0, ∞)`. -/
lemma ricci_nonneg_of_deriv_nonneg (g g' : ℝ → ℝ) (hd : ∀ x, HasDerivAt g (g' x) x)
    (h0 : g 0 = 0) (hpos : ∀ x, 0 ≤ x → 0 ≤ g' x) : ∀ x, 0 ≤ x → 0 ≤ g x := by
  intro x hx
  rcases hx.lt_or_eq with hx | hx
  · obtain ⟨c, hc, hc'⟩ := exists_hasDerivAt_eq_slope g g' hx
      (fun y _ => (hd y).continuousAt.continuousWithinAt) (fun y _ => hd y)
    rw [h0, sub_zero, sub_zero] at hc'
    have := hpos c hc.1.le
    rw [hc', le_div_iff₀ hx] at this
    linarith
  · rw [← hx, h0]

#print axioms ricci_nonneg_of_deriv_nonneg

/-- The derivative of an odd function is even (`deriv` is `0` where it fails to exist). -/
lemma ricci_deriv_even_of_odd (g : ℝ → ℝ) (hodd : ∀ x, g (-x) = -g x) (x : ℝ) :
    deriv g (-x) = deriv g x := by
  have h := congrArg (fun F => deriv F x) (funext hodd)
  simp only [deriv_comp_neg, deriv.fun_neg] at h
  linarith

#print axioms ricci_deriv_even_of_odd

/-- The derivative of an even function is odd. -/
lemma ricci_deriv_odd_of_even (g : ℝ → ℝ) (heven : ∀ x, g (-x) = g x) (x : ℝ) :
    deriv g (-x) = -deriv g x := by
  have h := congrArg (fun F => deriv F x) (funext heven)
  simp only [deriv_comp_neg] at h
  linarith

#print axioms ricci_deriv_odd_of_even

/-- Taylor bounds for cosine on `[0, ∞)`:
`1 - x²/2 + x⁴/24 - x⁶/720 ≤ cos x ≤ 1 - x²/2 + x⁴/24`. -/
lemma ricci_cos_taylor_bounds (x : ℝ) (hx : 0 ≤ x) :
    cos x ≤ 1 - x ^ 2 / 2 + x ^ 4 / 24 ∧
    1 - x ^ 2 / 2 + x ^ 4 / 24 - x ^ 6 / 720 ≤ cos x := by
  have s2 := ricci_nonneg_of_deriv_nonneg (fun x => sin x - x + x ^ 3 / 6)
    (fun x => cos x - 1 + x ^ 2 / 2)
    (fun x => (((hasDerivAt_sin x).sub (hasDerivAt_id' x)).add
      ((hasDerivAt_pow 3 x).div_const 6)).congr_deriv (by norm_num; ring))
    (by simp) (fun x _ => by nlinarith [one_sub_sq_div_two_le_cos (x := x)])
  have c2 := ricci_nonneg_of_deriv_nonneg (fun x => 1 - x ^ 2 / 2 + x ^ 4 / 24 - cos x)
    (fun x => sin x - x + x ^ 3 / 6)
    (fun x => ((((hasDerivAt_pow 2 x).div_const 2).const_sub 1).add
      ((hasDerivAt_pow 4 x).div_const 24) |>.sub (hasDerivAt_cos x)).congr_deriv
      (by norm_num; ring))
    (by simp) s2
  have s3 := ricci_nonneg_of_deriv_nonneg (fun x => x - x ^ 3 / 6 + x ^ 5 / 120 - sin x)
    (fun x => 1 - x ^ 2 / 2 + x ^ 4 / 24 - cos x)
    (fun x => (((hasDerivAt_id' x).sub ((hasDerivAt_pow 3 x).div_const 6)).add
      ((hasDerivAt_pow 5 x).div_const 120) |>.sub (hasDerivAt_sin x)).congr_deriv
      (by norm_num; ring))
    (by simp) c2
  have c3 := ricci_nonneg_of_deriv_nonneg
    (fun x => cos x - (1 - x ^ 2 / 2 + x ^ 4 / 24 - x ^ 6 / 720))
    (fun x => x - x ^ 3 / 6 + x ^ 5 / 120 - sin x)
    (fun x => ((hasDerivAt_cos x).sub (((((hasDerivAt_pow 2 x).div_const 2).const_sub 1).add
      ((hasDerivAt_pow 4 x).div_const 24)).sub ((hasDerivAt_pow 6 x).div_const 720))).congr_deriv
      (by norm_num; ring))
    (by simp) s3
  exact ⟨by linarith [c2 x hx], by linarith [c3 x hx]⟩
#print axioms ricci_cos_taylor_bounds

/-- **A small disc's area falls short by S r²/24 (the volume formula with n = 2).** On a surface
whose metric is smooth at the centre (the rim function `f` is smooth and odd with `f'(0) = 1`),
with Gaussian curvature `K` given by `K(ρ) f(ρ) = -f''(ρ)` away from the centre and continuous up
to it, the geodesic disc of radius `r` has area
`2π ∫₀ʳ f = π r² (1 - S r²/24) + (terms in r⁶ and smaller)` as `r → 0`, where `S = 2 K(0)` is the
scalar curvature at the centre. The statement is local: only small `r ≥ 0` count. -/
theorem geodesic_disc_area_eq_flat_mul_one_sub_scalar_curvature
    (f K : ℝ → ℝ) (hf : ContDiff ℝ ((⊤ : ℕ∞) : WithTop ℕ∞) f) (hodd : ∀ ρ, f (-ρ) = -f ρ) (hf1 : deriv f 0 = 1)
    (hK : ∀ ρ, 0 < ρ → K ρ * f ρ = -deriv (deriv f) ρ)
    (hKc : ContinuousWithinAt K (Ici 0) 0) :
    (fun r : ℝ => 2 * π * (∫ ρ in (0 : ℝ)..r, f ρ) - π * r ^ 2 * (1 - 2 * K 0 * r ^ 2 / 24))
      =O[𝓝[≥] 0] (fun r : ℝ => r ^ 6) := by
  obtain ⟨d0, h1⟩ := contDiff_infty_iff_deriv.mp hf
  obtain ⟨d1, h2⟩ := contDiff_infty_iff_deriv.mp h1
  obtain ⟨d2, h3⟩ := contDiff_infty_iff_deriv.mp h2
  obtain ⟨d3, h4⟩ := contDiff_infty_iff_deriv.mp h3
  obtain ⟨d4, h5⟩ := contDiff_infty_iff_deriv.mp h4
  -- parity of the derivatives at the centre
  have f0 : f 0 = 0 := by have := hodd 0; rw [neg_zero] at this; linarith
  have e1 := ricci_deriv_even_of_odd f hodd
  have o2 := ricci_deriv_odd_of_even _ e1
  have e3 := ricci_deriv_even_of_odd _ o2
  have o4 := ricci_deriv_odd_of_even _ e3
  have f2z : deriv (deriv f) 0 = 0 := by have := o2 0; rw [neg_zero] at this; linarith
  have f4z : deriv (deriv (deriv (deriv f))) 0 = 0 := by
    have := o4 0; rw [neg_zero] at this; linarith
  set a := deriv (deriv (deriv f)) 0 with ha
  -- the curvature at the centre is `-f'''(0)`
  have slope_lim : ∀ g : ℝ → ℝ, g 0 = 0 → DifferentiableAt ℝ g 0 →
      Tendsto (fun x => g x / x) (𝓝[>] 0) (𝓝 (deriv g 0)) := by
    intro g hg0 hgd
    have := hasDerivAt_iff_tendsto_slope.mp hgd.hasDerivAt
    refine (this.mono_left (nhdsWithin_mono _ fun x hx => ne_of_gt hx)).congr' ?_
    filter_upwards with x
    rw [slope_def_field, hg0, sub_zero, sub_zero]
  have lim0 := slope_lim f f0 (d0 0)
  have lim2 := slope_lim _ f2z (d2 0)
  rw [hf1] at lim0
  have limA : Tendsto (fun x => K x * (f x / x)) (𝓝[>] 0) (𝓝 (K 0 * 1)) :=
    Tendsto.mul (hKc.mono Ioi_subset_Ici_self) lim0
  have limB : Tendsto (fun x => K x * (f x / x)) (𝓝[>] 0) (𝓝 (-a)) := by
    refine lim2.neg.congr' ?_
    filter_upwards [self_mem_nhdsWithin] with x hx
    rw [mul_div_assoc', hK x hx, neg_div]
  have hKa : K 0 = -a := by have := tendsto_nhds_unique limA limB; linarith
  -- the chain of estimates
  have b4 : deriv (deriv (deriv (deriv f))) =O[𝓝[≥] 0] (fun x => x ^ (0 + 1)) := by
    refine ricci_bigO_succ_of_deriv _ (deriv (deriv (deriv (deriv (deriv f))))) 0 f4z
      (fun x => (d4 x).hasDerivAt) ?_
    have := ((h5.continuous.tendsto 0).isBigO_one ℝ).mono (nhdsWithin_le_nhds (s := Ici 0))
    simpa only [pow_zero] using this
  have b3 : (fun x => deriv (deriv (deriv f)) x - a) =O[𝓝[≥] 0] (fun x => x ^ (1 + 1)) :=
    ricci_bigO_succ_of_deriv _ _ 1 (by simp [a]) (fun x => (d3 x).hasDerivAt.sub_const a) b4
  have b2 : (fun x => deriv (deriv f) x - a * x) =O[𝓝[≥] 0] (fun x => x ^ (2 + 1)) :=
    ricci_bigO_succ_of_deriv _ _ 2 (by simp [f2z])
      (fun x => ((d2 x).hasDerivAt.sub ((hasDerivAt_id' x).const_mul a)).congr_deriv (by ring)) b3
  have b1 : (fun x => deriv f x - 1 - a / 2 * x ^ 2) =O[𝓝[≥] 0] (fun x => x ^ (3 + 1)) :=
    ricci_bigO_succ_of_deriv _ _ 3 (by simp [hf1])
      (fun x => (((d1 x).hasDerivAt.sub_const 1).sub
        ((hasDerivAt_pow 2 x).const_mul (a / 2))).congr_deriv (by norm_num; ring)) b2
  have b0 : (fun x => f x - x - a / 6 * x ^ 3) =O[𝓝[≥] 0] (fun x => x ^ (4 + 1)) :=
    ricci_bigO_succ_of_deriv _ _ 4 (by simp [f0])
      (fun x => (((d0 x).hasDerivAt.sub (hasDerivAt_id' x)).sub
        ((hasDerivAt_pow 3 x).const_mul (a / 6))).congr_deriv (by norm_num; ring)) b1
  have bT := ricci_bigO_succ_of_deriv
    (fun r : ℝ => 2 * π * (∫ ρ in (0 : ℝ)..r, f ρ) - π * r ^ 2 * (1 - 2 * K 0 * r ^ 2 / 24))
    (fun x => 2 * π * (f x - x - a / 6 * x ^ 3)) 5 (by simp)
    (fun x => ((((d0.continuous.integral_hasStrictDerivAt 0 x).hasDerivAt.const_mul (2 * π))).sub
      (((hasDerivAt_pow 2 x).const_mul π).mul
        ((((hasDerivAt_pow 2 x).const_mul (2 * K 0)).div_const 24).const_sub 1))).congr_deriv
      (by rw [hKa]; norm_num; ring)) (b0.const_mul_left (2 * π))
  simpa using bT

/-- **The dome, exactly.** On a dome that is part of a sphere of radius `R > 0` (scalar curvature
`S = 2/R²`), the patch of all points within distance `r ≥ 0` of the top, measured along the
roof, has area `2π ∫₀ʳ R sin(s/R) ds = 2π R² (1 - cos(r/R))`. That area is at least the
scalar-curvature prediction `π r² (1 - S r²/24)` and exceeds it by at most `π r⁶/(360 R⁴)`, the
next term of the series. -/
theorem dome_patch_area_between_prediction_and_next_term (R r : ℝ) (hR : 0 < R) (hr : 0 ≤ r) :
    2 * π * (∫ s in (0 : ℝ)..r, R * sin (s / R)) = 2 * π * R ^ 2 * (1 - cos (r / R)) ∧
    π * r ^ 2 * (1 - 2 / R ^ 2 * r ^ 2 / 24) ≤ 2 * π * R ^ 2 * (1 - cos (r / R)) ∧
    2 * π * R ^ 2 * (1 - cos (r / R))
      ≤ π * r ^ 2 * (1 - 2 / R ^ 2 * r ^ 2 / 24) + π * r ^ 6 / (360 * R ^ 4) := by
  have hR0 : R ≠ 0 := hR.ne'
  set x := r / R with hxdef
  have hx : 0 ≤ x := div_nonneg hr hR.le
  have hrx : r = R * x := by rw [hxdef]; field_simp
  obtain ⟨hup, hlo⟩ := ricci_cos_taylor_bounds x hx
  have hpred : π * r ^ 2 * (1 - 2 / R ^ 2 * r ^ 2 / 24)
      = 2 * π * R ^ 2 * (x ^ 2 / 2 - x ^ 4 / 24) := by
    rw [hrx]; field_simp
  have hnext : π * r ^ 6 / (360 * R ^ 4) = 2 * π * R ^ 2 * (x ^ 6 / 720) := by
    rw [hrx]; field_simp; ring
  have hc : 0 ≤ 2 * π * R ^ 2 := by positivity
  refine ⟨?_, ?_, ?_⟩
  · rw [intervalIntegral.integral_const_mul, intervalIntegral.integral_comp_div _ hR0,
      integral_sin, zero_div, cos_zero, smul_eq_mul]
    ring
  · rw [hpred]
    exact mul_le_mul_of_nonneg_left (by linarith) hc
  · rw [hpred, hnext, ← mul_add]
    exact mul_le_mul_of_nonneg_left (by linarith) hc

/-- **Averaging the cones over all directions (Step 3).** In dimension `n ≥ 1`, a thin cone of
shortest paths has cross-section `s^(n-1) (1 - s² Ric(v,v)/6)`, and Ric averages to `S/n` over
directions, whose total size is `n ω_n`. Adding the cones out to radius `r` gives
`n ω_n ∫₀ʳ s^(n-1) (1 - S s²/(6n)) ds = ω_n rⁿ (1 - S r²/(6(n+2)))`: the flat volume times one
minus the fraction `S r²/(6(n+2))`. -/
theorem cone_average_integral_eq_ball_volume_formula (n : ℕ) (hn : 1 ≤ n) (ω S r : ℝ) :
    n * ω * (∫ s in (0 : ℝ)..r, s ^ (n - 1) * (1 - S / (6 * n) * s ^ 2))
      = ω * r ^ n * (1 - S / (6 * (n + 2)) * r ^ 2) := by
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  have hint : (∫ s in (0 : ℝ)..r, s ^ (m + 1 - 1) * (1 - S / (6 * ((m + 1 : ℕ) : ℝ)) * s ^ 2))
      = (∫ s in (0 : ℝ)..r, s ^ m) - S / (6 * ((m + 1 : ℕ) : ℝ)) * ∫ s in (0 : ℝ)..r, s ^ (m + 2) := by
    rw [← intervalIntegral.integral_const_mul, ← intervalIntegral.integral_sub
      (intervalIntegrable_pow m) ((intervalIntegrable_pow (m + 2)).const_mul _)]
    congr 1
    ext s
    rw [Nat.add_sub_cancel]
    ring
  rw [hint, integral_pow, integral_pow]
  push_cast
  have h1 : (m : ℝ) + 1 ≠ 0 := by positivity
  have h3 : (m : ℝ) + 1 + 2 ≠ 0 := by positivity
  have h2 : (m : ℝ) + 2 + 1 ≠ 0 := by positivity
  field_simp
  ring

-- The dome, R = 30 m: scalar curvature S = 2/R² = 2/900 = 1/450 per m² (0.00222222).
example : (2 : ℚ) / 30 ^ 2 = 1 / 450 := by norm_num
-- Gaussian curvature K = S/2 = 1/900 per m² (0.00111111).
example : (1 : ℚ) / 450 / 2 = 1 / 900 := by norm_num
-- Fraction of the 5 m patch missing: S r²/24 = (1/450)(25)/24 = 1/432 (0.00231481).
example : (1 : ℚ) / 450 * 5 ^ 2 / 24 = 1 / 432 := by norm_num
-- The same fraction from r²/(12 R²) = 25/10800.
example : (5 : ℚ) ^ 2 / (12 * 30 ^ 2) = 1 / 432 := by norm_num
-- The denominator 6(n + 2): 24 on the roof (n = 2), 30 for the stacked dome (n = 3).
example : 6 * (2 + 2) = 24 ∧ 6 * (3 + 2) = 30 := by decide
-- Stacked dome, 5 m ball: fraction missing S r²/30 = (1/450)(25)/30 = 1/540.
example : (1 : ℚ) / 450 * 5 ^ 2 / 30 = 1 / 540 := by norm_num
-- Stacked dome: Ric along the dome 1/900 + 0, along t 0 + 0, and S = 1/900 + 1/900 + 0 = 1/450.
example : (1 : ℚ) / 900 + 0 + (1 / 900 + 0) + (0 + 0) = 1 / 450 := by norm_num
-- Tilted 45 degrees: Ric = (1/2)(1/900) + (1/2)(0) = 1/1800 (0.00055556).
example : (1 : ℚ) / 2 * (1 / 900) + 1 / 2 * 0 = 1 / 1800 := by norm_num
-- Average of Ric over directions is S/3 = (1/450)/3 = 1/1350 (0.00074074).
example : (1 : ℚ) / 450 / 3 = 1 / 1350 := by norm_num
-- Taking S as K halves the shortfall: (1/900) r²/24 is half of (1/450) r²/24.
example : (1 : ℚ) / 900 * 25 / 24 = (1 / 450 * 25 / 24) / 2 := by norm_num
-- Independent parts of Rm, n²(n² − 1)/12, for n = 2, 3, 4: 1, 6, 20.
example : 2 ^ 2 * (2 ^ 2 - 1) / 12 = 1 ∧ 3 ^ 2 * (3 ^ 2 - 1) / 12 = 6 ∧
    4 ^ 2 * (4 ^ 2 - 1) / 12 = 20 := by decide
-- Independent parts of Ric, n(n + 1)/2, for n = 2, 3, 4: 3, 6, 10.
example : 2 * (2 + 1) / 2 = 3 ∧ 3 * (3 + 1) / 2 = 6 ∧ 4 * (4 + 1) / 2 = 10 := by decide
-- In four dimensions the Weyl tensor keeps the other 20 − 10 = 10 parts.
example : 20 - 10 = 10 := by decide

#print axioms geodesic_disc_area_eq_flat_mul_one_sub_scalar_curvature
#print axioms dome_patch_area_between_prediction_and_next_term
#print axioms cone_average_integral_eq_ball_volume_formula
