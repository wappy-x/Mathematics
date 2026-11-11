-- Gaussian elimination: swaps, nonzero scalings and taking a multiple of one row from another bring every linear system over a field to row echelon form without changing its solutions, and a staircase with a pivot in every column and no row reading 0 = nonzero has exactly one solution.
import Mathlib.LinearAlgebra.Matrix.Echelon.Basic
import Mathlib.LinearAlgebra.Matrix.ElementaryRowOperations
import Mathlib.LinearAlgebra.Matrix.Transvection
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.Block
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring

open Matrix

/-- The three legal row moves, each as Mathlib's elementary matrix acting from the left:
swap rows `i` and `j` (`Matrix.swap`); scale row `i` by a number `c` that is not zero
(`Matrix.rowScale`); take `c` times row `k` away from a different row `i`
(`Matrix.transvection i k (-c)`). Doing a move to the system `A x = b` means multiplying both
the counts `A` and the totals `b` by its matrix, so the money rides along on every row. -/
inductive IsLegalRowMove {K : Type*} [Field K] {m : Type*} [DecidableEq m] [Fintype m] :
    Matrix m m K → Prop
  | swap (i j : m) : IsLegalRowMove (Matrix.swap K i j)
  | scale (i : m) (c : K) (hc : c ≠ 0) : IsLegalRowMove (Matrix.rowScale i c)
  | subtract (i k : m) (hik : i ≠ k) (c : K) : IsLegalRowMove (Matrix.transvection i k (-c))

/-- Each legal row move can be undone: its matrix is invertible. -/
lemma isLegalRowMove_isUnit {K : Type*} [Field K] {m : Type*} [DecidableEq m] [Fintype m]
    {E : Matrix m m K} (h : IsLegalRowMove E) : IsUnit E := by
  cases h with
  | swap i j => exact ⟨GeneralLinearGroup.swap K i j, rfl⟩
  | scale i c hc => exact ⟨GeneralLinearGroup.rowScale i (Units.mk0 c hc), rfl⟩
  | subtract i k hik c => exact ⟨GeneralLinearGroup.transvection i k hik (-c), rfl⟩

/-- A list of legal row moves multiplies out to an invertible matrix. -/
lemma legal_moves_prod_isUnit {K : Type*} [Field K] {m : ℕ}
    (moves : List (Matrix (Fin m) (Fin m) K)) (hmoves : ∀ E ∈ moves, IsLegalRowMove E) :
    IsUnit moves.prod := by
  induction moves with
  | nil => simp
  | cons E l ih =>
    rw [List.prod_cons]
    exact (isLegalRowMove_isUnit (hmoves E (by simp))).mul
      (ih fun F hF => hmoves F (by simp [hF]))

/-- Helper: legal moves change no solution (used before the main statement of this fact). -/
lemma legal_moves_keep_solutions {K : Type*} [Field K] {m n : ℕ}
    (moves : List (Matrix (Fin m) (Fin m) K)) (hmoves : ∀ E ∈ moves, IsLegalRowMove E)
    (A : Matrix (Fin m) (Fin n) K) (b : Fin m → K) (x : Fin n → K) :
    (moves.prod * A) *ᵥ x = moves.prod *ᵥ b ↔ A *ᵥ x = b := by
  rw [← Matrix.mulVec_mulVec]
  exact (Matrix.mulVec_injective_iff_isUnit.2 (legal_moves_prod_isUnit moves hmoves)).eq_iff

/-- Clearing: subtract a multiple of row `r` from every row in the list `l`, killing column `c`. -/
lemma clear_rows {K : Type*} [Field K] {m n : ℕ} (B : Matrix (Fin m) (Fin n) K) (r : Fin m)
    (c : Fin n) (l : List (Fin m)) (hr : r ∉ l) (hl : l.Nodup) :
    ∃ L : List (Matrix (Fin m) (Fin m) K), (∀ E ∈ L, IsLegalRowMove E) ∧
      ∀ k, (L.prod * B) k = if k ∈ l then B k - (B k c / B r c) • B r else B k := by
  induction l with
  | nil => exact ⟨[], by simp, by simp⟩
  | cons a l ih =>
    simp only [List.mem_cons, not_or, List.nodup_cons] at hr hl
    obtain ⟨L, hL, hrow⟩ := ih hr.2 hl.2
    refine ⟨transvection a r (-(B a c / B r c)) :: L, ?_, ?_⟩
    · intro E hE
      rw [List.mem_cons] at hE
      rcases hE with rfl | hE
      · exact IsLegalRowMove.subtract a r (Ne.symm hr.1) _
      · exact hL E hE
    · intro k
      rw [List.prod_cons, Matrix.mul_assoc]
      by_cases hk : k = a
      · subst hk
        ext j
        rw [transvection_mul_apply_same, hrow, hrow]
        simp [hl.1, hr.2]
        ring
      · ext j
        rw [transvection_mul_apply_of_ne (ha := hk), hrow]
        simp [hk]

/-- The elimination loop, column by column: after handling the first `s` columns, the first `r`
rows are a staircase, each with a nonzero entry among those columns, and every lower row is zero
there. -/
lemma elim_cols {K : Type*} [Field K] {m n : ℕ} (A : Matrix (Fin m) (Fin n) K) :
    ∀ s : ℕ, s ≤ n → ∃ moves : List (Matrix (Fin m) (Fin m) K),
      (∀ E ∈ moves, IsLegalRowMove E) ∧
      ∃ r : ℕ, (∀ i : Fin m, r ≤ i.val → ∀ j : Fin n, j.val < s → (moves.prod * A) i j = 0) ∧
        (∀ i : Fin m, i.val < r → ∃ j : Fin n, j.val < s ∧ (moves.prod * A) i j ≠ 0) ∧
        (∀ i₁ i₂ : Fin m, i₁ < i₂ → i₂.val < r → ∀ j₂ : Fin n,
            (∀ j₁ < j₂, (moves.prod * A) i₁ j₁ = 0) → (moves.prod * A) i₂ j₂ = 0) := by
  intro s
  induction s with
  | zero =>
    intro _
    refine ⟨[], by simp, 0, ?_, ?_, ?_⟩
    · intro i _ j hj; omega
    · intro i hi; omega
    · intro i₁ i₂ _ hi; omega
  | succ s ih =>
    intro hs
    obtain ⟨L, hL, r, h1, h2, h3⟩ := ih (by omega)
    set B := L.prod * A with hB
    by_cases hcol : ∀ i : Fin m, r ≤ i.val → B i ⟨s, hs⟩ = 0
    · refine ⟨L, hL, r, ?_, ?_, h3⟩
      · intro i hi j hj
        rcases Nat.lt_succ_iff_lt_or_eq.1 hj with hj | hj
        · exact h1 i hi j hj
        · have : j = ⟨s, hs⟩ := Fin.ext hj
          rw [this]; exact hcol i hi
      · intro i hi
        obtain ⟨j, hj, hne⟩ := h2 i hi
        exact ⟨j, by omega, hne⟩
    · push Not at hcol
      obtain ⟨p, hpr, hp⟩ := hcol
      have hrm : r < m := lt_of_le_of_lt hpr p.isLt
      set R : Fin m := ⟨r, hrm⟩ with hR
      set B' := swap K p R * B with hB'
      have hB'R : B' R = B p := by ext j; simp [hB']
      have hB'lt : ∀ i : Fin m, i.val < r → B' i = B i := by
        intro i hi
        ext j
        rw [hB', swap_mul_of_ne]
        · intro h; subst h; omega
        · intro h; rw [h] at hi; simp [hR] at hi
      have hB'low : ∀ i : Fin m, r ≤ i.val → ∀ j : Fin n, j.val < s → B' i j = 0 := by
        intro i hi j hj
        by_cases hip : i = p
        · subst hip; rw [hB', swap_mul_apply_left]; exact h1 R le_rfl j hj
        · by_cases hiR : i = R
          · rw [hiR, hB'R]; exact h1 p hpr j hj
          · rw [hB', swap_mul_of_ne hip hiR]; exact h1 i hi j hj
      have hpiv : B' R ⟨s, hs⟩ ≠ 0 := by rw [hB'R]; exact hp
      obtain ⟨L2, hL2, hrow⟩ := clear_rows B' R ⟨s, hs⟩
        ((Finset.univ.filter (fun i : Fin m => r < i.val)).toList) (by simp [hR])
        (Finset.nodup_toList _)
      have hprod : (L2 ++ swap K p R :: L).prod * A = L2.prod * B' := by
        simp [List.prod_append, List.prod_cons, Matrix.mul_assoc, hB', hB]
      have hC : ∀ i : Fin m, i.val ≤ r → (L2.prod * B') i = B' i := by
        intro i hi
        rw [hrow]
        have : ¬ (i ∈ (Finset.univ.filter (fun i : Fin m => r < i.val)).toList) := by
          simp; omega
        simp [this]
      refine ⟨L2 ++ swap K p R :: L, ?_, r + 1, ?_, ?_, ?_⟩
      · intro E hE
        rw [List.mem_append, List.mem_cons] at hE
        rcases hE with hE | rfl | hE
        · exact hL2 E hE
        · exact IsLegalRowMove.swap p R
        · exact hL E hE
      · intro i hi j hj
        rw [hprod, hrow]
        have hmem : i ∈ (Finset.univ.filter (fun i : Fin m => r < i.val)).toList := by
          simp; omega
        simp only [hmem, ite_true, Pi.sub_apply, Pi.smul_apply, smul_eq_mul]
        rcases Nat.lt_succ_iff_lt_or_eq.1 hj with hj | hj
        · rw [hB'low i (by omega) j hj, hB'low R le_rfl j hj]; ring
        · have : j = ⟨s, hs⟩ := Fin.ext hj
          rw [this]
          field_simp
          ring
      · intro i hi
        rw [hprod]
        rcases Nat.lt_succ_iff_lt_or_eq.1 hi with hi | hi
        · obtain ⟨j, hj, hne⟩ := h2 i hi
          refine ⟨j, by omega, ?_⟩
          rw [hC i hi.le, hB'lt i hi]; exact hne
        · have : i = R := Fin.ext hi
          refine ⟨⟨s, hs⟩, by simp, ?_⟩
          rw [hC i hi.le, this]; exact hpiv
      · intro i₁ i₂ hlt hi₂ j₂ hz
        rw [hprod] at hz ⊢
        have hi₁ : i₁.val < r := by
          have : i₁.val < i₂.val := hlt
          omega
        rw [hC i₁ hi₁.le, hB'lt i₁ hi₁] at hz
        rw [hC i₂ (by omega)]
        rcases Nat.lt_succ_iff_lt_or_eq.1 hi₂ with hi₂ | hi₂
        · rw [hB'lt i₂ hi₂]
          exact h3 i₁ i₂ hlt hi₂ j₂ hz
        · obtain ⟨j0, hj0, hne⟩ := h2 i₁ hi₁
          have hj : j₂ ≤ j0 := by
            by_contra hc
            exact hne (hz j0 (lt_of_not_ge hc))
          have hj' : j₂.val < s := lt_of_le_of_lt hj hj0
          exact hB'low i₂ (by omega) j₂ hj'

/-- Gaussian elimination. With exact arithmetic (numbers from a field), every system of `m`
equations in `n` unknowns, `A x = b`, can be turned by a finite list of legal row moves into a
staircase: the new counts are in row echelon form. Done to whole equations (counts and total
together), the moves change no solution: a price list fits the staircase exactly when it fits
the original system. (`moves.prod` applies the last move in the list first.) -/
theorem three_row_moves_turn_any_system_into_a_staircase {K : Type*} [Field K] {m n : ℕ}
    (A : Matrix (Fin m) (Fin n) K) (b : Fin m → K) :
    ∃ moves : List (Matrix (Fin m) (Fin m) K), (∀ E ∈ moves, IsLegalRowMove E) ∧
      (moves.prod * A).IsRowEchelon ∧
      ∀ x : Fin n → K, (moves.prod * A) *ᵥ x = moves.prod *ᵥ b ↔ A *ᵥ x = b := by
  classical
  obtain ⟨L, hL, r, h1, h2, h3⟩ := elim_cols A n le_rfl
  refine ⟨L, hL, ?_, fun x => legal_moves_keep_solutions L hL A b x⟩
  intro i₁ i₂ hlt j₂ hz
  by_cases hi : i₂.val < r
  · exact h3 i₁ i₂ hlt hi j₂ hz
  · exact h1 i₂ (by omega) j₂ j₂.isLt

/-- Every move has a way back, so no answer moves: after any list of legal row moves, done to
the counts and the totals alike, a list of values solves the new system exactly when it solves
the old one. Nothing is lost and nothing is gained. -/
theorem legal_row_moves_change_no_solution {K : Type*} [Field K] {m n : ℕ}
    (moves : List (Matrix (Fin m) (Fin m) K)) (hmoves : ∀ E ∈ moves, IsLegalRowMove E)
    (A : Matrix (Fin m) (Fin n) K) (b : Fin m → K) (x : Fin n → K) :
    (moves.prod * A) *ᵥ x = moves.prod *ᵥ b ↔ A *ᵥ x = b := by
  exact legal_moves_keep_solutions moves hmoves A b x

/-- Reading the staircase back from the bottom. A system in row echelon form with a pivot
(leading entry) in every unknown's column, and no row reading 0 = a number that is not zero,
has exactly one solution. -/
theorem staircase_with_a_pivot_for_every_unknown_has_one_answer {K : Type*} [Field K] {m n : ℕ}
    (U : Matrix (Fin m) (Fin n) K) (c : Fin m → K) (hU : U.IsRowEchelon)
    (hpivots : ∀ j, ∃ i, U.IsLeadingEntry i j) (hno_contradiction : ∀ i, U i = 0 → c i = 0) :
    ∃! x : Fin n → K, U *ᵥ x = c := by
  classical
  have same : ∀ i₁ i₂ j, U.IsLeadingEntry i₁ j → U.IsLeadingEntry i₂ j → i₁ = i₂ := by
    intro i₁ i₂ j h₁ h₂
    by_contra hne
    rcases lt_or_gt_of_ne hne with h | h
    · exact h₂.2 (hU h h₁.1)
    · exact h₁.2 (hU h h₂.1)
  choose p hp using hpivots
  set V : Matrix (Fin n) (Fin n) K := U.submatrix p id with hV
  have hVtri : V.IsUpperTriangular := fun i j hji => (hp i).1 j hji
  have hdet : IsUnit V.det := by
    rw [Matrix.det_of_isUpperTriangular hVtri]
    exact isUnit_iff_ne_zero.2 (Finset.prod_ne_zero_iff.2 fun j _ => (hp j).2)
  have hzero : ∀ i, i ∉ Set.range p → U i = 0 := by
    intro i hi
    by_contra h
    obtain ⟨k, hk⟩ := Matrix.row_ne_zero_iff_exists_isLeadingEntry.1 h
    exact hi ⟨k, same _ _ k (hp k) hk⟩
  have key : ∀ x, U *ᵥ x = c ↔ V *ᵥ x = c ∘ p := by
    intro x
    constructor
    · intro h
      ext j
      rw [← h]
      simp [hV, Matrix.mulVec, dotProduct]
    · intro h
      ext i
      by_cases hi : i ∈ Set.range p
      · obtain ⟨j, rfl⟩ := hi
        have := congrFun h j
        simpa [hV, Matrix.mulVec, dotProduct] using this
      · rw [hno_contradiction i (hzero i hi)]
        simp [Matrix.mulVec, dotProduct, hzero i hi]
  refine ⟨V⁻¹ *ᵥ (c ∘ p), ?_, ?_⟩
  · show U *ᵥ (V⁻¹ *ᵥ (c ∘ p)) = c
    rw [key, Matrix.mulVec_mulVec, Matrix.mul_nonsing_inv _ hdet, Matrix.one_mulVec]
  · intro y hy
    rw [key] at hy
    rw [← hy, Matrix.mulVec_mulVec, Matrix.nonsing_inv_mul _ hdet, Matrix.one_mulVec]

-- The till slips: 2c + p + s = 17, c + p = 7, c + 2p + 2s = 22, and the prices $4, $3, $6 fit.
example : !![(2 : ℚ), 1, 1; 1, 1, 0; 1, 2, 2] *ᵥ ![4, 3, 6] = ![17, 7, 22] := by
  ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_three] <;> norm_num

-- The three moves: middle − 0.5 × top, bottom − 0.5 × top, bottom − 3 × middle.
-- On the counts they give the staircase [2, 1, 1], [0, 0.5, −0.5], [0, 0, 3] ...
example : transvection (2 : Fin 3) 1 (-3 : ℚ) * (transvection 2 0 (-(1/2)) *
      (transvection 1 0 (-(1/2)) * !![(2 : ℚ), 1, 1; 1, 1, 0; 1, 2, 2])) =
      !![2, 1, 1; 0, 1/2, -1/2; 0, 0, 3] := by
  ext i j; fin_cases i <;> fin_cases j <;>
    simp [transvection, Matrix.mul_apply, Fin.sum_univ_three, Matrix.add_apply, Matrix.single] <;>
    norm_num

-- ... and on the totals 17, 7, 22 they give 17, −1.5, 18.
example : transvection (2 : Fin 3) 1 (-3 : ℚ) *ᵥ (transvection 2 0 (-(1/2)) *ᵥ
      (transvection 1 0 (-(1/2)) *ᵥ ![(17 : ℚ), 7, 22])) = ![17, -3/2, 18] := by
  ext i; fin_cases i <;>
    simp [transvection, Matrix.mulVec, dotProduct, Fin.sum_univ_three, Matrix.add_apply,
      Matrix.single] <;> norm_num

-- The result is a staircase (row echelon form).
example : (!![(2 : ℚ), 1, 1; 0, 1/2, -1/2; 0, 0, 3]).IsRowEchelon := by
  intro i₁ i₂ h j hj
  fin_cases i₁ <;> fin_cases i₂ <;> fin_cases j <;> simp_all [Fin.forall_fin_succ]

-- Back substitution: the bottom row says 3 sandwiches cost $18, and $4, $3, $6 fit every step.
example : (18 : ℚ) / 3 = 6 ∧ ((-3/2 : ℚ) + 1/2 * 6) / (1/2) = 3 ∧ ((17 : ℚ) - 3 - 6) / 2 = 4 := by
  norm_num
example : !![(2 : ℚ), 1, 1; 0, 1/2, -1/2; 0, 0, 3] *ᵥ ![4, 3, 6] = ![17, -3/2, 18] := by
  ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_three] <;> norm_num

-- Wednesday as Monday plus Tuesday, total 24: both (4, 3, 6) and (3, 4, 7) fit, a line of answers.
example : !![(2 : ℚ), 1, 1; 1, 1, 0; 3, 2, 1] *ᵥ ![4, 3, 6] = ![17, 7, 24] ∧
    !![(2 : ℚ), 1, 1; 1, 1, 0; 3, 2, 1] *ᵥ ![3, 4, 7] = ![17, 7, 24] := by
  constructor <;>
    (ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_three] <;> norm_num)

-- Its elimination ends in the bottom row [0, 0, 0 | 0]; misread as 25, it ends in [0, 0, 0 | 1].
example : transvection (2 : Fin 3) 1 (-1 : ℚ) * (transvection 2 0 (-(3/2)) *
      (transvection 1 0 (-(1/2)) * !![(2 : ℚ), 1, 1; 1, 1, 0; 3, 2, 1])) =
      !![2, 1, 1; 0, 1/2, -1/2; 0, 0, 0] := by
  ext i j; fin_cases i <;> fin_cases j <;>
    simp [transvection, Matrix.mul_apply, Fin.sum_univ_three, Matrix.add_apply, Matrix.single] <;>
    norm_num
example : transvection (2 : Fin 3) 1 (-1 : ℚ) *ᵥ (transvection 2 0 (-(3/2)) *ᵥ
      (transvection 1 0 (-(1/2)) *ᵥ ![(17 : ℚ), 7, 24])) = ![17, -3/2, 0] ∧
    transvection (2 : Fin 3) 1 (-1 : ℚ) *ᵥ (transvection 2 0 (-(3/2)) *ᵥ
      (transvection 1 0 (-(1/2)) *ᵥ ![(17 : ℚ), 7, 25])) = ![17, -3/2, 1] := by
  constructor <;>
    (ext i; fin_cases i <;>
      simp [transvection, Matrix.mulVec, dotProduct, Fin.sum_univ_three, Matrix.add_apply,
        Matrix.single] <;> norm_num)

#print axioms isLegalRowMove_isUnit
#print axioms legal_moves_prod_isUnit
#print axioms legal_moves_keep_solutions
#print axioms clear_rows
#print axioms elim_cols
#print axioms three_row_moves_turn_any_system_into_a_staircase
#print axioms legal_row_moves_change_no_solution
#print axioms staircase_with_a_pivot_for_every_unknown_has_one_answer
