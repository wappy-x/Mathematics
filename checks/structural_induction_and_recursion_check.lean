-- Structural induction: every knockout bracket built by the two rules plays one game fewer than it has teams, every formula built from p, q, not and (bracketed) and has as many "(" as ")", and a recursion whose every call shrinks a counting-number measure has exactly one answer.
import Mathlib.Data.Tree.Basic
import Mathlib.Data.List.Count
import Mathlib.Data.Nat.GCD.Basic
import Mathlib.Order.WellFounded
import Mathlib.Tactic.NormNum

open BinaryTree

/-! A bracket is a `BinaryTree Unit`: `nil` is a lone team, and `L △ R` joins two brackets with
one final. Mathlib's `numLeaves` counts the teams, `numNodes` counts the finals (the games),
and `height` is the most games a team can play. -/

/-- Every knockout bracket, built from lone teams by joining two brackets with one final, plays
exactly one game fewer than it has teams: games(T) = teams(T) − 1. -/
theorem games_eq_teams_sub_one (T : BinaryTree Unit) :
    T.numNodes = T.numLeaves - 1 := by
  rw [numLeaves_eq_numNodes_succ]
  rfl

/-- Formulas built from the two plain statements p and q by two rules: from A make not A, and
from A and B make (A and B). Each formula has one build. -/
inductive Formula : Type
  | p : Formula
  | q : Formula
  | neg : Formula → Formula
  | conj : Formula → Formula → Formula
  deriving DecidableEq

/-- How a formula is written out, character by character: "not A" and "(A and B)". -/
def Formula.write : Formula → List Char
  | .p => ['p']
  | .q => ['q']
  | .neg a => "not ".toList ++ a.write
  | .conj a b => ['('] ++ a.write ++ " and ".toList ++ b.write ++ [')']

/-- Every formula built from p and q by the not rule and the bracketed and rule has as many
"(" as ")" when written out. -/
theorem formula_open_count_eq_close_count (f : Formula) :
    f.write.count '(' = f.write.count ')' := by
  induction f with
  | p => decide
  | q => decide
  | neg a ih =>
    simp only [Formula.write, List.count_append, ih]
    rfl
  | conj a b iha ihb =>
    have h1 : List.count '(' " and ".toList = 0 := by decide
    have h2 : List.count ')' " and ".toList = 0 := by decide
    have h3 : List.count '(' ['('] = 1 := by decide
    have h4 : List.count ')' ['('] = 0 := by decide
    have h5 : List.count '(' [')'] = 0 := by decide
    have h6 : List.count ')' [')'] = 1 := by decide
    simp only [Formula.write, List.count_append, iha, ihb, h1, h2, h3, h4, h5, h6]
    omega

/-- Well-founded recursion: if a rule works out the answer at `x` from answers at pieces that are
smaller by a counting-number measure `m` (a measure that cannot fall forever), then exactly one
function obeys the rule at every input, so the recursion is sure to stop with a single answer. -/
theorem well_founded_recursion_has_unique_answer {α β : Type*} (m : α → ℕ)
    (rule : ∀ x : α, (∀ y : α, m y < m x → β) → β) :
    ∃! f : α → β, ∀ x, f x = rule x (fun y _ => f y) := by
  have hwf : WellFounded (fun a b : α => m a < m b) := (measure m).wf
  refine ⟨hwf.fix (fun x g => rule x g), fun x => hwf.fix_eq _ x, ?_⟩
  intro g hg
  funext x
  induction x using hwf.induction with
  | _ x ih =>
    rw [hg x, hwf.fix_eq]
    congr 1
    funext y hy
    exact ih y hy

/-- The bracket built by doubling: `doubled k` has 2^k teams, two copies joined by a final. -/
def doubled : ℕ → BinaryTree Unit
  | 0 => nil
  | k + 1 => doubled k △ doubled k

/-- A 5-bowler stepladder: the fifth seed plays the fourth, the winner plays the third, and so on. -/
def stepladder : BinaryTree Unit := (((nil △ nil) △ nil) △ nil) △ nil

-- The 16-team draw: 16 teams, height 4, 15 games.
example : (doubled 4).numLeaves = 16 ∧ (doubled 4).height = 4 ∧ (doubled 4).numNodes = 15 := by
  decide
-- The 64-team draw: 64 teams, height 6, 63 games.
example : (doubled 6).numLeaves = 64 ∧ (doubled 6).height = 6 ∧ (doubled 6).numNodes = 63 := by
  decide
-- The stepladder: 5 bowlers, height 4, 4 games.
example : stepladder.numLeaves = 5 ∧ stepladder.height = 4 ∧ stepladder.numNodes = 4 := by
  decide
-- Doubling 1, 2, 4, 8, 16 teams gives 0, 1, 3, 7, 15 games.
example : (List.range 5).map (fun k => (doubled k).numNodes) = [0, 1, 3, 7, 15] := by
  decide
-- (not (p and q) and p) has 2 "(" and 2 ")".
example : (Formula.conj (.neg (.conj .p .q)) .p).write = "(not (p and q) and p)".toList := by
  decide
example : (Formula.conj (.neg (.conj .p .q)) .p).write.count '(' = 2 ∧
    (Formula.conj (.neg (.conj .p .q)) .p).write.count ')' = 2 := by
  decide
-- Euclid on 63 and 15: (63, 15) → (15, 3) → (3, 0), answer 3.
example : 63 % 15 = 3 ∧ 15 % 3 = 0 ∧ Nat.gcd 63 15 = 3 := by
  decide

#print axioms games_eq_teams_sub_one
#print axioms formula_open_count_eq_close_count
#print axioms well_founded_recursion_has_unique_answer
