-- Correlated paths: every possible correlation table has exactly one lower-triangular factor with a positive diagonal, its rows have length one, any such factor proves the table possible, and the accumulated path shocks have covariance the correlation times the earlier date.
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.LinearAlgebra.Matrix.Block
import Mathlib.LinearAlgebra.Matrix.Symmetric
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Analysis.Matrix.LDL
import Mathlib.Tactic.LinearCombination
import Mathlib.Algebra.Order.Star.Real

open Matrix

/-! Matrices are real and square, indexed by `Fin n` (one row per share). `R.IsSymm` means
`Rᵀ = R`. Mathlib's `R.PosDef` means `R` is symmetric and every non-zero holding `x` has
positive variance `xᵀ R x > 0`. `L.IsLowerTriangular` means every entry above the diagonal is
zero. Row `i` of `L` dotted with row `j` is `∑ k, L i k * L j k`, which is entry `(i, j)` of
`L * Lᵀ`. -/

lemma cholesky_lower_mul_diag {n : ℕ} (A B : Matrix (Fin n) (Fin n) ℝ)
    (hA : A.IsLowerTriangular) (hB : B.IsLowerTriangular) (i : Fin n) :
    (A * B) i i = A i i * B i i := by
  rw [Matrix.mul_apply, Finset.sum_eq_single i]
  · intro k _ hk
    rcases lt_or_gt_of_ne hk with h | h
    · rw [hB (show OrderDual.toDual i < OrderDual.toDual k from h), mul_zero]
    · rw [hA (show OrderDual.toDual k < OrderDual.toDual i from h), zero_mul]
  · simp

lemma cholesky_det_pos_of_lower {n : ℕ} (L : Matrix (Fin n) (Fin n) ℝ)
    (hL : L.IsLowerTriangular) (hpos : ∀ i, 0 < L i i) : 0 < L.det := by
  rw [Matrix.det_of_isLowerTriangular L hL]
  exact Finset.prod_pos fun i _ => hpos i

#print axioms cholesky_lower_mul_diag
#print axioms cholesky_det_pos_of_lower

/-- The card's main claim. A correlation table `R` (symmetric, ones down the diagonal, every
non-zero holding of the shares given a positive variance) has exactly one mixing table `L`
that is lower triangular, has a positive diagonal and satisfies `R = L Lᵀ`: the Cholesky
factor. Any table `L` with `R = L Lᵀ` has every row of length one, which is what keeps each
share at its own volatility. -/
theorem correlation_matrix_has_unique_cholesky_factor {n : ℕ}
    (R : Matrix (Fin n) (Fin n) ℝ) (hsymm : R.IsSymm) (hdiag : ∀ i, R i i = 1)
    (hR : R.PosDef) :
    (∃! L : Matrix (Fin n) (Fin n) ℝ,
        L.IsLowerTriangular ∧ (∀ i, 0 < L i i) ∧ R = L * Lᵀ) ∧
      ∀ L : Matrix (Fin n) (Fin n) ℝ, R = L * Lᵀ → ∀ i, ∑ k, L i k ^ 2 = 1 := by
  have hsq : ∀ L : Matrix (Fin n) (Fin n) ℝ, R = L * Lᵀ → ∀ i, ∑ k, L i k ^ 2 = 1 := by
    intro L hL i
    rw [← hdiag i, hL, Matrix.mul_apply]
    simp [sq]
  refine ⟨?_, hsq⟩
  obtain ⟨L, hLt, hLp, hLR⟩ : ∃ L : Matrix (Fin n) (Fin n) ℝ,
      L.IsLowerTriangular ∧ (∀ i, 0 < L i i) ∧ R = L * Lᵀ := by
    set A := LDL.lower hR with hAdef
    have hAt : A.IsLowerTriangular := LDL.isLowerTriangular_lower hR
    have hD : (LDL.diag hR).PosDef := by
      rw [LDL.diag_eq_lowerInv_conj]
      exact hR.mul_mul_conjTranspose_same (Matrix.vecMul_injective_of_invertible _)
    have hd : ∀ i, 0 < LDL.diagEntries hR i := fun i => by
      have := hD.diag_pos (i := i)
      simpa [LDL.diag] using this
    have hAdet : A.det ≠ 0 := by
      have h1 : A * LDL.lowerInv hR = 1 := by
        rw [hAdef, LDL.lower]; exact Matrix.inv_mul_of_invertible _
      intro h0
      have := congrArg Matrix.det h1
      rw [Matrix.det_mul, h0, zero_mul, Matrix.det_one] at this
      exact zero_ne_one this
    have hAii : ∀ i, A i i ≠ 0 := by
      rw [Matrix.det_of_isLowerTriangular A hAt] at hAdet
      exact fun i => (Finset.prod_ne_zero_iff.1 hAdet) i (Finset.mem_univ i)
    let v : Fin n → ℝ := fun i =>
      (if 0 < A i i then (1 : ℝ) else -1) * Real.sqrt (LDL.diagEntries hR i)
    refine ⟨A * Matrix.diagonal v, ?_, ?_, ?_⟩
    · intro i j h
      rw [Matrix.mul_diagonal, hAt h, zero_mul]
    · intro i
      rw [Matrix.mul_diagonal]
      have hs := Real.sqrt_pos.2 (hd i)
      simp only [v]
      split_ifs with hA
      · nlinarith
      · have : A i i < 0 := lt_of_le_of_ne (not_lt.1 hA) (hAii i)
        nlinarith
    · have h1 := LDL.lower_conj_diag hR
      rw [Matrix.conjTranspose_eq_transpose_of_trivial] at h1
      have hvv : Matrix.diagonal v * (Matrix.diagonal v)ᵀ = LDL.diag hR := by
        rw [Matrix.diagonal_transpose, Matrix.diagonal_mul_diagonal, LDL.diag]
        congr 1
        funext i
        simp only [v]
        split_ifs <;> linear_combination Real.mul_self_sqrt (hd i).le
      calc R = A * LDL.diag hR * Aᵀ := h1.symm
        _ = A * (Matrix.diagonal v * (Matrix.diagonal v)ᵀ) * Aᵀ := by rw [hvv]
        _ = A * Matrix.diagonal v * (A * Matrix.diagonal v)ᵀ := by
          rw [Matrix.transpose_mul]; simp only [Matrix.mul_assoc]
  refine ⟨L, ⟨hLt, hLp, hLR⟩, ?_⟩
  rintro L' ⟨hL't, hL'p, hL'R⟩
  have hdetL := cholesky_det_pos_of_lower L hLt hLp
  let _ : Invertible L := Matrix.invertibleOfIsUnitDet L hdetL.ne'.isUnit
  set M := L⁻¹ * L' with hM
  have hLinv : (L⁻¹).IsLowerTriangular := blockTriangular_inv_of_blockTriangular hLt
  have hMt : M.IsLowerTriangular := hLinv.mul hL't
  have hMM : M * Mᵀ = 1 := by
    rw [hM, Matrix.transpose_mul, Matrix.transpose_nonsing_inv]
    calc L⁻¹ * L' * (L'ᵀ * Lᵀ⁻¹) = L⁻¹ * (L' * L'ᵀ) * Lᵀ⁻¹ := by simp only [Matrix.mul_assoc]
      _ = L⁻¹ * (L * Lᵀ) * Lᵀ⁻¹ := by rw [← hL'R, hLR]
      _ = 1 := by
        rw [← Matrix.mul_assoc, Matrix.inv_mul_of_invertible, Matrix.one_mul,
          Matrix.mul_inv_of_invertible]
  let _ : Invertible M := invertibleOfRightInverse M Mᵀ hMM
  have hMinvT : M⁻¹ = Mᵀ := Matrix.inv_eq_right_inv hMM
  have hMinv : (M⁻¹).IsLowerTriangular := blockTriangular_inv_of_blockTriangular hMt
  have hoff : ∀ i j, i ≠ j → M i j = 0 := by
    intro i j hij
    rcases lt_or_gt_of_ne hij with h | h
    · exact hMt (show OrderDual.toDual j < OrderDual.toDual i from h)
    · have := hMinv (show OrderDual.toDual i < OrderDual.toDual j from h)
      rw [hMinvT, Matrix.transpose_apply] at this
      exact this
  have hMpos : ∀ i, 0 < M i i := by
    intro i
    rw [hM, cholesky_lower_mul_diag _ _ hLinv hL't]
    have h1 : L⁻¹ i i * L i i = 1 := by
      rw [← cholesky_lower_mul_diag _ _ hLinv hLt, Matrix.inv_mul_of_invertible,
        Matrix.one_apply_eq]
    have h2 : 0 < L⁻¹ i i := by
      by_contra hc
      push Not at hc
      nlinarith [hLp i]
    exact mul_pos h2 (hL'p i)
  have hMone : M = 1 := by
    ext i j
    by_cases hij : i = j
    · subst hij
      have h := congrFun (congrFun hMM i) i
      rw [Matrix.mul_apply, Finset.sum_eq_single i, Matrix.one_apply_eq,
        Matrix.transpose_apply] at h
      · rw [Matrix.one_apply_eq]
        nlinarith [hMpos i]
      · intro k _ hk
        rw [Matrix.transpose_apply, hoff i k (Ne.symm hk), zero_mul]
      · simp
    · rw [hoff i j hij, Matrix.one_apply_ne hij]
  have : L' = L * M := by
    rw [hM, ← Matrix.mul_assoc, Matrix.mul_inv_of_invertible, Matrix.one_mul]
  rw [this, hMone, Matrix.mul_one]

/-- The converse the program relies on. If `R = L Lᵀ` for a lower-triangular `L` with a
positive diagonal, then every non-zero holding has positive variance under `R`: a run that
finishes with every pivot positive has proved the dial possible. -/
theorem posDef_of_lower_triangular_positive_diagonal_factor {n : ℕ}
    (L : Matrix (Fin n) (Fin n) ℝ) (hL : L.IsLowerTriangular) (hpos : ∀ i, 0 < L i i) :
    (L * Lᵀ).PosDef := by
  have hu : IsUnit L :=
    (Matrix.isUnit_iff_isUnit_det L).2 (cholesky_det_pos_of_lower L hL hpos).ne'.isUnit
  have h := Matrix.PosDef.mul_conjTranspose_self L (Matrix.vecMul_injective_iff_isUnit.2 hu)
  rwa [Matrix.conjTranspose_eq_transpose_of_trivial] at h

/-- The clock (Step 3). Fix grid steps of lengths `dt 0, …, dt (m-1)` years, so date `a` is
`t a = dt 0 + ⋯ + dt a`. Share `i`'s accumulated shock at date `a` puts weight
`√(dt k) · L i l` on step `k`'s draw `l` for every step `k ≤ a`, and nothing on later steps.
If `R = L Lᵀ`, the covariance of share `i` at date `a` with share `j` at date `b` (the dot
product of their weights) is `R i j · min (t a) (t b)`. -/
theorem grid_covariance_eq_correlation_mul_earlier_date {n m : ℕ}
    (R L : Matrix (Fin n) (Fin n) ℝ) (hRL : R = L * Lᵀ)
    (dt : Fin m → ℝ) (hdt : ∀ k, 0 ≤ dt k) (a b : Fin m) (i j : Fin n) :
    ∑ k : Fin m, ∑ l : Fin n,
        (if k ≤ a then Real.sqrt (dt k) * L i l else 0) *
          (if k ≤ b then Real.sqrt (dt k) * L j l else 0) =
      R i j * min (∑ k ∈ Finset.univ.filter (· ≤ a), dt k)
                  (∑ k ∈ Finset.univ.filter (· ≤ b), dt k) := by
  have hR : R i j = ∑ l, L i l * L j l := by
    rw [hRL, Matrix.mul_apply]; rfl
  have hterm : ∀ k : Fin m, ∑ l : Fin n,
      (if k ≤ a then Real.sqrt (dt k) * L i l else 0) *
        (if k ≤ b then Real.sqrt (dt k) * L j l else 0) =
      if k ≤ min a b then dt k * R i j else 0 := by
    intro k
    rw [hR]
    by_cases ha : k ≤ a <;> by_cases hb : k ≤ b <;> simp [ha, hb]
    rw [Finset.mul_sum]
    refine Finset.sum_congr rfl fun l _ => ?_
    linear_combination (L i l * L j l) * Real.mul_self_sqrt (hdt k)
  have hmin : min (∑ k ∈ Finset.univ.filter (· ≤ a), dt k)
      (∑ k ∈ Finset.univ.filter (· ≤ b), dt k) =
      ∑ k ∈ Finset.univ.filter (· ≤ min a b), dt k := by
    rcases le_total a b with h | h
    · rw [min_eq_left h, min_eq_left]
      apply Finset.sum_le_sum_of_subset_of_nonneg
      · intro k
        simp only [Finset.mem_filter, Finset.mem_univ, true_and]
        exact fun hk => hk.trans h
      · intro k _ _; exact hdt k
    · rw [min_eq_right h, min_eq_right]
      apply Finset.sum_le_sum_of_subset_of_nonneg
      · intro k
        simp only [Finset.mem_filter, Finset.mem_univ, true_and]
        exact fun hk => hk.trans h
      · intro k _ _; exact hdt k
  rw [Finset.sum_congr rfl (fun k _ => hterm k), hmin, Finset.sum_filter, Finset.mul_sum]
  refine Finset.sum_congr rfl fun k _ => ?_
  split_ifs <;> ring

/-! The card's exact worked numbers (rational, no decimals). -/

-- Every pair at one half, the correlation table used as the mixer by mistake: its rows have
-- squared length 3/2 (length 1.224745) and the pair agrees (5/4)/(3/2) = 5/6 = 0.833333.
example : (!![1, 1/2, 1/2; 1/2, 1, 1/2; 1/2, 1/2, 1] : Matrix (Fin 3) (Fin 3) ℚ) *
    (!![1, 1/2, 1/2; 1/2, 1, 1/2; 1/2, 1/2, 1] : Matrix (Fin 3) (Fin 3) ℚ)ᵀ =
    !![3/2, 5/4, 5/4; 5/4, 3/2, 5/4; 5/4, 5/4, 3/2] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_three]
example : ((5 : ℚ) / 4) / (3 / 2) = 5 / 6 := by norm_num

-- The impossible dial 0.9, 0.9, −0.9: the holding (1, −1, −1) has variance −2.4 = −12/5.
example : (let R : Matrix (Fin 3) (Fin 3) ℚ :=
      !![1, 9/10, 9/10; 9/10, 1, -9/10; 9/10, -9/10, 1]
    let x : Fin 3 → ℚ := ![1, -1, -1]
    ∑ i, ∑ j, x i * R i j * x j) = -12 / 5 := by
  simp [Fin.sum_univ_three]; norm_num

-- Its third pivot: second pivot 1 − 0.81 = 19/100, third-row second entry
-- (−0.9 − 0.81)/√(19/100), so the third pivot is 1 − 0.81 − (171/100)²/(19/100) = −15.2.
example : (1 : ℚ) - (9/10)^2 - (-9/10 - (9/10) * (9/10))^2 / (1 - (9/10)^2) = -76 / 5 := by
  norm_num

-- Try changing: every pair at −0.6 has third pivot 1 − 0.36 − 1.44 = −0.8.
example : (1 : ℚ) - (-3/5)^2 - (-3/5 - (-3/5) * (-3/5))^2 / (1 - (-3/5)^2) = -4 / 5 := by
  norm_num

-- The chart: the three-share average has variance σ²(1 + 2ρ)/3 in shock units; the factor
-- (1 + 2ρ)/3 is 0 at ρ = −1/2, 1/3 at ρ = 0, 2/3 at ρ = 1/2 and 1 at ρ = 1.
example : ((1 : ℚ) + 2 * (-1/2)) / 3 = 0 ∧ ((1 : ℚ) + 2 * 0) / 3 = 1 / 3 ∧
    ((1 : ℚ) + 2 * (1/2)) / 3 = 2 / 3 ∧ ((1 : ℚ) + 2 * 1) / 3 = 1 := by
  norm_num

#print axioms correlation_matrix_has_unique_cholesky_factor
#print axioms posDef_of_lower_triangular_positive_diagonal_factor
#print axioms grid_covariance_eq_correlation_mul_earlier_date
