-- Lebesgue decomposition: a σ-finite measure splits in exactly one way into a part absolutely continuous to a reference measure and a part singular to it, the first part has a density when the reference is σ-finite too, and on the line, against length, the singular part splits again into point masses and a continuous singular part.
import Mathlib.MeasureTheory.Measure.Decomposition.Lebesgue
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Tactic.NormNum

open MeasureTheory

/-- A measure split as a + b, with a null on T and b null off T, is the pair of restrictions. -/
theorem lebdec_split_eq_restrict {Ω : Type*} [MeasurableSpace Ω] {m a b : Measure Ω}
    {T : Set Ω} (hT : MeasurableSet T) (h : m = a + b) (ha : a T = 0) (hb : b Tᶜ = 0) :
    a = m.restrict Tᶜ ∧ b = m.restrict T := by
  subst h
  rw [Measure.restrict_add, Measure.restrict_add]
  have h1 : a.restrict T = 0 := Measure.restrict_eq_zero.mpr ha
  have h2 : b.restrict Tᶜ = 0 := Measure.restrict_eq_zero.mpr hb
  have h3 : a.restrict Tᶜ = a := by
    conv_rhs => rw [← Measure.restrict_add_restrict_compl (μ := a) hT]
    rw [h1, zero_add]
  have h4 : b.restrict T = b := by
    conv_rhs => rw [← Measure.restrict_add_restrict_compl (μ := b) hT]
    rw [h2, add_zero]
  rw [h1, h2, h3, h4]
  simp

/-- Uniqueness of the absolutely continuous / singular split, for any measures. -/
theorem lebdec_unique {Ω : Type*} [MeasurableSpace Ω] {μ ν a b a' b' : Measure Ω}
    (h : ν = a + b) (ha : a ≪ μ) (hb : b ⟂ₘ μ)
    (h' : ν = a' + b') (ha' : a' ≪ μ) (hb' : b' ⟂ₘ μ) : a = a' ∧ b = b' := by
  set T := hb.nullSetᶜ ∪ hb'.nullSetᶜ with hT_def
  have hTm : MeasurableSet T :=
    hb.measurableSet_nullSet.compl.union hb'.measurableSet_nullSet.compl
  have hμT : μ T = 0 :=
    measure_union_null hb.measure_compl_nullSet hb'.measure_compl_nullSet
  have hbT : b Tᶜ = 0 := by
    refine measure_mono_null ?_ hb.measure_nullSet
    intro x hx
    simp only [hT_def, Set.mem_compl_iff, Set.mem_union, not_or, not_not] at hx
    exact hx.1
  have hbT' : b' Tᶜ = 0 := by
    refine measure_mono_null ?_ hb'.measure_nullSet
    intro x hx
    simp only [hT_def, Set.mem_compl_iff, Set.mem_union, not_or, not_not] at hx
    exact hx.2
  obtain ⟨e1, e2⟩ := lebdec_split_eq_restrict hTm h (ha hμT) hbT
  obtain ⟨e1', e2'⟩ := lebdec_split_eq_restrict hTm h' (ha' hμT) hbT'
  exact ⟨e1.trans e1'.symm, e2.trans e2'.symm⟩

/-- Uniqueness of the split into a part on a countable set and a part with no atoms. -/
theorem lebdec_unique_atoms {b d c d' c' : Measure ℝ} (h : b = d + c) (h' : b = d' + c')
    {S S' : Set ℝ} (hS : S.Countable) (hS' : S'.Countable) (hd : d Sᶜ = 0) (hd' : d' S'ᶜ = 0)
    (hc : ∀ x : ℝ, c {x} = 0) (hc' : ∀ x : ℝ, c' {x} = 0) : d = d' ∧ c = c' := by
  have hT : (S ∪ S').Countable := hS.union hS'
  have hTm : MeasurableSet (S ∪ S') := hT.measurableSet
  have : NullSingletonClass c := ⟨hc⟩
  have : NullSingletonClass c' := ⟨hc'⟩
  have hcT : c (S ∪ S') = 0 := hT.measure_zero c
  have hcT' : c' (S ∪ S') = 0 := hT.measure_zero c'
  have hdT : d (S ∪ S')ᶜ = 0 :=
    measure_mono_null (Set.compl_subset_compl.mpr Set.subset_union_left) hd
  have hdT' : d' (S ∪ S')ᶜ = 0 :=
    measure_mono_null (Set.compl_subset_compl.mpr Set.subset_union_right) hd'
  obtain ⟨e1, e2⟩ := lebdec_split_eq_restrict hTm (h.trans (add_comm _ _)) hcT hdT
  obtain ⟨e1', e2'⟩ := lebdec_split_eq_restrict hTm (h'.trans (add_comm _ _)) hcT' hdT'
  exact ⟨e2.trans e2'.symm, e1.trans e1'.symm⟩

#print axioms lebdec_split_eq_restrict
#print axioms lebdec_unique
#print axioms lebdec_unique_atoms

/-- Lebesgue decomposition. Let mu (the reference) and nu be measures on the same sigma-algebra,
with nu σ-finite. Then nu splits in exactly one way as nu = nu_ac + nu_s, where nu_ac is
absolutely continuous with respect to mu (every mu-null set is nu_ac-null) and nu_s is singular
to mu (it lives on one mu-null set). No σ-finiteness of mu is needed for the split itself. -/
theorem lebesgue_decomposition_exists_unique {Ω : Type*} [MeasurableSpace Ω]
    (μ ν : Measure Ω) [SigmaFinite ν] :
    ∃! p : Measure Ω × Measure Ω, ν = p.1 + p.2 ∧ p.1 ≪ μ ∧ p.2 ⟂ₘ μ := by
  classical
  set s := μ.sigmaFiniteSetWRT ν with hs_def
  have hs : MeasurableSet s := measurableSet_sigmaFiniteSetWRT
  set ν1 := ν.restrict s with hν1
  set μ1 := μ.restrict s with hμ1
  have hdec : ν1 = ν1.singularPart μ1 + μ1.withDensity (ν1.rnDeriv μ1) :=
    Measure.haveLebesgueDecomposition_add ν1 μ1
  have hsing := Measure.mutuallySingular_singularPart ν1 μ1
  have hcompl : ν.restrict sᶜ ≪ μ := by
    intro A hA
    rw [Measure.restrict_apply' hs.compl]
    by_contra hne
    have htop := measure_eq_top_of_subset_compl_sigmaFiniteSetWRT
      (μ := μ) (ν := ν) Set.inter_subset_right hne
    rw [measure_mono_null Set.inter_subset_left hA] at htop
    exact ENNReal.zero_ne_top htop
  have hac : μ1.withDensity (ν1.rnDeriv μ1) + ν.restrict sᶜ ≪ μ := by
    refine Measure.AbsolutelyContinuous.add_left ?_ hcompl
    exact (withDensity_absolutelyContinuous μ1 _).trans
      (Measure.absolutelyContinuous_of_le Measure.restrict_le_self)
  have hsc : ν1.singularPart μ1 sᶜ = 0 := by
    refine nonpos_iff_eq_zero.mp ?_
    calc ν1.singularPart μ1 sᶜ ≤ ν1 sᶜ := Measure.singularPart_le ν1 μ1 sᶜ
      _ = 0 := by rw [hν1, Measure.restrict_apply' hs]; simp
  have hms : ν1.singularPart μ1 ⟂ₘ μ := by
    refine ⟨hsing.nullSet ∪ sᶜ, hsing.measurableSet_nullSet.union hs.compl, ?_, ?_⟩
    · exact measure_union_null hsing.measure_nullSet hsc
    · have h0 : μ.restrict s hsing.nullSetᶜ = 0 := hsing.measure_compl_nullSet
      rw [Measure.restrict_apply hsing.measurableSet_nullSet.compl] at h0
      rw [Set.compl_union, compl_compl]
      exact h0
  refine ⟨(μ1.withDensity (ν1.rnDeriv μ1) + ν.restrict sᶜ, ν1.singularPart μ1),
    ⟨?_, hac, hms⟩, ?_⟩
  · simp only
    conv_lhs => rw [← Measure.restrict_add_restrict_compl (μ := ν) hs]
    rw [← hν1]
    conv_lhs => rw [hdec]
    abel
  · rintro ⟨a, b⟩ ⟨h1, ha, hb⟩
    obtain ⟨e1, e2⟩ := lebdec_unique (μ := μ) h1 ha hb (by
      conv_lhs => rw [← Measure.restrict_add_restrict_compl (μ := ν) hs]
      rw [← hν1]
      conv_lhs => rw [hdec]
      abel) hac hms
    simp only at e1 e2
    rw [e1, e2]

/-- The density. If mu is σ-finite as well, the absolutely continuous part has a density:
nu = (the measure A ↦ ∫_A f dmu) + nu_s for a measurable f ≥ 0 and a part nu_s singular to mu,
and f is unique up to a mu-null set: any other measurable g giving such a split agrees with f
mu-almost everywhere. -/
theorem lebesgue_decomposition_density {Ω : Type*} [MeasurableSpace Ω]
    (μ ν : Measure Ω) [SigmaFinite μ] [SigmaFinite ν] :
    ∃ f : Ω → ENNReal, Measurable f ∧
      (∃ νs : Measure Ω, νs ⟂ₘ μ ∧ ν = μ.withDensity f + νs) ∧
      ∀ g : Ω → ENNReal, Measurable g →
        (∃ νs' : Measure Ω, νs' ⟂ₘ μ ∧ ν = μ.withDensity g + νs') → g =ᵐ[μ] f := by
  refine ⟨ν.rnDeriv μ, Measure.measurable_rnDeriv ν μ,
    ⟨ν.singularPart μ, Measure.mutuallySingular_singularPart ν μ, ?_⟩, ?_⟩
  · rw [add_comm]
    exact Measure.haveLebesgueDecomposition_add ν μ
  · rintro g hg ⟨νs', hνs', hadd⟩
    exact Measure.eq_rnDeriv hg hνs' (hadd.trans (add_comm _ _))

/-- On the line, density plus jumps plus staircase. Let nu be a measure on the real line that is
finite on bounded sets. Against length (Lebesgue measure), nu splits in exactly one way as
nu = nu_ac + nu_d + nu_sc, where nu_ac is absolutely continuous with respect to length, nu_d is a
pure point-mass part (it lives on a countable set), and nu_sc is continuous singular: it lives on
a set of length zero and gives every single point mass zero. -/
theorem lebesgue_decomposition_on_the_line (ν : Measure ℝ)
    (hν : ∀ s : Set ℝ, Bornology.IsBounded s → ν s < ⊤) :
    ∃! t : Measure ℝ × Measure ℝ × Measure ℝ,
      ν = t.1 + t.2.1 + t.2.2 ∧
      t.1 ≪ volume ∧
      (∃ S : Set ℝ, S.Countable ∧ t.2.1 Sᶜ = 0) ∧
      t.2.2 ⟂ₘ volume ∧ ∀ x : ℝ, t.2.2 {x} = 0 := by
  classical
  have : IsFiniteMeasureOnCompacts ν := ⟨fun K hK => hν K hK.isBounded⟩
  have : SigmaFinite ν := inferInstance
  -- a statement-level description of the property, for the uniqueness argument
  have key : ∀ t t' : Measure ℝ × Measure ℝ × Measure ℝ,
      (ν = t.1 + t.2.1 + t.2.2 ∧ t.1 ≪ volume ∧ (∃ S : Set ℝ, S.Countable ∧ t.2.1 Sᶜ = 0) ∧
        t.2.2 ⟂ₘ volume ∧ ∀ x : ℝ, t.2.2 {x} = 0) →
      (ν = t'.1 + t'.2.1 + t'.2.2 ∧ t'.1 ≪ volume ∧ (∃ S : Set ℝ, S.Countable ∧ t'.2.1 Sᶜ = 0) ∧
        t'.2.2 ⟂ₘ volume ∧ ∀ x : ℝ, t'.2.2 {x} = 0) → t = t' := by
    rintro ⟨a, d, c⟩ ⟨a', d', c'⟩ ⟨h, ha, ⟨S, hS, hd⟩, hc, hc0⟩ ⟨h', ha', ⟨S', hS', hd'⟩, hc', hc0'⟩
    simp only at *
    have hdsing : ∀ {d : Measure ℝ} {S : Set ℝ}, S.Countable → d Sᶜ = 0 → d ⟂ₘ volume := by
      intro d S hS hd
      refine ⟨Sᶜ, hS.measurableSet.compl, hd, ?_⟩
      rw [compl_compl]
      exact hS.measure_zero volume
    obtain ⟨e1, e2⟩ := lebdec_unique (μ := volume) (h.trans (add_assoc _ _ _)) ha
      ((hdsing hS hd).add_left hc) (h'.trans (add_assoc _ _ _)) ha'
      ((hdsing hS' hd').add_left hc')
    obtain ⟨e3, e4⟩ := lebdec_unique_atoms (b := d + c) rfl e2 hS hS' hd hd' hc0 hc0'
    rw [e1, e3, e4]
  obtain ⟨⟨a, b⟩, ⟨h, ha, hb⟩, -⟩ := lebesgue_decomposition_exists_unique volume ν
  simp only at h ha hb
  have : SigmaFinite b := by
    have hle : b ≤ ν := by
      rw [h]
      exact Measure.le_add_left le_rfl
    exact Measure.sigmaFinite_of_le ν hle
  set S := {x : ℝ | 0 < b {x}} with hS_def
  have hS : S.Countable := by
    have := Measure.countable_meas_pos_of_disjoint_iUnion (μ := b) (As := fun x : ℝ => ({x} : Set ℝ))
      (fun x => measurableSet_singleton x)
      (fun x y hxy => Set.disjoint_singleton.mpr hxy)
    exact this
  have hSm : MeasurableSet S := hS.measurableSet
  have P : ν = a + b.restrict S + b.restrict Sᶜ ∧ a ≪ volume ∧
      (∃ S' : Set ℝ, S'.Countable ∧ b.restrict S S'ᶜ = 0) ∧
      b.restrict Sᶜ ⟂ₘ volume ∧ ∀ x : ℝ, b.restrict Sᶜ {x} = 0 := by
    refine ⟨?_, ha, ⟨S, hS, ?_⟩, hb.restrict _, ?_⟩
    · rw [add_assoc, Measure.restrict_add_restrict_compl hSm, h]
    · rw [Measure.restrict_apply' hSm]
      simp
    · intro x
      rw [Measure.restrict_apply (measurableSet_singleton x)]
      by_cases hx : x ∈ S
      · have : ({x} : Set ℝ) ∩ Sᶜ = ∅ := by
          ext y; simp only [Set.mem_inter_iff, Set.mem_singleton_iff, Set.mem_compl_iff,
            Set.mem_empty_iff_false, iff_false, not_and, not_not]
          rintro rfl; exact hx
        rw [this, measure_empty]
      · have hx0 : b {x} = 0 := by
          simp only [hS_def, Set.mem_ofPred_eq, not_lt, nonpos_iff_eq_zero] at hx
          exact hx
        exact measure_mono_null Set.inter_subset_left hx0
  exact ⟨(a, b.restrict S, b.restrict Sᶜ), P, fun t ht => key t _ ht P⟩

-- The loaded die against the reference die. Faces 1 to 6 are 0 to 5 here.
-- Weights in tenths: nu = 1,1,1,1,2,4; mu = 0.25 on faces 1 to 4 and 0 on faces 5, 6.
-- Of the 64 sets of faces, 4 are mu-null: the subsets of {5, 6}.
example : (Finset.univ : Finset (Finset (Fin 6))).card = 64 := by decide
example : (Finset.univ.powerset.filter
    (fun s : Finset (Fin 6) => ∑ k ∈ s, ![1, 1, 1, 1, 0, 0] k = (0 : ℕ))).card = 4 := by decide
-- The mu-null set nu weighs most is {5, 6}, with 6 tenths, and no mu-null set holds more.
example : ∑ k ∈ ({4, 5} : Finset (Fin 6)), ![1, 1, 1, 1, 2, (4 : ℕ)] k = 6 := by decide
example : ∀ s : Finset (Fin 6), ∑ k ∈ s, ![1, 1, 1, 1, 0, (0 : ℕ)] k = 0 →
    ∑ k ∈ s, ![1, 1, 1, 1, 2, (4 : ℕ)] k ≤ 6 := by decide
-- The split adds back to nu face by face: nu_ac = 1,1,1,1,0,0 and nu_s = 0,0,0,0,2,4 (tenths).
example : ∀ k : Fin 6, ![1, 1, 1, 1, 0, (0 : ℕ)] k + ![0, 0, 0, 0, 2, (4 : ℕ)] k =
    ![1, 1, 1, 1, 2, (4 : ℕ)] k := by decide
-- Density of nu_ac against mu on faces 1 to 4: 0.1 / 0.25 = 2/5.
example : (1 / 10 : ℚ) / (1 / 4) = 2 / 5 := by norm_num
-- Against the fair die: density 0.1 / (1/6) = 3/5, 0.2 / (1/6) = 6/5, 0.4 / (1/6) = 12/5.
example : (1 / 10 : ℚ) / (1 / 6) = 3 / 5 ∧ (2 / 10 : ℚ) / (1 / 6) = 6 / 5 ∧
    (4 / 10 : ℚ) / (1 / 6) = 12 / 5 := by norm_num
-- The bus: density mass 7/10 plus jump 3/10 leaves 0 for a staircase.
example : (1 : ℚ) - 7 / 10 - 3 / 10 = 0 := by norm_num
-- Three-piece law: mean 0.3 × 0 + 0.5 × 1 + 0.2 × 0.5 = 3/5.
example : (3 / 10 : ℚ) * 0 + 1 / 2 * 1 + 1 / 5 * (1 / 2) = 3 / 5 := by norm_num
-- The staircase piece 0.2 C at the ninths 0, 1/9, ..., 1, with C = 0, 1/4, 1/4, 1/2, ..., 1:
-- 0, 1/20, 1/20, 1/10, 1/10, 1/10, 1/10, 3/20, 3/20, 1/5.
example : (1 / 5 : ℚ) * (1 / 4) = 1 / 20 ∧ (1 / 5 : ℚ) * (1 / 2) = 1 / 10 ∧
    (1 / 5 : ℚ) * (3 / 4) = 3 / 20 ∧ (1 / 5 : ℚ) * 1 = 1 / 5 := by norm_num
-- Census bound: the 2^n steep cells of width 3^-n have total width (2/3)^n.
example : (2 : ℚ) ^ 10 * (1 / 3) ^ 10 = (2 / 3) ^ 10 := by norm_num
-- Counting measure: the dyadic grid k/2^12 has 4097 points, the triadic grid k/3^8 has 6562.
example : 2 ^ 12 + 1 = 4097 ∧ 3 ^ 8 + 1 = 6562 := by norm_num

#print axioms lebesgue_decomposition_exists_unique
#print axioms lebesgue_decomposition_density
#print axioms lebesgue_decomposition_on_the_line
