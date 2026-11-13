-- The geometric Asian call: in the Black-Scholes model the geometric average of the share price over the year is lognormal, so the call on it is priced exactly by the Black-Scholes formula with the volatility divided by √3 and the yield replaced by q̂ = (r + q)/2 + σ²/12, and with n fixing dates the log average is normal with mean ln S + νT(n+1)/(2n) and variance σ²T(n+1)(2n+1)/(6n²), which tend to the continuous half and third.
import Mathlib.Probability.BrownianMotion.Basic
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Probability.HasLaw
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Tactic.NormNum

open Real MeasureTheory ProbabilityTheory Filter Topology
open scoped NNReal

/-! The model (the card's "When it holds"): under the pricing measure `P`, Acme's price is
`S_t = S e^(ν t + σ W_t)` with `W` a Brownian motion (Mathlib's `IsBrownianReal`), constant bank
rate `r`, dividend yield `q` and volatility `σ`, and `ν = r - q - σ²/2`. The averaging window
runs from today to expiry `T`, the average is geometric, the strike `K` is fixed and the payoff
`max(G - K, 0)` is paid in cash at `T`. -/

/-- `N(x)`: the bell-curve area to the left of `x`. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- `ν = r - q - σ²/2`, the drift of the log price under the pricing measure. -/
noncomputable def logDrift (r q σ : ℝ) : ℝ := r - q - σ ^ 2 / 2

/-- Acme's price at time `t`: `S_t = S e^(ν t + σ W_t)`. -/
noncomputable def acmePrice (S r q σ : ℝ) {Ω : Type*} (W : ℝ≥0 → Ω → ℝ) (t : ℝ) (ω : Ω) : ℝ :=
  S * exp (logDrift r q σ * t + σ * W t.toNNReal ω)

/-- The continuous geometric average over `[0, T]`: `G = exp((1/T) ∫₀ᵀ ln S_t dt)`. -/
noncomputable def contGeomAverage (S r q σ T : ℝ) {Ω : Type*} (W : ℝ≥0 → Ω → ℝ) (ω : Ω) : ℝ :=
  exp ((1 / T) * ∫ t in (0 : ℝ)..T, log (acmePrice S r q σ W t ω))

/-- The geometric average on `n` equally spaced fixings `t_i = iT/n`, `i = 1, …, n` (today not
counted): multiply the `n` prices and take the `n`-th root. -/
noncomputable def fixingsGeomAverage (n : ℕ) (S r q σ T : ℝ) {Ω : Type*} (W : ℝ≥0 → Ω → ℝ)
    (ω : Ω) : ℝ :=
  (∏ i ∈ Finset.Icc 1 n, acmePrice S r q σ W (i * T / n) ω) ^ (1 / (n : ℝ))

/-- `σ_G = σ/√3`, the volatility of the average. -/
noncomputable def kvVol (σ : ℝ) : ℝ := σ / √3

/-- `q̂ = (r + q)/2 + σ²/12`, the stand-in yield that slows the average. -/
noncomputable def kvYield (r q σ : ℝ) : ℝ := (r + q) / 2 + σ ^ 2 / 12

/-- `d₁ = (ln(S/K) + (r - q̂ + σ_G²/2) T) / (σ_G √T)`; and `d₂ = d₁ - σ_G √T`. -/
noncomputable def kvD1 (S K r q σ T : ℝ) : ℝ :=
  (log (S / K) + (r - kvYield r q σ + kvVol σ ^ 2 / 2) * T) / (kvVol σ * √T)

lemma kv_gauss_Ioi (μ c s : ℝ) (hs : 0 < s) :
    (gaussianReal μ (s ^ 2).toNNReal).real (Set.Ioi c) = stdNormalCDF ((μ - c) / s) := by
  have hmap : gaussianReal μ (s ^ 2).toNNReal = (gaussianReal 0 1).map (fun z => μ + s * z) := by
    have : (fun z : ℝ => μ + s * z) = (fun z => μ + z) ∘ (fun z => s * z) := rfl
    rw [this, ← Measure.map_map (measurable_const_add μ) (measurable_const_mul s),
      gaussianReal_map_const_mul, gaussianReal_map_const_add]
    congr 1
    · ring
    · apply NNReal.eq
      simp [Real.coe_toNNReal _ (sq_nonneg s)]
  have hpre : (fun z => μ + s * z) ⁻¹' Set.Ioi c = Set.Ioi ((c - μ) / s) := by
    ext z
    simp only [Set.mem_preimage, Set.mem_Ioi, div_lt_iff₀ hs]
    constructor <;> intro h <;> linarith
  have hneg : (gaussianReal 0 1).map (fun x => -x) = gaussianReal 0 1 := by
    rw [gaussianReal_map_neg]; simp
  have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  rw [hmap, map_measureReal_apply (by fun_prop) measurableSet_Ioi, hpre, ← hneg,
    map_measureReal_apply (by fun_prop) measurableSet_Ioi]
  have hpre2 : (fun x : ℝ => -x) ⁻¹' Set.Ioi ((c - μ) / s) = Set.Iio ((μ - c) / s) := by
    ext z
    simp only [Set.mem_preimage, Set.mem_Ioi, Set.mem_Iio]
    constructor <;> intro h <;> linarith [show (μ - c) / s = -((c - μ) / s) by ring]
  rw [hpre2, stdNormalCDF, cdf_eq_real]
  exact measureReal_congr Iio_ae_eq_Iic

#print axioms kv_gauss_Ioi

lemma kv_pdf_tilt (m : ℝ) (v : ℝ≥0) (hv : v ≠ 0) (y : ℝ) :
    gaussianPDFReal m v y * exp y = exp (m + v / 2) * gaussianPDFReal (m + v) v y := by
  have hv' : (v : ℝ) ≠ 0 := by exact_mod_cast hv
  simp only [gaussianPDFReal]
  rw [mul_assoc, ← exp_add, mul_left_comm, ← exp_add]
  congr 2
  field_simp
  ring

#print axioms kv_pdf_tilt

lemma kv_setIntegral_exp (m c : ℝ) (v : ℝ≥0) (hv : v ≠ 0) :
    ∫ y in Set.Ioi c, exp y ∂gaussianReal m v =
      exp (m + v / 2) * (gaussianReal (m + v) v).real (Set.Ioi c) := by
  rw [← integral_indicator measurableSet_Ioi, ← integral_indicator_one measurableSet_Ioi,
    integral_gaussianReal_eq_integral_smul hv, integral_gaussianReal_eq_integral_smul hv,
    ← integral_const_mul]
  congr 1
  ext y
  by_cases h : y ∈ Set.Ioi c
  · simp only [Set.indicator_of_mem h, smul_eq_mul, Pi.one_apply, mul_one]
    exact kv_pdf_tilt m v hv y
  · simp [Set.indicator_of_notMem h]

#print axioms kv_setIntegral_exp

lemma kv_bs_integral (m K s : ℝ) (hK : 0 < K) (hs : 0 < s) :
    ∫ y, max (exp y - K) 0 ∂gaussianReal m (s ^ 2).toNNReal =
      exp (m + s ^ 2 / 2) * stdNormalCDF ((m - log K) / s + s)
        - K * stdNormalCDF ((m - log K) / s) := by
  have hv : (s ^ 2).toNNReal ≠ 0 := by
    rw [ne_eq, Real.toNNReal_eq_zero, not_le]; positivity
  have hcoe : (((s ^ 2).toNNReal : ℝ≥0) : ℝ) = s ^ 2 := Real.coe_toNNReal _ (sq_nonneg s)
  have e1 : (fun y => max (exp y - K) 0) = (Set.Ioi (log K)).indicator (fun y => exp y - K) := by
    ext y
    by_cases h : log K < y
    · have : K < exp y := (Real.log_lt_iff_lt_exp hK).1 h
      rw [Set.indicator_of_mem (Set.mem_Ioi.2 h), max_eq_left (by linarith)]
    · have : exp y ≤ K := by
        rw [not_lt, Real.le_log_iff_exp_le hK] at h; exact h
      rw [Set.indicator_of_notMem (by simpa using h), max_eq_right (by linarith)]
  rw [e1, integral_indicator measurableSet_Ioi,
    integral_sub (integrable_exp_mul_gaussianReal (t := 1) |>.integrableOn |>.congr_fun
      (fun y _ => by simp) measurableSet_Ioi) (integrableOn_const (by simp)),
    setIntegral_const, kv_setIntegral_exp _ _ _ hv, hcoe, kv_gauss_Ioi _ _ _ hs,
    kv_gauss_Ioi _ _ _ hs, smul_eq_mul]
  rw [mul_comm _ K]
  congr 3
  field_simp
  ring

#print axioms kv_bs_integral

lemma kv_sum_Icc_nat (n : ℕ) : 2 * ∑ i ∈ Finset.Icc 1 n, i = n * (n + 1) := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_Icc_succ_top (by omega), mul_add, ih]
    ring

#print axioms kv_sum_Icc_nat

lemma kv_sum_min_nat (n : ℕ) :
    6 * ∑ i ∈ Finset.Icc 1 n, ∑ j ∈ Finset.Icc 1 n, min i j = n * (n + 1) * (2 * n + 1) := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_Icc_succ_top (by omega)]
    rw [Finset.sum_congr rfl (g := fun i => ∑ j ∈ Finset.Icc 1 n, min i j + i) (fun i hi => by
      rw [Finset.sum_Icc_succ_top (by omega), min_eq_left (by simp at hi; omega)])]
    rw [Finset.sum_congr rfl (g := fun j => j) (s₁ := Finset.Icc 1 (n + 1)) (fun j hj => by
      simp at hj; exact min_eq_right (by omega))]
    rw [Finset.sum_add_distrib, Finset.sum_Icc_succ_top (by omega : 1 ≤ n + 1)]
    have h2 := kv_sum_Icc_nat n
    rw [mul_add, mul_add, mul_add, ih]
    nlinarith [h2]

#print axioms kv_sum_min_nat

lemma kv_hasLaw_sum_fixings {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsPreBrownianReal W P) (n : ℕ) (hn : 1 ≤ n) (T : ℝ) (hT : 0 ≤ T) :
    HasLaw (fun ω => ∑ i ∈ Finset.Icc 1 n, W (((i : ℝ) * T / n).toNNReal) ω)
      (gaussianReal 0 (T * (((n : ℝ) + 1) * (2 * n + 1) / 6)).toNNReal) P := by
  have hG : IsGaussianProcess (fun i : ℕ => W (((i : ℝ) * T / n).toNNReal)) P :=
    hW.isGaussianProcess.comp_right (fun i : ℕ => (((i : ℝ) * T / n).toNNReal))
  have hL := hG.hasGaussianLaw_fun_sum (I := Finset.Icc 1 n)
  have hmem : ∀ t, MemLp (W t) 2 P := fun t => (hW.isGaussianProcess.hasGaussianLaw_eval t).memLp_two
  have := hW.isGaussianProcess.isProbabilityMeasure
  refine ⟨hL.aemeasurable, ?_⟩
  rw [hL.map_eq_gaussianReal]
  congr 1
  · rw [integral_finsetSum _ (fun i _ => hW.integrable_eval _)]
    simp [hW.integral_eval]
  · rw [← covariance_self hL.aemeasurable, covariance_fun_sum_fun_sum' (fun i _ => hmem _)
      (fun i _ => hmem _)]
    simp only [hW.covariance_eval]
    congr 1
    have hn' : (0 : ℝ) < n := by exact_mod_cast hn
    have e : ∀ i j : ℕ, (((min (((i : ℝ) * T / n).toNNReal) (((j : ℝ) * T / n).toNNReal)) : ℝ≥0) : ℝ)
        = ((min i j : ℕ) : ℝ) * (T / n) := by
      intro i j
      rw [NNReal.coe_min, Real.coe_toNNReal _ (by positivity), Real.coe_toNNReal _ (by positivity),
        Nat.cast_min, mul_div_assoc, mul_div_assoc, min_mul_of_nonneg _ _ (by positivity)]
    simp only [e, ← Finset.sum_mul]
    have h6 : (6 : ℝ) * ∑ i ∈ Finset.Icc 1 n, ∑ j ∈ Finset.Icc 1 n, ((min i j : ℕ) : ℝ)
        = n * (n + 1) * (2 * n + 1) := by
      exact_mod_cast kv_sum_min_nat n
    field_simp
    linear_combination T * h6

#print axioms kv_hasLaw_sum_fixings

lemma kv_sum_Icc_eq_range (F : ℕ → ℝ) (n : ℕ) :
    ∑ i ∈ Finset.Icc 1 n, F i = ∑ k ∈ Finset.range n, F (k + 1) := by
  induction n with
  | zero => simp
  | succ n ih => rw [Finset.sum_Icc_succ_top (by omega), ih, Finset.sum_range_succ]

#print axioms kv_sum_Icc_eq_range

lemma kv_riemann (g : ℝ → ℝ) (hg : Continuous g) (T : ℝ) (hT : 0 < T) :
    Tendsto (fun n : ℕ => T / n * ∑ i ∈ Finset.Icc 1 n, g (i * T / n)) atTop
      (𝓝 (∫ t in (0 : ℝ)..T, g t)) := by
  rw [Metric.tendsto_atTop]
  intro ε hε
  obtain ⟨δ, hδ, hUC⟩ := Metric.uniformContinuousOn_iff.1
    ((isCompact_Icc (a := (0 : ℝ)) (b := T)).uniformContinuousOn_of_continuous hg.continuousOn)
    (ε / (2 * T)) (by positivity)
  obtain ⟨N, hN⟩ := exists_nat_gt (T / δ)
  refine ⟨N + 1, fun n hn => ?_⟩
  have hn0 : (0 : ℝ) < n := by
    have : (1 : ℝ) ≤ n := by exact_mod_cast (show 1 ≤ n by omega)
    linarith
  have hNn : (N : ℝ) < n := by exact_mod_cast (show N < n by omega)
  have hTn : T / n < δ := by
    rw [div_lt_iff₀ hn0]
    rw [div_lt_iff₀ hδ] at hN
    nlinarith
  set a : ℕ → ℝ := fun k => k * T / n with ha
  have hsplit : ∫ t in (0 : ℝ)..T, g t = ∑ k ∈ Finset.range n, ∫ t in a k..a (k + 1), g t := by
    rw [intervalIntegral.sum_integral_adjacent_intervals (fun k _ => hg.intervalIntegrable _ _)]
    simp only [ha, Nat.cast_zero, zero_mul, zero_div]
    congr 1
    all_goals field_simp
  have hstep : ∀ k, a (k + 1) - a k = T / n := by
    intro k; simp only [ha]; push_cast; ring
  have hR : T / n * ∑ i ∈ Finset.Icc 1 n, g (i * T / n) =
      ∑ k ∈ Finset.range n, ∫ t in a k..a (k + 1), g (a (k + 1)) := by
    simp only [intervalIntegral.integral_const, smul_eq_mul, hstep]
    rw [Finset.mul_sum, kv_sum_Icc_eq_range (fun i => T / n * g (i * T / n))]
  rw [hR, hsplit, dist_eq_norm, ← Finset.sum_sub_distrib]
  calc ‖∑ k ∈ Finset.range n, ((∫ t in a k..a (k + 1), g (a (k + 1))) -
          ∫ t in a k..a (k + 1), g t)‖
      ≤ ∑ k ∈ Finset.range n, ‖(∫ t in a k..a (k + 1), g (a (k + 1))) -
          ∫ t in a k..a (k + 1), g t‖ := norm_sum_le _ _
    _ ≤ ∑ k ∈ Finset.range n, ε / (2 * T) * |a (k + 1) - a k| := by
        apply Finset.sum_le_sum
        intro k hk
        have hk' : (k : ℝ) + 1 ≤ n := by
          have := Finset.mem_range.1 hk
          exact_mod_cast (show k + 1 ≤ n by omega)
        rw [← intervalIntegral.integral_sub intervalIntegrable_const (hg.intervalIntegrable _ _)]
        apply intervalIntegral.norm_integral_le_of_norm_le_const
        intro x hx
        have hle : a k ≤ a (k + 1) := by linarith [hstep k, div_pos hT hn0]
        rw [Set.uIoc_of_le hle] at hx
        have ha0 : 0 ≤ a k := by simp only [ha]; positivity
        have haT : a (k + 1) ≤ T := by
          simp only [ha]; push_cast
          rw [div_le_iff₀ hn0]; nlinarith
        rw [← dist_eq_norm]
        refine (hUC (a (k + 1)) ⟨by linarith [hx.1], haT⟩ x ⟨by linarith [hx.1], by linarith [hx.2]⟩
          ?_).le
        rw [Real.dist_eq, abs_of_nonneg (by linarith [hx.2])]
        linarith [hstep k, hx.1]
    _ = ε / 2 := by
        simp only [hstep, Finset.sum_const, Finset.card_range, nsmul_eq_mul,
          abs_of_pos (div_pos hT hn0)]
        field_simp
    _ < ε := by linarith

#print axioms kv_riemann

lemma kv_hasLaw_integral {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P) (T : ℝ) (hT : 0 < T) :
    HasLaw (fun ω => ∫ t in (0 : ℝ)..T, W t.toNNReal ω) (gaussianReal 0 (T ^ 3 / 3).toNNReal) P := by
  set R : ℕ → Ω → ℝ := fun n ω => T / n * ∑ i ∈ Finset.Icc 1 n, W (((i : ℝ) * T / n).toNNReal) ω
    with hRdef
  have hlim : ∀ᵐ ω ∂P, Tendsto (fun n => R n ω) atTop
      (𝓝 (∫ t in (0 : ℝ)..T, W t.toNNReal ω)) := by
    filter_upwards [hW.cont] with ω hω
    exact kv_riemann (fun t => W t.toNNReal ω) (hω.comp continuous_real_toNNReal) T hT
  have hRm : ∀ n, AEMeasurable (R n) P := fun n =>
    (Finset.aemeasurable_fun_sum _ (fun i _ => hW.aemeasurable _)).const_mul _
  have hJm := aemeasurable_of_tendsto_metrizable_ae' hRm hlim
  have hRlaw : ∀ n, 1 ≤ n → HasLaw (R n) (gaussianReal 0
      (.mk ((T / n) ^ 2) (sq_nonneg _) * (T * (((n : ℝ) + 1) * (2 * n + 1) / 6)).toNNReal)) P := by
    intro n hn
    have := gaussianReal_const_mul (kv_hasLaw_sum_fixings hW.toIsPreBrownianReal n hn T hT.le)
      (T / n)
    simpa only [mul_zero] using this
  have := hW.isGaussianProcess.isProbabilityMeasure
  refine ⟨hJm, ?_⟩
  apply Measure.ext_of_charFun
  funext u
  have hcont : Continuous (fun x : ℝ => Complex.exp (u * x * Complex.I)) := by fun_prop
  rw [charFun_gaussianReal, charFun_apply_real, integral_map hJm hcont.aestronglyMeasurable]
  have h1 : Tendsto (fun n => ∫ ω, Complex.exp (u * R n ω * Complex.I) ∂P) atTop
      (𝓝 (∫ ω, Complex.exp (u * (∫ t in (0 : ℝ)..T, W t.toNNReal ω) * Complex.I) ∂P)) := by
    refine tendsto_integral_of_dominated_convergence (fun _ => 1)
      (fun n => (hcont.measurable.comp_aemeasurable (hRm n)).aestronglyMeasurable) (integrable_const 1)
      (fun n => ae_of_all _ (fun ω => ?_)) (hlim.mono fun ω h => (hcont.tendsto _).comp h)
    rw [← Complex.ofReal_mul, Complex.norm_exp_ofReal_mul_I]
  have hV : Tendsto (fun n : ℕ => (T / n) ^ 2 * (T * (((n : ℝ) + 1) * (2 * n + 1) / 6))) atTop
      (𝓝 (T ^ 3 / 3)) := by
    have h0 := tendsto_one_div_atTop_nhds_zero_nat (𝕜 := ℝ)
    have h1 : Tendsto (fun n : ℕ => T ^ 3 * (1 / 3 + 1 / 2 * (1 / (n : ℝ)) +
        1 / 6 * ((1 / (n : ℝ)) * (1 / (n : ℝ)))))
        atTop (𝓝 (T ^ 3 * (1 / 3 + 1 / 2 * 0 + 1 / 6 * (0 * 0)))) :=
      tendsto_const_nhds.mul ((tendsto_const_nhds.add (tendsto_const_nhds.mul h0)).add
        (tendsto_const_nhds.mul (h0.mul h0)))
    have e : T ^ 3 * (1 / 3 + 1 / 2 * 0 + 1 / 6 * (0 * 0)) = T ^ 3 / 3 := by ring
    rw [e] at h1
    refine h1.congr' ?_
    filter_upwards [eventually_ge_atTop 1] with n hn
    have : (n : ℝ) ≠ 0 := by positivity
    field_simp
    ring
  have h2 : Tendsto (fun n => ∫ ω, Complex.exp (u * R n ω * Complex.I) ∂P) atTop
      (𝓝 (Complex.exp (u * (0 : ℝ) * Complex.I - (((T ^ 3 / 3).toNNReal : ℝ≥0) : ℂ) * u ^ 2 / 2))) := by
    have hF : Continuous (fun x : ℝ => Complex.exp (u * (0 : ℝ) * Complex.I - (x : ℂ) * u ^ 2 / 2)) := by
      fun_prop
    have h3 := (hF.tendsto _).comp hV
    rw [Real.coe_toNNReal _ (by positivity)]
    refine h3.congr' ?_
    filter_upwards [eventually_ge_atTop 1] with n hn
    rw [Function.comp_apply]
    have := (hRlaw n hn).integral_comp hcont.aestronglyMeasurable
    simp only [Function.comp_def] at this
    rw [this, ← charFun_apply_real, charFun_gaussianReal, NNReal.coe_mul, NNReal.coe_mk,
      Real.coe_toNNReal _ (by positivity)]
  exact tendsto_nhds_unique h1 h2

#print axioms kv_hasLaw_integral

/-- **Kemna-Vorst: the geometric Asian call is a Black-Scholes call** (The formula; Why it works,
Steps 0 to 4). In the Black-Scholes model with constant `r`, `q` and volatility `σ > 0`, today's
price `S > 0`, a fixed strike `K > 0` paid in cash at `T > 0`, and the averaging window running
from today to expiry, the price today of the call on the continuous geometric average `G`, its
average payoff `max(G - K, 0)` under the pricing measure discounted by `e^(-rT)`, is the
Black-Scholes call with volatility `σ_G = σ/√3` and yield `q̂ = (r + q)/2 + σ²/12`:
`C_G = S e^(-q̂T) N(d₁) - K e^(-rT) N(d₂)`, with `d₂ = d₁ - σ_G √T`. -/
theorem geometric_asian_call_kemna_vorst {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P)
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    exp (-r * T) * ∫ ω, max (contGeomAverage S r q σ T W ω - K) 0 ∂P =
      S * exp (-kvYield r q σ * T) * stdNormalCDF (kvD1 S K r q σ T)
        - K * exp (-r * T) * stdNormalCDF (kvD1 S K r q σ T - kvVol σ * √T) := by
  set J := fun ω => ∫ t in (0 : ℝ)..T, W t.toNNReal ω with hJdef
  have hJ : HasLaw J (gaussianReal 0 (T ^ 3 / 3).toNNReal) P := kv_hasLaw_integral hW T hT
  set m := log S + logDrift r q σ * T / 2 with hm
  set s := kvVol σ * √T with hsdef
  have h3 : (0 : ℝ) < √3 := by positivity
  have hsT : (0 : ℝ) < √T := Real.sqrt_pos.2 hT
  have hs : 0 < s := by rw [hsdef, kvVol]; positivity
  have hs2 : s ^ 2 = σ ^ 2 * T / 3 := by
    rw [hsdef, kvVol, mul_pow, div_pow, Real.sq_sqrt (by norm_num), Real.sq_sqrt hT.le]
    ring
  have hY : HasLaw (fun ω => m + σ / T * J ω) (gaussianReal m (s ^ 2).toNNReal) P := by
    have := gaussianReal_const_add (gaussianReal_const_mul hJ (σ / T)) m
    convert this using 2
    · simp
    · apply NNReal.eq
      rw [NNReal.coe_mul, NNReal.coe_mk, Real.coe_toNNReal _ (by positivity),
        Real.coe_toNNReal _ (by positivity), hs2]
      field_simp
  have hG : ∀ᵐ ω ∂P, contGeomAverage S r q σ T W ω = exp (m + σ / T * J ω) := by
    filter_upwards [hW.cont] with ω hω
    have hg : Continuous (fun t : ℝ => W t.toNNReal ω) := hω.comp continuous_real_toNNReal
    unfold contGeomAverage
    congr 1
    have e : ∀ t, log (acmePrice S r q σ W t ω) =
        log S + (logDrift r q σ * t + σ * W t.toNNReal ω) := by
      intro t
      unfold acmePrice
      rw [Real.log_mul hS.ne' (exp_pos _).ne', Real.log_exp]
    simp_rw [e]
    have hc1 : Continuous (fun t : ℝ => logDrift r q σ * t) := continuous_const.mul continuous_id
    have hc2 : Continuous (fun t : ℝ => σ * W t.toNNReal ω) := continuous_const.mul hg
    have hc3 : Continuous (fun t : ℝ => logDrift r q σ * t + σ * W t.toNNReal ω) := hc1.add hc2
    rw [intervalIntegral.integral_add intervalIntegrable_const (hc3.intervalIntegrable _ _),
      intervalIntegral.integral_add (hc1.intervalIntegrable _ _) (hc2.intervalIntegrable _ _),
      intervalIntegral.integral_const, intervalIntegral.integral_const_mul,
      intervalIntegral.integral_const_mul, integral_id]
    simp only [smul_eq_mul, hm, hJdef]
    field_simp
    ring
  rw [integral_congr_ae (g := fun ω => max (exp (m + σ / T * J ω) - K) 0)
    (hG.mono fun ω h => by simp only [h])]
  have hI := hY.integral_comp (f := fun y => max (exp y - K) 0) (by fun_prop)
  simp only [Function.comp_def] at hI
  rw [hI, kv_bs_integral m K s hK hs]
  have hlogSK : log (S / K) = log S - log K := Real.log_div hS.ne' hK.ne'
  have hd : (m - log K) / s + s = kvD1 S K r q σ T := by
    rw [kvD1, ← hsdef, hlogSK, kvYield, hm, logDrift]
    have hv2 : kvVol σ ^ 2 = σ ^ 2 / 3 := by
      rw [kvVol, div_pow, Real.sq_sqrt (by norm_num)]
    rw [hv2]
    field_simp
    rw [hs2]
    ring
  have hd2 : (m - log K) / s = kvD1 S K r q σ T - kvVol σ * √T := by
    rw [← hd, ← hsdef]; ring
  have hexp : exp (-r * T) * exp (m + s ^ 2 / 2) = S * exp (-kvYield r q σ * T) := by
    rw [← exp_add, hm, hs2, kvYield, logDrift]
    rw [show -r * T + (log S + (r - q - σ ^ 2 / 2) * T / 2 + σ ^ 2 * T / 3 / 2) =
      log S + (-((r + q) / 2 + σ ^ 2 / 12) * T) by ring, exp_add, exp_log hS]
  rw [hd2, ← hd2, hd, hd2]
  rw [mul_sub, ← mul_assoc, hexp]
  ring

/-- **On `n` fixing dates the average is still lognormal** (The formula; the detailed proof of
Step 2). In the same model, with `S > 0`, `T > 0` and `n ≥ 1` equally spaced fixings
`t_i = iT/n` ending at `T`, the log of the geometric average `G_n` is normal with mean
`ln S + νT (n+1)/(2n)` and variance `σ²T (n+1)(2n+1)/(6n²)`. -/
theorem log_fixings_geometric_average_is_normal {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P)
    (n : ℕ) (hn : 1 ≤ n) (S r q σ T : ℝ) (hS : 0 < S) (hT : 0 < T) :
    HasLaw (fun ω => log (fixingsGeomAverage n S r q σ T W ω))
      (gaussianReal (log S + logDrift r q σ * T * ((n + 1) / (2 * n)))
        (σ ^ 2 * T * ((n + 1) * (2 * n + 1) / (6 * n ^ 2))).toNNReal) P := by
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  have hZ := kv_hasLaw_sum_fixings hW.toIsPreBrownianReal n hn T hT.le
  have h1 := gaussianReal_const_add (gaussianReal_const_mul hZ (σ / n))
    (log S + logDrift r q σ * T * ((n + 1) / (2 * n)))
  have hsum : ∑ i ∈ Finset.Icc 1 n, (i : ℝ) = n * (n + 1) / 2 := by
    have := kv_sum_Icc_nat n
    have h' := congrArg (Nat.cast (R := ℝ)) this
    push_cast at h'
    linarith
  have key : ∀ ω, log (fixingsGeomAverage n S r q σ T W ω) =
      (log S + logDrift r q σ * T * ((n + 1) / (2 * n))) +
        σ / n * ∑ i ∈ Finset.Icc 1 n, W (((i : ℝ) * T / n).toNNReal) ω := by
    intro ω
    unfold fixingsGeomAverage
    have hpos : ∀ i ∈ Finset.Icc 1 n, 0 < acmePrice S r q σ W (i * T / n) ω := fun i _ => by
      unfold acmePrice; positivity
    rw [Real.log_rpow (Finset.prod_pos hpos), Real.log_prod (fun i hi => (hpos i hi).ne')]
    simp only [acmePrice, Real.log_mul hS.ne' (exp_pos _).ne', Real.log_exp]
    rw [Finset.sum_add_distrib, Finset.sum_add_distrib, Finset.sum_const, Nat.card_Icc]
    simp only [← Finset.mul_sum, ← Finset.sum_div, ← Finset.sum_mul, hsum]
    simp only [nsmul_eq_mul, Nat.add_sub_cancel]
    field_simp
    ring
  simp_rw [key]
  convert h1 using 2
  · simp
  · apply NNReal.eq
    rw [NNReal.coe_mul, NNReal.coe_mk, Real.coe_toNNReal _ (by positivity),
      Real.coe_toNNReal _ (by positivity)]
    field_simp

/-- **More fixings move the price toward the continuous one** (Step 5). At one fixing the mean and
variance of the log average are those of the last price, `ln S + νT` and `σ²T` (the vanilla
call); as the number of fixings `n` grows they tend to the continuous `ln S + νT/2` and
`σ²T/3`, the half and the third behind `q̂` and `σ_G = σ/√3`. -/
theorem fixings_tend_to_half_drift_third_variance (S r q σ T : ℝ) :
    (log S + logDrift r q σ * T * ((1 + 1) / (2 * 1)) = log S + logDrift r q σ * T ∧
      σ ^ 2 * T * ((1 + 1) * (2 * 1 + 1) / (6 * 1 ^ 2)) = σ ^ 2 * T) ∧
    Tendsto (fun n : ℕ => log S + logDrift r q σ * T * (((n : ℝ) + 1) / (2 * n))) atTop
      (𝓝 (log S + logDrift r q σ * T / 2)) ∧
    Tendsto (fun n : ℕ => σ ^ 2 * T * (((n : ℝ) + 1) * (2 * n + 1) / (6 * n ^ 2))) atTop
      (𝓝 (σ ^ 2 * T / 3)) := by
  have h0 := tendsto_one_div_atTop_nhds_zero_nat (𝕜 := ℝ)
  refine ⟨⟨by norm_num, by norm_num⟩, ?_, ?_⟩
  · have h1 : Tendsto (fun n : ℕ => log S + logDrift r q σ * T * (1 / 2 + 1 / 2 * (1 / (n : ℝ))))
        atTop (𝓝 (log S + logDrift r q σ * T * (1 / 2 + 1 / 2 * 0))) :=
      tendsto_const_nhds.add (tendsto_const_nhds.mul (tendsto_const_nhds.add
        (tendsto_const_nhds.mul h0)))
    have e : log S + logDrift r q σ * T * (1 / 2 + 1 / 2 * 0) = log S + logDrift r q σ * T / 2 := by
      ring
    rw [e] at h1
    refine h1.congr' ?_
    filter_upwards [eventually_ge_atTop 1] with n hn
    have : (n : ℝ) ≠ 0 := by positivity
    field_simp
  · have h1 : Tendsto (fun n : ℕ => σ ^ 2 * T * (1 / 3 + 1 / 2 * (1 / (n : ℝ)) +
        1 / 6 * ((1 / (n : ℝ)) * (1 / (n : ℝ)))))
        atTop (𝓝 (σ ^ 2 * T * (1 / 3 + 1 / 2 * 0 + 1 / 6 * (0 * 0)))) :=
      tendsto_const_nhds.mul ((tendsto_const_nhds.add (tendsto_const_nhds.mul h0)).add
        (tendsto_const_nhds.mul (h0.mul h0)))
    have e : σ ^ 2 * T * (1 / 3 + 1 / 2 * 0 + 1 / 6 * (0 * 0)) = σ ^ 2 * T / 3 := by ring
    rw [e] at h1
    refine h1.congr' ?_
    filter_upwards [eventually_ge_atTop 1] with n hn
    have : (n : ℝ) ≠ 0 := by positivity
    field_simp
    ring

/-! The card's exact worked numbers, as fractions. Acme: S = K = 100, r = 5/100, q = 2/100,
σ = 1/5, T = 1 year. -/

-- The toy averages of 81 and 121: geometric √(81 × 121) = 99, arithmetic (81 + 121)/2 = 101.
example : (99 : ℕ) * 99 = 81 * 121 := by norm_num
example : ((81 : ℕ) + 121) / 2 = 101 := by norm_num
example : (99 : ℕ) ≤ 101 := by norm_num
-- ν = r - q - σ²/2 = 0.05 - 0.02 - 0.02 = 0.01.
example : (5 / 100 : ℚ) - 2 / 100 - (1 / 5) ^ 2 / 2 = 1 / 100 := by norm_num
-- Variance of ln G: σ²T/3 = 0.04/3 = 0.013333, which is σ_G² T with σ_G = σ/√3.
example : (1 / 5 : ℚ) ^ 2 * 1 / 3 = 1 / 75 := by norm_num
-- q̂ = (r + q)/2 + σ²/12 = 0.035 + 0.003333 = 0.038333.
example : ((5 / 100 : ℚ) + 2 / 100) / 2 + (1 / 5) ^ 2 / 12 = 23 / 600 := by norm_num
-- b = r - q̂ = 0.011667, the same as (r - q)/2 - σ²/12.
example : (5 / 100 : ℚ) - 23 / 600 = 7 / 600 := by norm_num
example : ((5 / 100 : ℚ) - 2 / 100) / 2 - (1 / 5) ^ 2 / 12 = 7 / 600 := by norm_num
-- Step 3: r - q̂ = ν/2 + σ_G²/2, with σ_G² = σ²/3.
example : (7 / 600 : ℚ) = (1 / 100) / 2 + ((1 / 5) ^ 2 / 3) / 2 := by norm_num
-- Weekly fixings, n = 52: 1 + 2 + … + 52 = 52·53/2, and 1² + 2² + … + 52² = 52·53·105/6.
example : ∑ m ∈ Finset.Icc 1 52, m = 52 * 53 / 2 := by decide
example : ∑ m ∈ Finset.Icc 1 52, m ^ 2 = 52 * 53 * 105 / 6 := by decide
-- Weekly variance of ln G: σ²T · 53·105/(6·52²) = 0.04 × 1855/5408 = 0.013720.
example : (1 / 5 : ℚ) ^ 2 * 1 * ((52 + 1) * (2 * 52 + 1) / (6 * 52 ^ 2)) = 1855 / 135200 := by
  norm_num
-- Monthly fixings, n = 12: variance fraction 13·25/(6·144) = 325/864.
example : ((12 : ℚ) + 1) * (2 * 12 + 1) / (6 * 12 ^ 2) = 325 / 864 := by norm_num

#print axioms geometric_asian_call_kemna_vorst
#print axioms log_fixings_geometric_average_is_normal
#print axioms fixings_tend_to_half_drift_third_variance
