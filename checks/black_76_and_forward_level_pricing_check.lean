-- Black-76: if a positive forward quote ends at F e^(-σ²T/2 + σ√T Z) with Z a standard bell-curve draw, the discounted average payoff of a call or put struck at K > 0 is exactly the Black-76 formula, the call minus the put is D(F - K) and equals the spot formula carried to the forward, and the call lies strictly between D·max(F - K, 0) and D·F, climbs strictly with volatility, and so has exactly one implied volatility for every quote inside that band.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Probability.HasLaw
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Real MeasureTheory ProbabilityTheory Set

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- The forward quote on expiry day in the card's model (Step 2): today's forward `F`, the
forward's volatility `σ`, the wait `T`, and a standard bell-curve draw `z`:
`F_T = F e^(-σ²T/2 + σ√T z)`. -/
noncomputable def forwardAtExpiry (F σ T z : ℝ) : ℝ :=
  F * exp (-(σ ^ 2 * T) / 2 + σ * √T * z)

/-- The first distance `d₁ = (ln(F/K) + σ²T/2) / (σ√T)`; the second is `d₂ = d₁ - σ√T`. -/
noncomputable def black76D1 (F K σ T : ℝ) : ℝ :=
  (log (F / K) + σ ^ 2 * T / 2) / (σ * √T)

/-- The Black-76 call premium `C = e^(-rT) [F N(d₁) - K N(d₂)]`. -/
noncomputable def black76Call (F K r σ T : ℝ) : ℝ :=
  exp (-r * T) * (F * stdNormalCDF (black76D1 F K σ T)
    - K * stdNormalCDF (black76D1 F K σ T - σ * √T))

/-- The Black-76 put premium `P = e^(-rT) [K N(-d₂) - F N(-d₁)]`. -/
noncomputable def black76Put (F K r σ T : ℝ) : ℝ :=
  exp (-r * T) * (K * stdNormalCDF (-(black76D1 F K σ T - σ * √T))
    - F * stdNormalCDF (-black76D1 F K σ T))

/-- The spot Black-Scholes call with dividend yield `q` (Step 4):
`C = S e^(-qT) N(d₁) - K e^(-rT) N(d₁ - σ√T)`, with
`d₁ = (ln(S/K) + (r - q + σ²/2) T) / (σ√T)`. -/
noncomputable def blackScholesCall (S K r q σ T : ℝ) : ℝ :=
  let d1 := (log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)
  S * exp (-q * T) * stdNormalCDF d1 - K * exp (-r * T) * stdNormalCDF (d1 - σ * √T)


lemma b76_continuous_pdf : Continuous (gaussianPDFReal 0 1) := by
  unfold gaussianPDFReal; fun_prop

lemma b76_N_eq_integral (x : ℝ) :
    stdNormalCDF x = ∫ t in Iic x, gaussianPDFReal 0 1 t := by
  unfold stdNormalCDF
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Iic
      (fun t _ ↦ gaussianPDFReal_nonneg 0 1 t))]

lemma b76_hasDerivAt_N (x : ℝ) : HasDerivAt stdNormalCDF (gaussianPDFReal 0 1 x) x := by
  have hint : ∀ a, IntegrableOn (gaussianPDFReal 0 1) (Iic a) :=
    fun a ↦ (integrable_gaussianPDFReal 0 1).integrableOn
  have heq : stdNormalCDF = fun y ↦ stdNormalCDF 0 + ∫ t in (0 : ℝ)..y, gaussianPDFReal 0 1 t := by
    funext y
    rw [b76_N_eq_integral, b76_N_eq_integral, ← intervalIntegral.integral_Iic_sub_Iic (hint 0)
      (hint y)]
    ring
  rw [heq]
  exact ((b76_continuous_pdf.integral_hasStrictDerivAt 0 x).hasDerivAt).const_add _

lemma b76_continuous_N : Continuous stdNormalCDF :=
  continuous_iff_continuousAt.2 fun x ↦ (b76_hasDerivAt_N x).continuousAt

lemma b76_real_Ioi (b : ℝ) : (gaussianReal 0 1).real (Ioi b) = 1 - stdNormalCDF b := by
  rw [← compl_Iic, probReal_compl_eq_one_sub measurableSet_Iic, stdNormalCDF, cdf_eq_real]

lemma b76_N_neg (x : ℝ) : stdNormalCDF (-x) = 1 - stdNormalCDF x := by
  rw [← b76_real_Ioi]
  have hmap : (gaussianReal 0 1).map (fun x ↦ -x) = gaussianReal 0 1 := by
    rw [gaussianReal_map_neg, neg_zero]
  have hsing : gaussianReal 0 1 {x} = 0 :=
    gaussianReal_absolutelyContinuous 0 one_ne_zero (Real.volume_singleton)
  rw [stdNormalCDF, cdf_eq_real, ← hmap, map_measureReal_apply measurable_neg measurableSet_Iic,
    hmap, measureReal_congr (Ioi_ae_eq_Ici' hsing)]
  congr 1
  ext t; simp

lemma b76_real_Ioi' (b : ℝ) : (gaussianReal 0 1).real (Ioi b) = stdNormalCDF (-b) := by
  rw [b76_real_Ioi, b76_N_neg]

lemma b76_pdf_shift (s z : ℝ) :
    gaussianPDFReal 0 1 z * exp (-s ^ 2 / 2 + s * z) = gaussianPDFReal s 1 z := by
  unfold gaussianPDFReal
  simp only [NNReal.coe_one, mul_one]
  rw [mul_assoc, ← exp_add]
  congr 2
  ring

lemma b76_setIntegral_exp (s : ℝ) {A : Set ℝ} (hA : MeasurableSet A) :
    ∫ z in A, exp (-s ^ 2 / 2 + s * z) ∂(gaussianReal 0 1) = (gaussianReal s 1).real A := by
  rw [← integral_indicator hA, integral_gaussianReal_eq_integral_smul one_ne_zero]
  have : ∀ z, gaussianPDFReal 0 1 z • A.indicator (fun z ↦ exp (-s ^ 2 / 2 + s * z)) z
      = A.indicator (gaussianPDFReal s 1) z := by
    intro z
    by_cases hz : z ∈ A
    · simp [hz, b76_pdf_shift]
    · simp [hz]
  simp_rw [this]
  rw [integral_indicator hA, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (setIntegral_nonneg hA (fun t _ ↦ gaussianPDFReal_nonneg s 1 t))]

lemma b76_shift_Ioi (s b : ℝ) :
    (gaussianReal s 1).real (Ioi b) = stdNormalCDF (s - b) := by
  have h := gaussianReal_map_add_const (μ := 0) (v := 1) s
  rw [zero_add] at h
  rw [← h, map_measureReal_apply (measurable_add_const s) measurableSet_Ioi,
    preimage_add_const_Ioi, b76_real_Ioi']
  ring_nf

lemma b76_integrable_exp (s : ℝ) :
    Integrable (fun z ↦ exp (-s ^ 2 / 2 + s * z)) (gaussianReal 0 1) := by
  have := (integrable_exp_mul_gaussianReal (μ := 0) (v := 1) s).const_mul (exp (-s ^ 2 / 2))
  simpa [← exp_add] using this

lemma b76_forward_eq (F σ T : ℝ) (hT : 0 < T) (z : ℝ) :
    forwardAtExpiry F σ T z = F * exp (-(σ * √T) ^ 2 / 2 + (σ * √T) * z) := by
  unfold forwardAtExpiry
  rw [mul_pow, sq_sqrt hT.le]

lemma b76_continuous_forward (F σ T : ℝ) : Continuous (forwardAtExpiry F σ T) := by
  unfold forwardAtExpiry; fun_prop

lemma b76_integrable_forward (F σ T : ℝ) (hT : 0 < T) :
    Integrable (forwardAtExpiry F σ T) (gaussianReal 0 1) := by
  have : forwardAtExpiry F σ T = fun z ↦ F * exp (-(σ * √T) ^ 2 / 2 + (σ * √T) * z) :=
    funext (b76_forward_eq F σ T hT)
  rw [this]
  exact (b76_integrable_exp _).const_mul F

lemma b76_integral_forward (F σ T : ℝ) (hT : 0 < T) :
    ∫ z, forwardAtExpiry F σ T z ∂(gaussianReal 0 1) = F := by
  have : forwardAtExpiry F σ T = fun z ↦ F * exp (-(σ * √T) ^ 2 / 2 + (σ * √T) * z) :=
    funext (b76_forward_eq F σ T hT)
  rw [this, integral_const_mul, ← setIntegral_univ, b76_setIntegral_exp _ MeasurableSet.univ]
  simp

lemma b76_call_integral (F K σ T : ℝ) (hF : 0 < F) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    ∫ z, max (forwardAtExpiry F σ T z - K) 0 ∂(gaussianReal 0 1) =
      F * stdNormalCDF (black76D1 F K σ T) - K * stdNormalCDF (black76D1 F K σ T - σ * √T) := by
  set s := σ * √T with hs_def
  have hs : 0 < s := mul_pos hσ (sqrt_pos.2 hT)
  have hd1 : black76D1 F K σ T = (log (F / K) + s ^ 2 / 2) / s := by
    unfold black76D1
    rw [hs_def, mul_pow, sq_sqrt hT.le]
  set d1 := black76D1 F K σ T
  set b := -(d1 - s) with hb
  have key : ∀ z, (0 < F * exp (-s ^ 2 / 2 + s * z) - K ↔ b < z) := by
    intro z
    have hsb : s * b = s ^ 2 / 2 - log (F / K) := by
      rw [hb, hd1]; field_simp; ring
    have hlog : log (F / K) = log F - log K := log_div hF.ne' hK.ne'
    rw [sub_pos, ← Real.log_lt_log_iff hK (by positivity), Real.log_mul hF.ne' (exp_pos _).ne',
      Real.log_exp]
    constructor
    · intro h
      have : s * b < s * z := by rw [hsb, hlog]; linarith
      exact lt_of_mul_lt_mul_left this hs.le
    · intro h
      have := mul_lt_mul_of_pos_left h hs
      rw [hsb, hlog] at this
      linarith
  have hpt : ∀ z, max (forwardAtExpiry F σ T z - K) 0 =
      (Ioi b).indicator (fun z ↦ F * exp (-s ^ 2 / 2 + s * z) - K) z := by
    intro z
    rw [b76_forward_eq F σ T hT z]
    by_cases hz : b < z
    · rw [indicator_of_mem (show z ∈ Ioi b from hz), max_eq_left ((key z).2 hz).le]
    · rw [indicator_of_notMem (show z ∉ Ioi b from hz), max_eq_right (not_lt.1 (mt (key z).1 hz))]
  simp_rw [hpt]
  rw [integral_indicator measurableSet_Ioi, integral_sub, integral_const_mul,
    b76_setIntegral_exp _ measurableSet_Ioi, setIntegral_const, b76_shift_Ioi, b76_real_Ioi']
  · simp only [smul_eq_mul, hb]
    ring_nf
  · exact ((b76_integrable_exp s).const_mul F).integrableOn
  · exact integrableOn_const

lemma b76_put_integral (F K σ T : ℝ) (hF : 0 < F) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    ∫ z, max (K - forwardAtExpiry F σ T z) 0 ∂(gaussianReal 0 1) =
      F * stdNormalCDF (black76D1 F K σ T) - K * stdNormalCDF (black76D1 F K σ T - σ * √T)
        - (F - K) := by
  have hpt : ∀ z, max (K - forwardAtExpiry F σ T z) 0 =
      max (forwardAtExpiry F σ T z - K) 0 - (forwardAtExpiry F σ T z - K) := by
    intro z
    rcases max_cases (K - forwardAtExpiry F σ T z) 0 with h | h <;>
      rcases max_cases (forwardAtExpiry F σ T z - K) 0 with h' | h' <;> linarith
  have hfwd := b76_integrable_forward F σ T hT
  simp_rw [hpt]
  have h1 : Integrable (fun z ↦ forwardAtExpiry F σ T z - K) (gaussianReal 0 1) :=
    hfwd.sub (integrable_const K)
  rw [integral_sub h1.pos_part h1, integral_sub hfwd (integrable_const K), b76_call_integral F K σ T hF hK hσ hT,
    b76_integral_forward F σ T hT]
  simp

lemma b76_pdf_ratio (F K σ T : ℝ) (hF : 0 < F) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    F * gaussianPDFReal 0 1 (black76D1 F K σ T) =
      K * gaussianPDFReal 0 1 (black76D1 F K σ T - σ * √T) := by
  set s := σ * √T with hs_def
  have hs : 0 < s := mul_pos hσ (sqrt_pos.2 hT)
  have hd1 : black76D1 F K σ T = (log (F / K) + s ^ 2 / 2) / s := by
    unfold black76D1
    rw [hs_def, mul_pow, sq_sqrt hT.le]
  set d1 := black76D1 F K σ T
  have hsd : s * d1 = log (F / K) + s ^ 2 / 2 := by rw [hd1]; field_simp
  unfold gaussianPDFReal
  have hexp : -(d1 - s - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ)) =
      -(d1 - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ)) + log (F / K) := by
    simp only [NNReal.coe_one]
    linear_combination hsd
  rw [hexp, exp_add, exp_log (div_pos hF hK)]
  field_simp

lemma b76_hasDerivAt_call (F K r T : ℝ) (hF : 0 < F) (hK : 0 < K) (hT : 0 < T) (σ : ℝ)
    (hσ : 0 < σ) :
    HasDerivAt (fun σ ↦ black76Call F K r σ T)
      (exp (-r * T) * (K * gaussianPDFReal 0 1 (black76D1 F K σ T - σ * √T) * √T)) σ := by
  have hnum : HasDerivAt (fun x : ℝ ↦ log (F / K) + x ^ 2 * T / 2) _ σ :=
    (((hasDerivAt_pow 2 σ).mul_const T).div_const 2).const_add (log (F / K))
  have hden : HasDerivAt (fun x : ℝ ↦ x * √T) (1 * √T) σ := (hasDerivAt_id' σ).mul_const √T
  obtain ⟨d', hd1⟩ : ∃ d', HasDerivAt (fun x ↦ black76D1 F K x T) d' σ :=
    ⟨_, hnum.div hden (mul_pos hσ (sqrt_pos.2 hT)).ne'⟩
  have hd2 := hd1.sub hden
  have hN1 := (b76_hasDerivAt_N (black76D1 F K σ T)).comp σ hd1
  have hN2 := (b76_hasDerivAt_N (black76D1 F K σ T - σ * √T)).comp σ hd2
  have h := ((hN1.const_mul F).sub (hN2.const_mul K)).const_mul (exp (-r * T))
  refine h.congr_deriv ?_
  have key := b76_pdf_ratio F K σ T hF hK hσ hT
  linear_combination (exp (-r * T) * d') * key

lemma b76_d1_split (F K σ T : ℝ) (hσ : 0 < σ) (hT : 0 < T) :
    black76D1 F K σ T = log (F / K) / √T * σ⁻¹ + √T / 2 * σ := by
  have hw : 0 < √T := sqrt_pos.2 hT
  unfold black76D1
  rw [show σ ^ 2 * T = (σ * √T) ^ 2 by rw [mul_pow, sq_sqrt hT.le]]
  field_simp

lemma b76_d2_split (F K σ T : ℝ) (hσ : 0 < σ) (hT : 0 < T) :
    black76D1 F K σ T - σ * √T = log (F / K) / √T * σ⁻¹ + -(√T / 2) * σ := by
  rw [b76_d1_split F K σ T hσ hT]
  ring

open Filter Topology in
lemma b76_lim_top (F K r T : ℝ) (hT : 0 < T) :
    Tendsto (fun σ ↦ black76Call F K r σ T) atTop (𝓝 (exp (-r * T) * F)) := by
  have hw : 0 < √T := sqrt_pos.2 hT
  have hA : Tendsto (fun σ : ℝ ↦ log (F / K) / √T * σ⁻¹) atTop (𝓝 0) := by
    simpa using tendsto_inv_atTop_zero.const_mul (log (F / K) / √T)
  have hB : Tendsto (fun σ : ℝ ↦ √T / 2 * σ) atTop atTop :=
    tendsto_id.const_mul_atTop (by positivity)
  have hB' : Tendsto (fun σ : ℝ ↦ -(√T / 2) * σ) atTop atBot :=
    tendsto_id.const_mul_atTop_of_neg (by linarith)
  have h1 : Tendsto (fun σ ↦ black76D1 F K σ T) atTop atTop := by
    refine (hB.atTop_add hA |>.congr' ?_)
    filter_upwards [eventually_gt_atTop 0] with σ hσ
    rw [b76_d1_split F K σ T hσ hT]; ring
  have h2 : Tendsto (fun σ ↦ black76D1 F K σ T - σ * √T) atTop atBot := by
    refine (hB'.atBot_add hA |>.congr' ?_)
    filter_upwards [eventually_gt_atTop 0] with σ hσ
    rw [b76_d2_split F K σ T hσ hT]; ring
  have hN1 : Tendsto (fun σ ↦ stdNormalCDF (black76D1 F K σ T)) atTop (𝓝 1) :=
    Tendsto.comp (tendsto_cdf_atTop (μ := gaussianReal 0 1)) h1
  have hN2 : Tendsto (fun σ ↦ stdNormalCDF (black76D1 F K σ T - σ * √T)) atTop (𝓝 0) :=
    Tendsto.comp (tendsto_cdf_atBot (μ := gaussianReal 0 1)) h2
  have h := ((hN1.const_mul F).sub (hN2.const_mul K)).const_mul (exp (-r * T))
  rw [show exp (-r * T) * F = exp (-r * T) * (F * 1 - K * 0) by ring]
  exact h

open Filter Topology in
lemma b76_lim_zero (F K r T : ℝ) (hF : 0 < F) (hK : 0 < K) (hT : 0 < T) :
    Tendsto (fun σ ↦ black76Call F K r σ T) (𝓝[>] 0) (𝓝 (exp (-r * T) * max (F - K) 0)) := by
  have hw : 0 < √T := sqrt_pos.2 hT
  have hid : Tendsto (fun σ : ℝ ↦ σ) (𝓝[>] 0) (𝓝 0) := tendsto_id.mono_left nhdsWithin_le_nhds
  have hB : Tendsto (fun σ : ℝ ↦ √T / 2 * σ) (𝓝[>] 0) (𝓝 0) := by
    simpa using hid.const_mul (√T / 2)
  have hB' : Tendsto (fun σ : ℝ ↦ -(√T / 2) * σ) (𝓝[>] 0) (𝓝 0) := by
    simpa using hid.const_mul (-(√T / 2))
  have ev1 : (fun σ ↦ log (F / K) / √T * σ⁻¹ + √T / 2 * σ) =ᶠ[𝓝[>] 0]
      fun σ ↦ black76D1 F K σ T := by
    filter_upwards [self_mem_nhdsWithin] with σ hσ
    exact (b76_d1_split F K σ T hσ hT).symm
  have ev2 : (fun σ ↦ log (F / K) / √T * σ⁻¹ + -(√T / 2) * σ) =ᶠ[𝓝[>] 0]
      fun σ ↦ black76D1 F K σ T - σ * √T := by
    filter_upwards [self_mem_nhdsWithin] with σ hσ
    exact (b76_d2_split F K σ T hσ hT).symm
  rcases lt_trichotomy F K with h | h | h
  · have ha : log (F / K) < 0 := log_neg (div_pos hF hK) ((div_lt_one hK).2 h)
    have hA : Tendsto (fun σ : ℝ ↦ log (F / K) / √T * σ⁻¹) (𝓝[>] 0) atBot :=
      tendsto_inv_nhdsGT_zero.const_mul_atTop_of_neg (div_neg_of_neg_of_pos ha hw)
    have hN1 : Tendsto (fun σ ↦ stdNormalCDF (black76D1 F K σ T)) (𝓝[>] 0) (𝓝 0) :=
      Tendsto.comp (tendsto_cdf_atBot (μ := gaussianReal 0 1)) ((hA.atBot_add hB).congr' ev1)
    have hN2 : Tendsto (fun σ ↦ stdNormalCDF (black76D1 F K σ T - σ * √T)) (𝓝[>] 0) (𝓝 0) :=
      Tendsto.comp (tendsto_cdf_atBot (μ := gaussianReal 0 1)) ((hA.atBot_add hB').congr' ev2)
    have h' := ((hN1.const_mul F).sub (hN2.const_mul K)).const_mul (exp (-r * T))
    rw [max_eq_right (by linarith), show exp (-r * T) * 0 = exp (-r * T) * (F * 0 - K * 0) by ring]
    exact h'
  · subst h
    have hN1 : Tendsto (fun σ ↦ stdNormalCDF (black76D1 F F σ T)) (𝓝[>] 0)
        (𝓝 (stdNormalCDF 0)) := by
      refine (b76_continuous_N.tendsto 0).comp ((tendsto_congr' ev1).1 ?_)
      simp only [div_self hF.ne', log_one, zero_div, zero_mul, zero_add]; exact hB
    have hN2 : Tendsto (fun σ ↦ stdNormalCDF (black76D1 F F σ T - σ * √T)) (𝓝[>] 0)
        (𝓝 (stdNormalCDF 0)) := by
      refine (b76_continuous_N.tendsto 0).comp ((tendsto_congr' ev2).1 ?_)
      simp only [div_self hF.ne', log_one, zero_div, zero_mul, zero_add]; exact hB'
    have h' := ((hN1.const_mul F).sub (hN2.const_mul F)).const_mul (exp (-r * T))
    rw [show exp (-r * T) * max (F - F) 0 = exp (-r * T) * (F * stdNormalCDF 0 - F * stdNormalCDF 0)
      by simp]
    exact h'
  · have ha : 0 < log (F / K) := log_pos ((one_lt_div hK).2 h)
    have hA : Tendsto (fun σ : ℝ ↦ log (F / K) / √T * σ⁻¹) (𝓝[>] 0) atTop :=
      tendsto_inv_nhdsGT_zero.const_mul_atTop (div_pos ha hw)
    have hN1 : Tendsto (fun σ ↦ stdNormalCDF (black76D1 F K σ T)) (𝓝[>] 0) (𝓝 1) :=
      Tendsto.comp (tendsto_cdf_atTop (μ := gaussianReal 0 1)) ((hA.atTop_add hB).congr' ev1)
    have hN2 : Tendsto (fun σ ↦ stdNormalCDF (black76D1 F K σ T - σ * √T)) (𝓝[>] 0) (𝓝 1) :=
      Tendsto.comp (tendsto_cdf_atTop (μ := gaussianReal 0 1)) ((hA.atTop_add hB').congr' ev2)
    have h' := ((hN1.const_mul F).sub (hN2.const_mul K)).const_mul (exp (-r * T))
    rw [max_eq_left (by linarith), show exp (-r * T) * (F - K) = exp (-r * T) * (F * 1 - K * 1) by ring]
    exact h'

#print axioms b76_continuous_pdf
#print axioms b76_N_eq_integral
#print axioms b76_hasDerivAt_N
#print axioms b76_continuous_N
#print axioms b76_real_Ioi
#print axioms b76_N_neg
#print axioms b76_real_Ioi'
#print axioms b76_pdf_shift
#print axioms b76_setIntegral_exp
#print axioms b76_shift_Ioi
#print axioms b76_integrable_exp
#print axioms b76_forward_eq
#print axioms b76_continuous_forward
#print axioms b76_integrable_forward
#print axioms b76_integral_forward
#print axioms b76_call_integral
#print axioms b76_put_integral
#print axioms b76_pdf_ratio
#print axioms b76_hasDerivAt_call
#print axioms b76_d1_split
#print axioms b76_d2_split
#print axioms b76_lim_top
#print axioms b76_lim_zero

/-- **Black-76** (The formula, Steps 2 and 3). Take the forward quote to wander lognormally with
one constant volatility `σ > 0` and no drift, so that on expiry day, after a wait `T > 0`, it is
`F_T = F e^(-σ²T/2 + σ√T Z)` with `Z` a standard bell-curve draw; take today's forward `F > 0`
and the strike `K > 0`; the option is exercised on expiry day only and the cash arrives that
day, discounted at a known bank rate `r` by `D = e^(-rT)`. Then the call's premium, `D` times
the average of `(F_T - K)⁺`, is `D [F N(d₁) - K N(d₂)]`, and the put's premium, `D` times the
average of `(K - F_T)⁺`, is `D [K N(-d₂) - F N(-d₁)]`. -/
theorem black76_premium_is_discounted_average_payoff
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {Z : Ω → ℝ}
    (F K r σ T : ℝ) (hF : 0 < F) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (hZ : HasLaw Z (gaussianReal 0 1) P) :
    exp (-r * T) * ∫ ω, max (forwardAtExpiry F σ T (Z ω) - K) 0 ∂P = black76Call F K r σ T ∧
      exp (-r * T) * ∫ ω, max (K - forwardAtExpiry F σ T (Z ω)) 0 ∂P = black76Put F K r σ T := by
  have hc : Continuous (fun z ↦ max (forwardAtExpiry F σ T z - K) 0) :=
    ((b76_continuous_forward F σ T).sub continuous_const).max continuous_const
  have hp : Continuous (fun z ↦ max (K - forwardAtExpiry F σ T z) 0) :=
    (continuous_const.sub (b76_continuous_forward F σ T)).max continuous_const
  have e1 := hZ.integral_comp hc.aestronglyMeasurable
  have e2 := hZ.integral_comp hp.aestronglyMeasurable
  simp only [Function.comp_def] at e1 e2
  rw [e1, e2, b76_call_integral F K σ T hF hK hσ hT, b76_put_integral F K σ T hF hK hσ hT]
  unfold black76Call black76Put
  rw [b76_N_neg, b76_N_neg]
  constructor <;> ring

/-- **Parity, and one contract in two coordinates** (The formula; Step 4). For a forward
`F > 0`, a strike `K > 0`, volatility `σ > 0` and wait `T > 0`, the call minus the put is the
forward discounted, `C - P = D (F - K)`, with volatility nowhere in it. And starting instead from
today's spot price `S > 0` with dividend yield `q`, the spot Black-Scholes call equals the
Black-76 call on the carried forward `F = S e^((r - q)T)`: the carry is eaten by the logarithm
and the two discounts merge into one. -/
theorem black76_parity_and_spot_coordinates (S F K r q σ T : ℝ)
    (hS : 0 < S) (hF : 0 < F) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    black76Call F K r σ T - black76Put F K r σ T = exp (-r * T) * (F - K) ∧
      blackScholesCall S K r q σ T = black76Call (S * exp ((r - q) * T)) K r σ T := by
  constructor
  · unfold black76Call black76Put
    rw [b76_N_neg, b76_N_neg]
    ring
  · unfold blackScholesCall black76Call black76D1
    have hlog : log (S * exp ((r - q) * T) / K) = log (S / K) + (r - q) * T := by
      rw [mul_div_right_comm, log_mul (div_pos hS hK).ne' (exp_pos _).ne', log_exp]
    have hd : (log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) =
        (log (S * exp ((r - q) * T) / K) + σ ^ 2 * T / 2) / (σ * √T) := by
      rw [hlog]; ring
    have he : exp (-r * T) * (S * exp ((r - q) * T)) = S * exp (-q * T) := by
      rw [mul_left_comm, ← exp_add]; ring_nf
    dsimp only
    rw [hd]
    set X := (log (S * exp ((r - q) * T) / K) + σ ^ 2 * T / 2) / (σ * √T)
    linear_combination (-(stdNormalCDF X)) * he

/-- **The premium band and the one implied volatility** (The formula). For a forward `F > 0`,
a strike `K > 0` and a wait `T > 0`, at every volatility `σ > 0` the call premium lies strictly
above `D (F - K)` (indeed above `D max(F - K, 0)`) and strictly below `D F`; it climbs strictly
with volatility; and so every quote strictly inside the band from `D max(F - K, 0)` to `D F`
comes from exactly one volatility. -/
theorem black76_call_band_and_unique_implied_volatility (F K r T : ℝ)
    (hF : 0 < F) (hK : 0 < K) (hT : 0 < T) :
    (∀ σ : ℝ, 0 < σ →
        exp (-r * T) * (F - K) < black76Call F K r σ T ∧
        exp (-r * T) * max (F - K) 0 < black76Call F K r σ T ∧
        black76Call F K r σ T < exp (-r * T) * F) ∧
      StrictMonoOn (fun σ ↦ black76Call F K r σ T) (Ioi 0) ∧
      ∀ c : ℝ, exp (-r * T) * max (F - K) 0 < c → c < exp (-r * T) * F →
        ∃! σ : ℝ, 0 < σ ∧ black76Call F K r σ T = c := by
  open Filter Topology in
  have hD : 0 < exp (-r * T) := exp_pos _
  have hderiv := b76_hasDerivAt_call F K r T hF hK hT
  have hcont : ContinuousOn (fun σ ↦ black76Call F K r σ T) (Ioi 0) :=
    fun σ hσ ↦ (hderiv σ hσ).continuousAt.continuousWithinAt
  have hmono : StrictMonoOn (fun σ ↦ black76Call F K r σ T) (Ioi 0) := by
    refine strictMonoOn_of_deriv_pos (convex_Ioi 0) hcont fun σ hσ ↦ ?_
    rw [interior_Ioi] at hσ
    rw [(hderiv σ hσ).deriv]
    exact mul_pos hD (mul_pos (mul_pos hK (gaussianPDFReal_pos _ _ _ one_ne_zero))
      (sqrt_pos.2 hT))
  have h0 := b76_lim_zero F K r T hF hK hT
  have hinf := b76_lim_top F K r T hT
  have lower : ∀ σ : ℝ, 0 < σ → exp (-r * T) * max (F - K) 0 < black76Call F K r σ T := by
    intro σ hσ
    have hle : exp (-r * T) * max (F - K) 0 ≤ black76Call F K r (σ / 2) T := by
      refine le_of_tendsto h0 ?_
      filter_upwards [Ioo_mem_nhdsGT (half_pos hσ)] with x hx
      exact (hmono hx.1 (half_pos hσ) hx.2).le
    exact hle.trans_lt (hmono (half_pos hσ) hσ (half_lt_self hσ))
  have upper : ∀ σ : ℝ, 0 < σ → black76Call F K r σ T < exp (-r * T) * F := by
    intro σ hσ
    have h2 : (0 : ℝ) < 2 * σ := by linarith
    have hle : black76Call F K r (2 * σ) T ≤ exp (-r * T) * F := by
      refine ge_of_tendsto hinf ?_
      filter_upwards [eventually_gt_atTop (2 * σ)] with x hx
      exact (hmono h2 (h2.trans hx) hx).le
    exact (hmono hσ h2 (by linarith)).trans_le hle
  refine ⟨fun σ hσ ↦ ⟨?_, lower σ hσ, upper σ hσ⟩, hmono, fun c hc1 hc2 ↦ ?_⟩
  · refine lt_of_le_of_lt ?_ (lower σ hσ)
    exact mul_le_mul_of_nonneg_left (le_max_left _ _) hD.le
  obtain ⟨σ1, hσ1c, hσ1⟩ := ((h0.eventually (gt_mem_nhds hc1)).and self_mem_nhdsWithin).exists
  obtain ⟨σ2, hσ2c, hσ2⟩ :=
    ((hinf.eventually (lt_mem_nhds hc2)).and (eventually_gt_atTop 0)).exists
  have hσ1 : (0 : ℝ) < σ1 := hσ1
  have h12 : σ1 ≤ σ2 := by
    by_contra hcon
    have := hmono hσ2 hσ1 (lt_of_not_ge hcon)
    simp only at this hσ1c hσ2c
    linarith
  obtain ⟨σ, hσmem, hσeq⟩ := intermediate_value_Icc h12
    (hcont.mono fun x hx ↦ lt_of_lt_of_le hσ1 hx.1) ⟨hσ1c.le, hσ2c.le⟩
  have hσpos : 0 < σ := lt_of_lt_of_le hσ1 hσmem.1
  refine ⟨σ, ⟨hσpos, hσeq⟩, fun y hy ↦ ?_⟩
  exact hmono.injOn hy.1 hσpos (hy.2.trans hσeq.symm)

-- The card's Acme numbers: ln(F/K) = 0.03, σ = 0.20, T = 1.
-- d₁ = (0.03 + 0.20²/2) / 0.20 = 0.25 and d₂ = 0.25 - 0.20 = 0.05.
example : ((3 : ℚ) / 100 + (20 / 100) ^ 2 * 1 / 2) / (20 / 100 * 1) = 1 / 4 ∧
    (1 : ℚ) / 4 - 20 / 100 = 1 / 20 := by norm_num
-- The same d₁ from the card's own definitions: F = 100 e^(0.03), K = 100, σ = 0.2, T = 1.
example : black76D1 (100 * exp (3 / 100)) 100 (1 / 5) 1 = 1 / 4 := by
  unfold black76D1
  rw [show (100 : ℝ) * exp (3 / 100) / 100 = exp (3 / 100) by ring, log_exp, sqrt_one]
  norm_num
-- The carry exponent: (r - q) T = (0.05 - 0.02) × 1 = 0.03.
example : ((5 : ℚ) / 100 - 2 / 100) * 1 = 3 / 100 := by norm_num
-- What the call settles for: at a quote of 120 it pays 20; at 80, nothing.
example : max ((120 : ℚ) - 100) 0 = 20 ∧ max ((80 : ℚ) - 100) 0 = 0 := by norm_num
-- The payoff chart: 80, 85, ..., 130 against strike 100 gives 0,0,0,0,0,5,10,...,30.
example : (List.range 11).map (fun i ↦ max ((80 : ℤ) + 5 * i - 100) 0) =
    [0, 0, 0, 0, 0, 5, 10, 15, 20, 25, 30] := by decide
-- The switch split at 120: collect 120, pay 100, net 20.
example : (120 : ℚ) * 1 - 100 * 1 = 20 := by norm_num

#print axioms black76_premium_is_discounted_average_payoff
#print axioms black76_parity_and_spot_coordinates
#print axioms black76_call_band_and_unique_implied_volatility
