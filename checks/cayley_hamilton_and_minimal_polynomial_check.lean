-- Cayley-Hamilton and the minimal polynomial: every square matrix over a field is a root of its own characteristic polynomial, its minimal polynomial divides every polynomial that kills it, and a complex square matrix is diagonalisable exactly when its minimal polynomial has no repeated root.
import Mathlib.LinearAlgebra.Matrix.Charpoly.Basic
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.FieldTheory.Minpoly.Field
import Mathlib.Basic.Complex.Basic
import Mathlib.LinearAlgebra.Eigenspace.Semisimple
import Mathlib.Analysis.Complex.Polynomial.Basic
import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.FieldTheory.Separable

open Polynomial Matrix

theorem aeval_conj_matrix {n : ℕ} (P D Q : Matrix (Fin n) (Fin n) ℂ) (h : Q * P = 1)
    (q : ℂ[X]) : aeval (P * D * Q) q = P * aeval D q * Q := by
  have hpow : ∀ k : ℕ, (P * D * Q) ^ k = P * D ^ k * Q := by
    intro k
    induction k with
    | zero => simpa using (mul_eq_one_comm.mp h).symm
    | succ k ih => rw [pow_succ, ih, pow_succ]; simp only [Matrix.mul_assoc]; rw [← Matrix.mul_assoc Q P, h, Matrix.one_mul]
  induction q using Polynomial.induction_on' with
  | add p q hp hq => simp [hp, hq, Matrix.mul_add, Matrix.add_mul]
  | monomial k c => simp [aeval_monomial, hpow, Algebra.algebraMap_eq_smul_one]

theorem aeval_diagonal_matrix {n : ℕ} (d : Fin n → ℂ) (q : ℂ[X]) :
    aeval (diagonal d) q = diagonal (fun i => eval (d i) q) := by
  induction q using Polynomial.induction_on' with
  | add p q hp hq => simp [hp, hq, diagonal_add]
  | monomial k c =>
    ext i j
    simp [aeval_monomial, diagonal_pow, Algebra.algebraMap_eq_smul_one, diagonal_apply]
    rcases eq_or_ne i j with rfl | hij
    · simp
    · simp [one_apply_ne hij, hij]

theorem minpoly_roots_nodup_of_diagonalisable {n : ℕ}
    (A : Matrix (Fin n) (Fin n) ℂ) :
    (∃ (P : Matrix (Fin n) (Fin n) ℂ) (d : Fin n → ℂ), IsUnit P.det ∧ A = P * diagonal d * P⁻¹)
      → (minpoly ℂ A).roots.Nodup := by
  classical
  rintro ⟨P, d, hP, rfl⟩
  set q : ℂ[X] := ∏ c ∈ Finset.univ.image d, (X - C c) with hq
  have hq0 : q ≠ 0 := (monic_prod_of_monic _ _ fun c _ => monic_X_sub_C c).ne_zero
  have hkill : aeval (P * diagonal d * P⁻¹) q = 0 := by
    rw [aeval_conj_matrix P _ _ (nonsing_inv_mul P hP), aeval_diagonal_matrix]
    have : (fun i => eval (d i) q) = 0 := by
      funext i
      simp only [hq, eval_prod, eval_sub, eval_X, eval_C, Pi.zero_apply]
      exact Finset.prod_eq_zero (Finset.mem_image_of_mem d (Finset.mem_univ i)) (sub_self _)
    simp [this]
  have hdvd := minpoly.dvd ℂ _ hkill
  have hle := Polynomial.roots.le_of_dvd hq0 hdvd
  refine Multiset.nodup_of_le hle ?_
  rw [hq, roots_prod_X_sub_C]
  exact (Finset.univ.image d).nodup

theorem diagonalisable_of_minpoly_roots_nodup {n : ℕ}
    (A : Matrix (Fin n) (Fin n) ℂ) :
    (minpoly ℂ A).roots.Nodup →
    (∃ (P : Matrix (Fin n) (Fin n) ℂ) (d : Fin n → ℂ), IsUnit P.det ∧ A = P * diagonal d * P⁻¹) := by
  classical
  intro hnd
  have hint : IsIntegral ℂ A := Algebra.IsIntegral.isIntegral A
  have hm0 : minpoly ℂ A ≠ 0 := minpoly.ne_zero hint
  have hsep : (minpoly ℂ A).Separable :=
    (nodup_roots_iff_of_splits hm0 (IsAlgClosed.splits _)).mp hnd
  set f : Module.End ℂ (Fin n → ℂ) := toLin' A with hf
  have hfm : aeval f (minpoly ℂ A) = 0 := by
    show aeval (Matrix.toLinAlgEquiv' A) _ = 0
    rw [aeval_algEquiv, AlgHom.comp_apply, minpoly.aeval, map_zero]
  have hss : f.IsSemisimple := Module.End.isSemisimple_of_squarefree_aeval_eq_zero hsep.squarefree hfm
  have htop := hss.iSup_eigenspace_eq_top
  have hI : DirectSum.IsInternal (fun μ : ℂ => f.eigenspace μ) :=
    DirectSum.isInternal_submodule_of_iSupIndep_of_iSup_eq_top (Module.End.eigenspaces_iSupIndep f) htop
  let I := (ν : ℂ) × Fin (Module.finrank ℂ (f.eigenspace ν))
  let v : Module.Basis I ℂ (Fin n → ℂ) := hI.collectedBasis fun μ ↦ Module.finBasis ℂ (f.eigenspace μ)
  have : Fintype I := FiniteDimensional.fintypeBasisIndex v
  have hsv (i : I) : f (v i) = i.1 • v i :=
    Module.End.mem_eigenspace_iff.mp (hI.collectedBasis_mem _ i)
  have hcard : Fintype.card I = n := by
    rw [← Module.finrank_eq_card_basis v, Module.finrank_fin_fun]
  let e : I ≃ Fin n := Fintype.equivFinOfCardEq hcard
  let w := v.reindex e
  let d : Fin n → ℂ := fun j => (e.symm j).1
  have hw (j : Fin n) : A *ᵥ w j = d j • w j := by
    have := hsv (e.symm j)
    simpa [w, d, hf] using this
  let P := (Pi.basisFun ℂ (Fin n)).toMatrix w
  have hPinv : Invertible P := Module.Basis.invertibleToMatrix _ _
  have hPdet : IsUnit P.det := isUnit_det_of_invertible P
  refine ⟨P, d, hPdet, ?_⟩
  have hAP : A * P = P * diagonal d := by
    ext k j
    rw [mul_diagonal]
    have := congrFun (hw j) k
    simp only [mulVec, dotProduct, Pi.smul_apply, smul_eq_mul] at this
    simp only [P, Matrix.mul_apply, Module.Basis.toMatrix_apply, Pi.basisFun_repr]
    rw [this, mul_comm]
  calc A = A * P * P⁻¹ := by rw [Matrix.mul_assoc, mul_nonsing_inv P hPdet, Matrix.mul_one]
    _ = P * diagonal d * P⁻¹ := by rw [hAP]

#print axioms aeval_conj_matrix
#print axioms aeval_diagonal_matrix
#print axioms minpoly_roots_nodup_of_diagonalisable
#print axioms diagonalisable_of_minpoly_roots_nodup


/-- **Cayley-Hamilton, the card's main claim.** Put any n by n matrix A with entries from a
field into its own characteristic polynomial p_A(x) = det(xI - A) (Mathlib's `A.charpoly`):
x^k becomes A^k and a constant c becomes c times I. Every entry comes out zero. -/
theorem matrix_is_root_of_its_characteristic_polynomial {K : Type*} [Field K] {n : ℕ}
    (A : Matrix (Fin n) (Fin n) K) :
    aeval A A.charpoly = 0 := by
  exact Matrix.aeval_self_charpoly A

/-- **The minimal polynomial divides everything that kills A.** For an n by n matrix A over a
field, the minimal polynomial m_A (the monic polynomial of lowest degree with m_A(A) = 0,
Mathlib's `minpoly K A`) divides every polynomial f with f(A) = 0. -/
theorem minimal_polynomial_divides_every_killing_polynomial {K : Type*} [Field K] {n : ℕ}
    (A : Matrix (Fin n) (Fin n) K) (f : K[X]) (hf : aeval A f = 0) :
    minpoly K A ∣ f := by
  exact minpoly.dvd K A hf

/-- **The diagonalisability test.** With roots counted in the complex numbers, an n by n
matrix A can be diagonalised (a basis of eigenvectors, the columns of an invertible P, turns it
into a diagonal matrix: A = P diag(d) P⁻¹) exactly when its minimal polynomial has no
repeated root. -/
theorem diagonalisable_iff_minimal_polynomial_has_no_repeated_root {n : ℕ}
    (A : Matrix (Fin n) (Fin n) ℂ) :
    (∃ (P : Matrix (Fin n) (Fin n) ℂ) (d : Fin n → ℂ), IsUnit P.det ∧ A = P * diagonal d * P⁻¹)
      ↔ (minpoly ℂ A).roots.Nodup := by
  exact ⟨minpoly_roots_nodup_of_diagonalisable A, diagonalisable_of_minpoly_roots_nodup A⟩

-- The shops' week A = [[2, 1, 0], [0, 2, 0], [0, 0, 3]] has characteristic polynomial x^3 - 7x^2 + 16x - 12.
example : (!![2, 1, 0; 0, 2, 0; 0, 0, 3] : Matrix (Fin 3) (Fin 3) ℚ).charpoly
    = X ^ 3 - 7 * X ^ 2 + 16 * X - 12 := by
  rw [Matrix.charpoly, Matrix.det_fin_three]
  simp [C_ofNat]
  ring
-- So does D = diag(2, 2, 3).
example : (!![2, 0, 0; 0, 2, 0; 0, 0, 3] : Matrix (Fin 3) (Fin 3) ℚ).charpoly
    = X ^ 3 - 7 * X ^ 2 + 16 * X - 12 := by
  rw [Matrix.charpoly, Matrix.det_fin_three]
  simp [C_ofNat]
  ring
-- Cayley-Hamilton on A: A^3 - 7A^2 + 16A - 12I = 0.
example : let A : Matrix (Fin 3) (Fin 3) ℤ := !![2, 1, 0; 0, 2, 0; 0, 0, 3]
    A ^ 3 - 7 • A ^ 2 + 16 • A - 12 • 1 = 0 := by decide
-- The columns fall one at a time: A - 2I, (A - 2I)^2, (A - 2I)^2 (A - 3I).
example : let A : Matrix (Fin 3) (Fin 3) ℤ := !![2, 1, 0; 0, 2, 0; 0, 0, 3]
    A - 2 • 1 = !![0, 1, 0; 0, 0, 0; 0, 0, 1] ∧
    (A - 2 • 1) ^ 2 = !![0, 0, 0; 0, 0, 0; 0, 0, 1] ∧
    (A - 2 • 1) ^ 2 * (A - 3 • 1) = 0 := by decide
-- Mistake 1: (x - 2)(x - 3) does not kill A, but it kills D.
example : let A : Matrix (Fin 3) (Fin 3) ℤ := !![2, 1, 0; 0, 2, 0; 0, 0, 3]
    (A - 2 • 1) * (A - 3 • 1) = !![0, -1, 0; 0, 0, 0; 0, 0, 0] := by decide
example : let D : Matrix (Fin 3) (Fin 3) ℤ := !![2, 0, 0; 0, 2, 0; 0, 0, 3]
    (D - 2 • 1) * (D - 3 • 1) = 0 := by decide
-- p_D = (x - 2) m_D, and x^4 divided by m_D = x^2 - 5x + 6 leaves 65x - 114.
example : (X ^ 3 - 7 * X ^ 2 + 16 * X - 12 : ℤ[X]) = (X - 2) * (X ^ 2 - 5 * X + 6) := by ring
example : (X ^ 4 : ℤ[X]) = (X ^ 2 + 5 * X + 19) * (X ^ 2 - 5 * X + 6) + (65 * X - 114) := by ring
-- So D^4 = 65D - 114I.
example : let D : Matrix (Fin 3) (Fin 3) ℤ := !![2, 0, 0; 0, 2, 0; 0, 0, 3]
    D ^ 4 = 65 • D - 114 • 1 := by decide
-- Cayley-Hamilton inverts A: 12 A⁻¹ = A^2 - 7A + 16I = [[6, -3, 0], [0, 6, 0], [0, 0, 4]].
example : let A : Matrix (Fin 3) (Fin 3) ℤ := !![2, 1, 0; 0, 2, 0; 0, 0, 3]
    A ^ 2 - 7 • A + 16 • 1 = !![6, -3, 0; 0, 6, 0; 0, 0, 4] ∧
    (A ^ 2 - 7 • A + 16 • 1) * A = 12 • 1 := by decide
-- Tenth powers, top row: A^10 gives (1024, 5120, 0), D^10 gives (1024, 0, 0).
example : let A : Matrix (Fin 3) (Fin 3) ℤ := !![2, 1, 0; 0, 2, 0; 0, 0, 3]
    (A ^ 10) 0 0 = 1024 ∧ (A ^ 10) 0 1 = 5120 ∧ (A ^ 10) 0 2 = 0 := by decide
example : let D : Matrix (Fin 3) (Fin 3) ℤ := !![2, 0, 0; 0, 2, 0; 0, 0, 3]
    (D ^ 10) 0 0 = 1024 ∧ (D ^ 10) 0 1 = 0 ∧ (D ^ 10) 0 2 = 0 := by decide
-- Mistake 2: the trace through the same substitution, 3A - 7I, is not zero.
example : let A : Matrix (Fin 3) (Fin 3) ℤ := !![2, 1, 0; 0, 2, 0; 0, 0, 3]
    3 • A - 7 • 1 = !![-1, 3, 0; 0, -1, 0; 0, 0, 2] := by decide
-- The patternless 4 by 4 M: p_M = x^4 - x^3 - 35x^2 + 38x + 175, and p_M(M) = 0.
example : let M : Matrix (Fin 4) (Fin 4) ℤ := !![2, -1, 0, 3; 1, 0, 4, 1; 0, 5, -2, 2; 3, 1, 1, 1]
    M ^ 4 - M ^ 3 - 35 • M ^ 2 + 38 • M + 175 • 1 = 0 := by decide
-- The fleet times 10, F = [[8, 3], [2, 7]]: F^2 - 15F + 50I = 0, i.e. the fleet obeys F^2 = 1.5F - 0.5I.
example : let F : Matrix (Fin 2) (Fin 2) ℤ := !![8, 3; 2, 7]
    F ^ 2 - 15 • F + 50 • 1 = 0 := by decide

#print axioms matrix_is_root_of_its_characteristic_polynomial
#print axioms minimal_polynomial_divides_every_killing_polynomial
#print axioms diagonalisable_iff_minimal_polynomial_has_no_repeated_root
