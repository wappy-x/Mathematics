-- Variance: for any random variable with a finite average square, the variance equals the average square minus the square of the mean, rescaling by aX + b multiplies the variance by a² and the standard deviation by |a|, and the average square is at least the squared mean, with equality only for a constant.
import Mathlib.Probability.Moments.Variance

open MeasureTheory ProbabilityTheory

/-- The shortcut formula. Let X be a random variable (a real-valued measurable function on a
probability space) whose average square E[X²] is finite. Then its variance, the average squared
distance from the mean μ = E[X], equals E[(X − μ)²], and it also equals the average of the square
minus the square of the average: Var(X) = E[X²] − μ². -/
theorem variance_eq_mean_sq_sub_sq_mean {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (X : Ω → ℝ) (hX : MemLp X 2 μ) :
    variance X μ = ∫ ω, (X ω - ∫ ω', X ω' ∂μ) ^ 2 ∂μ ∧
    variance X μ = (∫ ω, X ω ^ 2 ∂μ) - (∫ ω, X ω ∂μ) ^ 2 := by
  refine ⟨variance_eq_integral hX.aemeasurable, ?_⟩
  rw [variance_eq_sub hX]
  rfl

/-- The rescaling rule. Let X have finite E[X²], and let a and b be fixed numbers. Then
Var(aX + b) = a² Var(X), and the standard deviation, the square root of the variance, obeys
σ(aX + b) = |a| σ(X): the shift b changes nothing, and the stretch a enters squared in the
variance and as its size |a| in the standard deviation. -/
theorem variance_affine_and_std_dev_affine {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (X : Ω → ℝ) (hX : MemLp X 2 μ) (a b : ℝ) :
    variance (fun ω => a * X ω + b) μ = a ^ 2 * variance X μ ∧
    Real.sqrt (variance (fun ω => a * X ω + b) μ) = |a| * Real.sqrt (variance X μ) := by
  have h1 : variance (fun ω => a * X ω + b) μ = a ^ 2 * variance X μ := by
    rw [variance_add_const (hX.aestronglyMeasurable.const_mul a) b, variance_const_mul]
  refine ⟨h1, ?_⟩
  rw [h1, Real.sqrt_mul (sq_nonneg a), Real.sqrt_sq_eq_abs]

/-- Since a variance is never negative, the shortcut shows that for X with finite E[X²] the
average of the square is at least the square of the average, E[X²] ≥ μ², with equality exactly
when X never moves: X equals its mean μ with probability 1. -/
theorem sq_mean_le_mean_sq_eq_iff_const {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (X : Ω → ℝ) (hX : MemLp X 2 μ) :
    (∫ ω, X ω ∂μ) ^ 2 ≤ ∫ ω, X ω ^ 2 ∂μ ∧
    ((∫ ω, X ω ^ 2 ∂μ) = (∫ ω, X ω ∂μ) ^ 2 ↔ ∀ᵐ ω ∂μ, X ω = ∫ ω', X ω' ∂μ) := by
  have hv := variance_eq_sub hX
  have hv' : variance X μ = (∫ ω, X ω ^ 2 ∂μ) - (∫ ω, X ω ∂μ) ^ 2 := by rw [hv]; rfl
  have hn := variance_nonneg X μ
  refine ⟨by linarith, ?_⟩
  constructor
  · intro h
    exact ae_eq_integral_of_variance_eq_zero hX (by linarith)
  · intro h
    have h0 : variance X μ = 0 := by
      rw [variance_eq_integral hX.aemeasurable]
      apply integral_eq_zero_of_ae
      filter_upwards [h] with ω hω
      simp [hω]
    linarith

-- The raffle ticket: $0 with chance 99/100, $100 with chance 1/100.
-- Its mean is $1.
example : (99 / 100 : ℚ) * 0 + 1 / 100 * 100 = 1 := by norm_num
-- Signed distances from the mean cancel: 0.99 × (0 − 1) + 0.01 × (100 − 1) = 0.
example : (99 / 100 : ℚ) * (0 - 1) + 1 / 100 * (100 - 1) = 0 := by norm_num
-- The two shares of the variance (the chart's bars): 99/100 and 9801/100 (0.99 and 98.01).
example : (99 / 100 : ℚ) * (0 - 1) ^ 2 = 99 / 100 := by norm_num
example : (1 / 100 : ℚ) * (100 - 1) ^ 2 = 9801 / 100 := by norm_num
-- Variance by the definition: 99 square dollars.
example : (99 / 100 : ℚ) * (0 - 1) ^ 2 + 1 / 100 * (100 - 1) ^ 2 = 99 := by norm_num
-- E[X²] = 100, and the shortcut 100 − 1² gives 99 again.
example : (99 / 100 : ℚ) * 0 ^ 2 + 1 / 100 * 100 ^ 2 = 100 := by norm_num
example : (100 : ℚ) - 1 ^ 2 = 99 := by norm_num
-- The whole-number count over 100 tickets, ticket 37 the winner: total payout 100, and
-- the sum of (100 × payout − total)² is 99 × 100³, so the variance is exactly 99.
example : (∑ t ∈ Finset.range 100, (if t = 37 then (100 : ℤ) else 0)) = 100 := by norm_num [Finset.sum_range_succ]
example : (∑ t ∈ Finset.range 100, (100 * (if t = 37 then (100 : ℤ) else 0) - 100) ^ 2)
    = 99 * 100 ^ 3 := by norm_num [Finset.sum_range_succ]
-- The yes-or-no road: p(1 − p) = 99/10000 for p = 1/100, and 100² times it is 99.
example : (1 / 100 : ℚ) * (1 - 1 / 100) = 99 / 10000 := by norm_num
example : (100 : ℚ) ^ 2 * ((1 / 100) * (1 - 1 / 100)) = 99 := by norm_num
-- Rescaled tickets: a² × 99 for a = 1, −1, 2, 100.
example : (1 : ℚ) ^ 2 * 99 = 99 := by norm_num
example : (-1 : ℚ) ^ 2 * 99 = 99 := by norm_num
example : (2 : ℚ) ^ 2 * 99 = 396 := by norm_num
example : (100 : ℚ) ^ 2 * 99 = 990000 := by norm_num
-- Rescaled means a × 1 + b: net of a $2 price −1, organiser's side 1, doubled prize 2.
example : (1 : ℚ) * 1 + (-2) = -1 := by norm_num
example : (-1 : ℚ) * 1 + 2 = 1 := by norm_num
example : (2 : ℚ) * 1 + 0 = 2 := by norm_num
-- The four mistakes: 2 × 99 = 198, 4 × 100 − 2 = 398, −99 + 2 = −97 (all wrong answers).
example : (2 : ℚ) * 99 = 198 := by norm_num
example : (4 : ℚ) * 100 - 2 * 1 = 398 := by norm_num
example : -(99 : ℚ) + 2 = -97 := by norm_num
-- Mean absolute deviation: 99/100 × 1 + 1/100 × 99 = 198/100 ($1.98).
example : (99 / 100 : ℚ) * |0 - 1| + 1 / 100 * |100 - 1| = 198 / 100 := by norm_num
-- Try changing: a $1,000 prize at chance 1/1000 has mean 1 and variance 999;
-- a $2 prize at chance 1/2 has mean 1 and variance 1.
example : (999 / 1000 : ℚ) * 0 + 1 / 1000 * 1000 = 1 := by norm_num
example : (999 / 1000 : ℚ) * (0 - 1) ^ 2 + 1 / 1000 * (1000 - 1) ^ 2 = 999 := by norm_num
example : (1 / 2 : ℚ) * (0 - 1) ^ 2 + 1 / 2 * (2 - 1) ^ 2 = 1 := by norm_num

#print axioms variance_eq_mean_sq_sub_sq_mean
#print axioms variance_affine_and_std_dev_affine
#print axioms sq_mean_le_mean_sq_eq_iff_const
