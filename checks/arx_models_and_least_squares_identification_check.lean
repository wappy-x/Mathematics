-- ARX identification: the least-squares fit solves the normal equations and is the unique best fit when Φᵀ Φ is invertible, and the two-lag input table has eigenvalues r₀ ± r₁.
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.LinearAlgebra.Eigenspace.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Basic.Real.Basic

open Matrix

/-- The sum of squared misses of the stacked equations `Y = Φ θ + e` for a choice `θ` of the
unknowns: `∑ₖ (Yₖ - (Φ θ)ₖ)²`. -/
noncomputable def sumSqMiss {N n : ℕ} (Φ : Matrix (Fin N) (Fin n) ℝ) (Y : Fin N → ℝ)
    (θ : Fin n → ℝ) : ℝ :=
  ∑ k, (Y k - (Φ *ᵥ θ) k) ^ 2

/-- A real dot product of a vector with itself is never negative. -/
theorem real_dotProduct_self_nonneg {m : ℕ} (v : Fin m → ℝ) : 0 ≤ v ⬝ᵥ v :=
  Finset.sum_nonneg fun i _ => mul_self_nonneg (v i)

#print axioms real_dotProduct_self_nonneg

/-- A real vector whose dot product with itself is zero is the zero vector. -/
theorem real_dotProduct_self_eq_zero {m : ℕ} {v : Fin m → ℝ} (h : v ⬝ᵥ v = 0) : v = 0 := by
  have h' := (Finset.sum_eq_zero_iff_of_nonneg fun i _ => mul_self_nonneg (v i)).1 h
  funext i
  exact mul_self_eq_zero.1 (h' i (Finset.mem_univ i))

#print axioms real_dotProduct_self_eq_zero

/-- Expanding the sum of squared misses around a point `θh`. -/
theorem sumSqMiss_add {N n : ℕ} (Φ : Matrix (Fin N) (Fin n) ℝ) (Y : Fin N → ℝ)
    (θh d : Fin n → ℝ) :
    sumSqMiss Φ Y (θh + d) = sumSqMiss Φ Y θh
      - 2 * ((Φᵀ *ᵥ (Y - Φ *ᵥ θh)) ⬝ᵥ d) + (Φ *ᵥ d) ⬝ᵥ (Φ *ᵥ d) := by
  rw [mulVec_transpose, ← dotProduct_mulVec]
  unfold sumSqMiss
  simp only [mulVec_add, Pi.add_apply, dotProduct, Pi.sub_apply, Finset.mul_sum,
    ← Finset.sum_sub_distrib, ← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl fun k _ => ?_
  ring

#print axioms sumSqMiss_add

/-- The normal equations in residual form. -/
theorem normal_eq_iff_residual {N n : ℕ} (Φ : Matrix (Fin N) (Fin n) ℝ) (Y : Fin N → ℝ)
    (θh : Fin n → ℝ) :
    (Φᵀ * Φ) *ᵥ θh = Φᵀ *ᵥ Y ↔ Φᵀ *ᵥ (Y - Φ *ᵥ θh) = 0 := by
  rw [mulVec_sub, ← mulVec_mulVec, sub_eq_zero, eq_comm]

#print axioms normal_eq_iff_residual

/-- Step 1, the input moves enough: when `Φᵀ Φ` is invertible, the least-squares estimate
`θ̂ = (Φᵀ Φ)⁻¹ Φᵀ Y` misses the stacked equations least of all choices of the unknowns, and it is
the only choice that does: any `θ` other than `θ̂` has a strictly larger sum of squared misses. -/
theorem least_squares_estimate_is_unique_minimiser {N n : ℕ}
    (Φ : Matrix (Fin N) (Fin n) ℝ) (Y : Fin N → ℝ) (hexc : IsUnit (Φᵀ * Φ).det) :
    ∀ θ : Fin n → ℝ, θ ≠ (Φᵀ * Φ)⁻¹ *ᵥ (Φᵀ *ᵥ Y) →
      sumSqMiss Φ Y ((Φᵀ * Φ)⁻¹ *ᵥ (Φᵀ *ᵥ Y)) < sumSqMiss Φ Y θ := by
  intro θ hθ
  set θh := (Φᵀ * Φ)⁻¹ *ᵥ (Φᵀ *ᵥ Y) with hθh
  have hne : (Φᵀ * Φ) *ᵥ θh = Φᵀ *ᵥ Y := by
    rw [hθh, mulVec_mulVec, mul_nonsing_inv _ hexc, one_mulVec]
  have hres := (normal_eq_iff_residual Φ Y θh).1 hne
  have key := sumSqMiss_add Φ Y θh (θ - θh)
  rw [add_sub_cancel, hres, zero_dotProduct] at key
  rw [key]
  have hd : θ - θh ≠ 0 := sub_ne_zero.2 hθ
  have hΦd : Φ *ᵥ (θ - θh) ≠ 0 := by
    intro h0
    apply hd
    have : (Φᵀ * Φ) *ᵥ (θ - θh) = 0 := by rw [← mulVec_mulVec, h0, mulVec_zero]
    calc θ - θh = ((Φᵀ * Φ)⁻¹ * (Φᵀ * Φ)) *ᵥ (θ - θh) := by
          rw [nonsing_inv_mul _ hexc, one_mulVec]
      _ = 0 := by rw [← mulVec_mulVec, this, mulVec_zero]
  have hpos : 0 < (Φ *ᵥ (θ - θh)) ⬝ᵥ (Φ *ᵥ (θ - θh)) := by
    rcases (real_dotProduct_self_nonneg _).lt_or_eq with h | h
    · exact h
    · exact absurd (real_dotProduct_self_eq_zero h.symm) hΦd
  linarith

/-- The normal equations: a choice `θ̂` of the unknowns minimises the sum of squared misses
exactly when its misses `Y - Φ θ̂` are perpendicular to every column of `Φ`, that is
`Φᵀ (Y - Φ θ̂) = 0`, equivalently `Φᵀ Φ θ̂ = Φᵀ Y`. -/
theorem minimiser_iff_normal_equations {N n : ℕ}
    (Φ : Matrix (Fin N) (Fin n) ℝ) (Y : Fin N → ℝ) (θhat : Fin n → ℝ) :
    (∀ θ : Fin n → ℝ, sumSqMiss Φ Y θhat ≤ sumSqMiss Φ Y θ) ↔
      (Φᵀ * Φ) *ᵥ θhat = Φᵀ *ᵥ Y := by
  rw [normal_eq_iff_residual]
  set g := Φᵀ *ᵥ (Y - Φ *ᵥ θhat) with hg
  constructor
  · intro hmin
    by_contra hne
    have hgg : 0 < g ⬝ᵥ g := by
      rcases (real_dotProduct_self_nonneg g).lt_or_eq with h | h
      · exact h
      · exact absurd (real_dotProduct_self_eq_zero h.symm) hne
    set q := (Φ *ᵥ g) ⬝ᵥ (Φ *ᵥ g)
    have hq : 0 ≤ q := real_dotProduct_self_nonneg _
    set t := (g ⬝ᵥ g) / (q + 1)
    have ht : 0 < t := div_pos hgg (by linarith)
    have htq : t * (q + 1) = g ⬝ᵥ g := div_mul_cancel₀ _ (by linarith)
    have key := sumSqMiss_add Φ Y θhat (t • g)
    have h1 := hmin (θhat + t • g)
    rw [← hg] at key
    rw [key, mulVec_smul, dotProduct_smul, smul_dotProduct, dotProduct_smul,
      smul_eq_mul, smul_eq_mul, smul_eq_mul] at h1
    -- h1 : 0 ≤ -2 t (g⬝g) + t² q
    have : t * (t * q) ≤ t * (t * (q + 1)) := by nlinarith
    nlinarith
  · intro h0 θ
    have key := sumSqMiss_add Φ Y θhat (θ - θhat)
    rw [← hg] at key
    rw [add_sub_cancel, h0, zero_dotProduct] at key
    rw [key]
    have := real_dotProduct_self_nonneg (Φ *ᵥ (θ - θhat))
    linarith

/-- Step 3, persistent excitation of order 2: the table of input correlations for two input
lags, `[[r₀, r₁], [r₁, r₀]]`, has eigenvalues exactly `r₀ + r₁` and `r₀ - r₁`. -/
theorem input_table_eigenvalues (r₀ r₁ μ : ℝ) :
    Module.End.HasEigenvalue (Matrix.toLin' !![r₀, r₁; r₁, r₀]) μ ↔
      μ = r₀ + r₁ ∨ μ = r₀ - r₁ := by
  constructor
  · intro h
    obtain ⟨v, hv⟩ := h.exists_hasEigenvector
    have hfv := hv.apply_eq_smul
    have hv0 := hv.2
    have e0 := congrFun hfv 0
    have e1 := congrFun hfv 1
    simp [Matrix.toLin'_apply, Matrix.mulVec, dotProduct, Fin.sum_univ_two] at e0 e1
    have hor : v 0 + v 1 ≠ 0 ∨ v 0 - v 1 ≠ 0 := by
      by_contra hc
      rw [not_or, not_not, not_not] at hc
      apply hv0
      funext i
      fin_cases i <;> simp <;> linarith [hc.1, hc.2]
    rcases hor with h | h
    · left
      have : (μ - (r₀ + r₁)) * (v 0 + v 1) = 0 := by linarith
      rcases mul_eq_zero.1 this with h' | h'
      · linarith
      · exact absurd h' h
    · right
      have : (μ - (r₀ - r₁)) * (v 0 - v 1) = 0 := by linarith
      rcases mul_eq_zero.1 this with h' | h'
      · linarith
      · exact absurd h' h
  · rintro (rfl | rfl)
    · apply Module.End.hasEigenvalue_of_hasEigenvector (x := ![1, 1])
      refine ⟨Module.End.mem_eigenspace_iff.2 ?_, ?_⟩
      · funext i
        fin_cases i <;> simp [Matrix.toLin'_apply, Matrix.mulVec, dotProduct, Fin.sum_univ_two, add_comm]
      · intro h; have := congrFun h 0; simp at this
    · apply Module.End.hasEigenvalue_of_hasEigenvector (x := ![1, -1])
      refine ⟨Module.End.mem_eigenspace_iff.2 ?_, ?_⟩
      · funext i
        fin_cases i <;> simp [Matrix.toLin'_apply, Matrix.mulVec, dotProduct, Fin.sum_univ_two] <;> ring
      · intro h; have := congrFun h 0; simp at this

/-- One step of the card's 11-bit shift register (feedback from bits 10 and 8,
polynomial x¹¹ + x⁹ + 1). -/
def prbsStep (reg : ℕ) : ℕ :=
  ((reg <<< 1) ||| (((reg >>> 10) ^^^ (reg >>> 8)) &&& 1)) &&& 0x7FF

/-- Number of minutes the valve is high (register's low bit is 1) in the first `n` minutes,
starting from the register state `reg`. -/
def prbsHighCount : ℕ → ℕ → ℕ
  | 0, _ => 0
  | n + 1, reg => (reg &&& 1) + prbsHighCount n (prbsStep reg)

-- The PRBS period is 2¹¹ - 1 = 2047 minutes.
example : 2 ^ 11 - 1 = 2047 := by norm_num
-- The register returns to its starting state 0x7FF after 2047 steps.
example : prbsStep^[2047] 0x7FF = 0x7FF := by decide +kernel
-- Over the day of 1,440 minutes the valve is high 713 minutes and low 727.
example : prbsHighCount 1440 0x7FF = 713 := by decide +kernel
example : 1440 - 713 = 727 := by norm_num

#print axioms least_squares_estimate_is_unique_minimiser
#print axioms minimiser_iff_normal_equations
#print axioms input_table_eigenvalues
