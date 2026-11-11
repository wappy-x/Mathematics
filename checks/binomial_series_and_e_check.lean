-- The binomial series and the number e: for every real power a, (1 + x)^a is the sum of the extended choice counts C(a, k) times x^k whenever x is strictly between −1 and 1 (or a is a whole number, for any x), compounding (1 + 1/n)^n stays under the series 1 + 1 + 1/2! + … and heads for e, which that series equals, and the alternating series is 1/e, the limit of the clean-draw share D(n)/n!, with D(n) equal to n!/e rounded from n = 1 on.
import Mathlib.Analysis.Analytic.Binomial
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Exponential
import Mathlib.Analysis.SpecialFunctions.Complex.LogBounds
import Mathlib.Combinatorics.Derangements.Exponential
import Mathlib.Algebra.Order.Round
import Mathlib.Tactic.NormNum

open Filter Topology Finset Nat

theorem numDerangements_div_factorial_eq (n : ℕ) :
    (numDerangements n : ℝ) / n.factorial = ∑ k ∈ Finset.range (n + 1), (-1 : ℝ) ^ k / k.factorial := by
  rw [← Int.cast_natCast, numDerangements_sum]
  push_cast
  rw [Finset.sum_div]
  refine Finset.sum_congr (refl _) ?_
  intro k hk
  have h_le : k ≤ n := Finset.mem_range_succ_iff.mp hk
  rw [Nat.ascFactorial_eq_div, add_tsub_cancel_of_le h_le]
  push_cast [Nat.factorial_dvd_factorial h_le]
  field

#print axioms numDerangements_div_factorial_eq

/-- **Newton's binomial series.** Take any real power a and write
C(a, k) = a(a − 1)(a − 2)⋯(a − k + 1)/k!, with C(a, 0) = 1 (Mathlib's `Ring.choose a k`).
If the added bit x is strictly between −1 and 1, or if the power a is a whole number 0, 1, 2, …
(then the pieces stop and any x works), the endless sum ∑ C(a, k) x^k adds up exactly to
(1 + x)^a. -/
theorem binomial_series_hasSum (a x : ℝ) (h : (-1 < x ∧ x < 1) ∨ ∃ m : ℕ, a = m) :
    HasSum (fun k : ℕ => Ring.choose a k * x ^ k) ((1 + x) ^ a) := by
  rcases h with ⟨h1, h2⟩ | ⟨m, rfl⟩
  · have hx : x ∈ Metric.eball (0 : ℝ) 1 := by
      rw [Metric.mem_eball, edist_dist, ENNReal.ofReal_lt_one, Real.dist_eq, sub_zero, abs_lt]
      exact ⟨h1, h2⟩
    have := (Real.one_add_rpow_hasFPowerSeriesOnBall_zero (a := a)).hasSum hx
    simpa [binomialSeries, FormalMultilinearSeries.coeff_ofScalars, mul_comm] using this
  · rw [Real.rpow_natCast]
    have hfin : ∀ k ∉ range (m + 1), Ring.choose (m : ℝ) k * x ^ k = 0 := by
      intro k hk
      rw [Ring.choose_natCast, Nat.choose_eq_zero_of_lt (by simpa using hk)]
      simp
    suffices e : (1 + x) ^ m = ∑ k ∈ range (m + 1), Ring.choose (m : ℝ) k * x ^ k by
      rw [e]; exact hasSum_sum_of_ne_finset_zero hfin
    rw [add_comm, add_pow]
    refine Finset.sum_congr rfl fun k _ => ?_
    rw [Ring.choose_natCast]
    ring

/-- **e from compounding and from factorials.** One dollar at 100% a year paid in n instalments,
(1 + 1/n)^n, never exceeds the series 1 + 1 + 1/2! + ⋯ + 1/n! cut at n; as n grows it heads
for e; and e is exactly the endless sum of one over every factorial. -/
theorem compounding_le_series_and_both_reach_e :
    (∀ n : ℕ, (1 + 1 / (n : ℝ)) ^ n ≤ ∑ k ∈ range (n + 1), 1 / (k ! : ℝ)) ∧
    Tendsto (fun n : ℕ => (1 + 1 / (n : ℝ)) ^ n) atTop (𝓝 (Real.exp 1)) ∧
    HasSum (fun k : ℕ => 1 / (k ! : ℝ)) (Real.exp 1) := by
  refine ⟨?_, Real.tendsto_one_add_div_pow_exp 1, ?_⟩
  · intro n
    rcases Nat.eq_zero_or_pos n with rfl | hn
    · simp
    rw [add_comm, add_pow]
    refine Finset.sum_le_sum fun k _ => ?_
    have hn' : (0 : ℝ) < n := by exact_mod_cast hn
    have hd : (n.descFactorial k : ℝ) ≤ (n : ℝ) ^ k := by exact_mod_cast Nat.descFactorial_le_pow n k
    rw [Nat.descFactorial_eq_factorial_mul_choose] at hd
    push_cast at hd
    have hk : (0 : ℝ) < k ! := by exact_mod_cast Nat.factorial_pos k
    rw [one_pow, mul_one, div_pow, one_pow, one_div_mul_eq_div, div_le_div_iff₀ (by positivity) hk]
    linarith
  · have := NormedSpace.expSeries_div_hasSum_exp (1 : ℝ)
    rw [← Real.exp_eq_exp_ℝ] at this
    simpa using this

/-- **1/e and clean draws.** The alternating series 1 − 1 + 1/2! − 1/3! + ⋯ adds up to 1/e. The
share D(n)/n! of draws of n names in which nobody gets their own (derangements) heads for 1/e,
and from n = 1 on, D(n) is n!/e rounded to the nearest whole number. -/
theorem alternating_series_inv_e_and_derangements_round :
    HasSum (fun k : ℕ => (-1 : ℝ) ^ k / (k ! : ℝ)) (Real.exp 1)⁻¹ ∧
    Tendsto (fun n : ℕ => (numDerangements n : ℝ) / (n ! : ℝ)) atTop (𝓝 (Real.exp 1)⁻¹) ∧
    ∀ n : ℕ, 1 ≤ n → (numDerangements n : ℤ) = round ((n ! : ℝ) / Real.exp 1) := by
  refine ⟨?_, ?_, ?_⟩
  · have := NormedSpace.expSeries_div_hasSum_exp (-1 : ℝ)
    rw [← Real.exp_eq_exp_ℝ, Real.exp_neg] at this
    exact this
  · rw [← Real.exp_neg]
    exact numDerangements_tendsto_inv_e
  · intro n hn
    have he := Real.exp_pos 1
    have he2 : 2 < Real.exp 1 := by
      have := Real.add_one_lt_exp (x := 1) one_ne_zero
      linarith
    rcases Nat.lt_or_ge n 2 with h2 | h2
    · obtain rfl : n = 1 := by omega
      symm
      rw [round_eq_iff]
      simp only [numDerangements_one, Nat.cast_zero, Int.cast_zero, Nat.factorial_one, zero_sub,
        zero_add, Set.mem_Ico]
      constructor
      · have : 0 < 1 / Real.exp 1 := by positivity
        linarith
      · rw [div_lt_div_iff₀ he (by norm_num)]
        norm_num
        linarith
    · symm
      rw [round_eq_iff]
      have hb := Real.exp_bound (x := -1) (by simp) (n := n + 1) (by omega)
      rw [← numDerangements_div_factorial_eq, Real.exp_neg] at hb
      simp only [abs_neg, abs_one, one_pow, one_mul] at hb
      have hf : (0 : ℝ) < n ! := by exact_mod_cast Nat.factorial_pos n
      have hfs : ((n + 1)! : ℝ) = (n + 1) * n ! := by push_cast [Nat.factorial_succ]; ring
      have key : |(n ! : ℝ) / Real.exp 1 - numDerangements n| < 1 / 2 := by
        have e1 : (n ! : ℝ) / Real.exp 1 - numDerangements n
            = n ! * ((Real.exp 1)⁻¹ - (numDerangements n : ℝ) / n !) := by
          field_simp
        rw [e1, abs_mul, abs_of_pos hf]
        have hn2 : (2 : ℝ) ≤ n := by exact_mod_cast h2
        calc (n ! : ℝ) * |(Real.exp 1)⁻¹ - (numDerangements n : ℝ) / n !|
            ≤ n ! * (((n + 1).succ : ℕ) / ((n + 1)! * (n + 1 : ℕ) : ℝ)) :=
              mul_le_mul_of_nonneg_left hb hf.le
          _ = (n + 2) / ((n + 1) * (n + 1)) := by
              rw [hfs]; push_cast; field_simp; ring
          _ < 1 / 2 := by
              rw [div_lt_div_iff₀ (by positivity) (by norm_num)]
              nlinarith
      rw [abs_lt] at key
      simp only [Int.cast_natCast, Set.mem_Ico]
      constructor <;> linarith

-- C(1/2, k) for k = 0..3, by the countdown a(a − 1)⋯(a − k + 1)/k!: 1, 1/2, −1/8, 1/16.
example : ((1 : ℚ) / 2) / 1 = 1 / 2 := by norm_num
example : ((1 : ℚ) / 2) * (1 / 2 - 1) / 2 = -1 / 8 := by norm_num
example : ((1 : ℚ) / 2) * (1 / 2 - 1) * (1 / 2 - 2) / 6 = 1 / 16 := by norm_num
-- The next coefficient, C(1/2, 4) = −5/128 (0.0390625 in size, the first piece left out).
example : ((1 : ℚ) / 2) * (1 / 2 - 1) * (1 / 2 - 2) * (1 / 2 - 3) / 24 = -5 / 128 := by norm_num
-- Four pieces for the root of 1.1: 1 + 0.05 − 0.00125 + 0.0000625 = 1.0488125.
example : (1 : ℚ) + 1 / 2 * (1 / 10) + (-1 / 8) * (1 / 10) ^ 2 + 1 / 16 * (1 / 10) ^ 3
    = 10488125 / 10000000 := by norm_num
-- Forgetting the k!: 1 + 0.05 − 0.0025 + 0.000375 = 1.047875.
example : (1 : ℚ) + 1 / 2 * (1 / 10) + (-1 / 4) * (1 / 10) ^ 2 + 3 / 8 * (1 / 10) ^ 3
    = 1047875 / 1000000 := by norm_num
-- Six people draw names in 6! = 720 ways.
example : (6 : ℕ)! = 720 := by decide
-- Clean draws D(n) for n = 4..8: 9, 44, 265, 1854, 14833.
example : numDerangements 4 = 9 := by decide
example : numDerangements 5 = 44 := by decide
example : numDerangements 6 = 265 := by decide
example : numDerangements 7 = 1854 := by decide
example : numDerangements 8 = 14833 := by decide
-- D(6) is 6! times the alternating series cut at 6: 720 − 720 + 360 − 120 + 30 − 6 + 1 = 265.
example : ∑ k ∈ range 7, (-1 : ℚ) ^ k * ((6 ! : ℕ) : ℚ) / (k ! : ℚ) = 265 := by
  simp [Finset.sum_range_succ, Nat.factorial]; norm_num
-- Signs dropped: 720 × (1 + 1 + 1/2! + ⋯ + 1/6!) = 1957 "clean" draws out of 720.
example : ∑ k ∈ range 7, ((6 ! : ℕ) : ℚ) / (k ! : ℚ) = 1957 := by
  simp [Finset.sum_range_succ, Nat.factorial]; norm_num
-- The chart's first rungs: (1 + 1/1)^1 = 2, (1 + 1/2)^2 = 9/4, and the series 1 + 1 + 1/2 = 5/2.
example : (1 + 1 / (1 : ℚ)) ^ 1 = 2 ∧ (1 + 1 / (2 : ℚ)) ^ 2 = 9 / 4 := by norm_num
example : (1 : ℚ) + 1 + 1 / 2 = 5 / 2 := by norm_num

#print axioms binomial_series_hasSum
#print axioms compounding_le_series_and_both_reach_e
#print axioms alternating_series_inv_e_and_derangements_round
