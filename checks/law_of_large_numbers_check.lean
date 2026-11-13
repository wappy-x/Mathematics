-- Law of large numbers: the average of n independent draws with a common mean and a common finite variance has variance σ²/n, misses the mean by ε or more with chance at most σ²/(nε²), and so misses with a chance that tends to 0 for every ε > 0.
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Independence.Basic

open MeasureTheory ProbabilityTheory Filter Topology

theorem lln_avg_mean_var {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ) (μ σ2 : ℝ)
    (hind : iIndepFun X P)
    (hL2 : ∀ i, MemLp (X i) 2 P)
    (hmean : ∀ i, ∫ ω, X i ω ∂P = μ)
    (hvar : ∀ i, variance (X i) P = σ2)
    (n : ℕ) (hn : 1 ≤ n) :
    ∫ ω, (∑ i ∈ Finset.range n, X i ω) / n ∂P = μ ∧
      variance (fun ω => (∑ i ∈ Finset.range n, X i ω) / n) P = σ2 / n := by
  have hnpos : (0 : ℝ) < n := by exact_mod_cast hn
  constructor
  · rw [integral_div, integral_finsetSum _ (fun i _ => (hL2 i).integrable one_le_two)]
    simp only [hmean, Finset.sum_const, Finset.card_range, nsmul_eq_mul]
    field_simp
  · have hfun : (fun ω => (∑ i ∈ Finset.range n, X i ω) / n)
        = fun ω => (1 / (n : ℝ)) * (∑ i ∈ Finset.range n, X i) ω := by
      funext ω; simp [Finset.sum_apply]; ring
    rw [hfun, variance_const_mul, IndepFun.variance_sum (fun i _ => hL2 i)
      (fun i _ j _ hij => hind.indepFun hij)]
    simp only [hvar, Finset.sum_const, Finset.card_range, nsmul_eq_mul]
    field_simp

theorem lln_cheb {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ) (μ σ2 : ℝ)
    (hind : iIndepFun X P)
    (hL2 : ∀ i, MemLp (X i) 2 P)
    (hmean : ∀ i, ∫ ω, X i ω ∂P = μ)
    (hvar : ∀ i, variance (X i) P = σ2)
    (n : ℕ) (hn : 1 ≤ n) (ε : ℝ) (hε : 0 < ε) :
    P {ω | ε ≤ |(∑ i ∈ Finset.range n, X i ω) / n - μ|} ≤
      ENNReal.ofReal (σ2 / (n * ε ^ 2)) := by
  obtain ⟨hm, hv⟩ := lln_avg_mean_var X μ σ2 hind hL2 hmean hvar n hn
  have hL : MemLp (fun ω => (∑ i ∈ Finset.range n, X i ω) / n) 2 P := by
    have : MemLp (∑ i ∈ Finset.range n, X i) 2 P := memLp_finsetSum' _ (fun i _ => hL2 i)
    have h2 := this.const_mul (1 / (n : ℝ))
    convert h2 using 1
    funext ω; simp [Finset.sum_apply]; ring
  have := meas_ge_le_variance_div_sq hL hε
  rw [hm, hv] at this
  convert this using 2
  rw [div_div]

#print axioms lln_avg_mean_var
#print axioms lln_cheb

/-- **The weak law of large numbers.** Let `X 0, X 1, X 2, …` be independent random draws,
each with the same mean `μ` and the same finite variance `σ²`. Then, however small the
tolerance `ε > 0`, the chance that the average of the first `n` draws misses `μ` by at least
`ε` tends to 0 as `n` grows: the average converges in probability to `μ`. -/
theorem weak_law_of_large_numbers {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ) (μ σ2 : ℝ)
    (hind : iIndepFun X P)
    (hL2 : ∀ i, MemLp (X i) 2 P)
    (hmean : ∀ i, ∫ ω, X i ω ∂P = μ)
    (hvar : ∀ i, variance (X i) P = σ2) :
    ∀ ε : ℝ, 0 < ε →
      Tendsto (fun n : ℕ => P {ω | ε ≤ |(∑ i ∈ Finset.range n, X i ω) / n - μ|})
        atTop (𝓝 0) := by
  intro ε hε
  have hlim : Tendsto (fun n : ℕ => ENNReal.ofReal (σ2 / (n * ε ^ 2))) atTop (𝓝 0) := by
    rw [← ENNReal.ofReal_zero]
    apply ENNReal.tendsto_ofReal
    have h := tendsto_const_div_atTop_nhds_zero_nat (σ2 / ε ^ 2)
    refine h.congr (fun n => ?_)
    rw [div_div, mul_comm]
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds hlim
    (Eventually.of_forall fun n => zero_le) ?_
  filter_upwards [eventually_ge_atTop 1] with n hn
  exact lln_cheb X μ σ2 hind hL2 hmean hvar n hn ε hε

/-- **The average has one n-th of the variance.** For independent draws, each with the same
mean `μ` and the same finite variance `σ²`, the average of the first `n ≥ 1` draws has
mean `μ` and variance `σ² / n`. -/
theorem mean_and_variance_of_average {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ) (μ σ2 : ℝ)
    (hind : iIndepFun X P)
    (hL2 : ∀ i, MemLp (X i) 2 P)
    (hmean : ∀ i, ∫ ω, X i ω ∂P = μ)
    (hvar : ∀ i, variance (X i) P = σ2)
    (n : ℕ) (hn : 1 ≤ n) :
    ∫ ω, (∑ i ∈ Finset.range n, X i ω) / n ∂P = μ ∧
      variance (fun ω => (∑ i ∈ Finset.range n, X i ω) / n) P = σ2 / n := by
  have hnpos : (0 : ℝ) < n := by exact_mod_cast hn
  constructor
  · rw [integral_div, integral_finsetSum _ (fun i _ => (hL2 i).integrable one_le_two)]
    simp only [hmean, Finset.sum_const, Finset.card_range, nsmul_eq_mul]
    field_simp
  · have hfun : (fun ω => (∑ i ∈ Finset.range n, X i ω) / n)
        = fun ω => (1 / (n : ℝ)) * (∑ i ∈ Finset.range n, X i) ω := by
      funext ω; simp [Finset.sum_apply]; ring
    rw [hfun, variance_const_mul, IndepFun.variance_sum (fun i _ => hL2 i)
      (fun i _ j _ hij => hind.indepFun hij)]
    simp only [hvar, Finset.sum_const, Finset.card_range, nsmul_eq_mul]
    field_simp

/-- **Chebyshev's bound for the average.** For independent draws, each with the same mean
`μ` and the same finite variance `σ²`, any number of draws `n ≥ 1` and any tolerance
`ε > 0`, the chance that the average of the first `n` draws misses `μ` by at least `ε` is
at most `σ² / (n ε²)`. -/
theorem chebyshev_bound_for_average {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ) (μ σ2 : ℝ)
    (hind : iIndepFun X P)
    (hL2 : ∀ i, MemLp (X i) 2 P)
    (hmean : ∀ i, ∫ ω, X i ω ∂P = μ)
    (hvar : ∀ i, variance (X i) P = σ2)
    (n : ℕ) (hn : 1 ≤ n) (ε : ℝ) (hε : 0 < ε) :
    P {ω | ε ≤ |(∑ i ∈ Finset.range n, X i ω) / n - μ|} ≤
      ENNReal.ofReal (σ2 / (n * ε ^ 2)) := by
  obtain ⟨hm, hv⟩ := lln_avg_mean_var X μ σ2 hind hL2 hmean hvar n hn
  have hL : MemLp (fun ω => (∑ i ∈ Finset.range n, X i ω) / n) 2 P := by
    have : MemLp (∑ i ∈ Finset.range n, X i) 2 P := memLp_finsetSum' _ (fun i _ => hL2 i)
    have h2 := this.const_mul (1 / (n : ℝ))
    convert h2 using 1
    funext ω; simp [Finset.sum_apply]; ring
  have := meas_ge_le_variance_div_sq hL hε
  rw [hm, hv] at this
  convert this using 2
  rw [div_div]

-- One fair die: mean (1 + 2 + … + 6)/6 = 7/2, mean square (1 + 4 + … + 36)/6 = 91/6.
example : ((1 + 2 + 3 + 4 + 5 + 6 : ℚ)) / 6 = 7 / 2 := by norm_num
example : ((1 + 4 + 9 + 16 + 25 + 36 : ℚ)) / 6 = 91 / 6 := by norm_num
-- Its variance: 91/6 - (7/2)² = 35/12, the same as the closed form (6 × 6 - 1)/12.
example : (91 / 6 : ℚ) - (7 / 2) ^ 2 = 35 / 12 := by norm_num
example : ((6 * 6 - 1 : ℚ)) / 12 = 35 / 12 := by norm_num
-- The average of 1,000 rolls has variance (35/12)/1000 = 7/2400.
example : (35 / 12 : ℚ) / 1000 = 7 / 2400 := by norm_num
-- Chebyshev at n = 1000, ε = 1/10: the miss bound is 7/24, so a hit has chance at least 17/24.
example : (35 / 12 : ℚ) / (1000 * (1 / 10) ^ 2) = 7 / 24 := by norm_num
example : (1 : ℚ) - 7 / 24 = 17 / 24 := by norm_num
-- Sample size for a miss chance of at most 1/20: the bound certifies 5,834 rolls but not 5,833.
example : (35 / 12 : ℚ) / (5834 * (1 / 10) ^ 2) ≤ 1 / 20 := by norm_num
example : ¬ ((35 / 12 : ℚ) / (5833 * (1 / 10) ^ 2) ≤ 1 / 20) := by norm_num
-- At 100 and 200 rolls the bound is above 1, so it says nothing; it first drops to 1 or less at 292.
example : (1 : ℚ) < (35 / 12) / (100 * (1 / 10) ^ 2) := by norm_num
example : (1 : ℚ) < (35 / 12) / (291 * (1 / 10) ^ 2) := by norm_num
example : (35 / 12 : ℚ) / (292 * (1 / 10) ^ 2) ≤ 1 := by norm_num
-- The whole-number miss test 5|2S - 7n| ≥ n at n = 1000: totals 3,401 to 3,599 hit, 3,400 and 3,600 miss.
example : 5 * |2 * (3401 : ℤ) - 7 * 1000| < 1000 ∧ 5 * |2 * (3599 : ℤ) - 7 * 1000| < 1000 := by
  norm_num
example : 1000 ≤ 5 * |2 * (3400 : ℤ) - 7 * 1000| ∧ 1000 ≤ 5 * |2 * (3600 : ℤ) - 7 * 1000| := by
  norm_num

#print axioms weak_law_of_large_numbers
#print axioms mean_and_variance_of_average
#print axioms chebyshev_bound_for_average
