-- Windows: for every frame length N and every real window, the windowed DFT of a steady tone A cos(2π f₀ n / f_s) is A/2 times the window's spectrum moved onto plus and minus the tone; the plain cut's spectrum is zero at every whole offset that is not a multiple of N; and every cosine window's spectrum is shifted copies of the plain cut's.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Complex.Circle
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic.NormNum

open Complex Finset
open Real (pi)

/-! Conventions, as on the card.
* A frame is the samples `n = 0, 1, …, N - 1`; the window gives sample `n` the real weight `w n`.
* `j` on the card is Lean's `I`, the square root of -1.
* The window's spectrum at an offset of `d` bins (any real `d`) is
  `W(d) = ∑_{n<N} w[n] e^(-j 2π d n / N)`.
* A cosine window has weights `a₀ - a₁ cos(2πn/N) + a₂ cos(4πn/N)`; the plain cut is `(1, 0, 0)`,
  Hann `(1/2, 1/2, 0)`, Hamming `(0.54, 0.46, 0)`, Blackman `(0.42, 0.5, 0.08)`. -/

/-- The window's own spectrum, `d` bins off centre: `W(d) = ∑_{n<N} w[n] e^(-j 2π d n / N)`. -/
noncomputable def windowSpectrum (N : ℕ) (w : ℕ → ℝ) (d : ℝ) : ℂ :=
  ∑ n ∈ range N, (w n : ℂ) * cexp (-((2 * pi * d * n / N : ℝ) : ℂ) * I)

/-- **The leakage identity.** Take any frame length `N`, any real window `w`, and a steady tone
`x[n] = A cos(2π f₀ n / f_s)` sampled `f_s` times a second, which sits `β = f₀ N / f_s` bins up
the scale. Then the windowed DFT at bin `k`,
`X[k] = ∑_{n<N} w[n] x[n] e^(-j 2π k n / N)`, equals `(A/2) [W(k - β) + W(k + β)]`:
the window's own spectrum centred on the tone, plus a mirror copy centred on minus the tone.
(Stated for every real `k`, so it covers the whole-number bins and the zero-padded ones.) -/
theorem windowed_tone_dft_eq_shifted_window_spectrum (N : ℕ) (w : ℕ → ℝ)
    (A f₀ f_s k : ℝ) :
    ∑ n ∈ range N, (w n : ℂ) * ((A * Real.cos (2 * pi * f₀ * n / f_s) : ℝ) : ℂ) *
        cexp (-((2 * pi * k * n / N : ℝ) : ℂ) * I) =
      ((A / 2 : ℝ) : ℂ) *
        (windowSpectrum N w (k - f₀ * N / f_s) + windowSpectrum N w (k + f₀ * N / f_s)) := by
  unfold windowSpectrum
  rw [← sum_add_distrib, mul_sum]
  refine sum_congr rfl fun n hn => ?_
  have hN : (N : ℝ) ≠ 0 := by
    have := mem_range.mp hn
    exact_mod_cast (by omega : N ≠ 0)
  have hinv : (N : ℝ) * (N : ℝ)⁻¹ = 1 := mul_inv_cancel₀ hN
  set θ : ℝ := 2 * pi * f₀ * n / f_s with hθ
  set φ : ℝ := 2 * pi * k * n / N with hφ
  have h1 : 2 * pi * (k - f₀ * N / f_s) * n / N = φ - θ := by
    rw [hθ, hφ]; simp only [div_eq_mul_inv]
    linear_combination (-(2 * pi * f₀ * f_s⁻¹ * n)) * hinv
  have h2 : 2 * pi * (k + f₀ * N / f_s) * n / N = φ + θ := by
    rw [hθ, hφ]; simp only [div_eq_mul_inv]
    linear_combination (2 * pi * f₀ * f_s⁻¹ * n) * hinv
  rw [h1, h2]
  push_cast
  rw [Complex.cos]
  have e1 : -((φ : ℂ) - θ) * I = -(φ : ℂ) * I + θ * I := by ring
  have e2 : -((φ : ℂ) + θ) * I = -(φ : ℂ) * I + -(θ * I) := by ring
  rw [e1, e2, Complex.exp_add, Complex.exp_add]
  ring_nf

/-- **A whole number of cycles leaks nothing.** The plain cut (`w[n] = 1` for every sample)
has a spectrum that is zero at every whole-number offset `d` that is not a multiple of `N`:
a tone exactly on a bin puts nothing into the other bins. -/
theorem rect_window_spectrum_eq_zero_at_whole_offsets (N : ℕ) (d : ℤ) (hd : ¬ (N : ℤ) ∣ d) :
    windowSpectrum N (fun _ => 1) d = 0 := by
  unfold windowSpectrum
  rcases Nat.eq_zero_or_pos N with h0 | hpos
  · subst h0; simp
  have hN : (N : ℝ) ≠ 0 := by exact_mod_cast hpos.ne'
  set r : ℂ := cexp (-((2 * pi * d / N : ℝ) : ℂ) * I) with hr
  have hterm : ∀ n : ℕ, ((1 : ℝ) : ℂ) * cexp (-((2 * pi * (d : ℝ) * n / N : ℝ) : ℂ) * I) = r ^ n := by
    intro n
    rw [hr, ← Complex.exp_nat_mul]
    push_cast; ring_nf
  simp only [hterm]
  have hrN : r ^ N = 1 := by
    rw [hr, ← Complex.exp_nat_mul]
    rw [Complex.exp_eq_one_iff]
    refine ⟨-d, ?_⟩
    have hNc : (N : ℂ) ≠ 0 := by exact_mod_cast hpos.ne'
    push_cast
    field_simp
  have hr1 : r ≠ 1 := by
    intro h
    rw [hr, Complex.exp_eq_one_iff] at h
    obtain ⟨m, hm⟩ := h
    have hNc : (N : ℂ) ≠ 0 := by exact_mod_cast hpos.ne'
    have hpi : (pi : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
    push_cast at hm
    have : (d : ℂ) = -m * N := by
      field_simp at hm
      linear_combination -hm
    apply hd
    refine ⟨-m, ?_⟩
    have : ((d : ℤ) : ℂ) = (((N : ℤ) * (-m) : ℤ) : ℂ) := by push_cast; rw [this]; ring
    exact_mod_cast this
  have := geom_sum_mul r N
  rw [hrN, sub_self] at this
  exact (mul_eq_zero.mp this).resolve_right (sub_ne_zero.mpr hr1)

/-- **A taper is shifted copies of the plain cut.** For any frame length `N` and any cosine
window `w[n] = a₀ - a₁ cos(2πn/N) + a₂ cos(4πn/N)`, its spectrum at every offset `d` is
`a₀ W_rect(d) - (a₁/2)[W_rect(d-1) + W_rect(d+1)] + (a₂/2)[W_rect(d-2) + W_rect(d+2)]`.
For Hann, `(a₀, a₁, a₂) = (1/2, 1/2, 0)`, this is
`W_Hann(d) = ½ W_rect(d) - ¼ W_rect(d-1) - ¼ W_rect(d+1)`. -/
theorem cosine_window_spectrum_eq_shifted_rect (N : ℕ) (a₀ a₁ a₂ d : ℝ) :
    windowSpectrum N
        (fun n => a₀ - a₁ * Real.cos (2 * pi * n / N) + a₂ * Real.cos (4 * pi * n / N)) d =
      (a₀ : ℂ) * windowSpectrum N (fun _ => 1) d
        - ((a₁ / 2 : ℝ) : ℂ) *
            (windowSpectrum N (fun _ => 1) (d - 1) + windowSpectrum N (fun _ => 1) (d + 1))
        + ((a₂ / 2 : ℝ) : ℂ) *
            (windowSpectrum N (fun _ => 1) (d - 2) + windowSpectrum N (fun _ => 1) (d + 2)) := by
  unfold windowSpectrum
  simp only [← sum_add_distrib, mul_sum, ← sum_sub_distrib]
  refine sum_congr rfl fun n _ => ?_
  set φ : ℝ := 2 * pi * d * n / N with hφ
  set α : ℝ := 2 * pi * n / N with hα
  have h4 : 4 * pi * n / N = 2 * α := by rw [hα]; ring
  have hm1 : 2 * pi * (d - 1) * n / N = φ - α := by rw [hφ, hα]; ring
  have hp1 : 2 * pi * (d + 1) * n / N = φ + α := by rw [hφ, hα]; ring
  have hm2 : 2 * pi * (d - 2) * n / N = φ - 2 * α := by rw [hφ, hα]; ring
  have hp2 : 2 * pi * (d + 2) * n / N = φ + 2 * α := by rw [hφ, hα]; ring
  rw [h4, hm1, hp1, hm2, hp2]
  push_cast
  rw [Complex.cos, Complex.cos]
  have e1 : -((φ : ℂ) - α) * I = -(φ : ℂ) * I + α * I := by ring
  have e2 : -((φ : ℂ) + α) * I = -(φ : ℂ) * I + -(α * I) := by ring
  have e3 : -((φ : ℂ) - 2 * α) * I = -(φ : ℂ) * I + (2 * α) * I := by ring
  have e4 : -((φ : ℂ) + 2 * α) * I = -(φ : ℂ) * I + -((2 * α) * I) := by ring
  rw [e1, e2, e3, e4]
  simp only [Complex.exp_add]
  ring_nf

-- The 440 Hz note in the 8192-sample frame at 44,100 Hz sits at β = 440 · 8192 / 44100,
-- between bins 81 and 82 (81.7342 on the card), so it is not a whole number of cycles.
example : (81 : ℚ) < 440 * 8192 / 44100 ∧ (440 * 8192 / 44100 : ℚ) < 82 := by norm_num

-- The 470 Hz buzz sits at 470 · 8192 / 44100 bins (87.3070 on the card); its nearest bin is 87.
example : (87 : ℚ) < 470 * 8192 / 44100 ∧ (470 * 8192 / 44100 : ℚ) < 87 + 1 / 2 := by norm_num

-- Hann's equivalent noise bandwidth: (a₀² + a₁²/2) / a₀² with a₀ = a₁ = 1/2 is exactly 3/2 bins.
example : (((1 : ℚ) / 2) ^ 2 + ((1 : ℚ) / 2) ^ 2 / 2) / ((1 : ℚ) / 2) ^ 2 = 3 / 2 := by norm_num

-- Hann starts the frame at zero: w[0] = 1/2 - 1/2 cos 0 = 0.
example : (1 / 2 : ℝ) - 1 / 2 * Real.cos (2 * pi * (0 : ℕ) / 8192) = 0 := by norm_num

#print axioms windowed_tone_dft_eq_shifted_window_spectrum
#print axioms rect_window_spectrum_eq_zero_at_whole_offsets
#print axioms cosine_window_spectrum_eq_shifted_rect
