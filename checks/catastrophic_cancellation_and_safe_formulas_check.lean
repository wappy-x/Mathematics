-- Cancellation: a subtraction multiplies its inputs' relative error by at most kappa = (|u| + |v|) / |u - v|, and the safe quadratic and Welford's update are exact rewrites of the formulas they replace.
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.GCongr

/-! The two numbers being subtracted are `u` and `v`. Their stored values are
`u * (1 + δ₁)` and `v * (1 + δ₂)`, where the relative errors `δ₁` and `δ₂` are each at most
`δ` in size. The condition number of the subtraction is `κ = (|u| + |v|) / |u - v|`. -/

/-- The magnification is at most kappa: if the inputs `u` and `v` (with `u ≠ v`) carry relative
errors `δ₁` and `δ₂`, each at most `δ` in size, then the relative error of the exact difference of
the stored values is at most `κ * δ`, where `κ = (|u| + |v|) / |u - v|`. -/
theorem subtraction_relative_error_le_kappa (u v δ δ₁ δ₂ : ℝ) (huv : u ≠ v)
    (h₁ : |δ₁| ≤ δ) (h₂ : |δ₂| ≤ δ) :
    |(u * (1 + δ₁) - v * (1 + δ₂)) - (u - v)| / |u - v| ≤ (|u| + |v|) / |u - v| * δ := by
  have hpos : 0 < |u - v| := abs_pos.mpr (sub_ne_zero.mpr huv)
  have hδ : 0 ≤ δ := le_trans (abs_nonneg _) h₁
  have heq : (u * (1 + δ₁) - v * (1 + δ₂)) - (u - v) = u * δ₁ + (-v) * δ₂ := by ring
  rw [heq, div_mul_eq_mul_div]
  apply div_le_div_of_nonneg_right _ hpos.le
  calc |u * δ₁ + (-v) * δ₂| ≤ |u * δ₁| + |(-v) * δ₂| := abs_add_le _ _
    _ = |u| * |δ₁| + |v| * |δ₂| := by rw [abs_mul, abs_mul, abs_neg]
    _ ≤ |u| * δ + |v| * δ := by
        gcongr
    _ = (|u| + |v|) * δ := by ring

/-- The safe quadratic: for `a x² + b x + c` with `a ≠ 0` and real roots (`b² - 4ac ≥ 0`), let
`q = -(b + sign(b) √(b² - 4ac)) / 2`, adding the square root to `b` with `b`'s own sign
(sign taken as `+` when `b = 0`). Then the roots are exactly `x₁ = q / a` and `x₂ = c / q`:
the quadratic factors as `a (x - q/a) (x - c/q)` for every `x`. -/
theorem safe_quadratic_roots (a b c : ℝ) (ha : a ≠ 0) (hD : 0 ≤ b ^ 2 - 4 * a * c) :
    let q := if 0 ≤ b then -(b + Real.sqrt (b ^ 2 - 4 * a * c)) / 2
             else -(b - Real.sqrt (b ^ 2 - 4 * a * c)) / 2
    ∀ x : ℝ, a * x ^ 2 + b * x + c = a * (x - q / a) * (x - c / q) := by
  intro q x
  have hs : Real.sqrt (b ^ 2 - 4 * a * c) ^ 2 = b ^ 2 - 4 * a * c := Real.sq_sqrt hD
  have hs0 : 0 ≤ Real.sqrt (b ^ 2 - 4 * a * c) := Real.sqrt_nonneg _
  have hq : q ^ 2 + b * q + a * c = 0 := by
    simp only [q]
    split_ifs <;> linear_combination (1 / 4 : ℝ) * hs
  by_cases hq0 : q = 0
  · have hc : c = 0 := by
      rw [hq0] at hq
      have : a * c = 0 := by linarith
      rcases mul_eq_zero.mp this with h | h
      · exact absurd h ha
      · exact h
    have hb : b = 0 := by
      simp only [q] at hq0
      split_ifs at hq0 with hb0
      · linarith
      · nlinarith
    rw [hq0, hc, hb]
    simp
    ring
  · field_simp
    linear_combination x * hq

/-- The running mean of the readings `x 1, ..., x k`: `μ_k = (x 1 + ... + x k) / k`. -/
noncomputable def runningMean (x : ℕ → ℝ) (k : ℕ) : ℝ :=
  (∑ i ∈ Finset.Icc 1 k, x i) / k

/-- The running sum of squared distances from the mean: `M_k = Σ_{i ≤ k} (x i - μ_k)²`.
The variance of the first `n` readings is `M_n / n`. -/
noncomputable def runningSqDist (x : ℕ → ℝ) (k : ℕ) : ℝ :=
  ∑ i ∈ Finset.Icc 1 k, (x i - runningMean x k) ^ 2

/-- Welford's update: for every list of readings and every `k ≥ 1`, the running mean and the
running sum of squared distances obey
`μ_k = μ_{k-1} + (x_k - μ_{k-1}) / k` and `M_k = M_{k-1} + (x_k - μ_{k-1}) (x_k - μ_k)`
(written here with `k + 1` in place of `k`). -/
theorem welford_update (x : ℕ → ℝ) (k : ℕ) :
    runningMean x (k + 1) = runningMean x k + (x (k + 1) - runningMean x k) / (k + 1) ∧
    runningSqDist x (k + 1) = runningSqDist x k +
      (x (k + 1) - runningMean x k) * (x (k + 1) - runningMean x (k + 1)) := by
  have hexp : ∀ (n : ℕ) (m : ℝ), ∑ i ∈ Finset.Icc 1 n, (x i - m) ^ 2 =
      ∑ i ∈ Finset.Icc 1 n, x i ^ 2 - 2 * m * ∑ i ∈ Finset.Icc 1 n, x i + n * m ^ 2 := by
    intro n m
    have h1 : ∀ i ∈ Finset.Icc 1 n, (x i - m) ^ 2 = x i ^ 2 - 2 * m * x i + m ^ 2 := by
      intro i _; ring
    rw [Finset.sum_congr rfl h1, Finset.sum_add_distrib, Finset.sum_sub_distrib,
      ← Finset.mul_sum, Finset.sum_const, Nat.card_Icc, nsmul_eq_mul]
    simp
  have hS : ∑ i ∈ Finset.Icc 1 (k + 1), x i = ∑ i ∈ Finset.Icc 1 k, x i + x (k + 1) :=
    Finset.sum_Icc_succ_top (by omega) _
  have hQ : ∑ i ∈ Finset.Icc 1 (k + 1), x i ^ 2 = ∑ i ∈ Finset.Icc 1 k, x i ^ 2 + x (k + 1) ^ 2 :=
    Finset.sum_Icc_succ_top (by omega) _
  have hk1 : ((k + 1 : ℕ) : ℝ) ≠ 0 := by positivity
  unfold runningSqDist
  rw [hexp (k + 1), hexp k]
  unfold runningMean
  rw [hS, hQ]
  rcases Nat.eq_zero_or_pos k with rfl | hk
  · simp
    ring
  · have hk0 : (k : ℝ) ≠ 0 := by positivity
    push_cast at hk1 ⊢
    constructor
    · field_simp
      ring
    · field_simp
      ring

/-! The card's exact worked numbers. -/

-- The discriminant of x² - 100000000x + 1: 10^16 - 4 = 9999999999999996.
example : (100000000 : ℤ) ^ 2 - 4 * 1 * 1 = 9999999999999996 := by norm_num
-- The product of the roots is c/a = 1, so the small root is 1/q; at q = 10^8 it is 1/100000000.
example : (1 : ℚ) / 100000000 * 100000000 = 1 := by norm_num
-- Kappa for the quadratic's subtraction: (10^8 + 10^8) / (2 × 10^-8) = 10^16.
example : ((10 : ℚ) ^ 8 + 10 ^ 8) / (2 / 10 ^ 8) = 10 ^ 16 := by norm_num
-- The four weighings, in mg: mean 1000000010.
example : ((1000000004 + 1000000007 + 1000000013 + 1000000016 : ℚ)) / 4 = 1000000010 := by
  norm_num
-- Their distances from the mean are 6, 3, 3 and 6, and the true variance is 22.5 = 45/2 mg².
example : ((1000000004 - 1000000010 : ℚ) ^ 2 + (1000000007 - 1000000010) ^ 2 +
    (1000000013 - 1000000010) ^ 2 + (1000000016 - 1000000010) ^ 2) / 4 = 45 / 2 := by norm_num
-- In exact arithmetic the shortcut (mean of squares minus squared mean) gives the same 45/2.
example : ((1000000004 : ℚ) ^ 2 + 1000000007 ^ 2 + 1000000013 ^ 2 + 1000000016 ^ 2) / 4 -
    1000000010 ^ 2 = 45 / 2 := by norm_num
-- Near 10^18 stored numbers are 128 apart: 2^59 ≤ 10^18 < 2^60, and 2^(59 - 52) = 128.
example : (2 : ℕ) ^ 59 ≤ 10 ^ 18 ∧ (10 : ℕ) ^ 18 < 2 ^ 60 ∧ (2 : ℕ) ^ (59 - 52) = 128 := by
  norm_num
-- The stored 0.1 is 3602879701896397 / 2^55; a million of them total exactly
-- 100000 + 200000 / 2^55 (that is, 100000 + 5.551e-12).
example : (1000000 : ℚ) * (3602879701896397 / 2 ^ 55) = 100000 + 200000 / 2 ^ 55 := by norm_num

#print axioms subtraction_relative_error_le_kappa
#print axioms safe_quadratic_roots
#print axioms welford_update
