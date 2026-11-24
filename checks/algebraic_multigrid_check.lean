-- Algebraic multigrid: the Galerkin coarse matrix PᵀAP of a symmetric positive definite A stays symmetric positive definite when P has independent columns, and the coarse-grid correction is the best one in the energy norm.
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Tactic.NormNum

/-! `A` is the `n × n` fine matrix, `P` the `n × m` interpolation matrix (one column per
coarse point), `A_c = Pᵀ * A * P` the Galerkin coarse matrix. Mathlib's `Matrix.PosDef`
means symmetric (Hermitian, which over `ℝ` is symmetric) with `vᵀ A v > 0` for every
nonzero `v`. "P has independent columns" is `LinearIndependent ℝ P.col`.
The energy norm squared of `e` is `e ⬝ᵥ (A *ᵥ e)`. -/

open Matrix

/-- Moving `P` across the dot product. -/
theorem amg_dot_mulVec_left {n m : ℕ} (P : Matrix (Fin n) (Fin m) ℝ) (y : Fin m → ℝ)
    (z : Fin n → ℝ) : (P *ᵥ y) ⬝ᵥ z = y ⬝ᵥ (Pᵀ *ᵥ z) := by
  rw [dotProduct_comm, dotProduct_mulVec, mulVec_transpose, dotProduct_comm]

/-- A symmetric matrix gives a symmetric bilinear form. -/
theorem amg_dot_symm {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (hA : Aᵀ = A)
    (x y : Fin n → ℝ) : x ⬝ᵥ (A *ᵥ y) = y ⬝ᵥ (A *ᵥ x) := by
  rw [dotProduct_mulVec, ← mulVec_transpose, hA, dotProduct_comm]

/-- Expanding the energy of a sum. -/
theorem amg_energy_add {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (hA : Aᵀ = A)
    (d u : Fin n → ℝ) :
    (d + u) ⬝ᵥ (A *ᵥ (d + u)) = d ⬝ᵥ (A *ᵥ d) + 2 * (u ⬝ᵥ (A *ᵥ d)) + u ⬝ᵥ (A *ᵥ u) := by
  have h := amg_dot_symm A hA d u
  simp only [mulVec_add, add_dotProduct, dotProduct_add]
  rw [h]; ring

#print axioms amg_dot_mulVec_left
#print axioms amg_dot_symm
#print axioms amg_energy_add

/-- The Galerkin coarse matrix stays symmetric positive definite: if `A` is symmetric
positive definite and the interpolation `P` has independent columns, then
`A_c = Pᵀ A P` is symmetric positive definite. -/
theorem galerkin_coarse_matrix_posDef {n m : ℕ} (A : Matrix (Fin n) (Fin n) ℝ)
    (hA : A.PosDef) (P : Matrix (Fin n) (Fin m) ℝ) (hP : LinearIndependent ℝ P.col) :
    (Pᵀ * A * P).PosDef := by
  have h := hA.conjTranspose_mul_mul_same (Matrix.mulVec_injective_iff.mpr hP)
  rwa [conjTranspose_eq_transpose_of_trivial] at h

/-- The coarse-grid correction is the best one available from the coarse grid: with
error `e`, residual `r = A e` and correction `P v`, `v = A_c⁻¹ Pᵀ r`, the energy error
splits by Pythagoras, `‖e‖_A² = ‖e - P v‖_A² + ‖P v‖_A²` (so it cannot grow), and no
other coarse vector `w` leaves a smaller energy error `‖e - P w‖_A`. -/
theorem coarse_correction_best_in_energy_norm {n m : ℕ} (A : Matrix (Fin n) (Fin n) ℝ)
    (hA : A.PosDef) (P : Matrix (Fin n) (Fin m) ℝ) (hP : LinearIndependent ℝ P.col)
    (e : Fin n → ℝ) (v : Fin m → ℝ) (hv : v = (Pᵀ * A * P)⁻¹ *ᵥ (Pᵀ *ᵥ (A *ᵥ e))) :
    e ⬝ᵥ (A *ᵥ e) = (e - P *ᵥ v) ⬝ᵥ (A *ᵥ (e - P *ᵥ v)) + (P *ᵥ v) ⬝ᵥ (A *ᵥ (P *ᵥ v)) ∧
    ∀ w : Fin m → ℝ, (e - P *ᵥ v) ⬝ᵥ (A *ᵥ (e - P *ᵥ v)) ≤ (e - P *ᵥ w) ⬝ᵥ (A *ᵥ (e - P *ᵥ w)) := by
  have hT : Aᵀ = A := by
    have := hA.1
    rwa [IsHermitian, conjTranspose_eq_transpose_of_trivial] at this
  have hAc : (Pᵀ * A * P).PosDef := by
    have h := hA.conjTranspose_mul_mul_same (Matrix.mulVec_injective_iff.mpr hP)
    rwa [conjTranspose_eq_transpose_of_trivial] at h
  have hdet : IsUnit (Pᵀ * A * P).det := (Matrix.isUnit_iff_isUnit_det _).mp hAc.isUnit
  have hsolve : (Pᵀ * A * P) *ᵥ v = Pᵀ *ᵥ (A *ᵥ e) := by
    rw [hv, mulVec_mulVec, mul_nonsing_inv _ hdet, one_mulVec]
  set d := e - P *ᵥ v with hd
  have horth0 : Pᵀ *ᵥ (A *ᵥ d) = 0 := by
    rw [hd, mulVec_sub, mulVec_sub, ← hsolve, mulVec_mulVec, mulVec_mulVec, sub_self]
  have horth : ∀ y : Fin m → ℝ, (P *ᵥ y) ⬝ᵥ (A *ᵥ d) = 0 := by
    intro y
    rw [amg_dot_mulVec_left, horth0, dotProduct_zero]
  refine ⟨?_, fun w => ?_⟩
  · have he : e = d + P *ᵥ v := by rw [hd, sub_add_cancel]
    conv_lhs => rw [he]
    rw [amg_energy_add A hT, horth]; ring
  · have he : e - P *ᵥ w = d + P *ᵥ (v - w) := by
      rw [hd, mulVec_sub]; abel
    rw [he, amg_energy_add A hT, horth]
    have hnn := hA.posSemidef.dotProduct_mulVec_nonneg (P *ᵥ (v - w))
    rw [star_trivial] at hnn
    linarith

/-- On a row that sums to zero the interpolation weights sum to one: for an F point `i`
with positive diagonal, at least one strong C neighbour, negative ties `a_ij < 0` to its
C neighbours `Pᵢ`, and `∑ₖ a_ik = 0`, the weights `w_ij = -αᵢ a_ij / a_ii` with
`αᵢ = (∑_{k ≠ i} a_ik) / (∑_{k ∈ Pᵢ} a_ik)` add up to exactly 1, so a constant error
is interpolated exactly. -/
theorem interpolation_weights_sum_to_one {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (i : Fin n)
    (Pi : Finset (Fin n)) (hdiag : 0 < A i i) (hPi : Pi.Nonempty)
    (hneg : ∀ j ∈ Pi, A i j < 0) (hrow : ∑ k, A i k = 0) :
    ∑ j ∈ Pi, -((∑ k ∈ Finset.univ.erase i, A i k) / (∑ k ∈ Pi, A i k)) * A i j / A i i = 1 := by
  have hS : ∑ k ∈ Pi, A i k < 0 := Finset.sum_neg hneg hPi
  have hR : ∑ k ∈ Finset.univ.erase i, A i k = -A i i := by
    have := Finset.add_sum_erase Finset.univ (fun k => A i k) (Finset.mem_univ i)
    linarith
  have hS0 : ∑ k ∈ Pi, A i k ≠ 0 := hS.ne
  have hd0 : A i i ≠ 0 := hdiag.ne'
  rw [hR]
  have : ∀ j ∈ Pi, -(-A i i / ∑ k ∈ Pi, A i k) * A i j / A i i
      = (1 / ∑ k ∈ Pi, A i k) * A i j := by
    intro j _
    field_simp
  rw [Finset.sum_congr rfl this, ← Finset.mul_sum]
  field_simp

/-! The card's worked numbers for junction 1, exactly: diagonal 4.6 = 46/10, a tie of
4 to junction 2 and 0.5 = 1/2 to junction 3, threshold 0.25 = 1/4. -/

-- Strength cut 0.25 × 4 = 1: the tie 4 is strong, the tie 0.5 is weak.
example : (1 / 4 : ℚ) * 4 = 1 ∧ (4 : ℚ) ≥ 1 / 4 * 4 ∧ (1 / 2 : ℚ) < 1 / 4 * 4 := by norm_num

-- α = (4 + 0.5) ÷ 4 = 9/8 = 1.1250, and the weight 1.1250 × 4 ÷ 4.6 = 45/46 ≈ 0.978261.
example : ((4 : ℚ) + 1 / 2) / 4 = 9 / 8 ∧ (9 / 8 : ℚ) * 4 / (46 / 10) = 45 / 46 := by norm_num

-- Junction 1's row sums to the 0.1 L/s customer draw, so its weight misses 1 by 1/46.
example : (46 / 10 : ℚ) - 4 - 1 / 2 = 1 / 10 ∧ 1 - (45 / 46 : ℚ) = 1 / 46 := by norm_num

-- The same weight from the formula applied to the card's 3 × 3 matrix `A3`.
example :
    let A3 : Matrix (Fin 3) (Fin 3) ℚ := !![46 / 10, -4, -1 / 2; -4, 41 / 10, 0; -1 / 2, 0, 6 / 10];
    -((A3 0 1 + A3 0 2) / A3 0 1) * A3 0 1 / A3 0 0 = 45 / 46 := by
  norm_num

-- The plate's first coarse level: 63 rows × 31 C points per row = 1,953 points.
example : 63 * 31 = 1953 := by decide

#print axioms galerkin_coarse_matrix_posDef
#print axioms coarse_correction_best_in_energy_norm
#print axioms interpolation_weights_sum_to_one
