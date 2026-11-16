-- Two pairs worth memorising: with f-hat(ξ) = ∫ f(t) e^(−2πiξt) dt and ξ in hertz, a gate open for T seconds transforms to T sinc(ξT), which is zero exactly at ξ = k/T for nonzero whole k, and the bell e^(−πt²) transforms to itself.
import Mathlib.Analysis.SpecialFunctions.Gaussian.FourierTransform
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Sinc

open MeasureTheory Complex Real
open scoped FourierTransform

/-! Mathlib's `𝓕` on `ℝ` is the card's transform exactly:
`𝓕 f ξ = ∫ f(t) e^(−2πiξt) dt`, with ξ in hertz (see `Real.fourier_real_eq_integral_exp_smul`).
Mathlib's `Real.sinc x` is `sin x / x` (and 1 at 0), so the card's
`sinc(u) = sin(πu)/(πu)` is `Real.sinc (π * u)`. -/

/-- The card's gate: open (1) while `|t| < T/2`, shut (0) at every other time. -/
noncomputable def gate (T : ℝ) : ℝ → ℂ :=
  Set.indicator (Set.Ioo (-T / 2) (T / 2)) (fun _ => 1)

/-- The gate's transform as an interval integral of the exponential. -/
lemma gate_fourier_eq_intervalIntegral (T : ℝ) (hT : 0 < T) (ξ : ℝ) :
    𝓕 (gate T) ξ = ∫ v in (-T / 2)..(T / 2), cexp ((-2 * π * ξ * I) * (v : ℂ)) := by
  rw [Real.fourier_real_eq_integral_exp_smul, intervalIntegral.integral_of_le (by linarith),
    integral_Ioc_eq_integral_Ioo, ← integral_indicator measurableSet_Ioo]
  congr 1
  ext v
  simp only [gate, Set.indicator, smul_eq_mul]
  split_ifs <;> simp
  congr 1
  ring

/-- Gate and sinc: a gate open for `T > 0` seconds has spectrum `T sinc(ξT)` at every
frequency `ξ` in hertz, that is `sin(πξT)/(πξ)` for `ξ ≠ 0` and the open time `T` at `ξ = 0`. -/
theorem gate_fourier_eq_T_mul_sinc (T : ℝ) (hT : 0 < T) (ξ : ℝ) :
    𝓕 (gate T) ξ = ((T * Real.sinc (π * (ξ * T)) : ℝ) : ℂ) := by
  rw [gate_fourier_eq_intervalIntegral T hT]
  rcases eq_or_ne ξ 0 with rfl | hξ
  · simp
    ring
  · have hc : (-2 * π * ξ * I : ℂ) ≠ 0 := by
      have := Real.pi_pos.ne'
      simp [hξ, this, I_ne_zero]
    rw [integral_exp_mul_complex hc]
    have hx : π * (ξ * T) ≠ 0 := by
      have := Real.pi_pos.ne'; positivity
    rw [Real.sinc_of_ne_zero hx]
    have key : cexp (-2 * π * ξ * I * ((T / 2 : ℝ) : ℂ)) - cexp (-2 * π * ξ * I * ((-T / 2 : ℝ) : ℂ))
        = -2 * I * Complex.sin ((π * (ξ * T) : ℝ) : ℂ) := by
      rw [Complex.sin]
      have e1 : -2 * π * ξ * I * ((T / 2 : ℝ) : ℂ) = -(((π * (ξ * T) : ℝ) : ℂ) * I) := by
        push_cast; ring
      have e2 : -2 * π * ξ * I * ((-T / 2 : ℝ) : ℂ) = ((π * (ξ * T) : ℝ) : ℂ) * I := by
        push_cast; ring
      rw [e1, e2]
      field_simp
      rw [I_sq]
      ring
    rw [key, ← Complex.ofReal_sin]
    have hπ : (π : ℂ) ≠ 0 := by exact_mod_cast Real.pi_pos.ne'
    have hξ' : (ξ : ℂ) ≠ 0 := by exact_mod_cast hξ
    have hT' : (T : ℂ) ≠ 0 := by exact_mod_cast hT.ne'
    push_cast
    field_simp

/-- The law of pulse length: the spectrum of a gate open for `T > 0` seconds is zero exactly
at the frequencies `ξ = k/T` with `k` a nonzero whole number; so the first zero is `1/T`. -/
theorem gate_fourier_eq_zero_iff (T : ℝ) (hT : 0 < T) (ξ : ℝ) :
    𝓕 (gate T) ξ = 0 ↔ ∃ k : ℤ, k ≠ 0 ∧ ξ = k / T := by
  rw [gate_fourier_eq_T_mul_sinc T hT, Complex.ofReal_eq_zero, mul_eq_zero, or_iff_right hT.ne']
  constructor
  · intro h
    rcases eq_or_ne ξ 0 with rfl | hξ
    · simp at h
    have hx : π * (ξ * T) ≠ 0 := by
      have := Real.pi_pos.ne'; positivity
    rw [Real.sinc_of_ne_zero hx, div_eq_zero_iff, or_iff_left hx, Real.sin_eq_zero_iff] at h
    obtain ⟨n, hn⟩ := h
    have hn' : (n : ℝ) = ξ * T := by
      have := Real.pi_pos.ne'
      apply mul_right_cancel₀ this
      linarith [hn]
    refine ⟨n, ?_, ?_⟩
    · rintro rfl
      simp at hn'
      rcases hn'.symm with h | h
      · exact hT.ne' h
      · exact hξ h
    · rw [hn']; field_simp
  · rintro ⟨k, hk, rfl⟩
    have hk' : (k : ℝ) ≠ 0 := by exact_mod_cast hk
    have e : π * ((k : ℝ) / T * T) = k * π := by field_simp
    rw [e, Real.sinc_of_ne_zero (by have := Real.pi_pos.ne'; positivity), Real.sin_int_mul_pi,
      zero_div]

/-- The bell that transforms to itself: the transform of `e^(−πt²)` is `e^(−πξ²)`. -/
theorem bell_fourier_eq_bell :
    𝓕 (fun t : ℝ => cexp (-π * (t : ℂ) ^ 2)) = fun ξ : ℝ => cexp (-π * (ξ : ℂ) ^ 2) := by
  have h := fourier_gaussian_pi (b := 1) (by simp)
  simpa using h

-- Worked numbers, exact.
-- Pulse lengths and first zeros 1/T: 1/100 s, 1/250 s, 1/1000 s, 1/4000 s, 1 μs.
example : 1 / (1 / 100 : ℚ) = 100 := by norm_num
example : 1 / (1 / 250 : ℚ) = 250 := by norm_num
example : 1 / (1 / 1000 : ℚ) = 1000 := by norm_num
example : 1 / (1 / 4000 : ℚ) = 4000 := by norm_num
example : 1 / (1 / 1000000 : ℚ) = 1000000 := by norm_num
-- Gate at 500 Hz with T = 1/1000 s: sin(π/2)/(500π) = 1/(500π) seconds.
example : Real.sin (π * 500 * (1 / 1000)) / (π * 500) = 1 / (500 * π) := by
  rw [show π * 500 * (1 / 1000) = π / 2 by ring, Real.sin_pi_div_two]; ring
-- Gate at 1,000 Hz with T = 1/1000 s: sin(π) = 0, the first zero.
example : Real.sin (π * 1000 * (1 / 1000)) = 0 := by
  rw [show π * 1000 * (1 / 1000) = π by ring, Real.sin_pi]
-- Sampling at h = 20 μs is a rate of 50 kHz; 1,000 bins of a DFT fall every 50 Hz.
example : 1 / (20 / 1000000 : ℚ) = 50000 := by norm_num
example : (50000 : ℚ) / 1000 = 50 := by norm_num
-- The 51 samples of 1, with half weight at the two ends, sum to 50; times h = 1/50 ms, 1 ms.
example : (49 : ℚ) + 2 * (1 / 2) = 50 := by norm_num
example : (50 : ℚ) * (1 / 50) = 1 := by norm_num
-- Edge samples at full weight: 51 steps of 1/50 ms give 51/50 ms at 0 Hz.
example : (51 : ℚ) * (1 / 50) = 51 / 50 := by norm_num

#print axioms gate_fourier_eq_intervalIntegral
#print axioms gate_fourier_eq_T_mul_sinc
#print axioms gate_fourier_eq_zero_iff
#print axioms bell_fourier_eq_bell
