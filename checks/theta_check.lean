-- Theta: in the Black–Scholes model the slope of the call and put prices against the calendar, share price frozen, is a volatility term plus two carry terms, net of carry it is exactly minus one half σ²S² times gamma, and with a dividend yield at most zero and a rate at least zero the call's theta is negative.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open MeasureTheory ProbabilityTheory Real

/-! The model: `N(x)` is Mathlib's `cdf (gaussianReal 0 1) x`, the area under the standard
bell curve to the left of `x`, and `φ(x)` is Mathlib's `gaussianPDFReal 0 1 x`, its height.
Share price `S`, strike `K`, riskless rate `r`, dividend yield `q`, volatility `σ`, time left
`T` in years. `d1 = (log (S / K) + (r - q + σ² / 2) T) / (σ √T)` and `d2 = d1 - σ √T`.
Theta is the slope of the price against today's date `t`, with expiry fixed at date `E`, so
the time left is `T = E - t`; every other input is held still. -/

/-- `d1 = (log (S / K) + (r - q + σ² / 2) T) / (σ √T)`. -/
noncomputable def bsD1 (S K r q σ T : ℝ) : ℝ :=
  (log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)

/-- The Black–Scholes call `C = S e^(-qT) N(d1) - K e^(-rT) N(d2)`. -/
noncomputable def bsCall (S K r q σ T : ℝ) : ℝ :=
  S * exp (-(q * T)) * cdf (gaussianReal 0 1) (bsD1 S K r q σ T) -
    K * exp (-(r * T)) * cdf (gaussianReal 0 1) (bsD1 S K r q σ T - σ * √T)

/-- The Black–Scholes put `P = K e^(-rT) N(-d2) - S e^(-qT) N(-d1)`. -/
noncomputable def bsPut (S K r q σ T : ℝ) : ℝ :=
  K * exp (-(r * T)) * cdf (gaussianReal 0 1) (-(bsD1 S K r q σ T - σ * √T)) -
    S * exp (-(q * T)) * cdf (gaussianReal 0 1) (-(bsD1 S K r q σ T))

/-- The card's call theta formula:
`-S e^(-qT) φ(d1) σ / (2 √T) + q S e^(-qT) N(d1) - r K e^(-rT) N(d2)`. -/
noncomputable def callTheta (S K r q σ T : ℝ) : ℝ :=
  -(S * exp (-(q * T)) * gaussianPDFReal 0 1 (bsD1 S K r q σ T) * σ / (2 * √T)) +
    q * S * exp (-(q * T)) * cdf (gaussianReal 0 1) (bsD1 S K r q σ T) -
    r * K * exp (-(r * T)) * cdf (gaussianReal 0 1) (bsD1 S K r q σ T - σ * √T)

/-- The card's put theta formula:
`-S e^(-qT) φ(d1) σ / (2 √T) - q S e^(-qT) N(-d1) + r K e^(-rT) N(-d2)`. -/
noncomputable def putTheta (S K r q σ T : ℝ) : ℝ :=
  -(S * exp (-(q * T)) * gaussianPDFReal 0 1 (bsD1 S K r q σ T) * σ / (2 * √T)) -
    q * S * exp (-(q * T)) * cdf (gaussianReal 0 1) (-(bsD1 S K r q σ T)) +
    r * K * exp (-(r * T)) * cdf (gaussianReal 0 1) (-(bsD1 S K r q σ T - σ * √T))

lemma theta_Ncdf_eq_integral (x : ℝ) :
    cdf (gaussianReal 0 1) x = ∫ y in Set.Iic x, gaussianPDFReal 0 1 y := by
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Iic
      (fun y _ => gaussianPDFReal_nonneg _ _ _))]

lemma theta_continuous_pdf : Continuous (gaussianPDFReal 0 1) := by
  unfold gaussianPDFReal; fun_prop

lemma theta_hasDerivAt_Ncdf (x : ℝ) :
    HasDerivAt (fun y => cdf (gaussianReal 0 1) y) (gaussianPDFReal 0 1 x) x := by
  have hI : ∀ a : ℝ, MeasureTheory.IntegrableOn (gaussianPDFReal 0 1) (Set.Iic a) :=
    fun a => (integrable_gaussianPDFReal 0 1).integrableOn
  have heq : (fun y => cdf (gaussianReal 0 1) y) =
      fun y => (∫ z in Set.Iic 0, gaussianPDFReal 0 1 z) + ∫ z in (0:ℝ)..y, gaussianPDFReal 0 1 z := by
    funext y
    rw [theta_Ncdf_eq_integral, ← intervalIntegral.integral_Iic_sub_Iic (hI 0) (hI y)]
    ring
  rw [heq]
  exact ((theta_continuous_pdf.integral_hasStrictDerivAt 0 x).hasDerivAt).const_add _

lemma theta_pdf_neg (x : ℝ) : gaussianPDFReal 0 1 (-x) = gaussianPDFReal 0 1 x := by
  simp [gaussianPDFReal]

lemma theta_key (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    K * exp (-(r * T)) * gaussianPDFReal 0 1 (bsD1 S K r q σ T - σ * √T) =
      S * exp (-(q * T)) * gaussianPDFReal 0 1 (bsD1 S K r q σ T) := by
  have ha : 0 < σ * √T := mul_pos hσ (sqrt_pos.2 hT)
  have hdd : bsD1 S K r q σ T * (σ * √T) = log (S / K) + (r - q + σ ^ 2 / 2) * T := by
    rw [bsD1]; field_simp
  set d := bsD1 S K r q σ T
  have hsq : (√T) ^ 2 = T := sq_sqrt hT.le
  have hSK : 0 < S / K := div_pos hS hK
  have hexp : -(r * T) + -(d - σ * √T) ^ 2 / 2 = log (S / K) + -(q * T) + -d ^ 2 / 2 := by
    linear_combination hdd - σ ^ 2 / 2 * hsq
  simp only [gaussianPDFReal, NNReal.coe_one, mul_one, sub_zero]
  set c := (√(2 * π))⁻¹
  calc K * exp (-(r * T)) * (c * exp (-(d - σ * √T) ^ 2 / 2))
      = c * K * exp (-(r * T) + -(d - σ * √T) ^ 2 / 2) := by rw [exp_add]; ring
    _ = c * K * exp (log (S / K) + -(q * T) + -d ^ 2 / 2) := by rw [hexp]
    _ = S * exp (-(q * T)) * (c * exp (-d ^ 2 / 2)) := by
      rw [exp_add, exp_add, exp_log hSK]; field_simp

lemma theta_hasDerivAt_d1_T (S K r q σ T : ℝ) (hσ : 0 < σ) (hT : 0 < T) :
    ∃ d', HasDerivAt (fun x => bsD1 S K r q σ x) d' T := by
  have ha : σ * √T ≠ 0 := (mul_pos hσ (sqrt_pos.2 hT)).ne'
  have hnum : HasDerivAt (fun x => log (S / K) + (r - q + σ ^ 2 / 2) * x)
      ((r - q + σ ^ 2 / 2) * 1) T := ((hasDerivAt_id' T).const_mul _).const_add _
  have hden : HasDerivAt (fun x => σ * √x) (σ * (1 / (2 * √T))) T :=
    (hasDerivAt_sqrt hT.ne').const_mul σ
  exact ⟨_, hnum.div hden ha⟩

lemma theta_call_dT (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun x => bsCall S K r q σ x) (-callTheta S K r q σ T) T := by
  obtain ⟨d', hd⟩ := theta_hasDerivAt_d1_T S K r q σ T hσ hT
  have hden : HasDerivAt (fun x => σ * √x) (σ * (1 / (2 * √T))) T :=
    (hasDerivAt_sqrt hT.ne').const_mul σ
  have h1 := ((((hasDerivAt_id' T).const_mul q).neg.exp).const_mul S).mul
    ((theta_hasDerivAt_Ncdf _).comp T hd)
  have h2 := ((((hasDerivAt_id' T).const_mul r).neg.exp).const_mul K).mul
    ((theta_hasDerivAt_Ncdf _).comp T (hd.sub hden))
  have key := theta_key S K r q σ T hS hK hσ hT
  have h : HasDerivAt (fun x => bsCall S K r q σ x) _ T := h1.sub h2
  refine h.congr_deriv ?_
  simp only [callTheta, Function.comp_apply, Pi.neg_apply, Pi.sub_apply]
  linear_combination (-(d' - σ * (1 / (2 * √T)))) * key

lemma theta_put_dT (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun x => bsPut S K r q σ x) (-putTheta S K r q σ T) T := by
  obtain ⟨d', hd⟩ := theta_hasDerivAt_d1_T S K r q σ T hσ hT
  have hden : HasDerivAt (fun x => σ * √x) (σ * (1 / (2 * √T))) T :=
    (hasDerivAt_sqrt hT.ne').const_mul σ
  have h1 := ((((hasDerivAt_id' T).const_mul r).neg.exp).const_mul K).mul
    ((theta_hasDerivAt_Ncdf _).comp T (hd.sub hden).neg)
  have h2 := ((((hasDerivAt_id' T).const_mul q).neg.exp).const_mul S).mul
    ((theta_hasDerivAt_Ncdf _).comp T hd.neg)
  have key := theta_key S K r q σ T hS hK hσ hT
  have h : HasDerivAt (fun x => bsPut S K r q σ x) _ T := h1.sub h2
  refine h.congr_deriv ?_
  simp only [putTheta, Function.comp_apply, Pi.neg_apply, Pi.sub_apply]
  simp only [theta_pdf_neg]
  linear_combination (-(d' - σ * (1 / (2 * √T)))) * key

lemma theta_hasDerivAt_d1_S (s K r q σ T : ℝ) (hs : 0 < s) (hK : 0 < K) (hσ : 0 < σ)
    (hT : 0 < T) :
    HasDerivAt (fun x => bsD1 x K r q σ T) (1 / (s * (σ * √T))) s := by
  have ha : 0 < σ * √T := mul_pos hσ (sqrt_pos.2 hT)
  have h := ((((hasDerivAt_id' s).div_const K).log (div_pos hs hK).ne').add_const
    ((r - q + σ ^ 2 / 2) * T)).div_const (σ * √T)
  refine h.congr_deriv ?_
  field_simp

lemma theta_call_dS (s K r q σ T : ℝ) (hs : 0 < s) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun x => bsCall x K r q σ T)
      (exp (-(q * T)) * cdf (gaussianReal 0 1) (bsD1 s K r q σ T)) s := by
  have hd := theta_hasDerivAt_d1_S s K r q σ T hs hK hσ hT
  have h1 := ((hasDerivAt_id' s).mul_const (exp (-(q * T)))).mul
    ((theta_hasDerivAt_Ncdf _).comp s hd)
  have h2 := ((theta_hasDerivAt_Ncdf _).comp s (hd.sub_const (σ * √T))).const_mul
    (K * exp (-(r * T)))
  have key := theta_key s K r q σ T hs hK hσ hT
  have h : HasDerivAt (fun x => bsCall x K r q σ T) _ s := h1.sub h2
  refine h.congr_deriv ?_
  simp only [Function.comp_apply]
  linear_combination (-(1 / (s * (σ * √T)))) * key

lemma theta_put_dS (s K r q σ T : ℝ) (hs : 0 < s) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun x => bsPut x K r q σ T)
      (-(exp (-(q * T)) * cdf (gaussianReal 0 1) (-bsD1 s K r q σ T))) s := by
  have hd := theta_hasDerivAt_d1_S s K r q σ T hs hK hσ hT
  have h1 := ((theta_hasDerivAt_Ncdf _).comp s (hd.sub_const (σ * √T)).neg).const_mul
    (K * exp (-(r * T)))
  have h2 := ((hasDerivAt_id' s).mul_const (exp (-(q * T)))).mul
    ((theta_hasDerivAt_Ncdf _).comp s hd.neg)
  have key := theta_key s K r q σ T hs hK hσ hT
  have h : HasDerivAt (fun x => bsPut x K r q σ T) _ s := h1.sub h2
  refine h.congr_deriv ?_
  simp only [Function.comp_apply, Pi.neg_apply]
  simp only [theta_pdf_neg]
  linear_combination (-(1 / (s * (σ * √T)))) * key

#print axioms theta_Ncdf_eq_integral
#print axioms theta_continuous_pdf
#print axioms theta_hasDerivAt_Ncdf
#print axioms theta_pdf_neg
#print axioms theta_key
#print axioms theta_hasDerivAt_d1_T
#print axioms theta_call_dT
#print axioms theta_put_dT
#print axioms theta_hasDerivAt_d1_S
#print axioms theta_call_dS
#print axioms theta_put_dS

/-- Theta (the formula, Steps 0 to 4): in the Black–Scholes world, with a positive share price
and strike, positive volatility, and today's date `t` before the expiry date `E`, hold the share
price, rate, dividend yield and volatility still and move only the calendar. Then the call
price has slope against the date equal to the volatility term plus the two carry terms,
`-S e^(-qT) φ(d1) σ / (2 √T) + q S e^(-qT) N(d1) - r K e^(-rT) N(d2)` with `T = E - t`, and the
European put has slope `-S e^(-qT) φ(d1) σ / (2 √T) - q S e^(-qT) N(-d1) + r K e^(-rT) N(-d2)`. -/
theorem theta_eq_volatility_term_plus_carry_terms
    (S K r q σ E t : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (ht : t < E) :
    HasDerivAt (fun u : ℝ => bsCall S K r q σ (E - u)) (callTheta S K r q σ (E - t)) t ∧
      HasDerivAt (fun u : ℝ => bsPut S K r q σ (E - u)) (putTheta S K r q σ (E - t)) t := by
  have hT : 0 < E - t := sub_pos.2 ht
  exact ⟨((theta_call_dT S K r q σ (E - t) hS hK hσ hT).comp_const_sub E t).congr_deriv (neg_neg _),
    ((theta_put_dT S K r q σ (E - t) hS hK hσ hT).comp_const_sub E t).congr_deriv (neg_neg _)⟩

/-- Theta is the rent on gamma (Step 5): with a positive share price and strike, positive
volatility and positive time left, write delta `Δ` and gamma `Γ` for the first and second
slopes of the price against the share price. Then for the call and for the put the
Black–Scholes equation `Θ + (r - q) S Δ + ½ σ² S² Γ = r V` holds, so theta net of carry,
`Θ - [r V - (r - q) S Δ]`, is `-½ σ² S² Γ`; and that rent, `½ σ² S² Γ`, is exactly the size
of the volatility term, `S e^(-qT) φ(d1) σ / (2 √T)`. -/
theorem theta_net_of_carry_is_rent_on_gamma
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    callTheta S K r q σ T + (r - q) * S * deriv (fun s : ℝ => bsCall s K r q σ T) S +
        σ ^ 2 * S ^ 2 / 2 * deriv (deriv (fun s : ℝ => bsCall s K r q σ T)) S =
      r * bsCall S K r q σ T ∧
    putTheta S K r q σ T + (r - q) * S * deriv (fun s : ℝ => bsPut s K r q σ T) S +
        σ ^ 2 * S ^ 2 / 2 * deriv (deriv (fun s : ℝ => bsPut s K r q σ T)) S =
      r * bsPut S K r q σ T ∧
    σ ^ 2 * S ^ 2 / 2 * deriv (deriv (fun s : ℝ => bsCall s K r q σ T)) S =
      S * exp (-(q * T)) * gaussianPDFReal 0 1 (bsD1 S K r q σ T) * σ / (2 * √T) ∧
    σ ^ 2 * S ^ 2 / 2 * deriv (deriv (fun s : ℝ => bsPut s K r q σ T)) S =
      S * exp (-(q * T)) * gaussianPDFReal 0 1 (bsD1 S K r q σ T) * σ / (2 * √T) := by
  have hsT : 0 < √T := sqrt_pos.2 hT
  have hd := theta_hasDerivAt_d1_S S K r q σ T hS hK hσ hT
  have hgc : deriv (deriv (fun s : ℝ => bsCall s K r q σ T)) S =
      exp (-(q * T)) * gaussianPDFReal 0 1 (bsD1 S K r q σ T) * (1 / (S * (σ * √T))) := by
    have hev : deriv (fun s : ℝ => bsCall s K r q σ T) =ᶠ[nhds S]
        fun s => exp (-(q * T)) * cdf (gaussianReal 0 1) (bsD1 s K r q σ T) := by
      filter_upwards [Ioi_mem_nhds hS] with s hs
      exact (theta_call_dS s K r q σ T hs hK hσ hT).deriv
    rw [hev.deriv_eq]
    have h := ((theta_hasDerivAt_Ncdf _).comp S hd).const_mul (exp (-(q * T)))
    have h' : HasDerivAt (fun s => exp (-(q * T)) * cdf (gaussianReal 0 1) (bsD1 s K r q σ T)) _ S :=
      h
    rw [h'.deriv]
    ring
  have hgp : deriv (deriv (fun s : ℝ => bsPut s K r q σ T)) S =
      exp (-(q * T)) * gaussianPDFReal 0 1 (bsD1 S K r q σ T) * (1 / (S * (σ * √T))) := by
    have hev : deriv (fun s : ℝ => bsPut s K r q σ T) =ᶠ[nhds S]
        fun s => -(exp (-(q * T)) * cdf (gaussianReal 0 1) (-bsD1 s K r q σ T)) := by
      filter_upwards [Ioi_mem_nhds hS] with s hs
      exact (theta_put_dS s K r q σ T hs hK hσ hT).deriv
    rw [hev.deriv_eq]
    have h := (((theta_hasDerivAt_Ncdf _).comp S hd.neg).const_mul (exp (-(q * T)))).neg
    have h' : HasDerivAt
        (fun s => -(exp (-(q * T)) * cdf (gaussianReal 0 1) (-bsD1 s K r q σ T))) _ S := h
    rw [h'.deriv]
    simp only [Pi.neg_apply, theta_pdf_neg]
    ring
  have hvc : σ ^ 2 * S ^ 2 / 2 * deriv (deriv (fun s : ℝ => bsCall s K r q σ T)) S =
      S * exp (-(q * T)) * gaussianPDFReal 0 1 (bsD1 S K r q σ T) * σ / (2 * √T) := by
    rw [hgc]
    field_simp
  have hvp : σ ^ 2 * S ^ 2 / 2 * deriv (deriv (fun s : ℝ => bsPut s K r q σ T)) S =
      S * exp (-(q * T)) * gaussianPDFReal 0 1 (bsD1 S K r q σ T) * σ / (2 * √T) := by
    rw [hgp]
    field_simp
  refine ⟨?_, ?_, hvc, hvp⟩
  · rw [hvc, (theta_call_dS S K r q σ T hS hK hσ hT).deriv]
    simp only [callTheta, bsCall]
    ring
  · rw [hvp, (theta_put_dS S K r q σ T hS hK hσ hT).deriv]
    simp only [putTheta, bsPut]
    ring

/-- The call's sign (Detailed proof, "The call's sign"): with a positive share price and
strike, positive volatility and positive time left, if the dividend yield is at most zero and
the rate is at least zero, the call's theta is strictly negative. A positive call theta needs
a positive dividend yield. -/
theorem call_theta_neg_of_no_dividend_yield
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (hq : q ≤ 0) (hr : 0 ≤ r) :
    callTheta S K r q σ T < 0 := by
  have hA : 0 < S * exp (-(q * T)) * gaussianPDFReal 0 1 (bsD1 S K r q σ T) * σ / (2 * √T) := by
    have := gaussianPDFReal_pos 0 1 (bsD1 S K r q σ T) one_ne_zero
    have := sqrt_pos.2 hT
    positivity
  have hB : 0 ≤ -q * S * exp (-(q * T)) * cdf (gaussianReal 0 1) (bsD1 S K r q σ T) :=
    mul_nonneg (mul_nonneg (mul_nonneg (neg_nonneg.2 hq) hS.le) (exp_pos _).le) (cdf_nonneg _ _)
  have hC : 0 ≤ r * K * exp (-(r * T)) * cdf (gaussianReal 0 1) (bsD1 S K r q σ T - σ * √T) :=
    mul_nonneg (mul_nonneg (mul_nonneg hr hK.le) (exp_pos _).le) (cdf_nonneg _ _)
  unfold callTheta
  linarith

/-! The card's worked numbers that are exact fractions, for Acme:
S = 100, K = 100, r = 5/100, q = 2/100, σ = 1/5, T = 1. -/

-- d1 = (ln(100/100) + 0.05) / (0.20 × √1) = 0.25.
example : bsD1 100 100 (5 / 100) (2 / 100) (1 / 5) 1 = 1 / 4 := by
  norm_num [bsD1]

-- d2 = d1 - σ √T = 0.25 - 0.20 = 0.05.
example : bsD1 100 100 (5 / 100) (2 / 100) (1 / 5) 1 - 1 / 5 * √1 = 1 / 20 := by
  norm_num [bsD1]

-- At T = 1 the denominator 2 √T of the volatility term is 2: the √T hides, the 2 does not.
example : 2 * √(1 : ℝ) = 2 := by norm_num

#print axioms theta_eq_volatility_term_plus_carry_terms
#print axioms theta_net_of_carry_is_rent_on_gamma
#print axioms call_theta_neg_of_no_dividend_yield
