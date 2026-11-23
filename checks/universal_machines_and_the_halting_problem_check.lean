-- Universal machines: one partial recursive program runs every program from its code, and no total computable program decides, for every program and input, whether the run stops.
import Mathlib.Computability.Halting
import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Fintype.Pi
import Mathlib.Tactic.NormNum.Basic

open Nat.Partrec

/-- The universal machine: there is one program `U`, itself partial recursive, that is handed a
program's code `⟨M⟩` and an input `x` and gives what `M` gives on `x`; every partial recursive
function `f` is run this way by some code `c`. -/
theorem universal_machine_runs_every_program :
    ∃ U : Code × ℕ →. ℕ, Partrec U ∧
      ∀ f : ℕ →. ℕ, Nat.Partrec f → ∃ c : Code, ∀ x, U (c, x) = f x := by
  refine ⟨fun p => p.1.eval p.2, Nat.Partrec.Code.eval_part, ?_⟩
  intro f hf
  obtain ⟨c, hc⟩ := Nat.Partrec.Code.exists_code.1 hf
  exact ⟨c, fun x => by simp [hc]⟩

/-- The halting problem: no program `H` that always stops can answer, for every program code `c`
and every input `x`, `true` exactly when program `c` stops on input `x`. -/
theorem no_program_decides_halting :
    ¬ ∃ H : Code × ℕ → Bool, Computable H ∧
      ∀ c : Code, ∀ x : ℕ, H (c, x) = true ↔ (c.eval x).Dom := by
  rintro ⟨H, hH, hspec⟩
  apply ComputablePred.halting_problem 0
  refine ComputablePred.computable_iff.2 ⟨fun c => H (c, 0), ?_, ?_⟩
  · exact hH.comp (Computable.pair Computable.id (Computable.const 0))
  · funext c
    exact propext (hspec c 0).symm

/-- Flip the diagonal: in any table of yes-or-no answers, rows `i` against columns `x`, the row
made by flipping each diagonal cell `(x, x)` differs from every row of the table. -/
theorem flipped_diagonal_is_on_no_row (T : ℕ → ℕ → Bool) :
    ∀ i : ℕ, (fun x => !T x x) ≠ T i := by
  intro i h
  have := congrFun h i
  cases hT : T i i <;> simp [hT] at this

/-! The card's own worked numbers. -/

-- The card's halting table: five programs (rows) on inputs 0 to 4 (columns), `true` = stops.
-- Its flipped diagonal is `false, false, false, true, true`, and it is on no row.
example :
    let T : Fin 5 → Fin 5 → Bool :=
      ![![true, true, true, true, true],      -- 0 countdown
        ![false, true, true, true, true],     -- 1 collatz
        ![true, false, true, false, true],    -- 2 even-stop
        ![true, false, false, false, false],  -- 3 count-up
        ![true, true, true, false, false]]    -- 4 below-3
    (fun x => !T x x) = ![false, false, false, true, true] ∧
      ∀ i : Fin 5, (fun x => !T x x) ≠ T i := by
  decide

-- Countdown from k takes 3k + 1 steps: 7 from 2, 121 from 40.
example : 3 * 2 + 1 = 7 ∧ 3 * 40 + 1 = 121 := by norm_num

-- Count-up from 1 with numbers kept 0 to 255: 255 rounds of 3 steps, then the final test.
example : 3 * 255 + 1 = 766 := by norm_num

-- D against the cap-N decider: 1 step to ask, N steps of simulation, 1 step to stop.
example : 1 + 100 + 1 = 102 ∧ 1 + 300 + 1 = 302 := by norm_num

-- The Collatz loop from 27 reaches 1 after exactly 111 moves.
set_option maxRecDepth 100000 in
example :
    let step : ℕ → ℕ := fun n => if n % 2 = 0 then n / 2 else 3 * n + 1
    step^[111] 27 = 1 ∧ ∀ k < 111, step^[k] 27 ≠ 1 := by
  decide

#print axioms universal_machine_runs_every_program
#print axioms no_program_decides_halting
#print axioms flipped_diagonal_is_on_no_row
