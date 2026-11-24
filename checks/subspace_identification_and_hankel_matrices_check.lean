-- Subspace identification: for a fixed linear model x(k+1) = A x(k) + B u(k), y(k) = C x(k), the Hankel matrix of its impulse response h(k) = C A^(k-1) B is the observability matrix times the controllability matrix, so when every state is steerable and visible and the matrix is at least as big as the order n, its rank is exactly n, and no model with fewer states gives the same response.
import Mathlib.LinearAlgebra.Matrix.Rank
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum

open Matrix

/-- The `m × m` Hankel matrix of a response `h`: its entry in row `i`, column `j` (counted from 0)
is `h (i + j + 1)`, so each anti-diagonal holds one sample, from `h 1` in the top-left corner. -/
def hankel (h : ℕ → ℝ) (m : ℕ) : Matrix (Fin m) (Fin m) ℝ :=
  Matrix.of fun i j => h ((i : ℕ) + (j : ℕ) + 1)

/-- The same matrix shifted one step: entry `(i, j)` is `h (i + j + 2)`, from `h 2` to `h (2m)`. -/
def shiftedHankel (h : ℕ → ℝ) (m : ℕ) : Matrix (Fin m) (Fin m) ℝ :=
  Matrix.of fun i j => h ((i : ℕ) + (j : ℕ) + 2)

/-- The observability matrix with `m` rows `C, CA, CA², …, CA^(m-1)`. -/
def obsMat {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (C : Fin n → ℝ) (m : ℕ) :
    Matrix (Fin m) (Fin n) ℝ :=
  Matrix.of fun i k => (C ᵥ* (A ^ (i : ℕ))) k

/-- The controllability matrix with `m` columns `B, AB, A²B, …, A^(m-1)B`. -/
def ctrlMat {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (B : Fin n → ℝ) (m : ℕ) :
    Matrix (Fin n) (Fin m) ℝ :=
  Matrix.of fun k j => ((A ^ (j : ℕ)) *ᵥ B) k

/-- Helper: the Hankel factorization `H₀ = 𝒪 𝒞` and `H₁ = 𝒪 A 𝒞`. -/
theorem hankel_factor_aux {n m : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (B C : Fin n → ℝ)
    (h : ℕ → ℝ) (hh : ∀ k, 1 ≤ k → h k = C ⬝ᵥ ((A ^ (k - 1)) *ᵥ B)) :
    hankel h m = obsMat A C m * ctrlMat A B m ∧
      shiftedHankel h m = obsMat A C m * A * ctrlMat A B m := by
  constructor
  · ext i j
    have e : ∀ x : Fin n, (obsMat A C m) i x * (ctrlMat A B m) x j
        = (C ᵥ* (A ^ (i : ℕ))) x * ((A ^ (j : ℕ)) *ᵥ B) x := fun _ => rfl
    rw [Matrix.mul_apply, Finset.sum_congr rfl (fun x _ => e x), ← dotProduct,
      ← dotProduct_mulVec, mulVec_mulVec, ← pow_add]
    simp only [hankel, of_apply]
    rw [hh _ (by omega)]
    congr 3
  · ext i j
    have e : ∀ x : Fin n, (obsMat A C m * A) i x * (ctrlMat A B m) x j
        = (C ᵥ* (A ^ ((i : ℕ) + 1))) x * ((A ^ (j : ℕ)) *ᵥ B) x := by
      intro x
      congr 1
      simp only [Matrix.mul_apply, obsMat, of_apply, pow_succ, ← vecMul_vecMul]
      rfl
    rw [Matrix.mul_apply, Finset.sum_congr rfl (fun x _ => e x), ← dotProduct,
      ← dotProduct_mulVec, mulVec_mulVec, ← pow_add]
    simp only [shiftedHankel, of_apply]
    rw [hh _ (by omega)]
    congr 3
    omega

/-- Helper: the `n × n` Hankel matrix of a steerable, visible `n`-state model has rank `n`. -/
theorem hankel_rank_self_aux {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (B C : Fin n → ℝ)
    (h : ℕ → ℝ) (hh : ∀ k, 1 ≤ k → h k = C ⬝ᵥ ((A ^ (k - 1)) *ᵥ B))
    (hc : (ctrlMat A B n).rank = n) (ho : (obsMat A C n).rank = n) :
    (hankel h n).rank = n := by
  rw [(hankel_factor_aux A B C h hh).1]
  have h1 := rank_mul_ge (obsMat A C n) (ctrlMat A B n)
  have h2 := rank_mul_le_right (obsMat A C n) (ctrlMat A B n)
  simp only [Fintype.card_fin] at h1
  omega

#print axioms hankel_factor_aux
#print axioms hankel_rank_self_aux

/-- The Hankel matrix's rank is the model's order. Take a fixed (linear, time-invariant) model
with `n` states whose impulse response is `h k = C A^(k-1) B` for `k = 1, 2, 3, …`. If every
state is steerable (the controllability matrix `[B AB … A^(n-1)B]` has rank `n`) and visible (the
observability matrix with rows `C, CA, …, CA^(n-1)` has rank `n`), then every `m × m` Hankel
matrix of the response with `m ≥ n` has rank exactly `n`. -/
theorem hankel_rank_eq_order {n m : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (B C : Fin n → ℝ)
    (h : ℕ → ℝ) (hh : ∀ k, 1 ≤ k → h k = C ⬝ᵥ ((A ^ (k - 1)) *ᵥ B)) (hm : n ≤ m)
    (hc : (ctrlMat A B n).rank = n) (ho : (obsMat A C n).rank = n) :
    (hankel h m).rank = n := by
  have hsub : hankel h n = (hankel h m).submatrix (Fin.castLE hm) (Fin.castLE hm) := by
    ext i j; rfl
  have h1 := rank_submatrix_le (hankel h m) (Fin.castLE hm) (Fin.castLE hm)
  rw [← hsub, hankel_rank_self_aux A B C h hh hc ho] at h1
  rw [(hankel_factor_aux A B C h hh).1] at h1 ⊢
  have h2 := rank_mul_le_right (obsMat A C m) (ctrlMat A B m)
  have h3 := rank_le_height (ctrlMat A B m)
  omega

/-- The Hankel matrix factors through the state: `H₀ = 𝒪 𝒞` (observability matrix times
controllability matrix) and the shifted matrix is `H₁ = 𝒪 A 𝒞`, for any model with
`h k = C A^(k-1) B` and any size `m`. -/
theorem hankel_eq_obs_mul_ctrl {n m : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (B C : Fin n → ℝ)
    (h : ℕ → ℝ) (hh : ∀ k, 1 ≤ k → h k = C ⬝ᵥ ((A ^ (k - 1)) *ᵥ B)) :
    hankel h m = obsMat A C m * ctrlMat A B m ∧
      shiftedHankel h m = obsMat A C m * A * ctrlMat A B m := by
  exact hankel_factor_aux A B C h hh

/-- The order is the smallest model's size. If a model with `n` states, every state steerable
and visible, has response `h`, then any other fixed linear model `(A', B', C')` with `n'` states
that gives the same response `h k = C' A'^(k-1) B'` has at least `n` states. -/
theorem order_le_of_same_response {n n' : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (B C : Fin n → ℝ)
    (A' : Matrix (Fin n') (Fin n') ℝ) (B' C' : Fin n' → ℝ) (h : ℕ → ℝ)
    (hh : ∀ k, 1 ≤ k → h k = C ⬝ᵥ ((A ^ (k - 1)) *ᵥ B))
    (hh' : ∀ k, 1 ≤ k → h k = C' ⬝ᵥ ((A' ^ (k - 1)) *ᵥ B'))
    (hc : (ctrlMat A B n).rank = n) (ho : (obsMat A C n).rank = n) :
    n ≤ n' := by
  have h1 := hankel_rank_self_aux A B C h hh hc ho
  rw [(hankel_factor_aux A' B' C' h hh').1] at h1
  have h2 := rank_mul_le_right (obsMat A' C' n) (ctrlMat A' B' n)
  have h3 := rank_le_height (ctrlMat A' B' n)
  omega

/-! ### The card's radiator panel, exactly: `h k = 0.8^k + 0.5^k` °C per valve-minute -/

-- Worked numbers, step 1: h₁ … h₆ = 1.3, 0.89, 0.637, 0.4721, 0.35893, 0.277769, and h₇ = 0.2175277
-- exactly (the card rounds it to 0.217528).
example : ((4 : ℚ) / 5) ^ 1 + (1 / 2) ^ 1 = 13 / 10 := by norm_num
example : ((4 : ℚ) / 5) ^ 2 + (1 / 2) ^ 2 = 89 / 100 := by norm_num
example : ((4 : ℚ) / 5) ^ 3 + (1 / 2) ^ 3 = 637 / 1000 := by norm_num
example : ((4 : ℚ) / 5) ^ 4 + (1 / 2) ^ 4 = 4721 / 10000 := by norm_num
example : ((4 : ℚ) / 5) ^ 5 + (1 / 2) ^ 5 = 35893 / 100000 := by norm_num
example : ((4 : ℚ) / 5) ^ 6 + (1 / 2) ^ 6 = 277769 / 1000000 := by norm_num
example : ((4 : ℚ) / 5) ^ 7 + (1 / 2) ^ 7 = 2175277 / 10000000 := by norm_num

-- Step 3: the top-left 2 × 2 minor h₁h₃ − h₂² = 1.3 × 0.637 − 0.89² = 0.036, not zero (rank ≥ 2).
example : (13 / 10 : ℚ) * (637 / 1000) - (89 / 100) ^ 2 = 36 / 1000 := by norm_num

-- Step 4: the recurrence h₅ = 1.3 h₄ − 0.4 h₃ checks on the unused sample (rank ≤ 2).
example : (35893 / 100000 : ℚ) = 13 / 10 * (4721 / 10000) - 2 / 5 * (637 / 1000) := by norm_num

-- Step 5: the poles 0.8 and 0.5 are the roots of z² − 1.3 z + 0.4.
example : ((4 : ℚ) / 5) ^ 2 - 13 / 10 * (4 / 5) + 2 / 5 = 0 := by norm_num
example : ((1 : ℚ) / 2) ^ 2 - 13 / 10 * (1 / 2) + 2 / 5 = 0 := by norm_num

-- Exact integer Hankel matrix 10^(i+j-1) h(i+j-1) = 8^(i+j-1) + 5^(i+j-1): its 2 × 2 minor is 360
-- (0.036 × 10⁴), not zero.
example : (8 ^ 1 + 5 ^ 1 : ℤ) * (8 ^ 3 + 5 ^ 3) - (8 ^ 2 + 5 ^ 2) ^ 2 = 360 := by norm_num

#print axioms hankel_rank_eq_order
#print axioms hankel_eq_obs_mul_ctrl
#print axioms order_le_of_same_response
