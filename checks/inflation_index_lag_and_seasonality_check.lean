-- Index lag and seasonality: monthly seasonal factors that repeat each year and add to zero leave every 1-year inflation swap rate equal to the trend rate.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Finset

theorem seasonal_twelve_window_zero
    (s : ℤ → ℝ) (hper : ∀ m, s (m + 12) = s m) (hsum : ∑ i ∈ range 12, s i = 0) (m : ℤ) :
    ∑ i ∈ range 12, s (m + i) = 0 := by
  have step : ∀ k : ℤ, ∑ i ∈ range 12, s (k + 1 + i) = ∑ i ∈ range 12, s (k + i) := by
    intro k
    have h1 := Finset.sum_range_succ (fun i : ℕ => s (k + i)) 12
    have h2 := Finset.sum_range_succ' (fun i : ℕ => s (k + i)) 12
    have e : ∑ i ∈ range 12, s (k + 1 + i) = ∑ i ∈ range 12, s (k + ((i + 1 : ℕ) : ℤ)) := by
      refine Finset.sum_congr rfl fun i _ => ?_
      congr 1; push_cast; ring
    have h12 : s (k + ((12 : ℕ) : ℤ)) = s (k + ((0 : ℕ) : ℤ)) := by
      simpa using hper k
    rw [e]; linarith
  have h0 : ∑ i ∈ range 12, s ((0 : ℤ) + i) = 0 := by simpa using hsum
  induction m using Int.induction_on with
  | zero => exact h0
  | succ k ih => rw [step]; exact ih
  | pred k ih =>
    have := step (-(k : ℤ) - 1)
    have e : (-(k : ℤ) - 1 + 1) = -(k : ℤ) := by ring
    rw [e] at this; rw [← this]; exact ih

theorem seasonal_one_year_sum
    (s : ℤ → ℝ) (hper : ∀ m, s (m + 12) = s m) (hsum : ∑ i ∈ range 12, s i = 0)
    (a b : ℝ) (n : ℤ) :
    (1 - a) * s (n - 2) + ∑ i ∈ range 11, s (n - 1 + i) + b * s (n + 10)
      = (b - a) * s (n - 2) := by
  have hz := seasonal_twelve_window_zero s hper hsum (n - 2)
  rw [Finset.sum_range_succ'] at hz
  have e : ∑ i ∈ range 11, s (n - 2 + ((i + 1 : ℕ) : ℤ)) = ∑ i ∈ range 11, s (n - 1 + i) := by
    refine Finset.sum_congr rfl fun i _ => ?_
    congr 1; push_cast; ring
  have hp : s (n + 10) = s (n - 2) := by
    have := hper (n - 2); rw [← this]; congr 1; ring
  rw [e] at hz
  simp only [Nat.cast_zero, add_zero] at hz
  rw [hp]; linarith

#print axioms seasonal_twelve_window_zero
#print axioms seasonal_one_year_sum

/-- A full year of a lagged, day-interpolated reference index collects no seasonality.
Take seasonal factors `s m` for CPI months `m` that repeat every 12 months and add to zero
over a year. A swap from day `t` of date month `n` to day `t` of month `n + 12` collects the
seasonal sum `S = (1 - w₀) s(n-2) + s(n-1) + ... + s(n+9) + w₁ s(n+10)`, where the three-month
lag and the daily interpolation give the weights `w₀ = (t-1)/D₀` and `w₁ = (t-1)/D₁` from the
lengths `D₀`, `D₁` of the start and end months. When the two months have the same length, the
1-year swap rate `k₁' = (1 + k₁) e^{S/1} - 1` read off the seasonal curve equals the trend rate `k₁`. -/
theorem one_year_swap_rate_unchanged_by_zero_sum_seasonality
    (s : ℤ → ℝ) (hper : ∀ m, s (m + 12) = s m) (hsum : ∑ i ∈ range 12, s i = 0)
    (k₁ t D₀ D₁ : ℝ) (n : ℤ) (hD : D₀ = D₁) :
    (1 + k₁) * Real.exp
        (((1 - (t - 1) / D₀) * s (n - 2) + ∑ i ∈ range 11, s (n - 1 + i)
          + (t - 1) / D₁ * s (n + 10)) / 1) - 1 = k₁ := by
  rw [seasonal_one_year_sum s hper hsum, hD]
  simp

/-- Which CPI months a swap collects. Let `σ` be the seasonal level of CPI months, the running
total of the factors, so `s m = σ m - σ (m - 1)`. On day `t` of date month `n` the reference index
sits at seasonal level `σ(n-3) + w s(n-2)` (three months back, plus the day weight `w` of the next
month's step). A swap from date month `n` to date month `n + h` collects the end level minus the
start level, which is `(1 - w₀) s(n-2) + s(n-1) + ... + s(n+h-3) + w₁ s(n+h-2)`. -/
theorem lagged_window_seasonal_sum
    (σ s : ℤ → ℝ) (hs : ∀ m, s m = σ m - σ (m - 1)) (w₀ w₁ : ℝ) (n : ℤ) (h : ℕ) (hh : 1 ≤ h) :
    (σ (n + h - 3) + w₁ * s (n + h - 2)) - (σ (n - 3) + w₀ * s (n - 2))
      = (1 - w₀) * s (n - 2) + ∑ i ∈ range (h - 1), s (n - 1 + i) + w₁ * s (n + h - 2) := by
  have tel : ∀ k : ℕ, ∑ i ∈ range k, s (n - 1 + i) = σ (n - 2 + k) - σ (n - 2) := by
    intro k
    induction k with
    | zero => simp
    | succ k ih =>
      rw [Finset.sum_range_succ, ih, hs]
      have e1 : n - 1 + (k : ℤ) = n - 2 + ((k + 1 : ℕ) : ℤ) := by push_cast; ring
      have e2 : n - 2 + ((k + 1 : ℕ) : ℤ) - 1 = n - 2 + (k : ℤ) := by push_cast; ring
      rw [e1, e2]; ring
  obtain ⟨k, rfl⟩ : ∃ k, h = k + 1 := ⟨h - 1, by omega⟩
  rw [Nat.add_sub_cancel, tel k, hs (n - 2)]
  have e1 : n + ((k + 1 : ℕ) : ℤ) - 3 = n - 2 + (k : ℤ) := by push_cast; ring
  have e2 : n - 2 - 1 = n - 3 := by ring
  rw [e1, e2]; ring

/-- The leap-day exception. With factors that repeat yearly and add to zero, but start and end
months of different lengths `D₀` and `D₁` (February 2028 against February 2029), a 1-year window
collects `((t-1)/D₁ - (t-1)/D₀) s(n-2)` instead of zero. -/
theorem one_year_seasonal_sum_unequal_months
    (s : ℤ → ℝ) (hper : ∀ m, s (m + 12) = s m) (hsum : ∑ i ∈ range 12, s i = 0)
    (t D₀ D₁ : ℝ) (n : ℤ) :
    (1 - (t - 1) / D₀) * s (n - 2) + ∑ i ∈ range 11, s (n - 1 + i) + (t - 1) / D₁ * s (n + 10)
      = ((t - 1) / D₁ - (t - 1) / D₀) * s (n - 2) := by
  exact seasonal_one_year_sum s hper hsum _ _ n

-- Reference CPI on 15 April from January 300.0 and February 301.2, with CPI in thousandths:
-- Treasury formula, truncated to six decimals and rounded to five, gives 300.56000.
example : ((300000 * 30 + (15 - 1) * (301200 - 300000)) * 1000 / 30 + 5) / 10 = 30056000 := by
  norm_num
-- Wrong: no interpolation (January alone) gives 300.00000.
example : ((300000 * 30 + (1 - 1) * (301200 - 300000)) * 1000 / 30 + 5) / 10 = 30000000 := by
  norm_num
-- Wrong: 15 days counted, not 14, gives 300.60000.
example : ((300000 * 30 + (16 - 1) * (301200 - 300000)) * 1000 / 30 + 5) / 10 = 30060000 := by
  norm_num

-- The card's twelve factors, in hundredths of a percent, add to zero.
example : ([30, 20, 15, 10, 3, 2, -8, -5, -2, -10, -25, -30] : List ℤ).sum = 0 := by decide

-- 15 April to 15 July: S = 16/30 Feb + Mar + Apr + 14/31 May = 0.370215 percent
-- (here in hundredths of a percent).
example : (16 / 30 : ℚ) * 20 + 15 + 10 + 14 / 31 * 3 = 3443 / 93 := by norm_num

-- 15 April to 15 April a year later: 16/30 of February, March to January in full,
-- 14/30 of February; the sum is zero.
example : (16 / 30 : ℚ) * 20 + (15 + 10 + 3 + 2 - 8 - 5 - 2 - 10 - 25 - 30 + 30)
    + 14 / 30 * 20 = 0 := by norm_num

-- 15 February 2028 to 15 February 2029: December at 15/29 and 14/28, January to November in full;
-- the sum is -15/29 hundredths of a percent, not zero.
example : (15 / 29 : ℚ) * (-30) + (30 + 20 + 15 + 10 + 3 + 2 - 8 - 5 - 2 - 10 - 25)
    + 14 / 28 * (-30) = -15 / 29 := by norm_num

#print axioms one_year_swap_rate_unchanged_by_zero_sum_seasonality
#print axioms lagged_window_seasonal_sum
#print axioms one_year_seasonal_sum_unequal_months
