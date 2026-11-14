-- The one-factor Gaussian copula: blending one shared standard-normal economy factor with private standard-normal noise keeps each firm's default chance exactly N(a) = p for every correlation 0 ≤ ρ < 1, the pair default chance is the one-dimensional average of q(m)², and it is strictly larger than p² whenever 0 < ρ < 1.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Probability.HasLaw
import Mathlib.Probability.Independence.Basic

open MeasureTheory ProbabilityTheory

noncomputable section

/-- Below a cutoff, strict and non-strict give the same standard-normal chance. -/
lemma ofc_gauss_Iio (c : ℝ) :
    gaussianReal 0 1 (Set.Iio c) = ENNReal.ofReal (cdf (gaussianReal 0 1) c) := by
  have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  rw [ofReal_cdf, measure_congr Iio_ae_eq_Iic]

#print axioms ofc_gauss_Iio

/-- The slice of the default region at a fixed economy value is a half-line. -/
lemma ofc_slice {ρ : ℝ} (hρ1 : ρ < 1) (a m : ℝ) :
    {e : ℝ | √ρ * m + √(1 - ρ) * e < a} = Set.Iio ((a - √ρ * m) / √(1 - ρ)) := by
  have hs : 0 < √(1 - ρ) := Real.sqrt_pos.2 (by linarith)
  ext e
  change √ρ * m + √(1 - ρ) * e < a ↔ e < (a - √ρ * m) / √(1 - ρ)
  rw [lt_div_iff₀ hs, mul_comm e]
  constructor <;> intro h <;> linarith

#print axioms ofc_slice

lemma ofc_measurable_q (ρ a : ℝ) :
    Measurable (fun m : ℝ => cdf (gaussianReal 0 1) ((a - √ρ * m) / √(1 - ρ))) :=
  (monotone_cdf _).measurable.comp (by fun_prop)

#print axioms ofc_measurable_q

lemma ofc_prod_lintegral {ρ : ℝ} (hρ1 : ρ < 1) (a : ℝ) :
    ((gaussianReal 0 1).prod (gaussianReal 0 1)) {x : ℝ × ℝ | √ρ * x.1 + √(1 - ρ) * x.2 < a}
      = ∫⁻ m, ENNReal.ofReal (cdf (gaussianReal 0 1) ((a - √ρ * m) / √(1 - ρ)))
          ∂(gaussianReal 0 1) := by
  rw [Measure.prod_apply (measurableSet_lt (by fun_prop) (by fun_prop))]
  refine lintegral_congr (fun m => ?_)
  rw [← ofc_gauss_Iio, ← ofc_slice hρ1 a m]
  rfl

#print axioms ofc_prod_lintegral

lemma ofc_prod3_lintegral {ρ : ℝ} (hρ1 : ρ < 1) (a : ℝ) :
    ((gaussianReal 0 1).prod ((gaussianReal 0 1).prod (gaussianReal 0 1)))
      {x : ℝ × ℝ × ℝ | √ρ * x.1 + √(1 - ρ) * x.2.1 < a ∧ √ρ * x.1 + √(1 - ρ) * x.2.2 < a}
      = ∫⁻ m, ENNReal.ofReal ((cdf (gaussianReal 0 1) ((a - √ρ * m) / √(1 - ρ))) ^ 2)
          ∂(gaussianReal 0 1) := by
  have hS : MeasurableSet
      {x : ℝ × ℝ × ℝ | √ρ * x.1 + √(1 - ρ) * x.2.1 < a ∧ √ρ * x.1 + √(1 - ρ) * x.2.2 < a} :=
    (measurableSet_lt (f := fun x : ℝ × ℝ × ℝ => √ρ * x.1 + √(1 - ρ) * x.2.1)
      (g := fun _ => a) (by fun_prop) measurable_const).inter
      (measurableSet_lt (f := fun x : ℝ × ℝ × ℝ => √ρ * x.1 + √(1 - ρ) * x.2.2)
        (g := fun _ => a) (by fun_prop) measurable_const)
  rw [Measure.prod_apply hS]
  refine lintegral_congr (fun m => ?_)
  have hset : Prod.mk m ⁻¹'
      {x : ℝ × ℝ × ℝ | √ρ * x.1 + √(1 - ρ) * x.2.1 < a ∧ √ρ * x.1 + √(1 - ρ) * x.2.2 < a}
      = {e : ℝ | √ρ * m + √(1 - ρ) * e < a} ×ˢ {e : ℝ | √ρ * m + √(1 - ρ) * e < a} := by
    ext x; simp
  rw [hset, Measure.prod_prod, ofc_slice hρ1, ofc_gauss_Iio,
    ← ENNReal.ofReal_mul (cdf_nonneg _ _), sq]

#print axioms ofc_prod3_lintegral

/-- Each firm keeps its own default chance exactly. Let the economy score `M` and the firm's
private noise `ε` be independent standard bell-curve draws, let the asset correlation satisfy
`0 ≤ ρ < 1`, and let the cutoff `a` be the point with bell-curve area `p` to its left
(`N(a) = p`). Then the latent score `X = √ρ M + √(1-ρ) ε` falls below `a` with chance exactly
`p`, and averaging the conditional default chance
`q(m) = N((a - √ρ m) / √(1-ρ))` over the economy also gives exactly `p`. -/
theorem one_factor_default_chance_exact
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (M ε : Ω → ℝ) (hM : HasLaw M (gaussianReal 0 1) P) (hε : HasLaw ε (gaussianReal 0 1) P)
    (hind : IndepFun M ε P) {ρ : ℝ} (hρ0 : 0 ≤ ρ) (hρ1 : ρ < 1) {p a : ℝ}
    (ha : cdf (gaussianReal 0 1) a = p) :
    P.real {ω | √ρ * M ω + √(1 - ρ) * ε ω < a} = p ∧
      ∫ m, cdf (gaussianReal 0 1) ((a - √ρ * m) / √(1 - ρ)) ∂(gaussianReal 0 1) = p := by
  have hs1 : (0 : ℝ) ≤ 1 - ρ := by linarith
  have hP : HasLaw (fun ω => (M ω, ε ω)) ((gaussianReal 0 1).prod (gaussianReal 0 1)) P :=
    hind.hasLaw_prod hM hε
  have hS : MeasurableSet {x : ℝ × ℝ | √ρ * x.1 + √(1 - ρ) * x.2 < a} :=
    measurableSet_lt (by fun_prop) (by fun_prop)
  have e1 : P.real {ω | √ρ * M ω + √(1 - ρ) * ε ω < a} =
      ((gaussianReal 0 1).prod (gaussianReal 0 1)).real
        {x : ℝ × ℝ | √ρ * x.1 + √(1 - ρ) * x.2 < a} :=
    hP.measureReal_eq (p := fun x : ℝ × ℝ => √ρ * x.1 + √(1 - ρ) * x.2 < a) hS
  have e2 : ∫ m, cdf (gaussianReal 0 1) ((a - √ρ * m) / √(1 - ρ)) ∂(gaussianReal 0 1) =
      ((gaussianReal 0 1).prod (gaussianReal 0 1)).real
        {x : ℝ × ℝ | √ρ * x.1 + √(1 - ρ) * x.2 < a} := by
    rw [measureReal_def, ofc_prod_lintegral hρ1,
      integral_eq_lintegral_of_nonneg_ae (ae_of_all _ fun _ => cdf_nonneg _ _)
        (ofc_measurable_q ρ a).aestronglyMeasurable]
  have hX := gaussianReal_const_mul hM (√ρ)
  have hY := gaussianReal_const_mul hε (√(1 - ρ))
  have hind' : IndepFun (fun ω => √ρ * M ω) (fun ω => √(1 - ρ) * ε ω) P :=
    hind.comp (measurable_const_mul _) (measurable_const_mul _)
  have hmap := gaussianReal_add_gaussianReal_of_indepFun hind' hX hY
  have hvar : gaussianReal (√ρ * 0 + √(1 - ρ) * 0)
      (⟨√ρ ^ 2, sq_nonneg _⟩ * 1 + ⟨√(1 - ρ) ^ 2, sq_nonneg _⟩ * 1) = gaussianReal 0 1 := by
    congr 1
    · simp
    · ext
      change √ρ ^ 2 * 1 + √(1 - ρ) ^ 2 * 1 = (1 : ℝ)
      rw [Real.sq_sqrt hρ0, Real.sq_sqrt hs1]
      ring
  have hlaw : HasLaw (fun ω => √ρ * M ω + √(1 - ρ) * ε ω) (gaussianReal 0 1) P :=
    ⟨by fun_prop, by rw [← hvar]; exact hmap⟩
  have e3 : P.real {ω | √ρ * M ω + √(1 - ρ) * ε ω < a} = p := by
    rw [hlaw.measureReal_eq (p := fun x : ℝ => x < a) (measurableSet_lt (by fun_prop) (by fun_prop))]
    rw [← ha, measureReal_def]
    change (gaussianReal 0 1 (Set.Iio a)).toReal = _
    rw [ofc_gauss_Iio, ENNReal.toReal_ofReal (cdf_nonneg _ _)]
  exact ⟨e3, by rw [e2, ← e1, e3]⟩

/-- Every joint question becomes a one-dimensional average over the economy. With one economy
score `M` and two private noises `ε₁`, `ε₂`, all three independent standard bell-curve draws,
and `0 ≤ ρ < 1`, the chance that both firms' latent scores fall below the cutoff `a` equals
`J = ∫ φ(m) q(m)² dm`, the square of the conditional default chance averaged over the economy. -/
theorem pair_default_eq_factor_integral
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (M ε₁ ε₂ : Ω → ℝ) (hM : HasLaw M (gaussianReal 0 1) P)
    (h₁ : HasLaw ε₁ (gaussianReal 0 1) P) (h₂ : HasLaw ε₂ (gaussianReal 0 1) P)
    (hind : iIndepFun ![M, ε₁, ε₂] P) {ρ : ℝ} (hρ0 : 0 ≤ ρ) (hρ1 : ρ < 1) (a : ℝ) :
    P.real {ω | √ρ * M ω + √(1 - ρ) * ε₁ ω < a ∧ √ρ * M ω + √(1 - ρ) * ε₂ ω < a} =
      ∫ m, (cdf (gaussianReal 0 1) ((a - √ρ * m) / √(1 - ρ))) ^ 2 ∂(gaussianReal 0 1) := by
  have hmeas : ∀ i, AEMeasurable (![M, ε₁, ε₂] i) P := by
    intro i
    fin_cases i
    · exact hM.aemeasurable
    · exact h₁.aemeasurable
    · exact h₂.aemeasurable
  have i12 : IndepFun ε₁ ε₂ P := by
    simpa using hind.indepFun (i := 1) (j := 2) (by decide)
  have i0 : IndepFun (fun ω => (ε₁ ω, ε₂ ω)) M P := by
    simpa using hind.indepFun_prodMk₀ hmeas 1 2 0 (by decide) (by decide)
  have hL12 := i12.hasLaw_prod h₁ h₂
  have hL := i0.symm.hasLaw_prod hM hL12
  have hS : MeasurableSet
      {x : ℝ × ℝ × ℝ | √ρ * x.1 + √(1 - ρ) * x.2.1 < a ∧ √ρ * x.1 + √(1 - ρ) * x.2.2 < a} :=
    (measurableSet_lt (f := fun x : ℝ × ℝ × ℝ => √ρ * x.1 + √(1 - ρ) * x.2.1)
      (g := fun _ => a) (by fun_prop) measurable_const).inter
      (measurableSet_lt (f := fun x : ℝ × ℝ × ℝ => √ρ * x.1 + √(1 - ρ) * x.2.2)
        (g := fun _ => a) (by fun_prop) measurable_const)
  rw [hL.measureReal_eq (p := fun x : ℝ × ℝ × ℝ =>
      √ρ * x.1 + √(1 - ρ) * x.2.1 < a ∧ √ρ * x.1 + √(1 - ρ) * x.2.2 < a) hS,
    measureReal_def, ofc_prod3_lintegral hρ1,
    integral_eq_lintegral_of_nonneg_ae (ae_of_all _ fun _ => sq_nonneg _)
      ((ofc_measurable_q ρ a).pow_const 2).aestronglyMeasurable]

/-- Positive asset correlation always means positive default correlation: for every
correlation `0 < ρ < 1` and every cutoff `a`, the pair default chance
`J = ∫ φ(m) q(m)² dm` is strictly larger than `p² = N(a)²`, the pair chance for unconnected
firms. -/
theorem pair_default_gt_independent {ρ : ℝ} (hρ0 : 0 < ρ) (hρ1 : ρ < 1) (a : ℝ) :
    (cdf (gaussianReal 0 1) a) ^ 2 <
      ∫ m, (cdf (gaussianReal 0 1) ((a - √ρ * m) / √(1 - ρ))) ^ 2 ∂(gaussianReal 0 1) := by
  set q : ℝ → ℝ := fun m => cdf (gaussianReal 0 1) ((a - √ρ * m) / √(1 - ρ)) with hq
  set p : ℝ := cdf (gaussianReal 0 1) a with hp
  have hqm : Measurable q := ofc_measurable_q ρ a
  have hqi : Integrable q (gaussianReal 0 1) :=
    Integrable.of_bound hqm.aestronglyMeasurable 1 (ae_of_all _ fun m => by
      rw [Real.norm_eq_abs, abs_of_nonneg (cdf_nonneg _ _)]; exact cdf_le_one _ _)
  have hq2i : Integrable (fun m => q m ^ 2) (gaussianReal 0 1) :=
    Integrable.of_bound (hqm.pow_const 2).aestronglyMeasurable 1 (ae_of_all _ fun m => by
      have h0 : 0 ≤ q m := cdf_nonneg _ _
      have h1 : q m ≤ 1 := cdf_le_one _ _
      rw [Real.norm_eq_abs, abs_of_nonneg (sq_nonneg _)]; nlinarith)
  have hmean : ∫ m, q m ∂(gaussianReal 0 1) = p := by
    have hfst : HasLaw (fun x : ℝ × ℝ => x.1) (gaussianReal 0 1)
        ((gaussianReal 0 1).prod (gaussianReal 0 1)) :=
      (measurePreserving_fst).hasLaw
    have hsnd : HasLaw (fun x : ℝ × ℝ => x.2) (gaussianReal 0 1)
        ((gaussianReal 0 1).prod (gaussianReal 0 1)) :=
      (measurePreserving_snd).hasLaw
    have hind : IndepFun (fun x : ℝ × ℝ => x.1) (fun x : ℝ × ℝ => x.2)
        ((gaussianReal 0 1).prod (gaussianReal 0 1)) :=
      indepFun_prod (X := id) (Y := id) measurable_id measurable_id
    exact (one_factor_default_chance_exact _ _ hfst hsnd hind hρ0.le hρ1 rfl).2
  -- strict monotonicity of the standard normal distribution function
  have hcdf : StrictMono (cdf (gaussianReal 0 1)) := by
    intro x y hxy
    refine lt_of_le_of_ne (monotone_cdf _ hxy.le) fun heq => ?_
    have h1 : gaussianReal 0 1 (Set.Iic y) = gaussianReal 0 1 (Set.Iic x) := by
      rw [← ofReal_cdf, ← ofReal_cdf, heq]
    have h2 : gaussianReal 0 1 (Set.Ioc x y) = 0 := by
      have hd : Set.Ioc x y = Set.Iic y \ Set.Iic x := by ext t; simp [and_comm]
      rw [hd, measure_sdiff (Set.Iic_subset_Iic.2 hxy.le)
        measurableSet_Iic.nullMeasurableSet (measure_ne_top _ _), h1, tsub_self]
    have h3 := gaussianReal_absolutelyContinuous' (0 : ℝ) (v := 1) one_ne_zero h2
    rw [Real.volume_Ioc] at h3
    have : 0 < y - x := by linarith
    simp [ENNReal.ofReal_eq_zero] at h3
    linarith
  have hs : 0 < √(1 - ρ) := Real.sqrt_pos.2 (by linarith)
  have hr : 0 < √ρ := Real.sqrt_pos.2 hρ0
  have hanti : StrictAnti q := by
    intro x y hxy
    apply hcdf
    apply div_lt_div_of_pos_right _ hs
    nlinarith
  have hzero : gaussianReal 0 1 {m | q m = p} = 0 := by
    have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
    refine Set.Subsingleton.measure_zero ?_ _
    intro x hx y hy
    exact hanti.injective (hx.trans hy.symm)
  have hpos : 0 < ∫ m, (q m - p) ^ 2 ∂(gaussianReal 0 1) := by
    have hp0 : 0 ≤ p := cdf_nonneg _ _
    have hp1 : p ≤ 1 := cdf_le_one _ _
    have hdi : Integrable (fun m => (q m - p) ^ 2) (gaussianReal 0 1) :=
      Integrable.of_bound ((hqm.sub measurable_const).pow_const 2).aestronglyMeasurable 1
        (ae_of_all _ fun m => by
          have h0 : 0 ≤ q m := cdf_nonneg _ _
          have h1 : q m ≤ 1 := cdf_le_one _ _
          rw [Real.norm_eq_abs, abs_of_nonneg (sq_nonneg _)]; nlinarith)
    rw [integral_pos_iff_support_of_nonneg (fun m => sq_nonneg (q m - p)) hdi]
    have hsupp : Function.support (fun m => (q m - p) ^ 2) = {m | q m = p}ᶜ := by
      ext m; simp [sub_eq_zero]
    rw [hsupp, (prob_compl_eq_one_iff (measurableSet_eq_fun hqm measurable_const)).2 hzero]
    exact one_pos
  have hexp : ∫ m, (q m - p) ^ 2 ∂(gaussianReal 0 1) =
      ∫ m, q m ^ 2 ∂(gaussianReal 0 1) - p ^ 2 := by
    have : (fun m => (q m - p) ^ 2) = fun m => (q m ^ 2 - (2 * p) * q m) + p ^ 2 := by
      funext m; ring
    have i1 : Integrable (fun m => q m ^ 2 - 2 * p * q m) (gaussianReal 0 1) :=
      hq2i.sub (hqi.const_mul _)
    have i2 : Integrable (fun m => 2 * p * q m) (gaussianReal 0 1) := hqi.const_mul _
    rw [this, integral_add i1 (integrable_const _),
      integral_sub hq2i (hqi.const_mul _), integral_const_mul, hmean, integral_const]
    simp
    ring
  linarith

end

-- Pool expected loss: 5% default chance times 60% loss given default is 3%.
example : (5 / 100 : ℚ) * (60 / 100) = 3 / 100 := by norm_num
-- Ten defaults of 100 equal loans at 60% loss cost 6% of the pool, twice the expected 3%.
example : (10 : ℚ) * (60 / 100) / 100 = 6 / 100 ∧ (6 / 100 : ℚ) = 2 * (3 / 100) := by norm_num
-- Unconnected pair: 0.05 × 0.05 = 0.25%.
example : (5 / 100 : ℚ) * (5 / 100) = 25 / 10000 := by norm_num
-- The blend's variance at ρ = 20%: ρ + (1 - ρ) = 1.
example : (20 / 100 : ℚ) + (1 - 20 / 100) = 1 := by norm_num
-- What breaks: weighting the economy by ρ instead of √ρ gives variance 0.04 + 0.8 = 0.84.
example : (20 / 100 : ℚ) ^ 2 + (1 - 20 / 100) = 84 / 100 := by norm_num
-- What breaks: dropping √(1 - ρ) gives variance 0.2 + 1 = 1.2.
example : (20 / 100 : ℚ) + 1 = 12 / 10 := by norm_num

#print axioms one_factor_default_chance_exact
#print axioms pair_default_eq_factor_integral
#print axioms pair_default_gt_independent
