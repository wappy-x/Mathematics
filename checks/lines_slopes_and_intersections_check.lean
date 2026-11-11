-- Lines: on square axes two lines cross at a right angle exactly when their slopes multiply to -1, two lines with a nonzero crossing number meet at the one point the crossing formula gives, and lines with equal slopes and different intercepts never meet.
import Mathlib.Geometry.Euclidean.Angle.Unoriented.Affine
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Tactic.NormNum

open EuclideanGeometry Real

-- Points of the plane are `!₂[x, y]` in `EuclideanSpace ℝ (Fin 2)`: axes at right angles with
-- the same unit both ways. `∠ U J W` is the angle at J between the rays J→U and J→W, in
-- radians; a right angle is π / 2.

/-- The perpendicular test. On axes at right angles with the same unit both ways, let the lines
y = m₁x + k₁ and y = m₂x + k₂ both pass through the point J = (x₀, y₀). Step 1 unit east along
each line from J, to U on the first line and W on the second. The lines cross square (the angle
U J W is a right angle) exactly when their slopes multiply to -1. -/
theorem perpendicular_iff_slopes_mul_eq_neg_one (m₁ k₁ m₂ k₂ x₀ y₀ : ℝ)
    (h₁ : y₀ = m₁ * x₀ + k₁) (h₂ : y₀ = m₂ * x₀ + k₂) :
    ∠ (!₂[x₀ + 1, m₁ * (x₀ + 1) + k₁]) (!₂[x₀, y₀]) (!₂[x₀ + 1, m₂ * (x₀ + 1) + k₂]) = π / 2 ↔
      m₁ * m₂ = -1 := by
  rw [EuclideanGeometry.angle, ← InnerProductGeometry.inner_eq_zero_iff_angle_eq_pi_div_two]
  simp [EuclideanSpace.inner_eq_star_dotProduct, Fin.sum_univ_two, dotProduct]
  have e₁ : m₁ * (x₀ + 1) + k₁ - y₀ = m₁ := by linarith
  have e₂ : m₂ * (x₀ + 1) + k₂ - y₀ = m₂ := by linarith
  rw [e₁, e₂]
  constructor <;> intro h <;> linarith [mul_comm m₁ m₂]

/-- Where two lines meet. For the lines ax + by = p and cx + dy = q with a nonzero crossing
number ad - bc, a point (x, y) lies on both lines exactly when
x = (pd - bq)/(ad - bc) and y = (aq - cp)/(ad - bc): the lines meet at exactly one point. -/
theorem lines_meet_at_crossing_formula (a b p c d q : ℝ) (h : a * d - b * c ≠ 0) (x y : ℝ) :
    (a * x + b * y = p ∧ c * x + d * y = q) ↔
      (x = (p * d - b * q) / (a * d - b * c) ∧ y = (a * q - c * p) / (a * d - b * c)) := by
  have hx : ∀ x y : ℝ, (a * x + b * y = p ∧ c * x + d * y = q) →
      (x = (p * d - b * q) / (a * d - b * c) ∧ y = (a * q - c * p) / (a * d - b * c)) := by
    rintro x y ⟨e1, e2⟩
    constructor
    · rw [eq_div_iff h]; rw [← e1, ← e2]; ring
    · rw [eq_div_iff h]; rw [← e1, ← e2]; ring
  constructor
  · exact hx x y
  · rintro ⟨rfl, rfl⟩
    constructor
    · rw [mul_div_assoc', mul_div_assoc', ← add_div, div_eq_iff h]; ring
    · rw [mul_div_assoc', mul_div_assoc', ← add_div, div_eq_iff h]; ring

/-- The parallel test. Two lines y = mx + k₁ and y = mx + k₂ with the same slope m and
different north-axis crossings k₁ ≠ k₂ never meet. -/
theorem equal_slopes_different_intercepts_never_meet (m k₁ k₂ : ℝ) (hk : k₁ ≠ k₂) :
    ¬ ∃ x y : ℝ, y = m * x + k₁ ∧ y = m * x + k₂ := by
  rintro ⟨x, y, e1, e2⟩
  exact hk (by linarith)

-- The card's worked numbers, as exact fractions (the card's 0.5 is 1/2).
-- Slope of route A, D (0, 0) to E (10, 5): 5/10 = 1/2.
example : ((5 : ℚ) - 0) / (10 - 0) = 1 / 2 := by norm_num
-- Slope of route B, Q (3, 9) to R (7, 1): -8/4 = -2.
example : ((1 : ℚ) - 9) / (7 - 3) = -2 := by norm_num
-- Route B's north-axis crossing: 9 - (-2)(3) = 15.
example : (9 : ℤ) - (-2) * 3 = 15 := by decide
-- Slopes from the general forms, -a/b: route A x - 2y = 0 gives 1/2, route B 2x + y = 15 gives -2.
example : -(1 : ℚ) / (-2) = 1 / 2 ∧ -(2 : ℚ) / 1 = -2 := by norm_num
-- Crossing number of A with B: 1 × 1 - (-2) × 2 = 5; of A with ring road C (x - 2y = -10): 0.
example : (1 : ℤ) * 1 - (-2) * 2 = 5 := by decide
example : (1 : ℤ) * (-2) - (-2) * 1 = 0 := by decide
-- The junction: x = (0 × 1 - (-2) × 15)/5 = 6 and y = (1 × 15 - 2 × 0)/5 = 3.
example : ((0 : ℚ) * 1 - (-2) * 15) / 5 = 6 ∧ ((1 : ℚ) * 15 - 2 * 0) / 5 = 3 := by norm_num
-- J = (6, 3) lies on both routes: 6 - 2 × 3 = 0 and 2 × 6 + 3 = 15.
example : (6 : ℤ) - 2 * 3 = 0 ∧ (2 : ℤ) * 6 + 3 = 15 := by decide
-- Square: slope product (1/2)(-2) = -1.
example : (1 / 2 : ℚ) * (-2) = -1 := by norm_num
-- Pythagoras in triangle D, J, Q: DJ² = 45, JQ² = 45, DQ² = 90, and 45 + 45 = 90.
example : (6 : ℤ) ^ 2 + 3 ^ 2 = 45 ∧ ((3 : ℤ) - 6) ^ 2 + (9 - 3) ^ 2 = 45 ∧
    (3 : ℤ) ^ 2 + 9 ^ 2 = 90 ∧ (45 : ℤ) + 45 = 90 := by decide
-- Step dot product (10, 5)·(4, -8) = 0.
example : (10 : ℤ) * 4 + 5 * (-8) = 0 := by decide
-- Route A, (10t, 5t), put into route B: 2(10t) + 5t = 25t = 15 at t = 3/5 (60% of the way).
example : 2 * (10 * (3 / 5 : ℚ)) + 5 * (3 / 5) = 15 := by norm_num
-- On route B, (3, 9) + s(4, -8) reaches (6, 3) at s = 3/4.
example : (3 : ℚ) + (3 / 4) * 4 = 6 ∧ (9 : ℚ) + (3 / 4) * (-8) = 3 := by norm_num
-- Ring road y = x/2 + 5 is 5 above route A at x = 0, 4, 8.
example : ((0 : ℚ) / 2 + 5) - 0 / 2 = 5 ∧ ((4 : ℚ) / 2 + 5) - 4 / 2 = 5 ∧
    ((8 : ℚ) / 2 + 5) - 8 / 2 = 5 := by norm_num
-- Ring road C meets route B at (4, 7): 4 - 2 × 7 = -10 and 2 × 4 + 7 = 15; there s = 1/4.
example : (4 : ℤ) - 2 * 7 = -10 ∧ (2 : ℤ) * 4 + 7 = 15 := by decide
example : (3 : ℚ) + (1 / 4) * 4 = 4 ∧ (9 : ℚ) + (1 / 4) * (-8) = 7 := by norm_num
-- The street x = 2 (1x + 0y = 2) meets route A at (2, 1); crossing number 1 × 0 - (-2) × 1 = 2.
example : (1 : ℤ) * 0 - (-2) * 1 = 2 ∧ (2 : ℤ) - 2 * 1 = 0 := by decide
-- Mistake 2: perpendicular to B taken as 1/m gives slope -1/2 and step dot product
-- (1, -2)·(1, -1/2) = 2, not 0.
example : (1 : ℚ) / (-2) = -1 / 2 ∧ (1 : ℚ) * 1 + (-2) * (-1 / 2) = 2 := by norm_num

#print axioms perpendicular_iff_slopes_mul_eq_neg_one
#print axioms lines_meet_at_crossing_formula
#print axioms equal_slopes_different_intercepts_never_meet
