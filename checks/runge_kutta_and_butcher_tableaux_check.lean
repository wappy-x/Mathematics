-- Runge-Kutta: an explicit tableau with s stages always fails the order condition of the chain tree with s + 1 nodes, so its order is at most s, and the card's tableaux meet exactly the tree conditions it says.
import Mathlib.Data.Matrix.Mul
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Basic.Real.Basic
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity

/-! A Butcher tableau with `s` stages is a matrix `A : Matrix (Fin s) (Fin s) ℝ` of blends
`a_ij`, a column `c` of reading times and a row `b` of weights. Stages are numbered
`0, …, s - 1` here (the card numbers them from 1).
The order condition of a rooted tree reads `b ⬝ᵥ Φ(tree) = 1 / γ(tree)`. For the chain of
`n` nodes, `Φ = A ^ (n - 2) *ᵥ c` and `γ = n!`; for the chain with `s + 1` nodes the
condition is `b ⬝ᵥ (A ^ (s - 1) *ᵥ c) = 1 / (s + 1)!`. -/

open Matrix

/-- Powers of a strictly lower-triangular matrix: an entry `(A ^ k) i j` can be nonzero
only when `j + k ≤ i`. -/
theorem strictLower_pow_entry_eq_zero (s : ℕ) (A : Matrix (Fin s) (Fin s) ℝ)
    (hA : ∀ i j, i ≤ j → A i j = 0) (k : ℕ) :
    ∀ i j : Fin s, (A ^ k) i j ≠ 0 → (j : ℕ) + k ≤ i := by
  induction k with
  | zero =>
    intro i j h
    rw [pow_zero] at h
    by_cases hij : i = j
    · subst hij; simp
    · exact absurd (Matrix.one_apply_ne hij) h
  | succ k ih =>
    intro i j h
    rw [pow_succ, Matrix.mul_apply] at h
    obtain ⟨l, -, hl⟩ := Finset.exists_ne_zero_of_sum_ne_zero h
    have h1 : (A ^ k) i l ≠ 0 := left_ne_zero_of_mul hl
    have h2 : A l j ≠ 0 := right_ne_zero_of_mul hl
    have hlj : j < l := by
      by_contra hc
      exact h2 (hA l j (not_lt.mp hc))
    have := ih i l h1
    have hlj' : (j : ℕ) < l := hlj
    omega

#print axioms strictLower_pow_entry_eq_zero

/-- Step 5 of the card: `s` stages never reach order `s + 1`. If the tableau is explicit
(strictly lower-triangular: `a_ij = 0` whenever `j` is not an earlier stage than `i`) and
each `c_i` is its row sum `∑_j a_ij`, then the chain tree with `s + 1` nodes fails its
order condition: `b^T A^(s-1) c` is `0`, never `1 / (s + 1)!`. -/
theorem explicit_tableau_misses_chain_condition (s : ℕ) (A : Matrix (Fin s) (Fin s) ℝ)
    (b c : Fin s → ℝ) (hA : ∀ i j, i ≤ j → A i j = 0) (hc : ∀ i, c i = ∑ j, A i j) :
    b ⬝ᵥ (A ^ (s - 1) *ᵥ c) ≠ 1 / ((s + 1).factorial : ℝ) := by
  have hpos : (0 : ℝ) < 1 / ((s + 1).factorial : ℝ) := by
    have : (0 : ℝ) < ((s + 1).factorial : ℝ) := by exact_mod_cast Nat.factorial_pos _
    positivity
  have hzero : b ⬝ᵥ (A ^ (s - 1) *ᵥ c) = 0 := by
    rcases Nat.eq_zero_or_pos s with hs | hs
    · subst hs
      simp [dotProduct]
    · have hcv : c = A *ᵥ (fun _ => (1 : ℝ)) := by
        funext i
        rw [hc i]
        simp [mulVec, dotProduct]
      have hAs : A ^ s = 0 := by
        ext i j
        by_contra h
        have := strictLower_pow_entry_eq_zero s A hA s i j h
        have hi := i.isLt
        omega
      rw [hcv, mulVec_mulVec, pow_sub_one_mul (Nat.pos_iff_ne_zero.mp hs), hAs]
      simp
  rw [hzero]
  exact ne_of_lt hpos

/-- Step 4 of the card: the three-stage methods of order 3. Pick reading times `c2`, `c3`
with `c2 ≠ 0`, `c3 ≠ 0`, `c2 ≠ c3` and `c2 ≠ 2/3`. Then
`b2 = (2 - 3 c3) / (6 c2 (c2 - c3))`, `b3 = (2 - 3 c2) / (6 c3 (c3 - c2))`,
`b1 = 1 - b2 - b3` and `a32 = 1 / (6 b3 c2)` satisfy the four order-3 conditions
(trees 1 to 4): `∑ b_i = 1`, `∑ b_i c_i = 1/2`, `∑ b_i c_i^2 = 1/3`, `b3 a32 c2 = 1/6`. -/
theorem three_stage_order_three_family (c2 c3 : ℝ) (h2 : c2 ≠ 0) (h3 : c3 ≠ 0)
    (h23 : c2 ≠ c3) (h2' : c2 ≠ 2 / 3) :
    let b2 := (2 - 3 * c3) / (6 * c2 * (c2 - c3))
    let b3 := (2 - 3 * c2) / (6 * c3 * (c3 - c2))
    let b1 := 1 - b2 - b3
    let a32 := 1 / (6 * b3 * c2)
    b1 + b2 + b3 = 1 ∧ b2 * c2 + b3 * c3 = 1 / 2 ∧
      b2 * c2 ^ 2 + b3 * c3 ^ 2 = 1 / 3 ∧ b3 * a32 * c2 = 1 / 6 := by
  intro b2 b3 b1 a32
  have hd : c2 - c3 ≠ 0 := sub_ne_zero.mpr h23
  have hd' : c3 - c2 ≠ 0 := sub_ne_zero.mpr (Ne.symm h23)
  have hn : 2 - 3 * c2 ≠ 0 := by
    intro h
    apply h2'
    linarith
  have hb3 : b3 ≠ 0 := by
    simp only [b3]
    exact div_ne_zero hn (by positivity)
  refine ⟨by simp only [b1]; ring, ?_, ?_, ?_⟩
  · simp only [b2, b3]
    field_simp
    ring
  · simp only [b2, b3]
    field_simp
    ring
  · simp only [a32]
    field_simp

/-! Worked examples from the card, in exact fractions. -/

-- Kutta's choice c2 = 1/2, c3 = 1 gives b = (1/6, 2/3, 1/6), a32 = 2, a31 = c3 - a32 = -1.
example : (2 - 3 * (1 : ℝ)) / (6 * (1 / 2) * (1 / 2 - 1)) = 2 / 3 ∧
    (2 - 3 * (1 / 2 : ℝ)) / (6 * 1 * (1 - 1 / 2)) = 1 / 6 ∧
    1 / (6 * (1 / 6 : ℝ) * (1 / 2)) = 2 ∧ (1 : ℝ) - 2 = -1 := by norm_num

-- Heun's third-order choice c2 = 1/3, c3 = 2/3 gives b = (1/4, 0, 3/4), a32 = 2/3, a31 = 0.
example : (2 - 3 * (2 / 3 : ℝ)) / (6 * (1 / 3) * (1 / 3 - 2 / 3)) = 0 ∧
    (2 - 3 * (1 / 3 : ℝ)) / (6 * (2 / 3) * (2 / 3 - 1 / 3)) = 3 / 4 ∧
    1 / (6 * (3 / 4 : ℝ) * (1 / 3)) = 2 / 3 := by norm_num

-- RK4's tableau meets all eight order-4 tree conditions (Step 3's table).
example :
    let A : Matrix (Fin 4) (Fin 4) ℝ := !![0, 0, 0, 0; 1/2, 0, 0, 0; 0, 1/2, 0, 0; 0, 0, 1, 0]
    let c : Fin 4 → ℝ := ![0, 1/2, 1/2, 1]
    let b : Fin 4 → ℝ := ![1/6, 1/3, 1/3, 1/6]
    (∑ i, b i = 1) ∧ b ⬝ᵥ c = 1/2 ∧ (∑ i, b i * c i ^ 2) = 1/3 ∧ b ⬝ᵥ (A *ᵥ c) = 1/6 ∧
    (∑ i, b i * c i ^ 3) = 1/4 ∧ (∑ i, b i * c i * (A *ᵥ c) i) = 1/8 ∧
    b ⬝ᵥ (A *ᵥ fun i => c i ^ 2) = 1/12 ∧ b ⬝ᵥ (A *ᵥ (A *ᵥ c)) = 1/24 := by
  intro A c b
  simp only [A, c, b, dotProduct, mulVec, Fin.sum_univ_four]
  norm_num

-- Kutta's tableau meets trees 1 to 4, and three stages give the chain of 4 exactly 0, not 1/24.
example :
    let A : Matrix (Fin 3) (Fin 3) ℝ := !![0, 0, 0; 1/2, 0, 0; -1, 2, 0]
    let c : Fin 3 → ℝ := ![0, 1/2, 1]
    let b : Fin 3 → ℝ := ![1/6, 2/3, 1/6]
    (∑ i, b i = 1) ∧ b ⬝ᵥ c = 1/2 ∧ (∑ i, b i * c i ^ 2) = 1/3 ∧ b ⬝ᵥ (A *ᵥ c) = 1/6 ∧
    b ⬝ᵥ (A *ᵥ (A *ᵥ c)) = 0 := by
  intro A c b
  simp only [A, c, b, dotProduct, mulVec, Fin.sum_univ_three]
  norm_num

-- What breaks: Kutta's weights with a31 = 0, a32 = 1 give tree 4 the value 1/12, not 1/6.
example :
    let A : Matrix (Fin 3) (Fin 3) ℝ := !![0, 0, 0; 1/2, 0, 0; 0, 1, 0]
    let c : Fin 3 → ℝ := ![0, 1/2, 1]
    let b : Fin 3 → ℝ := ![1/6, 2/3, 1/6]
    b ⬝ᵥ (A *ᵥ c) = 1/12 := by
  intro A c b
  simp only [A, c, b, dotProduct, mulVec, Fin.sum_univ_three]
  norm_num

-- What breaks: equal weights 1/3 pass ∑ b_i c_i = 1/2 but give ∑ b_i c_i^2 = 5/12, not 1/3.
example :
    let c : Fin 3 → ℝ := ![0, 1/2, 1]
    let b : Fin 3 → ℝ := ![1/3, 1/3, 1/3]
    b ⬝ᵥ c = 1/2 ∧ (∑ i, b i * c i ^ 2) = 5/12 := by
  intro c b
  simp only [c, b, dotProduct, Fin.sum_univ_three]
  norm_num

-- Step 6: the five-stage barrier's right side, 1/24 - 1/30 = 1/120.
example : (1 : ℚ) / 24 - 1 / 30 = 1 / 120 := by norm_num

-- Step 6's count: s(s+1)/2 free numbers for s = 1..6.
example : (List.range 6).map (fun k => (k + 1) * (k + 2) / 2) = [1, 3, 6, 10, 15, 21] := by decide

#print axioms explicit_tableau_misses_chain_condition
#print axioms three_stage_order_three_family
