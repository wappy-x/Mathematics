-- The Fourier transform of an absolutely integrable signal, and why it fades at infinity: for every integrable signal f, its transform f̂(ξ) = ∫ f(t) e^(−2πiξt) dt is bounded by the area of |f|, is continuous, and tends to zero as |ξ| grows (the Riemann–Lebesgue lemma).
import Mathlib.Analysis.Fourier.RiemannLebesgueLemma

open MeasureTheory Complex

/-- Our explicit integral `∫ f(t) e^(−2πiξt) dt` is Mathlib's Fourier transform `𝓕 f ξ`. -/
theorem fourier_explicit_eq (f : ℝ → ℂ) (ξ : ℝ) :
    (∫ t : ℝ, f t * cexp (-2 * ↑Real.pi * I * ↑ξ * ↑t)) = FourierTransform.fourier f ξ := by
  rw [Real.fourier_real_eq_integral_exp_smul]
  congr 1
  ext t
  rw [smul_eq_mul, mul_comm]
  congr 1
  push_cast
  ring_nf

#print axioms fourier_explicit_eq

/-- The Riemann–Lebesgue lemma: for every signal `f` whose absolute value has finite area
(`f` in L¹), the transform `f̂(ξ) = ∫ f(t) e^(−2πiξt) dt` shrinks to zero as the frequency
grows: for every tolerance `ε > 0` there is a frequency `R` beyond which `|f̂(ξ)| < ε`. -/
theorem fourier_transform_tends_to_zero (f : ℝ → ℂ) (hf : Integrable f) :
    ∀ ε : ℝ, 0 < ε → ∃ R : ℝ, ∀ ξ : ℝ, R < |ξ| →
      ‖∫ t : ℝ, f t * cexp (-2 * ↑Real.pi * I * ↑ξ * ↑t)‖ < ε := by
  intro ε hε
  have h := Real.zero_at_infty_fourier f
  rw [← Metric.cobounded_eq_cocompact, ← comap_norm_atTop] at h
  have h2 := (Metric.tendsto_nhds.mp h) ε hε
  rw [Filter.eventually_comap, Filter.eventually_atTop] at h2
  obtain ⟨R, hR⟩ := h2
  refine ⟨R, fun ξ hξ => ?_⟩
  have := hR |ξ| hξ.le ξ (Real.norm_eq_abs ξ)
  rw [fourier_explicit_eq]
  simpa [dist_zero_right] using this

/-- Bounded by the area: for every `f` in L¹ and every frequency `ξ`, the transform is never
larger than the area of `|f|`, that is `|f̂(ξ)| ≤ ‖f‖₁ = ∫ |f(t)| dt`. -/
theorem fourier_transform_le_l1_norm (f : ℝ → ℂ) (hf : Integrable f) (ξ : ℝ) :
    ‖∫ t : ℝ, f t * cexp (-2 * ↑Real.pi * I * ↑ξ * ↑t)‖ ≤ ∫ t : ℝ, ‖f t‖ := by
  refine (norm_integral_le_integral_norm _).trans (le_of_eq ?_)
  congr 1
  ext t
  rw [norm_mul, norm_exp]
  have : (-2 * ↑Real.pi * I * ↑ξ * ↑t : ℂ).re = 0 := by simp
  rw [this, Real.exp_zero, mul_one]

/-- Continuous: for every `f` in L¹, the transform `ξ ↦ f̂(ξ)` changes continuously with the
frequency `ξ`. -/
theorem fourier_transform_continuous (f : ℝ → ℂ) (hf : Integrable f) :
    Continuous (fun ξ : ℝ => ∫ t : ℝ, f t * cexp (-2 * ↑Real.pi * I * ↑ξ * ↑t)) := by
  simp_rw [fourier_explicit_eq]
  exact VectorFourier.fourierIntegral_continuous Real.continuous_fourierChar
    (innerSL ℝ).continuous₂ hf

#print axioms fourier_transform_tends_to_zero
#print axioms fourier_transform_le_l1_norm
#print axioms fourier_transform_continuous
