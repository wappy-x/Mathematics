-- Angles at a circle: a spot on a circle sees a chord at half the centre's angle on the far arc, a diameter at a right angle, and a line touching the circle once meets the radius square on.
import Mathlib.Geometry.Euclidean.Angle.Sphere
import Mathlib.Analysis.Convex.Side
import Mathlib.Tactic.NormNum.RealSqrt
import Mathlib.Geometry.Euclidean.Sphere.SecondInter

open EuclideanGeometry Module Real

variable {E Pt : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] [MetricSpace Pt]
  [NormedAddTorsor E Pt]

/-- Helper: in the plane, two points off a line through two different points lie either strictly
on the same side of it or strictly on opposite sides. -/
theorem sSameSide_or_sOppSide_of_finrank_two [Fact (finrank ℝ E = 2)] {A B X Y : Pt}
    (hAB : A ≠ B) (hX : X ∉ line[ℝ, A, B]) (hY : Y ∉ line[ℝ, A, B]) :
    (line[ℝ, A, B]).SSameSide X Y ∨ (line[ℝ, A, B]).SOppSide X Y := by
  have hA : A ∈ line[ℝ, A, B] := left_mem_affineSpan_pair ℝ A B
  have hli : LinearIndependent ℝ ![B -ᵥ A, X -ᵥ A] := by
    rw [LinearIndependent.pair_iff]
    intro a b hab
    by_cases hb : b = 0
    · subst hb
      rw [zero_smul, add_zero] at hab
      rcases smul_eq_zero.mp hab with h | h
      · exact ⟨h, rfl⟩
      · exact absurd (vsub_eq_zero_iff_eq.mp h).symm hAB
    · exfalso
      apply hX
      have h1 : b • (X -ᵥ A) = -(a • (B -ᵥ A)) := eq_neg_of_add_eq_zero_right hab
      have h2 : X -ᵥ A = (-a / b) • (B -ᵥ A) := by
        rw [← inv_smul_smul₀ hb (X -ᵥ A), h1, smul_neg, smul_smul, ← neg_smul]
        congr 1
        ring
      rw [(eq_vadd_iff_vsub_eq X _ A).mpr h2]
      exact smul_vsub_vadd_mem_affineSpan_pair _ _ _
  have hspan : Submodule.span ℝ (Set.range ![B -ᵥ A, X -ᵥ A]) = ⊤ :=
    hli.span_eq_top_of_card_eq_finrank (by simp [(Fact.out : finrank ℝ E = 2)])
  obtain ⟨a, b, hab⟩ : ∃ a b : ℝ, a • (B -ᵥ A) + b • (X -ᵥ A) = Y -ᵥ A := by
    have hmem : Y -ᵥ A ∈ Submodule.span ℝ (Set.range ![B -ᵥ A, X -ᵥ A]) :=
      hspan ▸ Submodule.mem_top
    rw [Matrix.range_cons, Matrix.range_cons, Matrix.range_empty, Set.union_empty,
      Set.singleton_union, Submodule.mem_span_pair] at hmem
    exact hmem
  have hP : a • (B -ᵥ A) +ᵥ A ∈ line[ℝ, A, B] := smul_vsub_vadd_mem_affineSpan_pair _ _ _
  have hYP : Y -ᵥ (a • (B -ᵥ A) +ᵥ A) = b • (X -ᵥ A) := by
    rw [vsub_vadd_eq_vsub_sub, ← hab, add_sub_cancel_left]
  rcases lt_trichotomy b 0 with hb | hb | hb
  · right
    rw [AffineSubspace.sOppSide_iff_exists_left hA]
    refine ⟨hX, hY, _, hP, ?_⟩
    rw [← neg_vsub_eq_vsub_rev Y, hYP, ← neg_smul]
    exact SameRay.sameRay_nonneg_smul_right _ (by linarith)
  · exfalso
    apply hY
    rw [hb, zero_smul, vsub_eq_zero_iff_eq] at hYP
    rw [hYP]
    exact hP
  · left
    rw [AffineSubspace.sSameSide_iff_exists_left hA]
    refine ⟨hX, hY, _, hP, ?_⟩
    rw [hYP]
    exact SameRay.sameRay_nonneg_smul_right _ hb.le

open scoped Module.Oriented.Arbitrary in
/-- Helper: the inscribed-angle rule, proved with an arbitrary orientation of the plane. -/
theorem inscribed_angle_aux [Fact (finrank ℝ E = 2)] {s : Sphere Pt}
    {A B V : Pt} (hA : A ∈ s) (hB : B ∈ s) (hV : V ∈ s) (hAB : A ≠ B) (hVA : V ≠ A)
    (hVB : V ≠ B) :
    (¬ (line[ℝ, A, B]).SOppSide V s.center → ∠ A V B = ∠ A s.center B / 2) ∧
      ((line[ℝ, A, B]).SOppSide V s.center → ∠ A V B = (2 * π - ∠ A s.center B) / 2) := by
  have : FiniteDimensional ℝ E := .of_fact_finrank_eq_two
  have hAl : A ∈ line[ℝ, A, B] := left_mem_affineSpan_pair ℝ A B
  have hBl : B ∈ line[ℝ, A, B] := right_mem_affineSpan_pair ℝ A B
  have hAOB : ∡ A s.center B = (2 : ℤ) • ∡ A V B :=
    Sphere.oangle_center_eq_two_zsmul_oangle hA hV hB hVA hVB
  have hang : ∠ A V B = |(∡ A V B).toReal| := angle_eq_abs_oangle_toReal hVA.symm hVB.symm
  have hcos : Cospherical ({A, V, B} : Set Pt) := by
    refine ⟨s.center, s.radius, ?_⟩
    intro p hp
    simp only [Set.mem_insert_iff, Set.mem_singleton_iff] at hp
    rcases hp with rfl | rfl | rfl
    · exact mem_sphere.mp hA
    · exact mem_sphere.mp hV
    · exact mem_sphere.mp hB
  have hind := hcos.affineIndependent_of_ne hVA.symm hAB hVB
  have hθ0 : (∡ A V B).sign ≠ 0 := by
    rw [Ne, oangle_sign_eq_zero_iff_collinear]
    exact affineIndependent_iff_not_collinear_set.mp hind
  have hVline : V ∉ line[ℝ, A, B] := by
    intro h
    have hc := collinear_insert_of_mem_affineSpan_pair h
    rw [Set.insert_comm] at hc
    exact affineIndependent_iff_not_collinear_set.mp hind hc
  constructor
  · intro hn
    have h2 : 2 * ∠ A V B ≤ π := by
      by_contra hlt
      rw [not_le] at hlt
      have hbig : π / 2 < |(∡ A V B).toReal| := by rw [← hang]; linarith
      have hsgn : (∡ A s.center B).sign = -(∡ A V B).sign := by
        rw [hAOB]
        exact Real.Angle.sign_two_zsmul_eq_neg_sign_iff.mpr (Or.inr hbig)
      have hO : s.center ∉ line[ℝ, A, B] := by
        intro h
        have hc := collinear_insert_of_mem_affineSpan_pair h
        rw [Set.insert_comm] at hc
        have h0 := (oangle_sign_eq_zero_iff_collinear).mpr hc
        rw [hsgn] at h0
        exact hθ0 (by simpa using h0)
      rcases sSameSide_or_sOppSide_of_finrank_two hAB hVline hO with hss | hos
      · have h3 := hss.oangle_sign_eq hAl hBl
        rw [hsgn] at h3
        exact hθ0 (SignType.neg_eq_self_iff.mp h3)
      · exact hn hos
    have := Sphere.angle_center_eq_two_mul_angle_of_two_mul_angle_le_pi hA hV hB hVA hVB h2
    linarith
  · intro hopp
    have hs := hopp.oangle_sign_eq_neg hAl hBl
    rw [hAOB, Real.Angle.sign_two_zsmul_eq_neg_sign_iff] at hs
    have hbig : π / 2 < |(∡ A V B).toReal| := by
      rcases hs with h | h
      · exfalso
        rw [h, Real.Angle.sign_zero] at hθ0
        exact hθ0 rfl
      · exact h
    have h2 : π ≤ 2 * ∠ A V B := by rw [hang]; linarith
    have := Sphere.angle_center_eq_two_pi_sub_two_mul_angle_of_pi_le_two_mul_angle hA hV hB hVA
      hVB h2
    linarith

#print axioms sSameSide_or_sOppSide_of_finrank_two
#print axioms inscribed_angle_aux

/-- The inscribed-angle rule. A, B and the camera V lie on one circle in the plane, V away from
A and B. The angle at V between A and B is half the angle at the centre O on the arc from A to B
that does not hold V. When V and O are on the same side of the chord AB (or O is on it), that
arc's centre angle is the ordinary angle AOB; when O is on the other side, the arc goes the long
way round and its centre angle is 360° (2π) minus angle AOB. -/
theorem inscribed_angle_is_half_central_angle [Fact (finrank ℝ E = 2)] {s : Sphere Pt}
    {A B V : Pt} (hA : A ∈ s) (hB : B ∈ s) (hV : V ∈ s) (hAB : A ≠ B) (hVA : V ≠ A)
    (hVB : V ≠ B) :
    (¬ (line[ℝ, A, B]).SOppSide V s.center → ∠ A V B = ∠ A s.center B / 2) ∧
      ((line[ℝ, A, B]).SOppSide V s.center → ∠ A V B = (2 * π - ∠ A s.center B) / 2) := by
  exact inscribed_angle_aux hA hB hV hAB hVA hVB

/-- Thales' theorem. When A and B are the two ends of a diameter, every other spot V on the
circle sees them at a right angle (90°, π/2). -/
theorem diameter_seen_at_right_angle [Fact (finrank ℝ E = 2)] {s : Sphere Pt} {A B V : Pt}
    (hd : s.IsDiameter A B) (hV : V ∈ s) (hVA : V ≠ A) (hVB : V ≠ B) :
    ∠ A V B = π / 2 := by
  exact (Sphere.angle_eq_pi_div_two_iff_mem_sphere_of_isDiameter hd).mpr hV

/-- The tangent meets the radius square on. A straight line through T, a point of the circle,
and another point X, which meets the circle at T only, makes a right angle with the radius OT. -/
theorem tangent_meets_radius_at_right_angle [Fact (finrank ℝ E = 2)] {s : Sphere Pt} {T X : Pt}
    (hT : T ∈ s) (hXT : X ≠ T) (honly : ∀ Y ∈ line[ℝ, T, X], Y ∈ s → Y = T) :
    ∠ s.center T X = π / 2 := by
  have hY := s.secondInter_vsub_mem_affineSpan T X
  have hYs : s.secondInter T (X -ᵥ T) ∈ s := (Sphere.secondInter_mem _).mpr hT
  have heq := honly _ hY hYs
  rw [Sphere.secondInter_eq_self_iff] at heq
  rw [EuclideanGeometry.angle, ← InnerProductGeometry.inner_eq_zero_iff_angle_eq_pi_div_two,
    ← neg_vsub_eq_vsub_rev T s.center, inner_neg_left, real_inner_comm, heq, neg_zero]

-- 90° lens: the 12 m stage is the diameter, so the half-circle has radius 6 m round M.
example : (12 : ℝ) / 2 = 6 := by norm_num
-- 60° lens: the centre angle is twice the rim angle, 120°.
example : (2 : ℕ) * 60 = 120 := by decide
-- The aisle, a = 4 m and b = 16 m: radius (a + b) / 2 = 10 m, and M to B is (b - a) / 2 = 6 m.
example : ((4 : ℝ) + 16) / 2 = 10 ∧ ((16 : ℝ) - 4) / 2 = 6 := by norm_num
-- Their squares differ by a × b, so t = √(10² − 6²) = √(4 × 16) = 8 m back.
example : (10 : ℝ) ^ 2 - 6 ^ 2 = 4 * 16 := by norm_num
example : Real.sqrt ((10 : ℝ) ^ 2 - 6 ^ 2) = 8 ∧ Real.sqrt ((4 : ℝ) * 16) = 8 := by norm_num
-- Triangle OMB, sides 6, 8 and 10 m, is the 3, 4, 5 triangle doubled.
example : (6 : ℕ) ^ 2 + 8 ^ 2 = 10 ^ 2 ∧ 6 = 2 * 3 ∧ 8 = 2 * 4 ∧ 10 = 2 * 5 := by decide
-- The mistake: the average spot, (4 + 16) / 2 = 10 m, is not the best spot, 8 m.
example : ((4 : ℝ) + 16) / 2 ≠ Real.sqrt (4 * 16) := by norm_num

#print axioms inscribed_angle_is_half_central_angle
#print axioms diameter_seen_at_right_angle
#print axioms tangent_meets_radius_at_right_angle
