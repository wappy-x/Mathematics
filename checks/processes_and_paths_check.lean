-- Stochastic processes: the law of a process (its chances over whole paths) is a probability that fixes every one-time and finite-list table, those one-time tables do not fix the law, and the card's gambler numbers check out.
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.MeasureTheory.MeasurableSpace.Constructions
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Tactic.NormNum
import Mathlib.MeasureTheory.Measure.Dirac.Basic

namespace ProcessesAndPaths

open MeasureTheory

/-- **The law fixes every one-time table, and every table for a finite list of times.**
Take any family of random variables `X i`, one for each time `i`, on one shared set of outcomes
`Ω` with chances `P`. Its law is the chance over whole paths: `P_X(A)` is the chance of the
outcomes whose path `i ↦ X i ω` lands in the set of paths `A`. Then for every finite list of
times `J` and every choice of value sets `s j`, the chance that `X j` lands in `s j` for every
`j` in `J` equals the law of the set of paths whose entry at each `j` in `J` lies in `s j`.
With `J` a single time `n` and `s n = {x}`, this is `P(X_n = x) = P_X(paths with entry x at n)`. -/
theorem law_fixes_finite_dim_tables {ι Ω E : Type*} [MeasurableSpace Ω] [MeasurableSpace E]
    (P : Measure Ω) [IsProbabilityMeasure P] (X : ι → Ω → E) (hX : ∀ i, Measurable (X i))
    (J : Finset ι) (s : ι → Set E) (hs : ∀ j ∈ J, MeasurableSet (s j)) :
    P {ω | ∀ j ∈ J, X j ω ∈ s j} =
      (P.map (fun ω i => X i ω)) {f : ι → E | ∀ j ∈ J, f j ∈ s j} := by
  have hm : Measurable (fun ω i => X i ω) := Measurable.of_eval hX
  have hA : MeasurableSet {f : ι → E | ∀ j ∈ J, f j ∈ s j} :=
    MeasurableSet.pi J.countable_toSet hs
  rw [Measure.map_apply hm hA]
  rfl

/-- **The law is a genuine probability table on paths.** For any family of random variables on
one shared set of outcomes, the law (chances over whole paths) has total 1. -/
theorem law_is_probability {ι Ω E : Type*} [MeasurableSpace Ω] [MeasurableSpace E]
    (P : Measure Ω) [IsProbabilityMeasure P] (X : ι → Ω → E) (hX : ∀ i, Measurable (X i)) :
    IsProbabilityMeasure (P.map (fun ω i => X i ω)) := by
  exact (Measure.isProbabilityMeasure_map_iff (Measurable.of_eval hX).aemeasurable).2
    inferInstance

/-- **The one-time tables do not fix the law.** There are two processes in whole-number states
over the rounds `0, 1, 2, …`, on one shared set of outcomes with chances `P`, whose one-time
tables agree at every round but whose laws over whole paths differ. -/
theorem one_time_tables_do_not_fix_law :
    ∃ (Ω : Type) (_ : MeasurableSpace Ω) (P : Measure Ω) (X Y : ℕ → Ω → ℤ),
      IsProbabilityMeasure P ∧ (∀ n, Measurable (X n)) ∧ (∀ n, Measurable (Y n)) ∧
      (∀ n, P.map (X n) = P.map (Y n)) ∧
      P.map (fun ω n => X n ω) ≠ P.map (fun ω n => Y n ω) := by
  let P : Measure Bool := (2⁻¹ : ENNReal) • (Measure.dirac true + Measure.dirac false)
  let X : ℕ → Bool → ℤ := fun _ b => if b then 1 else 0
  let Y : ℕ → Bool → ℤ := fun n b => if n = 0 then (if b then 1 else 0) else (if b then 0 else 1)
  have hX : ∀ n, Measurable (X n) := fun n => measurable_of_countable _
  have hY : ∀ n, Measurable (Y n) := fun n => measurable_of_countable _
  refine ⟨Bool, inferInstance, P, X, Y, ?_, hX, hY, ?_, ?_⟩
  · constructor
    simp [P, ENNReal.inv_two_add_inv_two]
  · intro n
    rw [Measure.map_smul, Measure.map_smul, Measure.map_add _ _ (hX n),
      Measure.map_add _ _ (hY n), Measure.map_dirac' (hX n), Measure.map_dirac' (hX n),
      Measure.map_dirac' (hY n), Measure.map_dirac' (hY n)]
    rcases Nat.eq_zero_or_pos n with h | h
    · subst h; simp [X, Y]
    · simp [X, Y, h.ne', add_comm]
    all_goals first | exact (hX n).aemeasurable | exact (hY n).aemeasurable
  · intro heq
    have hmX : Measurable (fun ω n => X n ω) := Measurable.of_eval hX
    have hmY : Measurable (fun ω n => Y n ω) := Measurable.of_eval hY
    have hA : MeasurableSet {f : ℕ → ℤ | f 0 = f 1} :=
      measurableSet_eq_fun (measurable_pi_apply 0) (measurable_pi_apply 1)
    have := congrArg (fun μ => μ {f : ℕ → ℤ | f 0 = f 1}) heq
    simp only [Measure.map_apply hmX hA, Measure.map_apply hmY hA] at this
    simp [P, X, Y, Measure.smul_apply, Measure.add_apply, Set.preimage] at this

/-! The card's gambler: 10 chips, one chip won or lost each round, play stops at 0 chips. -/

/-- The house rule: add one chip on a win, take one away on a loss, stay at 0 once ruined. -/
def step (x : ℕ) (won : Bool) : ℕ := if x = 0 then 0 else if won then x + 1 else x - 1

/-- `chips ω n` is the chip count after round `n`; `ω k` is `true` when round `k + 1` is won. -/
def chips (ω : ℕ → Bool) : ℕ → ℕ
  | 0 => 10
  | n + 1 => step (chips ω n) (ω n)

/-- An outcome as a whole number, as in the card's code: bit `k` is 1 when round `k + 1` is won. -/
def bits (ω : ℕ) : ℕ → Bool := fun k => ω.testBit k

/-- Evening 1: W L L L W L L L L W W W W L W L L L W L. -/
def evening1 : ℕ → Bool := fun k =>
  [true, false, false, false, true, false, false, false, false, true,
   true, true, true, false, true, false, false, false, true, false].getD k false

-- 2^20 = 1,048,576 outcomes.
example : 2 ^ 20 = 1048576 := by norm_num
-- Evening 1's sample path: 10, 11, 10, 9, 8, 9, 8, 7, 6, 5, 6, 7, 8, 9, 8, 9, 8, 7, 6, 7, 6.
example : (List.range 21).map (chips evening1) =
    [10, 11, 10, 9, 8, 9, 8, 7, 6, 5, 6, 7, 8, 9, 8, 9, 8, 7, 6, 7, 6] := by decide
-- X_7 on evening 1 is 7 = 10 + 2 - 5.
example : chips evening1 7 = 10 + 2 - 5 := by decide
-- Of the 2^7 = 128 patterns of 7 results, 21 = 7 * 6 / 2 end on 7 chips: P(X_7 = 7) = 21/128.
example : ((Finset.range (2 ^ 7)).filter (fun ω => chips (bits ω) 7 = 7)).card = 21 := by decide
example : Nat.choose 7 2 = 7 * 6 / 2 ∧ Nat.choose 7 2 = 21 := by decide
-- Over all 2^20 records the same chance: 172,032 of 1,048,576 is 21/128.
example : (172032 : ℚ) / 1048576 = 21 / 128 := by norm_num
-- After 4 rounds: 1, 4, 6, 4, 1 of 16 patterns on 6, 8, 10, 12, 14 chips.
example : ((Finset.range 16).filter (fun ω => chips (bits ω) 4 = 6)).card = 1 ∧
    ((Finset.range 16).filter (fun ω => chips (bits ω) 4 = 8)).card = 4 ∧
    ((Finset.range 16).filter (fun ω => chips (bits ω) 4 = 10)).card = 6 ∧
    ((Finset.range 16).filter (fun ω => chips (bits ω) 4 = 12)).card = 4 ∧
    ((Finset.range 16).filter (fun ω => chips (bits ω) 4 = 14)).card = 1 := by decide
-- P(X_1 = 11 and X_2 = 12): only W W, one pattern of 4; the product of the one-time tables
-- (1/2 and 1/4) gives 1/8 instead.
example : ((Finset.range 4).filter
    (fun ω => chips (bits ω) 1 = 11 ∧ chips (bits ω) 2 = 12)).card = 1 := by decide
example : ((Finset.range 2).filter (fun ω => chips (bits ω) 1 = 11)).card = 1 ∧
    ((Finset.range 4).filter (fun ω => chips (bits ω) 2 = 12)).card = 1 := by decide
example : (1 : ℚ) / 2 * (1 / 4) = 1 / 8 ∧ (1 : ℚ) / 8 ≠ 1 / 4 := by norm_num
-- P(X_20 = 10) = 184,755 of 1,048,576: the C(20,10) records with ten wins, less the one
-- (ten losses, then ten wins) that is ruined at round 10 and stays at 0.
example : Nat.choose 20 10 - Nat.choose 20 0 = 184755 := by decide
example : chips (fun k => decide (10 ≤ k)) 10 = 0 ∧ chips (fun k => decide (10 ≤ k)) 20 = 0 := by
  decide
-- Ruin by round 20 by the reflection count: 27,896 = C(20,5) + 2 (C(20,0) + ... + C(20,4)).
example : Nat.choose 20 5 + 2 * ∑ k ∈ Finset.range 5, Nat.choose 20 k = 27896 := by decide

#print axioms law_fixes_finite_dim_tables
#print axioms law_is_probability
#print axioms one_time_tables_do_not_fix_law

end ProcessesAndPaths
