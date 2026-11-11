-- Nearest-neighbour maps: in the flat plane the spots equally far from two hospitals form the straight bisector line 2 (Q − P) · X = |Q|² − |P|², every Voronoi cell is convex, the centre of the circle through three hospitals is a corner of the map exactly when no hospital lies strictly inside that circle, and the card's county numbers come out as it says.
import Mathlib.Geometry.Euclidean.Circumcenter
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Convex.Basic
import Mathlib.Tactic.NormNum

/-! A spot in the plane is a point of `EuclideanSpace ℝ (Fin 2)`, so `dist X P` is the
straight-line distance, `‖P‖` the distance from the origin and `⟪u, v⟫` the dot product.
The hospitals are a finite set `S`. The Voronoi cell of a hospital `P` is every spot at least
as close to `P` as to any hospital of `S`. A triangle `t` (Mathlib's `Affine.Triangle`) has
three corners that do not lie on one line; `t.circumcenter` and `t.circumradius` are the
centre and radius of the one circle through them. -/

open RealInnerProductSpace

/-- Helper: comparing distances to `P` and `Q` is a linear condition on `X`. -/
theorem dist_le_dist_iff_inner (P Q X : EuclideanSpace ℝ (Fin 2)) :
    dist X P ≤ dist X Q ↔ 2 * ⟪Q - P, X⟫ ≤ ‖Q‖ ^ 2 - ‖P‖ ^ 2 := by
  rw [dist_eq_norm, dist_eq_norm, ← sq_le_sq₀ (norm_nonneg _) (norm_nonneg _),
    norm_sub_sq_real, norm_sub_sq_real, inner_sub_left, real_inner_comm X P,
    real_inner_comm X Q]
  constructor <;> intro h <;> linarith

#print axioms dist_le_dist_iff_inner

/-- The card's cell: every spot `X` at least as close to `P` as to every hospital `Q` of `S`.
Comparing `P` with itself costs nothing, so "every other hospital" and "every hospital" give
the same set. -/
def voronoiCell (S : Finset (EuclideanSpace ℝ (Fin 2))) (P : EuclideanSpace ℝ (Fin 2)) :
    Set (EuclideanSpace ℝ (Fin 2)) :=
  {X | ∀ Q ∈ S, dist X P ≤ dist X Q}

/-- The empty-circle property (Steps 2 and 3). Take any finite set of hospitals in the plane,
straight-line distance, every hospital counting the same, and any three of them that do not lie
on one line. The centre of the circle through the three is a corner of the map, a spot lying in
all three of their cells, exactly when no hospital lies strictly inside that circle: every
hospital is at least the radius away from the centre. -/
theorem circumcenter_is_voronoi_corner_iff_empty_circle
    (S : Finset (EuclideanSpace ℝ (Fin 2))) (t : Affine.Triangle ℝ (EuclideanSpace ℝ (Fin 2)))
    (ht : ∀ i, t.points i ∈ S) :
    (∀ i, t.circumcenter ∈ voronoiCell S (t.points i)) ↔
      ∀ T ∈ S, t.circumradius ≤ dist t.circumcenter T := by
  have hr := t.dist_circumcenter_eq_circumradius'
  constructor
  · intro h T hT
    have := h 0 T hT
    rwa [hr 0] at this
  · intro h i Q hQ
    rw [hr i]
    exact h Q hQ

/-- A boundary is a straight line (Step 0). For any two hospitals `P`, `Q` and any spot `X`
in the plane, `X` is equally far from both exactly when `2 (Q − P) · X = |Q|² − |P|²`:
no square of `X` is left, so the spots form one straight line, the perpendicular bisector. -/
theorem equally_far_iff_bisector_equation (P Q X : EuclideanSpace ℝ (Fin 2)) :
    dist X P = dist X Q ↔ 2 * ⟪Q - P, X⟫ = ‖Q‖ ^ 2 - ‖P‖ ^ 2 := by
  rw [dist_eq_norm, dist_eq_norm]
  constructor
  · intro h
    have h2 : ‖X - P‖ ^ 2 = ‖X - Q‖ ^ 2 := by rw [h]
    rw [norm_sub_sq_real, norm_sub_sq_real] at h2
    rw [inner_sub_left, real_inner_comm X P, real_inner_comm X Q]
    linarith
  · intro h
    have h2 : ‖X - P‖ ^ 2 = ‖X - Q‖ ^ 2 := by
      rw [norm_sub_sq_real, norm_sub_sq_real]
      rw [inner_sub_left, real_inner_comm X P, real_inner_comm X Q] at h
      linarith
    exact (sq_eq_sq₀ (norm_nonneg _) (norm_nonneg _)).1 h2

/-- A cell is convex (Step 1). For any finite set of hospitals in the plane and any hospital
`P`, the Voronoi cell of `P` is convex: the segment between two of its spots stays inside. -/
theorem voronoi_cell_convex (S : Finset (EuclideanSpace ℝ (Fin 2)))
    (P : EuclideanSpace ℝ (Fin 2)) :
    Convex ℝ (voronoiCell S P) := by
  have : voronoiCell S P =
      ⋂ Q ∈ S, {X : EuclideanSpace ℝ (Fin 2) | 2 * ⟪Q - P, X⟫ ≤ ‖Q‖ ^ 2 - ‖P‖ ^ 2} := by
    ext X
    simp only [voronoiCell, Set.mem_ofPred_eq, Set.mem_iInter]
    exact forall₂_congr fun Q _ => dist_le_dist_iff_inner P Q X
  rw [this]
  refine convex_iInter₂ fun Q _ => ?_
  have hlin : IsLinearMap ℝ fun X : EuclideanSpace ℝ (Fin 2) => 2 * ⟪Q - P, X⟫ :=
    ⟨fun x y => by rw [inner_add_right]; ring,
      fun c x => by rw [real_inner_smul_right, smul_eq_mul]; ring⟩
  exact convex_halfSpace_le hlin _

/-! The county, in whole kilometres: A (1, 3), B (9, 3), C (9, 7), D (3, 7), E (7, 5).
`sqDist X P` is the squared straight-line distance, so the checks stay in whole numbers or
fractions; comparing squared distances compares distances. -/

/-- Squared straight-line distance between two grid spots. -/
def sqDist (X P : ℚ × ℚ) : ℚ := (X.1 - P.1) ^ 2 + (X.2 - P.2) ^ 2

/-- The five hospitals. -/
def county : List (ℚ × ℚ) := [(1, 3), (9, 3), (9, 7), (3, 7), (7, 5)]

-- The house (4, 5): squared distances 13, 29, 29, 5, 9 to A, B, C, D, E, so D (√5 ≈ 2.24 km)
-- is nearest, then E (3 km).
example : sqDist (4, 5) (1, 3) = 13 ∧ sqDist (4, 5) (9, 3) = 29 ∧ sqDist (4, 5) (9, 7) = 29 ∧
    sqDist (4, 5) (3, 7) = 5 ∧ sqDist (4, 5) (7, 5) = 9 := by norm_num [sqDist]
example : ∀ Q ∈ county, sqDist (4, 5) (3, 7) ≤ sqDist (4, 5) Q := by norm_num [county, sqDist]

-- Bisector of A and E: 2 × (6, 2) · (x, y) = 74 − 10, that is 12x + 4y = 64, or 3x + y = 16.
example : (2 * (7 - 1) : ℚ) = 12 ∧ (2 * (5 - 3) : ℚ) = 4 ∧
    ((7 : ℚ) ^ 2 + 5 ^ 2) - (1 ^ 2 + 3 ^ 2) = 64 ∧ (64 : ℚ) / 4 = 16 := by norm_num
-- Bisector of A and B is x = 5: the spot (5, y) is equally far from both, for every y.
example (y : ℚ) : sqDist (5, y) (1, 3) = sqDist (5, y) (9, 3) := by simp [sqDist]; ring

-- Corner for A, B, E: x = 5 into 3x + y = 16 gives (5, 1), squared radius 20 (4.47 km).
-- D is √40 ≈ 6.32 km away, C √52, so the circle is empty and (5, 1) lies in E's cell.
example : 3 * (5 : ℚ) + 1 = 16 := by norm_num
example : sqDist (5, 1) (1, 3) = 20 ∧ sqDist (5, 1) (9, 3) = 20 ∧ sqDist (5, 1) (7, 5) = 20 ∧
    sqDist (5, 1) (3, 7) = 40 ∧ sqDist (5, 1) (9, 7) = 52 := by norm_num [sqDist]
example : ∀ Q ∈ county, sqDist (5, 1) (7, 5) ≤ sqDist (5, 1) Q := by norm_num [county, sqDist]

-- The other three corners: (4, 4) for A, D, E (squared radius 10), (9, 5) for B, C, E
-- (squared radius 4), (6, 8) for C, D, E (squared radius 10); each circle is empty.
example : ∀ Q ∈ county, sqDist (4, 4) (7, 5) ≤ sqDist (4, 4) Q := by norm_num [county, sqDist]
example : ∀ Q ∈ county, sqDist (9, 5) (7, 5) ≤ sqDist (9, 5) Q := by norm_num [county, sqDist]
example : ∀ Q ∈ county, sqDist (6, 8) (7, 5) ≤ sqDist (6, 8) Q := by norm_num [county, sqDist]
example : sqDist (4, 4) (1, 3) = 10 ∧ sqDist (4, 4) (3, 7) = 10 ∧ sqDist (9, 5) (9, 3) = 4 ∧
    sqDist (9, 5) (9, 7) = 4 ∧ sqDist (6, 8) (9, 7) = 10 ∧ sqDist (6, 8) (3, 7) = 10 := by norm_num [sqDist]

-- Triangle A B D fails: its centre (5, 7/2) is √(65/4) ≈ 4.03 km from A, B, D but
-- √(25/4) = 2.5 km from E, inside the circle.
example : sqDist (5, 7/2) (1, 3) = 65/4 ∧ sqDist (5, 7/2) (9, 3) = 65/4 ∧ sqDist (5, 7/2) (3, 7) = 65/4 ∧
    sqDist (5, 7/2) (7, 5) = 25/4 := by norm_num [sqDist]

-- The centroid (17/3, 11/3) of A B E is not equally far from A, B, E:
-- squared distances 200/9, 104/9, 32/9.
example : sqDist (17/3, 11/3) (1, 3) = 200/9 ∧ sqDist (17/3, 11/3) (9, 3) = 104/9 ∧
    sqDist (17/3, 11/3) (7, 5) = 32/9 := by norm_num [sqDist]

-- Area of E's cell by shoelace on (5, 1), (9, 5), (6, 8), (4, 4): (16 + 42 − 8 − 16) / 2 = 17.
example : ((5 * 5 - 9 * 1) + (9 * 8 - 6 * 5) + (6 * 4 - 4 * 8) + (4 * 1 - 5 * 4) : ℚ) / 2 = 17 := by
  norm_num

-- The worst-served spot: (5, 0) on the edge x = 5 is 5 km from A and B (squared 25),
-- farther than the corner (5, 1) at squared radius 20.
example : sqDist (5, 0) (1, 3) = 25 ∧ sqDist (5, 0) (9, 3) = 25 ∧ (20 : ℚ) < 25 := by norm_num [sqDist]
example : ∀ Q ∈ county, sqDist (5, 0) (1, 3) ≤ sqDist (5, 0) Q := by norm_num [county, sqDist]

-- Counts with n = 5 hospitals, h = 4 on the hull: 2n − 2 − h = 4 triangles,
-- 3n − 3 − h = 8 edges; 5 hospitals give 10 triples.
example : 2 * 5 - 2 - 4 = 4 ∧ 3 * 5 - 3 - 4 = 8 ∧ Nat.choose 5 3 = 10 := by decide

#print axioms circumcenter_is_voronoi_corner_iff_empty_circle
#print axioms equally_far_iff_bisector_equation
#print axioms voronoi_cell_convex
