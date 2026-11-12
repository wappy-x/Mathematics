-- Eigenvalues by iteration: for a symmetric matrix, power and shifted inverse iteration shrink the angle to the target mode by the gap ratio γ each step, the eigenvalue estimate is off by at most the spread times the squared shape error, and the residual bounds both errors.
import Mathlib.Analysis.Matrix.Spectrum
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Topology.Order.Real
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecificLimits.Basic

open Matrix Filter Topology

lemma eig_parseval {n : ℕ} {A : Matrix (Fin n) (Fin n) ℝ} (hA : A.IsHermitian) (y z : Fin n → ℝ) :
    y ⬝ᵥ z = ∑ j, ((⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ y) *
      ((⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ z) := by
  have h := (hA.eigenvectorBasis).sum_inner_mul_inner (WithLp.toLp 2 y) (WithLp.toLp 2 z)
  simp only [EuclideanSpace.inner_eq_star_dotProduct, star_trivial] at h
  rw [dotProduct_comm y, ← h]
  refine Finset.sum_congr rfl fun j _ => ?_
  rw [dotProduct_comm z]

lemma eig_orth {n : ℕ} {A : Matrix (Fin n) (Fin n) ℝ} (hA : A.IsHermitian) (i j : Fin n) :
    (⇑(hA.eigenvectorBasis i) : Fin n → ℝ) ⬝ᵥ (⇑(hA.eigenvectorBasis j) : Fin n → ℝ) =
      if i = j then 1 else 0 := by
  have h := orthonormal_iff_ite.mp (hA.eigenvectorBasis).orthonormal i j
  rw [EuclideanSpace.inner_eq_star_dotProduct, star_trivial, dotProduct_comm] at h
  exact h

lemma eig_mulVec {n : ℕ} {A : Matrix (Fin n) (Fin n) ℝ} (hA : A.IsHermitian) (j : Fin n)
    (y : Fin n → ℝ) :
    (⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ (A *ᵥ y) =
      hA.eigenvalues j * ((⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ y) := by
  rw [dotProduct_mulVec, ← mulVec_transpose]
  have hT : Aᵀ = A := by simpa [conjTranspose_eq_transpose_of_trivial] using hA.eq
  rw [hT, hA.mulVec_eigenvectorBasis, smul_dotProduct, smul_eq_mul]

lemma off_sq_eq {n : ℕ} (u : Fin n → Fin n → ℝ) (t : Fin n)
    (hpar : ∀ y z : Fin n → ℝ, y ⬝ᵥ z = ∑ j, (u j ⬝ᵥ y) * (u j ⬝ᵥ z))
    (hunit : u t ⬝ᵥ u t = 1) (y : Fin n → ℝ) :
    (y - (u t ⬝ᵥ y) • u t) ⬝ᵥ (y - (u t ⬝ᵥ y) • u t) =
      ∑ j ∈ Finset.univ.erase t, (u j ⬝ᵥ y) ^ 2 := by
  have h1 : (y - (u t ⬝ᵥ y) • u t) ⬝ᵥ (y - (u t ⬝ᵥ y) • u t) =
      y ⬝ᵥ y - (u t ⬝ᵥ y) ^ 2 := by
    simp only [sub_dotProduct, dotProduct_sub, smul_dotProduct, dotProduct_smul, smul_eq_mul,
      hunit, dotProduct_comm y (u t)]
    ring
  rw [h1, hpar y y, ← Finset.add_sum_erase _ _ (Finset.mem_univ t)]
  simp only [sq]
  ring

lemma sup_ratio_facts {ι : Type*} [Finite ι] (f : ι → ℝ) (h0 : ∀ i, 0 ≤ f i)
    (h1 : ∀ i, f i < 1) :
    0 ≤ ⨆ i, f i ∧ (⨆ i, f i) < 1 ∧ ∀ i, f i ≤ ⨆ i, f i := by
  refine ⟨Real.iSup_nonneg h0, ?_, fun i => le_ciSup (Finite.bddAbove_range f) i⟩
  rcases isEmpty_or_nonempty ι with hι | hι
  · rw [Real.iSup_of_isEmpty]; norm_num
  · obtain ⟨i, hi⟩ := exists_eq_ciSup_of_finite (f := f)
    rw [← hi]; exact h1 i

lemma tendsto_zero_of_le_geom (f : ℕ → ℝ) (γ C : ℝ) (h0 : ∀ k, 0 ≤ f k)
    (h : ∀ k, f k ≤ γ ^ k * C) (hγ0 : 0 ≤ γ) (hγ1 : γ < 1) :
    Tendsto f atTop (𝓝 0) := by
  have hg : Tendsto (fun k => γ ^ k * C) atTop (𝓝 0) := by
    simpa using (tendsto_pow_atTop_nhds_zero_of_lt_one hγ0 hγ1).mul_const C
  exact squeeze_zero h0 h hg

lemma e_le_tan {n : ℕ} (u : Fin n → Fin n → ℝ) (t : Fin n)
    (hpar : ∀ y z : Fin n → ℝ, y ⬝ᵥ z = ∑ j, (u j ⬝ᵥ y) * (u j ⬝ᵥ z))
    (y : Fin n → ℝ) (hy : y ⬝ᵥ y = 1) (hc : u t ⬝ᵥ y ≠ 0) (E : ℝ) (hE : 0 ≤ E) :
    E ≤ E / |u t ⬝ᵥ y| := by
  have hle : (u t ⬝ᵥ y) ^ 2 ≤ 1 := by
    rw [← hy, hpar y y, sq]
    exact Finset.single_le_sum (f := fun j => (u j ⬝ᵥ y) * (u j ⬝ᵥ y))
      (fun j _ => mul_self_nonneg _) (Finset.mem_univ t)
  have habs : |u t ⬝ᵥ y| ≤ 1 := (sq_le_one_iff_abs_le_one _).1 hle
  have hpos : 0 < |u t ⬝ᵥ y| := abs_pos.2 hc
  rw [le_div_iff₀ hpos]
  exact mul_le_of_le_one_right hE habs

lemma iter_core {n : ℕ} (u : Fin n → Fin n → ℝ) (t : Fin n) (M : Matrix (Fin n) (Fin n) ℝ)
    (ν : Fin n → ℝ) (γ : ℝ)
    (hpar : ∀ y z : Fin n → ℝ, y ⬝ᵥ z = ∑ j, (u j ⬝ᵥ y) * (u j ⬝ᵥ z))
    (hunit : u t ⬝ᵥ u t = 1)
    (hM : ∀ j y, u j ⬝ᵥ (M *ᵥ y) = ν j * (u j ⬝ᵥ y))
    (hνt : ν t ≠ 0) (hγ0 : 0 ≤ γ) (hγ : ∀ j, j ≠ t → |ν j| ≤ γ * |ν t|)
    (x : ℕ → Fin n → ℝ) (hx0 : x 0 ⬝ᵥ x 0 = 1) (hstart : u t ⬝ᵥ x 0 ≠ 0)
    (hstep : ∀ k, x (k + 1) = (Real.sqrt ((M *ᵥ x k) ⬝ᵥ (M *ᵥ x k)))⁻¹ • (M *ᵥ x k)) :
    let off : ℕ → Fin n → ℝ := fun k => x k - (u t ⬝ᵥ x k) • u t
    let e : ℕ → ℝ := fun k => Real.sqrt (off k ⬝ᵥ off k)
    let tanθ : ℕ → ℝ := fun k => e k / |u t ⬝ᵥ x k|
    (∀ k, x k ⬝ᵥ x k = 1 ∧ u t ⬝ᵥ x k ≠ 0) ∧ (∀ k, tanθ k ≤ γ ^ k * tanθ 0) ∧
      (∀ k, e k ≤ γ ^ k * tanθ 0) := by
  intro off e tanθ
  have hc : ∀ k j, u j ⬝ᵥ x (k + 1) =
      (Real.sqrt ((M *ᵥ x k) ⬝ᵥ (M *ᵥ x k)))⁻¹ * (ν j * (u j ⬝ᵥ x k)) := by
    intro k j; rw [hstep k, dotProduct_smul, smul_eq_mul, hM]
  have hpos : ∀ k, u t ⬝ᵥ x k ≠ 0 → 0 < (M *ᵥ x k) ⬝ᵥ (M *ᵥ x k) := by
    intro k hk
    have hzt : u t ⬝ᵥ (M *ᵥ x k) ≠ 0 := by rw [hM]; exact mul_ne_zero hνt hk
    rw [hpar (M *ᵥ x k) (M *ᵥ x k)]
    calc 0 < (u t ⬝ᵥ (M *ᵥ x k)) * (u t ⬝ᵥ (M *ᵥ x k)) := mul_self_pos.2 hzt
      _ ≤ ∑ j, (u j ⬝ᵥ (M *ᵥ x k)) * (u j ⬝ᵥ (M *ᵥ x k)) :=
        Finset.single_le_sum (f := fun j => (u j ⬝ᵥ (M *ᵥ x k)) * (u j ⬝ᵥ (M *ᵥ x k)))
          (fun j _ => mul_self_nonneg _) (Finset.mem_univ t)
  have hinv : ∀ k, x k ⬝ᵥ x k = 1 ∧ u t ⬝ᵥ x k ≠ 0 := by
    intro k
    induction k with
    | zero => exact ⟨hx0, hstart⟩
    | succ k ih =>
      have hzz := hpos k ih.2
      have hs : Real.sqrt ((M *ᵥ x k) ⬝ᵥ (M *ᵥ x k)) ≠ 0 := (Real.sqrt_pos.2 hzz).ne'
      have h2 := Real.mul_self_sqrt hzz.le
      refine ⟨?_, ?_⟩
      · have key : ∀ a b : ℝ, a ≠ 0 → a * a = b → a⁻¹ * (a⁻¹ * b) = 1 := by
          intro a b ha hab; rw [← hab]; field_simp
        rw [hstep k, smul_dotProduct, dotProduct_smul, smul_eq_mul, smul_eq_mul]
        exact key _ _ hs h2
      · rw [hc]
        exact mul_ne_zero (inv_ne_zero hs) (mul_ne_zero hνt ih.2)
  have hS : ∀ k, off k ⬝ᵥ off k = ∑ j ∈ Finset.univ.erase t, (u j ⬝ᵥ x k) ^ 2 :=
    fun k => off_sq_eq u t hpar hunit (x k)
  have he : ∀ k, e k = Real.sqrt (∑ j ∈ Finset.univ.erase t, (u j ⬝ᵥ x k) ^ 2) := by
    intro k; show Real.sqrt (off k ⬝ᵥ off k) = _; rw [hS]
  have he0 : ∀ k, 0 ≤ e k := fun k => Real.sqrt_nonneg _
  have htan : ∀ k, tanθ k = e k / |u t ⬝ᵥ x k| := fun k => rfl
  have hone : ∀ k, tanθ (k + 1) ≤ γ * tanθ k := by
    intro k
    have hzz := hpos k (hinv k).2
    set s := (Real.sqrt ((M *ᵥ x k) ⬝ᵥ (M *ᵥ x k)))⁻¹ with hs_def
    have hs : s ≠ 0 := inv_ne_zero (Real.sqrt_pos.2 hzz).ne'
    have hsum : ∑ j ∈ Finset.univ.erase t, (u j ⬝ᵥ x (k + 1)) ^ 2 ≤
        (s * γ * |ν t|) ^ 2 * ∑ j ∈ Finset.univ.erase t, (u j ⬝ᵥ x k) ^ 2 := by
      rw [Finset.mul_sum]
      refine Finset.sum_le_sum fun j hj => ?_
      have hjt : j ≠ t := Finset.ne_of_mem_erase hj
      have h1 : ν j ^ 2 ≤ (γ * |ν t|) ^ 2 := by
        apply sq_le_sq.2
        rw [abs_of_nonneg (mul_nonneg hγ0 (abs_nonneg _))]
        exact hγ j hjt
      rw [hc]
      calc (s * (ν j * (u j ⬝ᵥ x k))) ^ 2 = (s * (u j ⬝ᵥ x k)) ^ 2 * ν j ^ 2 := by ring
        _ ≤ (s * (u j ⬝ᵥ x k)) ^ 2 * (γ * |ν t|) ^ 2 :=
          mul_le_mul_of_nonneg_left h1 (sq_nonneg _)
        _ = (s * γ * |ν t|) ^ 2 * (u j ⬝ᵥ x k) ^ 2 := by ring
    have hek : e (k + 1) ≤ |s| * γ * |ν t| * e k := by
      rw [he, he]
      calc Real.sqrt (∑ j ∈ Finset.univ.erase t, (u j ⬝ᵥ x (k + 1)) ^ 2)
          ≤ Real.sqrt ((s * γ * |ν t|) ^ 2 * ∑ j ∈ Finset.univ.erase t, (u j ⬝ᵥ x k) ^ 2) :=
            Real.sqrt_le_sqrt hsum
        _ = abs (s * γ * |ν t|) * Real.sqrt (∑ j ∈ Finset.univ.erase t, (u j ⬝ᵥ x k) ^ 2) := by
            rw [Real.sqrt_mul (sq_nonneg _), Real.sqrt_sq_eq_abs]
        _ = |s| * γ * |ν t| * Real.sqrt (∑ j ∈ Finset.univ.erase t, (u j ⬝ᵥ x k) ^ 2) := by
            rw [abs_mul, abs_mul, abs_abs, abs_of_nonneg hγ0]
    have hct : |u t ⬝ᵥ x (k + 1)| = |s| * |ν t| * |u t ⬝ᵥ x k| := by
      rw [hc, abs_mul, abs_mul, mul_assoc]
    have hpos' : 0 < |s| * |ν t| * |u t ⬝ᵥ x k| :=
      mul_pos (mul_pos (abs_pos.2 hs) (abs_pos.2 hνt)) (abs_pos.2 (hinv k).2)
    rw [htan, htan, hct]
    calc e (k + 1) / (|s| * |ν t| * |u t ⬝ᵥ x k|)
        ≤ |s| * γ * |ν t| * e k / (|s| * |ν t| * |u t ⬝ᵥ x k|) := by gcongr
      _ = γ * (e k / |u t ⬝ᵥ x k|) := by
        have h1 : |s| ≠ 0 := (abs_pos.2 hs).ne'
        have h2 : |ν t| ≠ 0 := (abs_pos.2 hνt).ne'
        have h3 : |u t ⬝ᵥ x k| ≠ 0 := (abs_pos.2 (hinv k).2).ne'
        field_simp
  have htanK : ∀ k, tanθ k ≤ γ ^ k * tanθ 0 := by
    intro k
    induction k with
    | zero => simp
    | succ k ih =>
      calc tanθ (k + 1) ≤ γ * tanθ k := hone k
        _ ≤ γ * (γ ^ k * tanθ 0) := mul_le_mul_of_nonneg_left ih hγ0
        _ = γ ^ (k + 1) * tanθ 0 := by ring
  refine ⟨hinv, htanK, fun k => ?_⟩
  calc e k ≤ tanθ k := e_le_tan u t hpar (x k) (hinv k).1 (hinv k).2 (e k) (he0 k)
    _ ≤ γ ^ k * tanθ 0 := htanK k

/-- Step 1 of the card, power iteration. Let `A` be a real symmetric matrix with eigenvalues
`λ_j` and perpendicular unit eigenvectors `v_j` (Mathlib's `eigenvalues` and
`eigenvectorBasis`). Suppose the target eigenvalue `λ_t` is strictly the largest in size
(the gap: `|λ_j| < |λ_t|` for every other `j`), the unit start `x₀` has a share of the target
mode (`v_t · x₀ ≠ 0`), and every step multiplies by `A` and rescales to length 1. Let
`γ` be the largest `|λ_j| / |λ_t|` over `j ≠ t` (the second-largest size over the largest),
`tan θ_k` the length of the part of `x_k` off `v_t` over the size of the part along it, and
`e_k` the length of the part off `v_t` (the sine of the angle). Then for every step `k`,
`tan θ_k ≤ γ^k tan θ_0` and `e_k ≤ γ^k tan θ_0`; the Rayleigh quotient `x_kᵀ A x_k` is within
`(λ_n - λ_1) e_k²` of `λ_t`, where `λ_n - λ_1` is the largest eigenvalue minus the smallest;
and `e_k` tends to `0`. -/
theorem power_iteration_error_shrinks_by_eigenvalue_ratio {n : ℕ}
    (A : Matrix (Fin n) (Fin n) ℝ) (hA : A.IsHermitian) (t : Fin n)
    (hgap : ∀ j, j ≠ t → |hA.eigenvalues j| < |hA.eigenvalues t|)
    (x : ℕ → Fin n → ℝ) (hx0 : x 0 ⬝ᵥ x 0 = 1)
    (hstart : (⇑(hA.eigenvectorBasis t) : Fin n → ℝ) ⬝ᵥ x 0 ≠ 0)
    (hstep : ∀ k, x (k + 1) = (Real.sqrt ((A *ᵥ x k) ⬝ᵥ (A *ᵥ x k)))⁻¹ • (A *ᵥ x k)) :
    let v : Fin n → ℝ := ⇑(hA.eigenvectorBasis t)
    let γ : ℝ := ⨆ j : {j : Fin n // j ≠ t}, |hA.eigenvalues j| / |hA.eigenvalues t|
    let off : ℕ → Fin n → ℝ := fun k => x k - (v ⬝ᵥ x k) • v
    let e : ℕ → ℝ := fun k => Real.sqrt (off k ⬝ᵥ off k)
    let tanθ : ℕ → ℝ := fun k => e k / |v ⬝ᵥ x k|
    (∀ k, tanθ k ≤ γ ^ k * tanθ 0) ∧ (∀ k, e k ≤ γ ^ k * tanθ 0) ∧
    (∀ k, |x k ⬝ᵥ (A *ᵥ x k) - hA.eigenvalues t| ≤
      ((⨆ j, hA.eigenvalues j) - (⨅ j, hA.eigenvalues j)) * e k ^ 2) ∧
    Tendsto e atTop (𝓝 0) := by
  intro v γ off e tanθ
  have hpar := eig_parseval hA
  have hunit : v ⬝ᵥ v = 1 := by simpa using eig_orth hA t t
  have hD : ∀ j, |hA.eigenvalues j - hA.eigenvalues t| ≤
      (⨆ j, hA.eigenvalues j) - (⨅ j, hA.eigenvalues j) := by
    intro j
    have h1 := le_ciSup (Finite.bddAbove_range hA.eigenvalues) j
    have h2 := ciInf_le (Finite.bddBelow_range hA.eigenvalues) j
    have h3 := le_ciSup (Finite.bddAbove_range hA.eigenvalues) t
    have h4 := ciInf_le (Finite.bddBelow_range hA.eigenvalues) t
    rw [abs_le]; constructor <;> linarith
  by_cases hlam : hA.eigenvalues t = 0
  · have hall : ∀ j, j = t := by
      intro j
      by_contra h
      have := hgap j h
      rw [hlam, abs_zero] at this
      exact absurd this (not_lt.2 (abs_nonneg _))
    have hS0 : ∀ k, off k ⬝ᵥ off k = 0 := by
      intro k
      show (x k - (v ⬝ᵥ x k) • v) ⬝ᵥ (x k - (v ⬝ᵥ x k) • v) = 0
      rw [off_sq_eq (fun j => (⇑(hA.eigenvectorBasis j) : Fin n → ℝ)) t hpar hunit (x k)]
      apply Finset.sum_eq_zero
      intro j hj
      exact absurd (hall j) (Finset.ne_of_mem_erase hj)
    have he : ∀ k, e k = 0 := by
      intro k; show Real.sqrt (off k ⬝ᵥ off k) = 0; rw [hS0]; simp
    have htan : ∀ k, tanθ k = 0 := by
      intro k; show e k / |v ⬝ᵥ x k| = 0; rw [he]; simp
    refine ⟨fun k => by rw [htan, htan]; simp, fun k => by rw [he, htan]; simp, fun k => ?_, ?_⟩
    · have h0 : x k ⬝ᵥ (A *ᵥ x k) = 0 := by
        rw [hpar]
        apply Finset.sum_eq_zero
        intro j _
        rw [eig_mulVec, hall j, hlam]; ring
      rw [h0, hlam, he]; simp
    · have : e = fun _ => 0 := funext he
      rw [this]; exact tendsto_const_nhds
  · obtain ⟨hγ0, hγ1, hγle⟩ := sup_ratio_facts
      (fun j : {j : Fin n // j ≠ t} => |hA.eigenvalues j| / |hA.eigenvalues t|)
      (fun j => div_nonneg (abs_nonneg _) (abs_nonneg _))
      (fun j => (div_lt_one (abs_pos.2 hlam)).2 (hgap j.1 j.2))
    have hγ : ∀ j, j ≠ t → |hA.eigenvalues j| ≤ γ * |hA.eigenvalues t| :=
      fun j hj => (div_le_iff₀ (abs_pos.2 hlam)).1 (hγle ⟨j, hj⟩)
    obtain ⟨hinv, htan, he⟩ := iter_core (fun j => (⇑(hA.eigenvectorBasis j) : Fin n → ℝ)) t A
      hA.eigenvalues γ hpar hunit (eig_mulVec hA) hlam hγ0 hγ x hx0 hstart hstep
    refine ⟨htan, he, fun k => ?_,
      tendsto_zero_of_le_geom e γ (tanθ 0) (fun k => Real.sqrt_nonneg _) he hγ0 hγ1⟩
    have hxAx : x k ⬝ᵥ (A *ᵥ x k) = ∑ j, hA.eigenvalues j *
        ((⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ x k) ^ 2 := by
      rw [hpar]
      refine Finset.sum_congr rfl fun j _ => ?_
      rw [eig_mulVec]; ring
    have hxx : ∑ j, ((⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ x k) ^ 2 = 1 := by
      rw [← (hinv k).1, hpar (x k) (x k)]
      refine Finset.sum_congr rfl fun j _ => ?_
      ring
    have hoff := off_sq_eq (fun j => (⇑(hA.eigenvectorBasis j) : Fin n → ℝ)) t hpar hunit (x k)
    have he2 : e k ^ 2 = ∑ j ∈ Finset.univ.erase t,
        ((⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ x k) ^ 2 := by
      show Real.sqrt ((x k - (v ⬝ᵥ x k) • v) ⬝ᵥ (x k - (v ⬝ᵥ x k) • v)) ^ 2 = _
      rw [hoff, Real.sq_sqrt (Finset.sum_nonneg fun j _ => sq_nonneg _)]
    have hdiff : x k ⬝ᵥ (A *ᵥ x k) - hA.eigenvalues t = ∑ j ∈ Finset.univ.erase t,
        (hA.eigenvalues j - hA.eigenvalues t) *
          ((⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ x k) ^ 2 := by
      rw [Finset.sum_erase _ (by ring)]
      calc x k ⬝ᵥ (A *ᵥ x k) - hA.eigenvalues t
          = ∑ j, hA.eigenvalues j * ((⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ x k) ^ 2 -
            hA.eigenvalues t *
              ∑ j, ((⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ x k) ^ 2 := by
            rw [hxx, mul_one, hxAx]
        _ = _ := by
            rw [Finset.mul_sum, ← Finset.sum_sub_distrib]
            refine Finset.sum_congr rfl fun j _ => ?_
            ring
    rw [hdiff, he2, Finset.mul_sum]
    calc |∑ j ∈ Finset.univ.erase t, (hA.eigenvalues j - hA.eigenvalues t) *
          ((⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ x k) ^ 2|
        ≤ ∑ j ∈ Finset.univ.erase t, |(hA.eigenvalues j - hA.eigenvalues t) *
          ((⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ x k) ^ 2| :=
          Finset.abs_sum_le_sum_abs _ _
      _ ≤ _ := Finset.sum_le_sum fun j _ => by
          rw [abs_mul, abs_of_nonneg (sq_nonneg ((⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ x k))]
          exact mul_le_mul_of_nonneg_right (hD j) (sq_nonneg _)

/-- Step 2 of the card, shifted inverse iteration. Let `A` be a real symmetric matrix, `μ` a
shift, and suppose the target eigenvalue `λ_t` is strictly nearest `μ` (the gap:
`|λ_t - μ| < |λ_j - μ|` for every other `j`). Start from a unit vector `x₀` with a share of the
target mode, and at every step solve with `A - μI` and rescale to length 1. Let `γ` be the
largest `|λ_t - μ| / |λ_j - μ|` over `j ≠ t`, that is `|λ_t - μ| / |λ_o - μ|` with `λ_o` the
next nearest eigenvalue to `μ`. Then `tan θ_k ≤ γ^k tan θ_0` and `e_k ≤ γ^k tan θ_0` for every
step `k`, and `e_k` tends to `0`. With `μ = 0` this is inverse iteration. -/
theorem shifted_inverse_iteration_error_shrinks_by_gap_ratio {n : ℕ}
    (A : Matrix (Fin n) (Fin n) ℝ) (hA : A.IsHermitian) (μ : ℝ) (t : Fin n)
    (hgap : ∀ j, j ≠ t → |hA.eigenvalues t - μ| < |hA.eigenvalues j - μ|)
    (x : ℕ → Fin n → ℝ) (hx0 : x 0 ⬝ᵥ x 0 = 1)
    (hstart : (⇑(hA.eigenvectorBasis t) : Fin n → ℝ) ⬝ᵥ x 0 ≠ 0)
    (hstep : ∀ k, x (k + 1) =
      (Real.sqrt (((A - μ • 1)⁻¹ *ᵥ x k) ⬝ᵥ ((A - μ • 1)⁻¹ *ᵥ x k)))⁻¹ •
        ((A - μ • 1)⁻¹ *ᵥ x k)) :
    let v : Fin n → ℝ := ⇑(hA.eigenvectorBasis t)
    let γ : ℝ := ⨆ j : {j : Fin n // j ≠ t}, |hA.eigenvalues t - μ| / |hA.eigenvalues j - μ|
    let off : ℕ → Fin n → ℝ := fun k => x k - (v ⬝ᵥ x k) • v
    let e : ℕ → ℝ := fun k => Real.sqrt (off k ⬝ᵥ off k)
    let tanθ : ℕ → ℝ := fun k => e k / |v ⬝ᵥ x k|
    (∀ k, tanθ k ≤ γ ^ k * tanθ 0) ∧ (∀ k, e k ≤ γ ^ k * tanθ 0) ∧
    Tendsto e atTop (𝓝 0) := by
  intro v γ off e tanθ
  have hpar := eig_parseval hA
  have hunit : v ⬝ᵥ v = 1 := by simpa using eig_orth hA t t
  obtain ⟨hγ0, hγ1, hγle⟩ := sup_ratio_facts
    (fun j : {j : Fin n // j ≠ t} => |hA.eigenvalues t - μ| / |hA.eigenvalues j - μ|)
    (fun j => div_nonneg (abs_nonneg _) (abs_nonneg _))
    (fun j => (div_lt_one (lt_of_le_of_lt (abs_nonneg _) (hgap j.1 j.2))).2 (hgap j.1 j.2))
  suffices h : (∀ k, tanθ k ≤ γ ^ k * tanθ 0) ∧ (∀ k, e k ≤ γ ^ k * tanθ 0) from
    ⟨h.1, h.2, tendsto_zero_of_le_geom e γ (tanθ 0) (fun k => Real.sqrt_nonneg _) h.2 hγ0 hγ1⟩
  by_cases hdet : IsUnit (A - μ • (1 : Matrix (Fin n) (Fin n) ℝ)).det
  · have hsolve : ∀ j y, (⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ ((A - μ • 1)⁻¹ *ᵥ y) *
        (hA.eigenvalues j - μ) = (⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ y := by
      intro j y
      have hy : (A - μ • 1) *ᵥ ((A - μ • 1)⁻¹ *ᵥ y) = y := by
        rw [mulVec_mulVec, mul_nonsing_inv _ hdet, one_mulVec]
      conv_rhs => rw [← hy]
      rw [sub_mulVec, dotProduct_sub, eig_mulVec, smul_mulVec, one_mulVec, dotProduct_smul,
        smul_eq_mul]
      ring
    have hne : ∀ j, hA.eigenvalues j - μ ≠ 0 := by
      intro j h
      have := hsolve j (⇑(hA.eigenvectorBasis j))
      rw [h, mul_zero, eig_orth] at this
      simp at this
    have hM : ∀ j y, (⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ ((A - μ • 1)⁻¹ *ᵥ y) =
        (hA.eigenvalues j - μ)⁻¹ * ((⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ y) := by
      intro j y
      rw [← hsolve j y]
      field_simp [hne j]
    have hγ : ∀ j, j ≠ t → |(hA.eigenvalues j - μ)⁻¹| ≤ γ * |(hA.eigenvalues t - μ)⁻¹| := by
      intro j hj
      have h := hγle ⟨j, hj⟩
      have ha : 0 < |hA.eigenvalues t - μ| := abs_pos.2 (hne t)
      have hb : 0 < |hA.eigenvalues j - μ| := abs_pos.2 (hne j)
      rw [abs_inv, abs_inv]
      calc |hA.eigenvalues j - μ|⁻¹
          = |hA.eigenvalues t - μ| / |hA.eigenvalues j - μ| * |hA.eigenvalues t - μ|⁻¹ := by
            field_simp
        _ ≤ γ * |hA.eigenvalues t - μ|⁻¹ := mul_le_mul_of_nonneg_right h (inv_nonneg.2 ha.le)
    obtain ⟨_, htan, he⟩ := iter_core (fun j => (⇑(hA.eigenvectorBasis j) : Fin n → ℝ)) t
      (A - μ • 1)⁻¹ (fun j => (hA.eigenvalues j - μ)⁻¹) γ hpar hunit hM (inv_ne_zero (hne t))
      hγ0 hγ x hx0 hstart hstep
    exact ⟨htan, he⟩
  · have hB : (A - μ • (1 : Matrix (Fin n) (Fin n) ℝ))⁻¹ = 0 :=
      nonsing_inv_apply_not_isUnit _ hdet
    have hx : ∀ k, x (k + 1) = 0 := by
      intro k; rw [hstep, hB]; simp
    have he : ∀ k, e (k + 1) = 0 := by
      intro k
      show Real.sqrt ((x (k + 1) - (v ⬝ᵥ x (k + 1)) • v) ⬝ᵥ (x (k + 1) - (v ⬝ᵥ x (k + 1)) • v)) = 0
      rw [hx]; simp
    have htan : ∀ k, tanθ (k + 1) = 0 := by
      intro k; show e (k + 1) / |v ⬝ᵥ x (k + 1)| = 0; rw [he]; simp
    have hnn : 0 ≤ tanθ 0 := div_nonneg (Real.sqrt_nonneg _) (abs_nonneg _)
    have he0 : e 0 ≤ tanθ 0 :=
      e_le_tan (fun j => (⇑(hA.eigenvectorBasis j) : Fin n → ℝ)) t hpar (x 0) hx0 hstart (e 0)
        (Real.sqrt_nonneg _)
    refine ⟨fun k => ?_, fun k => ?_⟩
    · cases k with
      | zero => simp
      | succ k => rw [htan]; positivity
    · cases k with
      | zero => simpa using he0
      | succ k => rw [he]; positivity

/-- Step 3 of the card, stopping on the residual. Let `A` be a real symmetric matrix, `x` a
unit vector, `λ̂ = xᵀ A x` its Rayleigh quotient and `r = A x - λ̂ x` its residual. Then some
eigenvalue lies within `‖r‖` of `λ̂`. And for a target mode `v_t`, if the gap (the distance
from `λ̂` to the nearest eigenvalue `λ_j` with `j ≠ t`) is positive, the shape error
`e = ‖x - (v_t · x) v_t‖` is at most `‖r‖` divided by the gap. -/
theorem residual_bounds_eigenvalue_and_shape_error {n : ℕ}
    (A : Matrix (Fin n) (Fin n) ℝ) (hA : A.IsHermitian)
    (x : Fin n → ℝ) (hx : x ⬝ᵥ x = 1) :
    let lhat : ℝ := x ⬝ᵥ (A *ᵥ x)
    let r : Fin n → ℝ := A *ᵥ x - lhat • x
    (∃ j, |hA.eigenvalues j - lhat| ≤ Real.sqrt (r ⬝ᵥ r)) ∧
    ∀ t : Fin n,
      let v : Fin n → ℝ := ⇑(hA.eigenvectorBasis t)
      let gap : ℝ := ⨅ j : {j : Fin n // j ≠ t}, |hA.eigenvalues j - lhat|
      0 < gap →
        Real.sqrt ((x - (v ⬝ᵥ x) • v) ⬝ᵥ (x - (v ⬝ᵥ x) • v)) ≤ Real.sqrt (r ⬝ᵥ r) / gap := by
  intro lhat r
  have hpar := eig_parseval hA
  have hr : ∀ j, (⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ r =
      (hA.eigenvalues j - lhat) * ((⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ x) := by
    intro j
    show (⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ (A *ᵥ x - lhat • x) = _
    rw [dotProduct_sub, eig_mulVec, dotProduct_smul, smul_eq_mul]
    ring
  have hrr : r ⬝ᵥ r = ∑ j, (hA.eigenvalues j - lhat) ^ 2 *
      ((⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ x) ^ 2 := by
    rw [hpar]
    refine Finset.sum_congr rfl fun j _ => ?_
    rw [hr]; ring
  have hxx : ∑ j, ((⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ x) ^ 2 = 1 := by
    rw [← hx, hpar x x]
    refine Finset.sum_congr rfl fun j _ => ?_
    ring
  constructor
  · have hne : Nonempty (Fin n) := by
      rcases Nat.eq_zero_or_pos n with hn | hn
      · subst hn; simp [dotProduct] at hx
      · exact ⟨⟨0, hn⟩⟩
    obtain ⟨j0, -, hj0⟩ := Finset.exists_min_image Finset.univ
      (fun j => |hA.eigenvalues j - lhat|) Finset.univ_nonempty
    refine ⟨j0, Real.abs_le_sqrt ?_⟩
    rw [hrr]
    calc (hA.eigenvalues j0 - lhat) ^ 2
        = ∑ j, (hA.eigenvalues j0 - lhat) ^ 2 *
            ((⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ x) ^ 2 := by
          rw [← Finset.mul_sum, hxx, mul_one]
      _ ≤ _ := Finset.sum_le_sum fun j _ =>
          mul_le_mul_of_nonneg_right (sq_le_sq.2 (hj0 j (Finset.mem_univ j))) (sq_nonneg _)
  · intro t v gap hgap
    have hunit : v ⬝ᵥ v = 1 := by simpa using eig_orth hA t t
    have hgle : ∀ j, j ≠ t → gap ≤ |hA.eigenvalues j - lhat| :=
      fun j hj => ciInf_le (Finite.bddBelow_range _) (⟨j, hj⟩ : {j : Fin n // j ≠ t})
    have hoff := off_sq_eq (fun j => (⇑(hA.eigenvectorBasis j) : Fin n → ℝ)) t hpar hunit x
    show Real.sqrt ((x - (v ⬝ᵥ x) • v) ⬝ᵥ (x - (v ⬝ᵥ x) • v)) ≤ Real.sqrt (r ⬝ᵥ r) / gap
    rw [hoff, le_div_iff₀ hgap]
    have hS : (∑ j ∈ Finset.univ.erase t, ((⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ x) ^ 2) *
        gap ^ 2 ≤ r ⬝ᵥ r := by
      rw [hrr, Finset.sum_mul]
      calc ∑ j ∈ Finset.univ.erase t, ((⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ x) ^ 2 * gap ^ 2
          ≤ ∑ j ∈ Finset.univ.erase t, (hA.eigenvalues j - lhat) ^ 2 *
              ((⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ x) ^ 2 :=
            Finset.sum_le_sum fun j hj => by
              have h1 := hgle j (Finset.ne_of_mem_erase hj)
              have h2 : gap ^ 2 ≤ (hA.eigenvalues j - lhat) ^ 2 := by
                apply sq_le_sq.2
                rw [abs_of_pos hgap]
                exact h1
              rw [mul_comm]
              exact mul_le_mul_of_nonneg_right h2 (sq_nonneg _)
        _ ≤ _ := Finset.sum_le_sum_of_subset_of_nonneg (Finset.erase_subset _ _)
            (fun j _ _ => mul_nonneg (sq_nonneg _) (sq_nonneg _))
    calc Real.sqrt (∑ j ∈ Finset.univ.erase t, ((⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ x) ^ 2)
          * gap
        = Real.sqrt ((∑ j ∈ Finset.univ.erase t,
            ((⇑(hA.eigenvectorBasis j) : Fin n → ℝ) ⬝ᵥ x) ^ 2) * gap ^ 2) := by
          rw [Real.sqrt_mul' _ (sq_nonneg _), Real.sqrt_sq hgap.le]
      _ ≤ Real.sqrt (r ⬝ᵥ r) := Real.sqrt_le_sqrt hS

/-- The frame's matrix `A = K / s`, five storeys, the top floor's diagonal entry 1. -/
def frameA : Matrix (Fin 5) (Fin 5) ℤ :=
  !![2, -1, 0, 0, 0; -1, 2, -1, 0, 0; 0, -1, 2, -1, 0; 0, 0, -1, 2, -1; 0, 0, 0, -1, 1]

-- The card's hand computation: the inverse of `A` has entry `(i, j)` equal to the smaller of `i`
-- and `j` (counting from 1).
example : frameA * (Matrix.of fun i j : Fin 5 => (min i.val j.val + 1 : ℤ)) = 1 := by decide

-- Solve `A y = (1, 1, 1, 1, 1)`: `y = (5, 9, 12, 14, 15)`; then `A z = y`: `z = (55, 105, 146, 175, 190)`.
example : frameA *ᵥ ![5, 9, 12, 14, 15] = ![1, 1, 1, 1, 1] := by decide
example : frameA *ᵥ ![55, 105, 146, 175, 190] = ![5, 9, 12, 14, 15] := by decide

-- The Rayleigh quotients 55 / 671 and 8272 / 102091.
example : (![5, 9, 12, 14, 15] : Fin 5 → ℤ) ⬝ᵥ ![1, 1, 1, 1, 1] = 55 ∧
    (![5, 9, 12, 14, 15] : Fin 5 → ℤ) ⬝ᵥ ![5, 9, 12, 14, 15] = 671 := by decide
example : (![55, 105, 146, 175, 190] : Fin 5 → ℤ) ⬝ᵥ ![5, 9, 12, 14, 15] = 8272 ∧
    (![55, 105, 146, 175, 190] : Fin 5 → ℤ) ⬝ᵥ ![55, 105, 146, 175, 190] = 102091 := by decide

-- The start's Rayleigh quotient: the sum of all entries of `A` is 1, so `λ̂_0 = 1/5`.
example : (![1, 1, 1, 1, 1] : Fin 5 → ℤ) ⬝ᵥ (frameA *ᵥ ![1, 1, 1, 1, 1]) = 1 := by decide

-- The two free checks: the trace is 9 and the determinant is 1.
example : frameA.trace = 9 := by decide
example : frameA.det = 1 := by
  simp [frameA, Matrix.det_succ_row_zero, Fin.sum_univ_succ, Fin.succAbove]

#print axioms power_iteration_error_shrinks_by_eigenvalue_ratio
#print axioms shifted_inverse_iteration_error_shrinks_by_gap_ratio
#print axioms residual_bounds_eigenvalue_and_shape_error
#print axioms eig_parseval
#print axioms eig_orth
#print axioms eig_mulVec
#print axioms off_sq_eq
#print axioms sup_ratio_facts
#print axioms tendsto_zero_of_le_geom
#print axioms e_le_tan
#print axioms iter_core
