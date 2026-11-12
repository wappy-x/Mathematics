-- Valid arguments: over all four yes-or-no situations, modus ponens and modus tollens have no counterexample, while affirming the consequent and denying the antecedent each fail on exactly one situation, on time with a fee.
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Fintype.Card

/-- Modus ponens and modus tollens are valid. Each fact is a plain yes or no, so a
situation is a pair (late, fee) of true/false values, and the rule "if late, then fee"
is one of the premises. Then no situation makes every premise true and the conclusion
false: not for Rosa (rule, late; so fee), and not for Sam (rule, no fee; so not late). -/
theorem modus_ponens_and_modus_tollens_valid :
    (¬ ∃ late fee : Bool, (late = true → fee = true) ∧ late = true ∧ ¬ fee = true) ∧
    (¬ ∃ late fee : Bool, (late = true → fee = true) ∧ fee = false ∧ ¬ late = false) := by
  decide

/-- Affirming the consequent is invalid: with the rule "if late, then fee" and "a fee"
as premises, the conclusion "late" fails in exactly one situation, on time with a fee,
(0, 1). -/
theorem affirming_the_consequent_fails_only_on_time_with_fee :
    ∀ late fee : Bool,
      ((late = true → fee = true) ∧ fee = true ∧ ¬ late = true) ↔
        (late = false ∧ fee = true) := by
  decide

/-- Denying the antecedent is invalid: with the rule "if late, then fee" and "not late"
as premises, the conclusion "no fee" fails in exactly one situation, the same one,
on time with a fee, (0, 1). -/
theorem denying_the_antecedent_fails_only_on_time_with_fee :
    ∀ late fee : Bool,
      ((late = true → fee = true) ∧ late = false ∧ ¬ fee = false) ↔
        (late = false ∧ fee = true) := by
  decide

-- The worked numbers. A situation is (late, fee); the rule is "not late, or a fee".
-- Situations to check: 4.
example : Fintype.card (Bool × Bool) = 4 := by decide

-- The rule by itself is false in exactly 1 situation, (1, 0).
example : (Finset.univ.filter (fun c : Bool × Bool => (!c.1 || c.2) = false)).card = 1 := by
  decide
example : Finset.univ.filter (fun c : Bool × Bool => (!c.1 || c.2) = false) = {(true, false)} := by
  decide

-- Rosa, modus ponens: premises hold in 1 situation, 0 counterexamples.
example : (Finset.univ.filter (fun c : Bool × Bool => (!c.1 || c.2) && c.1)).card = 1 := by
  decide
example : (Finset.univ.filter (fun c : Bool × Bool => (!c.1 || c.2) && c.1 && !c.2)).card = 0 := by
  decide

-- Sam, modus tollens: premises hold in 1 situation, 0 counterexamples.
example : (Finset.univ.filter (fun c : Bool × Bool => (!c.1 || c.2) && !c.2)).card = 1 := by
  decide
example : (Finset.univ.filter (fun c : Bool × Bool => (!c.1 || c.2) && !c.2 && c.1)).card = 0 := by
  decide

-- Tess, affirming the consequent: premises hold in 2 situations, 1 counterexample, (0, 1).
example : (Finset.univ.filter (fun c : Bool × Bool => (!c.1 || c.2) && c.2)).card = 2 := by
  decide
example : Finset.univ.filter (fun c : Bool × Bool => (!c.1 || c.2) && c.2 && !c.1)
    = {(false, true)} := by
  decide

-- Vic, denying the antecedent: premises hold in 2 situations, 1 counterexample, (0, 1).
example : (Finset.univ.filter (fun c : Bool × Bool => (!c.1 || c.2) && !c.1)).card = 2 := by
  decide
example : Finset.univ.filter (fun c : Bool × Bool => (!c.1 || c.2) && !c.1 && c.2)
    = {(false, true)} := by
  decide

-- Delete the promise (the rule always true): all four arguments get 1 counterexample each.
example : (Finset.univ.filter (fun c : Bool × Bool => c.1 && !c.2)).card = 1 ∧
    (Finset.univ.filter (fun c : Bool × Bool => !c.2 && c.1)).card = 1 ∧
    (Finset.univ.filter (fun c : Bool × Bool => c.2 && !c.1)).card = 1 ∧
    (Finset.univ.filter (fun c : Bool × Bool => !c.1 && c.2)).card = 1 := by
  decide

#print axioms modus_ponens_and_modus_tollens_valid
#print axioms affirming_the_consequent_fails_only_on_time_with_fee
#print axioms denying_the_antecedent_fails_only_on_time_with_fee
