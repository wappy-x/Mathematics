-- The variance swap: the short log contract that sets the fair variance strike is worth exactly the option strip weighted one over strike squared, the strip pays the log on every final price, and the variance payoff lies above the vega-linear one.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals

open MeasureTheory

/-- Helper: the same identity as `neg_log_eq_forward_add_option_strip`, proved here so the
first theorem can use it. -/
theorem neg_log_strip_aux (S F : ℝ) (hS : 0 < S) (hF : 0 < F) :
    -Real.log (S / F) =
      -(S - F) / F + (∫ K in (0 : ℝ)..F, max (K - S) 0 / K ^ 2) +
        ∫ K in Set.Ioi F, max (S - K) 0 / K ^ 2 := by
  rcases le_or_gt S F with hSF | hSF
  · have hcall : ∫ K in Set.Ioi F, max (S - K) 0 / K ^ 2 = 0 := by
      apply setIntegral_eq_zero_of_forall_eq_zero
      intro K hK
      have hK' : F < K := hK
      have : S - K ≤ 0 := by linarith
      simp [max_eq_right this]
    have heq0 : Set.EqOn (fun K : ℝ => max (K - S) 0 / K ^ 2) (fun _ => (0:ℝ)) (Set.uIcc 0 S) := by
      intro K hK
      rw [Set.uIcc_of_le hS.le] at hK
      have : K - S ≤ 0 := by linarith [hK.2]
      simp [max_eq_right this]
    have h1 : ∫ K in (0:ℝ)..S, max (K - S) 0 / K ^ 2 = 0 := by
      rw [intervalIntegral.integral_congr heq0]; simp
    have hi1 : IntervalIntegrable (fun K : ℝ => max (K - S) 0 / K ^ 2) MeasureTheory.volume 0 S :=
      (continuousOn_const.congr heq0).intervalIntegrable
    have heq2 : Set.EqOn (fun K : ℝ => max (K - S) 0 / K ^ 2) (fun K => K⁻¹ + S * (-(K ^ 2)⁻¹))
        (Set.uIcc S F) := by
      intro K hK
      rw [Set.uIcc_of_le hSF] at hK
      have hK0 : 0 < K := lt_of_lt_of_le hS hK.1
      have : 0 ≤ K - S := by linarith [hK.1]
      simp only [max_eq_left this]
      field_simp
      ring
    have hcont2 : ContinuousOn (fun K : ℝ => max (K - S) 0 / K ^ 2) (Set.uIcc S F) := by
      apply ContinuousOn.div (by fun_prop) (by fun_prop)
      intro K hK
      rw [Set.uIcc_of_le hSF] at hK
      have hK0 : 0 < K := lt_of_lt_of_le hS hK.1
      positivity
    have hi2 : IntervalIntegrable (fun K : ℝ => max (K - S) 0 / K ^ 2) MeasureTheory.volume S F :=
      hcont2.intervalIntegrable
    have h2 : ∫ K in S..F, max (K - S) 0 / K ^ 2
        = (Real.log F + S * F⁻¹) - (Real.log S + S * S⁻¹) := by
      rw [intervalIntegral.integral_congr heq2]
      apply intervalIntegral.integral_eq_sub_of_hasDerivAt (f := fun K => Real.log K + S * K⁻¹)
      · intro K hK
        rw [Set.uIcc_of_le hSF] at hK
        have hK0 : 0 < K := lt_of_lt_of_le hS hK.1
        exact (Real.hasDerivAt_log hK0.ne').add ((hasDerivAt_inv hK0.ne').const_mul S)
      · exact (hcont2.congr heq2.symm).intervalIntegrable
    rw [← intervalIntegral.integral_add_adjacent_intervals hi1 hi2, h1, h2, hcall,
      Real.log_div hS.ne' hF.ne']
    field_simp
    ring
  · have hput : ∫ K in (0:ℝ)..F, max (K - S) 0 / K ^ 2 = 0 := by
      have heq0 : Set.EqOn (fun K : ℝ => max (K - S) 0 / K ^ 2) (fun _ => (0:ℝ)) (Set.uIcc 0 F) := by
        intro K hK
        rw [Set.uIcc_of_le hF.le] at hK
        have : K - S ≤ 0 := by linarith [hK.2]
        simp [max_eq_right this]
      rw [intervalIntegral.integral_congr heq0]; simp
    have hsub : ∫ K in Set.Ioi F, max (S - K) 0 / K ^ 2 = ∫ K in Set.Ioc F S, max (S - K) 0 / K ^ 2 := by
      apply setIntegral_eq_of_subset_of_forall_sdiff_eq_zero measurableSet_Ioi Set.Ioc_subset_Ioi_self
      intro K hK
      have hK1 : F < K := hK.1
      have hK2 : S < K := by
        by_contra h
        exact hK.2 ⟨hK1, le_of_not_gt h⟩
      have : S - K ≤ 0 := by linarith
      simp [max_eq_right this]
    have heq2 : Set.EqOn (fun K : ℝ => max (S - K) 0 / K ^ 2) (fun K => -(S * -(K ^ 2)⁻¹) - K⁻¹)
        (Set.uIcc F S) := by
      intro K hK
      rw [Set.uIcc_of_le hSF.le] at hK
      have hK0 : 0 < K := lt_of_lt_of_le hF hK.1
      have : 0 ≤ S - K := by linarith [hK.2]
      simp only [max_eq_left this]
      field_simp
    have hcont2 : ContinuousOn (fun K : ℝ => max (S - K) 0 / K ^ 2) (Set.uIcc F S) := by
      apply ContinuousOn.div (by fun_prop) (by fun_prop)
      intro K hK
      rw [Set.uIcc_of_le hSF.le] at hK
      have hK0 : 0 < K := lt_of_lt_of_le hF hK.1
      positivity
    have h2 : ∫ K in F..S, max (S - K) 0 / K ^ 2
        = (-(S * S⁻¹) - Real.log S) - (-(S * F⁻¹) - Real.log F) := by
      rw [intervalIntegral.integral_congr heq2]
      apply intervalIntegral.integral_eq_sub_of_hasDerivAt (f := fun K => -(S * K⁻¹) - Real.log K)
      · intro K hK
        rw [Set.uIcc_of_le hSF.le] at hK
        have hK0 : 0 < K := lt_of_lt_of_le hF hK.1
        exact ((hasDerivAt_inv hK0.ne').const_mul S).neg.sub (Real.hasDerivAt_log hK0.ne')
      · exact (hcont2.congr heq2.symm).intervalIntegrable
    rw [hput, hsub, ← intervalIntegral.integral_of_le hSF.le, h2, Real.log_div hS.ne' hF.ne']
    field_simp
    ring

#print axioms neg_log_strip_aux

/-- The fair strike comes from the option strip with no model. Take any pricing-world
distribution `μ` of the final price `S_T` (European options at every strike, expiring with
the swap, a known rate `r`): prices are positive, the forward `F` is the average of `S_T`,
and the log contract has a price. Put and call prices are the discounted average payoffs
`P(K) = e^{-rT} E[(K - S_T)^+]` and `C(K) = e^{-rT} E[(S_T - K)^+]`. Then the fair variance
`K_var = (2/T) E[-ln(S_T/F)]` (Step 2 of the card) equals
`(2 e^{rT} / T) (∫_0^F P(K)/K^2 dK + ∫_F^∞ C(K)/K^2 dK)`.
(Step 1, that the hedged log contract earns realised variance, is Ito calculus, which
Mathlib does not have; this theorem is Steps 2 and 3.) -/
theorem fair_variance_strike_eq_option_strip
    (μ : Measure ℝ) [IsProbabilityMeasure μ] (r T F : ℝ) (hT : 0 < T) (hF : 0 < F)
    (hpos : ∀ᵐ s ∂μ, 0 < s) (hint : Integrable (fun s : ℝ => s) μ)
    (hmean : ∫ s, s ∂μ = F) (hlog : Integrable Real.log μ) :
    (2 / T) * ∫ s, -Real.log (s / F) ∂μ =
      2 * Real.exp (r * T) / T *
        ((∫ K in (0 : ℝ)..F, Real.exp (-(r * T)) * (∫ s, max (K - s) 0 ∂μ) / K ^ 2) +
          ∫ K in Set.Ioi F, Real.exp (-(r * T)) * (∫ s, max (s - K) 0 ∂μ) / K ^ 2) := by
  set P : ℝ → ℝ → ℝ := fun s K => max (K - s) 0 / K ^ 2 with hP
  set C : ℝ → ℝ → ℝ := fun s K => max (s - K) 0 / K ^ 2 with hC
  have hPnn : ∀ s K, 0 ≤ P s K := fun s K => div_nonneg (le_max_right _ _) (sq_nonneg _)
  have hCnn : ∀ s K, 0 ≤ C s K := fun s K => div_nonneg (le_max_right _ _) (sq_nonneg _)
  have hpt : ∀ᵐ s ∂μ, -Real.log (s / F) =
      -(s - F) / F + (∫ K in Set.Ioc 0 F, P s K) + ∫ K in Set.Ioi F, C s K := by
    filter_upwards [hpos] with s hs
    rw [neg_log_strip_aux s F hs hF, intervalIntegral.integral_of_le hF.le]
  have hg : Integrable (fun s => -Real.log (s / F) + (s - F) / F) μ := by
    have hae : (fun s => -Real.log (s / F) + (s - F) / F) =ᵐ[μ]
        fun s => (-Real.log s + Real.log F) + (s / F - 1) := by
      filter_upwards [hpos] with s hs
      rw [Real.log_div hs.ne' hF.ne']
      field_simp
      ring
    refine Integrable.congr ?_ hae.symm
    exact (hlog.neg.add (integrable_const _)).add ((hint.div_const F).sub (integrable_const _))
  have hPm : Measurable (Function.uncurry P) := by
    simp only [hP]; fun_prop
  have hCm : Measurable (Function.uncurry C) := by
    simp only [hC]; fun_prop
  have hPint : Integrable (Function.uncurry P) (μ.prod (volume.restrict (Set.Ioc 0 F))) := by
    rw [integrable_prod_iff hPm.aestronglyMeasurable]
    constructor
    · filter_upwards [hpos] with s hs
      refine Integrable.mono' (integrable_const (1 / s)) ?_ ?_
      · exact (hPm.comp measurable_prodMk_left).aestronglyMeasurable
      · refine Filter.Eventually.of_forall (fun K => ?_)
        simp only [Function.uncurry_apply_pair, hP, Real.norm_eq_abs]
        rw [abs_of_nonneg (div_nonneg (le_max_right _ _) (sq_nonneg _))]
        rcases le_or_gt K s with hKs | hKs
        · rw [max_eq_right (by linarith), zero_div]; exact div_nonneg zero_le_one hs.le
        · rw [max_eq_left (by linarith), div_le_div_iff₀ (pow_pos (by linarith) 2) hs]
          nlinarith
    · refine Integrable.mono' hg ?_ ?_
      · exact hPm.norm.aestronglyMeasurable.integral_prod_right'
      · filter_upwards [hpt] with s hs
        simp only [Function.uncurry_apply_pair, Real.norm_eq_abs, abs_of_nonneg (hPnn _ _)]
        rw [abs_of_nonneg (integral_nonneg (fun K => hPnn s K))]
        have := integral_nonneg (μ := volume.restrict (Set.Ioi F)) (f := fun K => C s K) (fun K => hCnn s K)
        have := neg_div F (s - F)
        linarith
  have hCint : Integrable (Function.uncurry C) (μ.prod (volume.restrict (Set.Ioi F))) := by
    rw [integrable_prod_iff hCm.aestronglyMeasurable]
    constructor
    · filter_upwards [hpos] with s hs
      have hr : IntegrableOn (fun K : ℝ => s * K ^ (-2 : ℝ)) (Set.Ioi F) :=
        (integrableOn_Ioi_rpow_of_lt (by norm_num) hF).const_mul s
      refine Integrable.mono' hr ?_ ?_
      · exact (hCm.comp measurable_prodMk_left).aestronglyMeasurable
      · filter_upwards [ae_restrict_mem measurableSet_Ioi] with K hK
        have hK0 : 0 < K := lt_trans hF hK
        simp only [Function.uncurry_apply_pair, hC, Real.norm_eq_abs]
        rw [abs_of_nonneg (div_nonneg (le_max_right _ _) (sq_nonneg _)),
          Real.rpow_neg hK0.le, Real.rpow_two, ← div_eq_mul_inv]
        apply div_le_div_of_nonneg_right _ (sq_nonneg _)
        exact max_le (by linarith) hs.le
    · refine Integrable.mono' hg ?_ ?_
      · exact hCm.norm.aestronglyMeasurable.integral_prod_right'
      · filter_upwards [hpt] with s hs
        simp only [Function.uncurry_apply_pair, Real.norm_eq_abs, abs_of_nonneg (hCnn _ _)]
        rw [abs_of_nonneg (integral_nonneg (fun K => hCnn s K))]
        have := integral_nonneg (μ := volume.restrict (Set.Ioc 0 F)) (f := fun K => P s K) (fun K => hPnn s K)
        have := neg_div F (s - F)
        linarith
  have hPi : Integrable (fun s => ∫ K in Set.Ioc 0 F, P s K) μ := hPint.integral_prod_left
  have hCi : Integrable (fun s => ∫ K in Set.Ioi F, C s K) μ := hCint.integral_prod_left
  have hfwd : Integrable (fun s : ℝ => -(s - F) / F) μ :=
    ((hint.sub (integrable_const F)).neg).div_const F
  have hfwd0 : ∫ s, -(s - F) / F ∂μ = 0 := by
    rw [integral_div, integral_neg, integral_sub hint (integrable_const F), hmean]
    simp
  have hE : ∫ s, -Real.log (s / F) ∂μ =
      (∫ K in Set.Ioc 0 F, ∫ s, P s K ∂μ) + ∫ K in Set.Ioi F, ∫ s, C s K ∂μ := by
    rw [integral_congr_ae hpt, integral_add (f := fun s => -(s - F) / F + ∫ K in Set.Ioc 0 F, P s K)
      (g := fun s => ∫ K in Set.Ioi F, C s K) (hfwd.add hPi) hCi]
    rw [integral_add hfwd hPi, hfwd0, zero_add, integral_integral_swap hPint, integral_integral_swap hCint]
  have hswapP : ∀ K, ∫ s, P s K ∂μ = (∫ s, max (K - s) 0 ∂μ) / K ^ 2 := fun K => by
    simp only [hP]; rw [integral_div]
  have hswapC : ∀ K, ∫ s, C s K ∂μ = (∫ s, max (s - K) 0 ∂μ) / K ^ 2 := fun K => by
    simp only [hC]; rw [integral_div]
  simp_rw [hswapP, hswapC] at hE
  simp_rw [mul_div_assoc]
  rw [intervalIntegral.integral_of_le hF.le, integral_const_mul, integral_const_mul, hE]
  have he : Real.exp (r * T) * Real.exp (-(r * T)) = 1 := by
    rw [← Real.exp_add]; simp
  linear_combination (-(2 / T) * ((∫ K in Set.Ioc 0 F, (∫ s, max (K - s) 0 ∂μ) / K ^ 2) +
    ∫ K in Set.Ioi F, (∫ s, max (s - K) 0 ∂μ) / K ^ 2)) * he

/-- The strip pays the log exactly, on every final price: for a final price `S_T > 0` and a
forward `F > 0`, a forward struck at `F`, puts below `F` and calls above `F`, each weighted
one over strike squared, pay `-ln(S_T/F)`. -/
theorem neg_log_eq_forward_add_option_strip (S F : ℝ) (hS : 0 < S) (hF : 0 < F) :
    -Real.log (S / F) =
      -(S - F) / F + (∫ K in (0 : ℝ)..F, max (K - S) 0 / K ^ 2) +
        ∫ K in Set.Ioi F, max (S - K) 0 / K ^ 2 := by
  exact neg_log_strip_aux S F hS hF

/-- Variance notional is vega notional over twice the strike. With that sizing the variance
swap's payoff `N_var (σ^2 - K^2)` never falls below the straight vega payoff `N_vega (σ - K)`,
and the two are equal exactly when the realised volatility `σ` equals the strike `K`. -/
theorem variance_payoff_ge_vega_payoff (Nvega K σ : ℝ) (hN : 0 < Nvega) (hK : 0 < K) :
    Nvega * (σ - K) ≤ Nvega / (2 * K) * (σ ^ 2 - K ^ 2) ∧
      (Nvega * (σ - K) = Nvega / (2 * K) * (σ ^ 2 - K ^ 2) ↔ σ = K) := by
  have key : Nvega / (2 * K) * (σ ^ 2 - K ^ 2) - Nvega * (σ - K) = Nvega / (2 * K) * (σ - K) ^ 2 := by
    field_simp
    ring
  have hc : 0 < Nvega / (2 * K) := by positivity
  refine ⟨?_, ?_⟩
  · have : 0 ≤ Nvega / (2 * K) * (σ - K) ^ 2 := by positivity
    linarith
  · constructor
    · intro h
      have h0 : Nvega / (2 * K) * (σ - K) ^ 2 = 0 := by linarith
      rcases mul_eq_zero.mp h0 with h1 | h1
      · exact absurd h1 hc.ne'
      · have := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp h1
        linarith
    · intro h; subst h; ring

-- Worked numbers: $100,000 vega notional struck at 20 vol points is $2,500 per variance point.
example : (100000 : ℤ) / (2 * 20) = 2500 := by norm_num
-- Variance swap payoffs at realised volatility 10, 15, 20, 25, 30 (dollars).
example : (2500 : ℤ) * (10 ^ 2 - 20 ^ 2) = -750000 := by norm_num
example : (2500 : ℤ) * (15 ^ 2 - 20 ^ 2) = -437500 := by norm_num
example : (2500 : ℤ) * (20 ^ 2 - 20 ^ 2) = 0 := by norm_num
example : (2500 : ℤ) * (25 ^ 2 - 20 ^ 2) = 562500 := by norm_num
example : (2500 : ℤ) * (30 ^ 2 - 20 ^ 2) = 1250000 := by norm_num
-- The straight vega-linear payoffs at the same points.
example : (100000 : ℤ) * (10 - 20) = -1000000 := by norm_num
example : (100000 : ℤ) * (15 - 20) = -500000 := by norm_num
example : (100000 : ℤ) * (25 - 20) = 500000 := by norm_num
example : (100000 : ℤ) * (30 - 20) = 1000000 := by norm_num
-- 20 vol points is 400 variance points.
example : (20 : ℤ) ^ 2 = 400 := by norm_num

#print axioms fair_variance_strike_eq_option_strip
#print axioms neg_log_eq_forward_add_option_strip
#print axioms variance_payoff_ge_vega_payoff
