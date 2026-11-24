-- Generalised eigenproblems: for a symmetric pencil K x = λ M x with M positive definite and M = L Lᵀ, the matrix C = L⁻¹ K L⁻ᵀ is symmetric with the same eigenvalues, its eigenvectors map back by x = L⁻ᵀ y, orthonormal y give M-orthonormal modes, and modes with different eigenvalues are M-orthogonal.
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Matrix

/-! Matrices are real and square, indexed by `Fin n`. `Kᵀ = K` says `K` is symmetric.
Mathlib's `M.PosDef` says `M` is symmetric and `xᵀ M x > 0` for every nonzero `x`.
`A *ᵥ x` is the matrix-vector product, `x ⬝ᵥ y` the plain dot product, and `L⁻¹` the
inverse of `L`. The eigenvalue is written `lam`, since `λ` is a reserved word in Lean. -/

/-- With M positive definite and M = L Lᵀ, the factor L has a nonzero determinant. -/
theorem gep_isUnit_det_factor {n : ℕ} (M L : Matrix (Fin n) (Fin n) ℝ)
    (hM : M.PosDef) (hL : M = L * Lᵀ) : IsUnit L.det := by
  have h := hM.det_pos
  rw [hL, det_mul, det_transpose] at h
  exact isUnit_iff_ne_zero.mpr (fun h0 => by rw [h0, mul_zero] at h; exact lt_irrefl _ h)

/-- With M = L Lᵀ and L invertible, M L⁻ᵀ = L. -/
theorem gep_M_mul_invT {n : ℕ} (M L : Matrix (Fin n) (Fin n) ℝ)
    (hu : IsUnit L.det) (hL : M = L * Lᵀ) : M * (L⁻¹)ᵀ = L := by
  rw [hL, Matrix.mul_assoc, ← transpose_mul, nonsing_inv_mul _ hu, transpose_one, Matrix.mul_one]

/-- The Cholesky reduction. Let K and M be symmetric with M positive definite, and let
M = L Lᵀ (for example its Cholesky factorisation). Then C = L⁻¹ K L⁻ᵀ is symmetric;
C y = λ y holds exactly when x = L⁻ᵀ y solves the pencil K x = λ M x; and the pencil has a
nonzero mode with eigenvalue λ exactly when C has a nonzero eigenvector with eigenvalue λ. -/
theorem cholesky_reduction_same_eigenvalues {n : ℕ} (K M L : Matrix (Fin n) (Fin n) ℝ)
    (hK : Kᵀ = K) (hM : M.PosDef) (hL : M = L * Lᵀ) :
    (L⁻¹ * K * (L⁻¹)ᵀ)ᵀ = L⁻¹ * K * (L⁻¹)ᵀ ∧
    (∀ (lam : ℝ) (y : Fin n → ℝ),
      (L⁻¹ * K * (L⁻¹)ᵀ) *ᵥ y = lam • y ↔
        K *ᵥ ((L⁻¹)ᵀ *ᵥ y) = lam • (M *ᵥ ((L⁻¹)ᵀ *ᵥ y))) ∧
    (∀ lam : ℝ,
      (∃ x : Fin n → ℝ, x ≠ 0 ∧ K *ᵥ x = lam • (M *ᵥ x)) ↔
        (∃ y : Fin n → ℝ, y ≠ 0 ∧ (L⁻¹ * K * (L⁻¹)ᵀ) *ᵥ y = lam • y)) := by
  have hu := gep_isUnit_det_factor M L hM hL
  have hML := gep_M_mul_invT M L hu hL
  have hLt : IsUnit Lᵀ.det := by rw [det_transpose]; exact hu
  have key : ∀ (lam : ℝ) (y : Fin n → ℝ),
      (L⁻¹ * K * (L⁻¹)ᵀ) *ᵥ y = lam • y ↔
        K *ᵥ ((L⁻¹)ᵀ *ᵥ y) = lam • (M *ᵥ ((L⁻¹)ᵀ *ᵥ y)) := by
    intro lam y
    have hMx : M *ᵥ ((L⁻¹)ᵀ *ᵥ y) = L *ᵥ y := by rw [mulVec_mulVec, hML]
    have hCy : (L⁻¹ * K * (L⁻¹)ᵀ) *ᵥ y = L⁻¹ *ᵥ (K *ᵥ ((L⁻¹)ᵀ *ᵥ y)) := by
      rw [mulVec_mulVec, mulVec_mulVec, Matrix.mul_assoc]
    rw [hMx, hCy]
    constructor
    · intro h
      have h2 := congrArg (fun v => L *ᵥ v) h
      simp only [mulVec_smul] at h2
      rw [mulVec_mulVec, mul_nonsing_inv _ hu, one_mulVec] at h2
      exact h2
    · intro h
      rw [h, mulVec_smul, mulVec_mulVec, nonsing_inv_mul _ hu, one_mulVec]
  refine ⟨?_, key, ?_⟩
  · rw [transpose_mul, transpose_mul, transpose_transpose, hK, Matrix.mul_assoc]
  · intro lam
    constructor
    · rintro ⟨x, hx0, hx⟩
      refine ⟨Lᵀ *ᵥ x, ?_, ?_⟩
      · intro h0
        apply hx0
        have h2 := congrArg (fun v => (Lᵀ)⁻¹ *ᵥ v) h0
        simpa [mulVec_mulVec, nonsing_inv_mul _ hLt] using h2
      · have hx' : (L⁻¹)ᵀ *ᵥ (Lᵀ *ᵥ x) = x := by
          rw [mulVec_mulVec, transpose_nonsing_inv, nonsing_inv_mul _ hLt, one_mulVec]
        rw [key, hx']
        exact hx
    · rintro ⟨y, hy0, hy⟩
      refine ⟨(L⁻¹)ᵀ *ᵥ y, ?_, (key lam y).mp hy⟩
      intro h0
      apply hy0
      have h2 := congrArg (fun v => Lᵀ *ᵥ v) h0
      simpa [mulVec_mulVec, transpose_nonsing_inv, mul_nonsing_inv _ hLt] using h2

/-- Orthonormal vectors y of the reduced problem give M-orthonormal modes: with M = L Lᵀ
and M positive definite, the shapes x = L⁻ᵀ y satisfy xᵢᵀ M xⱼ = yᵢᵀ yⱼ. -/
theorem m_inner_product_of_scaled_back {n : ℕ} (M L : Matrix (Fin n) (Fin n) ℝ)
    (hM : M.PosDef) (hL : M = L * Lᵀ) (y z : Fin n → ℝ) :
    ((L⁻¹)ᵀ *ᵥ y) ⬝ᵥ (M *ᵥ ((L⁻¹)ᵀ *ᵥ z)) = y ⬝ᵥ z := by
  have hu := gep_isUnit_det_factor M L hM hL
  rw [mulVec_mulVec, gep_M_mul_invT M L hu hL, mulVec_transpose, dotProduct_mulVec,
    vecMul_vecMul, nonsing_inv_mul _ hu, vecMul_one]

/-- Modes are perpendicular once lengths are weighted by mass: if K and M are symmetric,
K v = λᵢ M v and K w = λⱼ M w with λᵢ ≠ λⱼ, then wᵀ M v = 0, and then wᵀ K v = 0 too. -/
theorem modes_are_m_orthogonal {n : ℕ} (K M : Matrix (Fin n) (Fin n) ℝ)
    (hK : Kᵀ = K) (hM : Mᵀ = M) (v w : Fin n → ℝ) (lamᵢ lamⱼ : ℝ)
    (hv : K *ᵥ v = lamᵢ • (M *ᵥ v)) (hw : K *ᵥ w = lamⱼ • (M *ᵥ w)) (hne : lamᵢ ≠ lamⱼ) :
    w ⬝ᵥ (M *ᵥ v) = 0 ∧ w ⬝ᵥ (K *ᵥ v) = 0 := by
  have hsymK : w ⬝ᵥ (K *ᵥ v) = v ⬝ᵥ (K *ᵥ w) := by
    rw [dotProduct_mulVec, ← mulVec_transpose, hK, dotProduct_comm]
  have hsymM : w ⬝ᵥ (M *ᵥ v) = v ⬝ᵥ (M *ᵥ w) := by
    rw [dotProduct_mulVec, ← mulVec_transpose, hM, dotProduct_comm]
  have h1 : w ⬝ᵥ (K *ᵥ v) = lamᵢ * (w ⬝ᵥ (M *ᵥ v)) := by rw [hv, dotProduct_smul, smul_eq_mul]
  have h2 : v ⬝ᵥ (K *ᵥ w) = lamⱼ * (v ⬝ᵥ (M *ᵥ w)) := by rw [hw, dotProduct_smul, smul_eq_mul]
  have h0 : w ⬝ᵥ (M *ᵥ v) = 0 := by
    have : (lamᵢ - lamⱼ) * (w ⬝ᵥ (M *ᵥ v)) = 0 := by
      rw [sub_mul, ← h1, hsymK, h2, hsymM, sub_self]
    rcases mul_eq_zero.mp this with h | h
    · exact absurd (sub_eq_zero.mp h) hne
    · exact h
  exact ⟨h0, by rw [h1, h0, mul_zero]⟩

/-! The card's worked example: carts of 2 kg and 1 kg, springs of 3 N/m and 2 N/m. -/

-- det(K − λM) = 2λ² − 9λ + 6 for K = [[5, −2], [−2, 2]] and M = diag(2, 1).
example (lam : ℝ) :
    (!![5, -2; -2, 2] - lam • !![2, 0; 0, 1] : Matrix (Fin 2) (Fin 2) ℝ).det =
      2 * lam ^ 2 - 9 * lam + 6 := by
  rw [det_fin_two]; simp; ring

-- The roots λ = (9 ∓ √33)/4 of that polynomial.
example : 2 * ((9 - √33) / 4) ^ 2 - 9 * ((9 - √33) / 4) + 6 = 0 ∧
    2 * ((9 + √33) / 4) ^ 2 - 9 * ((9 + √33) / 4) + 6 = 0 := by
  have h : (√33) ^ 2 = 33 := Real.sq_sqrt (by norm_num)
  constructor <;> nlinarith [h]

-- The modes v = (1, (5 − 2λ)/2) are (1, (1 + √33)/4) and (1, (1 − √33)/4): their plain dot
-- product is −1, their mass-weighted product 2·1·1 + 1·v₂·w₂ is exactly 0.
example : (1 : ℝ) * 1 + ((1 + √33) / 4) * ((1 - √33) / 4) = -1 ∧
    (2 : ℝ) * 1 * 1 + 1 * ((1 + √33) / 4) * ((1 - √33) / 4) = 0 := by
  have h : (√33) ^ 2 = 33 := Real.sq_sqrt (by norm_num)
  constructor <;> nlinarith [h]

-- C = L⁻¹ K L⁻ᵀ with L = diag(√2, 1) is [[5/2, −2/√2], [−2/√2, 2]]: trace 9/2, determinant 3.
example : (!![5 / 2, -2 / √2; -2 / √2, 2] : Matrix (Fin 2) (Fin 2) ℝ).trace = 9 / 2 ∧
    (!![5 / 2, -2 / √2; -2 / √2, 2] : Matrix (Fin 2) (Fin 2) ℝ).det = 3 := by
  have h : (√2) ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  have h0 : (√2) ≠ 0 := by positivity
  refine ⟨?_, ?_⟩
  · simp [trace, Fin.sum_univ_two]; norm_num
  · rw [det_fin_two]; simp; field_simp; nlinarith [h]

-- Counting below σ = 2: the pivots of K − 2M are 5 − 2·2 = 1 and (2 − 2) − 4/1 = −4.
example : (5 : ℚ) - 2 * 2 = 1 ∧ ((2 : ℚ) - 2) - 4 / (5 - 2 * 2) = -4 := by norm_num

-- A massless second cart, M = diag(2, 0): det(K − λM) = 6 − 4λ, whose one root is 3/2.
example (lam : ℝ) :
    (!![5, -2; -2, 2] - lam • !![2, 0; 0, 0] : Matrix (Fin 2) (Fin 2) ℝ).det = 6 - 4 * lam := by
  rw [det_fin_two]; simp; ring

example : (6 : ℚ) - 4 * (3 / 2) = 0 := by norm_num

-- QZ's pairs at m₂ = 0: det(βK − αM) = β(6β − 4α), zero at (α, β) = (3, 2) and (1, 0).
example (α β : ℝ) :
    (β • !![5, -2; -2, 2] - α • !![2, 0; 0, 0] : Matrix (Fin 2) (Fin 2) ℝ).det =
      β * (6 * β - 4 * α) := by
  rw [det_fin_two]; simp; ring

example : (2 : ℚ) * (6 * 2 - 4 * 3) = 0 ∧ (0 : ℚ) * (6 * 0 - 4 * 1) = 0 := by norm_num

#print axioms gep_isUnit_det_factor
#print axioms gep_M_mul_invT
#print axioms cholesky_reduction_same_eigenvalues
#print axioms m_inner_product_of_scaled_back
#print axioms modes_are_m_orthogonal
