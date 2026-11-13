-- Ito's lemma: on any grid of steps a smooth function changes by its slopes times the steps plus half its curvatures times the squared steps, up to a cubed-step remainder, with x squared splitting exactly into a left-end sum plus squared steps, and the log of a share drifting at mu minus half sigma squared.
import Mathlib.Analysis.Calculus.Taylor
import Mathlib.Analysis.SpecialFunctions.Log.Deriv

open Finset

/-! Mathlib has Brownian motion (`ProbabilityTheory.IsBrownianReal`) but no Ito integral,
so the card's formula for a general Ito process cannot be stated here. This file states the
exact, path-by-path pieces the card proves it from.

A grid path is a sequence `w : ℕ → ℝ`: `w k` is the path at the end of step `k`,
and `w (k + 1) - w k` is step `k`. Nothing about randomness is assumed: the facts below
hold on every grid and every path. -/

/-- One step of the grid: second-order Taylor expansion with a cubed-step remainder. -/
theorem ito_step_taylor_bound (f : ℝ → ℝ) (hf : ContDiff ℝ 3 f) (M : ℝ)
    (hM : ∀ x, |iteratedDeriv 3 f x| ≤ M) (a b : ℝ) :
    |f b - f a - (deriv f a * (b - a) + (1 / 2) * iteratedDeriv 2 f a * (b - a) ^ 2)|
      ≤ M / 6 * |b - a| ^ 3 := by
  rcases eq_or_ne a b with rfl | hab
  · simp
  have hcd : ContDiffOn ℝ ((2 : ℕ) + 1) f (Set.uIcc a b) := by
    norm_num; exact hf.contDiffOn
  obtain ⟨c, -, hc⟩ := taylor_mean_remainder_lagrange_iteratedDeriv hab hcd
  have hu : UniqueDiffOn ℝ (Set.uIcc a b) := uniqueDiffOn_uIcc hab
  have ha : a ∈ Set.uIcc a b := Set.left_mem_uIcc
  have hk : ∀ k : ℕ, k ≤ 3 → iteratedDerivWithin k f (Set.uIcc a b) a = iteratedDeriv k f a := by
    intro k hk
    exact iteratedDerivWithin_eq_iteratedDeriv hu
      ((hf.of_le (by exact_mod_cast hk)).contDiffAt) ha
  rw [taylor_within_apply] at hc
  simp only [Finset.sum_range_succ, Finset.sum_range_zero, smul_eq_mul] at hc
  rw [hk 0 (by norm_num), hk 1 (by norm_num), hk 2 (by norm_num), iteratedDeriv_zero,
    iteratedDeriv_one] at hc
  have key : f b - f a - (deriv f a * (b - a) + (1 / 2) * iteratedDeriv 2 f a * (b - a) ^ 2)
      = iteratedDeriv 3 f c * (b - a) ^ 3 / 6 := by
    norm_num [Nat.factorial] at hc
    linear_combination hc
  rw [key, abs_div, abs_mul, abs_pow]
  have h3 := hM c
  have : 0 ≤ |b - a| ^ 3 := by positivity
  rw [abs_of_pos (by norm_num : (0:ℝ) < 6)]
  nlinarith

#print axioms ito_step_taylor_bound

/-- Steps 1 and 2 of the card: cut the path into `n` steps. Then the change in `f`
is the sum of its slopes times the steps, plus half its curvatures times the squared
steps, with a total remainder at most `M / 6` times the sum of the cubed step sizes,
where `M` bounds the size of the third derivative of `f`. -/
theorem ito_taylor_expansion_on_grid (f : ℝ → ℝ) (hf : ContDiff ℝ 3 f) (M : ℝ)
    (hM : ∀ x, |iteratedDeriv 3 f x| ≤ M) (w : ℕ → ℝ) (n : ℕ) :
    |f (w n) - f (w 0)
        - ∑ k ∈ range n, (deriv f (w k) * (w (k + 1) - w k)
            + (1 / 2) * iteratedDeriv 2 f (w k) * (w (k + 1) - w k) ^ 2)|
      ≤ M / 6 * ∑ k ∈ range n, |w (k + 1) - w k| ^ 3 := by
  have htel : f (w n) - f (w 0) = ∑ k ∈ range n, (f (w (k + 1)) - f (w k)) :=
    (Finset.sum_range_sub (fun k => f (w k)) n).symm
  rw [htel, ← Finset.sum_sub_distrib, Finset.mul_sum]
  refine (Finset.abs_sum_le_sum_abs _ _).trans (Finset.sum_le_sum fun k _ => ?_)
  have := ito_step_taylor_bound f hf M hM (w k) (w (k + 1))
  convert this using 2

/-- Step 7 of the card, `W` squared: on every grid and every path, the final square
minus the starting square is exactly twice the left-end sum `∑ W_k ΔW_k` plus the sum
of the squared steps, with no remainder. -/
theorem sq_eq_two_left_end_sum_add_sum_sq_steps (w : ℕ → ℝ) (n : ℕ) :
    w n ^ 2 - w 0 ^ 2
      = 2 * ∑ k ∈ range n, w k * (w (k + 1) - w k) + ∑ k ∈ range n, (w (k + 1) - w k) ^ 2 := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_range_succ, Finset.sum_range_succ]
    linear_combination ih

/-- The share's log: for `f = log` with drift size `a = μ S` and kick size `b = σ S`,
the `dt` part of Ito's formula, `a f' + ½ b² f''`, is `μ - σ² / 2` at every positive price `S`. -/
theorem log_share_ito_drift (μ σ S : ℝ) (hS : 0 < S) :
    (μ * S) * deriv Real.log S + (1 / 2) * (σ * S) ^ 2 * iteratedDeriv 2 Real.log S
      = μ - σ ^ 2 / 2 := by
  have h2 : iteratedDeriv 2 Real.log S = -(S ^ 2)⁻¹ := by
    rw [iteratedDeriv_succ', iteratedDeriv_one, Real.deriv_log']
    simp
  rw [h2, Real.deriv_log]
  field_simp
  ring

/-! The card's worked numbers, as exact fractions: `σ = 0.40 = 2/5`, `μ = 0.10 = 1/10`. -/

-- kick size squared: 0.40 × 0.40 = 0.16
example : ((2 : ℚ) / 5) ^ 2 = 4 / 25 := by norm_num
-- Ito term for the log: half of 0.16 with the log's negative curvature, −0.08
example : -((1 : ℚ) / 2) * ((2 : ℚ) / 5) ^ 2 = -2 / 25 := by norm_num
-- log drift: 0.10 − 0.08 = 0.02
example : (1 : ℚ) / 10 - (1 / 2) * ((2 : ℚ) / 5) ^ 2 = 1 / 50 := by norm_num
-- where $100 sits, in spreads from the middle: −0.02 ÷ 0.40 = −0.05
example : -((1 : ℚ) / 50) / (2 / 5) = -1 / 20 := by norm_num
-- plus sign on the correction: 0.10 + 0.08 = 0.18
example : (1 : ℚ) / 10 + (1 / 2) * ((2 : ℚ) / 5) ^ 2 = 9 / 50 := by norm_num
-- wobble variance: n · 2Δt² = 2TΔt, here with T = 1 and n = 1024
example : (1024 : ℚ) * (2 * (1 / 1024) ^ 2) = 2 * 1 * (1 / 1024) := by norm_num

#print axioms ito_taylor_expansion_on_grid
#print axioms sq_eq_two_left_end_sum_add_sum_sq_steps
#print axioms log_share_ito_drift
