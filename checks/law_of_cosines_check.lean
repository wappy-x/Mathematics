-- Law of cosines: in a flat plane, the square of the side facing an angle equals the sum of the squares of the two sides that form it, minus twice their product times the angle's cosine.
import Mathlib.Geometry.Euclidean.Triangle
import Mathlib.Analysis.InnerProductSpace.PiL2

open EuclideanGeometry

/-- The law of cosines. For any three points A, B, C on a flat plane, with sides
a = CB and b = CA meeting at the corner C and c = AB the side facing C:
c² = a² + b² − 2ab cos C. At a right angle the cosine is 0 and Pythagoras is left. -/
theorem law_of_cosines (A B C : EuclideanSpace ℝ (Fin 2)) :
    dist A B ^ 2 = dist C B ^ 2 + dist C A ^ 2
      - 2 * dist C B * dist C A * Real.cos (∠ A C B) := by
  have h := dist_sq_eq_dist_sq_add_dist_sq_sub_two_mul_dist_mul_dist_mul_cos_angle A C B
  rw [dist_comm A C, dist_comm B C] at h
  nlinarith [h]

/-- Three sides that close. For positive lengths a, b, c, the cosine the rearranged law asks for,
(a² + b² − c²) / (2ab), lies strictly between −1 and 1 exactly when each side is shorter than
the other two together. -/
theorem law_of_cosines_sss_range (a b c : ℝ) (ha : 0 < a) (hb : 0 < b) (hc : 0 < c) :
    (-1 < (a ^ 2 + b ^ 2 - c ^ 2) / (2 * a * b) ∧ (a ^ 2 + b ^ 2 - c ^ 2) / (2 * a * b) < 1) ↔
      (a < b + c ∧ b < a + c ∧ c < a + b) := by
  have h2 : 0 < 2 * a * b := by positivity
  rw [lt_div_iff₀ h2, div_lt_iff₀ h2]
  constructor
  · rintro ⟨h1, h3⟩
    refine ⟨?_, ?_, ?_⟩
    · nlinarith [sq_nonneg (a - b - c), sq_nonneg (a - b + c)]
    · nlinarith [sq_nonneg (b - a - c), sq_nonneg (b - a + c)]
    · nlinarith [sq_nonneg (c - a - b), sq_nonneg (c + a + b)]
  · rintro ⟨h1, h3, h4⟩
    constructor
    · nlinarith [mul_pos (by linarith : 0 < a + b - c) (by linarith : 0 < a + b + c)]
    · nlinarith [mul_pos (by linarith : 0 < c - a + b) (by linarith : 0 < c + a - b)]

/-- The arrow route. With u the arrow from C to A and v the arrow from C to B, the dot product
u · v equals |u| |v| cos C, the two lengths times the cosine of the angle between them. -/
theorem dot_product_eq_mul_cos_angle (A B C : EuclideanSpace ℝ (Fin 2)) :
    inner ℝ (A - C) (B - C) = dist C A * dist C B * Real.cos (∠ A C B) := by
  rw [EuclideanGeometry.angle, dist_comm C A, dist_comm C B, dist_eq_norm, dist_eq_norm,
    ← InnerProductGeometry.cos_angle_mul_norm_mul_norm]
  simp only [vsub_eq_sub]
  ring

-- The survey: square the sightings and add.
example : (300 : ℝ) ^ 2 + 450 ^ 2 = 292500 := by norm_num

-- At a right angle the correction is 0 and Pythagoras is left.
example : (300 : ℝ) ^ 2 + 450 ^ 2 - 2 * 300 * 450 * Real.cos (Real.pi / 2) = 292500 := by
  rw [Real.cos_pi_div_two]; norm_num

-- Sides of 300, 450 and 800 m ask for a cosine below −1, so no triangle exists.
example : ((300 : ℝ) ^ 2 + 450 ^ 2 - 800 ^ 2) / (2 * 300 * 450) < -1 := by norm_num

-- The same failure seen as sides: 800 is not shorter than 300 and 450 together.
example : ¬ ((800 : ℝ) < 300 + 450) := by norm_num

#print axioms law_of_cosines
#print axioms law_of_cosines_sss_range
#print axioms dot_product_eq_mul_cos_angle
