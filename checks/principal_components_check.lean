-- Principal components: no unit direction carries more sample variance than the covariance matrix's top eigenvector, the top r eigenvalues bound the variance any r perpendicular directions keep, and the total variance equals the sum of the eigenvalues.
import Mathlib.Analysis.Matrix.Spectrum
import Mathlib.Tactic.NormNum

open Matrix

namespace PrincipalComponents

variable {n d : ℕ}

/-- The average day: the mean of the `n` data vectors `x t`. -/
noncomputable def mean (x : Fin n → Fin d → ℝ) : Fin d → ℝ :=
  (1 / (n : ℝ)) • ∑ t, x t

/-- The sample covariance matrix `(1/(n-1)) * Σ_t (x_t - x̄)(x_t - x̄)^T`. -/
noncomputable def sampleCov (x : Fin n → Fin d → ℝ) : Matrix (Fin d) (Fin d) ℝ :=
  (1 / ((n : ℝ) - 1)) • ∑ t, vecMulVec (x t - mean x) (x t - mean x)

/-- The variance of the scores `z_t = u^T (x_t - x̄)` along a direction `u`,
with the same `n - 1` divisor as the covariance matrix. -/
noncomputable def scoreVar (x : Fin n → Fin d → ℝ) (u : Fin d → ℝ) : ℝ :=
  (1 / ((n : ℝ) - 1)) * ∑ t, (u ⬝ᵥ (x t - mean x)) ^ 2

lemma scoreVar_eq_dot (x : Fin n → Fin d → ℝ) (u : Fin d → ℝ) :
    scoreVar x u = u ⬝ᵥ (sampleCov x *ᵥ u) := by
  simp [scoreVar, sampleCov, Matrix.smul_mulVec, Matrix.sum_mulVec, vecMulVec_mulVec,
    dotProduct_sum, dotProduct_comm, sq]

lemma expand_eig {C : Matrix (Fin d) (Fin d) ℝ} (hC : C.IsHermitian) (u : Fin d → ℝ) :
    u = ∑ i, (⇑(hC.eigenvectorBasis i) ⬝ᵥ u) • ⇑(hC.eigenvectorBasis i) := by
  have h := (hC.eigenvectorBasis).sum_repr' (WithLp.toLp 2 u)
  have h2 := congrArg (WithLp.ofLp) h
  simp [EuclideanSpace.inner_eq_star_dotProduct] at h2
  conv_lhs => rw [← h2]
  simp_rw [dotProduct_comm u]

lemma quad_eig {C : Matrix (Fin d) (Fin d) ℝ} (hC : C.IsHermitian) (u : Fin d → ℝ) :
    u ⬝ᵥ (C *ᵥ u) = ∑ i, hC.eigenvalues i * (⇑(hC.eigenvectorBasis i) ⬝ᵥ u) ^ 2 := by
  conv_lhs => arg 2; rw [expand_eig hC u]
  simp only [mulVec_sum, mulVec_smul, hC.mulVec_eigenvectorBasis, dotProduct_sum,
    dotProduct_smul, smul_eq_mul]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [dotProduct_comm u]
  ring

lemma norm_eig {C : Matrix (Fin d) (Fin d) ℝ} (hC : C.IsHermitian) (u : Fin d → ℝ) :
    u ⬝ᵥ u = ∑ i, (⇑(hC.eigenvectorBasis i) ⬝ᵥ u) ^ 2 := by
  conv_lhs => arg 2; rw [expand_eig hC u]
  simp only [dotProduct_sum, dotProduct_smul, smul_eq_mul]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [dotProduct_comm u]
  ring


lemma kyfan_aux {m r : ℕ} (hr : r ≤ m) (μ : Fin m → ℝ) (hμ : Antitone μ) (w : Fin m → ℝ)
    (h0 : ∀ k, 0 ≤ w k) (h1 : ∀ k, w k ≤ 1) (hs : ∑ k, w k = r) :
    ∑ k, μ k * w k ≤ ∑ k : Fin r, μ (Fin.castLE hr k) := by
  have key : ∀ g : Fin m → ℝ,
      ∑ k : Fin r, g (Fin.castLE hr k) = ∑ k : Fin m, if (k : ℕ) < r then g k else 0 := by
    intro g
    rw [← Finset.sum_filter]
    refine Finset.sum_bij (fun k _ => Fin.castLE hr k) ?_ ?_ ?_ ?_
    · intro k _
      simp [Finset.mem_filter, k.isLt]
    · intro a _ b _ h
      exact Fin.castLE_injective hr h
    · intro b hb
      simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hb
      exact ⟨⟨b, hb⟩, Finset.mem_univ _, rfl⟩
    · intro k _
      rfl
  rcases Nat.eq_zero_or_pos r with rfl | hrpos
  · have hw : ∀ k, w k = 0 := by
      have := (Finset.sum_eq_zero_iff_of_nonneg (fun k _ => h0 k)).1 (by simpa using hs)
      intro k
      exact this k (Finset.mem_univ _)
    simp [hw]
  · set t := μ ⟨r - 1, by omega⟩ with ht
    have hpt : ∀ k, μ k * w k ≤ (if (k : ℕ) < r then μ k else 0) +
        t * (w k - if (k : ℕ) < r then 1 else 0) := by
      intro k
      split_ifs with hk
      · have : t ≤ μ k := hμ (show k ≤ (⟨r - 1, by omega⟩ : Fin m) by
          rw [Fin.le_def]; simp; omega)
        nlinarith [h1 k]
      · have : μ k ≤ t := hμ (show (⟨r - 1, by omega⟩ : Fin m) ≤ k by
          rw [Fin.le_def]; simp; omega)
        nlinarith [h0 k]
    have hcard : ∑ k : Fin m, (if (k : ℕ) < r then (1 : ℝ) else 0) = r := by
      rw [← key (fun _ => 1)]
      simp
    calc ∑ k, μ k * w k ≤ ∑ k : Fin m, ((if (k : ℕ) < r then μ k else 0) +
          t * (w k - if (k : ℕ) < r then 1 else 0)) := Finset.sum_le_sum fun k _ => hpt k
      _ = ∑ k : Fin r, μ (Fin.castLE hr k) := by
        rw [Finset.sum_add_distrib, ← Finset.mul_sum, Finset.sum_sub_distrib, hs, hcard, key]
        ring

/-- The sample covariance matrix is symmetric. -/
theorem sampleCov_isHermitian (x : Fin n → Fin d → ℝ) : (sampleCov x).IsHermitian := by
  ext i j
  simp [sampleCov, vecMulVec, Matrix.sum_apply, mul_comm]

/-- The first principal component: if `u₁` is a unit eigenvector of the sample covariance
matrix whose eigenvalue `lam₁` is the largest eigenvalue, then the variance of the data along
`u₁` equals `lam₁`, and no unit direction `u` carries more variance than `u₁` does. -/
theorem top_eigenvector_carries_most_variance (x : Fin n → Fin d → ℝ)
    (lam₁ : ℝ) (u₁ : Fin d → ℝ) (hu₁ : u₁ ⬝ᵥ u₁ = 1)
    (heig : sampleCov x *ᵥ u₁ = lam₁ • u₁)
    (htop : ∀ μ ∈ spectrum ℝ (sampleCov x), μ ≤ lam₁) :
    scoreVar x u₁ = lam₁ ∧ ∀ u : Fin d → ℝ, u ⬝ᵥ u = 1 → scoreVar x u ≤ scoreVar x u₁ := by
  have hC := sampleCov_isHermitian x
  have hle : ∀ i, hC.eigenvalues i ≤ lam₁ := fun i =>
    htop _ (hC.eigenvalues_mem_spectrum_real i)
  have h1 : scoreVar x u₁ = lam₁ := by
    rw [scoreVar_eq_dot, heig, dotProduct_smul, hu₁, smul_eq_mul, mul_one]
  refine ⟨h1, fun u hu => ?_⟩
  rw [h1, scoreVar_eq_dot, quad_eig hC u]
  have hn := norm_eig hC u
  rw [hu] at hn
  calc ∑ i, hC.eigenvalues i * (⇑(hC.eigenvectorBasis i) ⬝ᵥ u) ^ 2
      ≤ ∑ i, lam₁ * (⇑(hC.eigenvectorBasis i) ⬝ᵥ u) ^ 2 :=
        Finset.sum_le_sum fun i _ => mul_le_mul_of_nonneg_right (hle i) (sq_nonneg _)
    _ = lam₁ := by rw [← Finset.mul_sum, ← hn, mul_one]

/-- Keeping the top `r` components: over all choices of `r` perpendicular unit directions,
the largest total variance kept is the sum of the `r` largest eigenvalues of the sample
covariance matrix (`eigenvalues₀` lists them in falling order). -/
theorem top_r_components_keep_most_variance (x : Fin n → Fin d → ℝ) (r : ℕ)
    (hr : r ≤ Fintype.card (Fin d)) :
    IsGreatest
      {s : ℝ | ∃ v : Fin r → Fin d → ℝ,
        (∀ i j, v i ⬝ᵥ v j = if i = j then 1 else 0) ∧ s = ∑ j, scoreVar x (v j)}
      (∑ k : Fin r, (sampleCov_isHermitian x).eigenvalues₀ (Fin.castLE hr k)) := by
  have hC := sampleCov_isHermitian x
  set b := hC.eigenvectorBasis with hb
  set e := Fintype.equivOfCardEq (Fintype.card_fin (Fintype.card (Fin d))) with he
  have hbb : ∀ i j, ⇑(b i) ⬝ᵥ ⇑(b j) = if i = j then 1 else 0 := by
    intro i j
    have := orthonormal_iff_ite.1 b.orthonormal j i
    rw [EuclideanSpace.inner_eq_star_dotProduct] at this
    simpa [eq_comm] using this
  constructor
  · refine ⟨fun j => ⇑(b (e (Fin.castLE hr j))), ?_, ?_⟩
    · intro i j
      rw [hbb]
      simp
    · refine Finset.sum_congr rfl fun j _ => ?_
      rw [scoreVar_eq_dot, hC.mulVec_eigenvectorBasis, dotProduct_smul, smul_eq_mul, hbb]
      simp [IsHermitian.eigenvalues, he]
  · rintro s ⟨v, hv, rfl⟩
    have hO : Orthonormal ℝ (fun j => WithLp.toLp 2 (v j)) := by
      rw [orthonormal_iff_ite]
      intro i j
      rw [EuclideanSpace.inner_toLp_toLp]
      simpa [eq_comm] using hv j i
    have hbes : ∀ i, ∑ j, (⇑(b i) ⬝ᵥ v j) ^ 2 ≤ 1 := by
      intro i
      have := hO.sum_inner_products_le (x := b i) (s := Finset.univ)
      rw [b.orthonormal.1 i] at this
      simpa [EuclideanSpace.inner_eq_star_dotProduct, dotProduct_comm, sq_abs] using this
    have hev : ∀ k, hC.eigenvalues (e k) = hC.eigenvalues₀ k := by
      intro k
      simp [IsHermitian.eigenvalues, he]
    simp_rw [scoreVar_eq_dot, quad_eig hC]
    rw [Finset.sum_comm]
    simp_rw [← Finset.mul_sum]
    rw [← e.sum_comp]
    simp_rw [hev]
    refine kyfan_aux hr _ hC.eigenvalues₀_antitone (fun k => ∑ j, (⇑(b (e k)) ⬝ᵥ v j) ^ 2)
      (fun k => by positivity) (fun k => hbes _) ?_
    rw [e.sum_comp (fun i => ∑ j, (⇑(b i) ⬝ᵥ v j) ^ 2), Finset.sum_comm]
    have hone : ∀ j, ∑ i, (⇑(b i) ⬝ᵥ v j) ^ 2 = 1 := fun j => by
      have := hv j j
      simp only [↓reduceIte] at this
      rw [← this]
      exact (norm_eig hC (v j)).symm
    simp [hone]

/-- Total variance is conserved: the trace of the sample covariance matrix (the sum of the
variances of the individual measurements) equals the sum of its eigenvalues. -/
theorem total_variance_eq_sum_eigenvalues (x : Fin n → Fin d → ℝ) :
    (sampleCov x).trace = ∑ k, (sampleCov_isHermitian x).eigenvalues₀ k := by
  have hC := sampleCov_isHermitian x
  rw [hC.trace_eq_sum_eigenvalues]
  simp only [IsHermitian.eigenvalues]
  simp
  exact Equiv.sum_comp _ (fun k => hC.eigenvalues₀ k)

/-! ### The card's worked numbers (exact, as whole numbers and fractions) -/

/-- The three hidden shapes of the card's model, over the ten maturities. -/
def level : Fin 10 → ℤ := ![1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
def slope : Fin 10 → ℤ := ![-9, -7, -5, -3, -1, 1, 3, 5, 7, 9]
def curvature : Fin 10 → ℤ := ![6, 2, -1, -3, -4, -4, -3, -1, 2, 6]

-- Squared lengths of the shapes: 10, 330, 132.
example : level ⬝ᵥ level = 10 := by decide
example : slope ⬝ᵥ slope = 330 := by decide
example : curvature ⬝ᵥ curvature = 132 := by decide

-- The three shapes are perpendicular.
example : level ⬝ᵥ slope = 0 := by decide
example : level ⬝ᵥ curvature = 0 := by decide
example : slope ⬝ᵥ curvature = 0 := by decide

-- Model eigenvalues: 3^2 * 10 + 0.5^2 = 90.25, 0.2^2 * 330 + 0.5^2 = 13.45,
-- 0.15^2 * 132 + 0.5^2 = 3.22, and total 108.67.
example : (3 : ℚ) ^ 2 * 10 + (1 / 2) ^ 2 = 9025 / 100 := by norm_num
example : (2 / 10 : ℚ) ^ 2 * 330 + (1 / 2) ^ 2 = 1345 / 100 := by norm_num
example : (15 / 100 : ℚ) ^ 2 * 132 + (1 / 2) ^ 2 = 322 / 100 := by norm_num
example : (9025 / 100 : ℚ) + 1345 / 100 + 322 / 100 + 7 * (1 / 4) = 10867 / 100 := by norm_num

-- Shares, as stated to two decimals: level 83.05%, slope 12.38%, top two 95.43%.
example : (16609 : ℚ) / 20000 ≤ (9025 / 100) / (10867 / 100) ∧
    (9025 / 100 : ℚ) / (10867 / 100) < 16611 / 20000 := by norm_num
example : (2475 : ℚ) / 20000 ≤ (1345 / 100) / (10867 / 100) ∧
    (1345 / 100 : ℚ) / (10867 / 100) < 2477 / 20000 := by norm_num
example : (19085 : ℚ) / 20000 ≤ (9025 / 100 + 1345 / 100) / (10867 / 100) ∧
    (9025 / 100 + 1345 / 100 : ℚ) / (10867 / 100) < 19087 / 20000 := by norm_num

#print axioms scoreVar_eq_dot
#print axioms expand_eig
#print axioms quad_eig
#print axioms norm_eig
#print axioms kyfan_aux
#print axioms sampleCov_isHermitian
#print axioms top_eigenvector_carries_most_variance
#print axioms top_r_components_keep_most_variance
#print axioms total_variance_eq_sum_eigenvalues

end PrincipalComponents
