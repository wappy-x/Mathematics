-- Rate volatilities: at the money the lognormal (Black) and normal (Bachelier) swaption premiums agree exactly when σN = F √(2π/T) [2N(w/2) - 1], and every premium strictly between the payoff locked in and the model's ceiling has exactly one lognormal, shifted or normal volatility.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF

open Real MeasureTheory ProbabilityTheory

namespace RateVolatilities

/-! The models (The formula). `N(x)` is Mathlib's `cdf (gaussianReal 0 1) x`, the bell-curve
area left of `x`; `φ(x)` is Mathlib's `gaussianPDFReal 0 1 x`, the curve's height at `x`.
`F` is the forward swap rate, `K` the strike, `T` the wait to expiry in years. A premium in rate
units is `p`; in dollars it is `V = M A p`, with notional `M` and annuity `A`.
The shifted model with shift `a` is Black with `F + a`, `K + a` and its own volatility. -/

/-- The bell-curve area left of `x`. -/
noncomputable def N (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- The bell curve's height at `x`. -/
noncomputable def φ (x : ℝ) : ℝ := gaussianPDFReal 0 1 x

/-- The Black (lognormal) payer premium in rate units:
`p = F N(d₁) - K N(d₂)`, `d₁ = (ln(F/K) + σ²T/2) / (σ√T)`, `d₂ = d₁ - σ√T`. -/
noncomputable def black (F K σ T : ℝ) : ℝ :=
  let d₁ := (log (F / K) + σ ^ 2 * T / 2) / (σ * √T)
  F * N d₁ - K * N (d₁ - σ * √T)

/-- The Bachelier (normal) payer premium in rate units:
`p = (F - K) N(d) + σN √T φ(d)`, `d = (F - K) / (σN √T)`. -/
noncomputable def bachelier (F K σN T : ℝ) : ℝ :=
  let d := (F - K) / (σN * √T)
  (F - K) * N d + σN * √T * φ d

section Helpers

open Filter Topology Set

lemma φ_eq (x : ℝ) : φ x = (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := by
  simp [φ, gaussianPDFReal]

lemma φ_pos (x : ℝ) : 0 < φ x := by rw [φ_eq]; positivity

lemma φ_le (x : ℝ) : φ x ≤ (√(2 * π))⁻¹ := by
  rw [φ_eq]
  have : exp (-x ^ 2 / 2) ≤ 1 := by
    rw [exp_le_one_iff]; nlinarith [sq_nonneg x]
  have h0 : 0 ≤ (√(2 * π))⁻¹ := by positivity
  nlinarith

lemma φ_continuous : Continuous φ := by
  have : φ = fun x => (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := funext φ_eq
  rw [this]; fun_prop

lemma φ_zero : φ 0 = (√(2 * π))⁻¹ := by simp [φ_eq]

lemma φ_neg (x : ℝ) : φ (-x) = φ x := by simp [φ_eq]

lemma N_eq_integral (x : ℝ) : N x = ∫ t in Iic x, φ t := by
  rw [N, cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal]
  · rfl
  · exact setIntegral_nonneg measurableSet_Iic (fun t _ => gaussianPDFReal_nonneg _ _ _)

lemma hasDerivAt_N (x : ℝ) : HasDerivAt N (φ x) x := by
  have hint : Integrable φ := integrable_gaussianPDFReal 0 1
  have hfun : N = fun u => N 0 + ∫ t in (0:ℝ)..u, φ t := by
    funext u
    rw [N_eq_integral, N_eq_integral, ← intervalIntegral.integral_Iic_sub_Iic hint.integrableOn
      hint.integrableOn]
    ring
  rw [hfun]
  apply HasDerivAt.const_add
  exact intervalIntegral.integral_hasDerivAt_right (hint.intervalIntegrable)
    (φ_continuous.stronglyMeasurableAtFilter _ _) φ_continuous.continuousAt

lemma N_continuous : Continuous N :=
  continuous_iff_continuousAt.2 fun x => (hasDerivAt_N x).continuousAt

lemma N_atTop : Tendsto N atTop (𝓝 1) := tendsto_cdf_atTop _
lemma N_atBot : Tendsto N atBot (𝓝 0) := tendsto_cdf_atBot _

lemma N_neg (x : ℝ) : N (-x) = 1 - N x := by
  have hd : ∀ y, HasDerivAt (fun y => N y + N (-y)) 0 y := by
    intro y
    have h1 := hasDerivAt_N y
    have h2 := (hasDerivAt_N (-y)).comp y (hasDerivAt_neg y)
    convert h1.add h2 using 1
    · rfl
    · rw [φ_neg]; ring
  have hc : ∀ y, N y + N (-y) = N 0 + N (-0) := fun y =>
    is_const_of_deriv_eq_zero (fun y => (hd y).differentiableAt) (fun y => (hd y).deriv) y 0
  have hlim : Tendsto (fun y => N y + N (-y)) atTop (𝓝 (1 + 0)) :=
    N_atTop.add (N_atBot.comp tendsto_neg_atTop_atBot)
  have hconst : Tendsto (fun y => N y + N (-y)) atTop (𝓝 (N 0 + N (-0))) := by
    rw [show (fun y => N y + N (-y)) = fun _ => N 0 + N (-0) from funext hc]
    exact tendsto_const_nhds
  have := tendsto_nhds_unique hconst hlim
  have := hc x
  linarith

lemma N_zero : N 0 = 1 / 2 := by
  have := N_neg 0; simp at this; linarith

lemma hasDerivAt_φ (x : ℝ) : HasDerivAt φ (-x * φ x) x := by
  have hf : φ = fun x => (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := funext φ_eq
  have h := (((hasDerivAt_pow 2 x).neg.div_const 2).exp).const_mul (√(2 * π))⁻¹
  rw [hf]
  convert h using 1
  simp; ring

lemma black_eq (F K σ T : ℝ) (hT : 0 ≤ T) :
    black F K σ T = F * N (log (F / K) / (σ * √T) + σ * √T / 2)
      - K * N (log (F / K) / (σ * √T) - σ * √T / 2) := by
  have hsq : σ ^ 2 * T = (σ * √T) ^ 2 := by rw [mul_pow, sq_sqrt hT]
  have h1 : (log (F / K) + σ ^ 2 * T / 2) / (σ * √T)
      = log (F / K) / (σ * √T) + σ * √T / 2 := by
    rw [hsq]; field_simp
  have h2 : log (F / K) / (σ * √T) + σ * √T / 2 - σ * √T
      = log (F / K) / (σ * √T) - σ * √T / 2 := by ring
  simp only [black, h1, h2]

lemma φ_black_identity (F K w : ℝ) (hF : 0 < F) (hK : 0 < K) (hw : w ≠ 0) :
    F * φ (log (F / K) / w + w / 2) = K * φ (log (F / K) / w - w / 2) := by
  rw [φ_eq, φ_eq]
  have h : -(log (F / K) / w + w / 2) ^ 2 / 2 = -(log (F / K) / w - w / 2) ^ 2 / 2
      + -log (F / K) := by
    field_simp; ring
  rw [h, exp_add, exp_neg, exp_log (div_pos hF hK)]
  field_simp

lemma black_hasDerivAt (F K w : ℝ) (hF : 0 < F) (hK : 0 < K) (hw : w ≠ 0) :
    HasDerivAt (fun w => F * N (log (F / K) / w + w / 2) - K * N (log (F / K) / w - w / 2))
      (K * φ (log (F / K) / w - w / 2)) w := by
  have hq : HasDerivAt (fun y => log (F / K) / y) ((0 * w - log (F / K) * 1) / w ^ 2) w :=
    (hasDerivAt_const w (log (F / K))).div (hasDerivAt_id w) hw
  have h1 := hq.add ((hasDerivAt_id w).div_const 2)
  have h2 := hq.sub ((hasDerivAt_id w).div_const 2)
  have := (((hasDerivAt_N (log (F / K) / w + w / 2)).comp w h1).const_mul F).sub
    (((hasDerivAt_N (log (F / K) / w - w / 2)).comp w h2).const_mul K)
  have key := φ_black_identity F K w hF hK hw
  convert this using 1
  · funext y; simp only [Pi.add_apply, Pi.sub_apply, Function.comp, id]
  · linear_combination (-((0 * w - log (F / K) * 1) / w ^ 2 + 1 / 2)) * key

lemma black_strictMonoOn (F K : ℝ) (hF : 0 < F) (hK : 0 < K) :
    StrictMonoOn (fun w => F * N (log (F / K) / w + w / 2) - K * N (log (F / K) / w - w / 2))
      (Ioi 0) := by
  apply strictMonoOn_of_deriv_pos (convex_Ioi 0)
  · intro w hw
    exact (black_hasDerivAt F K w hF hK (ne_of_gt hw)).continuousAt.continuousWithinAt
  · intro w hw
    rw [interior_Ioi] at hw
    rw [(black_hasDerivAt F K w hF hK (ne_of_gt hw)).deriv]
    exact mul_pos hK (φ_pos _)

lemma black_continuousOn (F K : ℝ) (hF : 0 < F) (hK : 0 < K) :
    ContinuousOn (fun w => F * N (log (F / K) / w + w / 2) - K * N (log (F / K) / w - w / 2))
      (Ioi 0) := fun w hw =>
  (black_hasDerivAt F K w hF hK (ne_of_gt hw)).continuousAt.continuousWithinAt

lemma black_tendsto_atTop (F K : ℝ) :
    Tendsto (fun w => F * N (log (F / K) / w + w / 2) - K * N (log (F / K) / w - w / 2))
      atTop (𝓝 F) := by
  have hL : Tendsto (fun w : ℝ => log (F / K) / w) atTop (𝓝 0) :=
    tendsto_const_nhds.div_atTop tendsto_id
  have hh : Tendsto (fun w : ℝ => w / 2) atTop atTop := tendsto_id.atTop_div_const two_pos
  have h1 : Tendsto (fun w : ℝ => log (F / K) / w + w / 2) atTop atTop := hL.add_atTop hh
  have h2 : Tendsto (fun w : ℝ => log (F / K) / w - w / 2) atTop atBot := by
    exact (hL.add_atBot (tendsto_neg_atTop_atBot.comp hh)).congr fun w => by
      simp [sub_eq_add_neg]
  have := ((N_atTop.comp h1).const_mul F).sub ((N_atBot.comp h2).const_mul K)
  rw [show F * 1 - K * 0 = F by ring] at this
  exact this

lemma black_tendsto_zero (F K : ℝ) (hF : 0 < F) (hK : 0 < K) :
    Tendsto (fun w => F * N (log (F / K) / w + w / 2) - K * N (log (F / K) / w - w / 2))
      (𝓝[>] 0) (𝓝 (max (F - K) 0)) := by
  have hw : Tendsto (fun w : ℝ => w / 2) (𝓝[>] 0) (𝓝 0) := by
    have : Tendsto (fun w : ℝ => w / 2) (𝓝 0) (𝓝 (0 / 2)) := tendsto_id.div_const 2
    rw [zero_div] at this
    exact this.mono_left nhdsWithin_le_nhds
  have hwn : Tendsto (fun w : ℝ => -(w / 2)) (𝓝[>] 0) (𝓝 0) := by
    simpa using hw.neg
  rcases lt_trichotomy (log (F / K)) 0 with hL | hL | hL
  · have hFK : F < K := by
      by_contra h
      have : 1 ≤ F / K := (one_le_div hK).2 (not_lt.1 h)
      linarith [log_nonneg this]
    have hinv : Tendsto (fun w : ℝ => log (F / K) / w) (𝓝[>] 0) atBot := by
      simpa only [← div_eq_mul_inv] using tendsto_inv_nhdsGT_zero.const_mul_atTop_of_neg hL
    have h1 := hinv.atBot_add hw
    have h2 : Tendsto (fun w : ℝ => log (F / K) / w - w / 2) (𝓝[>] 0) atBot := by
      exact (hinv.atBot_add hwn).congr fun w => by simp [sub_eq_add_neg]
    have := ((N_atBot.comp h1).const_mul F).sub ((N_atBot.comp h2).const_mul K)
    rw [show F * 0 - K * 0 = max (F - K) 0 by rw [max_eq_right (by linarith)]; ring] at this
    exact this
  · have hFK : F = K := by
      rcases log_eq_zero.1 hL with h | h | h
      · exact absurd h (div_pos hF hK).ne'
      · exact (div_eq_one_iff_eq hK.ne').1 h
      · linarith [div_pos hF hK]
    rw [hL]
    have h1 : Tendsto (fun w : ℝ => 0 / w + w / 2) (𝓝[>] 0) (𝓝 0) := by
      simpa using hw
    have h2 : Tendsto (fun w : ℝ => 0 / w - w / 2) (𝓝[>] 0) (𝓝 0) := by
      simpa [sub_eq_add_neg] using hwn
    have := (((N_continuous.tendsto 0).comp h1).const_mul F).sub
      (((N_continuous.tendsto 0).comp h2).const_mul K)
    rw [show F * N 0 - K * N 0 = max (F - K) 0 by rw [hFK]; simp] at this
    exact this
  · have hFK : K < F := by
      by_contra h
      have : F / K ≤ 1 := (div_le_one hK).2 (not_lt.1 h)
      linarith [log_nonpos (div_pos hF hK).le this]
    have hinv : Tendsto (fun w : ℝ => log (F / K) / w) (𝓝[>] 0) atTop := by
      simpa only [← div_eq_mul_inv] using tendsto_inv_nhdsGT_zero.const_mul_atTop hL
    have h1 := hinv.atTop_add hw
    have h2 : Tendsto (fun w : ℝ => log (F / K) / w - w / 2) (𝓝[>] 0) atTop := by
      exact (hinv.atTop_add hwn).congr fun w => by simp [sub_eq_add_neg]
    have := ((N_atTop.comp h1).const_mul F).sub ((N_atTop.comp h2).const_mul K)
    rw [show F * 1 - K * 1 = max (F - K) 0 by rw [max_eq_left (by linarith)]; ring] at this
    exact this

lemma bach_hasDerivAt (c u : ℝ) (hu : u ≠ 0) :
    HasDerivAt (fun u => c * N (c / u) + u * φ (c / u)) (φ (c / u)) u := by
  have hq : HasDerivAt (fun y => c / y) ((0 * u - c * 1) / u ^ 2) u :=
    (hasDerivAt_const u c).div (hasDerivAt_id u) hu
  have := (((hasDerivAt_N (c / u)).comp u hq).const_mul c).add
    ((hasDerivAt_id u).mul ((hasDerivAt_φ (c / u)).comp u hq))
  convert this using 1
  · funext y; simp only [Pi.add_apply, Pi.mul_apply, Function.comp, id]
  · simp only [Function.comp, id]
    field_simp
    ring

lemma bach_strictMonoOn (c : ℝ) :
    StrictMonoOn (fun u => c * N (c / u) + u * φ (c / u)) (Ioi 0) := by
  apply strictMonoOn_of_deriv_pos (convex_Ioi 0)
  · intro w hw
    exact (bach_hasDerivAt c w (ne_of_gt hw)).continuousAt.continuousWithinAt
  · intro w hw
    rw [interior_Ioi] at hw
    rw [(bach_hasDerivAt c w (ne_of_gt hw)).deriv]
    exact φ_pos _

lemma bach_continuousOn (c : ℝ) :
    ContinuousOn (fun u => c * N (c / u) + u * φ (c / u)) (Ioi 0) := fun w hw =>
  (bach_hasDerivAt c w (ne_of_gt hw)).continuousAt.continuousWithinAt

lemma bach_tendsto_atTop (c : ℝ) :
    Tendsto (fun u => c * N (c / u) + u * φ (c / u)) atTop atTop := by
  have hq : Tendsto (fun u : ℝ => c / u) atTop (𝓝 0) := tendsto_const_nhds.div_atTop tendsto_id
  have h1 := ((N_continuous.tendsto 0).comp hq).const_mul c
  have h2 := tendsto_id.atTop_mul_pos (φ_pos 0) ((φ_continuous.tendsto 0).comp hq)
  exact h1.add_atTop h2

lemma bach_tendsto_zero (c : ℝ) :
    Tendsto (fun u => c * N (c / u) + u * φ (c / u)) (𝓝[>] 0) (𝓝 (max c 0)) := by
  have h2 : Tendsto (fun u : ℝ => u * φ (c / u)) (𝓝[>] 0) (𝓝 0) := by
    have hup : Tendsto (fun u : ℝ => u * (√(2 * π))⁻¹) (𝓝[>] 0) (𝓝 0) := by
      have : Tendsto (fun u : ℝ => u * (√(2 * π))⁻¹) (𝓝 0) (𝓝 (0 * (√(2 * π))⁻¹)) :=
        tendsto_id.mul_const _
      rw [zero_mul] at this
      exact this.mono_left nhdsWithin_le_nhds
    refine tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds hup ?_ ?_
    · filter_upwards [self_mem_nhdsWithin] with u hu
      exact mul_nonneg (le_of_lt hu) (φ_pos _).le
    · filter_upwards [self_mem_nhdsWithin] with u hu
      exact mul_le_mul_of_nonneg_left (φ_le _) (le_of_lt hu)
  have h1 : Tendsto (fun u : ℝ => c * N (c / u)) (𝓝[>] 0) (𝓝 (max c 0)) := by
    rcases lt_trichotomy c 0 with hc | hc | hc
    · have hinv : Tendsto (fun w : ℝ => c / w) (𝓝[>] 0) atBot := by
        simpa only [← div_eq_mul_inv] using tendsto_inv_nhdsGT_zero.const_mul_atTop_of_neg hc
      have := (N_atBot.comp hinv).const_mul c
      rw [show c * 0 = max c 0 by rw [max_eq_right hc.le]; ring] at this
      exact this
    · subst hc; simp
    · have hinv : Tendsto (fun w : ℝ => c / w) (𝓝[>] 0) atTop := by
        simpa only [← div_eq_mul_inv] using tendsto_inv_nhdsGT_zero.const_mul_atTop hc
      have := (N_atTop.comp hinv).const_mul c
      rw [show c * 1 = max c 0 by rw [max_eq_left hc.le]; ring] at this
      exact this
  simpa using h1.add h2

lemma exists_unique_of_strictMonoOn (f : ℝ → ℝ) (T p : ℝ) (hT : 0 < T)
    (hmono : StrictMonoOn f (Ioi 0)) (hcont : ContinuousOn f (Ioi 0))
    (hlo : ∃ w, 0 < w ∧ f w < p) (hhi : ∃ w, 0 < w ∧ p < f w) :
    ∃! σ : ℝ, 0 < σ ∧ f (σ * √T) = p := by
  have hs : 0 < √T := sqrt_pos.2 hT
  obtain ⟨w₁, hw₁, hf₁⟩ := hlo
  obtain ⟨w₂, hw₂, hf₂⟩ := hhi
  have h12 : w₁ ≤ w₂ := by
    by_contra h
    have := hmono.monotoneOn hw₂ hw₁ (le_of_lt (not_le.1 h))
    linarith
  have hsub : Icc w₁ w₂ ⊆ Ioi 0 := fun x hx => lt_of_lt_of_le hw₁ hx.1
  obtain ⟨w, hw, hfw⟩ := intermediate_value_Icc h12 (hcont.mono hsub) ⟨hf₁.le, hf₂.le⟩
  have hw0 : 0 < w := hsub hw
  refine ⟨w / √T, ⟨div_pos hw0 hs, ?_⟩, ?_⟩
  · rw [div_mul_cancel₀ _ hs.ne']; exact hfw
  · rintro σ ⟨hσ, hσp⟩
    have hσw : σ * √T = w := by
      apply hmono.injOn (mul_pos hσ hs) hw0
      rw [hσp, hfw]
    rw [← hσw, mul_div_cancel_right₀ _ hs.ne']

lemma atm_aux (M A F σ σN T : ℝ)
    (hM : 0 < M) (hA : 0 < A) (hF : 0 < F) (_hσ : 0 < σ) (hT : 0 < T) :
    M * A * black F F σ T = M * A * bachelier F F σN T ↔
      σN = F * √(2 * π / T) * (2 * N (σ * √T / 2) - 1) := by
  have hs : 0 < √T := sqrt_pos.2 hT
  have hr : 0 < √(2 * π) := by positivity
  have hb : black F F σ T = F * (2 * N (σ * √T / 2) - 1) := by
    rw [black_eq F F σ T hT.le, div_self hF.ne', log_one, zero_div, zero_add, zero_sub, N_neg]
    ring
  have hn : bachelier F F σN T = σN * √T * (√(2 * π))⁻¹ := by
    simp only [bachelier, sub_self, zero_div, zero_mul, zero_add, φ_zero]
  rw [hb, hn, mul_right_inj' (by positivity : M * A ≠ 0), sqrt_div' _ hT.le]
  generalize 2 * N (σ * √T / 2) - 1 = X
  constructor
  · intro h
    field_simp at h ⊢
    linarith
  · intro h
    rw [h]
    field_simp

lemma shifted_aux (F K a T p : ℝ)
    (hF : 0 < F + a) (hK : 0 < K + a) (hT : 0 < T)
    (hlo : max (F - K) 0 < p) (hhi : p < F + a) :
    ∃! σa : ℝ, 0 < σa ∧ black (F + a) (K + a) σa T = p := by
  set f := fun w => (F + a) * N (log ((F + a) / (K + a)) / w + w / 2)
    - (K + a) * N (log ((F + a) / (K + a)) / w - w / 2) with hf
  have heq : ∀ σ, black (F + a) (K + a) σ T = f (σ * √T) := fun σ =>
    black_eq (F + a) (K + a) σ T hT.le
  simp_rw [heq]
  apply exists_unique_of_strictMonoOn f T p hT (black_strictMonoOn _ _ hF hK)
    (black_continuousOn _ _ hF hK)
  · have hlim := black_tendsto_zero (F + a) (K + a) hF hK
    have hlo' : max (F + a - (K + a)) 0 < p := by
      rw [show F + a - (K + a) = F - K by ring]; exact hlo
    exact ((hlim.eventually (gt_mem_nhds hlo')).and self_mem_nhdsWithin).exists.imp
      fun w hw => ⟨hw.2, hw.1⟩
  · exact (((black_tendsto_atTop (F + a) (K + a)).eventually (lt_mem_nhds hhi)).and
      (eventually_gt_atTop 0)).exists.imp fun w hw => ⟨hw.2, hw.1⟩

lemma normal_aux (F K T p : ℝ)
    (hT : 0 < T) (hlo : max (F - K) 0 < p) :
    ∃! σN : ℝ, 0 < σN ∧ bachelier F K σN T = p := by
  apply exists_unique_of_strictMonoOn (fun u => (F - K) * N ((F - K) / u) + u * φ ((F - K) / u))
    T p hT (bach_strictMonoOn _) (bach_continuousOn _)
  · exact (((bach_tendsto_zero (F - K)).eventually (gt_mem_nhds hlo)).and
      self_mem_nhdsWithin).exists.imp fun w hw => ⟨hw.2, hw.1⟩
  · exact (((bach_tendsto_atTop (F - K)).eventually_gt_atTop p).and
      (eventually_gt_atTop 0)).exists.imp fun w hw => ⟨hw.2, hw.1⟩

end Helpers

#print axioms φ_eq
#print axioms φ_pos
#print axioms φ_le
#print axioms φ_continuous
#print axioms φ_zero
#print axioms φ_neg
#print axioms N_eq_integral
#print axioms hasDerivAt_N
#print axioms N_continuous
#print axioms N_atTop
#print axioms N_atBot
#print axioms N_neg
#print axioms N_zero
#print axioms hasDerivAt_φ
#print axioms black_eq
#print axioms φ_black_identity
#print axioms black_hasDerivAt
#print axioms black_strictMonoOn
#print axioms black_continuousOn
#print axioms black_tendsto_atTop
#print axioms black_tendsto_zero
#print axioms bach_hasDerivAt
#print axioms bach_strictMonoOn
#print axioms bach_continuousOn
#print axioms bach_tendsto_atTop
#print axioms bach_tendsto_zero
#print axioms exists_unique_of_strictMonoOn
#print axioms atm_aux
#print axioms shifted_aux
#print axioms normal_aux

/-- **The exact conversion at the money** (The formula; Step 2). For one swaption, with the same
notional `M > 0` and annuity `A > 0` in both models, a forward swap rate `F > 0` struck at the
money (`K = F`), a lognormal volatility `σ > 0` and a wait `T > 0`: the lognormal dollar premium
`M A p` equals the normal dollar premium at normal volatility `σN` exactly when
`σN = F √(2π/T) [2N(w/2) - 1]`, with `w = σ √T`. -/
theorem atm_lognormal_to_normal_volatility_exact (M A F σ σN T : ℝ)
    (hM : 0 < M) (hA : 0 < A) (hF : 0 < F) (hσ : 0 < σ) (hT : 0 < T) :
    M * A * black F F σ T = M * A * bachelier F F σN T ↔
      σN = F * √(2 * π / T) * (2 * N (σ * √T / 2) - 1) := by
  exact atm_aux M A F σ σN T hM hA hF hσ hT

/-- **One lognormal or shifted quote per premium** (When it holds; Step 0). With shift `a`
(`a = 0` is plain lognormal), the forward and strike above the floor (`F + a > 0`, `K + a > 0`)
and a wait `T > 0`: every premium `p` strictly between the payoff locked in at zero volatility,
`max (F - K) 0`, and the ceiling `F + a` is reproduced by exactly one positive volatility `σₐ`
in the shifted Black model. -/
theorem shifted_lognormal_volatility_exists_unique (F K a T p : ℝ)
    (hF : 0 < F + a) (hK : 0 < K + a) (hT : 0 < T)
    (hlo : max (F - K) 0 < p) (hhi : p < F + a) :
    ∃! σa : ℝ, 0 < σa ∧ black (F + a) (K + a) σa T = p := by
  exact shifted_aux F K a T p hF hK hT hlo hhi

/-- **One normal quote per premium** (When it holds; Step 0). The normal model has no floor and
no ceiling: for any forward `F` and strike `K`, negative ones included, and a wait `T > 0`, every
premium `p` above the payoff locked in at zero volatility, `max (F - K) 0`, is reproduced by
exactly one positive normal volatility `σN`. -/
theorem normal_volatility_exists_unique (F K T p : ℝ)
    (hT : 0 < T) (hlo : max (F - K) 0 < p) :
    ∃! σN : ℝ, 0 < σN ∧ bachelier F K σN T = p := by
  exact normal_aux F K T p hT hlo

/-! The card's whole-number worked steps, rates in basis points, `σ = 0.30`, `T = 1`. -/

-- At the money the cut-offs are d₁ = (0 + 0.3²/2)/0.3 = 0.15 and d₂ = 0.15 - 0.3 = -0.15.
example : ((0 : ℚ) + (3 / 10) ^ 2 / 2) / (3 / 10) = 3 / 20 ∧
    (3 : ℚ) / 20 - 3 / 10 = -3 / 20 := by norm_num
-- The rule of thumb F σ = 440 × 0.30 = 132 bp.
example : (440 : ℚ) * (3 / 10) = 132 := by norm_num
-- The shrink factor 1 - 0.3²/24 = 0.99625, and 132 × 0.99625 = 131.505 bp.
example : (1 : ℚ) - (3 / 10) ^ 2 / 24 = 99625 / 100000 ∧
    (132 : ℚ) * (1 - (3 / 10) ^ 2 / 24) = 131505 / 1000 := by norm_num
-- The shifted rule with a 200 bp shift: σ F / (F + a) = 30 × 440 / 640 = 20.625 percent.
example : (440 : ℚ) + 200 = 640 ∧ (30 : ℚ) * 440 / 640 = 20625 / 1000 := by norm_num
-- The shifted rule at 100 and 300 bp shifts: 30 × 440 / 540 = 24.444... and 30 × 440 / 740 = 17.8378...
example : (30 : ℚ) * 440 / 540 = 220 / 9 ∧ (30 : ℚ) * 440 / 740 = 660 / 37 := by norm_num

#print axioms atm_lognormal_to_normal_volatility_exact
#print axioms shifted_lognormal_volatility_exists_unique
#print axioms normal_volatility_exists_unique

end RateVolatilities
