-- Smith normal form: every integer matrix reduces by moves with whole-number inverses to a unique diagonal d₁ ∣ d₂ ∣ ⋯, and the homology group read off it is ℤ^(n_k − r_k − r_(k+1)) plus one ℤ mod dᵢ for each diagonal entry.
import Mathlib.LinearAlgebra.Matrix.Rank
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Quotient.Defs
import Mathlib.Data.ZMod.Defs
import Mathlib.Data.Int.GCD
import Mathlib.Tactic.NormNum
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.Transvection
import Mathlib.LinearAlgebra.Matrix.Permutation
import Mathlib.LinearAlgebra.FreeModule.PID
import Mathlib.LinearAlgebra.FiniteDimensional.Lemmas
import Mathlib.LinearAlgebra.Dimension.Localization
import Mathlib.RingTheory.Int.Basic
import Mathlib.Data.ZMod.Basic

section SNFHelpers

open Matrix

/-- Zero out the first `r` coordinates. -/
def zr {n : ℕ} (r : ℕ) (y : Fin n → ℤ) : Fin n → ℤ := fun i => if (i : ℕ) < r then 0 else y i

/-- Put a vector of length `r` into the first `r` coordinates. -/
def emb {n r : ℕ} (t : Fin r → ℤ) : Fin n → ℤ :=
  fun i => if h : (i : ℕ) < r then t ⟨i, h⟩ else 0

lemma snf_mulVec {n₁ n₂ r : ℕ} {D : Matrix (Fin n₁) (Fin n₂) ℤ} {d : ℕ → ℤ} (hr₂ : r ≤ n₂)
    (hD : ∀ i j, D i j = if (i : ℕ) = (j : ℕ) ∧ (i : ℕ) < r then d i else 0)
    (w : Fin n₂ → ℤ) (i : Fin n₁) :
    (D *ᵥ w) i = if h : (i : ℕ) < r then d i * w ⟨i, by omega⟩ else 0 := by
  simp only [mulVec, dotProduct, hD]
  split_ifs with h
  · rw [Finset.sum_eq_single ⟨i, by omega⟩]
    · simp [h]
    · intro b _ hb
      rw [if_neg]; · simp
      rintro ⟨h1, _⟩; exact hb (Fin.ext h1.symm)
    · simp
  · exact Finset.sum_eq_zero fun j _ => by rw [if_neg (by omega)]; simp

lemma col_zero {n₀ n₁ n₂ r : ℕ} {M : Matrix (Fin n₀) (Fin n₁) ℤ} {D : Matrix (Fin n₁) (Fin n₂) ℤ}
    {d : ℕ → ℤ} (hr₂ : r ≤ n₂) (hpos : ∀ i < r, 0 < d i)
    (hD : ∀ i j, D i j = if (i : ℕ) = (j : ℕ) ∧ (i : ℕ) < r then d i else 0) (hMD : M * D = 0)
    (k : Fin n₀) (l : Fin n₁) (hl : (l : ℕ) < r) : M k l = 0 := by
  have h := congrFun (congrFun hMD k) ⟨l, by omega⟩
  rw [Matrix.mul_apply, Finset.sum_eq_single l] at h
  · rw [hD, if_pos ⟨rfl, hl⟩] at h
    simpa [(hpos l hl).ne'] using h
  · intro b _ hb
    rw [hD, if_neg]; · simp
    rintro ⟨h1, _⟩; exact hb (Fin.ext h1)
  · simp

lemma mulVec_zr {n₀ n₁ r : ℕ} {M : Matrix (Fin n₀) (Fin n₁) ℤ}
    (hcol : ∀ k (l : Fin n₁), (l : ℕ) < r → M k l = 0) (y : Fin n₁ → ℤ) :
    M *ᵥ zr r y = M *ᵥ y := by
  ext k
  simp only [mulVec, dotProduct, zr]
  refine Finset.sum_congr rfl fun l _ => ?_
  split_ifs with h
  · simp [hcol k l h]
  · rfl

lemma mulVec_emb {n₀ n₁ r : ℕ} {M : Matrix (Fin n₀) (Fin n₁) ℤ}
    (hcol : ∀ k (l : Fin n₁), (l : ℕ) < r → M k l = 0) (t : Fin r → ℤ) :
    M *ᵥ (emb t : Fin n₁ → ℤ) = 0 := by
  rw [← mulVec_zr hcol]
  have : zr r (emb t : Fin n₁ → ℤ) = 0 := by
    ext i; simp only [zr, emb]; split_ifs <;> rfl
  rw [this, mulVec_zero]

/-- The cycles with their first `r` new coordinates zero. -/
def Fsub {n₀ n₁ : ℕ} (M : Matrix (Fin n₀) (Fin n₁) ℤ) (r : ℕ) : Submodule ℤ (Fin n₁ → ℤ) where
  carrier := {y | M *ᵥ y = 0 ∧ ∀ i : Fin n₁, (i : ℕ) < r → y i = 0}
  add_mem' := by
    rintro a b ⟨ha1, ha2⟩ ⟨hb1, hb2⟩
    exact ⟨by rw [mulVec_add, ha1, hb1, add_zero], fun i hi => by simp [ha2 i hi, hb2 i hi]⟩
  zero_mem' := ⟨by simp, fun _ _ => rfl⟩
  smul_mem' := by
    rintro c a ⟨ha1, ha2⟩
    exact ⟨by rw [mulVec_smul, ha1, smul_zero], fun i hi => by simp [ha2 i hi]⟩

/-- The cycles split as the part beyond the first `r` new coordinates and those coordinates. -/
noncomputable def cycleEquiv {n₀ n₁ r : ℕ} (A : Matrix (Fin n₀) (Fin n₁) ℤ)
    (S : Matrix (Fin n₁) (Fin n₁) ℤ) (hS : IsUnit S.det) (hr : r ≤ n₁)
    (hcol : ∀ k (l : Fin n₁), (l : ℕ) < r → (A * S⁻¹) k l = 0) :
    LinearMap.ker A.mulVecLin ≃ₗ[ℤ] Fsub (A * S⁻¹) r × (Fin r → ℤ) where
  toFun x := (⟨zr r (S *ᵥ (x : Fin n₁ → ℤ)), by
      refine ⟨?_, fun i hi => by simp [zr, hi]⟩
      rw [mulVec_zr hcol, mulVec_mulVec, Matrix.mul_assoc, nonsing_inv_mul _ hS, Matrix.mul_one]
      have := LinearMap.mem_ker.mp x.2
      rwa [mulVecLin_apply] at this⟩, fun i => (S *ᵥ (x : Fin n₁ → ℤ)) (Fin.castLE hr i))
  invFun p := ⟨S⁻¹ *ᵥ ((p.1 : Fin n₁ → ℤ) + emb p.2), by
      rw [LinearMap.mem_ker, mulVecLin_apply, mulVec_mulVec, mulVec_add, mulVec_emb hcol,
        p.1.2.1, add_zero]⟩
  map_add' x y := by
    ext i
    · simp [zr, mulVec_add]; split_ifs <;> simp
    · simp [mulVec_add]
  map_smul' c x := by
    ext i
    · simp [zr, mulVec_smul, -zsmul_eq_mul]
    · simp [mulVec_smul, -zsmul_eq_mul]
  left_inv x := by
    apply Subtype.ext
    simp only
    have : zr r (S *ᵥ (x : Fin n₁ → ℤ)) + emb (fun i => (S *ᵥ (x : Fin n₁ → ℤ)) (Fin.castLE hr i))
        = S *ᵥ (x : Fin n₁ → ℤ) := by
      ext i; simp only [zr, emb, Pi.add_apply]; split_ifs with h <;> simp
    rw [this, mulVec_mulVec, nonsing_inv_mul _ hS, one_mulVec]
  right_inv p := by
    obtain ⟨⟨y, hy1, hy2⟩, t⟩ := p
    have hSS : S *ᵥ (S⁻¹ *ᵥ (y + emb t)) = y + emb t := by
      rw [mulVec_mulVec, mul_nonsing_inv _ hS, one_mulVec]
    ext i
    · simp only [hSS]
      simp only [zr, emb, Pi.add_apply]
      split_ifs with h1 <;> simp_all
    · simp only [hSS]
      simp [emb, hy2 _ (show ((Fin.castLE hr i : Fin n₁) : ℕ) < r by simp)]


/-- A matrix with first entry `a`, rest of the first row `r`, rest of the first column `c`,
and lower-right block `M`. -/
def blk4 {m n : ℕ} (a : ℤ) (r : Fin n → ℤ) (c : Fin m → ℤ) (M : Matrix (Fin m) (Fin n) ℤ) :
    Matrix (Fin (m + 1)) (Fin (n + 1)) ℤ :=
  Matrix.of fun i j => Fin.cases (motive := fun _ => ℤ) (Fin.cases (motive := fun _ => ℤ) a r j)
    (fun i' => Fin.cases (motive := fun _ => ℤ) (c i') (M i') j) i

section blk
variable {m n : ℕ} (a : ℤ) (r : Fin n → ℤ) (c : Fin m → ℤ) (M : Matrix (Fin m) (Fin n) ℤ)

@[simp] lemma blk4_zero_zero : blk4 a r c M 0 0 = a := by simp [blk4]
@[simp] lemma blk4_zero_succ (j : Fin n) : blk4 a r c M 0 j.succ = r j := by simp [blk4]
@[simp] lemma blk4_succ_zero (i : Fin m) : blk4 a r c M i.succ 0 = c i := by simp [blk4]
@[simp] lemma blk4_succ_succ (i : Fin m) (j : Fin n) : blk4 a r c M i.succ j.succ = M i j := by
  simp [blk4]

lemma blk4_eta (X : Matrix (Fin (m + 1)) (Fin (n + 1)) ℤ) :
    X = blk4 (X 0 0) (fun j => X 0 j.succ) (fun i => X i.succ 0) (X.submatrix Fin.succ Fin.succ) := by
  ext i j
  refine Fin.cases ?_ (fun i => ?_) i <;> refine Fin.cases ?_ (fun j => ?_) j <;> simp

end blk

lemma det_blk4_row0 {m : ℕ} (a : ℤ) (c : Fin m → ℤ) (M : Matrix (Fin m) (Fin m) ℤ) :
    (blk4 a 0 c M).det = a * M.det := by
  rw [det_succ_row_zero, Fin.sum_univ_succ]
  have : (blk4 a 0 c M).submatrix Fin.succ Fin.succ = M := by
    ext i j; simp
  simp [this]

lemma blk4_mul_blk4 {m n p : ℕ} (a b : ℤ) (X : Matrix (Fin m) (Fin n) ℤ)
    (Y : Matrix (Fin n) (Fin p) ℤ) :
    blk4 a 0 0 X * blk4 b 0 0 Y = blk4 (a * b) 0 0 (X * Y) := by
  ext i j
  refine Fin.cases ?_ (fun i => ?_) i <;> refine Fin.cases ?_ (fun j => ?_) j <;>
    simp [Matrix.mul_apply, Fin.sum_univ_succ]

/-- `B` is reached from `A` by row and column moves that whole numbers undo. -/
def SEquiv {m n : ℕ} (A B : Matrix (Fin m) (Fin n) ℤ) : Prop :=
  ∃ (S : Matrix (Fin m) (Fin m) ℤ) (T : Matrix (Fin n) (Fin n) ℤ),
    IsUnit S.det ∧ IsUnit T.det ∧ B = S * A * T

lemma sequiv_refl {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℤ) : SEquiv A A :=
  ⟨1, 1, by simp, by simp, by simp⟩

lemma sequiv_left {m n : ℕ} {A B : Matrix (Fin m) (Fin n) ℤ} (h : SEquiv A B)
    (S : Matrix (Fin m) (Fin m) ℤ) (hS : IsUnit S.det) : SEquiv A (S * B) := by
  obtain ⟨S₀, T₀, h1, h2, rfl⟩ := h
  exact ⟨S * S₀, T₀, by rw [det_mul]; exact hS.mul h1, h2, by simp [Matrix.mul_assoc]⟩

lemma sequiv_right {m n : ℕ} {A B : Matrix (Fin m) (Fin n) ℤ} (h : SEquiv A B)
    (T : Matrix (Fin n) (Fin n) ℤ) (hT : IsUnit T.det) : SEquiv A (B * T) := by
  obtain ⟨S₀, T₀, h1, h2, rfl⟩ := h
  exact ⟨S₀, T₀ * T, h1, by rw [det_mul]; exact h2.mul hT, by simp [Matrix.mul_assoc]⟩

lemma isUnit_det_transvection {k : ℕ} {i j : Fin k} (h : i ≠ j) (c : ℤ) :
    IsUnit (transvection i j c).det := by
  simp [h]

/-- The conclusion of `exists_smith_normal_form`. -/
def HasSNF {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℤ) : Prop :=
  ∃ (S : Matrix (Fin m) (Fin m) ℤ) (T : Matrix (Fin n) (Fin n) ℤ) (r : ℕ) (d : ℕ → ℤ),
      IsUnit S.det ∧ IsUnit T.det ∧ r ≤ m ∧ r ≤ n ∧ (∀ i < r, 0 < d i) ∧
      (∀ i, i + 1 < r → d i ∣ d (i + 1)) ∧
      ∀ i j, (S * A * T) i j = if (i : ℕ) = (j : ℕ) ∧ (i : ℕ) < r then d i else 0

lemma hasSNF_zero {m n : ℕ} : HasSNF (0 : Matrix (Fin m) (Fin n) ℤ) :=
  ⟨1, 1, 0, 0, by simp, by simp, by omega, by omega, by simp, by simp, by simp⟩

lemma hasSNF_of_sequiv {m n : ℕ} {A B : Matrix (Fin m) (Fin n) ℤ} (h : SEquiv A B)
    (hB : HasSNF B) : HasSNF A := by
  obtain ⟨S₀, T₀, h1, h2, rfl⟩ := h
  obtain ⟨S, T, r, d, hS, hT, hrm, hrn, hpos, hdiv, hD⟩ := hB
  refine ⟨S * S₀, T₀ * T, r, d, by rw [det_mul]; exact hS.mul h1,
    by rw [det_mul]; exact h2.mul hT, hrm, hrn, hpos, hdiv, fun i j => ?_⟩
  rw [← hD]; simp [Matrix.mul_assoc]

lemma dvd_mul_entries {m n : ℕ} {c : ℤ} {M : Matrix (Fin m) (Fin n) ℤ} (h : ∀ i j, c ∣ M i j)
    (S : Matrix (Fin m) (Fin m) ℤ) (T : Matrix (Fin n) (Fin n) ℤ) (i : Fin m) (j : Fin n) :
    c ∣ (S * M * T) i j := by
  simp only [Matrix.mul_apply]
  exact Finset.dvd_sum fun k _ => Dvd.dvd.mul_right
    (Finset.dvd_sum fun l _ => Dvd.dvd.mul_left (h l k) _) _

lemma hasSNF_blk {m n : ℕ} (c : ℤ) (hc : c ≠ 0) (M : Matrix (Fin m) (Fin n) ℤ)
    (hM : HasSNF M) (hdvd : ∀ i j, c ∣ M i j) : HasSNF (blk4 c 0 0 M) := by
  obtain ⟨S', T', r', d', hS', hT', hrm, hrn, hpos', hdiv', hD'⟩ := hM
  set ε : ℤ := if 0 < c then 1 else -1 with hε_def
  have hεc : 0 < ε * c := by rw [hε_def]; split_ifs <;> omega
  have hε : IsUnit ε := by
    rw [hε_def]; split_ifs
    · exact isUnit_one
    · exact isUnit_one.neg
  refine ⟨blk4 ε 0 0 S', blk4 1 0 0 T', r' + 1, fun i => if i = 0 then ε * c else d' (i - 1),
    ?_, ?_, by omega, by omega, ?_, ?_, ?_⟩
  · rw [det_blk4_row0]; exact hε.mul hS'
  · rw [det_blk4_row0, one_mul]; exact hT'
  · intro i hi
    dsimp only
    split_ifs
    · exact hεc
    · exact hpos' _ (by omega)
  · intro i hi
    rcases i with _ | i
    · simp only [if_true, show (0 + 1 = 0) = False by simp, if_false, Nat.add_sub_cancel]
      have h0 : d' 0 = (S' * M * T') ⟨0, by omega⟩ ⟨0, by omega⟩ := by
        rw [hD']; simp; omega
      rw [h0]
      exact (hε.mul_left_dvd).mpr (dvd_mul_entries hdvd S' T' _ _)
    · simp only [Nat.add_eq_zero_iff, one_ne_zero, and_false, if_false]
      simpa using hdiv' i (by omega)
  · intro i j
    rw [blk4_mul_blk4, blk4_mul_blk4, mul_one]
    refine Fin.cases ?_ (fun i => ?_) i <;> refine Fin.cases ?_ (fun j => ?_) j <;>
      simp [hD']

lemma exists_blk {m n : ℕ} (A : Matrix (Fin (m + 1)) (Fin (n + 1)) ℤ) (hA : A ≠ 0) :
    ∃ (c : ℤ) (M : Matrix (Fin m) (Fin n) ℤ), c ≠ 0 ∧ (∀ i j, c ∣ M i j) ∧
      SEquiv A (blk4 c 0 0 M) := by
  classical
  have hex : ∃ k, ∃ B, SEquiv A B ∧ ∃ i j, B i j ≠ 0 ∧ (B i j).natAbs = k := by
    obtain ⟨i, j, hij⟩ : ∃ i j, A i j ≠ 0 := by
      by_contra h
      push Not at h
      exact hA (Matrix.ext fun i j => by simp [h])
    exact ⟨_, A, sequiv_refl A, i, j, hij, rfl⟩
  obtain ⟨B, hB, i₀, j₀, hB0, hBk⟩ := Nat.find_spec hex
  have hmin : ∀ C, SEquiv A C → ∀ i j, C i j ≠ 0 → Nat.find hex ≤ (C i j).natAbs :=
    fun C hC i j h => Nat.find_min' hex ⟨C, hC, i, j, h, rfl⟩
  have hδ : 0 < Nat.find hex := by rw [← hBk]; exact Int.natAbs_pos.mpr hB0
  have key : ∀ C, SEquiv A C → (C 0 0).natAbs = Nat.find hex →
      (∀ j, C 0 0 ∣ C 0 j) ∧ (∀ i, C 0 0 ∣ C i 0) := by
    intro C hC hC0
    have hc : C 0 0 ≠ 0 := by
      intro h; rw [h] at hC0; simp at hC0; omega
    constructor
    · intro j
      by_contra hnd
      have hj : j ≠ 0 := by rintro rfl; exact hnd dvd_rfl
      have hρ : C 0 j % C 0 0 ≠ 0 := fun h => hnd (Int.dvd_of_emod_eq_zero h)
      have hC' := sequiv_right hC (transvection 0 j (-(C 0 j / C 0 0)))
        (isUnit_det_transvection (Ne.symm hj) _)
      have hval : (C * transvection 0 j (-(C 0 j / C 0 0))) 0 j = C 0 j % C 0 0 := by
        rw [mul_transvection_apply_same, Int.emod_def]; ring
      have h1 := hmin _ hC' 0 j (by rw [hval]; exact hρ)
      rw [hval] at h1
      have h2 := Int.emod_lt (C 0 j) hc
      have h3 := Int.emod_nonneg (C 0 j) hc
      omega
    · intro i
      by_contra hnd
      have hi : i ≠ 0 := by rintro rfl; exact hnd dvd_rfl
      have hρ : C i 0 % C 0 0 ≠ 0 := fun h => hnd (Int.dvd_of_emod_eq_zero h)
      have hC' := sequiv_left hC (transvection i 0 (-(C i 0 / C 0 0)))
        (isUnit_det_transvection hi _)
      have hval : (transvection i 0 (-(C i 0 / C 0 0)) * C) i 0 = C i 0 % C 0 0 := by
        rw [transvection_mul_apply_same, Int.emod_def]; ring
      have h1 := hmin _ hC' i 0 (by rw [hval]; exact hρ)
      rw [hval] at h1
      have h2 := Int.emod_lt (C i 0) hc
      have h3 := Int.emod_nonneg (C i 0) hc
      omega
  -- move the smallest entry to the corner
  set σ : Equiv.Perm (Fin (m + 1)) := Equiv.swap 0 i₀
  set τ : Equiv.Perm (Fin (n + 1)) := Equiv.swap 0 j₀
  set B1 := σ.permMatrix ℤ * B * τ.permMatrix ℤ with hB1_def
  have hB1 : SEquiv A B1 :=
    sequiv_right (sequiv_left hB _ (by rw [det_permutation]; exact Units.isUnit _)) _
      (by rw [det_permutation]; exact Units.isUnit _)
  have hB100 : B1 0 0 = B i₀ j₀ := by
    rw [hB1_def, Equiv.Perm.permMatrix, Equiv.Perm.permMatrix, PEquiv.toMatrix_toPEquiv_mul,
      PEquiv.mul_toMatrix_toPEquiv]
    simp [σ, τ]
  set c := B1 0 0 with hc_def
  have hc : c ≠ 0 := by rw [hB100]; exact hB0
  have hcδ : c.natAbs = Nat.find hex := by rw [hB100, hBk]
  obtain ⟨hrow, hcol⟩ := key B1 hB1 hcδ
  -- clear the first row and column
  set L : Matrix (Fin (m + 1)) (Fin (m + 1)) ℤ := blk4 1 0 (fun i => -(B1 i.succ 0 / c)) 1
  set R : Matrix (Fin (n + 1)) (Fin (n + 1)) ℤ :=
    (blk4 1 0 (fun j => -(B1 0 j.succ / c)) 1)ᵀ
  have hL : IsUnit L.det := by rw [det_blk4_row0]; simp
  have hR : IsUnit R.det := by rw [det_transpose, det_blk4_row0]; simp
  set C := L * B1 * R with hC_def
  have hC : SEquiv A C := sequiv_right (sequiv_left hB1 L hL) R hR
  have hLB : ∀ j, (L * B1) 0 j = B1 0 j := by
    intro j; simp [L, Matrix.mul_apply, Fin.sum_univ_succ]
  have hLB' : ∀ i : Fin m, (L * B1) i.succ 0 = 0 := by
    intro i
    simp [L, Matrix.mul_apply, Fin.sum_univ_succ, Matrix.one_apply]
    rw [Int.ediv_mul_cancel (hcol _)]; ring
  have hC0 : ∀ i, C i 0 = (L * B1) i 0 := by
    intro i; simp [C, R, Matrix.mul_apply, Fin.sum_univ_succ]
  have hC00 : C 0 0 = c := by rw [hC0, hLB]
  have hCi0 : ∀ i : Fin m, C i.succ 0 = 0 := by intro i; rw [hC0, hLB']
  have hC0j : ∀ j : Fin n, C 0 j.succ = 0 := by
    intro j
    simp [C, R, Matrix.mul_apply, Fin.sum_univ_succ, Matrix.one_apply, hLB]
    rw [Int.mul_ediv_cancel' (hrow _)]; ring
  have hCblk : C = blk4 c 0 0 (C.submatrix Fin.succ Fin.succ) := by
    conv_lhs => rw [blk4_eta C]
    rw [hC00]
    congr 1
    · funext j; exact hC0j j
    · funext i; exact hCi0 i
  refine ⟨c, C.submatrix Fin.succ Fin.succ, hc, fun i j => ?_, hCblk ▸ hC⟩
  have hC2 := sequiv_left hC (transvection 0 i.succ (1 : ℤ))
    (isUnit_det_transvection (Fin.succ_ne_zero i).symm _)
  have h00 : (transvection 0 i.succ (1 : ℤ) * C) 0 0 = c := by
    rw [transvection_mul_apply_same, hC00, hCi0]; ring
  have h0j : (transvection 0 i.succ (1 : ℤ) * C) 0 j.succ = C i.succ j.succ := by
    rw [transvection_mul_apply_same, hC0j]; ring
  have := (key _ hC2 (by rw [h00, hcδ])).1 j.succ
  rw [h00, h0j] at this
  simpa using this

lemma hasSNF_all : ∀ (m n : ℕ) (A : Matrix (Fin m) (Fin n) ℤ), HasSNF A := by
  intro m
  induction m with
  | zero =>
    intro n A
    have : A = 0 := by ext i; exact i.elim0
    rw [this]; exact hasSNF_zero
  | succ m ih =>
    intro n A
    cases n with
    | zero =>
      have : A = 0 := by ext i j; exact j.elim0
      rw [this]; exact hasSNF_zero
    | succ n =>
      by_cases hA : A = 0
      · rw [hA]; exact hasSNF_zero
      · obtain ⟨c, M, hc, hdvd, hAB⟩ := exists_blk A hA
        exact hasSNF_of_sequiv hAB (hasSNF_blk c hc M (ih n M) hdvd)


/-- The ideal generated by all k-by-k minors (rows and columns chosen by any maps). -/
def minorIdeal {m n : ℕ} (k : ℕ) (A : Matrix (Fin m) (Fin n) ℤ) : Ideal ℤ :=
  Ideal.span {x | ∃ (f : Fin k → Fin m) (g : Fin k → Fin n), x = (A.submatrix f g).det}

lemma det_mul_rect {k m : ℕ} (P : Matrix (Fin k) (Fin m) ℤ) (Q : Matrix (Fin m) (Fin k) ℤ) :
    (P * Q).det = ∑ p : Fin k → Fin m, (∏ i, P i (p i)) * (Q.submatrix p id).det := by
  have h : (P * Q) = fun i => ∑ j, P i j • Q j := by
    ext i l; simp [Matrix.mul_apply, Finset.sum_apply]
  change Matrix.detRowAlternating.toMultilinearMap (P * Q) = _
  rw [h, MultilinearMap.map_sum]
  refine Finset.sum_congr rfl fun p _ => ?_
  rw [MultilinearMap.map_smul_univ, smul_eq_mul]
  rfl

lemma minorIdeal_mul_left {m n k l : ℕ} (S : Matrix (Fin l) (Fin m) ℤ)
    (A : Matrix (Fin m) (Fin n) ℤ) : minorIdeal k (S * A) ≤ minorIdeal k A := by
  rw [minorIdeal, Ideal.span_le]
  rintro x ⟨f, g, rfl⟩
  have : (S * A).submatrix f g = S.submatrix f id * A.submatrix id g := by
    ext; simp [Matrix.mul_apply]
  rw [this, det_mul_rect]
  exact Submodule.sum_mem _ fun p _ => Ideal.mul_mem_left _ _ (Ideal.subset_span ⟨p, g, rfl⟩)

lemma minorIdeal_mul_right {m n k l : ℕ} (A : Matrix (Fin m) (Fin n) ℤ)
    (T : Matrix (Fin n) (Fin l) ℤ) : minorIdeal k (A * T) ≤ minorIdeal k A := by
  rw [minorIdeal, Ideal.span_le]
  rintro x ⟨f, g, rfl⟩
  have : ((A * T).submatrix f g).det = ((Tᵀ.submatrix g id) * (Aᵀ.submatrix id f)).det := by
    rw [← det_transpose]; congr 1; ext; simp [Matrix.mul_apply, mul_comm]
  rw [this, det_mul_rect]
  refine Submodule.sum_mem _ fun p _ => Ideal.mul_mem_left _ _ (Ideal.subset_span ⟨f, p, ?_⟩)
  rw [← det_transpose]; rfl

lemma minorIdeal_eq {m n k : ℕ} (A : Matrix (Fin m) (Fin n) ℤ) (S : Matrix (Fin m) (Fin m) ℤ)
    (T : Matrix (Fin n) (Fin n) ℤ) (hS : IsUnit S.det) (hT : IsUnit T.det) :
    minorIdeal k (S * A * T) = minorIdeal k A := by
  apply le_antisymm
  · exact (minorIdeal_mul_right _ _).trans (minorIdeal_mul_left _ _)
  · have : A = S⁻¹ * (S * A * T) * T⁻¹ := by
      rw [← Matrix.mul_assoc, ← Matrix.mul_assoc, Matrix.nonsing_inv_mul _ hS, Matrix.one_mul,
        Matrix.mul_assoc, Matrix.mul_nonsing_inv _ hT, Matrix.mul_one]
    conv_lhs => rw [this]
    exact (minorIdeal_mul_right _ _).trans (minorIdeal_mul_left _ _)

lemma chain_dvd {r : ℕ} {d : ℕ → ℤ} (hdiv : ∀ i, i + 1 < r → d i ∣ d (i + 1)) :
    ∀ a b, a ≤ b → b < r → d a ∣ d b := by
  intro a b hab hb
  induction b with
  | zero => obtain rfl : a = 0 := by omega
            exact dvd_rfl
  | succ b ih =>
    rcases Nat.eq_or_lt_of_le hab with rfl | h
    · exact dvd_rfl
    · exact (ih (by omega) (by omega)).trans (hdiv b hb)

lemma prod_range_dvd_prod_finset {r : ℕ} {d : ℕ → ℤ} (hdiv : ∀ i, i + 1 < r → d i ∣ d (i + 1)) :
    ∀ (k : ℕ) (s : Finset ℕ), s.card = k → (∀ j ∈ s, j < r) →
      ∏ i ∈ Finset.range k, d i ∣ ∏ j ∈ s, d j := by
  intro k
  induction k with
  | zero => intro s _ _; simp
  | succ k ih =>
    intro s hs hr
    have hne : s.Nonempty := Finset.card_pos.mp (by omega)
    have hM : s.max' hne ∈ s := Finset.max'_mem s hne
    have hkM : k ≤ s.max' hne := by
      have hsub : s ⊆ Finset.range (s.max' hne + 1) := fun x hx =>
        Finset.mem_range.mpr (Nat.lt_succ_of_le (Finset.le_max' s x hx))
      have := Finset.card_le_card hsub
      simp at this; omega
    rw [Finset.prod_range_succ, ← Finset.mul_prod_erase s _ hM, mul_comm]
    exact mul_dvd_mul (chain_dvd hdiv _ _ hkM (hr _ hM))
      (ih _ (by rw [Finset.card_erase_of_mem hM]; omega)
        (fun j hj => hr j (Finset.mem_of_mem_erase hj)))

lemma minor_dvd_of_snf {m n r k : ℕ} {D : Matrix (Fin m) (Fin n) ℤ} {d : ℕ → ℤ}
    (hdiv : ∀ i, i + 1 < r → d i ∣ d (i + 1))
    (hD : ∀ i j, D i j = if (i : ℕ) = (j : ℕ) ∧ (i : ℕ) < r then d i else 0)
    (f : Fin k → Fin m) (g : Fin k → Fin n) :
    (if k ≤ r then ∏ i ∈ Finset.range k, d i else 0) ∣ (D.submatrix f g).det := by
  by_cases hg : Function.Injective g
  · rw [Matrix.det_apply]
    apply Finset.dvd_sum
    intro σ _
    by_cases h0 : ∃ i, D (f (σ i)) (g i) = 0
    · obtain ⟨i, hi⟩ := h0
      rw [Finset.prod_eq_zero (Finset.mem_univ i) (by simpa using hi)]
      simp
    · push Not at h0
      have hg' : ∀ i, ((g i : ℕ) < r) ∧ D (f (σ i)) (g i) = d (g i) := by
        intro i
        have := h0 i
        rw [hD] at this ⊢
        split_ifs at this ⊢ with h
        · exact ⟨h.1 ▸ h.2, by rw [h.1]⟩
        · exact absurd rfl this
      have hkr : k ≤ r := by
        have := Fintype.card_le_of_injective (fun i => (⟨g i, (hg' i).1⟩ : Fin r))
          (by intro a b h; apply hg; simp only [Fin.mk.injEq] at h; exact Fin.ext h)
        simpa using this
      rw [if_pos hkr, Units.smul_def]
      apply Dvd.dvd.mul_left
      have himg : (Finset.univ.image (fun i => (g i : ℕ))).card = k := by
        rw [Finset.card_image_of_injective _ (fun a b h => hg (Fin.ext h))]; simp
      calc ∏ i ∈ Finset.range k, d i
          ∣ ∏ j ∈ Finset.univ.image (fun i => (g i : ℕ)), d j :=
            prod_range_dvd_prod_finset hdiv k _ himg (by
              intro j hj; simp only [Finset.mem_image] at hj
              obtain ⟨i, _, rfl⟩ := hj; exact (hg' i).1)
        _ = ∏ i, d (g i) := Finset.prod_image (fun a _ b _ h => hg (Fin.ext h))
        _ = ∏ i, (D.submatrix f g) (σ i) i := by
            refine Finset.prod_congr rfl fun i _ => ?_
            simp [(hg' i).2]
  · obtain ⟨a, b, hab, hne⟩ : ∃ a b, g a = g b ∧ a ≠ b := by
      simpa [Function.Injective] using hg
    rw [Matrix.det_zero_of_column_eq hne (by intro i; simp [hab])]
    exact dvd_zero _

lemma minorIdeal_snf {m n r : ℕ} {D : Matrix (Fin m) (Fin n) ℤ} {d : ℕ → ℤ}
    (hrm : r ≤ m) (hrn : r ≤ n) (hdiv : ∀ i, i + 1 < r → d i ∣ d (i + 1))
    (hD : ∀ i j, D i j = if (i : ℕ) = (j : ℕ) ∧ (i : ℕ) < r then d i else 0) (k : ℕ) :
    minorIdeal k D = Ideal.span {if k ≤ r then ∏ i ∈ Finset.range k, d i else 0} := by
  apply le_antisymm
  · rw [minorIdeal, Ideal.span_le]
    rintro x ⟨f, g, rfl⟩
    exact Ideal.mem_span_singleton.mpr (minor_dvd_of_snf hdiv hD f g)
  · rw [Ideal.span_le, Set.singleton_subset_iff]
    split_ifs with hk
    · apply Ideal.subset_span
      refine ⟨Fin.castLE (hk.trans hrm), Fin.castLE (hk.trans hrn), ?_⟩
      have : D.submatrix (Fin.castLE (hk.trans hrm)) (Fin.castLE (hk.trans hrn)) =
          Matrix.diagonal (fun i : Fin k => d i) := by
        ext i j
        rw [Matrix.submatrix_apply, hD, Matrix.diagonal_apply]
        simp only [Fin.val_castLE, Fin.ext_iff]
        split_ifs with h1 h2 h2 <;> first | rfl | omega
      rw [this, det_diagonal, Fin.prod_univ_eq_prod_range (fun i => d i) k]
    · exact zero_mem _


/-- The homology statement, proved with `Matrix` notation open. -/
lemma homology_aux {n₀ n₁ n₂ r : ℕ}
    (A : Matrix (Fin n₀) (Fin n₁) ℤ) (B : Matrix (Fin n₁) (Fin n₂) ℤ) (hAB : A * B = 0)
    (S : Matrix (Fin n₁) (Fin n₁) ℤ) (T : Matrix (Fin n₂) (Fin n₂) ℤ)
    (hS : IsUnit S.det) (hT : IsUnit T.det) (d : ℕ → ℤ)
    (hr₁ : r ≤ n₁) (hr₂ : r ≤ n₂) (hpos : ∀ i < r, 0 < d i)
    (hdiv : ∀ i, i + 1 < r → d i ∣ d (i + 1))
    (hD : ∀ i j, (S * B * T) i j = if (i : ℕ) = (j : ℕ) ∧ (i : ℕ) < r then d i else 0) :
    Nonempty ((LinearMap.ker A.mulVecLin ⧸
        (LinearMap.range B.mulVecLin).comap (LinearMap.ker A.mulVecLin).subtype) ≃+
      ((Fin (n₁ - A.rank - r) → ℤ) × ((i : Fin r) → ZMod (d i).natAbs))) := by
  have hMD : A * S⁻¹ * (S * B * T) = 0 := by
    rw [show A * S⁻¹ * (S * B * T) = A * (S⁻¹ * S) * B * T by simp only [Matrix.mul_assoc],
      nonsing_inv_mul _ hS, Matrix.mul_one, hAB, Matrix.zero_mul]
  have hcol := col_zero hr₂ hpos hD hMD
  set E := cycleEquiv A S hS hr₁ hcol
  -- the rank of the free part
  have hrk : Module.finrank ℤ (Fsub (A * S⁻¹) r) = n₁ - A.rank - r := by
    have h1 := E.finrank_eq
    rw [Module.finrank_prod, Module.finrank_fin_fun] at h1
    have h3 := LinearMap.finrank_range_add_finrank_ker A.mulVecLin
    rw [Module.finrank_fin_fun] at h3
    rw [Matrix.rank]
    omega
  set eF := (Module.finBasisOfFinrankEq ℤ _ hrk).equivFun
  let modmap : (Fin r → ℤ) →ₗ[ℤ] ((i : Fin r) → ZMod (d i).natAbs) :=
    { toFun := fun t i => (t i : ZMod (d i).natAbs)
      map_add' := fun a b => by funext i; simp
      map_smul' := fun c a => by funext i; simp }
  set Ψ := (LinearMap.prodMap eF.toLinearMap modmap) ∘ₗ E.toLinearMap
  have hsurj : Function.Surjective Ψ := by
    intro ⟨z, u⟩
    have hu := fun i => ZMod.intCast_surjective (u i)
    choose t ht using hu
    obtain ⟨x, hx⟩ := E.surjective (eF.symm z, t)
    refine ⟨x, ?_⟩
    simp only [Ψ, LinearMap.coe_comp, Function.comp_apply, LinearEquiv.coe_coe, hx,
      LinearMap.prodMap_apply, LinearEquiv.apply_symm_apply]
    congr 1
    funext i; exact ht i
  have hker : LinearMap.ker Ψ =
      (LinearMap.range B.mulVecLin).comap (LinearMap.ker A.mulVecLin).subtype := by
    ext x
    simp only [LinearMap.mem_ker, Submodule.mem_comap, Submodule.coe_subtype, LinearMap.mem_range,
      mulVecLin_apply]
    simp only [Ψ, LinearMap.coe_comp, Function.comp_apply, LinearEquiv.coe_coe,
      LinearMap.prodMap_apply, Prod.mk_eq_zero, LinearEquiv.map_eq_zero_iff]
    have hE1 : ((E x).1 : Fin n₁ → ℤ) = zr r (S *ᵥ (x : Fin n₁ → ℤ)) := rfl
    have hE2 : (E x).2 = fun i => (S *ᵥ (x : Fin n₁ → ℤ)) (Fin.castLE hr₁ i) := rfl
    have hmod : ∀ t : Fin r → ℤ, modmap t = 0 ↔ ∀ i : Fin r, d i ∣ t i := by
      intro t
      simp only [modmap, LinearMap.coe_mk, AddHom.coe_mk, funext_iff, Pi.zero_apply]
      exact forall_congr' fun i => by rw [ZMod.intCast_zmod_eq_zero_iff_dvd, Int.natAbs_dvd]
    rw [hmod, hE2]
    constructor
    · rintro ⟨h1, h2⟩
      have hz : zr r (S *ᵥ (x : Fin n₁ → ℤ)) = 0 := by rw [← hE1, h1]; rfl
      let w : Fin n₂ → ℤ := fun j =>
        if h : (j : ℕ) < r then (S *ᵥ (x : Fin n₁ → ℤ)) ⟨j, by omega⟩ / d j else 0
      have hw : (S * B * T) *ᵥ w = S *ᵥ (x : Fin n₁ → ℤ) := by
        ext i
        rw [snf_mulVec hr₂ hD]
        split_ifs with h
        · simp only [w, dif_pos h]
          exact Int.mul_ediv_cancel' (h2 ⟨i, h⟩)
        · have := congrFun hz i
          simp only [zr, if_neg h, Pi.zero_apply] at this
          exact this.symm
      refine ⟨T *ᵥ w, ?_⟩
      calc B *ᵥ (T *ᵥ w) = S⁻¹ *ᵥ ((S * B * T) *ᵥ w) := by
            rw [mulVec_mulVec, mulVec_mulVec, ← Matrix.mul_assoc, ← Matrix.mul_assoc,
              nonsing_inv_mul _ hS, Matrix.one_mul]
        _ = x := by rw [hw, mulVec_mulVec, nonsing_inv_mul _ hS, one_mulVec]
    · rintro ⟨v, hv⟩
      have hSx : S *ᵥ (x : Fin n₁ → ℤ) = (S * B * T) *ᵥ (T⁻¹ *ᵥ v) := by
        rw [← hv, mulVec_mulVec, mulVec_mulVec, Matrix.mul_assoc (S * B), mul_nonsing_inv _ hT,
          Matrix.mul_one]
      constructor
      · apply Subtype.ext
        rw [hE1]
        ext i
        simp only [zr, Pi.zero_apply, ZeroMemClass.coe_zero]
        split_ifs with h
        · rfl
        · rw [hSx, snf_mulVec hr₂ hD, dif_neg h]
      · intro i
        simp only [hSx]
        rw [snf_mulVec hr₂ hD, dif_pos (by simp)]
        exact dvd_mul_right _ _
  exact ⟨((Submodule.quotEquivOfEq _ _ hker.symm).trans
    (Ψ.quotKerEquivOfSurjective hsurj)).toAddEquiv⟩

#print axioms snf_mulVec
#print axioms col_zero
#print axioms mulVec_zr
#print axioms mulVec_emb
#print axioms blk4_zero_zero
#print axioms blk4_zero_succ
#print axioms blk4_succ_zero
#print axioms blk4_succ_succ
#print axioms blk4_eta
#print axioms det_blk4_row0
#print axioms blk4_mul_blk4
#print axioms sequiv_refl
#print axioms sequiv_left
#print axioms sequiv_right
#print axioms isUnit_det_transvection
#print axioms hasSNF_zero
#print axioms hasSNF_of_sequiv
#print axioms dvd_mul_entries
#print axioms hasSNF_blk
#print axioms exists_blk
#print axioms hasSNF_all
#print axioms det_mul_rect
#print axioms minorIdeal_mul_left
#print axioms minorIdeal_mul_right
#print axioms minorIdeal_eq
#print axioms chain_dvd
#print axioms prod_range_dvd_prod_finset
#print axioms minor_dvd_of_snf
#print axioms minorIdeal_snf
#print axioms homology_aux

end SNFHelpers

/-- The homology group read off the Smith diagonal. Let `A = ∂_k` and `B = ∂_(k+1)` be integer
boundary matrices with signed rims, so that `∂_k ∂_(k+1) = 0`. Suppose row and column moves that
whole numbers undo (`S`, `T` with determinant ±1) turn `B` into its Smith normal form: the
positive diagonal `d₀ ∣ d₁ ∣ ⋯ ∣ d_(r-1)` followed by zeros. Then the k-th homology group, the
cycles (kernel of `A`) modulo the rims (image of `B`), is one free whole-number counter for each
of the `n_k − r_k − r_(k+1)` holes, plus one counter `ℤ mod dᵢ` for each diagonal entry. -/
theorem homology_eq_free_part_plus_smith_torsion {n₀ n₁ n₂ r : ℕ}
    (A : Matrix (Fin n₀) (Fin n₁) ℤ) (B : Matrix (Fin n₁) (Fin n₂) ℤ) (hAB : A * B = 0)
    (S : Matrix (Fin n₁) (Fin n₁) ℤ) (T : Matrix (Fin n₂) (Fin n₂) ℤ)
    (hS : IsUnit S.det) (hT : IsUnit T.det) (d : ℕ → ℤ)
    (hr₁ : r ≤ n₁) (hr₂ : r ≤ n₂) (hpos : ∀ i < r, 0 < d i)
    (hdiv : ∀ i, i + 1 < r → d i ∣ d (i + 1))
    (hD : ∀ i j, (S * B * T) i j = if (i : ℕ) = (j : ℕ) ∧ (i : ℕ) < r then d i else 0) :
    Nonempty ((LinearMap.ker A.mulVecLin ⧸
        (LinearMap.range B.mulVecLin).comap (LinearMap.ker A.mulVecLin).subtype) ≃+
      ((Fin (n₁ - A.rank - r) → ℤ) × ((i : Fin r) → ZMod (d i).natAbs))) := by
  exact homology_aux A B hAB S T hS hT d hr₁ hr₂ hpos hdiv hD

/-- The routine always stops: every integer matrix can be brought, by row and column moves that
whole numbers undo, to a diagonal of positive whole numbers, each dividing the next, then zeros. -/
theorem exists_smith_normal_form {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℤ) :
    ∃ (S : Matrix (Fin m) (Fin m) ℤ) (T : Matrix (Fin n) (Fin n) ℤ) (r : ℕ) (d : ℕ → ℤ),
      IsUnit S.det ∧ IsUnit T.det ∧ r ≤ m ∧ r ≤ n ∧ (∀ i < r, 0 < d i) ∧
      (∀ i, i + 1 < r → d i ∣ d (i + 1)) ∧
      ∀ i j, (S * A * T) i j = if (i : ℕ) = (j : ℕ) ∧ (i : ℕ) < r then d i else 0 := by
  exact hasSNF_all m n A

/-- The diagonal does not depend on the route: two Smith normal forms of the same integer matrix
have the same number of nonzero entries and the same entries. -/
theorem smith_normal_form_unique {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℤ)
    (S S' : Matrix (Fin m) (Fin m) ℤ) (T T' : Matrix (Fin n) (Fin n) ℤ) (r r' : ℕ)
    (d d' : ℕ → ℤ) (hS : IsUnit S.det) (hT : IsUnit T.det)
    (hS' : IsUnit S'.det) (hT' : IsUnit T'.det)
    (hr : r ≤ m ∧ r ≤ n) (hr' : r' ≤ m ∧ r' ≤ n)
    (hpos : ∀ i < r, 0 < d i) (hpos' : ∀ i < r', 0 < d' i)
    (hdiv : ∀ i, i + 1 < r → d i ∣ d (i + 1)) (hdiv' : ∀ i, i + 1 < r' → d' i ∣ d' (i + 1))
    (hD : ∀ i j, (S * A * T) i j = if (i : ℕ) = (j : ℕ) ∧ (i : ℕ) < r then d i else 0)
    (hD' : ∀ i j, (S' * A * T') i j = if (i : ℕ) = (j : ℕ) ∧ (i : ℕ) < r' then d' i else 0) :
    r = r' ∧ ∀ i < r, d i = d' i := by
  have hJ : ∀ k, Ideal.span {if k ≤ r then ∏ i ∈ Finset.range k, d i else 0} =
      Ideal.span {if k ≤ r' then ∏ i ∈ Finset.range k, d' i else 0} := fun k => by
    rw [← minorIdeal_snf hr.1 hr.2 hdiv hD, ← minorIdeal_snf hr'.1 hr'.2 hdiv' hD',
      minorIdeal_eq A S T hS hT, minorIdeal_eq A S' T' hS' hT']
  have hP : ∀ k ≤ r, 0 < ∏ i ∈ Finset.range k, d i := fun k hk =>
    Finset.prod_pos (fun i hi => hpos i (by simp at hi; omega))
  have hP' : ∀ k ≤ r', 0 < ∏ i ∈ Finset.range k, d' i := fun k hk =>
    Finset.prod_pos (fun i hi => hpos' i (by simp at hi; omega))
  have hrr : r = r' := by
    by_contra hne
    rcases Nat.lt_or_gt_of_ne hne with h | h
    · have h1 := hJ (r + 1)
      rw [if_neg (by omega), if_pos (by omega)] at h1
      have h2 := Ideal.span_singleton_eq_bot.mp (h1.symm.trans (Ideal.span_singleton_eq_bot.mpr rfl))
      exact (hP' (r + 1) (by omega)).ne' h2
    · have h1 := hJ (r' + 1)
      rw [if_pos (by omega), if_neg (by omega)] at h1
      have h2 := Ideal.span_singleton_eq_bot.mp (h1.trans (Ideal.span_singleton_eq_bot.mpr rfl))
      exact (hP (r' + 1) (by omega)).ne' h2
  subst hrr
  have hPeq : ∀ k ≤ r, ∏ i ∈ Finset.range k, d i = ∏ i ∈ Finset.range k, d' i := by
    intro k hk
    have h1 := hJ k
    rw [if_pos hk, if_pos hk, Ideal.span_singleton_eq_span_singleton] at h1
    exact Int.eq_of_associated_of_nonneg h1 (hP k hk).le (hP' k hk).le
  refine ⟨rfl, fun i hi => ?_⟩
  have h1 := hPeq (i + 1) (by omega)
  rw [Finset.prod_range_succ, Finset.prod_range_succ, hPeq i (by omega)] at h1
  exact mul_left_cancel₀ (hP' i (by omega)).ne' h1

/-! Worked numbers from the card: the Klein bottle cut into 1 corner, edges a b c, triangles U L. -/

/-- The cell Klein bottle's `∂₂`, rows a, b, c and columns U, L. -/
def kleinD2 : Matrix (Fin 3) (Fin 2) ℤ := !![1, 1; 1, -1; -1, -1]

-- The row moves (row b − row a, row c + row a, row b × −1) and the column move
-- (column L − column U) reduce `∂₂` to diag(1, 2); both move matrices have determinant ±1.
example : !![(1 : ℤ), 0, 0; 1, -1, 0; 1, 0, 1] * kleinD2 * !![(1 : ℤ), -1; 0, 1] =
    !![1, 0; 0, 2; 0, 0] := by decide
example : (!![(1 : ℤ), 0, 0; 1, -1, 0; 1, 0, 1]).det = -1 := by decide
example : (!![(1 : ℤ), -1; 0, 1]).det = 1 := by decide
-- The intermediate steps of the hand reduction.
example : !![(1 : ℤ), 0, 0; -1, 1, 0; 1, 0, 1] * kleinD2 = !![1, 1; 0, -2; 0, 0] := by decide
example : !![(1 : ℤ), 1; 0, -2; 0, 0] * !![(1 : ℤ), -1; 0, 1] = !![1, 0; 0, -2; 0, 0] := by decide
-- The twist itself: the rim of U − L is 2b.
example : kleinD2.mulVec ![1, -1] = ![0, 2, 0] := by decide
-- Check by minors: the 2-by-2 minors are −2, 0, −2, with gcd 2.
example : (kleinD2.submatrix ![0, 1] id).det = -2 := by decide
example : (kleinD2.submatrix ![0, 2] id).det = 0 := by decide
example : (kleinD2.submatrix ![1, 2] id).det = -2 := by decide
example : Int.gcd (Int.gcd (-2) 0) (-2) = 2 := by decide
-- β₁ = n₁ − r₁ − r₂ = 3 − 0 − 2 = 1.
example : (3 : ℕ) - 0 - 2 = 1 := by norm_num
-- Smith of [[2, 0], [0, 3]] is diag(1, 6), and of [[4, 6]] is [2].
example : !![(1 : ℤ), 1; 3, 2] * !![(2 : ℤ), 0; 0, 3] * !![(-1 : ℤ), 3; 1, -2] =
    !![1, 0; 0, 6] := by decide
example : (!![(1 : ℤ), 1; 3, 2]).det = -1 ∧ (!![(-1 : ℤ), 3; 1, -2]).det = -1 := by decide
example : !![(4 : ℤ), 6] * !![(-1 : ℤ), -3; 1, 2] = !![2, 0] := by decide
example : (!![(-1 : ℤ), -3; 1, 2]).det = 1 := by decide
-- What breaks: with signs dropped, ∂₂ is all 1s and its Smith diagonal is just [1].
example : !![(1 : ℤ), 0, 0; -1, 1, 0; -1, 0, 1] * !![(1 : ℤ), 1; 1, 1; 1, 1] *
    !![(1 : ℤ), -1; 0, 1] = !![1, 0; 0, 0; 0, 0] := by decide
-- Counting mod 2 (universal coefficient count): (β₀, β₁, β₂) = (1, 1, 0), t₁(2) = 1, so
-- mod-2 Betti numbers 1 + 0, 1 + 1 + 0, 0 + 0 + 1 = (1, 2, 1).
example : (1 + 0, 1 + 1 + 0, 0 + 0 + 1) = ((1 : ℕ), (2 : ℕ), (1 : ℕ)) := by norm_num

#print axioms homology_eq_free_part_plus_smith_torsion
#print axioms exists_smith_normal_form
#print axioms smith_normal_form_unique
