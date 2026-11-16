-- The transform rulebook: for an integrable signal on the line, with the transform f-hat(ξ) = ∫ f(t) e^(−2πiξt) dt, a delay turns the transform, a frequency shift slides it, a stretch rescales it, transforming twice flips time, and a derivative becomes multiplication by 2πiξ.
import Mathlib.Analysis.Fourier.FourierTransformDeriv
import Mathlib.Analysis.Fourier.Inversion

open MeasureTheory Complex Real
open scoped FourierTransform

/-- Helper: a delay by `t₀` multiplies the transform by `e^(−2πiξt₀)`. -/
theorem fourier_shift_aux (g : ℝ → ℂ) (t₀ ξ : ℝ) :
    𝓕 (fun t : ℝ => g (t - t₀)) ξ = cexp (-2 * π * I * ξ * t₀) * 𝓕 g ξ := by
  rw [Real.fourier_real_eq_integral_exp_smul, Real.fourier_real_eq_integral_exp_smul,
    ← integral_const_mul]
  have h := integral_sub_right_eq_self (μ := volume)
    (fun u : ℝ => cexp (↑(-2 * π * (u + t₀) * ξ) * I) • g u) t₀
  simp only [sub_add_cancel] at h
  rw [h]
  congr 1 with u
  rw [smul_eq_mul, smul_eq_mul, ← mul_assoc, ← Complex.exp_add]
  congr 2
  push_cast
  ring

/-- Helper: a stretch by `s ≠ 0` gives `|s|` times the transform read at `sξ`. -/
theorem fourier_scale_aux (g : ℝ → ℂ) (s : ℝ) (hs : s ≠ 0) (ξ : ℝ) :
    𝓕 (fun t : ℝ => g (t / s)) ξ = ((|s| : ℝ) : ℂ) * 𝓕 g (s * ξ) := by
  rw [Real.fourier_real_eq_integral_exp_smul, Real.fourier_real_eq_integral_exp_smul]
  have h := Measure.integral_comp_div (fun y : ℝ => cexp (↑(-2 * π * (y * s) * ξ) * I) • g y) s
  simp only [div_mul_cancel₀ _ hs] at h
  rw [h, Complex.real_smul]
  congr 2 with y
  congr 3
  push_cast
  ring

/-- Shift, modulation and scaling (the card's main formula). For an absolutely integrable
signal `f` and a stretch factor `s ≠ 0`, at every frequency `ξ` (in hertz), with
`f-hat(ξ) = ∫ f(t) e^(−2πiξt) dt` (Mathlib's `𝓕`):
* a delay by `t₀` turns the transform: `f(t − t₀) ↦ e^(−2πiξt₀) f-hat(ξ)`;
* multiplying by the arrow `e^(2πiξ₀t)` slides it: `↦ f-hat(ξ − ξ₀)`;
* a stretch by `s` rescales both axes: `f(t/s) ↦ |s| f-hat(sξ)`;
* stretch first, then delay: `f((t − t₀)/s) ↦ |s| f-hat(sξ) e^(−2πiξt₀)`. -/
theorem fourier_shift_modulation_scale (f : ℝ → ℂ) (hf : Integrable f)
    (t₀ ξ₀ s : ℝ) (hs : s ≠ 0) (ξ : ℝ) :
    𝓕 (fun t : ℝ => f (t - t₀)) ξ = cexp (-2 * π * I * ξ * t₀) * 𝓕 f ξ ∧
    𝓕 (fun t : ℝ => cexp (2 * π * I * ξ₀ * t) * f t) ξ = 𝓕 f (ξ - ξ₀) ∧
    𝓕 (fun t : ℝ => f (t / s)) ξ = ((|s| : ℝ) : ℂ) * 𝓕 f (s * ξ) ∧
    𝓕 (fun t : ℝ => f ((t - t₀) / s)) ξ =
      ((|s| : ℝ) : ℂ) * 𝓕 f (s * ξ) * cexp (-2 * π * I * ξ * t₀) := by
  refine ⟨fourier_shift_aux f t₀ ξ, ?_, fourier_scale_aux f s hs ξ, ?_⟩
  · rw [Real.fourier_real_eq_integral_exp_smul, Real.fourier_real_eq_integral_exp_smul]
    congr 1 with t
    rw [smul_eq_mul, smul_eq_mul, ← mul_assoc, ← Complex.exp_add]
    congr 2
    push_cast
    ring
  · rw [fourier_shift_aux (fun t : ℝ => f (t / s)) t₀ ξ, fourier_scale_aux f s hs ξ]
    exact mul_comm _ _

/-- Duality: transforming twice flips time. If `f` is continuous and both `f` and its
transform are absolutely integrable, then the transform of `f-hat` is `f(−ξ)`. -/
theorem fourier_fourier_eq_comp_neg (f : ℝ → ℂ) (hc : Continuous f) (hf : Integrable f)
    (hf' : Integrable (𝓕 f)) (ξ : ℝ) :
    𝓕 (𝓕 f) ξ = f (-ξ) := by
  have h := hf.fourierInv_fourier_eq hf' (hc.continuousAt (x := -ξ))
  rw [fourierInv_eq_fourier_neg, neg_neg] at h
  exact h

/-- The derivative rules, both directions.
* Time side: if `f` has no jumps (it is differentiable) and both `f` and its slope `f'` are
  absolutely integrable, then `f'` has transform `2πiξ f-hat(ξ)`.
* Frequency side: if `f` and `t f(t)` are absolutely integrable, then `f-hat` has a slope
  at every `ξ`, and that slope is the transform of `−2πi t f(t)`. -/
theorem fourier_deriv_rules :
    (∀ f : ℝ → ℂ, Differentiable ℝ f → Integrable f → Integrable (deriv f) →
      ∀ ξ : ℝ, 𝓕 (deriv f) ξ = 2 * π * I * ξ * 𝓕 f ξ) ∧
    (∀ f : ℝ → ℂ, Integrable f → Integrable (fun t : ℝ => (t : ℂ) * f t) →
      ∀ ξ : ℝ, HasDerivAt (𝓕 f) (𝓕 (fun t : ℝ => -2 * π * I * t * f t) ξ) ξ) := by
  refine ⟨fun f hd hf hf' ξ => ?_, fun f hf hf' ξ => ?_⟩
  · rw [Real.fourier_deriv hf hd hf']
    simp only [smul_eq_mul]
  · have h := Real.hasDerivAt_fourier hf (by simpa only [Complex.real_smul] using hf') ξ
    simpa only [Complex.real_smul, smul_eq_mul] using h

/-! The card's worked shutter, in milliseconds and kilohertz: plain exposure 1 ms,
stretch 2, delay 3 ms, frequency 250 Hz = 1/4 kHz. -/

-- The new pulse opens at 3 − 2 × 1/2 = 2 ms and closes at 3 + 2 × 1/2 = 4 ms.
example : (3 : ℚ) - 2 * (1 / 2) = 2 ∧ (3 : ℚ) + 2 * (1 / 2) = 4 := by norm_num
-- The stretch reads the plain transform at 2 × 250 = 500 Hz.
example : (2 : ℕ) * 250 = 500 := by decide
-- Turns of the arrow: 250 Hz × 3 ms = 1/4 kHz × 3 ms = 3/4 turn.
example : (1 / 4 : ℚ) * 3 = 3 / 4 := by norm_num
-- Delay first, then stretch: the centre lands at 2 × 3 = 6 ms, so 1.5 turns, not 0.75.
example : (2 : ℚ) * 3 = 6 ∧ (1 / 4 : ℚ) * 6 = 3 / 2 := by norm_num

#print axioms fourier_shift_aux
#print axioms fourier_scale_aux
#print axioms fourier_shift_modulation_scale
#print axioms fourier_fourier_eq_comp_neg
#print axioms fourier_deriv_rules
