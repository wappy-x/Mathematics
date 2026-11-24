-- Model reduction: a change of coordinates carries the two Gramians along and leaves the Hankel singular values unchanged, and states that are unseeable or unreachable drop out of every Markov parameter C A^k B.
import Mathlib.LinearAlgebra.Matrix.Charpoly.Basic
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Data.Matrix.ColumnRowPartitioned
import Mathlib.Data.Matrix.Block
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Data.Real.Basic

open Matrix

/-- Hankel singular values do not depend on the coordinates. Let the Gramians `P` and `Q` of the
model `x' = A x + B u`, `y = C x` solve the two Lyapunov equations `A P + P Aᵀ + B Bᵀ = 0` and
`Aᵀ Q + Q A + Cᵀ C = 0`. Write the state as `z = T x` with `T` invertible, so the model becomes
`(T A T⁻¹, T B, C T⁻¹)`. Then `T P Tᵀ` and `T⁻ᵀ Q T⁻¹` solve the Lyapunov equations of the new
model, their product is the similarity transform `T (P Q) T⁻¹`, and so it has the same
characteristic polynomial as `P Q`: the eigenvalues of `P Q`, whose square roots are the Hankel
singular values, are unchanged. -/
theorem hankel_singular_values_coordinate_free
    {n m p : Type*} [Fintype n] [DecidableEq n] [Fintype m] [Fintype p]
    (A P Q T : Matrix n n ℝ) (B : Matrix n m ℝ) (C : Matrix p n ℝ)
    (hP : A * P + P * Aᵀ + B * Bᵀ = 0)
    (hQ : Aᵀ * Q + Q * A + Cᵀ * C = 0)
    (hT : IsUnit T.det) :
    (T * A * T⁻¹) * (T * P * Tᵀ) + (T * P * Tᵀ) * (T * A * T⁻¹)ᵀ + (T * B) * (T * B)ᵀ = 0 ∧
    (T * A * T⁻¹)ᵀ * ((T⁻¹)ᵀ * Q * T⁻¹) + ((T⁻¹)ᵀ * Q * T⁻¹) * (T * A * T⁻¹)
        + (C * T⁻¹)ᵀ * (C * T⁻¹) = 0 ∧
    (T * P * Tᵀ) * ((T⁻¹)ᵀ * Q * T⁻¹) = T * (P * Q) * T⁻¹ ∧
    ((T * P * Tᵀ) * ((T⁻¹)ᵀ * Q * T⁻¹)).charpoly = (P * Q).charpoly := by
  have h1 : T⁻¹ * T = 1 := Matrix.nonsing_inv_mul T hT
  have h2 : T * T⁻¹ = 1 := Matrix.mul_nonsing_inv T hT
  have h3 : Tᵀ * (T⁻¹)ᵀ = 1 := by rw [← Matrix.transpose_mul, h1, Matrix.transpose_one]
  have key : (T * P * Tᵀ) * ((T⁻¹)ᵀ * Q * T⁻¹) = T * (P * Q) * T⁻¹ := by
    calc (T * P * Tᵀ) * ((T⁻¹)ᵀ * Q * T⁻¹) = T * P * (Tᵀ * (T⁻¹)ᵀ) * Q * T⁻¹ := by
          simp only [Matrix.mul_assoc]
      _ = T * (P * Q) * T⁻¹ := by rw [h3]; simp only [Matrix.mul_one, Matrix.mul_assoc]
  refine ⟨?_, ?_, key, ?_⟩
  · calc (T * A * T⁻¹) * (T * P * Tᵀ) + (T * P * Tᵀ) * (T * A * T⁻¹)ᵀ + (T * B) * (T * B)ᵀ
        = T * A * (T⁻¹ * T) * P * Tᵀ + T * P * (Tᵀ * (T⁻¹)ᵀ) * Aᵀ * Tᵀ + T * (B * Bᵀ) * Tᵀ := by
          simp only [Matrix.transpose_mul, Matrix.mul_assoc]
      _ = T * (A * P + P * Aᵀ + B * Bᵀ) * Tᵀ := by
          rw [h1, h3]; simp only [Matrix.mul_one, Matrix.mul_add, Matrix.add_mul, Matrix.mul_assoc]
      _ = 0 := by rw [hP]; simp
  · calc (T * A * T⁻¹)ᵀ * ((T⁻¹)ᵀ * Q * T⁻¹) + ((T⁻¹)ᵀ * Q * T⁻¹) * (T * A * T⁻¹)
          + (C * T⁻¹)ᵀ * (C * T⁻¹)
        = (T⁻¹)ᵀ * Aᵀ * (Tᵀ * (T⁻¹)ᵀ) * Q * T⁻¹ + (T⁻¹)ᵀ * Q * (T⁻¹ * T) * A * T⁻¹
          + (T⁻¹)ᵀ * (Cᵀ * C) * T⁻¹ := by
          simp only [Matrix.transpose_mul, Matrix.mul_assoc]
      _ = (T⁻¹)ᵀ * (Aᵀ * Q + Q * A + Cᵀ * C) * T⁻¹ := by
          rw [h1, h3]; simp only [Matrix.mul_one, Matrix.mul_add, Matrix.add_mul, Matrix.mul_assoc]
      _ = 0 := by rw [hQ]; simp
  · rw [key]
    have hu : IsUnit T := (Matrix.isUnit_iff_isUnit_det T).mpr hT
    obtain ⟨U, rfl⟩ := hu
    have : (U : Matrix n n ℝ)⁻¹ = ((U⁻¹ : (Matrix n n ℝ)ˣ) : Matrix n n ℝ) := by
      rw [Matrix.coe_units_inv]
    exact Matrix.charpoly_units_conj U (P * Q)

/-- Unseeable states can go. Sort the state as (kept part, unseeable part). The unseeable
directions are mapped into themselves by `A` (so `A` has a zero top-right block) and the output
reads nothing from them (so `C` has a zero right block). Then every Markov parameter `C Aᵏ B`,
and so the transfer function, is the same product built from the kept block alone. -/
theorem unseeable_states_drop_out
    {ι₁ ι₂ m p : Type*} [Fintype ι₁] [DecidableEq ι₁] [Fintype ι₂] [DecidableEq ι₂]
    (A₁₁ : Matrix ι₁ ι₁ ℝ) (A₂₁ : Matrix ι₂ ι₁ ℝ) (A₂₂ : Matrix ι₂ ι₂ ℝ)
    (B₁ : Matrix ι₁ m ℝ) (B₂ : Matrix ι₂ m ℝ) (C₁ : Matrix p ι₁ ℝ) (k : ℕ) :
    fromCols C₁ (0 : Matrix p ι₂ ℝ) * (fromBlocks A₁₁ 0 A₂₁ A₂₂) ^ k * fromRows B₁ B₂
      = C₁ * A₁₁ ^ k * B₁ := by
  have h : ∀ j : ℕ, fromCols C₁ (0 : Matrix p ι₂ ℝ) * (fromBlocks A₁₁ 0 A₂₁ A₂₂) ^ j
      = fromCols (C₁ * A₁₁ ^ j) 0 := by
    intro j
    induction j with
    | zero => simp
    | succ j ih =>
      rw [pow_succ, ← Matrix.mul_assoc, ih, fromCols_mul_fromBlocks]
      simp [pow_succ, Matrix.mul_assoc]
  rw [h, fromCols_mul_fromRows]
  simp

/-- Unreachable states can go. Sort the state as (kept part, unreachable part). The reachable
directions are mapped into themselves by `A` (so `A` has a zero bottom-left block) and the input
feeds only them (so `B` has a zero bottom block). Then every Markov parameter `C Aᵏ B`, and so
the transfer function, is the same product built from the kept block alone. -/
theorem unreachable_states_drop_out
    {ι₁ ι₂ m p : Type*} [Fintype ι₁] [DecidableEq ι₁] [Fintype ι₂] [DecidableEq ι₂]
    (A₁₁ : Matrix ι₁ ι₁ ℝ) (A₁₂ : Matrix ι₁ ι₂ ℝ) (A₂₂ : Matrix ι₂ ι₂ ℝ)
    (B₁ : Matrix ι₁ m ℝ) (C₁ : Matrix p ι₁ ℝ) (C₂ : Matrix p ι₂ ℝ) (k : ℕ) :
    fromCols C₁ C₂ * (fromBlocks A₁₁ A₁₂ 0 A₂₂) ^ k * fromRows B₁ (0 : Matrix ι₂ m ℝ)
      = C₁ * A₁₁ ^ k * B₁ := by
  have h : ∀ j : ℕ, (fromBlocks A₁₁ A₁₂ 0 A₂₂) ^ j * fromRows B₁ (0 : Matrix ι₂ m ℝ)
      = fromRows (A₁₁ ^ j * B₁) 0 := by
    intro j
    induction j with
    | zero => simp
    | succ j ih =>
      rw [pow_succ', Matrix.mul_assoc, ih, fromBlocks_mul_fromRows]
      simp [pow_succ', Matrix.mul_assoc]
  rw [Matrix.mul_assoc, h, fromCols_mul_fromRows]
  simp [Matrix.mul_assoc]

/-! The card's room, in exact fractions: capacities 1/10, 1, 1, 50 kW·min/°C; links 1/2, 1/20,
2/5, 1/10 and 1/50 kW/°C. -/

-- Worked numbers, step 1: walls and outside in series, plus windows, leak 1/10 kW/°C in total.
example : ((2 / 5 : ℚ) * (1 / 10)) / (2 / 5 + 1 / 10) + 1 / 50 = 1 / 10 := by norm_num

-- Worked numbers, step 2: the steady gain is 1 / (1/10) = 10 °C/kW.
example : (1 : ℚ) / (1 / 10) = 10 := by norm_num

-- Steady state under 1 kW: pipe 32, radiator 30, air 10, walls 8 °C solve A x + B = 0,
-- so the air settles 10 °C above outside per kW (G(0) = 10 °C/kW).
example :
    !![-(1/2) / (1/10), (1/2) / (1/10), 0, 0;
       1/2, -(1/2 + 1/20), 1/20, 0;
       0, 1/20, -(1/20 + 2/5 + 1/50), 2/5;
       0, 0, (2/5) / 50, -(2/5 + 1/10) / 50] *ᵥ ![32, 30, 10, 8] + ![1 / (1/10), 0, 0, 0]
      = (0 : Fin 4 → ℚ) := by
  ext i; fin_cases i <;> norm_num [mulVec, dotProduct, Fin.sum_univ_four]

#print axioms hankel_singular_values_coordinate_free
#print axioms unseeable_states_drop_out
#print axioms unreachable_states_drop_out
