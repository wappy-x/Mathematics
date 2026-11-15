-- Weak solutions: for a two-layer wall the weak heat equation holds against every smooth probe exactly when the heat flux is equal on both sides of the joint, and a bounded coercive pairing has exactly one weak solution (Lax-Milgram).
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.InnerProductSpace.LaxMilgram
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.ContDiff.Operations

open scoped ContDiff

theorem weak_residual_aux
    (L₁ L k₁ k₂ T₀ s₁ s₂ : ℝ) (hL₁ : 0 < L₁) (hL : L₁ < L)
    (v : ℝ → ℝ) (hv : ContDiff ℝ ∞ v) (hv0 : v 0 = 0) (hvL : v L = 0) :
    let k : ℝ → ℝ := fun x => if x ≤ L₁ then k₁ else k₂
    let u : ℝ → ℝ := fun x => if x ≤ L₁ then T₀ + s₁ * x else T₀ + s₁ * L₁ + s₂ * (x - L₁)
    ∫ x in (0 : ℝ)..L, k x * deriv u x * deriv v x = (k₁ * s₁ - k₂ * s₂) * v L₁ := by
  intro k u
  have hdiff : Differentiable ℝ v := hv.differentiable (by simp)
  have hcont : Continuous (deriv v) := hv.continuous_deriv (by simp)
  have hu1 : ∀ x, x < L₁ → deriv u x = s₁ := by
    intro x hx
    have he : u =ᶠ[nhds x] fun y => T₀ + s₁ * y := by
      filter_upwards [Iio_mem_nhds hx] with y hy
      simp only [u, (Set.mem_Iio.mp hy).le, ite_true]
    rw [he.deriv_eq]
    exact (((hasDerivAt_id x).const_mul s₁).const_add T₀).deriv.trans (mul_one s₁)
  have hu2 : ∀ x, L₁ < x → deriv u x = s₂ := by
    intro x hx
    have he : u =ᶠ[nhds x] fun y => T₀ + s₁ * L₁ + s₂ * (y - L₁) := by
      filter_upwards [Ioi_mem_nhds hx] with y hy
      simp only [u, not_le.mpr (Set.mem_Ioi.mp hy), ite_false]
    rw [he.deriv_eq]
    exact ((((hasDerivAt_id x).sub_const L₁).const_mul s₂).const_add (T₀ + s₁ * L₁)).deriv.trans
      (mul_one s₂)
  have e1 : Set.EqOn (fun x => k x * deriv u x * deriv v x) (fun x => k₁ * s₁ * deriv v x)
      (Set.uIoo 0 L₁) := by
    intro x hx
    rw [Set.uIoo_of_le hL₁.le] at hx
    simp only [k, hx.2.le, ite_true, hu1 x hx.2]
  have e2 : Set.EqOn (fun x => k x * deriv u x * deriv v x) (fun x => k₂ * s₂ * deriv v x)
      (Set.uIoo L₁ L) := by
    intro x hx
    rw [Set.uIoo_of_le hL.le] at hx
    simp only [k, not_le.mpr hx.1, ite_false, hu2 x hx.1]
  have i1 : IntervalIntegrable (fun x => k x * deriv u x * deriv v x) MeasureTheory.volume 0 L₁ :=
    (intervalIntegrable_congr_uIoo e1).mpr ((hcont.const_mul _).intervalIntegrable _ _)
  have i2 : IntervalIntegrable (fun x => k x * deriv u x * deriv v x) MeasureTheory.volume L₁ L :=
    (intervalIntegrable_congr_uIoo e2).mpr ((hcont.const_mul _).intervalIntegrable _ _)
  rw [← intervalIntegral.integral_add_adjacent_intervals i1 i2,
    intervalIntegral.integral_congr_uIoo e1, intervalIntegral.integral_congr_uIoo e2,
    intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul,
    intervalIntegral.integral_deriv_eq_sub (fun x _ => hdiff x) (hcont.intervalIntegrable _ _),
    intervalIntegral.integral_deriv_eq_sub (fun x _ => hdiff x) (hcont.intervalIntegrable _ _),
    hv0, hvL]
  ring

#print axioms weak_residual_aux

/-- The weak form builds in the joint condition. A wall of thickness `L` has a layer of
conductivity `k₁ > 0` on `0 ≤ x ≤ L₁` and a layer of conductivity `k₂ > 0` beyond it, with no
heat made inside (`f = 0`). Take a temperature profile that is straight in each layer (so the
strong form holds inside each layer), with slope `s₁` in the first layer and `s₂` in the second,
and no jump at the joint. It satisfies the weak form `∫₀ᴸ k u' v' dx = 0` against every smooth
probe `v` that is zero at both faces exactly when the heat flux is the same on both sides of the
joint: `k₁ s₁ = k₂ s₂`. -/
theorem weak_form_iff_equal_flux_at_joint
    (L₁ L k₁ k₂ T₀ s₁ s₂ : ℝ) (hL₁ : 0 < L₁) (hL : L₁ < L) (hk₁ : 0 < k₁) (hk₂ : 0 < k₂) :
    let k : ℝ → ℝ := fun x => if x ≤ L₁ then k₁ else k₂
    let u : ℝ → ℝ := fun x => if x ≤ L₁ then T₀ + s₁ * x else T₀ + s₁ * L₁ + s₂ * (x - L₁)
    (∀ v : ℝ → ℝ, ContDiff ℝ ∞ v → v 0 = 0 → v L = 0 →
        ∫ x in (0 : ℝ)..L, k x * deriv u x * deriv v x = 0) ↔
      k₁ * s₁ = k₂ * s₂ := by
  intro k u
  constructor
  · intro h
    let w : ℝ → ℝ := fun x => x * (L - x)
    have hw : ContDiff ℝ ∞ w := contDiff_id.mul (contDiff_const.sub contDiff_id)
    have hw0 : w 0 = 0 := by simp [w]
    have hwL : w L = 0 := by simp [w]
    have e : ∫ x in (0 : ℝ)..L, k x * deriv u x * deriv w x = (k₁ * s₁ - k₂ * s₂) * w L₁ :=
      weak_residual_aux L₁ L k₁ k₂ T₀ s₁ s₂ hL₁ hL w hw hw0 hwL
    rw [h w hw hw0 hwL] at e
    have hpos : 0 < w L₁ := mul_pos hL₁ (sub_pos.mpr hL)
    have := (mul_eq_zero.mp e.symm).resolve_right hpos.ne'
    linarith
  · intro h v hv hv0 hvL
    have e : ∫ x in (0 : ℝ)..L, k x * deriv u x * deriv v x = (k₁ * s₁ - k₂ * s₂) * v L₁ :=
      weak_residual_aux L₁ L k₁ k₂ T₀ s₁ s₂ hL₁ hL v hv hv0 hvL
    rw [e, h, sub_self, zero_mul]

/-- Every strong solution's weak residual is the flux jump at the joint. For the same two-layer
wall and a profile straight in each layer, and any smooth probe `v` zero at both faces,
`∫₀ᴸ k u' v' dx = (k₁ s₁ − k₂ s₂) v(L₁)`: the flux mismatch at the joint times the probe's
height there. -/
theorem weak_residual_eq_flux_jump_times_probe
    (L₁ L k₁ k₂ T₀ s₁ s₂ : ℝ) (hL₁ : 0 < L₁) (hL : L₁ < L) (hk₁ : 0 < k₁) (hk₂ : 0 < k₂)
    (v : ℝ → ℝ) (hv : ContDiff ℝ ∞ v) (hv0 : v 0 = 0) (hvL : v L = 0) :
    let k : ℝ → ℝ := fun x => if x ≤ L₁ then k₁ else k₂
    let u : ℝ → ℝ := fun x => if x ≤ L₁ then T₀ + s₁ * x else T₀ + s₁ * L₁ + s₂ * (x - L₁)
    ∫ x in (0 : ℝ)..L, k x * deriv u x * deriv v x = (k₁ * s₁ - k₂ * s₂) * v L₁ := by
  exact weak_residual_aux L₁ L k₁ k₂ T₀ s₁ s₂ hL₁ hL v hv hv0 hvL

/-- Lax-Milgram for a weak solution with fixed face values. Let `W` be a real Hilbert space of
profiles (standing for `H¹`) and `V` a closed subspace of profiles zero at the fixed faces
(standing for `H¹₀`). Let the pairing `a` be bounded, `|a(w, v)| ≤ C ‖w‖ ‖v‖`, and coercive on
`V`, `c ‖v‖² ≤ a(v, v)` with `c > 0`, and let the source `ℓ` be a bounded functional. Then for
any profile `g` with the right face values there is exactly one correction `w` in `V` with
`a(w, v) = ℓ(v) − a(g, v)` for every `v` in `V`; the weak solution is `u = g + w`. -/
theorem exists_unique_weak_solution_of_bounded_coercive
    {W : Type*} [NormedAddCommGroup W] [InnerProductSpace ℝ W] [CompleteSpace W]
    (V : Submodule ℝ W) (hV : IsClosed (V : Set W))
    (a : W →L[ℝ] W →L[ℝ] ℝ) (c C : ℝ) (hc : 0 < c)
    (hbound : ∀ w v, |a w v| ≤ C * ‖w‖ * ‖v‖)
    (hcoer : ∀ v ∈ V, c * ‖v‖ ^ 2 ≤ a v v)
    (ℓ : W →L[ℝ] ℝ) (g : W) :
    ∃! w : V, ∀ v : V, a w v = ℓ v - a g v := by
  have : CompleteSpace V := hV.completeSpace_coe
  let B : V →L[ℝ] V →L[ℝ] ℝ := a.bilinearComp V.subtypeL V.subtypeL
  have hB : ∀ w v : V, B w v = a w v := fun w v => rfl
  have hBc : IsCoercive B := by
    refine ⟨c, hc, fun v => ?_⟩
    rw [hB]
    have := hcoer v v.2
    have hn : ‖(v : W)‖ = ‖v‖ := rfl
    rw [hn] at this
    nlinarith
  let f : StrongDual ℝ V := (ℓ - a g).comp V.subtypeL
  let y : V := (InnerProductSpace.toDual ℝ V).symm f
  refine ⟨hBc.continuousLinearEquivOfBilin.symm y, ?_, ?_⟩
  · intro v
    rw [← hB, ← hBc.continuousLinearEquivOfBilin_apply,
      ContinuousLinearEquiv.apply_symm_apply, InnerProductSpace.toDual_symm_apply]
    rfl
  · intro w hw
    apply hBc.continuousLinearEquivOfBilin.injective
    rw [ContinuousLinearEquiv.apply_symm_apply]
    apply (InnerProductSpace.toDual ℝ V).injective
    rw [LinearIsometryEquiv.apply_symm_apply]
    ext v
    rw [InnerProductSpace.toDual_apply_apply,
      hBc.continuousLinearEquivOfBilin_apply, hB, hw v]
    rfl

-- The wall, in exact rationals: wool k₁ = 0.035 = 7/200, brick k₂ = 0.77 = 77/100 W/(m K),
-- layers 1/10 m each, faces 20 °C and 0 °C. Joint 20/23 ≈ 0.8696 °C, slopes −4400/23 ≈ −191.30
-- and −200/23 ≈ −8.70 K/m: equal flux, and the profile reaches 0 °C at the outer face.
example :
    (7 / 200 : ℚ) * (-4400 / 23) = 77 / 100 * (-200 / 23) ∧
    (20 : ℚ) + (-4400 / 23) * (1 / 10) = 20 / 23 ∧
    (20 / 23 : ℚ) + (-200 / 23) * (1 / 10) = 0 := by
  norm_num
-- Resistances in series: 20 / (0.1/0.035 + 0.1/0.77) = 154/23 ≈ 6.6957 W/m², the flux −k₁ s₁.
example : (20 : ℚ) / ((1 / 10) / (7 / 200) + (1 / 10) / (77 / 100)) = 154 / 23 ∧
    -((7 / 200 : ℚ) * (-4400 / 23)) = 154 / 23 := by
  norm_num
-- Minimum energy a(u, u) = 3080/23 ≈ 133.9130 = flux × temperature drop; the straight line scores 805.
example : (7 / 200 : ℚ) * (-4400 / 23) ^ 2 * (1 / 10) + 77 / 100 * (-200 / 23) ^ 2 * (1 / 10)
      = 3080 / 23 ∧ (154 / 23 : ℚ) * 20 = 3080 / 23 := by
  norm_num
example : (7 / 200 : ℚ) * (-100) ^ 2 * (1 / 10) + 77 / 100 * (-100) ^ 2 * (1 / 10) = 805 := by
  norm_num
-- The straight line's flux mismatch at the joint: k₁ s₁ − k₂ s₂ = 73.5 = 147/2 (the probe's
-- residual is e⁻¹ times this); its fluxes are 3.5 and 77 W/m².
example : (7 / 200 : ℚ) * (-100) - 77 / 100 * (-100) = 147 / 2 ∧
    (7 / 200 : ℚ) * 100 = 7 / 2 ∧ (77 / 100 : ℚ) * 100 = 77 := by
  norm_num
-- Lax-Milgram constants c = 0.035, C = 0.77: the ratio C / c is 22.
example : (77 / 100 : ℚ) / (7 / 200) = 22 := by norm_num

#print axioms weak_form_iff_equal_flux_at_joint
#print axioms weak_residual_eq_flux_jump_times_probe
#print axioms exists_unique_weak_solution_of_bounded_coercive
