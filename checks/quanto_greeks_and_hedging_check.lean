-- Hedging a quanto: the quanto call's dollar delta is X̄ e^((μ - r_d)T) N(d₁), a hedge of V_S / X shares funded by a loan of their euro value matches the call's slopes in the share and the exchange rate, the correlation, currency-volatility and euro-rate Greeks are that delta position seen through the drift μ = r_f - q - ρ σ_S σ_X, gamma, share vega and dollar rho take the stated forms, and the price solves the Black-Scholes equation with dividend yield r_d - μ.
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

/-- The quanto drift `μ = r_f - q - ρ σ_S σ_X`: euro rate `rf`, dividend yield `q`,
share volatility `σS`, currency volatility `σX`, correlation `ρ`. -/
def quantoDrift (rf q σS σX ρ : ℝ) : ℝ := rf - q - ρ * σS * σX

/-- The cut-off `d₁ = (ln(S/K) + (μ + σ_S²/2) T) / (σ_S √T)`; then `d₂ = d₁ - σ_S √T`. -/
noncomputable def quantoD1 (S K μ σS T : ℝ) : ℝ :=
  (log (S / K) + (μ + σS ^ 2 / 2) * T) / (σS * √T)

/-- The quanto call's price in dollars (from the card "Quanto option"):
`V = X̄ e^(-r_d T) [S e^(μT) N(d₁) - K N(d₂)]`, share `S` and strike `K` in euros, fixed rate `Xbar`
in dollars per euro, dollar rate `rd`, euro rate `rf`, dividend yield `q`, volatilities `σS`, `σX`,
correlation `ρ`, years to expiry `T`. Today's exchange rate is not an input. -/
noncomputable def quantoCall (S K Xbar rd rf q σS σX ρ T : ℝ) : ℝ :=
  Xbar * exp (-rd * T) *
    (S * exp (quantoDrift rf q σS σX ρ * T) *
        stdNormalCDF (quantoD1 S K (quantoDrift rf q σS σX ρ) σS T)
      - K * stdNormalCDF (quantoD1 S K (quantoDrift rf q σS σX ρ) σS T - σS * √T))

lemma qg_stdNormalPDF_eq (x : ℝ) : stdNormalPDF x = (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := by
  simp [stdNormalPDF, gaussianPDFReal]

lemma qg_continuous_stdNormalPDF : Continuous stdNormalPDF := by
  have : stdNormalPDF = fun x => (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := funext qg_stdNormalPDF_eq
  rw [this]; fun_prop

lemma qg_stdNormalCDF_eq_integral (x : ℝ) :
    stdNormalCDF x = ∫ t in Set.Iic x, stdNormalPDF t := by
  unfold stdNormalCDF stdNormalPDF
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (integral_nonneg fun _ => gaussianPDFReal_nonneg _ _ _)]

lemma qg_stdNormalCDF_eq_add (x : ℝ) :
    stdNormalCDF x = stdNormalCDF 0 + ∫ t in (0 : ℝ)..x, stdNormalPDF t := by
  have hi := intervalIntegral.integral_Iic_sub_Iic (f := stdNormalPDF) (a := 0) (b := x)
    (μ := volume) (integrable_gaussianPDFReal 0 1).integrableOn
    (integrable_gaussianPDFReal 0 1).integrableOn
  rw [qg_stdNormalCDF_eq_integral, qg_stdNormalCDF_eq_integral]
  linarith

lemma qg_hasDerivAt_stdNormalCDF (x : ℝ) : HasDerivAt stdNormalCDF (stdNormalPDF x) x := by
  have h := intervalIntegral.integral_hasDerivAt_right
    (qg_continuous_stdNormalPDF.intervalIntegrable 0 x)
    qg_continuous_stdNormalPDF.aestronglyMeasurable.stronglyMeasurableAtFilter
    qg_continuous_stdNormalPDF.continuousAt
  have h2 := h.const_add (stdNormalCDF 0)
  have : stdNormalCDF = fun x => stdNormalCDF 0 + ∫ t in (0 : ℝ)..x, stdNormalPDF t :=
    funext qg_stdNormalCDF_eq_add
  rw [this]; exact h2

/-- The identity behind the Greeks: `S e^(μT) φ(d₁) = K φ(d₂)`. -/
lemma qg_pdf_identity (S K μ σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    S * exp (μ * T) * stdNormalPDF (quantoD1 S K μ σ T)
      = K * stdNormalPDF (quantoD1 S K μ σ T - σ * √T) := by
  set d := quantoD1 S K μ σ T with hd
  have hsq : √T ^ 2 = T := Real.sq_sqrt hT.le
  have hsT : 0 < √T := Real.sqrt_pos.mpr hT
  have hu : σ * √T ≠ 0 := by positivity
  have hdu : d * (σ * √T) = log (S / K) + (μ + σ ^ 2 / 2) * T := by
    rw [hd, quantoD1]; field_simp
  have hexp : -(d - σ * √T) ^ 2 / 2 = -d ^ 2 / 2 + (log (S / K) + μ * T) := by
    linear_combination hdu - (σ ^ 2 / 2) * hsq
  have hlog : exp (log (S / K)) = S / K := exp_log (by positivity)
  rw [qg_stdNormalPDF_eq, qg_stdNormalPDF_eq, hexp, exp_add, exp_add, hlog]
  field_simp

/-- Product and chain rule for `a N(d) - b N(d - u)` when `a φ(d) = b φ(d - u)`: the terms in the
slope of `d` cancel, leaving `a' N(d) - b' N(d - u) + a φ(d) u'`. -/
lemma qg_hasDerivAt_generic {a b d u : ℝ → ℝ} {p a' b' u' : ℝ} (ha : HasDerivAt a a' p)
    (hb : HasDerivAt b b' p) (hd : DifferentiableAt ℝ d p) (hu : HasDerivAt u u' p)
    (hid : a p * stdNormalPDF (d p) = b p * stdNormalPDF (d p - u p)) :
    HasDerivAt (fun q => a q * stdNormalCDF (d q) - b q * stdNormalCDF (d q - u q))
      (a' * stdNormalCDF (d p) - b' * stdNormalCDF (d p - u p) + a p * stdNormalPDF (d p) * u')
      p := by
  obtain ⟨D, hD⟩ : ∃ D, HasDerivAt d D p := ⟨_, hd.hasDerivAt⟩
  have h1 := ha.mul ((qg_hasDerivAt_stdNormalCDF (d p)).comp p hD)
  have h2 := hb.mul ((qg_hasDerivAt_stdNormalCDF (d p - u p)).comp p (hD.sub hu))
  convert h1.sub h2 using 1
  · rfl
  · simp only [Function.comp_apply, Pi.sub_apply]
    linear_combination (u' - D) * hid

lemma qg_d1_hasDerivAt_spot (S K μ σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ)
    (hT : 0 < T) :
    HasDerivAt (fun x => quantoD1 x K μ σ T) (1 / (S * σ * √T)) S := by
  have hsT : 0 < √T := Real.sqrt_pos.mpr hT
  have h := ((((hasDerivAt_id S).div_const K).log (by simp only [id]; positivity)).add_const
    ((μ + σ ^ 2 / 2) * T)).div_const (σ * √T)
  refine h.congr_deriv ?_
  simp only [id]
  field_simp

/-- The dollar delta: `V_S = X̄ e^((μ - r_d)T) N(d₁)`. -/
lemma qg_delta (S K Xbar rd rf q σS σX ρ T : ℝ)
    (hS : 0 < S) (hK : 0 < K) (hσS : 0 < σS) (hT : 0 < T) :
    HasDerivAt (fun s => quantoCall s K Xbar rd rf q σS σX ρ T)
      (Xbar * exp ((quantoDrift rf q σS σX ρ - rd) * T) *
        stdNormalCDF (quantoD1 S K (quantoDrift rf q σS σX ρ) σS T)) S := by
  set μ := quantoDrift rf q σS σX ρ with hμ
  have h := (qg_hasDerivAt_generic (a := fun x => x * exp (μ * T))
    (b := fun _ => K) (d := fun x => quantoD1 x K μ σS T)
    (u := fun _ => σS * √T) (u' := 0) ((hasDerivAt_id S).mul_const _) (hasDerivAt_const _ _)
    (qg_d1_hasDerivAt_spot S K μ σS T hS hK hσS hT).differentiableAt (hasDerivAt_const _ _)
    (qg_pdf_identity S K μ σS T hS hK hσS hT)).const_mul (Xbar * exp (-rd * T))
  have he : exp ((μ - rd) * T) = exp (-rd * T) * exp (μ * T) := by
    rw [← exp_add]; ring_nf
  convert h using 1
  · funext s; rfl
  · rw [he]; ring

#print axioms qg_stdNormalPDF_eq
#print axioms qg_continuous_stdNormalPDF
#print axioms qg_stdNormalCDF_eq_integral
#print axioms qg_stdNormalCDF_eq_add
#print axioms qg_hasDerivAt_stdNormalCDF
#print axioms qg_pdf_identity
#print axioms qg_hasDerivAt_generic
#print axioms qg_d1_hasDerivAt_spot
#print axioms qg_delta


lemma qg_exp_mul {g : ℝ → ℝ} {g' p : ℝ} (S T : ℝ) (hg : HasDerivAt g g' p) :
    HasDerivAt (fun x => S * exp (g x * T)) (S * exp (g p * T) * (g' * T)) p := by
  have := ((hg.mul_const T).exp).const_mul S
  convert this using 1
  ring

lemma qg_drift_rho (rf q σS σX ρ : ℝ) :
    HasDerivAt (fun r => quantoDrift rf q σS σX r) (-(σS * σX)) ρ := by
  have e : (fun r => quantoDrift rf q σS σX r) = fun r => (rf - q) - r * (σS * σX) := by
    funext r; simp only [quantoDrift]; ring
  rw [e]; exact (((hasDerivAt_id' ρ).mul_const _).const_sub _).congr_deriv (by ring)

lemma qg_drift_sigmaX (rf q σS σX ρ : ℝ) :
    HasDerivAt (fun b => quantoDrift rf q σS b ρ) (-(ρ * σS)) σX := by
  have e : (fun b => quantoDrift rf q σS b ρ) = fun b => (rf - q) - b * (ρ * σS) := by
    funext b; simp only [quantoDrift]; ring
  rw [e]; exact (((hasDerivAt_id' σX).mul_const _).const_sub _).congr_deriv (by ring)

lemma qg_drift_sigmaS (rf q σS σX ρ : ℝ) :
    HasDerivAt (fun a => quantoDrift rf q a σX ρ) (-(ρ * σX)) σS := by
  have e : (fun a => quantoDrift rf q a σX ρ) = fun a => (rf - q) - a * (ρ * σX) := by
    funext a; simp only [quantoDrift]; ring
  rw [e]; exact (((hasDerivAt_id' σS).mul_const _).const_sub _).congr_deriv (by ring)

lemma qg_drift_rf (rf q σS σX ρ : ℝ) :
    HasDerivAt (fun f => quantoDrift f q σS σX ρ) 1 rf := by
  have e : (fun f => quantoDrift f q σS σX ρ) = fun f => f - (q + ρ * σS * σX) := by
    funext f; simp only [quantoDrift]; ring
  rw [e]; exact (hasDerivAt_id' rf).sub_const _

#print axioms qg_exp_mul
#print axioms qg_drift_rho
#print axioms qg_drift_sigmaX
#print axioms qg_drift_sigmaS
#print axioms qg_drift_rf

/-- **The hedge, and the Greeks that act through the drift** (the card's main claim; Why it works,
Steps 1, 2 and 4). With share `S > 0`, strike `K > 0`, share volatility `σS > 0`, `T > 0` years
left and today's exchange rate `X > 0` dollars per euro, write `μ = r_f - q - ρ σ_S σ_X` and
`V_S = X̄ e^((μ - r_d)T) N(d₁)`. Then:
* `V_S` is the call's slope in the share price (its dollar delta);
* hold `η = V_S / X` shares and owe `L = η S` euros: the dollar value of this position plus the
  `V` dollars kept, `η s x - L x + V`, has slope `V_S` in the share price, the same as the call,
  and slope `0` in the exchange rate, the same as the call (whose price has no `X` in it);
* the call's slope in the correlation is `V_ρ = -σ_S σ_X T · S V_S`;
* its slope in the currency volatility is `V_{σ_X} = -ρ σ_S T · S V_S`;
* its slope in the euro rate is `V_{r_f} = T · S V_S`. -/
theorem quanto_hedge_and_greeks_through_the_drift
    (S K Xbar rd rf q σS σX ρ T X : ℝ)
    (hS : 0 < S) (hK : 0 < K) (hσS : 0 < σS) (hT : 0 < T) (hX : 0 < X) :
    let μ := quantoDrift rf q σS σX ρ
    let VS := Xbar * exp ((μ - rd) * T) * stdNormalCDF (quantoD1 S K μ σS T)
    let V := quantoCall S K Xbar rd rf q σS σX ρ T
    let η := VS / X
    let L := η * S
    HasDerivAt (fun s => quantoCall s K Xbar rd rf q σS σX ρ T) VS S ∧
      HasDerivAt (fun s => η * s * X - L * X + V) VS S ∧
      HasDerivAt (fun x => η * S * x - L * x + V) 0 X ∧
      HasDerivAt (fun r => quantoCall S K Xbar rd rf q σS σX r T) (-(σS * σX * T * (S * VS))) ρ ∧
      HasDerivAt (fun b => quantoCall S K Xbar rd rf q σS b ρ T) (-(ρ * σS * T * (S * VS))) σX ∧
      HasDerivAt (fun f => quantoCall S K Xbar rd f q σS σX ρ T) (T * (S * VS)) rf := by
  intro μ VS V η L
  have hsT : 0 < √T := Real.sqrt_pos.mpr hT
  have hid := qg_pdf_identity S K μ σS T hS hK hσS hT
  have hΔ : HasDerivAt (fun s => quantoCall s K Xbar rd rf q σS σX ρ T) VS S :=
    qg_delta S K Xbar rd rf q σS σX ρ T hS hK hσS hT
  have he : exp ((μ - rd) * T) = exp (-rd * T) * exp (μ * T) := by
    rw [← exp_add]; ring_nf
  have hVS : VS = Xbar * exp (-rd * T) * exp (μ * T) *
      stdNormalCDF (quantoD1 S K μ σS T) := by
    simp only [VS]; rw [he]; ring
  refine ⟨hΔ, ?_, ?_, ?_, ?_, ?_⟩
  · have h := ((((hasDerivAt_id S).const_mul η).mul_const X).sub_const (L * X)).add_const V
    refine h.congr_deriv ?_
    simp only [η]
    field_simp
  · have h := ((((hasDerivAt_id X).const_mul (η * S)).sub
      ((hasDerivAt_id X).const_mul L))).add_const V
    refine h.congr_deriv ?_
    simp only [L]
    ring
  · have h := (qg_hasDerivAt_generic
      (a := fun r => S * exp (quantoDrift rf q σS σX r * T))
      (b := fun _ => K) (d := fun r => quantoD1 S K (quantoDrift rf q σS σX r) σS T)
      (u := fun _ => σS * √T) (u' := 0)
      (qg_exp_mul S T (qg_drift_rho rf q σS σX ρ))
      (hasDerivAt_const _ _)
      (by unfold quantoD1 quantoDrift; fun_prop (disch := positivity)) (hasDerivAt_const _ _)
      hid).const_mul (Xbar * exp (-rd * T))
    convert h using 1
    · funext r; rfl
    · rw [hVS]; ring
  · have h := (qg_hasDerivAt_generic
      (a := fun b => S * exp (quantoDrift rf q σS b ρ * T))
      (b := fun _ => K) (d := fun b => quantoD1 S K (quantoDrift rf q σS b ρ) σS T)
      (u := fun _ => σS * √T) (u' := 0)
      (qg_exp_mul S T (qg_drift_sigmaX rf q σS σX ρ))
      (hasDerivAt_const _ _)
      (by unfold quantoD1 quantoDrift; fun_prop (disch := positivity)) (hasDerivAt_const _ _)
      hid).const_mul (Xbar * exp (-rd * T))
    convert h using 1
    · funext r; rfl
    · rw [hVS]; ring
  · have h := (qg_hasDerivAt_generic
      (a := fun f => S * exp (quantoDrift f q σS σX ρ * T))
      (b := fun _ => K) (d := fun f => quantoD1 S K (quantoDrift f q σS σX ρ) σS T)
      (u := fun _ => σS * √T) (u' := 0)
      (qg_exp_mul S T (qg_drift_rf rf q σS σX ρ))
      (hasDerivAt_const _ _)
      (by unfold quantoD1 quantoDrift; fun_prop (disch := positivity)) (hasDerivAt_const _ _)
      hid).const_mul (Xbar * exp (-rd * T))
    convert h using 1
    · funext r; rfl
    · rw [hVS]; ring

/-- **Gamma, share vega and dollar rho** (The formula). Under the same terms, with
`F = S e^(μT)` the quanto forward:
* the slope of delta in the share price is `V_SS = X̄ e^((μ - r_d)T) φ(d₁) / (S σ_S √T)`;
* the slope of the price in the share volatility, which both widens the outcomes and slows the
  drift, is `V_{σ_S} = X̄ e^(-r_d T) F [√T φ(d₁) - ρ σ_X T N(d₁)]`;
* the slope of the price in the dollar rate is `V_{r_d} = -T V`. -/
theorem quanto_gamma_share_vega_dollar_rho
    (S K Xbar rd rf q σS σX ρ T : ℝ)
    (hS : 0 < S) (hK : 0 < K) (hσS : 0 < σS) (hT : 0 < T) :
    let μ := quantoDrift rf q σS σX ρ
    let d₁ := quantoD1 S K μ σS T
    HasDerivAt (deriv fun s => quantoCall s K Xbar rd rf q σS σX ρ T)
        (Xbar * exp ((μ - rd) * T) * stdNormalPDF d₁ / (S * σS * √T)) S ∧
      HasDerivAt (fun a => quantoCall S K Xbar rd rf q a σX ρ T)
        (Xbar * exp (-rd * T) * (S * exp (μ * T)) *
          (√T * stdNormalPDF d₁ - ρ * σX * T * stdNormalCDF d₁)) σS ∧
      HasDerivAt (fun r => quantoCall S K Xbar r rf q σS σX ρ T)
        (-(T * quantoCall S K Xbar rd rf q σS σX ρ T)) rd := by
  intro μ d₁
  have hsT : 0 < √T := Real.sqrt_pos.mpr hT
  have hid := qg_pdf_identity S K μ σS T hS hK hσS hT
  refine ⟨?_, ?_, ?_⟩
  · have hev : (deriv fun s => quantoCall s K Xbar rd rf q σS σX ρ T)
        =ᶠ[nhds S] fun s => Xbar * exp ((μ - rd) * T) * stdNormalCDF (quantoD1 s K μ σS T) :=
      (eventually_gt_nhds hS).mono fun s hs =>
        (qg_delta s K Xbar rd rf q σS σX ρ T hs hK hσS hT).deriv
    have h := ((qg_hasDerivAt_stdNormalCDF (quantoD1 S K μ σS T)).comp S
      (qg_d1_hasDerivAt_spot S K μ σS T hS hK hσS hT)).const_mul (Xbar * exp ((μ - rd) * T))
    refine (h.congr_of_eventuallyEq hev).congr_deriv ?_
    simp only [d₁]
    field_simp
  · have h := (qg_hasDerivAt_generic
      (a := fun a => S * exp (quantoDrift rf q a σX ρ * T))
      (b := fun _ => K) (d := fun a => quantoD1 S K (quantoDrift rf q a σX ρ) a T)
      (u := fun a => a * √T)
      (qg_exp_mul S T (qg_drift_sigmaS rf q σS σX ρ))
      (hasDerivAt_const _ _)
      (by unfold quantoD1 quantoDrift; fun_prop (disch := positivity))
      ((hasDerivAt_id' σS).mul_const _)
      hid).const_mul (Xbar * exp (-rd * T))
    convert h using 1
    · funext r; rfl
    · simp only [d₁, μ]
      ring
  · have h := ((((hasDerivAt_neg rd).mul_const T).exp).const_mul Xbar).mul_const
      (S * exp (μ * T) * stdNormalCDF d₁ - K * stdNormalCDF (d₁ - σS * √T))
    convert h using 1
    · funext r; rfl
    · simp only [quantoCall, μ, d₁]
      ring

/-- **The price solves the Black-Scholes equation with dividend yield `r_d - μ`** (Why it works,
detailed proof). This is what makes the funded hedge copy the call exactly. Under the same terms,
counting time as years to expiry `τ` (so `∂V/∂t = -∂V/∂τ`), the price's slope in `τ` at `τ = T` is
`μ S V_S + ½ σ_S² S² V_SS - r_d V`; that is,
`∂V/∂t + μ S V_S + ½ σ_S² S² V_SS - r_d V = 0`. -/
theorem quanto_call_solves_black_scholes_equation_with_quanto_drift
    (S K Xbar rd rf q σS σX ρ T : ℝ)
    (hS : 0 < S) (hK : 0 < K) (hσS : 0 < σS) (hT : 0 < T) :
    HasDerivAt (fun τ => quantoCall S K Xbar rd rf q σS σX ρ τ)
      (quantoDrift rf q σS σX ρ * S * deriv (fun s => quantoCall s K Xbar rd rf q σS σX ρ T) S
        + σS ^ 2 / 2 * S ^ 2 * deriv (deriv fun s => quantoCall s K Xbar rd rf q σS σX ρ T) S
        - rd * quantoCall S K Xbar rd rf q σS σX ρ T) T := by
  set μ := quantoDrift rf q σS σX ρ with hμ
  have hsT : 0 < √T := Real.sqrt_pos.mpr hT
  have hid := qg_pdf_identity S K μ σS T hS hK hσS hT
  have hΔ := (qg_delta S K Xbar rd rf q σS σX ρ T hS hK hσS hT).deriv
  have hΓ := ((quanto_gamma_share_vega_dollar_rho S K Xbar rd rf q σS σX ρ T hS hK hσS hT).1).deriv
  rw [hΔ, hΓ]
  have he : exp ((μ - rd) * T) = exp (-rd * T) * exp (μ * T) := by
    rw [← exp_add]; ring_nf
  have hg := qg_hasDerivAt_generic
      (a := fun t => S * exp (μ * t))
      (b := fun _ => K) (d := fun t => quantoD1 S K μ σS t)
      (u := fun t => σS * √t)
      (((hasDerivAt_id T).const_mul μ).exp.const_mul S)
      (hasDerivAt_const _ _)
      (by unfold quantoD1; fun_prop (disch := positivity))
      ((Real.hasDerivAt_sqrt hT.ne').const_mul σS)
      hid
  have h := (((hasDerivAt_id T).const_mul (-rd)).exp.const_mul Xbar).mul hg
  convert h using 1
  · funext t; rfl
  · simp only [quantoCall, ← hμ, id, he]
    field_simp
    ring

-- House quanto: S = K = 100 EUR, r_f = 3%, q = 1%, σ_S = 20%, σ_X = 10%, ρ = 0.30, T = 1.
-- The adjustment ρ σ_S σ_X = 0.30 × 0.20 × 0.10 = 0.006.
example : (3 / 10 : ℝ) * (1 / 5) * (1 / 10) = 6 / 1000 := by norm_num
-- The quanto drift μ = 0.03 - 0.01 - 0.006 = 0.014.
example : quantoDrift (3 / 100) (1 / 100) (1 / 5) (1 / 10) (3 / 10) = 14 / 1000 := by
  unfold quantoDrift; norm_num
-- d₁ = (0 + 0.014 + 0.02) / 0.20 = 0.17.
example : quantoD1 100 100 (14 / 1000) (1 / 5) 1 = 17 / 100 := by
  unfold quantoD1; norm_num
-- d₂ = 0.17 - 0.20 = -0.03.
example : quantoD1 100 100 (14 / 1000) (1 / 5) 1 - 1 / 5 * √1 = -3 / 100 := by
  unfold quantoD1; norm_num
-- The euro loan is the shares times the share price: 0.523627 × 100 = 52.3627 EUR.
example : (523627 : ℕ) * 100 = 52362700 := by decide

#print axioms quanto_hedge_and_greeks_through_the_drift
#print axioms quanto_gamma_share_vega_dollar_rho
#print axioms quanto_call_solves_black_scholes_equation_with_quanto_drift
