-- Tomorrow's volatility: the expected GARCH(1,1) forecast closes its gap to the long-run level by the factor alpha + beta each day, the EWMA forecast is a weighted average whose weights sum to one, and the QLIKE penalty is never negative and is zero exactly when forecast and measurement match.
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum

open Finset

/-- Helper: the EWMA recursion unrolled `n` steps. -/
theorem ewma_unrolled_helper
    (lam : ℝ) (e r : ℕ → ℝ)
    (hstep : ∀ t, 1 ≤ t → e (t + 1) = lam * e t + (1 - lam) * r t ^ 2) (n : ℕ) :
    e (n + 1) = lam ^ n * e 1 + (1 - lam) * ∑ j ∈ Icc 1 n, lam ^ (n - j) * r j ^ 2 := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [hstep (n + 1) (by omega), ih, Finset.sum_Icc_succ_top (by omega)]
    have hs : ∑ j ∈ Icc 1 n, lam ^ (n + 1 - j) * r j ^ 2
        = lam * ∑ j ∈ Icc 1 n, lam ^ (n - j) * r j ^ 2 := by
      rw [Finset.mul_sum]
      refine Finset.sum_congr rfl fun j hj => ?_
      have hj' := (Finset.mem_Icc.mp hj).2
      rw [show n + 1 - j = (n - j) + 1 by omega, pow_succ]
      ring
    rw [hs, Nat.sub_self, pow_zero]
    ring

/-- The k-day GARCH(1,1) forecast. If the expected forecasts `M k` for `k` days ahead
obey `M (k+1) = ω + α M k + β M k` (the step from the tower property), and
`α + β < 1`, then with `ρ = α + β` and long-run level `h̄ = ω / (1 - ρ)`,
the expected forecast `k` days out is `h̄ + ρ^(k-1) (M 1 - h̄)`: the gap to the
long-run level shrinks by the factor `ρ` each day. -/
theorem garch_expected_forecast_term_structure
    (ω α β : ℝ) (M : ℕ → ℝ)
    (hρ : α + β < 1)
    (hstep : ∀ k, 1 ≤ k → M (k + 1) = ω + α * M k + β * M k) :
    ∀ k, 1 ≤ k →
      M k = ω / (1 - (α + β)) + (α + β) ^ (k - 1) * (M 1 - ω / (1 - (α + β))) := by
  intro k hk
  have hne : (1 - (α + β)) ≠ 0 := by linarith
  have hω : ω = (1 - (α + β)) * (ω / (1 - (α + β))) := by field_simp
  induction k, hk using Nat.le_induction with
  | base => simp
  | succ n hn ih =>
    rw [hstep n hn, ih]
    obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
    rw [show m + 1 + 1 - 1 = m + 1 by omega, show m + 1 - 1 = m by omega, pow_succ]
    set h := ω / (1 - (α + β))
    rw [hω]
    ring

/-- EWMA unrolled. If `e (t+1) = λ e t + (1 - λ) r_t²` for every day `t ≥ 1`, then after
`n` days `e (n+1) = λ^n e 1 + (1 - λ) Σ_{j=1}^{n} λ^(n-j) r_j²`, and the seed's weight
`λ^n` and the squares' weights add up to exactly 1. -/
theorem ewma_unrolled_weighted_average
    (lam : ℝ) (e r : ℕ → ℝ)
    (hstep : ∀ t, 1 ≤ t → e (t + 1) = lam * e t + (1 - lam) * r t ^ 2) (n : ℕ) :
    e (n + 1) = lam ^ n * e 1 + (1 - lam) * ∑ j ∈ Icc 1 n, lam ^ (n - j) * r j ^ 2 ∧
    lam ^ n + (1 - lam) * ∑ j ∈ Icc 1 n, lam ^ (n - j) = 1 := by
  refine ⟨ewma_unrolled_helper lam e r hstep n, ?_⟩
  have h := ewma_unrolled_helper lam (fun _ => 1) (fun _ => 1)
    (fun t _ => by ring) n
  simpa using h.symm

/-- The QLIKE penalty on one day, `x - ln x - 1` with `x = RV / f` the ratio of measured
to forecast variance, is never negative for positive numbers, and it is zero exactly when
the two match (`x = 1`). -/
theorem qlike_penalty_nonneg_and_zero_iff_match (RV f : ℝ) (hRV : 0 < RV) (hf : 0 < f) :
    0 ≤ RV / f - Real.log (RV / f) - 1 ∧
    (RV / f - Real.log (RV / f) - 1 = 0 ↔ RV = f) := by
  set x := RV / f with hx
  have hxpos : 0 < x := div_pos hRV hf
  refine ⟨by linarith [Real.log_le_sub_one_of_pos hxpos], ?_⟩
  constructor
  · intro h0
    by_contra hne
    have hx1 : x ≠ 1 := by
      intro h1
      apply hne
      rw [hx, div_eq_one_iff_eq hf.ne'] at h1
      exact h1
    linarith [Real.log_lt_sub_one_of_pos hxpos hx1]
  · intro h
    rw [hx, h, div_self hf.ne', Real.log_one]
    norm_num

-- Worked numbers from the card, in percent-squared, as exact fractions.
-- EWMA for day 2: 0.94 × 2.00 + 0.06 × 1.00² = 1.94.
example : (94 / 100 : ℚ) * 2 + 6 / 100 * 1 ^ 2 = 194 / 100 := by norm_num
-- GARCH for day 2: 0.10 + 0.10 × 1.00² + 0.85 × 2.00 = 1.90.
example : (10 / 100 : ℚ) + 10 / 100 * 1 ^ 2 + 85 / 100 * 2 = 190 / 100 := by norm_num
-- Realised variance of day 1, pieces in hundredths of a percent: 55² + 5² + 40² + 10² = 4750,
-- that is 0.4750 percent-squared.
example : 55 ^ 2 + 5 ^ 2 + 40 ^ 2 + 10 ^ 2 = 4750 := by decide
-- Long-run GARCH level: 0.1000 / (1 - 0.10 - 0.85) = 2.00.
example : (10 / 100 : ℚ) / (1 - (10 / 100 + 85 / 100)) = 2 := by norm_num
-- EWMA is GARCH with α = 1 - λ and β = λ, so α + β = 1 exactly.
example : (1 - 94 / 100 : ℚ) + 94 / 100 = 1 := by norm_num

#print axioms ewma_unrolled_helper
#print axioms garch_expected_forecast_term_structure
#print axioms ewma_unrolled_weighted_average
#print axioms qlike_penalty_nonneg_and_zero_iff_match
