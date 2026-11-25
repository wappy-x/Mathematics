-- The Killing form and roots: over a field of characteristic zero a finite-dimensional Lie algebra has no nonzero solvable ideal exactly when its Killing form is nondegenerate, and then a split Cartan subalgebra cuts the algebra into its own directions plus one line per root, with B = 6 tr(XY) on sl(3).
import Mathlib.Algebra.Lie.CartanCriterion
import Mathlib.Algebra.Lie.Weights.Killing
import Mathlib.Algebra.Lie.Classical
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Tactic

open LieAlgebra LieModule Module

namespace KillingFormRoots

theorem stdBasis_repr_apply' {K : Type*} [Field K] (A : Matrix (Fin 3) (Fin 3) K) (i j : Fin 3) :
    (Matrix.stdBasis K (Fin 3) (Fin 3)).repr A (i, j) = A i j := by
  simp [Matrix.stdBasis]

/-- Commutator map `A ↦ Z A - A Z` on 3 by 3 matrices. -/
noncomputable def commMap {K : Type*} [Field K] (Z : Matrix (Fin 3) (Fin 3) K) :
    Matrix (Fin 3) (Fin 3) K →ₗ[K] Matrix (Fin 3) (Fin 3) K :=
  LinearMap.mulLeft K Z - LinearMap.mulRight K Z

/-- Trace of `A ↦ [X, [Y, A]]` on all 3 by 3 matrices, for traceless `X`. -/
theorem trace_commMap_comp {K : Type*} [Field K] (X Y : Matrix (Fin 3) (Fin 3) K)
    (hX : Matrix.trace X = 0) :
    LinearMap.trace K (Matrix (Fin 3) (Fin 3) K) (commMap X ∘ₗ commMap Y) =
      6 * Matrix.trace (X * Y) := by
  rw [LinearMap.trace_eq_matrix_trace K (Matrix.stdBasis K (Fin 3) (Fin 3))]
  simp only [Matrix.trace, Matrix.diag, LinearMap.toMatrix_apply, Fintype.sum_prod_type,
    Matrix.stdBasis_eq_single, stdBasis_repr_apply', LinearMap.comp_apply, commMap,
    LinearMap.sub_apply, LinearMap.mulLeft_apply, LinearMap.mulRight_apply,
    Fin.sum_univ_three, Matrix.mul_apply, Matrix.sub_apply, Matrix.single_apply] at *
  simp
  linear_combination (-2 * (Y 0 0 + Y 1 1 + Y 2 2)) * hX

#print axioms stdBasis_repr_apply'
#print axioms trace_commMap_comp

/-- **Cartan's criterion.** Over a field of characteristic zero (the complex or real numbers), a
finite-dimensional Lie algebra is semisimple, meaning it has no nonzero solvable ideal (its solvable
radical is zero), exactly when its Killing form `B(X, Y) = tr(ad X ad Y)` is nondegenerate: no
nonzero `X` pairs to zero with every `Y`. -/
theorem semisimple_iff_killingForm_nondegenerate
    {K L : Type*} [Field K] [CharZero K] [LieRing L] [LieAlgebra K L] [FiniteDimensional K L] :
    HasTrivialRadical K L ↔ (killingForm K L).Nondegenerate := by
  constructor
  · intro _
    exact IsKilling.killingForm_nondegenerate K L
  · intro h
    have : IsKilling K L := ⟨by
      ext x
      simp only [LieIdeal.mem_killingCompl, LieSubmodule.mem_top, true_implies,
        LieSubmodule.mem_bot]
      exact ⟨fun hx => h.2 x hx, by rintro rfl; simp⟩⟩
    infer_instance

/-- **Root space decomposition.** Let `L` be a finite-dimensional semisimple Lie algebra over a field
of characteristic zero, and `H` a Cartan subalgebra whose maps `ad h` have all their eigenvalues in
the field (as over the complex numbers). Then `H` is exactly the part every `ad h` kills; each root
space `𝔤_α` is scaled by every `h` in `H` by the number `α(h)`; the root spaces are independent and
together fill `L`, so `L = 𝔥 ⊕ ⨁_{α ∈ Φ} 𝔤_α`; and each root space of a nonzero root is a single
line. -/
theorem root_space_decomposition
    {K L : Type*} [Field K] [CharZero K] [LieRing L] [LieAlgebra K L] [FiniteDimensional K L]
    [HasTrivialRadical K L]
    (H : LieSubalgebra K L) [H.IsCartanSubalgebra] [IsTriangularizable K H L] :
    rootSpace H 0 = H.toLieSubmodule ∧
    (∀ (α : Weight K H L) (h : H) (x : L), x ∈ rootSpace H α → ⁅(h : L), x⁆ = α h • x) ∧
    iSupIndep (fun α : Weight K H L => rootSpace H α) ∧
    (⨆ α : Weight K H L, rootSpace H α) = ⊤ ∧
    (∀ α : Weight K H L, α.IsNonZero → finrank K (rootSpace H α) = 1) := by
  refine ⟨rootSpace_zero_eq K L H, fun α h x hx => ?_, iSupIndep_genWeightSpace' K H L,
    iSup_genWeightSpace_eq_top' K H L, fun α hα => IsKilling.finrank_rootSpace_eq_one α hα⟩
  exact IsKilling.lie_eq_smul_of_mem_rootSpace hx h

/-- **The Killing form of sl(3) is six times the trace form.** On the traceless 3 by 3 matrices,
`B(X, Y) = tr(ad X ad Y) = 6 tr(XY)`. -/
theorem killingForm_sl3_eq_six_mul_trace {K : Type*} [Field K] [CharZero K]
    (X Y : SpecialLinear.sl (Fin 3) K) :
    killingForm K (SpecialLinear.sl (Fin 3) K) X Y = 6 * Matrix.trace (X.val * Y.val) := by
  let _ : LieRing (Matrix (Fin 3) (Fin 3) K) := LieRing.ofAssociativeRing
  have hmem : ∀ A, (commMap X.val ∘ₗ commMap Y.val) A ∈
      (SpecialLinear.sl (Fin 3) K).toSubmodule := by
    intro A
    change (commMap X.val ∘ₗ commMap Y.val) A ∈ LinearMap.ker (Matrix.traceLinearMap (Fin 3) K K)
    rw [LinearMap.mem_ker, Matrix.traceLinearMap_apply]
    have := matrix_trace_commutator_zero (Fin 3) K X.val (Y.val * A - A * Y.val)
    simpa [commMap, Ring.lie_def] using this
  have hres : ad K (SpecialLinear.sl (Fin 3) K) X ∘ₗ ad K (SpecialLinear.sl (Fin 3) K) Y =
      (commMap X.val ∘ₗ commMap Y.val).restrict (fun A _ => hmem A) := by
    ext A : 1
    apply Subtype.ext
    rw [LinearMap.coe_restrict_apply]
    simp [commMap, Ring.lie_def]
  rw [killingForm_apply_apply, hres]
  exact (LinearMap.trace_restrict_eq_of_forall_mem _ _ hmem).trans
    (trace_commMap_comp X.val Y.val X.2)

/-! The card's whole-number worked examples, on integer matrices. -/

/-- The test element `H = diag(1, -1, 0)`. -/
def Hd : Matrix (Fin 3) (Fin 3) ℤ := !![1, 0, 0; 0, -1, 0; 0, 0, 0]
/-- The second basis element `H₂ = diag(0, 1, -1)` of the Cartan subalgebra. -/
def H2 : Matrix (Fin 3) (Fin 3) ℤ := !![0, 0, 0; 0, 1, 0; 0, 0, -1]
/-- Matrix units `E₁₂`, `E₂₁`, `E₁₃`, `E₂₃`. -/
def E12 : Matrix (Fin 3) (Fin 3) ℤ := !![0, 1, 0; 0, 0, 0; 0, 0, 0]
def E21 : Matrix (Fin 3) (Fin 3) ℤ := !![0, 0, 0; 1, 0, 0; 0, 0, 0]
def E13 : Matrix (Fin 3) (Fin 3) ℤ := !![0, 0, 1; 0, 0, 0; 0, 0, 0]
def E23 : Matrix (Fin 3) (Fin 3) ℤ := !![0, 0, 0; 0, 0, 1; 0, 0, 0]

-- sl(3) has dimension 9 - 1 = 8 = 2 + 6.
example : 3 * 3 - 1 = 2 + 6 := by decide
-- The roots of E₁₂, E₁₃, E₂₃ at H = diag(1, -1, 0): 2, 1, -1.
example : Hd * E12 - E12 * Hd = 2 • E12 := by decide
example : Hd * E13 - E13 * Hd = 1 • E13 := by decide
example : Hd * E23 - E23 * Hd = (-1 : ℤ) • E23 := by decide
-- B(H, H) = 6 tr(H²) = 6 × 2 = 12, and by root squares 4 + 4 + 1 + 1 + 1 + 1 = 12.
example : 6 * Matrix.trace (Hd * Hd) = 12 := by decide
example : (2 : ℤ) ^ 2 + (-2) ^ 2 + 1 ^ 2 + (-1) ^ 2 + (-1) ^ 2 + 1 ^ 2 = 12 := by decide
-- B(H₁, H₂) = 6 tr(diag(0, -1, 0)) = -6; B(E₁₂, E₂₁) = 6; B(E₁₂, E₁₂) = 0.
example : 6 * Matrix.trace (Hd * H2) = -6 := by decide
example : 6 * Matrix.trace (E12 * E21) = 6 := by decide
example : 6 * Matrix.trace (E12 * E12) = 0 := by decide
-- [E₁₂, E₂₁] = diag(1, -1, 0).
example : E12 * E21 - E21 * E12 = Hd := by decide
-- Each E_ij, E_ji block has determinant -36; the 𝔥 block 12 × 12 - (-6)² = 108.
example : Matrix.det !![(0 : ℤ), 6; 6, 0] = -36 := by norm_num [Matrix.det_fin_two]
example : Matrix.det !![(12 : ℤ), -6; -6, 12] = 108 := by norm_num [Matrix.det_fin_two]
-- Cartan's test in the basis E_ij, H₁, H₂: (-36)³ × 108 = -46656 × 108 = -5038848, not 0.
example : (-36 : ℤ) ^ 3 * 108 = -5038848 := by norm_num
example : (-36 : ℤ) ^ 3 = -46656 := by norm_num
-- The torus 2^H = diag(2, 1/2, 1) scales E₁₂ by 2 ÷ (1/2) = 4 = 2².
example : (2 : ℚ) / (1 / 2) = 2 ^ 2 := by norm_num
-- Centralizer of H: 8 - 6 nonzero root values = 2.
example : 8 - 6 = 2 := by decide
-- Root lengths: (α, α) = 4/12 = 1/3, (α, β) = 4 × (-6)/(12 × 12) = -1/6, cos = -1/2.
example : (4 : ℚ) / 12 = 1 / 3 := by norm_num
example : (4 : ℚ) * (-6) / (12 * 12) = -1 / 6 := by norm_num
example : ((-1 : ℚ) / 6) / (1 / 3) = -1 / 2 := by norm_num
-- Asymptotic freedom: 11 C_A/3 - 2 n_f/3 with C_A = 3 and n_f = 6 is 7.
example : (11 : ℚ) * 3 / 3 - 2 * 6 / 3 = 7 := by norm_num

#print axioms semisimple_iff_killingForm_nondegenerate
#print axioms root_space_decomposition
#print axioms killingForm_sl3_eq_six_mul_trace

end KillingFormRoots
