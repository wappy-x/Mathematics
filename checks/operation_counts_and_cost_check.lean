-- Counting the work: the flop counts for elimination, a determinant by elimination and Cramer's rule are exact polynomials in n, and the cofactor count divided by n factorial tends to e.
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Analysis.SpecialFunctions.Exponential
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Topology.Algebra.Order.Floor

open Finset Filter Topology

/-! A flop is one add, subtract, multiply or divide on two numbers. Each count below is the
card's nested loop written as a sum of the flops in its body, for a dense n by n matrix.

* Clearing column `k` (for `k = 1, …, n`) leaves `m = n - k` rows below the pivot. Each of
  those rows costs 1 division for its multiplier, a multiply and a subtract for each of the
  `m` entries to its right, and one more pair for the right side: `m * (1 + 2 * m + 2)` flops.
* Back substitution: row `i` needs `n - i` multiply-subtract pairs and one division.
* A determinant by elimination drops the right side and back substitution and multiplies the
  `n` diagonal entries instead: `n - 1` flops.
* Cramer's rule with such determinants: `n + 1` determinants and `n` divisions.
* A cofactor determinant of size `n` costs `n` determinants of size `n - 1`, then `n`
  multiplies and `n - 1` adds or subtracts, with `C(1) = 0`. -/

/-- Flops to solve `n` equations by elimination and back substitution. -/
def elimFlops (n : ℕ) : ℕ :=
  (∑ k ∈ Icc 1 n, (n - k) * (1 + 2 * (n - k) + 2)) + ∑ i ∈ Icc 1 n, (2 * (n - i) + 1)

/-- Flops for one determinant of size `n` by elimination: `D(n)`. -/
def detElimFlops (n : ℕ) : ℕ :=
  (∑ k ∈ Icc 1 n, (n - k) * (1 + 2 * (n - k))) + (n - 1)

/-- Flops for Cramer's rule with each determinant by elimination: `K(n) = (n + 1) D(n) + n`. -/
def cramerElimFlops (n : ℕ) : ℕ := (n + 1) * detElimFlops n + n

/-- Flops for one determinant of size `n` by cofactor expansion along the top row:
`C(1) = 0` and `C(n) = n C(n - 1) + 2n - 1` (`C 0` is set to 0 and is not used). -/
def cofactorFlops : ℕ → ℕ
  | 0 => 0
  | 1 => 0
  | n + 2 => (n + 2) * cofactorFlops (n + 1) + (2 * (n + 2) - 1)

theorem sum_Icc_sub_eq_sum_range {M : Type*} [AddCommMonoid M] (g : ℕ → M) (n : ℕ) :
    ∑ k ∈ Icc 1 n, g (n - k) = ∑ m ∈ range n, g m := by
  refine Finset.sum_nbij' (fun k => n - k) (fun m => n - m) ?_ ?_ ?_ ?_ ?_
  · intro k hk; simp only [mem_Icc, mem_range] at hk ⊢; omega
  · intro m hm; simp only [mem_Icc, mem_range] at hm ⊢; omega
  · intro k hk; simp only [mem_Icc] at hk; omega
  · intro m hm; simp only [mem_range] at hm; omega
  · intro k _; rfl

theorem sum_range_elim_rows (n : ℕ) :
    ((∑ m ∈ range n, m * (1 + 2 * m + 2) : ℕ) : ℚ) = 2 / 3 * n ^ 3 + 1 / 2 * n ^ 2 - 7 / 6 * n := by
  induction n with
  | zero => simp
  | succ n ih => rw [sum_range_succ, Nat.cast_add, ih]; push_cast; ring

theorem sum_range_back_sub (n : ℕ) :
    ((∑ m ∈ range n, (2 * m + 1) : ℕ) : ℚ) = (n : ℚ) ^ 2 := by
  induction n with
  | zero => simp
  | succ n ih => rw [sum_range_succ, Nat.cast_add, ih]; push_cast; ring

theorem sum_range_det_rows (n : ℕ) :
    ((∑ m ∈ range n, m * (1 + 2 * m) : ℕ) : ℚ) = 2 / 3 * n ^ 3 - 1 / 2 * n ^ 2 - 1 / 6 * n := by
  induction n with
  | zero => simp
  | succ n ih => rw [sum_range_succ, Nat.cast_add, ih]; push_cast; ring

theorem cofactorFlops_succ (n : ℕ) (hn : 1 ≤ n) :
    cofactorFlops (n + 1) = (n + 1) * cofactorFlops n + (2 * (n + 1) - 1) := by
  obtain ⟨k, rfl⟩ : ∃ k, n = k + 1 := ⟨n - 1, by omega⟩
  rfl

theorem cofactorFlops_eq (n : ℕ) (hn : 1 ≤ n) :
    (cofactorFlops n : ℝ) =
      (n.factorial : ℝ) * ∑ j ∈ range n, 1 / (j.factorial : ℝ) - 1 := by
  induction n, hn using Nat.le_induction with
  | base => simp [cofactorFlops]
  | succ n hn ih =>
    rw [cofactorFlops_succ n hn, sum_range_succ, Nat.factorial_succ]
    have h2 : (((2 * (n + 1) - 1 : ℕ)) : ℝ) = 2 * n + 1 := by
      rw [Nat.cast_sub (by omega)]; push_cast; ring
    have hf : (n.factorial : ℝ) ≠ 0 := by positivity
    rw [Nat.cast_add, Nat.cast_mul, h2, ih]
    push_cast
    field_simp
    ring

theorem sum_range_inv_factorial_le_exp_one (n : ℕ) :
    ∑ j ∈ range n, 1 / (j.factorial : ℝ) ≤ Real.exp 1 := by
  have := Real.sum_le_exp_of_nonneg (x := 1) zero_le_one n
  simpa using this

theorem tendsto_sum_range_inv_factorial :
    Tendsto (fun n : ℕ => ∑ j ∈ range n, 1 / (j.factorial : ℝ)) atTop (𝓝 (Real.exp 1)) := by
  have h := NormedSpace.expSeries_div_hasSum_exp (1 : ℝ)
  rw [← Real.exp_eq_exp_ℝ] at h
  simpa using h.tendsto_sum_nat

#print axioms sum_Icc_sub_eq_sum_range
#print axioms sum_range_elim_rows
#print axioms sum_range_back_sub
#print axioms sum_range_det_rows
#print axioms cofactorFlops_succ
#print axioms cofactorFlops_eq
#print axioms sum_range_inv_factorial_le_exp_one
#print axioms tendsto_sum_range_inv_factorial

/-- Elimination costs exactly `E(n) = 2/3 n^3 + 3/2 n^2 - 7/6 n` flops, for every `n`:
the multipliers, the row updates, the right side and back substitution add to this. -/
theorem elimination_flop_count (n : ℕ) :
    (elimFlops n : ℚ) = 2 / 3 * n ^ 3 + 3 / 2 * n ^ 2 - 7 / 6 * n := by
  unfold elimFlops
  rw [sum_Icc_sub_eq_sum_range (fun m => m * (1 + 2 * m + 2)) n,
    sum_Icc_sub_eq_sum_range (fun m => 2 * m + 1) n, Nat.cast_add, sum_range_elim_rows,
    sum_range_back_sub]
  ring

/-- One determinant by elimination costs exactly `D(n) = 2/3 n^3 - 1/2 n^2 + 5/6 n - 1`
flops, and Cramer's rule with such determinants costs `K(n) = (n + 1) D(n) + n`,
for every size `n ≥ 1`. -/
theorem cramer_by_elimination_flop_count (n : ℕ) (hn : 1 ≤ n) :
    (detElimFlops n : ℚ) = 2 / 3 * n ^ 3 - 1 / 2 * n ^ 2 + 5 / 6 * n - 1 ∧
    (cramerElimFlops n : ℚ) =
      (n + 1) * (2 / 3 * n ^ 3 - 1 / 2 * n ^ 2 + 5 / 6 * n - 1) + n := by
  have hD : (detElimFlops n : ℚ) = 2 / 3 * n ^ 3 - 1 / 2 * n ^ 2 + 5 / 6 * n - 1 := by
    unfold detElimFlops
    rw [sum_Icc_sub_eq_sum_range (fun m => m * (1 + 2 * m)) n, Nat.cast_add,
      sum_range_det_rows, Nat.cast_sub hn]
    push_cast
    ring
  refine ⟨hD, ?_⟩
  unfold cramerElimFlops
  push_cast
  rw [hD]

/-- A cofactor determinant of size `n` costs about `e` times `n!` flops: `C(n) / n!` tends to
`e` as `n → ∞`, and `C(n) < e · n!` for every `n`. -/
theorem cofactor_flops_div_factorial_tendsto_e :
    Tendsto (fun n : ℕ => (cofactorFlops n : ℝ) / (n.factorial : ℝ)) atTop
      (𝓝 (Real.exp 1)) ∧
    ∀ n : ℕ, (cofactorFlops n : ℝ) < Real.exp 1 * (n.factorial : ℝ) := by
  refine ⟨?_, ?_⟩
  · have hlim : Tendsto (fun n : ℕ => ∑ j ∈ range n, 1 / (j.factorial : ℝ) -
        1 / (n.factorial : ℝ)) atTop (𝓝 (Real.exp 1)) := by
      have h0 := FloorSemiring.tendsto_pow_div_factorial_atTop (1 : ℝ)
      simp only [one_pow] at h0
      simpa using tendsto_sum_range_inv_factorial.sub h0
    refine hlim.congr' ?_
    filter_upwards [eventually_ge_atTop 1] with n hn
    have hf : (n.factorial : ℝ) ≠ 0 := by positivity
    rw [cofactorFlops_eq n hn]
    field_simp
  · intro n
    rcases Nat.eq_zero_or_pos n with rfl | hn
    · simp [cofactorFlops, Real.exp_pos]
    · rw [cofactorFlops_eq n hn]
      have hS := sum_range_inv_factorial_le_exp_one n
      have hf : (0 : ℝ) < n.factorial := by positivity
      nlinarith

/-! The card's whole-number worked examples. -/

-- Elimination at n = 20: 190 + 4,940 + 380 + 400 = 5,910 flops.
example : elimFlops 20 = 5910 := by decide
example : 20 * 19 / 2 + 19 * 20 * 39 / 3 + 20 * 19 + 20 ^ 2 = 5910 := by norm_num
-- One determinant by elimination at n = 20: 190 + 4,940 + 19 = 5,149 flops.
example : detElimFlops 20 = 5149 := by decide
-- Cramer's rule with determinants by elimination at n = 20: 21 × 5,149 + 20 = 108,149.
example : cramerElimFlops 20 = 108149 := by decide
-- Cofactor counts for n = 1 to 8: 0 3 14 63 324 1955 13698 109599.
example : (List.range 8).map (fun k => cofactorFlops (k + 1)) =
    [0, 3, 14, 63, 324, 1955, 13698, 109599] := by decide
-- C(20) = 6,613,313,319,248,079,999.
example : cofactorFlops 20 = 6613313319248079999 := by decide
-- Cramer's rule by cofactors at n = 20: 21 × C(20) + 20 = 138,879,579,704,209,679,999 flops.
example : 21 * cofactorFlops 20 + 20 = 138879579704209679999 := by decide
-- Counting only multiplies and divides at n = 20 gives 3,060.
example : 20 * 19 / 2 + 19 * 20 * 39 / 6 + 20 * 19 / 2 + 20 * 21 / 2 = 3060 := by norm_num
-- Matrix times matrix, n = 48: 2n^3 = 221,184 flops; plain-loop model n^3 + 2n^2 = 115,200
-- fetches; tiled model with t = 16, 2n^3/t + n^2 = 16,128 fetches.
example : 2 * 48 ^ 3 = 221184 ∧ 48 ^ 3 + 2 * 48 ^ 2 = 115200 ∧
    2 * 48 ^ 3 / 16 + 48 ^ 2 = 16128 := by norm_num
-- Intensity at n = 20: matrix times vector 780 flops on 440 numbers; matrix times matrix
-- n^2(2n - 1) = 15,600 flops on 3n^2 = 1,200 numbers.
example : 20 * (2 * 20 - 1) = 780 ∧ 20 ^ 2 + 2 * 20 = 440 ∧
    20 ^ 2 * (2 * 20 - 1) = 15600 ∧ 3 * 20 ^ 2 = 1200 := by norm_num

#print axioms elimination_flop_count
#print axioms cramer_by_elimination_flop_count
#print axioms cofactor_flops_div_factorial_tendsto_e
