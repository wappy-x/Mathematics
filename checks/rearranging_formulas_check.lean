-- Rearranging a formula: when a is not zero, F = a C + b and C = (F - b) / a say exactly the same thing, so Fahrenheit and Celsius convert both ways, and a circle's area gives back its radius as a square root because a radius cannot be negative.
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Tactic.NormNum

/-- A formula is one relationship between its letters, and rearranging it picks which letter it
hands back. If `F = a * C + b`, with a multiplier `a` that is not zero (so the multiplying has an
undo), then taking `b` off both sides and dividing both sides by `a`, in that reverse order, makes
`C` the subject: `C = (F - b) / a`. The two formulas hold for exactly the same pairs of numbers. -/
theorem rearranged_formula_same_relationship (a b F C : ℝ) (ha : a ≠ 0) :
    F = a * C + b ↔ C = (F - b) / a := by
  constructor
  · intro h
    rw [h]
    field_simp
    ring
  · intro h
    rw [h]
    field_simp
    ring

/-- The card's own formula. `F = 1.8 C + 32` turns Celsius into Fahrenheit, and rearranged,
`C = (F - 32) / 1.8` turns Fahrenheit back into Celsius. Both are true for exactly the same
temperatures. -/
theorem celsius_from_fahrenheit (F C : ℝ) :
    F = 1.8 * C + 32 ↔ C = (F - 32) / 1.8 := by
  exact rearranged_formula_same_relationship 1.8 32 F C (by norm_num)

/-- A square is undone by a square root, but only for a letter that cannot be negative.
If a circle of radius `r` has area `A = π r²`, and `r` is a length (so `r ≥ 0`), then making the
radius the subject gives `r = √(A / π)`. -/
theorem radius_from_area (A r : ℝ) (hr : 0 ≤ r) (hA : A = Real.pi * r ^ 2) :
    r = Real.sqrt (A / Real.pi) := by
  have hpi : Real.pi ≠ 0 := Real.pi_ne_zero
  have h : A / Real.pi = r ^ 2 := by
    rw [hA]
    field_simp
  rw [h, Real.sqrt_sq hr]

-- The card's 1.8 is exact: it is 9/5, so the examples below use 9/5.
example : (1.8 : ℚ) = 9 / 5 := by norm_num
-- Forwards: 1.8 × 25 = 45, then 45 + 32 = 77.
example : (9 / 5 : ℚ) * 25 = 45 := by norm_num
example : (45 : ℚ) + 32 = 77 := by norm_num
-- Backwards: 77 − 32 = 45, then 45 / 1.8 = 25.
example : (77 : ℚ) - 32 = 45 := by norm_num
example : (45 : ℚ) / (9 / 5) = 25 := by norm_num
-- The table and the plotted line: 0, 5, 10, 15, 20, 25 degrees C are 32, 41, 50, 59, 68, 77
-- degrees F, and the rearranged formula brings each one back.
example : ([0, 5, 10, 15, 20, 25] : List ℚ).map (fun c => 9 / 5 * c + 32)
    = [32, 41, 50, 59, 68, 77] := by norm_num
example : ([32, 41, 50, 59, 68, 77] : List ℚ).map (fun f => (f - 32) / (9 / 5))
    = [0, 5, 10, 15, 20, 25] := by norm_num
-- The taxi: 5 miles costs 3 + 2 × 5 = 13, and rearranged, a 13 dollar fare is (13 − 3) / 2 = 5 miles.
example : (3 : ℕ) + 2 * 5 = 13 := by decide
example : ((13 : ℚ) - 3) / 2 = 5 := by norm_num
-- Undoing in the wrong order (divide first, then take off 32) does not give 25.
example : (77 : ℚ) / (9 / 5) - 32 ≠ 25 := by norm_num
-- Forgetting the flagfall: 13 / 2 is not 5 miles.
example : (13 : ℚ) / 2 ≠ 5 := by norm_num

#print axioms rearranged_formula_same_relationship
#print axioms celsius_from_fahrenheit
#print axioms radius_from_area
