-- Dual spaces: for a finite-dimensional space, each basis has exactly one dual basis and the dual space has the same dimension, the dual map's matrix is the transpose, and the annihilator count gives row rank equal to column rank.
import Mathlib.LinearAlgebra.Matrix.Rank
import Mathlib.Tactic.NormNum
import Mathlib.LinearAlgebra.Matrix.Dual
import Mathlib.LinearAlgebra.Dual.Lemmas
import Mathlib.Tactic.FinCases

open Module Matrix

/-- **A basis gives a dual basis, so the readings form a space of the same size.**
Let `V` be a space with a finite basis `b`. There is exactly one basis `f` of the
dual space `V*` (all linear readings of `V`) with `f i (b j) = 1` when `i = j` and
`0` otherwise: each dual reading scores 1 on its own basis vector and 0 on every
other one. And `dim V* = dim V`. -/
theorem dual_basis_exists_unique_and_dim_dual_eq_dim {K V ι : Type*} [Field K]
    [AddCommGroup V] [Module K V] [Fintype ι] [DecidableEq ι] (b : Basis ι K V) :
    (∃! f : Basis ι K (Module.Dual K V), ∀ i j, f i (b j) = if i = j then 1 else 0) ∧
      finrank K (Module.Dual K V) = finrank K V := by
  classical
  refine ⟨⟨b.dualBasis, fun i j => ?_, fun f hf => ?_⟩, ?_⟩
  · rw [Basis.dualBasis_apply_self]
    by_cases h : i = j
    · simp [h]
    · simp [h, Ne.symm h]
  · apply Basis.eq_of_apply_eq
    intro i
    apply b.ext
    intro j
    rw [hf, Basis.dualBasis_apply_self]
    by_cases h : i = j
    · simp [h]
    · simp [h, Ne.symm h]
  · exact b.toDualEquiv.finrank_eq.symm

/-- **The transpose is the dual map.** Let `T : V → W` be a linear map between spaces
with finite bases, and let `A` be its matrix in those bases. The dual map
`T* q = q ∘ T`, which pulls a reading of `W` back to a reading of `V`, has matrix
`Aᵀ` in the two dual bases. -/
theorem dual_map_matrix_eq_transpose {K V W ι κ : Type*} [Field K]
    [AddCommGroup V] [Module K V] [AddCommGroup W] [Module K W]
    [Fintype ι] [Fintype κ] [DecidableEq ι] [DecidableEq κ]
    (bV : Basis ι K V) (bW : Basis κ K W) (T : V →ₗ[K] W) :
    LinearMap.toMatrix bW.dualBasis bV.dualBasis T.dualMap = (LinearMap.toMatrix bV bW T)ᵀ := by
  exact LinearMap.toMatrix_transpose T

/-- **Annihilators, and row rank equals column rank.** In a finite-dimensional space
`V`, the readings that score 0 on all of a subspace `U` form a subspace of dimension
`dim V - dim U`. And for every matrix `A` with finitely many rows and columns, the
rows of `A` span a space of the same dimension as the columns of `A`. -/
theorem annihilator_dim_and_row_rank_eq_column_rank {K V m n : Type*} [Field K]
    [AddCommGroup V] [Module K V] [FiniteDimensional K V] [Fintype m] [Fintype n]
    (U : Submodule K V) (A : Matrix m n K) :
    finrank K U.dualAnnihilator = finrank K V - finrank K U ∧
      finrank K (Submodule.span K (Set.range A.row)) =
        finrank K (Submodule.span K (Set.range A.col)) := by
  refine ⟨?_, ?_⟩
  · have h := Subspace.finrank_add_finrank_dualAnnihilator_eq U
    omega
  · rw [← Matrix.rank_eq_finrank_span_row, ← Matrix.rank_eq_finrank_span_cols]

-- The house bill: the price list (3, 2, 4) reads the basket (2, 3, 1) as $16.
example : (![3, 2, 4] : Fin 3 → ℤ) ⬝ᵥ ![2, 3, 1] = 16 := by simp [dotProduct, Fin.sum_univ_succ]
-- Dual basis of the bundles (2, 1) and (1, 1): (1, -1) and (-1, 2) read 1, 0, 0, 1.
example : (![1, -1] : Fin 2 → ℤ) ⬝ᵥ ![2, 1] = 1 ∧ (![1, -1] : Fin 2 → ℤ) ⬝ᵥ ![1, 1] = 0 ∧
    (![-1, 2] : Fin 2 → ℤ) ⬝ᵥ ![2, 1] = 0 ∧ (![-1, 2] : Fin 2 → ℤ) ⬝ᵥ ![1, 1] = 1 := by simp [dotProduct, Fin.sum_univ_succ]
-- The counters rebuild the price list (3, 2): 8(1, -1) + 5(-1, 2) = (3, 2).
example : (8 : ℤ) • (![1, -1] : Fin 2 → ℤ) + (5 : ℤ) • ![-1, 2] = ![3, 2] := by ext i; fin_cases i <;> simp
-- Counters as coordinates: (2, 3) reads -1 and 4, and -1(2, 1) + 4(1, 1) = (2, 3).
example : (![1, -1] : Fin 2 → ℤ) ⬝ᵥ ![2, 3] = -1 ∧ (![-1, 2] : Fin 2 → ℤ) ⬝ᵥ ![2, 3] = 4 ∧
    (-1 : ℤ) • (![2, 1] : Fin 2 → ℤ) + (4 : ℤ) • ![1, 1] = ![2, 3] := by refine ⟨?_, ?_, ?_⟩ <;> [simp [dotProduct, Fin.sum_univ_succ]; simp [dotProduct, Fin.sum_univ_succ]; (ext i; fin_cases i <;> simp)]
-- Hamper prices: the transpose pulls (3, 2, 4) back to (16, 11).
example : (!![2, 1; 3, 0; 1, 2] : Matrix (Fin 3) (Fin 2) ℤ)ᵀ *ᵥ ![3, 2, 4] = ![16, 11] := by
  ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_succ]
-- The order (1, 2) unpacks to (4, 3, 5) items.
example : (!![2, 1; 3, 0; 1, 2] : Matrix (Fin 3) (Fin 2) ℤ) *ᵥ ![1, 2] = ![4, 3, 5] := by ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_succ]
-- Both roads give one bill: $38 by items and $38 by hamper prices.
example : (![3, 2, 4] : Fin 3 → ℤ) ⬝ᵥ ![4, 3, 5] = 38 ∧
    (![16, 11] : Fin 2 → ℤ) ⬝ᵥ ![1, 2] = 38 := by simp [dotProduct, Fin.sum_univ_succ]
-- The hidden price change (-2, 1, 1) scores 0 on both hampers.
example : (!![2, 1; 3, 0; 1, 2] : Matrix (Fin 3) (Fin 2) ℤ)ᵀ *ᵥ ![-2, 1, 1] = 0 := by ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_succ]
-- Try changing: prices (1, 3, 5) still give hamper prices (16, 11).
example : (!![2, 1; 3, 0; 1, 2] : Matrix (Fin 3) (Fin 2) ℤ)ᵀ *ᵥ ![1, 3, 5] = ![16, 11] := by
  ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_succ]
-- Mistake 1: the bundle (2, 1) used as a price list reads the bundles as 5 and 3.
example : (![2, 1] : Fin 2 → ℤ) ⬝ᵥ ![2, 1] = 5 ∧ (![2, 1] : Fin 2 → ℤ) ⬝ᵥ ![1, 1] = 3 := by
  simp [dotProduct, Fin.sum_univ_succ]
-- Mistake 2: hamper prices pushed forward by A give (43, 48, 38).
example : (!![2, 1; 3, 0; 1, 2] : Matrix (Fin 3) (Fin 2) ℤ) *ᵥ ![16, 11] = ![43, 48, 38] := by
  ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_succ]
-- Mistake 3: with b2 = (1, 0), the dual basis is (0, 1) and (1, -2).
example : (![0, 1] : Fin 2 → ℤ) ⬝ᵥ ![2, 1] = 1 ∧ (![0, 1] : Fin 2 → ℤ) ⬝ᵥ ![1, 0] = 0 ∧
    (![1, -2] : Fin 2 → ℤ) ⬝ᵥ ![2, 1] = 0 ∧ (![1, -2] : Fin 2 → ℤ) ⬝ᵥ ![1, 0] = 1 := by simp [dotProduct, Fin.sum_univ_succ]
-- No basis: no reading is worth 1 on (2, 1) and 0 on (4, 2).
example : ¬ ∃ f : Fin 2 → ℚ, f ⬝ᵥ ![2, 1] = 1 ∧ f ⬝ᵥ ![4, 2] = 0 := by
  rintro ⟨f, h1, h2⟩
  have : f ⬝ᵥ ![4, 2] = 2 * (f ⬝ᵥ ![2, 1]) := by
    simp [dotProduct, Fin.sum_univ_succ]; ring
  rw [h1, h2] at this
  norm_num at this

#print axioms dual_basis_exists_unique_and_dim_dual_eq_dim
#print axioms dual_map_matrix_eq_transpose
#print axioms annihilator_dim_and_row_rank_eq_column_rank
