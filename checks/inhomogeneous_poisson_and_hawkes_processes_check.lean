-- Arrivals whose rate changes: the area under a sine-wave call rate has a closed form (48 + 72/π calls to noon, 96 over a day), and a Hawkes process with branching ratio n < 1 has after-effect area n, mean cluster size 1/(1 - n) and long-run rate μ/(1 - n), the only solution of m = μ + n m.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Tactic.NormNum

/-! Notation as on the card. Time is in hours. `μ` is the Hawkes base rate, `n` the branching
ratio (calls each call triggers directly, on average), `β` the rate at which one call's
after-effect `g(s) = n β e^{-β s}` fades. For the clock-driven line the rate is
`a + b sin(2π u / P)` with period `P`; the card's switchboard has `a = 4`, `b = 3`, `P = 24`,
and the expected count by time `t` is the area `Λ(t) = ∫₀ᵗ λ(u) du`. -/

open Real MeasureTheory Set intervalIntegral

namespace RateChanges

/-- **The Hawkes numbers** (the card's main Hawkes claim, Steps 4 and 5). Take a base rate `μ`,
a branching ratio `n` with `0 ≤ n < 1`, and a fading rate `β > 0`. Then:
the area under one call's after-effect `g(s) = n β e^{-β s}` is `n`, so each call triggers
`n` calls directly on average; generation `k` of a cluster has `n^k` members on average and
the mean cluster size is `1 + n + n² + ⋯ = 1/(1 - n)`; the long-run rate, immigrants at rate
`μ` times the mean cluster, is `μ n⁰ + μ n¹ + ⋯ = μ/(1 - n)`; and this rate is the one and
only solution of the steady-rate equation `m = μ + n m`. -/
theorem hawkes_cluster_size_and_long_run_rate (μ n β : ℝ) (hn0 : 0 ≤ n) (hn1 : n < 1)
    (hβ : 0 < β) :
    (∫ s in Ioi (0 : ℝ), n * β * exp (-β * s)) = n ∧
      HasSum (fun k : ℕ => n ^ k) (1 / (1 - n)) ∧
      HasSum (fun k : ℕ => μ * n ^ k) (μ / (1 - n)) ∧
      ∀ m : ℝ, m = μ + n * m ↔ m = μ / (1 - n) := by
  have hne : (1 - n) ≠ 0 := by linarith
  refine ⟨?_, ?_, ?_, ?_⟩
  · rw [MeasureTheory.integral_const_mul, integral_exp_mul_Ioi (by linarith) 0]
    simp
    field_simp
  · rw [one_div]
    exact hasSum_geometric_of_lt_one hn0 hn1
  · have h := (hasSum_geometric_of_lt_one hn0 hn1).mul_left μ
    simpa [div_eq_mul_inv] using h
  · intro m
    constructor
    · intro h
      field_simp
      linarith
    · intro h
      rw [h]
      field_simp
      ring

/-- **The expected count is the area under the rate, in closed form** (Step 2, in general).
For a rate that swings as `a + b sin(2π u / P)` with period `P > 0`, the area under it from
time 0 to time `t` is `Λ(t) = a t + b (P/(2π)) (1 - cos(2π t / P))`. -/
theorem area_under_sine_rate (a b P t : ℝ) (hP : 0 < P) :
    ∫ u in (0 : ℝ)..t, (a + b * sin (2 * π * u / P)) =
      a * t + b * (P / (2 * π)) * (1 - cos (2 * π * t / P)) := by
  have hc : (2 * π / P) ≠ 0 := by positivity
  have hderiv : ∀ x ∈ uIcc (0 : ℝ) t, HasDerivAt
      (fun u => a * u - b * (P / (2 * π)) * cos (2 * π * u / P))
      (a + b * sin (2 * π * x / P)) x := by
    intro x _
    have h1 : HasDerivAt (fun u : ℝ => 2 * π * u / P) (2 * π / P) x := by
      have := ((hasDerivAt_id x).const_mul (2 * π)).div_const P
      simpa using this
    have h2 := (h1.cos).const_mul (b * (P / (2 * π)))
    have h3 : HasDerivAt (fun u => a * u - b * (P / (2 * π)) * cos (2 * π * u / P))
        (a * 1 - b * (P / (2 * π)) * (-sin (2 * π * x / P) * (2 * π / P))) x :=
      ((hasDerivAt_id' x).const_mul a).sub h2
    convert h3 using 1
    have hπ : π ≠ 0 := pi_ne_zero
    have hP' : P ≠ 0 := hP.ne'
    field_simp
    ring
  rw [integral_eq_sub_of_hasDerivAt hderiv]
  · simp
    ring
  · apply Continuous.intervalIntegrable
    fun_prop

/-- **The switchboard's expected calls** (the card's worked example). For the rate
`4 + 3 sin(2π t/24)` calls an hour, the expected count from midnight to noon is
`48 + 72/π` (about 70.9183), and over the full 24 hours the hump and the dip cancel,
leaving exactly 96, the same as a flat 4 an hour. -/
theorem switchboard_expected_calls :
    (∫ u in (0 : ℝ)..12, (4 + 3 * sin (2 * π * u / 24))) = 48 + 72 / π ∧
      (∫ u in (0 : ℝ)..24, (4 + 3 * sin (2 * π * u / 24))) = 96 := by
  have h1 := area_under_sine_rate 4 3 24 12 (by norm_num)
  have h2 := area_under_sine_rate 4 3 24 24 (by norm_num)
  have e1 : 2 * π * 12 / 24 = π := by ring
  have e2 : 2 * π * 24 / 24 = 2 * π := by ring
  rw [e1, cos_pi] at h1
  rw [e2, cos_two_pi] at h2
  refine ⟨?_, ?_⟩
  · rw [h1]
    field_simp
    ring
  · rw [h2]
    ring

end RateChanges

-- Base part to noon: 4 an hour for 12 hours.
example : (4 : ℕ) * 12 = 48 := by norm_num
-- Proposals at the peak rate: 7 an hour for 12 hours.
example : (7 : ℕ) * 12 = 84 := by norm_num
-- Each call lifts the rate by n β = 0.5 × 2 = 1 call an hour.
example : (1 / 2 : ℚ) * 2 = 1 := by norm_num
-- Hawkes long-run rate: 2/(1 - 0.5) = 4 an hour.
example : (2 : ℚ) / (1 - 1 / 2) = 4 := by norm_num
-- Mean cluster size: 1/(1 - 0.5) = 2 calls; 2 immigrants an hour times 2 calls each is 4.
example : (1 : ℚ) / (1 - 1 / 2) = 2 ∧ (2 : ℚ) * 2 = 4 := by norm_num
-- The fixed point: 4 = 2 + 0.5 × 4.
example : (4 : ℚ) = 2 + 1 / 2 * 4 := by norm_num
-- Partial sums of the series 1 + 0.5 + 0.25 + ...: 1, 1.5, 1.75, 1.875, 1.9375, 1.96875.
example : (1 : ℚ) + 1 / 2 = 3 / 2 ∧ (1 : ℚ) + 1 / 2 + 1 / 4 = 7 / 4 ∧
    (1 : ℚ) + 1 / 2 + 1 / 4 + 1 / 8 = 15 / 8 ∧
    (1 : ℚ) + 1 / 2 + 1 / 4 + 1 / 8 + 1 / 16 = 31 / 16 ∧
    (1 : ℚ) + 1 / 2 + 1 / 4 + 1 / 8 + 1 / 16 + 1 / 32 = 63 / 32 := by norm_num
-- Rate by generation, 2 × 0.5^k: 2, 1, 0.5, 0.25, 0.125 calls an hour, adding to 3.875 of the 4.
example : (2 : ℚ) * (1 / 2) ^ 0 = 2 ∧ (2 : ℚ) * (1 / 2) ^ 1 = 1 ∧ (2 : ℚ) * (1 / 2) ^ 2 = 1 / 2 ∧
    (2 : ℚ) * (1 / 2) ^ 3 = 1 / 4 ∧ (2 : ℚ) * (1 / 2) ^ 4 = 1 / 8 ∧
    (2 : ℚ) + 1 + 1 / 2 + 1 / 4 + 1 / 8 = 31 / 8 := by norm_num
-- Cluster-size variance n/(1 - n)³ = 0.5/0.125 = 4, and the long-window variance per hour
-- 2 × E[S²] = 2 × (4 + 2²) = 16.
example : (1 / 2 : ℚ) / (1 - 1 / 2) ^ 3 = 4 ∧ (2 : ℚ) * (4 + 2 ^ 2) = 16 := by norm_num
-- The mistake of counting only the first generation: 2 × (1 + 0.5) = 3, not 4.
example : (2 : ℚ) * (1 + 1 / 2) = 3 := by norm_num
-- At n = 0.9: the rate is 2/0.1 = 20 an hour and the mean cluster 1/0.1 = 10 calls.
example : (2 : ℚ) / (1 - 9 / 10) = 20 ∧ (1 : ℚ) / (1 - 9 / 10) = 10 := by norm_num

namespace RateChanges

#print axioms hawkes_cluster_size_and_long_run_rate
#print axioms area_under_sine_rate
#print axioms switchboard_expected_calls

end RateChanges
