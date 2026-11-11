-- Small angles: for every angle x in radians strictly between 0 and a right angle, sin x < x < tan x, which gives the chain 1 - x^2/2 < cos x < sin x / x < 1 < tan x / x < 1 / cos x and the cosine's ceiling cos x < 1 - x^2/2 + x^4/8.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Real

/-- The sandwich. Up to a right angle, in radians, the sine is less than the angle, and the
angle is less than the tangent: for 0 < x < π/2, sin x < x < tan x. -/
theorem sin_lt_self_lt_tan (x : ℝ) (h0 : 0 < x) (h1 : x < π / 2) :
    sin x < x ∧ x < tan x := by
  exact ⟨Real.sin_lt h0, Real.lt_tan h0 h1⟩

/-- The chain. Dividing the sandwich by x and putting a floor under the cosine: for
0 < x < π/2, 1 - x²/2 < cos x < sin x / x < 1 < tan x / x < 1 / cos x. Every link sits near 1
when x is small, which is why sin x ≈ x, tan x ≈ x and cos x ≈ 1 - x²/2. -/
theorem small_angle_chain (x : ℝ) (h0 : 0 < x) (h1 : x < π / 2) :
    1 - x ^ 2 / 2 < cos x ∧ cos x < sin x / x ∧ sin x / x < 1 ∧
      1 < tan x / x ∧ tan x / x < 1 / cos x := by
  have hs : sin x < x := Real.sin_lt h0
  have ht : x < tan x := Real.lt_tan h0 h1
  have hc : 0 < cos x := Real.cos_pos_of_mem_Ioo ⟨by linarith [Real.pi_pos], h1⟩
  have hsin : 0 < sin x := Real.sin_pos_of_pos_of_lt_pi h0 (by linarith [Real.pi_pos])
  rw [Real.tan_eq_sin_div_cos] at ht ⊢
  rw [lt_div_iff₀ hc] at ht
  refine ⟨Real.one_sub_sq_div_two_lt_cos h0.ne', ?_, ?_, ?_, ?_⟩
  · rw [lt_div_iff₀ h0]; linarith
  · rw [div_lt_one h0]; exact hs
  · rw [one_lt_div h0, lt_div_iff₀ hc]; linarith
  · rw [div_div, div_lt_div_iff₀ (mul_pos hc h0) hc]; nlinarith

/-- The cosine's ceiling. For 0 < x < π/2 the cosine overshoots its small-angle rule
1 - x²/2 by less than x⁴/8: cos x < 1 - x²/2 + x⁴/8. -/
theorem cos_lt_one_sub_sq_div_two_add_pow_four_div_eight (x : ℝ) (h0 : 0 < x) (h1 : x < π / 2) :
    cos x < 1 - x ^ 2 / 2 + x ^ 4 / 8 := by
  have hpi : π ≤ 4 := Real.pi_le_four
  have hx2 : 0 < x / 2 := by linarith
  have hs := Real.sin_gt_sub_cube hx2
  have hpos : 0 < x / 2 - (x / 2) ^ 3 / 6 := by
    have h2 : x < 2 := by linarith
    have hxx : x ^ 2 < 4 := by nlinarith
    have : x * x ^ 2 < x * 4 := mul_lt_mul_of_pos_left hxx h0
    nlinarith
  have hc : cos x = 1 - 2 * sin (x / 2) ^ 2 := by
    rw [← Real.cos_two_mul_eq_one_sub]; ring_nf
  have hsq : (x / 2 - (x / 2) ^ 3 / 6) ^ 2 < sin (x / 2) ^ 2 := by
    have := hs
    nlinarith
  rw [hc]
  nlinarith [sq_nonneg x, pow_pos h0 6]

-- The pendulum's 5° is π/36 radians; the figure's 40° is 2π/9 radians; 180° is π radians.
example : 5 * π / 180 = π / 36 := by ring
example : 40 * π / 180 = 2 * π / 9 := by ring
example : 180 * π / 180 = π := by ring
-- Archimedes' published fractions: 3 10/71 is 223/71 and 3 1/7 is 22/7, and the first is below the second.
example : (3 : ℚ) + 10 / 71 = 223 / 71 ∧ (3 : ℚ) + 1 / 7 = 22 / 7 := by norm_num
example : (223 : ℚ) / 71 < 22 / 7 := by norm_num
-- Archimedes' angle π/96: 30° halved four times, and 96 such angles make a half turn.
example : π / 6 / 2 / 2 / 2 / 2 = π / 96 := by ring
example : 96 * (π / 96) = π := by ring

#print axioms sin_lt_self_lt_tan
#print axioms small_angle_chain
#print axioms cos_lt_one_sub_sq_div_two_add_pow_four_div_eight
