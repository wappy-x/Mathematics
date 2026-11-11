-- Finite differences: a sum of the jumps a(k+1) − a(k) for k from 1 to n collapses to a(n+1) − a(1), which gives 1 + 2 + ⋯ + n = n(n+1)/2 and 1/(1·2) + ⋯ + 1/(n(n+1)) = 1 − 1/(n+1).
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Data.Nat.Fib.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Abel
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring

open Finset

/-- Telescoping. For any list a(1), a(2), a(3), … of quantities that can be added and
subtracted (whole numbers, fractions, any additive group), with every term present, adding the
jumps Δa(k) = a(k+1) − a(k) for k from 1 to n leaves only the term one past the end minus the
first: Δa(1) + Δa(2) + ⋯ + Δa(n) = a(n+1) − a(1). -/
theorem sum_of_differences_telescopes {G : Type*} [AddCommGroup G] (a : ℕ → G) (n : ℕ) :
    ∑ k ∈ Icc 1 n, (a (k + 1) - a k) = a (n + 1) - a 1 := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_Icc_succ_top (by omega), ih]
    abel

/-- The tins. For every n, the whole numbers 1 + 2 + 3 + ⋯ + n add to n(n+1)/2. -/
theorem sum_one_to_n_eq_half_n_mul_succ (n : ℕ) :
    ∑ k ∈ Icc 1 n, k = n * (n + 1) / 2 := by
  have h : ∀ m : ℕ, (∑ k ∈ Icc 1 m, k) * 2 = m * (m + 1) := by
    intro m
    induction m with
    | zero => simp
    | succ m ih =>
      rw [Finset.sum_Icc_succ_top (by omega), add_mul, ih]
      ring
  have := h n
  omega

/-- The fractions. For every n, since 1/(k(k+1)) = 1/k − 1/(k+1), the sum
1/(1·2) + 1/(2·3) + ⋯ + 1/(n(n+1)) collapses to exactly 1 − 1/(n+1). -/
theorem sum_one_div_k_mul_succ_telescopes (n : ℕ) :
    ∑ k ∈ Icc 1 n, (1 : ℚ) / ((k : ℚ) * ((k : ℚ) + 1)) = 1 - 1 / ((n : ℚ) + 1) := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_Icc_succ_top (by omega), ih]
    push_cast
    field_simp
    ring

-- The display row by row: running totals 1, 3, 6, 10, 15.
example : (List.range 5).map (fun i => ∑ k ∈ Icc 1 (i + 1), k) = [1, 3, 6, 10, 15] := by decide
-- First differences 2, 3, 4, 5, and second differences 1, 1, 1.
example : (List.range 4).map (fun i => (∑ k ∈ Icc 1 (i + 2), k) - ∑ k ∈ Icc 1 (i + 1), k) =
    [2, 3, 4, 5] := by decide
example : [3 - 2, 4 - 3, 5 - 4] = [1, 1, 1] := by decide
-- Newton's formula from the edge 1, 2, 1 at five rows: 1 + 2·C(4,1) + C(4,2) = 1 + 8 + 6 = 15.
example : 1 + 2 * Nat.choose 4 1 + Nat.choose 4 2 = 15 ∧ 2 * Nat.choose 4 1 = 8 ∧
    Nat.choose 4 2 = 6 := by decide
-- Newton's formula gives the same totals for rows 1 to 10.
example : (List.range 10).map (fun i => 1 + 2 * Nat.choose i 1 + Nat.choose i 2) =
    [1, 3, 6, 10, 15, 21, 28, 36, 45, 55] := by decide
-- Ten rows: 1 + 2 + ⋯ + 10 = 55 = 10 × 11 / 2.
example : ∑ k ∈ Icc 1 10, k = 55 ∧ 10 * 11 / 2 = 55 := by decide
-- The jumps 2 + 3 + ⋯ + 10 add to 54 = 55 − 1.
example : ∑ k ∈ Icc 2 10, k = 54 ∧ 55 - 1 = 54 := by decide
-- The fractions to k = 99, added exactly: 99/100.
example : ∑ k ∈ Icc (1 : ℕ) 99, (1 : ℚ) / ((k : ℚ) * ((k : ℚ) + 1)) = 99 / 100 := by
  decide +kernel
-- The hallway: F(11) = 89, and F(1) + ⋯ + F(9) = 88 = 89 − 1.
example : Nat.fib 11 = 89 ∧ ∑ k ∈ Icc 1 9, Nat.fib k = 88 ∧ 89 - 1 = 88 := by decide
-- The mistakes: n² gives 25 at five rows, not 15; stopping early gives 45, not 55.
example : 5 ^ 2 = 25 ∧ ∑ k ∈ Icc 1 9, k = 45 := by decide

#print axioms sum_of_differences_telescopes
#print axioms sum_one_to_n_eq_half_n_mul_succ
#print axioms sum_one_div_k_mul_succ_telescopes
