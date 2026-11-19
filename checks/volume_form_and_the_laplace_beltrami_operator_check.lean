-- Volume form and Laplace-Beltrami: the volume form √(det g) gives the same true size in every chart, the dome panel's area is 2πR²(1 − cos φ₀), and the Laplace-Beltrami operator sends the height z = R cos φ to −2z/R².
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open Matrix Real

/-- The volume form does not depend on the chart. If a regular chart has metric matrix `g`
(so `det g > 0`) and a change of coordinates has Jacobian matrix `J`, the new chart's metric is
`Jᵀ g J`, and its root-determinant is `|det J|` times the old one. Since the box itself changes
by `|det J|`, the true size `√(det g) dx` of a small coordinate box is the same in both charts. -/
theorem volume_form_sqrt_det_chart_invariant {n : ℕ} (g J : Matrix (Fin n) (Fin n) ℝ)
    (hg : 0 < g.det) :
    Real.sqrt (Jᵀ * g * J).det = |J.det| * Real.sqrt g.det := by
  rw [det_mul, det_mul, det_transpose,
    show J.det * g.det * J.det = J.det ^ 2 * g.det by ring,
    Real.sqrt_mul (sq_nonneg _), Real.sqrt_sq_eq_abs]

/-- The dome panel's area from the volume form `dA = R² sin φ dφ dθ`: a cap of a sphere of
radius `R` reaching the angle `φ₀` down from the top has area `2πR²(1 − cos φ₀)`. -/
theorem cap_area_from_volume_form (R φ₀ : ℝ) :
    (∫ _θ in (0 : ℝ)..(2 * π), ∫ φ in (0 : ℝ)..φ₀, R ^ 2 * Real.sin φ)
      = 2 * π * R ^ 2 * (1 - Real.cos φ₀) := by
  rw [intervalIntegral.integral_const_mul, integral_sin, intervalIntegral.integral_const,
    Real.cos_zero, smul_eq_mul]
  ring

/-- The Laplace-Beltrami operator `Δ_g f = (1/√(det g)) ∂_i(√(det g) g^{ij} ∂_j f)` of the height
`z = R cos φ` on the sphere of radius `R`, in the chart `(φ, θ)` with metric
`g = diag(R², R² sin² φ)`, is `−2z/R²` wherever the chart is regular (`det g > 0`). -/
theorem laplace_beltrami_height_on_sphere (R φ θ : ℝ)
    (hdet : 0 < R ^ 2 * (R ^ 2 * Real.sin φ ^ 2)) :
    let z : ℝ → ℝ → ℝ := fun p _t => R * Real.cos p
    let s : ℝ → ℝ := fun p => Real.sqrt (R ^ 2 * (R ^ 2 * Real.sin p ^ 2))
    (1 / s φ) * (deriv (fun p => s p * (1 / R ^ 2) * deriv (fun q => z q θ) p) φ
        + deriv (fun t => s φ * (1 / (R ^ 2 * Real.sin φ ^ 2)) * deriv (fun t' => z φ t') t) θ)
      = -2 * z φ θ / R ^ 2 := by
  intro z s
  have hz : deriv (fun q => z q θ) = fun p => -(R * Real.sin p) := by
    funext p
    simp only [z]
    rw [deriv_const_mul _ (Real.differentiableAt_cos), Real.deriv_cos]
    ring
  have hz2 : ∀ t, deriv (fun t' => z φ t') t = 0 := fun t => by simp [z]
  simp only [hz, hz2, mul_zero, deriv_const', add_zero]
  have hR : R ≠ 0 := by
    rintro rfl; simp at hdet
  have hsin : Real.sin φ ≠ 0 := by
    rintro h; rw [h] at hdet; simp at hdet
  have hh : HasDerivAt (fun p => R ^ 2 * (R ^ 2 * Real.sin p ^ 2))
      (R ^ 2 * (R ^ 2 * (2 * Real.sin φ * Real.cos φ))) φ := by
    have := ((Real.hasDerivAt_sin φ).pow 2).const_mul (R ^ 2) |>.const_mul (R ^ 2)
    convert this using 1
    push_cast; ring
  have hs : HasDerivAt s (R ^ 2 * (R ^ 2 * (2 * Real.sin φ * Real.cos φ)) /
      (2 * Real.sqrt (R ^ 2 * (R ^ 2 * Real.sin φ ^ 2)))) φ := hh.sqrt hdet.ne'
  have hf : HasDerivAt (fun p => s p * (1 / R ^ 2) * -(R * Real.sin p))
      (R ^ 2 * (R ^ 2 * (2 * Real.sin φ * Real.cos φ)) /
        (2 * Real.sqrt (R ^ 2 * (R ^ 2 * Real.sin φ ^ 2))) * (1 / R ^ 2) * -(R * Real.sin φ)
        + s φ * (1 / R ^ 2) * -(R * Real.cos φ)) φ :=
    (hs.mul_const (1 / R ^ 2)).mul ((Real.hasDerivAt_sin φ).const_mul R).neg
  rw [hf.deriv]
  have hsq : Real.sqrt (R ^ 2 * (R ^ 2 * Real.sin φ ^ 2)) ^ 2 = R ^ 2 * (R ^ 2 * Real.sin φ ^ 2) :=
    Real.sq_sqrt hdet.le
  have hpos : 0 < Real.sqrt (R ^ 2 * (R ^ 2 * Real.sin φ ^ 2)) := Real.sqrt_pos.mpr hdet
  simp only [s, z]
  field_simp
  rw [show R ^ 4 * Real.sin φ ^ 2 = R ^ 2 * (R ^ 2 * Real.sin φ ^ 2) by ring, hsq]
  ring

/-- The mesh with `n = 8` rings (1, 6, 12, ..., 48 points) has 217 points. -/
example : 1 + ∑ k ∈ Finset.range 8, 6 * (k + 1) = 217 := by decide

/-- The mesh with `n = 16` rings has 817 points. -/
example : 1 + ∑ k ∈ Finset.range 16, 6 * (k + 1) = 817 := by decide

/-- At the panel's edge, `φ₀ = 60°`: `1 − cos φ₀ = 1/2`, so the area is `2π · 1² · 1/2 = π`. -/
example : 2 * π * (1 : ℝ) ^ 2 * (1 - Real.cos (π / 3)) = π := by
  rw [Real.cos_pi_div_three]; ring

#print axioms volume_form_sqrt_det_chart_invariant
#print axioms cap_area_from_volume_form
#print axioms laplace_beltrami_height_on_sphere
