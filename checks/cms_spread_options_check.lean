-- CMS spread options: when the two rates' standard scores are jointly normal with correlation ρ, the gap R₁₀ − R₂ is normal with average F₁₀ − F₂ and variance (σ₁₀² + σ₂² − 2ρσ₁₀σ₂)T, the call on it has Bachelier's price, and a quoted spread variance gives back exactly one correlation.
import Mathlib.Probability.Distributions.Gaussian.HasGaussianLaw.Basic
import Mathlib.Probability.Moments.Covariance
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral

open MeasureTheory ProbabilityTheory Real

section CmsBachelierHelpers
open Filter Topology Set

theorem cms_bach_pdf_eq (z : ℝ) :
    gaussianPDFReal 0 1 z = (Real.sqrt (2 * Real.pi))⁻¹ * Real.exp (-(1/2) * z ^ 2) := by
  simp only [gaussianPDFReal, NNReal.coe_one, mul_one, sub_zero]
  congr 2
  ring

theorem cms_bach_pdf_neg (z : ℝ) : gaussianPDFReal 0 1 (-z) = gaussianPDFReal 0 1 z := by
  rw [cms_bach_pdf_eq, cms_bach_pdf_eq, neg_sq]

theorem cms_bach_cdf_neg (d : ℝ) :
    cdf (gaussianReal 0 1) (-d) = 1 - cdf (gaussianReal 0 1) d := by
  have hmap : (gaussianReal 0 1).map (fun x : ℝ ↦ -x) = gaussianReal 0 1 := by
    rw [gaussianReal_map_neg, neg_zero]
  rw [cdf_eq_real, cdf_eq_real]
  have h1 : (gaussianReal 0 1).real (Iic (-d)) = (gaussianReal 0 1).real (Ici d) := by
    conv_lhs => rw [← hmap]
    rw [map_measureReal_apply (by fun_prop) measurableSet_Iic]
    congr 1
    ext x; simp
  rw [h1]
  have h2 : (gaussianReal 0 1).real (Ici d) = (gaussianReal 0 1).real (Ioi d) := by
    have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
    rw [measureReal_def, measureReal_def,
      measure_congr (Ioi_ae_eq_Ici (μ := gaussianReal 0 1) (a := d))]
  rw [h2, ← compl_Iic, measureReal_compl measurableSet_Iic, probReal_univ]

theorem cms_bach_integrableOn_mul_pdf (a : ℝ) :
    IntegrableOn (fun z ↦ z * gaussianPDFReal 0 1 z) (Ioi a) := by
  have h := (integrable_mul_exp_neg_mul_sq (b := 1/2) (by norm_num)).const_mul
    (Real.sqrt (2 * Real.pi))⁻¹
  refine (h.congr (ae_of_all _ fun z ↦ ?_)).integrableOn
  simp only [cms_bach_pdf_eq]
  ring

theorem cms_bach_integral_Ioi_pdf (a : ℝ) :
    ∫ z in Ioi a, gaussianPDFReal 0 1 z = cdf (gaussianReal 0 1) (-a) := by
  have h := gaussianReal_apply_eq_integral 0 (v := 1) one_ne_zero (Ioi a)
  have hnn : 0 ≤ ∫ z in Ioi a, gaussianPDFReal 0 1 z :=
    setIntegral_nonneg measurableSet_Ioi fun z _ ↦ gaussianPDFReal_nonneg _ _ _
  have h2 : (gaussianReal 0 1).real (Ioi a) = ∫ z in Ioi a, gaussianPDFReal 0 1 z := by
    rw [measureReal_def, h, ENNReal.toReal_ofReal hnn]
  rw [← h2, ← compl_Iic, measureReal_compl measurableSet_Iic, probReal_univ, ← cdf_eq_real,
    cms_bach_cdf_neg]

theorem cms_bach_integral_Ioi_mul_pdf (a : ℝ) :
    ∫ z in Ioi a, z * gaussianPDFReal 0 1 z = gaussianPDFReal 0 1 a := by
  have hf : (fun z ↦ -gaussianPDFReal 0 1 z) =
      fun z ↦ -((Real.sqrt (2 * Real.pi))⁻¹ * Real.exp (-(1/2) * z ^ 2)) := by
    funext z; rw [cms_bach_pdf_eq]
  have key := integral_Ioi_of_hasDerivAt_of_tendsto (a := a) (m := 0)
    (f := fun z ↦ -gaussianPDFReal 0 1 z) (f' := fun z ↦ z * gaussianPDFReal 0 1 z)
    ?_ ?_ (cms_bach_integrableOn_mul_pdf a) ?_
  · rw [key]; ring
  · rw [hf]; exact (by fun_prop : Continuous _).continuousWithinAt
  · intro z _
    rw [hf, cms_bach_pdf_eq]
    have h1 := (((hasDerivAt_pow 2 z).const_mul (-(1/2 : ℝ))).exp).const_mul
      (Real.sqrt (2 * Real.pi))⁻¹
    convert h1.neg using 1
    push_cast
    ring
  · rw [hf]
    have h0 : Tendsto (fun z : ℝ ↦ -(1/2) * z ^ 2) atTop atBot := by
      apply Tendsto.const_mul_atTop_of_neg (by norm_num)
      exact tendsto_pow_atTop two_ne_zero
    have h1 := (Real.tendsto_exp_atBot.comp h0).const_mul (Real.sqrt (2 * Real.pi))⁻¹
    have h2 := h1.neg
    simpa using h2

theorem cms_bach_call_core (m s : ℝ) (hs : 0 < s) :
    ∫ z, max (m + s * z) 0 ∂(gaussianReal 0 1) =
      m * cdf (gaussianReal 0 1) (m / s) + s * gaussianPDFReal 0 1 (m / s) := by
  rw [integral_gaussianReal_eq_integral_smul one_ne_zero]
  have hind : (fun z ↦ gaussianPDFReal 0 1 z • max (m + s * z) 0) =
      (Ioi (-(m / s))).indicator
        (fun z ↦ m * gaussianPDFReal 0 1 z + s * (z * gaussianPDFReal 0 1 z)) := by
    funext z
    have hms : m + s * z = s * (m / s + z) := by field_simp
    simp only [smul_eq_mul, indicator, mem_Ioi]
    split_ifs with h
    · rw [max_eq_left]
      · ring
      · rw [hms]; exact mul_nonneg hs.le (by linarith)
    · rw [max_eq_right, mul_zero]
      rw [hms]; exact mul_nonpos_of_nonneg_of_nonpos hs.le (by linarith)
  rw [hind, integral_indicator measurableSet_Ioi, integral_add, integral_const_mul,
    integral_const_mul, cms_bach_integral_Ioi_pdf, cms_bach_integral_Ioi_mul_pdf, neg_neg, cms_bach_pdf_neg]
  · exact ((integrable_gaussianPDFReal 0 1).integrableOn).const_mul m
  · exact (cms_bach_integrableOn_mul_pdf _).const_mul s

#print axioms cms_bach_pdf_eq
#print axioms cms_bach_pdf_neg
#print axioms cms_bach_cdf_neg
#print axioms cms_bach_integrableOn_mul_pdf
#print axioms cms_bach_integral_Ioi_pdf
#print axioms cms_bach_integral_Ioi_mul_pdf
#print axioms cms_bach_call_core

end CmsBachelierHelpers

/-- The gap is normal (Step 2 of the card). Write the two CMS rates at the fixing as
`R₁₀ = F₁₀ + σ₁₀ √T X₁` and `R₂ = F₂ + σ₂ √T X₂`, where `X₁`, `X₂` are standard bell-curve
draws that are jointly normal with correlation `ρ`. Then the gap `R₁₀ − R₂` is normal, with
average `F₁₀ − F₂` and variance `(σ₁₀² + σ₂² − 2ρσ₁₀σ₂) T`. -/
theorem cms_spread_gap_normal_with_spread_variance
    {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω} {X₁ X₂ : Ω → ℝ}
    (hjoint : HasGaussianLaw (fun ω ↦ (X₁ ω, X₂ ω)) P)
    (h₁ : HasLaw X₁ (gaussianReal 0 1) P) (h₂ : HasLaw X₂ (gaussianReal 0 1) P)
    {ρ : ℝ} (hρ : covariance X₁ X₂ P = ρ)
    (F₁₀ F₂ σ₁₀ σ₂ T : ℝ) (hT : 0 ≤ T) :
    HasLaw (fun ω ↦ (F₁₀ + σ₁₀ * √T * X₁ ω) - (F₂ + σ₂ * √T * X₂ ω))
      (gaussianReal (F₁₀ - F₂) ((σ₁₀ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁₀ * σ₂) * T).toNNReal) P := by
  have hP : IsProbabilityMeasure P := hjoint.isProbabilityMeasure
  set a := σ₁₀ * √T with ha
  set b := σ₂ * √T with hb
  set Z : Ω → ℝ := fun ω ↦ a * X₁ ω - b * X₂ ω with hZdef
  have hZ : HasGaussianLaw Z P := by
    have := hjoint.map_fun (a • ContinuousLinearMap.fst ℝ ℝ ℝ - b • ContinuousLinearMap.snd ℝ ℝ ℝ)
    simpa [hZdef] using this
  have hm₁ : MemLp X₁ 2 P := hjoint.fst.memLp_two
  have hm₂ : MemLp X₂ 2 P := hjoint.snd.memLp_two
  have hv₁ : Var[X₁; P] = 1 := by rw [h₁.variance_eq, variance_id_gaussianReal]; rfl
  have hv₂ : Var[X₂; P] = 1 := by rw [h₂.variance_eq, variance_id_gaussianReal]; rfl
  have he₁ : P[X₁] = 0 := by rw [h₁.integral_eq, integral_id_gaussianReal]
  have he₂ : P[X₂] = 0 := by rw [h₂.integral_eq, integral_id_gaussianReal]
  have hmean : P[Z] = 0 := by
    simp only [hZdef]
    rw [integral_sub ((hm₁.integrable one_le_two).const_mul a)
      ((hm₂.integrable one_le_two).const_mul b), integral_const_mul, integral_const_mul, he₁, he₂]
    ring
  have hsq : √T ^ 2 = T := sq_sqrt hT
  have hvar : Var[Z; P] = (σ₁₀ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁₀ * σ₂) * T := by
    simp only [hZdef]
    rw [variance_fun_sub (hm₁.const_mul a) (hm₂.const_mul b), variance_const_mul,
      variance_const_mul, covariance_const_mul_left, covariance_const_mul_right, hv₁, hv₂, hρ,
      ha, hb]
    linear_combination (σ₁₀ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁₀ * σ₂) * hsq
  have hmapZ := hZ.map_eq_gaussianReal
  rw [hmean, hvar] at hmapZ
  have hY : (fun ω ↦ (F₁₀ + σ₁₀ * √T * X₁ ω) - (F₂ + σ₂ * √T * X₂ ω))
      = (fun z ↦ (F₁₀ - F₂) + z) ∘ Z := by
    funext ω; simp only [hZdef, Function.comp, ha, hb]; ring
  rw [hY]
  refine ⟨by fun_prop, ?_⟩
  rw [← AEMeasurable.map_map_of_aemeasurable (by fun_prop) hZ.aemeasurable, hmapZ,
    gaussianReal_map_const_add, zero_add]

/-- The CMS spread call is a Bachelier option on the gap (The formula, Step 3). With the same
two rates, a strike `K` and a discount factor `D`, the call that pays `(R₁₀ − R₂ − K)⁺` is worth
`C = D [m N(d) + s φ(d)]`, where `m = F₁₀ − F₂ − K` is the head start,
`s = √((σ₁₀² + σ₂² − 2ρσ₁₀σ₂) T)` is the gap's standard deviation, `d = m / s`, `N` is the
standard normal CDF and `φ` its density. The gap must actually wander (`s > 0`) for `d = m / s`
to make sense. -/
theorem cms_spread_call_eq_bachelier_on_gap
    {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω} {X₁ X₂ : Ω → ℝ}
    (hjoint : HasGaussianLaw (fun ω ↦ (X₁ ω, X₂ ω)) P)
    (h₁ : HasLaw X₁ (gaussianReal 0 1) P) (h₂ : HasLaw X₂ (gaussianReal 0 1) P)
    {ρ : ℝ} (hρ : covariance X₁ X₂ P = ρ)
    (F₁₀ F₂ σ₁₀ σ₂ T K D : ℝ) (hT : 0 ≤ T)
    (hs : 0 < (σ₁₀ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁₀ * σ₂) * T) :
    let m := F₁₀ - F₂ - K
    let s := √((σ₁₀ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁₀ * σ₂) * T)
    D * ∫ ω, max ((F₁₀ + σ₁₀ * √T * X₁ ω) - (F₂ + σ₂ * √T * X₂ ω) - K) 0 ∂P
      = D * (m * cdf (gaussianReal 0 1) (m / s) + s * gaussianPDFReal 0 1 (m / s)) := by
  intro m s
  set S := (σ₁₀ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁₀ * σ₂) * T with hSdef
  have hspos : 0 < s := Real.sqrt_pos.mpr hs
  have hlaw := cms_spread_gap_normal_with_spread_variance hjoint h₁ h₂ hρ F₁₀ F₂ σ₁₀ σ₂ T hT
  have hgauss : gaussianReal (F₁₀ - F₂) S.toNNReal
      = (gaussianReal 0 1).map (fun z ↦ (F₁₀ - F₂) + s * z) := by
    rw [show (fun z ↦ (F₁₀ - F₂) + s * z) = (fun x ↦ (F₁₀ - F₂) + x) ∘ (fun x ↦ s * x) from rfl,
      ← AEMeasurable.map_map_of_aemeasurable (by fun_prop) (by fun_prop),
      gaussianReal_map_const_mul, gaussianReal_map_const_add]
    congr 1
    · ring
    · ext
      simp only [s, NNReal.coe_mk, mul_one,
        Real.coe_toNNReal _ hs.le]
      rw [Real.sq_sqrt hs.le]
  congr 1
  have hcomp := hlaw.integral_comp (f := fun y ↦ max (y - K) 0) (by fun_prop)
  simp only [Function.comp_def] at hcomp
  rw [hcomp, hgauss, integral_map (by fun_prop) (by fun_prop)]
  rw [← cms_bach_call_core m s hspos]
  congr 1
  funext z
  congr 1
  simp only [m]; ring

/-- The implied correlation (Step 5). For nonzero volatilities and a nonzero time to the fixing,
a spread standard deviation `s_q` comes from correlation `ρ` exactly when
`ρ = (σ₁₀² + σ₂² − s_q² / T) / (2 σ₁₀ σ₂)`; so each quoted spread variance has one correlation. -/
theorem cms_spread_implied_correlation
    (σ₁₀ σ₂ T ρ s_q : ℝ) (h₁₀ : σ₁₀ ≠ 0) (h₂ : σ₂ ≠ 0) (hT : T ≠ 0) :
    s_q ^ 2 = (σ₁₀ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁₀ * σ₂) * T ↔
      ρ = (σ₁₀ ^ 2 + σ₂ ^ 2 - s_q ^ 2 / T) / (2 * σ₁₀ * σ₂) := by
  have hd : 2 * σ₁₀ * σ₂ ≠ 0 := by positivity
  rw [eq_div_iff hd]
  constructor
  · intro h
    rw [h]; field_simp; ring
  · intro h
    have : s_q ^ 2 / T = σ₁₀ ^ 2 + σ₂ ^ 2 - ρ * (2 * σ₁₀ * σ₂) := by linarith
    rw [div_eq_iff hT] at this
    rw [this]; ring

/-! The card's worked numbers, in basis points (rates 420 and 380 bp, vols 90 and 100 bp, T = 1). -/

-- head start: 4.20% − 3.80% − 0 = 40 bp
example : (420 : ℤ) - 380 - 0 = 40 := by norm_num

-- gap's variance at ρ = 0.8: 90² + 100² − 2·0.8·90·100 = 3700 bp² (0.37 in (percent)²)
example : (90 : ℚ) ^ 2 + 100 ^ 2 - 2 * (8 / 10) * 90 * 100 = 3700 := by norm_num

-- ρ = 0 (independent rates): 8100 + 10000 = 18100 bp²
example : (90 : ℚ) ^ 2 + 100 ^ 2 - 2 * 0 * 90 * 100 = 18100 := by norm_num

-- ρ = 1 (vols subtracted): the gap's variance is (100 − 90)² = 100 bp²
example : (90 : ℚ) ^ 2 + 100 ^ 2 - 2 * 1 * 90 * 100 = (100 - 90) ^ 2 := by norm_num

-- implied correlation from the Bachelier spread variance 3700 bp² gives back 0.8
example : ((90 : ℚ) ^ 2 + 100 ^ 2 - 3700 / 1) / (2 * 90 * 100) = 8 / 10 := by norm_num

#print axioms cms_spread_gap_normal_with_spread_variance
#print axioms cms_spread_call_eq_bachelier_on_gap
#print axioms cms_spread_implied_correlation
