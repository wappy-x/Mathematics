-- Three families: on a uniform grid each sine wave is bent into a multiple of itself, explicit heat steps under h²/(2α) never grow a wave, leapfrog sound steps under h/c keep every wave's size, and backward Euler shrinks a ringing wave while the trapezoidal step keeps it.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Complex.Basic
import Mathlib.Tactic

open Real

/-- The three-point bend on a grid of spacing h: (u(j-1) - 2 u(j) + u(j+1)) / h². -/
noncomputable def gridBend (h : ℝ) (u : ℤ → ℝ) (j : ℤ) : ℝ :=
  (u (j - 1) - 2 * u j + u (j + 1)) / h ^ 2

/-- The grid wave with k humps: u_j = sin(kπ j h) at grid point j. -/
noncomputable def gridWave (h k : ℝ) : ℤ → ℝ :=
  fun j => Real.sin (k * π * (j * h))

/-- The rate of the grid wave with k humps: λ_k = (4/h²) sin²(kπh/2). -/
noncomputable def gridRate (h k : ℝ) : ℝ :=
  4 / h ^ 2 * Real.sin (k * π * h / 2) ^ 2

/-- Every root of g² - (2 - w) g + 1 = 0 with 0 ≤ w < 4 has size 1. -/
theorem leapfrog_root_norm_one (w : ℝ) (hw0 : 0 ≤ w) (hw4 : w < 4) (g : ℂ)
    (hg : g ^ 2 - (2 - (w : ℂ)) * g + 1 = 0) : ‖g‖ = 1 := by
  have hre := congrArg Complex.re hg
  have him := congrArg Complex.im hg
  simp [pow_two] at hre him
  set x := g.re
  set y := g.im
  have key : x ^ 2 + y ^ 2 = 1 := by
    have him' : y * (2 * x - (2 - w)) = 0 := by linear_combination him
    rcases mul_eq_zero.mp him' with hy | hy
    · rw [hy] at hre ⊢
      have hsq : (x - (2 - w) / 2) ^ 2 + (1 - (2 - w) ^ 2 / 4) = 0 := by
        linear_combination hre
      have ha : 0 ≤ 1 - (2 - w) ^ 2 / 4 := by nlinarith
      have hc' : 1 - (2 - w) ^ 2 / 4 = 0 := by nlinarith [sq_nonneg (x - (2 - w) / 2)]
      have hb : (x - (2 - w) / 2) ^ 2 = 0 := by linarith
      have : x = (2 - w) / 2 := by
        have := pow_eq_zero_iff (n := 2) two_ne_zero |>.mp hb
        linarith
      rw [this]; linear_combination -hc'
    · linear_combination -hre + x * hy
  have hn : ‖g‖ ^ 2 = 1 := by
    rw [Complex.sq_norm, Complex.normSq_apply]; nlinarith [key]
  have : 0 ≤ ‖g‖ := norm_nonneg _
  nlinarith

#print axioms leapfrog_root_norm_one

/-- The two explicit step limits. Take the 1 m bar cut into N equal pieces, so the spacing is
h = 1/N, and a grid wave with k humps, 1 ≤ k ≤ N - 1, with rate λ_k = (4/h²) sin²(kπh/2).
Let the diffusivity α, the sound speed c and the time step Δt be positive.
Heat: if Δt ≤ h²/(2α), the explicit (forward Euler) step's factor 1 - αΔtλ_k lies between
-1 and 1, so no wave grows.
Sound: if Δt ≤ h/c, then ω_k² Δt² = c² λ_k Δt² is below 4 (that is, ω_k Δt < 2), and every
root g of leapfrog's equation g² - (2 - ω_k² Δt²) g + 1 = 0 has size exactly 1, so every wave
keeps its size. -/
theorem explicit_step_limits (N : ℕ) (k : ℕ) (hk1 : 1 ≤ k) (hkN : k < N)
    (α c Δt : ℝ) (hα : 0 < α) (hc : 0 < c) (hΔt : 0 < Δt) :
    (Δt ≤ (1 / (N : ℝ)) ^ 2 / (2 * α) →
      |1 - α * Δt * gridRate (1 / (N : ℝ)) k| ≤ 1) ∧
    (Δt ≤ (1 / (N : ℝ)) / c →
      c ^ 2 * gridRate (1 / (N : ℝ)) k * Δt ^ 2 < 4 ∧
      ∀ g : ℂ, g ^ 2 - (2 - ((c ^ 2 * gridRate (1 / (N : ℝ)) k * Δt ^ 2 : ℝ) : ℂ)) * g + 1 = 0 →
        ‖g‖ = 1) := by
  have hN : (0 : ℝ) < N := by exact_mod_cast (show 0 < N by omega)
  set h : ℝ := 1 / (N : ℝ) with hh
  have hpos : 0 < h := by positivity
  set x : ℝ := (k : ℝ) * π * h / 2 with hx
  have hk : (k : ℝ) < N := by exact_mod_cast hkN
  have hk1' : (1 : ℝ) ≤ k := by exact_mod_cast hk1
  have hx0 : 0 < x := by rw [hx]; have := Real.pi_pos; positivity
  have hx1 : x < π / 2 := by
    rw [hx, hh]
    have := Real.pi_pos
    rw [div_lt_div_iff_of_pos_right (by norm_num : (0:ℝ) < 2)]
    calc (k : ℝ) * π * (1 / N) = π * (k / N) := by ring
      _ < π * 1 := by
          apply mul_lt_mul_of_pos_left _ this
          rw [div_lt_one hN]; exact hk
      _ = π := by ring
  have hcos : 0 < Real.cos x := Real.cos_pos_of_mem_Ioo ⟨by linarith, hx1⟩
  have hs0 : 0 ≤ Real.sin x ^ 2 := sq_nonneg _
  have hs1 : Real.sin x ^ 2 < 1 := by
    have := Real.sin_sq_add_cos_sq x
    nlinarith [sq_pos_of_pos hcos]
  have hR : gridRate h k = 4 / h ^ 2 * Real.sin x ^ 2 := rfl
  have hR0 : 0 ≤ gridRate h k := by rw [hR]; positivity
  have hRh : gridRate h k * h ^ 2 = 4 * Real.sin x ^ 2 := by
    rw [hR]; field_simp
  refine ⟨fun hdt => ?_, fun hdt => ?_⟩
  · have h1 : α * Δt * gridRate h k ≤ 2 * Real.sin x ^ 2 := by
      have : α * Δt ≤ h ^ 2 / 2 := by
        rw [le_div_iff₀ (by positivity : (0:ℝ) < 2 * α)] at hdt
        linarith
      calc α * Δt * gridRate h k ≤ h ^ 2 / 2 * gridRate h k :=
            mul_le_mul_of_nonneg_right this hR0
        _ = 2 * Real.sin x ^ 2 := by linear_combination hRh / 2
    have h2 : 0 ≤ α * Δt * gridRate h k := by positivity
    rw [abs_le]; constructor <;> nlinarith
  · have hcd : c * Δt ≤ h := by
      rw [le_div_iff₀ hc] at hdt; linarith
    have hcd2 : c ^ 2 * Δt ^ 2 ≤ h ^ 2 := by
      have : 0 ≤ c * Δt := by positivity
      nlinarith
    have hw : c ^ 2 * gridRate h k * Δt ^ 2 ≤ 4 * Real.sin x ^ 2 := by
      calc c ^ 2 * gridRate h k * Δt ^ 2 = gridRate h k * (c ^ 2 * Δt ^ 2) := by ring
        _ ≤ gridRate h k * h ^ 2 := mul_le_mul_of_nonneg_left hcd2 hR0
        _ = 4 * Real.sin x ^ 2 := hRh
    have hw4 : c ^ 2 * gridRate h k * Δt ^ 2 < 4 := by linarith
    have hw0 : 0 ≤ c ^ 2 * gridRate h k * Δt ^ 2 := by positivity
    refine ⟨hw4, fun g hg => ?_⟩
    exact leapfrog_root_norm_one _ hw0 hw4 g hg

/-- Each grid wave is bent into a multiple of itself. On a grid of spacing h > 0, the
three-point bend of the wave u_j = sin(kπjh) is -λ_k u_j, with λ_k = (4/h²) sin²(kπh/2). -/
theorem grid_bend_of_wave (h k : ℝ) (hh : 0 < h) (j : ℤ) :
    gridBend h (gridWave h k) j = -(gridRate h k * gridWave h k j) := by
  unfold gridBend gridWave gridRate
  push_cast
  have hb : k * π * ((j - 1) * h) = k * π * (j * h) - k * π * h := by ring
  have hc : k * π * ((j + 1) * h) = k * π * (j * h) + k * π * h := by ring
  have hd : k * π * h = 2 * (k * π * h / 2) := by ring
  rw [hb, hc, Real.sin_sub, Real.sin_add]
  rw [hd, Real.cos_two_mul, Real.cos_sq']
  have : h ^ 2 ≠ 0 := by positivity
  field_simp
  ring


/-- Backward Euler damps a ring; the trapezoidal step keeps it. Take one grid wave ringing at
ω > 0, with displacement u and speed v, so u' = v and v' = -ω² u, and its size
sqrt(u² + (v/ω)²). A backward Euler step of length Δt > 0 (u₁ - u = Δt v₁,
v₁ - v = -ω²Δt u₁) multiplies the size by 1/sqrt(1 + ω²Δt²), which is below 1.
A trapezoidal step (each change is Δt times the average of the old and new right-hand sides)
keeps the size exactly. -/
theorem backward_euler_damps_trapezoid_keeps (ω Δt u v : ℝ) (hω : 0 < ω) (hΔt : 0 < Δt) :
    (∀ u₁ v₁ : ℝ, u₁ - u = Δt * v₁ → v₁ - v = -(ω ^ 2 * Δt * u₁) →
      √(u₁ ^ 2 + (v₁ / ω) ^ 2) = √(u ^ 2 + (v / ω) ^ 2) / √(1 + ω ^ 2 * Δt ^ 2)) ∧
    1 / √(1 + ω ^ 2 * Δt ^ 2) < 1 ∧
    (∀ u₁ v₁ : ℝ, u₁ - u = Δt * ((v + v₁) / 2) → v₁ - v = -(ω ^ 2 * Δt * ((u + u₁) / 2)) →
      u₁ ^ 2 + (v₁ / ω) ^ 2 = u ^ 2 + (v / ω) ^ 2) := by
  have hD : 1 < 1 + ω ^ 2 * Δt ^ 2 := by
    have : 0 < ω ^ 2 * Δt ^ 2 := by positivity
    linarith
  have hsD : 1 < √(1 + ω ^ 2 * Δt ^ 2) := by
    rw [Real.lt_sqrt (by norm_num)]; linarith
  have hω' : ω ≠ 0 := hω.ne'
  refine ⟨fun u₁ v₁ h1 h2 => ?_, ?_, fun u₁ v₁ h1 h2 => ?_⟩
  · have hS : u ^ 2 + (v / ω) ^ 2 = (u₁ ^ 2 + (v₁ / ω) ^ 2) * (1 + ω ^ 2 * Δt ^ 2) := by
      have hu : u = u₁ - Δt * v₁ := by linarith
      have hv : v = v₁ + ω ^ 2 * Δt * u₁ := by linarith
      rw [hu, hv]; field_simp; ring
    rw [hS, Real.sqrt_mul (by positivity), mul_div_assoc, div_self (by positivity), mul_one]
  · rw [div_lt_one (by linarith)]; exact hsD
  · have hk : ω ^ 2 * u₁ ^ 2 + v₁ ^ 2 = ω ^ 2 * u ^ 2 + v ^ 2 := by
      linear_combination ω ^ 2 * (u₁ + u) * h1 + (v₁ + v) * h2
    field_simp
    linear_combination hk

-- Worked numbers from the card.
-- Plate u_xx + u_yy: A = 1, B = 0, C = 1, so B² - 4AC = -4: elliptic.
example : (0 : ℤ) ^ 2 - 4 * 1 * 1 = -4 := by norm_num
-- Heat α u_xx - u_t with α = 12/1000000: A = α, B = 0, C = 0, so B² - 4AC = 0: parabolic.
example : (0 : ℚ) ^ 2 - 4 * (12 / 1000000) * 0 = 0 := by norm_num
-- Black-Scholes at S = 100, σ = 1/5: A = σ²S²/2 = 200.
example : (1 / 2 : ℚ) * (1 / 5) ^ 2 * 100 ^ 2 = 200 := by norm_num
-- Explicit heat limit h²/(2α) at h = 1/100 m, α = 12/1000000 m²/s is 25/6 s (4.1667 s).
example : (1 / 100 : ℚ) ^ 2 / (2 * (12 / 1000000)) = 25 / 6 := by norm_num
-- Explicit steps per hour: 864, and 3456 when h halves.
example : (3600 : ℚ) / ((1 / 100) ^ 2 / (2 * (12 / 1000000))) = 864 := by norm_num
example : (3600 : ℚ) / ((1 / 200) ^ 2 / (2 * (12 / 1000000))) = 3456 := by norm_num
-- Mesh ratio r = αΔt/h² at Δt = 4 s is 12/25 (0.48).
example : (12 / 1000000 : ℚ) * 4 / (1 / 100) ^ 2 = 12 / 25 := by norm_num
-- Thomas solve on 99 unknowns: 8n - 7 = 785 flops.
example : 8 * 99 - 7 = 785 := by norm_num
-- Flop counts: explicit 900 steps, backward Euler 60 and 900 steps, Crank-Nicolson 60 steps.
example : 900 * 99 * 5 = 445500 := by norm_num
example : 60 * (8 * 99 - 7) = 47100 := by norm_num
example : 900 * (8 * 99 - 7) = 706500 := by norm_num
example : 60 * (5 * 99 + 785) = 76800 := by norm_num
-- Plate at h = 1/20: 19 × 19 = 361 unknowns.
example : 19 ^ 2 = 361 := by norm_num

#print axioms explicit_step_limits
#print axioms grid_bend_of_wave
#print axioms backward_euler_damps_trapezoid_keeps
