-- The Laplace transform: this file proves that a signal with finite area on every finite stretch and at most exponential growth e^(at) has a Laplace transform at every s > a, that the card's five table entries are right, and that the transform of a weighted sum is the weighted sum of the transforms.
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Tactic.NormNum

/-! Setting, in the card's notation.
* A signal is a function `f : ℝ → ℝ`; only its values for `t ≥ 0` matter.
* The discount rate `s` is real, as on the card.
* The card's integral to infinity is the limit, as the horizon `T` grows, of the partial
  integral `∫ t in 0..T, e^(-st) f(t)`. "F(s) exists and equals `F`" is written
  `Tendsto (fun T => ∫ t in (0)..T, Real.exp (-(s * t)) * f t) atTop (𝓝 F)`.
* "Finite area near t = 0" (jumps allowed) is: `f` is integrable on `(0, T]` for every `T > 0`. -/

open MeasureTheory Filter Topology

namespace LaplaceCard

theorem integrand_intervalIntegrable (f : ℝ → ℝ) (s : ℝ) (hloc : ∀ T > 0, IntegrableOn f (Set.Ioc 0 T)) :
    ∀ᶠ T in atTop, IntervalIntegrable (fun t => Real.exp (-(s * t)) * f t) MeasureTheory.volume 0 T := by
  filter_upwards [eventually_gt_atTop 0] with T hT
  rw [intervalIntegrable_iff_integrableOn_Ioc_of_le hT.le]
  exact (hloc T hT).continuousOn_mul_of_subset (K := Set.Icc 0 T) (by fun_prop) isCompact_Icc
    measurableSet_Ioc Set.Ioc_subset_Icc_self

#print axioms integrand_intervalIntegrable

/-- FTC with limit: if `G' = g` everywhere, `g` continuous and `G T → 0`, then `∫ 0..T g → -G 0`. -/
theorem ftc_lim (g G : ℝ → ℝ) (L : ℝ) (hd : ∀ x, HasDerivAt G (g x) x) (hc : Continuous g)
    (hlim : Tendsto G atTop (𝓝 0)) (hL : L = -G 0) :
    Tendsto (fun T => ∫ t in (0)..T, g t) atTop (𝓝 L) := by
  have : (fun T => ∫ t in (0)..T, g t) = fun T => G T - G 0 := by
    ext T
    exact intervalIntegral.integral_eq_sub_of_hasDerivAt (fun x _ => hd x) (hc.intervalIntegrable _ _)
  rw [this, hL, ← zero_sub]
  exact hlim.sub_const _

#print axioms ftc_lim

theorem exp_decay (s : ℝ) (hs : 0 < s) : Tendsto (fun T => Real.exp (-(s * T))) atTop (𝓝 0) :=
  Real.tendsto_exp_neg_atTop_nhds_zero.comp (tendsto_id.const_mul_atTop hs)

#print axioms exp_decay

theorem exp_decay_mul_bdd (s : ℝ) (hs : 0 < s) (h : ℝ → ℝ) (C : ℝ) (hC : ∀ t, |h t| ≤ C) :
    Tendsto (fun T => Real.exp (-(s * T)) * h T) atTop (𝓝 0) := by
  refine squeeze_zero_norm (a := fun T => Real.exp (-(s * T)) * C) (fun T => ?_) ?_
  · rw [Real.norm_eq_abs, abs_mul, Real.abs_exp]
    exact mul_le_mul_of_nonneg_left (hC T) (Real.exp_pos _).le
  · simpa using (exp_decay s hs).mul_const C

#print axioms exp_decay_mul_bdd

theorem exp_one (r : ℝ) (hr : 0 < r) :
    Tendsto (fun T => ∫ t in (0)..T, Real.exp (-(r * t))) atTop (𝓝 (1 / r)) := by
  refine ftc_lim _ (fun t => -Real.exp (-(r * t)) / r) _ (fun x => ?_) (by fun_prop) ?_ ?_
  · have := (((hasDerivAt_id x).const_mul r).neg.exp).neg.div_const r
    refine this.congr_deriv ?_
    simp only [Pi.neg_apply, id]
    field_simp
  · simpa using (exp_decay r hr).neg.div_const r
  · simp [neg_div]

#print axioms exp_one

/-- Existence. Suppose a signal has finite area on every finite stretch `(0, T]`, and from some
time `t₀` on it stays below `M e^(at)` in size. Then its Laplace transform exists at every
discount rate `s` that beats the growth rate, `s > a`: the partial integrals of `e^(-st) f(t)`
up to `T` settle to a limit as `T` grows. -/
theorem laplace_transform_exists_of_exponential_growth (f : ℝ → ℝ) (a : ℝ)
    (hloc : ∀ T > 0, IntegrableOn f (Set.Ioc 0 T))
    (hgrow : ∃ M t₀ : ℝ, ∀ t ≥ t₀, |f t| ≤ M * Real.exp (a * t)) :
    ∀ s > a, ∃ F : ℝ,
      Tendsto (fun T => ∫ t in (0)..T, Real.exp (-(s * t)) * f t) atTop (𝓝 F) := by
  intro s hs
  obtain ⟨M, t₀, hM⟩ := hgrow
  set T₁ := max t₀ 1 with hT₁
  have hT₁pos : 0 < T₁ := lt_of_lt_of_le one_pos (le_max_right _ _)
  have hmeas : AEStronglyMeasurable f (volume.restrict (Set.Ioi 0)) := by
    have : Set.Ioi (0:ℝ) = ⋃ n : ℕ, Set.Ioc 0 ((n:ℝ) + 1) := by
      ext x; simp only [Set.mem_Ioi, Set.mem_iUnion, Set.mem_Ioc]
      constructor
      · intro hx
        obtain ⟨n, hn⟩ := exists_nat_ge x
        exact ⟨n, hx, by linarith⟩
      · rintro ⟨n, hx, -⟩; exact hx
    rw [this, aestronglyMeasurable_iUnion_iff]
    intro n
    exact (hloc _ (by positivity)).aestronglyMeasurable
  have h1 : IntegrableOn (fun t => Real.exp (-(s * t)) * f t) (Set.Ioc 0 T₁) :=
    (hloc T₁ hT₁pos).continuousOn_mul_of_subset (K := Set.Icc 0 T₁) (by fun_prop) isCompact_Icc
      measurableSet_Ioc Set.Ioc_subset_Icc_self
  have h2 : IntegrableOn (fun t => Real.exp (-(s * t)) * f t) (Set.Ioi T₁) := by
    have hb : IntegrableOn (fun t => M * Real.exp ((a - s) * t)) (Set.Ioi T₁) :=
      (integrableOn_exp_mul_Ioi (by linarith) T₁).const_mul M
    refine hb.mono' ?_ ?_
    · have hm : AEStronglyMeasurable f (volume.restrict (Set.Ioi T₁)) :=
        hmeas.mono_measure (Measure.restrict_mono (Set.Ioi_subset_Ioi hT₁pos.le) le_rfl)
      exact (Continuous.aestronglyMeasurable (by fun_prop)).mul hm
    · refine (ae_restrict_mem measurableSet_Ioi).mono fun t ht => ?_
      have ht' : t ≥ t₀ := le_trans (le_max_left _ _) (le_of_lt ht)
      rw [Real.norm_eq_abs, abs_mul, Real.abs_exp]
      calc Real.exp (-(s * t)) * |f t| ≤ Real.exp (-(s * t)) * (M * Real.exp (a * t)) :=
            mul_le_mul_of_nonneg_left (hM t ht') (Real.exp_pos _).le
        _ = M * Real.exp ((a - s) * t) := by
            rw [mul_left_comm, ← Real.exp_add]; congr 2; ring
  have hint : IntegrableOn (fun t => Real.exp (-(s * t)) * f t) (Set.Ioi 0) := by
    have : Set.Ioi (0:ℝ) = Set.Ioc 0 T₁ ∪ Set.Ioi T₁ := (Set.Ioc_union_Ioi_eq_Ioi hT₁pos.le).symm
    rw [this]; exact h1.union h2
  exact ⟨_, intervalIntegral_tendsto_integral_Ioi 0 hint tendsto_id⟩

/-- The table of five transforms. For `s > 0`: the level signal `1` has transform `1/s`, the
ramp `t` has `1/s^2`, the wave `cos(bt)` has `s/(s^2 + b^2)` and the wave `sin(bt)` has
`b/(s^2 + b^2)`. The growing signal `e^(at)` has transform `1/(s - a)` whenever `s > a`. -/
theorem laplace_transform_table (s b : ℝ) :
    (0 < s → Tendsto (fun T => ∫ t in (0)..T, Real.exp (-(s * t)) * 1) atTop (𝓝 (1 / s))) ∧
    (0 < s → Tendsto (fun T => ∫ t in (0)..T, Real.exp (-(s * t)) * t) atTop (𝓝 (1 / s ^ 2))) ∧
    (∀ a < s, Tendsto (fun T => ∫ t in (0)..T, Real.exp (-(s * t)) * Real.exp (a * t)) atTop
      (𝓝 (1 / (s - a)))) ∧
    (0 < s → Tendsto (fun T => ∫ t in (0)..T, Real.exp (-(s * t)) * Real.cos (b * t)) atTop
      (𝓝 (s / (s ^ 2 + b ^ 2)))) ∧
    (0 < s → Tendsto (fun T => ∫ t in (0)..T, Real.exp (-(s * t)) * Real.sin (b * t)) atTop
      (𝓝 (b / (s ^ 2 + b ^ 2)))) := by
  refine ⟨fun hs => ?_, fun hs => ?_, fun a ha => ?_, fun hs => ?_, fun hs => ?_⟩
  · simpa using exp_one s hs
  · refine ftc_lim _ (fun t => -(t / s + 1 / s ^ 2) * Real.exp (-(s * t))) _ (fun x => ?_)
      (by fun_prop) ?_ ?_
    · have := ((((hasDerivAt_id x).div_const s).add_const (1 / s ^ 2)).neg).mul
        (((hasDerivAt_id x).const_mul s).neg.exp)
      refine this.congr_deriv ?_
      simp only [Pi.neg_apply, id]
      field_simp
      ring
    · have h1 : Tendsto (fun T => (s * T) ^ 1 * Real.exp (-(s * T))) atTop (𝓝 0) :=
        (Real.tendsto_pow_mul_exp_neg_atTop_nhds_zero 1).comp (tendsto_id.const_mul_atTop hs)
      have h2 := ((h1.div_const (s ^ 2)).add ((exp_decay s hs).div_const (s ^ 2))).neg
      simp only [zero_div, add_zero, neg_zero] at h2
      refine h2.congr fun T => ?_
      field_simp
    · simp
  · have hr : 0 < s - a := by linarith
    refine (exp_one (s - a) hr).congr fun T => ?_
    congr 1; ext t
    rw [← Real.exp_add]; congr 1; ring
  · have hD : 0 < s ^ 2 + b ^ 2 := by positivity
    refine ftc_lim _ (fun t => Real.exp (-(s * t)) * (b * Real.sin (b * t) - s * Real.cos (b * t))
      / (s ^ 2 + b ^ 2)) _ (fun x => ?_) (by fun_prop) ?_ ?_
    · have := ((((hasDerivAt_id x).const_mul s).neg.exp).mul
        ((((hasDerivAt_id x).const_mul b).sin.const_mul b).sub
          (((hasDerivAt_id x).const_mul b).cos.const_mul s))).div_const (s ^ 2 + b ^ 2)
      refine this.congr_deriv ?_
      simp only [Pi.neg_apply, Pi.sub_apply, id]
      field_simp
      ring
    · have := (exp_decay_mul_bdd s hs (fun t => b * Real.sin (b * t) - s * Real.cos (b * t))
        (|b| + |s|) (fun t => by
          refine (abs_sub _ _).trans (add_le_add ?_ ?_) <;> rw [abs_mul]
          · exact mul_le_of_le_one_right (abs_nonneg _) (Real.abs_sin_le_one _)
          · exact mul_le_of_le_one_right (abs_nonneg _) (Real.abs_cos_le_one _))).div_const
        (s ^ 2 + b ^ 2)
      simpa using this
    · simp; ring
  · have hD : 0 < s ^ 2 + b ^ 2 := by positivity
    refine ftc_lim _ (fun t => -(Real.exp (-(s * t)) * (s * Real.sin (b * t) + b * Real.cos (b * t)))
      / (s ^ 2 + b ^ 2)) _ (fun x => ?_) (by fun_prop) ?_ ?_
    · have := (((((hasDerivAt_id x).const_mul s).neg.exp).mul
        ((((hasDerivAt_id x).const_mul b).sin.const_mul s).add
          (((hasDerivAt_id x).const_mul b).cos.const_mul b))).neg).div_const (s ^ 2 + b ^ 2)
      refine this.congr_deriv ?_
      simp only [Pi.neg_apply, Pi.add_apply, id]
      field_simp
      ring
    · have := ((exp_decay_mul_bdd s hs (fun t => s * Real.sin (b * t) + b * Real.cos (b * t))
        (|s| + |b|) (fun t => by
          refine (abs_add_le _ _).trans (add_le_add ?_ ?_) <;> rw [abs_mul]
          · exact mul_le_of_le_one_right (abs_nonneg _) (Real.abs_sin_le_one _)
          · exact mul_le_of_le_one_right (abs_nonneg _) (Real.abs_cos_le_one _))).neg).div_const
        (s ^ 2 + b ^ 2)
      simpa using this
    · simp; ring

/-- Linearity. If two signals with finite area on every finite stretch have transforms `F` and
`G` at the rate `s`, then for any constant weights `c` and `k` the signal `c f + k g` has
transform `c F + k G` at `s`. -/
theorem laplace_transform_linear (f g : ℝ → ℝ) (s F G c k : ℝ)
    (hf_loc : ∀ T > 0, IntegrableOn f (Set.Ioc 0 T))
    (hg_loc : ∀ T > 0, IntegrableOn g (Set.Ioc 0 T))
    (hF : Tendsto (fun T => ∫ t in (0)..T, Real.exp (-(s * t)) * f t) atTop (𝓝 F))
    (hG : Tendsto (fun T => ∫ t in (0)..T, Real.exp (-(s * t)) * g t) atTop (𝓝 G)) :
    Tendsto (fun T => ∫ t in (0)..T, Real.exp (-(s * t)) * (c * f t + k * g t)) atTop
      (𝓝 (c * F + k * G)) := by
  refine ((hF.const_mul c).add (hG.const_mul k)).congr' ?_
  filter_upwards [integrand_intervalIntegrable f s hf_loc, integrand_intervalIntegrable g s hg_loc] with T h1 h2
  rw [← intervalIntegral.integral_const_mul, ← intervalIntegral.integral_const_mul,
    ← intervalIntegral.integral_add (h1.const_mul c) (h2.const_mul k)]
  congr 1; ext t; ring

/-! The card's exact arithmetic, with s = 0.05 = 1/20 and a = 0.03 = 3/100. -/

-- Level stream, table row 1: 1000 × 1/s = 20,000 dollars.
example : (1000 : ℚ) * (1 / (1 / 20)) = 20000 := by norm_num
-- Ramp, table row 2: 1/s^2 = 400.
example : (1 : ℚ) / (1 / 20) ^ 2 = 400 := by norm_num
-- Growing stream, table row 3: 1/(s − a) = 50, so 1000 × 50 = 50,000 dollars.
example : (1 : ℚ) / (1 / 20 - 3 / 100) = 50 := by norm_num
example : (1000 : ℚ) * (1 / (1 / 20 - 3 / 100)) = 50000 := by norm_num
-- Rate rule on e^(0.03t): s × 50 − 1 = 1.5 = 0.03 × 50.
example : (1 / 20 : ℚ) * 50 - 1 = 3 / 2 ∧ (3 / 100 : ℚ) * 50 = 3 / 2 := by norm_num
-- Linearity's first piece: 1000 × 20 = 20,000.
example : (1000 : ℚ) * 20 = 20000 := by norm_num
-- At s = 0.03 the growing stream's integrand is the constant 1000: 1,000 dollars a year,
-- 100,000 by year 100 and 200,000 by year 200, with no limit; the chart's line rises 10,000 a decade.
example : (1000 : ℚ) * 100 = 100000 ∧ (1000 : ℚ) * 200 = 200000 ∧ (1000 : ℚ) * 10 = 10000 := by
  norm_num
-- Sign slip: 1000/(s + a) = 12,500 dollars, not 50,000.
example : (1000 : ℚ) / (1 / 20 + 3 / 100) = 12500 := by norm_num
-- Usual mistake: 1/(s − 0.03) at s = 0.02 is negative.
example : (1 : ℚ) / (2 / 100 - 3 / 100) < 0 := by norm_num

#print axioms laplace_transform_exists_of_exponential_growth
#print axioms laplace_transform_table
#print axioms laplace_transform_linear

end LaplaceCard
