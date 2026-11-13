-- Gamma: in the Black-Scholes model the second derivative of the call price in the share price, and of the put price, is e^(-qT) φ(d₁) / (S σ √T), this gamma rises up to S* = K e^(-(r - q + 3σ²/2)T) and falls beyond it, and at the strike it grows without limit as expiry nears.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus

open Real MeasureTheory ProbabilityTheory Filter Topology Set

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- `φ(x) = e^(-x²/2) / √(2π)`: the bell curve's height at `x`, the standard normal density. -/
noncomputable def stdNormalPDF (x : ℝ) : ℝ := gaussianPDFReal 0 1 x

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
  K * exp (-r * T) * stdNormalCDF (σ * √T - bsD1 S K r q σ T)
    - S * exp (-q * T) * stdNormalCDF (-bsD1 S K r q σ T)

/-- The closed formula for gamma: `Γ = e^(-qT) φ(d₁) / (S σ √T)`. -/
noncomputable def bsGamma (S K r q σ T : ℝ) : ℝ :=
  exp (-q * T) * stdNormalPDF (bsD1 S K r q σ T) / (S * σ * √T)

lemma stdPDF_eq (z : ℝ) :
    stdNormalPDF z = (√(2 * π))⁻¹ * exp (-z ^ 2 / 2) := by
  simp [stdNormalPDF, gaussianPDFReal]

#print axioms stdPDF_eq

lemma stdPDF_continuous : Continuous stdNormalPDF := by
  have : stdNormalPDF = fun x : ℝ => (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := by
    funext x; exact stdPDF_eq x
  rw [this]; fun_prop

#print axioms stdPDF_continuous

lemma stdPDF_pos (z : ℝ) : 0 < stdNormalPDF z :=
  gaussianPDFReal_pos 0 1 z one_ne_zero

#print axioms stdPDF_pos

lemma stdPDF_neg (z : ℝ) : stdNormalPDF (-z) = stdNormalPDF z := by
  rw [stdPDF_eq, stdPDF_eq, neg_sq]

#print axioms stdPDF_neg

lemma stdCDF_eq (z : ℝ) : stdNormalCDF z = ∫ t in Set.Iic z, stdNormalPDF t := by
  show cdf (gaussianReal 0 1) z = _
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (integral_nonneg fun t => gaussianPDFReal_nonneg _ _ _)]
  rfl

#print axioms stdCDF_eq

lemma stdCDF_hasDerivAt (z : ℝ) : HasDerivAt stdNormalCDF (stdNormalPDF z) z := by
  have hint : ∀ a : ℝ, IntegrableOn stdNormalPDF (Set.Iic a) := fun a =>
    (integrable_gaussianPDFReal 0 1).integrableOn
  have heq : stdNormalCDF = fun x => stdNormalCDF 0 + ∫ t in (0 : ℝ)..x, stdNormalPDF t := by
    funext x
    rw [← intervalIntegral.integral_Iic_sub_Iic (hint 0) (hint x), stdCDF_eq, stdCDF_eq]
    ring
  rw [heq]
  have hc := stdPDF_continuous
  exact (intervalIntegral.integral_hasDerivAt_right (hc.intervalIntegrable _ _)
    hc.aestronglyMeasurable.stronglyMeasurableAtFilter hc.continuousAt).const_add _

#print axioms stdCDF_hasDerivAt

lemma bsD1_eq (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) :
    bsD1 S K r q σ T = (log S - log K + (r - q + σ ^ 2 / 2) * T) / (σ * √T) := by
  rw [bsD1, log_div hS.ne' hK.ne']

#print axioms bsD1_eq

lemma bsD1_hasDerivAt (x K r q σ T : ℝ) (hx : 0 < x) (hK : 0 < K) :
    HasDerivAt (fun y => bsD1 y K r q σ T) (1 / (x * σ * √T)) x := by
  have h1 : HasDerivAt (fun y : ℝ => y / K) (1 / K) x := (hasDerivAt_id x).div_const K
  have h2 := (h1.log (div_pos hx hK).ne').add_const ((r - q + σ ^ 2 / 2) * T)
  have h3 := h2.div_const (σ * √T)
  unfold bsD1
  convert h3 using 1
  field_simp

#print axioms bsD1_hasDerivAt

/-- The identity `S e^(-qT) φ(d₁) = K e^(-rT) φ(d₂)` that makes the `N'` terms cancel. -/
lemma key_identity (x K r q σ T : ℝ) (hx : 0 < x) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    K * exp (-r * T) * stdNormalPDF (bsD1 x K r q σ T - σ * √T)
      = x * exp (-q * T) * stdNormalPDF (bsD1 x K r q σ T) := by
  set d := bsD1 x K r q σ T with hd
  set s := σ * √T with hs
  have hs0 : 0 < s := mul_pos hσ (sqrt_pos.mpr hT)
  have hss : s * s = σ ^ 2 * T := by
    rw [hs]; have := mul_self_sqrt hT.le; nlinarith [this]
  have hds : d * s = log (x / K) + (r - q + σ ^ 2 / 2) * T := by
    rw [hd, bsD1]; field_simp; rw [hs]; ring
  have hexp : -(d - s) ^ 2 / 2 = -d ^ 2 / 2 + (log (x / K) + (r - q) * T) := by
    linear_combination hds - hss / 2
  rw [stdPDF_eq, stdPDF_eq, hexp, exp_add, exp_add, exp_log (div_pos hx hK)]
  have he : exp (-r * T) * exp ((r - q) * T) = exp (-q * T) := by
    rw [← exp_add]; ring_nf
  rw [← he]
  field_simp

#print axioms key_identity

lemma delta_hasDerivAt (x K r q σ T : ℝ) (hx : 0 < x) (hK : 0 < K) :
    HasDerivAt (fun y => exp (-q * T) * stdNormalCDF (bsD1 y K r q σ T))
      (bsGamma x K r q σ T) x := by
  have h : HasDerivAt (fun y => exp (-q * T) * stdNormalCDF (bsD1 y K r q σ T))
      (exp (-q * T) * (stdNormalPDF (bsD1 x K r q σ T) * (1 / (x * σ * √T)))) x :=
    ((stdCDF_hasDerivAt (bsD1 x K r q σ T)).comp x
      (bsD1_hasDerivAt x K r q σ T hx hK)).const_mul (exp (-q * T))
  refine h.congr_deriv ?_
  unfold bsGamma; ring

#print axioms delta_hasDerivAt

lemma call_hasDerivAt (x K r q σ T : ℝ) (hx : 0 < x) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun y => bsCall y K r q σ T)
      (exp (-q * T) * stdNormalCDF (bsD1 x K r q σ T)) x := by
  have hd := bsD1_hasDerivAt x K r q σ T hx hK
  have h : HasDerivAt (fun y => bsCall y K r q σ T)
      (exp (-q * T) * stdNormalCDF (bsD1 x K r q σ T)
        + x * exp (-q * T) * (stdNormalPDF (bsD1 x K r q σ T) * (1 / (x * σ * √T)))
        - K * exp (-r * T) * (stdNormalPDF (bsD1 x K r q σ T - σ * √T) * (1 / (x * σ * √T))))
      x :=
    ((hasDerivAt_mul_const (exp (-q * T))).mul
      ((stdCDF_hasDerivAt (bsD1 x K r q σ T)).comp x hd)).sub
    (((stdCDF_hasDerivAt (bsD1 x K r q σ T - σ * √T)).comp x
      (hd.sub_const (σ * √T))).const_mul (K * exp (-r * T)))
  refine h.congr_deriv ?_
  have key := key_identity x K r q σ T hx hK hσ hT
  linear_combination (-(1 / (x * σ * √T))) * key

#print axioms call_hasDerivAt

lemma put_hasDerivAt (x K r q σ T : ℝ) (hx : 0 < x) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun y => bsPut y K r q σ T)
      (-(exp (-q * T) * stdNormalCDF (-bsD1 x K r q σ T))) x := by
  have hd := bsD1_hasDerivAt x K r q σ T hx hK
  have h : HasDerivAt (fun y => bsPut y K r q σ T)
      (K * exp (-r * T) * (stdNormalPDF (σ * √T - bsD1 x K r q σ T) * (-(1 / (x * σ * √T))))
        - (exp (-q * T) * stdNormalCDF (-bsD1 x K r q σ T)
          + x * exp (-q * T) * (stdNormalPDF (-bsD1 x K r q σ T) * (-(1 / (x * σ * √T))))))
      x :=
    (((stdCDF_hasDerivAt (σ * √T - bsD1 x K r q σ T)).comp x
      (hd.const_sub (σ * √T))).const_mul (K * exp (-r * T))).sub
    ((hasDerivAt_mul_const (exp (-q * T))).mul
      ((stdCDF_hasDerivAt (-bsD1 x K r q σ T)).comp x hd.neg))
  refine h.congr_deriv ?_
  have key := key_identity x K r q σ T hx hK hσ hT
  have e1 : σ * √T - bsD1 x K r q σ T = -(bsD1 x K r q σ T - σ * √T) := by ring
  rw [e1, stdPDF_neg, stdPDF_neg]
  linear_combination (-(1 / (x * σ * √T))) * key

#print axioms put_hasDerivAt

lemma putDelta_hasDerivAt (x K r q σ T : ℝ) (hx : 0 < x) (hK : 0 < K) :
    HasDerivAt (fun y => -(exp (-q * T) * stdNormalCDF (-bsD1 y K r q σ T)))
      (bsGamma x K r q σ T) x := by
  have h : HasDerivAt (fun y => -(exp (-q * T) * stdNormalCDF (-bsD1 y K r q σ T)))
      (-(exp (-q * T) * (stdNormalPDF (-bsD1 x K r q σ T) * (-(1 / (x * σ * √T)))))) x :=
    (((stdCDF_hasDerivAt (-bsD1 x K r q σ T)).comp x
      (bsD1_hasDerivAt x K r q σ T hx hK).neg).const_mul (exp (-q * T))).neg
  refine h.congr_deriv ?_
  unfold bsGamma; rw [stdPDF_neg]; ring

#print axioms putDelta_hasDerivAt

lemma bsGamma_eq (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) :
    bsGamma S K r q σ T = exp (-q * T) * (√(2 * π))⁻¹ / (σ * √T) *
      exp (-((log S - log K + (r - q + σ ^ 2 / 2) * T) / (σ * √T)) ^ 2 / 2 - log S) := by
  rw [bsGamma, stdPDF_eq, bsD1_eq S K r q σ T hS hK, exp_sub, exp_log hS]
  ring

#print axioms bsGamma_eq

/-- **Gamma is the bend in the price, the same for a call and a put** (The formula; Why it
works, Steps 1 to 5). In the Black-Scholes model with constant volatility `σ > 0`, constant
rates `r` and `q`, a plain call or put with strike `K > 0`, time left `T > 0`, and share price
`S > 0`: the rate at which the call's hedge ratio `e^(-qT) N(d₁)` changes per dollar of share
price, the call price's second derivative in the share price, and the put price's second
derivative in the share price are all equal to `e^(-qT) φ(d₁) / (S σ √T)`. -/
theorem gamma_is_second_derivative_same_for_call_and_put
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    deriv (fun x => exp (-q * T) * stdNormalCDF (bsD1 x K r q σ T)) S = bsGamma S K r q σ T ∧
      deriv (deriv (fun x => bsCall x K r q σ T)) S = bsGamma S K r q σ T ∧
      deriv (deriv (fun x => bsPut x K r q σ T)) S = bsGamma S K r q σ T := by
  refine ⟨(delta_hasDerivAt S K r q σ T hS hK).deriv, ?_, ?_⟩
  · have hev : deriv (fun x => bsCall x K r q σ T) =ᶠ[𝓝 S]
        fun x => exp (-q * T) * stdNormalCDF (bsD1 x K r q σ T) := by
      filter_upwards [Ioi_mem_nhds hS] with x hx
      exact (call_hasDerivAt x K r q σ T hx hK hσ hT).deriv
    rw [hev.deriv_eq]
    exact (delta_hasDerivAt S K r q σ T hS hK).deriv
  · have hev : deriv (fun x => bsPut x K r q σ T) =ᶠ[𝓝 S]
        fun x => -(exp (-q * T) * stdNormalCDF (-bsD1 x K r q σ T)) := by
      filter_upwards [Ioi_mem_nhds hS] with x hx
      exact (put_hasDerivAt x K r q σ T hx hK hσ hT).deriv
    rw [hev.deriv_eq]
    exact (putDelta_hasDerivAt S K r q σ T hS hK).deriv

/-- **Where the hump peaks** (Step 7). With `K > 0`, `σ > 0`, `T > 0` and any rates `r`, `q`,
gamma as a function of the share price rises strictly on `(0, S*]` and falls strictly on
`[S*, ∞)`, where `S* = K e^(-(r - q + 3σ²/2) T)`: it is largest at `S*` and falls on either side. -/
theorem gamma_peaks_at_S_star
    (K r q σ T : ℝ) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    StrictMonoOn (fun S => bsGamma S K r q σ T)
        (Ioc 0 (K * exp (-(r - q + 3 / 2 * σ ^ 2) * T))) ∧
      StrictAntiOn (fun S => bsGamma S K r q σ T)
        (Ici (K * exp (-(r - q + 3 / 2 * σ ^ 2) * T))) := by
  set s := σ * √T with hs
  set m := (r - q + σ ^ 2 / 2) * T with hm
  have hs0 : 0 < s := mul_pos hσ (sqrt_pos.mpr hT)
  have hss : s * s = σ ^ 2 * T := by
    rw [hs]; have := mul_self_sqrt hT.le; nlinarith [this]
  set A := exp (-q * T) * (√(2 * π))⁻¹ / (σ * √T) with hA
  have hA0 : 0 < A := by positivity
  have hstar : 0 < K * exp (-(r - q + 3 / 2 * σ ^ 2) * T) := by positivity
  have hlstar : log (K * exp (-(r - q + 3 / 2 * σ ^ 2) * T)) = log K - m - s * s := by
    rw [log_mul hK.ne' (exp_pos _).ne', log_exp, hss, hm]; ring
  -- the exponent, as a function of `u = log S`
  have key : ∀ a b : ℝ, 0 < a → 0 < b →
      (bsGamma a K r q σ T < bsGamma b K r q σ T ↔
        (log b - log a) * (log a + log b - 2 * log K + 2 * m + 2 * s * s) < 0) := by
    intro a b ha hb
    rw [bsGamma_eq a K r q σ T ha hK, bsGamma_eq b K r q σ T hb hK, ← hs, ← hm,
      mul_lt_mul_iff_right₀ hA0, exp_lt_exp]
    have e : ∀ u : ℝ, -((u - log K + m) / s) ^ 2 / 2 - u
        = -((u - log K + m) ^ 2 + 2 * s * s * u) / (2 * (s * s)) := by
      intro u; field_simp; ring
    rw [e, e, div_lt_div_iff_of_pos_right (by positivity)]
    constructor <;> intro h <;> nlinarith [h]
  constructor
  · intro a ha b hb hab
    have ha0 : 0 < a := ha.1
    have hb0 : 0 < b := hb.1
    rw [key a b ha0 hb0]
    have h1 : log a < log b := log_lt_log ha0 hab
    have h2 : log b ≤ log K - m - s * s := by
      rw [← hlstar]; exact log_le_log hb0 hb.2
    have h3 : 0 < -(log a + log b - 2 * log K + 2 * m + 2 * s * s) := by linarith
    nlinarith [mul_pos (sub_pos.mpr h1) h3]
  · intro a ha b hb hab
    have ha0 : 0 < a := lt_of_lt_of_le hstar ha
    have hb0 : 0 < b := ha0.trans hab
    rw [key b a hb0 ha0]
    have h1 : log a < log b := log_lt_log ha0 hab
    have h2 : log K - m - s * s ≤ log a := by
      rw [← hlstar]; exact log_le_log hstar ha
    have h3 : 0 < log b + log a - 2 * log K + 2 * m + 2 * s * s := by linarith
    nlinarith [mul_pos (sub_pos.mpr h1) h3]

/-- **Gamma at the strike explodes near expiry** (When it holds, "Time is left"). With the share
at the strike, `S = K > 0`, volatility `σ > 0` and any rates `r`, `q`, gamma grows without limit
as the time left `T` shrinks to zero. -/
theorem gamma_at_strike_unbounded_near_expiry
    (K r q σ : ℝ) (hK : 0 < K) (hσ : 0 < σ) :
    Tendsto (fun T => bsGamma K K r q σ T) (𝓝[>] 0) atTop := by
  let f : ℝ → ℝ := fun T => exp (-q * T) * stdNormalPDF ((r - q + σ ^ 2 / 2) * √T / σ) / (K * σ)
  have hf : Continuous f := by
    have := stdPDF_continuous
    fun_prop (disch := exact (mul_pos hK hσ).ne')
  have hf0 : 0 < f 0 := by
    have := stdPDF_pos ((r - q + σ ^ 2 / 2) * √0 / σ)
    simp only [f]; positivity
  have hlim : Tendsto f (𝓝[>] 0) (𝓝 (f 0)) := (hf.tendsto 0).mono_left nhdsWithin_le_nhds
  have hsq : Tendsto (fun T : ℝ => √T) (𝓝[>] 0) (𝓝[>] 0) := by
    rw [tendsto_nhdsWithin_iff]
    refine ⟨?_, ?_⟩
    · have := (continuous_sqrt.tendsto 0).mono_left (nhdsWithin_le_nhds (s := Ioi (0:ℝ)))
      simpa using this
    · filter_upwards [self_mem_nhdsWithin] with T hT
      exact sqrt_pos.mpr hT
  have hinv := tendsto_inv_nhdsGT_zero.comp hsq
  refine (hlim.pos_mul_atTop hf0 hinv).congr' ?_
  filter_upwards [self_mem_nhdsWithin] with T hT
  have hT' : (0:ℝ) < T := hT
  have hsT : 0 < √T := sqrt_pos.mpr hT'
  have hTT : √T * √T = T := mul_self_sqrt hT'.le
  have hd : bsD1 K K r q σ T = (r - q + σ ^ 2 / 2) * √T / σ := by
    rw [bsD1, div_self hK.ne', log_one, zero_add, div_eq_div_iff (by positivity) hσ.ne']
    linear_combination (-((r - q + σ ^ 2 / 2) * σ)) * hTT
  simp only [Function.comp_def, f, bsGamma, hd]
  field_simp

-- Acme: S = K = 100, r = 5/100, q = 2/100, σ = 1/5, T = 1 year.
-- d₁ = (ln 1 + (0.05 - 0.02 + 0.02) · 1) / 0.20 = 0.25.
example : bsD1 100 100 (5 / 100) (2 / 100) (1 / 5) 1 = 1 / 4 := by
  rw [bsD1]; norm_num
-- d₂ = d₁ - σ√T = 0.25 - 0.20 = 0.05.
example : bsD1 100 100 (5 / 100) (2 / 100) (1 / 5) 1 - 1 / 5 * √1 = 1 / 20 := by
  rw [bsD1]; norm_num
-- The dollar wiggle S σ √T = 100 × 0.20 × 1 = 20.
example : (100 : ℝ) * (1 / 5) * √1 = 20 := by
  norm_num
-- The drift allowance in d₁: 0 + 0.15 + 0.10 = 0.25.
example : (0 : ℚ) + 3 / 20 + 1 / 10 = 1 / 4 := by norm_num

#print axioms gamma_is_second_derivative_same_for_call_and_put
#print axioms gamma_peaks_at_S_star
#print axioms gamma_at_strike_unbounded_near_expiry
