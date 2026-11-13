-- Girsanov: weighting a Brownian motion's paths by exp(-θ W_T - θ² T / 2) gives a probability measure under which W_t + θ t is a Brownian motion on [0, T].
import Mathlib.Probability.BrownianMotion.Basic
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.MeasureTheory.Measure.WithDensity

open MeasureTheory ProbabilityTheory ProbabilityTheory.BrownianReal
open scoped NNReal ENNReal

lemma gaussianReal_withDensity_tilt (m θ : ℝ) (v : ℝ≥0) :
    (gaussianReal m v).withDensity
        (fun x ↦ ENNReal.ofReal (Real.exp (-θ * (x - m) - θ ^ 2 * v / 2)))
      = gaussianReal (m - θ * v) v := by
  by_cases hv : v = 0
  · subst hv
    ext s hs
    rw [withDensity_apply _ hs]
    classical
    simp only [gaussianReal_zero_var, NNReal.coe_zero, mul_zero, sub_zero, zero_div,
      MeasureTheory.restrict_dirac' hs]
    split_ifs with h <;> simp [h]
  · have hv' : (v : ℝ) ≠ 0 := by exact_mod_cast hv
    rw [gaussianReal_of_var_ne_zero _ hv, gaussianReal_of_var_ne_zero _ hv,
      ← withDensity_mul _ (measurable_gaussianPDF _ _) (by fun_prop)]
    congr 1
    ext x
    simp only [Pi.mul_apply, gaussianPDF, gaussianPDFReal]
    rw [← ENNReal.ofReal_mul (by positivity)]
    congr 1
    rw [mul_assoc, ← Real.exp_add]
    congr 2
    field_simp
    ring

lemma map_withDensity_comp {Ω α : Type*} [MeasurableSpace Ω] [MeasurableSpace α]
    (μ : Measure Ω) {f : Ω → α} (hf : AEMeasurable f μ) {g : α → ℝ≥0∞} (hg : Measurable g) :
    (μ.withDensity (fun ω ↦ g (f ω))).map f = (μ.map f).withDensity g := by
  ext s hs
  rw [Measure.map_apply_of_aemeasurable (hf.mono_ac (withDensity_absolutelyContinuous _ _)) hs,
    withDensity_apply _ hs, withDensity_apply₀ _ (hf.nullMeasurable hs),
    ← lintegral_indicator hs, lintegral_map' ((hg.indicator hs).aemeasurable) hf,
    ← lintegral_indicator₀ (hf.nullMeasurable hs)]
  rfl

lemma tilt_map_eval {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    (W : ℝ≥0 → Ω → ℝ) (hW : IsBrownianReal W P) (θ : ℝ) (T : ℝ≥0) :
    (P.withDensity (fun ω ↦ ENNReal.ofReal (Real.exp (-θ * W T ω - θ ^ 2 * T / 2)))).map (W T)
      = gaussianReal (-θ * T) T := by
  have := map_withDensity_comp P (hW.aemeasurable T)
    (g := fun x ↦ ENNReal.ofReal (Real.exp (-θ * x - θ ^ 2 * T / 2))) (by fun_prop)
  have h0 := gaussianReal_withDensity_tilt 0 θ T
  simp only [sub_zero, zero_sub] at h0
  rw [this, (hW.hasLaw_eval T).map_eq, h0, neg_mul]

#print axioms gaussianReal_withDensity_tilt
#print axioms map_withDensity_comp
#print axioms tilt_map_eval

/-- **Girsanov's theorem, constant tilt (Cameron-Martin).** Let `W` be a Brownian motion under
the probability measure `P`, let `θ` be a constant tilt and `T` a finite horizon. Weight every
path by `Z_T = exp(-θ W_T - θ² T / 2)`, that is, `Q(A) = E[Z_T 1_A]`. Then `Q` is a probability
measure with the same impossible events as `P`, and under `Q` the process `W_t + θ t` is a
Brownian motion for `0 ≤ t ≤ T`: its finite-dimensional laws at times up to `T` are those of
Brownian motion, and its paths are continuous on `[0, T]`. -/
theorem girsanov_constant_tilt_brownian
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (W : ℝ≥0 → Ω → ℝ) (hW : IsBrownianReal W P) (θ : ℝ) (T : ℝ≥0) :
    let Q := P.withDensity (fun ω ↦ ENNReal.ofReal (Real.exp (-θ * W T ω - θ ^ 2 * T / 2)))
    IsProbabilityMeasure Q ∧ Q ≪ P ∧ P ≪ Q ∧
      (∀ I : Finset ℝ≥0, (∀ t ∈ I, t ≤ T) →
        HasLaw (fun ω ↦ I.restrict (fun t ↦ W t ω + θ * t)) (projectiveFamily I) Q) ∧
      ∀ᵐ ω ∂Q, ContinuousOn (fun t ↦ W t ω + θ * t) (Set.Iic T) := by
  intro Q
  have hQP : Q ≪ P := withDensity_absolutelyContinuous _ _
  have hmap : Q.map (W T) = gaussianReal (-θ * T) T := tilt_map_eval P W hW θ T
  have hVQ : AEMeasurable (W T) Q := (hW.aemeasurable T).mono_ac hQP
  have hprob : IsProbabilityMeasure Q := by
    constructor
    have : Q.map (W T) Set.univ = gaussianReal (-θ * T) T Set.univ := by rw [hmap]
    rw [Measure.map_apply_of_aemeasurable hVQ MeasurableSet.univ, Set.preimage_univ] at this
    rw [this, measure_univ]
  refine ⟨hprob, hQP, ?_, ?_, ?_⟩
  · refine withDensity_absolutelyContinuous' ?_ (Filter.Eventually.of_forall fun ω ↦ ?_)
    · exact Measurable.comp_aemeasurable (g := fun x ↦ ENNReal.ofReal
        (Real.exp (-θ * x - θ ^ 2 * T / 2))) (by fun_prop) (hW.aemeasurable T)
    · simp [Real.exp_pos]
  · intro I hI
    let X : I → Ω → ℝ := fun i ω ↦ W i ω - ((i : ℝ) / T) * W T ω
    let Y : Unit → Ω → ℝ := fun _ ω ↦ W T ω
    have mX : ∀ i, AEMeasurable (X i) P :=
      fun i ↦ (hW.aemeasurable i).sub ((hW.aemeasurable T).const_mul _)
    have mY : ∀ u, AEMeasurable (Y u) P := fun _ ↦ hW.aemeasurable T
    have hgauss : IsGaussianProcess (Sum.elim X Y) P := by
      classical
      apply hW.isGaussianProcess.of_isGaussianProcess
      rintro (i | u)
      · exact ⟨{(i : ℝ≥0), T},
          { toFun x := x ⟨i, by simp⟩ - ((i : ℝ) / T) * x ⟨T, by simp⟩
            map_add' x y := by simp; ring
            map_smul' c x := by simp; ring }, by simp [X]⟩
      · exact ⟨{T},
          { toFun x := x ⟨T, by simp⟩
            map_add' x y := by simp
            map_smul' c x := by simp }, by simp [Y]⟩
    have hcov : ∀ i u, cov[X i, Y u; P] = 0 := by
      intro i u
      have hi : (i : ℝ≥0) ≤ T := hI i i.2
      simp only [X, Y]
      rw [covariance_fun_sub_left, covariance_const_mul_left, hW.covariance_eval,
        hW.covariance_eval, min_eq_left hi, min_self]
      · rcases eq_or_ne T 0 with hT | hT
        · have : (i : ℝ≥0) = 0 := le_antisymm (hT ▸ hi) bot_le
          simp [this, hT]
        · have : (T : ℝ) ≠ 0 := by exact_mod_cast hT
          field_simp
          ring
      · exact (hW.isGaussianProcess.hasGaussianLaw_eval _).memLp_two
      · exact (hW.isGaussianProcess.hasGaussianLaw_eval _).memLp_two.const_mul _
      · exact (hW.isGaussianProcess.hasGaussianLaw_eval _).memLp_two
    have hind : IndepFun (fun ω (i : I) ↦ X i ω) (fun ω (u : Unit) ↦ Y u ω) P :=
      hgauss.indepFun_of_covariance_eq_zero mX mY hcov
    let Yv : Ω → (I → ℝ) := fun ω i ↦ X i ω
    have hind2 : IndepFun Yv (fun ω ↦ W T ω + θ * T) P :=
      hind.comp (φ := id) (ψ := fun x : Unit → ℝ ↦ x () + θ * T) measurable_id (by fun_prop)
    have hind3 : IndepFun Yv (W T) P :=
      hind.comp (φ := id) (ψ := fun x : Unit → ℝ ↦ x ()) measurable_id (by fun_prop)
    have mYv : AEMeasurable Yv P := AEMeasurable.of_eval mX
    have hm1 : P.map (fun ω ↦ (Yv ω, W T ω + θ * T)) =
        (P.map Yv).prod (gaussianReal (θ * T) T) := by
      rw [(indepFun_iff_map_prod_eq_prod_map_map mYv ((hW.aemeasurable T).add_const _)).1 hind2]
      congr 1
      simpa using (gaussianReal_add_const (hW.hasLaw_eval T) (θ * T)).map_eq
    have hm2 : P.map (fun ω ↦ (Yv ω, W T ω)) = (P.map Yv).prod (gaussianReal 0 T) := by
      rw [(indepFun_iff_map_prod_eq_prod_map_map mYv (hW.aemeasurable T)).1 hind3,
        (hW.hasLaw_eval T).map_eq]
    let h : ℝ → ℝ≥0∞ := fun x ↦ ENNReal.ofReal (Real.exp (-θ * (x - θ * T) - θ ^ 2 * T / 2))
    have hh : Measurable h := by fun_prop
    have hQ' : Q = P.withDensity (fun ω ↦ (fun p : (I → ℝ) × ℝ ↦ h p.2) (Yv ω, W T ω + θ * T)) := by
      simp only [Q, h]
      congr
      funext ω
      ring_nf
    have hQmap : Q.map (fun ω ↦ (Yv ω, W T ω + θ * T)) = P.map (fun ω ↦ (Yv ω, W T ω)) := by
      rw [hQ', map_withDensity_comp P (mYv.prodMk ((hW.aemeasurable T).add_const _))
        (g := fun p : (I → ℝ) × ℝ ↦ h p.2) (hh.comp measurable_snd), hm1, hm2, ← prod_withDensity_right hh]
      congr 1
      simp only [h]
      rw [gaussianReal_withDensity_tilt, sub_self]
    let F : (I → ℝ) × ℝ → (I → ℝ) := fun p i ↦ p.1 i + ((i : ℝ) / T) * p.2
    have hF : Measurable F := by fun_prop
    have e1 : (fun ω ↦ I.restrict (fun t ↦ W t ω + θ * t)) =
        F ∘ (fun ω ↦ (Yv ω, W T ω + θ * T)) := by
      funext ω i
      have hi : (i : ℝ≥0) ≤ T := hI i i.2
      simp only [Finset.restrict, Function.comp, F, Yv, X]
      rcases eq_or_ne T 0 with hT | hT
      · have : (i : ℝ≥0) = 0 := le_antisymm (hT ▸ hi) bot_le
        simp [this, hT]
      · have : (T : ℝ) ≠ 0 := by exact_mod_cast hT
        field_simp
        ring
    have e2 : (fun ω ↦ I.restrict (W · ω)) = F ∘ (fun ω ↦ (Yv ω, W T ω)) := by
      funext ω i
      simp [F, Yv, X]
    have hP := hW.hasLaw I
    rw [e2] at hP
    have mQ : AEMeasurable (fun ω ↦ (Yv ω, W T ω + θ * T)) Q :=
      (mYv.prodMk ((hW.aemeasurable T).add_const _)).mono_ac hQP
    rw [e1]
    refine ⟨hF.comp_aemeasurable mQ, ?_⟩
    rw [← AEMeasurable.map_map_of_aemeasurable hF.aemeasurable mQ, hQmap,
      AEMeasurable.map_map_of_aemeasurable hF.aemeasurable (mYv.prodMk (hW.aemeasurable T))]
    exact hP.map_eq
  · filter_upwards [hQP.ae_le hW.cont] with ω hc
    exact (hc.add (continuous_const.mul NNReal.continuous_coe)).continuousOn

/-- **The weight slides the bell curve (Step 2).** Multiplying the bell curve with mean 0 and
variance `v` by the weight `exp(-θ x - θ² v / 2)` gives the bell curve with the same variance
`v`, slid to mean `-θ v`. -/
theorem gaussian_weighted_is_shifted (θ : ℝ) (v : ℝ≥0) :
    (gaussianReal 0 v).withDensity (fun x ↦ ENNReal.ofReal (Real.exp (-θ * x - θ ^ 2 * v / 2)))
      = gaussianReal (-θ * v) v := by
  have := gaussianReal_withDensity_tilt 0 θ v
  simp only [sub_zero, zero_sub] at this
  rw [this, neg_mul]


/-- **The discounted share is a fair game under `Q`.** A share with price
`S_T = S₀ exp((μ - σ²/2) T + σ W_T)` (drift `μ`, kick size `σ ≠ 0`), weighted by
`Z_T = exp(-θ W_T - θ² T / 2)` with tilt `θ = (μ - r) / σ`, has discounted average
`E^Q[e^(-r T) S_T] = S₀`: under the new odds it grows at the bank's rate `r`. -/
theorem girsanov_discounted_share_fair
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (W : ℝ≥0 → Ω → ℝ) (hW : IsBrownianReal W P) (S₀ μ r σ : ℝ) (hσ : σ ≠ 0) (T : ℝ≥0) :
    let θ := (μ - r) / σ
    let Q := P.withDensity (fun ω ↦ ENNReal.ofReal (Real.exp (-θ * W T ω - θ ^ 2 * T / 2)))
    ∫ ω, Real.exp (-r * T) * (S₀ * Real.exp ((μ - σ ^ 2 / 2) * T + σ * W T ω)) ∂Q = S₀ := by
  intro θ Q
  have hQP : Q ≪ P := withDensity_absolutelyContinuous _ _
  have hmap : Q.map (W T) = gaussianReal (-θ * T) T := tilt_map_eval P W hW θ T
  have hVQ : AEMeasurable (W T) Q := (hW.aemeasurable T).mono_ac hQP
  rw [← integral_map (f := fun x ↦ Real.exp (-r * T) * (S₀ * Real.exp ((μ - σ ^ 2 / 2) * T + σ * x)))
    hVQ (by fun_prop), hmap]
  have hm := congrFun (mgf_id_gaussianReal (μ := -θ * T) (v := T)) σ
  simp only [mgf, id] at hm
  simp_rw [Real.exp_add, ← mul_assoc]
  rw [integral_const_mul, hm, mul_assoc, mul_assoc, ← Real.exp_add, mul_left_comm,
    ← Real.exp_add]
  conv_rhs => rw [← mul_one S₀]
  congr 1
  rw [← Real.exp_zero]
  congr 1
  simp only [θ]
  field_simp
  ring

-- The card's worked numbers, as exact fractions: μ = 0.08, r = 0.05, σ = 0.20, T = 1.
-- Tilt θ = (μ - r) / σ = 0.15.
example : ((8 : ℚ) / 100 - 5 / 100) / (20 / 100) = 15 / 100 := by norm_num
-- Correction θ² T / 2 = 0.01125.
example : ((15 : ℚ) / 100) ^ 2 * 1 / 2 = 1125 / 100000 := by norm_num
-- Log drift under P: μ - σ²/2 = 0.06.
example : (8 : ℚ) / 100 - (20 / 100) ^ 2 / 2 = 6 / 100 := by norm_num
-- Log drift under Q: 0.06 - σ θ = 0.03, which is r - σ²/2.
example : (6 : ℚ) / 100 - 20 / 100 * (15 / 100) = 3 / 100 := by norm_num
example : (5 : ℚ) / 100 - (20 / 100) ^ 2 / 2 = 3 / 100 := by norm_num
-- Wrong sign on the tilt: drift μ + σ θ = 0.11.
example : (8 : ℚ) / 100 + 20 / 100 * (15 / 100) = 11 / 100 := by norm_num

#print axioms girsanov_constant_tilt_brownian
#print axioms gaussian_weighted_is_shifted
#print axioms girsanov_discounted_share_fair
