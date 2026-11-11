-- The Fourier transform: with the card's convention f-hat(ω) = ∫ f(t) e^(−iωt) dt, the Gaussian e^(−t²/2) has transform √(2π) e^(−ω²/2), the one-second flash has transform 2 sin(ω/2)/ω, and the inverse integral with 1/(2π) in front rebuilds any signal with |f| and |f-hat| of finite area wherever it is continuous.
import Mathlib.Analysis.SpecialFunctions.Gaussian.FourierTransform
import Mathlib.Analysis.Fourier.Inversion
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic

open MeasureTheory Complex

/-- The card's Fourier transform, frequency `ω` in radians per second:
`f-hat(ω) = ∫ f(t) e^(−iωt) dt` over the whole real line. (Mathlib's `𝓕` uses
`e^(−2πiωt)` instead, so the card's convention is written out here.) -/
noncomputable def fourierHat (f : ℝ → ℂ) (ω : ℝ) : ℂ :=
  ∫ t : ℝ, f t * cexp (-(I * ω * t))

/-- The card's flash: 1 for −1/2 < t < 1/2, 0 at every other time. -/
noncomputable def flash : ℝ → ℂ :=
  Set.indicator (Set.Ioo (-1 / 2 : ℝ) (1 / 2)) (fun _ => 1)

/-- The Gaussian is its own transform: for every frequency `ω`, the bell `e^(−t²/2)`
transforms to the bell `√(2π) e^(−ω²/2)`. -/
theorem gaussian_fourier_transform_is_gaussian (ω : ℝ) :
    fourierHat (fun t => cexp (-(t : ℂ) ^ 2 / 2)) ω
      = (Real.sqrt (2 * Real.pi) : ℂ) * cexp (-(ω : ℂ) ^ 2 / 2) := by
  have h := fourierIntegral_gaussian (b := (1/2 : ℂ)) (by norm_num) (-(ω : ℂ))
  unfold fourierHat
  have e1 : (fun t : ℝ => cexp (-(t : ℂ) ^ 2 / 2) * cexp (-(I * ω * t)))
      = fun x : ℝ => cexp (I * (-(ω:ℂ)) * x) * cexp (-(1/2 : ℂ) * x ^ 2) := by
    funext x; rw [mul_comm]; congr 2 <;> ring
  rw [e1, h]
  congr 1
  · rw [show (Real.pi : ℂ) / (1/2) = ((2 * Real.pi : ℝ) : ℂ) by push_cast; ring]
    rw [← Complex.ofReal_one, ← Complex.ofReal_ofNat, ← Complex.ofReal_div, ← Complex.ofReal_cpow (by positivity),
      Real.sqrt_eq_rpow]
  · congr 1; ring

/-- The flash's spectrum: at every frequency `ω ≠ 0` the one-second flash transforms to
`2 sin(ω/2)/ω`, and at `ω = 0` to its area, 1. -/
theorem flash_fourier_transform :
    (∀ ω : ℝ, ω ≠ 0 → fourierHat flash ω = ((2 * Real.sin (ω / 2) / ω : ℝ) : ℂ)) ∧
      fourierHat flash 0 = 1 := by
  have key : ∀ ω : ℝ, fourierHat flash ω = ∫ t in (-1/2 : ℝ)..(1/2), cexp (-(I * ω) * t) := by
    intro ω
    unfold fourierHat flash
    rw [intervalIntegral.integral_of_le (by norm_num), integral_Ioc_eq_integral_Ioo,
      ← integral_indicator measurableSet_Ioo]
    congr 1; funext t
    by_cases ht : t ∈ Set.Ioo (-1/2 : ℝ) (1/2)
    · rw [Set.indicator_of_mem ht, Set.indicator_of_mem ht]; simp
    · rw [Set.indicator_of_notMem ht, Set.indicator_of_notMem ht]; simp
  refine ⟨fun ω hω => ?_, ?_⟩
  · rw [key, integral_exp_mul_complex (by simpa using hω)]
    have hω' : (ω : ℂ) ≠ 0 := by exact_mod_cast hω
    push_cast
    rw [Complex.sin, show (↑ω / 2 : ℂ) = ω / 2 by rfl]
    field_simp
    ring_nf
    rw [I_sq]; ring
  · rw [key]; simp; norm_num

/-- The inversion theorem: if `|f|` and `|f-hat|` both have finite area, then wherever `f`
is continuous, the inverse integral `(1/2π) ∫ f-hat(ω) e^(iωt) dω` returns `f(t)`. -/
theorem fourier_inversion_at_continuity_point (f : ℝ → ℂ) (hf : Integrable f)
    (hfhat : Integrable (fourierHat f)) (t : ℝ) (hcont : ContinuousAt f t) :
    (1 / (2 * Real.pi) : ℂ) * ∫ ω : ℝ, fourierHat f ω * cexp (I * ω * t) = f t := by
  have hF : ∀ u : ℝ, FourierTransform.fourier f u = fourierHat f (2 * Real.pi * u) := by
    intro u
    rw [Real.fourier_real_eq_integral_exp_smul]
    unfold fourierHat
    congr 1; funext v
    rw [smul_eq_mul, mul_comm]; congr 2; push_cast; ring
  have h2pi : (2 * Real.pi : ℝ) ≠ 0 := by positivity
  have hint : Integrable (FourierTransform.fourier f) := by
    have := hfhat.comp_mul_left' h2pi
    convert this using 1
    funext u; exact hF u
  have inv := hf.fourierInv_fourier_eq hint hcont
  have hcv := MeasureTheory.Measure.integral_comp_mul_left
    (fun ω : ℝ => fourierHat f ω * cexp (I * ω * t)) (2 * Real.pi)
  have hinv : FourierTransformInv.fourierInv (FourierTransform.fourier f) t
      = ∫ x : ℝ, fourierHat f (2 * Real.pi * x) * cexp (I * ↑(2 * Real.pi * x) * t) := by
    rw [Real.fourierInv_eq']
    congr 1; funext x
    rw [hF, smul_eq_mul, mul_comm]
    congr 2
    simp only [RCLike.inner_apply, conj_trivial]
    push_cast; ring
  rw [← inv, hinv, hcv]
  have hpos : (0 : ℝ) < 2 * Real.pi := by positivity
  rw [abs_of_pos (inv_pos.mpr hpos), Complex.real_smul]
  push_cast
  rw [one_div]

-- Worked numbers, exact.
-- Flash at ω = π: 2 sin(π/2)/π = 2/π.
example : 2 * Real.sin (Real.pi / 2) / Real.pi = 2 / Real.pi := by rw [Real.sin_pi_div_two, mul_one]
-- Flash at ω = 2π: the probe turns once and the sum is 0.
example : 2 * Real.sin (2 * Real.pi / 2) / (2 * Real.pi) = 0 := by rw [show 2 * Real.pi / 2 = Real.pi by ring, Real.sin_pi]; simp
-- Completing the square: −t²/2 − iωt = −(t + iω)²/2 − ω²/2.
example (t ω : ℂ) : -t ^ 2 / 2 - I * ω * t = -(t + I * ω) ^ 2 / 2 - ω ^ 2 / 2 := by linear_combination (ω ^ 2 / 2) * I_sq
-- Cauchy bell at ω = 1: the residue at −i is e^(−1)/(−2i), and −2πi times it is π e^(−1).
example : -2 * Real.pi * I * (cexp (-1) / (-2 * I)) = Real.pi * cexp (-1) := by have := I_ne_zero; field_simp
-- Closing upward instead: 2πi times the residue e/(2i) at i gives π e.
example : 2 * Real.pi * I * (cexp 1 / (2 * I)) = Real.pi * cexp 1 := by have := I_ne_zero; field_simp
-- Cauchy rebuilt at t = 0: (1/2π) × 2π = 1.
example : (1 / (2 * Real.pi)) * (2 * Real.pi) = 1 := by have := Real.pi_ne_zero; field_simp

#print axioms gaussian_fourier_transform_is_gaussian
#print axioms flash_fourier_transform
#print axioms fourier_inversion_at_continuity_point
