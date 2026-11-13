-- Multivariate normal: independent standard normal draws mixed by a matrix L and shifted by μ have the multivariate normal law N(μ, L Lᵀ), a fixed linear mix a + B X of such a vector is again normal with law N(a + B μ, B Σ Bᵀ), and a matrix has a unique lower-triangular Cholesky factor with positive diagonal exactly when it is positive definite.
import Mathlib.Probability.Distributions.Gaussian.Multivariate
import Mathlib.Analysis.Matrix.LDL
import Mathlib.Probability.Independence.Basic
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Data.Matrix.Mul
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory Matrix

open scoped MatrixOrder RealInnerProductSpace

lemma mvn_inner_mulVec {ι κ : Type*} [Fintype ι] [Fintype κ] (M : Matrix ι κ ℝ)
    (x : EuclideanSpace ℝ κ) (t : EuclideanSpace ℝ ι) :
    ⟪WithLp.toLp 2 (M *ᵥ x.ofLp), t⟫ = ⟪x, WithLp.toLp 2 (Mᵀ *ᵥ t.ofLp)⟫ := by
  simp only [PiLp.inner_apply, RCLike.inner_apply, conj_trivial, Matrix.mulVec, dotProduct,
    transpose_apply, Finset.mul_sum, Finset.sum_mul]
  rw [Finset.sum_comm]
  refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => ?_
  ring

#print axioms mvn_inner_mulVec

lemma mvn_map_std {ι κ : Type*} [Fintype ι] [DecidableEq ι] [Fintype κ]
    (c : EuclideanSpace ℝ ι) (M : Matrix ι κ ℝ) :
    (stdGaussian (EuclideanSpace ℝ κ)).map (fun x ↦ c + WithLp.toLp 2 (M *ᵥ x.ofLp)) =
      multivariateGaussian c (M * Mᵀ) := by
  have hcont : Continuous (fun x : EuclideanSpace ℝ κ ↦ c + WithLp.toLp 2 (M *ᵥ x.ofLp)) := by
    fun_prop
  have hpsd : (M * Mᵀ).PosSemidef := by
    simpa [conjTranspose_eq_transpose_of_trivial] using posSemidef_self_mul_conjTranspose M
  apply Measure.ext_of_charFun
  ext t
  rw [charFun_multivariateGaussian hpsd, charFun_apply,
    integral_map hcont.measurable.aemeasurable (by fun_prop)]
  simp_rw [inner_add_left, mvn_inner_mulVec, Complex.ofReal_add, add_mul, Complex.exp_add]
  rw [integral_const_mul, ← charFun_apply, charFun_stdGaussian, ← Complex.exp_add]
  congr 1
  have hn : ‖WithLp.toLp 2 (Mᵀ *ᵥ t.ofLp)‖ ^ 2 = t.ofLp ⬝ᵥ (M * Mᵀ) *ᵥ t.ofLp := by
    rw [EuclideanSpace.real_norm_sq_eq, ← Matrix.mulVec_mulVec, dotProduct_mulVec,
      ← mulVec_transpose]
    simp [dotProduct, sq]
  rw [← hn, real_inner_comm c t]
  push_cast
  ring

#print axioms mvn_map_std

lemma mvn_aemeasurable_of_map_eq_gaussianReal {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] {Y : Ω → ℝ} (h : P.map Y = gaussianReal 0 1) :
    AEMeasurable Y P := by
  by_contra hY
  rw [Measure.map_of_not_aemeasurable_of_ne_zero hY (IsProbabilityMeasure.ne_zero P)] at h
  have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  have h1 := congrArg (fun m : Measure ℝ => m {(0 : ℝ) + Classical.ofNonempty}) h
  simp at h1

#print axioms mvn_aemeasurable_of_map_eq_gaussianReal

lemma chol_det_pos {n : ℕ} {L : Matrix (Fin n) (Fin n) ℝ} (hL : ∀ i j, i < j → L i j = 0)
    (hd : ∀ i, 0 < L i i) : 0 < L.det := by
  rw [det_of_isLowerTriangular L (fun i j hij => hL i j (by simpa using hij))]
  exact Finset.prod_pos fun i _ => hd i

#print axioms chol_det_pos

lemma chol_unique {n : ℕ} {A B : Matrix (Fin n) (Fin n) ℝ}
    (hA : ∀ i j, i < j → A i j = 0) (hAd : ∀ i, 0 < A i i)
    (hB : ∀ i j, i < j → B i j = 0) (hBd : ∀ i, 0 < B i i)
    (h : A * Aᵀ = B * Bᵀ) : A = B := by
  have hAu : IsUnit A.det := (chol_det_pos hA hAd).ne'.isUnit
  have hBu : IsUnit B.det := (chol_det_pos hB hBd).ne'.isUnit
  have hinv : ∀ {C : Matrix (Fin n) (Fin n) ℝ}, (∀ i j, i < j → C i j = 0) → IsUnit C.det →
      ∀ i j, i < j → C⁻¹ i j = 0 := by
    intro C hC hCu i j hij
    have := C.invertibleOfIsUnitDet hCu
    exact blockTriangular_inv_of_blockTriangular (b := OrderDual.toDual)
      (fun i j h => hC i j (by simpa using h)) (by simpa using hij)
  set M := B⁻¹ * A with hM
  have hMl : ∀ i j, i < j → M i j = 0 := by
    intro i j hij
    simp only [hM, Matrix.mul_apply]
    apply Finset.sum_eq_zero
    intro k _
    rcases lt_or_ge i k with hik | hki
    · rw [hinv hB hBu i k hik, zero_mul]
    · rw [hA k j (lt_of_le_of_lt hki hij), mul_zero]
  have hM2 : M = Bᵀ * (A⁻¹)ᵀ := by
    have hAt : IsUnit Aᵀ.det := by rwa [det_transpose]
    have : B⁻¹ * (A * Aᵀ) * (Aᵀ)⁻¹ = B⁻¹ * (B * Bᵀ) * (Aᵀ)⁻¹ := by rw [h]
    rw [← Matrix.mul_assoc B⁻¹ A, Matrix.mul_assoc, Matrix.mul_nonsing_inv _ hAt, Matrix.mul_one,
      ← Matrix.mul_assoc B⁻¹ B, Matrix.nonsing_inv_mul _ hBu, Matrix.one_mul,
      ] at this
    rw [transpose_nonsing_inv]; exact this
  have hMu : ∀ i j, j < i → M i j = 0 := by
    intro i j hij
    rw [hM2, Matrix.mul_apply]
    apply Finset.sum_eq_zero
    intro k _
    rcases lt_or_ge k i with hki | hik
    · rw [transpose_apply, hB k i hki, zero_mul]
    · rw [transpose_apply, transpose_apply, hinv hA hAu j k (lt_of_lt_of_le hij hik), mul_zero]
  have hMd : ∀ i j, i ≠ j → M i j = 0 := by
    intro i j hij
    rcases lt_or_gt_of_ne hij with h1 | h1
    · exact hMl i j h1
    · exact hMu i j h1
  have hMM : M * Mᵀ = 1 := by
    rw [hM, transpose_mul, Matrix.mul_assoc, ← Matrix.mul_assoc A, h, ← Matrix.mul_assoc,
      ← Matrix.mul_assoc, Matrix.nonsing_inv_mul _ hBu, Matrix.one_mul, ← transpose_mul,
      Matrix.nonsing_inv_mul _ hBu, transpose_one]
  have hsq : ∀ i, M i i * M i i = 1 := by
    intro i
    have := congrFun (congrFun hMM i) i
    rw [Matrix.mul_apply, Finset.sum_eq_single i] at this
    · simpa using this
    · intro k _ hk; rw [transpose_apply, hMd i k (Ne.symm hk), zero_mul]
    · simp
  have hAB : A = B * M := by
    rw [hM, ← Matrix.mul_assoc, Matrix.mul_nonsing_inv _ hBu, Matrix.one_mul]
  have hdiag : ∀ i, A i i = B i i * M i i := by
    intro i
    conv_lhs => rw [hAB]
    rw [Matrix.mul_apply, Finset.sum_eq_single i]
    · intro k _ hk; rw [hMd k i hk, mul_zero]
    · simp
  have hM1 : M = 1 := by
    ext i j
    by_cases hij : i = j
    · subst hij
      have hpos : 0 < M i i := by
        have := hdiag i
        by_contra hc
        push Not at hc
        have : A i i ≤ 0 := by rw [this]; exact mul_nonpos_of_nonneg_of_nonpos (hBd i).le hc
        linarith [hAd i]
      have := hsq i
      rw [one_apply_eq]
      nlinarith
    · rw [hMd i j hij, one_apply_ne hij]
  rw [hAB, hM1, Matrix.mul_one]

#print axioms chol_unique

/-- **Mixing independent normal draws gives the multivariate normal law `N(μ, L Lᵀ)`.**
Take independent standard normal draws `Z k` (one per source of news, any finite number of
them), mix them with a fixed table of weights `L` (one row per reading, one column per draw)
and shift by the averages `μ`: `X = μ + L Z`. Then the law of `X` is the multivariate normal
law with average vector `μ` and covariance matrix `Σ = L Lᵀ`. The law depends on `L` only
through `L Lᵀ`, so the averages and the covariance matrix fix the whole law. -/
theorem law_of_mixed_independent_normals_is_multivariate_normal
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {ι κ : Type*} [Fintype ι] [DecidableEq ι] [Fintype κ]
    (Z : κ → Ω → ℝ) (hindep : iIndepFun Z P) (hstd : ∀ k, P.map (Z k) = gaussianReal 0 1)
    (μ : EuclideanSpace ℝ ι) (L : Matrix ι κ ℝ) :
    P.map (fun ω ↦ μ + WithLp.toLp 2 (L *ᵥ fun k ↦ Z k ω)) =
      multivariateGaussian μ (L * Lᵀ) := by
  have hZm : ∀ k, AEMeasurable (Z k) P := fun k => mvn_aemeasurable_of_map_eq_gaussianReal (hstd k)
  have hpi : P.map (fun ω k ↦ Z k ω) = Measure.pi (fun _ => gaussianReal 0 1) := by
    rw [(iIndepFun_iff_map_fun_eq_pi_map hZm).mp hindep]
    simp_rw [hstd]
  have hV : AEMeasurable (fun ω k ↦ Z k ω) P := AEMeasurable.of_eval hZm
  have hF : Continuous (fun x : EuclideanSpace ℝ κ ↦ μ + WithLp.toLp 2 (L *ᵥ x.ofLp)) := by
    fun_prop
  have hT : Continuous (WithLp.toLp 2 : (κ → ℝ) → EuclideanSpace ℝ κ) := by fun_prop
  have : (fun ω ↦ μ + WithLp.toLp 2 (L *ᵥ fun k ↦ Z k ω)) =
      ((fun x : EuclideanSpace ℝ κ ↦ μ + WithLp.toLp 2 (L *ᵥ x.ofLp)) ∘ WithLp.toLp 2) ∘
        (fun ω k ↦ Z k ω) := rfl
  rw [this, ← AEMeasurable.map_map_of_aemeasurable (hF.measurable.comp hT.measurable).aemeasurable
    hV, hpi, ← Measure.map_map hF.measurable hT.measurable, map_pi_eq_stdGaussian, mvn_map_std]

/-- **A fixed linear mix of a normal vector is a normal vector** (Step 3).
If a random vector `X` (a measurable map, as every random vector is) has law `X ~ N(μ, Σ)`,
where `Σ` is a covariance matrix (so positive semidefinite), then for any
fixed matrix `B` and fixed vector `a`, the vector `a + B X` is multivariate normal with
average `a + B μ` and covariance `B Σ Bᵀ`. With `B` a single row `wᵀ` this is the portfolio:
normal with average `wᵀ μ` and variance `wᵀ Σ w`. -/
theorem linear_mix_of_multivariate_normal_is_normal
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {ι κ : Type*} [Fintype ι] [DecidableEq ι] [Fintype κ] [DecidableEq κ]
    (X : Ω → EuclideanSpace ℝ ι) (μ : EuclideanSpace ℝ ι) (S : Matrix ι ι ℝ)
    (hS : S.PosSemidef) (hX : P.map X = multivariateGaussian μ S) (hXm : AEMeasurable X P)
    (a : EuclideanSpace ℝ κ) (B : Matrix κ ι ℝ) :
    P.map (fun ω ↦ a + WithLp.toLp 2 (B *ᵥ (X ω).ofLp)) =
      multivariateGaussian (a + WithLp.toLp 2 (B *ᵥ μ.ofLp)) (B * S * Bᵀ) := by
  have hG : Continuous (fun x : EuclideanSpace ℝ ι ↦ a + WithLp.toLp 2 (B *ᵥ x.ofLp)) := by
    fun_prop
  have hH : Continuous (fun x : EuclideanSpace ℝ ι ↦
      μ + toEuclideanCLM (𝕜 := ℝ) (CFC.sqrt S) x) := by fun_prop
  have : (fun ω ↦ a + WithLp.toLp 2 (B *ᵥ (X ω).ofLp)) =
      (fun x : EuclideanSpace ℝ ι ↦ a + WithLp.toLp 2 (B *ᵥ x.ofLp)) ∘ X := rfl
  rw [this, ← AEMeasurable.map_map_of_aemeasurable hG.measurable.aemeasurable hXm, hX,
    multivariateGaussian, Measure.map_map hG.measurable hH.measurable]
  have hcomp : ((fun x : EuclideanSpace ℝ ι ↦ a + WithLp.toLp 2 (B *ᵥ x.ofLp)) ∘
      fun x ↦ μ + toEuclideanCLM (𝕜 := ℝ) (CFC.sqrt S) x) =
      fun x ↦ (a + WithLp.toLp 2 (B *ᵥ μ.ofLp)) +
        WithLp.toLp 2 ((B * CFC.sqrt S) *ᵥ x.ofLp) := by
    funext x
    ext i
    simp [Matrix.mulVec_add, Matrix.mulVec_mulVec, add_assoc]
  rw [hcomp, mvn_map_std]
  have hR : (CFC.sqrt S)ᵀ = CFC.sqrt S := by
    have h0 : (CFC.sqrt S).PosSemidef := Matrix.nonneg_iff_posSemidef.mp (CFC.sqrt_nonneg S)
    have := h0.isHermitian
    rwa [IsHermitian, conjTranspose_eq_transpose_of_trivial] at this
  rw [transpose_mul, hR, Matrix.mul_assoc, ← Matrix.mul_assoc (CFC.sqrt S),
    CFC.sqrt_mul_sqrt_self S hS.nonneg, Matrix.mul_assoc]

/-- **Cholesky: a triangular mixing table from the covariances alone** (Step 5 and its
detailed proof). A square matrix `Σ` is positive definite exactly when it can be written
`Σ = L Lᵀ` with `L` lower triangular (zeros above the diagonal) and every diagonal entry of
`L` positive; and then that triangular factor is unique. -/
theorem cholesky_factor_exists_unique_iff_posDef {n : ℕ} (S : Matrix (Fin n) (Fin n) ℝ) :
    S.PosDef ↔
      ∃! L : Matrix (Fin n) (Fin n) ℝ,
        (∀ i j, i < j → L i j = 0) ∧ (∀ i, 0 < L i i) ∧ S = L * Lᵀ := by
  constructor
  · intro hS
    set L0 := LDL.lower hS with hL0
    set d := LDL.diagEntries hS with hd
    have hS' : L0 * diagonal d * L0ᵀ = S := by
      have := LDL.lower_conj_diag hS
      rwa [conjTranspose_eq_transpose_of_trivial] at this
    have hDpsd : (diagonal d).PosSemidef := by
      have : diagonal d = LDL.diag hS := rfl
      rw [this, LDL.diag_eq_lowerInv_conj]
      exact hS.posSemidef.mul_mul_conjTranspose_same _
    have hdn : ∀ i, 0 ≤ d i := fun i => by simpa using hDpsd.diag_nonneg (i := i)
    have hL0l : ∀ i j, i < j → L0 i j = 0 := fun i j hij =>
      LDL.isLowerTriangular_lower hS (by simpa using hij)
    set C := L0 * diagonal (fun i => Real.sqrt (d i)) with hC
    have hCC : C * Cᵀ = S := by
      rw [hC, transpose_mul, diagonal_transpose, Matrix.mul_assoc, ← Matrix.mul_assoc (diagonal _),
        diagonal_mul_diagonal, ← hS', Matrix.mul_assoc]
      congr 3
      ext i
      exact Real.mul_self_sqrt (hdn i)
    have hCl : ∀ i j, i < j → C i j = 0 := by
      intro i j hij
      rw [hC, mul_diagonal, hL0l i j hij, zero_mul]
    have hCd : ∀ i, C i i ≠ 0 := by
      have hdet : C.det ≠ 0 := by
        intro h0
        have := hS.det_pos
        rw [← hCC, det_mul, h0, zero_mul] at this
        exact lt_irrefl _ this
      rw [det_of_isLowerTriangular C (fun i j hij => hCl i j (by simpa using hij))] at hdet
      exact fun i => Finset.prod_ne_zero_iff.mp hdet i (Finset.mem_univ _)
    set s : Fin n → ℝ := fun i => if 0 < C i i then 1 else -1 with hs
    set L := C * diagonal s with hL
    have hLl : ∀ i j, i < j → L i j = 0 := by
      intro i j hij
      rw [hL, mul_diagonal, hCl i j hij, zero_mul]
    have hLd : ∀ i, 0 < L i i := by
      intro i
      rw [hL, mul_diagonal, hs]
      dsimp only
      split_ifs with h
      · simpa using h
      · have := hCd i
        have : C i i < 0 := lt_of_le_of_ne (not_lt.mp h) this
        linarith
    have hLL : L * Lᵀ = S := by
      rw [hL, transpose_mul, diagonal_transpose, Matrix.mul_assoc, ← Matrix.mul_assoc (diagonal s),
        diagonal_mul_diagonal]
      have : (fun i => s i * s i) = fun _ => (1 : ℝ) := by
        ext i; rw [hs]; dsimp only; split_ifs <;> norm_num
      rw [this, diagonal_one, Matrix.one_mul, hCC]
    refine ⟨L, ⟨hLl, hLd, hLL.symm⟩, ?_⟩
    rintro L' ⟨h1, h2, h3⟩
    exact chol_unique h1 h2 hLl hLd (by rw [← h3, hLL])
  · rintro ⟨L, ⟨hl, hd, hS⟩, -⟩
    rw [hS]
    have hu : IsUnit L := (Matrix.isUnit_iff_isUnit_det L).mpr (chol_det_pos hl hd).ne'.isUnit
    have := PosDef.mul_conjTranspose_self L (vecMul_injective_of_isUnit hu)
    rwa [conjTranspose_eq_transpose_of_trivial] at this

-- The card's mixing table (returns in percent): bank, insurer, miner.
-- L = [[1.0, 0, 0], [0.9, 1.2, 0], [1.2, 0, 1.6]] gives
-- Σ = L Lᵀ = [[1, 0.9, 1.2], [0.9, 2.25, 1.08], [1.2, 1.08, 4]].
example :
    !![(1 : ℚ), 0, 0; 9/10, 6/5, 0; 6/5, 0, 8/5] * (!![(1 : ℚ), 0, 0; 9/10, 6/5, 0; 6/5, 0, 8/5])ᵀ =
      !![(1 : ℚ), 9/10, 6/5; 9/10, 9/4, 27/25; 6/5, 27/25, 4] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_succ] <;> norm_num

-- Correlations: 0.9/(1·1.5) = 0.6, 1.2/(1·2) = 0.6, 1.08/(1.5·2) = 0.36.
example : (9/10 : ℚ) / (1 * (3/2)) = 3/5 ∧ (6/5 : ℚ) / (1 * 2) = 3/5 ∧
    (27/25 : ℚ) / ((3/2) * 2) = 9/25 := by norm_num

-- det Σ = 3.6864 = (1.0 · 1.2 · 1.6)^2.
example : (!![(1 : ℚ), 9/10, 6/5; 9/10, 9/4, 27/25; 6/5, 27/25, 4]).det = 2304/625 ∧
    ((1 : ℚ) * (6/5) * (8/5)) ^ 2 = 2304/625 := by
  constructor
  · simp [Matrix.det_fin_three]; norm_num
  · norm_num

-- Cholesky pivots 1, 1.44, 2.56: Σ_22 - 0.9^2 and Σ_33 - 1.2^2 - 0^2;
-- the miner's insurance weight (1.08 - 1.2 · 0.9)/1.2 is 0.
example : (9/4 : ℚ) - (9/10) ^ 2 = 36/25 ∧ ((27/25 : ℚ) - 6/5 * (9/10)) / (6/5) = 0 ∧
    (4 : ℚ) - (6/5) ^ 2 - 0 ^ 2 = 64/25 := by norm_num

-- Portfolio w = (50, 30, 20): c = Lᵀ w = (101, 36, 32), and the variance is
-- 101^2 + 36^2 + 32^2 = 12,521 = wᵀ Σ w.
example : (!![(1 : ℚ), 0, 0; 9/10, 6/5, 0; 6/5, 0, 8/5])ᵀ *ᵥ ![50, 30, 20] = ![101, 36, 32] := by
  ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_succ] <;> norm_num
example : (101 : ℕ) ^ 2 + 36 ^ 2 + 32 ^ 2 = 12521 := by norm_num
example : ![(50 : ℚ), 30, 20] ⬝ᵥ (!![(1 : ℚ), 9/10, 6/5; 9/10, 9/4, 27/25; 6/5, 27/25, 4] *ᵥ
    ![50, 30, 20]) = 12521 := by
  simp [Matrix.mulVec, dotProduct, Fin.sum_univ_succ]; norm_num

-- Average daily gain: 50 · 0.04 + 30 · 0.03 + 20 · 0.05 = $3.90.
example : (50 : ℚ) * (1/25) + 30 * (3/100) + 20 * (1/20) = 39/10 := by norm_num

-- One day: draws (1.00, -0.50, 0.25) give returns μ + L z = (1.04, 0.33, 1.65),
-- and the fund gains $94.90.
example : ![(1/25 : ℚ), 3/100, 1/20] + !![(1 : ℚ), 0, 0; 9/10, 6/5, 0; 6/5, 0, 8/5] *ᵥ
    ![1, -1/2, 1/4] = ![26/25, 33/100, 33/20] := by
  ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_succ] <;> norm_num
example : (50 : ℚ) * (26/25) + 30 * (33/100) + 20 * (33/20) = 949/10 := by norm_num

-- That day, |z|^2 = 1 + 0.25 + 0.0625 = 1.3125, and solving Σ y = x - μ = L z
-- (y = (19/16, -5/12, 5/32)) then taking the dot product with x - μ gives 1.3125 too.
example : (1 : ℚ) ^ 2 + (-1/2) ^ 2 + (1/4) ^ 2 = 21/16 := by norm_num
example : !![(1 : ℚ), 9/10, 6/5; 9/10, 9/4, 27/25; 6/5, 27/25, 4] *ᵥ ![19/16, -5/12, 5/32] =
      ![1, 3/10, 8/5] ∧
    ![(1 : ℚ), 3/10, 8/5] ⬝ᵥ ![19/16, -5/12, 5/32] = 21/16 := by
  refine ⟨?_, ?_⟩
  · ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_succ] <;> norm_num
  · simp [dotProduct, Fin.sum_univ_succ]; norm_num

-- Hand-typed correlations 0.9, 0.9, 0 are not a covariance matrix: the mix (1, -1, -1)
-- gets variance -0.6, and the third Cholesky pivot is 0.19 - 0.81^2/0.19 = -62/19 (about -3.2632).
example : ![(1 : ℚ), -1, -1] ⬝ᵥ (!![(1 : ℚ), 9/10, 9/10; 9/10, 1, 0; 9/10, 0, 1] *ᵥ
    ![1, -1, -1]) = -3/5 := by
  simp [Matrix.mulVec, dotProduct, Fin.sum_univ_succ]; norm_num
example : (1 : ℚ) - (9/10) ^ 2 - ((0 - 9/10 * (9/10)) ^ 2 / (1 - (9/10) ^ 2)) = -62/19 := by
  norm_num

#print axioms law_of_mixed_independent_normals_is_multivariate_normal
#print axioms linear_mix_of_multivariate_normal_is_normal
#print axioms cholesky_factor_exists_unique_iff_posDef
