-- The Stratonovich integral: on every grid, the midpoint sum equals the start-point (Ito) sum plus half the sum of products of matching moves, and for W against itself it telescopes to half the change of W squared.
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Finset

/-- The conversion, exact on every grid: for any values `X k`, `Y k` of two processes at the grid
times `t_0 < t_1 < ... < t_n`, the Stratonovich (average-of-ends) sum
`∑ ½ (X_k + X_{k+1}) ΔY_k` equals the Ito (start-point) sum `∑ X_k ΔY_k` plus half the sum of
products of matching moves `½ ∑ ΔX_k ΔY_k`, whose limit is half the covariation. -/
theorem stratonovich_sum_eq_ito_sum_add_half_covariation (X Y : ℕ → ℝ) (n : ℕ) :
    ∑ k ∈ range n, (X k + X (k + 1)) / 2 * (Y (k + 1) - Y k) =
      ∑ k ∈ range n, X k * (Y (k + 1) - Y k) +
        (1 / 2) * ∑ k ∈ range n, (X (k + 1) - X k) * (Y (k + 1) - Y k) := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_range_succ, Finset.sum_range_succ, Finset.sum_range_succ, ih]; ring

/-- Step 1, first identity: the Stratonovich sum of `W` against itself telescopes, so on every grid
`∑ ½ (W_k + W_{k+1}) D_k = ½ (W_n² - W_0²)`, with no limit needed. -/
theorem stratonovich_sum_self_eq_half_sq_change (W : ℕ → ℝ) (n : ℕ) :
    ∑ k ∈ range n, (W k + W (k + 1)) / 2 * (W (k + 1) - W k) = (W n ^ 2 - W 0 ^ 2) / 2 := by
  induction n with
  | zero => simp
  | succ n ih => rw [Finset.sum_range_succ, ih]; ring

/-- Step 1, second identity: the Ito sum of `W` against itself is half the change of `W²` minus
half the sum of squared moves: `∑ W_k D_k = ½ (W_n² - W_0²) - ½ ∑ D_k²`. -/
theorem ito_sum_self_eq_half_sq_change_sub_half_sq_moves (W : ℕ → ℝ) (n : ℕ) :
    ∑ k ∈ range n, W k * (W (k + 1) - W k) =
      (W n ^ 2 - W 0 ^ 2) / 2 - (1 / 2) * ∑ k ∈ range n, (W (k + 1) - W k) ^ 2 := by
  induction n with
  | zero => simp
  | succ n ih => rw [Finset.sum_range_succ, Finset.sum_range_succ, ih]; ring

/-- The hand path: `W` = 0, 0.8, 0.6, 1.0, 1.4 at the quarter-years, written as exact fractions. -/
def handPath : ℕ → ℚ
  | 0 => 0
  | 1 => 4 / 5
  | 2 => 3 / 5
  | 3 => 1
  | _ => 7 / 5

-- Ito sum: 0 × 0.8 + 0.8 × (−0.2) + 0.6 × 0.4 + 1.0 × 0.4 = 0.48
example : ∑ k ∈ range 4, handPath k * (handPath (k + 1) - handPath k) = 12 / 25 := by
  simp [sum_range_succ, handPath]; norm_num

-- Stratonovich sum: 0.4 × 0.8 + 0.7 × (−0.2) + 0.8 × 0.4 + 1.2 × 0.4 = 0.98 = 1.4² / 2
example : ∑ k ∈ range 4, (handPath k + handPath (k + 1)) / 2 * (handPath (k + 1) - handPath k)
    = 49 / 50 := by
  simp [sum_range_succ, handPath]; norm_num

-- Sum of squared moves: 0.64 + 0.04 + 0.16 + 0.16 = 1.00
example : ∑ k ∈ range 4, (handPath (k + 1) - handPath k) ^ 2 = 1 := by
  simp [sum_range_succ, handPath]; norm_num

-- Gap, Stratonovich minus Ito: 0.98 − 0.48 = 0.50, half the sum of squared moves
example : ∑ k ∈ range 4, (handPath k + handPath (k + 1)) / 2 * (handPath (k + 1) - handPath k)
    - ∑ k ∈ range 4, handPath k * (handPath (k + 1) - handPath k)
    = (1 / 2) * ∑ k ∈ range 4, (handPath (k + 1) - handPath k) ^ 2 := by
  simp [sum_range_succ, handPath]; norm_num

-- The end-point sum (whole move instead of half): 1.48
example : ∑ k ∈ range 4, handPath (k + 1) * (handPath (k + 1) - handPath k) = 37 / 25 := by
  simp [sum_range_succ, handPath]; norm_num

#print axioms stratonovich_sum_eq_ito_sum_add_half_covariation
#print axioms stratonovich_sum_self_eq_half_sq_change
#print axioms ito_sum_self_eq_half_sq_change_sub_half_sq_moves
