-- Performance measures: the Sharpe ratio's delta-method error bar is (1 + S²/2)/n to first order, borrowing at cash leaves the Sharpe ratio unchanged, and the running-peak maximum drawdown equals the worst fall over every pair of months.
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.Finset.Lattice.Fold
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Inv

open Finset

/-- The error bar on the Sharpe ratio, by the delta method. The ratio is the function
`g m v = m / √v` of the sample mean `m` and the sample variance `v`. At the true values
`(μ, σ²)`, with `σ > 0`, take the slopes of `g` in each direction. Bell-curve monthly returns
over `n ≥ 2` months give the sample mean variance `σ²/n`, the sample variance variance
`2σ⁴/(n-1)`, and zero covariance between them. Then the first-order variance of the ratio,
slope squared times variance summed over the two inputs, is exactly
`1/n + (μ/σ)² / (2(n-1))`, which is `(1 + S²/2)/n` to leading order with `S = μ/σ`. -/
theorem sharpe_error_bar_delta_method (μ σ : ℝ) (hσ : 0 < σ) (n : ℕ) (hn : 2 ≤ n) :
    let g : ℝ → ℝ → ℝ := fun m v => m / Real.sqrt v
    let dm := deriv (fun m => g m (σ ^ 2)) μ
    let dv := deriv (fun v => g μ v) (σ ^ 2)
    dm ^ 2 * (σ ^ 2 / n) + dv ^ 2 * (2 * σ ^ 4 / ((n : ℝ) - 1)) =
      1 / n + (μ / σ) ^ 2 / (2 * ((n : ℝ) - 1)) := by
  intro g dm dv
  have hs : Real.sqrt (σ ^ 2) = σ := Real.sqrt_sq hσ.le
  have hdm : dm = 1 / σ := by
    show deriv (fun m => m / Real.sqrt (σ ^ 2)) μ = 1 / σ
    rw [hs]
    exact ((hasDerivAt_id μ).div_const σ).deriv
  have hv : (σ ^ 2) ≠ 0 := by positivity
  have hdv : dv = -(μ * (1 / (2 * σ))) / σ ^ 2 := by
    show deriv (fun v => μ / Real.sqrt v) (σ ^ 2) = _
    have h1 := Real.hasDerivAt_sqrt hv
    have h2 : HasDerivAt (fun v => μ / Real.sqrt v) _ (σ ^ 2) := (hasDerivAt_const (σ ^ 2) μ).div h1 (by rw [hs]; exact hσ.ne')
    rw [h2.deriv, hs]
    ring
  rw [hdm, hdv]
  have hn' : (2 : ℝ) ≤ n := by exact_mod_cast hn
  have h1 : (n : ℝ) - 1 ≠ 0 := by linarith
  have h2 : (n : ℝ) ≠ 0 := by linarith
  field_simp

/-- A score that does not change with the size of the bet. Take `n` monthly excess returns
`x` with a non-zero spread (not all equal). The Sharpe ratio is the average divided by the
sample spread (standard deviation with `n - 1` in the divisor). Borrowing at the cash rate to
invest `c > 0` times the money multiplies every excess return by `c`, and the Sharpe ratio
does not move. -/
theorem sharpe_ratio_unchanged_by_leverage (n : ℕ) (x : Fin n → ℝ)
    (hspread : ∃ s t, x s ≠ x t) (c : ℝ) (hc : 0 < c) :
    let sharpe : (Fin n → ℝ) → ℝ := fun y =>
      ((∑ t, y t) / n) / Real.sqrt ((∑ t, (y t - (∑ s, y s) / n) ^ 2) / ((n : ℝ) - 1))
    sharpe (fun t => c * x t) = sharpe x := by
  intro sharpe
  simp only [sharpe]
  have e1 : ∀ t, (c * x t - (∑ s, c * x s) / n) ^ 2 = c ^ 2 * (x t - (∑ s, x s) / n) ^ 2 := by
    intro t
    rw [← Finset.mul_sum]
    ring
  simp_rw [e1]
  rw [← Finset.mul_sum, ← Finset.mul_sum, mul_div_assoc (c ^ 2), Real.sqrt_mul (sq_nonneg c),
    Real.sqrt_sq hc.le, mul_div_assoc]
  exact mul_div_mul_left _ _ hc.ne'

/-- Maximum drawdown, found two ways. Let `W t > 0` be the value of the holding after month
`t`, for months `0, …, n`, and `H t = max_{j ≤ t} W j` its high-water mark. The largest
running-peak drawdown `max_t (1 - W t / H t)` equals the largest fall over every pair of
months, an earlier `j` and a later `t`: `max_{j ≤ t ≤ n} (1 - W t / W j)`. -/
theorem max_drawdown_running_peak_eq_every_pair (W : ℕ → ℝ) (hW : ∀ t, 0 < W t) (n : ℕ) :
    let H : ℕ → ℝ := fun t => (range (t + 1)).sup' nonempty_range_add_one W
    (range (n + 1)).sup' nonempty_range_add_one (fun t => 1 - W t / H t) =
      (range (n + 1)).sup' nonempty_range_add_one
        (fun t => (range (t + 1)).sup' nonempty_range_add_one (fun j => 1 - W t / W j)) := by
  intro H
  congr 1
  funext t
  apply le_antisymm
  · obtain ⟨j, hj, hHj⟩ := Finset.exists_mem_eq_sup' (nonempty_range_add_one (n := t)) W
    show 1 - W t / H t ≤ _
    simp only [H]
    rw [hHj]
    exact Finset.le_sup' (fun j => 1 - W t / W j) hj
  · apply Finset.sup'_le
    intro j hj
    have hle : W j ≤ H t := Finset.le_sup' W hj
    have : W t / H t ≤ W t / W j :=
      div_le_div_of_nonneg_left (hW t).le (hW j) hle
    linarith

#print axioms sharpe_error_bar_delta_method
#print axioms sharpe_ratio_unchanged_by_leverage
#print axioms max_drawdown_running_peak_eq_every_pair
