-- Steady-state error: for a loop gain with N integrators and a target A/s^(m+1), the final-value limit of s E(s) is zero when N > m, A/(1+K) when N = m = 0, A/K when N = m ≥ 1, and unbounded when N < m; the proportional room rests at A/(1 + k_c/U), and the room with integral action has zero step error and ramp error a/K_v.
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Topology.Algebra.Order.Field

open Filter Topology Set

/-- The whole table at once. Write the loop gain near zero as `L(s) = K M(s) / s^N`, where `N` is
the system type (the number of integrators), `K > 0` is the loop's low-frequency constant and
`M` is the rest of the loop, continuous at `0` and scaled so that `M(0) = 1`. Take the target
`R(s) = A / s^(m+1)`: `m = 0` is a step of size `A`, `m = 1` a ramp of slope `A`, `m = 2` a
parabola. The final-value limit of the error, `s E(s) = s R(s) / (1 + L(s))` as real `s` shrinks
to `0` from above, is
* zero when `N > m` (each extra integrator clears the next kind of target);
* `A / (1 + K)` when `N = m = 0` (the type-0 step offset, `K = K₀`);
* `A / K` when `N = m ≥ 1` (the ramp lag `a / K_v` for type 1, the parabola lag for type 2);
* unbounded when `N < m` and `A ≠ 0` (the error has no final value).
This is the transform-side computation; the card's stability hypothesis is what lets the final
value theorem read this limit as the room's actual final error. -/
theorem steady_state_error_by_system_type (N m : ℕ) (K A : ℝ) (hK : 0 < K)
    (M L : ℝ → ℝ) (hM : ContinuousAt M 0) (hM0 : M 0 = 1)
    (hL : ∀ᶠ s in 𝓝[>] (0 : ℝ), L s = K * M s / s ^ N) :
    (m < N →
      Tendsto (fun s : ℝ => s * (A / s ^ (m + 1)) / (1 + L s)) (𝓝[>] 0) (𝓝 0)) ∧
    (N = 0 → m = 0 →
      Tendsto (fun s : ℝ => s * (A / s ^ (m + 1)) / (1 + L s)) (𝓝[>] 0) (𝓝 (A / (1 + K)))) ∧
    (1 ≤ N → N = m →
      Tendsto (fun s : ℝ => s * (A / s ^ (m + 1)) / (1 + L s)) (𝓝[>] 0) (𝓝 (A / K))) ∧
    (N < m → A ≠ 0 →
      Tendsto (fun s : ℝ => |s * (A / s ^ (m + 1)) / (1 + L s)|) (𝓝[>] 0) atTop) := by
  have hev : ∀ᶠ s in 𝓝[>] (0 : ℝ), s * (A / s ^ (m + 1)) / (1 + L s)
      = A * s ^ N / s ^ m / (s ^ N + K * M s) := by
    filter_upwards [hL, self_mem_nhdsWithin] with s hs hpos
    have hs0 : s ≠ 0 := ne_of_gt hpos
    have hsN : s ^ N ≠ 0 := pow_ne_zero _ hs0
    have h1 : s * (A / s ^ (m + 1)) = A / s ^ m := by
      rw [pow_succ]; field_simp
    have h2 : 1 + L s = (s ^ N + K * M s) / s ^ N := by
      rw [hs]; field_simp
    rw [h1, h2, div_div_eq_mul_div]
    ring
  have hg : Tendsto (fun s : ℝ => s ^ N + K * M s) (𝓝[>] 0) (𝓝 ((0:ℝ) ^ N + K)) := by
    have : ContinuousAt (fun s : ℝ => s ^ N + K * M s) 0 :=
      (continuous_pow N).continuousAt.add (continuousAt_const.mul hM)
    have h := this.tendsto.mono_left (nhdsWithin_le_nhds (s := Ioi (0:ℝ)))
    simpa [hM0] using h
  have hgpos : (0:ℝ) < (0:ℝ) ^ N + K := add_pos_of_nonneg_of_pos (pow_nonneg le_rfl _) hK
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro hmN
    have hev1 : ∀ᶠ s in 𝓝[>] (0 : ℝ), s * (A / s ^ (m + 1)) / (1 + L s)
        = A * s ^ (N - m) / (s ^ N + K * M s) := by
      filter_upwards [hev, self_mem_nhdsWithin] with s hs hpos
      rw [hs, pow_sub₀ _ (ne_of_gt (show (0:ℝ) < s from hpos)) hmN.le]
      ring
    have hlim : Tendsto (fun s : ℝ => A * s ^ (N - m) / (s ^ N + K * M s)) (𝓝[>] 0)
        (𝓝 (A * (0:ℝ) ^ (N - m) / ((0:ℝ) ^ N + K))) := by
      refine Tendsto.div (tendsto_const_nhds.mul ?_) hg hgpos.ne'
      exact ((continuous_pow (N - m)).continuousAt.tendsto).mono_left nhdsWithin_le_nhds
    rw [zero_pow (by omega), mul_zero, zero_div] at hlim
    exact hlim.congr' (hev1.mono fun s hs => hs.symm)
  · intro hN hm
    subst hN; subst hm
    have hlim : Tendsto (fun s : ℝ => A / (s ^ 0 + K * M s)) (𝓝[>] 0)
        (𝓝 (A / ((0:ℝ) ^ 0 + K))) := tendsto_const_nhds.div hg hgpos.ne'
    simp only [pow_zero] at hlim ⊢
    refine hlim.congr' (hev.mono fun s hs => ?_)
    show _ = s * (A / s ^ (0 + 1)) / (1 + L s)
    rw [hs]; simp
  · intro hN hNm
    subst hNm
    have hlim : Tendsto (fun s : ℝ => A / (s ^ N + K * M s)) (𝓝[>] 0)
        (𝓝 (A / ((0:ℝ) ^ N + K))) := tendsto_const_nhds.div hg hgpos.ne'
    rw [zero_pow (by omega), zero_add] at hlim
    refine hlim.congr' ((hev.and self_mem_nhdsWithin).mono fun s hs => ?_)
    show _ = s * (A / s ^ (N + 1)) / (1 + L s)
    rw [hs.1]
    have : s ^ N ≠ 0 := pow_ne_zero _ (ne_of_gt (show (0:ℝ) < s from hs.2))
    field_simp
  · intro hNm hA
    have hev4 : ∀ᶠ s in 𝓝[>] (0 : ℝ), |A| / |s ^ N + K * M s| * (s⁻¹) ^ (m - N)
        = |s * (A / s ^ (m + 1)) / (1 + L s)| := by
      filter_upwards [hev, self_mem_nhdsWithin] with s hs hpos
      have hs0 : s ≠ 0 := ne_of_gt (show (0:ℝ) < s from hpos)
      rw [hs, abs_div, abs_div, abs_mul, inv_pow, abs_of_pos (pow_pos (show (0:ℝ) < s from hpos) _),
        abs_of_pos (pow_pos (show (0:ℝ) < s from hpos) _)]
      have : s ^ m = s ^ N * s ^ (m - N) := by rw [← pow_add]; congr 1; omega
      rw [this]
      have : s ^ N ≠ 0 := pow_ne_zero _ hs0
      have : s ^ (m - N) ≠ 0 := pow_ne_zero _ hs0
      field_simp
    have hC : Tendsto (fun s : ℝ => |A| / |s ^ N + K * M s|) (𝓝[>] 0)
        (𝓝 (|A| / |(0:ℝ) ^ N + K|)) :=
      tendsto_const_nhds.div hg.abs (abs_pos.mpr hgpos.ne').ne'
    have hI : Tendsto (fun s : ℝ => (s⁻¹) ^ (m - N)) (𝓝[>] 0) atTop :=
      (tendsto_pow_atTop (by omega)).comp tendsto_inv_nhdsGT_zero
    exact (hC.pos_mul_atTop (div_pos (abs_pos.mpr hA) (abs_pos.mpr hgpos.ne')) hI).congr' hev4

/-- The heat balance at rest for a proportional thermostat. A thermostat of gain `k_c ≥ 0` watts
per kelvin heats a room whose walls leak `U > 0` watts per kelvin, with the setpoint `A` kelvin
above outdoors. At rest the heat in, `k_c e`, equals the heat out, `U (A - e)`, exactly when the
error is `e = A / (1 + K₀)` with `K₀ = k_c / U`: an error is needed to make any heat at all. -/
theorem proportional_room_rest_error (kc U A e : ℝ) (hkc : 0 ≤ kc) (hU : 0 < U) :
    kc * e = U * (A - e) ↔ e = A / (1 + kc / U) := by
  have hpos : 0 < 1 + kc / U := by positivity
  rw [eq_div_iff hpos.ne']
  have hU' : U ≠ 0 := hU.ne'
  constructor
  · intro h
    field_simp
    linarith
  · intro h
    field_simp at h
    linarith

/-- The room with integral action. With thermostat gain `k_c`, wall loss `U`, room and pipe lags
`τ_r`, `τ_p` and integral time `T_i`, all positive, the loop gain is
`L(s) = (k_c / U)(1 + 1/(T_i s)) / ((τ_r s + 1)(τ_p s + 1))`. Its final-value step error is zero
for a step of any size `A`, and its ramp error for a ramp of slope `a` is `a / K_v` with velocity
constant `K_v = k_c / (U T_i)`; the lags do not affect either. -/
theorem room_pi_loop_step_and_ramp_error (kc U τr τp Ti A a : ℝ) (hkc : 0 < kc) (hU : 0 < U)
    (hτr : 0 < τr) (hτp : 0 < τp) (hTi : 0 < Ti) :
    Tendsto (fun s : ℝ => s * (A / s) /
        (1 + kc / U * (1 + 1 / (Ti * s)) / ((τr * s + 1) * (τp * s + 1)))) (𝓝[>] 0) (𝓝 0) ∧
    Tendsto (fun s : ℝ => s * (a / s ^ 2) /
        (1 + kc / U * (1 + 1 / (Ti * s)) / ((τr * s + 1) * (τp * s + 1)))) (𝓝[>] 0)
      (𝓝 (a / (kc / (U * Ti)))) := by
  set c := kc / U with hc
  have hcpos : 0 < c := div_pos hkc hU
  -- denominator after clearing fractions
  have hD : Tendsto (fun s : ℝ => Ti * s * ((τr * s + 1) * (τp * s + 1)) + c * (Ti * s + 1))
      (𝓝[>] 0) (𝓝 (Ti * 0 * ((τr * 0 + 1) * (τp * 0 + 1)) + c * (Ti * 0 + 1))) := by
    have : Continuous (fun s : ℝ => Ti * s * ((τr * s + 1) * (τp * s + 1)) + c * (Ti * s + 1)) := by
      fun_prop
    exact (this.tendsto 0).mono_left nhdsWithin_le_nhds
  have hP : Tendsto (fun s : ℝ => Ti * ((τr * s + 1) * (τp * s + 1)))
      (𝓝[>] 0) (𝓝 (Ti * ((τr * 0 + 1) * (τp * 0 + 1)))) := by
    have : Continuous (fun s : ℝ => Ti * ((τr * s + 1) * (τp * s + 1))) := by fun_prop
    exact (this.tendsto 0).mono_left nhdsWithin_le_nhds
  have hD0 : Ti * 0 * ((τr * 0 + 1) * (τp * 0 + 1)) + c * (Ti * 0 + 1) = c := by ring
  rw [hD0] at hD
  have hkey : ∀ s : ℝ, 0 < s →
      1 + c * (1 + 1 / (Ti * s)) / ((τr * s + 1) * (τp * s + 1))
        = (Ti * s * ((τr * s + 1) * (τp * s + 1)) + c * (Ti * s + 1)) /
          (Ti * s * ((τr * s + 1) * (τp * s + 1))) := by
    intro s hs
    have h1 : 0 < τr * s + 1 := by positivity
    have h2 : 0 < τp * s + 1 := by positivity
    have h3 : 0 < Ti * s := by positivity
    field_simp
  constructor
  · have hlim := (tendsto_const_nhds (x := A)).mul ((hP.mul (tendsto_id.mono_left nhdsWithin_le_nhds)).div hD hcpos.ne')
    simp only [id, mul_zero, zero_div] at hlim
    refine hlim.congr' (eventually_of_mem self_mem_nhdsWithin fun s (hs : 0 < s) => ?_)
    show A * (Ti * ((τr * s + 1) * (τp * s + 1)) * s /
        (Ti * s * ((τr * s + 1) * (τp * s + 1)) + c * (Ti * s + 1)))
      = s * (A / s) / (1 + c * (1 + 1 / (Ti * s)) / ((τr * s + 1) * (τp * s + 1)))
    rw [hkey s hs]
    have h1 : 0 < τr * s + 1 := by positivity
    have h2 : 0 < τp * s + 1 := by positivity
    have h3 : 0 < Ti * s * ((τr * s + 1) * (τp * s + 1)) + c * (Ti * s + 1) := by positivity
    field_simp
  · have hlim := (tendsto_const_nhds (x := a)).mul (hP.div hD hcpos.ne')
    have hval : a * (Ti * ((τr * 0 + 1) * (τp * 0 + 1)) / c) = a / (kc / (U * Ti)) := by
      rw [hc]; simp only [mul_zero, zero_add, mul_one]; field_simp
    rw [hval] at hlim
    refine hlim.congr' (eventually_of_mem self_mem_nhdsWithin fun s (hs : 0 < s) => ?_)
    show a * (Ti * ((τr * s + 1) * (τp * s + 1)) /
        (Ti * s * ((τr * s + 1) * (τp * s + 1)) + c * (Ti * s + 1)))
      = s * (a / s ^ 2) / (1 + c * (1 + 1 / (Ti * s)) / ((τr * s + 1) * (τp * s + 1)))
    rw [hkey s hs]
    have h1 : 0 < τr * s + 1 := by positivity
    have h2 : 0 < τp * s + 1 := by positivity
    have h3 : 0 < Ti * s * ((τr * s + 1) * (τp * s + 1)) + c * (Ti * s + 1) := by positivity
    field_simp

-- The room: k_c = 1900 W/K, U = 100 W/K, setpoint 20 °C, outdoors 0 °C, T_i = 30 min.
-- Position constant K₀ = 1900 / 100 = 19.
example : (1900 : ℚ) / 100 = 19 := by norm_num
-- Proportional offset 20 / (1 + 19) = 1 °C.
example : (20 : ℚ) / (1 + 19) = 1 := by norm_num
-- Heat balance: thermostat 1900 × 1 = walls 100 × (19 − 0) = 1900 W.
example : (1900 : ℚ) * 1 = 100 * (19 - 0) ∧ (100 : ℚ) * (19 - 0) = 1900 := by norm_num
-- Power the integral loop holds: 100 × (20 − 0) = 2000 W.
example : (100 : ℚ) * (20 - 0) = 2000 := by norm_num
-- Cold front, proportional: (20 − (−3)) / (1 + 19) = 23/20 °C.
example : ((20 : ℚ) - (-3)) / (1 + 19) = 23 / 20 := by norm_num
-- Velocity constant K_v = 19 / 30 per minute; ramp slope 2 K per hour = 1/30 K per minute.
example : (1900 : ℚ) / (100 * 30) = 19 / 30 := by norm_num
example : (2 : ℚ) / 60 = 1 / 30 := by norm_num
-- Ramp error (1/30) / (19/30) = 1/19 °C; ramp lag in time 1 / K_v = 30/19 min.
example : ((1 : ℚ) / 30) / (19 / 30) = 1 / 19 := by norm_num
example : (1 : ℚ) / (19 / 30) = 30 / 19 := by norm_num
-- If 22 °C were held with proportional control: 22 / (1 + 19) = 11/10 °C.
example : (22 : ℚ) / (1 + 19) = 11 / 10 := by norm_num
-- −15 °C outdoors, radiator capped at 3000 W: 100 × 35 = 3500 W needed; (3500 − 3000)/100 = 5 °C.
example : (100 : ℚ) * (20 - (-15)) = 3500 ∧ ((3500 : ℚ) - 3000) / 100 = 5 := by norm_num
-- Draughty room U = 150 W/K: 20 / (1 + 1900/150) = 60/41 °C.
example : (20 : ℚ) / (1 + 1900 / 150) = 60 / 41 := by norm_num
-- Thermostat gain 3900 W/K: 20 / (1 + 39) = 1/2 °C.
example : (20 : ℚ) / (1 + 3900 / 100) = 1 / 2 := by norm_num
-- Integral time 15 min: (1/30) / (19/15) = 1/38 °C.
example : ((1 : ℚ) / 30) / (1900 / (100 * 15)) = 1 / 38 := by norm_num

#print axioms steady_state_error_by_system_type
#print axioms proportional_room_rest_error
#print axioms room_pi_loop_step_and_ramp_error
