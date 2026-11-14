-- Nyquist and margins: scaling the loop by the gain margin, or delaying it by the delay margin, puts a closed-loop pole on the imaginary axis, and the delayed loop gain fades on the far half-circle.
import Mathlib.Analysis.SpecialFunctions.Complex.Arg
import Mathlib.Analysis.SpecialFunctions.Complex.Log

open Complex Real

/-- Gain margin. At the phase crossover the loop's answer `L(jω)` lies on the negative real axis
(phase −180°). Multiplying the loop by a real factor `c` makes `1 + c·L(jω) = 0`, a closed-loop pole
at `jω`, exactly when `c = 1 / |L(jω)|`, the gain margin. -/
theorem gain_margin_puts_crossing_on_minus_one (L : ℂ → ℂ) (ω : ℝ)
    (hpc : (L (ω * I)).arg = π) (c : ℝ) :
    1 + (c : ℂ) * L (ω * I) = 0 ↔ c = 1 / ‖L (ω * I)‖ := by
  obtain ⟨hre, him⟩ := arg_eq_pi_iff.mp hpc
  have hz' : L (ω * I) = ((L (ω * I)).re : ℂ) := by
    apply Complex.ext <;> simp [him]
  generalize (L (ω * I)).re = r at hz' hre
  rw [hz', Complex.norm_real, Real.norm_eq_abs, abs_of_neg hre]
  have hne : r ≠ 0 := hre.ne
  constructor
  · intro h
    have h2 : (1 + c * r : ℝ) = 0 := by exact_mod_cast h
    field_simp
    linarith
  · intro h
    rw [h]
    have hne' : (r : ℂ) ≠ 0 := by exact_mod_cast hne
    push_cast
    field_simp
    ring

/-- Phase and delay margin. An extra delay `Δ` multiplies `L(jω)` by `e^{-jωΔ}`, which has size 1,
so it only turns the point. At the gain crossover, where `L(jω) = e^{jφ}` has size 1 and unwrapped
phase `φ`, the phase margin is `PM = π + φ`, and the delay `Δ = PM / ω` puts a closed-loop pole at
`jω`: `1 + e^{-jωΔ} L(jω) = 0`. -/
theorem delay_margin_puts_pole_on_axis (L : ℂ → ℂ) (ω φ : ℝ) (hω : ω ≠ 0)
    (hgc : L (ω * I) = exp (φ * I)) :
    (∀ Δ : ℝ, ‖exp (-((Δ : ℂ) * (ω * I)))‖ = 1) ∧
      1 + exp (-((((π + φ) / ω : ℝ) : ℂ) * (ω * I))) * L (ω * I) = 0 := by
  refine ⟨fun Δ => ?_, ?_⟩
  · rw [Complex.norm_exp]; simp
  · rw [hgc, ← Complex.exp_add]
    have hω' : (ω : ℂ) ≠ 0 := by exact_mod_cast hω
    have : -((((π + φ) / ω : ℝ) : ℂ) * (ω * I)) + φ * I = -(π * I) := by
      push_cast
      field_simp
      ring
    rw [this, Complex.exp_neg_pi_mul_I]; ring

/-- The half-circle adds nothing. For `L(s) = K e^{-θ s} / ((T₁ s + 1)(T₂ s + 1))` with two lags
`T₁, T₂ > 0` and a delay `θ ≥ 0`, there is a radius `R₀` beyond which `|L(s)| < 1/2` everywhere in
the closed right half-plane; so `1 + L` has no zeros there and does not turn round 0 on the arc. -/
theorem loop_gain_small_on_far_right_half_plane (K T₁ T₂ θ : ℝ) (hT₁ : 0 < T₁) (hT₂ : 0 < T₂)
    (hθ : 0 ≤ θ) :
    ∃ R₀ : ℝ, ∀ s : ℂ, 0 ≤ s.re → R₀ < ‖s‖ →
      ‖(K : ℂ) * exp (-((θ : ℂ) * s)) / (((T₁ : ℂ) * s + 1) * ((T₂ : ℂ) * s + 1))‖ < 1 / 2 := by
  refine ⟨(2 + 2 * |K|) / T₁ + 2 / T₂, fun s hs hR => ?_⟩
  have hK : 0 ≤ |K| := abs_nonneg K
  have h1 : (2 + 2 * |K|) / T₁ < ‖s‖ := by
    have : 0 < 2 / T₂ := by positivity
    linarith
  have h2 : 2 / T₂ < ‖s‖ := by
    have : 0 < (2 + 2 * |K|) / T₁ := by positivity
    linarith
  have a1 : 2 + 2 * |K| < T₁ * ‖s‖ := by rw [div_lt_iff₀ hT₁] at h1; linarith
  have a2 : 2 < T₂ * ‖s‖ := by rw [div_lt_iff₀ hT₂] at h2; linarith
  have b1 : T₁ * ‖s‖ - 1 ≤ ‖(T₁ : ℂ) * s + 1‖ := by
    have hn : ‖(T₁ : ℂ) * s‖ = T₁ * ‖s‖ := by
      rw [norm_mul, Complex.norm_real, Real.norm_eq_abs, abs_of_pos hT₁]
    have := norm_sub_norm_le ((T₁ : ℂ) * s) (-1)
    simp only [sub_neg_eq_add, norm_neg, norm_one, hn] at this
    linarith
  have b2 : T₂ * ‖s‖ - 1 ≤ ‖(T₂ : ℂ) * s + 1‖ := by
    have hn : ‖(T₂ : ℂ) * s‖ = T₂ * ‖s‖ := by
      rw [norm_mul, Complex.norm_real, Real.norm_eq_abs, abs_of_pos hT₂]
    have := norm_sub_norm_le ((T₂ : ℂ) * s) (-1)
    simp only [sub_neg_eq_add, norm_neg, norm_one, hn] at this
    linarith
  have he : ‖exp (-((θ : ℂ) * s))‖ ≤ 1 := by
    rw [Complex.norm_exp]
    apply Real.exp_le_one_iff.mpr
    simp only [neg_re, mul_re, ofReal_re, ofReal_im, zero_mul, sub_zero]
    nlinarith
  have hd : 2 * |K| < ‖(T₁ : ℂ) * s + 1‖ * ‖(T₂ : ℂ) * s + 1‖ := by
    have p1 : 1 + 2 * |K| < ‖(T₁ : ℂ) * s + 1‖ := by linarith
    have p2 : 1 < ‖(T₂ : ℂ) * s + 1‖ := by linarith
    nlinarith
  have hdpos : 0 < ‖(T₁ : ℂ) * s + 1‖ * ‖(T₂ : ℂ) * s + 1‖ := by linarith
  rw [norm_div, norm_mul, norm_mul, Complex.norm_real, Real.norm_eq_abs, div_lt_iff₀ (by
    rw [← norm_mul]; rw [norm_mul]; exact hdpos)]
  have : |K| * ‖exp (-((θ : ℂ) * s))‖ ≤ |K| := by
    calc |K| * ‖exp (-((θ : ℂ) * s))‖ ≤ |K| * 1 := by gcongr
      _ = |K| := mul_one _
  nlinarith

-- The loop's steady gain: 0.4 °C per % times 16 % per °C is 6.4, written in tenths.
example : (4 : ℚ) / 10 * 16 = 64 / 10 := by norm_num

-- A 10 °C setpoint step asks this thermostat for 160 % open.
example : (16 : ℕ) * 10 = 160 := by norm_num

-- The reactor `L(s) = 2/(s - 1)`: its only closed-loop pole is at `s = -1`.
example (s : ℂ) (hs : s ≠ 1) : 1 + 2 / (s - 1) = 0 ↔ s = -1 := by
  have h : s - 1 ≠ 0 := sub_ne_zero.mpr hs
  rw [show (1 : ℂ) + 2 / (s - 1) = (s + 1) / (s - 1) by field_simp; ring, div_eq_zero_iff]
  constructor
  · rintro (h1 | h1)
    · linear_combination h1
    · exact absurd h1 h
  · intro h1; left; rw [h1]; ring

-- The reactor's curve `L(jω)` is a circle of radius 1 round −1.
example (ω : ℝ) : ‖2 / ((ω : ℂ) * I - 1) - (-1)‖ = 1 := by
  have h : (ω : ℂ) * I - 1 ≠ 0 := by
    intro h0
    have := congrArg Complex.re h0
    simp at this
  rw [show 2 / ((ω : ℂ) * I - 1) - (-1) = ((ω : ℂ) * I + 1) / ((ω : ℂ) * I - 1) by
    field_simp; ring, norm_div]
  rw [div_eq_one_iff_eq (norm_ne_zero_iff.mpr h)]
  rw [Complex.norm_def, Complex.norm_def]
  congr 1
  simp [Complex.normSq_apply]

#print axioms gain_margin_puts_crossing_on_minus_one
#print axioms delay_margin_puts_pole_on_axis
#print axioms loop_gain_small_on_far_right_half_plane
