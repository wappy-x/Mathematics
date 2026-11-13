-- Greeks of a futures option: in Black's 1976 model for a call on a futures price, the slope in the futures price is e^(-rT) N(d₁), the slope in the bank rate with the future held still is -T V, the slope in volatility is e^(-rT) F φ(d₁) √T, and the slope in time left gives theta = r V - e^(-rT) F φ(d₁) σ / (2√T).
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt

open Real MeasureTheory ProbabilityTheory

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def futN (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- `φ(x)`: the standard bell curve's height at `x`. -/
noncomputable def futPhi (x : ℝ) : ℝ := gaussianPDFReal 0 1 x

/-- Black-76 distance `d₁ = (ln(F/K) + σ²T/2) / (σ√T)`. It contains no bank rate. -/
noncomputable def futD1 (F K σ T : ℝ) : ℝ :=
  (log (F / K) + σ ^ 2 / 2 * T) / (σ * √T)

/-- Black-76 distance `d₂ = d₁ - σ√T`. -/
noncomputable def futD2 (F K σ T : ℝ) : ℝ :=
  futD1 F K σ T - σ * √T

/-- The premium-paid Black-76 call, dollars per barrel:
`V = e^(-rT) [F N(d₁) - K N(d₂)]`. -/
noncomputable def futCall (F K r σ T : ℝ) : ℝ :=
  exp (-r * T) * (F * futN (futD1 F K σ T) - K * futN (futD2 F K σ T))

lemma futPhi_eq (x : ℝ) : futPhi x = (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := by
  simp [futPhi, gaussianPDFReal]

lemma continuous_futPhi : Continuous futPhi := by
  have : futPhi = fun x => (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := funext futPhi_eq
  rw [this]; fun_prop

lemma futN_eq_integral (x : ℝ) : futN x = ∫ t in Set.Iic x, futPhi t := by
  unfold futN futPhi
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (integral_nonneg fun _ => gaussianPDFReal_nonneg _ _ _)]

lemma futN_eq_add (x : ℝ) : futN x = futN 0 + ∫ t in (0 : ℝ)..x, futPhi t := by
  have hi := intervalIntegral.integral_Iic_sub_Iic (f := futPhi) (a := 0) (b := x)
    (μ := volume) (integrable_gaussianPDFReal 0 1).integrableOn
    (integrable_gaussianPDFReal 0 1).integrableOn
  rw [futN_eq_integral, futN_eq_integral]
  linarith

lemma hasDerivAt_futN (x : ℝ) : HasDerivAt futN (futPhi x) x := by
  have h := intervalIntegral.integral_hasDerivAt_right
    (continuous_futPhi.intervalIntegrable 0 x)
    continuous_futPhi.aestronglyMeasurable.stronglyMeasurableAtFilter
    continuous_futPhi.continuousAt
  have h2 := h.const_add (futN 0)
  have : futN = fun x => futN 0 + ∫ t in (0 : ℝ)..x, futPhi t := funext futN_eq_add
  rw [this]; exact h2

/-- `F φ(d₁) = K φ(d₂)`. -/
lemma fut_pdf_identity (F K σ T : ℝ) (hF : 0 < F) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    F * futPhi (futD1 F K σ T) = K * futPhi (futD1 F K σ T - σ * √T) := by
  set d := futD1 F K σ T with hd
  have hsq : √T ^ 2 = T := Real.sq_sqrt hT.le
  have hsT : 0 < √T := Real.sqrt_pos.mpr hT
  have hu : σ * √T ≠ 0 := by positivity
  have hdu : d * (σ * √T) = log (F / K) + σ ^ 2 / 2 * T := by
    rw [hd, futD1]; field_simp
  have hexp : -(d - σ * √T) ^ 2 / 2 = -d ^ 2 / 2 + log (F / K) := by
    linear_combination hdu - (σ ^ 2 / 2) * hsq
  have hlog : exp (log (F / K)) = F / K := exp_log (by positivity)
  rw [futPhi_eq, futPhi_eq, hexp, exp_add, hlog]
  field_simp

/-- Product and chain rule for `a N(d) - b N(d - u)` when `a φ(d) = b φ(d - u)`. -/
lemma fut_hasDerivAt_generic {a b d u : ℝ → ℝ} {p a' b' u' : ℝ} (ha : HasDerivAt a a' p)
    (hb : HasDerivAt b b' p) (hd : DifferentiableAt ℝ d p) (hu : HasDerivAt u u' p)
    (hid : a p * futPhi (d p) = b p * futPhi (d p - u p)) :
    HasDerivAt (fun q => a q * futN (d q) - b q * futN (d q - u q))
      (a' * futN (d p) - b' * futN (d p - u p) + a p * futPhi (d p) * u') p := by
  obtain ⟨D, hD⟩ : ∃ D, HasDerivAt d D p := ⟨_, hd.hasDerivAt⟩
  have h1 := ha.mul ((hasDerivAt_futN (d p)).comp p hD)
  have h2 := hb.mul ((hasDerivAt_futN (d p - u p)).comp p (hD.sub hu))
  convert h1.sub h2 using 1
  · rfl
  · simp only [Function.comp_apply, Pi.sub_apply]
    linear_combination (u' - D) * hid

lemma futD1_hasDerivAt_F (F K σ T : ℝ) (hF : 0 < F) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun x => futD1 x K σ T) (1 / (F * σ * √T)) F := by
  have hsT : 0 < √T := Real.sqrt_pos.mpr hT
  have h := ((((hasDerivAt_id F).div_const K).log (by simp only [id]; positivity)).add_const
    (σ ^ 2 / 2 * T)).div_const (σ * √T)
  refine h.congr_deriv ?_
  simp only [id]
  field_simp

#print axioms futPhi_eq
#print axioms continuous_futPhi
#print axioms futN_eq_integral
#print axioms futN_eq_add
#print axioms hasDerivAt_futN
#print axioms fut_pdf_identity
#print axioms fut_hasDerivAt_generic
#print axioms futD1_hasDerivAt_F

/-- **Delta and rho of a futures option** (the card's main claim; Why it works, Steps 1 and 4).
In Black's 1976 model, for a premium-paid European call on a future with futures price `F > 0`,
strike `K > 0`, volatility `σ > 0` and time left `T > 0`, at any bank rate `r`:
the call price's slope in the futures price, every other input frozen, is the discount times
`N(d₁)`, `Δ = e^(-rT) N(d₁)` (a count of futures per barrel); and its slope in the bank rate,
with the futures price held still, is minus the time left times the premium, `ρ = -T V`. -/
theorem futures_call_delta_eq_discount_mul_N_d1_and_rho_eq_neg_time_mul_price
    (F K r σ T : ℝ) (hF : 0 < F) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun f => futCall f K r σ T) (exp (-r * T) * futN (futD1 F K σ T)) F ∧
      HasDerivAt (fun x => futCall F K x σ T) (-T * futCall F K r σ T) r := by
  have hsT : 0 < √T := Real.sqrt_pos.mpr hT
  have hid := fut_pdf_identity F K σ T hF hK hσ hT
  refine ⟨?_, ?_⟩
  · have h := fut_hasDerivAt_generic (a := fun x => x) (b := fun _ => K)
      (d := fun x => futD1 x K σ T) (u := fun _ => σ * √T) (u' := 0) (hasDerivAt_id' F)
      (hasDerivAt_const _ _) (futD1_hasDerivAt_F F K σ T hF hK hσ hT).differentiableAt
      (hasDerivAt_const _ _) hid
    refine (h.const_mul (exp (-r * T))).congr_deriv ?_
    simp
  · have h := (((hasDerivAt_id r).neg.mul_const T).exp).mul_const
      (F * futN (futD1 F K σ T) - K * futN (futD2 F K σ T))
    refine h.congr_deriv ?_
    simp only [Pi.neg_apply, id_eq, futCall]
    ring

/-- **Gamma and vega share one piece** (Why it works, Step 3). Under the same terms, delta's own
slope in the futures price is `Γ = e^(-rT) φ(d₁) / (F σ √T)`, and the call price's slope in
volatility is `ν = e^(-rT) F φ(d₁) √T`. -/
theorem futures_call_gamma_and_vega
    (F K r σ T : ℝ) (hF : 0 < F) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun f => exp (-r * T) * futN (futD1 f K σ T))
        (exp (-r * T) * futPhi (futD1 F K σ T) / (F * σ * √T)) F ∧
      HasDerivAt (fun s => futCall F K r s T)
        (exp (-r * T) * F * futPhi (futD1 F K σ T) * √T) σ := by
  have hsT : 0 < √T := Real.sqrt_pos.mpr hT
  have hid := fut_pdf_identity F K σ T hF hK hσ hT
  refine ⟨?_, ?_⟩
  · have h := ((hasDerivAt_futN (futD1 F K σ T)).comp F
      (futD1_hasDerivAt_F F K σ T hF hK hσ hT)).const_mul (exp (-r * T))
    refine h.congr_deriv ?_
    field_simp
  · have h := fut_hasDerivAt_generic (a := fun _ => F) (b := fun _ => K)
      (d := fun s => futD1 F K s T) (u := fun s => s * √T) (hasDerivAt_const _ _)
      (hasDerivAt_const _ _) (by unfold futD1; fun_prop (disch := positivity))
      ((hasDerivAt_id σ).mul_const _) hid
    refine (h.const_mul (exp (-r * T))).congr_deriv ?_
    ring

/-- **Theta adds back the interest on the premium** (Why it works, Step 3 and the detailed
proof). Under the same terms, theta, minus the call price's slope in the time left, is
`Θ = r V - e^(-rT) F φ(d₁) σ / (2√T)`. -/
theorem futures_call_theta_eq_interest_minus_decay
    (F K r σ T : ℝ) (hF : 0 < F) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun t => futCall F K r σ t)
      (-(r * futCall F K r σ T - exp (-r * T) * F * futPhi (futD1 F K σ T) * σ / (2 * √T))) T := by
  have hsT : 0 < √T := Real.sqrt_pos.mpr hT
  have hid := fut_pdf_identity F K σ T hF hK hσ hT
  have h := fut_hasDerivAt_generic (a := fun _ => F) (b := fun _ => K)
    (d := fun t => futD1 F K σ t) (u := fun t => σ * √t) (hasDerivAt_const _ _)
    (hasDerivAt_const _ _) (by unfold futD1; fun_prop (disch := positivity))
    ((Real.hasDerivAt_sqrt hT.ne').const_mul σ) hid
  have he := ((hasDerivAt_id T).const_mul (-r)).exp
  refine (he.mul h).congr_deriv ?_
  simp only [id, futCall, futD2]
  field_simp
  ring

/-! The card's worked numbers that are exact fractions, for the house Brent call:
F = 85, K = 85, σ = 3/10, T = 1/2, r = 5/100, one option on 1,000 barrels, lot 1,000 barrels. -/

-- The drift term σ²T/2 = 0.5 × 0.09 × 0.5 = 0.0225.
example : (1 / 2 : ℚ) * (3 / 10) ^ 2 * (1 / 2) = 9 / 400 := by norm_num

-- The discount's exponent rT = 0.05 × 0.5 = 0.025.
example : (5 / 100 : ℚ) * (1 / 2) = 1 / 40 := by norm_num

-- At the money, d₂ = -d₁ (the card's 0.1061 and -0.1061).
example : futD2 85 85 (3 / 10) (1 / 2) = -futD1 85 85 (3 / 10) (1 / 2) := by
  have h : (0 : ℝ) < √(1 / 2) := Real.sqrt_pos.mpr (by norm_num)
  have hsq : √(1 / 2 : ℝ) ^ 2 = 1 / 2 := Real.sq_sqrt (by norm_num)
  unfold futD2 futD1
  rw [div_self (by norm_num : (85 : ℝ) ≠ 0), log_one]
  field_simp
  linear_combination (-36 : ℝ) * hsq

-- Hedge in lots, h = n m Δ / M with n = 1, m = M = 1,000: the lots equal delta.
example (Δ : ℝ) : 1 * 1000 * Δ / 1000 = Δ := by
  ring

#print axioms futures_call_delta_eq_discount_mul_N_d1_and_rho_eq_neg_time_mul_price
#print axioms futures_call_gamma_and_vega
#print axioms futures_call_theta_eq_interest_minus_decay
