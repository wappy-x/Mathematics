-- Logical equivalence and De Morgan: for any two yes-or-no sentences, "not (A or B)" says the same as "(not A) and (not B)", "not (A and B)" says the same as "(not A) or (not B)", and "not both" is not the same as "neither".
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Fintype.Card

/-- De Morgan's laws: for any two sentences p and q, each plainly true or false,
"not (p or q)" is equivalent to "(not p) and (not q)", and
"not (p and q)" is equivalent to "(not p) or (not q)". Here "or" is inclusive
and the "not" covers the whole bracket. -/
theorem de_morgan_laws (p q : Prop) :
    (¬ (p ∨ q) ↔ ¬ p ∧ ¬ q) ∧ (¬ (p ∧ q) ↔ ¬ p ∨ ¬ q) := by
  constructor
  · exact not_or
  · exact not_and_or

/-- The truth-table form: with nuts and dairy each a plain yes or no, both laws give
the same answer on every one of the four dishes. -/
theorem de_morgan_every_dish :
    ∀ nuts dairy : Bool,
      (!(nuts || dairy)) = (!nuts && !dairy) ∧ (!(nuts && dairy)) = (!nuts || !dairy) := by
  intro nuts dairy
  cases nuts <;> cases dairy <;> decide

/-- The usual mistake: "not both nuts and dairy" is not equivalent to "no nuts and no
dairy"; some dish gets different answers from the two. -/
theorem not_both_ne_neither :
    ¬ ∀ nuts dairy : Bool, (!(nuts && dairy)) = (!nuts && !dairy) := by
  intro h
  have := h true false
  revert this
  decide

-- Dish 2 by hand (nuts yes, dairy no): "nuts or dairy" is yes, its flip is no,
-- "no nuts and no dairy" is no; "nuts and dairy" is no, its flip is yes,
-- "(no nuts) or (no dairy)" is yes.
example : (true || false) = true ∧ (!(true || false)) = false ∧ (!true && !false) = false := by
  decide
example : (true && false) = false ∧ (!(true && false)) = true ∧ (!true || !false) = true := by
  decide

-- There are exactly four dishes: two yes-or-no questions.
example : Fintype.card (Bool × Bool) = 4 := by decide

-- Law 1 holds on all 4 rows, and law 2 holds on all 4 rows.
example : (Finset.univ.filter
    (fun d : Bool × Bool => (!(d.1 || d.2)) = (!d.1 && !d.2))).card = 4 := by decide
example : (Finset.univ.filter
    (fun d : Bool × Bool => (!(d.1 && d.2)) = (!d.1 || !d.2))).card = 4 := by decide

-- The menu note lets 1 dish through; "not both" lets 3 through.
example : (Finset.univ.filter (fun d : Bool × Bool => (!d.1 && !d.2) = true)).card = 1 := by
  decide
example : (Finset.univ.filter (fun d : Bool × Bool => (!(d.1 && d.2)) = true)).card = 3 := by
  decide

-- "Not both" and the note disagree on 2 dishes: dishes 2 and 3.
example : (Finset.univ.filter
    (fun d : Bool × Bool => (!(d.1 && d.2)) ≠ (!d.1 && !d.2))).card = 2 := by decide
example : (!(true && false)) ≠ (!true && !false) ∧ (!(false && true)) ≠ (!false && !true) := by
  decide

-- Forgetting the flip: "(no nuts) or (no dairy)" is true on 3 dishes, not 1.
example : (Finset.univ.filter (fun d : Bool × Bool => (!d.1 || !d.2) = true)).card = 3 := by
  decide

-- Dropping the brackets: "(no nuts) or dairy" lets dish 1 (nuts and dairy) through,
-- where "not (nuts or dairy)" says no.
example : (!true || true) = true ∧ (!(true || true)) = false := by decide

#print axioms de_morgan_laws
#print axioms de_morgan_every_dish
#print axioms not_both_ne_neither
