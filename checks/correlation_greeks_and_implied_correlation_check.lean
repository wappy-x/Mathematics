-- Correlation Greeks and implied correlation: an index's variance is its members' weighted variances plus a cross term linear in correlation, a quoted index variance implies exactly one correlation in [-1, 1] precisely when it lies between the full-anticorrelation and full-correlation levels, and best-of plus worst-of call payoffs equal two ordinary call payoffs.
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Moments.Covariance

open MeasureTheory ProbabilityTheory

/-- The variance of a weighted sum (the index's variance). If shares numbered by a finite set
have returns `X i` with finite variance, each share's variance is `σ i ^ 2`, and every pair of
different shares has the same correlation `ρ`, so that their covariance is `ρ * σ i * σ j`, then
the variance of the index return `∑ i, w i * X i` is the shares' own variances scaled by their
weights squared, plus `ρ` times the cross sum `∑_{i ≠ j} w i * w j * σ i * σ j`.
With two shares this is `w₁²σ₁² + w₂²σ₂² + 2 w₁ w₂ ρ σ₁ σ₂`. -/
theorem index_variance_eq_own_terms_add_correlation_cross_term
    {Ω ι : Type*} [MeasurableSpace Ω] {μ : Measure Ω} [IsProbabilityMeasure μ]
    [Fintype ι] [DecidableEq ι]
    (X : ι → Ω → ℝ) (hX : ∀ i, MemLp (X i) 2 μ) (w σ : ι → ℝ) (ρ : ℝ)
    (hvar : ∀ i, Var[X i; μ] = σ i ^ 2)
    (hcov : ∀ i j, i ≠ j → cov[X i, X j; μ] = ρ * σ i * σ j) :
    Var[fun ω => ∑ i, w i * X i ω; μ] =
      ∑ i, w i ^ 2 * σ i ^ 2 + ρ * ∑ i, ∑ j ∈ Finset.univ.erase i, w i * w j * σ i * σ j := by
  have hY : ∀ i, MemLp (fun ω => w i * X i ω) 2 μ := fun i => (hX i).const_mul (w i)
  rw [variance_fun_sum (X := fun i ω => w i * X i ω) hY]
  simp only [covariance_const_mul_left, covariance_const_mul_right]
  rw [Finset.mul_sum, ← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [← Finset.add_sum_erase _ _ (Finset.mem_univ i), Finset.mul_sum]
  rw [covariance_self (hX i).aemeasurable, hvar i]
  congr 1
  · ring
  · refine Finset.sum_congr rfl fun j hj => ?_
    rw [hcov i j (Finset.ne_of_mem_erase hj).symm]
    ring

/-- Implied correlation exists and is unique inside the bounds. With positive weights and
positive volatilities for two shares, a quoted index variance `v` is produced by exactly one
correlation `ρ` between −1 and 1 if and only if `v` lies between `(w₁σ₁ − w₂σ₂)²` and
`(w₁σ₁ + w₂σ₂)²`; and any correlation that produces `v` is
`ρ_impl = (v − w₁²σ₁² − w₂²σ₂²) / (2 w₁ w₂ σ₁ σ₂)`. -/
theorem implied_correlation_exists_unique_iff_between_bounds
    (w₁ w₂ σ₁ σ₂ v : ℝ) (hw₁ : 0 < w₁) (hw₂ : 0 < w₂) (hσ₁ : 0 < σ₁) (hσ₂ : 0 < σ₂) :
    ((∃! ρ : ℝ, ρ ∈ Set.Icc (-1 : ℝ) 1 ∧
        v = w₁ ^ 2 * σ₁ ^ 2 + w₂ ^ 2 * σ₂ ^ 2 + 2 * w₁ * w₂ * ρ * σ₁ * σ₂) ↔
      v ∈ Set.Icc ((w₁ * σ₁ - w₂ * σ₂) ^ 2) ((w₁ * σ₁ + w₂ * σ₂) ^ 2)) ∧
    ∀ ρ : ℝ, v = w₁ ^ 2 * σ₁ ^ 2 + w₂ ^ 2 * σ₂ ^ 2 + 2 * w₁ * w₂ * ρ * σ₁ * σ₂ →
      ρ = (v - w₁ ^ 2 * σ₁ ^ 2 - w₂ ^ 2 * σ₂ ^ 2) / (2 * w₁ * w₂ * σ₁ * σ₂) := by
  have hc : 0 < 2 * w₁ * w₂ * σ₁ * σ₂ := by positivity
  have key : ∀ ρ : ℝ, v = w₁ ^ 2 * σ₁ ^ 2 + w₂ ^ 2 * σ₂ ^ 2 + 2 * w₁ * w₂ * ρ * σ₁ * σ₂ →
      ρ = (v - w₁ ^ 2 * σ₁ ^ 2 - w₂ ^ 2 * σ₂ ^ 2) / (2 * w₁ * w₂ * σ₁ * σ₂) := by
    intro ρ h
    rw [eq_div_iff hc.ne', h]
    ring
  refine ⟨⟨fun ⟨ρ, ⟨⟨h1, h2⟩, hv⟩, _⟩ => ?_, fun ⟨h1, h2⟩ => ?_⟩, key⟩
  · have a : 0 ≤ (ρ + 1) * (2 * w₁ * w₂ * σ₁ * σ₂) := mul_nonneg (by linarith) hc.le
    have b : 0 ≤ (1 - ρ) * (2 * w₁ * w₂ * σ₁ * σ₂) := mul_nonneg (by linarith) hc.le
    constructor <;> nlinarith
  · set ρ := (v - w₁ ^ 2 * σ₁ ^ 2 - w₂ ^ 2 * σ₂ ^ 2) / (2 * w₁ * w₂ * σ₁ * σ₂) with hρ
    have hv : v = w₁ ^ 2 * σ₁ ^ 2 + w₂ ^ 2 * σ₂ ^ 2 + 2 * w₁ * w₂ * ρ * σ₁ * σ₂ := by
      rw [hρ]; field_simp; ring
    refine ⟨ρ, ⟨⟨?_, ?_⟩, hv⟩, fun r ⟨_, hr⟩ => key r hr⟩
    · rw [hρ, le_div_iff₀ hc]; nlinarith
    · rw [hρ, div_le_iff₀ hc]; nlinarith

/-- Best-of and worst-of cancel. For any two finishing prices and any strike, the best-of call
payoff plus the worst-of call payoff equals the sum of the two ordinary call payoffs, so
best-of plus worst-of is two ordinary calls, which do not depend on correlation. -/
theorem best_of_call_add_worst_of_call_eq_two_calls (a b K : ℝ) :
    max (max a b - K) 0 + max (min a b - K) 0 = max (a - K) 0 + max (b - K) 0 := by
  rcases le_total a b with h | h
  · rw [max_eq_right h, min_eq_left h]; ring
  · rw [max_eq_left h, min_eq_right h]

-- House pair: weights 1/2, volatilities 1/5, correlation 1/2.
-- Own terms 1/100 each, cross term 1/100, index variance 3/100.
example : ((1 : ℚ) / 2) ^ 2 * (1 / 5) ^ 2 = 1 / 100 := by norm_num
example : 2 * ((1 : ℚ) / 2) * (1 / 2) * (1 / 2) * (1 / 5) * (1 / 5) = 1 / 100 := by norm_num
example : ((1 : ℚ) / 2) ^ 2 * (1 / 5) ^ 2 + (1 / 2) ^ 2 * (1 / 5) ^ 2
    + 2 * (1 / 2) * (1 / 2) * (1 / 2) * (1 / 5) * (1 / 5) = 3 / 100 := by norm_num
-- Bounds: variance 2/100 at correlation 0, and (1/5)^2 at correlation 1 (index volatility 20 percent).
example : ((1 : ℚ) / 2) ^ 2 * (1 / 5) ^ 2 + (1 / 2) ^ 2 * (1 / 5) ^ 2 = 2 / 100 := by norm_num
example : ((1 : ℚ) / 2 * (1 / 5) + 1 / 2 * (1 / 5)) ^ 2 = (1 / 5) ^ 2 := by norm_num
-- An 18 percent quote: variance 324/10000, less own terms 124/10000, over the cross term
-- at correlation 1 (2/100), gives implied correlation 62/100.
example : ((18 : ℚ) / 100) ^ 2 = 324 / 10000 := by norm_num
example : ((18 : ℚ) / 100) ^ 2 - 2 / 100 = 124 / 10000 := by norm_num
example : 2 * ((1 : ℚ) / 2) * (1 / 2) * (1 / 5) * (1 / 5) = 2 / 100 := by norm_num
example : (((18 : ℚ) / 100) ^ 2 - (1 / 2) ^ 2 * (1 / 5) ^ 2 - (1 / 2) ^ 2 * (1 / 5) ^ 2)
    / (2 * (1 / 2) * (1 / 2) * (1 / 5) * (1 / 5)) = 62 / 100 := by norm_num
-- A 25 percent quote lies above the 20 percent ceiling: no implied correlation.
example : ((1 : ℚ) / 2 * (1 / 5) + 1 / 2 * (1 / 5)) ^ 2 < ((25 : ℚ) / 100) ^ 2 := by norm_num
-- Quotes of 16 and 14 percent imply correlations 28/100 and -2/100.
example : (((16 : ℚ) / 100) ^ 2 - 2 / 100) / (2 / 100) = 28 / 100 := by norm_num
example : (((14 : ℚ) / 100) ^ 2 - 2 / 100) / (2 / 100) = -2 / 100 := by norm_num
-- Fifty equal names: at average correlation -1/(50-1) the index variance factor
-- 1/n + (1 - 1/n) * ρ is exactly zero, the floor.
example : (1 : ℚ) / 50 + (1 - 1 / 50) * (-1 / (50 - 1)) = 0 := by norm_num
-- Bridge factor σ₁ σ₂ T S₁ S₂ for the house pair.
example : ((1 : ℚ) / 5) * (1 / 5) * 1 * 100 * 100 = 400 := by norm_num
-- Best-of plus worst-of on finishing prices 120 and 90, strike 100: 20 + 0 on each side.
example : max (max (120 : ℤ) 90 - 100) 0 + max (min (120 : ℤ) 90 - 100) 0
    = max ((120 : ℤ) - 100) 0 + max ((90 : ℤ) - 100) 0 := by decide
example : max (max (120 : ℤ) 90 - 100) 0 + max (min (120 : ℤ) 90 - 100) 0 = 20 := by decide

#print axioms index_variance_eq_own_terms_add_correlation_cross_term
#print axioms implied_correlation_exists_unique_iff_between_bounds
#print axioms best_of_call_add_worst_of_call_eq_two_calls
