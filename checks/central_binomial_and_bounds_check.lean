-- The middle of the row: the middle entry C(2n, n) of row 2n is its largest entry and lies between 4^n/(2n+1) and 4^n, neighbouring entries satisfy k C(n,k) = (n-k+1) C(n,k-1), and for 1 ≤ k ≤ n the count C(n,k) lies between (n/k)^k and n^k/k!.
import Mathlib.Data.Nat.Choose.Central
import Mathlib.Data.Nat.Choose.Bounds
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum

open Nat Finset

/-- Helper: `((n+1)/(k+1))^(k+1) ≤ C(n+1, k+1)` whenever `k ≤ n`. -/
theorem choose_lower_aux (k : ℕ) : ∀ n : ℕ, k ≤ n →
    (((n : ℝ) + 1) / ((k : ℝ) + 1)) ^ (k + 1) ≤ ((n + 1).choose (k + 1) : ℝ) := by
  induction k with
  | zero =>
    intro n _
    simp
  | succ k ih =>
    intro n hkn
    obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
    have hkm : k ≤ m := by omega
    have h1 := ih m hkm
    have hrec : ((m + 1 + 1).choose (k + 1 + 1) : ℝ) * ((k : ℝ) + 1 + 1)
        = ((m : ℝ) + 1 + 1) * ((m + 1).choose (k + 1) : ℝ) := by
      have := Nat.add_one_mul_choose_eq (m + 1) (k + 1)
      exact_mod_cast this.symm
    have hk0 : (0 : ℝ) < (k : ℝ) + 1 + 1 := by positivity
    have hk1 : (0 : ℝ) < (k : ℝ) + 1 := by positivity
    have hkmR : (k : ℝ) ≤ m := by exact_mod_cast hkm
    have hratio : ((m : ℝ) + 1 + 1) / ((k : ℝ) + 1 + 1) ≤ ((m : ℝ) + 1) / ((k : ℝ) + 1) := by
      rw [div_le_div_iff₀ hk0 hk1]
      nlinarith
    have hpow : (((m : ℝ) + 1 + 1) / ((k : ℝ) + 1 + 1)) ^ (k + 1)
        ≤ (((m : ℝ) + 1) / ((k : ℝ) + 1)) ^ (k + 1) :=
      pow_le_pow_left₀ (by positivity) hratio _
    have hC : ((m + 1 + 1).choose (k + 1 + 1) : ℝ)
        = ((m : ℝ) + 1 + 1) / ((k : ℝ) + 1 + 1) * ((m + 1).choose (k + 1) : ℝ) := by
      rw [div_mul_eq_mul_div, eq_div_iff hk0.ne']
      exact hrec
    push_cast
    rw [hC, pow_succ, mul_comm]
    exact mul_le_mul_of_nonneg_left (hpow.trans h1) (by positivity)

/-- The middle entry of an even row is its largest, so it is trapped between the row's total and
the row's average: for every whole number `n`, no entry `C(2n, k)` of row `2n` beats the middle
entry `C(2n, n)`, and `4^n / (2n + 1) ≤ C(2n, n) ≤ 4^n`. -/
theorem central_binom_largest_and_sandwiched (n : ℕ) :
    (∀ k : ℕ, (2 * n).choose k ≤ (2 * n).choose n) ∧
    (4 : ℝ) ^ n / (2 * n + 1) ≤ ((2 * n).choose n : ℝ) ∧
    ((2 * n).choose n : ℝ) ≤ (4 : ℝ) ^ n := by
  refine ⟨fun k => ?_, ?_, ?_⟩
  · have := Nat.choose_le_centralBinom k n
    rwa [Nat.centralBinom_eq_two_mul_choose] at this
  · have h := Nat.four_pow_le_two_mul_add_one_mul_centralBinom n
    rw [Nat.centralBinom_eq_two_mul_choose] at h
    have h' : ((4 : ℝ) ^ n) ≤ (2 * n + 1) * ((2 * n).choose n : ℝ) := by exact_mod_cast h
    rw [div_le_iff₀ (by positivity)]
    linarith
  · have h := Nat.centralBinom_le_four_pow n
    rw [Nat.centralBinom_eq_two_mul_choose] at h
    exact_mod_cast h

/-- Neighbours sit in a fixed ratio: for whole numbers with `1 ≤ k ≤ n`, one step right along
row `n` multiplies the count by `(n - k + 1) / k`; cleared of fractions,
`k × C(n, k) = (n - k + 1) × C(n, k - 1)`. -/
theorem choose_neighbour_ratio (n k : ℕ) (hk : 1 ≤ k) (hkn : k ≤ n) :
    k * n.choose k = (n - k + 1) * n.choose (k - 1) := by
  obtain ⟨j, rfl⟩ : ∃ j, k = j + 1 := ⟨k - 1, by omega⟩
  have h := Nat.choose_succ_right_eq n j
  have e : n - (j + 1) + 1 = n - j := by omega
  rw [e, Nat.add_sub_cancel]
  rw [mul_comm] at h
  rw [h, mul_comm]

/-- Bounds for any pick size: for every `k` from 1 to `n`, the count of picks lies between
`n / k` multiplied in `k` times and `n` multiplied in `k` times over `k!`:
`(n / k)^k ≤ C(n, k) ≤ n^k / k!`. -/
theorem choose_between_pow_bounds (n k : ℕ) (hk : 1 ≤ k) (hkn : k ≤ n) :
    ((n : ℝ) / k) ^ k ≤ (n.choose k : ℝ) ∧ (n.choose k : ℝ) ≤ (n : ℝ) ^ k / (k ! : ℝ) := by
  refine ⟨?_, Nat.choose_le_pow_div k n⟩
  obtain ⟨j, rfl⟩ : ∃ j, k = j + 1 := ⟨k - 1, by omega⟩
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  have := choose_lower_aux j m (by omega)
  push_cast
  exact this

-- The tasting board: 10 cheeses from 20 make 184,756 boards; boards of 9 or 11 make 167,960.
example : Nat.choose 20 10 = 184756 ∧ Nat.choose 20 9 = 167960 ∧ Nat.choose 20 11 = 167960 := by
  decide

-- Row 20, entry by entry, as in the chart.
example : (List.range 21).map (Nat.choose 20) =
    [1, 20, 190, 1140, 4845, 15504, 38760, 77520, 125970, 167960, 184756, 167960, 125970, 77520,
      38760, 15504, 4845, 1140, 190, 20, 1] := by
  decide

-- Row 20 adds to 1,048,576 = 4^10, and 2^10 = 1,024 falls below the count it would cap.
example : (∑ k ∈ range 21, Nat.choose 20 k) = 1048576 ∧ 4 ^ 10 = 1048576 ∧
    2 ^ 10 = 1024 ∧ 2 ^ 10 < Nat.choose 20 10 := by
  decide

-- Step 0 at the board: 11 × 167,960 = 10 × 184,756.
example : 11 * Nat.choose 20 9 = 10 * Nat.choose 20 10 := by
  decide

-- The sandwich cleared of fractions: 184,756 ≤ 1,048,576 ≤ 21 × 184,756 = 3,879,876.
example : Nat.choose 20 10 ≤ 4 ^ 10 ∧ 4 ^ 10 ≤ 21 * Nat.choose 20 10 ∧
    21 * Nat.choose 20 10 = 3879876 := by
  decide

-- The house row, row 10: 252 is its middle, the row adds to 1,024, and 1,024 ≤ 11 × 252 ≤ 11 × 1,024.
example : Nat.choose 10 5 = 252 ∧ (∑ k ∈ range 11, Nat.choose 10 k) = 1024 ∧
    4 ^ 5 ≤ 11 * Nat.choose 10 5 ∧ Nat.choose 10 5 ≤ 4 ^ 5 := by
  decide

-- The general pair at the board, cleared of fractions: 10^10 × 184,756 ≥ 20^10 and 10! × 184,756 ≤ 20^10.
example : 20 ^ 10 ≤ 10 ^ 10 * Nat.choose 20 10 ∧ 10 ! * Nat.choose 20 10 ≤ 20 ^ 10 ∧
    (20 / 10) ^ 10 = 1024 := by
  decide

-- The sampler box: 5 from 100 is 75,287,520, between (100/5)^5 = 3,200,000 and 100^5/5!.
example : Nat.choose 100 5 = 75287520 ∧ (100 / 5) ^ 5 = 3200000 ∧
    3200000 ≤ Nat.choose 100 5 ∧ 5 ! * Nat.choose 100 5 ≤ 100 ^ 5 := by
  decide

-- Vandermonde's road: row 10 squared and added gives 184,756.
example : (∑ k ∈ range 11, Nat.choose 10 k ^ 2) = 184756 := by
  decide

-- The mistake of halving the row: 524,288.
example : 4 ^ 10 / 2 = 524288 := by
  decide

#print axioms choose_lower_aux
#print axioms central_binom_largest_and_sandwiched
#print axioms choose_neighbour_ratio
#print axioms choose_between_pow_bounds
