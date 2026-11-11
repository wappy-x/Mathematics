-- Fixed points: a contraction of a closed interval into itself has exactly one fixed point, pressing it from any start converges there with the first-step and last-step error bounds, a slope bound q makes a rule a contraction with factor q, and cos is a contraction of [0, 1] with factor sin 1.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Topology.Algebra.Order.Field
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Analysis.Real.Pi.Bounds

open Set Filter Topology

/-- Banach's fixed-point theorem on a closed interval. If a rule `g` maps the closed interval
`[a, b]` into itself and shrinks every distance by one factor `q` with `0 ≤ q < 1`, then `g` has
exactly one fixed point `p` in `[a, b]`. Pressing `g` again and again from any start `x₀` in the
interval converges to `p`, and the error after `n` presses obeys the first-step bound
`|xₙ - p| ≤ qⁿ / (1 - q) · |x₁ - x₀|` and, for `n ≥ 1`, the last-step bound
`|xₙ - p| ≤ q / (1 - q) · |xₙ - xₙ₋₁|`. -/
theorem contraction_has_unique_fixed_point_and_iteration_converges
    (g : ℝ → ℝ) (a b q : ℝ) (hab : a ≤ b)
    (hmaps : MapsTo g (Icc a b) (Icc a b))
    (hcontr : ∀ x ∈ Icc a b, ∀ y ∈ Icc a b, |g x - g y| ≤ q * |x - y|)
    (hq0 : 0 ≤ q) (hq1 : q < 1) :
    ∃ p ∈ Icc a b, g p = p ∧
      (∀ r ∈ Icc a b, g r = r → r = p) ∧
      ∀ x₀ ∈ Icc a b,
        Tendsto (fun n : ℕ => g^[n] x₀) atTop (𝓝 p) ∧
        (∀ n : ℕ, |g^[n] x₀ - p| ≤ q ^ n / (1 - q) * |g x₀ - x₀|) ∧
        (∀ n : ℕ, 1 ≤ n → |g^[n] x₀ - p| ≤ q / (1 - q) * |g^[n] x₀ - g^[n - 1] x₀|) := by
  have hlip : LipschitzOnWith (Real.toNNReal q) g (Icc a b) :=
    LipschitzOnWith.of_dist_le' (fun x hx y hy => by
      simpa [Real.dist_eq] using hcontr x hx y hy)
  have hgc : ContinuousOn g (Icc a b) := hlip.continuousOn
  have hhc : ContinuousOn (fun x => g x - x) (Icc a b) := hgc.sub continuousOn_id
  have ha := hmaps (left_mem_Icc.2 hab)
  have hb := hmaps (right_mem_Icc.2 hab)
  obtain ⟨p, hp, hpe⟩ : (0 : ℝ) ∈ (fun x => g x - x) '' Icc a b := by
    apply intermediate_value_Icc' hab hhc
    constructor
    · linarith [hb.2]
    · linarith [ha.1]
  have hfix : g p = p := by simp only at hpe; linarith
  have h1q : 0 < 1 - q := by linarith
  have hstep : ∀ x ∈ Icc a b, |g x - p| ≤ q * |x - p| := by
    intro x hx
    have := hcontr x hx p hp
    rwa [hfix] at this
  have hiter : ∀ x₀ ∈ Icc a b, ∀ n : ℕ, |g^[n] x₀ - p| ≤ q ^ n * |x₀ - p| := by
    intro x₀ hx₀ n
    induction n with
    | zero => simp
    | succ n ih =>
      rw [Function.iterate_succ_apply', pow_succ]
      calc |g (g^[n] x₀) - p| ≤ q * |g^[n] x₀ - p| := hstep _ (hmaps.iterate n hx₀)
        _ ≤ q * (q ^ n * |x₀ - p|) := mul_le_mul_of_nonneg_left ih hq0
        _ = q ^ n * q * |x₀ - p| := by ring
  have htri : ∀ x : ℝ, |x - p| ≤ |g x - x| + |g x - p| := by
    intro x
    calc |x - p| = |(x - g x) + (g x - p)| := by ring_nf
      _ ≤ |x - g x| + |g x - p| := abs_add_le _ _
      _ = |g x - x| + |g x - p| := by rw [abs_sub_comm x (g x)]
  have hfirst : ∀ x₀ ∈ Icc a b, |x₀ - p| ≤ |g x₀ - x₀| / (1 - q) := by
    intro x₀ hx₀
    rw [le_div_iff₀ h1q]
    have h1 := hstep x₀ hx₀
    have h2 := htri x₀
    nlinarith
  refine ⟨p, hp, hfix, ?_, ?_⟩
  · intro r hr hrr
    have h := hstep r hr
    rw [hrr] at h
    have h0 : |r - p| ≤ 0 := by nlinarith [abs_nonneg (r - p)]
    have : |r - p| = 0 := le_antisymm h0 (abs_nonneg _)
    linarith [abs_eq_zero.1 this]
  · intro x₀ hx₀
    have hbound : ∀ n : ℕ, |g^[n] x₀ - p| ≤ q ^ n / (1 - q) * |g x₀ - x₀| := by
      intro n
      calc |g^[n] x₀ - p| ≤ q ^ n * |x₀ - p| := hiter x₀ hx₀ n
        _ ≤ q ^ n * (|g x₀ - x₀| / (1 - q)) :=
            mul_le_mul_of_nonneg_left (hfirst x₀ hx₀) (pow_nonneg hq0 n)
        _ = q ^ n / (1 - q) * |g x₀ - x₀| := by ring
    refine ⟨?_, hbound, ?_⟩
    · have hlim : Tendsto (fun n : ℕ => q ^ n / (1 - q) * |g x₀ - x₀|) atTop (𝓝 0) := by
        have := tendsto_pow_atTop_nhds_zero_of_lt_one hq0 hq1
        simpa using (this.div_const (1 - q)).mul_const |g x₀ - x₀|
      rw [tendsto_iff_norm_sub_tendsto_zero]
      refine squeeze_zero (fun n => norm_nonneg _) (fun n => ?_) hlim
      rw [Real.norm_eq_abs]
      exact hbound n
    · intro n hn
      obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
      simp only [Nat.add_sub_cancel]
      have hm := hmaps.iterate m hx₀
      rw [Function.iterate_succ_apply']
      set y := g^[m] x₀
      have h1 := hstep y hm
      have h2 := htri y
      rw [div_mul_eq_mul_div, le_div_iff₀ h1q]
      nlinarith

/-- The derivative certifies the shrinking: a rule that is continuous on `[a, b]` and whose slope
stays between `-q` and `q` inside the interval shrinks every distance in `[a, b]` by the factor `q`
(the mean value theorem). -/
theorem slope_bound_gives_contraction
    (g g' : ℝ → ℝ) (a b q : ℝ)
    (hcont : ContinuousOn g (Icc a b))
    (hderiv : ∀ x ∈ Ioo a b, HasDerivAt g (g' x) x)
    (hslope : ∀ x ∈ Ioo a b, |g' x| ≤ q) :
    ∀ x ∈ Icc a b, ∀ y ∈ Icc a b, |g x - g y| ≤ q * |x - y| := by
  have key : ∀ x ∈ Icc a b, ∀ y ∈ Icc a b, x < y → |g y - g x| ≤ q * |y - x| := by
    intro x hx y hy hxy
    have hsub : Icc x y ⊆ Icc a b := Icc_subset_Icc hx.1 hy.2
    have hsub' : Ioo x y ⊆ Ioo a b := Ioo_subset_Ioo hx.1 hy.2
    obtain ⟨c, hc, hc'⟩ := exists_hasDerivAt_eq_slope g g' hxy (hcont.mono hsub)
      (fun z hz => hderiv z (hsub' hz))
    have hne : y - x ≠ 0 := sub_ne_zero.2 hxy.ne'
    have : g y - g x = g' c * (y - x) := by rw [hc']; field_simp
    rw [this, abs_mul]
    exact mul_le_mul_of_nonneg_right (hslope c (hsub' hc)) (abs_nonneg _)
  intro x hx y hy
  rcases lt_trichotomy x y with h | h | h
  · rw [abs_sub_comm (g x), abs_sub_comm x]
    exact key x hx y hy h
  · subst h; simp
  · exact key y hy x hx h

/-- The card's example: cos (in radians) maps `[0, 1]` into itself and shrinks every distance there
by the factor `q = sin 1`, which is below 1, so `cos x = x` has exactly one solution in `[0, 1]`. -/
theorem cos_is_contraction_on_unit_interval :
    MapsTo Real.cos (Icc 0 1) (Icc 0 1) ∧
    (∀ x ∈ Icc (0 : ℝ) 1, ∀ y ∈ Icc (0 : ℝ) 1,
      |Real.cos x - Real.cos y| ≤ Real.sin 1 * |x - y|) ∧
    0 ≤ Real.sin 1 ∧ Real.sin 1 < 1 ∧
    ∃! p, p ∈ Icc (0 : ℝ) 1 ∧ Real.cos p = p := by
  have hpi : 1 < Real.pi / 2 := by linarith [Real.pi_gt_three]
  have hmaps : MapsTo Real.cos (Icc 0 1) (Icc 0 1) := by
    intro x hx
    exact ⟨Real.cos_nonneg_of_mem_Icc ⟨by linarith [hx.1], by linarith [hx.2]⟩,
      Real.cos_le_one x⟩
  have hcontr : ∀ x ∈ Icc (0 : ℝ) 1, ∀ y ∈ Icc (0 : ℝ) 1,
      |Real.cos x - Real.cos y| ≤ Real.sin 1 * |x - y| := by
    apply slope_bound_gives_contraction Real.cos (fun x => -Real.sin x) 0 1 (Real.sin 1)
      Real.continuous_cos.continuousOn
    · intro x _; exact Real.hasDerivAt_cos x
    · intro x hx
      have h0 : 0 ≤ Real.sin x :=
        Real.sin_nonneg_of_nonneg_of_le_pi hx.1.le (by linarith [hx.2, Real.pi_gt_three])
      have h1 : Real.sin x ≤ Real.sin 1 :=
        Real.sin_le_sin_of_le_of_le_pi_div_two (by linarith [hx.1]) hpi.le hx.2.le
      rw [abs_neg, abs_of_nonneg h0]
      exact h1
  have hs0 : 0 ≤ Real.sin 1 :=
    Real.sin_nonneg_of_nonneg_of_le_pi zero_le_one (by linarith [Real.pi_gt_three])
  have hs1 : Real.sin 1 < 1 := Real.sin_lt one_pos
  refine ⟨hmaps, hcontr, hs0, hs1, ?_⟩
  obtain ⟨p, hp, hfix, huniq, -⟩ :=
    contraction_has_unique_fixed_point_and_iteration_converges Real.cos 0 1 (Real.sin 1)
      zero_le_one hmaps hcontr hs0 hs1
  exact ⟨p, ⟨hp, hfix⟩, fun r hr => huniq r hr.1 hr.2⟩

-- "When it holds", exact checks. x/2 + 1 sends 1 to 3/2, outside [0, 1]; its fixed point is 2.
example : (1 : ℝ) / 2 + 1 = 3 / 2 := by norm_num
example : (2 : ℝ) / 2 + 1 = 2 := by norm_num
-- Halving has no fixed point on (0, 1], the interval with 0 left out.
example : ∀ x ∈ Ioc (0 : ℝ) 1, x / 2 ≠ x := by
  intro x hx h
  linarith [hx.1]
-- x + 1/x has no fixed point on the numbers from 1 up.
example : ∀ x : ℝ, 1 ≤ x → x + 1 / x ≠ x := by
  intro x hx h
  have : 0 < 1 / x := by positivity
  linarith

#print axioms contraction_has_unique_fixed_point_and_iteration_converges
#print axioms slope_bound_gives_contraction
#print axioms cos_is_contraction_on_unit_interval
