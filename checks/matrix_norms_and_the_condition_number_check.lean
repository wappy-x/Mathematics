-- Matrix norms and the condition number: the relative error in the solution of A x = b is at most κ(A) = ‖A‖ ‖A⁻¹‖ times the relative error in b, some data error reaches that bound, and the infinity-norm of a matrix is its largest absolute row sum.
import Mathlib.Analysis.Matrix.Normed
import Mathlib.Analysis.Normed.Operator.Basic
import Mathlib.Topology.Algebra.Module.FiniteDimension
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.Notation

open Matrix

/-- The condition number κ(A) = ‖A‖ ‖A⁻¹‖ of an invertible linear map, with both norms
induced by the same vector norm on `E`. -/
noncomputable def condNum {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (A : E ≃L[ℝ] E) : ℝ :=
  ‖(A : E →L[ℝ] E)‖ * ‖(A.symm : E →L[ℝ] E)‖

theorem exists_norm_apply_eq_opNorm_mul
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E]
    [Nontrivial E] (f : E →L[ℝ] E) :
    ∃ x : E, x ≠ 0 ∧ ‖f x‖ = ‖f‖ * ‖x‖ := by
  have : ProperSpace E := FiniteDimensional.proper ℝ E
  have hK : IsCompact (Metric.sphere (0 : E) 1) := isCompact_sphere 0 1
  have hne : (Metric.sphere (0 : E) 1).Nonempty := NormedSpace.sphere_nonempty.mpr zero_le_one
  obtain ⟨x, hx, hmax⟩ := hK.exists_isMaxOn hne (continuous_norm.comp f.continuous).continuousOn
  have hx1 : ‖x‖ = 1 := by simpa using hx
  have hx0 : x ≠ 0 := by
    intro h; rw [h, norm_zero] at hx1; exact zero_ne_one hx1
  refine ⟨x, hx0, ?_⟩
  rw [hx1, mul_one]
  apply le_antisymm
  · simpa [hx1] using f.le_opNorm x
  · refine f.opNorm_le_bound (norm_nonneg _) fun y => ?_
    rcases eq_or_ne y 0 with rfl | hy
    · simp
    · have hy' : 0 < ‖y‖ := norm_pos_iff.mpr hy
      set u : E := (‖y‖⁻¹ : ℝ) • y with hu
      have hu1 : u ∈ Metric.sphere (0 : E) 1 := by
        simp [hu, norm_smul, hy'.ne']
      have h1 : ‖f u‖ ≤ ‖f x‖ := hmax hu1
      have h2 : ‖f u‖ = ‖y‖⁻¹ * ‖f y‖ := by
        simp [hu, map_smul, norm_smul]
      rw [h2] at h1
      calc ‖f y‖ = ‖y‖ * (‖y‖⁻¹ * ‖f y‖) := by field_simp
        _ ≤ ‖y‖ * ‖f x‖ := by gcongr
        _ = ‖f x‖ * ‖y‖ := mul_comm _ _

#print axioms exists_norm_apply_eq_opNorm_mul

/-- The condition-number bound. Let `A` be square and invertible, and measure every vector in
one norm, with `‖A‖` and `‖A⁻¹‖` the matrix norms that norm induces. If `A x = b` and the
changed data `b + Δb` give the changed answer `x + Δx`, then the relative error in the answer
is at most κ(A) times the relative error in the data, for a change of any size. -/
theorem relative_error_le_condNum_mul_relative_data_error
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (A : E ≃L[ℝ] E) (x Δx b Δb : E)
    (hb : A x = b) (hΔ : A (x + Δx) = b + Δb) :
    ‖Δx‖ / ‖x‖ ≤ condNum A * (‖Δb‖ / ‖b‖) := by
  have hAΔ : A Δx = Δb := by
    rw [map_add, hb] at hΔ; exact add_left_cancel hΔ
  have hΔx : Δx = A.symm Δb := by rw [← hAΔ, A.symm_apply_apply]
  have h1 : ‖Δx‖ ≤ ‖(A.symm : E →L[ℝ] E)‖ * ‖Δb‖ := by
    rw [hΔx]; exact (A.symm : E →L[ℝ] E).le_opNorm Δb
  have h2 : ‖b‖ ≤ ‖(A : E →L[ℝ] E)‖ * ‖x‖ := by
    rw [← hb]; exact (A : E →L[ℝ] E).le_opNorm x
  have hRHS : 0 ≤ condNum A * (‖Δb‖ / ‖b‖) := by
    unfold condNum; positivity
  rcases eq_or_ne x 0 with hx | hx
  · simp [hx, hRHS]
  have hbne : b ≠ 0 := by
    rw [← hb]; intro h; exact hx (by simpa using congrArg A.symm h)
  have hxp : 0 < ‖x‖ := norm_pos_iff.mpr hx
  have hbp : 0 < ‖b‖ := norm_pos_iff.mpr hbne
  unfold condNum
  rw [div_le_iff₀ hxp]
  calc ‖Δx‖ ≤ ‖(A.symm : E →L[ℝ] E)‖ * ‖Δb‖ := h1
    _ = ‖(A.symm : E →L[ℝ] E)‖ * ‖Δb‖ / ‖b‖ * ‖b‖ := by field_simp
    _ ≤ ‖(A.symm : E →L[ℝ] E)‖ * ‖Δb‖ / ‖b‖ * (‖(A : E →L[ℝ] E)‖ * ‖x‖) := by
        gcongr
    _ = ‖(A : E →L[ℝ] E)‖ * ‖(A.symm : E →L[ℝ] E)‖ * (‖Δb‖ / ‖b‖) * ‖x‖ := by ring

/-- The bound is reached: in a finite-dimensional space (a square matrix of size at least 1),
there is a nonzero answer `x` and a nonzero data change `Δb` for which the relative error in
the answer is exactly κ(A) times the relative error in the data `b = A x`. -/
theorem condNum_bound_is_attained
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E]
    [Nontrivial E] (A : E ≃L[ℝ] E) :
    ∃ x Δb : E, x ≠ 0 ∧ Δb ≠ 0 ∧
      ‖A.symm Δb‖ / ‖x‖ = condNum A * (‖Δb‖ / ‖A x‖) := by
  obtain ⟨x, hx, hxn⟩ := exists_norm_apply_eq_opNorm_mul (A : E →L[ℝ] E)
  obtain ⟨d, hd, hdn⟩ := exists_norm_apply_eq_opNorm_mul (A.symm : E →L[ℝ] E)
  refine ⟨x, d, hx, hd, ?_⟩
  have hAx : A x ≠ 0 := by
    intro h; exact hx (by simpa using congrArg A.symm h)
  have hAxp : 0 < ‖A x‖ := norm_pos_iff.mpr hAx
  have hxp : 0 < ‖x‖ := norm_pos_iff.mpr hx
  have hxn' : ‖A x‖ = ‖(A : E →L[ℝ] E)‖ * ‖x‖ := hxn
  have hdn' : ‖A.symm d‖ = ‖(A.symm : E →L[ℝ] E)‖ * ‖d‖ := hdn
  have hA0 : ‖(A : E →L[ℝ] E)‖ ≠ 0 := by
    intro h; rw [h, zero_mul] at hxn'; exact hAxp.ne' hxn'
  unfold condNum
  rw [hdn', hxn']
  field_simp

/-- The infinity-norm of a square matrix, defined as its worst stretch
`max ‖A x‖∞ / ‖x‖∞` (the operator norm of `x ↦ A x` for the max-entry norm on vectors),
equals its largest row sum of absolute values. -/
theorem infinity_norm_eq_max_row_sum {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) :
    ‖LinearMap.toContinuousLinearMap (Matrix.toLin' A)‖ =
      ((Finset.univ.sup fun i : Fin n => ∑ j : Fin n, ‖A i j‖₊ : NNReal) : ℝ) := by
  let _ := Matrix.linftyOpNormedAddCommGroup (m := Fin n) (n := Fin n) (α := ℝ)
  rw [← Matrix.linfty_opNorm_def A, Matrix.linfty_opNorm_eq_opNorm]
  rfl

/-! The card's stream example: `A = [[1, 1], [1, 0.96]]`, `b = (10, 9.8)`, `x = (5, 5)`,
written with exact fractions (0.96 = 24/25, 9.8 = 49/5). -/

-- The true flows solve the system: A (5, 5) = (10, 9.8).
example : !![(1 : ℚ), 1; 1, 24/25] *ᵥ ![5, 5] = ![10, 49/5] := by
  ext i; fin_cases i <;> norm_num [mulVec, dotProduct, Fin.sum_univ_two]

-- det A = 1 × 0.96 − 1 × 1 = −0.04.
example : (!![(1 : ℚ), 1; 1, 24/25]).det = -1/25 := by
  norm_num [det_fin_two_of]

-- A⁻¹ = [[-24, 25], [25, -25]]: their product is the identity.
example : !![(1 : ℚ), 1; 1, 24/25] * !![-24, 25; 25, -25] = 1 := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [mul_apply, Fin.sum_univ_two]

-- Infinity-norms by row sums: ‖A‖∞ = max(2, 1.96) = 2, ‖A⁻¹‖∞ = max(49, 50) = 50, κ∞ = 100.
example : max (|(1 : ℚ)| + |1|) (|1| + |24/25|) * max (|(-24 : ℚ)| + |25|) (|25| + |-25|)
    = 100 := by
  norm_num [abs_of_nonneg, abs_of_neg]

-- Gauge 1% low: Δb = (−0.1, 0) gives Δx = A⁻¹ Δb = (2.4, −2.5), so x' = (7.4, 2.5).
example : !![(-24 : ℚ), 25; 25, -25] *ᵥ ![-1/10, 0] = ![12/5, -5/2] := by
  ext i; fin_cases i <;> norm_num [mulVec, dotProduct, Fin.sum_univ_two]

-- Worst case: Δb = (−0.1, +0.1) gives Δx = (4.9, −5), so x' = (9.9, 0): 100% error from 1%.
example : !![(-24 : ℚ), 25; 25, -25] *ᵥ ![-1/10, 1/10] = ![49/10, -5] := by
  ext i; fin_cases i <;> norm_num [mulVec, dotProduct, Fin.sum_univ_two]

#print axioms relative_error_le_condNum_mul_relative_data_error
#print axioms condNum_bound_is_attained
#print axioms infinity_norm_eq_max_row_sum
