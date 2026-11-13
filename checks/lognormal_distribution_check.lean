-- Lognormal: if the log return X is normal with centre μ and spread σ > 0, the price S = S0 e^X has E[S^k] = S0^k e^(kμ + k²σ²/2) for every real k and variance E[S]²(e^(σ²) - 1), has density e^(-(ln(s/S0) - μ)²/(2σ²))/(sσ√(2π)) and cumulative chance Φ((ln(s/S0) - μ)/σ), and its density peaks at S0 e^(μ - σ²), below the median S0 e^μ, which is below the mean.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Probability.Moments.Variance
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Real MeasureTheory ProbabilityTheory

/-- The card's lognormal density of the price `s`, for today's price `S0`, log-return centre `μ`
and spread `σ`: `f(s) = 1/(s σ √(2π)) · e^(-(ln(s/S0) - μ)^2/(2σ^2))` for `s > 0`, and `0` for
`s ≤ 0`. -/
noncomputable def lognormalPDF (S0 μ σ s : ℝ) : ℝ :=
  if 0 < s then 1 / (s * σ * √(2 * π)) * exp (-(log (s / S0) - μ) ^ 2 / (2 * σ ^ 2)) else 0

lemma lognormal_aux_toNNReal (σ : ℝ) : (((σ ^ 2).toNNReal : NNReal) : ℝ) = σ ^ 2 :=
  Real.coe_toNNReal _ (sq_nonneg σ)

lemma lognormal_aux_moment
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {X : Ω → ℝ}
    (S0 μ σ : ℝ) (hS0 : 0 < S0)
    (hX : HasLaw X (gaussianReal μ (σ ^ 2).toNNReal) P) (k : ℝ) :
    ∫ ω, (S0 * exp (X ω)) ^ k ∂P = S0 ^ k * exp (k * μ + k ^ 2 * σ ^ 2 / 2) := by
  have h : ∀ ω, (S0 * exp (X ω)) ^ k = S0 ^ k * exp (k * X ω) := by
    intro ω
    rw [Real.mul_rpow hS0.le (exp_pos _).le, ← Real.exp_mul, mul_comm (X ω)]
  simp_rw [h, integral_const_mul]
  have hm : ∫ ω, exp (k * X ω) ∂P = mgf X P k := rfl
  rw [hm, mgf_gaussianReal hX, lognormal_aux_toNNReal]
  congr 2
  ring

lemma lognormal_aux_pdf (S0 μ σ : ℝ) (hS0 : 0 < S0) (y : ℝ) :
    lognormalPDF S0 μ σ (S0 * exp y)
      = 1 / (S0 * σ * √(2 * π)) * exp (-(y - μ) ^ 2 / (2 * σ ^ 2) - y) := by
  rw [lognormalPDF, if_pos (mul_pos hS0 (exp_pos y)), mul_div_cancel_left₀ _ hS0.ne', log_exp,
    sub_eq_add_neg _ y, exp_add, exp_neg]
  field_simp

lemma lognormal_aux_map (S0 μ σ : ℝ) (hS0 : 0 < S0) (hσ : 0 < σ) :
    (gaussianReal μ (σ ^ 2).toNNReal).map (fun x ↦ S0 * exp x)
      = volume.withDensity (fun s ↦ ENNReal.ofReal (lognormalPDF S0 μ σ s)) := by
  set g : ℝ → ℝ := fun x ↦ S0 * exp x with hg
  have hgm : Measurable g := by fun_prop
  have hrange : Set.range g = Set.Ioi 0 := by
    ext y
    constructor
    · rintro ⟨x, rfl⟩
      exact mul_pos hS0 (exp_pos x)
    · intro hy
      refine ⟨log (y / S0), ?_⟩
      simp only [hg]
      rw [exp_log (div_pos hy hS0)]
      field_simp
  have hleft : Function.LeftInverse (fun y ↦ log (y / S0)) g := by
    intro x
    simp only [hg]
    rw [mul_div_cancel_left₀ _ hS0.ne', log_exp]
  have hemb : MeasurableEmbedding g :=
    MeasurableEmbedding.of_measurable_inverse hgm (hrange ▸ measurableSet_Ioi) (by fun_prop) hleft
  have hv0 : (σ ^ 2).toNNReal ≠ 0 := by
    intro h
    have := congrArg (fun t : NNReal ↦ (t : ℝ)) h
    simp only [lognormal_aux_toNNReal, NNReal.coe_zero] at this
    exact (pow_pos hσ 2).ne' this
  set ν := volume.withDensity (fun s ↦ ENNReal.ofReal (lognormalPDF S0 μ σ s)) with hν
  have hcomap : ν.comap g = gaussianReal μ (σ ^ 2).toNNReal := by
    ext s hs
    rw [hemb.comap_apply, hν, withDensity_apply _ (hemb.measurableSet_image' hs),
      lintegral_image_eq_lintegral_abs_deriv_mul hs (f' := fun x ↦ S0 * exp x)
        (fun x _ ↦ ((hasDerivAt_exp x).const_mul S0).hasDerivWithinAt) hemb.injective.injOn,
      gaussianReal_apply _ hv0 s]
    refine setLIntegral_congr_fun hs (fun x _ ↦ ?_)
    rw [gaussianPDF, ← ENNReal.ofReal_mul (abs_nonneg _)]
    congr 1
    rw [lognormal_aux_pdf S0 μ σ hS0, abs_of_pos (mul_pos hS0 (exp_pos x)), gaussianPDFReal,
      lognormal_aux_toNNReal,
      show √(2 * π * σ ^ 2) = √(2 * π) * σ by
        rw [Real.sqrt_mul (by positivity), Real.sqrt_sq hσ.le],
      sub_eq_add_neg _ x, exp_add, exp_neg]
    field_simp
  rw [← hcomap, hemb.map_comap, hrange]
  refine Measure.restrict_eq_self_of_ae_mem ?_
  rw [ae_iff]
  have hmeas : MeasurableSet {x : ℝ | ¬ x ∈ Set.Ioi 0} := measurableSet_Ioi.compl
  rw [hν, withDensity_apply _ hmeas]
  have h0 : Set.EqOn (fun s ↦ ENNReal.ofReal (lognormalPDF S0 μ σ s)) (fun _ ↦ 0)
      {x : ℝ | ¬ x ∈ Set.Ioi 0} := by
    intro x hx
    simp only [Set.mem_setOf_eq, Set.mem_Ioi] at hx
    simp [lognormalPDF, hx]
  rw [setLIntegral_congr_fun hmeas h0]
  simp

lemma lognormal_aux_std
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {X : Ω → ℝ}
    (μ σ : ℝ) (hσ : 0 < σ)
    (hX : HasLaw X (gaussianReal μ (σ ^ 2).toNNReal) P) :
    HasLaw (fun ω ↦ (X ω - μ) / σ) (gaussianReal 0 1) P := by
  have h := gaussianReal_div_const (gaussianReal_sub_const hX μ) σ
  convert h using 2
  · simp
  · ext
    simp only [NNReal.coe_one, NNReal.coe_div, NNReal.coe_mk, lognormal_aux_toNNReal]
    field_simp

lemma lognormal_aux_cdf_zero : cdf (gaussianReal 0 1) 0 = 1 / 2 := by
  set N := gaussianReal 0 1
  have : NullSingletonClass N := nullSingletonClass_gaussianReal one_ne_zero
  have hsym : N.map (fun x ↦ -x) = N := by
    simp only [N]
    rw [gaussianReal_map_neg, neg_zero]
  have h1 : N (Set.Iic 0) = N (Set.Ioi 0) := by
    rw [measure_congr (Ioi_ae_eq_Ici (μ := N) (a := (0 : ℝ)))]
    conv_lhs => rw [← hsym]
    rw [Measure.map_apply measurable_neg measurableSet_Iic]
    congr 1
    ext x
    simp
  have h1' : N.real (Set.Iic 0) = N.real (Set.Ioi 0) := by
    simp only [measureReal_def, h1]
  have h2 : N.real (Set.Ioi 0) = 1 - N.real (Set.Iic 0) := by
    rw [← Set.compl_Iic, measureReal_compl measurableSet_Iic]
    simp
  rw [cdf_eq_real]
  linarith

/-- **Every power of the price, and the variance** (The formula, Step 3). Let today's price be
`S0 > 0` and let the year's log return `X` be normal with centre `μ` and spread `σ > 0`, so the
price in a year is `S = S0 e^X`, lognormal with parameters `μ` and `σ`. Then for every real power
`k`, `E[S^k] = S0^k e^(kμ + k^2 σ^2/2)`, and `Var(S) = E[S]^2 (e^(σ^2) - 1)` with
`E[S] = S0 e^(μ + σ^2/2)`. -/
theorem lognormal_moment_and_variance
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {X : Ω → ℝ}
    (S0 μ σ : ℝ) (hS0 : 0 < S0) (hσ : 0 < σ)
    (hX : HasLaw X (gaussianReal μ (σ ^ 2).toNNReal) P) :
    (∀ k : ℝ, ∫ ω, (S0 * exp (X ω)) ^ k ∂P = S0 ^ k * exp (k * μ + k ^ 2 * σ ^ 2 / 2)) ∧
      Var[fun ω ↦ S0 * exp (X ω); P] = (S0 * exp (μ + σ ^ 2 / 2)) ^ 2 * (exp (σ ^ 2) - 1) := by
  have := hX.isProbabilityMeasure
  refine ⟨lognormal_aux_moment S0 μ σ hS0 hX, ?_⟩
  have hint : Integrable (fun ω ↦ exp (2 * X ω)) P := by
    rw [← mgf_pos_iff, mgf_gaussianReal hX]
    exact exp_pos _
  have hY : MemLp (fun ω ↦ S0 * exp (X ω)) 2 P := by
    rw [memLp_two_iff_integrable_sq (by
      have := hX.aemeasurable
      fun_prop)]
    refine (hint.const_mul (S0 ^ 2)).congr (Filter.Eventually.of_forall fun ω ↦ ?_)
    simp only
    rw [mul_pow, sq (exp (X ω)), ← exp_add, two_mul]
  rw [variance_eq_sub hY]
  have e2 : ∫ ω, ((fun ω ↦ S0 * exp (X ω)) ^ 2) ω ∂P = S0 ^ (2 : ℝ) * exp (2 * μ + 2 ^ 2 * σ ^ 2 / 2) := by
    rw [← lognormal_aux_moment S0 μ σ hS0 hX 2]
    congr 1
    ext ω
    simp only [Pi.pow_apply]
    exact (Real.rpow_two _).symm
  have e1 : ∫ ω, S0 * exp (X ω) ∂P = S0 * exp (μ + σ ^ 2 / 2) := by
    have := lognormal_aux_moment S0 μ σ hS0 hX 1
    simp only [Real.rpow_one, one_mul, one_pow] at this
    exact this
  rw [e2, e1, Real.rpow_two]
  have : exp (2 * μ + 2 ^ 2 * σ ^ 2 / 2) = exp (μ + σ ^ 2 / 2) ^ 2 * exp (σ ^ 2) := by
    rw [show exp (μ + σ ^ 2 / 2) ^ 2 * exp (σ ^ 2) = exp ((μ + σ ^ 2 / 2) + (μ + σ ^ 2 / 2) + σ ^ 2) by
      rw [sq (exp (μ + σ ^ 2 / 2)), ← exp_add, ← exp_add]]
    congr 1
    ring
  rw [this]
  ring

/-- **The density and the cumulative chance** (The formula, Steps 1 and 2). With `S0 > 0`,
`σ > 0` and `X` normal with centre `μ` and spread `σ`, the price `S = S0 e^X` has the density
`lognormalPDF S0 μ σ` (zero at or below zero), and for every price `s > 0`,
`P(S ≤ s) = Φ((ln(s/S0) - μ)/σ)`, where `Φ` is the standard normal's cumulative chance. -/
theorem lognormal_density_and_cdf
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {X : Ω → ℝ}
    (S0 μ σ : ℝ) (hS0 : 0 < S0) (hσ : 0 < σ)
    (hX : HasLaw X (gaussianReal μ (σ ^ 2).toNNReal) P) :
    HasLaw (fun ω ↦ S0 * exp (X ω))
        (volume.withDensity (fun s ↦ ENNReal.ofReal (lognormalPDF S0 μ σ s))) P ∧
      ∀ s : ℝ, 0 < s →
        P.real {ω | S0 * exp (X ω) ≤ s} = cdf (gaussianReal 0 1) ((log (s / S0) - μ) / σ) := by
  have := hX.isProbabilityMeasure
  refine ⟨?_, ?_⟩
  · rw [← lognormal_aux_map S0 μ σ hS0 hσ]
    exact HasLaw.fun_comp (Y := fun x ↦ S0 * exp x) ⟨by fun_prop, rfl⟩ hX
  · intro s hs
    have hZ := lognormal_aux_std μ σ hσ hX
    have hset : {ω | S0 * exp (X ω) ≤ s}
        = {ω | (fun z ↦ z ≤ (log (s / S0) - μ) / σ) ((X ω - μ) / σ)} := by
      ext ω
      simp only [Set.mem_setOf_eq]
      rw [div_le_div_iff_of_pos_right hσ, sub_le_sub_iff_right, le_log_iff_exp_le (div_pos hs hS0),
        le_div_iff₀' hS0]
    rw [hset, hZ.measureReal_eq (p := fun z ↦ z ≤ (log (s / S0) - μ) / σ) measurableSet_Iic,
      cdf_eq_real]
    rfl

/-- **Mode below median below mean** (Steps 1, 4 and 5). With `S0 > 0`, `σ > 0` and `X` normal
with centre `μ` and spread `σ`, for the price `S = S0 e^X`: the density has a single peak at the
mode `S0 e^(μ - σ^2)` (every other price has a strictly lower density), half the chance lies at
or below the median `S0 e^μ`, and mode < median < E[S]. -/
theorem lognormal_mode_lt_median_lt_mean
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {X : Ω → ℝ}
    (S0 μ σ : ℝ) (hS0 : 0 < S0) (hσ : 0 < σ)
    (hX : HasLaw X (gaussianReal μ (σ ^ 2).toNNReal) P) :
    (∀ s : ℝ, s ≠ S0 * exp (μ - σ ^ 2) →
        lognormalPDF S0 μ σ s < lognormalPDF S0 μ σ (S0 * exp (μ - σ ^ 2))) ∧
      P.real {ω | S0 * exp (X ω) ≤ S0 * exp μ} = 1 / 2 ∧
      S0 * exp (μ - σ ^ 2) < S0 * exp μ ∧
      S0 * exp μ < ∫ ω, S0 * exp (X ω) ∂P := by
  have := hX.isProbabilityMeasure
  have hmean : ∫ ω, S0 * exp (X ω) ∂P = S0 * exp (μ + σ ^ 2 / 2) := by
    have := lognormal_aux_moment S0 μ σ hS0 hX 1
    simp only [Real.rpow_one, one_mul, one_pow] at this
    exact this
  have hσ2 : 0 < σ ^ 2 := by positivity
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro s hs
    rw [lognormal_aux_pdf S0 μ σ hS0]
    by_cases hpos : 0 < s
    · have hsx : s = S0 * exp (log (s / S0)) := by
        rw [exp_log (div_pos hpos hS0)]
        field_simp
      set x := log (s / S0)
      rw [hsx, lognormal_aux_pdf S0 μ σ hS0]
      have hne : x - μ + σ ^ 2 ≠ 0 := by
        intro h
        apply hs
        rw [hsx]
        congr 2
        linarith
      have key : (-(x - μ) ^ 2 / (2 * σ ^ 2) - x) - (-(μ - σ ^ 2 - μ) ^ 2 / (2 * σ ^ 2) - (μ - σ ^ 2))
          = -((x - μ + σ ^ 2) ^ 2 / (2 * σ ^ 2)) := by
        field_simp
        ring
      have hp : 0 < (x - μ + σ ^ 2) ^ 2 / (2 * σ ^ 2) := by positivity
      have hc : 0 < 1 / (S0 * σ * √(2 * π)) := by positivity
      exact mul_lt_mul_of_pos_left (exp_lt_exp.2 (by linarith)) hc
    · rw [lognormalPDF, if_neg hpos]
      positivity
  · rw [(lognormal_density_and_cdf S0 μ σ hS0 hσ hX).2 _ (by positivity),
      mul_div_cancel_left₀ _ hS0.ne', log_exp, sub_self, zero_div, lognormal_aux_cdf_zero]
  · exact mul_lt_mul_of_pos_left (exp_lt_exp.2 (by linarith)) hS0
  · rw [hmean]
    exact mul_lt_mul_of_pos_left (exp_lt_exp.2 (by linarith)) hS0

-- The card's share: S0 = 50, μ = 8/100, σ = 30/100.
-- Half the variance: 0.30^2/2 = 0.09/2 = 0.045.
example : ((30 : ℚ) / 100) ^ 2 = 9 / 100 ∧ ((30 : ℚ) / 100) ^ 2 / 2 = 45 / 1000 := by norm_num
-- Exponents: mean μ + σ^2/2 = 0.125, mode μ - σ^2 = -0.01.
example : (8 : ℚ) / 100 + ((30 : ℚ) / 100) ^ 2 / 2 = 125 / 1000 ∧
    (8 : ℚ) / 100 - ((30 : ℚ) / 100) ^ 2 = -1 / 100 := by norm_num
-- Exponents for the price variance formula: 2μ + 2σ^2 = 0.34 and 2μ + σ^2 = 0.25 differ by σ^2 = 0.09.
example : 2 * ((8 : ℚ) / 100) + 2 * ((30 : ℚ) / 100) ^ 2 - (2 * ((8 : ℚ) / 100) + ((30 : ℚ) / 100) ^ 2)
    = 9 / 100 := by norm_num
-- Standard score for ending at $50: (ln(50/50) - 0.08)/0.30 = -4/15 (about -0.2667).
example : ((0 : ℚ) - 8 / 100) / (30 / 100) = -4 / 15 := by norm_num
-- Chance of ending below the mean is Φ(σ/2) = Φ(0.15).
example : ((30 : ℚ) / 100) / 2 = 15 / 100 := by norm_num
-- Z = +1 and Z = -1 exponents: 0.08 + 0.30 = 0.38 and 0.08 - 0.30 = -0.22.
example : (8 : ℚ) / 100 + 30 / 100 = 38 / 100 ∧ (8 : ℚ) / 100 - 30 / 100 = -22 / 100 := by norm_num
-- Price spread taken wrongly as S0 σ: 50 × 0.30 = $15.
example : (50 : ℚ) * (30 / 100) = 15 := by norm_num
-- Four years: μ = 4 × 0.08 = 0.32, variance 4 × 0.09 = 0.36, spread 0.60 = 2 × 0.30.
example : 4 * ((8 : ℚ) / 100) = 32 / 100 ∧ 4 * ((30 : ℚ) / 100) ^ 2 = 36 / 100 ∧
    (2 * ((30 : ℚ) / 100)) ^ 2 = 36 / 100 := by norm_num
-- A coin-flip year of 252 days has 253 outcomes, and its daily drift 0.08/252 sums back to 0.08.
example : (252 : ℕ) + 1 = 253 ∧ (252 : ℚ) * ((8 / 100) / 252) = 8 / 100 := by norm_num

#print axioms lognormal_aux_toNNReal
#print axioms lognormal_aux_moment
#print axioms lognormal_aux_pdf
#print axioms lognormal_aux_map
#print axioms lognormal_aux_std
#print axioms lognormal_aux_cdf_zero
#print axioms lognormal_moment_and_variance
#print axioms lognormal_density_and_cdf
#print axioms lognormal_mode_lt_median_lt_mean
