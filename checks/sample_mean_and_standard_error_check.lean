-- Standard error: the average of n independent answers with common mean μ and variance σ² has mean μ, variance σ²/n and standard deviation σ/√n, and the sample variance that divides by n − 1 has mean exactly σ² when n ≥ 2.
import Mathlib.Probability.Moments.Variance
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory

lemma sum_sq_dev_aux (n : ℕ) (x : Fin n → ℝ) (m : ℝ) :
    ∑ i, (x i - (∑ j, x j) / n) ^ 2
      = ∑ i, (x i - m) ^ 2 - n * ((∑ j, x j) / n - m) ^ 2 := by
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp
  have hn' : (n : ℝ) ≠ 0 := by positivity
  set S := ∑ j, x j with hS
  have h1 : ∀ i, (x i - m) ^ 2 = (x i - S / n) ^ 2 + 2 * (S / n - m) * (x i - S / n)
      + (S / n - m) ^ 2 := fun i => by ring
  have h0 : ∑ i, (x i - S / n) = 0 := by
    rw [Finset.sum_sub_distrib, ← hS]
    simp only [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
    field_simp
    ring
  rw [Finset.sum_congr rfl (fun i _ => h1 i), Finset.sum_add_distrib, Finset.sum_add_distrib,
    ← Finset.mul_sum, h0]
  simp only [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
  ring

#print axioms sum_sq_dev_aux

lemma sample_mean_aux {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] (n : ℕ) (hn : 0 < n) (X : Fin n → Ω → ℝ)
    (hind : iIndepFun X P) (hX : ∀ i, MemLp (X i) 2 P) (μ σ : ℝ)
    (hmean : ∀ i, ∫ ω, X i ω ∂P = μ) (hvar : ∀ i, variance (X i) P = σ ^ 2) :
    (∫ ω, (∑ i, X i ω) / n ∂P) = μ ∧
    variance (fun ω => (∑ i, X i ω) / n) P = σ ^ 2 / n := by
  have hn' : (n : ℝ) ≠ 0 := by positivity
  constructor
  · rw [integral_div, integral_finsetSum _ (fun i _ => (hX i).integrable one_le_two)]
    simp [hmean]
    field_simp
  · have hsum : variance (fun ω => ∑ i, X i ω) P = n * σ ^ 2 := by
      have := IndepFun.variance_sum (s := Finset.univ) (fun i _ => hX i)
        (fun i _ j _ hij => hind.indepFun hij)
      rw [show (fun ω => ∑ i, X i ω) = ∑ i, X i by ext ω; simp, this]
      simp [hvar]
    simp_rw [div_eq_mul_inv]
    rw [variance_mul_const, hsum]
    field_simp

#print axioms sample_mean_aux

/-- The average aims at the mean, and its spread shrinks like one over root n. Let
X₁, …, Xₙ (n ≥ 1) be independent answers on one probability space, each with mean μ and a
finite variance σ², where σ ≥ 0 is the standard deviation of one answer. Then the sample
mean X̄ = (X₁ + … + Xₙ)/n has E[X̄] = μ, Var(X̄) = σ²/n, and its standard deviation, the
standard error, is σ/√n. -/
theorem sample_mean_mean_variance_standard_error {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] (n : ℕ) (hn : 0 < n) (X : Fin n → Ω → ℝ)
    (hind : iIndepFun X P) (hX : ∀ i, MemLp (X i) 2 P) (μ σ : ℝ) (hσ : 0 ≤ σ)
    (hmean : ∀ i, ∫ ω, X i ω ∂P = μ) (hvar : ∀ i, variance (X i) P = σ ^ 2) :
    (∫ ω, (∑ i, X i ω) / n ∂P) = μ ∧
    variance (fun ω => (∑ i, X i ω) / n) P = σ ^ 2 / n ∧
    Real.sqrt (variance (fun ω => (∑ i, X i ω) / n) P) = σ / Real.sqrt n := by
  obtain ⟨h1, h2⟩ := sample_mean_aux P n hn X hind hX μ σ hmean hvar
  refine ⟨h1, h2, ?_⟩
  rw [h2, Real.sqrt_div' _ (Nat.cast_nonneg n), Real.sqrt_sq hσ]

/-- Dividing by n − 1 is exactly right on average. Let X₁, …, Xₙ with n ≥ 2 be independent
answers on one probability space, each with mean μ and finite variance σ². Write
Q = Σᵢ (Xᵢ − X̄)² for the sum of squared deviations from the sample mean X̄. Then the sample
variance S² = Q/(n − 1) has E[S²] = σ², while the divide-by-n version V = Q/n has
E[V] = (n − 1)σ²/n, low by the factor (n − 1)/n. -/
theorem sample_variance_unbiased {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] (n : ℕ) (hn : 2 ≤ n) (X : Fin n → Ω → ℝ)
    (hind : iIndepFun X P) (hX : ∀ i, MemLp (X i) 2 P) (μ σ : ℝ)
    (hmean : ∀ i, ∫ ω, X i ω ∂P = μ) (hvar : ∀ i, variance (X i) P = σ ^ 2) :
    (∫ ω, (∑ i, (X i ω - (∑ j, X j ω) / n) ^ 2) / (n - 1) ∂P) = σ ^ 2 ∧
    (∫ ω, (∑ i, (X i ω - (∑ j, X j ω) / n) ^ 2) / n ∂P) = (n - 1) / n * σ ^ 2 := by
  have hn0 : 0 < n := by omega
  have hnR : (2 : ℝ) ≤ n := by exact_mod_cast hn
  have hn' : (n : ℝ) ≠ 0 := by positivity
  have hn1 : (n : ℝ) - 1 ≠ 0 := by linarith
  obtain ⟨h1, h2⟩ := sample_mean_aux P n hn0 X hind hX μ σ hmean hvar
  have hbarL : MemLp (fun ω => (∑ i, X i ω) / n) 2 P := by
    simp_rw [div_eq_mul_inv]
    exact (memLp_finsetSum _ (fun i _ => hX i)).mul_const _
  have hint_i : ∀ i, Integrable (fun ω => (X i ω - μ) ^ 2) P := fun i =>
    ((hX i).sub (memLp_const μ)).integrable_sq
  have hint_bar : Integrable (fun ω => ((∑ j, X j ω) / n - μ) ^ 2) P :=
    (hbarL.sub (memLp_const μ)).integrable_sq
  have hEi : ∀ i, ∫ ω, (X i ω - μ) ^ 2 ∂P = σ ^ 2 := fun i => by
    rw [← hvar i, variance_eq_integral (hX i).aemeasurable, hmean i]
  have hEbar : ∫ ω, ((∑ j, X j ω) / n - μ) ^ 2 ∂P = σ ^ 2 / n := by
    rw [← h2, variance_eq_integral hbarL.aemeasurable, h1]
  have hQ : ∫ ω, ∑ i, (X i ω - (∑ j, X j ω) / n) ^ 2 ∂P = (n - 1) * σ ^ 2 := by
    simp_rw [sum_sq_dev_aux n _ μ]
    rw [integral_sub (integrable_finsetSum _ (fun i _ => hint_i i)) (hint_bar.const_mul _),
      integral_finsetSum _ (fun i _ => hint_i i), integral_const_mul, hEbar]
    simp only [hEi, Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
    field_simp
  constructor
  · rw [integral_div, hQ]
    field_simp
  · rw [integral_div, hQ]
    field_simp

/-- The shortfall identity, pure algebra for every list of numbers. For any numbers
x₁, …, xₙ with average x̄ and any number m, the squared deviations from the list's own
average fall short of those from m by exactly n(x̄ − m)²:
Σᵢ (xᵢ − x̄)² = Σᵢ (xᵢ − m)² − n(x̄ − m)². -/
theorem sum_sq_dev_sample_mean_eq (n : ℕ) (x : Fin n → ℝ) (m : ℝ) :
    ∑ i, (x i - (∑ j, x j) / n) ^ 2
      = ∑ i, (x i - m) ^ 2 - n * ((∑ j, x j) / n - m) ^ 2 := by
  exact sum_sq_dev_aux n x m

/-! The card's worked numbers, exactly, as fractions. -/

-- The poll: 520 yes and 480 no make 1,000 answers, average 520/1000 = 0.52.
example : 520 + 480 = 1000 := by decide
example : (520 / 1000 : ℚ) = 52 / 100 := by norm_num
-- One answer's variance at p = 0.52: p(1 − p) = 0.52 × 0.48 = 0.2496.
example : (52 / 100 : ℚ) * (48 / 100) = 2496 / 10000 := by norm_num
-- Squared deviations: (1 − 0.52)² = 0.2304 for a yes, 0.52² = 0.2704 for a no.
example : (1 - 52 / 100 : ℚ) ^ 2 = 2304 / 10000 ∧ (52 / 100 : ℚ) ^ 2 = 2704 / 10000 := by norm_num
-- Q = 520 × 0.2304 + 480 × 0.2704 = 119.808 + 129.792 = 249.6.
example : (520 : ℚ) * (2304 / 10000) = 119808 / 1000 ∧ (480 : ℚ) * (2704 / 10000) = 129792 / 1000 ∧
    (119808 / 1000 : ℚ) + 129792 / 1000 = 2496 / 10 := by norm_num
-- Step 5 for 0/1 answers: Q = n p̂(1 − p̂) = 1000 × 0.52 × 0.48 = 249.6.
example : (1000 : ℚ) * (52 / 100) * (48 / 100) = 2496 / 10 := by norm_num
-- The sample variance s² = 249.6 / 999 = 416/1665 exactly (0.249850 rounded),
-- and the divide-by-n version V = 249.6 / 1000 = 0.2496.
example : (2496 / 10 : ℚ) / 999 = 416 / 1665 ∧ (2496 / 10 : ℚ) / 1000 = 2496 / 10000 := by norm_num
-- s² = (n/(n − 1)) p̂(1 − p̂) = (1000/999) × 0.2496.
example : (1000 / 999 : ℚ) * (2496 / 10000) = 416 / 1665 := by norm_num
-- The squared standard error of the poll: σ²/n = 0.2496/1000 = 0.0002496.
example : (2496 / 10000 : ℚ) / 1000 = 2496 / 10000000 := by norm_num
-- Var(X̄) = σ²/n at 2 voters is 0.124800 and at 8 voters 0.031200.
example : (2496 / 10000 : ℚ) / 2 = 1248 / 10000 ∧ (2496 / 10000 : ℚ) / 8 = 312 / 10000 := by norm_num
-- Four times the voters, a quarter the variance, so half the error: 25 → 100 and 250 → 1000.
example : 4 * 25 = 100 ∧ 4 * 250 = 1000 := by decide
example : (2496 / 10000 : ℚ) / 100 = (2496 / 10000 / 25) / 4 := by norm_num
example : Real.sqrt 4 = 2 := by
  rw [show (4 : ℝ) = 2 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]
-- The two-voter poll: a mixed pair has chance 2 × 0.52 × 0.48 = 0.4992; its average is 1/2
-- and its squared deviations total (1 − 1/2)² + (0 − 1/2)² = 1/2.
example : (2 : ℚ) * (52 / 100) * (48 / 100) = 4992 / 10000 := by norm_num
example : (1 - 1 / 2 : ℚ) ^ 2 + (0 - 1 / 2) ^ 2 = 1 / 2 := by norm_num
-- Over all four answer lists (yes-yes, yes-no, no-yes, no-no), S² (divide by 1) averages
-- 0.2496, the truth, and V (divide by 2) averages 0.1248.
example : (52 / 100 : ℚ) ^ 2 * 0 + (52 / 100) * (48 / 100) * (1 / 2) + (48 / 100) * (52 / 100) * (1 / 2)
    + (48 / 100) ^ 2 * 0 = 2496 / 10000 := by norm_num
example : ((52 / 100 : ℚ) ^ 2 * 0 + (52 / 100) * (48 / 100) * (1 / 2) + (48 / 100) * (52 / 100) * (1 / 2)
    + (48 / 100) ^ 2 * 0) / 2 = 1248 / 10000 := by norm_num
-- E[V] as a percent of σ²: 100(n − 1)/n is 50 at n = 2, 75 at 4, 80 at 5 and 87.5 at 8.
example : (100 : ℚ) * (2 - 1) / 2 = 50 ∧ (100 : ℚ) * (4 - 1) / 4 = 75 ∧
    (100 : ℚ) * (5 - 1) / 5 = 80 ∧ (100 : ℚ) * (8 - 1) / 8 = 875 / 10 := by norm_num
-- The three-answer question: values 1, 2, 3 with chances 0.25, 0.5, 0.25 have mean 2 and
-- variance 0.5; over every list of 4 answers E[S²] = 0.5 and E[V] = (3/4) × 0.5 = 0.375.
example : (1 / 4 : ℚ) * 1 + (1 / 2) * 2 + (1 / 4) * 3 = 2 ∧
    (1 / 4 : ℚ) * (1 - 2) ^ 2 + (1 / 2) * (2 - 2) ^ 2 + (1 / 4) * (3 - 2) ^ 2 = 1 / 2 ∧
    (4 - 1) / 4 * (1 / 2 : ℚ) = 375 / 1000 := by norm_num
-- The clustered poll: 100 homes of 10 make 1,000 calls but only 100 independent answers,
-- so the average's variance is 0.2496/100 = 0.002496, not 0.2496/1000.
example : 100 * 10 = 1000 := by decide
example : (2496 / 10000 : ℚ) / 100 = 2496 / 1000000 := by norm_num

#print axioms sample_mean_mean_variance_standard_error
#print axioms sample_variance_unbiased
#print axioms sum_sq_dev_sample_mean_eq
