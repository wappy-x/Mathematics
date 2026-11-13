-- Strike from delta: in the Garman-Kohlhagen model the spot and forward deltas of an FX option fall strictly as the strike rises, so each delta inside its range names exactly one strike, given by the one-line quantile formula; the premium-adjusted put delta names exactly one strike for every negative value, and the premium-adjusted call delta has exactly one peak, so each value below the peak names exactly two strikes, the peak value one, and higher values none.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Order.Monotone.Basic
import Mathlib.Data.Set.Card

open Real MeasureTheory ProbabilityTheory Set

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- `φ(x)`: the height of the standard bell curve at `x`. -/
noncomputable def stdNormalPDF (x : ℝ) : ℝ := gaussianPDFReal 0 1 x

/-- The forward rate `F = S e^((r_d - r_f) T)`: spot `S` (dollars per euro), dollar rate `r_d`,
euro rate `r_f`, time `T` in years. -/
noncomputable def fxForward (S rd rf T : ℝ) : ℝ := S * exp ((rd - rf) * T)

/-- The helper `d₁ = (ln(F/K) + σ²T/2) / (σ√T)` at strike `K`. -/
noncomputable def gkD1 (S rd rf σ T K : ℝ) : ℝ :=
  (log (fxForward S rd rf T / K) + σ ^ 2 * T / 2) / (σ * √T)

/-- The helper `d₂ = d₁ - σ√T` at strike `K`. -/
noncomputable def gkD2 (S rd rf σ T K : ℝ) : ℝ := gkD1 S rd rf σ T K - σ * √T

/-- The drag on a delta: `e^(-r_f T)` for a spot delta (`spot = true`), `1` for a forward delta
(`spot = false`). -/
noncomputable def fxDrag (spot : Bool) (rf T : ℝ) : ℝ := if spot then exp (-rf * T) else 1

/-- The call's spot or forward delta as a function of the strike: `e^(-r_f T) N(d₁)` or `N(d₁)`. -/
noncomputable def callDelta (spot : Bool) (S rd rf σ T K : ℝ) : ℝ :=
  fxDrag spot rf T * stdNormalCDF (gkD1 S rd rf σ T K)

/-- The put's spot or forward delta as a function of the strike: `-e^(-r_f T) N(-d₁)` or
`-N(-d₁)`. -/
noncomputable def putDelta (spot : Bool) (S rd rf σ T K : ℝ) : ℝ :=
  -(fxDrag spot rf T * stdNormalCDF (-gkD1 S rd rf σ T K))

/-- The call's premium-adjusted spot or forward delta: `e^(-r_f T) (K/F) N(d₂)` or `(K/F) N(d₂)`. -/
noncomputable def paCallDelta (spot : Bool) (S rd rf σ T K : ℝ) : ℝ :=
  fxDrag spot rf T * (K / fxForward S rd rf T) * stdNormalCDF (gkD2 S rd rf σ T K)

/-- The put's premium-adjusted spot or forward delta: `-e^(-r_f T) (K/F) N(-d₂)` or
`-(K/F) N(-d₂)`. -/
noncomputable def paPutDelta (spot : Bool) (S rd rf σ T K : ℝ) : ℝ :=
  -(fxDrag spot rf T * (K / fxForward S rd rf T) * stdNormalCDF (-gkD2 S rd rf σ T K))

lemma phi_eq (x : ℝ) : stdNormalPDF x = (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := by
  simp [stdNormalPDF, gaussianPDFReal]

lemma phi_pos (x : ℝ) : 0 < stdNormalPDF x := gaussianPDFReal_pos _ _ _ one_ne_zero

lemma phi_cont : Continuous stdNormalPDF := by
  have : stdNormalPDF = fun x => (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := funext phi_eq
  rw [this]; fun_prop

lemma phi_hasDeriv (x : ℝ) : HasDerivAt stdNormalPDF (-x * stdNormalPDF x) x := by
  have : stdNormalPDF = fun x => (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := funext phi_eq
  rw [this]
  have h := (((hasDerivAt_pow 2 x).neg.div_const 2).exp).const_mul (√(2 * π))⁻¹
  convert h using 1
  simp; ring

lemma N_eq_integral (x : ℝ) : stdNormalCDF x = ∫ t in Iic x, stdNormalPDF t := by
  rw [stdNormalCDF, cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Iic (fun t _ => gaussianPDFReal_nonneg 0 1 t))]
  rfl

lemma N_sub (x : ℝ) : stdNormalCDF x = stdNormalCDF 0 + ∫ t in (0:ℝ)..x, stdNormalPDF t := by
  rw [N_eq_integral, N_eq_integral, ← intervalIntegral.integral_Iic_sub_Iic]
  · ring
  · exact (integrable_gaussianPDFReal 0 1).integrableOn
  · exact (integrable_gaussianPDFReal 0 1).integrableOn

lemma N_hasDeriv (x : ℝ) : HasDerivAt stdNormalCDF (stdNormalPDF x) x := by
  have h := ((phi_cont.integral_hasStrictDerivAt 0 x).hasDerivAt).const_add (stdNormalCDF 0)
  convert h using 1
  funext y; exact N_sub y

lemma N_cont : Continuous stdNormalCDF :=
  continuous_iff_continuousAt.2 fun x => (N_hasDeriv x).continuousAt

lemma N_strictMono : StrictMono stdNormalCDF :=
  strictMono_of_hasDerivAt_pos N_hasDeriv phi_pos

lemma N_tendsto_bot : Filter.Tendsto stdNormalCDF Filter.atBot (nhds 0) := tendsto_cdf_atBot _

lemma N_tendsto_top : Filter.Tendsto stdNormalCDF Filter.atTop (nhds 1) := tendsto_cdf_atTop _

lemma N_pos (x : ℝ) : 0 < stdNormalCDF x :=
  lt_of_le_of_lt (cdf_nonneg _ (x - 1)) (N_strictMono (by linarith))

lemma N_lt_one (x : ℝ) : stdNormalCDF x < 1 :=
  lt_of_lt_of_le (N_strictMono (by linarith : x < x + 1)) (cdf_le_one _ _)

lemma N_surj (y : ℝ) (h0 : 0 < y) (h1 : y < 1) : ∃ z, stdNormalCDF z = y := by
  obtain ⟨a, ha⟩ := ((tendsto_order.1 N_tendsto_bot).2 y h0).exists
  obtain ⟨b, hb⟩ := ((tendsto_order.1 N_tendsto_top).1 y h1).exists
  exact intermediate_value_univ a b N_cont ⟨ha.le, hb.le⟩

lemma sq_tendsto_bot (a : ℝ) : Filter.Tendsto (fun x : ℝ => exp (-(x + a) ^ 2 / 2)) Filter.atBot (nhds 0) := by
  have h1 : Filter.Tendsto (fun x : ℝ => -(x + a)) Filter.atBot Filter.atTop :=
    Filter.tendsto_neg_atBot_atTop.comp (Filter.tendsto_atBot_add_const_right _ a Filter.tendsto_id)
  have h2 : Filter.Tendsto (fun x : ℝ => (-(x + a)) ^ 2 / 2) Filter.atBot Filter.atTop :=
    ((Filter.tendsto_pow_atTop two_ne_zero).comp h1).atTop_div_const (by norm_num)
  refine Real.tendsto_exp_atBot.comp ?_
  have h3 := Filter.tendsto_neg_atTop_atBot.comp h2
  refine h3.congr fun x => ?_
  simp; ring

lemma sq_tendsto_top (a : ℝ) : Filter.Tendsto (fun x : ℝ => exp (-(x + a) ^ 2 / 2)) Filter.atTop (nhds 0) := by
  have h1 : Filter.Tendsto (fun x : ℝ => (x + a)) Filter.atTop Filter.atTop :=
    Filter.tendsto_atTop_add_const_right _ a Filter.tendsto_id
  have h2 : Filter.Tendsto (fun x : ℝ => (x + a) ^ 2 / 2) Filter.atTop Filter.atTop :=
    ((Filter.tendsto_pow_atTop two_ne_zero).comp h1).atTop_div_const (by norm_num)
  refine Real.tendsto_exp_atBot.comp ?_
  have h3 := Filter.tendsto_neg_atTop_atBot.comp h2
  refine h3.congr fun x => ?_
  simp; ring

lemma fxForward_pos {S : ℝ} (rd rf T : ℝ) (hS : 0 < S) : 0 < fxForward S rd rf T :=
  mul_pos hS (exp_pos _)

lemma fxDrag_pos (spot : Bool) (rf T : ℝ) : 0 < fxDrag spot rf T := by
  cases spot <;> simp [fxDrag, exp_pos]

lemma sq_sigma_T {σ T : ℝ} (hT : 0 < T) : σ ^ 2 * T = (σ * √T) ^ 2 := by
  rw [mul_pow, sq_sqrt hT.le]

lemma gkD1_eq (S rd rf σ T : ℝ) {K : ℝ} (hS : 0 < S) (hT : 0 < T) (hK : 0 < K) :
    gkD1 S rd rf σ T K =
      (log (fxForward S rd rf T) - log K + (σ * √T) ^ 2 / 2) / (σ * √T) := by
  rw [gkD1, log_div (fxForward_pos rd rf T hS).ne' hK.ne', sq_sigma_T hT]

lemma gkD1_mul_exp (S rd rf σ T w : ℝ) (hS : 0 < S) (hT : 0 < T) :
    gkD1 S rd rf σ T (fxForward S rd rf T * exp w) = (-w + σ ^ 2 * T / 2) / (σ * √T) := by
  have hF := fxForward_pos rd rf T hS
  rw [gkD1_eq S rd rf σ T hS hT (mul_pos hF (exp_pos w)), log_mul hF.ne' (exp_pos w).ne',
    log_exp, sq_sigma_T hT]
  ring

lemma gkD1_strictAntiOn (S rd rf σ T : ℝ) (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T) :
    StrictAntiOn (gkD1 S rd rf σ T) (Ioi 0) := by
  intro a ha b hb hab
  have hs : 0 < σ * √T := mul_pos hσ (sqrt_pos.2 hT)
  rw [gkD1_eq S rd rf σ T hS hT ha, gkD1_eq S rd rf σ T hS hT hb]
  apply div_lt_div_of_pos_right _ hs
  have := log_lt_log (mem_Ioi.1 ha) hab
  linarith

lemma gkD1_continuousOn (S rd rf σ T : ℝ) (hS : 0 < S) :
    ContinuousOn (gkD1 S rd rf σ T) (Ioi 0) := by
  intro K hK
  have hK' : K ≠ 0 := (mem_Ioi.1 hK).ne'
  have hF := (fxForward_pos rd rf T hS).ne'
  apply ContinuousAt.continuousWithinAt
  exact (((continuousAt_const.div continuousAt_id hK').log (div_ne_zero hF hK')).add
    continuousAt_const).div_const _

lemma gkD2_strictAntiOn (S rd rf σ T : ℝ) (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T) :
    StrictAntiOn (gkD2 S rd rf σ T) (Ioi 0) := by
  intro a ha b hb hab
  have := gkD1_strictAntiOn S rd rf σ T hS hσ hT ha hb hab
  simp only [gkD2]; linarith

lemma gkD2_continuousOn (S rd rf σ T : ℝ) (hS : 0 < S) :
    ContinuousOn (gkD2 S rd rf σ T) (Ioi 0) :=
  (gkD1_continuousOn S rd rf σ T hS).sub continuousOn_const

/-- `K / F = exp (-s d₂ - s²/2)` for a positive strike. -/
lemma strike_div_forward (S rd rf σ T : ℝ) {K : ℝ} (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T)
    (hK : 0 < K) :
    K / fxForward S rd rf T = exp (-(σ * √T) * gkD2 S rd rf σ T K - (σ * √T) ^ 2 / 2) := by
  have hs : 0 < σ * √T := mul_pos hσ (sqrt_pos.2 hT)
  have hF := fxForward_pos rd rf T hS
  rw [gkD2, gkD1_eq S rd rf σ T hS hT hK]
  have : -(σ * √T) * ((log (fxForward S rd rf T) - log K + (σ * √T) ^ 2 / 2) / (σ * √T) - σ * √T)
      - (σ * √T) ^ 2 / 2 = log K - log (fxForward S rd rf T) := by
    field_simp; ring
  rw [this, exp_sub, exp_log hK, exp_log hF]

lemma gkD2_of_exp (S rd rf σ T x : ℝ) (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T) :
    gkD2 S rd rf σ T (fxForward S rd rf T * exp (-(σ * √T) * x - (σ * √T) ^ 2 / 2)) = x := by
  have hs : 0 < σ * √T := mul_pos hσ (sqrt_pos.2 hT)
  rw [gkD2, gkD1_mul_exp S rd rf σ T _ hS hT, sq_sigma_T hT]
  field_simp; ring

lemma unimodal_lt {g : ℝ → ℝ} {xs : ℝ} (hmono : StrictMonoOn g (Iic xs))
    (hanti : StrictAntiOn g (Ici xs)) (x : ℝ) (hx : x ≠ xs) : g x < g xs := by
  rcases lt_or_gt_of_ne hx with h | h
  · exact hmono (mem_Iic.2 h.le) (mem_Iic.2 le_rfl) h
  · exact hanti (mem_Ici.2 le_rfl) (mem_Ici.2 h.le) h

lemma unimodal_count {g : ℝ → ℝ} {xs : ℝ} (hc : Continuous g) (hmono : StrictMonoOn g (Iic xs))
    (hanti : StrictAntiOn g (Ici xs)) (hbot : Filter.Tendsto g Filter.atBot (nhds 0))
    (htop : Filter.Tendsto g Filter.atTop (nhds 0)) (y : ℝ) (hy : 0 < y) (hy2 : y < g xs) :
    ∃ a b, a < xs ∧ xs < b ∧ ∀ x, g x = y ↔ x = a ∨ x = b := by
  obtain ⟨t, ht, htx⟩ := (((tendsto_order.1 hbot).2 y hy).and (Filter.eventually_le_atBot xs)).exists
  obtain ⟨u, hu, hux⟩ := (((tendsto_order.1 htop).2 y hy).and (Filter.eventually_ge_atTop xs)).exists
  obtain ⟨a, ha, hga⟩ := intermediate_value_Icc htx hc.continuousOn ⟨ht.le, hy2.le⟩
  obtain ⟨b, hb, hgb⟩ := intermediate_value_Icc' hux hc.continuousOn ⟨hu.le, hy2.le⟩
  have hax : a < xs := lt_of_le_of_ne ha.2 (by rintro rfl; linarith)
  have hbx : xs < b := lt_of_le_of_ne hb.1 (by rintro rfl; linarith)
  refine ⟨a, b, hax, hbx, fun x => ⟨fun hx => ?_, ?_⟩⟩
  · rcases le_total x xs with h | h
    · exact Or.inl (hmono.injOn (mem_Iic.2 h) (mem_Iic.2 hax.le) (hx.trans hga.symm))
    · exact Or.inr (hanti.injOn (mem_Ici.2 h) (mem_Ici.2 hbx.le) (hx.trans hgb.symm))
  · rintro (rfl | rfl)
    · exact hga
    · exact hgb

lemma kfun_hasDeriv (s x : ℝ) :
    HasDerivAt (fun x => stdNormalPDF x - s * stdNormalCDF x) (-(x + s) * stdNormalPDF x) x := by
  have h := (phi_hasDeriv x).sub ((N_hasDeriv x).const_mul s)
  convert h using 1; ring

lemma kfun_cont (s : ℝ) : Continuous (fun x => stdNormalPDF x - s * stdNormalCDF x) :=
  continuous_iff_continuousAt.2 fun x => (kfun_hasDeriv s x).continuousAt

lemma kfun_strictMonoOn (s : ℝ) :
    StrictMonoOn (fun x => stdNormalPDF x - s * stdNormalCDF x) (Iic (-s)) := by
  refine strictMonoOn_of_hasDerivWithinAt_pos (convex_Iic _) (kfun_cont s).continuousOn
    (fun x _ => (kfun_hasDeriv s x).hasDerivWithinAt) fun x hx => ?_
  rw [interior_Iic, mem_Iio] at hx
  have := phi_pos x
  nlinarith

lemma kfun_strictAntiOn (s : ℝ) :
    StrictAntiOn (fun x => stdNormalPDF x - s * stdNormalCDF x) (Ici (-s)) := by
  refine strictAntiOn_of_hasDerivWithinAt_neg (convex_Ici _) (kfun_cont s).continuousOn
    (fun x _ => (kfun_hasDeriv s x).hasDerivWithinAt) fun x hx => ?_
  rw [interior_Ici, mem_Ioi] at hx
  have := phi_pos x
  nlinarith

lemma phi_tendsto_bot : Filter.Tendsto stdNormalPDF Filter.atBot (nhds 0) := by
  have h := (sq_tendsto_bot 0).const_mul (√(2 * π))⁻¹
  rw [mul_zero] at h
  refine h.congr fun x => ?_
  rw [phi_eq, add_zero]

lemma phi_tendsto_top : Filter.Tendsto stdNormalPDF Filter.atTop (nhds 0) := by
  have h := (sq_tendsto_top 0).const_mul (√(2 * π))⁻¹
  rw [mul_zero] at h
  refine h.congr fun x => ?_
  rw [phi_eq, add_zero]

lemma kfun_pos {s : ℝ} (x : ℝ) (hx : x ≤ -s) : 0 < stdNormalPDF x - s * stdNormalCDF x := by
  have hlim : Filter.Tendsto (fun x => stdNormalPDF x - s * stdNormalCDF x) Filter.atBot
      (nhds 0) := by
    have := phi_tendsto_bot.sub (N_tendsto_bot.const_mul s)
    simpa using this
  have hge : ∀ y ≤ -s, 0 ≤ stdNormalPDF y - s * stdNormalCDF y := by
    intro y hy
    refine le_of_tendsto hlim ?_
    filter_upwards [Filter.eventually_le_atBot y] with t ht
    exact (kfun_strictMonoOn s).monotoneOn (mem_Iic.2 (ht.trans hy)) (mem_Iic.2 hy) ht
  exact lt_of_le_of_lt (hge (x - 1) (by linarith))
    (kfun_strictMonoOn s (mem_Iic.2 (by linarith)) (mem_Iic.2 hx) (by linarith))

lemma kfun_root {s : ℝ} (hs : 0 < s) : ∃ xs, -s < xs ∧ stdNormalPDF xs - s * stdNormalCDF xs = 0 ∧
    (∀ x < xs, 0 < stdNormalPDF x - s * stdNormalCDF x) ∧
    (∀ x, xs < x → stdNormalPDF x - s * stdNormalCDF x < 0) := by
  have hlim : Filter.Tendsto (fun x => stdNormalPDF x - s * stdNormalCDF x) Filter.atTop
      (nhds (0 - s * 1)) := phi_tendsto_top.sub (N_tendsto_top.const_mul s)
  obtain ⟨b, hb⟩ := ((tendsto_order.1 hlim).2 0 (by linarith)).exists
  have hbs : -s < b := by
    by_contra h
    exact absurd (kfun_pos b (le_of_not_gt h)) (not_lt.2 hb.le)
  have hk0 := kfun_pos (s := s) (-s) le_rfl
  obtain ⟨xs, hxs, hxs0⟩ := intermediate_value_Icc' hbs.le (kfun_cont s).continuousOn
    ⟨hb.le, hk0.le⟩
  have hxs1 : -s < xs := lt_of_le_of_ne hxs.1 (by rintro rfl; simp at hxs0; linarith)
  refine ⟨xs, hxs1, hxs0, fun x hx => ?_, fun x hx => ?_⟩
  · rcases le_or_gt x (-s) with h | h
    · exact kfun_pos x h
    · have := kfun_strictAntiOn s (mem_Ici.2 h.le) (mem_Ici.2 hxs1.le) hx
      simp only at this hxs0; linarith
  · have := kfun_strictAntiOn s (mem_Ici.2 hxs1.le) (mem_Ici.2 (hxs1.trans hx).le) hx
    simp only at this hxs0; linarith

lemma gfun_hasDeriv (s x : ℝ) :
    HasDerivAt (fun x => exp (-s * x - s ^ 2 / 2) * stdNormalCDF x)
      (exp (-s * x - s ^ 2 / 2) * (stdNormalPDF x - s * stdNormalCDF x)) x := by
  have h1 : HasDerivAt (fun x => -s * x - s ^ 2 / 2) (-s) x := by
    simpa using ((hasDerivAt_id x).const_mul (-s)).sub_const (s ^ 2 / 2)
  have h := h1.exp.mul (N_hasDeriv x)
  convert h using 1; ring

lemma gfun_cont (s : ℝ) : Continuous (fun x => exp (-s * x - s ^ 2 / 2) * stdNormalCDF x) :=
  continuous_iff_continuousAt.2 fun x => (gfun_hasDeriv s x).continuousAt

lemma gfun_tendsto_top {s : ℝ} (hs : 0 < s) :
    Filter.Tendsto (fun x => exp (-s * x - s ^ 2 / 2) * stdNormalCDF x) Filter.atTop (nhds 0) := by
  have hlin : Filter.Tendsto (fun x : ℝ => -s * x - s ^ 2 / 2) Filter.atTop Filter.atBot := by
    have := Filter.tendsto_neg_atTop_atBot.comp
      (Filter.tendsto_atTop_add_const_right _ (s ^ 2 / 2)
        (Filter.Tendsto.const_mul_atTop hs Filter.tendsto_id))
    refine this.congr fun x => ?_
    simp; ring
  have he := Real.tendsto_exp_atBot.comp hlin
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds he (fun x => ?_) fun x => ?_
  · exact (mul_pos (exp_pos _) (N_pos x)).le
  · simp only [Function.comp]
    exact mul_le_of_le_one_right (exp_pos _).le (N_lt_one x).le

lemma gfun_tendsto_bot {s : ℝ} (hs : 0 < s) :
    Filter.Tendsto (fun x => exp (-s * x - s ^ 2 / 2) * stdNormalCDF x) Filter.atBot (nhds 0) := by
  have h := (sq_tendsto_bot s).const_mul ((√(2 * π))⁻¹ / s)
  rw [mul_zero] at h
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds h
    (Filter.Eventually.of_forall fun x => (mul_pos (exp_pos _) (N_pos x)).le) ?_
  filter_upwards [Filter.eventually_le_atBot (-s)] with x hx
  have hk := kfun_pos x hx
  have hN : stdNormalCDF x ≤ stdNormalPDF x / s := by
    rw [le_div_iff₀ hs]; linarith
  calc exp (-s * x - s ^ 2 / 2) * stdNormalCDF x
      ≤ exp (-s * x - s ^ 2 / 2) * (stdNormalPDF x / s) :=
        mul_le_mul_of_nonneg_left hN (exp_pos _).le
    _ = (√(2 * π))⁻¹ / s * exp (-(x + s) ^ 2 / 2) := by
        rw [phi_eq, mul_div_assoc', mul_left_comm, ← exp_add]
        have : -s * x - s ^ 2 / 2 + -x ^ 2 / 2 = -(x + s) ^ 2 / 2 := by ring
        rw [this]; ring

#print axioms phi_eq
#print axioms phi_pos
#print axioms phi_cont
#print axioms phi_hasDeriv
#print axioms N_eq_integral
#print axioms N_sub
#print axioms N_hasDeriv
#print axioms N_cont
#print axioms N_strictMono
#print axioms N_tendsto_bot
#print axioms N_tendsto_top
#print axioms N_pos
#print axioms N_lt_one
#print axioms N_surj
#print axioms sq_tendsto_bot
#print axioms sq_tendsto_top
#print axioms fxForward_pos
#print axioms fxDrag_pos
#print axioms sq_sigma_T
#print axioms gkD1_eq
#print axioms gkD1_mul_exp
#print axioms gkD1_strictAntiOn
#print axioms gkD1_continuousOn
#print axioms gkD2_strictAntiOn
#print axioms gkD2_continuousOn
#print axioms strike_div_forward
#print axioms gkD2_of_exp
#print axioms unimodal_lt
#print axioms unimodal_count
#print axioms kfun_hasDeriv
#print axioms kfun_cont
#print axioms kfun_strictMonoOn
#print axioms kfun_strictAntiOn
#print axioms phi_tendsto_bot
#print axioms phi_tendsto_top
#print axioms kfun_pos
#print axioms kfun_root
#print axioms gfun_hasDeriv
#print axioms gfun_cont
#print axioms gfun_tendsto_top
#print axioms gfun_tendsto_bot

/-- **Spot and forward deltas: one strike, in one line** (The formula; Why it works, Steps 1 and
2). In the Garman-Kohlhagen model with spot `S > 0`, volatility `σ > 0` attached to the strike,
time `T > 0` and any constant rates `r_d`, `r_f`, take a spot delta (drag `c = e^(-r_f T)`) or a
forward delta (drag `c = 1`). A call delta `Δ` with `0 < Δ < c` is the delta of exactly one
positive strike, and if `N(z) = Δ / c` that strike is `K = F exp(-z σ√T + σ²T/2)`. A put delta
`Δ` with `-c < Δ < 0` is the delta of exactly one positive strike, and if `N(z) = |Δ| / c` that
strike is `K = F exp(z σ√T + σ²T/2)`. -/
theorem fx_strike_from_delta_one_line
    (spot : Bool) (S rd rf σ T : ℝ) (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T) :
    (∀ Δ : ℝ, 0 < Δ → Δ < fxDrag spot rf T →
      (∃! K : ℝ, 0 < K ∧ callDelta spot S rd rf σ T K = Δ) ∧
      ∀ z : ℝ, stdNormalCDF z = Δ / fxDrag spot rf T →
        callDelta spot S rd rf σ T
          (fxForward S rd rf T * exp (-(z * (σ * √T)) + σ ^ 2 * T / 2)) = Δ) ∧
    (∀ Δ : ℝ, -fxDrag spot rf T < Δ → Δ < 0 →
      (∃! K : ℝ, 0 < K ∧ putDelta spot S rd rf σ T K = Δ) ∧
      ∀ z : ℝ, stdNormalCDF z = |Δ| / fxDrag spot rf T →
        putDelta spot S rd rf σ T
          (fxForward S rd rf T * exp (z * (σ * √T) + σ ^ 2 * T / 2)) = Δ) := by
  have hc := fxDrag_pos spot rf T
  have hs : 0 < σ * √T := mul_pos hσ (sqrt_pos.2 hT)
  have hF := fxForward_pos rd rf T hS
  have hinj := (gkD1_strictAntiOn S rd rf σ T hS hσ hT).injOn
  constructor
  · intro Δ h0 h1
    have formula : ∀ z : ℝ, stdNormalCDF z = Δ / fxDrag spot rf T →
        callDelta spot S rd rf σ T
          (fxForward S rd rf T * exp (-(z * (σ * √T)) + σ ^ 2 * T / 2)) = Δ := by
      intro z hz
      rw [callDelta, gkD1_mul_exp S rd rf σ T _ hS hT]
      have : (-(-(z * (σ * √T)) + σ ^ 2 * T / 2) + σ ^ 2 * T / 2) / (σ * √T) = z := by
        field_simp; ring
      rw [this, hz]; field_simp
    refine ⟨?_, formula⟩
    obtain ⟨z, hz⟩ := N_surj (Δ / fxDrag spot rf T) (div_pos h0 hc) ((div_lt_one hc).2 h1)
    refine ⟨_, ⟨mul_pos hF (exp_pos _), formula z hz⟩, ?_⟩
    rintro K ⟨hK, hKΔ⟩
    have h2 := formula z hz
    rw [← hKΔ, callDelta, callDelta] at h2
    have h3 := N_strictMono.injective (mul_left_cancel₀ hc.ne' h2)
    exact (hinj (mem_Ioi.2 (mul_pos hF (exp_pos _))) (mem_Ioi.2 hK) h3).symm
  · intro Δ h0 h1
    have habs : |Δ| = -Δ := abs_of_neg h1
    have formula : ∀ z : ℝ, stdNormalCDF z = |Δ| / fxDrag spot rf T →
        putDelta spot S rd rf σ T
          (fxForward S rd rf T * exp (z * (σ * √T) + σ ^ 2 * T / 2)) = Δ := by
      intro z hz
      rw [putDelta, gkD1_mul_exp S rd rf σ T _ hS hT]
      have : -((-(z * (σ * √T) + σ ^ 2 * T / 2) + σ ^ 2 * T / 2) / (σ * √T)) = z := by
        field_simp; ring
      rw [this, hz, habs]; field_simp
    refine ⟨?_, formula⟩
    obtain ⟨z, hz⟩ := N_surj (|Δ| / fxDrag spot rf T) (div_pos (by rw [habs]; linarith) hc)
      ((div_lt_one hc).2 (by rw [habs]; linarith))
    refine ⟨_, ⟨mul_pos hF (exp_pos _), formula z hz⟩, ?_⟩
    rintro K ⟨hK, hKΔ⟩
    have h2 := formula z hz
    rw [← hKΔ, putDelta, putDelta, neg_inj] at h2
    have h3 := neg_inj.1 (N_strictMono.injective (mul_left_cancel₀ hc.ne' h2))
    exact (hinj (mem_Ioi.2 (mul_pos hF (exp_pos _))) (mem_Ioi.2 hK) h3).symm

/-- **The premium-adjusted put: unique for every negative delta** (Why it works, Step 4, detailed
proof). Under the same terms, the premium-adjusted put delta, spot or forward, falls strictly as
the strike rises, and every negative delta `Δ < 0` is the premium-adjusted put delta of exactly one
positive strike. -/
theorem premium_adjusted_put_strike_unique
    (spot : Bool) (S rd rf σ T : ℝ) (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T) :
    StrictAntiOn (paPutDelta spot S rd rf σ T) (Ioi 0) ∧
      ∀ Δ : ℝ, Δ < 0 → ∃! K : ℝ, 0 < K ∧ paPutDelta spot S rd rf σ T K = Δ := by
  have hc := fxDrag_pos spot rf T
  have hF := fxForward_pos rd rf T hS
  have h2 := gkD2_strictAntiOn S rd rf σ T hS hσ hT
  -- the positive function `f K = c (K/F) N(-d₂)`, with `paPutDelta = -f`
  have hf : StrictMonoOn (fun K => fxDrag spot rf T * (K / fxForward S rd rf T) *
      stdNormalCDF (-gkD2 S rd rf σ T K)) (Ioi 0) := by
    intro a ha b hb hab
    have ha' : 0 < a := ha
    have hN : stdNormalCDF (-gkD2 S rd rf σ T a) < stdNormalCDF (-gkD2 S rd rf σ T b) :=
      N_strictMono (neg_lt_neg (h2 ha hb hab))
    have hNa := N_pos (-gkD2 S rd rf σ T a)
    have hdiv : a / fxForward S rd rf T < b / fxForward S rd rf T := div_lt_div_of_pos_right hab hF
    have hapos : 0 < a / fxForward S rd rf T := div_pos ha' hF
    have key : a / fxForward S rd rf T * stdNormalCDF (-gkD2 S rd rf σ T a) <
        b / fxForward S rd rf T * stdNormalCDF (-gkD2 S rd rf σ T b) := by nlinarith
    show fxDrag spot rf T * (a / fxForward S rd rf T) * stdNormalCDF (-gkD2 S rd rf σ T a) <
      fxDrag spot rf T * (b / fxForward S rd rf T) * stdNormalCDF (-gkD2 S rd rf σ T b)
    rw [mul_assoc, mul_assoc]
    exact mul_lt_mul_of_pos_left key hc
  have hanti : StrictAntiOn (paPutDelta spot S rd rf σ T) (Ioi 0) := by
    intro a ha b hb hab
    simp only [paPutDelta]
    exact neg_lt_neg (hf ha hb hab)
  refine ⟨hanti, fun Δ hΔ => ?_⟩
  have hcont : ContinuousOn (fun K => fxDrag spot rf T * (K / fxForward S rd rf T) *
      stdNormalCDF (-gkD2 S rd rf σ T K)) (Ioi 0) :=
    (continuousOn_const.mul (continuousOn_id.div_const _)).mul
      (N_cont.comp_continuousOn (gkD2_continuousOn S rd rf σ T hS).neg)
  set a := -Δ / fxDrag spot rf T with ha_def
  have ha : 0 < a := div_pos (by linarith) hc
  have hn0 := N_pos 0
  -- a strike with value below `-Δ`
  set K1 := fxForward S rd rf T * a / 2 with hK1
  have hK1pos : 0 < K1 := by positivity
  have hv1 : fxDrag spot rf T * (K1 / fxForward S rd rf T) *
      stdNormalCDF (-gkD2 S rd rf σ T K1) < -Δ := by
    have e : K1 / fxForward S rd rf T = a / 2 := by rw [hK1]; field_simp
    rw [e]
    have := N_lt_one (-gkD2 S rd rf σ T K1)
    have hca : fxDrag spot rf T * a = -Δ := by rw [ha_def]; field_simp
    nlinarith [N_pos (-gkD2 S rd rf σ T K1)]
  -- a strike with value above `-Δ`
  set K2 := fxForward S rd rf T * max 1 (2 * a / stdNormalCDF 0) with hK2
  have hK2pos : 0 < K2 := mul_pos hF (lt_of_lt_of_le one_pos (le_max_left _ _))
  have hv2 : -Δ < fxDrag spot rf T * (K2 / fxForward S rd rf T) *
      stdNormalCDF (-gkD2 S rd rf σ T K2) := by
    have e : K2 / fxForward S rd rf T = max 1 (2 * a / stdNormalCDF 0) := by rw [hK2]; field_simp
    rw [e]
    have hd : gkD2 S rd rf σ T K2 ≤ 0 := by
      have h := (gkD2_strictAntiOn S rd rf σ T hS hσ hT).antitoneOn (mem_Ioi.2 hF)
        (mem_Ioi.2 hK2pos) (by rw [hK2]; exact le_mul_of_one_le_right hF.le (le_max_left _ _))
      refine h.trans ?_
      rw [gkD2, gkD1_eq S rd rf σ T hS hT hF, sub_self, zero_add]
      have hs : 0 < σ * √T := mul_pos hσ (sqrt_pos.2 hT)
      rw [sub_nonpos, div_le_iff₀ hs]; nlinarith
    have hN : stdNormalCDF 0 ≤ stdNormalCDF (-gkD2 S rd rf σ T K2) :=
      N_strictMono.monotone (by linarith)
    have hm : 2 * a / stdNormalCDF 0 ≤ max 1 (2 * a / stdNormalCDF 0) := le_max_right _ _
    have hm2 : 2 * a ≤ max 1 (2 * a / stdNormalCDF 0) * stdNormalCDF 0 := by
      rwa [div_le_iff₀ hn0] at hm
    have hca : fxDrag spot rf T * a = -Δ := by rw [ha_def]; field_simp
    have hmpos : 0 ≤ max 1 (2 * a / stdNormalCDF 0) := le_trans zero_le_one (le_max_left _ _)
    have : max 1 (2 * a / stdNormalCDF 0) * stdNormalCDF 0 ≤
        max 1 (2 * a / stdNormalCDF 0) * stdNormalCDF (-gkD2 S rd rf σ T K2) :=
      mul_le_mul_of_nonneg_left hN hmpos
    nlinarith
  have hle : K1 ≤ K2 := by
    by_contra h
    exact absurd (hf (mem_Ioi.2 hK2pos) (mem_Ioi.2 hK1pos) (lt_of_not_ge h)) (by
      simp only; linarith)
  obtain ⟨K, hK, hKv⟩ := intermediate_value_Icc hle (hcont.mono (Icc_subset_Ioi_iff hle |>.2 hK1pos))
    ⟨hv1.le, hv2.le⟩
  have hKpos : 0 < K := lt_of_lt_of_le hK1pos hK.1
  simp only at hKv
  refine ⟨K, ⟨hKpos, ?_⟩, ?_⟩
  · simp only [paPutDelta]; rw [hKv]; ring
  · rintro K' ⟨hK', hK'v⟩
    refine hanti.injOn (mem_Ioi.2 hK') (mem_Ioi.2 hKpos) ?_
    rw [hK'v]; simp only [paPutDelta]; rw [hKv]; ring

/-- **The premium-adjusted call: one peak, two roots, take the higher** (Why it works, Steps 3 and
4). Under the same terms, the premium-adjusted call delta, spot or forward, has exactly one peak:
there is a positive strike `K_peak`, where `σ√T N(d₂) = φ(d₂)`, such that the delta rises strictly
on `(0, K_peak]` and falls strictly on `[K_peak, ∞)`. Every delta strictly between 0 and the peak
value is the delta of exactly two positive strikes, and of exactly one strike above the peak (the
desk's choice); the peak value is the delta of `K_peak` alone; a delta above the peak value has no
strike. -/
theorem premium_adjusted_call_one_peak_two_roots
    (spot : Bool) (S rd rf σ T : ℝ) (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T) :
    ∃ Kpeak : ℝ, 0 < Kpeak ∧
      σ * √T * stdNormalCDF (gkD2 S rd rf σ T Kpeak) = stdNormalPDF (gkD2 S rd rf σ T Kpeak) ∧
      StrictMonoOn (paCallDelta spot S rd rf σ T) (Ioc 0 Kpeak) ∧
      StrictAntiOn (paCallDelta spot S rd rf σ T) (Ici Kpeak) ∧
      (∀ Δ : ℝ, 0 < Δ → Δ < paCallDelta spot S rd rf σ T Kpeak →
        {K : ℝ | 0 < K ∧ paCallDelta spot S rd rf σ T K = Δ}.ncard = 2 ∧
        ∃! K : ℝ, Kpeak < K ∧ paCallDelta spot S rd rf σ T K = Δ) ∧
      {K : ℝ | 0 < K ∧ paCallDelta spot S rd rf σ T K = paCallDelta spot S rd rf σ T Kpeak} =
        {Kpeak} ∧
      (∀ Δ : ℝ, paCallDelta spot S rd rf σ T Kpeak < Δ →
        ¬ ∃ K : ℝ, 0 < K ∧ paCallDelta spot S rd rf σ T K = Δ) := by
  have hc := fxDrag_pos spot rf T
  have hs : 0 < σ * √T := mul_pos hσ (sqrt_pos.2 hT)
  have hF := fxForward_pos rd rf T hS
  have hd2anti := gkD2_strictAntiOn S rd rf σ T hS hσ hT
  obtain ⟨xs, -, hk0, hkpos, hkneg⟩ := kfun_root hs
  set g : ℝ → ℝ := fun x => exp (-(σ * √T) * x - (σ * √T) ^ 2 / 2) * stdNormalCDF x with hg
  have hgd : ∀ x, HasDerivAt g (exp (-(σ * √T) * x - (σ * √T) ^ 2 / 2) *
      (stdNormalPDF x - σ * √T * stdNormalCDF x)) x := gfun_hasDeriv _
  have hgc : Continuous g := gfun_cont _
  have hgmono : StrictMonoOn g (Iic xs) := by
    refine strictMonoOn_of_hasDerivWithinAt_pos (convex_Iic _) hgc.continuousOn
      (fun x _ => (hgd x).hasDerivWithinAt) fun x hx => ?_
    rw [interior_Iic, mem_Iio] at hx
    exact mul_pos (exp_pos _) (hkpos x hx)
  have hganti : StrictAntiOn g (Ici xs) := by
    refine strictAntiOn_of_hasDerivWithinAt_neg (convex_Ici _) hgc.continuousOn
      (fun x _ => (hgd x).hasDerivWithinAt) fun x hx => ?_
    rw [interior_Ici, mem_Ioi] at hx
    exact mul_neg_of_pos_of_neg (exp_pos _) (hkneg x hx)
  set Kof : ℝ → ℝ := fun x => fxForward S rd rf T * exp (-(σ * √T) * x - (σ * √T) ^ 2 / 2)
    with hKof
  have hKof_pos : ∀ x, 0 < Kof x := fun x => mul_pos hF (exp_pos _)
  have hd2Kof : ∀ x, gkD2 S rd rf σ T (Kof x) = x := fun x => gkD2_of_exp S rd rf σ T x hS hσ hT
  have hKofd2 : ∀ K, 0 < K → Kof (gkD2 S rd rf σ T K) = K := by
    intro K hK
    simp only [hKof]
    rw [← strike_div_forward S rd rf σ T hS hσ hT hK]
    field_simp
  have hKof_anti : StrictAnti Kof := by
    intro x y hxy
    simp only [hKof]
    apply mul_lt_mul_of_pos_left _ hF
    apply exp_lt_exp.2
    nlinarith
  have hpa : ∀ K, 0 < K → paCallDelta spot S rd rf σ T K =
      fxDrag spot rf T * g (gkD2 S rd rf σ T K) := by
    intro K hK
    rw [paCallDelta, strike_div_forward S rd rf σ T hS hσ hT hK, hg, mul_assoc]
  set Kpeak := Kof xs with hKpeak
  have hKp : 0 < Kpeak := hKof_pos xs
  have hpeak : paCallDelta spot S rd rf σ T Kpeak = fxDrag spot rf T * g xs := by
    rw [hpa _ hKp, hd2Kof]
  -- every value of the delta in terms of `g`
  have hval : ∀ K, 0 < K → ∀ Δ, paCallDelta spot S rd rf σ T K = Δ ↔
      g (gkD2 S rd rf σ T K) = Δ / fxDrag spot rf T := by
    intro K hK Δ
    rw [hpa K hK, eq_div_iff hc.ne', mul_comm]
  refine ⟨Kpeak, hKp, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · rw [hd2Kof]; linarith
  · intro a ha b hb hab
    have h1 := hd2anti (mem_Ioi.2 ha.1) (mem_Ioi.2 hb.1) hab
    have h2 : xs ≤ gkD2 S rd rf σ T b := by
      rw [← hd2Kof xs]
      exact hd2anti.antitoneOn (mem_Ioi.2 hb.1) (mem_Ioi.2 hKp) hb.2
    rw [hpa a ha.1, hpa b hb.1]
    exact mul_lt_mul_of_pos_left
      (hganti (mem_Ici.2 h2) (mem_Ici.2 (h2.trans h1.le)) h1) hc
  · intro a ha b hb hab
    have ha' : 0 < a := lt_of_lt_of_le hKp ha
    have hb' : 0 < b := lt_of_lt_of_le hKp hb
    have h1 := hd2anti (mem_Ioi.2 ha') (mem_Ioi.2 hb') hab
    have h2 : gkD2 S rd rf σ T a ≤ xs := by
      rw [← hd2Kof xs]
      exact hd2anti.antitoneOn (mem_Ioi.2 hKp) (mem_Ioi.2 ha') ha
    rw [hpa a ha', hpa b hb']
    exact mul_lt_mul_of_pos_left
      (hgmono (mem_Iic.2 (h1.le.trans h2)) (mem_Iic.2 h2) h1) hc
  · intro Δ hΔ hΔP
    rw [hpeak] at hΔP
    obtain ⟨a, b, ha, hb, hab⟩ := unimodal_count hgc hgmono hganti (gfun_tendsto_bot hs)
      (gfun_tendsto_top hs) (Δ / fxDrag spot rf T) (div_pos hΔ hc)
      ((div_lt_iff₀ hc).2 (by linarith))
    have hset : {K : ℝ | 0 < K ∧ paCallDelta spot S rd rf σ T K = Δ} = {Kof a, Kof b} := by
      ext K
      simp only [mem_ofPred_eq, mem_insert_iff, mem_singleton_iff]
      constructor
      · rintro ⟨hK, hv⟩
        rw [hval K hK, hab] at hv
        rcases hv with h | h
        · left; rw [← h, hKofd2 K hK]
        · right; rw [← h, hKofd2 K hK]
      · rintro (rfl | rfl)
        · exact ⟨hKof_pos a, by rw [hval _ (hKof_pos a), hd2Kof, hab]; left; rfl⟩
        · exact ⟨hKof_pos b, by rw [hval _ (hKof_pos b), hd2Kof, hab]; right; rfl⟩
    refine ⟨?_, ⟨Kof a, ⟨hKof_anti ha, ?_⟩, ?_⟩⟩
    · rw [hset]
      exact ncard_pair (hKof_anti (ha.trans hb)).ne'
    · rw [hval _ (hKof_pos a), hd2Kof, hab]; left; rfl
    · rintro K ⟨hK, hv⟩
      have hK0 : 0 < K := hKp.trans hK
      have hlt : gkD2 S rd rf σ T K < xs := by
        rw [← hd2Kof xs]; exact hd2anti (mem_Ioi.2 hKp) (mem_Ioi.2 hK0) hK
      rw [hval K hK0, hab] at hv
      rcases hv with h | h
      · rw [← h, hKofd2 K hK0]
      · exact absurd (h ▸ hlt) (not_lt.2 hb.le)
  · ext K
    simp only [mem_ofPred_eq, mem_singleton_iff]
    constructor
    · rintro ⟨hK, hv⟩
      rw [hpa K hK, hpeak] at hv
      have hv' := mul_left_cancel₀ hc.ne' hv
      by_contra hne
      have hne' : gkD2 S rd rf σ T K ≠ xs := by
        intro h; apply hne; rw [← hKofd2 K hK, h]
      exact absurd hv' (unimodal_lt hgmono hganti _ hne').ne
    · rintro rfl; exact ⟨hKp, rfl⟩
  · rintro Δ hΔ ⟨K, hK, hv⟩
    rw [hpeak] at hΔ
    rw [hpa K hK] at hv
    have : g (gkD2 S rd rf σ T K) ≤ g xs := by
      by_cases h : gkD2 S rd rf σ T K = xs
      · rw [h]
      · exact (unimodal_lt hgmono hganti _ h).le
    have := mul_le_mul_of_nonneg_left this hc.le
    linarith

#print axioms fx_strike_from_delta_one_line
#print axioms premium_adjusted_put_strike_unique
#print axioms premium_adjusted_call_one_peak_two_roots
