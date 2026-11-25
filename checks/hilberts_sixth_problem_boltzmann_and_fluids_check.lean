-- Hilbert's sixth problem: the exact pieces of the chain, namely that the Boltzmann-Grad scaling keeps the mean free path fixed while the volume fraction goes to 0, that keeping the packing fixed instead sends the free path to 0, and that a hard-sphere collision keeps momentum and energy.
import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Topology.Algebra.Order.Field

open Filter Topology

/-- Boltzmann's mean free path for hard spheres of diameter `d` at `n` spheres per unit volume:
`λ = 1 / (√2 π d² n)`. -/
noncomputable def meanFreePath (n d : ℝ) : ℝ := 1 / (Real.sqrt 2 * Real.pi * d ^ 2 * n)

/-- The volume fraction: the share of space filled by `n` spheres of diameter `d` per unit
volume, `φ = n π d³ / 6`. -/
noncomputable def volumeFraction (n d : ℝ) : ℝ := n * Real.pi * d ^ 3 / 6

/-- The Boltzmann-Grad limit: shrink the diameter by a factor `c` and multiply the number of
spheres by `c²`, so that `N d²` stays fixed. Then the mean free path `1 / (√2 π d² n)` does not
change at all, while the volume fraction `n π d³ / 6` goes to 0 as `c` grows: the gas becomes
dilute. -/
theorem boltzmann_grad_scaling_keeps_mean_free_path (n d : ℝ) :
    (∀ c : ℝ, c ≠ 0 → meanFreePath (c ^ 2 * n) (d / c) = meanFreePath n d) ∧
    Tendsto (fun c : ℝ => volumeFraction (c ^ 2 * n) (d / c)) atTop (𝓝 0) := by
  refine ⟨fun c hc => ?_, ?_⟩
  · unfold meanFreePath
    congr 1
    field_simp
  · have h : ∀ᶠ c : ℝ in atTop, (n * Real.pi * d ^ 3 / 6) / c =
        volumeFraction (c ^ 2 * n) (d / c) := by
      filter_upwards [eventually_gt_atTop 0] with c hc
      unfold volumeFraction
      field_simp
    exact (tendsto_const_nhds.div_atTop tendsto_id).congr' h

/-- What breaks: shrink the diameter by `c` but multiply the number of spheres by `c³`, keeping
`N d³` and so the packing fixed. Then the volume fraction does not change, and the mean free path
goes to 0: the limit is a dense fluid, not Boltzmann's gas. -/
theorem fixed_packing_sends_mean_free_path_to_zero (n d : ℝ) :
    (∀ c : ℝ, c ≠ 0 → volumeFraction (c ^ 3 * n) (d / c) = volumeFraction n d) ∧
    Tendsto (fun c : ℝ => meanFreePath (c ^ 3 * n) (d / c)) atTop (𝓝 0) := by
  refine ⟨fun c hc => ?_, ?_⟩
  · unfold volumeFraction
    field_simp
  · have h : ∀ᶠ c : ℝ in atTop, (1 / (Real.sqrt 2 * Real.pi * d ^ 2 * n)) / c =
        meanFreePath (c ^ 3 * n) (d / c) := by
      filter_upwards [eventually_gt_atTop 0] with c hc
      unfold meanFreePath
      rw [div_div]
      congr 1
      field_simp
    exact (tendsto_const_nhds.div_atTop tendsto_id).congr' h

/-- A hard-sphere collision with unit direction `ω` joining the centres sends `v, v₁` to
`v' = v + ((v₁ - v)·ω) ω` and `v₁' = v₁ - ((v₁ - v)·ω) ω`. It keeps the total momentum
`v + v₁` and the total kinetic energy `|v|² + |v₁|²` (equal masses). -/
theorem hard_sphere_collision_conserves_momentum_and_energy
    {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (v v₁ ω : E) (hω : ‖ω‖ = 1) :
    (v + inner ℝ (v₁ - v) ω • ω) + (v₁ - inner ℝ (v₁ - v) ω • ω) = v + v₁ ∧
    ‖v + inner ℝ (v₁ - v) ω • ω‖ ^ 2 + ‖v₁ - inner ℝ (v₁ - v) ω • ω‖ ^ 2 =
      ‖v‖ ^ 2 + ‖v₁‖ ^ 2 := by
  have hω2 : inner ℝ ω ω = (1 : ℝ) := by
    rw [real_inner_self_eq_norm_sq, hω]; norm_num
  refine ⟨by abel, ?_⟩
  rw [norm_add_sq_real, norm_sub_sq_real, inner_smul_right, inner_smul_right, norm_smul,
    hω, Real.norm_eq_abs, mul_one, sq_abs]
  have : inner ℝ (v₁ - v) ω = inner ℝ v₁ ω - inner ℝ v ω := inner_sub_left _ _ _
  rw [this]
  ring

-- The card's table: halve d three times and multiply N by 4 each time; N d² does not change.
example : (4 : ℚ) ^ 1 * (1 / 2 ^ 1) ^ 2 = 1 ∧ (4 : ℚ) ^ 2 * (1 / 2 ^ 2) ^ 2 = 1 ∧
    (4 : ℚ) ^ 3 * (1 / 2 ^ 3) ^ 2 = 1 := by norm_num

-- What breaks: shrinking d by 8 with N d³ fixed multiplies N by 512.
example : (8 : ℕ) ^ 3 = 512 := by decide

-- What breaks: the radius in place of the diameter makes the target area 4 times smaller.
example : (1 / 2 : ℚ) ^ 2 = 1 / 4 := by norm_num

-- The simulation: 48 boxes of 64 spheres is 3,072 spheres.
example : 48 * 64 = 3072 := by decide

#print axioms boltzmann_grad_scaling_keeps_mean_free_path
#print axioms fixed_packing_sends_mean_free_path_to_zero
#print axioms hard_sphere_collision_conserves_momentum_and_energy
