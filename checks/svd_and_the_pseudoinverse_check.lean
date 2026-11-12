-- Singular value decomposition: keeping the top k layers of the SVD gives the closest rank-k matrix in the 2-norm and the Frobenius norm, noise moves each singular value by at most its 2-norm, and the pseudoinverse gives the shortest least-squares solution.
import Mathlib.Analysis.InnerProductSpace.SingularValues
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Topology.Algebra.Module.FiniteDimension
import Mathlib.LinearAlgebra.Matrix.Rank
import Mathlib.LinearAlgebra.Finsupp.LinearCombination
import Mathlib.Analysis.Matrix.Spectrum
import Mathlib.Algebra.Order.Star.Real

open Matrix

/-!
Conventions. A real `m × n` matrix `A` acts on Euclidean space through `Matrix.toEuclideanLin`.
Its singular values are Mathlib's `LinearMap.singularValues`, largest first and indexed from 0,
so the card's `σ_(k+1)` is `(toEuclideanLin A).singularValues k`.
The 2-norm `‖A‖₂` (largest stretch) is the operator norm of `toEuclideanLin A`;
the squared Frobenius norm `‖A‖_F²` is the sum of the squares of the entries.
-/

-- Helper lemmas used by the three theorems below.

section svdHelpers

open scoped RealInnerProductSpace

variable {E F : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] [FiniteDimensional ℝ E]
  [NormedAddCommGroup F] [InnerProductSpace ℝ F] [FiniteDimensional ℝ F]

/-- The squared length of `T x`, written in the eigenvector basis of `Tᵀ T`. -/
theorem svdAux_norm_sq (T : E →ₗ[ℝ] F) (x : E) :
    ‖T x‖ ^ 2 = ∑ i : Fin (Module.finrank ℝ E), T.singularValues i ^ 2 *
      ⟪T.isSymmetric_adjoint_comp_self.eigenvectorBasis rfl i, x⟫ ^ 2 := by
  set hT := T.isSymmetric_adjoint_comp_self
  set v := hT.eigenvectorBasis rfl
  have h1 : ‖T x‖ ^ 2 = ⟪x, (LinearMap.adjoint T ∘ₗ T) x⟫ := by
    rw [LinearMap.comp_apply, LinearMap.adjoint_inner_right, real_inner_self_eq_norm_sq]
  rw [h1, ← v.sum_repr' ((LinearMap.adjoint T ∘ₗ T) x), inner_sum]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [inner_smul_right, ← hT (v i) x, hT.apply_eigenvectorBasis rfl i, real_inner_smul_left,
    ← T.sq_singularValues_fin rfl i, real_inner_comm x (v i)]
  simp only [RCLike.ofReal_real_eq_id, id]
  ring

/-- The sum of `‖T bⱼ‖²` over any orthonormal basis is the sum of the squared singular values. -/
theorem svdAux_sum_sq_basis {ι : Type*} [Fintype ι] (T : E →ₗ[ℝ] F) (b : OrthonormalBasis ι ℝ E) :
    ∑ j, ‖T (b j)‖ ^ 2 = ∑ i ∈ Finset.range (Module.finrank ℝ E), T.singularValues i ^ 2 := by
  set v := T.isSymmetric_adjoint_comp_self.eigenvectorBasis rfl
  rw [← Fin.sum_univ_eq_sum_range (fun i => T.singularValues i ^ 2)]
  simp_rw [svdAux_norm_sq]
  rw [Finset.sum_comm]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [← Finset.mul_sum]
  simp_rw [real_inner_comm (b _)]
  rw [b.sum_sq_inner_right, v.orthonormal.1 i]
  simp

/-- Lower bound: any map of rank at most `k` misses `T` by at least `σ_k` in operator norm. -/
theorem svdAux_lower (T B : E →ₗ[ℝ] F) (k : ℕ) (hB : Module.finrank ℝ (LinearMap.range B) ≤ k) :
    T.singularValues k ≤ ‖LinearMap.toContinuousLinearMap (T - B)‖ := by
  by_cases hk : Module.finrank ℝ E ≤ k
  · rw [T.singularValues_of_finrank_le hk]; exact norm_nonneg _
  push Not at hk
  set v := T.isSymmetric_adjoint_comp_self.eigenvectorBasis rfl
  set f : Fin (k + 1) → E := fun j => v (Fin.castLE hk j)
  set W := Submodule.span ℝ (Set.range f)
  have hW : Module.finrank ℝ W = k + 1 := by
    have hli : LinearIndependent ℝ f :=
      v.orthonormal.linearIndependent.comp _ (Fin.castLE_injective hk)
    rw [finrank_span_eq_card hli, Fintype.card_fin]
  have hrn := LinearMap.finrank_range_add_finrank_ker (B.domRestrict W)
  have hle : Module.finrank ℝ (LinearMap.range (B.domRestrict W)) ≤ k :=
    (Submodule.finrank_mono (LinearMap.range_domRestrict_le_range B W)).trans hB
  have hker : LinearMap.ker (B.domRestrict W) ≠ ⊥ := by
    intro h
    rw [h, finrank_bot, hW] at hrn
    omega
  obtain ⟨z, hz, hz0⟩ := Submodule.exists_mem_ne_zero_of_ne_bot hker
  set w : E := (z : E)
  have hw0 : w ≠ 0 := fun h => hz0 (Subtype.ext h)
  have hBw : B w = 0 := hz
  have hcoef : ∀ i : Fin (Module.finrank ℝ E), k < i.val → ⟪v i, w⟫ = 0 := by
    intro i hi
    obtain ⟨c, hc⟩ := (Submodule.mem_span_range_iff_exists_fun ℝ).mp z.2
    rw [show w = (z : E) from rfl, ← hc, inner_sum]
    refine Finset.sum_eq_zero fun j _ => ?_
    rw [inner_smul_right, v.orthonormal.2 ?_, mul_zero]
    intro h
    have := congrArg Fin.val h
    simp at this
    omega
  have hsq : (T.singularValues k * ‖w‖) ^ 2 ≤ ‖T w‖ ^ 2 := by
    rw [mul_pow, ← v.sum_sq_inner_right w, Finset.mul_sum, svdAux_norm_sq]
    refine Finset.sum_le_sum fun i _ => ?_
    by_cases hi : k < i.val
    · rw [hcoef i hi]; simp
    · push Not at hi
      have h1 : T.singularValues k ≤ T.singularValues i := T.singularValues_antitone hi
      have h2 : T.singularValues k ^ 2 ≤ T.singularValues i ^ 2 :=
        pow_le_pow_left₀ (T.singularValues_nonneg k) h1 2
      exact mul_le_mul_of_nonneg_right h2 (sq_nonneg _)
  have h1 : T.singularValues k * ‖w‖ ≤ ‖T w‖ :=
    (pow_le_pow_iff_left₀ (mul_nonneg (T.singularValues_nonneg k) (norm_nonneg _))
      (norm_nonneg _) two_ne_zero).mp hsq
  have h2 : ‖T w‖ ≤ ‖LinearMap.toContinuousLinearMap (T - B)‖ * ‖w‖ := by
    have := (LinearMap.toContinuousLinearMap (T - B)).le_opNorm w
    rwa [LinearMap.coe_toContinuousLinearMap', LinearMap.sub_apply, hBw, sub_zero] at this
  exact le_of_mul_le_mul_right (h1.trans h2) (norm_pos_iff.mpr hw0)

/-- Truncation: keeping the top `k` eigen-directions gives a map of rank at most `k` that misses
`T` by exactly `σ_k` in operator norm, and whose error has squared singular values
`σ_k², …, σ_(n-1)²` in total. -/
theorem svdAux_trunc (T : E →ₗ[ℝ] F) (k : ℕ) :
    ∃ C : E →ₗ[ℝ] F, Module.finrank ℝ (LinearMap.range C) ≤ k ∧
      ‖LinearMap.toContinuousLinearMap (T - C)‖ = T.singularValues k ∧
      ∑ i ∈ Finset.range (Module.finrank ℝ E), (T - C).singularValues i ^ 2
        = ∑ i ∈ Finset.Ico k (Module.finrank ℝ E), T.singularValues i ^ 2 := by
  classical
  set v := T.isSymmetric_adjoint_comp_self.eigenvectorBasis rfl
  set s := Finset.univ.filter (fun i : Fin (Module.finrank ℝ E) => i.val < k)
  set P : E →ₗ[ℝ] E := ∑ i ∈ s, (innerₛₗ ℝ (v i)).smulRight (v i)
  have hP : ∀ x, P x = ∑ i ∈ s, ⟪v i, x⟫ • v i := by
    intro x; simp [P]
  have hvv : ∀ i j, ⟪v i, v j⟫ = if i = j then (1 : ℝ) else 0 :=
    fun i j => orthonormal_iff_ite.mp v.orthonormal i j
  have hPin : ∀ x j, ⟪v j, x - P x⟫ = if j ∈ s then 0 else ⟪v j, x⟫ := by
    intro x j
    rw [inner_sub_right, hP, inner_sum]
    simp_rw [inner_smul_right, hvv, mul_ite, mul_one, mul_zero]
    rw [Finset.sum_ite_eq]
    split_ifs <;> simp [real_inner_comm]
  have hPv : ∀ j, v j - P (v j) = if j ∈ s then 0 else v j := by
    intro j
    rw [hP]
    simp_rw [hvv, ite_smul, one_smul, zero_smul]
    rw [Finset.sum_ite_eq']
    split_ifs <;> simp
  have hTC : ∀ x, (T - T ∘ₗ P) x = T (x - P x) := by
    intro x; simp [map_sub]
  have hrank : Module.finrank ℝ (LinearMap.range (T ∘ₗ P)) ≤ k := by
    rw [LinearMap.range_comp]
    refine (Submodule.finrank_map_le T _).trans ?_
    have hsub : LinearMap.range P ≤ Submodule.span ℝ ((s.image v : Finset E) : Set E) := by
      rintro _ ⟨x, rfl⟩
      rw [hP]
      refine Submodule.sum_mem _ fun i hi => Submodule.smul_mem _ _ (Submodule.subset_span ?_)
      simp only [Finset.coe_image]
      exact Set.mem_image_of_mem _ hi
    refine (Submodule.finrank_mono hsub).trans ((finrank_span_finset_le_card _).trans ?_)
    refine Finset.card_image_le.trans ?_
    calc s.card ≤ (Finset.range k).card := by
          refine Finset.card_le_card_of_injOn Fin.val ?_ (fun a _ b _ h => Fin.ext h)
          intro i hi
          simp only [s, Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq] at hi
          simpa using hi
      _ = k := Finset.card_range k
  have hup : ‖LinearMap.toContinuousLinearMap (T - T ∘ₗ P)‖ ≤ T.singularValues k := by
    refine ContinuousLinearMap.opNorm_le_bound _ (T.singularValues_nonneg k) fun x => ?_
    rw [LinearMap.coe_toContinuousLinearMap', hTC]
    refine (pow_le_pow_iff_left₀ (norm_nonneg _)
      (mul_nonneg (T.singularValues_nonneg k) (norm_nonneg _)) two_ne_zero).mp ?_
    rw [mul_pow, ← v.sum_sq_inner_right x, Finset.mul_sum, svdAux_norm_sq]
    refine Finset.sum_le_sum fun i _ => ?_
    rw [hPin]
    split_ifs with hi
    · simp only [ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, mul_zero]
      exact mul_nonneg (sq_nonneg _) (sq_nonneg _)
    · have hki : k ≤ i.val := by
        simp only [s, Finset.mem_filter, Finset.mem_univ, true_and] at hi
        omega
      have h1 : T.singularValues i ≤ T.singularValues k := T.singularValues_antitone hki
      have h2 : T.singularValues i ^ 2 ≤ T.singularValues k ^ 2 :=
        pow_le_pow_left₀ (T.singularValues_nonneg i) h1 2
      exact mul_le_mul_of_nonneg_right h2 (sq_nonneg _)
  refine ⟨T ∘ₗ P, hrank, le_antisymm hup (svdAux_lower T _ k hrank), ?_⟩
  rw [← svdAux_sum_sq_basis (T - T ∘ₗ P) v]
  have hj : ∀ j, ‖(T - T ∘ₗ P) (v j)‖ ^ 2
      = if j.val < k then 0 else T.singularValues j ^ 2 := by
    intro j
    rw [hTC, hPv]
    by_cases hj : j ∈ s
    · have : j.val < k := by simpa [s] using hj
      simp [hj, this]
    · have : ¬ j.val < k := by simpa [s] using hj
      simp only [hj, ite_false, this]
      rw [svdAux_norm_sq]
      change ∑ i : Fin (Module.finrank ℝ E), T.singularValues i ^ 2 * ⟪v i, v j⟫ ^ 2 = _
      simp_rw [hvv]
      simp
  simp_rw [hj]
  rw [Fin.sum_univ_eq_sum_range (fun i => if i < k then (0 : ℝ) else T.singularValues i ^ 2),
    Finset.sum_ite, Finset.sum_const_zero, zero_add]
  congr 1
  ext i
  simp only [Finset.mem_filter, Finset.mem_range, Finset.mem_Ico]
  omega

/-- Interlacing: removing a map of rank at most `k` lowers the index of each singular value by at
most `k`. -/
theorem svdAux_shift (T B : E →ₗ[ℝ] F) (k j : ℕ)
    (hB : Module.finrank ℝ (LinearMap.range B) ≤ k) :
    T.singularValues (k + j) ≤ (T - B).singularValues j := by
  obtain ⟨C, hC, hCn, -⟩ := svdAux_trunc (T - B) j
  have hBC : Module.finrank ℝ (LinearMap.range (B + C)) ≤ k + j :=
    (Submodule.finrank_mono (LinearMap.range_add_le B C)).trans
      ((Submodule.finrank_add_le_finrank_add_finrank _ _).trans (add_le_add hB hC))
  have h := svdAux_lower T (B + C) (k + j) hBC
  rwa [show T - (B + C) = (T - B) - C by abel, hCn] at h

/-- Eckart–Young in the Frobenius norm, for linear maps. -/
theorem svdAux_frob (T B : E →ₗ[ℝ] F) (k : ℕ)
    (hB : Module.finrank ℝ (LinearMap.range B) ≤ k) :
    ∑ i ∈ Finset.Ico k (Module.finrank ℝ E), T.singularValues i ^ 2
      ≤ ∑ i ∈ Finset.range (Module.finrank ℝ E), (T - B).singularValues i ^ 2 := by
  rw [Finset.sum_Ico_eq_sum_range]
  calc ∑ j ∈ Finset.range (Module.finrank ℝ E - k), T.singularValues (k + j) ^ 2
      ≤ ∑ j ∈ Finset.range (Module.finrank ℝ E - k), (T - B).singularValues j ^ 2 :=
        Finset.sum_le_sum fun j _ =>
          pow_le_pow_left₀ (T.singularValues_nonneg _) (svdAux_shift T B k j hB) 2
    _ ≤ ∑ j ∈ Finset.range (Module.finrank ℝ E), (T - B).singularValues j ^ 2 :=
        Finset.sum_le_sum_of_subset_of_nonneg
          (Finset.range_subset_range.mpr (Nat.sub_le _ _)) (fun _ _ _ => sq_nonneg _)

/-- Weyl's bound for linear maps: adding `D` raises each singular value by at most `‖D‖`. -/
theorem svdAux_weyl (T D : E →ₗ[ℝ] F) (i : ℕ) :
    (T + D).singularValues i ≤ T.singularValues i + ‖LinearMap.toContinuousLinearMap D‖ := by
  obtain ⟨C, hC, hCn, -⟩ := svdAux_trunc T i
  calc (T + D).singularValues i ≤ ‖LinearMap.toContinuousLinearMap (T + D - C)‖ :=
        svdAux_lower (T + D) C i hC
    _ = ‖LinearMap.toContinuousLinearMap (T - C) + LinearMap.toContinuousLinearMap D‖ := by
        rw [show T + D - C = (T - C) + D by abel, map_add]
    _ ≤ _ := by rw [← hCn]; exact norm_add_le _ _

end svdHelpers

theorem svdAux_mat_rank {m n : ℕ} (B : Matrix (Fin m) (Fin n) ℝ) :
    B.rank = Module.finrank ℝ (LinearMap.range (toEuclideanLin B)) := by
  rw [toEuclideanLin_eq_toLin_orthonormal]
  exact B.rank_eq_finrank_range_toLin _ _

theorem svdAux_mat_frob {m n : ℕ} (M : Matrix (Fin m) (Fin n) ℝ) :
    ∑ i, ∑ j, M i j ^ 2 = ∑ i ∈ Finset.range n, (toEuclideanLin M).singularValues i ^ 2 := by
  have h := svdAux_sum_sq_basis (toEuclideanLin M) (EuclideanSpace.basisFun (Fin n) ℝ)
  rw [finrank_euclideanSpace_fin] at h
  rw [← h, Finset.sum_comm]
  refine Finset.sum_congr rfl fun j _ => ?_
  rw [EuclideanSpace.norm_sq_eq]
  simp [toLpLin_apply]

/-- A real symmetric matrix `S` has a symmetric generalized inverse `G` that commutes with it. -/
theorem svdAux_sym_ginv {n : ℕ} (S : Matrix (Fin n) (Fin n) ℝ) (hS : Sᵀ = S) :
    ∃ G : Matrix (Fin n) (Fin n) ℝ, Gᵀ = G ∧ S * G * S = S ∧ G * S * G = G ∧ G * S = S * G := by
  have hH : S.IsHermitian := by
    rw [IsHermitian, conjTranspose_eq_transpose_of_trivial, hS]
  set U := hH.eigenvectorUnitary
  set φ := Unitary.conjStarAlgAut ℝ (Matrix (Fin n) (Fin n) ℝ) U
  set d : Fin n → ℝ := RCLike.ofReal ∘ hH.eigenvalues
  have hSd : S = φ (diagonal d) := hH.spectral_theorem
  refine ⟨φ (diagonal d⁻¹), ?_, ?_, ?_, ?_⟩
  · rw [← conjTranspose_eq_transpose_of_trivial, ← star_eq_conjTranspose, ← map_star,
      star_eq_conjTranspose, diagonal_conjTranspose, star_trivial]
  · rw [hSd, ← map_mul, ← map_mul, diagonal_mul_diagonal, diagonal_mul_diagonal]
    congr 2
    funext i
    simp only [Pi.inv_apply]
    by_cases h : d i = 0
    · simp [h]
    · field_simp
  · rw [hSd, ← map_mul, ← map_mul, diagonal_mul_diagonal, diagonal_mul_diagonal]
    congr 2
    funext i
    simp only [Pi.inv_apply]
    by_cases h : d i = 0
    · simp [h]
    · field_simp
  · rw [hSd, ← map_mul, ← map_mul, diagonal_mul_diagonal, diagonal_mul_diagonal]
    congr 2
    funext i
    simp only [Pi.inv_apply]
    ring

/-- Any two matrices meeting Penrose's four conditions are equal. -/
theorem svdAux_penrose_unique {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ)
    (X Y : Matrix (Fin n) (Fin m) ℝ)
    (hX1 : A * X * A = A) (hX2 : X * A * X = X) (hX3 : (A * X)ᵀ = A * X) (hX4 : (X * A)ᵀ = X * A)
    (hY1 : A * Y * A = A) (hY2 : Y * A * Y = Y) (hY3 : (A * Y)ᵀ = A * Y) (hY4 : (Y * A)ᵀ = Y * A) :
    X = Y := by
  have hAt1 : Aᵀ = Aᵀ * (A * Y) := by
    conv_lhs => rw [← hY1]
    rw [transpose_mul, hY3]
  have hAt2 : Aᵀ = (X * A) * Aᵀ := by
    conv_lhs => rw [← hX1]
    rw [Matrix.mul_assoc, transpose_mul, hX4]
  have hX : X = X * A * Y := by
    calc X = X * (A * X) := by rw [← Matrix.mul_assoc, hX2]
      _ = X * (A * X)ᵀ := by rw [hX3]
      _ = X * (Xᵀ * (Aᵀ * (A * Y))) := by rw [transpose_mul, ← hAt1]
      _ = X * ((A * X)ᵀ * (A * Y)) := by rw [transpose_mul, Matrix.mul_assoc]
      _ = (X * A * X) * A * Y := by rw [hX3]; simp only [Matrix.mul_assoc]
      _ = X * A * Y := by rw [hX2]
  have hY : Y = X * A * Y := by
    calc Y = (Y * A) * Y := by rw [hY2]
      _ = (Y * A)ᵀ * Y := by rw [hY4]
      _ = ((X * A) * Aᵀ * Yᵀ) * Y := by rw [transpose_mul, ← hAt2]
      _ = (X * A) * (Y * A)ᵀ * Y := by rw [transpose_mul]; simp only [Matrix.mul_assoc]
      _ = (X * A) * (Y * A * Y) := by rw [hY4]; simp only [Matrix.mul_assoc]
      _ = X * A * Y := by rw [hY2]
  rw [hX, ← hY]

/-- Some matrix meets Penrose's four conditions: `X = G Aᵀ` with `G` a symmetric generalized
inverse of `Aᵀ A`. -/
theorem svdAux_penrose_exists {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) :
    ∃ X : Matrix (Fin n) (Fin m) ℝ,
      A * X * A = A ∧ X * A * X = X ∧ (A * X)ᵀ = A * X ∧ (X * A)ᵀ = X * A := by
  have hS : (Aᵀ * A)ᵀ = Aᵀ * A := by rw [transpose_mul, transpose_transpose]
  obtain ⟨G, hGt, h1, h2, h3⟩ := svdAux_sym_ginv (Aᵀ * A) hS
  have hN : A * (G * (Aᵀ * A)) = A := by
    have hSN : (Aᵀ * A) * (G * (Aᵀ * A) - 1) = 0 := by
      rw [Matrix.mul_sub, ← Matrix.mul_assoc, h1, Matrix.mul_one, sub_self]
    have hM : (A * (G * (Aᵀ * A) - 1))ᴴ * (A * (G * (Aᵀ * A) - 1)) = 0 := by
      rw [conjTranspose_eq_transpose_of_trivial, transpose_mul, Matrix.mul_assoc,
        ← Matrix.mul_assoc Aᵀ, hSN, Matrix.mul_zero]
    have h := conjTranspose_mul_self_eq_zero.mp hM
    rwa [Matrix.mul_sub, Matrix.mul_one, sub_eq_zero] at h
  refine ⟨G * Aᵀ, ?_, ?_, ?_, ?_⟩
  · calc A * (G * Aᵀ) * A = A * (G * (Aᵀ * A)) := by simp only [Matrix.mul_assoc]
      _ = A := hN
  · calc G * Aᵀ * A * (G * Aᵀ) = G * (Aᵀ * A) * G * Aᵀ := by simp only [Matrix.mul_assoc]
      _ = G * Aᵀ := by rw [h2]
  · rw [transpose_mul, transpose_mul, transpose_transpose, hGt, Matrix.mul_assoc]
  · rw [Matrix.mul_assoc, transpose_mul, hS, hGt, h3]

/-- If `X` meets Penrose's four conditions, `X y` is the shortest least-squares solution. -/
theorem svdAux_least_squares {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ)
    (X : Matrix (Fin n) (Fin m) ℝ)
    (h1 : A * X * A = A) (h2 : X * A * X = X) (h3 : (A * X)ᵀ = A * X) (h4 : (X * A)ᵀ = X * A)
    (y : Fin m → ℝ) :
    (∀ x : Fin n → ℝ, (A *ᵥ (X *ᵥ y) - y) ⬝ᵥ (A *ᵥ (X *ᵥ y) - y) ≤ (A *ᵥ x - y) ⬝ᵥ (A *ᵥ x - y)) ∧
      ∀ x : Fin n → ℝ,
        (A *ᵥ x - y) ⬝ᵥ (A *ᵥ x - y) ≤ (A *ᵥ (X *ᵥ y) - y) ⬝ᵥ (A *ᵥ (X *ᵥ y) - y) →
        x ≠ X *ᵥ y → (X *ᵥ y) ⬝ᵥ (X *ᵥ y) < x ⬝ᵥ x := by
  have hAtAX : Aᵀ * A * X = Aᵀ := by
    rw [Matrix.mul_assoc, ← h3, ← transpose_mul, h1]
  have hAr : Aᵀ *ᵥ (A *ᵥ (X *ᵥ y) - y) = 0 := by
    rw [mulVec_sub, mulVec_mulVec, mulVec_mulVec, hAtAX, sub_self]
  have horth : ∀ z, (A *ᵥ z) ⬝ᵥ (A *ᵥ (X *ᵥ y) - y) = 0 := by
    intro z
    rw [dotProduct_comm, dotProduct_mulVec, ← mulVec_transpose, hAr, zero_dotProduct]
  have hsplit : ∀ x, (A *ᵥ x - y) ⬝ᵥ (A *ᵥ x - y)
      = (A *ᵥ (x - X *ᵥ y)) ⬝ᵥ (A *ᵥ (x - X *ᵥ y))
        + (A *ᵥ (X *ᵥ y) - y) ⬝ᵥ (A *ᵥ (X *ᵥ y) - y) := by
    intro x
    have h : A *ᵥ x - y = A *ᵥ (x - X *ᵥ y) + (A *ᵥ (X *ᵥ y) - y) := by
      rw [mulVec_sub]; abel
    rw [h, add_dotProduct, dotProduct_add, dotProduct_add, horth,
      dotProduct_comm (A *ᵥ (X *ᵥ y) - y), horth]
    ring
  have hnnm : ∀ u : Fin m → ℝ, 0 ≤ u ⬝ᵥ u :=
    fun u => Finset.sum_nonneg fun i _ => mul_self_nonneg (u i)
  have hnnn : ∀ u : Fin n → ℝ, 0 ≤ u ⬝ᵥ u :=
    fun u => Finset.sum_nonneg fun i _ => mul_self_nonneg (u i)
  refine ⟨fun x => by rw [hsplit x]; linarith [hnnm (A *ᵥ (x - X *ᵥ y))], fun x hx hne => ?_⟩
  have hz : A *ᵥ (x - X *ᵥ y) = 0 := by
    rw [hsplit x] at hx
    exact dotProduct_self_eq_zero.mp (le_antisymm (by linarith) (hnnm _))
  have hz0 : x - X *ᵥ y ≠ 0 := sub_ne_zero.mpr hne
  have hp : X *ᵥ y = (X * A) *ᵥ (X *ᵥ y) := by rw [mulVec_mulVec, h2]
  have hpz : (X *ᵥ y) ⬝ᵥ (x - X *ᵥ y) = 0 := by
    calc (X *ᵥ y) ⬝ᵥ (x - X *ᵥ y) = ((X * A) *ᵥ (X *ᵥ y)) ⬝ᵥ (x - X *ᵥ y) := by rw [← hp]
      _ = ((X * A)ᵀ *ᵥ (x - X *ᵥ y)) ⬝ᵥ (X *ᵥ y) := by
        rw [dotProduct_comm, dotProduct_mulVec, mulVec_transpose]
      _ = 0 := by rw [h4, ← mulVec_mulVec, hz, mulVec_zero, zero_dotProduct]
  have hpos : 0 < (x - X *ᵥ y) ⬝ᵥ (x - X *ᵥ y) :=
    lt_of_le_of_ne (hnnn _) (Ne.symm (mt dotProduct_self_eq_zero.mp hz0))
  have hx' : x = X *ᵥ y + (x - X *ᵥ y) := by abel
  rw [hx', add_dotProduct, dotProduct_add, dotProduct_add, hpz,
    dotProduct_comm (x - X *ᵥ y), hpz]
  linarith

#print axioms svdAux_norm_sq
#print axioms svdAux_sum_sq_basis
#print axioms svdAux_lower
#print axioms svdAux_trunc
#print axioms svdAux_shift
#print axioms svdAux_frob
#print axioms svdAux_weyl
#print axioms svdAux_mat_rank
#print axioms svdAux_mat_frob
#print axioms svdAux_sym_ginv
#print axioms svdAux_penrose_unique
#print axioms svdAux_penrose_exists
#print axioms svdAux_least_squares

/-- Eckart–Young. For any real `m × n` matrix `A` and any `k`: every matrix `B` of rank at most `k`
misses `A` by at least `σ_(k+1)` in the 2-norm and by at least `σ_(k+1)² + … + σ_n²` in the squared
Frobenius norm, and some matrix `A_k` of rank at most `k` (the top `k` layers) attains both
bounds exactly. So the top `k` layers are the closest rank-`k` table in both norms. -/
theorem best_rank_k_fit_keeps_top_k_layers {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (k : ℕ) :
    (∀ B : Matrix (Fin m) (Fin n) ℝ, B.rank ≤ k →
        (toEuclideanLin A).singularValues k
            ≤ ‖LinearMap.toContinuousLinearMap (toEuclideanLin (A - B))‖ ∧
        ∑ i ∈ Finset.Ico k n, (toEuclideanLin A).singularValues i ^ 2
            ≤ ∑ i, ∑ j, (A - B) i j ^ 2) ∧
    ∃ Ak : Matrix (Fin m) (Fin n) ℝ, Ak.rank ≤ k ∧
        ‖LinearMap.toContinuousLinearMap (toEuclideanLin (A - Ak))‖
            = (toEuclideanLin A).singularValues k ∧
        ∑ i, ∑ j, (A - Ak) i j ^ 2
            = ∑ i ∈ Finset.Ico k n, (toEuclideanLin A).singularValues i ^ 2 := by
  refine ⟨fun B hB => ?_, ?_⟩
  · have hB' : Module.finrank ℝ (LinearMap.range (toEuclideanLin B)) ≤ k := by
      rwa [← svdAux_mat_rank]
    refine ⟨?_, ?_⟩
    · rw [map_sub]; exact svdAux_lower _ _ k hB'
    · have h := svdAux_frob (toEuclideanLin A) (toEuclideanLin B) k hB'
      rw [finrank_euclideanSpace_fin] at h
      rwa [svdAux_mat_frob, map_sub]
  · obtain ⟨C, hC, hCn, hCf⟩ := svdAux_trunc (toEuclideanLin A) k
    rw [finrank_euclideanSpace_fin] at hCf
    refine ⟨toEuclideanLin.symm C, ?_, ?_, ?_⟩
    · rw [svdAux_mat_rank, LinearEquiv.apply_symm_apply]; exact hC
    · rw [map_sub, LinearEquiv.apply_symm_apply, hCn]
    · rw [svdAux_mat_frob, map_sub, LinearEquiv.apply_symm_apply, hCf]

/-- Weyl's bound. If the measured matrix is `A = A₀ + E`, then every singular value of `A` lies
within `‖E‖₂` of the matching singular value of the noise-free `A₀`. -/
theorem singular_value_moves_at_most_noise_norm {m n : ℕ} (A₀ E : Matrix (Fin m) (Fin n) ℝ)
    (i : ℕ) :
    |(toEuclideanLin (A₀ + E)).singularValues i - (toEuclideanLin A₀).singularValues i|
      ≤ ‖LinearMap.toContinuousLinearMap (toEuclideanLin E)‖ := by
  have h1 := svdAux_weyl (toEuclideanLin A₀) (toEuclideanLin E) i
  have h2 := svdAux_weyl (toEuclideanLin (A₀ + E)) (-toEuclideanLin E) i
  rw [map_add, add_neg_cancel_right, map_neg, norm_neg] at h2
  rw [map_add, abs_sub_le_iff]
  constructor <;> linarith

/-- The pseudoinverse. Exactly one matrix `X` satisfies Penrose's four conditions
`A X A = A`, `X A X = X`, `(A X)ᵀ = A X`, `(X A)ᵀ = X A`; this is `A⁺`. For every `y`,
`A⁺ y` is a least-squares solution (no `x` makes `‖A x - y‖²` smaller), and every other
least-squares solution is strictly longer: `A⁺ y` is the shortest one. -/
theorem pseudoinverse_gives_shortest_least_squares {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) :
    (∃! X : Matrix (Fin n) (Fin m) ℝ,
        A * X * A = A ∧ X * A * X = X ∧ (A * X)ᵀ = A * X ∧ (X * A)ᵀ = X * A) ∧
    ∀ X : Matrix (Fin n) (Fin m) ℝ,
      A * X * A = A → X * A * X = X → (A * X)ᵀ = A * X → (X * A)ᵀ = X * A →
      ∀ y : Fin m → ℝ,
        (∀ x : Fin n → ℝ, (A *ᵥ (X *ᵥ y) - y) ⬝ᵥ (A *ᵥ (X *ᵥ y) - y) ≤ (A *ᵥ x - y) ⬝ᵥ (A *ᵥ x - y)) ∧
        ∀ x : Fin n → ℝ,
          (A *ᵥ x - y) ⬝ᵥ (A *ᵥ x - y) ≤ (A *ᵥ (X *ᵥ y) - y) ⬝ᵥ (A *ᵥ (X *ᵥ y) - y) →
          x ≠ X *ᵥ y → (X *ᵥ y) ⬝ᵥ (X *ᵥ y) < x ⬝ᵥ x := by
  refine ⟨?_, fun X h1 h2 h3 h4 y => svdAux_least_squares A X h1 h2 h3 h4 y⟩
  obtain ⟨X, hX⟩ := svdAux_penrose_exists A
  exact ⟨X, hX, fun Y hY => svdAux_penrose_unique A Y X hY.1 hY.2.1 hY.2.2.1 hY.2.2.2
    hX.1 hX.2.1 hX.2.2.1 hX.2.2.2⟩

-- The card's whole-number worked examples.
-- Storage for the rank-3 fit of the 240 × 20 log: 3 × (240 + 20 + 1) = 783 numbers of 4,800.
example : 3 * (240 + 20 + 1) = 783 := by norm_num
example : 240 * 20 = 4800 := by norm_num
-- Householder QR of the same table: 2mn² − 2n³/3 = 186,667 flops (whole-number division).
example : 2 * 240 * 20 ^ 2 - 2 * 20 ^ 3 / 3 = 186667 := by decide

#print axioms best_rank_k_fit_keeps_top_k_layers
#print axioms singular_value_moves_at_most_noise_norm
#print axioms pseudoinverse_gives_shortest_least_squares
