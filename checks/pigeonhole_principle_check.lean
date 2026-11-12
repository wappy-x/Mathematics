-- Pigeonhole: when finitely many pigeons each land in one of fewer holes, two share a hole, so no such placing is one-to-one, and more than n times as many pigeons as holes puts more than n in some hole.
import Mathlib.Combinatorics.Pigeonhole
import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Fintype.Pigeonhole

open Finset

/-- More pigeons than holes means some hole holds two: put a finite set of pigeons `α`
into a finite set of holes `β`, every pigeon into exactly one hole (a function `f`). If
there are strictly more pigeons than holes, then two different pigeons land in the same
hole, whatever the placing. -/
theorem more_pigeons_than_holes_some_hole_holds_two {α β : Type*} [Fintype α] [Fintype β]
    (f : α → β) (h : Fintype.card β < Fintype.card α) :
    ∃ x y, x ≠ y ∧ f x = f y := by
  exact Fintype.exists_ne_map_eq_of_card_lt f h

/-- Said as a function: from a bigger finite set into a smaller one, no function is
one-to-one. -/
theorem no_one_to_one_function_into_smaller_finite_set {α β : Type*} [Fintype α] [Fintype β]
    (h : Fintype.card β < Fintype.card α) (f : α → β) :
    ¬ Function.Injective f := by
  intro hf
  exact absurd (Fintype.card_le_of_injective f hf) (not_le.mpr h)

/-- More than one round: if there are more than `n` pigeons for every hole (more pigeons than
`n` times the holes), then some hole holds more than `n` pigeons. Twenty-five guests in
twelve months: 12 × 2 = 24 < 25, so some month holds three. -/
theorem more_than_n_rounds_some_hole_holds_more_than_n {α β : Type*} [Fintype α] [Fintype β]
    [DecidableEq β] (f : α → β) (n : ℕ) (h : n * Fintype.card β < Fintype.card α) :
    ∃ y : β, n < #(univ.filter fun x => f x = y) := by
  rw [mul_comm] at h
  exact Fintype.exists_lt_card_fiber_of_mul_lt_card f h

/-! ### The card's worked numbers -/

-- The dinner: 12 months hold 12 guests with nothing shared, 13 turned up, 1 left over.
example : 12 * 1 = 12 ∧ 12 < 13 ∧ 13 - 12 = 1 := by decide
-- Twenty-five guests, twelve months: two rounds place 24, and 25 turned up.
example : 12 * 2 = 24 ∧ 24 < 25 := by decide
-- The sentence: 27 words, 26 letters to start them, 1 word left over.
example : 26 * 1 < 27 ∧ 27 - 26 = 1 := by decide

/-- The card's dinner placing, months numbered January = 0 to December = 11: guest `i + 1`
was born in month `born i`. -/
def born : Fin 13 → Fin 12 :=
  ![2, 10, 6, 0, 8, 11, 3, 5, 1, 7, 4, 9, 6]

-- Guests 3 and 13 share July (month 6).
example : born 2 = 6 ∧ born 12 = 6 := by decide
-- Exactly 1 month holds two or more guests, 11 hold one, and none is empty.
example : #(univ.filter fun m : Fin 12 => 2 ≤ #(univ.filter fun g => born g = m)) = 1 := by
  decide
example : #(univ.filter fun m : Fin 12 => #(univ.filter fun g => born g = m) = 1) = 11 := by
  decide
example : #(univ.filter fun m : Fin 12 => #(univ.filter fun g => born g = m) = 0) = 0 := by
  decide
-- What breaks: the first 12 guests into 12 months all sit apart.
example : Function.Injective (fun g : Fin 12 => born (Fin.castSucc g)) := by decide
-- Every guest born a month later: the shared month moves to August (month 7).
example : (born 2 + 1 : Fin 12) = 7 ∧ (born 12 + 1 : Fin 12) = 7 := by decide

#print axioms more_pigeons_than_holes_some_hole_holds_two
#print axioms no_one_to_one_function_into_smaller_finite_set
#print axioms more_than_n_rounds_some_hole_holds_more_than_n
