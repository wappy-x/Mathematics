-- Incomplete factorisations: for an M-matrix, incomplete elimination on any pattern that holds the diagonal has every pivot positive and at least the exact pivot, and the incomplete factors reproduce the matrix exactly on the pattern.
import Mathlib.Data.Matrix.Mul
import Mathlib.Basic.Real.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Data.Fin.Tuple.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Algebra.Order.BigOperators.Group.Finset

open Matrix

/-! ### How the card's objects are written here

The matrix `A` is a real `n × n` matrix, `A : Matrix (Fin n) (Fin n) ℝ`, with unknowns numbered
from `0`. The pattern of kept positions is `P : Fin n → Fin n → Prop`; `P i j` means position
`(i, j)` is kept.

Mathlib has no M-matrix or incomplete factorisation, so they are written out here as the card
defines them.

* `IsMMatrix A` is the card's Step 3 definition: every off-diagonal entry is zero or negative,
  and some vector `x` with every entry positive gives `A x` with every entry positive.
* `iluStep P A` is one step of incomplete elimination (the card's update rule). Unknown `0` is
  removed, and entry `(i, j)` of what is left becomes `a_ij - a_i0 a_0j / a_00` only when
  `(i, j)` is in the pattern; outside the pattern the update is skipped.
* `iluPivots n P A` lists the pivots `u_00, u_11, ...`: the first is `a_00`, the rest are the
  pivots of the block `iluStep P A` with the pattern cut down to it.
* `iluL n P A` (unit lower) and `iluU n P A` (upper) are the incomplete factors: row `0` of `U`
  is row `0` of `A`, column `0` of `L` below the diagonal is `a_i0 / a_00`, and the rest are the
  factors of the block that is left.
* The exact factorisation is the same rule with every position kept, `P = fun _ _ => True`. -/

/-- The card's M-matrix (Step 3): off-diagonal entries zero or negative, and some vector with
every entry positive is sent to a vector with every entry positive. -/
def IsMMatrix {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) : Prop :=
  (∀ i j, i ≠ j → A i j ≤ 0) ∧ ∃ x : Fin n → ℝ, (∀ i, 0 < x i) ∧ ∀ i, 0 < (A *ᵥ x) i

open Classical in
/-- One step of incomplete elimination with pattern `P`: remove unknown `0`, and update entry
`(i, j)` of the rest by `a_ij ← a_ij - a_i0 a_0j / a_00` only when `(i, j)` is kept. -/
noncomputable def iluStep {n : ℕ} (P : Fin (n + 1) → Fin (n + 1) → Prop)
    (A : Matrix (Fin (n + 1)) (Fin (n + 1)) ℝ) : Matrix (Fin n) (Fin n) ℝ :=
  Matrix.of fun i j =>
    if P i.succ j.succ then A i.succ j.succ - A i.succ 0 * A 0 j.succ / A 0 0
    else A i.succ j.succ

/-- The pivots `u_00, u_11, ...` of incomplete elimination with pattern `P`. -/
noncomputable def iluPivots : (n : ℕ) → (Fin n → Fin n → Prop) →
    Matrix (Fin n) (Fin n) ℝ → Fin n → ℝ
  | 0, _, _ => Fin.elim0
  | n + 1, P, A =>
      Fin.cons (A 0 0) (iluPivots n (fun i j => P i.succ j.succ) (iluStep P A))

/-- The unit lower incomplete factor `L`. -/
noncomputable def iluL : (n : ℕ) → (Fin n → Fin n → Prop) →
    Matrix (Fin n) (Fin n) ℝ → Matrix (Fin n) (Fin n) ℝ
  | 0, _, _ => 0
  | n + 1, P, A =>
      Matrix.of fun i j =>
        Fin.cons (α := fun _ => ℝ) (Fin.cons (α := fun _ => ℝ) 1 (fun _ => 0) j)
          (fun i' => Fin.cons (α := fun _ => ℝ) (A i'.succ 0 / A 0 0)
            (fun j' => iluL n (fun a b => P a.succ b.succ) (iluStep P A) i' j') j) i

/-- The upper incomplete factor `U`, whose diagonal holds the pivots. -/
noncomputable def iluU : (n : ℕ) → (Fin n → Fin n → Prop) →
    Matrix (Fin n) (Fin n) ℝ → Matrix (Fin n) (Fin n) ℝ
  | 0, _, _ => 0
  | n + 1, P, A =>
      Matrix.of fun i j =>
        Fin.cons (α := fun _ => ℝ) (A 0 j)
          (fun i' => Fin.cons (α := fun _ => ℝ) 0
            (fun j' => iluU n (fun a b => P a.succ b.succ) (iluStep P A) i' j') j) i


/-- An M-matrix has a positive first diagonal entry. -/
theorem isMMatrix_zero_pos {n : ℕ} (A : Matrix (Fin (n + 1)) (Fin (n + 1)) ℝ)
    (hA : IsMMatrix A) : 0 < A 0 0 := by
  obtain ⟨hZ, x, hx, hAx⟩ := hA
  have h0 := hAx 0
  simp only [mulVec, dotProduct, Fin.sum_univ_succ] at h0
  have hs : ∑ j : Fin n, A 0 j.succ * x j.succ ≤ 0 :=
    Finset.sum_nonpos fun j _ =>
      mul_nonpos_of_nonpos_of_nonneg (hZ 0 j.succ (Fin.succ_ne_zero j).symm) (hx _).le
  have : 0 < A 0 0 * x 0 := by linarith
  exact pos_of_mul_pos_left this (hx 0).le

/-- The exact Schur complement times the cut-down vector. -/
theorem schur_mulVec {n : ℕ} (A : Matrix (Fin (n + 1)) (Fin (n + 1)) ℝ) (h0 : A 0 0 ≠ 0)
    (x : Fin (n + 1) → ℝ) (i : Fin n) :
    ∑ j : Fin n, (A i.succ j.succ - A i.succ 0 * A 0 j.succ / A 0 0) * x j.succ =
      (A *ᵥ x) i.succ - A i.succ 0 / A 0 0 * (A *ᵥ x) 0 := by
  simp only [mulVec, dotProduct, Fin.sum_univ_succ, sub_mul, Finset.sum_sub_distrib]
  rw [mul_add, Finset.mul_sum]
  have : ∀ j : Fin n, A i.succ 0 * A 0 j.succ / A 0 0 * x j.succ =
      A i.succ 0 / A 0 0 * (A 0 j.succ * x j.succ) := fun j => by ring
  simp only [this]
  field_simp
  ring

/-- Entrywise, one incomplete step of an M-matrix with any pattern is at least the exact step. -/
theorem schur_le_iluStep {n : ℕ} (P : Fin (n + 1) → Fin (n + 1) → Prop)
    (A : Matrix (Fin (n + 1)) (Fin (n + 1)) ℝ) (hZ : ∀ i j, i ≠ j → A i j ≤ 0)
    (h0 : 0 < A 0 0) (i j : Fin n) :
    A i.succ j.succ - A i.succ 0 * A 0 j.succ / A 0 0 ≤ iluStep P A i j := by
  have h1 := hZ i.succ 0 (Fin.succ_ne_zero i)
  have h2 := hZ 0 j.succ (Fin.succ_ne_zero j).symm
  have : 0 ≤ A i.succ 0 * A 0 j.succ / A 0 0 :=
    div_nonneg (mul_nonneg_of_nonpos_of_nonpos h1 h2) h0.le
  simp only [iluStep, of_apply]
  split_ifs <;> linarith

/-- One incomplete step keeps the off-diagonal entries zero or negative. -/
theorem iluStep_offdiag {n : ℕ} (P : Fin (n + 1) → Fin (n + 1) → Prop)
    (A : Matrix (Fin (n + 1)) (Fin (n + 1)) ℝ) (hZ : ∀ i j, i ≠ j → A i j ≤ 0)
    (h0 : 0 < A 0 0) : ∀ i j, i ≠ j → iluStep P A i j ≤ 0 := by
  intro i j hij
  have h1 := hZ i.succ 0 (Fin.succ_ne_zero i)
  have h2 := hZ 0 j.succ (Fin.succ_ne_zero j).symm
  have h3 := hZ i.succ j.succ (fun h => hij (Fin.succ_injective _ h))
  have : 0 ≤ A i.succ 0 * A 0 j.succ / A 0 0 :=
    div_nonneg (mul_nonneg_of_nonpos_of_nonpos h1 h2) h0.le
  simp only [iluStep, of_apply]
  split_ifs <;> linarith

/-- One incomplete step of an M-matrix, with any pattern, is again an M-matrix. -/
theorem iluStep_isMMatrix {n : ℕ} (P : Fin (n + 1) → Fin (n + 1) → Prop)
    (A : Matrix (Fin (n + 1)) (Fin (n + 1)) ℝ) (hA : IsMMatrix A) :
    IsMMatrix (iluStep P A) := by
  have h0 := isMMatrix_zero_pos A hA
  obtain ⟨hZ, x, hx, hAx⟩ := hA
  refine ⟨iluStep_offdiag P A hZ h0, fun i => x i.succ, fun i => hx _, fun i => ?_⟩
  have key := schur_mulVec A h0.ne' x i
  have hle : ∑ j : Fin n, (A i.succ j.succ - A i.succ 0 * A 0 j.succ / A 0 0) * x j.succ ≤
      ∑ j : Fin n, iluStep P A i j * x j.succ :=
    Finset.sum_le_sum fun j _ =>
      mul_le_mul_of_nonneg_right (schur_le_iluStep P A hZ h0 i j) (hx _).le
  have hc : 0 ≤ -(A i.succ 0 / A 0 0) :=
    neg_nonneg.mpr (div_nonpos_of_nonpos_of_nonneg (hZ _ _ (Fin.succ_ne_zero i)) h0.le)
  have := mul_nonneg hc (hAx 0).le
  have h1 := hAx i.succ
  simp only [mulVec, dotProduct] at hle ⊢
  simp only [mulVec, dotProduct] at key this h1
  linarith

/-- The comparison, generalised: exact elimination on an M-matrix `A` gives pivots no larger than
incomplete elimination on any `B ≥ A` whose off-diagonal entries are zero or negative. -/
theorem exact_pivot_le_ilu_pivot_of_le : ∀ (n : ℕ) (A B : Matrix (Fin n) (Fin n) ℝ)
    (P : Fin n → Fin n → Prop), IsMMatrix A → (∀ i j, A i j ≤ B i j) →
    (∀ i j, i ≠ j → B i j ≤ 0) →
    ∀ i, iluPivots n (fun _ _ => True) A i ≤ iluPivots n P B i
  | 0, _, _, _, _, _, _, i => Fin.elim0 i
  | n + 1, A, B, P, hA, hAB, hBZ, i => by
    have hA0 := isMMatrix_zero_pos A hA
    have hB0 : 0 < B 0 0 := lt_of_lt_of_le hA0 (hAB 0 0)
    have hAZ := hA.1
    refine Fin.cases ?_ (fun i => ?_) i
    · simpa [iluPivots] using hAB 0 0
    · simp only [iluPivots, Fin.cons_succ]
      refine exact_pivot_le_ilu_pivot_of_le n (iluStep (fun _ _ => True) A) (iluStep P B)
        (fun a b => P a.succ b.succ) (iluStep_isMMatrix _ A hA) (fun a b => ?_)
        (iluStep_offdiag P B hBZ hB0) i
      refine le_trans ?_ (schur_le_iluStep P B hBZ hB0 a b)
      have e : iluStep (fun _ _ => True) A a b =
          A a.succ b.succ - A a.succ 0 * A 0 b.succ / A 0 0 := by simp [iluStep]
      rw [e]
      have h1 := hAZ a.succ 0 (Fin.succ_ne_zero a)
      have h2 := hAZ 0 b.succ (Fin.succ_ne_zero b).symm
      have g1 := hBZ a.succ 0 (Fin.succ_ne_zero a)
      have g2 := hBZ 0 b.succ (Fin.succ_ne_zero b).symm
      have f1 := hAB a.succ 0
      have f2 := hAB 0 b.succ
      have hprod : B a.succ 0 * B 0 b.succ ≤ A a.succ 0 * A 0 b.succ := by
        nlinarith
      have hdiv : B a.succ 0 * B 0 b.succ / B 0 0 ≤ A a.succ 0 * A 0 b.succ / A 0 0 :=
        div_le_div₀ (mul_nonneg_of_nonpos_of_nonpos h1 h2) hprod hA0 (hAB 0 0)
      linarith [hAB a.succ b.succ]

#print axioms isMMatrix_zero_pos
#print axioms schur_mulVec
#print axioms schur_le_iluStep
#print axioms iluStep_offdiag
#print axioms iluStep_isMMatrix
#print axioms exact_pivot_le_ilu_pivot_of_le

/-- **Meijerink and van der Vorst (1977), the card's Step 3.** If `A` is an M-matrix, then
incomplete elimination with any pattern that keeps the diagonal never breaks down: every pivot
of the incomplete factor is positive. -/
theorem ilu_pivots_pos_of_isMMatrix {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ)
    (hA : IsMMatrix A) (P : Fin n → Fin n → Prop) (hP : ∀ i, P i i) :
    ∀ i, 0 < iluPivots n P A i := by
  induction n with
  | zero => exact fun i => Fin.elim0 i
  | succ n ih =>
    intro i
    refine Fin.cases ?_ (fun i => ?_) i
    · simpa [iluPivots] using isMMatrix_zero_pos A hA
    · simp only [iluPivots, Fin.cons_succ]
      exact ih (iluStep P A) (iluStep_isMMatrix P A hA) _ (fun i => hP i.succ) i

/-- **The comparison half of Step 3.** If `A` is an M-matrix, then every pivot of incomplete
elimination with a pattern that keeps the diagonal is at least the matching pivot of exact
elimination (the same rule keeping every position). -/
theorem exact_pivot_le_ilu_pivot {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ)
    (hA : IsMMatrix A) (P : Fin n → Fin n → Prop) (hP : ∀ i, P i i) :
    ∀ i, iluPivots n (fun _ _ => True) A i ≤ iluPivots n P A i := by
  exact exact_pivot_le_ilu_pivot_of_le n A A P hA (fun _ _ => le_rfl) hA.1

/-- **The card's Step 2.** When incomplete elimination runs (every pivot is nonzero), the
incomplete factors reproduce `A` exactly on the pattern: `(L U)_ij = a_ij` for every kept
position `(i, j)`, so the remainder `R = A - L U` is zero there. -/
theorem ilu_factors_match_on_pattern {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ)
    (P : Fin n → Fin n → Prop) (hpiv : ∀ i, iluPivots n P A i ≠ 0) :
    ∀ i j, P i j → (iluL n P A * iluU n P A) i j = A i j := by
  induction n with
  | zero => exact fun i => Fin.elim0 i
  | succ n ih =>
    have h0 : A 0 0 ≠ 0 := by simpa [iluPivots] using hpiv 0
    have hpiv' : ∀ i, iluPivots n (fun a b => P a.succ b.succ) (iluStep P A) i ≠ 0 := by
      intro i
      simpa [iluPivots] using hpiv i.succ
    intro i j hij
    cases i using Fin.cases with
    | zero =>
      simp [iluL, iluU, Matrix.mul_apply, Fin.sum_univ_succ]
    | succ i' =>
      cases j using Fin.cases with
      | zero =>
        simp [iluL, iluU, Matrix.mul_apply, Fin.sum_univ_succ]
        field_simp
      | succ j' =>
        have := ih (iluStep P A) (fun a b => P a.succ b.succ) hpiv' i' j' hij
        rw [Matrix.mul_apply] at this
        simp only [iluL, iluU, Matrix.mul_apply, Fin.sum_univ_succ, of_apply, Fin.cons_succ,
          Fin.cons_zero, this]
        simp only [iluStep, of_apply, hij, ↓reduceIte]
        field_simp
        ring

/-! ### The card's exact worked numbers -/

-- The 4 by 4 grid: the first fill, 0 - (-1)(-1)/4 = -1/4, dropped by IC(0);
-- pivot 2 (and pivot 5) is 4 - (-1)(-1)/4 = 15/4; pivot 6 is 4 - 1/(15/4) - 1/(15/4) = 52/15.
example : (0 : ℚ) - (-1) * (-1) / 4 = -1 / 4 := by norm_num
example : (4 : ℚ) - (-1) * (-1) / 4 = 15 / 4 := by norm_num
example : (4 : ℚ) - 1 / (15 / 4) - 1 / (15 / 4) = 52 / 15 := by norm_num

-- Five-point matrix sizes: the m by m grid has 5 m^2 - 4 m nonzeros (64 at m = 4, 19,593 at
-- m = 63), IC(0) drops 2 (m - 1)^2 fill entries at m = 4 (18), and IC(1) keeps
-- 19,593 + 2 × 62^2 = 27,281 entries at m = 63.
example : 5 * 4 ^ 2 - 4 * 4 = 64 ∧ 63 * 63 = 3969 ∧ 5 * 63 ^ 2 - 4 * 63 = 19593 := by norm_num
example : 2 * (4 - 1) ^ 2 = 18 ∧ 19593 + 2 * 62 ^ 2 = 27281 := by norm_num

-- Flop counts on the 63 by 63 plate: a plain CG step, a preconditioned step, and the totals.
example : 2 * 19593 + 10 * 3969 = 78876 ∧ 4 * 19593 + 9 * 3969 = 114093 := by norm_num
example : 119 * 78876 = 9386244 ∧ 55 * 114093 + 38812 = 6313927 := by norm_num

-- Kershaw's matrix: positive definite but not an M-matrix (entry (4, 1) is +2).
/-- Kershaw's 4 by 4 matrix from the card's "What breaks". -/
def kershaw : Matrix (Fin 4) (Fin 4) ℝ :=
  !![3, -2, 0, 2; -2, 3, -2, 0; 0, -2, 3, -2; 2, 0, -2, 3]

example : 0 < kershaw 3 0 := by norm_num [kershaw]

-- Exact elimination: pivots 3, 5/3, 3/5, 1/3, all positive.
example : iluPivots 4 (fun _ _ => True) kershaw = ![3, 5 / 3, 3 / 5, 1 / 3] := by
  funext i
  fin_cases i <;>
    norm_num [iluPivots, iluStep, kershaw, Fin.succ_zero_eq_one, Fin.succ_one_eq_two] <;> rfl

-- IC(0), keeping only Kershaw's own nonzeros: the fourth pivot comes out -5.
example : iluPivots 4 (fun i j => kershaw i j ≠ 0) kershaw 3 = -5 := by
  norm_num [iluPivots, iluStep, kershaw, Fin.succ_zero_eq_one, Fin.succ_one_eq_two]
  rfl

#print axioms ilu_pivots_pos_of_isMMatrix
#print axioms exact_pivot_le_ilu_pivot
#print axioms ilu_factors_match_on_pattern
