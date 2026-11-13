-- Sample spaces and events: on a finite sample space, "and", "or" and "not" of yes-or-no questions are intersection, union and complement of their events, the union count is |A| + |S| - |A ∩ S|, there are 2^|Ω| events, and the two-dice counts on the card are exact.
import Mathlib.Data.Finset.Card
import Mathlib.Data.Finset.Powerset
import Mathlib.Data.Finset.Prod
import Mathlib.Data.Fintype.Basic
import Mathlib.Order.Interval.Finset.Nat

/-- On a finite sample space, every yes-or-no question is a set of outcomes (its event), and
"p and q", "p or q" and "not p" have as events the intersection, the union and the complement
of the events of p and q. -/
theorem and_or_not_are_intersection_union_complement {Ω : Type*} [Fintype Ω] [DecidableEq Ω]
    (p q : Ω → Prop) [DecidablePred p] [DecidablePred q] :
    Finset.univ.filter (fun ω => p ω ∧ q ω) = Finset.univ.filter p ∩ Finset.univ.filter q ∧
    Finset.univ.filter (fun ω => p ω ∨ q ω) = Finset.univ.filter p ∪ Finset.univ.filter q ∧
    Finset.univ.filter (fun ω => ¬ p ω) = (Finset.univ.filter p)ᶜ := by
  refine ⟨?_, ?_, ?_⟩ <;> ext ω <;> simp

/-- The count of "A or S": add the two counts and take the overlap off once,
|A ∪ S| = |A| + |S| - |A ∩ S|. -/
theorem card_union_eq_add_sub_card_inter {Ω : Type*} [DecidableEq Ω] (A S : Finset Ω) :
    (A ∪ S).card = A.card + S.card - (A ∩ S).card := by
  have h := Finset.card_union_add_card_inter A S
  omega

/-- On a finite sample space every subset is an event, so a space of n outcomes has 2^n events. -/
theorem number_of_events_eq_two_pow {α : Type*} (Ω : Finset α) :
    Ω.powerset.card = 2 ^ Ω.card := by
  exact Finset.card_powerset Ω

/-- The sample space of a red die and a white die: the 36 ordered pairs (i, j). -/
abbrev dice : Finset (ℕ × ℕ) := Finset.Icc 1 6 ×ˢ Finset.Icc 1 6

-- The sample space has 36 outcomes.
example : dice.card = 36 := by decide

-- "Total is 7" is the six pairs (1,6), (2,5), (3,4), (4,3), (5,2), (6,1).
example : dice.filter (fun w => w.1 + w.2 = 7) = {(1,6), (2,5), (3,4), (4,3), (5,2), (6,1)} := by
  decide
example : (dice.filter (fun w => w.1 + w.2 = 7)).card = 6 := by decide

-- "A six shows" has 11 outcomes.
example : (dice.filter (fun w => w.1 = 6 ∨ w.2 = 6)).card = 11 := by decide

-- "Total 7 and a six shows" is (1,6) and (6,1).
example : dice.filter (fun w => w.1 + w.2 = 7) ∩ dice.filter (fun w => w.1 = 6 ∨ w.2 = 6)
    = {(1,6), (6,1)} := by decide

-- "Total 7 or a six shows" has 15 outcomes: 6 + 11 - 2.
example : (dice.filter (fun w => w.1 + w.2 = 7) ∪ dice.filter (fun w => w.1 = 6 ∨ w.2 = 6)).card
    = 15 := by decide

-- "Not total 7" has 36 - 6 = 30 outcomes.
example : (dice \ dice.filter (fun w => w.1 + w.2 = 7)).card = 30 := by decide

-- De Morgan on the dice: not (A or S) = (not A) and (not S), 21 outcomes both ways.
example : dice \ (dice.filter (fun w => w.1 + w.2 = 7) ∪ dice.filter (fun w => w.1 = 6 ∨ w.2 = 6))
    = (dice \ dice.filter (fun w => w.1 + w.2 = 7)) ∩ (dice \ dice.filter (fun w => w.1 = 6 ∨ w.2 = 6))
    := by decide
example : (dice \ (dice.filter (fun w => w.1 + w.2 = 7) ∪
    dice.filter (fun w => w.1 = 6 ∨ w.2 = 6))).card = 21 := by decide

-- "Total 7" and "a double" are disjoint.
example : dice.filter (fun w => w.1 + w.2 = 7) ∩ dice.filter (fun w => w.1 = w.2) = ∅ := by decide

-- A double has 6 outcomes.
example : (dice.filter (fun w => w.1 = w.2)).card = 6 := by decide

-- The totals 2 to 12 hold 6 minus the distance from s to 7 outcomes each: 1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1.
example : ∀ s ∈ Finset.Icc 2 12,
    (dice.filter (fun w => w.1 + w.2 = s)).card = 6 - Int.natAbs ((s : ℤ) - 7) := by decide

-- The 11 total events cover all 36 outcomes.
example : (Finset.Icc 2 12).biUnion (fun s => dice.filter (fun w => w.1 + w.2 = s)) = dice := by
  decide

-- The two-dice space has 2^36 = 68,719,476,736 events.
example : 2 ^ dice.card = 68719476736 := by decide

#print axioms and_or_not_are_intersection_union_complement
#print axioms card_union_eq_add_sub_card_inter
#print axioms number_of_events_eq_two_pow
