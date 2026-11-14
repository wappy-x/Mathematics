-- Linearisation: at a rest of a differentiable plant the rates and readings equal their first-order slopes times the offsets plus a leftover that shrinks faster than the offsets, with the cart-and-pole slopes and cubic leftover as cases.
import Mathlib.Analysis.Calculus.FDeriv.Prod
import Mathlib.Analysis.Calculus.FDeriv.Mul
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds
import Mathlib.LinearAlgebra.Matrix.Notation

open Asymptotics Filter Topology Matrix

/-- Helper: the first-order remainder of a map differentiable at `(xe, ue)`, written with the slopes
against each component of the product, shrinks faster than the offset. -/
theorem linearisation_remainder_aux
    {E F G : Type*}
    [NormedAddCommGroup E] [NormedSpace ℝ E] [NormedAddCommGroup F] [NormedSpace ℝ F]
    [NormedAddCommGroup G] [NormedSpace ℝ G]
    (φ : E × F → G) (xe : E) (ue : F) (hφ : DifferentiableAt ℝ φ (xe, ue)) :
    (fun d : E × F => (φ (xe + d.1, ue + d.2) - φ (xe, ue))
        - ((fderiv ℝ φ (xe, ue)).comp (ContinuousLinearMap.inl ℝ E F) d.1
          + (fderiv ℝ φ (xe, ue)).comp (ContinuousLinearMap.inr ℝ E F) d.2))
      =o[𝓝 0] (fun d => d) := by
  have := hasFDerivAt_iff_isLittleO_nhds_zero.mp hφ.hasFDerivAt
  refine this.congr_left (fun d => ?_)
  have e1 : (xe, ue) + d = (xe + d.1, ue + d.2) := rfl
  have e2 : (fderiv ℝ φ (xe, ue)) d
      = (fderiv ℝ φ (xe, ue)) (d.1, 0) + (fderiv ℝ φ (xe, ue)) (0, d.2) := by
    rw [← map_add]; simp
  rw [e1, e2]; simp

#print axioms linearisation_remainder_aux

/-- Linearisation about an operating point. Let `x' = f (x, u)` and `y = h (x, u)` be a plant
whose rules are smooth (differentiable, no kink) at a point `(xe, ue)` that really is a rest,
`f (xe, ue) = 0`. Take `A, B` as the slopes of `f` against the state and the input, and `C, D`
as the slopes of `h`, all at `(xe, ue)`. Then for offsets `(δx, δu)` the rates are
`A δx + B δu` plus a leftover, the reading offsets `h (xe + δx, ue + δu) - h (xe, ue)` are
`C δx + D δu` plus a leftover, and both leftovers shrink faster than the offsets. -/
theorem linearisation_about_rest
    {E F G H : Type*}
    [NormedAddCommGroup E] [NormedSpace ℝ E] [NormedAddCommGroup F] [NormedSpace ℝ F]
    [NormedAddCommGroup G] [NormedSpace ℝ G] [NormedAddCommGroup H] [NormedSpace ℝ H]
    (f : E × F → G) (h : E × F → H) (xe : E) (ue : F)
    (hf : DifferentiableAt ℝ f (xe, ue)) (hh : DifferentiableAt ℝ h (xe, ue))
    (hrest : f (xe, ue) = 0) :
    let A := (fderiv ℝ f (xe, ue)).comp (ContinuousLinearMap.inl ℝ E F)
    let B := (fderiv ℝ f (xe, ue)).comp (ContinuousLinearMap.inr ℝ E F)
    let C := (fderiv ℝ h (xe, ue)).comp (ContinuousLinearMap.inl ℝ E F)
    let D := (fderiv ℝ h (xe, ue)).comp (ContinuousLinearMap.inr ℝ E F)
    (fun d : E × F => f (xe + d.1, ue + d.2) - (A d.1 + B d.2)) =o[𝓝 0] (fun d => d) ∧
    (fun d : E × F => (h (xe + d.1, ue + d.2) - h (xe, ue)) - (C d.1 + D d.2))
      =o[𝓝 0] (fun d => d) := by
  intro A B C D
  refine ⟨?_, linearisation_remainder_aux h xe ue hh⟩
  refine (linearisation_remainder_aux f xe ue hf).congr_left (fun d => ?_)
  simp only [hrest, sub_zero]
  rfl

/-- The cart and pole, at a held lean `θe` (upright is `θe = 0`). The push `ue = g tan θe`
holds the lean still: the lean's rate `(g sin θ - u cos θ) / l` is zero there. Its slopes
there are `g / (l cos θe)` against the lean and `-cos θe / l` against the push; at upright these
are `g / l` and `-1 / l`. -/
theorem cart_pole_slopes_at_held_lean (g l θe : ℝ) (hc : Real.cos θe ≠ 0) :
    let ue := g * Real.tan θe
    (g * Real.sin θe - ue * Real.cos θe) / l = 0 ∧
    HasFDerivAt (fun q : ℝ × ℝ => (g * Real.sin q.1 - q.2 * Real.cos q.1) / l)
      ((g / (l * Real.cos θe)) • ContinuousLinearMap.fst ℝ ℝ ℝ
        - (Real.cos θe / l) • ContinuousLinearMap.snd ℝ ℝ ℝ) (θe, ue) := by
  intro ue
  refine ⟨?_, ?_⟩
  · simp only [ue, Real.tan_eq_sin_div_cos]
    field_simp
    ring
  · have h1 : HasFDerivAt (fun q : ℝ × ℝ => Real.sin q.1)
        (Real.cos θe • ContinuousLinearMap.fst ℝ ℝ ℝ) (θe, ue) :=
      (hasFDerivAt_fst (p := (θe, ue))).sin
    have h2 : HasFDerivAt (fun q : ℝ × ℝ => Real.cos q.1)
        (-Real.sin θe • ContinuousLinearMap.fst ℝ ℝ ℝ) (θe, ue) :=
      (hasFDerivAt_fst (p := (θe, ue))).cos
    have h3 : HasFDerivAt (fun q : ℝ × ℝ => q.2) (ContinuousLinearMap.snd ℝ ℝ ℝ) (θe, ue) :=
      hasFDerivAt_snd
    have h4 := ((h1.const_mul g).sub (h3.mul h2)).mul_const l⁻¹
    have hfun : (fun q : ℝ × ℝ => (g * Real.sin q.1 - q.2 * Real.cos q.1) / l)
        = (fun q : ℝ × ℝ => (g * Real.sin q.1 - q.2 * Real.cos q.1) * l⁻¹) := by
      funext q; rw [div_eq_mul_inv]
    rw [hfun]
    convert h4 using 1
    ext <;> simp [ue, Real.tan_eq_sin_div_cos] <;> field_simp
    linear_combination (-(g * l⁻¹)) * Real.sin_sq_add_cos_sq θe

/-- At upright the leftover that the straight model drops from gravity's push starts at the
cube: `θ - sin θ` is `θ ^ 3 / 6` up to a term that shrinks faster than `θ ^ 3`. -/
theorem pole_leftover_is_cubic :
    (fun θ : ℝ => (θ - Real.sin θ) - θ ^ 3 / 6) =o[𝓝 0] (fun θ : ℝ => θ ^ 3) := by
  have hb : (fun θ : ℝ => (θ - Real.sin θ) - θ ^ 3 / 6) =O[𝓝 0] (fun θ : ℝ => θ ^ 5) := by
    refine Asymptotics.IsBigO.of_bound (1 / 100) ?_
    have : ∀ᶠ θ : ℝ in 𝓝 0, |θ| ≤ 1 := by
      have := Metric.closedBall_mem_nhds (0 : ℝ) one_pos
      filter_upwards [this] with θ hθ
      simpa [Real.dist_eq] using hθ
    filter_upwards [this] with θ hθ
    have := Real.sin_bound hθ
    rw [Real.norm_eq_abs, Real.norm_eq_abs, abs_pow]
    calc |θ - Real.sin θ - θ ^ 3 / 6| = |Real.sin θ - (θ - θ ^ 3 / 6)| := by
          rw [← abs_neg]; ring_nf
      _ ≤ |θ| ^ 5 / 100 := this
      _ = 1 / 100 * |θ| ^ 5 := by ring
  exact hb.trans_isLittleO (Asymptotics.isLittleO_pow_pow (m := 3) (n := 5) (by norm_num))

-- The card's pole: g = 9.81 m/s² over l = 0.613125 m is exactly 16 per s².
example : (981 / 100 : ℚ) / (613125 / 1000000) = 16 := by norm_num

-- The upright A: (0, 0, 1, 4) is a motion growing at +4 per s.
example : (!![0, 1, 0, 0; 0, 0, 0, 0; 0, 0, 0, 1; 0, 0, 16, 0] : Matrix (Fin 4) (Fin 4) ℤ)
    *ᵥ ![0, 0, 1, 4] = (4 : ℤ) • ![0, 0, 1, 4] := by decide

-- The upright A: (0, 0, 1, -4) is a motion dying at -4 per s.
example : (!![0, 1, 0, 0; 0, 0, 0, 0; 0, 0, 0, 1; 0, 0, 16, 0] : Matrix (Fin 4) (Fin 4) ℤ)
    *ᵥ ![0, 0, 1, -4] = (-4 : ℤ) • ![0, 0, 1, -4] := by decide

-- The upright A: (1, 0, 0, 0) is the cart's eigenvalue 0 (a still offset in position).
example : (!![0, 1, 0, 0; 0, 0, 0, 0; 0, 0, 0, 1; 0, 0, 16, 0] : Matrix (Fin 4) (Fin 4) ℤ)
    *ᵥ ![1, 0, 0, 0] = 0 := by decide

-- The balancing rule u = l (32 θ + 8 ω) on θ'' = 16 θ - u / l gives θ'' = -16 θ - 8 ω,
-- whose characteristic polynomial s² + 8 s + 16 has the double root -4.
example : (16 : ℤ) - 32 = -16 ∧ (-4 : ℤ) ^ 2 + 8 * (-4) + 16 = 0 := by norm_num

#print axioms linearisation_about_rest
#print axioms cart_pole_slopes_at_held_lean
#print axioms pole_leftover_is_cubic
