-- Decision trees and forests: a split never raises the size-weighted Gini impurity or entropy (the Gini drop is exactly 2w(1 - w)(p_L - p_R)^2), an average of B equally correlated tree votes has variance ρσ² + (1 - ρ)σ²/B, and the share a bootstrap sample leaves out, (1 - 1/n)^n, tends to 1/e.
import Mathlib.Probability.Moments.Variance
import Mathlib.Analysis.SpecialFunctions.Complex.LogBounds
import Mathlib.Analysis.SpecialFunctions.Log.Base
import Mathlib.Analysis.SpecialFunctions.BinaryEntropy

open MeasureTheory ProbabilityTheory Filter Topology

/-- The Gini impurity of a node whose share of returned orders is `p`:
one minus the squared shares of each outcome. -/
noncomputable def gini (p : ℝ) : ℝ := 1 - p ^ 2 - (1 - p) ^ 2

/-- The binary entropy of a node whose share of returned orders is `p`, in bits. -/
noncomputable def entropyBits (p : ℝ) : ℝ :=
  -p * Real.logb 2 p - (1 - p) * Real.logb 2 (1 - p)

/-- A split never makes things worse. A node with share returned `p = w p_L + (1 - w) p_R`
is split into a yes branch holding the share `w` of its orders, with share returned `p_L`,
and a no branch with share returned `p_R`. Then the Gini drop is exactly
`2 w (1 - w) (p_L - p_R)^2`, so the size-weighted Gini of the branches is at most the
parent's Gini, and the same holds for the entropy in bits. -/
theorem split_never_raises_impurity (w pL pR : ℝ) (hw0 : 0 ≤ w) (hw1 : w ≤ 1)
    (hL0 : 0 ≤ pL) (hL1 : pL ≤ 1) (hR0 : 0 ≤ pR) (hR1 : pR ≤ 1) :
    gini (w * pL + (1 - w) * pR) - (w * gini pL + (1 - w) * gini pR)
        = 2 * w * (1 - w) * (pL - pR) ^ 2 ∧
      w * gini pL + (1 - w) * gini pR ≤ gini (w * pL + (1 - w) * pR) ∧
      w * entropyBits pL + (1 - w) * entropyBits pR ≤ entropyBits (w * pL + (1 - w) * pR) := by
  have hE : ∀ p : ℝ, entropyBits p = Real.binEntropy p / Real.log 2 := by
    intro p
    simp only [entropyBits, Real.binEntropy, Real.logb, Real.log_inv]
    ring
  have hlog : 0 < Real.log 2 := Real.log_pos (by norm_num)
  have hconc := Real.strictConcave_binEntropy.concaveOn.2
    (show pL ∈ Set.Icc (0 : ℝ) 1 from ⟨hL0, hL1⟩) (show pR ∈ Set.Icc (0 : ℝ) 1 from ⟨hR0, hR1⟩)
    hw0 (sub_nonneg.2 hw1) (by ring)
  simp only [smul_eq_mul] at hconc
  have hid : gini (w * pL + (1 - w) * pR) - (w * gini pL + (1 - w) * gini pR)
      = 2 * w * (1 - w) * (pL - pR) ^ 2 := by
    simp only [gini]; ring
  refine ⟨hid, ?_, ?_⟩
  · have : 0 ≤ 2 * w * (1 - w) * (pL - pR) ^ 2 := by
      have := sub_nonneg.2 hw1
      positivity
    linarith
  · rw [hE, hE, hE]
    rw [div_eq_mul_inv, div_eq_mul_inv, div_eq_mul_inv]
    have hi : 0 < (Real.log 2)⁻¹ := inv_pos.2 hlog
    nlinarith

/-- Averaging correlated votes: if each of `B ≥ 1` tree votes has variance `σ²` and every
pair of different trees has correlation `ρ` (covariance `ρ σ²`), then the forest's average
vote has variance `ρ σ² + (1 - ρ) σ² / B`. -/
theorem variance_of_average_of_correlated_votes {Ω : Type*} [MeasurableSpace Ω]
    {μ : Measure Ω} [IsProbabilityMeasure μ] {B : ℕ} (hB : 0 < B)
    (f : Fin B → Ω → ℝ) (σ ρ : ℝ) (hf : ∀ b, MemLp (f b) 2 μ)
    (hvar : ∀ b, Var[f b; μ] = σ ^ 2)
    (hcov : ∀ b c, b ≠ c → cov[f b, f c; μ] = ρ * σ ^ 2) :
    Var[fun ω => (1 / (B : ℝ)) * ∑ b, f b ω; μ] = ρ * σ ^ 2 + (1 - ρ) * σ ^ 2 / B := by
  rw [variance_const_mul, variance_fun_sum hf]
  have h : ∀ b c, cov[f b, f c; μ] = ρ * σ ^ 2 + (if b = c then (1 - ρ) * σ ^ 2 else 0) := by
    intro b c
    by_cases hbc : b = c
    · subst hbc
      rw [covariance_self (hf b).aemeasurable, hvar]
      simp; ring
    · rw [hcov b c hbc]; simp [hbc]
  simp only [h, Finset.sum_add_distrib, Finset.sum_ite_eq, Finset.mem_univ, ite_true,
    Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
  have hB' : (B : ℝ) ≠ 0 := by exact_mod_cast hB.ne'
  field_simp

/-- The share of orders a bootstrap sample of `n` draws from `n` leaves out,
`(1 - 1/n)^n`, tends to `1/e` as `n` grows. -/
theorem out_of_bag_share_tendsto_inv_e :
    Tendsto (fun n : ℕ => (1 - 1 / (n : ℝ)) ^ n) atTop (𝓝 (Real.exp (-1))) := by
  convert Real.tendsto_one_add_div_pow_exp (-1) using 2 with n
  ring

-- Ten orders, 6 returned and 4 kept: Gini 0.48.
example : gini (3 / 5) = 12 / 25 := by norm_num [gini]
-- The £50 or less group, 2 returned and 4 kept: Gini 0.4444.
example : gini (1 / 3) = 4 / 9 := by norm_num [gini]
-- The parent's share is the size-weighted average of the branches' shares.
example : (2 / 5 : ℝ) * 1 + (3 / 5) * (1 / 3) = 3 / 5 := by norm_num
-- Basket over £50: groups 4:0 and 2:4, weighted Gini 0.2667.
example : (2 / 5) * gini 1 + (3 / 5) * gini (1 / 3) = 4 / 15 := by norm_num [gini]
-- The Gini drop 0.48 - 0.2667 = 0.2133 equals 2 × 0.4 × 0.6 × (2/3)^2.
example : gini (3 / 5) - 4 / 15 = 16 / 75 ∧ 2 * (2 / 5 : ℝ) * (3 / 5) * (1 - 1 / 3) ^ 2 = 16 / 75 := by
  norm_num [gini]
-- The mistake: "more than 1 item" makes groups 6:2 and 0:2; plain average 0.1875,
-- basket cut plain average 0.2222, true weighted Gini of the item cut 0.3000.
example : (gini (3 / 4) + gini 0) / 2 = 3 / 16 ∧ (gini 1 + gini (1 / 3)) / 2 = 2 / 9 ∧
    (4 / 5) * gini (3 / 4) + (1 / 5) * gini 0 = 3 / 10 := by
  norm_num [gini]
-- Pruned versions at α = 1.5: costs 5.5, 5.0, 5.5, 6.0; the one-question tree wins.
example : (4 : ℚ) + 3 / 2 * 1 = 11 / 2 ∧ (2 : ℚ) + 3 / 2 * 2 = 5 ∧
    (1 : ℚ) + 3 / 2 * 3 = 11 / 2 ∧ (0 : ℚ) + 3 / 2 * 4 = 6 := by norm_num
-- Share left out of a bootstrap sample of 10 orders: 0.9^10 = 0.3487 (to four places).
example : ((9 : ℚ) / 10) ^ 10 = 3486784401 / 10000000000 := by norm_num

#print axioms split_never_raises_impurity
#print axioms variance_of_average_of_correlated_votes
#print axioms out_of_bag_share_tendsto_inv_e
