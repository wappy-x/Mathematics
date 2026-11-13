-- Forward measures: with the bond paying $1 on the payment date as the unit, the quarter's forward rate is a fair bet (a martingale), a payment on that date is priced as today's bond price times its plain average, and a lognormal forward makes that average Black's bracket.
import Mathlib.Probability.Martingale.Basic
import Mathlib.MeasureTheory.Measure.WithDensity
import Mathlib.MeasureTheory.Integral.Bochner.ContinuousLinearMap
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory

lemma trim_withDensity_martingale {Ω ι : Type*} {m0 : MeasurableSpace Ω} [Preorder ι] [OrderTop ι]
    (Q : Measure Ω) [IsFiniteMeasure Q] (ℱ : Filtration ι m0) (M : ι → Ω → ℝ)
    (hM : Martingale M ℱ Q) (hM_nn : ∀ t ω, 0 ≤ M t ω) (c : ℝ) (hc : 0 < c) (t : ι) :
    (Q.withDensity (fun ω => ENNReal.ofReal (M ⊤ ω / c))).trim (ℱ.le t) =
      @Measure.withDensity Ω (ℱ t) (Q.trim (ℱ.le t)) (fun ω => ENNReal.ofReal (M t ω / c)) := by
  have hmt : Measurable[ℱ t] (fun ω => ENNReal.ofReal (M t ω / c)) :=
    ((hM.stronglyMeasurable t).measurable.div_const c).ennreal_ofReal
  refine @Measure.ext _ (ℱ t) _ _ (fun A hA => ?_)
  rw [trim_measurableSet_eq (ℱ.le t) hA, withDensity_apply _ (ℱ.le t A hA),
    withDensity_apply (μ := Q.trim (ℱ.le t)) _ hA, restrict_trim (ℱ.le t) Q hA, lintegral_trim _ hmt,
    ← ofReal_integral_eq_lintegral_ofReal, ← ofReal_integral_eq_lintegral_ofReal]
  · congr 1
    rw [integral_div, integral_div, hM.setIntegral_eq le_top hA]
  · exact ((hM.integrable t).div_const c).restrict
  · exact ae_of_all _ (fun ω => div_nonneg (hM_nn t ω) hc.le)
  · exact ((hM.integrable ⊤).div_const c).restrict
  · exact ae_of_all _ (fun ω => div_nonneg (hM_nn ⊤ ω) hc.le)

#print axioms trim_withDensity_martingale

lemma integral_withDensity_martingale {Ω ι : Type*} {m0 : MeasurableSpace Ω} [Preorder ι]
    [OrderTop ι] (Q : Measure Ω) [IsFiniteMeasure Q] (ℱ : Filtration ι m0) (M : ι → Ω → ℝ)
    (hM : Martingale M ℱ Q) (hM_nn : ∀ t ω, 0 ≤ M t ω) (c : ℝ) (hc : 0 < c) (t : ι)
    (G : Ω → ℝ) (hG : StronglyMeasurable[ℱ t] G) :
    ∫ ω, G ω ∂(Q.withDensity (fun ω => ENNReal.ofReal (M ⊤ ω / c))) =
      ∫ ω, M t ω / c * G ω ∂Q := by
  have hmt : Measurable[ℱ t] (fun ω => (M t ω / c).toNNReal) :=
    ((hM.stronglyMeasurable t).measurable.div_const c).real_toNNReal
  have hprod : StronglyMeasurable[ℱ t] (fun ω => M t ω / c * G ω) :=
    (((hM.stronglyMeasurable t).measurable.div_const c).stronglyMeasurable).mul hG
  rw [integral_trim (ℱ.le t) hG, trim_withDensity_martingale Q ℱ M hM hM_nn c hc t,
    integral_trim (ℱ.le t) hprod]
  have h := @integral_withDensity_eq_integral_smul Ω ℝ (ℱ t) (Q.trim (ℱ.le t)) _ _
    (fun ω => (M t ω / c).toNNReal) hmt G
  refine h.trans ?_
  congr 1 with ω
  rw [NNReal.smul_def, smul_eq_mul, Real.coe_toNNReal _ (div_nonneg (hM_nn t ω) hc.le)]

#print axioms integral_withDensity_martingale

lemma integrable_withDensity_martingale {Ω ι : Type*} {m0 : MeasurableSpace Ω} [Preorder ι]
    [OrderTop ι] (Q : Measure Ω) [IsFiniteMeasure Q] (ℱ : Filtration ι m0) (M : ι → Ω → ℝ)
    (hM : Martingale M ℱ Q) (hM_nn : ∀ t ω, 0 ≤ M t ω) (c : ℝ) (hc : 0 < c) (t : ι)
    (G : Ω → ℝ) (hG : StronglyMeasurable[ℱ t] G)
    (hint : Integrable (fun ω => M t ω / c * G ω) Q) :
    Integrable G (Q.withDensity (fun ω => ENNReal.ofReal (M ⊤ ω / c))) := by
  have hmt : Measurable[ℱ t] (fun ω => (M t ω / c).toNNReal) :=
    ((hM.stronglyMeasurable t).measurable.div_const c).real_toNNReal
  have hprod : StronglyMeasurable[ℱ t] (fun ω => M t ω / c * G ω) :=
    (((hM.stronglyMeasurable t).measurable.div_const c).stronglyMeasurable).mul hG
  refine integrable_of_integrable_trim (ℱ.le t) ?_
  rw [trim_withDensity_martingale Q ℱ M hM hM_nn c hc t]
  have h := integrable_withDensity_iff_integrable_smul (μ := Q.trim (ℱ.le t)) hmt (g := G)
  refine h.mpr ?_
  have h2 := hint.trim (ℱ.le t) hprod
  refine h2.congr (ae_of_all _ (fun ω => ?_))
  simp only
  rw [NNReal.smul_def, smul_eq_mul, Real.coe_toNNReal _ (div_nonneg (hM_nn t ω) hc.le)]

#print axioms integrable_withDensity_martingale

lemma gaussian_Ioi_eq_cdf (m a s : ℝ) (hs : 0 < s) :
    (gaussianReal m (s ^ 2).toNNReal) (Set.Ioi a) =
      ENNReal.ofReal (cdf (gaussianReal 0 1) ((m - a) / s)) := by
  have hmap : (gaussianReal m (s ^ 2).toNNReal).map (fun x => (m - x) / s) = gaussianReal 0 1 := by
    have : (fun x : ℝ => (m - x) / s) = (fun x => x / s) ∘ (fun x => m - x) := rfl
    rw [this, ← Measure.map_map (by fun_prop) (by fun_prop), gaussianReal_map_const_sub,
      gaussianReal_map_div_const]
    congr 1
    · simp
    · ext
      simp [Real.coe_toNNReal _ (sq_nonneg s), hs.ne']
  have hpre : (fun x => (m - x) / s) ⁻¹' Set.Iio ((m - a) / s) = Set.Ioi a := by
    ext x
    simp only [Set.mem_preimage, Set.mem_Iio, Set.mem_Ioi]
    rw [div_lt_div_iff_of_pos_right hs]
    constructor <;> intro h <;> linarith
  have := nullSingletonClass_gaussianReal (μ := (0 : ℝ)) (v := 1) one_ne_zero
  rw [ofReal_cdf, ← measure_congr (Iio_ae_eq_Iic (μ := gaussianReal 0 1)), ← hmap,
    Measure.map_apply (by fun_prop) measurableSet_Iio, hpre]

#print axioms gaussian_Ioi_eq_cdf

lemma gaussianPDFReal_exp_tilt (m : ℝ) (v : NNReal) (hv : v ≠ 0) (x : ℝ) :
    gaussianPDFReal m v x * Real.exp x =
      Real.exp (m + v / 2) * gaussianPDFReal (m + v) v x := by
  have hv' : (v : ℝ) ≠ 0 := by exact_mod_cast hv
  simp only [gaussianPDFReal]
  rw [mul_assoc, ← Real.exp_add, mul_left_comm, ← Real.exp_add]
  congr 2
  field_simp
  ring

#print axioms gaussianPDFReal_exp_tilt

lemma setIntegral_exp_gaussianReal (m a : ℝ) (v : NNReal) (hv : v ≠ 0) :
    ∫ x in Set.Ioi a, Real.exp x ∂(gaussianReal m v) =
      Real.exp (m + v / 2) * ((gaussianReal (m + v) v) (Set.Ioi a)).toReal := by
  rw [← integral_indicator measurableSet_Ioi, integral_gaussianReal_eq_integral_smul hv,
    gaussianReal_apply_eq_integral _ hv,
    ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Ioi
      (fun x _ => gaussianPDFReal_nonneg _ _ x)),
    ← integral_const_mul, ← integral_indicator measurableSet_Ioi]
  congr 1 with x
  by_cases hx : x ∈ Set.Ioi a
  · simp [Set.indicator_of_mem hx, smul_eq_mul, gaussianPDFReal_exp_tilt m v hv x]
  · simp [Set.indicator_of_notMem hx]

#print axioms setIntegral_exp_gaussianReal

/-- The forward rate is a fair bet under the payment-date bond's odds. Time runs over any ordered
index from today (`⊥`) to the payment date `T₂` (`⊤`), so it covers discrete and continuous time.
Let `B` be the bank account and `P₁`, `P₂` the prices of the bonds paying $1 at the fixing date
and at the payment date; all three are strictly positive, and today's values `B₀`, `P₂₀` are
known numbers. Let `Q` be the bank's (risk-neutral) odds: both bonds counted in bank units,
`P₁ / B` and `P₂ / B`, are `Q`-martingales (both bonds trade). Reweight `Q` by how well the
payment-date bond did against the bank, `Z = (P₂(T₂) / B(T₂)) / (P₂₀ / B₀)`, to get the forward
measure `Q^{T₂}`. Then for any accrual fraction `τ > 0` the forward rate
`F(t) = (P₁(t) / P₂(t) - 1) / τ` is a martingale under `Q^{T₂}`; in particular
`E^{T₂}[F(T₁)] = F(0)`. -/
theorem forward_rate_is_martingale_under_forward_measure {Ω ι : Type*} {m0 : MeasurableSpace Ω}
    [Preorder ι] [OrderBot ι] [OrderTop ι]
    (Q : Measure Ω) [IsProbabilityMeasure Q] (ℱ : Filtration ι m0)
    (B P₁ P₂ : ι → Ω → ℝ) (B₀ P₂₀ τ : ℝ) (hτ : 0 < τ)
    (hB_pos : ∀ t ω, 0 < B t ω) (hP₁_pos : ∀ t ω, 0 < P₁ t ω) (hP₂_pos : ∀ t ω, 0 < P₂ t ω)
    (hB₀ : ∀ ω, B ⊥ ω = B₀) (hP₂₀ : ∀ ω, P₂ ⊥ ω = P₂₀)
    (hP₁ : Martingale (fun t ω => P₁ t ω / B t ω) ℱ Q)
    (hP₂ : Martingale (fun t ω => P₂ t ω / B t ω) ℱ Q) :
    Martingale (fun t ω => (P₁ t ω / P₂ t ω - 1) / τ) ℱ
      (Q.withDensity (fun ω => ENNReal.ofReal ((P₂ ⊤ ω / B ⊤ ω) / (P₂₀ / B₀)))) := by
  obtain ⟨ω₀⟩ := nonempty_of_isProbabilityMeasure Q
  have hP₂₀pos : 0 < P₂₀ := hP₂₀ ω₀ ▸ hP₂_pos ⊥ ω₀
  have hB₀pos : 0 < B₀ := hB₀ ω₀ ▸ hB_pos ⊥ ω₀
  set c := P₂₀ / B₀ with hc_def
  have hc : 0 < c := div_pos hP₂₀pos hB₀pos
  set M : ι → Ω → ℝ := fun t ω => P₂ t ω / B t ω with hM_def
  set N : ι → Ω → ℝ := fun t ω => P₁ t ω / B t ω with hN_def
  have hMnn : ∀ t ω, 0 ≤ M t ω := fun t ω => (div_pos (hP₂_pos t ω) (hB_pos t ω)).le
  have : IsFiniteMeasure (Q.withDensity (fun ω => ENNReal.ofReal (M ⊤ ω / c))) :=
    isFiniteMeasure_withDensity_ofReal ((hP₂.integrable ⊤).div_const c).2
  have hFeq : ∀ t, (fun ω => (P₁ t ω / P₂ t ω - 1) / τ) = fun ω => (N t ω / M t ω - 1) / τ := by
    intro t
    ext ω
    have := hB_pos t ω
    have := hP₂_pos t ω
    simp only [hM_def, hN_def]
    field_simp
  have hsm : ∀ t, StronglyMeasurable[ℱ t] (fun ω => (P₁ t ω / P₂ t ω - 1) / τ) := by
    intro t
    rw [hFeq]
    exact ((((hP₁.stronglyMeasurable t).measurable.div
      (hP₂.stronglyMeasurable t).measurable).sub_const 1).div_const τ).stronglyMeasurable
  have hprod : ∀ t ω, M t ω / c * ((P₁ t ω / P₂ t ω - 1) / τ) = (N t ω - M t ω) / (c * τ) := by
    intro t ω
    have := hB_pos t ω
    have := hP₂_pos t ω
    simp only [hM_def, hN_def]
    field_simp
  have hint : ∀ t, Integrable (fun ω => (P₁ t ω / P₂ t ω - 1) / τ)
      (Q.withDensity (fun ω => ENNReal.ofReal (M ⊤ ω / c))) := by
    intro t
    refine integrable_withDensity_martingale Q ℱ M hP₂ hMnn c hc t _ (hsm t) ?_
    simp_rw [hprod]
    exact ((hP₁.integrable t).sub (hP₂.integrable t)).div_const _
  have hset : ∀ t s, MeasurableSet[ℱ t] s →
      ∫ ω in s, (P₁ t ω / P₂ t ω - 1) / τ ∂(Q.withDensity (fun ω => ENNReal.ofReal (M ⊤ ω / c)))
        = (∫ ω in s, N t ω ∂Q - ∫ ω in s, M t ω ∂Q) / (c * τ) := by
    intro t s hs
    rw [← integral_indicator (ℱ.le t s hs),
      integral_withDensity_martingale Q ℱ M hP₂ hMnn c hc t _ ((hsm t).indicator hs),
      ← integral_sub (hP₁.integrable t).integrableOn (hP₂.integrable t).integrableOn,
      ← integral_div, ← integral_indicator (ℱ.le t s hs)]
    congr 1 with ω
    by_cases hω : ω ∈ s
    · simp only [Set.indicator_of_mem hω]
      exact hprod t ω
    · simp [Set.indicator_of_notMem hω]
  refine ⟨fun t => hsm t, fun i j hij => ?_⟩
  refine (ae_eq_condExp_of_forall_setIntegral_eq (ℱ.le i) (hint j)
    (fun s _ _ => (hint i).integrableOn) (fun s hs _ => ?_) (hsm i).aestronglyMeasurable).symm
  rw [hset i s hs, hset j s (ℱ.mono hij s hs), hP₁.setIntegral_eq hij hs,
    hP₂.setIntegral_eq hij hs]

/-- The caplet is the payment-date bond times its plain average payoff. In the same setting,
let the payment-date bond pay exactly $1 on the payment date (`P₂(T₂) = 1`). The caplet pays
`τ · (F(T₁) - K)⁺` dollars on the payment date, where `F(T₁)` is the forward rate fixed at the
fixing date `T₁` and `K` is the strike. Its price by the bank's odds,
`V = B₀ · E^Q[τ (F(T₁) - K)⁺ / B(T₂)]`, equals today's payment-date bond price times the
undiscounted average of the payoff under the forward measure:
`V = P(0, T₂) · E^{T₂}[τ (F(T₁) - K)⁺]`. -/
theorem caplet_price_eq_bond_times_forward_average {Ω ι : Type*} {m0 : MeasurableSpace Ω}
    [Preorder ι] [OrderBot ι] [OrderTop ι]
    (Q : Measure Ω) [IsProbabilityMeasure Q] (ℱ : Filtration ι m0)
    (B P₁ P₂ : ι → Ω → ℝ) (B₀ P₂₀ τ K : ℝ) (T₁ : ι) (hτ : 0 < τ)
    (hB_pos : ∀ t ω, 0 < B t ω) (hP₁_pos : ∀ t ω, 0 < P₁ t ω) (hP₂_pos : ∀ t ω, 0 < P₂ t ω)
    (hB₀ : ∀ ω, B ⊥ ω = B₀) (hP₂₀ : ∀ ω, P₂ ⊥ ω = P₂₀)
    (hP₁ : Martingale (fun t ω => P₁ t ω / B t ω) ℱ Q)
    (hP₂ : Martingale (fun t ω => P₂ t ω / B t ω) ℱ Q)
    (hP₂_pays : ∀ ω, P₂ ⊤ ω = 1) :
    B₀ * ∫ ω, τ * max ((P₁ T₁ ω / P₂ T₁ ω - 1) / τ - K) 0 / B ⊤ ω ∂Q =
      P₂₀ * ∫ ω, τ * max ((P₁ T₁ ω / P₂ T₁ ω - 1) / τ - K) 0
        ∂(Q.withDensity (fun ω => ENNReal.ofReal ((P₂ ⊤ ω / B ⊤ ω) / (P₂₀ / B₀)))) := by
  obtain ⟨ω₀⟩ := nonempty_of_isProbabilityMeasure Q
  have hP₂₀pos : 0 < P₂₀ := hP₂₀ ω₀ ▸ hP₂_pos ⊥ ω₀
  have hB₀pos : 0 < B₀ := hB₀ ω₀ ▸ hB_pos ⊥ ω₀
  have hmeas : Measurable (fun ω => P₂ ⊤ ω / B ⊤ ω) :=
    ((hP₂.stronglyMeasurable ⊤).mono (ℱ.le ⊤)).measurable
  have hZ : (fun ω => ENNReal.ofReal ((P₂ ⊤ ω / B ⊤ ω) / (P₂₀ / B₀))) =
      fun ω => (((P₂ ⊤ ω / B ⊤ ω) / (P₂₀ / B₀)).toNNReal : ENNReal) := rfl
  rw [hZ, integral_withDensity_eq_integral_smul (hmeas.div_const _).real_toNNReal,
    ← integral_const_mul, ← integral_const_mul]
  congr 1 with ω
  have hB := hB_pos ⊤ ω
  have hP := hP₂_pos ⊤ ω
  rw [NNReal.smul_def, smul_eq_mul, Real.coe_toNNReal _ (by positivity), hP₂_pays ω]
  field_simp

/-- Black's bracket for a lognormal forward. Let the forward fixed at `T₁` be lognormal under
the odds in use: `ln F(T₁)` is a bell curve with centre `ln F(0) - σ² T₁ / 2` and spread
`σ √T₁`, with `F(0) > 0`, strike `K > 0`, volatility `σ > 0` and `T₁ > 0`. Then the average
call payoff is `E[(F(T₁) - K)⁺] = F(0) N(d₁) - K N(d₂)`, where `N` is the standard normal
distribution function, `d₁ = (ln(F(0) / K) + σ² T₁ / 2) / (σ √T₁)` and `d₂ = d₁ - σ √T₁`. -/
theorem lognormal_forward_call_average_eq_black {Ω : Type*} {m0 : MeasurableSpace Ω}
    (μ : Measure Ω) [IsProbabilityMeasure μ] (F₁ : Ω → ℝ) (F₀ K σ T₁ : ℝ)
    (hF₀ : 0 < F₀) (hK : 0 < K) (hσ : 0 < σ) (hT₁ : 0 < T₁)
    (hlaw : μ.map (fun ω => Real.log (F₁ ω)) =
      gaussianReal (Real.log F₀ - σ ^ 2 * T₁ / 2) (Real.toNNReal (σ ^ 2 * T₁)))
    (hF₁_pos : ∀ ω, 0 < F₁ ω) :
    ∫ ω, max (F₁ ω - K) 0 ∂μ =
      F₀ * cdf (gaussianReal 0 1)
          ((Real.log (F₀ / K) + σ ^ 2 * T₁ / 2) / (σ * Real.sqrt T₁)) -
        K * cdf (gaussianReal 0 1)
          ((Real.log (F₀ / K) + σ ^ 2 * T₁ / 2) / (σ * Real.sqrt T₁) - σ * Real.sqrt T₁) := by
  set s := σ * Real.sqrt T₁ with hs_def
  have hs : 0 < s := mul_pos hσ (Real.sqrt_pos.mpr hT₁)
  have hs2 : s ^ 2 = σ ^ 2 * T₁ := by rw [hs_def, mul_pow, Real.sq_sqrt hT₁.le]
  set v : NNReal := (σ ^ 2 * T₁).toNNReal with hv_def
  have hvr : (v : ℝ) = σ ^ 2 * T₁ := Real.coe_toNNReal _ (by positivity)
  have hv : v ≠ 0 := by
    intro h
    have : (v : ℝ) = 0 := by simp [h]
    rw [hvr] at this
    have : 0 < σ ^ 2 * T₁ := by positivity
    linarith
  set m := Real.log F₀ - σ ^ 2 * T₁ / 2 with hm_def
  have hvs : v = (s ^ 2).toNNReal := by rw [hs2]
  -- the log-forward is a.e. measurable, since its law is not a Dirac mass
  have hae : AEMeasurable (fun ω => Real.log (F₁ ω)) μ := by
    by_contra h
    rw [Measure.map_of_not_aemeasurable_of_ne_zero h (IsProbabilityMeasure.ne_zero μ)] at hlaw
    have := nullSingletonClass_gaussianReal (μ := m) hv
    have h1 := congrArg (fun ν : Measure ℝ => ν {Classical.ofNonempty}) hlaw
    simp only [Measure.dirac_apply_of_mem (Set.mem_singleton _), measure_singleton] at h1
    exact one_ne_zero h1
  have hA : ∫ ω, max (F₁ ω - K) 0 ∂μ = ∫ y, max (Real.exp y - K) 0 ∂(gaussianReal m v) := by
    rw [← hlaw, integral_map hae (by fun_prop)]
    congr 1 with ω
    rw [Real.exp_log (hF₁_pos ω)]
  set a := Real.log K with ha_def
  have hB : ∫ y, max (Real.exp y - K) 0 ∂(gaussianReal m v) =
      ∫ y in Set.Ioi a, Real.exp y ∂(gaussianReal m v) -
        K * ((gaussianReal m v) (Set.Ioi a)).toReal := by
    have hpt : (fun y => max (Real.exp y - K) 0) =
        Set.indicator (Set.Ioi a) (fun y => Real.exp y - K) := by
      ext y
      by_cases hy : y ∈ Set.Ioi a
      · rw [Set.indicator_of_mem hy]
        have : K < Real.exp y := by
          rw [← Real.exp_log hK]; exact Real.exp_lt_exp.mpr hy
        exact max_eq_left (by linarith)
      · rw [Set.indicator_of_notMem hy]
        have : Real.exp y ≤ K := by
          rw [← Real.exp_log hK]; exact Real.exp_le_exp.mpr (not_lt.mp hy)
        exact max_eq_right (by linarith)
    have hexp : Integrable (fun y => Real.exp y) (gaussianReal m v) := by
      simpa using integrable_exp_mul_gaussianReal (μ := m) (v := v) 1
    rw [hpt, integral_indicator measurableSet_Ioi,
      integral_sub hexp.integrableOn (integrable_const K).integrableOn, setIntegral_const,
      smul_eq_mul, mul_comm, measureReal_def]
  rw [hA, hB, setIntegral_exp_gaussianReal m a v hv]
  have hF : Real.exp (m + v / 2) = F₀ := by
    rw [hvr, hm_def]; ring_nf; exact Real.exp_log hF₀
  rw [hF]
  have hlogdiv : Real.log (F₀ / K) = Real.log F₀ - a := Real.log_div hF₀.ne' hK.ne'
  rw [hvs, gaussian_Ioi_eq_cdf _ _ _ hs, gaussian_Ioi_eq_cdf _ _ _ hs,
    ENNReal.toReal_ofReal (cdf_nonneg _ _), ENNReal.toReal_ofReal (cdf_nonneg _ _)]
  congr 3
  · rw [← hvs, hvr, hlogdiv, hm_def]; ring
  · rw [hlogdiv, hm_def]
    field_simp
    rw [hs2]
    ring

-- The shelf's curve: quarterly forwards 44/1000 + (5/10000) i for quarters i = 0 to 7, each
-- discount factor the previous one divided by 1 + τ F with τ = 1/4.
-- The last quarter's forward is 4.75 percent.
example : (44 / 1000 + 5 / 10000 * 7 : ℚ) = 19 / 400 := by norm_num
-- The payment-date bond is the fixing-date bond divided by 1 + τ F(0) = 1619/1600.
example : (1 + (1 / 4) * (19 / 400) : ℚ) = 1619 / 1600 := by norm_num
-- The forward recovered from the two chained bonds, (P(0,1.75) / P(0,2.00) - 1) / τ, is exactly 19/400.
example :
    ((∏ i ∈ Finset.range 7, (1 + (1 / 4 : ℚ) * (44 / 1000 + 5 / 10000 * i))⁻¹) /
        (∏ i ∈ Finset.range 8, (1 + (1 / 4 : ℚ) * (44 / 1000 + 5 / 10000 * i))⁻¹) - 1) / (1 / 4)
      = 19 / 400 := by
  norm_num [Finset.prod_range_succ]
-- The forward's log variance runs to the fixing date: σ² T₁ = (3/10)² · (7/4) = 63/400.
example : ((3 / 10) ^ 2 * (7 / 4) : ℚ) = 63 / 400 := by norm_num

#print axioms forward_rate_is_martingale_under_forward_measure
#print axioms caplet_price_eq_bond_times_forward_average
#print axioms lognormal_forward_call_average_eq_black
