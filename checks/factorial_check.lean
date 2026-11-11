-- Factorials: the number of ways to line up n different things is n!, n! beats 2^n from n = 4 on, and n! eventually beats every fixed power n^k, with the card's playlist and race numbers checked.
import Mathlib.Data.Fintype.Perm
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Data.Nat.Digits.Lemmas
import Mathlib.Tactic.NormNum

open Nat

/-- The number of ways to put `n` different things in a line is `n!`.
A line has places `1, …, n` (here `Fin n`, a first place and a last), every thing is used once,
and order counts: an ordering is a one-to-one, onto assignment of the `n` things to the `n`
places. For any collection `α` of `n` different things, those orderings number `n!`. -/
theorem card_orderings_eq_factorial {α : Type*} [Fintype α] [DecidableEq α] (n : ℕ)
    (hα : Fintype.card α = n) :
    Fintype.card (Fin n ≃ α) = n ! := by
  rw [Fintype.card_equiv (Fintype.equivFinOfCardEq hα).symm, Fintype.card_fin]

/-- The factorial leaves doubling behind from four things on: for every `n ≥ 4`, `2^n < n!`,
and it never falls back. -/
theorem two_pow_lt_factorial (n : ℕ) (hn : 4 ≤ n) : 2 ^ n < n ! := by
  induction n, hn using Nat.le_induction with
  | base => decide
  | succ m hm ih =>
    rw [Nat.factorial_succ, Nat.pow_succ]
    have : 2 ≤ m + 1 := by omega
    calc 2 ^ m * 2 < m ! * 2 := Nat.mul_lt_mul_of_pos_right ih (by norm_num)
      _ = 2 * m ! := Nat.mul_comm _ _
      _ ≤ (m + 1) * m ! := Nat.mul_le_mul_right _ this

/-- The factorial outruns every fixed power: for each fixed exponent `k`, from some point on
`n^k < n!`. -/
theorem pow_lt_factorial_eventually (k : ℕ) : ∃ N : ℕ, ∀ n ≥ N, n ^ k < n ! := by
  refine ⟨k + k + 2 ^ k + 1, fun n hn => ?_⟩
  generalize hM : 2 ^ k = M at hn
  obtain ⟨j, rfl⟩ : ∃ j, n = j + k := ⟨n - k, by omega⟩
  have hj : k + M + 1 ≤ j := by omega
  have hjpos : 0 < j := by omega
  have h1 : (j + k) ^ k ≤ (2 * j) ^ k := Nat.pow_le_pow_left (by omega) k
  have h2 : (2 * j) ^ k < j ^ (k + 1) := by
    rw [Nat.mul_pow, Nat.pow_succ, Nat.mul_comm (j ^ k) j, hM]
    exact Nat.mul_lt_mul_of_pos_right (by omega) (Nat.pow_pos hjpos)
  have h3 : j ^ (k + 1) ≤ (j + k).descFactorial (k + 1) := by
    have := Nat.pow_sub_le_descFactorial (j + k) (k + 1)
    rwa [show j + k + 1 - (k + 1) = j by omega] at this
  have h4 : (j + k).descFactorial (k + 1) ≤ (j + k) ! := by
    rw [← Nat.factorial_mul_descFactorial (show k + 1 ≤ j + k by omega)]
    exact Nat.le_mul_of_pos_left _ (Nat.factorial_pos _)
  omega

-- The ladder: 0! = 1, 1! = 1, 2! = 2, 3! = 6, 4! = 24, and each rung is the one below times n.
example : 0 ! = 1 ∧ 1 ! = 1 ∧ 2 ! = 2 ∧ 3 ! = 6 ∧ 4 ! = 24 := by decide
example : 8 ! = 8 * 5040 ∧ 10 ! = 10 * 362880 := by decide
-- The ten-song playlist, the eight runners, the twenty-song playlist.
example : 10 ! = 3628800 := by decide
example : 8 ! = 40320 := by decide
example : 20 ! = 2432902008176640000 := by norm_num [Nat.factorial]
-- The three songs A, B, C, lined up every way: six orderings.
example : Fintype.card (Fin 3 ≃ Fin 3) = 6 := by decide
-- The factorial starts behind doubling at three things and crosses at four.
example : 3 ! < 2 ^ 3 ∧ 2 ^ 4 < 4 ! := by decide
-- Digits at twenty things: n! needs 19, 2^n needs 7, n^2 needs 3.
example : (Nat.digits 10 (20 !)).length = 19 := by norm_num [Nat.factorial]
example : (Nat.digits 10 (2 ^ 20)).length = 7 := by norm_num
example : (Nat.digits 10 (20 ^ 2)).length = 3 := by norm_num
-- The mistakes: repeats allowed gives 10^10; one song on twice gives half of 10!.
example : 10 ^ 10 = 10000000000 := by norm_num
example : 10 ! / 2 = 1814400 := by decide

#print axioms card_orderings_eq_factorial
#print axioms two_pow_lt_factorial
#print axioms pow_lt_factorial_eventually
