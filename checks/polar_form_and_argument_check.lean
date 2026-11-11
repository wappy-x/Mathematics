-- Polar form: multiplying two complex numbers in polar form multiplies the lengths and adds the angles, every nonzero complex number has exactly one angle in (-π, π], and the argument of a product is the sum of the arguments only up to whole turns, with a jump on the negative real axis.
import Mathlib.Analysis.SpecialFunctions.Complex.Arg

open Complex Real Filter Topology

lemma polar_cos_three_pi_div_four : Real.cos (3 * π / 4) = -(Real.sqrt 2 / 2) := by
  rw [show 3 * π / 4 = π - π / 4 by ring, Real.cos_pi_sub, Real.cos_pi_div_four]

lemma polar_sin_three_pi_div_four : Real.sin (3 * π / 4) = Real.sqrt 2 / 2 := by
  rw [show 3 * π / 4 = π - π / 4 by ring, Real.sin_pi_sub, Real.sin_pi_div_four]

lemma polar_arg_real_polar {r θ : ℝ} (hr : 0 < r) (hθ : θ ∈ Set.Ioc (-π) π) :
    arg ((r : ℂ) * (Real.cos θ + Real.sin θ * I)) = θ := by
  rw [ofReal_cos, ofReal_sin]
  exact arg_mul_cos_add_sin_mul_I hr hθ

/-- Lengths multiply, angles add. A number of length r at angle θ times a number of length s at
angle φ is the number of length r·s at angle θ + φ:
r(cos θ + i sin θ) · s(cos φ + i sin φ) = rs(cos(θ + φ) + i sin(θ + φ)). -/
theorem lengths_multiply_angles_add (r s θ φ : ℝ) :
    ((r : ℂ) * (Real.cos θ + Real.sin θ * I)) * ((s : ℂ) * (Real.cos φ + Real.sin φ * I)) =
      ((r * s : ℝ) : ℂ) * (Real.cos (θ + φ) + Real.sin (θ + φ) * I) := by
  rw [Real.cos_add, Real.sin_add]
  push_cast
  ring_nf
  rw [I_sq]
  ring

/-- Every nonzero complex number is its length times a direction: z = |z|(cos θ + i sin θ) with
θ the principal argument, which lies in (-π, π]. No other angle in that range works, so the
principal argument is unique. The range must jump somewhere: at every point x of the negative
real axis the argument is π, it tends to π when you approach x from above, and it tends to -π
when you approach x from below, a drop of a full turn. -/
theorem principal_argument_unique_and_jumps_on_negative_axis (z : ℂ) (hz : z ≠ 0) :
    (arg z ∈ Set.Ioc (-π) π ∧
      z = (‖z‖ : ℂ) * (Real.cos (arg z) + Real.sin (arg z) * I) ∧
      ∀ θ ∈ Set.Ioc (-π) π, z = (‖z‖ : ℂ) * (Real.cos θ + Real.sin θ * I) → θ = arg z) ∧
    ∀ x : ℝ, x < 0 →
      arg (x : ℂ) = π ∧
      Tendsto arg (𝓝[{w : ℂ | 0 ≤ w.im}] (x : ℂ)) (𝓝 π) ∧
      Tendsto arg (𝓝[{w : ℂ | w.im < 0}] (x : ℂ)) (𝓝 (-π)) := by
  refine ⟨⟨arg_mem_Ioc z, ?_, ?_⟩, ?_⟩
  · rw [ofReal_cos, ofReal_sin, norm_mul_cos_add_sin_mul_I]
  · intro θ hθ h
    have := polar_arg_real_polar (norm_pos_iff.mpr hz) hθ
    rw [← h] at this
    exact this.symm
  · intro x hx
    refine ⟨arg_ofReal_of_neg hx, ?_, ?_⟩
    · exact tendsto_arg_nhdsWithin_im_nonneg_of_re_neg_of_im_zero (by simpa using hx) (by simp)
    · exact tendsto_arg_nhdsWithin_im_neg_of_re_neg_of_im_zero (by simpa using hx) (by simp)

/-- Arguments add only up to whole turns: for nonzero z and w, arg(zw) is arg z + arg w plus
some whole number k of full turns, 2πk. -/
theorem arg_of_product_up_to_whole_turns (z w : ℂ) (hz : z ≠ 0) (hw : w ≠ 0) :
    ∃ k : ℤ, arg (z * w) = arg z + arg w + 2 * π * k := by
  have h := arg_mul_coe_angle hz hw
  rw [← Real.Angle.coe_add, Real.Angle.angle_eq_iff_two_pi_dvd_sub] at h
  obtain ⟨k, hk⟩ := h
  exact ⟨k, by linarith⟩

-- The card's wind: 10 at 45 degrees is 5√2 + 5√2 i (the 7.071068 + 7.071068i of the card).
example : (10 : ℂ) * (Real.cos (π / 4) + Real.sin (π / 4) * I) =
    ((5 * Real.sqrt 2 : ℝ) : ℂ) + ((5 * Real.sqrt 2 : ℝ) : ℂ) * I := by
  rw [Real.cos_pi_div_four, Real.sin_pi_div_four]
  push_cast
  ring
-- The multiplier: 2 at 90 degrees is 2i.
example : (2 : ℂ) * (Real.cos (π / 2) + Real.sin (π / 2) * I) = 2 * I := by
  rw [Real.cos_pi_div_two, Real.sin_pi_div_two]
  push_cast
  ring
-- Multiply in polar: 10 × 2 = 20, and 45° + 90° = 135°.
example : ((10 : ℝ) : ℂ) * (Real.cos (π / 4) + Real.sin (π / 4) * I) *
      (((2 : ℝ) : ℂ) * (Real.cos (π / 2) + Real.sin (π / 2) * I)) =
    ((20 : ℝ) : ℂ) * (Real.cos (3 * π / 4) + Real.sin (3 * π / 4) * I) := by
  rw [lengths_multiply_angles_add, show π / 4 + π / 2 = 3 * π / 4 by ring]
  norm_num
-- Multiply in pairs: (5√2 + 5√2 i)(2i) = -10√2 + 10√2 i, the -14.142136 + 14.142136i of the card.
example : (((5 * Real.sqrt 2 : ℝ) : ℂ) + ((5 * Real.sqrt 2 : ℝ) : ℂ) * I) * (2 * I) =
    ((-10 * Real.sqrt 2 : ℝ) : ℂ) + ((10 * Real.sqrt 2 : ℝ) : ℂ) * I := by
  push_cast
  ring_nf
  rw [I_sq]
  ring
-- The product has length 20 and principal argument 135°, that is 3π/4.
example : ‖((-10 * Real.sqrt 2 : ℝ) : ℂ) + ((10 * Real.sqrt 2 : ℝ) : ℂ) * I‖ = 20 ∧
    arg (((-10 * Real.sqrt 2 : ℝ) : ℂ) + ((10 * Real.sqrt 2 : ℝ) : ℂ) * I) = 3 * π / 4 := by
  have e : ((-10 * Real.sqrt 2 : ℝ) : ℂ) + ((10 * Real.sqrt 2 : ℝ) : ℂ) * I =
      ((20 : ℝ) : ℂ) * (Real.cos (3 * π / 4) + Real.sin (3 * π / 4) * I) := by
    rw [polar_cos_three_pi_div_four, polar_sin_three_pi_div_four]
    push_cast
    ring
  rw [e]
  refine ⟨?_, polar_arg_real_polar (by norm_num) ⟨by linarith [Real.pi_pos], by linarith [Real.pi_pos]⟩⟩
  rw [norm_mul, ofReal_cos, ofReal_sin, norm_cos_add_sin_mul_I]
  simp
-- Turn once more by i: 135° + 90° = 225° is past π, so the principal argument is -135°, k = -1.
example : arg ((((-10 * Real.sqrt 2 : ℝ) : ℂ) + ((10 * Real.sqrt 2 : ℝ) : ℂ) * I) * I) =
    3 * π / 4 + π / 2 + 2 * π * (-1) := by
  have e : (((-10 * Real.sqrt 2 : ℝ) : ℂ) + ((10 * Real.sqrt 2 : ℝ) : ℂ) * I) * I =
      ((20 : ℝ) : ℂ) * (Real.cos (-(3 * π / 4)) + Real.sin (-(3 * π / 4)) * I) := by
    rw [Real.cos_neg, Real.sin_neg, polar_cos_three_pi_div_four, polar_sin_three_pi_div_four]
    push_cast
    ring_nf
    rw [I_sq]
    ring
  rw [e, polar_arg_real_polar (by norm_num) ⟨by linarith [Real.pi_pos], by linarith [Real.pi_pos]⟩]
  ring
-- The south-west wind -1 - i sits at -135°, not 225°.
example : arg (-1 - I) = -(3 * π / 4) := by
  have h2 : Real.sqrt 2 * Real.sqrt 2 = 2 := Real.mul_self_sqrt (by norm_num)
  have e : (-1 - I : ℂ) =
      ((Real.sqrt 2 : ℝ) : ℂ) * (Real.cos (-(3 * π / 4)) + Real.sin (-(3 * π / 4)) * I) := by
    rw [Real.cos_neg, Real.sin_neg, polar_cos_three_pi_div_four, polar_sin_three_pi_div_four]
    have h2c : ((Real.sqrt 2 : ℝ) : ℂ) * ((Real.sqrt 2 : ℝ) : ℂ) = 2 := by
      rw [← ofReal_mul, h2]; norm_num
    push_cast
    linear_combination ((1:ℂ)/2 + I/2) * h2c
  rw [e]
  exact polar_arg_real_polar (by positivity) ⟨by linarith [Real.pi_pos], by linarith [Real.pi_pos]⟩
-- The drone at 3 + 4i has length 5.
example : ‖(3 : ℂ) + 4 * I‖ = 5 := by
  rw [Complex.norm_def, Complex.normSq_apply]
  simp
  rw [show (3 * 3 + 4 * 4 : ℝ) = 5 ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)
-- Sitting on the cut: -5 has argument π, and -π is not in the range.
example : arg (-5 : ℂ) = π ∧ -π ∉ Set.Ioc (-π) π := by
  refine ⟨?_, by simp⟩
  have := arg_ofReal_of_neg (show (-5 : ℝ) < 0 by norm_num)
  simpa using this

#print axioms polar_cos_three_pi_div_four
#print axioms polar_sin_three_pi_div_four
#print axioms polar_arg_real_polar
#print axioms lengths_multiply_angles_add
#print axioms principal_argument_unique_and_jumps_on_negative_axis
#print axioms arg_of_product_up_to_whole_turns
