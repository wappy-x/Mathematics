-- Complex measures: the total variation of a complex measure is the least measure above it, it is finite, the measure is a size-1 direction times it, and integrals obey the size bound.
import Mathlib.MeasureTheory.Measure.Complex
import Mathlib.MeasureTheory.VectorMeasure.Variation.Basic
import Mathlib.MeasureTheory.VectorMeasure.Integral
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Combinatorics.Enumerative.Bell
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.MeasureTheory.VectorMeasure.Variation.SignedMeasure
import Mathlib.MeasureTheory.VectorMeasure.Decomposition.RadonNikodym
import Mathlib.MeasureTheory.VectorMeasure.WithDensityVec

open MeasureTheory Complex
open scoped ENNReal

variable {α : Type*} [MeasurableSpace α]

/-- The total variation of a complex measure is a finite measure. -/
theorem complexMeasure_variation_isFinite (ν : ComplexMeasure α) :
    IsFiniteMeasure ν.variation := by
  have hle : ν.variation ≤ (ComplexMeasure.re ν).variation + (ComplexMeasure.im ν).variation := by
    apply VectorMeasure.variation_le_of_forall_enorm_le
    intro E hE
    rw [Measure.add_apply]
    refine le_trans ?_ (add_le_add (VectorMeasure.enorm_measure_le_variation _ E)
      (VectorMeasure.enorm_measure_le_variation _ E))
    simp only [ComplexMeasure.re_apply, ComplexMeasure.im_apply]
    rw [← ofReal_norm, ← ofReal_norm, ← ofReal_norm,
      ← ENNReal.ofReal_add (norm_nonneg _) (norm_nonneg _)]
    exact ENNReal.ofReal_le_ofReal (Complex.norm_le_abs_re_add_abs_im _)
  have h1 : IsFiniteMeasure (ComplexMeasure.re ν).variation := by
    rw [← SignedMeasure.totalVariation_eq_variation]; infer_instance
  have h2 : IsFiniteMeasure (ComplexMeasure.im ν).variation := by
    rw [← SignedMeasure.totalVariation_eq_variation]; infer_instance
  exact isFiniteMeasure_of_le _ hle

/-- A complex measure is the measure with density its Radon-Nikodym derivative with respect to
its total variation. -/
theorem complexMeasure_withDensityᵥ_rnDeriv_variation (ν : ComplexMeasure α) :
    ν.variation.withDensityᵥ (ν.rnDeriv ν.variation) = ν := by
  have := complexMeasure_variation_isFinite ν
  have hac : ∀ s : SignedMeasure α, (∀ E, MeasurableSet E → ‖s E‖ ≤ ‖ν E‖) →
      s ≪ᵥ ν.variation.toENNRealVectorMeasure := by
    intro s hs
    refine VectorMeasure.AbsolutelyContinuous.mk fun E hE h0 => ?_
    rw [Measure.toENNRealVectorMeasure_apply_measurable hE] at h0
    have h1 : ‖ν E‖ₑ = 0 := le_antisymm (h0 ▸ VectorMeasure.enorm_measure_le_variation ν E) bot_le
    have h2 : ‖s E‖ = 0 := le_antisymm ((hs E hE).trans (by simpa using h1)) (norm_nonneg _)
    simpa using h2
  have hre := SignedMeasure.withDensityᵥ_rnDeriv_eq (ComplexMeasure.re ν) ν.variation
    (hac _ fun E _ => by rw [Real.norm_eq_abs]; exact Complex.abs_re_le_norm (ν E))
  have him := SignedMeasure.withDensityᵥ_rnDeriv_eq (ComplexMeasure.im ν) ν.variation
    (hac _ fun E _ => by rw [Real.norm_eq_abs]; exact Complex.abs_im_le_norm (ν E))
  ext i hi : 1
  rw [withDensityᵥ_apply (ν.integrable_rnDeriv _) hi]
  apply Complex.ext
  · rw [← RCLike.re_eq_complex_re, ← integral_re (ν.integrable_rnDeriv _).integrableOn,
      RCLike.re_eq_complex_re]
    have := congrArg (fun m : SignedMeasure α => m i) hre
    rw [withDensityᵥ_apply (SignedMeasure.integrable_rnDeriv _ _) hi] at this
    exact this
  · rw [← RCLike.im_eq_complex_im, ← integral_im (ν.integrable_rnDeriv _).integrableOn,
      RCLike.im_eq_complex_im]
    have := congrArg (fun m : SignedMeasure α => m i) him
    rw [withDensityᵥ_apply (SignedMeasure.integrable_rnDeriv _ _) hi] at this
    exact this

/-- Polar form. For every complex measure `ν`, its total variation `|ν|` is a finite measure,
and there is a measurable function `h` with `|h| = 1` almost everywhere for `|ν|` such that
`ν(E) = ∫_E h d|ν|` for every measurable set `E`. -/
theorem complex_measure_polar_form (ν : ComplexMeasure α) :
    IsFiniteMeasure ν.variation ∧
      ∃ h : α → ℂ, Measurable h ∧ (∀ᵐ x ∂ν.variation, ‖h x‖ = 1) ∧
        ∀ E, MeasurableSet E → ν E = ∫ x in E, h x ∂ν.variation := by
  have := complexMeasure_variation_isFinite ν
  refine ⟨inferInstance, ν.rnDeriv ν.variation, ?_, ?_, ?_⟩
  · exact Complex.equivRealProdCLM.symm.continuous.measurable.comp
      ((SignedMeasure.measurable_rnDeriv _ _).prodMk (SignedMeasure.measurable_rnDeriv _ _))
  · have hint := ν.integrable_rnDeriv ν.variation
    have key := Measure.variation_withDensityᵥ hint
    rw [complexMeasure_withDensityᵥ_rnDeriv_variation] at key
    have key2 : ν.variation.withDensity (fun x => ‖ν.rnDeriv ν.variation x‖ₑ)
        = ν.variation.withDensity 1 := by rw [withDensity_one, ← key]
    replace key2 := (withDensity_eq_iff_of_sigmaFinite (g := 1) hint.aestronglyMeasurable.enorm
      measurable_one.aemeasurable).1 key2
    filter_upwards [key2] with x hx
    have : ‖ν.rnDeriv ν.variation x‖ₑ = 1 := by simpa using hx
    rwa [← ofReal_norm, ENNReal.ofReal_eq_one] at this
  · intro E hE
    conv_lhs => rw [← complexMeasure_withDensityᵥ_rnDeriv_variation ν]
    exact withDensityᵥ_apply (ν.integrable_rnDeriv _) hE

/-- The total variation dominates the complex measure, `|ν(E)| ≤ |ν|(E)` for every set `E`,
and it is the smallest such measure: any ordinary measure `μ` with `|ν(E)| ≤ μ(E)` for every
measurable `E` satisfies `|ν| ≤ μ`. -/
theorem variation_least_dominating_measure (ν : ComplexMeasure α) :
    (∀ E, ‖ν E‖ₑ ≤ ν.variation E) ∧
      ∀ μ : Measure α, (∀ E, MeasurableSet E → ‖ν E‖ₑ ≤ μ E) → ν.variation ≤ μ := by
  exact ⟨VectorMeasure.enorm_measure_le_variation ν,
    fun μ hμ => VectorMeasure.variation_le_of_forall_enorm_le hμ⟩

/-- The integral bound. If `∫ |f| d|ν|` is finite, then the integral of `f` against the complex
measure `ν` has size at most `∫ |f| d|ν|`. -/
theorem norm_integral_complex_measure_le (ν : ComplexMeasure α) (f : α → ℂ)
    (hf : Integrable f ν.variation) :
    ‖∫ᵛ x, f x ∂[ContinuousLinearMap.mul ℝ ℂ; ν]‖ ≤ ∫ x, ‖f x‖ ∂ν.variation := by
  have := VectorMeasure.norm_integral_le_integral_norm (B := ContinuousLinearMap.mul ℝ ℂ)
    (μ := ν) (f := f)
  refine this.trans ?_
  calc ‖ContinuousLinearMap.mul ℝ ℂ‖ * ∫ x, ‖f x‖ ∂ν.variation
      ≤ 1 * ∫ x, ‖f x‖ ∂ν.variation := by
        exact mul_le_mul_of_nonneg_right (ContinuousLinearMap.opNorm_mul_le ℝ ℂ)
          (integral_nonneg fun _ => norm_nonneg _)
    _ = _ := one_mul _

-- The half-lap displacement: (e^(iπ) − 1)/i = 2i.
example : (exp (Real.pi * I) - 1) / I = 2 * I := by
  rw [exp_pi_mul_I, div_eq_iff I_ne_zero]; ring_nf; norm_num

-- The full-lap displacement: (e^(2πi) − 1)/i = 0.
example : (exp (2 * Real.pi * I) - 1) / I = 0 := by
  norm_num [exp_two_pi_mul_I]

-- The hexagon cut: six chords of size 2 sin(π/6) = 1 add to 6.
example : 6 * (2 * Real.sin (Real.pi / 6)) = 6 := by
  norm_num [Real.sin_pi_div_six]

-- There are 203 ways to group six stretches into blocks (the Bell number of 6).
example : Nat.bell 6 = 203 := by
  decide +kernel

-- Twelve stretches have 2^12 − 1 = 4095 non-empty unions.
example : 2 ^ 12 - 1 = 4095 := by
  norm_num

#print axioms complex_measure_polar_form
#print axioms variation_least_dominating_measure
#print axioms norm_integral_complex_measure_le
#print axioms complexMeasure_variation_isFinite
#print axioms complexMeasure_withDensityᵥ_rnDeriv_variation
