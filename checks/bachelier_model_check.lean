-- Bachelier: if the level on expiry day is today's forward plus a normal draw of width σN√T, the discounted call and put premiums are given by the Bachelier formula, and call minus put is the discounted head start.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral

open MeasureTheory ProbabilityTheory

/-! The model: `Z` is a standard bell-curve draw, the measure `gaussianReal 0 1`.
The level on expiry day is `F_T = F + σN * √T * Z`, with no floor and no logarithm.
`N(x)` is Mathlib's `cdf (gaussianReal 0 1) x`, the area to the left of `x`.
`φ(x)` is Mathlib's `gaussianPDFReal 0 1 x`, the height at `x`.
The head start is `m = F - K`, one standard deviation is `s = σN * √T`, `d = m / s`,
and the discount factor is `D = exp (-(r * T))`.
`F` and `K` are any real numbers, negative ones included. -/

section BachelierHelpers
open Filter Topology Set

theorem bach_pdf_eq (z : ℝ) :
    gaussianPDFReal 0 1 z = (Real.sqrt (2 * Real.pi))⁻¹ * Real.exp (-(1/2) * z ^ 2) := by
  simp only [gaussianPDFReal, NNReal.coe_one, mul_one, sub_zero]
  congr 2
  ring

theorem bach_pdf_neg (z : ℝ) : gaussianPDFReal 0 1 (-z) = gaussianPDFReal 0 1 z := by
  rw [bach_pdf_eq, bach_pdf_eq, neg_sq]

theorem bach_cdf_neg (d : ℝ) :
    cdf (gaussianReal 0 1) (-d) = 1 - cdf (gaussianReal 0 1) d := by
  have hmap : (gaussianReal 0 1).map (fun x : ℝ ↦ -x) = gaussianReal 0 1 := by
    rw [gaussianReal_map_neg, neg_zero]
  rw [cdf_eq_real, cdf_eq_real]
  have h1 : (gaussianReal 0 1).real (Iic (-d)) = (gaussianReal 0 1).real (Ici d) := by
    conv_lhs => rw [← hmap]
    rw [map_measureReal_apply (by fun_prop) measurableSet_Iic]
    congr 1
    ext x; simp
  rw [h1]
  have h2 : (gaussianReal 0 1).real (Ici d) = (gaussianReal 0 1).real (Ioi d) := by
    have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
    rw [measureReal_def, measureReal_def,
      measure_congr (Ioi_ae_eq_Ici (μ := gaussianReal 0 1) (a := d))]
  rw [h2, ← compl_Iic, measureReal_compl measurableSet_Iic, probReal_univ]

theorem bach_integrableOn_mul_pdf (a : ℝ) :
    IntegrableOn (fun z ↦ z * gaussianPDFReal 0 1 z) (Ioi a) := by
  have h := (integrable_mul_exp_neg_mul_sq (b := 1/2) (by norm_num)).const_mul
    (Real.sqrt (2 * Real.pi))⁻¹
  refine (h.congr (ae_of_all _ fun z ↦ ?_)).integrableOn
  simp only [bach_pdf_eq]
  ring

theorem bach_integral_Ioi_pdf (a : ℝ) :
    ∫ z in Ioi a, gaussianPDFReal 0 1 z = cdf (gaussianReal 0 1) (-a) := by
  have h := gaussianReal_apply_eq_integral 0 (v := 1) one_ne_zero (Ioi a)
  have hnn : 0 ≤ ∫ z in Ioi a, gaussianPDFReal 0 1 z :=
    setIntegral_nonneg measurableSet_Ioi fun z _ ↦ gaussianPDFReal_nonneg _ _ _
  have h2 : (gaussianReal 0 1).real (Ioi a) = ∫ z in Ioi a, gaussianPDFReal 0 1 z := by
    rw [measureReal_def, h, ENNReal.toReal_ofReal hnn]
  rw [← h2, ← compl_Iic, measureReal_compl measurableSet_Iic, probReal_univ, ← cdf_eq_real,
    bach_cdf_neg]

theorem bach_integral_Ioi_mul_pdf (a : ℝ) :
    ∫ z in Ioi a, z * gaussianPDFReal 0 1 z = gaussianPDFReal 0 1 a := by
  have hf : (fun z ↦ -gaussianPDFReal 0 1 z) =
      fun z ↦ -((Real.sqrt (2 * Real.pi))⁻¹ * Real.exp (-(1/2) * z ^ 2)) := by
    funext z; rw [bach_pdf_eq]
  have key := integral_Ioi_of_hasDerivAt_of_tendsto (a := a) (m := 0)
    (f := fun z ↦ -gaussianPDFReal 0 1 z) (f' := fun z ↦ z * gaussianPDFReal 0 1 z)
    ?_ ?_ (bach_integrableOn_mul_pdf a) ?_
  · rw [key]; ring
  · rw [hf]; exact (by fun_prop : Continuous _).continuousWithinAt
  · intro z _
    rw [hf, bach_pdf_eq]
    have h1 := (((hasDerivAt_pow 2 z).const_mul (-(1/2 : ℝ))).exp).const_mul
      (Real.sqrt (2 * Real.pi))⁻¹
    convert h1.neg using 1
    push_cast
    ring
  · rw [hf]
    have h0 : Tendsto (fun z : ℝ ↦ -(1/2) * z ^ 2) atTop atBot := by
      apply Tendsto.const_mul_atTop_of_neg (by norm_num)
      exact tendsto_pow_atTop two_ne_zero
    have h1 := (Real.tendsto_exp_atBot.comp h0).const_mul (Real.sqrt (2 * Real.pi))⁻¹
    have h2 := h1.neg
    simpa using h2

theorem bach_call_core (m s : ℝ) (hs : 0 < s) :
    ∫ z, max (m + s * z) 0 ∂(gaussianReal 0 1) =
      m * cdf (gaussianReal 0 1) (m / s) + s * gaussianPDFReal 0 1 (m / s) := by
  rw [integral_gaussianReal_eq_integral_smul one_ne_zero]
  have hind : (fun z ↦ gaussianPDFReal 0 1 z • max (m + s * z) 0) =
      (Ioi (-(m / s))).indicator
        (fun z ↦ m * gaussianPDFReal 0 1 z + s * (z * gaussianPDFReal 0 1 z)) := by
    funext z
    have hms : m + s * z = s * (m / s + z) := by field_simp
    simp only [smul_eq_mul, indicator, mem_Ioi]
    split_ifs with h
    · rw [max_eq_left]
      · ring
      · rw [hms]; exact mul_nonneg hs.le (by linarith)
    · rw [max_eq_right, mul_zero]
      rw [hms]; exact mul_nonpos_of_nonneg_of_nonpos hs.le (by linarith)
  rw [hind, integral_indicator measurableSet_Ioi, integral_add, integral_const_mul,
    integral_const_mul, bach_integral_Ioi_pdf, bach_integral_Ioi_mul_pdf, neg_neg, bach_pdf_neg]
  · exact ((integrable_gaussianPDFReal 0 1).integrableOn).const_mul m
  · exact (bach_integrableOn_mul_pdf _).const_mul s

#print axioms bach_pdf_eq
#print axioms bach_pdf_neg
#print axioms bach_cdf_neg
#print axioms bach_integrableOn_mul_pdf
#print axioms bach_integral_Ioi_pdf
#print axioms bach_integral_Ioi_mul_pdf
#print axioms bach_call_core

theorem bach_parity_core (F K c : ℝ) :
    ∫ z, max (F + c * z - K) 0 ∂(gaussianReal 0 1) -
      ∫ z, max (K - (F + c * z)) 0 ∂(gaussianReal 0 1) = F - K := by
  have hid : Integrable (fun z : ℝ ↦ z) (gaussianReal 0 1) :=
    (memLp_id_gaussianReal (μ := 0) (v := 1) 1).integrable le_rfl
  have hlin : Integrable (fun z ↦ F + c * z) (gaussianReal 0 1) :=
    (integrable_const F).add (hid.const_mul _)
  have hint : Integrable (fun z ↦ F + c * z - K) (gaussianReal 0 1) :=
    hlin.sub (integrable_const K)
  have h2 : Integrable (fun z ↦ max (K - (F + c * z)) 0) (gaussianReal 0 1) := by
    refine hint.neg.pos_part.congr (ae_of_all _ fun z ↦ ?_)
    simp only [Pi.neg_apply, neg_sub]
  rw [← integral_sub hint.pos_part h2]
  have h3 : (fun z ↦ max (F + c * z - K) 0 - max (K - (F + c * z)) 0)
      = fun z ↦ (F + c * z) - K := by
    funext z
    rw [← neg_sub (F + c * z) K, max_zero_sub_max_neg_zero_eq_self]
  have h4 : ∫ z, (F + c * z) ∂(gaussianReal 0 1) = F := by
    rw [integral_add (integrable_const F) (hid.const_mul _), integral_const_mul,
      integral_id_gaussianReal]
    simp
  rw [h3, integral_sub hlin (integrable_const K), h4]
  simp

#print axioms bach_parity_core

end BachelierHelpers

/-- Bachelier's call formula: with the level on expiry day equal to `F + σN √T Z`
for a standard bell-curve draw `Z`, positive normal volatility `σN` and a positive wait `T`,
the discounted average of `max (F_T - K) 0` is `D * (m * N(d) + s * φ(d))`. -/
theorem bachelier_call_formula (F K r σN T : ℝ) (hσ : 0 < σN) (hT : 0 < T) :
    Real.exp (-(r * T)) *
        ∫ z, max (F + σN * Real.sqrt T * z - K) 0 ∂(gaussianReal 0 1) =
      Real.exp (-(r * T)) *
        ((F - K) * cdf (gaussianReal 0 1) ((F - K) / (σN * Real.sqrt T)) +
          σN * Real.sqrt T * gaussianPDFReal 0 1 ((F - K) / (σN * Real.sqrt T))) := by
  have hs : 0 < σN * Real.sqrt T := mul_pos hσ (Real.sqrt_pos.mpr hT)
  congr 1
  rw [← bach_call_core (F - K) (σN * Real.sqrt T) hs]
  congr 1
  funext z
  congr 1
  ring

/-- Bachelier's put formula: under the same model, the discounted average of
`max (K - F_T) 0` is `D * (-m * N(-d) + s * φ(d))`. -/
theorem bachelier_put_formula (F K r σN T : ℝ) (hσ : 0 < σN) (hT : 0 < T) :
    Real.exp (-(r * T)) *
        ∫ z, max (K - (F + σN * Real.sqrt T * z)) 0 ∂(gaussianReal 0 1) =
      Real.exp (-(r * T)) *
        (-(F - K) * cdf (gaussianReal 0 1) (-((F - K) / (σN * Real.sqrt T))) +
          σN * Real.sqrt T * gaussianPDFReal 0 1 ((F - K) / (σN * Real.sqrt T))) := by
  have hs : 0 < σN * Real.sqrt T := mul_pos hσ (Real.sqrt_pos.mpr hT)
  have hdiff := bach_parity_core F K (σN * Real.sqrt T)
  have hcall : ∫ z, max (F + σN * Real.sqrt T * z - K) 0 ∂(gaussianReal 0 1) =
      (F - K) * cdf (gaussianReal 0 1) ((F - K) / (σN * Real.sqrt T)) +
        σN * Real.sqrt T * gaussianPDFReal 0 1 ((F - K) / (σN * Real.sqrt T)) := by
    rw [← bach_call_core (F - K) (σN * Real.sqrt T) hs]
    congr 1
    funext z
    congr 1
    ring
  congr 1
  rw [bach_cdf_neg]
  linarith

/-- Put-call parity in the normal model: call minus put is the discounted head start
`D * (F - K)`, with no volatility in it, for any level and strike, negative ones included. -/
theorem bachelier_put_call_parity (F K r σN T : ℝ) :
    Real.exp (-(r * T)) *
        ∫ z, max (F + σN * Real.sqrt T * z - K) 0 ∂(gaussianReal 0 1) -
      Real.exp (-(r * T)) *
        ∫ z, max (K - (F + σN * Real.sqrt T * z)) 0 ∂(gaussianReal 0 1) =
      Real.exp (-(r * T)) * (F - K) := by
  rw [← mul_sub, bach_parity_core]

/-! The card's whole-number worked steps, in basis points:
F = 50, K = 75, σN = 60, T = 1. -/

-- The head start m = F - K.
example : (50 : ℚ) - 75 = -25 := by norm_num
-- One standard deviation s = σN * √T, with √1 = 1.
example : (60 : ℚ) * 1 = 60 := by norm_num
-- The standardised head start d = m / s = -25 / 60 = -5/12 (the card's -0.416667).
example : ((50 : ℚ) - 75) / 60 = -5 / 12 := by norm_num
-- Wander adds up in the square root of time: over four years s is 60 * 2 = 120, not 60 * 4 = 240.
example : (60 : ℚ) * 2 = 120 ∧ (60 : ℚ) * 4 = 240 ∧ (2 : ℚ) ^ 2 = 4 := by norm_num

#print axioms bachelier_call_formula
#print axioms bachelier_put_formula
#print axioms bachelier_put_call_parity
