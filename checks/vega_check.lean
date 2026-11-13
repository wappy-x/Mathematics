-- Vega: in the Black–Scholes model the slope of the call price and of the put price against volatility is the same number, S e^(-qT) φ(d1) √T, which equals the cash-side form K e^(-rT) φ(d2) √T and is always positive, so the call price rises with volatility.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open MeasureTheory ProbabilityTheory Real

lemma vega_cdf_eq_integral (x : ℝ) :
    cdf (gaussianReal 0 1) x = ∫ t in Set.Iic x, gaussianPDFReal 0 1 t := by
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Iic
      (fun t _ => gaussianPDFReal_nonneg _ _ t))]

lemma vega_continuous_pdf : Continuous (gaussianPDFReal 0 1) := by
  rw [gaussianPDFReal_def]; fun_prop

lemma vega_cdf_hasDerivAt (z : ℝ) :
    HasDerivAt (cdf (gaussianReal 0 1)) (gaussianPDFReal 0 1 z) z := by
  have hI : ∀ a, IntegrableOn (gaussianPDFReal 0 1) (Set.Iic a) :=
    fun a => (integrable_gaussianPDFReal 0 1).integrableOn
  have hfun : (cdf (gaussianReal 0 1) : ℝ → ℝ) =
      fun x => cdf (gaussianReal 0 1) 0 + ∫ t in (0:ℝ)..x, gaussianPDFReal 0 1 t := by
    funext x
    rw [← intervalIntegral.integral_Iic_sub_Iic (hI 0) (hI x), vega_cdf_eq_integral,
      vega_cdf_eq_integral]
    ring
  rw [hfun]
  exact (intervalIntegral.integral_hasDerivAt_right
    (vega_continuous_pdf.intervalIntegrable _ _)
    (vega_continuous_pdf.stronglyMeasurableAtFilter _ _)
    vega_continuous_pdf.continuousAt).const_add _

lemma vega_pdf_neg (x : ℝ) : gaussianPDFReal 0 1 (-x) = gaussianPDFReal 0 1 x := by
  simp [gaussianPDFReal_def]

lemma vega_share_cash
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

#print axioms vega_cdf_eq_integral
#print axioms vega_continuous_pdf
#print axioms vega_cdf_hasDerivAt
#print axioms vega_pdf_neg
#print axioms vega_share_cash

/-! The model: `N(x)` is Mathlib's `cdf (gaussianReal 0 1) x`, the area under the standard
bell curve to the left of `x`, and `φ(x)` is Mathlib's `gaussianPDFReal 0 1 x`, its height.
Share price `S`, strike `K`, riskless rate `r`, dividend yield `q`, volatility `σ`, years `T`.
`d1 = (log (S / K) + (r - q + σ² / 2) T) / (σ √T)` and `d2 = d1 - σ √T`.
Call `C = S e^(-qT) N(d1) - K e^(-rT) N(d2)`; put `P = K e^(-rT) N(-d2) - S e^(-qT) N(-d1)`.
Vega is the slope of each in `σ`, every other input held still. -/

/-- Vega (the formula, Steps 0 to 4): with a positive share price and strike, positive
volatility and positive time, the Black–Scholes call price, seen as a function of volatility
alone, has slope `S e^(-qT) φ(d1) √T` at `σ`, and the put on the same share, strike and date
has exactly the same slope. -/
theorem call_and_put_vega_eq_share_value_times_bell_height_times_sqrt_time
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt
        (fun s : ℝ =>
          S * exp (-(q * T)) *
              cdf (gaussianReal 0 1) ((log (S / K) + (r - q + s ^ 2 / 2) * T) / (s * √T)) -
            K * exp (-(r * T)) *
              cdf (gaussianReal 0 1)
                ((log (S / K) + (r - q + s ^ 2 / 2) * T) / (s * √T) - s * √T))
        (S * exp (-(q * T)) *
            gaussianPDFReal 0 1 ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)) * √T)
        σ ∧
      HasDerivAt
        (fun s : ℝ =>
          K * exp (-(r * T)) *
              cdf (gaussianReal 0 1)
                (-((log (S / K) + (r - q + s ^ 2 / 2) * T) / (s * √T) - s * √T)) -
            S * exp (-(q * T)) *
              cdf (gaussianReal 0 1) (-((log (S / K) + (r - q + s ^ 2 / 2) * T) / (s * √T))))
        (S * exp (-(q * T)) *
            gaussianPDFReal 0 1 ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)) * √T)
        σ := by
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  set D : ℝ → ℝ := fun s => (log (S / K) + (r - q + s ^ 2 / 2) * T) / (s * √T) with hDdef
  have hDd : DifferentiableAt ℝ D σ := by
    rw [hDdef]
    exact DifferentiableAt.div (by fun_prop) (by fun_prop) (by positivity)
  have hD : HasDerivAt D (deriv D σ) σ := hDd.hasDerivAt
  have hL : HasDerivAt (fun s => s * √T) √T σ := by
    simpa using (hasDerivAt_id σ).mul_const √T
  have hD2 : HasDerivAt (fun s => D s - s * √T) (deriv D σ - √T) σ := hD.sub hL
  have hshare : S * exp (-(q * T)) * gaussianPDFReal 0 1 (D σ) =
      K * exp (-(r * T)) * gaussianPDFReal 0 1 (D σ - σ * √T) :=
    vega_share_cash S K r q σ T hS hK hσ hT
  have hN1 := (vega_cdf_hasDerivAt (D σ)).comp σ hD
  have hN2 := (vega_cdf_hasDerivAt (D σ - σ * √T)).comp σ hD2
  have hN3 := (vega_cdf_hasDerivAt (-(D σ - σ * √T))).comp σ hD2.neg
  have hN4 := (vega_cdf_hasDerivAt (-(D σ))).comp σ hD.neg
  rw [vega_pdf_neg] at hN3 hN4
  constructor
  · have := (hN1.const_mul (S * exp (-(q * T)))).sub (hN2.const_mul (K * exp (-(r * T))))
    convert this using 1
    · rfl
    · show _ = _ - K * exp (-(r * T)) * _
      rw [← mul_assoc (K * exp (-(r * T))), ← hshare]; ring
  · have := (hN3.const_mul (K * exp (-(r * T)))).sub (hN4.const_mul (S * exp (-(q * T))))
    convert this using 1
    · rfl
    · show _ = K * exp (-(r * T)) * _ - _
      rw [← mul_assoc (K * exp (-(r * T))), ← hshare]; ring

/-- The cash-side form (Step 1): with a positive share price and strike, positive volatility
and positive time, the share side and the cash side carry equal weight at the strike,
`S e^(-qT) φ(d1) = K e^(-rT) φ(d2)`, so vega is also `K e^(-rT) φ(d2) √T`. -/
theorem share_side_eq_cash_side
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    S * exp (-(q * T)) *
        gaussianPDFReal 0 1 ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)) =
      K * exp (-(r * T)) *
        gaussianPDFReal 0 1 ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) - σ * √T) := by
  exact vega_share_cash S K r q σ T hS hK hσ hT

/-- Vega is always positive (Step 5): with a positive share price and strike, positive
volatility and positive time, vega is positive, so the call price strictly rises as
volatility rises, and at most one volatility fits a quoted price. -/
theorem vega_pos_and_call_strictly_rises_with_volatility
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    0 < S * exp (-(q * T)) *
          gaussianPDFReal 0 1 ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)) * √T ∧
      StrictMonoOn
        (fun s : ℝ =>
          S * exp (-(q * T)) *
              cdf (gaussianReal 0 1) ((log (S / K) + (r - q + s ^ 2 / 2) * T) / (s * √T)) -
            K * exp (-(r * T)) *
              cdf (gaussianReal 0 1)
                ((log (S / K) + (r - q + s ^ 2 / 2) * T) / (s * √T) - s * √T))
        (Set.Ioi 0) := by
  have hpos : ∀ s : ℝ, 0 < S * exp (-(q * T)) *
      gaussianPDFReal 0 1 ((log (S / K) + (r - q + s ^ 2 / 2) * T) / (s * √T)) * √T := by
    intro s
    have := gaussianPDFReal_pos 0 1 ((log (S / K) + (r - q + s ^ 2 / 2) * T) / (s * √T))
      one_ne_zero
    have hsT : 0 < √T := Real.sqrt_pos.2 hT
    positivity
  refine ⟨hpos σ, ?_⟩
  have hder := fun (s : ℝ) (hs : 0 < s) =>
    (call_and_put_vega_eq_share_value_times_bell_height_times_sqrt_time S K r q s T hS hK hs hT).1
  apply strictMonoOn_of_deriv_pos (convex_Ioi 0)
  · intro x hx
    exact (hder x hx).continuousAt.continuousWithinAt
  · intro x hx
    rw [interior_Ioi] at hx
    rw [(hder x hx).deriv]
    exact hpos x

/-! The card's worked numbers that are exact fractions, for Acme:
S = 100, K = 100, r = 5/100, q = 2/100, σ = 1/5, T = 1. -/

-- The drift term (r - q + σ² / 2) T is 0.05.
example : ((5 : ℚ) / 100 - 2 / 100 + (1 / 5) ^ 2 / 2) * 1 = 1 / 20 := by norm_num

-- d1 = (ln(100/100) + 0.05) / (0.20 × √1) = 0.25.
example :
    (log ((100 : ℝ) / 100) + (5 / 100 - 2 / 100 + (1 / 5) ^ 2 / 2) * 1) / (1 / 5 * √1) =
      1 / 4 := by
  norm_num

-- d2 = d1 - σ √T = 0.25 - 0.20 = 0.05.
example :
    (log ((100 : ℝ) / 100) + (5 / 100 - 2 / 100 + (1 / 5) ^ 2 / 2) * 1) / (1 / 5 * √1) -
        1 / 5 * √1 = 1 / 20 := by
  norm_num

#print axioms call_and_put_vega_eq_share_value_times_bell_height_times_sqrt_time
#print axioms share_side_eq_cash_side
#print axioms vega_pos_and_call_strictly_rises_with_volatility
