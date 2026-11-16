-- Poisson summation and sampling: for a continuous signal that, with its transform, fades like a power of 1/|t| higher than the first, the sum of its samples every T seconds equals 1/T times the sum of its transform at the multiples of 1/T, so the samples' spectrum is the true spectrum plus copies every 1/T hertz, and with nothing at or above half the rate the samples report the true spectrum.
import Mathlib.Analysis.Fourier.PoissonSummation

open Complex Real
open scoped FourierTransform

section PSHelpers

open Filter Asymptotics MeasureTheory

/-- Decay bound to big-O at infinity. -/
lemma ps_isBigO_of_bound {h : ℝ → ℂ} {C a c b : ℝ} (hC : 0 ≤ C) (ha : a ≠ 0) (hb : 0 < b)
    (hh : ∀ x : ℝ, ‖h x‖ ≤ C * (1 + |a * x + c|) ^ (-b)) :
    h =O[cocompact ℝ] (|·| ^ (-b)) := by
  have ha' : 0 < |a| := abs_pos.mpr ha
  refine Asymptotics.IsBigO.of_bound (C * (|a| / 2) ^ (-b)) ?_
  have hev := (tendsto_norm_cocompact_atTop (E := ℝ)).eventually_ge_atTop (2 * |c| / |a| + 1)
  filter_upwards [hev] with x hx
  rw [Real.norm_eq_abs] at hx
  have hx1 : 2 * |c| ≤ |a| * |x| := by
    have : 2 * |c| / |a| ≤ |x| := by linarith
    rw [div_le_iff₀ ha'] at this; linarith
  have hxpos : 0 < |x| := by
    have : 0 ≤ 2 * |c| / |a| := by positivity
    linarith
  have hlow : |a| * |x| / 2 ≤ 1 + |a * x + c| := by
    have h1 : |a * x| - |c| ≤ |a * x + c| := by
      have := abs_sub_abs_le_abs_sub (a * x) (-c)
      simpa [sub_neg_eq_add, abs_neg] using this
    rw [abs_mul] at h1
    linarith
  have hpos : 0 < |a| * |x| / 2 := by positivity
  calc ‖h x‖ ≤ C * (1 + |a * x + c|) ^ (-b) := hh x
    _ ≤ C * (|a| * |x| / 2) ^ (-b) := by
        apply mul_le_mul_of_nonneg_left _ hC
        exact Real.rpow_le_rpow_of_nonpos hpos hlow (by linarith)
    _ = C * (|a| / 2) ^ (-b) * ‖|x| ^ (-b)‖ := by
        rw [Real.norm_eq_abs, abs_of_nonneg (Real.rpow_nonneg (abs_nonneg x) _),
          show |a| * |x| / 2 = (|a| / 2) * |x| by ring, Real.mul_rpow (by positivity) hxpos.le]
        ring

/-- Big-O decay with exponent above one gives summable norms at the integers. -/
lemma ps_summable_norm {h : ℝ → ℂ} {b : ℝ} (hb : 1 < b) (hh : h =O[cocompact ℝ] (|·| ^ (-b))) :
    Summable fun n : ℤ => ‖h n‖ :=
  summable_of_isBigO (Real.summable_abs_int_rpow hb)
    (hh.norm_left.comp_tendsto Int.tendsto_coe_cofinite)

/-- The general scaled and modulated Poisson formula. -/
lemma ps_main {f : ℝ → ℂ} (hc : Continuous f)
    {M δ : ℝ} (hM : 0 < M) (hδ : 0 < δ)
    (hf : ∀ t : ℝ, ‖f t‖ ≤ M * (1 + |t|) ^ (-1 - δ))
    (hFf : ∀ ξ : ℝ, ‖𝓕 f ξ‖ ≤ M * (1 + |ξ|) ^ (-1 - δ))
    {T : ℝ} (hT : 0 < T) (ξ : ℝ) :
    (T : ℂ) * ∑' n : ℤ, f (n * T) * Complex.exp (↑(-2 * π * ξ * (n * T)) * Complex.I) =
      ∑' k : ℤ, 𝓕 f (ξ + k * (1 / T)) := by
  set g : ℝ → ℂ := fun t => (T : ℂ) * (f (t * T) * Complex.exp (↑(-2 * π * ξ * (t * T)) * Complex.I))
    with hg
  have hb : 1 < 1 + δ := by linarith
  have hneg : -1 - δ = -(1 + δ) := by ring
  have hgc : Continuous g := by
    have : Continuous fun t : ℝ => f (t * T) := hc.comp (continuous_id.mul continuous_const)
    fun_prop
  have hFg : ∀ w : ℝ, 𝓕 g w = 𝓕 f (ξ + w * (1 / T)) := by
    intro w
    rw [Real.fourier_real_eq_integral_exp_smul, Real.fourier_real_eq_integral_exp_smul]
    set F : ℝ → ℂ := fun s => Complex.exp (↑(-2 * π * s * (ξ + w * (1 / T))) * Complex.I) • f s
    have hpt : ∀ v : ℝ, Complex.exp (↑(-2 * π * v * w) * Complex.I) • g v = (T : ℂ) • F (v * T) := by
      intro v
      simp only [hg, F, smul_eq_mul]
      have : Complex.exp (↑(-2 * π * v * w) * Complex.I) *
          Complex.exp (↑(-2 * π * ξ * (v * T)) * Complex.I) =
          Complex.exp (↑(-2 * π * (v * T) * (ξ + w * (1 / T))) * Complex.I) := by
        rw [← Complex.exp_add]
        congr 1
        have hT0 : (T : ℂ) ≠ 0 := by exact_mod_cast hT.ne'
        push_cast
        field_simp
        ring
      rw [← this]; ring
    simp_rw [hpt]
    rw [integral_smul, MeasureTheory.Measure.integral_comp_mul_right, abs_inv, abs_of_pos hT]
    have : (T : ℂ) * (T⁻¹ : ℝ) = 1 := by
      have hT0 : (T : ℂ) ≠ 0 := by exact_mod_cast hT.ne'
      push_cast; field_simp
    rw [smul_eq_mul, Complex.real_smul, ← mul_assoc, this, one_mul]
  have hg_bound : ∀ x : ℝ, ‖g x‖ ≤ (T * M) * (1 + |T * x + 0|) ^ (-(1 + δ)) := by
    intro x
    simp only [hg, norm_mul, Complex.norm_real, Real.norm_eq_abs, abs_of_pos hT]
    rw [Complex.norm_exp_ofReal_mul_I, mul_one, add_zero, mul_comm T x, mul_assoc, ← hneg]
    exact mul_le_mul_of_nonneg_left (hf _) hT.le
  have hFg_bound : ∀ x : ℝ, ‖𝓕 g x‖ ≤ M * (1 + |(1 / T) * x + ξ|) ^ (-(1 + δ)) := by
    intro x
    rw [hFg, ← hneg, add_comm ((1 / T) * x), mul_comm (1 / T)]
    exact hFf _
  have hgO := ps_isBigO_of_bound (by positivity) hT.ne' (by linarith) hg_bound
  have hFgO := ps_isBigO_of_bound hM.le (by positivity) (by linarith) hFg_bound
  have hP := Real.tsum_eq_tsum_fourier_of_rpow_decay_of_summable hgc hb hgO
    (ps_summable_norm hb hFgO).of_norm 0
  simp only [zero_add, hFg, AddCircle.coe_zero, fourier_eval_zero, mul_one] at hP
  rw [← hP, hg, tsum_mul_left]

end PSHelpers


/-- **Poisson summation.** Let `f` be a continuous signal and let `T > 0` be the time between
samples, so the sampling rate is `f_s = 1/T`. Suppose there are constants `M > 0` and `δ > 0`
with `|f(t)| ≤ M (1 + |t|)^(-1-δ)` and `|f̂(ξ)| ≤ M (1 + |ξ|)^(-1-δ)`, where
`f̂(ξ) = 𝓕 f ξ = ∫ f(t) e^(-2πiξt) dt`. Then both sums converge absolutely, and the sum of all
samples equals the sampling rate times the sum of the spectrum at every whole multiple of the
sampling rate: `∑ₙ f(nT) = f_s ∑ₖ f̂(k f_s)`. -/
theorem sum_of_samples_eq_rate_times_sum_of_spectrum {f : ℝ → ℂ} (hc : Continuous f)
    {M δ : ℝ} (hM : 0 < M) (hδ : 0 < δ)
    (hf : ∀ t : ℝ, ‖f t‖ ≤ M * (1 + |t|) ^ (-1 - δ))
    (hFf : ∀ ξ : ℝ, ‖𝓕 f ξ‖ ≤ M * (1 + |ξ|) ^ (-1 - δ))
    {T : ℝ} (hT : 0 < T) :
    (Summable fun n : ℤ => ‖f (n * T)‖) ∧
    (Summable fun k : ℤ => ‖𝓕 f (k * (1 / T))‖) ∧
    ∑' n : ℤ, f (n * T) = ((1 / T : ℝ) : ℂ) * ∑' k : ℤ, 𝓕 f (k * (1 / T)) := by
  have hb : 1 < 1 + δ := by linarith
  have hneg : -1 - δ = -(1 + δ) := by ring
  refine ⟨?_, ?_, ?_⟩
  · have hB : ∀ x : ℝ, ‖f (x * T)‖ ≤ M * (1 + |T * x + 0|) ^ (-(1 + δ)) := by
      intro x; rw [add_zero, mul_comm T x, ← hneg]; exact hf _
    have hO := ps_isBigO_of_bound hM.le hT.ne' (by linarith) hB
    exact ps_summable_norm hb hO
  · have hTi : (1 / T) ≠ 0 := by positivity
    have hB : ∀ x : ℝ, ‖𝓕 f (x * (1 / T))‖ ≤ M * (1 + |(1 / T) * x + 0|) ^ (-(1 + δ)) := by
      intro x; rw [add_zero, mul_comm (1 / T) x, ← hneg]; exact hFf _
    have hO := ps_isBigO_of_bound hM.le hTi (by linarith) hB
    have hS := ps_summable_norm hb hO
    beta_reduce at hS
    exact hS
  · have h := ps_main hc hM hδ hf hFf hT 0
    simp only [mul_zero, zero_mul, Complex.ofReal_zero, Complex.exp_zero, mul_one, zero_add] at h
    have hT0 : (T : ℂ) ≠ 0 := by exact_mod_cast hT.ne'
    have h1 : ((1 / T : ℝ) : ℂ) * (T : ℂ) = 1 := by push_cast; field_simp
    rw [← h, ← mul_assoc, h1, one_mul]

/-- **The copies.** Under the same conditions, the sampled spectrum
`S(ξ) = T ∑ₙ f(nT) e^(-2πiξnT)`, what the samples alone report, equals at every frequency `ξ`
the true spectrum plus a copy of it shifted by every whole multiple of the sampling rate
`f_s = 1/T`: `S(ξ) = ∑ₖ f̂(ξ - k f_s)`. -/
theorem sampled_spectrum_eq_sum_of_copies {f : ℝ → ℂ} (hc : Continuous f)
    {M δ : ℝ} (hM : 0 < M) (hδ : 0 < δ)
    (hf : ∀ t : ℝ, ‖f t‖ ≤ M * (1 + |t|) ^ (-1 - δ))
    (hFf : ∀ ξ : ℝ, ‖𝓕 f ξ‖ ≤ M * (1 + |ξ|) ^ (-1 - δ))
    {T : ℝ} (hT : 0 < T) (ξ : ℝ) :
    (T : ℂ) * ∑' n : ℤ, f (n * T) * Complex.exp (↑(-2 * π * ξ * (n * T)) * Complex.I) =
      ∑' k : ℤ, 𝓕 f (ξ - k * (1 / T)) := by
  rw [ps_main hc hM hδ hf hFf hT ξ]
  rw [← (Equiv.neg ℤ).tsum_eq]
  congr 1 with k
  simp [sub_eq_add_neg]

/-- **No overlap means nothing is lost.** Under the same conditions, if the spectrum is zero at
and above half the sampling rate, `f̂(ξ) = 0` for `|ξ| ≥ f_s/2` with `f_s = 1/T`, then inside
the band `|ξ| < f_s/2` the samples report the true spectrum exactly:
`T ∑ₙ f(nT) e^(-2πiξnT) = f̂(ξ)`. -/
theorem sampled_spectrum_eq_spectrum_of_band_limited {f : ℝ → ℂ} (hc : Continuous f)
    {M δ : ℝ} (hM : 0 < M) (hδ : 0 < δ)
    (hf : ∀ t : ℝ, ‖f t‖ ≤ M * (1 + |t|) ^ (-1 - δ))
    (hFf : ∀ ξ : ℝ, ‖𝓕 f ξ‖ ≤ M * (1 + |ξ|) ^ (-1 - δ))
    {T : ℝ} (hT : 0 < T)
    (hband : ∀ ξ : ℝ, (1 / T) / 2 ≤ |ξ| → 𝓕 f ξ = 0)
    (ξ : ℝ) (hξ : |ξ| < (1 / T) / 2) :
    (T : ℂ) * ∑' n : ℤ, f (n * T) * Complex.exp (↑(-2 * π * ξ * (n * T)) * Complex.I) =
      𝓕 f ξ := by
  rw [sampled_spectrum_eq_sum_of_copies hc hM hδ hf hFf hT ξ]
  rw [tsum_eq_single 0]
  · simp
  · intro k hk
    apply hband
    have hk1 : (1 : ℝ) ≤ |(k : ℝ)| := by
      rw [← Int.cast_abs]; exact_mod_cast Int.one_le_abs hk
    have hTi : 0 < 1 / T := by positivity
    have h2 : 1 / T ≤ |(k : ℝ) * (1 / T)| := by
      rw [abs_mul, abs_of_pos hTi]; nlinarith
    have h3 : |(k : ℝ) * (1 / T)| - |ξ| ≤ |ξ - k * (1 / T)| := by
      rw [abs_sub_comm]; exact abs_sub_abs_le_abs_sub _ _
    linarith

/-! Whole-number checks from the card's worked examples. -/

-- The click's width in samples: b = a f_s = 25 μs × 48,000 per second = 6/5 = 1.2.
example : (25 : ℚ) / 10 ^ 6 * 48000 = 6 / 5 := by norm_num

-- A 30 kHz tone sampled at 48 kHz: the nearest multiple of 48,000 is 48,000, heard at 18,000 Hz.
example : Int.natAbs (30000 - 48000 * 1) = 18000 := by decide
-- The same tone sampled at 44.1 kHz is heard at 14,100 Hz.
example : Int.natAbs (30000 - 44100 * 1) = 14100 := by decide

-- Tones at 40,500, 41,500, ..., 47,500 Hz sampled at 16,000 Hz (nearest multiple 48,000)
-- are heard at 7,500, 6,500, ..., 500 Hz, each in a place of its own.
example : (List.range 8).map (fun j : ℕ => Int.natAbs (40500 + 1000 * (j : ℤ) - 16000 * 3)) =
    [7500, 6500, 5500, 4500, 3500, 2500, 1500, 500] := by decide

-- The shutter gate, equal to 1 on [0, 1] ms and read every 1 ms: two samples (at 0 and 1)
-- are 1, so the sample sum is 2, while the transform side is 1.
example : ((Finset.Icc (-5 : ℤ) 5).filter (fun n => 0 ≤ n ∧ n ≤ 1)).card = 2 := by decide
-- With the value 1/2 at each jump, the sample sum is 1/2 + 1/2 = 1, matching the transform side.
example : (1 / 2 : ℚ) + 1 / 2 = 1 := by norm_num

#print axioms ps_isBigO_of_bound
#print axioms ps_summable_norm
#print axioms ps_main
#print axioms sum_of_samples_eq_rate_times_sum_of_spectrum
#print axioms sampled_spectrum_eq_sum_of_copies
#print axioms sampled_spectrum_eq_spectrum_of_band_limited
