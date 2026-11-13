-- Signed measures: every signed measure splits the space into a positive and a negative part (Hahn), its gains and losses are two mutually singular measures and the cheapest such split (Jordan), and for two probability measures the largest gap on any event is half the total variation of their difference.
import Mathlib.MeasureTheory.VectorMeasure.Decomposition.Jordan
import Mathlib.Topology.Instances.EReal.Lemmas
import Mathlib.Tactic.NormNum

open MeasureTheory

open Filter Topology
open scoped ENNReal

lemma ereal_neg_finset_sum {ι : Type*} (x : ι → EReal)
    (hx : (∀ i, x i ≠ ⊥) ∨ (∀ i, x i ≠ ⊤)) (s : Finset ι) :
    ∑ i ∈ s, -x i = -(∑ i ∈ s, x i) := by
  classical
  induction s using Finset.induction_on with
  | empty => simp
  | insert a s ha ih =>
    rw [Finset.sum_insert ha, Finset.sum_insert ha, ih]
    rcases hx with hx | hx
    · have hs : ∑ i ∈ s, x i ≠ ⊥ :=
        Finset.sum_induction _ (· ≠ ⊥) (fun a b ha hb => EReal.add_ne_bot_iff.2 ⟨ha, hb⟩)
          (by simp) (fun i _ => hx i)
      rw [EReal.neg_add (Or.inl (hx a)) (Or.inr hs), sub_eq_add_neg]
    · have hs : ∑ i ∈ s, x i ≠ ⊤ :=
        Finset.sum_induction _ (· ≠ ⊤) (fun a b ha hb => EReal.add_ne_top ha hb)
          (by simp) (fun i _ => hx i)
      rw [EReal.neg_add (Or.inr hs) (Or.inl (hx a)), sub_eq_add_neg]

#print axioms ereal_neg_finset_sum

lemma ereal_hasSum_neg {ι : Type*} {x : ι → EReal} {a : EReal} (h : HasSum x a)
    (hx : (∀ i, x i ≠ ⊥) ∨ (∀ i, x i ≠ ⊤)) : HasSum (fun i => -x i) (-a) := by
  unfold HasSum at *
  have := (continuous_neg.tendsto a).comp h
  refine this.congr (fun s => ?_)
  simp only [Function.comp_apply]
  rw [ereal_neg_finset_sum x hx s]

#print axioms ereal_hasSum_neg

/-- The negative of an extended-real vector measure that avoids one of the two infinities. -/
noncomputable def erealVMNeg {Ω : Type*} [MeasurableSpace Ω] (ν : VectorMeasure Ω EReal)
    (hν : (∀ s, ν s ≠ ⊥) ∨ (∀ s, ν s ≠ ⊤)) : VectorMeasure Ω EReal where
  measureOf' s := -ν s
  empty' := by simp
  not_measurable' s hs := by simp [ν.not_measurable hs]
  m_iUnion' f hf hd := by
    refine ereal_hasSum_neg (ν.m_iUnion hf hd) ?_
    rcases hν with h | h
    · exact Or.inl fun i => h _
    · exact Or.inr fun i => h _

#print axioms erealVMNeg

lemma erealVMNeg_apply {Ω : Type*} [MeasurableSpace Ω] (ν : VectorMeasure Ω EReal)
    (hν : (∀ s, ν s ≠ ⊥) ∨ (∀ s, ν s ≠ ⊤)) (s : Set Ω) : erealVMNeg ν hν s = -ν s := rfl

#print axioms erealVMNeg_apply

/-- A finite extended-real vector measure, read as a signed measure. -/
noncomputable def erealVMToSigned {Ω : Type*} [MeasurableSpace Ω] (ν : VectorMeasure Ω EReal)
    (ht : ∀ s, ν s ≠ ⊤) (hb : ∀ s, ν s ≠ ⊥) : SignedMeasure Ω where
  measureOf' s := (ν s).toReal
  empty' := by simp
  not_measurable' s hs := by simp [ν.not_measurable hs]
  m_iUnion' f hf hd := by
    have h1 := ν.m_iUnion hf hd
    unfold HasSum at *
    rw [← EReal.tendsto_coe, EReal.coe_toReal (ht _) (hb _)]
    refine h1.congr (fun s => ?_)
    change _ = Real.toERealAddHom _
    rw [map_sum]
    exact Finset.sum_congr rfl fun i _ => (EReal.coe_toReal (ht _) (hb _)).symm

#print axioms erealVMToSigned

lemma erealVMToSigned_apply {Ω : Type*} [MeasurableSpace Ω] (ν : VectorMeasure Ω EReal)
    (ht : ∀ s, ν s ≠ ⊤) (hb : ∀ s, ν s ≠ ⊥) (s : Set Ω) :
    erealVMToSigned ν ht hb s = (ν s).toReal := rfl

#print axioms erealVMToSigned_apply

/-- A nonnegative extended-real vector measure, read as a measure. -/
noncomputable def erealVMToMeasure {Ω : Type*} [MeasurableSpace Ω] (ν : VectorMeasure Ω EReal)
    (h : ∀ s, 0 ≤ ν s) : Measure Ω :=
  Measure.ofMeasurable (fun s _ => (ν s).toENNReal) (by simp) (by
    intro f hf hd
    have h1 := ν.m_iUnion hf hd
    have h2 := (CompleteLattice.summable (f := fun i => (ν (f i)).toENNReal)).hasSum.map
      (⟨⟨(↑), EReal.coe_ennreal_zero⟩, EReal.coe_ennreal_add⟩ : ℝ≥0∞ →+ EReal)
      continuous_coe_ennreal_ereal
    have h3 : HasSum (fun i => ν (f i))
        (((∑' i, (ν (f i)).toENNReal : ℝ≥0∞)) : EReal) := by
      convert h2 using 1
      funext i
      simp [EReal.coe_toENNReal (h _)]
    rw [h1.unique h3, EReal.toENNReal_coe])

#print axioms erealVMToMeasure

lemma erealVMToMeasure_apply {Ω : Type*} [MeasurableSpace Ω] (ν : VectorMeasure Ω EReal)
    (h : ∀ s, 0 ≤ ν s) {s : Set Ω} (hs : MeasurableSet s) :
    erealVMToMeasure ν h s = (ν s).toENNReal := by
  rw [erealVMToMeasure, Measure.ofMeasurable_apply _ hs]

#print axioms erealVMToMeasure_apply

lemma ereal_neg_nonneg_iff (x : EReal) : 0 ≤ -x ↔ x ≤ 0 := by
  rw [← EReal.neg_le_neg_iff, neg_neg, neg_zero]

#print axioms ereal_neg_nonneg_iff

lemma ereal_neg_nonpos_iff (x : EReal) : -x ≤ 0 ↔ 0 ≤ x := by
  rw [← EReal.neg_le_neg_iff, neg_neg, neg_zero]

#print axioms ereal_neg_nonpos_iff

lemma hahn_of_ne_top {Ω : Type*} [MeasurableSpace Ω] (ν : VectorMeasure Ω EReal)
    (ht : ∀ s, ν s ≠ ⊤) :
    ∃ P : Set Ω, MeasurableSet P ∧ (∀ B, MeasurableSet B → B ⊆ P → 0 ≤ ν B) ∧
      (∀ B, MeasurableSet B → B ⊆ Pᶜ → ν B ≤ 0) := by
  classical
  set S : Set EReal := {x | ∃ P, MeasurableSet P ∧ 0 ≤[P] ν ∧ x = ν P} with hS
  have hSne : S.Nonempty := ⟨0, ∅, MeasurableSet.empty, by simp, by simp⟩
  obtain ⟨u, -, hu, huS⟩ := exists_seq_tendsto_sSup hSne (OrderTop.bddAbove S)
  choose Pn hPn using huS
  set P := ⋃ n, Pn n with hP
  have hPm : MeasurableSet P := MeasurableSet.iUnion fun n => (hPn n).1
  have hPpos : 0 ≤[P] ν :=
    VectorMeasure.restrict_le_restrict_iUnion _ _ (fun n => (hPn n).1) (fun n => (hPn n).2.1)
  have hposS : ∀ Q, MeasurableSet Q → 0 ≤[Q] ν → ∀ B, MeasurableSet B → B ⊆ Q → 0 ≤ ν B :=
    fun Q hQ hQpos B hB hBQ => by
      simpa using (VectorMeasure.restrict_le_restrict_iff _ _ hQ).1 hQpos hB hBQ
  have hpos : ∀ B, MeasurableSet B → B ⊆ P → 0 ≤ ν B := hposS P hPm hPpos
  have hPS : ν P ∈ S := ⟨P, hPm, hPpos, rfl⟩
  have hPeq : ν P = sSup S := by
    apply le_antisymm (le_sSup hPS)
    refine le_of_tendsto' hu (fun n => ?_)
    rw [(hPn n).2.2, ← VectorMeasure.of_add_of_sdiff (hPn n).1 hPm (Set.subset_iUnion _ n)]
    exact le_add_of_nonneg_right (hpos _ (hPm.diff (hPn n).1) Set.sdiff_subset)
  refine ⟨P, hPm, hpos, ?_⟩
  intro C hC hCP
  by_contra hCneg
  push Not at hCneg
  have hCbot : ν C ≠ ⊥ := ne_bot_of_gt hCneg
  have hsub : ∀ B, MeasurableSet B → B ⊆ C → ν B ≠ ⊥ := by
    intro B hB hBC hBbot
    have := VectorMeasure.of_add_of_sdiff (v := ν) hB hC hBC
    rw [hBbot, EReal.bot_add] at this
    exact hCbot this.symm
  set ρ := ν.restrict C with hρdef
  have hρ : ∀ s, MeasurableSet s → ρ s = ν (s ∩ C) :=
    fun s hs => VectorMeasure.restrict_apply _ hC hs
  have hρt : ∀ s, ρ s ≠ ⊤ := by
    intro s; by_cases hs : MeasurableSet s
    · rw [hρ s hs]; exact ht _
    · rw [ρ.not_measurable hs]; simp
  have hρb : ∀ s, ρ s ≠ ⊥ := by
    intro s; by_cases hs : MeasurableSet s
    · rw [hρ s hs]; exact hsub _ (hs.inter hC) Set.inter_subset_right
    · rw [ρ.not_measurable hs]; simp
  obtain ⟨i, hi, hi1, hi2⟩ := (erealVMToSigned ρ hρt hρb).exists_compl_positive_negative
  have hval : ∀ B, MeasurableSet B → B ⊆ C →
      erealVMToSigned ρ hρt hρb B = (ν B).toReal ∧ ((ν B).toReal : EReal) = ν B := by
    intro B hB hBC
    refine ⟨?_, EReal.coe_toReal (ht _) (hsub B hB hBC)⟩
    rw [erealVMToSigned_apply, hρ B hB, Set.inter_eq_left.2 hBC]
  set D := C ∩ i with hD
  have hDm : MeasurableSet D := hC.inter hi
  have hDpos : 0 ≤[D] ν := by
    refine VectorMeasure.restrict_le_restrict_of_subset_le _ _ fun B hB hBD => ?_
    have h1 := (VectorMeasure.restrict_le_restrict_iff _ _ hi).1 hi1 hB
      (hBD.trans Set.inter_subset_right)
    obtain ⟨h2, h3⟩ := hval B hB (hBD.trans Set.inter_subset_left)
    simp only [zero_apply] at h1 ⊢
    rw [h2] at h1
    rw [← h3]
    exact EReal.coe_nonneg.2 h1
  have hCD : ν (C \ D) ≤ 0 := by
    have hsub' : C \ D ⊆ iᶜ := by
      intro x hx; simp only [hD, Set.mem_sdiff, Set.mem_inter_iff, not_and] at hx
      exact hx.2 hx.1
    have h1 := (VectorMeasure.restrict_le_restrict_iff _ _ hi.compl).1 hi2 (hC.diff hDm) hsub'
    obtain ⟨h2, h3⟩ := hval (C \ D) (hC.diff hDm) Set.sdiff_subset
    simp only [zero_apply] at h1
    rw [h2] at h1
    rw [← h3]
    exact EReal.coe_nonpos.2 h1
  have hDC : ν C ≤ ν D := by
    rw [← VectorMeasure.of_add_of_sdiff hDm hC Set.inter_subset_left]
    exact add_le_of_nonpos_right hCD
  have hDpos' : 0 < ν D := lt_of_lt_of_le hCneg hDC
  have hdisj : Disjoint P D := by
    refine Set.disjoint_left.2 fun x hxP hxD => ?_
    exact hCP (Set.inter_subset_left hxD) hxP
  have hPD : ν (P ∪ D) ≤ ν P := by
    rw [hPeq]
    exact le_sSup ⟨P ∪ D, hPm.union hDm,
      VectorMeasure.restrict_le_restrict_union _ _ hPm hPpos hDm hDpos, rfl⟩
  rw [VectorMeasure.of_union hdisj hPm hDm] at hPD
  have hPbot : ν P ≠ ⊥ := ne_bot_of_le_ne_bot (by simp) (hpos P hPm le_rfl)
  have key := EReal.add_lt_add_left_coe hDpos' (ν P).toReal
  rw [add_zero, EReal.coe_toReal (ht _) hPbot] at key
  exact absurd hPD (not_le.2 key)

#print axioms hahn_of_ne_top

/-- Hahn decomposition. Let nu be a signed measure: it gives each measurable set a size from
minus infinity to plus infinity, the empty set has size 0, sizes add over countably many
disjoint pieces (unconditionally, so the order of the pieces does not matter), and nu takes at
most one of the two values plus infinity and minus infinity. Then the space splits into two
disjoint measurable sets, Omega+ and Omega-, whose union is everything, such that every
measurable piece of Omega+ has size at least 0 and every measurable piece of Omega- has size
at most 0. -/
theorem hahn_decomposition {Ω : Type*} [MeasurableSpace Ω] (ν : VectorMeasure Ω EReal)
    (hν : ¬ ((∃ A, MeasurableSet A ∧ ν A = ⊤) ∧ (∃ B, MeasurableSet B ∧ ν B = ⊥))) :
    ∃ Ωp Ωn : Set Ω, MeasurableSet Ωp ∧ MeasurableSet Ωn ∧
      Ωp ∪ Ωn = Set.univ ∧ Disjoint Ωp Ωn ∧
      (∀ B, MeasurableSet B → B ⊆ Ωp → 0 ≤ ν B) ∧
      (∀ B, MeasurableSet B → B ⊆ Ωn → ν B ≤ 0) := by
  have hcase : (∀ s, ν s ≠ ⊤) ∨ (∀ s, ν s ≠ ⊥) := by
    by_contra hc
    push Not at hc
    obtain ⟨⟨A, hA⟩, ⟨B, hB⟩⟩ := hc
    apply hν
    refine ⟨⟨A, ?_, hA⟩, ⟨B, ?_, hB⟩⟩
    · by_contra hm
      rw [ν.not_measurable hm] at hA
      exact EReal.zero_ne_top hA
    · by_contra hm
      rw [ν.not_measurable hm] at hB
      exact EReal.zero_ne_bot hB
  rcases hcase with h | h
  · obtain ⟨P, hP, hpos, hneg⟩ := hahn_of_ne_top ν h
    exact ⟨P, Pᶜ, hP, hP.compl, Set.union_compl_self P, disjoint_compl_right, hpos, hneg⟩
  · have ht' : ∀ s, erealVMNeg ν (Or.inl h) s ≠ ⊤ := fun s => by
      rw [erealVMNeg_apply, Ne, EReal.neg_eq_top_iff]; exact h s
    obtain ⟨P, hP, hpos, hneg⟩ := hahn_of_ne_top _ ht'
    refine ⟨Pᶜ, P, hP.compl, hP, Set.compl_union_self P, disjoint_compl_left, ?_, ?_⟩
    · intro B hB hBP
      have := hneg B hB hBP
      rwa [erealVMNeg_apply, ereal_neg_nonpos_iff] at this
    · intro B hB hBP
      have := hpos B hB hBP
      rwa [erealVMNeg_apply, ereal_neg_nonneg_iff] at this

/-- Jordan decomposition. For the same kind of signed measure nu there is a measurable set
Omega+ and two ordinary measures nu+ (the gains) and nu- (the losses) such that nu+ gives the
complement of Omega+ size 0, nu- gives Omega+ size 0 (they live on disjoint parts), and
nu(E) = nu+(E) - nu-(E) for every measurable E. This split is the cheapest: whenever
nu = mu1 - mu2 for two measures mu1 and mu2, then nu+ is at most mu1 and nu- is at most mu2. -/
theorem jordan_decomposition {Ω : Type*} [MeasurableSpace Ω] (ν : VectorMeasure Ω EReal)
    (hν : ¬ ((∃ A, MeasurableSet A ∧ ν A = ⊤) ∧ (∃ B, MeasurableSet B ∧ ν B = ⊥))) :
    ∃ Ωp : Set Ω, MeasurableSet Ωp ∧ ∃ νp νn : Measure Ω,
      νp Ωpᶜ = 0 ∧ νn Ωp = 0 ∧
      (∀ E, MeasurableSet E → ν E = (νp E : EReal) - (νn E : EReal)) ∧
      ∀ μ₁ μ₂ : Measure Ω, (∀ E, MeasurableSet E → ν E = (μ₁ E : EReal) - (μ₂ E : EReal)) →
        νp ≤ μ₁ ∧ νn ≤ μ₂ := by
  obtain ⟨Ωp, Ωn, hp, hn, hU, hD, hpos, hneg⟩ := hahn_decomposition ν hν
  have hp0 : ∀ s, 0 ≤ ν.restrict Ωp s := by
    intro s; by_cases hs : MeasurableSet s
    · rw [VectorMeasure.restrict_apply _ hp hs]
      exact hpos _ (hs.inter hp) Set.inter_subset_right
    · rw [VectorMeasure.not_measurable _ hs]
  have hn0 : ∀ s, ν.restrict Ωn s ≤ 0 := by
    intro s; by_cases hs : MeasurableSet s
    · rw [VectorMeasure.restrict_apply _ hn hs]
      exact hneg _ (hs.inter hn) Set.inter_subset_right
    · rw [VectorMeasure.not_measurable _ hs]
  have hnt : ∀ s, ν.restrict Ωn s ≠ ⊤ := fun s h => by
    have := hn0 s; rw [h] at this; exact absurd this (by simp)
  have hn0' : ∀ s, 0 ≤ erealVMNeg (ν.restrict Ωn) (Or.inr hnt) s := fun s => by
    rw [erealVMNeg_apply, ereal_neg_nonneg_iff]; exact hn0 s
  refine ⟨Ωp, hp, erealVMToMeasure _ hp0, erealVMToMeasure _ hn0', ?_, ?_, ?_, ?_⟩
  · rw [erealVMToMeasure_apply _ _ hp.compl, VectorMeasure.restrict_apply _ hp hp.compl]
    simp
  · rw [erealVMToMeasure_apply _ _ hp, erealVMNeg_apply, VectorMeasure.restrict_apply _ hn hp,
      Set.disjoint_iff_inter_eq_empty.1 hD]
    simp
  · intro E hE
    rw [erealVMToMeasure_apply _ _ hE, erealVMToMeasure_apply _ _ hE,
      EReal.coe_toENNReal (hp0 _), EReal.coe_toENNReal (hn0' _), erealVMNeg_apply,
      VectorMeasure.restrict_apply _ hp hE, VectorMeasure.restrict_apply _ hn hE,
      sub_eq_add_neg, neg_neg,
      ← VectorMeasure.of_union (hD.mono Set.inter_subset_right Set.inter_subset_right)
        (hE.inter hp) (hE.inter hn), ← Set.inter_union_distrib_left, hU, Set.inter_univ]
  · intro μ₁ μ₂ hμ
    constructor
    · rw [Measure.le_iff]
      intro s hs
      rw [erealVMToMeasure_apply _ _ hs, VectorMeasure.restrict_apply _ hp hs,
        hμ _ (hs.inter hp)]
      have h1 : (μ₁ (s ∩ Ωp) : EReal) - (μ₂ (s ∩ Ωp) : EReal) ≤ (μ₁ s : EReal) := by
        rw [sub_eq_add_neg]
        refine (add_le_of_nonpos_right ?_).trans ?_
        · rw [ereal_neg_nonpos_iff]; exact EReal.coe_ennreal_nonneg _
        · exact EReal.coe_ennreal_le_coe_ennreal_iff.2 (measure_mono Set.inter_subset_left)
      exact (EReal.toENNReal_le_toENNReal h1).trans_eq EReal.toENNReal_coe
    · rw [Measure.le_iff]
      intro s hs
      rw [erealVMToMeasure_apply _ _ hs, erealVMNeg_apply, VectorMeasure.restrict_apply _ hn hs,
        hμ _ (hs.inter hn)]
      have h1 : -((μ₁ (s ∩ Ωn) : EReal) - (μ₂ (s ∩ Ωn) : EReal)) ≤ (μ₂ s : EReal) := by
        rw [EReal.neg_le, sub_eq_add_neg]
        refine (le_add_of_nonneg_left (EReal.coe_ennreal_nonneg _)).trans' ?_
        rw [EReal.neg_le_neg_iff]
        exact EReal.coe_ennreal_le_coe_ennreal_iff.2 (measure_mono Set.inter_subset_left)
      exact (EReal.toENNReal_le_toENNReal h1).trans_eq EReal.toENNReal_coe

/-- Total variation distance. For two probability measures P and Q on the same space, the
largest disagreement |Q(A) - P(A)| over all events A equals half the total variation of the
signed measure Q - P on the whole space, and some event attains it. -/
theorem total_variation_distance_eq_half_total_variation {Ω : Type*} [MeasurableSpace Ω]
    (P Q : Measure Ω) [IsProbabilityMeasure P] [IsProbabilityMeasure Q] :
    IsGreatest {x : ℝ | ∃ A, MeasurableSet A ∧ x = |Q.real A - P.real A|}
      ((1 / 2) * (Q.toSignedMeasure - P.toSignedMeasure).totalVariation.real Set.univ) := by
  set σ := Q.toSignedMeasure - P.toSignedMeasure with hσ
  set j := σ.toJordanDecomposition with hj
  have hσA : ∀ A, MeasurableSet A → σ A = Q.real A - P.real A := fun A hA => by
    rw [hσ, sub_apply, Measure.toSignedMeasure_apply_measurable hA,
      Measure.toSignedMeasure_apply_measurable hA]
  have hjA : ∀ A, MeasurableSet A → σ A = j.posPart.real A - j.negPart.real A :=
    fun A hA => σ.apply_eq_posPart_real_sub_negPart_real hA
  have huniv : j.posPart.real Set.univ = j.negPart.real Set.univ := by
    have h1 := hjA _ MeasurableSet.univ
    rw [hσA _ MeasurableSet.univ] at h1
    simp only [probReal_univ, sub_self] at h1
    linarith
  have hTV : (1 / 2) * σ.totalVariation.real Set.univ = j.posPart.real Set.univ := by
    rw [SignedMeasure.totalVariation, measureReal_add_apply, ← hj, huniv]
    ring
  rw [hTV]
  obtain ⟨S, hS, -, -, hpS, hnS⟩ := j.exists_compl_positive_negative
  constructor
  · refine ⟨Sᶜ, hS.compl, ?_⟩
    rw [← hσA _ hS.compl, hjA _ hS.compl, measureReal_def j.negPart, hnS, ENNReal.toReal_zero,
      sub_zero, abs_of_nonneg measureReal_nonneg]
    have h2 := measureReal_add_measureReal_compl (μ := j.posPart) hS
    rw [measureReal_def j.posPart S, hpS, ENNReal.toReal_zero, zero_add] at h2
    exact h2.symm
  · rintro x ⟨A, hA, rfl⟩
    rw [← hσA _ hA, hjA _ hA, abs_le]
    have h1 : j.posPart.real A ≤ j.posPart.real Set.univ := measureReal_mono (Set.subset_univ _)
    have h2 : j.negPart.real A ≤ j.negPart.real Set.univ := measureReal_mono (Set.subset_univ _)
    have h3 : 0 ≤ j.posPart.real A := measureReal_nonneg
    have h4 : 0 ≤ j.negPart.real A := measureReal_nonneg
    constructor <;> linarith

-- The dice, in thirtieths so every number is whole. Faces 1 to 6 are 0 to 5 here.
-- Fair die P: 5 per face (1/6). Loaded die Q: 3, 3, 3, 3, 6, 12 (0.1, 0.1, 0.1, 0.1, 0.2, 0.4).
-- nu = Q - P face by face: -2, -2, -2, -2, 1, 7.
example : (fun i : Fin 6 => ![3, 3, 3, 3, 6, 12] i - ![5, 5, 5, 5, 5, 5] i) =
    ![-2, -2, -2, -2, 1, (7 : ℤ)] := by decide
-- {4, 5, 6} has positive size 6 (0.200) but is not a positive set: {4} has size -2.
example : ∑ i ∈ ({3, 4, 5} : Finset (Fin 6)), ![-2, -2, -2, -2, 1, (7 : ℤ)] i = 6 ∧
    ![-2, -2, -2, -2, 1, (7 : ℤ)] 3 = -2 := by decide
-- Of the 64 events, exactly 4 are positive sets and 16 are negative sets.
example : (Finset.univ.filter (fun A : Finset (Fin 6) =>
    ∀ B ∈ A.powerset, 0 ≤ ∑ i ∈ B, ![-2, -2, -2, -2, 1, (7 : ℤ)] i)).card = 4 := by decide
example : (Finset.univ.filter (fun A : Finset (Fin 6) =>
    ∀ B ∈ A.powerset, ∑ i ∈ B, ![-2, -2, -2, -2, 1, (7 : ℤ)] i ≤ 0)).card = 16 := by decide
-- Hahn split {5, 6} and {1, 2, 3, 4}: gains 8 (0.267), losses 8 (0.267), total variation 16 (0.533).
example : ∑ i ∈ ({4, 5} : Finset (Fin 6)), ![-2, -2, -2, -2, 1, (7 : ℤ)] i = 8 ∧
    ∑ i ∈ ({0, 1, 2, 3} : Finset (Fin 6)), ![-2, -2, -2, -2, 1, (7 : ℤ)] i = -8 ∧
    ∑ i, |![-2, -2, -2, -2, 1, (7 : ℤ)] i| = 16 := by decide
-- Distance: no event has |Q(A) - P(A)| above 8 (4/15, 0.267); only {5, 6} and {1, 2, 3, 4} reach it.
example : ∀ A : Finset (Fin 6), |∑ i ∈ A, ![-2, -2, -2, -2, 1, (7 : ℤ)] i| ≤ 8 := by decide
example : (Finset.univ.filter (fun A : Finset (Fin 6) =>
    |∑ i ∈ A, ![-2, -2, -2, -2, 1, (7 : ℤ)] i| = 8)) = {{4, 5}, {0, 1, 2, 3}} := by decide
-- Overlap: the sum of min(p_i, q_i) is 22 (0.733), and 30 - 22 = 8.
example : ∑ i, min (![5, 5, 5, 5, 5, 5] i) (![3, 3, 3, 3, 6, 12] i) = (22 : ℤ) := by decide
-- The split Q - P itself costs Q(Omega) + P(Omega) = 60 (total 2), against 16 for Jordan.
example : ∑ i, ![3, 3, 3, 3, 6, 12] i + ∑ i, ![5, 5, 5, 5, 5, 5] i = (60 : ℤ) := by decide
-- The same numbers as fractions.
example : (2 / 10 - 1 / 6 : ℚ) + (4 / 10 - 1 / 6) = 4 / 15 ∧
    4 * (1 / 6 - 1 / 10 : ℚ) = 4 / 15 ∧ (4 / 15 + 4 / 15 : ℚ) / 2 = 4 / 15 := by norm_num

#print axioms hahn_decomposition
#print axioms jordan_decomposition
#print axioms total_variation_distance_eq_half_total_variation
