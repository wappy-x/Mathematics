-- Nondimensionalisation: rescaling the pipe start-up equation by U, R and T = ρU/G leaves one coefficient ε = μU/(GR²), which equals 8/(f Re) and is exactly 1/8 for laminar flow.
import Mathlib.Analysis.Calculus.Deriv.CompMul
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring

/-- Water starting from rest in a long straight pipe obeys
`ρ ∂u/∂t = G + μ (1/r) ∂/∂r (r ∂u/∂r)` inside the pipe, with `u = 0` at the wall `r = R`
and `u = 0` when the pump starts. Measure speed in units of the design speed `U`, radius in
units of `R`, and time in units of `T = ρU/G`. Then the rescaled speed `u* = u/U` obeys
`∂u*/∂τ = 1 + ε (1/r*) ∂/∂r* (r* ∂u*/∂r*)` with the single coefficient `ε = μU/(GR²)`,
`u* = 0` at the wall `r* = 1`, and `u* = 0` at `τ = 0`. -/
theorem pipe_startup_rescaled_equation
    (ρ μ U G R : ℝ) (hρ : 0 < ρ) (hμ : 0 < μ) (hU : 0 < U) (hG : 0 < G) (hR : 0 < R)
    (u : ℝ → ℝ → ℝ)
    (hpde : ∀ t r, 0 < t → 0 < r → r < R →
      ρ * deriv (fun t' => u t' r) t
        = G + μ * (1 / r * deriv (fun s => s * deriv (fun s' => u t s') s) r))
    (hwall : ∀ t, u t R = 0)
    (hstart : ∀ r, u 0 r = 0) :
    let T := ρ * U / G
    let ε := μ * U / (G * R ^ 2)
    let us : ℝ → ℝ → ℝ := fun τ x => u (T * τ) (R * x) / U
    (∀ τ x, 0 < τ → 0 < x → x < 1 →
      deriv (fun τ' => us τ' x) τ
        = 1 + ε * (1 / x * deriv (fun y => y * deriv (fun y' => us τ y') y) x))
    ∧ (∀ τ, us τ 1 = 0)
    ∧ (∀ x, us 0 x = 0) := by
  intro T ε us
  refine ⟨?_, ?_, ?_⟩
  · intro τ x hτ hx0 hx1
    have hT : 0 < T := by positivity
    have ht : 0 < T * τ := mul_pos hT hτ
    have hr0 : 0 < R * x := mul_pos hR hx0
    have hr1 : R * x < R := by nlinarith
    have key := hpde (T * τ) (R * x) ht hr0 hr1
    set g : ℝ → ℝ := fun s => s * deriv (fun s' => u (T * τ) s') s with hg
    have hL : deriv (fun τ' => us τ' x) τ
        = T * deriv (fun t' => u t' (R * x)) (T * τ) / U := by
      show deriv (fun τ' => u (T * τ') (R * x) / U) τ = _
      rw [deriv_div_const]
      congr 1
      exact deriv_comp_mul_left (f := fun t' => u t' (R * x)) (c := T) (x := τ)
    have hin : ∀ y, deriv (fun y' => us τ y') y = R * deriv (fun s' => u (T * τ) s') (R * y) / U := by
      intro y
      show deriv (fun y' => u (T * τ) (R * y') / U) y = _
      rw [deriv_div_const]
      congr 1
      exact deriv_comp_mul_left (f := fun s' => u (T * τ) s') (c := R) (x := y)
    have hR2 : deriv (fun y => y * deriv (fun y' => us τ y') y) x = R * deriv g (R * x) / U := by
      have hfun : (fun y => y * deriv (fun y' => us τ y') y) = fun y => (g <| R * ·) y / U := by
        funext y
        rw [hin y]
        simp only [hg]
        ring
      rw [hfun, deriv_div_const]
      congr 1
      exact deriv_comp_mul_left (f := g) (c := R) (x := x)
    rw [hL, hR2]
    have hDt : deriv (fun t' => u t' (R * x)) (T * τ)
        = (G + μ * (1 / (R * x) * deriv g (R * x))) / ρ := by
      rw [← key]; field_simp
    rw [hDt]
    simp only [T, ε]
    field_simp
  · intro τ
    show u (T * τ) (R * 1) / U = 0
    rw [mul_one, hwall, zero_div]
  · intro x
    show u (T * 0) (R * x) / U = 0
    rw [mul_zero, hstart, zero_div]

/-- The small parameter through the Reynolds number: if the pump is sized by
`G = f ρ U² / (2D)` with radius `R = D/2`, kinematic viscosity `ν = μ/ρ` and
Reynolds number `Re = UD/ν`, then `ε = μU/(GR²) = 8/(f Re)`. -/
theorem small_parameter_eq_eight_div_friction_mul_reynolds
    (ρ μ U D f G : ℝ) (hρ : 0 < ρ) (hμ : 0 < μ) (hU : 0 < U) (hD : 0 < D) (hf : 0 < f)
    (hGdef : G = f * ρ * U ^ 2 / (2 * D)) :
    μ * U / (G * (D / 2) ^ 2) = 8 / (f * (U * D / (μ / ρ))) := by
  subst hGdef
  field_simp
  ring

/-- Every laminar design gives exactly one eighth: with the laminar friction factor
`f = 64/Re`, the small parameter `ε = μU/(GR²)` equals `1/8`, whatever the pipe, speed or fluid. -/
theorem laminar_small_parameter_eq_one_eighth
    (ρ μ U D f G : ℝ) (hρ : 0 < ρ) (hμ : 0 < μ) (hU : 0 < U) (hD : 0 < D)
    (hfdef : f = 64 / (U * D / (μ / ρ)))
    (hGdef : G = f * ρ * U ^ 2 / (2 * D)) :
    μ * U / (G * (D / 2) ^ 2) = 1 / 8 := by
  subst hGdef
  subst hfdef
  field_simp
  ring

-- The slow pipe, worked by hand on the card: ρ = 1000, ν = 1/10^6, μ = 1/1000, D = 1/10, Re = 2000.
-- Design speed U = Re ν / D = 0.02 m/s.
example : (2000 : ℚ) * (1 / 10 ^ 6) / (1 / 10) = 1 / 50 := by norm_num
-- Laminar friction factor f = 64/Re = 0.032.
example : (64 : ℚ) / 2000 = 4 / 125 := by norm_num
-- Push G = f ρ U² / (2D) = 0.064 Pa/m.
example : (4 / 125 : ℚ) * 1000 * (1 / 50) ^ 2 / (2 * (1 / 10)) = 8 / 125 := by norm_num
-- Natural time T = ρ U / G = 312.5 s.
example : (1000 : ℚ) * (1 / 50) / (8 / 125) = 625 / 2 := by norm_num
-- Small parameter ε = μ U / (G R²) = 0.125, with R = 0.05 m.
example : (1 / 1000 : ℚ) * (1 / 50) / ((8 / 125) * (1 / 20) ^ 2) = 1 / 8 := by norm_num
-- The same through 8/(f Re) = 8/64.
example : (8 : ℚ) / ((4 / 125) * 2000) = 1 / 8 := by norm_num
-- Viscous time R²/ν = 2500 s, and for a laminar pipe T = R²/(8ν) = 312.5 s.
example : ((1 / 20 : ℚ) ^ 2) / (1 / 10 ^ 6) = 2500 := by norm_num
example : ((1 / 20 : ℚ) ^ 2) / (8 * (1 / 10 ^ 6)) = 625 / 2 := by norm_num

#print axioms pipe_startup_rescaled_equation
#print axioms small_parameter_eq_eight_div_friction_mul_reynolds
#print axioms laminar_small_parameter_eq_one_eighth
