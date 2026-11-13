-- Poisson: the binomial chance of k events in n slots, each with chance lambda/n, tends to e^(-lambda) lambda^k / k! as the slots multiply, these Poisson masses add to 1, and the Poisson law's mean and variance both equal lambda.
import Mathlib.Probability.Distributions.Poisson.PoissonLimitThm
import Mathlib.Probability.Moments.Variance
import Mathlib.Tactic.NormNum

open Filter Topology MeasureTheory ProbabilityTheory
open scoped NNReal

/-- Helper: the Poisson masses times n add to r. -/
lemma poisson_hasSum_mul_self (r : ℝ) :
    HasSum (fun n : ℕ => Real.exp (-r) * r ^ n / n.factorial * n) r := by
  have h0 : HasSum (fun n : ℕ => Real.exp (-r) * r ^ n / n.factorial) 1 := by
    convert (NormedSpace.expSeries_div_hasSum_exp r).mul_left (Real.exp (-r)) using 1
    · ext n; simp [mul_div_assoc]
    · simp [← Real.exp_eq_exp_ℝ, ← Real.exp_add]
  rw [← hasSum_nat_add_iff' 1]
  simp only [Finset.range_one, Finset.sum_singleton, Nat.cast_zero, mul_zero, sub_zero]
  convert h0.mul_left r using 1
  · ext n
    rw [Nat.factorial_succ]; push_cast
    field_simp; ring
  · ring

/-- Helper: the Poisson masses times n^2 add to r^2 + r. -/
lemma poisson_hasSum_mul_sq (r : ℝ) :
    HasSum (fun n : ℕ => Real.exp (-r) * r ^ n / n.factorial * (n : ℝ) ^ 2) (r ^ 2 + r) := by
  have h0 : HasSum (fun n : ℕ => Real.exp (-r) * r ^ n / n.factorial) 1 := by
    convert (NormedSpace.expSeries_div_hasSum_exp r).mul_left (Real.exp (-r)) using 1
    · ext n; simp [mul_div_assoc]
    · simp [← Real.exp_eq_exp_ℝ, ← Real.exp_add]
  have h1 := poisson_hasSum_mul_self r
  rw [← hasSum_nat_add_iff' 1]
  simp only [Finset.range_one, Finset.sum_singleton, Nat.cast_zero]
  convert ((h1.add h0).mul_left r) using 1
  · ext n
    rw [Nat.factorial_succ]; push_cast
    field_simp; ring
  · ring

#print axioms poisson_hasSum_mul_self
#print axioms poisson_hasSum_mul_sq

/-- The Poisson law is the limit of the binomial. Fix an average lambda > 0 and a count k.
Cut the window into n slots, each holding an event with chance lambda / n. The binomial chance
of exactly k events, C(n, k) (lambda/n)^k (1 - lambda/n)^(n - k), tends to the Poisson mass
e^(-lambda) lambda^k / k! as n grows. The number of slots disappears; only the average survives. -/
theorem binomial_tends_to_poisson (lam : ℝ) (hlam : 0 < lam) (k : ℕ) :
    Tendsto (fun n : ℕ => (n.choose k : ℝ) * (lam / n) ^ k * (1 - lam / n) ^ (n - k)) atTop
      (𝓝 (Real.exp (-lam) * lam ^ k / k.factorial)) := by
  apply tendsto_choose_mul_pow_of_tendsto_mul_atTop k (p := fun n : ℕ => lam / n)
  apply tendsto_const_nhds.congr'
  filter_upwards [eventually_ge_atTop 1] with n hn
  have : (n : ℝ) ≠ 0 := by positivity
  field_simp

/-- The Poisson masses account for every outcome: e^(-lambda) lambda^k / k!, summed over all
counts k = 0, 1, 2, ..., adds to exactly 1. -/
theorem poisson_masses_sum_to_one (lam : ℝ) (hlam : 0 < lam) :
    HasSum (fun k : ℕ => Real.exp (-lam) * lam ^ k / k.factorial) 1 := by
  exact hasSum_one_poissonMeasure ⟨lam, hlam.le⟩

/-- Mean equals variance: a count X following the Poisson law with average lambda > 0
has long-run average E[X] = lambda and variance Var(X) = lambda. -/
theorem poisson_mean_eq_variance_eq_lambda (r : ℝ≥0) (hr : 0 < r) :
    (∫ n, (n : ℝ) ∂(poissonMeasure r)) = r ∧
      variance (fun n : ℕ => (n : ℝ)) (poissonMeasure r) = r := by
  have hmean : (∫ n, (n : ℝ) ∂(poissonMeasure r)) = r := by
    rw [integral_poissonMeasure]
    simpa using (poisson_hasSum_mul_self r).tsum_eq
  refine ⟨hmean, ?_⟩
  have hsq : (∫ n, (n : ℝ) ^ 2 ∂(poissonMeasure r)) = (r : ℝ) ^ 2 + r := by
    rw [integral_poissonMeasure]
    simpa using (poisson_hasSum_mul_sq r).tsum_eq
  have hint : Integrable (fun n : ℕ => (n : ℝ) ^ 2) (poissonMeasure r) := by
    rw [integrable_poissonMeasure_iff]
    simpa [abs_of_nonneg] using (poisson_hasSum_mul_sq r).summable
  have hmem : MemLp (fun n : ℕ => (n : ℝ)) 2 (poissonMeasure r) :=
    (memLp_two_iff_integrable_sq (by fun_prop)).2 hint
  rw [variance_eq_sub hmem]
  simp only [Pi.pow_apply]
  rw [hsq, hmean]; ring

-- The help desk: 12 emails an hour over 1 hour gives lambda = 12.
example : (12 : ℕ) * 1 = 12 := by norm_num
-- The peak: the step from p11 to p12 multiplies by 12/12 = 1, so the two masses are equal.
example : (12 : ℚ) / 12 = 1 := by norm_num
example : Real.exp (-12) * 12 ^ 11 / (Nat.factorial 11 : ℝ)
    = Real.exp (-12) * 12 ^ 12 / (Nat.factorial 12 : ℝ) := by
  rw [mul_div_assoc, mul_div_assoc]; norm_num [Nat.factorial]
-- The check from above: p21 = p20 × 12/21.
example : Real.exp (-12) * 12 ^ 21 / (Nat.factorial 21 : ℝ)
    = Real.exp (-12) * 12 ^ 20 / (Nat.factorial 20 : ℝ) * (12 / 21) := by
  rw [mul_div_assoc, mul_div_assoc, mul_assoc]; norm_num [Nat.factorial]
-- The bracket: later ratios are at most 12/22, so the tail is at most p21 × 1/(1 - 12/22) = p21 × 22/10.
example : (1 : ℚ) / (1 - 12 / 22) = 22 / 10 := by norm_num
-- Mean equals variance at the help desk: E[X(X-1)] + E[X] - E[X]^2 = 144 + 12 - 144 = 12.
example : (12 : ℤ) ^ 2 + 12 - 12 ^ 2 = 12 := by norm_num
-- Coarse slots: 60 one-minute slots, chance 12/60 = 1/5 each; variance 60 × 1/5 × 4/5 = 48/5 (9.6).
example : (12 : ℚ) / 60 = 1 / 5 ∧ (60 : ℚ) * (1 / 5) * (1 - 1 / 5) = 48 / 5 := by norm_num
-- Le Cam's bound at 3600 slots: lambda^2 / n = 144/3600 = 1/25 (0.0400).
example : (12 : ℚ) ^ 2 / 3600 = 1 / 25 := by norm_num
-- Emails in pairs, 6 pairs an hour: mean 2 × 6 = 12, variance 2^2 × 6 = 24.
example : 2 * 6 = 12 ∧ 2 ^ 2 * 6 = 24 := by norm_num
-- A coin flip picks rate 6 or 18: mean (6 + 18)/2 = 12; variance = average variance 12
-- plus the spread of the rate ((6 - 12)^2 + (18 - 12)^2)/2 = 36, total 48.
example : ((6 : ℚ) + 18) / 2 = 12 ∧ ((6 : ℚ) + 18) / 2 + ((6 - 12) ^ 2 + (18 - 12) ^ 2) / 2 = 48 := by
  norm_num
-- Lambda matches the window: a two-hour window has lambda = 12 × 2 = 24.
example : (12 : ℕ) * 2 = 24 := by norm_num

#print axioms binomial_tends_to_poisson
#print axioms poisson_masses_sum_to_one
#print axioms poisson_mean_eq_variance_eq_lambda
