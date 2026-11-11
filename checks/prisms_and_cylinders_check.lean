-- Prisms and cylinders: a solid whose every horizontal slice is a congruent copy of its base, from height 0 up to height h, has volume equal to the base's area times h, and so a cylinder of radius r and height h holds π r² h.
import Mathlib.MeasureTheory.Measure.Lebesgue.VolumeOfBalls
import Mathlib.MeasureTheory.Measure.Prod
import Mathlib.Data.Int.Interval
import Mathlib.Data.Finset.Prod
import Mathlib.Analysis.Normed.Affine.MazurUlam
import Mathlib.MeasureTheory.Measure.Haar.InnerProductSpace

open MeasureTheory Metric Set
open scoped Real ENNReal

/-! Space is modelled as `EuclideanSpace ℝ (Fin 2) × ℝ`: a point of the flat base plane, and a
height measured square on (at right angles) to that plane. Its `volume` is the product of area
on the plane and length on the height axis, which is ordinary volume in three dimensions.
The horizontal slice of a solid `S` at height `z` is the set of base-plane points `p` with
`(p, z) ∈ S`. -/

/-- A distance-keeping map of the plane does not change the area of any set. -/
theorem volume_image_isometryEquiv (e : EuclideanSpace ℝ (Fin 2) ≃ᵢ EuclideanSpace ℝ (Fin 2))
    (B : Set (EuclideanSpace ℝ (Fin 2))) : volume (e '' B) = volume B := by
  set g := e.symm
  set f := g.trans (IsometryEquiv.addRight (g 0)).symm
  have hf0 : f 0 = 0 := by simp [f]
  set L := f.toRealLinearIsometryEquivOfMapZero hf0
  have hg : ∀ x, g x = L x + g 0 := by
    intro x
    simp [L, IsometryEquiv.coe_toRealLinearIsometryEquivOfMapZero, f]
  have himg : e '' B = L ⁻¹' ((· + g 0) ⁻¹' B) := by
    rw [show ⇑e '' B = ⇑e.symm ⁻¹' B from e.toEquiv.image_eq_preimage_symm B]
    ext x
    show g x ∈ B ↔ L x + g 0 ∈ B
    rw [hg]
  rw [himg, (LinearIsometryEquiv.measurePreserving L).measure_preimage_emb
    L.toHomeomorph.measurableEmbedding, measure_preimage_add_right]

#print axioms volume_image_isometryEquiv

/-- Volume is cross-section times height. Take a base `B` in the plane and a solid `S` whose
horizontal slice at every height from 0 to h is a congruent copy of `B` (moved by some
distance-keeping map of the plane, which may shift it sideways, so leaning prisms count), and
which has nothing outside those heights. Then the solid holds the base's area times the
height h, measured square on. -/
theorem volume_eq_base_area_mul_height
    (B : Set (EuclideanSpace ℝ (Fin 2))) (S : Set (EuclideanSpace ℝ (Fin 2) × ℝ)) (h : ℝ)
    (hS : MeasurableSet S)
    (hslice : ∀ z ∈ Icc (0 : ℝ) h,
      ∃ e : EuclideanSpace ℝ (Fin 2) ≃ᵢ EuclideanSpace ℝ (Fin 2), {p | (p, z) ∈ S} = e '' B)
    (hout : ∀ z ∉ Icc (0 : ℝ) h, {p | (p, z) ∈ S} = ∅) :
    volume S = volume B * ENNReal.ofReal h := by
  rw [Measure.volume_eq_prod, Measure.prod_apply_symm hS]
  have hz : ∀ z, volume ((fun x => (x, z)) ⁻¹' S)
      = (Icc (0 : ℝ) h).indicator (fun _ => volume B) z := by
    intro z
    by_cases hzI : z ∈ Icc (0 : ℝ) h
    · obtain ⟨e, he⟩ := hslice z hzI
      rw [indicator_of_mem hzI, ← volume_image_isometryEquiv e B, ← he]
      rfl
    · rw [indicator_of_notMem hzI]
      have := hout z hzI
      change volume {p | (p, z) ∈ S} = 0
      rw [this, measure_empty]
  simp_rw [hz]
  rw [lintegral_indicator_const measurableSet_Icc, Real.volume_Icc, sub_zero]

/-- The cylinder. An upright cylinder whose base is a disc of radius r (centre to rim) and whose
height is h holds π r² h: base area π r² times height. -/
theorem cylinder_volume_eq_pi_mul_radius_sq_mul_height
    (c : EuclideanSpace ℝ (Fin 2)) (r h : ℝ) (hr : 0 ≤ r) :
    volume (closedBall c r ×ˢ Icc (0 : ℝ) h) = ENNReal.ofReal (π * r ^ 2 * h) := by
  rw [Measure.volume_eq_prod, Measure.prod_prod, EuclideanSpace.volume_closedBall_fin_two, Real.volume_Icc,
    sub_zero, ← ENNReal.ofReal_pow hr, ← ENNReal.ofReal_mul (by positivity),
    ← ENNReal.ofReal_mul (by positivity)]
  congr 1
  ring

/-- The usual mistake, measured. A cylinder twice as wide but just as tall holds four times
as much, because the radius is squared: putting the width in for the radius gives four times
the true volume. -/
theorem cylinder_double_radius_four_times_volume
    (c : EuclideanSpace ℝ (Fin 2)) (r h : ℝ) :
    volume (closedBall c (2 * r) ×ˢ Icc (0 : ℝ) h)
      = 4 * volume (closedBall c r ×ˢ Icc (0 : ℝ) h) := by
  rcases lt_or_ge r 0 with hr | hr
  · rw [closedBall_eq_empty.mpr (by linarith), closedBall_eq_empty.mpr hr]
    simp
  · rw [cylinder_volume_eq_pi_mul_radius_sq_mul_height c (2 * r) h (by linarith),
      cylinder_volume_eq_pi_mul_radius_sq_mul_height c r h hr,
      show (4 : ℝ≥0∞) = ENNReal.ofReal 4 by norm_num, ← ENNReal.ofReal_mul (by norm_num)]
    congr 1
    ring

-- A cubic metre holds 10 × 10 × 10 litre cubes.
example : 10 * 10 * 10 = 1000 := by decide
-- The square box the tank fits in, 2 m by 2 m by 3 m: 20 × 20 = 400 litre cubes a layer.
example : 20 * 20 = 400 := by decide
-- 30 layers, each 10 cm deep, fill it: 12000 litres.
example : 400 * 30 = 12000 := by decide
-- The box's walls unroll into one rectangle 8 m (once round the floor) by 3 m: 24 square metres.
example : (2 + 2 + 2 + 2) * 3 = 24 := by decide
-- Floor and lid add 4 square metres each: 32 square metres in all.
example : 24 + 2 * (2 * 2) = 32 := by decide
-- Litre cubes on the tank's floor (radius 10 cube edges): 276 squares lie wholly inside the
-- circle (farthest corner inside), and 30 layers give 8280 litres.
example :
    ((Finset.Ico (-10 : ℤ) 10 ×ˢ Finset.Ico (-10 : ℤ) 10).filter
      (fun q : ℤ × ℤ => max (q.1 * q.1) ((q.1 + 1) * (q.1 + 1))
        + max (q.2 * q.2) ((q.2 + 1) * (q.2 + 1)) ≤ 100)).card = 276 := by
  decide +kernel
example : 276 * 30 = 8280 := by decide
-- 344 squares touch the circle (nearest corner inside), and 30 layers give 10320 litres.
example :
    ((Finset.Ico (-10 : ℤ) 10 ×ˢ Finset.Ico (-10 : ℤ) 10).filter
      (fun q : ℤ × ℤ => min (q.1 * q.1) ((q.1 + 1) * (q.1 + 1))
        + min (q.2 * q.2) ((q.2 + 1) * (q.2 + 1)) < 100)).card = 344 := by
  decide +kernel
example : 344 * 30 = 10320 := by decide

#print axioms volume_eq_base_area_mul_height
#print axioms cylinder_volume_eq_pi_mul_radius_sq_mul_height
#print axioms cylinder_double_radius_four_times_volume
