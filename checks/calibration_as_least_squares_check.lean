-- Calibration: the damped least-squares step of a calibration exists, is unique and points downhill, and one quote alone cannot tell two knobs apart.
import Mathlib.Data.Real.Basic
import Mathlib.Data.Matrix.Mul
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.ToLinearEquiv

open Matrix

theorem calib_quad_JtJ {m n : ℕ} (J : Matrix (Fin m) (Fin n) ℝ) (d : Fin n → ℝ) :
    0 ≤ d ⬝ᵥ ((Jᵀ * J) *ᵥ d) := by
  rw [← mulVec_mulVec, dotProduct_mulVec, vecMul_transpose]
  simp only [dotProduct]
  exact Finset.sum_nonneg (fun i _ => mul_self_nonneg _)

theorem calib_quad_diag {n : ℕ} (c : Fin n → ℝ) (hc : ∀ k, 0 < c k) (lam : ℝ) (hlam : 0 < lam)
    (d : Fin n → ℝ) (hd : d ≠ 0) :
    0 < d ⬝ᵥ ((lam • diagonal c) *ᵥ d) := by
  obtain ⟨k, hk⟩ := Function.ne_iff.mp hd
  rw [smul_mulVec, dotProduct_smul, smul_eq_mul]
  apply mul_pos hlam
  simp only [dotProduct, mulVec_diagonal]
  apply Finset.sum_pos'
  · intro i _
    have := hc i
    nlinarith [mul_self_nonneg (d i)]
  · refine ⟨k, Finset.mem_univ _, ?_⟩
    have := hc k
    have : 0 < d k * d k := mul_self_pos.mpr hk
    nlinarith

theorem calib_posdef_step {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ)
    (hA : ∀ d : Fin n → ℝ, d ≠ 0 → 0 < d ⬝ᵥ (A *ᵥ d)) (g : Fin n → ℝ) :
    A.det ≠ 0 ∧ (∃! d : Fin n → ℝ, A *ᵥ d = -g) ∧
    (g ≠ 0 → ∀ d : Fin n → ℝ, A *ᵥ d = -g → g ⬝ᵥ d < 0) := by
  have hdet : A.det ≠ 0 := by
    intro h
    obtain ⟨v, hv, hAv⟩ := (Matrix.exists_mulVec_eq_zero_iff).mpr h
    have := hA v hv
    rw [hAv, dotProduct_zero] at this
    exact lt_irrefl _ this
  refine ⟨hdet, ?_, ?_⟩
  · have hu : IsUnit A.det := isUnit_iff_ne_zero.mpr hdet
    refine ⟨A⁻¹ *ᵥ (-g), ?_, ?_⟩
    · simp only [mulVec_mulVec, mul_nonsing_inv A hu, one_mulVec]
    · intro y hy
      rw [← hy, mulVec_mulVec, nonsing_inv_mul A hu, one_mulVec]
  · intro hg d hd
    have hd0 : d ≠ 0 := by
      rintro rfl
      apply hg
      rw [mulVec_zero] at hd
      exact neg_eq_zero.mp hd.symm
    have := hA d hd0
    have hg' : g = -(A *ᵥ d) := by rw [hd, neg_neg]
    rw [hg', neg_dotProduct, dotProduct_comm]
    linarith

#print axioms calib_quad_JtJ
#print axioms calib_quad_diag
#print axioms calib_posdef_step

/-- Marquardt's damped step, the card's formula. Take any slope table `J` (one row per quote,
one column per knob), any column of scaled misses `e`, a positive damping `lam`, and suppose every
diagonal entry of `Jᵀ J` is positive. Then the damped matrix `Jᵀ J + lam · diag(Jᵀ J)` is
invertible, the step equations `(Jᵀ J + lam · diag(Jᵀ J)) d = -Jᵀ e` have exactly one solution,
and when the loss's slope `g = Jᵀ e` is not zero that step points downhill: `g · d < 0`. -/
theorem marquardt_step_unique_and_downhill {m n : ℕ}
    (J : Matrix (Fin m) (Fin n) ℝ) (e : Fin m → ℝ) (lam : ℝ) (hlam : 0 < lam)
    (hdiag : ∀ k, 0 < (Jᵀ * J) k k) :
    (Jᵀ * J + lam • diagonal (fun k => (Jᵀ * J) k k)).det ≠ 0 ∧
    (∃! d : Fin n → ℝ, (Jᵀ * J + lam • diagonal (fun k => (Jᵀ * J) k k)) *ᵥ d = -(Jᵀ *ᵥ e)) ∧
    (Jᵀ *ᵥ e ≠ 0 → ∀ d : Fin n → ℝ,
      (Jᵀ * J + lam • diagonal (fun k => (Jᵀ * J) k k)) *ᵥ d = -(Jᵀ *ᵥ e) →
      (Jᵀ *ᵥ e) ⬝ᵥ d < 0) := by
  apply calib_posdef_step
  intro d hd
  rw [add_mulVec, dotProduct_add]
  have h1 := calib_quad_JtJ J d
  have h2 := calib_quad_diag (fun k => (Jᵀ * J) k k) hdiag lam hlam d hd
  linarith

/-- Levenberg's damped step. For any slope table `J`, any misses `e` and any positive damping
`lam`, the matrix `Jᵀ J + lam · I` is invertible, the step equations `(Jᵀ J + lam · I) d = -Jᵀ e`
have exactly one solution, and when the slope `g = Jᵀ e` is not zero the step goes downhill:
`g · d < 0`. -/
theorem levenberg_step_unique_and_downhill {m n : ℕ}
    (J : Matrix (Fin m) (Fin n) ℝ) (e : Fin m → ℝ) (lam : ℝ) (hlam : 0 < lam) :
    (Jᵀ * J + lam • (1 : Matrix (Fin n) (Fin n) ℝ)).det ≠ 0 ∧
    (∃! d : Fin n → ℝ, (Jᵀ * J + lam • (1 : Matrix (Fin n) (Fin n) ℝ)) *ᵥ d = -(Jᵀ *ᵥ e)) ∧
    (Jᵀ *ᵥ e ≠ 0 → ∀ d : Fin n → ℝ,
      (Jᵀ * J + lam • (1 : Matrix (Fin n) (Fin n) ℝ)) *ᵥ d = -(Jᵀ *ᵥ e) →
      (Jᵀ *ᵥ e) ⬝ᵥ d < 0) := by
  apply calib_posdef_step
  intro d hd
  rw [add_mulVec, dotProduct_add, ← diagonal_one]
  have h1 := calib_quad_JtJ J d
  have h2 := calib_quad_diag (fun _ => (1 : ℝ)) (fun _ => one_pos) lam hlam d hd
  linarith

/-- One quote cannot tell two knobs apart: when the slope table has a single row and two columns,
`det(Jᵀ J) = 0`. -/
theorem one_quote_cannot_separate_two_knobs (J : Matrix (Fin 1) (Fin 2) ℝ) :
    (Jᵀ * J).det = 0 := by
  simp [det_fin_two, Matrix.mul_apply, transpose_apply]
  ring

#print axioms marquardt_step_unique_and_downhill
#print axioms levenberg_step_unique_and_downhill
#print axioms one_quote_cannot_separate_two_knobs
