-- Levy's arcsine laws: the last zero of a Brownian motion before time 1 comes by time s with chance (2/π) arcsin √s, that law has density 1/(π√(s(1 − s))), and in a fair coin game of 2n tosses the last tie falls on day 2k with chance u_{2k} u_{2n−2k}.
import Mathlib
import Mathlib.Probability.BrownianMotion.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.InverseDeriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Data.Fintype.Pi
import Mathlib.Algebra.Order.Field.Rat
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory Finset
open scoped NNReal ENNReal

/-- The last zero `L` of the path `t ↦ B t ω` in the year `[0, 1]`: the latest time `t ≤ 1`
at which the path is at 0 (the last tie). -/
noncomputable def lastZero {Ω : Type*} (B : ℝ≥0 → Ω → ℝ) (ω : Ω) : ℝ≥0 :=
  sSup {t : ℝ≥0 | t ≤ 1 ∧ B t ω = 0}

section asl_brownian

open Real

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

lemma asl_sin_lt_iff {α x : ℝ} (hα0 : 0 < α) (hα : α < π / 2) (hx0 : 0 ≤ x) (hx : x ≤ π / 2) :
    sin x < sin α ↔ x < α :=
  Real.strictMonoOn_sin.lt_iff_lt ⟨by linarith, hx⟩ ⟨by linarith, hα.le⟩

lemma asl_angle_iff {α θ : ℝ} (hα0 : 0 < α) (hα : α < π / 2) (h1 : -π < θ) (h2 : θ < π) :
    sin θ ^ 2 < sin α ^ 2 ↔ θ < -π + α ∨ (-α < θ ∧ θ < α) ∨ π - α < θ := by
  have hsa : 0 < sin α := Real.sin_pos_of_pos_of_lt_pi hα0 (by linarith)
  rw [sq_lt_sq, abs_of_pos hsa]
  have hpi := Real.pi_pos
  rcases le_or_gt θ (-(π / 2)) with h | h
  · -- θ ∈ (-π, -π/2]
    have e : |sin θ| = sin (θ + π) := by
      rw [Real.sin_add_pi, abs_of_nonpos]
      exact Real.sin_nonpos_of_nonpos_of_neg_pi_le (by linarith) (by linarith)
    rw [e, asl_sin_lt_iff hα0 hα (by linarith) (by linarith)]
    constructor
    · intro h'; left; linarith
    · rintro (h' | ⟨h', -⟩ | h') <;> linarith
  rcases le_or_gt θ 0 with h' | h'
  · have e : |sin θ| = sin (-θ) := by
      rw [Real.sin_neg, abs_of_nonpos]
      exact Real.sin_nonpos_of_nonpos_of_neg_pi_le h' (by linarith)
    rw [e, asl_sin_lt_iff hα0 hα (by linarith) (by linarith)]
    constructor
    · intro h''; right; left; constructor <;> linarith
    · rintro (h'' | ⟨h'', -⟩ | h'') <;> linarith
  rcases le_or_gt θ (π / 2) with h'' | h''
  · have e : |sin θ| = sin θ := abs_of_nonneg (Real.sin_nonneg_of_nonneg_of_le_pi h'.le (by linarith))
    rw [e, asl_sin_lt_iff hα0 hα (by linarith) (by linarith)]
    constructor
    · intro h3; right; left; constructor <;> linarith
    · rintro (h3 | ⟨-, h3⟩ | h3) <;> linarith
  · have e : |sin θ| = sin (π - θ) := by
      rw [Real.sin_pi_sub, abs_of_nonneg (Real.sin_nonneg_of_nonneg_of_le_pi h'.le (by linarith))]
    rw [e, asl_sin_lt_iff hα0 hα (by linarith) (by linarith)]
    constructor
    · intro h3; right; right; linarith
    · rintro (h3 | ⟨-, h3⟩ | h3) <;> linarith

lemma asl_angle_measure {α : ℝ} (hα0 : 0 < α) (hα : α < π / 2) :
    volume ({θ : ℝ | sin θ ^ 2 < sin α ^ 2} ∩ Set.Ioo (-π) π) = ENNReal.ofReal (4 * α) := by
  have hpi := Real.pi_pos
  have e : {θ : ℝ | sin θ ^ 2 < sin α ^ 2} ∩ Set.Ioo (-π) π =
      (Set.Ioo (-π) (-π + α) ∪ Set.Ioo (-α) α) ∪ Set.Ioo (π - α) π := by
    ext θ
    simp only [Set.mem_inter_iff, Set.mem_ofPred_eq, Set.mem_Ioo, Set.mem_union]
    constructor
    · rintro ⟨h, h1, h2⟩
      rcases (asl_angle_iff hα0 hα h1 h2).1 h with h3 | h3 | h3
      · exact Or.inl (Or.inl ⟨h1, h3⟩)
      · exact Or.inl (Or.inr h3)
      · exact Or.inr ⟨h3, h2⟩
    · rintro ((⟨h1, h2⟩ | ⟨h1, h2⟩) | ⟨h1, h2⟩)
      · exact ⟨(asl_angle_iff hα0 hα h1 (by linarith)).2 (Or.inl h2), h1, by linarith⟩
      · exact ⟨(asl_angle_iff hα0 hα (by linarith) (by linarith)).2 (Or.inr (Or.inl ⟨h1, h2⟩)),
          by linarith, by linarith⟩
      · exact ⟨(asl_angle_iff hα0 hα (by linarith) h2).2 (Or.inr (Or.inr h1)), by linarith, h2⟩
  rw [e, measure_union _ measurableSet_Ioo, measure_union _ measurableSet_Ioo]
  · simp only [Real.volume_Ioo]
    rw [← ENNReal.ofReal_add (by linarith) (by linarith),
      ← ENNReal.ofReal_add (by linarith) (by linarith)]
    congr 1; ring
  · rw [Set.disjoint_left]
    rintro x ⟨-, h⟩ ⟨h', -⟩; linarith
  · rw [Set.disjoint_left]
    rintro x (⟨-, h⟩ | ⟨-, h⟩) ⟨h', -⟩ <;> linarith

lemma asl_radial :
    ∫ r in Set.Ioi (0 : ℝ), r * exp (-(1 / 2) * r ^ 2) = 1 := by
  have hb : (0 : ℝ) < 1 / 2 := by norm_num
  have A : ∀ x : ℝ, HasDerivAt (fun x => -exp (-(1 / 2) * x ^ 2)) (x * exp (-(1 / 2) * x ^ 2)) x := by
    intro x
    convert (((hasDerivAt_pow 2 x).const_mul (-(1 / 2 : ℝ))).exp).neg using 1
    ring
  have B : Filter.Tendsto (fun x : ℝ => -exp (-(1 / 2) * x ^ 2)) Filter.atTop (nhds (-0)) := by
    refine Filter.Tendsto.neg ?_
    exact tendsto_exp_atBot.comp
      ((Filter.tendsto_pow_atTop two_ne_zero).const_mul_atTop_of_neg (by norm_num))
  rw [integral_Ioi_of_hasDerivAt_of_tendsto' (fun x _ => A x)
    (integrable_mul_exp_neg_mul_sq hb).integrableOn B]
  simp

lemma asl_std_angle {s : ℝ} (hs0 : 0 < s) (hs1 : s < 1) :
    ((gaussianReal 0 1).prod (gaussianReal 0 1)) {p : ℝ × ℝ | p.2 ^ 2 < s * (p.1 ^ 2 + p.2 ^ 2)} =
      ENNReal.ofReal (2 / π * arcsin (√s)) := by
  have hpi := Real.pi_pos
  set α := arcsin (√s) with hαdef
  have hsq0 : 0 < √s := Real.sqrt_pos.2 hs0
  have hsq1 : √s < 1 := by rw [Real.sqrt_lt' one_pos]; simpa using hs1
  have hα0 : 0 < α := Real.arcsin_pos.2 hsq0
  have hα1 : α < π / 2 := by
    rw [hαdef, ← Real.arcsin_one]
    exact Real.arcsin_lt_arcsin (by linarith) hsq1 le_rfl
  have hsinα : sin α ^ 2 = s := by
    rw [hαdef, Real.sin_arcsin (by linarith) hsq1.le, Real.sq_sqrt hs0.le]
  set A : Set (ℝ × ℝ) := {p : ℝ × ℝ | p.2 ^ 2 < s * (p.1 ^ 2 + p.2 ^ 2)} with hAdef
  have hA : MeasurableSet A := measurableSet_lt (by fun_prop) (by fun_prop)
  set T : Set ℝ := {θ : ℝ | sin θ ^ 2 < sin α ^ 2} with hTdef
  have hT : MeasurableSet T := measurableSet_lt (by fun_prop) (by fun_prop)
  set φ : ℝ → ℝ≥0∞ := gaussianPDF 0 1 with hφ
  have hφm : Measurable φ := by fun_prop
  rw [gaussianReal_of_var_ne_zero 0 one_ne_zero, prod_withDensity hφm hφm,
    withDensity_apply _ hA, ← Measure.volume_eq_prod, ← lintegral_indicator hA,
    ← lintegral_comp_polarCoord_symm]
  set G : ℝ → ℝ≥0∞ := fun r => ENNReal.ofReal ((2 * π)⁻¹ * (r * exp (-(1 / 2) * r ^ 2)))
    with hG
  have hcongr : ∀ p ∈ polarCoord.target,
      ENNReal.ofReal p.1 • A.indicator (fun z : ℝ × ℝ => φ z.1 * φ z.2) (polarCoord.symm p) =
        G p.1 * T.indicator 1 p.2 := by
    rintro ⟨r, θ⟩ ⟨hr, -⟩
    simp only [Set.mem_Ioi] at hr
    simp only [polarCoord_symm_apply]
    have hiff : (r * cos θ, r * sin θ) ∈ A ↔ θ ∈ T := by
      simp only [hAdef, hTdef, Set.mem_ofPred_eq, hsinα]
      have : (r * cos θ) ^ 2 + (r * sin θ) ^ 2 = r ^ 2 := by
        rw [mul_pow, mul_pow, ← mul_add, Real.cos_sq_add_sin_sq, mul_one]
      rw [this, mul_pow, mul_comm s]
      exact mul_lt_mul_iff_right₀ (by positivity)
    by_cases hθ : θ ∈ T
    · rw [Set.indicator_of_mem (hiff.2 hθ), Set.indicator_of_mem hθ, Pi.one_apply, mul_one, hG]
      simp only [hφ, gaussianPDF, gaussianPDFReal, smul_eq_mul]
      rw [← ENNReal.ofReal_mul (by positivity), ← ENNReal.ofReal_mul hr.le]
      congr 1
      simp only [NNReal.coe_one, mul_one, sub_zero]
      have h2 : (√(2 * π))⁻¹ * (√(2 * π))⁻¹ = (2 * π)⁻¹ := by
        rw [← mul_inv, Real.mul_self_sqrt (by positivity)]
      have h3 : exp (-(r * cos θ) ^ 2 / 2) * exp (-(r * sin θ) ^ 2 / 2) =
          exp (-(1 / 2) * r ^ 2) := by
        rw [← Real.exp_add]; congr 1
        have := Real.cos_sq_add_sin_sq θ
        linear_combination (-(1 / 2) * r ^ 2) * this
      calc r * ((√(2 * π))⁻¹ * exp (-(r * cos θ) ^ 2 / 2) *
            ((√(2 * π))⁻¹ * exp (-(r * sin θ) ^ 2 / 2)))
          = r * (((√(2 * π))⁻¹ * (√(2 * π))⁻¹) *
            (exp (-(r * cos θ) ^ 2 / 2) * exp (-(r * sin θ) ^ 2 / 2))) := by ring
        _ = _ := by rw [h2, h3]; ring
    · rw [Set.indicator_of_notMem (fun h => hθ (hiff.1 h)), Set.indicator_of_notMem hθ, smul_zero,
        mul_zero]
  rw [setLIntegral_congr_fun (polarCoord.open_target.measurableSet) hcongr]
  rw [polarCoord_target, Measure.volume_eq_prod, ← Measure.prod_restrict,
    lintegral_prod_mul (by fun_prop) (by fun_prop)]
  rw [lintegral_indicator_one hT, Measure.restrict_apply hT, asl_angle_measure hα0 hα1]
  rw [hG, ← ofReal_integral_eq_lintegral_ofReal]
  · rw [integral_const_mul, asl_radial, ← ENNReal.ofReal_mul (by positivity)]
    congr 1
    field_simp
    ring
  · exact ((integrable_mul_exp_neg_mul_sq (by norm_num : (0 : ℝ) < 1 / 2)).integrableOn).const_mul _
  · filter_upwards [ae_restrict_mem measurableSet_Ioi] with r hr
    simp only [Set.mem_Ioi] at hr
    simp only [Pi.zero_apply]
    positivity

lemma asl_scale {s u : ℝ≥0} (hs0 : 0 < s) (hu : 0 < u) (hsu : s + u = 1) :
    ((gaussianReal 0 s).prod (gaussianReal 0 u)) {p : ℝ × ℝ | |p.2| < |p.1|} =
      ENNReal.ofReal (2 / π * arcsin (√(s : ℝ))) := by
  have hsu' : (s : ℝ) + u = 1 := by exact_mod_cast hsu
  have hs0' : (0 : ℝ) < s := hs0
  have hu0' : (0 : ℝ) < u := hu
  have hmap : ∀ v : ℝ≥0, (gaussianReal 0 1).map (fun x => √(v : ℝ) * x) = gaussianReal 0 v := by
    intro v
    rw [gaussianReal_map_const_mul, mul_zero]
    congr 1
    ext
    simp
  rw [← hmap s, ← hmap u, Measure.map_prod_map _ _ (by fun_prop) (by fun_prop),
    Measure.map_apply (by fun_prop) (measurableSet_lt (by fun_prop) (by fun_prop))]
  have e : (Prod.map (fun x => √(s : ℝ) * x) (fun x => √(u : ℝ) * x)) ⁻¹'
      {p : ℝ × ℝ | |p.2| < |p.1|} =
      {p : ℝ × ℝ | p.2 ^ 2 < (s : ℝ) * (p.1 ^ 2 + p.2 ^ 2)} := by
    ext p
    simp only [Set.mem_preimage, Prod.map_fst, Prod.map_snd, Set.mem_ofPred_eq]
    rw [← sq_lt_sq, mul_pow, mul_pow, Real.sq_sqrt hs0'.le, Real.sq_sqrt hu0'.le]
    constructor <;> intro h <;> nlinarith
  rw [e]
  exact asl_std_angle hs0' (by linarith)

lemma asl_lastZero_le_iff {Ω : Type*} (B : ℝ≥0 → Ω → ℝ) (ω : Ω) (s : ℝ≥0) :
    lastZero B ω ≤ s ↔ ∀ t : ℝ≥0, s < t → t ≤ 1 → B t ω ≠ 0 := by
  constructor
  · intro h t hst ht1 hz
    have : t ≤ lastZero B ω := le_csSup ⟨1, fun x hx => hx.1⟩ ⟨ht1, hz⟩
    exact absurd (lt_of_lt_of_le hst (this.trans h)) (lt_irrefl _)
  · intro h
    apply csSup_le'
    rintro t ⟨ht1, hz⟩
    by_contra hc
    push Not at hc
    exact h t hc ht1 hz

lemma asl_path {f : ℝ≥0 → ℝ} (hf : Continuous f) {s u : ℝ≥0} (hsu : s + u = 1) (h0 : f s ≠ 0) :
    (∀ t : ℝ≥0, s < t → t ≤ 1 → f t ≠ 0) ↔
      (0 < f s ∧ (⨆ t : Set.Iic u, -(f (s + t) - f s)) < f s) ∨
      (f s < 0 ∧ (⨆ t : Set.Iic u, (f (s + t) - f s)) < -f s) := by
  have hg : Continuous (fun t => f (s + t)) := hf.comp (continuous_const.add continuous_id)
  constructor
  · intro h
    have hne : ∀ t ≤ u, f (s + t) ≠ 0 := by
      intro t ht
      rcases eq_or_ne t 0 with rfl | ht0
      · simpa using h0
      · refine h (s + t) (lt_add_of_pos_right s (pos_iff_ne_zero.2 ht0)) ?_
        rw [← hsu]; exact (add_le_add_iff_left s).2 ht
    rcases lt_or_gt_of_ne h0 with hneg | hpos
    · right
      refine ⟨hneg, ?_⟩
      have hall : ∀ t ≤ u, f (s + t) < 0 := by
        intro t ht
        by_contra hc
        push Not at hc
        obtain ⟨r, hr, hfr⟩ := intermediate_value_Icc (zero_le : (0 : ℝ≥0) ≤ t) hg.continuousOn
          ⟨by simpa using hneg.le, hc⟩
        exact hne r (hr.2.trans ht) hfr
      obtain ⟨t, ht, -, heq⟩ := rpm_max (f := fun t => f (s + t) - f s)
        (hg.sub continuous_const) u
      rw [heq]; have := hall t ht; linarith
    · left
      refine ⟨hpos, ?_⟩
      have hall : ∀ t ≤ u, 0 < f (s + t) := by
        intro t ht
        by_contra hc
        push Not at hc
        obtain ⟨r, hr, hfr⟩ := intermediate_value_Icc' (zero_le : (0 : ℝ≥0) ≤ t) hg.continuousOn
          ⟨hc, by simpa using hpos.le⟩
        exact hne r (hr.2.trans ht) hfr
      obtain ⟨t, ht, -, heq⟩ := rpm_max (f := fun t => -(f (s + t) - f s))
        (hg.sub continuous_const).neg u
      rw [heq]; have := hall t ht; linarith
  · rintro (⟨hpos, hM⟩ | ⟨hneg, hM⟩) t hst ht1
    · have hle : t - s ≤ u := by rw [tsub_le_iff_left, hsu]; exact ht1
      have := rpm_le_sup (f := fun t => -(f (s + t) - f s)) (hg.sub continuous_const).neg hle
      simp only [add_tsub_cancel_of_le hst.le] at this
      intro hz; rw [hz] at this; linarith
    · have hle : t - s ≤ u := by rw [tsub_le_iff_left, hsu]; exact ht1
      have := rpm_le_sup (f := fun t => f (s + t) - f s) (hg.sub continuous_const) hle
      simp only [add_tsub_cancel_of_le hst.le] at this
      intro hz; rw [hz] at this; linarith

lemma asl_sup_grid {f : ℝ≥0 → ℝ} (hf : Continuous f) (t : ℝ≥0) :
    ⨆ s : Set.Iic t, f s = ⨆ p : ℕ × ℕ, f (t * ((min p.2 (p.1 + 1) : ℕ) : ℝ≥0) / (p.1 + 1)) := by
  obtain ⟨s, hs, hmax, heq⟩ := rpm_max hf t
  have hle : ∀ p : ℕ × ℕ, f (t * ((min p.2 (p.1 + 1) : ℕ) : ℝ≥0) / (p.1 + 1)) ≤ f s :=
    fun p ↦ hmax _ (rpm_grid_le (min_le_right _ _))
  have hbdd : BddAbove (Set.range fun p : ℕ × ℕ ↦
      f (t * ((min p.2 (p.1 + 1) : ℕ) : ℝ≥0) / (p.1 + 1))) := by
    refine ⟨f s, ?_⟩
    rintro _ ⟨p, rfl⟩
    exact hle p
  rw [heq]
  apply le_antisymm
  · apply le_of_forall_pos_le_add
    intro δ hδ
    obtain ⟨n, k, hk, hkδ⟩ := (rpm_hit_eventually hf t hδ heq.ge).exists
    have h := le_ciSup hbdd (n, k)
    simp only [min_eq_left hk] at h
    linarith
  · exact ciSup_le hle

lemma asl_joint_law {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω} [IsProbabilityMeasure P]
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P) (u : ℝ≥0) {X : Ω → ℝ} (hX : AEMeasurable X P)
    (hind : IndepFun (fun ω t ↦ W t ω) X P) {S : Set (ℝ × ℝ)} (hS : MeasurableSet S) :
    P {ω | (X ω, ⨆ t : Set.Iic u, W t ω) ∈ S} =
      ((P.map X).prod ((gaussianReal 0 u).map (fun y ↦ |y|))) S := by
  set g : (ℝ≥0 → ℝ) → ℝ := fun w ↦
    ⨆ p : ℕ × ℕ, w (u * ((min p.2 (p.1 + 1) : ℕ) : ℝ≥0) / (p.1 + 1)) with hg
  have hgm : Measurable g := Measurable.iSup (fun p ↦ measurable_pi_apply _)
  set M : Ω → ℝ := fun ω ↦ g (fun t ↦ W t ω) with hM
  have hMae : (fun ω ↦ ⨆ t : Set.Iic u, W t ω) =ᵐ[P] M := by
    filter_upwards [hW.cont] with ω hω
    exact asl_sup_grid hω u
  have hMm : AEMeasurable M P := AEMeasurable.iSup (fun p ↦ hW.aemeasurable _)
  have hindM : IndepFun M X P := hind.comp hgm measurable_id
  have hlawM : P.map M = (gaussianReal 0 u).map (fun y ↦ |y|) := by
    rw [← Measure.map_congr hMae, (running_max_identDistrib_abs hW u).map_eq,
      ← (hW.hasLaw_eval u).map_eq,
      AEMeasurable.map_map_of_aemeasurable continuous_abs.measurable.aemeasurable
        (hW.aemeasurable u)]
    rfl
  calc P {ω | (X ω, ⨆ t : Set.Iic u, W t ω) ∈ S} = P {ω | (X ω, M ω) ∈ S} := by
        apply measure_congr
        filter_upwards [hMae] with ω hω
        rw [hω]
    _ = (P.map (fun ω ↦ (X ω, M ω))) S :=
        (Measure.map_apply_of_aemeasurable (hX.prodMk hMm) hS).symm
    _ = ((P.map X).prod (P.map M)) S := by
        rw [(indepFun_iff_map_prod_eq_prod_map_map hX hMm).1 hindM.symm]
    _ = _ := by rw [hlawM]

lemma asl_main {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    {B : ℝ≥0 → Ω → ℝ} (hB : IsBrownianReal B P) {s : ℝ≥0} (hs0 : 0 < s) (hs1 : s < 1) :
    P {ω | lastZero B ω ≤ s} = ENNReal.ofReal (2 / π * arcsin (√(s : ℝ))) := by
  have : IsProbabilityMeasure P := hB.isGaussianProcess.isProbabilityMeasure
  set u : ℝ≥0 := 1 - s with hudef
  have hsu : s + u = 1 := add_tsub_cancel_of_le hs1.le
  have hu : 0 < u := tsub_pos_of_lt hs1
  have hW : IsBrownianReal (fun t ω ↦ B (s + t) ω - B s ω) P := hB.shift s
  have hWn : IsBrownianReal (fun t ω ↦ -(B (s + t) ω - B s ω)) P := hW.neg
  have hind := hB.indepFun_shift s
  have hindX : IndepFun (fun ω t ↦ B (s + t) ω - B s ω) (B s) P :=
    hind.comp measurable_id (measurable_pi_apply (⟨s, Set.mem_Iic.2 le_rfl⟩ : Set.Iic s))
  have hindXn : IndepFun (fun ω t ↦ -(B (s + t) ω - B s ω)) (B s) P :=
    hind.comp (show Measurable (fun (w : ℝ≥0 → ℝ) (t : ℝ≥0) ↦ -(w t)) by fun_prop)
      (measurable_pi_apply (⟨s, Set.mem_Iic.2 le_rfl⟩ : Set.Iic s))
  have hlawX : P.map (B s) = gaussianReal 0 s := (hB.hasLaw_eval s).map_eq
  set S1 : Set (ℝ × ℝ) := {p | 0 < p.1 ∧ p.2 < p.1} with hS1def
  set S2 : Set (ℝ × ℝ) := {p | p.1 < 0 ∧ p.2 < -p.1} with hS2def
  have hS1 : MeasurableSet S1 :=
    (measurableSet_lt measurable_const measurable_fst).inter
      (measurableSet_lt measurable_snd measurable_fst)
  have hS2 : MeasurableSet S2 :=
    (measurableSet_lt measurable_fst measurable_const).inter
      (measurableSet_lt measurable_snd measurable_fst.neg)
  have J1 := asl_joint_law hWn u (hB.aemeasurable s) hindXn hS1
  have J2 := asl_joint_law hW u (hB.aemeasurable s) hindX hS2
  rw [hlawX] at J1 J2
  set A1 : Set Ω := {ω | (B s ω, ⨆ t : Set.Iic u, -(B (s + t) ω - B s ω)) ∈ S1} with hA1
  set A2 : Set Ω := {ω | (B s ω, ⨆ t : Set.Iic u, (B (s + t) ω - B s ω)) ∈ S2} with hA2
  have hne : ∀ᵐ ω ∂P, B s ω ≠ 0 := by
    rw [ae_iff]
    have := nullSingletonClass_gaussianReal (μ := 0) hs0.ne'
    simp only [ne_eq, not_not]
    rw [(hB.hasLaw_eval s).measure_eq (p := fun x ↦ x = 0) (measurableSet_singleton 0)]
    exact measure_singleton 0
  have hset : {ω | lastZero B ω ≤ s} =ᵐ[P] A1 ∪ A2 := by
    filter_upwards [hB.cont, hne] with ω hω hne
    rw [asl_lastZero_le_iff, asl_path hω hsu hne]
    rfl
  have hA2m : NullMeasurableSet A2 P :=
    ((hB.aemeasurable s).prodMk (rpm_max_aemeasurable hW u)).nullMeasurableSet_preimage hS2
  have hdisj : Disjoint A1 A2 := by
    rw [Set.disjoint_left]
    rintro ω ⟨h1, -⟩ ⟨h2, -⟩
    simp only at h1 h2
    linarith
  rw [measure_congr hset, measure_union₀ hA2m hdisj.aedisjoint, J1, J2,
    ← measure_union (Set.disjoint_left.2 fun p h1 h2 => by
      simp only [hS1def, hS2def, Set.mem_ofPred_eq] at h1 h2; linarith [h1.1, h2.1]) hS2]
  rw [← Measure.map_id (μ := gaussianReal 0 s),
    Measure.map_prod_map _ _ measurable_id continuous_abs.measurable,
    Measure.map_apply (measurable_id.prodMap continuous_abs.measurable) (hS1.union hS2)]
  have e : Prod.map id (abs : ℝ → ℝ) ⁻¹' (S1 ∪ S2) = {p : ℝ × ℝ | |p.2| < |p.1|} := by
    ext ⟨x, y⟩
    simp only [hS1def, hS2def, Set.mem_preimage, Prod.map_apply, id_eq, Set.mem_union,
      Set.mem_ofPred_eq]
    constructor
    · rintro (⟨h1, h2⟩ | ⟨h1, h2⟩)
      · rw [abs_of_pos h1]; exact h2
      · rw [abs_of_neg h1]; exact h2
    · intro h
      rcases lt_trichotomy x 0 with h1 | h1 | h1
      · right; exact ⟨h1, by rwa [abs_of_neg h1] at h⟩
      · subst h1; simp at h; linarith [abs_nonneg y]
      · left; exact ⟨h1, by rwa [abs_of_pos h1] at h⟩
  rw [e]
  exact asl_scale hs0 hu hsu

end asl_brownian

/-- Levy's arcsine law for the last zero. Let `B` be a Brownian motion: it starts at 0, runs
for the fixed year from time 0 to time 1, and is the limit of a fair game. For every fraction
`s` of the year, `0 ≤ s ≤ 1`, the chance that the last zero `L` comes by time `s` is
`P(L ≤ s) = (2/π) arcsin √s`. -/
theorem last_zero_arcsine_law {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    {B : ℝ≥0 → Ω → ℝ} (hB : IsBrownianReal B P) (s : ℝ≥0) (hs : s ≤ 1) :
    P {ω | lastZero B ω ≤ s} = ENNReal.ofReal (2 / Real.pi * Real.arcsin (Real.sqrt s)) := by
  rcases eq_or_lt_of_le hs with rfl | hs1
  · have e : {ω | lastZero B ω ≤ 1} = Set.univ :=
      Set.eq_univ_of_forall fun ω => (asl_lastZero_le_iff B ω 1).2
        fun t h1 h2 => absurd (lt_of_lt_of_le h1 h2) (lt_irrefl _)
    have : IsProbabilityMeasure P := hB.isGaussianProcess.isProbabilityMeasure
    rw [e, measure_univ]
    simp
  rcases eq_zero_or_pos s with rfl | hs0
  · have hlim : Filter.Tendsto (fun ε : ℝ≥0 => ENNReal.ofReal (2 / Real.pi *
        Real.arcsin (Real.sqrt ε))) (nhdsWithin 0 (Set.Ioi 0))
        (nhds (ENNReal.ofReal (2 / Real.pi * Real.arcsin (Real.sqrt ((0 : ℝ≥0) : ℝ))))) := by
      refine Filter.Tendsto.mono_left (Continuous.tendsto ?_ 0) nhdsWithin_le_nhds
      exact ENNReal.continuous_ofReal.comp (continuous_const.mul
        (Real.continuous_arcsin.comp (Real.continuous_sqrt.comp NNReal.continuous_coe)))
    have := ge_of_tendsto hlim (by
      filter_upwards [Ioo_mem_nhdsGT (zero_lt_one : (0 : ℝ≥0) < 1)] with ε hε
      rw [← asl_main hB hε.1 hε.2]
      exact measure_mono (Set.ofPred_subset_ofPred.2 fun ω (hω : lastZero B ω ≤ 0) => hω.trans hε.1.le))
    refine le_antisymm this ?_
    simp
  · exact asl_main hB hs0 hs1

/-- The arcsine density. For `0 < s < 1` the arcsine law `F(s) = (2/π) arcsin √s` has
derivative `f(s) = 1 / (π √(s (1 − s)))`, the chance per unit of time. -/
theorem arcsine_cdf_hasDerivAt {s : ℝ} (hs0 : 0 < s) (hs1 : s < 1) :
    HasDerivAt (fun x : ℝ => 2 / Real.pi * Real.arcsin (Real.sqrt x))
      (1 / (Real.pi * Real.sqrt (s * (1 - s)))) s := by
  have hsq : 0 < Real.sqrt s := Real.sqrt_pos.2 hs0
  have hsq1 : Real.sqrt s < 1 := by
    rw [Real.sqrt_lt' one_pos]; simpa using hs1
  have h1 := Real.hasDerivAt_sqrt hs0.ne'
  have h2 := (Real.hasDerivAt_arcsin (by linarith) hsq1.ne).comp s h1
  have h3 := h2.const_mul (2 / Real.pi)
  convert h3 using 1
  · rfl
  have hss : Real.sqrt s ^ 2 = s := Real.sq_sqrt hs0.le
  have h1s : 0 < 1 - s := by linarith
  rw [Real.sqrt_mul hs0.le, hss]
  have hpi := Real.pi_pos
  have hq : 0 < Real.sqrt (1 - s) := Real.sqrt_pos.2 h1s
  field_simp

/-- The score of a match `x` of `m` fair coin tosses after the first `j` tosses: +1 for each
toss Ana wins (`true`), −1 for each toss Ben wins (`false`). -/
def coinScore {m : ℕ} (x : Fin m → Bool) (j : ℕ) : ℤ :=
  ∑ i : Fin m, if (i : ℕ) < j then (if x i then 1 else -1) else 0

/-- The last tie of a match of `m` tosses: the latest day `j ≤ m` on which the score is 0
(day 0 always counts, since the game starts at a tie). -/
def lastTie {m : ℕ} (x : Fin m → Bool) : ℕ :=
  ((range (m + 1)).filter (fun j => coinScore x j = 0)).sup id

/-- `u m = C(2m, m) / 4^m`: the chance that a fair coin game is tied on day `2m`. -/
def tieChance (m : ℕ) : ℚ := ((2 * m).choose m : ℚ) / 4 ^ m

lemma asl_score_split {a b : ℕ} (x : Fin (a + b) → Bool) (j : ℕ) :
    coinScore x j = coinScore (fun i : Fin a => x (Fin.castAdd b i)) j +
      coinScore (fun i : Fin b => x (Fin.natAdd a i)) (j - a) := by
  unfold coinScore
  rw [Fin.sum_univ_add]
  congr 1
  apply Finset.sum_congr rfl
  intro i _
  simp only [Fin.val_natAdd]
  split_ifs <;> first | rfl | (exfalso; omega)

lemma asl_score_zero {m : ℕ} (x : Fin m → Bool) : coinScore x 0 = 0 := by
  simp [coinScore]

lemma asl_score_ge {m : ℕ} (x : Fin m → Bool) {j : ℕ} (hj : m ≤ j) :
    coinScore x j = coinScore x m := by
  unfold coinScore
  apply Finset.sum_congr rfl
  intro i _
  simp only [show (i : ℕ) < j by omega, i.2, ↓reduceIte]

lemma asl_score_full {m : ℕ} (y : Fin m → Bool) :
    coinScore y m = 2 * ((univ.filter (fun i => y i = true)).card : ℤ) - m := by
  unfold coinScore
  have h : ∀ i : Fin m, (if (i : ℕ) < m then (if y i then (1 : ℤ) else -1) else 0) =
      2 * (if y i = true then 1 else 0) - 1 := by
    intro i
    simp only [i.2, ↓reduceIte]
    cases y i <;> simp
  rw [Finset.sum_congr rfl (fun i _ => h i), Finset.sum_sub_distrib, ← Finset.mul_sum,
    Finset.sum_boole]
  simp

lemma asl_score_even {m : ℕ} (x : Fin m → Bool) {j : ℕ} (hj : j ≤ m)
    (h : coinScore x j = 0) : Even j := by
  obtain ⟨r, rfl⟩ := Nat.exists_eq_add_of_le hj
  rw [asl_score_split, Nat.sub_self, asl_score_zero, add_zero, asl_score_full] at h
  exact ⟨(univ.filter (fun i : Fin j => x (Fin.castAdd r i) = true)).card, by omega⟩

lemma asl_sup_eq_iff (S : Finset ℕ) (hS : S.Nonempty) (j : ℕ) :
    S.sup id = j ↔ j ∈ S ∧ ∀ y ∈ S, y ≤ j := by
  constructor
  · rintro rfl
    obtain ⟨y, hy, hyeq⟩ := Finset.exists_mem_eq_sup S hS id
    refine ⟨by rw [hyeq]; exact hy, fun z hz => Finset.le_sup (f := id) hz⟩
  · rintro ⟨hj, hle⟩
    exact le_antisymm (Finset.sup_le hle) (Finset.le_sup (f := id) hj)

lemma asl_lastTie_mem {m : ℕ} (x : Fin m → Bool) :
    lastTie x ∈ (range (m + 1)).filter (fun j => coinScore x j = 0) := by
  have hne : ((range (m + 1)).filter (fun j => coinScore x j = 0)).Nonempty :=
    ⟨0, by simp [asl_score_zero]⟩
  obtain ⟨y, hy, hyeq⟩ := Finset.exists_mem_eq_sup _ hne id
  unfold lastTie
  rw [hyeq]; exact hy

lemma asl_lastTie_iff {j r : ℕ} (x : Fin (j + r) → Bool) :
    lastTie x = j ↔ coinScore (fun i : Fin j => x (Fin.castAdd r i)) j = 0 ∧
      ∀ i ∈ Icc (1 : ℕ) r, coinScore (fun i : Fin r => x (Fin.natAdd j i)) i ≠ 0 := by
  have hne : ((range (j + r + 1)).filter (fun j' => coinScore x j' = 0)).Nonempty :=
    ⟨0, by simp [asl_score_zero]⟩
  have hL : ∀ y, coinScore x y = coinScore (fun i : Fin j => x (Fin.castAdd r i)) y +
      coinScore (fun i : Fin r => x (Fin.natAdd j i)) (y - j) := asl_score_split x
  unfold lastTie
  rw [asl_sup_eq_iff _ hne]
  simp only [Finset.mem_filter, Finset.mem_range]
  constructor
  · rintro ⟨⟨-, h0⟩, hle⟩
    have h0' : coinScore (fun i : Fin j => x (Fin.castAdd r i)) j = 0 := by
      rw [hL, Nat.sub_self, asl_score_zero, add_zero] at h0; exact h0
    refine ⟨h0', fun i hi hzero => ?_⟩
    rw [Finset.mem_Icc] at hi
    have := hle (j + i) ⟨by omega, by
      rw [hL, Nat.add_sub_cancel_left, asl_score_ge _ (by omega), h0', hzero, add_zero]⟩
    omega
  · rintro ⟨h0, hnz⟩
    refine ⟨⟨by omega, by rw [hL, Nat.sub_self, asl_score_zero, add_zero]; exact h0⟩, ?_⟩
    rintro y ⟨hy, hyz⟩
    by_contra hcon
    push Not at hcon
    obtain ⟨i, rfl⟩ := Nat.exists_eq_add_of_lt hcon
    rw [hL, asl_score_ge _ (by omega), h0, zero_add,
      show j + i + 1 - j = i + 1 by omega] at hyz
    exact hnz (i + 1) (Finset.mem_Icc.2 ⟨by omega, by omega⟩) hyz

lemma asl_card_lastTie_add (j r : ℕ) :
    (univ.filter (fun x : Fin (j + r) → Bool => lastTie x = j)).card =
      (univ.filter (fun y : Fin j → Bool => coinScore y j = 0)).card *
      (univ.filter (fun z : Fin r → Bool => ∀ i ∈ Icc (1 : ℕ) r, coinScore z i ≠ 0)).card := by
  rw [← Finset.card_product, ← Finset.filter_product]
  refine Finset.card_nbij' (fun x => (fun i => x (Fin.castAdd r i), fun i => x (Fin.natAdd j i)))
    (fun p => Fin.append p.1 p.2) ?_ ?_ ?_ ?_
  · intro x hx
    simp only [Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq] at hx ⊢
    exact ⟨by simp, (asl_lastTie_iff x).1 hx⟩
  · intro p hp
    simp only [Finset.coe_filter, Finset.mem_product, Finset.mem_univ, true_and,
      Set.mem_ofPred_eq] at hp ⊢
    rw [asl_lastTie_iff]
    simp only [Fin.append_left, Fin.append_right]
    exact hp
  · intro x _
    exact Fin.append_castAdd_natAdd
  · intro p _
    simp

lemma asl_card_lastTie (m j : ℕ) (h : j ≤ m) :
    (univ.filter (fun x : Fin m → Bool => lastTie x = j)).card =
      (univ.filter (fun y : Fin j → Bool => coinScore y j = 0)).card *
      (univ.filter (fun z : Fin (m - j) → Bool =>
        ∀ i ∈ Icc (1 : ℕ) (m - j), coinScore z i ≠ 0)).card := by
  obtain ⟨r, rfl⟩ := Nat.exists_eq_add_of_le h
  rw [Nat.add_sub_cancel_left]
  exact asl_card_lastTie_add j r

lemma asl_card_tied (k : ℕ) :
    (univ.filter (fun y : Fin (2 * k) → Bool => coinScore y (2 * k) = 0)).card =
      (2 * k).choose k := by
  have e : univ.filter (fun y : Fin (2 * k) → Bool => coinScore y (2 * k) = 0) =
      univ.filter (fun y : Fin (2 * k) → Bool =>
        (univ.filter (fun i => y i = true)).card = k) := by
    ext y
    simp only [Finset.mem_filter, Finset.mem_univ, true_and, asl_score_full]
    push_cast
    omega
  rw [e, show (2 * k).choose k = (univ : Finset (Fin (2 * k))).card.choose k by simp,
    ← Finset.card_powersetCard, Finset.powersetCard_eq_filter]
  refine Finset.card_nbij' (fun y => univ.filter (fun i => y i = true))
    (fun s i => decide (i ∈ s)) ?_ ?_ ?_ ?_
  · intro y hy
    simp only [Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq,
      Finset.mem_powerset] at hy ⊢
    exact ⟨Finset.subset_univ _, hy⟩
  · intro s hs
    simp only [Finset.coe_filter, Finset.mem_powerset, Finset.mem_univ, true_and,
      Set.mem_ofPred_eq, decide_eq_true_eq] at hs ⊢
    simpa using hs.2
  · intro y _
    funext i
    simp
  · intro s _
    ext i
    simp

lemma asl_sum_lastTie (n : ℕ) :
    ∑ k ∈ range (n + 1), (univ.filter (fun x : Fin (2 * n) → Bool => lastTie x = 2 * k)).card =
      4 ^ n := by
  have hcard : (univ : Finset (Fin (2 * n) → Bool)).card = 4 ^ n := by
    rw [Finset.card_univ, Fintype.card_fun, Fintype.card_bool, Fintype.card_fin, pow_mul]
    norm_num
  rw [← hcard, Finset.card_eq_sum_card_fiberwise (f := fun x => lastTie x / 2)
    (t := range (n + 1))]
  · apply Finset.sum_congr rfl
    intro k _
    congr 1
    ext x
    simp only [Finset.mem_filter, Finset.mem_univ, true_and]
    have hm := asl_lastTie_mem x
    simp only [Finset.mem_filter, Finset.mem_range] at hm
    obtain ⟨r, hr⟩ := asl_score_even x (by omega) hm.2
    omega
  · intro x _
    have hm := asl_lastTie_mem x
    simp only [Finset.mem_filter, Finset.mem_range] at hm
    simp only [Finset.coe_range, Set.mem_Iio]
    omega

lemma asl_conv (a : ℕ → ℚ) (h0 : a 0 = 1)
    (hrec : ∀ k : ℕ, 2 * ((k : ℚ) + 1) * a (k + 1) = (2 * k + 1) * a k) :
    ∀ n, ∑ p ∈ antidiagonal n, a p.1 * a p.2 = 1 := by
  have hT : ∀ n, 2 * ∑ p ∈ antidiagonal n, ((p.1 : ℕ) : ℚ) * a p.1 * a p.2 =
      n * ∑ p ∈ antidiagonal n, a p.1 * a p.2 := by
    intro n
    have hsw : ∑ p ∈ antidiagonal n, ((p.1 : ℕ) : ℚ) * a p.1 * a p.2 =
        ∑ p ∈ antidiagonal n, ((p.2 : ℕ) : ℚ) * a p.1 * a p.2 := by
      rw [← Finset.Nat.sum_antidiagonal_swap]
      apply Finset.sum_congr rfl
      intro p _
      simp only [Prod.fst_swap, Prod.snd_swap]
      ring
    rw [two_mul]
    nth_rewrite 2 [hsw]
    rw [← Finset.sum_add_distrib, Finset.mul_sum]
    apply Finset.sum_congr rfl
    intro p hp
    rw [Finset.HasAntidiagonal.mem_antidiagonal] at hp
    rw [← hp]
    push_cast
    ring
  intro n
  induction n with
  | zero => simp [h0]
  | succ n ih =>
    have key : ((n : ℚ) + 1) * ∑ p ∈ antidiagonal (n + 1), a p.1 * a p.2 = (n + 1) * 1 := by
      have h1 := hT (n + 1)
      rw [Finset.Nat.sum_antidiagonal_succ] at h1
      simp only [Nat.cast_zero, zero_mul, zero_add] at h1
      have h2 : 2 * ∑ p ∈ antidiagonal n, ((p.1 + 1 : ℕ) : ℚ) * a (p.1 + 1) * a p.2 =
          ∑ p ∈ antidiagonal n, (2 * ((p.1 : ℕ) : ℚ) + 1) * a p.1 * a p.2 := by
        rw [Finset.mul_sum]
        apply Finset.sum_congr rfl
        intro p _
        have := hrec p.1
        push_cast
        linear_combination a p.2 * this
      rw [h2] at h1
      have h3 : ∑ p ∈ antidiagonal n, (2 * ((p.1 : ℕ) : ℚ) + 1) * a p.1 * a p.2 =
          2 * ∑ p ∈ antidiagonal n, ((p.1 : ℕ) : ℚ) * a p.1 * a p.2 +
            ∑ p ∈ antidiagonal n, a p.1 * a p.2 := by
        rw [Finset.mul_sum, ← Finset.sum_add_distrib]
        apply Finset.sum_congr rfl
        intro p _
        ring
      rw [h3, hT n, ih] at h1
      push_cast at h1
      linarith
    have hn : (n : ℚ) + 1 ≠ 0 := by positivity
    exact mul_left_cancel₀ hn key

lemma asl_central_conv (n : ℕ) :
    ∑ k ∈ range (n + 1), (2 * k).choose k * (2 * (n - k)).choose (n - k) = 4 ^ n := by
  have h := asl_conv (fun k => ((2 * k).choose k : ℚ) / 4 ^ k) (by simp) (by
    intro k
    have h1 := Nat.succ_mul_centralBinom_succ k
    rw [Nat.centralBinom_eq_two_mul_choose, Nat.centralBinom_eq_two_mul_choose] at h1
    have h1' : ((k : ℚ) + 1) * ((2 * (k + 1)).choose (k + 1) : ℚ) =
        2 * (2 * k + 1) * ((2 * k).choose k : ℚ) := by exact_mod_cast h1
    rw [pow_succ]
    field_simp
    linear_combination 2 * h1') n
  rw [Finset.Nat.sum_antidiagonal_eq_sum_range_succ_mk] at h
  have h2 : ∑ k ∈ range (n + 1), (((2 * k).choose k * (2 * (n - k)).choose (n - k) : ℕ) : ℚ) =
      4 ^ n := by
    have : ∀ k ∈ range (n + 1), (((2 * k).choose k * (2 * (n - k)).choose (n - k) : ℕ) : ℚ) =
        4 ^ n * (((2 * k).choose k : ℚ) / 4 ^ k * (((2 * (n - k)).choose (n - k) : ℚ) /
          4 ^ (n - k))) := by
      intro k hk
      rw [Finset.mem_range] at hk
      have e : (4 : ℚ) ^ n = 4 ^ k * 4 ^ (n - k) := by
        rw [← pow_add]; congr 1; omega
      rw [e]
      push_cast
      field_simp
    rw [Finset.sum_congr rfl this, ← Finset.mul_sum]
    simp only at h
    rw [h, mul_one]
  exact_mod_cast h2

lemma asl_card_nonzero (m r : ℕ) (hr : r = 2 * m) :
    (univ.filter (fun z : Fin r → Bool =>
        ∀ i ∈ Icc (1 : ℕ) r, coinScore z i ≠ 0)).card = (2 * m).choose m := by
  set NZ : ℕ → ℕ := fun r => (univ.filter (fun z : Fin r → Bool =>
        ∀ i ∈ Icc (1 : ℕ) r, coinScore z i ≠ 0)).card with hNZdef
  change NZ r = _
  subst hr
  induction m using Nat.strong_induction_on with
  | _ m ih =>
    have h1 : ∑ k ∈ range (m + 1), (2 * k).choose k * NZ (2 * m - 2 * k) = 4 ^ m := by
      rw [← asl_sum_lastTie m]
      apply Finset.sum_congr rfl
      intro k hk
      rw [Finset.mem_range] at hk
      rw [asl_card_lastTie (2 * m) (2 * k) (by omega), asl_card_tied]
    have h2 := asl_central_conv m
    rw [← h2, Finset.sum_range_succ', Finset.sum_range_succ'] at h1
    have h3 : ∑ k ∈ range m, (2 * (k + 1)).choose (k + 1) * NZ (2 * m - 2 * (k + 1)) =
        ∑ k ∈ range m, (2 * (k + 1)).choose (k + 1) *
          (2 * (m - (k + 1))).choose (m - (k + 1)) := by
      apply Finset.sum_congr rfl
      intro k hk
      rw [Finset.mem_range] at hk
      rw [show 2 * m - 2 * (k + 1) = 2 * (m - (k + 1)) by omega, ih _ (by omega)]
    rw [h3] at h1
    simpa using h1

/-- The coin game, counted exactly. In a fair game of `2n` tosses, every one of the `4^n`
matches equally likely and the game starting at a tie, the chance that the last tie falls on
day `2k` (for `k ≤ n`) is `u_{2k} u_{2n−2k}`: a tie on day `2k` times no tie in the days left. -/
theorem last_tie_prob_eq_tieChance_mul {n k : ℕ} (hk : k ≤ n) :
    ((univ.filter (fun x : Fin (2 * n) → Bool => lastTie x = 2 * k)).card : ℚ) / 4 ^ n =
      tieChance k * tieChance (n - k) := by
  rw [asl_card_lastTie (2 * n) (2 * k) (by omega), asl_card_tied,
    asl_card_nonzero (n - k) (2 * n - 2 * k) (by omega)]
  unfold tieChance
  have e : (4 : ℚ) ^ n = 4 ^ k * 4 ^ (n - k) := by
    rw [← pow_add]; congr 1; omega
  rw [e]
  push_cast
  field_simp

-- The card's 16-toss check (n = 8): the numbers of matches whose last tie is on day 2k,
-- k = 0..8, are C(2k, k) C(16 − 2k, 8 − k).
example : (List.range 9).map (fun k => (2 * k).choose k * (16 - 2 * k).choose (8 - k)) =
    [12870, 6864, 5544, 5040, 4900, 5040, 5544, 6864, 12870] := by
  decide

-- The nine counts cover all 65,536 = 4^8 matches of 16 tosses.
example : 12870 + 6864 + 5544 + 5040 + 4900 + 5040 + 5544 + 6864 + 12870 = 4 ^ 8 := by
  norm_num

#print axioms last_zero_arcsine_law
#print axioms arcsine_cdf_hasDerivAt
#print axioms last_tie_prob_eq_tieChance_mul
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
#print axioms running_max_identDistrib_abs
#print axioms asl_sin_lt_iff
#print axioms asl_angle_iff
#print axioms asl_angle_measure
#print axioms asl_radial
#print axioms asl_std_angle
#print axioms asl_scale
#print axioms asl_lastZero_le_iff
#print axioms asl_path
#print axioms asl_sup_grid
#print axioms asl_joint_law
#print axioms asl_main
#print axioms asl_score_split
#print axioms asl_score_zero
#print axioms asl_score_ge
#print axioms asl_score_full
#print axioms asl_score_even
#print axioms asl_sup_eq_iff
#print axioms asl_lastTie_mem
#print axioms asl_lastTie_iff
#print axioms asl_card_lastTie_add
#print axioms asl_card_lastTie
#print axioms asl_card_tied
#print axioms asl_sum_lastTie
#print axioms asl_conv
#print axioms asl_central_conv
#print axioms asl_card_nonzero
