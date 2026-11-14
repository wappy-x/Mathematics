-- Root locus: a point is a closed-loop pole at positive gain K exactly when the angle condition holds and K equals the distance ratio, a breakaway point makes D'N - DN' vanish, and the heated room's poles reach the imaginary axis only at gain 63/5 = 12.6.
import Mathlib.Analysis.SpecialFunctions.Complex.Arg
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Complex
import Mathlib.Algebra.Polynomial.Derivative
import Mathlib.Algebra.BigOperators.Fin

open Complex Polynomial

lemma root_locus_prod_polar {ι : Type*} (t : Finset ι) (f : ι → ℂ) :
    ∏ i ∈ t, f i = ((∏ i ∈ t, ‖f i‖ : ℝ) : ℂ) * exp ((∑ i ∈ t, arg (f i) : ℝ) * I) := by
  conv_lhs => rw [← Finset.prod_congr rfl (fun i _ => norm_mul_exp_arg_mul_I (f i))]
  rw [Finset.prod_mul_distrib]
  push_cast
  rw [Finset.sum_mul, Complex.exp_sum]
#print axioms root_locus_prod_polar

/-- Evans's angle and size conditions. Write the loop gain as `K · N(s)/D(s)` with
`N(s) = b ∏ (s - z_k)` (the `m` open-loop zeros) and `D(s) = a ∏ (s - p_i)` (the `n` open-loop poles),
where the leading coefficients have `a / b > 0`. For a positive gain `K` and a point `s` that is not
a zero, `s` is a closed-loop pole, `D(s) + K N(s) = 0`, exactly when the angles from the zeros minus
the angles from the poles make an odd number of half turns, and `K = (a/b) ∏ |s - p_i| / ∏ |s - z_k|`. -/
theorem closed_loop_pole_iff_angle_and_size {m n : ℕ} (a b : ℝ) (hab : 0 < a / b)
    (z : Fin m → ℂ) (p : Fin n → ℂ) (s : ℂ) (hs : ∀ k, s ≠ z k) (K : ℝ) (hK : 0 < K) :
    (a : ℂ) * ∏ i, (s - p i) + (K : ℂ) * ((b : ℂ) * ∏ k, (s - z k)) = 0 ↔
      (∃ q : ℤ, ∑ k, arg (s - z k) - ∑ i, arg (s - p i) = (2 * q + 1) * Real.pi) ∧
        K = a / b * (∏ i, ‖s - p i‖) / ∏ k, ‖s - z k‖ := by
  have hb : b ≠ 0 := by rintro rfl; simp at hab
  have ha : a ≠ 0 := by rintro rfl; simp at hab
  set rP := ∏ i, ‖s - p i‖ with hrP
  set rZ := ∏ k, ‖s - z k‖ with hrZ
  set α := ∑ i, arg (s - p i) with hα
  set β := ∑ k, arg (s - z k) with hβ
  have hrP0 : 0 ≤ rP := Finset.prod_nonneg (fun i _ => norm_nonneg _)
  have hrZ0 : 0 < rZ := Finset.prod_pos (fun k _ => norm_pos_iff.mpr (sub_ne_zero.mpr (hs k)))
  have hP : ∏ i, (s - p i) = (rP : ℂ) * exp (α * I) := root_locus_prod_polar _ _
  have hZ : ∏ k, (s - z k) = (rZ : ℂ) * exp (β * I) := root_locus_prod_polar _ _
  set θ := β - α with hθ
  have hβ' : (β : ℂ) * I = α * I + θ * I := by rw [hθ]; push_cast; ring
  have key : (a : ℂ) * ∏ i, (s - p i) + (K : ℂ) * ((b : ℂ) * ∏ k, (s - z k)) =
      exp (α * I) * (((a * rP + K * b * rZ * Real.cos θ : ℝ) : ℂ) +
        ((K * b * rZ * Real.sin θ : ℝ) : ℂ) * I) := by
    rw [hP, hZ, hβ', Complex.exp_add]
    rw [Complex.exp_mul_I (θ : ℂ)]
    push_cast
    ring
  rw [key, mul_eq_zero, or_iff_right (Complex.exp_ne_zero _)]
  rw [Complex.ext_iff]
  simp only [add_re, ofReal_re, mul_re, I_re, mul_zero, ofReal_im, I_im, mul_one, sub_self,
    add_zero, zero_re, add_im, mul_im, zero_add, zero_im]
  have hKb : K * b ≠ 0 := mul_ne_zero hK.ne' hb
  constructor
  · rintro ⟨h1, h2⟩
    have hs0 : Real.sin θ = 0 := by
      rcases mul_eq_zero.mp h2 with h | h
      · exact absurd h (mul_ne_zero hKb hrZ0.ne')
      · exact h
    have hc : Real.cos θ = 1 ∨ Real.cos θ = -1 := by
      have := Real.sin_sq_add_cos_sq θ
      rw [hs0] at this
      exact sq_eq_one_iff.mp (by linarith)
    rcases hc with hc | hc
    · exfalso
      rw [hc] at h1
      have : a / b * rP + K * rZ = 0 := by
        field_simp
        linarith
      have : 0 ≤ a / b * rP := mul_nonneg hab.le hrP0
      have : 0 < K * rZ := mul_pos hK hrZ0
      linarith
    · refine ⟨?_, ?_⟩
      · obtain ⟨k, hk⟩ := Real.cos_eq_neg_one_iff.mp hc
        exact ⟨k, by rw [← hk]; ring⟩
      · rw [hc] at h1
        field_simp
        linarith
  · rintro ⟨⟨q, hq⟩, hKv⟩
    have hc : Real.cos θ = -1 := Real.cos_eq_neg_one_iff.mpr ⟨q, by rw [hq]; ring⟩
    have hs0 : Real.sin θ = 0 := by
      have := Real.sin_sq_add_cos_sq θ
      rw [hc] at this
      nlinarith [sq_nonneg (Real.sin θ)]
    refine ⟨?_, by rw [hs0]; ring⟩
    rw [hc, hKv]
    field_simp
    ring

/-- Breakaway rule. If at gain `K` the closed-loop polynomial `D + K N` has a double root `s₀`,
then `D'(s₀) N(s₀) - D(s₀) N'(s₀) = 0`: the numerator of `d(-D/N)/ds` vanishes there, so the
breakaway is a stationary point of the gain read along the axis. -/
theorem breakaway_double_root_stationary (D N : ℂ[X]) (K : ℝ) (s₀ : ℂ)
    (hdouble : (X - C s₀) ^ 2 ∣ D + C (K : ℂ) * N) :
    (derivative D).eval s₀ * N.eval s₀ - D.eval s₀ * (derivative N).eval s₀ = 0 := by
  obtain ⟨G, hG⟩ := hdouble
  have h0 := congrArg (eval s₀) hG
  have h1 := congrArg (fun F => eval s₀ (derivative F)) hG
  simp only [eval_add, eval_mul, eval_C, eval_pow, eval_sub, eval_X, sub_self] at h0
  simp only [derivative_add, derivative_mul, derivative_C, zero_mul, zero_add, derivative_pow,
    derivative_sub, derivative_X, sub_zero, eval_add, eval_mul, eval_C, eval_pow, eval_sub,
    eval_X, sub_self, eval_one] at h1
  have hD : D.eval s₀ = -(K : ℂ) * N.eval s₀ := by
    linear_combination h0
  have hD' : (derivative D).eval s₀ = -(K : ℂ) * (derivative N).eval s₀ := by
    linear_combination h1
  rw [hD, hD']
  ring

/-- The heated room's crossing. For a positive loop gain `K`, the closed-loop polynomial
`80 s³ + 68 s² + 16 s + (1 + K)` has a root `s = jω` on the imaginary axis exactly when `K = 12.6`. -/
theorem room_crossing_gain (K : ℝ) (hK : 0 < K) :
    (∃ ω : ℝ, 80 * ((ω : ℂ) * I) ^ 3 + 68 * ((ω : ℂ) * I) ^ 2 + 16 * ((ω : ℂ) * I) + (1 + K) = 0) ↔
      K = 63 / 5 := by
  have expand : ∀ ω : ℝ, 80 * ((ω : ℂ) * I) ^ 3 + 68 * ((ω : ℂ) * I) ^ 2 + 16 * ((ω : ℂ) * I)
      + (1 + K) = ((1 + K - 68 * ω ^ 2 : ℝ) : ℂ) + ((16 * ω - 80 * ω ^ 3 : ℝ) : ℂ) * I := by
    intro ω
    push_cast
    ring_nf
    rw [I_sq, show I ^ 3 = I ^ 2 * I by ring, I_sq]
    ring
  constructor
  · rintro ⟨ω, hω⟩
    rw [expand, Complex.ext_iff] at hω
    simp only [add_re, ofReal_re, mul_re, I_re, mul_zero, ofReal_im, I_im, mul_one, sub_self,
      add_zero, zero_re, add_im, mul_im, zero_add, zero_im] at hω
    obtain ⟨h1, h2⟩ := hω
    have hw : ω ≠ 0 := by
      rintro rfl
      linarith
    have : ω ^ 2 = 1 / 5 := by
      have : ω * (16 - 80 * ω ^ 2) = 0 := by linarith
      rcases mul_eq_zero.mp this with h | h
      · exact absurd h hw
      · linarith
    linarith
  · rintro rfl
    refine ⟨Real.sqrt (1 / 5), ?_⟩
    have hs : Real.sqrt (1 / 5) ^ 2 = 1 / 5 := Real.sq_sqrt (by norm_num)
    rw [expand]
    have e1 : (1 + 63 / 5 - 68 * Real.sqrt (1 / 5) ^ 2 : ℝ) = 0 := by rw [hs]; norm_num
    have e2 : (16 * Real.sqrt (1 / 5) - 80 * Real.sqrt (1 / 5) ^ 3 : ℝ) = 0 := by
      rw [show Real.sqrt (1 / 5) ^ 3 = Real.sqrt (1 / 5) ^ 2 * Real.sqrt (1 / 5) by ring, hs]
      ring
    rw [e1, e2]
    simp

-- The room's open-loop polynomial: (2s + 1)(4s + 1)(10s + 1) = 80 s³ + 68 s² + 16 s + 1.
example (s : ℚ) : (2 * s + 1) * (4 * s + 1) * (10 * s + 1) = 80 * s ^ 3 + 68 * s ^ 2 + 16 * s + 1 := by
  ring

-- The centroid of the open-loop poles −1/2, −1/4, −1/10 is −17/60 ≈ −0.2833.
example : ((-1 / 2 : ℚ) + (-1 / 4) + (-1 / 10)) / 3 = -17 / 60 := by norm_num

-- D'(s) = 240 s² + 136 s + 16 vanishes at −1/6 and at −2/5.
example : 240 * (-1 / 6 : ℚ) ^ 2 + 136 * (-1 / 6) + 16 = 0 ∧
    240 * (-2 / 5 : ℚ) ^ 2 + 136 * (-2 / 5) + 16 = 0 := by norm_num

-- The gain −D(s) is 4/27 ≈ 0.148148 at the breakaway −1/6, and −9/25 = −0.36 at −2/5 (off the locus).
example : -(80 * (-1 / 6 : ℚ) ^ 3 + 68 * (-1 / 6) ^ 2 + 16 * (-1 / 6) + 1) = 4 / 27 ∧
    -(80 * (-2 / 5 : ℚ) ^ 3 + 68 * (-2 / 5) ^ 2 + 16 * (-2 / 5) + 1) = -9 / 25 := by norm_num

-- At gain 4/27 the pair meets at −1/6 and the third pole sits at −31/60 ≈ −0.5167.
example (s : ℚ) :
    80 * s ^ 3 + 68 * s ^ 2 + 16 * s + (1 + 4 / 27) = 80 * (s + 1 / 6) ^ 2 * (s + 31 / 60) := by
  ring

-- Crossing: with ω² = 16/80 = 1/5 both parts of (1 + K − 68ω²) + j(16ω − 80ω³) vanish at K = 63/5 = 12.6.
example : (1 + 63 / 5 - 68 * (1 / 5) : ℚ) = 0 ∧ (16 - 80 * (1 / 5) : ℚ) = 0 := by norm_num

-- ζ = 0.5: σ = 2/17, pair −σ ± jσ√3, third pole −209/340 ≈ −0.6147, gain K = 8463/4913 ≈ 1.7226.
example (s : ℚ) :
    80 * (s ^ 2 + 2 * (2 / 17) * s + 4 * (2 / 17) ^ 2) * (s + 209 / 340) =
      80 * s ^ 3 + 68 * s ^ 2 + 16 * s + (1 + 8463 / 4913) := by
  ring

#print axioms closed_loop_pole_iff_angle_and_size
#print axioms breakaway_double_root_stationary
#print axioms room_crossing_gain
