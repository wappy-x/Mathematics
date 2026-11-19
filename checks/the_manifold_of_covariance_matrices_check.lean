-- Covariance matrices: the affine-invariant average of two positive definite matrices is the unique positive definite M with M A⁻¹ M = B, its determinant is √(det A · det B), for two assets it has a closed form, and it does not depend on units or on storing inverses.
import Mathlib.Analysis.Matrix.Order
import Mathlib.LinearAlgebra.Matrix.Adjugate
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse

open Matrix
open scoped MatrixOrder

/-- The affine-invariant average of two covariance matrices: the midpoint `γ(1/2)` of the
geodesic `γ(t) = A^{1/2} (A^{-1/2} B A^{-1/2})^t A^{1/2}`, that is
`A^{1/2} (A^{-1/2} B A^{-1/2})^{1/2} A^{1/2}`, with matrix square roots taken by
Mathlib's `CFC.sqrt`. -/
noncomputable def aiMean {n : Type*} [Fintype n] [DecidableEq n] (A B : Matrix n n ℝ) :
    Matrix n n ℝ :=
  CFC.sqrt A * CFC.sqrt ((CFC.sqrt A)⁻¹ * B * (CFC.sqrt A)⁻¹) * CFC.sqrt A

lemma aiMean_aux_sqrt_mul {n : Type*} [Fintype n] [DecidableEq n] {A : Matrix n n ℝ}
    (hA : A.PosDef) : CFC.sqrt A * CFC.sqrt A = A :=
  CFC.sqrt_mul_sqrt_self A hA.posSemidef.nonneg

lemma aiMean_aux_sqrt_posDef {n : Type*} [Fintype n] [DecidableEq n] {A : Matrix n n ℝ}
    (hA : A.PosDef) : (CFC.sqrt A).PosDef := by
  have h0 : (CFC.sqrt A).PosSemidef := (CFC.sqrt_nonneg A).posSemidef
  refine h0.posDef_iff_isUnit.mpr ?_
  have hu : IsUnit (CFC.sqrt A * CFC.sqrt A) := by
    rw [aiMean_aux_sqrt_mul hA]; exact hA.isUnit
  exact isUnit_of_mul_isUnit_left hu

lemma aiMean_aux_conj {n : Type*} [Fintype n] [DecidableEq n] {T X : Matrix n n ℝ}
    (hT : T.IsHermitian) (hTu : IsUnit T) (hX : X.PosDef) : (T * X * T).PosDef := by
  have h := (Matrix.IsUnit.posDef_star_right_conjugate_iff (x := X) hTu).mpr hX
  rwa [star_eq_conjTranspose, hT.eq] at h

lemma aiMean_aux_spec {n : Type*} [Fintype n] [DecidableEq n]
    {A B : Matrix n n ℝ} (hA : A.PosDef) (hB : B.PosDef) :
    (aiMean A B).PosDef ∧ aiMean A B * A⁻¹ * aiMean A B = B ∧
      (∀ X : Matrix n n ℝ, X.PosDef → X * A⁻¹ * X = B → X = aiMean A B) := by
  set S := CFC.sqrt A with hSdef
  have hS : S.PosDef := aiMean_aux_sqrt_posDef hA
  have hSS : S * S = A := aiMean_aux_sqrt_mul hA
  have hSd : IsUnit S.det := (Matrix.isUnit_iff_isUnit_det S).mp hS.isUnit
  have hSi : S⁻¹.PosDef := hS.inv
  have hAinv : A⁻¹ = S⁻¹ * S⁻¹ := by rw [← hSS, Matrix.mul_inv_rev]
  set C := S⁻¹ * B * S⁻¹ with hCdef
  have hC : C.PosDef := aiMean_aux_conj hSi.isHermitian hSi.isUnit hB
  set R := CFC.sqrt C with hRdef
  have hR : R.PosDef := aiMean_aux_sqrt_posDef hC
  have hRR : R * R = C := aiMean_aux_sqrt_mul hC
  have hM : aiMean A B = S * R * S := rfl
  refine ⟨?_, ?_, ?_⟩
  · rw [hM]; exact aiMean_aux_conj hS.isHermitian hS.isUnit hR
  · rw [hM, hAinv]
    calc S * R * S * (S⁻¹ * S⁻¹) * (S * R * S)
        = S * (R * ((S * S⁻¹) * (S⁻¹ * S)) * R) * S := by simp only [Matrix.mul_assoc]
      _ = S * (R * R) * S := by
          rw [Matrix.mul_nonsing_inv _ hSd, Matrix.nonsing_inv_mul _ hSd]; simp [Matrix.mul_assoc]
      _ = B := by
          rw [hRR, hCdef]
          simp only [← Matrix.mul_assoc]
          rw [Matrix.mul_nonsing_inv _ hSd, Matrix.one_mul, Matrix.nonsing_inv_mul_cancel_right S _ hSd]
  · intro X hX hXB
    set Y := S⁻¹ * X * S⁻¹ with hYdef
    have hY : Y.PosDef := aiMean_aux_conj hSi.isHermitian hSi.isUnit hX
    have hYY : Y * Y = C := by
      rw [hCdef, ← hXB, hAinv, hYdef]; simp only [Matrix.mul_assoc]
    have hRY : R = Y := CFC.sqrt_unique hYY hY.posSemidef.nonneg
    rw [hM, hRY, hYdef]
    simp only [← Matrix.mul_assoc]
    rw [Matrix.mul_nonsing_inv _ hSd, Matrix.one_mul, Matrix.nonsing_inv_mul_cancel_right S _ hSd]

lemma aiMean_aux_two_key (A B : Matrix (Fin 2) (Fin 2) ℝ) (hAh : A.IsHermitian)
    (hBh : B.IsHermitian) (a b : ℝ) (ha : a ^ 2 = A.det) (hb : b ^ 2 = B.det) :
    b • ((b • A + a • B) * A.adjugate * (b • A + a • B)) = (a * (b • A + a • B).det) • B := by
  have hA10 : A 1 0 = A 0 1 := by simpa using (hAh.apply 1 0).symm
  have hB10 : B 1 0 = B 0 1 := by simpa using (hBh.apply 1 0).symm
  rw [Matrix.det_fin_two, hA10] at ha
  rw [Matrix.det_fin_two, hB10] at hb
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [Matrix.adjugate_fin_two, Matrix.det_fin_two, Matrix.mul_apply, Fin.sum_univ_two,
      hA10, hB10]
  · linear_combination (-(B 0 0 * B 1 1 - B 0 1 * B 0 1) * (b * A 0 0 + a * B 0 0)) * ha
      + ((A 0 0 * A 1 1 - A 0 1 * A 0 1) * (b * A 0 0 + a * B 0 0)) * hb
  · linear_combination (-(B 0 0 * B 1 1 - B 0 1 * B 0 1) * (b * A 0 1 + a * B 0 1)) * ha
      + ((A 0 0 * A 1 1 - A 0 1 * A 0 1) * (b * A 0 1 + a * B 0 1)) * hb
  · linear_combination (-(B 0 0 * B 1 1 - B 0 1 * B 0 1) * (b * A 0 1 + a * B 0 1)) * ha
      + ((A 0 0 * A 1 1 - A 0 1 * A 0 1) * (b * A 0 1 + a * B 0 1)) * hb
  · linear_combination (-(B 0 0 * B 1 1 - B 0 1 * B 0 1) * (b * A 1 1 + a * B 1 1)) * ha
      + ((A 0 0 * A 1 1 - A 0 1 * A 0 1) * (b * A 1 1 + a * B 1 1)) * hb

/-- For two positive definite covariance matrices `A` and `B`, the affine-invariant average
`M = A^{1/2} (A^{-1/2} B A^{-1/2})^{1/2} A^{1/2}` is itself a positive definite covariance
matrix, it solves `M A⁻¹ M = B` (multiplying by `A⁻¹` in the middle undoes one half-step),
it is the only positive definite matrix that does, and its determinant (the generalised
variance) is `√(det A · det B)`. -/
theorem ai_mean_unique_pos_def_solution {n : Type*} [Fintype n] [DecidableEq n]
    {A B : Matrix n n ℝ} (hA : A.PosDef) (hB : B.PosDef) :
    (aiMean A B).PosDef ∧ aiMean A B * A⁻¹ * aiMean A B = B ∧
      (∀ X : Matrix n n ℝ, X.PosDef → X * A⁻¹ * X = B → X = aiMean A B) ∧
      (aiMean A B).det = Real.sqrt (A.det * B.det) := by
  obtain ⟨h1, h2, h3⟩ := aiMean_aux_spec hA hB
  refine ⟨h1, h2, h3, ?_⟩
  have hdA : A.det ≠ 0 := hA.det_pos.ne'
  have hd : (aiMean A B).det * A.det⁻¹ * (aiMean A B).det = B.det := by
    have := congrArg Matrix.det h2
    rwa [Matrix.det_mul, Matrix.det_mul, Matrix.det_nonsing_inv, Ring.inverse_eq_inv'] at this
  have hsq : A.det * B.det = (aiMean A B).det ^ 2 := by
    rw [← hd]; field_simp
  rw [hsq, Real.sqrt_sq h1.det_pos.le]

/-- The two-by-two closed form: for two assets, scale each estimate to determinant 1, add,
and scale back. With `S = A/√(det A) + B/√(det B)`, the affine-invariant average is
`√(√(det A) √(det B) / det S) · S`. -/
theorem ai_mean_two_by_two_closed_form {A B : Matrix (Fin 2) (Fin 2) ℝ}
    (hA : A.PosDef) (hB : B.PosDef) :
    aiMean A B =
      Real.sqrt (Real.sqrt A.det * Real.sqrt B.det /
          ((Real.sqrt A.det)⁻¹ • A + (Real.sqrt B.det)⁻¹ • B).det) •
        ((Real.sqrt A.det)⁻¹ • A + (Real.sqrt B.det)⁻¹ • B) := by
  obtain ⟨-, -, h3⟩ := aiMean_aux_spec hA hB
  have hdA := hA.det_pos
  have hdB := hB.det_pos
  set a := Real.sqrt A.det with ha_def
  set b := Real.sqrt B.det with hb_def
  have hapos : 0 < a := Real.sqrt_pos.mpr hdA
  have hbpos : 0 < b := Real.sqrt_pos.mpr hdB
  have ha2 : a ^ 2 = A.det := Real.sq_sqrt hdA.le
  have hb2 : b ^ 2 = B.det := Real.sq_sqrt hdB.le
  set S := a⁻¹ • A + b⁻¹ • B with hSdef
  have hS : S.PosDef := (hA.smul (inv_pos.mpr hapos)).add (hB.smul (inv_pos.mpr hbpos))
  set T := b • A + a • B with hTdef
  have hST : S = (a * b)⁻¹ • T := by
    rw [hSdef, hTdef, smul_add, smul_smul, smul_smul]
    congr 2 <;> field_simp
  have hdS : S.det = ((a * b)⁻¹) ^ 2 * T.det := by
    rw [hST, Matrix.det_smul]; simp
  have hdpos : 0 < S.det := hS.det_pos
  have hdT : 0 < T.det := by
    rw [hdS] at hdpos
    exact pos_of_mul_pos_right hdpos (by positivity)
  set c := Real.sqrt (a * b / S.det) with hc_def
  have hc : 0 < c := Real.sqrt_pos.mpr (by positivity)
  have hc2 : c ^ 2 = a * b / S.det := Real.sq_sqrt (by positivity)
  refine (h3 _ (hS.smul hc) ?_).symm
  have hAinv : A⁻¹ = (A.det)⁻¹ • A.adjugate := by rw [Matrix.inv_def, Ring.inverse_eq_inv']
  have key := aiMean_aux_two_key A B hA.isHermitian hB.isHermitian a b ha2 hb2
  have key' : T * A.adjugate * T = (b⁻¹ * (a * T.det)) • B := by
    rw [← smul_smul, ← key, smul_smul, inv_mul_cancel₀ hbpos.ne', one_smul]
  rw [hST, hAinv]
  simp only [Matrix.smul_mul, Matrix.mul_smul, smul_smul]
  rw [key', smul_smul]
  convert one_smul ℝ B
  rw [hdS] at hc2
  have hc2' : c ^ 2 * T.det = (a * b) ^ 3 := by
    rw [hc2]; field_simp
  rw [← ha2]
  field_simp
  linear_combination hc2'

/-- The affine-invariant average gives one answer in any units: re-expressing the assets as
new mixes with an invertible matrix `W` (each covariance matrix `Σ` becoming `W Σ Wᵀ`)
re-expresses the average the same way. It also gives one answer whether the matrices or
their inverses are stored: averaging the inverses gives the inverse of the average. -/
theorem ai_mean_affine_invariant {n : Type*} [Fintype n] [DecidableEq n]
    {A B : Matrix n n ℝ} (hA : A.PosDef) (hB : B.PosDef)
    (W : Matrix n n ℝ) (hW : IsUnit W.det) :
    aiMean (W * A * Wᵀ) (W * B * Wᵀ) = W * aiMean A B * Wᵀ ∧
      aiMean A⁻¹ B⁻¹ = (aiMean A B)⁻¹ := by
  obtain ⟨h1, h2, -⟩ := aiMean_aux_spec hA hB
  have hWu : IsUnit W := (Matrix.isUnit_iff_isUnit_det W).mpr hW
  have hWt : IsUnit Wᵀ.det := by rwa [Matrix.det_transpose]
  have conjW : ∀ X : Matrix n n ℝ, X.PosDef → (W * X * Wᵀ).PosDef := by
    intro X hX
    have h := (Matrix.IsUnit.posDef_star_right_conjugate_iff (x := X) hWu).mpr hX
    rwa [star_eq_conjTranspose, conjTranspose_eq_transpose_of_trivial] at h
  have hMd : IsUnit (aiMean A B).det := (Matrix.isUnit_iff_isUnit_det _).mp h1.isUnit
  have hAd : IsUnit A.det := (Matrix.isUnit_iff_isUnit_det _).mp hA.isUnit
  refine ⟨?_, ?_⟩
  · obtain ⟨-, -, h3'⟩ := aiMean_aux_spec (conjW A hA) (conjW B hB)
    refine (h3' _ (conjW _ h1) ?_).symm
    generalize aiMean A B = M at h1 h2 hMd ⊢
    subst h2
    rw [Matrix.mul_inv_rev, Matrix.mul_inv_rev]
    calc W * M * Wᵀ * (Wᵀ⁻¹ * (A⁻¹ * W⁻¹)) * (W * M * Wᵀ)
        = W * M * (Wᵀ * Wᵀ⁻¹) * A⁻¹ * (W⁻¹ * W) * M * Wᵀ := by
          simp only [Matrix.mul_assoc]
      _ = W * (M * A⁻¹ * M) * Wᵀ := by
          rw [Matrix.mul_nonsing_inv _ hWt, Matrix.nonsing_inv_mul _ hW]
          simp only [Matrix.mul_one, Matrix.mul_assoc]
  · obtain ⟨-, -, h3'⟩ := aiMean_aux_spec hA.inv hB.inv
    refine (h3' _ h1.inv ?_).symm
    generalize aiMean A B = M at h1 h2 hMd ⊢
    subst h2
    rw [Matrix.nonsing_inv_nonsing_inv _ hAd, Matrix.mul_inv_rev, Matrix.mul_inv_rev,
      Matrix.nonsing_inv_nonsing_inv _ hAd]
    simp only [Matrix.mul_assoc]

/-! The card's worked numbers, with A = [[16, 2], [2, 4]] (calm) and B = [[36, 9], [9, 9]]
(stress), in percent squared. -/

-- det A = 60 and det B = 243.
example : (!![16, 2; 2, 4] : Matrix (Fin 2) (Fin 2) ℝ).det = 60 := by
  norm_num [Matrix.det_fin_two_of]

example : (!![36, 9; 9, 9] : Matrix (Fin 2) (Fin 2) ℝ).det = 243 := by
  norm_num [Matrix.det_fin_two_of]

-- A⁻¹B has trace 4.2 and determinant 4.05.
example : ((!![16, 2; 2, 4] : Matrix (Fin 2) (Fin 2) ℝ)⁻¹ * !![36, 9; 9, 9]).trace = 21 / 5 := by
  norm_num [Matrix.inv_def, Matrix.adjugate_fin_two, Matrix.det_fin_two_of, Matrix.trace_fin_two]

example : ((!![16, 2; 2, 4] : Matrix (Fin 2) (Fin 2) ℝ)⁻¹ * !![36, 9; 9, 9]).det = 81 / 20 := by
  norm_num [Matrix.inv_def, Matrix.adjugate_fin_two, Matrix.det_fin_two_of]

-- The eigenvalues of A⁻¹B, the largest and smallest risk ratios, are 2.7 and 1.5:
-- det(B - λA) = 0 at both.
example : ((!![36, 9; 9, 9] : Matrix (Fin 2) (Fin 2) ℝ) - (27 / 10 : ℝ) • !![16, 2; 2, 4]).det
    = 0 := by
  norm_num [Matrix.det_fin_two]

example : ((!![36, 9; 9, 9] : Matrix (Fin 2) (Fin 2) ℝ) - (3 / 2 : ℝ) • !![16, 2; 2, 4]).det
    = 0 := by
  norm_num [Matrix.det_fin_two]

-- One asset: halfway between variances 16 and 36 on the ratio scale is 24.
example : (16 : ℝ) * (3 / 2) = 24 ∧ (24 : ℝ) * (3 / 2) = 36 ∧ (24 : ℝ) ^ 2 = 16 * 36 := by
  norm_num

-- The entry-by-entry average has determinant 138.75.
example : ((1 / 2 : ℝ) • ((!![16, 2; 2, 4] : Matrix (Fin 2) (Fin 2) ℝ) + !![36, 9; 9, 9])).det
    = 555 / 4 := by
  norm_num [Matrix.det_fin_two_of]

-- The straight line run back to t = -1 gives 2A - B = [[-4, -5], [-5, -1]]: stock variance -4.
example : (2 : ℝ) • (!![16, 2; 2, 4] : Matrix (Fin 2) (Fin 2) ℝ) - !![36, 9; 9, 9]
    = !![-4, -5; -5, -1] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num

-- The geodesic run back to t = -1 gives A B⁻¹ A = [[208/27, -4/27], [-4/27, 52/27]].
example : (!![16, 2; 2, 4] : Matrix (Fin 2) (Fin 2) ℝ) * (!![36, 9; 9, 9])⁻¹ * !![16, 2; 2, 4]
    = !![208 / 27, -4 / 27; -4 / 27, 52 / 27] := by
  norm_num [Matrix.inv_def, Matrix.adjugate_fin_two, Matrix.det_fin_two_of]

#print axioms aiMean_aux_sqrt_mul
#print axioms aiMean_aux_sqrt_posDef
#print axioms aiMean_aux_conj
#print axioms aiMean_aux_spec
#print axioms aiMean_aux_two_key
#print axioms ai_mean_unique_pos_def_solution
#print axioms ai_mean_two_by_two_closed_form
#print axioms ai_mean_affine_invariant
