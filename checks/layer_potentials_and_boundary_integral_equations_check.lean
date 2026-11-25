-- Layer potentials: on the unit circle the double-layer kernel and its adjoint are the constant -1/(4π), inside the circle the kernel splits into -1/(4π) plus a multiple of the Poisson kernel, and the interior Dirichlet rim equation with data cos θ has exactly one continuous solution, μ = -2 cos θ.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open Real RealInnerProductSpace

/-- On the unit circle the double-layer kernel is one constant. For two different points
`x` and `y` on the unit circle, with outward normals `n_y = y` and `n_x = x`, the kernel
`∂Φ(x - y)/∂n_y = (x - y)·n_y / (2π |x - y|²)` and its adjoint
`(y - x)·n_x / (2π |x - y|²)` both equal `-1/(4π)`. -/
theorem double_layer_kernel_const_on_unit_circle (x y : EuclideanSpace ℝ (Fin 2))
    (hx : ‖x‖ = 1) (hy : ‖y‖ = 1) (hxy : x ≠ y) :
    ⟪x - y, y⟫ / (2 * π * ‖x - y‖ ^ 2) = -1 / (4 * π) ∧
      ⟪y - x, x⟫ / (2 * π * ‖x - y‖ ^ 2) = -1 / (4 * π) := by
  have hD : ‖x - y‖ ^ 2 = ‖x‖ ^ 2 - 2 * ⟪x, y⟫ + ‖y‖ ^ 2 := norm_sub_sq_real x y
  have hne : ‖x - y‖ ^ 2 ≠ 0 := by
    have : ‖x - y‖ ≠ 0 := by rwa [norm_ne_zero_iff, sub_ne_zero]
    positivity
  have h1 : ⟪x - y, y⟫ = ⟪x, y⟫ - ‖y‖ ^ 2 := by
    rw [inner_sub_left, real_inner_self_eq_norm_sq]
  have h2 : ⟪y - x, x⟫ = ⟪x, y⟫ - ‖x‖ ^ 2 := by
    rw [inner_sub_left, real_inner_self_eq_norm_sq, real_inner_comm]
  have hpi : π ≠ 0 := pi_ne_zero
  rw [hx] at hD h2
  rw [hy] at hD h1
  constructor
  · rw [div_eq_div_iff (by positivity) (by positivity), h1]
    rw [hD]; ring
  · rw [div_eq_div_iff (by positivity) (by positivity), h2]
    rw [hD]; ring

/-- Inside the unit circle the double-layer kernel splits into the rim constant plus a
Poisson-kernel term: for a rim point `y` and a point `x` inside the circle,
`(x - y)·y / |x - y|² = -1/2 - (1 - |x|²) / (2 |x - y|²)`. -/
theorem double_layer_kernel_inside_unit_circle (x y : EuclideanSpace ℝ (Fin 2))
    (hx : ‖x‖ < 1) (hy : ‖y‖ = 1) :
    ⟪x - y, y⟫ / ‖x - y‖ ^ 2 = -1 / 2 - (1 - ‖x‖ ^ 2) / (2 * ‖x - y‖ ^ 2) := by
  have hD : ‖x - y‖ ^ 2 = ‖x‖ ^ 2 - 2 * ⟪x, y⟫ + ‖y‖ ^ 2 := norm_sub_sq_real x y
  have hxy : x ≠ y := by
    rintro rfl; linarith
  have hne : ‖x - y‖ ^ 2 ≠ 0 := by
    have : ‖x - y‖ ≠ 0 := by rwa [norm_ne_zero_iff, sub_ne_zero]
    positivity
  have h1 : ⟪x - y, y⟫ = ⟪x, y⟫ - ‖y‖ ^ 2 := by
    rw [inner_sub_left, real_inner_self_eq_norm_sq]
  rw [hy] at hD h1
  rw [h1]
  generalize ‖x - y‖ ^ 2 = D at hD hne ⊢
  field_simp
  linear_combination (1 : ℝ) * hD

/-- The interior Dirichlet equation on the unit circle, `-½ μ + K μ = g` with the constant
kernel `-1/(4π)` and rim temperature `g = cos θ`, has exactly one continuous solution:
the density `μ = -2 cos θ`. -/
theorem circle_interior_dirichlet_unique_solution (μ : ℝ → ℝ) (hμ : Continuous μ) :
    (∀ t, -(1 / 2) * μ t + ∫ s in (0 : ℝ)..2 * π, (-1 / (4 * π)) * μ s = cos t) ↔
      ∀ t, μ t = -2 * cos t := by
  clear hμ
  have hpi : π ≠ 0 := pi_ne_zero
  constructor
  · intro h
    set c := ∫ s in (0 : ℝ)..2 * π, (-1 / (4 * π)) * μ s with hc
    have hμeq : ∀ t, μ t = 2 * c - 2 * cos t := by
      intro t; have := h t; linarith
    have hfun : μ = fun t => 2 * c - 2 * cos t := funext hμeq
    have hint : c = -c := by
      conv_lhs => rw [hc, hfun]
      rw [intervalIntegral.integral_const_mul, intervalIntegral.integral_sub,
        intervalIntegral.integral_const, intervalIntegral.integral_const_mul, integral_cos]
      · simp only [sin_two_pi, sin_zero, smul_eq_mul]
        field_simp
        ring
      · exact intervalIntegrable_const
      · exact (continuous_const.mul continuous_cos).intervalIntegrable _ _
    have hc0 : c = 0 := by linarith
    intro t; rw [hμeq t, hc0]; ring
  · intro h t
    have hfun : μ = fun t => -2 * cos t := funext h
    rw [hfun, intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul,
      integral_cos]
    simp

/-- The card's flow numbers, with stream speed 1 m/s: the speed over the top at twice the
bar's radius is `U (1 + 1/r²)` with `r = 2`, which is 5/4 m/s (1.250 m/s). -/
example : (1 : ℚ) * (1 + 1 / 2 ^ 2) = 5 / 4 := by norm_num

/-- The speed in front of the bar at `r = 2` is `U (1 - 1/r²)`, which is 3/4 m/s (0.750 m/s). -/
example : (1 : ℚ) * (1 - 1 / 2 ^ 2) = 3 / 4 := by norm_num

/-- The Reynolds number `2 a U / ν` with `a = 25/1000` m, `U = 1` m/s and `ν = 1/10⁶` m²/s
is 50000. -/
example : (2 : ℚ) * (25 / 1000) * 1 / (1 / 10 ^ 6) = 50000 := by norm_num

/-- The temperature `r cos θ` at `r = 1/2`, `θ = 0` is 1/2 K (0.500 K). -/
example : (1 / 2 : ℝ) * cos 0 = 1 / 2 := by simp

#print axioms double_layer_kernel_const_on_unit_circle
#print axioms double_layer_kernel_inside_unit_circle
#print axioms circle_interior_dirichlet_unique_solution
