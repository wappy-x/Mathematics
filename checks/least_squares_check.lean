-- Least squares: a choice of coefficients makes the total squared miss as small as possible exactly when it solves the normal equations A^T A x = A^T b, the squared miss of any other choice is the best one plus a Pythagoras term, and when the ages are not all equal the best straight line is unique and given by the card's cross-multiplied formulas, with the card's four used cars checked exactly.
import Mathlib.Data.Matrix.Mul
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Basic.Real.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.NormNum
import Mathlib

open Matrix

/-! The prices are one column `b : Fin n → ℝ`, one entry per car. The design matrix `A` has one
row per car and one column per unknown (`p` columns; for a line, `p = 2`: the age, then a 1).
`A *ᵥ x` is `A` times the column `x`, which rebuilds the predicted prices, and `Aᵀ` is `A`
transposed. The total squared miss of a choice `x` is the leftover `b - A *ᵥ x` dotted with
itself, `(b - A *ᵥ x) ⬝ᵥ (b - A *ᵥ x)`. -/

/-- Helper: a real vector dotted with itself is never negative. -/
theorem ls_dot_self_nonneg {n : ℕ} (v : Fin n → ℝ) : 0 ≤ v ⬝ᵥ v :=
  Finset.sum_nonneg fun i _ => mul_self_nonneg (v i)

/-- Helper: the expansion of the squared miss of `y` around `x`. -/
theorem ls_expand {n p : ℕ} (A : Matrix (Fin n) (Fin p) ℝ) (b : Fin n → ℝ) (x y : Fin p → ℝ) :
    (b - A *ᵥ y) ⬝ᵥ (b - A *ᵥ y) =
      (b - A *ᵥ x) ⬝ᵥ (b - A *ᵥ x) - 2 * ((Aᵀ *ᵥ b - (Aᵀ * A) *ᵥ x) ⬝ᵥ (y - x)) +
        (A *ᵥ (y - x)) ⬝ᵥ (A *ᵥ (y - x)) := by
  have h1 : b - A *ᵥ y = (b - A *ᵥ x) - A *ᵥ (y - x) := by
    rw [mulVec_sub]; abel
  have h2 : (b - A *ᵥ x) ⬝ᵥ (A *ᵥ (y - x)) = (Aᵀ *ᵥ b - (Aᵀ * A) *ᵥ x) ⬝ᵥ (y - x) := by
    rw [dotProduct_mulVec, ← mulVec_mulVec, ← mulVec_sub, mulVec_transpose]
  rw [h1, ← h2]
  generalize b - A *ᵥ x = u
  generalize A *ᵥ (y - x) = v
  simp only [sub_dotProduct, dotProduct_sub, dotProduct_comm v u]
  ring

/-- Helper: if `0 ≤ -2 t G + t² c` for every real `t`, with `0 ≤ G` and `0 ≤ c`, then `G = 0`. -/
theorem ls_quad_zero (G c : ℝ) (hG : 0 ≤ G) (hc : 0 ≤ c)
    (h : ∀ t : ℝ, 0 ≤ -2 * t * G + t ^ 2 * c) : G = 0 := by
  have hc1 : 0 < c + 1 := by linarith
  have ht := h (G / (c + 1))
  have key : 0 ≤ (c + 1) ^ 2 * (-2 * (G / (c + 1)) * G + (G / (c + 1)) ^ 2 * c) :=
    mul_nonneg (by positivity) ht
  have e : (c + 1) ^ 2 * (-2 * (G / (c + 1)) * G + (G / (c + 1)) ^ 2 * c) = -(G ^ 2 * (c + 2)) := by
    field_simp; ring
  rw [e] at key
  have : G ^ 2 * (c + 2) ≤ 0 := by linarith
  have hG2 : G ^ 2 ≤ 0 := by
    by_contra hneg
    rw [not_le] at hneg
    have : 0 < G ^ 2 * (c + 2) := mul_pos hneg (by linarith)
    linarith
  nlinarith

/-- Helper: the expansion of the squared miss of a line `(m', k')` around `(m, k)`. -/
theorem ls_line_expand {n : ℕ} (age price : Fin n → ℝ) (m k m' k' : ℝ) :
    ∑ i, (price i - (m' * age i + k')) ^ 2 =
      ∑ i, (price i - (m * age i + k)) ^ 2
        - 2 * ((m' - m) * ∑ i, age i * (price i - (m * age i + k))
            + (k' - k) * ∑ i, (price i - (m * age i + k)))
        + ∑ i, ((m' - m) * age i + (k' - k)) ^ 2 := by
  rw [Finset.mul_sum, Finset.mul_sum, ← Finset.sum_add_distrib, Finset.mul_sum,
    ← Finset.sum_sub_distrib, ← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl fun i _ => ?_
  ring

/-- Helper: `n Σ a² − (Σ a)²` is half the sum of all squared differences. -/
theorem ls_det_eq {n : ℕ} (age : Fin n → ℝ) :
    2 * ((n : ℝ) * ∑ i, age i ^ 2 - (∑ i, age i) ^ 2) = ∑ i, ∑ j, (age i - age j) ^ 2 := by
  have e : ∀ i j, (age i - age j) ^ 2 = age i ^ 2 + age j ^ 2 - 2 * (age i * age j) := by
    intro i j; ring
  simp only [e, Finset.sum_sub_distrib, Finset.sum_add_distrib, ← Finset.mul_sum,
    ← Finset.sum_mul, Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
  ring

theorem ls_det_pos {n : ℕ} (age : Fin n → ℝ) (h : ∃ i j, age i ≠ age j) :
    0 < (n : ℝ) * ∑ i, age i ^ 2 - (∑ i, age i) ^ 2 := by
  obtain ⟨i, j, hij⟩ := h
  have hpos : 0 < (age i - age j) ^ 2 := by
    have : age i - age j ≠ 0 := sub_ne_zero.mpr hij
    positivity
  have h1 : (age i - age j) ^ 2 ≤ ∑ j', (age i - age j') ^ 2 :=
    Finset.single_le_sum (f := fun j' => (age i - age j') ^ 2) (fun _ _ => sq_nonneg _)
      (Finset.mem_univ j)
  have h2 : ∑ j', (age i - age j') ^ 2 ≤ ∑ i', ∑ j', (age i' - age j') ^ 2 :=
    Finset.single_le_sum (f := fun i' => ∑ j', (age i' - age j') ^ 2)
      (fun _ _ => Finset.sum_nonneg fun _ _ => sq_nonneg _) (Finset.mem_univ i)
  have := ls_det_eq age
  linarith

/-- Least squares is the normal equations. For any table `A` (any number of rows and columns)
and any prices `b`, a choice `x` scores the smallest total squared miss of every possible choice
exactly when it solves `Aᵀ A x = Aᵀ b`, that is, exactly when the leftover `b - A x` is
perpendicular to every column of `A`. -/
theorem least_squares_iff_normal_equations {n p : ℕ} (A : Matrix (Fin n) (Fin p) ℝ)
    (b : Fin n → ℝ) (x : Fin p → ℝ) :
    (∀ y : Fin p → ℝ, (b - A *ᵥ x) ⬝ᵥ (b - A *ᵥ x) ≤ (b - A *ᵥ y) ⬝ᵥ (b - A *ᵥ y)) ↔
      (Aᵀ * A) *ᵥ x = Aᵀ *ᵥ b := by
  constructor
  · intro hmin
    set g := Aᵀ *ᵥ b - (Aᵀ * A) *ᵥ x with hg
    have hG : g ⬝ᵥ g = 0 := by
      apply ls_quad_zero (g ⬝ᵥ g) ((A *ᵥ g) ⬝ᵥ (A *ᵥ g)) (ls_dot_self_nonneg g)
        (ls_dot_self_nonneg _)
      intro t
      have hy := hmin (x + t • g)
      rw [ls_expand A b x (x + t • g)] at hy
      have hd : x + t • g - x = t • g := by abel
      rw [hd, mulVec_smul, dotProduct_smul, smul_dotProduct, dotProduct_smul, smul_eq_mul,
        smul_eq_mul, smul_eq_mul] at hy
      rw [← hg] at hy
      nlinarith
    have : g = 0 := dotProduct_self_eq_zero.mp hG
    rw [hg] at this
    exact (sub_eq_zero.mp this).symm
  · intro hx y
    rw [ls_expand A b x y, hx, sub_self, zero_dotProduct, mul_zero, sub_zero]
    have := ls_dot_self_nonneg (A *ᵥ (y - x))
    linarith

/-- Squared lengths add, by Pythagoras. If `x` solves the normal equations, then for every other
choice `y` the total squared miss of `y` is the best total squared miss plus the squared length
of `A (y - x)`, the gap between the two sets of predictions. -/
theorem squared_miss_splits_by_pythagoras {n p : ℕ} (A : Matrix (Fin n) (Fin p) ℝ)
    (b : Fin n → ℝ) (x : Fin p → ℝ) (hx : (Aᵀ * A) *ᵥ x = Aᵀ *ᵥ b) (y : Fin p → ℝ) :
    (b - A *ᵥ y) ⬝ᵥ (b - A *ᵥ y) =
      (b - A *ᵥ x) ⬝ᵥ (b - A *ᵥ x) + (A *ᵥ (y - x)) ⬝ᵥ (A *ᵥ (y - x)) := by
  rw [ls_expand A b x y, hx, sub_self, zero_dotProduct, mul_zero, sub_zero]

/-- The best-fit line, in one step. Take `n` cars with ages `age i` and prices `price i`, and
suppose the ages are not all equal. Then a line price = slope × age + intercept has the smallest
total squared miss of all lines exactly when
slope = (n × Σ age·price − Σ age × Σ price) / (n × Σ age² − (Σ age)²) and
intercept = (Σ age² × Σ price − Σ age × Σ age·price) / (n × Σ age² − (Σ age)²).
So the best line exists, is unique, and is the cross-multiplied answer of the normal
equations. -/
theorem best_fit_line_unique_when_ages_differ {n : ℕ} (age price : Fin n → ℝ)
    (h : ∃ i j, age i ≠ age j) (m k : ℝ) :
    (∀ m' k' : ℝ, ∑ i, (price i - (m * age i + k)) ^ 2 ≤ ∑ i, (price i - (m' * age i + k')) ^ 2) ↔
      (m = ((n : ℝ) * ∑ i, age i * price i - (∑ i, age i) * ∑ i, price i) /
            ((n : ℝ) * ∑ i, age i ^ 2 - (∑ i, age i) ^ 2) ∧
        k = ((∑ i, age i ^ 2) * ∑ i, price i - (∑ i, age i) * ∑ i, age i * price i) /
            ((n : ℝ) * ∑ i, age i ^ 2 - (∑ i, age i) ^ 2)) := by
  have hD := ls_det_pos age h
  have hD0 := hD.ne'
  set E1 := ∑ i, age i * (price i - (m * age i + k)) with hE1
  set E0 := ∑ i, (price i - (m * age i + k)) with hE0
  clear_value E1 E0
  have hE1' : E1 = ∑ i, age i * price i - m * ∑ i, age i ^ 2 - k * ∑ i, age i := by
    rw [hE1, Finset.mul_sum, Finset.mul_sum, ← Finset.sum_sub_distrib, ← Finset.sum_sub_distrib]
    exact Finset.sum_congr rfl fun i _ => by ring
  have hE0' : E0 = ∑ i, price i - m * ∑ i, age i - k * n := by
    rw [hE0, Finset.mul_sum, ← Finset.sum_sub_distrib]
    simp only [Finset.sum_sub_distrib, Finset.sum_add_distrib, Finset.sum_const,
      Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
    ring
  have step : (∀ m' k' : ℝ, ∑ i, (price i - (m * age i + k)) ^ 2 ≤
      ∑ i, (price i - (m' * age i + k')) ^ 2) ↔ (E1 = 0 ∧ E0 = 0) := by
    constructor
    · intro hmin
      have hz : E1 ^ 2 + E0 ^ 2 = 0 := by
        apply ls_quad_zero (E1 ^ 2 + E0 ^ 2) (∑ i, (E1 * age i + E0) ^ 2) (by positivity)
          (Finset.sum_nonneg fun _ _ => sq_nonneg _)
        intro t
        have hy := hmin (m + t * E1) (k + t * E0)
        rw [ls_line_expand age price m k (m + t * E1) (k + t * E0)] at hy
        have e1 : m + t * E1 - m = t * E1 := by ring
        have e2 : k + t * E0 - k = t * E0 := by ring
        rw [e1, e2] at hy
        have e3 : ∑ i, (t * E1 * age i + t * E0) ^ 2 = t ^ 2 * ∑ i, (E1 * age i + E0) ^ 2 := by
          rw [Finset.mul_sum]; exact Finset.sum_congr rfl fun i _ => by ring
        rw [e3, ← hE1, ← hE0] at hy
        nlinarith
      constructor <;> nlinarith [sq_nonneg E1, sq_nonneg E0]
    · rintro ⟨h1, h0⟩ m' k'
      rw [ls_line_expand age price m k m' k', ← hE1, ← hE0, h1, h0]
      have := Finset.sum_nonneg (s := Finset.univ)
        (fun i _ => sq_nonneg ((m' - m) * age i + (k' - k)))
      linarith
  rw [step, hE1', hE0']
  constructor
  · rintro ⟨h1, h0⟩
    constructor
    · rw [eq_div_iff hD0]; linear_combination (-(n : ℝ)) * h1 + (∑ i, age i) * h0
    · rw [eq_div_iff hD0]; linear_combination (-(∑ i, age i ^ 2)) * h0 + (∑ i, age i) * h1
  · rintro ⟨hm, hk⟩
    rw [eq_div_iff hD0] at hm hk
    constructor
    · apply mul_left_cancel₀ hD0
      linear_combination (-(∑ i, age i ^ 2)) * hm - (∑ i, age i) * hk
    · apply mul_left_cancel₀ hD0
      linear_combination (-(∑ i, age i)) * hm - (n : ℝ) * hk

-- The four cars: A = [[1, 1], [2, 1], [3, 1], [4, 1]], prices b = (20, 17, 13, 10) in thousands.
-- A^T A = [[30, 10], [10, 4]] and A^T b = (133, 60).
example : (!![(1 : ℚ), 1; 2, 1; 3, 1; 4, 1])ᵀ * !![(1 : ℚ), 1; 2, 1; 3, 1; 4, 1] =
    !![30, 10; 10, 4] := by
  ext i j; fin_cases i <;> fin_cases j <;>
    norm_num [Matrix.mul_apply, Fin.sum_univ_four, Matrix.transpose_apply]
example : (!![(1 : ℚ), 1; 2, 1; 3, 1; 4, 1])ᵀ *ᵥ ![20, 17, 13, 10] = ![133, 60] := by
  ext i; fin_cases i <;>
    norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_four, Matrix.transpose_apply]
-- Determinant 30 × 4 − 10 × 10 = 20.
example : Matrix.det !![(30 : ℚ), 10; 10, 4] = 20 := by norm_num [Matrix.det_fin_two_of]
-- Slope (133 × 4 − 10 × 60) / 20 = −17/5 (the card's −3.4);
-- intercept (30 × 60 − 10 × 133) / 20 = 47/2 (the card's 23.5).
example : ((133 : ℚ) * 4 - 10 * 60) / 20 = -17/5 ∧ ((30 : ℚ) * 60 - 10 * 133) / 20 = 47/2 := by
  norm_num
-- (−17/5, 47/2) solves the normal equations: 30 m + 10 k = 133 and 10 m + 4 k = 60.
example : !![(30 : ℚ), 10; 10, 4] *ᵥ ![-17/5, 47/2] = ![133, 60] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
-- Fitted prices 20.1, 16.7, 13.3, 9.9, written exactly.
example : !![(1 : ℚ), 1; 2, 1; 3, 1; 4, 1] *ᵥ ![-17/5, 47/2] = ![201/10, 167/10, 133/10, 99/10] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
-- Leftovers −0.1, 0.3, −0.3, 0.1, dotted with both columns give 0, and their squares add to 0.2.
example : (![-1/10, 3/10, -3/10, 1/10] : Fin 4 → ℚ) ⬝ᵥ ![1, 2, 3, 4] = 0 ∧
    (![-1/10, 3/10, -3/10, 1/10] : Fin 4 → ℚ) ⬝ᵥ ![1, 1, 1, 1] = 0 := by
  norm_num [dotProduct, Fin.sum_univ_four]
example : ∑ i : Fin 4, ((![20, 17, 13, 10] : Fin 4 → ℚ) i -
    (-17/5 * (![1, 2, 3, 4] : Fin 4 → ℚ) i + 47/2)) ^ 2 = 1/5 := by
  norm_num [Fin.sum_univ_four]
-- The other road: average age 5/2, average price 15; Σ (age − 5/2)(price − 15) = −17,
-- Σ (age − 5/2)² = 5, slope −17/5, intercept 15 + 17/2 = 47/2.
example : ∑ i : Fin 4, ((![1, 2, 3, 4] : Fin 4 → ℚ) i - 5/2) *
    ((![20, 17, 13, 10] : Fin 4 → ℚ) i - 15) = -17 ∧
    ∑ i : Fin 4, ((![1, 2, 3, 4] : Fin 4 → ℚ) i - 5/2) ^ 2 = 5 ∧
    (15 : ℚ) - (-17/5) * (5/2) = 47/2 := by
  norm_num [Fin.sum_univ_four]
-- Mistake 1, no column of ones: slope 133/30 (4.4333), squared miss 11051/30 (368.3667).
example : ∑ i : Fin 4, ((![20, 17, 13, 10] : Fin 4 → ℚ) i -
    133/30 * (![1, 2, 3, 4] : Fin 4 → ℚ) i) ^ 2 = 11051/30 := by
  norm_num [Fin.sum_univ_four]
-- Mistake 2, first and last car only: slope −10/3 (−3.3333), squared miss 2/9 (0.2222).
example : ∑ i : Fin 4, ((![20, 17, 13, 10] : Fin 4 → ℚ) i -
    (-10/3 * (![1, 2, 3, 4] : Fin 4 → ℚ) i + 70/3)) ^ 2 = 2/9 := by
  norm_num [Fin.sum_univ_four]
-- Mistake 3, adding misses without squaring: price = 27.5 − 5 × age also sums to 0,
-- but its squared miss is 13.
example : ∑ i : Fin 4, ((![20, 17, 13, 10] : Fin 4 → ℚ) i -
    (-5 * (![1, 2, 3, 4] : Fin 4 → ℚ) i + 55/2)) = 0 ∧
    ∑ i : Fin 4, ((![20, 17, 13, 10] : Fin 4 → ℚ) i -
    (-5 * (![1, 2, 3, 4] : Fin 4 → ℚ) i + 55/2)) ^ 2 = 13 := by
  norm_num [Fin.sum_univ_four]
-- Second lot, prices 21, 18, 12, 9: A^T b = (129, 60), slope −21/5, intercept 51/2,
-- squared miss 9/5 (1.8).
example : !![(30 : ℚ), 10; 10, 4] *ᵥ ![-21/5, 51/2] = ![129, 60] ∧
    (!![(1 : ℚ), 1; 2, 1; 3, 1; 4, 1])ᵀ *ᵥ ![21, 18, 12, 9] = ![129, 60] := by
  constructor <;> ext i <;> fin_cases i <;>
    norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two, Fin.sum_univ_four,
      Matrix.transpose_apply]
example : ∑ i : Fin 4, ((![21, 18, 12, 9] : Fin 4 → ℚ) i -
    (-21/5 * (![1, 2, 3, 4] : Fin 4 → ℚ) i + 51/2)) ^ 2 = 9/5 := by
  norm_num [Fin.sum_univ_four]
-- Every car aged 2: A^T A = [[16, 8], [8, 4]], determinant 16 × 4 − 8 × 8 = 0, no unique line.
example : Matrix.det !![(16 : ℚ), 8; 8, 4] = 0 := by norm_num [Matrix.det_fin_two_of]

#print axioms ls_dot_self_nonneg
#print axioms ls_expand
#print axioms ls_quad_zero
#print axioms ls_line_expand
#print axioms ls_det_eq
#print axioms ls_det_pos
#print axioms least_squares_iff_normal_equations
#print axioms squared_miss_splits_by_pythagoras
#print axioms best_fit_line_unique_when_ages_differ
