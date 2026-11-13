-- Composite option: if the share's and the currency's log returns are jointly normal, the log of the dollar value is normal with the variance of a product, the composite volatility lies between the difference and the sum of the two volatilities, and put-call parity holds on the dollar value.
import Mathlib.Probability.Distributions.Gaussian.HasGaussianLaw.Basic
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Moments.Covariance
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open MeasureTheory ProbabilityTheory

/-- Steps 2 and 3 of the card. Let the share's euro price `ST` and the exchange rate `XT`
(dollars per euro) on expiry day be positive, with their logs jointly normal ("two linked
lognormal walks"), the share's log having variance `σS² T`, the currency's `σX² T`, and their
covariance `ρ σS σX T` (constant volatilities and correlation). Then the log of the dollar value
`V_T = S_T X_T` is normal, with mean the sum of the two means and variance
`(σS² + σX² + 2 ρ σS σX) T = σV² T`: the dollar value is lognormal with the volatility of a
product. -/
theorem log_dollar_value_gaussian_composite_variance
    {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    (ST XT : Ω → ℝ) (σS σX ρ T : ℝ)
    (hS_pos : ∀ ω, 0 < ST ω) (hX_pos : ∀ ω, 0 < XT ω)
    (hjoint : HasGaussianLaw (fun ω ↦ (Real.log (ST ω), Real.log (XT ω))) P)
    (hvarS : Var[fun ω ↦ Real.log (ST ω); P] = σS ^ 2 * T)
    (hvarX : Var[fun ω ↦ Real.log (XT ω); P] = σX ^ 2 * T)
    (hcov : cov[fun ω ↦ Real.log (ST ω), fun ω ↦ Real.log (XT ω); P] = ρ * σS * σX * T) :
    P.map (fun ω ↦ Real.log (ST ω * XT ω)) =
      gaussianReal (P[fun ω ↦ Real.log (ST ω)] + P[fun ω ↦ Real.log (XT ω)])
        ((σS ^ 2 + σX ^ 2 + 2 * ρ * σS * σX) * T).toNNReal := by
  have hP : IsProbabilityMeasure P := hjoint.isProbabilityMeasure
  have hsum : HasGaussianLaw (fun ω ↦ Real.log (ST ω) + Real.log (XT ω)) P := hjoint.fun_add
  have hA := hjoint.fst.memLp_two
  have hB := hjoint.snd.memLp_two
  have heq : (fun ω ↦ Real.log (ST ω * XT ω)) =
      (fun ω ↦ Real.log (ST ω) + Real.log (XT ω)) := by
    funext ω
    exact Real.log_mul (hS_pos ω).ne' (hX_pos ω).ne'
  rw [heq, hsum.map_eq_gaussianReal, integral_add hjoint.fst.integrable hjoint.snd.integrable,
    variance_fun_add hA hB, hvarS, hvarX, hcov]
  congr 2
  ring

/-- The composite volatility is squeezed between the difference and the sum of the two
volatilities: for any correlation `ρ` from −1 to +1, `|σS − σX| ≤ σV ≤ σS + σX`, so
"volatilities added" is right only at `ρ = +1`. -/
theorem composite_vol_between_difference_and_sum
    (σS σX ρ : ℝ) (hσS : 0 ≤ σS) (hσX : 0 ≤ σX) (hρ₁ : -1 ≤ ρ) (hρ₂ : ρ ≤ 1) :
    |σS - σX| ≤ Real.sqrt (σS ^ 2 + σX ^ 2 + 2 * ρ * σS * σX) ∧
      Real.sqrt (σS ^ 2 + σX ^ 2 + 2 * ρ * σS * σX) ≤ σS + σX := by
  have hprod : 0 ≤ σS * σX := mul_nonneg hσS hσX
  constructor
  · apply Real.abs_le_sqrt
    nlinarith
  · rw [Real.sqrt_le_iff]
    constructor
    · positivity
    · nlinarith

/-- Put-call parity on the dollar value. If the dollar value `V_T` on expiry day is integrable
and, in the dollar pricing world, grows at `r_d − q` from today's value `V`
(`E[V_T] = V e^{(r_d − q) T}`), then the composite call `C = e^{−r_d T} E[max(V_T − K, 0)]` and
put `P = e^{−r_d T} E[max(K − V_T, 0)]` satisfy `C − P = V e^{−qT} − K e^{−r_d T}`. -/
theorem composite_put_call_parity
    {Ω : Type*} {mΩ : MeasurableSpace Ω} {Q : Measure Ω} [IsProbabilityMeasure Q]
    (VT : Ω → ℝ) (V K rd q T : ℝ)
    (hint : Integrable VT Q)
    (hgrowth : Q[VT] = V * Real.exp ((rd - q) * T)) :
    Real.exp (-rd * T) * Q[fun ω ↦ max (VT ω - K) 0] -
        Real.exp (-rd * T) * Q[fun ω ↦ max (K - VT ω) 0] =
      V * Real.exp (-q * T) - K * Real.exp (-rd * T) := by
  have h1 : Integrable (fun ω ↦ max (VT ω - K) 0) Q :=
    (hint.sub (integrable_const K)).sup (integrable_const 0)
  have h2 : Integrable (fun ω ↦ max (K - VT ω) 0) Q :=
    ((integrable_const K).sub hint).sup (integrable_const 0)
  have hdiff : (fun ω ↦ max (VT ω - K) 0 - max (K - VT ω) 0) = fun ω ↦ VT ω - K := by
    funext ω
    rcases le_total (VT ω) K with h | h
    · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; ring
    · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; ring
  have hI : Q[fun ω ↦ max (VT ω - K) 0] - Q[fun ω ↦ max (K - VT ω) 0] = Q[VT] - K := by
    rw [← integral_sub h1 h2, hdiff, integral_sub hint (integrable_const K)]
    simp
  have hexp : V * Real.exp ((rd - q) * T) * Real.exp (-rd * T) = V * Real.exp (-q * T) := by
    rw [mul_assoc, ← Real.exp_add]
    congr 2
    ring
  rw [← mul_sub, hI, hgrowth, mul_sub, mul_comm (Real.exp (-rd * T)), hexp,
    mul_comm (Real.exp (-rd * T))]

-- The house example: σS = 20%, σX = 10%, ρ = 0.30. Cross term 0.012, composite variance 0.062.
example : (2 : ℚ) * (3 / 10) * (1 / 5) * (1 / 10) = 12 / 1000 := by norm_num
example : ((1 : ℚ) / 5) ^ 2 + (1 / 10) ^ 2 + 2 * (3 / 10) * (1 / 5) * (1 / 10) = 62 / 1000 := by
  norm_num

-- At ρ = −1 the composite vol is 10%, at ρ = +1 it is 30%, at ρ = −0.25 it is exactly 20%.
example : Real.sqrt ((1 / 5 : ℝ) ^ 2 + (1 / 10) ^ 2 + 2 * (-1) * (1 / 5) * (1 / 10)) = 1 / 10 := by
  rw [show (1 / 5 : ℝ) ^ 2 + (1 / 10) ^ 2 + 2 * (-1) * (1 / 5) * (1 / 10) = (1 / 10) ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)
example : Real.sqrt ((1 / 5 : ℝ) ^ 2 + (1 / 10) ^ 2 + 2 * 1 * (1 / 5) * (1 / 10)) = 3 / 10 := by
  rw [show (1 / 5 : ℝ) ^ 2 + (1 / 10) ^ 2 + 2 * 1 * (1 / 5) * (1 / 10) = (3 / 10) ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)
example : Real.sqrt ((1 / 5 : ℝ) ^ 2 + (1 / 10) ^ 2 + 2 * (-1 / 4) * (1 / 5) * (1 / 10)) = 1 / 5 := by
  rw [show (1 / 5 : ℝ) ^ 2 + (1 / 10) ^ 2 + 2 * (-1 / 4) * (1 / 5) * (1 / 10) = (1 / 5) ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)

-- Today's dollar value: 100 euros at 1.10 dollars per euro is 110 dollars.
example : (100 : ℚ) * (11 / 10) = 110 := by norm_num

-- The four expiry days (strike 110 dollars; quanto and plain strike 100 euros, quanto rate 1.10).
-- Share 120, rate 1.30: dollar value 156, quanto 22, composite 46, plain 26.
example : (120 : ℚ) * (13 / 10) = 156 := by norm_num
example : (11 / 10 : ℚ) * max (120 - 100) 0 = 22 := by norm_num
example : max ((120 : ℚ) * (13 / 10) - 110) 0 = 46 := by norm_num
example : (13 / 10 : ℚ) * max (120 - 100) 0 = 26 := by norm_num
-- Share 120, rate 0.90: dollar value 108, composite 0, plain 18.
example : max ((120 : ℚ) * (9 / 10) - 110) 0 = 0 := by norm_num
example : (9 / 10 : ℚ) * max (120 - 100) 0 = 18 := by norm_num
-- Share 95, rate 1.30: dollar value 123.50, quanto 0, composite 13.50, plain 0.
example : max ((95 : ℚ) * (13 / 10) - 110) 0 = 27 / 2 := by norm_num
example : (11 / 10 : ℚ) * max (95 - 100) 0 = 0 := by norm_num
-- Share 110, rate 1.10: dollar value 121, all three pay 11.
example : max ((110 : ℚ) * (11 / 10) - 110) 0 = 11 := by norm_num
example : (11 / 10 : ℚ) * max (110 - 100) 0 = 11 := by norm_num

#print axioms log_dollar_value_gaussian_composite_variance
#print axioms composite_vol_between_difference_and_sum
#print axioms composite_put_call_parity
