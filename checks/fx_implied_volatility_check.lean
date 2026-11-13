-- Implied vol for a currency option: a Garman-Kohlhagen EUR call quoted in dollars per euro has exactly one positive volatility that reprices it exactly when the quote lies strictly between max(S e^(-r_f T) - K e^(-r_d T), 0) and S e^(-r_f T), the euro-side mirror put gives the same vol, and the price climbs with vega S e^(-r_f T) φ(d₁) √T > 0.
import Mathlib.Probability.CDF
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Real ProbabilityTheory

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- The card's `d₁ = (ln(S/K) + (r_d - r_f + σ²/2) T) / (σ√T)`; then `d₂ = d₁ - σ√T`.
Spot `S` and strike `K` are dollars per euro, `rd` the dollar rate, `rf` the euro rate. -/
noncomputable def gkD1 (S K rd rf σ T : ℝ) : ℝ :=
  (log (S / K) + (rd - rf + σ ^ 2 / 2) * T) / (σ * √T)

/-- The Garman-Kohlhagen EUR call / USD put price in dollars per euro at volatility `σ`:
`C(σ) = S e^{-r_f T} N(d₁) - K e^{-r_d T} N(d₂)`. -/
noncomputable def gkCall (S K rd rf σ T : ℝ) : ℝ :=
  S * exp (-rf * T) * stdNormalCDF (gkD1 S K rd rf σ T)
    - K * exp (-rd * T) * stdNormalCDF (gkD1 S K rd rf σ T - σ * √T)

/-- The Garman-Kohlhagen put price at volatility `σ`, in units of the domestic currency per unit
of the foreign one: `P(σ) = K e^{-r_d T} N(-d₂) - S e^{-r_f T} N(-d₁)`. -/
noncomputable def gkPut (S K rd rf σ T : ℝ) : ℝ :=
  K * exp (-rd * T) * stdNormalCDF (-(gkD1 S K rd rf σ T - σ * √T))
    - S * exp (-rf * T) * stdNormalCDF (-(gkD1 S K rd rf σ T))

section Helpers

open MeasureTheory Set Filter Topology

lemma continuous_stdPDF : Continuous (gaussianPDFReal 0 1) := by
  unfold gaussianPDFReal; fun_prop

lemma stdNormalCDF_eq_integral (x : ℝ) :
    stdNormalCDF x = ∫ t in Iic x, gaussianPDFReal 0 1 t := by
  rw [stdNormalCDF, cdf_eq_real, measureReal_def,
    gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Iic
      (fun _ _ => gaussianPDFReal_nonneg _ _ _))]

lemma stdNormalCDF_hasDerivAt (x : ℝ) :
    HasDerivAt stdNormalCDF (gaussianPDFReal 0 1 x) x := by
  have hI : ∀ a, IntegrableOn (gaussianPDFReal 0 1) (Iic a) :=
    fun a => (integrable_gaussianPDFReal 0 1).integrableOn
  have heq : stdNormalCDF = fun y => (∫ t in Iic 0, gaussianPDFReal 0 1 t)
      + ∫ t in (0:ℝ)..y, gaussianPDFReal 0 1 t := by
    funext y
    rw [stdNormalCDF_eq_integral, ← intervalIntegral.integral_Iic_sub_Iic (hI 0) (hI y)]
    ring
  rw [heq]
  exact ((continuous_stdPDF.integral_hasStrictDerivAt 0 x).hasDerivAt).const_add _

lemma gkD1_hasDerivAt (S K rd rf T σ : ℝ) (hT : 0 < T) (hσ : 0 < σ) :
    HasDerivAt (fun s => gkD1 S K rd rf s T) (deriv (fun s => gkD1 S K rd rf s T) σ) σ := by
  have hne : σ * √T ≠ 0 := by positivity
  apply DifferentiableAt.hasDerivAt
  unfold gkD1
  exact DifferentiableAt.div (by fun_prop) (by fun_prop) hne

/-- `B φ(d₂) = A φ(d₁)`. -/
lemma gk_pdf_identity (S K rd rf T σ : ℝ) (hS : 0 < S) (hK : 0 < K) (hT : 0 < T) (hσ : 0 < σ) :
    K * exp (-rd * T) * gaussianPDFReal 0 1 (gkD1 S K rd rf σ T - σ * √T)
      = S * exp (-rf * T) * gaussianPDFReal 0 1 (gkD1 S K rd rf σ T) := by
  set d := gkD1 S K rd rf σ T with hd
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  have hu : σ * √T ≠ 0 := by positivity
  have hdu : d * (σ * √T) = log S - log K + (rd - rf + σ ^ 2 / 2) * T := by
    rw [hd, gkD1, div_mul_cancel₀ _ hu, log_div hS.ne' hK.ne']
  have hsq : (√T) ^ 2 = T := Real.sq_sqrt hT.le
  have key : -(d - σ * √T) ^ 2 / 2 = -d ^ 2 / 2 + (log S - rf * T - (log K - rd * T)) := by
    have : (d - σ * √T) ^ 2 = d ^ 2 - 2 * (d * (σ * √T)) + σ ^ 2 * (√T) ^ 2 := by ring
    rw [this, hdu, hsq]; ring
  simp only [gaussianPDFReal, NNReal.coe_one, sub_zero, mul_one]
  rw [key, exp_add, exp_sub, exp_sub, exp_sub, exp_log hS, exp_log hK]
  have h1 : exp (rf * T) ≠ 0 := (exp_pos _).ne'
  have h2 : exp (rd * T) ≠ 0 := (exp_pos _).ne'
  rw [show -rd * T = -(rd * T) by ring, show -rf * T = -(rf * T) by ring, exp_neg, exp_neg]
  field_simp
lemma gkCall_hasDerivAt (S K rd rf T σ : ℝ) (hS : 0 < S) (hK : 0 < K) (hT : 0 < T) (hσ : 0 < σ) :
    HasDerivAt (fun s => gkCall S K rd rf s T)
        (S * exp (-rf * T) * gaussianPDFReal 0 1 (gkD1 S K rd rf σ T) * √T) σ := by
  set D := deriv (fun s => gkD1 S K rd rf s T) σ
  have hd := gkD1_hasDerivAt S K rd rf T σ hT hσ
  have h1 := (stdNormalCDF_hasDerivAt (gkD1 S K rd rf σ T)).comp σ hd
  have h2 := (stdNormalCDF_hasDerivAt (gkD1 S K rd rf σ T - σ * √T)).comp σ
    (hd.sub ((hasDerivAt_id σ).mul_const √T))
  have h := (h1.const_mul (S * exp (-rf * T))).sub (h2.const_mul (K * exp (-rd * T)))
  have hid := gk_pdf_identity S K rd rf T σ hS hK hT hσ
  convert h using 1
  · funext s; simp [gkCall]
  simp only [one_mul]
  rw [← mul_assoc (K * exp (-rd * T)), hid]
  ring

lemma gkD1_eq (S K rd rf T σ : ℝ) (hS : 0 < S) (hK : 0 < K) (hT : 0 < T) (hσ : 0 < σ) :
    gkD1 S K rd rf σ T = (log (S * exp (-rf * T)) - log (K * exp (-rd * T))) / (σ * √T)
      + σ * √T / 2 := by
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  have hsq : (√T) ^ 2 = T := Real.sq_sqrt hT.le
  rw [gkD1, log_mul hS.ne' (exp_pos _).ne', log_mul hK.ne' (exp_pos _).ne', log_exp, log_exp,
    log_div hS.ne' hK.ne']
  field_simp
  rw [hsq]
  ring

/-- The limits of `g u = A N(m/u + u/2) - B N(m/u - u/2)`. -/
lemma gk_tendsto_atTop (A B m : ℝ) :
    Tendsto (fun u : ℝ => A * stdNormalCDF (m / u + u / 2) - B * stdNormalCDF (m / u + u / 2 - u))
      atTop (𝓝 A) := by
  have h0 : Tendsto (fun u : ℝ => m / u) atTop (𝓝 0) := tendsto_const_nhds.div_atTop tendsto_id
  have hu2 : Tendsto (fun u : ℝ => u / 2) atTop atTop := tendsto_id.atTop_div_const two_pos
  have hd1 : Tendsto (fun u : ℝ => m / u + u / 2) atTop atTop := h0.add_atTop hu2
  have hd2 : Tendsto (fun u : ℝ => m / u + u / 2 - u) atTop atBot := by
    have : (fun u : ℝ => m / u + u / 2 - u) = fun u => m / u + -(u / 2) := by
      funext u; ring
    rw [this]
    exact h0.add_atBot (tendsto_neg_atTop_atBot.comp hu2)
  have := (((tendsto_cdf_atTop (gaussianReal 0 1)).comp hd1).const_mul A).sub
    (((tendsto_cdf_atBot (gaussianReal 0 1)).comp hd2).const_mul B)
  simpa [stdNormalCDF] using this

lemma stdNormalCDF_continuous : Continuous stdNormalCDF :=
  continuous_iff_continuousAt.2 fun x => (stdNormalCDF_hasDerivAt x).continuousAt

lemma gk_tendsto_zero (A B m : ℝ) (hA : 0 < A) (hB : 0 < B) (hm : m = log A - log B) :
    Tendsto (fun u : ℝ => A * stdNormalCDF (m / u + u / 2) - B * stdNormalCDF (m / u + u / 2 - u))
      (𝓝[>] 0) (𝓝 (max (A - B) 0)) := by
  have hu2 : Tendsto (fun u : ℝ => u / 2) (𝓝[>] 0) (𝓝 0) := by
    have := (tendsto_id (x := 𝓝 (0:ℝ))).div_const 2
    simpa using this.mono_left nhdsWithin_le_nhds
  have hmu2 : Tendsto (fun u : ℝ => -(u / 2)) (𝓝[>] 0) (𝓝 0) := by
    simpa using hu2.neg
  have hsub : ∀ u : ℝ, m / u + u / 2 - u = m / u + -(u / 2) := fun u => by ring
  simp_rw [hsub]
  rcases lt_trichotomy m 0 with hneg | hzero | hpos
  · have hAB : A < B := by
      have : log A < log B := by linarith
      exact (log_lt_log_iff hA hB).1 this
    have hmu : Tendsto (fun u : ℝ => m / u) (𝓝[>] 0) atBot := by
      simp only [div_eq_mul_inv]
      exact tendsto_inv_nhdsGT_zero.const_mul_atTop_of_neg hneg
    have := (((tendsto_cdf_atBot (gaussianReal 0 1)).comp (hmu.atBot_add hu2)).const_mul A).sub
      (((tendsto_cdf_atBot (gaussianReal 0 1)).comp (hmu.atBot_add hmu2)).const_mul B)
    rw [max_eq_right (by linarith)]
    simpa [stdNormalCDF] using this
  · have hAB : A = B := by
      have : log A = log B := by linarith
      exact log_injOn_pos (Set.mem_Ioi.2 hA) (Set.mem_Ioi.2 hB) this
    subst hAB
    have hc := stdNormalCDF_continuous.continuousAt (x := 0)
    have := ((hc.tendsto.comp hu2).const_mul A).sub ((hc.tendsto.comp hmu2).const_mul A)
    simp only [hzero, zero_div, zero_add, sub_self, max_self]
    simpa using this
  · have hAB : B < A := by
      have : log B < log A := by linarith
      exact (log_lt_log_iff hB hA).1 this
    have hmu : Tendsto (fun u : ℝ => m / u) (𝓝[>] 0) atTop := by
      simp only [div_eq_mul_inv]
      exact tendsto_inv_nhdsGT_zero.const_mul_atTop hpos
    have := (((tendsto_cdf_atTop (gaussianReal 0 1)).comp (hmu.atTop_add hu2)).const_mul A).sub
      (((tendsto_cdf_atTop (gaussianReal 0 1)).comp (hmu.atTop_add hmu2)).const_mul B)
    rw [max_eq_left (by linarith)]
    simpa [stdNormalCDF] using this

lemma gkCall_tendsto (S K rd rf T : ℝ) (hS : 0 < S) (hK : 0 < K) (hT : 0 < T) :
    Tendsto (fun s => gkCall S K rd rf s T) (𝓝[>] 0)
        (𝓝 (max (S * exp (-rf * T) - K * exp (-rd * T)) 0)) ∧
      Tendsto (fun s => gkCall S K rd rf s T) atTop (𝓝 (S * exp (-rf * T))) := by
  set A := S * exp (-rf * T) with hA
  set B := K * exp (-rd * T) with hB
  have hApos : 0 < A := by positivity
  have hBpos : 0 < B := by positivity
  set m := log A - log B with hm
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  set g : ℝ → ℝ := fun u => A * stdNormalCDF (m / u + u / 2) - B * stdNormalCDF (m / u + u / 2 - u)
    with hg
  have hfg : ∀ s, 0 < s → gkCall S K rd rf s T = g (s * √T) := by
    intro s hs
    simp only [hg, gkCall, gkD1_eq S K rd rf T s hS hK hT hs, hA, hB, hm]
  have hlin : Continuous (fun s : ℝ => s * √T) := by fun_prop
  constructor
  · have hu : Tendsto (fun s : ℝ => s * √T) (𝓝[>] 0) (𝓝[>] 0) := by
      refine tendsto_nhdsWithin_iff.2 ⟨?_, ?_⟩
      · have := (hlin.tendsto 0).mono_left (nhdsWithin_le_nhds (s := Set.Ioi (0:ℝ)))
        simpa using this
      · filter_upwards [self_mem_nhdsWithin] with s hs
        exact mul_pos hs hsT
    refine Tendsto.congr' ?_ ((gk_tendsto_zero A B m hApos hBpos hm).comp hu)
    filter_upwards [self_mem_nhdsWithin] with s hs
    exact (hfg s hs).symm
  · have hu : Tendsto (fun s : ℝ => s * √T) atTop atTop := tendsto_id.atTop_mul_const hsT
    refine Tendsto.congr' ?_ ((gk_tendsto_atTop A B m).comp hu)
    filter_upwards [eventually_gt_atTop 0] with s hs
    exact (hfg s hs).symm

#print axioms continuous_stdPDF
#print axioms stdNormalCDF_eq_integral
#print axioms stdNormalCDF_hasDerivAt
#print axioms gkD1_hasDerivAt
#print axioms gk_pdf_identity
#print axioms gkCall_hasDerivAt
#print axioms gkD1_eq
#print axioms gk_tendsto_atTop
#print axioms stdNormalCDF_continuous
#print axioms gk_tendsto_zero
#print axioms gkCall_tendsto

end Helpers

/-- **Implied vol for a currency option exists and is unique exactly inside the bounds.**
Take a European EUR call / USD put with spot `S > 0` and strike `K > 0` in dollars per euro,
time to expiry `T > 0` years, dollar rate `rd` and euro rate `rf` (each on its own currency),
and a quote `C` already converted to dollars per euro. Write `A = S e^{-r_f T}` (a euro delivered
at expiry, costed today) and `B = K e^{-r_d T}` (the strike's dollars, discounted). Then there is
exactly one positive volatility `σ` whose Garman-Kohlhagen price equals the quote if and only if
`max(A - B, 0) < C < A`. -/
theorem fx_implied_vol_exists_unique_iff (S K rd rf T C : ℝ)
    (hS : 0 < S) (hK : 0 < K) (hT : 0 < T) :
    (∃! σ : ℝ, 0 < σ ∧ gkCall S K rd rf σ T = C) ↔
      max (S * exp (-rf * T) - K * exp (-rd * T)) 0 < C ∧ C < S * exp (-rf * T) := by
  set f : ℝ → ℝ := fun s => gkCall S K rd rf s T with hf
  have hderiv : ∀ s ∈ Set.Ioi (0:ℝ), HasDerivAt f
      (S * exp (-rf * T) * gaussianPDFReal 0 1 (gkD1 S K rd rf s T) * √T) s :=
    fun s hs => gkCall_hasDerivAt S K rd rf T s hS hK hT hs
  have hcont : ContinuousOn f (Set.Ioi 0) :=
    fun s hs => (hderiv s hs).continuousAt.continuousWithinAt
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  have hmono : StrictMonoOn f (Set.Ioi 0) := by
    refine strictMonoOn_of_deriv_pos (convex_Ioi 0) hcont fun s hs => ?_
    rw [interior_Ioi] at hs
    rw [(hderiv s hs).deriv]
    have := gaussianPDFReal_pos 0 1 (gkD1 S K rd rf s T) one_ne_zero
    positivity
  obtain ⟨hlim0, hlimTop⟩ := gkCall_tendsto S K rd rf T hS hK hT
  change Filter.Tendsto f _ _ at hlim0 hlimTop
  constructor
  · rintro ⟨σ, ⟨hσ, hfσ⟩, -⟩
    have hσ2 : (0:ℝ) < σ / 2 := half_pos hσ
    constructor
    · have hle : max (S * exp (-rf * T) - K * exp (-rd * T)) 0 ≤ f (σ / 2) := by
        refine le_of_tendsto hlim0 ?_
        filter_upwards [Ioo_mem_nhdsGT hσ2] with t ht
        exact (hmono ht.1 hσ2 ht.2).le
      have hlt : f (σ / 2) < f σ := hmono hσ2 hσ (by linarith)
      have : f σ = C := hfσ
      linarith
    · have hle : f (2 * σ) ≤ S * exp (-rf * T) := by
        refine ge_of_tendsto hlimTop ?_
        filter_upwards [Filter.eventually_gt_atTop (2 * σ)] with t ht
        exact (hmono (show (0:ℝ) < 2 * σ by linarith) (show (0:ℝ) < t by linarith) ht).le
      have hlt : f σ < f (2 * σ) := hmono hσ (show (0:ℝ) < 2 * σ by linarith) (by linarith)
      have : f σ = C := hfσ
      linarith
  · rintro ⟨hlo, hhi⟩
    obtain ⟨a, haC, ha⟩ := ((hlim0.eventually (gt_mem_nhds hlo)).and self_mem_nhdsWithin).exists
    obtain ⟨b, hbC, hb⟩ := ((hlimTop.eventually (lt_mem_nhds hhi)).and
      (Filter.eventually_gt_atTop 0)).exists
    have ha' : (0:ℝ) < a := ha
    have hab : a ≤ b := ((hmono.lt_iff_lt ha hb).1 (haC.trans hbC)).le
    have hsub : Set.Icc a b ⊆ Set.Ioi 0 := fun x hx => lt_of_lt_of_le ha' hx.1
    obtain ⟨σ, hσab, hfσ⟩ := intermediate_value_Icc hab (hcont.mono hsub) ⟨haC.le, hbC.le⟩
    have hσ : σ ∈ Set.Ioi (0:ℝ) := hsub hσab
    exact ⟨σ, ⟨hσ, hfσ⟩, fun y hy => hmono.injOn hy.1 hσ (hy.2.trans hfσ.symm)⟩

/-- **The same vol from the euro side** (Step 5). Seen from Frankfurt, the same option is a put
on the dollar: spot `1/S` and strike `1/K` in euros per dollar, domestic rate the euro's `rf`,
foreign rate the dollar's `rd`. At every positive volatility its premium `Q`, in euros per
dollar of notional, matches that put exactly when `S K Q`, in dollars per euro, matches the
EUR call. So inverting the mirror put gives the same implied vol. -/
theorem fx_mirror_put_same_vol (S K rd rf T σ Q : ℝ)
    (hS : 0 < S) (hK : 0 < K) (hT : 0 < T) (hσ : 0 < σ) :
    gkPut (1 / S) (1 / K) rf rd σ T = Q ↔ gkCall S K rd rf σ T = S * K * Q := by
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  have hu : σ * √T ≠ 0 := by positivity
  have hsq : (√T) ^ 2 = T := Real.sq_sqrt hT.le
  have h1 : -(gkD1 (1 / S) (1 / K) rf rd σ T - σ * √T) = gkD1 S K rd rf σ T := by
    have hl : log ((1 / S) / (1 / K)) = - log (S / K) := by
      rw [show (1 / S) / (1 / K) = (S / K)⁻¹ by field_simp, log_inv]
    rw [gkD1, gkD1, hl]
    field_simp
    rw [hsq]
    ring
  have h2 : -gkD1 (1 / S) (1 / K) rf rd σ T = gkD1 S K rd rf σ T - σ * √T := by
    linarith
  have hput : S * K * gkPut (1 / S) (1 / K) rf rd σ T = gkCall S K rd rf σ T := by
    rw [gkPut, h1, h2, gkCall]
    field_simp
  rw [← hput]
  constructor
  · intro h; rw [h]
  · intro h
    have hSK : S * K ≠ 0 := by positivity
    exact mul_left_cancel₀ hSK h

/-- **The price always climbs** (Step 3). At every positive volatility the slope of the call
price against `σ` is vega, `ν = S e^{-r_f T} φ(d₁) √T`, a positive cost times a positive
bell-curve height times a positive root, so `ν > 0`. -/
theorem fx_call_vega_pos (S K rd rf T σ : ℝ)
    (hS : 0 < S) (hK : 0 < K) (hT : 0 < T) (hσ : 0 < σ) :
    HasDerivAt (fun s => gkCall S K rd rf s T)
        (S * exp (-rf * T) * gaussianPDFReal 0 1 (gkD1 S K rd rf σ T) * √T) σ ∧
      0 < S * exp (-rf * T) * gaussianPDFReal 0 1 (gkD1 S K rd rf σ T) * √T := by
  refine ⟨gkCall_hasDerivAt S K rd rf T σ hS hK hT hσ, ?_⟩
  have := gaussianPDFReal_pos 0 1 (gkD1 S K rd rf σ T) one_ne_zero
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  positivity

/-! Worked numbers from the card: `S = K = 1.1`, `r_d = 5/100`, `r_f = 3/100`, `T = 1`,
quote 535.6 USD pips. Table values are the card's rounded six-decimal figures. -/

-- Quote in USD per EUR: 535.6 ÷ 10,000 = 0.05356.
example : (5356 / 10 : ℚ) / 10000 = 5356 / 100000 := by norm_num
-- Floor: A - B = 1.067490 - 1.046352 = 0.021138.
example : (1067490 : ℚ) / 10 ^ 6 - 1046352 / 10 ^ 6 = 21138 / 10 ^ 6 := by norm_num
-- Inside? 0.021138 < 0.05356 < 1.067490: yes, one answer.
example : (21138 : ℚ) / 10 ^ 6 < 5356 / 10 ^ 5 ∧ (5356 : ℚ) / 10 ^ 5 < 1067490 / 10 ^ 6 := by
  norm_num
-- The bad quote 0.0200 is below the floor, by 0.021138 - 0.0200 = 0.001138.
example : (200 : ℚ) / 10 ^ 4 < 21138 / 10 ^ 6 ∧
    (21138 : ℚ) / 10 ^ 6 - 200 / 10 ^ 4 = 1138 / 10 ^ 6 := by norm_num
-- Start: σ₀ = √(2 · 0.02 / 1) = 0.20, since 0.20² = 2 · 0.02.
example : (1 / 5 : ℚ) ^ 2 = 2 * (2 / 100) / 1 := by norm_num
-- d₁ at 10%: (ln(1.1/1.1) + (0.05 - 0.03 + 0.005) · 1) / (0.10 · √1) = 0.25.
example : (log ((11 / 10) / (11 / 10)) + ((5 / 100 : ℝ) - 3 / 100 + (1 / 10) ^ 2 / 2) * 1)
    / (1 / 10 * √1) = 1 / 4 := by norm_num
-- d₂ = d₁ - σ√T = 0.25 - 0.10 = 0.15.
example : (1 / 4 : ℝ) - 1 / 10 * √1 = 3 / 20 := by norm_num
-- The proof's identity d₁² - d₂² = 2m with m = ln(F/K) = 0.02.
example : (1 / 4 : ℚ) ^ 2 - (3 / 20) ^ 2 = 2 * (2 / 100) := by norm_num
-- Newton from 10%: 0.10 + (0.05356 - 0.053556) / 0.412764, and the step is 0.000004 / 0.412764.
example : (5356 : ℚ) / 10 ^ 5 - 53556 / 10 ^ 6 = 4 / 10 ^ 6 := by norm_num
-- One vol point moves the premium by a hundredth of vega: 0.412764 × 0.01 = 0.00412764.
example : (412764 : ℚ) / 10 ^ 6 * (1 / 100) = 412764 / 10 ^ 8 := by norm_num
-- Euro pips back to USD pips: 442.609675 × 1.1 × 1.1 = 535.55770675.
example : (442609675 : ℚ) / 10 ^ 6 * (11 / 10) * (11 / 10) = 53555770675 / 10 ^ 8 := by norm_num
-- Parity road: the dollar put costs C - (A - B) = 0.053556 - 0.021138 = 0.032418.
example : (53556 : ℚ) / 10 ^ 6 - 21138 / 10 ^ 6 = 32418 / 10 ^ 6 := by norm_num

#print axioms fx_implied_vol_exists_unique_iff
#print axioms fx_mirror_put_same_vol
#print axioms fx_call_vega_pos
