-- PID control: lambda-tuned PI on a lag-plus-delay room gives the loop gain e^(-θs)/((λ+θ)s) with known crossover, phase margin and gain margin, proportional control alone leaves the offset r/(1 + K Kp), and a settled PID loop has zero error.
import Mathlib.Analysis.SpecialFunctions.Complex.Arg
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Tactic.NormNum

open Complex

/-! The room is `G(s) = K e^(-θ s) / (τ s + 1)`: gain `K`, lag `τ`, delay `θ`, all positive.
Lambda tuning with chosen closed-loop time constant `lam > 0` gives the PI controller
`C(s) = Kp (1 + 1/(Ti s))` with `Kp = τ / (K (lam + θ))` and `Ti = τ`.
The loop gain is `L = C G`, read at `s = j ω` (here `j` is Mathlib's `Complex.I`). -/

/-- Lambda tuning, Step 5 and its detailed proof: with `Kp = τ/(K(λ + θ))` and `Ti = τ`,
the controller's zero cancels the room's lag, so for every frequency `ω > 0` the loop gain is
`L(jω) = e^(-jθω) / ((λ + θ) jω)`, of size `1/((λ + θ) ω)`. At the crossover
`ω_c = 1/(λ + θ)` its phase is `-π/2 - θ/(λ + θ)`, so the phase margin is
`π/2 - θ/(λ + θ)`; at `ω_180 = π/(2θ)` it equals the negative real number
`-2θ/(π(λ + θ))`, so the gain margin is `π(λ + θ)/(2θ)`. -/
theorem lambda_pi_loop_gain_and_margins (K τ θ lam : ℝ) (hK : 0 < K) (hτ : 0 < τ)
    (hθ : 0 < θ) (hlam : 0 < lam) :
    let Kp : ℝ := τ / (K * (lam + θ))
    let C : ℂ → ℂ := fun s => Kp * (1 + 1 / (τ * s))
    let G : ℂ → ℂ := fun s => K * Complex.exp (-(θ * s)) / (τ * s + 1)
    let L : ℂ → ℂ := fun s => C s * G s
    (∀ ω : ℝ, 0 < ω → L (ω * I) = Complex.exp (-(θ * ω * I)) / ((lam + θ) * ω * I)) ∧
    (∀ ω : ℝ, 0 < ω → ‖L (ω * I)‖ = 1 / ((lam + θ) * ω)) ∧
    ‖L ((1 / (lam + θ) : ℝ) * I)‖ = 1 ∧
    Complex.arg (L ((1 / (lam + θ) : ℝ) * I)) = -(Real.pi / 2) - θ / (lam + θ) ∧
    L ((Real.pi / (2 * θ) : ℝ) * I) = -(((2 * θ) / (Real.pi * (lam + θ)) : ℝ) : ℂ) := by
  intro Kp C G L
  have hlt : 0 < lam + θ := by linarith
  have hL : ∀ ω : ℝ, 0 < ω → L (ω * I) = Complex.exp (-(θ * ω * I)) / ((lam + θ) * ω * I) := by
    intro ω hω
    have hω0 : (ω : ℂ) ≠ 0 := by exact_mod_cast hω.ne'
    have hτ0 : (τ : ℂ) ≠ 0 := by exact_mod_cast hτ.ne'
    have hK0 : (K : ℂ) ≠ 0 := by exact_mod_cast hK.ne'
    have hs0 : (lam : ℂ) + θ ≠ 0 := by exact_mod_cast hlt.ne'
    have hden : (τ : ℂ) * (ω * I) + 1 ≠ 0 := by
      intro h
      have := congrArg Complex.re h
      simp at this
    simp only [L, C, G, Kp]
    push_cast
    have hden' : 1 + (τ : ℂ) * ω * I ≠ 0 := by
      intro h
      have := congrArg Complex.re h
      simp at this
    field_simp
    ring_nf
    rw [← add_one_mul, add_comm, mul_inv_cancel₀ hden']
  have hN : ∀ ω : ℝ, 0 < ω → ‖L (ω * I)‖ = 1 / ((lam + θ) * ω) := by
    intro ω hω
    rw [hL ω hω, norm_div]
    have h1 : ‖Complex.exp (-(θ * ω * I))‖ = 1 := by
      have : -((θ : ℂ) * ω * I) = ((-(θ * ω) : ℝ) : ℂ) * I := by push_cast; ring
      rw [this, norm_exp_ofReal_mul_I]
    have h2 : ‖((lam : ℂ) + θ) * ω * I‖ = (lam + θ) * ω := by
      have : ((lam : ℂ) + θ) * ω * I = (((lam + θ) * ω : ℝ) : ℂ) * I := by push_cast; ring
      rw [this, norm_mul, Complex.norm_I, mul_one, Complex.norm_real, Real.norm_eq_abs,
        abs_of_pos (by positivity)]
    rw [h1, h2]
  have hc : (0 : ℝ) < 1 / (lam + θ) := by positivity
  refine ⟨hL, hN, ?_, ?_, ?_⟩
  · rw [hN _ hc]
    field_simp
  · rw [hL _ hc]
    have hq : 0 < θ / (lam + θ) := by positivity
    have hq1 : θ / (lam + θ) < 1 := by rw [div_lt_one hlt]; linarith
    have hs0 : (lam : ℂ) + θ ≠ 0 := by exact_mod_cast hlt.ne'
    have : Complex.exp (-(θ * ((1 / (lam + θ) : ℝ) : ℂ) * I)) / ((lam + θ) * ((1 / (lam + θ) : ℝ) : ℂ) * I)
        = Complex.exp (((-(Real.pi / 2) - θ / (lam + θ) : ℝ) : ℂ) * I) := by
      have e1 : (((-(Real.pi / 2) - θ / (lam + θ) : ℝ) : ℂ) * I)
          = (-(θ * ((1 / (lam + θ) : ℝ) : ℂ) * I)) + (-(Real.pi / 2 * I)) := by
        push_cast; ring
      rw [e1, Complex.exp_add, Complex.exp_neg (Real.pi / 2 * I), exp_pi_div_two_mul_I]
      push_cast
      field_simp
    rw [this, arg_exp_mul_I, toIocMod_eq_self]
    have := Real.two_le_pi
    constructor <;> linarith
  · rw [hL _ (by positivity)]
    have hpi : (Real.pi : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
    have hθ0 : (θ : ℂ) ≠ 0 := by exact_mod_cast hθ.ne'
    have hs0 : (lam : ℂ) + θ ≠ 0 := by exact_mod_cast hlt.ne'
    have e1 : -((θ : ℂ) * ((Real.pi / (2 * θ) : ℝ) : ℂ) * I) = -(Real.pi / 2 * I) := by
      push_cast; field_simp
    rw [e1, Complex.exp_neg, exp_pi_div_two_mul_I]
    push_cast
    field_simp
    simp

/-- Step 1: proportional action alone leaves an offset. If the room at rest sits at
`y = K u`, the controller sets `u = Kp e`, and the error is `e = r - y`, then the error at
rest is `e = r / (1 + K Kp)`, whatever the gains (room gain and proportional gain
nonnegative). -/
theorem p_only_rest_error (K Kp r y u e : ℝ) (hK : 0 ≤ K) (hKp : 0 ≤ Kp)
    (hy : y = K * u) (hu : u = Kp * e) (he : e = r - y) :
    e = r / (1 + K * Kp) := by
  have hpos : 0 < 1 + K * Kp := by positivity
  rw [eq_div_iff hpos.ne']
  subst hy hu
  linarith

/-- Step 2: any settled state of a PI or PID loop has zero error. The heater setting is
`u(t) = Kp e(t) + Ki ∫₀ᵗ e + Kd e'(t)` with `Ki ≠ 0` and a continuous error `e`.
If from some time `t₀` on the error stays at a constant `c` and the heater setting stays
constant, then `c = 0`. -/
theorem pid_settled_error_is_zero (Kp Ki Kd t₀ c : ℝ) (e u : ℝ → ℝ) (hKi : Ki ≠ 0)
    (he : Continuous e)
    (hu : ∀ t, u t = Kp * e t + Ki * (∫ x in (0 : ℝ)..t, e x) + Kd * deriv e t)
    (hsettle_e : ∀ t, t₀ ≤ t → e t = c) (hsettle_u : ∀ t, t₀ ≤ t → u t = u t₀) :
    c = 0 := by
  have hd : ∀ t, t₀ < t → deriv e t = 0 := by
    intro t ht
    have hev : e =ᶠ[nhds t] fun _ => c := by
      filter_upwards [lt_mem_nhds ht] with x hx
      exact hsettle_e x hx.le
    rw [hev.deriv_eq]
    simp
  have h1 := hu (t₀ + 1)
  have h2 := hu (t₀ + 2)
  rw [hsettle_u _ (by linarith), hsettle_e _ (by linarith), hd _ (by linarith)] at h1
  rw [hsettle_u _ (by linarith), hsettle_e _ (by linarith), hd _ (by linarith)] at h2
  have hint : (∫ x in (0 : ℝ)..(t₀ + 2), e x) - (∫ x in (0 : ℝ)..(t₀ + 1), e x)
      = ∫ x in (t₀ + 1)..(t₀ + 2), e x :=
    intervalIntegral.integral_interval_sub_left (he.intervalIntegrable _ _)
      (he.intervalIntegrable _ _)
  have hc : ∫ x in (t₀ + 1)..(t₀ + 2), e x = c := by
    rw [intervalIntegral.integral_congr (g := fun _ => c)]
    · simp; ring
    · intro x hx
      rw [Set.uIcc_of_le (by linarith)] at hx
      exact hsettle_e x (by linarith [hx.1])
  have : Ki * c = 0 := by
    rw [← hc, ← hint, mul_sub]
    linarith
  rcases mul_eq_zero.mp this with h | h
  · exact absurd h hKi
  · exact h

/-! The card's worked numbers, exactly (decimals written as fractions). -/

-- Model used: K = 2 °C/kW, τ = 3 min, θ = 1 min, λ = 1 min.
-- Lambda PI: Kp = 3 / (2 × (1 + 1)) = 0.750 kW/°C, Ti = τ = 3, Ki = Kp / Ti = 0.250.
example : (3 : ℚ) / (2 * (1 + 1)) = 3 / 4 := by norm_num
example : ((3 : ℚ) / 4) / 3 = 1 / 4 := by norm_num
-- Ziegler–Nichols PID: Kp = 1.2 × 3 / (2 × 1) = 1.8, Ti = 2 × 1 = 2, Td = 1/2,
-- Ki = Kp / Ti = 0.9, Kd = Kp Td = 0.9.
example : (6 / 5 : ℚ) * 3 / (2 * 1) = 9 / 5 := by norm_num
example : ((9 : ℚ) / 5) / 2 = 9 / 10 ∧ ((9 : ℚ) / 5) * (1 / 2) = 9 / 10 := by norm_num
-- P only, Kp = 1.8: a 1 °C step leaves 1/(1 + 2 × 1.8) = 5/23 ≈ 0.2174 °C of error.
example : (1 : ℚ) / (1 + 2 * (9 / 5)) = 5 / 23 := by norm_num
-- Door debt |d| / Ki with |d| = 0.5 kW: 0.5/0.9 = 5/9 ≈ 0.5556 (ZN), 0.5/0.25 = 2 (lambda).
example : ((1 : ℚ) / 2) / (9 / 10) = 5 / 9 ∧ ((1 : ℚ) / 2) / (1 / 4) = 2 := by norm_num
-- Lambda loop: crossover ω_c = 1/(λ + θ) = 1/2, and θ ω_c = 1/2 rad off the 90°.
example : (1 : ℚ) / (1 + 1) = 1 / 2 ∧ (1 : ℚ) * (1 / 2) = 1 / 2 := by norm_num
-- Lambda loop with λ = θ = 1: gain margin π(λ + θ)/(2θ) = π, and the delay may grow to
-- (λ + θ) π/2 = π min before the loop oscillates.
example : Real.pi * (1 + 1) / (2 * 1) = Real.pi := by norm_num
example : ((1 : ℝ) + 1) * (Real.pi / 2) = Real.pi := by ring
-- Doubled delay θ = 2 with the same lambda gains (λ + θ = 2 still): GM = π · 2 / (2 · 2) = π/2.
example : Real.pi * 2 / (2 * 2) = Real.pi / 2 := by ring
-- Radiator limit: 1.5 kW more at K = 2 °C/kW tops out at 20 + 3 = 23 °C;
-- a 4 °C setpoint asks for 4 / 2 = 2 kW extra.
example : (20 : ℚ) + 2 * (3 / 2) = 23 ∧ (4 : ℚ) / 2 = 2 := by norm_num
-- Two-point fit: τ = 1.5 (t63 - t28) inverts t28 = θ + τ/3, t63 = θ + τ.
example (θ τ : ℚ) : (3 / 2) * ((θ + τ) - (θ + τ / 3)) = τ := by ring

#print axioms lambda_pi_loop_gain_and_margins
#print axioms p_only_rest_error
#print axioms pid_settled_error_is_zero
