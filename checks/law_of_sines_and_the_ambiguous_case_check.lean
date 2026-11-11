-- Law of sines: in every flat triangle each side over the sine of the angle it faces equals the diameter of the circle through the corners, two angles and a side fix every side, and two sides with an angle not between them fit no triangle, one or two, as the card's table says.
import Mathlib.Geometry.Euclidean.Angle.Sphere
import Mathlib.Geometry.Euclidean.Congruence
import Mathlib.Geometry.Euclidean.Triangle
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Data.Set.Card
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.NormNum

open EuclideanGeometry Real

variable {V P : Type*} [NormedAddCommGroup V] [InnerProductSpace ℝ V] [MetricSpace P]
  [NormedAddTorsor V P]

/-- Helper: a length `b` is the third side of a plane triangle with angle `α` at A, `AB = c`
and `BC = a` exactly when `b` is a positive root of the law-of-cosines quadratic. -/
lemma ssa_mem_iff (α c a b : ℝ) (hα₀ : 0 < α) (hαπ : α < π) (hc : 0 < c) (ha : 0 < a) :
    (∃ A B C : EuclideanSpace ℝ (Fin 2),
      AffineIndependent ℝ ![A, B, C] ∧ ∠ B A C = α ∧ dist A B = c ∧ dist B C = a ∧
        dist A C = b) ↔ 0 < b ∧ b ^ 2 - 2 * b * c * Real.cos α + c ^ 2 - a ^ 2 = 0 := by
  constructor
  · rintro ⟨A, B, C, hi, hang, hAB, hBC, hAC⟩
    have hcol := affineIndependent_iff_not_collinear_set.mp hi
    have hAC' : A ≠ C := ne₁₃_of_not_collinear hcol
    refine ⟨?_, ?_⟩
    · rw [← hAC]; exact dist_pos.mpr hAC'
    · have := law_cos B A C
      rw [hang, dist_comm B A, dist_comm C A, hAB, hBC, hAC] at this
      nlinarith
  · rintro ⟨hb, hq⟩
    let u : EuclideanSpace ℝ (Fin 2) := EuclideanSpace.single 0 1
    let v : EuclideanSpace ℝ (Fin 2) := EuclideanSpace.single 1 1
    have huu : inner ℝ u u = 1 := by simp [u]
    have hvv : inner ℝ v v = 1 := by simp [v]
    have huv : inner ℝ u v = 0 := by simp [u, v, EuclideanSpace.inner_single_left]
    have hvu : inner ℝ v u = 0 := by simp [u, v, EuclideanSpace.inner_single_left]
    have hun : ‖u‖ = 1 := by simp [u]
    let w : EuclideanSpace ℝ (Fin 2) := Real.cos α • u + Real.sin α • v
    have hww : inner ℝ w w = 1 := by
      simp only [w, inner_add_left, inner_add_right, real_inner_smul_left, real_inner_smul_right,
        huu, hvv, huv, hvu]
      nlinarith [cos_sq_add_sin_sq α]
    have hwn : ‖w‖ = 1 := by
      have h1 := real_inner_self_eq_norm_sq w
      rw [hww] at h1
      nlinarith [norm_nonneg w]
    have huw : inner ℝ u w = Real.cos α := by
      simp only [w, inner_add_right, real_inner_smul_right, huu, huv]
      ring
    have hang0 : InnerProductGeometry.angle u w = α := by
      unfold InnerProductGeometry.angle
      rw [huw, hun, hwn, mul_one, div_one]
      exact Real.arccos_cos hα₀.le hαπ.le
    have hang : ∠ (c • u) 0 (b • w) = α := by
      rw [EuclideanGeometry.angle, vsub_eq_sub, vsub_eq_sub, sub_zero, sub_zero,
        InnerProductGeometry.angle_smul_left_of_pos _ _ hc,
        InnerProductGeometry.angle_smul_right_of_pos _ _ hb, hang0]
    have hAB : dist (0 : EuclideanSpace ℝ (Fin 2)) (c • u) = c := by
      rw [dist_zero_left, norm_smul, hun, Real.norm_eq_abs, abs_of_pos hc, mul_one]
    have hAC : dist (0 : EuclideanSpace ℝ (Fin 2)) (b • w) = b := by
      rw [dist_zero_left, norm_smul, hwn, Real.norm_eq_abs, abs_of_pos hb, mul_one]
    have hBC : dist (c • u) (b • w) = a := by
      have hl := law_cos (c • u) 0 (b • w)
      rw [hang, dist_comm (c • u) 0, dist_comm (b • w) 0, hAB, hAC] at hl
      have hsq : dist (c • u) (b • w) * dist (c • u) (b • w) = a * a := by
        rw [hl]; linear_combination hq
      rcases mul_self_eq_mul_self_iff.mp hsq with h1 | h1
      · exact h1
      · have := dist_nonneg (x := c • u) (y := b • w)
        linarith
    refine ⟨0, c • u, b • w, ?_, hang, hAB, hBC, hAC⟩
    rw [affineIndependent_iff_not_collinear_set, Set.insert_comm,
      collinear_iff_eq_or_eq_or_angle_eq_zero_or_angle_eq_pi, hang]
    push Not
    refine ⟨?_, ?_, hα₀.ne', hαπ.ne⟩
    · intro h0
      rw [h0, dist_self] at hAB
      linarith
    · intro h0
      rw [h0, dist_self] at hAC
      linarith

/-- Helper: with `D ^ 2 = a ^ 2 - (c sin α) ^ 2`, the law-of-cosines quadratic factors. -/
lemma ssa_factor (α c a b D : ℝ) (hD : D ^ 2 = a ^ 2 - (c * Real.sin α) ^ 2) :
    b ^ 2 - 2 * b * c * Real.cos α + c ^ 2 - a ^ 2 =
      (b - (c * Real.cos α + D)) * (b - (c * Real.cos α - D)) := by
  linear_combination (-c ^ 2) * (Real.cos_sq_add_sin_sq α) + hD

#print axioms ssa_mem_iff
#print axioms ssa_factor

/-- The law of sines. Take any triangle with corners A, B, C on flat ground (corners not in one
line). Each side, divided by the sine of the angle at the corner it faces, gives the same
length: BC / sin A = AC / sin B = AB / sin C. That common length is twice the radius of the
circle through the three corners, its diameter 2R. -/
theorem law_of_sines_side_over_sine_eq_diameter (A B C : P)
    (h : AffineIndependent ℝ ![A, B, C]) :
    dist B C / Real.sin (∠ B A C) = dist A C / Real.sin (∠ A B C) ∧
      dist A C / Real.sin (∠ A B C) = dist A B / Real.sin (∠ A C B) ∧
      dist A B / Real.sin (∠ A C B) =
        2 * (⟨![A, B, C], h⟩ : Affine.Triangle ℝ P).circumradius := by
  have e1 : dist B C / Real.sin (∠ B A C) =
      2 * (⟨![A, B, C], h⟩ : Affine.Triangle ℝ P).circumradius :=
    Affine.Triangle.dist_div_sin_angle_eq_two_mul_circumradius
      (⟨![A, B, C], h⟩ : Affine.Triangle ℝ P)
      (i₁ := 1) (i₂ := 0) (i₃ := 2) (by decide) (by decide) (by decide)
  have e2 : dist A C / Real.sin (∠ A B C) =
      2 * (⟨![A, B, C], h⟩ : Affine.Triangle ℝ P).circumradius :=
    Affine.Triangle.dist_div_sin_angle_eq_two_mul_circumradius
      (⟨![A, B, C], h⟩ : Affine.Triangle ℝ P)
      (i₁ := 0) (i₂ := 1) (i₃ := 2) (by decide) (by decide) (by decide)
  have e3 : dist A B / Real.sin (∠ A C B) =
      2 * (⟨![A, B, C], h⟩ : Affine.Triangle ℝ P).circumradius :=
    Affine.Triangle.dist_div_sin_angle_eq_two_mul_circumradius
      (⟨![A, B, C], h⟩ : Affine.Triangle ℝ P)
      (i₁ := 0) (i₂ := 2) (i₃ := 1) (by decide) (by decide) (by decide)
  exact ⟨by rw [e1, e2], by rw [e2, e3], e3⟩

/-- Two angles and a side fix every side. Take two triangles ABC and A'B'C' on flat ground.
If the angles at A and A' are equal, the angles at B and B' are equal, and one side of the
first equals the matching side of the second (the side between the two angles, as for the two
lighthouses, or either other side), then all three sides match. -/
theorem two_angles_and_a_side_fix_every_side (A B C A' B' C' : P)
    (h : AffineIndependent ℝ ![A, B, C]) (h' : AffineIndependent ℝ ![A', B', C'])
    (hA : ∠ B A C = ∠ B' A' C') (hB : ∠ A B C = ∠ A' B' C')
    (hside : dist A B = dist A' B' ∨ dist B C = dist B' C' ∨ dist A C = dist A' C') :
    dist A B = dist A' B' ∧ dist B C = dist B' C' ∧ dist A C = dist A' C' := by
  have hc := affineIndependent_iff_not_collinear_set.mp h
  have hc' := affineIndependent_iff_not_collinear_set.mp h'
  obtain ⟨L1, L2, -⟩ := law_of_sines_side_over_sine_eq_diameter A B C h
  obtain ⟨M1, M2, -⟩ := law_of_sines_side_over_sine_eq_diameter A' B' C' h'
  have hsum := angle_add_angle_add_angle_eq_pi C (ne₁₂_of_not_collinear hc).symm
  have hsum' := angle_add_angle_add_angle_eq_pi C' (ne₁₂_of_not_collinear hc').symm
  have hC : ∠ A C B = ∠ A' C' B' := by
    have e1 := angle_comm C A B
    have e2 := angle_comm C' A' B'
    have e3 := angle_comm A C B
    have e4 := angle_comm A' C' B'
    linarith
  have sA : 0 < Real.sin (∠ B A C) := sin_pos_of_not_collinear (by rwa [Set.insert_comm] at hc)
  have sB : 0 < Real.sin (∠ A B C) := sin_pos_of_not_collinear hc
  have sC : 0 < Real.sin (∠ A C B) := sin_pos_of_not_collinear (by rwa [Set.pair_comm] at hc)
  simp only [← hA, ← hB, ← hC] at M1 M2
  generalize Real.sin (∠ B A C) = x at *
  generalize Real.sin (∠ A B C) = y at *
  generalize Real.sin (∠ A C B) = z at *
  have eBC : dist B C = dist A B / z * x := by rw [← L2, ← L1]; field_simp
  have eAC : dist A C = dist A B / z * y := by rw [← L2]; field_simp
  have eAB : dist A B = dist A B / z * z := by field_simp
  have fBC : dist B' C' = dist A' B' / z * x := by rw [← M2, ← M1]; field_simp
  have fAC : dist A' C' = dist A' B' / z * y := by rw [← M2]; field_simp
  have fAB : dist A' B' = dist A' B' / z * z := by field_simp
  generalize dist A B / z = r at *
  generalize dist A' B' / z = r' at *
  have hr : r = r' := by
    rcases hside with hs | hs | hs
    · rw [eAB, fAB] at hs; exact mul_right_cancel₀ sC.ne' hs
    · rw [eBC, fBC] at hs; exact mul_right_cancel₀ sA.ne' hs
    · rw [eAC, fAC] at hs; exact mul_right_cancel₀ sB.ne' hs
  subst hr
  exact ⟨by rw [eAB, fAB], by rw [eBC, fBC], by rw [eAC, fAC]⟩

/-- Side-side-angle: none, one or two triangles. In the flat plane, fix an angle `α` at corner A
(strictly between 0 and π), the side `c = AB` beside it, and the side `a = BC` facing it, all
positive. The set below holds every length `b = AC` of a genuine triangle with these readings;
two such triangles with the same `b` are congruent (side-angle-side), so its size counts the
triangles. With `d = c sin α`, B's square-on distance to A's sightline:
range under d gives none; with α under a right angle, range d gives one, range between d and c
gives two, range c or more gives one; with α a right angle or more, range over c gives one and
any other range gives none. -/
theorem ssa_triangle_count (α c a : ℝ) (hα₀ : 0 < α) (hαπ : α < π) (hc : 0 < c) (ha : 0 < a) :
    let S : Set ℝ := {b | ∃ A B C : EuclideanSpace ℝ (Fin 2),
      AffineIndependent ℝ ![A, B, C] ∧ ∠ B A C = α ∧ dist A B = c ∧ dist B C = a ∧
        dist A C = b}
    let d := c * Real.sin α
    (a < d → S.ncard = 0) ∧
      (α < π / 2 → a = d → S.ncard = 1) ∧
      (α < π / 2 → d < a → a < c → S.ncard = 2) ∧
      (α < π / 2 → c ≤ a → S.ncard = 1) ∧
      (π / 2 ≤ α → c < a → S.ncard = 1) ∧
      (π / 2 ≤ α → a ≤ c → S.ncard = 0) := by
  intro S d
  have hS : ∀ b, b ∈ S ↔ 0 < b ∧ b ^ 2 - 2 * b * c * Real.cos α + c ^ 2 - a ^ 2 = 0 :=
    fun b => ssa_mem_iff α c a b hα₀ hαπ hc ha
  have hd : d = c * Real.sin α := rfl
  clear_value S d
  subst hd
  have hs : 0 < Real.sin α := Real.sin_pos_of_pos_of_lt_pi hα₀ hαπ
  have hks := Real.cos_sq_add_sin_sq α
  have hk2 : c ^ 2 * Real.cos α ^ 2 + c ^ 2 * Real.sin α ^ 2 = c ^ 2 := by
    rw [← mul_add, hks, mul_one]
  have hcs : 0 < c * Real.sin α := mul_pos hc hs
  set k := Real.cos α with hk
  set s := Real.sin α with hs'
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩
  · intro h
    have hS0 : S = ∅ := by
      ext b
      simp only [hS, Set.mem_empty_iff_false, iff_false]
      rintro ⟨hb, hq⟩
      nlinarith [sq_nonneg (b - c * k), mul_self_lt_mul_self ha.le h]
    rw [hS0, Set.ncard_empty]
  · intro hα h
    have hk0 : 0 < k := Real.cos_pos_of_mem_Ioo ⟨by linarith, hα⟩
    have hS1 : S = {c * k} := by
      ext b
      rw [hS, Set.mem_singleton_iff]
      constructor
      · rintro ⟨hb, hq⟩
        have h0 : (b - c * k) ^ 2 = 0 := by rw [h] at hq; nlinarith
        have := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp h0
        linarith
      · rintro rfl
        refine ⟨mul_pos hc hk0, ?_⟩
        rw [h]
        linear_combination (-c ^ 2) * hks
    rw [hS1, Set.ncard_singleton]
  · intro hα h1 h2
    have hk0 : 0 < k := Real.cos_pos_of_mem_Ioo ⟨by linarith, hα⟩
    set D := Real.sqrt (a ^ 2 - (c * s) ^ 2) with hDdef
    have hpos : 0 < a ^ 2 - (c * s) ^ 2 := by nlinarith
    have hD : D ^ 2 = a ^ 2 - (c * s) ^ 2 := Real.sq_sqrt hpos.le
    have hD0 : 0 < D := Real.sqrt_pos.mpr hpos
    have hck : 0 < c * k := mul_pos hc hk0
    have hDlt : D < c * k := by
      by_contra hh
      push Not at hh
      nlinarith [mul_self_le_mul_self hck.le hh, mul_self_lt_mul_self ha.le h2]
    have hS2 : S = {c * k + D, c * k - D} := by
      ext b
      rw [hS, Set.mem_insert_iff, Set.mem_singleton_iff, ssa_factor α c a b D hD]
      constructor
      · rintro ⟨-, hq⟩
        rcases mul_eq_zero.mp hq with h | h
        · left; linarith
        · right; linarith
      · rintro (rfl | rfl)
        · exact ⟨by linarith, by ring⟩
        · exact ⟨by linarith, by ring⟩
    rw [hS2, Set.ncard_pair (by linarith)]
  · intro hα h
    have hk0 : 0 < k := Real.cos_pos_of_mem_Ioo ⟨by linarith, hα⟩
    have hs1 : s ≤ 1 := Real.sin_le_one α
    have hpos : 0 ≤ a ^ 2 - (c * s) ^ 2 := by nlinarith
    set D := Real.sqrt (a ^ 2 - (c * s) ^ 2) with hDdef
    have hD : D ^ 2 = a ^ 2 - (c * s) ^ 2 := Real.sq_sqrt hpos
    have hD0 : 0 ≤ D := Real.sqrt_nonneg _
    have hck : 0 < c * k := mul_pos hc hk0
    have hDge : c * k ≤ D := by nlinarith
    have hS1 : S = {c * k + D} := by
      ext b
      rw [hS, Set.mem_singleton_iff, ssa_factor α c a b D hD]
      constructor
      · rintro ⟨hb, hq⟩
        rcases mul_eq_zero.mp hq with h | h
        · linarith
        · linarith
      · rintro rfl
        exact ⟨by linarith, by ring⟩
    rw [hS1, Set.ncard_singleton]
  · intro hα h
    have hk0 : k ≤ 0 := Real.cos_nonpos_of_pi_div_two_le_of_le hα (by linarith)
    have hs1 : s ≤ 1 := Real.sin_le_one α
    have hpos : 0 < a ^ 2 - (c * s) ^ 2 := by nlinarith
    set D := Real.sqrt (a ^ 2 - (c * s) ^ 2) with hDdef
    have hD : D ^ 2 = a ^ 2 - (c * s) ^ 2 := Real.sq_sqrt hpos.le
    have hD0 : 0 < D := Real.sqrt_pos.mpr hpos
    have hDgt : -(c * k) < D := by nlinarith
    have hS1 : S = {c * k + D} := by
      ext b
      rw [hS, Set.mem_singleton_iff, ssa_factor α c a b D hD]
      constructor
      · rintro ⟨hb, hq⟩
        rcases mul_eq_zero.mp hq with h | h
        · linarith
        · nlinarith
      · rintro rfl
        exact ⟨by linarith, by ring⟩
    rw [hS1, Set.ncard_singleton]
  · intro hα h
    have hk0 : k ≤ 0 := Real.cos_nonpos_of_pi_div_two_le_of_le hα (by linarith)
    have hS0 : S = ∅ := by
      ext b
      simp only [hS, Set.mem_empty_iff_false, iff_false]
      rintro ⟨hb, hq⟩
      nlinarith [mul_nonneg (mul_nonneg hb.le hc.le) (neg_nonneg.mpr hk0),
        mul_self_le_mul_self ha.le h]
    rw [hS0, Set.ncard_empty]

-- The clear-night fix: the angle at the ship is 180° − 30° − 105° = 45°.
example : (180 : ℤ) - 30 - 105 = 45 := by norm_num

-- The common ratio: 10 km over sin 45° is 10√2 km (14.1421 km), the circle's diameter.
example : (10 : ℝ) / Real.sin (π / 4) = 10 * Real.sqrt 2 := by
  rw [Real.sin_pi_div_four]
  have h : Real.sqrt 2 ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  have h0 : Real.sqrt 2 ≠ 0 := by positivity
  field_simp
  linear_combination (-1) * h

-- The fog's d: B's square-on distance to A's 30° sightline is 10 sin 30° = 5 km.
example : (10 : ℝ) * Real.sin (π / 6) = 5 := by
  rw [Real.sin_pi_div_six]; norm_num

-- The fog's range a = 5√2 km (7.07 km), so a² = 50. Both crossings t = 5√3 ± 5
-- (13.66 and 3.66 km) solve t² − 2ct cos 30° + c² − a² = 0, with c = 10 and cos 30° = √3/2.
example : (5 * Real.sqrt 3 + 5) ^ 2 - 2 * 10 * (5 * Real.sqrt 3 + 5) * (Real.sqrt 3 / 2)
    + 10 ^ 2 - 50 = 0 := by
  have h : Real.sqrt 3 ^ 2 = 3 := Real.sq_sqrt (by norm_num)
  linear_combination (-25) * h
example : (5 * Real.sqrt 3 - 5) ^ 2 - 2 * 10 * (5 * Real.sqrt 3 - 5) * (Real.sqrt 3 / 2)
    + 10 ^ 2 - 50 = 0 := by
  have h : Real.sqrt 3 ^ 2 = 3 := Real.sq_sqrt (by norm_num)
  linear_combination (-25) * h

-- The crossings multiply to c² − a² = 100 − 50 = 50, positive: both lie ahead of A.
example : (5 * Real.sqrt 3 + 5) * (5 * Real.sqrt 3 - 5) = 10 ^ 2 - 50 := by
  have h : Real.sqrt 3 ^ 2 = 3 := Real.sq_sqrt (by norm_num)
  linear_combination 25 * h

-- The four test ranges against d = 5 and c = 10 (compared by squares, a² against 25 and 100):
-- 4 km misses (16 < 25); 5 km touches; 7.07 km, a² = 50, lies between; 12 km is past c.
example : (4 : ℤ) ^ 2 < 5 ^ 2 := by norm_num
example : (5 : ℤ) ^ 2 < 50 ∧ (50 : ℤ) < 10 ^ 2 := by norm_num
-- At 12 km the crossings multiply to 10² − 12² = −44, negative: one lies behind A.
example : (10 : ℤ) ^ 2 - 12 ^ 2 = -44 := by norm_num

-- The circle through A (0, 0), B (10, 0) and the ship has centre (5, 5): radius² = 50,
-- so the radius is 5√2 km and the diameter 10√2 km. The ship sits at
-- ((15 + 5√3)/2, (5 + 5√3)/2), which is 5√3 + 5 km out along the 30° sightline.
example : (5 : ℤ) ^ 2 + 5 ^ 2 = 50 ∧ (10 - 5 : ℤ) ^ 2 + 5 ^ 2 = 50 := by norm_num
example : ((15 + 5 * Real.sqrt 3) / 2 - 5) ^ 2 + ((5 + 5 * Real.sqrt 3) / 2 - 5) ^ 2 = 50 := by
  have h : Real.sqrt 3 ^ 2 = 3 := Real.sq_sqrt (by norm_num)
  linear_combination (25 / 2) * h

-- The usual mistake: 105° is 3.5 times 30°, but sides do not follow the angles.
example : (105 : ℚ) / 30 = 7 / 2 := by norm_num

#print axioms law_of_sines_side_over_sine_eq_diameter
#print axioms two_angles_and_a_side_fix_every_side
#print axioms ssa_triangle_count
