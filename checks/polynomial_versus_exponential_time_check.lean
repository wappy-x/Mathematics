-- Polynomial or exponential: 2ⁿ beats n³ for every n from 10 on, and a machine s times faster multiplies a power-cost method's reach by s^(1/k) but only adds log₂ s to a 2ⁿ method's reach.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Log.Base

/-- The crossing: once n is 10 or more, 2ⁿ is strictly bigger than n³, and it never falls back. -/
theorem two_pow_gt_cube_from_ten (n : ℕ) (hn : 10 ≤ n) : n ^ 3 < 2 ^ n := by
  induction n, hn using Nat.le_induction with
  | base => norm_num
  | succ m hm ih =>
    have h1 : 3 * m ^ 2 + 3 * m + 1 ≤ m ^ 3 := by nlinarith
    calc (m + 1) ^ 3 = m ^ 3 + (3 * m ^ 2 + 3 * m + 1) := by ring
      _ ≤ m ^ 3 + m ^ 3 := by omega
      _ < 2 ^ m + 2 ^ m := by omega
      _ = 2 ^ (m + 1) := by ring

/-- A polynomial method's reach is multiplied by speed. If a cost of xᵏ steps exactly fills the
budget B at size n_old, then on a machine s times faster (budget s·B) the sizes that fit are
exactly those up to s^(1/k) · n_old. -/
theorem faster_machine_multiplies_polynomial_reach (k : ℕ) (hk : k ≠ 0) (s B n_old : ℝ)
    (hs : 0 < s) (hn : 0 ≤ n_old) (hB : n_old ^ k = B) (x : ℝ) (hx : 0 ≤ x) :
    x ^ k ≤ s * B ↔ x ≤ s ^ ((1 : ℝ) / k) * n_old := by
  have hsk : (s ^ ((1 : ℝ) / k)) ^ k = s := by
    rw [one_div]; exact Real.rpow_inv_natCast_pow hs.le hk
  have hc : 0 ≤ s ^ ((1 : ℝ) / k) * n_old := mul_nonneg (Real.rpow_nonneg hs.le _) hn
  have hpow : (s ^ ((1 : ℝ) / k) * n_old) ^ k = s * B := by
    rw [mul_pow, hsk, hB]
  rw [← hpow]
  exact pow_le_pow_iff_left₀ hx hc hk

/-- An exponential method's reach only grows by addition. If a cost of 2ˣ steps exactly fills the
budget B at size n_old, then on a machine s times faster (budget s·B) the sizes that fit are
exactly those up to n_old + log₂ s. -/
theorem faster_machine_adds_to_exponential_reach (s B n_old : ℝ) (hs : 0 < s)
    (hB : (2 : ℝ) ^ n_old = B) (x : ℝ) :
    (2 : ℝ) ^ x ≤ s * B ↔ x ≤ n_old + Real.logb 2 s := by
  have h : (2 : ℝ) ^ (n_old + Real.logb 2 s) = s * B := by
    rw [Real.rpow_add (by norm_num : (0 : ℝ) < 2), Real.rpow_logb (by norm_num) (by norm_num) hs,
      hB, mul_comm]
  rw [← h]
  exact Real.rpow_le_rpow_left_iff (by norm_num : (1 : ℝ) < 2)

-- The 40-stop van: the distance table and the count of sets of stops.
example : 40 ^ 3 = 64000 := by norm_num
example : 2 ^ 40 = 1099511627776 := by norm_num
example : 2 ^ 40 / 40 ^ 3 = 17179869 := by norm_num
-- One more stop: 41³ and 2⁴¹ = 2 · 2⁴⁰.
example : 41 ^ 3 = 68921 := by norm_num
example : 2 ^ 41 = 2199023255552 ∧ 2 ^ 41 = 2 * 2 ^ 40 := by norm_num
-- The crossing: 2⁸ < 8³, 2⁹ ≤ 9³, 2¹⁰ > 10³.
example : 2 ^ 8 = 256 ∧ 8 ^ 3 = 512 ∧ 2 ^ 8 < 8 ^ 3 := by norm_num
example : 2 ^ 9 = 512 ∧ 9 ^ 3 = 729 ∧ 2 ^ 9 ≤ 9 ^ 3 := by norm_num
example : 2 ^ 10 = 1024 ∧ 10 ^ 3 = 1000 ∧ 10 ^ 3 < 2 ^ 10 := by norm_num
-- The scan: from 1 to 120, 2ⁿ ≤ n³ holds exactly for n = 2 to 9.
example : (Finset.Icc 1 120).filter (fun n : ℕ => 2 ^ n ≤ n ^ 3) = Finset.Icc 2 9 := by decide
-- Against n⁵ the crossing is at 23: 2²² ≤ 22⁵ but 2ⁿ > n⁵ from 23 to 120.
example : 2 ^ 22 ≤ 22 ^ 5 ∧ 23 ^ 5 < 2 ^ 23 := by norm_num
example : ∀ n ∈ Finset.Icc 23 120, n ^ 5 < 2 ^ n := by decide
-- Against n⁴ the two meet at 16 and 2ⁿ passes at 17.
example : 2 ^ 16 = 65536 ∧ 16 ^ 4 = 65536 ∧ 17 ^ 4 < 2 ^ 17 := by norm_num
-- The set-by-set exact round for 40 stops: 39 · 38 · 2³⁷ + 39 steps.
example : 39 * 38 * 2 ^ 37 + 39 = 203684529045543 := by norm_num
-- One hour at a billion steps a second is 3,600,000,000,000 steps.
-- n³ fits 15,326 stops and 2ⁿ fits 41.
example : 15326 ^ 3 ≤ 3600 * 10 ^ 9 ∧ 3600 * 10 ^ 9 < 15327 ^ 3 := by norm_num
example : 2 ^ 41 ≤ 3600 * 10 ^ 9 ∧ 3600 * 10 ^ 9 < 2 ^ 42 := by norm_num
-- A machine 1,000 times faster: n³ fits 153,261 stops and 2ⁿ fits 51.
example : 153261 ^ 3 ≤ 1000 * (3600 * 10 ^ 9) ∧ 1000 * (3600 * 10 ^ 9) < 153262 ^ 3 := by norm_num
example : 2 ^ 51 ≤ 1000 * (3600 * 10 ^ 9) ∧ 1000 * (3600 * 10 ^ 9) < 2 ^ 52 := by norm_num
-- One day: n³ fits 44,208 stops and 2ⁿ fits 46.
example : 44208 ^ 3 ≤ 24 * (3600 * 10 ^ 9) ∧ 24 * (3600 * 10 ^ 9) < 44209 ^ 3 := by norm_num
example : 2 ^ 46 ≤ 24 * (3600 * 10 ^ 9) ∧ 24 * (3600 * 10 ^ 9) < 2 ^ 47 := by norm_num
-- 82 stops in one hour by speed alone: the least speed-up is 1,343,250,910,683.
example : 2 ^ 82 ≤ 1343250910683 * (3600 * 10 ^ 9) ∧
    1343250910682 * (3600 * 10 ^ 9) < 2 ^ 82 := by norm_num
-- Reading 2⁴⁰ as 40²: 1,600, not 1,099,511,627,776.
example : 40 ^ 2 = 1600 := by norm_num

#print axioms two_pow_gt_cube_from_ten
#print axioms faster_machine_multiplies_polynomial_reach
#print axioms faster_machine_adds_to_exponential_reach
