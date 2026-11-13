-- The rules: for any probability, chances of separate events add, "not A" has chance one minus the chance of A, and overlapping events follow inclusion-exclusion for two and three events.
import Mathlib.MeasureTheory.Measure.Real
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.Data.Fintype.Prod
import Mathlib.Tactic.NormNum

open MeasureTheory

/-- Chances of separate events add, and "not A" has chance one minus the chance of A.
Here `μ` is any probability (chances at least 0, total chance 1, separate events add),
an event is a measurable set of outcomes, and `μ.real A` is the chance of A as a real number.
No independence is assumed. -/
theorem separate_events_add_and_complement_is_one_minus
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ] :
    (∀ A B : Set Ω, MeasurableSet A → MeasurableSet B → Disjoint A B →
        μ.real (A ∪ B) = μ.real A + μ.real B) ∧
    (∀ A : Set Ω, MeasurableSet A → μ.real Aᶜ = 1 - μ.real A) := by
  refine ⟨fun A B _ hB hd => measureReal_union hd hB, fun A hA => ?_⟩
  exact probReal_compl_eq_one_sub₀ hA.nullMeasurableSet

/-- When two events overlap, adding their chances counts the overlap twice,
so it is subtracted back: P(A ∪ B) = P(A) + P(B) - P(A ∩ B). -/
theorem prob_union_eq_add_sub_inter
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (A B : Set Ω) (hA : MeasurableSet A) (hB : MeasurableSet B) :
    μ.real (A ∪ B) = μ.real A + μ.real B - μ.real (A ∩ B) := by
  have h := measureReal_union_add_inter (μ := μ) (s := A) hB
  linarith

/-- Inclusion-exclusion for three events: add the single chances, subtract every
overlap of two, and add back the overlap of all three. -/
theorem prob_union_three_inclusion_exclusion
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (A B C : Set Ω) (hA : MeasurableSet A) (hB : MeasurableSet B) (hC : MeasurableSet C) :
    μ.real (A ∪ B ∪ C) =
      μ.real A + μ.real B + μ.real C
        - μ.real (A ∩ B) - μ.real (A ∩ C) - μ.real (B ∩ C)
        + μ.real (A ∩ B ∩ C) := by
  have h1 := measureReal_union_add_inter (μ := μ) (s := A ∪ B) hC
  have h2 := measureReal_union_add_inter (μ := μ) (s := A) hB
  have h3 := measureReal_union_add_inter (μ := μ) (s := A ∩ C) (hB.inter hC)
  have e1 : (A ∪ B) ∩ C = A ∩ C ∪ B ∩ C := Set.union_inter_distrib_right A B C
  have e2 : A ∩ C ∩ (B ∩ C) = A ∩ B ∩ C := by
    ext x; simp only [Set.mem_inter_iff]; tauto
  rw [e1] at h1
  rw [e2] at h3
  linarith

-- The gambler's bet, four rolls of one die: 1296 sequences, 625 with no six, 671 with a six.
example : (6 : ℕ) ^ 4 = 1296 ∧ (5 : ℕ) ^ 4 = 625 ∧ 1296 - 625 = 671 := by norm_num
-- The complement rule on the bet: 1 - (5/6)^4 = 671/1296.
example : (1 : ℚ) - (5 / 6) ^ 4 = 671 / 1296 := by norm_num
-- Split by where the first six lands: 216 + 180 + 150 + 125 = 671.
example : 6 ^ 3 + 5 * 6 ^ 2 + 5 ^ 2 * 6 + 5 ^ 3 = (671 : ℕ) := by norm_num
-- Inclusion-exclusion on four rolls: 864 - 216 + 24 - 1 = 671.
example : (4 * 216 - 6 * 36 + 4 * 6 - 1 : ℤ) = 671 := by norm_num
-- House example, two dice: a six on the first or second die in 11 of 36 outcomes, counted directly.
example : (Finset.univ.filter (fun s : Fin 6 × Fin 6 => s.1 = 5 ∨ s.2 = 5)).card = 11 := by decide
-- The same by both roads: 6 + 6 - 1 = 11 and 36 - 25 = 11.
example : (6 + 6 - 1 : ℕ) = 11 ∧ (36 - 25 : ℕ) = 11 := by norm_num
-- Three rolls: 36 + 36 + 36 - 6 - 6 - 6 + 1 = 91, and 216 - 125 = 91.
example : (36 + 36 + 36 - 6 - 6 - 6 + 1 : ℤ) = 91 ∧ (216 - 125 : ℤ) = 91 := by norm_num
-- Three rolls counted directly: 91 of the 216 sequences contain a six.
example : (Finset.univ.filter
    (fun s : Fin 6 × Fin 6 × Fin 6 => s.1 = 5 ∨ s.2.1 = 5 ∨ s.2.2 = 5)).card = 91 := by decide

#print axioms separate_events_add_and_complement_is_one_minus
#print axioms prob_union_eq_add_sub_inter
#print axioms prob_union_three_inclusion_exclusion
