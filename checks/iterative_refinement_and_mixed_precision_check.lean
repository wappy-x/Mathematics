-- Iterative refinement: in exact arithmetic each refinement step multiplies the error by G = I - F⁻¹A, whose infinity-norm is at most κη/(1 - κη), so the iterates converge to the true answer whenever κη < 1/2.
import Mathlib.Analysis.Matrix.Normed
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Analysis.SpecificLimits.Basic

open Matrix Filter Topology
open scoped Matrix.Norms.Operator

variable {n : Type*} [Fintype n] [DecidableEq n]

/-- The condition number times the relative error is `‖A⁻¹‖ ‖F - A‖`. -/
lemma ir_kappa_eta (A F : Matrix n n ℝ) :
    ‖A‖ * ‖A⁻¹‖ * (‖F - A‖ / ‖A‖) = ‖A⁻¹‖ * ‖F - A‖ := by
  by_cases h : ‖A‖ = 0
  · have hA0 : A = 0 := norm_eq_zero.mp h
    simp [hA0]
  · field_simp

/-- The error recursion for one refinement step. -/
lemma ir_error_step (A F : Matrix n n ℝ) (b xs x d : n → ℝ)
    (hF : IsUnit F.det) (hxs : A *ᵥ xs = b) (hd : F *ᵥ d = b - A *ᵥ x) :
    (x + d) - xs = (1 - F⁻¹ * A) *ᵥ (x - xs) := by
  have hd' : d = F⁻¹ *ᵥ (b - A *ᵥ x) := by
    rw [← hd, mulVec_mulVec, nonsing_inv_mul F hF, one_mulVec]
  subst hxs
  rw [hd', sub_mulVec, one_mulVec, ← mulVec_mulVec, mulVec_sub, mulVec_sub, mulVec_sub]
  abel

/-- The perturbation bound, with `t = ‖A⁻¹‖ ‖F - A‖`. -/
lemma ir_norm_bound (A F : Matrix n n ℝ) (hA : IsUnit A.det)
    (ht : ‖A⁻¹‖ * ‖F - A‖ < 1) :
    IsUnit F.det ∧ ‖F⁻¹‖ ≤ ‖A⁻¹‖ / (1 - ‖A⁻¹‖ * ‖F - A‖) ∧
      ‖1 - F⁻¹ * A‖ ≤ ‖A⁻¹‖ * ‖F - A‖ / (1 - ‖A⁻¹‖ * ‖F - A‖) := by
  set t := ‖A⁻¹‖ * ‖F - A‖ with ht_def
  have hP : ‖A⁻¹ * (F - A)‖ ≤ t := linfty_opNorm_mul _ _
  have hF : IsUnit F.det := by
    rw [isUnit_iff_ne_zero]
    intro h0
    obtain ⟨v, hv, hFv⟩ := exists_mulVec_eq_zero_iff.mpr h0
    have hvv : (A⁻¹ * (F - A)) *ᵥ v = -v := by
      rw [← mulVec_mulVec, sub_mulVec, hFv, zero_sub, mulVec_neg, mulVec_mulVec,
        nonsing_inv_mul A hA, one_mulVec]
    have h1 : ‖v‖ ≤ t * ‖v‖ := by
      calc ‖v‖ = ‖(A⁻¹ * (F - A)) *ᵥ v‖ := by rw [hvv, norm_neg]
        _ ≤ ‖A⁻¹ * (F - A)‖ * ‖v‖ := linfty_opNorm_mulVec _ _
        _ ≤ t * ‖v‖ := by gcongr
    have hpos : 0 < ‖v‖ := norm_pos_iff.mpr hv
    nlinarith
  have h1t : 0 < 1 - t := by linarith
  have hid : F⁻¹ = A⁻¹ - A⁻¹ * (F - A) * F⁻¹ := by
    rw [mul_sub, sub_mul, mul_assoc, mul_nonsing_inv F hF, mul_one, nonsing_inv_mul A hA,
      one_mul]
    abel
  have hFinv : ‖F⁻¹‖ ≤ ‖A⁻¹‖ / (1 - t) := by
    rw [le_div_iff₀ h1t]
    have : ‖F⁻¹‖ ≤ ‖A⁻¹‖ + t * ‖F⁻¹‖ := by
      calc ‖F⁻¹‖ = ‖A⁻¹ - A⁻¹ * (F - A) * F⁻¹‖ := by rw [← hid]
        _ ≤ ‖A⁻¹‖ + ‖A⁻¹ * (F - A) * F⁻¹‖ := norm_sub_le _ _
        _ ≤ ‖A⁻¹‖ + ‖A⁻¹ * (F - A)‖ * ‖F⁻¹‖ := by gcongr; exact linfty_opNorm_mul _ _
        _ ≤ ‖A⁻¹‖ + t * ‖F⁻¹‖ := by gcongr
    nlinarith
  refine ⟨hF, hFinv, ?_⟩
  have hG : 1 - F⁻¹ * A = F⁻¹ * (F - A) := by
    rw [mul_sub, nonsing_inv_mul F hF]
  calc ‖1 - F⁻¹ * A‖ = ‖F⁻¹ * (F - A)‖ := by rw [hG]
    _ ≤ ‖F⁻¹‖ * ‖F - A‖ := linfty_opNorm_mul _ _
    _ ≤ ‖A⁻¹‖ / (1 - t) * ‖F - A‖ := by gcongr
    _ = t / (1 - t) := by rw [ht_def]; ring

#print axioms ir_kappa_eta
#print axioms ir_error_step
#print axioms ir_norm_bound

/-- Iterative refinement converges. Let `A` be invertible with true answer `A x* = b`, and let
`F` be the computed factors multiplied back together, `F = A + ΔA`. Measure everything in the
infinity-norm, with condition number `κ = ‖A‖ ‖A⁻¹‖` and the factor's relative error
`η = ‖F - A‖ / ‖A‖`. Run the refinement step: residual `r_k = b - A x̂_k`, correction `F d_k = r_k`,
new answer `x̂_(k+1) = x̂_k + d_k`. If `κη < 1/2`, then `q = κη / (1 - κη)` is below 1, every step
multiplies the error bound by `q`, so `‖x̂_k - x*‖ ≤ q^k ‖x̂_0 - x*‖`, and the iterates converge to
`x*` from any starting answer. -/
theorem iterative_refinement_converges
    (A F : Matrix n n ℝ) (b xs : n → ℝ) (x d : ℕ → n → ℝ)
    (hA : IsUnit A.det) (hxs : A *ᵥ xs = b)
    (hd : ∀ k, F *ᵥ d k = b - A *ᵥ x k) (hx : ∀ k, x (k + 1) = x k + d k)
    (hκη : ‖A‖ * ‖A⁻¹‖ * (‖F - A‖ / ‖A‖) < 1 / 2) :
    let κη := ‖A‖ * ‖A⁻¹‖ * (‖F - A‖ / ‖A‖)
    κη / (1 - κη) < 1 ∧
      (∀ k, ‖x k - xs‖ ≤ (κη / (1 - κη)) ^ k * ‖x 0 - xs‖) ∧
      Tendsto x atTop (𝓝 xs) := by
  intro κη
  have hk : κη = ‖A⁻¹‖ * ‖F - A‖ := ir_kappa_eta A F
  rw [ir_kappa_eta A F] at hκη
  rw [hk]
  set t := ‖A⁻¹‖ * ‖F - A‖ with ht_def
  have ht0 : 0 ≤ t := mul_nonneg (norm_nonneg _) (norm_nonneg _)
  obtain ⟨hF, -, hG⟩ := ir_norm_bound A F hA (by linarith)
  rw [← ht_def] at hG
  have h1t : 0 < 1 - t := by linarith
  have hq0 : 0 ≤ t / (1 - t) := div_nonneg ht0 h1t.le
  have hq1 : t / (1 - t) < 1 := by rw [div_lt_one h1t]; linarith
  have hbound : ∀ k, ‖x k - xs‖ ≤ (t / (1 - t)) ^ k * ‖x 0 - xs‖ := by
    intro k
    induction k with
    | zero => simp
    | succ k ih =>
      have hstep : x (k + 1) - xs = (1 - F⁻¹ * A) *ᵥ (x k - xs) := by
        rw [hx k]; exact ir_error_step A F b xs (x k) (d k) hF hxs (hd k)
      calc ‖x (k + 1) - xs‖ = ‖(1 - F⁻¹ * A) *ᵥ (x k - xs)‖ := by rw [hstep]
        _ ≤ ‖1 - F⁻¹ * A‖ * ‖x k - xs‖ := linfty_opNorm_mulVec _ _
        _ ≤ t / (1 - t) * ((t / (1 - t)) ^ k * ‖x 0 - xs‖) := by gcongr
        _ = (t / (1 - t)) ^ (k + 1) * ‖x 0 - xs‖ := by ring
  refine ⟨hq1, hbound, ?_⟩
  rw [tendsto_iff_norm_sub_tendsto_zero]
  have hlim : Tendsto (fun k => (t / (1 - t)) ^ k * ‖x 0 - xs‖) atTop (𝓝 0) := by
    simpa using (tendsto_pow_atTop_nhds_zero_of_lt_one hq0 hq1).mul_const ‖x 0 - xs‖
  exact squeeze_zero (fun k => norm_nonneg _) hbound hlim

/-- The error recursion. If the factor `F` is invertible, `A x* = b`, and one refinement step
computes the residual `r = b - A x̂`, solves `F d = r` and sets `x̂' = x̂ + d`, then in exact
arithmetic the new error is the iteration matrix `G = I - F⁻¹ A` applied to the old error:
`x̂' - x* = G (x̂ - x*)`. -/
theorem refinement_error_recursion
    (A F : Matrix n n ℝ) (b xs x d : n → ℝ)
    (hF : IsUnit F.det) (hxs : A *ᵥ xs = b) (hd : F *ᵥ d = b - A *ᵥ x) :
    (x + d) - xs = (1 - F⁻¹ * A) *ᵥ (x - xs) := by
  exact ir_error_step A F b xs x d hF hxs hd

/-- The bound on the iteration matrix. If `A` is invertible and `κη < 1`, with
`κ = ‖A‖ ‖A⁻¹‖` and `η = ‖F - A‖ / ‖A‖` in the infinity-norm, then the factor `F` is invertible,
`‖F⁻¹‖ ≤ ‖A⁻¹‖ / (1 - κη)`, and `‖I - F⁻¹ A‖ ≤ κη / (1 - κη)`. -/
theorem norm_iteration_matrix_le
    (A F : Matrix n n ℝ) (hA : IsUnit A.det)
    (hκη : ‖A‖ * ‖A⁻¹‖ * (‖F - A‖ / ‖A‖) < 1) :
    let κη := ‖A‖ * ‖A⁻¹‖ * (‖F - A‖ / ‖A‖)
    IsUnit F.det ∧ ‖F⁻¹‖ ≤ ‖A⁻¹‖ / (1 - κη) ∧ ‖1 - F⁻¹ * A‖ ≤ κη / (1 - κη) := by
  intro κη
  have hk : κη = ‖A⁻¹‖ * ‖F - A‖ := ir_kappa_eta A F
  rw [ir_kappa_eta A F] at hκη
  rw [hk]
  exact ir_norm_bound A F hA hκη

-- The network: a 16 by 16 grid of junctions has 256 unknowns and 2 × 16 × 15 = 480 grid pipes;
-- with 20 feed pipes that is 500 pipes.
example : 16 * 16 = 256 ∧ 2 * 16 * (16 - 1) = 480 ∧ 480 + 20 = 500 := by decide

-- Cost of the factor at n = 256: (4n^3 - 3n^2 - n)/6 = 11,152,000 flops, an exact division.
example : (4 * 256 ^ 3 - 3 * 256 ^ 2 - 256) / 6 = 11152000 ∧
    (4 * 256 ^ 3 - 3 * 256 ^ 2 - 256) % 6 = 0 := by norm_num

-- Cost of one step at n = 256: residual 2n^2 + solve (2n^2 - n) + update n = 4n^2 = 262,144 flops.
example : 2 * 256 ^ 2 + (2 * 256 ^ 2 - 256) + 256 = 4 * 256 ^ 2 ∧ 4 * 256 ^ 2 = 262144 := by
  norm_num

-- Four steps cost 9.40% of the factor at n = 256 and 2.40% at n = 1000 (to two decimals).
example : (9395 : ℚ) / 100000 ≤ 4 * 262144 / 11152000 ∧
    (4 * 262144 : ℚ) / 11152000 < 9405 / 100000 := by norm_num
example : (4 * 1000 ^ 3 - 3 * 1000 ^ 2 - 1000) / 6 = 666166500 ∧
    (2395 : ℚ) / 100000 ≤ 4 * (4 * 1000 ^ 2) / 666166500 ∧
    (4 * (4 * 1000 ^ 2) : ℚ) / 666166500 < 2405 / 100000 := by norm_num

#print axioms iterative_refinement_converges
#print axioms refinement_error_recursion
#print axioms norm_iteration_matrix_le
