-- Vanna: in the Black–Scholes model the cross slope of the call price, taken in share price and volatility in either order, is -e^(-qT) φ(d1) d2 / σ, the put has the same cross slope, and its sign is opposite to d2, turning at the price K e^(-(r - q - σ²/2)T).
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open MeasureTheory ProbabilityTheory Real

lemma vanna_cdf_eq_integral (x : ℝ) :
    cdf (gaussianReal 0 1) x = ∫ t in Set.Iic x, gaussianPDFReal 0 1 t := by
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Iic
      (fun t _ => gaussianPDFReal_nonneg _ _ t))]

lemma vanna_continuous_pdf : Continuous (gaussianPDFReal 0 1) := by
  rw [gaussianPDFReal_def]; fun_prop

lemma vanna_cdf_hasDerivAt (z : ℝ) :
    HasDerivAt (cdf (gaussianReal 0 1)) (gaussianPDFReal 0 1 z) z := by
  have hI : ∀ a, IntegrableOn (gaussianPDFReal 0 1) (Set.Iic a) :=
    fun a => (integrable_gaussianPDFReal 0 1).integrableOn
  have hfun : (cdf (gaussianReal 0 1) : ℝ → ℝ) =
      fun x => cdf (gaussianReal 0 1) 0 + ∫ t in (0:ℝ)..x, gaussianPDFReal 0 1 t := by
    funext x
    rw [← intervalIntegral.integral_Iic_sub_Iic (hI 0) (hI x), vanna_cdf_eq_integral,
      vanna_cdf_eq_integral]
    ring
  rw [hfun]
  exact (intervalIntegral.integral_hasDerivAt_right
    (vanna_continuous_pdf.intervalIntegrable _ _)
    (vanna_continuous_pdf.stronglyMeasurableAtFilter _ _)
    vanna_continuous_pdf.continuousAt).const_add _

lemma vanna_pdf_neg (x : ℝ) : gaussianPDFReal 0 1 (-x) = gaussianPDFReal 0 1 x := by
  simp [gaussianPDFReal_def]

lemma vanna_pdf_hasDerivAt (z : ℝ) :
    HasDerivAt (gaussianPDFReal 0 1) (-z * gaussianPDFReal 0 1 z) z := by
  have h : (gaussianPDFReal 0 1 : ℝ → ℝ) = fun x => (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := by
    funext x; simp [gaussianPDFReal_def]
  rw [h]
  have := (((hasDerivAt_pow 2 z).neg.div_const 2).exp).const_mul (√(2 * π))⁻¹
  convert this using 1
  simp only [Pi.neg_apply]; push_cast; ring

lemma vanna_cdf_neg (z : ℝ) : cdf (gaussianReal 0 1) (-z) = 1 - cdf (gaussianReal 0 1) z := by
  set f : ℝ → ℝ := fun x => cdf (gaussianReal 0 1) x + cdf (gaussianReal 0 1) (-x) with hf
  have hd : ∀ x, HasDerivAt f 0 x := by
    intro x
    have := (vanna_cdf_hasDerivAt x).add ((vanna_cdf_hasDerivAt (-x)).comp x (hasDerivAt_neg x))
    rw [vanna_pdf_neg] at this
    convert this using 1
    · rfl
    · ring
  have hc : ∀ x, f x = f 0 := fun x =>
    is_const_of_deriv_eq_zero (fun y => (hd y).differentiableAt) (fun y => (hd y).deriv) x 0
  have hlim : Filter.Tendsto f Filter.atTop (nhds 1) := by
    have h1 := tendsto_cdf_atTop (μ := gaussianReal 0 1)
    have h2 := (tendsto_cdf_atBot (μ := gaussianReal 0 1)).comp Filter.tendsto_neg_atTop_atBot
    simpa using h1.add h2
  have hconst : Filter.Tendsto f Filter.atTop (nhds (f 0)) := by
    rw [show f = fun _ => f 0 from funext hc]; exact tendsto_const_nhds
  have h0 : f 0 = 1 := tendsto_nhds_unique hconst hlim
  have := hc z
  rw [h0] at this
  simp only [hf] at this
  linarith

lemma vanna_share_cash
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

/-- slope of d1 in volatility -/
lemma vanna_d1_vol (x K r q σ T : ℝ) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun s : ℝ => (log (x / K) + (r - q + s ^ 2 / 2) * T) / (s * √T))
      (-(((log (x / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) - σ * √T) / σ)) σ := by
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  have hsq : √T ^ 2 = T := Real.sq_sqrt hT.le
  have h := ((((hasDerivAt_pow 2 σ).div_const 2).const_add (r - q)).mul_const T
    |>.const_add (log (x / K))).div ((hasDerivAt_id' σ).mul_const √T) (by positivity)
  convert h using 1
  have hσ' := hσ.ne'
  have hs' := hsT.ne'
  field_simp
  have h21 : (2 : ℕ) - 1 = 1 := rfl
  simp only [h21, pow_one, Nat.cast_ofNat]
  linear_combination (2 * σ ^ 2) * hsq

/-- slope of d1 in the share price -/
lemma vanna_d1_spot (x K r q σ T : ℝ) (hx : 0 < x) (hK : 0 < K) :
    HasDerivAt (fun y : ℝ => (log (y / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T))
      (1 / x / (σ * √T)) x := by
  have h := ((((hasDerivAt_id' x).div_const K).log (by positivity)).add_const
    ((r - q + σ ^ 2 / 2) * T)).div_const (σ * √T)
  convert h using 1
  field_simp

/-- the call's delta in closed form -/
lemma vanna_call_delta (x K r q s T : ℝ) (hx : 0 < x) (hK : 0 < K) (hs : 0 < s) (hT : 0 < T) :
    HasDerivAt (fun y : ℝ =>
      y * exp (-(q * T)) *
          cdf (gaussianReal 0 1) ((log (y / K) + (r - q + s ^ 2 / 2) * T) / (s * √T)) -
        K * exp (-(r * T)) *
          cdf (gaussianReal 0 1) ((log (y / K) + (r - q + s ^ 2 / 2) * T) / (s * √T) - s * √T))
      (exp (-(q * T)) *
        cdf (gaussianReal 0 1) ((log (x / K) + (r - q + s ^ 2 / 2) * T) / (s * √T))) x := by
  have hD := vanna_d1_spot x K r q s T hx hK
  have hN1 := (vanna_cdf_hasDerivAt _).comp x hD
  have hN2 := (vanna_cdf_hasDerivAt _).comp x (hD.sub_const (s * √T))
  have hshare := vanna_share_cash x K r q s T hx hK hs hT
  have := (((hasDerivAt_id' x).mul_const (exp (-(q * T)))).mul hN1).sub
    (hN2.const_mul (K * exp (-(r * T))))
  refine this.congr_deriv ?_
  simp only [Function.comp_apply]
  linear_combination (1 / x / (s * √T)) * hshare

/-- the call's vega in closed form -/
lemma vanna_call_vega (x K r q s T : ℝ) (hx : 0 < x) (hK : 0 < K) (hs : 0 < s) (hT : 0 < T) :
    HasDerivAt (fun t : ℝ =>
      x * exp (-(q * T)) *
          cdf (gaussianReal 0 1) ((log (x / K) + (r - q + t ^ 2 / 2) * T) / (t * √T)) -
        K * exp (-(r * T)) *
          cdf (gaussianReal 0 1) ((log (x / K) + (r - q + t ^ 2 / 2) * T) / (t * √T) - t * √T))
      (x * exp (-(q * T)) *
        gaussianPDFReal 0 1 ((log (x / K) + (r - q + s ^ 2 / 2) * T) / (s * √T)) * √T) s := by
  have hD := vanna_d1_vol x K r q s T hs hT
  have hL : HasDerivAt (fun t : ℝ => t * √T) √T s := by
    simpa using (hasDerivAt_id' s).mul_const √T
  have hN1 := (vanna_cdf_hasDerivAt _).comp s hD
  have hN2 := (vanna_cdf_hasDerivAt _).comp s (hD.sub hL)
  have hshare := vanna_share_cash x K r q s T hx hK hs hT
  have := (hN1.const_mul (x * exp (-(q * T)))).sub (hN2.const_mul (K * exp (-(r * T))))
  refine this.congr_deriv ?_
  simp only [Pi.sub_apply]
  linear_combination
    (-(√T + ((log (x / K) + (r - q + s ^ 2 / 2) * T) / (s * √T) - s * √T) / s)) * hshare

/-- put-call parity for the two pricing formulas -/
lemma vanna_parity (x K r q s T : ℝ) :
    K * exp (-(r * T)) *
          cdf (gaussianReal 0 1)
            (-((log (x / K) + (r - q + s ^ 2 / 2) * T) / (s * √T) - s * √T)) -
        x * exp (-(q * T)) *
          cdf (gaussianReal 0 1) (-((log (x / K) + (r - q + s ^ 2 / 2) * T) / (s * √T))) =
      (x * exp (-(q * T)) *
          cdf (gaussianReal 0 1) ((log (x / K) + (r - q + s ^ 2 / 2) * T) / (s * √T)) -
        K * exp (-(r * T)) *
          cdf (gaussianReal 0 1) ((log (x / K) + (r - q + s ^ 2 / 2) * T) / (s * √T) - s * √T))
        + (K * exp (-(r * T)) - x * exp (-(q * T))) := by
  rw [vanna_cdf_neg, vanna_cdf_neg]; ring

#print axioms vanna_cdf_eq_integral
#print axioms vanna_continuous_pdf
#print axioms vanna_cdf_hasDerivAt
#print axioms vanna_pdf_neg
#print axioms vanna_pdf_hasDerivAt
#print axioms vanna_cdf_neg
#print axioms vanna_share_cash
#print axioms vanna_d1_vol
#print axioms vanna_d1_spot
#print axioms vanna_call_delta
#print axioms vanna_call_vega
#print axioms vanna_parity

/-! The model: `N(x)` is Mathlib's `cdf (gaussianReal 0 1) x`, the area under the standard
bell curve to the left of `x`, and `φ(x)` is Mathlib's `gaussianPDFReal 0 1 x`, its height.
Share price `S`, strike `K`, riskless rate `r`, dividend yield `q`, volatility `σ`, years `T`.
`d1 = (log (S / K) + (r - q + σ² / 2) T) / (σ √T)` and `d2 = d1 - σ √T`.
Call `C(S, σ) = S e^(-qT) N(d1) - K e^(-rT) N(d2)`; put `P = K e^(-rT) N(-d2) - S e^(-qT) N(-d1)`.
Delta is the slope of the price in `S`, vega its slope in `σ`, every other input held still.
Vanna is the slope of delta in `σ`, and also the slope of vega in `S`. -/

/-- Vanna (the formula, Steps 0 to 3): with a positive share price and strike, positive
volatility and positive time, the Black–Scholes call's delta, seen as a function of volatility,
has slope `-e^(-qT) φ(d1) d2 / σ` at `σ`; and its vega, seen as a function of the share price,
has the very same slope at `S`. -/
theorem call_vanna_eq_delta_slope_in_vol_eq_vega_slope_in_spot
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    let C : ℝ → ℝ → ℝ := fun x s =>
      x * exp (-(q * T)) *
          cdf (gaussianReal 0 1) ((log (x / K) + (r - q + s ^ 2 / 2) * T) / (s * √T)) -
        K * exp (-(r * T)) *
          cdf (gaussianReal 0 1) ((log (x / K) + (r - q + s ^ 2 / 2) * T) / (s * √T) - s * √T)
    let vanna : ℝ :=
      -(exp (-(q * T)) *
          gaussianPDFReal 0 1 ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)) *
          (((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) - σ * √T) / σ))
    HasDerivAt (fun s : ℝ => deriv (fun x : ℝ => C x s) S) vanna σ ∧
      HasDerivAt (fun x : ℝ => deriv (fun s : ℝ => C x s) σ) vanna S := by
  intro C vanna
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  constructor
  · have hev : (fun s : ℝ => deriv (fun x : ℝ => C x s) S) =ᶠ[nhds σ] (fun s : ℝ =>
        exp (-(q * T)) *
          cdf (gaussianReal 0 1) ((log (S / K) + (r - q + s ^ 2 / 2) * T) / (s * √T))) := by
      filter_upwards [Ioi_mem_nhds hσ] with s hs
      exact (vanna_call_delta S K r q s T hS hK hs hT).deriv
    have h := ((vanna_cdf_hasDerivAt _).comp σ (vanna_d1_vol S K r q σ T hσ hT)).const_mul
      (exp (-(q * T)))
    refine (h.congr_of_eventuallyEq hev).congr_deriv ?_
    simp only [vanna]; ring
  · have hev : (fun x : ℝ => deriv (fun s : ℝ => C x s) σ) =ᶠ[nhds S] (fun x : ℝ =>
        x * exp (-(q * T)) *
          gaussianPDFReal 0 1 ((log (x / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)) * √T) := by
      filter_upwards [Ioi_mem_nhds hS] with x hx
      exact (vanna_call_vega x K r q σ T hx hK hσ hT).deriv
    have hP := (vanna_pdf_hasDerivAt _).comp S (vanna_d1_spot S K r q σ T hS hK)
    have h := (((hasDerivAt_id' S).mul_const (exp (-(q * T)))).mul hP).mul_const √T
    refine (h.congr_of_eventuallyEq hev).congr_deriv ?_
    simp only [vanna, Function.comp_apply]
    field_simp
    ring

/-- The put's vanna (Step 4): with a positive share price and strike, positive volatility and
positive time, the Black–Scholes put on the same share, strike and date has the same vanna as
the call: its delta moves with volatility, and its vega moves with the share price, at the
rate `-e^(-qT) φ(d1) d2 / σ`. -/
theorem put_vanna_eq_call_vanna
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    let P : ℝ → ℝ → ℝ := fun x s =>
      K * exp (-(r * T)) *
          cdf (gaussianReal 0 1)
            (-((log (x / K) + (r - q + s ^ 2 / 2) * T) / (s * √T) - s * √T)) -
        x * exp (-(q * T)) *
          cdf (gaussianReal 0 1) (-((log (x / K) + (r - q + s ^ 2 / 2) * T) / (s * √T)))
    let vanna : ℝ :=
      -(exp (-(q * T)) *
          gaussianPDFReal 0 1 ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)) *
          (((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) - σ * √T) / σ))
    HasDerivAt (fun s : ℝ => deriv (fun x : ℝ => P x s) S) vanna σ ∧
      HasDerivAt (fun x : ℝ => deriv (fun s : ℝ => P x s) σ) vanna S := by
  intro P vanna
  have hc := call_vanna_eq_delta_slope_in_vol_eq_vega_slope_in_spot S K r q σ T hS hK hσ hT
  obtain ⟨h1, h2⟩ := hc
  have hPC : ∀ x s, P x s = (x * exp (-(q * T)) *
          cdf (gaussianReal 0 1) ((log (x / K) + (r - q + s ^ 2 / 2) * T) / (s * √T)) -
        K * exp (-(r * T)) *
          cdf (gaussianReal 0 1) ((log (x / K) + (r - q + s ^ 2 / 2) * T) / (s * √T) - s * √T))
        + (K * exp (-(r * T)) - x * exp (-(q * T))) := fun x s => vanna_parity x K r q s T
  constructor
  · have hev : (fun s : ℝ => deriv (fun x : ℝ => P x s) S) =ᶠ[nhds σ] (fun s : ℝ =>
        deriv (fun x : ℝ => x * exp (-(q * T)) *
          cdf (gaussianReal 0 1) ((log (x / K) + (r - q + s ^ 2 / 2) * T) / (s * √T)) -
        K * exp (-(r * T)) *
          cdf (gaussianReal 0 1) ((log (x / K) + (r - q + s ^ 2 / 2) * T) / (s * √T) - s * √T))
          S - exp (-(q * T))) := by
      filter_upwards [Ioi_mem_nhds hσ] with s hs
      have hd := vanna_call_delta S K r q s T hS hK hs hT
      have hl : HasDerivAt (fun x : ℝ => K * exp (-(r * T)) - x * exp (-(q * T)))
          (-exp (-(q * T))) S := by
        simpa using ((hasDerivAt_id' S).mul_const (exp (-(q * T)))).const_sub
          (K * exp (-(r * T)))
      have h3 : HasDerivAt (fun x : ℝ => P x s) (exp (-(q * T)) *
          cdf (gaussianReal 0 1) ((log (S / K) + (r - q + s ^ 2 / 2) * T) / (s * √T)) +
          -exp (-(q * T))) S := by
        rw [show (fun x : ℝ => P x s) = _ from funext fun x => hPC x s]
        exact hd.add hl
      rw [h3.deriv, hd.deriv]
      ring
    exact (h1.sub_const (exp (-(q * T)))).congr_of_eventuallyEq hev
  · have hfun : (fun x : ℝ => deriv (fun s : ℝ => P x s) σ) = (fun x : ℝ =>
        deriv (fun s : ℝ => x * exp (-(q * T)) *
          cdf (gaussianReal 0 1) ((log (x / K) + (r - q + s ^ 2 / 2) * T) / (s * √T)) -
        K * exp (-(r * T)) *
          cdf (gaussianReal 0 1) ((log (x / K) + (r - q + s ^ 2 / 2) * T) / (s * √T) - s * √T))
          σ) := by
      funext x
      rw [show (fun s : ℝ => P x s) = _ from funext fun s => hPC x s, deriv_add_const]
    rw [hfun]
    exact h2

/-- The sign of vanna (Step 4): with a positive share price and strike, positive volatility
and positive time, vanna is negative exactly when the share price sits above the crossover
price `K e^(-(r - q - σ²/2)T)`, and positive exactly when it sits below. -/
theorem vanna_sign_flips_at_crossover_price
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    let vanna : ℝ :=
      -(exp (-(q * T)) *
          gaussianPDFReal 0 1 ((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)) *
          (((log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) - σ * √T) / σ))
    (vanna < 0 ↔ K * exp (-((r - q - σ ^ 2 / 2) * T)) < S) ∧
      (0 < vanna ↔ S < K * exp (-((r - q - σ ^ 2 / 2) * T))) := by
  intro vanna
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  have hsq : √T ^ 2 = T := Real.sq_sqrt hT.le
  set d := (log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) with hd
  have hA : 0 < exp (-(q * T)) * gaussianPDFReal 0 1 d :=
    mul_pos (exp_pos _) (gaussianPDFReal_pos 0 1 d one_ne_zero)
  have hv : vanna = -(exp (-(q * T)) * gaussianPDFReal 0 1 d) * ((d - σ * √T) / σ) := by
    simp only [vanna]; ring
  -- d2 > 0 iff S above crossover
  have hd2 : d - σ * √T = (log S - log (K * exp (-((r - q - σ ^ 2 / 2) * T)))) / (σ * √T) := by
    rw [hd, Real.log_mul hK.ne' (exp_pos _).ne', Real.log_exp, Real.log_div hS.ne' hK.ne']
    field_simp
    linear_combination (-2 * σ ^ 2) * hsq
  have hX : 0 < K * exp (-((r - q - σ ^ 2 / 2) * T)) := by positivity
  have key1 : 0 < d - σ * √T ↔ K * exp (-((r - q - σ ^ 2 / 2) * T)) < S := by
    rw [hd2, div_pos_iff_of_pos_right (by positivity), sub_pos, Real.log_lt_log_iff hX hS]
  have key2 : d - σ * √T < 0 ↔ S < K * exp (-((r - q - σ ^ 2 / 2) * T)) := by
    rw [hd2, div_neg_iff, sub_neg, Real.log_lt_log_iff hS hX]
    constructor
    · rintro (⟨_, h⟩ | ⟨h, _⟩)
      · exact absurd h (not_lt.2 (by positivity))
      · exact h
    · intro h; exact Or.inr ⟨h, by positivity⟩
  set A := exp (-(q * T)) * gaussianPDFReal 0 1 d with hAdef
  rw [hv, neg_mul, neg_lt_zero, neg_pos, ← key1, ← key2]
  constructor
  · constructor
    · intro h
      exact (div_pos_iff_of_pos_right hσ).1 (pos_of_mul_pos_right h hA.le)
    · intro h; exact mul_pos hA (div_pos h hσ)
  · constructor
    · intro h
      by_contra hc
      push Not at hc
      linarith [mul_nonneg hA.le (div_nonneg hc hσ.le)]
    · intro h; exact mul_neg_of_pos_of_neg hA (div_neg_of_neg_of_pos h hσ)

/-! The card's worked numbers that are exact fractions, for Acme:
S = 100, K = 100, r = 5/100, q = 2/100, σ = 1/5, T = 1. -/

-- d2 = (ln(100/100) + (0.05 - 0.02 - 0.02) × 1) / 0.20 = 0.05.
example :
    (log ((100 : ℝ) / 100) + (5 / 100 - 2 / 100 + (1 / 5) ^ 2 / 2) * 1) / (1 / 5 * √1) -
        1 / 5 * √1 = 1 / 20 := by
  norm_num

-- d1 = d2 + σ √T = 0.05 + 0.20 = 0.25.
example :
    (log ((100 : ℝ) / 100) + (5 / 100 - 2 / 100 + (1 / 5) ^ 2 / 2) * 1) / (1 / 5 * √1) =
      1 / 4 := by
  norm_num

-- d2 / σ = 0.05 / 0.20 = 0.25.
example : ((1 : ℚ) / 20) / (1 / 5) = 1 / 4 := by norm_num

-- The crossover exponent: (r - q - σ² / 2) T = 0.01, so the crossover is 100 e^(-0.01).
example : ((5 : ℚ) / 100 - 2 / 100 - (1 / 5) ^ 2 / 2) * 1 = 1 / 100 := by norm_num

#print axioms call_vanna_eq_delta_slope_in_vol_eq_vega_slope_in_spot
#print axioms put_vanna_eq_call_vanna
#print axioms vanna_sign_flips_at_crossover_price
