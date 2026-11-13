-- Normal approximation: the exact facts under the bell, namely that neighbouring binomial bars stand in the ratio (n - k)p / ((k + 1)(1 - p)), that the logarithm of that ratio drops in a straight line whose drops add up to the bell's exponent, and the card's whole-number counts for 100 fair flips.
import Mathlib.Probability.Distributions.Binomial
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Tactic.NormNum

open ProbabilityTheory Finset
open scoped unitInterval

/-- Helper: `Nat.choose` in a form the kernel evaluates quickly. -/
theorem choose_fast (n k : ℕ) : Nat.choose n k = n.descFactorial k / k.factorial :=
  Nat.choose_eq_descFactorial_div_factorial n k

/-- Step 1, neighbouring bars shrink by a fixed factor: for a binomial count `X` of `n` tries
with success chance `p` strictly between 0 and 1, and a count `k` below `n`, one bar over the
next is `P(X = k + 1) / P(X = k) = (n - k) p / ((k + 1)(1 - p))`. -/
theorem binomial_neighbour_ratio (n k : ℕ) (p : I) (hp0 : 0 < (p : ℝ)) (hp1 : (p : ℝ) < 1)
    (hk : k < n) :
    Bin(n, p).real {k + 1} / Bin(n, p).real {k} =
      ((n : ℝ) - k) * p / (((k : ℝ) + 1) * (1 - p)) := by
  rw [binomial_real_singleton, binomial_real_singleton]
  obtain ⟨m, rfl⟩ : ∃ m, n = k + 1 + m := ⟨n - (k + 1), by omega⟩
  have h1 : k + 1 + m - (k + 1) = m := by omega
  have h2 : k + 1 + m - k = m + 1 := by omega
  have hc : ((Nat.choose (k + 1 + m) (k + 1) : ℕ) : ℝ) * ((k : ℝ) + 1) =
      (Nat.choose (k + 1 + m) k : ℝ) * ((m : ℝ) + 1) := by
    have := Nat.choose_succ_right_eq (k + 1 + m) k
    rw [h2] at this
    exact_mod_cast this
  rw [h1, h2]
  have hq : (0 : ℝ) < 1 - p := by linarith
  have hpos : (0 : ℝ) < Nat.choose (k + 1 + m) k := by
    exact_mod_cast Nat.choose_pos (by omega)
  have hk1 : (0 : ℝ) < (k : ℝ) + 1 := by positivity
  push_cast
  rw [div_eq_div_iff (by positivity) (by positivity)]
  have e : ((k : ℝ) + 1 + m - k) = m + 1 := by ring
  rw [e]
  have hcd : ((Nat.choose (k + 1 + m) (k + 1) : ℕ) : ℝ) =
      (Nat.choose (k + 1 + m) k : ℝ) * ((m : ℝ) + 1) / ((k : ℝ) + 1) := by
    field_simp; linarith [hc]
  rw [hcd]
  field_simp
  ring

/-- Step 2, the drop is a straight line: write `q = 1 - p` and `σ² = npq`, and measure the count
from the centre, `k = np + s`. Then, for `n > 0` tries, the neighbour ratio `(n - k) p / ((k + 1) q)` equals
`(1 - s/(nq)) / (1 + (s + 1)/(np))`, and the first-order parts of the two logarithms add to
`-s/(nq) - (s + 1)/(np) = -(s + q)/σ²`, a straight line in `s`. -/
theorem neighbour_ratio_centred (n p s : ℝ) (hn : 0 < n) (hp0 : 0 < p) (hp1 : p < 1) :
    (n - (n * p + s)) * p / ((n * p + s + 1) * (1 - p)) =
        (1 - s / (n * (1 - p))) / (1 + (s + 1) / (n * p)) ∧
      -s / (n * (1 - p)) - (s + 1) / (n * p) = -(s + (1 - p)) / (n * p * (1 - p)) := by
  refine ⟨?_, ?_⟩
  · have hq : 1 - p ≠ 0 := by linarith
    have hp : p ≠ 0 := by linarith
    have hn' : n ≠ 0 := hn.ne'
    rcases eq_or_ne (n * p + s + 1) 0 with h | h
    · have h2 : 1 + (s + 1) / (n * p) = 0 := by
        rw [one_add_div (mul_ne_zero hn' hp), show n * p + (s + 1) = n * p + s + 1 by ring, h,
          zero_div]
      rw [h, zero_mul, div_zero, h2, div_zero]
    · have h' : n * p + (s + 1) ≠ 0 := by rwa [show n * p + (s + 1) = n * p + s + 1 by ring]
      rw [one_sub_div (mul_ne_zero hn' hq), one_add_div (mul_ne_zero hn' hp)]
      field_simp
      ring
  · have hq : 1 - p ≠ 0 := by linarith
    have hp : p ≠ 0 := by linarith
    field_simp
    ring

/-- Step 3, adding the drops makes the bell's exponent: the straight-line drops `-(s + q)/σ²`
for `s = 0, 1, …, t - 1` add up to `-(t(t - 1)/2 + q t)/σ² = -t²/(2σ²) + (1/2 - q) t/σ²`,
for every whole number `t` and all real `q` and `σ²`. -/
theorem sum_of_linear_drops (t : ℕ) (q σ2 : ℝ) :
    (∑ s ∈ range t, -((s : ℝ) + q) / σ2) =
        -(((t : ℝ) * (t - 1) / 2 + q * t) / σ2) ∧
      -(((t : ℝ) * (t - 1) / 2 + q * t) / σ2) =
        -(t : ℝ) ^ 2 / (2 * σ2) + (1 / 2 - q) * t / σ2 := by
  constructor
  · induction t with
    | zero => simp
    | succ t ih =>
      rw [Finset.sum_range_succ, ih]
      push_cast
      ring
  · ring

-- Pascal's row 100 holds every one of the 2^100 head-tail strings once.
example : (∑ k ∈ range 101, Nat.choose 100 k) = 2 ^ 100 := by
  rw [Nat.sum_range_choose]

-- 36,057,011,612,866,492,098,338,762,600 strings of 100 flips hold 60 heads or more.
example : (∑ k ∈ Icc 60 100, Nat.choose 100 k) = 36057011612866492098338762600 := by
  simp only [choose_fast]
  decide +kernel

-- That count over 2^100 rounds to 0.028444: it lies in [0.0284435, 0.0284445).
example : 284435 * 2 ^ 100 ≤ 10 ^ 7 * (∑ k ∈ Icc 60 100, Nat.choose 100 k) ∧
    10 ^ 7 * (∑ k ∈ Icc 60 100, Nat.choose 100 k) < 284445 * 2 ^ 100 := by
  simp only [choose_fast]
  decide +kernel

-- The single bar at 60 heads, C(100, 60)/2^100, rounds to 0.010844.
example : 108435 * 2 ^ 100 ≤ 10 ^ 7 * Nat.choose 100 60 ∧
    10 ^ 7 * Nat.choose 100 60 < 108445 * 2 ^ 100 := by
  simp only [choose_fast]
  decide +kernel

-- Step 1 at 100 fair flips: 50 to 51 heads multiplies by 50/51, and 59 to 60 by 41/60.
example : 51 * Nat.choose 100 51 = 50 * Nat.choose 100 50 ∧
    60 * Nat.choose 100 60 = 41 * Nat.choose 100 59 := by
  simp only [choose_fast]
  decide +kernel

-- Worked numbers: average 50, variance 25 (at least 10, so safe), spread 5 since 5² = 25,
-- and the cut at 59.5 sits (59.5 - 50)/5 = 1.9 spreads above the centre.
example : (100 : ℚ) * (1 / 2) = 50 ∧ (100 : ℚ) * (1 / 2) * (1 - 1 / 2) = 25 ∧
    (10 : ℚ) ≤ 25 ∧ (5 : ℚ) ^ 2 = 25 ∧ ((119 / 2 : ℚ) - 50) / 5 = 19 / 10 := by
  norm_num

-- The variance np instead of np(1 - p) is 50, so the wrong spread is √50, not 5.
example : (100 : ℚ) * (1 / 2) = 50 ∧ (5 : ℚ) ^ 2 ≠ 50 := by
  norm_num

-- 10 fair flips, 6 or more heads: 386 of 1,024 strings, exactly 0.376953125; np(1 - p) = 2.5.
example : (∑ k ∈ Icc 6 10, Nat.choose 10 k) = 386 ∧ 386 * 10 ^ 9 = 376953125 * 2 ^ 10 ∧
    (10 : ℚ) * (1 / 2) * (1 / 2) = 5 / 2 := by
  refine ⟨?_, by norm_num, by norm_num⟩
  simp only [choose_fast]
  decide +kernel

-- 30 fair flips, 18 or more heads: the exact chance rounds to 0.180797.
example : 1807965 * 2 ^ 30 ≤ 10 ^ 7 * (∑ k ∈ Icc 18 30, Nat.choose 30 k) ∧
    10 ^ 7 * (∑ k ∈ Icc 18 30, Nat.choose 30 k) < 1807975 * 2 ^ 30 := by
  simp only [choose_fast]
  decide +kernel

-- 400 fair flips, 240 or more heads: the exact chance rounds to 0.000037.
example : 365 * 2 ^ 400 ≤ 10 ^ 7 * (∑ k ∈ Icc 240 400, Nat.choose 400 k) ∧
    10 ^ 7 * (∑ k ∈ Icc 240 400, Nat.choose 400 k) < 375 * 2 ^ 400 := by
  simp only [choose_fast]
  decide +kernel

-- The bent coin, p = 0.02 and 100 tries: np(1 - p) = 1.96, under 10, and P(X = 0) = 0.98^100
-- rounds to 0.132620.
example : (100 : ℚ) * (2 / 100) * (98 / 100) = 196 / 100 ∧ (196 / 100 : ℚ) < 10 ∧
    (1326195 / 10 ^ 7 : ℚ) ≤ (98 / 100) ^ 100 ∧ ((98 : ℚ) / 100) ^ 100 < 1326205 / 10 ^ 7 := by
  norm_num

-- The bent coin's exact tail P(X ≥ 5) = 1 - P(X ≤ 4) rounds to 0.050830.
example : (508295 / 10 ^ 7 : ℚ) ≤
      1 - ∑ k ∈ range 5, (Nat.choose 100 k : ℚ) * (2 / 100) ^ k * (98 / 100) ^ (100 - k) ∧
    1 - ∑ k ∈ range 5, (Nat.choose 100 k : ℚ) * (2 / 100) ^ k * (98 / 100) ^ (100 - k) <
      508305 / 10 ^ 7 := by
  simp only [Finset.sum_range_succ, Finset.sum_range_zero]
  norm_num [Nat.choose]

#print axioms choose_fast
#print axioms binomial_neighbour_ratio
#print axioms neighbour_ratio_centred
#print axioms sum_of_linear_drops
