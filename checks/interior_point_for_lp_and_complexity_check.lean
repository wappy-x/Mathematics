-- Interior point for linear programs: a primal-dual Newton step of length α aimed at σμ cuts the gap between the prices' ceiling and the plan's profit by exactly the factor 1 − α(1 − σ), that gap is a sum of quantity-times-surplus products, and the short step's gap falls below ε within √n / 0.4 · ln(gap₀ / ε) steps.
import Mathlib.Data.Matrix.Mul
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Tactic

open Matrix

/-- The gap falls by an exact factor. Take a linear program in equality form, maximise
`c ⬝ᵥ x` subject to `A *ᵥ x = b`, `x ≥ 0`, with `m` resource rows and `n` variables. Start from a
plan `x` and prices `y` strictly inside: `A *ᵥ x = b`, surplus `s = Aᵀ *ᵥ y - c`, and every `x j`
and `s j` positive. Let `μ = (x ⬝ᵥ s) / n` be the average product and let `(dx, dy, ds)` solve
the Newton system aimed at `σ μ`: `A *ᵥ dx = 0`, `Aᵀ *ᵥ dy - ds = 0` and
`s j * dx j + x j * ds j = σ μ - x j * s j` for every `j`. Then for every step length `α`, the gap
between the new prices' ceiling and the new plan's profit, `b ⬝ᵥ y' - c ⬝ᵥ x'`, is exactly
`1 - α (1 - σ)` times the old gap `b ⬝ᵥ y - c ⬝ᵥ x`, and the same holds for the sum of products
`x' ⬝ᵥ s'`. -/
theorem newton_step_cuts_gap_by_exact_factor {m n : ℕ}
    (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) (c : Fin n → ℝ)
    (x s : Fin n → ℝ) (y : Fin m → ℝ)
    (hx : ∀ j, 0 < x j) (hs : ∀ j, 0 < s j)
    (hprimal : A *ᵥ x = b) (hdual : Aᵀ *ᵥ y - s = c)
    (σ μ : ℝ) (hμ : μ = (x ⬝ᵥ s) / n)
    (dx ds : Fin n → ℝ) (dy : Fin m → ℝ)
    (hdx : A *ᵥ dx = 0) (hds : Aᵀ *ᵥ dy - ds = 0)
    (hnewton : ∀ j, s j * dx j + x j * ds j = σ * μ - x j * s j)
    (α : ℝ) :
    b ⬝ᵥ (y + α • dy) - c ⬝ᵥ (x + α • dx) = (1 - α * (1 - σ)) * (b ⬝ᵥ y - c ⬝ᵥ x) ∧
      (x + α • dx) ⬝ᵥ (s + α • ds) = (1 - α * (1 - σ)) * (x ⬝ᵥ s) := by
  have hds' : ds = Aᵀ *ᵥ dy := (sub_eq_zero.mp hds).symm
  -- n * μ = x ⬝ᵥ s
  have hnμ : (n : ℝ) * μ = x ⬝ᵥ s := by
    rcases Nat.eq_zero_or_pos n with h | h
    · subst h; simp [dotProduct]
    · rw [hμ]; field_simp
  -- sum of Newton rows
  have hsum : s ⬝ᵥ dx + x ⬝ᵥ ds = σ * (x ⬝ᵥ s) - x ⬝ᵥ s := by
    have : s ⬝ᵥ dx + x ⬝ᵥ ds = ∑ j, (σ * μ - x j * s j) := by
      simp only [dotProduct, ← Finset.sum_add_distrib, hnewton]
    rw [this, Finset.sum_sub_distrib, Finset.sum_const, Finset.card_univ, Fintype.card_fin,
      nsmul_eq_mul, ← mul_assoc, mul_comm (n : ℝ) σ, mul_assoc, hnμ]
    simp [dotProduct]
  -- b ⬝ dy = x ⬝ ds
  have hbdy : b ⬝ᵥ dy = x ⬝ᵥ ds := by
    rw [← hprimal, hds', dotProduct_comm, dotProduct_mulVec, ← mulVec_transpose,
      dotProduct_comm]
  -- c ⬝ dx = - s ⬝ dx
  have hcdx : c ⬝ᵥ dx = - (s ⬝ᵥ dx) := by
    rw [← hdual, sub_dotProduct, mulVec_transpose, ← dotProduct_mulVec, hdx, dotProduct_zero,
      dotProduct_comm]
    ring
  -- dx ⬝ ds = 0
  have hdxds : dx ⬝ᵥ ds = 0 := by
    rw [hds', dotProduct_comm, mulVec_transpose, ← dotProduct_mulVec, hdx, dotProduct_zero]
  have hgap' : b ⬝ᵥ y - c ⬝ᵥ x = x ⬝ᵥ s := by
    subst hprimal hdual
    rw [sub_dotProduct, dotProduct_comm (A *ᵥ x) y, dotProduct_mulVec, ← mulVec_transpose,
      dotProduct_comm (Aᵀ *ᵥ y) x, sub_sub_cancel, dotProduct_comm]
  constructor
  · rw [dotProduct_add, dotProduct_add, dotProduct_smul, dotProduct_smul, smul_eq_mul,
      smul_eq_mul, hbdy, hcdx]
    linear_combination α * hsum + α * (1 - σ) * hgap'
  · rw [add_dotProduct, dotProduct_add, dotProduct_add, smul_dotProduct, smul_dotProduct,
      dotProduct_smul, dotProduct_smul, hdxds, smul_eq_mul, smul_eq_mul, smul_eq_mul,
      smul_eq_mul, dotProduct_comm dx s]
    linear_combination α * hsum

/-- The gap is a sum of products, and weak duality. If the plan satisfies `A *ᵥ x = b` and the
surplus is `s = Aᵀ *ᵥ y - c`, then the prices' ceiling minus the plan's profit equals the sum of
each quantity times its surplus, `∑ j, x j * s j`. So when `x ≥ 0` and `s ≥ 0`, every term is
non-negative and the ceiling is at least the profit. -/
theorem gap_is_sum_of_products {m n : ℕ}
    (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) (c : Fin n → ℝ)
    (x s : Fin n → ℝ) (y : Fin m → ℝ)
    (hprimal : A *ᵥ x = b) (hdual : Aᵀ *ᵥ y - s = c) :
    b ⬝ᵥ y - c ⬝ᵥ x = ∑ j, x j * s j ∧
      (0 ≤ x → 0 ≤ s → c ⬝ᵥ x ≤ b ⬝ᵥ y) := by
  have key : b ⬝ᵥ y - c ⬝ᵥ x = ∑ j, x j * s j := by
    subst hprimal hdual
    rw [sub_dotProduct, dotProduct_comm (A *ᵥ x) y, dotProduct_mulVec, ← mulVec_transpose,
      dotProduct_comm (Aᵀ *ᵥ y) x]
    rw [sub_sub_cancel, dotProduct_comm]
    rfl
  refine ⟨key, fun h0 h1 => ?_⟩
  have : 0 ≤ ∑ j, x j * s j := Finset.sum_nonneg fun j _ => mul_nonneg (h0 j) (h1 j)
  linarith

/-- The short step's count. With `n ≥ 1` variables, the short-step method uses
`σ = 1 - 0.4 / √n` and multiplies the gap by exactly `σ` each step, so after `k` steps the gap is
`σ ^ k * gap₀`. For any starting gap `gap₀ > 0` and tolerance `ε > 0`, once
`k ≥ (√n / 0.4) * ln (gap₀ / ε)`, that gap is at most `ε`. -/
theorem short_step_gap_below_tolerance (n : ℕ) (hn : 1 ≤ n)
    (gap₀ ε : ℝ) (hgap : 0 < gap₀) (hε : 0 < ε) (k : ℕ)
    (hk : Real.sqrt n / (2 / 5) * Real.log (gap₀ / ε) ≤ k) :
    (1 - (2 / 5) / Real.sqrt n) ^ k * gap₀ ≤ ε := by
  have hn' : (1 : ℝ) ≤ n := by exact_mod_cast hn
  have hsq : 1 ≤ Real.sqrt n := by rw [Real.one_le_sqrt]; exact hn'
  have hsq0 : 0 < Real.sqrt n := by linarith
  set t := (2 / 5 : ℝ) / Real.sqrt n with ht
  have ht0 : 0 < t := by positivity
  have ht1 : t ≤ 2 / 5 := by
    rw [ht, div_le_iff₀ hsq0]; nlinarith
  have h1t : 0 ≤ 1 - t := by linarith
  have hexp : (1 - t) ^ k ≤ Real.exp (-(t * k)) := by
    calc (1 - t) ^ k ≤ (Real.exp (-t)) ^ k := by
          apply pow_le_pow_left₀ h1t
          have := Real.add_one_le_exp (-t); linarith
      _ = Real.exp (-(t * k)) := by rw [← Real.exp_nat_mul]; ring_nf
  have hlog : Real.log (gap₀ / ε) ≤ t * k := by
    have : Real.log (gap₀ / ε) = t * (Real.sqrt n / (2 / 5) * Real.log (gap₀ / ε)) := by
      rw [ht]; field_simp
    rw [this]; exact mul_le_mul_of_nonneg_left hk ht0.le
  have hexp2 : Real.exp (-(t * k)) ≤ ε / gap₀ := by
    rw [show ε / gap₀ = Real.exp (- Real.log (gap₀ / ε)) by
      rw [Real.exp_neg, Real.exp_log (by positivity), inv_div]]
    exact Real.exp_le_exp.mpr (by linarith)
  calc (1 - t) ^ k * gap₀ ≤ ε / gap₀ * gap₀ := by
        apply mul_le_mul_of_nonneg_right (hexp.trans hexp2) hgap.le
    _ = ε := by field_simp

-- The workshop in equality form: rows timber (4, 2, 1, 0, 0), labour (3, 1, 0, 1, 0),
-- finish (1, 2, 0, 0, 1); stock (160, 120, 64); profits (19, 20, 0, 0, 0).
-- The start plan (10, 10, 100, 80, 34) uses the stock exactly.
example : !![(4 : ℚ), 2, 1, 0, 0; 3, 1, 0, 1, 0; 1, 2, 0, 0, 1] *ᵥ ![10, 10, 100, 80, 34] =
    ![160, 120, 64] := by
  ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_succ] <;> norm_num
-- Prices (5, 5, 5) give surplus s = Aᵀ y - c = (21, 5, 5, 5, 5).
example : (!![(4 : ℚ), 2, 1, 0, 0; 3, 1, 0, 1, 0; 1, 2, 0, 0, 1])ᵀ *ᵥ ![5, 5, 5] -
    ![19, 20, 0, 0, 0] = ![21, 5, 5, 5, 5] := by
  ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_succ] <;> norm_num
-- The start gap: 10 × 21 + 10 × 5 + (100 + 80 + 34) × 5 = 1330 = 1720 − 390; μ = 1330 / 5 = 266.
example : 10 * 21 + 10 * 5 + (100 + 80 + 34) * 5 = 1330 := by norm_num
example : (160 + 120 + 64) * 5 = 1720 ∧ 19 * 10 + 20 * 10 = 390 ∧ 1720 - 390 = 1330 := by decide
example : 1330 / 5 = 266 := by norm_num
-- The best plan (32, 16) fits all three limits and earns £928.
example : 4 * 32 + 2 * 16 ≤ 160 ∧ 3 * 32 + 1 * 16 ≤ 120 ∧ 1 * 32 + 2 * 16 ≤ 64 := by decide
example : 19 * 32 + 20 * 16 = 928 := by norm_num
-- The prices (3, 0, 7) cover tables (19) and chairs (20) and value the stock at £928.
example : 4 * 3 + 3 * 0 + 1 * 7 = 19 ∧ 2 * 3 + 1 * 0 + 2 * 7 = 20 := by decide
example : 160 * 3 + 120 * 0 + 64 * 7 = 928 := by norm_num
-- The corners and their profits: (0, 0) 0, (0, 32) 640, (32, 16) 928, (40, 0) 760.
example : 19 * 0 + 20 * 0 = 0 ∧ 19 * 0 + 20 * 32 = 640 ∧ 19 * 40 + 20 * 0 = 760 := by decide
-- Tied best plans: with chairs at £38, profit 19 x₁ + 38 x₂ = 19 (x₁ + 2 x₂) = 19 × 64 = 1216.
example : 19 * 64 = 1216 ∧ 19 * 0 + 38 * 32 = 1216 ∧ 19 * 32 + 38 * 16 = 1216 := by decide
-- Klee–Minty: Dantzig's rule takes 2^d − 1 pivots.
example : 2 ^ 2 - 1 = 3 ∧ 2 ^ 4 - 1 = 15 ∧ 2 ^ 6 - 1 = 63 ∧ 2 ^ 8 - 1 = 255 ∧
    2 ^ 10 - 1 = 1023 := by decide
example : 2 ^ 20 - 1 = 1048575 := by norm_num
example : 2 ^ 40 - 1 = 1099511627775 := by norm_num
example : 2 ^ 80 - 1 = 1208925819614629174706175 := by norm_num

#print axioms newton_step_cuts_gap_by_exact_factor
#print axioms gap_is_sum_of_products
#print axioms short_step_gap_below_tolerance
