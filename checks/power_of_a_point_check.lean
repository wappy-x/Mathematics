-- Power of a point: for any line through a point that meets a circle at A and B, the distances PA and PB multiply to the size of d² − r², the tangent squared equals d² − r², and points of equal power to two circles with different centres form a line at x = (s² + r² − r₂²)/(2s).
import Mathlib.Geometry.Euclidean.Sphere.Power
import Mathlib.Analysis.InnerProductSpace.PiL2

open EuclideanGeometry

/-- The plane, with points written by their coordinates (x, y). -/
local notation "Plane" => EuclideanSpace ℝ (Fin 2)

/-- **Power of a point** (Euclid III.35 and III.36). Take a circle in the plane with centre O
and radius r, and a point P at distance d = PO from the centre. If a straight line through P
meets the circle at A and B, then the two distances from P multiply to the size of the
point's power: PA × PB = |d² − r²|. This covers any secant or chord meeting the circle at
distinct points A and B (when A = B, line[ℝ, A, B] is just {A}, forcing P = A); the tangent
case from outside is proved next. -/
theorem mul_dist_eq_abs_dist_center_sq_sub_radius_sq {ω : Sphere Plane} {P A B : Plane}
    (hP : P ∈ line[ℝ, A, B]) (hA : A ∈ ω) (hB : B ∈ ω) :
    dist P A * dist P B = |dist P ω.center ^ 2 - ω.radius ^ 2| := by
  exact Sphere.mul_dist_eq_abs_power hP hA hB

/-- **Tangent length.** If the line from P to the point T of the circle touches the circle
at T, then the tangent squared equals the power: PT² = d² − r². -/
theorem dist_tangent_sq_eq_dist_center_sq_sub_radius_sq {ω : Sphere Plane} {P T : Plane}
    (hT : ω.IsTangentAt T line[ℝ, P, T]) :
    dist P T ^ 2 = dist P ω.center ^ 2 - ω.radius ^ 2 := by
  exact (Sphere.IsTangentAt.power_eq_dist_sq hT).symm

/-- **The radical axis is a line.** Put the first circle's centre O at (0, 0) and the second
circle's centre at (s, 0), with s ≠ 0 so the centres differ. The points with equal power to
both circles are exactly the vertical line x = (s² + r² − r₂²)/(2s), where r and r₂ are the
radii. -/
theorem radical_axis_eq_vertical_line {ω₁ ω₂ : Sphere Plane} {s : ℝ}
    (h₁ : ω₁.center = !₂[0, 0]) (h₂ : ω₂.center = !₂[s, 0]) (hs : s ≠ 0) :
    {p : Plane | ω₁.power p = ω₂.power p} =
      {p : Plane | p 0 = (s ^ 2 + ω₁.radius ^ 2 - ω₂.radius ^ 2) / (2 * s)} := by
  have key : ∀ p : Plane, ω₁.power p = ω₂.power p ↔
      p 0 = (s ^ 2 + ω₁.radius ^ 2 - ω₂.radius ^ 2) / (2 * s) := by
    intro p
    have e1 : dist p ω₁.center ^ 2 = (p 0) ^ 2 + (p 1) ^ 2 := by
      rw [EuclideanSpace.dist_eq, Real.sq_sqrt (Finset.sum_nonneg fun _ _ => sq_nonneg _), Fin.sum_univ_two, h₁]
      simp [sq_abs]
    have e2 : dist p ω₂.center ^ 2 = (p 0 - s) ^ 2 + (p 1) ^ 2 := by
      rw [EuclideanSpace.dist_eq, Real.sq_sqrt (Finset.sum_nonneg fun _ _ => sq_nonneg _), Fin.sum_univ_two, h₂]
      simp [Real.dist_eq, sq_abs]
    simp only [Sphere.power, e1, e2]
    rw [eq_div_iff (mul_ne_zero two_ne_zero hs)]
    constructor <;> intro h <;> linarith
  ext p
  exact key p

-- The stake, 13 m from the centre of a pond of radius 5 m: power 144, tangent 12 m.
example : (13 : ℤ) ^ 2 - 5 ^ 2 = 144 := by norm_num
example : (12 : ℤ) ^ 2 = 13 ^ 2 - 5 ^ 2 := by norm_num
-- The line through the centre meets the banks at 8 m and 18 m: 8 × 18 = 144 = 12 × 12.
example : (8 : ℤ) * 18 = 13 ^ 2 - 5 ^ 2 ∧ (8 : ℤ) * 18 = 12 * 12 := by norm_num
-- Far bank from the near one, then the pond across: 144 ÷ 8 = 18, and 18 − 8 = 10.
example : (144 : ℤ) / 8 = 18 ∧ (18 : ℤ) - 8 = 10 := by norm_num
-- The fountain, 3 m from the centre: power −16; the diameter splits 2 × 8 and the
-- chord square to it splits 4 × 4, both 16.
example : (3 : ℤ) ^ 2 - 5 ^ 2 = -16 := by norm_num
example : (2 : ℤ) * 8 = |(3 : ℤ) ^ 2 - 5 ^ 2| ∧ (4 : ℤ) * 4 = |(3 : ℤ) ^ 2 - 5 ^ 2| := by norm_num
-- Diameter as one chord: (r − d)(r + d) = r² − d² at r = 5, d = 3.
example : ((5 : ℤ) - 3) * (5 + 3) = 5 ^ 2 - 3 ^ 2 := by norm_num
-- Second pond, radius 9 m, centre 28 m away: the radical axis is at x = 13.
example : ((28 : ℚ) ^ 2 + 5 ^ 2 - 9 ^ 2) / (2 * 28) = 13 := by norm_num
-- At (13, 5) on the axis, the tangents to both ponds are 13 m: power 169 for each.
example : (13 : ℤ) ^ 2 + 5 ^ 2 - 5 ^ 2 = 13 ^ 2 ∧ ((13 : ℤ) - 28) ^ 2 + 5 ^ 2 - 9 ^ 2 = 13 ^ 2 := by
  norm_num
-- Third pond, centre (0, 20), radius 5: the radical centre (13, 10) has power 244 to all three.
example : (13 : ℤ) ^ 2 + 10 ^ 2 - 5 ^ 2 = 244 ∧ ((13 : ℤ) - 28) ^ 2 + 10 ^ 2 - 9 ^ 2 = 244 ∧
    (13 : ℤ) ^ 2 + (10 - 20) ^ 2 - 5 ^ 2 = 244 := by norm_num
-- The arch 8 m wide rising 2 m: half-span 4, so 4 × 4 = 2 × (2r − 2) gives r = 5.
example : (4 : ℤ) * 4 = 2 * (2 * 5 - 2) := by norm_num
-- The usual mistake: the outside piece times the inside piece gives 8 × 10 = 80, not 144.
example : (8 : ℤ) * 10 ≠ 13 ^ 2 - 5 ^ 2 := by norm_num

#print axioms mul_dist_eq_abs_dist_center_sq_sub_radius_sq
#print axioms dist_tangent_sq_eq_dist_center_sq_sub_radius_sq
#print axioms radical_axis_eq_vertical_line
