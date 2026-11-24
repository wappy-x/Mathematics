-- Weak solutions and the martingale problem: on any grid path B from 0, re-signing the noise W = ∑ sgn(B) ΔB rebuilds B exactly while the rebuild of −B misses by twice the steps taken at zero, the noise keeps B's clock and sees only |B|, and Tanaka's generator is f''/2.
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

open Finset

/-! Setting. Mathlib has no Brownian motion and no Ito integral, so the card's weak existence,
uniqueness in law, the lack of a strong solution, Yamada–Watanabe and Stroock–Varadhan cannot be
stated here. What can be stated exactly is the algebra under Steps 1, 2 and 4 on a time grid,
which is also what the card's code and hand table check, and the generator of Step 6.
A grid path is `B : ℕ → ℝ`, with `B k` its value after `k` steps and `B (k+1) - B k` its step.
Mathlib's `SignType.sign` and `Real.sign` give 0 at 0; the card's sign gives −1 at 0 (and
warns that `sgn(0) = 0` breaks the equation), so it is defined here. -/

/-- The card's sign: `sgn x = +1` for `x > 0` and `−1` for `x ≤ 0`. -/
noncomputable def tanakaSgn (x : ℝ) : ℝ := if 0 < x then 1 else -1

/-- One step of the card's noise built from a grid path: `ΔW_k = sgn(B_k) ΔB_k`. -/
noncomputable def noiseStep (B : ℕ → ℝ) (k : ℕ) : ℝ := tanakaSgn (B k) * (B (k + 1) - B k)

/-- The generator of `dX = μ(X) dt + σ(X) dW` on a test function `f`:
`Lf(x) = μ(x) f'(x) + ½ σ(x)² f''(x)`. -/
noncomputable def generator (μ σ f : ℝ → ℝ) (x : ℝ) : ℝ :=
  μ x * deriv f x + 1 / 2 * σ x ^ 2 * deriv (deriv f) x

/-- The card's sign squares to one. -/
theorem tanakaSgn_sq (x : ℝ) : tanakaSgn x ^ 2 = 1 := by
  unfold tanakaSgn; split_ifs <;> norm_num

/-- `x ↦ x ^ n` has derivative `n x ^ (n-1)`, as a function equality. -/
theorem deriv_fun_pow_eq (n : ℕ) : deriv (fun y : ℝ => y ^ n) = fun y => (n : ℝ) * y ^ (n - 1) := by
  funext y; simp

/-- **Two paths, one noise, on a grid** (Why it works, Steps 1 and 2; Worked numbers). Let `B` be
any grid path from 0 and build the noise from it, `ΔW_k = sgn(B_k) ΔB_k`. Re-signing the noise
by `B` rebuilds `B` exactly: `∑_{k<n} sgn(B_k) ΔW_k = B_n`. Re-signing it by `−B` rebuilds `−B`
up to twice the steps `B` takes while sitting at zero:
`∑_{k<n} sgn(−B_k) ΔW_k = −B_n + 2 ∑_{k<n, B_k = 0} ΔB_k`. -/
theorem tanaka_grid_rebuild_of_B_and_minus_B (B : ℕ → ℝ) (h0 : B 0 = 0) (n : ℕ) :
    ∑ k ∈ range n, tanakaSgn (B k) * noiseStep B k = B n ∧
      ∑ k ∈ range n, tanakaSgn (-B k) * noiseStep B k
        = -B n + 2 * ∑ k ∈ (range n).filter (fun k => B k = 0), (B (k + 1) - B k) := by
  have k1 : ∀ k, tanakaSgn (B k) * noiseStep B k = B (k + 1) - B k := by
    intro k
    have h := tanakaSgn_sq (B k)
    unfold noiseStep
    linear_combination (B (k + 1) - B k) * h
  have k2 : ∀ k, tanakaSgn (-B k) * noiseStep B k
      = -(B (k + 1) - B k) + 2 * (if B k = 0 then B (k + 1) - B k else 0) := by
    intro k
    unfold noiseStep tanakaSgn
    rcases lt_trichotomy (B k) 0 with h | h | h
    · have h1 : B k ≠ 0 := ne_of_lt h
      have h2 : 0 < -B k := by linarith
      have h3 : ¬ 0 < B k := by linarith
      simp only [h1, h2, h3, ite_true, ite_false]; ring
    · simp only [h, neg_zero, lt_irrefl, ite_true, ite_false]; ring
    · have h1 : B k ≠ 0 := ne_of_gt h
      have h2 : ¬ 0 < -B k := by linarith
      simp only [h1, h2, h, ite_true, ite_false]; ring
  constructor
  · rw [sum_congr rfl (fun k _ => k1 k), sum_range_sub, h0, sub_zero]
  · rw [sum_congr rfl (fun k _ => k2 k), sum_add_distrib, ← mul_sum, sum_filter,
      sum_neg_distrib, sum_range_sub, h0, sub_zero]

/-- **The noise keeps the clock and sees only the size** (Step 1 on the grid; Step 4; road 2 of
the code). For any grid path `B`, the noise built from it has the same summed squared steps,
`∑_{k<n} (ΔW_k)² = ∑_{k<n} (ΔB_k)²`, and every step of `|B| − W` (the discrete local time) is at
least 0: `sgn(B_k) ΔB_k ≤ |B_{k+1}| − |B_k|`. -/
theorem tanaka_noise_keeps_clock_and_local_time_grows (B : ℕ → ℝ) (n : ℕ) :
    ∑ k ∈ range n, noiseStep B k ^ 2 = ∑ k ∈ range n, (B (k + 1) - B k) ^ 2 ∧
      ∀ k, noiseStep B k ≤ |B (k + 1)| - |B k| := by
  constructor
  · refine sum_congr rfl (fun k _ => ?_)
    have h := tanakaSgn_sq (B k)
    unfold noiseStep
    linear_combination (B (k + 1) - B k) ^ 2 * h
  · intro k
    unfold noiseStep tanakaSgn
    split_ifs with h
    · rw [abs_of_pos h]; have := le_abs_self (B (k + 1)); linarith
    · rw [abs_of_nonpos (not_lt.mp h)]; have := neg_abs_le (B (k + 1)); linarith

/-- **Tanaka's generator is Brownian motion's** (The formula; Step 6). With no drift and noise
size `sgn`, `σ² = 1` everywhere, so `Lf = ½ f''` for every test function `f`; on the card's test
functions, `L(x²) = 1` and `L(x⁴) = 6x²`. -/
theorem tanaka_generator_eq_half_second_derivative :
    (∀ (f : ℝ → ℝ) (x : ℝ), generator (fun _ => 0) tanakaSgn f x = 1 / 2 * deriv (deriv f) x) ∧
      (∀ x : ℝ, generator (fun _ => 0) tanakaSgn (fun y => y ^ 2) x = 1) ∧
      (∀ x : ℝ, generator (fun _ => 0) tanakaSgn (fun y => y ^ 4) x = 6 * x ^ 2) := by
  have hg : ∀ (f : ℝ → ℝ) (x : ℝ), generator (fun _ => 0) tanakaSgn f x = 1 / 2 * deriv (deriv f) x := by
    intro f x
    unfold generator
    rw [tanakaSgn_sq]; ring
  refine ⟨hg, fun x => ?_, fun x => ?_⟩
  · rw [hg, deriv_fun_pow_eq]
    norm_num
  · rw [hg, deriv_fun_pow_eq]
    norm_num
    ring

/-! The card's hand path, exactly: quarter-year steps 0.30, −0.50, 0.40, 0.60 from 0. -/

/-- The hand path: 0, 0.30, −0.20, 0.20, 0.80. -/
noncomputable def handB : ℕ → ℝ
  | 0 => 0
  | 1 => 3 / 10
  | 2 => -1 / 5
  | 3 => 1 / 5
  | _ => 4 / 5

-- Signs at the step starts: −1, 1, −1, 1.
example : tanakaSgn (handB 0) = -1 ∧ tanakaSgn (handB 1) = 1 ∧ tanakaSgn (handB 2) = -1 ∧
    tanakaSgn (handB 3) = 1 := by
  norm_num [tanakaSgn, handB]
-- Noise steps −0.30, −0.50, −0.40, 0.60.
example : noiseStep handB 0 = -3 / 10 ∧ noiseStep handB 1 = -1 / 2 ∧ noiseStep handB 2 = -2 / 5 ∧
    noiseStep handB 3 = 3 / 5 := by
  norm_num [noiseStep, tanakaSgn, handB]
-- The noise ends the year at W_1 = −0.60.
example : ∑ k ∈ range 4, noiseStep handB k = -3 / 5 := by
  norm_num [sum_range_succ, noiseStep, tanakaSgn, handB]
-- Summed squared steps: 0.8600 for W and for B.
example : ∑ k ∈ range 4, noiseStep handB k ^ 2 = 43 / 50 ∧
    ∑ k ∈ range 4, (handB (k + 1) - handB k) ^ 2 = 43 / 50 := by
  norm_num [sum_range_succ, noiseStep, tanakaSgn, handB]
-- Rebuild of B: 0.8000 = B_1.
example : ∑ k ∈ range 4, tanakaSgn (handB k) * noiseStep handB k = 4 / 5 := by
  norm_num [sum_range_succ, noiseStep, tanakaSgn, handB]
-- Rebuild of −B on the grid: −0.2000 against −0.8000, a gap of 0.6000 = 2 × 0.30.
example : ∑ k ∈ range 4, tanakaSgn (-handB k) * noiseStep handB k = -1 / 5 ∧
    (-1 / 5 : ℝ) - (-4 / 5) = 2 * (3 / 10) := by
  norm_num [sum_range_succ, noiseStep, tanakaSgn, handB]

#print axioms tanakaSgn_sq
#print axioms deriv_fun_pow_eq
#print axioms tanaka_grid_rebuild_of_B_and_minus_B
#print axioms tanaka_noise_keeps_clock_and_local_time_grows
#print axioms tanaka_generator_eq_half_second_derivative
