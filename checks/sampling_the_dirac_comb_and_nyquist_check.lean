-- Sampling: sampling a rapidly decreasing signal every Δt copies its spectrum every 2π/Δt, the Dirac comb's transform is (2π/Δt) times a comb, and no copy touches a band of B hertz when 1/Δt > 2B.
import Mathlib.Analysis.Fourier.PoissonSummation

open Complex Real MeasureTheory
open scoped SchwartzMap

/-- **The copies formula.** Sample a rapidly decreasing signal `x` every `Δt` seconds. The sampled
spectrum `S(ω) = Δt ∑ₙ x(nΔt) e^{-iωnΔt}` equals the true spectrum
`x̂(ω) = ∫ x(t) e^{-iωt} dt` plus its copies shifted by every whole multiple of `ω_s = 2π/Δt`:
`S(ω) = ∑ₖ x̂(ω - k ω_s)`. -/
theorem sampled_spectrum_eq_sum_of_copies (x : 𝓢(ℝ, ℂ)) {Δt : ℝ} (hΔt : 0 < Δt) (ω : ℝ) :
    (Δt : ℂ) * ∑' n : ℤ, x (n * Δt) * Complex.exp (-(↑(ω * (n * Δt)) * Complex.I)) =
      ∑' k : ℤ, ∫ t : ℝ, x t * Complex.exp (-(↑((ω - k * (2 * π / Δt)) * t) * Complex.I)) := by
  have hne : Δt ≠ 0 := hΔt.ne'
  let e : ℝ ≃L[ℝ] ℝ := ContinuousLinearEquiv.unitsEquivAut ℝ (Units.mk0 Δt hne)
  let y : 𝓢(ℝ, ℂ) := SchwartzMap.compCLMOfContinuousLinearEquiv ℝ e x
  have hyapp : ∀ s, y s = x (s * Δt) := fun s => rfl
  let f : 𝓢(ℝ, ℂ) := FourierTransformInv.fourierInv y
  have hP := SchwartzMap.tsum_eq_tsum_fourier f (-(ω * Δt / (2 * π)))
  have hFf : FourierTransform.fourier f = y := FourierInvPair.fourier_fourierInv_eq y
  have h1 : ∀ n : ℤ, FourierTransform.fourier f n *
      fourier n ((-(ω * Δt / (2 * π)) : ℝ) : UnitAddCircle) =
      x (n * Δt) * Complex.exp (-(↑(ω * (n * Δt)) * Complex.I)) := by
    intro n
    rw [hFf, hyapp, fourier_coe_apply]
    congr 2
    push_cast
    field_simp
  have h2 : ∀ n : ℤ, (Δt : ℂ) * f (-(ω * Δt / (2 * π)) + n) =
      ∫ t : ℝ, x t * Complex.exp (-(↑((ω - n * (2 * π / Δt)) * t) * Complex.I)) := by
    intro n
    have hf : (f : ℝ → ℂ) = FourierTransformInv.fourierInv (y : ℝ → ℂ) :=
      SchwartzMap.fourierInv_coe y
    rw [hf, Real.fourierInv_eq']
    let G : ℝ → ℂ := fun t => x t *
      Complex.exp (-(↑((ω - n * (2 * π / Δt)) * t) * Complex.I))
    have hG : ∀ s : ℝ, Complex.exp (↑(2 * π * inner ℝ s (-(ω * Δt / (2 * π)) + n)) * Complex.I) • y s
        = G (s * Δt) := by
      intro s
      simp only [G, hyapp, smul_eq_mul, RCLike.inner_apply, conj_trivial]
      rw [mul_comm]
      congr 2
      have hc : (Δt : ℂ) ≠ 0 := Complex.ofReal_ne_zero.mpr hne
      push_cast
      field_simp
      ring
    simp_rw [hG]
    rw [Measure.integral_comp_mul_right, abs_inv, abs_of_pos hΔt]
    rw [Complex.real_smul, ← mul_assoc, ← Complex.ofReal_mul, mul_inv_cancel₀ hne, Complex.ofReal_one, one_mul]
  rw [← tsum_congr h1, ← hP, ← tsum_mul_left]
  exact tsum_congr h2

/-- **The Dirac comb's transform is a comb.** Tested on any rapidly decreasing probe `φ`, the
transform of the comb `Ш_Δt` (a spike every `Δt`) acts as `2π/Δt` times the comb `Ш_{ω_s}` with
spikes every `ω_s = 2π/Δt`: `∑ₙ φ̂(nΔt) = (2π/Δt) ∑ₖ φ(k ω_s)`, where
`φ̂(s) = ∫ φ(ω) e^{-iωs} dω`. -/
theorem fourier_dirac_comb_eq_scaled_comb (φ : 𝓢(ℝ, ℂ)) {Δt : ℝ} (hΔt : 0 < Δt) :
    ∑' n : ℤ, (∫ ω : ℝ, φ ω * Complex.exp (-(↑(ω * (n * Δt)) * Complex.I))) =
      ((2 * π / Δt : ℝ) : ℂ) * ∑' k : ℤ, φ (k * (2 * π / Δt)) := by
  have hD : 0 < 2 * π / Δt := div_pos (by positivity) hΔt
  have h := sampled_spectrum_eq_sum_of_copies φ hD 0
  have hinv : 2 * π / (2 * π / Δt) = Δt := by
    have : (2 * π) ≠ 0 := by positivity
    field_simp
  rw [hinv] at h
  have hl : ∀ n : ℤ, φ (n * (2 * π / Δt)) * Complex.exp (-(↑((0:ℝ) * (n * (2 * π / Δt))) * Complex.I))
      = φ (n * (2 * π / Δt)) := by
    intro n; simp
  simp_rw [hl] at h
  rw [h, ← (Equiv.neg ℤ).tsum_eq]
  refine tsum_congr fun n => ?_
  congr 1
  funext t
  congr 3
  simp only [Equiv.neg_apply, Int.cast_neg]
  push_cast
  ring

/-- **The rate at which nothing is lost.** If the spectrum `x̂(ω) = ∫ x(t) e^{-iωt} dt` is zero
above `B` hertz (for `|ω| > 2πB`) and the sampling rate `1/Δt` exceeds `2B`, the copies do not
touch the band: on `|ω| ≤ 2πB` the sampled spectrum `Δt ∑ₙ x(nΔt) e^{-iωnΔt}` equals `x̂(ω)`. -/
theorem sampled_spectrum_eq_spectrum_of_rate_gt_twice_band (x : 𝓢(ℝ, ℂ)) {Δt B : ℝ}
    (hΔt : 0 < Δt)
    (hband : ∀ ω : ℝ, 2 * π * B < |ω| →
      ∫ t : ℝ, x t * Complex.exp (-(↑(ω * t) * Complex.I)) = 0)
    (hrate : 2 * B < 1 / Δt) (ω : ℝ) (hω : |ω| ≤ 2 * π * B) :
    (Δt : ℂ) * ∑' n : ℤ, x (n * Δt) * Complex.exp (-(↑(ω * (n * Δt)) * Complex.I)) =
      ∫ t : ℝ, x t * Complex.exp (-(↑(ω * t) * Complex.I)) := by
  rw [sampled_spectrum_eq_sum_of_copies x hΔt ω]
  rw [tsum_eq_single 0]
  · simp
  · intro k hk
    apply hband
    have hk1 : (1 : ℝ) ≤ |(k : ℝ)| := by
      rw [← Int.cast_abs]
      exact_mod_cast Int.one_le_abs hk
    have hs : 2 * π / Δt = 2 * π * (1 / Δt) := by ring
    have hpos : 0 < 2 * π / Δt := div_pos (by positivity) hΔt
    have h4 : 4 * π * B < 2 * π / Δt := by
      rw [hs]; nlinarith [Real.pi_pos]
    have htri : |(k : ℝ) * (2 * π / Δt)| - |ω| ≤ |ω - k * (2 * π / Δt)| := by
      have := abs_sub_abs_le_abs_sub ((k : ℝ) * (2 * π / Δt)) ω
      rw [abs_sub_comm] at this
      exact this
    rw [abs_mul, abs_of_pos hpos] at htri
    nlinarith

-- CD audio: the rate needed for a 20,000 Hz band, and 44,100 clears it.
example : 2 * 20000 = 40000 := by norm_num
example : (40000 : ℕ) < 44100 := by norm_num
-- The Nyquist frequency, the first copy of the band, and the guard gap.
example : 44100 / 2 = 22050 := by norm_num
example : 44100 - 20000 = 24100 := by norm_num
example : 24100 - 20000 = 4100 := by norm_num
-- A 30,000 Hz tone has a spike at -30,000 Hz, shifted by 44,100 Hz to 14,100 Hz.
example : (-30000 : ℤ) + 44100 = 14100 := by norm_num
-- What breaks: a 20,000 Hz band sampled 32,000 times a second.
example : (32000 : ℕ) < 2 * 20000 := by norm_num
example : 32000 - 20000 = 12000 ∧ 2 * 20000 - 32000 = 8000 := by norm_num
-- The 12-point rehearsal: spacing 3 in time becomes spacing 4 in frequency, and back;
-- the tone at bin 5 is heard at bin 5 mod 4 = 1.
example : 12 / 3 = 4 ∧ 12 / 4 = 3 := by norm_num
example : 5 % 4 = 1 := by norm_num
-- The comb's partial sums at 0 Hz: 2N + 1 ones, so 3, 5, 23, 201 for N = 1, 2, 11, 100.
example : (∑ _n ∈ Finset.Icc (-1 : ℤ) 1, (1 : ℤ)) = 3 := by decide
example : (∑ _n ∈ Finset.Icc (-2 : ℤ) 2, (1 : ℤ)) = 5 := by decide
example : (∑ _n ∈ Finset.Icc (-11 : ℤ) 11, (1 : ℤ)) = 23 := by decide
example : (∑ _n ∈ Finset.Icc (-100 : ℤ) 100, (1 : ℤ)) = 201 := by decide +kernel
-- At 22,050 Hz each term is e^{-iπn} = (-1)^n: the sums are -1, 1, -1, 1 for N = 1, 2, 11, 100.
example : (∑ n ∈ Finset.Icc (-1 : ℤ) 1, (-1 : ℤ) ^ n.natAbs) = -1 := by decide
example : (∑ n ∈ Finset.Icc (-2 : ℤ) 2, (-1 : ℤ) ^ n.natAbs) = 1 := by decide
example : (∑ n ∈ Finset.Icc (-11 : ℤ) 11, (-1 : ℤ) ^ n.natAbs) = -1 := by decide
example : (∑ n ∈ Finset.Icc (-100 : ℤ) 100, (-1 : ℤ) ^ n.natAbs) = 1 := by decide +kernel

#print axioms sampled_spectrum_eq_sum_of_copies
#print axioms fourier_dirac_comb_eq_scaled_comb
#print axioms sampled_spectrum_eq_spectrum_of_rate_gt_twice_band
