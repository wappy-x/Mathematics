-- VIX futures and options: a VIX future is at most 100 times the square root of the forward variance, a lognormal VIX shrinks it by exp(-ω²T/2), and that gap gives back the vol of VIX.
import Mathlib.Analysis.Convex.Integral
import Mathlib.Analysis.Convex.SpecificFunctions.Pow
import Mathlib.Probability.Distributions.Gaussian.Real

open MeasureTheory ProbabilityTheory

lemma integral_exp_mul_std_gaussian (t : ℝ) :
    ∫ z, Real.exp (t * z) ∂(gaussianReal 0 1) = Real.exp (t ^ 2 / 2) := by
  have h := congrFun (mgf_id_gaussianReal (μ := 0) (v := 1)) t
  simp only [mgf, id] at h
  rw [h]; congr 1; push_cast; ring

/-- The ceiling (Jensen for the square root). In the pricing world `P`, let `VIX` be the VIX on the
expiry morning, never negative, with `VIX²` having an average. If the future's price `F` is the
average VIX at expiry, and the average of `VIX²` is `10,000 ξ`, where `ξ = (K₂ (T + τ) - K₁ T) / τ`
is the forward variance for the 30 days after expiry, then the future is at most `100 √ξ`. -/
theorem vix_future_le_sqrt_forward_variance {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] (VIX : Ω → ℝ) (K₁ K₂ T τ F : ℝ)
    (hnonneg : ∀ x, 0 ≤ VIX x)
    (hsq : Integrable (fun x => VIX x ^ 2) P)
    (hF : F = ∫ x, VIX x ∂P)
    (hvar : ∫ x, VIX x ^ 2 ∂P = 10000 * ((K₂ * (T + τ) - K₁ * T) / τ)) :
    F ≤ 100 * Real.sqrt ((K₂ * (T + τ) - K₁ * T) / τ) := by
  set ξ := (K₂ * (T + τ) - K₁ * T) / τ
  have h100 : (100 : ℝ) * Real.sqrt ξ = Real.sqrt (10000 * ξ) := by
    rw [Real.sqrt_mul (by norm_num), show (10000 : ℝ) = 100 ^ 2 by norm_num,
      Real.sqrt_sq (by norm_num)]
  rw [h100]
  by_cases hi : Integrable VIX P
  · have hJ : (∫ x, VIX x ∂P) ^ 2 ≤ ∫ x, VIX x ^ 2 ∂P :=
      (convexOn_pow 2).map_integral_le (continuous_pow 2).continuousOn isClosed_Ici
        (Filter.Eventually.of_forall fun x => hnonneg x) hi hsq
    have hF0 : 0 ≤ F := hF ▸ integral_nonneg hnonneg
    apply Real.le_sqrt_of_sq_le
    rw [← hvar, hF]; exact hJ
  · rw [hF, integral_undef hi]; exact Real.sqrt_nonneg _

/-- The gap under a lognormal VIX. Let `z` be a standard normal draw and
`VIX_T = 100 √ξ · exp(ω √T z - ω² T)`, so that `ln VIX_T` is normal with spread `ω √T`.
Then the average of `VIX_T²` is the forward variance `10,000 ξ`, and the future, the average of
`VIX_T`, is the ceiling `100 √ξ` shrunk by the factor `exp(-ω² T / 2)`. -/
theorem vix_future_lognormal (ξ ω T : ℝ) (hξ : 0 ≤ ξ) (hT : 0 ≤ T) :
    (∫ z, (100 * Real.sqrt ξ * Real.exp (ω * Real.sqrt T * z - ω ^ 2 * T)) ^ 2
        ∂(gaussianReal 0 1) = 10000 * ξ) ∧
    ∫ z, 100 * Real.sqrt ξ * Real.exp (ω * Real.sqrt T * z - ω ^ 2 * T) ∂(gaussianReal 0 1)
      = 100 * Real.sqrt ξ * Real.exp (-(ω ^ 2 * T / 2)) := by
  have hsT : Real.sqrt T ^ 2 = T := Real.sq_sqrt hT
  have hsξ : Real.sqrt ξ ^ 2 = ξ := Real.sq_sqrt hξ
  constructor
  · have hfun : (fun z : ℝ => (100 * Real.sqrt ξ * Real.exp (ω * Real.sqrt T * z - ω ^ 2 * T)) ^ 2)
        = fun z => (10000 * ξ * Real.exp (-(2 * ω ^ 2 * T))) * Real.exp ((2 * ω * Real.sqrt T) * z) := by
      funext z
      rw [mul_pow, mul_pow, ← Real.exp_nat_mul, hsξ, mul_assoc (10000 * ξ), ← Real.exp_add]
      congr 1
      · ring
      · congr 1; push_cast; ring
    rw [hfun, integral_const_mul, integral_exp_mul_std_gaussian, mul_assoc, ← Real.exp_add]
    have : -(2 * ω ^ 2 * T) + (2 * ω * Real.sqrt T) ^ 2 / 2 = 0 := by
      rw [mul_pow, hsT]; ring
    rw [this, Real.exp_zero, mul_one]
  · have hfun : (fun z : ℝ => 100 * Real.sqrt ξ * Real.exp (ω * Real.sqrt T * z - ω ^ 2 * T))
        = fun z => (100 * Real.sqrt ξ * Real.exp (-(ω ^ 2 * T))) * Real.exp ((ω * Real.sqrt T) * z) := by
      funext z
      rw [mul_assoc (100 * Real.sqrt ξ), ← Real.exp_add]
      congr 2; ring
    rw [hfun, integral_const_mul, integral_exp_mul_std_gaussian, mul_assoc, ← Real.exp_add]
    congr 2
    rw [mul_pow, hsT]; ring

/-- The inverse: reading the vol of VIX off the futures gap. If the future is
`F = 100 √ξ · exp(-ω² T / 2)` with a positive forward variance, a positive time to expiry and a
vol of VIX that is not negative, then `ω = √((2 / T) ln(100 √ξ / F))`. -/
theorem vol_of_vix_from_futures_gap (ξ ω T F : ℝ) (hξ : 0 < ξ) (hT : 0 < T) (hω : 0 ≤ ω)
    (hF : F = 100 * Real.sqrt ξ * Real.exp (-(ω ^ 2 * T / 2))) :
    ω = Real.sqrt (2 / T * Real.log (100 * Real.sqrt ξ / F)) := by
  have hA : 0 < 100 * Real.sqrt ξ := by positivity
  have hdiv : 100 * Real.sqrt ξ / F = Real.exp (ω ^ 2 * T / 2) := by
    rw [hF, div_mul_cancel_left₀ hA.ne', Real.exp_neg, inv_inv]
  rw [hdiv, Real.log_exp]
  have : 2 / T * (ω ^ 2 * T / 2) = ω ^ 2 := by field_simp
  rw [this, Real.sqrt_sq hω]

-- Worked numbers: forward variance on the flat surface, K₁ = K₂ = 0.04, T = 1/2, τ = 30/365.
example : ((4 : ℚ) / 100 * (1 / 2 + 30 / 365) - 4 / 100 * (1 / 2)) / (30 / 365) = 4 / 100 := by
  norm_num

-- The ceiling: 100 √0.04 = 20.
example : (100 : ℝ) * Real.sqrt (4 / 100) = 20 := by
  rw [show (4 : ℝ) / 100 = (1 / 5) ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]
  norm_num

-- The exponent: 0.8² × 0.5 / 2 = 0.16.
example : ((4 : ℚ) / 5) ^ 2 * (1 / 2) / 2 = 4 / 25 := by
  norm_num

#print axioms integral_exp_mul_std_gaussian
#print axioms vix_future_le_sqrt_forward_variance
#print axioms vix_future_lognormal
#print axioms vol_of_vix_from_futures_gap
