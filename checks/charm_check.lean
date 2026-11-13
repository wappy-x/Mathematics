-- Charm: in the Black-Scholes model the slope of the call's delta against the calendar, share price frozen, is q e^(-qT) N(d₁) - e^(-qT) φ(d₁) (2(r-q)T - d₂σ√T)/(2Tσ√T), the put's charm is that minus q e^(-qT), and charm is also the slope of theta in the share price.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.Deriv.Shift

open MeasureTheory ProbabilityTheory Real

/-! The model: `N(x)` is Mathlib's `cdf (gaussianReal 0 1) x`, the area under the standard
bell curve to the left of `x`, and `φ(x)` is Mathlib's `gaussianPDFReal 0 1 x`, its height.
Share price `S`, strike `K`, riskless rate `r`, dividend yield `q`, volatility `σ`, time left
`T` in years. `d₁ = (log (S / K) + (r - q + σ² / 2) T) / (σ √T)` and `d₂ = d₁ - σ √T`.
Charm is the slope of delta against today's date `t`, with expiry fixed at date `E`, so the
time left is `T = E - t`; the share price, rates and volatility are held still. -/

/-- `d₁ = (log (S / K) + (r - q + σ² / 2) T) / (σ √T)`. -/
noncomputable def bsD1 (S K r q σ T : ℝ) : ℝ :=
  (log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)

/-- `d₂ = d₁ - σ √T`. -/
noncomputable def bsD2 (S K r q σ T : ℝ) : ℝ :=
  bsD1 S K r q σ T - σ * √T

/-- The call's delta, from the delta card: `Δ_C = e^(-qT) N(d₁)`. -/
noncomputable def callDelta (S K r q σ T : ℝ) : ℝ :=
  exp (-(q * T)) * cdf (gaussianReal 0 1) (bsD1 S K r q σ T)

/-- The put's delta, from the delta card: `Δ_P = -e^(-qT) N(-d₁)`. -/
noncomputable def putDelta (S K r q σ T : ℝ) : ℝ :=
  -(exp (-(q * T)) * cdf (gaussianReal 0 1) (-bsD1 S K r q σ T))

/-- The card's call charm formula:
`χ_C = q e^(-qT) N(d₁) - e^(-qT) φ(d₁) (2(r - q)T - d₂ σ √T) / (2T σ √T)`. -/
noncomputable def callCharm (S K r q σ T : ℝ) : ℝ :=
  q * exp (-(q * T)) * cdf (gaussianReal 0 1) (bsD1 S K r q σ T) -
    exp (-(q * T)) * gaussianPDFReal 0 1 (bsD1 S K r q σ T) *
      ((2 * (r - q) * T - bsD2 S K r q σ T * (σ * √T)) / (2 * T * (σ * √T)))

/-- The Black-Scholes call `C = S e^(-qT) N(d₁) - K e^(-rT) N(d₂)`. -/
noncomputable def bsCall (S K r q σ T : ℝ) : ℝ :=
  S * exp (-(q * T)) * cdf (gaussianReal 0 1) (bsD1 S K r q σ T) -
    K * exp (-(r * T)) * cdf (gaussianReal 0 1) (bsD2 S K r q σ T)


lemma charm_phi_eq (x : ℝ) : gaussianPDFReal 0 1 x = (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := by
  simp [gaussianPDFReal]

lemma charm_phi_continuous : Continuous (gaussianPDFReal 0 1) := by
  rw [gaussianPDFReal_def]; fun_prop

lemma charm_phi_neg (x : ℝ) : gaussianPDFReal 0 1 (-x) = gaussianPDFReal 0 1 x := by
  simp [gaussianPDFReal]

lemma charm_N_eq_integral (x : ℝ) :
    cdf (gaussianReal 0 1) x = ∫ t in Set.Iic x, gaussianPDFReal 0 1 t := by
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal]
  exact setIntegral_nonneg measurableSet_Iic (fun t _ => gaussianPDFReal_nonneg _ _ _)

lemma charm_N_sub (a b : ℝ) :
    cdf (gaussianReal 0 1) b - cdf (gaussianReal 0 1) a = ∫ t in a..b, gaussianPDFReal 0 1 t := by
  rw [charm_N_eq_integral, charm_N_eq_integral]
  exact intervalIntegral.integral_Iic_sub_Iic (integrable_gaussianPDFReal 0 1).integrableOn
    (integrable_gaussianPDFReal 0 1).integrableOn

lemma charm_N_hasDerivAt (x : ℝ) :
    HasDerivAt (fun y => cdf (gaussianReal 0 1) y) (gaussianPDFReal 0 1 x) x := by
  have h : (fun y => cdf (gaussianReal 0 1) y) =
      fun y => cdf (gaussianReal 0 1) 0 + ∫ t in (0:ℝ)..y, gaussianPDFReal 0 1 t := by
    funext y; rw [← charm_N_sub]; ring
  rw [h]
  exact (intervalIntegral.integral_hasDerivAt_right (charm_phi_continuous.intervalIntegrable _ _)
    (charm_phi_continuous.stronglyMeasurableAtFilter _ _)
    charm_phi_continuous.continuousAt).const_add _

lemma charm_N_add_N_neg (x : ℝ) :
    cdf (gaussianReal 0 1) x + cdf (gaussianReal 0 1) (-x) = 1 := by
  rw [charm_N_eq_integral, charm_N_eq_integral, ← integral_comp_neg_Ioi]
  simp_rw [charm_phi_neg]
  rw [← Set.compl_Iic, integral_add_compl measurableSet_Iic (integrable_gaussianPDFReal 0 1),
    integral_gaussianPDFReal_eq_one 0 one_ne_zero]

lemma charm_phi_hasDerivAt (x : ℝ) :
    HasDerivAt (fun y => gaussianPDFReal 0 1 y) (-x * gaussianPDFReal 0 1 x) x := by
  have h : (fun y => gaussianPDFReal 0 1 y) = fun y => (√(2 * π))⁻¹ * exp (-y ^ 2 / 2) := by
    funext y; exact charm_phi_eq y
  rw [h, charm_phi_eq]
  have := ((((hasDerivAt_pow 2 x).neg).div_const 2).exp).const_mul (√(2 * π))⁻¹
  refine this.congr_deriv ?_
  simp; ring

/-- `K e^(-rT) φ(d₂) = S e^(-qT) φ(d₁)`. -/
lemma charm_key (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    K * exp (-(r * T)) * gaussianPDFReal 0 1 (bsD2 S K r q σ T)
      = S * exp (-(q * T)) * gaussianPDFReal 0 1 (bsD1 S K r q σ T) := by
  have hs : 0 < σ * √T := mul_pos hσ (Real.sqrt_pos.2 hT)
  have hsq : √T ^ 2 = T := Real.sq_sqrt hT.le
  unfold bsD2
  set d := bsD1 S K r q σ T with hd_def
  have hd : d * (σ * √T) = log (S / K) + (r - q + σ ^ 2 / 2) * T := by
    rw [hd_def, bsD1]; field_simp
  have hexp : -(d - σ * √T) ^ 2 / 2 + -(r * T) = -d ^ 2 / 2 + -(q * T) + log (S / K) := by
    linear_combination hd - (σ ^ 2 / 2) * hsq
  rw [charm_phi_eq, charm_phi_eq]
  rw [show K * exp (-(r * T)) * ((√(2 * π))⁻¹ * exp (-(d - σ * √T) ^ 2 / 2))
      = (√(2 * π))⁻¹ * K * exp (-(d - σ * √T) ^ 2 / 2 + -(r * T)) by rw [exp_add]; ring,
    hexp, exp_add, exp_add, exp_log (div_pos hS hK)]
  field_simp

/-- The slope of `d₁` in the time left. -/
lemma charm_slide (S K r q σ T : ℝ) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun τ : ℝ => bsD1 S K r q σ τ)
      ((2 * (r - q) * T - bsD2 S K r q σ T * (σ * √T)) / (2 * T * (σ * √T))) T := by
  have hw : 0 < √T := Real.sqrt_pos.2 hT
  have hsqrt : HasDerivAt (fun τ => √τ) (1 / (2 * √T)) T := Real.hasDerivAt_sqrt hT.ne'
  have hnum : HasDerivAt (fun τ => log (S / K) + (r - q + σ ^ 2 / 2) * τ)
      (r - q + σ ^ 2 / 2) T := by
    simpa using ((hasDerivAt_id T).const_mul (r - q + σ ^ 2 / 2)).const_add (log (S / K))
  have hden : HasDerivAt (fun τ => σ * √τ) (σ * (1 / (2 * √T))) T := hsqrt.const_mul σ
  have := hnum.div hden (by positivity)
  show HasDerivAt (fun τ => (log (S / K) + (r - q + σ ^ 2 / 2) * τ) / (σ * √τ)) _ T
  refine this.congr_deriv ?_
  have hsq : √T ^ 2 = T := Real.sq_sqrt hT.le
  unfold bsD2 bsD1
  clear this hden hnum hsqrt
  generalize √T = w at hsq hw ⊢
  subst hsq
  field_simp
  ring

/-- The call price's slope in the time left. -/
lemma charm_call_T (s K r q σ T : ℝ) (hs : 0 < s) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun τ : ℝ => bsCall s K r q σ τ)
      (-(q * s * exp (-(q * T)) * cdf (gaussianReal 0 1) (bsD1 s K r q σ T)) +
        r * K * exp (-(r * T)) * cdf (gaussianReal 0 1) (bsD2 s K r q σ T) +
        s * exp (-(q * T)) * gaussianPDFReal 0 1 (bsD1 s K r q σ T) * (σ / (2 * √T))) T := by
  have hd1 := charm_slide s K r q σ T hσ hT
  have hd2 : HasDerivAt (fun τ => bsD2 s K r q σ τ)
      ((2 * (r - q) * T - bsD2 s K r q σ T * (σ * √T)) / (2 * T * (σ * √T)) -
        σ * (1 / (2 * √T))) T :=
    hd1.sub ((Real.hasDerivAt_sqrt hT.ne').const_mul σ)
  have hEq : HasDerivAt (fun τ => exp (-(q * τ))) (exp (-(q * T)) * -(q * 1)) T :=
    (((hasDerivAt_id' T).const_mul q).neg).exp
  have hEr : HasDerivAt (fun τ => exp (-(r * τ))) (exp (-(r * T)) * -(r * 1)) T :=
    (((hasDerivAt_id' T).const_mul r).neg).exp
  have hN1 := (charm_N_hasDerivAt (bsD1 s K r q σ T)).comp T hd1
  have hN2 := (charm_N_hasDerivAt (bsD2 s K r q σ T)).comp T hd2
  have := ((hEq.const_mul s).mul hN1).sub ((hEr.const_mul K).mul hN2)
  refine this.congr_deriv ?_
  simp only [Function.comp_apply]
  have key := charm_key s K r q σ T hs hK hσ hT
  have hφ2 : gaussianPDFReal 0 1 (bsD2 s K r q σ T) =
      s * exp (-(q * T)) * gaussianPDFReal 0 1 (bsD1 s K r q σ T) / (K * exp (-(r * T))) := by
    rw [← key]; field_simp
  rw [hφ2]
  have hw : 0 < √T := Real.sqrt_pos.2 hT
  field_simp
  ring

/-- Theta, written out: the call price's slope against the date. -/
lemma charm_theta (s K r q σ E t : ℝ) (hs : 0 < s) (hK : 0 < K) (hσ : 0 < σ) (ht : t < E) :
    deriv (fun u : ℝ => bsCall s K r q σ (E - u)) t =
      q * exp (-(q * (E - t))) * (s * cdf (gaussianReal 0 1) (bsD1 s K r q σ (E - t))) -
        r * K * exp (-(r * (E - t))) * cdf (gaussianReal 0 1) (bsD2 s K r q σ (E - t)) -
        exp (-(q * (E - t))) * (σ / (2 * √(E - t))) *
          (s * gaussianPDFReal 0 1 (bsD1 s K r q σ (E - t))) := by
  have h := (charm_call_T s K r q σ (E - t) hs hK hσ (sub_pos.2 ht)).comp_const_sub E t
  rw [h.deriv]; ring

/-- The slope of theta's closed form in the share price. -/
lemma charm_theta_slope (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun s : ℝ =>
      q * exp (-(q * T)) * (s * cdf (gaussianReal 0 1) (bsD1 s K r q σ T)) -
        r * K * exp (-(r * T)) * cdf (gaussianReal 0 1) (bsD2 s K r q σ T) -
        exp (-(q * T)) * (σ / (2 * √T)) * (s * gaussianPDFReal 0 1 (bsD1 s K r q σ T)))
      (callCharm S K r q σ T) S := by
  have hl : HasDerivAt (fun s => log (s / K)) (1 / S) S := by
    have := ((hasDerivAt_id' S).div_const K).log (div_pos hS hK).ne'
    refine this.congr_deriv ?_
    field_simp
  have hd1 : HasDerivAt (fun s => bsD1 s K r q σ T) (1 / S / (σ * √T)) S :=
    (hl.add_const ((r - q + σ ^ 2 / 2) * T)).div_const (σ * √T)
  have hd2 : HasDerivAt (fun s => bsD2 s K r q σ T) (1 / S / (σ * √T)) S :=
    hd1.sub_const (σ * √T)
  have hN1 := (charm_N_hasDerivAt (bsD1 S K r q σ T)).comp S hd1
  have hN2 := (charm_N_hasDerivAt (bsD2 S K r q σ T)).comp S hd2
  have hP1 := (charm_phi_hasDerivAt (bsD1 S K r q σ T)).comp S hd1
  have := ((((hasDerivAt_id' S).mul hN1).const_mul (q * exp (-(q * T)))).sub
    (hN2.const_mul (r * K * exp (-(r * T))))).sub
    (((hasDerivAt_id' S).mul hP1).const_mul (exp (-(q * T)) * (σ / (2 * √T))))
  refine this.congr_deriv ?_
  simp only [Function.comp_apply]
  have key := charm_key S K r q σ T hS hK hσ hT
  have hφ2 : gaussianPDFReal 0 1 (bsD2 S K r q σ T) =
      S * exp (-(q * T)) * gaussianPDFReal 0 1 (bsD1 S K r q σ T) / (K * exp (-(r * T))) := by
    rw [← key]; field_simp
  rw [hφ2]
  unfold callCharm bsD2
  have hw : 0 < √T := Real.sqrt_pos.2 hT
  have hsq : √T ^ 2 = T := Real.sq_sqrt hT.le
  clear this hN1 hN2 hP1 hd1 hd2 hl key hφ2
  generalize bsD1 S K r q σ T = d
  generalize √T = w at hsq hw ⊢
  subst hsq
  field_simp
  ring

/-- **Charm, call and put** (The formula; Why it works, Steps 0 to 4). In the Black-Scholes
model, with a positive share price and strike, positive volatility, and today's date `t` before
the expiry date `E`, hold the share price, rates and volatility still and move only the
calendar. Then the call's delta `e^(-qT) N(d₁)`, with `T = E - t`, has slope against the date
`χ_C = q e^(-qT) N(d₁) - e^(-qT) φ(d₁) (2(r - q)T - d₂ σ √T) / (2T σ √T)`, and the put's delta
`-e^(-qT) N(-d₁)` has slope `χ_P = χ_C - q e^(-qT)`. -/
theorem charm_eq_dividend_piece_minus_bell_piece
    (S K r q σ E t : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (ht : t < E) :
    HasDerivAt (fun u : ℝ => callDelta S K r q σ (E - u)) (callCharm S K r q σ (E - t)) t ∧
      HasDerivAt (fun u : ℝ => putDelta S K r q σ (E - u))
        (callCharm S K r q σ (E - t) - q * exp (-(q * (E - t)))) t := by
  have hT := sub_pos.2 ht
  have hd1 := (charm_slide S K r q σ (E - t) hσ hT).comp_const_sub E t
  have hE : HasDerivAt (fun u => exp (-(q * (E - u)))) (q * exp (-(q * (E - t)))) t := by
    have := ((((hasDerivAt_id' t).const_sub E).const_mul q).neg).exp
    refine this.congr_deriv ?_
    simp only [Pi.neg_apply]; ring
  have hN := (charm_N_hasDerivAt _).comp t hd1
  have hC : HasDerivAt (fun u : ℝ => callDelta S K r q σ (E - u))
      (callCharm S K r q σ (E - t)) t := by
    have := hE.mul hN
    refine this.congr_deriv ?_
    simp only [Function.comp_apply]
    unfold callCharm; ring
  refine ⟨hC, ?_⟩
  have hfun : (fun u : ℝ => putDelta S K r q σ (E - u)) =
      fun u => callDelta S K r q σ (E - u) - exp (-(q * (E - u))) := by
    funext u
    unfold putDelta callDelta
    have := charm_N_add_N_neg (bsD1 S K r q σ (E - u))
    linear_combination (-exp (-(q * (E - u)))) * this
  rw [hfun]
  exact hC.sub hE

/-- **The slide** (Step 2 and the detailed proof). With a positive share price and strike,
positive volatility and positive time left, the slope of `d₁` in the time left is
`∂d₁/∂T = (2(r - q)T - d₂ σ √T) / (2T σ √T)`. -/
theorem d1_slide_in_time_left
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun τ : ℝ => bsD1 S K r q σ τ)
      ((2 * (r - q) * T - bsD2 S K r q σ T * (σ * √T)) / (2 * T * (σ * √T))) T := by
  exact charm_slide S K r q σ T hσ hT

/-- **Another door: charm is theta's slope in the share price.** With a positive share price
and strike, positive volatility, and today's date `t` before the expiry date `E`, write theta
for the call price's slope against the date. Then theta's slope in the share price, at `S`, is
the call's charm. -/
theorem charm_eq_slope_of_theta_in_share_price
    (S K r q σ E t : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (ht : t < E) :
    HasDerivAt (fun s : ℝ => deriv (fun u : ℝ => bsCall s K r q σ (E - u)) t)
      (callCharm S K r q σ (E - t)) S := by
  refine (charm_theta_slope S K r q σ (E - t) hS hK hσ (sub_pos.2 ht)).congr_of_eventuallyEq ?_
  filter_upwards [Ioi_mem_nhds hS] with s hs
  exact charm_theta s K r q σ E t hs hK hσ ht

/-! The card's worked numbers that are exact fractions, for the house call:
S = 100, K = 100, r = 5/100, q = 2/100, σ = 1/5, T = 1. -/

-- d₁ = (ln(100/100) + (0.05 - 0.02 + 0.02) × 1) / (0.20 × √1) = 0.25.
example : bsD1 100 100 (5 / 100) (2 / 100) (1 / 5) 1 = 1 / 4 := by
  norm_num [bsD1]

-- d₂ = d₁ - σ√T = 0.25 - 0.20 = 0.05.
example : bsD2 100 100 (5 / 100) (2 / 100) (1 / 5) 1 = 1 / 20 := by
  norm_num [bsD2, bsD1]

-- The slide: (2 × 0.03 × 1 - 0.05 × 0.20) / (2 × 1 × 0.20) = 0.05 / 0.40 = 0.125.
example : ((2 : ℚ) * (5 / 100 - 2 / 100) * 1 - 1 / 20 * (1 / 5)) / (2 * 1 * (1 / 5)) = 1 / 8 := by
  norm_num

#print axioms charm_eq_dividend_piece_minus_bell_piece
#print axioms d1_slide_in_time_left
#print axioms charm_eq_slope_of_theta_in_share_price
#print axioms charm_phi_eq
#print axioms charm_phi_continuous
#print axioms charm_phi_neg
#print axioms charm_N_eq_integral
#print axioms charm_N_sub
#print axioms charm_N_hasDerivAt
#print axioms charm_N_add_N_neg
#print axioms charm_phi_hasDerivAt
#print axioms charm_key
#print axioms charm_slide
#print axioms charm_call_T
#print axioms charm_theta
#print axioms charm_theta_slope
