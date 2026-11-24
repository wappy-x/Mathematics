-- ISDA SIMM: within one bucket, with a valid correlation table, the margin of two books together is at most the sum of their separate margins.
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.Analysis.Real.Sqrt
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Algebra.QuadraticDiscriminant

open Matrix

/-- The SIMM margin of one bucket: the square root of the correlated sum
`∑ k, ∑ l, C k l * ws k * ws l` of the weighted sensitivities `ws` (each sensitivity
times its risk weight), with correlation table `C`. -/
noncomputable def simmMargin {ι : Type*} [Fintype ι] (C : Matrix ι ι ℝ) (ws : ι → ℝ) : ℝ :=
  Real.sqrt (ws ⬝ᵥ (C *ᵥ ws))

/-- Subadditivity (why a hedge never raises the margin): if the correlation table `C` is a true
correlation matrix (positive semidefinite, with ones on the diagonal), then the margin of two books
`u` and `v` combined in one netting set is at most the sum of their separate margins. -/
theorem simm_margin_subadditive {ι : Type*} [Fintype ι] (C : Matrix ι ι ℝ)
    (hC : C.PosSemidef) (hdiag : ∀ i, C i i = 1) (u v : ι → ℝ) :
    simmMargin C (u + v) ≤ simmMargin C u + simmMargin C v := by
  unfold simmMargin
  set q : (ι → ℝ) → ℝ := fun x => x ⬝ᵥ (C *ᵥ x) with hq
  have hnn : ∀ x, 0 ≤ q x := by
    intro x
    have := hC.dotProduct_mulVec_nonneg x
    simpa [hq] using this
  have hsymm : v ⬝ᵥ (C *ᵥ u) = u ⬝ᵥ (C *ᵥ v) := by
    have hT : Cᵀ = C := by
      have h1 := hC.1
      rw [IsHermitian, conjTranspose_eq_transpose_of_trivial] at h1
      exact h1
    rw [dotProduct_mulVec, ← mulVec_transpose, hT, dotProduct_comm]
  set b := u ⬝ᵥ (C *ᵥ v) with hb
  have hexp : ∀ t : ℝ, q (t • u + v) = q u * (t * t) + 2 * b * t + q v := by
    intro t
    simp only [hq, mulVec_add, mulVec_smul, add_dotProduct, dotProduct_add, smul_dotProduct,
      dotProduct_smul, smul_eq_mul, hsymm, hb]
    ring
  have hdisc : discrim (q u) (2 * b) (q v) ≤ 0 :=
    discrim_le_zero fun t => by rw [← hexp t]; exact hnn _
  have hcs : b * b ≤ q u * q v := by
    unfold discrim at hdisc; nlinarith
  have huv : q (u + v) = q u + 2 * b + q v := by
    have := hexp 1
    simpa using this
  have hbsq : b ≤ Real.sqrt (q u) * Real.sqrt (q v) := by
    rw [← Real.sqrt_mul (hnn u)]
    calc b ≤ |b| := le_abs_self b
      _ = Real.sqrt (b * b) := (Real.sqrt_mul_self_eq_abs b).symm
      _ ≤ Real.sqrt (q u * q v) := Real.sqrt_le_sqrt hcs
  show Real.sqrt (q (u + v)) ≤ Real.sqrt (q u) + Real.sqrt (q v)
  rw [show Real.sqrt (q u) + Real.sqrt (q v)
      = Real.sqrt ((Real.sqrt (q u) + Real.sqrt (q v)) ^ 2) from
      (Real.sqrt_sq (by positivity)).symm]
  apply Real.sqrt_le_sqrt
  rw [huv, add_sq, Real.sq_sqrt (hnn u), Real.sq_sqrt (hnn v)]
  linarith

/-- The bucket formula for two sensitivities: with correlation `ρ` between the two rates, the margin
is `√(WS₁² + WS₂² + 2 ρ WS₁ WS₂)`. -/
theorem simm_margin_two_sensitivities (ρ w₁ w₂ : ℝ) :
    simmMargin !![1, ρ; ρ, 1] ![w₁, w₂] = Real.sqrt (w₁ ^ 2 + w₂ ^ 2 + 2 * ρ * w₁ * w₂) := by
  simp only [simmMargin, dotProduct, mulVec, Fin.sum_univ_two]
  congr 1
  simp
  ring

/-- The other half of being a length: scaling a book by `c > 0` scales its margin by `c`. -/
theorem simm_margin_scale {ι : Type*} [Fintype ι] (C : Matrix ι ι ℝ) (ws : ι → ℝ)
    (c : ℝ) (hc : 0 < c) :
    simmMargin C (c • ws) = c * simmMargin C ws := by
  unfold simmMargin
  rw [mulVec_smul, smul_dotProduct, dotProduct_smul, smul_eq_mul, smul_eq_mul, ← mul_assoc,
    Real.sqrt_mul (mul_self_nonneg c), Real.sqrt_mul_self hc.le]

-- Weighted sensitivities: 10,000 × 50 and −8,000 × 55.
example : (10000 : ℤ) * 50 = 500000 ∧ (-8000 : ℤ) * 55 = -440000 := by norm_num

-- Under the root for the hedged pair with correlation 0.9: 47,600,000,000.
example : ![(500000 : ℝ), -440000] ⬝ᵥ (!![1, 9/10; 9/10, 1] *ᵥ ![(500000 : ℝ), -440000])
    = 47600000000 := by
  simp [dotProduct, mulVec, Fin.sum_univ_two]
  norm_num

-- Netting the two tenors (correlation 1) leaves (500,000 − 440,000)² = 60,000² under the root.
example : ![(500000 : ℝ), -440000] ⬝ᵥ (!![1, 1; 1, 1] *ᵥ ![(500000 : ℝ), -440000])
    = 60000 ^ 2 := by
  simp [dotProduct, mulVec, Fin.sum_univ_two]
  norm_num

-- Not a valid correlation table: correlations 0.9, 0.9 and −0.9 give −24,000,000,000 under the root.
example : ![(100000 : ℝ), -100000, -100000] ⬝ᵥ
    (!![1, 9/10, 9/10; 9/10, 1, -9/10; 9/10, -9/10, 1] *ᵥ ![(100000 : ℝ), -100000, -100000])
    = -24000000000 := by
  simp [dotProduct, mulVec, Fin.sum_univ_three]
  norm_num

#print axioms simm_margin_subadditive
#print axioms simm_margin_two_sensitivities
#print axioms simm_margin_scale
