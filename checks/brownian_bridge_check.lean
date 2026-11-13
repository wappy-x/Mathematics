-- Brownian bridge: given a Brownian motion's recorded values, its position at a time inside a gap between two neighbouring record times is normal, with mean on the straight line between the two neighbouring values and variance (time since the left pin)(time to the right pin)/(gap), and no other recorded value matters.
import Mathlib.Probability.BrownianMotion.Basic
import Mathlib.Probability.Kernel.CondDistrib
import Mathlib.Probability.Moments.Covariance
import Mathlib.Probability.Independence.Basic
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory
open scoped NNReal

/-! Mathlib's `IsBrownianReal W P` says that `W : ℝ≥0 → Ω → ℝ` is a Brownian motion under `P`:
it starts at 0, its steps over separate stretches are independent, the step over a stretch of
length `h` is normal with mean 0 and variance `h`, and its paths are continuous almost surely.
`condDistrib Y X P x` is the law of `Y` given `X = x` (defined for almost every value `x` of `X`),
and `gaussianReal m v` is the normal law with mean `m` and variance `v`.
The instance `[IsProbabilityMeasure P]` is needed only to write `condDistrib`; it already follows
from `IsBrownianReal W P`, so it adds no assumption. -/

/-- If `Z` is independent of `X`, then given `X = x`, the law of `f X + Z` is the law of `Z`
shifted by `f x`. -/
lemma condDistrib_add_of_indepFun {Ω β : Type*} [MeasurableSpace Ω] [MeasurableSpace β]
    {μ : Measure Ω} [IsProbabilityMeasure μ] {X : Ω → β} {Z : Ω → ℝ}
    (hX : AEMeasurable X μ) (hZ : AEMeasurable Z μ) (hXZ : IndepFun X Z μ)
    {f : β → ℝ} (hf : Measurable f) :
    ∀ᵐ x ∂(μ.map X), condDistrib (fun ω => f (X ω) + Z ω) X μ x =
      (μ.map Z).map (fun z => f x + z) := by
  set ν := μ.map Z with hν
  let κ : Kernel β ℝ :=
    ((Kernel.deterministic f hf) ×ₖ (Kernel.const β ν)).map (fun p => p.1 + p.2)
  have hκ : ∀ x, κ x = ν.map (fun z => f x + z) := by
    intro x
    simp only [κ]
    rw [Kernel.map_apply _ (by fun_prop), Kernel.prod_apply, Kernel.deterministic_apply,
      Kernel.const_apply, Measure.dirac_prod, Measure.map_map (by fun_prop) (by fun_prop)]
    rfl
  have hg : Measurable (fun p : β × ℝ => (p.1, f p.1 + p.2)) := by fun_prop
  have hmeas : μ.map (fun ω => (X ω, f (X ω) + Z ω)) = μ.map X ⊗ₘ κ := by
    have h1 : μ.map (fun ω => (X ω, f (X ω) + Z ω)) =
        (μ.map (fun ω => (X ω, Z ω))).map (fun p : β × ℝ => (p.1, f p.1 + p.2)) := by
      rw [AEMeasurable.map_map_of_aemeasurable hg.aemeasurable (hX.prodMk hZ)]
      rfl
    rw [h1, (indepFun_iff_map_prod_eq_prod_map_map hX hZ).1 hXZ]
    ext s hs
    rw [Measure.map_apply hg hs, Measure.prod_apply (hg hs), Measure.compProd_apply hs]
    refine lintegral_congr fun x => ?_
    rw [hκ x, Measure.map_apply (by fun_prop) (measurable_prodMk_left hs)]
    rfl
  filter_upwards [condDistrib_ae_eq_of_measure_eq_compProd (κ := κ)
    (Y := fun ω => f (X ω) + Z ω) hX
    ((hf.comp_aemeasurable hX).add hZ) hmeas] with x hx
  rw [hx, hκ x]

#print axioms condDistrib_add_of_indepFun

/-- The card's main claim. Record a Brownian motion at a finite set `I` of fixed times, and take
two neighbouring record times `t₁ < t₂` (no record time strictly between them). Given the whole
record, the position at a time `t` with `t₁ ≤ t ≤ t₂` is normal, with mean on the straight line
from the value at `t₁` to the value at `t₂`, `a + (t - t₁)/(t₂ - t₁) (b - a)`, and variance
`(t - t₁)(t₂ - t)/(t₂ - t₁)`. Only the two neighbouring values appear: the rest of the record
has no say. With `I = {t₁, t₂}` this is the card's two-pin formula. -/
theorem brownian_bridge_conditional_law {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P)
    (I : Finset ℝ≥0) {t₁ t₂ t : ℝ≥0} (h₁ : t₁ ∈ I) (h₂ : t₂ ∈ I) (h12 : t₁ < t₂)
    (hgap : ∀ s ∈ I, ¬ (t₁ < s ∧ s < t₂)) (ht₁ : t₁ ≤ t) (ht₂ : t ≤ t₂) :
    ∀ᵐ x ∂(P.map fun ω => I.restrict (W · ω)),
      condDistrib (W t) (fun ω => I.restrict (W · ω)) P x =
        gaussianReal
          (x ⟨t₁, h₁⟩ + ((t : ℝ) - t₁) / ((t₂ : ℝ) - t₁) * (x ⟨t₂, h₂⟩ - x ⟨t₁, h₁⟩))
          ((t - t₁) * (t₂ - t) / (t₂ - t₁)) := by
  classical
  have hL : ∀ u, MemLp (W u) 2 P := fun u => (hW.isGaussianProcess.hasGaussianLaw_eval u).memLp_two
  have hm : ∀ u, AEMeasurable (W u) P := fun u => hW.aemeasurable u
  have hd : (t₂ : ℝ) - t₁ ≠ 0 := by
    have : (t₁ : ℝ) < t₂ := h12
    linarith
  set c : ℝ := ((t : ℝ) - t₁) / ((t₂ : ℝ) - t₁) with hc
  let X : Ω → (I → ℝ) := fun ω => I.restrict (W · ω)
  let f : (I → ℝ) → ℝ := fun x => x ⟨t₁, h₁⟩ + c * (x ⟨t₂, h₂⟩ - x ⟨t₁, h₁⟩)
  have hf : Measurable f := by fun_prop
  let Z : Ω → ℝ := W t - W t₁ - c • (W t₂ - W t₁)
  have hZL : MemLp Z 2 P := ((hL t).sub (hL t₁)).sub (((hL t₂).sub (hL t₁)).const_smul c)
  have hWt : W t = fun ω => f (X ω) + Z ω := by
    funext ω
    simp only [f, X, Z, Finset.restrict, Pi.sub_apply, Pi.smul_apply, smul_eq_mul]
    ring
  -- covariance of `Z` with the path
  have hcov : ∀ s, cov[W s, Z; P] = ((min s t : ℝ≥0) : ℝ) - ((min s t₁ : ℝ≥0) : ℝ)
      - c * (((min s t₂ : ℝ≥0) : ℝ) - ((min s t₁ : ℝ≥0) : ℝ)) := by
    intro s
    simp only [Z]
    rw [covariance_sub_right (hL s) ((hL t).sub (hL t₁)) (((hL t₂).sub (hL t₁)).const_smul c),
      covariance_sub_right (hL s) (hL t) (hL t₁), covariance_smul_right,
      covariance_sub_right (hL s) (hL t₂) (hL t₁)]
    simp only [hW.covariance_eval]
  have hcovI : ∀ s ∈ I, cov[W s, Z; P] = 0 := by
    intro s hs
    rw [hcov s]
    rcases le_or_gt s t₁ with h | h
    · rw [min_eq_left (h.trans ht₁), min_eq_left h, min_eq_left (h.trans h12.le)]
      ring
    · have h' : t₂ ≤ s := by
        by_contra h''
        exact hgap s hs ⟨h, lt_of_not_ge h''⟩
      rw [min_eq_right (ht₂.trans h'), min_eq_right h.le, min_eq_right h']
      rw [hc]
      field_simp
      ring
  -- `Z` is independent of the record
  have hG : IsGaussianProcess (Sum.elim (fun i : I => W i) (fun _ : Unit => Z)) P := by
    apply hW.isGaussianProcess.of_isGaussianProcess
    rintro (i | u)
    · exact ⟨{(i : ℝ≥0)},
        { toFun x := x ⟨i, by simp⟩
          map_add' x y := by simp
          map_smul' c x := by simp }, by simp⟩
    · exact ⟨{t, t₁, t₂},
        { toFun x := x ⟨t, by simp⟩ - x ⟨t₁, by simp⟩ - c * (x ⟨t₂, by simp⟩ - x ⟨t₁, by simp⟩)
          map_add' x y := by simp; ring
          map_smul' a x := by simp; ring }, by simp [Z]⟩
  have hind : IndepFun X Z P := by
    have h := hG.indepFun_of_covariance_eq_zero (X := fun i : I => W i) (Y := fun _ : Unit => Z)
      (fun i => hm i) (fun _ => hZL.aestronglyMeasurable.aemeasurable)
      (fun i _ => hcovI i i.2)
    exact h.comp measurable_id (measurable_pi_apply ())
  -- the law of `Z`
  have hZG : HasGaussianLaw Z P := hG.hasGaussianLaw_eval (Sum.inr ())
  have hmean : P[Z] = 0 := by
    simp only [Z, Pi.sub_apply, Pi.smul_apply, smul_eq_mul]
    rw [integral_sub, integral_sub, integral_const_mul, integral_sub, hW.integral_eval,
      hW.integral_eval, hW.integral_eval]
    · simp
    all_goals first
      | exact hW.integrable_eval _
      | exact (hW.integrable_eval _).sub (hW.integrable_eval _)
      | exact ((hW.integrable_eval _).sub (hW.integrable_eval _)).const_mul c
  have hvar : Var[Z; P] = ((t : ℝ) - t₁) * ((t₂ : ℝ) - t) / ((t₂ : ℝ) - t₁) := by
    rw [← covariance_self hZL.aestronglyMeasurable.aemeasurable]
    conv_lhs => enter [1]; simp only [Z]
    rw [covariance_sub_left ((hL t).sub (hL t₁)) (((hL t₂).sub (hL t₁)).const_smul c) hZL,
      covariance_sub_left (hL t) (hL t₁) hZL, covariance_smul_left,
      covariance_sub_left (hL t₂) (hL t₁) hZL, hcovI t₁ h₁, hcovI t₂ h₂, hcov t,
      min_self, min_eq_right ht₁, min_eq_left ht₂]
    rw [hc]
    field_simp
    ring
  have hlaw : P.map Z = gaussianReal 0 ((t - t₁) * (t₂ - t) / (t₂ - t₁)) := by
    rw [hZG.map_eq_gaussianReal, hmean, hvar]
    congr 1
    apply NNReal.coe_injective
    rw [Real.coe_toNNReal _ (by
      apply div_nonneg
      · apply mul_nonneg
        · have : (t₁ : ℝ) ≤ t := ht₁
          linarith
        · have : (t : ℝ) ≤ t₂ := ht₂
          linarith
      · have : (t₁ : ℝ) < t₂ := h12
        linarith)]
    push_cast [ht₁, ht₂, h12.le]
    rfl
  have hX : AEMeasurable X P := AEMeasurable.of_eval fun i => hm i
  filter_upwards [condDistrib_add_of_indepFun hX hZL.aestronglyMeasurable.aemeasurable hind hf]
    with x hx
  have : condDistrib (W t) X P = condDistrib (fun ω => f (X ω) + Z ω) X P := by rw [← hWt]
  simp only [X] at this hx
  rw [this, hx, hlaw, gaussianReal_map_const_add, zero_add]

/-- The bridge as a process (the card's Step 3). Pin the path at `b` at time `T > 0` by setting
`B_t = W_t - (t/T) W_T + (t/T) b`. For times `s ≤ t ≤ T` its covariance is
`Cov(B_s, B_t) = s (T - t)/T`; with `s = t` this is the variance `t (T - t)/T`. -/
theorem brownian_bridge_covariance {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P) {T s t : ℝ≥0} (hT : 0 < T)
    (hst : s ≤ t) (htT : t ≤ T) (b : ℝ) :
    cov[fun ω => W s ω - (s : ℝ) / T * W T ω + (s : ℝ) / T * b,
        fun ω => W t ω - (t : ℝ) / T * W T ω + (t : ℝ) / T * b; P]
      = (s : ℝ) * ((T : ℝ) - t) / T := by
  have hP := hW.isGaussianProcess.isProbabilityMeasure
  have hL : ∀ u, MemLp (W u) 2 P := fun u => (hW.isGaussianProcess.hasGaussianLaw_eval u).memLp_two
  have hI : ∀ u, Integrable (W u) P := fun u => hW.integrable_eval u
  rw [covariance_add_const_left (X := fun ω => W s ω - (s : ℝ) / T * W T ω)
      ((hI s).sub ((hI T).const_mul _)),
    covariance_add_const_right (Y := fun ω => W t ω - (t : ℝ) / T * W T ω)
      ((hI t).sub ((hI T).const_mul _)),
    covariance_fun_sub_left (X := W s) (Y := fun ω => (s : ℝ) / T * W T ω)
      (Z := fun ω => W t ω - (t : ℝ) / T * W T ω)
      (hL s) ((hL T).const_mul _) (((hL t).sub ((hL T).const_mul _))),
    covariance_fun_sub_right (X := W s) (Y := W t) (Z := fun ω => (t : ℝ) / T * W T ω)
      (hL s) (hL t) ((hL T).const_mul _),
    covariance_fun_sub_right (X := fun ω => (s : ℝ) / T * W T ω) (Y := W t)
      (Z := fun ω => (t : ℝ) / T * W T ω) ((hL T).const_mul _) (hL t) ((hL T).const_mul _),
    covariance_const_mul_left, covariance_const_mul_left, covariance_const_mul_right,
    covariance_const_mul_right]
  simp only [hW.covariance_eval, min_eq_left hst, min_eq_left (hst.trans htT), min_eq_right htT,
    min_self]
  have hT' : (T : ℝ) ≠ 0 := by positivity
  field_simp
  ring

/-- The fact that makes everything work (the card's Step 0). The wiggle, the free path minus the
straight line through its own end, `t ↦ W_t - (t/T) W_T` on `[0, T]`, is independent of where the
path ends, `W_T`. -/
theorem brownian_wiggle_indep_end {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P) {T : ℝ≥0} (hT : 0 < T) :
    IndepFun (fun ω => fun t : Set.Icc (0 : ℝ≥0) T => W t ω - (t : ℝ) / T * W T ω) (W T) P := by
  classical
  have hP := hW.isGaussianProcess.isProbabilityMeasure
  have hL : ∀ u, MemLp (W u) 2 P := fun u => (hW.isGaussianProcess.hasGaussianLaw_eval u).memLp_two
  have hm : ∀ u, AEMeasurable (W u) P := fun u => hW.aemeasurable u
  let X : Set.Icc (0 : ℝ≥0) T → Ω → ℝ := fun u ω => W u ω - (u : ℝ) / T * W T ω
  let Y : Unit → Ω → ℝ := fun _ => W T
  have hG : IsGaussianProcess (Sum.elim X Y) P := by
    apply hW.isGaussianProcess.of_isGaussianProcess
    rintro (u | u)
    · exact ⟨{(u : ℝ≥0), T},
        { toFun x := x ⟨u, by simp⟩ - (u : ℝ) / T * x ⟨T, by simp⟩
          map_add' x y := by simp; ring
          map_smul' c x := by simp; ring }, by simp [X]⟩
    · exact ⟨{T},
        { toFun x := x ⟨T, by simp⟩
          map_add' x y := by simp
          map_smul' c x := by simp }, by simp [Y]⟩
  have h := hG.indepFun_of_covariance_eq_zero (X := X) (Y := Y)
    (fun u => (hm u).sub ((hm T).const_mul _)) (fun _ => hm T) (by
      rintro ⟨u, hu0, huT⟩ -
      simp only [X, Y]
      rw [covariance_fun_sub_left (X := W u) (Y := fun ω => (u : ℝ) / T * W T ω) (Z := W T)
        (hL u) ((hL T).const_mul _) (hL T), covariance_const_mul_left]
      simp only [hW.covariance_eval, min_eq_left huT, min_self]
      have hT' : (T : ℝ) ≠ 0 := by positivity
      field_simp
      ring)
  exact h.comp measurable_id (measurable_pi_apply ())

/-! The card's exact worked numbers, as fractions: pinned at 0 at time 0 and at 2 at 10 seconds,
and the half-second fill-in between 1.3 at 4 seconds and 0.5 at 5 seconds. -/

-- Mean at 4 seconds: (4/10) × 2 = 0.8.
example : (4 : ℚ) / 10 * 2 = 4 / 5 := by norm_num

-- Variance at 4 seconds: 4 − 4^2/10 = 4 × 6/10 = 2.4.
example : (4 : ℚ) - 4 ^ 2 / 10 = 12 / 5 ∧ (4 : ℚ) * (10 - 4) / 10 = 12 / 5 := by norm_num

-- Peak variance in the middle, at 5 seconds: 5 × 5/10 = T/4 = 2.5.
example : (5 : ℚ) * (10 - 5) / 10 = 10 / 4 ∧ (10 : ℚ) / 4 = 5 / 2 := by norm_num

-- Cov(B_3, B_7) = 3 × (10 − 7)/10 = 0.9.
example : (3 : ℚ) * (10 - 7) / 10 = 9 / 10 := by norm_num

-- Half-second fill-in: mean 1.3 + 0.5 × (0.5 − 1.3) = 0.9, variance (0.5 × 0.5)/1 = 0.25, spread 0.5.
example : (13 : ℚ) / 10 + (9 / 2 - 4) / (5 - 4) * (1 / 2 - 13 / 10) = 9 / 10 := by norm_num
example : ((9 : ℚ) / 2 - 4) * (5 - 9 / 2) / (5 - 4) = 1 / 4 ∧ ((1 : ℚ) / 2) ^ 2 = 1 / 4 := by
  norm_num

-- Spread rate σ² = 4: the variance at 4 seconds becomes 4 × 2.4 = 9.6.
example : (4 : ℚ) * (12 / 5) = 48 / 5 := by norm_num

-- Coin-flip walk, 10 steps: pinned variance 2.4 + 2.4 × 0.6/(10 − 1) = 2.56, error 0.16.
example : (12 : ℚ) / 5 + 12 / 5 * (3 / 5) / (10 - 1) = 64 / 25 ∧
    (64 : ℚ) / 25 - 12 / 5 = 4 / 25 := by norm_num

-- The variance at 4 seconds in the main theorem's ℝ≥0 form: (4 − 0)(10 − 4)/(10 − 0) = 2.4.
example : ((4 : ℝ≥0) - 0) * (10 - 4) / (10 - 0) = 12 / 5 := by
  rw [← NNReal.coe_inj]; push_cast [show (4 : ℝ≥0) ≤ 10 by norm_num]; norm_num

#print axioms brownian_bridge_conditional_law
#print axioms brownian_bridge_covariance
#print axioms brownian_wiggle_indep_end
