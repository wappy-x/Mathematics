-- Credibility and reinsurance: the credibility weight n/(n + s/a) gives the least-squared-error straight-line forecast with error a(1 - Z), a reinsurance layer's expected payment is the integral of tail chances, and the excess-of-loss price is the expected claim count times the per-claim layer value.
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Moments.Covariance
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.IdentDistrib
import Mathlib.MeasureTheory.Integral.Layercake

open MeasureTheory ProbabilityTheory
open scoped ENNReal


variable {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}

/-- Helper: the mean squared error of the straight-line forecast `c + z * X` for `M`, written
with the means, variances and covariance. -/
theorem mean_sq_error_linear_forecast [IsProbabilityMeasure P]
    (M X : Ω → ℝ) (hM : MemLp M 2 P) (hX : MemLp X 2 P) (c z : ℝ) :
    ∫ ω, (M ω - (c + z * X ω)) ^ 2 ∂P
      = Var[M; P] - 2 * z * cov[M, X; P] + z ^ 2 * Var[X; P] + (P[M] - c - z * P[X]) ^ 2 := by
  have iM2 : Integrable (fun ω => M ω ^ 2) P := hM.integrable_sq
  have iX2 : Integrable (fun ω => X ω ^ 2) P := hX.integrable_sq
  have iMX : Integrable (fun ω => M ω * X ω) P := hM.integrable_mul hX
  have iM : Integrable M P := hM.integrable one_le_two
  have iX : Integrable X P := hX.integrable one_le_two
  have e : (fun ω => (M ω - (c + z * X ω)) ^ 2) = fun ω =>
      ((M ω ^ 2 + (-2 * z) * (M ω * X ω)) + z ^ 2 * X ω ^ 2)
        + (((-2 * c) * M ω + (2 * c * z) * X ω) + c ^ 2) := by
    ext ω; ring
  rw [e, integral_add (by fun_prop) (by fun_prop), integral_add (by fun_prop) (by fun_prop),
    integral_add (by fun_prop) (by fun_prop), integral_add (by fun_prop) (by fun_prop),
    integral_add (by fun_prop) (by fun_prop), integral_const_mul, integral_const_mul,
    integral_const_mul, integral_const_mul, integral_const,
    variance_eq_sub hM, variance_eq_sub hX, covariance_eq_sub hM hX]
  simp only [Pi.pow_apply, Pi.mul_apply, probReal_univ, smul_eq_mul, one_mul]
  ring

/-- Helper: a random-length sum of nonnegative terms, integrated, is the sum over `i` of the
integral of term `i` on the event `{i < N}`. -/
theorem lintegral_random_sum_eq_tsum (N : Ω → ℕ) (hN : Measurable N)
    (g : ℕ → Ω → ℝ≥0∞) (hg : ∀ i, Measurable (g i)) :
    ∫⁻ ω, ∑ i ∈ Finset.range (N ω), g i ω ∂P
      = ∑' i, ∫⁻ ω, (Set.Ioi i).indicator (fun _ => (1 : ℝ≥0∞)) (N ω) * g i ω ∂P := by
  have hpt : ∀ ω, ∑ i ∈ Finset.range (N ω), g i ω
      = ∑' i, (Set.Ioi i).indicator (fun _ => (1 : ℝ≥0∞)) (N ω) * g i ω := by
    intro ω
    rw [sum_eq_tsum_indicator]
    congr 1; ext i
    simp only [Set.indicator, Finset.coe_range, Set.mem_Iio, Set.mem_Ioi]
    split_ifs <;> simp
  simp_rw [hpt]
  rw [lintegral_tsum]
  intro i
  exact (((measurable_const.indicator measurableSet_Ioi).comp hN).mul (hg i)).aemeasurable

/-- Bühlmann credibility. Let `M` be the policy's true long-run level and `Xbar` the average of
its `n` years of record, both with finite variance. Suppose both have mean `μ` (the class mean),
`M` has variance `a > 0` (spread between policies), `Xbar` has variance `a + s/n` (spread between
policies plus year-to-year noise `s` averaged over `n` years), and their covariance is `a`.
Put `Z = n / (n + s/a)`. Then among all straight-line forecasts `c + z * Xbar`, the blend
`(1 - Z) * μ + Z * Xbar` has the smallest expected squared error, and that error is `a * (1 - Z)`. -/
theorem credibility_weight_is_best_linear_forecast [IsProbabilityMeasure P]
    (M Xbar : Ω → ℝ) (hM : MemLp M 2 P) (hX : MemLp Xbar 2 P)
    (μ a s : ℝ) (n : ℕ) (hn : 0 < n) (ha : 0 < a)
    (hMmean : P[M] = μ) (hXmean : P[Xbar] = μ)
    (hVarM : Var[M; P] = a) (hVarX : Var[Xbar; P] = a + s / n)
    (hCov : cov[M, Xbar; P] = a) :
    let Z : ℝ := n / (n + s / a)
    (∀ c z : ℝ, ∫ ω, (M ω - ((1 - Z) * μ + Z * Xbar ω)) ^ 2 ∂P
        ≤ ∫ ω, (M ω - (c + z * Xbar ω)) ^ 2 ∂P) ∧
      ∫ ω, (M ω - ((1 - Z) * μ + Z * Xbar ω)) ^ 2 ∂P = a * (1 - Z) := by
  intro Z
  have hf : ∀ c z : ℝ, ∫ ω, (M ω - (c + z * Xbar ω)) ^ 2 ∂P
      = a - 2 * z * a + z ^ 2 * (a + s / n) + (μ - c - z * μ) ^ 2 := by
    intro c z
    rw [mean_sq_error_linear_forecast M Xbar hM hX c z, hVarM, hVarX, hCov, hMmean, hXmean]
  set v : ℝ := a + s / n with hv_def
  have hav : a ≤ v := by
    have h0 : 0 ≤ ∫ ω, (M ω - (0 + 1 * Xbar ω)) ^ 2 ∂P :=
      integral_nonneg fun ω => sq_nonneg _
    rw [hf] at h0
    nlinarith
  have hvpos : 0 < v := lt_of_lt_of_le ha hav
  have hnpos : (0 : ℝ) < n := by exact_mod_cast hn
  have hZ : Z = a / v := by
    have h1 : (n : ℝ) + s / a = (n / a) * v := by
      rw [hv_def]; field_simp
    show (n : ℝ) / (n + s / a) = a / v
    rw [h1]
    field_simp
  have hZv : Z * v = a := by rw [hZ]; field_simp
  refine ⟨fun c z => ?_, ?_⟩
  · rw [hf, hf]
    have key : (a - 2 * z * a + z ^ 2 * v + (μ - c - z * μ) ^ 2)
        - (a - 2 * Z * a + Z ^ 2 * v + (μ - (1 - Z) * μ - Z * μ) ^ 2)
        = v * (z - Z) ^ 2 + (μ - c - z * μ) ^ 2 := by
      linear_combination (2 * z - 2 * Z) * hZv
    nlinarith [mul_nonneg hvpos.le (sq_nonneg (z - Z)), sq_nonneg (μ - c - z * μ)]
  · rw [hf]
    have : μ - (1 - Z) * μ - Z * μ = 0 := by ring
    rw [this]
    nlinarith [hZv]

/-- A reinsurance layer's fair price is a tail integral: for a loss `Y` and retention `d`,
the expected payment `E[(Y - d)_+]` equals the integral over every level `t > d` of the
chance `P(Y > t)` that the loss reaches that level (both sides may be infinite). -/
theorem layer_price_eq_integral_of_tail_probability [IsProbabilityMeasure P]
    (Y : Ω → ℝ) (hY : Measurable Y) (d : ℝ) :
    ∫⁻ ω, ENNReal.ofReal (Y ω - d) ∂P = ∫⁻ t in Set.Ioi d, P {ω | t < Y ω} := by
  have h1 : ∫⁻ ω, ENNReal.ofReal (Y ω - d) ∂P = ∫⁻ ω, ENNReal.ofReal (max (Y ω - d) 0) ∂P := by
    congr 1; ext ω; rw [ENNReal.ofReal_max]; simp
  have hm : Measurable (fun ω => max (Y ω - d) 0) := (hY.sub_const d).max measurable_const
  rw [h1, lintegral_eq_lintegral_meas_lt P (f := fun ω => max (Y ω - d) 0)
    (Filter.Eventually.of_forall fun ω => le_max_right _ _) hm.aemeasurable]
  have h2 : ∀ t ∈ Set.Ioi (0:ℝ), P {ω | t < max (Y ω - d) 0} = P {ω | t + d < Y ω} := by
    intro t ht
    congr 1; ext ω
    simp only [Set.mem_ofPred_eq, lt_max_iff]
    simp only [Set.mem_Ioi] at ht
    constructor
    · rintro (h | h) <;> linarith
    · intro h; left; linarith
  rw [setLIntegral_congr_fun measurableSet_Ioi h2]
  rw [← lintegral_indicator measurableSet_Ioi, ← lintegral_indicator measurableSet_Ioi]
  rw [← lintegral_add_right_eq_self (μ := (MeasureTheory.volume : Measure ℝ))
    (fun t => (Set.Ioi d).indicator (fun t => P {ω | t < Y ω}) t) d]
  congr 1; ext t
  simp only [Set.indicator, Set.mem_Ioi]
  by_cases h : 0 < t
  · simp [h, show d < t + d by linarith]
  · simp [h, show ¬ d < t + d by linarith]

/-- Excess of loss factorises: if the claim count `N` is independent of the claim sizes
`Y 0, Y 1, ...`, and the sizes are independent of each other with a common law, then the
expected yearly payment `E[∑_{i < N} (Y_i - d)_+]` is `E[N] * E[(Y - d)_+]`. -/
theorem excess_of_loss_premium_eq_mean_count_mul_layer_value [IsProbabilityMeasure P]
    (Y : ℕ → Ω → ℝ) (N : Ω → ℕ) (hY : ∀ i, Measurable (Y i)) (hN : Measurable N)
    (hindepN : IndepFun N (fun ω i => Y i ω) P) (hindepY : iIndepFun Y P)
    (hident : ∀ i, IdentDistrib (Y i) (Y 0) P P) (d : ℝ) :
    ∫⁻ ω, ∑ i ∈ Finset.range (N ω), ENNReal.ofReal (Y i ω - d) ∂P
      = (∫⁻ ω, (N ω : ℝ≥0∞) ∂P) * ∫⁻ ω, ENNReal.ofReal (Y 0 ω - d) ∂P := by
  have hφ : Measurable (fun x : ℝ => ENNReal.ofReal (x - d)) :=
    ENNReal.measurable_ofReal.comp (measurable_id.sub_const d)
  have hNsum : ∀ ω, (N ω : ℝ≥0∞) = ∑ i ∈ Finset.range (N ω), (fun _ _ => (1 : ℝ≥0∞)) i ω := by
    intro ω; simp
  simp_rw [hNsum]
  rw [lintegral_random_sum_eq_tsum N hN (fun i ω => ENNReal.ofReal (Y i ω - d))
      (fun i => hφ.comp (hY i)),
    lintegral_random_sum_eq_tsum N hN _ (fun _ => measurable_const), ← ENNReal.tsum_mul_right]
  congr 1; ext i
  have hind : Measurable (fun n : ℕ => (Set.Ioi i).indicator (fun _ => (1 : ℝ≥0∞)) n) :=
    measurable_const.indicator measurableSet_Ioi
  have hproj : Measurable (fun y : ℕ → ℝ => ENNReal.ofReal (y i - d)) :=
    hφ.comp (measurable_pi_apply i)
  have hI := (hindepN.comp hind hproj)
  have hmul := lintegral_mul_eq_lintegral_mul_lintegral_of_indepFun'' (hind.comp hN).aemeasurable
    (hproj.comp (measurable_pi_iff.mpr hY)).aemeasurable hI
  simp only [Function.comp_def] at hmul
  rw [hmul]
  simp only [mul_one]
  congr 1
  exact ((hident i).comp hφ).lintegral_eq

/-! The card's worked numbers, as exact fractions. -/

-- class mean μ = (1 + 3)/2 = 2
example : ((1 : ℚ) + 3) / 2 = 2 := by norm_num
-- between-fleet spread a = ((1-2)^2 + (3-2)^2)/2 = 1
example : (((1 : ℚ) - 2) ^ 2 + (3 - 2) ^ 2) / 2 = 1 := by norm_num
-- credibility Z = 3/(3 + 2/1) = 0.6
example : (3 : ℚ) / (3 + 2 / 1) = 3 / 5 := by norm_num
-- fleet average (1 + 1 + 2)/3 and forecast 0.6 * 4/3 + 0.4 * 2 = 1.6
example : ((1 : ℚ) + 1 + 2) / 3 = 4 / 3 := by norm_num
example : (3 / 5 : ℚ) * (4 / 3) + (1 - 3 / 5) * 2 = 8 / 5 := by norm_num
-- the error parabola a - 2za + z^2 (a + s/n) at z = Z equals a(1 - Z) = 0.4
example : (1 : ℚ) - 2 * (3 / 5) * 1 + (3 / 5) ^ 2 * (1 + 2 / 3) = 2 / 5 := by norm_num
example : (1 : ℚ) * (1 - 3 / 5) = 2 / 5 := by norm_num
-- per-claim layer value 0.5 * (4000 - 2000) = 1000; excess-of-loss premium 1.6 * 1000 = 1600
example : (1 / 2 : ℚ) * (4000 - 2000) = 1000 := by norm_num
example : (8 / 5 : ℚ) * 1000 = 1600 := by norm_num
-- expected yearly total 1.6 * 2500 = 4000
example : (8 / 5 : ℚ) * ((1000 + 4000) / 2) = 4000 := by norm_num
-- wrong flipped ratio n/(n + a/s) = 3/(3 + 1/2) = 0.857
example : (3 : ℚ) / (3 + 1 / 2) = 6 / 7 := by norm_num
-- Z with n = 10 years is 5/6; Z with types 1.5 and 2.5 (a = 1/4) is 3/11 = 0.273
example : (10 : ℚ) / (10 + 2 / 1) = 5 / 6 := by norm_num
example : (3 : ℚ) / (3 + 2 / (1 / 4)) = 3 / 11 := by norm_num


#print axioms credibility_weight_is_best_linear_forecast
#print axioms layer_price_eq_integral_of_tail_probability
#print axioms excess_of_loss_premium_eq_mean_count_mul_layer_value
#print axioms mean_sq_error_linear_forecast
#print axioms lintegral_random_sum_eq_tsum
