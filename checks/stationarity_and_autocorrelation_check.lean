-- Stationarity and autocorrelation: the autocorrelation of a weakly stationary series lies between −1 and 1, its autocovariance is symmetric in the lag with the variance at lag 0, and the sample autocorrelation divided by n lies between −1 and 1 for every record.
import Mathlib.Probability.Moments.Covariance
import Mathlib.Probability.Moments.Variance
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory Finset

/-- A weakly stationary series has autocorrelation between −1 and 1 at every lag.
The series `X t`, indexed by whole-number times `t`, is weakly stationary: every value
has the same mean `m`, the covariance of `X t` and `X (t + h)` is `γ h` whatever the
time `t`, and the variance is finite (each value has a finite second moment). Then
`ρ(h) = γ(h) / γ(0)` satisfies `−1 ≤ ρ(h) ≤ 1`. -/
theorem autocorrelation_mem_Icc_neg_one_one
    {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω} [IsProbabilityMeasure μ]
    (X : ℤ → Ω → ℝ) (m : ℝ) (γ : ℤ → ℝ)
    (h_finite : ∀ t, MemLp (X t) 2 μ)
    (h_mean : ∀ t, μ[X t] = m)
    (h_cov : ∀ t h, cov[X t, X (t + h); μ] = γ h)
    (h : ℤ) :
    -1 ≤ γ h / γ 0 ∧ γ h / γ 0 ≤ 1 := by
  have hvar : ∀ t, Var[X t; μ] = γ 0 := by
    intro t
    rw [← covariance_self (h_finite t).aemeasurable, ← h_cov t 0, add_zero]
  have hA := variance_nonneg (X 0 + X (0 + h)) μ
  have hB := variance_nonneg (X 0 - X (0 + h)) μ
  rw [variance_add (h_finite 0) (h_finite (0 + h)), hvar, hvar, h_cov] at hA
  rw [variance_sub (h_finite 0) (h_finite (0 + h)), hvar, hvar, h_cov] at hB
  have hnn : 0 ≤ γ 0 := hvar 0 ▸ variance_nonneg (X 0) μ
  rcases hnn.lt_or_eq with h0 | h0
  · constructor
    · rw [le_div_iff₀ h0]; linarith
    · rw [div_le_iff₀ h0]; linarith
  · rw [← h0, div_zero]
    norm_num

/-- In a weakly stationary series the autocovariance at lag 0 is the variance of every
value, and the autocovariance is symmetric in the lag: `γ(−h) = γ(h)`. -/
theorem autocovariance_zero_eq_variance_and_symm
    {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω} [IsProbabilityMeasure μ]
    (X : ℤ → Ω → ℝ) (m : ℝ) (γ : ℤ → ℝ)
    (h_finite : ∀ t, MemLp (X t) 2 μ)
    (h_mean : ∀ t, μ[X t] = m)
    (h_cov : ∀ t h, cov[X t, X (t + h); μ] = γ h) :
    (∀ t, Var[X t; μ] = γ 0) ∧ ∀ h, γ (-h) = γ h := by
  refine ⟨fun t => ?_, fun h => ?_⟩
  · rw [← covariance_self (h_finite t).aemeasurable, ← h_cov t 0, add_zero]
  · have := h_cov h (-h)
    rw [add_neg_cancel, covariance_comm] at this
    rw [← this, ← h_cov 0 h, zero_add]

/-- For every record `x 0, …, x (n − 1)` of real numbers and every lag `h`, the sample
autocorrelation `r(h) = c(h) / c(0)` lies between −1 and 1, where the sample
autocovariance `c(h)` sums the `n − h` lag-`h` products of deviations from the record's
average and divides by `n`. -/
theorem sample_autocorrelation_abs_le_one (x : ℕ → ℝ) (n h : ℕ) :
    let xbar := (∑ t ∈ range n, x t) / n
    let c := fun k : ℕ => (∑ t ∈ range (n - k), (x t - xbar) * (x (t + k) - xbar)) / n
    |c h / c 0| ≤ 1 := by
  intro xbar c
  have key : ∀ d : ℕ → ℝ, |∑ t ∈ range (n - h), d t * d (t + h)| ≤ ∑ t ∈ range (n - 0), d t * d (t + 0) := by
    intro d
    simp only [Nat.sub_zero, add_zero]
    have hS : ∀ t ∈ range n, 0 ≤ d t * d t := fun t _ => mul_self_nonneg _
    have h1 : ∑ t ∈ range (n - h), d t * d t ≤ ∑ t ∈ range n, d t * d t :=
      Finset.sum_le_sum_of_subset_of_nonneg (Finset.range_subset_range.mpr (Nat.sub_le n h))
        (fun t ht _ => hS t ht)
    have h2 : ∑ t ∈ range (n - h), d (t + h) * d (t + h) ≤ ∑ t ∈ range n, d t * d t := by
      rw [← Finset.sum_image (s := range (n - h)) (g := fun t => t + h)
        (f := fun t => d t * d t) (fun a _ b _ hab => by simpa using hab)]
      apply Finset.sum_le_sum_of_subset_of_nonneg
      · intro x hx
        simp only [Finset.mem_image, Finset.mem_range] at hx ⊢
        omega
      · intro t ht _; exact hS t ht
    calc |∑ t ∈ range (n - h), d t * d (t + h)|
        ≤ ∑ t ∈ range (n - h), |d t * d (t + h)| := Finset.abs_sum_le_sum_abs _ _
      _ ≤ ∑ t ∈ range (n - h), (d t * d t + d (t + h) * d (t + h)) / 2 := by
          apply Finset.sum_le_sum
          intro t _
          rw [abs_le]
          constructor <;> nlinarith [sq_nonneg (d t + d (t + h)), sq_nonneg (d t - d (t + h))]
      _ = (∑ t ∈ range (n - h), d t * d t + ∑ t ∈ range (n - h), d (t + h) * d (t + h)) / 2 := by
          rw [← Finset.sum_add_distrib, Finset.sum_div]
      _ ≤ ∑ t ∈ range n, d t * d t := by linarith
  have hk := key (fun t => x t - xbar)
  have hn : (0 : ℝ) ≤ n := Nat.cast_nonneg n
  have hc : |c h| ≤ |c 0| := by
    simp only [c, abs_div, abs_of_nonneg hn]
    exact div_le_div_of_nonneg_right (le_trans hk (le_abs_self _)) hn
  rw [abs_div]
  exact div_le_one_of_le₀ hc (abs_nonneg _)

/-- The twelve months of 1949, in thousands of passengers, January to December. -/
def y1949 : ℕ → ℚ := fun t =>
  [112, 118, 132, 129, 121, 135, 148, 148, 136, 119, 104, 118].getD t 0

-- Average of the 12 months of 1949: 126.6667 = 380/3.
example : (∑ t ∈ range 12, y1949 t) / 12 = 380 / 3 := by
  norm_num [Finset.sum_range_succ, y1949]

-- Sum of squared deviations: 2070.6667 = 6212/3.
example : ∑ t ∈ range 12, (y1949 t - 380 / 3) ^ 2 = 6212 / 3 := by
  norm_num [Finset.sum_range_succ, y1949]

-- Sum of the 11 lag-1 products: 1163.5556 = 10472/9.
example : ∑ t ∈ range 11, (y1949 t - 380 / 3) * (y1949 (t + 1) - 380 / 3) = 10472 / 9 := by
  norm_num [Finset.sum_range_succ, y1949]

-- r(1) for 1949: the two 1/12 divisors cancel, giving 2618/4659 = 0.5619.
example : (10472 / 9 : ℚ) / (6212 / 3) = 2618 / 4659 := by
  norm_num

#print axioms autocorrelation_mem_Icc_neg_one_one
#print axioms autocovariance_zero_eq_variance_and_symm
#print axioms sample_autocorrelation_abs_le_one
