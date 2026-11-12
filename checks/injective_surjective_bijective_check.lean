-- One-to-one and onto: a function is both one-to-one and onto exactly when every output has exactly one input arriving, on finite sets of equal size one-to-one and onto stand or fall together, more inputs than outputs rules out one-to-one and fewer rules out onto, and the card's clock and seatings come out as it says.
import Mathlib.Data.Fintype.Card
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Algebra.BigOperators.Group.Finset.Basic

open Function

/-- Both at once is a pairing. A function is one-to-one and onto (a bijection) exactly when
every output has exactly one input arriving at it. -/
theorem bijective_iff_exactly_one_arrives {α β : Type*} (f : α → β) :
    Bijective f ↔ ∀ b : β, ∃! a : α, f a = b := by
  exact Function.bijective_iff_existsUnique f

/-- On finite sets of the same size, the two tests tie together: if one passes, so does the
other. A function between two finite sets with equal counts is one-to-one exactly when it is
onto. -/
theorem injective_iff_surjective_of_card_eq {α β : Type*} [Fintype α] [Fintype β]
    (f : α → β) (h : Fintype.card α = Fintype.card β) :
    Injective f ↔ Surjective f := by
  constructor
  · intro hi
    exact ((Fintype.bijective_iff_injective_and_card f).2 ⟨hi, h⟩).2
  · intro hs
    exact ((Fintype.bijective_iff_surjective_and_card f).2 ⟨hs, h⟩).1

/-- Sizes settle half of it at most. Between finite sets, more inputs than outputs makes
one-to-one impossible, and fewer inputs than outputs makes onto impossible. -/
theorem size_rules_out_one_test {α β : Type*} [Fintype α] [Fintype β] (f : α → β) :
    (Fintype.card β < Fintype.card α → ¬ Injective f) ∧
      (Fintype.card α < Fintype.card β → ¬ Surjective f) := by
  constructor
  · intro hlt hi
    exact absurd (Fintype.card_le_of_injective f hi) (by omega)
  · intro hlt hs
    exact absurd (Fintype.card_le_of_surjective f hs) (by omega)

/-! The card's worked examples. Hours are 0 to 23; dial numbers, guests and seats are
numbered from 1, as on the card. -/

/-- The 12 dial numbers, 1 to 12. -/
abbrev DialNumber := {d : ℕ // d ∈ Finset.Icc 1 12}

/-- The clock: an hour of the day goes to its dial number; 00:00 and 12:00 both give 12. -/
def clock (h : Fin 24) : DialNumber :=
  ⟨if h.val % 12 = 0 then 12 else h.val % 12, by
    rw [Finset.mem_Icc]; split <;> omega⟩

/-- Guests and seats numbered 1 to `n`. -/
abbrev Numbered (n : ℕ) := {k : ℕ // k ∈ Finset.Icc 1 n}

/-- Guest 1 in seat 1, guest 2 in seat 2, down the row of eight. -/
def seated (g : Numbered 8) : Numbered 8 := g

/-- The same eight guests, same order, in a row of ten seats. -/
def seatedInTen (g : Numbered 8) : Numbered 10 :=
  ⟨g.val, by have := g.property; rw [Finset.mem_Icc] at this ⊢; omega⟩

/-- Nine guests into eight seats: the first eight as before, the ninth in seat 1. -/
def nineGuests (g : Numbered 9) : Numbered 8 :=
  ⟨if g.val = 9 then 1 else g.val, by
    have := g.property; rw [Finset.mem_Icc] at this ⊢; split <;> omega⟩

/-- Eight guests, eight seats, guests 3 and 4 both in seat 3: seats 1 2 3 3 5 6 7 8. -/
def crowded (g : Numbered 8) : Numbered 8 :=
  ⟨if g.val = 4 then 3 else g.val, by
    have := g.property; rw [Finset.mem_Icc] at this ⊢; split <;> omega⟩

/-- How many inputs arrive at the output `b`. -/
def arrivals {α β : Type*} [Fintype α] [DecidableEq β] (f : α → β) (b : β) : ℕ :=
  (Finset.univ.filter (fun a => f a = b)).card

-- The clock: 01:00 and 13:00 both give dial 1; 12:00 and 00:00 both give dial 12.
example : (clock 1).val = 1 ∧ (clock 13).val = 1 ∧ (clock 12).val = 12 ∧ (clock 0).val = 12 := by
  decide
-- 24 hours onto 12 dial numbers, 2 arriving at each: onto, not one-to-one.
example : Fintype.card (Fin 24) = 24 ∧ Fintype.card DialNumber = 12 := by decide
example : ∀ d : DialNumber, arrivals clock d = 2 := by decide
example : (Finset.univ.sum fun d : DialNumber => arrivals clock d) = 24 := by decide
example : Surjective clock ∧ ¬ Injective clock := by decide
-- Eight guests, eight seats: 1 arriving at each seat, one-to-one and onto.
example : ∀ s : Numbered 8, arrivals seated s = 1 := by decide
example : Injective seated ∧ Surjective seated := by decide
example : Bijective seated := by decide
-- The same eight guests in ten seats: one-to-one, not onto, 10 − 8 = 2 seats empty.
example : Injective seatedInTen ∧ ¬ Surjective seatedInTen := by decide
example : (Finset.univ.filter (fun s : Numbered 10 => arrivals seatedInTen s = 0)).card = 2 := by
  decide
-- Nine guests into eight seats: one seat holds 2, so not one-to-one.
example : arrivals nineGuests ⟨1, by decide⟩ = 2 ∧ ¬ Injective nineGuests := by decide
-- Two guests crowd seat 3: 7 seats of 8 filled, neither test passes.
example : (Finset.univ.filter (fun s : Numbered 8 => arrivals crowded s ≠ 0)).card = 7 := by
  decide
example : ¬ Injective crowded ∧ ¬ Surjective crowded := by decide

#print axioms bijective_iff_exactly_one_arrives
#print axioms injective_iff_surjective_of_card_eq
#print axioms size_rules_out_one_test
