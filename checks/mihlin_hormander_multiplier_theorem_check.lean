-- Fourier multipliers: a gain that passes the size part of the Mihlin-Hörmander test keeps every signal's energy within that bound in any dimension, the octave equaliser 1 + ½cos(2π log₂|ξ|) has Mihlin constant exactly π/ln 2, and the plane gain ξ₁²/|ξ|² has Mihlin constant exactly 2.
import Mathlib.Analysis.Fourier.LpSpace
import Mathlib.MeasureTheory.Measure.Haar.InnerProductSpace
import Mathlib.Analysis.SpecialFunctions.Log.Base
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open MeasureTheory FourierTransform Real

/-- The energy case (p = 2) of the Mihlin-Hörmander theorem, in every dimension `d ≥ 1`.
If the gain `m` obeys the size part of the test, `|m(ξ)| ≤ A` at every frequency `ξ ≠ 0`,
and the filter turns the finite-energy signal `f` into `T_m f` by multiplying its Fourier
transform by `m(ξ)` frequency by frequency, then `‖T_m f‖₂ ≤ A ‖f‖₂`. -/
theorem mihlin_test_bounds_energy (d : ℕ) (hd : 1 ≤ d)
    (m : EuclideanSpace ℝ (Fin d) → ℂ) (A : ℝ)
    (hm : ∀ ξ : EuclideanSpace ℝ (Fin d), ξ ≠ 0 → ‖m ξ‖ ≤ A)
    (f Tf : Lp (α := EuclideanSpace ℝ (Fin d)) ℂ 2)
    (hT : ((𝓕 Tf : Lp (α := EuclideanSpace ℝ (Fin d)) ℂ 2) : EuclideanSpace ℝ (Fin d) → ℂ)
      =ᵐ[volume] fun ξ => m ξ * ((𝓕 f : Lp (α := EuclideanSpace ℝ (Fin d)) ℂ 2) :
        EuclideanSpace ℝ (Fin d) → ℂ) ξ) :
    ‖Tf‖ ≤ A * ‖f‖ := by
  have : Nonempty (Fin d) := ⟨⟨0, hd⟩⟩
  rw [← Lp.norm_fourier_eq Tf, ← Lp.norm_fourier_eq f]
  apply Lp.norm_le_mul_norm_of_ae_le_mul
  filter_upwards [hT, Measure.ae_ne volume (0 : EuclideanSpace ℝ (Fin d))] with ξ h1 h2
  rw [h1, norm_mul]
  exact mul_le_mul_of_nonneg_right (hm ξ h2) (norm_nonneg _)

theorem equaliser_hasDerivAt (ξ : ℝ) (hξ : ξ ≠ 0) :
    HasDerivAt (fun ξ : ℝ => 1 + (1 / 2) * Real.cos (2 * π * Real.logb 2 |ξ|))
      (-(π * Real.sin (2 * π * Real.logb 2 ξ) / (ξ * Real.log 2))) ξ := by
  have hfun : (fun ξ : ℝ => 1 + (1 / 2) * Real.cos (2 * π * Real.logb 2 |ξ|)) =
      fun ξ : ℝ => 1 + (1 / 2) * Real.cos (2 * π * (Real.log ξ / Real.log 2)) := by
    funext x; rw [Real.logb_abs]; rfl
  rw [hfun]
  have h := ((((Real.hasDerivAt_log hξ).div_const (Real.log 2)).const_mul (2 * π)).cos.const_mul
    (1 / 2 : ℝ)).const_add 1
  convert h using 1
  have hl : Real.log 2 ≠ 0 := (Real.log_pos one_lt_two).ne'
  simp only [Real.logb]
  field_simp

/-- The equaliser's Mihlin constant is `π / ln 2`. The gain
`m(ξ) = 1 + ½ cos(2π log₂ |ξ|)` repeats every octave, `m(2ξ) = m(ξ)`; at every `ξ ≠ 0` its size
is at most `3/2` and its slope per unit of natural log, `ξ m'(ξ)`, is at most `π / ln 2` in size;
both bounds are reached (at the band centre `ξ = 1` and at `ξ = 2^(1/4)`), and `3/2 < π / ln 2`,
so the larger, `π / ln 2`, is the smallest constant that passes the test on the line. -/
theorem equaliser_mihlin_constant :
    let m : ℝ → ℝ := fun ξ => 1 + (1 / 2) * Real.cos (2 * π * Real.logb 2 |ξ|)
    (∀ ξ : ℝ, ξ ≠ 0 → m (2 * ξ) = m ξ) ∧
    (∀ ξ : ℝ, ξ ≠ 0 → |m ξ| ≤ 3 / 2) ∧
    (∀ ξ : ℝ, ξ ≠ 0 → |ξ * deriv m ξ| ≤ π / Real.log 2) ∧
    m 1 = 3 / 2 ∧
    |(2 : ℝ) ^ ((1 : ℝ) / 4) * deriv m ((2 : ℝ) ^ ((1 : ℝ) / 4))| = π / Real.log 2 ∧
    3 / 2 < π / Real.log 2 := by
  intro m
  have hl : 0 < Real.log 2 := Real.log_pos one_lt_two
  have hxd : ∀ ξ : ℝ, ξ ≠ 0 → ξ * deriv m ξ = -(π * Real.sin (2 * π * Real.logb 2 ξ) / Real.log 2) := by
    intro ξ hξ
    rw [(equaliser_hasDerivAt ξ hξ).deriv]
    field_simp
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩
  · intro ξ hξ
    simp only [m]
    rw [abs_mul, Real.logb_mul (by norm_num) (abs_ne_zero.mpr hξ)]
    rw [show |(2:ℝ)| = 2 by norm_num, Real.logb_self_eq_one one_lt_two]
    rw [show 2 * π * (1 + Real.logb 2 |ξ|) = 2 * π * Real.logb 2 |ξ| + 2 * π by ring,
      Real.cos_add_two_pi]
  · intro ξ _
    simp only [m]
    have h1 := Real.cos_le_one (2 * π * Real.logb 2 |ξ|)
    have h2 := Real.neg_one_le_cos (2 * π * Real.logb 2 |ξ|)
    rw [abs_le]; constructor <;> linarith
  · intro ξ hξ
    rw [hxd ξ hξ, abs_neg, abs_div, abs_mul, abs_of_pos Real.pi_pos, abs_of_pos hl]
    apply div_le_div_of_nonneg_right _ hl.le
    have := Real.abs_sin_le_one (2 * π * Real.logb 2 ξ)
    nlinarith [Real.pi_pos]
  · simp [m]
    norm_num
  · have hpos : (0:ℝ) < 2 ^ ((1:ℝ)/4) := by positivity
    rw [hxd _ hpos.ne', Real.logb_rpow (by norm_num) (by norm_num)]
    rw [show 2 * π * (1 / 4) = π / 2 by ring, Real.sin_pi_div_two, mul_one, abs_neg,
      abs_div, abs_of_pos Real.pi_pos, abs_of_pos hl]
  · rw [lt_div_iff₀ hl]
    have := Real.log_lt_sub_one_of_pos (by norm_num : (0:ℝ) < 2) (by norm_num)
    nlinarith [Real.two_le_pi]

theorem riesz_hasDerivAt_sq (a : ℝ) : HasDerivAt (fun x : ℝ => x ^ 2) (2 * a) a := by
  simpa using hasDerivAt_pow 2 a

theorem riesz_hasDerivAt_x (a b : ℝ) (h : a ^ 2 + b ^ 2 ≠ 0) :
    HasDerivAt (fun x : ℝ => x ^ 2 / (x ^ 2 + b ^ 2)) (2 * a * b ^ 2 / (a ^ 2 + b ^ 2) ^ 2) a := by
  have := (riesz_hasDerivAt_sq a).div ((riesz_hasDerivAt_sq a).add_const (b ^ 2)) h
  convert this using 1
  field_simp
  ring

theorem riesz_hasDerivAt_y (a b : ℝ) (h : a ^ 2 + b ^ 2 ≠ 0) :
    HasDerivAt (fun y : ℝ => a ^ 2 / (a ^ 2 + y ^ 2)) (-2 * a ^ 2 * b / (a ^ 2 + b ^ 2) ^ 2) b := by
  have := (hasDerivAt_const b (a ^ 2)).div ((riesz_hasDerivAt_sq b).const_add (a ^ 2)) h
  convert this using 1
  field_simp
  ring

theorem riesz_hasDerivAt_xx (a b : ℝ) (h : a ^ 2 + b ^ 2 ≠ 0) :
    HasDerivAt (fun x : ℝ => 2 * x * b ^ 2 / (x ^ 2 + b ^ 2) ^ 2)
      (2 * b ^ 2 * (b ^ 2 - 3 * a ^ 2) / (a ^ 2 + b ^ 2) ^ 3) a := by
  have hn : HasDerivAt (fun x : ℝ => 2 * x * b ^ 2) (2 * b ^ 2) a := by
    simpa using ((hasDerivAt_id' a).const_mul 2).mul_const (b ^ 2)
  have := hn.div (((riesz_hasDerivAt_sq a).add_const (b ^ 2)).fun_pow 2) (pow_ne_zero 2 h)
  convert this using 1
  field_simp
  ring

theorem riesz_hasDerivAt_yy (a b : ℝ) (h : a ^ 2 + b ^ 2 ≠ 0) :
    HasDerivAt (fun y : ℝ => -2 * a ^ 2 * y / (a ^ 2 + y ^ 2) ^ 2)
      (-2 * a ^ 2 * (a ^ 2 - 3 * b ^ 2) / (a ^ 2 + b ^ 2) ^ 3) b := by
  have hn : HasDerivAt (fun y : ℝ => -2 * a ^ 2 * y) (-2 * a ^ 2 * 1) b :=
    (hasDerivAt_id' b).const_mul (-2 * a ^ 2)
  have := hn.div (((riesz_hasDerivAt_sq b).const_add (a ^ 2)).fun_pow 2) (pow_ne_zero 2 h)
  convert this using 1
  field_simp
  ring

theorem riesz_hasDerivAt_xy (a b : ℝ) (h : a ^ 2 + b ^ 2 ≠ 0) :
    HasDerivAt (fun y : ℝ => 2 * a * y ^ 2 / (a ^ 2 + y ^ 2) ^ 2)
      (4 * a * b * (a ^ 2 - b ^ 2) / (a ^ 2 + b ^ 2) ^ 3) b := by
  have hn : HasDerivAt (fun y : ℝ => 2 * a * y ^ 2) (2 * a * (2 * b)) b :=
    (riesz_hasDerivAt_sq b).const_mul (2 * a)
  have := hn.div (((riesz_hasDerivAt_sq b).const_add (a ^ 2)).fun_pow 2) (pow_ne_zero 2 h)
  convert this using 1
  field_simp
  ring

theorem riesz_first_bound (a b : ℝ) (hs : 0 < a ^ 2 + b ^ 2) :
    √(a ^ 2 + b ^ 2) * |2 * a * b ^ 2 / (a ^ 2 + b ^ 2) ^ 2| ≤ 4 / (3 * √3) := by
  rw [← pow_le_pow_iff_left₀ (by positivity) (by positivity) two_ne_zero, mul_pow,
    Real.sq_sqrt hs.le, sq_abs, div_pow, div_pow, mul_pow 3, Real.sq_sqrt (by norm_num : (0:ℝ) ≤ 3)]
  have e : (a ^ 2 + b ^ 2) * ((2 * a * b ^ 2) ^ 2 / ((a ^ 2 + b ^ 2) ^ 2) ^ 2)
      = 4 * a ^ 2 * b ^ 4 / (a ^ 2 + b ^ 2) ^ 3 := by
    field_simp
    ring
  rw [e, div_le_div_iff₀ (by positivity) (by norm_num)]
  nlinarith [mul_nonneg (sq_nonneg (b ^ 2 - 2 * a ^ 2)) (by positivity : (0:ℝ) ≤ a ^ 2 + 4 * b ^ 2)]

theorem riesz_second_bound (a b : ℝ) (hs : 0 < a ^ 2 + b ^ 2) :
    (a ^ 2 + b ^ 2) * |2 * b ^ 2 * (b ^ 2 - 3 * a ^ 2) / (a ^ 2 + b ^ 2) ^ 3| ≤ 2 := by
  rw [abs_div, abs_mul, abs_of_pos (by positivity : (0:ℝ) < (a ^ 2 + b ^ 2) ^ 3),
    abs_of_nonneg (by positivity : (0:ℝ) ≤ 2 * b ^ 2)]
  have e : (a ^ 2 + b ^ 2) * (2 * b ^ 2 * |b ^ 2 - 3 * a ^ 2| / (a ^ 2 + b ^ 2) ^ 3)
      = 2 * b ^ 2 * |b ^ 2 - 3 * a ^ 2| / (a ^ 2 + b ^ 2) ^ 2 := by
    field_simp
  rw [e, div_le_iff₀ (by positivity)]
  rcases abs_cases (b ^ 2 - 3 * a ^ 2) with ⟨h1, _⟩ | ⟨h1, _⟩ <;> rw [h1] <;>
    nlinarith [sq_nonneg a, sq_nonneg b, mul_nonneg (sq_nonneg a) (sq_nonneg b),
      sq_nonneg (a ^ 2 - b ^ 2), pow_two_nonneg (a ^ 2), pow_two_nonneg (b ^ 2)]

theorem riesz_mixed_bound (a b : ℝ) (hs : 0 < a ^ 2 + b ^ 2) :
    (a ^ 2 + b ^ 2) * |4 * a * b * (a ^ 2 - b ^ 2) / (a ^ 2 + b ^ 2) ^ 3| ≤ 1 := by
  rw [abs_div, abs_of_pos (by positivity : (0:ℝ) < (a ^ 2 + b ^ 2) ^ 3)]
  have e : (a ^ 2 + b ^ 2) * (|4 * a * b * (a ^ 2 - b ^ 2)| / (a ^ 2 + b ^ 2) ^ 3)
      = |4 * a * b * (a ^ 2 - b ^ 2)| / (a ^ 2 + b ^ 2) ^ 2 := by
    field_simp
  rw [e, div_le_iff₀ (by positivity), one_mul, abs_le]
  constructor <;> nlinarith [sq_nonneg (2 * a * b - (a ^ 2 - b ^ 2)),
    sq_nonneg (2 * a * b + (a ^ 2 - b ^ 2))]

/-- The plane gain `m(ξ₁, ξ₂) = ξ₁² / (ξ₁² + ξ₂²)`, which is `-R₁²`, passes the test with two
derivatives and Mihlin constant exactly `2`. At every `ξ ≠ 0`: `|m| ≤ 1`;
`|ξ| |∂₁m|` and `|ξ| |∂₂m|` are at most `4/(3√3)`; `|ξ|² |∂₁²m|` and `|ξ|² |∂₂²m|` are at most
`2`; and `|ξ|² |∂₁∂₂m|` is at most `1`. The value `4/(3√3)` is reached at `ξ = (1, √2)` and
the value `2` at `ξ = (0, 1)`. Partial derivatives are derivatives of one-variable slices. -/
theorem riesz_square_mihlin_constant :
    (∀ a b : ℝ, (a, b) ≠ (0, 0) →
      |a ^ 2 / (a ^ 2 + b ^ 2)| ≤ 1 ∧
      √(a ^ 2 + b ^ 2) * |deriv (fun x => x ^ 2 / (x ^ 2 + b ^ 2)) a| ≤ 4 / (3 * √3) ∧
      √(a ^ 2 + b ^ 2) * |deriv (fun y => a ^ 2 / (a ^ 2 + y ^ 2)) b| ≤ 4 / (3 * √3) ∧
      (a ^ 2 + b ^ 2) *
          |deriv (fun x => deriv (fun x' => x' ^ 2 / (x' ^ 2 + b ^ 2)) x) a| ≤ 2 ∧
      (a ^ 2 + b ^ 2) *
          |deriv (fun y => deriv (fun y' => a ^ 2 / (a ^ 2 + y' ^ 2)) y) b| ≤ 2 ∧
      (a ^ 2 + b ^ 2) *
          |deriv (fun y => deriv (fun x => x ^ 2 / (x ^ 2 + y ^ 2)) a) b| ≤ 1) ∧
    √(1 ^ 2 + √2 ^ 2) * |deriv (fun x => x ^ 2 / (x ^ 2 + √2 ^ 2)) 1| = 4 / (3 * √3) ∧
    ((0 : ℝ) ^ 2 + 1 ^ 2) *
        |deriv (fun x => deriv (fun x' => x' ^ 2 / (x' ^ 2 + 1 ^ 2)) x) 0| = 2 := by
  -- the inner first derivatives agree with their formulas near any point off the origin
  have hxx : ∀ a b : ℝ, a ^ 2 + b ^ 2 ≠ 0 →
      deriv (fun x => deriv (fun x' => x' ^ 2 / (x' ^ 2 + b ^ 2)) x) a
        = 2 * b ^ 2 * (b ^ 2 - 3 * a ^ 2) / (a ^ 2 + b ^ 2) ^ 3 := by
    intro a b h
    have hev : (fun x => deriv (fun x' => x' ^ 2 / (x' ^ 2 + b ^ 2)) x) =ᶠ[nhds a]
        fun x => 2 * x * b ^ 2 / (x ^ 2 + b ^ 2) ^ 2 := by
      filter_upwards [(by fun_prop : Continuous fun x : ℝ => x ^ 2 + b ^ 2).continuousAt.eventually_ne h]
        with x hx
      exact (riesz_hasDerivAt_x x b hx).deriv
    rw [hev.deriv_eq, (riesz_hasDerivAt_xx a b h).deriv]
  refine ⟨?_, ?_, ?_⟩
  · intro a b hab
    have hs : 0 < a ^ 2 + b ^ 2 := by
      rcases eq_or_ne a 0 with ha | ha
      · have hb : b ≠ 0 := fun hb => hab (by simp [ha, hb])
        positivity
      · positivity
    have h := hs.ne'
    refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩
    · rw [abs_of_nonneg (by positivity), div_le_one hs]
      nlinarith [sq_nonneg b]
    · rw [(riesz_hasDerivAt_x a b h).deriv]
      exact riesz_first_bound a b hs
    · rw [(riesz_hasDerivAt_y a b h).deriv]
      have := riesz_first_bound b a (by linarith)
      rw [add_comm (b ^ 2)] at this
      convert this using 2
      rw [show -2 * a ^ 2 * b = -(2 * b * a ^ 2) by ring, neg_div, abs_neg]
    · rw [hxx a b h]
      exact riesz_second_bound a b hs
    · have hev : (fun y => deriv (fun y' => a ^ 2 / (a ^ 2 + y' ^ 2)) y) =ᶠ[nhds b]
          fun y => -2 * a ^ 2 * y / (a ^ 2 + y ^ 2) ^ 2 := by
        filter_upwards [(by fun_prop : Continuous fun y : ℝ => a ^ 2 + y ^ 2).continuousAt.eventually_ne h]
          with y hy
        exact (riesz_hasDerivAt_y a y hy).deriv
      rw [hev.deriv_eq, (riesz_hasDerivAt_yy a b h).deriv]
      have := riesz_second_bound b a (by linarith)
      rw [add_comm (b ^ 2)] at this
      convert this using 2
      rw [show -2 * a ^ 2 * (a ^ 2 - 3 * b ^ 2) = -(2 * a ^ 2 * (a ^ 2 - 3 * b ^ 2)) by ring,
        neg_div, abs_neg]
    · have hev : (fun y => deriv (fun x => x ^ 2 / (x ^ 2 + y ^ 2)) a) =ᶠ[nhds b]
          fun y => 2 * a * y ^ 2 / (a ^ 2 + y ^ 2) ^ 2 := by
        filter_upwards [(by fun_prop : Continuous fun y : ℝ => a ^ 2 + y ^ 2).continuousAt.eventually_ne h]
          with y hy
        exact (riesz_hasDerivAt_x a y hy).deriv
      rw [hev.deriv_eq, (riesz_hasDerivAt_xy a b h).deriv]
      exact riesz_mixed_bound a b hs
  · rw [(riesz_hasDerivAt_x 1 √2 (by positivity)).deriv]
    have h2 : √2 ^ 2 = 2 := Real.sq_sqrt (by norm_num)
    have h3 : √3 ^ 2 = 3 := Real.sq_sqrt (by norm_num)
    have h3p : 0 < √3 := by positivity
    rw [h2]
    norm_num
    field_simp
    rw [h3]; norm_num
  · rw [hxx 0 1 (by norm_num)]
    norm_num

-- The number of derivatives the test asks for, ⌊d/2⌋ + 1: one on the line, two in the plane.
example : 1 / 2 + 1 = 1 ∧ 2 / 2 + 1 = 2 := by decide
-- The tail step needs 2N > d for N = ⌊d/2⌋ + 1 derivatives: true in every dimension up to 100.
example : ∀ d < 100, d < 2 * (d / 2 + 1) := by decide
-- The ten band centres, 2^k kHz for k = -5, ..., 4, in hertz: 31.25 Hz up to 16 kHz.
example : (List.range 10).map (fun k : ℕ => (1000 : ℚ) * 2 ^ k / 32) =
    [125 / 4, 125 / 2, 125, 250, 500, 1000, 2000, 4000, 8000, 16000] := by
  norm_num [List.range_succ]
-- The plane example's first-derivative value 4/(3√3) is below the second-derivative value 2:
-- its square is 16/27 < 4, so A = max(1, 4/(3√3), 2, 1) = 2.
example : (4 : ℚ) ^ 2 / (3 ^ 2 * 3) = 16 / 27 ∧ (16 : ℚ) / 27 < 2 ^ 2 := by norm_num
-- At ξ = (1, √2), where |ξ|² = 3: ∂₁m = 2ξ₁ξ₂²/|ξ|⁴ = 2·1·2/9 = 4/9.
example : (2 : ℚ) * 1 * 2 / 3 ^ 2 = 4 / 9 := by norm_num

#print axioms mihlin_test_bounds_energy
#print axioms equaliser_mihlin_constant
#print axioms riesz_square_mihlin_constant
#print axioms equaliser_hasDerivAt
#print axioms riesz_hasDerivAt_sq
#print axioms riesz_hasDerivAt_x
#print axioms riesz_hasDerivAt_y
#print axioms riesz_hasDerivAt_xx
#print axioms riesz_hasDerivAt_yy
#print axioms riesz_hasDerivAt_xy
#print axioms riesz_first_bound
#print axioms riesz_second_bound
#print axioms riesz_mixed_bound
