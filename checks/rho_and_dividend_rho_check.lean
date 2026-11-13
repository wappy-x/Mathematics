-- Rho and dividend rho: in the Black–Scholes model the slope of the call price in the bank rate is T K e^(-rT) N(d2) and its slope in the dividend yield is -T S e^(-qT) N(d1), with the put and the move-both-rates-together slopes following.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open MeasureTheory ProbabilityTheory Real

lemma rho_cdf_eq_integral (x : ℝ) :
    cdf (gaussianReal 0 1) x = ∫ t in Set.Iic x, gaussianPDFReal 0 1 t := by
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Iic
      (fun t _ => gaussianPDFReal_nonneg _ _ t))]

lemma rho_continuous_pdf : Continuous (gaussianPDFReal 0 1) := by
  rw [gaussianPDFReal_def]; fun_prop

lemma rho_cdf_hasDerivAt (z : ℝ) :
    HasDerivAt (cdf (gaussianReal 0 1)) (gaussianPDFReal 0 1 z) z := by
  have hI : ∀ a, IntegrableOn (gaussianPDFReal 0 1) (Set.Iic a) :=
    fun a => (integrable_gaussianPDFReal 0 1).integrableOn
  have hfun : (cdf (gaussianReal 0 1) : ℝ → ℝ) =
      fun x => cdf (gaussianReal 0 1) 0 + ∫ t in (0:ℝ)..x, gaussianPDFReal 0 1 t := by
    funext x
    rw [← intervalIntegral.integral_Iic_sub_Iic (hI 0) (hI x), rho_cdf_eq_integral,
      rho_cdf_eq_integral]
    ring
  rw [hfun]
  exact (intervalIntegral.integral_hasDerivAt_right
    (rho_continuous_pdf.intervalIntegrable _ _)
    (rho_continuous_pdf.stronglyMeasurableAtFilter _ _)
    rho_continuous_pdf.continuousAt).const_add _

lemma rho_pdf_neg (x : ℝ) : gaussianPDFReal 0 1 (-x) = gaussianPDFReal 0 1 x := by
  simp [gaussianPDFReal_def]

lemma rho_share_cash
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    S * exp (-(q * T)) *
        gaussianPDFReal 0 1 ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)) =
      K * exp (-(r * T)) *
        gaussianPDFReal 0 1 ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) - σ * √T) := by
  set d := (log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) with hd
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  have hsq : √T ^ 2 = T := Real.sq_sqrt hT.le
  have key : d * (σ * √T) = log S - log K + (r - q + σ ^ 2 / 2) * T := by
    rw [hd, div_mul_cancel₀ _ (by positivity), Real.log_div hS.ne' hK.ne']
  simp only [gaussianPDFReal_def, NNReal.coe_one, sub_zero, mul_one]
  have h : log S + -(q * T) + -d ^ 2 / 2 = log K + -(r * T) + -(d - σ * √T) ^ 2 / 2 := by
    linear_combination (-1 : ℝ) * key + (σ ^ 2 / 2) * hsq
  have e1 : S * exp (-(q * T)) * ((√(2 * π))⁻¹ * exp (-d ^ 2 / 2)) =
      (√(2 * π))⁻¹ * exp (log S + -(q * T) + -d ^ 2 / 2) := by
    rw [exp_add, exp_add, exp_log hS]; ring
  have e2 : K * exp (-(r * T)) * ((√(2 * π))⁻¹ * exp (-(d - σ * √T) ^ 2 / 2)) =
      (√(2 * π))⁻¹ * exp (log K + -(r * T) + -(d - σ * √T) ^ 2 / 2) := by
    rw [exp_add, exp_add, exp_log hK]; ring
  rw [e1, e2, h]

/-- The distance `d1`, seen as a function of the bank rate, has slope `T / (σ √T)`. -/
lemma rho_d_hasDerivAt_r (S K q σ T r : ℝ) :
    HasDerivAt (fun x : ℝ => (log (S / K) + (x - q + σ ^ 2 / 2) * T) / (σ * √T))
      (T / (σ * √T)) r := by
  have := ((((hasDerivAt_id r).sub_const q).add_const (σ ^ 2 / 2)).mul_const T).const_add
    (log (S / K)) |>.div_const (σ * √T)
  exact this.congr_deriv (by ring)

/-- The distance `d1`, seen as a function of the dividend yield, has slope `-T / (σ √T)`. -/
lemma rho_d_hasDerivAt_q (S K r σ T q : ℝ) :
    HasDerivAt (fun y : ℝ => (log (S / K) + (r - y + σ ^ 2 / 2) * T) / (σ * √T))
      (-T / (σ * √T)) q := by
  have := ((((hasDerivAt_id q).const_sub r).add_const (σ ^ 2 / 2)).mul_const T).const_add
    (log (S / K)) |>.div_const (σ * √T)
  exact this.congr_deriv (by ring)

/-- The discount factor `e^(-xT)` has slope `-T e^(-xT)`. -/
lemma rho_exp_hasDerivAt (T x : ℝ) :
    HasDerivAt (fun y : ℝ => exp (-(y * T))) (exp (-(x * T)) * -T) x := by
  simpa using ((hasDerivAt_id x).mul_const T).neg.exp

#print axioms rho_cdf_eq_integral
#print axioms rho_continuous_pdf
#print axioms rho_cdf_hasDerivAt
#print axioms rho_pdf_neg
#print axioms rho_share_cash
#print axioms rho_d_hasDerivAt_r
#print axioms rho_d_hasDerivAt_q
#print axioms rho_exp_hasDerivAt

/-! The model: `N(x)` is Mathlib's `cdf (gaussianReal 0 1) x`, the area under the standard
bell curve to the left of `x`. Share price `S`, strike `K`, bank rate `r`, dividend yield `q`,
volatility `σ`, years `T`.
`d1 = (log (S / K) + (r - q + σ² / 2) T) / (σ √T)` and `d2 = d1 - σ √T`.
Call `C = S e^(-qT) N(d1) - K e^(-rT) N(d2)`; put `P = K e^(-rT) N(-d2) - S e^(-qT) N(-d1)`.
Rho is the slope in `r`, dividend rho the slope in `q`, every other input held still. -/

/-- Rho and dividend rho (the card's main claim, Steps 0 to 4): with a positive share price
and strike, positive volatility and positive time, the Black–Scholes call price, seen as a
function of the bank rate alone, has slope `T K e^(-rT) N(d2)` (time times the cash half),
and, seen as a function of the dividend yield alone, has slope `-T S e^(-qT) N(d1)`
(minus time times the share half). -/
theorem call_rho_eq_time_times_cash_half_and_dividend_rho_eq_neg_time_times_share_half
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt
        (fun x : ℝ =>
          S * exp (-(q * T)) *
              cdf (gaussianReal 0 1) ((log (S / K) + (x - q + σ ^ 2 / 2) * T) / (σ * √T)) -
            K * exp (-(x * T)) *
              cdf (gaussianReal 0 1)
                ((log (S / K) + (x - q + σ ^ 2 / 2) * T) / (σ * √T) - σ * √T))
        (T * (K * exp (-(r * T)) *
            cdf (gaussianReal 0 1)
              ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) - σ * √T)))
        r ∧
      HasDerivAt
        (fun y : ℝ =>
          S * exp (-(y * T)) *
              cdf (gaussianReal 0 1) ((log (S / K) + (r - y + σ ^ 2 / 2) * T) / (σ * √T)) -
            K * exp (-(r * T)) *
              cdf (gaussianReal 0 1)
                ((log (S / K) + (r - y + σ ^ 2 / 2) * T) / (σ * √T) - σ * √T))
        (-(T * (S * exp (-(q * T)) *
            cdf (gaussianReal 0 1) ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)))))
        q := by
  have hshare := rho_share_cash S K r q σ T hS hK hσ hT
  constructor
  · have hD := rho_d_hasDerivAt_r S K q σ T r
    have hD2 := hD.sub_const (σ * √T)
    have hN1 := (rho_cdf_hasDerivAt
      ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T))).comp r hD
    have hN2 := (rho_cdf_hasDerivAt
      ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) - σ * √T)).comp r hD2
    have := (hN1.const_mul (S * exp (-(q * T)))).sub
      (((rho_exp_hasDerivAt T r).const_mul K).mul hN2)
    refine this.congr_deriv ?_
    simp only [Function.comp_apply]
    linear_combination (T / (σ * √T)) * hshare
  · have hD := rho_d_hasDerivAt_q S K r σ T q
    have hD2 := hD.sub_const (σ * √T)
    have hN1 := (rho_cdf_hasDerivAt
      ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T))).comp q hD
    have hN2 := (rho_cdf_hasDerivAt
      ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) - σ * √T)).comp q hD2
    have := (((rho_exp_hasDerivAt T q).const_mul S).mul hN1).sub
      (hN2.const_mul (K * exp (-(r * T))))
    refine this.congr_deriv ?_
    simp only [Function.comp_apply]
    linear_combination (-(T / (σ * √T))) * hshare

/-- The put (the formula and Step 5): with a positive share price and strike, positive
volatility and positive time, the Black–Scholes put price has slope `-T K e^(-rT) N(-d2)`
in the bank rate and slope `T S e^(-qT) N(-d1)` in the dividend yield. -/
theorem put_rho_and_put_dividend_rho
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt
        (fun x : ℝ =>
          K * exp (-(x * T)) *
              cdf (gaussianReal 0 1)
                (-((log (S / K) + (x - q + σ ^ 2 / 2) * T) / (σ * √T) - σ * √T)) -
            S * exp (-(q * T)) *
              cdf (gaussianReal 0 1) (-((log (S / K) + (x - q + σ ^ 2 / 2) * T) / (σ * √T))))
        (-(T * (K * exp (-(r * T)) *
            cdf (gaussianReal 0 1)
              (-((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) - σ * √T)))))
        r ∧
      HasDerivAt
        (fun y : ℝ =>
          K * exp (-(r * T)) *
              cdf (gaussianReal 0 1)
                (-((log (S / K) + (r - y + σ ^ 2 / 2) * T) / (σ * √T) - σ * √T)) -
            S * exp (-(y * T)) *
              cdf (gaussianReal 0 1) (-((log (S / K) + (r - y + σ ^ 2 / 2) * T) / (σ * √T))))
        (T * (S * exp (-(q * T)) *
            cdf (gaussianReal 0 1) (-((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)))))
        q := by
  have hshare := rho_share_cash S K r q σ T hS hK hσ hT
  constructor
  · have hD := rho_d_hasDerivAt_r S K q σ T r
    have hD2 := hD.sub_const (σ * √T)
    have hN3 := (rho_cdf_hasDerivAt
      (-((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) - σ * √T))).comp r hD2.neg
    have hN4 := (rho_cdf_hasDerivAt
      (-((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)))).comp r hD.neg
    rw [rho_pdf_neg] at hN3 hN4
    have := (((rho_exp_hasDerivAt T r).const_mul K).mul hN3).sub
      (hN4.const_mul (S * exp (-(q * T))))
    refine this.congr_deriv ?_
    simp only [Function.comp_apply]
    linear_combination (T / (σ * √T)) * hshare
  · have hD := rho_d_hasDerivAt_q S K r σ T q
    have hD2 := hD.sub_const (σ * √T)
    have hN3 := (rho_cdf_hasDerivAt
      (-((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) - σ * √T))).comp q hD2.neg
    have hN4 := (rho_cdf_hasDerivAt
      (-((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)))).comp q hD.neg
    rw [rho_pdf_neg] at hN3 hN4
    have := (hN3.const_mul (K * exp (-(r * T)))).sub
      (((rho_exp_hasDerivAt T q).const_mul S).mul hN4)
    refine this.congr_deriv ?_
    simp only [Function.comp_apply]
    linear_combination (-(T / (σ * √T))) * hshare

/-- Move both rates together (Step 6): with a positive share price and strike, positive
volatility and positive time, raising the bank rate and the dividend yield by the same step
`h` changes the call price at the slope `-T C`: minus the time to expiry times the call's
own price. -/
theorem call_slope_when_both_rates_move_together_eq_neg_time_times_price
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt
        (fun h : ℝ =>
          S * exp (-((q + h) * T)) *
              cdf (gaussianReal 0 1)
                ((log (S / K) + ((r + h) - (q + h) + σ ^ 2 / 2) * T) / (σ * √T)) -
            K * exp (-((r + h) * T)) *
              cdf (gaussianReal 0 1)
                ((log (S / K) + ((r + h) - (q + h) + σ ^ 2 / 2) * T) / (σ * √T) - σ * √T))
        (-(T * (S * exp (-(q * T)) *
              cdf (gaussianReal 0 1) ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)) -
            K * exp (-(r * T)) *
              cdf (gaussianReal 0 1)
                ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) - σ * √T))))
        0 := by
  have hc : ∀ h : ℝ, (log (S / K) + ((r + h) - (q + h) + σ ^ 2 / 2) * T) / (σ * √T) =
      (log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) := fun h => by ring
  have hD : HasDerivAt
      (fun h : ℝ => (log (S / K) + ((r + h) - (q + h) + σ ^ 2 / 2) * T) / (σ * √T)) 0 0 := by
    simp only [hc]; exact hasDerivAt_const _ _
  have hD2 := hD.sub_const (σ * √T)
  have hEq : HasDerivAt (fun h : ℝ => exp (-((q + h) * T))) (exp (-(q * T)) * -T) 0 := by
    simpa using (((hasDerivAt_id (0 : ℝ)).const_add q).mul_const T).neg.exp
  have hEr : HasDerivAt (fun h : ℝ => exp (-((r + h) * T))) (exp (-(r * T)) * -T) 0 := by
    simpa using (((hasDerivAt_id (0 : ℝ)).const_add r).mul_const T).neg.exp
  have hN1 := (rho_cdf_hasDerivAt
    ((log (S / K) + ((r + 0) - (q + 0) + σ ^ 2 / 2) * T) / (σ * √T))).comp (0 : ℝ) hD
  have hN2 := (rho_cdf_hasDerivAt
    ((log (S / K) + ((r + 0) - (q + 0) + σ ^ 2 / 2) * T) / (σ * √T) - σ * √T)).comp (0 : ℝ)
      hD2
  have := ((hEq.const_mul S).mul hN1).sub ((hEr.const_mul K).mul hN2)
  refine this.congr_deriv ?_
  simp only [Function.comp_apply, add_zero, mul_zero]
  ring

/-! The card's worked numbers that are exact fractions, for Acme:
S = 100, K = 100, r = 5/100, q = 2/100, σ = 1/5, T = 1. -/

-- d1 = (ln(100/100) + (0.05 - 0.02 + 0.02) × 1) / (0.20 × √1) = 0.25.
example :
    (log ((100 : ℝ) / 100) + (5 / 100 - 2 / 100 + (1 / 5) ^ 2 / 2) * 1) / (1 / 5 * √1) =
      1 / 4 := by
  norm_num

-- d2 = d1 - σ √T = 0.25 - 0.20 = 0.05.
example :
    (log ((100 : ℝ) / 100) + (5 / 100 - 2 / 100 + (1 / 5) ^ 2 / 2) * 1) / (1 / 5 * √1) -
        1 / 5 * √1 = 1 / 20 := by
  norm_num

-- Step 1: both distances move by T / (σ √T) = √T / σ = 1 / 0.20 = 5 per unit of rate.
example : (1 : ℝ) / (1 / 5 * √1) = 5 := by norm_num

#print axioms call_rho_eq_time_times_cash_half_and_dividend_rho_eq_neg_time_times_share_half
#print axioms put_rho_and_put_dividend_rho
#print axioms call_slope_when_both_rates_move_together_eq_neg_time_times_price
