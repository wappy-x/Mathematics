-- Changing rate: dropping samples folds each tone to its alias frequency, the zero-padding comb is one in every L-th slot, and zero-padding a tone adds image tones at r·fs ± f.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Algebra.Order.Round
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum.GCD

open Real Finset

/-! A tone of amplitude `a` at frequency `f` (Hz), sampled at `fs` samples a second, is the
stream `k ↦ a * sin (2π f k / fs)` over whole-number sample counters `k`.
Decimation by `M` keeps `y n = x (n M)`; the new rate is `R = fs / M`.
The folded (alias) frequency at rate `R` is the card's `f_alias = |f - R * round (f / R)|`.
Zero-padding by `L` gives `v i = x (i / L)` when `L` divides `i` and `0` otherwise. -/

/-- Helper: the cosine sum over all `L` slots is zero when `L` does not divide `i`. -/
theorem comb_cos_sum_zero (L : ℕ) (hL : 0 < L) (i : ℤ) (hi : ¬ (L : ℤ) ∣ i) :
    ∑ r ∈ range L, Real.cos (2 * π * r * i / L) = 0 := by
  have hL' : (L : ℝ) ≠ 0 := by positivity
  set θ : ℝ := 2 * π * i / L with hθ
  have hs : Real.sin (θ / 2) ≠ 0 := by
    intro h
    rw [Real.sin_eq_zero_iff] at h
    obtain ⟨n, hn⟩ := h
    apply hi
    refine ⟨n, ?_⟩
    have : (i : ℝ) = (L : ℝ) * n := by
      rw [hθ] at hn
      field_simp at hn
      nlinarith [Real.pi_pos]
    exact_mod_cast this
  have key : ∀ r : ℕ, Real.sin (((r + 1 : ℕ) : ℝ) * θ - θ / 2) - Real.sin ((r : ℝ) * θ - θ / 2)
      = 2 * Real.sin (θ / 2) * Real.cos (2 * π * r * i / L) := by
    intro r
    rw [Real.sin_sub_sin]
    congr 2
    · push_cast; congr 1; ring
    · rw [hθ]; push_cast; ring
  have tel := Finset.sum_range_sub (fun r : ℕ => Real.sin ((r : ℝ) * θ - θ / 2)) L
  simp only [key] at tel
  rw [← Finset.mul_sum] at tel
  have hLθ : (L : ℝ) * θ - θ / 2 = -(θ / 2) + (i : ℝ) * (2 * π) := by
    rw [hθ]; field_simp; ring
  rw [hLθ, Real.sin_add_int_mul_two_pi] at tel
  simp only [Nat.cast_zero, zero_mul, zero_sub] at tel
  have : 2 * Real.sin (θ / 2) * ∑ r ∈ range L, Real.cos (2 * π * r * i / L) = 0 := by
    rw [tel]; ring
  rcases mul_eq_zero.mp this with h | h
  · exfalso; apply hs; linarith
  · exact h

/-- Dropping samples folds the spectrum: keeping one sample in `M` of a tone at `f`
sampled at `fs` gives, at the new rate `R = fs / M`, a tone with the same amplitude at the
folded frequency `|f - R * round (f / R)|`, possibly with its sign flipped
(the sign is the same for every sample). -/
theorem decimation_folds_tone (a f fs : ℝ) (hfs : 0 < fs) (M : ℕ) (hM : 0 < M) :
    ∃ s : ℝ, (s = 1 ∨ s = -1) ∧ ∀ n : ℤ,
      a * Real.sin (2 * π * f * ((n * M : ℤ) : ℝ) / fs) =
        s * a * Real.sin (2 * π * |f - fs / M * round (f / (fs / M))| * n / (fs / M)) := by
  have hM' : (M : ℝ) ≠ 0 := by positivity
  have hfs' : fs ≠ 0 := hfs.ne'
  set q : ℤ := round (f / (fs / M))
  set g : ℝ := f - fs / M * q with hg
  have base : ∀ n : ℤ, Real.sin (2 * π * f * ((n * M : ℤ) : ℝ) / fs) =
      Real.sin (2 * π * g * n / (fs / M)) := by
    intro n
    have : 2 * π * f * ((n * M : ℤ) : ℝ) / fs = 2 * π * g * n / (fs / M) + ((q * n : ℤ) : ℝ) * (2 * π) := by
      rw [hg]; push_cast; field_simp; ring
    rw [this, Real.sin_add_int_mul_two_pi]
  rcases le_or_gt 0 g with h | h
  · refine ⟨1, Or.inl rfl, fun n => ?_⟩
    rw [abs_of_nonneg h, base n, one_mul]
  · refine ⟨-1, Or.inr rfl, fun n => ?_⟩
    rw [abs_of_neg h, base n]
    have : 2 * π * -g * n / (fs / M) = -(2 * π * g * n / (fs / M)) := by ring
    rw [this, Real.sin_neg]; ring

/-- The zero-padding comb: `c[i] = (1/L) * Σ_{r=0}^{L-1} cos (2π r i / L)` is `1` when `L`
divides `i` and `0` otherwise. -/
theorem comb_is_one_every_Lth_slot (L : ℕ) (hL : 0 < L) (i : ℤ) :
    (1 / (L : ℝ)) * ∑ r ∈ range L, Real.cos (2 * π * r * i / L) =
      if (L : ℤ) ∣ i then 1 else 0 := by
  have hL' : (L : ℝ) ≠ 0 := by positivity
  split_ifs with h
  · obtain ⟨j, rfl⟩ := h
    have : ∀ r ∈ range L, Real.cos (2 * π * r * ((L * j : ℤ) : ℝ) / L) = 1 := by
      intro r _
      have : 2 * π * r * ((L * j : ℤ) : ℝ) / L = ((r * j : ℤ) : ℝ) * (2 * π) := by
        push_cast; field_simp
      rw [this, Real.cos_int_mul_two_pi]
    rw [Finset.sum_congr rfl this]
    simp [hL']
  · rw [comb_cos_sum_zero L hL i h, mul_zero]

/-- Padding with zeros makes copies: putting `L - 1` zeros after every sample of a tone of
amplitude `a` at `f` (sampled at `fs`) gives, at the padded rate `L fs`, the tone at `f` with
amplitude `a / L`, plus image tones at `r fs + f` and `r fs - f` with amplitude `a / (2L)` each,
for `r = 1, …, L - 1` (copy `r` and copy `L - r` land on the same frequencies, giving `a / L`). -/
theorem zero_padding_makes_images (a f fs : ℝ) (hfs : 0 < fs) (L : ℕ) (hL : 0 < L) (i : ℤ) :
    (if (L : ℤ) ∣ i then a * Real.sin (2 * π * f * ((i / L : ℤ) : ℝ) / fs) else 0) =
      a / L * Real.sin (2 * π * f * i / (L * fs)) +
        ∑ r ∈ Ico 1 L, a / (2 * L) *
          (Real.sin (2 * π * (r * fs + f) * i / (L * fs)) -
            Real.sin (2 * π * (r * fs - f) * i / (L * fs))) := by
  have hL' : (L : ℝ) ≠ 0 := by positivity
  have hfs' : fs ≠ 0 := hfs.ne'
  set B : ℝ := 2 * π * f * i / (L * fs) with hB
  have term : ∀ r : ℕ, a / (2 * L) *
      (Real.sin (2 * π * (r * fs + f) * i / (L * fs)) -
        Real.sin (2 * π * (r * fs - f) * i / (L * fs))) =
      a / L * Real.sin B * Real.cos (2 * π * r * i / L) := by
    intro r
    rw [Real.sin_sub_sin]
    have e1 : (2 * π * (r * fs + f) * i / (L * fs) - 2 * π * (r * fs - f) * i / (L * fs)) / 2 = B := by
      rw [hB]; field_simp; ring
    have e2 : (2 * π * (r * fs + f) * i / (L * fs) + 2 * π * (r * fs - f) * i / (L * fs)) / 2
        = 2 * π * r * i / L := by
      field_simp; ring
    rw [e1, e2]; field_simp
  simp only [term]
  rw [← Finset.mul_sum]
  have hsplit : ∑ r ∈ range L, Real.cos (2 * π * r * i / L) =
      1 + ∑ r ∈ Ico 1 L, Real.cos (2 * π * r * i / L) := by
    rw [Finset.range_eq_Ico, Finset.sum_eq_sum_Ico_succ_bot hL]
    simp
  have comb := comb_is_one_every_Lth_slot L hL i
  rw [hsplit] at comb
  have : a / L * Real.sin B + a / L * Real.sin B * ∑ r ∈ Ico 1 L, Real.cos (2 * π * r * i / L)
      = a * Real.sin B * ((1 / (L : ℝ)) * (1 + ∑ r ∈ Ico 1 L, Real.cos (2 * π * r * i / L))) := by
    ring
  rw [this, comb]
  split_ifs with h
  · obtain ⟨j, rfl⟩ := h
    have hL0 : (L : ℤ) ≠ 0 := by exact_mod_cast hL.ne'
    have hB2 : B = 2 * π * f * ((L * j / L : ℤ) : ℝ) / fs := by
      rw [Int.mul_ediv_cancel_left _ hL0, hB]; push_cast; field_simp
    rw [hB2, mul_one]
  · ring

/-! The card's whole-number worked examples. -/

-- 48 kHz to 44.1 kHz: gcd 300, so up by L = 147 and down by M = 160.
example : Nat.gcd 48000 44100 = 300 := by norm_num
example : 44100 / 300 = 147 ∧ 48000 / 300 = 160 := by norm_num
-- In-between rate, new Nyquist frequency, and where 23 kHz folds at 44.1 kHz.
example : 48000 * 147 = 7056000 ∧ 44100 / 2 = 22050 ∧ 44100 - 23000 = 21100 := by norm_num
example : |(23000 : ℝ) - 44100 * round ((23000 : ℝ) / 44100)| = 21100 := by
  have : round ((23000 : ℝ) / 44100) = 1 := by
    rw [round_eq, Int.floor_eq_iff]; norm_num
  rw [this]; norm_num [abs_of_neg]
-- Down by 3 to 16 kHz: 15 kHz folds to 1 kHz and 23 kHz folds to 7 kHz.
example : |(15000 : ℝ) - 16000 * round ((15000 : ℝ) / 16000)| = 1000 := by
  have : round ((15000 : ℝ) / 16000) = 1 := by
    rw [round_eq, Int.floor_eq_iff]; norm_num
  rw [this]; norm_num [abs_of_neg]
example : |(23000 : ℝ) - 16000 * round ((23000 : ℝ) / 16000)| = 7000 := by
  have : round ((23000 : ℝ) / 16000) = 1 := by
    rw [round_eq, Int.floor_eq_iff]; norm_num
  rw [this]; norm_num [abs_of_neg]
-- Filter length and cost: 129 × 147 taps, 129 per output, literal route 160 × 18,963.
example : 129 * 147 = 18963 ∧ 18963 / 147 = 129 ∧ 160 * 18963 = 3034080 := by norm_num
-- Down by 3 with 265 taps: 795 multiplies if every sample is filtered.
example : 3 * 265 = 795 := by norm_num
-- The time gap between output n (at 44.1 kHz) and input k (at 48 kHz),
-- in ticks of 1/7,056,000 s, is exactly n M - k L.
example (n k : ℤ) : ((n : ℚ) / 44100 - k / 48000) * 7056000 = n * 160 - k * 147 := by ring

#print axioms comb_cos_sum_zero
#print axioms decimation_folds_tone
#print axioms comb_is_one_every_Lth_slot
#print axioms zero_padding_makes_images
