-- Perturbation theory: to first order a level moves by the nudge averaged over its old wave, a half-box step lifts every box level by exactly half its height, and a degenerate pair splits by the 2 x 2 formula.
import Mathlib.Analysis.InnerProductSpace.Symmetric
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic

open Real InnerProductSpace

/-- First order is the average of the nudge (Step 2). Let the plain energy operator `H₀`
be symmetric and let the plain problem be solved exactly: `H₀ φ = E₀ φ` with `φ` of size 1.
If the first-order terms satisfy `(H₀ - E₀) φ₁ = (E₁ - V) φ`, then the first-order shift
`E₁` is the nudge averaged over the old wave, `E₁ = ⟪φ, V φ⟫ = V_nn`. -/
theorem first_order_shift_eq_average
    {F : Type*} [NormedAddCommGroup F] [InnerProductSpace ℝ F]
    (H₀ V : F →ₗ[ℝ] F) (hH : H₀.IsSymmetric)
    (E₀ E₁ : ℝ) (φ φ₁ : F)
    (hφ : H₀ φ = E₀ • φ) (hnorm : ‖φ‖ = 1)
    (h1 : H₀ φ₁ - E₀ • φ₁ = E₁ • φ - V φ) :
    E₁ = ⟪φ, V φ⟫_ℝ := by
  have h2 : ⟪φ, H₀ φ₁ - E₀ • φ₁⟫_ℝ = ⟪φ, E₁ • φ - V φ⟫_ℝ := by rw [h1]
  rw [inner_sub_right, inner_sub_right, inner_smul_right, inner_smul_right, ← hH φ φ₁, hφ,
    inner_smul_left, real_inner_self_eq_norm_sq, hnorm] at h2
  simp at h2
  linarith

/-- The half-box step lifts every level by exactly half its height. In a box of width
`L > 0`, with level `n ≥ 1` wave `φ_n(x) = √(2/L) sin(nπx/L)` and a step of height `V₀`
over the right half `L/2 ≤ x ≤ L`, the first-order shift is
`V_nn = V₀ ∫_{L/2}^{L} φ_n(x)² dx = V₀ / 2`. -/
theorem half_box_step_first_order_shift (L V₀ : ℝ) (hL : 0 < L) (n : ℕ) (hn : 1 ≤ n) :
    V₀ * ∫ x in L / 2..L, (√(2 / L) * sin (n * π * x / L)) ^ 2 = V₀ / 2 := by
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  have hpi := Real.pi_pos
  have hk : (n : ℝ) * π ≠ 0 := by positivity
  have hLne : L ≠ 0 := hL.ne'
  have hfun : (fun x : ℝ => (√(2 / L) * sin (n * π * x / L)) ^ 2)
      = fun x => 2 / L * sin (n * π * x / L) ^ 2 := by
    funext x
    rw [mul_pow, Real.sq_sqrt (by positivity)]
  rw [hfun]
  have hderiv : ∀ x ∈ Set.uIcc (L / 2) L,
      HasDerivAt (fun x : ℝ => x / L - sin (2 * (n * π) * x / L) / (2 * (n * π)))
        (2 / L * sin (n * π * x / L) ^ 2) x := by
    intro x _
    have h1 : HasDerivAt (fun x : ℝ => 2 * (n * π) * x / L) (2 * (n * π) / L) x := by
      have := ((hasDerivAt_id x).const_mul (2 * (n * π))).div_const L
      simpa using this
    have h2 := (h1.sin).div_const (2 * (n * π))
    have h3 := ((hasDerivAt_id x).div_const L).sub h2
    convert h3 using 1
    · rfl
    have : 2 * (n * π) * x / L = 2 * (n * π * x / L) := by ring
    rw [this, Real.cos_two_mul, Real.cos_sq']
    field_simp
    ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hderiv]
  · have e1 : 2 * ((n : ℝ) * π) * L / L = (2 * n : ℕ) * π := by push_cast; field_simp
    have e2 : 2 * ((n : ℝ) * π) * (L / 2) / L = (n : ℕ) * π := by field_simp
    rw [e1, e2, Real.sin_nat_mul_pi, Real.sin_nat_mul_pi]
    field_simp
    ring
  · apply Continuous.intervalIntegrable
    fun_prop

/-- Degenerate pair (Step 4). Two levels share the plain energy `E⁰`, and the nudge's block
inside the pair is the symmetric matrix `[[V_aa, V_ab], [V_ab, V_bb]]`. The pair's energies,
the roots of `det(E⁰ I + block - E I) = 0`, are exactly
`E± = E⁰ + (V_aa + V_bb)/2 ± √(((V_aa - V_bb)/2)² + V_ab²)`. -/
theorem degenerate_pair_levels (E₀ Vaa Vbb Vab E : ℝ) :
    (!![E₀ + Vaa, Vab; Vab, E₀ + Vbb] - E • (1 : Matrix (Fin 2) (Fin 2) ℝ)).det = 0 ↔
      E = E₀ + (Vaa + Vbb) / 2 + √(((Vaa - Vbb) / 2) ^ 2 + Vab ^ 2) ∨
      E = E₀ + (Vaa + Vbb) / 2 - √(((Vaa - Vbb) / 2) ^ 2 + Vab ^ 2) := by
  have hs := Real.sq_sqrt (show (0 : ℝ) ≤ ((Vaa - Vbb) / 2) ^ 2 + Vab ^ 2 by positivity)
  set s := √(((Vaa - Vbb) / 2) ^ 2 + Vab ^ 2)
  rw [Matrix.det_fin_two]
  simp [Matrix.sub_apply, Matrix.smul_apply]
  constructor
  · intro h
    have : (E - (E₀ + (Vaa + Vbb) / 2) - s) * (E - (E₀ + (Vaa + Vbb) / 2) + s) = 0 := by
      nlinarith
    rcases mul_eq_zero.mp this with h | h
    · left; linarith
    · right; linarith
  · rintro (h | h) <;> subst h <;> nlinarith

-- The square box's twins (1,2) and (2,1) share the energy 5 E₁, since a² + b² = 5 for both.
example : (1 : ℕ) ^ 2 + 2 ^ 2 = 5 ∧ (2 : ℕ) ^ 2 + 1 ^ 2 = 5 := by decide
-- The plain gap from level 1 to level 2 is (2² - 1²) E₁ = 3 E₁.
example : (2 : ℕ) ^ 2 - 1 ^ 2 = 3 := by decide
-- Gaps grow as m²: level 4 sits 4² - 1 = 15 E₁ above level 1.
example : (4 : ℕ) ^ 2 - 1 ^ 2 = 15 := by decide

#print axioms first_order_shift_eq_average
#print axioms half_box_step_first_order_shift
#print axioms degenerate_pair_levels
