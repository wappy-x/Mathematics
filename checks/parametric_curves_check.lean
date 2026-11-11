-- Parametric curves: removing the turn θ from the rolling-wheel formulas x = Rθ − b sin θ, y = R − b cos θ gives x from y alone on the rising half of each arch, a second formula on the falling half, and a circle for the valve seen from the hub.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Inverse

open Real

/-- The valve of a wheel of radius `R`, sitting `b` from the hub, is at
`x = Rθ − b sin θ`, `y = R − b cos θ` after a turn of `θ` radians. On the rising half of
each arch, `0 ≤ θ ≤ π`, the turn can be removed: `x = R arccos((R − y)/b) − √(b² − (R − y)²)`. -/
theorem valve_x_from_y_rising_half (R b θ : ℝ) (hb : 0 < b) (h0 : 0 ≤ θ) (hπ : θ ≤ π) :
    R * θ - b * sin θ =
      R * arccos ((R - (R - b * cos θ)) / b) - √(b ^ 2 - (R - (R - b * cos θ)) ^ 2) := by
  have h1 : (R - (R - b * cos θ)) / b = cos θ := by
    field_simp; ring
  have h2 : b ^ 2 - (R - (R - b * cos θ)) ^ 2 = (b * sin θ) ^ 2 := by
    have := sin_sq_add_cos_sq θ
    linear_combination (-b ^ 2) * this
  have hs : 0 ≤ sin θ := sin_nonneg_of_nonneg_of_le_pi h0 hπ
  rw [h1, h2, arccos_cos h0 hπ, Real.sqrt_sq (mul_nonneg hb.le hs)]

/-- On the falling half of the first arch, `π ≤ θ ≤ 2π`, the same height needs a different
formula: `x = R(2π − arccos((R − y)/b)) + √(b² − (R − y)²)`. So no single "y gives x" rule
covers a whole turn. -/
theorem valve_x_from_y_falling_half (R b θ : ℝ) (hb : 0 < b) (hπ : π ≤ θ) (h2π : θ ≤ 2 * π) :
    R * θ - b * sin θ =
      R * (2 * π - arccos ((R - (R - b * cos θ)) / b)) + √(b ^ 2 - (R - (R - b * cos θ)) ^ 2) := by
  have h1 : (R - (R - b * cos θ)) / b = cos (2 * π - θ) := by
    rw [cos_two_pi_sub]
    field_simp; ring
  have h2 : b ^ 2 - (R - (R - b * cos θ)) ^ 2 = (b * sin (2 * π - θ)) ^ 2 := by
    have := sin_sq_add_cos_sq θ
    rw [sin_two_pi_sub]
    linear_combination (-b ^ 2) * this
  have ha : 0 ≤ 2 * π - θ := by linarith
  have hb' : 2 * π - θ ≤ π := by linarith
  have hs : 0 ≤ sin (2 * π - θ) := sin_nonneg_of_nonneg_of_le_pi ha hb'
  rw [h1, h2, arccos_cos ha hb', Real.sqrt_sq (mul_nonneg hb.le hs), sin_two_pi_sub]
  ring

/-- Seen from the hub, the valve is at `(−b sin θ, −b cos θ)`: across² + up² = b², a circle of
radius `b`, whatever the turn. -/
theorem valve_from_hub_on_circle (b θ : ℝ) :
    (-b * sin θ) ^ 2 + (-b * cos θ) ^ 2 = b ^ 2 := by
  have := sin_sq_add_cos_sq θ
  linear_combination b ^ 2 * this

#print axioms valve_x_from_y_rising_half
#print axioms valve_x_from_y_falling_half
#print axioms valve_from_hub_on_circle
