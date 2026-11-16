-- Correlation: correlation is convolution with a flipped, conjugated copy, and with noise independent from sample to sample the matched filter gives the largest signal-to-noise ratio of any linear detector, reached only by copies of the pulse.
import Mathlib.Analysis.Fourier.Convolution
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Independence.Basic
import Mathlib.Tactic.NormNum

/-! Signals are complex-valued functions of time `t : ℝ`. `𝓕 f ξ` is Mathlib's Fourier transform
in hertz, `∫ e^(−2πiξt) f(t) dt`, the card's `f̂(ξ)`. The card's convolution
`(f * g)(t) = ∫ f(u) g(t − u) du` is Mathlib's `f ⋆[ContinuousLinearMap.mul ℂ ℂ] g`, and the
cross-correlation is `R_fg(τ) = ∫ f(t) conj(g(t − τ)) dt`.

The radar: a pulse of `N` real chips `s k`, an echo of height `A`, and noise samples `n k`, random
variables on a probability space `(Ω, P)` with standard deviation `σ`, independent from sample to
sample. A linear detector with weights `w` reports `∑ w k r (d + k)`; its echo part is
`A ∑ w k s k` and its noise part is the random variable `∑ w k n k`. Its signal-to-noise ratio is
the echo part squared over the variance of the noise part. -/

open MeasureTheory ProbabilityTheory FourierTransform ComplexConjugate
open scoped Convolution

/-- The signal-to-noise ratio of the linear detector with weights `w`: the square of the echo's
contribution `A ∑ w k s k` over the variance of the noise's contribution `∑ w k n k`. -/
noncomputable def detectorSNR {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) {N : ℕ}
    (A : ℝ) (s w : Fin N → ℝ) (n : Fin N → Ω → ℝ) : ℝ :=
  A ^ 2 * (∑ k, w k * s k) ^ 2 / Var[fun ω => ∑ k, w k * n k ω; P]

/-- The noise part of a linear detector has variance `σ² ∑ w k²` when the noise samples are
independent, each with variance `σ²`. -/
theorem detector_noise_variance {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] {N : ℕ} (σ : ℝ) (w : Fin N → ℝ) (n : Fin N → Ω → ℝ)
    (hind : iIndepFun n P) (hmem : ∀ k, MemLp (n k) 2 P) (hvar : ∀ k, Var[n k; P] = σ ^ 2) :
    Var[fun ω => ∑ k, w k * n k ω; P] = σ ^ 2 * ∑ k, w k ^ 2 := by
  have hcomp : iIndepFun (fun k => (fun x => w k * x) ∘ n k) P :=
    hind.comp _ (fun k => measurable_const_mul (w k))
  have hfun : (fun ω => ∑ k, w k * n k ω) = ∑ k ∈ Finset.univ, (fun ω => w k * n k ω) := by
    ext ω; simp [Finset.sum_apply]
  rw [hfun, IndepFun.variance_sum (fun k _ => (hmem k).const_mul (w k))
    (fun i _ j _ hij => hcomp.indepFun hij)]
  simp only [variance_const_mul, hvar, Finset.mul_sum]
  exact Finset.sum_congr rfl fun k _ => by ring

#print axioms detector_noise_variance

/-- Equality in the Cauchy–Schwarz inequality forces proportional vectors. -/
theorem sum_mul_sq_eq_imp_smul {N : ℕ} (s w : Fin N → ℝ) (hs : s ≠ 0)
    (h : (∑ k, w k * s k) ^ 2 = (∑ k, w k ^ 2) * ∑ k, s k ^ 2) :
    ∃ c : ℝ, w = c • s := by
  have hS : 0 < ∑ k, s k ^ 2 := by
    obtain ⟨i, hi⟩ := Function.ne_iff.mp hs
    simp only [Pi.zero_apply] at hi
    exact lt_of_lt_of_le (by positivity) (Finset.single_le_sum
      (f := fun k => s k ^ 2) (fun k _ => sq_nonneg _) (Finset.mem_univ i))
  set c := (∑ k, w k * s k) / ∑ k, s k ^ 2 with hc
  refine ⟨c, ?_⟩
  have hsum : ∑ k, (w k - c * s k) ^ 2 = 0 := by
    have e : ∑ k, (w k - c * s k) ^ 2 =
        ∑ k, w k ^ 2 - 2 * c * ∑ k, w k * s k + c ^ 2 * ∑ k, s k ^ 2 := by
      simp only [sub_sq, Finset.sum_add_distrib, Finset.sum_sub_distrib, Finset.mul_sum]
      congr 1; congr 1
      all_goals exact Finset.sum_congr rfl fun k _ => by ring
    rw [e, hc]
    field_simp
    nlinarith [h]
  have hz := (Finset.sum_eq_zero_iff_of_nonneg (fun k _ => sq_nonneg (w k - c * s k))).1 hsum
  funext k
  have := hz k (Finset.mem_univ k)
  simp only [Pi.smul_apply, smul_eq_mul]
  nlinarith [sq_nonneg (w k - c * s k), pow_eq_zero_iff (n := 2) (two_ne_zero) |>.1 this]

#print axioms sum_mul_sq_eq_imp_smul

/-- The matched filter is the best linear detector. When the noise samples are independent from
sample to sample, each with standard deviation `σ`, no choice of weights `w` gives a larger
signal-to-noise ratio than `A² E / σ²`, where `E = ∑ s k²` is the pulse's energy; and the weights
that copy the pulse, `w = s`, reach it. -/
theorem matched_filter_maximizes_snr {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] {N : ℕ} (A σ : ℝ) (s : Fin N → ℝ) (n : Fin N → Ω → ℝ)
    (hind : iIndepFun n P) (hmem : ∀ k, MemLp (n k) 2 P) (hvar : ∀ k, Var[n k; P] = σ ^ 2)
    (hσ : 0 < σ) :
    (∀ w : Fin N → ℝ, w ≠ 0 → detectorSNR P A s w n ≤ A ^ 2 * (∑ k, s k ^ 2) / σ ^ 2) ∧
      detectorSNR P A s s n = A ^ 2 * (∑ k, s k ^ 2) / σ ^ 2 := by
  constructor
  · intro w hw
    have hW : 0 < ∑ k, w k ^ 2 := by
      obtain ⟨i, hi⟩ := Function.ne_iff.mp hw
      simp only [Pi.zero_apply] at hi
      exact lt_of_lt_of_le (by positivity) (Finset.single_le_sum
        (f := fun k => w k ^ 2) (fun k _ => sq_nonneg _) (Finset.mem_univ i))
    unfold detectorSNR
    rw [detector_noise_variance σ w n hind hmem hvar]
    rw [div_le_div_iff₀ (by positivity) (by positivity)]
    have hcs := Finset.sum_mul_sq_le_sq_mul_sq Finset.univ w s
    have hA : 0 ≤ A ^ 2 * σ ^ 2 := by positivity
    nlinarith [mul_le_mul_of_nonneg_left hcs hA]
  · unfold detectorSNR
    rw [detector_noise_variance σ s n hind hmem hvar]
    by_cases hS : ∑ k, s k ^ 2 = 0
    · simp [hS]
    · have : ∑ k, s k * s k = ∑ k, s k ^ 2 := Finset.sum_congr rfl fun k _ => by ring
      rw [this]
      field_simp

/-- Only copies of the pulse are best. For a real echo (`A ≠ 0`) and a nonzero pulse, a detector
with weights `w ≠ 0` reaches the bound `A² E / σ²` exactly when `w` is a multiple `c s` of the
pulse. -/
theorem matched_filter_snr_eq_bound_iff {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] {N : ℕ} (A σ : ℝ) (s : Fin N → ℝ) (n : Fin N → Ω → ℝ)
    (hind : iIndepFun n P) (hmem : ∀ k, MemLp (n k) 2 P) (hvar : ∀ k, Var[n k; P] = σ ^ 2)
    (hσ : 0 < σ) (hA : A ≠ 0) (hs : s ≠ 0) (w : Fin N → ℝ) (hw : w ≠ 0) :
    detectorSNR P A s w n = A ^ 2 * (∑ k, s k ^ 2) / σ ^ 2 ↔ ∃ c : ℝ, w = c • s := by
  have hW : 0 < ∑ k, w k ^ 2 := by
    obtain ⟨i, hi⟩ := Function.ne_iff.mp hw
    simp only [Pi.zero_apply] at hi
    exact lt_of_lt_of_le (by positivity) (Finset.single_le_sum
      (f := fun k => w k ^ 2) (fun k _ => sq_nonneg _) (Finset.mem_univ i))
  unfold detectorSNR
  rw [detector_noise_variance σ w n hind hmem hvar]
  have hA2 : 0 < A ^ 2 := by positivity
  constructor
  · intro h
    apply sum_mul_sq_eq_imp_smul s w hs
    rw [div_eq_div_iff (by positivity) (by positivity)] at h
    have h' : A ^ 2 * σ ^ 2 * ((∑ k, w k * s k) ^ 2) =
        A ^ 2 * σ ^ 2 * ((∑ k, w k ^ 2) * ∑ k, s k ^ 2) := by linarith
    exact mul_left_cancel₀ (by positivity) h'
  · rintro ⟨c, rfl⟩
    have hc : c ≠ 0 := by rintro rfl; exact hw (by simp)
    simp only [Pi.smul_apply, smul_eq_mul]
    have e1 : ∑ k, c * s k * s k = c * ∑ k, s k ^ 2 := by
      rw [Finset.mul_sum]; exact Finset.sum_congr rfl fun k _ => by ring
    have e2 : ∑ k, (c * s k) ^ 2 = c ^ 2 * ∑ k, s k ^ 2 := by
      rw [Finset.mul_sum]; exact Finset.sum_congr rfl fun k _ => by ring
    have hS : ∑ k, s k ^ 2 ≠ 0 := by
      intro h0; apply hc
      simp only [Pi.smul_apply, smul_eq_mul] at hW
      rw [e2, h0] at hW; simp at hW
    rw [e1, e2]
    field_simp

/-- Correlation is convolution with a flipped copy. Writing `g̃(t) = conj (g (−t))`, the
cross-correlation `R_fg(τ) = ∫ f(t) conj(g(t − τ)) dt` equals `(f * g̃)(τ)` at every lag `τ`; and
for signals of finite area its transform is `f̂(ξ) conj(ĝ(ξ))` at every frequency `ξ`. -/
theorem correlation_eq_convolution_with_flip {f g : ℝ → ℂ} (hf : Integrable f)
    (hg : Integrable g) :
    (∀ τ : ℝ, (f ⋆[ContinuousLinearMap.mul ℂ ℂ] fun t => conj (g (-t))) τ =
        ∫ t, f t * conj (g (t - τ))) ∧
      ∀ ξ : ℝ, 𝓕 (fun τ => ∫ t, f t * conj (g (t - τ))) ξ = 𝓕 f ξ * conj (𝓕 g ξ) := by
  have h1 : ∀ τ : ℝ, (f ⋆[ContinuousLinearMap.mul ℂ ℂ] fun t => conj (g (-t))) τ =
        ∫ t, f t * conj (g (t - τ)) := by
    intro τ
    rw [convolution_def]
    congr 1
    ext t
    simp only [ContinuousLinearMap.mul_apply', neg_sub]
  refine ⟨h1, fun ξ => ?_⟩
  have hfun : (fun τ => ∫ t, f t * conj (g (t - τ))) =
      (f ⋆[ContinuousLinearMap.mul ℂ ℂ] fun t => conj (g (-t))) := by
    funext τ; exact (h1 τ).symm
  have hg' : Integrable (fun t => conj (g (-t))) := by
    exact (Complex.conjCLE.toContinuousLinearMap.integrable_comp hg.comp_neg :)
  rw [hfun, Real.fourier_mul_convolution_eq hf hg' ξ]
  congr 1
  rw [Real.fourier_real_eq, Real.fourier_real_eq, ← integral_conj]
  rw [← integral_neg_eq_self]
  congr 1
  ext v
  simp [Circle.smul_def, Real.fourierChar_apply]
  left
  rw [← Complex.exp_conj]
  congr 1
  simp [map_mul, Complex.conj_ofReal]
  left
  exact (Complex.conj_ofNat 2).symm

/-! The card's worked numbers. A pulse is a whole-number signal on the samples `k`, zero outside
`0 ≤ k < 13`, one sample per microsecond. The sampled correlation is
`R_rs[m] = ∑ k, r (k + m) s k`. -/

/-- The 13-chip Barker code, chips 0 to 12, zero elsewhere. -/
def barker (k : ℤ) : ℤ :=
  if 0 ≤ k ∧ k < 13 then [1, 1, 1, 1, 1, -1, -1, 1, 1, -1, 1, -1, 1].getD k.toNat 0 else 0

/-- The plain pulse: 13 upright chips. -/
def plainPulse (k : ℤ) : ℤ := if 0 ≤ k ∧ k < 13 then 1 else 0

/-- The Barker code read backwards, the kernel that convolution would slide. -/
def barkerReversed (k : ℤ) : ℤ := barker (12 - k)

/-- `R_rs[m] = ∑ k r (k + m) s k` for a 13-sample pulse `s`. -/
def sampledCorr (r s : ℤ → ℤ) (m : ℤ) : ℤ := ∑ k ∈ Finset.range 13, r (k + m) * s k

/-- A clean record: unit echoes of the pulse `p` at the given delays, no noise. -/
def cleanRecord (p : ℤ → ℤ) (delays : List ℤ) (k : ℤ) : ℤ := (delays.map fun d => p (k - d)).sum

-- The Barker autocorrelation at lags −12 to 12: a spike of 13 with side values 0 or 1.
example : (List.range 25).map (fun i => sampledCorr barker barker ((i : ℤ) - 12)) =
    [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 13, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1] := by decide
-- The plain pulse's autocorrelation at lags −12 to 12: a triangle falling by 1 per microsecond.
example : (List.range 25).map (fun i => sampledCorr plainPulse plainPulse ((i : ℤ) - 12)) =
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1] := by decide
-- Both pulses have energy E = 13.
example : ∑ k ∈ Finset.range 13, barker k ^ 2 = 13 ∧
    ∑ k ∈ Finset.range 13, plainPulse k ^ 2 = 13 := by decide
-- Range: 3e8 m/s × 1 µs / 2 = 150 m per microsecond; 100 µs is 15,000 m; 4 µs is 600 m.
example : (300000000 : ℚ) * (1 / 1000000) / 2 = 150 ∧ (100 : ℚ) * 150 = 15000 ∧
    (4 : ℚ) * 150 = 600 := by norm_num
-- Worked numbers: echo part A E = 13 µV, noise variance σ² E = 13, SNR 13² / 13 = 13.
example : (1 : ℚ) * 13 = 13 ∧ (1 : ℚ) ^ 2 * 13 = 13 ∧ (13 : ℚ) ^ 2 / 13 = 13 := by norm_num
-- Convolving with the pulse as sent (sliding the reversed code) on a clean echo at 100 µs:
-- output 1 at lag 100, peak 5 at lags 92 and 108, and nothing above 5 on lags 0 to 187.
example : sampledCorr (cleanRecord barker [100]) barkerReversed 100 = 1 ∧
    sampledCorr (cleanRecord barker [100]) barkerReversed 92 = 5 ∧
    sampledCorr (cleanRecord barker [100]) barkerReversed 108 = 5 ∧
    ∀ m ∈ Finset.range 188, sampledCorr (cleanRecord barker [100]) barkerReversed m ≤ 5 := by
  decide +kernel
-- Two echoes at 100 and 104 µs, no noise, lags 96 to 108: the Barker output reads 14 at both.
example : (List.range 13).map (fun i => sampledCorr (cleanRecord barker [100, 104]) barker
      ((i : ℤ) + 96)) = [2, 0, 2, 0, 14, 0, 2, 0, 14, 0, 2, 0, 2] := by decide
-- The plain pulse's output is one plateau of 22 from 100 to 104.
example : (List.range 13).map (fun i => sampledCorr (cleanRecord plainPulse [100, 104]) plainPulse
      ((i : ℤ) + 96)) = [14, 16, 18, 20, 22, 22, 22, 22, 22, 20, 18, 16, 14] := by decide
-- Try changing: echoes 2 µs apart. Barker reads 14, 0, 14 at lags 100 to 102; plain reads 24.
example : (List.range 3).map (fun i => sampledCorr (cleanRecord barker [100, 102]) barker
      ((i : ℤ) + 100)) = [14, 0, 14] ∧
    (List.range 3).map (fun i => sampledCorr (cleanRecord plainPulse [100, 102]) plainPulse
      ((i : ℤ) + 100)) = [24, 24, 24] := by decide
-- Try changing: an echo of 0.7 µV adds 0.7 × 13 = 9.1 µV at its own lag.
example : (7 / 10 : ℚ) * 13 = 91 / 10 := by norm_num

#print axioms matched_filter_maximizes_snr
#print axioms matched_filter_snr_eq_bound_iff
#print axioms correlation_eq_convolution_with_flip
