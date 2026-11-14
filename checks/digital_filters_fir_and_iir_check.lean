-- Digital filters: an FIR filter with symmetric weights has a pure linear phase (equal delay at every frequency), and the M-reading moving average has the gain |sin(Mω/2)/(M sin(ω/2))| and wipes out any sampled sine that fits whole cycles into M readings.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Complex.Circle
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Complex
import Mathlib.Analysis.SpecialFunctions.Complex.Log
import Mathlib.Algebra.BigOperators.Field

open Complex Finset

theorem exp_ofReal_mul_I_sub_one_eq (θ : ℝ) :
    Complex.exp ((θ : ℂ) * I) - 1 =
      Complex.exp (((θ / 2 : ℝ) : ℂ) * I) * (2 * I * Complex.sin ((θ / 2 : ℝ) : ℂ)) := by
  have h2 : (2 : ℂ) * Complex.sin ((θ / 2 : ℝ) : ℂ) =
      (Complex.exp (-((θ / 2 : ℝ) : ℂ) * I) - Complex.exp (((θ / 2 : ℝ) : ℂ) * I)) * I :=
    Complex.two_sin _
  have e1 : Complex.exp ((θ : ℂ) * I) =
      Complex.exp (((θ / 2 : ℝ) : ℂ) * I) * Complex.exp (((θ / 2 : ℝ) : ℂ) * I) := by
    rw [← Complex.exp_add]; congr 1; push_cast; ring
  have e2 : Complex.exp (((θ / 2 : ℝ) : ℂ) * I) * Complex.exp (-((θ / 2 : ℝ) : ℂ) * I) = 1 := by
    rw [← Complex.exp_add]; simp
  calc Complex.exp ((θ : ℂ) * I) - 1
      = Complex.exp (((θ / 2 : ℝ) : ℂ) * I) * Complex.exp (((θ / 2 : ℝ) : ℂ) * I)
        - Complex.exp (((θ / 2 : ℝ) : ℂ) * I) * Complex.exp (-((θ / 2 : ℝ) : ℂ) * I) := by
          rw [e1, e2]
    _ = Complex.exp (((θ / 2 : ℝ) : ℂ) * I) *
          ((Complex.exp (-((θ / 2 : ℝ) : ℂ) * I) - Complex.exp (((θ / 2 : ℝ) : ℂ) * I)) * I * I) := by
          rw [mul_assoc _ I I, Complex.I_mul_I]; ring
    _ = _ := by rw [← h2]; ring

theorem norm_exp_ofReal_mul_I_sub_one (θ : ℝ) :
    ‖Complex.exp ((θ : ℂ) * I) - 1‖ = 2 * |Real.sin (θ / 2)| := by
  rw [exp_ofReal_mul_I_sub_one_eq, norm_mul, Complex.norm_exp_ofReal_mul_I, norm_mul, norm_mul,
    ← Complex.ofReal_sin, Complex.norm_real, Complex.norm_I]
  simp

#print axioms exp_ofReal_mul_I_sub_one_eq
#print axioms norm_exp_ofReal_mul_I_sub_one

/-- An FIR filter whose real weights read the same forwards and backwards,
`b k = b (M - 1 - k)`, has frequency response
`H(e^{jω}) = Σ b_k e^{-jωk} = e^{-jω(M-1)/2} × (a real number)`, the real number being
`Σ b_k cos(ω((M-1)/2 - k))`. So its phase is the straight line `-ω(M-1)/2`:
a pure delay of `(M-1)/2` readings at every frequency. -/
theorem symmetric_fir_linear_phase (M : ℕ) (b : ℕ → ℝ)
    (hb : ∀ k, k < M → b k = b (M - 1 - k)) (ω : ℝ) :
    ∑ k ∈ range M, (b k : ℂ) * Complex.exp (-((ω : ℂ) * k) * I) =
      Complex.exp (-((ω : ℂ) * (((M : ℂ) - 1) / 2)) * I) *
        ((∑ k ∈ range M, b k * Real.cos (ω * (((M : ℝ) - 1) / 2 - k)) : ℝ) : ℂ) := by
  set S := ∑ k ∈ range M, (b k : ℂ) * Complex.exp (-((ω : ℂ) * k) * I) with hS
  have hrefl : ∑ k ∈ range M, (b k : ℂ) * Complex.exp (-((ω : ℂ) * ((M : ℂ) - 1 - k)) * I) = S := by
    rw [hS, ← Finset.sum_range_reflect]
    apply Finset.sum_congr rfl
    intro k hk
    have hk' : k < M := Finset.mem_range.mp hk
    rw [← hb k hk']
    congr 3
    rw [Nat.cast_sub (by omega), Nat.cast_sub (by omega)]
    push_cast; ring
  have hterm : ∀ k ∈ range M,
      Complex.exp (-((ω : ℂ) * (((M : ℂ) - 1) / 2)) * I) *
        (((b k * Real.cos (ω * (((M : ℝ) - 1) / 2 - k)) : ℝ)) : ℂ) =
      ((b k : ℂ) * Complex.exp (-((ω : ℂ) * k) * I) +
        (b k : ℂ) * Complex.exp (-((ω : ℂ) * ((M : ℂ) - 1 - k)) * I)) / 2 := by
    intro k _
    have hc := Complex.two_cos ((ω : ℂ) * (((M : ℂ) - 1) / 2 - k))
    push_cast
    have : Complex.cos ((ω : ℂ) * (((M : ℂ) - 1) / 2 - k)) =
        (Complex.exp ((ω : ℂ) * (((M : ℂ) - 1) / 2 - k) * I) +
          Complex.exp (-((ω : ℂ) * (((M : ℂ) - 1) / 2 - k)) * I)) / 2 := by
      rw [← hc]; ring
    rw [this]
    have ea : Complex.exp (-((ω : ℂ) * (((M : ℂ) - 1) / 2)) * I) *
        Complex.exp ((ω : ℂ) * (((M : ℂ) - 1) / 2 - k) * I) =
        Complex.exp (-((ω : ℂ) * k) * I) := by
      rw [← Complex.exp_add]; congr 1; ring
    have eb : Complex.exp (-((ω : ℂ) * (((M : ℂ) - 1) / 2)) * I) *
        Complex.exp (-((ω : ℂ) * (((M : ℂ) - 1) / 2 - k)) * I) =
        Complex.exp (-((ω : ℂ) * ((M : ℂ) - 1 - k)) * I) := by
      rw [← Complex.exp_add]; congr 1; ring
    linear_combination (b k : ℂ) / 2 * ea + (b k : ℂ) / 2 * eb
  rw [Complex.ofReal_sum, Finset.mul_sum, Finset.sum_congr rfl hterm, ← Finset.sum_div,
    Finset.sum_add_distrib, hrefl]
  ring

/-- The gain of the M-reading moving average, `b_k = 1/M`, at angle `ω` per reading is
`|sin(Mω/2) / (M sin(ω/2))|` (wherever `sin(ω/2) ≠ 0`, so the ratio is defined). -/
theorem moving_average_gain (M : ℕ) (hM : 0 < M) (ω : ℝ) (hω : Real.sin (ω / 2) ≠ 0) :
    ‖(1 / (M : ℂ)) * ∑ k ∈ range M, Complex.exp (-((ω : ℂ) * k) * I)‖ =
      |Real.sin (M * ω / 2) / (M * Real.sin (ω / 2))| := by
  set z := Complex.exp (((-ω : ℝ) : ℂ) * I) with hz
  have hpow : ∀ k : ℕ, Complex.exp (-((ω : ℂ) * k) * I) = z ^ k := by
    intro k
    rw [hz, ← Complex.exp_nat_mul]; congr 1; push_cast; ring
  have hzM : z ^ M = Complex.exp (((-(M * ω) : ℝ) : ℂ) * I) := by
    rw [hz, ← Complex.exp_nat_mul]; congr 1; push_cast; ring
  have hz1n : ‖z - 1‖ = 2 * |Real.sin (ω / 2)| := by
    rw [hz, norm_exp_ofReal_mul_I_sub_one, neg_div, Real.sin_neg, abs_neg]
  have hz1 : z ≠ 1 := by
    intro h
    rw [h, sub_self, norm_zero] at hz1n
    have : |Real.sin (ω / 2)| ≠ 0 := abs_ne_zero.mpr hω
    apply this; linarith
  simp_rw [hpow]
  rw [geom_sum_eq hz1, hzM, norm_mul, norm_div, norm_div, norm_exp_ofReal_mul_I_sub_one, hz1n]
  rw [show -(↑M * ω) / 2 = -(↑M * ω / 2) by ring, Real.sin_neg, abs_neg]
  have hMpos : (0 : ℝ) < M := by exact_mod_cast hM
  rw [abs_div, abs_mul, abs_of_pos hMpos]
  rw [norm_one]
  simp only [Complex.norm_natCast]
  have : |Real.sin (ω / 2)| ≠ 0 := abs_ne_zero.mpr hω
  field_simp

/-- The moving average over M readings removes a sampled sine that makes a whole number `m`
of cycles in those M readings (any `m` that is not a multiple of M, so not a constant):
the sum over the last M readings is zero at every reading `n`, whatever the phase `φ`. -/
theorem moving_average_cancels_whole_cycle_sine (M : ℕ) (m : ℤ) (hm : ¬ (M : ℤ) ∣ m)
    (φ : ℝ) (n : ℤ) :
    ∑ k ∈ range M, Real.sin (2 * Real.pi * m * ((n : ℝ) - k) / M + φ) = 0 := by
  rcases Nat.eq_zero_or_pos M with h0 | hMpos
  · subst h0; simp
  have hM0 : (M : ℂ) ≠ 0 := by exact_mod_cast hMpos.ne'
  set ζ := Complex.exp (-(2 * (Real.pi : ℂ) * m / M) * I) with hζ
  set a : ℝ := 2 * Real.pi * m * n / M + φ with ha
  have hterm : ∀ k ∈ range M, Real.sin (2 * Real.pi * m * ((n : ℝ) - k) / M + φ) =
      (Complex.exp ((a : ℂ) * I) * ζ ^ k).im := by
    intro k _
    rw [← Complex.exp_ofReal_mul_I_im, hζ, ← Complex.exp_nat_mul, ← Complex.exp_add]
    congr 2
    rw [ha]; push_cast; field_simp; ring
  have hζM : ζ ^ M = 1 := by
    rw [hζ, ← Complex.exp_nat_mul]
    have : (M : ℂ) * (-(2 * (Real.pi : ℂ) * m / M) * I) = ((-m : ℤ) : ℂ) * (2 * Real.pi * I) := by
      push_cast; field_simp
    rw [this, Complex.exp_int_mul_two_pi_mul_I]
  have hζ1 : ζ ≠ 1 := by
    intro h
    rw [hζ, Complex.exp_eq_one_iff] at h
    obtain ⟨j, hj⟩ := h
    apply hm
    refine ⟨-j, ?_⟩
    have hpi : (Real.pi : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
    have : (m : ℂ) = (M : ℂ) * ((-j : ℤ) : ℂ) := by
      field_simp at hj
      push_cast
      linear_combination (-1 : ℂ) * hj
    exact_mod_cast this
  rw [Finset.sum_congr rfl hterm, ← Complex.im_sum, ← Finset.mul_sum, geom_sum_eq hζ1, hζM]
  simp

-- The average's length: 500 readings a second over 50 cycles a second is 10 readings.
example : 500 / 50 = 10 ∧ 500 % 50 = 0 := by decide
-- On 60 Hz mains at the same rate, 500/60 is not whole.
example : 500 % 60 ≠ 0 := by decide
-- The Butterworth's top is (1 + z⁻¹)^5: weights 1, 5, 10, 10, 5, 1.
example : (List.range 6).map (Nat.choose 5) = [1, 5, 10, 10, 5, 1] := by decide
-- The notches sit at k·fs/M: 50, 100, 150, 200 and 250 Hz.
example : (List.range' 1 5).map (fun k => k * 500 / 10) = [50, 100, 150, 200, 250] := by decide

#print axioms symmetric_fir_linear_phase
#print axioms moving_average_gain
#print axioms moving_average_cancels_whole_cycle_sine
