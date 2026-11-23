-- The Jacobian conjecture: a one-variable polynomial with constant nonzero derivative has a polynomial inverse, while from three variables up a polynomial map with constant nonzero Jacobian determinant can send two points to one, as the 2026 map K does.
import Mathlib.Algebra.MvPolynomial.PDeriv
import Mathlib.Algebra.Polynomial.Derivative
import Mathlib.Basic.Complex.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.NormNum

noncomputable section

open MvPolynomial

/-- The Jacobian grid of a polynomial map F of n-space: the entry in row i, column j is the
partial derivative ∂F_i/∂x_j, itself a polynomial. -/
def jacobianMatrix {n : ℕ} (F : Fin n → MvPolynomial (Fin n) ℂ) :
    Matrix (Fin n) (Fin n) (MvPolynomial (Fin n) ℂ) :=
  Matrix.of fun i j => pderiv j (F i)

/-- The point map of F: it sends a point x of ℂⁿ to (F_1(x), …, F_n(x)). -/
def pointMap {n : ℕ} (F : Fin n → MvPolynomial (Fin n) ℂ) : (Fin n → ℂ) → (Fin n → ℂ) :=
  fun x i => eval x (F i)

/-- One variable, proved. Over a field where whole numbers never vanish, a polynomial f whose
rate f' is a constant c ≠ 0 has an inverse g that is again a polynomial: g undoes f and f
undoes g, as compositions of polynomials. -/
theorem jacobian_conjecture_one_variable {K : Type*} [Field K] [CharZero K]
    (f : Polynomial K) (c : K) (hf : Polynomial.derivative f = Polynomial.C c) (hc : c ≠ 0) :
    ∃ g : Polynomial K, f.comp g = Polynomial.X ∧ g.comp f = Polynomial.X := by
  have hcoef : ∀ n, f.coeff (n + 2) = 0 := by
    intro n
    have h := congrArg (fun p => Polynomial.coeff p (n + 1)) hf
    simp only [Polynomial.coeff_derivative, Polynomial.coeff_C] at h
    simp only [Nat.add_one_ne_zero, ite_false] at h
    have h2 : ((n + 1 : ℕ) : K) + 1 ≠ 0 := by exact_mod_cast Nat.succ_ne_zero (n + 1)
    have : f.coeff (n + 1 + 1) * (((n + 1 : ℕ) : K) + 1) = 0 := by exact_mod_cast h
    exact (mul_eq_zero.mp this).resolve_right h2
  have h1 : f.coeff 1 = c := by
    have h := congrArg (fun p => Polynomial.coeff p 0) hf
    simpa [Polynomial.coeff_derivative] using h
  have hform : f = Polynomial.C (f.coeff 0) + Polynomial.C c * Polynomial.X := by
    ext n
    rcases n with _ | _ | n
    · simp
    · simp [h1]
    · simp [hcoef n]
  obtain ⟨a, ha⟩ : ∃ a, f = Polynomial.C a + Polynomial.C c * Polynomial.X := ⟨_, hform⟩
  subst ha
  refine ⟨Polynomial.C c⁻¹ * (Polynomial.X - Polynomial.C a), ?_, ?_⟩
  · 
    simp only [Polynomial.add_comp, Polynomial.mul_comp, Polynomial.C_comp, Polynomial.X_comp]
    rw [← mul_assoc, ← Polynomial.C_mul, mul_inv_cancel₀ hc]
    simp
  · simp only [Polynomial.mul_comp, Polynomial.sub_comp, Polynomial.C_comp, Polynomial.X_comp]
    rw [add_sub_cancel_left, ← mul_assoc, ← Polynomial.C_mul, inv_mul_cancel₀ hc]
    simp

/-- The 2026 counterexample, with s = 1 + xy and t = 4 + 3xy:
K(x, y, z) = (s³z + y²st, y + 3xs²z + 3xy²t, 2x − 3x²y − x³z). -/
def keller2026 : Fin 3 → MvPolynomial (Fin 3) ℂ :=
  let x : MvPolynomial (Fin 3) ℂ := X 0
  let y : MvPolynomial (Fin 3) ℂ := X 1
  let z : MvPolynomial (Fin 3) ℂ := X 2
  let s := 1 + x * y
  let t := 4 + 3 * x * y
  ![s ^ 3 * z + y ^ 2 * s * t,
    y + 3 * x * s ^ 2 * z + 3 * x * y ^ 2 * t,
    2 * x - 3 * x ^ 2 * y - x ^ 3 * z]

/-- The 2026 map K of ℂ³ has Jacobian determinant −2 as a polynomial, so −2 at every point,
yet the three different points (0, 0, −1/4), (1, −3/2, 13/2) and (−1, 3/2, 13/2) all go to
(−1/4, 0, 0); so K is not one to one and has no inverse of any kind. -/
theorem keller2026_det_and_collision :
    (jacobianMatrix keller2026).det = C (-2) ∧
      pointMap keller2026 ![0, 0, -1/4] = ![-1/4, 0, 0] ∧
      pointMap keller2026 ![1, -3/2, 13/2] = ![-1/4, 0, 0] ∧
      pointMap keller2026 ![-1, 3/2, 13/2] = ![-1/4, 0, 0] := by
  refine ⟨?_, ?_, ?_, ?_⟩
  · have hn : ∀ (i : Fin 3) (n : ℕ) [n.AtLeastTwo],
        pderiv i (OfNat.ofNat n : MvPolynomial (Fin 3) ℂ) = 0 := by
      intro i n _
      rw [show (OfNat.ofNat n : MvPolynomial (Fin 3) ℂ) = ((OfNat.ofNat n : ℕ) : MvPolynomial (Fin 3) ℂ)
        from (Nat.cast_ofNat).symm]
      exact Derivation.map_natCast _ _
    have h01 : pderiv 0 (X 1 : MvPolynomial (Fin 3) ℂ) = 0 := pderiv_X_of_ne (by decide)
    have h02 : pderiv 0 (X 2 : MvPolynomial (Fin 3) ℂ) = 0 := pderiv_X_of_ne (by decide)
    have h10 : pderiv 1 (X 0 : MvPolynomial (Fin 3) ℂ) = 0 := pderiv_X_of_ne (by decide)
    have h12 : pderiv 1 (X 2 : MvPolynomial (Fin 3) ℂ) = 0 := pderiv_X_of_ne (by decide)
    have h20 : pderiv 2 (X 0 : MvPolynomial (Fin 3) ℂ) = 0 := pderiv_X_of_ne (by decide)
    have h21 : pderiv 2 (X 1 : MvPolynomial (Fin 3) ℂ) = 0 := pderiv_X_of_ne (by decide)
    rw [Matrix.det_fin_three]
    simp only [jacobianMatrix, Matrix.of_apply, keller2026, Matrix.cons_val_zero, Matrix.cons_val_one,
      Matrix.cons_val_two, Matrix.head_cons, Matrix.tail_cons]
    simp only [map_add, map_sub, Derivation.leibniz, Derivation.leibniz_pow, smul_eq_mul, nsmul_eq_mul,
      Derivation.map_one_eq_zero, pderiv_X_self, h01, h02, h10, h12, h20, h21, hn]
    simp only [Nat.cast_ofNat, Nat.add_one_sub_one, pow_one]
    rw [map_neg, map_ofNat C 2]
    ring
  all_goals
    funext i
    fin_cases i <;> simp [pointMap, keller2026] <;> norm_num

/-- Refuted for n of 3 or more: in every dimension n ≥ 3 there is a polynomial map of ℂⁿ whose
Jacobian determinant is a nonzero constant c, yet two different points have the same image,
so no polynomial inverse exists. -/
theorem jacobian_conjecture_false_of_three_le (n : ℕ) (hn : 3 ≤ n) :
    ∃ F : Fin n → MvPolynomial (Fin n) ℂ, ∃ c : ℂ, c ≠ 0 ∧
      (jacobianMatrix F).det = C c ∧ ¬ Function.Injective (pointMap F) := by
  classical
  obtain ⟨hdet, h1, h2, -⟩ := keller2026_det_and_collision
  obtain ⟨k, rfl⟩ : ∃ k, n = 3 + k := ⟨n - 3, by omega⟩
  let e : Fin 3 ⊕ Fin k ≃ Fin (3 + k) := finSumFinEquiv
  let ι : Fin 3 → Fin (3 + k) := fun j => e (Sum.inl j)
  have hι : Function.Injective ι := e.injective.comp Sum.inl_injective
  have hzero : ∀ (p : MvPolynomial (Fin 3) ℂ) (v : Fin (3 + k)), (∀ j, ι j ≠ v) →
      pderiv v (rename ι p) = 0 := by
    intro p v hv
    induction p using MvPolynomial.induction_on with
    | C a => simp
    | add p q hp hq => simp [hp, hq]
    | mul_X p j h =>
      rw [map_mul, rename_X, Derivation.leibniz, h, pderiv_X_of_ne (hv j)]
      simp
  let F : Fin (3 + k) → MvPolynomial (Fin (3 + k)) ℂ := fun i =>
    Sum.elim (fun j => rename ι (keller2026 j)) (fun _ => X i) (e.symm i)
  refine ⟨F, -2, by norm_num, ?_, ?_⟩
  · have key : (jacobianMatrix F).submatrix e e =
        Matrix.fromBlocks ((jacobianMatrix keller2026).map (rename ι)) 0 0 1 := by
      refine Matrix.ext fun i j => ?_
      rcases i with a | a <;> rcases j with b | b
      · simp [jacobianMatrix, F, ι, Matrix.fromBlocks]
        exact pderiv_rename hι b (keller2026 a)
      · simp only [jacobianMatrix, F, Matrix.submatrix_apply, Matrix.of_apply,
          Equiv.symm_apply_apply, Sum.elim_inl, Matrix.fromBlocks_apply₁₂, Matrix.zero_apply]
        apply hzero
        intro j h
        exact Sum.inl_ne_inr (e.injective h)
      · simp only [jacobianMatrix, F, Matrix.submatrix_apply, Matrix.of_apply,
          Equiv.symm_apply_apply, Sum.elim_inr, Matrix.fromBlocks_apply₂₁, Matrix.zero_apply]
        apply pderiv_X_of_ne
        intro h
        exact Sum.inr_ne_inl (e.injective h)
      · simp only [jacobianMatrix, F, Matrix.submatrix_apply, Matrix.of_apply,
          Equiv.symm_apply_apply, Sum.elim_inr, Matrix.fromBlocks_apply₂₂, pderiv_X,
          Pi.single_apply, Matrix.one_apply, e.injective.eq_iff, Sum.inr.injEq]
    rw [← Matrix.det_submatrix_equiv_self e, key, Matrix.det_fromBlocks_zero₂₁, Matrix.det_one,
      mul_one]
    have hm := AlgHom.map_det (rename ι) (jacobianMatrix keller2026)
    rw [AlgHom.mapMatrix_apply] at hm
    rw [← hm, hdet, rename_C]
  · intro hinj
    let lift : (Fin 3 → ℂ) → Fin (3 + k) → ℂ := fun v i => Sum.elim v (fun _ => 0) (e.symm i)
    have hlift : ∀ v, pointMap F (lift v) = lift (pointMap keller2026 v) := by
      intro v
      funext i
      obtain ⟨a, rfl⟩ := e.surjective i
      rcases a with j | j
      · have hc : lift v ∘ ι = v := by
          funext j'
          simp [lift, ι]
        simp only [pointMap, F, lift, Equiv.symm_apply_apply, Sum.elim_inl, eval_rename]
        rw [show (fun i => Sum.elim v (fun _ => (0 : ℂ)) (e.symm i)) ∘ ι = v from hc]
      · simp [pointMap, F, lift]
    have h := @hinj (lift ![0, 0, -1/4]) (lift ![1, -3/2, 13/2]) (by rw [hlift, hlift, h1, h2])
    have := congrFun h (ι 0)
    simp [lift, ι] at this

end

-- The plane map at (1, 2): u = 3, F(1, 2) = (1 + 9, 2 − 9) = (10, −7).
example : ((1 : ℤ) + (1 + 2) ^ 2, (2 : ℤ) - (1 + 2) ^ 2) = (10, -7) := by norm_num
-- The undo: w = 10 + (−7) = 3, G(10, −7) = (10 − 9, −7 + 9) = (1, 2).
example : ((10 : ℤ) - (10 + -7) ^ 2, (-7 : ℤ) + (10 + -7) ^ 2) = (1, 2) := by norm_num
-- The Jacobian at (1, 2) is [[7, 6], [−6, −5]], determinant 7 × (−5) − 6 × (−6) = 1.
example : !![(7 : ℤ), 6; -6, -5].det = 1 := by norm_num [Matrix.det_fin_two]
-- J − I = [[6, 6], [−6, −6]] squares to the zero grid.
example : !![(6 : ℤ), 6; -6, -6] * !![(6 : ℤ), 6; -6, -6] = 0 := by decide
-- Modulo 5, x − x⁵ sends all of 0, 1, 2, 3, 4 to 0.
example : ∀ a : ZMod 5, a - a ^ 5 = 0 := by decide
-- Coefficients −2..2 up to degree 3: 625 polynomials; rate a₁ + 2a₂x + 3a₃x² is a nonzero
-- constant for exactly 20 of them.
example : (Finset.univ : Finset (Fin 5 × Fin 5 × Fin 5 × Fin 5)).card = 625 := by
  norm_num [Finset.card_univ]
example : ((Finset.univ : Finset (Fin 5 × Fin 5 × Fin 5 × Fin 5)).filter fun a =>
    let v : Fin 5 → ℤ := fun k => (k : ℤ) - 2
    v a.2.1 ≠ 0 ∧ 2 * v a.2.2.1 = 0 ∧ 3 * v a.2.2.2 = 0).card = 20 := by decide
-- The 3-d collision at (1, −3/2, 13/2), by hand: s = t = −1/2 and the three outputs.
example : (1 : ℚ) + 1 * (-3/2) = -1/2 ∧ (4 : ℚ) + 3 * 1 * (-3/2) = -1/2 ∧
    (-13/16 : ℚ) + 9/16 = -1/4 ∧ (-3/2 : ℚ) + 39/8 - 27/8 = 0 ∧ (2 : ℚ) + 9/2 - 13/2 = 0 := by
  norm_num

#print axioms jacobian_conjecture_one_variable
#print axioms keller2026_det_and_collision
#print axioms jacobian_conjecture_false_of_three_le
