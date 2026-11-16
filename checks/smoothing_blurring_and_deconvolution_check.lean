-- Blurring and unblurring: damping by any λ > 0 caps the gain at every frequency at 1/(2√λ), the damped estimate is the unique best compromise at each frequency, and plain division by a bell-shaped blur's factor has no ceiling.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Complex.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

/-! At one frequency `ξ` the blur's factor is `ĥ(ξ)`, the photo's strength is `ŷ(ξ)`, and the
damping is `λ`. The damped estimate there is `conj(ĥ) ŷ / (|ĥ|² + λ)`. For the card's real,
positive bell-shaped blur the **gain**, the number the estimate multiplies the photo by, is
`ĥ / (ĥ² + λ)`. The bell of standard deviation `σ` has factor `ĥ(ξ) = exp(−2π²σ²ξ²)`, so plain
division multiplies by `1 / ĥ(ξ)`. Complex numbers are Mathlib's `ℂ`, the bar is
`starRingEnd ℂ`, and `|z|²` is `‖z‖ ^ 2` (equal to `Complex.normSq z`). -/

open Real Filter

/-- **Damping caps the gain.** If the damping `λ` is positive, then at every frequency the
damped gain `ĥ / (ĥ² + λ)` of a real blur factor `ĥ` is at most `1 / (2√λ)`, and it equals
that cap exactly when `ĥ = √λ`. -/
theorem damped_gain_le_inv_two_sqrt (lam : ℝ) (hlam : 0 < lam) (h : ℝ) :
    h / (h ^ 2 + lam) ≤ 1 / (2 * Real.sqrt lam) ∧
      (h / (h ^ 2 + lam) = 1 / (2 * Real.sqrt lam) ↔ h = Real.sqrt lam) := by
  have hs : 0 < Real.sqrt lam := Real.sqrt_pos.mpr hlam
  have hss : Real.sqrt lam ^ 2 = lam := Real.sq_sqrt hlam.le
  set s := Real.sqrt lam
  have hD : 0 < h ^ 2 + lam := by positivity
  refine ⟨?_, ?_⟩
  · rw [div_le_div_iff₀ hD (by positivity)]
    nlinarith [sq_nonneg (h - s)]
  · constructor
    · intro heq
      rw [div_eq_div_iff hD.ne' (by positivity)] at heq
      have : (h - s) ^ 2 = 0 := by nlinarith
      have := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp this
      linarith
    · intro heq
      rw [heq, div_eq_div_iff (by positivity) (by positivity)]
      rw [hss.symm]; ring

/-- **Damping is the best compromise at each frequency.** If the damping `λ` is positive, then
for any blur factor `H = ĥ(ξ)` and photo strength `Y = ŷ(ξ)`, the damped estimate
`a* = conj(H) Y / (|H|² + λ)` makes the mismatch plus the damping cost,
`|H a − Y|² + λ |a|²`, as small as any number `a` can, and no other `a` does as well. -/
theorem damped_estimate_unique_minimizer (lam : ℝ) (hlam : 0 < lam) (H Y : ℂ) :
    let a₀ : ℂ := starRingEnd ℂ H * Y / ((‖H‖ ^ 2 + lam : ℝ) : ℂ)
    ∀ a : ℂ, ‖H * a₀ - Y‖ ^ 2 + lam * ‖a₀‖ ^ 2 ≤ ‖H * a - Y‖ ^ 2 + lam * ‖a‖ ^ 2 ∧
      (‖H * a - Y‖ ^ 2 + lam * ‖a‖ ^ 2 = ‖H * a₀ - Y‖ ^ 2 + lam * ‖a₀‖ ^ 2 → a = a₀) := by
  intro a₀ a
  have hD : 0 < ‖H‖ ^ 2 + lam := by positivity
  have key : ‖H * a - Y‖ ^ 2 + lam * ‖a‖ ^ 2 =
      ‖H * a₀ - Y‖ ^ 2 + lam * ‖a₀‖ ^ 2 + (‖H‖ ^ 2 + lam) * ‖a - a₀‖ ^ 2 := by
    have hD' : H.re ^ 2 + H.im ^ 2 + lam ≠ 0 := by
      have : ‖H‖ ^ 2 = H.re ^ 2 + H.im ^ 2 := by
        rw [Complex.sq_norm, Complex.normSq_apply]; ring
      rw [← this]; exact hD.ne'
    have hre : a₀.re = (H.re * Y.re + H.im * Y.im) / (H.re ^ 2 + H.im ^ 2 + lam) := by
      simp only [a₀, Complex.div_ofReal_re, Complex.mul_re, Complex.conj_re, Complex.conj_im,
        Complex.sq_norm, Complex.normSq_apply]
      congr 1 <;> ring
    have him : a₀.im = (H.re * Y.im - H.im * Y.re) / (H.re ^ 2 + H.im ^ 2 + lam) := by
      simp only [a₀, Complex.div_ofReal_im, Complex.mul_im, Complex.conj_re, Complex.conj_im,
        Complex.sq_norm, Complex.normSq_apply]
      congr 1 <;> ring
    simp only [Complex.sq_norm, Complex.normSq_apply, Complex.sub_re, Complex.sub_im,
      Complex.mul_re, Complex.mul_im, hre, him]
    field_simp
    ring
  refine ⟨?_, ?_⟩
  · rw [key]; nlinarith [sq_nonneg ‖a - a₀‖]
  · intro heq
    rw [key] at heq
    have h1 : (‖H‖ ^ 2 + lam) * ‖a - a₀‖ ^ 2 = 0 := by linarith
    rcases mul_eq_zero.mp h1 with h2 | h2
    · exact absurd h2 hD.ne'
    · have := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp h2
      exact sub_eq_zero.mp (norm_eq_zero.mp this)

/-- **Plain division has no ceiling.** For a bell-shaped blur of standard deviation `σ > 0`,
plain division multiplies frequency `ξ` by `1 / ĥ(ξ) = 1 / exp(−2π²σ²ξ²)`, and this factor grows
without limit as `ξ` grows. -/
theorem plain_division_gain_unbounded (σ : ℝ) (hσ : 0 < σ) :
    Tendsto (fun ξ : ℝ => 1 / Real.exp (-2 * π ^ 2 * σ ^ 2 * ξ ^ 2)) atTop atTop := by
  have hc : 0 < 2 * π ^ 2 * σ ^ 2 := by positivity
  have h1 : Tendsto (fun ξ : ℝ => 2 * π ^ 2 * σ ^ 2 * ξ ^ 2) atTop atTop :=
    (tendsto_pow_atTop (by norm_num)).const_mul_atTop hc
  refine (Real.tendsto_exp_atTop.comp h1).congr ?_
  intro ξ
  simp only [Function.comp, one_div, ← Real.exp_neg]
  congr 1; ring

-- The cap at λ = 10⁻⁴ is 1/(2√0.0001) = 1/0.02 = 50.
example : 1 / (2 * Real.sqrt (1 / 10000)) = 50 := by
  rw [show (1 / 10000 : ℝ) = (1 / 100) ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]
  norm_num
-- The cap at λ = 10⁻⁸ is 5000.
example : 1 / (2 * Real.sqrt (1 / 100000000)) = 5000 := by
  rw [show (1 / 100000000 : ℝ) = (1 / 10000) ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]
  norm_num
-- The bell's exponent at σ = 2 pixels and ξ = 1/4: 2π² × 4 × 1/16 = π²/2.
example : 2 * π ^ 2 * (2 : ℝ) ^ 2 * (1 / 4) ^ 2 = π ^ 2 / 2 := by ring
-- Frequencies on the 64-pixel row: k = 16 is ξ = 1/4 (stripes 4 pixels apart),
-- k = 32 is ξ = 1/2 (stripes 2 pixels apart), the finest.
example : (16 : ℚ) / 64 = 1 / 4 ∧ 1 / ((1 : ℚ) / 4) = 4 ∧ (32 : ℚ) / 64 = 1 / 2 ∧
    1 / ((1 : ℚ) / 2) = 2 := by norm_num
-- Too much damping, λ = 0.1: the gain at ξ = 0, where ĥ = 1, is 1/(1 + 0.1) = 10/11,
-- so the whole picture dims by 1/11 (about 9%).
example : (1 : ℚ) / (1 ^ 2 + 1 / 10) = 10 / 11 ∧ 1 - (10 : ℚ) / 11 = 1 / 11 := by norm_num
-- A bell blur of standard deviation 2 pixels is heat flow with κt = σ²/2 = 2 square pixels.
example : (2 : ℚ) ^ 2 / 2 = 2 := by norm_num
-- The true row: sky 200 on 54 pixels, the post 40 on pixels 28 to 35 (8 pixels),
-- the wire 60 on pixels 44 and 45 (2 pixels), 64 pixels in all.
example : (Finset.Icc 28 35).card = 8 ∧ (Finset.Icc 44 45).card = 2 ∧ 54 + 8 + 2 = 64 := by
  decide

#print axioms damped_gain_le_inv_two_sqrt
#print axioms damped_estimate_unique_minimizer
#print axioms plain_division_gain_unbounded
