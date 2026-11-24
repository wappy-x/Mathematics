-- The Dirichlet problem by Brownian motion: the half-hot plate's closed form is harmonic in the unit disc and takes the held rim values, every solution on the disc is the Poisson-weighted average of its rim values, and a held hole of radius δ loses its grip as δ shrinks to 0.
import Mathlib.Analysis.Complex.Harmonic.Poisson
import Mathlib.Analysis.InnerProductSpace.Harmonic.Constructions
import Mathlib.Analysis.SpecialFunctions.Trigonometric.ArctanDeriv
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.SpecialFunctions.Complex.Analytic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic

open Complex InnerProductSpace Metric Filter Topology

/-- The settled temperature of the half-hot plate: the unit disc with its rim held at 1 on the
upper half and 0 on the lower half. At the point z = x + iy it is
u = 1/2 + (1/π) arctan(2y / (1 - x² - y²)). -/
noncomputable def plateTemp (z : ℂ) : ℝ :=
  1 / 2 + (1 / Real.pi) * Real.arctan (2 * z.im / (1 - ‖z‖ ^ 2))

lemma plateTemp_aux_re (z : ℂ) :
    ((1 + z) / (1 - z)).re = (1 - ‖z‖ ^ 2) / Complex.normSq (1 - z) := by
  rw [Complex.div_re, Complex.sq_norm]
  simp only [Complex.normSq_apply, Complex.add_re, Complex.one_re, Complex.sub_re, Complex.add_im, Complex.one_im,
    Complex.sub_im]
  field_simp
  ring

lemma plateTemp_aux_im (z : ℂ) :
    ((1 + z) / (1 - z)).im = 2 * z.im / Complex.normSq (1 - z) := by
  rw [Complex.div_im]
  simp only [Complex.add_re, Complex.one_re, Complex.sub_re, Complex.add_im, Complex.one_im,
    Complex.sub_im]
  field_simp
  ring

lemma plateTemp_eq_arg {z : ℂ} (hz : z ∈ ball (0 : ℂ) 1) :
    plateTemp z = 1 / 2 + (1 / Real.pi) * (Complex.log ((1 + z) / (1 - z))).im := by
  have hz1 : ‖z‖ < 1 := by simpa using hz
  have hne : (1 - z) ≠ 0 := by
    intro h
    have : z = 1 := by linear_combination -h
    simp [this] at hz1
  have hN : 0 < Complex.normSq (1 - z) := Complex.normSq_pos.2 hne
  have hre : 0 < ((1 + z) / (1 - z)).re := by
    rw [plateTemp_aux_re]
    apply div_pos _ hN
    nlinarith [norm_nonneg z]
  rw [Complex.log_im]
  have harg := Complex.abs_arg_lt_pi_div_two_iff.2 (Or.inl hre)
  rw [abs_lt] at harg
  rw [← Real.arctan_tan harg.1 harg.2, Complex.tan_arg, plateTemp_aux_re, plateTemp_aux_im,
    plateTemp]
  congr 3
  field_simp

lemma plateTemp_harmonic : HarmonicOnNhd plateTemp (ball (0 : ℂ) 1) := by
  intro z hz
  have hz1 : ‖z‖ < 1 := by simpa using hz
  have hne : (1 - z) ≠ 0 := by
    intro h
    have : z = 1 := by linear_combination -h
    simp [this] at hz1
  have hN : 0 < Complex.normSq (1 - z) := Complex.normSq_pos.2 hne
  have hre : 0 < ((1 + z) / (1 - z)).re := by
    rw [plateTemp_aux_re]
    apply div_pos _ hN
    nlinarith [norm_nonneg z]
  have hev : plateTemp =ᶠ[𝓝 z]
      ((fun _ => (1 / 2 : ℝ)) + (1 / Real.pi) • (fun w => (Complex.log ((1 + w) / (1 - w))).im)) := by
    filter_upwards [isOpen_ball.mem_nhds hz] with w hw
    rw [plateTemp_eq_arg hw]
    simp
  rw [harmonicAt_congr_nhds hev]
  apply (harmonicAt_const _).add
  apply HarmonicAt.const_smul
  apply AnalyticAt.harmonicAt_im
  apply AnalyticAt.clog
  · apply AnalyticAt.div (by fun_prop) (by fun_prop) hne
  · exact Or.inl hre

lemma plateTemp_rim_limit {z : ℂ} (hz : ‖z‖ = 1) (hzi : z.im ≠ 0) :
    Tendsto plateTemp (𝓝[ball (0 : ℂ) 1] z) (𝓝 (if 0 < z.im then 1 else 0)) := by
  have hden : Tendsto (fun w : ℂ => 1 - ‖w‖ ^ 2) (𝓝[ball (0 : ℂ) 1] z) (𝓝[>] 0) := by
    apply tendsto_nhdsWithin_iff.2 ⟨?_, ?_⟩
    · apply tendsto_nhdsWithin_of_tendsto_nhds
      have : (0 : ℝ) = 1 - ‖z‖ ^ 2 := by rw [hz]; norm_num
      rw [this]
      exact (continuous_const.sub (continuous_norm.pow 2)).tendsto z
    · apply eventually_nhdsWithin_of_forall
      intro w hw
      have hw1 : ‖w‖ < 1 := by simpa using hw
      show 0 < 1 - ‖w‖ ^ 2
      nlinarith [norm_nonneg w]
  have hinv : Tendsto (fun w : ℂ => (1 - ‖w‖ ^ 2)⁻¹) (𝓝[ball (0 : ℂ) 1] z) atTop :=
    tendsto_inv_nhdsGT_zero.comp hden
  have hnum : Tendsto (fun w : ℂ => 2 * w.im) (𝓝[ball (0 : ℂ) 1] z) (𝓝 (2 * z.im)) :=
    tendsto_nhdsWithin_of_tendsto_nhds
      ((continuous_const.mul Complex.continuous_im).tendsto z)
  have hpi : Real.pi ≠ 0 := Real.pi_ne_zero
  rcases lt_or_gt_of_ne hzi with hneg | hpos
  · have h1 : Tendsto (fun w : ℂ => 2 * w.im * (1 - ‖w‖ ^ 2)⁻¹) (𝓝[ball (0 : ℂ) 1] z) atBot :=
      hnum.neg_mul_atTop (by linarith) hinv
    have h2 := ((Real.tendsto_arctan_atBot.mono_right nhdsWithin_le_nhds).comp h1).const_mul
      (1 / Real.pi) |>.const_add (1 / 2)
    have hn : ¬ (0 < z.im) := by linarith
    simp only [hn, ↓reduceIte]
    convert h2 using 2
    · simp [plateTemp, div_eq_mul_inv]
    · field_simp; ring
  · have h1 : Tendsto (fun w : ℂ => 2 * w.im * (1 - ‖w‖ ^ 2)⁻¹) (𝓝[ball (0 : ℂ) 1] z) atTop :=
      hnum.pos_mul_atTop (by linarith) hinv
    have h2 := ((Real.tendsto_arctan_atTop.mono_right nhdsWithin_le_nhds).comp h1).const_mul
      (1 / Real.pi) |>.const_add (1 / 2)
    simp only [hpos, ↓reduceIte]
    convert h2 using 2
    · simp [plateTemp, div_eq_mul_inv]
    · field_simp; ring

lemma norm_sq_exp_sub (r φ s : ℝ) :
    ‖exp (s * I) - r * exp (φ * I)‖ ^ 2 = 1 - 2 * r * Real.cos (φ - s) + r ^ 2 := by
  rw [Complex.sq_norm, Complex.normSq_apply]
  simp only [Complex.sub_re, Complex.sub_im, Complex.mul_re, Complex.mul_im,
    Complex.exp_ofReal_mul_I_re, Complex.exp_ofReal_mul_I_im, Complex.ofReal_re,
    Complex.ofReal_im, zero_mul, sub_zero, add_zero]
  rw [Real.cos_sub]
  linear_combination Real.sin_sq_add_cos_sq s + r ^ 2 * Real.sin_sq_add_cos_sq φ

#print axioms plateTemp_aux_re
#print axioms plateTemp_aux_im
#print axioms plateTemp_eq_arg
#print axioms plateTemp_harmonic
#print axioms plateTemp_rim_limit
#print axioms norm_sq_exp_sub

/-- The half-hot plate solves the Dirichlet problem: its settled temperature
u = 1/2 + (1/π) arctan(2y / (1 - x² - y²)) is harmonic inside the unit disc, and as the point
approaches any rim point where the held value is continuous (every rim point off the real axis)
it tends to the held value there: 1 on the upper half of the rim, 0 on the lower half. -/
theorem half_hot_plate_solves_dirichlet :
    HarmonicOnNhd plateTemp (ball (0 : ℂ) 1) ∧
      ∀ z : ℂ, ‖z‖ = 1 → z.im ≠ 0 →
        Tendsto plateTemp (𝓝[ball (0 : ℂ) 1] z) (𝓝 (if 0 < z.im then 1 else 0)) := by
  exact ⟨plateTemp_harmonic, fun z hz hzi => plateTemp_rim_limit hz hzi⟩

/-- Any solution is the Poisson average: if h is harmonic inside the unit disc and continuous up
to the rim, then at the point at distance r < 1 from the centre and angle φ, h equals the average
of its rim values h(e^{is}) weighted by the Poisson kernel
(1/(2π)) (1 - r²) / (1 - 2r cos(φ - s) + r²) ds, the density of where the Brownian path exits. -/
theorem harmonic_eq_poisson_average (h : ℂ → ℝ) (hh : HarmonicContOnCl h (ball (0 : ℂ) 1))
    (r φ : ℝ) (hr0 : 0 ≤ r) (hr1 : r < 1) :
    h (r * exp (φ * I)) =
      (1 / (2 * Real.pi)) * ∫ s in (0 : ℝ)..2 * Real.pi,
        (1 - r ^ 2) / (1 - 2 * r * Real.cos (φ - s) + r ^ 2) * h (exp (s * I)) := by
  have hnw : ‖(r : ℂ) * exp (φ * I)‖ = r := by
    rw [norm_mul, Complex.norm_exp_ofReal_mul_I, Complex.norm_real, Real.norm_eq_abs,
      abs_of_nonneg hr0, mul_one]
  have hw : (r : ℂ) * exp (φ * I) ∈ ball (0 : ℂ) 1 := by
    rw [mem_ball_zero_iff, hnw]; exact hr1
  rw [← hh.circleAverage_poissonKernel_smul hw, Real.circleAverage_def, smul_eq_mul, one_div]
  congr 1
  apply intervalIntegral.integral_congr
  intro s _
  simp only [Pi.mul_apply, smul_eq_mul, circleMap, poissonKernel_def, zero_add, sub_zero,
    Complex.ofReal_one, one_mul, Complex.norm_exp_ofReal_mul_I, hnw, one_pow, norm_sq_exp_sub]

/-- A held hole loses its grip as it shrinks: for a hole of radius δ (0 < δ < 1) held at 1
inside the unit disc whose rim is held at 0, the temperature ln‖z‖ / ln δ is harmonic in the ring
δ < ‖z‖ < 1, equals 1 on the hole's edge and 0 on the rim; and at any fixed distance r with
0 < r < 1 the temperature ln r / ln δ tends to 0 as δ shrinks to 0. -/
theorem shrinking_hole_loses_grip :
    (∀ δ : ℝ, 0 < δ → δ < 1 →
      HarmonicOnNhd (fun z : ℂ => Real.log ‖z‖ / Real.log δ) {z : ℂ | δ < ‖z‖ ∧ ‖z‖ < 1} ∧
        (∀ z : ℂ, ‖z‖ = δ → Real.log ‖z‖ / Real.log δ = 1) ∧
        (∀ z : ℂ, ‖z‖ = 1 → Real.log ‖z‖ / Real.log δ = 0)) ∧
      ∀ r : ℝ, 0 < r → r < 1 →
        Tendsto (fun δ : ℝ => Real.log r / Real.log δ) (𝓝[>] 0) (𝓝 0) := by
  refine ⟨fun δ hδ0 hδ1 => ⟨?_, ?_, ?_⟩, fun r _ _ => ?_⟩
  · intro z hz
    have hz0 : z ≠ 0 := by
      intro h; subst h; simp at hz; linarith
    have hf : (fun z : ℂ => Real.log ‖z‖ / Real.log δ) =
        (Real.log δ)⁻¹ • (fun z : ℂ => Real.log ‖id z‖) := by
      funext w; simp [div_eq_mul_inv, mul_comm]
    rw [hf]
    exact (analyticAt_id.harmonicAt_log_norm hz0).const_smul
  · intro z hz
    rw [hz]
    exact div_self (Real.log_neg hδ0 hδ1).ne
  · intro z hz
    rw [hz, Real.log_one, zero_div]
  · have := (tendsto_inv_atBot_zero.comp Real.tendsto_log_nhdsGT_zero).const_mul (Real.log r)
    simpa [div_eq_mul_inv] using this

-- The card's worked numbers at the start point (0, 1/2), exact as fractions.
-- At the centre the temperature is exactly 1/2.
example : plateTemp 0 = 1 / 2 := by simp [plateTemp]
-- Room to the rim: 1 - r² = 3/4.
example : (1 : ℚ) - (1 / 2) ^ 2 = 3 / 4 := by norm_num
-- The fraction inside the arctan: 2y / (1 - r²) = 4/3.
example : (2 : ℚ) * (1 / 2) / (1 - (1 / 2) ^ 2) = 4 / 3 := by norm_num
-- On the axis: (1 + r)/(1 - r) = 3, and (a² - 1)/(2a) at a = 3 is the same 4/3.
example : ((1 : ℚ) + 1 / 2) / (1 - 1 / 2) = 3 := by norm_num
example : ((3 : ℚ) ^ 2 - 1) / (2 * 3) = 4 / 3 := by norm_num
-- Poisson weights seen from (0, 1/2): top point 3, bottom point 1/3, side point 3/5.
example : ((1 : ℚ) - (1 / 2) ^ 2) / (1 - 2 * (1 / 2) + (1 / 2) ^ 2) = 3 := by norm_num
example : ((1 : ℚ) - (1 / 2) ^ 2) / (1 + 2 * (1 / 2) + (1 / 2) ^ 2) = 1 / 3 := by norm_num
example : ((1 : ℚ) - (1 / 2) ^ 2) / (1 + (1 / 2) ^ 2) = 3 / 5 := by norm_num
-- Average time to leave, by Dynkin's formula: (1 - r²)/2 = 3/8.
example : ((1 : ℚ) - (1 / 2) ^ 2) / 2 = 3 / 8 := by norm_num

#print axioms half_hot_plate_solves_dirichlet
#print axioms harmonic_eq_poisson_average
#print axioms shrinking_hole_loses_grip
