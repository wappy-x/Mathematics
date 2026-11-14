-- Sensitivity functions: for a loop with plant P and controller C, S + T = 1, every output is a sum of gang-of-four paths, and the draught's area is d0 / Ki.
import Mathlib.Analysis.Complex.Basic
import Mathlib.Topology.Algebra.Field
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.NormNum

open Filter Topology

/-- The sensitivity S = 1/(1+PC) plus the complementary sensitivity T = PC/(1+PC) is exactly 1,
as complex numbers, at every frequency where the loop is defined (1 + PC is not zero). -/
theorem sensitivity_add_complementary_sensitivity_eq_one (P C : ℂ) (h : 1 + P * C ≠ 0) :
    1 / (1 + P * C) + P * C / (1 + P * C) = 1 := by
  rw [← add_div, div_self h]

/-- Solving the loop Y = P(U + D), U = C(R - Y - N): the room, the heater and the error
are each a sum of the three inputs through the gang of four,
y = T r + PS d - T n, u = CS r - T d - CS n, e = S r - PS d + T n. -/
theorem loop_outputs_through_gang_of_four (P C R D N Y U : ℂ) (h : 1 + P * C ≠ 0)
    (hY : Y = P * (U + D)) (hU : U = C * (R - Y - N)) :
    Y = P * C / (1 + P * C) * R + P / (1 + P * C) * D - P * C / (1 + P * C) * N ∧
    U = C / (1 + P * C) * R - P * C / (1 + P * C) * D - C / (1 + P * C) * N ∧
    R - Y = 1 / (1 + P * C) * R - P / (1 + P * C) * D + P * C / (1 + P * C) * N := by
  have hY' : Y * (1 + P * C) = P * C * R + P * D - P * C * N := by
    rw [hU] at hY; linear_combination hY
  have hYe : Y = P * C / (1 + P * C) * R + P / (1 + P * C) * D - P * C / (1 + P * C) * N := by
    field_simp
    linear_combination hY'
  refine ⟨hYe, ?_, ?_⟩
  · have hU' : U * (1 + P * C) = C * R - P * C * D - C * N := by
      rw [hY] at hU; linear_combination hU
    rw [eq_div_of_mul_eq h hU']
    ring
  · rw [hYe]
    field_simp
    ring

/-- For the room P(s) = K/(τ s + 1) under the PI controller C(s) = Kp + Ki/s, the area under the
dip after a step draught of size d0, the limit of PS(s) d0 / s as s → 0, is d0 / Ki:
the room gain K cancels. -/
theorem draught_area_eq_d0_div_Ki (K τ Kp Ki d0 : ℂ) (hK : K ≠ 0) (hKi : Ki ≠ 0) :
    Tendsto
      (fun s : ℂ =>
        (K / (τ * s + 1)) / (1 + (K / (τ * s + 1)) * (Kp + Ki / s)) * d0 / s)
      (𝓝[≠] 0) (𝓝 (d0 / Ki)) := by
  set g : ℂ → ℂ := fun s => K * d0 / ((τ * s + 1) * s + K * Kp * s + K * Ki) with hg
  have hden : Continuous fun s : ℂ => (τ * s + 1) * s + K * Kp * s + K * Ki := by fun_prop
  have h0 : (τ * 0 + 1) * 0 + K * Kp * 0 + K * Ki ≠ 0 := by simpa using mul_ne_zero hK hKi
  have hgc : ContinuousAt g 0 := by
    exact (continuousAt_const).div hden.continuousAt h0
  have hg0 : g 0 = d0 / Ki := by
    simp only [hg]; field_simp; ring
  have hlim : Tendsto g (𝓝[≠] 0) (𝓝 (d0 / Ki)) := by
    rw [← hg0]; exact hgc.tendsto.mono_left nhdsWithin_le_nhds
  have e1 : ∀ᶠ s in 𝓝 (0:ℂ), (τ * s + 1) * s + K * Kp * s + K * Ki ≠ 0 :=
    hden.continuousAt.eventually_ne h0
  have e2 : ∀ᶠ s in 𝓝 (0:ℂ), τ * s + 1 ≠ 0 := by
    have hc : Continuous fun s : ℂ => τ * s + 1 := by fun_prop
    exact hc.continuousAt.eventually_ne (by simp)
  refine hlim.congr' ?_
  filter_upwards [nhdsWithin_le_nhds e1, nhdsWithin_le_nhds e2, self_mem_nhdsWithin] with s h1 h2 h3
  have hs : s ≠ 0 := h3
  have hB : 1 + K / (τ * s + 1) * (Kp + Ki / s) ≠ 0 := by
    have : 1 + K / (τ * s + 1) * (Kp + Ki / s)
        = ((τ * s + 1) * s + K * Kp * s + K * Ki) / ((τ * s + 1) * s) := by
      field_simp; ring
    rw [this]; exact div_ne_zero h1 (mul_ne_zero h2 hs)
  simp only [hg]
  field_simp
  ring

-- Worked numbers, K = 2, τ = 20, Kp = 2, Ki = 1/5, d0 = -1/2.
-- No thermostat: settled change K d0 = -1.
example : (2 : ℚ) * (-1/2) = -1 := by norm_num
-- Closed-loop polynomial: τ s² + (1 + K Kp) s + K Ki = 20 s² + 5 s + 2/5.
example : (1 : ℚ) + 2 * 2 = 5 ∧ (2 : ℚ) * (1/5) = 2/5 := by norm_num
-- Decay rate α = 5 / (2 × 20) = 1/8.
example : (5 : ℚ) / (2 * 20) = 1/8 := by norm_num
-- Area under the dip: d0 / Ki = (-1/2) / (1/5) = -5/2 degree-minutes.
example : ((-1/2 : ℚ)) / (1/5) = -5/2 := by norm_num
-- Pole-cancelling design: Ki = Kp / τ = 2/20 = 1/10, area d0 / Ki = -5.
example : (2 : ℚ) / 20 = 1/10 ∧ ((-1/2 : ℚ)) / (1/10) = -5 := by norm_num
-- A 5 degree setpoint step asks for Kp × 5 = 10 kW at the first instant.
example : (2 : ℚ) * 5 = 10 := by norm_num

#print axioms sensitivity_add_complementary_sensitivity_eq_one
#print axioms loop_outputs_through_gang_of_four
#print axioms draught_area_eq_d0_div_Ki
