-- Pyramids, cones and spheres: a pyramid or cone of any base holds one third of base area times height, a ball of radius r holds four thirds of pi r cubed, and three equal pyramids with one shared tip fill a cube.
import Mathlib.MeasureTheory.Measure.Lebesgue.VolumeOfBalls
import Mathlib.MeasureTheory.Constructions.BorelSpace.Real
import Mathlib.MeasureTheory.Measure.Prod
import Mathlib.Tactic.NormNum

open MeasureTheory Set

/-- The one-third rule. Space is (x, y) × z, with the base B lying flat in the level plane z = 0
and the tip at the point p, at height h straight above that plane (the height is measured
square on). The solid is every point on a straight segment from a point of the base to the tip:
the point a fraction t of the way up from base point b is ((1 − t) b + t p, t h). The base may
have any shape that has an area (a square for a pyramid, a disc for a cone, or anything else),
and the tip need not sit above the base's centre (a leaning cone obeys it too). Then the
volume is one third of the base's area times the height. -/
theorem pyramid_cone_volume_eq_third_base_times_height
    (B : Set (ℝ × ℝ)) (hB : MeasurableSet B) (p : ℝ × ℝ) (h : ℝ) (hh : 0 < h) :
    volume {q : (ℝ × ℝ) × ℝ |
        ∃ b ∈ B, ∃ t ∈ Icc (0 : ℝ) 1, q = ((1 - t) • b + t • p, t * h)} =
      1 / 3 * volume B * ENNReal.ofReal h := by
  set S := {q : (ℝ × ℝ) × ℝ |
        ∃ b ∈ B, ∃ t ∈ Icc (0 : ℝ) 1, q = ((1 - t) • b + t • p, t * h)} with hS
  set S' : Set ((ℝ × ℝ) × ℝ) :=
    {q | q.2 ∈ Ico 0 h ∧ (1 - q.2 / h)⁻¹ • (q.1 - (q.2 / h) • p) ∈ B} with hS'
  have hS'meas : MeasurableSet S' := by
    refine (measurableSet_Ico.preimage measurable_snd).inter (hB.preimage ?_)
    fun_prop
  have hsub1 : S' ⊆ S := by
    rintro ⟨x, z⟩ ⟨⟨hz0, hzh⟩, hb⟩
    have hs1 : z / h < 1 := (div_lt_one hh).2 hzh
    have hs0 : 0 ≤ z / h := div_nonneg hz0 hh.le
    refine ⟨_, hb, z / h, ⟨hs0, hs1.le⟩, ?_⟩
    refine Prod.ext ?_ ?_
    · simp only
      rw [smul_smul, mul_inv_cancel₀ (by linarith : (1 - z / h) ≠ 0), one_smul, sub_add_cancel]
    · simp only
      rw [div_mul_cancel₀ _ hh.ne']
  have hsub2 : S ⊆ S' ∪ {(p, h)} := by
    rintro ⟨x, z⟩ ⟨b, hb, t, ⟨ht0, ht1⟩, hq⟩
    simp only [Prod.mk.injEq] at hq
    obtain ⟨rfl, rfl⟩ := hq
    rcases eq_or_lt_of_le ht1 with rfl | ht
    · right
      simp
    · left
      have htz : t * h / h = t := mul_div_cancel_right₀ _ hh.ne'
      refine ⟨⟨by positivity, by nlinarith⟩, ?_⟩
      simp only
      rw [htz, add_sub_cancel_right, smul_smul, inv_mul_cancel₀ (by linarith : (1 - t) ≠ 0),
        one_smul]
      exact hb
  have hvol : volume S = volume S' := by
    refine le_antisymm ?_ (measure_mono hsub1)
    calc volume S ≤ volume (S' ∪ {(p, h)}) := measure_mono hsub2
      _ ≤ volume S' + volume ({(p, h)} : Set ((ℝ × ℝ) × ℝ)) := measure_union_le _ _
      _ = volume S' := by
        rw [← Set.singleton_prod_singleton, Measure.volume_eq_prod, Measure.prod_prod,
          Real.volume_singleton, mul_zero, add_zero]
  have hslice : ∀ z : ℝ, volume ((fun x => (x, z)) ⁻¹' S') =
      (Ico 0 h).indicator (fun z => ENNReal.ofReal ((1 - z / h) ^ 2) * volume B) z := by
    intro z
    by_cases hz : z ∈ Ico 0 h
    · have hne : (1 - z / h) ≠ 0 := by
        have := (div_lt_one hh).2 hz.2
        linarith
      have : (fun x => (x, z)) ⁻¹' S' =
          (fun x => x + (-((z / h) • p))) ⁻¹' ((fun y => (1 - z / h)⁻¹ • y) ⁻¹' B) := by
        ext x
        change (z ∈ Ico 0 h ∧ (1 - z / h)⁻¹ • (x - (z / h) • p) ∈ B) ↔
          (1 - z / h)⁻¹ • (x + -((z / h) • p)) ∈ B
        rw [and_iff_right hz, ← sub_eq_add_neg]
      rw [this, measure_preimage_add_right,
        Measure.addHaar_preimage_smul volume (inv_ne_zero hne)]
      simp [indicator, hz, Module.finrank_prod]
    · have : (fun x => (x, z)) ⁻¹' S' = ∅ := by
        ext x
        exact ⟨fun hx => absurd hx.1 hz, fun hx => hx.elim⟩
      rw [this]
      simp [indicator, hz]
  have hint : ∫ z in (0 : ℝ)..h, (1 - z / h) ^ 2 = h / 3 := by
    rw [intervalIntegral.integral_comp_div (fun u => (1 - u) ^ 2) hh.ne',
      intervalIntegral.integral_comp_sub_left (fun u => u ^ 2), integral_pow]
    norm_num [hh.ne']
    ring
  rw [hvol, Measure.volume_eq_prod, Measure.prod_apply_symm hS'meas]
  simp_rw [hslice]
  rw [lintegral_indicator measurableSet_Ico, lintegral_mul_const _ (by fun_prop),
    Measure.restrict_congr_set Ico_ae_eq_Ioc,
    ← ofReal_integral_eq_lintegral_ofReal, ← intervalIntegral.integral_of_le hh.le, hint]
  · rw [ENNReal.ofReal_div_of_pos (by norm_num), ENNReal.ofReal_ofNat, div_eq_mul_inv, one_div]
    ring
  · exact ((by fun_prop : Continuous fun z : ℝ => (1 - z / h) ^ 2).integrableOn_Icc).mono_set
      Ioc_subset_Icc_self
  · exact Filter.Eventually.of_forall (fun _ => sq_nonneg _)

/-- The ball's volume. In ordinary three-dimensional space, the solid ball of radius r about
any centre c (every point at distance at most r from c) holds four thirds of pi r cubed. -/
theorem ball_volume_eq_four_thirds_pi_r_cubed (c : EuclideanSpace ℝ (Fin 3)) (r : ℝ) :
    volume (Metric.closedBall c r) = ENNReal.ofReal (4 / 3 * Real.pi * r ^ 3) := by
  rw [EuclideanSpace.volume_closedBall_fin_three]
  rcases le_or_gt 0 r with hr | hr
  · rw [← ENNReal.ofReal_pow hr, ← ENNReal.ofReal_mul (by positivity)]
    congr 1; ring
  · have h3 : r ^ 3 < 0 := Odd.pow_neg (by decide) hr
    have h4 : 4 / 3 * Real.pi * r ^ 3 ≤ 0 := by nlinarith [Real.pi_pos]
    rw [ENNReal.ofReal_of_nonpos hr.le, ENNReal.ofReal_of_nonpos h4]
    simp

/-- Three pyramids fill a cube. Take the 1 m cube with corner Q at (0, 0, 0) and the opposite
corner P at (1, 1, 1). The pyramid on the face x = 0 with tip P is every point a fraction t of
the way from P to a point (0, b, c) of that face. It is exactly the set of cube points whose
first coordinate is the smallest, that is, the points nearest that face. Renaming the
coordinates in a cycle, (x, y, z) to (z, x, y), turns the cube a third of a turn about the line
PQ; it carries this pyramid onto the pyramid on the face y = 0 and then onto the one on z = 0,
and the three pyramids together cover the whole cube. -/
theorem three_pyramids_fill_cube :
    let piece : Set (ℝ × ℝ × ℝ) :=
      {q | ∃ b ∈ Icc (0 : ℝ) 1, ∃ c ∈ Icc (0 : ℝ) 1, ∃ t ∈ Icc (0 : ℝ) 1,
        q = (1 - t, 1 - t + t * b, 1 - t + t * c)}
    let turn : ℝ × ℝ × ℝ → ℝ × ℝ × ℝ := fun q => (q.2.2, q.1, q.2.1)
    piece = {q | q ∈ Icc (0 : ℝ × ℝ × ℝ) 1 ∧ q.1 ≤ q.2.1 ∧ q.1 ≤ q.2.2} ∧
      Icc (0 : ℝ × ℝ × ℝ) 1 = piece ∪ turn '' piece ∪ turn '' (turn '' piece) := by
  intro piece turn
  have hpiece : piece = {q | q ∈ Icc (0 : ℝ × ℝ × ℝ) 1 ∧ q.1 ≤ q.2.1 ∧ q.1 ≤ q.2.2} := by
    ext ⟨x, y, z⟩
    simp only [piece, mem_ofPred_eq, mem_Icc, Prod.mk.injEq, Prod.fst_zero,
      Prod.snd_zero, Prod.fst_one, Prod.snd_one, Prod.le_def]
    constructor
    · rintro ⟨b, ⟨hb0, hb1⟩, c, ⟨hc0, hc1⟩, t, ⟨ht0, ht1⟩, rfl, rfl, rfl⟩
      refine ⟨⟨⟨by linarith, by nlinarith, by nlinarith⟩, ⟨by linarith, by nlinarith, by nlinarith⟩⟩,
        by nlinarith, by nlinarith⟩
    · rintro ⟨⟨⟨hx0, hy0, hz0⟩, ⟨hx1, hy1, hz1⟩⟩, hxy, hxz⟩
      rcases eq_or_lt_of_le hx1 with hx | hx
      · refine ⟨0, ⟨le_rfl, zero_le_one⟩, 0, ⟨le_rfl, zero_le_one⟩, 0, ⟨le_rfl, zero_le_one⟩,
          ?_, ?_, ?_⟩ <;> simp <;> linarith
      · have hpos : 0 < 1 - x := by linarith
        refine ⟨(y - x) / (1 - x), ⟨div_nonneg (by linarith) hpos.le,
            (div_le_one hpos).2 (by linarith)⟩,
          (z - x) / (1 - x), ⟨div_nonneg (by linarith) hpos.le,
            (div_le_one hpos).2 (by linarith)⟩,
          1 - x, ⟨hpos.le, by linarith⟩, by ring, ?_, ?_⟩ <;> field_simp <;> ring
  refine ⟨hpiece, ?_⟩
  have himg : ∀ S : Set (ℝ × ℝ × ℝ), turn '' S = {q | (q.2.1, q.2.2, q.1) ∈ S} := by
    intro S
    ext ⟨a, b, c⟩
    simp only [mem_image, mem_ofPred_eq, turn]
    constructor
    · rintro ⟨⟨x, y, z⟩, hS, h⟩
      simp only [Prod.mk.injEq] at h
      obtain ⟨rfl, rfl, rfl⟩ := h
      exact hS
    · intro h
      exact ⟨(b, c, a), h, rfl⟩
  rw [himg, himg, hpiece]
  ext ⟨x, y, z⟩
  simp only [mem_union, mem_ofPred_eq, mem_Icc, Prod.le_def, Prod.fst_zero,
      Prod.snd_zero, Prod.fst_one, Prod.snd_one]
  constructor
  · rintro ⟨⟨hx0, hy0, hz0⟩, ⟨hx1, hy1, hz1⟩⟩
    rcases le_total x y with hxy | hxy <;> rcases le_total x z with hxz | hxz <;>
      rcases le_total y z with hyz | hyz
    all_goals first
      | (left; left; exact ⟨⟨⟨hx0, hy0, hz0⟩, ⟨hx1, hy1, hz1⟩⟩, by linarith, by linarith⟩)
      | (left; right; exact ⟨⟨⟨hy0, hz0, hx0⟩, ⟨hy1, hz1, hx1⟩⟩, by linarith, by linarith⟩)
      | (right; exact ⟨⟨⟨hz0, hx0, hy0⟩, ⟨hz1, hx1, hy1⟩⟩, by linarith, by linarith⟩)
  · rintro ((⟨h, -⟩ | ⟨⟨⟨hy0, hz0, hx0⟩, ⟨hy1, hz1, hx1⟩⟩, -⟩) | ⟨⟨⟨hz0, hx0, hy0⟩, ⟨hz1, hx1, hy1⟩⟩, -⟩)
    · exact h
    · exact ⟨⟨hx0, hy0, hz0⟩, ⟨hx1, hy1, hz1⟩⟩
    · exact ⟨⟨hx0, hy0, hz0⟩, ⟨hx1, hy1, hz1⟩⟩

-- The hopper: rim radius 1 m, depth 3/4 m. The slant is 5/4 m, since 1² + (3/4)² = (5/4)².
example : (1 : ℚ) ^ 2 + (3 / 4) ^ 2 = (5 / 4) ^ 2 := by norm_num
-- Its volume, a third of pi × 1² × 3/4, is pi / 4: a quarter of a cubic metre for each pi,
-- the same as the bottom 1/4 m of the tank (pi × 1² × 1/4).
example : 1 / 3 * (Real.pi * 1 ^ 2) * (3 / 4) = Real.pi * 1 ^ 2 * (1 / 4) := by ring
-- The cylinder on the rim holds three times the hopper.
example : Real.pi * 1 ^ 2 * (3 / 4) = 3 * (1 / 3 * (Real.pi * 1 ^ 2) * (3 / 4)) := by ring
-- The steel: the unrolled sector is r / slant = 1 / (5/4) = 4/5 of the disc, 288 degrees,
-- and 4/5 of pi × (5/4)² is pi × 1 × 5/4.
example : (1 : ℚ) / (5 / 4) = 4 / 5 := by norm_num
example : (4 / 5 : ℚ) * 360 = 288 := by norm_num
example : 4 / 5 * (Real.pi * (5 / 4) ^ 2) = Real.pi * 1 * (5 / 4) := by ring
-- Step 1 and Step 2: one of three pyramids in a 1 m cube holds 1/3; squashed to 3/4 m tall, 1/4.
example : (1 / 3 : ℚ) * (1 * 1) * 1 = 1 / 3 := by norm_num
example : (1 / 3 : ℚ) * (1 * 1) * (3 / 4) = 1 / 4 := by norm_num
-- Step 5: 0.6 m above the middle, the half-ball's slice has radius 0.8 m, since 1 − 0.6² = 0.8².
example : (1 : ℚ) - (3 / 5) ^ 2 = (4 / 5) ^ 2 := by norm_num
-- The half-ball holds pi − pi/3 = 2 pi / 3, so the ball holds 4/3 pi, which is 2/3 of the
-- 2 m cylinder around it (pi × 1² × 2).
example : 2 * (Real.pi - Real.pi / 3) = 4 / 3 * Real.pi * 1 ^ 3 := by ring
example : 4 / 3 * Real.pi * 1 ^ 3 = 2 / 3 * (Real.pi * 1 ^ 2 * 2) := by ring
-- Step 6: a third of skin times radius gives the volume: 1/3 × 4 pi × 1 = 4/3 pi.
example : 1 / 3 * (4 * Real.pi * 1 ^ 2) * 1 = 4 / 3 * Real.pi * 1 ^ 3 := by ring
-- The usual mistake: a ball twice as wide (radius 2) holds 2³ = 8 times as much, not 2 times.
example : 4 / 3 * Real.pi * 2 ^ 3 = 8 * (4 / 3 * Real.pi * 1 ^ 3) := by ring

#print axioms pyramid_cone_volume_eq_third_base_times_height
#print axioms ball_volume_eq_four_thirds_pi_r_cubed
#print axioms three_pyramids_fill_cube
