-- The structured singular value: for errors that are separate complex gains, mu sits between the spectral radius and the largest singular value of every rescaled matrix D M D⁻¹, rescaling leaves mu unchanged, and a rank-one matrix has mu equal to the sum of the sizes of its diagonal entries.
import Mathlib.Analysis.CStarAlgebra.Matrix
import Mathlib.Analysis.Normed.Algebra.Spectrum
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.NormNum

open Matrix
open scoped Matrix.Norms.L2Operator

/-- The structured singular value of a square complex matrix `M` for an error made of separate
complex gains, `Δ = diagonal δ`: one over the size of the smallest such error that makes
`I - M Δ` singular, and `0` when no such error exists (`sInf ∅ = 0` and `0⁻¹ = 0` in Lean).
The size of a diagonal error is `‖δ‖ = maxᵢ |δᵢ|`, which is its largest singular value. -/
noncomputable def structuredSingularValue {n : Type*} [Fintype n] [DecidableEq n]
    (M : Matrix n n ℂ) : ℝ :=
  (sInf {r : ℝ | ∃ δ : n → ℂ, ‖δ‖ = r ∧ (1 - M * diagonal δ).det = 0})⁻¹


lemma ssv_one_le_of_det_eq_zero {n : Type*} [Fintype n] [DecidableEq n] (M : Matrix n n ℂ)
    (δ : n → ℂ) (h : (1 - M * diagonal δ).det = 0) : 1 ≤ ‖M‖ * ‖δ‖ := by
  by_contra h'
  push Not at h'
  have hlt : ‖M * diagonal δ‖ < 1 :=
    (norm_mul_le _ _).trans_lt (by rw [l2_opNorm_diagonal]; exact h')
  have hu := isUnit_one_sub_of_norm_lt_one hlt
  rw [Matrix.isUnit_iff_isUnit_det, h] at hu
  exact not_isUnit_zero hu

lemma ssv_nonneg {n : Type*} [Fintype n] [DecidableEq n] (M : Matrix n n ℂ) :
    0 ≤ structuredSingularValue M := by
  unfold structuredSingularValue
  apply inv_nonneg.mpr
  apply Real.sInf_nonneg
  rintro r ⟨δ, rfl, -⟩
  exact norm_nonneg _

lemma ssv_le_norm {n : Type*} [Fintype n] [DecidableEq n] (M : Matrix n n ℂ) :
    structuredSingularValue M ≤ ‖M‖ := by
  unfold structuredSingularValue
  set S := {r : ℝ | ∃ δ : n → ℂ, ‖δ‖ = r ∧ (1 - M * diagonal δ).det = 0} with hS
  by_cases hne : S.Nonempty
  · have hne' := hne
    obtain ⟨r0, δ0, -, h0⟩ := hne'
    have hM : 0 < ‖M‖ := by
      have := ssv_one_le_of_det_eq_zero M δ0 h0
      rcases (norm_nonneg M).lt_or_eq with h | h
      · exact h
      · rw [← h] at this; simp at this; linarith
    have hle : ‖M‖⁻¹ ≤ sInf S := by
      apply le_csInf hne
      rintro r ⟨δ, rfl, hdet⟩
      rw [inv_le_iff_one_le_mul₀' hM]
      exact ssv_one_le_of_det_eq_zero M δ hdet
    exact inv_le_of_inv_le₀ hM hle
  · rw [Set.not_nonempty_iff_eq_empty] at hne
    rw [hne, Real.sInf_empty, _root_.inv_zero]
    exact norm_nonneg _

lemma ssv_det_scale {n : Type*} [Fintype n] [DecidableEq n] (M : Matrix n n ℂ)
    (d : n → ℝ) (hd : ∀ i, 0 < d i) (δ : n → ℂ) :
    (1 - diagonal (fun i => (d i : ℂ)) * M * diagonal (fun i => ((d i)⁻¹ : ℂ)) *
      diagonal δ).det = (1 - M * diagonal δ).det := by
  have e : diagonal (fun i => (d i : ℂ)) * M * diagonal (fun i => ((d i)⁻¹ : ℂ)) *
      diagonal δ = diagonal (fun i => (d i : ℂ)) *
        (M * (diagonal (fun i => ((d i)⁻¹ : ℂ)) * diagonal δ)) := by
    simp only [Matrix.mul_assoc]
  rw [e, det_one_sub_mul_comm, Matrix.mul_assoc, diagonal_mul_diagonal, diagonal_mul_diagonal]
  congr 4
  funext i
  have : (d i : ℂ) ≠ 0 := by exact_mod_cast (hd i).ne'
  field_simp

lemma ssv_det_rank_one {n : Type*} [Fintype n] [DecidableEq n] (u v δ : n → ℂ) :
    (1 - vecMulVec u v * diagonal δ).det = 1 - ∑ i, u i * v i * δ i := by
  have e : vecMulVec u v * diagonal δ =
      replicateCol (Fin 1) u * replicateRow (Fin 1) (v * δ) := by
    ext i j
    rw [mul_diagonal, vecMulVec_apply]
    simp [Matrix.mul_apply, replicateCol, replicateRow, mul_assoc]
  rw [e, det_one_sub_mul_comm, det_unique, Matrix.sub_apply, Matrix.one_apply_eq,
    replicateRow_mul_replicateCol_apply]
  congr 1
  simp only [dotProduct, Pi.mul_apply]
  exact Finset.sum_congr rfl fun i _ => by ring


lemma ssv_norm_le_of_mem_spectrum {n : Type*} [Fintype n] [DecidableEq n] (M : Matrix n n ℂ)
    (k : ℂ) (hk : k ∈ spectrum ℂ M) : ‖k‖ ≤ structuredSingularValue M := by
  rcases eq_or_ne k 0 with rfl | hk0
  · simpa using ssv_nonneg M
  have hdet : (1 - M * diagonal (fun _ => k⁻¹)).det = 0 := by
    rw [spectrum.mem_iff, Algebra.algebraMap_eq_smul_one, Matrix.isUnit_iff_isUnit_det,
      isUnit_iff_ne_zero, not_not] at hk
    have e : 1 - M * diagonal (fun _ : n => k⁻¹) = k⁻¹ • (k • (1 : Matrix n n ℂ) - M) := by
      rw [← smul_one_eq_diagonal, mul_smul_comm, Matrix.mul_one, smul_sub, smul_smul,
        inv_mul_cancel₀ hk0, one_smul]
    rw [e, det_smul, hk, mul_zero]
  unfold structuredSingularValue
  set S := {r : ℝ | ∃ δ : n → ℂ, ‖δ‖ = r ∧ (1 - M * diagonal δ).det = 0} with hS
  have hmem : ‖(fun _ : n => k⁻¹)‖ ∈ S := ⟨_, rfl, hdet⟩
  have hne : S.Nonempty := ⟨_, hmem⟩
  have hM : 0 < ‖M‖ := by
    have := ssv_one_le_of_det_eq_zero M _ hdet
    rcases (norm_nonneg M).lt_or_eq with h | h
    · exact h
    · rw [← h] at this; simp at this; linarith
  have hlow : ‖M‖⁻¹ ≤ sInf S := by
    apply le_csInf hne
    rintro r ⟨δ, rfl, hd⟩
    rw [inv_le_iff_one_le_mul₀' hM]
    exact ssv_one_le_of_det_eq_zero M δ hd
  have hpos : 0 < sInf S := lt_of_lt_of_le (inv_pos.mpr hM) hlow
  have hle : sInf S ≤ ‖(fun _ : n => k⁻¹)‖ := by
    apply csInf_le ⟨0, ?_⟩ hmem
    rintro r ⟨δ, rfl, -⟩
    exact norm_nonneg _
  have hle2 : ‖(fun _ : n => k⁻¹)‖ ≤ ‖k⁻¹‖ :=
    (pi_norm_le_iff_of_nonneg (norm_nonneg _)).mpr fun _ => le_rfl
  calc ‖k‖ = ‖k⁻¹‖⁻¹ := by rw [norm_inv, inv_inv]
    _ ≤ (sInf S)⁻¹ := inv_anti₀ hpos (hle.trans hle2)

lemma ssv_scale_eq {n : Type*} [Fintype n] [DecidableEq n] (M : Matrix n n ℂ)
    (d : n → ℝ) (hd : ∀ i, 0 < d i) :
    structuredSingularValue
      (diagonal (fun i => (d i : ℂ)) * M * diagonal (fun i => ((d i)⁻¹ : ℂ))) =
    structuredSingularValue M := by
  unfold structuredSingularValue
  simp_rw [ssv_det_scale M d hd]

lemma ssv_rank_one_lower {n : Type*} [Fintype n] (u v δ : n → ℂ)
    (hA : 0 < ∑ i, ‖u i * v i‖) (h : ∑ i, u i * v i * δ i = 1) :
    (∑ i, ‖u i * v i‖)⁻¹ ≤ ‖δ‖ := by
  rw [inv_le_iff_one_le_mul₀' hA]
  calc (1 : ℝ) = ‖∑ i, u i * v i * δ i‖ := by rw [h, norm_one]
    _ ≤ ∑ i, ‖u i * v i * δ i‖ := norm_sum_le _ _
    _ ≤ ∑ i, ‖u i * v i‖ * ‖δ‖ := Finset.sum_le_sum fun i _ => by
        rw [norm_mul]
        exact mul_le_mul_of_nonneg_left (norm_le_pi_norm δ i) (norm_nonneg _)
    _ = (∑ i, ‖u i * v i‖) * ‖δ‖ := (Finset.sum_mul _ _ _).symm

/-- The bounds. For separate complex errors, the structured singular value `μ(M)` is at least
the spectral radius of `M` (the size of its largest eigenvalue) and at most the largest
singular value `σ̄(D M D⁻¹)` for every scaling `D = diagonal d` with all `dᵢ > 0`; with no
scaling (`D = I`) this is the small-gain bound `μ(M) ≤ σ̄(M)`. -/
theorem spectralRadius_le_mu_le_scaled_largest_singular_value
    {n : Type*} [Fintype n] [DecidableEq n] (M : Matrix n n ℂ)
    (d : n → ℝ) (hd : ∀ i, 0 < d i) :
    spectralRadius ℂ M ≤ ENNReal.ofReal (structuredSingularValue M) ∧
    structuredSingularValue M ≤
      ‖diagonal (fun i => (d i : ℂ)) * M * diagonal (fun i => ((d i)⁻¹ : ℂ))‖ ∧
    structuredSingularValue M ≤ ‖M‖ := by
  refine ⟨?_, ?_, ssv_le_norm M⟩
  · apply iSup₂_le
    intro k hk
    rw [← ENNReal.ofReal_coe_nnreal, coe_nnnorm]
    apply ENNReal.ofReal_le_ofReal
    rcases mem_quasispectrum_iff.mp hk with h | h
    · rw [h, norm_zero]
      exact ssv_nonneg M
    · exact ssv_norm_le_of_mem_spectrum M k h
  · rw [← ssv_scale_eq M d hd]
    exact ssv_le_norm _

/-- Rescaling the signals between separate error blocks cannot change stability: for every
scaling `D = diagonal d` with all `dᵢ > 0`, `μ(D M D⁻¹) = μ(M)`. -/
theorem mu_scaling_invariant
    {n : Type*} [Fintype n] [DecidableEq n] (M : Matrix n n ℂ)
    (d : n → ℝ) (hd : ∀ i, 0 < d i) :
    structuredSingularValue
      (diagonal (fun i => (d i : ℂ)) * M * diagonal (fun i => ((d i)⁻¹ : ℂ))) =
    structuredSingularValue M := by
  exact ssv_scale_eq M d hd

/-- A rank-one matrix has a formula: if `M = u vᵀ`, then `μ(M) = Σᵢ |mᵢᵢ| = Σᵢ |uᵢ vᵢ|`;
for two blocks, `μ = |m₁₁| + |m₂₂|`. -/
theorem mu_rank_one_eq_sum_abs_diagonal
    {n : Type*} [Fintype n] [DecidableEq n] (u v : n → ℂ) :
    structuredSingularValue (vecMulVec u v) = ∑ i, ‖u i * v i‖ := by
  have hdet : ∀ δ : n → ℂ, (1 - vecMulVec u v * diagonal δ).det = 0 ↔
      ∑ i, u i * v i * δ i = 1 := by
    intro δ
    rw [ssv_det_rank_one, sub_eq_zero, eq_comm]
  unfold structuredSingularValue
  simp_rw [hdet]
  rcases (Finset.sum_nonneg (fun i _ => norm_nonneg (u i * v i)) :
      (0 : ℝ) ≤ ∑ i, ‖u i * v i‖).lt_or_eq with hA | hA
  · set A := ∑ i, ‖u i * v i‖ with hAdef
    have hAc : (A : ℂ) ≠ 0 := by exact_mod_cast hA.ne'
    let δ : n → ℂ := fun i => starRingEnd ℂ (u i * v i) / ((‖u i * v i‖ : ℂ) * A)
    have hsum : ∑ i, u i * v i * δ i = 1 := by
      have : ∀ i, u i * v i * δ i = (‖u i * v i‖ : ℂ) / A := by
        intro i
        rcases eq_or_ne (u i * v i) 0 with h0 | h0
        · simp [δ, h0]
        · have hn : (‖u i * v i‖ : ℂ) ≠ 0 := by exact_mod_cast (norm_pos_iff.mpr h0).ne'
          simp only [δ]
          rw [← mul_div_assoc, Complex.mul_conj']
          field_simp
      rw [Finset.sum_congr rfl fun i _ => this i, ← Finset.sum_div]
      rw [hAdef]
      push_cast
      exact div_self (by exact_mod_cast hA.ne')
    have key : IsLeast {r : ℝ | ∃ δ : n → ℂ, ‖δ‖ = r ∧ ∑ i, u i * v i * δ i = 1} A⁻¹ := by
      refine ⟨⟨δ, le_antisymm ?_ (ssv_rank_one_lower u v δ hA hsum), hsum⟩, ?_⟩
      · refine (pi_norm_le_iff_of_nonneg (inv_nonneg.mpr hA.le)).mpr fun i => ?_
        simp only [δ, norm_div, norm_mul, RCLike.norm_conj, Complex.norm_real, Real.norm_eq_abs,
          abs_norm, abs_of_pos hA]
        rcases eq_or_ne (‖u i‖ * ‖v i‖) 0 with h0 | h0
        · rw [h0]; simp [hA.le]
        · rw [div_mul_cancel_left₀ h0]
      · rintro r ⟨δ', rfl, h⟩
        exact ssv_rank_one_lower u v δ' hA h
    rw [key.csInf_eq, inv_inv]
  · have h0 : ∀ i, u i * v i = 0 := by
      intro i
      have := (Finset.sum_eq_zero_iff_of_nonneg (fun i _ => norm_nonneg (u i * v i))).mp
        hA.symm i (Finset.mem_univ i)
      exact norm_eq_zero.mp this
    have hempty : {r : ℝ | ∃ δ : n → ℂ, ‖δ‖ = r ∧ ∑ i, u i * v i * δ i = 1} = ∅ := by
      ext r
      simp [h0]
    rw [hempty, Real.sInf_empty, _root_.inv_zero, ← hA]

/-! The card's conveyor matrix at 2 rad/s, `M = [[1/2, 2], [1/8, 1/2]] = u vᵀ` with
`u = (1, 1/4)` and `v = (1/2, 2)`. -/

-- M is the rank-one product u vᵀ.
example : vecMulVec ![(1 : ℚ), 1/4] ![1/2, 2] = !![1/2, 2; 1/8, 1/2] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [vecMulVec]

-- Trace 1 and determinant 0, so the eigenvalues are 1 and 0 and ρ(M) = 1.
example : (!![(1 : ℚ)/2, 2; 1/8, 1/2]).trace = 1 := by
  norm_num [Matrix.trace, Fin.sum_univ_two]
example : (!![(1 : ℚ)/2, 2; 1/8, 1/2]).det = 0 := by
  norm_num [Matrix.det_fin_two_of]

-- The breaking pair δ₁ = δ₂ = 1: det(I - M) = 0.
example : (1 - !![(1 : ℚ)/2, 2; 1/8, 1/2]).det = 0 := by
  rw [Matrix.det_fin_two]; norm_num

-- M has rank one, so σ̄(M)² is the sum of the squared entries: 1/4 + 4 + 1/64 + 1/4 = (17/8)².
example : (1 : ℚ)/4 + 4 + 1/64 + 1/4 = (17/8)^2 := by norm_num

-- The best scaling: d² = (1/8)/2 = 1/16, so d = 1/4.
example : ((1 : ℚ)/8) / 2 = (1/4)^2 := by norm_num

-- At d = 1/4 the scaled matrix D M D⁻¹ has all four entries 1/2.
example : diagonal ![(1 : ℚ)/4, 1] * !![1/2, 2; 1/8, 1/2] * diagonal ![4, 1]
    = !![1/2, 1/2; 1/2, 1/2] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]

-- Its largest singular value squared is 4 × 1/4 = 1, so the upper bound meets ρ = 1.
example : 4 * ((1 : ℚ)/2)^2 = 1 := by norm_num

-- The rank-one formula: |m₁₁| + |m₂₂| = 1/2 + 1/2 = 1.
example : |(1 : ℚ)/2| + |1/2| = 1 := by norm_num

-- Scaling the wrong way, d = 4: σ̄² = 1/4 + 1/4 + (2·4)² + (1/8/4)² = (8 + 1/32)².
example : (1 : ℚ)/4 + 1/4 + (2 * 4)^2 + (1/8/4)^2 = (8 + 1/32)^2 := by norm_num

-- The flipped matrix [[1/2, -2], [1/8, -1/2]]: trace 0 and determinant 0, so ρ = 0 ...
example : (!![(1 : ℚ)/2, -2; 1/8, -1/2]).trace = 0 := by
  norm_num [Matrix.trace, Fin.sum_univ_two]
example : (!![(1 : ℚ)/2, -2; 1/8, -1/2]).det = 0 := by
  norm_num [Matrix.det_fin_two_of]

-- ... yet δ₁ = 1, δ₂ = -1 breaks it: det(I - M diag(1, -1)) = 0, so μ ≥ 1.
example : (1 - !![(1 : ℚ)/2, -2; 1/8, -1/2] * diagonal ![1, -1]).det = 0 := by
  rw [Matrix.det_fin_two]
  norm_num [Matrix.mul_apply, Matrix.vecMul, dotProduct, Fin.sum_univ_two]

#print axioms ssv_one_le_of_det_eq_zero
#print axioms ssv_nonneg
#print axioms ssv_le_norm
#print axioms ssv_det_scale
#print axioms ssv_det_rank_one
#print axioms ssv_norm_le_of_mem_spectrum
#print axioms ssv_scale_eq
#print axioms ssv_rank_one_lower
#print axioms spectralRadius_le_mu_le_scaled_largest_singular_value
#print axioms mu_scaling_invariant
#print axioms mu_rank_one_eq_sum_abs_diagonal
