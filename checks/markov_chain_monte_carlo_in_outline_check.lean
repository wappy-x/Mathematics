-- MCMC in outline: the Metropolis walk on a finite set of states, with a symmetric proposal, is a genuine Markov chain that keeps the posterior at rest, balances flows between every pair of states, and never needs the normalising constant.
import Mathlib.Algebra.BigOperators.Field
import Mathlib.Basic.Real.Basic
import Mathlib.Data.Int.Interval
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Tactic.NormNum

open Finset

/-- The Metropolis move chance on a finite set of states `ι`. `w i` is the posterior height at
state `i` (prior times likelihood, constant unknown) and `Q i k` is the chance of proposing `k`
from `i`. A move to `k ≠ i` happens with chance `Q i k * min 1 (w k / w i)`; the chance of
staying at `i` is whatever is left over. -/
noncomputable def metropolis {ι : Type*} [Fintype ι] [DecidableEq ι]
    (w : ι → ℝ) (Q : ι → ι → ℝ) (i k : ι) : ℝ :=
  if k = i then 1 - ∑ j ∈ univ.erase i, Q i j * min 1 (w j / w i)
  else Q i k * min 1 (w k / w i)

/-- Helper: for positive heights, `a * min 1 (b / a) = min a b`. -/
theorem metropolis_mul_min_ratio (a b : ℝ) (ha : 0 < a) : a * min 1 (b / a) = min a b := by
  rw [mul_min_of_nonneg _ _ ha.le, mul_one, mul_div_cancel₀ _ ha.ne']

/-- Helper: detailed balance without the normalising division. -/
theorem metropolis_flow_symm {ι : Type*} [Fintype ι] [DecidableEq ι]
    (w : ι → ℝ) (hw : ∀ i, 0 < w i)
    (Q : ι → ι → ℝ) (hsymm : ∀ i k, Q i k = Q k i) (i k : ι) :
    w i * metropolis w Q i k = w k * metropolis w Q k i := by
  unfold metropolis
  by_cases h : k = i
  · subst h; rfl
  · rw [ite_eq_right h, ite_eq_right (Ne.symm h)]
    have h1 : w i * (Q i k * min 1 (w k / w i)) = Q i k * (w i * min 1 (w k / w i)) := by ring
    have h2 : w k * (Q k i * min 1 (w i / w k)) = Q k i * (w k * min 1 (w i / w k)) := by ring
    rw [h1, h2, metropolis_mul_min_ratio _ _ (hw i), metropolis_mul_min_ratio _ _ (hw k),
      hsymm i k, min_comm]

#print axioms metropolis_mul_min_ratio
#print axioms metropolis_flow_symm

/-- A random walk that proposes moves symmetrically (a step from `i` to `k` is exactly as likely
as a step from `k` to `i`), always accepts uphill moves, and accepts downhill moves with chance
equal to the ratio of posterior heights, is a genuine Markov chain (move chances are at least 0
and add to 1 from every state), and the posterior, each state's height divided by the total, is
its resting state: one step of the walk applied to the posterior gives back the posterior. -/
theorem metropolis_posterior_is_stationary {ι : Type*} [Fintype ι] [DecidableEq ι]
    (w : ι → ℝ) (hw : ∀ i, 0 < w i)
    (Q : ι → ι → ℝ) (hQ0 : ∀ i k, 0 ≤ Q i k) (hQ1 : ∀ i, ∑ k, Q i k = 1)
    (hsymm : ∀ i k, Q i k = Q k i) :
    (∀ i k, 0 ≤ metropolis w Q i k) ∧
    (∀ i, ∑ k, metropolis w Q i k = 1) ∧
    (∀ k, ∑ i, (w i / ∑ j, w j) * metropolis w Q i k = w k / ∑ j, w j) := by
  have hm : ∀ i j, 0 ≤ min 1 (w j / w i) := fun i j =>
    le_min zero_le_one (div_nonneg (hw j).le (hw i).le)
  have hle : ∀ i j, min 1 (w j / w i) ≤ 1 := fun i j => min_le_left _ _
  have hnn : ∀ i k, 0 ≤ metropolis w Q i k := by
    intro i k
    unfold metropolis
    split_ifs with h
    · have hs : ∑ j ∈ univ.erase i, Q i j * min 1 (w j / w i) ≤ ∑ j, Q i j := by
        calc ∑ j ∈ univ.erase i, Q i j * min 1 (w j / w i)
            ≤ ∑ j ∈ univ.erase i, Q i j :=
              sum_le_sum fun j _ => mul_le_of_le_one_right (hQ0 i j) (hle i j)
          _ ≤ ∑ j, Q i j := sum_le_sum_of_subset_of_nonneg (erase_subset _ _)
              fun j _ _ => hQ0 i j
      rw [hQ1 i] at hs
      linarith
    · exact mul_nonneg (hQ0 i k) (hm i k)
  have hrow : ∀ i, ∑ k, metropolis w Q i k = 1 := by
    intro i
    rw [← add_sum_erase _ _ (mem_univ i)]
    have : ∑ k ∈ univ.erase i, metropolis w Q i k
        = ∑ k ∈ univ.erase i, Q i k * min 1 (w k / w i) :=
      sum_congr rfl fun k hk => by
        unfold metropolis; rw [ite_eq_right (ne_of_mem_erase hk)]
    rw [this]
    unfold metropolis
    rw [ite_eq_left rfl]
    ring
  refine ⟨hnn, hrow, fun k => ?_⟩
  have hb : ∀ i, (w i / ∑ j, w j) * metropolis w Q i k
      = (w k / ∑ j, w j) * metropolis w Q k i := fun i => by
    rw [div_mul_eq_mul_div, div_mul_eq_mul_div, metropolis_flow_symm w hw Q hsymm i k]
  rw [sum_congr rfl fun i _ => hb i, ← mul_sum, hrow k, mul_one]

/-- Detailed balance: with a symmetric proposal, a crowd spread like the posterior sends as many
walkers from `i` to `k` in one step as from `k` to `i`. -/
theorem metropolis_detailed_balance {ι : Type*} [Fintype ι] [DecidableEq ι]
    (w : ι → ℝ) (hw : ∀ i, 0 < w i)
    (Q : ι → ι → ℝ) (hsymm : ∀ i k, Q i k = Q k i) (i k : ι) :
    (w i / ∑ j, w j) * metropolis w Q i k = (w k / ∑ j, w j) * metropolis w Q k i := by
  rw [div_mul_eq_mul_div, div_mul_eq_mul_div, metropolis_flow_symm w hw Q hsymm i k]

/-- Only ratios are needed, so the constant cancels: multiplying every height by the same
positive constant (for example `1 / Z`, turning heights into the true posterior density) leaves
every move chance of the walk unchanged. -/
theorem metropolis_ignores_normalising_constant {ι : Type*} [Fintype ι] [DecidableEq ι]
    (w : ι → ℝ) (Q : ι → ι → ℝ) (c : ℝ) (hc : 0 < c) :
    metropolis (fun i => c * w i) Q = metropolis w Q := by
  funext i k
  unfold metropolis
  simp only [mul_div_mul_left _ _ hc.ne']

-- The exact tail: 232 of the 2048 outcomes of 11 fair flips have 8 or more heads.
example : ∑ k ∈ Icc 8 11, Nat.choose 11 k = 232 := by decide
example : (2 : ℕ) ^ 11 = 2048 := by norm_num
-- P(p > 0.5) for Beta(8, 4) is 1 - 232/2048 = 227/256 = 0.88671875, printed as 0.886719.
example : (1 : ℚ) - 232 / 2048 = 227 / 256 := by norm_num
-- The normalising constant: Z = 7! 3! / 11! = 1 / (4 * C(11, 4)) = 1 / 1320.
example : Nat.factorial 11 = 1320 * (Nat.factorial 7 * Nat.factorial 3) := by decide
example : 4 * Nat.choose 11 4 = 1320 := by decide
example : ((Nat.factorial 7 * Nat.factorial 3 : ℕ) : ℚ) / (Nat.factorial 11 : ℕ) = 1 / 1320 := by
  norm_num [Nat.factorial]
-- The Beta(8, 4) mean 8/12 = 2/3 and variance 8 * 4 / (12^2 * 13) = 32/1872.
example : (8 : ℚ) / 12 = 2 / 3 := by norm_num
example : (8 * 4 : ℚ) / (12 ^ 2 * 13) = 32 / 1872 := by norm_num
-- The grid walk proposes each of the 20 states i ± 1, ..., i ± 10 with chance 1/20.
example : ((Finset.Icc (-10 : ℤ) 10).erase 0).card = 20 := by decide

#print axioms metropolis_posterior_is_stationary
#print axioms metropolis_detailed_balance
#print axioms metropolis_ignores_normalising_constant
