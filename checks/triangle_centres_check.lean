-- Triangle centres: for three points not in a row, the perpendicular bisectors meet at exactly one point, the angle bisectors meet at the weighted average of the corners, at distance area over half-perimeter from every side, and the centroid sits two-thirds along every median and has the least total of squared distances.
import Mathlib.Geometry.Euclidean.PerpBisector
import Mathlib.Geometry.Euclidean.Angle.Unoriented.Affine
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Convex.Combination
import Mathlib.Topology.MetricSpace.HausdorffDistance
import Mathlib.Tactic.NormNum.RealSqrt
import Mathlib.Geometry.Euclidean.Circumcenter

open EuclideanGeometry AffineSubspace

/-- The plane, with ordinary straight-line distance. -/
local notation "Plane" => EuclideanSpace ℝ (Fin 2)

/-- Twice the signed area of the triangle X Y P. -/
noncomputable def tcCross (X Y P : Plane) : ℝ :=
  (Y 0 - X 0) * (P 1 - X 1) - (Y 1 - X 1) * (P 0 - X 0)

#print axioms tcCross

lemma tc_dist_eq (P Q : Plane) : dist P Q = √((P 0 - Q 0) ^ 2 + (P 1 - Q 1) ^ 2) := by
  rw [EuclideanSpace.dist_eq, Fin.sum_univ_two, Real.dist_eq, Real.dist_eq, sq_abs, sq_abs]

#print axioms tc_dist_eq

lemma tc_dist_sq (P Q : Plane) : dist P Q ^ 2 = (P 0 - Q 0) ^ 2 + (P 1 - Q 1) ^ 2 := by
  rw [tc_dist_eq, Real.sq_sqrt (by positivity)]

#print axioms tc_dist_sq

lemma tc_ext (P Q : Plane) (h0 : P 0 = Q 0) (h1 : P 1 = Q 1) : P = Q := by
  ext i; fin_cases i <;> simp [h0, h1]

#print axioms tc_ext

lemma tc_collinear (A B C : Plane) (h : tcCross A B C = 0) :
    Collinear ℝ ({A, B, C} : Set Plane) := by
  by_cases hBC : B = C
  · subst hBC
    simp [collinear_pair]
  · apply collinear_insert_of_mem_affineSpan_pair
    have hn : 0 < (B 0 - C 0) ^ 2 + (B 1 - C 1) ^ 2 := by
      rw [← tc_dist_sq]; exact pow_pos (dist_pos.2 hBC) 2
    rw [mem_affineSpan_pair_iff_exists_lineMap_eq]
    refine ⟨((A 0 - B 0) * (C 0 - B 0) + (A 1 - B 1) * (C 1 - B 1)) /
      ((B 0 - C 0) ^ 2 + (B 1 - C 1) ^ 2), ?_⟩
    unfold tcCross at h
    apply tc_ext <;> simp [AffineMap.lineMap_apply_module] <;> field_simp
    · linear_combination (C 1 - B 1) * h
    · linear_combination (B 0 - C 0) * h

#print axioms tc_collinear

lemma tc_infDist_line (X Y P : Plane) (hXY : X ≠ Y) :
    Metric.infDist P (line[ℝ, X, Y] : Set Plane) = |tcCross X Y P| / dist X Y := by
  have hn : 0 < (X 0 - Y 0) ^ 2 + (X 1 - Y 1) ^ 2 := by
    rw [← tc_dist_sq]; exact pow_pos (dist_pos.2 hXY) 2
  have hd : |tcCross X Y P| / dist X Y =
      √(tcCross X Y P ^ 2 / ((X 0 - Y 0) ^ 2 + (X 1 - Y 1) ^ 2)) := by
    rw [Real.sqrt_div' _ hn.le, Real.sqrt_sq_eq_abs, tc_dist_eq]
  rw [hd]
  apply le_antisymm
  · set t := ((Y 0 - X 0) * (P 0 - X 0) + (Y 1 - X 1) * (P 1 - X 1)) /
      ((X 0 - Y 0) ^ 2 + (X 1 - Y 1) ^ 2)
    refine (Metric.infDist_le_dist_of_mem (AffineMap.lineMap_mem_affineSpan_pair t X Y)).trans
      (le_of_eq ?_)
    rw [tc_dist_eq]
    congr 1
    simp only [AffineMap.lineMap_apply_module, t, tcCross]
    simp
    field_simp
    ring
  · rw [Metric.le_infDist ⟨X, left_mem_affineSpan_pair ℝ X Y⟩]
    intro Q hQ
    rw [SetLike.mem_coe, mem_affineSpan_pair_iff_exists_lineMap_eq] at hQ
    obtain ⟨r, rfl⟩ := hQ
    rw [tc_dist_eq]
    apply Real.sqrt_le_sqrt
    rw [div_le_iff₀ hn]
    simp [AffineMap.lineMap_apply_module, tcCross]
    nlinarith [sq_nonneg ((Y 0 - X 0) * (P 0 - ((1 - r) * X 0 + r * Y 0)) +
      (Y 1 - X 1) * (P 1 - ((1 - r) * X 1 + r * Y 1)))]

#print axioms tc_infDist_line

lemma tc_angle_bisect {V : Type*} [NormedAddCommGroup V] [InnerProductSpace ℝ V]
    (u v : V) (p q k : ℝ) (hu : ‖u‖ = q) (hv : ‖v‖ = p) (hq : q ≠ 0) (hp : p ≠ 0) :
    InnerProductGeometry.angle u (k • (p • u + q • v)) =
      InnerProductGeometry.angle (k • (p • u + q • v)) v := by
  unfold InnerProductGeometry.angle
  congr 1
  set w := k • (p • u + q • v)
  have h1 : inner ℝ u w = k * q * (p * q + inner ℝ u v) := by
    simp only [w, inner_smul_right, inner_add_right, real_inner_self_eq_norm_sq, hu]; ring
  have h2 : inner ℝ w v = k * p * (p * q + inner ℝ u v) := by
    simp only [w, inner_smul_left, inner_add_left, real_inner_self_eq_norm_sq, hv,
      RCLike.conj_to_real]; ring
  rw [h1, h2, hu, hv]
  by_cases hw : ‖w‖ = 0
  · simp [hw]
  · field_simp

#print axioms tc_angle_bisect

lemma tc_mem_hull (A B C P : Plane) (α β γ : ℝ) (ha : 0 ≤ α) (hb : 0 ≤ β) (hc : 0 ≤ γ)
    (hs : α + β + γ = 1) (hP : P = α • A + β • B + γ • C) :
    P ∈ convexHull ℝ ({A, B, C} : Set Plane) := by
  have := (convex_convexHull ℝ ({A, B, C} : Set Plane)).sum_mem (t := Finset.univ)
    (w := ![α, β, γ]) (z := ![A, B, C]) (by intro i _; fin_cases i <;> simpa)
    (by simpa [Fin.sum_univ_three] using hs)
    (by intro i _; fin_cases i <;> exact subset_convexHull ℝ _ (by simp))
  simpa [Fin.sum_univ_three, hP] using this

#print axioms tc_mem_hull

lemma tc_cross_comb (X Y x y : Plane) (a b : ℝ) (hab : a + b = 1) :
    tcCross X Y (a • x + b • y) = a * tcCross X Y x + b * tcCross X Y y := by
  obtain rfl : b = 1 - a := by linarith
  simp [tcCross]; ring

#print axioms tc_cross_comb

lemma tc_hull_sign (A B C : Plane) :
    convexHull ℝ ({A, B, C} : Set Plane) ⊆
      {P | 0 ≤ tcCross B C P * tcCross A B C ∧ 0 ≤ tcCross C A P * tcCross A B C ∧
        0 ≤ tcCross A B P * tcCross A B C} := by
  apply convexHull_min
  · intro P hP
    simp only [Set.mem_insert_iff, Set.mem_singleton_iff] at hP
    rcases hP with h | h | h <;> rw [h] <;> simp only [Set.mem_ofPred_eq, tcCross] <;>
      refine ⟨?_, ?_, ?_⟩ <;>
      nlinarith [sq_nonneg ((B 0 - A 0) * (C 1 - A 1) - (B 1 - A 1) * (C 0 - A 0))]
  · intro x hx y hy a b ha hb hab
    simp only [Set.mem_ofPred_eq, tc_cross_comb _ _ _ _ _ _ hab] at hx hy ⊢
    refine ⟨?_, ?_, ?_⟩ <;> nlinarith [mul_nonneg ha hx.1, mul_nonneg hb hy.1,
      mul_nonneg ha hx.2.1, mul_nonneg hb hy.2.1, mul_nonneg ha hx.2.2, mul_nonneg hb hy.2.2]

#print axioms tc_hull_sign

/-- The circumcentre. For three farms A, B and C on flat ground that are not in a row, the three
perpendicular bisectors (the points equally far from two of the farms) meet at exactly one point:
the one point equally far from all three farms. -/
theorem perpendicular_bisectors_meet_at_one_point (A B C : Plane)
    (h : ¬ Collinear ℝ ({A, B, C} : Set Plane)) :
    ∃! O : Plane, O ∈ perpBisector A B ∧ O ∈ perpBisector B C ∧ O ∈ perpBisector C A := by
  have hD : tcCross A B C ≠ 0 := fun h0 => h (tc_collinear A B C h0)
  have hind : AffineIndependent ℝ ![A, B, C] := affineIndependent_iff_not_collinear_set.2 h
  let T : Affine.Simplex ℝ Plane 2 := ⟨![A, B, C], hind⟩
  have hA : dist T.circumcenter A = T.circumradius := by
    rw [dist_comm]; exact T.dist_circumcenter_eq_circumradius 0
  have hB : dist T.circumcenter B = T.circumradius := by
    rw [dist_comm]; exact T.dist_circumcenter_eq_circumradius 1
  have hC : dist T.circumcenter C = T.circumradius := by
    rw [dist_comm]; exact T.dist_circumcenter_eq_circumradius 2
  refine ⟨T.circumcenter, ?_, ?_⟩
  · simp only [mem_perpBisector_iff_dist_eq]
    exact ⟨by rw [hA, hB], by rw [hB, hC], by rw [hC, hA]⟩
  · rintro O' ⟨e1, e2, -⟩
    rw [mem_perpBisector_iff_dist_eq] at e1 e2
    set O := T.circumcenter
    have f1 : dist O' A ^ 2 = dist O' B ^ 2 := by rw [e1]
    have f2 : dist O' B ^ 2 = dist O' C ^ 2 := by rw [e2]
    have g1 : dist O A ^ 2 = dist O B ^ 2 := by rw [hA, hB]
    have g2 : dist O B ^ 2 = dist O C ^ 2 := by rw [hB, hC]
    rw [tc_dist_sq, tc_dist_sq] at f1 f2 g1 g2
    have E1 : (O' 0 - O 0) * (B 0 - A 0) + (O' 1 - O 1) * (B 1 - A 1) = 0 := by
      linear_combination (f1 - g1) / 2
    have E2 : (O' 0 - O 0) * (C 0 - B 0) + (O' 1 - O 1) * (C 1 - B 1) = 0 := by
      linear_combination (f2 - g2) / 2
    have hx : (O' 0 - O 0) * tcCross A B C = 0 := by
      unfold tcCross; linear_combination (C 1 - B 1) * E1 - (B 1 - A 1) * E2
    have hy : (O' 1 - O 1) * tcCross A B C = 0 := by
      unfold tcCross; linear_combination (B 0 - A 0) * E2 - (C 0 - B 0) * E1
    apply tc_ext
    · exact sub_eq_zero.1 ((mul_eq_zero.1 hx).resolve_right hD)
    · exact sub_eq_zero.1 ((mul_eq_zero.1 hy).resolve_right hD)

/-- The incentre. For three farms not in a row, name each road by the farm it faces:
a = |BC|, b = |CA|, c = |AB|. Let K be the area (half base times height, base AB) and
s = (a + b + c) / 2 half the perimeter. The point I = (aA + bB + cC) / (a + b + c) lies inside
the triangle, on all three angle bisectors, at distance K / s from every road, and no point of
the triangle is more than K / s from its nearest road, so the largest pond has radius K / s. -/
theorem angle_bisectors_meet_at_incentre (A B C : Plane)
    (h : ¬ Collinear ℝ ({A, B, C} : Set Plane)) :
    let a := dist B C
    let b := dist C A
    let c := dist A B
    let s := (a + b + c) / 2
    let K := c * Metric.infDist C (line[ℝ, A, B] : Set Plane) / 2
    let I : Plane := (a + b + c)⁻¹ • (a • A + b • B + c • C)
    I ∈ interior (convexHull ℝ ({A, B, C} : Set Plane)) ∧
    (∠ B A I = ∠ I A C ∧ ∠ C B I = ∠ I B A ∧ ∠ A C I = ∠ I C B) ∧
    (Metric.infDist I (line[ℝ, B, C] : Set Plane) = K / s ∧
      Metric.infDist I (line[ℝ, C, A] : Set Plane) = K / s ∧
      Metric.infDist I (line[ℝ, A, B] : Set Plane) = K / s) ∧
    ∀ P ∈ convexHull ℝ ({A, B, C} : Set Plane),
      min (Metric.infDist P (line[ℝ, B, C] : Set Plane))
        (min (Metric.infDist P (line[ℝ, C, A] : Set Plane))
          (Metric.infDist P (line[ℝ, A, B] : Set Plane))) ≤ K / s := by
  intro a b c s K I
  have hD : tcCross A B C ≠ 0 := fun h0 => h (tc_collinear A B C h0)
  have hAB : A ≠ B := by rintro rfl; exact hD (by unfold tcCross; ring)
  have hBC : B ≠ C := by rintro rfl; exact hD (by unfold tcCross; ring)
  have hCA : C ≠ A := by rintro rfl; exact hD (by unfold tcCross; ring)
  have ha : 0 < a := dist_pos.2 hBC
  have hb : 0 < b := dist_pos.2 hCA
  have hc : 0 < c := dist_pos.2 hAB
  have hS : 0 < a + b + c := by positivity
  have hI0 : I 0 = (a + b + c)⁻¹ * (a * A 0 + b * B 0 + c * C 0) := by simp [I]; ring
  have hI1 : I 1 = (a + b + c)⁻¹ * (a * A 1 + b * B 1 + c * C 1) := by simp [I]; ring
  have hIa : tcCross B C I = a * tcCross A B C / (a + b + c) := by
    unfold tcCross; rw [hI0, hI1]; field_simp; ring
  have hIb : tcCross C A I = b * tcCross A B C / (a + b + c) := by
    unfold tcCross; rw [hI0, hI1]; field_simp; ring
  have hIc : tcCross A B I = c * tcCross A B C / (a + b + c) := by
    unfold tcCross; rw [hI0, hI1]; field_simp; ring
  have hKs : K / s = |tcCross A B C| / (a + b + c) := by
    simp only [K, s]
    rw [tc_infDist_line A B C hAB, show dist A B = c from rfl]
    field_simp
  refine ⟨?_, ?_, ?_, ?_⟩
  · -- I is inside the triangle
    have hU : IsOpen {P : Plane | 0 < tcCross B C P * tcCross A B C ∧
        0 < tcCross C A P * tcCross A B C ∧ 0 < tcCross A B P * tcCross A B C} := by
      simp only [Set.ofPred_and]
      unfold tcCross
      refine IsOpen.inter (isOpen_lt continuous_const (by fun_prop))
        (IsOpen.inter (isOpen_lt continuous_const (by fun_prop))
          (isOpen_lt continuous_const (by fun_prop)))
    have hsub : {P : Plane | 0 < tcCross B C P * tcCross A B C ∧
        0 < tcCross C A P * tcCross A B C ∧ 0 < tcCross A B P * tcCross A B C} ⊆
        convexHull ℝ ({A, B, C} : Set Plane) := by
      rintro P ⟨p1, p2, p3⟩
      have nn : ∀ x : ℝ, 0 < x * tcCross A B C → 0 ≤ x / tcCross A B C := by
        intro x hx
        rw [← mul_div_mul_right x _ hD]
        exact div_nonneg hx.le (mul_self_nonneg _)
      have k0 : tcCross B C P * A 0 + tcCross C A P * B 0 + tcCross A B P * C 0 =
          tcCross A B C * P 0 := by unfold tcCross; ring
      have k1 : tcCross B C P * A 1 + tcCross C A P * B 1 + tcCross A B P * C 1 =
          tcCross A B C * P 1 := by unfold tcCross; ring
      have ks : tcCross B C P + tcCross C A P + tcCross A B P = tcCross A B C := by
        unfold tcCross; ring
      apply tc_mem_hull A B C P _ _ _ (nn _ p1) (nn _ p2) (nn _ p3)
      · field_simp; linear_combination ks
      · apply tc_ext
        · simp; field_simp; linear_combination -k0
        · simp; field_simp; linear_combination -k1
    apply interior_maximal hsub hU
    have hDD : 0 < tcCross A B C * tcCross A B C := mul_self_pos.2 hD
    refine ⟨?_, ?_, ?_⟩
    · rw [hIa, div_mul_eq_mul_div, mul_assoc]; positivity
    · rw [hIb, div_mul_eq_mul_div, mul_assoc]; positivity
    · rw [hIc, div_mul_eq_mul_div, mul_assoc]; positivity
  · -- I lies on the three angle bisectors
    have hS0 : a + b + c ≠ 0 := hS.ne'
    have vA : I -ᵥ A = (a + b + c)⁻¹ • (b • (B -ᵥ A) + c • (C -ᵥ A)) := by
      apply tc_ext <;> simp [I] <;> field_simp <;> ring
    have vB : I -ᵥ B = (a + b + c)⁻¹ • (c • (C -ᵥ B) + a • (A -ᵥ B)) := by
      apply tc_ext <;> simp [I] <;> field_simp <;> ring
    have vC : I -ᵥ C = (a + b + c)⁻¹ • (a • (A -ᵥ C) + b • (B -ᵥ C)) := by
      apply tc_ext <;> simp [I] <;> field_simp <;> ring
    refine ⟨?_, ?_, ?_⟩
    · unfold EuclideanGeometry.angle
      rw [vA]
      exact tc_angle_bisect _ _ _ _ _ ((dist_eq_norm_vsub _ B A).symm.trans (dist_comm B A))
        (dist_eq_norm_vsub _ C A).symm hc.ne' hb.ne'
    · unfold EuclideanGeometry.angle
      rw [vB]
      exact tc_angle_bisect _ _ _ _ _ ((dist_eq_norm_vsub _ C B).symm.trans (dist_comm C B))
        (dist_eq_norm_vsub _ A B).symm ha.ne' hc.ne'
    · unfold EuclideanGeometry.angle
      rw [vC]
      exact tc_angle_bisect _ _ _ _ _ ((dist_eq_norm_vsub _ A C).symm.trans (dist_comm A C))
        (dist_eq_norm_vsub _ B C).symm hb.ne' ha.ne'
  · -- I is at distance K / s from each road
    rw [hKs, tc_infDist_line B C I hBC, tc_infDist_line C A I hCA, tc_infDist_line A B I hAB,
      show dist B C = a from rfl, show dist C A = b from rfl, show dist A B = c from rfl,
      hIa, hIb, hIc]
    refine ⟨?_, ?_, ?_⟩ <;>
      rw [abs_div, abs_mul, abs_of_pos hS] <;> first
        | rw [abs_of_pos ha]; field_simp
        | rw [abs_of_pos hb]; field_simp
        | rw [abs_of_pos hc]; field_simp
  · -- no point of the triangle is farther than K / s from its nearest road
    intro P hP
    obtain ⟨p1, p2, p3⟩ := tc_hull_sign A B C hP
    rw [tc_infDist_line B C P hBC, tc_infDist_line C A P hCA, tc_infDist_line A B P hAB, hKs]
    by_contra hcon
    rw [not_le] at hcon
    simp only [lt_min_iff] at hcon
    obtain ⟨q1, q2, q3⟩ := hcon
    rw [div_lt_div_iff₀ hS ha] at q1
    rw [div_lt_div_iff₀ hS hb] at q2
    rw [div_lt_div_iff₀ hS hc] at q3
    have hDpos : 0 < |tcCross A B C| := abs_pos.2 hD
    have m1 := mul_lt_mul_of_pos_right q1 hDpos
    have m2 := mul_lt_mul_of_pos_right q2 hDpos
    have m3 := mul_lt_mul_of_pos_right q3 hDpos
    have r1 : |tcCross B C P| * |tcCross A B C| = tcCross B C P * tcCross A B C := by
      rw [← abs_mul, abs_of_nonneg p1]
    have r2 : |tcCross C A P| * |tcCross A B C| = tcCross C A P * tcCross A B C := by
      rw [← abs_mul, abs_of_nonneg p2]
    have r3 : |tcCross A B P| * |tcCross A B C| = tcCross A B P * tcCross A B C := by
      rw [← abs_mul, abs_of_nonneg p3]
    have ks : tcCross B C P + tcCross C A P + tcCross A B P = tcCross A B C := by
      unfold tcCross; ring
    have hD2 : |tcCross A B C| * |tcCross A B C| = tcCross A B C * tcCross A B C :=
      abs_mul_abs_self _
    have t1 : |tcCross B C P| * (a + b + c) * |tcCross A B C| =
        (a + b + c) * (tcCross B C P * tcCross A B C) := by linear_combination (a + b + c) * r1
    have t2 : |tcCross C A P| * (a + b + c) * |tcCross A B C| =
        (a + b + c) * (tcCross C A P * tcCross A B C) := by linear_combination (a + b + c) * r2
    have t3 : |tcCross A B P| * (a + b + c) * |tcCross A B C| =
        (a + b + c) * (tcCross A B P * tcCross A B C) := by linear_combination (a + b + c) * r3
    have hs2 : (a + b + c) * (tcCross B C P * tcCross A B C) +
        (a + b + c) * (tcCross C A P * tcCross A B C) +
        (a + b + c) * (tcCross A B P * tcCross A B C) =
        (a + b + c) * (tcCross A B C * tcCross A B C) := by
      linear_combination (a + b + c) * tcCross A B C * ks
    have e : |tcCross A B C| * a * |tcCross A B C| + |tcCross A B C| * b * |tcCross A B C| +
        |tcCross A B C| * c * |tcCross A B C| = (a + b + c) * (tcCross A B C * tcCross A B C) := by
      linear_combination (a + b + c) * hD2
    linarith [m1, m2, m3, t1, t2, t3, hs2, e]

/-- The centroid. For any three corners, the average G = (A + B + C) / 3 is two-thirds of the
way from each corner to the midpoint of the opposite side, so it lies on all three medians; and
for every point P, the total of squared distances from P to the corners is 3|P − G|² plus the
same total at G, so that total is smallest at G. -/
theorem centroid_on_medians_and_least_squares (A B C : Plane) :
    let G : Plane := (1 / 3 : ℝ) • (A + B + C)
    (A + (2 / 3 : ℝ) • (midpoint ℝ B C - A) = G ∧
      B + (2 / 3 : ℝ) • (midpoint ℝ C A - B) = G ∧
      C + (2 / 3 : ℝ) • (midpoint ℝ A B - C) = G) ∧
    ∀ P : Plane, dist P A ^ 2 + dist P B ^ 2 + dist P C ^ 2 =
      3 * dist P G ^ 2 + (dist G A ^ 2 + dist G B ^ 2 + dist G C ^ 2) := by
  intro G
  refine ⟨⟨?_, ?_, ?_⟩, ?_⟩
  · apply tc_ext <;> simp [G, midpoint_eq_smul_add] <;> ring
  · apply tc_ext <;> simp [G, midpoint_eq_smul_add] <;> ring
  · apply tc_ext <;> simp [G, midpoint_eq_smul_add] <;> ring
  · intro P
    simp only [tc_dist_sq]
    simp [G]
    ring

-- Farms A (0, 0), B (8, 0), C (2, 6). The centroid averages the corners: (10/3, 2).
example : ((0 : ℚ) + 8 + 2) / 3 = 10 / 3 ∧ ((0 : ℚ) + 0 + 6) / 3 = 2 := by norm_num
-- From farm A, the median reaches the midpoint (5, 3); two-thirds of the way is (10/3, 2).
example : (0 : ℚ) + 2 / 3 * (5 - 0) = 10 / 3 ∧ (0 : ℚ) + 2 / 3 * (3 - 0) = 2 := by norm_num
-- Bisector of A and B: 16x = 64, so x = 4. Bisector of A and C: 4x + 12y = 40, so y = 2.
example : (16 : ℤ) * 4 = 64 ∧ (4 : ℤ) * 4 + 12 * 2 = 40 := by decide
-- O = (4, 2) is equally far from all three farms: squared distance 20 to each.
example : dist (!₂[4, 2] : Plane) !₂[0, 0] = dist (!₂[4, 2] : Plane) !₂[8, 0] ∧
    dist (!₂[4, 2] : Plane) !₂[8, 0] = dist (!₂[4, 2] : Plane) !₂[2, 6] := by
  simp [EuclideanSpace.dist_eq, Real.dist_eq]; norm_num
example : ((4 : ℤ) - 0) ^ 2 + (2 - 0) ^ 2 = 20 ∧ ((4 : ℤ) - 8) ^ 2 + (2 - 0) ^ 2 = 20 ∧
    ((4 : ℤ) - 2) ^ 2 + (2 - 6) ^ 2 = 20 := by decide
-- The area is 8 × 6 / 2 = 24 square km.
example : (8 : ℕ) * 6 / 2 = 24 := by decide
-- Total of squared distances: 176/3 (58.67) at G, against 60 at O.
example : ((10 / 3 : ℚ) ^ 2 + 2 ^ 2) + ((10 / 3 - 8) ^ 2 + 2 ^ 2) + ((10 / 3 - 2) ^ 2 + (2 - 6) ^ 2)
    = 176 / 3 := by norm_num
example : ((4 : ℤ) ^ 2 + 2 ^ 2) + ((4 - 8) ^ 2 + 2 ^ 2) + ((4 - 2) ^ 2 + (2 - 6) ^ 2) = 60 := by
  decide
-- Obtuse farms (0, 0), (8, 0), (2, 2): O = (4, −2), squared distance 20 to each, outside road AB.
example : dist (!₂[4, -2] : Plane) !₂[0, 0] = dist (!₂[4, -2] : Plane) !₂[8, 0] ∧
    dist (!₂[4, -2] : Plane) !₂[8, 0] = dist (!₂[4, -2] : Plane) !₂[2, 2] := by
  simp [EuclideanSpace.dist_eq, Real.dist_eq]; norm_num
-- There a well at the midpoint (4, 0) of road AB needs at most 4 km: 4² = 16 < 20.
example : ((4 : ℤ) - 0) ^ 2 + 0 ^ 2 = 16 ∧ ((4 : ℤ) - 8) ^ 2 + 0 ^ 2 = 16 ∧
    ((4 : ℤ) - 2) ^ 2 + (0 - 2) ^ 2 = 8 ∧ (16 : ℤ) < 20 := by decide

#print axioms perpendicular_bisectors_meet_at_one_point
#print axioms angle_bisectors_meet_at_incentre
#print axioms centroid_on_medians_and_least_squares
