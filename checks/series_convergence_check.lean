-- Infinite series: the running totals of a geometric series a + ar + ar^2 + ... head for a/(1 - r) whenever the ratio r is strictly between -1 and 1, the first n terms add to a(1 - r^n)/(1 - r) whenever r is not 1, and any series whose running totals settle has terms that shrink to 0.
import Mathlib.Algebra.Field.GeomSum
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Tactic.NormNum

open Filter Topology Finset

/-- The geometric series, forever. With first term a and a fixed ratio r strictly between -1 and 1,
the running totals a + ar + ... + ar^(n-1) head for one number, a / (1 - r): the series converges
and its sum is the first term over one minus the ratio. -/
theorem geometric_series_sums_to_first_term_over_one_minus_ratio (a r : ℝ)
    (h_lower : -1 < r) (h_upper : r < 1) :
    Tendsto (fun n : ℕ => ∑ k ∈ range n, a * r ^ k) atTop (𝓝 (a / (1 - r))) := by
  have hr : |r| < 1 := abs_lt.mpr ⟨h_lower, h_upper⟩
  have hp : Tendsto (fun n : ℕ => r ^ n) atTop (𝓝 0) :=
    tendsto_pow_atTop_nhds_zero_iff.mpr hr
  have h1 : (1 : ℝ) - r ≠ 0 := (sub_pos.mpr h_upper).ne'
  have h2 : r - 1 ≠ 0 := sub_ne_zero.mpr (ne_of_lt h_upper)
  have hlim : Tendsto (fun n : ℕ => a * (1 - r ^ n) / (1 - r)) atTop
      (𝓝 (a * (1 - 0) / (1 - r))) :=
    ((tendsto_const_nhds.sub hp).const_mul a).div_const (1 - r)
  rw [sub_zero, mul_one] at hlim
  refine hlim.congr (fun n => ?_)
  rw [← Finset.mul_sum, geom_sum_eq (ne_of_lt h_upper)]
  field_simp
  ring

/-- The finite geometric sum, by shifting and subtracting. For any ratio r other than 1, the first
n terms a + ar + ... + ar^(n-1) add to a(1 - r^n)/(1 - r). -/
theorem finite_geometric_sum (a r : ℝ) (hr : r ≠ 1) (n : ℕ) :
    ∑ k ∈ range n, a * r ^ k = a * (1 - r ^ n) / (1 - r) := by
  have h1 : (1 : ℝ) - r ≠ 0 := sub_ne_zero.mpr (Ne.symm hr)
  have h2 : r - 1 ≠ 0 := sub_ne_zero.mpr hr
  rw [← Finset.mul_sum, geom_sum_eq hr]
  field_simp
  ring

/-- The term test. If the running totals of a series settle on a number S, then the terms
themselves shrink to 0. Turned round: terms that do not shrink to 0 rule the series out. -/
theorem term_test (a : ℕ → ℝ) (S : ℝ)
    (h : Tendsto (fun n : ℕ => ∑ k ∈ range n, a k) atTop (𝓝 S)) :
    Tendsto a atTop (𝓝 0) := by
  have h1 : Tendsto (fun n : ℕ => ∑ k ∈ range (n + 1), a k) atTop (𝓝 S) :=
    h.comp (tendsto_add_atTop_nat 1)
  have h2 := h1.sub h
  rw [sub_self] at h2
  refine h2.congr (fun n => ?_)
  simp [Finset.sum_range_succ]

-- The perpetuity: first term 100/1.05, ratio 1/1.05, sum 100/0.05 = 2000 (written as fractions).
example : ((100 : ℚ) / (105 / 100)) / (1 - 1 / (105 / 100)) = 2000 := by norm_num
example : (100 : ℚ) / (5 / 100) = 2000 := by norm_num
-- The self-similar equation S = (100 + S)/1.05 holds at S = 2000.
example : ((100 : ℚ) + 2000) / (105 / 100) = 2000 := by norm_num
-- Landing within 1 of 2000: the tail 2000/1.05^n is at most 1 first at n = 156.
example : 2000 * 100 ^ 156 ≤ (105 : ℕ) ^ 156 ∧ (105 : ℕ) ^ 155 < 2000 * 100 ^ 155 := by norm_num
-- Landing within one cent: the tail is at most 1/100 first at n = 251.
example : 200000 * 100 ^ 251 ≤ (105 : ℕ) ^ 251 ∧ (105 : ℕ) ^ 250 < 200000 * 100 ^ 250 := by norm_num
-- Payments growing 5% a year: the second term 105/1.05^2 equals the first, 100/1.05 (ratio 1).
example : (105 : ℚ) / (105 / 100) ^ 2 = 100 / (105 / 100) := by norm_num
-- The mistakes: ratio 0.95 gives 1900; a payment today as well gives 2100; S = 1 + 2S gives -1.
example : (95 : ℚ) / (1 - 95 / 100) = 1900 := by norm_num
example : (100 : ℚ) + 2000 = 2100 := by norm_num
example : (1 : ℚ) / (1 - 2) = -1 := by norm_num
-- The harmonic doubling bound: 1024 is ten 2s multiplied together, so the bound is 1 + 10/2 = 6.
example : (2 : ℕ) ^ 10 = 1024 ∧ (1 : ℚ) + 10 / 2 = 6 := by norm_num
-- One block of the harmonic series: 1/3 + 1/4 is at least 1/2, and 1/5 + ... + 1/8 is at least 1/2.
example : (1 : ℚ) / 3 + 1 / 4 ≥ 1 / 2 ∧ (1 : ℚ) / 5 + 1 / 6 + 1 / 7 + 1 / 8 ≥ 1 / 2 := by norm_num

#print axioms geometric_series_sums_to_first_term_over_one_minus_ratio
#print axioms finite_geometric_sum
#print axioms term_test
