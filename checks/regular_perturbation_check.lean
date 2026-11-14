-- Regular perturbation: the pendulum's period is 1 + ε/16 + 11ε²/3072 times the small-swing period, with an error of order ε³ where ε is the release angle squared, and the corrections behind it are exact.
import Mathlib.Analysis.Asymptotics.Defs
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open Real Filter Topology Asymptotics

lemma rp_inv_sqrt_bound {x : ℝ} (hx0 : 0 ≤ x) (hx1 : x ≤ 1 / 2) :
    |1 / √(1 - x) - (1 + x / 2 + 3 * x ^ 2 / 8)| ≤ 2 * x ^ 3 := by
  set y := √(1 - x) with hy
  have hy2 : y ^ 2 = 1 - x := sq_sqrt (by linarith)
  have hy0 : 0 ≤ y := sqrt_nonneg _
  have hypos : 0 < y := by nlinarith
  have hyl : 1 / 2 ≤ y := by nlinarith
  have hyu : y ≤ 1 := by nlinarith
  set p := 1 + x / 2 + 3 * x ^ 2 / 8 with hp
  have hp1 : 1 ≤ p := by nlinarith
  have hN : 1 - p ^ 2 * y ^ 2 = 5 * x ^ 3 / 8 + 15 * x ^ 4 / 64 + 9 * x ^ 5 / 64 := by
    rw [hy2, hp]; ring
  have hNle : 1 - p ^ 2 * y ^ 2 ≤ x ^ 3 := by
    rw [hN]; have : x ^ 4 ≤ x ^ 3 := by nlinarith [pow_nonneg hx0 3]
    have : x ^ 5 ≤ x ^ 3 := by nlinarith [pow_nonneg hx0 3, pow_nonneg hx0 4]
    nlinarith
  have hNge : 0 ≤ 1 - p ^ 2 * y ^ 2 := by rw [hN]; positivity
  have key : 1 / y - p = (1 - p ^ 2 * y ^ 2) / (y * (1 + p * y)) := by
    field_simp; ring
  rw [key, abs_of_nonneg (by positivity)]
  rw [div_le_iff₀ (by positivity)]
  have : 1 ≤ y * (1 + p * y) := by nlinarith
  nlinarith [pow_nonneg hx0 3]

#print axioms rp_inv_sqrt_bound

lemma rp_sin_sq_bound {a : ℝ} (ha : |a| ≤ 1) :
    |sin (a / 2) ^ 2 - (a ^ 2 / 4 - a ^ 4 / 48)| ≤ a ^ 6 / 64 := by
  set t := a / 2 with ht
  have ht1 : |t| ≤ 1 := by rw [ht, abs_div]; norm_num; linarith
  have hb := Real.sin_bound ht1
  set e := sin t - (t - t ^ 3 / 6) with he
  have hs : sin t = t - t ^ 3 / 6 + e := by rw [he]; ring
  have hat : a = 2 * t := by rw [ht]; ring
  rw [hs, hat]
  have ht2 : t ^ 2 ≤ 1 := by nlinarith [abs_nonneg t, sq_abs t]
  have hta : |t| ^ 2 = t ^ 2 := sq_abs t
  have h5 : |t| ^ 5 ≤ |t| := by
    calc |t| ^ 5 ≤ |t| ^ 1 := pow_le_pow_of_le_one (abs_nonneg _) ht1 (by norm_num)
      _ = |t| := pow_one _
  have he1 : |e| ≤ |t| ^ 5 / 100 := hb
  have expand : (t - t ^ 3 / 6 + e) ^ 2 - ((2 * t) ^ 2 / 4 - (2 * t) ^ 4 / 48)
      = t ^ 6 / 36 + 2 * (t - t ^ 3 / 6) * e + e ^ 2 := by ring
  rw [expand]
  have h1 : |2 * (t - t ^ 3 / 6) * e| ≤ 2 * |t| * (|t| ^ 5 / 100) := by
    rw [abs_mul, abs_mul]
    have : |t - t ^ 3 / 6| ≤ |t| := by
      rw [abs_le]; constructor <;> nlinarith [abs_le.mp (le_refl |t|), le_abs_self t, neg_abs_le t, sq_nonneg t, abs_nonneg t]
    have : |(2:ℝ)| = 2 := by norm_num
    rw [this]; gcongr
  have h2 : |e ^ 2| ≤ (|t| ^ 5 / 100) ^ 2 := by
    rw [abs_pow]; gcongr
  have h6 : (2 * t) ^ 6 / 64 = |t| ^ 6 := by
    rw [show |t| ^ 6 = (|t| ^ 2) ^ 3 by ring, hta]; ring
  rw [h6]
  have h66 : t ^ 6 = |t| ^ 6 := by rw [show |t| ^ 6 = (|t| ^ 2) ^ 3 by ring, hta]; ring
  calc |t ^ 6 / 36 + 2 * (t - t ^ 3 / 6) * e + e ^ 2|
      ≤ |t ^ 6 / 36| + |2 * (t - t ^ 3 / 6) * e| + |e ^ 2| := abs_add_three _ _ _
    _ ≤ |t| ^ 6 / 36 + 2 * |t| * (|t| ^ 5 / 100) + (|t| ^ 5 / 100) ^ 2 := by
        gcongr
        rw [abs_div, abs_pow]; norm_num
    _ ≤ |t| ^ 6 := by
        have h10 : |t| ^ 10 ≤ |t| ^ 6 := pow_le_pow_of_le_one (abs_nonneg _) ht1 (by norm_num)
        have : 2 * |t| * (|t| ^ 5 / 100) = |t| ^ 6 / 50 := by ring
        have : (|t| ^ 5 / 100) ^ 2 = |t| ^ 10 / 10000 := by ring
        nlinarith [pow_nonneg (abs_nonneg t) 6]

#print axioms rp_sin_sq_bound

lemma rp_integral_poly (s : ℝ) :
    ∫ φ in (0 : ℝ)..(π / 2), (1 + s * sin φ ^ 2 / 2 + 3 * (s * sin φ ^ 2) ^ 2 / 8)
      = π / 2 + s * π / 8 + 9 * s ^ 2 * π / 128 := by
  have h : (fun φ : ℝ => 1 + s * sin φ ^ 2 / 2 + 3 * (s * sin φ ^ 2) ^ 2 / 8)
      = fun φ => 1 + (s / 2) * sin φ ^ 2 + (3 * s ^ 2 / 8) * sin φ ^ (2 + 2) := by
    funext φ; ring
  rw [h, intervalIntegral.integral_add, intervalIntegral.integral_add,
    intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul,
    integral_sin_pow 2, integral_sin_sq]
  · simp; ring
  all_goals apply Continuous.intervalIntegrable; fun_prop

#print axioms rp_integral_poly

/-- The card's main claim. The exact period of a pendulum released from rest at angle `a`,
as a multiple of the small-swing period, is `(2/π) ∫₀^{π/2} (1 - sin²(a/2) sin²φ)^(-1/2) dφ`.
With the small number `ε = a²`, it equals `1 + ε/16 + 11ε²/3072` up to a remainder of order `ε³`
as the swing gets small. -/
theorem pendulum_period_series :
    (fun a : ℝ =>
        (2 / π) * (∫ φ in (0 : ℝ)..(π / 2), 1 / √(1 - sin (a / 2) ^ 2 * sin φ ^ 2))
          - (1 + a ^ 2 / 16 + 11 * (a ^ 2) ^ 2 / 3072))
      =O[𝓝 0] (fun a : ℝ => (a ^ 2) ^ 3) := by
  apply IsBigO.of_bound 1
  have hev : ∀ᶠ a : ℝ in 𝓝 0, |a| ≤ 1 := by
    filter_upwards [Metric.ball_mem_nhds (0 : ℝ) one_pos] with a ha
    rw [Metric.mem_ball, dist_zero_right, Real.norm_eq_abs] at ha
    exact ha.le
  filter_upwards [hev] with a ha
  set s := sin (a / 2) ^ 2 with hs
  have hA0 : 0 ≤ a ^ 2 := sq_nonneg a
  have hA1 : a ^ 2 ≤ 1 := by nlinarith [sq_abs a, abs_nonneg a]
  have hs0 : 0 ≤ s := sq_nonneg _
  have hsA : s ≤ a ^ 2 / 4 := by
    have := sin_sq_le_sq (x := a / 2); rw [hs]; nlinarith
  have hs1 : s ≤ 1 / 4 := by linarith
  have hpi : 0 < π := pi_pos
  -- pointwise bound on the integrand
  have hcont_f : Continuous (fun φ : ℝ => 1 / √(1 - s * sin φ ^ 2)) := by
    apply Continuous.div continuous_const (by fun_prop)
    intro φ
    have : sin φ ^ 2 ≤ 1 := sin_sq_le_one φ
    have : 0 < 1 - s * sin φ ^ 2 := by nlinarith
    exact (sqrt_pos.mpr this).ne'
  have hcont_p : Continuous
      (fun φ : ℝ => 1 + s * sin φ ^ 2 / 2 + 3 * (s * sin φ ^ 2) ^ 2 / 8) := by fun_prop
  have hdiff : |(∫ φ in (0 : ℝ)..(π / 2), 1 / √(1 - s * sin φ ^ 2))
      - ∫ φ in (0 : ℝ)..(π / 2), (1 + s * sin φ ^ 2 / 2 + 3 * (s * sin φ ^ 2) ^ 2 / 8)|
      ≤ 2 * s ^ 3 * (π / 2) := by
    rw [← intervalIntegral.integral_sub (hcont_f.intervalIntegrable _ _)
      (hcont_p.intervalIntegrable _ _)]
    have := intervalIntegral.norm_integral_le_of_norm_le_const (a := 0) (b := π / 2)
      (C := 2 * s ^ 3)
      (f := fun φ => 1 / √(1 - s * sin φ ^ 2)
        - (1 + s * sin φ ^ 2 / 2 + 3 * (s * sin φ ^ 2) ^ 2 / 8)) (by
        intro φ _
        rw [Real.norm_eq_abs]
        have h1 : sin φ ^ 2 ≤ 1 := sin_sq_le_one φ
        have h0 : 0 ≤ sin φ ^ 2 := sq_nonneg _
        have hx0 : 0 ≤ s * sin φ ^ 2 := mul_nonneg hs0 h0
        have hxs : s * sin φ ^ 2 ≤ s := by nlinarith
        refine (rp_inv_sqrt_bound hx0 (by linarith)).trans ?_
        have : (s * sin φ ^ 2) ^ 3 ≤ s ^ 3 := pow_le_pow_left₀ hx0 hxs 3
        linarith)
    rw [Real.norm_eq_abs] at this
    simpa [abs_of_pos (by positivity : (0 : ℝ) < π / 2)] using this
  rw [rp_integral_poly] at hdiff
  set I := ∫ φ in (0 : ℝ)..(π / 2), 1 / √(1 - s * sin φ ^ 2) with hI
  -- the sine expansion
  have hd := rp_sin_sq_bound ha
  rw [← hs] at hd
  set d := s - (a ^ 2 / 4 - a ^ 4 / 48) with hdd
  have hsplit : 2 / π * I - (1 + a ^ 2 / 16 + 11 * (a ^ 2) ^ 2 / 3072)
      = 2 / π * (I - (π / 2 + s * π / 8 + 9 * s ^ 2 * π / 128))
        + (d / 4 + 9 / 64 * ((s - a ^ 2 / 4) * (s + a ^ 2 / 4))) := by
    rw [hdd]; field_simp; ring
  rw [Real.norm_eq_abs, Real.norm_eq_abs, hsplit, abs_of_nonneg (by positivity : (0:ℝ) ≤ (a ^ 2) ^ 3)]
  have hT1 : |2 / π * (I - (π / 2 + s * π / 8 + 9 * s ^ 2 * π / 128))| ≤ 2 * s ^ 3 := by
    rw [abs_mul, abs_of_pos (by positivity : (0:ℝ) < 2 / π)]
    calc 2 / π * |I - (π / 2 + s * π / 8 + 9 * s ^ 2 * π / 128)|
        ≤ 2 / π * (2 * s ^ 3 * (π / 2)) := by gcongr
      _ = 2 * s ^ 3 := by field_simp
  have hs3 : s ^ 3 ≤ (a ^ 2 / 4) ^ 3 := pow_le_pow_left₀ hs0 hsA 3
  have ha4 : a ^ 4 = (a ^ 2) ^ 2 := by ring
  have ha6 : a ^ 6 = (a ^ 2) ^ 3 := by ring
  have hA3 : (a ^ 2) ^ 3 ≤ (a ^ 2) ^ 2 := by nlinarith [pow_nonneg hA0 2]
  have hsm : |s - a ^ 2 / 4| ≤ (a ^ 2) ^ 2 := by
    have : s - a ^ 2 / 4 = d - a ^ 4 / 48 := by rw [hdd]; ring
    rw [this]
    calc |d - a ^ 4 / 48| ≤ |d| + |a ^ 4 / 48| := abs_sub _ _
      _ ≤ a ^ 6 / 64 + a ^ 4 / 48 := by
          gcongr; rw [abs_of_nonneg (by positivity)]
      _ ≤ (a ^ 2) ^ 2 := by rw [ha4, ha6]; nlinarith [pow_nonneg hA0 2]
  have hsp : |s + a ^ 2 / 4| ≤ a ^ 2 / 2 := by
    rw [abs_of_nonneg (by positivity)]; linarith
  have hT2 : |d / 4 + 9 / 64 * ((s - a ^ 2 / 4) * (s + a ^ 2 / 4))|
      ≤ (a ^ 2) ^ 3 / 256 + 9 / 64 * ((a ^ 2) ^ 2 * (a ^ 2 / 2)) := by
    calc _ ≤ |d / 4| + |9 / 64 * ((s - a ^ 2 / 4) * (s + a ^ 2 / 4))| := abs_add_le _ _
      _ ≤ _ := by
        gcongr
        · rw [abs_div, abs_of_pos (by norm_num : (0:ℝ) < 4)]
          rw [ha6] at hd; linarith
        · rw [abs_mul, abs_mul, abs_of_pos (by norm_num : (0:ℝ) < 9 / 64)]
          gcongr
  calc _ ≤ |2 / π * (I - (π / 2 + s * π / 8 + 9 * s ^ 2 * π / 128))|
        + |d / 4 + 9 / 64 * ((s - a ^ 2 / 4) * (s + a ^ 2 / 4))| := abs_add_le _ _
    _ ≤ 2 * (a ^ 2 / 4) ^ 3 + ((a ^ 2) ^ 3 / 256 + 9 / 64 * ((a ^ 2) ^ 2 * (a ^ 2 / 2))) := by
        linarith
    _ ≤ 1 * (a ^ 2) ^ 3 := by nlinarith [pow_nonneg hA0 3]

/-- Step 5: from frequency to period. If the frequency is `ω = 1 - ε/16 + ε²/3072`,
the period `1/ω` is `1 + ε/16 + 11ε²/3072` up to a remainder of order `ε³`. -/
theorem period_from_frequency :
    (fun ε : ℝ => 1 / (1 - ε / 16 + ε ^ 2 / 3072) - (1 + ε / 16 + 11 * ε ^ 2 / 3072))
      =O[𝓝 0] (fun ε : ℝ => ε ^ 3) := by
  apply IsBigO.of_bound 1
  have hev : ∀ᶠ e : ℝ in 𝓝 0, |e| ≤ 1 := by
    filter_upwards [Metric.ball_mem_nhds (0 : ℝ) one_pos] with e he
    rw [Metric.mem_ball, dist_zero_right, Real.norm_eq_abs] at he
    exact he.le
  filter_upwards [hev] with ε hε
  have h1 := abs_le.mp hε
  have hD : 15 / 16 ≤ 1 - ε / 16 + ε ^ 2 / 3072 := by nlinarith [sq_nonneg ε]
  have hDpos : 0 < 1 - ε / 16 + ε ^ 2 / 3072 := by linarith
  have key : 1 / (1 - ε / 16 + ε ^ 2 / 3072) - (1 + ε / 16 + 11 * ε ^ 2 / 3072)
      = ε ^ 3 * (10 / 49152 - 11 * ε / 9437184) / (1 - ε / 16 + ε ^ 2 / 3072) := by
    rw [eq_div_iff hDpos.ne', sub_mul, one_div_mul_cancel hDpos.ne']; ring
  rw [Real.norm_eq_abs, Real.norm_eq_abs, key, abs_div, abs_mul, abs_of_pos hDpos,
    div_le_iff₀ hDpos]
  have hc : |10 / 49152 - 11 * ε / 9437184| ≤ 1 / 100 := by
    rw [abs_le]; constructor <;> nlinarith
  have := abs_nonneg (ε ^ 3)
  calc |ε ^ 3| * |10 / 49152 - 11 * ε / 9437184| ≤ |ε ^ 3| * (1 / 100) := by gcongr
    _ ≤ 1 * |ε ^ 3| * (1 - ε / 16 + ε ^ 2 / 3072) := by nlinarith

/-- Step 3: with the frequency correction `ω₁ = -1/16`, the first correction
`u₁(τ) = (cos τ - cos 3τ)/192` solves the first rung `u₁'' + u₁ = 2ω₁ cos τ + cos³τ / 6`
and starts at rest at zero: `u₁(0) = 0`, `u₁'(0) = 0`. No term grows with time. -/
theorem strained_first_correction :
    let u₁ : ℝ → ℝ := fun τ => (cos τ - cos (3 * τ)) / 192
    (∀ τ : ℝ, deriv (deriv u₁) τ + u₁ τ = 2 * (-1 / 16 : ℝ) * cos τ + cos τ ^ 3 / 6) ∧
      u₁ 0 = 0 ∧ deriv u₁ 0 = 0 := by
  intro u₁
  have h1 : ∀ τ, HasDerivAt u₁ ((-sin τ + 3 * sin (3 * τ)) / 192) τ := by
    intro τ
    have := ((hasDerivAt_cos τ).sub ((hasDerivAt_cos (3 * τ)).comp τ
      ((hasDerivAt_id τ).const_mul 3))).div_const 192
    convert this using 1
    all_goals first | rfl | ring
  have hd1 : deriv u₁ = fun τ => (-sin τ + 3 * sin (3 * τ)) / 192 :=
    funext fun τ => (h1 τ).deriv
  have h2 : ∀ τ, HasDerivAt (fun τ => (-sin τ + 3 * sin (3 * τ)) / 192)
      ((-cos τ + 9 * cos (3 * τ)) / 192) τ := by
    intro τ
    have := (((hasDerivAt_sin τ).neg).add (((hasDerivAt_sin (3 * τ)).comp τ
      ((hasDerivAt_id τ).const_mul 3)).const_mul 3)).div_const 192
    convert this using 1
    all_goals first | rfl | ring
  have hd2 : deriv (deriv u₁) = fun τ => (-cos τ + 9 * cos (3 * τ)) / 192 := by
    rw [hd1]; exact funext fun τ => (h2 τ).deriv
  refine ⟨?_, ?_, ?_⟩
  · intro τ
    rw [hd2]
    simp only [u₁]
    rw [cos_three_mul]; ring
  · simp [u₁]
  · rw [hd1]; simp

-- Step 3: ω₁ = -1/16 kills the resonant push, 2ω₁ + 1/8 = 0.
example : 2 * (-1 / 16 : ℚ) + 1 / 8 = 0 := by norm_num
-- Step 4: the cos τ parts in units of 1/1536 sum to -1, so 2ω₂ = 1/1536 and ω₂ = 1/3072.
example : (-1 : ℤ) + 6 + 2 - 8 = -1 := by norm_num
example : (-1 / 1536 : ℚ) + 1 / 256 + 1 / 768 - 1 / 192 = -1 / 1536 := by norm_num
example : 2 * (1 / 3072 : ℚ) - 1 / 1536 = 0 := by norm_num
-- Step 5: the second period coefficient, 1/256 - 1/3072 = 11/3072.
example : (1 / 256 : ℚ) - 1 / 3072 = 11 / 3072 := by norm_num
-- Detailed proof: the same coefficient by the integral road, -1/192 + 9/1024 = 11/3072.
example : (-1 / 192 : ℚ) + 9 / 1024 = 11 / 3072 := by norm_num
example : (-16 : ℚ) / 3072 + 27 / 3072 = 11 / 3072 := by norm_num
-- Step 6: halving the amplitude quarters ε, so an ε³ error falls 4³ = 64-fold.
example : (2 : ℕ) ^ 2 = 4 ∧ (4 : ℕ) ^ 3 = 64 := by decide

#print axioms pendulum_period_series
#print axioms period_from_frequency
#print axioms strained_first_correction
