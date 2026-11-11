-- Congruent triangles: in the flat plane, each of the four tests SSS, SAS, ASA and RHS forces two triangles to match in all three sides and all three angles, while SSA and AAA do not.
import Mathlib.Geometry.Euclidean.Triangle
import Mathlib.Geometry.Euclidean.Congruence
import Mathlib.Geometry.Euclidean.Angle.Unoriented.RightAngle
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.LinearAlgebra.AffineSpace.Independent
import Mathlib.Tactic.NormNum

open EuclideanGeometry

/-- The card's definition of `△ABC ≅ △DEF`, partners fixed by the letter order: all six parts
match. Sides AB = DE, BC = EF, CA = FD; angles at A and D, at B and E, at C and F.
`∠ B A C` is the angle at the middle letter, A. Angles are unsigned, so a flipped copy counts. -/
def SixPartsMatch (A B C D E F : EuclideanSpace ℝ (Fin 2)) : Prop :=
  dist A B = dist D E ∧ dist B C = dist E F ∧ dist C A = dist F D ∧
    ∠ B A C = ∠ E D F ∧ ∠ A B C = ∠ D E F ∧ ∠ A C B = ∠ D F E

theorem sixPartsMatch_of_sss (A B C D E F : EuclideanSpace ℝ (Fin 2))
    (h₁ : dist A B = dist D E) (h₂ : dist B C = dist E F) (h₃ : dist C A = dist F D) :
    SixPartsMatch A B C D E F := by
  have h := side_side_side h₁ h₂ h₃
  refine ⟨h₁, h₂, h₃, ?_, ?_, ?_⟩
  · simpa using angle_eq_of_congruent h 1 0 2
  · simpa using angle_eq_of_congruent h 0 1 2
  · simpa using angle_eq_of_congruent h 0 2 1

#print axioms sixPartsMatch_of_sss

theorem affineIndependent_of_det (A B C : EuclideanSpace ℝ (Fin 2))
    (h : (B 0 - A 0) * (C 1 - A 1) - (B 1 - A 1) * (C 0 - A 0) ≠ 0) :
    AffineIndependent ℝ ![A, B, C] := by
  rw [affineIndependent_iff_not_collinear_set]
  intro hcol
  rw [collinear_iff_of_mem (p₀ := A) (by simp)] at hcol
  obtain ⟨v, hv⟩ := hcol
  obtain ⟨r, hr⟩ := hv B (by simp)
  obtain ⟨s, hs⟩ := hv C (by simp)
  apply h
  subst hr hs
  simp
  ring

#print axioms affineIndependent_of_det

/-- Three well-chosen matching parts force the other three to match. Take two genuine
triangles ABC and DEF in the flat plane (corners not on one line), partners in letter order.
Each test on its own makes all six parts match:
SSS, all three sides; SAS, two sides and the angle between them (at A);
ASA, two angles (at A and B) and the side between them; RHS, a right angle at A and D,
the hypotenuse BC facing it, and one other side AB. -/
theorem three_matching_parts_force_congruence (A B C D E F : EuclideanSpace ℝ (Fin 2))
    (hABC : AffineIndependent ℝ ![A, B, C]) (hDEF : AffineIndependent ℝ ![D, E, F]) :
    -- SSS
    ((dist A B = dist D E ∧ dist B C = dist E F ∧ dist C A = dist F D) →
      SixPartsMatch A B C D E F) ∧
    -- SAS
    ((dist A B = dist D E ∧ ∠ B A C = ∠ E D F ∧ dist C A = dist F D) →
      SixPartsMatch A B C D E F) ∧
    -- ASA
    ((∠ B A C = ∠ E D F ∧ dist A B = dist D E ∧ ∠ A B C = ∠ D E F) →
      SixPartsMatch A B C D E F) ∧
    -- RHS
    ((∠ B A C = Real.pi / 2 ∧ ∠ E D F = Real.pi / 2 ∧
        dist B C = dist E F ∧ dist A B = dist D E) →
      SixPartsMatch A B C D E F) := by
  refine ⟨fun ⟨h₁, h₂, h₃⟩ => sixPartsMatch_of_sss A B C D E F h₁ h₂ h₃, ?_, ?_, ?_⟩
  · rintro ⟨h₁, hA, h₃⟩
    have h := side_angle_side hA (by rwa [dist_comm B A, dist_comm E D])
      (by rwa [dist_comm A C, dist_comm D F])
    have h₂ : dist B C = dist E F := by simpa using h.dist_eq 0 2
    exact sixPartsMatch_of_sss A B C D E F h₁ h₂ h₃
  · rintro ⟨hA, h₁, hB⟩
    have hcol : ¬Collinear ℝ ({C, A, B} : Set _) := by
      rw [affineIndependent_iff_not_collinear_set] at hABC
      intro hc; apply hABC
      convert hc using 1
      ext x; simp; tauto
    have h := angle_side_angle hcol (by rwa [angle_comm C A B, angle_comm F D E]) h₁ hB
    have h₃ : dist C A = dist F D := by simpa using h.dist_eq 0 1
    have h₂ : dist B C = dist E F := by simpa using h.dist_eq 2 0
    exact sixPartsMatch_of_sss A B C D E F h₁ h₂ h₃
  · rintro ⟨hA, hD, h₂, h₁⟩
    have p1 := (dist_sq_eq_dist_sq_add_dist_sq_iff_angle_eq_pi_div_two B A C).2 hA
    have p2 := (dist_sq_eq_dist_sq_add_dist_sq_iff_angle_eq_pi_div_two E D F).2 hD
    have h₃ : dist C A = dist F D := by
      have hsq : dist C A * dist C A = dist F D * dist F D := by
        rw [dist_comm B A, dist_comm E D] at *
        rw [h₂, h₁] at p1
        linarith
      nlinarith [dist_nonneg (x := C) (y := A), dist_nonneg (x := F) (y := D)]
    exact sixPartsMatch_of_sss A B C D E F h₁ h₂ h₃

/-- SSA is not a test. There are two genuine triangles in the flat plane with the rail AB, the
stile CA and the angle at B (not between those two sides) all matching, yet the braces BC and
EF have different lengths. On the gate the two braces are 1.700 m and 0.947 m. -/
theorem side_side_angle_is_not_a_test :
    ∃ A B C D E F : EuclideanSpace ℝ (Fin 2),
      AffineIndependent ℝ ![A, B, C] ∧ AffineIndependent ℝ ![D, E, F] ∧
      dist A B = dist D E ∧ dist C A = dist F D ∧ ∠ A B C = ∠ D E F ∧
      dist B C ≠ dist E F := by
  refine ⟨!₂[0, 0], !₂[3/2, 0], !₂[0, 4/5], !₂[0, 0], !₂[3/2, 0], !₂[192/289, 644/1445],
    affineIndependent_of_det _ _ _ (by simp), affineIndependent_of_det _ _ _ (by norm_num),
    rfl, ?_, ?_, ?_⟩
  · simp [EuclideanSpace.dist_eq]
    norm_num
  · apply angle_smul_right_of_pos _ (r := 289 / 161) (by norm_num)
    ext i; fin_cases i <;> simp <;> norm_num
  · have e1 : dist (!₂[3/2, 0] : EuclideanSpace ℝ (Fin 2)) !₂[0, 4/5] = 17 / 10 := by
      rw [EuclideanSpace.dist_eq, Real.sqrt_eq_iff_mul_self_eq_of_pos (by norm_num)]
      simp [Real.dist_eq, sq_abs]
      norm_num
    have e2 : dist (!₂[3/2, 0] : EuclideanSpace ℝ (Fin 2)) !₂[192/289, 644/1445] = 161 / 170 := by
      rw [EuclideanSpace.dist_eq, Real.sqrt_eq_iff_mul_self_eq_of_pos (by norm_num)]
      simp [Real.dist_eq, sq_abs]
      norm_num
    rw [e1, e2]
    norm_num

/-- AAA is not a test. There are two genuine triangles in the flat plane with all three angles
matching, yet their sides differ: angles fix the shape, not the size. On the gate a 0.8-size
copy has a brace 0.340 m short. -/
theorem angle_angle_angle_is_not_a_test :
    ∃ A B C D E F : EuclideanSpace ℝ (Fin 2),
      AffineIndependent ℝ ![A, B, C] ∧ AffineIndependent ℝ ![D, E, F] ∧
      ∠ B A C = ∠ E D F ∧ ∠ A B C = ∠ D E F ∧ ∠ A C B = ∠ D F E ∧
      dist A B ≠ dist D E := by
  set A : EuclideanSpace ℝ (Fin 2) := !₂[0, 0]
  set B : EuclideanSpace ℝ (Fin 2) := !₂[1, 0]
  set C : EuclideanSpace ℝ (Fin 2) := !₂[0, 1]
  have hABC : AffineIndependent ℝ ![A, B, C] :=
    affineIndependent_of_det A B C (by simp [A, B, C])
  set h := AffineMap.homothety A (2 : ℝ)
  refine ⟨A, B, C, h A, h B, h C, hABC, ?_, ?_, ?_, ?_, ?_⟩
  · have hinj : Function.Injective h := by
      intro x y hxy
      simpa [h, AffineMap.homothety_apply] using hxy
    have := hABC.map' h hinj
    convert this using 1
    ext i; fin_cases i <;> rfl
  · exact (angle_homothety A B A C two_ne_zero).symm
  · exact (angle_homothety A A B C two_ne_zero).symm
  · exact (angle_homothety A A C B two_ne_zero).symm
  · rw [show h A = A by simp [h], dist_center_homothety]
    have : dist A B ≠ 0 := by simp [A, B]
    simp
    intro e; apply this; linarith

-- The gate in centimetres: rail 150, stile 80, brace 170 at a square corner.
example : (150 : ℕ) ^ 2 + 80 ^ 2 = 170 ^ 2 := by norm_num
-- Right leaf holes in centimetres: D (320, 0), E (170, 0), F (320, 80); the brace EF is 170.
example : ((320 : ℤ) - 170) ^ 2 + (80 - 0) ^ 2 = 170 ^ 2 := by norm_num
-- Rail and stile swapped: the rail hole misses by 150 - 80 = 70 cm.
example : (150 : ℕ) - 80 = 70 := by norm_num
-- SSA, in metres: the brace line from B (3/2, 0) runs toward C (0, 4/5). The second stile hole
-- (192/289, 644/1445) lies on that line and 4/5 m from the corner A (0, 0).
example : (644 / 1445 : ℚ) * 15 = -8 * (192 / 289 - 3 / 2) := by norm_num
example : (192 / 289 : ℚ) ^ 2 + (644 / 1445) ^ 2 = (4 / 5) ^ 2 := by norm_num
-- Its brace is 161/170 m (about 0.947 m), not 17/10 m.
example : ((192 / 289 : ℚ) - 3 / 2) ^ 2 + (644 / 1445) ^ 2 = (161 / 170) ^ 2 := by norm_num
example : (161 / 170 : ℚ) ≠ 17 / 10 := by norm_num
-- AAA in centimetres: the 0.8-size copy is 120, 64, 136, with the same slope as the gate,
-- and its brace is 34 cm short.
example : (120 : ℕ) ^ 2 + 64 ^ 2 = 136 ^ 2 := by norm_num
example : (64 : ℕ) * 150 = 80 * 120 := by norm_num
example : (170 : ℕ) - 136 = 34 := by norm_num

#print axioms three_matching_parts_force_congruence
#print axioms side_side_angle_is_not_a_test
#print axioms angle_angle_angle_is_not_a_test
