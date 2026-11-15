-- Elliptic, parabolic, hyperbolic: changing variables turns the top coefficient matrix A into J A Jᵀ and keeps the number of positive, negative and zero eigenvalues, an equation is elliptic exactly when its principal symbol vanishes in no nonzero direction, and the drum's cone r = c t is characteristic.
import Mathlib.Analysis.Matrix.Spectrum
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt

open Matrix

/-- The principal symbol `p(ξ) = ξᵀ A ξ = ∑ a_ij ξ_i ξ_j` of the top coefficient matrix `A`
in the direction `ξ`. -/
def principalSymbol {d : ℕ} (A : Matrix (Fin d) (Fin d) ℝ) (ξ : Fin d → ℝ) : ℝ :=
  ξ ⬝ᵥ (A *ᵥ ξ)

/-- How many eigenvalues of the symmetric matrix `A` are positive. -/
noncomputable def posCount {d : ℕ} {A : Matrix (Fin d) (Fin d) ℝ} (hA : A.IsHermitian) : ℕ :=
  (Finset.univ.filter fun i => 0 < hA.eigenvalues i).card

/-- How many eigenvalues of the symmetric matrix `A` are negative. -/
noncomputable def negCount {d : ℕ} {A : Matrix (Fin d) (Fin d) ℝ} (hA : A.IsHermitian) : ℕ :=
  (Finset.univ.filter fun i => hA.eigenvalues i < 0).card

/-- How many eigenvalues of the symmetric matrix `A` are zero. -/
noncomputable def zeroCount {d : ℕ} {A : Matrix (Fin d) (Fin d) ℝ} (hA : A.IsHermitian) : ℕ :=
  (Finset.univ.filter fun i => hA.eigenvalues i = 0).card

/-- Elliptic at a point: all eigenvalues of the top coefficient matrix have one sign. -/
def IsElliptic {d : ℕ} {A : Matrix (Fin d) (Fin d) ℝ} (hA : A.IsHermitian) : Prop :=
  (∀ i, 0 < hA.eigenvalues i) ∨ (∀ i, hA.eigenvalues i < 0)

/-- Over the reals `Jᴴ = Jᵀ`, so `J A Jᵀ` is symmetric whenever `A` is. -/
theorem isHermitian_mul_mul_transpose {d : ℕ} {A : Matrix (Fin d) (Fin d) ℝ}
    (J : Matrix (Fin d) (Fin d) ℝ) (hA : A.IsHermitian) : (J * A * Jᵀ).IsHermitian := by
  simpa [conjTranspose_eq_transpose_of_trivial] using isHermitian_mul_mul_conjTranspose J hA

theorem mulVec_dotProduct_eq {d : ℕ} (M : Matrix (Fin d) (Fin d) ℝ) (x y : Fin d → ℝ) :
    (M *ᵥ x) ⬝ᵥ y = x ⬝ᵥ (Mᵀ *ᵥ y) := by
  rw [dotProduct_comm, dotProduct_mulVec, ← mulVec_transpose, dotProduct_comm]

theorem star_eigenvectorUnitary_eq_transpose {d : ℕ} {A : Matrix (Fin d) (Fin d) ℝ}
    (hA : A.IsHermitian) : (star (hA.eigenvectorUnitary : Matrix (Fin d) (Fin d) ℝ)) =
      (hA.eigenvectorUnitary : Matrix (Fin d) (Fin d) ℝ)ᵀ := by
  rw [star_eq_conjTranspose, conjTranspose_eq_transpose_of_trivial]

theorem principalSymbol_eigenvectorUnitary_mulVec {d : ℕ} {A : Matrix (Fin d) (Fin d) ℝ}
    (hA : A.IsHermitian) (y : Fin d → ℝ) :
    principalSymbol A ((hA.eigenvectorUnitary : Matrix (Fin d) (Fin d) ℝ) *ᵥ y) =
      ∑ i, hA.eigenvalues i * y i ^ 2 := by
  have hD := hA.conjStarAlgAut_star_eigenvectorUnitary
  rw [Unitary.conjStarAlgAut_star_apply] at hD
  simp only [star_eigenvectorUnitary_eq_transpose hA] at hD
  unfold principalSymbol
  rw [mulVec_dotProduct_eq, mulVec_mulVec, mulVec_mulVec, hD]
  simp [dotProduct, mulVec_diagonal]
  refine Finset.sum_congr rfl fun i _ => by ring

theorem eigenvectorUnitary_transpose_mul {d : ℕ} {A : Matrix (Fin d) (Fin d) ℝ}
    (hA : A.IsHermitian) : (hA.eigenvectorUnitary : Matrix (Fin d) (Fin d) ℝ)ᵀ *
      (hA.eigenvectorUnitary : Matrix (Fin d) (Fin d) ℝ) = 1 := by
  rw [← star_eigenvectorUnitary_eq_transpose hA, Unitary.coe_star_mul_self]

theorem eigenvectorUnitary_mul_transpose {d : ℕ} {A : Matrix (Fin d) (Fin d) ℝ}
    (hA : A.IsHermitian) : (hA.eigenvectorUnitary : Matrix (Fin d) (Fin d) ℝ) *
      (hA.eigenvectorUnitary : Matrix (Fin d) (Fin d) ℝ)ᵀ = 1 := by
  rw [← star_eigenvectorUnitary_eq_transpose hA, Unitary.mul_star_self_of_mem (hA.eigenvectorUnitary).2]

theorem principalSymbol_eq_sum {d : ℕ} {A : Matrix (Fin d) (Fin d) ℝ}
    (hA : A.IsHermitian) (x : Fin d → ℝ) :
    principalSymbol A x = ∑ i, hA.eigenvalues i *
      (((hA.eigenvectorUnitary : Matrix (Fin d) (Fin d) ℝ)ᵀ *ᵥ x) i) ^ 2 := by
  rw [← principalSymbol_eigenvectorUnitary_mulVec hA, mulVec_mulVec,
    eigenvectorUnitary_mul_transpose, one_mulVec]

theorem principalSymbol_mul_mul_transpose {d : ℕ} (A J : Matrix (Fin d) (Fin d) ℝ)
    (x : Fin d → ℝ) : principalSymbol (J * A * Jᵀ) x = principalSymbol A (Jᵀ *ᵥ x) := by
  unfold principalSymbol
  rw [← mulVec_mulVec, ← mulVec_mulVec, dotProduct_comm, mulVec_dotProduct_eq]
  exact dotProduct_comm _ _

theorem signCount_le_of_eq_mul_mul_transpose {d : ℕ} (s : ℝ) {A B J : Matrix (Fin d) (Fin d) ℝ}
    (hA : A.IsHermitian) (hB : B.IsHermitian) (h : B = J * A * Jᵀ) :
    (Finset.univ.filter fun i => 0 < s * hB.eigenvalues i).card ≤
      (Finset.univ.filter fun i => 0 < s * hA.eigenvalues i).card := by
  classical
  rw [← Fintype.card_subtype, ← Fintype.card_subtype]
  set pA : Fin d → Prop := fun i => 0 < s * hA.eigenvalues i with hpA
  set pB : Fin d → Prop := fun i => 0 < s * hB.eigenvalues i with hpB
  set UA := (hA.eigenvectorUnitary : Matrix (Fin d) (Fin d) ℝ)
  set UB := (hB.eigenvectorUnitary : Matrix (Fin d) (Fin d) ℝ)
  let e : ({i // pB i} → ℝ) →ₗ[ℝ] (Fin d → ℝ) :=
    LinearMap.pi fun i => if h : pB i then LinearMap.proj (⟨i, h⟩ : {i // pB i}) else 0
  let r : (Fin d → ℝ) →ₗ[ℝ] ({i // pA i} → ℝ) := LinearMap.pi fun i => LinearMap.proj i.1
  let f := r ∘ₗ (mulVecLin (UAᵀ * Jᵀ * UB)) ∘ₗ e
  have he : ∀ c i, e c i = if h : pB i then c ⟨i, h⟩ else 0 := by
    intro c i
    simp only [e, LinearMap.pi_apply]
    split_ifs <;> simp
  have hf : Function.Injective f := by
    rw [← LinearMap.ker_eq_bot, LinearMap.ker_eq_bot']
    intro c hc
    have key := principalSymbol_mul_mul_transpose A J (UB *ᵥ e c)
    rw [← h, principalSymbol_eigenvectorUnitary_mulVec hB, principalSymbol_eq_sum hA,
      mulVec_mulVec, mulVec_mulVec] at key
    have hz : ∀ i, pA i → (((UAᵀ * Jᵀ * UB) *ᵥ e c) i) = 0 := by
      intro i hi
      exact congrFun hc ⟨i, hi⟩
    have hR : s * ∑ i, hA.eigenvalues i * (((UAᵀ * Jᵀ * UB) *ᵥ e c) i) ^ 2 ≤ 0 := by
      rw [Finset.mul_sum]
      refine Finset.sum_nonpos fun i _ => ?_
      by_cases hi : pA i
      · simp [hz i hi]
      · have : s * hA.eigenvalues i ≤ 0 := not_lt.mp hi
        have := mul_nonpos_of_nonpos_of_nonneg this (sq_nonneg (((UAᵀ * Jᵀ * UB) *ᵥ e c) i))
        linarith
    have hterm : ∀ i, 0 ≤ s * (hB.eigenvalues i * (e c i) ^ 2) := by
      intro i
      by_cases hi : pB i
      · have := mul_nonneg hi.le (sq_nonneg (e c i)); linarith
      · simp [he, hi]
    have hzero : ∑ i, s * (hB.eigenvalues i * (e c i) ^ 2) = 0 := by
      rw [← Finset.mul_sum, key]
      exact le_antisymm hR (by rw [← key, Finset.mul_sum]; exact Finset.sum_nonneg fun i _ => hterm i)
    rw [Finset.sum_eq_zero_iff_of_nonneg fun i _ => hterm i] at hzero
    funext j
    have hj := hzero j.1 (Finset.mem_univ _)
    simp only [he, j.2, ↓reduceDIte] at hj
    have hpos : 0 < s * hB.eigenvalues j.1 := j.2
    have : c j ^ 2 = 0 := by
      have : (s * hB.eigenvalues j.1) * c j ^ 2 = 0 := by rw [← hj]; ring
      rcases mul_eq_zero.mp this with h1 | h1
      · exact absurd h1 hpos.ne'
      · exact h1
    simpa using this
  have := LinearMap.finrank_le_finrank_of_injective hf
  simpa using this

theorem card_pos_add_card_neg_add_card_zero {d : ℕ} (f : Fin d → ℝ) :
    (Finset.univ.filter fun i => 0 < f i).card + (Finset.univ.filter fun i => f i < 0).card +
      (Finset.univ.filter fun i => f i = 0).card = d := by
  simp only [Finset.card_filter, ← Finset.sum_add_distrib]
  calc _ = ∑ _i : Fin d, 1 := Finset.sum_congr rfl fun i _ => ?_
    _ = d := by simp
  rcases lt_trichotomy (f i) 0 with h | h | h
  · simp [h, h.ne, not_lt.mpr h.le]
  · simp [h]
  · simp [h, h.ne', not_lt.mpr h.le]

/-- Sylvester's law of inertia, the card's Step 1: a change of variables with invertible
Jacobian `J` turns the symmetric top coefficient matrix `A` into `J A Jᵀ`, and this sandwich
keeps the number of positive, of negative and of zero eigenvalues. So the family (elliptic,
parabolic, hyperbolic) does not depend on the coordinates. -/
theorem sign_counts_invariant_under_change_of_variables {d : ℕ}
    (A J : Matrix (Fin d) (Fin d) ℝ) (hA : A.IsHermitian) (hJ : IsUnit J.det) :
    posCount (isHermitian_mul_mul_transpose J hA) = posCount hA ∧
      negCount (isHermitian_mul_mul_transpose J hA) = negCount hA ∧
      zeroCount (isHermitian_mul_mul_transpose J hA) = zeroCount hA := by
  have hB := isHermitian_mul_mul_transpose J hA
  have hAeq : A = J⁻¹ * (J * A * Jᵀ) * (J⁻¹)ᵀ := by
    have hJt : IsUnit Jᵀ.det := by rwa [det_transpose]
    rw [transpose_nonsing_inv, Matrix.mul_assoc, Matrix.mul_assoc, mul_nonsing_inv _ hJt,
      Matrix.mul_one, ← Matrix.mul_assoc, nonsing_inv_mul _ hJ, Matrix.one_mul]
  have hs : ∀ s : ℝ,
      (Finset.univ.filter fun i => 0 < s * (isHermitian_mul_mul_transpose J hA).eigenvalues i).card
        = (Finset.univ.filter fun i => 0 < s * hA.eigenvalues i).card := fun s =>
    le_antisymm (signCount_le_of_eq_mul_mul_transpose s hA _ rfl)
      (signCount_le_of_eq_mul_mul_transpose s _ hA hAeq)
  have hpos : posCount (isHermitian_mul_mul_transpose J hA) = posCount hA := by
    simpa [posCount] using hs 1
  have hneg : negCount (isHermitian_mul_mul_transpose J hA) = negCount hA := by
    simpa [negCount] using hs (-1)
  refine ⟨hpos, hneg, ?_⟩
  have h1 := card_pos_add_card_neg_add_card_zero (isHermitian_mul_mul_transpose J hA).eigenvalues
  have h2 := card_pos_add_card_neg_add_card_zero hA.eigenvalues
  unfold posCount at hpos
  unfold negCount at hneg
  unfold zeroCount
  omega

/-- Step 2: no surface is characteristic for an elliptic equation, and only for it. The
principal symbol of a symmetric `A` is nonzero in every nonzero direction exactly when all
eigenvalues of `A` have one sign. -/
theorem symbol_never_zero_iff_elliptic {d : ℕ} (A : Matrix (Fin d) (Fin d) ℝ)
    (hA : A.IsHermitian) :
    (∀ ξ : Fin d → ℝ, ξ ≠ 0 → principalSymbol A ξ ≠ 0) ↔ IsElliptic hA := by
  set U := (hA.eigenvectorUnitary : Matrix (Fin d) (Fin d) ℝ) with hU
  have hUt : Uᵀ * U = 1 := eigenvectorUnitary_transpose_mul hA
  have hUt' : U * Uᵀ = 1 := eigenvectorUnitary_mul_transpose hA
  have hUinj : ∀ y : Fin d → ℝ, y ≠ 0 → U *ᵥ y ≠ 0 := by
    intro y hy h0
    apply hy
    have := congrArg (fun z => Uᵀ *ᵥ z) h0
    simpa [mulVec_mulVec, hUt] using this
  constructor
  · intro hne
    by_contra hE
    unfold IsElliptic at hE
    push Not at hE
    obtain ⟨⟨i, hi⟩, ⟨j, hj⟩⟩ := hE
    by_cases hz : ∃ k, hA.eigenvalues k = 0
    · obtain ⟨k, hk⟩ := hz
      have hy : (Pi.single k 1 : Fin d → ℝ) ≠ 0 := by simp
      apply hne _ (hUinj _ hy)
      rw [principalSymbol_eigenvectorUnitary_mulVec hA]
      rw [Finset.sum_eq_single k]
      · simp [hk]
      · intro b _ hb; simp [hb]
      · simp
    · push Not at hz
      have hi' : hA.eigenvalues i < 0 := lt_of_le_of_ne hi (hz i)
      have hj' : 0 < hA.eigenvalues j := lt_of_le_of_ne hj (hz j).symm
      have hij : i ≠ j := by rintro rfl; linarith
      set y : Fin d → ℝ := fun k => if k = i then Real.sqrt (hA.eigenvalues j)
        else if k = j then Real.sqrt (-hA.eigenvalues i) else 0 with hydef
      have hy : y ≠ 0 := by
        intro h0
        have := congrFun h0 i
        simp [hydef] at this
        exact (Real.sqrt_pos.mpr hj').ne' this
      apply hne _ (hUinj _ hy)
      rw [principalSymbol_eigenvectorUnitary_mulVec hA, Fintype.sum_eq_add i j hij]
      · simp [hydef, hij.symm, Real.sq_sqrt hj'.le, Real.sq_sqrt (neg_nonneg.mpr hi)]
        ring
      · rintro k ⟨hki, hkj⟩
        simp [hydef, hki, hkj]
  · intro hE ξ hξ
    rw [principalSymbol_eq_sum hA]
    have hy : Uᵀ *ᵥ ξ ≠ 0 := by
      intro h0
      apply hξ
      have := congrArg (fun z => U *ᵥ z) h0
      simpa [mulVec_mulVec, hUt'] using this
    obtain ⟨k, hk⟩ := Function.ne_iff.mp hy
    have hk2 : 0 < ((Uᵀ *ᵥ ξ) k) ^ 2 := lt_of_le_of_ne (sq_nonneg _) (Ne.symm (pow_ne_zero 2 hk))
    rcases hE with hpos | hneg
    · refine ne_of_gt (Finset.sum_pos' (fun i _ => ?_) ⟨k, Finset.mem_univ _, ?_⟩)
      · exact mul_nonneg (hpos i).le (sq_nonneg _)
      · exact mul_pos (hpos k) hk2
    · refine ne_of_lt (Finset.sum_neg' (fun i _ => ?_) ⟨k, Finset.mem_univ _, ?_⟩)
      · exact mul_nonpos_of_nonpos_of_nonneg (hneg i).le (sq_nonneg _)
      · exact mul_neg_of_neg_of_pos (hneg k) hk2

/-- Step 2, the drum: in the variables `(x, y, t)` the wave equation
`c² (u_xx + u_yy) − u_tt = 0` has top matrix `diag(c², c², −1)`, and the cone
`φ(x, y, t) = √(x² + y²) − c t` is characteristic: away from the axis `x = y = 0`, the symbol
on its normal `∇φ` is zero. -/
theorem drum_cone_is_characteristic (c : ℝ) (v : Fin 3 → ℝ) (hv : (v 0, v 1) ≠ (0, 0)) :
    principalSymbol (Matrix.diagonal ![c ^ 2, c ^ 2, -1])
      (fun i => fderiv ℝ (fun w : Fin 3 → ℝ => Real.sqrt (w 0 ^ 2 + w 1 ^ 2) - c * w 2) v
        (Pi.single i 1)) = 0 := by
  have hr : v 0 ^ 2 + v 1 ^ 2 ≠ 0 := by
    intro h
    apply hv
    have h0 : v 0 = 0 := by nlinarith [sq_nonneg (v 0), sq_nonneg (v 1)]
    have h1 : v 1 = 0 := by nlinarith [sq_nonneg (v 0), sq_nonneg (v 1)]
    simp [h0, h1]
  have h0 : HasFDerivAt (fun w : Fin 3 → ℝ => w 0) (ContinuousLinearMap.proj (R := ℝ) (φ := fun _ : Fin 3 => ℝ) 0) v :=
    hasFDerivAt_apply (𝕜 := ℝ) 0 v
  have h1 : HasFDerivAt (fun w : Fin 3 → ℝ => w 1) (ContinuousLinearMap.proj (R := ℝ) (φ := fun _ : Fin 3 => ℝ) 1) v :=
    hasFDerivAt_apply (𝕜 := ℝ) 1 v
  have h2 : HasFDerivAt (fun w : Fin 3 → ℝ => w 2) (ContinuousLinearMap.proj (R := ℝ) (φ := fun _ : Fin 3 => ℝ) 2) v :=
    hasFDerivAt_apply (𝕜 := ℝ) 2 v
  have hF := (((h0.pow 2).add (h1.pow 2)).sqrt hr).sub (h2.const_mul c)
  have hF' : HasFDerivAt (fun w : Fin 3 → ℝ => Real.sqrt (w 0 ^ 2 + w 1 ^ 2) - c * w 2) _ v := hF
  rw [hF'.fderiv]
  simp [principalSymbol, dotProduct, mulVec, diagonal, Fin.sum_univ_succ, Pi.single_apply]
  have hpos : 0 < v 0 ^ 2 + v 1 ^ 2 := lt_of_le_of_ne (by positivity) (Ne.symm hr)
  have hs : Real.sqrt (v 0 ^ 2 + v 1 ^ 2) ^ 2 = v 0 ^ 2 + v 1 ^ 2 := Real.sq_sqrt hpos.le
  have hs0 : Real.sqrt (v 0 ^ 2 + v 1 ^ 2) ≠ 0 := (Real.sqrt_pos.mpr hpos).ne'
  field_simp
  linear_combination (-(c ^ 2)) * hs

-- The trap u_xx + u_yy + u_zz + 4(u_xy + u_yz + u_xz): matrix with 1 on the diagonal and 2 off
-- it has eigenvalues 5, −1, −1, shown by three independent eigenvectors.
example : !![(1 : ℤ), 2, 2; 2, 1, 2; 2, 2, 1] *ᵥ ![1, 1, 1] = (5 : ℤ) • ![1, 1, 1] := by
  ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_succ]
example : !![(1 : ℤ), 2, 2; 2, 1, 2; 2, 2, 1] *ᵥ ![1, -1, 0] = (-1 : ℤ) • ![1, -1, 0] := by
  ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_succ]
example : !![(1 : ℤ), 2, 2; 2, 1, 2; 2, 2, 1] *ᵥ ![1, 0, -1] = (-1 : ℤ) • ![1, 0, -1] := by
  ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_succ]

-- u_xx + 2u_xy + u_yy halved right (off-diagonal 1): eigenvalues 2 and 0, parabolic.
example : !![(1 : ℤ), 1; 1, 1] *ᵥ ![1, 1] = (2 : ℤ) • ![1, 1] := by
  ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_succ]
example : !![(1 : ℤ), 1; 1, 1] *ᵥ ![1, -1] = (0 : ℤ) • ![1, -1] := by
  ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_succ]

-- Not halved (off-diagonal 2): eigenvalues 3 and −1, wrongly hyperbolic.
example : !![(1 : ℤ), 2; 2, 1] *ᵥ ![1, 1] = (3 : ℤ) • ![1, 1] := by
  ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_succ]
example : !![(1 : ℤ), 2; 2, 1] *ᵥ ![1, -1] = (-1 : ℤ) • ![1, -1] := by
  ext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_succ]

-- Drum front speed: with c = 100 m/s the symbol diag(10000, 10000, −1) vanishes on the
-- direction (1, 0, −100), so a front moves at s = 100 m/s.
example : principalSymbol (Matrix.diagonal ![10000, 10000, -1]) ![1, 0, -100] = 0 := by
  norm_num [principalSymbol, mulVec, dotProduct, Fin.sum_univ_succ, diagonal]

-- Cooling: the slice t = const, normal (0, 0, 1), is characteristic for diag(κ, κ, 0).
example (κ : ℝ) : principalSymbol (Matrix.diagonal ![κ, κ, 0]) ![0, 0, 1] = 0 := by
  norm_num [principalSymbol, mulVec, dotProduct, Fin.sum_univ_succ, diagonal]

#print axioms mulVec_dotProduct_eq
#print axioms star_eigenvectorUnitary_eq_transpose
#print axioms principalSymbol_eigenvectorUnitary_mulVec
#print axioms eigenvectorUnitary_transpose_mul
#print axioms eigenvectorUnitary_mul_transpose
#print axioms principalSymbol_eq_sum
#print axioms principalSymbol_mul_mul_transpose
#print axioms signCount_le_of_eq_mul_mul_transpose
#print axioms card_pos_add_card_neg_add_card_zero
#print axioms isHermitian_mul_mul_transpose
#print axioms sign_counts_invariant_under_change_of_variables
#print axioms symbol_never_zero_iff_elliptic
#print axioms drum_cone_is_characteristic
