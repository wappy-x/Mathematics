-- Solving rate options backwards: a swaption quote has exactly one Black volatility, one normal volatility, or one strike precisely when it lies inside the card's fence.
import Mathlib.Probability.CDF
import Mathlib.Probability.Distributions.Gaussian.Real

open Real ProbabilityTheory

namespace RateOptionInverses

/-- The standard normal distribution function `N`: the bell-curve area left of `x`. -/
noncomputable def N (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- The standard normal density `φ`: the bell-curve height at `x`. -/
noncomputable def φ (x : ℝ) : ℝ := gaussianPDFReal 0 1 x

/-- Black's payer swaption premium per unit notional, with annuity `A`, forward swap rate `F`,
strike `K`, expiry `T` and lognormal volatility `σ`:
`A [F N(d₁) - K N(d₂)]`, `d₁ = ln(F/K)/(σ√T) + σ√T/2`, `d₂ = d₁ - σ√T`. -/
noncomputable def black (A F K T σ : ℝ) : ℝ :=
  A * (F * N (log (F / K) / (σ * √T) + σ * √T / 2)
    - K * N (log (F / K) / (σ * √T) - σ * √T / 2))

/-- Bachelier's (normal) payer swaption premium per unit notional, with normal volatility `σN`:
`A [(F - K) N(d) + σN √T φ(d)]`, `d = (F - K)/(σN √T)`. -/
noncomputable def bachelier (A F K T σN : ℝ) : ℝ :=
  A * ((F - K) * N ((F - K) / (σN * √T)) + σN * √T * φ ((F - K) / (σN * √T)))

section Helpers

open MeasureTheory Filter Topology Set

lemma φ_eq (x : ℝ) : φ x = (√(2 * π))⁻¹ * rexp (-x ^ 2 / 2) := by
  simp [φ, gaussianPDFReal]

#print axioms φ_eq

lemma φ_pos (x : ℝ) : 0 < φ x := gaussianPDFReal_pos _ _ _ one_ne_zero

#print axioms φ_pos

lemma φ_cont : Continuous φ := by
  have : φ = fun x => (√(2 * π))⁻¹ * rexp (-x ^ 2 / 2) := funext φ_eq
  rw [this]; fun_prop

#print axioms φ_cont

lemma N_eq_integral (x : ℝ) : N x = ∫ t in Iic x, φ t := by
  unfold N φ
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal]
  exact setIntegral_nonneg measurableSet_Iic (fun t _ => gaussianPDFReal_nonneg _ _ _)

#print axioms N_eq_integral

lemma φ_integrable : Integrable φ := integrable_gaussianPDFReal 0 1

#print axioms φ_integrable

lemma N_eq (x : ℝ) : N x = N 0 + ∫ t in (0:ℝ)..x, φ t := by
  rw [N_eq_integral, N_eq_integral, ← intervalIntegral.integral_Iic_sub_Iic
    φ_integrable.integrableOn φ_integrable.integrableOn]
  ring

#print axioms N_eq

lemma N_hasDerivAt (x : ℝ) : HasDerivAt N (φ x) x := by
  have h := (φ_cont.integral_hasStrictDerivAt 0 x).hasDerivAt.const_add (N 0)
  have : N = fun x => N 0 + ∫ t in (0:ℝ)..x, φ t := funext N_eq
  rw [this]; exact h

#print axioms N_hasDerivAt

lemma N_cont : Continuous N := continuous_iff_continuousAt.2 fun x => (N_hasDerivAt x).continuousAt

#print axioms N_cont

lemma N_strictMono : StrictMono N :=
  strictMono_of_deriv_pos fun x => by rw [(N_hasDerivAt x).deriv]; exact φ_pos x

#print axioms N_strictMono

lemma N_atBot : Tendsto N atBot (𝓝 0) := tendsto_cdf_atBot _

#print axioms N_atBot

lemma N_atTop : Tendsto N atTop (𝓝 1) := tendsto_cdf_atTop _

#print axioms N_atTop

lemma N_pos (x : ℝ) : 0 < N x := lt_of_le_of_lt (cdf_nonneg _ _) (N_strictMono (by linarith : x - 1 < x))

#print axioms N_pos

lemma N_lt_one (x : ℝ) : N x < 1 := lt_of_lt_of_le (N_strictMono (by linarith : x < x + 1)) (cdf_le_one _ _)

#print axioms N_lt_one

lemma φ_hasDerivAt (x : ℝ) : HasDerivAt φ (-x * φ x) x := by
  have : φ = fun x => (√(2 * π))⁻¹ * rexp (-x ^ 2 / 2) := funext φ_eq
  rw [this]
  have h := ((((hasDerivAt_pow 2 x).neg.div_const 2).exp).const_mul (√(2 * π))⁻¹)
  convert h using 1
  simp only [Pi.neg_apply]; push_cast; ring

#print axioms φ_hasDerivAt

lemma φ_le (x : ℝ) : φ x ≤ (√(2 * π))⁻¹ := by
  rw [φ_eq]
  have : rexp (-x ^ 2 / 2) ≤ 1 := by
    rw [Real.exp_le_one_iff]; nlinarith [sq_nonneg x]
  have : 0 < (√(2 * π))⁻¹ := by positivity
  nlinarith

#print axioms φ_le

lemma exists_unique_of_mono {f : ℝ → ℝ} {P : ℝ} (hc : ContinuousOn f (Ioi 0))
    (hm : StrictMonoOn f (Ioi 0)) (h1 : ∃ x, 0 < x ∧ f x < P) (h2 : ∃ y, 0 < y ∧ P < f y) :
    ∃! x, 0 < x ∧ f x = P := by
  obtain ⟨x, hx, hfx⟩ := h1
  obtain ⟨y, hy, hfy⟩ := h2
  have hxy : x ≤ y := by
    by_contra h
    rw [not_le] at h
    have := hm hy hx h
    linarith
  have hsub : Icc x y ⊆ Ioi 0 := fun t ht => lt_of_lt_of_le hx ht.1
  obtain ⟨z, hz, hfz⟩ := intermediate_value_Icc hxy (hc.mono hsub) ⟨hfx.le, hfy.le⟩
  refine ⟨z, ⟨hsub hz, hfz⟩, ?_⟩
  rintro w ⟨hw, hfw⟩
  exact hm.injOn hw (hsub hz) (hfw.trans hfz.symm)

#print axioms exists_unique_of_mono

lemma lower_of_tendsto {f : ℝ → ℝ} {a : ℝ} (hm : StrictMonoOn f (Ioi 0))
    (h0 : Tendsto f (𝓝[>] 0) (𝓝 a)) {x : ℝ} (hx : 0 < x) : a < f x := by
  have hx2 : (0:ℝ) < x / 2 := by linarith
  have h1 : a ≤ f (x / 2) := by
    apply le_of_tendsto h0
    filter_upwards [Ioo_mem_nhdsGT hx2] with t ht
    exact (hm ht.1 hx2 ht.2).le
  exact lt_of_le_of_lt h1 (hm hx2 hx (by linarith))

#print axioms lower_of_tendsto

lemma exists_below_of_tendsto {f : ℝ → ℝ} {a P : ℝ} (h0 : Tendsto f (𝓝[>] 0) (𝓝 a))
    (ha : a < P) : ∃ x, 0 < x ∧ f x < P := by
  obtain ⟨x, h1, h2⟩ := ((h0.eventually (gt_mem_nhds ha)).and
    (eventually_mem_nhdsWithin (s := Ioi (0:ℝ)) (a := 0))).exists
  exact ⟨x, h2, h1⟩

#print axioms exists_below_of_tendsto

lemma strictMonoOn_of_hasDerivAt {f f' : ℝ → ℝ} (hd : ∀ x, 0 < x → HasDerivAt f (f' x) x)
    (hp : ∀ x, 0 < x → 0 < f' x) : ContinuousOn f (Ioi 0) ∧ StrictMonoOn f (Ioi 0) := by
  have hc : ContinuousOn f (Ioi 0) := fun x hx => (hd x hx).continuousAt.continuousWithinAt
  refine ⟨hc, strictMonoOn_of_deriv_pos (convex_Ioi 0) hc fun x hx => ?_⟩
  rw [interior_Ioi] at hx
  rw [(hd x hx).deriv]
  exact hp x hx

#print axioms strictMonoOn_of_hasDerivAt

lemma key (F K w : ℝ) (hF : 0 < F) (hK : 0 < K) (hw : w ≠ 0) :
    F * φ (log (F / K) / w + w / 2) = K * φ (log (F / K) / w - w / 2) := by
  rw [φ_eq, φ_eq]
  have e : -(log (F / K) / w + w / 2) ^ 2 / 2 = -(log (F / K) / w - w / 2) ^ 2 / 2 + -log (F / K) := by
    field_simp; ring
  rw [e, exp_add, exp_neg, exp_log (div_pos hF hK)]
  field_simp

#print axioms key

lemma black_hasDerivAt_σ (A F K T σ : ℝ) (hF : 0 < F) (hK : 0 < K) (hT : 0 < T) (hσ : 0 < σ) :
    HasDerivAt (black A F K T)
      (A * F * φ (log (F / K) / (σ * √T) + σ * √T / 2) * √T) σ := by
  have hs : 0 < √T := sqrt_pos.2 hT
  have e1 : (fun x => log (F / K) / (x * √T) + x * √T / 2)
      = fun x => log (F / K) / √T * x⁻¹ + id x * (√T / 2) := by
    funext x; simp only [id]; ring
  have e2 : (fun x => log (F / K) / (x * √T) - x * √T / 2)
      = fun x => log (F / K) / √T * x⁻¹ - id x * (√T / 2) := by
    funext x; simp only [id]; ring
  have hd1 : HasDerivAt (fun x => log (F / K) / (x * √T) + x * √T / 2)
      (log (F / K) / √T * (-(σ ^ 2)⁻¹) + 1 * (√T / 2)) σ := by
    rw [e1]
    exact ((hasDerivAt_inv hσ.ne').const_mul _).add ((hasDerivAt_id σ).mul_const _)
  have hd2 : HasDerivAt (fun x => log (F / K) / (x * √T) - x * √T / 2)
      (log (F / K) / √T * (-(σ ^ 2)⁻¹) - 1 * (√T / 2)) σ := by
    rw [e2]
    exact ((hasDerivAt_inv hσ.ne').const_mul _).sub ((hasDerivAt_id σ).mul_const _)
  have h := ((((N_hasDerivAt _).comp σ hd1).const_mul F).sub
    (((N_hasDerivAt _).comp σ hd2).const_mul K)).const_mul A
  have hk := key F K (σ * √T) hF hK (by positivity)
  refine h.congr_deriv ?_
  linear_combination (A * (log (F / K) / √T * (-(σ ^ 2)⁻¹) - 1 * (√T / 2))) * hk

#print axioms black_hasDerivAt_σ

lemma bachelier_hasDerivAt (A F K T σ : ℝ) (hT : 0 < T) (hσ : 0 < σ) :
    HasDerivAt (bachelier A F K T) (A * (√T * φ ((F - K) / (σ * √T)))) σ := by
  have hs : 0 < √T := sqrt_pos.2 hT
  have e1 : (fun x => (F - K) / (x * √T)) = fun x => (F - K) / √T * x⁻¹ := by
    funext x; ring
  have hd : HasDerivAt (fun x => (F - K) / (x * √T)) ((F - K) / √T * (-(σ ^ 2)⁻¹)) σ := by
    rw [e1]; exact (hasDerivAt_inv hσ.ne').const_mul _
  have h := ((((N_hasDerivAt _).comp σ hd).const_mul (F - K)).add
    (((hasDerivAt_id σ).mul_const √T).mul ((φ_hasDerivAt _).comp σ hd))).const_mul A
  have hm : σ * √T * ((F - K) / (σ * √T)) = F - K := by field_simp
  refine h.congr_deriv ?_
  simp only [id, Function.comp_apply]
  linear_combination (-A * φ ((F - K) / (σ * √T)) * ((F - K) / √T * (-(σ ^ 2)⁻¹))) * hm

#print axioms bachelier_hasDerivAt

lemma black_hasDerivAt_K (A F K T σ : ℝ) (hF : 0 < F) (hK : 0 < K) (hT : 0 < T) (hσ : 0 < σ) :
    HasDerivAt (fun K => black A F K T σ)
      (-(A * N (log (F / K) / (σ * √T) - σ * √T / 2))) K := by
  have hw : 0 < σ * √T := mul_pos hσ (sqrt_pos.2 hT)
  have hq : HasDerivAt (fun x => F / x) ((0 * K - F * 1) / K ^ 2) K :=
    (hasDerivAt_const K F).div (hasDerivAt_id' K) hK.ne'
  have hL := hq.log (div_pos hF hK).ne'
  have hd1 := (hL.div_const (σ * √T)).add_const (σ * √T / 2)
  have hd2 := (hL.div_const (σ * √T)).sub_const (σ * √T / 2)
  have h := ((((N_hasDerivAt _).comp K hd1).const_mul F).sub
    ((hasDerivAt_id' K).mul ((N_hasDerivAt _).comp K hd2))).const_mul A
  have hk := key F K (σ * √T) hF hK hw.ne'
  refine h.congr_deriv ?_
  simp only [Function.comp_apply]
  linear_combination (A * ((0 * K - F * 1) / K ^ 2 / (F / K) / (σ * √T))) * hk

#print axioms black_hasDerivAt_K

lemma tendsto_mul_nhdsGT (s : ℝ) (hs : 0 < s) :
    Tendsto (fun σ : ℝ => σ * s) (𝓝[>] 0) (𝓝[>] 0) := by
  apply tendsto_nhdsWithin_iff.2
  refine ⟨?_, ?_⟩
  · have : Tendsto (fun σ : ℝ => σ * s) (𝓝 0) (𝓝 (0 * s)) :=
      (continuous_id.mul continuous_const).tendsto 0
    rw [zero_mul] at this
    exact this.mono_left nhdsWithin_le_nhds
  · filter_upwards [eventually_mem_nhdsWithin] with σ hσ
    exact mul_pos hσ hs

#print axioms tendsto_mul_nhdsGT

lemma tendsto_mul_half (s : ℝ) : Tendsto (fun σ : ℝ => σ * s / 2) (𝓝[>] 0) (𝓝 0) := by
  have : Tendsto (fun σ : ℝ => σ * s / 2) (𝓝 0) (𝓝 (0 * s / 2)) :=
    ((continuous_id.mul continuous_const).div_const 2).tendsto 0
  rw [zero_mul, zero_div] at this
  exact this.mono_left nhdsWithin_le_nhds

#print axioms tendsto_mul_half

lemma black_tendsto_zero (A F K T : ℝ) (hF : 0 < F) (hK : 0 < K) (hT : 0 < T) :
    Tendsto (black A F K T) (𝓝[>] 0) (𝓝 (A * max (F - K) 0)) := by
  have hs : 0 < √T := sqrt_pos.2 hT
  have hinv : Tendsto (fun σ : ℝ => (σ * √T)⁻¹) (𝓝[>] 0) atTop :=
    tendsto_inv_nhdsGT_zero.comp (tendsto_mul_nhdsGT _ hs)
  have hh := tendsto_mul_half √T
  rcases lt_trichotomy F K with hFK | hFK | hFK
  · have hL : log (F / K) < 0 := log_neg (div_pos hF hK) ((div_lt_one hK).2 hFK)
    have hq : Tendsto (fun σ : ℝ => log (F / K) / (σ * √T)) (𝓝[>] 0) atBot :=
      (hinv.const_mul_atTop_of_neg hL).congr fun σ => (div_eq_mul_inv _ _).symm
    have hd1 := hq.atBot_add hh
    have hd2 : Tendsto (fun σ : ℝ => log (F / K) / (σ * √T) - σ * √T / 2) (𝓝[>] 0) atBot :=
      (hq.atBot_add hh.neg).congr fun σ => (sub_eq_add_neg _ _).symm
    have h : Tendsto (black A F K T) (𝓝[>] 0) (𝓝 (A * (F * 0 - K * 0))) :=
      (((N_atBot.comp hd1).const_mul F).sub ((N_atBot.comp hd2).const_mul K)).const_mul A
    rw [max_eq_right (by linarith)]
    simpa using h
  · subst hFK
    have e : black A F F T = fun σ => A * (F * N (σ * √T / 2) - F * N (-(σ * √T / 2))) := by
      funext σ; simp [black, div_self hF.ne', sub_eq_add_neg]
    rw [e]
    have h1 := (N_cont.tendsto 0).comp hh
    have hh' := hh.neg
    rw [neg_zero] at hh'
    have h2 := (N_cont.tendsto 0).comp hh'
    have h : Tendsto (fun σ => A * (F * N (σ * √T / 2) - F * N (-(σ * √T / 2)))) (𝓝[>] 0)
        (𝓝 (A * (F * N 0 - F * N 0))) := ((h1.const_mul F).sub (h2.const_mul F)).const_mul A
    simpa using h
  · have hL : 0 < log (F / K) := log_pos ((one_lt_div hK).2 hFK)
    have hq : Tendsto (fun σ : ℝ => log (F / K) / (σ * √T)) (𝓝[>] 0) atTop :=
      (hinv.const_mul_atTop hL).congr fun σ => (div_eq_mul_inv _ _).symm
    have hd1 := hq.atTop_add hh
    have hd2 : Tendsto (fun σ : ℝ => log (F / K) / (σ * √T) - σ * √T / 2) (𝓝[>] 0) atTop :=
      (hq.atTop_add hh.neg).congr fun σ => (sub_eq_add_neg _ _).symm
    have h : Tendsto (black A F K T) (𝓝[>] 0) (𝓝 (A * (F * 1 - K * 1))) :=
      (((N_atTop.comp hd1).const_mul F).sub ((N_atTop.comp hd2).const_mul K)).const_mul A
    rw [max_eq_left (by linarith)]
    simpa using h

#print axioms black_tendsto_zero

lemma black_tendsto_atTop (A F K T : ℝ) (hT : 0 < T) :
    Tendsto (black A F K T) atTop (𝓝 (A * F)) := by
  have hs : 0 < √T := sqrt_pos.2 hT
  have hw : Tendsto (fun σ : ℝ => σ * √T) atTop atTop := tendsto_id.atTop_mul_const hs
  have hq0 := (tendsto_inv_atTop_zero.comp hw).const_mul (log (F / K))
  rw [mul_zero] at hq0
  have hq : Tendsto (fun σ : ℝ => log (F / K) / (σ * √T)) atTop (𝓝 0) :=
    hq0.congr fun σ => by simp [div_eq_mul_inv]
  have hh : Tendsto (fun σ : ℝ => σ * √T / 2) atTop atTop := hw.atTop_div_const two_pos
  have hd1 := hq.add_atTop hh
  have hd2 : Tendsto (fun σ : ℝ => log (F / K) / (σ * √T) - σ * √T / 2) atTop atBot :=
    (hq.add_atBot (tendsto_neg_atTop_atBot.comp hh)).congr fun σ => (sub_eq_add_neg _ _).symm
  have h : Tendsto (black A F K T) atTop (𝓝 (A * (F * 1 - K * 0))) :=
    (((N_atTop.comp hd1).const_mul F).sub ((N_atBot.comp hd2).const_mul K)).const_mul A
  simpa using h

#print axioms black_tendsto_atTop

lemma bachelier_tendsto_zero (A F K T : ℝ) (hT : 0 < T) :
    Tendsto (bachelier A F K T) (𝓝[>] 0) (𝓝 (A * max (F - K) 0)) := by
  have hs : 0 < √T := sqrt_pos.2 hT
  have hinv : Tendsto (fun σ : ℝ => (σ * √T)⁻¹) (𝓝[>] 0) atTop :=
    tendsto_inv_nhdsGT_zero.comp (tendsto_mul_nhdsGT _ hs)
  have hs0 : Tendsto (fun σ : ℝ => σ * √T) (𝓝[>] 0) (𝓝 0) :=
    (tendsto_mul_nhdsGT _ hs).mono_right nhdsWithin_le_nhds
  have h2 : Tendsto (fun σ : ℝ => σ * √T * φ ((F - K) / (σ * √T))) (𝓝[>] 0) (𝓝 0) := by
    have hb := hs0.mul_const (√(2 * π))⁻¹
    rw [zero_mul] at hb
    refine squeeze_zero' ?_ ?_ hb
    · filter_upwards [eventually_mem_nhdsWithin] with σ hσ
      have : 0 < σ := hσ
      exact mul_nonneg (by positivity) (φ_pos _).le
    · filter_upwards [eventually_mem_nhdsWithin] with σ hσ
      have : 0 < σ := hσ
      exact mul_le_mul_of_nonneg_left (φ_le _) (by positivity)
  have h1 : Tendsto (fun σ : ℝ => (F - K) * N ((F - K) / (σ * √T))) (𝓝[>] 0)
      (𝓝 (max (F - K) 0)) := by
    rcases lt_trichotomy (F - K) 0 with hm | hm | hm
    · have hq : Tendsto (fun σ : ℝ => (F - K) / (σ * √T)) (𝓝[>] 0) atBot :=
        (hinv.const_mul_atTop_of_neg hm).congr fun σ => (div_eq_mul_inv _ _).symm
      have := (N_atBot.comp hq).const_mul (F - K)
      rw [mul_zero] at this
      rw [max_eq_right hm.le]
      exact this
    · rw [hm]
      simp
    · have hq : Tendsto (fun σ : ℝ => (F - K) / (σ * √T)) (𝓝[>] 0) atTop :=
        (hinv.const_mul_atTop hm).congr fun σ => (div_eq_mul_inv _ _).symm
      have := (N_atTop.comp hq).const_mul (F - K)
      rw [mul_one] at this
      rw [max_eq_left hm.le]
      exact this
  have h := (h1.add h2).const_mul A
  rw [add_zero] at h
  exact h

#print axioms bachelier_tendsto_zero

lemma bachelier_tendsto_atTop (A F K T : ℝ) (hA : 0 < A) (hT : 0 < T) :
    Tendsto (bachelier A F K T) atTop atTop := by
  have hs : 0 < √T := sqrt_pos.2 hT
  have hw : Tendsto (fun σ : ℝ => σ * √T) atTop atTop := tendsto_id.atTop_mul_const hs
  have hq0 := (tendsto_inv_atTop_zero.comp hw).const_mul (F - K)
  rw [mul_zero] at hq0
  have hq : Tendsto (fun σ : ℝ => (F - K) / (σ * √T)) atTop (𝓝 0) :=
    hq0.congr fun σ => by simp [div_eq_mul_inv]
  have h1 := ((N_cont.tendsto 0).comp hq).const_mul (F - K)
  have h2 := hw.atTop_mul_pos (φ_pos 0) ((φ_cont.tendsto 0).comp hq)
  exact (h1.add_atTop h2).const_mul_atTop hA

#print axioms bachelier_tendsto_atTop

lemma black_lt (A F K T σ : ℝ) (hA : 0 < A) (hF : 0 < F) (hK : 0 < K) :
    black A F K T σ < A * F := by
  unfold black
  have h1 := N_lt_one (log (F / K) / (σ * √T) + σ * √T / 2)
  have h2 := N_pos (log (F / K) / (σ * √T) - σ * √T / 2)
  apply mul_lt_mul_of_pos_left _ hA
  nlinarith [mul_pos hK h2]

#print axioms black_lt

lemma black_mono (A F K T : ℝ) (hA : 0 < A) (hF : 0 < F) (hK : 0 < K) (hT : 0 < T) :
    ContinuousOn (black A F K T) (Ioi 0) ∧ StrictMonoOn (black A F K T) (Ioi 0) :=
  strictMonoOn_of_hasDerivAt (fun σ hσ => black_hasDerivAt_σ A F K T σ hF hK hT hσ)
    fun σ hσ => by have := φ_pos (log (F / K) / (σ * √T) + σ * √T / 2); have := sqrt_pos.2 hT; positivity

#print axioms black_mono

lemma black_gt (A F K T σ : ℝ) (hA : 0 < A) (hF : 0 < F) (hK : 0 < K) (hT : 0 < T) (hσ : 0 < σ) :
    A * max (F - K) 0 < black A F K T σ :=
  lower_of_tendsto (black_mono A F K T hA hF hK hT).2 (black_tendsto_zero A F K T hF hK hT) hσ

#print axioms black_gt

lemma black_implied_vol_unique_iff_aux (A F K T P : ℝ) (hA : 0 < A) (hF : 0 < F) (hK : 0 < K)
    (hT : 0 < T) :
    (∃! σ : ℝ, 0 < σ ∧ black A F K T σ = P) ↔ A * max (F - K) 0 < P ∧ P < A * F := by
  constructor
  · rintro ⟨σ, ⟨hσ, rfl⟩, -⟩
    exact ⟨black_gt A F K T σ hA hF hK hT hσ, black_lt A F K T σ hA hF hK⟩
  · rintro ⟨h1, h2⟩
    obtain ⟨hc, hm⟩ := black_mono A F K T hA hF hK hT
    refine exists_unique_of_mono hc hm (exists_below_of_tendsto (black_tendsto_zero A F K T hF hK hT) h1) ?_
    obtain ⟨y, hy1, hy2⟩ := (((black_tendsto_atTop A F K T hT).eventually (lt_mem_nhds h2)).and
      (eventually_gt_atTop 0)).exists
    exact ⟨y, hy2, hy1⟩

#print axioms black_implied_vol_unique_iff_aux

lemma bachelier_implied_vol_unique_iff_aux (A F K T P : ℝ) (hA : 0 < A) (hT : 0 < T) :
    (∃! σN : ℝ, 0 < σN ∧ bachelier A F K T σN = P) ↔ A * max (F - K) 0 < P := by
  have hmono : ContinuousOn (bachelier A F K T) (Ioi 0) ∧ StrictMonoOn (bachelier A F K T) (Ioi 0) :=
    strictMonoOn_of_hasDerivAt (fun σ hσ => bachelier_hasDerivAt A F K T σ hT hσ)
      fun σ hσ => by have := φ_pos ((F - K) / (σ * √T)); have := sqrt_pos.2 hT; positivity
  constructor
  · rintro ⟨σ, ⟨hσ, rfl⟩, -⟩
    exact lower_of_tendsto hmono.2 (bachelier_tendsto_zero A F K T hT) hσ
  · intro h1
    refine exists_unique_of_mono hmono.1 hmono.2
      (exists_below_of_tendsto (bachelier_tendsto_zero A F K T hT) h1) ?_
    obtain ⟨y, hy1, hy2⟩ := (((bachelier_tendsto_atTop A F K T hA hT).eventually_gt_atTop P).and
      (eventually_gt_atTop 0)).exists
    exact ⟨y, hy2, hy1⟩

#print axioms bachelier_implied_vol_unique_iff_aux

lemma black_K_tendsto_zero (A F T σ : ℝ) (hF : 0 < F) (hT : 0 < T) (hσ : 0 < σ) :
    Tendsto (fun K => black A F K T σ) (𝓝[>] 0) (𝓝 (A * F)) := by
  have hw : 0 < σ * √T := mul_pos hσ (sqrt_pos.2 hT)
  have hlog : Tendsto (fun K : ℝ => log F + -log K) (𝓝[>] 0) atTop :=
    tendsto_const_nhds.add_atTop (tendsto_neg_atBot_atTop.comp tendsto_log_nhdsGT_zero)
  have hL : Tendsto (fun K : ℝ => log (F / K)) (𝓝[>] 0) atTop := by
    refine hlog.congr' ?_
    filter_upwards [eventually_mem_nhdsWithin] with K hK
    have : 0 < K := hK
    rw [log_div hF.ne' this.ne']; ring
  have hd1 := (hL.atTop_div_const hw).atTop_add (tendsto_const_nhds (x := σ * √T / 2))
  have hd2 : Tendsto (fun K : ℝ => log (F / K) / (σ * √T) - σ * √T / 2) (𝓝[>] 0) atTop :=
    ((hL.atTop_div_const hw).atTop_add (tendsto_const_nhds (x := -(σ * √T / 2)))).congr
      fun K => (sub_eq_add_neg _ _).symm
  have hid : Tendsto (fun K : ℝ => K) (𝓝[>] 0) (𝓝 0) := tendsto_id'.2 nhdsWithin_le_nhds
  have h : Tendsto (fun K => black A F K T σ) (𝓝[>] 0) (𝓝 (A * (F * 1 - 0 * 1))) :=
    (((N_atTop.comp hd1).const_mul F).sub (hid.mul (N_atTop.comp hd2))).const_mul A
  simpa using h

#print axioms black_K_tendsto_zero

lemma black_K_upper_tendsto (F T σ : ℝ) (hF : 0 < F) (hT : 0 < T) (hσ : 0 < σ) :
    Tendsto (fun K => N (log (F / K) / (σ * √T) + σ * √T / 2)) atTop (𝓝 0) := by
  have hw : 0 < σ * √T := mul_pos hσ (sqrt_pos.2 hT)
  have hlog : Tendsto (fun K : ℝ => log F + -log K) atTop atBot :=
    tendsto_const_nhds.add_atBot (tendsto_neg_atTop_atBot.comp tendsto_log_atTop)
  have hL : Tendsto (fun K : ℝ => log (F / K)) atTop atBot := by
    refine hlog.congr' ?_
    filter_upwards [eventually_gt_atTop 0] with K hK
    rw [log_div hF.ne' hK.ne']; ring
  exact N_atBot.comp ((hL.atBot_div_const hw).atBot_add tendsto_const_nhds)

#print axioms black_K_upper_tendsto

lemma black_strike_from_price_unique_iff_aux (A F T σ P : ℝ) (hA : 0 < A) (hF : 0 < F)
    (hT : 0 < T) (hσ : 0 < σ) :
    (∃! K : ℝ, 0 < K ∧ black A F K T σ = P) ↔ 0 < P ∧ P < A * F := by
  constructor
  · rintro ⟨K, ⟨hK, rfl⟩, -⟩
    refine ⟨lt_of_le_of_lt ?_ (black_gt A F K T σ hA hF hK hT hσ), black_lt A F K T σ hA hF hK⟩
    exact mul_nonneg hA.le (le_max_right _ _)
  · rintro ⟨h1, h2⟩
    have hmono : ContinuousOn (fun K => -black A F K T σ) (Ioi 0) ∧
        StrictMonoOn (fun K => -black A F K T σ) (Ioi 0) :=
      strictMonoOn_of_hasDerivAt (fun K hK => (black_hasDerivAt_K A F K T σ hF hK hT hσ).neg)
        fun K hK => by
          simp only [neg_neg]
          exact mul_pos hA (N_pos _)
    have hx : ∃ x, 0 < x ∧ -black A F x T σ < -P := by
      obtain ⟨x, hx1, hx2⟩ := exists_below_of_tendsto (black_K_tendsto_zero A F T σ hF hT hσ).neg
        (neg_lt_neg h2)
      exact ⟨x, hx1, hx2⟩
    have hy : ∃ y, 0 < y ∧ -P < -black A F y T σ := by
      have hlim := (black_K_upper_tendsto F T σ hF hT hσ).const_mul (A * F)
      rw [mul_zero] at hlim
      obtain ⟨y, hy1, hy2⟩ := ((hlim.eventually (gt_mem_nhds h1)).and
        (eventually_gt_atTop 0)).exists
      refine ⟨y, hy2, neg_lt_neg ?_⟩
      have hb : black A F y T σ ≤ A * F * N (log (F / y) / (σ * √T) + σ * √T / 2) := by
        unfold black
        have := N_pos (log (F / y) / (σ * √T) - σ * √T / 2)
        have : 0 ≤ A * (y * N (log (F / y) / (σ * √T) - σ * √T / 2)) := by positivity
        nlinarith
      exact lt_of_le_of_lt hb hy1
    obtain ⟨K, ⟨hK, hg⟩, hu⟩ := exists_unique_of_mono hmono.1 hmono.2 hx hy
    refine ⟨K, ⟨hK, neg_inj.1 hg⟩, fun K' hK' => hu K' ⟨hK'.1, by rw [hK'.2]⟩⟩

#print axioms black_strike_from_price_unique_iff_aux

end Helpers

/-- Implied lognormal volatility: with positive annuity, forward, strike and expiry, a quoted
premium `P` is reached by exactly one positive Black volatility if and only if it lies strictly
between the intrinsic value `A max(F - K, 0)` and the floating leg `A F`. -/
theorem black_implied_vol_unique_iff (A F K T P : ℝ) (hA : 0 < A) (hF : 0 < F) (hK : 0 < K)
    (hT : 0 < T) :
    (∃! σ : ℝ, 0 < σ ∧ black A F K T σ = P) ↔ A * max (F - K) 0 < P ∧ P < A * F := by
  exact black_implied_vol_unique_iff_aux A F K T P hA hF hK hT

/-- Implied normal volatility: with positive annuity and expiry (forward and strike may have any
sign), a quoted premium `P` is reached by exactly one positive normal volatility if and only if it
lies strictly above the intrinsic value `A max(F - K, 0)`; there is no ceiling. -/
theorem bachelier_implied_vol_unique_iff (A F K T P : ℝ) (hA : 0 < A) (hT : 0 < T) :
    (∃! σN : ℝ, 0 < σN ∧ bachelier A F K T σN = P) ↔ A * max (F - K) 0 < P := by
  exact bachelier_implied_vol_unique_iff_aux A F K T P hA hT

/-- Strike from price: with positive annuity, forward, expiry and Black volatility, a quoted
premium `P` is paid by exactly one positive strike if and only if `0 < P < A F`. -/
theorem black_strike_from_price_unique_iff (A F T σ P : ℝ) (hA : 0 < A) (hF : 0 < F)
    (hT : 0 < T) (hσ : 0 < σ) :
    (∃! K : ℝ, 0 < K ∧ black A F K T σ = P) ↔ 0 < P ∧ P < A * F := by
  exact black_strike_from_price_unique_iff_aux A F T σ P hA hF hT hσ

#print axioms black_implied_vol_unique_iff
#print axioms bachelier_implied_vol_unique_iff
#print axioms black_strike_from_price_unique_iff

end RateOptionInverses
