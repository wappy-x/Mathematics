-- MCMC as a tool: the Metropolis rule with independent bell-curve steps sends as much posterior weight from any point to any other as flows back, the step's chance is the same in both directions, and the unknown constant cancels from the acceptance chance.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.MeasureTheory.Function.L1Space.Integrable

open MeasureTheory ProbabilityTheory
open scoped NNReal

/-- The chance density of proposing `θ'` from `θ` when every unknown `i` is nudged by its own
step `s i` times a fresh standard bell-curve draw: `θ'ᵢ = θᵢ + sᵢ zᵢ`. -/
noncomputable def proposalDensity {d : ℕ} (s : Fin d → ℝ≥0) (θ θ' : Fin d → ℝ) : ℝ :=
  ∏ i, gaussianPDFReal 0 (s i ^ 2) (θ' i - θ i)

/-- The Metropolis acceptance chance `α = min(1, f(θ') / f(θ))`. -/
noncomputable def acceptance {d : ℕ} (f : (Fin d → ℝ) → ℝ) (θ θ' : Fin d → ℝ) : ℝ :=
  min 1 (f θ' / f θ)

/-- Helper: for nonnegative `a`, `b`, the flow `a * min(1, b/a)` equals `min a b`. -/
lemma mul_min_one_div_eq_min (a b : ℝ) (ha : 0 ≤ a) (hb : 0 ≤ b) :
    a * min 1 (b / a) = min a b := by
  rcases ha.eq_or_lt with h | h
  · subst h; simp [hb]
  · rw [mul_min_of_nonneg _ _ h.le, mul_one, mul_div_cancel₀ _ h.ne']

/-- Card claim (Step 0): for a posterior height `f` (nonnegative, finite total weight) on the
`d` unknowns, and a random walk that moves each unknown by its own nonzero frozen step times a
bell-curve draw and accepts with chance `min(1, f(θ')/f(θ))`, as much probability flows from any
point `θ` to any other point `θ'` as flows back (detailed balance), so the posterior is the walk's
equilibrium. -/
theorem metropolis_flow_balanced {d : ℕ} (f : (Fin d → ℝ) → ℝ) (hf : ∀ θ, 0 ≤ f θ)
    (hfint : Integrable f) (s : Fin d → ℝ≥0) (hs : ∀ i, s i ≠ 0) (θ θ' : Fin d → ℝ) :
    f θ * proposalDensity s θ θ' * acceptance f θ θ' =
      f θ' * proposalDensity s θ' θ * acceptance f θ' θ := by
  have hsym : proposalDensity s θ' θ = proposalDensity s θ θ' := by
    unfold proposalDensity
    refine Finset.prod_congr rfl fun i _ => ?_
    simp only [gaussianPDFReal]
    ring_nf
  rw [hsym, acceptance, acceptance, mul_right_comm, mul_min_one_div_eq_min _ _ (hf θ) (hf θ'),
    mul_right_comm (f θ'), mul_min_one_div_eq_min _ _ (hf θ') (hf θ), min_comm]

/-- Card claim: a bell-curve step from `θ` to `θ'` is exactly as likely as the reverse step, so
the Hastings correction for lopsided proposals is 1. -/
theorem bell_curve_step_symmetric {d : ℕ} (s : Fin d → ℝ≥0) (θ θ' : Fin d → ℝ) :
    proposalDensity s θ θ' = proposalDensity s θ' θ := by
  unfold proposalDensity
  refine Finset.prod_congr rfl fun i _ => ?_
  simp only [gaussianPDFReal]
  ring_nf

/-- Card claim: the posterior is known only up to a constant, and that constant cancels from the
acceptance chance: scaling the height `f` by any `C > 0` leaves `min(1, f(θ')/f(θ))` unchanged. -/
theorem acceptance_ignores_constant {d : ℕ} (f : (Fin d → ℝ) → ℝ) (C : ℝ) (hC : 0 < C)
    (θ θ' : Fin d → ℝ) :
    acceptance (fun x => C * f x) θ θ' = acceptance f θ θ' := by
  simp only [acceptance]
  rw [mul_div_mul_left _ _ hC.ne']

-- Worked numbers from the card, whole numbers and exact fractions only.
-- 70 wet days of 200 leaves 130 dry days.
example : (200 : ℕ) - 70 = 130 := by norm_num
-- Exact posterior mean of p under the flat prior: (70 + 1) / (200 + 2) = 71/202.
example : ((70 + 1 : ℚ) / (200 + 2)) = 71 / 202 := by norm_num
-- Exact posterior variance of p: 71 × 131 / (202² × 203).
example : ((71 * 131 : ℚ) / (202 ^ 2 * 203)) = 9301 / 8283212 := by norm_num
-- Steps ten times smaller need 10 × 10 = 100 times as many steps.
example : (10 : ℕ) * 10 = 100 := by norm_num
-- 12,000 steps per chain, 2,000 burn-in: 10,000 kept; four chains: 40,000 kept draws.
example : (12000 : ℕ) - 2000 = 10000 := by norm_num
example : (4 : ℕ) * 10000 = 40000 := by norm_num
-- Batch means: 25 batches of 400 steps fill a 10,000-step chain; 4 chains give 100 batch averages.
example : (25 : ℕ) * 400 = 10000 := by norm_num
example : (4 : ℕ) * 25 = 100 := by norm_num
-- The grid for (k, c): 161 × 361 pairs.
example : (161 : ℕ) * 361 = 58121 := by norm_num

#print axioms mul_min_one_div_eq_min
#print axioms metropolis_flow_balanced
#print axioms bell_curve_step_symmetric
#print axioms acceptance_ignores_constant
