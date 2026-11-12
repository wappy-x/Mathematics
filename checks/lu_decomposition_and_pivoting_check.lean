-- LU with partial pivoting: every square matrix with nonzero determinant splits, after a reordering P of its rows, as PA = LU with L lower triangular, 1s on its diagonal and every multiplier at most 1 in size, and U upper triangular with nonzero pivots; then Ax = b is solved by the two sweeps Ly = Pb and Ux = y, and det A is the sign of P times the product of the pivots.
import Mathlib.LinearAlgebra.Matrix.Block
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Basic.Real.Basic
import Mathlib.Data.Rat.Defs
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.NormNum

open Matrix

/-- Gluing a first column and a lower triangle below a row `1, 0, …, 0` gives a lower triangle. -/
theorem lu_glue_lower {n : ℕ} (m : Fin n → ℝ) (L' : Matrix (Fin n) (Fin n) ℝ)
    (hL' : L'.IsLowerTriangular) :
    (Matrix.of (vecCons (vecCons 1 0) (fun i => vecCons (m i) (L' i))) :
      Matrix (Fin (n + 1)) (Fin (n + 1)) ℝ).IsLowerTriangular := by
  intro i j h
  change i < j at h
  cases i using Fin.cases with
  | zero =>
    cases j using Fin.cases with
    | zero => exact absurd h (lt_irrefl _)
    | succ j => simp
  | succ i =>
    cases j using Fin.cases with
    | zero => exact absurd h (Fin.not_lt_zero _)
    | succ j =>
      simp only [of_apply, cons_val_succ]
      exact hL' (show i < j from Fin.succ_lt_succ_iff.mp h)

#print axioms lu_glue_lower

/-- Gluing a first row above a zero column and an upper triangle gives an upper triangle. -/
theorem lu_glue_upper {n : ℕ} (r : Fin (n + 1) → ℝ) (U' : Matrix (Fin n) (Fin n) ℝ)
    (hU' : U'.IsUpperTriangular) :
    (Matrix.of (vecCons r (fun i => vecCons 0 (U' i))) :
      Matrix (Fin (n + 1)) (Fin (n + 1)) ℝ).IsUpperTriangular := by
  intro i j h
  change j < i at h
  cases i using Fin.cases with
  | zero => exact absurd h (Fin.not_lt_zero _)
  | succ i =>
    cases j using Fin.cases with
    | zero => simp
    | succ j =>
      simp only [of_apply, cons_val_succ]
      exact hU' (show j < i from Fin.succ_lt_succ_iff.mp h)

#print axioms lu_glue_upper

/-- LU with partial pivoting exists. Let A be a square n by n matrix of real numbers that is not
singular: its determinant is not zero. Then there is a row order σ (row i of PA is row σ i of A),
a lower triangle L with 1s on its diagonal and every multiplier ℓ_ik at most 1 in size, and an
upper triangle U whose pivots (its diagonal entries) are all nonzero, such that PA = LU. -/
theorem lu_with_partial_pivoting_exists {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (hA : A.det ≠ 0) :
    ∃ (σ : Equiv.Perm (Fin n)) (L U : Matrix (Fin n) (Fin n) ℝ),
      L.IsLowerTriangular ∧ (∀ i, L i i = 1) ∧ (∀ i j, |L i j| ≤ 1) ∧
      U.IsUpperTriangular ∧ (∀ i, U i i ≠ 0) ∧
      A.submatrix σ id = L * U := by
  induction n with
  | zero =>
    refine ⟨1, 1, 1, ?_, ?_, ?_, ?_, ?_, ?_⟩
    · intro i; exact i.elim0
    · intro i; exact i.elim0
    · intro i; exact i.elim0
    · intro i; exact i.elim0
    · intro i; exact i.elim0
    · ext i; exact i.elim0
  | succ n ih =>
    -- the pivot row p holds the largest entry of column 0 in size
    obtain ⟨p, -, hp⟩ := Finset.exists_max_image Finset.univ (fun r => |A r 0|)
      Finset.univ_nonempty
    have hp0 : A p 0 ≠ 0 := by
      intro h0
      apply hA
      apply det_eq_zero_of_column_eq_zero 0
      intro r
      have := hp r (Finset.mem_univ _)
      rw [h0, abs_zero] at this
      exact abs_nonpos_iff.mp this
    -- B is A with rows 0 and p swapped
    set B : Matrix (Fin (n + 1)) (Fin (n + 1)) ℝ := A.submatrix (Equiv.swap 0 p) id with hBdef
    have hB00 : B 0 0 = A p 0 := by simp [hBdef]
    have hBdet : B.det ≠ 0 := by
      rw [hBdef, det_permute]
      exact mul_ne_zero (by simp) hA
    -- multipliers and Schur complement
    set m : Fin n → ℝ := fun i => B i.succ 0 / B 0 0 with hm
    set S : Matrix (Fin n) (Fin n) ℝ := Matrix.of fun i j => B i.succ j.succ - m i * B 0 j.succ
      with hS
    have hm_le : ∀ i, |m i| ≤ 1 := by
      intro i
      rw [hm]
      simp only
      rw [abs_div, div_le_one (abs_pos.mpr (hB00 ▸ hp0)), hB00]
      exact hp _ (Finset.mem_univ _)
    -- det B = B 0 0 * det S
    have hSdet : S.det ≠ 0 := by
      set L1 : Matrix (Fin (n + 1)) (Fin (n + 1)) ℝ :=
        Matrix.of (vecCons (vecCons 1 0) (fun i => vecCons (m i) ((1 : Matrix (Fin n) (Fin n) ℝ) i)))
      set U1 : Matrix (Fin (n + 1)) (Fin (n + 1)) ℝ :=
        Matrix.of (vecCons (B 0) (fun i => vecCons 0 (S i)))
      have hL1 : L1.det = 1 := by
        rw [det_of_isLowerTriangular L1 (lu_glue_lower m 1 blockTriangular_one)]
        apply Finset.prod_eq_one
        intro i _
        cases i using Fin.cases with
        | zero => simp [L1]
        | succ i => simp [L1]
      have hU1 : U1.det = B 0 0 * S.det := by
        rw [det_succ_column_zero, Fin.sum_univ_succ]
        simp only [U1, of_apply, cons_val_zero, cons_val_succ, Fin.val_zero, pow_zero, one_mul,
          zero_mul, mul_zero, Finset.sum_const_zero, add_zero, Fin.succAbove_zero]
        congr 2
      have hBLU : B = L1 * U1 := by
        ext i j
        cases i using Fin.cases with
        | zero =>
          rw [Matrix.mul_apply, Fin.sum_univ_succ]
          simp [L1, U1]
        | succ i =>
          cases j using Fin.cases with
          | zero =>
            rw [Matrix.mul_apply, Fin.sum_univ_succ]
            simp [L1, U1, hm]
            field_simp [hB00 ▸ hp0]
          | succ j =>
            rw [Matrix.mul_apply, Fin.sum_univ_succ]
            simp [L1, U1, hS, Matrix.one_apply]
      intro h0
      apply hBdet
      rw [hBLU, det_mul, hL1, hU1, h0, mul_zero, mul_zero]
    obtain ⟨τ, L', U', hL'l, hL'1, hL'b, hU'u, hU'd, hLU'⟩ := ih S hSdet
    refine ⟨Equiv.Perm.decomposeFin.symm (p, τ),
      Matrix.of (vecCons (vecCons 1 0) (fun i => vecCons (m (τ i)) (L' i))),
      Matrix.of (vecCons (B 0) (fun i => vecCons 0 (U' i))),
      lu_glue_lower _ L' hL'l, ?_, ?_, lu_glue_upper _ U' hU'u, ?_, ?_⟩
    · intro i
      cases i using Fin.cases with
      | zero => simp
      | succ i => simp [hL'1]
    · intro i j
      cases i using Fin.cases with
      | zero =>
        cases j using Fin.cases with
        | zero => simp
        | succ j => simp
      | succ i =>
        cases j using Fin.cases with
        | zero => simpa using hm_le (τ i)
        | succ j => simpa using hL'b i j
    · intro i
      cases i using Fin.cases with
      | zero => simpa [hB00] using hp0
      | succ i => simpa using hU'd i
    · ext i j
      have hS' : ∀ i j, S (τ i) j = ∑ k, L' i k * U' k j := by
        intro i j
        have := congrFun (congrFun hLU' i) j
        rw [← Matrix.mul_apply]; exact this
      cases i using Fin.cases with
      | zero =>
        rw [Matrix.mul_apply, Fin.sum_univ_succ]
        simp [Equiv.Perm.decomposeFin_symm_apply_zero, hBdef]
      | succ i =>
        cases j using Fin.cases with
        | zero =>
          rw [Matrix.mul_apply, Fin.sum_univ_succ]
          simp [Equiv.Perm.decomposeFin_symm_apply_succ, hm]
          rw [div_mul_cancel₀ _ (hB00 ▸ hp0)]
          rfl
        | succ j =>
          rw [Matrix.mul_apply, Fin.sum_univ_succ]
          simp [Equiv.Perm.decomposeFin_symm_apply_succ, ← hS']
          rw [hS, of_apply, add_sub_cancel]
          rfl

/-- Solving by two triangle sweeps. If PA = LU, with row i of PA being row σ i of A, then
Ax = b holds exactly when there is a halfway vector y with Ly = Pb (the sweep down L, where
entry i of Pb is b (σ i)) and Ux = y (the sweep up U). So every new right-hand side b reuses the
same L and U. -/
theorem solve_by_two_triangle_sweeps {n : ℕ} (A L U : Matrix (Fin n) (Fin n) ℝ)
    (σ : Equiv.Perm (Fin n)) (hLU : A.submatrix σ id = L * U) (x b : Fin n → ℝ) :
    A *ᵥ x = b ↔ ∃ y : Fin n → ℝ, L *ᵥ y = b ∘ σ ∧ U *ᵥ x = y := by
  have key : ∀ i, (L *ᵥ (U *ᵥ x)) i = (A *ᵥ x) (σ i) := by
    intro i
    rw [mulVec_mulVec, ← hLU]
    rfl
  constructor
  · intro h
    refine ⟨U *ᵥ x, ?_, rfl⟩
    funext i
    rw [key, h]
    rfl
  · rintro ⟨y, hy, rfl⟩
    funext k
    have := congrFun hy (σ.symm k)
    rw [key] at this
    simpa using this

/-- The determinant comes free. If PA = LU with L lower triangular with 1s on its diagonal and U
upper triangular, then det A is the sign of the row order σ (+1 for an even number of swaps,
-1 for an odd number) times the product of the pivots U i i. -/
theorem det_eq_sign_mul_prod_pivots {n : ℕ} (A L U : Matrix (Fin n) (Fin n) ℝ)
    (σ : Equiv.Perm (Fin n)) (hL : L.IsLowerTriangular) (hL1 : ∀ i, L i i = 1)
    (hU : U.IsUpperTriangular) (hLU : A.submatrix σ id = L * U) :
    A.det = ((Equiv.Perm.sign σ : ℤ) : ℝ) * ∏ i, U i i := by
  have h1 := det_permute σ A
  rw [hLU, det_mul, det_of_isLowerTriangular L hL, det_of_isUpperTriangular hU] at h1
  simp only [hL1, Finset.prod_const_one, one_mul] at h1
  rw [h1, ← mul_assoc]
  have : ((Equiv.Perm.sign σ : ℤ) : ℝ) * ((Equiv.Perm.sign σ : ℤ) : ℝ) = 1 := by
    rw [← Int.cast_mul, ← Units.val_mul, Int.units_mul_self]; simp
  rw [this, one_mul]

/-! The card's water network, exactly, with r1 = 1/10, r2 = 3/10, r3 = 2/5 and H = 60.
Unknowns (h1, h2, q1, q2, q3); rows J1, J2, pipe 1, pipe 2, pipe 3. -/

/-- The network matrix A of the card. -/
def netA : Matrix (Fin 5) (Fin 5) ℚ :=
  !![0, 0, 1, -1, 0;
     0, 0, 0, 1, 1;
     1, 0, 1/10, 0, 0;
     -1, 1, 0, 3/10, 0;
     0, 1, 0, 0, 2/5]

/-- The row order pivoting chose: pipe 1, pipe 2, J1, J2, pipe 3 (two swaps). -/
def netσ : Equiv.Perm (Fin 5) := Equiv.swap 0 2 * Equiv.swap 1 3

/-- L, the multipliers. -/
def netL : Matrix (Fin 5) (Fin 5) ℚ :=
  !![1, 0, 0, 0, 0;
     -1, 1, 0, 0, 0;
     0, 0, 1, 0, 0;
     0, 0, 0, 1, 0;
     0, 1, -1/10, -2/5, 1]

/-- U, what elimination leaves; pivots 1, 1, 1, 1, 4/5. -/
def netU : Matrix (Fin 5) (Fin 5) ℚ :=
  !![1, 0, 1/10, 0, 0;
     0, 1, 1/10, 3/10, 0;
     0, 0, 1, -1, 0;
     0, 0, 0, 1, 1;
     0, 0, 0, 0, 4/5]

/-- The right side for demands d1, d2: (d1, d2, H, 0, H). -/
def netB (d1 d2 : ℚ) : Fin 5 → ℚ := ![d1, d2, 60, 0, 60]

-- The row order is pipe 1, pipe 2, J1, J2, pipe 3.
example : (netσ 0, netσ 1, netσ 2, netσ 3, netσ 4) = (2, 3, 0, 1, 4) := by decide

-- PA = LU for the network.
example : netA.submatrix netσ id = netL * netU := by
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [netA, netL, netU, netσ, Matrix.mul_apply, Fin.sum_univ_succ, Equiv.swap_apply_def] <;>
    norm_num

-- Every multiplier is at most 1 in size; the largest is 1.
example : ∀ i j, |netL i j| ≤ 1 := by
  intro i j
  fin_cases i <;> fin_cases j <;> simp [netL] <;> norm_num [abs_of_nonneg, abs_of_nonpos]

-- det A = (-1)^2 × 1 × 1 × 1 × 1 × 4/5 = 4/5, the loop's total resistance 1/10 + 3/10 + 2/5.
example : netA.det = 4 / 5 ∧ (1 : ℚ) / 10 + 3 / 10 + 2 / 5 = 4 / 5 := by
  refine ⟨?_, by norm_num⟩
  simp [netA, Matrix.det_succ_row_zero, Fin.sum_univ_succ, Fin.succAbove]
  norm_num

-- Morning (d1, d2) = (20, 30): Pb = (60, 0, 20, 30, 60), y = (60, 60, 20, 30, 14),
-- x = (h1, h2, q1, q2, q3) = (56.75, 53, 32.5, 12.5, 17.5).
example : netB 20 30 ∘ netσ = ![60, 0, 20, 30, 60] ∧
    netL *ᵥ ![60, 60, 20, 30, 14] = netB 20 30 ∘ netσ ∧
    netU *ᵥ ![227/4, 53, 65/2, 25/2, 35/2] = ![60, 60, 20, 30, 14] ∧
    netA *ᵥ ![227/4, 53, 65/2, 25/2, 35/2] = netB 20 30 := by
  refine ⟨?_, ?_, ?_, ?_⟩ <;> ext i <;> fin_cases i <;>
    simp [netA, netL, netU, netB, netσ, Matrix.mulVec, dotProduct, Fin.sum_univ_succ,
      Equiv.swap_apply_def] <;> norm_num

-- The other five patterns from the same L and U: night, midday, evening, weekend, fire at J2.
example : netA *ᵥ ![587/10, 286/5, 13, 5, 7] = netB 8 12 ∧
    netA *ᵥ ![1161/20, 279/5, 39/2, 15/2, 21/2] = netB 12 18 ∧
    netA *ᵥ ![561/10, 258/5, 39, 15, 21] = netB 24 36 ∧
    netA *ᵥ ![288/5, 276/5, 24, 8, 12] = netB 16 20 ∧
    netA *ᵥ ![1129/20, 247/5, 71/2, 47/2, 53/2] = netB 12 50 := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;> ext i <;> fin_cases i <;>
    simp [netA, netB, Matrix.mulVec, dotProduct, Fin.sum_univ_succ] <;> norm_num

-- Forgetting to reorder b: sweeping L and U on b itself gives (16, 52, 40, -20, 20),
-- which does not solve the morning system.
example : netL *ᵥ (netU *ᵥ ![16, 52, 40, -20, 20]) = netB 20 30 ∧
    netA *ᵥ ![16, 52, 40, -20, 20] ≠ netB 20 30 := by
  refine ⟨?_, ?_⟩
  · ext i; fin_cases i <;>
      simp [netL, netU, netB, Matrix.mulVec, dotProduct, Fin.sum_univ_succ] <;> norm_num
  · intro h
    have h0 := congrFun h 0
    simp [netA, netB, Matrix.mulVec, dotProduct, Fin.sum_univ_succ] at h0

-- Flop counts: factor (4n^3 - 3n^2 - n)/6, each solve 2n^2 - n, whole solve (4n^3 + 9n^2 - 7n)/6.
-- n = 5: factor 70, solve 45; six patterns: reuse 70 + 6 × 45 = 340 against refactor 6 × 115 = 690.
example : (4 * 5 ^ 3 - 3 * 5 ^ 2 - 5) / 6 = 70 ∧ 2 * 5 ^ 2 - 5 = 45 ∧
    (4 * 5 ^ 3 + 9 * 5 ^ 2 - 7 * 5) / 6 = 115 ∧ 70 + 6 * 45 = 340 ∧ 6 * 115 = 690 := by
  decide
-- n = 500: factor 83,208,250, solve 499,500; reuse 86,205,250, refactor 502,246,500;
-- inverse first 83,208,250 + 500 × 499,500 = 332,958,250.
example : (4 * 500 ^ 3 - 3 * 500 ^ 2 - 500) / 6 = 83208250 ∧ 2 * 500 ^ 2 - 500 = 499500 ∧
    83208250 + 6 * 499500 = 86205250 ∧
    6 * ((4 * 500 ^ 3 + 9 * 500 ^ 2 - 7 * 500) / 6) = 502246500 ∧
    83208250 + 500 * 499500 = 332958250 := by
  norm_num
-- n = 2,000: factor 5,331,333,000, solve 7,998,000, so 666 solves per factorisation.
example : (4 * 2000 ^ 3 - 3 * 2000 ^ 2 - 2000) / 6 = 5331333000 ∧
    2 * 2000 ^ 2 - 2000 = 7998000 ∧ 5331333000 / 7998000 = 666 := by
  norm_num

#print axioms lu_with_partial_pivoting_exists
#print axioms solve_by_two_triangle_sweeps
#print axioms det_eq_sign_mul_prod_pivots
