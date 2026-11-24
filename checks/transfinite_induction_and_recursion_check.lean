-- Transfinite induction: a claim checked at 0, at every step and at every limit holds at every ordinal, exactly one sequence follows any rule that reads all earlier values, and the halving-toward-1 sequence never passes 1.
import Mathlib.SetTheory.Ordinal.Arithmetic
import Mathlib.Order.ConditionallyCompleteLattice.Basic
import Mathlib.Data.Real.Archimedean
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.IntervalCases

open Ordinal Order

/-- The card's main claim (transfinite induction): if a claim holds at 0, carries from every
ordinal α to α + 1, and holds at every limit l whenever it holds at every ordinal below l,
then it holds at every ordinal. (A limit is an ordinal that is not 0 and has no ordinal just
before it: Mathlib's `IsSuccLimit`. Every non-empty set of Mathlib's ordinals has a least
member, which is the card's fourth condition.) -/
theorem transfinite_induction {P : Ordinal → Prop}
    (zero : P 0)
    (succ : ∀ α, P α → P (α + 1))
    (limit : ∀ l, IsSuccLimit l → (∀ β < l, P β) → P l) :
    ∀ α, P α := by
  intro α
  exact Ordinal.limitRecOn α zero succ limit

/-- The recursion theorem (Step 3): take any rule that reads the list of all values before α
and returns one value. Then exactly one sequence along the ordinals takes, at every α, the
value the rule gives. -/
theorem recursion_theorem {X : Type*} (rule : (α : Ordinal) → ((β : Ordinal) → β < α → X) → X) :
    ∃! a : Ordinal → X, ∀ α, a α = rule α (fun β _ => a β) := by
  refine ⟨fun α => Ordinal.lt_wf.fix (fun α f => rule α f) α, ?_, ?_⟩
  · intro α
    exact Ordinal.lt_wf.fix_eq (fun α f => rule α f) α
  · intro b hb
    funext α
    induction α using WellFoundedLT.induction with
    | _ α ih =>
      rw [hb α, Ordinal.lt_wf.fix_eq (fun α f => rule α f) α]
      congr 1
      funext β hβ
      exact ih β hβ

/-- The card's worked claim (Step 2): a sequence with a(0) = 0, a(α + 1) = (1 + a(α)) ÷ 2, and
at every limit l the least upper bound of every earlier value, is at most 1 at every ordinal. -/
theorem halving_sequence_le_one (a : Ordinal → ℝ)
    (h0 : a 0 = 0)
    (hsucc : ∀ α, a (α + 1) = (1 + a α) / 2)
    (hlim : ∀ l, IsSuccLimit l → a l = sSup (a '' Set.Iio l)) :
    ∀ α, a α ≤ 1 := by
  refine transfinite_induction ?_ ?_ ?_
  · rw [h0]; norm_num
  · intro α hα
    rw [hsucc α]; linarith
  · intro l hl ih
    rw [hlim l hl]
    refine Real.sSup_le ?_ zero_le_one
    rintro _ ⟨β, hβ, rfl⟩
    exact ih β hβ

-- Worked numbers: a(1) = 1/2, a(2) = 3/4, a(3) = 7/8, each one halving of the gap to 1.
example : ((1 + 0) / 2 : ℚ) = 1 / 2 ∧ ((1 + 1 / 2) / 2 : ℚ) = 3 / 4 ∧
    ((1 + 3 / 4) / 2 : ℚ) = 7 / 8 := by norm_num

-- The closed form: (2 - 1/2^n) ÷ 2 = 1 - 1/2^(n+1), checked for n = 0 to 10.
example : ∀ n < 11,
    ((1 + (1 - 1 / 2 ^ n)) / 2 : ℚ) = 1 - 1 / 2 ^ (n + 1) := by
  intro n hn; interval_cases n <;> norm_num

-- a(10) = 1 - 1/2^10 = 1023/1024, the first value above 999/1000; a(9) = 1 - 1/2^9 is not.
example : (1 - 1 / 2 ^ 10 : ℚ) = 1023 / 1024 ∧ (999 / 1000 : ℚ) < 1023 / 1024 ∧
    (1 - 1 / 2 ^ 9 : ℚ) ≤ 999 / 1000 := by norm_num

-- After ω the halving keeps 1 fixed: a(ω + 1) = (1 + 1) ÷ 2 = 1.
example : ((1 + 1) / 2 : ℚ) = 1 := by norm_num

-- The mistakes: the biggest of the first ten values is 511/512, their sum is 4097/512 (above 1),
-- and dropping the halving, a(α + 1) = 1 + a(α), gives a(3) = 3.
example : (1 - 1 / 2 ^ 9 : ℚ) = 511 / 512 ∧
    (∑ n ∈ Finset.range 10, (1 - 1 / 2 ^ n : ℚ)) = 4097 / 512 ∧
    Nat.iterate (fun x => 1 + x) 3 0 = 3 := by
  norm_num [Finset.sum_range_succ]

#print axioms transfinite_induction
#print axioms recursion_theorem
#print axioms halving_sequence_le_one
