-- Currency digitals: in Garman-Kohlhagen's lognormal exchange-rate model the dollar digital is e^(-r_d T) N(d₂) and minus the strike slope of the call, the euro digital in euros is e^(-r_f T) N(d₁) and is a plain digital put on the inverted quote, and on a smile each picks up minus vega times the smile's slope.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Probability.HasLaw
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Calculus.Deriv.Basic

open Real MeasureTheory ProbabilityTheory

/-! Notation. `S` is today's EURUSD rate in dollars per euro (the euro is foreign, the dollar
domestic), `K` the strike, `r_d` the dollar rate, `r_f` the euro rate, both continuously
compounded, `σ` the volatility and `T` the years to expiry. `N(x)` is Mathlib's
`cdf (gaussianReal 0 1) x` and `φ(x)` is `gaussianPDFReal 0 1 x`. -/

/-- Garman-Kohlhagen `d₁ = (ln(S/K) + (r_d - r_f + σ²/2) T) / (σ√T)`. -/
noncomputable def gkD1 (S K rd rf σ T : ℝ) : ℝ :=
  (log (S / K) + (rd - rf + σ ^ 2 / 2) * T) / (σ * √T)

/-- Garman-Kohlhagen `d₂ = d₁ - σ√T`. -/
noncomputable def gkD2 (S K rd rf σ T : ℝ) : ℝ :=
  gkD1 S K rd rf σ T - σ * √T

/-- The Garman-Kohlhagen call in dollars per euro: `C = S e^(-r_f T) N(d₁) - K e^(-r_d T) N(d₂)`. -/
noncomputable def gkCall (S K rd rf σ T : ℝ) : ℝ :=
  S * exp (-(rf * T)) * cdf (gaussianReal 0 1) (gkD1 S K rd rf σ T) -
    K * exp (-(rd * T)) * cdf (gaussianReal 0 1) (gkD2 S K rd rf σ T)

/-- Vega, the call's change per 1.00 of volatility: `ν = S e^(-r_f T) φ(d₁) √T`. -/
noncomputable def gkVega (S K rd rf σ T : ℝ) : ℝ :=
  S * exp (-(rf * T)) * gaussianPDFReal 0 1 (gkD1 S K rd rf σ T) * √T

/-- The rate on expiry day in the dollar pricing world, for a standard bell-curve draw `z`:
`S_T = S e^((r_d - r_f - σ²/2) T + σ√T z)`. Read with the rates swapped and `1/S` in place of
`S`, it is the inverted quote in the euro pricing world. -/
noncomputable def fxRateAtExpiry (S rd rf σ T z : ℝ) : ℝ :=
  S * exp ((rd - rf - σ ^ 2 / 2) * T + σ * √T * z)

lemma fxd_cdf_eq_setIntegral (x : ℝ) :
    cdf (gaussianReal 0 1) x = ∫ t in Set.Iic x, gaussianPDFReal 0 1 t := by
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Iic
      (fun t _ => gaussianPDFReal_nonneg _ _ t))]

lemma fxd_continuous_pdf : Continuous (gaussianPDFReal 0 1) := by
  rw [gaussianPDFReal_def]; fun_prop

lemma fxd_hasDerivAt_cdf (x : ℝ) :
    HasDerivAt (cdf (gaussianReal 0 1)) (gaussianPDFReal 0 1 x) x := by
  have hint : ∀ a : ℝ, IntegrableOn (gaussianPDFReal 0 1) (Set.Iic a) :=
    fun a => (integrable_gaussianPDFReal 0 1).integrableOn
  have heq : cdf (gaussianReal 0 1) = fun y =>
      (∫ t in Set.Iic 0, gaussianPDFReal 0 1 t) + ∫ t in (0:ℝ)..y, gaussianPDFReal 0 1 t := by
    funext y
    rw [fxd_cdf_eq_setIntegral, ← intervalIntegral.integral_Iic_sub_Iic (hint 0) (hint y)]
    ring
  rw [heq]
  refine HasDerivAt.const_add _ ?_
  exact intervalIntegral.integral_hasDerivAt_right
    (fxd_continuous_pdf.intervalIntegrable _ _)
    (fxd_continuous_pdf.stronglyMeasurableAtFilter _ _) fxd_continuous_pdf.continuousAt

lemma fxd_measureReal_Ioi (c : ℝ) :
    (gaussianReal 0 1).real (Set.Ioi c) = 1 - cdf (gaussianReal 0 1) c := by
  rw [cdf_eq_real, ← Set.compl_Iic, measureReal_compl measurableSet_Iic, probReal_univ]

lemma fxd_measureReal_Iio (c : ℝ) :
    (gaussianReal 0 1).real (Set.Iio c) = cdf (gaussianReal 0 1) c := by
  have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  rw [cdf_eq_real, measureReal_def, measureReal_def, measure_congr Iio_ae_eq_Iic]

lemma fxd_cdf_neg (x : ℝ) :
    cdf (gaussianReal 0 1) (-x) = 1 - cdf (gaussianReal 0 1) x := by
  rw [← fxd_measureReal_Ioi, ← fxd_measureReal_Iio]
  have h := gaussianReal_map_neg (μ := 0) (v := 1)
  rw [neg_zero] at h
  conv_rhs => rw [← h]
  rw [map_measureReal_apply measurable_neg measurableSet_Ioi]
  congr 1
  ext t; simp

lemma fxd_pdf_identity (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    S * exp (-(rf * T)) * gaussianPDFReal 0 1 (gkD1 S K rd rf σ T) =
      K * exp (-(rd * T)) * gaussianPDFReal 0 1 (gkD2 S K rd rf σ T) := by
  have hr : 0 < √T := Real.sqrt_pos.mpr hT
  have hb2 : (σ * √T) ^ 2 = σ ^ 2 * T := by rw [mul_pow, Real.sq_sqrt hT.le]
  have hd1b : gkD1 S K rd rf σ T * (σ * √T) = log (S / K) + (rd - rf + σ ^ 2 / 2) * T := by
    unfold gkD1; field_simp
  have hSK : S = K * exp (log (S / K)) := by
    rw [exp_log (div_pos hS hK)]; field_simp
  unfold gkD2
  set d := gkD1 S K rd rf σ T
  simp only [gaussianPDFReal, NNReal.coe_one, mul_one, sub_zero]
  conv_lhs => rw [hSK]
  have he : log (S / K) + -(rf * T) + -d ^ 2 / 2 = -(rd * T) + -(d - σ * √T) ^ 2 / 2 := by
    linear_combination -hd1b + hb2 / 2
  calc K * exp (log (S / K)) * exp (-(rf * T)) * ((√(2 * π))⁻¹ * exp (-d ^ 2 / 2))
      = K * (√(2 * π))⁻¹ * exp (log (S / K) + -(rf * T) + -d ^ 2 / 2) := by
        rw [exp_add, exp_add]; ring
    _ = K * (√(2 * π))⁻¹ * exp (-(rd * T) + -(d - σ * √T) ^ 2 / 2) := by rw [he]
    _ = _ := by rw [exp_add]; ring

lemma fxd_smile_deriv (S K rd rf T : ℝ) (σ : ℝ → ℝ) (β : ℝ) (hS : 0 < S) (hK : 0 < K)
    (hT : 0 < T) (hσK : 0 < σ K) (hβ : HasDerivAt σ β K) :
    HasDerivAt (fun k : ℝ => gkCall S k rd rf (σ k) T)
        (-(exp (-(rd * T)) * cdf (gaussianReal 0 1) (gkD2 S K rd rf (σ K) T) -
            gkVega S K rd rf (σ K) T * β)) K := by
  have hr : 0 < √T := Real.sqrt_pos.mpr hT
  have hdiff : DifferentiableAt ℝ (fun k => gkD1 S k rd rf (σ k) T) K := by
    unfold gkD1
    refine DifferentiableAt.div ?_ ?_ (by positivity)
    · refine DifferentiableAt.add ?_ ?_
      · exact (DifferentiableAt.div (differentiableAt_const _) differentiableAt_id hK.ne').log
          (div_pos hS hK).ne'
      · exact ((differentiableAt_const _).add
          ((hβ.differentiableAt.pow 2).div_const _)).mul (differentiableAt_const _)
    · exact hβ.differentiableAt.mul (differentiableAt_const _)
  obtain ⟨d', hD1⟩ : ∃ d', HasDerivAt (fun k => gkD1 S k rd rf (σ k) T) d' K :=
    ⟨_, hdiff.hasDerivAt⟩
  have hD2 : HasDerivAt (fun k => gkD2 S k rd rf (σ k) T) (d' - β * √T) K :=
    hD1.sub (hβ.mul_const _)
  have hN1 := (fxd_hasDerivAt_cdf (gkD1 S K rd rf (σ K) T)).comp K hD1
  have hN2 := (fxd_hasDerivAt_cdf (gkD2 S K rd rf (σ K) T)).comp K hD2
  have hC := (hN1.const_mul (S * exp (-(rf * T)))).sub
    (((hasDerivAt_id K).mul_const (exp (-(rd * T)))).mul hN2)
  have hid := fxd_pdf_identity S K rd rf (σ K) T hS hK hσK hT
  refine HasDerivAt.congr_deriv (f := fun k : ℝ => gkCall S k rd rf (σ k) T) hC ?_
  unfold gkVega
  simp only [id, Function.comp_apply]
  linear_combination (d' - β * √T) * hid

lemma fxd_threshold (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    (log K - log S - (rd - rf - σ ^ 2 / 2) * T) / (σ * √T) = -gkD2 S K rd rf σ T := by
  have hr : 0 < √T := Real.sqrt_pos.mpr hT
  have hb2 : √T ^ 2 = T := Real.sq_sqrt hT.le
  unfold gkD2 gkD1
  rw [log_div hS.ne' hK.ne']
  field_simp
  linear_combination (-2 * σ ^ 2) * hb2

lemma fxd_set_gt (S K a b : ℝ) (hS : 0 < S) (hK : 0 < K) (hb : 0 < b) (z : ℝ) :
    K < S * exp (a + b * z) ↔ (log K - log S - a) / b < z := by
  rw [div_lt_iff₀ hb]
  conv_lhs => rw [← exp_log hK, ← exp_log hS, ← exp_add, exp_lt_exp]
  constructor <;> intro h <;> linarith

lemma fxd_set_lt (S K a b : ℝ) (hS : 0 < S) (hK : 0 < K) (hb : 0 < b) (z : ℝ) :
    S * exp (a + b * z) < K ↔ z < (log K - log S - a) / b := by
  rw [lt_div_iff₀ hb]
  conv_lhs => rw [← exp_log hK, ← exp_log hS, ← exp_add, exp_lt_exp]
  constructor <;> intro h <;> linarith

lemma fxd_shifted_pdf (a b z : ℝ) :
    gaussianPDFReal 0 1 z * exp (a + b * z) = exp (a + b ^ 2 / 2) * gaussianPDFReal b 1 z := by
  simp only [gaussianPDFReal, NNReal.coe_one, mul_one, sub_zero]
  have : -z ^ 2 / 2 + (a + b * z) = a + b ^ 2 / 2 + -(z - b) ^ 2 / 2 := by ring
  calc (√(2 * π))⁻¹ * exp (-z ^ 2 / 2) * exp (a + b * z)
      = (√(2 * π))⁻¹ * exp (-z ^ 2 / 2 + (a + b * z)) := by rw [mul_assoc, ← exp_add]
    _ = (√(2 * π))⁻¹ * exp (a + b ^ 2 / 2 + -(z - b) ^ 2 / 2) := by rw [this]
    _ = _ := by rw [exp_add]; ring

lemma fxd_integral_indicator_prob (c : ℝ) :
    ∫ z, (if c < z then (1 : ℝ) else 0) ∂(gaussianReal 0 1) = 1 - cdf (gaussianReal 0 1) c := by
  rw [← fxd_measureReal_Ioi, ← integral_indicator_one measurableSet_Ioi]
  congr 1

lemma fxd_integral_indicator_prob_lt (c : ℝ) :
    ∫ z, (if z < c then (1 : ℝ) else 0) ∂(gaussianReal 0 1) = cdf (gaussianReal 0 1) c := by
  rw [← fxd_measureReal_Iio, ← integral_indicator_one measurableSet_Iio]
  congr 1

lemma fxd_integral_share (S a b c : ℝ) :
    ∫ z, (if c < z then S * exp (a + b * z) else 0) ∂(gaussianReal 0 1) =
      S * exp (a + b ^ 2 / 2) * cdf (gaussianReal 0 1) (b - c) := by
  rw [integral_gaussianReal_eq_integral_smul one_ne_zero]
  have h1 : (fun z => gaussianPDFReal 0 1 z • (if c < z then S * exp (a + b * z) else 0)) =
      fun z => (S * exp (a + b ^ 2 / 2)) * (Set.Ioi c).indicator (gaussianPDFReal b 1) z := by
    funext z
    by_cases hz : c < z
    · simp only [hz, ite_true, smul_eq_mul, Set.indicator_of_mem (Set.mem_Ioi.mpr hz)]
      rw [mul_left_comm, fxd_shifted_pdf]; ring
    · simp [hz]
  rw [h1, integral_const_mul, integral_indicator measurableSet_Ioi]
  congr 1
  have h2 : ∫ z in Set.Ioi c, gaussianPDFReal b 1 z = (gaussianReal b 1).real (Set.Ioi c) := by
    rw [measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
      ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Ioi
        (fun t _ => gaussianPDFReal_nonneg _ _ t))]
  have h3 := gaussianReal_map_add_const (μ := 0) (v := 1) b
  rw [zero_add] at h3
  rw [h2, ← h3, map_measureReal_apply (measurable_add_const b) measurableSet_Ioi]
  have h4 : (fun x => x + b) ⁻¹' Set.Ioi c = Set.Ioi (c - b) := by
    ext t; simp [sub_lt_iff_lt_add]
  rw [h4, fxd_measureReal_Ioi, ← fxd_cdf_neg, neg_sub]

#print axioms fxd_cdf_eq_setIntegral
#print axioms fxd_continuous_pdf
#print axioms fxd_hasDerivAt_cdf
#print axioms fxd_measureReal_Ioi
#print axioms fxd_measureReal_Iio
#print axioms fxd_cdf_neg
#print axioms fxd_pdf_identity
#print axioms fxd_smile_deriv
#print axioms fxd_threshold
#print axioms fxd_set_gt
#print axioms fxd_set_lt
#print axioms fxd_shifted_pdf
#print axioms fxd_integral_indicator_prob
#print axioms fxd_integral_indicator_prob_lt
#print axioms fxd_integral_share

/-- **The two flat digitals** (The formula; Why it works, Steps 0 to 2). In Garman-Kohlhagen's
model, let the rate on expiry day be `S_T = S e^((r_d - r_f - σ²/2) T + σ√T Z)` with `Z` a
standard bell-curve draw under the dollar pricing measure `Q`, one constant volatility `σ > 0`,
known constant rates `r_d` and `r_f`, today's rate `S > 0`, strike `K > 0` and `T > 0` years,
with one look on expiry day. Then:
the dollar digital (pays one dollar if `S_T > K`), the discounted average payoff, is
`e^(-r_d T) N(d₂)`; the euro digital (pays one euro, worth `S_T` dollars, if `S_T > K`), valued in
euros by dividing its dollar price by `S`, is `e^(-r_f T) N(d₁)`; and the dollar digital is minus
the slope of the call price against the strike. -/
theorem fx_digitals_are_discounted_chances_and_minus_strike_slope
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z : Ω → ℝ}
    (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (hZ : HasLaw Z (gaussianReal 0 1) Q) :
    exp (-(rd * T)) * ∫ ω, (if K < fxRateAtExpiry S rd rf σ T (Z ω) then (1 : ℝ) else 0) ∂Q =
        exp (-(rd * T)) * cdf (gaussianReal 0 1) (gkD2 S K rd rf σ T) ∧
      (exp (-(rd * T)) * ∫ ω, (if K < fxRateAtExpiry S rd rf σ T (Z ω)
          then fxRateAtExpiry S rd rf σ T (Z ω) else 0) ∂Q) / S =
        exp (-(rf * T)) * cdf (gaussianReal 0 1) (gkD1 S K rd rf σ T) ∧
      HasDerivAt (fun k : ℝ => gkCall S k rd rf σ T)
        (-(exp (-(rd * T)) * cdf (gaussianReal 0 1) (gkD2 S K rd rf σ T))) K := by
  have hr : 0 < √T := Real.sqrt_pos.mpr hT
  have hb : 0 < σ * √T := mul_pos hσ hr
  have hcd := fxd_threshold S K rd rf σ T hS hK hσ hT
  set c := (log K - log S - (rd - rf - σ ^ 2 / 2) * T) / (σ * √T) with hc
  have hiff : ∀ z, K < fxRateAtExpiry S rd rf σ T z ↔ c < z := fun z =>
    fxd_set_gt S K _ _ hS hK hb z
  have hmeas : ∀ (g : ℝ → ℝ), Measurable g →
      AEStronglyMeasurable (fun z => if c < z then g z else 0) (gaussianReal 0 1) :=
    fun g hg => (Measurable.ite (measurableSet_lt measurable_const measurable_id) hg
      measurable_const).aestronglyMeasurable
  refine ⟨?_, ?_, ?_⟩
  · simp_rw [hiff]
    have h := hZ.integral_comp (hmeas (fun _ => (1 : ℝ)) measurable_const)
    simp only [Function.comp_def] at h
    rw [h, fxd_integral_indicator_prob, hcd, fxd_cdf_neg]
    ring
  · simp_rw [hiff]
    have h := hZ.integral_comp
      (hmeas (fun z => S * exp ((rd - rf - σ ^ 2 / 2) * T + σ * √T * z)) (by fun_prop))
    simp only [Function.comp_def] at h
    unfold fxRateAtExpiry
    rw [h, fxd_integral_share]
    have hd : σ * √T - c = gkD1 S K rd rf σ T := by
      rw [hcd]; unfold gkD2; ring
    have hb2 : (σ * √T) ^ 2 = σ ^ 2 * T := by rw [mul_pow, Real.sq_sqrt hT.le]
    rw [hd, hb2]
    have he : exp (-(rd * T)) * exp ((rd - rf - σ ^ 2 / 2) * T + σ ^ 2 * T / 2) = exp (-(rf * T)) := by
      rw [← exp_add]; congr 1; ring
    rw [← he, mul_div_assoc, mul_assoc S, mul_div_cancel_left₀ _ hS.ne', mul_assoc]
  · have h := fxd_smile_deriv S K rd rf T (fun _ => σ) 0 hS hK hT hσ (hasDerivAt_const K σ)
    simp only [mul_zero, sub_zero] at h
    exact h

/-- **On a smile, minus vega times the smile's slope** (The formula; Why it works, Step 4).
Let every call be priced by Garman-Kohlhagen at its own strike's volatility, `C(k, σ(k))`, with
`S > 0`, `K > 0`, `T > 0`, a positive volatility `σ(K)` at the strike, and a smile with slope `β`
at `K`. Then the dollar digital, minus the strike slope of the smile call, is
`e^(-r_d T) N(d₂) - ν β`, and the euro digital, by the share-half route
`(C + K D_d) / S`, is `e^(-r_f T) N(d₁) - (K/S) ν β` (with `d₁`, `d₂`, `ν` all at `σ(K)`). -/
theorem fx_digitals_on_a_smile_subtract_vega_times_smile_slope
    (S K rd rf T : ℝ) (σ : ℝ → ℝ) (β : ℝ) (hS : 0 < S) (hK : 0 < K) (hT : 0 < T)
    (hσK : 0 < σ K) (hβ : HasDerivAt σ β K) :
    HasDerivAt (fun k : ℝ => gkCall S k rd rf (σ k) T)
        (-(exp (-(rd * T)) * cdf (gaussianReal 0 1) (gkD2 S K rd rf (σ K) T) -
            gkVega S K rd rf (σ K) T * β)) K ∧
      (gkCall S K rd rf (σ K) T +
          K * (exp (-(rd * T)) * cdf (gaussianReal 0 1) (gkD2 S K rd rf (σ K) T) -
            gkVega S K rd rf (σ K) T * β)) / S =
        exp (-(rf * T)) * cdf (gaussianReal 0 1) (gkD1 S K rd rf (σ K) T) -
          K / S * gkVega S K rd rf (σ K) T * β := by
  refine ⟨fxd_smile_deriv S K rd rf T σ β hS hK hT hσK hβ, ?_⟩
  unfold gkCall
  field_simp
  ring

/-- **The euro digital is a plain digital on the inverted quote** (Why it works, Step 3). A
euro-based bank sees the rate `1/S` euros per dollar, with the euro rate `r_f` domestic, the
dollar rate `r_d` foreign and the same volatility `σ`. With `S > 0`, `K > 0`, `σ > 0`, `T > 0`
and `Z` a standard bell-curve draw under that bank's euro pricing measure `Q_f`, the digital put
paying one euro if the inverted rate finishes below `1/K` costs `e^(-r_f T) N(-d₂ᴵⁿᵛ)`, and
`-d₂ᴵⁿᵛ = d₁`, so it is the euro digital's price `e^(-r_f T) N(d₁)`. -/
theorem eur_digital_is_digital_put_on_inverted_quote
    {Ω : Type*} [MeasurableSpace Ω] {Qf : Measure Ω} {Z : Ω → ℝ}
    (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (hZ : HasLaw Z (gaussianReal 0 1) Qf) :
    exp (-(rf * T)) * ∫ ω, (if fxRateAtExpiry S⁻¹ rf rd σ T (Z ω) < K⁻¹ then (1 : ℝ) else 0) ∂Qf =
        exp (-(rf * T)) * cdf (gaussianReal 0 1) (-gkD2 S⁻¹ K⁻¹ rf rd σ T) ∧
      -gkD2 S⁻¹ K⁻¹ rf rd σ T = gkD1 S K rd rf σ T := by
  have hr : 0 < √T := Real.sqrt_pos.mpr hT
  have hb : 0 < σ * √T := mul_pos hσ hr
  have hcd := fxd_threshold S⁻¹ K⁻¹ rf rd σ T (inv_pos.mpr hS) (inv_pos.mpr hK) hσ hT
  set c := (log K⁻¹ - log S⁻¹ - (rf - rd - σ ^ 2 / 2) * T) / (σ * √T) with hc
  have hiff : ∀ z, fxRateAtExpiry S⁻¹ rf rd σ T z < K⁻¹ ↔ z < c := fun z =>
    fxd_set_lt S⁻¹ K⁻¹ _ _ (inv_pos.mpr hS) (inv_pos.mpr hK) hb z
  refine ⟨?_, ?_⟩
  · simp_rw [hiff]
    have h := hZ.integral_comp (f := fun z => if z < c then (1 : ℝ) else 0)
      (Measurable.ite (measurableSet_lt measurable_id measurable_const) measurable_const
        measurable_const).aestronglyMeasurable
    simp only [Function.comp_def] at h
    rw [h, fxd_integral_indicator_prob_lt, hcd]
  · have hb2 : √T ^ 2 = T := Real.sq_sqrt hT.le
    unfold gkD2 gkD1
    rw [show S⁻¹ / K⁻¹ = K / S by field_simp, log_div hK.ne' hS.ne', log_div hS.ne' hK.ne']
    field_simp
    linear_combination (2 * σ ^ 2) * hb2

/-! The card's exact worked numbers: `S = K = 1.10`, `r_d = 5/100`, `r_f = 3/100`, `σ = 1/10`,
`T = 1` year. -/

-- Drift for d₁: 0.05 - 0.03 + ½(0.01) = 0.025.
example : (5 / 100 : ℚ) - 3 / 100 + (1 / 10) ^ 2 / 2 = 25 / 1000 := by norm_num
-- d₁ = 0.025 / 0.10 = 0.25.
example : gkD1 (11 / 10) (11 / 10) (5 / 100) (3 / 100) (1 / 10) 1 = 1 / 4 := by
  norm_num [gkD1]
-- d₂ = 0.25 - 0.10 = 0.15.
example : gkD2 (11 / 10) (11 / 10) (5 / 100) (3 / 100) (1 / 10) 1 = 3 / 20 := by
  norm_num [gkD2, gkD1]
-- Step 3: on the inverted quote 1/1.10, rates swapped, d₂ᴵⁿᵛ = -0.25 = -d₁.
example : gkD2 (10 / 11) (10 / 11) (3 / 100) (5 / 100) (1 / 10) 1 = -1 / 4 := by
  norm_num [gkD2, gkD1]
-- At 1.10 on the house smile: flat 0.530331 plus skew term 0.037427 is 0.567758.
example : (530331 / 1000000 : ℚ) + 37427 / 1000000 = 567758 / 1000000 := by norm_num

#print axioms fx_digitals_are_discounted_chances_and_minus_strike_slope
#print axioms fx_digitals_on_a_smile_subtract_vega_times_smile_slope
#print axioms eur_digital_is_digital_put_on_inverted_quote
