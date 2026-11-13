-- Two walls: the image sum of bell curves for a driftless walk between walls a < 0 < b converges and is zero on both walls, reweighting one image for drift gives the range bet from a shifted rate times e^{λc}, and knock-in plus knock-out is the plain option (with the double one-touch D minus the double no-touch) under any pricing measure.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.Topology.Algebra.InfiniteSum.Basic
import Mathlib.NumberTheory.ModularForms.JacobiTheta.TwoVariable

open Real ProbabilityTheory MeasureTheory
open scoped NNReal

namespace DoubleBarrier


/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- Image `n` of the driftless walk between the walls `a` and `b` on the log scale, with
corridor width `w = b - a` and the year's variance `v = σ²T`: a plus bell curve centred at
`2nw` minus a minus bell curve centred at `2b + 2nw`, read at the end point `x`. -/
noncomputable def imageTerm (a b : ℝ) (v : ℝ≥0) (x : ℝ) (n : ℤ) : ℝ :=
  gaussianPDFReal (2 * n * (b - a)) v x - gaussianPDFReal (2 * b + 2 * n * (b - a)) v x

/-- The card's driftless survival density by images,
`p₀(x) = Σₙ [φ_v(x - 2nw) - φ_v(x - 2b - 2nw)]`, summed over every whole number `n`. -/
noncomputable def imageDensity (a b : ℝ) (v : ℝ≥0) (x : ℝ) : ℝ :=
  ∑' n : ℤ, imageTerm a b v x n

/-- Bell curves at an evenly spaced lattice of centres `c + 2nw` are summable over `n : ℤ`. -/
theorem summable_gaussian_lattice (c w x : ℝ) (v : ℝ≥0) (hw : w ≠ 0) (hv : v ≠ 0) :
    Summable (fun n : ℤ => gaussianPDFReal (c + 2 * n * w) v x) := by
  have hv' : (0 : ℝ) < v := by positivity
  set y := x - c
  set T : ℝ := 2 * w ^ 2 / (π * v)
  set S : ℝ := |w| * |y| / (π * v)
  have hT : 0 < T := by positivity
  have hsum := (summable_pow_mul_jacobiTheta₂_term_bound S hT 0).mul_left (√(2 * π * v))⁻¹
  refine Summable.of_nonneg_of_le (fun n => gaussianPDFReal_nonneg _ _ _) (fun n => ?_) hsum
  simp only [gaussianPDFReal, pow_zero, one_mul]
  gcongr
  have key : -π * (T * (n : ℝ) ^ 2 - 2 * S * |(n : ℝ)|) =
      -(4 * w ^ 2 * (n : ℝ) ^ 2 - 4 * |w| * |y| * |(n : ℝ)|) / (2 * v) := by
    simp only [T, S]; field_simp; ring
  rw [Int.cast_abs, key]
  apply div_le_div_of_nonneg_right _ (by positivity)
  have h1 : y * (n : ℝ) * w ≤ |y| * |(n : ℝ)| * |w| := by
    rw [← abs_mul, ← abs_mul]; exact le_abs_self _
  have h2 : (x - (c + 2 * n * w)) = y - 2 * n * w := by simp only [y]; ring
  rw [h2]
  nlinarith [h1, sq_nonneg y]

#print axioms summable_gaussian_lattice

/-- Completing the square: tilting a bell curve by `e^{λx - λ²v/2}` shifts its centre by `λv`
and multiplies it by `e^{λc}`. -/
theorem exp_tilt_gaussianPDFReal (lam c : ℝ) (v : ℝ≥0) (hv : v ≠ 0) (x : ℝ) :
    exp (lam * x - lam ^ 2 * v / 2) * gaussianPDFReal c v x =
      exp (lam * c) * gaussianPDFReal (c + lam * v) v x := by
  have hv' : (v : ℝ) ≠ 0 := by exact_mod_cast hv
  simp only [gaussianPDFReal]
  rw [mul_left_comm, mul_left_comm (exp (lam * c)), ← exp_add, ← exp_add]
  congr 2
  field_simp
  ring

#print axioms exp_tilt_gaussianPDFReal

/-- The standard normal CDF as an integral of the standard bell curve. -/
theorem stdNormalCDF_eq_integral (y : ℝ) :
    stdNormalCDF y = ∫ t in Set.Iic y, gaussianPDFReal 0 1 t := by
  rw [stdNormalCDF, cdf_eq_real, measureReal_def,
    gaussianReal_apply_eq_integral _ one_ne_zero, ENNReal.toReal_ofReal]
  exact setIntegral_nonneg measurableSet_Iic (fun t _ => gaussianPDFReal_nonneg _ _ _)

#print axioms stdNormalCDF_eq_integral

/-- Area under any bell curve over a window, in terms of the standard normal CDF. -/
theorem intervalIntegral_gaussianPDFReal (μ lo hi : ℝ) (v : ℝ≥0) (hv : v ≠ 0) :
    ∫ x in lo..hi, gaussianPDFReal μ v x =
      stdNormalCDF ((hi - μ) / √(v : ℝ)) - stdNormalCDF ((lo - μ) / √(v : ℝ)) := by
  have hv' : (0 : ℝ) < v := by positivity
  set s := √(v : ℝ) with hs_def
  have hs : 0 < s := Real.sqrt_pos.mpr hv'
  have hs2 : s ^ 2 = v := Real.sq_sqrt hv'.le
  have hpt : ∀ x, gaussianPDFReal μ v x = s⁻¹ * gaussianPDFReal 0 1 (x / s - μ / s) := by
    intro x
    simp only [gaussianPDFReal, NNReal.coe_one, mul_one, sub_zero]
    rw [← mul_assoc, ← mul_inv, hs_def, ← Real.sqrt_mul (by positivity) (2 * π),
      mul_comm (v : ℝ)]
    congr 2
    rw [show x / s - μ / s = (x - μ) / s by ring, div_pow, hs2]
    field_simp
  simp_rw [hpt]
  rw [intervalIntegral.integral_const_mul, intervalIntegral.integral_comp_div_sub (fun t => gaussianPDFReal 0 1 t) hs.ne' (μ / s),
    stdNormalCDF_eq_integral, stdNormalCDF_eq_integral,
    intervalIntegral.integral_Iic_sub_Iic (integrable_gaussianPDFReal _ _).integrableOn
      (integrable_gaussianPDFReal _ _).integrableOn, smul_eq_mul, ← mul_assoc,
    inv_mul_cancel₀ hs.ne', one_mul]
  congr 1 <;> ring

#print axioms intervalIntegral_gaussianPDFReal

/-- **Two mirrors make a hall of mirrors that settles** (Steps 2 and 4, Detailed proof). Put
today's rate at 0 on the log scale with the walls strictly on either side, `a < 0 < b`, and take
a positive variance `v = σ²T`. Then the alternating sum of bell curves, plus terms at `2nw` and
minus terms at `2b + 2nw` for every whole number `n`, converges at every end point `x`, and it is
exactly zero on the upper wall `b` and on the lower wall `a`: every touched path is cancelled. -/
theorem image_sum_converges_and_vanishes_on_both_walls (a b : ℝ) (v : ℝ≥0)
    (ha : a < 0) (hb : 0 < b) (hv : v ≠ 0) :
    (∀ x : ℝ, Summable (imageTerm a b v x)) ∧
      imageDensity a b v b = 0 ∧ imageDensity a b v a = 0 := by
  have hw : b - a ≠ 0 := by linarith
  have hsum : ∀ c x : ℝ, Summable (fun n : ℤ => gaussianPDFReal (c + 2 * n * (b - a)) v x) :=
    fun c x => summable_gaussian_lattice c (b - a) x v hw hv
  have hsum0 : ∀ x : ℝ, Summable (fun n : ℤ => gaussianPDFReal (2 * n * (b - a)) v x) := by
    intro x; simpa using hsum 0 x
  refine ⟨fun x => (hsum0 x).sub (hsum (2 * b) x), ?_, ?_⟩
  · -- on the upper wall the minus image at `n` is the plus image at `-n`
    let e : ℤ ≃ ℤ := Equiv.neg ℤ
    have he : ∀ n : ℤ, gaussianPDFReal (2 * b + 2 * n * (b - a)) v b =
        gaussianPDFReal (2 * ((e n : ℤ) : ℝ) * (b - a)) v b := by
      intro n
      simp only [gaussianPDFReal, e, Equiv.neg_apply, Int.cast_neg]
      congr 2
      ring
    unfold imageDensity imageTerm
    simp_rw [he]
    have hs2 : Summable (fun n : ℤ => gaussianPDFReal (2 * ((e n : ℤ) : ℝ) * (b - a)) v b) :=
      (e.summable_iff (f := fun n : ℤ => gaussianPDFReal (2 * (n : ℝ) * (b - a)) v b)).mpr
        (hsum0 b)
    rw [Summable.tsum_sub (hsum0 b) hs2,
      e.tsum_eq (fun n : ℤ => gaussianPDFReal (2 * (n : ℝ) * (b - a)) v b), sub_self]
  · -- on the lower wall the minus image at `n` is the plus image at `-n - 1`
    let e : ℤ ≃ ℤ := (Equiv.neg ℤ).trans (Equiv.subRight 1)
    have he : ∀ n : ℤ, gaussianPDFReal (2 * b + 2 * n * (b - a)) v a =
        gaussianPDFReal (2 * ((e n : ℤ) : ℝ) * (b - a)) v a := by
      intro n
      simp only [gaussianPDFReal, e, Equiv.trans_apply, Equiv.neg_apply, Equiv.subRight_apply,
        Int.cast_sub, Int.cast_neg, Int.cast_one]
      congr 2
      ring
    unfold imageDensity imageTerm
    simp_rw [he]
    have hs2 : Summable (fun n : ℤ => gaussianPDFReal (2 * ((e n : ℤ) : ℝ) * (b - a)) v a) :=
      (e.summable_iff (f := fun n : ℤ => gaussianPDFReal (2 * (n : ℝ) * (b - a)) v a)).mpr
        (hsum0 a)
    rw [Summable.tsum_sub (hsum0 a) hs2,
      e.tsum_eq (fun n : ℤ => gaussianPDFReal (2 * (n : ℝ) * (b - a)) v a), sub_self]

/-- **One image, reweighted for drift, is a range bet from a shifted rate** (Detailed proof,
"One image"). For any drift-per-variance `λ` (here `lam`), any image centre `c`, any window
`(lo, hi)` and any positive variance `v`, complete the square:
`∫_{lo}^{hi} e^{λx - λ²v/2} φ_v(x - c) dx = e^{λc} [N((hi - c - λv)/√v) - N((lo - c - λv)/√v)]`. -/
theorem drift_weighted_image_eq_shifted_range_bet (lam c lo hi : ℝ) (v : ℝ≥0) (hv : v ≠ 0) :
    ∫ x in lo..hi, exp (lam * x - lam ^ 2 * v / 2) * gaussianPDFReal c v x =
      exp (lam * c) *
        (stdNormalCDF ((hi - c - lam * v) / √(v : ℝ)) -
          stdNormalCDF ((lo - c - lam * v) / √(v : ℝ))) := by
  simp_rw [exp_tilt_gaussianPDFReal lam c v hv]
  rw [intervalIntegral.integral_const_mul, intervalIntegral_gaussianPDFReal _ _ _ v hv]
  rw [show hi - (c + lam * (v : ℝ)) = hi - c - lam * v by ring,
    show lo - (c + lam * (v : ℝ)) = lo - c - lam * v by ring]

/-- **In plus out, with no model** (Step 6). Under any pricing measure `P` (a probability
measure on paths), for any integrable payoff `f` at expiry, any measurable event `A` ("some wall
was touched") and any discount `D`: the knock-in (pays `f` only on `A`) plus the knock-out (pays
`f` only off `A`) is the plain option, and the double one-touch (one dollar on `A`) costs `D`
minus the double no-touch (one dollar off `A`). -/
theorem knock_in_plus_knock_out_and_double_one_touch {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] (f : Ω → ℝ) (hf : Integrable f P)
    (A : Set Ω) (hA : MeasurableSet A) (D : ℝ) :
    D * ∫ ω, A.indicator f ω ∂P + D * ∫ ω, Aᶜ.indicator f ω ∂P = D * ∫ ω, f ω ∂P ∧
      D * P.real A = D - D * P.real Aᶜ := by
  constructor
  · rw [← mul_add, integral_indicator hA, integral_indicator hA.compl, integral_add_compl hA hf]
  · rw [probReal_compl_eq_one_sub hA]; ring

/-! Worked numbers from the card, as exact fractions of its six-decimal figures. -/

-- Drift of log EURUSD: ν = 0.05 - 0.03 - ½(0.10)² = 0.015, and λ = ν/σ² = 0.015/0.01 = 1.5.
example : (5 / 100 : ℚ) - 3 / 100 - 1 / 2 * (1 / 10) ^ 2 = 15 / 1000 ∧
    (15 / 1000 : ℚ) / (1 / 10) ^ 2 = 3 / 2 := by norm_num
-- Corridor width on the log scale: w = 0.087011 + 0.046520 = 0.133531.
example : (87011 : ℚ) / 10 ^ 6 + 46520 / 10 ^ 6 = 133531 / 10 ^ 6 := by norm_num
-- After one reflection: 0.470917 - 0.178558 - 0.270440 = 0.021919.
example : (470917 : ℚ) / 10 ^ 6 - 178558 / 10 ^ 6 - 270440 / 10 ^ 6 = 21919 / 10 ^ 6 := by
  norm_num
-- Double knock-in = plain call - double knock-out: 0.053556 - 0.001989 = 0.051567.
example : (53556 : ℚ) / 10 ^ 6 - 1989 / 10 ^ 6 = 51567 / 10 ^ 6 := by norm_num

#print axioms image_sum_converges_and_vanishes_on_both_walls
#print axioms drift_weighted_image_eq_shifted_range_bet
#print axioms knock_in_plus_knock_out_and_double_one_touch

end DoubleBarrier
