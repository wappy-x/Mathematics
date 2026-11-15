-- Sobolev and Poincare: on an interval of length L, a function with square-integrable slope strays from its mean by at most L/π times the slope's 2-size (and L/π cannot be lowered), and it is continuous with two readings a gap apart differing by at most the square root of the gap times the slope's 2-size.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Function.LpSeminorm.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic.NormNum
import Mathlib.MeasureTheory.Integral.IntervalIntegral.AbsolutelyContinuousFun
import Mathlib.MeasureTheory.Integral.IntervalIntegral.LebesgueDifferentiationThm
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.MeasureTheory.Function.L2Space
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Algebra.QuadraticDiscriminant

open MeasureTheory Set Real

/-- Cauchy-Schwarz for interval integrals. -/
theorem sob_cs {a b : ℝ} (hab : a ≤ b) {f h : ℝ → ℝ}
    (hf2 : IntervalIntegrable (fun t => f t ^ 2) volume a b)
    (hh2 : IntervalIntegrable (fun t => h t ^ 2) volume a b)
    (hfh : IntervalIntegrable (fun t => f t * h t) volume a b) :
    |∫ t in a..b, f t * h t| ≤
      Real.sqrt (∫ t in a..b, f t ^ 2) * Real.sqrt (∫ t in a..b, h t ^ 2) := by
  have key : ∀ s : ℝ, 0 ≤ (∫ t in a..b, h t ^ 2) * (s * s)
      + (-2 * ∫ t in a..b, f t * h t) * s + ∫ t in a..b, f t ^ 2 := by
    intro s
    have h1 : 0 ≤ ∫ t in a..b, (f t - s * h t) ^ 2 :=
      intervalIntegral.integral_nonneg hab (fun t _ => sq_nonneg _)
    have h2 : (∫ t in a..b, (f t - s * h t) ^ 2) = (∫ t in a..b, h t ^ 2) * (s * s)
      + (-2 * ∫ t in a..b, f t * h t) * s + ∫ t in a..b, f t ^ 2 := by
      have e : (fun t => (f t - s * h t) ^ 2) =
          fun t => (f t ^ 2 + (-2 * s) * (f t * h t)) + (s * s) * h t ^ 2 := by
        funext t; ring
      rw [e, intervalIntegral.integral_add (hf2.add (hfh.const_mul _)) (hh2.const_mul _),
        intervalIntegral.integral_add hf2 (hfh.const_mul _),
        intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul]
      ring
    linarith
  have hd := discrim_le_zero key
  unfold discrim at hd
  have hA : 0 ≤ ∫ t in a..b, f t ^ 2 := intervalIntegral.integral_nonneg hab (fun t _ => sq_nonneg _)
  rw [← Real.sqrt_mul hA]
  apply Real.abs_le_sqrt
  nlinarith

/-- Integration by parts against a running integral. -/
theorem sob_ibp {L : ℝ} (hL : 0 ≤ L) {w w' g : ℝ → ℝ} (hw : ∀ t, HasDerivAt w (w' t) t)
    (hw' : Continuous w') (hg : IntervalIntegrable g volume 0 L) :
    ∫ t in (0:ℝ)..L, w t * g t
      = w L * (∫ τ in (0:ℝ)..L, g τ) - ∫ t in (0:ℝ)..L, w' t * ∫ τ in (0:ℝ)..t, g τ := by
  have hderiv : deriv w = w' := funext fun t => (hw t).deriv
  have hC1 : ContDiff ℝ 1 w := by
    rw [contDiff_one_iff_deriv, hderiv]
    exact ⟨fun t => (hw t).differentiableAt, hw'⟩
  have hwAC : AbsolutelyContinuousOnInterval w 0 L :=
    hC1.contDiffOn.absolutelyContinuousOnInterval
  have hFAC := hg.absolutelyContinuousOnInterval_intervalIntegral (c := 0) (by simp [hL])
  have h := hwAC.integral_mul_deriv_eq_deriv_mul hFAC
  rw [hderiv] at h
  simp only [intervalIntegral.integral_same, mul_zero, sub_zero] at h
  rw [← h]
  apply intervalIntegral.integral_congr_ae
  filter_upwards [hg.ae_hasDerivAt_integral] with x hx hxI
  rw [(hx (uIoc_subset_uIcc hxI) 0 (by simp [hL])).deriv]
/-- Wirtinger with a shifted weight: for `δ > 0`, `π² ∫ w² ≤ (L + 2δ)² ∫ w'²`. -/
theorem sob_dirichlet_shift {L : ℝ} (hL : 0 < L) {w w' : ℝ → ℝ}
    (hw : ∀ t, HasDerivAt w (w' t) t) (hw' : Continuous w') (h0 : w 0 = 0) (hL0 : w L = 0)
    {δ : ℝ} (hδ : 0 < δ) :
    π ^ 2 * ∫ t in (0:ℝ)..L, w t ^ 2 ≤ (L + 2 * δ) ^ 2 * ∫ t in (0:ℝ)..L, w' t ^ 2 := by
  have hwc : Continuous w := continuous_iff_continuousAt.2 fun t => (hw t).continuousAt
  set k := π / (L + 2 * δ) with hk
  have hLd : 0 < L + 2 * δ := by linarith
  have hkpos : 0 < k := div_pos pi_pos hLd
  have hsin : ∀ t ∈ uIcc (0:ℝ) L, 0 < sin (k * (t + δ)) := by
    intro t ht
    rw [uIcc_of_le hL.le] at ht
    apply sin_pos_of_pos_of_lt_pi
    · have : 0 < t + δ := by linarith [ht.1]
      positivity
    · rw [hk, div_mul_eq_mul_div, div_lt_iff₀ hLd]
      have : t + δ < L + 2 * δ := by linarith [ht.2]
      nlinarith [pi_pos]
  set D : ℝ → ℝ := fun t => -k ^ 2 * w t ^ 2 / sin (k * (t + δ)) ^ 2
      + 2 * k * (cos (k * (t + δ)) / sin (k * (t + δ))) * w t * w' t with hD
  set H : ℝ → ℝ := fun t => k * (cos (k * (t + δ)) / sin (k * (t + δ))) * w t ^ 2 with hH
  have hderiv : ∀ t ∈ uIcc (0:ℝ) L, HasDerivAt H (D t) t := by
    intro t ht
    have hs := (hsin t ht).ne'
    have hθ : HasDerivAt (fun t => k * (t + δ)) k t := by
      simpa using ((hasDerivAt_id t).add_const δ).const_mul k
    have hc := (Real.hasDerivAt_cos (k * (t + δ))).comp t hθ
    have hsn := (Real.hasDerivAt_sin (k * (t + δ))).comp t hθ
    have hq := hc.div hsn hs
    have hw2 := (hw t).pow 2
    have := (hq.const_mul k).mul hw2
    convert this using 1
    · funext s; simp [hH, Function.comp_apply]
    rw [hD]
    simp only [Function.comp_apply, Pi.pow_apply, Pi.div_apply]
    have hsc := sin_sq_add_cos_sq (k * (t + δ))
    field_simp
    push_cast
    linear_combination (k * w t ^ 2) * hsc
  have hDc : ContinuousOn D (uIcc 0 L) := by
    apply ContinuousOn.add
    · apply ContinuousOn.div (by fun_prop) (by fun_prop)
      intro t ht; exact pow_ne_zero _ (hsin t ht).ne'
    · apply ContinuousOn.mul (ContinuousOn.mul (ContinuousOn.mul (by fun_prop) ?_) (by fun_prop))
        (by fun_prop)
      apply ContinuousOn.div (by fun_prop) (by fun_prop)
      intro t ht; exact (hsin t ht).ne'
  have hint : ∫ t in (0:ℝ)..L, D t = 0 := by
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hderiv (hDc.intervalIntegrable)]
    simp [hH, h0, hL0]
  have hle : ∫ t in (0:ℝ)..L, D t ≤ ∫ t in (0:ℝ)..L, (w' t ^ 2 - k ^ 2 * w t ^ 2) := by
    apply intervalIntegral.integral_mono_on hL.le hDc.intervalIntegrable
      (by apply Continuous.intervalIntegrable; fun_prop)
    intro t ht
    have hs := hsin t (by rw [uIcc_of_le hL.le]; exact ht)
    have hsc := sin_sq_add_cos_sq (k * (t + δ))
    have key : w' t ^ 2 - k ^ 2 * w t ^ 2 - D t
        = (w' t - k * (cos (k * (t + δ)) / sin (k * (t + δ))) * w t) ^ 2 := by
      simp only [hD]
      field_simp
      linear_combination (-k ^ 2 * w t ^ 2) * hsc
    nlinarith [sq_nonneg (w' t - k * (cos (k * (t + δ)) / sin (k * (t + δ))) * w t)]
  rw [intervalIntegral.integral_sub (by apply Continuous.intervalIntegrable; fun_prop)
    (by apply Continuous.intervalIntegrable; fun_prop), intervalIntegral.integral_const_mul] at hle
  have hkL : k * (L + 2 * δ) = π := by rw [hk]; field_simp
  have : k ^ 2 * ∫ t in (0:ℝ)..L, w t ^ 2 ≤ ∫ t in (0:ℝ)..L, w' t ^ 2 := by linarith
  calc π ^ 2 * ∫ t in (0:ℝ)..L, w t ^ 2
      = (L + 2 * δ) ^ 2 * (k ^ 2 * ∫ t in (0:ℝ)..L, w t ^ 2) := by rw [← hkL]; ring
    _ ≤ (L + 2 * δ) ^ 2 * ∫ t in (0:ℝ)..L, w' t ^ 2 := by gcongr

/-- Wirtinger's inequality for a `C¹` function vanishing at both ends. -/
theorem sob_dirichlet_C1 {L : ℝ} (hL : 0 < L) {w w' : ℝ → ℝ}
    (hw : ∀ t, HasDerivAt w (w' t) t) (hw' : Continuous w') (h0 : w 0 = 0) (hL0 : w L = 0) :
    π ^ 2 * ∫ t in (0:ℝ)..L, w t ^ 2 ≤ L ^ 2 * ∫ t in (0:ℝ)..L, w' t ^ 2 := by
  have hT : Filter.Tendsto (fun δ : ℝ => (L + 2 * δ) ^ 2 * ∫ t in (0:ℝ)..L, w' t ^ 2)
      (nhdsWithin 0 (Ioi 0)) (nhds (L ^ 2 * ∫ t in (0:ℝ)..L, w' t ^ 2)) := by
    have hc : Continuous (fun δ : ℝ => (L + 2 * δ) ^ 2 * ∫ t in (0:ℝ)..L, w' t ^ 2) := by
      fun_prop
    simpa using (hc.tendsto 0).mono_left nhdsWithin_le_nhds
  exact ge_of_tendsto hT (eventually_nhdsWithin_of_forall fun δ hδ =>
    sob_dirichlet_shift hL hw hw' h0 hL0 hδ)

/-- A running integral of an integrable slope is continuous on the closed interval. -/
theorem sob_cont {L : ℝ} (hL : 0 < L) {u g : ℝ → ℝ} (hgi : IntervalIntegrable g volume 0 L)
    (hu : ∀ t ∈ Icc 0 L, u t = u 0 + ∫ τ in (0 : ℝ)..t, g τ) : ContinuousOn u (Icc 0 L) := by
  have h1 : ContinuousOn (fun x => ∫ t in (0:ℝ)..x, g t) (uIcc 0 L) :=
    intervalIntegral.continuousOn_primitive_interval
      (by rw [uIcc_of_le hL.le]; exact (intervalIntegrable_iff_integrableOn_Icc_of_le hL.le).1 hgi)
  rw [uIcc_of_le hL.le] at h1
  exact (continuousOn_const.add h1).congr hu

/-- Extend a function continuous on `[0, L]` to a continuous function on the line. -/
theorem sob_ext {L : ℝ} (hL : 0 < L) {u : ℝ → ℝ} (hc : ContinuousOn u (Icc 0 L)) :
    ∃ ue : ℝ → ℝ, Continuous ue ∧ ∀ t ∈ Icc 0 L, ue t = u t := by
  refine ⟨fun t => u (max 0 (min L t)), ?_, ?_⟩
  · exact hc.comp_continuous (continuous_const.max (continuous_const.min continuous_id))
      (fun t => ⟨le_max_left _ _, max_le hL.le (min_le_left _ _)⟩)
  · intro t ht
    simp [min_eq_right ht.2, max_eq_right ht.1]

/-- The closing algebra: `A ≤ √W √B` and `π² W ≤ L² A` give `π² A ≤ L² B`. -/
theorem sob_alg {A W B L : ℝ} (hA : 0 ≤ A) (hB : 0 ≤ B) (hW : 0 ≤ W)
    (h1 : A ≤ Real.sqrt W * Real.sqrt B) (h2 : π ^ 2 * W ≤ L ^ 2 * A) :
    π ^ 2 * A ≤ L ^ 2 * B := by
  have h3 : A ^ 2 ≤ W * B := by
    calc A ^ 2 ≤ (Real.sqrt W * Real.sqrt B) ^ 2 := by gcongr
      _ = W * B := by rw [mul_pow, sq_sqrt hW, sq_sqrt hB]
  rcases hA.eq_or_lt with h | h
  · rw [← h]; simp only [mul_zero]; positivity
  · have : (π ^ 2 * A) * A ≤ (L ^ 2 * B) * A := by
      nlinarith [sq_nonneg L, mul_nonneg (sq_nonneg L) hB, pi_pos]
    exact le_of_mul_le_mul_right this h

theorem sob_sqrt_of_sq {A B L : ℝ} (hL : 0 < L) (_hB : 0 ≤ B) (h : π ^ 2 * A ≤ L ^ 2 * B) :
    Real.sqrt A ≤ (L / π) * Real.sqrt B := by
  rw [show L / π * Real.sqrt B = Real.sqrt ((L / π) ^ 2 * B) by
    rw [Real.sqrt_mul (by positivity), Real.sqrt_sq (by positivity)]]
  apply Real.sqrt_le_sqrt
  rw [div_pow, div_mul_eq_mul_div, le_div_iff₀ (by positivity)]
  linarith

/-- Neumann-type Poincare inequality, squared form. -/
theorem sob_neumann_sq {L : ℝ} (hL : 0 < L) {u g : ℝ → ℝ}
    (hgi : IntervalIntegrable g volume 0 L)
    (hg2 : IntervalIntegrable (fun t => g t ^ 2) volume 0 L)
    (hu : ∀ t ∈ Icc 0 L, u t = u 0 + ∫ τ in (0 : ℝ)..t, g τ) :
    π ^ 2 * ∫ t in (0 : ℝ)..L, (u t - (1 / L) * ∫ s in (0 : ℝ)..L, u s) ^ 2
      ≤ L ^ 2 * ∫ t in (0 : ℝ)..L, g t ^ 2 := by
  obtain ⟨ue, hue, hue_eq⟩ := sob_ext hL (sob_cont hL hgi hu)
  set c := (1 / L) * ∫ s in (0 : ℝ)..L, u s with hc
  set v : ℝ → ℝ := fun t => ue t - c with hv_def
  have hv : Continuous v := hue.sub continuous_const
  set w : ℝ → ℝ := fun t => ∫ s in (0:ℝ)..t, v s with hw_def
  have hw : ∀ t, HasDerivAt w (v t) t := fun t => (hv.integral_hasStrictDerivAt 0 t).hasDerivAt
  have hIcc : ∀ t ∈ uIcc (0:ℝ) L, t ∈ Icc 0 L := fun t ht => by rwa [uIcc_of_le hL.le] at ht
  have hintu : ∫ t in (0:ℝ)..L, ue t = ∫ t in (0:ℝ)..L, u t :=
    intervalIntegral.integral_congr fun t ht => hue_eq t (hIcc t ht)
  have hw0 : w 0 = 0 := by simp [w]
  have hwL : w L = 0 := by
    simp only [w, v]
    rw [intervalIntegral.integral_sub (hue.intervalIntegrable _ _) intervalIntegrable_const,
      hintu, intervalIntegral.integral_const, hc]
    simp only [sub_zero, smul_eq_mul]
    rw [one_div, ← mul_assoc, mul_inv_cancel₀ hL.ne', one_mul, sub_self]
  have hA := sob_dirichlet_C1 hL hw hv hw0 hwL
  have hibp := sob_ibp hL.le hw hv hgi
  rw [hwL, zero_mul, zero_sub] at hibp
  set F : ℝ → ℝ := fun t => ∫ τ in (0:ℝ)..t, g τ with hF
  have hFc : ContinuousOn F (uIcc 0 L) :=
    intervalIntegral.continuousOn_primitive_interval
      (by rw [uIcc_of_le hL.le]; exact (intervalIntegrable_iff_integrableOn_Icc_of_le hL.le).1 hgi)
  have hvF : ∫ t in (0:ℝ)..L, v t ^ 2 = ∫ t in (0:ℝ)..L, v t * F t := by
    have e : ∫ t in (0:ℝ)..L, v t ^ 2 = ∫ t in (0:ℝ)..L, (v t * F t + (u 0 - c) * v t) := by
      apply intervalIntegral.integral_congr
      intro t ht
      have h1 := hue_eq t (hIcc t ht)
      have h2 := hu t (hIcc t ht)
      simp only [v, F, h1]
      rw [h2]; ring
    rw [e, intervalIntegral.integral_add (f := fun t => v t * F t)
      (g := fun t => (u 0 - c) * v t) ((hv.continuousOn.mul hFc).intervalIntegrable)
      ((hv.intervalIntegrable _ _).const_mul _), intervalIntegral.integral_const_mul]
    have : ∫ t in (0:ℝ)..L, v t = 0 := hwL
    rw [this]; ring
  have hkey : ∫ t in (0:ℝ)..L, v t ^ 2 = -∫ t in (0:ℝ)..L, w t * g t := by
    rw [hvF, hibp]; ring
  have hwc : Continuous w := continuous_iff_continuousAt.2 fun t => (hw t).continuousAt
  have hcs := sob_cs hL.le ((hwc.pow 2).intervalIntegrable 0 L) hg2
    (hgi.continuousOn_mul hwc.continuousOn)
  have hconc := sob_alg (A := ∫ t in (0:ℝ)..L, v t ^ 2) (W := ∫ t in (0:ℝ)..L, w t ^ 2)
    (B := ∫ t in (0:ℝ)..L, g t ^ 2) (L := L)
    (intervalIntegral.integral_nonneg hL.le fun t _ => sq_nonneg _)
    (intervalIntegral.integral_nonneg hL.le fun t _ => sq_nonneg _)
    (intervalIntegral.integral_nonneg hL.le fun t _ => sq_nonneg _)
    (by rw [hkey]; exact (neg_le_abs _).trans hcs) hA
  convert hconc using 2
  apply intervalIntegral.integral_congr
  intro t ht
  simp only [v, hue_eq t (hIcc t ht)]

/-- The slope is integrable and has integrable square on `[0, L]`. -/
theorem sob_int {L : ℝ} (hL : 0 < L) {g : ℝ → ℝ} (hg : MemLp g 2 (volume.restrict (Ioc 0 L))) :
    IntervalIntegrable g volume 0 L ∧ IntervalIntegrable (fun t => g t ^ 2) volume 0 L := by
  have : IsFiniteMeasure (volume.restrict (Ioc (0:ℝ) L)) :=
    isFiniteMeasure_restrict.2 measure_Ioc_lt_top.ne
  exact ⟨(intervalIntegrable_iff_integrableOn_Ioc_of_le hL.le).2 (hg.integrable one_le_two),
    (intervalIntegrable_iff_integrableOn_Ioc_of_le hL.le).2 hg.integrable_sq⟩

/-- The Holder step: `|u t - u s| ≤ √(t - s) ‖g‖₂` for `s ≤ t` in `[0, L]`. -/
theorem sob_holder {L : ℝ} {u g : ℝ → ℝ}
    (hgi : IntervalIntegrable g volume 0 L)
    (hg2 : IntervalIntegrable (fun t => g t ^ 2) volume 0 L)
    (hu : ∀ t ∈ Icc 0 L, u t = u 0 + ∫ τ in (0 : ℝ)..t, g τ)
    {s t : ℝ} (hs : s ∈ Icc 0 L) (ht : t ∈ Icc 0 L) (hst : s ≤ t) :
    |u t - u s| ≤ Real.sqrt (t - s) * Real.sqrt (∫ τ in (0 : ℝ)..L, g τ ^ 2) := by
  have hL : 0 ≤ L := hs.1.trans hs.2
  have hsub : ∀ x ∈ Icc 0 L, uIcc 0 x ⊆ uIcc 0 L := fun x hx =>
    uIcc_subset_uIcc left_mem_uIcc (by rw [uIcc_of_le hL]; exact hx)
  have hdiff : u t - u s = ∫ τ in s..t, g τ := by
    rw [hu t ht, hu s hs, add_sub_add_left_eq_sub,
      intervalIntegral.integral_interval_sub_left (hgi.mono_set (hsub t ht))
        (hgi.mono_set (hsub s hs))]
  have hsubst : uIcc s t ⊆ uIcc 0 L := by
    rw [uIcc_of_le hst, uIcc_of_le hL]; exact Icc_subset_Icc hs.1 ht.2
  have hcs := sob_cs hst (f := fun _ => (1:ℝ)) (h := g)
    (by simp) (hg2.mono_set hsubst) (by simpa using hgi.mono_set hsubst)
  simp only [one_mul, one_pow, intervalIntegral.integral_const, smul_eq_mul, mul_one] at hcs
  rw [hdiff]
  refine hcs.trans (mul_le_mul_of_nonneg_left ?_ (Real.sqrt_nonneg _))
  apply Real.sqrt_le_sqrt
  exact intervalIntegral.integral_mono_interval hs.1 hst ht.2
    (Filter.Eventually.of_forall fun x => sq_nonneg (g x)) hg2

/-- Poincare inequality on an interval, with the best constant `C_P = L/π`. Take a record of
finite length `L > 0` and a function `u` in `H^1(0, L)`: in its continuous version, `u` is the
running integral of its weak derivative `g`, `u t = u 0 + ∫₀ᵗ g`, and the slope `g` has finite
2-size on `(0, L)`. Then the 2-size of `u`'s departure from its mean `ū = (1/L) ∫₀ᴸ u` is at most
`L/π` times the 2-size of the slope: `‖u - ū‖₂ ≤ (L/π) ‖u'‖₂`. The same constant serves `H^1_0`:
if also `u 0 = 0` and `u L = 0`, then `‖u‖₂ ≤ (L/π) ‖u'‖₂`. -/
theorem poincare_inequality_interval {L : ℝ} (hL : 0 < L) {u g : ℝ → ℝ}
    (hg : MemLp g 2 (volume.restrict (Ioc 0 L)))
    (hu : ∀ t ∈ Icc 0 L, u t = u 0 + ∫ τ in (0 : ℝ)..t, g τ) :
    Real.sqrt (∫ t in (0 : ℝ)..L, (u t - (1 / L) * ∫ s in (0 : ℝ)..L, u s) ^ 2)
        ≤ (L / π) * Real.sqrt (∫ t in (0 : ℝ)..L, g t ^ 2) ∧
      (u 0 = 0 → u L = 0 →
        Real.sqrt (∫ t in (0 : ℝ)..L, u t ^ 2)
          ≤ (L / π) * Real.sqrt (∫ t in (0 : ℝ)..L, g t ^ 2)) := by
  obtain ⟨hgi, hg2⟩ := sob_int hL hg
  have hB : 0 ≤ ∫ t in (0 : ℝ)..L, g t ^ 2 :=
    intervalIntegral.integral_nonneg hL.le fun t _ => sq_nonneg _
  refine ⟨sob_sqrt_of_sq hL hB (sob_neumann_sq hL hgi hg2 hu), ?_⟩
  intro h0 hL0
  have hIcc : ∀ t ∈ uIcc (0:ℝ) L, t ∈ Icc 0 L := fun t ht => by rwa [uIcc_of_le hL.le] at ht
  obtain ⟨ue, hue, hue_eq⟩ := sob_ext hL (sob_cont hL hgi hu)
  set V : ℝ → ℝ := fun t => ∫ s in (0:ℝ)..t, ue s with hV
  have hN := sob_neumann_sq hL (hue.intervalIntegrable 0 L) ((hue.pow 2).intervalIntegrable 0 L)
    (u := V) (fun t _ => by simp [V])
  set cV := (1 / L) * ∫ s in (0 : ℝ)..L, V s with hcV
  set ψ : ℝ → ℝ := fun t => V t - cV with hψ_def
  have hψ : ∀ t, HasDerivAt ψ (ue t) t := fun t =>
    (hue.integral_hasStrictDerivAt 0 t).hasDerivAt.sub_const cV
  have hψc : Continuous ψ := continuous_iff_continuousAt.2 fun t => (hψ t).continuousAt
  have hibp := sob_ibp hL.le hψ hue hgi
  have hg0 : ∫ τ in (0:ℝ)..L, g τ = 0 := by
    have := hu L ⟨hL.le, le_rfl⟩
    rw [hL0, h0, zero_add] at this
    exact this.symm
  rw [hg0, mul_zero, zero_sub] at hibp
  have hkey : ∫ t in (0:ℝ)..L, u t ^ 2 = -∫ t in (0:ℝ)..L, ψ t * g t := by
    rw [hibp, neg_neg]
    apply intervalIntegral.integral_congr
    intro t ht
    simp only
    rw [hue_eq t (hIcc t ht)]
    have := hu t (hIcc t ht)
    rw [h0, zero_add] at this
    rw [← this]; ring
  have hue2 : ∫ t in (0:ℝ)..L, ue t ^ 2 = ∫ t in (0:ℝ)..L, u t ^ 2 :=
    intervalIntegral.integral_congr fun t ht => by simp only [hue_eq t (hIcc t ht)]
  rw [hue2] at hN
  have hcs := sob_cs hL.le ((hψc.pow 2).intervalIntegrable 0 L) hg2
    (hgi.continuousOn_mul hψc.continuousOn)
  have hconc := sob_alg (A := ∫ t in (0:ℝ)..L, u t ^ 2) (W := ∫ t in (0:ℝ)..L, ψ t ^ 2)
    (B := ∫ t in (0:ℝ)..L, g t ^ 2) (L := L)
    (intervalIntegral.integral_nonneg hL.le fun t _ => sq_nonneg _) hB
    (intervalIntegral.integral_nonneg hL.le fun t _ => sq_nonneg _)
    (by rw [hkey]; exact (neg_le_abs _).trans hcs) hN
  exact sob_sqrt_of_sq hL hB hconc

/-- `L/π` is the best Poincare constant: if a number `C` makes `‖u - ū‖₂ ≤ C ‖u'‖₂` true for
every `u` in `H^1(0, L)` (every running integral `u` of a slope `g` with finite 2-size), then
`C ≥ L/π`. The slow half-wave `cos(π t / L)` reaches `L/π` exactly. -/
theorem poincare_constant_optimal {L : ℝ} (hL : 0 < L) (C : ℝ)
    (hC : ∀ u g : ℝ → ℝ, MemLp g 2 (volume.restrict (Ioc 0 L)) →
      (∀ t ∈ Icc 0 L, u t = u 0 + ∫ τ in (0 : ℝ)..t, g τ) →
      Real.sqrt (∫ t in (0 : ℝ)..L, (u t - (1 / L) * ∫ s in (0 : ℝ)..L, u s) ^ 2)
        ≤ C * Real.sqrt (∫ t in (0 : ℝ)..L, g t ^ 2)) :
    L / π ≤ C := by
  set k := π / L with hk
  have hk0 : k ≠ 0 := (div_pos pi_pos hL).ne'
  have hkL : k * L = π := by rw [hk]; field_simp
  have : IsFiniteMeasure (volume.restrict (Ioc (0:ℝ) L)) :=
    isFiniteMeasure_restrict.2 measure_Ioc_lt_top.ne
  have hder : ∀ x : ℝ, HasDerivAt (fun t => cos (k * t)) (-sin (k * x) * k) x := by
    intro x
    have h1 : HasDerivAt (fun t => k * t) k x := by simpa using (hasDerivAt_id x).const_mul k
    exact h1.cos
  have hmem : MemLp (fun t => -sin (k * t) * k) 2 (volume.restrict (Ioc 0 L)) := by
    refine MemLp.of_bound (by fun_prop) |k| (Filter.Eventually.of_forall fun x => ?_)
    rw [Real.norm_eq_abs, abs_mul, abs_neg]
    exact mul_le_of_le_one_left (abs_nonneg _) (abs_sin_le_one _)
  have hu : ∀ t ∈ Icc 0 L, cos (k * t) = cos (k * 0) + ∫ τ in (0 : ℝ)..t, -sin (k * τ) * k := by
    intro t _
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun x _ => hder x)
      (by apply Continuous.intervalIntegrable; fun_prop)]
    ring
  have h := hC _ _ hmem hu
  have hmean : ∫ s in (0 : ℝ)..L, cos (k * s) = 0 := by
    rw [intervalIntegral.integral_comp_mul_left (fun x => cos x) hk0, integral_cos, hkL]
    simp
  have hcos2 : ∫ t in (0 : ℝ)..L, cos (k * t) ^ 2 = L / 2 := by
    rw [intervalIntegral.integral_comp_mul_left (fun x => cos x ^ 2) hk0, integral_cos_sq, hkL]
    simp only [smul_eq_mul, mul_zero, sin_pi, sin_zero, sub_zero, zero_add]
    rw [hk]; field_simp
  have hsin2 : ∫ t in (0 : ℝ)..L, (-sin (k * t) * k) ^ 2 = k ^ 2 * (L / 2) := by
    have e : (fun t => (-sin (k * t) * k) ^ 2) = fun t => k ^ 2 * sin (k * t) ^ 2 := by
      funext t; ring
    rw [e, intervalIntegral.integral_const_mul,
      intervalIntegral.integral_comp_mul_left (fun x => sin x ^ 2) hk0, integral_sin_sq, hkL]
    simp only [smul_eq_mul, mul_zero, sin_pi, sin_zero, sub_zero, zero_add, zero_mul]
    rw [hk]; field_simp
  simp only [hmean, mul_zero, sub_zero] at h
  rw [hcos2, hsin2, Real.sqrt_mul (sq_nonneg _),
    Real.sqrt_sq (div_pos pi_pos hL).le] at h
  have hpos : 0 < Real.sqrt (L / 2) := Real.sqrt_pos.2 (by positivity)
  have h1 : 1 ≤ C * k := by
    have : 1 * Real.sqrt (L / 2) ≤ (C * k) * Real.sqrt (L / 2) := by linarith
    exact le_of_mul_le_mul_right this hpos
  rw [hk] at h1
  rw [div_le_iff₀ pi_pos]
  have := mul_le_mul_of_nonneg_right h1 hL.le
  rw [mul_assoc, div_mul_cancel₀ _ hL.ne'] at this
  linarith

/-- Sobolev embedding in one dimension, `H^1(0, L) ↪ C[0, L]`. For `u` in `H^1(0, L)` (the
running integral of a slope `g` with finite 2-size on a record of length `L > 0`): `u` is
continuous on `[0, L]`; any two readings differ by at most the square root of their time gap
times the slope's 2-size, `|u t - u s| ≤ √|t - s| ‖u'‖₂`; no reading is farther from the mean than
`√L ‖u'‖₂`; and every reading obeys `|u t| ≤ ‖u‖₂ / √L + √L ‖u'‖₂`. -/
theorem sobolev_embedding_one_dim {L : ℝ} (hL : 0 < L) {u g : ℝ → ℝ}
    (hg : MemLp g 2 (volume.restrict (Ioc 0 L)))
    (hu : ∀ t ∈ Icc 0 L, u t = u 0 + ∫ τ in (0 : ℝ)..t, g τ) :
    ContinuousOn u (Icc 0 L) ∧
      (∀ s ∈ Icc 0 L, ∀ t ∈ Icc 0 L,
        |u t - u s| ≤ Real.sqrt |t - s| * Real.sqrt (∫ τ in (0 : ℝ)..L, g τ ^ 2)) ∧
      (∀ t ∈ Icc 0 L, |u t - (1 / L) * ∫ s in (0 : ℝ)..L, u s|
        ≤ Real.sqrt L * Real.sqrt (∫ τ in (0 : ℝ)..L, g τ ^ 2)) ∧
      (∀ t ∈ Icc 0 L, |u t| ≤ Real.sqrt (∫ s in (0 : ℝ)..L, u s ^ 2) / Real.sqrt L
        + Real.sqrt L * Real.sqrt (∫ τ in (0 : ℝ)..L, g τ ^ 2)) := by
  obtain ⟨hgi, hg2⟩ := sob_int hL hg
  have hcont := sob_cont hL hgi hu
  have hcont' : ContinuousOn u (uIcc 0 L) := by rwa [uIcc_of_le hL.le]
  set M := Real.sqrt (∫ τ in (0 : ℝ)..L, g τ ^ 2) with hM
  have hM0 : 0 ≤ M := Real.sqrt_nonneg _
  have hhol : ∀ s ∈ Icc 0 L, ∀ t ∈ Icc 0 L, |u t - u s| ≤ Real.sqrt |t - s| * M := by
    intro s hs t ht
    rcases le_total s t with hst | hts
    · rw [abs_of_nonneg (sub_nonneg.2 hst)]
      exact sob_holder hgi hg2 hu hs ht hst
    · rw [abs_sub_comm (u t), abs_sub_comm t s, abs_of_nonneg (sub_nonneg.2 hts)]
      exact sob_holder hgi hg2 hu ht hs hts
  have hmean : ∀ t ∈ Icc 0 L, |u t - (1 / L) * ∫ s in (0 : ℝ)..L, u s| ≤ Real.sqrt L * M := by
    intro t ht
    have hbound : ∀ x ∈ uIoc (0:ℝ) L, ‖u t - u x‖ ≤ Real.sqrt L * M := by
      intro x hx
      rw [uIoc_of_le hL.le] at hx
      have hx' : x ∈ Icc 0 L := Ioc_subset_Icc_self hx
      rw [Real.norm_eq_abs, abs_sub_comm]
      refine (hhol t ht x hx').trans (mul_le_mul_of_nonneg_right ?_ hM0)
      apply Real.sqrt_le_sqrt
      rw [abs_le]; constructor <;> linarith [hx'.1, hx'.2, ht.1, ht.2]
    have hI := intervalIntegral.norm_integral_le_of_norm_le_const hbound
    rw [intervalIntegral.integral_sub intervalIntegrable_const hcont'.intervalIntegrable,
      intervalIntegral.integral_const, smul_eq_mul, sub_zero, Real.norm_eq_abs,
      abs_of_pos hL] at hI
    have e : u t - (1 / L) * ∫ s in (0 : ℝ)..L, u s = (1 / L) * (L * u t - ∫ s in (0:ℝ)..L, u s) := by
      field_simp
    rw [e, abs_mul, abs_of_pos (by positivity : (0:ℝ) < 1 / L)]
    calc 1 / L * |L * u t - ∫ s in (0:ℝ)..L, u s| ≤ 1 / L * (Real.sqrt L * M * L) := by gcongr
      _ = Real.sqrt L * M := by field_simp
  refine ⟨hcont, hhol, hmean, ?_⟩
  intro t ht
  have hcs := sob_cs hL.le (f := fun _ => (1:ℝ)) (h := u) (by simp)
    ((hcont'.pow 2).intervalIntegrable) (by simpa using hcont'.intervalIntegrable)
  simp only [one_mul, one_pow, intervalIntegral.integral_const, smul_eq_mul, mul_one,
    sub_zero] at hcs
  have hsL : 0 < Real.sqrt L := Real.sqrt_pos.2 hL
  have hc : |(1 / L) * ∫ s in (0 : ℝ)..L, u s| ≤ Real.sqrt (∫ s in (0 : ℝ)..L, u s ^ 2) / Real.sqrt L := by
    rw [abs_mul, abs_of_pos (by positivity : (0:ℝ) < 1 / L)]
    have hLs : L = Real.sqrt L * Real.sqrt L := (Real.mul_self_sqrt hL.le).symm
    calc 1 / L * |∫ s in (0 : ℝ)..L, u s|
        ≤ 1 / L * (Real.sqrt L * Real.sqrt (∫ s in (0 : ℝ)..L, u s ^ 2)) := by gcongr
      _ = Real.sqrt (∫ s in (0 : ℝ)..L, u s ^ 2) / Real.sqrt L := by
        field_simp; rw [Real.sq_sqrt hL.le]
  calc |u t| = |(1 / L) * (∫ s in (0 : ℝ)..L, u s) + (u t - (1 / L) * ∫ s in (0 : ℝ)..L, u s)| := by
        ring_nf
    _ ≤ |(1 / L) * ∫ s in (0 : ℝ)..L, u s| + |u t - (1 / L) * ∫ s in (0 : ℝ)..L, u s| :=
        abs_add_le _ _
    _ ≤ _ := add_le_add hc (hmean t ht)

-- The storm day, in exact fractions (hours, metres): 1 → 8/5 m over hours 0 to 6,
-- then 8/5 → 28/25 m over hours 6 to 24.
-- Slopes: +1/10 m/h on the rise, -2/75 m/h on the drain.
example : ((8 : ℚ) / 5 - 1) / 6 = 1 / 10 := by norm_num
example : ((28 : ℚ) / 25 - 8 / 5) / 18 = -2 / 75 := by norm_num
-- Mean level: (6 × (1 + 8/5)/2 + 18 × (8/5 + 28/25)/2) / 24 = 269/200 m (1.345 m).
example : ((6 : ℚ) * ((1 + 8 / 5) / 2) + 18 * ((8 / 5 + 28 / 25) / 2)) / 24 = 269 / 200 := by
  norm_num
-- Departures at hours 0, 6, 24: -69/200, 51/200, -9/40 m.
example : (1 : ℚ) - 269 / 200 = -69 / 200 ∧ (8 / 5 : ℚ) - 269 / 200 = 51 / 200 ∧
    (28 / 25 : ℚ) - 269 / 200 = -9 / 40 := by norm_num
-- Departure energy: each piece is width × (a² + ab + b²)/3; total 2709/5000 m² h (0.5418).
example : let a : ℚ := -69 / 200; let b : ℚ := 51 / 200; let c : ℚ := -9 / 40
    6 * ((a ^ 2 + a * b + b ^ 2) / 3) + 18 * ((b ^ 2 + b * c + c ^ 2) / 3) = 2709 / 5000 := by
  norm_num
-- Slope energy: 6 × (1/10)² + 18 × (2/75)² = 3/50 + 8/625 = 91/1250 m²/h (0.0728).
example : (6 : ℚ) * (1 / 10) ^ 2 = 3 / 50 ∧ (18 : ℚ) * (2 / 75) ^ 2 = 8 / 625 ∧
    (3 : ℚ) / 50 + 8 / 625 = 91 / 1250 := by norm_num
-- Mean value theorem bound: 24 h × 1/10 m/h = 12/5 m (2.4 m).
example : (24 : ℚ) * (1 / 10) = 12 / 5 := by norm_num
-- Holder on the rise: (√6 × √(3/50))² = 6 × 3/50 = 9/25 = (3/5)², exactly the true rise 0.6 m.
example : (6 : ℚ) * (3 / 50) = (3 / 5) ^ 2 := by norm_num
-- A sensor offset of +1 m moves the mean to 469/200 m (2.345 m).
example : (269 : ℚ) / 200 + 1 = 469 / 200 := by norm_num

#print axioms poincare_inequality_interval
#print axioms poincare_constant_optimal
#print axioms sobolev_embedding_one_dim
#print axioms sob_cs
#print axioms sob_ibp
#print axioms sob_dirichlet_shift
#print axioms sob_dirichlet_C1
#print axioms sob_cont
#print axioms sob_ext
#print axioms sob_alg
#print axioms sob_sqrt_of_sq
#print axioms sob_neumann_sq
#print axioms sob_int
#print axioms sob_holder
