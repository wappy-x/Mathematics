-- Viscosity: Newton's law of viscosity, the force balance on a plug and no-slip at the wall give the parabolic profile and Poiseuille's law Δp = 8 μ L Q / (π R⁴), the pump power equals the viscous heating, and the laminar friction factor is 64/Re.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.Calculus.MeanValue

open Real intervalIntegral

/-- Poiseuille's law. In steady flow along a round pipe of radius `R > 0` and length `L > 0`,
take the speed `u r` and the shear stress `τ r` at distance `r` from the axis. Suppose Newton's
law of viscosity `τ = -μ du/dr` holds across the bore (with `μ > 0`), the pressure drop `Δp` on
every plug of radius `0 < r ≤ R` balances the drag on its skin, `Δp π r² = τ(r) 2π r L`, and the
fluid sticks to the wall, `u R = 0`. Then with `G = Δp / L` the speed is the parabola
`u r = G/(4μ) (R² - r²)`, and the flow `Q = ∫₀ᴿ u(r) 2π r dr` satisfies `Δp = 8 μ L Q / (π R⁴)`. -/
theorem poiseuille_law (μ R L Δp : ℝ) (hμ : 0 < μ) (hR : 0 < R) (hL : 0 < L)
    (u τ : ℝ → ℝ)
    (hnewton : ∀ r ∈ Set.Icc 0 R, HasDerivAt u (-(τ r) / μ) r)
    (hbalance : ∀ r ∈ Set.Ioc 0 R, Δp * (π * r ^ 2) = τ r * (2 * π * r * L))
    (hwall : u R = 0) :
    (∀ r ∈ Set.Icc 0 R, u r = Δp / L / (4 * μ) * (R ^ 2 - r ^ 2)) ∧
    Δp = 8 * μ * L * (∫ r in (0 : ℝ)..R, u r * (2 * π * r)) / (π * R ^ 4) := by
  have hτ : ∀ r ∈ Set.Ioc 0 R, τ r = Δp * r / (2 * L) := by
    intro r hr
    have h := hbalance r hr
    have hr0 : 0 < r := hr.1
    field_simp
    have hπ : 0 < π := pi_pos
    nlinarith [mul_pos hπ hr0, mul_pos (mul_pos hπ hr0) hr0]
  set v : ℝ → ℝ := fun r => u r - Δp / L / (4 * μ) * (R ^ 2 - r ^ 2) with hv
  have hvd : ∀ r ∈ Set.Icc 0 R, HasDerivAt v (-(τ r) / μ - Δp / L / (4 * μ) * (0 - 2 * r)) r := by
    intro r hr
    have h1 := hnewton r hr
    have h2 : HasDerivAt (fun s : ℝ => R ^ 2 - s ^ 2) (0 - 2 * r) r := by
      have := ((hasDerivAt_pow 2 r).const_sub (R ^ 2))
      simpa using this
    exact h1.sub (h2.const_mul _)
  have hv0 : ∀ r ∈ Set.Ioc 0 R, HasDerivAt v 0 r := by
    intro r hr
    have := hvd r ⟨hr.1.le, hr.2⟩
    convert this using 1
    rw [hτ r hr]
    field_simp
    ring
  have hvc : ContinuousOn v (Set.Icc 0 R) := fun r hr => (hvd r hr).continuousAt.continuousWithinAt
  have hconst : ∀ x ∈ Set.Icc 0 R, v x = v R := by
    intro x hx
    rcases eq_or_lt_of_le hx.2 with h | h
    · rw [h]
    · obtain ⟨c, hc, hc'⟩ := exists_hasDerivAt_eq_slope v (fun _ => (0 : ℝ)) h
        (hvc.mono (Set.Icc_subset_Icc hx.1 le_rfl))
        (fun y hy => hv0 y ⟨lt_of_le_of_lt hx.1 hy.1, hy.2.le⟩)
      have hne : R - x ≠ 0 := sub_ne_zero.2 h.ne'
      rw [eq_comm, div_eq_zero_iff] at hc'
      rcases hc' with h' | h'
      · linarith
      · exact absurd h' hne
  have hvR : v R = 0 := by simp [hv, hwall]
  have hprof : ∀ r ∈ Set.Icc 0 R, u r = Δp / L / (4 * μ) * (R ^ 2 - r ^ 2) := by
    intro r hr
    have := hconst r hr
    rw [hvR] at this
    simp only [hv] at this
    linarith
  refine ⟨hprof, ?_⟩
  have hint : (∫ r in (0 : ℝ)..R, u r * (2 * π * r)) =
      ∫ r in (0 : ℝ)..R, Δp / L / (4 * μ) * (R ^ 2 - r ^ 2) * (2 * π * r) := by
    apply intervalIntegral.integral_congr
    intro r hr
    rw [Set.uIcc_of_le hR.le] at hr
    simp only [hprof r hr]
  rw [hint]
  set G := Δp / L / (4 * μ) with hG
  have hF : ∀ x ∈ Set.uIcc (0 : ℝ) R, HasDerivAt
      (fun r => G * (2 * π) * (R ^ 2 * r ^ 2 / 2 - r ^ 4 / 4))
      (G * (R ^ 2 - x ^ 2) * (2 * π * x)) x := by
    intro x _
    have h := (((hasDerivAt_pow 2 x).const_mul (R ^ 2)).div_const 2).sub
      ((hasDerivAt_pow 4 x).div_const 4)
    convert h.const_mul (G * (2 * π)) using 1
    push_cast; ring
  rw [integral_eq_sub_of_hasDerivAt hF (Continuous.intervalIntegrable (by fun_prop : Continuous fun x =>
      G * (R ^ 2 - x ^ 2) * (2 * π * x)) 0 R)]
  have hπ : 0 < π := pi_pos
  rw [hG]
  field_simp
  ring

/-- The check by energy: for the laminar profile `u r = G/(4μ) (R² - r²)`, the heat made by
viscosity, `μ (du/dr)²` per cubic metre, integrated over the bore, equals the pump power per
metre `G Q`, where `Q = ∫₀ᴿ u(r) 2π r dr` is the flow. -/
theorem viscous_heating_eq_pump_power (μ R G : ℝ) (hμ : 0 < μ) (hR : 0 < R) :
    (∫ r in (0 : ℝ)..R, μ * (deriv (fun s => G / (4 * μ) * (R ^ 2 - s ^ 2)) r) ^ 2 * (2 * π * r)) =
      G * ∫ r in (0 : ℝ)..R, G / (4 * μ) * (R ^ 2 - r ^ 2) * (2 * π * r) := by
  have hd : ∀ r : ℝ, deriv (fun s => G / (4 * μ) * (R ^ 2 - s ^ 2)) r = G / (4 * μ) * (0 - 2 * r) := by
    intro r
    have h2 : HasDerivAt (fun s : ℝ => R ^ 2 - s ^ 2) (0 - 2 * r) r := by
      have := ((hasDerivAt_pow 2 r).const_sub (R ^ 2))
      simpa using this
    exact (h2.const_mul _).deriv
  simp only [hd]
  have hF1 : ∀ x ∈ Set.uIcc (0 : ℝ) R, HasDerivAt
      (fun r => μ * (G / (4 * μ)) ^ 2 * 4 * (2 * π) * (r ^ 4 / 4))
      (μ * (G / (4 * μ) * (0 - 2 * x)) ^ 2 * (2 * π * x)) x := by
    intro x _
    convert ((hasDerivAt_pow 4 x).div_const 4).const_mul (μ * (G / (4 * μ)) ^ 2 * 4 * (2 * π)) using 1
    push_cast; ring
  have hF2 : ∀ x ∈ Set.uIcc (0 : ℝ) R, HasDerivAt
      (fun r => G / (4 * μ) * (2 * π) * (R ^ 2 * r ^ 2 / 2 - r ^ 4 / 4))
      (G / (4 * μ) * (R ^ 2 - x ^ 2) * (2 * π * x)) x := by
    intro x _
    have h := (((hasDerivAt_pow 2 x).const_mul (R ^ 2)).div_const 2).sub
      ((hasDerivAt_pow 4 x).div_const 4)
    convert h.const_mul (G / (4 * μ) * (2 * π)) using 1
    push_cast; ring
  rw [integral_eq_sub_of_hasDerivAt hF1 (Continuous.intervalIntegrable (by fun_prop : Continuous fun x =>
      μ * (G / (4 * μ) * (0 - 2 * x)) ^ 2 * (2 * π * x)) 0 R),
    integral_eq_sub_of_hasDerivAt hF2 (Continuous.intervalIntegrable (by fun_prop : Continuous fun x =>
      G / (4 * μ) * (R ^ 2 - x ^ 2) * (2 * π * x)) 0 R)]
  field_simp
  ring

/-- The laminar law in friction-factor form: with mean speed `V = G R² / (8 μ)` (half the
centre speed), bore `D = 2R`, Darcy friction factor `f = G · 2D / (ρ V²)` and Reynolds number
`Re = ρ V D / μ`, the friction factor is `f = 64 / Re`. -/
theorem laminar_friction_factor_eq_64_div_reynolds (μ ρ R G : ℝ) (hμ : 0 < μ) (hρ : 0 < ρ)
    (hR : 0 < R) (hG : 0 < G) :
    G * (2 * (2 * R)) / (ρ * (G * R ^ 2 / (8 * μ)) ^ 2) =
      64 / (ρ * (G * R ^ 2 / (8 * μ)) * (2 * R) / μ) := by
  field_simp
  ring

-- bore: 15 mm outside, 0.7 mm wall, so 13.6 mm inside
example : (15 : ℚ) - 2 * (7 / 10) = 68 / 5 := by norm_num
-- flow: 12 litres a minute is 12000 cm³ in 60 s, 200 cm³/s
example : (12 * 1000 : ℕ) / 60 = 200 := by decide
-- radius form against diameter form: 8 / R⁴ = 128 / D⁴ since 8 · 2⁴ = 128
example : (8 : ℕ) * 2 ^ 4 = 128 := by decide
-- D put into the radius form gives an answer 2⁴ = 16 times too small
example : (2 : ℕ) ^ 4 = 16 := by decide

#print axioms poiseuille_law
#print axioms viscous_heating_eq_pump_power
#print axioms laminar_friction_factor_eq_64_div_reynolds
