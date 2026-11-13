-- Returns: growth factors multiply and log returns add over time, independent months give a spread that grows with the square root of time, and up then down by the same fraction keeps one minus its square.
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Moments.Variance

open Real MeasureTheory ProbabilityTheory Finset

/-- Chaining periods: for positive prices `P 0, P 1, ..., P n`, the total growth factor
`1 + R_total = P n / P 0` is the product of the monthly growth factors `1 + R_i`, where
`R_i = (P (i+1) - P i) / P i` is the simple return of month `i`, and the total log return
`ln (P n / P 0)` is the sum of the monthly log returns `ln (P (i+1) / P i)`. -/
theorem log_returns_add_over_time (P : ℕ → ℝ) (hP : ∀ i, 0 < P i) (n : ℕ) :
    P n / P 0 = ∏ i ∈ range n, (1 + (P (i + 1) - P i) / P i) ∧
    Real.log (P n / P 0) = ∑ i ∈ range n, Real.log (P (i + 1) / P i) := by
  have key : ∀ m : ℕ, P m / P 0 = ∏ i ∈ range m, (1 + (P (i + 1) - P i) / P i) := by
    intro m
    induction m with
    | zero => simp [(hP 0).ne']
    | succ m ih =>
      rw [prod_range_succ, ← ih]
      have h0 := (hP 0).ne'
      have hm := (hP m).ne'
      field_simp
      ring
  have keylog : ∀ m : ℕ, Real.log (P m / P 0) = ∑ i ∈ range m, Real.log (P (i + 1) / P i) := by
    intro m
    induction m with
    | zero => simp [(hP 0).ne']
    | succ m ih =>
      rw [sum_range_succ, ← ih, ← Real.log_mul (div_pos (hP m) (hP 0)).ne'
        (div_pos (hP (m + 1)) (hP m)).ne']
      congr 1
      have h0 := (hP 0).ne'
      have hm := (hP m).ne'
      field_simp
  exact ⟨key n, keylog n⟩

/-- The square root of time: if the monthly log returns `r_1, ..., r_n` are independent,
each with average `g` and spread `σ` (variance `σ²`), then the `n`-month log return
`r_1 + ... + r_n` has average `n g` and spread `σ √n`. -/
theorem log_return_spread_scales_with_sqrt_time {Ω : Type*} [MeasurableSpace Ω]
    (μ : Measure Ω) [IsProbabilityMeasure μ] (n : ℕ) (r : Fin n → Ω → ℝ) (g σ : ℝ)
    (hσ : 0 ≤ σ) (hr : ∀ i, MemLp (r i) 2 μ) (hind : iIndepFun r μ)
    (hmean : ∀ i, ∫ ω, r i ω ∂μ = g) (hvar : ∀ i, variance (r i) μ = σ ^ 2) :
    ∫ ω, (∑ i, r i) ω ∂μ = n * g ∧
    Real.sqrt (variance (∑ i, r i) μ) = σ * Real.sqrt n := by
  have hint : ∀ i, Integrable (r i) μ := fun i => (hr i).integrable one_le_two
  refine ⟨?_, ?_⟩
  · rw [Finset.sum_fn, MeasureTheory.integral_finsetSum _ (fun i _ => hint i)]
    simp [hmean]
  · rw [IndepFun.variance_sum (fun i _ => hr i)
      (fun i _ j _ hij => hind.indepFun hij)]
    simp only [hvar, sum_const, card_univ, Fintype.card_fin, nsmul_eq_mul]
    rw [Real.sqrt_mul (Nat.cast_nonneg n), Real.sqrt_sq hσ, mul_comm]

/-- The volatility drag, exactly: up by `a` then down by `a` (prices staying positive, so
`-1 < a < 1`) multiplies money by `1 - a²`, and the average monthly log return of the pair
is `½ ln (1 - a²)`, which is below zero whenever `a ≠ 0`. -/
theorem up_then_down_loses_the_square (a : ℝ) (ha₁ : -1 < a) (ha₂ : a < 1) :
    (1 + a) * (1 - a) = 1 - a ^ 2 ∧
    (Real.log (1 + a) + Real.log (1 - a)) / 2 = Real.log (1 - a ^ 2) / 2 ∧
    (a ≠ 0 → (Real.log (1 + a) + Real.log (1 - a)) / 2 < 0) := by
  have h1 : 0 < 1 + a := by linarith
  have h2 : 0 < 1 - a := by linarith
  have hprod : (1 + a) * (1 - a) = 1 - a ^ 2 := by ring
  have hlog : Real.log (1 + a) + Real.log (1 - a) = Real.log (1 - a ^ 2) := by
    rw [← Real.log_mul h1.ne' h2.ne', hprod]
  refine ⟨hprod, by rw [hlog], fun ha => ?_⟩
  rw [hlog]
  have hpos : 0 < 1 - a ^ 2 := by rw [← hprod]; positivity
  have hlt : 1 - a ^ 2 < 1 := by have := pow_pos (abs_pos.mpr ha) 2; rw [sq_abs] at this; linarith
  have := Real.log_neg hpos hlt
  linarith

-- $100, up 10% then down 10%, ends at $99.
example : (100 : ℚ) * (11 / 10) * (9 / 10) = 99 := by norm_num
-- Half in a share up 10%, half in one down 10%: the portfolio keeps its $100.
example : (50 : ℚ) * (11 / 10) + 50 * (9 / 10) = 100 := by norm_num
-- Twelve up-or-down months give 4,096 possible years.
example : 2 ^ 12 = 4096 := by norm_num
-- A year of six up-down pairs ends at $100 × 0.99^6 = $94.1480149401.
example : (100 : ℚ) * (99 / 100) ^ 6 = 941480149401 / 10 ^ 10 := by norm_num
-- Up 20% then down 20% leaves $96; up 50% then down 50% leaves $75.
example : (100 : ℚ) * (6 / 5) * (4 / 5) = 96 := by norm_num
example : (100 : ℚ) * (3 / 2) * (1 / 2) = 75 := by norm_num
-- 2026 (1 January a Thursday) has 261 weekdays; less 10 NYSE holidays, 251 trading days.
set_option maxRecDepth 100000 in
example : ((range 365).filter (fun d => (3 + d) % 7 < 5)).card = 261 := by decide
example : 261 - 10 = 251 := by norm_num

#print axioms log_returns_add_over_time
#print axioms log_return_spread_scales_with_sqrt_time
#print axioms up_then_down_loses_the_square
