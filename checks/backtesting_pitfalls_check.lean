-- Backtesting: when phantom daily gains leave the spread unchanged, the Sharpe ratio rises by exactly √252/s per unit of average phantom gain, a constant daily gain never changes the spread, and a sign bet on a bell-curve draw cut at c averages twice the bell-curve height at c.
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Basic.Real.Sign
import Mathlib.Probability.Distributions.Gaussian.Real

open Finset ProbabilityTheory MeasureTheory

/-- The backtest ledger. Over `n` days, a backtest credits each day the live return plus three
phantom gains: look-ahead, survivorship and costs never charged. So the backtest's average daily
return is the live average plus the three phantom averages. The Sharpe ratio is `√252` times the
average divided by the spread `s` (standard deviation of the daily returns). When the spread is the
same in the backtest as live, the backtest's Sharpe ratio exceeds the live one by exactly
`√252 / s` times the sum of the phantom averages: each phantom unit of return a day adds
`√252 / s` to the Sharpe ratio. -/
theorem phantom_gains_raise_sharpe_by_root_252_over_spread (n : ℕ)
    (rLive gLook gSurv gCost : Fin n → ℝ) :
    let mean : (Fin n → ℝ) → ℝ := fun y => (∑ t, y t) / n
    let spread : (Fin n → ℝ) → ℝ := fun y => Real.sqrt ((∑ t, (y t - mean y) ^ 2) / n)
    let sharpe : (Fin n → ℝ) → ℝ := fun y => Real.sqrt 252 * mean y / spread y
    let rBack : Fin n → ℝ := fun t => rLive t + gLook t + gSurv t + gCost t
    spread rBack = spread rLive →
      mean rBack = mean rLive + mean gLook + mean gSurv + mean gCost ∧
      sharpe rBack - sharpe rLive =
        Real.sqrt 252 / spread rLive * (mean gLook + mean gSurv + mean gCost) := by
  intro mean spread sharpe rBack h
  have hm : mean rBack = mean rLive + mean gLook + mean gSurv + mean gCost := by
    simp only [mean, rBack, Finset.sum_add_distrib]
    ring
  refine ⟨hm, ?_⟩
  simp only [sharpe]
  rw [h, hm]
  ring

/-- Why a phantom gain barely touches the spread. Adding the same phantom gain `G` to every day's
return leaves the spread of daily returns exactly unchanged, and raises the Sharpe ratio by exactly
`√252 · G / s`. -/
theorem constant_phantom_gain_keeps_spread (n : ℕ) (r : Fin n → ℝ) (G : ℝ) :
    let mean : (Fin n → ℝ) → ℝ := fun y => (∑ t, y t) / n
    let spread : (Fin n → ℝ) → ℝ := fun y => Real.sqrt ((∑ t, (y t - mean y) ^ 2) / n)
    let sharpe : (Fin n → ℝ) → ℝ := fun y => Real.sqrt 252 * mean y / spread y
    spread (fun t => r t + G) = spread r ∧
      sharpe (fun t => r t + G) - sharpe r = Real.sqrt 252 * G / spread r := by
  intro mean spread sharpe
  rcases Nat.eq_zero_or_pos n with hn | hn
  · subst hn
    simp [mean, spread, sharpe]
  have hn' : (n : ℝ) ≠ 0 := by positivity
  have hm : mean (fun t => r t + G) = mean r + G := by
    simp only [mean, Finset.sum_add_distrib, Finset.sum_const, Finset.card_univ,
      Fintype.card_fin, nsmul_eq_mul]
    field_simp
  have hs : spread (fun t => r t + G) = spread r := by
    simp only [spread]
    rw [hm]
    congr 2
    refine Finset.sum_congr rfl fun t _ => ?_
    ring
  refine ⟨hs, ?_⟩
  simp only [sharpe]
  rw [hs, hm]
  ring

/-- The sign-bet identity behind the edge. For a standard bell-curve draw `z`, a bet of
`sign (z - c)` times `z` (plus above the cut point `c`, minus below) averages twice the bell-curve
height at the cut. At the cut `c = 0`, for a healthy stock, that is `2/√(2π) = √(2/π)`. -/
theorem sign_bet_average_eq_twice_height_at_cut (c : ℝ) :
    ∫ z, Real.sign (z - c) * z ∂(gaussianReal 0 1) = 2 * gaussianPDFReal 0 1 c ∧
      2 * gaussianPDFReal 0 1 0 = Real.sqrt (2 / Real.pi) := by
  set φ : ℝ → ℝ := gaussianPDFReal 0 1 with hφdef
  have hφ : ∀ z, φ z = (Real.sqrt (2 * Real.pi))⁻¹ * Real.exp (-z ^ 2 / 2) := by
    intro z
    simp [hφdef, gaussianPDFReal]
  have hv : (1 : NNReal) ≠ 0 := one_ne_zero
  -- integrability of z * φ z
  have hint : Integrable (fun z => φ z * z) := by
    have h0 := (integrable_mul_exp_neg_mul_sq (b := 1 / 2) (by norm_num)).const_mul
      (Real.sqrt (2 * Real.pi))⁻¹
    refine h0.congr (ae_of_all _ fun z => ?_)
    simp only [hφ]
    ring_nf
  -- mean zero
  have hmean : ∫ z, φ z * z = 0 := by
    have := integral_gaussianReal_eq_integral_smul (μ := 0) (f := fun z : ℝ => z) hv
    simp only [integral_id_gaussianReal, smul_eq_mul] at this
    rw [hφdef, ← this]
  -- tail integral
  have htail : ∫ z in Set.Ioi c, φ z * z = φ c := by
    have hderiv : ∀ x ∈ Set.Ici c, HasDerivAt (fun z => -φ z) (φ x * x) x := by
      intro x _
      have h1 : HasDerivAt (fun z : ℝ => -z ^ 2 / 2) (-x) x := by
        have := ((hasDerivAt_pow 2 x).neg).div_const 2
        convert this using 1
        push_cast; ring
      have h2 := (h1.exp.const_mul (Real.sqrt (2 * Real.pi))⁻¹).neg
      have hfun : (fun z => -φ z) =
          fun z => -((Real.sqrt (2 * Real.pi))⁻¹ * Real.exp (-z ^ 2 / 2)) := by
        ext z; rw [hφ]
      rw [hfun]
      convert h2 using 1
      rw [hφ]; ring
    have hlim : Filter.Tendsto (fun z => -φ z) Filter.atTop (nhds 0) := by
      have h1 : Filter.Tendsto (fun z : ℝ => -z ^ 2 / 2) Filter.atTop Filter.atBot := by
        have : Filter.Tendsto (fun z : ℝ => z ^ 2 / 2) Filter.atTop Filter.atTop :=
          (Filter.tendsto_pow_atTop two_ne_zero).atTop_div_const (by norm_num)
        have := Filter.tendsto_neg_atTop_atBot.comp this
        refine this.congr fun z => ?_
        simp only [Function.comp]
        ring
      have h2 := ((Real.tendsto_exp_atBot.comp h1).const_mul
        (Real.sqrt (2 * Real.pi))⁻¹).neg
      simp only [mul_zero, neg_zero] at h2
      refine h2.congr fun z => ?_
      simp only [Function.comp, hφ]
    rw [integral_Ioi_of_hasDerivAt_of_tendsto' hderiv hint.integrableOn hlim]
    ring
  have hφ0 : φ 0 = (Real.sqrt (2 * Real.pi))⁻¹ := by rw [hφ]; simp
  refine ⟨?_, ?_⟩
  · rw [integral_gaussianReal_eq_integral_smul hv]
    have hae : (fun z => gaussianPDFReal 0 1 z • (Real.sign (z - c) * z)) =ᵐ[volume]
        fun z => 2 * (Set.Ioi c).indicator (fun z => φ z * z) z - φ z * z := by
      filter_upwards [compl_mem_ae_iff.2 (Real.volume_singleton (a := c))] with z hz
      have hz' : z ≠ c := hz
      rcases lt_or_gt_of_ne hz' with h | h
      · have hs : Real.sign (z - c) = -1 := Real.sign_of_neg (by linarith)
        have hi : z ∉ Set.Ioi c := fun h' => by simp at h'; linarith
        rw [Set.indicator_of_notMem hi, hs, smul_eq_mul]
        ring
      · have hs : Real.sign (z - c) = 1 := Real.sign_of_pos (by linarith)
        have hi : z ∈ Set.Ioi c := h
        rw [Set.indicator_of_mem hi, hs, smul_eq_mul]
        ring
    rw [integral_congr_ae hae, integral_sub ((hint.indicator measurableSet_Ioi).const_mul 2) hint,
      integral_const_mul, integral_indicator measurableSet_Ioi, htail, hmean]
    ring
  · rw [hφ0]
    have hpi : 0 < Real.pi := Real.pi_pos
    have h4 : (2 : ℝ) / Real.pi = 4 / (2 * Real.pi) := by field_simp; ring
    rw [h4, Real.sqrt_div (by norm_num)]
    have : Real.sqrt 4 = 2 := by
      rw [show (4 : ℝ) = 2 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]
    rw [this, div_eq_mul_inv]

-- The mispricing's steady variance, in %^2: 1.2² ÷ (1 - 0.5²) = 1.920.
example : ((12 : ℚ) / 10) ^ 2 / (1 - (1 / 2) ^ 2) = 192 / 100 := by norm_num
-- Years 6-10, shock halved to 0.6: the steady variance falls to a quarter, 0.480.
example : ((6 : ℚ) / 10) ^ 2 / (1 - (1 / 2) ^ 2) = 48 / 100 := by norm_num
-- The covariance γ with the return two days on: -1.920 × 0.5 × 0.5 = -0.480 %^2.
example : -((192 : ℚ) / 100) * (1 / 2) * (1 / 2) = -48 / 100 := by norm_num
-- Look-ahead fills lose one factor of b and double the covariance: -0.960 = 2 × -0.480.
example : -((192 : ℚ) / 100) * (1 / 2) = 2 * (-48 / 100) := by norm_num
-- A failing firm's signal centre: 20 days × (-0.5%) = -10%.
example : (20 : ℚ) * (-5 / 1000) = -1 / 10 := by norm_num
-- Drift part, in bp: 0.5% × (0.9238 - 0.0762) = 42.38 bp, a loss.
example : (5 : ℚ) / 1000 * (9238 / 10000 - 762 / 10000) * 10000 = 4238 / 100 := by norm_num
-- Net for a failing firm: -42.38 + 1.97 = -40.41 bp a day.
example : -(4238 : ℚ) / 100 + 197 / 100 = -4041 / 100 := by norm_num
-- Each flip closes a 1/50 position and opens one: 2/50 of the book traded.
example : (1 : ℚ) / 50 + 1 / 50 = 2 / 50 := by norm_num
-- Costs never charged: 0.2428 of the book a day × 5 bp = 1.214 bp a day.
example : (2428 : ℚ) / 10000 * 5 = 1214 / 1000 := by norm_num

#print axioms phantom_gains_raise_sharpe_by_root_252_over_spread
#print axioms constant_phantom_gain_keeps_spread
#print axioms sign_bet_average_eq_twice_height_at_cut
