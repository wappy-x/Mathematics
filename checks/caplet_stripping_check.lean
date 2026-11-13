-- Caplet stripping: when each neighbouring cap price difference lies strictly between that caplet's zero-volatility floor and infinite-volatility ceiling, exactly one list of positive caplet volatilities reproduces every cap price under Black's formula, and when some difference lies outside that window no list does.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Real MeasureTheory ProbabilityTheory Set Filter Topology

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- Black's formula for one caplet (The formula): notional `L`, accrual `τ`, discount factor `D`
to the payment date, forward `F`, strike `K`, fixing date `T`, volatility `σ`:
`c(σ) = L τ D [F N(d₁) - K N(d₂)]`, `d₁ = (ln(F/K) + σ²T/2)/(σ√T)`, `d₂ = d₁ - σ√T`. -/
noncomputable def capletPrice (L τ D F K T σ : ℝ) : ℝ :=
  let d1 := (log (F / K) + σ ^ 2 * T / 2) / (σ * √T)
  L * τ * D * (F * stdNormalCDF d1 - K * stdNormalCDF (d1 - σ * √T))

/-- The caplet's floor, its value at zero volatility: `L τ D max(F - K, 0)`. -/
noncomputable def capletFloor (L τ D F K : ℝ) : ℝ := L * τ * D * max (F - K) 0

/-- The caplet's ceiling, its value as volatility grows without limit: `L τ D F`. -/
noncomputable def capletCeiling (L τ D F : ℝ) : ℝ := L * τ * D * F

/-- The price of cap `k` (caplets `0, …, k-1`, numbered from 0 here) from its flat quote `s`:
every caplet in the cap is priced at the same volatility, `C_k = ∑_{i<k} c_i(s)`.
Caplet `i` fixes at `T i`, has forward `F i`, and is discounted from its payment date by `D i`. -/
noncomputable def capPrice (L τ K : ℝ) (T F D : ℕ → ℝ) (k : ℕ) (s : ℝ) : ℝ :=
  ∑ i ∈ Finset.range k, capletPrice L τ (D i) (F i) K (T i) s

lemma stdNormalCDF_eq_integral (x : ℝ) :
    stdNormalCDF x = ∫ t in Iic x, gaussianPDFReal 0 1 t := by
  unfold stdNormalCDF
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral 0 one_ne_zero,
    ENNReal.toReal_ofReal]
  exact setIntegral_nonneg measurableSet_Iic (fun t _ => gaussianPDFReal_nonneg 0 1 t)

lemma continuous_stdPDF : Continuous (gaussianPDFReal 0 1) := by
  rw [gaussianPDFReal_def]; fun_prop

lemma hasDerivAt_stdNormalCDF (x : ℝ) :
    HasDerivAt stdNormalCDF (gaussianPDFReal 0 1 x) x := by
  have hint : ∀ y, IntegrableOn (gaussianPDFReal 0 1) (Iic y) :=
    fun y => (integrable_gaussianPDFReal 0 1).integrableOn
  have h : stdNormalCDF = fun y => stdNormalCDF 0 + ∫ t in (0:ℝ)..y, gaussianPDFReal 0 1 t := by
    funext y
    rw [stdNormalCDF_eq_integral, stdNormalCDF_eq_integral,
      ← intervalIntegral.integral_Iic_sub_Iic (hint 0) (hint y)]
    ring
  rw [h]
  exact ((continuous_stdPDF.integral_hasStrictDerivAt 0 x).hasDerivAt).const_add _

lemma stdNormalCDF_strictMono : StrictMono stdNormalCDF :=
  strictMono_of_hasDerivAt_pos hasDerivAt_stdNormalCDF
    (fun x => gaussianPDFReal_pos 0 1 x one_ne_zero)

lemma continuous_stdNormalCDF : Continuous stdNormalCDF :=
  continuous_iff_continuousAt.2 fun x => (hasDerivAt_stdNormalCDF x).continuousAt

lemma tendsto_stdNormalCDF_atTop : Tendsto stdNormalCDF atTop (𝓝 1) := tendsto_cdf_atTop _
lemma tendsto_stdNormalCDF_atBot : Tendsto stdNormalCDF atBot (𝓝 0) := tendsto_cdf_atBot _

/-- `K φ(d - s) = F φ(d)` when `d s - s²/2 = log (F/K)`. -/
lemma pdf_identity (F K s : ℝ) (hF : 0 < F) (hK : 0 < K) (hs : s ≠ 0) :
    F * gaussianPDFReal 0 1 (log (F / K) * s⁻¹ + s / 2) =
      K * gaussianPDFReal 0 1 (log (F / K) * s⁻¹ + s / 2 - s) := by
  simp only [gaussianPDFReal_def, NNReal.coe_one, mul_one, sub_zero]
  have key : -(log (F / K) * s⁻¹ + s / 2 - s) ^ 2 / 2 =
      -(log (F / K) * s⁻¹ + s / 2) ^ 2 / 2 + log (F / K) := by
    field_simp
    ring
  rw [key, exp_add, exp_log (div_pos hF hK)]
  field_simp

lemma core_hasDerivAt (F K a σ : ℝ) (hF : 0 < F) (hK : 0 < K) (ha : 0 < a) (hσ : σ ≠ 0) :
    HasDerivAt (fun σ => F * stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2)
        - K * stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a))
      (K * gaussianPDFReal 0 1 (log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a) * a) σ := by
  have hs : σ * a ≠ 0 := mul_ne_zero hσ ha.ne'
  have hlin : HasDerivAt (fun σ => σ * a) a σ := by simpa using (hasDerivAt_id σ).mul_const a
  obtain ⟨d, he⟩ : ∃ d, HasDerivAt (fun σ => log (F / K) * (σ * a)⁻¹ + σ * a / 2) d σ :=
    ⟨_, ((hlin.inv hs).const_mul _).add (hlin.div_const 2)⟩
  have h1 : HasDerivAt (fun σ => stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2))
      (gaussianPDFReal 0 1 (log (F / K) * (σ * a)⁻¹ + σ * a / 2) * d) σ :=
    (hasDerivAt_stdNormalCDF _).comp σ he
  have h2 : HasDerivAt (fun σ => stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a))
      (gaussianPDFReal 0 1 (log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a) * (d - a)) σ :=
    (hasDerivAt_stdNormalCDF _).comp σ (he.sub hlin)
  have hid := pdf_identity F K (σ * a) hF hK hs
  convert (h1.const_mul F).sub (h2.const_mul K) using 1
  linear_combination (-d) * hid

lemma core_strictMonoOn (F K a : ℝ) (hF : 0 < F) (hK : 0 < K) (ha : 0 < a) :
    StrictMonoOn (fun σ => F * stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2)
        - K * stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a)) (Ioi 0) ∧
    ContinuousOn (fun σ => F * stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2)
        - K * stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a)) (Ioi 0) := by
  have hc : ContinuousOn (fun σ => F * stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2)
        - K * stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a)) (Ioi 0) :=
    fun σ hσ => (core_hasDerivAt F K a σ hF hK ha (ne_of_gt hσ)).continuousAt.continuousWithinAt
  refine ⟨strictMonoOn_of_deriv_pos (convex_Ioi 0) hc ?_, hc⟩
  intro σ hσ
  rw [interior_Ioi] at hσ
  rw [(core_hasDerivAt F K a σ hF hK ha (ne_of_gt hσ)).deriv]
  exact mul_pos (mul_pos hK (gaussianPDFReal_pos 0 1 _ one_ne_zero)) ha

lemma core_tendsto_atTop (F K a : ℝ) (ha : 0 < a) :
    Tendsto (fun σ => F * stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2)
        - K * stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a)) atTop (𝓝 F) := by
  have hs : Tendsto (fun σ : ℝ => σ * a) atTop atTop := tendsto_id.atTop_mul_const ha
  have hu : Tendsto (fun σ : ℝ => log (F / K) * (σ * a)⁻¹) atTop (𝓝 0) := by
    simpa using (tendsto_inv_atTop_zero.comp hs).const_mul (log (F / K))
  have hv : Tendsto (fun σ : ℝ => σ * a / 2) atTop atTop := hs.atTop_div_const two_pos
  have h1 : Tendsto (fun σ : ℝ => log (F / K) * (σ * a)⁻¹ + σ * a / 2) atTop atTop :=
    hu.add_atTop hv
  have h2 : Tendsto (fun σ : ℝ => log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a) atTop atBot := by
    have := hu.add_atBot (tendsto_neg_atTop_atBot.comp hv)
    refine this.congr (fun σ => ?_)
    simp only [Function.comp]; ring
  have := ((tendsto_stdNormalCDF_atTop.comp h1).const_mul F).sub
    ((tendsto_stdNormalCDF_atBot.comp h2).const_mul K)
  simpa using this

lemma core_tendsto_zero (F K a : ℝ) (hF : 0 < F) (hK : 0 < K) (ha : 0 < a) :
    Tendsto (fun σ => F * stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2)
        - K * stdNormalCDF (log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a)) (𝓝[>] 0)
        (𝓝 (max (F - K) 0)) := by
  have hv : Tendsto (fun σ : ℝ => σ * a / 2) (𝓝[>] 0) (𝓝 0) := by
    have := ((continuous_id.mul continuous_const).div_const 2 :
      Continuous (fun σ : ℝ => σ * a / 2)).tendsto 0
    simpa using this.mono_left nhdsWithin_le_nhds
  have hw : Tendsto (fun σ : ℝ => -(σ * a / 2)) (𝓝[>] 0) (𝓝 0) := by
    simpa using hv.neg
  have hinv : Tendsto (fun σ : ℝ => σ⁻¹) (𝓝[>] 0) atTop := tendsto_inv_nhdsGT_zero
  have hu_eq : ∀ σ : ℝ, log (F / K) * (σ * a)⁻¹ = (log (F / K) * a⁻¹) * σ⁻¹ := by
    intro σ; rw [mul_inv]; ring
  have e1 : ∀ σ : ℝ, log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a =
      log (F / K) * (σ * a)⁻¹ + -(σ * a / 2) := by intro σ; ring
  rcases lt_trichotomy (log (F / K)) 0 with hm | hm | hm
  · -- F < K: both arguments go to -∞, price to 0
    have hFK : F < K := by
      have := (log_neg_iff (div_pos hF hK)).1 hm
      rwa [div_lt_one hK] at this
    have hu : Tendsto (fun σ : ℝ => log (F / K) * (σ * a)⁻¹) (𝓝[>] 0) atBot := by
      simp only [hu_eq]
      exact hinv.const_mul_atTop_of_neg (mul_neg_of_neg_of_pos hm (inv_pos.2 ha))
    have h1 := hu.atBot_add hv
    have h2 : Tendsto (fun σ : ℝ => log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a) (𝓝[>] 0)
        atBot := by simp only [e1]; exact hu.atBot_add hw
    have := ((tendsto_stdNormalCDF_atBot.comp h1).const_mul F).sub
      ((tendsto_stdNormalCDF_atBot.comp h2).const_mul K)
    rw [max_eq_right (by linarith)]
    simpa using this
  · -- F = K
    have hFK : F = K := by
      rcases log_eq_zero.1 hm with h | h | h
      · exact absurd h (div_pos hF hK).ne'
      · exact (div_eq_one_iff_eq hK.ne').1 h
      · linarith [div_pos hF hK]
    have h1 : Tendsto (fun σ : ℝ => log (F / K) * (σ * a)⁻¹ + σ * a / 2) (𝓝[>] 0) (𝓝 0) := by
      simpa [hm] using hv
    have h2 : Tendsto (fun σ : ℝ => log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a) (𝓝[>] 0)
        (𝓝 0) := by simp only [e1]; simpa [hm] using hw
    have := (((continuous_stdNormalCDF.tendsto 0).comp h1).const_mul F).sub
      (((continuous_stdNormalCDF.tendsto 0).comp h2).const_mul K)
    rw [hFK] at this ⊢
    simpa using this
  · -- F > K
    have hFK : K < F := by
      have := (log_pos_iff (div_pos hF hK).le).1 hm
      rwa [one_lt_div hK] at this
    have hu : Tendsto (fun σ : ℝ => log (F / K) * (σ * a)⁻¹) (𝓝[>] 0) atTop := by
      simp only [hu_eq]
      exact hinv.const_mul_atTop (mul_pos hm (inv_pos.2 ha))
    have h1 := hu.atTop_add hv
    have h2 : Tendsto (fun σ : ℝ => log (F / K) * (σ * a)⁻¹ + σ * a / 2 - σ * a) (𝓝[>] 0)
        atTop := by simp only [e1]; exact hu.atTop_add hw
    have := ((tendsto_stdNormalCDF_atTop.comp h1).const_mul F).sub
      ((tendsto_stdNormalCDF_atTop.comp h2).const_mul K)
    rw [max_eq_left (by linarith)]
    simpa using this

lemma window_of_strictMonoOn (f : ℝ → ℝ) (lo hi : ℝ) (hmono : StrictMonoOn f (Ioi 0))
    (hcont : ContinuousOn f (Ioi 0)) (h0 : Tendsto f (𝓝[>] 0) (𝓝 lo))
    (hinf : Tendsto f atTop (𝓝 hi)) :
    (∀ σ, 0 < σ → lo < f σ ∧ f σ < hi) ∧ ∀ c, lo < c → c < hi → ∃! σ, 0 < σ ∧ f σ = c := by
  refine ⟨fun σ hσ => ⟨?_, ?_⟩, fun c hlo hhi => ?_⟩
  · have hσ2 : 0 < σ / 2 := by positivity
    have hle : lo ≤ f (σ / 2) := by
      refine le_of_tendsto h0 ?_
      filter_upwards [Ioo_mem_nhdsGT hσ2] with x hx
      exact (hmono.lt_iff_lt hx.1 hσ2).2 hx.2 |>.le
    exact hle.trans_lt (hmono hσ2 hσ (by linarith))
  · have h2 : 0 < 2 * σ := by positivity
    have hle : f (2 * σ) ≤ hi := by
      refine ge_of_tendsto hinf ?_
      filter_upwards [eventually_ge_atTop (2 * σ)] with x hx
      exact hmono.monotoneOn h2 (lt_of_lt_of_le h2 hx) hx
    exact (hmono hσ h2 (by linarith)).trans_le hle
  · obtain ⟨x1, hx1c, hx1⟩ :=
      ((h0.eventually_lt_const hlo).and self_mem_nhdsWithin).exists
    obtain ⟨x2, hx2c, hx2⟩ :=
      ((hinf.eventually_const_lt hhi).and (eventually_gt_atTop 0)).exists
    have hx12 : x1 ≤ x2 := by
      by_contra h
      have := hmono hx2 hx1 (not_le.1 h)
      linarith
    obtain ⟨σ, hσI, hσc⟩ : c ∈ f '' Icc x1 x2 :=
      intermediate_value_Icc hx12 (hcont.mono fun y hy => lt_of_lt_of_le hx1 hy.1)
        ⟨hx1c.le, hx2c.le⟩
    have hσ : 0 < σ := lt_of_lt_of_le hx1 hσI.1
    refine ⟨σ, ⟨hσ, hσc⟩, fun y hy => ?_⟩
    exact hmono.injOn hy.1 hσ (hy.2.trans hσc.symm)

lemma d1_eq (m σ a : ℝ) : (m + σ ^ 2 * a ^ 2 / 2) / (σ * a) = m * (σ * a)⁻¹ + σ * a / 2 := by
  by_cases h : σ * a = 0
  · rcases mul_eq_zero.1 h with h | h <;> simp [h]
  · field_simp

lemma capletPrice_eq (L τ D F K T σ : ℝ) (hT : 0 ≤ T) :
    capletPrice L τ D F K T σ = L * τ * D *
      (F * stdNormalCDF (log (F / K) * (σ * √T)⁻¹ + σ * √T / 2)
        - K * stdNormalCDF (log (F / K) * (σ * √T)⁻¹ + σ * √T / 2 - σ * √T)) := by
  unfold capletPrice
  have h := sq_sqrt hT
  simp only
  rw [← d1_eq, h]

lemma caplet_price_window_aux (L τ D F K T : ℝ)
    (hL : 0 < L) (hτ : 0 < τ) (hD : 0 < D) (hF : 0 < F) (hK : 0 < K) (hT : 0 < T) :
    (∀ σ : ℝ, 0 < σ →
        capletFloor L τ D F K < capletPrice L τ D F K T σ ∧
          capletPrice L τ D F K T σ < capletCeiling L τ D F) ∧
      StrictMonoOn (fun σ ↦ capletPrice L τ D F K T σ) (Ioi 0) ∧
      Tendsto (fun σ ↦ capletPrice L τ D F K T σ) (𝓝[>] 0) (𝓝 (capletFloor L τ D F K)) ∧
      Tendsto (fun σ ↦ capletPrice L τ D F K T σ) atTop (𝓝 (capletCeiling L τ D F)) ∧
      ∀ c : ℝ, capletFloor L τ D F K < c → c < capletCeiling L τ D F →
        ∃! σ : ℝ, 0 < σ ∧ capletPrice L τ D F K T σ = c := by
  have ha : 0 < √T := sqrt_pos.2 hT
  have hc : 0 < L * τ * D := by positivity
  have hfun : (fun σ ↦ capletPrice L τ D F K T σ) = fun σ => L * τ * D *
      (F * stdNormalCDF (log (F / K) * (σ * √T)⁻¹ + σ * √T / 2)
        - K * stdNormalCDF (log (F / K) * (σ * √T)⁻¹ + σ * √T / 2 - σ * √T)) := by
    funext σ; exact capletPrice_eq L τ D F K T σ hT.le
  obtain ⟨hmono, hcont⟩ := core_strictMonoOn F K (√T) hF hK ha
  have hmono' : StrictMonoOn (fun σ ↦ capletPrice L τ D F K T σ) (Ioi 0) := by
    rw [hfun]
    intro x hx y hy hxy
    exact mul_lt_mul_of_pos_left (hmono hx hy hxy) hc
  have hcont' : ContinuousOn (fun σ ↦ capletPrice L τ D F K T σ) (Ioi 0) := by
    rw [hfun]; exact hcont.const_smul (L * τ * D)
  have h0 : Tendsto (fun σ ↦ capletPrice L τ D F K T σ) (𝓝[>] 0)
      (𝓝 (capletFloor L τ D F K)) := by
    rw [hfun]; exact (core_tendsto_zero F K (√T) hF hK ha).const_mul (L * τ * D)
  have hinf : Tendsto (fun σ ↦ capletPrice L τ D F K T σ) atTop
      (𝓝 (capletCeiling L τ D F)) := by
    rw [hfun]; exact (core_tendsto_atTop F K (√T) ha).const_mul (L * τ * D)
  obtain ⟨hb, hu⟩ := window_of_strictMonoOn _ _ _ hmono' hcont' h0 hinf
  exact ⟨hb, hmono', h0, hinf, hu⟩

lemma sum_Iic_fin_eq (n : ℕ) (g : Fin n → ℝ) (k : Fin n) :
    ∑ i ∈ Finset.Iic k, g i =
      ∑ j ∈ Finset.range ((k : ℕ) + 1), (if h : j < n then g ⟨j, h⟩ else 0) := by
  rw [Nat.range_succ_eq_Iic, ← Fin.map_valEmbedding_Iic, Finset.sum_map]
  simp

lemma sum_Iic_fin_iff (n : ℕ) (g : Fin n → ℝ) (C : ℕ → ℝ) (hC : C 0 = 0) :
    (∀ k : Fin n, ∑ i ∈ Finset.Iic k, g i = C (k + 1)) ↔
      ∀ k : Fin n, g k = C (k + 1) - C k := by
  set g' : ℕ → ℝ := fun j => if h : j < n then g ⟨j, h⟩ else 0 with hg'
  have hgk : ∀ k : Fin n, g k = g' k := fun k => by simp [hg']
  simp only [sum_Iic_fin_eq]
  constructor
  · intro h k
    have h1 := h k
    rw [Finset.sum_range_succ] at h1
    have h0 : ∑ j ∈ Finset.range (k : ℕ), g' j = C k := by
      rcases Nat.eq_zero_or_eq_succ_pred (k : ℕ) with hk | hk
      · rw [hk, Finset.sum_range_zero, hC]
      · have := h ⟨(k : ℕ) - 1, by omega⟩
        simp only at this
        rw [show (k : ℕ) - 1 + 1 = k by omega] at this
        exact this
    rw [hgk]
    linarith
  · intro h
    have key : ∀ m, m < n → ∑ j ∈ Finset.range (m + 1), g' j = C (m + 1) := by
      intro m
      induction m with
      | zero =>
        intro hm
        have := h ⟨0, hm⟩
        rw [hgk] at this
        simp only at this
        simp [this, hC]
      | succ m ih =>
        intro hm
        have := h ⟨m + 1, hm⟩
        rw [hgk] at this
        simp only at this
        rw [Finset.sum_range_succ, ih (by omega), this]
        ring
    exact fun k => key k k.2

/-- **Caplet stripping has exactly one answer** (Why it works, Steps 2 to 4, and the detailed
proof). Take `n` caplets with one notional `L > 0`, one accrual `τ > 0` and one strike `K > 0`
across the strip; caplet `i` fixes at `T i > 0`, has a positive forward `F i` and a positive
discount factor `D i` to its payment date. Quote one flat volatility `flat k` for each cap
`k = 1, …, n`, turn each quote into the cap price `C_k = ∑_{i<k} c_i(flat k)` (with `C_0 = 0`).
If every neighbouring difference `C_{k+1} - C_k` lies strictly between caplet `k`'s floor and
ceiling, then exactly one list of positive caplet volatilities `σ` reproduces every cap price:
`∑_{i ≤ k} c_i(σ_i) = C_{k+1}` for every `k`. -/
theorem caplet_volatilities_exist_and_are_unique (n : ℕ) (L τ K : ℝ) (T F D flat : ℕ → ℝ)
    (hL : 0 < L) (hτ : 0 < τ) (hK : 0 < K)
    (hT : ∀ i < n, 0 < T i) (hF : ∀ i < n, 0 < F i) (hD : ∀ i < n, 0 < D i)
    (hwindow : ∀ k < n,
      capletFloor L τ (D k) (F k) K <
          capPrice L τ K T F D (k + 1) (flat (k + 1)) - capPrice L τ K T F D k (flat k) ∧
        capPrice L τ K T F D (k + 1) (flat (k + 1)) - capPrice L τ K T F D k (flat k) <
          capletCeiling L τ (D k) (F k)) :
    ∃! σ : Fin n → ℝ, (∀ i, 0 < σ i) ∧
      ∀ k : Fin n, ∑ i ∈ Finset.Iic k, capletPrice L τ (D i) (F i) K (T i) (σ i) =
        capPrice L τ K T F D (k + 1) (flat (k + 1)) := by
  have hC : capPrice L τ K T F D 0 (flat 0) = 0 := by simp [capPrice]
  have hex : ∀ k : Fin n, ∃! s : ℝ, 0 < s ∧ capletPrice L τ (D k) (F k) K (T k) s =
      capPrice L τ K T F D (k + 1) (flat (k + 1)) - capPrice L τ K T F D k (flat k) :=
    fun k => (caplet_price_window_aux L τ (D k) (F k) K (T k) hL hτ (hD k k.2) (hF k k.2) hK
      (hT k k.2)).2.2.2.2 _ (hwindow k k.2).1 (hwindow k k.2).2
  choose σ hσ hσu using hex
  refine ⟨σ, ⟨fun i => (hσ i).1, ?_⟩, ?_⟩
  · exact (sum_Iic_fin_iff n (fun i => capletPrice L τ (D i) (F i) K (T i) (σ i))
      (fun j => capPrice L τ K T F D j (flat j)) hC).2 (fun k => (hσ k).2)
  · rintro σ' ⟨hpos', hsum'⟩
    have h := (sum_Iic_fin_iff n (fun i => capletPrice L τ (D i) (F i) K (T i) (σ' i))
      (fun j => capPrice L τ K T F D j (flat j)) hC).1 hsum'
    funext k
    exact hσu k (σ' k) ⟨hpos' k, h k⟩

/-- **One caplet's price curve** (Why it works, Step 3, and the detailed proof). For a notional
`L > 0`, accrual `τ > 0`, discount factor `D > 0`, forward `F > 0`, strike `K > 0` and fixing
date `T > 0`, the caplet price at every positive volatility lies strictly between the floor
`L τ D max(F - K, 0)` and the ceiling `L τ D F`; it rises strictly with volatility; it tends to
the floor as volatility shrinks to zero and to the ceiling as volatility grows without limit;
so every price strictly inside the window comes from exactly one positive volatility. -/
theorem caplet_price_rises_strictly_from_floor_to_ceiling (L τ D F K T : ℝ)
    (hL : 0 < L) (hτ : 0 < τ) (hD : 0 < D) (hF : 0 < F) (hK : 0 < K) (hT : 0 < T) :
    (∀ σ : ℝ, 0 < σ →
        capletFloor L τ D F K < capletPrice L τ D F K T σ ∧
          capletPrice L τ D F K T σ < capletCeiling L τ D F) ∧
      StrictMonoOn (fun σ ↦ capletPrice L τ D F K T σ) (Ioi 0) ∧
      Tendsto (fun σ ↦ capletPrice L τ D F K T σ) (𝓝[>] 0) (𝓝 (capletFloor L τ D F K)) ∧
      Tendsto (fun σ ↦ capletPrice L τ D F K T σ) atTop (𝓝 (capletCeiling L τ D F)) ∧
      ∀ c : ℝ, capletFloor L τ D F K < c → c < capletCeiling L τ D F →
        ∃! σ : ℝ, 0 < σ ∧ capletPrice L τ D F K T σ = c := by
  exact caplet_price_window_aux L τ D F K T hL hτ hD hF hK hT

/-- **Quotes that allow no answer** (When it holds, Existence; the detailed proof, "Existence
fails at the edges"). With the same setup, if for some caplet `k` the cap price difference
`C_{k+1} - C_k` is at or below that caplet's floor, or at or above its ceiling, then no list of
positive caplet volatilities reproduces every cap price. -/
theorem no_caplet_volatilities_outside_the_window (n : ℕ) (L τ K : ℝ) (T F D flat : ℕ → ℝ)
    (hL : 0 < L) (hτ : 0 < τ) (hK : 0 < K)
    (hT : ∀ i < n, 0 < T i) (hF : ∀ i < n, 0 < F i) (hD : ∀ i < n, 0 < D i)
    (k : ℕ) (hk : k < n)
    (hout : capPrice L τ K T F D (k + 1) (flat (k + 1)) - capPrice L τ K T F D k (flat k) ≤
          capletFloor L τ (D k) (F k) K ∨
        capletCeiling L τ (D k) (F k) ≤
          capPrice L τ K T F D (k + 1) (flat (k + 1)) - capPrice L τ K T F D k (flat k)) :
    ¬ ∃ σ : Fin n → ℝ, (∀ i, 0 < σ i) ∧
      ∀ j : Fin n, ∑ i ∈ Finset.Iic j, capletPrice L τ (D i) (F i) K (T i) (σ i) =
        capPrice L τ K T F D (j + 1) (flat (j + 1)) := by
  rintro ⟨σ, hpos, hsum⟩
  have hC : capPrice L τ K T F D 0 (flat 0) = 0 := by simp [capPrice]
  have h := (sum_Iic_fin_iff n (fun i => capletPrice L τ (D i) (F i) K (T i) (σ i))
      (fun j => capPrice L τ K T F D j (flat j)) hC).1 hsum ⟨k, hk⟩
  have hb := (caplet_price_window_aux L τ (D k) (F k) K (T k) hL hτ (hD k hk) (hF k hk) hK
      (hT k hk)).1 (σ ⟨k, hk⟩) (hpos _)
  simp only at h
  rw [h] at hb
  rcases hout with hout | hout
  · linarith [hb.1]
  · linarith [hb.2]

-- Step 2 in cents: cap 8 minus cap 7 is caplet 8's price, 14,908.96 - 11,481.00 = 3,427.96.
example : (1490896 : ℤ) - 1148100 = 342796 := by norm_num
-- Worked numbers: caplet 8's price sits inside its window, 2,611.19 < 3,427.96 < 13,749.78.
example : (261119 : ℕ) < 342796 ∧ (342796 : ℕ) < 1374978 := by decide
-- The wrong road, in tenths of a percent: 8 × 29.4 - 7 × 30.0 = 25.2.
example : (8 : ℤ) * 294 - 7 * 300 = 252 := by norm_num
-- The 2-year cap is cap 7: its last caplet fixes at 7 quarters = 1.75 years and pays at 2 years.
example : (7 : ℚ) * (1 / 4) = 7 / 4 ∧ (7 : ℚ) / 4 + 1 / 4 = 2 := by norm_num

#print axioms caplet_volatilities_exist_and_are_unique
#print axioms caplet_price_rises_strictly_from_floor_to_ceiling
#print axioms no_caplet_volatilities_outside_the_window
#print axioms stdNormalCDF_eq_integral
#print axioms continuous_stdPDF
#print axioms hasDerivAt_stdNormalCDF
#print axioms stdNormalCDF_strictMono
#print axioms continuous_stdNormalCDF
#print axioms tendsto_stdNormalCDF_atTop
#print axioms tendsto_stdNormalCDF_atBot
#print axioms pdf_identity
#print axioms core_hasDerivAt
#print axioms core_strictMonoOn
#print axioms core_tendsto_atTop
#print axioms core_tendsto_zero
#print axioms window_of_strictMonoOn
#print axioms d1_eq
#print axioms capletPrice_eq
#print axioms caplet_price_window_aux
#print axioms sum_Iic_fin_eq
#print axioms sum_Iic_fin_iff
