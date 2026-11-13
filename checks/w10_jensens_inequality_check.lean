-- Jensen's inequality: on a probability space a convex function of the integral is at most the integral of the convex function, equality for a strictly convex function forces the function to be constant almost surely, and p-norms rise with p.
import Mathlib.Analysis.Convex.Integral
import Mathlib.MeasureTheory.Function.LpSeminorm.CompareExp
import Mathlib.Data.EReal.Operations
import Mathlib.Analysis.Convex.Continuous
import Mathlib.Analysis.Convex.Deriv

open MeasureTheory
open scoped ENNReal

variable {Ω : Type*} [MeasurableSpace Ω]

lemma jensen_aux_not_interior {I : Set ℝ} (hI : I.OrdConnected) {x : ℝ} (_hx : x ∈ I)
    (hxi : x ∉ interior I) : (∀ y ∈ I, x ≤ y) ∨ (∀ y ∈ I, y ≤ x) := by
  by_contra h
  push Not at h
  obtain ⟨⟨y, hyI, hy⟩, ⟨z, hzI, hz⟩⟩ := h
  exact hxi (mem_interior_iff_mem_nhds.2 (Filter.mem_of_superset (Ioo_mem_nhds hy hz)
    (Set.Ioo_subset_Icc_self.trans (hI.out hyI hzI))))

lemma jensen_aux_countable {I : Set ℝ} (hI : I.OrdConnected) : (I \ interior I).Countable := by
  have h1 : ({x | x ∈ I ∧ ∀ y ∈ I, x ≤ y} : Set ℝ).Subsingleton := by
    intro a ha b hb
    exact le_antisymm (ha.2 b hb.1) (hb.2 a ha.1)
  have h2 : ({x | x ∈ I ∧ ∀ y ∈ I, y ≤ x} : Set ℝ).Subsingleton := by
    intro a ha b hb
    exact le_antisymm (hb.2 a ha.1) (ha.2 b hb.1)
  refine (h1.countable.union h2.countable).mono ?_
  rintro x ⟨hx, hxi⟩
  rcases jensen_aux_not_interior hI hx hxi with h | h
  · exact Or.inl ⟨hx, h⟩
  · exact Or.inr ⟨hx, h⟩

lemma jensen_aux_measurable {I : Set ℝ} (hI : I.OrdConnected) {φ : ℝ → ℝ}
    (hφ : ConvexOn ℝ I φ) : Measurable (I.indicator φ) := by
  refine measurable_of_restrict_of_restrict_compl (isOpen_interior (s := I)).measurableSet ?_ ?_
  · have hc : ContinuousOn (I.indicator φ) (interior I) := by
      refine hφ.continuousOn_interior.congr ?_
      intro x hx
      exact Set.indicator_of_mem (interior_subset hx) φ
    exact (continuousOn_iff_continuous_domRestrict.1 hc).measurable
  · have hE : Measurable ((I \ interior I).indicator φ) := by
      refine measurable_of_measurable_on_compl_countable _ (jensen_aux_countable hI) ?_
      have : (I \ interior I)ᶜ.domRestrict ((I \ interior I).indicator φ) = fun _ => 0 := by
        funext x
        exact Set.indicator_of_notMem x.2 φ
      rw [this]
      exact measurable_const
    have : (interior I)ᶜ.domRestrict (I.indicator φ) =
        (fun x : ↥((interior I)ᶜ) => (I \ interior I).indicator φ x) := by
      funext x
      by_cases hx : (x : ℝ) ∈ I
      · simp [Set.indicator_of_mem hx, Set.indicator_of_mem (show (x : ℝ) ∈ I \ interior I
          from ⟨hx, x.2⟩)]
      · simp [Set.indicator_of_notMem hx, Set.indicator_of_notMem
          (show (x : ℝ) ∉ I \ interior I from fun h => hx h.1)]
    rw [this]
    exact hE.comp measurable_subtype_coe

lemma jensen_aux_lt_integral (P : Measure Ω) [IsProbabilityMeasure P] {g : Ω → ℝ}
    (hg : Integrable g P) (a : ℝ) (h : ∀ ω, a < g ω) : a < ∫ ω, g ω ∂P := by
  have hsupp : Function.support (fun ω => g ω - a) = Set.univ :=
    Set.eq_univ_of_forall fun ω => (sub_pos.2 (h ω)).ne'
  have hpos : 0 < ∫ ω, (g ω - a) ∂P := by
    rw [integral_pos_iff_support_of_nonneg (fun ω => (sub_pos.2 (h ω)).le)
      (hg.sub (integrable_const a)), hsupp, measure_univ]
    exact one_pos
  rw [integral_sub hg (integrable_const a), integral_const] at hpos
  simp at hpos
  linarith

lemma jensen_aux_mean_mem (P : Measure Ω) [IsProbabilityMeasure P]
    {I : Set ℝ} (hI : I.OrdConnected) {f : Ω → ℝ} (hf : Integrable f P) (hfI : ∀ ω, f ω ∈ I) :
    ∫ ω, f ω ∂P ∈ I := by
  obtain ⟨y, hyI, hy⟩ : ∃ y ∈ I, y ≤ ∫ ω, f ω ∂P := by
    by_contra h
    push Not at h
    exact lt_irrefl _ (jensen_aux_lt_integral P hf _ fun ω => h _ (hfI ω))
  obtain ⟨z, hzI, hz⟩ : ∃ z ∈ I, ∫ ω, f ω ∂P ≤ z := by
    by_contra h
    push Not at h
    have := jensen_aux_lt_integral P hf.neg (-∫ ω, f ω ∂P) fun ω => neg_lt_neg (h _ (hfI ω))
    simp only [Pi.neg_apply, integral_neg] at this
    exact lt_irrefl _ this
  exact hI.out hyI hzI ⟨hy, hz⟩

lemma jensen_aux_ae_eq_of_not_interior (P : Measure Ω) [IsProbabilityMeasure P]
    {I : Set ℝ} (hI : I.OrdConnected) {f : Ω → ℝ} (hf : Integrable f P) (hfI : ∀ ω, f ω ∈ I)
    (hmi : ∫ ω, f ω ∂P ∉ interior I) : f =ᵐ[P] fun _ => ∫ ω, f ω ∂P := by
  set m := ∫ ω, f ω ∂P with hm_def
  have hm : m ∈ I := jensen_aux_mean_mem P hI hf hfI
  have hint : ∫ ω, (f ω - m) ∂P = 0 := by
    rw [integral_sub hf (integrable_const m), integral_const]
    simp [← hm_def]
  rcases jensen_aux_not_interior hI hm hmi with h | h
  · have h0 : 0 ≤ fun ω => f ω - m := fun ω => sub_nonneg.2 (h _ (hfI ω))
    have := (integral_eq_zero_iff_of_nonneg h0 (hf.sub (integrable_const m))).1 hint
    filter_upwards [this] with ω hω
    simp only [Pi.zero_apply, sub_eq_zero] at hω
    exact hω
  · have h0 : 0 ≤ fun ω => m - f ω := fun ω => sub_nonneg.2 (h _ (hfI ω))
    have hint' : ∫ ω, (m - f ω) ∂P = 0 := by
      rw [integral_sub (integrable_const m) hf, integral_const]
      simp [← hm_def]
    have := (integral_eq_zero_iff_of_nonneg h0 ((integrable_const m).sub hf)).1 hint'
    filter_upwards [this] with ω hω
    simp only [Pi.zero_apply, sub_eq_zero] at hω
    exact hω.symm

lemma jensen_aux_support_line {I : Set ℝ} {φ : ℝ → ℝ} (hφ : ConvexOn ℝ I φ) {m : ℝ}
    (hm : m ∈ interior I) : ∃ c : ℝ, ∀ x ∈ I, φ m + c * (x - m) ≤ φ x := by
  refine ⟨derivWithin φ (Set.Ioi m) m, fun x hx => ?_⟩
  rcases lt_trichotomy x m with hxm | rfl | hxm
  · have h1 := hφ.slope_le_leftDeriv_of_mem_interior hx hm hxm
    have h2 := hφ.leftDeriv_le_rightDeriv_of_mem_interior hm
    rw [slope_def_field, div_le_iff₀ (sub_pos.2 hxm)] at h1
    have h3 : φ m - φ x ≤ derivWithin φ (Set.Ioi m) m * (m - x) :=
      h1.trans (mul_le_mul_of_nonneg_right h2 (sub_pos.2 hxm).le)
    nlinarith
  · simp
  · have h1 := hφ.rightDeriv_le_slope_of_mem_interior hm hx hxm
    rw [slope_def_field, le_div_iff₀ (sub_pos.2 hxm)] at h1
    linarith

lemma jensen_aux_integral_affine (P : Measure Ω) [IsProbabilityMeasure P] {f : Ω → ℝ}
    (hf : Integrable f P) (a c : ℝ) :
    ∫ ω, (a + c * (f ω - ∫ ω, f ω ∂P)) ∂P = a := by
  have h1 : Integrable (fun ω => c * (f ω - ∫ ω, f ω ∂P)) P :=
    (hf.sub (integrable_const _)).const_mul c
  rw [integral_add (integrable_const a) h1, integral_const_mul,
    integral_sub hf (integrable_const _)]
  simp

lemma jensen_aux_exists_ae_line (P : Measure Ω) [IsProbabilityMeasure P]
    {I : Set ℝ} (hI : I.OrdConnected) {φ : ℝ → ℝ} (hφ : ConvexOn ℝ I φ)
    {f : Ω → ℝ} (hf : Integrable f P) (hfI : ∀ ω, f ω ∈ I) :
    ∃ c : ℝ, ∀ᵐ ω ∂P, φ (∫ ω, f ω ∂P) + c * (f ω - ∫ ω, f ω ∂P) ≤ φ (f ω) := by
  by_cases hmi : ∫ ω, f ω ∂P ∈ interior I
  · obtain ⟨c, hc⟩ := jensen_aux_support_line hφ hmi
    exact ⟨c, Filter.Eventually.of_forall fun ω => hc _ (hfI ω)⟩
  · refine ⟨0, ?_⟩
    filter_upwards [jensen_aux_ae_eq_of_not_interior P hI hf hfI hmi] with ω hω
    rw [hω]
    simp

/-- Jensen's inequality. Let P be a probability measure, I an interval, φ convex on I, and f
an integrable function (f in L¹(P)) with every value in I. Then φ ∘ f is measurable, the
negative part of φ ∘ f has finite integral, so the integral of φ ∘ f exists as a number or
+∞, and φ(∫ f dP) ≤ ∫ φ ∘ f dP. The integral of φ ∘ f is written as the integral of its
positive part minus the integral of its negative part, in the extended reals, so the
case ∫ φ ∘ f dP = +∞ is covered. -/
theorem convex_of_integral_le_integral_of_convex (P : Measure Ω) [IsProbabilityMeasure P]
    (I : Set ℝ) (hI : I.OrdConnected) (φ : ℝ → ℝ) (hφ : ConvexOn ℝ I φ)
    (f : Ω → ℝ) (hf : Integrable f P) (hfI : ∀ ω, f ω ∈ I) :
    AEStronglyMeasurable (fun ω => φ (f ω)) P ∧
      (∫⁻ ω, ENNReal.ofReal (-φ (f ω)) ∂P) < ∞ ∧
      ((φ (∫ ω, f ω ∂P) : ℝ) : EReal) ≤
        ((∫⁻ ω, ENNReal.ofReal (φ (f ω)) ∂P : ℝ≥0∞) : EReal) -
          ((∫⁻ ω, ENNReal.ofReal (-φ (f ω)) ∂P : ℝ≥0∞) : EReal) := by
  set m := ∫ ω, f ω ∂P with hm_def
  obtain ⟨c, hc⟩ := jensen_aux_exists_ae_line P hI hφ hf hfI
  have hLi : Integrable (fun ω => φ m + c * (f ω - m)) P :=
    (integrable_const _).add ((hf.sub (integrable_const _)).const_mul c)
  have hLint : ∫ ω, (φ m + c * (f ω - m)) ∂P = φ m := jensen_aux_integral_affine P hf _ _
  have hmeas : AEStronglyMeasurable (fun ω => φ (f ω)) P := by
    have h := ((jensen_aux_measurable hI hφ).comp_aemeasurable
      hf.aemeasurable).aestronglyMeasurable
    have heq : (I.indicator φ ∘ f) = fun ω => φ (f ω) := by
      funext ω
      exact Set.indicator_of_mem (hfI ω) φ
    rwa [heq] at h
  have hneg_le : ∫⁻ ω, ENNReal.ofReal (-φ (f ω)) ∂P ≤
      ∫⁻ ω, ENNReal.ofReal (-(φ m + c * (f ω - m))) ∂P := by
    apply lintegral_mono_ae
    filter_upwards [hc] with ω hω
    exact ENNReal.ofReal_le_ofReal (neg_le_neg hω)
  have hpos_le : ∫⁻ ω, ENNReal.ofReal (φ m + c * (f ω - m)) ∂P ≤
      ∫⁻ ω, ENNReal.ofReal (φ (f ω)) ∂P := by
    apply lintegral_mono_ae
    filter_upwards [hc] with ω hω
    exact ENNReal.ofReal_le_ofReal hω
  have hLneg_fin : ∫⁻ ω, ENNReal.ofReal (-(φ m + c * (f ω - m))) ∂P < ∞ :=
    hLi.neg.lintegral_lt_top
  have hLpos_fin : ∫⁻ ω, ENNReal.ofReal (φ m + c * (f ω - m)) ∂P < ∞ := hLi.lintegral_lt_top
  refine ⟨hmeas, hneg_le.trans_lt hLneg_fin, ?_⟩
  have key : ((φ m : ℝ) : EReal) =
      ((∫⁻ ω, ENNReal.ofReal (φ m + c * (f ω - m)) ∂P : ℝ≥0∞) : EReal) -
        ((∫⁻ ω, ENNReal.ofReal (-(φ m + c * (f ω - m))) ∂P : ℝ≥0∞) : EReal) := by
    have h := integral_eq_lintegral_pos_part_sub_lintegral_neg_part hLi
    rw [hLint] at h
    refine (congrArg (fun x : ℝ => (x : EReal)) h).trans ?_
    rw [EReal.coe_sub,
      EReal.coe_ennreal_toReal hLpos_fin.ne, EReal.coe_ennreal_toReal hLneg_fin.ne]
  rw [key]
  exact EReal.sub_le_sub (EReal.coe_ennreal_le_coe_ennreal_iff.2 hpos_le)
    (EReal.coe_ennreal_le_coe_ennreal_iff.2 hneg_le)

/-- The equality case. With the same setting and φ strictly convex on I, if the integral of
φ ∘ f is finite, then φ(∫ f dP) = ∫ φ ∘ f dP exactly when f equals its mean almost surely. -/
theorem jensen_equality_iff_ae_const (P : Measure Ω) [IsProbabilityMeasure P]
    (I : Set ℝ) (hI : I.OrdConnected) (φ : ℝ → ℝ) (hφ : StrictConvexOn ℝ I φ)
    (f : Ω → ℝ) (hf : Integrable f P) (hfI : ∀ ω, f ω ∈ I)
    (hφf : Integrable (fun ω => φ (f ω)) P) :
    φ (∫ ω, f ω ∂P) = ∫ ω, φ (f ω) ∂P ↔ f =ᵐ[P] fun _ => ∫ ω, f ω ∂P := by
  set m := ∫ ω, f ω ∂P with hm_def
  have hm : m ∈ I := jensen_aux_mean_mem P hI hf hfI
  constructor
  · intro heq
    by_cases hmi : m ∈ interior I
    swap
    · exact jensen_aux_ae_eq_of_not_interior P hI hf hfI hmi
    obtain ⟨c, hc⟩ := jensen_aux_support_line hφ.convexOn hmi
    have hLi : Integrable (fun ω => φ m + c * (f ω - m)) P :=
      (integrable_const _).add ((hf.sub (integrable_const _)).const_mul c)
    have hLint : ∫ ω, (φ m + c * (f ω - m)) ∂P = φ m := jensen_aux_integral_affine P hf _ _
    have h0 : 0 ≤ fun ω => φ (f ω) - (φ m + c * (f ω - m)) :=
      fun ω => sub_nonneg.2 (hc _ (hfI ω))
    have hint : ∫ ω, (φ (f ω) - (φ m + c * (f ω - m))) ∂P = 0 := by
      rw [integral_sub hφf hLi, hLint, ← heq, sub_self]
    have hae := (integral_eq_zero_iff_of_nonneg h0 (hφf.sub hLi)).1 hint
    filter_upwards [hae] with ω hω
    simp only [Pi.zero_apply, sub_eq_zero] at hω
    show f ω = m
    by_contra hne
    have hz : (1 / 2 : ℝ) • f ω + (1 / 2 : ℝ) • m ∈ I :=
      hφ.1 (hfI ω) hm (by norm_num) (by norm_num) (by norm_num)
    have hlt := hφ.2 (hfI ω) hm hne (by norm_num : (0 : ℝ) < 1 / 2)
      (by norm_num : (0 : ℝ) < 1 / 2) (by norm_num)
    have hle := hc _ hz
    simp only [smul_eq_mul] at hlt hle
    nlinarith
  · intro h
    have : ∫ ω, φ (f ω) ∂P = ∫ _ω, φ m ∂P :=
      integral_congr_ae (by filter_upwards [h] with ω hω; rw [hω])
    rw [this, integral_const]
    simp

/-- Lyapunov's inequality: moments nest. On a probability space, for powers 0 < p < q and a
measurable f, the p-norm (∫ |f|^p dP)^(1/p) is at most the q-norm (∫ |f|^q dP)^(1/q). -/
theorem lyapunov_p_norm_le_q_norm (P : Measure Ω) [IsProbabilityMeasure P]
    (p q : ℝ) (hp : 0 < p) (hpq : p < q) (f : Ω → ℝ) (hf : AEStronglyMeasurable f P) :
    eLpNorm' f p P ≤ eLpNorm' f q P := by
  exact eLpNorm'_le_eLpNorm'_of_exponent_le hp hpq.le P hf

-- The wind week 3, 5, 8, 2, 6, 4, 7: the speeds sum to 35, so the mean is 35 / 7 = 5.
example : ([3, 5, 8, 2, 6, 4, 7] : List ℕ).sum = 35 ∧ 35 / 7 = 5 := by decide

-- The cubes sum to 1295, so the mean cube is 1295 / 7 = 185, above the cube of the mean, 125.
example : (([3, 5, 8, 2, 6, 4, 7] : List ℕ).map (fun x => x ^ 3)).sum = 1295 ∧
    1295 = 7 * 185 ∧ 5 ^ 3 = 125 ∧ 125 ≤ 185 := by decide

-- The gaps (x - 5)^2 (x + 10) to the supporting line 125 + 75 (x - 5), day by day.
example : ([3, 5, 8, 2, 6, 4, 7] : List ℤ).map (fun x => (x - 5) ^ 2 * (x + 10)) =
    [52, 0, 162, 108, 16, 14, 68] := by decide

-- Each gap is the cube minus the line.
example : ([3, 5, 8, 2, 6, 4, 7] : List ℤ).all
    (fun x => x ^ 3 - (125 + 75 * (x - 5)) = (x - 5) ^ 2 * (x + 10)) = true := by decide

-- The gaps sum to 420, a mean gap of 60, and 125 + 60 = 185.
example : [52, 0, 162, 108, 16, 14, 68].sum = 420 ∧ 420 = 7 * 60 ∧ 125 + 60 = 185 := by decide

-- The square: the squares sum to 203 = 7 × 29, and 29 - 25 = 4, the variance.
example : (([3, 5, 8, 2, 6, 4, 7] : List ℕ).map (fun x => x ^ 2)).sum = 203 ∧
    203 = 7 * 29 ∧ 29 - 5 ^ 2 = 4 ∧
    (([3, 5, 8, 2, 6, 4, 7] : List ℕ).map (fun x => (x - 5 : ℤ) ^ 2)).sum = 7 * 4 := by decide

-- The geometric mean: the product of the speeds is 40320, and 40320 < 5 ^ 7, so its
-- seventh root is below the mean 5.
example : ([3, 5, 8, 2, 6, 4, 7] : List ℕ).prod = 40320 ∧ 40320 < 5 ^ 7 := by decide

-- Lyapunov in exact integers: the fourth powers sum to 8771 = 7 × 1253, and
-- 25 ≤ 29, 125 ≤ 185, 841 ≤ 1253.
example : (([3, 5, 8, 2, 6, 4, 7] : List ℕ).map (fun x => x ^ 4)).sum = 8771 ∧
    8771 = 7 * 1253 ∧ 5 ^ 2 ≤ 29 ∧ 5 ^ 3 ≤ 185 ∧ 29 ^ 2 = 841 ∧ 841 ≤ 1253 := by decide

-- Counting measure, total size 7: the integral of the speed is 35, its cube 42875,
-- far above the integral of the cubes, 1295.
example : (35 : ℕ) ^ 3 = 42875 ∧ 1295 < 42875 := by decide

#print axioms jensen_aux_not_interior
#print axioms jensen_aux_countable
#print axioms jensen_aux_measurable
#print axioms jensen_aux_lt_integral
#print axioms jensen_aux_mean_mem
#print axioms jensen_aux_ae_eq_of_not_interior
#print axioms jensen_aux_support_line
#print axioms jensen_aux_integral_affine
#print axioms jensen_aux_exists_ae_line
#print axioms convex_of_integral_le_integral_of_convex
#print axioms jensen_equality_iff_ae_const
#print axioms lyapunov_p_norm_le_q_norm
