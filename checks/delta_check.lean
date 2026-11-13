-- Delta: in the Black-Scholes model the slope of the call price in the share price is e^(-qT) N(d₁), the put's slope is -e^(-qT) N(-d₁), and these lie strictly between 0 and e^(-qT) and between -e^(-qT) and 0.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt

open Real MeasureTheory ProbabilityTheory

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- The share-side distance to the strike,
`d₁ = (ln(S/K) + (r - q + σ²/2) T) / (σ√T)`; the cash-side one is `d₂ = d₁ - σ√T`. -/
noncomputable def bsD1 (S K r q σ T : ℝ) : ℝ :=
  (log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)

/-- The Black-Scholes call: `C = S e^(-qT) N(d₁) - K e^(-rT) N(d₂)`. -/
noncomputable def bsCall (S K r q σ T : ℝ) : ℝ :=
  S * exp (-q * T) * stdNormalCDF (bsD1 S K r q σ T)
    - K * exp (-r * T) * stdNormalCDF (bsD1 S K r q σ T - σ * √T)

/-- The Black-Scholes put: `P = K e^(-rT) N(-d₂) - S e^(-qT) N(-d₁)`. -/
noncomputable def bsPut (S K r q σ T : ℝ) : ℝ :=
  K * exp (-r * T) * stdNormalCDF (-(bsD1 S K r q σ T - σ * √T))
    - S * exp (-q * T) * stdNormalCDF (-bsD1 S K r q σ T)

/-- The standard normal density, written out. -/
lemma delta_phi_eq (x : ℝ) : gaussianPDFReal 0 1 x = (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := by
  simp [gaussianPDFReal]

lemma delta_phi_continuous : Continuous (gaussianPDFReal 0 1) := by
  rw [gaussianPDFReal_def]; fun_prop

lemma delta_phi_neg (x : ℝ) : gaussianPDFReal 0 1 (-x) = gaussianPDFReal 0 1 x := by
  simp [gaussianPDFReal]

lemma delta_N_eq_integral (x : ℝ) : stdNormalCDF x = ∫ t in Set.Iic x, gaussianPDFReal 0 1 t := by
  unfold stdNormalCDF
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal]
  exact setIntegral_nonneg measurableSet_Iic (fun t _ => gaussianPDFReal_nonneg _ _ _)

lemma delta_N_sub (a b : ℝ) :
    stdNormalCDF b - stdNormalCDF a = ∫ t in a..b, gaussianPDFReal 0 1 t := by
  rw [delta_N_eq_integral, delta_N_eq_integral]
  exact intervalIntegral.integral_Iic_sub_Iic (integrable_gaussianPDFReal 0 1).integrableOn
    (integrable_gaussianPDFReal 0 1).integrableOn

lemma delta_N_hasDerivAt (x : ℝ) : HasDerivAt stdNormalCDF (gaussianPDFReal 0 1 x) x := by
  have h : stdNormalCDF = fun y => stdNormalCDF 0 + ∫ t in (0:ℝ)..y, gaussianPDFReal 0 1 t := by
    funext y; rw [← delta_N_sub]; ring
  rw [h]
  exact (intervalIntegral.integral_hasDerivAt_right (delta_phi_continuous.intervalIntegrable _ _)
    (delta_phi_continuous.stronglyMeasurableAtFilter _ _)
    delta_phi_continuous.continuousAt).const_add _

lemma delta_N_pos (x : ℝ) : 0 < stdNormalCDF x := by
  have h1 := delta_N_sub (x - 1) x
  have h2 : 0 < ∫ t in (x - 1)..x, gaussianPDFReal 0 1 t :=
    intervalIntegral.intervalIntegral_pos_of_pos_on (delta_phi_continuous.intervalIntegrable _ _)
      (fun t _ => gaussianPDFReal_pos _ _ _ one_ne_zero) (by linarith)
  have h3 : 0 ≤ stdNormalCDF (x - 1) := cdf_nonneg _ _
  linarith

lemma delta_N_lt_one (x : ℝ) : stdNormalCDF x < 1 := by
  have h1 := delta_N_sub x (x + 1)
  have h2 : 0 < ∫ t in x..(x + 1), gaussianPDFReal 0 1 t :=
    intervalIntegral.intervalIntegral_pos_of_pos_on (delta_phi_continuous.intervalIntegrable _ _)
      (fun t _ => gaussianPDFReal_pos _ _ _ one_ne_zero) (by linarith)
  have h3 : stdNormalCDF (x + 1) ≤ 1 := cdf_le_one _ _
  linarith

lemma delta_N_add_N_neg (x : ℝ) : stdNormalCDF x + stdNormalCDF (-x) = 1 := by
  rw [delta_N_eq_integral, delta_N_eq_integral, ← integral_comp_neg_Ioi]
  simp_rw [delta_phi_neg]
  rw [← Set.compl_Iic, integral_add_compl measurableSet_Iic (integrable_gaussianPDFReal 0 1),
    integral_gaussianPDFReal_eq_one 0 one_ne_zero]

/-- The cancellation behind delta: `K e^(-rT) φ(d₂) = S e^(-qT) φ(d₁)`. -/
lemma delta_key (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    K * exp (-r * T) * gaussianPDFReal 0 1 (bsD1 S K r q σ T - σ * √T)
      = S * exp (-q * T) * gaussianPDFReal 0 1 (bsD1 S K r q σ T) := by
  have hs : 0 < σ * √T := mul_pos hσ (Real.sqrt_pos.2 hT)
  have hsq : √T ^ 2 = T := Real.sq_sqrt hT.le
  set d := bsD1 S K r q σ T with hd_def
  have hd : d * (σ * √T) = log (S / K) + (r - q + σ ^ 2 / 2) * T := by
    rw [hd_def, bsD1]; field_simp
  have hexp : -(d - σ * √T) ^ 2 / 2 + -r * T = -d ^ 2 / 2 + -q * T + log (S / K) := by
    linear_combination hd - (σ ^ 2 / 2) * hsq
  rw [delta_phi_eq, delta_phi_eq]
  rw [show K * exp (-r * T) * ((√(2 * π))⁻¹ * exp (-(d - σ * √T) ^ 2 / 2))
      = (√(2 * π))⁻¹ * K * exp (-(d - σ * √T) ^ 2 / 2 + -r * T) by rw [exp_add]; ring,
    hexp, exp_add, exp_add, exp_log (div_pos hS hK)]
  field_simp

/-- **Call delta** (The formula; Why it works, Steps 1 and 2). In the Black-Scholes model with
constant volatility `σ > 0`, constant rates `r` and a continuous dividend yield `q`, a plain call
with strike `K > 0`, time left `T > 0` and share price `S > 0`, with every other input frozen:
the call price's slope in the share price is the dividend drag times the share-counted
exercise chance, `∂C/∂S = e^(-qT) N(d₁)`. -/
theorem call_delta_eq_dividend_drag_mul_N_d1
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun x => bsCall x K r q σ T)
      (exp (-q * T) * stdNormalCDF (bsD1 S K r q σ T)) S := by
  have hs : 0 < σ * √T := mul_pos hσ (Real.sqrt_pos.2 hT)
  have hd1 : HasDerivAt (fun x => bsD1 x K r q σ T)
      ((1 / K) / (S / K) / (σ * √T)) S := by
    have h := ((((hasDerivAt_id' S).div_const K).log (div_pos hS hK).ne').add_const
      ((r - q + σ ^ 2 / 2) * T)).div_const (σ * √T)
    simpa [bsD1] using h
  have hC := (((hasDerivAt_id S).mul_const (exp (-q * T))).mul
      ((delta_N_hasDerivAt _).comp S hd1)).sub
    (((delta_N_hasDerivAt _).comp S (hd1.sub_const (σ * √T))).const_mul (K * exp (-r * T)))
  have key := delta_key S K r q σ T hS hK hσ hT
  convert hC using 1
  all_goals first
    | (funext x; simp [bsCall, Function.comp]; done)
    | (simp only [id, Function.comp]
       linear_combination ((1 / K) / (S / K) / (σ * √T)) * key)

/-- **Put delta, and call minus put** (Why it works, Step 3). Under the same terms, the put
price's slope in the share price is `∂P/∂S = e^(-qT)(N(d₁) - 1) = -e^(-qT) N(-d₁)`, so the call's
delta minus the put's delta is the dividend drag `e^(-qT)`. -/
theorem put_delta_eq_neg_dividend_drag_mul_N_neg_d1
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun x => bsPut x K r q σ T)
      (-(exp (-q * T) * stdNormalCDF (-bsD1 S K r q σ T))) S ∧
      exp (-q * T) * stdNormalCDF (bsD1 S K r q σ T)
        - (-(exp (-q * T) * stdNormalCDF (-bsD1 S K r q σ T))) = exp (-q * T) := by
  have hs : 0 < σ * √T := mul_pos hσ (Real.sqrt_pos.2 hT)
  have hd1 : HasDerivAt (fun x => bsD1 x K r q σ T)
      ((1 / K) / (S / K) / (σ * √T)) S := by
    have h := ((((hasDerivAt_id' S).div_const K).log (div_pos hS hK).ne').add_const
      ((r - q + σ ^ 2 / 2) * T)).div_const (σ * √T)
    simpa [bsD1] using h
  refine ⟨?_, ?_⟩
  · have hP := (((delta_N_hasDerivAt _).comp S
        (hd1.sub_const (σ * √T)).neg).const_mul (K * exp (-r * T))).sub
      (((hasDerivAt_id S).mul_const (exp (-q * T))).mul
        ((delta_N_hasDerivAt _).comp S hd1.neg))
    have key := delta_key S K r q σ T hS hK hσ hT
    convert hP using 1
    all_goals first
      | (funext x; simp [bsPut, Function.comp]; done)
      | (simp only [id, Function.comp, Pi.neg_apply, delta_phi_neg]
         linear_combination ((1 / K) / (S / K) / (σ * √T)) * key)
  · linear_combination exp (-q * T) * delta_N_add_N_neg (bsD1 S K r q σ T)

/-- **The bounds are 0 and `e^(-qT)`, not 0 and 1** (Why it works, Step 5). Under the same terms,
the call delta lies strictly between `0` and `e^(-qT)`, and the put delta strictly between
`-e^(-qT)` and `0`. -/
theorem delta_bounds
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    (0 < exp (-q * T) * stdNormalCDF (bsD1 S K r q σ T) ∧
        exp (-q * T) * stdNormalCDF (bsD1 S K r q σ T) < exp (-q * T)) ∧
      (-exp (-q * T) < -(exp (-q * T) * stdNormalCDF (-bsD1 S K r q σ T)) ∧
        -(exp (-q * T) * stdNormalCDF (-bsD1 S K r q σ T)) < 0) := by
  have he : 0 < exp (-q * T) := exp_pos _
  refine ⟨⟨mul_pos he (delta_N_pos _), mul_lt_of_lt_one_right he (delta_N_lt_one _)⟩,
    neg_lt_neg (mul_lt_of_lt_one_right he (delta_N_lt_one _)),
    neg_neg_of_pos (mul_pos he (delta_N_pos _))⟩

-- Acme: S = K = 100, r = 5/100, q = 2/100, σ = 1/5, T = 1 year.
-- d₁ = (ln 1 + (0.05 - 0.02 + 0.02) · 1) / 0.20 = 0.25.
example : bsD1 100 100 (5 / 100) (2 / 100) (1 / 5) 1 = 1 / 4 := by
  simp [bsD1]; norm_num
-- d₂ = d₁ - σ√T = 0.25 - 0.20 = 0.05.
example : bsD1 100 100 (5 / 100) (2 / 100) (1 / 5) 1 - 1 / 5 * √1 = 1 / 20 := by
  simp [bsD1]; norm_num
-- The drift allowance in d₁: 0.05 - 0.02 + 0.02 = 0.05, over σ = 0.20, gives 0.25.
example : ((5 : ℚ) / 100 - 2 / 100 + (1 / 5) ^ 2 / 2) / (1 / 5) = 1 / 4 := by norm_num
-- Call minus put, as printed: 0.586851 + 0.393348 = 0.980199, the dividend drag.
example : (586851 : ℕ) + 393348 = 980199 := by decide

#print axioms delta_phi_eq
#print axioms delta_phi_continuous
#print axioms delta_phi_neg
#print axioms delta_N_eq_integral
#print axioms delta_N_sub
#print axioms delta_N_hasDerivAt
#print axioms delta_N_pos
#print axioms delta_N_lt_one
#print axioms delta_N_add_N_neg
#print axioms delta_key
#print axioms call_delta_eq_dividend_drag_mul_N_d1
#print axioms put_delta_eq_neg_dividend_drag_mul_N_neg_d1
#print axioms delta_bounds
