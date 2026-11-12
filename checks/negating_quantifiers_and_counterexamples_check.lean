-- Negating a quantifier: on any listed group, "not every covered case passes" equals "some covered case fails", and "not some case passes" equals "every case fails".
import Mathlib.Data.Finset.Card
import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Fin.VecNotation

/-- Not-every is some-not, with the description kept on: for any listed group `s`,
a description `P` (which cases the claim covers) and a yes/no test `Q`,
"it is not true that every case in `s` fitting `P` passes `Q`" holds exactly when
"some case in `s` fits `P` and fails `Q`" — that is, when there is a counterexample. -/
theorem not_every_iff_some_counterexample {α : Type*} (s : Finset α) (P Q : α → Prop) :
    (¬ ∀ x ∈ s, P x → Q x) ↔ ∃ x ∈ s, P x ∧ ¬ Q x := by
  simp only [not_forall, exists_prop, and_assoc]

/-- Not-some is every-not: for any listed group `s` and yes/no test `R`,
"it is not true that some case in `s` passes `R`" holds exactly when
"every case in `s` fails `R`" — so killing a "some" claim means checking them all. -/
theorem not_some_iff_every_fails {α : Type*} (s : Finset α) (R : α → Prop) :
    (¬ ∃ x ∈ s, R x) ↔ ∀ x ∈ s, ¬ R x := by
  simp only [not_exists, not_and]

/-- Road 2, by counting: an "every" claim on a listed group is false exactly when
the number of counterexamples (covered cases that fail) is at least 1. -/
theorem not_every_iff_counterexample_count_pos {α : Type*} (s : Finset α)
    (P Q : α → Prop) [DecidablePred P] [DecidablePred Q] :
    (¬ ∀ x ∈ s, P x → Q x) ↔ 1 ≤ (s.filter (fun x => P x ∧ ¬ Q x)).card := by
  rw [Nat.one_le_iff_ne_zero, Ne, Finset.card_eq_zero, ← Ne, ← Finset.nonempty_iff_ne_empty]
  simp only [Finset.Nonempty, Finset.mem_filter, not_forall, exists_prop, and_assoc]

/-! The gate: bags 1 to 5 (indices 0 to 4), weights in kg, and whether each went in the cabin. -/

def kg : Fin 5 → ℕ := ![4, 5, 6, 9, 11]
def cabin : Fin 5 → Bool := ![true, true, false, false, false]

-- The sign covers 3 bags; of those, 1 was refused, and it is bag 3 at 6 kg.
example : (Finset.univ.filter (fun i : Fin 5 => kg i < 7)).card = 3 := by decide
example : (Finset.univ.filter (fun i : Fin 5 => kg i < 7 ∧ cabin i = false)).card = 1 := by decide
example : Finset.univ.filter (fun i : Fin 5 => kg i < 7 ∧ cabin i = false) = {2} := by decide
example : kg 2 = 6 := by decide
-- "Every bag under 7 kg in the cabin?" F.
example : ¬ ∀ i : Fin 5, kg i < 7 → cabin i = true := by decide
-- "Some bag under 7 kg refused?" T.
example : ∃ i : Fin 5, kg i < 7 ∧ cabin i = false := by decide
-- "Some bag over 20 kg?" F.
example : ¬ ∃ i : Fin 5, kg i > 20 := by decide
-- "Every bag 20 kg or under?" T.
example : ∀ i : Fin 5, kg i ≤ 20 := by decide
-- The wreck, "every under-7 bag refused": F.
example : ¬ ∀ i : Fin 5, kg i < 7 → cabin i = false := by decide
-- All 8 yes/no patterns for the three light bags: both swaps hold.
example : ∀ a b c : Bool,
    (!(a && b && c)) = (!a || !b || !c) ∧ (!(a || b || c)) = (!a && !b && !c) := by decide

#print axioms not_every_iff_some_counterexample
#print axioms not_some_iff_every_fails
#print axioms not_every_iff_counterexample_count_pos
