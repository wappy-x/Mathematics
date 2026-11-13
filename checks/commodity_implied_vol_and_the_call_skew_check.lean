-- Implied vol on a futures option and the commodity smile: a Black-76 call or put quote has exactly one positive implied volatility exactly when it lies strictly between its zero-volatility floor and its ceiling, and on a mean-reverting spot the averaged futures variance is σ_S²(1 - e^(-2κT))/(2κT), so implied vol falls strictly with contract month.
import Mathlib.Probability.CDF
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open Real ProbabilityTheory Set intervalIntegral

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- The first distance `d₁ = (ln(F/K) + σ²T/2) / (σ√T)`; the second is `d₂ = d₁ - σ√T`. -/
noncomputable def black76D1 (F K σ T : ℝ) : ℝ :=
  (log (F / K) + σ ^ 2 * T / 2) / (σ * √T)

/-- The Black-76 call on a futures price: `C(σ) = D [F N(d₁) - K N(d₂)]` with `D = e^(-rT)`. -/
noncomputable def black76Call (F K r σ T : ℝ) : ℝ :=
  exp (-r * T) * (F * stdNormalCDF (black76D1 F K σ T)
    - K * stdNormalCDF (black76D1 F K σ T - σ * √T))

/-- The Black-76 put on a futures price: `P(σ) = D [K N(-d₂) - F N(-d₁)]` with `D = e^(-rT)`. -/
noncomputable def black76Put (F K r σ T : ℝ) : ℝ :=
  exp (-r * T) * (K * stdNormalCDF (-(black76D1 F K σ T - σ * √T))
    - F * stdNormalCDF (-black76D1 F K σ T))

open MeasureTheory Filter Topology

lemma stdNormalCDF_eq_integral (x : ℝ) :
    stdNormalCDF x = ∫ t in Iic x, gaussianPDFReal 0 1 t := by
  unfold stdNormalCDF
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral 0 one_ne_zero,
    ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Iic
      (fun t _ => gaussianPDFReal_nonneg 0 1 t))]

lemma gaussianPDFReal_zero_one (x : ℝ) :
    gaussianPDFReal 0 1 x = (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := by
  simp [gaussianPDFReal]

lemma continuous_gaussianPDFReal_zero_one : Continuous (gaussianPDFReal 0 1) := by
  have : gaussianPDFReal 0 1 = fun x => (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) :=
    funext gaussianPDFReal_zero_one
  rw [this]; fun_prop

lemma hasDerivAt_stdNormalCDF (x : ℝ) :
    HasDerivAt stdNormalCDF (gaussianPDFReal 0 1 x) x := by
  have hi : ∀ y : ℝ, IntegrableOn (gaussianPDFReal 0 1) (Iic y) :=
    fun y => (integrable_gaussianPDFReal 0 1).integrableOn
  have key : stdNormalCDF = fun y => (∫ t in Iic 0, gaussianPDFReal 0 1 t)
      + ∫ t in (0 : ℝ)..y, gaussianPDFReal 0 1 t := by
    funext y
    rw [stdNormalCDF_eq_integral, ← integral_Iic_sub_Iic (hi 0) (hi y)]
    ring
  rw [key]
  exact ((continuous_gaussianPDFReal_zero_one.integral_hasStrictDerivAt 0 x).hasDerivAt).const_add _

lemma continuous_stdNormalCDF : Continuous stdNormalCDF :=
  continuous_iff_continuousAt.2 fun x => (hasDerivAt_stdNormalCDF x).continuousAt

lemma stdNormalCDF_neg (x : ℝ) : stdNormalCDF (-x) = 1 - stdNormalCDF x := by
  have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  unfold stdNormalCDF
  rw [cdf_eq_real, cdf_eq_real]
  have hmap : (gaussianReal 0 1).map (fun x : ℝ => -x) = gaussianReal 0 1 := by
    rw [gaussianReal_map_neg, neg_zero]
  have hpre : (fun x : ℝ => -x) ⁻¹' Iic (-x) = Ici x := by
    ext y; simp
  rw [← hmap, map_measureReal_apply measurable_neg measurableSet_Iic, hpre, hmap,
    ← compl_Iio, measureReal_compl measurableSet_Iio, probReal_univ,
    measureReal_def, measureReal_def, measure_congr Iio_ae_eq_Iic]

lemma tendsto_stdNormalCDF_atTop : Tendsto stdNormalCDF atTop (𝓝 1) :=
  tendsto_cdf_atTop (gaussianReal 0 1)

lemma tendsto_stdNormalCDF_atBot : Tendsto stdNormalCDF atBot (𝓝 0) :=
  tendsto_cdf_atBot (gaussianReal 0 1)

lemma exists_unique_pos_iff_of_strictMonoOn {h : ℝ → ℝ} {L0 L1 c : ℝ}
    (hm : StrictMonoOn h (Ioi 0)) (hc : ContinuousOn h (Ioi 0))
    (h0 : Tendsto h (𝓝[>] 0) (𝓝 L0)) (h1 : Tendsto h atTop (𝓝 L1)) :
    (∃! s : ℝ, 0 < s ∧ h s = c) ↔ L0 < c ∧ c < L1 := by
  have lower : ∀ s, 0 < s → L0 < h s := by
    intro s hs
    have hs2 : 0 < s / 2 := by positivity
    have : L0 ≤ h (s / 2) := by
      refine le_of_tendsto h0 ?_
      filter_upwards [Ioo_mem_nhdsGT hs2] with t ht
      exact (hm ht.1 (show (0:ℝ) < s / 2 from hs2) ht.2).le
    exact this.trans_lt (hm (show (0:ℝ) < s / 2 from hs2) (show (0:ℝ) < s from hs) (by linarith))
  have upper : ∀ s, 0 < s → h s < L1 := by
    intro s hs
    have : h (s + 1) ≤ L1 := by
      refine ge_of_tendsto h1 ?_
      filter_upwards [eventually_gt_atTop (s + 1)] with t ht
      exact (hm (show (0:ℝ) < s + 1 by linarith) (show (0:ℝ) < t by linarith) ht).le
    exact (hm (show (0:ℝ) < s from hs) (show (0:ℝ) < s + 1 by linarith) (by linarith)).trans_le this
  constructor
  · rintro ⟨s, ⟨hs, rfl⟩, -⟩
    exact ⟨lower s hs, upper s hs⟩
  · rintro ⟨hl, hu⟩
    obtain ⟨a, ha, hac⟩ : ∃ a, 0 < a ∧ h a < c := by
      have e1 : ∀ᶠ t in 𝓝[>] (0:ℝ), h t < c := h0 (Iio_mem_nhds hl)
      have e2 : ∀ᶠ t in 𝓝[>] (0:ℝ), 0 < t := self_mem_nhdsWithin
      exact (e2.and e1).exists
    obtain ⟨b, hab, hbc⟩ : ∃ b, a < b ∧ c < h b := by
      have e1 : ∀ᶠ t in atTop, c < h t := h1 (Ioi_mem_nhds hu)
      exact ((eventually_gt_atTop a).and e1).exists
    obtain ⟨s, hs, hsc⟩ := intermediate_value_Icc hab.le
      (hc.mono fun t ht => lt_of_lt_of_le ha ht.1) ⟨hac.le, hbc.le⟩
    refine ⟨s, ⟨lt_of_lt_of_le ha hs.1, hsc⟩, ?_⟩
    rintro u ⟨hu0, huc⟩
    exact hm.injOn hu0 (lt_of_lt_of_le ha hs.1) (huc.trans hsc.symm)

lemma black_density_identity (F K ℓ s : ℝ) (hFK : F = K * exp ℓ) (hs : s ≠ 0) :
    F * gaussianPDFReal 0 1 ((ℓ + s ^ 2 / 2) / s)
      = K * gaussianPDFReal 0 1 ((ℓ + s ^ 2 / 2) / s - s) := by
  rw [gaussianPDFReal_zero_one, gaussianPDFReal_zero_one, hFK]
  have e : ℓ + -((ℓ + s ^ 2 / 2) / s) ^ 2 / 2 = -((ℓ + s ^ 2 / 2) / s - s) ^ 2 / 2 := by
    field_simp; ring
  calc K * exp ℓ * ((√(2 * π))⁻¹ * exp (-((ℓ + s ^ 2 / 2) / s) ^ 2 / 2))
      = K * ((√(2 * π))⁻¹ * exp (ℓ + -((ℓ + s ^ 2 / 2) / s) ^ 2 / 2)) := by
        rw [exp_add]; ring
    _ = _ := by rw [e]

lemma black_g_hasDerivAt (F K ℓ s : ℝ) (hFK : F = K * exp ℓ) (hs : 0 < s) :
    HasDerivAt (fun s : ℝ => F * stdNormalCDF ((ℓ + s ^ 2 / 2) / s)
        - K * stdNormalCDF ((ℓ + s ^ 2 / 2) / s - s))
      (K * gaussianPDFReal 0 1 ((ℓ + s ^ 2 / 2) / s - s)) s := by
  have hd1 : HasDerivAt (fun s : ℝ => (ℓ + s ^ 2 / 2) / s) ((s ^ 2 / 2 - ℓ) / s ^ 2) s := by
    have := (((hasDerivAt_pow 2 s).div_const 2).const_add ℓ).div (hasDerivAt_id s) hs.ne'
    refine this.congr_deriv ?_
    simp only [id]; norm_num; field_simp; ring
  have hd2 : HasDerivAt (fun s : ℝ => (ℓ + s ^ 2 / 2) / s - s) ((s ^ 2 / 2 - ℓ) / s ^ 2 - 1) s :=
    hd1.sub (hasDerivAt_id' s)
  have h1 := ((hasDerivAt_stdNormalCDF _).comp s hd1).const_mul F
  have h2 := ((hasDerivAt_stdNormalCDF _).comp s hd2).const_mul K
  refine (h1.sub h2).congr_deriv ?_
  have key := black_density_identity F K ℓ s hFK hs.ne'
  linear_combination ((s ^ 2 / 2 - ℓ) / s ^ 2) * key

lemma black_g_strictMonoOn (F K ℓ : ℝ) (hK : 0 < K) (hFK : F = K * exp ℓ) :
    StrictMonoOn (fun s : ℝ => F * stdNormalCDF ((ℓ + s ^ 2 / 2) / s)
        - K * stdNormalCDF ((ℓ + s ^ 2 / 2) / s - s)) (Ioi 0) := by
  refine strictMonoOn_of_deriv_pos (convex_Ioi 0) ?_ ?_
  · exact fun x hx => (black_g_hasDerivAt F K ℓ x hFK hx).continuousAt.continuousWithinAt
  · intro x hx
    rw [interior_Ioi] at hx
    rw [(black_g_hasDerivAt F K ℓ x hFK hx).deriv]
    exact mul_pos hK (gaussianPDFReal_pos _ _ _ one_ne_zero)

lemma black_g_continuousOn (F K ℓ : ℝ) (hFK : F = K * exp ℓ) :
    ContinuousOn (fun s : ℝ => F * stdNormalCDF ((ℓ + s ^ 2 / 2) / s)
        - K * stdNormalCDF ((ℓ + s ^ 2 / 2) / s - s)) (Ioi 0) :=
  fun x hx => (black_g_hasDerivAt F K ℓ x hFK hx).continuousAt.continuousWithinAt

lemma black_g_tendsto_atTop (F K ℓ : ℝ) :
    Tendsto (fun s : ℝ => F * stdNormalCDF ((ℓ + s ^ 2 / 2) / s)
        - K * stdNormalCDF ((ℓ + s ^ 2 / 2) / s - s)) atTop (𝓝 F) := by
  have hinv : Tendsto (fun s : ℝ => ℓ * s⁻¹) atTop (𝓝 0) := by
    simpa using tendsto_inv_atTop_zero.const_mul ℓ
  have hhalf : Tendsto (fun s : ℝ => s / 2) atTop atTop := tendsto_id.atTop_div_const (by norm_num)
  have hd1 : Tendsto (fun s : ℝ => (ℓ + s ^ 2 / 2) / s) atTop atTop := by
    refine (hinv.add_atTop hhalf).congr' ?_
    filter_upwards [eventually_gt_atTop 0] with s hs
    field_simp
  have hd2 : Tendsto (fun s : ℝ => (ℓ + s ^ 2 / 2) / s - s) atTop atBot := by
    refine (hinv.add_atBot (tendsto_neg_atTop_atBot.comp hhalf)).congr' ?_
    filter_upwards [eventually_gt_atTop 0] with s hs
    simp only [Function.comp]
    field_simp; ring
  have := ((tendsto_stdNormalCDF_atTop.comp hd1).const_mul F).sub
    ((tendsto_stdNormalCDF_atBot.comp hd2).const_mul K)
  simpa using this

lemma black_g_tendsto_zero (F K ℓ : ℝ) (hK : 0 < K) (hFK : F = K * exp ℓ) :
    Tendsto (fun s : ℝ => F * stdNormalCDF ((ℓ + s ^ 2 / 2) / s)
        - K * stdNormalCDF ((ℓ + s ^ 2 / 2) / s - s)) (𝓝[>] 0) (𝓝 (max (F - K) 0)) := by
  have hhalf : Tendsto (fun s : ℝ => s / 2) (𝓝[>] 0) (𝓝 0) := by
    have : Tendsto (fun s : ℝ => s / 2) (𝓝 0) (𝓝 (0 / 2)) :=
      (continuous_id.div_const 2).tendsto 0
    simpa using this.mono_left nhdsWithin_le_nhds
  have hnhalf : Tendsto (fun s : ℝ => -(s / 2)) (𝓝[>] 0) (𝓝 0) := by
    simpa using hhalf.neg
  have eq1 : (fun s : ℝ => ℓ * s⁻¹ + s / 2) =ᶠ[𝓝[>] 0] fun s => (ℓ + s ^ 2 / 2) / s := by
    filter_upwards [self_mem_nhdsWithin] with s (hs : 0 < s)
    field_simp
  have eq2 : (fun s : ℝ => ℓ * s⁻¹ + -(s / 2)) =ᶠ[𝓝[>] 0]
      fun s => (ℓ + s ^ 2 / 2) / s - s := by
    filter_upwards [self_mem_nhdsWithin] with s (hs : 0 < s)
    field_simp; ring
  rcases lt_trichotomy ℓ 0 with hl | hl | hl
  · have hFK' : F < K := by
      rw [hFK]; nlinarith [exp_lt_one_iff.2 hl]
    have hinv : Tendsto (fun s : ℝ => ℓ * s⁻¹) (𝓝[>] 0) atBot :=
      tendsto_inv_nhdsGT_zero.const_mul_atTop_of_neg hl
    have hd1 := (hinv.atBot_add hhalf).congr' eq1
    have hd2 := (hinv.atBot_add hnhalf).congr' eq2
    have := ((tendsto_stdNormalCDF_atBot.comp hd1).const_mul F).sub
      ((tendsto_stdNormalCDF_atBot.comp hd2).const_mul K)
    rw [max_eq_right (by linarith)]
    simpa using this
  · subst hl
    have hFK' : F = K := by rw [hFK, exp_zero, mul_one]
    have e1 : (fun s : ℝ => s / 2) =ᶠ[𝓝[>] 0] fun s => (0 + s ^ 2 / 2) / s := by
      filter_upwards [self_mem_nhdsWithin] with s (hs : 0 < s)
      field_simp; ring
    have e2 : (fun s : ℝ => -(s / 2)) =ᶠ[𝓝[>] 0] fun s => (0 + s ^ 2 / 2) / s - s := by
      filter_upwards [self_mem_nhdsWithin] with s (hs : 0 < s)
      field_simp; ring
    have hd1 := hhalf.congr' e1
    have hd2 := hnhalf.congr' e2
    have := (((continuous_stdNormalCDF.tendsto 0).comp hd1).const_mul F).sub
      (((continuous_stdNormalCDF.tendsto 0).comp hd2).const_mul K)
    rw [hFK', sub_self, max_self]
    simpa [hFK'] using this
  · have hFK' : K < F := by
      rw [hFK]; nlinarith [one_lt_exp_iff.2 hl]
    have hinv : Tendsto (fun s : ℝ => ℓ * s⁻¹) (𝓝[>] 0) atTop :=
      tendsto_inv_nhdsGT_zero.const_mul_atTop hl
    have hd1 := (hinv.atTop_add hhalf).congr' eq1
    have hd2 := (hinv.atTop_add hnhalf).congr' eq2
    have := ((tendsto_stdNormalCDF_atTop.comp hd1).const_mul F).sub
      ((tendsto_stdNormalCDF_atTop.comp hd2).const_mul K)
    rw [max_eq_left (by linarith)]
    simpa using this

lemma strictMonoOn_comp_scale_props {g : ℝ → ℝ} {D c L0 L1 : ℝ} (hD : 0 < D) (hc : 0 < c)
    (hm : StrictMonoOn g (Ioi 0)) (hco : ContinuousOn g (Ioi 0))
    (h0 : Tendsto g (𝓝[>] 0) (𝓝 L0)) (h1 : Tendsto g atTop (𝓝 L1)) :
    StrictMonoOn (fun σ => D * g (σ * c)) (Ioi 0) ∧ ContinuousOn (fun σ => D * g (σ * c)) (Ioi 0)
      ∧ Tendsto (fun σ => D * g (σ * c)) (𝓝[>] 0) (𝓝 (D * L0))
      ∧ Tendsto (fun σ => D * g (σ * c)) atTop (𝓝 (D * L1)) := by
  have hmaps : MapsTo (fun σ : ℝ => σ * c) (Ioi 0) (Ioi 0) := fun σ hσ => mul_pos hσ hc
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro a ha b hb hab
    exact mul_lt_mul_of_pos_left (hm (hmaps ha) (hmaps hb) (mul_lt_mul_of_pos_right hab hc)) hD
  · exact continuousOn_const.mul (hco.comp (continuous_id.mul continuous_const).continuousOn hmaps)
  · have hsc : Tendsto (fun σ : ℝ => σ * c) (𝓝[>] 0) (𝓝[>] 0) := by
      refine tendsto_nhdsWithin_iff.2 ⟨?_, ?_⟩
      · have : Tendsto (fun σ : ℝ => σ * c) (𝓝 0) (𝓝 (0 * c)) :=
          (continuous_id.mul continuous_const).tendsto 0
        simpa using this.mono_left nhdsWithin_le_nhds
      · filter_upwards [self_mem_nhdsWithin] with σ hσ using hmaps hσ
    exact (h0.comp hsc).const_mul D
  · exact (h1.comp (tendsto_id.atTop_mul_const hc)).const_mul D

lemma black76Call_fun_eq (F K r T : ℝ) (hT : 0 ≤ T) :
    (fun σ => black76Call F K r σ T) = fun σ => exp (-r * T) *
      (F * stdNormalCDF ((log (F / K) + (σ * √T) ^ 2 / 2) / (σ * √T))
        - K * stdNormalCDF ((log (F / K) + (σ * √T) ^ 2 / 2) / (σ * √T) - σ * √T)) := by
  funext σ
  unfold black76Call black76D1
  rw [mul_pow, sq_sqrt hT]

lemma black76Put_eq_call (F K r σ T : ℝ) :
    black76Put F K r σ T = black76Call F K r σ T - exp (-r * T) * (F - K) := by
  unfold black76Put black76Call
  rw [stdNormalCDF_neg, stdNormalCDF_neg]
  ring

lemma one_sub_exp_neg_div_strictAntiOn :
    StrictAntiOn (fun x : ℝ => (1 - exp (-x)) / x) (Ioi 0) := by
  have hd : ∀ x : ℝ, 0 < x →
      HasDerivAt (fun x : ℝ => (1 - exp (-x)) / x) ((exp (-x) * x - (1 - exp (-x))) / x ^ 2) x := by
    intro x hx
    have := ((hasDerivAt_neg x).exp.const_sub 1).div (hasDerivAt_id x) hx.ne'
    refine this.congr_deriv ?_
    simp only [id]; ring
  refine strictAntiOn_of_deriv_neg (convex_Ioi 0) ?_ ?_
  · exact fun x hx => (hd x hx).continuousAt.continuousWithinAt
  · intro x hx
    rw [interior_Ioi] at hx
    have hx' : (0 : ℝ) < x := hx
    rw [(hd x hx').deriv]
    apply div_neg_of_neg_of_pos _ (by positivity)
    have h1 : x + 1 < exp x := add_one_lt_exp hx'.ne'
    have h2 : exp (-x) * exp x = 1 := by rw [← exp_add]; simp
    nlinarith [exp_pos (-x)]

#print axioms stdNormalCDF_eq_integral
#print axioms gaussianPDFReal_zero_one
#print axioms continuous_gaussianPDFReal_zero_one
#print axioms hasDerivAt_stdNormalCDF
#print axioms continuous_stdNormalCDF
#print axioms stdNormalCDF_neg
#print axioms tendsto_stdNormalCDF_atTop
#print axioms tendsto_stdNormalCDF_atBot
#print axioms exists_unique_pos_iff_of_strictMonoOn
#print axioms black_density_identity
#print axioms black_g_hasDerivAt
#print axioms black_g_strictMonoOn
#print axioms black_g_continuousOn
#print axioms black_g_tendsto_atTop
#print axioms black_g_tendsto_zero
#print axioms strictMonoOn_comp_scale_props
#print axioms black76Call_fun_eq
#print axioms black76Put_eq_call
#print axioms one_sub_exp_neg_div_strictAntiOn

/-- **One quote, one volatility** (The formula; Why it works, Steps 0 to 2). Take a European
option on a futures contract, premium paid today, with agreed inputs: futures price `F > 0`,
strike `K > 0`, time to expiry `T > 0` and bank rate `r`, so `D = e^(-rT)` (futures-style
margining is the case `r = 0`, `D = 1`). Price it by Black-76. Then a call quote `C` is matched
by exactly one positive volatility if and only if `D (F - K)⁺ < C < D F`, and a put quote `P`
is matched by exactly one positive volatility if and only if `D (K - F)⁺ < P < D K`. -/
theorem futures_option_implied_vol_exists_unique_iff (F K r T C P : ℝ)
    (hF : 0 < F) (hK : 0 < K) (hT : 0 < T) :
    ((∃! σ : ℝ, 0 < σ ∧ black76Call F K r σ T = C) ↔
        exp (-r * T) * max (F - K) 0 < C ∧ C < exp (-r * T) * F) ∧
      ((∃! σ : ℝ, 0 < σ ∧ black76Put F K r σ T = P) ↔
        exp (-r * T) * max (K - F) 0 < P ∧ P < exp (-r * T) * K) := by
  have hFK : F = K * exp (log (F / K)) := by rw [exp_log (div_pos hF hK)]; field_simp
  have hsT : 0 < √T := sqrt_pos.2 hT
  have P := strictMonoOn_comp_scale_props (exp_pos (-r * T)) hsT
    (black_g_strictMonoOn F K _ hK hFK) (black_g_continuousOn F K _ hFK)
    (black_g_tendsto_zero F K _ hK hFK) (black_g_tendsto_atTop F K _)
  have hfun := black76Call_fun_eq F K r T hT.le
  have hm : StrictMonoOn (fun σ => black76Call F K r σ T) (Ioi 0) := by rw [hfun]; exact P.1
  have hco : ContinuousOn (fun σ => black76Call F K r σ T) (Ioi 0) := by rw [hfun]; exact P.2.1
  have h0 : Tendsto (fun σ => black76Call F K r σ T) (𝓝[>] 0)
      (𝓝 (exp (-r * T) * max (F - K) 0)) := by rw [hfun]; exact P.2.2.1
  have h1 : Tendsto (fun σ => black76Call F K r σ T) atTop (𝓝 (exp (-r * T) * F)) := by
    rw [hfun]; exact P.2.2.2
  refine ⟨exists_unique_pos_iff_of_strictMonoOn hm hco h0 h1, ?_⟩
  have hpfun : (fun σ => black76Put F K r σ T)
      = fun σ => black76Call F K r σ T - exp (-r * T) * (F - K) :=
    funext fun σ => black76Put_eq_call F K r σ T
  have e0 : exp (-r * T) * max (K - F) 0
      = exp (-r * T) * max (F - K) 0 - exp (-r * T) * (F - K) := by
    rcases le_total F K with h | h
    · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; ring
    · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; ring
  have e1 : exp (-r * T) * K = exp (-r * T) * F - exp (-r * T) * (F - K) := by ring
  have hm' : StrictMonoOn (fun σ => black76Put F K r σ T) (Ioi 0) := by
    rw [hpfun]
    intro a ha b hb hab
    simp only
    linarith [hm ha hb hab]
  have hco' : ContinuousOn (fun σ => black76Put F K r σ T) (Ioi 0) := by
    rw [hpfun]; exact hco.sub continuousOn_const
  have h0' : Tendsto (fun σ => black76Put F K r σ T) (𝓝[>] 0)
      (𝓝 (exp (-r * T) * max (K - F) 0)) := by
    rw [hpfun, e0]; exact h0.sub_const _
  have h1' : Tendsto (fun σ => black76Put F K r σ T) atTop (𝓝 (exp (-r * T) * K)) := by
    rw [hpfun, e1]; exact h1.sub_const _
  exact exists_unique_pos_iff_of_strictMonoOn hm' hco' h0' h1'

/-- **The Samuelson formula** (Step 5). On a spot pulled back toward a normal level at a steady
speed `κ > 0`, the contract delivering at `T` has volatility `σ_S e^(-κ(T - t))` at time `t`.
The option's implied variance is the average of its square over the option's life `[0, T]`,
and that average is `σ_S² (1 - e^(-2κT)) / (2κT)`. -/
theorem samuelson_implied_variance (σS κ T : ℝ) (hκ : 0 < κ) (hT : 0 < T) :
    (1 / T) * ∫ t in (0 : ℝ)..T, σS ^ 2 * exp (-2 * κ * (T - t)) =
      σS ^ 2 * (1 - exp (-2 * κ * T)) / (2 * κ * T) := by
  have hκ' : (2 * κ) ≠ 0 := by positivity
  rw [integral_eq_sub_of_hasDerivAt (f := fun t => σS ^ 2 * exp (-2 * κ * (T - t)) / (2 * κ))]
  · simp only [sub_self, mul_zero, exp_zero, sub_zero]
    field_simp
  · intro t _
    have := ((((hasDerivAt_id' t).const_sub T).const_mul (-2 * κ)).exp.const_mul (σS ^ 2)).div_const
      (2 * κ)
    refine this.congr_deriv ?_
    field_simp
  · exact (by fun_prop : Continuous fun t : ℝ => σS ^ 2 * exp (-2 * κ * (T - t))).intervalIntegrable _ _

/-- **Vol fades with contract month** (Step 5). With a spot volatility `σ_S > 0` and a steady
pull-back speed `κ > 0`, the implied volatility `σ_S √((1 - e^(-2κT)) / (2κT))` of the contract
delivering at `T` falls strictly as `T` grows: further contract months carry lower volatility. -/
theorem samuelson_vol_strictly_falls_with_maturity (σS κ : ℝ) (hσS : 0 < σS) (hκ : 0 < κ) :
    StrictAntiOn (fun T : ℝ => σS * √((1 - exp (-2 * κ * T)) / (2 * κ * T))) (Ioi 0) := by
  intro a ha b hb hab
  have ha' : (0 : ℝ) < a := ha
  have hb' : (0 : ℝ) < b := hb
  have e : ∀ T : ℝ, -2 * κ * T = -(2 * κ * T) := fun T => by ring
  simp only [e]
  have hlt := one_sub_exp_neg_div_strictAntiOn (show (0 : ℝ) < 2 * κ * a by positivity)
    (show (0 : ℝ) < 2 * κ * b by positivity) (by nlinarith)
  have hnn : 0 ≤ (1 - exp (-(2 * κ * b))) / (2 * κ * b) := by
    apply div_nonneg _ (by positivity)
    have : exp (-(2 * κ * b)) ≤ 1 := exp_le_one_iff.2 (by nlinarith)
    linarith
  exact mul_lt_mul_of_pos_left (sqrt_lt_sqrt hnn hlt) hσS

/-! Worked numbers from the card, as exact fractions. -/

-- At the money, F = K = 85: the floor D (F - K)⁺ is 0.
example : max ((85 : ℚ) - 85) 0 = 0 := by norm_num
-- The house quote is inside the range: 0 < 7.002679 < 82.901343.
example : (0 : ℚ) < 7002679 / 10 ^ 6 ∧ (7002679 : ℚ) / 10 ^ 6 < 82901343 / 10 ^ 6 := by norm_num
-- A quote of 83.00 sits above the ceiling 82.901343, leaving 0.098657 (about 0.10) riskless.
example : (82901343 : ℚ) / 10 ^ 6 < 83 ∧ (83 : ℚ) - 82901343 / 10 ^ 6 = 98657 / 10 ^ 6 := by
  norm_num
-- Risk reversal 34 - 28 = 6 vol points; butterfly (34 + 28)/2 - 30 = 1 vol point.
example : (34 : ℚ) - 28 = 6 ∧ ((34 : ℚ) + 28) / 2 - 30 = 1 := by norm_num
-- The skew's cost on the 15-delta call: 1.396756 - 0.895547 = 0.501209.
example : (1396756 : ℚ) / 10 ^ 6 - 895547 / 10 ^ 6 = 501209 / 10 ^ 6 := by norm_num
-- The Samuelson exponents with κ = 1.2: 2κT = 1.2 at six months and 4.8 at 24 months.
example : 2 * ((12 : ℚ) / 10) * (1 / 2) = 12 / 10 ∧ 2 * ((12 : ℚ) / 10) * 2 = 48 / 10 := by
  norm_num
-- Six-month factor from the rounded e^(-1.2) = 0.301194: (1 - 0.301194)/1.2 = 0.58233833...
example : (1 - (301194 : ℚ) / 10 ^ 6) / (12 / 10) = 349403 / 600000 := by norm_num
-- Pricing the 24-month call at the front's 30% overpays 12.920768 - 7.733545 = 5.187223.
example : (12920768 : ℚ) / 10 ^ 6 - 7733545 / 10 ^ 6 = 5187223 / 10 ^ 6 := by norm_num

#print axioms futures_option_implied_vol_exists_unique_iff
#print axioms samuelson_implied_variance
#print axioms samuelson_vol_strictly_falls_with_maturity
