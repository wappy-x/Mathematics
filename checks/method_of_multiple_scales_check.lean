-- Multiple scales: the solvability condition fixes the Duffing phase drift at 3a²/8, the plain expansion's correction grows without bound, and the van der Pol slow amplitude settles at 2.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Exp

open Real Filter Topology

theorem duffing_sin_integral (a da dφ : ℝ) :
    (∫ θ in (0 : ℝ)..2 * π,
        (2 * da * sin θ + 2 * a * dφ * cos θ - (a * cos θ) ^ 3) * sin θ) = 2 * π * da := by
  have hd : ∀ x ∈ Set.uIcc (0 : ℝ) (2 * π), HasDerivAt
      (fun θ => 2 * da * (θ / 2 - sin θ * cos θ / 2) + a * dφ * sin θ ^ 2 + a ^ 3 * cos θ ^ 4 / 4)
      ((2 * da * sin x + 2 * a * dφ * cos x - (a * cos x) ^ 3) * sin x) x := by
    intro x _
    have h1 := ((((hasDerivAt_id x).div_const 2).sub
      (((hasDerivAt_sin x).mul (hasDerivAt_cos x)).div_const 2)).const_mul (2 * da))
    have h2 := ((hasDerivAt_sin x).pow 2).const_mul (a * dφ)
    have h3 := (((hasDerivAt_cos x).pow 4).const_mul (a ^ 3)).div_const 4
    have h := (h1.add h2).add h3
    convert h using 1
    · funext θ; simp only [id, Pi.add_apply, Pi.sub_apply, Pi.mul_apply, Pi.pow_apply]
    · linear_combination da * sin_sq_add_cos_sq x
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hd
    (Continuous.intervalIntegrable (by fun_prop) _ _)]
  simp [sin_two_pi, cos_two_pi]
  ring

#print axioms duffing_sin_integral

theorem duffing_cos_integral (a da dφ : ℝ) :
    (∫ θ in (0 : ℝ)..2 * π,
        (2 * da * sin θ + 2 * a * dφ * cos θ - (a * cos θ) ^ 3) * cos θ) =
      2 * π * a * dφ - 3 * π * a ^ 3 / 4 := by
  have hd : ∀ x ∈ Set.uIcc (0 : ℝ) (2 * π), HasDerivAt
      (fun θ => da * sin θ ^ 2 + 2 * a * dφ * (θ / 2 + sin θ * cos θ / 2)
        - a ^ 3 * (3 * θ / 8 + 3 * sin θ * cos θ / 8 + cos θ ^ 3 * sin θ / 4))
      ((2 * da * sin x + 2 * a * dφ * cos x - (a * cos x) ^ 3) * cos x) x := by
    intro x _
    have h1 := ((hasDerivAt_sin x).pow 2).const_mul da
    have h2 := (((hasDerivAt_id x).div_const 2).add
        (((hasDerivAt_sin x).mul (hasDerivAt_cos x)).div_const 2)).const_mul (2 * a * dφ)
    have h3 := (((((hasDerivAt_id x).const_mul 3).div_const 8).add
        ((((hasDerivAt_sin x).const_mul 3).mul (hasDerivAt_cos x)).div_const 8)).add
        ((((hasDerivAt_cos x).pow 3).mul (hasDerivAt_sin x)).div_const 4)).const_mul (a ^ 3)
    have h := (h1.add h2).sub h3
    convert h using 1
    · funext θ; simp only [id, Pi.add_apply, Pi.sub_apply, Pi.mul_apply, Pi.pow_apply]
    · simp only [Nat.cast_ofNat, Nat.reduceSub, pow_one, Pi.pow_apply]
      linear_combination (a * dφ + a ^ 3 * (-3 / 8 - 3 * cos x ^ 2 / 4)) * sin_sq_add_cos_sq x
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hd
    (Continuous.intervalIntegrable (by fun_prop) _ _)]
  simp [sin_two_pi, cos_two_pi]
  ring

#print axioms duffing_cos_integral

/-- The solvability condition for the Duffing spring `x'' + x + ε x³ = 0`. On the rung with one `ε`,
two-timing leaves the right side `2 a' sin θ + 2 a φ' cos θ - (a cos θ)³`, where `a'` and `φ'` are the
slow-time rates of the amplitude and the phase. Its parts in step with the swing (its `sin θ` and
`cos θ` components over one swing) both vanish exactly when the amplitude does not drift, `a' = 0`,
and the phase creeps ahead at `φ' = 3a²/8`; so the frequency is `1 + 3εa²/8`. -/
theorem duffing_solvability_condition (a da dφ : ℝ) (ha : a ≠ 0) :
    ((∫ θ in (0 : ℝ)..2 * π,
        (2 * da * sin θ + 2 * a * dφ * cos θ - (a * cos θ) ^ 3) * sin θ) = 0 ∧
      (∫ θ in (0 : ℝ)..2 * π,
        (2 * da * sin θ + 2 * a * dφ * cos θ - (a * cos θ) ^ 3) * cos θ) = 0) ↔
      (da = 0 ∧ dφ = 3 * a ^ 2 / 8) := by
  rw [duffing_sin_integral, duffing_cos_integral]
  have hπ : π ≠ 0 := pi_ne_zero
  constructor
  · rintro ⟨h1, h2⟩
    refine ⟨?_, ?_⟩
    · rcases mul_eq_zero.mp h1 with h | h
      · exact absurd (by linarith : π = 0) hπ
      · exact h
    · have h3 : (π * a) * (2 * dφ - 3 * a ^ 2 / 4) = 0 := by linear_combination h2
      rcases mul_eq_zero.mp h3 with h | h
      · exact absurd h (mul_ne_zero hπ ha)
      · linarith
  · rintro ⟨h1, h2⟩
    subst h1 h2
    constructor <;> ring

/-- The plain expansion fails. Its first correction
`x₁(t) = (cos 3t - cos t)/32 - (3/8) t sin t` solves `x₁'' + x₁ = -(3/4) cos t - (1/4) cos 3t`
with `x₁(0) = 0` and `x₁'(0) = 0`, and the secular term `t sin t` makes it grow without bound. -/
theorem plain_expansion_correction_is_secular :
    let x₁ : ℝ → ℝ := fun t => (cos (3 * t) - cos t) / 32 - 3 / 8 * t * sin t
    (∀ t, deriv (deriv x₁) t + x₁ t = -(3 / 4) * cos t - (1 / 4) * cos (3 * t)) ∧
      x₁ 0 = 0 ∧ deriv x₁ 0 = 0 ∧ ¬ ∃ C : ℝ, ∀ t, |x₁ t| ≤ C := by
  intro x₁
  have hx : ∀ t, HasDerivAt x₁
      ((-3 * sin (3 * t) + sin t) / 32 - 3 / 8 * sin t - 3 / 8 * t * cos t) t := by
    intro t
    have h := (((((hasDerivAt_id t).const_mul 3).cos).sub (hasDerivAt_cos t)).div_const 32).sub
      (((hasDerivAt_id t).const_mul (3 / 8)).mul (hasDerivAt_sin t))
    convert h using 1
    · rfl
    · simp only [id]; ring
  have hd : deriv x₁ = fun t =>
      (-3 * sin (3 * t) + sin t) / 32 - 3 / 8 * sin t - 3 / 8 * t * cos t := by
    funext t; exact (hx t).deriv
  have hx2 : ∀ t, HasDerivAt (deriv x₁)
      ((-9 * cos (3 * t) + cos t) / 32 - 3 / 4 * cos t + 3 / 8 * t * sin t) t := by
    intro t
    rw [hd]
    have h := ((((((hasDerivAt_id t).const_mul 3).sin).const_mul (-3)).add (hasDerivAt_sin t)).div_const 32).sub
      ((hasDerivAt_sin t).const_mul (3 / 8)) |>.sub
      (((hasDerivAt_id t).const_mul (3 / 8)).mul (hasDerivAt_cos t))
    convert h using 1
    · rfl
    · simp only [id]; ring
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro t
    rw [(hx2 t).deriv]
    simp only [x₁]
    ring
  · simp [x₁]
  · rw [hd]; simp
  · rintro ⟨C, hC⟩
    obtain ⟨n, hn⟩ := exists_nat_gt |C|
    set t : ℝ := π / 2 + n * (2 * π) with ht
    have hs : sin t = 1 := by rw [ht, sin_add_nat_mul_two_pi, sin_pi_div_two]
    have hc1 : |cos (3 * t) - cos t| ≤ 2 := by
      rw [abs_le]; constructor <;>
        nlinarith [neg_one_le_cos (3 * t), cos_le_one (3 * t), neg_one_le_cos t, cos_le_one t]
    have hC' := hC t
    simp only [x₁, hs, mul_one] at hC'
    have hpi := two_le_pi
    have hn0 : (0 : ℝ) ≤ n := Nat.cast_nonneg n
    have htn : t ≥ 1 + 4 * n := by rw [ht]; nlinarith
    have hCabs := le_abs_self C
    have h1 := abs_le.mp hC'
    rw [abs_le] at hc1
    nlinarith [h1.1, h1.2, hc1.1, hc1.2]

/-- The van der Pol slow amplitude. From any starting size `a₀ > 0`,
`a(T) = 2 / √(1 + (4/a₀² - 1) e^(-T))` starts at `a₀`, solves `da/dT = (a/2)(1 - a²/4)` for all
slow times `T ≥ 0`, and settles at amplitude 2. -/
theorem van_der_pol_amplitude_settles_at_two (a₀ : ℝ) (h₀ : 0 < a₀) :
    let amp : ℝ → ℝ := fun T => 2 / √(1 + (4 / a₀ ^ 2 - 1) * exp (-T))
    amp 0 = a₀ ∧
      (∀ T, 0 ≤ T → HasDerivAt amp (amp T / 2 * (1 - amp T ^ 2 / 4)) T) ∧
      Tendsto amp atTop (𝓝 2) := by
  intro amp
  have ha2 : 0 < a₀ ^ 2 := by positivity
  refine ⟨?_, ?_, ?_⟩
  · simp only [amp, neg_zero, exp_zero, mul_one]
    rw [show 1 + (4 / a₀ ^ 2 - 1) = (2 / a₀) ^ 2 by field_simp; ring,
      sqrt_sq (by positivity)]
    field_simp
  · intro T hT
    set c : ℝ := 4 / a₀ ^ 2 - 1 with hc
    have he : exp (-T) ≤ 1 := by rw [exp_le_one_iff]; linarith
    have he0 : 0 < exp (-T) := exp_pos _
    have hq : 0 < 1 + c * exp (-T) := by
      have : 1 + c * exp (-T) = (1 - exp (-T)) + 4 / a₀ ^ 2 * exp (-T) := by rw [hc]; ring
      rw [this]
      have : 0 < 4 / a₀ ^ 2 * exp (-T) := by positivity
      linarith
    have hqd : HasDerivAt (fun T => 1 + c * exp (-T)) (c * (exp (-T) * -1)) T :=
      ((((hasDerivAt_neg T).exp)).const_mul c).const_add 1
    have hs := hqd.sqrt hq.ne'
    have hsp : 0 < √(1 + c * exp (-T)) := sqrt_pos.mpr hq
    have h := (hasDerivAt_const T (2 : ℝ)).div hs hsp.ne'
    convert h using 1
    have hss : √(1 + c * exp (-T)) ^ 2 = 1 + c * exp (-T) := sq_sqrt hq.le
    rw [show amp T = 2 / √(1 + c * exp (-T)) from rfl]
    set s := √(1 + c * exp (-T))
    clear_value s c
    field_simp
    linear_combination 4 * hss
  · set c : ℝ := 4 / a₀ ^ 2 - 1 with hc
    have h1 : Tendsto (fun T => 1 + c * exp (-T)) atTop (𝓝 1) := by
      simpa using (tendsto_exp_neg_atTop_nhds_zero.const_mul c).const_add 1
    have h2 : Tendsto (fun T => √(1 + c * exp (-T))) atTop (𝓝 1) := by
      have := (continuous_sqrt.tendsto 1).comp h1
      rw [sqrt_one] at this
      exact this
    have h3 := (tendsto_const_nhds (x := (2 : ℝ))).div h2 one_ne_zero
    rw [div_one] at h3
    exact h3

-- The small number: k₃ A² / k with k₃ = 800,000 N/m³, A = 10 mm = 1/100 m, k = 800 N/m.
example : (800000 : ℚ) * (1 / 100) ^ 2 / 800 = 1 / 10 := by norm_num
-- Small-motion frequency: 20² = k/m = 800/2, so ω₀ = 20 rad/s.
example : (20 : ℚ) ^ 2 = 800 / 2 := by norm_num
-- Two-timing frequency: 1 + 3ε/8 at ε = 1/10 is 83/80 (1.0375), and 83/80 × 20 rad/s = 83/4 rad/s (20.75).
example : (1 : ℚ) + 3 * (1 / 10) / 8 = 83 / 80 := by norm_num
example : (83 : ℚ) / 80 * 20 = 83 / 4 := by norm_num
-- Van der Pol growth rate at a = 1 is 1/2 - 1/8 = 3/8; at a = 2 it is zero.
example : (1 : ℚ) / 2 * (1 - 1 ^ 2 / 4) = 3 / 8 := by norm_num
example : (2 : ℚ) / 2 * (1 - 2 ^ 2 / 4) = 0 := by norm_num

#print axioms duffing_solvability_condition
#print axioms plain_expansion_correction_is_secular
#print axioms van_der_pol_amplitude_settles_at_two
