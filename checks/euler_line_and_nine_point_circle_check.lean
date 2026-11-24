-- The Euler line and the nine-point circle: in every triangle in the plane the point 3G - 2O lies on all three altitudes and is the orthocentre, O, G and H lie on one line with HG = 2 GO, and the circle centred halfway from O to H with half the circumradius passes through the three side midpoints, the three altitude feet and the three midpoints from H to the corners.
import Mathlib.Geometry.Euclidean.NinePointCircle
import Mathlib.Analysis.InnerProductSpace.PiL2

open EuclideanGeometry

/-- The plane, with ordinary straight-line distance. -/
local notation "Plane" => EuclideanSpace ℝ (Fin 2)

theorem euler_aux_centroid (t : Affine.Triangle ℝ Plane) :
    t.centroid = (1 / 3 : ℝ) • (t.points 0 + t.points 1 + t.points 2) := by
  have h := t.centroid_vsub_eq 0
  simp only [vsub_eq_sub, sub_zero] at h
  rw [h, Fin.sum_univ_three]; norm_num

theorem euler_aux_orthocenter (t : Affine.Triangle ℝ Plane) :
    (3 : ℝ) • t.centroid - (2 : ℝ) • t.circumcenter = t.orthocenter := by
  rw [t.orthocenter_eq_smul_vsub_vadd_circumcenter, Affine.Simplex.univ_centroid_eq,
    vsub_eq_sub, vadd_eq_add]
  module

theorem euler_aux_radius (t : Affine.Triangle ℝ Plane) (i : Fin 3) :
    ‖t.points i - t.circumcenter‖ = t.circumradius := by
  rw [← dist_eq_norm]; exact t.dist_circumcenter_eq_circumradius i

#print axioms euler_aux_centroid
#print axioms euler_aux_orthocenter
#print axioms euler_aux_radius

/-- **Euler line.** In every triangle (corners not in a row), with circumcentre O and
centroid G, the point H = 3G - 2O lies on all three altitudes and is the orthocentre,
and O, G and H lie on one line. -/
theorem three_centroid_sub_two_circumcenter_is_orthocenter_on_euler_line
    (t : Affine.Triangle ℝ Plane) :
    let O := t.circumcenter
    let G := t.centroid
    let H := (3 : ℝ) • G - (2 : ℝ) • O
    (∀ i, H ∈ t.altitude i) ∧ H = t.orthocenter ∧ Collinear ℝ ({O, G, H} : Set Plane) := by
  dsimp only
  have hH := euler_aux_orthocenter t
  refine ⟨fun i => hH ▸ t.orthocenter_mem_altitude, hH, ?_⟩
  rw [collinear_iff_of_mem (p₀ := t.circumcenter) (by simp)]
  refine ⟨t.centroid - t.circumcenter, ?_⟩
  intro p hp
  simp only [Set.mem_insert_iff, Set.mem_singleton_iff] at hp
  rcases hp with rfl | rfl | rfl
  · exact ⟨0, by simp⟩
  · exact ⟨1, by simp⟩
  · exact ⟨3, by simp only [vadd_eq_add]; module⟩

/-- **The 2 : 1 split.** On the Euler line the centroid sits a third of the way from O to
H: the distance HG is twice the distance GO. -/
theorem dist_orthocenter_centroid_eq_two_mul_dist_centroid_circumcenter
    (t : Affine.Triangle ℝ Plane) :
    let O := t.circumcenter
    let G := t.centroid
    let H := (3 : ℝ) • G - (2 : ℝ) • O
    dist H G = 2 * dist G O := by
  dsimp only
  have : (3 : ℝ) • t.centroid - (2 : ℝ) • t.circumcenter - t.centroid =
      (2 : ℝ) • (t.centroid - t.circumcenter) := by module
  rw [dist_eq_norm, dist_eq_norm, this, norm_smul]
  norm_num

/-- **Nine-point circle.** In every triangle, with circumcentre O, circumradius R and
H = 3G - 2O, the circle centred at N, the midpoint of O and H, with radius R / 2 passes
through the three side midpoints, the three feet of the altitudes and the three midpoints
between H and the corners. -/
theorem nine_points_on_circle_midpoint_OH_half_circumradius
    (t : Affine.Triangle ℝ Plane) :
    let O := t.circumcenter
    let G := t.centroid
    let H := (3 : ℝ) • G - (2 : ℝ) • O
    let N := midpoint ℝ O H
    (∀ i j, i ≠ j → dist (midpoint ℝ (t.points i) (t.points j)) N = t.circumradius / 2) ∧
    (∀ i, dist (t.altitudeFoot i) N = t.circumradius / 2) ∧
    (∀ i, dist (midpoint ℝ H (t.points i)) N = t.circumradius / 2) := by
  dsimp only
  have hG := euler_aux_centroid t
  have hN : midpoint ℝ t.circumcenter ((3 : ℝ) • t.centroid - (2 : ℝ) • t.circumcenter) =
      (1 / 2 : ℝ) • ((3 : ℝ) • t.centroid - t.circumcenter) := by
    simp only [midpoint_eq_smul_add, invOf_eq_inv]; module
  have key : ∀ k, ‖(1 / 2 : ℝ) • (t.points k - t.circumcenter)‖ = t.circumradius / 2 := by
    intro k
    rw [norm_smul, euler_aux_radius]; norm_num; ring
  refine ⟨?_, ?_, ?_⟩
  · intro i j hij
    rw [dist_comm, dist_eq_norm, hN, midpoint_eq_smul_add, hG]
    fin_cases i <;> fin_cases j <;> simp at hij <;> simp only [Fin.zero_eta, Fin.mk_one, Fin.reduceFinMk, Fin.isValue]
    · convert key 2 using 2; simp only [invOf_eq_inv]; module
    · convert key 1 using 2; simp only [invOf_eq_inv]; module
    · convert key 2 using 2; simp only [invOf_eq_inv]; module
    · convert key 0 using 2; simp only [invOf_eq_inv]; module
    · convert key 1 using 2; simp only [invOf_eq_inv]; module
    · convert key 0 using 2; simp only [invOf_eq_inv]; module
  · intro i
    have h := t.altitudeFoot_mem_ninePointCircle i
    rw [EuclideanGeometry.mem_sphere, Affine.Simplex.ninePointCircle_center,
      Affine.Simplex.ninePointCircle_radius] at h
    have hc : ((((2 : ℕ) : ℝ) + 1) / ((2 : ℕ) : ℝ)) • (t.centroid -ᵥ t.circumcenter) +ᵥ
        t.circumcenter = (1 / 2 : ℝ) • ((3 : ℝ) • t.centroid - t.circumcenter) := by
      rw [vsub_eq_sub, vadd_eq_add]; norm_num; module
    rw [hc] at h
    rw [hN, h]; norm_num
  · intro i
    rw [dist_eq_norm, hN, midpoint_eq_smul_add]
    convert key i using 2
    simp only [invOf_eq_inv]; module

/-! The card's example: A (0, 0), B (6, 0), C (2, 4), worked exactly in fractions. -/

-- O = (3, 1) is equally far from all three corners: squared distance 10 each, so R = √10.
example : (3 - 0 : ℚ) ^ 2 + (1 - 0) ^ 2 = 10 ∧ (3 - 6 : ℚ) ^ 2 + (1 - 0) ^ 2 = 10 ∧
    (3 - 2 : ℚ) ^ 2 + (1 - 4) ^ 2 = 10 := by norm_num

-- G = ((0 + 6 + 2)/3, (0 + 0 + 4)/3) = (8/3, 4/3), and H = 3G - 2O = (2, 2).
example : ((0 + 6 + 2) / 3 : ℚ) = 8 / 3 ∧ ((0 + 0 + 4) / 3 : ℚ) = 4 / 3 ∧
    3 * (8 / 3 : ℚ) - 2 * 3 = 2 ∧ 3 * (4 / 3 : ℚ) - 2 * 1 = 2 := by norm_num

-- H = (2, 2) is on all three altitudes: (H - A)·(B - C) = 0, (H - B)·(C - A) = 0, (H - C)·(A - B) = 0.
example : (2 - 0 : ℚ) * (6 - 2) + (2 - 0) * (0 - 4) = 0 ∧
    (2 - 6 : ℚ) * (2 - 0) + (2 - 0) * (4 - 0) = 0 ∧
    (2 - 2 : ℚ) * (0 - 6) + (2 - 4) * (0 - 0) = 0 := by norm_num

-- O, G, H all lie on the Euler line x + y = 4.
example : (3 + 1 : ℚ) = 4 ∧ (8 / 3 + 4 / 3 : ℚ) = 4 ∧ (2 + 2 : ℚ) = 4 := by norm_num

-- HG = 2 GO, compared as squares: |H - G|² = 8/9 and |G - O|² = 2/9.
example : (2 - 8 / 3 : ℚ) ^ 2 + (2 - 4 / 3) ^ 2 = 4 * ((8 / 3 - 3) ^ 2 + (4 / 3 - 1) ^ 2) := by
  norm_num

-- N = midpoint of O (3, 1) and H (2, 2) = (5/2, 3/2); all nine points are at squared
-- distance 10/4 = (R/2)² from N.
example : ((3 + 2) / 2 : ℚ) = 5 / 2 ∧ ((1 + 2) / 2 : ℚ) = 3 / 2 := by norm_num

example :
    -- side midpoints (4, 2), (1, 2), (3, 0)
    (4 - 5 / 2 : ℚ) ^ 2 + (2 - 3 / 2) ^ 2 = 10 / 4 ∧
    (1 - 5 / 2 : ℚ) ^ 2 + (2 - 3 / 2) ^ 2 = 10 / 4 ∧
    (3 - 5 / 2 : ℚ) ^ 2 + (0 - 3 / 2) ^ 2 = 10 / 4 ∧
    -- altitude feet (3, 3), (6/5, 12/5), (2, 0)
    (3 - 5 / 2 : ℚ) ^ 2 + (3 - 3 / 2) ^ 2 = 10 / 4 ∧
    (6 / 5 - 5 / 2 : ℚ) ^ 2 + (12 / 5 - 3 / 2) ^ 2 = 10 / 4 ∧
    (2 - 5 / 2 : ℚ) ^ 2 + (0 - 3 / 2) ^ 2 = 10 / 4 ∧
    -- midpoints to H (1, 1), (4, 1), (2, 3)
    (1 - 5 / 2 : ℚ) ^ 2 + (1 - 3 / 2) ^ 2 = 10 / 4 ∧
    (4 - 5 / 2 : ℚ) ^ 2 + (1 - 3 / 2) ^ 2 = 10 / 4 ∧
    (2 - 5 / 2 : ℚ) ^ 2 + (3 - 3 / 2) ^ 2 = 10 / 4 := by norm_num

#print axioms three_centroid_sub_two_circumcenter_is_orthocenter_on_euler_line
#print axioms dist_orthocenter_centroid_eq_two_mul_dist_centroid_circumcenter
#print axioms nine_points_on_circle_midpoint_OH_half_circumradius
