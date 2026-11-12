-- Pythagoras: in a flat triangle ABC the angle at C is a right angle exactly when BC^2 + CA^2 = AB^2.
import Mathlib.Geometry.Euclidean.Angle.Unoriented.RightAngle
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open EuclideanGeometry Real

/-- Pythagoras and its converse, in the flat plane. Take corners A, B, C, with legs
a = BC and b = CA meeting at C and the side c = AB opposite C. If the angle at C is a
right angle, then a^2 + b^2 = c^2; and if three lengths of a triangle obey
a^2 + b^2 = c^2, the angle at C, between a and b, is a right angle. -/
theorem pythagoras_and_its_converse (A B C : EuclideanSpace ℝ (Fin 2)) :
    ∠ B C A = π / 2 ↔ dist B C ^ 2 + dist C A ^ 2 = dist A B ^ 2 := by
  have h := EuclideanGeometry.dist_sq_eq_dist_sq_add_dist_sq_iff_angle_eq_pi_div_two B C A
  rw [← h, dist_comm B A, dist_comm A C]
  constructor <;> intro h <;> nlinarith [h]

/-- The formula turned into a length: with the right angle at C, the hypotenuse is the
positive square root of the leg squares added, c = √(a^2 + b^2). -/
theorem hypotenuse_eq_sqrt_sum_of_leg_squares (A B C : EuclideanSpace ℝ (Fin 2))
    (h : ∠ B C A = π / 2) :
    dist A B = √(dist B C ^ 2 + dist C A ^ 2) := by
  rw [(pythagoras_and_its_converse A B C).1 h]
  exact (Real.sqrt_sq dist_nonneg).symm

/-- The dissection count of Step 3: a square of side a + b, less four corner triangles
of area ab/2 each, leaves a^2 + b^2. -/
theorem dissection_area_count (a b : ℝ) :
    (a + b) ^ 2 - 4 * (a * b / 2) = a ^ 2 + b ^ 2 := by
  ring

-- The truss: rafters 3 m and 4 m give 9 + 16 = 25, and the tie beam is the root of 25, 5 m.
example : 3 ^ 2 + 4 ^ 2 = 5 ^ 2 := by norm_num
example : √((3 : ℝ) ^ 2 + 4 ^ 2) = 5 := by
  rw [show (3 : ℝ) ^ 2 + 4 ^ 2 = 5 ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)
-- The dissection: outer square 7 x 7 = 49, four triangles 4 x (3 x 4 / 2) = 24, middle 25.
example : 7 * 7 = 49 ∧ 4 * (3 * 4 / 2) = 24 ∧ 49 - 24 = 25 := by decide
-- The missing rafter: span 5 m and rafter 3 m leave 25 - 9 = 16 = 4^2.
example : 5 ^ 2 - 3 ^ 2 = 4 ^ 2 := by decide
-- The symmetric truss: 9 + 9 = 18, and 18 has no whole-number root.
example : 3 ^ 2 + 3 ^ 2 = 18 ∧ ¬ IsSquare (18 : ℕ) := by decide +kernel
-- Try changing: rafters 6 and 8 span 10; rafters 5 and 12 span 13.
example : 6 ^ 2 + 8 ^ 2 = 10 ^ 2 := by decide
example : 5 ^ 2 + 12 ^ 2 = 13 ^ 2 := by decide
-- Mistakes: adding the rafters gives 7, not 5; lengths 3, 5, 4 in that order leave residual 18.
example : 3 + 4 = 7 ∧ (3 + 4) ^ 2 ≠ 3 ^ 2 + 4 ^ 2 := by decide
example : (3 : ℤ) ^ 2 + 5 ^ 2 - 4 ^ 2 = 18 := by decide

#print axioms pythagoras_and_its_converse
#print axioms hypotenuse_eq_sqrt_sum_of_leg_squares
#print axioms dissection_area_count
