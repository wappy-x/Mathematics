-- Tempered distributions: with the card's transform convention φ̂(ω) = ∫ φ(t) e^(−iωt) dt, moved onto Schwartz probes, a constant c transforms to 2πc times a delta, a delta at t₀ transforms to the function e^(−iωt₀), and the inverse transform brings every tempered distribution back.
import Mathlib.Analysis.Distribution.TemperedDistribution
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Tactic.NormNum

open SchwartzMap MeasureTheory FourierTransform Real

noncomputable section

namespace TemperedFourierCard

/-- Rescaling of frequency, `ω ↦ ω / (2π)`. Mathlib's transform uses `e^(−2πi ξ t)`; the card
uses `e^(−iωt)`, so the card's frequency `ω` is Mathlib's `ξ = ω / (2π)`. -/
def freqScale : ℝ ≃L[ℝ] ℝ :=
  ContinuousLinearEquiv.unitsEquivAut ℝ (Units.mk0 (2 * π) Real.two_pi_pos.ne')⁻¹

/-- The card's transform of a Schwartz probe, `φ̂(ω) = ∫ φ(t) e^(−iωt) dt`
(Mathlib's `𝓕 φ` read at `ω / (2π)`). -/
def cardHat : 𝓢(ℝ, ℂ) →L[ℂ] 𝓢(ℝ, ℂ) :=
  (compCLMOfContinuousLinearEquiv ℂ freqScale) ∘L fourierCLM ℂ 𝓢(ℝ, ℂ)

/-- The card's inverse transform of a Schwartz probe,
`𝓕⁻¹ψ(ω) = (1 / 2π) ∫ ψ(t) e^(iωt) dt`. -/
def cardHatInv : 𝓢(ℝ, ℂ) →L[ℂ] 𝓢(ℝ, ℂ) :=
  ((2 * π : ℂ)⁻¹) • ((compCLMOfContinuousLinearEquiv ℂ freqScale) ∘L fourierInvCLM ℂ 𝓢(ℝ, ℂ))

/-- The card's definition: the transform of a tempered distribution `T` is `T̂(φ) = T(φ̂)`. -/
def fourierT : 𝓢'(ℝ, ℂ) →L[ℂ] 𝓢'(ℝ, ℂ) :=
  PointwiseConvergenceCLM.precomp ℂ cardHat

/-- The card's inverse on tempered distributions: `(𝓕⁻¹T)(ψ) = T(𝓕⁻¹ψ)`. -/
def fourierInvT : 𝓢'(ℝ, ℂ) →L[ℂ] 𝓢'(ℝ, ℂ) :=
  PointwiseConvergenceCLM.precomp ℂ cardHatInv


lemma freqScale_apply (x : ℝ) : freqScale x = x * (2 * π)⁻¹ := by
  simp [freqScale, ContinuousLinearEquiv.unitsEquivAut_apply]

lemma cardHat_apply (φ : 𝓢(ℝ, ℂ)) (x : ℝ) :
    cardHat φ x = 𝓕 (φ : ℝ → ℂ) (x * (2 * π)⁻¹) := by
  simp [cardHat, freqScale_apply, SchwartzMap.fourier_coe]

lemma cardHatInv_apply (ψ : 𝓢(ℝ, ℂ)) (x : ℝ) :
    cardHatInv ψ x = (2 * π : ℂ)⁻¹ * 𝓕⁻ (ψ : ℝ → ℂ) (x * (2 * π)⁻¹) := by
  simp [cardHatInv, freqScale_apply, SchwartzMap.fourierInv_coe]

lemma integral_fourier_eq_apply_zero (φ : 𝓢(ℝ, ℂ)) :
    ∫ y : ℝ, 𝓕 (φ : ℝ → ℂ) y = φ 0 := by
  have h0 : 𝓕⁻ (𝓕 φ) = φ := fourierInv_fourier_eq φ
  have h := congrArg (fun f : 𝓢(ℝ, ℂ) => f 0) h0
  simp only [SchwartzMap.fourierInv_coe, SchwartzMap.fourier_coe, Real.fourierInv_eq] at h
  simpa using h

lemma cardHat_cardHatInv (ψ : 𝓢(ℝ, ℂ)) : cardHat (cardHatInv ψ) = ψ := by
  ext y
  rw [cardHat_apply, Real.fourier_real_eq]
  simp_rw [cardHatInv_apply]
  set h : ℝ → ℂ := 𝓕⁻ (ψ : ℝ → ℂ)
  have key : ∀ v : ℝ, 𝐞 (-(v * (y * (2 * π)⁻¹))) • ((2 * π : ℂ)⁻¹ * h (v * (2 * π)⁻¹)) =
      (2 * π : ℂ)⁻¹ * (fun u : ℝ => 𝐞 (-(u * y)) • h u) (v * (2 * π)⁻¹) := by
    intro v
    simp only [Circle.smul_def, smul_eq_mul]
    have : v * (y * (2 * π)⁻¹) = v * (2 * π)⁻¹ * y := by ring
    rw [this]; ring
  simp_rw [key]
  rw [integral_const_mul, Measure.integral_comp_mul_right (fun u : ℝ => 𝐞 (-(u * y)) • h u),
    ← Real.fourier_real_eq, inv_inv, abs_of_pos Real.two_pi_pos]
  have hψ0 : 𝓕 (𝓕⁻ ψ) = ψ := fourier_fourierInv_eq ψ
  have hψ := congrArg (fun f : 𝓢(ℝ, ℂ) => f y) hψ0
  simp only [SchwartzMap.fourier_coe, SchwartzMap.fourierInv_coe] at hψ
  rw [Complex.real_smul, hψ]
  have : (2 * π : ℂ) ≠ 0 := by exact_mod_cast Real.two_pi_pos.ne'
  push_cast
  field_simp

/-- A constant's spectrum is a spike: the constant signal `c` (the tempered distribution
`φ ↦ c ∫ φ`) has transform `2πc δ`, where `δ` reads a probe at frequency 0.
For the steady 8 m/s wind this is `16π δ`. -/
theorem fourier_of_constant_eq_two_pi_mul_delta (c : ℂ) :
    fourierT (c • (volume : Measure ℝ).toTemperedDistribution) =
      ((2 * π : ℂ) * c) • TemperedDistribution.delta (0 : ℝ) := by
  ext φ
  change c • ∫ x : ℝ, cardHat φ x = ((2 * π : ℂ) * c) • φ 0
  simp_rw [cardHat_apply]
  rw [Measure.integral_comp_mul_right (fun y : ℝ => 𝓕 (φ : ℝ → ℂ) y) ((2 * π)⁻¹),
    integral_fourier_eq_apply_zero, inv_inv, abs_of_pos Real.two_pi_pos, Complex.real_smul]
  simp only [smul_eq_mul]
  push_cast
  ring

/-- A spike's spectrum is flat: the delta at time `t₀` transforms to the function
`e^(−iωt₀)`, of size 1 at every frequency, read through probes:
`δ̂_{t₀}(φ) = ∫ e^(−iωt₀) φ(ω) dω`. At `t₀ = 0` this is `δ̂ = 1`. -/
theorem fourier_of_delta_eq_exp (t₀ : ℝ) (φ : 𝓢(ℝ, ℂ)) :
    fourierT (TemperedDistribution.delta t₀) φ =
      ∫ ω : ℝ, Complex.exp (-((ω * t₀ : ℝ) : ℂ) * Complex.I) * φ ω := by
  change cardHat φ t₀ = _
  rw [cardHat_apply, Real.fourier_real_eq]
  congr 1
  ext ω
  rw [Circle.smul_def, Real.fourierChar_apply, smul_eq_mul]
  congr 2
  have : (π : ℂ) ≠ 0 := by exact_mod_cast Real.pi_pos.ne'
  push_cast
  field_simp

/-- Inversion: the inverse transform, applied on the probe's side, brings every tempered
distribution back, `𝓕⁻¹ T̂ = T`. -/
theorem fourierInv_fourier_eq_self (T : 𝓢'(ℝ, ℂ)) :
    fourierInvT (fourierT T) = T := by
  ext ψ
  change T (cardHat (cardHatInv ψ)) = T ψ
  rw [cardHat_cardHatInv]

/-! Whole-number checks from the card's eight-sample rehearsal (Δt = 1/2 s). -/

/-- The wind list: 8 m/s, and `8 + 3 / (1/2) = 14` m/s in the gust sample. -/
example : (8 : ℚ) + 3 / (1 / 2) = 14 := by norm_num

/-- Zero bin of `Δt · DFT` for `8 8 8 8 14 8 8 8`: `(1/2)(7 · 8 + 14) = 35`. -/
example : ((List.range 8).map (fun n => (1 / 2 : ℚ) * (if n = 4 then 14 else 8))).sum = 35 := by
  norm_num [List.range_succ]

/-- Bin k = 4, where `e^(−2πi·4n/8) = (−1)^n`: `(1/2) Σ (−1)^n x_n = 3`, the gust's flat 3. -/
example : ((List.range 8).map
    (fun n => (1 / 2 : ℚ) * (-1) ^ n * (if n = 4 then 14 else 8))).sum = 3 := by
  norm_num [List.range_succ]

/-- Zero bin at N = 128 (a 64 s record): `(1/2)(127 · 8 + 14) = 515`. -/
example : (1 / 2 : ℚ) * (127 * 8 + 14) = 515 := by norm_num

#print axioms freqScale_apply
#print axioms cardHat_apply
#print axioms cardHatInv_apply
#print axioms integral_fourier_eq_apply_zero
#print axioms cardHat_cardHatInv
#print axioms fourier_of_constant_eq_two_pi_mul_delta
#print axioms fourier_of_delta_eq_exp
#print axioms fourierInv_fourier_eq_self

end TemperedFourierCard

end
