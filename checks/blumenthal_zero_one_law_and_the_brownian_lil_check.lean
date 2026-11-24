-- Brownian paths up close: for a Brownian motion, the lim sup of W_t / sqrt(2 t ln ln t) is 1 with probability one, every event decided by every opening stretch of the path has chance 0 or 1, and the path is both above and below its start in every opening stretch.
import Mathlib.Probability.BrownianMotion.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Data.EReal.Basic
import Mathlib.Order.LiminfLimsup
import Mathlib.Analysis.PSeries
import Mathlib.Probability.BorelCantelli
import Mathlib.Probability.Moments.Basic
import Mathlib.Analysis.Complex.ExponentialBounds

open MeasureTheory ProbabilityTheory Filter
open scoped NNReal ENNReal

lemma lil_grid_le {t : ℝ≥0} {n k : ℕ} (hk : k ≤ n + 1) : t * k / (n + 1) ≤ t := by
  rw [div_le_iff₀ (by positivity)]
  gcongr
  exact_mod_cast hk

lemma lil_grid_mono {t : ℝ≥0} {n j k : ℕ} (hjk : j ≤ k) : t * j / (n + 1) ≤ t * k / (n + 1) := by
  gcongr

lemma lil_grid_approx {t s : ℝ≥0} (hs : s ≤ t) (n : ℕ) :
    ∃ k ≤ n + 1, t * k / (n + 1) ≤ s ∧ (s : ℝ) ≤ (t * k / (n + 1) : ℝ≥0) + (t : ℝ) / (n + 1) := by
  rcases eq_or_ne t 0 with ht | ht
  · subst ht
    have : s = 0 := le_antisymm hs zero_le
    subst this
    exact ⟨0, by omega, by simp, by simp⟩
  have htr : (0 : ℝ) < t := NNReal.coe_pos.2 (pos_iff_ne_zero.2 ht)
  have hsr : (s : ℝ) ≤ t := hs
  refine ⟨⌊(s : ℝ) * (n + 1) / t⌋₊, ?_, ?_, ?_⟩
  · apply Nat.floor_le_of_le
    rw [div_le_iff₀ htr]
    push_cast
    nlinarith [s.2]
  · rw [← NNReal.coe_le_coe]
    push_cast
    rw [div_le_iff₀ (by positivity)]
    have := Nat.floor_le (a := (s : ℝ) * (n + 1) / t) (by positivity)
    rw [le_div_iff₀ htr] at this
    nlinarith
  · push_cast
    have := Nat.lt_floor_add_one ((s : ℝ) * (n + 1) / t)
    rw [div_lt_iff₀ htr] at this
    rw [← add_div, le_div_iff₀ (by positivity)]
    nlinarith

open Filter in
lemma lil_mesh (t : ℝ≥0) {δ : ℝ} (hδ : 0 < δ) : ∀ᶠ n : ℕ in atTop, (t : ℝ) / (n + 1) < δ := by
  have h := (tendsto_one_div_add_atTop_nhds_zero_nat).const_mul (t : ℝ)
  rw [mul_zero] at h
  filter_upwards [h.eventually (gt_mem_nhds hδ)] with n hn
  have : (t : ℝ) / (n + 1) = t * (1 / ((n : ℝ) + 1)) := by ring
  rw [this]; exact hn

lemma lil_max {f : ℝ≥0 → ℝ} (hf : Continuous f) (t : ℝ≥0) :
    ∃ s ≤ t, (∀ r ≤ t, f r ≤ f s) ∧ ⨆ r : Set.Iic t, f r = f s := by
  have hc : IsCompact (Set.Iic t) := by
    rw [← Set.Icc_bot]; exact isCompact_Icc
  obtain ⟨s, hs, hmax⟩ := hc.exists_isMaxOn Set.nonempty_Iic hf.continuousOn
  refine ⟨s, hs, fun r hr ↦ hmax hr, le_antisymm ?_ ?_⟩
  · exact ciSup_le fun r ↦ hmax r.2
  · refine le_ciSup (f := fun r : Set.Iic t ↦ f r) ⟨f s, ?_⟩ ⟨s, hs⟩
    rintro _ ⟨r, rfl⟩
    exact hmax r.2

lemma lil_le_sup {f : ℝ≥0 → ℝ} (hf : Continuous f) {t r : ℝ≥0} (hr : r ≤ t) :
    f r ≤ ⨆ r : Set.Iic t, f r := by
  obtain ⟨s, -, hmax, heq⟩ := lil_max hf t
  rw [heq]; exact hmax r hr

open Filter in
lemma lil_hit_eventually {f : ℝ≥0 → ℝ} (hf : Continuous f) (t : ℝ≥0) {a δ : ℝ} (hδ : 0 < δ)
    (ha : a ≤ ⨆ r : Set.Iic t, f r) :
    ∀ᶠ n : ℕ in atTop, ∃ k ≤ n + 1, a - δ ≤ f (t * k / (n + 1)) := by
  obtain ⟨s, hs, -, heq⟩ := lil_max hf t
  rw [heq] at ha
  obtain ⟨δ', hδ', hcont⟩ := Metric.continuous_iff.1 hf s δ hδ
  filter_upwards [lil_mesh t hδ'] with n hn
  obtain ⟨k, hk, h1, h2⟩ := lil_grid_approx hs n
  refine ⟨k, hk, ?_⟩
  have hd : dist (t * k / (n + 1)) s < δ' := by
    rw [NNReal.dist_eq, abs_sub_comm, abs_of_nonneg (by rw [sub_nonneg]; exact_mod_cast h1)]
    linarith
  have := hcont _ hd
  rw [Real.dist_eq] at this
  linarith [abs_lt.1 this]

lemma lil_gauss_symm (v : ℝ≥0) (c : ℝ) :
    gaussianReal 0 v {x | x ≤ -c} = gaussianReal 0 v {x | c ≤ x} := by
  have h : (gaussianReal 0 v).map (fun x ↦ -x) = gaussianReal 0 v := by
    simpa using gaussianReal_map_neg (μ := 0) (v := v)
  calc gaussianReal 0 v {x | x ≤ -c} = (gaussianReal 0 v).map (fun x ↦ -x) {x | x ≤ -c} := by
        rw [h]
    _ = gaussianReal 0 v {x | c ≤ x} := by
      rw [Measure.map_apply measurable_neg (show MeasurableSet {x : ℝ | x ≤ -c} from measurableSet_Iic)]
      congr 1
      ext x
      simp

lemma lil_gauss_small {v : ℝ≥0} (hv : v ≠ 0) (x : ℝ) {η : ℝ≥0∞} (hη : 0 < η) :
    ∃ δ > 0, gaussianReal 0 v (Set.Icc (x - δ) (x + δ)) < η := by
  have := nullSingletonClass_gaussianReal (μ := 0) hv
  set s : ℕ → Set ℝ := fun m ↦ Set.Icc (x - 1 / (m + 1)) (x + 1 / (m + 1)) with hs
  have hanti : Antitone s := by
    intro m m' hmm'
    have : (1 : ℝ) / (m' + 1) ≤ 1 / (m + 1) := by gcongr
    exact Set.Icc_subset_Icc (by linarith) (by linarith)
  have hsub : ⋂ m, s m ⊆ {x} := by
    intro y hy
    rw [Set.mem_iInter] at hy
    rw [Set.mem_singleton_iff]
    by_contra hne
    have hpos : 0 < |y - x| := abs_pos.2 (sub_ne_zero.2 hne)
    obtain ⟨m, hm⟩ := exists_nat_one_div_lt hpos
    have := hy m
    simp only [hs, Set.mem_Icc] at this
    have : |y - x| ≤ 1 / (m + 1) := abs_sub_le_iff.2 ⟨by linarith, by linarith⟩
    linarith
  have ht := tendsto_measure_iInter_atTop (μ := gaussianReal 0 v)
    (fun m ↦ measurableSet_Icc.nullMeasurableSet) hanti ⟨0, measure_ne_top _ _⟩
  rw [measure_mono_null hsub (measure_singleton x)] at ht
  obtain ⟨m, hm⟩ := (ht.eventually (gt_mem_nhds hη)).exists
  exact ⟨1 / (m + 1), by positivity, hm⟩

lemma lil_reflect_step {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    {B : ℝ≥0 → Ω → ℝ} (hB : IsPreBrownianReal B P) {u t : ℝ≥0} (hut : u ≤ t)
    (S : Set (Set.Iic u → ℝ)) (hS : MeasurableSet S) (c : ℝ) :
    P ({ω | (fun s : Set.Iic u ↦ B s ω) ∈ S} ∩ {ω | B t ω - B u ω ≤ -c}) =
      P ({ω | (fun s : Set.Iic u ↦ B s ω) ∈ S} ∩ {ω | c ≤ B t ω - B u ω}) := by
  have hind := hB.indepFun_shift u
  have e : u + (t - u) = t := add_tsub_cancel_of_le hut
  have key : ∀ T : Set ℝ, MeasurableSet T →
      P ({ω | (fun s : Set.Iic u ↦ B s ω) ∈ S} ∩ {ω | B t ω - B u ω ∈ T}) =
        P {ω | (fun s : Set.Iic u ↦ B s ω) ∈ S} * gaussianReal 0 (nndist t.1 u.1) T := by
    intro T hT
    have h := hind.measure_inter_preimage_eq_mul {x : ℝ≥0 → ℝ | x (t - u) ∈ T} S
      (measurable_pi_apply (t - u) hT) hS
    simp only [Set.preimage_ofPred_eq, e] at h
    have hlaw := (hB.hasLaw_sub t u).measure_eq (p := fun x ↦ x ∈ T) hT
    simp only [Pi.sub_apply, Set.ofPred_mem_eq] at hlaw
    rw [Set.inter_comm, ← hlaw, mul_comm]
    exact h
  have h1 := key {x | x ≤ -c} (measurableSet_le measurable_id measurable_const)
  have h2 := key {x | c ≤ x} (measurableSet_le measurable_const measurable_id)
  simp only [Set.mem_ofPred_eq] at h1 h2
  rw [h1, h2, lil_gauss_symm]

lemma lil_first_hit (x : ℕ → ℝ) (a : ℝ) {K : ℕ} (h : ∃ k ≤ K, a ≤ x k) :
    ∃ k ≤ K, a ≤ x k ∧ ∀ j < k, x j < a := by
  classical
  refine ⟨Nat.find h, (Nat.find_spec h).1, (Nat.find_spec h).2, fun j hj ↦ ?_⟩
  by_contra hc
  push Not at hc
  exact Nat.find_min h hj ⟨hj.le.trans (Nat.find_spec h).1, hc⟩

lemma lil_E_nm {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    {B : ℝ≥0 → Ω → ℝ} (hB : IsPreBrownianReal B P) (τ : ℕ → ℝ≥0) (a : ℝ) (k : ℕ) :
    NullMeasurableSet {ω | a ≤ B (τ k) ω ∧ ∀ j < k, B (τ j) ω < a} P := by
  have : {ω | a ≤ B (τ k) ω ∧ ∀ j < k, B (τ j) ω < a} =
      {ω | a ≤ B (τ k) ω} ∩ ⋂ j : Fin k, {ω | B (τ j) ω < a} := by
    ext ω; simp [Fin.forall_iff]
  rw [this]
  exact (nullMeasurableSet_le aemeasurable_const (hB.aemeasurable _)).inter
    (NullMeasurableSet.iInter fun j ↦ nullMeasurableSet_lt (hB.aemeasurable _) aemeasurable_const)

lemma lil_E_disj {Ω : Type*} (B : ℝ≥0 → Ω → ℝ) (τ : ℕ → ℝ≥0) (a : ℝ) {i j : ℕ} (hij : i ≠ j)
    (X Y : Set Ω) :
    Disjoint ({ω | a ≤ B (τ i) ω ∧ ∀ l < i, B (τ l) ω < a} ∩ X)
      ({ω | a ≤ B (τ j) ω ∧ ∀ l < j, B (τ l) ω < a} ∩ Y) := by
  rw [Set.disjoint_left]
  rintro ω ⟨⟨hi1, hi2⟩, -⟩ ⟨⟨hj1, hj2⟩, -⟩
  rcases lt_or_gt_of_ne hij with h | h
  · linarith [hj2 i h]
  · linarith [hi2 j h]

lemma lil_sum_reflect {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    {B : ℝ≥0 → Ω → ℝ} (hB : IsPreBrownianReal B P) {τ : ℕ → ℝ≥0} (hmono : Monotone τ)
    {t : ℝ≥0} {K : ℕ} (hτ : τ K ≤ t) (a c : ℝ) :
    P (⋃ k ∈ Finset.range (K + 1), {ω | a ≤ B (τ k) ω ∧ ∀ j < k, B (τ j) ω < a} ∩
        {ω | B t ω - B (τ k) ω ≤ -c}) =
      P (⋃ k ∈ Finset.range (K + 1), {ω | a ≤ B (τ k) ω ∧ ∀ j < k, B (τ j) ω < a} ∩
        {ω | c ≤ B t ω - B (τ k) ω}) := by
  have hm := hB.aemeasurable
  rw [measure_biUnion_finset₀, measure_biUnion_finset₀]
  · refine Finset.sum_congr rfl fun k hk ↦ ?_
    have hkK : k ≤ K := Nat.lt_succ_iff.1 (Finset.mem_range.1 hk)
    let S : Set (Set.Iic (τ k) → ℝ) := {x | a ≤ x ⟨τ k, Set.mem_Iic.2 le_rfl⟩} ∩
      ⋂ j : Fin k, {x | x ⟨τ j, Set.mem_Iic.2 (hmono j.2.le)⟩ < a}
    have hS : MeasurableSet S := (measurableSet_le measurable_const (measurable_pi_apply _)).inter
      (MeasurableSet.iInter fun j ↦ measurableSet_lt (measurable_pi_apply _) measurable_const)
    have hE : {ω | a ≤ B (τ k) ω ∧ ∀ j < k, B (τ j) ω < a} =
        {ω | (fun s : Set.Iic (τ k) ↦ B s ω) ∈ S} := by
      ext ω; simp [S, Fin.forall_iff]
    rw [hE]
    exact lil_reflect_step hB ((hmono hkK).trans hτ) S hS c
  · intro i _ j _ hij
    exact (lil_E_disj B τ a hij _ _).aedisjoint
  · intro k _
    exact (lil_E_nm hB τ a k).inter (nullMeasurableSet_le aemeasurable_const (by fun_prop))
  · intro i _ j _ hij
    exact (lil_E_disj B τ a hij _ _).aedisjoint
  · intro k _
    exact (lil_E_nm hB τ a k).inter (nullMeasurableSet_le (by fun_prop) aemeasurable_const)

lemma lil_disc_upper {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    {B : ℝ≥0 → Ω → ℝ} (hB : IsPreBrownianReal B P) {τ : ℕ → ℝ≥0} (hmono : Monotone τ)
    {t : ℝ≥0} {K : ℕ} (hτ : τ K ≤ t) (a b : ℝ) :
    P ({ω | ∃ k ≤ K, a ≤ B (τ k) ω} ∩ {ω | B t ω ≤ b}) ≤ P {ω | 2 * a - b ≤ B t ω} := by
  calc P ({ω | ∃ k ≤ K, a ≤ B (τ k) ω} ∩ {ω | B t ω ≤ b})
      ≤ P (⋃ k ∈ Finset.range (K + 1), {ω | a ≤ B (τ k) ω ∧ ∀ j < k, B (τ j) ω < a} ∩
        {ω | B t ω - B (τ k) ω ≤ -(a - b)}) := by
        apply measure_mono
        rintro ω ⟨hex, hb⟩
        obtain ⟨k, hk, h1, h2⟩ := lil_first_hit (fun k ↦ B (τ k) ω) a hex
        simp only [Set.mem_iUnion, Finset.mem_range, Set.mem_inter_iff, Set.mem_ofPred_eq]
        refine ⟨k, by omega, ⟨h1, h2⟩, ?_⟩
        simp only [Set.mem_ofPred_eq] at hb
        linarith
    _ = P (⋃ k ∈ Finset.range (K + 1), {ω | a ≤ B (τ k) ω ∧ ∀ j < k, B (τ j) ω < a} ∩
        {ω | a - b ≤ B t ω - B (τ k) ω}) := lil_sum_reflect hB hmono hτ a (a - b)
    _ ≤ P {ω | 2 * a - b ≤ B t ω} := by
        apply measure_mono
        intro ω hω
        simp only [Set.mem_iUnion, Finset.mem_range, Set.mem_inter_iff, Set.mem_ofPred_eq] at hω
        obtain ⟨k, -, ⟨h1, -⟩, h3⟩ := hω
        simp only [Set.mem_ofPred_eq]
        linarith

lemma lil_grid_monotone (t : ℝ≥0) (n : ℕ) : Monotone (fun k : ℕ ↦ t * k / (n + 1)) :=
  fun _ _ h ↦ lil_grid_mono h

lemma lil_upper {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    {B : ℝ≥0 → Ω → ℝ} (hB : IsBrownianReal B P) {t : ℝ≥0} (ht : t ≠ 0) (a b : ℝ) :
    P {ω | a ≤ (⨆ s : Set.Iic t, B s ω) ∧ B t ω ≤ b} ≤ P {ω | 2 * a - b ≤ B t ω} := by
  refine ENNReal.le_of_forall_pos_le_add fun η hη _ ↦ ?_
  obtain ⟨δ, hδ, hν⟩ := lil_gauss_small ht (2 * a - b) (η := η) (by exact_mod_cast hη)
  have hlaw := hB.hasLaw_eval t
  let A : ℕ → Set Ω := fun N ↦
    {ω | ∀ n ≥ N, ∃ k ≤ n + 1, a - δ / 2 ≤ B (t * k / (n + 1)) ω} ∩ {ω | B t ω ≤ b}
  have hA : Monotone A := by
    intro N N' h ω hω
    exact ⟨fun n hn ↦ hω.1 n (h.trans hn), hω.2⟩
  calc P {ω | a ≤ (⨆ s : Set.Iic t, B s ω) ∧ B t ω ≤ b} ≤ P (⋃ N, A N) := by
        apply measure_mono_ae
        filter_upwards [hB.cont] with ω hω hmem
        obtain ⟨N, hN⟩ := (lil_hit_eventually hω t (half_pos hδ) hmem.1).exists_forall_of_atTop
        exact Set.mem_iUnion.2 ⟨N, fun n hn ↦ hN n hn, hmem.2⟩
    _ = ⨆ N, P (A N) := hA.measure_iUnion
    _ ≤ P {ω | 2 * a - b ≤ B t ω} + η := by
        refine iSup_le fun N ↦ ?_
        calc P (A N) ≤ P ({ω | ∃ k ≤ N + 1, a - δ / 2 ≤ B (t * k / (N + 1)) ω} ∩
              {ω | B t ω ≤ b}) := measure_mono fun ω hω ↦ ⟨hω.1 N le_rfl, hω.2⟩
          _ ≤ P {ω | 2 * (a - δ / 2) - b ≤ B t ω} :=
              lil_disc_upper hB.toIsPreBrownianReal (lil_grid_monotone t N)
                (lil_grid_le le_rfl) _ _
          _ ≤ P ({ω | 2 * a - b ≤ B t ω} ∪
              {ω | B t ω ∈ Set.Icc (2 * a - b - δ) (2 * a - b + δ)}) := by
              apply measure_mono
              intro ω hω
              simp only [Set.mem_ofPred_eq, Set.mem_union, Set.mem_Icc] at hω ⊢
              by_cases hc : 2 * a - b ≤ B t ω
              · exact Or.inl hc
              · right; constructor <;> linarith
          _ ≤ P {ω | 2 * a - b ≤ B t ω} +
              P {ω | B t ω ∈ Set.Icc (2 * a - b - δ) (2 * a - b + δ)} := measure_union_le _ _
          _ ≤ P {ω | 2 * a - b ≤ B t ω} + η := by
              gcongr
              rw [hlaw.measure_eq (p := fun x ↦ x ∈ Set.Icc (2 * a - b - δ) (2 * a - b + δ))
                measurableSet_Icc, Set.ofPred_mem_eq]
              exact hν.le

lemma lil_max_tail_le {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    {B : ℝ≥0 → Ω → ℝ} (hB : IsBrownianReal B P) {t : ℝ≥0} (ht : t ≠ 0) (a : ℝ) :
    P {ω | a ≤ ⨆ s : Set.Iic t, B s ω} ≤ 2 * P {ω | a ≤ B t ω} := by
  calc P {ω | a ≤ ⨆ s : Set.Iic t, B s ω}
      ≤ P ({ω | a ≤ (⨆ s : Set.Iic t, B s ω) ∧ B t ω ≤ a} ∪ {ω | a ≤ B t ω}) := by
        apply measure_mono
        intro ω hω
        simp only [Set.mem_ofPred_eq, Set.mem_union] at hω ⊢
        by_cases h : B t ω ≤ a
        · exact Or.inl ⟨hω, h⟩
        · exact Or.inr (le_of_lt (lt_of_not_ge h))
    _ ≤ P {ω | a ≤ (⨆ s : Set.Iic t, B s ω) ∧ B t ω ≤ a} + P {ω | a ≤ B t ω} :=
        measure_union_le _ _
    _ ≤ P {ω | 2 * a - a ≤ B t ω} + P {ω | a ≤ B t ω} := by
        exact add_le_add_left (lil_upper hB ht a a) _
    _ = 2 * P {ω | a ≤ B t ω} := by
        rw [show 2 * a - a = a by ring, two_mul]

lemma lil_gauss_upper {v : ℝ≥0} (hv : v ≠ 0) {a : ℝ} (ha : 0 ≤ a) :
    gaussianReal 0 v {x | a ≤ x} ≤ ENNReal.ofReal (Real.exp (-a ^ 2 / (2 * v))) := by
  have hv' : (0 : ℝ) < v := NNReal.coe_pos.2 (pos_iff_ne_zero.2 hv)
  have h := measure_ge_le_exp_mul_mgf (μ := gaussianReal 0 v) (X := id) a (t := a / v)
    (div_nonneg ha hv'.le) (integrable_exp_mul_gaussianReal (μ := 0) (v := v) (a / v))
  rw [mgf_id_gaussianReal] at h
  simp only [id] at h
  rw [← ofReal_measureReal]
  apply ENNReal.ofReal_le_ofReal
  refine h.trans (le_of_eq ?_)
  rw [← Real.exp_add]
  congr 1
  field_simp
  ring

lemma lil_gauss_lower {v : ℝ≥0} (hv : v ≠ 0) {a : ℝ} (ha : 0 ≤ a) :
    ENNReal.ofReal ((Real.sqrt (2 * Real.pi))⁻¹ * Real.exp (-(a / Real.sqrt v + 1) ^ 2 / 2)) ≤
      gaussianReal 0 v {x | a ≤ x} := by
  have hv' : (0 : ℝ) < v := NNReal.coe_pos.2 (pos_iff_ne_zero.2 hv)
  set sv := Real.sqrt v with hsv
  have hsv0 : 0 < sv := Real.sqrt_pos.2 hv'
  have hsv2 : sv ^ 2 = v := Real.sq_sqrt hv'.le
  set m : ℝ := (Real.sqrt (2 * Real.pi * v))⁻¹ * Real.exp (-(a + sv) ^ 2 / (2 * v)) with hm
  have hmeq : m * sv = (Real.sqrt (2 * Real.pi))⁻¹ * Real.exp (-(a / sv + 1) ^ 2 / 2) := by
    have h1 : Real.sqrt (2 * Real.pi * v) = Real.sqrt (2 * Real.pi) * sv := by
      rw [Real.sqrt_mul (by positivity)]
    have h2 : -(a + sv) ^ 2 / (2 * v) = -(a / sv + 1) ^ 2 / 2 := by
      rw [← hsv2]; field_simp
    rw [hm, h1, h2]
    field_simp
  rw [gaussianReal_of_var_ne_zero 0 hv,
    withDensity_apply _ (by exact measurableSet_Ici : MeasurableSet {x : ℝ | a ≤ x})]
  calc ENNReal.ofReal ((Real.sqrt (2 * Real.pi))⁻¹ * Real.exp (-(a / sv + 1) ^ 2 / 2))
      = ENNReal.ofReal m * volume (Set.Icc a (a + sv)) := by
        rw [Real.volume_Icc, ← ENNReal.ofReal_mul (by positivity), ← hmeq]
        congr 2; ring
    _ = ∫⁻ x in Set.Icc a (a + sv), ENNReal.ofReal m := (setLIntegral_const _ _).symm
    _ ≤ ∫⁻ x in Set.Icc a (a + sv), gaussianPDF 0 v x := by
        refine setLIntegral_mono (measurable_gaussianPDF 0 v) fun x hx ↦ ?_
        show ENNReal.ofReal m ≤ ENNReal.ofReal
          ((Real.sqrt (2 * Real.pi * v))⁻¹ * Real.exp (-(x - 0) ^ 2 / (2 * v)))
        apply ENNReal.ofReal_le_ofReal
        rw [hm]
        have hx2 : (x - 0) ^ 2 ≤ (a + sv) ^ 2 := by nlinarith [hx.1, hx.2]
        have h3 : -(a + sv) ^ 2 / (2 * v) ≤ -(x - 0) ^ 2 / (2 * v) := by
          apply div_le_div_of_nonneg_right _ (by positivity)
          linarith
        gcongr
    _ ≤ ∫⁻ x in {x | a ≤ x}, gaussianPDF 0 v x :=
        lintegral_mono_set fun x hx ↦ hx.1

lemma lil_h_mono {x y : ℝ} (hx0 : 0 < x) (hx : 1 ≤ Real.log x) (hxy : x ≤ y) :
    Real.sqrt (2 * x * Real.log (Real.log x)) ≤ Real.sqrt (2 * y * Real.log (Real.log y)) := by
  have hy0 : 0 < y := hx0.trans_le hxy
  have hl : Real.log x ≤ Real.log y := Real.log_le_log hx0 hxy
  have hll0 : 0 ≤ Real.log (Real.log x) := Real.log_nonneg hx
  have hll : Real.log (Real.log x) ≤ Real.log (Real.log y) :=
    Real.log_le_log (by linarith) hl
  apply Real.sqrt_le_sqrt
  have := mul_le_mul hxy hll hll0 hy0.le
  nlinarith

lemma lil_h_step {x q : ℝ} (hx : 1 ≤ x) (hq : 1 ≤ q) :
    Real.sqrt (2 * x * Real.log (Real.log x)) ≤
      Real.sqrt (2 * (q * x) * Real.log (Real.log (q * x))) / Real.sqrt q := by
  have hx0 : 0 < x := by linarith
  have hq0 : 0 < q := by linarith
  by_cases hpos : 0 < Real.log (Real.log x)
  · have hlx0 : 0 ≤ Real.log x := Real.log_nonneg hx
    have hlx : 1 < Real.log x := by
      by_contra h
      push Not at h
      have : Real.log (Real.log x) ≤ 0 := Real.log_nonpos hlx0 h
      linarith
    have hl : Real.log x ≤ Real.log (q * x) := Real.log_le_log hx0 (by nlinarith)
    have hll : Real.log (Real.log x) ≤ Real.log (Real.log (q * x)) :=
      Real.log_le_log (by linarith) hl
    rw [← Real.sqrt_div' _ hq0.le]
    apply Real.sqrt_le_sqrt
    have e : 2 * (q * x) * Real.log (Real.log (q * x)) / q =
        2 * x * Real.log (Real.log (q * x)) := by
      field_simp
    rw [e]
    have := mul_le_mul_of_nonneg_left hll (by positivity : (0 : ℝ) ≤ 2 * x)
    linarith
  · push Not at hpos
    have h0 : Real.sqrt (2 * x * Real.log (Real.log x)) = 0 := by
      apply Real.sqrt_eq_zero'.2
      have := mul_nonpos_of_nonneg_of_nonpos (by positivity : (0 : ℝ) ≤ 2 * x) hpos
      linarith
    rw [h0]
    positivity

lemma lil_upper_bound {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    {B : ℝ≥0 → Ω → ℝ} (hB : IsBrownianReal B P) {c : ℝ} (hc : 1 < c) :
    ∀ᵐ ω ∂P, ∀ᶠ t : ℝ≥0 in atTop,
      B t ω ≤ c * Real.sqrt (2 * (t : ℝ) * Real.log (Real.log t)) := by
  have hprob : IsProbabilityMeasure P := hB.isGaussianProcess.isProbabilityMeasure
  have hc0 : 0 < c := by linarith
  set cN : ℝ≥0 := ⟨c, hc0.le⟩ with hcN
  have hcN1 : 1 < cN := by rw [← NNReal.coe_lt_coe]; exact hc
  have hlogc : 0 < Real.log c := Real.log_pos hc
  obtain ⟨N0, hN0⟩ := exists_nat_ge (1 / Real.log c)
  have hmN : ∀ m : ℕ, N0 ≤ m → 1 ≤ (m : ℝ) * Real.log c := by
    intro m hm
    have : (N0 : ℝ) ≤ m := by exact_mod_cast hm
    rw [div_le_iff₀ hlogc] at hN0
    nlinarith
  set T : ℕ → ℝ≥0 := fun m ↦ cN ^ m with hT
  have hTcoe : ∀ m, ((T m : ℝ≥0) : ℝ) = c ^ m := fun m ↦ by
    simp only [hT, hcN]; rfl
  set a : ℕ → ℝ := fun m ↦ c * Real.sqrt (2 * (T m : ℝ) * Real.log (Real.log (T m))) with ha
  set E : ℕ → Set Ω := fun n ↦ {ω | a (n + N0) ≤ ⨆ s : Set.Iic (T (n + N0 + 1)), B s ω}
    with hE
  set f : ℕ → ℝ := fun n ↦ 2 * (((n + N0 : ℕ) : ℝ) * Real.log c) ^ (-c) with hf
  have hf_nonneg : ∀ n, 0 ≤ f n := fun n ↦ by positivity
  have hPE : ∀ n, P (E n) ≤ ENNReal.ofReal (f n) := by
    intro n
    set m := n + N0 with hmdef
    have hm1 : 1 ≤ (m : ℝ) * Real.log c := hmN m (by omega)
    have hlogT : Real.log (T m) = m * Real.log c := by rw [hTcoe, Real.log_pow]
    have hLL : 0 ≤ Real.log (Real.log (T m)) := by rw [hlogT]; exact Real.log_nonneg hm1
    have hT0 : T (m + 1) ≠ 0 := by
      simp only [hT]; exact pow_ne_zero _ (ne_of_gt (zero_lt_one.trans hcN1))
    have ha0 : 0 ≤ a m := by simp only [ha]; positivity
    have hsq : (a m) ^ 2 = c ^ 2 * (2 * c ^ m * Real.log (m * Real.log c)) := by
      simp only [ha]
      rw [mul_pow, Real.sq_sqrt (mul_nonneg (by positivity) hLL), hlogT, hTcoe]
    have hexp : -(a m) ^ 2 / (2 * ((T (m + 1) : ℝ≥0) : ℝ)) =
        Real.log (m * Real.log c) * (-c) := by
      rw [hsq, hTcoe, pow_succ]
      field_simp
      ring
    calc P (E n) ≤ 2 * P {ω | a m ≤ B (T (m + 1)) ω} := lil_max_tail_le hB hT0 (a m)
      _ = 2 * gaussianReal 0 (T (m + 1)) {x | a m ≤ x} := by
          rw [(hB.hasLaw_eval _).measure_eq (p := fun x ↦ a m ≤ x) measurableSet_Ici]
      _ ≤ 2 * ENNReal.ofReal (Real.exp (-(a m) ^ 2 / (2 * ((T (m + 1) : ℝ≥0) : ℝ)))) := by
          gcongr
          exact lil_gauss_upper hT0 ha0
      _ = ENNReal.ofReal (f n) := by
          rw [hexp, ← Real.rpow_def_of_pos (by positivity), hf]
          simp only
          rw [ENNReal.ofReal_mul (by norm_num), ENNReal.ofReal_ofNat]
  have hfs : Summable f := by
    have e : f = fun n ↦ (2 * Real.log c ^ (-c)) * (((n + N0 : ℕ) : ℝ) ^ c)⁻¹ := by
      ext n
      simp only [hf]
      rw [Real.mul_rpow (by positivity) hlogc.le, Real.rpow_neg (by positivity),
        Real.rpow_neg hlogc.le]
      ring
    rw [e]
    exact ((summable_nat_add_iff N0).2 (Real.summable_nat_rpow_inv.2 hc)).mul_left _
  have hsum : ∑' n, P (E n) ≠ ⊤ := by
    refine ne_top_of_le_ne_top ?_ (tsum_le_tsum hPE)
    rw [← ENNReal.ofReal_tsum_of_nonneg hf_nonneg hfs]
    exact ENNReal.ofReal_ne_top
  filter_upwards [ae_eventually_notMem hsum, hB.cont] with ω hω hcont
  obtain ⟨n1, hn1⟩ := eventually_atTop.1 hω
  rw [eventually_atTop]
  refine ⟨T (n1 + N0), fun t ht ↦ ?_⟩
  have h1t : 1 ≤ t := (one_le_pow₀ hcN1.le).trans ht
  obtain ⟨m, hm1, hm2⟩ := exists_nat_pow_near h1t hcN1
  have hmge : n1 + N0 ≤ m := by
    by_contra h
    push Not at h
    have h1 : cN ^ (m + 1) ≤ cN ^ (n1 + N0) := pow_le_pow_right₀ hcN1.le (by omega)
    have : t < t := lt_of_lt_of_le hm2 (h1.trans ht)
    exact lt_irrefl _ this
  obtain ⟨n, rfl⟩ : ∃ n, m = n + N0 := ⟨m - N0, by omega⟩
  have hnot := hn1 n (by omega)
  simp only [hE, Set.mem_ofPred_eq, not_le] at hnot
  have hBt : B t ω ≤ ⨆ s : Set.Iic (T (n + N0 + 1)), B s ω := lil_le_sup hcont (le_of_lt hm2)
  have hTm0 : (0 : ℝ) < (T (n + N0) : ℝ) := by rw [hTcoe]; positivity
  have hlogTm : 1 ≤ Real.log (T (n + N0)) := by
    rw [hTcoe, Real.log_pow]; exact hmN _ (by omega)
  have hmono := lil_h_mono hTm0 hlogTm
    (show ((T (n + N0) : ℝ≥0) : ℝ) ≤ t from by exact_mod_cast hm1)
  calc B t ω ≤ ⨆ s : Set.Iic (T (n + N0 + 1)), B s ω := hBt
    _ ≤ a (n + N0) := hnot.le
    _ ≤ c * Real.sqrt (2 * (t : ℝ) * Real.log (Real.log t)) := by
        simp only [ha]
        exact mul_le_mul_of_nonneg_left hmono hc0.le

lemma lil_one_lt_log_three : 1 < Real.log 3 := by
  rw [Real.lt_log_iff_exp_lt (by norm_num)]
  exact Real.exp_one_lt_three

lemma lil_quad {x d : ℝ} (hd : 0 < d) : (x + 1) ^ 2 ≤ (1 + d) * x ^ 2 + (1 + 1 / d) := by
  have h1 : d * (1 / d) = 1 := by field_simp
  have h2 : 0 ≤ (d * x - 1) ^ 2 := sq_nonneg _
  have h3 : 2 * x ≤ d * x ^ 2 + 1 / d := by
    have : 2 * x * d ≤ (d * x ^ 2 + 1 / d) * d := by nlinarith
    exact le_of_mul_le_mul_right this hd
  nlinarith

lemma lil_not_summable {K : ℝ} (hK : 0 < K) :
    ∑' n : ℕ, ENNReal.ofReal (K / ((n : ℝ) + 1)) = ⊤ := by
  have e : ∀ n : ℕ, ENNReal.ofReal (K / ((n : ℝ) + 1)) =
      ((Real.toNNReal (K / ((n : ℝ) + 1)) : ℝ≥0) : ℝ≥0∞) := fun n ↦ rfl
  simp_rw [e]
  rw [ENNReal.tsum_coe_eq_top_iff_not_summable_coe]
  intro hs
  have hs' : Summable fun n : ℕ ↦ K / ((n : ℝ) + 1) := by
    refine hs.congr fun n ↦ ?_
    rw [Real.coe_toNNReal _ (by positivity)]
  have h2 : Summable fun n : ℕ ↦ 1 / (((n + 1 : ℕ) : ℝ)) := by
    have := hs'.mul_left (1 / K)
    refine this.congr fun n ↦ ?_
    push_cast
    field_simp
  exact Real.not_summable_one_div_natCast ((summable_nat_add_iff 1).1 h2)

lemma lil_lower_bound {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    {B : ℝ≥0 → Ω → ℝ} (hB : IsBrownianReal B P) {r : ℝ} (hr0 : 0 < r) (hr1 : r < 1) :
    ∀ᵐ ω ∂P, ∃ᶠ t : ℝ≥0 in atTop,
      r * Real.sqrt (2 * (t : ℝ) * Real.log (Real.log t)) ≤ B t ω := by
  have hprob : IsProbabilityMeasure P := hB.isGaussianProcess.isProbabilityMeasure
  set α : ℝ := (1 + r) / 2 with hα
  have hα0 : 0 < α := by rw [hα]; linarith
  have hα1 : α < 1 := by rw [hα]; linarith
  have hα2 : 0 < 1 - α ^ 2 := by nlinarith
  obtain ⟨q, hq⟩ := exists_nat_ge (max 3 (max (16 / (1 - r) ^ 2) (2 / (1 - α ^ 2))))
  have hq3 : (3 : ℝ) ≤ q := le_trans (le_max_left _ _) hq
  have hq16 : 16 / (1 - r) ^ 2 ≤ q :=
    le_trans (le_trans (le_max_left _ _) (le_max_right _ _)) hq
  have hq2 : 2 / (1 - α ^ 2) ≤ q :=
    le_trans (le_trans (le_max_right _ _) (le_max_right _ _)) hq
  have hqpos : (0 : ℝ) < q := by linarith
  have h1r : 0 < 1 - r := by linarith
  have hsqq : 2 / Real.sqrt q ≤ α - r := by
    have h4 : 4 / (1 - r) ≤ Real.sqrt q := by
      rw [Real.le_sqrt (by positivity) hqpos.le, div_pow]
      norm_num
      linarith
    rw [div_le_iff₀ h1r] at h4
    rw [div_le_iff₀ (Real.sqrt_pos.2 hqpos), hα]
    nlinarith
  have hq2' : 2 ≤ q * (1 - α ^ 2) := by rwa [div_le_iff₀ hα2] at hq2
  set κ : ℝ := (q - 1) / (α ^ 2 * q) with hκ
  have hκ1 : 0 < κ - 1 := by
    rw [hκ, sub_pos, one_lt_div (by positivity)]
    nlinarith
  set C : ℝ := 1 + 1 / (κ - 1) with hC
  have hlogq : 1 < Real.log q :=
    lil_one_lt_log_three.trans_le (Real.log_le_log (by norm_num) hq3)
  set K : ℝ := (Real.sqrt (2 * Real.pi))⁻¹ * Real.exp (-C / 2) / Real.log q with hK
  have hK0 : 0 < K := by rw [hK]; positivity
  -- the times and the increments
  set qN : ℝ≥0 := (q : ℝ≥0) with hqN
  have hqN1 : 1 ≤ qN := by
    rw [hqN]; exact_mod_cast (show 1 ≤ q by exact_mod_cast (by linarith : (1 : ℝ) ≤ q))
  set τ : ℕ → ℝ≥0 := fun n ↦ qN ^ n with hτ
  have hτcoe : ∀ n, ((τ n : ℝ≥0) : ℝ) = (q : ℝ) ^ n := fun n ↦ by simp [hτ, hqN]
  have hτmono : Monotone τ := fun i j hij ↦ pow_le_pow_right₀ hqN1 hij
  set Z : ℕ → Ω → ℝ := fun n ω ↦ B (τ (n + 1)) ω - B (τ n) ω with hZ
  have hind : iIndepFun Z P := hB.toIsPreBrownianReal.hasIndepIncrements.nat hτmono
  set a : ℕ → ℝ := fun n ↦
    α * Real.sqrt (2 * (τ (n + 1) : ℝ) * Real.log (Real.log (τ (n + 1)))) with ha
  -- the lower bound on each probability
  have hPF : ∀ n : ℕ, ENNReal.ofReal (K / ((n : ℝ) + 1)) ≤ P {ω | a n ≤ Z n ω} := by
    intro n
    set v : ℝ≥0 := nndist (τ (n + 1)).1 (τ n).1 with hv
    have hvcoe : (v : ℝ) = (q : ℝ) ^ n * (q - 1) := by
      rw [hv, coe_nndist, Real.dist_eq]
      simp only [NNReal.val_eq_coe, hτcoe]
      rw [abs_of_nonneg (sub_nonneg.2 (pow_le_pow_right₀ (by linarith) (Nat.le_add_right n 1)))]
      ring
    have hvpos : (0 : ℝ) < v := by rw [hvcoe]; nlinarith [pow_pos hqpos n]
    have hv0 : v ≠ 0 := by
      intro h; rw [h] at hvpos; simp at hvpos
    have hlaw := hB.hasLaw_sub (τ (n + 1)) (τ n)
    have hlogτ : Real.log (τ (n + 1)) = ((n : ℝ) + 1) * Real.log q := by
      rw [hτcoe, Real.log_pow]; push_cast; ring
    have hL1 : 1 ≤ ((n : ℝ) + 1) * Real.log q := by nlinarith
    set L := Real.log (((n : ℝ) + 1) * Real.log q) with hL
    have hL0 : 0 ≤ L := Real.log_nonneg hL1
    have ha0 : 0 ≤ a n := by
      simp only [ha]; positivity
    have hasq : (a n) ^ 2 = α ^ 2 * (2 * (q : ℝ) ^ (n + 1) * L) := by
      simp only [ha]
      rw [mul_pow, Real.sq_sqrt (mul_nonneg (by positivity) (by rw [hlogτ]; exact hL0)),
        hlogτ, hτcoe]
    set x := a n / Real.sqrt v with hx
    have hx0 : 0 ≤ x := by positivity
    have hxsq : κ * x ^ 2 = 2 * L := by
      rw [hx, div_pow, Real.sq_sqrt hvpos.le, hasq, hvcoe, hκ, pow_succ]
      have : (q : ℝ) - 1 ≠ 0 := by linarith
      field_simp
      ring
    have hquad := lil_quad (x := x) hκ1
    rw [show 1 + (κ - 1) = κ by ring, hxsq] at hquad
    have hexp : Real.exp (-C / 2) / (((n : ℝ) + 1) * Real.log q) ≤
        Real.exp (-(x + 1) ^ 2 / 2) := by
      have e1 : Real.exp (-C / 2) / (((n : ℝ) + 1) * Real.log q) = Real.exp (-L - C / 2) := by
        rw [sub_eq_add_neg, Real.exp_add, Real.exp_neg, Real.exp_log (by positivity)]
        ring_nf
      rw [e1]
      apply Real.exp_le_exp.2
      linarith [hC]
    calc ENNReal.ofReal (K / ((n : ℝ) + 1))
        ≤ ENNReal.ofReal ((Real.sqrt (2 * Real.pi))⁻¹ * Real.exp (-(x + 1) ^ 2 / 2)) := by
          apply ENNReal.ofReal_le_ofReal
          have e2 : K / ((n : ℝ) + 1) = (Real.sqrt (2 * Real.pi))⁻¹ *
              (Real.exp (-C / 2) / (((n : ℝ) + 1) * Real.log q)) := by
            rw [hK]; field_simp
          rw [e2]
          gcongr
      _ ≤ gaussianReal 0 v {y | a n ≤ y} := lil_gauss_lower hv0 ha0
      _ = P {ω | a n ≤ Z n ω} := by
          exact (hlaw.measure_eq (p := fun y ↦ a n ≤ y) measurableSet_Ici).symm
  -- measurable versions
  have hZm : ∀ n, AEMeasurable (Z n) P := fun n ↦
    (hB.aemeasurable _).sub (hB.aemeasurable _)
  set Z' : ℕ → Ω → ℝ := fun n ↦ (hZm n).mk (Z n) with hZ'
  have hZ'm : ∀ n, Measurable (Z' n) := fun n ↦ (hZm n).measurable_mk
  have hind' : iIndepFun Z' P := hind.congr fun n ↦ (hZm n).ae_eq_mk
  set F : ℕ → Set Ω := fun n ↦ {ω | a n ≤ Z' n ω} with hF
  have hFm : ∀ n, MeasurableSet (F n) := fun n ↦ measurableSet_le measurable_const (hZ'm n)
  have hFind : iIndepSet F P := by
    rw [iIndepSet_iff_meas_biInter hFm]
    intro S
    exact hind'.measure_inter_preimage_eq_mul S (sets := fun n ↦ Set.Ici (a n))
      (fun _ _ ↦ measurableSet_Ici)
  have hFP : ∀ n, P (F n) = P {ω | a n ≤ Z n ω} := by
    intro n
    apply measure_congr
    filter_upwards [(hZm n).ae_eq_mk] with ω hω
    show (a n ≤ (hZm n).mk (Z n) ω) = (a n ≤ Z n ω)
    rw [← hω]
  have hsum : ∑' n, P (F n) = ⊤ := by
    refine top_le_iff.1 ?_
    rw [← lil_not_summable hK0]
    exact tsum_le_tsum fun n ↦ (hPF n).trans (hFP n).ge
  have hlim := measure_limsup_eq_one hFm hFind hsum
  have hFae : ∀ᵐ ω ∂P, ω ∈ limsup F atTop := by
    rw [ae_iff]
    exact (prob_compl_eq_zero_iff (MeasurableSet.measurableSet_limsup hFm)).2 hlim
  have hUp := lil_upper_bound hB.neg (c := 2) one_lt_two
  have hτtend : Tendsto τ atTop atTop := by
    refine tendsto_pow_atTop_atTop_of_one_lt ?_
    rw [hqN]; exact_mod_cast (show 1 < q by exact_mod_cast (by linarith : (1 : ℝ) < q))
  have hτtend' : Tendsto (fun n ↦ τ (n + 1)) atTop atTop :=
    hτtend.comp (tendsto_add_atTop_nat 1)
  filter_upwards [hFae, ae_all_iff.2 fun n ↦ (hZm n).ae_eq_mk, hUp] with ω h1 h2 h3
  have hfreq : ∃ᶠ n in atTop, a n ≤ Z n ω := by
    refine (mem_limsup_iff_frequently_mem.1 h1).mono fun n hn ↦ ?_
    simp only [hF, Set.mem_ofPred_eq] at hn
    rw [h2 n]; exact hn
  have hev : ∀ᶠ n in atTop, -B (τ n) ω ≤
      2 * Real.sqrt (2 * (τ n : ℝ) * Real.log (Real.log (τ n))) := by
    have := hτtend.eventually h3
    simpa using this
  refine hτtend'.frequently ((hfreq.and_eventually hev).mono fun n hn ↦ ?_)
  obtain ⟨hn1, hn2⟩ := hn
  set h1 := Real.sqrt (2 * (τ (n + 1) : ℝ) * Real.log (Real.log (τ (n + 1)))) with hh1
  set h0 := Real.sqrt (2 * (τ n : ℝ) * Real.log (Real.log (τ n))) with hh0
  have hstep : h0 ≤ h1 / Real.sqrt q := by
    have hτ1 : 1 ≤ ((τ n : ℝ≥0) : ℝ) := by
      rw [hτcoe]; exact one_le_pow₀ (by linarith)
    have := lil_h_step hτ1 (show (1 : ℝ) ≤ q by linarith)
    have e : (q : ℝ) * (τ n : ℝ) = (τ (n + 1) : ℝ) := by
      rw [hτcoe, hτcoe, pow_succ]; ring
    rw [e] at this
    exact this
  have hh1nn : 0 ≤ h1 := Real.sqrt_nonneg _
  have hsq0 : 0 < Real.sqrt q := Real.sqrt_pos.2 hqpos
  have h3' : 2 * h0 ≤ (2 / Real.sqrt q) * h1 := by
    rw [div_mul_eq_mul_div, le_div_iff₀ hsq0]
    rw [le_div_iff₀ hsq0] at hstep
    linarith
  have h4 : (2 / Real.sqrt q) * h1 ≤ (α - r) * h1 := mul_le_mul_of_nonneg_right hsqq hh1nn
  have hZn : Z n ω = B (τ (n + 1)) ω - B (τ n) ω := rfl
  simp only [ha] at hn1
  rw [hZn] at hn1
  rw [← hh1] at hn1
  nlinarith

lemma bzl_approx {Ω ι : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    (m' : MeasurableSpace Ω) (m : ι → MeasurableSpace Ω)
    (hm : ∀ i S, MeasurableSet[m i] S → ∃ S', MeasurableSet[m'] S' ∧ S =ᵐ[P] S')
    {S : Set Ω} (hS : MeasurableSet[⨆ i, m i] S) :
    ∃ S', MeasurableSet[m'] S' ∧ S =ᵐ[P] S' := by
  rw [MeasurableSpace.measurableSet_iSup] at hS
  induction hS with
  | basic s hs => obtain ⟨i, hi⟩ := hs; exact hm i s hi
  | empty => exact ⟨∅, @MeasurableSet.empty _ m', EventuallyEq.rfl⟩
  | compl s _ ih =>
    obtain ⟨S', h1, h2⟩ := ih
    exact ⟨S'ᶜ, h1.compl, h2.compl⟩
  | iUnion f _ ih =>
    choose S' h1 h2 using ih
    exact ⟨⋃ n, S' n, MeasurableSet.iUnion h1, EventuallyEqSet.countable_iUnion h2⟩

lemma bzl_approx_comap {Ω ι : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    (m' : MeasurableSpace Ω) (f g : ι → Ω → ℝ) (hg : ∀ i, Measurable[m'] (g i))
    (hfg : ∀ i, f i =ᵐ[P] g i) :
    ∀ i S, MeasurableSet[MeasurableSpace.comap (f i) inferInstance] S →
      ∃ S', MeasurableSet[m'] S' ∧ S =ᵐ[P] S' := by
  rintro i S ⟨B, hB, rfl⟩
  refine ⟨g i ⁻¹' B, hg i hB, ?_⟩
  filter_upwards [hfg i] with ω hω
  change (f i ω ∈ B) = (g i ω ∈ B)
  rw [hω]

lemma bzl_comap_pi_le {Ω ι : Type*} (f : ι → Ω → ℝ) :
    MeasurableSpace.comap (fun ω i ↦ f i ω) MeasurableSpace.pi ≤
      ⨆ i, MeasurableSpace.comap (f i) inferInstance := by
  rw [MeasurableSpace.pi, MeasurableSpace.comap_iSup]
  refine iSup_mono fun i ↦ ?_
  rw [MeasurableSpace.comap_comp]
  rfl

lemma bzl_limsup_meas {Ω : Type*} (m : MeasurableSpace Ω) (S : ℕ → Set Ω) (k : ℕ)
    (h : ∀ n, k ≤ n → MeasurableSet[m] (S n)) : MeasurableSet[m] (limsup S atTop) := by
  rw [← Filter.limsup_nat_add S k]
  exact @MeasurableSet.measurableSet_limsup _ m _ fun n ↦ h (n + k) (by omega)

lemma bzl_eps_anti {i j : ℕ} (h : i ≤ j) : (1 : ℝ≥0) / (j + 1) ≤ 1 / (i + 1) := by
  gcongr

lemma bzl_zero_one {Ω : Type*} {mΩ : MeasurableSpace Ω}
    {P : Measure Ω} {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P) (A : Set Ω)
    (hA : MeasurableSet[⨅ ε : ℝ≥0, ⨅ (_ : 0 < ε), ⨆ s : ℝ≥0, ⨆ (_ : s ≤ ε),
      MeasurableSpace.comap (W s) (inferInstance : MeasurableSpace ℝ)] A) :
    P A = 0 ∨ P A = 1 := by
  have hprob : IsProbabilityMeasure P := hW.isGaussianProcess.isProbabilityMeasure
  set ε : ℕ → ℝ≥0 := fun n ↦ 1 / (n + 1) with hε
  have hεpos : ∀ n, 0 < ε n := fun n ↦ by positivity
  let V : ℝ≥0 → Ω → ℝ := fun t ↦ (hW.aemeasurable t).mk (W t)
  have hVm : ∀ t, Measurable (V t) := fun t ↦ (hW.aemeasurable t).measurable_mk
  have hWV : ∀ t, W t =ᵐ[P] V t := fun t ↦ (hW.aemeasurable t).ae_eq_mk
  have hV : IsPreBrownianReal V P := hW.toIsPreBrownianReal.congr hWV
  let Fv : ℝ≥0 → MeasurableSpace Ω := fun e ↦
    MeasurableSpace.comap (fun ω (t : Set.Iic e) ↦ V t ω) MeasurableSpace.pi
  have hFv_meas : ∀ e (s : Set.Iic e), Measurable[Fv e] (V s) := fun e s ↦ by
    have := (measurable_pi_apply s).comp
      (comap_measurable (m := MeasurableSpace.pi) (fun ω (t : Set.Iic e) ↦ V t ω))
    exact this
  have hFv_mono : ∀ e e', e ≤ e' → Fv e ≤ Fv e' := by
    intro e e' hee'
    let R : (Set.Iic e' → ℝ) → (Set.Iic e → ℝ) := fun x t ↦ x ⟨t, t.2.trans hee'⟩
    have hR : Measurable R := measurable_pi_iff.2 fun t ↦ measurable_pi_apply _
    have e1 : (fun ω (t : Set.Iic e) ↦ V t ω) = R ∘ (fun ω (t : Set.Iic e') ↦ V t ω) := rfl
    change MeasurableSpace.comap (fun ω (t : Set.Iic e) ↦ V t ω) MeasurableSpace.pi ≤ _
    rw [e1, ← MeasurableSpace.comap_comp]
    exact MeasurableSpace.comap_mono hR.comap_le
  have hFv_le : ∀ e, Fv e ≤ mΩ := fun e ↦
    Measurable.comap_le (measurable_pi_iff.2 fun t ↦ hVm t)
  -- approximate `A` inside each past σ-algebra of `V`
  have hAn : ∀ n, ∃ S, MeasurableSet[Fv (ε n)] S ∧ A =ᵐ[P] S := by
    intro n
    have h1 := MeasurableSpace.measurableSet_iInf.1 hA (ε n)
    have h2 := MeasurableSpace.measurableSet_iInf.1 h1 (hεpos n)
    have h3 : MeasurableSet[⨆ s : Set.Iic (ε n),
        MeasurableSpace.comap (W s) (inferInstance : MeasurableSpace ℝ)] A := by
      refine (iSup₂_le fun s hs ↦ ?_ : (⨆ s : ℝ≥0, ⨆ (_ : s ≤ ε n),
        MeasurableSpace.comap (W s) (inferInstance : MeasurableSpace ℝ)) ≤ _) A h2
      exact le_iSup (fun s : Set.Iic (ε n) ↦
        MeasurableSpace.comap (W s) (inferInstance : MeasurableSpace ℝ)) ⟨s, hs⟩
    exact bzl_approx _ _ (bzl_approx_comap (Fv (ε n)) (fun s : Set.Iic (ε n) ↦ W s)
      (fun s : Set.Iic (ε n) ↦ V s) (hFv_meas (ε n)) (fun s ↦ hWV s)) h3
  choose S hSm hAS using hAn
  set Astar := limsup S atTop with hAstar
  have hA_ae : A =ᵐ[P] Astar := by
    filter_upwards [ae_all_iff.2 hAS] with ω hω
    rw [hAstar]
    apply propext
    rw [Filter.mem_limsup_iff_frequently_mem]
    have : ∀ n, (ω ∈ S n ↔ ω ∈ A) := fun n ↦ by rw [hω n]
    simp_rw [this]
    exact frequently_const.symm
  have hAstarF : ∀ k, MeasurableSet[Fv (ε k)] Astar := fun k ↦
    bzl_limsup_meas _ S k fun n hn ↦ hFv_mono _ _ (bzl_eps_anti hn) _ (hSm n)
  -- the future σ-algebras
  let H : ℕ → MeasurableSpace Ω := fun n ↦
    MeasurableSpace.comap (fun ω (t : ℝ≥0) ↦ V (ε n + t) ω - V (ε n) ω) MeasurableSpace.pi
  have hH_meas : ∀ n t, Measurable[H n] (fun ω ↦ V (ε n + t) ω - V (ε n) ω) := fun n t ↦ by
    have := (measurable_pi_apply t).comp (comap_measurable (m := MeasurableSpace.pi)
      (fun ω (t : ℝ≥0) ↦ V (ε n + t) ω - V (ε n) ω))
    exact this
  have hH_le : ∀ n, H n ≤ mΩ := fun n ↦
    Measurable.comap_le (measurable_pi_iff.2 fun t ↦ (hVm _).sub (hVm _))
  have hH_mono : Monotone H := by
    intro n m hnm
    have hle : ε m ≤ ε n := bzl_eps_anti hnm
    let T : (ℝ≥0 → ℝ) → (ℝ≥0 → ℝ) := fun x t ↦ x (ε n - ε m + t) - x (ε n - ε m)
    have hT : Measurable T := measurable_pi_iff.2 fun t ↦
      (measurable_pi_apply _).sub (measurable_pi_apply _)
    have e1 : (fun ω (t : ℝ≥0) ↦ V (ε n + t) ω - V (ε n) ω) =
        T ∘ (fun ω (t : ℝ≥0) ↦ V (ε m + t) ω - V (ε m) ω) := by
      have h1 : ∀ t, ε m + (ε n - ε m + t) = ε n + t := fun t ↦ by
        rw [← add_assoc, add_tsub_cancel_of_le hle]
      have h2 : ε m + (ε n - ε m) = ε n := add_tsub_cancel_of_le hle
      ext ω t
      simp only [Function.comp_apply, T, h1, h2]
      ring
    change MeasurableSpace.comap (fun ω (t : ℝ≥0) ↦ V (ε n + t) ω - V (ε n) ω)
      MeasurableSpace.pi ≤ _
    rw [e1, ← MeasurableSpace.comap_comp]
    exact MeasurableSpace.comap_mono hT.comap_le
  let G : MeasurableSpace Ω := MeasurableSpace.generateFrom {Astar}
  have hG_le : ∀ n, G ≤ Fv (ε n) := fun n ↦
    MeasurableSpace.generateFrom_le fun s hs ↦ by
      rw [Set.mem_singleton_iff] at hs; rw [hs]; exact hAstarF n
  have hind : ∀ n, Indep (H n) G P := by
    intro n
    have h := hV.indepFun_shift (ε n)
    rw [IndepFun_iff_Indep] at h
    exact indep_of_indep_of_le_right h (hG_le n)
  have hI : Indep (⨆ n, H n) G P :=
    indep_iSup_of_directed_le hind hH_le ((hG_le 0).trans (hFv_le _)) hH_mono.directed_le
  -- `V t` is a.e. a limit of `H`-measurable variables
  let Y : ℝ≥0 → Ω → ℝ := fun t ω ↦ limsup (fun n ↦ V t ω - V (min (ε n) t) ω) atTop
  have hY_meas : ∀ t, Measurable[⨆ n, H n] (Y t) := by
    intro t
    refine Measurable.limsup fun n ↦ ?_
    refine Measurable.mono ?_ (le_iSup H n) le_rfl
    by_cases h : ε n ≤ t
    · have e1 : (fun ω ↦ V t ω - V (min (ε n) t) ω) =
          fun ω ↦ V (ε n + (t - ε n)) ω - V (ε n) ω := by
        rw [min_eq_left h, add_tsub_cancel_of_le h]
      rw [e1]
      exact hH_meas n _
    · have e1 : (fun ω ↦ V t ω - V (min (ε n) t) ω) = fun _ ↦ 0 := by
        rw [min_eq_right (le_of_not_ge h)]
        ext ω; ring
      rw [e1]
      exact measurable_const
  have hεlim : Tendsto ε atTop (nhds 0) := by
    have h : Tendsto (fun n : ℕ ↦ ((ε n : ℝ≥0) : ℝ)) atTop (nhds 0) := by
      refine (tendsto_one_div_add_atTop_nhds_zero_nat).congr fun n ↦ ?_
      simp [hε]
    exact NNReal.tendsto_coe.1 (by simpa using h)
  have hVY : ∀ t, V t =ᵐ[P] Y t := by
    intro t
    have hall : ∀ᵐ ω ∂P, ∀ n, W (min (ε n) t) ω = V (min (ε n) t) ω :=
      ae_all_iff.2 fun n ↦ hWV _
    filter_upwards [hall, hW.cont, hW.eval_zero_ae_eq_zero] with ω hω hc h0
    have hmin : Tendsto (fun n ↦ min (ε n) t) atTop (nhds 0) := by
      have := hεlim.min (tendsto_const_nhds (x := t))
      simpa using this
    have hconv : Tendsto (fun n ↦ V t ω - V (min (ε n) t) ω) atTop (nhds (V t ω)) := by
      have h1 : Tendsto (fun n ↦ W (min (ε n) t) ω) atTop (nhds 0) := by
        have := (hc.tendsto 0).comp hmin
        rw [h0] at this
        exact this
      simp_rw [← hω]
      simpa using (tendsto_const_nhds (x := V t ω)).sub h1
    exact hconv.limsup_eq.symm
  -- approximate `Astar` inside the future σ-algebra
  have hAstar_pi : MeasurableSet[⨆ s : Set.Iic (ε 0),
      MeasurableSpace.comap (V s) (inferInstance : MeasurableSpace ℝ)] Astar :=
    bzl_comap_pi_le (fun s : Set.Iic (ε 0) ↦ V s) _ (hAstarF 0)
  obtain ⟨B, hBm, hB⟩ := bzl_approx _ _ (bzl_approx_comap (⨆ n, H n)
    (fun s : Set.Iic (ε 0) ↦ V s) (fun s ↦ Y s) (fun s ↦ hY_meas s) (fun s ↦ hVY s)) hAstar_pi
  have hmul := (Indep_iff _ _ _).1 hI B Astar hBm
    (MeasurableSpace.measurableSet_generateFrom (Set.mem_singleton _))
  have hBA : P (B ∩ Astar) = P Astar := by
    apply measure_congr
    have := hB.symm.inter (EventuallyEq.rfl : Astar =ᵐ[P] Astar)
    rwa [Set.inter_self] at this
  rw [hBA, measure_congr hB.symm] at hmul
  rw [measure_congr hA_ae]
  rcases eq_or_ne (P Astar) 0 with h | h
  · exact Or.inl h
  · right
    have hfin : P Astar ≠ ⊤ := measure_ne_top _ _
    have := (ENNReal.mul_eq_left h hfin).1 hmul.symm
    exact this

lemma bzl_half {v : ℝ≥0} (hv : v ≠ 0) : gaussianReal 0 v (Set.Ioi 0) = 2⁻¹ := by
  have := nullSingletonClass_gaussianReal (μ := 0) hv
  have hsym : gaussianReal 0 v (Set.Iio 0) = gaussianReal 0 v (Set.Ioi 0) := by
    have h : (gaussianReal 0 v).map (fun x ↦ -x) = gaussianReal 0 v := by
      simpa using gaussianReal_map_neg (μ := 0) (v := v)
    calc gaussianReal 0 v (Set.Iio 0) = (gaussianReal 0 v).map (fun x ↦ -x) (Set.Iio 0) := by
          rw [h]
      _ = gaussianReal 0 v (Set.Ioi 0) := by
        rw [Measure.map_apply measurable_neg measurableSet_Iio]
        congr 1
        ext x
        simp
  have hc := prob_compl_eq_one_sub (μ := gaussianReal 0 v) (measurableSet_Ioi (a := (0 : ℝ)))
  rw [Set.compl_Ioi, ← measure_congr Iio_ae_eq_Iic, hsym] at hc
  have hfin : gaussianReal 0 v (Set.Ioi 0) ≠ ⊤ := measure_ne_top _ _
  apply ENNReal.eq_inv_of_mul_eq_one_left
  have h1 : gaussianReal 0 v (Set.Ioi 0) ≤ 1 := prob_le_one
  rw [mul_two]
  nth_rw 1 [hc]
  exact tsub_add_cancel_of_le h1

lemma bzl_pos {Ω : Type*} {mΩ : MeasurableSpace Ω}
    {P : Measure Ω} {B : ℝ≥0 → Ω → ℝ} (hB : IsBrownianReal B P) :
    ∀ᵐ ω ∂P, ∀ ε : ℝ≥0, 0 < ε → ∃ s ≤ ε, 0 < B s ω := by
  have hprob : IsProbabilityMeasure P := hB.isGaussianProcess.isProbabilityMeasure
  set e : ℕ → ℝ≥0 := fun n ↦ 1 / (n + 1) with he
  have hepos : ∀ n, 0 < e n := fun n ↦ by positivity
  let E : ℕ → Set Ω := fun n ↦ {ω | 0 < B (e n) ω}
  have hEnm : ∀ n, NullMeasurableSet (E n) P := fun n ↦
    nullMeasurableSet_lt aemeasurable_const (hB.aemeasurable _)
  have hEP : ∀ n, P (E n) = 2⁻¹ := fun n ↦ by
    rw [(hB.hasLaw_eval (e n)).measure_eq (p := fun x ↦ 0 < x) measurableSet_Ioi]
    exact bzl_half (hepos n).ne'
  set A := limsup E atTop with hAdef
  have hAgerm : MeasurableSet[⨅ ε : ℝ≥0, ⨅ (_ : 0 < ε), ⨆ s : ℝ≥0, ⨆ (_ : s ≤ ε),
      MeasurableSpace.comap (B s) (inferInstance : MeasurableSpace ℝ)] A := by
    refine MeasurableSpace.measurableSet_iInf.2 fun ε ↦ MeasurableSpace.measurableSet_iInf.2
      fun hε ↦ ?_
    obtain ⟨k, hk⟩ := exists_nat_one_div_lt (NNReal.coe_pos.2 hε)
    refine bzl_limsup_meas _ E k fun n hn ↦ ?_
    have hle : e n ≤ ε := by
      rw [← NNReal.coe_le_coe]
      have : (e n : ℝ) ≤ 1 / ((k : ℝ) + 1) := by
        simp only [he, one_div, NNReal.coe_inv, NNReal.coe_add, NNReal.coe_natCast,
          NNReal.coe_one]
        rw [← one_div, ← one_div]
        gcongr
      linarith
    have h1 : MeasurableSet[MeasurableSpace.comap (B (e n)) (inferInstance : MeasurableSpace ℝ)]
        (E n) := ⟨Set.Ioi 0, measurableSet_Ioi, rfl⟩
    exact (le_iSup₂ (f := fun s (_ : s ≤ ε) ↦
      MeasurableSpace.comap (B s) (inferInstance : MeasurableSpace ℝ)) (e n) hle) _ h1
  have hU : A = ⋂ n, ⋃ i ≥ n, E i := by
    rw [hAdef, Filter.limsup_eq_iInf_iSup_of_nat]
    simp only [Set.iSup_eq_iUnion, Set.iInf_eq_iInter]
  have hUanti : Antitone (fun n ↦ ⋃ i ≥ n, E i) := by
    intro n m hnm ω hω
    simp only [Set.mem_iUnion] at hω ⊢
    obtain ⟨i, hi, h⟩ := hω
    exact ⟨i, hnm.trans hi, h⟩
  have hUnm : ∀ n, NullMeasurableSet (⋃ i ≥ n, E i) P := fun n ↦
    NullMeasurableSet.iUnion fun i ↦ NullMeasurableSet.iUnion fun _ ↦ hEnm i
  have hAnm : NullMeasurableSet A P := by
    rw [hU]; exact NullMeasurableSet.iInter hUnm
  have hApos : P A ≠ 0 := by
    have h1 : P A = ⨅ n, P (⋃ i ≥ n, E i) := by
      rw [hU]; exact hUanti.measure_iInter hUnm ⟨0, measure_ne_top _ _⟩
    have h2 : (2⁻¹ : ℝ≥0∞) ≤ P A := by
      rw [h1]
      refine le_iInf fun n ↦ ?_
      rw [← hEP n]
      refine measure_mono fun ω hω ↦ ?_
      simp only [Set.mem_iUnion]
      exact ⟨n, le_rfl, hω⟩
    intro h0
    rw [h0] at h2
    simp at h2
  have hA1 : P A = 1 := (bzl_zero_one hB A hAgerm).resolve_left hApos
  have hAae : ∀ᵐ ω ∂P, ω ∈ A := by
    rw [ae_iff]
    exact (prob_compl_eq_zero_iff₀ hAnm).2 hA1
  filter_upwards [hAae] with ω hω ε hε
  rw [hU] at hω
  obtain ⟨k, hk⟩ := exists_nat_one_div_lt (NNReal.coe_pos.2 hε)
  have := Set.mem_iInter.1 hω k
  simp only [Set.mem_iUnion] at this
  obtain ⟨i, hi, h⟩ := this
  refine ⟨e i, ?_, h⟩
  rw [← NNReal.coe_le_coe]
  have : (e i : ℝ) ≤ 1 / ((k : ℝ) + 1) := by
    simp only [he, one_div, NNReal.coe_inv, NNReal.coe_add, NNReal.coe_natCast, NNReal.coe_one]
    rw [← one_div, ← one_div]
    gcongr
  linarith

/-- **The law of the iterated logarithm.** For a standard Brownian motion `W` (no drift,
independent normal moves with variance equal to the elapsed time, continuous paths), with
probability one the lim sup, as `t → ∞`, of the position divided by the envelope
`h(t) = √(2 t ln ln t)` is exactly 1:
`limsup_{t → ∞} W_t / √(2 t ln ln t) = 1`.
The lim sup is taken in the extended reals, so it is the true lim sup of the ratio. -/
theorem limsup_brownian_div_sqrt_two_mul_log_log_eq_one {Ω : Type*} {mΩ : MeasurableSpace Ω}
    {P : Measure Ω} {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P) :
    ∀ᵐ ω ∂P, limsup (fun t : ℝ≥0 ↦
      ((W t ω / Real.sqrt (2 * (t : ℝ) * Real.log (Real.log t)) : ℝ) : EReal)) atTop = 1 := by
  have hU : ∀ᵐ ω ∂P, ∀ k : ℕ, ∀ᶠ t : ℝ≥0 in atTop,
      W t ω ≤ (1 + 1 / ((k : ℝ) + 1)) * Real.sqrt (2 * (t : ℝ) * Real.log (Real.log t)) :=
    ae_all_iff.2 fun k ↦ lil_upper_bound hW (by
      have : (0 : ℝ) < 1 / ((k : ℝ) + 1) := by positivity
      linarith)
  have hL : ∀ᵐ ω ∂P, ∀ k : ℕ, ∃ᶠ t : ℝ≥0 in atTop,
      (1 - 1 / ((k : ℝ) + 2)) * Real.sqrt (2 * (t : ℝ) * Real.log (Real.log t)) ≤ W t ω :=
    ae_all_iff.2 fun k ↦ lil_lower_bound hW
      (by
        have : 1 / ((k : ℝ) + 2) < 1 := by
          rw [div_lt_one (by positivity)]; linarith [(Nat.cast_nonneg k : (0 : ℝ) ≤ k)]
        linarith)
      (by
        have : (0 : ℝ) < 1 / ((k : ℝ) + 2) := by positivity
        linarith)
  filter_upwards [hU, hL] with ω hU hL
  have hpos : ∀ᶠ t : ℝ≥0 in atTop, 0 < Real.sqrt (2 * (t : ℝ) * Real.log (Real.log t)) := by
    rw [eventually_atTop]
    refine ⟨3, fun t ht ↦ ?_⟩
    have ht3 : (3 : ℝ) ≤ t := by exact_mod_cast ht
    have hlog : 1 < Real.log t :=
      lil_one_lt_log_three.trans_le (Real.log_le_log (by norm_num) ht3)
    have : 0 < Real.log (Real.log t) := Real.log_pos hlog
    have ht0 : (0 : ℝ) < t := by linarith
    exact Real.sqrt_pos.2 (by positivity)
  apply le_antisymm
  · rw [← EReal.le_of_forall_lt_iff_le]
    intro z hz
    have hz' : (1 : ℝ) < z := by exact_mod_cast hz
    obtain ⟨k, hk⟩ := exists_nat_one_div_lt (sub_pos.2 hz')
    refine Filter.limsup_le_of_le (by isBoundedDefault) ?_
    filter_upwards [hU k, hpos] with t h1 h2
    rw [EReal.coe_le_coe_iff, div_le_iff₀ h2]
    calc W t ω ≤ (1 + 1 / ((k : ℝ) + 1)) * Real.sqrt (2 * (t : ℝ) * Real.log (Real.log t)) := h1
      _ ≤ z * Real.sqrt (2 * (t : ℝ) * Real.log (Real.log t)) := by
          gcongr
          linarith
  · rw [← EReal.ge_of_forall_gt_iff_ge]
    intro z hz
    have hz' : z < 1 := by exact_mod_cast hz
    obtain ⟨k, hk⟩ := exists_nat_one_div_lt (sub_pos.2 hz')
    refine Filter.le_limsup_of_frequently_le ?_ (by isBoundedDefault)
    refine ((hL k).and_eventually hpos).mono fun t ht ↦ ?_
    obtain ⟨h1, h2⟩ := ht
    rw [EReal.coe_le_coe_iff, le_div_iff₀ h2]
    have hk2 : 1 / ((k : ℝ) + 2) ≤ 1 / ((k : ℝ) + 1) := by
      gcongr; linarith
    calc z * Real.sqrt (2 * (t : ℝ) * Real.log (Real.log t))
        ≤ (1 - 1 / ((k : ℝ) + 2)) * Real.sqrt (2 * (t : ℝ) * Real.log (Real.log t)) := by
          gcongr
          linarith
      _ ≤ W t ω := h1

/-- **Blumenthal's zero-one law.** Let `𝓕_ε` be the sigma-algebra of events the path of the
Brownian motion `W` up to time `ε` decides, generated by the positions `W_s`, `s ≤ ε`, and let
the germ field be `𝓕_{0+} = ⋂_{ε > 0} 𝓕_ε`. Every event `A` in the germ field has
`P(A) = 0` or `P(A) = 1`. -/
theorem blumenthal_zero_one_law {Ω : Type*} {mΩ : MeasurableSpace Ω}
    {P : Measure Ω} {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P) (A : Set Ω)
    (hA : MeasurableSet[⨅ ε : ℝ≥0, ⨅ (_ : 0 < ε), ⨆ s : ℝ≥0, ⨆ (_ : s ≤ ε),
      MeasurableSpace.comap (W s) (inferInstance : MeasurableSpace ℝ)] A) :
    P A = 0 ∨ P A = 1 := by
  exact bzl_zero_one hW A hA

/-- **The sign changes at time 0.** With probability one, every opening stretch `[0, ε]` of a
Brownian path, however short, holds a time `s` with `W_s > 0` and a time `u` with `W_u < 0`. -/
theorem brownian_pos_and_neg_in_every_opening_stretch {Ω : Type*} {mΩ : MeasurableSpace Ω}
    {P : Measure Ω} {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P) :
    ∀ᵐ ω ∂P, ∀ ε : ℝ≥0, 0 < ε → (∃ s ≤ ε, 0 < W s ω) ∧ (∃ u ≤ ε, W u ω < 0) := by
  filter_upwards [bzl_pos hW, bzl_pos hW.neg] with ω h1 h2 ε hε
  refine ⟨h1 ε hε, ?_⟩
  obtain ⟨u, hu, h⟩ := h2 ε hε
  exact ⟨u, hu, by simpa using h⟩

-- The typical distance at a million seconds: √1,000,000 = 1,000, since 1,000² = 1,000,000.
example : (1000 : ℕ) ^ 2 = 1000000 := by norm_num

-- Upper half with c = 2 and q = 2: the power λ = c² / q is 2, above 1.
example : ((2 : ℚ) ^ 2 / 2 = 2) ∧ (1 : ℚ) < 2 ^ 2 / 2 := by norm_num

-- Block 20 starts at 2^20 = 1,048,576 seconds.
example : (2 : ℕ) ^ 20 = 1048576 := by norm_num

-- Factor c = 1.1 with blocks of ratio 2: λ = 1.1² / 2 = 0.6050 is below 1, since 2 is not below
-- c² = 1.21; with ratio q = 1.1 it is λ = 1.1² / 1.1 = 1.1, above 1.
example : ((11 / 10 : ℚ) ^ 2 / 2 = 121 / 200) ∧ (121 / 200 : ℚ) < 1 ∧ ¬ ((2 : ℚ) < (11 / 10) ^ 2) := by
  norm_num
example : ((11 / 10 : ℚ) ^ 2 / (11 / 10) = 11 / 10) ∧ (1 : ℚ) < 11 / 10 ∧ (11 / 10 : ℚ) < (11 / 10) ^ 2 := by
  norm_num

-- Lower half with q = 100: block 3 ends at 100^3 = 10^6 seconds.
example : (100 : ℕ) ^ 3 = 10 ^ 6 := by norm_num

#print axioms limsup_brownian_div_sqrt_two_mul_log_log_eq_one
#print axioms blumenthal_zero_one_law
#print axioms brownian_pos_and_neg_in_every_opening_stretch
#print axioms lil_grid_le
#print axioms lil_grid_mono
#print axioms lil_grid_approx
#print axioms lil_mesh
#print axioms lil_max
#print axioms lil_le_sup
#print axioms lil_hit_eventually
#print axioms lil_gauss_symm
#print axioms lil_gauss_small
#print axioms lil_reflect_step
#print axioms lil_first_hit
#print axioms lil_E_nm
#print axioms lil_E_disj
#print axioms lil_sum_reflect
#print axioms lil_disc_upper
#print axioms lil_grid_monotone
#print axioms lil_upper
#print axioms lil_max_tail_le
#print axioms lil_gauss_upper
#print axioms lil_gauss_lower
#print axioms lil_h_mono
#print axioms lil_h_step
#print axioms lil_upper_bound
#print axioms lil_one_lt_log_three
#print axioms lil_quad
#print axioms lil_not_summable
#print axioms lil_lower_bound
#print axioms bzl_approx
#print axioms bzl_approx_comap
#print axioms bzl_comap_pi_le
#print axioms bzl_limsup_meas
#print axioms bzl_eps_anti
#print axioms bzl_zero_one
#print axioms bzl_half
#print axioms bzl_pos
