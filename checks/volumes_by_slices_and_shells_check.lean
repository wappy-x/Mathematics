-- Volumes: a solid made by spinning a flat region round an axis has volume equal to the disc integral of pi r squared along the axis, the washer integral of pi (R squared minus r squared), and the shell integral of 2 pi rho times the tube length, and the wine glass bowl holds 100 pi.
import Mathlib.MeasureTheory.Measure.Lebesgue.VolumeOfBalls
import Mathlib.MeasureTheory.Measure.Prod
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.MeasureTheory.Constructions.HaarToSphere

open MeasureTheory Set
open scoped Real

/-! Space is modelled as `EuclideanSpace ℝ (Fin 2) × ℝ`: a point `q.1` of the flat plane square
on (at right angles) to the axis, and a height `q.2` up the axis. The axis is the line of points
whose plane part is `0`, so a point's distance from the axis is `‖q.1‖`. The `volume` of this
space is area on the plane times length up the axis: ordinary volume in three dimensions. -/

/-- Volume from slices: a solid whose slice at height `y` has area `f y` on `[a, b]`, and is
empty elsewhere, has volume the integral of `f`. -/
lemma volume_eq_of_slices (S : Set (EuclideanSpace ℝ (Fin 2) × ℝ)) (hS : MeasurableSet S)
    (f : ℝ → ℝ) (a b : ℝ) (hab : a ≤ b) (hf : ContinuousOn f (Icc a b))
    (hf0 : ∀ y ∈ Icc a b, 0 ≤ f y)
    (hslice : ∀ y, volume ((fun x => (x, y)) ⁻¹' S) = (Icc a b).indicator (fun y => ENNReal.ofReal (f y)) y) :
    volume S = ENNReal.ofReal (∫ y in a..b, f y) := by
  rw [Measure.volume_eq_prod, Measure.prod_apply_symm hS]
  simp_rw [hslice]
  rw [lintegral_indicator measurableSet_Icc,
    ← ofReal_integral_eq_lintegral_ofReal (hf.integrableOn_compact isCompact_Icc)
      ((ae_restrict_iff' measurableSet_Icc).2 (Filter.Eventually.of_forall hf0)),
    intervalIntegral.integral_of_le hab, integral_Icc_eq_integral_Ioc]

/-- A function continuous on `[a, b]`, clamped, is continuous everywhere. -/
lemma continuous_clamp (f : ℝ → ℝ) (a b : ℝ) (hab : a ≤ b) (hf : ContinuousOn f (Icc a b)) :
    Continuous (fun y => f (max a (min b y))) :=
  hf.comp_continuous (by fun_prop) (fun y => ⟨le_max_left _ _, max_le hab (min_le_left _ _)⟩)

/-- Clamping leaves points of `[a, b]` alone. -/
lemma clamp_eq (a b y : ℝ) (hy : y ∈ Icc a b) : max a (min b y) = y := by
  rw [min_eq_right hy.2, max_eq_right hy.1]

#print axioms volume_eq_of_slices
#print axioms continuous_clamp
#print axioms clamp_eq

/-- Discs. Spin round the axis the region under a radius `r(y)`, for heights y from a to b, where
every radius is a distance from the axis (never negative) and the radius is an unbroken
(continuous) function of height. The solid holds the integral from a to b of the slice area
pi r(y)², exactly. -/
theorem volume_solid_of_revolution_eq_disc_integral
    (r : ℝ → ℝ) (a b : ℝ) (hab : a ≤ b)
    (hr : ContinuousOn r (Icc a b)) (hr0 : ∀ y ∈ Icc a b, 0 ≤ r y) :
    volume {q : EuclideanSpace ℝ (Fin 2) × ℝ | q.2 ∈ Icc a b ∧ ‖q.1‖ ≤ r q.2}
      = ENNReal.ofReal (∫ y in a..b, π * r y ^ 2) := by
  have hc := continuous_clamp r a b hab hr
  set r' := fun y => r (max a (min b y))
  have hS : {q : EuclideanSpace ℝ (Fin 2) × ℝ | q.2 ∈ Icc a b ∧ ‖q.1‖ ≤ r q.2}
      = {q : EuclideanSpace ℝ (Fin 2) × ℝ | q.2 ∈ Icc a b ∧ ‖q.1‖ ≤ r' q.2} := by
    ext q
    simp only [mem_setOf_eq, r']
    constructor
    · rintro ⟨h1, h2⟩; exact ⟨h1, by rwa [clamp_eq a b _ h1]⟩
    · rintro ⟨h1, h2⟩; exact ⟨h1, by rwa [clamp_eq a b _ h1] at h2⟩
  rw [hS]
  apply volume_eq_of_slices _ _ (fun y => π * r y ^ 2) a b hab (by fun_prop)
  · intro y hy; have := hr0 y hy; positivity
  · intro y
    by_cases hy : y ∈ Icc a b
    · rw [indicator_of_mem hy]
      have : (fun x : EuclideanSpace ℝ (Fin 2) => (x, y)) ⁻¹'
          {q : EuclideanSpace ℝ (Fin 2) × ℝ | q.2 ∈ Icc a b ∧ ‖q.1‖ ≤ r' q.2}
          = Metric.closedBall 0 (r y) := by
        ext x; simp [r', hy.1, hy.2]
      rw [this, EuclideanSpace.volume_closedBall_fin_two, ← ENNReal.ofReal_pow (hr0 y hy),
        ← ENNReal.ofReal_mul (by positivity), mul_comm]
    · rw [indicator_of_notMem hy]
      have : (fun x : EuclideanSpace ℝ (Fin 2) => (x, y)) ⁻¹'
          {q : EuclideanSpace ℝ (Fin 2) × ℝ | q.2 ∈ Icc a b ∧ ‖q.1‖ ≤ r' q.2} = ∅ := by
        ext x
        simp only [mem_preimage, mem_setOf_eq, mem_empty_iff_false, iff_false]
        exact fun h => hy h.1
      rw [this, measure_empty]
  · exact (measurableSet_Icc.preimage measurable_snd).inter
      (measurableSet_le (by fun_prop) (hc.measurable.comp measurable_snd))

/-- Washers. A solid of revolution with a hole: at height y, from a to b, it fills the points
farther than the hole's radius r(y) from the axis and no farther than the outer radius R(y),
the hole lying inside the outer edge (0 ≤ r(y) ≤ R(y)), both radii unbroken (continuous).
Its volume is the integral of pi R(y)² minus pi r(y)²: areas subtracted, not radii. -/
theorem volume_washer_solid_eq_integral
    (r R : ℝ → ℝ) (a b : ℝ) (hab : a ≤ b)
    (hr : ContinuousOn r (Icc a b)) (hR : ContinuousOn R (Icc a b))
    (hrR : ∀ y ∈ Icc a b, 0 ≤ r y ∧ r y ≤ R y) :
    volume {q : EuclideanSpace ℝ (Fin 2) × ℝ |
        q.2 ∈ Icc a b ∧ r q.2 < ‖q.1‖ ∧ ‖q.1‖ ≤ R q.2}
      = ENNReal.ofReal (∫ y in a..b, π * (R y ^ 2 - r y ^ 2)) := by
  have hc := continuous_clamp r a b hab hr
  have hC := continuous_clamp R a b hab hR
  set r' := fun y => r (max a (min b y))
  set R' := fun y => R (max a (min b y))
  have hS : {q : EuclideanSpace ℝ (Fin 2) × ℝ |
        q.2 ∈ Icc a b ∧ r q.2 < ‖q.1‖ ∧ ‖q.1‖ ≤ R q.2}
      = {q : EuclideanSpace ℝ (Fin 2) × ℝ |
        q.2 ∈ Icc a b ∧ r' q.2 < ‖q.1‖ ∧ ‖q.1‖ ≤ R' q.2} := by
    ext q
    simp only [mem_setOf_eq, r', R']
    constructor
    · rintro ⟨h1, h2⟩; rw [clamp_eq a b _ h1]; exact ⟨h1, h2⟩
    · rintro ⟨h1, h2⟩; rw [clamp_eq a b _ h1] at h2; exact ⟨h1, h2⟩
  rw [hS]
  apply volume_eq_of_slices _ _ (fun y => π * (R y ^ 2 - r y ^ 2)) a b hab (by fun_prop)
  · intro y hy
    have h := hrR y hy
    have : r y ^ 2 ≤ R y ^ 2 := pow_le_pow_left₀ h.1 h.2 2
    have := Real.pi_pos
    nlinarith
  · intro y
    by_cases hy : y ∈ Icc a b
    · rw [indicator_of_mem hy]
      have h := hrR y hy
      have : (fun x : EuclideanSpace ℝ (Fin 2) => (x, y)) ⁻¹'
          {q : EuclideanSpace ℝ (Fin 2) × ℝ | q.2 ∈ Icc a b ∧ r' q.2 < ‖q.1‖ ∧ ‖q.1‖ ≤ R' q.2}
          = Metric.closedBall 0 (R y) \ Metric.closedBall 0 (r y) := by
        ext x; simp [r', R', hy.1, hy.2, and_comm]
      rw [this, measure_sdiff (Metric.closedBall_subset_closedBall h.2)
          measurableSet_closedBall.nullMeasurableSet measure_closedBall_lt_top.ne,
        EuclideanSpace.volume_closedBall_fin_two, EuclideanSpace.volume_closedBall_fin_two,
        ← ENNReal.ofReal_pow h.1, ← ENNReal.ofReal_pow (h.1.trans h.2),
        ← ENNReal.ofReal_mul (by positivity), ← ENNReal.ofReal_mul (by positivity),
        ← ENNReal.ofReal_sub _ (by positivity)]
      congr 1; ring
    · rw [indicator_of_notMem hy]
      have : (fun x : EuclideanSpace ℝ (Fin 2) => (x, y)) ⁻¹'
          {q : EuclideanSpace ℝ (Fin 2) × ℝ | q.2 ∈ Icc a b ∧ r' q.2 < ‖q.1‖ ∧ ‖q.1‖ ≤ R' q.2}
          = ∅ := by
        ext x
        simp only [mem_preimage, mem_setOf_eq, mem_empty_iff_false, iff_false]
        exact fun h => hy h.1
      rw [this, measure_empty]
  · exact (measurableSet_Icc.preimage measurable_snd).inter
      ((measurableSet_lt (hc.measurable.comp measurable_snd) (by fun_prop)).inter
      (measurableSet_le (by fun_prop) (hC.measurable.comp measurable_snd)))

/-- Shells. A solid of revolution cut into tubes round the axis: the tube at distance ρ from the
axis, for ρ from 0 to c, runs up the axis from height g(ρ) for a length ℓ(ρ) ≥ 0, with g and ℓ
unbroken (continuous). Counting each distance once, from 0 up, the solid holds the integral
from 0 to c of circumference times length, 2 pi ρ ℓ(ρ). -/
theorem volume_solid_of_revolution_eq_shell_integral
    (g ℓ : ℝ → ℝ) (c : ℝ) (hc : 0 ≤ c)
    (hg : ContinuousOn g (Icc 0 c)) (hℓ : ContinuousOn ℓ (Icc 0 c))
    (hℓ0 : ∀ ρ ∈ Icc 0 c, 0 ≤ ℓ ρ) :
    volume {q : EuclideanSpace ℝ (Fin 2) × ℝ |
        ‖q.1‖ ≤ c ∧ g ‖q.1‖ ≤ q.2 ∧ q.2 ≤ g ‖q.1‖ + ℓ ‖q.1‖}
      = ENNReal.ofReal (∫ ρ in (0 : ℝ)..c, 2 * π * ρ * ℓ ρ) := by
  have hgc := continuous_clamp g 0 c hc hg
  have hℓc := continuous_clamp ℓ 0 c hc hℓ
  set g' := fun y => g (max 0 (min c y))
  set ℓ' := fun y => ℓ (max 0 (min c y))
  have hℓ'0 : ∀ y, 0 ≤ ℓ' y := fun y =>
    hℓ0 _ ⟨le_max_left _ _, max_le hc (min_le_left _ _)⟩
  have hS : {q : EuclideanSpace ℝ (Fin 2) × ℝ |
        ‖q.1‖ ≤ c ∧ g ‖q.1‖ ≤ q.2 ∧ q.2 ≤ g ‖q.1‖ + ℓ ‖q.1‖}
      = {q : EuclideanSpace ℝ (Fin 2) × ℝ |
        ‖q.1‖ ≤ c ∧ g' ‖q.1‖ ≤ q.2 ∧ q.2 ≤ g' ‖q.1‖ + ℓ' ‖q.1‖} := by
    ext q
    simp only [mem_setOf_eq, g', ℓ']
    constructor
    · rintro ⟨h1, h2⟩; rw [clamp_eq 0 c _ ⟨norm_nonneg _, h1⟩]; exact ⟨h1, h2⟩
    · rintro ⟨h1, h2⟩; rw [clamp_eq 0 c _ ⟨norm_nonneg _, h1⟩] at h2; exact ⟨h1, h2⟩
  have hmeas : MeasurableSet {q : EuclideanSpace ℝ (Fin 2) × ℝ |
        ‖q.1‖ ≤ c ∧ g' ‖q.1‖ ≤ q.2 ∧ q.2 ≤ g' ‖q.1‖ + ℓ' ‖q.1‖} := by
    have h1 : Measurable fun q : EuclideanSpace ℝ (Fin 2) × ℝ => g' ‖q.1‖ :=
      hgc.measurable.comp (by fun_prop)
    have h2 : Measurable fun q : EuclideanSpace ℝ (Fin 2) × ℝ => ℓ' ‖q.1‖ :=
      hℓc.measurable.comp (by fun_prop)
    exact (measurableSet_le (measurable_norm.comp measurable_fst) measurable_const).inter
      ((measurableSet_le h1 measurable_snd).inter
      (measurableSet_le measurable_snd (h1.add h2)))
  rw [hS, Measure.volume_eq_prod, Measure.prod_apply hmeas]
  have hslice : ∀ x : EuclideanSpace ℝ (Fin 2),
      volume (Prod.mk x ⁻¹' {q : EuclideanSpace ℝ (Fin 2) × ℝ |
        ‖q.1‖ ≤ c ∧ g' ‖q.1‖ ≤ q.2 ∧ q.2 ≤ g' ‖q.1‖ + ℓ' ‖q.1‖})
      = ENNReal.ofReal ((Metric.closedBall (0 : EuclideanSpace ℝ (Fin 2)) c).indicator
          (fun x => ℓ' ‖x‖) x) := by
    intro x
    by_cases hx : ‖x‖ ≤ c
    · have : Prod.mk x ⁻¹' {q : EuclideanSpace ℝ (Fin 2) × ℝ |
          ‖q.1‖ ≤ c ∧ g' ‖q.1‖ ≤ q.2 ∧ q.2 ≤ g' ‖q.1‖ + ℓ' ‖q.1‖}
          = Icc (g' ‖x‖) (g' ‖x‖ + ℓ' ‖x‖) := by
        ext y; simp [hx]
      rw [this, Real.volume_Icc, indicator_of_mem (by simpa using hx)]
      congr 1; ring
    · have : Prod.mk x ⁻¹' {q : EuclideanSpace ℝ (Fin 2) × ℝ |
          ‖q.1‖ ≤ c ∧ g' ‖q.1‖ ≤ q.2 ∧ q.2 ≤ g' ‖q.1‖ + ℓ' ‖q.1‖} = ∅ := by
        ext y; simp [hx]
      rw [this, measure_empty, indicator_of_notMem (by simpa using hx), ENNReal.ofReal_zero]
  simp_rw [hslice]
  have hint : Integrable ((Metric.closedBall (0 : EuclideanSpace ℝ (Fin 2)) c).indicator
          (fun x => ℓ' ‖x‖)) :=
    ((hℓc.comp continuous_norm).continuousOn.integrableOn_compact (isCompact_closedBall 0 c)).integrable_indicator
      measurableSet_closedBall
  rw [← ofReal_integral_eq_lintegral_ofReal hint
    (Filter.Eventually.of_forall fun x => indicator_nonneg (fun x _ => hℓ'0 _) x)]
  congr 1
  have hfun : (Metric.closedBall (0 : EuclideanSpace ℝ (Fin 2)) c).indicator (fun x => ℓ' ‖x‖)
      = fun x => (Iic c).indicator ℓ' ‖x‖ := by
    funext x
    by_cases hx : ‖x‖ ≤ c
    · rw [indicator_of_mem (by simpa using hx), indicator_of_mem (by simpa using hx)]
    · rw [indicator_of_notMem (by simpa using hx), indicator_of_notMem (by simpa using hx)]
  rw [hfun, integral_fun_norm_addHaar volume ((Iic c).indicator ℓ')]
  have hfun2 : (fun y : ℝ => y ^ (Module.finrank ℝ (EuclideanSpace ℝ (Fin 2)) - 1) •
      (Iic c).indicator ℓ' y) = (Iic c).indicator (fun y => y * ℓ' y) := by
    funext y
    by_cases hy : y ∈ Iic c <;> simp [hy]
  rw [hfun2, setIntegral_indicator measurableSet_Iic, Ioi_inter_Iic,
    intervalIntegral.integral_of_le hc]
  have hball : volume.real (Metric.ball (0 : EuclideanSpace ℝ (Fin 2)) 1) = π := by
    simp [Measure.real, Real.pi_pos.le]
  rw [hball, finrank_euclideanSpace_fin]
  simp_rw [mul_assoc]
  rw [integral_const_mul, integral_const_mul, nsmul_eq_mul, smul_eq_mul]
  have : ∫ y in Ioc 0 c, y * ℓ' y = ∫ y in Ioc 0 c, y * ℓ y := by
    refine setIntegral_congr_fun measurableSet_Ioc fun y hy => ?_
    simp only [ℓ', clamp_eq 0 c y ⟨hy.1.le, hy.2⟩]
  rw [this]; push_cast; ring

-- The bowl's wall is y = r²/2: 2 cm out it stands 2 cm high, 4 cm out 8 cm, and the 10 cm rim
-- sits where r² = 20.
example : (2 : ℚ) ^ 2 / 2 = 2 ∧ (4 : ℚ) ^ 2 / 2 = 8 ∧ (2 : ℚ) * 10 = 20 := by norm_num
-- Discs: the slice area is pi r² = 2 pi y, and adding them from 0 to 10 cm gives 100 pi.
example : ∫ y in (0 : ℝ)..10, π * (2 * y) = 100 * π := by
  rw [intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul, integral_id]
  norm_num
  ring
-- Discs by the antiderivative: pi y² at 10 is 100 pi.
example : π * 10 ^ 2 = 100 * π := by ring
-- Shells: 2 pi (5 rho² - rho⁴/8) at rho² = 20 is 2 pi (100 - 50) = 100 pi.
example : 2 * π * (5 * 20 - 20 ^ 2 / 8) = 100 * π := by ring
-- Shells, as an integral: tubes 2 pi rho (10 - rho²/2) from 0 to the rim, sqrt 20, add to 100 pi.
example : ∫ ρ in (0 : ℝ)..√20, 2 * π * ρ * (10 - ρ ^ 2 / 2) = 100 * π := by
  have h : ∀ ρ : ℝ, 2 * π * ρ * (10 - ρ ^ 2 / 2) = 20 * π * ρ ^ 1 - π * ρ ^ 3 := fun ρ => by ring
  simp_rw [h]
  rw [intervalIntegral.integral_sub, intervalIntegral.integral_const_mul,
    intervalIntegral.integral_const_mul, integral_pow, integral_pow]
  · have h2 : (√20 : ℝ) ^ 2 = 20 := Real.sq_sqrt (by norm_num)
    have h4 : (√20 : ℝ) ^ 4 = 400 := by rw [show (4 : ℕ) = 2 * 2 from rfl, pow_mul, h2]; norm_num
    norm_num [h2, h4]
    ring
  all_goals exact (Continuous.intervalIntegrable (by fun_prop) _ _)
-- The can round the bowl: pi × 20 × 10 = 200 pi, twice the bowl's 100 pi.
example : π * 20 * 10 = 2 * (100 * π) := by ring
-- The disc squeeze's gap: pi (r(b)² - r(a)²)(b - a) = pi (20 - 0) × 10 = 200 pi, over n slices.
example : π * (20 - 0) * 10 = 200 * π := by ring
-- The shell squeeze's bound: 2 pi c² (ℓ(0) - ℓ(c)) = 2 pi × 20 × (10 - 0) = 400 pi, over n tubes.
example : 2 * π * 20 * (10 - 0) = 400 * π := by ring
-- Washers for the glass: the outer radius² 2(y + 3/10) minus the hole's 2y is 3/5 at every
-- height, so each washer is 2 pi × 3/10.
example (y : ℝ) : π * (2 * (y + 3 / 10) - 2 * y) = 2 * π * (3 / 10) := by ring
-- The glass: 2 pi × 3/10 × 10 for the wall plus pi (3/10)² for the cap is 609/100 pi (6.09 pi).
example : 2 * π * (3 / 10) * 10 + π * (3 / 10) ^ 2 = 609 / 100 * π := by ring
-- The usual mistake: filled to half the depth, 5 cm, the bowl holds pi × 5² = 25 pi, a quarter
-- of 100 pi.
example : π * 5 ^ 2 * 4 = π * 10 ^ 2 := by ring

#print axioms volume_solid_of_revolution_eq_disc_integral
#print axioms volume_washer_solid_eq_integral
#print axioms volume_solid_of_revolution_eq_shell_integral
