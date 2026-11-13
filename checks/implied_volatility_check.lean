-- Implied volatility: under Black-Scholes a call quote has exactly one positive volatility that reprices it exactly when the quote lies strictly between max(A - B, 0) and A, a put quote likewise between max(B - A, 0) and B, and vega is A φ(d₁) √T.
import Mathlib.Probability.CDF
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Real ProbabilityTheory

/-- The standard normal distribution function `N(x)`: the area under the bell curve left of `x`. -/
local notation "Φ" => cdf (gaussianReal 0 1)

/-- The card's `d₁ = (ln(S/K) + (r - q + σ²/2) T) / (σ √T)`; then `d₂ = d₁ - σ √T`. -/
noncomputable def bsD1 (S K r q T σ : ℝ) : ℝ :=
  (log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)

/-- The Black-Scholes call price with volatility `σ`:
`C(σ) = S e^{-qT} N(d₁) - K e^{-rT} N(d₂)`. -/
noncomputable def bsCall (S K r q T σ : ℝ) : ℝ :=
  S * exp (-q * T) * Φ (bsD1 S K r q T σ) - K * exp (-r * T) * Φ (bsD1 S K r q T σ - σ * √T)

/-- The Black-Scholes put price with volatility `σ`:
`P(σ) = K e^{-rT} N(-d₂) - S e^{-qT} N(-d₁)`. -/
noncomputable def bsPut (S K r q T σ : ℝ) : ℝ :=
  K * exp (-r * T) * Φ (σ * √T - bsD1 S K r q T σ) - S * exp (-q * T) * Φ (-bsD1 S K r q T σ)

section IVHelpers

open MeasureTheory Filter Topology Set

lemma iv_continuous_pdf : Continuous (gaussianPDFReal 0 1) := by
  rw [gaussianPDFReal_def]; fun_prop

lemma iv_cdf_eq_integral (x : ℝ) : Φ x = ∫ t in Iic x, gaussianPDFReal 0 1 t := by
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral 0 one_ne_zero,
    ENNReal.toReal_ofReal]
  exact setIntegral_nonneg measurableSet_Iic (fun t _ => gaussianPDFReal_nonneg 0 1 t)

lemma iv_cdf_eq (x : ℝ) : Φ x = Φ 0 + ∫ t in (0:ℝ)..x, gaussianPDFReal 0 1 t := by
  rw [iv_cdf_eq_integral, iv_cdf_eq_integral, ← intervalIntegral.integral_Iic_sub_Iic]
  · ring
  · exact (integrable_gaussianPDFReal 0 1).integrableOn
  · exact (integrable_gaussianPDFReal 0 1).integrableOn

lemma iv_hasDerivAt_cdf (x : ℝ) : HasDerivAt (fun y => Φ y) (gaussianPDFReal 0 1 x) x := by
  have h := ((iv_continuous_pdf.integral_hasStrictDerivAt 0 x).hasDerivAt).const_add (Φ 0)
  convert h using 1
  funext y; exact iv_cdf_eq y

lemma iv_pdf_pos (x : ℝ) : 0 < gaussianPDFReal 0 1 x := gaussianPDFReal_pos 0 1 x one_ne_zero

lemma iv_pdf_neg (x : ℝ) : gaussianPDFReal 0 1 (-x) = gaussianPDFReal 0 1 x := by
  simp [gaussianPDFReal]

lemma iv_cdf_continuous : Continuous (fun y => Φ y) :=
  continuous_iff_continuousAt.2 fun x => (iv_hasDerivAt_cdf x).continuousAt

lemma iv_cdf_neg (x : ℝ) : Φ (-x) = 1 - Φ x := by
  have hd : ∀ y, HasDerivAt (fun y => Φ (-y) + Φ y) 0 y := by
    intro y
    have h1 := (iv_hasDerivAt_cdf (-y)).comp y (hasDerivAt_neg y)
    have h2 := h1.add (iv_hasDerivAt_cdf y)
    convert h2 using 1
    · rfl
    · rw [iv_pdf_neg]; ring
  have hc : ∀ y, Φ (-y) + Φ y = Φ (-0) + Φ 0 := fun y =>
    is_const_of_deriv_eq_zero (fun y => (hd y).differentiableAt) (fun y => (hd y).deriv) y 0
  have ht : Tendsto (fun y => Φ (-y) + Φ y) atTop (𝓝 (0 + 1)) :=
    ((tendsto_cdf_atBot _).comp tendsto_neg_atTop_atBot).add (tendsto_cdf_atTop _)
  have hconst : Tendsto (fun y => Φ (-y) + Φ y) atTop (𝓝 (Φ (-0) + Φ 0)) := by
    simp only [hc]; exact tendsto_const_nhds
  have := tendsto_nhds_unique hconst ht
  have := hc x
  linarith
lemma iv_unique_iff {f f' : ℝ → ℝ} {L U c : ℝ}
    (hd : ∀ s, 0 < s → HasDerivAt f (f' s) s) (hpos : ∀ s, 0 < s → 0 < f' s)
    (h0 : Tendsto f (𝓝[>] 0) (𝓝 L)) (hinf : Tendsto f atTop (𝓝 U)) :
    (∃! s, 0 < s ∧ f s = c) ↔ L < c ∧ c < U := by
  have hcont : ContinuousOn f (Ioi 0) := fun s hs => (hd s hs).continuousAt.continuousWithinAt
  have hmono : StrictMonoOn f (Ioi 0) := by
    refine strictMonoOn_of_deriv_pos (convex_Ioi 0) hcont (fun s hs => ?_)
    rw [interior_Ioi] at hs
    rw [(hd s hs).deriv]; exact hpos s hs
  constructor
  · rintro ⟨s, ⟨hs, rfl⟩, -⟩
    constructor
    · have h1 : ∀ᶠ t in 𝓝[>] 0, f t ≤ f (s / 2) := by
        filter_upwards [Ioo_mem_nhdsGT (half_pos hs)] with t ht
        exact (hmono ht.1 (half_pos hs) ht.2).le
      have h2 := le_of_tendsto h0 h1
      have h3 := hmono (half_pos hs) hs (half_lt_self hs)
      linarith
    · have h1 : ∀ᶠ t in atTop, f (2 * s) ≤ f t := by
        filter_upwards [eventually_ge_atTop (2 * s)] with t ht
        exact hmono.monotoneOn (show (0:ℝ) < 2 * s by positivity)
          (show (0:ℝ) < t by linarith) ht
      have h2 := ge_of_tendsto hinf h1
      have h3 := hmono hs (show (0:ℝ) < 2 * s by positivity) (by linarith)
      linarith
  · rintro ⟨hL, hU⟩
    obtain ⟨a, ha1, ha2⟩ := ((h0.eventually (gt_mem_nhds hL)).and self_mem_nhdsWithin).exists
    obtain ⟨b, hb1, hb2⟩ := ((hinf.eventually (lt_mem_nhds hU)).and (eventually_gt_atTop 0)).exists
    have ha : (0:ℝ) < a := ha2
    have hab : a ≤ b := by
      by_contra h
      push Not at h
      have := hmono hb2 ha h
      linarith
    have hsub : Icc a b ⊆ Ioi 0 := fun t ht => lt_of_lt_of_le ha ht.1
    obtain ⟨s, hs, hfs⟩ := intermediate_value_Icc hab (hcont.mono hsub) ⟨ha1.le, hb1.le⟩
    refine ⟨s, ⟨hsub hs, hfs⟩, ?_⟩
    rintro t ⟨ht, hft⟩
    exact hmono.injOn ht (hsub hs) (hft.trans hfs.symm)

lemma iv_A_eq (S K r q T : ℝ) (hS : 0 < S) (hK : 0 < K) :
    S * exp (-q * T) = K * exp (-r * T) * exp (log (S / K) + (r - q) * T) := by
  rw [exp_add, exp_log (div_pos hS hK)]
  have h : exp (-q * T) = exp (-r * T) * exp ((r - q) * T) := by rw [← exp_add]; ring_nf
  rw [h]; field_simp

lemma iv_d1_eq (S K r q T σ : ℝ) (hT : 0 < T) (hσ : σ ≠ 0) :
    bsD1 S K r q T σ = (log (S / K) + (r - q) * T) / √T * σ⁻¹ + √T / 2 * σ := by
  have hs : √T ≠ 0 := (sqrt_pos.2 hT).ne'
  have hsq : √T ^ 2 = T := sq_sqrt hT.le
  unfold bsD1
  field_simp
  linear_combination (-σ ^ 2) * hsq

lemma iv_pdf_shift (d v : ℝ) :
    gaussianPDFReal 0 1 (d - v) = gaussianPDFReal 0 1 d * exp (d * v - v ^ 2 / 2) := by
  simp only [gaussianPDFReal, NNReal.coe_one, sub_zero, mul_one]
  rw [mul_assoc, ← exp_add]; congr 2; ring

lemma iv_key (S K r q T σ : ℝ) (hS : 0 < S) (hK : 0 < K) (hT : 0 < T) (hσ : σ ≠ 0) :
    K * exp (-r * T) * gaussianPDFReal 0 1 (bsD1 S K r q T σ - σ * √T)
      = S * exp (-q * T) * gaussianPDFReal 0 1 (bsD1 S K r q T σ) := by
  have hs : √T ≠ 0 := (sqrt_pos.2 hT).ne'
  have hsq : √T ^ 2 = T := sq_sqrt hT.le
  rw [iv_pdf_shift, iv_A_eq S K r q T hS hK]
  have h : bsD1 S K r q T σ * (σ * √T) - (σ * √T) ^ 2 / 2 = log (S / K) + (r - q) * T := by
    rw [iv_d1_eq S K r q T σ hT hσ]
    field_simp
    ring
  rw [h]; ring

lemma iv_call_eq (S K r q T s : ℝ) (hT : 0 < T) (hs : s ≠ 0) :
    bsCall S K r q T s =
      S * exp (-q * T) * Φ ((log (S / K) + (r - q) * T) / √T * s⁻¹ + √T / 2 * s)
      - K * exp (-r * T) * Φ ((log (S / K) + (r - q) * T) / √T * s⁻¹ + √T / 2 * s - s * √T) := by
  rw [bsCall, iv_d1_eq S K r q T s hT hs]

lemma iv_call_deriv (S K r q T σ : ℝ) (hS : 0 < S) (hK : 0 < K) (hT : 0 < T) (hσ : 0 < σ) :
    HasDerivAt (fun s => bsCall S K r q T s)
      (S * exp (-q * T) * gaussianPDFReal 0 1 (bsD1 S K r q T σ) * √T) σ := by
  have hg : HasDerivAt (fun s : ℝ => (log (S / K) + (r - q) * T) / √T * s⁻¹ + √T / 2 * s)
      ((log (S / K) + (r - q) * T) / √T * (-(σ ^ 2)⁻¹) + √T / 2 * 1) σ :=
    ((hasDerivAt_inv hσ.ne').const_mul _).add ((hasDerivAt_id σ).const_mul _)
  have hg2 := hg.sub ((hasDerivAt_id σ).mul_const √T)
  have h1 := ((iv_hasDerivAt_cdf _).comp σ hg).const_mul (S * exp (-q * T))
  have h2 := ((iv_hasDerivAt_cdf _).comp σ hg2).const_mul (K * exp (-r * T))
  have h := h1.sub h2
  have hkey := iv_key S K r q T σ hS hK hT hσ.ne'
  rw [iv_d1_eq S K r q T σ hT hσ.ne'] at hkey ⊢
  refine (h.congr_of_eventuallyEq ?_).congr_deriv ?_
  · filter_upwards [Ioi_mem_nhds hσ] with s hs
    rw [iv_call_eq S K r q T s hT (ne_of_gt hs)]
    rfl
  · simp only [id] at hkey ⊢
    linear_combination (-((log (S / K) + (r - q) * T) / √T * (-(σ ^ 2)⁻¹) + √T / 2 * 1 - 1 * √T))
      * hkey

lemma iv_call_tendsto_atTop (S K r q T : ℝ) (hT : 0 < T) :
    Tendsto (fun s => bsCall S K r q T s) atTop (𝓝 (S * exp (-q * T))) := by
  have hsT : 0 < √T := sqrt_pos.2 hT
  set m := log (S / K) + (r - q) * T with hm
  have hinv0 : Tendsto (fun s : ℝ => m / √T * s⁻¹) atTop (𝓝 0) := by
    simpa using tendsto_inv_atTop_zero.const_mul (m / √T)
  have hlin : Tendsto (fun s : ℝ => √T / 2 * s) atTop atTop :=
    tendsto_id.const_mul_atTop (by positivity)
  have hg : Tendsto (fun s : ℝ => m / √T * s⁻¹ + √T / 2 * s) atTop atTop :=
    hinv0.add_atTop hlin
  have hg2 : Tendsto (fun s : ℝ => m / √T * s⁻¹ + √T / 2 * s - s * √T) atTop atBot := by
    have := hinv0.add_atBot (tendsto_neg_atTop_atBot.comp hlin)
    refine this.congr (fun s => ?_)
    simp only [Function.comp_apply]; ring
  have hlim := (((tendsto_cdf_atTop (gaussianReal 0 1)).comp hg).const_mul (S * exp (-q * T))).sub
    (((tendsto_cdf_atBot (gaussianReal 0 1)).comp hg2).const_mul (K * exp (-r * T)))
  rw [mul_one, mul_zero, sub_zero] at hlim
  refine hlim.congr' ?_
  filter_upwards [eventually_gt_atTop 0] with s hs
  rw [iv_call_eq S K r q T s hT hs.ne']
  rfl

lemma iv_call_tendsto_zero (S K r q T : ℝ) (hS : 0 < S) (hK : 0 < K) (hT : 0 < T) :
    Tendsto (fun s => bsCall S K r q T s) (𝓝[>] 0)
      (𝓝 (max (S * exp (-q * T) - K * exp (-r * T)) 0)) := by
  have hsT : 0 < √T := sqrt_pos.2 hT
  have hAB := iv_A_eq S K r q T hS hK
  have hB : 0 < K * exp (-r * T) := by positivity
  set m := log (S / K) + (r - q) * T with hm
  set A := S * exp (-q * T) with hA
  set B := K * exp (-r * T) with hBdef
  have hlin : Tendsto (fun s : ℝ => √T / 2 * s) (𝓝[>] 0) (𝓝 0) := by
    have : Tendsto (fun s : ℝ => √T / 2 * s) (𝓝 0) (𝓝 0) :=
      (continuous_const.mul continuous_id).tendsto' 0 0 (by simp)
    exact this.mono_left nhdsWithin_le_nhds
  have hlin2 : Tendsto (fun s : ℝ => √T / 2 * s - s * √T) (𝓝[>] 0) (𝓝 0) := by
    have : Tendsto (fun s : ℝ => √T / 2 * s - s * √T) (𝓝 0) (𝓝 0) :=
      ((continuous_const.mul continuous_id).sub (continuous_id.mul continuous_const)).tendsto' 0 0
        (by simp)
    exact this.mono_left nhdsWithin_le_nhds
  have heq : (fun s : ℝ => A * Φ (m / √T * s⁻¹ + √T / 2 * s)
      - B * Φ (m / √T * s⁻¹ + √T / 2 * s - s * √T)) =ᶠ[𝓝[>] 0] (fun s => bsCall S K r q T s) := by
    filter_upwards [self_mem_nhdsWithin] with s hs
    rw [iv_call_eq S K r q T s hT (ne_of_gt hs)]
  refine Tendsto.congr' heq ?_
  rcases lt_trichotomy m 0 with h | h | h
  · have hc : m / √T < 0 := div_neg_of_neg_of_pos h hsT
    have h1 : Tendsto (fun s : ℝ => m / √T * s⁻¹) (𝓝[>] 0) atBot :=
      tendsto_inv_nhdsGT_zero.const_mul_atTop_of_neg hc
    have hg : Tendsto (fun s : ℝ => m / √T * s⁻¹ + √T / 2 * s) (𝓝[>] 0) atBot := h1.atBot_add hlin
    have hg2 : Tendsto (fun s : ℝ => m / √T * s⁻¹ + √T / 2 * s - s * √T) (𝓝[>] 0) atBot := by
      refine (h1.atBot_add hlin2).congr (fun s => ?_); ring
    have hlim := (((tendsto_cdf_atBot (gaussianReal 0 1)).comp hg).const_mul A).sub
      (((tendsto_cdf_atBot (gaussianReal 0 1)).comp hg2).const_mul B)
    have hmax : max (A - B) 0 = 0 := by
      apply max_eq_right
      have : exp m < 1 := exp_lt_one_iff.2 h
      rw [hAB]; nlinarith
    rw [hmax]
    simpa using hlim
  · have hg : Tendsto (fun s : ℝ => m / √T * s⁻¹ + √T / 2 * s) (𝓝[>] 0) (𝓝 0) := by
      simpa [h] using hlin
    have hg2 : Tendsto (fun s : ℝ => m / √T * s⁻¹ + √T / 2 * s - s * √T) (𝓝[>] 0) (𝓝 0) := by
      refine hlin2.congr (fun s => ?_); rw [h]; ring
    have hc := iv_cdf_continuous.continuousAt (x := 0)
    have hlim := ((hc.tendsto.comp hg).const_mul A).sub ((hc.tendsto.comp hg2).const_mul B)
    have hAB' : A = B := by rw [hAB, h, exp_zero, mul_one]
    have hmax : max (A - B) 0 = A * Φ 0 - B * Φ 0 := by rw [hAB']; simp
    rw [hmax]
    exact hlim
  · have hc : 0 < m / √T := div_pos h hsT
    have h1 : Tendsto (fun s : ℝ => m / √T * s⁻¹) (𝓝[>] 0) atTop :=
      tendsto_inv_nhdsGT_zero.const_mul_atTop hc
    have hg : Tendsto (fun s : ℝ => m / √T * s⁻¹ + √T / 2 * s) (𝓝[>] 0) atTop := h1.atTop_add hlin
    have hg2 : Tendsto (fun s : ℝ => m / √T * s⁻¹ + √T / 2 * s - s * √T) (𝓝[>] 0) atTop := by
      refine (h1.atTop_add hlin2).congr (fun s => ?_); ring
    have hlim := (((tendsto_cdf_atTop (gaussianReal 0 1)).comp hg).const_mul A).sub
      (((tendsto_cdf_atTop (gaussianReal 0 1)).comp hg2).const_mul B)
    have hmax : max (A - B) 0 = A - B := by
      apply max_eq_left
      have : 1 < exp m := one_lt_exp_iff.2 h
      rw [hAB]; nlinarith
    rw [hmax]
    simpa using hlim

lemma iv_put_eq (S K r q T σ : ℝ) :
    bsPut S K r q T σ = bsCall S K r q T σ - S * exp (-q * T) + K * exp (-r * T) := by
  unfold bsPut bsCall
  rw [show σ * √T - bsD1 S K r q T σ = -(bsD1 S K r q T σ - σ * √T) by ring, iv_cdf_neg,
    iv_cdf_neg]
  ring

end IVHelpers

#print axioms iv_continuous_pdf
#print axioms iv_cdf_eq_integral
#print axioms iv_cdf_eq
#print axioms iv_hasDerivAt_cdf
#print axioms iv_pdf_pos
#print axioms iv_pdf_neg
#print axioms iv_cdf_continuous
#print axioms iv_cdf_neg
#print axioms iv_unique_iff
#print axioms iv_A_eq
#print axioms iv_d1_eq
#print axioms iv_pdf_shift
#print axioms iv_key
#print axioms iv_call_eq
#print axioms iv_call_deriv
#print axioms iv_call_tendsto_atTop
#print axioms iv_call_tendsto_zero
#print axioms iv_put_eq

/-- **Implied volatility exists and is unique exactly inside the fence.** Fix a European call's
share price `S > 0`, strike `K > 0`, time to expiry `T > 0`, bank rate `r` and dividend yield `q`,
and take one quoted price `C`. Write `A = S e^{-qT}` (a share delivered at expiry, bought today)
and `B = K e^{-rT}` (the strike paid at expiry, valued today). Then there is exactly one positive
volatility `σ` whose Black-Scholes price equals the quote if and only if
`max(A - B, 0) < C < A`. -/
theorem implied_volatility_exists_unique_iff (S K r q T C : ℝ)
    (hS : 0 < S) (hK : 0 < K) (hT : 0 < T) :
    (∃! σ : ℝ, 0 < σ ∧ bsCall S K r q T σ = C) ↔
      max (S * exp (-q * T) - K * exp (-r * T)) 0 < C ∧ C < S * exp (-q * T) := by
  exact iv_unique_iff
    (f' := fun s => S * exp (-q * T) * gaussianPDFReal 0 1 (bsD1 S K r q T s) * √T)
    (fun s hs => iv_call_deriv S K r q T s hS hK hT hs)
    (fun s _ => mul_pos (mul_pos (by positivity) (gaussianPDFReal_pos 0 1 _ one_ne_zero))
      (Real.sqrt_pos.2 hT))
    (iv_call_tendsto_zero S K r q T hS hK hT) (iv_call_tendsto_atTop S K r q T hT)

/-- **The put has its own fence** (Step 5). With the same inputs, a quoted put price `P` has
exactly one positive volatility whose Black-Scholes put price equals it if and only if
`max(B - A, 0) < P < B`. -/
theorem put_implied_volatility_exists_unique_iff (S K r q T P : ℝ)
    (hS : 0 < S) (hK : 0 < K) (hT : 0 < T) :
    (∃! σ : ℝ, 0 < σ ∧ bsPut S K r q T σ = P) ↔
      max (K * exp (-r * T) - S * exp (-q * T)) 0 < P ∧ P < K * exp (-r * T) := by
  have hmax : max (S * exp (-q * T) - K * exp (-r * T)) 0 - S * exp (-q * T) + K * exp (-r * T)
      = max (K * exp (-r * T) - S * exp (-q * T)) 0 := by
    rcases le_total (S * exp (-q * T)) (K * exp (-r * T)) with h | h
    · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; ring
    · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; ring
  have hfun : (fun s => bsPut S K r q T s)
      = fun s => bsCall S K r q T s - S * exp (-q * T) + K * exp (-r * T) :=
    funext (iv_put_eq S K r q T)
  have hiff := iv_unique_iff (f := fun s => bsPut S K r q T s) (c := P)
    (f' := fun s => S * exp (-q * T) * gaussianPDFReal 0 1 (bsD1 S K r q T s) * √T)
    (fun s hs => by
      rw [hfun]
      exact ((iv_call_deriv S K r q T s hS hK hT hs).sub_const _).add_const _)
    (fun s _ => mul_pos (mul_pos (by positivity) (gaussianPDFReal_pos 0 1 _ one_ne_zero))
      (Real.sqrt_pos.2 hT))
    (by rw [hfun]; exact ((iv_call_tendsto_zero S K r q T hS hK hT).sub_const _).add_const _)
    (by rw [hfun]; exact ((iv_call_tendsto_atTop S K r q T hT).sub_const _).add_const _)
  rw [hiff, hmax, sub_self, zero_add]

/-- **Vega** (Step 3). At every positive volatility the slope of the call price against `σ` is
`ν = S e^{-qT} φ(d₁) √T`, the prepaid share times the bell curve's height at `d₁` times the square
root of time; every factor is positive. -/
theorem call_vega_eq (S K r q T σ : ℝ)
    (hS : 0 < S) (hK : 0 < K) (hT : 0 < T) (hσ : 0 < σ) :
    HasDerivAt (fun s => bsCall S K r q T s)
      (S * exp (-q * T) * gaussianPDFReal 0 1 (bsD1 S K r q T σ) * √T) σ := by
  exact iv_call_deriv S K r q T σ hS hK hT hσ

/-! Worked numbers from the card: `S = K = 100`, `r = 5/100`, `q = 2/100`, `T = 1`. -/

-- d₁ at σ = 1/5: (ln(100/100) + (0.05 - 0.02 + 0.02) · 1) / (0.20 · √1) = 0.25.
example : (log (100 / 100) + ((5 / 100 : ℝ) - 2 / 100 + (1 / 5) ^ 2 / 2) * 1) / (1 / 5 * √1)
    = 1 / 4 := by norm_num
-- d₂ = d₁ - σ√T = 0.25 - 0.20 = 0.05.
example : (1 / 4 : ℚ) - 1 / 5 * 1 = 1 / 20 := by norm_num
-- The identity d₁² - d₂² = 2m with m = ln(A/B) = 0.03.
example : (1 / 4 : ℚ) ^ 2 - (1 / 20) ^ 2 = 2 * (3 / 100) := by norm_num
-- Floor from the rounded table: A - B = 98.019867 - 95.122942 = 2.896925.
example : (98019867 : ℚ) / 10 ^ 6 - 95122942 / 10 ^ 6 = 2896925 / 10 ^ 6 := by norm_num
-- The quote is inside the fence: 2.896925 < 9.227006 < 98.019867.
example : (2896925 : ℚ) / 10 ^ 6 < 9227006 / 10 ^ 6 ∧ (9227006 : ℚ) / 10 ^ 6 < 98019867 / 10 ^ 6 := by
  norm_num
-- Free money below the floor: a call at 2.80 takes in 2.896925 - 2.80 = 0.096925.
example : (2896925 : ℚ) / 10 ^ 6 - 280 / 100 = 96925 / 10 ^ 6 := by norm_num
-- Free money above the ceiling: a call at 99 keeps 99 - 98.019867 = 0.980133.
example : (99 : ℚ) - 98019867 / 10 ^ 6 = 980133 / 10 ^ 6 := by norm_num
-- One vol point: 37.901158 × 0.01 = 0.37901158, about 0.379012 dollars.
example : (37901158 : ℚ) / 10 ^ 6 * (1 / 100) = 37901158 / 10 ^ 8 := by norm_num

#print axioms implied_volatility_exists_unique_iff
#print axioms put_implied_volatility_exists_unique_iff
#print axioms call_vega_eq
