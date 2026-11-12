-- Cholesky: a symmetric matrix has a factor A = L Lᵀ (L lower triangular, positive diagonal) exactly when it is positive definite, every entry of such a factor is at most the square root of its row's diagonal entry of A, each pivot is a ratio of leading determinants, and the flop count is about half of LU's.
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.LinearAlgebra.Matrix.Block
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Analysis.Matrix.LDL
import Mathlib.Algebra.Order.Star.Real
import Mathlib.Tactic.NormNum

open Matrix Filter Topology

/-! Matrices are real and square, indexed by `Fin n`. Mathlib's `A.PosDef` is "positive
definite": `A` is symmetric (`IsHermitian`, which over ℝ means `Aᵀ = A`) and every nonzero mix
`x` gives `xᵀ A x > 0`. `L.IsLowerTriangular` means every entry above the diagonal is zero.
The top-left `k`-by-`k` block of `A` is `A.submatrix (Fin.castLE h) (Fin.castLE h)`. -/

theorem cholesky_exists_of_posDef {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (hA : A.PosDef) :
    ∃ L : Matrix (Fin n) (Fin n) ℝ, L.IsLowerTriangular ∧ (∀ i, 0 < L i i) ∧ A = L * Lᵀ := by
  set d := LDL.diagEntries hA
  have hD : LDL.diag hA = diagonal d := rfl
  have hdpos : ∀ i, 0 < d i := by
    intro i
    have hP : (LDL.diag hA).PosDef := by
      rw [LDL.diag_eq_lowerInv_conj]
      exact hA.mul_mul_conjTranspose_same (vecMul_injective_of_invertible _)
    have := hP.diag_pos (i := i)
    simpa [hD] using this
  set L1 := LDL.lower hA * diagonal (fun i => Real.sqrt (d i))
  have hL1 : L1.IsLowerTriangular :=
    (LDL.isLowerTriangular_lower hA).mul (blockTriangular_diagonal _)
  have hA1 : A = L1 * L1ᵀ := by
    have h := LDL.lower_conj_diag hA
    rw [conjTranspose_eq_transpose_of_trivial] at h
    have hd : diagonal d = diagonal (fun i => √(d i)) * (diagonal (fun i => √(d i)))ᵀ := by
      rw [diagonal_transpose, diagonal_mul_diagonal]
      congr 1; ext i; exact (Real.mul_self_sqrt (hdpos i).le).symm
    rw [hD, hd] at h
    rw [← h]
    simp only [L1, transpose_mul, Matrix.mul_assoc]
  have hdet : ∀ i, L1 i i ≠ 0 := by
    have : L1.det ≠ 0 := by
      intro h0
      have := hA.det_pos
      rw [hA1, det_mul, det_transpose, h0] at this; simp at this
    rw [det_of_isLowerTriangular _ hL1] at this
    exact fun i => (Finset.prod_ne_zero_iff.mp this) i (Finset.mem_univ _)
  set s : Fin n → ℝ := fun i => if 0 < L1 i i then 1 else -1
  have hss : diagonal s * (diagonal s)ᵀ = 1 := by
    rw [diagonal_transpose, diagonal_mul_diagonal, ← diagonal_one]
    congr 1; ext i; simp only [s]; split_ifs <;> norm_num
  refine ⟨L1 * diagonal s, hL1.mul (blockTriangular_diagonal _), ?_, ?_⟩
  · intro i
    simp only [mul_diagonal, s]
    have := hdet i
    split_ifs with h
    · simpa using h
    · have : L1 i i < 0 := lt_of_le_of_ne (not_lt.mp h) this
      linarith
  · rw [transpose_mul, Matrix.mul_assoc, ← Matrix.mul_assoc (diagonal s), hss, Matrix.one_mul]
    exact hA1

theorem posDef_of_cholesky {n : ℕ} (L : Matrix (Fin n) (Fin n) ℝ)
    (hL : L.IsLowerTriangular) (hpos : ∀ i, 0 < L i i) : (L * Lᵀ).PosDef := by
  have hu : IsUnit L := by
    rw [isUnit_iff_isUnit_det, det_of_isLowerTriangular _ hL, isUnit_iff_ne_zero]
    exact Finset.prod_ne_zero_iff.mpr fun i _ => (hpos i).ne'
  have := PosDef.mul_conjTranspose_self L (vecMul_injective_iff_isUnit.mpr hu)
  rwa [conjTranspose_eq_transpose_of_trivial] at this

theorem entry_le_sqrt_diag {n : ℕ} (A L : Matrix (Fin n) (Fin n) ℝ) (hA : A = L * Lᵀ)
    (i j : Fin n) : |L i j| ≤ Real.sqrt (A i i) := by
  apply Real.abs_le_sqrt
  rw [hA, Matrix.mul_apply]
  simp only [transpose_apply]
  rw [sq]
  exact Finset.single_le_sum (f := fun k => L i k * L i k) (fun k _ => mul_self_nonneg _)
    (Finset.mem_univ j)

theorem leading_block_det {n m : ℕ} (A L : Matrix (Fin n) (Fin n) ℝ) (hL : L.IsLowerTriangular)
    (hA : A = L * Lᵀ) (h : m ≤ n) :
    (A.submatrix (Fin.castLE h) (Fin.castLE h)).det = (∏ i : Fin m, L (Fin.castLE h i) (Fin.castLE h i)) ^ 2 := by
  set M := L.submatrix (Fin.castLE h) (Fin.castLE h)
  have hM : M.IsLowerTriangular := by
    intro i j hij
    exact hL hij
  have hsub : A.submatrix (Fin.castLE h) (Fin.castLE h) = M * Mᵀ := by
    ext i j
    simp only [hA, submatrix_apply, Matrix.mul_apply, transpose_apply, M]
    symm
    apply Fintype.sum_of_injective (Fin.castLE h) (Fin.castLE_injective h)
    · intro l hl
      have hil : Fin.castLE h i < l := by
        by_contra hc
        apply hl
        refine ⟨⟨l, ?_⟩, ?_⟩
        · have := i.isLt; simp [Fin.lt_def] at hc; omega
        · ext; simp
      rw [hL (by simpa using hil), zero_mul]
    · intro l; rfl
  rw [hsub, det_mul, det_transpose, det_of_isLowerTriangular _ hM, sq]
  rfl

#print axioms cholesky_exists_of_posDef
#print axioms posDef_of_cholesky
#print axioms entry_le_sqrt_diag
#print axioms leading_block_det

/-- The Cholesky factor, as a test and as a bound. For a symmetric matrix `A`:
a lower-triangular `L` with a positive diagonal and `A = L Lᵀ` exists exactly when `A` is
positive definite (so a failed run means "not positive definite"); and every entry of a
factor `A = L Lᵀ` obeys `|ℓ_ij| ≤ √a_ii`, so no entry can grow and no pivoting is needed. -/
theorem cholesky_factor_iff_posDef_and_entries_bounded {n : ℕ}
    (A : Matrix (Fin n) (Fin n) ℝ) (hA : A.IsSymm) :
    (A.PosDef ↔ ∃ L : Matrix (Fin n) (Fin n) ℝ,
        L.IsLowerTriangular ∧ (∀ i, 0 < L i i) ∧ A = L * Lᵀ) ∧
    ∀ L : Matrix (Fin n) (Fin n) ℝ, A = L * Lᵀ → ∀ i j, |L i j| ≤ Real.sqrt (A i i) := by
  refine ⟨⟨fun h => cholesky_exists_of_posDef A h, ?_⟩, fun L hL i j => entry_le_sqrt_diag A L hL i j⟩
  rintro ⟨L, hL, hpos, rfl⟩
  exact posDef_of_cholesky L hL hpos

/-- The pivots measure the distance to the edge. If `A = L Lᵀ` with `L` lower triangular and
a positive diagonal, then `det A = (ℓ₁₁ ℓ₂₂ ⋯ ℓ_nn)²`, and the pivot `ℓ_kk²` of each column
equals the determinant of the top-left block that ends at that column divided by the
determinant of the block just before it (counting columns from 0 here: column `k` uses the
blocks of sizes `k + 1` and `k`). -/
theorem cholesky_pivot_eq_ratio_of_leading_dets {n : ℕ}
    (A L : Matrix (Fin n) (Fin n) ℝ) (hL : L.IsLowerTriangular) (hpos : ∀ i, 0 < L i i)
    (hA : A = L * Lᵀ) :
    A.det = (∏ i, L i i) ^ 2 ∧
    ∀ (k : ℕ) (hk : k < n),
      L ⟨k, hk⟩ ⟨k, hk⟩ ^ 2 =
        (A.submatrix (Fin.castLE hk) (Fin.castLE hk)).det /
          (A.submatrix (Fin.castLE hk.le) (Fin.castLE hk.le)).det := by
  refine ⟨?_, ?_⟩
  · rw [hA, det_mul, det_transpose, det_of_isLowerTriangular _ hL, sq]
  · intro k hk
    rw [leading_block_det (m := k + 1) A L hL hA hk, leading_block_det (m := k) A L hL hA hk.le,
      Fin.prod_univ_castSucc]
    have hne : ∏ i : Fin k, L (Fin.castLE hk.le i) (Fin.castLE hk.le i) ≠ 0 :=
      Finset.prod_ne_zero_iff.mpr fun i _ => (hpos _).ne'
    have e1 : ∀ i : Fin k, Fin.castLE hk (Fin.castSucc i) = Fin.castLE hk.le i := fun i => rfl
    have e2 : Fin.castLE hk (Fin.last k) = ⟨k, hk⟩ := rfl
    simp only [e1, e2]
    field_simp

/-- The cost. Column `j` (from 1) of the Cholesky run costs `(2j − 1)(n − j + 1)` flops, so the
whole run costs `(2n³ + 3n² + n)/6`; LU's step removing `m` entries costs `m + 2m²`, so LU costs
`(4n³ − 3n² − n)/6`; and the ratio of the two tends to one half as `n → ∞`. -/
theorem cholesky_costs_half_of_lu :
    (∀ n : ℕ, ∑ j ∈ Finset.Icc 1 n, (2 * (j : ℝ) - 1) * ((n : ℝ) - j + 1) =
        (2 * (n : ℝ) ^ 3 + 3 * n ^ 2 + n) / 6) ∧
    (∀ n : ℕ, ∑ m ∈ Finset.range n, ((m : ℝ) + 2 * m ^ 2) =
        (4 * (n : ℝ) ^ 3 - 3 * n ^ 2 - n) / 6) ∧
    Tendsto (fun n : ℕ => ((2 * (n : ℝ) ^ 3 + 3 * n ^ 2 + n) / 6) /
        ((4 * (n : ℝ) ^ 3 - 3 * n ^ 2 - n) / 6)) atTop (𝓝 (1 / 2)) := by
  refine ⟨?_, ?_, ?_⟩
  · have gen : ∀ (x : ℝ) (N : ℕ), ∑ k ∈ Finset.range N, (2 * (k : ℝ) + 1) * (x - k) =
        x * N ^ 2 - ((N : ℝ) - 1) * N * (2 * N - 1) / 3 - (N : ℝ) * (N - 1) / 2 := by
      intro x N
      induction N with
      | zero => simp
      | succ N ih => rw [Finset.sum_range_succ, ih]; push_cast; ring
    intro n
    have e : Finset.Icc 1 n = Finset.Ico 1 (n + 1) := rfl
    rw [e, Finset.sum_Ico_eq_sum_range, Nat.add_sub_cancel]
    have := gen n n
    calc _ = ∑ k ∈ Finset.range n, (2 * (k : ℝ) + 1) * ((n : ℝ) - k) := by
          apply Finset.sum_congr rfl; intro k _; push_cast; ring
      _ = _ := by rw [this]; ring
  · intro n
    induction n with
    | zero => simp
    | succ n ih => rw [Finset.sum_range_succ, ih]; push_cast; ring
  · have h : Tendsto (fun n : ℕ => (1 : ℝ) / n) atTop (𝓝 0) := tendsto_one_div_atTop_nhds_zero_nat
    have key : Tendsto (fun n : ℕ => (2 + 3 * (1 / (n : ℝ)) + (1 / (n : ℝ)) ^ 2) /
        (4 - 3 * (1 / (n : ℝ)) - (1 / (n : ℝ)) ^ 2)) atTop
        (𝓝 ((2 + 3 * 0 + 0 ^ 2) / (4 - 3 * 0 - 0 ^ 2))) := by
      apply Tendsto.div _ _ (by norm_num)
      · exact (tendsto_const_nhds.add (h.const_mul 3)).add (h.pow 2)
      · exact (tendsto_const_nhds.sub (h.const_mul 3)).sub (h.pow 2)
    have e : ((2 : ℝ) + 3 * 0 + 0 ^ 2) / (4 - 3 * 0 - 0 ^ 2) = 1 / 2 := by norm_num
    rw [e] at key
    refine key.congr' ?_
    filter_upwards [eventually_ge_atTop 2] with n hn
    have hn' : (2 : ℝ) ≤ n := by exact_mod_cast hn
    have hpos : (0 : ℝ) < n := by linarith
    have hden : (4 * (n : ℝ) ^ 3 - 3 * n ^ 2 - n) ≠ 0 := by
      have h1 : 0 < (n : ℝ) * (4 * n + 1) * (n - 1) :=
        mul_pos (mul_pos hpos (by linarith)) (by linarith)
      have h2 : (4 * (n : ℝ) ^ 3 - 3 * n ^ 2 - n) = (n : ℝ) * (4 * n + 1) * (n - 1) := by ring
      rw [h2]; exact h1.ne'
    have hden2 : (4 - 3 * (1 / (n : ℝ)) - (1 / (n : ℝ)) ^ 2) ≠ 0 := by
      intro h0
      apply hden
      have : (4 * (n : ℝ) ^ 3 - 3 * n ^ 2 - n) = n ^ 3 * (4 - 3 * (1 / (n : ℝ)) - (1 / (n : ℝ)) ^ 2) := by
        field_simp
      rw [this, h0, mul_zero]
    rw [div_eq_div_iff hden2 (by positivity)]
    field_simp

/-! The card's worked numbers. The covariance matrix in percent squared is
`A = !![400, 360, 140; 360, 900, 375; 140, 375, 625]`; the Acme–Cobalt entry is `750 ρ₂₃`. -/

-- The factor by hand: rows (20, 0, 0), (18, 24, 0), (7, 10.375, √468.359375), and L Lᵀ = A.
example :
    !![(20 : ℝ), 0, 0; 18, 24, 0; 7, 83 / 8, Real.sqrt (29975 / 64)] *
      (!![(20 : ℝ), 0, 0; 18, 24, 0; 7, 83 / 8, Real.sqrt (29975 / 64)])ᵀ =
      !![(400 : ℝ), 360, 140; 360, 900, 375; 140, 375, 625] := by
  have hs : Real.sqrt (29975 / 64) * Real.sqrt (29975 / 64) = 29975 / 64 :=
    Real.mul_self_sqrt (by norm_num)
  generalize Real.sqrt (29975 / 64) = s at hs ⊢
  ext i j
  fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_three] <;> linarith

-- The first two pivots multiply to the top-left 2-by-2 determinant: 400 × 576 = 230,400.
example : (400 : ℝ) * 576 = !![(400 : ℝ), 360; 360, 900].det := by rw [Matrix.det_fin_two_of]; norm_num

-- Third pivot = det A ÷ 230,400 = 468.359375 = 29975/64 at ρ₂₃ = 0.5.
example : !![(400 : ℝ), 360, 140; 360, 900, 375; 140, 375, 625].det / 230400 = 29975 / 64 := by
  rw [Matrix.det_fin_three]; simp; norm_num

-- ρ₂₃ = 0.9: third pivot 52.734375 = 3375/64, passes.
example : !![(400 : ℝ), 360, 140; 360, 900, 675; 140, 675, 625].det / 230400 = 3375 / 64 := by
  rw [Matrix.det_fin_three]; simp; norm_num

-- ρ₂₃ = 0.936: the edge, third pivot exactly 0, fails.
example : !![(400 : ℝ), 360, 140; 360, 900, 702; 140, 702, 625].det = 0 := by rw [Matrix.det_fin_three]; simp; norm_num

-- ρ₂₃ = 0.94: third pivot −6.015625 = −385/64, fails.
example : !![(400 : ℝ), 360, 140; 360, 900, 705; 140, 705, 625].det / 230400 = -385 / 64 := by
  rw [Matrix.det_fin_three]; simp; norm_num

-- ρ₂₃ = 0.95: third pivot −21.19140625 = −5425/256, fails.
example :
    !![(400 : ℝ), 360, 140; 360, 900, 1425 / 2; 140, 1425 / 2, 625].det / 230400 = -5425 / 256 := by
  rw [Matrix.det_fin_three]; simp; norm_num

-- Flops at n = 3: Cholesky 14, LU 13, counted column by column.
example : ∑ j ∈ Finset.Icc 1 3, (2 * j - 1) * (3 - j + 1) = 14 := by decide
example : ∑ m ∈ Finset.range 3, (m + 2 * m ^ 2) = 13 := by decide

-- Flops at n = 40 and n = 500 from the two formulas.
example : (2 * 40 ^ 3 + 3 * 40 ^ 2 + 40) / 6 = 22140 ∧ (4 * 40 ^ 3 - 3 * 40 ^ 2 - 40) / 6 = 41860 := by
  norm_num
example : (2 * 500 ^ 3 + 3 * 500 ^ 2 + 500) / 6 = 41791750 ∧
    (4 * 500 ^ 3 - 3 * 500 ^ 2 - 500) / 6 = 83208250 := by
  norm_num

#print axioms cholesky_factor_iff_posDef_and_entries_bounded
#print axioms cholesky_pivot_eq_ratio_of_leading_dets
#print axioms cholesky_costs_half_of_lu
