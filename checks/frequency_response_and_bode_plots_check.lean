-- Bode plots: a stable linear time-invariant system fed a sine settles to a sine of the same frequency, scaled by the size of its transfer function at jω and shifted by its angle; the car's Bode curves are the sum of its two factors' curves; and a single factor's straight-line magnitude sketch is never more than 10 log10 2 dB off, with that worst error exactly at the corner.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.Analysis.SpecialFunctions.Complex.Arg
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Arctan
import Mathlib.Analysis.SpecialFunctions.Log.Base
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum
import Mathlib.MeasureTheory.Integral.IntegralEqImproper

/-! Setting, in the card's notation.
* The engineers' `j` is Mathlib's `Complex.I`.
* A linear time-invariant system is given by its impulse response `h`, a real function of the
  past time `r ≥ 0`. Started from rest, input `u` (zero before time 0) gives the output
  `y(t) = ∫₀ᵗ h(r) u(t − r) dr` (the card's convolution, Step 1).
* "Stable" is the card's condition in the detailed proof: `∫₀^∞ |h(r)| dr` is finite,
  `IntegrableOn h (Ioi 0)`.
* The transfer function on the imaginary axis is `G(jω) = ∫₀^∞ h(r) e^(−jωr) dr`.
* "Settled" is the limit as `t → ∞`.
* A gain `g` in decibels is `20 log₁₀ g`, Mathlib's `20 * Real.logb 10 g`. -/

open MeasureTheory Set Filter Topology Complex

namespace BodePlots

/-- The output at time `t` of the system with impulse response `h`, started from rest and fed
the input `u` from time 0 on: `y(t) = ∫₀ᵗ h(r) u(t − r) dr`. -/
noncomputable def response (h u : ℝ → ℝ) (t : ℝ) : ℝ :=
  ∫ r in (0 : ℝ)..t, h r * u (t - r)

/-- The transfer function on the imaginary axis, `G(jω) = ∫₀^∞ h(r) e^(−jωr) dr`. -/
noncomputable def freqResponse (h : ℝ → ℝ) (ω : ℝ) : ℂ :=
  ∫ r in Ioi (0 : ℝ), (h r : ℂ) * cexp (-((ω * r : ℝ) : ℂ) * I)


/-- Helper: the size of `1 + x j` is `√(1 + x²)`. -/
theorem norm_one_add_mul_I (x : ℝ) : ‖(1 : ℂ) + (x : ℂ) * I‖ = Real.sqrt (1 + x ^ 2) := by
  have := Complex.norm_add_mul_I 1 x
  simpa using this

/-- Helper: the angle of `1 + x j` is `arctan x`. -/
theorem arg_one_add_mul_I (x : ℝ) : arg ((1 : ℂ) + (x : ℂ) * I) = Real.arctan x := by
  rw [Complex.arg_of_re_nonneg (by simp), norm_one_add_mul_I, Real.arctan_eq_arcsin]
  simp

/-- Helper: `logb` of a square root is half the `logb`. -/
theorem logb_sqrt' (y : ℝ) (hy : 0 ≤ y) :
    Real.logb 10 (Real.sqrt y) = Real.logb 10 y / 2 := by
  unfold Real.logb
  rw [Real.log_sqrt hy]
  ring

/-- **Sine in, same-frequency sine out.** Take a linear time-invariant system with a real
impulse response `h` that is stable (`∫₀^∞ |h(r)| dr` finite). Feed it, from rest, the sine
`u(t) = A sin(ωt)` of any size `A` and any angular frequency `ω`. Once it settles, the output is
the sine `A |G(jω)| sin(ωt + φ(ω))` with `φ(ω) = arg G(jω)`: the difference between the true
output and that sine tends to 0 as `t → ∞`. -/
theorem stable_system_settles_to_scaled_shifted_sine
    (h : ℝ → ℝ) (hstable : IntegrableOn h (Ioi 0)) (A ω : ℝ) :
    Tendsto (fun t => response h (fun s => A * Real.sin (ω * s)) t
        - A * ‖freqResponse h ω‖ * Real.sin (ω * t + arg (freqResponse h ω)))
      atTop (𝓝 0) := by
  set F : ℝ → ℂ := fun r => (h r : ℂ) * cexp (-((ω * r : ℝ) : ℂ) * I) with hF
  set G := freqResponse h ω with hG
  have hFi : IntegrableOn F (Ioi 0) := by
    have hm : AEStronglyMeasurable F (volume.restrict (Ioi 0)) :=
      (Complex.continuous_ofReal.comp_aestronglyMeasurable hstable.aestronglyMeasurable).mul
        (Continuous.aestronglyMeasurable (by fun_prop))
    refine hstable.norm.mono' hm (Eventually.of_forall (fun r => ?_))
    simp only [F, norm_mul, Complex.norm_real, Real.norm_eq_abs]
    rw [show -((ω * r : ℝ) : ℂ) * I = ((-(ω * r) : ℝ) : ℂ) * I by push_cast; ring,
      Complex.norm_exp_ofReal_mul_I, mul_one]
  have hGt : Tendsto (fun t => ∫ r in (0 : ℝ)..t, F r) atTop (𝓝 G) :=
    intervalIntegral_tendsto_integral_Ioi 0 hFi tendsto_id
  have key : ∀ t, 0 ≤ t → response h (fun s => A * Real.sin (ω * s)) t
      = A * (cexp ((ω * t : ℝ) * I) * ∫ r in (0 : ℝ)..t, F r).im := by
    intro t ht
    have hint : IntervalIntegrable (fun r => cexp ((ω * t : ℝ) * I) * F r) volume 0 t := by
      rw [intervalIntegrable_iff_integrableOn_Ioc_of_le ht]
      exact (hFi.mono_set Ioc_subset_Ioi_self).const_mul _
    have hpt : (fun r => h r * (A * Real.sin (ω * (t - r))))
        = fun r => A * Complex.imCLM (cexp ((ω * t : ℝ) * I) * F r) := by
      funext r
      simp only [Complex.imCLM_apply, F]
      rw [show cexp ((ω * t : ℝ) * I) * ((h r : ℂ) * cexp (-((ω * r : ℝ) : ℂ) * I))
          = (h r : ℂ) * cexp (((ω * t - ω * r : ℝ) : ℂ) * I) by
            rw [mul_left_comm, ← Complex.exp_add]; push_cast; ring_nf,
        Complex.im_ofReal_mul, Complex.exp_ofReal_mul_I_im, mul_sub]
      ring
    unfold response
    rw [hpt, intervalIntegral.integral_const_mul,
      ContinuousLinearMap.intervalIntegral_comp_comm _ hint, Complex.imCLM_apply,
      intervalIntegral.integral_const_mul]
  have phase : ∀ θ : ℝ, (cexp (θ * I) * G).im = ‖G‖ * Real.sin (θ + arg G) := by
    intro θ
    rw [Complex.mul_im, Complex.exp_ofReal_mul_I_re, Complex.exp_ofReal_mul_I_im, Real.sin_add]
    have h1 := Complex.norm_mul_cos_arg G
    have h2 := Complex.norm_mul_sin_arg G
    linear_combination (-Real.sin θ) * h1 + (-Real.cos θ) * h2
  have hev : ∀ᶠ t in atTop, response h (fun s => A * Real.sin (ω * s)) t
        - A * ‖G‖ * Real.sin (ω * t + arg G)
      = A * (cexp ((ω * t : ℝ) * I) * ((∫ r in (0 : ℝ)..t, F r) - G)).im := by
    filter_upwards [eventually_ge_atTop 0] with t ht
    rw [key t ht, mul_assoc A ‖G‖, ← phase, mul_sub, Complex.sub_im]
    ring
  rw [tendsto_congr' hev]
  have hlim : Tendsto (fun t => |A| * ‖(∫ r in (0 : ℝ)..t, F r) - G‖) atTop (𝓝 0) := by
    have := (tendsto_iff_norm_sub_tendsto_zero.mp hGt).const_mul |A|
    simpa using this
  refine squeeze_zero_norm' (Eventually.of_forall (fun t => ?_)) hlim
  rw [norm_mul, Real.norm_eq_abs]
  refine mul_le_mul_of_nonneg_left ?_ (abs_nonneg A)
  refine (Complex.abs_im_le_norm _).trans ?_
  rw [norm_mul, Complex.norm_exp_ofReal_mul_I, one_mul]

/-- **The car's Bode curves, one factor at a time.** For the car
`G(s) = K / ((τ₁ s + 1)(τ₂ s + 1))` with steady gain `K > 0`, at every angular frequency `ω`:
in decibels each factor's contribution is subtracted,
`M(ω) = 20 log₁₀ K − 10 log₁₀(1 + ω²τ₁²) − 10 log₁₀(1 + ω²τ₂²)`,
and in angle each factor's lag is added, `φ(ω) = −arctan(ωτ₁) − arctan(ωτ₂)`. -/
theorem car_bode_magnitude_and_phase (K τ₁ τ₂ ω : ℝ) (hK : 0 < K) :
    20 * Real.logb 10 ‖(K : ℂ) / ((τ₁ * (ω * I) + 1) * (τ₂ * (ω * I) + 1))‖
        = 20 * Real.logb 10 K - 10 * Real.logb 10 (1 + ω ^ 2 * τ₁ ^ 2)
          - 10 * Real.logb 10 (1 + ω ^ 2 * τ₂ ^ 2) ∧
      arg ((K : ℂ) / ((τ₁ * (ω * I) + 1) * (τ₂ * (ω * I) + 1)))
        = -Real.arctan (ω * τ₁) - Real.arctan (ω * τ₂) := by
  have e1 : (τ₁ : ℂ) * (ω * I) + 1 = 1 + ((ω * τ₁ : ℝ) : ℂ) * I := by push_cast; ring
  have e2 : (τ₂ : ℂ) * (ω * I) + 1 = 1 + ((ω * τ₂ : ℝ) : ℂ) * I := by push_cast; ring
  rw [e1, e2]
  have n1 : (1 : ℂ) + ((ω * τ₁ : ℝ) : ℂ) * I ≠ 0 := by
    intro h0; have := congrArg Complex.re h0; simp at this
  have n2 : (1 : ℂ) + ((ω * τ₂ : ℝ) : ℂ) * I ≠ 0 := by
    intro h0; have := congrArg Complex.re h0; simp at this
  constructor
  · rw [norm_div, norm_mul, norm_one_add_mul_I, norm_one_add_mul_I, Complex.norm_real,
      Real.norm_eq_abs, abs_of_pos hK]
    have p1 : 0 < Real.sqrt (1 + (ω * τ₁) ^ 2) := Real.sqrt_pos.mpr (by positivity)
    have p2 : 0 < Real.sqrt (1 + (ω * τ₂) ^ 2) := Real.sqrt_pos.mpr (by positivity)
    rw [Real.logb_div hK.ne' (mul_pos p1 p2).ne', Real.logb_mul p1.ne' p2.ne',
      logb_sqrt' _ (by positivity), logb_sqrt' _ (by positivity), mul_pow, mul_pow]
    ring
  · rw [div_eq_mul_inv, Complex.arg_real_mul _ hK]
    have hsum : arg ((1 + ((ω * τ₁ : ℝ) : ℂ) * I) * (1 + ((ω * τ₂ : ℝ) : ℂ) * I))
        = Real.arctan (ω * τ₁) + Real.arctan (ω * τ₂) := by
      rw [Complex.arg_mul n1 n2, arg_one_add_mul_I, arg_one_add_mul_I]
      rw [arg_one_add_mul_I, arg_one_add_mul_I]
      have a1 := Real.arctan_lt_pi_div_two (ω * τ₁)
      have a2 := Real.arctan_lt_pi_div_two (ω * τ₂)
      have b1 := Real.neg_pi_div_two_lt_arctan (ω * τ₁)
      have b2 := Real.neg_pi_div_two_lt_arctan (ω * τ₂)
      constructor <;> linarith
    rw [Complex.arg_inv, hsum]
    have a1 := Real.arctan_lt_pi_div_two (ω * τ₁)
    have a2 := Real.arctan_lt_pi_div_two (ω * τ₂)
    rw [if_neg (by linarith)]
    ring

/-- The exact magnitude in dB of one factor `1 / (1 + jωτ)`. -/
noncomputable def poleDb (τ ω : ℝ) : ℝ :=
  20 * Real.logb 10 ‖(1 : ℂ) / (1 + τ * (ω * I))‖

/-- The straight-line sketch of that factor with corner `ω_c = 1/τ`: flat at 0 dB up to the
corner, then falling 20 dB per decade, `−20 log₁₀(ω/ω_c)`. -/
noncomputable def poleSketchDb (τ ω : ℝ) : ℝ :=
  if ω ≤ 1 / τ then 0 else -20 * Real.logb 10 (ω * τ)

/-- Helper: the exact dB of one factor, `−10 log₁₀(1 + (ωτ)²)`. -/
theorem poleDb_eq (τ ω : ℝ) : poleDb τ ω = -10 * Real.logb 10 (1 + (ω * τ) ^ 2) := by
  unfold poleDb
  have e : (1 : ℂ) + τ * (ω * I) = 1 + ((ω * τ : ℝ) : ℂ) * I := by push_cast; ring
  rw [e, norm_div, norm_one, norm_one_add_mul_I, one_div, Real.logb_inv,
    logb_sqrt' _ (by positivity)]
  ring

/-- **The sketch's worst error is 3.01 dB, at the corner.** For one factor `1 / (1 + jωτ)` with
time constant `τ > 0`, the gap between the exact magnitude and the straight-line sketch, over all
frequencies `ω > 0`, is largest at the corner `ω = 1/τ`, where it is exactly `10 log₁₀ 2` dB
(the true size there is `1/√2`). -/
theorem pole_sketch_worst_error_at_corner (τ : ℝ) (hτ : 0 < τ) :
    IsGreatest {e | ∃ ω : ℝ, 0 < ω ∧ e = |poleDb τ ω - poleSketchDb τ ω|}
      (10 * Real.logb 10 2) ∧
    |poleDb τ (1 / τ) - poleSketchDb τ (1 / τ)| = 10 * Real.logb 10 2 := by
  have l2 : 0 ≤ Real.logb 10 2 := Real.logb_nonneg (by norm_num) (by norm_num)
  have corner : |poleDb τ (1 / τ) - poleSketchDb τ (1 / τ)| = 10 * Real.logb 10 2 := by
    rw [poleDb_eq, poleSketchDb, if_pos le_rfl, one_div_mul_cancel hτ.ne']
    norm_num
    exact l2
  refine ⟨⟨⟨1 / τ, by positivity, corner.symm⟩, ?_⟩, corner⟩
  rintro e ⟨ω, hω, rfl⟩
  have hx : 0 < ω * τ := mul_pos hω hτ
  rw [poleDb_eq, poleSketchDb]
  split_ifs with hc
  · have hx1 : ω * τ ≤ 1 := by
      rw [le_div_iff₀ hτ] at hc; exact hc
    have h0 : 0 ≤ Real.logb 10 (1 + (ω * τ) ^ 2) :=
      Real.logb_nonneg (by norm_num) (by nlinarith)
    have h1 : Real.logb 10 (1 + (ω * τ) ^ 2) ≤ Real.logb 10 2 :=
      Real.logb_le_logb_of_le (by norm_num) (by positivity) (by nlinarith)
    rw [sub_zero, abs_le]
    constructor <;> linarith
  · have hx1 : 1 < ω * τ := by
      have hc' := not_le.mp hc; rw [div_lt_iff₀ hτ] at hc'; exact hc'
    have hsq : Real.logb 10 ((ω * τ) ^ 2) = 2 * Real.logb 10 (ω * τ) := by
      rw [Real.logb_pow]; push_cast; ring
    have h0 : Real.logb 10 ((ω * τ) ^ 2) ≤ Real.logb 10 (1 + (ω * τ) ^ 2) :=
      Real.logb_le_logb_of_le (by norm_num) (by positivity) (by nlinarith)
    have h1 : Real.logb 10 (1 + (ω * τ) ^ 2) ≤ Real.logb 10 (2 * (ω * τ) ^ 2) :=
      Real.logb_le_logb_of_le (by norm_num) (by positivity) (by nlinarith)
    rw [Real.logb_mul (by norm_num) (by positivity)] at h1
    rw [abs_le]
    constructor <;> linarith

end BodePlots

/-! The card's worked numbers, exact. -/

-- Decibels: a gain of 10 is +20 dB, a gain of 1 is 0 dB, a gain of 0.1 = 1/10 is −20 dB.
example : 20 * Real.logb 10 10 = 20 := by
  rw [Real.logb_self_eq_one (by norm_num)]; norm_num
example : 20 * Real.logb 10 1 = 0 := by
  rw [Real.logb_one]; norm_num
example : 20 * Real.logb 10 (1 / 10) = -20 := by
  rw [one_div, Real.logb_inv, Real.logb_self_eq_one (by norm_num)]; norm_num
-- Corners at 1/τ₁ = 1/10 rad/s and 1/τ₂ = 1/(1/2) = 2 rad/s.
example : (1 : ℚ) / 10 = 1 / 10 ∧ (1 : ℚ) / (1 / 2) = 2 := by norm_num
-- Worked numbers at ω = 1 rad/s: ωτ₁ = 1 × 10 = 10 and ωτ₂ = 1 × 1/2 = 1/2,
-- so 1 + (ωτ₁)² = 101 and 1 + (ωτ₂)² = 5/4.
example : (1 : ℚ) * 10 = 10 ∧ (1 : ℚ) * (1 / 2) = 1 / 2 := by norm_num
example : (1 : ℚ) + 10 ^ 2 = 101 ∧ (1 : ℚ) + (1 / 2) ^ 2 = 5 / 4 := by norm_num
-- At a corner, ωτ = 1: the factor 1/(1 + j) has size 1/√2 and angle −45° = −π/4.
example : ‖(1 : ℂ) / (1 + Complex.I)‖ = 1 / Real.sqrt 2 := by
  have := BodePlots.norm_one_add_mul_I 1
  rw [norm_div, norm_one]
  simp only [Complex.ofReal_one, one_mul] at this
  rw [this]; norm_num
example : Complex.arg ((1 : ℂ) / (1 + Complex.I)) = -(Real.pi / 4) := by
  have := BodePlots.arg_one_add_mul_I 1
  simp only [Complex.ofReal_one, one_mul, Real.arctan_one] at this
  rw [one_div, Complex.arg_inv, this, if_neg (by linarith [Real.pi_pos])]
-- The integrator 1/s at ω = 1 and ω = 10: size 1 and 1/10 (0 dB and −20 dB), angle −90°.
example : ‖(1 : ℂ) / (1 * Complex.I)‖ = 1 ∧ ‖(1 : ℂ) / (10 * Complex.I)‖ = 1 / 10 := by
  constructor <;> simp
example : Complex.arg ((1 : ℂ) / (10 * Complex.I)) = -(Real.pi / 2) := by
  have e : (1 : ℂ) / (10 * Complex.I) = ((1 / 10 : ℝ) : ℂ) * (-Complex.I) := by
    field_simp; push_cast; ring_nf; simp
  rw [e, Complex.arg_real_mul _ (by norm_num), Complex.arg_neg_I]
-- The zero 1 + 10s at 1 rad/s is the car's factor 1/(1 + 10s) turned upside down:
-- its size is the reciprocal.
example : ‖(1 : ℂ) + 10 * Complex.I‖ = 1 / ‖(1 : ℂ) / (1 + 10 * Complex.I)‖ := by
  rw [norm_div, norm_one, one_div_one_div]
-- The sweep: four decades at 1,000 steps per decade, ends included, is 4,001 frequencies.
example : 4 * 1000 + 1 = 4001 := by decide

open BodePlots

#print axioms stable_system_settles_to_scaled_shifted_sine
#print axioms car_bode_magnitude_and_phase
#print axioms pole_sketch_worst_error_at_corner
#print axioms norm_one_add_mul_I
#print axioms arg_one_add_mul_I
#print axioms logb_sqrt'
#print axioms poleDb_eq
