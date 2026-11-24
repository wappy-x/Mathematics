-- Tensor products: a table is a single product v ⊗ w exactly when its rank is at most 1, every bilinear map is one linear map on V ⊗ W, and V ⊗ W has dimension mn.
import Mathlib.LinearAlgebra.TensorProduct.Basic
import Mathlib.LinearAlgebra.Dimension.Constructions
import Mathlib.LinearAlgebra.Matrix.Rank
import Mathlib.LinearAlgebra.Matrix.Kronecker

open Matrix TensorProduct

/-- The rank test: an m-by-n table T over a field is a single product v ⊗ w
(the table whose entry in row i, column j is v_i w_j) exactly when its rank is at most 1. -/
theorem exists_tensor_eq_iff_rank_le_one {K : Type*} [Field K] {m n : ℕ}
    (T : Matrix (Fin m) (Fin n) K) :
    (∃ (v : Fin m → K) (w : Fin n → K), T = vecMulVec v w) ↔ T.rank ≤ 1 := by
  constructor
  · rintro ⟨v, w, rfl⟩
    exact rank_vecMulVec_le v w
  · intro h
    rw [rank_eq_finrank_span_cols, Submodule.finrank_le_one_iff_isPrincipal] at h
    obtain ⟨v, hv⟩ := h.principal
    have hcol : ∀ j, ∃ c : K, c • v = T.col j := by
      intro j
      have hj : T.col j ∈ Submodule.span K (Set.range T.col) :=
        Submodule.subset_span ⟨j, rfl⟩
      rw [hv] at hj
      exact Submodule.mem_span_singleton.mp hj
    choose w hw using hcol
    refine ⟨v, w, ?_⟩
    ext i j
    have := congrFun (hw j) i
    simp only [Matrix.col_apply, Pi.smul_apply, smul_eq_mul] at this
    rw [vecMulVec_apply, ← this, mul_comm]

/-- The universal property: every rule β on pairs that is linear in each slot is a linear
rule L on V ⊗ W with L (v ⊗ w) = β(v, w), in exactly one way. -/
theorem bilinear_eq_linear_on_tensor_unique {K V W U : Type*} [Field K]
    [AddCommGroup V] [Module K V] [AddCommGroup W] [Module K W]
    [AddCommGroup U] [Module K U] (β : V →ₗ[K] W →ₗ[K] U) :
    ∃! L : V ⊗[K] W →ₗ[K] U, ∀ v w, L (v ⊗ₜ w) = β v w := by
  refine ⟨TensorProduct.lift β, fun v w => TensorProduct.lift.tmul v w, ?_⟩
  intro L hL
  exact TensorProduct.lift.unique hL

/-- The dimension count: if V has dimension m and W has dimension n,
then V ⊗ W has dimension mn. -/
theorem finrank_tensor_eq_mul {K V W : Type*} [Field K]
    [AddCommGroup V] [Module K V] [FiniteDimensional K V]
    [AddCommGroup W] [Module K W] [FiniteDimensional K W] :
    Module.finrank K (V ⊗[K] W) = Module.finrank K V * Module.finrank K W := by
  exact Module.finrank_tensorProduct

-- The repeated list: (1, 2) ⊗ (3, 0, 1) is the table [[3, 0, 1], [6, 0, 2]].
example : vecMulVec ![(1 : ℤ), 2] ![3, 0, 1] = !![3, 0, 1; 6, 0, 2] := by decide

-- All three cross-differences of that table are 0.
example : (fun T : Matrix (Fin 2) (Fin 3) ℤ =>
      ![T 0 0 * T 1 1 - T 0 1 * T 1 0, T 0 0 * T 1 2 - T 0 2 * T 1 0, T 0 1 * T 1 2 - T 0 2 * T 1 1])
    !![3, 0, 1; 6, 0, 2] = ![0, 0, 0] := by decide

-- S = e1 ⊗ f1 + e2 ⊗ f2 is [[1, 0, 0], [0, 1, 0]], and its first cross-difference is 1, not 0.
example : vecMulVec ![(1 : ℤ), 0] ![1, 0, 0] + vecMulVec ![0, 1] ![0, 1, 0]
    = !![1, 0, 0; 0, 1, 0] := by decide
example : (fun S : Matrix (Fin 2) (Fin 3) ℤ => S 0 0 * S 1 1 - S 0 1 * S 1 0)
    !![1, 0, 0; 0, 1, 0] = 1 := by decide

-- The bill: prices [[3, 2, 4], [3, 2, 5]] give $41 from the pair and $41 from the table.
example : ∑ i : Fin 2, ∑ j : Fin 3, !![(3 : ℤ), 2, 4; 3, 2, 5] i j * (![1, 2] i * ![3, 0, 1] j) = 41 := by decide
example : ∑ i : Fin 2, ∑ j : Fin 3, !![(3 : ℤ), 2, 4; 3, 2, 5] i j * !![3, 0, 1; 6, 0, 2] i j = 41 := by decide

-- The Kronecker product: Av = (1, 3), Bw = (3, 0, 12), and (A ⊗ B) times the flat table
-- (3, 0, 1, 6, 0, 2) is (3, 0, 12, 9, 0, 36), the flat (Av) ⊗ (Bw).
example : !![(1 : ℤ), 0; 1, 1] *ᵥ ![1, 2] = ![1, 3] ∧
    !![(1 : ℤ), 0, 0; 0, 1, 0; 0, 0, 12] *ᵥ ![3, 0, 1] = ![3, 0, 12] := by decide
example : (kroneckerMap (· * ·) !![(1 : ℤ), 0; 1, 1] !![1, 0, 0; 0, 1, 0; 0, 0, 12])
      *ᵥ (fun p : Fin 2 × Fin 3 => !![(3 : ℤ), 0, 1; 6, 0, 2] p.1 p.2)
    = fun p => vecMulVec ![(1 : ℤ), 3] ![3, 0, 12] p.1 p.2 := by decide
example : (fun p : Fin 2 × Fin 3 => vecMulVec ![(1 : ℤ), 3] ![3, 0, 12] p.1 p.2)
    = fun p => !![(3 : ℤ), 0, 12; 9, 0, 36] p.1 p.2 := by decide

-- Mistake 2: (e1 + e2) ⊗ (f1 + f2) is [[1, 1, 0], [1, 1, 0]], not S.
example : vecMulVec ![(1 : ℤ), 1] ![1, 1, 0] = !![1, 1, 0; 1, 1, 0] ∧
    vecMulVec ![(1 : ℤ), 1] ![1, 1, 0] ≠ !![1, 0, 0; 0, 1, 0] := by decide

#print axioms exists_tensor_eq_iff_rank_le_one
#print axioms bilinear_eq_linear_on_tensor_unique
#print axioms finrank_tensor_eq_mul
