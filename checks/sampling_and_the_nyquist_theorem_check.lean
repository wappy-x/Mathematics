-- Sampling: a finite-energy signal with no frequency above B is rebuilt exactly from its readings by the sinc sum whenever the sampling rate beats 2B, a tone's readings match those of its alias folded into 0 to half the sampling rate, and the Butterworth order rule is exactly the condition for the filter to reach the required loss.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Sinc
import Mathlib.Analysis.Fourier.AddCircle
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Base
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.MeasureTheory.Function.LpSeminorm.Basic
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Algebra.Order.Round
import Mathlib.Topology.Algebra.InfiniteSum.Defs
import Mathlib.Tactic.NormNum

open MeasureTheory

namespace Sampling

open ComplexConjugate in
/-- Parseval's identity for inner products of two square-integrable functions on `(a, a + T]`. -/
theorem parseval_liftIoc (T a : ℝ) [hT : Fact (0 < T)] {f g : ℝ → ℂ}
    (hf : MemLp f 2 (volume.restrict (Set.Ioc a (a + T))))
    (hg : MemLp g 2 (volume.restrict (Set.Ioc a (a + T)))) :
    HasSum (fun i => conj (fourierCoeff (AddCircle.liftIoc T a f) i) *
        fourierCoeff (AddCircle.liftIoc T a g) i)
      (T⁻¹ • ∫ x in a..a + T, conj (f x) * g x) := by
  have hF := hf.memLp_liftIoc.haarAddCircle
  have hG := hg.memLp_liftIoc.haarAddCircle
  have H := fourierBasis.hasSum_inner_mul_inner hF.toLp hG.toLp
  convert H using 1
  · funext i
    rw [← inner_conj_symm, ← HilbertBasis.repr_apply_apply, ← HilbertBasis.repr_apply_apply,
      fourierBasis_repr, fourierBasis_repr, fourierCoeff_congr_ae hF.coeFn_toLp,
      fourierCoeff_congr_ae hG.coeFn_toLp]
  · rw [MeasureTheory.L2.inner_def]
    have e : ∫ y, inner ℂ ((hF.toLp) y) ((hG.toLp) y) ∂AddCircle.haarAddCircle
        = ∫ y, AddCircle.liftIoc T a (fun x => conj (f x) * g x) y ∂AddCircle.haarAddCircle := by
      apply integral_congr_ae
      filter_upwards [hF.coeFn_toLp, hG.coeFn_toLp] with y hy1 hy2
      rw [hy1, hy2]
      simp [AddCircle.liftIoc, mul_comm]
    rw [e, AddCircle.integral_haarAddCircle, AddCircle.integral_liftIoc_eq_intervalIntegral]

/-- The Fourier coefficients of a lifted function, as an interval integral over `(a, a + T]`. -/
theorem fourierCoeff_liftIoc_eq_intervalIntegral (T a : ℝ) [hT : Fact (0 < T)] (f : ℝ → ℂ)
    (n : ℤ) :
    fourierCoeff (AddCircle.liftIoc T a f) n
      = (1 / T) • ∫ x in a..a + T, fourier (-n) (x : AddCircle T) • f x := by
  rw [fourierCoeff_eq_intervalIntegral _ _ a]
  congr 1
  refine intervalIntegral.integral_congr_ae (ae_of_all _ fun x hx => ?_)
  rw [Set.uIoc_of_le (lt_add_of_pos_right a hT.out).le] at hx
  simp only [AddCircle.liftIoc_coe_apply hx]

/-- The integral of `e^{-i·2u·ν/fs}` over one period `(-fs/2, fs/2]`, divided by the period,
is the normalised sinc `sin u / u`. -/
theorem integral_exp_over_period (fs u : ℝ) (hfs : 0 < fs) :
    (1 / fs : ℂ) * ∫ ν in -fs / 2..-fs / 2 + fs,
        Complex.exp (-(2 * Complex.I * u / fs) * ν) = (Real.sinc u : ℂ) := by
  have hfs' : (fs : ℂ) ≠ 0 := by exact_mod_cast hfs.ne'
  rcases eq_or_ne u 0 with hu | hu
  · subst hu
    simp [Real.sinc_zero]
    field_simp
  · have hc : -(2 * Complex.I * u / fs) ≠ 0 := by
      have : (u : ℂ) ≠ 0 := by exact_mod_cast hu
      simp [Complex.I_ne_zero, this, hfs']
    rw [integral_exp_mul_complex hc, Real.sinc_of_ne_zero hu]
    have e1 : -(2 * Complex.I * u / fs) * ((-fs / 2 + fs : ℝ) : ℂ) = -(u * Complex.I) := by
      push_cast; field_simp; ring
    have e2 : -(2 * Complex.I * u / fs) * ((-fs / 2 : ℝ) : ℂ) = (u * Complex.I) := by
      push_cast; field_simp
    rw [e1, e2, Complex.exp_mul_I, ← neg_mul, Complex.exp_mul_I, Complex.cos_neg,
      Complex.sin_neg]
    have : (u : ℂ) ≠ 0 := by exact_mod_cast hu
    push_cast
    field_simp
    ring_nf

#print axioms parseval_liftIoc
#print axioms fourierCoeff_liftIoc_eq_intervalIntegral
#print axioms integral_exp_over_period

/-- **The sampling theorem.** Let the spectrum `X` have finite energy and be zero at every
frequency `f` with `|f| > B`, and let the signal be `x(t) = ∫ X(f) e^{j2πft} df`. If the
sampling rate `fs` is more than twice the band limit, `fs > 2B`, then at every time `t` the
signal is the sum over all readings `x[n] = x(n/fs)` of the reading times a sinc bump centred
on its time: `x(t) = Σₙ x(n/fs) · sinc((t - n/fs)·fs)`, where `sinc(u) = sin(πu)/(πu)` and
`sinc(0) = 1` (Mathlib's `Real.sinc` is the unnormalised `sin u / u`, so it is applied to `πu`). -/
theorem band_limited_signal_is_sinc_sum_of_its_samples (X : ℝ → ℂ) (B fs : ℝ)
    (hX : MemLp X 2 volume) (hband : ∀ f : ℝ, B < |f| → X f = 0) (hfs : 2 * B < fs)
    (x : ℝ → ℂ) (hx : ∀ t : ℝ, x t = ∫ f : ℝ, Complex.exp (2 * Real.pi * Complex.I * f * t) * X f)
    (t : ℝ) :
    HasSum (fun n : ℤ => x (n / fs) * (Real.sinc (Real.pi * (fs * t - n)) : ℂ)) (x t) := by
  rcases lt_or_ge B 0 with hB | hB
  · have hX0 : ∀ f, X f = 0 := fun f => hband f (lt_of_lt_of_le hB (abs_nonneg f))
    have hx0 : ∀ s, x s = 0 := fun s => by rw [hx]; simp [hX0]
    simp only [hx0, zero_mul]
    exact hasSum_zero
  have hfs0 : 0 < fs := by linarith
  have : Fact (0 < fs) := ⟨hfs0⟩
  have hfs' : (fs : ℂ) ≠ 0 := by exact_mod_cast hfs0.ne'
  set k : ℝ → ℂ := fun ν => Complex.exp (-(2 * Real.pi * Complex.I * ν * t)) with hk_def
  have hk : MemLp k 2 (volume.restrict (Set.Ioc (-fs / 2) (-fs / 2 + fs))) := by
    refine MemLp.of_bound (by fun_prop : Continuous k).aestronglyMeasurable 1
      (ae_of_all _ fun ν => ?_)
    simp [k, Complex.norm_exp]
  have hXr : MemLp X 2 (volume.restrict (Set.Ioc (-fs / 2) (-fs / 2 + fs))) := hX.restrict _
  have P := parseval_liftIoc fs (-fs / 2) hk hXr
  have hsupp : ∀ ν, ν ∉ Set.Ioc (-fs / 2) (-fs / 2 + fs) → X ν = 0 := by
    intro ν hν
    apply hband
    simp only [Set.mem_Ioc, not_and_or, not_lt, not_le] at hν
    rw [lt_abs]
    rcases hν with h | h
    · right; linarith
    · left; linarith
  have hint : ∀ F : ℝ → ℂ,
      (∫ ν in (-fs / 2)..(-fs / 2 + fs), F ν * X ν) = ∫ ν, F ν * X ν := by
    intro F
    rw [intervalIntegral.integral_of_le (by linarith)]
    exact setIntegral_eq_integral_of_forall_compl_eq_zero (fun ν hν => by simp [hsupp ν hν])
  have h1 : ∀ n : ℤ, fourierCoeff (AddCircle.liftIoc fs (-fs / 2) X) n
      = x (((-n : ℤ) : ℝ) / fs) / fs := by
    intro n
    rw [fourierCoeff_liftIoc_eq_intervalIntegral]
    simp_rw [smul_eq_mul, fourier_coe_apply]
    have e : ∀ ν : ℝ, Complex.exp (2 * Real.pi * Complex.I * ((-n : ℤ) : ℂ) * ν / fs) * X ν
        = Complex.exp (2 * Real.pi * Complex.I * ν * (((((-n : ℤ) : ℝ) / fs : ℝ)) : ℂ)) * X ν := by
      intro ν
      congr 2
      push_cast
      ring
    rw [hint, hx, Complex.real_smul, div_eq_inv_mul, integral_congr_ae (ae_of_all _ e)]
    push_cast
    ring
  have h2 : ∀ n : ℤ, (starRingEnd ℂ) (fourierCoeff (AddCircle.liftIoc fs (-fs / 2) k) n)
      = (Real.sinc (Real.pi * (fs * t + n)) : ℂ) := by
    intro n
    have : fourierCoeff (AddCircle.liftIoc fs (-fs / 2) k) n
        = (Real.sinc (Real.pi * (fs * t + n)) : ℂ) := by
      rw [fourierCoeff_liftIoc_eq_intervalIntegral, ← integral_exp_over_period fs _ hfs0,
        Complex.real_smul]
      push_cast
      congr 1
      refine intervalIntegral.integral_congr (fun ν _ => ?_)
      simp only [k, smul_eq_mul, fourier_coe_apply]
      rw [← Complex.exp_add]
      congr 1
      push_cast
      field_simp
      ring
    rw [this, Complex.conj_ofReal]
  have h3 : fs⁻¹ • (∫ ν in (-fs / 2)..(-fs / 2 + fs), (starRingEnd ℂ) (k ν) * X ν) = x t / fs := by
    have hc : ∀ ν, (starRingEnd ℂ) (k ν) = Complex.exp (2 * Real.pi * Complex.I * ν * t) := by
      intro ν
      simp [k, ← Complex.exp_conj, map_ofNat]
    simp_rw [hc]
    rw [hint, ← hx, Complex.real_smul]
    push_cast
    ring
  simp only [h1, h2, h3] at P
  have P2 := P.mul_left (fs : ℂ)
  rw [← (Equiv.neg ℤ).hasSum_iff]
  convert P2 using 1
  · funext n
    simp only [Function.comp_apply, Equiv.neg_apply, Int.cast_neg, sub_neg_eq_add]
    field_simp
  · field_simp

/-- **The alias.** A tone at frequency `f` read `fs > 0` times a second gives exactly the same
readings as a tone at `f_a = |f - k·fs|`, where `k` is the whole number nearest `f/fs`; and
`f_a` always lands between 0 and `fs/2`. -/
theorem tone_and_its_alias_give_the_same_samples (f fs : ℝ) (hfs : 0 < fs) :
    (∀ n : ℤ, Real.cos (2 * Real.pi * f * (n / fs))
        = Real.cos (2 * Real.pi * |f - round (f / fs) * fs| * (n / fs))) ∧
      0 ≤ |f - round (f / fs) * fs| ∧ |f - round (f / fs) * fs| ≤ fs / 2 := by
  refine ⟨fun n => ?_, abs_nonneg _, ?_⟩
  · have hfs' : fs ≠ 0 := hfs.ne'
    have key : 2 * Real.pi * (f - round (f / fs) * fs) * (n / fs)
        = 2 * Real.pi * f * (n / fs) - ((round (f / fs) * n : ℤ) : ℝ) * (2 * Real.pi) := by
      push_cast; field_simp
    rcases abs_choice (f - round (f / fs) * fs) with h | h
    · rw [h, key, Real.cos_sub_int_mul_two_pi]
    · rw [h, show 2 * Real.pi * -(f - round (f / fs) * fs) * (n / fs)
          = -(2 * Real.pi * (f - round (f / fs) * fs) * (n / fs)) by ring, Real.cos_neg, key,
        Real.cos_sub_int_mul_two_pi]
  · have e : f - round (f / fs) * fs = (f / fs - round (f / fs)) * fs := by
      field_simp
    rw [e, abs_mul, abs_of_pos hfs]
    have := abs_sub_round (f / fs)
    nlinarith

/-- **The filter order rule.** A Butterworth filter of order `N` with its corner at the band
edge `fp` cuts a wobble at the stop edge `fstop > fp` by `10 log₁₀(1 + (fstop/fp)^{2N})` dB.
For a required loss `A > 0` dB, it reaches that loss exactly when
`N ≥ log₁₀(10^{A/10} - 1) / (2 log₁₀(fstop/fp))`. -/
theorem butterworth_order_rule (A fp fstop : ℝ) (N : ℕ) (hA : 0 < A) (hfp : 0 < fp)
    (hstop : fp < fstop) :
    A ≤ 10 * Real.logb 10 (1 + (fstop / fp) ^ (2 * N)) ↔
      Real.logb 10 ((10 : ℝ) ^ (A / 10) - 1) / (2 * Real.logb 10 (fstop / fp)) ≤ N := by
  have hr : 1 < fstop / fp := (one_lt_div hfp).2 hstop
  have hL : 0 < Real.logb 10 (fstop / fp) := Real.logb_pos (by norm_num) hr
  have hP : 0 < (10 : ℝ) ^ (A / 10) - 1 := by
    have := Real.one_lt_rpow (by norm_num : (1 : ℝ) < 10) (by positivity : 0 < A / 10)
    linarith
  have hpow : 0 < (fstop / fp) ^ (2 * N) := by positivity
  have e : (N : ℝ) * (2 * Real.logb 10 (fstop / fp)) = Real.logb 10 ((fstop / fp) ^ (2 * N)) := by
    rw [Real.logb_pow]; push_cast; ring
  rw [div_le_iff₀ (by positivity), e, Real.logb_le_logb (by norm_num) hP hpow,
    ← div_le_iff₀' (by norm_num : (0 : ℝ) < 10),
    Real.le_logb_iff_rpow_le (by norm_num) (by positivity)]
  constructor <;> intro h <;> linarith

/-! The card's whole-number worked examples. Frequencies in kHz unless stated. -/

-- Time between readings at 20 kHz: 1/20000 s = 50 μs.
example : (1 : ℚ) / 20000 = 50 / 1000000 := by norm_num
-- Nyquist frequency 20/2 = 10 kHz; the whistle's Nyquist rate 2 × 15 = 30 kHz, and 20 falls short.
example : (20 : ℕ) / 2 = 10 ∧ 2 * 15 = 30 ∧ 20 < 2 * 15 := by decide
-- The alias of the whistle: 15/20 is nearest 1, and |15 - 20 × 1| = 5 kHz.
example : round ((15 : ℚ) / 20) = 1 := by norm_num [round_eq]
example : |(15 : ℤ) - 20 * 1| = 5 := by decide
-- Turn per reading: 360° × 15/20 = 270°, the same point as 270° - 360° = -90°.
example : (360 : ℚ) * 15 / 20 = 270 ∧ (270 : ℤ) - 360 = -90 := by norm_num
-- Folding at 20 kHz: 9 → 9, 11 → 9, 15 → 5, 19 → 1, 21 → 1, 25 → 5, 35 → 5.
example : ([9, 11, 15, 19, 21, 25, 35] : List ℤ).map (fun f => |f - 20 * round ((f : ℚ) / 20)|)
    = [9, 9, 5, 1, 1, 5, 5] := by
  norm_num [round_eq]
-- 15 kHz sampled at 40 kHz stays at 15.
example : |(15 : ℤ) - 40 * round ((15 : ℚ) / 40)| = 15 := by norm_num [round_eq]
-- Film: 22 turns a second at 24 frames a second looks like 22 - 24 × 1 = -2 turns a second.
example : (22 : ℤ) - 24 * round ((22 : ℚ) / 24) = -2 := by norm_num [round_eq]
-- Filter: stop edge 20 - 5 = 15 kHz, ratio 15/5 = 3; 60 dB is a power ratio of 10^6.
-- Order 7 reaches it (1 + 3^14 ≥ 10^6), order 6 does not (1 + 3^12 < 10^6).
example : (20 : ℕ) - 5 = 15 ∧ 15 / 5 = 3 := by decide
example : (10 : ℕ) ^ 6 ≤ 1 + 3 ^ 14 ∧ 1 + 3 ^ 12 < (10 : ℕ) ^ 6 := by norm_num
-- Sized at the Nyquist frequency instead (ratio 10/5 = 2): order 10 is the smallest for 60 dB.
example : (10 : ℕ) ^ 6 ≤ 1 + 2 ^ 20 ∧ 1 + 2 ^ 18 < (10 : ℕ) ^ 6 := by norm_num
-- Try it: 90 dB at ratio 3 needs order 10.
example : (10 : ℕ) ^ 9 ≤ 1 + 3 ^ 20 ∧ 1 + 3 ^ 18 < (10 : ℕ) ^ 9 := by norm_num
-- Try it: at 40 kHz, Nyquist 20 kHz, stop edge 40 - 5 = 35 kHz, ratio 7, order 4 for 60 dB.
example : (40 : ℕ) / 2 = 20 ∧ 40 - 5 = 35 ∧ 35 / 5 = 7 := by decide
example : (10 : ℕ) ^ 6 ≤ 1 + 7 ^ 8 ∧ 1 + 7 ^ 6 < (10 : ℕ) ^ 6 := by norm_num
-- Guitar: 44100 readings a second for 10 s is 441000 readings; Nyquist 22050 Hz;
-- stop edge 44100 - 20000 = 24100 Hz.
example : (44100 : ℕ) * 10 = 441000 ∧ 44100 / 2 = 22050 ∧ 44100 - 20000 = 24100 := by decide

#print axioms band_limited_signal_is_sinc_sum_of_its_samples
#print axioms tone_and_its_alias_give_the_same_samples
#print axioms butterworth_order_rule

end Sampling
