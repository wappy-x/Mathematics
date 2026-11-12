-- QR: a table with independent columns is exactly one perpendicular-unit-column matrix times one upper triangle with a positive diagonal, and a Householder mirror is symmetric, undoes itself and folds its column onto the first axis.
import Mathlib.LinearAlgebra.Matrix.Block
import Mathlib.LinearAlgebra.LinearIndependent.Defs
import Mathlib.Data.Matrix.Mul
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.InnerProductSpace.GramSchmidtOrtho
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.LinearAlgebra.Matrix.DotProduct

open Matrix

theorem qr_exists_aux {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ)
    (hA : LinearIndependent ℝ Aᵀ) :
    ∃ Q : Matrix (Fin m) (Fin n) ℝ, ∃ R : Matrix (Fin n) (Fin n) ℝ,
      Qᵀ * Q = 1 ∧ R.BlockTriangular id ∧ (∀ i, 0 < R i i) ∧ A = Q * R := by
  classical
  let f : Fin n → EuclideanSpace ℝ (Fin m) := fun j => WithLp.toLp 2 (Aᵀ j)
  have hf : LinearIndependent ℝ f :=
    hA.map' (WithLp.linearEquiv 2 ℝ (Fin m → ℝ)).symm.toLinearMap
      (WithLp.linearEquiv 2 ℝ (Fin m → ℝ)).symm.ker
  let q := InnerProductSpace.gramSchmidtNormed ℝ f
  have hq : Orthonormal ℝ q := InnerProductSpace.gramSchmidtNormed_orthonormal hf
  refine ⟨Matrix.of fun k j => q j k, Matrix.of fun i j => inner ℝ (q i) (f j), ?_, ?_, ?_, ?_⟩
  · ext i j
    have := (orthonormal_iff_ite.mp hq) i j
    rw [EuclideanSpace.inner_eq_star_dotProduct] at this
    simp only [Matrix.mul_apply, transpose_apply, of_apply, Matrix.one_apply]
    rw [← this]
    simp [dotProduct, mul_comm]
  · intro i j hij
    simp only [of_apply, q, InnerProductSpace.gramSchmidtNormed, inner_smul_left]
    rw [InnerProductSpace.gramSchmidt_inv_triangular ℝ f (show j < i from hij)]
    simp
  · intro j
    simp only [of_apply, q, InnerProductSpace.gramSchmidtNormed, real_inner_smul_left]
    have hne := InnerProductSpace.gramSchmidt_ne_zero j hf
    have key : inner ℝ (InnerProductSpace.gramSchmidt ℝ f j) (f j)
        = ‖InnerProductSpace.gramSchmidt ℝ f j‖ ^ 2 := by
      conv_lhs => rw [InnerProductSpace.gramSchmidt_def'' ℝ f j]
      rw [inner_add_right, inner_sum, real_inner_self_eq_norm_sq]
      rw [Finset.sum_eq_zero, add_zero]
      intro i hi
      rw [inner_smul_right, InnerProductSpace.gramSchmidt_orthogonal ℝ f
        (Finset.mem_Iio.mp hi).ne', mul_zero]
    rw [key]
    have : 0 < ‖InnerProductSpace.gramSchmidt ℝ f j‖ := norm_pos_iff.mpr hne
    simp only [RCLike.ofReal_real_eq_id, id]
    field_simp
    positivity
  · have hspan : ∀ j, f j ∈ Submodule.span ℝ (Set.range q) := by
      intro j
      rw [InnerProductSpace.span_gramSchmidtNormed_range, InnerProductSpace.span_gramSchmidt]
      exact Submodule.subset_span ⟨j, rfl⟩
    ext k j
    obtain ⟨c, hc⟩ := (Submodule.mem_span_range_iff_exists_fun ℝ).mp (hspan j)
    have hcoef : ∀ i, inner ℝ (q i) (f j) = c i := by
      intro i; rw [← hc]; exact hq.inner_right_fintype c i
    have : A k j = (f j) k := rfl
    rw [this, ← hc]
    simp only [Matrix.mul_apply, of_apply, hcoef]
    simp [mul_comm]

theorem qr_unique_aux {m n : ℕ} (Q₁ Q₂ : Matrix (Fin m) (Fin n) ℝ)
    (R₁ R₂ : Matrix (Fin n) (Fin n) ℝ) (hQ₁ : Q₁ᵀ * Q₁ = 1) (hQ₂ : Q₂ᵀ * Q₂ = 1)
    (hR₁ : R₁.BlockTriangular id) (hR₂ : R₂.BlockTriangular id)
    (hd₁ : ∀ i, 0 < R₁ i i) (hd₂ : ∀ i, 0 < R₂ i i) (h : Q₁ * R₁ = Q₂ * R₂) :
    Q₁ = Q₂ ∧ R₁ = R₂ := by
  classical
  have hdet : IsUnit R₁.det := by
    rw [det_of_isUpperTriangular hR₁]
    exact (Finset.prod_pos fun i _ => hd₁ i).ne'.isUnit
  have : Invertible R₁ := (R₁.isUnit_iff_isUnit_det.mpr hdet).invertible
  set M := R₂ * R₁⁻¹ with hMdef
  have hM : M.BlockTriangular id := hR₂.mul (blockTriangular_inv_of_blockTriangular hR₁)
  have hMR : M * R₁ = R₂ := by rw [hMdef, Matrix.inv_mul_cancel_right_of_invertible]
  have hQ : Q₁ = Q₂ * M := by
    rw [hMdef, ← Matrix.mul_assoc, ← h, Matrix.mul_inv_cancel_right_of_invertible]
  clear_value M
  have hMM : Mᵀ * M = 1 := by
    rw [← hQ₁, hQ, transpose_mul, Matrix.mul_assoc, ← Matrix.mul_assoc Q₂ᵀ, hQ₂,
      Matrix.one_mul]
  have : Invertible M := invertibleOfLeftInverse M Mᵀ hMM
  have hMinv : M⁻¹ = Mᵀ := Matrix.inv_eq_left_inv hMM
  have hMl : ∀ i j, i ≠ j → M i j = 0 := by
    intro i j hij
    rcases lt_or_gt_of_ne hij with hlt | hlt
    · have := blockTriangular_inv_of_blockTriangular hM (i := j) (j := i) hlt
      rw [hMinv] at this
      simpa using this
    · exact hM hlt
  have hdiag : ∀ i, M i i * R₁ i i = R₂ i i := by
    intro i
    rw [← hMR, Matrix.mul_apply, Finset.sum_eq_single i]
    · intro k _ hk
      rw [hMl i k (Ne.symm hk), zero_mul]
    · simp
  have hMpos : ∀ i, 0 < M i i := by
    intro i
    have := hdiag i
    have h1 := hd₁ i
    have h2 := hd₂ i
    by_contra hneg
    push Not at hneg
    nlinarith
  have hMone : M = 1 := by
    ext i j
    by_cases hij : i = j
    · subst hij
      have := congrFun (congrFun hMM i) i
      rw [Matrix.mul_apply, Finset.sum_eq_single i] at this
      · simp only [transpose_apply, Matrix.one_apply_eq] at this
        have hp := hMpos i
        rw [Matrix.one_apply_eq]
        nlinarith
      · intro k _ hk
        rw [transpose_apply, hMl k i hk, zero_mul]
      · simp
    · rw [hMl i j hij, Matrix.one_apply_ne hij]
  refine ⟨?_, ?_⟩
  · rw [hQ, hMone, Matrix.mul_one]
  · rw [← hMR, hMone, Matrix.one_mul]

theorem householder_dot_aux {m : ℕ} (x : Fin (m + 1) → ℝ) (s : ℝ) (hs : s * s = 1) :
    let v : Fin (m + 1) → ℝ := x + (s * Real.sqrt (x ⬝ᵥ x)) • Pi.single 0 1
    v ⬝ᵥ v = 2 * (x ⬝ᵥ x + s * Real.sqrt (x ⬝ᵥ x) * x 0) ∧
      v ⬝ᵥ x = x ⬝ᵥ x + s * Real.sqrt (x ⬝ᵥ x) * x 0 := by
  intro v
  have hxx : 0 ≤ x ⬝ᵥ x := Finset.sum_nonneg fun i _ => mul_self_nonneg (x i)
  have hr : Real.sqrt (x ⬝ᵥ x) ^ 2 = x ⬝ᵥ x := Real.sq_sqrt hxx
  have h1 : (Pi.single 0 1 : Fin (m + 1) → ℝ) ⬝ᵥ x = x 0 := by simp
  have h2 : x ⬝ᵥ (Pi.single 0 1 : Fin (m + 1) → ℝ) = x 0 := by simp
  have h3 : (Pi.single 0 1 : Fin (m + 1) → ℝ) ⬝ᵥ (Pi.single 0 1 : Fin (m + 1) → ℝ) = 1 := by
    simp
  constructor
  · simp only [v, add_dotProduct, dotProduct_add, smul_dotProduct, dotProduct_smul, h1, h2, h3,
      smul_eq_mul]
    linear_combination (x ⬝ᵥ x) * hs + (s * s) * hr
  · simp only [v, add_dotProduct, smul_dotProduct, h1, smul_eq_mul]

theorem householder_length_aux {m : ℕ} (x : Fin (m + 1) → ℝ) :
    let s : ℝ := if 0 ≤ x 0 then 1 else -1
    let v : Fin (m + 1) → ℝ := x + (s * Real.sqrt (x ⬝ᵥ x)) • Pi.single 0 1
    v ⬝ᵥ v = 2 * Real.sqrt (x ⬝ᵥ x) * (Real.sqrt (x ⬝ᵥ x) + |x 0|) := by
  intro s v
  have hs : s * s = 1 := by simp only [s]; split_ifs <;> norm_num
  have hsx : s * x 0 = |x 0| := by
    simp only [s]; split_ifs with h
    · rw [abs_of_nonneg h, one_mul]
    · rw [abs_of_neg (not_le.mp h)]; ring
  have hxx : 0 ≤ x ⬝ᵥ x := Finset.sum_nonneg fun i _ => mul_self_nonneg (x i)
  have hr : Real.sqrt (x ⬝ᵥ x) ^ 2 = x ⬝ᵥ x := Real.sq_sqrt hxx
  rw [(householder_dot_aux x s hs).1]
  linear_combination (-2) * hr + 2 * Real.sqrt (x ⬝ᵥ x) * hsx

#print axioms qr_exists_aux
#print axioms qr_unique_aux
#print axioms householder_dot_aux
#print axioms householder_length_aux

/-- QR exists and is unique: if the `n` columns of an `m × n` real table `A` are linearly
independent, then there is exactly one pair `(Q, R)` with `A = Q R`, where `Q` is `m × n` with
perpendicular unit columns (`Qᵀ Q = I`) and `R` is `n × n`, upper triangular (`r_ij = 0` for
`i > j`) with every diagonal entry positive. -/
theorem qr_factorisation_exists_unique {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ)
    (hA : LinearIndependent ℝ Aᵀ) :
    ∃! QR : Matrix (Fin m) (Fin n) ℝ × Matrix (Fin n) (Fin n) ℝ,
      QR.1ᵀ * QR.1 = 1 ∧ QR.2.BlockTriangular id ∧ (∀ i, 0 < QR.2 i i) ∧ A = QR.1 * QR.2 := by
  obtain ⟨Q, R, hQ, hR, hd, hAQR⟩ := qr_exists_aux A hA
  refine ⟨(Q, R), ⟨hQ, hR, hd, hAQR⟩, ?_⟩
  rintro ⟨Q', R'⟩ ⟨hQ', hR', hd', hA'⟩
  obtain ⟨h1, h2⟩ := qr_unique_aux Q' Q R' R hQ' hQ hR' hR hd' hd (hA'.symm.trans hAQR)
  rw [h1, h2]

/-- The Householder mirror: for a column piece `x` with top entry `x₁`, put
`v = x + sign(x₁) ‖x‖ e₁` (sign `+1` when `x₁ ≥ 0`, else `-1`) and `H = I - 2 v vᵀ / (vᵀ v)`.
Then `H` is symmetric, applying it twice gives `I` (so it keeps every length and angle), and it
sends `x` to `-sign(x₁) ‖x‖ e₁`, a point on the first axis. -/
theorem householder_mirror_folds_column_onto_axis {m : ℕ} (x : Fin (m + 1) → ℝ) :
    let s : ℝ := if 0 ≤ x 0 then 1 else -1
    let e₁ : Fin (m + 1) → ℝ := Pi.single 0 1
    let v : Fin (m + 1) → ℝ := x + (s * Real.sqrt (x ⬝ᵥ x)) • e₁
    let H : Matrix (Fin (m + 1)) (Fin (m + 1)) ℝ := 1 - (2 / (v ⬝ᵥ v)) • vecMulVec v v
    Hᵀ = H ∧ H * H = 1 ∧ H *ᵥ x = (-(s * Real.sqrt (x ⬝ᵥ x))) • e₁ := by
  intro s e₁ v H
  have hs : s * s = 1 := by simp only [s]; split_ifs <;> norm_num
  obtain ⟨hvv, hvx⟩ := householder_dot_aux x s hs
  refine ⟨?_, ?_, ?_⟩
  · simp only [H, transpose_sub, transpose_one, transpose_smul, transpose_vecMulVec]
  · have hPP : vecMulVec v v * vecMulVec v v = (v ⬝ᵥ v) • vecMulVec v v := by
      rw [vecMulVec_mul_vecMulVec, vecMulVec_smul]
    have hcc : 2 / (v ⬝ᵥ v) * (2 / (v ⬝ᵥ v) * (v ⬝ᵥ v)) = 2 / (v ⬝ᵥ v) + 2 / (v ⬝ᵥ v) := by
      by_cases h0 : v ⬝ᵥ v = 0
      · simp [h0]
      · field_simp; ring
    simp only [H, sub_mul, mul_sub, Matrix.one_mul, Matrix.mul_one, Matrix.smul_mul,
      Matrix.mul_smul, hPP, smul_smul, hcc, add_smul]
    abel
  · have hvv' : v ⬝ᵥ v = 2 * (x ⬝ᵥ x + s * Real.sqrt (x ⬝ᵥ x) * x 0) := hvv
    have hvx' : v ⬝ᵥ x = x ⬝ᵥ x + s * Real.sqrt (x ⬝ᵥ x) * x 0 := hvx
    have hlen : v ⬝ᵥ v = 2 * Real.sqrt (x ⬝ᵥ x) * (Real.sqrt (x ⬝ᵥ x) + |x 0|) :=
      householder_length_aux x
    have hHx : H *ᵥ x = x - (2 / (v ⬝ᵥ v) * (v ⬝ᵥ x)) • v := by
      simp only [H, sub_mulVec, one_mulVec, smul_mulVec, vecMulVec_mulVec, op_smul_eq_smul,
        smul_smul]
    by_cases h0 : v ⬝ᵥ v = 0
    · have hr0 : Real.sqrt (x ⬝ᵥ x) = 0 := by
        have h1 := Real.sqrt_nonneg (x ⬝ᵥ x)
        have h2 := abs_nonneg (x 0)
        nlinarith
      have hx0 : x = 0 := by
        apply dotProduct_self_eq_zero.mp
        have hxx : 0 ≤ x ⬝ᵥ x := Finset.sum_nonneg fun i _ => mul_self_nonneg (x i)
        rw [Real.sqrt_eq_zero hxx] at hr0
        exact hr0
      rw [hHx, h0, div_zero, zero_mul, zero_smul, sub_zero, hr0, mul_zero, neg_zero, zero_smul]
      exact hx0
    · have hw : x ⬝ᵥ x + s * Real.sqrt (x ⬝ᵥ x) * x 0 ≠ 0 := by
        intro hw; apply h0; rw [hvv', hw, mul_zero]
      have hone : 2 / (v ⬝ᵥ v) * (v ⬝ᵥ x) = 1 := by
        rw [hvv', hvx']; field_simp
      rw [hHx, hone, one_smul, neg_smul]
      simp only [v]
      abel

/-- The sign rule's shortcut: with `v = x + sign(x₁) ‖x‖ e₁`, the mirror's scale is
`vᵀ v = 2 ‖x‖ (‖x‖ + |x₁|)`, with no second dot product and no cancellation. -/
theorem householder_normal_length_sq {m : ℕ} (x : Fin (m + 1) → ℝ) :
    let s : ℝ := if 0 ≤ x 0 then 1 else -1
    let v : Fin (m + 1) → ℝ := x + (s * Real.sqrt (x ⬝ᵥ x)) • Pi.single 0 1
    v ⬝ᵥ v = 2 * Real.sqrt (x ⬝ᵥ x) * (Real.sqrt (x ⬝ᵥ x) + |x 0|) := by
  exact householder_length_aux x

-- Worked numbers: the distances are d_i = i/20 for i = 0, ..., 199. Their sum is 19900/20 = 995.
example : ∑ i ∈ Finset.range 200, i = 19900 := by
  decide +kernel

-- Their centred sum of squares: d_i - 4.975 = (2i - 199)/40, and 2666600/1600 = 1666.625.
example : ∑ i ∈ Finset.range 200, ((2 * i - 199 : ℤ)) ^ 2 = 2666600 := by
  decide +kernel

-- Flop counts at m = 200: Gram-Schmidt n(n-1)/2 (4m-1) + n(3m-1) for n = 2, 11, 50.
example : 2 * (2 - 1) / 2 * (4 * 200 - 1) + 2 * (3 * 200 - 1) = 1997 := by norm_num
example : 11 * (11 - 1) / 2 * (4 * 200 - 1) + 11 * (3 * 200 - 1) = 50534 := by norm_num
example : 50 * (50 - 1) / 2 * (4 * 200 - 1) + 50 * (3 * 200 - 1) = 1008725 := by norm_num

-- Householder R count at m = 200: the sum over k < n of (2(m-k)-1) + (n-k-1)(4(m-k)-1).
example : ∑ k ∈ Finset.range 2, ((2 * (200 - k) - 1) + (2 - k - 1) * (4 * (200 - k) - 1)) = 1595 := by
  decide +kernel
example : ∑ k ∈ Finset.range 11, ((2 * (200 - k) - 1) + (11 - k - 1) * (4 * (200 - k) - 1)) = 47564 := by
  decide +kernel
example : ∑ k ∈ Finset.range 50, ((2 * (200 - k) - 1) + (50 - k - 1) * (4 * (200 - k) - 1)) = 917875 := by
  decide +kernel

#print axioms qr_factorisation_exists_unique
#print axioms householder_mirror_folds_column_onto_axis
#print axioms householder_normal_length_sq
