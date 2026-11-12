-- Sets: a set is fixed by its members alone, so two sets with the same members are equal, there is exactly one set with no members, and the card's office guest list comes out as it says.
import Mathlib.Data.Set.Basic
import Mathlib.Data.Finset.Image
import Mathlib.Data.Finset.Card
import Mathlib.Data.List.Permutation

/-- Same members, same set (extensionality): for any two sets `A` and `B` of things of one
kind, `A` and `B` are the same set exactly when, for every candidate `x`, `x` is in `A`
precisely when `x` is in `B`. -/
theorem sets_equal_iff_same_members {α : Type*} (A B : Set α) :
    A = B ↔ ∀ x, x ∈ A ↔ x ∈ B := by
  constructor
  · rintro rfl x
    exact Iff.rfl
  · intro h
    exact Set.ext h

/-- The empty set: among sets of things of one kind, there is exactly one set with no
members, so any two rules that pick nobody name the same set. -/
theorem exactly_one_empty_set {α : Type*} :
    ∃! E : Set α, ∀ x, x ∉ E := by
  refine ⟨∅, fun x => Set.notMem_empty x, ?_⟩
  intro E hE
  exact Set.eq_empty_iff_forall_notMem.mpr hE

/-- Set-builder shorthand: two rules picking from the same fixed collection `S` name the same
set `{x ∈ S : p x} = {x ∈ S : q x}` exactly when they give the same yes-or-no answer for
every member of `S`. -/
theorem set_builder_equal_iff_same_answers {α : Type*} (S : Set α) (p q : α → Prop) :
    {x ∈ S | p x} = {x ∈ S | q x} ↔ ∀ x ∈ S, p x ↔ q x := by
  constructor
  · intro h x hx
    have h1 : x ∈ {x ∈ S | p x} ↔ x ∈ {x ∈ S | q x} := by rw [h]
    simpa [hx] using h1
  · intro h
    ext x
    simp only [Set.mem_ofPred_eq]
    constructor
    · rintro ⟨hx, hp⟩
      exact ⟨hx, (h x hx).mp hp⟩
    · rintro ⟨hx, hq⟩
      exact ⟨hx, (h x hx).mpr hq⟩

-- The office: five people with their ages.
example : ({("Ana", 24), ("Ben", 31), ("Cleo", 28), ("Dev", 41), ("Eli", 29)} :
    Finset (String × ℕ)).card = 5 := by decide
-- The guest list by the rule "under 30" is the roster {Ana, Cleo, Eli}, three guests.
example : (({("Ana", 24), ("Ben", 31), ("Cleo", 28), ("Dev", 41), ("Eli", 29)} :
    Finset (String × ℕ)).filter (fun p => p.2 < 30)).image Prod.fst =
    ({"Ana", "Cleo", "Eli"} : Finset String) := by decide
example : ({"Ana", "Cleo", "Eli"} : Finset String).card = 3 := by decide
-- Ana is on the list, Ben is not; the rule is strict, so a 30-year-old is out.
example : "Ana" ∈ ({"Ana", "Cleo", "Eli"} : Finset String) := by decide
example : "Ben" ∉ ({"Ana", "Cleo", "Eli"} : Finset String) := by decide
example : ¬ (30 < 30) := by decide
-- The scrambled spelling {Eli, Ana, Cleo, Ana} is the same set, three members, not four.
example : ({"Eli", "Ana", "Cleo", "Ana"} : Finset String) = {"Ana", "Cleo", "Eli"} := by decide
example : ({"Eli", "Ana", "Cleo", "Ana"} : Finset String).card = 3 := by decide
example : ["Eli", "Ana", "Cleo", "Ana"].length = 4 := by decide
-- Treated as an ordered list, three guests have 3 × 2 × 1 = 6 spellings.
example : (["Ana", "Cleo", "Eli"].permutations).length = 6 := by
  rw [List.length_permutations]; decide
-- Nobody under 20, nobody over 60: two rules, both the empty set.
example : ({("Ana", 24), ("Ben", 31), ("Cleo", 28), ("Dev", 41), ("Eli", 29)} :
    Finset (String × ℕ)).filter (fun p => p.2 < 20) = ∅ := by decide
example : ({("Ana", 24), ("Ben", 31), ("Cleo", 28), ("Dev", 41), ("Eli", 29)} :
    Finset (String × ℕ)).filter (fun p => 60 < p.2) = ∅ := by decide

#print axioms sets_equal_iff_same_members
#print axioms exactly_one_empty_set
#print axioms set_builder_equal_iff_same_answers
