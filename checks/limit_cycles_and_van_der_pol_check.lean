-- Limit cycles: in the polar model r' = r(1 - r^2) every start off the origin is pulled onto the unit circle, the closed form solves the law, and van der Pol's spring energy changes at rate mu(1 - x^2)v^2.
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.ODE.ExistUnique
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Notation

open Filter Topology

/-- The closed-form profile `1 / √(1 + c e^(-2t))` tends to 1. -/
lemma closedForm_tendsto_one (c : ℝ) :
    Tendsto (fun t : ℝ => 1 / Real.sqrt (1 + c * Real.exp (-2 * t))) atTop (𝓝 1) := by
  have h1 : Tendsto (fun t : ℝ => Real.exp (-2 * t)) atTop (𝓝 0) := by
    have := Real.tendsto_exp_neg_atTop_nhds_zero.comp
      (tendsto_id.const_mul_atTop (show (0:ℝ) < 2 by norm_num))
    refine this.congr (fun t => ?_)
    simp [Function.comp, neg_mul]
  have h2 : Tendsto (fun t : ℝ => 1 + c * Real.exp (-2 * t)) atTop (𝓝 (1 + c * 0)) :=
    tendsto_const_nhds.add (h1.const_mul c)
  have h3 := h2.sqrt.inv₀ (by simp)
  simpa [one_div] using h3

/-- For `t ≥ 0` and `r0 > 0`, the quantity `1 + (1/r0^2 - 1) e^(-2t)` is positive. -/
lemma closedForm_denom_pos (r0 : ℝ) (h0 : 0 < r0) (t : ℝ) (ht : 0 ≤ t) :
    0 < 1 + (1 / r0 ^ 2 - 1) * Real.exp (-2 * t) := by
  have he : Real.exp (-2 * t) ≤ 1 := by
    rw [Real.exp_le_one_iff]; linarith
  have he' : 0 < Real.exp (-2 * t) := Real.exp_pos _
  have hr : 0 < 1 / r0 ^ 2 := by positivity
  nlinarith


/-- The unit circle of the polar model is a limit cycle that attracts every start but the origin:
if the distance `r` from the origin obeys `r' = r (1 - r^2)` from time 0 on and starts at any
`r 0 > 0`, then `r t` tends to 1 as time runs on, from inside or from outside. -/
theorem polar_model_every_start_spirals_onto_unit_circle (r : ℝ → ℝ) (hr0 : 0 < r 0)
    (hr : ∀ t, 0 ≤ t → HasDerivAt r (r t * (1 - r t ^ 2)) t) :
    Tendsto r atTop (𝓝 1) := by
  set c := 1 / r 0 ^ 2 - 1 with hc
  -- k measures the failure of `r^2 (1 + c e^(-2t)) = 1`.
  set k : ℝ → ℝ := fun t => 1 - r t ^ 2 * (1 + c * Real.exp (-2 * t)) with hk
  have hkd : ∀ t, 0 ≤ t → HasDerivAt k (-2 * r t ^ 2 * k t) t := by
    intro t ht
    have hE : HasDerivAt (fun s => 1 + c * Real.exp (-2 * s))
        (c * (Real.exp (-2 * t) * (-2))) t := by
      have := ((hasDerivAt_id t).const_mul (-2)).exp
      simpa using (this.const_mul c).const_add 1
    have := (((hr t ht).pow 2).mul hE).const_sub 1
    convert this using 1
    simp only [hk, Pi.pow_apply]
    push_cast
    ring
  have hcont : ContinuousOn r (Set.Ici 0) := fun t ht =>
    (hr t ht).continuousAt.continuousWithinAt
  have hk2 : AntitoneOn (fun t => k t ^ 2) (Set.Ici 0) := by
    apply antitoneOn_of_deriv_nonpos (convex_Ici 0)
    · intro t ht
      exact ((hkd t ht).pow 2).continuousAt.continuousWithinAt
    · intro t ht
      rw [interior_Ici] at ht
      exact ((hkd t (le_of_lt ht)).pow 2).differentiableAt.differentiableWithinAt
    · intro t ht
      rw [interior_Ici] at ht
      change deriv (k ^ 2) t ≤ 0
      rw [((hkd t (le_of_lt ht)).pow 2).deriv]
      have : (↑(2:ℕ) : ℝ) * k t ^ (2 - 1) * (-2 * r t ^ 2 * k t) = -4 * (r t * k t) ^ 2 := by
        push_cast; ring
      rw [this]
      nlinarith [sq_nonneg (r t * k t)]
  have hk0 : k 0 = 0 := by
    simp only [hk, mul_zero, Real.exp_zero, mul_one, hc]
    field_simp
    ring
  have hkz : ∀ t, 0 ≤ t → k t = 0 := by
    intro t ht
    have := hk2 ((Set.mem_Ici.mpr le_rfl)) (Set.mem_Ici.mpr ht) ht
    simp only [hk0] at this
    have : k t ^ 2 = 0 := le_antisymm (by simpa using this) (sq_nonneg _)
    exact pow_eq_zero_iff (n := 2) (by norm_num) |>.mp this
  have hpos : ∀ t, 0 ≤ t → 0 < r t := by
    intro t ht
    by_contra hneg
    push Not at hneg
    have hivt := intermediate_value_Icc' ht (hcont.mono (Set.Icc_subset_Ici_self))
    obtain ⟨s, hs, hs0⟩ := hivt ⟨hneg, hr0.le⟩
    have := hkz s hs.1
    simp only [hk, hs0] at this
    norm_num at this
  have heq : ∀ t, 0 ≤ t → r t = 1 / Real.sqrt (1 + c * Real.exp (-2 * t)) := by
    intro t ht
    have h1 := hkz t ht
    simp only [hk] at h1
    have hD := closedForm_denom_pos (r 0) hr0 t ht
    rw [← hc] at hD
    have hrt := hpos t ht
    have hsq : r t ^ 2 = 1 / (1 + c * Real.exp (-2 * t)) := by
      rw [eq_div_iff hD.ne']; linarith
    rw [← Real.sqrt_sq hrt.le, hsq, Real.sqrt_div' _ hD.le, Real.sqrt_one]
  refine (closedForm_tendsto_one c).congr' ?_
  filter_upwards [eventually_ge_atTop 0] with t ht
  exact (heq t ht).symm

/-- The closed form of the polar model: for a start `r0 > 0`,
`r(t) = 1 / √(1 + (1/r0^2 - 1) e^(-2t))` starts at `r0`, obeys `r' = r (1 - r^2)` for all
`t ≥ 0`, and tends to 1, the gap fading like `e^(-2t)`. -/
theorem polar_model_closed_form (r0 : ℝ) (h0 : 0 < r0) :
    let R : ℝ → ℝ := fun t => 1 / Real.sqrt (1 + (1 / r0 ^ 2 - 1) * Real.exp (-2 * t))
    R 0 = r0 ∧ (∀ t, 0 ≤ t → HasDerivAt R (R t * (1 - R t ^ 2)) t) ∧ Tendsto R atTop (𝓝 1) := by
  intro R
  refine ⟨?_, ?_, closedForm_tendsto_one _⟩
  · simp only [R, mul_zero, Real.exp_zero, mul_one, add_sub_cancel]
    rw [Real.sqrt_div' 1 (sq_nonneg r0), Real.sqrt_sq h0.le, Real.sqrt_one]
    field_simp
  · intro t ht
    set c := 1 / r0 ^ 2 - 1 with hc
    have hD := closedForm_denom_pos r0 h0 t ht
    rw [← hc] at hD
    have hE : HasDerivAt (fun s => 1 + c * Real.exp (-2 * s))
        (c * (Real.exp (-2 * t) * (-2))) t := by
      have := ((hasDerivAt_id t).const_mul (-2)).exp
      simpa using (this.const_mul c).const_add 1
    have hS := hE.sqrt hD.ne'
    have hR := (hasDerivAt_const t (1:ℝ)).div hS (Real.sqrt_pos.mpr hD).ne'
    convert hR using 1
    have hs := Real.sqrt_pos.mpr hD
    have hsq := Real.sq_sqrt hD.le
    show 1 / Real.sqrt (1 + c * Real.exp (-2 * t)) *
      (1 - (1 / Real.sqrt (1 + c * Real.exp (-2 * t))) ^ 2) = _
    generalize Real.sqrt (1 + c * Real.exp (-2 * t)) = s at hs hsq ⊢
    generalize Real.exp (-2 * t) = E at hsq ⊢
    field_simp
    linear_combination hsq

/-- Van der Pol trades energy: along any path of `x' = v`, `v' = μ (1 - x^2) v - x`, the spring's
energy `E = (x^2 + v^2)/2` changes at rate `μ (1 - x^2) v^2`, so energy flows in while
`-1 < x < 1` and drains outside (for `μ > 0`). -/
theorem van_der_pol_energy_rate (μ : ℝ) (x v : ℝ → ℝ) (t : ℝ)
    (hx : HasDerivAt x (v t) t) (hv : HasDerivAt v (μ * (1 - x t ^ 2) * v t - x t) t) :
    HasDerivAt (fun s => (x s ^ 2 + v s ^ 2) / 2) (μ * (1 - x t ^ 2) * v t ^ 2) t := by
  have h := ((hx.pow 2).add (hv.pow 2)).div_const 2
  convert h using 1
  push_cast
  ring

-- Worked numbers: the offset of the start r0 = 1/10 is 1/r0^2 - 1 = 99.
example : (1 / (1 / 10 : ℚ) ^ 2 - 1) = 99 := by norm_num

-- From r0 = 2 the offset is negative: 1/4 - 1 = -3/4.
example : (1 / (2 : ℚ) ^ 2 - 1) = -3 / 4 := by norm_num

-- Van der Pol with μ = 1: the Jacobian at the rest point is [[0, 1], [-1, 1]],
-- with trace 1 and determinant 1.
example : Matrix.trace !![(0 : ℤ), 1; -1, 1] = 1 := by
  norm_num [Matrix.trace, Fin.sum_univ_two]

example : Matrix.det !![(0 : ℤ), 1; -1, 1] = 1 := by
  norm_num [Matrix.det_fin_two]

-- Trace squared minus four times the determinant is 1 - 4 = -3 < 0, so the eigenvalues
-- (1 ± √-3)/2 are complex with real part 1/2 > 0: a spiral source.
example : (1 : ℤ) ^ 2 - 4 * 1 = -3 ∧ (1 : ℚ) / 2 > 0 := by norm_num

#print axioms closedForm_tendsto_one
#print axioms closedForm_denom_pos
#print axioms polar_model_every_start_spirals_onto_unit_circle
#print axioms polar_model_closed_form
#print axioms van_der_pol_energy_rate
