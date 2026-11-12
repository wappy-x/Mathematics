-- Flow problems: with the Courant number ν = cΔt/h at most 1, every upwind step is a weighted average of two old values, so the grid never rises above its largest starting value or falls below its smallest, its leading error on a smooth pulse is the numerical diffusion c h (1 − ν)/2 times the second derivative, and the centred step's growth factor exceeds 1 for every wave but two.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.Complex.Basic
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.Taylor
import Mathlib.Analysis.Asymptotics.Defs
import Mathlib.Tactic.NormNum

open Filter Asymptotics Complex Topology

/-- No wobble, no growth. Take a river flowing at speed c > 0 toward larger cell numbers, cells
of length h > 0 and time steps Δt > 0, with Courant number ν = cΔt/h at most 1. The upwind step
replaces the value u_j in cell j by u_j − ν(u_j − u_{j−1}), reading only the cell the water comes
from. If every starting value lies between m and M, then after any number n of upwind steps every
cell's value still lies between m and M: the grid never shows more than the largest old value or
less than the smallest. -/
theorem upwind_steps_stay_between_old_min_and_max (c h Δt m M : ℝ) (hc : 0 < c) (hh : 0 < h)
    (hΔt : 0 < Δt) (hcfl : c * Δt / h ≤ 1) (u₀ : ℤ → ℝ) (hu₀ : ∀ j, m ≤ u₀ j ∧ u₀ j ≤ M)
    (n : ℕ) (j : ℤ) :
    m ≤ (fun (u : ℤ → ℝ) (k : ℤ) => u k - c * Δt / h * (u k - u (k - 1)))^[n] u₀ j ∧
      (fun (u : ℤ → ℝ) (k : ℤ) => u k - c * Δt / h * (u k - u (k - 1)))^[n] u₀ j ≤ M := by
  have hν0 : 0 ≤ c * Δt / h := div_nonneg (mul_nonneg hc.le hΔt.le) hh.le
  induction n generalizing j with
  | zero => simpa using hu₀ j
  | succ n ih =>
    rw [Function.iterate_succ_apply']
    obtain ⟨a1, a2⟩ := ih j
    obtain ⟨b1, b2⟩ := ih (j - 1)
    constructor
    · nlinarith [mul_nonneg (sub_nonneg.2 hcfl) (sub_nonneg.2 a1), mul_nonneg hν0 (sub_nonneg.2 b1)]
    · nlinarith [mul_nonneg (sub_nonneg.2 hcfl) (sub_nonneg.2 a2), mul_nonneg hν0 (sub_nonneg.2 b2)]

/-- The price is numerical diffusion. Let the spill f be a smooth pulse (three times continuously
differentiable), so the exact concentration is u(x, t) = f(x − ct). Feed this exact answer into
the upwind step with cell length h, Courant number ν (0 < ν ≤ 1) and time step Δt = νh/c. The
amount by which it fails the step,
(u(x, t + Δt) − u(x, t))/Δt + c (u(x, t) − u(x − h, t))/h,
equals −α_num u_xx(x, t) with α_num = c h (1 − ν)/2, up to an error of order h² as h → 0.
So the grid behaves like u_t + c u_x = α_num u_xx: a river that mixes at the rate c h (1 − ν)/2. -/
theorem upwind_modified_equation_numerical_diffusion (f : ℝ → ℝ) (hf : ContDiff ℝ 3 f)
    (c ν x t : ℝ) (hc : 0 < c) (hν0 : 0 < ν) (hν1 : ν ≤ 1) :
    (fun h : ℝ =>
        (f (x - c * (t + ν * h / c)) - f (x - c * t)) / (ν * h / c)
          + c * (f (x - c * t) - f ((x - h) - c * t)) / h
          + c * h * (1 - ν) / 2 * iteratedDeriv 2 f (x - c * t))
      =O[𝓝[>] 0] (fun h : ℝ => h ^ 2) := by
  set s := x - c * t with hs
  set T : ℝ → ℝ := fun y => f y - taylorWithinEval f 3 Set.univ s y with hT
  have hTo : T =o[𝓝 s] fun y => (y - s) ^ 3 := taylor_isLittleO_univ (n := 3) hf
  have hTay : ∀ y, taylorWithinEval f 3 Set.univ s y = f s + (y - s) * iteratedDeriv 1 f s
      + (y - s) ^ 2 / 2 * iteratedDeriv 2 f s + (y - s) ^ 3 / 6 * iteratedDeriv 3 f s := by
    intro y
    rw [taylor_within_apply]
    simp only [Finset.sum_range_succ, Finset.sum_range_zero, iteratedDerivWithin_univ,
      iteratedDeriv_zero, Nat.factorial, smul_eq_mul]
    push_cast
    ring
  have hfy : ∀ y, f y = T y + (f s + (y - s) * iteratedDeriv 1 f s
      + (y - s) ^ 2 / 2 * iteratedDeriv 2 f s + (y - s) ^ 3 / 6 * iteratedDeriv 3 f s) := by
    intro y; simp only [hT, hTay]; ring
  have hE : (fun h : ℝ => c * (1 - ν ^ 2) / 6 * iteratedDeriv 3 f s * h ^ 2
        + c / ν * (T (s - ν * h) * h⁻¹) - c * (T (s - h) * h⁻¹)) =ᶠ[𝓝[>] 0]
      (fun h : ℝ =>
        (f (x - c * (t + ν * h / c)) - f (x - c * t)) / (ν * h / c)
          + c * (f (x - c * t) - f ((x - h) - c * t)) / h
          + c * h * (1 - ν) / 2 * iteratedDeriv 2 f (x - c * t)) := by
    filter_upwards [self_mem_nhdsWithin] with h hh
    have hh' : h ≠ 0 := ne_of_gt hh
    have e1 : x - c * (t + ν * h / c) = s - ν * h := by rw [hs]; field_simp; ring
    have e2 : (x - h) - c * t = s - h := by rw [hs]; ring
    rw [e1, e2, hfy (s - ν * h), hfy (s - h)]
    field_simp
    ring
  have hsub : ∀ k : ℝ, (fun y => (y - s) ^ 3) ∘ (fun h : ℝ => s - k * h) = fun h => (-k) ^ 3 * h ^ 3 := by
    intro k; funext h; simp only [Function.comp]; ring
  have tend : ∀ k : ℝ, Tendsto (fun h : ℝ => s - k * h) (𝓝[>] 0) (𝓝 s) := by
    intro k
    have : Tendsto (fun h : ℝ => s - k * h) (𝓝 0) (𝓝 (s - k * 0)) :=
      ((continuous_const.sub (continuous_const.mul continuous_id)).tendsto 0)
    simpa using this.mono_left nhdsWithin_le_nhds
  have O3 : ∀ k : ℝ, (fun h : ℝ => T (s - k * h) * h⁻¹) =O[𝓝[>] 0] fun h : ℝ => h ^ 2 := by
    intro k
    have o1 := (hTo.comp_tendsto (tend k)).isBigO
    rw [hsub k] at o1
    have o2 : (fun h : ℝ => T (s - k * h)) =O[𝓝[>] 0] fun h : ℝ => h ^ 3 :=
      o1.trans (isBigO_const_mul_self _ _ _)
    have o3 := o2.mul (isBigO_refl (fun h : ℝ => h⁻¹) (𝓝[>] 0))
    refine o3.congr' EventuallyEq.rfl ?_
    filter_upwards [self_mem_nhdsWithin] with h hh
    have hh' : h ≠ 0 := ne_of_gt hh
    field_simp
  have O1 := O3 ν
  have O2 := O3 1
  simp only [one_mul] at O2
  refine IsBigO.congr' ?_ hE EventuallyEq.rfl
  exact (((isBigO_const_mul_self _ _ _).add (O1.const_mul_left _)).sub (O2.const_mul_left _))

/-- The centred step grows. The centred step u_j − (ν/2)(u_{j+1} − u_{j−1}) multiplies the wave
e^{iξj} by g(ξ) = 1 − (ν/2)(e^{iξ} − e^{−iξ}). For every Courant number ν > 0 and every wave
except the flat one and the shortest one (those with sin ξ = 0), |g(ξ)| > 1: the wave grows every
step, so shrinking the step at a fixed ν does not save it. -/
theorem centred_step_growth_factor_exceeds_one (ν ξ : ℝ) (hν : 0 < ν) (hξ : Real.sin ξ ≠ 0) :
    1 < ‖(1 : ℂ) - (ν / 2 : ℂ) * (exp (ξ * I) - exp (-(ξ * I)))‖ := by
  have hneg : -((ξ : ℂ) * I) = ((-ξ : ℝ) : ℂ) * I := by push_cast; ring
  have hre : (exp (-((ξ : ℂ) * I))).re = Real.cos ξ := by
    rw [hneg, exp_ofReal_mul_I_re, Real.cos_neg]
  have him : (exp (-((ξ : ℂ) * I))).im = -Real.sin ξ := by
    rw [hneg, exp_ofReal_mul_I_im, Real.sin_neg]
  have h2 : (1 : ℂ) - (ν / 2 : ℂ) * (exp (ξ * I) - exp (-(ξ * I))) = ⟨1, -(ν * Real.sin ξ)⟩ := by
    apply Complex.ext
    · simp [exp_ofReal_mul_I_re, exp_ofReal_mul_I_im, hre, him]
    · simp [exp_ofReal_mul_I_re, exp_ofReal_mul_I_im, hre, him]; ring
  rw [h2]
  have h3 : ‖(⟨1, -(ν * Real.sin ξ)⟩ : ℂ)‖ ^ 2 = 1 + (ν * Real.sin ξ) ^ 2 := by
    rw [Complex.sq_norm, Complex.normSq_apply]; ring
  have h4 : 0 < (ν * Real.sin ξ) ^ 2 := by
    have := mul_ne_zero hν.ne' hξ
    positivity
  nlinarith [norm_nonneg (⟨1, -(ν * Real.sin ξ)⟩ : ℂ)]

-- The Courant number on the river: ν = 2.0 km/h × 0.1 h ÷ 0.25 km = 0.80.
example : (2 : ℚ) * (1 / 10) / (1 / 4) = 4 / 5 := by norm_num
-- The numerical diffusivity c h (1 − ν)/2 = 2.0 × 0.25 × 0.2 ÷ 2 = 0.0500 km²/h.
example : (2 : ℚ) * (1 / 4) * (1 - 4 / 5) / 2 = 1 / 20 := by norm_num
-- In m²/s: 0.05 × 10^6 ÷ 3600 = 125/9 = 13.89 m²/s.
example : (1 / 20 : ℚ) * 10 ^ 6 / 3600 = 125 / 9 := by norm_num
-- The variance at 3.0 h: 0.5 + 2 × 0.05 × 3 = 0.8000 km².
example : (1 / 2 : ℚ) + 2 * (1 / 20) * 3 = 4 / 5 := by norm_num
-- The step that is too long: 2.0 × 0.15 ÷ 0.25 = 1.2.
example : (2 : ℚ) * (15 / 100) / (1 / 4) = 6 / 5 := by norm_num
-- Upwind growth factor at ξ = π: |g|² = 1 − 2ν(1 − ν)(1 − cos π) = 0.36, so |g| = 0.6000.
example : 1 - 2 * (4 / 5 : ℝ) * (1 - 4 / 5) * (1 - Real.cos Real.pi) = (3 / 5) ^ 2 := by
  rw [Real.cos_pi]; norm_num
-- Lax-Wendroff growth factor at ξ = π: |g|² = 1 − ν²(1 − ν²)(1 − cos π)² = 0.0784, so |g| = 0.2800.
example : 1 - (4 / 5 : ℝ) ^ 2 * (1 - (4 / 5) ^ 2) * (1 - Real.cos Real.pi) ^ 2 = (7 / 25) ^ 2 := by
  rw [Real.cos_pi]; norm_num
-- Centred growth factor at ξ = π/2: |g|² = 1 + ν² sin²(π/2) = 1.64, so |g| = 1.2806.
example : 1 + (4 / 5 : ℝ) ^ 2 * Real.sin (Real.pi / 2) ^ 2 = 41 / 25 := by
  rw [Real.sin_pi_div_two]; norm_num

#print axioms upwind_steps_stay_between_old_min_and_max
#print axioms upwind_modified_equation_numerical_diffusion
#print axioms centred_step_growth_factor_exceeds_one
