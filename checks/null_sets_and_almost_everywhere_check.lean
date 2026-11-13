-- Null sets and almost everywhere: a list of null sets has a null union (so a list of almost-everywhere properties holds together almost everywhere), the uncountable dartboard is a union of null points yet has area π, and every measure has a unique completion that makes each piece of a null set measurable and null.
import Mathlib.MeasureTheory.Measure.Lebesgue.VolumeOfBalls

open MeasureTheory Set Metric

/-- Countably many null sets make a null set. If `N 1, N 2, ...` are each measurable with
measure 0, their union is measurable with measure 0. Turned round: if each property in a list
fails only inside some null set, then the outcomes where some property fails also fit inside one
null set, so the properties hold together almost everywhere. -/
theorem countable_union_of_null_sets_is_null {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) :
    (∀ N : ℕ → Set Ω, (∀ k, MeasurableSet (N k) ∧ μ (N k) = 0) →
      MeasurableSet (⋃ k, N k) ∧ μ (⋃ k, N k) = 0) ∧
    (∀ p : ℕ → Ω → Prop,
      (∀ k, ∃ N, MeasurableSet N ∧ μ N = 0 ∧ {ω | ¬ p k ω} ⊆ N) →
      ∃ N, MeasurableSet N ∧ μ N = 0 ∧ {ω | ¬ ∀ k, p k ω} ⊆ N) := by
  refine ⟨fun N hN => ⟨MeasurableSet.iUnion fun k => (hN k).1,
    measure_iUnion_null fun k => (hN k).2⟩, fun p hp => ?_⟩
  choose N hNm hN0 hNs using hp
  refine ⟨⋃ k, N k, MeasurableSet.iUnion hNm, measure_iUnion_null hN0, ?_⟩
  intro ω hω
  simp only [mem_ofPred_eq, not_forall] at hω
  obtain ⟨k, hk⟩ := hω
  exact mem_iUnion.2 ⟨k, hNs k hk⟩

/-- Uncountably many null sets need not make a null set. On the dartboard of radius 1 (the closed
unit disc in the plane, measured by area) every single point is measurable with area 0, the board
is the union of its points, yet the board has area π, not 0. So its points cannot be listed. -/
theorem uncountable_union_of_null_points_need_not_be_null :
    (∀ p ∈ closedBall (0 : EuclideanSpace ℝ (Fin 2)) 1,
      MeasurableSet ({p} : Set (EuclideanSpace ℝ (Fin 2))) ∧ volume ({p} : Set _) = 0) ∧
    closedBall (0 : EuclideanSpace ℝ (Fin 2)) 1 = ⋃ p ∈ closedBall (0 : EuclideanSpace ℝ (Fin 2)) 1, {p} ∧
    volume (closedBall (0 : EuclideanSpace ℝ (Fin 2)) 1) = ENNReal.ofReal Real.pi ∧
    ¬ (closedBall (0 : EuclideanSpace ℝ (Fin 2)) 1).Countable := by
  have hvol : volume (closedBall (0 : EuclideanSpace ℝ (Fin 2)) 1) = ENNReal.ofReal Real.pi := by
    simp
  refine ⟨fun p _ => ⟨measurableSet_singleton p, measure_singleton p⟩,
    (biUnion_of_singleton _).symm, hvol, fun hc => ?_⟩
  have h0 := hc.measure_zero volume
  rw [hvol] at h0
  exact (ENNReal.ofReal_pos.2 Real.pi_pos).ne' h0

/-- Every measure has a completion, with no hypotheses. There is a larger collection of measurable
sets, exactly the sets `A ∪ M` with `A` measurable and `M` a piece of a null set `N`, and a measure
on it that gives `A ∪ M` the size of `A`. It agrees with the old measure on the old sets, every
piece of one of its null sets is measurable and null, and no other measure on the larger
collection agrees with the old one on the old sets. -/
theorem every_measure_has_a_completion {Ω : Type*} [m : MeasurableSpace Ω] (μ : Measure Ω) :
    ∃ (m' : MeasurableSpace Ω) (μ' : @Measure Ω m'),
      (∀ E : Set Ω, MeasurableSet[m'] E ↔
        ∃ A M N : Set Ω, MeasurableSet[m] A ∧ MeasurableSet[m] N ∧ μ N = 0 ∧ M ⊆ N ∧
          E = A ∪ M) ∧
      m ≤ m' ∧
      (∀ A M N : Set Ω, MeasurableSet[m] A → MeasurableSet[m] N → μ N = 0 → M ⊆ N →
        μ' (A ∪ M) = μ A) ∧
      (∀ A : Set Ω, MeasurableSet[m] A → μ' A = μ A) ∧
      (∀ S T : Set Ω, MeasurableSet[m'] T → μ' T = 0 → S ⊆ T → MeasurableSet[m'] S ∧ μ' S = 0) ∧
      (∀ ν : @Measure Ω m', (∀ A : Set Ω, MeasurableSet[m] A → ν A = μ A) → ν = μ') := by
  -- size of `A ∪ M` under `μ` itself
  have key : ∀ A M N : Set Ω, MeasurableSet[m] A → μ N = 0 → M ⊆ N → μ (A ∪ M) = μ A := by
    intro A M N _ hN hMN
    apply le_antisymm
    · calc μ (A ∪ M) ≤ μ A + μ M := measure_union_le A M
        _ = μ A := by rw [measure_mono_null hMN hN, add_zero]
    · exact measure_mono subset_union_left
  have hiff : ∀ E : Set Ω, NullMeasurableSet E μ ↔
      ∃ A M N : Set Ω, MeasurableSet[m] A ∧ MeasurableSet[m] N ∧ μ N = 0 ∧ M ⊆ N ∧
          E = A ∪ M := by
    intro E
    constructor
    · intro hE
      obtain ⟨t, htE, htm, hte⟩ := hE.exists_measurable_subset_ae_eq
      have hnull : μ (E \ t) = 0 := by
        have := (ae_eq_set.1 hte).2
        exact this
      obtain ⟨N, hEN, hNm, hN0⟩ := exists_measurable_superset_of_null hnull
      exact ⟨t, E \ t, N, htm, hNm, hN0, hEN, (union_sdiff_cancel htE).symm⟩
    · rintro ⟨A, M, N, hA, _, hN0, hMN, rfl⟩
      exact hA.nullMeasurableSet.union (NullMeasurableSet.of_null (measure_mono_null hMN hN0))
  refine ⟨NullMeasurableSpace.instMeasurableSpace (μ := μ), μ.completion, hiff,
    fun s hs => hs.nullMeasurableSet, ?_, ?_, ?_, ?_⟩
  · intro A M N hA _ hN hMN
    exact key A M N hA hN hMN
  · intro A _
    rfl
  · intro S T _ hT hST
    have hS : μ S = 0 := measure_mono_null hST hT
    exact ⟨NullMeasurableSet.of_null hS, hS⟩
  · intro ν hν
    refine @Measure.ext Ω (NullMeasurableSpace.instMeasurableSpace (μ := μ)) _ _ fun E hE => ?_
    obtain ⟨A, M, N, hA, hNm, hN0, hMN, rfl⟩ := (hiff E).1 hE
    have hkey : μ (A ∪ M) = μ A := key A M N hA hN0 hMN
    have h1 := hν A hA
    have h2 := hν (A ∪ N) (hA.union hNm)
    have h3 := (@Measure.toOuterMeasure Ω (NullMeasurableSpace.instMeasurableSpace (μ := μ)) ν).mono (subset_union_left (s := A) (t := M))
    have h4 := (@Measure.toOuterMeasure Ω (NullMeasurableSpace.instMeasurableSpace (μ := μ)) ν).mono (union_subset_union_right A hMN)
    have h5 : μ (A ∪ N) = μ A := key A N N hA hN0 subset_rfl
    refine le_antisymm ?_ ?_
    · exact h4.trans (h2.trans (h5.trans hkey.symm)).le
    · exact (hkey.trans h1.symm).le.trans h3

/- The card's exact worked numbers, as fractions. Chances are areas divided by π. -/

-- Within 1/10 m of the centre: chance (1/10)(1/10) = 1/100; within 1/100 m: 1/10000.
example : (1 / 10 : ℚ) * (1 / 10) = 1 / 100 ∧ (1 / 100 : ℚ) * (1 / 100) = 1 / 10000 := by
  norm_num

-- Within 1/100 m of the rim: 1 - (99/100)(99/100) = 199/10000; within 1/10 m: 19/100.
example : 1 - (99 / 100 : ℚ) * (99 / 100) = 199 / 10000 ∧ 1 - (9 / 10 : ℚ) * (9 / 10) = 19 / 100 := by
  norm_num

-- Cover of the first 5 rational points with eps = 1/1000: square k has area eps / 2^k, and the
-- total is eps (1 - 1/32) = 31/32000.
example : ∑ k ∈ Finset.Icc 1 5, (1 / 1000 : ℚ) / 2 ^ k = 1 / 1000 * (1 - 1 / 2 ^ 5) ∧
    (1 / 1000 : ℚ) * (1 - 1 / 2 ^ 5) = 31 / 32000 := by
  norm_num [Finset.sum_Icc_succ_top]

-- Rational points (p1/d, p2/d) on the board with denominator d at most D, each counted once in
-- lowest terms: 5, 13, 37, 73, 149, 225 for D = 1, ..., 6.
example : ((Finset.Icc (-6 : ℤ) 6 ×ˢ Finset.Icc (-6 : ℤ) 6 ×ˢ Finset.Icc (1 : ℤ) 6).filter
    (fun t : ℤ × ℤ × ℤ => t.1 ^ 2 + t.2.1 ^ 2 ≤ t.2.2 ^ 2 ∧
      Int.gcd (Int.gcd t.1 t.2.1) t.2.2 = 1)).card = 225 := by
  decide +kernel

-- The diameter in n squares of side 2/n: total area n (2/n)^2 = 4/n, which is 2/5, 1/25 and
-- 1/250 for n = 10, 100, 1000.
example : (10 : ℚ) * (2 / 10) ^ 2 = 2 / 5 ∧ (100 : ℚ) * (2 / 100) ^ 2 = 1 / 25 ∧
    (1000 : ℚ) * (2 / 1000) ^ 2 = 1 / 250 := by
  norm_num

-- The scorer: outcomes centre 0, rim 1, inner 2, outer 3. Its sigma-algebra has 4 sets; gluing
-- every piece of the null set {centre, rim} onto them gives a completion of 8 sets, and {inner}
-- is not among them.
example : ((({∅, {0, 1}, {2, 3}, Finset.univ} : Finset (Finset (Fin 4))) ×ˢ
    ({0, 1} : Finset (Fin 4)).powerset).image (fun p => p.1 ∪ p.2)).card = 8 ∧
    ({2} : Finset (Fin 4)) ∉ (({∅, {0, 1}, {2, 3}, Finset.univ} : Finset (Finset (Fin 4))) ×ˢ
    ({0, 1} : Finset (Fin 4)).powerset).image (fun p => p.1 ∪ p.2) := by
  decide

#print axioms countable_union_of_null_sets_is_null
#print axioms uncountable_union_of_null_points_need_not_be_null
#print axioms every_measure_has_a_completion
