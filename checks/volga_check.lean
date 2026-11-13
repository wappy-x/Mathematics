-- Volga: in the Black–Scholes model the rate at which vega changes with volatility, for the call and for the put alike, is vega times d1 d2 over σ, where d1 d2 = m²/(σ²T) − σ²T/4 with m = ln(F/K), so volga is positive when |m| exceeds half the variance and negative when it falls short.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open MeasureTheory ProbabilityTheory Real

lemma volga_cdf_eq_integral (x : ℝ) :
    cdf (gaussianReal 0 1) x = ∫ t in Set.Iic x, gaussianPDFReal 0 1 t := by
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Iic
      (fun t _ => gaussianPDFReal_nonneg _ _ t))]

lemma volga_continuous_pdf : Continuous (gaussianPDFReal 0 1) := by
  rw [gaussianPDFReal_def]; fun_prop

lemma volga_cdf_hasDerivAt (z : ℝ) :
    HasDerivAt (cdf (gaussianReal 0 1)) (gaussianPDFReal 0 1 z) z := by
  have hI : ∀ a, IntegrableOn (gaussianPDFReal 0 1) (Set.Iic a) :=
    fun a => (integrable_gaussianPDFReal 0 1).integrableOn
  have hfun : (cdf (gaussianReal 0 1) : ℝ → ℝ) =
      fun x => cdf (gaussianReal 0 1) 0 + ∫ t in (0:ℝ)..x, gaussianPDFReal 0 1 t := by
    funext x
    rw [← intervalIntegral.integral_Iic_sub_Iic (hI 0) (hI x), volga_cdf_eq_integral,
      volga_cdf_eq_integral]
    ring
  rw [hfun]
  exact (intervalIntegral.integral_hasDerivAt_right
    (volga_continuous_pdf.intervalIntegrable _ _)
    (volga_continuous_pdf.stronglyMeasurableAtFilter _ _)
    volga_continuous_pdf.continuousAt).const_add _

lemma volga_pdf_neg (x : ℝ) : gaussianPDFReal 0 1 (-x) = gaussianPDFReal 0 1 x := by
  simp [gaussianPDFReal_def]

lemma volga_pdf_hasDerivAt (x : ℝ) :
    HasDerivAt (gaussianPDFReal 0 1) (-x * gaussianPDFReal 0 1 x) x := by
  have h : (gaussianPDFReal 0 1 : ℝ → ℝ) = fun y => (√(2 * π))⁻¹ * exp (-y ^ 2 / 2) := by
    funext y; simp [gaussianPDFReal_def]
  rw [h]
  have h2 : HasDerivAt (fun y : ℝ => -y ^ 2 / 2) (-x) x := by
    have := ((hasDerivAt_pow 2 x).neg).div_const 2
    convert this using 1; ring
  have := (h2.exp).const_mul (√(2 * π))⁻¹
  convert this using 1; ring

lemma volga_share_cash
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

/-- The derivative of `d1` in volatility is `-d2 / σ`. -/
lemma volga_d1_hasDerivAt
    (S K r q σ T : ℝ) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun s : ℝ => (log (S / K) + (r - q + s ^ 2 / 2) * T) / (s * √T))
      (-((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) - σ * √T) / σ) σ := by
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  have hsq : √T ^ 2 = T := Real.sq_sqrt hT.le
  have hN : HasDerivAt (fun s : ℝ => log (S / K) + (r - q + s ^ 2 / 2) * T) (σ * T) σ := by
    have := (((hasDerivAt_pow 2 σ).div_const 2).const_add (r - q)).mul_const T |>.const_add
      (log (S / K))
    convert this using 1; push_cast; ring
  have hL : HasDerivAt (fun s : ℝ => s * √T) √T σ := by
    simpa using (hasDerivAt_id σ).mul_const √T
  have := hN.div hL (by positivity)
  convert this using 1
  field_simp
  rw [hsq]
  ring

/-- Vega: the slope in volatility of the call and of the put. -/
lemma volga_vega
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
    volga_share_cash S K r q σ T hS hK hσ hT
  have hN1 := (volga_cdf_hasDerivAt (D σ)).comp σ hD
  have hN2 := (volga_cdf_hasDerivAt (D σ - σ * √T)).comp σ hD2
  have hN3 := (volga_cdf_hasDerivAt (-(D σ - σ * √T))).comp σ hD2.neg
  have hN4 := (volga_cdf_hasDerivAt (-(D σ))).comp σ hD.neg
  rw [volga_pdf_neg] at hN3 hN4
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

/-- The slope in volatility of vega itself. -/
lemma volga_vega_hasDerivAt
    (S K r q σ T : ℝ) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt
        (fun s : ℝ => S * exp (-(q * T)) *
            gaussianPDFReal 0 1 ((log (S / K) + (r - q + s ^ 2 / 2) * T) / (s * √T)) * √T)
        (S * exp (-(q * T)) *
            gaussianPDFReal 0 1 ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)) * √T *
          ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)) *
          ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) - σ * √T) / σ)
        σ := by
  have h := (volga_pdf_hasDerivAt
    ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T))).comp σ
      (volga_d1_hasDerivAt S K r q σ T hσ hT)
  have := (h.const_mul (S * exp (-(q * T)))).mul_const √T
  convert this using 1
  simp only [Function.comp_def]
  ring

#print axioms volga_cdf_eq_integral
#print axioms volga_continuous_pdf
#print axioms volga_cdf_hasDerivAt
#print axioms volga_pdf_neg
#print axioms volga_pdf_hasDerivAt
#print axioms volga_share_cash
#print axioms volga_d1_hasDerivAt
#print axioms volga_vega
#print axioms volga_vega_hasDerivAt

/-! The model: `N(x)` is Mathlib's `cdf (gaussianReal 0 1) x`, the area under the standard
bell curve to the left of `x`, and `φ(x)` is Mathlib's `gaussianPDFReal 0 1 x`, its height.
Share price `S`, strike `K`, riskless rate `r`, dividend yield `q`, volatility `σ`, years `T`.
`d1 = (log (S / K) + (r - q + σ² / 2) T) / (σ √T)` and `d2 = d1 - σ √T`.
Call `C = S e^(-qT) N(d1) - K e^(-rT) N(d2)`; put `P = K e^(-rT) N(-d2) - S e^(-qT) N(-d1)`.
Vega `V = S e^(-qT) φ(d1) √T`. The forward is `F = S e^((r - q) T)` and `m = log (F / K)`.
Volga is the slope in `σ` of the slope in `σ`, every other input held still. -/

/-- Volga (the formula, Steps 0 to 3, and the put by parity): with a positive share price and
strike, positive volatility and positive time, the slope in volatility of the call's vega,
that is the call price's second derivative in volatility, is `V d1 d2 / σ` at `σ`; the put on
the same share, strike and date has exactly the same volga. -/
theorem call_and_put_volga_eq_vega_times_d1_d2_div_sigma
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt
        (deriv fun s : ℝ =>
          S * exp (-(q * T)) *
              cdf (gaussianReal 0 1) ((log (S / K) + (r - q + s ^ 2 / 2) * T) / (s * √T)) -
            K * exp (-(r * T)) *
              cdf (gaussianReal 0 1)
                ((log (S / K) + (r - q + s ^ 2 / 2) * T) / (s * √T) - s * √T))
        (S * exp (-(q * T)) *
            gaussianPDFReal 0 1 ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)) * √T *
          ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)) *
          ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) - σ * √T) / σ)
        σ ∧
      HasDerivAt
        (deriv fun s : ℝ =>
          K * exp (-(r * T)) *
              cdf (gaussianReal 0 1)
                (-((log (S / K) + (r - q + s ^ 2 / 2) * T) / (s * √T) - s * √T)) -
            S * exp (-(q * T)) *
              cdf (gaussianReal 0 1) (-((log (S / K) + (r - q + s ^ 2 / 2) * T) / (s * √T))))
        (S * exp (-(q * T)) *
            gaussianPDFReal 0 1 ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)) * √T *
          ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)) *
          ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) - σ * √T) / σ)
        σ := by
  have hV := volga_vega_hasDerivAt S K r q σ T hσ hT
  constructor
  · refine hV.congr_of_eventuallyEq ?_
    filter_upwards [lt_mem_nhds hσ] with s hs
    exact (volga_vega S K r q s T hS hK hs hT).1.deriv
  · refine hV.congr_of_eventuallyEq ?_
    filter_upwards [lt_mem_nhds hσ] with s hs
    exact (volga_vega S K r q s T hS hK hs hT).2.deriv

/-- The second form (Step 4): with a positive share price and strike, positive volatility and
positive time, the product of the two distances is the squared distance from the forward in
spread units minus a quarter of the variance, `d1 d2 = m² / (σ² T) - σ² T / 4`,
with `m = log (F / K)` and `F = S e^((r - q) T)`. -/
theorem d1_mul_d2_eq_sq_log_forward_div_variance_sub_quarter_variance
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    (log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) *
        ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) - σ * √T) =
      log (S * exp ((r - q) * T) / K) ^ 2 / (σ ^ 2 * T) - σ ^ 2 * T / 4 := by
  obtain ⟨t, ht, rfl⟩ : ∃ t, 0 < t ∧ T = t ^ 2 :=
    ⟨√T, Real.sqrt_pos.2 hT, (Real.sq_sqrt hT.le).symm⟩
  have hm : log (S * exp ((r - q) * t ^ 2) / K) = log (S / K) + (r - q) * t ^ 2 := by
    rw [mul_div_right_comm, log_mul (by positivity) (exp_pos _).ne', log_exp]
  rw [hm, Real.sqrt_sq ht.le]
  field_simp
  ring

/-- The sign of volga (Step 4): with a positive share price and strike, positive volatility
and positive time, the call's volga, the second derivative of its price in volatility, is
positive exactly when the strike sits further than half the variance from the forward in log
terms, `|log (F / K)| > σ² T / 2`, and negative exactly when it sits strictly closer. -/
theorem volga_pos_iff_far_from_forward_and_neg_iff_near
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    (0 < deriv (deriv fun s : ℝ =>
          S * exp (-(q * T)) *
              cdf (gaussianReal 0 1) ((log (S / K) + (r - q + s ^ 2 / 2) * T) / (s * √T)) -
            K * exp (-(r * T)) *
              cdf (gaussianReal 0 1)
                ((log (S / K) + (r - q + s ^ 2 / 2) * T) / (s * √T) - s * √T)) σ ↔
        σ ^ 2 * T / 2 < |log (S * exp ((r - q) * T) / K)|) ∧
      (deriv (deriv fun s : ℝ =>
          S * exp (-(q * T)) *
              cdf (gaussianReal 0 1) ((log (S / K) + (r - q + s ^ 2 / 2) * T) / (s * √T)) -
            K * exp (-(r * T)) *
              cdf (gaussianReal 0 1)
                ((log (S / K) + (r - q + s ^ 2 / 2) * T) / (s * √T) - s * √T)) σ < 0 ↔
        |log (S * exp ((r - q) * T) / K)| < σ ^ 2 * T / 2) := by
  have h1 := (call_and_put_volga_eq_vega_times_d1_d2_div_sigma S K r q σ T hS hK hσ hT).1.deriv
  have h2 := d1_mul_d2_eq_sq_log_forward_div_variance_sub_quarter_variance S K r q σ T hS hK hσ hT
  rw [h1]
  set m := log (S * exp ((r - q) * T) / K)
  set d1 := (log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  have hφ : 0 < gaussianPDFReal 0 1 d1 := gaussianPDFReal_pos 0 1 d1 one_ne_zero
  have hc : 0 < S * exp (-(q * T)) * gaussianPDFReal 0 1 d1 * √T / σ := by positivity
  have he : S * exp (-(q * T)) * gaussianPDFReal 0 1 d1 * √T * d1 * (d1 - σ * √T) / σ =
      S * exp (-(q * T)) * gaussianPDFReal 0 1 d1 * √T / σ * (d1 * (d1 - σ * √T)) := by ring
  rw [he, h2]
  have hv : 0 < σ ^ 2 * T := by positivity
  have hsplit : m ^ 2 / (σ ^ 2 * T) - σ ^ 2 * T / 4 = (m ^ 2 - (σ ^ 2 * T / 2) ^ 2) / (σ ^ 2 * T) := by
    field_simp; ring
  have habs : |σ ^ 2 * T / 2| = σ ^ 2 * T / 2 := abs_of_pos (by positivity)
  rw [hsplit]
  constructor
  · rw [mul_pos_iff_of_pos_left hc, div_pos_iff_of_pos_right hv, sub_pos, sq_lt_sq, habs]
  · rw [← neg_pos, ← mul_neg, mul_pos_iff_of_pos_left hc, neg_pos, ← neg_pos,
      ← neg_div, div_pos_iff_of_pos_right hv, neg_pos, sub_neg, sq_lt_sq, habs]

/-! The card's worked numbers that are exact fractions, for Acme's house option:
S = 100, K = 100, r = 5/100, q = 2/100, σ = 1/5, T = 1. -/

-- d1 = (ln(100/100) + 0.05) / (0.20 × √1) = 0.25.
example :
    (log ((100 : ℝ) / 100) + (5 / 100 - 2 / 100 + (1 / 5) ^ 2 / 2) * 1) / (1 / 5 * √1) =
      1 / 4 := by
  norm_num

-- d1 d2 = 0.25 × 0.05 = 0.0125.
example :
    (log ((100 : ℝ) / 100) + (5 / 100 - 2 / 100 + (1 / 5) ^ 2 / 2) * 1) / (1 / 5 * √1) *
        ((log ((100 : ℝ) / 100) + (5 / 100 - 2 / 100 + (1 / 5) ^ 2 / 2) * 1) / (1 / 5 * √1) -
          1 / 5 * √1) = 1 / 80 := by
  norm_num

-- m = ln(F / K) = ln(100 e^0.03 / 100) = 0.03.
example : log ((100 : ℝ) * exp ((5 / 100 - 2 / 100) * 1) / 100) = 3 / 100 := by
  norm_num

-- Sign check: m = 0.03 beats half the variance, (0.20² × 1) / 2 = 0.02, so volga is positive.
example : (1 / 5 : ℚ) ^ 2 * 1 / 2 = 1 / 50 ∧ (1 / 50 : ℚ) < 3 / 100 := by norm_num

-- The second form gives the same product: 0.03² / 0.04 - 0.04 / 4 = 0.0225 - 0.01 = 0.0125.
example : (3 / 100 : ℚ) ^ 2 / ((1 / 5) ^ 2 * 1) - (1 / 5) ^ 2 * 1 / 4 = 1 / 80 := by norm_num

#print axioms call_and_put_volga_eq_vega_times_d1_d2_div_sigma
#print axioms d1_mul_d2_eq_sq_log_forward_div_variance_sub_quarter_variance
#print axioms volga_pos_iff_far_from_forward_and_neg_iff_near
