-- Linear versus exponential growth: any straight line is eventually and forever passed by growth that starts at one or more and multiplies by a factor bigger than 1, the last doubling adds more than all the doublings before it, and with factor 1 the gardener wins.
import Mathlib.Data.Real.Basic
import Mathlib.Algebra.Order.Ring.GeomSum
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.Tactic.NormNum

/-- Adding always loses to multiplying, if you wait: take any straight line (any starting
amount `c`, any fixed step `d` added each day) and any exponential growth that starts with at
least one (`1 ≤ a`) and multiplies by a factor bigger than 1 (`1 < b`) each day. Then from some
day on, every day, the exponential amount `a * b ^ n` is bigger than the linear amount
`c + d * n`. -/
theorem multiplying_eventually_beats_adding (a b c d : ℝ) (ha : 1 ≤ a) (hb : 1 < b) :
    ∃ N : ℕ, ∀ n : ℕ, N ≤ n → c + d * n < a * b ^ n := by
  have hb0 : 0 < b := by linarith
  have h1 : Filter.Tendsto (fun n : ℕ => (n : ℝ) ^ 1 / b ^ n) Filter.atTop (nhds 0) :=
    tendsto_pow_const_div_const_pow_of_one_lt 1 hb
  have h2 : Filter.Tendsto (fun n : ℕ => (1 : ℝ) / b ^ n) Filter.atTop (nhds 0) := by
    have := tendsto_pow_atTop_nhds_zero_of_lt_one (r := b⁻¹) (by positivity)
      (inv_lt_one_of_one_lt₀ hb)
    simpa [one_div] using this
  have h3 : Filter.Tendsto (fun n : ℕ => |c| * (1 / b ^ n) + |d| * ((n : ℝ) ^ 1 / b ^ n))
      Filter.atTop (nhds (|c| * 0 + |d| * 0)) :=
    (h2.const_mul _).add (h1.const_mul _)
  rw [mul_zero, mul_zero, add_zero] at h3
  obtain ⟨N, hN⟩ := Filter.eventually_atTop.mp (h3.eventually (gt_mem_nhds (show (0:ℝ) < 1 by norm_num)))
  refine ⟨N, fun n hn => ?_⟩
  have h := hN n hn
  have hbn : 0 < b ^ n := pow_pos hb0 n
  have : |c| * (1 / b ^ n) + |d| * ((n : ℝ) ^ 1 / b ^ n) = (|c| + |d| * n) / b ^ n := by
    field_simp
  rw [this, div_lt_one hbn] at h
  have hn0 : (0:ℝ) ≤ n := Nat.cast_nonneg n
  have e1 : c + d * n ≤ |c| + |d| * n := by
    have := le_abs_self c
    have : d * n ≤ |d| * n := mul_le_mul_of_nonneg_right (le_abs_self d) hn0
    linarith
  have e2 : b ^ n ≤ a * b ^ n := by nlinarith
  linarith

/-- The last doubling adds more than all the ones before it put together: the doubling pond
holds `2 ^ k` pads on day `k` and gains `2 ^ (k + 1) - 2 ^ k` overnight, and the gain from day `n`
to day `n + 1` is bigger than the gains of all the earlier nights added up. -/
theorem last_doubling_beats_all_before (n : ℕ) :
    ∑ k ∈ Finset.range n, (2 ^ (k + 1) - 2 ^ k) < 2 ^ (n + 1) - 2 ^ n := by
  have e : ∀ k : ℕ, 2 ^ (k + 1) - 2 ^ k = 2 ^ k := by
    intro k
    rw [pow_succ]
    omega
  have h : ∀ m : ℕ, ∑ k ∈ Finset.range m, (2 ^ (k + 1) - 2 ^ k) + 1 = 2 ^ m := by
    intro m
    induction m with
    | zero => simp
    | succ m ih => rw [Finset.sum_range_succ, e m, pow_succ]; omega
  have h1 := h n
  rw [e n]
  omega

/-- With factor 1 the gardener wins: a pond that starts with one pad and is multiplied by 1 each
day stays at one pad, so from day 1 on it has fewer pads than the gardener's pond, which starts
at one pad and gains one pad a day. -/
theorem factor_one_gardener_wins (n : ℕ) (hn : 1 ≤ n) :
    1 * 1 ^ n < 1 + n * 1 := by
  simp
  omega

-- Day 2: three pads against four.
example : 1 + 2 * 1 = 3 ∧ 1 * 2 ^ 2 = 4 := by decide
-- The first ten days, one pad a day: 1, 2, 3, ..., 11.
example : (List.range 11).map (fun n => 1 + n * 1) = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] := by
  decide
-- The first ten days, doubling: 1, 2, 4, ..., 1024.
example : (List.range 11).map (fun n => 1 * 2 ^ n) =
    [1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024] := by decide
-- Day 10: the gardener has 11 pads, the doubling pond 1,024.
example : 1 + 10 * 1 = 11 ∧ 2 ^ 10 = 1024 := by decide
-- Day 19, doubling: 524,288; day 20 is that doubled: 1,048,576.
example : 2 ^ 19 = 524288 ∧ 524288 * 2 = 1048576 ∧ 2 ^ 20 = 1048576 := by norm_num
-- Day 20, gardener: 1 + 20 x 1 = 21; the gap on day 20 is 1,048,555.
example : 1 + 20 * 1 = 21 ∧ 2 ^ 20 - 21 = 1048555 := by norm_num
-- A second road: twenty doublings are ten doublings squared, 1,024 x 1,024.
example : 2 ^ 20 = 1024 * 1024 := by norm_num
-- A million pads covers a pond: day 19 is short of it, day 20 reaches it.
example : 2 ^ 19 < 1000000 ∧ 1000000 ≤ 2 ^ 20 := by norm_num
-- The gardener reaches a million on day 999,999, which is 2,739 whole years.
example : 1 + 999999 * 1 = 1000000 ∧ 999999 / 365 = 2739 := by norm_num
-- The two mistakes: two more a day gives 41, and 2 x 20 gives 40.
example : 1 + 20 * 2 = 41 ∧ 2 * 20 = 40 := by norm_num
-- Halfway in time is nowhere near halfway in size: half of day 20 is 524,288, day 10 is 1,024.
example : 2 ^ 20 / 2 = 524288 ∧ 2 ^ 10 = 1024 := by norm_num
-- On day 4 the pond holds 16 and gains 16 overnight; on day 19 it holds 524,288 and gains 524,288.
example : 2 ^ 5 - 2 ^ 4 = 16 ∧ 2 ^ 20 - 2 ^ 19 = 524288 := by norm_num

#print axioms multiplying_eventually_beats_adding
#print axioms last_doubling_beats_all_before
#print axioms factor_one_gardener_wins
