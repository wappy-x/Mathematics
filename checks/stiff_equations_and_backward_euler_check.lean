-- Stiff equations: for a decaying fast rate, the backward Euler and trapezoid gap factors are below 1 in size at every positive step size, so a backward Euler step always shrinks the gap.
import Mathlib.Analysis.Complex.Basic
import Mathlib.Tactic.NormNum

theorem one_lt_norm_one_sub (lam : ℂ) (hlam : lam.re < 0)
    (h : ℝ) (hh : 0 < h) : 1 < ‖1 - (h : ℂ) * lam‖ := by
  have hre : (1 - (h : ℂ) * lam).re = 1 - h * lam.re := by simp
  have h1 : (1 - (h : ℂ) * lam).re ≤ ‖1 - (h : ℂ) * lam‖ := Complex.re_le_norm _
  have : 0 < h * (-lam.re) := mul_pos hh (by linarith)
  linarith

#print axioms one_lt_norm_one_sub

/-- Backward Euler's gap factor `1 / (1 - z)`, with `z = h λ`, is below 1 in size
for every decaying fast rate `λ` (real part below 0) and every positive step size `h`. -/
theorem backward_euler_gap_factor_lt_one (lam : ℂ) (hlam : lam.re < 0)
    (h : ℝ) (hh : 0 < h) :
    ‖(1 - (h : ℂ) * lam)⁻¹‖ < 1 := by
  rw [norm_inv]
  exact inv_lt_one_of_one_lt₀ (one_lt_norm_one_sub lam hlam h hh)

/-- A backward Euler step on the fast part `d' = λ d` reads the slope at its destination:
`d₁ = d₀ + h (λ d₁)`. For a decaying rate and any positive step size, the new gap is
smaller in size than the old one (unless the old gap was already 0). -/
theorem backward_euler_step_shrinks_gap (lam : ℂ) (hlam : lam.re < 0)
    (h : ℝ) (hh : 0 < h) (d₀ d₁ : ℂ)
    (hstep : d₁ = d₀ + (h : ℂ) * (lam * d₁)) (hd₀ : d₀ ≠ 0) :
    ‖d₁‖ < ‖d₀‖ := by
  have hgt := one_lt_norm_one_sub lam hlam h hh
  have hne : (1 - (h : ℂ) * lam) ≠ 0 := by
    intro h0; rw [h0, norm_zero] at hgt; linarith
  have hd : d₁ = (1 - (h : ℂ) * lam)⁻¹ * d₀ := by
    rw [eq_inv_mul_iff_mul_eq₀ hne]
    linear_combination hstep
  rw [hd, norm_mul]
  have := backward_euler_gap_factor_lt_one lam hlam h hh
  have : 0 < ‖d₀‖ := norm_pos_iff.mpr hd₀
  nlinarith

/-- The trapezoid's gap factor `(1 + z/2) / (1 - z/2)`, with `z = h λ`, is also below 1
in size for every decaying fast rate `λ` and every positive step size `h`. -/
theorem trapezoid_gap_factor_lt_one (lam : ℂ) (hlam : lam.re < 0)
    (h : ℝ) (hh : 0 < h) :
    ‖(1 + (h : ℂ) * lam / 2) / (1 - (h : ℂ) * lam / 2)‖ < 1 := by
  set w : ℂ := (h : ℂ) * lam / 2 with hw
  have hwre : w.re < 0 := by
    have : w.re = h * lam.re / 2 := by simp [hw]
    rw [this]
    have : h * lam.re < 0 := mul_neg_of_pos_of_neg hh hlam
    linarith
  have hsq : Complex.normSq (1 + w) < Complex.normSq (1 - w) := by
    simp only [Complex.normSq_apply, Complex.add_re, Complex.add_im, Complex.sub_re,
      Complex.sub_im, Complex.one_re, Complex.one_im]
    nlinarith
  have hn : ‖1 + w‖ < ‖1 - w‖ := by
    rw [Complex.normSq_eq_norm_sq, Complex.normSq_eq_norm_sq] at hsq
    exact lt_of_pow_lt_pow_left₀ 2 (norm_nonneg _) hsq
  have hpos : 0 < ‖1 - w‖ := lt_of_le_of_lt (norm_nonneg _) hn
  rw [norm_div, div_lt_one hpos]
  exact hn

-- Worked numbers: h = 1/100 s and λ = -1000 per s give z = -10.
example : (1 / 100 : ℚ) * (-1000) = -10 := by norm_num
-- Forward, backward and trapezoid gap factors at z = -10: -9, 1/11, -2/3.
example : (1 : ℚ) + (-10) = -9 := by norm_num
example : (1 : ℚ) / (1 - (-10)) = 1 / 11 := by norm_num
example : ((1 : ℚ) + (-10) / 2) / (1 - (-10) / 2) = -2 / 3 := by norm_num
-- Trapezoid at h = 1/10 s: z = -100, factor -49/51.
example : ((1 : ℚ) + (1 / 10 * -1000) / 2) / (1 - (1 / 10 * -1000) / 2) = -49 / 51 := by norm_num
-- Forward Euler factor 1 - 1000 h: -9/10 at h = 19/10000, -11/10 at h = 21/10000; limit h < 2/1000.
example : (1 : ℚ) - 1000 * (19 / 10000) = -9 / 10 := by norm_num
example : (1 : ℚ) - 1000 * (21 / 10000) = -11 / 10 := by norm_num
example : |(1 : ℚ) - 1000 * (2 / 1000)| = 1 := by norm_num
-- Backward factor 1 / (1 + 1000 h) at h = 1/1000 and h = 10: 1/2 and 1/10001.
example : (1 : ℚ) / (1 + 1000 * (1 / 1000)) = 1 / 2 := by norm_num
example : (1 : ℚ) / (1 + 1000 * 10) = 1 / 10001 := by norm_num
-- Plug-in iteration of the backward step multiplies by 1000 h = 10 with a sign flip: factor -10.
example : -(1000 : ℚ) * (1 / 100) = -10 := by norm_num

#print axioms backward_euler_gap_factor_lt_one
#print axioms backward_euler_step_shrinks_gap
#print axioms trapezoid_gap_factor_lt_one
