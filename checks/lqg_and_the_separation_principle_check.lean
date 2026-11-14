-- LQG: feeding the filter's estimate into the regulator's gain gives a loop whose poles are exactly the regulator's poles together with the filter's poles, because the filter's error ignores the steering.
import Mathlib.LinearAlgebra.Matrix.Charpoly.Basic
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Tactic.NormNum

open Matrix

/-- The separation principle, for the poles. Take any linear plant `x ↦ A x + B u`, read through
`y = C x`, any regulator gain `K` and any filter gain `M`. The controller corrects its prediction
`z` by the reading, `x̂ = z + M (y - C z)`, commands `u = -K x̂`, and predicts the next state as
`A x̂ + B u`, using the same `B` as the plant. Let `Φ` be the matrix that steps the plant state and
the prediction forward together. Then the characteristic polynomial of `Φ` is the regulator's,
`det(λI - (A - BK))`, times the filter's, `det(λI - A(I - MC))`: the joined loop's poles are the
two designs' poles side by side, and nothing else. -/
theorem lqg_loop_poles_eq_regulator_poles_and_filter_poles
    {n m p : Type*} [Fintype n] [DecidableEq n] [Fintype m] [Fintype p]
    (A : Matrix n n ℝ) (B : Matrix n m ℝ) (C : Matrix p n ℝ)
    (K : Matrix m n ℝ) (M : Matrix n p ℝ) (Φ : Matrix (n ⊕ n) (n ⊕ n) ℝ)
    (hΦ : ∀ x z : n → ℝ,
      let xhat := z + M *ᵥ (C *ᵥ x - C *ᵥ z)
      let u := -(K *ᵥ xhat)
      Φ *ᵥ Sum.elim x z = Sum.elim (A *ᵥ x + B *ᵥ u) (A *ᵥ xhat + B *ᵥ u)) :
    Φ.charpoly = (A - B * K).charpoly * (A * (1 - M * C)).charpoly := by
  set T : Matrix (n ⊕ n) (n ⊕ n) ℝ := fromBlocks 1 0 1 (-1) with hT
  set U : Matrix (n ⊕ n) (n ⊕ n) ℝ :=
    fromBlocks (A - B * K) (B * K * (1 - M * C)) 0 (A * (1 - M * C)) with hU
  have hTT : T * T = 1 := by
    rw [hT, fromBlocks_multiply]; simp [fromBlocks_one]
  have hΦU : Φ = T * (U * T) := by
    rw [ext_iff_mulVec]
    intro v
    rw [← Sum.elim_comp_inl_inr v, hΦ, ← mulVec_mulVec, ← mulVec_mulVec, hT, hU]
    simp only [fromBlocks_mulVec, Sum.elim_comp_inl, Sum.elim_comp_inr]
    congr 1
    · simp only [mulVec_add, mulVec_sub, mulVec_neg, sub_mulVec, add_mulVec, ← mulVec_mulVec,
        one_mulVec, Matrix.mul_sub, Matrix.sub_mul, Matrix.mul_one, zero_mulVec, neg_mulVec, mulVec_zero]
      abel
    · simp only [mulVec_add, mulVec_sub, mulVec_neg, sub_mulVec, add_mulVec, ← mulVec_mulVec,
        one_mulVec, Matrix.mul_sub, Matrix.sub_mul, Matrix.mul_one, zero_mulVec, neg_mulVec, mulVec_zero]
      abel
  rw [hΦU, charpoly_mul_comm, Matrix.mul_assoc, hTT, Matrix.mul_one, hU,
    charpoly_fromBlocks_zero₂₁]

/-- The filter's error does not care what the motor does. With shove `d` and encoder noise `v`,
the plant steps to `A x + B u + B d`, the reading is `y = C x + v`, the estimate is
`x̂ = z + M (y - C z)` and the next prediction is `A x̂ + B u`. Whatever command `u` is applied,
the new prediction error is `A(I - MC) e - A M v + B d`, where `e = x - z`: no `u` appears. -/
theorem lqg_prediction_error_ignores_command
    {n m p : Type*} [Fintype n] [DecidableEq n] [Fintype m] [Fintype p]
    (A : Matrix n n ℝ) (B : Matrix n m ℝ) (C : Matrix p n ℝ) (M : Matrix n p ℝ)
    (x z : n → ℝ) (u d : m → ℝ) (v : p → ℝ) :
    let y := C *ᵥ x + v
    let xhat := z + M *ᵥ (y - C *ᵥ z)
    (A *ᵥ x + B *ᵥ u + B *ᵥ d) - (A *ᵥ xhat + B *ᵥ u)
      = (A * (1 - M * C)) *ᵥ (x - z) - (A * M) *ᵥ v + B *ᵥ d := by
  intro y xhat
  simp only [y, xhat, mulVec_add, mulVec_sub, sub_mulVec, ← mulVec_mulVec, one_mulVec,
    Matrix.mul_sub, Matrix.mul_one]
  abel

/-- Completing the square with the regulator's Riccati equation (one motor input, as on the card).
Let `P` be the regulator's cost-to-go matrix (a symmetric matrix, since `xᵀ P x` is a cost),
`s = R + Bᵀ P B`, `K = s⁻¹ Bᵀ P A` the LQR gain, and suppose `P = Q + Aᵀ P A - Kᵀ s K`. Then for
every state `x` and command `u`,
`xᵀ Q x + R u² = xᵀ P x - (A x + B u)ᵀ P (A x + B u) + s (u + K x)²`.
This is the step that makes `u = -K x̂` the best command once only the estimate is known. -/
theorem lqr_riccati_completes_the_square
    {n : Type*} [Fintype n] [DecidableEq n]
    (A P Q : Matrix n n ℝ) (b K : n → ℝ) (R s : ℝ)
    (hsym : Pᵀ = P)
    (hs : s = R + b ⬝ᵥ (P *ᵥ b))
    (hK : s • K = b ᵥ* (P * A))
    (hP : P = Q + Aᵀ * P * A - s • vecMulVec K K)
    (x : n → ℝ) (u : ℝ) :
    x ⬝ᵥ (Q *ᵥ x) + R * u ^ 2
      = x ⬝ᵥ (P *ᵥ x) - (A *ᵥ x + u • b) ⬝ᵥ (P *ᵥ (A *ᵥ x + u • b)) + s * (u + K ⬝ᵥ x) ^ 2 := by
  have hswap : ∀ v w : n → ℝ, v ⬝ᵥ (P *ᵥ w) = w ⬝ᵥ (P *ᵥ v) := by
    intro v w
    rw [dotProduct_mulVec, ← hsym, vecMul_transpose, hsym, dotProduct_comm]
  have h1 : x ⬝ᵥ (P *ᵥ x) = x ⬝ᵥ (Q *ᵥ x) + (A *ᵥ x) ⬝ᵥ (P *ᵥ (A *ᵥ x))
      - s * (K ⬝ᵥ x) ^ 2 := by
    conv_lhs => rw [hP]
    rw [sub_mulVec, add_mulVec, smul_mulVec, vecMulVec_mulVec, dotProduct_sub,
      dotProduct_add, dotProduct_smul, ← mulVec_mulVec, ← mulVec_mulVec, dotProduct_mulVec x Aᵀ,
      vecMul_transpose]
    simp only [MulOpposite.smul_eq_mul_unop, MulOpposite.unop_op, smul_eq_mul, dotProduct_smul]
    rw [dotProduct_comm x K]
    ring
  have h2 : s * (K ⬝ᵥ x) = b ⬝ᵥ (P *ᵥ (A *ᵥ x)) := by
    have := congrArg (· ⬝ᵥ x) hK
    simp only [smul_dotProduct, smul_eq_mul] at this
    rw [this, ← dotProduct_mulVec, mulVec_mulVec]
  have h3 : (A *ᵥ x + u • b) ⬝ᵥ (P *ᵥ (A *ᵥ x + u • b))
      = (A *ᵥ x) ⬝ᵥ (P *ᵥ (A *ᵥ x)) + 2 * u * (b ⬝ᵥ (P *ᵥ (A *ᵥ x)))
        + u ^ 2 * (b ⬝ᵥ (P *ᵥ b)) := by
    rw [mulVec_add, mulVec_smul, add_dotProduct, dotProduct_add, dotProduct_add,
      smul_dotProduct, smul_dotProduct, dotProduct_smul, dotProduct_smul, hswap (A *ᵥ x) b]
    simp only [smul_eq_mul]
    ring
  rw [h1, h3, ← h2, hs]
  ring

-- The card's pole: g = 9.81 m/s², l = 0.613125 m, so g/l = 16 exactly, and the open-loop pole is 4 rad/s.
example : ((981 : ℚ) / 100) / (981 / 1600) = 16 := by norm_num
example : Real.sqrt 16 = 4 := by
  rw [show (16 : ℝ) = 4 ^ 2 by norm_num]; exact Real.sqrt_sq (by norm_num)

#print axioms lqg_loop_poles_eq_regulator_poles_and_filter_poles
#print axioms lqg_prediction_error_ignores_command
#print axioms lqr_riccati_completes_the_square
