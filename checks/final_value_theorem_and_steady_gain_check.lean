-- Final value and bandwidth: a signal whose derivative is absolutely integrable settles at the limit of s times its Laplace transform as s shrinks to zero, the car's speed settles at its steady gain times the throttle step, and a first-order lag's gain falls to 1/√2 of its zero-frequency value exactly at the frequency 1/τ.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Integral.IntegrableOn
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Analysis.Complex.Basic
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
import Mathlib.Analysis.Calculus.MeanValue

open Filter Topology MeasureTheory Set

/-- The final value theorem. If a signal `y` is differentiable for `t > 0`, continuous from
`t = 0` on, and its derivative `y'` is absolutely integrable over `(0, ∞)`, then `y` settles at a
final value, and that final value equals the limit of `s · Y(s)` as real `s` shrinks to `0` from
above, where `Y(s) = ∫₀^∞ e^(-s t) y(t) dt` is the Laplace transform of `y`. -/
theorem final_value_theorem (y y' : ℝ → ℝ)
    (hcont : ContinuousOn y (Ici 0))
    (hderiv : ∀ t, 0 < t → HasDerivAt y (y' t) t)
    (hint : IntegrableOn y' (Ioi 0)) :
    ∃ L : ℝ, Tendsto y atTop (𝓝 L) ∧
      Tendsto (fun s : ℝ => s * ∫ t in Ioi (0 : ℝ), Real.exp (-(s * t)) * y t)
        (𝓝[>] 0) (𝓝 L) := by
  set L := limUnder atTop y
  have hL : Tendsto y atTop (𝓝 L) :=
    tendsto_limUnder_of_hasDerivAt_of_integrableOn_Ioi (fun x hx => hderiv x hx) hint
  refine ⟨L, hL, ?_⟩
  obtain ⟨T, hT⟩ : ∃ T, ∀ t ≥ T, |y t - L| ≤ 1 := by
    have := hL.eventually (Metric.closedBall_mem_nhds L one_pos)
    rw [eventually_atTop] at this
    obtain ⟨T, hT⟩ := this
    exact ⟨T, fun t ht => by simpa [Real.dist_eq] using hT t ht⟩
  obtain ⟨C, hC⟩ := (isCompact_Icc : IsCompact (Icc (0 : ℝ) T)).exists_bound_of_continuousOn
    (hcont.mono Icc_subset_Ici_self)
  set M := max C (|L| + 1)
  have hM : ∀ t : ℝ, 0 ≤ t → |y t| ≤ M := by
    intro t ht
    rcases le_total t T with h | h
    · have := hC t ⟨ht, h⟩
      rw [Real.norm_eq_abs] at this
      exact this.trans (le_max_left _ _)
    · have h1 := hT t h
      have h2 : |y t| ≤ |L| + 1 := by
        calc |y t| = |(y t - L) + L| := by ring_nf
          _ ≤ |y t - L| + |L| := abs_add_le _ _
          _ ≤ |L| + 1 := by linarith
      exact h2.trans (le_max_right _ _)
  have key : ∀ s : ℝ, 0 < s → s * ∫ t in Ioi (0 : ℝ), Real.exp (-(s * t)) * y t
      = ∫ u in Ioi (0 : ℝ), Real.exp (-u) * y (u / s) := by
    intro s hs
    have h := integral_comp_mul_left_Ioi' (fun u => Real.exp (-u) * y (u / s)) 0 hs
    simp only [mul_zero, smul_eq_mul] at h
    rw [← h]
    congr 1
    congr 1
    funext t
    rw [mul_div_cancel_left₀ t hs.ne']
  have hlim : Tendsto (fun s : ℝ => ∫ u in Ioi (0 : ℝ), Real.exp (-u) * y (u / s)) (𝓝[>] 0)
      (𝓝 (∫ u in Ioi (0 : ℝ), Real.exp (-u) * L)) := by
    refine tendsto_integral_filter_of_dominated_convergence (fun u => M * Real.exp (-u)) ?_ ?_ ?_ ?_
    · filter_upwards [self_mem_nhdsWithin] with s hs
      have hs : (0 : ℝ) < s := hs
      refine ContinuousOn.aestronglyMeasurable ?_ measurableSet_Ioi
      refine (Real.continuous_exp.comp continuous_neg).continuousOn.mul ?_
      refine hcont.comp (continuousOn_id.div_const s) ?_
      intro u hu
      exact div_nonneg (le_of_lt hu) hs.le
    · filter_upwards [self_mem_nhdsWithin] with s hs
      have hs : (0 : ℝ) < s := hs
      rw [ae_restrict_iff' measurableSet_Ioi]
      refine Eventually.of_forall (fun u hu => ?_)
      have hu : (0 : ℝ) < u := hu
      rw [Real.norm_eq_abs, abs_mul, Real.abs_exp, mul_comm]
      exact mul_le_mul_of_nonneg_right (hM _ (div_nonneg hu.le hs.le)) (Real.exp_pos _).le
    · exact (integrableOn_exp_neg_Ioi 0).const_mul M
    · rw [ae_restrict_iff' measurableSet_Ioi]
      refine Eventually.of_forall (fun u hu => ?_)
      have hu : (0 : ℝ) < u := hu
      refine Tendsto.const_mul _ (hL.comp ?_)
      have := tendsto_inv_nhdsGT_zero.const_mul_atTop hu
      refine this.congr (fun s => ?_)
      exact (div_eq_mul_inv u s).symm
  rw [integral_mul_const, integral_exp_neg_Ioi_zero, one_mul] at hlim
  refine hlim.congr' ?_
  filter_upwards [self_mem_nhdsWithin] with s hs
  exact (key s hs).symm

/-- Where the car settles. A car of mass `m > 0` with drag `b > 0` per unit speed and push `F`
per unit throttle obeys `m v' = F u₀ - b v` once the throttle is held at `u₀`. Whatever speed it
starts from, its speed settles at the steady gain `G(0) = K = F / b` times the step size `u₀`. -/
theorem step_response_settles_at_steady_gain (m b F u₀ : ℝ) (hm : 0 < m) (hb : 0 < b)
    (v v' : ℝ → ℝ)
    (hderiv : ∀ t, 0 < t → HasDerivAt v (v' t) t)
    (hode : ∀ t, 0 < t → m * v' t = F * u₀ - b * v t) :
    Tendsto v atTop (𝓝 (F / b * u₀)) := by
  set c := F / b * u₀ with hc
  set k := b / m with hkdef
  have hk : 0 < k := div_pos hb hm
  set g : ℝ → ℝ := fun t => (v t - c) * Real.exp (k * t) with hgdef
  have hg : ∀ t, 0 < t → HasDerivAt g 0 t := by
    intro t ht
    have h1 := ((hderiv t ht).sub_const c).mul (((hasDerivAt_id t).const_mul k).exp)
    convert h1 using 1
    · funext x
      simp [hgdef]
    have hv' : v' t = (F * u₀ - b * v t) / m := by
      field_simp
      linarith [hode t ht]
    rw [hv', hc, hkdef]
    simp only [id]
    field_simp
    ring
  have hconst : ∀ t, 1 ≤ t → g t = g 1 := by
    intro t ht
    rcases eq_or_lt_of_le ht with h | h
    · rw [h]
    obtain ⟨x, hx, hx'⟩ := exists_hasDerivAt_eq_slope g (fun _ => 0) h
      (fun x hx => (hg x (by linarith [hx.1])).continuousAt.continuousWithinAt)
      (fun x hx => hg x (by linarith [hx.1]))
    have hne : t - 1 ≠ 0 := by linarith
    have : g t - g 1 = 0 := by
      have := hx'.symm
      rw [div_eq_zero_iff] at this
      rcases this with h0 | h0
      · exact h0
      · exact absurd h0 hne
    linarith
  have hv : ∀ t, 1 ≤ t → v t = c + g 1 * Real.exp (-(k * t)) := by
    intro t ht
    rw [← hconst t ht, hgdef]
    simp only
    rw [mul_assoc, ← Real.exp_add]
    simp
  have hlim : Tendsto (fun t => c + g 1 * Real.exp (-(k * t))) atTop (𝓝 (c + g 1 * 0)) := by
    refine tendsto_const_nhds.add (tendsto_const_nhds.mul ?_)
    exact Real.tendsto_exp_atBot.comp
      (tendsto_neg_atTop_atBot.comp (tendsto_id.const_mul_atTop hk))
  rw [mul_zero, add_zero] at hlim
  refine hlim.congr' ?_
  filter_upwards [eventually_ge_atTop 1] with t ht
  exact (hv t ht).symm

/-- Bandwidth of a first-order lag. For `G(s) = K / (τ s + 1)` with a nonzero steady gain `K` and
time constant `τ > 0`, the gain `|G(jω)|` at a frequency `ω ≥ 0` equals `|G(0)| / √2` exactly
when `ω = 1 / τ`. -/
theorem first_order_lag_bandwidth (K τ ω : ℝ) (hK : K ≠ 0) (hτ : 0 < τ) (hω : 0 ≤ ω) :
    ‖(K : ℂ) / ((τ : ℂ) * ((ω : ℂ) * Complex.I) + 1)‖ = |K| / Real.sqrt 2 ↔ ω = 1 / τ := by
  have hden : ‖(τ : ℂ) * ((ω : ℂ) * Complex.I) + 1‖ = Real.sqrt ((τ * ω) ^ 2 + 1) := by
    rw [Complex.norm_def, Complex.normSq_apply]
    congr 1
    simp
    ring
  rw [norm_div, Complex.norm_real, Real.norm_eq_abs, hden]
  have hKp : 0 < |K| := abs_pos.mpr hK
  have hs1 : 0 < Real.sqrt ((τ * ω) ^ 2 + 1) := Real.sqrt_pos.mpr (by positivity)
  have hs2 : 0 < Real.sqrt 2 := by positivity
  constructor
  · intro h
    rw [div_eq_div_iff hs1.ne' hs2.ne'] at h
    have h3 := mul_left_cancel₀ hKp.ne' h
    rw [Real.sqrt_inj (by norm_num) (by positivity)] at h3
    have hτω : 0 ≤ τ * ω := mul_nonneg hτ.le hω
    have h4 : τ * ω = 1 := by nlinarith
    field_simp
    linarith
  · intro h
    subst h
    have : τ * (1 / τ) = 1 := by field_simp
    rw [this]
    norm_num

-- The car's numbers: m = 1500 kg, b = 60 N s/m, F = 1500 N, throttle step 0.8 = 4/5.
-- Steady gain K = F / b = 25 m/s per unit throttle.
example : (1500 : ℚ) / 60 = 25 := by norm_num
-- Time constant τ = m / b = 25 s.
example : (1500 : ℚ) / 60 = 25 := by norm_num
-- Final speed G(0) u₀ = 25 × 4/5 = 20 m/s, which is 72 km/h.
example : (25 : ℚ) * (4 / 5) = 20 := by norm_num
example : (20 : ℚ) * 3600 / 1000 = 72 := by norm_num
-- s Y(s) at s = 1/100: 25 × 4/5 / (25 × 1/100 + 1) = 20 / (5/4) = 16 m/s.
example : (25 : ℚ) * (4 / 5) / (25 * (1 / 100) + 1) = 16 := by norm_num
-- Bandwidth 1/τ = 1/25 = 4/100 rad/s.
example : (1 : ℚ) / 25 = 4 / 100 := by norm_num
-- Partial fractions: 20 / (s (25 s + 1)) = 20 / s - 20 / (s + 1/25), checked at s = 1.
example : (20 : ℚ) / (1 * (25 * 1 + 1)) = 20 / 1 - 20 / (1 + 1 / 25) := by norm_num

#print axioms final_value_theorem
#print axioms step_response_settles_at_steady_gain
#print axioms first_order_lag_bandwidth
