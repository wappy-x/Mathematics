-- Complex vectors and matrices: with the first vector conjugated, a complex column's squared length is a sum of real squares and is positive unless the column is zero, a Hermitian matrix has only real eigenvalues, and a matrix with U* U = I keeps every length; the card's quarter turn, its eigenvectors and its Hermitian partner are checked exactly.
import Mathlib.LinearAlgebra.Matrix.Hermitian
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Basic.Complex.BigOperators

open Matrix Complex

/-- Helper: the conjugated square of a complex column is the real sum of squares, positive
unless the column is zero. -/
theorem cvm_star_dot_self_aux (n : ℕ) (v : Fin n → ℂ) :
    star v ⬝ᵥ v = ((∑ j, ((v j).re ^ 2 + (v j).im ^ 2) : ℝ) : ℂ) ∧
      (v ≠ 0 → 0 < ∑ j, ((v j).re ^ 2 + (v j).im ^ 2)) := by
  refine ⟨?_, ?_⟩
  · rw [dotProduct, Complex.ofReal_sum]
    refine Finset.sum_congr rfl fun j _ => ?_
    apply Complex.ext <;> simp [Pi.star_apply, pow_two]; ring
  · intro hv
    obtain ⟨j, hj⟩ : ∃ j, v j ≠ 0 := by
      by_contra h
      push Not at h
      exact hv (funext h)
    apply Finset.sum_pos' (fun i _ => by positivity)
    refine ⟨j, Finset.mem_univ _, ?_⟩
    have := Complex.normSq_pos.mpr hj
    rw [Complex.normSq_apply] at this
    nlinarith

/-- Hermitian matrices have real eigenvalues. Let `H` be a square complex matrix of any size `n`
that equals its own conjugate transpose (`H* = H`). If `H v = λ v` for a non-zero complex column
`v`, then the eigenvalue `λ` is a real number: its imaginary part is 0. -/
theorem hermitian_eigenvalues_are_real (n : ℕ) (H : Matrix (Fin n) (Fin n) ℂ) (hH : H.IsHermitian)
    (lam : ℂ) (v : Fin n → ℂ) (hv : v ≠ 0) (heig : H *ᵥ v = lam • v) :
    lam.im = 0 := by
  obtain ⟨hs, hpos⟩ := cvm_star_dot_self_aux n v
  have hne : star v ⬝ᵥ v ≠ 0 := by
    rw [hs]; exact_mod_cast (hpos hv).ne'
  have h1 : star v ⬝ᵥ (H *ᵥ v) = lam * (star v ⬝ᵥ v) := by
    rw [heig, dotProduct_smul, smul_eq_mul]
  have h2 : star v ⬝ᵥ (H *ᵥ v) = star lam * (star v ⬝ᵥ v) := by
    rw [dotProduct_mulVec, ← hH.eq, ← star_mulVec, heig, star_smul, smul_dotProduct,
      smul_eq_mul]
  have h3 : lam = star lam := mul_right_cancel₀ hne (h1.symm.trans h2)
  have := congrArg Complex.im h3
  simp at this
  linarith

/-- Lengths that cannot vanish. For a complex column `v` with entries `v_j = a_j + b_j i`, the
conjugated dot product `v* v` (conjugate each entry of the first copy, multiply, add) equals the real
number `a_1² + b_1² + ... + a_n² + b_n²`, and that number is positive whenever `v` is not zero. -/
theorem conjugate_dot_self_is_sum_of_squares (n : ℕ) (v : Fin n → ℂ) :
    star v ⬝ᵥ v = ((∑ j, ((v j).re ^ 2 + (v j).im ^ 2) : ℝ) : ℂ) ∧
      (v ≠ 0 → 0 < ∑ j, ((v j).re ^ 2 + (v j).im ^ 2)) := by
  exact cvm_star_dot_self_aux n v

/-- Unitary matrices keep lengths. If a square complex matrix `U` of any size satisfies `U* U = I`,
then for every complex column `x`, the squared length of `U x` equals that of `x`:
`(U x)* (U x) = x* x`. -/
theorem unitary_keeps_length (n : ℕ) (U : Matrix (Fin n) (Fin n) ℂ) (hU : Uᴴ * U = 1)
    (x : Fin n → ℂ) :
    star (U *ᵥ x) ⬝ᵥ (U *ᵥ x) = star x ⬝ᵥ x := by
  rw [star_mulVec, ← dotProduct_mulVec, mulVec_mulVec, hU, one_mulVec]

/-! The card's worked numbers, checked exactly. R is the quarter turn, v = (1, i), w = (1, -i),
H = 2I - iR, S the complex symmetric look-alike, x the drone pair (3 + 4i, 1 + 2i). -/

-- plain square of v = (1, i) is 0; the conjugated square is 2
example : (![1, I] : Fin 2 → ℂ) ⬝ᵥ ![1, I] = 0 := by
  simp [dotProduct, Fin.sum_univ_two]
example : star (![1, I] : Fin 2 → ℂ) ⬝ᵥ ![1, I] = 2 := by
  simp [dotProduct, Fin.sum_univ_two]; norm_num
-- four real squares for v: 1 + 0 + 0 + 1 = 2
example : (1 : ℤ) ^ 2 + 0 ^ 2 + 0 ^ 2 + 1 ^ 2 = 2 := by decide
-- w = (1, -i) and v = (1, i) are perpendicular: w* v = 0, while the plain w^T v = 2
example : star (![1, -I] : Fin 2 → ℂ) ⬝ᵥ ![1, I] = 0 := by
  simp [dotProduct, Fin.sum_univ_two]
example : (![1, -I] : Fin 2 → ℂ) ⬝ᵥ ![1, I] = 2 := by
  simp [dotProduct, Fin.sum_univ_two]; norm_num
-- R (1, -i) = (i, 1) = i (1, -i), and R (1, i) = -i (1, i)
example : (!![0, -1; 1, 0] : Matrix (Fin 2) (Fin 2) ℂ) *ᵥ ![1, -I] = ![I, 1] := by
  ext k; fin_cases k <;> simp [mulVec, dotProduct, Fin.sum_univ_two]
example : (!![0, -1; 1, 0] : Matrix (Fin 2) (Fin 2) ℂ) *ᵥ ![1, -I] = I • ![1, -I] := by
  ext k; fin_cases k <;> simp [mulVec, dotProduct, Fin.sum_univ_two]
example : (!![0, -1; 1, 0] : Matrix (Fin 2) (Fin 2) ℂ) *ᵥ ![1, I] = (-I) • ![1, I] := by
  ext k; fin_cases k <;> simp [mulVec, dotProduct, Fin.sum_univ_two]
-- R is unitary: R* R = I; R is not Hermitian; four quarter turns are no turn
example : (!![0, -1; 1, 0] : Matrix (Fin 2) (Fin 2) ℂ)ᴴ * !![0, -1; 1, 0] = 1 := by
  rw [eta_fin_two (!![0, -1; 1, 0] : Matrix (Fin 2) (Fin 2) ℂ)ᴴ, mul_fin_two, one_fin_two]; simp
example : ¬ (!![0, -1; 1, 0] : Matrix (Fin 2) (Fin 2) ℂ).IsHermitian := by
  intro h
  have := congrFun (congrFun h 0) 1
  norm_num [conjTranspose_apply] at this
example : (!![0, -1; 1, 0] : Matrix (Fin 2) (Fin 2) ℤ) ^ 4 = 1 := by decide
-- no real eigenvalue for R: det(R - tI) = t^2 + 1, never below 1
example (t : ℝ) : (!![0 - t, -1; 1, 0 - t] : Matrix (Fin 2) (Fin 2) ℝ).det = t ^ 2 + 1 := by
  simp [det_fin_two]; ring
-- H = 2I - iR = [[2, i], [-i, 2]] is Hermitian, with H w = 3 w and H v = 1 v
example : (2 : Matrix (Fin 2) (Fin 2) ℂ) - I • !![0, -1; 1, 0] = !![2, I; -I, 2] := by
  rw [ofNat_fin_two]; ext i j; fin_cases i <;> fin_cases j <;> simp
example : (!![2, I; -I, 2] : Matrix (Fin 2) (Fin 2) ℂ).IsHermitian := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [conjTranspose_apply]
example : (!![2, I; -I, 2] : Matrix (Fin 2) (Fin 2) ℂ) *ᵥ ![1, -I] = (3 : ℂ) • ![1, -I] := by
  ext k; fin_cases k <;> simp [mulVec, dotProduct, Fin.sum_univ_two] <;> ring
example : (!![2, I; -I, 2] : Matrix (Fin 2) (Fin 2) ℂ) *ᵥ ![1, I] = (1 : ℂ) • ![1, I] := by
  ext k; fin_cases k <;> simp [mulVec, dotProduct, Fin.sum_univ_two] <;> ring
-- S = [[0, i], [i, 0]] equals its transpose but is not Hermitian, and has the eigenvalue i on (1, 1)
example : (!![0, I; I, 0] : Matrix (Fin 2) (Fin 2) ℂ)ᵀ = !![0, I; I, 0] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp
example : ¬ (!![0, I; I, 0] : Matrix (Fin 2) (Fin 2) ℂ).IsHermitian := by
  intro h
  have := congrFun (congrFun h 0) 1
  simp [conjTranspose_apply] at this
  have := congrArg Complex.im this
  norm_num at this
example : (!![0, I; I, 0] : Matrix (Fin 2) (Fin 2) ℂ) *ᵥ ![1, 1] = I • ![1, 1] := by
  ext k; fin_cases k <;> simp [mulVec, dotProduct, Fin.sum_univ_two]
-- the drone pair x = (3 + 4i, 1 + 2i): x* x = 25 + 5 = 30; R x = (-1 - 2i, 3 + 4i), squared length 5 + 25 = 30
example : star (![3 + 4 * I, 1 + 2 * I] : Fin 2 → ℂ) ⬝ᵥ ![3 + 4 * I, 1 + 2 * I] = 30 := by
  simp [dotProduct, Fin.sum_univ_two, map_ofNat]; ring_nf; simp [I_sq]; norm_num
example : (!![0, -1; 1, 0] : Matrix (Fin 2) (Fin 2) ℂ) *ᵥ ![3 + 4 * I, 1 + 2 * I]
    = ![-1 - 2 * I, 3 + 4 * I] := by
  ext k; fin_cases k <;> simp [mulVec, dotProduct, Fin.sum_univ_two]; ring
example : star (![-1 - 2 * I, 3 + 4 * I] : Fin 2 → ℂ) ⬝ᵥ ![-1 - 2 * I, 3 + 4 * I] = 30 := by
  simp [dotProduct, Fin.sum_univ_two, map_ofNat]; ring_nf; simp [I_sq]; norm_num

#print axioms cvm_star_dot_self_aux
#print axioms hermitian_eigenvalues_are_real
#print axioms conjugate_dot_self_is_sum_of_squares
#print axioms unitary_keeps_length
