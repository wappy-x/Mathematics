-- Stress tests: if a month's spot and volatility moves are jointly normal with mean zero, typical sizes m_s and m_v and correlation ρ, then the chance that the book loses at least a given limit is at most e^(-d*²/2), where d* is the smallest distance d among the scenarios that reach the limit; along the way, d is plain distance in independent standard coordinates and two independent standard draws land beyond radius a with chance exactly e^(-a²/2).
import Mathlib.Probability.Distributions.Gaussian.HasGaussianLaw.Independence
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.HasLaw
import Mathlib.Probability.Moments.Covariance
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Independence.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.PolarCoord
import Mathlib.MeasureTheory.Integral.IntegralEqImproper

open Real MeasureTheory ProbabilityTheory

/-- The reverse test's distance `d(s, v)`, counted in typical months (The formula): scale the
spot move `s` by its typical monthly size `m_s` and the volatility move `v` by `m_v`, then
`d² = (z_s² - 2ρ z_s z_v + z_v²) / (1 - ρ²)` with `z_s = s / m_s` and `z_v = v / m_v`. -/
noncomputable def scenarioDist (ms mv ρ s v : ℝ) : ℝ :=
  √(((s / ms) ^ 2 - 2 * ρ * (s / ms) * (v / mv) + (v / mv) ^ 2) / (1 - ρ ^ 2))

/-- `d_*`: the smallest distance `d(s, v)` among the scenarios whose change in the book's value
`L(s, v)` is at or below the loss limit `ℓ` (for the card, `ℓ = -$3 million`). -/
noncomputable def reverseStressDist (ms mv ρ : ℝ) (L : ℝ → ℝ → ℝ) (ℓ : ℝ) : ℝ :=
  sInf ((fun p : ℝ × ℝ => scenarioDist ms mv ρ p.1 p.2) '' {p | L p.1 p.2 ≤ ℓ})

/-- Helper: same statement as `scenario_dist_sq_eq_plain_dist_sq`, placed early for reuse. -/
lemma scenarioDist_sq_aux
    (ms mv ρ x y : ℝ) (hms : 0 < ms) (hmv : 0 < mv) (hρ₁ : -1 < ρ) (hρ₂ : ρ < 1) :
    scenarioDist ms mv ρ (ms * x) (mv * (ρ * x + √(1 - ρ ^ 2) * y)) ^ 2 = x ^ 2 + y ^ 2 := by
  have h1 : 0 < 1 - ρ ^ 2 := by nlinarith
  have hc : √(1 - ρ ^ 2) ^ 2 = 1 - ρ ^ 2 := Real.sq_sqrt h1.le
  have key : ((ms * x / ms) ^ 2 - 2 * ρ * (ms * x / ms) * (mv * (ρ * x + √(1 - ρ ^ 2) * y) / mv)
      + (mv * (ρ * x + √(1 - ρ ^ 2) * y) / mv) ^ 2) / (1 - ρ ^ 2) = x ^ 2 + y ^ 2 := by
    rw [mul_div_cancel_left₀ _ hms.ne', mul_div_cancel_left₀ _ hmv.ne', div_eq_iff h1.ne']
    linear_combination (y ^ 2) * hc
  unfold scenarioDist
  rw [key, Real.sq_sqrt (by positivity)]

#print axioms scenarioDist_sq_aux

/-- Helper: `∫_a^∞ r e^(-r²/2) dr = e^(-a²/2)`, as a lower integral. -/
lemma radial_tail (a : ℝ) (ha : 0 ≤ a) :
    ∫⁻ r in Set.Ioi a, ENNReal.ofReal (r * exp (-r ^ 2 / 2)) = ENNReal.ofReal (exp (-a ^ 2 / 2)) := by
  have hderiv : ∀ x ∈ Set.Ici a,
      HasDerivAt (fun r => -exp (-r ^ 2 / 2)) (x * exp (-x ^ 2 / 2)) x := by
    intro x _
    have := (((hasDerivAt_pow 2 x).neg).div_const 2).exp.neg
    convert this using 1
    simp; ring
  have hnn : ∀ x ∈ Set.Ioi a, 0 ≤ x * exp (-x ^ 2 / 2) :=
    fun x hx => mul_nonneg (ha.trans (le_of_lt hx)) (exp_pos _).le
  have hlim : Filter.Tendsto (fun r : ℝ => -exp (-r ^ 2 / 2)) Filter.atTop (nhds 0) := by
    have h1 : Filter.Tendsto (fun r : ℝ => -r ^ 2 / 2) Filter.atTop Filter.atBot := by
      have := (Filter.tendsto_pow_atTop (two_ne_zero)).atTop_div_const (by norm_num : (0:ℝ) < 2)
      refine (Filter.tendsto_neg_atTop_atBot.comp this).congr fun r => ?_
      simp [Function.comp, neg_div]
    simpa using (tendsto_exp_atBot.comp h1).neg
  have hint := integrableOn_Ioi_deriv_of_nonneg' hderiv hnn hlim
  have hval := integral_Ioi_of_hasDerivAt_of_nonneg' hderiv hnn hlim
  rw [← ofReal_integral_eq_lintegral_ofReal hint
    ((ae_restrict_iff' measurableSet_Ioi).2 (Filter.Eventually.of_forall hnn)), hval]
  simp

#print axioms radial_tail

/-- Helper: same statement as `standard_gaussian_radius_tail`, placed early for reuse. -/
lemma gaussian_radius_tail_aux
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {X Y : Ω → ℝ}
    (hX : HasLaw X (gaussianReal 0 1) P) (hY : HasLaw Y (gaussianReal 0 1) P)
    (hXY : IndepFun X Y P) (a : ℝ) (ha : 0 < a) :
    P {ω | a < √(X ω ^ 2 + Y ω ^ 2)} = ENNReal.ofReal (exp (-a ^ 2 / 2)) := by
  have hP : IsProbabilityMeasure P := hX.hasGaussianLaw.isProbabilityMeasure
  have hmap : P.map (fun ω => (X ω, Y ω)) = (gaussianReal 0 1).prod (gaussianReal 0 1) := by
    rw [(indepFun_iff_map_prod_eq_prod_map_map hX.aemeasurable hY.aemeasurable).1 hXY,
      hX.map_eq, hY.map_eq]
  set S : Set (ℝ × ℝ) := {p | a < √(p.1 ^ 2 + p.2 ^ 2)} with hSdef
  have hS : MeasurableSet S := measurableSet_lt measurable_const (by fun_prop)
  have h1 : P {ω | a < √(X ω ^ 2 + Y ω ^ 2)} = P.map (fun ω => (X ω, Y ω)) S := by
    rw [Measure.map_apply_of_aemeasurable (hX.aemeasurable.prodMk hY.aemeasurable) hS]; rfl
  rw [h1, hmap, gaussianReal_of_var_ne_zero _ one_ne_zero,
    prod_withDensity (measurable_gaussianPDF _ _) (measurable_gaussianPDF _ _),
    ← Measure.volume_eq_prod, withDensity_apply _ hS, ← lintegral_indicator hS,
    ← lintegral_comp_polarCoord_symm]
  have hpt : ∀ p ∈ polarCoord.target, ENNReal.ofReal p.1 •
      S.indicator (fun z : ℝ × ℝ => gaussianPDF 0 1 z.1 * gaussianPDF 0 1 z.2) (polarCoord.symm p)
      = ENNReal.ofReal (2 * π)⁻¹ *
        (Set.Ioi a).indicator (fun r => ENNReal.ofReal (r * exp (-r ^ 2 / 2))) p.1 := by
    rintro ⟨r, θ⟩ ⟨hr, -⟩
    simp only [Set.mem_Ioi] at hr
    have hsq : (r * cos θ) ^ 2 + (r * sin θ) ^ 2 = r ^ 2 := by
      linear_combination r ^ 2 * sin_sq_add_cos_sq θ
    simp only [polarCoord_symm_apply, Set.indicator, S, Set.mem_ofPred_eq, Set.mem_Ioi, hsq,
      Real.sqrt_sq hr.le]
    split_ifs with h
    · simp only [smul_eq_mul, gaussianPDF, gaussianPDFReal, NNReal.coe_one, mul_one, sub_zero]
      rw [← ENNReal.ofReal_mul (by positivity), ← ENNReal.ofReal_mul hr.le,
        ← ENNReal.ofReal_mul (by positivity)]
      congr 1
      have e : exp (-(r * cos θ) ^ 2 / 2) * exp (-(r * sin θ) ^ 2 / 2) = exp (-r ^ 2 / 2) := by
        rw [← exp_add]; congr 1; linear_combination (-1/2 : ℝ) * hsq
      have s2 : (√(2 * π))⁻¹ * (√(2 * π))⁻¹ = (2 * π)⁻¹ := by
        rw [← mul_inv, mul_self_sqrt (by positivity)]
      linear_combination r * exp (-(r * cos θ) ^ 2 / 2) * exp (-(r * sin θ) ^ 2 / 2) * s2
        + r * (2 * π)⁻¹ * e
    · simp
  rw [setLIntegral_congr_fun polarCoord.open_target.measurableSet hpt]
  rw [polarCoord_target, Measure.volume_eq_prod, ← Measure.prod_restrict,
    lintegral_prod _ (by fun_prop (disch := exact measurableSet_Ioi))]
  simp only [lintegral_const, Measure.restrict_apply MeasurableSet.univ, Set.univ_inter,
    Real.volume_Ioo]
  rw [lintegral_mul_const _ (by fun_prop (disch := exact measurableSet_Ioi)), lintegral_const_mul _ (by fun_prop (disch := exact measurableSet_Ioi)),
    lintegral_indicator measurableSet_Ioi, Measure.restrict_restrict measurableSet_Ioi,
    Set.Ioi_inter_Ioi, max_eq_left ha.le, radial_tail a ha.le,
    ← ENNReal.ofReal_mul (by positivity), ← ENNReal.ofReal_mul (by positivity)]
  congr 1
  field_simp
  ring

#print axioms gaussian_radius_tail_aux

/-- **The reverse test's chance bound** (The formula; Why it works, Step 6 and the detailed proof).
Let a month's spot move `s` and volatility move `v` be jointly normal (bell-shaped) with mean
zero, typical sizes `m_s > 0` and `m_v > 0` (their standard deviations) and correlation `ρ`
strictly between `-1` and `1`. Let `L(s, v)` be the change in the book's value in scenario
`(s, v)`, any rule at all, and `ℓ` the loss limit. If `d_*` is the smallest distance `d` among the
scenarios with `L(s, v) ≤ ℓ`, then the chance of a month with `L(s, v) ≤ ℓ` is at most
`e^(-d_*²/2)`. -/
theorem reverse_stress_chance_bound
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {s v : Ω → ℝ}
    (ms mv ρ : ℝ) (hms : 0 < ms) (hmv : 0 < mv) (hρ₁ : -1 < ρ) (hρ₂ : ρ < 1)
    (hjoint : HasGaussianLaw (fun ω => (s ω, v ω)) P)
    (hs_mean : ∫ ω, s ω ∂P = 0) (hv_mean : ∫ ω, v ω ∂P = 0)
    (hs_var : variance s P = ms ^ 2) (hv_var : variance v P = mv ^ 2)
    (hcov : covariance s v P = ρ * ms * mv)
    (L : ℝ → ℝ → ℝ) (ℓ : ℝ) :
    P {ω | L (s ω) (v ω) ≤ ℓ} ≤
      ENNReal.ofReal (exp (-(reverseStressDist ms mv ρ L ℓ) ^ 2 / 2)) := by
  have hP : IsProbabilityMeasure P := hjoint.isProbabilityMeasure
  have hsL : MemLp s 2 P := hjoint.fst.memLp_two
  have hvL : MemLp v 2 P := hjoint.snd.memLp_two
  have h1ρ : 0 < 1 - ρ ^ 2 := by nlinarith
  set c := √(1 - ρ ^ 2) with hc_def
  have hc : 0 < c := Real.sqrt_pos.2 h1ρ
  have hc2 : c ^ 2 = 1 - ρ ^ 2 := Real.sq_sqrt h1ρ.le
  set D := reverseStressDist ms mv ρ L ℓ with hD_def
  have hbdd : BddBelow ((fun p : ℝ × ℝ => scenarioDist ms mv ρ p.1 p.2) '' {p | L p.1 p.2 ≤ ℓ}) :=
    ⟨0, by rintro _ ⟨p, -, rfl⟩; exact Real.sqrt_nonneg _⟩
  have hD0 : 0 ≤ D := Real.sInf_nonneg (by rintro _ ⟨p, -, rfl⟩; exact Real.sqrt_nonneg _)
  rcases hD0.eq_or_lt with hD | hD
  · rw [← hD]; simpa using prob_le_one
  let X : Ω → ℝ := fun ω => ms⁻¹ * s ω
  let Y : Ω → ℝ := fun ω => (mv * c)⁻¹ * v ω - (ρ / (ms * c)) * s ω
  have hXYg : HasGaussianLaw (fun ω => (X ω, Y ω)) P := by
    let T : ℝ × ℝ →L[ℝ] ℝ × ℝ :=
      (ms⁻¹ • ContinuousLinearMap.fst ℝ ℝ ℝ).prod
        ((mv * c)⁻¹ • ContinuousLinearMap.snd ℝ ℝ ℝ - (ρ / (ms * c)) • ContinuousLinearMap.fst ℝ ℝ ℝ)
    have hT : (fun ω => (X ω, Y ω)) = fun ω => T (s ω, v ω) := by
      funext ω; simp [T, X, Y]
    rw [hT]; exact hjoint.map_fun T
  have hXL : MemLp X 2 P := hsL.const_mul _
  have hYL : MemLp Y 2 P := (hvL.const_mul _).sub (hsL.const_mul _)
  have hXmean : ∫ ω, X ω ∂P = 0 := by simp [X, integral_const_mul, hs_mean]
  have hYmean : ∫ ω, Y ω ∂P = 0 := by
    simp only [Y]
    rw [integral_sub ((hvL.const_mul _).integrable one_le_two)
      ((hsL.const_mul _).integrable one_le_two), integral_const_mul, integral_const_mul,
      hs_mean, hv_mean]
    simp
  have hXvar : variance X P = 1 := by
    rw [← covariance_self hXL.aemeasurable]
    simp only [X]
    rw [covariance_const_mul_left, covariance_const_mul_right,
      covariance_self hsL.aemeasurable, hs_var]
    field_simp
  have hcovXY : covariance X Y P = 0 := by
    simp only [X, Y]
    rw [covariance_const_mul_left, covariance_fun_sub_right hsL (hvL.const_mul _) (hsL.const_mul _),
      covariance_const_mul_right, covariance_const_mul_right, hcov,
      covariance_self hsL.aemeasurable, hs_var]
    field_simp
    ring
  have hYvar : variance Y P = 1 := by
    rw [← covariance_self hYL.aemeasurable]
    simp only [Y]
    rw [covariance_fun_sub_left (hvL.const_mul _) (hsL.const_mul _) hYL]
    simp only [Y]
    rw [covariance_fun_sub_right (hvL.const_mul _) (hvL.const_mul _) (hsL.const_mul _),
      covariance_fun_sub_right (hsL.const_mul _) (hvL.const_mul _) (hsL.const_mul _),
      covariance_const_mul_left, covariance_const_mul_left, covariance_const_mul_left,
      covariance_const_mul_left, covariance_const_mul_right, covariance_const_mul_right,
      covariance_const_mul_right, covariance_const_mul_right,
      covariance_self hsL.aemeasurable, covariance_self hvL.aemeasurable, covariance_comm v s,
      hcov, hs_var, hv_var]
    field_simp
    linear_combination (-1 : ℝ) * hc2
  have hXlaw : HasLaw X (gaussianReal 0 1) P :=
    ⟨hXYg.fst.aemeasurable, by rw [hXYg.fst.map_eq_gaussianReal, hXmean, hXvar]; simp⟩
  have hYlaw : HasLaw Y (gaussianReal 0 1) P :=
    ⟨hXYg.snd.aemeasurable, by rw [hXYg.snd.map_eq_gaussianReal, hYmean, hYvar]; simp⟩
  have hind : IndepFun X Y P := hXYg.indepFun_of_covariance_eq_zero hcovXY
  have hdist : ∀ ω, scenarioDist ms mv ρ (s ω) (v ω) = √(X ω ^ 2 + Y ω ^ 2) := by
    intro ω
    have h := scenarioDist_sq_aux ms mv ρ (X ω) (Y ω) hms hmv hρ₁ hρ₂
    have e1 : ms * X ω = s ω := by simp only [X]; field_simp
    have e2 : mv * (ρ * X ω + √(1 - ρ ^ 2) * Y ω) = v ω := by
      simp only [X, Y, ← hc_def]; field_simp; ring
    rw [e1, e2] at h
    rw [← h]; exact (Real.sqrt_sq (Real.sqrt_nonneg _)).symm
  have hbound : ∀ a, 0 < a → a < D → P {ω | L (s ω) (v ω) ≤ ℓ} ≤ ENNReal.ofReal (exp (-a ^ 2 / 2)) := by
    intro a ha haD
    calc P {ω | L (s ω) (v ω) ≤ ℓ} ≤ P {ω | a < √(X ω ^ 2 + Y ω ^ 2)} := by
          refine measure_mono fun ω hω => ?_
          have : D ≤ scenarioDist ms mv ρ (s ω) (v ω) := csInf_le hbdd ⟨(s ω, v ω), hω, rfl⟩
          show a < √(X ω ^ 2 + Y ω ^ 2)
          rw [← hdist]; linarith
      _ = ENNReal.ofReal (exp (-a ^ 2 / 2)) := gaussian_radius_tail_aux hXlaw hYlaw hind a ha
  have hcont : Filter.Tendsto (fun a : ℝ => ENNReal.ofReal (exp (-a ^ 2 / 2)))
      (nhdsWithin D (Set.Ioo 0 D)) (nhds (ENNReal.ofReal (exp (-D ^ 2 / 2)))) :=
    ((ENNReal.continuous_ofReal.comp (by fun_prop : Continuous fun a : ℝ => exp (-a ^ 2 / 2))).tendsto
      D).mono_left nhdsWithin_le_nhds
  have : (nhdsWithin D (Set.Ioo 0 D)).NeBot :=
    mem_closure_iff_nhdsWithin_neBot.1 (by rw [closure_Ioo hD.ne]; exact ⟨hD.le, le_rfl⟩)
  exact ge_of_tendsto hcont (eventually_nhdsWithin_of_forall fun a ha => hbound a ha.1 ha.2)

/-- **In the right coordinates, `d` is plain distance** (Why it works, detailed proof). Write the
standardised moves as `z_s = x` and `z_v = ρ x + √(1 - ρ²) y`, so the spot move is `m_s x` and the
volatility move is `m_v (ρ x + √(1 - ρ²) y)`. For typical sizes `m_s > 0`, `m_v > 0` and a
correlation strictly between `-1` and `1`, the distance of that scenario satisfies
`d² = x² + y²`. -/
theorem scenario_dist_sq_eq_plain_dist_sq
    (ms mv ρ x y : ℝ) (hms : 0 < ms) (hmv : 0 < mv) (hρ₁ : -1 < ρ) (hρ₂ : ρ < 1) :
    scenarioDist ms mv ρ (ms * x) (mv * (ρ * x + √(1 - ρ ^ 2) * y)) ^ 2 = x ^ 2 + y ^ 2 := by
  exact scenarioDist_sq_aux ms mv ρ x y hms hmv hρ₁ hρ₂

/-- **The bell-curve radius tail** (Why it works, detailed proof). For two independent standard
bell-curve draws `x` and `y`, the chance that the radius `√(x² + y²)` exceeds any `a > 0` is
exactly `e^(-a²/2)`. -/
theorem standard_gaussian_radius_tail
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {X Y : Ω → ℝ}
    (hX : HasLaw X (gaussianReal 0 1) P) (hY : HasLaw Y (gaussianReal 0 1) P)
    (hXY : IndepFun X Y P) (a : ℝ) (ha : 0 < a) :
    P {ω | a < √(X ω ^ 2 + Y ω ^ 2)} = ENNReal.ofReal (exp (-a ^ 2 / 2)) := by
  exact gaussian_radius_tail_aux hX hY hXY a ha

-- Worked numbers, by hand: the stressed Acme price, $100 × (1 - 0.20) = $80.
example : (100 : ℚ) * (1 + (-20) / 100) = 80 := by norm_num

-- Stressed volatility: vol points are added, 20 percent plus 15 points is 35 percent.
example : (20 : ℚ) / 100 + 15 / 100 = 35 / 100 := by norm_num

-- The mistake: reading "+15 vol" as 15 percent of 20 gives 23 percent, not 35.
example : (20 : ℚ) * (1 + 15 / 100) = 23 := by norm_num

-- Short shares: -18,715 × (80 - 100) = +$374,300.
example : (-18715 : ℤ) * (80 - 100) = 374300 := by norm_num

-- The ray search: 720 directions spaced half a degree apart cover the full circle.
example : (720 : ℚ) * (1 / 2) = 360 := by norm_num

#print axioms reverse_stress_chance_bound
#print axioms scenario_dist_sq_eq_plain_dist_sq
#print axioms standard_gaussian_radius_tail
