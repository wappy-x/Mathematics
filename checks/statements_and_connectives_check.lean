-- Statements and connectives: two true-or-false statements can land only four ways, so a joining word's rule is fixed by its four-line truth table, on which and is true once, or three times, and not flips each value.
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Fintype.Card
import Mathlib.Data.Bool.Basic

/-- A joining word's rule can be written out in full: when each part is true or false and
nothing between, any two rules for joining two statements are the same rule exactly when
they give the same answer on the four lines of the truth table. -/
theorem connective_settled_by_truth_table (f g : Bool → Bool → Bool) :
    f = g ↔ (f true true = g true true ∧ f true false = g true false ∧
      f false true = g false true ∧ f false false = g false false) := by
  constructor
  · rintro rfl
    exact ⟨rfl, rfl, rfl, rfl⟩
  · rintro ⟨h1, h2, h3, h4⟩
    funext a b
    cases a <;> cases b <;> assumption

/-- There are only four ways two statements can land, and on those four lines "and" is
true on exactly one, while inclusive "or" is true on exactly three. -/
theorem truth_table_four_lines_and_one_or_three :
    Fintype.card (Bool × Bool) = 4 ∧
    (Finset.univ.filter (fun x : Bool × Bool => (x.1 && x.2) = true)).card = 1 ∧
    (Finset.univ.filter (fun x : Bool × Bool => (x.1 || x.2) = true)).card = 3 := by
  refine ⟨by decide, by decide, by decide⟩

/-- "Not" just flips: it turns every truth value into the other one, and flipping twice
brings you back to where you started. -/
theorem not_flips_and_twice_returns (p : Bool) : (!p) ≠ p ∧ (!!p) = p := by
  cases p <;> decide

-- The four people at the door: (showed ID, over 21) for Nia, Sam, Ray and Jo.
-- Nia: yes, yes. Not over 21 is no; and is yes; or is yes.
example : (!true) = false ∧ (true && true) = true ∧ (true || true) = true := by decide
-- Sam: yes, no. Not over 21 is yes; and is no; or is yes.
example : (!false) = true ∧ (true && false) = false ∧ (true || false) = true := by decide
-- Ray: no, yes. Not over 21 is no; and is no; or is yes.
example : (!true) = false ∧ (false && true) = false ∧ (false || true) = true := by decide
-- Jo: no, no. Not over 21 is yes; and is no; or is no.
example : (!false) = true ∧ (false && false) = false ∧ (false || false) = false := by decide

-- And lets in 1 of 4, or would let in 3 of 4, and "not over 21" is true for 2 of 4.
example : ([(true, true), (true, false), (false, true), (false, false)].filter
    (fun x : Bool × Bool => x.1 && x.2)).length = 1 := by decide
example : ([(true, true), (true, false), (false, true), (false, false)].filter
    (fun x : Bool × Bool => x.1 || x.2)).length = 3 := by decide
example : ([(true, true), (true, false), (false, true), (false, false)].filter
    (fun x : Bool × Bool => !x.2)).length = 2 := by decide

-- The mistakes: reading "or" as one-but-not-both lets in 2 of 4, and Nia is refused;
-- checking only the ID lets in 2 of 4.
example : ([(true, true), (true, false), (false, true), (false, false)].filter
    (fun x : Bool × Bool => xor x.1 x.2)).length = 2 := by decide
example : xor true true = false := by decide
example : ([(true, true), (true, false), (false, true), (false, false)].filter
    (fun x : Bool × Bool => x.1)).length = 2 := by decide

#print axioms connective_settled_by_truth_table
#print axioms truth_table_four_lines_and_one_or_three
#print axioms not_flips_and_twice_returns
