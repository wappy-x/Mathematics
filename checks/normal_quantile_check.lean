-- Normal quantiles: every tail chance strictly between 0 and 1 has exactly one standard normal cutoff, and stretching by the spread and shifting by the centre gives the cutoff for any normal law.
import Mathlib.Probability.CDF
import Mathlib.Probability.Distributions.Gaussian.Real

open MeasureTheory ProbabilityTheory
open scoped NNReal

lemma nq_cdf_eq_integral (x : ℝ) :
    cdf (gaussianReal 0 1) x = ∫ t in Set.Iic x, gaussianPDFReal 0 1 t := by
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Iic
      (fun t _ => gaussianPDFReal_nonneg _ _ t))]

lemma nq_continuous_pdf : Continuous (gaussianPDFReal 0 1) := by
  rw [gaussianPDFReal_def]; fun_prop

lemma nq_hasDerivAt (z : ℝ) :
    HasDerivAt (cdf (gaussianReal 0 1)) (gaussianPDFReal 0 1 z) z := by
  have hI : ∀ a, IntegrableOn (gaussianPDFReal 0 1) (Set.Iic a) :=
    fun a => (integrable_gaussianPDFReal 0 1).integrableOn
  have hfun : (cdf (gaussianReal 0 1) : ℝ → ℝ) =
      fun x => cdf (gaussianReal 0 1) 0 + ∫ t in (0:ℝ)..x, gaussianPDFReal 0 1 t := by
    funext x
    rw [← intervalIntegral.integral_Iic_sub_Iic (hI 0) (hI x), nq_cdf_eq_integral,
      nq_cdf_eq_integral]
    ring
  rw [hfun]
  exact (intervalIntegral.integral_hasDerivAt_right
    (nq_continuous_pdf.intervalIntegrable _ _)
    (nq_continuous_pdf.stronglyMeasurableAtFilter _ _)
    nq_continuous_pdf.continuousAt).const_add _

lemma nq_strictMono : StrictMono (cdf (gaussianReal 0 1)) :=
  strictMono_of_hasDerivAt_pos nq_hasDerivAt
    (fun _ => gaussianPDFReal_pos _ _ _ one_ne_zero)

lemma nq_continuous : Continuous (cdf (gaussianReal 0 1)) :=
  continuous_iff_continuousAt.2 fun x => (nq_hasDerivAt x).continuousAt

lemma nq_stretch (μ : ℝ) (σ : ℝ≥0) (hσ : 0 < σ) (x : ℝ) :
    cdf (gaussianReal μ (σ ^ 2)) x = cdf (gaussianReal 0 1) ((x - μ) / σ) := by
  have hσ' : (0 : ℝ) < σ := hσ
  have hmap : (gaussianReal 0 1).map (fun t => (σ : ℝ) * t + μ) = gaussianReal μ (σ ^ 2) := by
    have h1 : (fun t : ℝ => (σ : ℝ) * t + μ) = (· + μ) ∘ ((σ : ℝ) * ·) := rfl
    rw [h1, ← Measure.map_map (by fun_prop) (by fun_prop), gaussianReal_map_const_mul,
      gaussianReal_map_add_const]
    congr 1
    · simp
    · ext; simp
  rw [← hmap, cdf_eq_real, cdf_eq_real, map_measureReal_apply (by fun_prop) measurableSet_Iic]
  congr 1
  ext t
  simp only [Set.mem_preimage, Set.mem_Iic]
  rw [le_div_iff₀ hσ']
  constructor <;> intro h <;> linarith

#print axioms nq_cdf_eq_integral
#print axioms nq_continuous_pdf
#print axioms nq_hasDerivAt
#print axioms nq_strictMono
#print axioms nq_continuous
#print axioms nq_stretch

/-- For a tail chance `p` strictly between 0 and 1, there is exactly one standard cutoff `z`
whose left area under the standard bell curve is `p` (the normal quantile). For a normal law with
centre `μ` and positive spread `σ`, the only cutoff with chance `p` below it is `μ + σ z`:
find the quantile once for the standard curve, then stretch by the spread and shift by the centre. -/
theorem normal_quantile_stretch_shift (p μ : ℝ) (σ : ℝ≥0) (hp0 : 0 < p) (hp1 : p < 1)
    (hσ : 0 < σ) :
    ∃ z : ℝ, (∀ z' : ℝ, cdf (gaussianReal 0 1) z' = p ↔ z' = z) ∧
      ∀ x : ℝ, cdf (gaussianReal μ (σ ^ 2)) x = p ↔ x = μ + σ * z := by
  obtain ⟨a, ha⟩ := ((tendsto_cdf_atBot (gaussianReal 0 1)).eventually
    (eventually_lt_nhds hp0)).exists
  obtain ⟨b, hb⟩ := ((tendsto_cdf_atTop (gaussianReal 0 1)).eventually
    (eventually_gt_nhds hp1)).exists
  obtain ⟨z, hz⟩ : p ∈ Set.range (cdf (gaussianReal 0 1)) :=
    intermediate_value_univ a b nq_continuous ⟨ha.le, hb.le⟩
  have hσ' : (0 : ℝ) < σ := hσ
  have key : ∀ z' : ℝ, cdf (gaussianReal 0 1) z' = p ↔ z' = z := by
    intro z'
    rw [← hz]
    exact nq_strictMono.injective.eq_iff
  refine ⟨z, key, fun x => ?_⟩
  rw [nq_stretch μ σ hσ x, key, div_eq_iff hσ'.ne']
  constructor <;> intro h <;> linarith

/-- Symmetry: the area under the standard bell curve left of `-z` equals the area right of `z`,
so the cutoff for tail chance `1 - p` is minus the cutoff for `p`. -/
theorem normal_quantile_symmetry (z : ℝ) :
    cdf (gaussianReal 0 1) (-z) = 1 - cdf (gaussianReal 0 1) z := by
  have := nullSingletonClass_gaussianReal (μ := (0:ℝ)) (v := 1) one_ne_zero
  have hmap : (gaussianReal 0 1).map (fun x => -x) = gaussianReal 0 1 := by
    rw [gaussianReal_map_neg, neg_zero]
  rw [← hmap, cdf_eq_real, cdf_eq_real, map_measureReal_apply (by fun_prop) measurableSet_Iic]
  have hpre : (fun x : ℝ => -x) ⁻¹' Set.Iic (-z) = (Set.Iio z)ᶜ := by
    ext t; simp
  rw [hpre, probReal_compl_eq_one_sub measurableSet_Iio, measureReal_congr Iio_ae_eq_Iic, hmap]

/-- The slope of the standard cumulative curve at `z` is the bell curve's height
`e^(-z^2/2) / sqrt(2π)`; this is the divisor in Newton's step. -/
theorem normal_cdf_slope_eq_density (z : ℝ) :
    HasDerivAt (cdf (gaussianReal 0 1)) (Real.exp (-z ^ 2 / 2) / Real.sqrt (2 * Real.pi)) z := by
  convert nq_hasDerivAt z using 1
  simp [gaussianPDFReal]
  ring

#print axioms normal_quantile_stretch_shift
#print axioms normal_quantile_symmetry
#print axioms normal_cdf_slope_eq_density
