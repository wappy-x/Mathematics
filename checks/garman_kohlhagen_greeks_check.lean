-- The Greeks of a currency option: in the Garman-Kohlhagen model the call's slopes in spot, the dollar rate and the euro rate are e^(-r_f T) N(d₁), +T K e^(-r_d T) N(d₂) and -T S e^(-r_f T) N(d₁), a bank counting in euros hedges with Δ - C/S euros, gamma and vega are the bell-curve height at d₁ scaled, and moving both rates together changes the price at -T C.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt

open Real MeasureTheory ProbabilityTheory

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- `φ(x)`: the bell curve's height at `x`, the standard normal density. -/
noncomputable def stdNormalPDF (x : ℝ) : ℝ := gaussianPDFReal 0 1 x

/-- The card's `d₁ = (ln(S/K) + (r_d - r_f + σ²/2) T) / (σ√T)`; then `d₂ = d₁ - σ√T`.
Spot `S` and strike `K` in dollars per euro, dollar rate `rd`, euro rate `rf`, volatility `σ`,
years to expiry `T`. -/
noncomputable def gkD1 (S K rd rf σ T : ℝ) : ℝ :=
  (log (S / K) + (rd - rf + σ ^ 2 / 2) * T) / (σ * √T)

/-- The Garman-Kohlhagen EUR call / USD put, in dollars per euro of notional:
`C = S e^(-r_f T) N(d₁) - K e^(-r_d T) N(d₂)`. -/
noncomputable def gkCall (S K rd rf σ T : ℝ) : ℝ :=
  S * exp (-rf * T) * stdNormalCDF (gkD1 S K rd rf σ T)
    - K * exp (-rd * T) * stdNormalCDF (gkD1 S K rd rf σ T - σ * √T)

lemma stdNormalPDF_eq (x : ℝ) : stdNormalPDF x = (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := by
  simp [stdNormalPDF, gaussianPDFReal]

lemma stdNormalPDF_pos (x : ℝ) : 0 < stdNormalPDF x :=
  gaussianPDFReal_pos 0 1 x one_ne_zero

lemma continuous_stdNormalPDF : Continuous stdNormalPDF := by
  have : stdNormalPDF = fun x => (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := funext stdNormalPDF_eq
  rw [this]; fun_prop

lemma stdNormalCDF_eq_integral (x : ℝ) : stdNormalCDF x = ∫ t in Set.Iic x, stdNormalPDF t := by
  unfold stdNormalCDF stdNormalPDF
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (integral_nonneg fun _ => gaussianPDFReal_nonneg _ _ _)]

lemma stdNormalCDF_eq_add (x : ℝ) :
    stdNormalCDF x = stdNormalCDF 0 + ∫ t in (0 : ℝ)..x, stdNormalPDF t := by
  have hi := intervalIntegral.integral_Iic_sub_Iic (f := stdNormalPDF) (a := 0) (b := x)
    (μ := volume) (integrable_gaussianPDFReal 0 1).integrableOn
    (integrable_gaussianPDFReal 0 1).integrableOn
  rw [stdNormalCDF_eq_integral, stdNormalCDF_eq_integral]
  linarith

lemma hasDerivAt_stdNormalCDF (x : ℝ) : HasDerivAt stdNormalCDF (stdNormalPDF x) x := by
  have h := intervalIntegral.integral_hasDerivAt_right
    (continuous_stdNormalPDF.intervalIntegrable 0 x)
    continuous_stdNormalPDF.aestronglyMeasurable.stronglyMeasurableAtFilter
    continuous_stdNormalPDF.continuousAt
  have h2 := h.const_add (stdNormalCDF 0)
  have : stdNormalCDF = fun x => stdNormalCDF 0 + ∫ t in (0 : ℝ)..x, stdNormalPDF t :=
    funext stdNormalCDF_eq_add
  rw [this]; exact h2

lemma stdNormalCDF_strictMono : StrictMono stdNormalCDF :=
  strictMono_of_hasDerivAt_pos hasDerivAt_stdNormalCDF stdNormalPDF_pos

lemma stdNormalCDF_pos (x : ℝ) : 0 < stdNormalCDF x :=
  lt_of_le_of_lt (cdf_nonneg _ (x - 1)) (stdNormalCDF_strictMono (by linarith))

lemma stdNormalPDF_shift (x u : ℝ) :
    exp (u * x + u ^ 2 / 2) * stdNormalPDF (x + u) = stdNormalPDF x := by
  rw [stdNormalPDF_eq, stdNormalPDF_eq, mul_left_comm, ← exp_add]
  congr 2; ring

/-- The call-price positivity core: `e^(u x + u²/2) N(x + u) > N(x)` for `u > 0`. -/
lemma shifted_cdf_gap_pos (u : ℝ) (hu : 0 < u) (x : ℝ) :
    0 < exp (u * x + u ^ 2 / 2) * stdNormalCDF (x + u) - stdNormalCDF x := by
  set G : ℝ → ℝ := fun y => exp (u * y + u ^ 2 / 2) * stdNormalCDF (y + u) - stdNormalCDF y
    with hG
  have hderiv : ∀ y, HasDerivAt G (u * exp (u * y + u ^ 2 / 2) * stdNormalCDF (y + u)) y := by
    intro y
    have h1 : HasDerivAt (fun y => exp (u * y + u ^ 2 / 2)) (exp (u * y + u ^ 2 / 2) * u) y := by
      have := (((hasDerivAt_id y).const_mul u).add_const (u ^ 2 / 2)).exp
      simpa using this
    have h2 : HasDerivAt (fun y => stdNormalCDF (y + u)) (stdNormalPDF (y + u)) y := by
      convert (hasDerivAt_stdNormalCDF (y + u)).comp y ((hasDerivAt_id y).add_const u) using 1
      · rfl
      · simp
    have h3 := (h1.mul h2).sub (hasDerivAt_stdNormalCDF y)
    refine h3.congr_deriv ?_
    have := stdNormalPDF_shift y u
    linear_combination this
  have hmono : StrictMono G :=
    strictMono_of_hasDerivAt_pos hderiv fun y => by
      have := stdNormalCDF_pos (y + u); positivity
  have hlim : Filter.Tendsto G Filter.atBot (nhds 0) := by
    have he : Filter.Tendsto (fun y => exp (u * y + u ^ 2 / 2)) Filter.atBot (nhds 0) := by
      refine tendsto_exp_atBot.comp ?_
      exact Filter.tendsto_atBot_add_const_right _ _
        (Filter.Tendsto.const_mul_atBot hu Filter.tendsto_id)
    have hp : Filter.Tendsto (fun y => exp (u * y + u ^ 2 / 2) * stdNormalCDF (y + u))
        Filter.atBot (nhds 0) := by
      refine tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds he ?_ ?_
      · intro y; have := stdNormalCDF_pos (y + u); positivity
      · intro y
        have h1 : stdNormalCDF (y + u) ≤ 1 := cdf_le_one _ _
        have h2 := exp_pos (u * y + u ^ 2 / 2)
        simpa using mul_le_mul_of_nonneg_left h1 h2.le
    have hN : Filter.Tendsto stdNormalCDF Filter.atBot (nhds 0) := tendsto_cdf_atBot _
    simpa using hp.sub hN
  have h0 : 0 ≤ G (x - 1) := hmono.monotone.le_of_tendsto hlim (x - 1)
  have := hmono (show x - 1 < x by linarith)
  exact lt_of_le_of_lt h0 this

/-- The identity behind the Greeks: `S e^(-r_f T) φ(d₁) = K e^(-r_d T) φ(d₂)`. -/
lemma gk_pdf_identity (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    S * exp (-rf * T) * stdNormalPDF (gkD1 S K rd rf σ T)
      = K * exp (-rd * T) * stdNormalPDF (gkD1 S K rd rf σ T - σ * √T) := by
  set d := gkD1 S K rd rf σ T with hd
  have hsq : √T ^ 2 = T := Real.sq_sqrt hT.le
  have hsT : 0 < √T := Real.sqrt_pos.mpr hT
  have hu : σ * √T ≠ 0 := by positivity
  have hdu : d * (σ * √T) = log (S / K) + (rd - rf + σ ^ 2 / 2) * T := by
    rw [hd, gkD1]; field_simp
  have hexp : -(d - σ * √T) ^ 2 / 2 = -d ^ 2 / 2 + (log (S / K) + (rd - rf) * T) := by
    linear_combination hdu - (σ ^ 2 / 2) * hsq
  have hlog : exp (log (S / K)) = S / K := exp_log (by positivity)
  have hrt : exp (-rd * T) * exp ((rd - rf) * T) = exp (-rf * T) := by
    rw [← exp_add]; ring_nf
  rw [stdNormalPDF_eq, stdNormalPDF_eq, hexp, exp_add, exp_add, hlog, ← hrt]
  field_simp

/-- Product and chain rule for `a N(d) - b N(d - u)` when `a φ(d) = b φ(d - u)`: the terms in the
slope of `d` cancel, leaving `a' N(d) - b' N(d - u) + a φ(d) u'`. -/
lemma gk_hasDerivAt_generic {a b d u : ℝ → ℝ} {p a' b' u' : ℝ} (ha : HasDerivAt a a' p)
    (hb : HasDerivAt b b' p) (hd : DifferentiableAt ℝ d p) (hu : HasDerivAt u u' p)
    (hid : a p * stdNormalPDF (d p) = b p * stdNormalPDF (d p - u p)) :
    HasDerivAt (fun q => a q * stdNormalCDF (d q) - b q * stdNormalCDF (d q - u q))
      (a' * stdNormalCDF (d p) - b' * stdNormalCDF (d p - u p) + a p * stdNormalPDF (d p) * u')
      p := by
  obtain ⟨D, hD⟩ : ∃ D, HasDerivAt d D p := ⟨_, hd.hasDerivAt⟩
  have h1 := ha.mul ((hasDerivAt_stdNormalCDF (d p)).comp p hD)
  have h2 := hb.mul ((hasDerivAt_stdNormalCDF (d p - u p)).comp p (hD.sub hu))
  convert h1.sub h2 using 1
  · rfl
  · simp only [Function.comp_apply, Pi.sub_apply]
    linear_combination (u' - D) * hid

lemma gkCall_pos (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    0 < gkCall S K rd rf σ T := by
  set d := gkD1 S K rd rf σ T with hd
  set u := σ * √T with hu
  have hsq : √T ^ 2 = T := Real.sq_sqrt hT.le
  have hsT : 0 < √T := Real.sqrt_pos.mpr hT
  have hupos : 0 < u := by positivity
  have hid := gk_pdf_identity S K rd rf σ T hS hK hσ hT
  rw [← hd, ← hu] at hid
  -- `S e^(-r_f T) = K e^(-r_d T) e^(u d₂ + u²/2)`
  have hshift := stdNormalPDF_shift (d - u) u
  rw [sub_add_cancel] at hshift
  have hA : S * exp (-rf * T) = K * exp (-rd * T) * exp (u * (d - u) + u ^ 2 / 2) := by
    have hp := stdNormalPDF_pos d
    apply mul_right_cancel₀ hp.ne'
    rw [hid, ← hshift]; ring
  have hgap := shifted_cdf_gap_pos u hupos (d - u)
  rw [sub_add_cancel] at hgap
  have : gkCall S K rd rf σ T
      = K * exp (-rd * T) * (exp (u * (d - u) + u ^ 2 / 2) * stdNormalCDF d - stdNormalCDF (d - u)) := by
    rw [gkCall, ← hd, ← hu, hA]; ring
  rw [this]; positivity

lemma gkD1_hasDerivAt_spot (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ)
    (hT : 0 < T) :
    HasDerivAt (fun x => gkD1 x K rd rf σ T) (1 / (S * σ * √T)) S := by
  have hsT : 0 < √T := Real.sqrt_pos.mpr hT
  have h := ((((hasDerivAt_id S).div_const K).log (by simp only [id]; positivity)).add_const
    ((rd - rf + σ ^ 2 / 2) * T)).div_const (σ * √T)
  refine h.congr_deriv ?_
  simp only [id]
  field_simp

lemma gk_delta (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun x => gkCall x K rd rf σ T)
      (exp (-rf * T) * stdNormalCDF (gkD1 S K rd rf σ T)) S := by
  have h := gk_hasDerivAt_generic (a := fun x => x * exp (-rf * T))
    (b := fun _ => K * exp (-rd * T)) (d := fun x => gkD1 x K rd rf σ T)
    (u := fun _ => σ * √T) (u' := 0) ((hasDerivAt_id S).mul_const _) (hasDerivAt_const _ _)
    (gkD1_hasDerivAt_spot S K rd rf σ T hS hK hσ hT).differentiableAt (hasDerivAt_const _ _)
    (gk_pdf_identity S K rd rf σ T hS hK hσ hT)
  refine h.congr_deriv ?_
  simp

#print axioms stdNormalPDF_eq
#print axioms stdNormalPDF_pos
#print axioms continuous_stdNormalPDF
#print axioms stdNormalCDF_eq_integral
#print axioms stdNormalCDF_eq_add
#print axioms hasDerivAt_stdNormalCDF
#print axioms stdNormalCDF_strictMono
#print axioms stdNormalCDF_pos
#print axioms stdNormalPDF_shift
#print axioms shifted_cdf_gap_pos
#print axioms gk_pdf_identity
#print axioms gk_hasDerivAt_generic
#print axioms gkCall_pos
#print axioms gkD1_hasDerivAt_spot
#print axioms gk_delta

/-- **Delta in euros, two rhos of opposite sign, and the euro-counted hedge** (the card's main
claim; Why it works, Steps 2, 4 and 6). In the Garman-Kohlhagen model (one constant volatility
`σ > 0`, flat constant rates `rd` and `rf`, European exercise), with spot `S > 0`, strike `K > 0`
and `T > 0` years left, each input moved alone:
* the call's slope in spot is `Δ = e^(-r_f T) N(d₁)`;
* its slope in the dollar rate is `ρ_d = T K e^(-r_d T) N(d₂)`, which is positive;
* its slope in the euro rate is `ρ_f = -T S e^(-r_f T) N(d₁)`, which is negative;
* the same option valued in euros, `C/S`, has slope `Δ/S - C/S²` in spot, so a bank counting in
  euros hedges with `Δ - C/S` euros per euro of notional, which equals `(K/S) e^(-r_d T) N(d₂)`
  and is fewer than `Δ` by exactly the premium in euros, `C/S > 0`. -/
theorem gk_delta_two_rhos_opposite_signs_and_euro_counted_hedge
    (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun x => gkCall x K rd rf σ T)
        (exp (-rf * T) * stdNormalCDF (gkD1 S K rd rf σ T)) S ∧
      HasDerivAt (fun x => gkCall S K x rf σ T)
        (T * K * exp (-rd * T) * stdNormalCDF (gkD1 S K rd rf σ T - σ * √T)) rd ∧
      HasDerivAt (fun y => gkCall S K rd y σ T)
        (-(T * S * exp (-rf * T) * stdNormalCDF (gkD1 S K rd rf σ T))) rf ∧
      0 < T * K * exp (-rd * T) * stdNormalCDF (gkD1 S K rd rf σ T - σ * √T) ∧
      -(T * S * exp (-rf * T) * stdNormalCDF (gkD1 S K rd rf σ T)) < 0 ∧
      HasDerivAt (fun x => gkCall x K rd rf σ T / x)
        (exp (-rf * T) * stdNormalCDF (gkD1 S K rd rf σ T) / S
          - gkCall S K rd rf σ T / S ^ 2) S ∧
      exp (-rf * T) * stdNormalCDF (gkD1 S K rd rf σ T) - gkCall S K rd rf σ T / S
        = K / S * exp (-rd * T) * stdNormalCDF (gkD1 S K rd rf σ T - σ * √T) ∧
      0 < gkCall S K rd rf σ T / S := by
  have hsT : 0 < √T := Real.sqrt_pos.mpr hT
  have hid := gk_pdf_identity S K rd rf σ T hS hK hσ hT
  have hΔ := gk_delta S K rd rf σ T hS hK hσ hT
  have hN1 := stdNormalCDF_pos (gkD1 S K rd rf σ T)
  have hN2 := stdNormalCDF_pos (gkD1 S K rd rf σ T - σ * √T)
  refine ⟨hΔ, ?_, ?_, by positivity, ?_, ?_, ?_, div_pos (gkCall_pos S K rd rf σ T hS hK hσ hT) hS⟩
  · have h := gk_hasDerivAt_generic (a := fun _ => S * exp (-rf * T))
      (b := fun x => K * exp (-x * T)) (d := fun x => gkD1 S K x rf σ T)
      (u := fun _ => σ * √T) (u' := 0) (hasDerivAt_const _ _)
      ((((hasDerivAt_id rd).neg.mul_const T).exp).const_mul K)
      (by unfold gkD1; fun_prop (disch := positivity)) (hasDerivAt_const _ _) hid
    refine h.congr_deriv ?_
    simp only [Pi.neg_apply, id]; ring
  · have h := gk_hasDerivAt_generic (a := fun y => S * exp (-y * T))
      (b := fun _ => K * exp (-rd * T)) (d := fun y => gkD1 S K rd y σ T)
      (u := fun _ => σ * √T) (u' := 0)
      ((((hasDerivAt_id rf).neg.mul_const T).exp).const_mul S) (hasDerivAt_const _ _)
      (by unfold gkD1; fun_prop (disch := positivity)) (hasDerivAt_const _ _) hid
    refine h.congr_deriv ?_
    simp only [Pi.neg_apply, id]; ring
  · have : 0 < T * S * exp (-rf * T) * stdNormalCDF (gkD1 S K rd rf σ T) := by positivity
    linarith
  · refine (hΔ.div (hasDerivAt_id S) hS.ne').congr_deriv ?_
    simp only [id]
    field_simp
  · unfold gkCall
    field_simp
    ring

/-- **Gamma, vega and theta** (The formula; Why it works, Steps 1, 2, 3 and 5). Under the same
terms: the slope of delta in spot is `Γ = e^(-r_f T) φ(d₁) / (S σ √T)`; the call's slope in the
volatility is `𝒱 = S e^(-r_f T) φ(d₁) √T`; its slope in the years to expiry is minus theta,
where `Θ = -S e^(-r_f T) φ(d₁) σ / (2√T) + r_f S e^(-r_f T) N(d₁) - r_d K e^(-r_d T) N(d₂)`;
and the identity behind all three, `S e^(-r_f T) φ(d₁) = K e^(-r_d T) φ(d₂)`, holds. -/
theorem gk_gamma_vega_theta
    (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (deriv fun x => gkCall x K rd rf σ T)
        (exp (-rf * T) * stdNormalPDF (gkD1 S K rd rf σ T) / (S * σ * √T)) S ∧
      HasDerivAt (fun v => gkCall S K rd rf v T)
        (S * exp (-rf * T) * stdNormalPDF (gkD1 S K rd rf σ T) * √T) σ ∧
      HasDerivAt (fun t => gkCall S K rd rf σ t)
        (-(-(S * exp (-rf * T) * stdNormalPDF (gkD1 S K rd rf σ T) * σ / (2 * √T))
            + rf * S * exp (-rf * T) * stdNormalCDF (gkD1 S K rd rf σ T)
            - rd * K * exp (-rd * T) * stdNormalCDF (gkD1 S K rd rf σ T - σ * √T))) T ∧
      S * exp (-rf * T) * stdNormalPDF (gkD1 S K rd rf σ T)
        = K * exp (-rd * T) * stdNormalPDF (gkD1 S K rd rf σ T - σ * √T) := by
  have hsT : 0 < √T := Real.sqrt_pos.mpr hT
  have hid := gk_pdf_identity S K rd rf σ T hS hK hσ hT
  refine ⟨?_, ?_, ?_, hid⟩
  · have hev : (deriv fun x => gkCall x K rd rf σ T)
        =ᶠ[nhds S] fun x => exp (-rf * T) * stdNormalCDF (gkD1 x K rd rf σ T) :=
      (eventually_gt_nhds hS).mono fun x hx => (gk_delta x K rd rf σ T hx hK hσ hT).deriv
    have h := ((hasDerivAt_stdNormalCDF (gkD1 S K rd rf σ T)).comp S
      (gkD1_hasDerivAt_spot S K rd rf σ T hS hK hσ hT)).const_mul (exp (-rf * T))
    refine (h.congr_of_eventuallyEq hev).congr_deriv ?_
    field_simp
  · have h := gk_hasDerivAt_generic (a := fun _ => S * exp (-rf * T))
      (b := fun _ => K * exp (-rd * T)) (d := fun v => gkD1 S K rd rf v T)
      (u := fun v => v * √T) (hasDerivAt_const _ _) (hasDerivAt_const _ _)
      (by unfold gkD1; fun_prop (disch := positivity)) ((hasDerivAt_id σ).mul_const _) hid
    refine h.congr_deriv ?_
    ring
  · have h := gk_hasDerivAt_generic (a := fun t => S * exp (-rf * t))
      (b := fun t => K * exp (-rd * t)) (d := fun t => gkD1 S K rd rf σ t)
      (u := fun t => σ * √t)
      ((((hasDerivAt_id T).const_mul (-rf)).exp).const_mul S)
      ((((hasDerivAt_id T).const_mul (-rd)).exp).const_mul K)
      (by unfold gkD1; fun_prop (disch := positivity))
      ((Real.hasDerivAt_sqrt hT.ne').const_mul σ) hid
    refine h.congr_deriv ?_
    simp only [id]
    field_simp
    ring

/-- **Both rates up together** (Why it works, Step 4, last paragraph). Under the same terms,
raising the dollar rate and the euro rate by the same step `h` moves the call at the slope
`ρ_d + ρ_f = -T C`: minus the years to expiry times the call's own price. -/
theorem gk_parallel_rate_move_slope_eq_neg_time_mul_price
    (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun h => gkCall S K (rd + h) (rf + h) σ T)
      (-(T * gkCall S K rd rf σ T)) 0 := by
  have hid := gk_pdf_identity S K rd rf σ T hS hK hσ hT
  have h := gk_hasDerivAt_generic (a := fun h => S * exp (-(rf + h) * T))
    (b := fun h => K * exp (-(rd + h) * T)) (d := fun h => gkD1 S K (rd + h) (rf + h) σ T)
    (u := fun _ => σ * √T) (u' := 0)
    (((((hasDerivAt_id (0 : ℝ)).const_add rf).neg.mul_const T).exp).const_mul S)
    (((((hasDerivAt_id (0 : ℝ)).const_add rd).neg.mul_const T).exp).const_mul K)
    (by unfold gkD1; fun_prop (disch := positivity)) (hasDerivAt_const _ _)
    (by simpa only [add_zero] using hid)
  refine h.congr_deriv ?_
  simp only [add_zero, id, Pi.neg_apply, gkCall]
  ring

-- House market: S = K = 1.10, r_d = 5%, r_f = 3%, σ = 10%, T = 1 year.
-- d₁ = (0 + (0.05 - 0.03 + 0.005) · 1) / 0.10 = 0.25.
example : gkD1 (11 / 10) (11 / 10) (5 / 100) (3 / 100) (1 / 10) 1 = 1 / 4 := by
  unfold gkD1; norm_num
-- d₂ = 0.25 - 0.10 = 0.15.
example : gkD1 (11 / 10) (11 / 10) (5 / 100) (3 / 100) (1 / 10) 1 - 1 / 10 * √1 = 3 / 20 := by
  unfold gkD1; norm_num
-- The printed rhos add to minus the printed premium (T = 1): 0.585557 - 0.639113 = -0.053556.
example : (585557 : ℤ) - 639113 = -53556 := by decide
-- The euro-counted hedge: 0.581012 - 0.048687 = 0.532325.
example : (581012 : ℕ) - 48687 = 532325 := by decide

#print axioms gk_delta_two_rhos_opposite_signs_and_euro_counted_hedge
#print axioms gk_gamma_vega_theta
#print axioms gk_parallel_rate_move_slope_eq_neg_time_mul_price
