-- Several inputs, several outputs: every row of the relative gain array of an invertible square matrix sums to 1, a decoupler's loop gain is 1 plus the input errors weighted by the RGA, and det(I + L) is the closed-loop polynomial over the open-loop one.
import Mathlib.LinearAlgebra.Matrix.Hadamard
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.SchurComplement
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Data.Real.Sqrt
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Matrix

/-- The relative gain array of a square, invertible gain matrix `G` is `Λ = G ⊙ (G⁻¹)ᵀ`,
entry by entry. Each row of it sums to 1, because row `i` sums to `(G G⁻¹)ᵢᵢ = 1`. -/
theorem rga_row_sum_eq_one {K : Type*} [Field K] {n : Type*} [Fintype n] [DecidableEq n]
    (G : Matrix n n K) (hG : IsUnit G.det) (i : n) :
    ∑ j, (G ⊙ (G⁻¹)ᵀ) i j = 1 := by
  have h := congrFun (congrFun (mul_nonsing_inv G hG) i) i
  simp only [Matrix.mul_apply, Matrix.one_apply_eq] at h
  simpa [hadamard_apply, transpose_apply] using h

/-- If the drives' real gains are `1 + εⱼ` instead of 1, a decoupler `G⁻¹` built from the model
leaves the steady loop matrix `G (I + E) G⁻¹`, and its diagonal entry `i` is
`1 + ∑ⱼ λᵢⱼ εⱼ`: the relative gain array multiplies the input errors. -/
theorem decoupled_loop_diag_eq_one_add_rga_mul_error {K : Type*} [Field K] {n : Type*}
    [Fintype n] [DecidableEq n] (G : Matrix n n K) (hG : IsUnit G.det) (ε : n → K) (i : n) :
    (G * (1 + diagonal ε) * G⁻¹) i i = 1 + ∑ j, (G ⊙ (G⁻¹)ᵀ) i j * ε j := by
  have h1 : G * (1 + diagonal ε) * G⁻¹ = G * G⁻¹ + G * diagonal ε * G⁻¹ := by
    rw [Matrix.mul_add, Matrix.mul_one, Matrix.add_mul]
  rw [h1, mul_nonsing_inv G hG]
  simp only [Matrix.add_apply, Matrix.one_apply_eq, Matrix.mul_apply,
    Matrix.hadamard_apply, Matrix.transpose_apply]
  congr 1
  refine Finset.sum_congr rfl fun j _ => ?_
  rw [← Matrix.mul_apply, Matrix.mul_diagonal]
  ring

/-- With the loop in state space, `L(s) = C (sI - A)⁻¹ B`, unity feedback gives the closed-loop
matrix `A - BC`, and `det(sI - A + BC) = det(sI - A) · det(I + L(s))`: so `det(I + L)` is the
closed-loop pole polynomial over the open-loop one, which is what the generalised Nyquist
criterion counts turns of. -/
theorem det_closed_loop_eq_det_open_loop_mul_det_one_add_loop {K : Type*} [Field K]
    {n m : Type*} [Fintype n] [DecidableEq n] [Fintype m] [DecidableEq m]
    (A : Matrix n n K) (B : Matrix n m K) (C : Matrix m n K) (s : K)
    (hs : IsUnit (s • (1 : Matrix n n K) - A).det) :
    (s • (1 : Matrix n n K) - A + B * C).det
      = (s • (1 : Matrix n n K) - A).det * (1 + C * (s • (1 : Matrix n n K) - A)⁻¹ * B).det := by
  exact det_add_mul B C hs

-- The belt's steady gain G(0) = [[1, 0.8], [0.8, 1]]: its relative gain λ₁₁ is 25/9 = 2.7778.
example : ((!![(1 : ℚ), 4/5; 4/5, 1]) ⊙ (!![(1 : ℚ), 4/5; 4/5, 1])⁻¹ᵀ) 0 0 = 25/9 := by
  rw [inv_def, adjugate_fin_two_of, det_fin_two_of]
  simp [hadamard_apply]
  norm_num

-- λ₁₁ = 1/(1 - 0.8 × 0.8) = 2.7778, and λ₁₂ = 1 - λ₁₁ = -1.7778.
example : (1 : ℚ) / (1 - 4/5 * (4/5)) = 25/9 ∧ 1 - (25/9 : ℚ) = -16/9 := by
  norm_num

-- "Together" (1, 1) is stretched by 1.8 and "against" (1, -1) by 0.2; condition number 9.
example : !![(1 : ℚ), 4/5; 4/5, 1] *ᵥ ![1, 1] = (9/5 : ℚ) • ![1, 1] ∧
    !![(1 : ℚ), 4/5; 4/5, 1] *ᵥ ![1, -1] = (1/5 : ℚ) • ![1, -1] ∧
    (9/5 : ℚ) / (1/5) = 9 := by
  refine ⟨?_, ?_, ?_⟩
  · ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_two] <;> norm_num
  · ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_two] <;> norm_num
  · norm_num

-- Drive commands for a 1 % step on pulley 1: 2.778 % and -2.222 %, that is 25/9 and -20/9.
example : !![(1 : ℚ), 4/5; 4/5, 1] *ᵥ ![25/9, -20/9] = ![1, 0] := by
  ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_two] <;> norm_num

-- The transmission zeros: (0.5 z + 1)² = 0.64 exactly at z = -0.4 and z = -3.6 rad/s.
example (z : ℝ) : (z/2 + 1)^2 = (4/5)^2 ↔ z = -2/5 ∨ z = -18/5 := by
  constructor
  · intro h
    have h2 : (z + 2/5) * (z + 18/5) = 0 := by nlinarith [h]
    rcases mul_eq_zero.mp h2 with h3 | h3
    · left; linarith
    · right; linarith
  · rintro (rfl | rfl) <;> norm_num

-- The "against" loop: 0.5 s² + s + 5 (0.5 s + 0.2) = (s² + 7 s + 2)/2, with slow root (-7 + √41)/2.
example (s : ℝ) : s^2/2 + s + 5 * (s/2 + 1/5) = (s^2 + 7*s + 2)/2 := by
  ring

example : ((-7 + Real.sqrt 41)/2)^2 + 7 * ((-7 + Real.sqrt 41)/2) + 2 = 0 := by
  have h := Real.sq_sqrt (show (0:ℝ) ≤ 41 by norm_num)
  nlinarith [h]

-- The swapped pairing: s² - 3 s - 2 has the unstable root (3 + √17)/2 = 3.5616 rad/s.
example : ((3 + Real.sqrt 17)/2)^2 - 3 * ((3 + Real.sqrt 17)/2) - 2 = 0 ∧ 0 < (3 + Real.sqrt 17)/2 := by
  have h := Real.sq_sqrt (show (0:ℝ) ≤ 17 by norm_num)
  have h2 := Real.sqrt_nonneg 17
  constructor
  · nlinarith [h]
  · linarith

-- Drive 1 20 % weak behind the decoupler: loop 1's steady gain 1 + λ₁₁ ε₁ = 1 - (25/9)(1/5) = 4/9 = 0.4444.
example : (1 : ℚ) + 25/9 * (-1/5) = 4/9 := by
  norm_num

#print axioms rga_row_sum_eq_one
#print axioms decoupled_loop_diag_eq_one_add_rga_mul_error
#print axioms det_closed_loop_eq_det_open_loop_mul_det_one_add_loop
