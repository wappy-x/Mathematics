-- Uncertainty: for every normalized wavefunction on a line, or in a box whose walls hold it at zero, the position spread times the momentum spread is at least ħ/2, and the box's lowest state sits strictly above that floor.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.InnerProductSpace.Calculus
import Mathlib.MeasureTheory.Function.L2Space
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Real.Pi.Bounds

open MeasureTheory Complex

noncomputable section

namespace Uncertainty

/-- The momentum operator: `(p̂ ψ)(x) = -i ħ ψ'(x)`. -/
def momentumOp (ħ : ℝ) (ψ : ℝ → ℂ) (x : ℝ) : ℂ := -I * ħ * deriv ψ x

/-- Mean position `x̄ = ∫ x |ψ(x)|² dx`, the integral taken with the measure `μ`
(all of the line, or the box). -/
def meanPos (μ : Measure ℝ) (ψ : ℝ → ℂ) : ℝ := ∫ x, x * ‖ψ x‖ ^ 2 ∂μ

/-- Position spread: the standard deviation `σ_x = √(∫ (x - x̄)² |ψ(x)|² dx)`. -/
def posSpread (μ : Measure ℝ) (ψ : ℝ → ℂ) : ℝ :=
  Real.sqrt (∫ x, (x - meanPos μ ψ) ^ 2 * ‖ψ x‖ ^ 2 ∂μ)

/-- Mean momentum `p̄ = ⟨ψ, p̂ ψ⟩ = ∫ ψ(x)* (-i ħ ψ'(x)) dx` (a real number; we take its real part). -/
def meanMom (μ : Measure ℝ) (ħ : ℝ) (ψ : ℝ → ℂ) : ℝ :=
  (∫ x, (starRingEnd ℂ) (ψ x) * momentumOp ħ ψ x ∂μ).re

/-- Momentum spread: the standard deviation `σ_p = ‖(p̂ - p̄) ψ‖ = √(∫ |-i ħ ψ'(x) - p̄ ψ(x)|² dx)`. -/
def momSpread (μ : Measure ℝ) (ħ : ℝ) (ψ : ℝ → ℂ) : ℝ :=
  Real.sqrt (∫ x, ‖momentumOp ħ ψ x - (meanMom μ ħ ψ : ℂ) * ψ x‖ ^ 2 ∂μ)

/-- Cauchy–Schwarz core. -/
theorem core_ineq (μ : Measure ℝ) (ħ c p : ℝ) (ψ : ℝ → ℂ)
    (hA : MemLp (fun x => ((x - c : ℝ) : ℂ) * ψ x) 2 μ)
    (hB : MemLp (fun x => momentumOp ħ ψ x - (p : ℂ) * ψ x) 2 μ)
    (hkey : ∫ x, (x - c) * (deriv ψ x * (starRingEnd ℂ) (ψ x)).re ∂μ = -1 / 2) :
    ħ / 2 ≤ Real.sqrt (∫ x, (x - c) ^ 2 * ‖ψ x‖ ^ 2 ∂μ) *
      Real.sqrt (∫ x, ‖momentumOp ħ ψ x - (p : ℂ) * ψ x‖ ^ 2 ∂μ) := by
  set A : ℝ → ℂ := fun x => ((x - c : ℝ) : ℂ) * ψ x with hAdef
  set B : ℝ → ℂ := fun x => momentumOp ħ ψ x - (p : ℂ) * ψ x with hBdef
  have hu : MemLp (fun x => ‖A x‖) (ENNReal.ofReal 2) μ := by
    simpa using hA.norm
  have hv : MemLp (fun x => ‖B x‖) (ENNReal.ofReal 2) μ := by
    simpa using hB.norm
  have hH := integral_mul_le_Lp_mul_Lq_of_nonneg Real.HolderConjugate.two_two
    (Filter.Eventually.of_forall (fun x => norm_nonneg (A x)))
    (Filter.Eventually.of_forall (fun x => norm_nonneg (B x))) hu hv
  have e1 : (fun x => ‖A x‖ ^ (2:ℝ)) = fun x => (x - c) ^ 2 * ‖ψ x‖ ^ 2 := by
    funext x
    rw [Real.rpow_two, hAdef]
    simp only [norm_mul, Complex.norm_real, Real.norm_eq_abs, mul_pow, sq_abs]
  have e2 : (fun x => ‖B x‖ ^ (2:ℝ)) = fun x => ‖B x‖ ^ 2 := by
    funext x; rw [Real.rpow_two]
  rw [e1, e2, ← Real.sqrt_eq_rpow, ← Real.sqrt_eq_rpow] at hH
  have hAB : Integrable (fun x => (B x * (starRingEnd ℂ) (A x))) μ := by
    have := hB.integrable_mul hA.star
    simpa [Pi.mul_def] using this
  have hcross : Integrable (fun x => (x - c) * (deriv ψ x * (starRingEnd ℂ) (ψ x)).re) μ := by
    apply Integrable.of_integral_ne_zero
    rw [hkey]; norm_num
  have hleft : ħ / 2 = ∫ x, (-ħ) * ((x - c) * (deriv ψ x * (starRingEnd ℂ) (ψ x)).re) ∂μ := by
    rw [integral_const_mul, hkey]; ring
  rw [hleft]
  refine le_trans (integral_mono (hcross.const_mul (-ħ)) ?_ ?_) hH
  · have := hAB.norm
    refine this.congr (Filter.Eventually.of_forall fun x => ?_)
    simp [mul_comm]
  · intro x
    have h1 : (-ħ) * ((x - c) * (deriv ψ x * (starRingEnd ℂ) (ψ x)).re)
        = (B x * (starRingEnd ℂ) (A x)).im := by
      simp only [hAdef, hBdef, momentumOp, Complex.mul_im, Complex.mul_re, Complex.conj_re,
        Complex.conj_im, Complex.ofReal_re, Complex.ofReal_im, Complex.sub_re, Complex.sub_im,
        Complex.neg_re, Complex.neg_im, Complex.I_re, Complex.I_im, map_mul, Complex.conj_ofReal]
      ring
    dsimp only; rw [h1]
    calc (B x * (starRingEnd ℂ) (A x)).im ≤ ‖B x * (starRingEnd ℂ) (A x)‖ :=
          le_trans (le_abs_self _) (Complex.abs_im_le_norm _)
      _ = ‖A x‖ * ‖B x‖ := by rw [norm_mul, Complex.norm_conj, mul_comm]

/-- The cross term `(x - c) Re(ψ' ψ̄)` is integrable when `(x - c) ψ` and `ψ'` are in L². -/
theorem cross_integrable (μ : Measure ℝ) (c : ℝ) (ψ : ℝ → ℂ)
    (hA : MemLp (fun x => ((x - c : ℝ) : ℂ) * ψ x) 2 μ) (hd : MemLp (deriv ψ) 2 μ) :
    Integrable (fun x => (x - c) * (deriv ψ x * (starRingEnd ℂ) (ψ x)).re) μ := by
  have h := (hd.integrable_mul hA.star).re
  refine h.congr (Filter.Eventually.of_forall fun x => ?_)
  simp [Complex.mul_re]
  ring

/-- Derivative of `(x - c) |ψ(x)|²`. -/
theorem hasDerivAt_weight (c : ℝ) (ψ : ℝ → ℂ) (x : ℝ) (h : DifferentiableAt ℝ ψ x) :
    HasDerivAt (fun y => (y - c) * ‖ψ y‖ ^ 2)
      (‖ψ x‖ ^ 2 + 2 * ((x - c) * (deriv ψ x * (starRingEnd ℂ) (ψ x)).re)) x := by
  have h1 := ((hasDerivAt_id x).sub_const c).mul h.hasDerivAt.norm_sq
  refine h1.congr_deriv ?_
  rw [Complex.inner]
  simp only [id]
  ring

/-- The uncertainty principle for a particle on a line. Let ψ be a wavefunction on the whole
real line: differentiable, normalized (`∫ |ψ|² = 1`), and with both spreads finite
(`x ψ` and `ψ'` square-integrable). Then the position spread times the momentum spread is at
least ħ/2: `σ_x σ_p ≥ ħ/2`. -/
theorem position_momentum_uncertainty (ħ : ℝ) (ψ : ℝ → ℂ)
    (hdiff : Differentiable ℝ ψ)
    (hψ : Integrable (fun x => ‖ψ x‖ ^ 2))
    (hnorm : ∫ x, ‖ψ x‖ ^ 2 = 1)
    (hx : Integrable (fun x => x ^ 2 * ‖ψ x‖ ^ 2))
    (hp : Integrable (fun x => ‖deriv ψ x‖ ^ 2)) :
    ħ / 2 ≤ posSpread volume ψ * momSpread volume ħ ψ := by
  set c := meanPos volume ψ
  set p := meanMom volume ħ ψ
  have hψc : Continuous ψ := hdiff.continuous
  have hψ2 : MemLp ψ 2 := (memLp_two_iff_integrable_sq_norm hψc.aestronglyMeasurable).2 hψ
  have hxψ : MemLp (fun x : ℝ => (x : ℂ) * ψ x) 2 :=
    (memLp_two_iff_integrable_sq_norm
      (Complex.continuous_ofReal.mul hψc).aestronglyMeasurable).2
      (by convert hx using 2 with x; simp [mul_pow])
  have hA : MemLp (fun x => ((x - c : ℝ) : ℂ) * ψ x) 2 := by
    have := hxψ.sub (hψ2.const_mul (c : ℂ))
    convert this using 1
    funext x; simp only [Pi.sub_apply]; push_cast; ring
  have hd : MemLp (deriv ψ) 2 :=
    (memLp_two_iff_integrable_sq_norm (measurable_deriv ψ).aestronglyMeasurable).2 hp
  have hB : MemLp (fun x => momentumOp ħ ψ x - (p : ℂ) * ψ x) 2 := by
    have := (hd.const_mul (-I * ħ)).sub (hψ2.const_mul (p : ℂ))
    exact this
  have hcross := cross_integrable volume c ψ hA hd
  have hA2 : Integrable (fun x => (x - c) ^ 2 * ‖ψ x‖ ^ 2) := by
    have := (memLp_two_iff_integrable_sq_norm hA.aestronglyMeasurable).1 hA
    convert this using 2 with x
    rw [norm_mul, mul_pow, Complex.norm_real, Real.norm_eq_abs, sq_abs]
  have hF : Integrable (fun x => (x - c) * ‖ψ x‖ ^ 2) := by
    refine (hA2.add hψ).mono' ((continuous_id.sub continuous_const).mul
      (hψc.norm.pow 2)).aestronglyMeasurable (Filter.Eventually.of_forall fun x => ?_)
    rw [Real.norm_eq_abs, abs_mul, abs_of_nonneg (by positivity : (0:ℝ) ≤ ‖ψ x‖ ^ 2)]
    have h1 : |x - c| ≤ (x - c) ^ 2 + 1 := by
      rcases abs_cases (x - c) with ⟨h, _⟩ | ⟨h, _⟩ <;> rw [h] <;> nlinarith
    have h2 : (0:ℝ) ≤ ‖ψ x‖ ^ 2 := by positivity
    show |x - c| * ‖ψ x‖ ^ 2 ≤ (x - c) ^ 2 * ‖ψ x‖ ^ 2 + ‖ψ x‖ ^ 2
    nlinarith
  have h0 := integral_eq_zero_of_hasDerivAt_of_integrable
    (fun x => hasDerivAt_weight c ψ x (hdiff x)) (hψ.add (hcross.const_mul 2)) hF
  rw [integral_add hψ (hcross.const_mul 2), hnorm, integral_const_mul] at h0
  have hkey : ∫ x, (x - c) * (deriv ψ x * (starRingEnd ℂ) (ψ x)).re = -1 / 2 := by linarith
  exact core_ineq volume ħ c p ψ hA hB hkey

/-- The uncertainty principle in a box with walls at `a < b` that hold the wavefunction at
zero. Let ψ be continuous on `[a, b]`, differentiable inside, zero at both walls, normalized on
`[a, b]`, with finite momentum spread (`ψ'` square-integrable on `[a, b]`). Then
`σ_x σ_p ≥ ħ/2`, all integrals taken over the box. -/
theorem box_uncertainty (ħ a b : ℝ) (hab : a < b) (ψ : ℝ → ℂ)
    (hcont : ContinuousOn ψ (Set.Icc a b))
    (hdiff : ∀ x ∈ Set.Ioo a b, DifferentiableAt ℝ ψ x)
    (hwalls : ψ a = 0 ∧ ψ b = 0)
    (hnorm : ∫ x in Set.Icc a b, ‖ψ x‖ ^ 2 = 1)
    (hp : IntegrableOn (fun x => ‖deriv ψ x‖ ^ 2) (Set.Icc a b)) :
    ħ / 2 ≤ posSpread (volume.restrict (Set.Icc a b)) ψ *
      momSpread (volume.restrict (Set.Icc a b)) ħ ψ := by
  set μ := volume.restrict (Set.Icc a b) with hμ
  set c := meanPos μ ψ
  set p := meanMom μ ħ ψ
  have hψ : Integrable (fun x => ‖ψ x‖ ^ 2) μ :=
    Integrable.of_integral_ne_zero (by rw [hnorm]; norm_num)
  have hψ2 : MemLp ψ 2 μ :=
    (memLp_two_iff_integrable_sq_norm (hcont.aestronglyMeasurable measurableSet_Icc)).2 hψ
  have hAc : ContinuousOn (fun x => ((x - c : ℝ) : ℂ) * ψ x) (Set.Icc a b) :=
    ((Complex.continuous_ofReal.comp (continuous_id.sub continuous_const)).continuousOn).mul hcont
  have hA : MemLp (fun x => ((x - c : ℝ) : ℂ) * ψ x) 2 μ :=
    (memLp_two_iff_integrable_sq_norm (hAc.aestronglyMeasurable measurableSet_Icc)).2
      ((hAc.norm.pow 2).integrableOn_Icc)
  have hd : MemLp (deriv ψ) 2 μ :=
    (memLp_two_iff_integrable_sq_norm (measurable_deriv ψ).aestronglyMeasurable).2 hp
  have hB : MemLp (fun x => momentumOp ħ ψ x - (p : ℂ) * ψ x) 2 μ := by
    have := (hd.const_mul (-I * ħ)).sub (hψ2.const_mul (p : ℂ))
    exact this
  have hcross := cross_integrable μ c ψ hA hd
  have hF'int : Integrable
      (fun x => ‖ψ x‖ ^ 2 + 2 * ((x - c) * (deriv ψ x * (starRingEnd ℂ) (ψ x)).re)) μ :=
    hψ.add (hcross.const_mul 2)
  have hFc : ContinuousOn (fun y => (y - c) * ‖ψ y‖ ^ 2) (Set.Icc a b) :=
    (continuous_id.sub continuous_const).continuousOn.mul (hcont.norm.pow 2)
  have hint : IntervalIntegrable
      (fun x => ‖ψ x‖ ^ 2 + 2 * ((x - c) * (deriv ψ x * (starRingEnd ℂ) (ψ x)).re))
      volume a b := by
    apply IntegrableOn.intervalIntegrable
    rw [Set.uIcc_of_le hab.le]
    exact hF'int
  have hftc := intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hab.le hFc
    (fun x hx => hasDerivAt_weight c ψ x (hdiff x hx)) hint
  rw [intervalIntegral.integral_of_le hab.le, ← integral_Icc_eq_integral_Ioc] at hftc
  have hzero : (b - c) * ‖ψ b‖ ^ 2 - (a - c) * ‖ψ a‖ ^ 2 = 0 := by
    simp [hwalls.1, hwalls.2]
  rw [hzero] at hftc
  change ∫ x, (‖ψ x‖ ^ 2 + 2 * ((x - c) * (deriv ψ x * (starRingEnd ℂ) (ψ x)).re)) ∂μ = 0
    at hftc
  rw [integral_add hψ (hcross.const_mul 2), integral_const_mul] at hftc
  have hn : ∫ x, ‖ψ x‖ ^ 2 ∂μ = 1 := hnorm
  have hkey : ∫ x, (x - c) * (deriv ψ x * (starRingEnd ℂ) (ψ x)).re ∂μ = -1 / 2 := by
    linarith
  exact core_ineq μ ħ c p ψ hA hB hkey

/-- The electron in the lowest state of a hard-walled box of width `L` has
`σ_x = L √(1/12 - 1/(2π²))` and `σ_p = π ħ / L`; their product sits strictly above the floor
ħ/2 (the card finds 0.567862 ħ), whatever the width. -/
theorem box_ground_state_above_floor (ħ L : ℝ) (hħ : 0 < ħ) (hL : 0 < L) :
    ħ / 2 < (L * Real.sqrt (1 / 12 - 1 / (2 * Real.pi ^ 2))) * (Real.pi * ħ / L) := by
  have hπ := Real.pi_gt_three
  have hπ0 : 0 < Real.pi := Real.pi_pos
  have h9 : 9 < Real.pi ^ 2 := by nlinarith
  have hdiff : 1 / 12 - 1 / (2 * Real.pi ^ 2) - (1 / (2 * Real.pi)) ^ 2
      = (Real.pi ^ 2 - 9) / (12 * Real.pi ^ 2) := by
    field_simp; ring
  have hpos : 0 < (Real.pi ^ 2 - 9) / (12 * Real.pi ^ 2) := by
    apply div_pos <;> nlinarith
  have hs : 1 / (2 * Real.pi) < Real.sqrt (1 / 12 - 1 / (2 * Real.pi ^ 2)) :=
    (Real.lt_sqrt (by positivity)).2 (by linarith)
  have hrw : (L * Real.sqrt (1 / 12 - 1 / (2 * Real.pi ^ 2))) * (Real.pi * ħ / L)
      = Real.pi * ħ * Real.sqrt (1 / 12 - 1 / (2 * Real.pi ^ 2)) := by
    field_simp
  rw [hrw]
  have h2 := mul_lt_mul_of_pos_left hs (by positivity : 0 < Real.pi * ħ)
  have h3 : Real.pi * ħ * (1 / (2 * Real.pi)) = ħ / 2 := by field_simp
  linarith

#print axioms core_ineq
#print axioms cross_integrable
#print axioms hasDerivAt_weight
#print axioms position_momentum_uncertainty
#print axioms box_uncertainty
#print axioms box_ground_state_above_floor

end Uncertainty

end
