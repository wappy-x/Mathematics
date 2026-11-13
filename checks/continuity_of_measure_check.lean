-- Continuity and subadditivity: in every measure space, a measurable set inside another is no bigger (and the difference has the difference of sizes when the smaller is finite), a countable union weighs at most the sum of its pieces, rising sets have sizes tending to the size of their union, shrinking sets that start finite have sizes tending to the size of their intersection, and the finite start cannot be dropped.
import Mathlib.MeasureTheory.Measure.Continuity
import Mathlib.MeasureTheory.Measure.Count

open MeasureTheory Set Filter Topology ENNReal

/-- Every measure respects inclusion: if `A ⊆ B` then `μ A ≤ μ B`, and when `μ A` is finite the
difference `B \ A` has size `μ B - μ A`. Every measure overcounts overlaps: the size of a countable
union is at most the sum of the sizes. Every measure passes to the limit along a rising list of
sets (the sizes tend to the size of the union) and along a shrinking list whose first set has
finite size (the sizes tend to the size of the intersection). All sets are in the sigma-algebra. -/
theorem measure_mono_subadditive_continuous
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) :
    (∀ A B : Set Ω, MeasurableSet A → MeasurableSet B → A ⊆ B →
      μ A ≤ μ B ∧ (μ A < ∞ → μ (B \ A) = μ B - μ A)) ∧
    (∀ A : ℕ → Set Ω, (∀ k, MeasurableSet (A k)) →
      μ (⋃ k, A k) ≤ ∑' k, μ (A k)) ∧
    (∀ E : ℕ → Set Ω, (∀ n, MeasurableSet (E n)) → Monotone E →
      Tendsto (fun n => μ (E n)) atTop (𝓝 (μ (⋃ n, E n)))) ∧
    (∀ F : ℕ → Set Ω, (∀ n, MeasurableSet (F n)) → Antitone F → μ (F 0) < ∞ →
      Tendsto (fun n => μ (F n)) atTop (𝓝 (μ (⋂ n, F n)))) := by
  refine ⟨fun A B hA hB hAB => ⟨measure_mono hAB, fun hfin =>
      measure_sdiff hAB hA.nullMeasurableSet hfin.ne⟩, fun A _ => measure_iUnion_le A,
    fun E _ hE => tendsto_measure_iUnion_atTop hE,
    fun F hF hFa h0 => tendsto_measure_iInter_atTop (fun n => (hF n).nullMeasurableSet) hFa
      ⟨0, h0.ne⟩⟩

/-- The finite start cannot be dropped: under counting measure on the whole numbers, the tails
`{n, n+1, ...}` shrink and each has infinitely many members, yet no number lies in all of them,
so their sizes do not tend to the size of their intersection, which is 0. -/
theorem counting_measure_tails_not_continuous_from_above :
    Antitone (fun n : ℕ => Ici n) ∧
    (∀ n : ℕ, Measure.count (Ici n) = ∞) ∧
    Measure.count (⋂ n : ℕ, Ici n) = 0 ∧
    ¬ Tendsto (fun n : ℕ => Measure.count (Ici n)) atTop
        (𝓝 (Measure.count (⋂ n : ℕ, Ici n))) := by
  have hinf : ∀ n : ℕ, Measure.count (Ici n) = ∞ := fun n =>
    Measure.count_apply_infinite (Set.infinite_of_not_bddAbove (not_bddAbove_Ici n))
  have hempty : (⋂ n : ℕ, Ici n) = ∅ := by
    ext x
    simp only [mem_iInter, mem_Ici, mem_empty_iff_false, iff_false, not_forall, not_le]
    exact ⟨x + 1, Nat.lt_succ_self x⟩
  refine ⟨fun a b hab => Ici_subset_Ici.mpr hab, hinf, by rw [hempty]; simp, ?_⟩
  rw [hempty, measure_empty]
  simp only [hinf]
  rw [tendsto_const_nhds_iff]
  exact ENNReal.top_ne_zero

/- The card's worked numbers, as exact fractions in sq km. -/

-- Flood stage 1: 5 km by 1 km is 5 sq km; the union: 5 km by 2 km is 10 sq km.
example : (5 : ℚ) * 1 = 5 ∧ (5 : ℚ) * 2 = 10 := by norm_num

-- Flood stage 3 by layers: 5 + 2.5 + 1.25 = 8.75 = 10 - 10/2^3.
example : (5 : ℚ) + 5 / 2 + 5 / 4 = 35 / 4 ∧ (10 : ℚ) - 10 / 2 ^ 3 = 35 / 4 := by norm_num

-- Stage 3 by monotonicity: stage 2 plus the band, 7.5 + 1.25 = 8.75.
example : (15 / 2 : ℚ) + 5 / 4 = 35 / 4 := by norm_num

-- Stage n by layers equals 10 - 10/2^n, for n = 10: 9.990234375 sq km.
example : ∑ j ∈ Finset.range 10, (5 : ℚ) / 2 ^ j = 10 - 10 / 2 ^ 10 ∧
    (10 : ℚ) - 10 / 2 ^ 10 = 9990234375 / 1000000000 := by norm_num [Finset.sum_range_succ]

-- Survey: three photographs sum to 4 + 2 + 1 = 7; their new pieces 4 + 1 + 0.5 = 5.5 = 6 - 4/2^3.
example : (4 : ℚ) + 2 + 1 = 7 ∧ (4 : ℚ) + 1 + 1 / 2 = 11 / 2 ∧ (6 : ℚ) - 4 / 2 ^ 3 = 11 / 2 := by
  norm_num

-- Reservoir day 4: 3 + 6/2^4 = 3.375; the pool: 3 km by 1 km is 3 sq km.
example : (3 : ℚ) + 6 / 2 ^ 4 = 27 / 8 ∧ (3 : ℚ) * 1 = 3 := by norm_num

-- Not nested: bands of 5 and 5 sq km, union 10, common part 0.
example : (5 : ℚ) + 5 = 10 := by norm_num

#print axioms measure_mono_subadditive_continuous
#print axioms counting_measure_tails_not_continuous_from_above
