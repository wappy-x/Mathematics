-- Markov and Chebyshev: a never-negative random variable with a finite mean reaches a positive threshold a with chance at most its mean over a, and a random variable with a finite variance lands at least ε from its mean with chance at most its variance over ε², or at least k standard deviations away with chance at most 1/k².
import Mathlib.Probability.Moments.Variance

open MeasureTheory ProbabilityTheory

/-- **Markov's inequality.** Let X be a random variable on a probability space that is never
negative and has a finite mean E[X]. Then for every positive threshold a, the chance that X
reaches at least a is at most the mean divided by a: P(X ≥ a) ≤ E[X] / a. -/
theorem markov_inequality {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (X : Ω → ℝ) (hX_nonneg : ∀ ω, 0 ≤ X ω) (hX_int : Integrable X μ)
    (a : ℝ) (ha : 0 < a) :
    μ.real {ω | a ≤ X ω} ≤ (∫ ω, X ω ∂μ) / a := by
  rw [le_div_iff₀ ha, mul_comm]
  exact mul_meas_ge_le_integral_of_nonneg (Filter.Eventually.of_forall hX_nonneg) hX_int a

/-- **Chebyshev's inequality.** Let X be a random variable on a probability space with a finite
variance σ² (that is, a finite average square), and mean μ = E[X]. Then for every positive
distance ε, the chance that X lands at least ε from its mean, on either side, is at most the
variance divided by ε squared: P(|X − μ| ≥ ε) ≤ σ² / ε². -/
theorem chebyshev_inequality {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (X : Ω → ℝ) (hX : MemLp X 2 μ) (ε : ℝ) (hε : 0 < ε) :
    μ.real {ω | ε ≤ |X ω - ∫ ω', X ω' ∂μ|} ≤ variance X μ / ε ^ 2 := by
  have h := meas_ge_le_variance_div_sq hX hε
  exact ENNReal.toReal_le_of_le_ofReal
    (div_nonneg (variance_nonneg X μ) (sq_nonneg ε)) h

/-- **Chebyshev in standard deviations.** Let X have a finite variance σ² with σ > 0, so its
standard deviation σ = √σ² is positive. Then for every positive number k, at most 1/k² of the
probability lies k or more standard deviations from the mean: P(|X − μ| ≥ kσ) ≤ 1 / k².
Two standard deviations: at most a quarter. Three: at most a ninth. -/
theorem chebyshev_inequality_std_dev {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (X : Ω → ℝ) (hX : MemLp X 2 μ) (hσ : 0 < variance X μ)
    (k : ℝ) (hk : 0 < k) :
    μ.real {ω | k * Real.sqrt (variance X μ) ≤ |X ω - ∫ ω', X ω' ∂μ|} ≤ 1 / k ^ 2 := by
  have hs : 0 < Real.sqrt (variance X μ) := Real.sqrt_pos.mpr hσ
  have h := chebyshev_inequality μ X hX (k * Real.sqrt (variance X μ)) (mul_pos hk hs)
  have e : variance X μ / (k * Real.sqrt (variance X μ)) ^ 2 = 1 / k ^ 2 := by
    rw [mul_pow, Real.sq_sqrt hσ.le]
    field_simp
  rw [e] at h
  exact h

-- The fête's prize table: 50 tickets pay $0, 230 pay $1, 470 pay $2, 210 pay $3, 40 pay $5.
-- There are 1,000 tickets.
example : 50 + 230 + 470 + 210 + 40 = 1000 := by decide
-- The prize fund is $2,000, so the mean is $2.
example : 50 * 0 + 230 * 1 + 470 * 2 + 210 * 3 + 40 * 5 = 2000 := by decide
example : (2000 : ℚ) / 1000 = 2 := by norm_num
-- Squared distances from the $2 mean: 4, 1, 0, 1, 9.
example : ((0 : ℤ) - 2) ^ 2 = 4 ∧ ((1 : ℤ) - 2) ^ 2 = 1 ∧ ((2 : ℤ) - 2) ^ 2 = 0 ∧
    ((3 : ℤ) - 2) ^ 2 = 1 ∧ ((5 : ℤ) - 2) ^ 2 = 9 := by decide
-- The variance: (50 × 4 + 230 × 1 + 470 × 0 + 210 × 1 + 40 × 9) / 1,000 = 1 square dollar.
example : 50 * 4 + 230 * 1 + 470 * 0 + 210 * 1 + 40 * 9 = 1000 := by decide
-- Markov at $4: 2 / 4 = 1/2, so at most 500 of the 1,000 tickets (4 × 500 = the $2,000 fund).
example : (2 : ℚ) / 4 = 1 / 2 := by norm_num
example : 4 * 500 = 2000 := by decide
-- Chebyshev at $2 from the mean: 1 / 2² = 1/4, so at most 250 tickets.
example : (1 : ℚ) / 2 ^ 2 = 1 / 4 := by norm_num
example : (1 / 4 : ℚ) * 1000 = 250 := by norm_num
-- Counted: the two-sided event holds 50 + 40 = 90 tickets, the one-sided event 40,
-- both under the ceiling of 250.
example : 50 + 40 = 90 ∧ 90 ≤ 250 ∧ 40 ≤ 250 := by decide
-- The quoted form: at k = 2 at most a quarter, at k = 3 at most a ninth.
example : (1 : ℚ) / 2 ^ 2 = 1 / 4 ∧ (1 : ℚ) / 3 ^ 2 = 1 / 9 := by norm_num
-- Step 4, Chebyshev met exactly: 8 tickets, one $0, six $2, one $4.
-- Mean 16 / 8 = 2, variance (4 + 0 + 4) / 8 = 1, two tickets of 8 at distance 2: a quarter.
example : 1 * 0 + 6 * 2 + 1 * 4 = 2 * 8 := by decide
example : 1 * 4 + 6 * 0 + 1 * 4 = 1 * 8 := by decide
example : (2 : ℚ) / 8 = 1 / 2 ^ 2 := by norm_num
-- Step 4, Markov met exactly: the house raffle, 99 tickets pay $0 and 1 pays $100; mean $1.
example : 99 * 0 + 1 * 100 = 1 * 100 := by decide
-- Markov at $100 allows 1/100, the true share; at $2 it allows 1/2.
example : (1 : ℚ) / 100 = 1 / 100 ∧ (1 : ℚ) / 2 = 1 / 2 := by norm_num
-- Cantelli at the fête: 1 / (1 + 2²) = 1/5. Five tickets meet it: four pay $3/2 and one pays $4,
-- mean $2 and variance 1.
example : (1 : ℚ) / (1 + 2 ^ 2) = 1 / 5 := by norm_num
example : (4 * (3 / 2) + 4 : ℚ) / 5 = 2 := by norm_num
example : (4 * (3 / 2 - 2) ^ 2 + (4 - 2) ^ 2 : ℚ) / 5 = 1 := by norm_num
-- Markov on the net payout X − 2 fails: its mean is 0, yet (210 + 40) / 1,000 = 1/4 net $1 or more.
example : (50 * (0 - 2) + 230 * (1 - 2) + 470 * (2 - 2) + 210 * (3 - 2) + 40 * (5 - 2) : ℤ) = 0 := by
  decide
example : ((210 + 40 : ℚ)) / 1000 = 1 / 4 := by norm_num
-- The heavy ticket: $2^j with chance 3/4^j. The average squared payout over n prize levels is 3n:
-- 30, 60 and 120 over 10, 20 and 40 levels.
example : (∑ j ∈ Finset.range 10, ((2 : ℚ) ^ (j + 1)) ^ 2 * (3 / 4 ^ (j + 1))) = 30 := by
  norm_num [Finset.sum_range_succ]
example : (∑ j ∈ Finset.range 20, ((2 : ℚ) ^ (j + 1)) ^ 2 * (3 / 4 ^ (j + 1))) = 60 := by
  norm_num [Finset.sum_range_succ]
example : (∑ j ∈ Finset.range 40, ((2 : ℚ) ^ (j + 1)) ^ 2 * (3 / 4 ^ (j + 1))) = 120 := by
  norm_num [Finset.sum_range_succ]
-- The poll: variance at most 1/(4n); with n = 2,000 and a 5-point distance, Chebyshev gives
-- 1 / (4 × 2000 × (1/20)²) = 1/20, a 5% risk.
example : (1 : ℚ) / (4 * 2000) / (1 / 20) ^ 2 = 1 / 20 := by norm_num

#print axioms markov_inequality
#print axioms chebyshev_inequality
#print axioms chebyshev_inequality_std_dev
