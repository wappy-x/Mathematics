-- Reflection principle: for a Brownian motion started at 0 and a level a above it, the chance of touching a by time t is twice the chance of being at or above a at time t, so the running maximum has the same law as the distance from the start.
import Mathlib.Probability.BrownianMotion.Basic
import Mathlib.Probability.IdentDistrib

open MeasureTheory ProbabilityTheory
open scoped NNReal ENNReal

lemma rpm_grid_le {t : ℝ≥0} {n k : ℕ} (hk : k ≤ n + 1) : t * k / (n + 1) ≤ t := by
  rw [div_le_iff₀ (by positivity)]
  gcongr
  exact_mod_cast hk

lemma rpm_grid_mono {t : ℝ≥0} {n j k : ℕ} (hjk : j ≤ k) : t * j / (n + 1) ≤ t * k / (n + 1) := by
  gcongr

lemma rpm_grid_dist (t : ℝ≥0) (n j : ℕ) :
    dist (t * ((j + 1 : ℕ) : ℝ≥0) / (n + 1)) (t * (j : ℝ≥0) / (n + 1)) = (t : ℝ) / (n + 1) := by
  rw [NNReal.dist_eq]
  push_cast
  have : (t : ℝ) * (j + 1) / (n + 1) - t * j / (n + 1) = t / (n + 1) := by
    field_simp; ring
  rw [this, abs_of_nonneg (by positivity)]

lemma rpm_grid_approx {t s : ℝ≥0} (hs : s ≤ t) (n : ℕ) :
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
lemma rpm_mesh (t : ℝ≥0) {δ : ℝ} (hδ : 0 < δ) : ∀ᶠ n : ℕ in atTop, (t : ℝ) / (n + 1) < δ := by
  have h := (tendsto_one_div_add_atTop_nhds_zero_nat).const_mul (t : ℝ)
  rw [mul_zero] at h
  filter_upwards [h.eventually (gt_mem_nhds hδ)] with n hn
  have : (t : ℝ) / (n + 1) = t * (1 / ((n : ℝ) + 1)) := by ring
  rw [this]; exact hn

lemma rpm_max {f : ℝ≥0 → ℝ} (hf : Continuous f) (t : ℝ≥0) :
    ∃ s ≤ t, (∀ r ≤ t, f r ≤ f s) ∧ ⨆ r : Set.Iic t, f r = f s := by
  have hc : IsCompact (Set.Iic t) := by
    rw [← Set.Icc_bot]; exact isCompact_Icc
  obtain ⟨s, hs, hmax⟩ := hc.exists_isMaxOn Set.nonempty_Iic hf.continuousOn
  refine ⟨s, hs, fun r hr ↦ hmax hr, le_antisymm ?_ ?_⟩
  · exact ciSup_le fun r ↦ hmax r.2
  · refine le_ciSup (f := fun r : Set.Iic t ↦ f r) ⟨f s, ?_⟩ ⟨s, hs⟩
    rintro _ ⟨r, rfl⟩
    exact hmax r.2

lemma rpm_le_sup {f : ℝ≥0 → ℝ} (hf : Continuous f) {t r : ℝ≥0} (hr : r ≤ t) :
    f r ≤ ⨆ r : Set.Iic t, f r := by
  obtain ⟨s, -, hmax, heq⟩ := rpm_max hf t
  rw [heq]; exact hmax r hr

open Filter in
lemma rpm_hit_eventually {f : ℝ≥0 → ℝ} (hf : Continuous f) (t : ℝ≥0) {a δ : ℝ} (hδ : 0 < δ)
    (ha : a ≤ ⨆ r : Set.Iic t, f r) :
    ∀ᶠ n : ℕ in atTop, ∃ k ≤ n + 1, a - δ ≤ f (t * k / (n + 1)) := by
  obtain ⟨s, hs, -, heq⟩ := rpm_max hf t
  rw [heq] at ha
  obtain ⟨δ', hδ', hcont⟩ := Metric.continuous_iff.1 hf s δ hδ
  filter_upwards [rpm_mesh t hδ'] with n hn
  obtain ⟨k, hk, h1, h2⟩ := rpm_grid_approx hs n
  refine ⟨k, hk, ?_⟩
  have hd : dist (t * k / (n + 1)) s < δ' := by
    rw [NNReal.dist_eq, abs_sub_comm, abs_of_nonneg (by rw [sub_nonneg]; exact_mod_cast h1)]
    linarith
  have := hcont _ hd
  rw [Real.dist_eq] at this
  linarith [abs_lt.1 this]

open Filter in
lemma rpm_overshoot {f : ℝ≥0 → ℝ} (hf : Continuous f) (t : ℝ≥0) {a ε : ℝ} (h0 : f 0 < a)
    (hε : 0 < ε) :
    ∀ᶠ n : ℕ in atTop, ∀ k ≤ n + 1, a ≤ f (t * k / (n + 1)) →
      (∀ j < k, f (t * j / (n + 1)) < a) → f (t * k / (n + 1)) ≤ a + ε := by
  have hc : IsCompact (Set.Icc 0 t) := isCompact_Icc
  obtain ⟨δ, hδ, hu⟩ := Metric.uniformContinuousOn_iff.1
    (hc.uniformContinuousOn_of_continuous hf.continuousOn) ε hε
  filter_upwards [rpm_mesh t hδ] with n hn
  intro k hk hak hj
  rcases k with _ | j
  · rw [Nat.cast_zero, mul_zero, zero_div] at hak; linarith
  have hj' := hj j (by omega)
  have hd := hu (t * ((j + 1 : ℕ) : ℝ≥0) / (n + 1)) ⟨zero_le, rpm_grid_le hk⟩
    (t * (j : ℝ≥0) / (n + 1)) ⟨zero_le, rpm_grid_le (by omega)⟩
    (by rw [rpm_grid_dist]; exact hn)
  rw [Real.dist_eq] at hd
  linarith [abs_lt.1 hd]

lemma rpm_gauss_symm (v : ℝ≥0) (c : ℝ) :
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

lemma rpm_gauss_small {v : ℝ≥0} (hv : v ≠ 0) (x : ℝ) {η : ℝ≥0∞} (hη : 0 < η) :
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

lemma rpm_reflect_step {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
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
  rw [h1, h2, rpm_gauss_symm]

lemma rpm_first_hit (x : ℕ → ℝ) (a : ℝ) {K : ℕ} (h : ∃ k ≤ K, a ≤ x k) :
    ∃ k ≤ K, a ≤ x k ∧ ∀ j < k, x j < a := by
  classical
  refine ⟨Nat.find h, (Nat.find_spec h).1, (Nat.find_spec h).2, fun j hj ↦ ?_⟩
  by_contra hc
  push Not at hc
  exact Nat.find_min h hj ⟨hj.le.trans (Nat.find_spec h).1, hc⟩

lemma rpm_E_nm {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    {B : ℝ≥0 → Ω → ℝ} (hB : IsPreBrownianReal B P) (τ : ℕ → ℝ≥0) (a : ℝ) (k : ℕ) :
    NullMeasurableSet {ω | a ≤ B (τ k) ω ∧ ∀ j < k, B (τ j) ω < a} P := by
  have : {ω | a ≤ B (τ k) ω ∧ ∀ j < k, B (τ j) ω < a} =
      {ω | a ≤ B (τ k) ω} ∩ ⋂ j : Fin k, {ω | B (τ j) ω < a} := by
    ext ω; simp [Fin.forall_iff]
  rw [this]
  exact (nullMeasurableSet_le aemeasurable_const (hB.aemeasurable _)).inter
    (NullMeasurableSet.iInter fun j ↦ nullMeasurableSet_lt (hB.aemeasurable _) aemeasurable_const)

lemma rpm_E_disj {Ω : Type*} (B : ℝ≥0 → Ω → ℝ) (τ : ℕ → ℝ≥0) (a : ℝ) {i j : ℕ} (hij : i ≠ j)
    (X Y : Set Ω) :
    Disjoint ({ω | a ≤ B (τ i) ω ∧ ∀ l < i, B (τ l) ω < a} ∩ X)
      ({ω | a ≤ B (τ j) ω ∧ ∀ l < j, B (τ l) ω < a} ∩ Y) := by
  rw [Set.disjoint_left]
  rintro ω ⟨⟨hi1, hi2⟩, -⟩ ⟨⟨hj1, hj2⟩, -⟩
  rcases lt_or_gt_of_ne hij with h | h
  · linarith [hj2 i h]
  · linarith [hi2 j h]

lemma rpm_sum_reflect {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
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
    exact rpm_reflect_step hB ((hmono hkK).trans hτ) S hS c
  · intro i _ j _ hij
    exact (rpm_E_disj B τ a hij _ _).aedisjoint
  · intro k _
    exact (rpm_E_nm hB τ a k).inter (nullMeasurableSet_le aemeasurable_const (by fun_prop))
  · intro i _ j _ hij
    exact (rpm_E_disj B τ a hij _ _).aedisjoint
  · intro k _
    exact (rpm_E_nm hB τ a k).inter (nullMeasurableSet_le (by fun_prop) aemeasurable_const)

lemma rpm_disc_upper {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    {B : ℝ≥0 → Ω → ℝ} (hB : IsPreBrownianReal B P) {τ : ℕ → ℝ≥0} (hmono : Monotone τ)
    {t : ℝ≥0} {K : ℕ} (hτ : τ K ≤ t) (a b : ℝ) :
    P ({ω | ∃ k ≤ K, a ≤ B (τ k) ω} ∩ {ω | B t ω ≤ b}) ≤ P {ω | 2 * a - b ≤ B t ω} := by
  calc P ({ω | ∃ k ≤ K, a ≤ B (τ k) ω} ∩ {ω | B t ω ≤ b})
      ≤ P (⋃ k ∈ Finset.range (K + 1), {ω | a ≤ B (τ k) ω ∧ ∀ j < k, B (τ j) ω < a} ∩
        {ω | B t ω - B (τ k) ω ≤ -(a - b)}) := by
        apply measure_mono
        rintro ω ⟨hex, hb⟩
        obtain ⟨k, hk, h1, h2⟩ := rpm_first_hit (fun k ↦ B (τ k) ω) a hex
        simp only [Set.mem_iUnion, Finset.mem_range, Set.mem_inter_iff, Set.mem_ofPred_eq]
        refine ⟨k, by omega, ⟨h1, h2⟩, ?_⟩
        simp only [Set.mem_ofPred_eq] at hb
        linarith
    _ = P (⋃ k ∈ Finset.range (K + 1), {ω | a ≤ B (τ k) ω ∧ ∀ j < k, B (τ j) ω < a} ∩
        {ω | a - b ≤ B t ω - B (τ k) ω}) := rpm_sum_reflect hB hmono hτ a (a - b)
    _ ≤ P {ω | 2 * a - b ≤ B t ω} := by
        apply measure_mono
        intro ω hω
        simp only [Set.mem_iUnion, Finset.mem_range, Set.mem_inter_iff, Set.mem_ofPred_eq] at hω
        obtain ⟨k, -, ⟨h1, -⟩, h3⟩ := hω
        simp only [Set.mem_ofPred_eq]
        linarith

lemma rpm_disc_lower {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    {B : ℝ≥0 → Ω → ℝ} (hB : IsPreBrownianReal B P) {τ : ℕ → ℝ≥0} (hmono : Monotone τ)
    {t : ℝ≥0} {K : ℕ} (hτ : τ K = t) {a b ε : ℝ} (hb : b ≤ a + ε) :
    P {ω | 2 * a - b + ε ≤ B t ω} ≤
      P ({ω | ∃ k ≤ K, a ≤ B (τ k) ω} ∩ {ω | B t ω ≤ b + ε}) +
        2 * P (⋃ k ∈ Finset.range (K + 1), {ω | a ≤ B (τ k) ω ∧ ∀ j < k, B (τ j) ω < a} ∩
          {ω | a + ε < B (τ k) ω}) := by
  set Bad := ⋃ k ∈ Finset.range (K + 1), {ω | a ≤ B (τ k) ω ∧ ∀ j < k, B (τ j) ω < a} ∩
          {ω | a + ε < B (τ k) ω} with hBad
  calc P {ω | 2 * a - b + ε ≤ B t ω}
      ≤ P ((⋃ k ∈ Finset.range (K + 1), {ω | a ≤ B (τ k) ω ∧ ∀ j < k, B (τ j) ω < a} ∩
        {ω | a - b ≤ B t ω - B (τ k) ω}) ∪ Bad) := by
        apply measure_mono
        intro ω hω
        simp only [Set.mem_ofPred_eq] at hω
        have hex : ∃ k ≤ K, a ≤ B (τ k) ω := ⟨K, le_rfl, by rw [hτ]; linarith⟩
        obtain ⟨k, hk, h1, h2⟩ := rpm_first_hit (fun k ↦ B (τ k) ω) a hex
        by_cases hc : B (τ k) ω ≤ a + ε
        · left
          simp only [Set.mem_iUnion, Finset.mem_range, Set.mem_inter_iff, Set.mem_ofPred_eq]
          exact ⟨k, by omega, ⟨h1, h2⟩, by linarith⟩
        · right
          simp only [hBad, Set.mem_iUnion, Finset.mem_range, Set.mem_inter_iff, Set.mem_ofPred_eq]
          exact ⟨k, by omega, ⟨h1, h2⟩, by linarith⟩
    _ ≤ P (⋃ k ∈ Finset.range (K + 1), {ω | a ≤ B (τ k) ω ∧ ∀ j < k, B (τ j) ω < a} ∩
        {ω | a - b ≤ B t ω - B (τ k) ω}) + P Bad := measure_union_le _ _
    _ = P (⋃ k ∈ Finset.range (K + 1), {ω | a ≤ B (τ k) ω ∧ ∀ j < k, B (τ j) ω < a} ∩
        {ω | B t ω - B (τ k) ω ≤ -(a - b)}) + P Bad := by
        rw [rpm_sum_reflect hB hmono hτ.le a (a - b)]
    _ ≤ P (({ω | ∃ k ≤ K, a ≤ B (τ k) ω} ∩ {ω | B t ω ≤ b + ε}) ∪ Bad) + P Bad := by
        gcongr
        intro ω hω
        simp only [Set.mem_iUnion, Finset.mem_range, Set.mem_inter_iff, Set.mem_ofPred_eq] at hω
        obtain ⟨k, hk, ⟨h1, h2⟩, h3⟩ := hω
        by_cases hc : B (τ k) ω ≤ a + ε
        · left
          exact ⟨⟨k, by omega, h1⟩, by simp only [Set.mem_ofPred_eq]; linarith⟩
        · right
          simp only [hBad, Set.mem_iUnion, Finset.mem_range, Set.mem_inter_iff, Set.mem_ofPred_eq]
          exact ⟨k, hk, ⟨h1, h2⟩, by linarith⟩
    _ ≤ P ({ω | ∃ k ≤ K, a ≤ B (τ k) ω} ∩ {ω | B t ω ≤ b + ε}) + P Bad + P Bad := by
        gcongr; exact measure_union_le _ _
    _ = _ := by rw [two_mul, add_assoc]

lemma rpm_grid_monotone (t : ℝ≥0) (n : ℕ) : Monotone (fun k : ℕ ↦ t * k / (n + 1)) :=
  fun _ _ h ↦ rpm_grid_mono h

lemma rpm_grid_last (t : ℝ≥0) (n : ℕ) : t * ((n + 1 : ℕ) : ℝ≥0) / (n + 1) = t := by
  push_cast
  rw [mul_div_assoc, div_self (by positivity), mul_one]

lemma rpm_upper {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    {B : ℝ≥0 → Ω → ℝ} (hB : IsBrownianReal B P) {t : ℝ≥0} (ht : t ≠ 0) (a b : ℝ) :
    P {ω | a ≤ (⨆ s : Set.Iic t, B s ω) ∧ B t ω ≤ b} ≤ P {ω | 2 * a - b ≤ B t ω} := by
  refine ENNReal.le_of_forall_pos_le_add fun η hη _ ↦ ?_
  obtain ⟨δ, hδ, hν⟩ := rpm_gauss_small ht (2 * a - b) (η := η) (by exact_mod_cast hη)
  have hlaw := hB.hasLaw_eval t
  let A : ℕ → Set Ω := fun N ↦
    {ω | ∀ n ≥ N, ∃ k ≤ n + 1, a - δ / 2 ≤ B (t * k / (n + 1)) ω} ∩ {ω | B t ω ≤ b}
  have hA : Monotone A := by
    intro N N' h ω hω
    exact ⟨fun n hn ↦ hω.1 n (h.trans hn), hω.2⟩
  calc P {ω | a ≤ (⨆ s : Set.Iic t, B s ω) ∧ B t ω ≤ b} ≤ P (⋃ N, A N) := by
        apply measure_mono_ae
        filter_upwards [hB.cont] with ω hω hmem
        obtain ⟨N, hN⟩ := (rpm_hit_eventually hω t (half_pos hδ) hmem.1).exists_forall_of_atTop
        exact Set.mem_iUnion.2 ⟨N, fun n hn ↦ hN n hn, hmem.2⟩
    _ = ⨆ N, P (A N) := hA.measure_iUnion
    _ ≤ P {ω | 2 * a - b ≤ B t ω} + η := by
        refine iSup_le fun N ↦ ?_
        calc P (A N) ≤ P ({ω | ∃ k ≤ N + 1, a - δ / 2 ≤ B (t * k / (N + 1)) ω} ∩
              {ω | B t ω ≤ b}) := measure_mono fun ω hω ↦ ⟨hω.1 N le_rfl, hω.2⟩
          _ ≤ P {ω | 2 * (a - δ / 2) - b ≤ B t ω} :=
              rpm_disc_upper hB.toIsPreBrownianReal (rpm_grid_monotone t N)
                (rpm_grid_le le_rfl) _ _
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

lemma rpm_lower {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    {B : ℝ≥0 → Ω → ℝ} (hB : IsBrownianReal B P) {t : ℝ≥0} (ht : t ≠ 0) {a b : ℝ}
    (ha : 0 < a) (hb : b ≤ a) :
    P {ω | 2 * a - b ≤ B t ω} ≤ P {ω | a ≤ (⨆ s : Set.Iic t, B s ω) ∧ B t ω ≤ b} := by
  have hprob := (hB.hasLaw_eval t).isProbabilityMeasure
  refine ENNReal.le_of_forall_pos_le_add fun η hη _ ↦ ?_
  set q : ℝ≥0∞ := ((η / 4 : ℝ≥0) : ℝ≥0∞) with hq
  have hq0 : 0 < q := by rw [hq]; exact_mod_cast div_pos hη (by norm_num)
  obtain ⟨δ1, hδ1, hν1⟩ := rpm_gauss_small ht (2 * a - b) hq0
  obtain ⟨δ2, hδ2, hν2⟩ := rpm_gauss_small ht b hq0
  set ε := min δ1 δ2 with hε
  have hε0 : 0 < ε := lt_min hδ1 hδ2
  have hε1 : ε ≤ δ1 := min_le_left _ _
  have hε2 : ε ≤ δ2 := min_le_right _ _
  let Bad : ℕ → Set Ω := fun n ↦ ⋃ k ∈ Finset.range (n + 1 + 1),
    {ω | a ≤ B (t * k / (n + 1)) ω ∧ ∀ j < k, B (t * j / (n + 1)) ω < a} ∩
      {ω | a + ε < B (t * k / (n + 1)) ω}
  let V : ℕ → Set Ω := fun N ↦ ⋃ n, ⋃ (_ : N ≤ n), Bad n
  have hVanti : Antitone V := by
    intro N N' h ω hω
    simp only [V, Set.mem_iUnion] at hω ⊢
    obtain ⟨n, hn, h'⟩ := hω
    exact ⟨n, h.trans hn, h'⟩
  have hm := hB.aemeasurable
  have hBad_nm : ∀ n, NullMeasurableSet (Bad n) P := fun n ↦
    NullMeasurableSet.iUnion fun k ↦ NullMeasurableSet.iUnion fun _ ↦
      (rpm_E_nm hB.toIsPreBrownianReal (fun k : ℕ ↦ t * k / (n + 1)) a k).inter
        (nullMeasurableSet_lt aemeasurable_const (hm _))
  have hV_nm : ∀ N, NullMeasurableSet (V N) P := fun N ↦
    NullMeasurableSet.iUnion fun n ↦ NullMeasurableSet.iUnion fun _ ↦ hBad_nm n
  have hVlim : P (⋂ N, V N) = 0 := by
    rw [measure_eq_zero_iff_ae_notMem]
    filter_upwards [hB.cont, hB.eval_zero_ae_eq_zero] with ω hω h0
    have h0' : (fun s ↦ B s ω) 0 < a := by simp only [h0]; exact ha
    obtain ⟨N, hN⟩ := (rpm_overshoot hω t h0' hε0).exists_forall_of_atTop
    intro hmem
    have := Set.mem_iInter.1 hmem N
    simp only [V, Bad, Set.mem_iUnion, Finset.mem_range, Set.mem_inter_iff,
      Set.mem_ofPred_eq] at this
    obtain ⟨n, hn, k, hk, ⟨h1, h2⟩, h3⟩ := this
    have := hN n hn k (by omega) h1 h2
    linarith
  have ht' := tendsto_measure_iInter_atTop hV_nm hVanti ⟨0, measure_ne_top _ _⟩
  rw [hVlim] at ht'
  obtain ⟨N, hN⟩ := (ht'.eventually (gt_mem_nhds hq0)).exists
  have hBadN : P (Bad N) ≤ q := by
    refine (measure_mono fun ω hω ↦ ?_).trans hN.le
    simp only [V, Set.mem_iUnion]
    exact ⟨N, le_rfl, hω⟩
  have hlaw := hB.hasLaw_eval t
  have h4 : q + 2 * q + q = η := by
    rw [hq]
    have : (η / 4 : ℝ≥0) + 2 * (η / 4) + η / 4 = η := by
      rw [← NNReal.coe_inj]; push_cast; ring
    exact_mod_cast this
  calc P {ω | 2 * a - b ≤ B t ω}
      ≤ P ({ω | 2 * a - b + ε ≤ B t ω} ∪
          {ω | B t ω ∈ Set.Icc (2 * a - b - δ1) (2 * a - b + δ1)}) := by
        apply measure_mono
        intro ω hω
        simp only [Set.mem_ofPred_eq, Set.mem_union, Set.mem_Icc] at hω ⊢
        by_cases hc : 2 * a - b + ε ≤ B t ω
        · exact Or.inl hc
        · right; constructor <;> linarith
    _ ≤ P {ω | 2 * a - b + ε ≤ B t ω} + q := by
        refine (measure_union_le _ _).trans ?_
        gcongr
        rw [hlaw.measure_eq (p := fun x ↦ x ∈ Set.Icc (2 * a - b - δ1) (2 * a - b + δ1))
          measurableSet_Icc, Set.ofPred_mem_eq]
        exact hν1.le
    _ ≤ (P ({ω | ∃ k ≤ N + 1, a ≤ B (t * k / (N + 1)) ω} ∩ {ω | B t ω ≤ b + ε}) +
          2 * P (Bad N)) + q := by
        gcongr
        exact rpm_disc_lower hB.toIsPreBrownianReal (rpm_grid_monotone t N)
          (rpm_grid_last t N) (by linarith)
    _ ≤ ((P {ω | a ≤ (⨆ s : Set.Iic t, B s ω) ∧ B t ω ≤ b} + q) + 2 * q) + q := by
        gcongr
        calc P ({ω | ∃ k ≤ N + 1, a ≤ B (t * k / (N + 1)) ω} ∩ {ω | B t ω ≤ b + ε})
            ≤ P ({ω | a ≤ (⨆ s : Set.Iic t, B s ω) ∧ B t ω ≤ b} ∪
                {ω | B t ω ∈ Set.Icc (b - δ2) (b + δ2)}) := by
              apply measure_mono_ae
              filter_upwards [hB.cont] with ω hω hmem
              obtain ⟨⟨k, hk, hak⟩, hbt⟩ := hmem
              simp only [Set.mem_ofPred_eq, Set.mem_union, Set.mem_Icc] at hbt ⊢
              by_cases hc : B t ω ≤ b
              · exact Or.inl ⟨hak.trans (rpm_le_sup hω (rpm_grid_le hk)), hc⟩
              · right; constructor <;> linarith
          _ ≤ P {ω | a ≤ (⨆ s : Set.Iic t, B s ω) ∧ B t ω ≤ b} + q := by
              refine (measure_union_le _ _).trans ?_
              gcongr
              rw [hlaw.measure_eq (p := fun x ↦ x ∈ Set.Icc (b - δ2) (b + δ2))
                measurableSet_Icc, Set.ofPred_mem_eq]
              exact hν2.le
    _ = P {ω | a ≤ (⨆ s : Set.Iic t, B s ω) ∧ B t ω ≤ b} + (q + 2 * q + q) := by ring
    _ = _ := by rw [h4]

lemma rpm_joint {Ω : Type*} {mΩ : MeasurableSpace Ω}
    {P : Measure Ω} {B : ℝ≥0 → Ω → ℝ} (hB : IsBrownianReal B P) (t : ℝ≥0) {a b : ℝ}
    (ha : 0 < a) (hb : b ≤ a) :
    P {ω | a ≤ (⨆ s : Set.Iic t, B s ω) ∧ B t ω ≤ b} = P {ω | 2 * a - b ≤ B t ω} := by
  rcases eq_or_ne t 0 with ht | ht
  · subst ht
    have h1 : P {ω | a ≤ (⨆ s : Set.Iic (0 : ℝ≥0), B s ω) ∧ B 0 ω ≤ b} = 0 := by
      rw [measure_eq_zero_iff_ae_notMem]
      filter_upwards [hB.cont, hB.eval_zero_ae_eq_zero] with ω hω h0 hmem
      obtain ⟨s, hs, -, heq⟩ := rpm_max hω 0
      have hs0 : s = 0 := le_antisymm hs zero_le
      have := hmem.1
      rw [heq, hs0, h0] at this
      linarith
    have h2 : P {ω | 2 * a - b ≤ B 0 ω} = 0 := by
      rw [measure_eq_zero_iff_ae_notMem]
      filter_upwards [hB.eval_zero_ae_eq_zero] with ω h0 hmem
      simp only [h0] at hmem
      linarith
    rw [h1, h2]
  · exact le_antisymm (rpm_upper hB ht a b) (rpm_lower hB ht ha hb)

lemma rpm_touch {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    {B : ℝ≥0 → Ω → ℝ} (hB : IsBrownianReal B P) (t : ℝ≥0) {a : ℝ} (ha : 0 < a) :
    P {ω | a ≤ ⨆ s : Set.Iic t, B s ω} = P {ω | ∃ s ≤ t, B s ω = a} := by
  refine measure_congr (Filter.eventuallyEqSet_iff.2 ?_)
  filter_upwards [hB.cont, hB.eval_zero_ae_eq_zero] with ω hω h0
  constructor
  · intro hle
    obtain ⟨s, hs, -, heq⟩ := rpm_max hω t
    rw [heq] at hle
    obtain ⟨r, hr, hfr⟩ := intermediate_value_Icc (zero_le : (0 : ℝ≥0) ≤ s) hω.continuousOn
      ⟨by simp only [h0]; exact ha.le, hle⟩
    exact ⟨r, hr.2.trans hs, hfr⟩
  · rintro ⟨s, hs, hsa⟩
    rw [← hsa]
    exact rpm_le_sup hω hs

lemma rpm_max_tail {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    {B : ℝ≥0 → Ω → ℝ} (hB : IsBrownianReal B P) (t : ℝ≥0) {a : ℝ} (ha : 0 < a) :
    P {ω | a ≤ ⨆ s : Set.Iic t, B s ω} = 2 * P {ω | a ≤ B t ω} := by
  rcases eq_or_ne t 0 with ht | ht
  · subst ht
    have h1 : P {ω | a ≤ ⨆ s : Set.Iic (0 : ℝ≥0), B s ω} = 0 := by
      rw [measure_eq_zero_iff_ae_notMem]
      filter_upwards [hB.cont, hB.eval_zero_ae_eq_zero] with ω hω h0 hmem
      obtain ⟨s, hs, -, heq⟩ := rpm_max hω 0
      have hs0 : s = 0 := le_antisymm hs zero_le
      rw [heq, hs0, h0] at hmem
      linarith
    have h2 : P {ω | a ≤ B 0 ω} = 0 := by
      rw [measure_eq_zero_iff_ae_notMem]
      filter_upwards [hB.eval_zero_ae_eq_zero] with ω h0 hmem
      simp only [h0] at hmem
      linarith
    rw [h1, h2, mul_zero]
  have h3 := rpm_joint hB t ha le_rfl
  have e : 2 * a - a = a := by ring
  rw [e] at h3
  have hlaw := hB.hasLaw_eval t
  have := nullSingletonClass_gaussianReal (μ := 0) ht
  have hatom : P {ω | a < B t ω} = P {ω | a ≤ B t ω} := by
    rw [hlaw.measure_eq (p := fun x ↦ a < x) measurableSet_Ioi,
      hlaw.measure_eq (p := fun x ↦ a ≤ x) measurableSet_Ici]
    exact measure_congr Ioi_ae_eq_Ici
  apply le_antisymm
  · calc P {ω | a ≤ ⨆ s : Set.Iic t, B s ω}
        ≤ P ({ω | a ≤ (⨆ s : Set.Iic t, B s ω) ∧ B t ω ≤ a} ∪ {ω | a < B t ω}) := by
          apply measure_mono
          intro ω hω
          simp only [Set.mem_ofPred_eq, Set.mem_union] at hω ⊢
          by_cases h : B t ω ≤ a
          · exact Or.inl ⟨hω, h⟩
          · exact Or.inr (lt_of_not_ge h)
      _ ≤ P {ω | a ≤ (⨆ s : Set.Iic t, B s ω) ∧ B t ω ≤ a} + P {ω | a < B t ω} :=
          measure_union_le _ _
      _ = 2 * P {ω | a ≤ B t ω} := by rw [h3, hatom, two_mul]
  · calc 2 * P {ω | a ≤ B t ω}
        = P {ω | a ≤ (⨆ s : Set.Iic t, B s ω) ∧ B t ω ≤ a} + P {ω | a < B t ω} := by
          rw [h3, hatom, two_mul]
      _ = P ({ω | a ≤ (⨆ s : Set.Iic t, B s ω) ∧ B t ω ≤ a} ∪ {ω | a < B t ω}) := by
          refine (measure_union₀ (nullMeasurableSet_lt aemeasurable_const (hB.aemeasurable t))
            (Disjoint.aedisjoint (Set.disjoint_left.2 fun ω h1 h2 ↦ ?_))).symm
          simp only [Set.mem_ofPred_eq] at h1 h2
          linarith [h1.2]
      _ ≤ P {ω | a ≤ ⨆ s : Set.Iic t, B s ω} := by
          apply measure_mono_ae
          filter_upwards [hB.cont] with ω hω hmem
          simp only [Set.mem_ofPred_eq, Set.mem_union] at hmem ⊢
          rcases hmem with h | h
          · exact h.1
          · exact h.le.trans (rpm_le_sup hω le_rfl)

lemma rpm_max_aemeasurable {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    {B : ℝ≥0 → Ω → ℝ} (hB : IsBrownianReal B P) (t : ℝ≥0) :
    AEMeasurable (fun ω ↦ ⨆ s : Set.Iic t, B s ω) P := by
  have hrep : (fun ω ↦ ⨆ s : Set.Iic t, B s ω) =ᵐ[P]
      fun ω ↦ ⨆ p : ℕ × ℕ, B (t * ((min p.2 (p.1 + 1) : ℕ) : ℝ≥0) / (p.1 + 1)) ω := by
    filter_upwards [hB.cont] with ω hω
    obtain ⟨s, hs, hmax, heq⟩ := rpm_max hω t
    have hle : ∀ p : ℕ × ℕ, B (t * ((min p.2 (p.1 + 1) : ℕ) : ℝ≥0) / (p.1 + 1)) ω ≤ B s ω :=
      fun p ↦ hmax _ (rpm_grid_le (min_le_right _ _))
    have hbdd : BddAbove (Set.range fun p : ℕ × ℕ ↦
        B (t * ((min p.2 (p.1 + 1) : ℕ) : ℝ≥0) / (p.1 + 1)) ω) := by
      refine ⟨B s ω, ?_⟩
      rintro _ ⟨p, rfl⟩
      exact hle p
    rw [heq]
    apply le_antisymm
    · apply le_of_forall_pos_le_add
      intro δ hδ
      obtain ⟨n, k, hk, hkδ⟩ := (rpm_hit_eventually hω t hδ heq.ge).exists
      have h := le_ciSup hbdd (n, k)
      simp only [min_eq_left hk] at h
      linarith
    · exact ciSup_le hle
  exact (AEMeasurable.iSup fun p ↦ hB.aemeasurable _).congr hrep.symm

/-- Reflection principle. Let `B` be a Brownian motion (started at 0, with continuous paths),
`t` a time and `a > 0` a level. The chance that the running maximum `M_t = sup_{s ≤ t} B_s`
is at least `a` equals the chance that the path touches `a` by time `t`, and both equal twice the
chance of being at or above `a` at time `t`:
`P(M_t ≥ a) = P(τ_a ≤ t) = 2 P(W_t ≥ a)`. -/
theorem touch_prob_eq_two_mul_tail {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    {B : ℝ≥0 → Ω → ℝ} (hB : IsBrownianReal B P) (t : ℝ≥0) {a : ℝ} (ha : 0 < a) :
    P {ω | a ≤ ⨆ s : Set.Iic t, B s ω} = P {ω | ∃ s ≤ t, B s ω = a} ∧
    P {ω | ∃ s ≤ t, B s ω = a} = 2 * P {ω | a ≤ B t ω} := by
  refine ⟨rpm_touch hB t ha, ?_⟩
  rw [← rpm_touch hB t ha]
  exact rpm_max_tail hB t ha

/-- The law of the best so far. For a Brownian motion `B` and a time `t`, the running maximum
`M_t = sup_{s ≤ t} B_s` has the same probability distribution as `|W_t|`, the distance from the
start at time `t`. -/
theorem running_max_identDistrib_abs {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    {B : ℝ≥0 → Ω → ℝ} (hB : IsBrownianReal B P) (t : ℝ≥0) :
    IdentDistrib (fun ω ↦ ⨆ s : Set.Iic t, B s ω) (fun ω ↦ |B t ω|) P P := by
  have hprob := (hB.hasLaw_eval t).isProbabilityMeasure
  have hM := rpm_max_aemeasurable hB t
  have hBt := hB.aemeasurable t
  have habs : AEMeasurable (fun ω ↦ |B t ω|) P := by fun_prop
  refine ⟨hM, habs, ?_⟩
  apply Measure.ext_of_Ici
  intro x
  rw [Measure.map_apply_of_aemeasurable hM measurableSet_Ici,
    Measure.map_apply_of_aemeasurable habs measurableSet_Ici]
  simp only [Set.preimage, Set.mem_Ici]
  rcases le_or_gt x 0 with hx | hx
  · have e1 : {ω | x ≤ |B t ω|} = Set.univ :=
      Set.eq_univ_of_forall fun ω ↦ hx.trans (abs_nonneg _)
    rw [e1]
    refine measure_congr (Filter.eventuallyEqSet_iff.2 ?_)
    filter_upwards [hB.cont, hB.eval_zero_ae_eq_zero] with ω hω h0
    simp only [Set.mem_univ, iff_true]
    have := rpm_le_sup hω (zero_le : (0 : ℝ≥0) ≤ t)
    simp only [h0] at this
    linarith
  · rw [rpm_max_tail hB t hx]
    have e : {ω | x ≤ |B t ω|} = {ω | x ≤ B t ω} ∪ {ω | B t ω ≤ -x} := by
      ext ω
      simp only [Set.mem_ofPred_eq, Set.mem_union, le_abs']
      tauto
    rw [e, measure_union₀ (nullMeasurableSet_le hBt aemeasurable_const)
      (Disjoint.aedisjoint (Set.disjoint_left.2 fun ω h1 h2 ↦ by
        simp only [Set.mem_ofPred_eq] at h1 h2; linarith)), two_mul]
    congr 1
    have hlaw := hB.hasLaw_eval t
    rw [hlaw.measure_eq (p := fun y ↦ y ≤ -x) measurableSet_Iic,
      hlaw.measure_eq (p := fun y ↦ x ≤ y) measurableSet_Ici, rpm_gauss_symm]

/-- The exchange behind the reflection principle (joint law of the maximum and the end).
For a Brownian motion `B`, a time `t`, a level `a > 0` and an ending position `b ≤ a`,
touching `a` by time `t` and ending at or below `b` is as likely as ending at or above
the mirror image `2a - b`: `P(M_t ≥ a, W_t ≤ b) = P(W_t ≥ 2a - b)`. -/
theorem max_ge_and_end_le_eq_tail_reflected {Ω : Type*} {mΩ : MeasurableSpace Ω}
    {P : Measure Ω} {B : ℝ≥0 → Ω → ℝ} (hB : IsBrownianReal B P) (t : ℝ≥0) {a b : ℝ}
    (ha : 0 < a) (hb : b ≤ a) :
    P {ω | a ≤ (⨆ s : Set.Iic t, B s ω) ∧ B t ω ≤ b} = P {ω | 2 * a - b ≤ B t ω} := by
  exact rpm_joint hB t ha hb

-- The card's mirror: level 3, ending position 1, mirror image 2 * 3 - 1 = 5.
example : 2 * 3 - 1 = 5 := by norm_num

-- The card's figure, in tenths of a micrometre: after the first touch of 3 (= 30 tenths),
-- each later point v of the path becomes 60 - v on the mirrored path.
example : [25, 28, 21, 15, 19, 12, 7, 13, 9, 4, 11, 10].map (fun v => 60 - v) =
    [35, 32, 39, 45, 41, 48, 53, 47, 51, 56, 49, 50] := by decide

#print axioms touch_prob_eq_two_mul_tail
#print axioms running_max_identDistrib_abs
#print axioms max_ge_and_end_le_eq_tail_reflected
#print axioms rpm_grid_le
#print axioms rpm_grid_mono
#print axioms rpm_grid_dist
#print axioms rpm_grid_approx
#print axioms rpm_mesh
#print axioms rpm_max
#print axioms rpm_le_sup
#print axioms rpm_hit_eventually
#print axioms rpm_overshoot
#print axioms rpm_gauss_symm
#print axioms rpm_gauss_small
#print axioms rpm_reflect_step
#print axioms rpm_first_hit
#print axioms rpm_E_nm
#print axioms rpm_E_disj
#print axioms rpm_sum_reflect
#print axioms rpm_disc_upper
#print axioms rpm_disc_lower
#print axioms rpm_grid_monotone
#print axioms rpm_grid_last
#print axioms rpm_upper
#print axioms rpm_lower
#print axioms rpm_joint
#print axioms rpm_touch
#print axioms rpm_max_tail
#print axioms rpm_max_aemeasurable
