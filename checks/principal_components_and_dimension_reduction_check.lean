-- Principal components: after every column is standardised, the correlation matrix's eigenvalues add up to the number of columns d, no r perpendicular directions keep a larger share of the variance than the top r eigenvalues over d, and the SVD of the table gives the same eigenvalues and components.
import Mathlib.Analysis.Matrix.Spectrum

open Matrix

namespace PrincipalComponentsReduction

variable {n d : ℕ}

/-- Column `j`'s mean `m_j` over the `n` orders. -/
noncomputable def colMean (x : Matrix (Fin n) (Fin d) ℝ) (j : Fin d) : ℝ :=
  (∑ i, x i j) / n

/-- Column `j`'s standard deviation `s_j`, with the `n - 1` divisor. -/
noncomputable def colSD (x : Matrix (Fin n) (Fin d) ℝ) (j : Fin d) : ℝ :=
  Real.sqrt ((∑ i, (x i j - colMean x j) ^ 2) / ((n : ℝ) - 1))

/-- The standardised table `Z`: `z_ij = (x_ij - m_j) / s_j`. -/
noncomputable def standardize (x : Matrix (Fin n) (Fin d) ℝ) : Matrix (Fin n) (Fin d) ℝ :=
  fun i j => (x i j - colMean x j) / colSD x j

/-- The matrix `R = (1/(n-1)) Zᵀ Z`; for a standardised table it is the correlation matrix. -/
noncomputable def corrMatrix (Z : Matrix (Fin n) (Fin d) ℝ) : Matrix (Fin d) (Fin d) ℝ :=
  (1 / ((n : ℝ) - 1)) • (Zᵀ * Z)

/-- The sample variance (divisor `n - 1`) of the scores `t_i = z_i · v` of all orders
along the direction `v`. -/
noncomputable def scoreVar (Z : Matrix (Fin n) (Fin d) ℝ) (v : Fin d → ℝ) : ℝ :=
  (∑ i, ((Z *ᵥ v) i - (∑ k, (Z *ᵥ v) k) / n) ^ 2) / ((n : ℝ) - 1)

/-- Indicator-sum reindexing. -/
theorem sum_ite_lt_eq_sum_castLE {m r : ℕ} (hr : r ≤ m) (g : Fin m → ℝ) :
    (∑ i : Fin m, if (i : ℕ) < r then g i else 0) = ∑ k : Fin r, g (Fin.castLE hr k) := by
  rw [← Finset.sum_filter]
  have : (Finset.univ.filter fun i : Fin m => (i : ℕ) < r) =
      Finset.univ.map (Fin.castLEEmb hr) := by
    ext i
    simp only [Finset.mem_filter, Finset.mem_univ, true_and, Finset.mem_map, Fin.castLEEmb_apply]
    constructor
    · intro h
      exact ⟨⟨i, h⟩, rfl⟩
    · rintro ⟨k, rfl⟩
      simp
  rw [this, Finset.sum_map]
  rfl

/-- Weights in `[0,1]` adding to `r`, against a decreasing list: at most the top `r`. -/
theorem sum_mul_le_top {m r : ℕ} (hr : r ≤ m) (f : Fin m → ℝ) (hf : Antitone f)
    (w : Fin m → ℝ) (h0 : ∀ i, 0 ≤ w i) (h1 : ∀ i, w i ≤ 1) (hsum : ∑ i, w i = r) :
    ∑ i, f i * w i ≤ ∑ k : Fin r, f (Fin.castLE hr k) := by
  rcases Nat.eq_zero_or_pos r with h | h
  · subst h
    have hw : ∀ i, w i = 0 := by
      intro i
      have := (Finset.sum_eq_zero_iff_of_nonneg (fun i _ => h0 i)).1 (by simpa using hsum) i
        (Finset.mem_univ _)
      exact this
    simp [hw]
  · set c := f ⟨r - 1, by omega⟩
    have key : ∀ i : Fin m, (f i - c) * w i ≤ if (i : ℕ) < r then f i - c else 0 := by
      intro i
      split_ifs with hi
      · have : c ≤ f i := hf (show i ≤ (⟨r - 1, by omega⟩ : Fin m) by
          rw [Fin.le_def]; simp; omega)
        nlinarith [h1 i]
      · have : f i ≤ c := hf (show (⟨r - 1, by omega⟩ : Fin m) ≤ i by
          rw [Fin.le_def]; simp; omega)
        nlinarith [h0 i]
    have h2 := Finset.sum_le_sum fun i (_ : i ∈ Finset.univ) => key i
    rw [sum_ite_lt_eq_sum_castLE hr] at h2
    simp only [sub_mul, Finset.sum_sub_distrib, ← Finset.mul_sum, hsum,
      Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul] at h2
    linarith

/-- `|A x|² = x · (Aᵀ A) x`. -/
theorem mulVec_dot_self {a b : Type*} [Fintype a] [Fintype b] (A : Matrix a b ℝ) (x : b → ℝ) :
    (A *ᵥ x) ⬝ᵥ (A *ᵥ x) = x ⬝ᵥ ((Aᵀ * A) *ᵥ x) := by
  rw [← mulVec_mulVec, dotProduct_mulVec, ← mulVec_transpose, dotProduct_comm]

/-- Bessel's inequality in matrix form. -/
theorem bessel_matrix {a b : Type*} [Fintype a] [Fintype b] [DecidableEq a]
    (V : Matrix a b ℝ) (hV : V * Vᵀ = 1) (x : b → ℝ) :
    (V *ᵥ x) ⬝ᵥ (V *ᵥ x) ≤ x ⬝ᵥ x := by
  set y := V *ᵥ x
  have hnn : 0 ≤ (x - Vᵀ *ᵥ y) ⬝ᵥ (x - Vᵀ *ᵥ y) :=
    Finset.sum_nonneg fun i _ => mul_self_nonneg _
  have e1 : x ⬝ᵥ (Vᵀ *ᵥ y) = y ⬝ᵥ y := by
    rw [dotProduct_mulVec, vecMul_transpose]
  have e2 : (Vᵀ *ᵥ y) ⬝ᵥ (Vᵀ *ᵥ y) = y ⬝ᵥ y := by
    rw [mulVec_dot_self, transpose_transpose, hV, one_mulVec]
  have e3 : (Vᵀ *ᵥ y) ⬝ᵥ x = y ⬝ᵥ y := by rw [dotProduct_comm, e1]
  rw [sub_dotProduct, dotProduct_sub, dotProduct_sub, e1, e2, e3] at hnn
  linarith


/-- Real spectral theorem in matrix form. -/
theorem spectral_real {ι : Type*} [Fintype ι] [DecidableEq ι] {R : Matrix ι ι ℝ}
    (hR : R.IsHermitian) :
    (hR.eigenvectorUnitary : Matrix ι ι ℝ)ᵀ * (hR.eigenvectorUnitary : Matrix ι ι ℝ) = 1 ∧
      (hR.eigenvectorUnitary : Matrix ι ι ℝ) * (hR.eigenvectorUnitary : Matrix ι ι ℝ)ᵀ = 1 ∧
      R = (hR.eigenvectorUnitary : Matrix ι ι ℝ) * diagonal hR.eigenvalues *
        (hR.eigenvectorUnitary : Matrix ι ι ℝ)ᵀ := by
  set U : Matrix ι ι ℝ := ↑hR.eigenvectorUnitary with hUdef
  have hs : star U = Uᵀ := by rw [star_eq_conjTranspose, conjTranspose_eq_transpose_of_trivial]
  have h1 : Uᵀ * U = 1 := by rw [← hs]; exact Unitary.coe_star_mul_self _
  have h2 : U * Uᵀ = 1 := by rw [← hs]; exact Unitary.coe_mul_star_self _
  have hRU : R * U = U * diagonal hR.eigenvalues := by
    ext i j
    have := congrFun (hR.mulVec_eigenvectorBasis j) i
    simp only [mulVec, dotProduct, Pi.smul_apply, smul_eq_mul] at this
    rw [Matrix.mul_diagonal, Matrix.mul_apply]
    simp only [U]
    exact this.trans (mul_comm _ _)
  refine ⟨h1, h2, ?_⟩
  calc R = R * (U * Uᵀ) := by rw [h2, Matrix.mul_one]
    _ = U * diagonal hR.eigenvalues * Uᵀ := by rw [← Matrix.mul_assoc, hRU]

/-- The quadratic form in eigen-coordinates. -/
theorem quad_eq {ι : Type*} [Fintype ι] [DecidableEq ι] {R : Matrix ι ι ℝ}
    (hR : R.IsHermitian) (v : ι → ℝ) :
    v ⬝ᵥ (R *ᵥ v) = ∑ j, hR.eigenvalues j *
      (((hR.eigenvectorUnitary : Matrix ι ι ℝ)ᵀ *ᵥ v) j) ^ 2 := by
  obtain ⟨-, -, h3⟩ := spectral_real hR
  conv_lhs => rw [h3]
  rw [← mulVec_mulVec, ← mulVec_mulVec, dotProduct_mulVec, ← mulVec_transpose]
  simp only [dotProduct, mulVec_diagonal]
  refine Finset.sum_congr rfl fun j _ => ?_
  ring

/-- Ky Fan upper bound. -/
theorem kyfan_le {r : ℕ} {R : Matrix (Fin d) (Fin d) ℝ} (hR : R.IsHermitian)
    (hr : r ≤ Fintype.card (Fin d)) (v : Fin r → Fin d → ℝ)
    (hv : ∀ k l, v k ⬝ᵥ v l = if k = l then 1 else 0) :
    ∑ k, v k ⬝ᵥ (R *ᵥ v k) ≤ ∑ k : Fin r, hR.eigenvalues₀ (Fin.castLE hr k) := by
  obtain ⟨h1, h2, -⟩ := spectral_real hR
  set U : Matrix (Fin d) (Fin d) ℝ := ↑hR.eigenvectorUnitary with hUdef
  set w : Fin d → ℝ := fun j => ∑ k, ((Uᵀ *ᵥ v k) j) ^ 2 with hwdef
  have hq : ∑ k, v k ⬝ᵥ (R *ᵥ v k) = ∑ j, hR.eigenvalues j * w j := by
    simp only [quad_eq hR, hwdef, Finset.mul_sum]
    exact Finset.sum_comm
  have hw0 : ∀ j, 0 ≤ w j := fun j => Finset.sum_nonneg fun k _ => sq_nonneg _
  have hw1 : ∀ j, w j ≤ 1 := by
    intro j
    let V : Matrix (Fin r) (Fin d) ℝ := Matrix.of v
    have hV : V * Vᵀ = 1 := by
      ext k l
      rw [mul_apply', Matrix.one_apply, ← hv k l]
      rfl
    have hb := bessel_matrix V hV (Uᵀ j)
    have hc : Uᵀ j ⬝ᵥ Uᵀ j = 1 := by
      have := congrFun (congrFun h1 j) j
      rw [mul_apply', Matrix.one_apply_eq] at this
      exact this
    have hw : w j = (V *ᵥ Uᵀ j) ⬝ᵥ (V *ᵥ Uᵀ j) := by
      simp only [hwdef, dotProduct, sq]
      refine Finset.sum_congr rfl fun k _ => ?_
      simp only [mulVec, dotProduct, V, of_apply, transpose_apply, mul_comm]
    rw [hw]
    linarith
  have hsum : ∑ j, w j = r := by
    simp only [hwdef]
    rw [Finset.sum_comm]
    have : ∀ k, ∑ j, ((Uᵀ *ᵥ v k) j) ^ 2 = 1 := by
      intro k
      have := mulVec_dot_self Uᵀ (v k)
      rw [transpose_transpose, h2, one_mulVec, hv k k] at this
      simpa [dotProduct, sq] using this
    simp [this]
  set e := Fintype.equivOfCardEq (Fintype.card_fin (Fintype.card (Fin d)))
  have he : ∀ i, hR.eigenvalues (e i) = hR.eigenvalues₀ i := by
    intro i
    simp [IsHermitian.eigenvalues, e]
  rw [hq, ← Equiv.sum_comp e]
  simp only [he]
  refine sum_mul_le_top hr _ hR.eigenvalues₀_antitone (fun i => w (e i)) (fun i => hw0 _)
    (fun i => hw1 _) ?_
  rw [Equiv.sum_comp e w, hsum]

/-- Ky Fan bound attained by the top eigenvectors. -/
theorem kyfan_attained {r : ℕ} {R : Matrix (Fin d) (Fin d) ℝ} (hR : R.IsHermitian)
    (hr : r ≤ Fintype.card (Fin d)) :
    ∃ v : Fin r → Fin d → ℝ, (∀ k l, v k ⬝ᵥ v l = if k = l then 1 else 0) ∧
      ∑ k, v k ⬝ᵥ (R *ᵥ v k) = ∑ k : Fin r, hR.eigenvalues₀ (Fin.castLE hr k) := by
  obtain ⟨h1, -, -⟩ := spectral_real hR
  set U : Matrix (Fin d) (Fin d) ℝ := ↑hR.eigenvectorUnitary with hUdef
  set e := Fintype.equivOfCardEq (Fintype.card_fin (Fintype.card (Fin d)))
  have he : ∀ i, hR.eigenvalues (e i) = hR.eigenvalues₀ i := by
    intro i
    simp [IsHermitian.eigenvalues, e]
  have hon : ∀ a b, Uᵀ a ⬝ᵥ Uᵀ b = if a = b then 1 else 0 := by
    intro a b
    have := congrFun (congrFun h1 a) b
    rw [mul_apply', Matrix.one_apply] at this
    exact this
  refine ⟨fun k => Uᵀ (e (Fin.castLE hr k)), ?_, ?_⟩
  · intro k l
    rw [hon]
    simp [Fin.castLE_inj]
  · refine Finset.sum_congr rfl fun k _ => ?_
    have hb : R *ᵥ Uᵀ (e (Fin.castLE hr k)) =
        hR.eigenvalues (e (Fin.castLE hr k)) • Uᵀ (e (Fin.castLE hr k)) :=
      hR.mulVec_eigenvectorBasis _
    rw [hb, dotProduct_smul, hon]; simp [he]


/-- With centred columns, the score variance is the quadratic form of `R`. -/
theorem scoreVar_standardize (x : Matrix (Fin n) (Fin d) ℝ) (hn : 2 ≤ n) (v : Fin d → ℝ) :
    scoreVar (standardize x) v = v ⬝ᵥ (corrMatrix (standardize x) *ᵥ v) := by
  have hn0 : (n : ℝ) ≠ 0 := by positivity
  have hcol : ∀ j, ∑ i, standardize x i j = 0 := by
    intro j
    simp only [standardize]
    rw [← Finset.sum_div, Finset.sum_sub_distrib, Finset.sum_const, Finset.card_univ,
      Fintype.card_fin, nsmul_eq_mul, colMean, mul_div_cancel₀ _ hn0, sub_self, zero_div]
  have hsum : ∑ k, (standardize x *ᵥ v) k = 0 := by
    simp only [mulVec, dotProduct]
    rw [Finset.sum_comm]
    simp [← Finset.sum_mul, hcol]
  rw [scoreVar, hsum, zero_div, corrMatrix, smul_mulVec, dotProduct_smul,
    ← mulVec_dot_self]
  simp only [sub_zero, smul_eq_mul, dotProduct, sq]
  ring

#print axioms sum_ite_lt_eq_sum_castLE
#print axioms sum_mul_le_top
#print axioms mulVec_dot_self
#print axioms bessel_matrix
#print axioms spectral_real
#print axioms quad_eq
#print axioms kyfan_le
#print axioms kyfan_attained
#print axioms scoreVar_standardize

/-- The card's main claim. Standardise every column (at least two orders, no constant column)
and form the correlation matrix `R`. Over every choice of `r` perpendicular unit directions,
the largest share of the total variance `d` that their scores keep is
`share(r) = (λ₁ + … + λᵣ) / d`, the top `r` eigenvalues of `R` over `d`
(`eigenvalues₀` lists them from largest down). So no `r` directions beat the top `r`
eigenvectors, and choosing `r` for a target share is reading this running total. -/
theorem top_r_components_keep_largest_share (x : Matrix (Fin n) (Fin d) ℝ)
    (hn : 2 ≤ n) (hsd : ∀ j, colSD x j ≠ 0)
    (hR : (corrMatrix (standardize x)).IsHermitian)
    (r : ℕ) (hr : r ≤ Fintype.card (Fin d)) :
    IsGreatest
      {s : ℝ | ∃ v : Fin r → Fin d → ℝ,
        (∀ k l, v k ⬝ᵥ v l = if k = l then 1 else 0) ∧
          s = (∑ k, scoreVar (standardize x) (v k)) / d}
      ((∑ k : Fin r, hR.eigenvalues₀ (Fin.castLE hr k)) / d) := by
  constructor
  · obtain ⟨v, hv, hsum⟩ := kyfan_attained hR hr
    refine ⟨v, hv, ?_⟩
    simp only [scoreVar_standardize x hn, hsum]
  · rintro s ⟨v, hv, rfl⟩
    simp only [scoreVar_standardize x hn]
    exact div_le_div_of_nonneg_right (kyfan_le hR hr v hv) (Nat.cast_nonneg _)

/-- Standardised covariance is correlation, and the total is `d`: after standardising,
`R` has ones on its diagonal, its trace is the number of columns `d`, and its eigenvalues
share out exactly `d` units of variance. -/
theorem standardized_total_variance_eq_num_columns (x : Matrix (Fin n) (Fin d) ℝ)
    (hn : 2 ≤ n) (hsd : ∀ j, colSD x j ≠ 0)
    (hR : (corrMatrix (standardize x)).IsHermitian) :
    (∀ j, corrMatrix (standardize x) j j = 1) ∧
      (corrMatrix (standardize x)).trace = d ∧
      ∑ j, hR.eigenvalues j = d := by
  have hn1 : (0 : ℝ) < (n : ℝ) - 1 := by
    have : (2 : ℝ) ≤ n := by exact_mod_cast hn
    linarith
  have hdiag : ∀ j, corrMatrix (standardize x) j j = 1 := by
    intro j
    set S := ∑ i, (x i j - colMean x j) ^ 2 with hS
    have hS0 : 0 ≤ S / ((n : ℝ) - 1) := div_nonneg (Finset.sum_nonneg fun i _ => sq_nonneg _)
      hn1.le
    have hsq : colSD x j ^ 2 = S / ((n : ℝ) - 1) := Real.sq_sqrt hS0
    have hSne : S ≠ 0 := by
      intro h
      apply hsd j
      simp [colSD, ← hS, h]
    have hsdne := hsd j
    rw [corrMatrix, Matrix.smul_apply, Matrix.mul_apply]
    simp only [transpose_apply, standardize, smul_eq_mul]
    have : ∑ i, (x i j - colMean x j) / colSD x j * ((x i j - colMean x j) / colSD x j) =
        S / colSD x j ^ 2 := by
      rw [hS, Finset.sum_div]
      refine Finset.sum_congr rfl fun i _ => ?_
      ring
    rw [this, hsq]
    field_simp
  refine ⟨hdiag, ?_, ?_⟩
  · simp [trace, hdiag]
  · have := hR.trace_eq_sum_eigenvalues
    simp only [RCLike.ofReal_real_eq_id, id] at this
    rw [← this]
    simp [trace, hdiag]

/-- The SVD road: if the table is `Z = U S Vᵀ`, where `U` and `V` have perpendicular unit
columns and `S` is diagonal with entries `s_k`, then `R = (1/(n-1)) Zᵀ Z = V (S²/(n-1)) Vᵀ`,
so each column of `V` is a component and its eigenvalue is `s_k² / (n - 1)`. -/
theorem svd_gives_components (Z : Matrix (Fin n) (Fin d) ℝ)
    (U : Matrix (Fin n) (Fin d) ℝ) (s : Fin d → ℝ) (V : Matrix (Fin d) (Fin d) ℝ)
    (hU : Uᵀ * U = 1) (hV : Vᵀ * V = 1) (hZ : Z = U * diagonal s * Vᵀ) :
    corrMatrix Z = V * diagonal (fun k => s k ^ 2 / ((n : ℝ) - 1)) * Vᵀ ∧
      ∀ k, corrMatrix Z *ᵥ (fun j => V j k) =
        (s k ^ 2 / ((n : ℝ) - 1)) • (fun j => V j k) := by
  have hZt : Zᵀ * Z = V * diagonal (fun k => s k ^ 2) * Vᵀ := by
    rw [hZ]
    simp only [transpose_mul, transpose_transpose, diagonal_transpose]
    calc _ = V * diagonal s * (Uᵀ * U) * diagonal s * Vᵀ := by simp only [Matrix.mul_assoc]
      _ = V * diagonal (fun k => s k ^ 2) * Vᵀ := by
        rw [hU, Matrix.mul_one, Matrix.mul_assoc V, diagonal_mul_diagonal]
        congr 3
        funext k
        ring
  have hD : diagonal (fun k => s k ^ 2 / ((n : ℝ) - 1)) =
      (1 / ((n : ℝ) - 1)) • diagonal (fun k => s k ^ 2) := by
    ext i j
    by_cases h : i = j
    · subst h; simp; ring
    · simp [h]
  have h1 : corrMatrix Z = V * diagonal (fun k => s k ^ 2 / ((n : ℝ) - 1)) * Vᵀ := by
    rw [corrMatrix, hZt, hD, Matrix.mul_smul, Matrix.smul_mul]
  refine ⟨h1, fun k => ?_⟩
  have hcol : (fun j => V j k) = V *ᵥ Pi.single k 1 := by
    rw [mulVec_single_one]; rfl
  rw [h1, hcol, mulVec_mulVec, Matrix.mul_assoc, Matrix.mul_assoc, hV, Matrix.mul_one,
    ← mulVec_mulVec, diagonal_mulVec_single, mul_one, ← mulVec_smul]
  congr 1
  ext i
  by_cases h : i = k
  · subst h; simp
  · simp [h]

#print axioms top_r_components_keep_largest_share
#print axioms standardized_total_variance_eq_num_columns
#print axioms svd_gives_components

end PrincipalComponentsReduction
