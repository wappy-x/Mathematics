-- A recurrence is a matrix: for a whole-number rule a(n+2) = p a(n+1) + q a(n) with fixed coefficients and nothing added, the n-th power of the companion matrix [[p, q], [1, 0]] moves the stack of two terms n steps at once, the n-th power of [[1, 1], [1, 0]] holds the tiling counts T(n), T(n-1), T(n-2), its eigenvalues are exactly the solutions of λ² − λ − 1 = 0, and the card's worked numbers come out as it says.
import Mathlib.Data.Matrix.Basic
import Mathlib.Basic.Real.Basic
import Mathlib.Data.Nat.Digits.Defs
import Mathlib.Data.Nat.Fib.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Tactic.NormNum

open Matrix

/-! The 2 × 2 matrix with rows (a, b) and (c, d) is `!![a, b; c, d]`, and the stack with `x` on
top and `y` below is `![x, y]`. `A *ᵥ v` is the matrix applied to the stack, and `A ^ n` is `n`
copies of `A` multiplied as matrices. -/

/-- A recurrence is a matrix. Take a two-step rule with fixed whole-number coefficients `p` and
`q` and nothing added on the side: a(n+2) = p · a(n+1) + q · a(n) at every step. Stack two
neighbouring terms, newer on top. Then the companion matrix [[p, q], [1, 0]] (top row the
coefficients, bottom row sliding the old top down) raised to the `n`-th power carries the stack
at any place `k` straight to the stack `n` places further on. -/
theorem companion_matrix_power_moves_stack_n_steps (p q : ℤ) (a : ℕ → ℤ)
    (h : ∀ n, a (n + 2) = p * a (n + 1) + q * a n) (n k : ℕ) :
    (!![p, q; 1, 0] : Matrix (Fin 2) (Fin 2) ℤ) ^ n *ᵥ ![a (k + 1), a k] =
      ![a (n + k + 1), a (n + k)] := by
  induction n generalizing k with
  | zero => simp
  | succ n ih =>
    have hstep : (!![p, q; 1, 0] : Matrix (Fin 2) (Fin 2) ℤ) *ᵥ ![a (k + 1), a k] =
        ![a (k + 1 + 1), a (k + 1)] := by
      ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_two, h k]
    rw [pow_succ, ← mulVec_mulVec, hstep, ih (k + 1)]
    have e1 : n + (k + 1) + 1 = n + 1 + k + 1 := by omega
    have e2 : n + (k + 1) = n + 1 + k := by omega
    rw [e1, e2]

/-- One power spells out three counts. Let T(n) count the tilings of a hallway 2 feet wide and
n feet long, so T(0) = 1, T(1) = 1 and T(n+2) = T(n+1) + T(n). Then for every n ≥ 2 the n-th
power of M = [[1, 1], [1, 0]] is [[T(n), T(n−1)], [T(n−1), T(n−2)]]. -/
theorem fibonacci_matrix_power_entries_are_tiling_counts (T : ℕ → ℕ)
    (h0 : T 0 = 1) (h1 : T 1 = 1) (h : ∀ n, T (n + 2) = T (n + 1) + T n)
    (n : ℕ) (hn : 2 ≤ n) :
    (!![1, 1; 1, 0] : Matrix (Fin 2) (Fin 2) ℕ) ^ n =
      !![T n, T (n - 1); T (n - 1), T (n - 2)] := by
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 2 := ⟨n - 2, by omega⟩
  simp only [Nat.add_sub_cancel, show m + 2 - 1 = m + 1 by omega]
  clear hn
  induction m with
  | zero =>
    have h2 : T 2 = 2 := by rw [h 0, h1, h0]
    rw [h2, h1, h0]
    ext i j; fin_cases i <;> fin_cases j <;> simp [sq, Matrix.mul_apply, Fin.sum_univ_two]
  | succ m ih =>
    rw [show m + 1 + 2 = (m + 2) + 1 by omega, pow_succ, ih, h (m + 1), h m]
    ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two]

/-- The eigenvalues are the characteristic roots. A real number r is an eigenvalue of
M = [[1, 1], [1, 0]], a stretch along some nonzero direction M does not turn, exactly when
r² − r − 1 = 0, the rule's own characteristic equation. -/
theorem eigenvalues_solve_characteristic_eq (r : ℝ) :
    (∃ v : Fin 2 → ℝ, v ≠ 0 ∧ (!![1, 1; 1, 0] : Matrix (Fin 2) (Fin 2) ℝ) *ᵥ v = r • v) ↔
      r ^ 2 - r - 1 = 0 := by
  constructor
  · rintro ⟨v, hv, hM⟩
    have e0 := congrFun hM 0
    have e1 := congrFun hM 1
    simp [mulVec, dotProduct, Fin.sum_univ_two] at e0 e1
    have hv1 : v 1 ≠ 0 := by
      intro h1
      apply hv
      ext i; fin_cases i
      · simp; rw [e1, h1]; simp
      · simpa using h1
    have : (r ^ 2 - r - 1) * v 1 = 0 := by
      have : r * (r * v 1) = r * v 1 + v 1 := by rw [← e1]; linarith
      linarith [this]
    rcases mul_eq_zero.mp this with h | h
    · exact h
    · exact absurd h hv1
  · intro hr
    refine ⟨![r, 1], ?_, ?_⟩
    · intro h0
      have := congrFun h0 1
      simp at this
    · ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_two]; nlinarith [hr]

-- The picture: one multiply by M takes (55, 34) to (89, 55), and the next to (144, 89).
example : (!![1, 1; 1, 0] : Matrix (Fin 2) (Fin 2) ℕ) *ᵥ ![55, 34] = ![89, 55] ∧
    (!![1, 1; 1, 0] : Matrix (Fin 2) (Fin 2) ℕ) *ᵥ ![89, 55] = ![144, 89] := by
  decide
-- The ladder by squaring: M², M⁴, M⁸ are [[2, 1], [1, 1]], [[5, 3], [3, 2]], [[34, 21], [21, 13]].
example : (!![1, 1; 1, 0] : Matrix (Fin 2) (Fin 2) ℕ) * !![1, 1; 1, 0] = !![2, 1; 1, 1] ∧
    (!![2, 1; 1, 1] : Matrix (Fin 2) (Fin 2) ℕ) * !![2, 1; 1, 1] = !![5, 3; 3, 2] ∧
    (!![5, 3; 3, 2] : Matrix (Fin 2) (Fin 2) ℕ) * !![5, 3; 3, 2] = !![34, 21; 21, 13] := by
  decide
-- Finish the exponent: M⁸ times M² is [[89, 55], [55, 34]], and that is M¹⁰.
example : (!![34, 21; 21, 13] : Matrix (Fin 2) (Fin 2) ℕ) * !![2, 1; 1, 1] = !![89, 55; 55, 34] ∧
    (!![1, 1; 1, 0] : Matrix (Fin 2) (Fin 2) ℕ) ^ 10 = !![89, 55; 55, 34] := by
  decide
-- Stepping the rule from 1, 1 one foot at a time: T(0) to T(10), ending at 89 after 9 additions.
example : (List.range 11).map (fun n => Nat.fib (n + 1)) = [1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89] := by
  decide
-- What it cost: ones in binary plus binary length minus 2 is 4 multiplications for 10 and
-- 25 for a million.
example : (Nat.digits 2 10).sum + (Nat.digits 2 10).length - 2 = 4 ∧
    (Nat.digits 2 1000000).sum + (Nat.digits 2 1000000).length - 2 = 25 := by
  norm_num
-- Trace 1 and determinant −1.
example : trace (!![1, 1; 1, 0] : Matrix (Fin 2) (Fin 2) ℤ) = 1 ∧
    det (!![1, 1; 1, 0] : Matrix (Fin 2) (Fin 2) ℤ) = -1 := by
  rw [trace_fin_two_of, det_fin_two_of]; norm_num
-- Cassini at ten feet: 89 × 34 − 55 × 55 = 1, and (−1) ten times over is 1.
example : (89 : ℤ) * 34 - 55 * 55 = 1 ∧ (-1 : ℤ) ^ 10 = 1 := by
  norm_num
-- Mistake 1: the matrix written [[1, 1], [0, 1]] gives [[1, 10], [0, 1]], top-left 1.
example : (!![1, 1; 0, 1] : Matrix (Fin 2) (Fin 2) ℕ) ^ 10 = !![1, 10; 0, 1] := by
  decide
-- Mistake 2: each entry raised to the tenth on its own gives [[1, 1], [1, 0]] straight back.
example : (!![1, 1; 1, 0] : Matrix (Fin 2) (Fin 2) ℕ).map (· ^ 10) = !![1, 1; 1, 0] := by
  decide
-- Mistake 3: the stack (1, 1) carried through M¹⁰ reports 144, the eleven-foot count.
example : (!![1, 1; 1, 0] : Matrix (Fin 2) (Fin 2) ℕ) ^ 10 *ᵥ ![1, 1] = ![144, 89] := by
  decide

#print axioms companion_matrix_power_moves_stack_n_steps
#print axioms fibonacci_matrix_power_entries_are_tiling_counts
#print axioms eigenvalues_solve_characteristic_eq
