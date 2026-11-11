-- Derivatives of sine and cosine: in radians, at every real x the rate of sin is cos x and the rate of cos is -sin x, tangent and secant have rates 1/cos^2 x and sin x/cos^2 x wherever cos x is not 0, and the two limits at zero behind the proof are (sin h)/h to 1 and (cos h - 1)/h to 0.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.ArctanDeriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Tactic.NormNum

open Real Filter Topology

/-- In radians (Mathlib's `Real.sin` and `Real.cos` take radians), at every angle x the rate of
sin is cos x and the rate of cos is minus sin x. -/
theorem deriv_sin_is_cos_and_deriv_cos_is_neg_sin (x : ℝ) :
    HasDerivAt sin (cos x) x ∧ HasDerivAt cos (-sin x) x := by
  exact ⟨hasDerivAt_sin x, hasDerivAt_cos x⟩

/-- By the quotient rule, wherever cos x is not zero: tangent, sin over cos, has rate
1 / cos² x (that is sec² x), and secant, 1 over cos, has rate sin x / cos² x (that is
sec x tan x). -/
theorem deriv_tan_and_sec (x : ℝ) (hx : cos x ≠ 0) :
    HasDerivAt tan (1 / cos x ^ 2) x ∧
      HasDerivAt (fun y => 1 / cos y) (sin x / cos x ^ 2) x := by
  refine ⟨hasDerivAt_tan hx, ?_⟩
  have h := (hasDerivAt_cos x).inv hx
  have e : (fun y => 1 / cos y) = fun y => (cos y)⁻¹ := by
    funext y; rw [one_div]
  rw [e]
  convert h using 1
  ring

/-- The two limits at zero that settle every angle: as the step h heads for 0 (never equal to
0), (sin h) / h heads for 1 and (cos h - 1) / h heads for 0. -/
theorem sin_div_tendsto_one_and_cos_sub_one_div_tendsto_zero :
    Tendsto (fun h : ℝ => sin h / h) (𝓝[≠] 0) (𝓝 1) ∧
      Tendsto (fun h : ℝ => (cos h - 1) / h) (𝓝[≠] 0) (𝓝 0) := by
  refine ⟨tendsto_sin_div_nhdsNE_zero, ?_⟩
  have h := (hasDerivAt_iff_tendsto_slope.mp (hasDerivAt_cos 0))
  simp only [sin_zero, neg_zero] at h
  refine h.congr' ?_
  filter_upwards [self_mem_nhdsWithin] with t ht
  rw [slope_def_field, cos_zero, sub_zero]

-- The crank at 30 degrees, π/6 radians, with arm 4 cm: the piston is 4 sin x = 2 cm up.
example : 4 * sin (π / 6) = 2 := by rw [sin_pi_div_six]; norm_num
-- The pin's sideways reach 4 cos x changes at -4 sin x = -2 cm per radian, not +2.
example : -(4 * sin (π / 6)) = -2 := by rw [sin_pi_div_six]; norm_num
-- Tangent's rate at 30 degrees: 1 / cos² x = 4/3 (the card's 1.333333).
example : 1 / cos (π / 6) ^ 2 = 4 / 3 := by rw [cos_pi_div_six]; norm_num [div_pow]
-- Secant's rate at 30 degrees: sin x / cos² x = 2/3 (the card's 0.666667).
example : sin (π / 6) / cos (π / 6) ^ 2 = 2 / 3 := by
  rw [sin_pi_div_six, cos_pi_div_six]; norm_num [div_pow]
-- The mistake tan² x gives 1/3 (the card's 0.333333), not 4/3.
example : (sin (π / 6) / cos (π / 6)) ^ 2 = 1 / 3 := by
  rw [sin_pi_div_six, cos_pi_div_six]; norm_num [div_pow]

#print axioms deriv_sin_is_cos_and_deriv_cos_is_neg_sin
#print axioms deriv_tan_and_sec
#print axioms sin_div_tendsto_one_and_cos_sub_one_div_tendsto_zero
