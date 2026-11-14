-- Life tables: the chance of living t more years is the ratio of two survivor counts, and it equals e to the minus the force of mortality integrated over those years.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Algebra.BigOperators.Intervals

open Finset

/-- The force of mortality is the slope of the log of the survivor count with its sign turned,
`μ y = -(dl/dy) / l y`. Then the chance of living `t` more years from age `x`, the survivor count
at `x + t` over the count at `x`, equals `exp (-∫₀ᵗ μ (x + s) ds)`: e to the minus the force of
mortality piled up over those `t` years. -/
theorem survival_ratio_eq_exp_neg_integral_force (l μ : ℝ → ℝ)
    (hpos : ∀ y, 0 < l y) (hdiff : Differentiable ℝ l) (hcont : Continuous (deriv l))
    (hμ : ∀ y, μ y = -deriv l y / l y) (x t : ℝ) :
    l (x + t) / l x = Real.exp (-∫ s in (0 : ℝ)..t, μ (x + s)) := by
  have hlc : Continuous l := hdiff.continuous
  have hderiv : ∀ s ∈ Set.uIcc (0:ℝ) t,
      HasDerivAt (fun s => -Real.log (l (x + s))) (μ (x + s)) s := by
    intro s _
    have h1 : HasDerivAt (fun s => l (x + s)) (deriv l (x + s)) s := by
      have := (hdiff (x + s)).hasDerivAt
      exact this.comp_const_add x s
    have h2 := (h1.log (hpos (x + s)).ne').neg
    rw [hμ]
    convert h2 using 1
    ring
  have hint : IntervalIntegrable (fun s => μ (x + s)) MeasureTheory.volume 0 t := by
    apply Continuous.intervalIntegrable
    have : (fun s => μ (x + s)) = fun s => -deriv l (x + s) / l (x + s) := by
      funext s; exact hμ _
    rw [this]
    exact Continuous.div ((hcont.comp (continuous_const.add continuous_id)).neg)
      (hlc.comp (continuous_const.add continuous_id)) (fun s => (hpos _).ne')
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hderiv hint]
  rw [show -(-Real.log (l (x + t)) - -Real.log (l (x + 0))) = Real.log (l (x + t)) - Real.log (l x) by
      rw [add_zero]; ring,
    Real.exp_sub, Real.exp_log (hpos _), Real.exp_log (hpos _)]

/-- Ratio of counts. If each year's survivors are last year's times that year's survival chance,
`l (y + 1) = l y * p y`, and the count at age `x` is not zero, then the chance of living `n` more
whole years, `l (x + n) / l x`, is the product of the `n` one-year survival chances
`p x * p (x + 1) * ... * p (x + n - 1)`. The radix cancels. -/
theorem life_table_ratio_eq_prod_survival (l p : ℕ → ℝ) (hrec : ∀ y, l (y + 1) = l y * p y)
    (x n : ℕ) (hx : l x ≠ 0) :
    l (x + n) / l x = ∏ j ∈ range n, p (x + j) := by
  have key : ∀ n : ℕ, l (x + n) = l x * ∏ j ∈ range n, p (x + j) := by
    intro n
    induction n with
    | zero => simp
    | succ n ih =>
      rw [prod_range_succ, ← add_assoc, hrec, ih]
      ring
  rw [key n]
  field_simp

/-- Curtate life expectancy, two roads. For a life table that closes at age `x + N`
(nobody is left: `l (x + N) = 0`), weighting each whole number of further years `k` by the
chance of dying between `x + k` and `x + k + 1`, `d (x + k) / l x` with `d y = l y - l (y + 1)`,
gives the same total as adding the survival chances `l (x + k) / l x` for `k = 1, ..., N`. -/
theorem curtate_expectation_deaths_eq_sum_survival (l : ℕ → ℝ) (x N : ℕ) (hN : l (x + N) = 0) :
    (∑ k ∈ range N, (k : ℝ) * (l (x + k) - l (x + k + 1))) / l x
      = (∑ k ∈ Icc 1 N, l (x + k)) / l x := by
  have key : ∀ n : ℕ, ∑ k ∈ range n, (k : ℝ) * (l (x + k) - l (x + k + 1))
      = (∑ k ∈ Icc 1 n, l (x + k)) - n * l (x + n) := by
    intro n
    induction n with
    | zero => simp
    | succ n ih =>
      rw [sum_range_succ, ih, sum_Icc_succ_top (by omega)]
      push_cast
      rw [← add_assoc]
      ring
  rw [key N, hN]
  simp

#print axioms survival_ratio_eq_exp_neg_integral_force
#print axioms life_table_ratio_eq_prod_survival
#print axioms curtate_expectation_deaths_eq_sum_survival
