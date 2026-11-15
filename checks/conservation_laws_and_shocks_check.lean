-- Conservation laws: a jump keeps the car count exactly when it moves at the Rankine-Hugoniot speed [q]/[ρ], characteristics first cross at t_b = 1/m, and density patterns travel slower than the cars.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Slope
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Topology.Order.IntermediateValue

open MeasureTheory

/-- Helper: the integral of a one-jump step function over an interval containing the jump. -/
theorem step_interval_integral (ρL ρR a b c : ℝ) (ha : a < c) (hb : c < b) :
    ∫ x in a..b, (if x < c then ρL else ρR) = ρL * (c - a) + ρR * (b - c) := by
  have h1 : Set.EqOn (fun _ : ℝ => ρL) (fun x => if x < c then ρL else ρR) (Set.uIoo a c) := by
    intro x hx
    rw [Set.uIoo_of_le ha.le] at hx
    simp [hx.2]
  have h2 : Set.EqOn (fun _ : ℝ => ρR) (fun x => if x < c then ρL else ρR) (Set.uIoo c b) := by
    intro x hx
    rw [Set.uIoo_of_le hb.le] at hx
    simp [not_lt.2 hx.1.le]
  have i1 : IntervalIntegrable (fun x : ℝ => if x < c then ρL else ρR) volume a c :=
    (intervalIntegrable_const (c := ρL)).congr_uIoo h1
  have i2 : IntervalIntegrable (fun x : ℝ => if x < c then ρL else ρR) volume c b :=
    (intervalIntegrable_const (c := ρR)).congr_uIoo h2
  rw [← intervalIntegral.integral_add_adjacent_intervals i1 i2,
    ← intervalIntegral.integral_congr_uIoo h1, ← intervalIntegral.integral_congr_uIoo h2]
  simp [intervalIntegral.integral_const]
  ring

/-- The Rankine-Hugoniot rule. A jump at place `X t` has density `ρL` behind it and `ρR` ahead
of it, and the flow `q` depends on density alone. Take a stretch of road `[a, b]` around the jump.
The number of cars in the stretch changes at the rate "flow in at `a` minus flow out at `b`"
(cars are conserved) exactly when the jump moves at
`X' = (q ρR - q ρL) / (ρR - ρL)`, the jump in flow over the jump in density.
Any other speed would lose or invent cars. -/
theorem rankine_hugoniot (q : ℝ → ℝ) (ρL ρR a b : ℝ) (X : ℝ → ℝ) (t : ℝ)
    (hjump : ρL ≠ ρR) (hX : DifferentiableAt ℝ X t) (ha : a < X t) (hb : X t < b) :
    HasDerivAt (fun τ => ∫ x in a..b, if x < X τ then ρL else ρR) (q ρL - q ρR) t ↔
      deriv X t = (q ρR - q ρL) / (ρR - ρL) := by
  have hev : (fun τ => ∫ x in a..b, if x < X τ then ρL else ρR) =ᶠ[nhds t]
      (fun τ => (ρL - ρR) * X τ + (ρR * b - ρL * a)) := by
    have hc := hX.continuousAt
    filter_upwards [hc.eventually (lt_mem_nhds ha), hc.eventually (gt_mem_nhds hb)]
      with τ h1 h2
    rw [step_interval_integral ρL ρR a b (X τ) h1 h2]
    ring
  rw [hev.hasDerivAt_iff]
  have hd : HasDerivAt (fun τ => (ρL - ρR) * X τ + (ρR * b - ρL * a))
      ((ρL - ρR) * deriv X t) t :=
    (hX.hasDerivAt.const_mul (ρL - ρR)).add_const _
  have hne : ρR - ρL ≠ 0 := sub_ne_zero.2 (Ne.symm hjump)
  constructor
  · intro h
    have := h.unique hd
    rw [eq_div_iff hne]
    linear_combination this
  · intro h
    convert hd using 1
    rw [h]
    field_simp
    ring

/-- The breaking time. Each start `x₀` sends a straight characteristic
`x = x₀ + q'(ρ₀ x₀) t`. Suppose the wave speed `k x₀ = q'(ρ₀ x₀)` falls from back to front at
most at rate `m > 0` per unit length, and at exactly that rate somewhere. Then before
`t_b = 1/m` the characteristics never cross: the map from start to place is one-to-one and
onto. After `t_b`, two characteristics from different starts have already met. -/
theorem breaking_time (q ρ₀ : ℝ → ℝ) (m : ℝ) (hm : 0 < m)
    (hq : ContDiff ℝ 2 q) (hρ₀ : ContDiff ℝ 1 ρ₀)
    (hmin : ∀ x₀, -m ≤ deriv (fun x => deriv q (ρ₀ x)) x₀)
    (hattain : ∃ x₀, deriv (fun x => deriv q (ρ₀ x)) x₀ = -m) :
    (∀ t, 0 ≤ t → t < 1 / m →
        Function.Bijective (fun x₀ => x₀ + deriv q (ρ₀ x₀) * t)) ∧
      ∀ t, 1 / m < t → ∃ x₁ x₂ τ, x₁ ≠ x₂ ∧ 0 < τ ∧ τ < t ∧
        x₁ + deriv q (ρ₀ x₁) * τ = x₂ + deriv q (ρ₀ x₂) * τ := by
  have hk1 : ContDiff ℝ 1 (fun x => deriv q (ρ₀ x)) := by
    have : ContDiff ℝ 1 (deriv q) := hq.deriv'
    exact this.comp hρ₀
  have hkd : Differentiable ℝ (fun x => deriv q (ρ₀ x)) := hk1.differentiable (by norm_num)
  set k : ℝ → ℝ := fun x => deriv q (ρ₀ x) with hk
  constructor
  · intro t ht0 htm
    have hmt : t * m < 1 := (lt_div_iff₀ hm).1 htm
    set c : ℝ := 1 - m * t with hc
    have hcpos : 0 < c := by rw [hc]; linarith
    have hderiv : ∀ x, HasDerivAt (fun x₀ => x₀ + k x₀ * t) (1 + deriv k x * t) x :=
      fun x => (hasDerivAt_id' x).add ((hkd x).hasDerivAt.mul_const t)
    have hlow : ∀ x, c ≤ 1 + deriv k x * t := by
      intro x
      have := hmin x
      rw [hc]
      nlinarith
    refine ⟨(strictMono_of_deriv_pos (fun x => by
      rw [(hderiv x).deriv]; linarith [hlow x])).injective, ?_⟩
    set f : ℝ → ℝ := fun x₀ => x₀ + k x₀ * t with hf
    have hfd : Differentiable ℝ f := fun x => (hderiv x).differentiableAt
    have hgd : ∀ x, HasDerivAt (fun x => f x - c * x) (1 + deriv k x * t - c * 1) x :=
      fun x => (hderiv x).sub ((hasDerivAt_id' x).const_mul c)
    have hgmono : Monotone (fun x => f x - c * x) :=
      monotone_of_deriv_nonneg (fun x => (hgd x).differentiableAt)
        (fun x => by rw [(hgd x).deriv]; linarith [hlow x])
    have htop : Filter.Tendsto f Filter.atTop Filter.atTop := by
      refine Filter.tendsto_atTop_mono' Filter.atTop ?_
        (Filter.tendsto_atTop_add_const_left Filter.atTop (f 0)
          (Filter.tendsto_id.const_mul_atTop hcpos))
      filter_upwards [Filter.eventually_ge_atTop 0] with x hx
      have := hgmono hx
      simp only [id] at this ⊢
      linarith
    have hbot : Filter.Tendsto f Filter.atBot Filter.atBot := by
      refine Filter.tendsto_atBot_mono' Filter.atBot ?_
        (Filter.tendsto_atBot_add_const_left Filter.atBot (f 0)
          (Filter.tendsto_id.const_mul_atBot hcpos))
      filter_upwards [Filter.eventually_le_atBot 0] with x hx
      have := hgmono hx
      simp only [id] at this ⊢
      linarith
    exact hfd.continuous.surjective htop hbot
  · intro t ht
    obtain ⟨x₀, hx₀⟩ := hattain
    have htpos : 0 < t := lt_trans (by positivity) ht
    have hD : HasDerivAt k (-m) x₀ := hx₀ ▸ (hkd x₀).hasDerivAt
    have hlt : -m < -1 / t := by
      have : 1 / t < m := by
        rw [div_lt_iff₀ htpos]
        rw [div_lt_iff₀ hm] at ht
        linarith
      rw [neg_div]; linarith
    have hev := (hasDerivAt_iff_tendsto_slope.1 hD).eventually (gt_mem_nhds hlt)
    obtain ⟨x, hxs, hxne⟩ := (hev.and self_mem_nhdsWithin).exists
    have hxne' : x ≠ x₀ := hxne
    rw [slope_def_field] at hxs
    set s := (k x - k x₀) / (x - x₀) with hs
    have hspos : 0 < -s := by
      have : -1 / t < 0 := by apply div_neg_of_neg_of_pos <;> linarith
      linarith
    have hst : 1 < -s * t := by
      have h1 : s * t < -1 / t * t := mul_lt_mul_of_pos_right hxs htpos
      rw [div_mul_cancel₀ _ htpos.ne'] at h1
      linarith
    have hdx : x - x₀ ≠ 0 := sub_ne_zero.2 hxne'
    have hdk : k x - k x₀ ≠ 0 := by
      intro h; rw [hs, h, zero_div] at hspos; linarith
    refine ⟨x₀, x, 1 / (-s), hxne'.symm, by positivity, ?_, ?_⟩
    · rw [div_lt_iff₀ hspos]; linarith
    · rw [hs]
      field_simp
      ring

/-- The wave speed is not the car speed. If the flow is density times car speed,
`q ρ = ρ * v ρ`, and the car speed falls as density rises (`v' < 0`), then at any positive
density the wave speed `q'(ρ)` is below the car speed `v ρ`: a pattern always travels slower
than the cars in it. -/
theorem wave_speed_lt_car_speed (v : ℝ → ℝ) (ρ : ℝ) (hρ : 0 < ρ)
    (hv : DifferentiableAt ℝ v ρ) (hdec : deriv v ρ < 0) :
    deriv (fun r => r * v r) ρ < v ρ := by
  have h : HasDerivAt (fun r => r * v r) (1 * v ρ + ρ * deriv v ρ) ρ :=
    (hasDerivAt_id' ρ).mul hv.hasDerivAt
  rw [h.deriv]
  nlinarith

-- The card's worked numbers, exactly, with q(ρ) = 90 ρ (1 - ρ/150) in cars/h.
-- Flow arriving: q(30) = 2160 cars/h; car speed 72 km/h; the queue's flow q(150) = 0.
example : (90 : ℚ) * 30 * (1 - 30 / 150) = 2160 := by norm_num
example : (90 : ℚ) * (1 - 30 / 150) = 72 := by norm_num
example : (90 : ℚ) * 150 * (1 - 150 / 150) = 0 := by norm_num
-- Top flow q(75) = 3375 cars/h.
example : (90 : ℚ) * 75 * (1 - 75 / 150) = 3375 := by norm_num
-- Wave speeds q'(ρ) = 90 (1 - 2ρ/150): +54, -18 and -90 km/h; curvature q'' = -2·90/150 = -6/5.
example : (90 : ℚ) * (1 - 2 * 30 / 150) = 54 := by norm_num
example : (90 : ℚ) * (1 - 2 * 90 / 150) = -18 := by norm_num
example : (90 : ℚ) * (1 - 2 * 150 / 150) = -90 := by norm_num
example : -(2 : ℚ) * 90 / 150 = -6 / 5 := by norm_num
-- Breaking time 1/((6/5)·300) h = 10 s; where it breaks: -0.5 km + (-18 km/h)(10 s) = -0.55 km.
example : 1 / ((6 / 5 : ℚ) * 300) * 3600 = 10 := by norm_num
example : (-1 / 2 : ℚ) + (-18) * (10 / 3600) = -11 / 20 := by norm_num
-- Rankine-Hugoniot: (0 - 2160)/(150 - 30) = -18 km/h, and the shortcut 90 (1 - 180/150) = -18.
example : ((0 : ℚ) - 2160) / (150 - 30) = -18 := by norm_num
example : (90 : ℚ) * (1 - 180 / 150) = -18 := by norm_num
-- Tail at 60 s: -0.55 + (-18)(50/3600) = -0.8 km, so the queue holds 0.8 · 150 = 120 cars.
example : (-11 / 20 : ℚ) + (-18) * (50 / 3600) = -4 / 5 := by norm_num
example : (4 / 5 : ℚ) * 150 = 120 := by norm_num
-- Count on [-2, 0] km: 1.3·30 + 0.4·90 + 0.3·150 = 120 at start, 2160/60 = 36 in, and
-- 30 (X + 2) + 150 (-X) = 156 at X = -0.8 km.
example : (13 / 10 : ℚ) * 30 + 2 / 5 * 90 + 3 / 10 * 150 = 120 := by norm_num
example : (2160 : ℚ) / 60 = 36 := by norm_num
example : (30 : ℚ) * (-4 / 5 + 2) + 150 * (4 / 5) = 156 := by norm_num
-- Mistake 1: characteristics at the car speed, v' = -90/150, break at 20 s, not 10 s.
example : 1 / ((90 / 150 : ℚ) * 300) * 3600 = 20 := by norm_num
-- Mistake 2: shock speed +18 km/h puts the tail at -0.3 km and counts 96 cars, not 156.
example : (-11 / 20 : ℚ) + 18 * (50 / 3600) = -3 / 10 := by norm_num
example : (30 : ℚ) * (-3 / 10 + 2) + 150 * (3 / 10) = 96 := by norm_num
-- Mistake 3: Burgers' 1-to-0 jump moves at 1/2 conserving u, at 2/3 conserving u^2/2.
example : ((0 : ℚ) ^ 2 / 2 - 1 ^ 2 / 2) / (0 - 1) = 1 / 2 := by norm_num
example : ((0 : ℚ) ^ 3 / 3 - 1 ^ 3 / 3) / (0 ^ 2 / 2 - 1 ^ 2 / 2) = 2 / 3 := by norm_num
-- Try: arriving at 60 cars/km, s = (0 - q(60))/90 = -36 km/h; an 800 m braking zone breaks at 20 s.
example : ((0 : ℚ) - 90 * 60 * (1 - 60 / 150)) / (150 - 60) = -36 := by norm_num
example : 1 / ((6 / 5 : ℚ) * 150) * 3600 = 20 := by norm_num

#print axioms step_interval_integral
#print axioms rankine_hugoniot
#print axioms breaking_time
#print axioms wave_speed_lt_car_speed
