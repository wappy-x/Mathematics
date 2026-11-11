-- Area: in the flat plane a triangle's area is half a side times the square-on height to that side, a trapezoid's area is the average of its parallel sides times the distance between them, and Heron's rule gives the same triangle area from the three sides alone.
import Mathlib.MeasureTheory.Measure.Haar.InnerProductSpace
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Convex.Combination
import Mathlib.Topology.MetricSpace.HausdorffDistance
import Mathlib.LinearAlgebra.AffineSpace.AffineSubspace.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Integral

open MeasureTheory

lemma area_dist_sq (x y : EuclideanSpace ℝ (Fin 2)) :
    dist x y ^ 2 = (x 0 - y 0) ^ 2 + (x 1 - y 1) ^ 2 := by
  rw [EuclideanSpace.dist_sq_eq, Fin.sum_univ_two, Real.dist_eq, Real.dist_eq, sq_abs, sq_abs]

lemma area_infDist_mul_dist (P Q R : EuclideanSpace ℝ (Fin 2)) :
    Metric.infDist P (line[ℝ, Q, R] : Set _) * dist Q R =
      |(Q 0 - P 0) * (R 1 - P 1) - (Q 1 - P 1) * (R 0 - P 0)| := by
  by_cases hQR : Q = R
  · subst hQR; rw [mul_comm (Q 1 - P 1)]; simp
  have hd : 0 < dist Q R := dist_pos.2 hQR
  set c := (Q 0 - P 0) * (R 1 - P 1) - (Q 1 - P 1) * (R 0 - P 0) with hc
  have hd2 := area_dist_sq Q R
  have key : ∀ y ∈ (line[ℝ, Q, R] : Set (EuclideanSpace ℝ (Fin 2))),
      |c| ≤ dist P y * dist Q R := by
    intro y hy
    obtain ⟨r, rfl⟩ := (mem_affineSpan_pair_iff_exists_lineMap_eq).1 hy
    have h1 := area_dist_sq P (AffineMap.lineMap Q R r)
    have hpos : 0 ≤ dist P (AffineMap.lineMap Q R r) * dist Q R := by positivity
    rw [← abs_of_nonneg hpos]
    apply sq_le_sq.1
    rw [mul_pow, h1, hd2]
    simp only [AffineMap.lineMap_apply_module, PiLp.add_apply, PiLp.smul_apply, smul_eq_mul, hc]
    nlinarith [sq_nonneg ((P 0 - ((1 - r) * Q 0 + r * R 0)) * (R 0 - Q 0)
      + (P 1 - ((1 - r) * Q 1 + r * R 1)) * (R 1 - Q 1))]
  have hne : (line[ℝ, Q, R] : Set (EuclideanSpace ℝ (Fin 2))).Nonempty :=
    ⟨Q, left_mem_affineSpan_pair ℝ Q R⟩
  apply le_antisymm
  · have hw : (R 0 - Q 0) ^ 2 + (R 1 - Q 1) ^ 2 ≠ 0 := by
      have : 0 < dist Q R ^ 2 := by positivity
      rw [hd2] at this; nlinarith
    set r0 := ((P 0 - Q 0) * (R 0 - Q 0) + (P 1 - Q 1) * (R 1 - Q 1)) /
      ((R 0 - Q 0) ^ 2 + (R 1 - Q 1) ^ 2) with hr0
    have hF : AffineMap.lineMap Q R r0 ∈ (line[ℝ, Q, R] : Set (EuclideanSpace ℝ (Fin 2))) :=
      AffineMap.lineMap_mem_affineSpan_pair r0 Q R
    have hfoot : dist P (AffineMap.lineMap Q R r0) * dist Q R = |c| := by
      have h0 : 0 ≤ dist P (AffineMap.lineMap Q R r0) * dist Q R := by positivity
      rw [← abs_of_nonneg h0]
      apply (sq_eq_sq_iff_abs_eq_abs _ _).1
      rw [mul_pow, area_dist_sq P, hd2]
      simp only [AffineMap.lineMap_apply_module, PiLp.add_apply, PiLp.smul_apply, smul_eq_mul, hc]
      rw [hr0]
      field_simp
      ring
    calc Metric.infDist P _ * dist Q R ≤ dist P (AffineMap.lineMap Q R r0) * dist Q R :=
          mul_le_mul_of_nonneg_right (Metric.infDist_le_dist_of_mem hF) hd.le
      _ = |c| := hfoot
  · have : |c| / dist Q R ≤ Metric.infDist P (line[ℝ, Q, R] : Set _) :=
      (Metric.le_infDist hne).2 (fun y hy => by rw [div_le_iff₀ hd]; exact key y hy)
    rwa [div_le_iff₀ hd] at this

lemma area_region_volume (t : ℝ) (ht : 0 ≤ t) :
    volume {v : EuclideanSpace ℝ (Fin 2) |
      0 ≤ v 0 ∧ v 0 ≤ 1 ∧ 0 ≤ v 1 ∧ v 1 ≤ 1 + (t - 1) * v 0} = ENNReal.ofReal ((1 + t) / 2) := by
  have hmp : MeasurePreserving
      (fun v : EuclideanSpace ℝ (Fin 2) => MeasurableEquiv.finTwoArrow (WithLp.ofLp v))
      volume volume :=
    (volume_preserving_finTwoArrow ℝ).comp (PiLp.volume_preserving_ofLp (Fin 2))
  set S : Set (ℝ × ℝ) := {p | p.1 ∈ Set.Icc 0 1 ∧ p.2 ∈ Set.Icc 0 (1 + (t - 1) * p.1)} with hSdef
  have hS : MeasurableSet S :=
    measurableSet_region_between_cc (f := fun _ => (0 : ℝ)) (g := fun x => 1 + (t - 1) * x)
      (by fun_prop) (by fun_prop) measurableSet_Icc
  have hpre : {v : EuclideanSpace ℝ (Fin 2) |
      0 ≤ v 0 ∧ v 0 ≤ 1 ∧ 0 ≤ v 1 ∧ v 1 ≤ 1 + (t - 1) * v 0} =
      (fun v : EuclideanSpace ℝ (Fin 2) => MeasurableEquiv.finTwoArrow (WithLp.ofLp v)) ⁻¹' S := by
    ext v
    simp [hSdef, MeasurableEquiv.finTwoArrow, and_assoc]
  rw [hpre, hmp.measure_preimage hS.nullMeasurableSet, Measure.volume_eq_prod,
    Measure.prod_apply hS]
  have hslice : ∀ x : ℝ, volume (Prod.mk x ⁻¹' S) =
      Set.indicator (Set.Icc 0 1) (fun x => ENNReal.ofReal (1 + (t - 1) * x)) x := by
    intro x
    by_cases hx : x ∈ Set.Icc (0 : ℝ) 1
    · have : Prod.mk x ⁻¹' S = Set.Icc 0 (1 + (t - 1) * x) := by
        ext y; simp [hSdef, hx.1, hx.2]
      rw [this, Real.volume_Icc, Set.indicator_of_mem hx]
      simp
    · have : Prod.mk x ⁻¹' S = ∅ := by
        ext y
        simp only [Set.mem_preimage, hSdef, Set.mem_ofPred_eq, Set.mem_empty_iff_false, iff_false,
          not_and]
        intro h; exact absurd h hx
      rw [this, Set.indicator_of_notMem hx]
      simp
  simp_rw [hslice]
  rw [lintegral_indicator measurableSet_Icc, ← ofReal_integral_eq_lintegral_ofReal]
  · congr 1
    rw [integral_Icc_eq_integral_Ioc, ← intervalIntegral.integral_of_le zero_le_one]
    rw [intervalIntegral.integral_add intervalIntegrable_const
      (Continuous.intervalIntegrable (by fun_prop) _ _), intervalIntegral.integral_const_mul]
    simp
    ring
  · exact (by fun_prop : Continuous fun x : ℝ => 1 + (t - 1) * x).integrableOn_Icc
  · refine (ae_restrict_iff' measurableSet_Icc).2 (Filter.Eventually.of_forall fun x hx => ?_)
    simp only [Pi.zero_apply]
    nlinarith [hx.1, hx.2]

lemma area_hull_region (t : ℝ) (ht : 0 ≤ t) :
    convexHull ℝ {(0 : EuclideanSpace ℝ (Fin 2)), EuclideanSpace.single 1 1,
      EuclideanSpace.single 0 1 + t • EuclideanSpace.single 1 1, EuclideanSpace.single 0 1} =
      {v : EuclideanSpace ℝ (Fin 2) |
        0 ≤ v 0 ∧ v 0 ≤ 1 ∧ 0 ≤ v 1 ∧ v 1 ≤ 1 + (t - 1) * v 0} := by
  apply Set.Subset.antisymm
  · apply convexHull_min
    · intro v hv
      simp only [Set.mem_insert_iff, Set.mem_singleton_iff] at hv
      rcases hv with rfl | rfl | rfl | rfl <;> simp <;> linarith
    · intro x hx y hy a b ha hb hab
      obtain ⟨hx0, hx1, hx2, hx3⟩ := hx
      obtain ⟨hy0, hy1, hy2, hy3⟩ := hy
      simp only [Set.mem_ofPred_eq, PiLp.add_apply, PiLp.smul_apply, smul_eq_mul]
      refine ⟨by positivity, by nlinarith, by positivity, by nlinarith⟩
  · rintro v ⟨h0, h1, h2, h3⟩
    set x := v 0
    set y := v 1
    set L := 1 + (t - 1) * x with hL
    have hL0 : 0 ≤ L := by nlinarith
    set lam := y / L with hlam
    have hlamL : lam * L = y := by
      by_cases hL' : L = 0
      · have : y = 0 := by linarith
        rw [hlam, hL', this]; simp
      · rw [hlam]; field_simp
    have hlam0 : 0 ≤ lam := div_nonneg h2 hL0
    have hlam1 : lam ≤ 1 := by
      by_cases hL' : L = 0
      · rw [hlam, hL']; simp
      · rw [hlam, div_le_one (lt_of_le_of_ne hL0 (Ne.symm hL'))]; exact h3
    set s : Set (EuclideanSpace ℝ (Fin 2)) := {(0 : EuclideanSpace ℝ (Fin 2)),
      EuclideanSpace.single 1 1, EuclideanSpace.single 0 1 + t • EuclideanSpace.single 1 1,
      EuclideanSpace.single 0 1} with hs
    have hP : (1 - x) • (0 : EuclideanSpace ℝ (Fin 2)) + x • EuclideanSpace.single 0 1 ∈
        convexHull ℝ s :=
      segment_subset_convexHull (by simp [hs]) (by simp [hs])
        ⟨1 - x, x, by linarith, h0, by ring, rfl⟩
    have hQ : (1 - x) • (EuclideanSpace.single 1 1 : EuclideanSpace ℝ (Fin 2)) +
        x • (EuclideanSpace.single 0 1 + t • EuclideanSpace.single 1 1) ∈ convexHull ℝ s :=
      segment_subset_convexHull (by simp [hs]) (by simp [hs])
        ⟨1 - x, x, by linarith, h0, by ring, rfl⟩
    have hv := convex_convexHull ℝ s hP hQ (by linarith : 0 ≤ 1 - lam) hlam0 (by ring)
    convert hv using 1
    ext i
    fin_cases i
    · simp [x]; ring
    · simp
      change y = _
      rw [hL] at hlamL
      linear_combination -hlamL

open scoped Pointwise in
lemma area_affine_volume (A U W : EuclideanSpace ℝ (Fin 2)) (t : ℝ) (ht : 0 ≤ t) :
    volume (convexHull ℝ {A, A + W, A + U + t • W, A + U}) =
      ENNReal.ofReal (|U 0 * W 1 - U 1 * W 0| * ((1 + t) / 2)) := by
  let L : EuclideanSpace ℝ (Fin 2) →ₗ[ℝ] EuclideanSpace ℝ (Fin 2) :=
    { toFun := fun v => v 0 • U + v 1 • W
      map_add' := by
        intro x y
        simp only [PiLp.add_apply, add_smul]
        abel
      map_smul' := by
        intro c x
        simp only [PiLp.smul_apply, smul_eq_mul, mul_smul, smul_add, RingHom.id_apply] }
  have hdet : LinearMap.det L = U 0 * W 1 - U 1 * W 0 := by
    rw [← LinearMap.det_toMatrix (EuclideanSpace.basisFun (Fin 2) ℝ).toBasis, Matrix.det_fin_two]
    simp [LinearMap.toMatrix_apply, L]
    ring
  have himg : ({A, A + W, A + U + t • W, A + U} : Set (EuclideanSpace ℝ (Fin 2))) =
      A +ᵥ (L '' {(0 : EuclideanSpace ℝ (Fin 2)), EuclideanSpace.single 1 1,
        EuclideanSpace.single 0 1 + t • EuclideanSpace.single 1 1, EuclideanSpace.single 0 1}) := by
    simp only [Set.image_insert_eq, Set.image_singleton, Set.vadd_set_insert,
      Set.vadd_set_singleton, vadd_eq_add]
    simp [L, add_assoc]
  rw [himg, convexHull_vadd, ← LinearMap.image_convexHull, area_hull_region t ht, measure_vadd,
    Measure.addHaar_image_linearMap, area_region_volume t ht, hdet,
    ← ENNReal.ofReal_mul (abs_nonneg _)]

#print axioms area_dist_sq
#print axioms area_infDist_mul_dist
#print axioms area_region_volume
#print axioms area_hull_region
#print axioms area_affine_volume

/-- Half base times height. In the flat plane, take any triangle with corners A, B and C, and
take side BC as the base. The height is the square-on distance from the far corner A to the
line through B and C. Then the area inside the triangle is half the base times the height.
No other condition is needed: if the corners lie on one line the triangle is flat and both
sides are 0. -/
theorem triangle_area_eq_half_base_times_height (A B C : EuclideanSpace ℝ (Fin 2)) :
    volume (convexHull ℝ {A, B, C}) =
      ENNReal.ofReal (1 / 2 * dist B C * Metric.infDist A (line[ℝ, B, C] : Set _)) := by
  have h := area_affine_volume A (C - A) (B - A) 0 le_rfl
  have hset : ({A, A + (B - A), A + (C - A) + (0 : ℝ) • (B - A), A + (C - A)} :
      Set (EuclideanSpace ℝ (Fin 2))) = {A, B, C} := by
    simp
  rw [hset] at h
  rw [h, mul_assoc, mul_comm (dist B C), area_infDist_mul_dist]
  congr 1
  simp only [PiLp.sub_apply]
  rw [show (C 0 - A 0) * (B 1 - A 1) - (C 1 - A 1) * (B 0 - A 0) =
    -((B 0 - A 0) * (C 1 - A 1) - (B 1 - A 1) * (C 0 - A 0)) by ring, abs_neg]
  ring

/-- Trapezoid rule. In the flat plane, let A, B, C, D be the corners of a trapezoid in order,
with the top side DC parallel to the base AB and pointing the same way (C − D is a
non-negative multiple of B − A). Its area is the average of the two parallel sides times the
height, the square-on distance between them. A parallelogram is the case DC = AB, giving base
times height. -/
theorem trapezoid_area_eq_average_of_parallel_sides_times_height
    (A B C D : EuclideanSpace ℝ (Fin 2)) (hpar : ∃ t : ℝ, 0 ≤ t ∧ C - D = t • (B - A)) :
    volume (convexHull ℝ {A, B, C, D}) =
      ENNReal.ofReal ((dist A B + dist D C) / 2 * Metric.infDist D (line[ℝ, A, B] : Set _)) := by
  obtain ⟨t, ht, hC⟩ := hpar
  have h := area_affine_volume A (D - A) (B - A) t ht
  have hset : ({A, A + (B - A), A + (D - A) + t • (B - A), A + (D - A)} :
      Set (EuclideanSpace ℝ (Fin 2))) = {A, B, C, D} := by
    have : A + (D - A) + t • (B - A) = C := by
      rw [← hC]; abel
    rw [this]; simp
  rw [hset] at h
  have hDC : dist D C = t * dist A B := by
    rw [dist_comm D C, dist_eq_norm, hC, norm_smul, Real.norm_of_nonneg ht, dist_comm,
      dist_eq_norm]
  rw [h, hDC]
  have key := area_infDist_mul_dist D A B
  congr 1
  calc |(D - A) 0 * (B - A) 1 - (D - A) 1 * (B - A) 0| * ((1 + t) / 2)
      = |(A 0 - D 0) * (B 1 - D 1) - (A 1 - D 1) * (B 0 - D 0)| * ((1 + t) / 2) := by
        simp only [PiLp.sub_apply]
        congr 1
        rw [← abs_neg]
        congr 1
        ring
    _ = Metric.infDist D (line[ℝ, A, B] : Set _) * dist A B * ((1 + t) / 2) := by rw [key]
    _ = (dist A B + t * dist A B) / 2 * Metric.infDist D (line[ℝ, A, B] : Set _) := by ring

/-- Heron's rule. In the flat plane, a triangle with sides a = BC, b = CA, c = AB and half
perimeter s = (a + b + c) / 2 has area √(s(s − a)(s − b)(s − c)). -/
theorem heron_triangle_area (A B C : EuclideanSpace ℝ (Fin 2)) :
    let a := dist B C
    let b := dist C A
    let c := dist A B
    let s := (a + b + c) / 2
    volume (convexHull ℝ {A, B, C}) =
      ENNReal.ofReal (Real.sqrt (s * (s - a) * (s - b) * (s - c))) := by
  intro a b c s
  have h := area_affine_volume A (C - A) (B - A) 0 le_rfl
  have hset : ({A, A + (B - A), A + (C - A) + (0 : ℝ) • (B - A), A + (C - A)} :
      Set (EuclideanSpace ℝ (Fin 2))) = {A, B, C} := by
    simp
  rw [hset] at h
  rw [h]
  congr 1
  set k := (C - A) 0 * (B - A) 1 - (C - A) 1 * (B - A) 0 with hk
  have ha := area_dist_sq B C
  have hb := area_dist_sq C A
  have hc := area_dist_sq A B
  have hprod : s * (s - a) * (s - b) * (s - c) =
      (2 * (a ^ 2) * (b ^ 2) + 2 * (b ^ 2) * (c ^ 2) + 2 * (c ^ 2) * (a ^ 2)
        - (a ^ 2) ^ 2 - (b ^ 2) ^ 2 - (c ^ 2) ^ 2) / 16 := by
    simp only [s]; ring
  have hk2 : s * (s - a) * (s - b) * (s - c) = (|k| * ((1 + 0) / 2)) ^ 2 := by
    rw [hprod, ha, hb, hc, mul_pow, sq_abs, hk]
    simp only [PiLp.sub_apply]
    ring
  rw [hk2, Real.sqrt_sq (by positivity)]

-- The 7-8-9 m bed: half the perimeter is 12, and Heron's product is 12 × 5 × 4 × 3 = 720.
example : ((7 + 8 + 9 : ℚ) / 2) = 12 := by norm_num
example : (12 : ℚ) * (12 - 7) * (12 - 8) * (12 - 9) = 720 := by norm_num

-- Step 4: the foot of the height lies (64 + 81 − 49) / 18 = 16/3 m from A, and h² = 64 − x².
example : ((8 : ℚ) ^ 2 + 9 ^ 2 - 7 ^ 2) / (2 * 9) = 16 / 3 := by norm_num
example : (8 : ℚ) ^ 2 - (16 / 3) ^ 2 = 320 / 9 := by norm_num
-- Half base times height squared matches Heron's product: (9/2)² × 320/9 = 720.
example : ((9 : ℚ) / 2) ^ 2 * (320 / 9) = 720 := by norm_num

-- Step 5: the four brackets are 24, 10, 8 and 6; their product is 11520 = 16 × 720,
-- and the expanded form gives the same number.
example : (7 + 8 + 9 : ℤ) * (-7 + 8 + 9) * (7 - 8 + 9) * (7 + 8 - 9) = 11520 := by norm_num
example : (11520 : ℤ) = 16 * 720 := by norm_num
example : (2 * (7 ^ 2 * 8 ^ 2 + 8 ^ 2 * 9 ^ 2 + 9 ^ 2 * 7 ^ 2) - (7 ^ 4 + 8 ^ 4 + 9 ^ 4) : ℤ)
    = 11520 := by norm_num

-- Sides 2, 3, 6 cannot close: Heron's product is −24.0625 = −385/16.
example : let s : ℚ := (2 + 3 + 6) / 2; s * (s - 2) * (s - 3) * (s - 6) = -385 / 16 := by
  norm_num
-- Sides 2, 3, 5 lie flat: Heron's product is 0.
example : let s : ℚ := (2 + 3 + 5) / 2; s * (s - 2) * (s - 3) * (s - 5) = 0 := by norm_num

-- The usual mistake: the 8 m sloping side used as the height gives 9 × 8 / 2 = 36.
example : (9 : ℚ) * 8 / 2 = 36 := by norm_num
-- A rectangle 3 m by 2 m holds six one-metre squares.
example : (3 : ℕ) * 2 = 6 := by decide

#print axioms triangle_area_eq_half_base_times_height
#print axioms trapezoid_area_eq_average_of_parallel_sides_times_height
#print axioms heron_triangle_area
