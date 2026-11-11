-- Angles: in the flat plane, two angles that share a straight line add to a half turn, vertical angles are equal, and a line crossing two parallel lines meets both at the same angle.
import Mathlib.Geometry.Euclidean.Angle.Unoriented.Affine
import Mathlib.Analysis.Convex.Side
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.NumberTheory.Divisors
import Mathlib.Tactic.NormNum

open EuclideanGeometry Affine Real

-- Mathlib measures angles in radians: a half turn, 180 degrees, is π, and ∠ A F T is the
-- angle at F between the rays F→A and F→T, from 0 to π (the smaller of the two angles).

/-- Parallel lines copy angles (corresponding angles). In the flat plane, let a straight line
(the ladder) cross a line g (the ground) at F and a parallel line ℓ (the gutter line) at T.
Take a point A on g and a point G on ℓ on the same side of the ladder (the same corner
position), and a point X on the ladder past T. Then the ladder meets ℓ at T at the same angle
as it meets g at F: ∠ A F T = ∠ G T X. -/
theorem corresponding_angles_eq_of_parallel (A F T G X : EuclideanSpace ℝ (Fin 2))
    (hpar : line[ℝ, F, A] ∥ line[ℝ, T, G])
    (hside : line[ℝ, F, T].SSameSide A G)
    (hX : Sbtw ℝ F T X) :
    ∠ A F T = ∠ G T X := by
  have hGd : G -ᵥ T ∈ (line[ℝ, F, A]).direction := by
    rw [hpar.direction_eq]
    exact AffineSubspace.vsub_mem_direction (right_mem_affineSpan_pair ℝ T G)
      (left_mem_affineSpan_pair ℝ T G)
  rw [direction_affineSpan, mem_vectorSpan_pair_rev] at hGd
  obtain ⟨r, hr⟩ := hGd
  have hGeq : G = r • (A -ᵥ F) +ᵥ T := by rw [hr]; simp
  have hFs : F ∈ line[ℝ, F, T] := left_mem_affineSpan_pair ℝ F T
  have hTs : T ∈ line[ℝ, F, T] := right_mem_affineSpan_pair ℝ F T
  have hrpos : 0 < r := by
    rcases lt_trichotomy r 0 with h | h | h
    · exfalso
      have := AffineSubspace.sOppSide_smul_vsub_vadd_left hside.left_notMem hFs hTs h
      rw [← hGeq] at this
      exact hside.symm.not_sOppSide this
    · exfalso
      apply hside.right_notMem
      rw [hGeq, h]; simpa using hTs
    · exact h
  obtain ⟨⟨t, ⟨ht0, ht1⟩, hT⟩, hTF, hTX⟩ := hX
  have htne0 : t ≠ 0 := by
    rintro rfl; simp at hT; exact hTF hT.symm
  have htne1 : t ≠ 1 := by
    rintro rfl; simp at hT; exact hTX hT.symm
  have hTF' : T -ᵥ F = t • (X -ᵥ F) := by
    rw [← hT, AffineMap.lineMap_vsub_left]
  have hXT' : X -ᵥ T = (1 - t) • (X -ᵥ F) := by
    rw [← hT, AffineMap.right_vsub_lineMap]
  have htpos : 0 < t := lt_of_le_of_ne ht0 (Ne.symm htne0)
  have ht1pos : 0 < 1 - t := by have := lt_of_le_of_ne ht1 htne1; linarith
  unfold EuclideanGeometry.angle
  rw [hTF', hXT', ← hr, InnerProductGeometry.angle_smul_right_of_pos _ _ htpos,
    InnerProductGeometry.angle_smul_right_of_pos _ _ ht1pos,
    InnerProductGeometry.angle_smul_left_of_pos _ _ hrpos]

/-- Angles on a straight line add to 180 degrees. In the flat plane, if F lies strictly between
A and B on a straight line, then for any point T the two neighbouring angles at F,
∠ A F T and ∠ T F B, add to a half turn, π. -/
theorem angles_on_straight_line_add_to_pi (A F B T : EuclideanSpace ℝ (Fin 2))
    (hline : Sbtw ℝ A F B) :
    ∠ A F T + ∠ T F B = π := by
  have := angle_add_angle_eq_pi_of_angle_eq_pi T hline.angle₁₂₃_eq_pi
  rw [angle_comm T F A] at this
  exact this

/-- Vertical angles are equal. In the flat plane, if two straight lines AB and TE cross at F
(F strictly between A and B, and strictly between T and E), then the angles facing each other
across the crossing are equal: ∠ A F T = ∠ B F E. -/
theorem vertical_angles_eq (A B T E F : EuclideanSpace ℝ (Fin 2))
    (hAB : Sbtw ℝ A F B) (hTE : Sbtw ℝ T F E) :
    ∠ A F T = ∠ B F E := by
  exact angle_eq_angle_of_angle_eq_pi_of_angle_eq_pi hAB.angle₁₂₃_eq_pi hTE.angle₁₂₃_eq_pi

-- The card's worked numbers, in whole degrees.
-- 70 degrees is 70/360 = 7/36 of a full turn.
example : (70 : ℚ) / 360 = 7 / 36 := by norm_num
-- Foot, far side, and the co-interior angle at the top: 180 − 70 = 110.
example : (180 : ℤ) - 70 = 110 := by norm_num
-- Ladder to wall: 90 − 70 = 20.
example : (90 : ℤ) - 70 = 20 := by norm_num
-- Round the crossing at the foot: 70 + 110 + 70 + 110 = 360.
example : (70 : ℤ) + 110 + 70 + 110 = 360 := by norm_num
-- The reflex angle the long way round from ground to ladder: 360 − 70 = 290.
example : (360 : ℤ) - 70 = 290 := by norm_num
-- A gutter rising 2 degrees is met at 70 + 2 = 72 degrees.
example : (70 : ℤ) + 2 = 72 := by norm_num
-- 360 has 24 whole-number divisors; 100 has 9.
example : (Nat.divisors 360).card = 24 := by decide
example : (Nat.divisors 100).card = 9 := by decide

#print axioms corresponding_angles_eq_of_parallel
#print axioms angles_on_straight_line_add_to_pi
#print axioms vertical_angles_eq
