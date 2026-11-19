-- Smith normal form: every matrix over a ring with division with remainder (such as ℤ or k[x]) is brought by moves the ring can undo to a diagonal whose entries each divide the next, its module splits into one counter per entry, and for x I − A the monic diagonal gives A's rational canonical form and decides similarity.
import Mathlib.LinearAlgebra.Matrix.Charpoly.Basic
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.Data.Matrix.Block
import Mathlib.Algebra.EuclideanDomain.Basic
import Mathlib.RingTheory.Ideal.Quotient.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.RingTheory.AdjoinRoot
import Mathlib.Algebra.Polynomial.Module.AEval
import Mathlib.LinearAlgebra.Quotient.Pi
import Mathlib.LinearAlgebra.Matrix.Transvection
import Mathlib.LinearAlgebra.Matrix.Block
import Mathlib.RingTheory.PrincipalIdealDomain
import Mathlib.Algebra.Polynomial.FieldDivision
import Mathlib.LinearAlgebra.Matrix.Basis
import Mathlib.LinearAlgebra.Dimension.Constructions
import Mathlib.LinearAlgebra.Matrix.Charpoly.Coeff

open Matrix Polynomial

/-- The companion matrix C(f) of f = x^m + c_{m-1}x^{m-1} + ⋯ + c_0, as on the card:
1s just below the diagonal and −c_0, …, −c_{m-1} down the last column. -/
noncomputable def companion {K : Type*} [Field K] (f : K[X]) :
    Matrix (Fin f.natDegree) (Fin f.natDegree) K :=
  fun i j => (if (i : ℕ) = (j : ℕ) + 1 then 1 else 0) -
    (if (j : ℕ) + 1 = f.natDegree then f.coeff i else 0)

section PartA

/-- The matrix with `a` in the top left corner, zeros in the rest of the first row and column,
and `M` in the lower right block. -/
def cornerBlock {R : Type*} [Zero R] {m n : ℕ} (a : R) (M : Matrix (Fin m) (Fin n) R) :
    Matrix (Fin (m + 1)) (Fin (n + 1)) R :=
  Matrix.of fun i j => Fin.cases (Fin.cases a (fun _ => 0) j) (fun i' => Fin.cases 0 (fun j' => M i' j') j) i

lemma cornerBlock_mul {R : Type*} [CommRing R] {l m n : ℕ} (a b : R) (M : Matrix (Fin l) (Fin m) R)
    (N : Matrix (Fin m) (Fin n) R) :
    cornerBlock a M * cornerBlock b N = cornerBlock (a * b) (M * N) := by
  ext i j
  refine Fin.cases ?_ (fun i => ?_) i <;> refine Fin.cases ?_ (fun j => ?_) j <;>
    simp [cornerBlock, Matrix.mul_apply, Fin.sum_univ_succ]
#print axioms cornerBlock_mul

lemma det_cornerBlock_one {R : Type*} [CommRing R] {m : ℕ} (M : Matrix (Fin m) (Fin m) R) :
    (cornerBlock 1 M).det = M.det := by
  rw [Matrix.det_succ_row_zero, Fin.sum_univ_succ]
  simp only [cornerBlock, Fin.succAbove_zero]
  simp
  congr 1
#print axioms det_cornerBlock_one

lemma one_submatrix_mul_apply' {R : Type*} [CommRing R] {m n : ℕ} (σ : Equiv.Perm (Fin m))
    (M : Matrix (Fin m) (Fin n) R) (a : Fin m) (b : Fin n) :
    ((1 : Matrix (Fin m) (Fin m) R).submatrix σ id * M) a b = M (σ a) b := by
  simp [Matrix.mul_apply, Matrix.one_apply]
#print axioms one_submatrix_mul_apply'

lemma mul_one_submatrix_apply' {R : Type*} [CommRing R] {m n : ℕ} (σ : Equiv.Perm (Fin n))
    (M : Matrix (Fin m) (Fin n) R) (a : Fin m) (b : Fin n) :
    (M * (1 : Matrix (Fin n) (Fin n) R).submatrix id σ) a b = M a (σ b) := by
  simp [Matrix.mul_apply, Matrix.one_apply]
#print axioms mul_one_submatrix_apply'

lemma isUnit_det_one_submatrix_left {R : Type*} [CommRing R] {m : ℕ} (σ : Equiv.Perm (Fin m)) :
    IsUnit ((1 : Matrix (Fin m) (Fin m) R).submatrix σ id).det := by
  rw [Matrix.det_permute]
  rcases Int.units_eq_one_or (Equiv.Perm.sign σ) with h | h <;> simp [h]
#print axioms isUnit_det_one_submatrix_left

lemma isUnit_det_one_submatrix_right {R : Type*} [CommRing R] {m : ℕ} (σ : Equiv.Perm (Fin m)) :
    IsUnit ((1 : Matrix (Fin m) (Fin m) R).submatrix id σ).det := by
  rw [Matrix.det_permute']
  rcases Int.units_eq_one_or (Equiv.Perm.sign σ) with h | h <;> simp [h]
#print axioms isUnit_det_one_submatrix_right

/-- If the corner of `S N T` is a nonzero entry that is minimal for the Euclidean order among all
such corners, it divides every entry of the first row. -/
lemma corner_dvd_row {R : Type*} [EuclideanDomain R] {m n : ℕ} (N : Matrix (Fin (m + 1)) (Fin (n + 1)) R)
    (c : R) (hc0 : c ≠ 0)
    (hmin : ∀ (S : Matrix (Fin (m + 1)) (Fin (m + 1)) R) (T : Matrix (Fin (n + 1)) (Fin (n + 1)) R),
      IsUnit S.det → IsUnit T.det → (S * N * T) 0 0 ≠ 0 → ¬ EuclideanDomain.r ((S * N * T) 0 0) c)
    (S : Matrix (Fin (m + 1)) (Fin (m + 1)) R) (T : Matrix (Fin (n + 1)) (Fin (n + 1)) R)
    (hS : IsUnit S.det) (hT : IsUnit T.det) (h0 : (S * N * T) 0 0 = c) (j : Fin (n + 1)) :
    c ∣ (S * N * T) 0 j := by
  by_contra hdvd
  have hj : j ≠ 0 := by rintro rfl; exact hdvd (h0 ▸ dvd_refl _)
  set x := (S * N * T) 0 j
  have hx : x % c ≠ 0 := fun h => hdvd (EuclideanDomain.mod_eq_zero.mp h)
  let T' := T * transvection 0 j (-(x / c)) * (1 : Matrix (Fin (n + 1)) (Fin (n + 1)) R).submatrix id
    (Equiv.swap 0 j)
  have hT' : IsUnit T'.det := by
    simp only [T', Matrix.det_mul, det_transvection_of_ne 0 j hj.symm, mul_one]
    exact hT.mul (isUnit_det_one_submatrix_right _)
  have hval : (S * N * T') 0 0 = x % c := by
    have : S * N * T' = (S * N * T) * transvection 0 j (-(x / c)) *
        (1 : Matrix (Fin (n + 1)) (Fin (n + 1)) R).submatrix id (Equiv.swap 0 j) := by
      simp only [T', Matrix.mul_assoc]
    rw [this, mul_one_submatrix_apply', Equiv.swap_apply_left, mul_transvection_apply_same, h0,
      EuclideanDomain.mod_eq_sub_mul_div]
    ring
  exact hmin S T' hS hT' (hval ▸ hx) (hval ▸ EuclideanDomain.mod_lt x hc0)
#print axioms corner_dvd_row

lemma corner_dvd_col {R : Type*} [EuclideanDomain R] {m n : ℕ} (N : Matrix (Fin (m + 1)) (Fin (n + 1)) R)
    (c : R) (hc0 : c ≠ 0)
    (hmin : ∀ (S : Matrix (Fin (m + 1)) (Fin (m + 1)) R) (T : Matrix (Fin (n + 1)) (Fin (n + 1)) R),
      IsUnit S.det → IsUnit T.det → (S * N * T) 0 0 ≠ 0 → ¬ EuclideanDomain.r ((S * N * T) 0 0) c)
    (S : Matrix (Fin (m + 1)) (Fin (m + 1)) R) (T : Matrix (Fin (n + 1)) (Fin (n + 1)) R)
    (hS : IsUnit S.det) (hT : IsUnit T.det) (h0 : (S * N * T) 0 0 = c) (i : Fin (m + 1)) :
    c ∣ (S * N * T) i 0 := by
  by_contra hdvd
  have hi : i ≠ 0 := by rintro rfl; exact hdvd (h0 ▸ dvd_refl _)
  set x := (S * N * T) i 0
  have hx : x % c ≠ 0 := fun h => hdvd (EuclideanDomain.mod_eq_zero.mp h)
  let S' := (1 : Matrix (Fin (m + 1)) (Fin (m + 1)) R).submatrix (Equiv.swap 0 i) id *
    transvection i 0 (-(x / c)) * S
  have hS' : IsUnit S'.det := by
    simp only [S', Matrix.det_mul, det_transvection_of_ne i 0 hi, mul_one]
    exact (isUnit_det_one_submatrix_left _).mul hS
  have hval : (S' * N * T) 0 0 = x % c := by
    have : S' * N * T = (1 : Matrix (Fin (m + 1)) (Fin (m + 1)) R).submatrix (Equiv.swap 0 i) id *
        (transvection i 0 (-(x / c)) * (S * N * T)) := by
      simp only [S', Matrix.mul_assoc]
    rw [this, one_submatrix_mul_apply', Equiv.swap_apply_left, transvection_mul_apply_same, h0,
      EuclideanDomain.mod_eq_sub_mul_div]
    ring
  exact hmin S' T hS' hT (hval ▸ hx) (hval ▸ EuclideanDomain.mod_lt x hc0)
#print axioms corner_dvd_col

lemma corner_reduce {R : Type*} [EuclideanDomain R] {m n : ℕ}
    (N : Matrix (Fin (m + 1)) (Fin (n + 1)) R) :
    ∃ (S : Matrix (Fin (m + 1)) (Fin (m + 1)) R) (T : Matrix (Fin (n + 1)) (Fin (n + 1)) R) (a : R)
      (M : Matrix (Fin m) (Fin n) R),
      IsUnit S.det ∧ IsUnit T.det ∧ (∀ i j, a ∣ M i j) ∧ S * N * T = cornerBlock a M := by
  classical
  by_cases hN : N = 0
  · refine ⟨1, 1, 0, 0, by simp, by simp, fun _ _ => dvd_refl _, ?_⟩
    subst hN
    ext i j
    refine Fin.cases ?_ (fun i => ?_) i <;> refine Fin.cases ?_ (fun j => ?_) j <;> simp [cornerBlock]
  obtain ⟨i0, j0, hij⟩ : ∃ i j, N i j ≠ 0 := by
    by_contra h; push Not at h; exact hN (Matrix.ext h)
  let s : Set R := {c | c ≠ 0 ∧ ∃ (S : Matrix (Fin (m + 1)) (Fin (m + 1)) R)
      (T : Matrix (Fin (n + 1)) (Fin (n + 1)) R), IsUnit S.det ∧ IsUnit T.det ∧ (S * N * T) 0 0 = c}
  have hs : s.Nonempty := by
    refine ⟨N i0 j0, hij, (1 : Matrix _ _ R).submatrix (Equiv.swap 0 i0) id,
      (1 : Matrix _ _ R).submatrix id (Equiv.swap 0 j0), isUnit_det_one_submatrix_left _,
      isUnit_det_one_submatrix_right _, ?_⟩
    rw [mul_one_submatrix_apply', one_submatrix_mul_apply']
    simp
  obtain ⟨c, ⟨hc0, S1, T1, hS1, hT1, hc⟩, hmin⟩ := EuclideanDomain.r_wellFounded.has_min s hs
  have hmin' : ∀ (S : Matrix (Fin (m + 1)) (Fin (m + 1)) R) (T : Matrix (Fin (n + 1)) (Fin (n + 1)) R),
      IsUnit S.det → IsUnit T.det → (S * N * T) 0 0 ≠ 0 → ¬ EuclideanDomain.r ((S * N * T) 0 0) c :=
    fun S T hS hT h0 => hmin _ ⟨h0, S, T, hS, hT, rfl⟩
  have hrow1 := corner_dvd_row N c hc0 hmin' S1 T1 hS1 hT1 hc
  have hcol1 := corner_dvd_col N c hc0 hmin' S1 T1 hS1 hT1 hc
  set M1 := S1 * N * T1 with hM1
  let S2 : Matrix (Fin (m + 1)) (Fin (m + 1)) R :=
    Matrix.of fun i k => if i = k then 1 else if k = 0 then -(M1 i 0 / c) else 0
  let T2 : Matrix (Fin (n + 1)) (Fin (n + 1)) R :=
    Matrix.of fun k j => if k = j then 1 else if k = 0 then -(M1 0 j / c) else 0
  have hS2 : S2.det = 1 := by
    rw [Matrix.det_of_isLowerTriangular]
    · simp [S2]
    · intro i k hik
      have hik' : i < k := hik
      have h1 : i ≠ k := ne_of_lt hik'
      have h2 : k ≠ 0 := by
        rintro rfl; exact absurd hik' (Fin.not_lt_zero _)
      simp [S2, h1, h2]
  have hT2 : T2.det = 1 := by
    rw [Matrix.det_of_isUpperTriangular]
    · simp [T2]
    · intro k j hjk
      have hjk' : j < k := hjk
      have h1 : k ≠ j := (ne_of_lt hjk').symm
      have h2 : k ≠ 0 := by
        rintro rfl; exact absurd hjk' (Fin.not_lt_zero _)
      simp [T2, h1, h2]
  have hrow : ∀ i l, (S2 * M1) i l = M1 i l - (if i = 0 then 0 else (M1 i 0 / c) * M1 0 l) := by
    intro i l
    by_cases hi : i = 0
    · subst hi
      have : ∀ k, S2 0 k = if 0 = k then 1 else 0 := by
        intro k; by_cases hk : k = 0 <;> simp [S2, hk, eq_comm]
      simp [Matrix.mul_apply, this]
    · have : ∀ k, S2 i k = (if i = k then 1 else 0) + (if k = 0 then -(M1 i 0 / c) else 0) := by
        intro k
        by_cases hk : k = 0
        · subst hk; simp [S2, hi]
        · simp [S2, hk]
      simp [Matrix.mul_apply, this, add_mul, Finset.sum_add_distrib, hi]
      ring
  have hcol : ∀ (P : Matrix (Fin (m + 1)) (Fin (n + 1)) R) a b,
      (P * T2) a b = P a b - (if b = 0 then 0 else P a 0 * (M1 0 b / c)) := by
    intro P a b
    by_cases hb : b = 0
    · subst hb
      have : ∀ k, T2 k 0 = if k = 0 then 1 else 0 := by
        intro k; by_cases hk : k = 0 <;> simp [T2, hk]
      simp [Matrix.mul_apply, this]
    · have : ∀ k, T2 k b = (if k = b then 1 else 0) + (if k = 0 then -(M1 0 b / c) else 0) := by
        intro k
        by_cases hk : k = 0
        · subst hk; simp [T2, Ne.symm hb]
        · simp [T2, hk]
      simp [Matrix.mul_apply, this, mul_add, Finset.sum_add_distrib, hb]
      ring
  set M2 := S2 * M1 * T2 with hM2
  have hM2_00 : M2 0 0 = c := by
    rw [hM2, hcol, hrow]; simp [hc]
  have hM2_i0 : ∀ i : Fin m, M2 i.succ 0 = 0 := by
    intro i
    rw [hM2, hcol, hrow]
    simp only [Fin.succ_ne_zero, ite_false, ite_true, hc]
    rw [mul_comm, EuclideanDomain.mul_div_cancel' hc0 (hcol1 _)]
    simp
  have hM2_0j : ∀ j : Fin n, M2 0 j.succ = 0 := by
    intro j
    rw [hM2, hcol, hrow, hrow]
    simp only [Fin.succ_ne_zero, ite_false, ite_true, hc, sub_zero]
    rw [EuclideanDomain.mul_div_cancel' hc0 (hrow1 _)]
    simp
  have hM2eq : M2 = S2 * S1 * N * (T1 * T2) := by
    simp only [hM2, hM1, Matrix.mul_assoc]
  have hrest : ∀ (i : Fin m) (j : Fin n), c ∣ M2 i.succ j.succ := by
    intro i j
    have hne : (0 : Fin (m + 1)) ≠ i.succ := (Fin.succ_ne_zero i).symm
    have hS3 : IsUnit (transvection 0 i.succ (1 : R) * (S2 * S1)).det := by
      rw [Matrix.det_mul, Matrix.det_mul, det_transvection_of_ne _ _ hne, hS2]; simpa using hS1
    have hT3 : IsUnit (T1 * T2).det := by
      rw [Matrix.det_mul, hT2]; simpa using hT1
    have heq : transvection 0 i.succ (1 : R) * (S2 * S1) * N * (T1 * T2) =
        transvection 0 i.succ (1 : R) * M2 := by
      rw [hM2eq]; simp only [Matrix.mul_assoc]
    have h0 : (transvection 0 i.succ (1 : R) * (S2 * S1) * N * (T1 * T2)) 0 0 = c := by
      rw [heq, transvection_mul_apply_same, hM2_00, hM2_i0]; simp
    have := corner_dvd_row N c hc0 hmin' _ _ hS3 hT3 h0 j.succ
    rwa [heq, transvection_mul_apply_same, hM2_0j, one_mul, zero_add] at this
  refine ⟨S2 * S1, T1 * T2, c, Matrix.of fun i j => M2 i.succ j.succ, ?_, ?_, fun i j => hrest i j, ?_⟩
  · rw [Matrix.det_mul, hS2]; simpa using hS1
  · rw [Matrix.det_mul, hT2]; simpa using hT1
  · rw [← hM2eq]
    ext i j
    refine Fin.cases ?_ (fun i => ?_) i <;> refine Fin.cases ?_ (fun j => ?_) j <;>
      simp [cornerBlock, hM2_00, hM2_i0, hM2_0j]
#print axioms corner_reduce

lemma snf_aux {R : Type*} [EuclideanDomain R] : ∀ (m n : ℕ) (N : Matrix (Fin m) (Fin n) R),
    ∃ (S : Matrix (Fin m) (Fin m) R) (T : Matrix (Fin n) (Fin n) R) (d : ℕ → R),
      IsUnit S.det ∧ IsUnit T.det ∧
      (∀ i j, i ≤ j → d i ∣ d j) ∧ (∀ i, n ≤ i → d i = 0) ∧ (∀ i, m ≤ i → d i = 0) ∧
      S * N * T = Matrix.of (fun (i : Fin m) (j : Fin n) => if (i : ℕ) = (j : ℕ) then d i else 0)
  | 0, n, N => ⟨1, 1, 0, by simp, by simp, by simp, by simp, by simp, by ext i; exact i.elim0⟩
  | m + 1, 0, N => ⟨1, 1, 0, by simp, by simp, by simp, by simp, by simp, by ext i j; exact j.elim0⟩
  | m + 1, n + 1, N => by
    obtain ⟨S0, T0, a, M, hS0, hT0, hdvd, hN⟩ := corner_reduce N
    obtain ⟨S', T', d', hS', hT', hd'dvd, hd'n, hd'm, hM⟩ := snf_aux m n M
    have ha : ∀ k, a ∣ d' k := by
      intro k
      by_cases hk : k < m ∧ k < n
      · have := congrFun (congrFun hM ⟨k, hk.1⟩) ⟨k, hk.2⟩
        simp only [Matrix.of_apply, ite_true] at this
        rw [← this]
        simp only [Matrix.mul_apply]
        exact Finset.dvd_sum fun b _ =>
          Dvd.dvd.mul_right (Finset.dvd_sum fun c _ => Dvd.dvd.mul_left (hdvd _ _) _) _
      · rw [not_and_or, not_lt, not_lt] at hk
        rcases hk with hk | hk
        · rw [hd'm k hk]; exact dvd_zero _
        · rw [hd'n k hk]; exact dvd_zero _
    let d : ℕ → R := fun k => match k with
      | 0 => a
      | k + 1 => d' k
    refine ⟨cornerBlock 1 S' * S0, T0 * cornerBlock 1 T', d, ?_, ?_, ?_, ?_, ?_, ?_⟩
    · rw [Matrix.det_mul, det_cornerBlock_one]; exact hS'.mul hS0
    · rw [Matrix.det_mul, det_cornerBlock_one]; exact hT0.mul hT'
    · intro i j hij
      cases i with
      | zero => cases j with
        | zero => exact dvd_refl _
        | succ j => exact ha j
      | succ i => cases j with
        | zero => omega
        | succ j => exact hd'dvd i j (by omega)
    · intro i hi
      cases i with
      | zero => omega
      | succ i => exact hd'n i (by omega)
    · intro i hi
      cases i with
      | zero => omega
      | succ i => exact hd'm i (by omega)
    · have : cornerBlock 1 S' * S0 * N * (T0 * cornerBlock 1 T') =
          cornerBlock 1 S' * (S0 * N * T0) * cornerBlock 1 T' := by
        simp only [Matrix.mul_assoc]
      rw [this, hN, cornerBlock_mul, cornerBlock_mul, hM]
      ext i j
      refine Fin.cases ?_ (fun i => ?_) i <;> refine Fin.cases ?_ (fun j => ?_) j <;>
        simp [cornerBlock, d]
#print axioms snf_aux

/-- Moves with inverses do not change the module: `R^m / N R^n ≅ R^m / (S N T) R^n`. -/
lemma range_mul_mul_eq {R : Type*} [CommRing R] {m n : ℕ} (S : Matrix (Fin m) (Fin m) R)
    (N : Matrix (Fin m) (Fin n) R) (T : Matrix (Fin n) (Fin n) R) (hT : IsUnit T.det) :
    LinearMap.range (S * N * T).mulVecLin = (LinearMap.range N.mulVecLin).map S.mulVecLin := by
  have hT' : LinearMap.range T.mulVecLin = ⊤ := by
    rw [LinearMap.range_eq_top]
    intro v
    refine ⟨T⁻¹.mulVec v, ?_⟩
    simp [Matrix.mulVec_mulVec, Matrix.mul_nonsing_inv _ hT]
  rw [Matrix.mulVecLin_mul, Matrix.mulVecLin_mul, LinearMap.range_comp, hT', Submodule.map_top,
    LinearMap.range_comp]
#print axioms range_mul_mul_eq

noncomputable def quotEquivOfMoves {R : Type*} [CommRing R] {m n : ℕ} (S : Matrix (Fin m) (Fin m) R)
    (N : Matrix (Fin m) (Fin n) R) (T : Matrix (Fin n) (Fin n) R) (hS : IsUnit S.det) (hT : IsUnit T.det) :
    ((Fin m → R) ⧸ LinearMap.range N.mulVecLin) ≃ₗ[R] ((Fin m → R) ⧸ LinearMap.range (S * N * T).mulVecLin) :=
  Submodule.Quotient.equiv _ _ (LinearEquiv.ofLinearMap S.mulVecLin S⁻¹.mulVecLin
    (LinearMap.ext fun v => by simp [Matrix.mulVec_mulVec, Matrix.mul_nonsing_inv _ hS])
    (LinearMap.ext fun v => by simp [Matrix.mulVec_mulVec, Matrix.nonsing_inv_mul _ hS]))
    (range_mul_mul_eq S N T hT).symm

lemma range_diag_eq_pi {R : Type*} [CommRing R] {m n : ℕ} (d : ℕ → R) (hd : ∀ i, n ≤ i → d i = 0) :
    LinearMap.range (Matrix.of (fun (i : Fin m) (j : Fin n) => if (i : ℕ) = (j : ℕ) then d i else 0)).mulVecLin
      = Submodule.pi Set.univ (fun i : Fin m => (Ideal.span {d i} : Submodule R R)) := by
  ext w
  simp only [LinearMap.mem_range, Matrix.mulVecLin_apply, Submodule.mem_pi, Set.mem_univ, true_implies,
    Ideal.mem_span_singleton]
  constructor
  · rintro ⟨v, rfl⟩ i
    simp only [Matrix.mulVec, dotProduct, Matrix.of_apply]
    exact Finset.dvd_sum fun j _ => by split_ifs <;> simp
  · intro h
    choose u hu using h
    refine ⟨fun j => if hj : (j : ℕ) < m then u ⟨j, hj⟩ else 0, ?_⟩
    ext i
    simp only [Matrix.mulVec, dotProduct, Matrix.of_apply]
    by_cases hi : (i : ℕ) < n
    · rw [Finset.sum_eq_single ⟨i, hi⟩]
      · simp [hu i]
      · intro j _ hj
        have : (i : ℕ) ≠ j := fun h => hj (Fin.ext h.symm)
        simp [this]
      · simp
    · have h0 : d i = 0 := hd i (not_lt.mp hi)
      rw [hu i, h0]
      simp
#print axioms range_diag_eq_pi

end PartA

section PartB


variable {K : Type*} [Field K] {n : ℕ}

lemma charmatrix_mulVec_C (A : Matrix (Fin n) (Fin n) K) (v : Fin n → K) :
    (charmatrix A).mulVec (fun i => C (v i)) = (X : K[X]) • (fun i => C (v i)) - (fun i => C ((A.mulVec v) i)) := by
  ext i
  simp [charmatrix_apply, Matrix.mulVec, dotProduct, sub_mul, Finset.sum_sub_distrib, Matrix.diagonal_apply,
    ite_mul, map_sum]
#print axioms charmatrix_mulVec_C

/-- The map sending a constant vector of polynomials to its class modulo the columns of `x I − A`. -/
noncomputable def constToQuot (A : Matrix (Fin n) (Fin n) K) :
    (Fin n → K) →ₗ[K] ((Fin n → K[X]) ⧸ LinearMap.range (charmatrix A).mulVecLin) where
  toFun v := Submodule.Quotient.mk (fun i => C (v i))
  map_add' v w := by
    rw [← Submodule.Quotient.mk_add]; congr 1; ext i; simp
  map_smul' k v := by
    rw [← Submodule.Quotient.mk_smul]; congr 1; ext i; simp [Polynomial.smul_eq_C_mul]

noncomputable def aevalToQuot (A : Matrix (Fin n) (Fin n) K) :
    Module.AEval' (Matrix.toLin' A) →ₗ[K[X]] ((Fin n → K[X]) ⧸ LinearMap.range (charmatrix A).mulVecLin) :=
  LinearMap.ofAEval _ (constToQuot A) (fun v => by
    simp only [constToQuot, LinearMap.coe_mk, AddHom.coe_mk]
    rw [← Submodule.Quotient.mk_smul, Submodule.Quotient.eq]
    refine ⟨-(fun i => C (v i)), ?_⟩
    rw [Matrix.mulVecLin_apply, Matrix.mulVec_neg, charmatrix_mulVec_C]
    ext i
    simp [Module.End.smul_def])

noncomputable def vecToAEval (A : Matrix (Fin n) (Fin n) K) :
    (Fin n → K[X]) →ₗ[K[X]] Module.AEval' (Matrix.toLin' A) :=
  Fintype.linearCombination K[X] (fun i => Module.AEval'.of (Matrix.toLin' A) (Pi.single i 1))

lemma vecToAEval_const (A : Matrix (Fin n) (Fin n) K) (v : Fin n → K) :
    vecToAEval A (fun i => C (v i)) = Module.AEval'.of (Matrix.toLin' A) v := by
  simp only [vecToAEval, Fintype.linearCombination_apply, Module.AEval.C_smul]
  simp only [← LinearEquiv.map_smul, ← map_sum]
  congr 1
  ext j
  simp [Finset.sum_apply, Pi.single_apply]
#print axioms vecToAEval_const

lemma range_le_ker_vecToAEval (A : Matrix (Fin n) (Fin n) K) :
    LinearMap.range (charmatrix A).mulVecLin ≤ LinearMap.ker (vecToAEval A) := by
  rintro _ ⟨q, rfl⟩
  rw [LinearMap.mem_ker]
  have : (vecToAEval A) ∘ₗ (charmatrix A).mulVecLin = 0 := by
    ext j : 2
    simp only [LinearMap.comp_apply, LinearMap.coe_single, Matrix.mulVecLin_apply, Matrix.mulVec_single_one,
      LinearMap.zero_apply]
    simp only [vecToAEval, Fintype.linearCombination_apply, Matrix.col_apply, charmatrix_apply, sub_smul,
      Finset.sum_sub_distrib, Module.AEval.C_smul, Matrix.diagonal_apply, ite_smul, zero_smul,
      Finset.sum_ite_eq', Finset.mem_univ, ite_true]
    rw [Module.AEval'.X_smul_of, sub_eq_zero]
    simp only [← LinearEquiv.map_smul, ← map_sum]
    congr 1
    ext i
    simp [Finset.sum_apply, Pi.single_apply, Matrix.toLin'_apply]
  exact LinearMap.congr_fun this q
#print axioms range_le_ker_vecToAEval

noncomputable def quotToAEval (A : Matrix (Fin n) (Fin n) K) :
    ((Fin n → K[X]) ⧸ LinearMap.range (charmatrix A).mulVecLin) →ₗ[K[X]] Module.AEval' (Matrix.toLin' A) :=
  (LinearMap.range (charmatrix A).mulVecLin).liftQ (vecToAEval A) (range_le_ker_vecToAEval A)

/-- The presentation: `k^n`, with `x` acting as `A`, is `k[x]^n` modulo the columns of `x I − A`. -/
noncomputable def aevalEquivQuot (A : Matrix (Fin n) (Fin n) K) :
    Module.AEval' (Matrix.toLin' A) ≃ₗ[K[X]] ((Fin n → K[X]) ⧸ LinearMap.range (charmatrix A).mulVecLin) :=
  LinearEquiv.ofLinearMap (aevalToQuot A) (quotToAEval A)
    (by
      ext j : 3
      simp only [LinearMap.comp_apply, Submodule.mkQ_apply, LinearMap.coe_single, LinearMap.id_apply,
        quotToAEval, Submodule.liftQ_apply]
      have : (Pi.single j (1 : K[X]) : Fin n → K[X]) = fun i => C ((Pi.single j (1 : K) : Fin n → K) i) := by
        ext i; simp [Pi.single_apply]
      rw [this, vecToAEval_const]
      simp [aevalToQuot, LinearMap.ofAEval, constToQuot])
    (by
      ext v
      obtain ⟨w, rfl⟩ := (Module.AEval'.of (Matrix.toLin' A)).surjective v
      simp [aevalToQuot, LinearMap.ofAEval, constToQuot, quotToAEval, vecToAEval_const])

end PartB

section PartC

variable {K : Type*} [Field K]

lemma natDegree_gcd_le [DecidableEq K] (f h : K[X]) (hh : h ≠ 0) : (gcd f h).natDegree ≤ h.natDegree :=
  natDegree_le_of_dvd (gcd_dvd_right f h) hh
#print axioms natDegree_gcd_le

lemma dvd_of_natDegree_gcd_eq [DecidableEq K] (f h : K[X]) (hf : f ≠ 0) (hh : h.Monic)
    (heq : (gcd f h).natDegree = h.natDegree) : h ∣ f := by
  have hg : (gcd f h).Monic := by
    rw [← normalize_gcd]; exact Polynomial.monic_normalize (gcd_ne_zero_of_left hf)
  have := eq_of_monic_of_dvd_of_natDegree_le hg hh (gcd_dvd_right f h) heq.ge
  rw [this]; exact gcd_dvd_left f h
#print axioms dvd_of_natDegree_gcd_eq

lemma natDegree_gcd_of_dvd [DecidableEq K] (f h : K[X]) (hh : h.Monic) (hd : h ∣ f) :
    (gcd f h).natDegree = h.natDegree := by
  have : gcd f h = h := by
    rw [gcd_eq_normalize (gcd_dvd_right f h) (dvd_gcd hd dvd_rfl), hh.normalize_eq_self]
  rw [this]
#print axioms natDegree_gcd_of_dvd

lemma first_dvd_of_sum_eq [DecidableEq K] {n : ℕ} (f g : Fin (n + 1) → K[X]) (hf : ∀ i, (f i).Monic)
    (hfd : ∀ i j, i ≤ j → f i ∣ f j) (hg : ∀ i, (g i).Monic)
    (hsum : ∀ h : K[X], h.Monic → ∑ i, (gcd (f i) h).natDegree = ∑ i, (gcd (g i) h).natDegree) :
    f 0 ∣ g 0 := by
  have h1 : ∑ i, (gcd (f i) (f 0)).natDegree = ∑ _i : Fin (n + 1), (f 0).natDegree :=
    Finset.sum_congr rfl (fun i _ => natDegree_gcd_of_dvd (f i) (f 0) (hf 0) (hfd 0 i (Fin.zero_le _)))
  rw [hsum (f 0) (hf 0)] at h1
  by_contra hnd
  have hlt : (gcd (g 0) (f 0)).natDegree < (f 0).natDegree :=
    lt_of_le_of_ne (natDegree_gcd_le _ _ (hf 0).ne_zero)
      (fun heq => hnd (dvd_of_natDegree_gcd_eq _ _ (hg 0).ne_zero (hf 0) heq))
  have : ∑ i, (gcd (g i) (f 0)).natDegree < ∑ _i : Fin (n + 1), (f 0).natDegree :=
    Finset.sum_lt_sum (fun i _ => natDegree_gcd_le _ _ (hf 0).ne_zero) ⟨0, Finset.mem_univ _, hlt⟩
  omega
#print axioms first_dvd_of_sum_eq

lemma chain_eq_of_sum_eq [DecidableEq K] : ∀ (n : ℕ) (f g : Fin n → K[X]), (∀ i, (f i).Monic) →
    (∀ i j, i ≤ j → f i ∣ f j) → (∀ i, (g i).Monic) → (∀ i j, i ≤ j → g i ∣ g j) →
    (∀ h : K[X], h.Monic → ∑ i, (gcd (f i) h).natDegree = ∑ i, (gcd (g i) h).natDegree) → f = g
  | 0, f, g, _, _, _, _, _ => funext fun i => i.elim0
  | n + 1, f, g, hf, hfd, hg, hgd, hsum => by
    have h0 : f 0 = g 0 := eq_of_monic_of_associated (hf 0) (hg 0)
      (associated_of_dvd_dvd (first_dvd_of_sum_eq f g hf hfd hg hsum)
        (first_dvd_of_sum_eq g f hg hgd hf (fun h hh => (hsum h hh).symm)))
    have htail := chain_eq_of_sum_eq n (fun i => f i.succ) (fun i => g i.succ) (fun i => hf _)
      (fun i j hij => hfd _ _ (Fin.succ_le_succ_iff.mpr hij)) (fun i => hg _)
      (fun i j hij => hgd _ _ (Fin.succ_le_succ_iff.mpr hij))
      (fun h hh => by
        have := hsum h hh
        rw [Fin.sum_univ_succ, Fin.sum_univ_succ, h0] at this
        omega)
    funext i
    exact Fin.cases h0 (fun i => congrFun htail i) i
#print axioms chain_eq_of_sum_eq

/-- The number `dim_k (M / h M)`. -/
noncomputable def quotDim (h : K[X]) (M : Type*) [AddCommGroup M] [Module K[X] M] [Module K M]
    [IsScalarTower K K[X] M] : ℕ :=
  Module.finrank K (M ⧸ LinearMap.range (h • LinearMap.id : M →ₗ[K[X]] M))

lemma quotDim_congr (h : K[X]) {M N : Type*} [AddCommGroup M] [Module K[X] M] [Module K M]
    [IsScalarTower K K[X] M] [AddCommGroup N] [Module K[X] N] [Module K N] [IsScalarTower K K[X] N]
    (e : M ≃ₗ[K[X]] N) : quotDim h M = quotDim h N := by
  unfold quotDim
  refine ((Submodule.Quotient.equiv _ _ e ?_).restrictScalars K).finrank_eq
  rw [← LinearMap.range_comp]
  have : (e : M →ₗ[K[X]] N) ∘ₗ (h • LinearMap.id) = (h • LinearMap.id) ∘ₗ (e : M →ₗ[K[X]] N) := by
    ext x; simp
  rw [this, LinearMap.range_comp_of_range_eq_top]
  exact LinearMap.range_eq_top.mpr e.surjective
#print axioms quotDim_congr

lemma quotDim_pi (h : K[X]) {n : ℕ} (Q : Fin n → Type*) [∀ i, AddCommGroup (Q i)] [∀ i, Module K[X] (Q i)]
    [∀ i, Module K (Q i)] [∀ i, IsScalarTower K K[X] (Q i)] [∀ i, Module.Finite K (Q i)] :
    quotDim h ((i : Fin n) → Q i) = ∑ i, quotDim h (Q i) := by
  unfold quotDim
  have hr : LinearMap.range (h • LinearMap.id : ((i : Fin n) → Q i) →ₗ[K[X]] ((i : Fin n) → Q i)) =
      Submodule.pi Set.univ (fun i => LinearMap.range (h • LinearMap.id : Q i →ₗ[K[X]] Q i)) := by
    ext x
    simp only [LinearMap.mem_range, LinearMap.smul_apply, LinearMap.id_apply, Submodule.mem_pi,
      Set.mem_univ, true_implies]
    constructor
    · rintro ⟨y, rfl⟩ i; exact ⟨y i, rfl⟩
    · intro hx
      choose y hy using hx
      exact ⟨y, funext hy⟩
  have e := ((Submodule.quotEquivOfEq _ _ hr).trans (Submodule.quotientPi _)).restrictScalars K
  rw [e.finrank_eq]
  have : ∀ i, Module.Finite K (Q i ⧸ LinearMap.range (h • LinearMap.id : Q i →ₗ[K[X]] Q i)) := fun i =>
    Module.Finite.of_surjective ((Submodule.mkQ _).restrictScalars K) (Submodule.mkQ_surjective _)
  exact Module.finrank_pi_fintype K
#print axioms quotDim_pi

lemma quotDim_adjoin [DecidableEq K] (f h : K[X]) :
    quotDim h (K[X] ⧸ Ideal.span {f}) = (gcd f h).natDegree := by
  unfold quotDim
  have hr : LinearMap.range (h • LinearMap.id : (K[X] ⧸ Ideal.span {f}) →ₗ[K[X]] (K[X] ⧸ Ideal.span {f})) =
      Submodule.map (Ideal.span {f} : Submodule K[X] K[X]).mkQ (Ideal.span {h}) := by
    ext x
    simp only [LinearMap.mem_range, LinearMap.smul_apply, LinearMap.id_apply, Submodule.mem_map,
      Submodule.mkQ_apply]
    constructor
    · rintro ⟨y, rfl⟩
      obtain ⟨p, rfl⟩ := Submodule.Quotient.mk_surjective _ y
      exact ⟨h * p, Ideal.mul_mem_right _ _ (Ideal.mem_span_singleton_self h), by
        rw [← Submodule.Quotient.mk_smul, smul_eq_mul]⟩
    · rintro ⟨q, hq, rfl⟩
      obtain ⟨p, rfl⟩ := Ideal.mem_span_singleton'.mp hq
      exact ⟨Submodule.Quotient.mk p, by rw [← Submodule.Quotient.mk_smul, smul_eq_mul, mul_comm]⟩
  have e := ((Submodule.quotEquivOfEq _ _ hr).trans
    (Submodule.quotientQuotientEquivQuotientSup _ _)).restrictScalars K
  rw [e.finrank_eq]
  have hs : (Ideal.span {f} : Submodule K[X] K[X]) ⊔ Ideal.span {h} = Ideal.span {gcd f h} := by
    rw [span_gcd, Ideal.span_insert]
  rw [← finrank_quotient_span_eq_natDegree]
  exact ((Submodule.quotEquivOfEq _ _ hs).restrictScalars K).finrank_eq
#print axioms quotDim_adjoin

end PartC

section PartD

variable {K : Type*} [Field K]

lemma range_diagonal_eq_pi {R : Type*} [CommRing R] {n : ℕ} (f : Fin n → R) :
    LinearMap.range (diagonal f).mulVecLin =
      Submodule.pi Set.univ (fun i => (Ideal.span {f i} : Submodule R R)) := by
  ext w
  simp only [LinearMap.mem_range, Matrix.mulVecLin_apply, Submodule.mem_pi, Set.mem_univ, true_implies,
    Ideal.mem_span_singleton]
  constructor
  · rintro ⟨v, rfl⟩ i
    rw [Matrix.mulVec_diagonal]
    exact dvd_mul_right _ _
  · intro h
    choose u hu using h
    exact ⟨u, funext fun i => by rw [Matrix.mulVec_diagonal, hu i]⟩
#print axioms range_diagonal_eq_pi

/-- `k^n` with `x` acting as `A` splits as `k[x]/(f_1) ⊕ ⋯ ⊕ k[x]/(f_n)`. -/
noncomputable def aevalEquivPi {n : ℕ} (A : Matrix (Fin n) (Fin n) K) (S T : Matrix (Fin n) (Fin n) K[X])
    (f : Fin n → K[X]) (hS : IsUnit S.det) (hT : IsUnit T.det) (hA : S * charmatrix A * T = diagonal f) :
    Module.AEval' (Matrix.toLin' A) ≃ₗ[K[X]] ((i : Fin n) → K[X] ⧸ Ideal.span {f i}) :=
  (aevalEquivQuot A).trans ((quotEquivOfMoves S _ T hS hT).trans
    ((Submodule.quotEquivOfEq _ _ (by rw [hA, range_diagonal_eq_pi])).trans (Submodule.quotientPi _)))

/-- The basis `1, x, …, x^{m-1}` of `k[x]/(f)` over `k`. -/
noncomputable def quotBasis {f : K[X]} (hf : f.Monic) : Module.Basis (Fin f.natDegree) K (K[X] ⧸ Ideal.span {f}) :=
  AdjoinRoot.powerBasisAux' hf

/-- Multiplication by `x` on `k[x]/(f)`, in the basis `1, x, …, x^{m-1}`, is the companion matrix. -/
lemma quotBasis_repr_X_smul {f : K[X]} (hf : f.Monic) (a b : Fin f.natDegree) :
    (quotBasis hf).repr ((X : K[X]) • quotBasis hf b) a = companion f a b := by
  have hb : (X : K[X]) • quotBasis hf b = Submodule.Quotient.mk (X ^ ((b : ℕ) + 1)) := by
    have : quotBasis hf b = Submodule.Quotient.mk (X ^ (b : ℕ)) := by
      apply (quotBasis hf).repr.injective
      ext i
      rw [Module.Basis.repr_self]
      show _ = (AdjoinRoot.powerBasisAux' hf).repr (AdjoinRoot.mk f (X ^ (b : ℕ))) i
      rw [AdjoinRoot.powerBasisAux'_repr_apply_to_fun, AdjoinRoot.modByMonicHom_mk,
        (modByMonic_eq_self_iff hf).mpr (by
          rw [degree_X_pow, degree_eq_natDegree hf.ne_zero]; exact_mod_cast b.isLt),
        coeff_X_pow, Finsupp.single_apply]
      simp [Fin.ext_iff, eq_comm]
    rw [this, ← Submodule.Quotient.mk_smul, smul_eq_mul, pow_succ']
  rw [hb]
  show (AdjoinRoot.powerBasisAux' hf).repr (AdjoinRoot.mk f _) a = _
  rw [AdjoinRoot.powerBasisAux'_repr_apply_to_fun, AdjoinRoot.modByMonicHom_mk]
  have hdeg : f.degree = (f.natDegree : WithBot ℕ) := degree_eq_natDegree hf.ne_zero
  have ha := a.isLt
  have hbl := b.isLt
  by_cases hlt : (b : ℕ) + 1 < f.natDegree
  · rw [(modByMonic_eq_self_iff hf).mpr (by rw [degree_X_pow, hdeg]; exact_mod_cast hlt)]
    simp only [companion, coeff_X_pow]
    have : (b : ℕ) + 1 ≠ f.natDegree := ne_of_lt hlt
    simp [this]
  · have heq : (b : ℕ) + 1 = f.natDegree := by omega
    have hmod : X ^ ((b : ℕ) + 1) %ₘ f = X ^ ((b : ℕ) + 1) - f := by
      refine (div_modByMonic_unique 1 _ hf ⟨by ring, ?_⟩).2
      rw [← neg_sub, degree_neg, heq]
      refine degree_sub_lt_left ?_ hf.ne_zero ?_
      · rw [degree_X_pow, hdeg]
      · rw [hf.leadingCoeff, leadingCoeff_X_pow]
    rw [hmod]
    simp only [companion, coeff_sub, coeff_X_pow]
    have h1 : (a : ℕ) ≠ (b : ℕ) + 1 := by omega
    have h2 : (a : ℕ) ≠ f.natDegree := by omega
    simp [h2, heq]
#print axioms quotBasis_repr_X_smul

end PartD

/-- Smith normal form, and the module read off it. Over a ring with division with remainder
by a size that shrinks (a Euclidean domain, such as ℤ or k[x]), every m by n relation matrix N
is turned by row moves S and column moves T, both with inverses in the ring (unit determinant),
into a diagonal d_1, d_2, … with each entry dividing the next (any zeros come last). The lists
of m scalars modulo the columns of N then form one counter wrapping at d_i for each i, a free
counter R/(0) = R for each zero: R^m / N R^n ≅ R/(d_1) ⊕ ⋯ ⊕ R/(d_m). -/
theorem smith_normal_form_and_module_splits {R : Type*} [EuclideanDomain R] {m n : ℕ}
    (N : Matrix (Fin m) (Fin n) R) :
    ∃ (S : Matrix (Fin m) (Fin m) R) (T : Matrix (Fin n) (Fin n) R) (d : ℕ → R),
      IsUnit S.det ∧ IsUnit T.det ∧
      (∀ i j, i ≤ j → d i ∣ d j) ∧ (∀ i, n ≤ i → d i = 0) ∧
      S * N * T = Matrix.of (fun (i : Fin m) (j : Fin n) => if (i : ℕ) = (j : ℕ) then d i else 0) ∧
      Nonempty (((Fin m → R) ⧸ LinearMap.range N.mulVecLin) ≃ₗ[R]
        ((i : Fin m) → R ⧸ Ideal.span {d i})) := by
  obtain ⟨S, T, d, hS, hT, hdvd, hn, -, hSNT⟩ := snf_aux m n N
  refine ⟨S, T, d, hS, hT, hdvd, hn, hSNT, ⟨?_⟩⟩
  exact (quotEquivOfMoves S N T hS hT).trans
    ((Submodule.quotEquivOfEq _ _ (by rw [hSNT, range_diag_eq_pi d hn])).trans
      (Submodule.quotientPi _))

/-- The invariant factors decide similarity. Let A and B be n by n matrices over one field k.
Reduce x I − A and x I − B over k[x] by moves k[x] can undo to diagonals f and g of monic
polynomials, each dividing the next. Then A and B are similar (B = P⁻¹ A P for some P with
an inverse) exactly when the two lists are the same. -/
theorem similar_iff_same_invariant_factors {K : Type*} [Field K] {n : ℕ}
    (A B : Matrix (Fin n) (Fin n) K)
    (SA TA SB TB : Matrix (Fin n) (Fin n) K[X]) (f g : Fin n → K[X])
    (hSA : IsUnit SA.det) (hTA : IsUnit TA.det) (hA : SA * charmatrix A * TA = diagonal f)
    (hf : ∀ i, (f i).Monic) (hfd : ∀ i j, i ≤ j → f i ∣ f j)
    (hSB : IsUnit SB.det) (hTB : IsUnit TB.det) (hB : SB * charmatrix B * TB = diagonal g)
    (hg : ∀ i, (g i).Monic) (hgd : ∀ i j, i ≤ j → g i ∣ g j) :
    (∃ P : Matrix (Fin n) (Fin n) K, IsUnit P.det ∧ P⁻¹ * A * P = B) ↔ f = g := by
  classical
  have hfin : ∀ (p : Fin n → K[X]), (∀ i, (p i).Monic) → ∀ i, Module.Finite K (K[X] ⧸ Ideal.span {p i}) :=
    fun p hp i => Module.Finite.of_basis (quotBasis (hp i))
  constructor
  · rintro ⟨P, hP, hPAB⟩
    -- `v ↦ P⁻¹ v` carries `x` acting as `A` to `x` acting as `B`.
    let L : (Fin n → K) ≃ₗ[K] (Fin n → K) := LinearEquiv.ofLinearMap (Matrix.toLin' P⁻¹) (Matrix.toLin' P)
      (by
        apply LinearMap.ext; intro v
        simp [Matrix.mulVec_mulVec, Matrix.nonsing_inv_mul _ hP])
      (by
        apply LinearMap.ext; intro v
        simp [Matrix.mulVec_mulVec, Matrix.mul_nonsing_inv _ hP])
    have hBP : B * P⁻¹ = P⁻¹ * A := by
      rw [← hPAB, Matrix.mul_assoc, Matrix.mul_assoc, Matrix.mul_nonsing_inv _ hP, Matrix.mul_one]
    let ψ : Module.AEval' (Matrix.toLin' A) ≃ₗ[K[X]] Module.AEval' (Matrix.toLin' B) :=
      LinearEquiv.ofAEval _ (L.trans (Module.AEval'.of (Matrix.toLin' B))) (fun v => by
        simp only [LinearEquiv.trans_apply, Module.AEval'.X_smul_of]
        congr 1
        simp [L, Module.End.smul_def, Matrix.mulVec_mulVec, hBP])
    let E := (aevalEquivPi A SA TA f hSA hTA hA).symm.trans (ψ.trans (aevalEquivPi B SB TB g hSB hTB hB))
    refine chain_eq_of_sum_eq n f g hf hfd hg hgd (fun h _ => ?_)
    have := hfin f hf
    have := hfin g hg
    have hE := quotDim_congr h E
    rw [quotDim_pi, quotDim_pi] at hE
    simpa only [quotDim_adjoin] using hE
  · rintro rfl
    let E := (aevalEquivPi A SA TA f hSA hTA hA).trans (aevalEquivPi B SB TB f hSB hTB hB).symm
    let L : (Fin n → K) ≃ₗ[K] (Fin n → K) := (Module.AEval'.of (Matrix.toLin' A)).trans
      ((E.restrictScalars K).trans (Module.AEval'.of (Matrix.toLin' B)).symm)
    have hL : ∀ v, L (A.mulVec v) = B.mulVec (L v) := by
      intro v
      simp only [L, LinearEquiv.trans_apply, LinearEquiv.restrictScalars_apply]
      rw [← Matrix.toLin'_apply A v, ← Module.AEval'.X_smul_of, map_smul, Module.AEval'.of_symm_X_smul,
        Matrix.toLin'_apply]
    let Q := LinearMap.toMatrix' (L : (Fin n → K) →ₗ[K] (Fin n → K))
    let P := LinearMap.toMatrix' (L.symm : (Fin n → K) →ₗ[K] (Fin n → K))
    have hQP : Q * P = 1 := by
      simp only [Q, P, ← LinearMap.toMatrix'_comp]
      rw [← LinearMap.toMatrix'_id]
      congr 1
      apply LinearMap.ext; intro v; simp
    have hQA : Q * A = B * Q := by
      have : (L : (Fin n → K) →ₗ[K] (Fin n → K)) ∘ₗ Matrix.toLin' A =
          Matrix.toLin' B ∘ₗ (L : (Fin n → K) →ₗ[K] (Fin n → K)) := by
        apply LinearMap.ext; intro v; simp [hL]
      have h2 := congrArg LinearMap.toMatrix' this
      rw [LinearMap.toMatrix'_comp, LinearMap.toMatrix'_comp] at h2
      simpa only [LinearMap.toMatrix'_toLin'] using h2
    refine ⟨P, Matrix.isUnit_det_of_left_inverse hQP, ?_⟩
    rw [Matrix.inv_eq_left_inv hQP, hQA, Matrix.mul_assoc, hQP, Matrix.mul_one]

/-- The rational canonical form. If x I − A reduces over k[x] to the monic diagonal
f_1 ∣ f_2 ∣ ⋯ ∣ f_n (the invariant factors of A, with 1s first), then the product
f_1 ⋯ f_n is the characteristic polynomial det(x I − A), and in new coordinates P
(columns a basis, P invertible) A becomes the chain of companion blocks
C(f_1) ⊕ ⋯ ⊕ C(f_n): A P = P C. A factor equal to 1 gives an empty block. -/
theorem rational_canonical_form_of_invariant_factors {K : Type*} [Field K] {n : ℕ}
    (A : Matrix (Fin n) (Fin n) K)
    (S T : Matrix (Fin n) (Fin n) K[X]) (f : Fin n → K[X])
    (hS : IsUnit S.det) (hT : IsUnit T.det) (hA : S * charmatrix A * T = diagonal f)
    (hf : ∀ i, (f i).Monic) (hfd : ∀ i j, i ≤ j → f i ∣ f j) :
    (∏ i, f i) = A.charpoly ∧
    ∃ (e : (Σ i : Fin n, Fin (f i).natDegree) ≃ Fin n) (P : Matrix (Fin n) (Fin n) K),
      IsUnit P.det ∧
      A * P = P * (blockDiagonal' (fun i => companion (f i))).reindex e e := by
  classical
  constructor
  · have hdet := congrArg Matrix.det hA
    rw [Matrix.det_mul, Matrix.det_mul, Matrix.det_diagonal] at hdet
    obtain ⟨u, -, hSu⟩ := Polynomial.isUnit_iff.mp hS
    obtain ⟨v, -, hTv⟩ := Polynomial.isUnit_iff.mp hT
    have hmon : (∏ i, f i).Monic := monic_prod_of_monic _ _ (fun i _ => hf i)
    have hcp : A.charpoly.Monic := Matrix.charpoly_monic A
    have h1 : C (u * v) * A.charpoly = ∏ i, f i := by
      rw [← hdet, ← hSu, ← hTv, Matrix.charpoly, C_mul]; ring
    have hlc := congrArg leadingCoeff h1
    rw [leadingCoeff_mul, leadingCoeff_C, hcp.leadingCoeff, hmon.leadingCoeff, mul_one] at hlc
    rw [← h1, hlc, C_1, one_mul]
  · let Φ := aevalEquivPi A S T f hS hT hA
    let B0 : Module.Basis (Σ i : Fin n, Fin (f i).natDegree) K ((i : Fin n) → K[X] ⧸ Ideal.span {f i}) :=
      Pi.basis fun i => quotBasis (hf i)
    let b := (B0.map (Φ.restrictScalars K).symm).map (Module.AEval'.of (Matrix.toLin' A)).symm
    have hcard : Fintype.card (Σ i : Fin n, Fin (f i).natDegree) = Fintype.card (Fin n) := by
      rw [← Module.finrank_eq_card_basis b, Module.finrank_fin_fun, Fintype.card_fin]
    let e := Fintype.equivOfCardEq hcard
    let b' := b.reindex e
    let std := Pi.basisFun K (Fin n)
    have key : LinearMap.toMatrix b' b' (Matrix.toLin' A) =
        (blockDiagonal' (fun i => companion (f i))).reindex e e := by
      ext k l
      rw [LinearMap.toMatrix_apply, Matrix.reindex_apply, Matrix.submatrix_apply, Module.Basis.reindex_apply,
        Module.Basis.repr_reindex_apply]
      generalize e.symm k = p
      generalize e.symm l = q
      have h1 : Matrix.toLin' A (b q) =
          (Module.AEval'.of (Matrix.toLin' A)).symm (Φ.symm ((X : K[X]) • B0 q)) := by
        simp only [b, Module.Basis.map_apply]
        rw [map_smul, Module.AEval'.of_symm_X_smul]
        rfl
      rw [h1]
      simp only [b, Module.Basis.map_repr, LinearEquiv.trans_apply, LinearEquiv.symm_symm,
        LinearEquiv.apply_symm_apply, LinearEquiv.restrictScalars_apply]
      rw [Pi.basis_repr, Pi.basis_apply, ← Pi.single_smul]
      obtain ⟨i, a⟩ := p
      obtain ⟨j, c⟩ := q
      rw [Matrix.blockDiagonal'_apply]
      by_cases hij : j = i
      · subst hij
        simp [quotBasis_repr_X_smul]
      · simp [Ne.symm hij]
    refine ⟨e, std.toMatrix b', ?_, ?_⟩
    · have := std.invertibleToMatrix b'
      exact isUnit_det_of_invertible _
    · have hP := basis_toMatrix_mul_linearMap_toMatrix_mul_basis_toMatrix std b' std b' (Matrix.toLin' A)
      rw [LinearMap.toMatrix_eq_toMatrix', LinearMap.toMatrix'_toLin', key] at hP
      conv_lhs => rw [← hP]
      rw [Matrix.mul_assoc, Module.Basis.toMatrix_mul_toMatrix_flip, Matrix.mul_one]

/-! The card's worked numbers, checked exactly. -/

-- The supercell N holds 12 unit cells: det N = −12.
example : (!![1, 0, 2; 0, 2, 2; 2, 2, 0] : Matrix (Fin 3) (Fin 3) ℤ).det = -12 := by
  norm_num [Matrix.det_fin_three]

-- The card's moves: S N T = diag(1, 2, 6), with det S = −1 and det T = 1.
example : (!![1, 0, 0; 0, 1, 0; 2, 1, -1] : Matrix (Fin 3) (Fin 3) ℤ) *
    !![1, 0, 2; 0, 2, 2; 2, 2, 0] * !![1, 0, -2; 0, 1, -1; 0, 0, 1] = !![1, 0, 0; 0, 2, 0; 0, 0, 6] := by
  decide
example : (!![1, 0, 0; 0, 1, 0; 2, 1, -1] : Matrix (Fin 3) (Fin 3) ℤ).det = -1 := by
  norm_num [Matrix.det_fin_three]
example : (!![1, 0, -2; 0, 1, -1; 0, 0, 1] : Matrix (Fin 3) (Fin 3) ℤ).det = 1 := by
  norm_num [Matrix.det_fin_three]

-- Z/2 ⊕ Z/6 has no shuffle of order 12: six steps bring every cell back.
example : ∀ x : ZMod 2 × ZMod 6, 6 • x = 0 := by decide
-- Z/12 does: one step needs 12 moves to come back.
example : (6 • (1 : ZMod 12)) ≠ 0 := by decide

-- The plain 2 × 2 × 3 box is the same module: diag(2, 2, 3) also reduces to diag(1, 2, 6).
example : (!![-1, 0, -1; 0, 1, 0; -3, 0, -2] : Matrix (Fin 3) (Fin 3) ℤ) *
    !![2, 0, 0; 0, 2, 0; 0, 0, 3] * !![1, 0, -3; 0, 1, 0; -1, 0, 2] = !![1, 0, 0; 0, 2, 0; 0, 0, 6] := by
  decide

-- A P_A = P_A C_A, with C_A = C(x − 2) ⊕ C(x^2 − 5x + 6) and det P_A = −1.
example : (!![2, 0, 0; 0, 2, 1; 0, 0, 3] : Matrix (Fin 3) (Fin 3) ℤ) * !![0, 1, 2; 1, 1, 3; 0, 1, 3] =
    !![0, 1, 2; 1, 1, 3; 0, 1, 3] * !![2, 0, 0; 0, 0, -6; 0, 1, 5] := by
  decide
example : (!![0, 1, 2; 1, 1, 3; 0, 1, 3] : Matrix (Fin 3) (Fin 3) ℤ).det = -1 := by
  norm_num [Matrix.det_fin_three]

-- B P_B = P_B C_B, with C_B = C(x^3 − 7x^2 + 16x − 12) and det P_B = −1.
example : (!![2, 1, 0; 0, 2, 1; 0, 0, 3] : Matrix (Fin 3) (Fin 3) ℤ) * !![0, 0, 1; 0, 1, 5; 1, 3, 9] =
    !![0, 0, 1; 0, 1, 5; 1, 3, 9] * !![0, 0, 12; 1, 0, -16; 0, 1, 7] := by
  decide
example : (!![0, 0, 1; 0, 1, 5; 1, 3, 9] : Matrix (Fin 3) (Fin 3) ℤ).det = -1 := by
  norm_num [Matrix.det_fin_three]

-- Minimal polynomials: (A − 2I)(A − 3I) = 0, but (B − 2I)(B − 3I) ≠ 0 and (B − 2I)^2 (B − 3I) = 0.
example : ((!![2, 0, 0; 0, 2, 1; 0, 0, 3] : Matrix (Fin 3) (Fin 3) ℤ) - 2) *
    (!![2, 0, 0; 0, 2, 1; 0, 0, 3] - 3) = 0 := by
  decide
example : ((!![2, 1, 0; 0, 2, 1; 0, 0, 3] : Matrix (Fin 3) (Fin 3) ℤ) - 2) *
    (!![2, 1, 0; 0, 2, 1; 0, 0, 3] - 3) = !![0, -1, 1; 0, 0, 0; 0, 0, 0] := by
  decide
example : ((!![2, 1, 0; 0, 2, 1; 0, 0, 3] : Matrix (Fin 3) (Fin 3) ℤ) - 2) ^ 2 *
    (!![2, 1, 0; 0, 2, 1; 0, 0, 3] - 3) = 0 := by
  decide

-- The first row of B^5 is (32, 80, 131), with 80 = 5 × 2^4.
example : ((!![2, 1, 0; 0, 2, 1; 0, 0, 3] : Matrix (Fin 3) (Fin 3) ℤ) ^ 5) 0 = ![32, 80, 131] := by
  decide

#print axioms smith_normal_form_and_module_splits
#print axioms similar_iff_same_invariant_factors
#print axioms rational_canonical_form_of_invariant_factors
