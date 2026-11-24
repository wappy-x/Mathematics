-- Bilinear forms: a change of grid turns a form's matrix B into Pᵀ B P, every real symmetric matrix is congruent to a diagonal of 1s, −1s and 0s whose counts are the same for every invertible P (Sylvester's law of inertia), and an alternating form has even rank.
import Mathlib.LinearAlgebra.Matrix.BilinearForm
import Mathlib.LinearAlgebra.Matrix.Rank
import Mathlib.LinearAlgebra.Matrix.Symmetric
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Basic.Real.Basic
import Mathlib.Basic.Sign.Basic
import Mathlib.Analysis.Matrix.Spectrum

open Matrix

lemma sylvester_quad_congr {n : ℕ} (B P : Matrix (Fin n) (Fin n) ℝ) (v w : Fin n → ℝ) :
    (P *ᵥ v) ⬝ᵥ (B *ᵥ (P *ᵥ w)) = v ⬝ᵥ ((Pᵀ * B * P) *ᵥ w) := by
  simp only [dotProduct_mulVec, ← vecMul_vecMul, vecMul_transpose]

#print axioms sylvester_quad_congr

lemma sylvester_card_sum {n : ℕ} (s : Fin n → SignType) :
    (Finset.univ.filter fun i => s i = 1).card + (Finset.univ.filter fun i => s i = -1).card +
      (Finset.univ.filter fun i => s i = 0).card = n := by
  simp only [Finset.card_filter, ← Finset.sum_add_distrib]
  have : ∀ i, ((if s i = 1 then 1 else 0) + (if s i = -1 then 1 else 0) +
      (if s i = 0 then 1 else 0) : ℕ) = 1 := by
    intro i; cases s i <;> decide
  simp [this]

#print axioms sylvester_card_sum

lemma sylvester_pos_le {n : ℕ} (B P Q : Matrix (Fin n) (Fin n) ℝ) (s t : Fin n → SignType)
    (hQ : IsUnit Q.det)
    (hs : Pᵀ * B * P = diagonal (fun i => ((s i : SignType) : ℝ)))
    (ht : Qᵀ * B * Q = diagonal (fun i => ((t i : SignType) : ℝ))) :
    (Finset.univ.filter fun i => s i = 1).card ≤ (Finset.univ.filter fun i => t i = 1).card := by
  by_contra hlt
  push Not at hlt
  let E : ({i // s i = 1} → ℝ) →ₗ[ℝ] (Fin n → ℝ) :=
    LinearMap.pi (fun i => if h : s i = 1 then LinearMap.proj ⟨i, h⟩ else 0)
  have hE : ∀ x i, E x i = if h : s i = 1 then x ⟨i, h⟩ else 0 := by
    intro x i; simp only [E, LinearMap.pi_apply]; split_ifs <;> simp
  let R : (Fin n → ℝ) →ₗ[ℝ] ({j // t j = 1} → ℝ) := LinearMap.funLeft ℝ ℝ Subtype.val
  let f := R ∘ₗ (Q⁻¹ * P).mulVecLin ∘ₗ E
  have hker : LinearMap.ker f ≠ ⊥ := by
    apply LinearMap.ker_ne_bot_of_finrank_lt
    simp only [Module.finrank_fintype_fun_eq_card, Fintype.card_subtype]
    exact hlt
  obtain ⟨x, hx, hx0⟩ := Submodule.exists_mem_ne_zero_of_ne_bot hker
  set X := E x with hX
  set y := (Q⁻¹ * P) *ᵥ X with hy
  have hX0 : ∃ i, s i = 1 ∧ X i ≠ 0 := by
    by_contra hc
    push Not at hc
    apply hx0
    funext i
    have := hc i.1 i.2
    rw [hX, hE] at this
    simpa [i.2] using this
  have hy0 : ∀ j, t j = 1 → y j = 0 := by
    intro j hj
    have := congrFun (LinearMap.mem_ker.mp hx) ⟨j, hj⟩
    simpa [f, R, LinearMap.funLeft, hy, hX] using this
  have hQy : Q *ᵥ y = P *ᵥ X := by
    rw [hy, mulVec_mulVec, ← Matrix.mul_assoc, mul_nonsing_inv Q hQ, Matrix.one_mul]
  have h1 := sylvester_quad_congr B P X X
  have h2 := sylvester_quad_congr B Q y y
  rw [hQy] at h2
  have hd : ∀ (u : Fin n → SignType) (z : Fin n → ℝ),
      (diagonal fun i => ((u i : SignType) : ℝ)) *ᵥ z = fun i => ((u i : SignType) : ℝ) * z i := by
    intro u z; funext i; exact mulVec_diagonal _ _ _
  rw [hs, hd] at h1
  rw [ht, hd] at h2
  have hpos : 0 < X ⬝ᵥ fun i => ((s i : SignType) : ℝ) * X i := by
    obtain ⟨i0, hi0, hXi0⟩ := hX0
    apply Finset.sum_pos'
    · intro i _
      by_cases h : s i = 1
      · simp [h, mul_self_nonneg]
      · have : X i = 0 := by rw [hX, hE]; simp [h]
        simp [this]
    · exact ⟨i0, Finset.mem_univ _, by simp [hi0, mul_self_pos.mpr hXi0]⟩
  have hnonpos : (y ⬝ᵥ fun i => ((t i : SignType) : ℝ) * y i) ≤ 0 := by
    apply Finset.sum_nonpos
    intro j _
    by_cases h : t j = 1
    · simp [hy0 j h]
    · have : ((t j : SignType) : ℝ) ≤ 0 := by
        cases ht' : t j
        · simp
        · simp
        · exact absurd ht' h
      have := mul_nonpos_of_nonpos_of_nonneg this (mul_self_nonneg (y j))
      linarith [show y j * (((t j : SignType) : ℝ) * y j) = ((t j : SignType) : ℝ) * (y j * y j)
        by ring]
  linarith

#print axioms sylvester_pos_le

/-- **Sylvester's law of inertia.** A real symmetric matrix `B` is congruent to a diagonal of
1s, −1s and 0s: some invertible grid `P` gives `Pᵀ B P = diag(s)` with every `s i` in
{1, −1, 0}. And the counts of plus, minus and zero squares are the same for every such grid:
if invertible `P` and `Q` both turn `B` into sign diagonals `s` and `t`, then `s` and `t` have
the same number of 1s, the same number of −1s and the same number of 0s. -/
theorem sylvesters_law_of_inertia {n : ℕ} (B : Matrix (Fin n) (Fin n) ℝ) (hB : B.IsSymm) :
    (∃ (P : Matrix (Fin n) (Fin n) ℝ) (s : Fin n → SignType),
        IsUnit P.det ∧ Pᵀ * B * P = diagonal (fun i => ((s i : SignType) : ℝ))) ∧
    ∀ (P Q : Matrix (Fin n) (Fin n) ℝ) (s t : Fin n → SignType),
      IsUnit P.det → IsUnit Q.det →
      Pᵀ * B * P = diagonal (fun i => ((s i : SignType) : ℝ)) →
      Qᵀ * B * Q = diagonal (fun i => ((t i : SignType) : ℝ)) →
      (Finset.univ.filter fun i => s i = 1).card = (Finset.univ.filter fun i => t i = 1).card ∧
      (Finset.univ.filter fun i => s i = -1).card = (Finset.univ.filter fun i => t i = -1).card ∧
      (Finset.univ.filter fun i => s i = 0).card = (Finset.univ.filter fun i => t i = 0).card := by
  refine ⟨?_, ?_⟩
  · have hA : B.IsHermitian := isHermitian_iff_isSymm.mpr hB
    set U : Matrix (Fin n) (Fin n) ℝ := (hA.eigenvectorUnitary : Matrix (Fin n) (Fin n) ℝ) with hU
    set ev := hA.eigenvalues with hev
    have hD : Uᵀ * B * U = diagonal ev := by
      have h := hA.conjStarAlgAut_star_eigenvectorUnitary
      rw [Unitary.conjStarAlgAut_star_apply] at h
      have hst : (star hA.eigenvectorUnitary : Matrix (Fin n) (Fin n) ℝ) = Uᵀ := by
        rw [star_eq_conjTranspose, conjTranspose_eq_transpose_of_trivial]
      rw [hst] at h
      rw [h]
      congr 1
    have hUunit : IsUnit U.det := by
      apply Matrix.isUnit_det_of_left_inverse (B := Uᵀ)
      have := Unitary.coe_star_mul_self hA.eigenvectorUnitary
      rwa [star_eq_conjTranspose, conjTranspose_eq_transpose_of_trivial] at this
    let d : Fin n → ℝ := fun i => if ev i = 0 then 1 else 1 / Real.sqrt |ev i|
    refine ⟨U * diagonal d, fun i => SignType.sign (ev i), ?_, ?_⟩
    · rw [det_mul, det_diagonal]
      refine hUunit.mul (isUnit_iff_ne_zero.mpr (Finset.prod_ne_zero_iff.mpr fun i _ => ?_))
      simp only [d]
      split_ifs with h
      · exact one_ne_zero
      · have : 0 < |ev i| := abs_pos.mpr h
        positivity
    · rw [transpose_mul, diagonal_transpose, show diagonal d * Uᵀ * B * (U * diagonal d) =
          diagonal d * (Uᵀ * B * U) * diagonal d by simp only [Matrix.mul_assoc], hD,
        diagonal_mul_diagonal, diagonal_mul_diagonal]
      congr 1
      funext i
      simp only [d]
      rcases lt_trichotomy (ev i) 0 with h | h | h
      · have h0 : ev i ≠ 0 := h.ne
        simp only [h0, ↓reduceIte]; rw [sign_neg h, abs_of_neg h]
        have hs : 0 < -ev i := neg_pos.mpr h
        have := Real.sq_sqrt hs.le
        field_simp
        simp
        nlinarith [this]
      · simp [h]
      · have h0 : ev i ≠ 0 := h.ne'
        simp only [h0, ↓reduceIte]; rw [sign_pos h, abs_of_pos h]
        have := Real.sq_sqrt h.le
        field_simp
        simp
        nlinarith [this]
  · intro P Q s t hP hQ hs ht
    have hneg : ∀ (R : Matrix (Fin n) (Fin n) ℝ) (u : Fin n → SignType),
        Rᵀ * B * R = diagonal (fun i => ((u i : SignType) : ℝ)) →
        Rᵀ * (-B) * R = diagonal (fun i => ((-u i : SignType) : ℝ)) := by
      intro R u h
      rw [Matrix.mul_neg, Matrix.neg_mul, h, diagonal_neg]
      congr 1; funext i; simp
    have hfilt : ∀ u : Fin n → SignType,
        (Finset.univ.filter fun i => -u i = 1) = (Finset.univ.filter fun i => u i = -1) := by
      intro u; ext i; simp [neg_eq_iff_eq_neg]
    have hp : (Finset.univ.filter fun i => s i = 1).card =
        (Finset.univ.filter fun i => t i = 1).card :=
      le_antisymm (sylvester_pos_le B P Q s t hQ hs ht) (sylvester_pos_le B Q P t s hP ht hs)
    have hm : (Finset.univ.filter fun i => s i = -1).card =
        (Finset.univ.filter fun i => t i = -1).card := by
      rw [← hfilt s, ← hfilt t]
      exact le_antisymm
        (sylvester_pos_le (-B) P Q _ _ hQ (hneg P s hs) (hneg Q t ht))
        (sylvester_pos_le (-B) Q P _ _ hP (hneg Q t ht) (hneg P s hs))
    have hs3 := sylvester_card_sum s
    have ht3 := sylvester_card_sum t
    refine ⟨hp, hm, ?_⟩
    omega

/-- **The congruence rule.** If the new grid's arrows are the columns of `P`, so old
coordinates are `v = P v'` and `w = P w'`, then `vᵀ B w = v'ᵀ (Pᵀ B P) w'`: in the new grid the
form's matrix is `Pᵀ B P`. And `det (Pᵀ B P) = (det P)² det B`, so the determinant's sign
never changes under an invertible grid. -/
theorem congruence_rule {n : ℕ} (B P : Matrix (Fin n) (Fin n) ℝ) :
    (∀ v' w' : Fin n → ℝ,
      (P *ᵥ v') ⬝ᵥ (B *ᵥ (P *ᵥ w')) = v' ⬝ᵥ ((Pᵀ * B * P) *ᵥ w')) ∧
    (Pᵀ * B * P).det = P.det ^ 2 * B.det := by
  refine ⟨fun v w => ?_, ?_⟩
  · simp only [dotProduct_mulVec, ← vecMul_vecMul, vecMul_transpose]
  · rw [det_mul, det_mul, det_transpose]; ring

/-- **Alternating forms have even rank.** If the form `ω(v, w) = vᵀ S w` is alternating,
meaning `ω(v, v) = 0` for every vector `v`, then the rank of its matrix `S` is even. -/
theorem alternating_form_rank_even {n : ℕ} (S : Matrix (Fin n) (Fin n) ℝ)
    (hS : LinearMap.IsAlt (Matrix.toBilin' S)) : Even S.rank := by
  obtain ⟨W, hW⟩ := Submodule.exists_isCompl (LinearMap.ker (Sᵀ.mulVecLin))
  have hdim : Module.finrank ℝ W = S.rank := by
    have h1 := Submodule.finrank_add_eq_of_isCompl hW
    have h2 := LinearMap.finrank_range_add_finrank_ker (Sᵀ.mulVecLin)
    rw [← rank_transpose S]
    unfold Matrix.rank
    simp only [Module.finrank_fin_fun] at h1 h2
    omega
  set B' := (Matrix.toBilin' S).restrict W
  have hnd : B'.Nondegenerate := by
    apply LinearMap.BilinForm.Nondegenerate.ofSeparatingLeft
    intro w hw
    have hall : ∀ v : Fin n → ℝ, (w : Fin n → ℝ) ⬝ᵥ S *ᵥ v = 0 := by
      intro v
      have hv : v ∈ LinearMap.ker (Sᵀ.mulVecLin) ⊔ W := by rw [hW.sup_eq_top]; trivial
      obtain ⟨k, hk, u, hu, rfl⟩ := Submodule.mem_sup.mp hv
      have h1 : (w : Fin n → ℝ) ⬝ᵥ S *ᵥ u = 0 := by
        have := hw ⟨u, hu⟩
        simpa [B', LinearMap.BilinForm.restrict_apply, Matrix.toBilin'_apply'] using this
      have h2 : (w : Fin n → ℝ) ⬝ᵥ S *ᵥ k = 0 := by
        have hk' : k ᵥ* S = 0 := by simpa using hk
        have := hS.neg k (w : Fin n → ℝ)
        rw [Matrix.toBilin'_apply', Matrix.toBilin'_apply', dotProduct_mulVec, hk',
          zero_dotProduct, neg_zero] at this
        exact this.symm
      rw [mulVec_add, dotProduct_add, h1, h2, add_zero]
    have hwK : (w : Fin n → ℝ) ∈ LinearMap.ker (Sᵀ.mulVecLin) := by
      have : (w : Fin n → ℝ) ᵥ* S = 0 := by
        ext i
        have := hall (Pi.single i 1)
        rw [dotProduct_mulVec] at this
        simpa [dotProduct_single] using this
      simpa using this
    have := hW.disjoint.le_bot ⟨hwK, w.2⟩
    exact Subtype.ext (by simpa using this)
  set b := Module.finBasis ℝ W
  set M := LinearMap.BilinForm.toMatrix b B'
  have hdet := (LinearMap.BilinForm.nondegenerate_iff_det_ne_zero b).mp hnd
  have hskew : Mᵀ = -M := by
    ext i j
    show M j i = - M i j
    simp only [M, LinearMap.BilinForm.toMatrix_apply, B', LinearMap.BilinForm.restrict_apply,
      LinearMap.domRestrict_apply]
    exact (hS.neg _ _).symm
  have h : M.det = (-1) ^ Module.finrank ℝ W * M.det := by
    conv_lhs => rw [← det_transpose, hskew, det_neg]
    simp
  have hpow : ((-1 : ℝ)) ^ Module.finrank ℝ W = 1 := by
    have := mul_right_cancel₀ hdet (h.symm.trans (one_mul _).symm)
    exact this
  rw [← hdim]
  exact (neg_one_pow_eq_one_iff_even (by norm_num)).mp hpow

-- The pass: q(x, y) = x² + 4xy + y² has matrix [[1, 2], [2, 1]]; heights at (1, 0), (1, 1),
-- (1, −1) are 1, 6, −2.
example : ![1, 0] ⬝ᵥ (!![(1 : ℤ), 2; 2, 1] *ᵥ ![1, 0]) = 1 := by
  simp [dotProduct, mulVec, Fin.sum_univ_two]
example : ![1, 1] ⬝ᵥ (!![(1 : ℤ), 2; 2, 1] *ᵥ ![1, 1]) = 6 := by
  simp [dotProduct, mulVec, Fin.sum_univ_two]
example : ![1, -1] ⬝ᵥ (!![(1 : ℤ), 2; 2, 1] *ᵥ ![1, -1]) = -2 := by
  simp [dotProduct, mulVec, Fin.sum_univ_two]

-- The pairing B(e₁, e₂) = 2, and from heights (q(1, 1) − q(1, 0) − q(0, 1)) / 2 = (6 − 1 − 1) / 2 = 2.
example : ![1, 0] ⬝ᵥ (!![(1 : ℤ), 2; 2, 1] *ᵥ ![0, 1]) = 2 := by
  simp [dotProduct, mulVec, Fin.sum_univ_two]
example : ((6 : ℤ) - 1 - 1) / 2 = 2 := by norm_num

-- Completing the square: P = [[1, −2], [0, 1]] gives Pᵀ B P = [[1, 0], [0, −3]].
example : (!![(1 : ℤ), -2; 0, 1])ᵀ * !![(1 : ℤ), 2; 2, 1] * !![(1 : ℤ), -2; 0, 1] =
    !![1, 0; 0, -3] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two]

-- det B = −3, and the eigenvalues are 3 and −1 (eigenvectors (1, 1) and (1, −1)).
example : (!![(1 : ℤ), 2; 2, 1]).det = -3 := by simp [det_fin_two]
example : !![(1 : ℤ), 2; 2, 1] *ᵥ ![1, 1] = (3 : ℤ) • ![1, 1] := by
  ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_two]
example : !![(1 : ℤ), 2; 2, 1] *ᵥ ![1, -1] = (-1 : ℤ) • ![1, -1] := by
  ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_two]

-- Signed area: legs (3, 1), (1, 2) give ad − bc = 5 with Ω = [[0, 1], [−1, 0]]; swapped, −5;
-- a leg with itself, 0.
example : ![3, 1] ⬝ᵥ (!![(0 : ℤ), 1; -1, 0] *ᵥ ![1, 2]) = 5 := by
  simp [dotProduct, mulVec, Fin.sum_univ_two]
example : ![1, 2] ⬝ᵥ (!![(0 : ℤ), 1; -1, 0] *ᵥ ![3, 1]) = -5 := by
  simp [dotProduct, mulVec, Fin.sum_univ_two]
example : ![3, 1] ⬝ᵥ (!![(0 : ℤ), 1; -1, 0] *ᵥ ![3, 1]) = 0 := by
  simp [dotProduct, mulVec, Fin.sum_univ_two]

-- Step 5 on [[0, 1, 2], [−1, 0, 3], [−2, −3, 0]]: the leftover vector (3, −2, 1) pairs to zero
-- with everything.
example : !![(0 : ℤ), 1, 2; -1, 0, 3; -2, -3, 0] *ᵥ ![3, -2, 1] = 0 := by
  ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_succ]

-- Mistake 1: similarity P⁻¹ B P = [[1, 2], [0, 1]] B [[1, −2], [0, 1]] = [[5, −6], [2, −3]].
example : !![(1 : ℤ), 2; 0, 1] * !![(1 : ℤ), -2; 0, 1] = 1 := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two]
example : !![(1 : ℤ), 2; 0, 1] * !![(1 : ℤ), 2; 2, 1] * !![(1 : ℤ), -2; 0, 1] =
    !![5, -6; 2, -3] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two]

-- Mistake 2: the flattening grid P = [[1, 1], [1, 1]] gives Pᵀ B P = [[6, 6], [6, 6]].
example : (!![(1 : ℤ), 1; 1, 1])ᵀ * !![(1 : ℤ), 2; 2, 1] * !![(1 : ℤ), 1; 1, 1] =
    !![6, 6; 6, 6] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two]

#print axioms sylvesters_law_of_inertia
#print axioms congruence_rule
#print axioms alternating_form_rank_even
