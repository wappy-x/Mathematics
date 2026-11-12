-- Bayesian optimisation: the expected improvement of a normal reading over the best so far has the closed form (mu - f+) Phi(z) + sigma phi(z), and it rises with both the predicted mean and the spread.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral

open MeasureTheory ProbabilityTheory

noncomputable section

/-- The standard normal CDF, `Φ(z)`: the chance a standard normal variable is at most `z`. -/
abbrev stdNormalCDF (z : ℝ) : ℝ := cdf (gaussianReal 0 1) z

/-- The standard normal density, `φ(z)`: the bell-curve height at `z`. -/
abbrev stdNormalPDF (z : ℝ) : ℝ := gaussianPDFReal 0 1 z

/-- The card's expected-improvement score `EI = (μ - f⁺) Φ(z) + σ φ(z)` with `z = (μ - f⁺)/σ`. -/
abbrev expectedImprovement (fbest μ σ : ℝ) : ℝ :=
  (μ - fbest) * stdNormalCDF ((μ - fbest) / σ) + σ * stdNormalPDF ((μ - fbest) / σ)

lemma stdPDF_eq (z : ℝ) :
    stdNormalPDF z = (√(2 * Real.pi))⁻¹ * Real.exp (-z ^ 2 / 2) := by
  simp [stdNormalPDF, gaussianPDFReal]

#print axioms stdPDF_eq

lemma stdPDF_fun_eq :
    stdNormalPDF = fun x : ℝ => (√(2 * Real.pi))⁻¹ * Real.exp (-x ^ 2 / 2) := by
  funext x; exact stdPDF_eq x

#print axioms stdPDF_fun_eq

lemma stdPDF_continuous : Continuous stdNormalPDF := by
  rw [stdPDF_fun_eq]; fun_prop

#print axioms stdPDF_continuous

lemma stdPDF_hasDerivAt (z : ℝ) : HasDerivAt stdNormalPDF (-z * stdNormalPDF z) z := by
  have h1 : HasDerivAt (fun x : ℝ => -x ^ 2 / 2) (-(2 * z) / 2) z := by
    convert ((hasDerivAt_pow 2 z).neg).div_const 2 using 1
    simp
  have h := (h1.exp).const_mul (√(2 * Real.pi))⁻¹
  rw [stdPDF_eq, stdPDF_fun_eq]
  convert h using 1
  ring

#print axioms stdPDF_hasDerivAt

lemma stdPDF_tendsto_atBot : Filter.Tendsto stdNormalPDF Filter.atBot (nhds 0) := by
  rw [stdPDF_fun_eq]
  have h2 : Filter.Tendsto (fun y : ℝ => y ^ 2 / 2) Filter.atTop Filter.atTop :=
    (Filter.tendsto_pow_atTop two_ne_zero).atTop_div_const (by norm_num)
  have h3 : Filter.Tendsto (fun x : ℝ => -x ^ 2 / 2) Filter.atBot Filter.atBot := by
    have := Filter.tendsto_neg_atTop_atBot.comp (h2.comp Filter.tendsto_neg_atBot_atTop)
    refine this.congr ?_
    intro x; simp [Function.comp, neg_div]
  have h4 := (Real.tendsto_exp_atBot.comp h3).const_mul (√(2 * Real.pi))⁻¹
  simpa using h4

#print axioms stdPDF_tendsto_atBot

lemma integrable_mul_stdPDF : MeasureTheory.Integrable (fun t : ℝ => t * stdNormalPDF t) := by
  have h := (integrable_mul_exp_neg_mul_sq (b := 1 / 2) (by norm_num)).const_mul
    (√(2 * Real.pi))⁻¹
  refine h.congr (Filter.Eventually.of_forall fun x => ?_)
  simp only [stdPDF_eq]
  ring_nf

#print axioms integrable_mul_stdPDF

lemma stdCDF_eq (z : ℝ) : stdNormalCDF z = ∫ t in Set.Iic z, stdNormalPDF t := by
  show cdf (gaussianReal 0 1) z = _
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (integral_nonneg fun t => gaussianPDFReal_nonneg _ _ _)]

#print axioms stdCDF_eq

lemma stdCDF_hasDerivAt (z : ℝ) : HasDerivAt stdNormalCDF (stdNormalPDF z) z := by
  have hint : ∀ a : ℝ, IntegrableOn stdNormalPDF (Set.Iic a) := fun a =>
    (integrable_gaussianPDFReal 0 1).integrableOn
  have heq : stdNormalCDF = fun x => stdNormalCDF 0 + ∫ t in (0 : ℝ)..x, stdNormalPDF t := by
    funext x
    rw [← intervalIntegral.integral_Iic_sub_Iic (hint 0) (hint x), stdCDF_eq, stdCDF_eq]
    ring
  rw [heq]
  have hc := stdPDF_continuous
  exact (intervalIntegral.integral_hasDerivAt_right (hc.intervalIntegrable _ _)
    hc.aestronglyMeasurable.stronglyMeasurableAtFilter hc.continuousAt).const_add _

#print axioms stdCDF_hasDerivAt

lemma stdCDF_pos (z : ℝ) : 0 < stdNormalCDF z := by
  show 0 < cdf (gaussianReal 0 1) z
  rw [cdf_eq_real, measureReal_def]
  apply ENNReal.toReal_pos
  · intro h
    have := gaussianReal_absolutelyContinuous' 0 one_ne_zero h
    simp at this
  · exact measure_ne_top _ _

#print axioms stdCDF_pos

lemma stdPDF_pos (z : ℝ) : 0 < stdNormalPDF z :=
  gaussianPDFReal_pos 0 1 z one_ne_zero

#print axioms stdPDF_pos

lemma integral_Iic_mul_stdPDF (z : ℝ) :
    ∫ t in Set.Iic z, t * stdNormalPDF t = -stdNormalPDF z := by
  have := integral_Iic_of_hasDerivAt_of_tendsto' (a := z) (m := 0)
    (f := fun x => -stdNormalPDF x) (f' := fun t => t * stdNormalPDF t)
    (fun x _ => by
      convert (stdPDF_hasDerivAt x).neg using 1
      ring)
    integrable_mul_stdPDF.integrableOn
    (by simpa using stdPDF_tendsto_atBot.neg)
  simpa using this

#print axioms integral_Iic_mul_stdPDF

lemma stdNormal_partial_expectation (z : ℝ) :
    ∫ t, gaussianPDFReal 0 1 t • max (z - t) 0 = z * stdNormalCDF z + stdNormalPDF z := by
  rw [← setIntegral_eq_integral_of_forall_compl_eq_zero (s := Set.Iic z)]
  swap
  · intro t ht
    simp only [Set.mem_Iic, not_le] at ht
    rw [max_eq_right (by linarith), smul_zero]
  rw [setIntegral_congr_fun measurableSet_Iic
    (g := fun t => z * stdNormalPDF t - t * stdNormalPDF t)]
  swap
  · intro t ht
    simp only [Set.mem_Iic] at ht
    simp only [smul_eq_mul]
    rw [max_eq_left (by linarith)]
    ring
  rw [integral_sub, integral_const_mul, ← stdCDF_eq, integral_Iic_mul_stdPDF]
  · ring
  · exact ((integrable_gaussianPDFReal 0 1).integrableOn).const_mul z
  · exact integrable_mul_stdPDF.integrableOn

#print axioms stdNormal_partial_expectation

/-- Step 3 of the card: if the efficiency `Y` at a setting is normal with mean `μ` and
spread `σ > 0`, then its expected improvement over the best reading so far `f⁺`,
`E[max(Y - f⁺, 0)]`, equals `(μ - f⁺) Φ(z) + σ φ(z)` with `z = (μ - f⁺)/σ`. -/
theorem expected_improvement_closed_form (μ fbest σ : ℝ) (hσ : 0 < σ) :
    ∫ y, max (y - fbest) 0 ∂(gaussianReal μ (Real.toNNReal (σ ^ 2))) =
      (μ - fbest) * stdNormalCDF ((μ - fbest) / σ) +
        σ * stdNormalPDF ((μ - fbest) / σ) := by
  have hσ0 : σ ≠ 0 := hσ.ne'
  have hmeas : gaussianReal μ (Real.toNNReal (σ ^ 2)) =
      (gaussianReal 0 1).map (fun t => μ - σ * t) := by
    have hc : (fun t : ℝ => μ - σ * t) = (fun x => μ - x) ∘ (fun t => σ * t) := rfl
    rw [hc, ← Measure.map_map (by fun_prop) (by fun_prop), gaussianReal_map_const_mul,
      gaussianReal_map_const_sub]
    congr 1
    · simp
    · ext
      simp [sq_nonneg]
  have hcont : Continuous fun y : ℝ => max (y - fbest) 0 := by fun_prop
  rw [hmeas, integral_map (by fun_prop) hcont.aestronglyMeasurable]
  set z := (μ - fbest) / σ with hz
  have hσz : σ * z = μ - fbest := by rw [hz]; field_simp
  have hpt : ∀ t, max (μ - σ * t - fbest) 0 = σ * max (z - t) 0 := by
    intro t
    have h : μ - σ * t - fbest = σ * (z - t) := by linear_combination -hσz
    rw [h, mul_max_of_nonneg _ _ hσ.le, mul_zero]
  simp only [hpt]
  rw [integral_const_mul, integral_gaussianReal_eq_integral_smul one_ne_zero,
    stdNormal_partial_expectation]
  linear_combination (stdNormalCDF z) * hσz

/-- Step 4 of the card: the slope of expected improvement with respect to the predicted
mean `μ` is `Φ(z)`, and with respect to the spread `σ` is `φ(z)`; both slopes are
positive, so expected improvement rises with a higher prediction and with a wider error bar. -/
theorem expected_improvement_slopes (μ fbest σ : ℝ) (hσ : 0 < σ) :
    HasDerivAt (fun m => expectedImprovement fbest m σ)
        (stdNormalCDF ((μ - fbest) / σ)) μ ∧
      HasDerivAt (fun s => expectedImprovement fbest μ s)
        (stdNormalPDF ((μ - fbest) / σ)) σ ∧
      0 < stdNormalCDF ((μ - fbest) / σ) ∧
      0 < stdNormalPDF ((μ - fbest) / σ) := by
  have hσ0 : σ ≠ 0 := hσ.ne'
  have hg : HasDerivAt (fun m : ℝ => (m - fbest) / σ) (1 / σ) μ :=
    ((hasDerivAt_id' μ).sub_const fbest).div_const σ
  have hgs : HasDerivAt (fun s : ℝ => (μ - fbest) / s)
      ((0 * σ - (μ - fbest) * 1) / σ ^ 2) σ :=
    (hasDerivAt_const σ (μ - fbest)).div (hasDerivAt_id' σ) hσ0
  refine ⟨?_, ?_, stdCDF_pos _, stdPDF_pos _⟩
  · have h := (((hasDerivAt_id' μ).sub_const fbest).mul
      ((stdCDF_hasDerivAt ((μ - fbest) / σ)).comp μ hg)).add
      (((stdPDF_hasDerivAt ((μ - fbest) / σ)).comp μ hg).const_mul σ)
    refine h.congr_deriv ?_
    simp only [Function.comp_apply]
    field_simp
    ring
  · have h := (((stdCDF_hasDerivAt ((μ - fbest) / σ)).comp σ hgs).const_mul (μ - fbest)).add
      ((hasDerivAt_id' σ).mul ((stdPDF_hasDerivAt ((μ - fbest) / σ)).comp σ hgs))
    refine h.congr_deriv ?_
    simp only [Function.comp_apply]
    field_simp
    ring

/-- Consequence of Step 4 stated as monotonicity: for a fixed best-so-far `f⁺`,
expected improvement strictly increases in the mean `μ` (for each fixed `σ > 0`)
and strictly increases in the spread `σ` on `σ > 0` (for each fixed `μ`). -/
theorem expected_improvement_strictly_increasing (fbest : ℝ) :
    (∀ σ : ℝ, 0 < σ → StrictMono (fun m => expectedImprovement fbest m σ)) ∧
      (∀ μ : ℝ, StrictMonoOn (fun s => expectedImprovement fbest μ s) (Set.Ioi 0)) := by
  refine ⟨fun σ hσ => ?_, fun μ => ?_⟩
  · apply strictMono_of_deriv_pos
    intro m
    rw [(expected_improvement_slopes m fbest σ hσ).1.deriv]
    exact stdCDF_pos _
  · apply strictMonoOn_of_deriv_pos (convex_Ioi 0)
    · intro s hs
      exact (expected_improvement_slopes μ fbest s hs).2.1.continuousAt.continuousWithinAt
    · intro s hs
      rw [interior_Ioi] at hs
      rw [(expected_improvement_slopes μ fbest s hs).2.1.deriv]
      exact stdPDF_pos _

end

-- The card's whole-number facts: a 21-value grid in three settings, and the costs.
example : 21 ^ 3 = 9261 := by norm_num
example : 9261 * 20000 = 185220000 := by norm_num
example : 15 * 20000 = 300000 := by norm_num
example : 40 ^ 3 = 64000 := by norm_num

#print axioms expected_improvement_closed_form
#print axioms expected_improvement_slopes
#print axioms expected_improvement_strictly_increasing
