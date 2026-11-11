-- Distance and midpoint: on axes at right angles with one unit on every axis, the distance between two points is the square root of the summed squared coordinate moves, and the midpoint, found by averaging coordinates on any straight axes, is the one point on the segment equally far from both ends.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Normed.Affine.AddTorsor
import Mathlib.Analysis.Convex.Segment
import Mathlib.LinearAlgebra.AffineSpace.Midpoint
import Mathlib.Tactic.NormNum

/-- The distance formula. Measure points on flat ground from an origin, along axes that cross
at right angles and share one unit (an orthonormal basis `e`; the coordinates of a point `A`
are `e.repr A i`). Then the straight-line distance from A to B is the positive square root of
the sum of the squared moves along each axis: two moves on a plane, three in space. -/
theorem distance_formula {n : ℕ} {V : Type*} [NormedAddCommGroup V] [InnerProductSpace ℝ V]
    (e : OrthonormalBasis (Fin n) ℝ V) (A B : V) :
    dist A B = Real.sqrt (∑ i, (e.repr B i - e.repr A i) ^ 2) := by
  rw [dist_eq_norm, ← e.repr.norm_map, EuclideanSpace.norm_eq]
  congr 1
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [map_sub]
  simp only [PiLp.sub_apply, Real.norm_eq_abs, sq_abs]
  ring

/-- The midpoint needs less. On any straight axes with evenly spaced marks (any basis `b`,
slanted or in mixed units), each coordinate of the midpoint of A and B is the average of
A's and B's coordinates. -/
theorem midpoint_coordinates_are_averages {ι V : Type*} [AddCommGroup V] [Module ℝ V]
    (b : Module.Basis ι ℝ V) (A B : V) (i : ι) :
    b.repr (midpoint ℝ A B) i = (b.repr A i + b.repr B i) / 2 := by
  simp only [midpoint_eq_smul_add, map_smul, map_add, Finsupp.smul_apply, Finsupp.add_apply,
    smul_eq_mul]
  norm_num
  ring

/-- The midpoint M of A and B is half the distance from each end, and it is the only point on
the segment from A to B that is equally far from both ends. -/
theorem midpoint_is_halfway_and_unique {V : Type*} [NormedAddCommGroup V]
    [InnerProductSpace ℝ V] (A B : V) :
    dist A (midpoint ℝ A B) = dist A B / 2 ∧ dist (midpoint ℝ A B) B = dist A B / 2 ∧
      ∀ P ∈ segment ℝ A B, (dist A P = dist P B ↔ P = midpoint ℝ A B) := by
  refine ⟨?_, ?_, ?_⟩
  · rw [dist_left_midpoint]; simp; ring
  · rw [dist_midpoint_right]; simp; ring
  · intro P hP
    obtain ⟨a, b, ha, hb, hab, rfl⟩ := hP
    obtain rfl : a = 1 - b := by linarith
    have h1 : dist A ((1 - b) • A + b • B) = b * dist A B := by
      rw [dist_eq_norm, dist_eq_norm]
      have : A - ((1 - b) • A + b • B) = b • (A - B) := by module
      rw [this, norm_smul, Real.norm_of_nonneg hb]
    have h2 : dist ((1 - b) • A + b • B) B = (1 - b) * dist A B := by
      rw [dist_eq_norm, dist_eq_norm]
      have : ((1 - b) • A + b • B) - B = (1 - b) • (A - B) := by module
      rw [this, norm_smul, Real.norm_of_nonneg ha]
    rw [h1, h2, midpoint_eq_smul_add]
    have key : (1 - b) • A + b • B - (⅟2 : ℝ) • (A + B) = (1 / 2 - b) • (A - B) := by
      rw [invOf_eq_inv]; module
    by_cases hAB : A = B
    · subst hAB
      have : (1 - b) • A + b • A = (⅟2 : ℝ) • (A + A) := by rw [invOf_eq_inv]; module
      simp [this]
    · have hd : dist A B ≠ 0 := dist_ne_zero.mpr hAB
      have hs : A - B ≠ 0 := sub_ne_zero.mpr hAB
      constructor
      · intro h
        have hb2 : b = 1 / 2 := by
          have := mul_right_cancel₀ hd h
          linarith
        rw [← sub_eq_zero, key, hb2]
        simp
      · intro h
        rw [← sub_eq_zero, key, smul_eq_zero] at h
        rcases h with h | h
        · have : b = 1 / 2 := by linarith
          rw [this]; ring
        · exact absurd h hs

-- The van: drops A (3, 4) and B (8, 1). Moves 5 east and -3 north; squares 25 and 9; sum 34.
example : (8 : ℤ) - 3 = 5 ∧ (1 : ℤ) - 4 = -3 := by decide
example : ((8 : ℤ) - 3) ^ 2 + ((1 : ℤ) - 4) ^ 2 = 34 := by decide
-- The same distance computed in the Euclidean plane: the square root of 34.
example : dist (!₂[(3 : ℝ), 4]) (!₂[(8 : ℝ), 1]) = Real.sqrt 34 := by
  norm_num [EuclideanSpace.dist_eq, Fin.sum_univ_two, Real.dist_eq, sq_abs]
-- The locker: averages (3 + 8) / 2 = 11/2 and (4 + 1) / 2 = 5/2, that is (5.5, 2.5).
example : ((3 : ℚ) + 8) / 2 = 11 / 2 ∧ ((4 : ℚ) + 1) / 2 = 5 / 2 := by norm_num
-- Each half is the move (5/2, -3/2): its square 34/4 is a quarter of 34, so each half is half of the root of 34.
example : ((11 : ℚ) / 2 - 3) ^ 2 + ((5 : ℚ) / 2 - 4) ^ 2 = 34 / 4 := by norm_num
-- B from A and M: 2M - A = (8, 1).
example : 2 * ((11 : ℚ) / 2) - 3 = 8 ∧ 2 * ((5 : ℚ) / 2) - 4 = 1 := by norm_num
-- The cable from (1, 2, 0) to (4, 6, 12): floor diagonal 3² + 4² = 5², then 5² + 12² = 13².
example : (3 : ℤ) ^ 2 + 4 ^ 2 = 5 ^ 2 ∧ (5 : ℤ) ^ 2 + 12 ^ 2 = 169 := by decide
example : ((4 : ℤ) - 1) ^ 2 + ((6 : ℤ) - 2) ^ 2 + ((12 : ℤ) - 0) ^ 2 = 13 ^ 2 := by decide
-- The cable's midpoint (5/2, 4, 6), and each half squared is a quarter of 169.
example : ((1 : ℚ) + 4) / 2 = 5 / 2 ∧ ((2 : ℚ) + 6) / 2 = 4 ∧ ((0 : ℚ) + 12) / 2 = 6 := by norm_num
example : ((5 : ℚ) / 2 - 1) ^ 2 + ((4 : ℚ) - 2) ^ 2 + ((6 : ℚ) - 0) ^ 2 = 169 / 4 := by norm_num
-- The depot road: 25 + 65 - 2 × 28 = 34.
example : (3 : ℤ) ^ 2 + 4 ^ 2 = 25 ∧ (8 : ℤ) ^ 2 + 1 ^ 2 = 65 ∧ (3 : ℤ) * 8 + 4 * 1 = 28 ∧
    (25 : ℤ) + 65 - 2 * 28 = 34 := by decide
-- The square on AB, corners (3, 4), (8, 1), (11, 6), (6, 9): twice its area by corners is 68; box 8 × 8 - 4 × 7.5 = 34.
example : (3 : ℤ) * 1 - 4 * 8 + (8 * 6 - 1 * 11) + (11 * 9 - 6 * 6) + (6 * 4 - 9 * 3) = 2 * 34 := by decide
example : (8 : ℤ) * 8 - 2 * (5 * 3) = 34 := by decide
-- The mistakes: adding the legs gives 8; stopping before the root gives 34; halving the move gives (5/2, -3/2).
example : (5 : ℤ) + 3 = 8 ∧ (5 : ℤ) ^ 2 + 3 ^ 2 = 34 := by decide
example : ((8 : ℚ) - 3) / 2 = 5 / 2 ∧ ((1 : ℚ) - 4) / 2 = -3 / 2 := by norm_num
-- Try changing: shift to (13, -3) and (18, -6), still 34; B at (9, 12) gives 6² + 8² = 10².
example : ((18 : ℤ) - 13) ^ 2 + ((-6 : ℤ) - (-3)) ^ 2 = 34 := by decide
example : ((9 : ℤ) - 3) ^ 2 + ((12 : ℤ) - 4) ^ 2 = 10 ^ 2 := by decide

#print axioms distance_formula
#print axioms midpoint_coordinates_are_averages
#print axioms midpoint_is_halfway_and_unique
