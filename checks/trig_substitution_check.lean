-- Trig substitution: for a radius a ≥ 0, the root √(a^2 - x^2) accumulated from -a to a equals a cos θ times a cos θ accumulated over θ from -π/2 to π/2, and both equal π a^2/2; the antiderivative is (x√(a^2 - x^2) + a^2 arcsin(x/a))/2, and the tangent relative 1/√(9 + x^2) from 0 to 4 gives ln 3.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.InverseDeriv
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Real Set

/-- The card's formula: for a radius `a ≥ 0`, the root `√(a^2 - x^2)` accumulated from `x = -a`
to `x = a` equals the root `a cos θ` times the restretched width `a cos θ` accumulated over the
half turn from `θ = -π/2` to `θ = π/2` (the substitution `x = a sin θ` on that branch), and both
equal half of pi a squared. -/
theorem integral_sqrt_sq_sub_sq_eq_half_pi_mul_sq (a : ℝ) (ha : 0 ≤ a) :
    ((∫ x in (-a)..a, √(a ^ 2 - x ^ 2)) = ∫ θ in (-(π / 2))..(π / 2), a * cos θ * (a * cos θ)) ∧
    (∫ θ in (-(π / 2))..(π / 2), a * cos θ * (a * cos θ)) = π * a ^ 2 / 2 := by
  have h2 : (∫ θ in (-(π / 2))..(π / 2), a * cos θ * (a * cos θ)) = π * a ^ 2 / 2 := by
    have : (fun θ => a * cos θ * (a * cos θ)) = fun θ => a ^ 2 * cos θ ^ 2 := by
      funext θ; ring
    rw [this, intervalIntegral.integral_const_mul, integral_cos_sq]
    simp
    ring
  refine ⟨?_, h2⟩
  rw [h2]
  have key := intervalIntegral.smul_integral_comp_mul_left (fun x => √(a ^ 2 - x ^ 2)) a
    (a := -1) (b := 1)
  simp only [mul_neg, mul_one, smul_eq_mul] at key
  rw [← key]
  have : (fun x : ℝ => √(a ^ 2 - (a * x) ^ 2)) = fun x => a * √(1 - x ^ 2) := by
    funext x
    have : a ^ 2 - (a * x) ^ 2 = a ^ 2 * (1 - x ^ 2) := by ring
    rw [this, Real.sqrt_mul (sq_nonneg a), Real.sqrt_sq ha]
  rw [this, intervalIntegral.integral_const_mul, integral_sqrt_one_sub_sq]
  ring

/-- The antiderivative without limits: for a radius `a > 0` and every `x` strictly between `-a`
and `a`, the function `(x √(a^2 - x^2) + a^2 θ)/2`, with `θ = arcsin(x/a)` the angle on the branch
from `-π/2` to `π/2` whose sine is `x/a`, has rate `√(a^2 - x^2)` at `x`. -/
theorem hasDerivAt_trig_substitution_antiderivative (a x : ℝ) (ha : 0 < a) (hx : x ∈ Ioo (-a) a) :
    HasDerivAt (fun x => (x * √(a ^ 2 - x ^ 2) + a ^ 2 * arcsin (x / a)) / 2)
      (√(a ^ 2 - x ^ 2)) x := by
  obtain ⟨h1, h2⟩ := hx
  have hpos : 0 < a ^ 2 - x ^ 2 := by nlinarith
  have hs : 0 < √(a ^ 2 - x ^ 2) := Real.sqrt_pos.mpr hpos
  have hxa1 : x / a ≠ -1 := by
    intro h; rw [div_eq_iff ha.ne'] at h; linarith
  have hxa2 : x / a ≠ 1 := by
    intro h; rw [div_eq_iff ha.ne'] at h; linarith
  have d1 : HasDerivAt (fun x => a ^ 2 - x ^ 2) (-(2 * x)) x := by
    simpa using (hasDerivAt_pow 2 x).const_sub (a ^ 2)
  have d2 := d1.sqrt hpos.ne'
  have d3 := (hasDerivAt_id' x).mul d2
  have d4 := (Real.hasDerivAt_arcsin hxa1 hxa2).comp x ((hasDerivAt_id' x).div_const a)
  have d5 := (d3.add (d4.const_mul (a ^ 2))).div_const 2
  refine d5.congr_deriv ?_
  have e : √(1 - (x / a) ^ 2) = √(a ^ 2 - x ^ 2) / a := by
    have : 1 - (x / a) ^ 2 = (a ^ 2 - x ^ 2) / a ^ 2 := by field_simp
    rw [this, Real.sqrt_div' _ (sq_nonneg a), Real.sqrt_sq ha.le]
  rw [e]
  field_simp
  rw [Real.sq_sqrt hpos.le]
  ring

/-- The relative through the 3-4-5 triangle: `1/√(9 + x^2)` accumulated from `x = 0` to `x = 4`
is `ln 3`, found by `x = 3 tan θ` and the antiderivative `ln(sec θ + tan θ)`. -/
theorem integral_inv_sqrt_nine_add_sq_zero_four :
    ∫ x in (0 : ℝ)..4, 1 / √(9 + x ^ 2) = log 3 := by
  have hpos : ∀ x : ℝ, 0 < 9 + x ^ 2 := fun x => by positivity
  have hsg : ∀ x : ℝ, |x| < √(9 + x ^ 2) := fun x => by
    rw [← Real.sqrt_sq_eq_abs]
    exact Real.sqrt_lt_sqrt (sq_nonneg x) (by linarith)
  have hS : ∀ x : ℝ, 0 < x + √(9 + x ^ 2) := fun x => by
    have := hsg x; have := neg_abs_le x; linarith
  have hd : ∀ x ∈ uIcc (0:ℝ) 4, HasDerivAt (fun x => log (x + √(9 + x ^ 2)))
      (1 / √(9 + x ^ 2)) x := by
    intro x _
    have d1 : HasDerivAt (fun x => 9 + x ^ 2) (2 * x) x := by
      simpa using (hasDerivAt_pow 2 x).const_add 9
    have d2 := ((hasDerivAt_id' x).add (d1.sqrt (hpos x).ne')).log (hS x).ne'
    refine d2.congr_deriv ?_
    simp only [Pi.add_apply]
    have hs : 0 < √(9 + x ^ 2) := Real.sqrt_pos.mpr (hpos x)
    have := (hS x).ne'
    field_simp
    ring
  have hcont : Continuous fun x : ℝ => 1 / √(9 + x ^ 2) := by
    refine Continuous.div continuous_const (by fun_prop) ?_
    intro x; exact (Real.sqrt_pos.mpr (hpos x)).ne'
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hd (hcont.intervalIntegrable _ _)]
  have h25 : √(9 + (4:ℝ) ^ 2) = 5 := by
    rw [show (9 + (4:ℝ) ^ 2) = 5 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]
  have h9 : √(9 + (0:ℝ) ^ 2) = 3 := by
    rw [show (9 + (0:ℝ) ^ 2) = 3 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]
  simp only [h25, h9]
  rw [← Real.log_div (by norm_num) (by norm_num)]
  norm_num

-- Step 0 at x = 3/2: 9 - x^2 = 27/4, and (3 cos θ)^2 with cos θ = √3/2 gives 9 · 3/4 = 27/4.
example : (9 : ℚ) - (3 / 2) ^ 2 = 27 / 4 ∧ (9 : ℚ) * (3 / 4) = 27 / 4 := by norm_num
-- The whole pond: twice the half pond π · 3^2 / 2 is 9π.
example : 2 * (π * 3 ^ 2 / 2) = 9 * π := by ring
-- Step 3: (9/2)(π/2 - (-π/2)), doubled, is again 9π.
example : 2 * ((9 / 2) * (π / 2 - (-(π / 2)))) = 9 * π := by ring
-- The mistake with the dx factor dropped: 2 · 3 · (sin(π/2) - sin(-π/2)) = 2 · 3 · 2 = 12.
example : (2 : ℤ) * 3 * (1 - (-1)) = 12 := by decide
-- Step 5: the 3-4-5 triangle, tan θ = 4/3 and sec θ = 5/3 at x = 4, with sec θ + tan θ = 3.
example : (3 : ℕ) ^ 2 + 4 ^ 2 = 5 ^ 2 := by decide
example : (9 : ℕ) + 4 ^ 2 = 5 ^ 2 := by decide
example : (5 / 3 : ℚ) + 4 / 3 = 3 := by norm_num

#print axioms integral_sqrt_sq_sub_sq_eq_half_pi_mul_sq
#print axioms hasDerivAt_trig_substitution_antiderivative
#print axioms integral_inv_sqrt_nine_add_sq_zero_four
