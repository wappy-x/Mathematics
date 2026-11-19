-- Lie group: the turns of n-dimensional space form a group, and at every turn the n(n+1)/2 equations of RᵀR = I are independent and leave n(n-1)/2 free directions, which is 3 for the drone.
import Mathlib.LinearAlgebra.Matrix.Symmetric
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Dimension.Finrank
import Mathlib.LinearAlgebra.FiniteDimensional.Defs
import Mathlib.Data.Real.Basic
import Mathlib.Data.Sym.Card
import Mathlib.LinearAlgebra.FiniteDimensional.Lemmas
import Mathlib.LinearAlgebra.Matrix.ToLin

open Matrix

/-- The derivative of the constraint `RᵀR = I` at `R`: a small change `H` to `R`
changes `RᵀR` by `Hᵀ R + Rᵀ H`, to first order. -/
noncomputable def constraintDerivative (n : ℕ) (R : Matrix (Fin n) (Fin n) ℝ) :
    Matrix (Fin n) (Fin n) ℝ →ₗ[ℝ] Matrix (Fin n) (Fin n) ℝ :=
  LinearMap.mulRight ℝ R ∘ₗ (transposeLinearEquiv (Fin n) (Fin n) ℝ ℝ).toLinearMap
    + LinearMap.mulLeft ℝ Rᵀ

-- The map above is exactly H ↦ Hᵀ R + Rᵀ H.
example (n : ℕ) (R H : Matrix (Fin n) (Fin n) ℝ) :
    constraintDerivative n R H = Hᵀ * R + Rᵀ * H := rfl

/-- The map sending a function on unordered pairs to the symmetric matrix it fills in. -/
noncomputable def symFill (n : ℕ) : (Sym2 (Fin n) → ℝ) →ₗ[ℝ] Matrix (Fin n) (Fin n) ℝ where
  toFun f := Matrix.of fun i j => f s(i, j)
  map_add' f g := by ext i j; simp
  map_smul' c f := by ext i j; simp

theorem symFill_injective (n : ℕ) : Function.Injective (symFill n) := by
  intro f g h
  funext z
  induction z using Sym2.ind with
  | h i j => exact congrFun (congrFun h i) j

theorem range_symFill (n : ℕ) (S : Matrix (Fin n) (Fin n) ℝ) :
    S ∈ LinearMap.range (symFill n) ↔ S.IsSymm := by
  constructor
  · rintro ⟨f, rfl⟩
    ext i j
    simp [symFill, Sym2.eq_swap]
  · intro hS
    refine ⟨Sym2.lift ⟨fun i j => S i j, fun i j => (hS.apply i j).symm⟩, ?_⟩
    ext i j
    simp [symFill, Sym2.lift_mk]

theorem finrank_range_symFill (n : ℕ) :
    Module.finrank ℝ (LinearMap.range (symFill n)) = n * (n + 1) / 2 := by
  rw [LinearMap.finrank_range_of_inj (symFill_injective n), Module.finrank_fintype_fun_eq_card,
    Sym2.card, Fintype.card_fin, Nat.choose_two_right, Nat.add_sub_cancel, Nat.mul_comm]

theorem range_constraintDerivative (n : ℕ) (R : Matrix (Fin n) (Fin n) ℝ)
    (hR : Rᵀ * R = 1) (S : Matrix (Fin n) (Fin n) ℝ) :
    S ∈ LinearMap.range (constraintDerivative n R) ↔ S.IsSymm := by
  constructor
  · rintro ⟨H, rfl⟩
    change (Hᵀ * R + Rᵀ * H)ᵀ = Hᵀ * R + Rᵀ * H
    rw [transpose_add, transpose_mul, transpose_mul, transpose_transpose, transpose_transpose,
      add_comm]
  · intro hS
    refine ⟨R * ((1 / 2 : ℝ) • S), ?_⟩
    change (R * ((1 / 2 : ℝ) • S))ᵀ * R + Rᵀ * (R * ((1 / 2 : ℝ) • S)) = S
    have hS' : Sᵀ = S := hS
    rw [transpose_mul, transpose_smul, hS', Matrix.mul_assoc, ← Matrix.mul_assoc Rᵀ R, hR,
      Matrix.one_mul, Matrix.mul_one, ← add_smul]
    norm_num

theorem range_constraintDerivative_eq (n : ℕ) (R : Matrix (Fin n) (Fin n) ℝ)
    (hR : Rᵀ * R = 1) :
    LinearMap.range (constraintDerivative n R) = LinearMap.range (symFill n) := by
  ext S
  rw [range_constraintDerivative n R hR, range_symFill]

#print axioms symFill_injective
#print axioms range_symFill
#print axioms finrank_range_symFill
#print axioms range_constraintDerivative
#print axioms range_constraintDerivative_eq

/-- The dimension count: at every matrix `R` with `RᵀR = I`, the directions `H` that keep
`RᵀR = I` to first order (those with `Hᵀ R + Rᵀ H = 0`) form a space of dimension
`n(n-1)/2`. For the drone's turns, `n = 3`, this is `9 - 6 = 3`. -/
theorem rotation_group_dimension (n : ℕ) (R : Matrix (Fin n) (Fin n) ℝ)
    (hR : Rᵀ * R = 1) :
    Module.finrank ℝ (LinearMap.ker (constraintDerivative n R)) = n * (n - 1) / 2 := by
  have h := LinearMap.finrank_range_add_finrank_ker (constraintDerivative n R)
  rw [range_constraintDerivative_eq n R hR, finrank_range_symFill, Module.finrank_matrix,
    Fintype.card_fin, Module.finrank_self, mul_one] at h
  have h2 : n * (n + 1) / 2 = n * (n - 1) / 2 + n := by
    rcases n with _ | m
    · rfl
    · rw [Nat.add_sub_cancel, show (m + 1) * (m + 1 + 1) = (m + 1) * m + (m + 1) * 2 by ring,
        Nat.add_mul_div_right _ _ Nat.two_pos]
  have h3 : n * (n - 1) / 2 * 2 = n * (n - 1) :=
    Nat.div_mul_cancel (Nat.even_mul_pred_self n).two_dvd
  have h4 : n * n = n * (n - 1) + n := by
    rcases n with _ | m
    · rfl
    · rw [Nat.add_sub_cancel]; ring
  omega

/-- The equations are independent at every point: at every `R` with `RᵀR = I`, the
derivative `H ↦ Hᵀ R + Rᵀ H` reaches exactly the symmetric matrices, so its rank is the
number of different equations in `RᵀR = I`, which is `n(n+1)/2` (6 when `n = 3`). -/
theorem constraint_derivative_onto_symmetric (n : ℕ) (R : Matrix (Fin n) (Fin n) ℝ)
    (hR : Rᵀ * R = 1) :
    (∀ S : Matrix (Fin n) (Fin n) ℝ,
        S ∈ LinearMap.range (constraintDerivative n R) ↔ S.IsSymm) ∧
      Module.finrank ℝ (LinearMap.range (constraintDerivative n R)) = n * (n + 1) / 2 := by
  exact ⟨range_constraintDerivative n R hR, by
    rw [range_constraintDerivative_eq n R hR, finrank_range_symFill]⟩

/-- The turns form a group: if `A` and `B` are turns (`AᵀA = I`, `det = 1`), then so is
the combined turn `A B`, and the transpose `Aᵀ` is a turn that undoes `A`. -/
theorem rotations_form_group (n : ℕ) (A B : Matrix (Fin n) (Fin n) ℝ)
    (hA : Aᵀ * A = 1 ∧ A.det = 1) (hB : Bᵀ * B = 1 ∧ B.det = 1) :
    ((A * B)ᵀ * (A * B) = 1 ∧ (A * B).det = 1) ∧
      ((Aᵀ)ᵀ * Aᵀ = 1 ∧ Aᵀ.det = 1) ∧ Aᵀ * A = 1 ∧ A * Aᵀ = 1 := by
  obtain ⟨hA1, hA2⟩ := hA
  obtain ⟨hB1, hB2⟩ := hB
  have hA3 : A * Aᵀ = 1 := mul_eq_one_comm.mp hA1
  refine ⟨⟨?_, ?_⟩, ⟨?_, ?_⟩, hA1, hA3⟩
  · rw [transpose_mul, Matrix.mul_assoc, ← Matrix.mul_assoc Aᵀ, hA1, Matrix.one_mul, hB1]
  · rw [det_mul, hA2, hB2, one_mul]
  · rw [transpose_transpose, hA3]
  · rw [det_transpose, hA2]

-- The card's whole-number counts.
-- 9 entries, 6 different equations, 3 free directions.
example : 3 * 3 - 3 * (3 + 1) / 2 = 3 := by norm_num
-- Counting all 9 written equations gives 0, the false answer.
example : 3 * 3 - 9 = 0 := by norm_num
-- dim SO(n) for n = 2, 3, 4, 5: n² - n(n+1)/2 = n(n-1)/2 = 1, 3, 6, 10.
example : [2, 3, 4, 5].map (fun n => n * n - n * (n + 1) / 2) = [1, 3, 6, 10] := by decide
example : [2, 3, 4, 5].map (fun n => n * (n - 1) / 2) = [1, 3, 6, 10] := by decide
-- The matrix groups at n = 3: GL 9, O 3, SO 3, U 9, SU 8.
example : 3 ^ 2 = 9 ∧ 3 * (3 - 1) / 2 = 3 ∧ 3 ^ 2 - 1 = 8 := by norm_num

#print axioms rotation_group_dimension
#print axioms constraint_derivative_onto_symmetric
#print axioms rotations_form_group
