-- If-then: an if-then sentence is false only when its if part holds and its then part fails, its contrapositive always agrees with it, and its converse disagrees exactly when the two parts differ.
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Fintype.Card
import Mathlib.Algebra.Ring.Parity

/-- An if-then promise breaks only one way: for any two yes-or-no statements P and Q,
"if P then Q" is false exactly when P happens and Q fails to follow. -/
theorem if_then_false_iff_if_and_not_then (P Q : Prop) : ¬ (P → Q) ↔ P ∧ ¬ Q := by
  exact not_imp

/-- The contrapositive is the same promise: "if P then Q" holds exactly when
"if not Q then not P" holds. -/
theorem if_then_iff_contrapositive (P Q : Prop) : (P → Q) ↔ (¬ Q → ¬ P) := by
  exact not_imp_not.symm

/-- The converse is a different promise: "if P then Q" and its converse "if Q then P"
give the same verdict exactly when P and Q have the same answer, so they disagree on the
two rows where the halves differ. -/
theorem if_then_iff_converse_iff (P Q : Prop) : ((P → Q) ↔ (Q → P)) ↔ (P ↔ Q) := by
  by_cases hp : P <;> by_cases hq : Q <;> simp [hp, hq]

-- The four customers in the order Ana, Ben, Cal, Dee: (cracked, replaced free), 1 = true, 0 = false.
-- The warranty's verdicts are 1, 0, 1, 1.
example : [(true, true), (true, false), (false, true), (false, false)].map
    (fun p : Bool × Bool => decide (p.1 = true → p.2 = true)) = [true, false, true, true] := by
  decide

-- The second route, "no crack, or replaced free", gives the same verdicts 1, 0, 1, 1.
example : [(true, true), (true, false), (false, true), (false, false)].map
    (fun p : Bool × Bool => decide (p.1 = false ∨ p.2 = true)) = [true, false, true, true] := by
  decide

-- The converse, "if replaced free, then it cracked", reads 1, 1, 0, 1: Cal's row is 0.
example : [(true, true), (true, false), (false, true), (false, false)].map
    (fun p : Bool × Bool => decide (p.2 = true → p.1 = true)) = [true, true, false, true] := by
  decide

-- The contrapositive, "if not replaced free, then no crack", reads 1, 0, 1, 1.
example : [(true, true), (true, false), (false, true), (false, false)].map
    (fun p : Bool × Bool => decide (p.2 = false → p.1 = false)) = [true, false, true, true] := by
  decide

-- Of the 4 rows, the warranty is broken on exactly 1 (Ben's).
example : (Finset.univ.filter
    (fun p : Bool × Bool => ¬ (p.1 = true → p.2 = true))).card = 1 := by
  decide

-- The converse disagrees with the warranty on 2 rows (Ben and Cal).
example : (Finset.univ.filter
    (fun p : Bool × Bool => ((p.1 = true → p.2 = true) ↔ (p.2 = true → p.1 = true)) → False)).card
      = 2 := by
  decide

-- The contrapositive disagrees with the warranty on 0 rows.
example : (Finset.univ.filter
    (fun p : Bool × Bool => ((p.1 = true → p.2 = true) ↔ (p.2 = false → p.1 = false)) → False)).card
      = 0 := by
  decide

-- "If 2 is odd, then 1 = 0" reads 1: the if part never happens.
example : Odd (2 : ℕ) → (1 : ℕ) = 0 := by decide

#print axioms if_then_false_iff_if_and_not_then
#print axioms if_then_iff_contrapositive
#print axioms if_then_iff_converse_iff
