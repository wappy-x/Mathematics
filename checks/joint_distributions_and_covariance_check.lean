-- Two variables at once: for two readings X and Y of the same random outcome with finite variances, Var(aX + bY) = a² Var(X) + b² Var(Y) + 2ab Cov(X, Y), the covariance equals E[XY] − E[X]E[Y], and the correlation lies between −1 and +1.
import Mathlib.Probability.Moments.Variance
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory

/-- The variance of a weighted sum. Let X and Y be two real readings of the same random outcome
(two real-valued functions on one probability space), each with a finite variance (finite average
square), and let a and b be fixed numbers. Then the spread of aX + bY is each spread scaled by its
weight squared, plus the cross term built from the covariance:
Var(aX + bY) = a² Var(X) + b² Var(Y) + 2ab Cov(X, Y). -/
theorem variance_weighted_sum_eq {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (X Y : Ω → ℝ) (hX : MemLp X 2 μ) (hY : MemLp Y 2 μ) (a b : ℝ) :
    variance (fun ω => a * X ω + b * Y ω) μ
      = a ^ 2 * variance X μ + b ^ 2 * variance Y μ + 2 * a * b * covariance X Y μ := by
  rw [variance_fun_add (hX.const_mul a) (hY.const_mul b), variance_const_mul, variance_const_mul,
    covariance_const_mul_left, covariance_const_mul_right]
  ring

/-- The covariance shortcut. For two readings X and Y of the same random outcome with finite
variances, the average product of their distances from their own averages equals the average of
the product minus the product of the averages: E[(X − E[X])(Y − E[Y])] = E[XY] − E[X] E[Y]. -/
theorem mean_centered_product_eq_mean_mul_sub {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (X Y : Ω → ℝ) (hX : MemLp X 2 μ) (hY : MemLp Y 2 μ) :
    ∫ ω, (X ω - ∫ ω', X ω' ∂μ) * (Y ω - ∫ ω', Y ω' ∂μ) ∂μ
      = (∫ ω, X ω * Y ω ∂μ) - (∫ ω, X ω ∂μ) * (∫ ω, Y ω ∂μ) := by
  have h := covariance_eq_sub hX hY
  simp only [covariance, Pi.mul_apply] at h
  exact h

/-- Correlation cannot pass ±1. For two readings X and Y of the same random outcome with finite
variances and both standard deviations above zero, the correlation
ρ = Cov(X, Y) / (σ_X σ_Y), with σ the square root of the variance, satisfies −1 ≤ ρ ≤ 1. -/
theorem correlation_mem_Icc_neg_one_one {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (X Y : Ω → ℝ) (hX : MemLp X 2 μ) (hY : MemLp Y 2 μ)
    (hσX : 0 < Real.sqrt (variance X μ)) (hσY : 0 < Real.sqrt (variance Y μ)) :
    -1 ≤ covariance X Y μ / (Real.sqrt (variance X μ) * Real.sqrt (variance Y μ)) ∧
    covariance X Y μ / (Real.sqrt (variance X μ) * Real.sqrt (variance Y μ)) ≤ 1 := by
  have hvX : 0 < variance X μ := Real.sqrt_pos.mp hσX
  have hvY : 0 ≤ variance Y μ := variance_nonneg Y μ
  set c := covariance X Y μ with hc
  have key : ∀ t : ℝ, 0 ≤ t ^ 2 * variance X μ + variance Y μ + 2 * t * c := by
    intro t
    have h := variance_weighted_sum_eq μ X Y hX hY t 1
    have h0 := variance_nonneg (fun ω => t * X ω + 1 * Y ω) μ
    rw [h] at h0
    linarith
  have hsq : c ^ 2 ≤ variance X μ * variance Y μ := by
    have h := key (-c / variance X μ)
    have e : (-c / variance X μ) ^ 2 * variance X μ + variance Y μ + 2 * (-c / variance X μ) * c
        = (variance X μ * variance Y μ - c ^ 2) / variance X μ := by
      field_simp
      ring
    rw [e] at h
    have := (div_nonneg_iff.mp h)
    rcases this with ⟨h1, _⟩ | ⟨_, h2⟩
    · linarith
    · linarith
  have habs : |c| ≤ Real.sqrt (variance X μ) * Real.sqrt (variance Y μ) := by
    rw [← Real.sqrt_mul hvX.le]
    exact Real.abs_le_sqrt hsq
  have hpos : 0 < Real.sqrt (variance X μ) * Real.sqrt (variance Y μ) := mul_pos hσX hσY
  have hab := abs_le.mp habs
  constructor
  · rw [le_div_iff₀ hpos]; linarith
  · rw [div_le_iff₀ hpos]; linarith

/-! The card's worked numbers: the 100 days, rows dry (X = 0) and wet (X = 1),
columns 0, 1, 2, 3 umbrellas sold. -/

-- The marginals: row totals 60 dry and 40 wet days; column totals 34, 28, 20, 18; 100 days in all.
example : 30 + 20 + 8 + 2 = 60 ∧ 4 + 8 + 12 + 16 = 40 ∧
    30 + 4 = 34 ∧ 20 + 8 = 28 ∧ 8 + 12 = 20 ∧ 2 + 16 = 18 ∧ 60 + 40 = 100 := by decide
-- E[X] = 40/100 and Var(X) = 0.4 × (1 − 0.4) = 0.24.
example : (40 / 100 : ℚ) * (1 - 40 / 100) = 24 / 100 := by norm_num
-- E[Y] = (1 × 28 + 2 × 20 + 3 × 18)/100 = 1.22 and E[Y²] = (1 × 28 + 4 × 20 + 9 × 18)/100 = 2.70.
example : ((1 * 28 + 2 * 20 + 3 * 18) / 100 : ℚ) = 122 / 100 := by norm_num
example : ((1 * 28 + 4 * 20 + 9 * 18) / 100 : ℚ) = 270 / 100 := by norm_num
-- Var(Y) = 2.7000 − 1.4884 = 1.2116.
example : (270 / 100 : ℚ) - (122 / 100) ^ 2 = 12116 / 10000 := by norm_num
-- E[XY], wet days only: (1 × 8 + 2 × 12 + 3 × 16)/100 = 0.80.
example : ((1 * 8 + 2 * 12 + 3 * 16) / 100 : ℚ) = 80 / 100 := by norm_num
-- The covariance shortcut on the stall: 0.8000 − 0.4 × 1.22 = 0.8000 − 0.4880 = 0.3120.
example : (40 / 100 : ℚ) * (122 / 100) = 4880 / 10000 ∧
    (80 / 100 : ℚ) - 4880 / 10000 = 3120 / 10000 := by norm_num
-- The same covariance from the centred products over all 8 cells, scaled by 100:
-- Σ count × (100x − 40)(100y − 122) = 100³ × 0.312.
example : (30 * (0 - 40) * (0 - 122) + 20 * (0 - 40) * (100 - 122) + 8 * (0 - 40) * (200 - 122)
    + 2 * (0 - 40) * (300 - 122) + 4 * (100 - 40) * (0 - 122) + 8 * (100 - 40) * (100 - 122)
    + 12 * (100 - 40) * (200 - 122) + 16 * (100 - 40) * (300 - 122) : ℤ) = 312000 := by decide
-- The yes-or-no road: dry-day average 42/60 = 0.7, wet-day average 80/40 = 2.0,
-- and Var(X) × gap = 0.24 × 1.3 = 0.312.
example : ((20 + 2 * 8 + 3 * 2) / 60 : ℚ) = 7 / 10 ∧ ((8 + 2 * 12 + 3 * 16) / 40 : ℚ) = 2 ∧
    (24 / 100 : ℚ) * (2 - 7 / 10) = 312 / 1000 := by norm_num
-- Profit variance by the theorem (b = 8, a = −5):
-- 64 × 1.2116 + 25 × 0.24 + 2 × 8 × (−5) × 0.312 = 77.5424 + 6.0000 − 24.9600 = 58.5824.
example : (64 : ℚ) * (12116 / 10000) = 775424 / 10000 ∧ (25 : ℚ) * (24 / 100) = 6 ∧
    (2 : ℚ) * 8 * (-5) * (312 / 1000) = -2496 / 100 ∧
    (775424 / 10000 : ℚ) + 6 - 2496 / 100 = 585824 / 10000 := by norm_num
-- Profit by brute force over the 100 days: values −5, 0, 3, 8, 11, 16, 19, 24 on 4, 30, 8, 20, 12,
-- 8, 16, 2 days; total $776 (mean $7.76), and Σ days × (100 × profit − 776)² = 100³ × 58.5824.
example : (4 * (-5) + 30 * 0 + 8 * 3 + 20 * 8 + 12 * 11 + 8 * 16 + 16 * 19 + 2 * 24 : ℤ) = 776 := by
  decide
example : (4 * (-500 - 776) ^ 2 + 30 * (0 - 776) ^ 2 + 8 * (300 - 776) ^ 2 + 20 * (800 - 776) ^ 2
    + 12 * (1100 - 776) ^ 2 + 8 * (1600 - 776) ^ 2 + 16 * (1900 - 776) ^ 2
    + 2 * (2400 - 776) ^ 2 : ℤ) = 58582400 := by decide
-- Mistake 1, cross term dropped: 77.5424 + 6.0000 = 83.5424.
example : (775424 / 10000 : ℚ) + 6 = 835424 / 10000 := by norm_num
-- Mistake 3, the wind W = −1, 0, +1, each a third: Cov(W, W²) = E[W³] − E[W] E[W²] = 0,
-- yet P(calm and upright) = 1/3, not (1/3) × (1/3) = 1/9.
example : ((-1) ^ 3 + 0 ^ 3 + 1 ^ 3 : ℚ) / 3
    - ((-1 + 0 + 1) / 3) * (((-1) ^ 2 + 0 ^ 2 + 1 ^ 2) / 3) = 0 := by norm_num
example : (1 / 3 : ℚ) * (1 / 3) = 1 / 9 ∧ (1 / 3 : ℚ) ≠ 1 / 9 := by norm_num
-- Mistake 4, umbrellas counted in dozens: the covariance becomes 0.312 / 12 = 0.026.
example : (312 / 1000 : ℚ) / 12 = 26 / 1000 := by norm_num

#print axioms variance_weighted_sum_eq
#print axioms mean_centered_product_eq_mean_mul_sub
#print axioms correlation_mem_Icc_neg_one_one
