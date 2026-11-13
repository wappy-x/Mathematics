-- The volatility surface: call prices that are discounted averages over a fair-game (martingale) price pass both the butterfly test across strikes and the calendar test across expiries at fixed log-moneyness, and the Black-Scholes call in forward units rises strictly with total variance, so the calendar test on prices is the calendar test on total variance and every honest price has exactly one total variance.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.MeasureTheory.Function.ConditionalExpectation.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory Real

/-! The setting. `(Ω, P)` is the market's pricing probability. Two expiries `T₁ < T₂`.
`X₁`, `X₂` are Acme's price at each expiry divided by that expiry's forward, so each averages 1.
Known rates and a proportional dividend make `X` a fair game (a martingale): `X₁` is known by
time `T₁` (it is measurable for the information `m` held then), and the best forecast of `X₂`
made at `T₁` is `X₁`. `D₁, D₂ > 0` are the discount factors and `F₁, F₂ > 0` the forwards.
The dollar call at strike `K` and expiry `Tᵢ` is `Cᵢ(K) = Dᵢ · E[(Fᵢ Xᵢ - K)⁺]`.
Log-moneyness `k` puts the strike at `Fᵢ e^k`; the forward-scaled call is `Cᵢ / (Dᵢ Fᵢ)`. -/

lemma butterfly_pointwise (y h : ℝ) :
    0 ≤ max (y + h) 0 - 2 * max y 0 + max (y - h) 0 := by
  have h1 := le_max_left (y + h) 0
  have h2 := le_max_right (y + h) 0
  have h3 := le_max_left (y - h) 0
  have h4 := le_max_right (y - h) 0
  rcases le_total y 0 with hy | hy
  · rw [max_eq_right hy]; linarith
  · rw [max_eq_left hy]; linarith

#print axioms butterfly_pointwise

/-- **An honest surface passes both tests** (Why it works, Steps 0, 1 and 5). If every call
price is the discounted average of its payoff, and the forward-scaled price is a fair game
(martingale) between the two expiries, then (1) at each expiry and every strike `K` and step
`h ≥ 0`, the butterfly `C(K-h) - 2C(K) + C(K+h)` is never negative; and (2) at every
log-moneyness `k`, the later expiry's forward-scaled call is worth at least the earlier one's:
no negative calendar spread. -/
theorem honest_surface_passes_butterfly_and_calendar_tests
    {Ω : Type*} {m m₀ : MeasurableSpace Ω} (P : @Measure Ω m₀) [IsProbabilityMeasure P]
    (hm : m ≤ m₀) (X₁ X₂ : Ω → ℝ)
    (hX₁ : Integrable X₁ P) (hX₂ : Integrable X₂ P)
    (hX₁m : StronglyMeasurable[m] X₁) (hmart : P[X₂ | m] =ᵐ[P] X₁)
    (D₁ D₂ F₁ F₂ : ℝ) (hD₁ : 0 < D₁) (hD₂ : 0 < D₂) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂)
    (C₁ C₂ : ℝ → ℝ)
    (hC₁ : ∀ K, C₁ K = D₁ * ∫ ω, max (F₁ * X₁ ω - K) 0 ∂P)
    (hC₂ : ∀ K, C₂ K = D₂ * ∫ ω, max (F₂ * X₂ ω - K) 0 ∂P) :
    (∀ K h : ℝ, 0 ≤ h →
        0 ≤ C₁ (K - h) - 2 * C₁ K + C₁ (K + h) ∧ 0 ≤ C₂ (K - h) - 2 * C₂ K + C₂ (K + h)) ∧
      (∀ k : ℝ, C₁ (F₁ * exp k) / (D₁ * F₁) ≤ C₂ (F₂ * exp k) / (D₂ * F₂)) := by
  -- integrability of call payoffs
  have hint : ∀ (X : Ω → ℝ), Integrable X P → ∀ F K : ℝ,
      Integrable (fun ω => max (F * X ω - K) 0) P := by
    intro X hX F K
    exact ((hX.const_mul F).sub (integrable_const K)).pos_part
  have bfly : ∀ (X : Ω → ℝ), Integrable X P → ∀ (D F : ℝ), 0 < D → ∀ (C : ℝ → ℝ),
      (∀ K, C K = D * ∫ ω, max (F * X ω - K) 0 ∂P) →
      ∀ K h : ℝ, 0 ≤ h → 0 ≤ C (K - h) - 2 * C K + C (K + h) := by
    intro X hX D F hD C hC K h _
    have key : ∫ ω, (max (F * X ω - (K - h)) 0 - 2 * max (F * X ω - K) 0
        + max (F * X ω - (K + h)) 0) ∂P
        = (∫ ω, max (F * X ω - (K - h)) 0 ∂P) - 2 * (∫ ω, max (F * X ω - K) 0 ∂P)
          + ∫ ω, max (F * X ω - (K + h)) 0 ∂P := by
      have i2 : Integrable (fun ω => 2 * max (F * X ω - K) 0) P := (hint X hX F K).const_mul 2
      have i1 : Integrable (fun ω => max (F * X ω - (K - h)) 0 - 2 * max (F * X ω - K) 0) P :=
        (hint X hX F _).sub i2
      rw [integral_add i1 (hint X hX F _), integral_sub (hint X hX F _) i2, integral_const_mul]
    have hnn : 0 ≤ ∫ ω, (max (F * X ω - (K - h)) 0 - 2 * max (F * X ω - K) 0
        + max (F * X ω - (K + h)) 0) ∂P := by
      refine integral_nonneg fun ω => ?_
      have := butterfly_pointwise (F * X ω - K) h
      simp only
      rw [show F * X ω - (K - h) = F * X ω - K + h by ring,
        show F * X ω - (K + h) = F * X ω - K - h by ring]
      exact this
    rw [hC, hC, hC]
    rw [key] at hnn
    have := mul_nonneg hD.le hnn
    linarith
  refine ⟨fun K h hh => ⟨bfly X₁ hX₁ D₁ F₁ hD₁ C₁ hC₁ K h hh,
    bfly X₂ hX₂ D₂ F₂ hD₂ C₂ hC₂ K h hh⟩, fun k => ?_⟩
  -- calendar test
  set c := exp k
  have scale : ∀ (X : Ω → ℝ), ∀ (D F : ℝ), 0 < D → 0 < F → ∀ (C : ℝ → ℝ),
      (∀ K, C K = D * ∫ ω, max (F * X ω - K) 0 ∂P) →
      C (F * c) / (D * F) = ∫ ω, max (X ω - c) 0 ∂P := by
    intro X D F hD hF C hC
    rw [hC]
    have : (fun ω => max (F * X ω - F * c) 0) = fun ω => F * max (X ω - c) 0 := by
      funext ω
      rw [← mul_sub, mul_max_of_nonneg _ _ hF.le, mul_zero]
    rw [this, integral_const_mul]
    field_simp
  rw [scale X₁ D₁ F₁ hD₁ hF₁ C₁ hC₁, scale X₂ D₂ F₂ hD₂ hF₂ C₂ hC₂]
  set A : Set Ω := X₁ ⁻¹' Set.Ioi c with hA
  have hAm : MeasurableSet[m] A := hX₁m.measurable measurableSet_Ioi
  have hAm₀ : MeasurableSet A := hm _ hAm
  have e1 : (fun ω => max (X₁ ω - c) 0) = A.indicator (fun ω => X₁ ω - c) := by
    funext ω
    by_cases hω : ω ∈ A
    · rw [Set.indicator_of_mem hω]
      have : c < X₁ ω := hω
      exact max_eq_left (by linarith)
    · rw [Set.indicator_of_notMem hω]
      have : ¬ c < X₁ ω := hω
      exact max_eq_right (by linarith)
  have le2 : ∫ ω, A.indicator (fun ω => X₂ ω - c) ω ∂P ≤ ∫ ω, max (X₂ ω - c) 0 ∂P := by
    refine integral_mono ((hX₂.sub (integrable_const c)).indicator hAm₀)
      (hX₂.sub (integrable_const c)).pos_part fun ω => ?_
    by_cases hω : ω ∈ A
    · rw [Set.indicator_of_mem hω]; exact le_max_left _ _
    · rw [Set.indicator_of_notMem hω]; exact le_max_right _ _
  refine le_trans (le_of_eq ?_) le2
  rw [e1, integral_indicator hAm₀, integral_indicator hAm₀,
    integral_sub hX₁.integrableOn (integrable_const c).integrableOn,
    integral_sub hX₂.integrableOn (integrable_const c).integrableOn,
    ← setIntegral_condExp hm hX₂ hAm]
  congr 1
  exact setIntegral_congr_ae hAm₀ (hmart.mono fun ω hω _ => hω.symm)

/-- `N`, the bell-curve area to the left of `x`. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- The Black-Scholes call in forward units, written in log-moneyness `k` and total variance
`w` (Step 3): `c(k, w) = N(d₁) - e^k N(d₂)`, with `d₁ = -k/√w + √w/2` and `d₂ = d₁ - √w`. -/
noncomputable def forwardScaledCall (k w : ℝ) : ℝ :=
  stdNormalCDF (-k / √w + √w / 2) - exp k * stdNormalCDF (-k / √w - √w / 2)

lemma stdNormalCDF_eq_integral (x : ℝ) :
    stdNormalCDF x = ∫ t in Set.Iic x, gaussianPDFReal 0 1 t := by
  rw [stdNormalCDF, cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Iic
      (fun _ _ => gaussianPDFReal_nonneg _ _ _))]

#print axioms stdNormalCDF_eq_integral

lemma continuous_stdGaussianPDF : Continuous (gaussianPDFReal 0 1) := by
  rw [gaussianPDFReal_def]
  fun_prop

#print axioms continuous_stdGaussianPDF

lemma stdNormalCDF_hasDerivAt (x : ℝ) :
    HasDerivAt stdNormalCDF (gaussianPDFReal 0 1 x) x := by
  have h := ((continuous_stdGaussianPDF.integral_hasStrictDerivAt 0 x).hasDerivAt).const_add
    (stdNormalCDF 0)
  convert h using 1
  funext y
  rw [stdNormalCDF_eq_integral, stdNormalCDF_eq_integral,
    ← intervalIntegral.integral_Iic_sub_Iic (integrable_gaussianPDFReal 0 1).integrableOn
      (integrable_gaussianPDFReal 0 1).integrableOn]
  ring

#print axioms stdNormalCDF_hasDerivAt

lemma stdGaussianPDF_eq (x : ℝ) : gaussianPDFReal 0 1 x = (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := by
  simp [gaussianPDFReal]

#print axioms stdGaussianPDF_eq

/-- The forward-scaled call as a function of `s = √w`. -/
noncomputable def callInVol (k s : ℝ) : ℝ :=
  stdNormalCDF (-k / s + s / 2) - exp k * stdNormalCDF (-k / s - s / 2)

lemma callInVol_hasDerivAt (k s : ℝ) (hs : 0 < s) :
    HasDerivAt (callInVol k) (gaussianPDFReal 0 1 (-k / s + s / 2)) s := by
  have hd1 : HasDerivAt (fun s => -k / s + s / 2) (k / s ^ 2 + 1 / 2) s := by
    have := ((hasDerivAt_const s (-k)).div (hasDerivAt_id s) hs.ne').add
      ((hasDerivAt_id s).div_const 2)
    refine this.congr_deriv ?_
    show (0 * s - -k * 1) / s ^ 2 + 1 / 2 = k / s ^ 2 + 1 / 2
    ring
  have hd2 : HasDerivAt (fun s => -k / s - s / 2) (k / s ^ 2 - 1 / 2) s := by
    have := ((hasDerivAt_const s (-k)).div (hasDerivAt_id s) hs.ne').sub
      ((hasDerivAt_id s).div_const 2)
    refine this.congr_deriv ?_
    show (0 * s - -k * 1) / s ^ 2 - 1 / 2 = k / s ^ 2 - 1 / 2
    ring
  have h := ((stdNormalCDF_hasDerivAt _).comp s hd1).sub
    (((stdNormalCDF_hasDerivAt _).comp s hd2).const_mul (exp k))
  refine h.congr_deriv ?_
  have key : exp k * gaussianPDFReal 0 1 (-k / s - s / 2) = gaussianPDFReal 0 1 (-k / s + s / 2) := by
    rw [stdGaussianPDF_eq, stdGaussianPDF_eq, mul_left_comm, ← exp_add]
    congr 2
    field_simp
    ring
  rw [← mul_assoc, key]
  ring

#print axioms callInVol_hasDerivAt

lemma callInVol_strictMonoOn (k : ℝ) : StrictMonoOn (callInVol k) (Set.Ioi 0) := by
  refine strictMonoOn_of_deriv_pos (convex_Ioi 0) ?_ ?_
  · intro s hs
    exact (callInVol_hasDerivAt k s hs).continuousAt.continuousWithinAt
  · intro s hs
    rw [interior_Ioi] at hs
    rw [(callInVol_hasDerivAt k s hs).deriv]
    exact gaussianPDFReal_pos _ _ _ one_ne_zero

#print axioms callInVol_strictMonoOn

lemma forwardScaledCall_eq (k w : ℝ) : forwardScaledCall k w = callInVol k (√w) := rfl

#print axioms forwardScaledCall_eq

lemma stdNormalCDF_continuous : Continuous stdNormalCDF :=
  continuous_iff_continuousAt.2 fun x => (stdNormalCDF_hasDerivAt x).continuousAt

#print axioms stdNormalCDF_continuous

open Filter Topology in
lemma stdNormalCDF_tendsto_atTop : Tendsto stdNormalCDF atTop (𝓝 1) :=
  tendsto_cdf_atTop _

#print axioms stdNormalCDF_tendsto_atTop

open Filter Topology in
lemma stdNormalCDF_tendsto_atBot : Tendsto stdNormalCDF atBot (𝓝 0) :=
  tendsto_cdf_atBot _

#print axioms stdNormalCDF_tendsto_atBot

open Filter Topology in
lemma callInVol_tendsto_atTop (k : ℝ) : Tendsto (callInVol k) atTop (𝓝 1) := by
  have hk : Tendsto (fun s : ℝ => -k / s) atTop (𝓝 0) := tendsto_const_nhds.div_atTop tendsto_id
  have hs : Tendsto (fun s : ℝ => s / 2) atTop atTop := tendsto_id.atTop_div_const (by norm_num)
  have h1 : Tendsto (fun s : ℝ => -k / s + s / 2) atTop atTop := hk.add_atTop hs
  have h2 : Tendsto (fun s : ℝ => -k / s - s / 2) atTop atBot := by
    have := hk.add_atBot (tendsto_neg_atTop_atBot.comp hs)
    refine this.congr fun s => ?_
    simp [sub_eq_add_neg]
  have := (stdNormalCDF_tendsto_atTop.comp h1).sub
    ((stdNormalCDF_tendsto_atBot.comp h2).const_mul (exp k))
  simp at this; exact this

#print axioms callInVol_tendsto_atTop

open Filter Topology in
lemma callInVol_tendsto_zero (k : ℝ) :
    Tendsto (callInVol k) (𝓝[>] 0) (𝓝 (max (1 - exp k) 0)) := by
  have hs : Tendsto (fun s : ℝ => s / 2) (𝓝[>] 0) (𝓝 0) := by
    have := ((continuous_id.div_const (2:ℝ)).tendsto 0).mono_left (nhdsWithin_le_nhds (s := Set.Ioi 0))
    simpa using this
  have hs' : Tendsto (fun s : ℝ => -(s / 2)) (𝓝[>] 0) (𝓝 0) := by
    simpa using hs.neg
  rcases lt_trichotomy k 0 with hk | hk | hk
  · have hinv : Tendsto (fun s : ℝ => -k / s) (𝓝[>] 0) atTop := by
      have := tendsto_inv_nhdsGT_zero.const_mul_atTop (neg_pos.2 hk)
      refine this.congr fun s => ?_
      simp [div_eq_mul_inv]
    have h1 : Tendsto (fun s : ℝ => -k / s + s / 2) (𝓝[>] 0) atTop := hinv.atTop_add hs
    have h2 : Tendsto (fun s : ℝ => -k / s - s / 2) (𝓝[>] 0) atTop := by
      refine (hinv.atTop_add hs').congr fun s => ?_
      simp [sub_eq_add_neg]
    have := (stdNormalCDF_tendsto_atTop.comp h1).sub
      ((stdNormalCDF_tendsto_atTop.comp h2).const_mul (exp k))
    rw [max_eq_left (by linarith [Real.exp_lt_one_iff.2 hk])]
    simp at this; exact this
  · subst hk
    have hc : Tendsto (fun s : ℝ => stdNormalCDF (s / 2) - stdNormalCDF (-(s / 2))) (𝓝[>] 0)
        (𝓝 (stdNormalCDF 0 - stdNormalCDF 0)) :=
      ((stdNormalCDF_continuous.tendsto 0).comp hs).sub
        ((stdNormalCDF_continuous.tendsto 0).comp hs')
    rw [sub_self] at hc
    simp only [exp_zero, sub_self, max_self]
    refine hc.congr fun s => ?_
    simp [callInVol]
  · have hinv : Tendsto (fun s : ℝ => -k / s) (𝓝[>] 0) atBot := by
      have := tendsto_inv_nhdsGT_zero.const_mul_atTop_of_neg (neg_lt_zero.2 hk)
      refine this.congr fun s => ?_
      simp [div_eq_mul_inv]
    have h1 : Tendsto (fun s : ℝ => -k / s + s / 2) (𝓝[>] 0) atBot := hinv.atBot_add hs
    have h2 : Tendsto (fun s : ℝ => -k / s - s / 2) (𝓝[>] 0) atBot := by
      refine (hinv.atBot_add hs').congr fun s => ?_
      simp [sub_eq_add_neg]
    have := (stdNormalCDF_tendsto_atBot.comp h1).sub
      ((stdNormalCDF_tendsto_atBot.comp h2).const_mul (exp k))
    rw [max_eq_right (by linarith [Real.one_lt_exp_iff.2 hk])]
    simp at this; exact this

#print axioms callInVol_tendsto_zero

/-- **The forward-scaled call rises strictly with total variance** (Step 5). At every
log-moneyness `k`, more total variance `w = σ²T` means a strictly dearer forward-scaled call.
So "the later call is worth at least the earlier one at the same `k`" is the same statement as
"total variance never falls as expiry lengthens". -/
theorem forward_scaled_call_strictly_increasing_in_total_variance (k : ℝ) :
    StrictMonoOn (fun w => forwardScaledCall k w) (Set.Ioi 0) := by
  intro a ha b hb hab
  simp only [forwardScaledCall_eq]
  exact callInVol_strictMonoOn k (Real.sqrt_pos.2 ha) (Real.sqrt_pos.2 hb)
    (Real.sqrt_lt_sqrt (le_of_lt ha) hab)

/-- **Every honest price has exactly one implied total variance** (Step 6). At every
log-moneyness `k`, a forward-scaled call price strictly between the intrinsic value
`(1 - e^k)⁺` (zero volatility) and the forward `1` (unlimited volatility) is the Black-Scholes
price of exactly one positive total variance, so solving Black-Scholes backwards always has one
answer there. -/
theorem forward_scaled_call_implied_total_variance_exists_unique (k p : ℝ)
    (hlo : max (1 - exp k) 0 < p) (hhi : p < 1) :
    ∃! w : ℝ, 0 < w ∧ forwardScaledCall k w = p := by
  obtain ⟨a, ha, ha0⟩ :=
    (((callInVol_tendsto_zero k).eventually (gt_mem_nhds hlo)).and self_mem_nhdsWithin).exists
  obtain ⟨b, hb, hab⟩ :=
    (((callInVol_tendsto_atTop k).eventually (lt_mem_nhds hhi)).and (Filter.eventually_gt_atTop a)).exists
  have ha0' : (0 : ℝ) < a := ha0
  have hcont : ContinuousOn (callInVol k) (Set.Icc a b) := fun s hs =>
    (callInVol_hasDerivAt k s (lt_of_lt_of_le ha0' hs.1)).continuousAt.continuousWithinAt
  obtain ⟨s, hs, hsp⟩ := intermediate_value_Ioo hab.le hcont ⟨ha, hb⟩
  have hs0 : 0 < s := lt_trans ha0' hs.1
  refine ⟨s ^ 2, ⟨by positivity, ?_⟩, fun y hy => ?_⟩
  · rw [forwardScaledCall_eq, Real.sqrt_sq hs0.le, hsp]
  · refine (forward_scaled_call_strictly_increasing_in_total_variance k).injOn hy.1
      (show (0:ℝ) < s ^ 2 by positivity) ?_
    rw [hy.2, forwardScaledCall_eq, Real.sqrt_sq hs0.le, hsp]

-- Step 1: the 95/100/105 butterfly pays 0, 0, 0, 0, 5, 0, 0, 0, 0
-- when Acme finishes at 80, 85, 90, 95, 100, 105, 110, 115, 120.
example : (List.map (fun x : ℤ => max (x - 95) 0 - 2 * max (x - 100) 0 + max (x - 105) 0)
    [80, 85, 90, 95, 100, 105, 110, 115, 120]) = [0, 0, 0, 0, 5, 0, 0, 0, 0] := by decide
-- Step 1: above 105 the three payoffs x - 95, -2(x - 100) and x - 105 sum to 0.
example : ∀ x : ℤ, (x - 95) - 2 * (x - 100) + (x - 105) = 0 := by intro x; norm_num; ring
-- The grid: 3 expiries × 9 strikes = 27 quotes; 7 interior strikes × 3 expiries = 21 butterflies.
example : 3 * 9 = 27 ∧ 7 * 3 = 21 := by decide
-- Lifted 6-month row at the same strike: forward variance (1 × 0.20² - 0.5 × 0.28²) / 0.5 = 0.0016.
example : ((1 : ℚ) * (1 / 5) ^ 2 - (1 / 2) * (7 / 25) ^ 2) / (1 / 2) = 16 / 10000 := by norm_num
-- Naive 9-month vol, linear in volatility: (18 + 20) / 2 = 19 percent.
example : ((18 : ℚ) + 20) / 2 = 19 := by norm_num

#print axioms honest_surface_passes_butterfly_and_calendar_tests
#print axioms forward_scaled_call_strictly_increasing_in_total_variance
#print axioms forward_scaled_call_implied_total_variance_exists_unique
