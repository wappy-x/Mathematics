-- Matrix completion: a certificate table that ignores the gaps and stretches nothing by more than 1 puts a floor under the nuclear norm of every fill, the viewers' rank-1 fill reaches the floor 14, and the nuclear norm is the least half-trace of a positive semidefinite wrapper.
import Mathlib.Analysis.InnerProductSpace.SingularValues
import Mathlib.Analysis.CStarAlgebra.Matrix
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.Data.Matrix.Block
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Algebra.Order.Star.Real

open Matrix
open scoped Matrix.Norms.L2Operator

/-- The nuclear norm of a real table: the sum of its singular values, the singular values being
Mathlib's `LinearMap.singularValues` of the table acting on Euclidean space. -/
noncomputable def nuclearNorm {m n : Type*} [Fintype m] [Fintype n] [DecidableEq n]
    (X : Matrix m n ℝ) : ℝ :=
  (Matrix.toEuclideanLin X).singularValues.sum fun _ s => s

theorem svd_aux {m n : Type*} [Fintype m] [Fintype n] [DecidableEq m] [DecidableEq n]
    (X : Matrix m n ℝ) :
    ∃ (d : ℕ) (V : Matrix n (Fin d) ℝ) (U : Matrix m (Fin d) ℝ) (σ e : Fin d → ℝ),
      (∀ k, 0 ≤ σ k) ∧ (∀ k, e k ≤ 1) ∧ (∀ k, e k * σ k = σ k) ∧
      Vᵀ * V = 1 ∧ V * Vᵀ = 1 ∧ Uᵀ * U = diagonal e ∧ U * diagonal e = U ∧
      X = U * diagonal σ * Vᵀ ∧ nuclearNorm X = ∑ k, σ k := by
  set T := toEuclideanLin X with hTdef
  have hT := T.isSymmetric_adjoint_comp_self
  set d := Module.finrank ℝ (EuclideanSpace ℝ n) with hd
  set b := hT.eigenvectorBasis rfl with hb
  set lam := hT.eigenvalues rfl with hlamdef
  have hlam : ∀ k, 0 ≤ lam k := T.isPositive_adjoint_comp_self.nonneg_eigenvalues rfl
  let V : Matrix n (Fin d) ℝ := Matrix.of fun a k => b k a
  have hAV : Xᵀ * X * V = V * diagonal lam := by
    ext a k
    have key : ∀ w : EuclideanSpace ℝ n,
        (LinearMap.adjoint T ∘ₗ T) w = WithLp.toLp 2 ((Xᵀ * X) *ᵥ WithLp.ofLp w) := by
      intro w
      rw [hTdef, ← Matrix.toEuclideanLin_conjTranspose_eq_adjoint]
      simp [toLpLin_apply, Matrix.mulVec_mulVec]
    have h : (LinearMap.adjoint T ∘ₗ T) (b k) = (lam k : ℝ) • b k := hT.apply_eigenvectorBasis rfl k
    rw [key] at h
    have h2 := congrArg (fun v : EuclideanSpace ℝ n => v a) h
    simp only [PiLp.smul_apply, smul_eq_mul, mulVec, dotProduct] at h2
    rw [Matrix.mul_apply, Matrix.mul_diagonal]
    simpa [V, mul_comm] using h2
  have hnuc : nuclearNorm X = ∑ k, Real.sqrt (lam k) := by
    unfold nuclearNorm
    rw [Finsupp.sum_of_support_subset _ (s := Finset.range d)]
    · rw [Finset.sum_range]
      refine Finset.sum_congr rfl fun k _ => ?_
      exact T.singularValues_fin rfl k
    · rw [LinearMap.support_singularValues]
      exact Finset.range_subset_range.mpr (LinearMap.finrank_range_le T)
    · intros; rfl
  have hVV : Vᵀ * V = 1 := by
    ext k l
    have := b.inner_eq_ite k l
    rw [EuclideanSpace.inner_eq_star_dotProduct] at this
    simpa [V, Matrix.mul_apply, dotProduct, Matrix.one_apply, mul_comm] using this
  have hVV' : V * Vᵀ = 1 := by
    ext a c
    have h := congrArg (fun v : EuclideanSpace ℝ n => v c) (b.sum_repr' (EuclideanSpace.single a 1))
    simp only [EuclideanSpace.inner_eq_star_dotProduct] at h
    simpa [V, Matrix.mul_apply, dotProduct, Matrix.one_apply, Finset.sum_apply, eq_comm] using h
  set σ : Fin d → ℝ := fun k => Real.sqrt (lam k) with hσ
  set σi : Fin d → ℝ := fun k => (σ k)⁻¹ with hσi
  set e : Fin d → ℝ := fun k => if σ k = 0 then 0 else 1 with he
  have hlamσ : ∀ k, lam k = σ k * σ k := fun k => (Real.mul_self_sqrt (hlam k)).symm
  have hΛ : (X * V)ᵀ * (X * V) = diagonal lam := by
    rw [transpose_mul, Matrix.mul_assoc, ← Matrix.mul_assoc Xᵀ, hAV,
      ← Matrix.mul_assoc, hVV, Matrix.one_mul]
  refine ⟨d, V, X * V * diagonal σi, σ, e, fun k => Real.sqrt_nonneg _, ?_, ?_, hVV, hVV', ?_, ?_,
    ?_, ?_⟩
  · intro k; simp only [he]; split_ifs <;> norm_num
  · intro k; simp only [he]; split_ifs with h <;> simp [h]
  · rw [transpose_mul, diagonal_transpose, Matrix.mul_assoc, ← Matrix.mul_assoc (X * V)ᵀ, hΛ,
      diagonal_mul_diagonal, diagonal_mul_diagonal]
    congr 1; ext k
    simp only [he, hσi, hlamσ]
    split_ifs with h
    · simp [h]
    · field_simp
  · rw [Matrix.mul_assoc, diagonal_mul_diagonal]
    congr 2; ext k
    simp only [he, hσi]
    split_ifs with h <;> simp [h]
  · have hY : X * V * diagonal (fun k => 1 - e k) = 0 := by
      rw [← Matrix.conjTranspose_mul_self_eq_zero, conjTranspose_eq_transpose_of_trivial,
        transpose_mul, diagonal_transpose, Matrix.mul_assoc, ← Matrix.mul_assoc (X * V)ᵀ, hΛ,
        diagonal_mul_diagonal, diagonal_mul_diagonal]
      rw [← diagonal_zero]
      congr 1; ext k
      simp only [he, hlamσ]
      split_ifs with h <;> simp [h]
    have hXV : X * V * diagonal e = X * V := by
      have : diagonal e = 1 - diagonal (fun k => 1 - e k) := by
        ext k l; by_cases hkl : k = l <;> simp [diagonal, hkl]
      rw [this, Matrix.mul_sub, hY, Matrix.mul_one, sub_zero]
    have hσσ : diagonal σi * diagonal σ = diagonal e := by
      rw [diagonal_mul_diagonal]; congr 1; ext k
      simp only [he, hσi]
      split_ifs with h
      · simp [h]
      · field_simp
    rw [Matrix.mul_assoc (X * V), hσσ, hXV, Matrix.mul_assoc, hVV', Matrix.mul_one]
  · rw [hnuc]

theorem sum_mul_sum_eq_trace {m n : Type*} [Fintype m] [Fintype n] (W X : Matrix m n ℝ) :
    ∑ i, ∑ j, W i j * X i j = trace (Wᵀ * X) := by
  simp only [trace, diag, Matrix.mul_apply, transpose_apply]
  exact Finset.sum_comm

theorem col_norm_le {m n : Type*} [Fintype m] [Fintype n] [DecidableEq m] [DecidableEq n]
    (W : Matrix m n ℝ) (hW : ‖W‖ ≤ 1) (v : n → ℝ) (hv : ∑ j, v j ^ 2 ≤ 1) :
    ∑ i, (W *ᵥ v) i ^ 2 ≤ 1 := by
  have h1 := W.l2_opNorm_mulVec (WithLp.toLp 2 v)
  have hv' : ‖(WithLp.toLp 2 v : EuclideanSpace ℝ n)‖ ≤ 1 := by
    rw [EuclideanSpace.norm_eq]
    simp only [Real.norm_eq_abs, sq_abs]
    rw [Real.sqrt_le_one]
    simpa using hv
  have h2 : ‖(EuclideanSpace.equiv m ℝ).symm (W *ᵥ v)‖ ≤ 1 := by
    refine h1.trans ?_
    calc ‖W‖ * ‖(WithLp.toLp 2 v : EuclideanSpace ℝ n)‖ ≤ 1 * 1 :=
          mul_le_mul hW hv' (norm_nonneg _) zero_le_one
      _ = 1 := one_mul 1
  have h3 := EuclideanSpace.real_norm_sq_eq ((EuclideanSpace.equiv m ℝ).symm (W *ᵥ v))
  have h4 : ‖(EuclideanSpace.equiv m ℝ).symm (W *ᵥ v)‖ ^ 2 ≤ 1 := by
    have := norm_nonneg ((EuclideanSpace.equiv m ℝ).symm (W *ᵥ v))
    nlinarith
  rw [h3] at h4
  simpa using h4

theorem inner_le_nuclearNorm {m n : Type*} [Fintype m] [Fintype n] [DecidableEq m]
    [DecidableEq n] (W X : Matrix m n ℝ) (hW : ‖W‖ ≤ 1) :
    ∑ i, ∑ j, W i j * X i j ≤ nuclearNorm X := by
  obtain ⟨d, V, U, σ, e, hσ, he1, -, hVV, -, hUU, -, hX, hnuc⟩ := svd_aux X
  rw [sum_mul_sum_eq_trace, hnuc, hX, ← Matrix.mul_assoc, ← Matrix.mul_assoc,
    Matrix.trace_mul_comm, ← Matrix.mul_assoc, ← Matrix.mul_assoc]
  simp only [trace, diag, Matrix.mul_diagonal]
  refine Finset.sum_le_sum fun k _ => ?_
  refine mul_le_of_le_one_left (hσ k) ?_
  set a : m → ℝ := W *ᵥ (fun j => V j k) with ha
  set c : m → ℝ := fun i => U i k with hc
  have hrow : (Vᵀ * Wᵀ * U) k k = ∑ i, a i * c i := by
    simp only [Matrix.mul_apply, transpose_apply, ha, hc, mulVec, dotProduct, Finset.sum_mul]
    exact Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => by ring
  have hv : ∑ j, V j k ^ 2 ≤ 1 := by
    have := congrFun (congrFun hVV k) k
    simp only [Matrix.mul_apply, transpose_apply, Matrix.one_apply_eq] at this
    simp only [sq]; rw [this]
  have ha1 := col_norm_le W hW _ hv
  have hc1 : ∑ i, c i ^ 2 ≤ 1 := by
    have := congrFun (congrFun hUU k) k
    simp only [Matrix.mul_apply, transpose_apply, diagonal_apply_eq] at this
    simp only [hc, sq]; rw [this]; exact he1 k
  rw [hrow]
  calc ∑ i, a i * c i ≤ ∑ i, (a i ^ 2 + c i ^ 2) / 2 :=
        Finset.sum_le_sum fun i _ => by nlinarith [sq_nonneg (a i - c i)]
    _ = (∑ i, a i ^ 2 + ∑ i, c i ^ 2) / 2 := by rw [← Finset.sum_div, Finset.sum_add_distrib]
    _ ≤ 1 := by linarith

theorem trace_fromBlocks_aux {m n : Type*} [Fintype m] [Fintype n] (A : Matrix m m ℝ)
    (B : Matrix m n ℝ) (C : Matrix n m ℝ) (D : Matrix n n ℝ) :
    trace (fromBlocks A B C D) = trace A + trace D := by
  simp [trace, Fintype.sum_sum_type]

theorem psd_wrapper_mem {m n : Type*} [Fintype m] [Fintype n]
    [DecidableEq m] [DecidableEq n] (X : Matrix m n ℝ) :
    ∃ (P : Matrix m m ℝ) (Q : Matrix n n ℝ),
      (fromBlocks P X Xᵀ Q).PosSemidef ∧ nuclearNorm X = (trace P + trace Q) / 2 := by
  obtain ⟨d, V, U, σ, e, hσ, -, heσ, hVV, -, hUU, -, hX, hnuc⟩ := svd_aux X
  refine ⟨U * diagonal σ * Uᵀ, V * diagonal σ * Vᵀ, ?_, ?_⟩
  · have hD : (diagonal (Sum.elim σ (0 : Fin d → ℝ))).PosSemidef := by
      refine PosSemidef.diagonal fun i => ?_
      cases i with
      | inl k => exact hσ k
      | inr k => exact le_rfl
    have h := hD.mul_mul_conjTranspose_same (fromBlocks U (0 : Matrix m (Fin d) ℝ) V 0)
    convert h using 1
    rw [conjTranspose_eq_transpose_of_trivial, fromBlocks_transpose, ← fromBlocks_diagonal,
      fromBlocks_multiply, fromBlocks_multiply]
    simp only [Matrix.mul_zero, Matrix.zero_mul, add_zero, transpose_zero]
    congr 1
    · rw [hX, transpose_mul, transpose_mul, diagonal_transpose, transpose_transpose,
        Matrix.mul_assoc]
  · have hP : trace (U * diagonal σ * Uᵀ) = ∑ k, σ k := by
      rw [Matrix.trace_mul_comm, ← Matrix.mul_assoc, hUU, diagonal_mul_diagonal, trace_diagonal]
      exact Finset.sum_congr rfl fun k _ => heσ k
    have hQ : trace (V * diagonal σ * Vᵀ) = ∑ k, σ k := by
      rw [Matrix.trace_mul_comm, ← Matrix.mul_assoc, hVV, Matrix.one_mul, trace_diagonal]
    rw [hP, hQ, hnuc]; ring

theorem psd_wrapper_lower {m n : Type*} [Fintype m] [Fintype n]
    [DecidableEq m] [DecidableEq n] (X : Matrix m n ℝ) (P : Matrix m m ℝ) (Q : Matrix n n ℝ)
    (hM : (fromBlocks P X Xᵀ Q).PosSemidef) :
    nuclearNorm X ≤ (trace P + trace Q) / 2 := by
  obtain ⟨d, V, U, σ, e, hσ, -, heσ, hVV, hVV', hUU, hUe, hX, hnuc⟩ := svd_aux X
  have hP : P.PosSemidef := by
    have := hM.submatrix (Sum.inl : m → m ⊕ n)
    convert this using 1
    ext i j; simp
  -- the projection onto the range
  set Pr := U * Uᵀ with hPr
  have hPrPr : Pr * Pr = Pr := by
    rw [hPr, Matrix.mul_assoc, ← Matrix.mul_assoc Uᵀ, hUU, ← Matrix.mul_assoc, hUe]
  have hPrt : Prᵀ = Pr := by rw [hPr, transpose_mul, transpose_transpose]
  have hPPr : trace (Uᵀ * P * U) ≤ trace P := by
    have h1 := (hP.conjTranspose_mul_mul_same (1 - Pr)).trace_nonneg
    rw [conjTranspose_eq_transpose_of_trivial, transpose_sub, transpose_one, hPrt] at h1
    have h2 : trace ((1 - Pr) * P * (1 - Pr)) = trace P - trace (Uᵀ * P * U) := by
      rw [Matrix.trace_mul_comm, ← Matrix.mul_assoc]
      have h3 : (1 - Pr) * (1 - Pr) = 1 - Pr := by
        rw [Matrix.sub_mul, Matrix.mul_sub, Matrix.mul_sub, hPrPr]; simp
      rw [h3, Matrix.sub_mul, Matrix.one_mul, trace_sub, hPr, Matrix.mul_assoc,
        Matrix.trace_mul_comm U (Uᵀ * P), Matrix.mul_assoc]
    linarith
  have hB := (hM.conjTranspose_mul_mul_same
    (fromBlocks U (0 : Matrix m (Fin d) ℝ) (-V) 0)).trace_nonneg
  rw [conjTranspose_eq_transpose_of_trivial, fromBlocks_transpose, fromBlocks_multiply,
    fromBlocks_multiply, trace_fromBlocks_aux] at hB
  simp only [Matrix.mul_zero, Matrix.zero_mul, add_zero, transpose_zero, trace_zero,
    transpose_neg, Matrix.neg_mul, Matrix.mul_neg, Matrix.add_mul,
    trace_add, trace_neg] at hB
  have hUXV : trace (Uᵀ * X * V) = ∑ k, σ k := by
    rw [hX, ← Matrix.mul_assoc, ← Matrix.mul_assoc, hUU, Matrix.mul_assoc, hVV, Matrix.mul_one,
      diagonal_mul_diagonal, trace_diagonal]
    exact Finset.sum_congr rfl fun k _ => heσ k
  have hVXU : trace (Vᵀ * Xᵀ * U) = ∑ k, σ k := by
    rw [← hUXV, ← trace_transpose, transpose_mul, transpose_mul, transpose_transpose,
      transpose_transpose, Matrix.mul_assoc]
  have hVQV : trace (Vᵀ * Q * V) = trace Q := by
    rw [Matrix.trace_mul_comm, ← Matrix.mul_assoc, hVV', Matrix.one_mul]
  rw [hnuc]
  linarith

theorem opNorm_le_one_of_sq {m n : Type*} [Fintype m] [Fintype n] [DecidableEq m]
    [DecidableEq n] (W : Matrix m n ℝ) (h : ∀ v : n → ℝ, ∑ i, (W *ᵥ v) i ^ 2 ≤ ∑ j, v j ^ 2) :
    ‖W‖ ≤ 1 := by
  rw [l2_opNorm_def]
  refine ContinuousLinearMap.opNorm_le_bound _ zero_le_one fun x => ?_
  rw [one_mul, EuclideanSpace.norm_eq, EuclideanSpace.norm_eq]
  refine Real.sqrt_le_sqrt ?_
  simpa [Real.norm_eq_abs, sq_abs, toLpLin_apply] using h (WithLp.ofLp x)

theorem certificate_norm_le_one :
    ‖!![(4 / 14 : ℝ), 5 / 14, 0; 5 / 14, 7 / 14, 3 / 14; 0, 3 / 14, 12 / 14]‖ ≤ 1 := by
  refine opNorm_le_one_of_sq _ fun v => ?_
  simp [Fin.sum_univ_three, mulVec, dotProduct]
  nlinarith [sq_nonneg (v 0 + v 1 - v 2), sq_nonneg (-5 * v 0 + 4 * v 1 - v 2)]

#print axioms svd_aux
#print axioms sum_mul_sum_eq_trace
#print axioms col_norm_le
#print axioms inner_le_nuclearNorm
#print axioms trace_fromBlocks_aux
#print axioms psd_wrapper_mem
#print axioms psd_wrapper_lower
#print axioms opNorm_le_one_of_sq
#print axioms certificate_norm_le_one

/-- The dual certificate. Let `Ω` be the seen cells and `M` the true table. If a table `W` is zero
on every gap (every cell outside `Ω`) and its spectral norm (largest singular value) is at most 1,
then every fill `X` that agrees with `M` on the seen cells has nuclear norm at least
`⟨W, X⟩ = Σ W_ij X_ij`, and `⟨W, X⟩ = ⟨W, P_Ω(M)⟩` is the same number for every such fill:
a floor computed from the seen entries alone. -/
theorem nuclearNorm_ge_certificate_floor {m n : Type*} [Fintype m] [Fintype n]
    [DecidableEq m] [DecidableEq n]
    (Ω : Set (m × n)) [DecidablePred (· ∈ Ω)] (M W X : Matrix m n ℝ)
    (hW_gaps : ∀ i j, (i, j) ∉ Ω → W i j = 0) (hW_norm : ‖W‖ ≤ 1)
    (hX_seen : ∀ i j, (i, j) ∈ Ω → X i j = M i j) :
    ∑ i, ∑ j, W i j * X i j = ∑ i, ∑ j, W i j * (if (i, j) ∈ Ω then M i j else 0) ∧
    ∑ i, ∑ j, W i j * X i j ≤ nuclearNorm X := by
  refine ⟨?_, inner_le_nuclearNorm W X hW_norm⟩
  refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => ?_
  split_ifs with h
  · rw [hX_seen i j h]
  · rw [hW_gaps i j h, zero_mul, zero_mul]

/-- The viewers' table [[1, 2, ?], [2, 4, 6], [?, 6, 9]]: every fill of the two gaps has nuclear
norm at least 14, and the rank-1 fill u uᵀ with u = (1, 2, 3), which puts 3 in both gaps,
has nuclear norm exactly 14. So 14 is the least nuclear norm and the fill 3, 3 reaches it. -/
theorem viewers_least_nuclear_norm_is_14 :
    (∀ a b : ℝ, 14 ≤ nuclearNorm !![1, 2, a; 2, 4, 6; b, 6, 9]) ∧
    vecMulVec ![(1 : ℝ), 2, 3] ![1, 2, 3] = !![1, 2, 3; 2, 4, 6; 3, 6, 9] ∧
    nuclearNorm !![(1 : ℝ), 2, 3; 2, 4, 6; 3, 6, 9] = 14 := by
  have h1 : ∀ a b : ℝ, 14 ≤ nuclearNorm !![1, 2, a; 2, 4, 6; b, 6, 9] := by
    intro a b
    have := inner_le_nuclearNorm _ !![1, 2, a; 2, 4, 6; b, 6, 9] certificate_norm_le_one
    simp [Fin.sum_univ_three] at this
    linarith
  have h2 : vecMulVec ![(1 : ℝ), 2, 3] ![1, 2, 3] = !![1, 2, 3; 2, 4, 6; 3, 6, 9] := by
    ext i j
    fin_cases i <;> fin_cases j <;> simp [vecMulVec] <;> norm_num
  refine ⟨h1, h2, le_antisymm ?_ (h1 3 3)⟩
  rw [← h2]
  set u : Fin 3 → ℝ := ![1, 2, 3]
  have hpsd : (fromBlocks (vecMulVec u u) (vecMulVec u u) (vecMulVec u u)ᵀ
      (vecMulVec u u)).PosSemidef := by
    have := posSemidef_vecMulVec_self_star (Sum.elim u u)
    rw [star_trivial] at this
    convert this using 1
    ext (i | i) (j | j) <;> simp [vecMulVec_apply]
  refine (psd_wrapper_lower _ _ _ hpsd).trans (le_of_eq ?_)
  simp [u, trace, Fin.sum_univ_three]
  norm_num

/-- The semidefinite form: the nuclear norm of `X` is the least value of `(tr P + tr Q) / 2`
over all blocks `P`, `Q` that make the wrapper [[P, X], [Xᵀ, Q]] positive semidefinite. -/
theorem nuclearNorm_eq_least_half_trace_of_psd_wrapper {m n : Type*} [Fintype m] [Fintype n]
    [DecidableEq m] [DecidableEq n] (X : Matrix m n ℝ) :
    IsLeast {s : ℝ | ∃ (P : Matrix m m ℝ) (Q : Matrix n n ℝ),
      (fromBlocks P X Xᵀ Q).PosSemidef ∧ s = (trace P + trace Q) / 2} (nuclearNorm X) := by
  refine ⟨?_, ?_⟩
  · obtain ⟨P, Q, hPQ, h⟩ := psd_wrapper_mem X
    exact ⟨P, Q, hPQ, h⟩
  · rintro s ⟨P, Q, hPQ, rfl⟩
    exact psd_wrapper_lower X P Q hPQ

-- Rank 1 fills both gaps by ratios: row 1 is half of row 2, row 3 is 3/2 of row 2.
example : (6 : ℚ) / 2 = 3 ∧ (2 : ℚ) * (3 / 2) = 3 := by norm_num

-- The rank-1 fill is u uᵀ with u = (1, 2, 3), and its trace is 1 + 4 + 9 = 14.
example : vecMulVec ![(1 : ℤ), 2, 3] ![1, 2, 3] = !![1, 2, 3; 2, 4, 6; 3, 6, 9] := by decide
example : trace !![(1 : ℤ), 2, 3; 2, 4, 6; 3, 6, 9] = 14 := by decide

-- The certificate 14 W = [[4, 5, 0], [5, 7, 3], [0, 3, 12]] is u uᵀ + 3 w wᵀ with w = (1, 1, -1),
-- it is zero on both gaps, and 14 W u = 14 u, 14 W w = 9 w.
example : !![(4 : ℤ), 5, 0; 5, 7, 3; 0, 3, 12] =
    vecMulVec ![1, 2, 3] ![1, 2, 3] + 3 • vecMulVec ![1, 1, -1] ![1, 1, -1] := by decide
example : !![(4 : ℤ), 5, 0; 5, 7, 3; 0, 3, 12] 0 2 = 0 ∧
    !![(4 : ℤ), 5, 0; 5, 7, 3; 0, 3, 12] 2 0 = 0 := by decide
example : !![(4 : ℤ), 5, 0; 5, 7, 3; 0, 3, 12] *ᵥ ![1, 2, 3] = ![14, 28, 42] := by decide
example : !![(4 : ℤ), 5, 0; 5, 7, 3; 0, 3, 12] *ᵥ ![1, 1, -1] = ![9, 9, -9] := by decide

-- The certificate on the seen cells: 196 / 14 = 14, the floor.
example : (4 * 1 + 5 * 2 + 5 * 2 + 7 * 4 + 3 * 6 + 3 * 6 + 12 * 9 : ℤ) = 196 ∧
    (196 : ℚ) / 14 = 14 := by norm_num

-- Incoherence of u = (1, 2, 3): 3 × 9/14 = 27/14, out of a possible 3.
example : (3 : ℚ) * (9 / 14) = 27 / 14 := by norm_num

-- The 50 by 40 table of rank 2 has r (m + n - r) = 176 free numbers; 800 of 2000 cells seen.
example : 2 * (50 + 40 - 2) = 176 ∧ 2000 - 800 = 1200 ∧ 50 * 40 = 2000 := by norm_num

-- The grid search tries 121 × 121 = 14,641 fills.
example : 121 * 121 = 14641 := by norm_num

#print axioms nuclearNorm_ge_certificate_floor
#print axioms viewers_least_nuclear_norm_is_14
#print axioms nuclearNorm_eq_least_half_trace_of_psd_wrapper
