-- Sparse storage and Krylov methods: GMRES with the diagonal preconditioner never leaves a longer residual than plain Jacobi, whose residual (Wᵀ)ᵏ s shrinks at least by β = √(‖Wᵀ‖₁ ‖Wᵀ‖∞) a step, κ₂(A) is at most (1 + β) t_max / ((1 − β) t_min), and a network with no exits leaves every residual above |Σ sᵢ| / √n.
import Mathlib.Analysis.CStarAlgebra.Matrix
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Span.Defs
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Algebra.Order.Chebyshev

open Matrix

/-- The length (2-norm) of a vector `v`: the Euclidean norm of `v` read as a point of
`EuclideanSpace ℝ (Fin n)`. -/
noncomputable abbrev len2 {n : ℕ} (v : Fin n → ℝ) : ℝ :=
  ‖(WithLp.toLp 2 v : EuclideanSpace ℝ (Fin n))‖

/-- The Krylov space `𝒦ₖ = span {s, B s, …, B^(k−1) s}`: every mix of the right-hand side
and its first `k − 1` products with `B`. -/
def krylov {n : ℕ} (B : Matrix (Fin n) (Fin n) ℝ) (s : Fin n → ℝ) (k : ℕ) :
    Submodule ℝ (Fin n → ℝ) :=
  Submodule.span ℝ (Set.range fun i : Fin k => (B ^ (i : ℕ)) *ᵥ s)

lemma len2_eq_sqrt {n : ℕ} (v : Fin n → ℝ) : len2 v = Real.sqrt (∑ i, v i ^ 2) := by
  simp [len2, EuclideanSpace.norm_eq]

lemma len2_sq {n : ℕ} (v : Fin n → ℝ) : len2 v ^ 2 = ∑ i, v i ^ 2 := by
  rw [len2_eq_sqrt, Real.sq_sqrt (Finset.sum_nonneg fun i _ => sq_nonneg _)]

lemma len2_nonneg {n : ℕ} (v : Fin n → ℝ) : 0 ≤ len2 v := norm_nonneg _

lemma len2_sub_le {n : ℕ} (u w : Fin n → ℝ) : len2 (u - w) ≤ len2 u + len2 w := by
  simp only [len2, WithLp.toLp_sub]
  exact norm_sub_le _ _

lemma len2_sub_ge {n : ℕ} (u w : Fin n → ℝ) : len2 u - len2 w ≤ len2 (u - w) := by
  simp only [len2, WithLp.toLp_sub]
  exact norm_sub_norm_le _ _

lemma len2_eq_zero {n : ℕ} {v : Fin n → ℝ} (h : len2 v = 0) : v = 0 := by
  simp only [len2, norm_eq_zero] at h
  simpa using congrArg WithLp.ofLp h

lemma schur_sq {n : ℕ} (C : Matrix (Fin n) (Fin n) ℝ) (a b : ℝ)
    (ha : ∀ j, ∑ i, |C i j| ≤ a) (hb : ∀ i, ∑ j, |C i j| ≤ b) (v : Fin n → ℝ) :
    ∑ i, (C *ᵥ v) i ^ 2 ≤ a * b * ∑ i, v i ^ 2 := by
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp
  have hb0 : 0 ≤ b := le_trans (Finset.sum_nonneg fun j _ => abs_nonneg _) (hb ⟨0, hn⟩)
  have hrow : ∀ i, (C *ᵥ v) i ^ 2 ≤ (∑ j, |C i j|) * ∑ j, |C i j| * v j ^ 2 := by
    intro i
    simp only [mulVec, dotProduct]
    apply Finset.sum_sq_le_sum_mul_sum_of_sq_le_mul
    · intro j _; exact abs_nonneg _
    · intro j _; exact mul_nonneg (abs_nonneg _) (sq_nonneg _)
    · intro j _
      rw [mul_pow, ← sq_abs (C i j)]; ring_nf; rfl
  calc ∑ i, (C *ᵥ v) i ^ 2 ≤ ∑ i, b * ∑ j, |C i j| * v j ^ 2 := by
        apply Finset.sum_le_sum; intro i _
        refine (hrow i).trans ?_
        exact mul_le_mul_of_nonneg_right (hb i)
          (Finset.sum_nonneg fun j _ => mul_nonneg (abs_nonneg _) (sq_nonneg _))
    _ = b * ∑ j, (∑ i, |C i j|) * v j ^ 2 := by
        rw [← Finset.mul_sum, Finset.sum_comm]; simp_rw [Finset.sum_mul]
    _ ≤ b * ∑ j, a * v j ^ 2 := by
        apply mul_le_mul_of_nonneg_left _ hb0
        apply Finset.sum_le_sum; intro j _
        exact mul_le_mul_of_nonneg_right (ha j) (sq_nonneg _)
    _ = a * b * ∑ i, v i ^ 2 := by rw [← Finset.mul_sum]; ring

lemma len2_mulVec_le {n : ℕ} (C : Matrix (Fin n) (Fin n) ℝ) (a b : ℝ)
    (ha : ∀ j, ∑ i, |C i j| ≤ a) (hb : ∀ i, ∑ j, |C i j| ≤ b) (v : Fin n → ℝ) :
    len2 (C *ᵥ v) ≤ Real.sqrt (a * b) * len2 v := by
  rw [len2_eq_sqrt, len2_eq_sqrt,
    ← Real.sqrt_mul' _ (Finset.sum_nonneg fun i _ => sq_nonneg _)]
  exact Real.sqrt_le_sqrt (schur_sq C a b ha hb v)

lemma len2_diag_le {n : ℕ} (d : Fin n → ℝ) (c : ℝ) (hc : 0 ≤ c) (hd : ∀ i, |d i| ≤ c)
    (v : Fin n → ℝ) : len2 (diagonal d *ᵥ v) ≤ c * len2 v := by
  rw [← sq_le_sq₀ (len2_nonneg _) (mul_nonneg hc (len2_nonneg _)), mul_pow, len2_sq, len2_sq,
    Finset.mul_sum]
  apply Finset.sum_le_sum; intro i _
  rw [mulVec_diagonal, mul_pow]
  apply mul_le_mul_of_nonneg_right _ (sq_nonneg _)
  rw [← sq_abs]
  exact pow_le_pow_left₀ (abs_nonneg _) (hd i) 2

lemma len2_diag_ge {n : ℕ} (d : Fin n → ℝ) (c : ℝ) (hc : 0 ≤ c) (hd : ∀ i, c ≤ |d i|)
    (v : Fin n → ℝ) : c * len2 v ≤ len2 (diagonal d *ᵥ v) := by
  rw [← sq_le_sq₀ (mul_nonneg hc (len2_nonneg _)) (len2_nonneg _), mul_pow, len2_sq, len2_sq,
    Finset.mul_sum]
  apply Finset.sum_le_sum; intro i _
  rw [mulVec_diagonal, mul_pow]
  apply mul_le_mul_of_nonneg_right _ (sq_nonneg _)
  rw [← sq_abs (d i)]
  exact pow_le_pow_left₀ hc (hd i) 2

lemma krylov_mono {n : ℕ} (B : Matrix (Fin n) (Fin n) ℝ) (s : Fin n → ℝ) {m k : ℕ}
    (h : m ≤ k) : krylov B s m ≤ krylov B s k := by
  unfold krylov
  apply Submodule.span_mono
  rintro _ ⟨i, rfl⟩
  exact ⟨⟨i, lt_of_lt_of_le i.2 h⟩, rfl⟩

lemma self_mem_krylov {n : ℕ} (B : Matrix (Fin n) (Fin n) ℝ) (s : Fin n → ℝ) (m : ℕ) :
    s ∈ krylov B s (m + 1) :=
  Submodule.subset_span ⟨⟨0, Nat.succ_pos m⟩, by simp⟩

lemma mulVec_mem_krylov {n : ℕ} (B : Matrix (Fin n) (Fin n) ℝ) (s : Fin n → ℝ) {m : ℕ}
    {v : Fin n → ℝ} (hv : v ∈ krylov B s m) : B *ᵥ v ∈ krylov B s (m + 1) := by
  have key : krylov B s m ≤ (krylov B s (m + 1)).comap (Matrix.mulVecLin B) := by
    unfold krylov
    rw [Submodule.span_le]
    rintro _ ⟨i, rfl⟩
    rw [SetLike.mem_coe, Submodule.mem_comap, Matrix.mulVecLin_apply, mulVec_mulVec, ← pow_succ']
    exact Submodule.subset_span ⟨⟨i + 1, by omega⟩, rfl⟩
  exact key hv

#print axioms len2_eq_sqrt
#print axioms len2_sq
#print axioms len2_nonneg
#print axioms len2_sub_le
#print axioms len2_sub_ge
#print axioms len2_eq_zero
#print axioms schur_sq
#print axioms len2_mulVec_le
#print axioms len2_diag_le
#print axioms len2_diag_ge
#print axioms krylov_mono
#print axioms self_mem_krylov
#print axioms mulVec_mem_krylov

/-- GMRES is never worse than Jacobi, and both fall geometrically. Take a turning table `W`,
travel times `tᵢ > 0`, the preconditioner `M = diag(1/tᵢ)` and the system matrix
`A = (I − Wᵀ) M`, so that `B = A M⁻¹ = I − Wᵀ`. Let `a` bound every column sum of `|Wᵀ|`
(so `‖Wᵀ‖₁ ≤ a`) and `b` bound every row sum (so `‖Wᵀ‖∞ ≤ b`). Run plain Jacobi from
`x₀ = 0`, `x_{m+1} = x_m + M⁻¹ (s − A x_m)`, and let `x` be the GMRES iterate after `k` steps:
`M x` lies in the Krylov space `𝒦ₖ(B, s)` and `‖s − A x‖₂` is smallest among all such `x`.
Then GMRES's residual is no longer than Jacobi's, Jacobi's residual is exactly `(Wᵀ)ᵏ s`,
and that is at most `βᵏ ‖s‖₂` with `β = √(a b)`. (The bound says something only when
`β < 1`; it holds whatever `β` is.) -/
theorem gmres_residual_le_jacobi_residual_le_geometric {n : ℕ}
    (W : Matrix (Fin n) (Fin n) ℝ) (t : Fin n → ℝ) (ht : ∀ i, 0 < t i)
    (M A : Matrix (Fin n) (Fin n) ℝ)
    (hM : M = diagonal fun i => (t i)⁻¹) (hA : A = (1 - Wᵀ) * M)
    (a b : ℝ) (ha : ∀ j, ∑ i, |Wᵀ i j| ≤ a) (hb : ∀ i, ∑ j, |Wᵀ i j| ≤ b)
    (s : Fin n → ℝ) (k : ℕ)
    (xJ : ℕ → Fin n → ℝ) (hJ0 : xJ 0 = 0)
    (hJ : ∀ m, xJ (m + 1) = xJ m + M⁻¹ *ᵥ (s - A *ᵥ xJ m))
    (x : Fin n → ℝ) (hx : M *ᵥ x ∈ krylov (A * M⁻¹) s k)
    (hmin : ∀ y : Fin n → ℝ, M *ᵥ y ∈ krylov (A * M⁻¹) s k →
      len2 (s - A *ᵥ x) ≤ len2 (s - A *ᵥ y)) :
    len2 (s - A *ᵥ x) ≤ len2 (s - A *ᵥ xJ k) ∧
      s - A *ᵥ xJ k = (Wᵀ ^ k) *ᵥ s ∧
      len2 ((Wᵀ ^ k) *ᵥ s) ≤ Real.sqrt (a * b) ^ k * len2 s := by
  have hMdet : IsUnit M.det := by
    rw [hM, det_diagonal, isUnit_iff_ne_zero, Finset.prod_ne_zero_iff]
    intro i _
    exact inv_ne_zero (ht i).ne'
  have hMM : M * M⁻¹ = 1 := mul_nonsing_inv M hMdet
  set B := A * M⁻¹ with hBdef
  have hB : B = 1 - Wᵀ := by rw [hBdef, hA, Matrix.mul_assoc, hMM, Matrix.mul_one]
  have hAB : A = B * M := by
    rw [hBdef, Matrix.mul_assoc, nonsing_inv_mul M hMdet, Matrix.mul_one]
  -- Jacobi iterates stay in the Krylov space.
  have hKry : ∀ m, M *ᵥ xJ m ∈ krylov B s m := by
    intro m
    induction m with
    | zero => rw [hJ0, mulVec_zero]; exact Submodule.zero_mem _
    | succ m ih =>
      have e : M *ᵥ xJ (m + 1) = s + M *ᵥ xJ m - B *ᵥ (M *ᵥ xJ m) := by
        rw [hJ m, mulVec_add, mulVec_mulVec, hMM, one_mulVec, hAB, ← mulVec_mulVec]
        abel
      rw [e]
      exact Submodule.sub_mem _
        (Submodule.add_mem _ (self_mem_krylov B s m) (krylov_mono B s (Nat.le_succ m) ih))
        (mulVec_mem_krylov B s ih)
  -- Jacobi residuals.
  have hRes : ∀ m, s - A *ᵥ xJ m = (Wᵀ ^ m) *ᵥ s := by
    intro m
    induction m with
    | zero => rw [hJ0, mulVec_zero, sub_zero, pow_zero, one_mulVec]
    | succ m ih =>
      rw [hJ m, mulVec_add, mulVec_mulVec, ← hBdef, hB, sub_mulVec, one_mulVec, ih,
        pow_succ', ← mulVec_mulVec]
      rw [← ih]
      abel
  -- Geometric decay.
  have hGeo : ∀ m, len2 ((Wᵀ ^ m) *ᵥ s) ≤ Real.sqrt (a * b) ^ m * len2 s := by
    intro m
    induction m with
    | zero => simp
    | succ m ih =>
      rw [pow_succ', ← mulVec_mulVec, pow_succ', mul_assoc]
      exact (len2_mulVec_le Wᵀ a b ha hb _).trans
        (mul_le_mul_of_nonneg_left ih (Real.sqrt_nonneg _))
  exact ⟨hmin (xJ k) (hKry k), hRes k, hGeo k⟩

open scoped Matrix.Norms.L2Operator in
/-- The condition-number bound of Step 5. With `A = (I − Wᵀ) M`, `M = diag(1/tᵢ)`, every
travel time between `t_min > 0` and `t_max ≥ t_min`, and `β = √(a b) < 1` where `a` bounds the
column sums and `b` the row sums of `|Wᵀ|`, the matrix `A` is invertible and its 2-norm
condition number satisfies `κ₂(A) = ‖A‖₂ ‖A⁻¹‖₂ ≤ ((1 + β) / t_min) · (t_max / (1 − β))`. -/
theorem kappa2_le_of_beta_lt_one {n : ℕ}
    (W : Matrix (Fin n) (Fin n) ℝ) (t : Fin n → ℝ) (tmin tmax : ℝ) (htmin : 0 < tmin)
    (htmax : tmin ≤ tmax) (ht : ∀ i, tmin ≤ t i ∧ t i ≤ tmax)
    (M A : Matrix (Fin n) (Fin n) ℝ)
    (hM : M = diagonal fun i => (t i)⁻¹) (hA : A = (1 - Wᵀ) * M)
    (a b : ℝ) (ha : ∀ j, ∑ i, |Wᵀ i j| ≤ a) (hb : ∀ i, ∑ j, |Wᵀ i j| ≤ b)
    (hβ : Real.sqrt (a * b) < 1) :
    IsUnit A.det ∧
      ‖A‖ * ‖A⁻¹‖ ≤ (1 + Real.sqrt (a * b)) / tmin * (tmax / (1 - Real.sqrt (a * b))) := by
  set β := Real.sqrt (a * b) with hβdef
  have hβ0 : 0 ≤ β := Real.sqrt_nonneg _
  have htmax0 : 0 < tmax := lt_of_lt_of_le htmin htmax
  have hAv : ∀ v, A *ᵥ v = M *ᵥ v - Wᵀ *ᵥ (M *ᵥ v) := by
    intro v
    rw [hA, ← mulVec_mulVec, sub_mulVec, one_mulVec]
  have hupper : ∀ v, len2 (A *ᵥ v) ≤ (1 + β) / tmin * len2 v := by
    intro v
    have hMv : len2 (M *ᵥ v) ≤ tmin⁻¹ * len2 v := by
      rw [hM]
      apply len2_diag_le _ _ (inv_nonneg.mpr htmin.le)
      intro i
      rw [abs_of_pos (inv_pos.mpr (lt_of_lt_of_le htmin (ht i).1))]
      exact inv_anti₀ htmin (ht i).1
    rw [hAv]
    calc len2 (M *ᵥ v - Wᵀ *ᵥ (M *ᵥ v))
        ≤ len2 (M *ᵥ v) + len2 (Wᵀ *ᵥ (M *ᵥ v)) := len2_sub_le _ _
      _ ≤ len2 (M *ᵥ v) + β * len2 (M *ᵥ v) := by
          gcongr; exact len2_mulVec_le Wᵀ a b ha hb _
      _ = (1 + β) * len2 (M *ᵥ v) := by ring
      _ ≤ (1 + β) * (tmin⁻¹ * len2 v) := by gcongr
      _ = (1 + β) / tmin * len2 v := by ring
  have hlower : ∀ v, (1 - β) / tmax * len2 v ≤ len2 (A *ᵥ v) := by
    intro v
    have hMv : tmax⁻¹ * len2 v ≤ len2 (M *ᵥ v) := by
      rw [hM]
      apply len2_diag_ge _ _ (inv_nonneg.mpr htmax0.le)
      intro i
      rw [abs_of_pos (inv_pos.mpr (lt_of_lt_of_le htmin (ht i).1))]
      exact inv_anti₀ (lt_of_lt_of_le htmin (ht i).1) (ht i).2
    rw [hAv]
    calc (1 - β) / tmax * len2 v = (1 - β) * (tmax⁻¹ * len2 v) := by ring
      _ ≤ (1 - β) * len2 (M *ᵥ v) := by gcongr
      _ = len2 (M *ᵥ v) - β * len2 (M *ᵥ v) := by ring
      _ ≤ len2 (M *ᵥ v) - len2 (Wᵀ *ᵥ (M *ᵥ v)) := by
          gcongr; exact len2_mulVec_le Wᵀ a b ha hb _
      _ ≤ len2 (M *ᵥ v - Wᵀ *ᵥ (M *ᵥ v)) := len2_sub_ge _ _
  have hc : 0 < (1 - β) / tmax := div_pos (by linarith) htmax0
  have hdet : IsUnit A.det := by
    rw [isUnit_iff_ne_zero]
    intro h0
    obtain ⟨v, hv0, hv⟩ := (Matrix.exists_mulVec_eq_zero_iff (M := A)).mpr h0
    have h1 := hlower v
    rw [hv] at h1
    have h2 : len2 (0 : Fin n → ℝ) = 0 := by simp [len2]
    rw [h2] at h1
    have h3 : len2 v = 0 :=
      le_antisymm (nonpos_of_mul_nonpos_right h1 hc) (len2_nonneg v)
    exact hv0 (len2_eq_zero h3)
  refine ⟨hdet, ?_⟩
  have hnormA : ‖A‖ ≤ (1 + β) / tmin := by
    rw [cstar_norm_def]
    refine ContinuousLinearMap.opNorm_le_bound _ (div_nonneg (by linarith) htmin.le) ?_
    intro x
    have := hupper (WithLp.ofLp x)
    show ‖WithLp.toLp 2 (A *ᵥ x.ofLp)‖ ≤ _
    simpa [len2] using this
  have hnormAinv : ‖A⁻¹‖ ≤ tmax / (1 - β) := by
    rw [cstar_norm_def]
    refine ContinuousLinearMap.opNorm_le_bound _ (div_nonneg htmax0.le (by linarith)) ?_
    intro x
    have h1 := hlower (A⁻¹ *ᵥ WithLp.ofLp x)
    rw [mulVec_mulVec, mul_nonsing_inv A hdet, one_mulVec] at h1
    have h2 : len2 (A⁻¹ *ᵥ WithLp.ofLp x) ≤ tmax / (1 - β) * len2 (WithLp.ofLp x) := by
      rw [div_mul_eq_mul_div, le_div_iff₀ (by linarith)]
      rw [div_mul_eq_mul_div, div_le_iff₀ htmax0] at h1
      linarith
    show ‖WithLp.toLp 2 (A⁻¹ *ᵥ x.ofLp)‖ ≤ _
    simpa [len2] using h2
  exact mul_le_mul hnormA hnormAinv (norm_nonneg _) (div_nonneg (by linarith) htmin.le)

/-- The closed-network floor. If every column of `A` sums to zero (no car ever exits), then
for every candidate answer `x`, in particular every GMRES iterate, the residual is at least
`|Σ sᵢ| / √n` long: no steady state exists and no solver can get below that floor. -/
theorem residual_ge_floor_of_column_sums_zero {n : ℕ}
    (A : Matrix (Fin n) (Fin n) ℝ) (hcol : ∀ j, ∑ i, A i j = 0)
    (s x : Fin n → ℝ) :
    |∑ i, s i| / Real.sqrt n ≤ len2 (s - A *ᵥ x) := by
  have hsum : ∑ i, (s - A *ᵥ x) i = ∑ i, s i := by
    have h0 : ∑ i, (A *ᵥ x) i = 0 := by
      simp only [mulVec, dotProduct]
      rw [Finset.sum_comm]
      simp [← Finset.sum_mul, hcol]
    simp [Finset.sum_sub_distrib, h0]
  apply div_le_of_le_mul₀ (Real.sqrt_nonneg _) (len2_nonneg _)
  rw [← hsum, ← sq_le_sq₀ (abs_nonneg _) (mul_nonneg (len2_nonneg _) (Real.sqrt_nonneg _)),
    sq_abs, mul_pow, len2_sq, Real.sq_sqrt (Nat.cast_nonneg _), mul_comm]
  simpa using sq_sum_le_card_mul_sum_sq (s := Finset.univ) (f := fun i => (s - A *ᵥ x) i)

/-! The card's whole-number worked examples: 50,000 links, six neighbours each. -/

-- Dense entries and bytes: 50,000 × 50,000 = 2,500,000,000 entries, × 8 = 20,000,000,000 bytes.
example : 50000 * 50000 = 2500000000 ∧ 50000 * 50000 * 8 = 20000000000 := by norm_num

-- Nonzeros: 50,000 × (1 + 6) = 350,000.
example : 50000 * (1 + 6) = 350000 := by norm_num

-- CSR bytes: 350,000 × 8 + 350,000 × 4 + 50,001 × 4 = 4,400,004; triplets: 16 × 350,000 = 5,600,000.
example : 350000 * 8 + 350000 * 4 + 50001 * 4 = 4400004 ∧ 16 * 350000 = 5600000 := by norm_num

-- One product: 2 × 350,000 = 700,000 flops in CSR against 2 × 2,500,000,000 = 5,000,000,000 dense.
example : 2 * 350000 = 700000 ∧ 2 * 2500000000 = 5000000000 := by norm_num

-- Cost of 20 preconditioned GMRES steps: 60,000,000 flops; basis 21 × 50,000 × 8 = 8,400,000 bytes.
example : ∑ k ∈ Finset.range 20,
    (2 * 350000 + 50000 + 4 * 50000 * (k + 1) + 3 * 50000) = 60000000 := by
  norm_num [Finset.sum_range_succ]
example : 21 * 50000 * 8 = 8400000 := by norm_num

-- Plain GMRES, 96 steps with no preconditioner: 1,012,800,000 flops; basis 97 × 50,000 × 8 = 38,800,000 bytes.
example : ∑ k ∈ Finset.range 96,
    (2 * 350000 + 4 * 50000 * (k + 1) + 3 * 50000) = 1012800000 := by
  norm_num [Finset.sum_range_succ]
example : 97 * 50000 * 8 = 38800000 := by norm_num

-- Dense LU: 2 × 50,000³ / 3 = 83,333,333,333,333 flops (rounded down).
example : 2 * 50000 ^ 3 / 3 = 83333333333333 := by norm_num

#print axioms gmres_residual_le_jacobi_residual_le_geometric
#print axioms kappa2_le_of_beta_lt_one
#print axioms residual_ge_floor_of_column_sums_zero
