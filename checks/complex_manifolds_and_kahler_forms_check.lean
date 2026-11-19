-- Complex manifolds and Kahler forms: the chart change w = 1/z of the projective line is holomorphic and carries the Fubini-Study density 1/(1 + |z|^2)^2 to itself, holomorphic means the dz-bar part of df is zero, and the form has area pi R^2/(1 + R^2) inside |z| <= R and pi in all.
import Mathlib.Analysis.Complex.Conformal
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Analysis.SpecialFunctions.PolarCoord
import Mathlib.MeasureTheory.Measure.Lebesgue.Complex
import Mathlib.MeasureTheory.Constructions.HaarToSphere
import Mathlib.MeasureTheory.Measure.Lebesgue.VolumeOfBalls
import Mathlib.MeasureTheory.Integral.IntegralEqImproper

open Complex MeasureTheory

lemma fs_unit_ball_real : (volume : Measure ℂ).real (Metric.ball (0 : ℂ) 1) = Real.pi := by
  simp [Measure.real, Complex.volume_ball]

#print axioms fs_unit_ball_real

lemma fs_radial (g : ℝ → ℝ) :
    ∫ z : ℂ, g ‖z‖ = 2 * Real.pi * ∫ y in Set.Ioi (0 : ℝ), y * g y := by
  rw [integral_fun_norm_addHaar volume g, fs_unit_ball_real, Complex.finrank_real_complex]
  simp only [nsmul_eq_mul, smul_eq_mul, pow_one, Nat.add_one_sub_one]
  push_cast; ring

#print axioms fs_radial

lemma fs_hasDeriv (x : ℝ) :
    HasDerivAt (fun y : ℝ => -(1 / 2) / (1 + y ^ 2)) (x / (1 + x ^ 2) ^ 2) x := by
  have h1 : (1 + x ^ 2) ≠ 0 := by positivity
  have := ((hasDerivAt_pow 2 x).const_add 1).inv h1
  convert this.const_mul (-(1 / 2) : ℝ) using 1
  · funext y; simp [div_eq_mul_inv]
  · field_simp; push_cast; ring

#print axioms fs_hasDeriv

/-- The projective line with its two charts z and w = 1/z is a complex manifold carrying the
Fubini-Study form: on the overlap z ≠ 0 the transition map w = 1/z is holomorphic with nonzero
derivative, the density read in the chart w and multiplied by the stretch factor |dw/dz|^2
equals the density 1/(1 + |z|^2)^2 read in the chart z, and that density is positive. -/
theorem fubini_study_form_same_in_both_charts (z : ℂ) (hz : z ≠ 0) :
    DifferentiableAt ℂ (fun u : ℂ => u⁻¹) z ∧ deriv (fun u : ℂ => u⁻¹) z ≠ 0 ∧
      1 / (1 + ‖z⁻¹‖ ^ 2) ^ 2 * ‖deriv (fun u : ℂ => u⁻¹) z‖ ^ 2 = 1 / (1 + ‖z‖ ^ 2) ^ 2 ∧
      0 < 1 / (1 + ‖z‖ ^ 2) ^ 2 := by
  have hd : deriv (fun u : ℂ => u⁻¹) z = -(z ^ 2)⁻¹ := deriv_inv
  have hn : 0 < ‖z‖ := norm_pos_iff.mpr hz
  refine ⟨differentiableAt_inv hz, ?_, ?_, by positivity⟩
  · rw [hd]; simp [hz]
  · rw [hd, norm_neg, norm_inv, norm_inv, norm_pow]
    field_simp
    ring

/-- The split of df: for any f on ℂ, with slopes f_x = df(1) and f_y = df(i), the differential is
df(v) = (1/2)(f_x - i f_y) v + (1/2)(f_x + i f_y) conj(v), its dz part plus its dz-bar part; and
when f is real-differentiable at z, f is holomorphic at z exactly when the dz-bar part
(1/2)(f_x + i f_y) is zero (the Cauchy-Riemann equations). -/
theorem holomorphic_iff_dzbar_part_zero (f : ℂ → ℂ) (z : ℂ) :
    (∀ v : ℂ, fderiv ℝ f z v =
        (1 / 2 : ℂ) * (fderiv ℝ f z 1 - I * fderiv ℝ f z I) * v +
          (1 / 2 : ℂ) * (fderiv ℝ f z 1 + I * fderiv ℝ f z I) * (starRingEnd ℂ) v) ∧
      (DifferentiableAt ℝ f z →
        (DifferentiableAt ℂ f z ↔ (1 / 2 : ℂ) * (fderiv ℝ f z 1 + I * fderiv ℝ f z I) = 0)) := by
  set L := fderiv ℝ f z with hL
  have hsplit : ∀ v : ℂ, L v = (v.re : ℂ) * L 1 + (v.im : ℂ) * L I := by
    intro v
    have hv : v = v.re • (1 : ℂ) + v.im • I := by
      apply Complex.ext <;> simp
    conv_lhs => rw [hv]
    rw [map_add, map_smul, map_smul, Complex.real_smul, Complex.real_smul]
  refine ⟨fun v => ?_, fun hf => ?_⟩
  · rw [hsplit v]
    apply Complex.ext <;> simp [Complex.conj_re, Complex.conj_im] <;> ring
  · rw [differentiableAt_iff_restrictScalars ℝ hf, ← hL]
    have key : (1 / 2 : ℂ) * (L 1 + I * L I) = 0 ↔ L I = I * L 1 := by
      constructor
      · intro h
        have h2 : L 1 + I * L I = 0 := by simpa using h
        have : I * (L 1 + I * L I) = 0 := by rw [h2, mul_zero]
        linear_combination -this + L I * I_sq
      · intro h
        rw [h]; ring_nf; rw [I_sq]; ring
    rw [key]
    constructor
    · rintro ⟨g, hg⟩
      have h1 : L 1 = g 1 := by rw [← hg]; rfl
      have h2 : L I = g I := by rw [← hg]; rfl
      rw [h1, h2]
      have : g I = I • g 1 := by rw [← map_smul, smul_eq_mul, mul_one]
      rw [this, smul_eq_mul]
    · intro h
      refine ⟨ContinuousLinearMap.smulRight (1 : ℂ →L[ℂ] ℂ) (L 1), ?_⟩
      ext v
      · simp only [ContinuousLinearMap.coe_restrictScalars', ContinuousLinearMap.smulRight_apply,
          one_apply_eq_self, smul_eq_mul]
        rw [hsplit v, h]
        apply Complex.ext <;> simp; ring

/-- The Fubini-Study area: the disc |z| ≤ R of the chart z (R ≥ 0) has area
pi R^2/(1 + R^2), and the whole chart z, which is the whole sphere less one point, has area pi. -/
theorem fubini_study_area (R : ℝ) (hR : 0 ≤ R) :
    ∫ z in Metric.closedBall (0 : ℂ) R, 1 / (1 + ‖z‖ ^ 2) ^ 2 = Real.pi * R ^ 2 / (1 + R ^ 2) ∧
      ∫ z : ℂ, 1 / (1 + ‖z‖ ^ 2) ^ 2 = Real.pi := by
  constructor
  · rw [← integral_indicator Metric.isClosed_closedBall.measurableSet]
    have : (Metric.closedBall (0 : ℂ) R).indicator (fun z : ℂ => 1 / (1 + ‖z‖ ^ 2) ^ 2) =
        fun z => (Set.Iic R).indicator (fun y : ℝ => 1 / (1 + y ^ 2) ^ 2) ‖z‖ := by
      funext z
      simp [Set.indicator, Metric.mem_closedBall, dist_zero_right]
    rw [this, fs_radial]
    have h2 : ∫ y in Set.Ioi (0 : ℝ), y * (Set.Iic R).indicator (fun y : ℝ => 1 / (1 + y ^ 2) ^ 2) y
        = ∫ y in (0 : ℝ)..R, y / (1 + y ^ 2) ^ 2 := by
      rw [intervalIntegral.integral_of_le hR, ← Set.Ioi_inter_Iic, Set.inter_comm, ← Measure.restrict_restrict measurableSet_Iic,
        ← integral_indicator measurableSet_Iic]
      congr 1
      funext y
      simp only [Set.indicator]
      split_ifs <;> simp [div_eq_mul_inv]
    rw [h2, intervalIntegral.integral_eq_sub_of_hasDerivAt (fun x _ => fs_hasDeriv x)]
    · field_simp; ring
    · apply Continuous.intervalIntegrable
      apply Continuous.div continuous_id (by fun_prop)
      intro x; positivity
  · rw [fs_radial (fun y => 1 / (1 + y ^ 2) ^ 2)]
    have h2 : ∫ y in Set.Ioi (0 : ℝ), y * (1 / (1 + y ^ 2) ^ 2) = 1 / 2 := by
      have := integral_Ioi_of_hasDerivAt_of_nonneg' (a := 0) (l := 0)
        (fun x _ => fs_hasDeriv x) (fun x hx => by have : (0:ℝ) < x := hx; positivity) ?_
      · simp only [mul_one_div]; rw [this]; norm_num
      · have : Filter.Tendsto (fun y : ℝ => 1 + y ^ 2) Filter.atTop Filter.atTop :=
          Filter.tendsto_atTop_add_const_left _ _ (Filter.tendsto_pow_atTop two_ne_zero)
        have h3 := (this.inv_tendsto_atTop).const_mul (-(1 / 2) : ℝ)
        rw [mul_zero] at h3
        exact h3.congr (fun y => by simp only [Pi.inv_apply]; ring)
    rw [h2]; ring

-- The card's exact worked numbers at z = 1 + i, where |z|^2 = 2.
example : ‖(1 : ℂ) + I‖ ^ 2 = 2 := by
  rw [Complex.sq_norm, Complex.normSq_apply]; norm_num
-- density in chart z: 1/(1 + 2)^2 = 1/9
example : (1 : ℚ) / (1 + 2) ^ 2 = 1 / 9 := by norm_num
-- density read in chart w, where |w|^2 = 1/2: 1/(1 + 1/2)^2 = 4/9
example : (1 : ℚ) / (1 + 1 / 2) ^ 2 = 4 / 9 := by norm_num
-- stretch factor |dw/dz|^2 = 1/|z^2|^2 = 1/|2i|^2 = 1/4, and 4/9 × 1/4 = 1/9
example : (1 : ℚ) / (0 ^ 2 + 2 ^ 2) = 1 / 4 ∧ (4 / 9 : ℚ) * (1 / 4) = 1 / 9 := by norm_num
-- the dz part of d(1/z) at 1 + i is -1/z^2 = i/2
example : -1 / ((1 : ℂ) + I) ^ 2 = I / 2 := by
  have h : ((1 : ℂ) + I) ^ 2 = 2 * I := by ring_nf; rw [I_sq]; ring_nf
  rw [h]; field_simp; rw [I_sq]
-- area shares R^2/(1 + R^2) for R = 1/2, 1, 3/2, 2, 5/2, 3, 7/2, 4
example : ((1 / 2 : ℚ) ^ 2 / (1 + (1 / 2) ^ 2), (1 : ℚ) ^ 2 / (1 + 1 ^ 2),
    (3 / 2 : ℚ) ^ 2 / (1 + (3 / 2) ^ 2), (2 : ℚ) ^ 2 / (1 + 2 ^ 2),
    (5 / 2 : ℚ) ^ 2 / (1 + (5 / 2) ^ 2), (3 : ℚ) ^ 2 / (1 + 3 ^ 2),
    (7 / 2 : ℚ) ^ 2 / (1 + (7 / 2) ^ 2), (4 : ℚ) ^ 2 / (1 + 4 ^ 2)) =
    (1 / 5, 1 / 2, 9 / 13, 4 / 5, 25 / 29, 9 / 10, 49 / 53, 16 / 17) := by norm_num
-- Archimedes' zone: height t = (R^2 - 1)/(R^2 + 1), share (t + 1)/2, here at R = 3/2
example : (((3 / 2 : ℚ) ^ 2 - 1) / ((3 / 2) ^ 2 + 1) + 1) / 2 = 9 / 13 := by norm_num
-- P^2 at (1 + i, 2 - i): N = 8, g11 = 6/64, g22 = 3/64, |g12|^2 = 10/64^2, det = 1/512 = 1/N^3
example : (1 : ℚ) + 2 + 5 = 8 ∧ (6 / 64 : ℚ) * (3 / 64) - 10 / 64 ^ 2 = 1 / 512 ∧
    (1 : ℚ) / 8 ^ 3 = 1 / 512 := by norm_num
-- the potential-free metric's mismatch |2 + i|^2 = 5
example : ‖(2 : ℂ) + I‖ ^ 2 = 5 := by
  rw [Complex.sq_norm, Complex.normSq_apply]; norm_num

#print axioms fubini_study_form_same_in_both_charts
#print axioms holomorphic_iff_dzbar_part_zero
#print axioms fubini_study_area
