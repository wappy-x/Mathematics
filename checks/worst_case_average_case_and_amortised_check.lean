-- Which case are you quoting? Worst, average and amortised cost: a playlist array that doubles when full costs at most 3n writes for any n adds from empty, exactly n + 2^⌈log₂ n⌉ - 1 writes in total, and linear search over n equally likely slots averages (n + 1)/2 comparisons.
import Mathlib.Data.Nat.Log
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Data.Rat.Defs
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.FieldSimp
import Mathlib.Algebra.BigOperators.Ring.Finset

open Finset

/-- The doubling array after `n` adds to an empty playlist, as
`(size, capacity, total writes)`. An add writes the new track (1 write); if the
block is full (`size = capacity`) it first copies every stored track into a new
block of capacity `max 1 (2 * capacity)`, so that add costs `size + 1` writes. -/
def doublingRun : ℕ → ℕ × ℕ × ℕ
  | 0 => (0, 0, 0)
  | n + 1 =>
    let s := (doublingRun n).1
    let m := (doublingRun n).2.1
    let t := (doublingRun n).2.2
    if s = m then (s + 1, max 1 (2 * m), t + s + 1) else (s + 1, m, t + 1)

/-- Total writes made by `n` adds to an empty doubling playlist. -/
def doublingTotal (n : ℕ) : ℕ := (doublingRun n).2.2

/-- Closed form of the doubling run. -/
theorem doublingRun_spec (n : ℕ) :
    doublingRun n = (n, if n = 0 then 0 else 2 ^ Nat.clog 2 n, n + 2 ^ Nat.clog 2 n - 1) := by
  induction n with
  | zero => simp [doublingRun]
  | succ n ih =>
    rw [doublingRun, ih]
    simp only
    rcases Nat.eq_zero_or_pos n with rfl | hn
    · simp
    · have hn0 : n ≠ 0 := Nat.pos_iff_ne_zero.mp hn
      simp only [hn0, ↓reduceIte, Nat.succ_ne_zero]
      set c := Nat.clog 2 n with hc
      have hle : n ≤ 2 ^ c := Nat.le_pow_clog (by norm_num) n
      have hmono : c ≤ Nat.clog 2 (n + 1) := Nat.clog_mono_right 2 (Nat.le_succ n)
      have hp : 1 ≤ 2 ^ c := Nat.one_le_two_pow
      split_ifs with h
      · have hc1 : Nat.clog 2 (n + 1) = c + 1 := by
          apply le_antisymm
          · apply Nat.clog_le_of_le_pow
            rw [pow_succ]; omega
          · rw [Nat.succ_le_iff, Nat.lt_clog_iff_pow_lt (by norm_num)]; omega
        rw [hc1, pow_succ]
        refine Prod.ext rfl (Prod.ext ?_ ?_) <;> dsimp only <;> omega
      · have hc1 : Nat.clog 2 (n + 1) = c := by
          apply le_antisymm
          · apply Nat.clog_le_of_le_pow; omega
          · exact hmono
        rw [hc1]
        refine Prod.ext rfl (Prod.ext rfl ?_)
        dsimp only
        omega

#print axioms doublingRun_spec

/-- For `n ≥ 1`, the smallest power of two at least `n` is below `2 n`. -/
theorem two_pow_clog_lt (n : ℕ) (hn : 1 ≤ n) : 2 ^ Nat.clog 2 n < 2 * n := by
  rcases Nat.lt_or_ge 1 n with h | h
  · have h1 := Nat.pow_pred_clog_lt_self (b := 2) (by norm_num) h
    have h2 : 0 < Nat.clog 2 n := Nat.clog_pos (by norm_num) h
    have h3 : 2 ^ Nat.clog 2 n = 2 * 2 ^ (Nat.clog 2 n).pred := by
      rw [← pow_succ']; congr 1; rw [Nat.pred_eq_sub_one]; omega
    omega
  · have : n = 1 := by omega
    subst this; simp

#print axioms two_pow_clog_lt

/-- The sum `1 + 2 + ⋯ + n` in `ℚ`. -/
theorem sum_Icc_one_cast (n : ℕ) : ∑ k ∈ Icc 1 n, (k : ℚ) = (n : ℚ) * ((n : ℚ) + 1) / 2 := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_Icc_succ_top (by omega), ih]
    push_cast
    ring

#print axioms sum_Icc_one_cast

/-- The amortised bound: for every `n`, a run of `n` adds to an empty playlist
array that doubles when full costs at most `3 n` writes in total, so the
amortised cost per add is at most 3. -/
theorem doubling_total_le_three_mul (n : ℕ) : doublingTotal n ≤ 3 * n := by
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · decide
  · have h := two_pow_clog_lt n hn
    have e : doublingTotal n = n + 2 ^ Nat.clog 2 n - 1 := by
      simp [doublingTotal, doublingRun_spec n]
    omega

/-- Where the copies fall: the copies are `1 + 2 + 4 + ⋯` up to the largest power
of two below `n`, so the total of `n` adds from empty is exactly
`n + 2^(j+1) - 1`, where `2^(j+1) = 2^⌈log₂ n⌉` is the smallest power of two that
is at least `n`. -/
theorem doubling_total_eq (n : ℕ) : doublingTotal n = n + 2 ^ Nat.clog 2 n - 1 := by
  simp [doublingTotal, doublingRun_spec n]

/-- The average case of linear search: a track in slot `k` costs `k` comparisons,
and if each of the `n` slots is equally likely (chance `1/n` each), the mean cost
is `(n + 1)/2`. -/
theorem linear_search_average_uniform (n : ℕ) (hn : n ≠ 0) :
    ∑ k ∈ Icc 1 n, (1 / (n : ℚ)) * (k : ℚ) = ((n : ℚ) + 1) / 2 := by
  rw [← Finset.mul_sum, sum_Icc_one_cast]
  have : (n : ℚ) ≠ 0 := by exact_mod_cast hn
  field_simp

/-! ### The card's whole-number worked examples -/

-- The first 20 adds: capacity 32, total 51 writes (running average 51/20).
example : doublingRun 20 = (20, 32, 51) := by decide
-- The per-add costs in the chart: 1, 2, 3, 1, 5, 1, 1, 1, 9, then 1s, and 17 at add 17.
example : (List.range 20).map (fun i => doublingTotal (i + 1) - doublingTotal i)
    = [1, 2, 3, 1, 5, 1, 1, 1, 9, 1, 1, 1, 1, 1, 1, 1, 17, 1, 1, 1] := by decide
-- One million adds: largest power of two below n is 2^19 = 524,288, final capacity 2^20.
example : 2 ^ 19 < 1000000 ∧ 1000000 ≤ 2 ^ 20 ∧ 2 ^ 19 = 524288 ∧ 2 ^ 20 = 1048576 := by
  norm_num
-- Copies 1 + 2 + ⋯ + 524,288 = 1,048,575; total 2,048,575 writes, under 3,000,000.
example : ∑ i ∈ range 20, 2 ^ i = 1048575 := by decide
example : 1000000 + 2 ^ 20 - 1 = 2048575 ∧ 2048575 ≤ 3 * 1000000 := by norm_num
-- Worst single add: 524,288 copies plus 1 write.
example : 2 ^ 19 + 1 = 524289 := by norm_num
-- Tight case: 1,048,577 adds cost 3,145,728 writes, still under 3 per add.
example : 1048577 + 2 ^ 21 - 1 = 3145728 ∧ 3145728 < 3 * 1048577 := by norm_num
-- Linear search on 1,000,000 slots: average (1,000,000 + 1)/2 = 500,000.5.
example : ((1000000 : ℚ) + 1) / 2 = 1000001 / 2 := by norm_num
-- 9 in 10 searches for the newest 10,000 (mean slot 995,000.5), 1 in 10 uniform.
example : (2 * 1000000 - 9999 : ℚ) / 2 = 1990001 / 2 := by norm_num
example : (9 / 10 : ℚ) * (1990001 / 2) + (1 / 10) * (1000001 / 2) = 1891001 / 2 := by norm_num
-- Fixed +1,000 growth: copies at 1,000, 2,000, …, 999,000; total 500,500,000 writes.
example : 1000000 + 1000 * (999 * 1000 / 2) = 500500000 := by norm_num
-- Quoting the worst add as the per-add cost predicts 524,289,000,000 writes.
example : 524289 * 1000000 = 524289000000 := by norm_num

#print axioms doubling_total_le_three_mul
#print axioms doubling_total_eq
#print axioms linear_search_average_uniform
