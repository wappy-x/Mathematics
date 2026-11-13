-- Black-Litterman: the card's blend formula equals the precision-weighted (Bayes) blend, its weights are the market plus a slice of each opinion's portfolio, and one opinion at confidence c moves its portfolio's return the fraction c of the way.
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.Order.Star.Real

open Matrix

/-!
Notation, matching the card.
* `Sig : Matrix n n ℝ` is the covariance matrix Σ of the assets.
* `Om : Matrix k k ℝ` is Ω, the opinions' uncertainty (one row and column per opinion).
* `P : Matrix k n ℝ` is the pick matrix, one row per opinion.
* `q : k → ℝ` are the opinions; `piv : n → ℝ` is the implied return vector π.
* `τ` scales the prior's doubt `τ • Sig`; `δ` is risk aversion.
Matrix inverses are Mathlib's `⁻¹` on matrices.
-/

variable {n k : Type*} [Fintype n] [DecidableEq n] [Fintype k] [DecidableEq k]

/-- The card's blend, `π + τΣ Pᵀ (P τΣ Pᵀ + Ω)⁻¹ (q − Pπ)`, equals the precision form
`[(τΣ)⁻¹ + Pᵀ Ω⁻¹ P]⁻¹ [(τΣ)⁻¹ π + Pᵀ Ω⁻¹ q]`: start at the market's implied returns and
correct by the surprise, or add the two readings' precisions and weight their centres; both
give the same blended returns. Here the covariance Σ and the opinions' uncertainty Ω are
positive definite (no portfolio, and no opinion, has zero variance) and τ is positive. -/
theorem black_litterman_blend_eq_precision_form
    (Sig : Matrix n n ℝ) (Om : Matrix k k ℝ) (P : Matrix k n ℝ) (τ : ℝ)
    (piv : n → ℝ) (q : k → ℝ)
    (hSig : Sig.PosDef) (hOm : Om.PosDef) (hτ : 0 < τ) :
    piv + ((τ • Sig) * Pᵀ * (P * (τ • Sig) * Pᵀ + Om)⁻¹) *ᵥ (q - P *ᵥ piv)
      = ((τ • Sig)⁻¹ + Pᵀ * Om⁻¹ * P)⁻¹ *ᵥ ((τ • Sig)⁻¹ *ᵥ piv + (Pᵀ * Om⁻¹) *ᵥ q) := by
  set A := τ • Sig with hAdef
  have hA : A.PosDef := hSig.smul hτ
  have hM : (P * A * Pᵀ + Om).PosDef := by
    have h1 := hA.posSemidef.mul_mul_conjTranspose_same P
    rw [conjTranspose_eq_transpose_of_trivial] at h1
    exact Matrix.PosDef.posSemidef_add h1 hOm
  have hB : (A⁻¹ + Pᵀ * Om⁻¹ * P).PosDef := by
    have h1 := hOm.inv.posSemidef.conjTranspose_mul_mul_same P
    rw [conjTranspose_eq_transpose_of_trivial] at h1
    exact hA.inv.add_posSemidef h1
  set M := P * A * Pᵀ + Om with hMdef
  set B := A⁻¹ + Pᵀ * Om⁻¹ * P with hBdef
  have dA : IsUnit A.det := (isUnit_iff_isUnit_det _).mp hA.isUnit
  have dO : IsUnit Om.det := (isUnit_iff_isUnit_det _).mp hOm.isUnit
  have dM : IsUnit M.det := (isUnit_iff_isUnit_det _).mp hM.isUnit
  have dB : IsUnit B.det := (isUnit_iff_isUnit_det _).mp hB.isUnit
  have key1 : B * A * Pᵀ = Pᵀ * Om⁻¹ * M := by
    have e1 : A⁻¹ * A = 1 := nonsing_inv_mul A dA
    have e2 : Om⁻¹ * Om = 1 := nonsing_inv_mul Om dO
    rw [hBdef, hMdef, Matrix.add_mul, e1, Matrix.add_mul, Matrix.one_mul, Matrix.mul_add,
      Matrix.mul_assoc (Pᵀ) (Om⁻¹) Om, e2, Matrix.mul_one]
    simp only [Matrix.mul_assoc]
    abel
  have key : B * (A * Pᵀ * M⁻¹) = Pᵀ * Om⁻¹ := by
    rw [← Matrix.mul_assoc, ← Matrix.mul_assoc, key1, Matrix.mul_assoc, mul_nonsing_inv M dM,
      Matrix.mul_one]
  have hBv : B *ᵥ (piv + (A * Pᵀ * M⁻¹) *ᵥ (q - P *ᵥ piv)) = A⁻¹ *ᵥ piv + (Pᵀ * Om⁻¹) *ᵥ q := by
    rw [mulVec_add, mulVec_mulVec, key, mulVec_sub, mulVec_mulVec, hBdef, add_mulVec]
    abel
  rw [← hBv, mulVec_mulVec, nonsing_inv_mul B dB, one_mulVec]

/-- Back to weights: with implied returns `π = δ Σ w_m`, feeding the blend to the optimiser,
`w_BL = (δΣ)⁻¹ μ_BL`, gives the market's weights plus `λ` units of each opinion's portfolio,
`w_BL = w_m + Pᵀ λ` with `λ = (τ/δ)(P τΣ Pᵀ + Ω)⁻¹ (q − Pπ)`. No other direction appears.
Here Σ is positive definite (so it can be inverted) and the risk aversion δ is positive. -/
theorem black_litterman_weights_eq_market_plus_view_portfolios
    (Sig : Matrix n n ℝ) (Om : Matrix k k ℝ) (P : Matrix k n ℝ) (τ δ : ℝ)
    (wm : n → ℝ) (q : k → ℝ)
    (hSig : Sig.PosDef) (hδ : 0 < δ) :
    let piv := (δ • Sig) *ᵥ wm
    let muBL := piv + ((τ • Sig) * Pᵀ * (P * (τ • Sig) * Pᵀ + Om)⁻¹) *ᵥ (q - P *ᵥ piv)
    let lam := (τ / δ) • ((P * (τ • Sig) * Pᵀ + Om)⁻¹ *ᵥ (q - P *ᵥ piv))
    (δ • Sig)⁻¹ *ᵥ muBL = wm + Pᵀ *ᵥ lam := by
  intro piv muBL lam
  have hD : (δ • Sig).PosDef := hSig.smul hδ
  have dD : IsUnit (δ • Sig).det := (isUnit_iff_isUnit_det _).mp hD.isUnit
  have e1 : (δ • Sig)⁻¹ * (δ • Sig) = 1 := nonsing_inv_mul _ dD
  have hT : τ • Sig = (τ / δ) • (δ • Sig) := by
    rw [smul_smul, div_mul_cancel₀ τ hδ.ne']
  set M := P * (τ • Sig) * Pᵀ + Om
  set r := q - P *ᵥ piv
  show (δ • Sig)⁻¹ *ᵥ (piv + ((τ • Sig) * Pᵀ * M⁻¹) *ᵥ r) = wm + Pᵀ *ᵥ ((τ / δ) • (M⁻¹ *ᵥ r))
  have e2 : (δ • Sig)⁻¹ * ((τ • Sig) * Pᵀ * M⁻¹) = (τ / δ) • (Pᵀ * M⁻¹) := by
    rw [hT, ← Matrix.mul_assoc, ← Matrix.mul_assoc, Matrix.mul_smul, e1, Matrix.smul_mul,
      Matrix.smul_mul, Matrix.one_mul]
  rw [mulVec_add, mulVec_mulVec, e1, one_mulVec, mulVec_mulVec, e2, smul_mulVec,
    mulVec_smul, mulVec_mulVec]

/-- One opinion alone, about the portfolio `p ≠ 0`, at confidence `c` with `0 < c ≤ 1`:
set its variance to `ω = (p τΣ pᵀ)(1 − c)/c`. Then the blend
`μ_BL = π + τΣ pᵀ (p τΣ pᵀ + ω)⁻¹ (q − p·π)` gives that portfolio the market's value plus
exactly the fraction `c` of the surprise: `p·μ_BL = p·π + c (q − p·π)`. -/
theorem black_litterman_one_view_moves_fraction_c
    (Sig : Matrix n n ℝ) (τ c q : ℝ) (p piv : n → ℝ)
    (hSig : Sig.PosDef) (hτ : 0 < τ) (hp : p ≠ 0) (hc0 : 0 < c) (hc1 : c ≤ 1) :
    let prior := p ⬝ᵥ ((τ • Sig) *ᵥ p)
    let ω := prior * (1 - c) / c
    let muBL := piv + ((q - p ⬝ᵥ piv) / (prior + ω)) • ((τ • Sig) *ᵥ p)
    p ⬝ᵥ muBL = p ⬝ᵥ piv + c * (q - p ⬝ᵥ piv) := by
  intro prior ω muBL
  have hpos : 0 < prior := by
    have h := (hSig.smul hτ).dotProduct_mulVec_pos hp
    simpa using h
  have hsum : prior + ω = prior / c := by
    simp only [ω]
    field_simp
    ring
  simp only [muBL, dotProduct_add, dotProduct_smul, smul_eq_mul]
  change p ⬝ᵥ piv + (q - p ⬝ᵥ piv) / (prior + ω) * prior = _
  rw [hsum]
  field_simp

/-! The card's worked numbers that are exact (written as fractions, not rounded decimals). -/

-- covariance of shares with bonds: 0.2 × 0.20 × 0.06 = 0.0024
example : (2 / 10 : ℚ) * (20 / 100) * (6 / 100) = 24 / 10000 := by norm_num

-- covariance of shares with gold: 0.1 × 0.20 × 0.15 = 0.003
example : (1 / 10 : ℚ) * (20 / 100) * (15 / 100) = 3 / 1000 := by norm_num

-- implied return, shares: 2.5 × (0.04 × 0.55 + 0.0024 × 0.30 + 0.003 × 0.15) = 5.7925 %
example : (5 / 2 : ℚ) * (4 / 100 * (55 / 100) + 24 / 10000 * (30 / 100) + 3 / 1000 * (15 / 100))
    = 57925 / 1000000 := by norm_num

-- implied return, bonds: 2.5 × (0.0024 × 0.55 + 0.0036 × 0.30) = 0.6000 %
example : (5 / 2 : ℚ) * (24 / 10000 * (55 / 100) + 36 / 10000 * (30 / 100)) = 6 / 1000 := by
  norm_num

-- prior doubt on gold minus bonds: 0.05 × (0.0036 + 0.0225 − 2 × 0) = 0.001305,
-- and opinion 1's variance at c = 0.5 is the same: 0.001305 × (1 − 0.5)/0.5 = 0.001305
example : (5 / 100 : ℚ) * (36 / 10000 + 225 / 10000 - 2 * 0) = 1305 / 1000000 := by norm_num
example : (1305 / 1000000 : ℚ) * (1 - 1 / 2) / (1 / 2) = 1305 / 1000000 := by norm_num

-- opinion 2's variance at c = 0.5: 0.05 × 0.04 × 1 = 0.002
example : (5 / 100 : ℚ) * (4 / 100) * 1 = 2 / 1000 := by norm_num

-- prior doubt shared by the two opinions: 0.05 × (0.003 − 0.0024) = 0.00003
example : (5 / 100 : ℚ) * (3 / 1000 - 24 / 10000) = 3 / 100000 := by norm_num

-- total doubt S on each opinion: 0.001305 + 0.001305 = 0.00261 and 0.002 + 0.002 = 0.004
example : (1305 / 1000000 : ℚ) + 1305 / 1000000 = 261 / 100000 := by norm_num
example : (2 / 1000 : ℚ) + 2 / 1000 = 4 / 1000 := by norm_num

-- slices of each opinion's portfolio use the factor τ/δ = 0.05 / 2.5 = 1/50
example : (5 / 100 : ℚ) / (5 / 2) = 1 / 50 := by norm_num

#print axioms black_litterman_blend_eq_precision_form
#print axioms black_litterman_weights_eq_market_plus_view_portfolios
#print axioms black_litterman_one_view_moves_fraction_c
