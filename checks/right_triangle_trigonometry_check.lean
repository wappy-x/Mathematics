-- Sine, cosine and tangent: in every right triangle with an acute angle A, sin A, cos A and tan A are the side ratios opposite over hypotenuse, adjacent over hypotenuse and opposite over adjacent, so each ratio depends on the angle alone, and the other acute angle swaps sine and cosine.
import Mathlib.Geometry.Euclidean.Angle.Unoriented.RightAngle
import Mathlib.Geometry.Euclidean.Triangle
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Tactic.NormNum

open EuclideanGeometry
open scoped EuclideanGeometry Real

/-- SOH-CAH-TOA. Take a right triangle with the right angle at C and an angle A strictly between
0° and 90° (here in radians: strictly between 0 and π/2). Name each side after the corner it
faces: a = BC (opposite A), b = AC (adjacent to A), c = AB (the hypotenuse). Then
sin A = a / c, cos A = b / c and tan A = a / b. -/
theorem sin_cos_tan_are_side_ratios
    {V P : Type*} [NormedAddCommGroup V] [InnerProductSpace ℝ V] [MetricSpace P]
    [NormedAddTorsor V P] {A B C : P}
    (hC : ∠ A C B = π / 2) (hA0 : 0 < ∠ B A C) (hA90 : ∠ B A C < π / 2) :
    Real.sin (∠ B A C) = dist B C / dist A B ∧
      Real.cos (∠ B A C) = dist A C / dist A B ∧
      Real.tan (∠ B A C) = dist B C / dist A C := by
  have hAC : A ≠ C := by
    rintro rfl
    simp at hA90
  have hBCA : ∠ B C A = π / 2 := by rw [angle_comm]; exact hC
  have hs := sin_angle_of_angle_eq_pi_div_two hBCA (Or.inr hAC)
  have hc := cos_angle_of_angle_eq_pi_div_two hBCA
  have ht := tan_angle_of_angle_eq_pi_div_two hBCA
  rw [angle_comm B A C, hs, hc, ht, dist_comm B A]
  exact ⟨rfl, rfl, rfl⟩

/-- One angle fixes the shape: two right triangles (right angle at C and at C', in any two
Euclidean spaces) with the same acute angle at A and A' have the same three side ratios,
whatever their sizes. So "the sine of 40°" is one number for every crane, ramp and roof. -/
theorem side_ratios_depend_on_angle_alone
    {V P : Type*} [NormedAddCommGroup V] [InnerProductSpace ℝ V] [MetricSpace P]
    [NormedAddTorsor V P]
    {V' P' : Type*} [NormedAddCommGroup V'] [InnerProductSpace ℝ V'] [MetricSpace P']
    [NormedAddTorsor V' P']
    {A B C : P} {A' B' C' : P'}
    (hC : ∠ A C B = π / 2) (hA0 : 0 < ∠ B A C) (hA90 : ∠ B A C < π / 2)
    (hC' : ∠ A' C' B' = π / 2) (hsame : ∠ B' A' C' = ∠ B A C) :
    dist B C / dist A B = dist B' C' / dist A' B' ∧
      dist A C / dist A B = dist A' C' / dist A' B' ∧
      dist B C / dist A C = dist B' C' / dist A' C' := by
  have hA0' : 0 < ∠ B' A' C' := hsame ▸ hA0
  have hA90' : ∠ B' A' C' < π / 2 := hsame ▸ hA90
  obtain ⟨s1, c1, t1⟩ := sin_cos_tan_are_side_ratios hC hA0 hA90
  obtain ⟨s2, c2, t2⟩ := sin_cos_tan_are_side_ratios hC' hA0' hA90'
  refine ⟨?_, ?_, ?_⟩
  · rw [← s1, ← s2, hsame]
  · rw [← c1, ← c2, hsame]
  · rw [← t1, ← t2, hsame]

/-- From the other corner the legs swap. In a right triangle with the right angle at C and an
acute angle A, the angle at B is the complement of A (B = 90° − A, here π/2 − A), so the sine
of B is the cosine of A and the cosine of B is the sine of A. -/
theorem other_acute_angle_swaps_sine_and_cosine
    {V P : Type*} [NormedAddCommGroup V] [InnerProductSpace ℝ V] [MetricSpace P]
    [NormedAddTorsor V P] {A B C : P}
    (hC : ∠ A C B = π / 2) (hA0 : 0 < ∠ B A C) (hA90 : ∠ B A C < π / 2) :
    ∠ A B C = π / 2 - ∠ B A C ∧
      Real.sin (∠ A B C) = Real.cos (∠ B A C) ∧
      Real.cos (∠ A B C) = Real.sin (∠ B A C) := by
  have hAC : A ≠ C := by
    rintro rfl
    simp at hA90
  have hAB : B ≠ A := by
    rintro rfl
    rw [angle_self_of_ne hAC] at hC
    exact absurd hC.symm (ne_of_gt (by positivity))
  have hsum := angle_add_angle_add_angle_eq_pi C hAB
  have hBCA : ∠ B C A = π / 2 := by rw [angle_comm]; exact hC
  have hCAB : ∠ C A B = ∠ B A C := angle_comm _ _ _
  have hB : ∠ A B C = π / 2 - ∠ B A C := by linarith
  refine ⟨hB, ?_, ?_⟩
  · rw [hB, Real.sin_pi_div_two_sub]
  · rw [hB, Real.cos_pi_div_two_sub]

-- The crane: a right angle and 40° at the pivot force 50° at the tip.
example : 180 - 90 - 40 = 50 := by decide
-- 40° and 50° are complements: they make up 90°.
example : 40 + 50 = 90 := by decide
-- Half an equilateral triangle of side 2: short side 1, hypotenuse 2, long side √3 by Pythagoras.
example : (1 : ℝ) ^ 2 + (Real.sqrt 3) ^ 2 = 2 ^ 2 := by norm_num
-- Half a square of side 1: the diagonal is √2 by Pythagoras.
example : (1 : ℝ) ^ 2 + 1 ^ 2 = (Real.sqrt 2) ^ 2 := by norm_num
-- The exact benchmark values: sin 30° = 1/2, cos 30° = √3/2, sin 45° = cos 45° = 1/√2.
example : Real.sin (π / 6) = 1 / 2 := by norm_num
example : Real.cos (π / 6) = Real.sqrt 3 / 2 := by norm_num
example : Real.sin (π / 4) = 1 / Real.sqrt 2 ∧ Real.cos (π / 4) = 1 / Real.sqrt 2 := by
  norm_num [div_eq_iff, eq_inv_mul_iff_mul_eq₀, ← sq]

#print axioms sin_cos_tan_are_side_ratios
#print axioms side_ratios_depend_on_angle_alone
#print axioms other_acute_angle_swaps_sine_and_cosine
