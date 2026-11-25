-- Kleene's recursion theorem: every computable rewrite of program codes has a code that behaves exactly like its own rewrite, and from it no program decides a nontrivial property of behaviour.
import Mathlib.Computability.PartrecCode
import Mathlib.Computability.Halting

open Nat.Partrec

/-- Kleene's recursion theorem, fixed-point form: for every computable (always halting)
rewrite `f` of program codes there is a program code `e` whose behaviour equals the
behaviour of its rewrite, `φ_e = φ_{f(e)}`. -/
theorem kleene_recursion_fixed_point {f : Code → Code} (hf : Computable f) :
    ∃ e : Code, Code.eval e = Code.eval (f e) := by
  obtain ⟨c, hc⟩ := Code.fixed_point hf
  exact ⟨c, hc.symm⟩

/-- The programmer's form: for every partial computable task `T` that receives a program
text and an input, some program `R` runs `T` on its own code, `R(x) = T(⟨R⟩, x)` for every
input `x`. -/
theorem program_runs_task_on_own_code {T : Code → ℕ →. ℕ} (hT : Partrec₂ T) :
    ∃ R : Code, ∀ x : ℕ, Code.eval R x = T R x := by
  obtain ⟨c, hc⟩ := Code.fixed_point₂ hT
  exact ⟨c, fun x => congrFun hc x⟩

/-- Rice's theorem, reproved from the recursion theorem: if a property `P` of behaviour is
held by some program `a` and not held by some program `b`, then no program decides, for every
program code `c`, whether the behaviour of `c` has `P`. -/
theorem no_decider_for_nontrivial_behaviour_property (P : Set (ℕ →. ℕ)) (a b : Code)
    (ha : Code.eval a ∈ P) (hb : Code.eval b ∉ P) :
    ¬ ComputablePred fun c : Code => Code.eval c ∈ P := by
  intro h
  exact hb (ComputablePred.rice P h (Code.exists_code.2 ⟨a, rfl⟩) (Code.exists_code.2 ⟨b, rfl⟩) ha)

-- The card's worked whole-number facts.
-- The Python quine line has 31 characters.
example : "s='s=%r;print(s%%s)';print(s%s)".length = 31 := by decide
-- The toy quine L4:DQWCDQWC has 11 characters.
example : "L4:DQWCDQWC".length = 11 := by decide
-- The self-length program has 13 characters, and its output is 13.
example : "L5:DQWCNDQWCN".length = 13 := by decide
-- The fixed points of "quote it" and "print its length" have 15 and 17 characters.
example : "L6:DQWCQEDQWCQE".length = 15 := by decide
example : "L7:DQWCNQEDQWCNQE".length = 17 := by decide
-- The fixed point of "run it, then add !" has 32 characters.
example : "L14:DQWCL5:L1:!CCEDQWCL5:L1:!CCE".length = 32 := by decide
-- The search space: a literal of up to 4 letters from D, Q, W, C, then up to 4 more,
-- gives (1 + 4 + 16 + 64 + 256)^2 = 116,281 programs.
example : (4 ^ 0 + 4 ^ 1 + 4 ^ 2 + 4 ^ 3 + 4 ^ 4) ^ 2 = 116281 := by decide
-- The capped deciders: C's own 6 steps plus the cap.
example : 6 + 100 = 106 ∧ 6 + 300 = 306 := by decide

#print axioms kleene_recursion_fixed_point
#print axioms program_runs_task_on_own_code
#print axioms no_decider_for_nontrivial_behaviour_property
