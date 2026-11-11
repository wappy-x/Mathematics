-- Triangles: in the flat plane, three lengths make a genuine triangle exactly when each is less than the other two added together, and the three angles of any genuine triangle add to a half-turn.
import Mathlib.Geometry.Euclidean.Triangle
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.LinearAlgebra.AffineSpace.Independent
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Convex.StrictConvexBetween
import Mathlib.Analysis.InnerProductSpace.Convex

open EuclideanGeometry

/-- Two sides must beat the third, and that is the whole test. Three lengths a, b, c are the
sides of a genuine triangle in the flat plane (three corners A, B, C not on one line, with side
a = BC facing corner A, side b = CA facing B, side c = AB facing C) exactly when each length is
strictly less than the other two laid end to end: a + b > c, b + c > a and c + a > b.
Equality is not enough: then the corners lie on one line and the triangle has no inside. -/
theorem triangle_exists_iff_two_sides_beat_third (a b c : ℝ) :
    (∃ A B C : EuclideanSpace ℝ (Fin 2), AffineIndependent ℝ ![A, B, C] ∧
        dist B C = a ∧ dist C A = b ∧ dist A B = c) ↔
      (a + b > c ∧ b + c > a ∧ c + a > b) := by
  constructor
  · rintro ⟨A, B, C, hABC, rfl, rfl, rfl⟩
    rw [affineIndependent_iff_not_collinear_set] at hABC
    refine ⟨?_, ?_, ?_⟩
    · have : ¬ Wbtw ℝ A C B := fun h => hABC (by
        have := h.collinear
        convert this using 1; ext; simp; tauto)
      have := dist_lt_dist_add_dist_iff.mpr this
      rw [dist_comm A C, dist_comm C B] at this
      linarith
    · have : ¬ Wbtw ℝ B A C := fun h => hABC (by
        have := h.collinear
        convert this using 1; ext; simp; tauto)
      have := dist_lt_dist_add_dist_iff.mpr this
      rw [dist_comm B A] at this
      linarith [dist_comm A C]
    · have : ¬ Wbtw ℝ C B A := fun h => hABC (by
        have := h.collinear
        convert this using 1; ext; simp; tauto)
      have := dist_lt_dist_add_dist_iff.mpr this
      rw [dist_comm C B, dist_comm B A] at this
      linarith
  · rintro ⟨h1, h2, h3⟩
    have ha : 0 < a := by linarith
    have hb : 0 < b := by linarith
    have hc : 0 < c := by linarith
    set x : ℝ := (b ^ 2 + c ^ 2 - a ^ 2) / (2 * c) with hx
    have hx1 : -b ≤ x := by
      rw [hx, le_div_iff₀ (by positivity)]; nlinarith
    have hx2 : x ≤ b := by
      rw [hx, div_le_iff₀ (by positivity)]; nlinarith
    have hxb : x ^ 2 ≤ b ^ 2 := sq_le_sq' hx1 hx2
    set y : ℝ := Real.sqrt (b ^ 2 - x ^ 2) with hy
    have hy2 : y ^ 2 = b ^ 2 - x ^ 2 := Real.sq_sqrt (by linarith)
    have hcx : 2 * c * x = b ^ 2 + c ^ 2 - a ^ 2 := by
      rw [hx]; field_simp
    let A : EuclideanSpace ℝ (Fin 2) := !₂[0, 0]
    let B : EuclideanSpace ℝ (Fin 2) := !₂[c, 0]
    let C : EuclideanSpace ℝ (Fin 2) := !₂[x, y]
    have dBC : dist B C = a := by
      rw [← sq_eq_sq₀ dist_nonneg ha.le, EuclideanSpace.dist_sq_eq]
      simp [B, C, Fin.sum_univ_two, Real.dist_eq, sq_abs]
      nlinarith
    have dCA : dist C A = b := by
      rw [← sq_eq_sq₀ dist_nonneg hb.le, EuclideanSpace.dist_sq_eq]
      simp [A, C, Fin.sum_univ_two, Real.dist_eq, sq_abs]
      nlinarith
    have dAB : dist A B = c := by
      rw [← sq_eq_sq₀ dist_nonneg hc.le, EuclideanSpace.dist_sq_eq]
      simp [A, B, Fin.sum_univ_two, Real.dist_eq, sq_abs]
    refine ⟨A, B, C, ?_, dBC, dCA, dAB⟩
    rw [affineIndependent_iff_not_collinear_set]
    intro hcol
    rcases hcol.wbtw_or_wbtw_or_wbtw with h | h | h
    · have := dist_add_dist_eq_iff.mpr h
      rw [dist_comm A C] at this
      linarith
    · have := dist_add_dist_eq_iff.mpr h
      rw [dist_comm B A] at this
      linarith
    · have := dist_add_dist_eq_iff.mpr h
      rw [dist_comm C B] at this
      linarith

/-- The angle sum. In any genuine triangle ABC in the flat plane, the angles at the three
corners add to a half-turn: A + B + C = 180°. Mathlib measures angles in radians, where a
half-turn, 180°, is π. So a missing angle is the half-turn minus the other two. -/
theorem triangle_angle_sum_eq_half_turn (A B C : EuclideanSpace ℝ (Fin 2))
    (hABC : AffineIndependent ℝ ![A, B, C]) :
    ∠ B A C + ∠ A B C + ∠ A C B = Real.pi := by
  have hBA : B ≠ A := by
    intro h
    rw [affineIndependent_iff_not_collinear_set] at hABC
    apply hABC
    rw [h, Set.insert_eq_of_mem (Set.mem_insert _ _)]
    exact collinear_pair ℝ A C
  have := angle_add_angle_add_angle_eq_pi C hBA
  rw [angle_comm B C A] at this
  linarith [angle_comm C A B]

/-- One comparison settles it. When c is the longest of three lengths, the other two tests
pass on their own, so the three-way test comes down to the two shorter against the longest:
a + b > c. -/
theorem two_shorter_against_longest_suffices (a b c : ℝ)
    (hac : a ≤ c) (hbc : b ≤ c) :
    (a + b > c ∧ b + c > a ∧ c + a > b) ↔ a + b > c := by
  constructor
  · exact fun h => h.1
  · intro h
    exact ⟨h, by linarith, by linarith⟩

-- The fence: panels 3, 4 and 8 fail by 1 m; swapping in 5 closes the bed.
example : (3 : ℕ) + 4 = 7 ∧ ¬ ((3 : ℕ) + 4 > 8) ∧ 8 - (3 + 4) = 1 := by decide
example : (3 : ℕ) + 4 > 5 ∧ 4 + 5 > 3 ∧ 5 + 3 > 4 := by decide
-- A third panel of 1 to 8 m with the 3 m and 4 m ones: only 2 to 6 pass, strictly between 1 and 7.
example : (List.range 8).map (fun i => decide ((3 : ℕ) + 4 > i + 1 ∧ 4 + (i + 1) > 3 ∧ (i + 1) + 3 > 4))
    = [false, true, true, true, true, true, false, false] := by decide
example : (4 : ℕ) - 3 = 1 ∧ (4 : ℕ) + 3 = 7 := by decide
-- Mistake 1: taking 8, 3 against 4 in the listed order says yes, but 3 + 4 against 8 says no.
example : (8 : ℕ) + 3 > 4 ∧ (3 : ℕ) + 8 > 4 ∧ (4 : ℕ) + 8 > 3 ∧ ¬ ((3 : ℕ) + 4 > 8) := by decide
-- Mistake 2: 3, 4, 7 is equality, not strictly greater, so it fails.
example : (3 : ℕ) + 4 = 7 ∧ ¬ ((3 : ℕ) + 4 > 7) := by decide
-- Two angles of 100° and 90° leave -10°: no triangle.
example : (180 : ℤ) - 100 - 90 = -10 := by decide

#print axioms triangle_exists_iff_two_sides_beat_third
#print axioms triangle_angle_sum_eq_half_turn
#print axioms two_shorter_against_longest_suffices
