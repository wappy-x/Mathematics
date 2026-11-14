-- PID in practice: the integral-area identity for an unstopped PI integral, the noise-gain sum of the filtered derivative, and its bounded limit under fast sampling.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt

open Filter Topology

/-- The integral-area identity. A PI controller asks for the valve `Kp * e t + x t`, where
`e` is the error and the integral term `x` grows at rate `Ki * e` and is never stopped.
The loop starts steady (error 0, valve `u_0`) and settles (error tends to 0, valve tends to
`u_inf`). Then the error's total area `∫₀^∞ e dt` is `(u_inf - u_0) / Ki`, whatever happened on
the way. -/
theorem integral_area_identity (Kp Ki u_0 u_inf : ℝ) (e x : ℝ → ℝ) (hKi : Ki ≠ 0)
    (he : ContinuousOn e (Set.Ici 0)) (hx : ContinuousOn x (Set.Ici 0))
    (hderiv : ∀ t > 0, HasDerivAt x (Ki * e t) t)
    (he0 : e 0 = 0) (hu0 : Kp * e 0 + x 0 = u_0)
    (he_lim : Tendsto e atTop (𝓝 0))
    (hu_lim : Tendsto (fun t => Kp * e t + x t) atTop (𝓝 u_inf)) :
    Tendsto (fun T => ∫ t in (0 : ℝ)..T, e t) atTop (𝓝 ((u_inf - u_0) / Ki)) := by
  have hInt : ∀ T ≥ (0:ℝ), ∫ t in (0 : ℝ)..T, e t = (x T - x 0) / Ki := by
    intro T hT
    have hc : ContinuousOn e (Set.uIcc 0 T) := he.mono (by
      rw [Set.uIcc_of_le hT]; exact Set.Icc_subset_Ici_self)
    have h1 : ∫ t in (0 : ℝ)..T, Ki * e t = x T - x 0 := by
      apply intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hT
      · exact hx.mono Set.Icc_subset_Ici_self
      · intro t ht; exact hderiv t ht.1
      · exact (continuousOn_const.mul hc).intervalIntegrable
    rw [intervalIntegral.integral_const_mul] at h1
    rw [eq_div_iff hKi, mul_comm]
    exact h1
  have hxlim : Tendsto x atTop (𝓝 u_inf) := by
    have h := hu_lim.sub (he_lim.const_mul Kp)
    rw [mul_zero, sub_zero] at h
    exact h.congr (fun t => by ring)
  have hx0 : x 0 = u_0 := by rw [he0, mul_zero, zero_add] at hu0; exact hu0
  have hlim : Tendsto (fun T => (x T - x 0) / Ki) atTop (𝓝 ((u_inf - u_0) / Ki)) := by
    rw [← hx0]
    exact (hxlim.sub_const (x 0)).div_const Ki
  refine hlim.congr' ?_
  filter_upwards [eventually_ge_atTop 0] with T hT
  exact (hInt T hT).symm

/-- The derivative-noise formula. The filtered derivative `D_k = a D_{k-1} + b (n_k - n_{k-1})`
answers a single unit reading at step 0 with the weights `g`. For `0 ≤ a < 1`, white noise of
size `σ` gives the output variance `σ² Σ g_k²`, and this sum converges to `σ_D²` with
`σ_D = b σ √(2 / (1 + a))`. -/
theorem filtered_derivative_noise (a b σ : ℝ) (g : ℕ → ℝ) (ha0 : 0 ≤ a) (ha1 : a < 1)
    (hg0 : g 0 = b * (1 - 0))
    (hg : ∀ k : ℕ, g (k + 1) = a * g k +
      b * ((if k + 1 = 0 then 1 else 0) - (if k = 0 then 1 else 0))) :
    HasSum (fun k => (σ * g k) ^ 2) ((b * σ * Real.sqrt (2 / (1 + a))) ^ 2) := by
  have hg1 : g 1 = (a - 1) * b := by
    rw [hg 0, hg0]; simp; ring
  have hgk : ∀ k : ℕ, g (k + 1) = a ^ k * ((a - 1) * b) := by
    intro k
    induction k with
    | zero => simpa using hg1
    | succ n ih => rw [hg (n + 1), ih]; simp; ring
  have ha2 : a ^ 2 < 1 := by nlinarith
  have hgeo := (hasSum_geometric_of_lt_one (sq_nonneg a) ha2).mul_left ((σ * ((a - 1) * b)) ^ 2)
  have hne1 : (1 : ℝ) - a ^ 2 ≠ 0 := by linarith
  have hne2 : (1 : ℝ) + a ≠ 0 := by linarith
  rw [← hasSum_nat_add_iff' 1]
  simp only [Finset.sum_range_one, hg0]
  convert hgeo using 1
  · funext n; rw [hgk n]; ring
  · rw [mul_pow, mul_pow, Real.sq_sqrt (by positivity)]
    field_simp
    ring

/-- Fast sampling cannot blow up a filtered derivative. With filter time `Tf > 0` held fixed,
`a = Tf / (Tf + h)` and `b = Kd / (Tf + h)`; as the sample period `h` shrinks to 0, the jitter
`σ_D = b σ √(2 / (1 + a))` tends to `Kd σ / Tf`, a bounded value. -/
theorem filtered_jitter_tendsto (Kd Tf σ : ℝ) (hTf : 0 < Tf) :
    Tendsto (fun h : ℝ => Kd / (Tf + h) * σ * Real.sqrt (2 / (1 + Tf / (Tf + h))))
      (𝓝[>] 0) (𝓝 (Kd * σ / Tf)) := by
  have h1 : Tf + 0 ≠ 0 := by linarith
  have h2 : 1 + Tf / (Tf + 0) ≠ 0 := by rw [add_zero, div_self hTf.ne']; norm_num
  have hc : ContinuousAt
      (fun h : ℝ => Kd / (Tf + h) * σ * Real.sqrt (2 / (1 + Tf / (Tf + h)))) 0 := by
    apply ContinuousAt.mul
    · exact (continuousAt_const.div (continuousAt_const.add continuousAt_id) h1).mul
        continuousAt_const
    · apply Real.continuous_sqrt.continuousAt.comp
      exact continuousAt_const.div (continuousAt_const.add
        (continuousAt_const.div (continuousAt_const.add continuousAt_id) h1)) h2
  convert hc.tendsto.mono_left nhdsWithin_le_nhds using 2
  rw [add_zero, div_self hTf.ne']
  norm_num
  ring

-- The card's worked numbers, as exact fractions.
-- Heat and valve before: 0.2 × (15 − (−5)) = 4 kW; 4/6 = 2/3.
example : (1 / 5 : ℚ) * (15 - (-5)) = 4 ∧ (4 : ℚ) / 6 = 2 / 3 := by norm_num
-- Heat and valve after: 0.2 × (21 − (−5)) = 5.2 kW; 5.2/6 = 13/15.
example : (1 / 5 : ℚ) * (21 - (-5)) = 26 / 5 ∧ (26 / 5 : ℚ) / 6 = 13 / 15 := by norm_num
-- First request 0.125 × 6 + 2/3 = 17/12 (1.4167), past the wide-open valve.
example : (1 / 8 : ℚ) * 6 + 2 / 3 = 17 / 12 ∧ (1 : ℚ) < 17 / 12 := by norm_num
-- Where wide open leads: −5 + 6/0.2 = 25 °C.
example : (-5 : ℚ) + 6 / (1 / 5) = 25 := by norm_num
-- Fixed error area: (13/15 − 2/3) / (0.125/15) = 24 °C·min.
example : ((13 / 15 : ℚ) - 2 / 3) / ((1 / 8) / 15) = 24 := by norm_num
-- Clamped valve frees at 21 − (1 − 2/3)/0.125 = 55/3 °C (18.333).
example : (21 : ℚ) - (1 - 2 / 3) / (1 / 8) = 55 / 3 := by norm_num
-- Filter with Tf = 0.2, h = 0.1, Kd = 0.25: a = 2/3, b = 5/6.
example : (1 / 5 : ℚ) / (1 / 5 + 1 / 10) = 2 / 3 ∧ (1 / 4 : ℚ) / (1 / 5 + 1 / 10) = 5 / 6 := by
  norm_num
-- Jitter squared, σ = 0.05: raw (a = 0, b = 5/2) gives 1/32 (σ_D = 0.1768);
-- filtered (a = 2/3, b = 5/6) gives 1/480 (σ_D = 0.0456).
example : (5 / 2 : ℚ) ^ 2 * (1 / 20) ^ 2 * (2 / (1 + 0)) = 1 / 32 := by norm_num
example : (5 / 6 : ℚ) ^ 2 * (1 / 20) ^ 2 * (2 / (1 + 2 / 3)) = 1 / 480 := by norm_num
-- Inner loop time: τ_q / (K_in Q_max) = 4 / ((8/6) × 6) = 1/2 min.
example : (4 : ℚ) / ((8 / 6) * 6) = 1 / 2 := by norm_num

#print axioms integral_area_identity
#print axioms filtered_derivative_noise
#print axioms filtered_jitter_tendsto
