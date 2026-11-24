-- BiCGSTAB: the smoothing step never lengthens the residual, biorthogonal shadow vectors give a three-term recurrence, and on the shift ring GMRES stalls while BiCGSTAB breaks down.
import Mathlib.LinearAlgebra.Matrix.Permutation
import Mathlib.LinearAlgebra.Span.Basic
import Mathlib.Logic.Equiv.Fin.Rotate
import Mathlib.LinearAlgebra.Matrix.DotProduct
import Mathlib.LinearAlgebra.FiniteDimensional.Basic
import Mathlib.LinearAlgebra.Dimension.Constructions

open Matrix

theorem dotProduct_self_nonneg_real {n : ℕ} (v : Fin n → ℝ) : 0 ≤ v ⬝ᵥ v :=
  Finset.sum_nonneg fun i _ => mul_self_nonneg (v i)

#print axioms dotProduct_self_nonneg_real

theorem krylov_span_mono {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (v : Fin n → ℝ) {a b : ℕ}
    (hab : a ≤ b) :
    Submodule.span ℝ (Set.range fun m : Fin a => (A ^ (m : ℕ)) *ᵥ v) ≤
      Submodule.span ℝ (Set.range fun m : Fin b => (A ^ (m : ℕ)) *ᵥ v) := by
  apply Submodule.span_mono
  rintro _ ⟨m, rfl⟩
  exact ⟨⟨m, by omega⟩, rfl⟩

#print axioms krylov_span_mono

theorem krylov_span_step {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (v x : Fin n → ℝ) {a : ℕ}
    (hx : x ∈ Submodule.span ℝ (Set.range fun m : Fin a => (A ^ (m : ℕ)) *ᵥ v)) :
    A *ᵥ x ∈ Submodule.span ℝ (Set.range fun m : Fin (a + 1) => (A ^ (m : ℕ)) *ᵥ v) := by
  induction hx using Submodule.span_induction with
  | mem y hy =>
    obtain ⟨m, rfl⟩ := hy
    apply Submodule.subset_span
    refine ⟨⟨m + 1, by omega⟩, ?_⟩
    simp only [mulVec_mulVec, pow_succ']
  | zero => simp
  | add y z _ _ hy hz => rw [mulVec_add]; exact add_mem hy hz
  | smul c y _ hy => rw [mulVec_smul]; exact Submodule.smul_mem _ c hy

#print axioms krylov_span_step

open Fin.NatCast in
theorem finRotate_pow_apply (n' m : ℕ) (i : Fin (n' + 1)) :
    ((finRotate (n' + 1)) ^ m) i = i + (m : Fin (n' + 1)) := by
  induction m with
  | zero => simp
  | succ m ih =>
    rw [pow_succ', Equiv.Perm.mul_apply, ih, finRotate_apply, Nat.cast_succ, add_assoc]

#print axioms finRotate_pow_apply

open Fin.NatCast in
theorem shift_ring_succ (n' : ℕ) :
    let Z : Matrix (Fin (n' + 1)) (Fin (n' + 1)) ℝ := ((finRotate (n' + 1))⁻¹).permMatrix ℝ
    let e₁ : Fin (n' + 1) → ℝ := Pi.single 0 1
    (Zᵀ * Z = 1 ∧ Z * Zᵀ = 1) ∧
    (∀ k < n' + 1, ∀ u ∈ Submodule.span ℝ (Set.range fun m : Fin k => (Z ^ (m : ℕ)) *ᵥ e₁),
      1 ≤ (e₁ - Z *ᵥ u) ⬝ᵥ (e₁ - Z *ᵥ u)) ∧
    (∃ u ∈ Submodule.span ℝ (Set.range fun m : Fin (n' + 1) => (Z ^ (m : ℕ)) *ᵥ e₁),
      Z *ᵥ u = e₁) ∧
    (2 ≤ n' + 1 → e₁ ⬝ᵥ (Z *ᵥ e₁) = 0) := by
  intro Z e₁
  set σ : Equiv.Perm (Fin (n' + 1)) := (finRotate (n' + 1))⁻¹ with hσ
  have hZv : ∀ v : Fin (n' + 1) → ℝ, Z *ᵥ v = v ∘ σ := fun v => permMatrix_mulVec σ
  have hpow : ∀ m : ℕ, Z ^ m = (σ ^ m).permMatrix ℝ := by
    intro m
    induction m with
    | zero => simp
    | succ m ih => rw [pow_succ', ih, pow_succ, Matrix.permMatrix_mul]
  have hσ0 : σ 0 = Fin.last n' := by
    rw [hσ, Equiv.Perm.inv_eq_iff_eq, finRotate_last]
  have hσpow : ∀ (m : ℕ) (j : Fin (n' + 1)), (σ ^ m) j = 0 ↔ j = (m : Fin (n' + 1)) := by
    intro m j
    rw [hσ, inv_pow, Equiv.Perm.inv_eq_iff_eq, finRotate_pow_apply, zero_add]
  have hZpow : ∀ m : ℕ, Z ^ m *ᵥ e₁ = Pi.single (m : Fin (n' + 1)) 1 := by
    intro m
    funext j
    rw [hpow, permMatrix_mulVec]
    simp only [Function.comp_apply, e₁, Pi.single_apply, hσpow]
  refine ⟨⟨?_, ?_⟩, ?_, ?_, ?_⟩
  · rw [transpose_permMatrix, ← Matrix.permMatrix_mul, mul_inv_cancel, Matrix.permMatrix_one]
  · rw [transpose_permMatrix, ← Matrix.permMatrix_mul, inv_mul_cancel, Matrix.permMatrix_one]
  · intro k hk u hu
    have hu0 : u (Fin.last n') = 0 := by
      induction hu using Submodule.span_induction with
      | mem y hy =>
        obtain ⟨m, rfl⟩ := hy
        simp only
        rw [hZpow, Pi.single_apply, ite_eq_right_iff]
        intro h
        have := congrArg Fin.val h
        rw [Fin.val_last, Fin.val_natCast, Nat.mod_eq_of_lt (by omega)] at this
        omega
      | zero => simp
      | add y z _ _ hy hz => simp [hy, hz]
      | smul c y _ hy => simp [hy]
    have h0 : (e₁ - Z *ᵥ u) 0 = 1 := by
      rw [Pi.sub_apply, hZv, Function.comp_apply, hσ0, hu0]
      simp [e₁]
    have := Finset.single_le_sum (f := fun i => (e₁ - Z *ᵥ u) i * (e₁ - Z *ᵥ u) i)
      (fun i _ => mul_self_nonneg _) (Finset.mem_univ 0)
    simp only [h0, mul_one] at this
    exact this
  · refine ⟨Z ^ n' *ᵥ e₁, Submodule.subset_span ⟨Fin.last n', rfl⟩, ?_⟩
    rw [mulVec_mulVec, ← pow_succ', hZpow, Fin.natCast_self]
  · intro h2
    rw [single_dotProduct, hZv, Function.comp_apply, hσ0, one_mul]
    simp only [e₁]
    rw [Pi.single_apply, ite_eq_right_iff]
    intro h
    have := congrArg Fin.val h
    simp at this
    omega

#print axioms shift_ring_succ

/-- BiCGSTAB's smoothing step (Step 4). Let `h` be the half-step residual and
`ω = (B h · h) / (B h · B h)`. Then the new residual `h - ω B h` is at right angles to `B h`,
its squared length is the lowest of all `h - c B h`, and so it is never longer than the half
step itself (take `c = 0`). -/
theorem bicgstab_smoothing_never_raises_residual {n : ℕ}
    (B : Matrix (Fin n) (Fin n) ℝ) (h : Fin n → ℝ) :
    let w := B *ᵥ h
    let ω := (w ⬝ᵥ h) / (w ⬝ᵥ w)
    w ⬝ᵥ (h - ω • w) = 0 ∧
    (∀ c : ℝ, (h - ω • w) ⬝ᵥ (h - ω • w) ≤ (h - c • w) ⬝ᵥ (h - c • w)) ∧
    (h - ω • w) ⬝ᵥ (h - ω • w) ≤ h ⬝ᵥ h := by
  intro w ω
  have key : ∀ c : ℝ, (h - c • w) ⬝ᵥ (h - c • w) =
      h ⬝ᵥ h - 2 * c * (w ⬝ᵥ h) + c ^ 2 * (w ⬝ᵥ w) := by
    intro c
    simp only [sub_dotProduct, dotProduct_sub, smul_dotProduct, dotProduct_smul, smul_eq_mul,
      dotProduct_comm h w]
    ring
  have hmin : ∀ c : ℝ, (h - ω • w) ⬝ᵥ (h - ω • w) ≤ (h - c • w) ⬝ᵥ (h - c • w) := by
    intro c
    by_cases hw : w ⬝ᵥ w = 0
    · have hw0 : w = 0 := dotProduct_self_eq_zero.mp hw
      simp [hw0]
    · have hpos : 0 < w ⬝ᵥ w := lt_of_le_of_ne (dotProduct_self_nonneg_real w) (Ne.symm hw)
      have : (h - c • w) ⬝ᵥ (h - c • w) - (h - ω • w) ⬝ᵥ (h - ω • w) =
          (c - ω) ^ 2 * (w ⬝ᵥ w) := by
        rw [key, key]
        simp only [ω]
        field_simp
        ring
      nlinarith [sq_nonneg (c - ω)]
  refine ⟨?_, hmin, ?_⟩
  · by_cases hw : w ⬝ᵥ w = 0
    · have hw0 : w = 0 := dotProduct_self_eq_zero.mp hw
      simp [hw0]
    · simp only [dotProduct_sub, dotProduct_smul, smul_eq_mul, ω]
      field_simp
      ring
  · simpa using hmin 0

/-- Biorthogonality makes the recurrence short (Step 1). Suppose each shadow residual
`r̃ᵢ` lies in the Krylov space `𝒦ᵢ₊₁(Bᵀ, r̃₀)`, the shadow residuals and residuals satisfy
`r̃ᵢ · rⱼ = 0` for `i ≠ j` up to step `k`, and there is no breakdown (`r̃ᵢ · rᵢ ≠ 0`).
Then `B rₖ` has no part along any `rᵢ` older than `rₖ₋₁`: `r̃ᵢ · B rₖ = 0` whenever `i + 1 < k`. -/
theorem biorthogonal_residuals_three_term_recurrence {n : ℕ}
    (B : Matrix (Fin n) (Fin n) ℝ) (r rt : ℕ → Fin n → ℝ) (k : ℕ)
    (hrt : ∀ i ≤ k, rt i ∈ Submodule.span ℝ
      (Set.range fun m : Fin (i + 1) => (Bᵀ ^ (m : ℕ)) *ᵥ rt 0))
    (hbi : ∀ i ≤ k, ∀ j ≤ k, i ≠ j → rt i ⬝ᵥ r j = 0)
    (hnb : ∀ i ≤ k, rt i ⬝ᵥ r i ≠ 0) :
    ∀ i, i + 1 < k → rt i ⬝ᵥ (B *ᵥ r k) = 0 := by
  intro i hik
  have hle : ∀ j ≤ k, Submodule.span ℝ (Set.range fun l : Fin (j + 1) => rt l) ≤
      Submodule.span ℝ (Set.range fun m : Fin (j + 1) => (Bᵀ ^ (m : ℕ)) *ᵥ rt 0) := by
    intro j hj
    rw [Submodule.span_le]
    rintro _ ⟨l, rfl⟩
    exact krylov_span_mono Bᵀ (rt 0) (by omega : (l : ℕ) + 1 ≤ j + 1) (hrt l (by omega))
  have hli : ∀ j ≤ k, LinearIndependent ℝ (fun l : Fin (j + 1) => rt l) := by
    intro j hj
    rw [linearIndependent_iff']
    intro s g hg l hl
    have h1 := congrArg (· ⬝ᵥ r l) hg
    simp only [sum_dotProduct, smul_dotProduct, zero_dotProduct, smul_eq_mul] at h1
    rw [Finset.sum_eq_single l] at h1
    · exact (mul_eq_zero.mp h1).resolve_right (hnb l (by omega))
    · intro b _ hb
      rw [hbi b (by omega) l (by omega) (fun h => hb (Fin.ext h)), mul_zero]
    · intro h; exact absurd hl h
  have heq : ∀ j ≤ k, Submodule.span ℝ (Set.range fun l : Fin (j + 1) => rt l) =
      Submodule.span ℝ (Set.range fun m : Fin (j + 1) => (Bᵀ ^ (m : ℕ)) *ᵥ rt 0) := by
    intro j hj
    apply Submodule.eq_of_le_of_finrank_le (hle j hj)
    rw [finrank_span_eq_card (hli j hj)]
    exact finrank_range_le_card _
  rw [dotProduct_mulVec, ← mulVec_transpose]
  have hmem : Bᵀ *ᵥ rt i ∈ Submodule.span ℝ (Set.range fun l : Fin (i + 1 + 1) => rt l) := by
    rw [heq (i + 1) (by omega)]
    exact krylov_span_step Bᵀ (rt 0) (rt i) (hrt i (by omega))
  have hall : ∀ v ∈ Submodule.span ℝ (Set.range fun l : Fin (i + 1 + 1) => rt l),
      v ⬝ᵥ r k = 0 := by
    intro v hv
    induction hv using Submodule.span_induction with
    | mem y hy =>
      obtain ⟨l, rfl⟩ := hy
      exact hbi l (by omega) k le_rfl (by omega)
    | zero => simp
    | add y z _ _ hy hz => rw [add_dotProduct, hy, hz, add_zero]
    | smul c y _ hy => rw [smul_dotProduct, hy, smul_zero]
  exact hall _ hmem

/-- The shift ring (Step 7). `Z` moves entry `i` to place `i + 1` around a ring of `n` places
and `e₁` is 1 in the first place. `Z` is normal (`ZᵀZ = ZZᵀ = 1`). Every answer `u` from a
Krylov space `𝒦ₖ(Z, e₁)` with `k < n` leaves a residual `e₁ - Z u` of squared length at
least 1 (so full GMRES is stuck at 1 until step `n`, and GMRES(m) with `m < n` never moves);
at `k = n` some `u` solves `Z u = e₁` exactly; and when `n ≥ 2` the first BiCG/BiCGSTAB
divisor `e₁ · Z e₁` is 0, a breakdown at step 1. -/
theorem shift_ring_gmres_stalls_and_bicgstab_breaks_down (n : ℕ) [NeZero n] :
    let Z : Matrix (Fin n) (Fin n) ℝ := ((finRotate n)⁻¹).permMatrix ℝ
    let e₁ : Fin n → ℝ := Pi.single 0 1
    (Zᵀ * Z = 1 ∧ Z * Zᵀ = 1) ∧
    (∀ k < n, ∀ u ∈ Submodule.span ℝ (Set.range fun m : Fin k => (Z ^ (m : ℕ)) *ᵥ e₁),
      1 ≤ (e₁ - Z *ᵥ u) ⬝ᵥ (e₁ - Z *ᵥ u)) ∧
    (∃ u ∈ Submodule.span ℝ (Set.range fun m : Fin n => (Z ^ (m : ℕ)) *ᵥ e₁), Z *ᵥ u = e₁) ∧
    (2 ≤ n → e₁ ⬝ᵥ (Z *ᵥ e₁) = 0) := by
  obtain ⟨n', rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, (Nat.succ_pred_eq_of_pos (NeZero.pos n)).symm⟩
  exact shift_ring_succ n'

-- The card's 8-link ring: eight shifts bring every entry home, and `e₁ · Z e₁ = 0`.
example : (finRotate 8) ^ 8 = 1 := by decide
example : (Pi.single (0 : Fin 8) (1 : ℤ)) ⬝ᵥ
    ((((finRotate 8)⁻¹).permMatrix ℤ) *ᵥ Pi.single (0 : Fin 8) 1) = 0 := by decide

-- Memory counts: one vector of 50,000 doubles; GMRES's 21-vector basis; BiCGSTAB's 8 vectors;
-- GMRES's 23 vectors after 20 steps; rush hour's 80 vectors; GMRES(5)'s 9 vectors.
example : 50000 * 8 = 400000 := by norm_num
example : 21 * 400000 = 8400000 := by norm_num
example : 8 * 400000 = 3200000 := by norm_num
example : (20 + 3) * 400000 = 9200000 := by norm_num
example : (77 + 3) * 400000 = 32000000 := by norm_num
example : (5 + 4) * 400000 = 3600000 := by norm_num

#print axioms bicgstab_smoothing_never_raises_residual
#print axioms biorthogonal_residuals_three_term_recurrence
#print axioms shift_ring_gmres_stalls_and_bicgstab_breaks_down
