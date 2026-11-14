-- Lift and drag: steady flow without viscosity round a circle with circulation Γ pushes it up by exactly ρ U Γ and not at all downstream, Kirchhoff's rule only takes lift away and only adds drag, and an arched camber line of height f_c has zero-lift angle -2 f_c.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.Deriv.Polynomial

open Real

/-- The Kutta–Joukowski theorem, on the circle the card's wing is mapped from. Air of density
`ρ` streams at speed `U` past a circle of radius `a > 0`, steadily and without viscosity, with
clockwise circulation `Γ` round it. At angle `θ` round the circle the air slides along the skin
at speed `v θ = 2 U sin θ + Γ / (2 π a)`, and Bernoulli gives the pressure
`p θ = p∞ + ½ ρ (U² - v θ²)`. Adding up the pressure over the skin (outward normal
`(cos θ, sin θ)`, length `a dθ`), the force at right angles to the stream is exactly
`ρ U Γ` (lift = density × speed × circulation), and the force along the stream is exactly
zero (d'Alembert's paradox: without the boundary layer there is no drag). -/
theorem lift_eq_density_mul_speed_mul_circulation
    (ρ U Γ a pinf : ℝ) (ha : 0 < a) :
    let v : ℝ → ℝ := fun θ => 2 * U * sin θ + Γ / (2 * π * a)
    let p : ℝ → ℝ := fun θ => pinf + ρ / 2 * (U ^ 2 - v θ ^ 2)
    (-∫ θ in (0 : ℝ)..(2 * π), p θ * sin θ * a) = ρ * U * Γ ∧
      (-∫ θ in (0 : ℝ)..(2 * π), p θ * cos θ * a) = 0 := by
  intro v p
  set c : ℝ := Γ / (2 * π * a) with hc
  set A : ℝ := pinf + ρ / 2 * (U ^ 2 - c ^ 2) with hA
  have e1 : (fun θ => p θ * sin θ * a) =
      fun θ => ((A * a) * sin θ + (-2 * ρ * U ^ 2 * a) * sin θ ^ 3) + (-2 * ρ * U * c * a) * sin θ ^ 2 := by
    funext θ; simp only [p, v, hA]; ring
  have e2 : (fun θ => p θ * cos θ * a) =
      fun θ => ((A * a) * cos θ + (-2 * ρ * U ^ 2 * a) * (sin θ ^ 2 * cos θ)) + (-2 * ρ * U * c * a) * (sin θ * cos θ) := by
    funext θ; simp only [p, v, hA]; ring
  have hpi : π ≠ 0 := Real.pi_ne_zero
  constructor
  · rw [e1, intervalIntegral.integral_add (by apply Continuous.intervalIntegrable; fun_prop)
      (by apply Continuous.intervalIntegrable; fun_prop),
      intervalIntegral.integral_add (by apply Continuous.intervalIntegrable; fun_prop)
      (by apply Continuous.intervalIntegrable; fun_prop),
      intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul,
      intervalIntegral.integral_const_mul, integral_sin, integral_sin_pow_three, integral_sin_sq]
    simp only [cos_two_pi, sin_two_pi, cos_zero, sin_zero, hc]
    field_simp
    ring
  · rw [e2, intervalIntegral.integral_add (by apply Continuous.intervalIntegrable; fun_prop)
      (by apply Continuous.intervalIntegrable; fun_prop),
      intervalIntegral.integral_add (by apply Continuous.intervalIntegrable; fun_prop)
      (by apply Continuous.intervalIntegrable; fun_prop),
      intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul,
      intervalIntegral.integral_const_mul, integral_cos, integral_sin_sq_mul_cos, integral_sin_mul_cos₁]
    simp

/-- Kirchhoff's rule only takes lift away and only adds drag. With lift slope `k > 0`, angle
from zero lift `α - α₀` between `0` and `π/2`, no-layer lift coefficient
`F = k sin(α - α₀)`, and upper surface attached for the front fraction `f` of the chord
(`0 ≤ f ≤ 1`), set `g = ((1 + √f)/2)²`. Then the lift with the layer,
`C_L = F (g cos²(α - α₀) + √f sin²(α - α₀))`, is at most `F`, and the separation pressure
drag `F sin(α - α₀) cos(α - α₀) (g - √f)` is never negative. Fully attached (`f = 1`),
nothing changes: `C_L = F` and the pressure drag is zero. Fully separated (`f = 0`), the
lift falls to a quarter of the part at right angles to the zero-lift line:
`C_L = F cos²(α - α₀) / 4`. -/
theorem kirchhoff_separation_lowers_lift_and_adds_drag
    (k ae f : ℝ) (hk : 0 < k) (ha0 : 0 ≤ ae) (ha1 : ae ≤ π / 2) (hf0 : 0 ≤ f) (hf1 : f ≤ 1) :
    let F := k * sin ae
    let g := ((1 + √f) / 2) ^ 2
    let CL := F * (g * cos ae ^ 2 + √f * sin ae ^ 2)
    let CDp := F * sin ae * cos ae * (g - √f)
    CL ≤ F ∧ 0 ≤ CDp ∧ (f = 1 → CL = F ∧ CDp = 0) ∧ (f = 0 → CL = F * cos ae ^ 2 / 4) := by
  intro F g CL CDp
  have hs0 : 0 ≤ √f := Real.sqrt_nonneg f
  have hs1 : √f ≤ 1 := by rw [Real.sqrt_le_one]; exact hf1
  have hsin : 0 ≤ sin ae := Real.sin_nonneg_of_nonneg_of_le_pi ha0 (by linarith [Real.pi_pos])
  have hcos : 0 ≤ cos ae := Real.cos_nonneg_of_mem_Icc ⟨by linarith [Real.pi_pos], ha1⟩
  have hF : 0 ≤ F := mul_nonneg hk.le hsin
  have hsc : sin ae ^ 2 + cos ae ^ 2 = 1 := sin_sq_add_cos_sq ae
  have hgs : 0 ≤ g - √f := by
    have : g - √f = ((1 - √f) / 2) ^ 2 := by simp only [g]; ring
    rw [this]; positivity
  have hg1 : g ≤ 1 := by
    simp only [g]; nlinarith
  refine ⟨?_, ?_, ?_, ?_⟩
  · have hin : g * cos ae ^ 2 + √f * sin ae ^ 2 ≤ 1 := by
      nlinarith [sq_nonneg (sin ae), sq_nonneg (cos ae)]
    calc CL = F * (g * cos ae ^ 2 + √f * sin ae ^ 2) := rfl
      _ ≤ F * 1 := mul_le_mul_of_nonneg_left hin hF
      _ = F := mul_one F
  · exact mul_nonneg (mul_nonneg (mul_nonneg hF hsin) hcos) hgs
  · intro h1
    subst h1
    simp only [CL, CDp, g, Real.sqrt_one]
    constructor
    · linear_combination F * hsc
    · ring
  · intro h0
    subst h0
    simp only [CL, g, Real.sqrt_zero]
    ring

/-- Thin aerofoil theory: the zero-lift angle of an arched camber line. For the parabolic arch
`z_c(x) = 4 f_c x (c - x) / c` of height `f_c` chords over a chord `c ≠ 0`, at the point
`x = (c/2)(1 - cos ϑ)` the slope is `dz_c/dx = 4 f_c cos ϑ`, and the zero-lift angle
`α₀ = -(1/π) ∫₀^π (dz_c/dx)(cos ϑ - 1) dϑ` comes out to exactly `-2 f_c` radians. -/
theorem zero_lift_angle_of_arched_camber_line (fc c : ℝ) (hc : c ≠ 0) :
    (∀ ϑ : ℝ, deriv (fun x : ℝ => 4 * fc * x * (c - x) / c) (c / 2 * (1 - cos ϑ))
        = 4 * fc * cos ϑ) ∧
      -(1 / π) * ∫ ϑ in (0 : ℝ)..π, (4 * fc * cos ϑ) * (cos ϑ - 1) = -2 * fc := by
  have hpi : π ≠ 0 := Real.pi_ne_zero
  constructor
  · intro ϑ
    have hd : ∀ x : ℝ, HasDerivAt (fun x : ℝ => 4 * fc * x * (c - x) / c)
        (((4 * fc * 1) * (c - x) + 4 * fc * x * (0 - 1)) / c) x := by
      intro x
      exact ((((hasDerivAt_id x).const_mul (4 * fc)).mul
        ((hasDerivAt_const x c).sub (hasDerivAt_id x)))).div_const c
    rw [(hd _).deriv]
    field_simp
    ring
  · have e : (fun ϑ : ℝ => (4 * fc * cos ϑ) * (cos ϑ - 1)) =
        fun ϑ => (4 * fc) * cos ϑ ^ 2 - (4 * fc) * cos ϑ := by
      funext ϑ; ring
    rw [e, intervalIntegral.integral_sub (by apply Continuous.intervalIntegrable; fun_prop)
      (by apply Continuous.intervalIntegrable; fun_prop),
      intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul,
      integral_cos_sq, integral_cos]
    simp only [cos_pi, sin_pi, cos_zero, sin_zero]
    field_simp
    ring

-- Kirchhoff's factor g = ((1 + √f)/2)² at the two ends: 1 when fully attached (√1 = 1),
-- a quarter when fully separated (√0 = 0).
example : ((1 + 1 : ℚ) / 2) ^ 2 = 1 := by norm_num
example : ((1 + 0 : ℚ) / 2) ^ 2 = 1 / 4 := by norm_num

#print axioms lift_eq_density_mul_speed_mul_circulation
#print axioms kirchhoff_separation_lowers_lift_and_adds_drag
#print axioms zero_lift_angle_of_arched_camber_line
