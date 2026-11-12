-- Symplectic steps: a Verlet step keeps phase-space area exactly for any pull that depends on the angle only, while an RK4 step on a small swing scales area by 1 - z^6/72 + z^8/576 with z = ωh.
import Mathlib.Analysis.Calculus.FDeriv.Prod
import Mathlib.Analysis.Calculus.FDeriv.Mul
import Mathlib.Analysis.Calculus.FDeriv.Comp
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Topology.Algebra.Module.Determinant
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.MeasureTheory.Measure.Prod

open MeasureTheory

/-- One velocity-Verlet step (kick, drift, kick) of size `h` for `θ' = p`, `p' = F θ`,
applied to the phase-space point `x = (θ, p)`: half a kick of pull, a whole drift at the
new speed, then the second half kick at the new angle. -/
noncomputable def verletStep (F : ℝ → ℝ) (h : ℝ) (x : ℝ × ℝ) : ℝ × ℝ :=
  let p₁ := x.2 + h / 2 * F x.1
  let θ₁ := x.1 + h * p₁
  (θ₁, p₁ + h / 2 * F θ₁)

/-- One classical Runge-Kutta four step of size `h` for `θ' = p`, `p' = F θ`, applied to
`x = (θ, p)`, with the four slope samples `k₁, …, k₄` of `p'` written out as in the card's code. -/
noncomputable def rk4Step (F : ℝ → ℝ) (h : ℝ) (x : ℝ × ℝ) : ℝ × ℝ :=
  let θ := x.1
  let p := x.2
  let k₁ := F θ
  let k₂ := F (θ + h / 2 * p)
  let k₃ := F (θ + h / 2 * (p + h / 2 * k₁))
  let k₄ := F (θ + h * (p + h / 2 * k₂))
  (θ + h * (p + h / 6 * (k₁ + k₂ + k₃)), p + h / 6 * (k₁ + 2 * k₂ + 2 * k₃ + k₄))

/-- The pendulum's pull `p' = -ω² sin θ`. -/
noncomputable def pendulumPull (ω : ℝ) (θ : ℝ) : ℝ := -ω ^ 2 * Real.sin θ


/-- The determinant of a linear map of the plane from its values on `(1, 0)` and `(0, 1)`. -/
lemma det_plane (L : ℝ × ℝ →L[ℝ] ℝ × ℝ) :
    L.det = (L (1, 0)).1 * (L (0, 1)).2 - (L (0, 1)).1 * (L (1, 0)).2 := by
  rw [ContinuousLinearMap.det, ← LinearMap.det_toMatrix (Module.Basis.finTwoProd ℝ), Matrix.det_fin_two]
  simp [LinearMap.toMatrix_apply, Module.Basis.finTwoProd_zero, Module.Basis.finTwoProd_one]

/-- A map of the plane that is linear in coordinates has its coefficient determinant as
the determinant of its derivative. -/
lemma det_fderiv_linear (f : ℝ × ℝ → ℝ × ℝ) (a b c d : ℝ)
    (hf : ∀ x, f x = (x.1 * a + x.2 * b, x.1 * c + x.2 * d)) (x : ℝ × ℝ) :
    (fderiv ℝ f x).det = a * d - b * c := by
  have hL : f = ⇑(((ContinuousLinearMap.fst ℝ ℝ ℝ).smulRight a
      + (ContinuousLinearMap.snd ℝ ℝ ℝ).smulRight b).prod
      ((ContinuousLinearMap.fst ℝ ℝ ℝ).smulRight c
      + (ContinuousLinearMap.snd ℝ ℝ ℝ).smulRight d)) := by
    funext y
    rw [hf y]
    simp
  rw [hL, ContinuousLinearMap.fderiv, det_plane]
  simp

/-- The kick: a shear `(θ, p) ↦ (θ, p + k · F θ)`. -/
noncomputable def kickMap (F : ℝ → ℝ) (k : ℝ) (x : ℝ × ℝ) : ℝ × ℝ := (x.1, x.2 + k * F x.1)

/-- The drift: a shear `(θ, p) ↦ (θ + h p, p)`. -/
noncomputable def driftMap (h : ℝ) (x : ℝ × ℝ) : ℝ × ℝ := (x.1 + h * x.2, x.2)

lemma det_comp_plane (A B : ℝ × ℝ →L[ℝ] ℝ × ℝ) : (A.comp B).det = A.det * B.det :=
  LinearMap.det_comp (A : ℝ × ℝ →ₗ[ℝ] ℝ × ℝ) (B : ℝ × ℝ →ₗ[ℝ] ℝ × ℝ)

lemma verletStep_eq (F : ℝ → ℝ) (h : ℝ) :
    verletStep F h = kickMap F (h / 2) ∘ driftMap h ∘ kickMap F (h / 2) := by
  funext x
  rfl

lemma kickMap_hasFDerivAt (F : ℝ → ℝ) (hF : Differentiable ℝ F) (k : ℝ) (x : ℝ × ℝ) :
    HasFDerivAt (kickMap F k) ((ContinuousLinearMap.fst ℝ ℝ ℝ).prod
      (ContinuousLinearMap.snd ℝ ℝ ℝ
        + k • (ContinuousLinearMap.fst ℝ ℝ ℝ).smulRight (deriv F x.1))) x := by
  have h1 : HasFDerivAt (fun y : ℝ × ℝ => F y.1)
      ((ContinuousLinearMap.fst ℝ ℝ ℝ).smulRight (deriv F x.1)) x := by
    have := (hF x.1).hasDerivAt.comp_hasFDerivAt x (hasFDerivAt_fst (𝕜 := ℝ) (p := x))
    exact this.congr_fderiv (ContinuousLinearMap.ext fun v => by simp [mul_comm])
  exact hasFDerivAt_fst.prodMk (hasFDerivAt_snd.add (h1.const_mul k))

lemma kickMap_det (F : ℝ → ℝ) (hF : Differentiable ℝ F) (k : ℝ) (x : ℝ × ℝ) :
    (fderiv ℝ (kickMap F k) x).det = 1 := by
  rw [(kickMap_hasFDerivAt F hF k x).fderiv, det_plane]
  simp

lemma driftMap_det (h : ℝ) (x : ℝ × ℝ) : (fderiv ℝ (driftMap h) x).det = 1 := by
  rw [det_fderiv_linear (driftMap h) 1 h 0 1 (fun y => by simp [driftMap]; ring)]
  ring

lemma kickMap_differentiable (F : ℝ → ℝ) (hF : Differentiable ℝ F) (k : ℝ) :
    Differentiable ℝ (kickMap F k) := fun x => (kickMap_hasFDerivAt F hF k x).differentiableAt

lemma driftMap_differentiable (h : ℝ) : Differentiable ℝ (driftMap h) := by
  unfold driftMap
  fun_prop

lemma kickMap_measurePreserving (F : ℝ → ℝ) (hF : Measurable F) (k : ℝ) :
    MeasurePreserving (kickMap F k) volume volume := by
  have := (MeasurePreserving.id (volume : Measure ℝ)).skew_product
    (μc := (volume : Measure ℝ)) (μd := (volume : Measure ℝ))
    (g := fun a c => c + k * F a) (by fun_prop)
    (Filter.Eventually.of_forall fun a => map_add_right_eq_self volume (k * F a))
  exact this

lemma driftMap_measurePreserving (h : ℝ) :
    MeasurePreserving (driftMap h) volume volume := by
  have hs : MeasurePreserving (Prod.swap : ℝ × ℝ → ℝ × ℝ) volume volume :=
    Measure.measurePreserving_swap
  have hk := kickMap_measurePreserving id measurable_id h
  have : driftMap h = Prod.swap ∘ kickMap id h ∘ Prod.swap := by
    funext x
    simp [driftMap, kickMap]
  rw [this]
  exact hs.comp (hk.comp hs)

/-- Verlet keeps area: for any pull `F` that depends on the angle only, at every step size `h`
and at every state `(θ, p)`, the Jacobian of one Verlet step has determinant 1, because kick,
drift and kick are each shears with determinant 1. -/
theorem verlet_step_preserves_area (F : ℝ → ℝ) (hF : Differentiable ℝ F) (h : ℝ)
    (x : ℝ × ℝ) : (fderiv ℝ (verletStep F h) x).det = 1 := by
  rw [verletStep_eq]
  have hK := kickMap_differentiable F hF (h / 2)
  have hD := driftMap_differentiable h
  rw [fderiv_comp x (hK _) ((hD.comp hK) x), fderiv_comp x (hD _) (hK x),
    det_comp_plane, det_comp_plane, kickMap_det F hF, driftMap_det, kickMap_det F hF]
  ring

/-- Each Verlet step on the frictionless pendulum `θ' = p`, `p' = -ω² sin θ` keeps the area of
every patch of the `(θ, p)` phase plane: the step map preserves Lebesgue measure on the plane. -/
theorem verlet_step_pendulum_keeps_every_area (ω h : ℝ) :
    MeasurePreserving (verletStep (pendulumPull ω) h) volume volume := by
  have hF : Measurable (pendulumPull ω) := by
    unfold pendulumPull
    fun_prop
  rw [verletStep_eq]
  exact (kickMap_measurePreserving _ hF _).comp
    ((driftMap_measurePreserving h).comp (kickMap_measurePreserving _ hF _))

/-- RK4 shrinks area: on a small swing, where the pendulum is the spring `p' = -ω² θ`, the
Jacobian of one RK4 step has determinant `|R(iz)|² = 1 - z^6/72 + z^8/576` with `z = ωh`,
at every state. -/
theorem rk4_step_spring_area_factor (ω h : ℝ) (x : ℝ × ℝ) :
    (fderiv ℝ (rk4Step (fun θ => -ω ^ 2 * θ) h) x).det
      = 1 - (ω * h) ^ 6 / 72 + (ω * h) ^ 8 / 576 := by
  rw [det_fderiv_linear _ (rk4Step (fun θ => -ω ^ 2 * θ) h (1, 0)).1
    (rk4Step (fun θ => -ω ^ 2 * θ) h (0, 1)).1 (rk4Step (fun θ => -ω ^ 2 * θ) h (1, 0)).2
    (rk4Step (fun θ => -ω ^ 2 * θ) h (0, 1)).2 (fun y => by
      simp only [rk4Step, Prod.mk.injEq]
      constructor <;> ring)]
  simp only [rk4Step]
  ring

-- The coefficients of |R(iz)|² from the card's detailed proof, power by power.
example : (-1 : ℚ) + 1 = 0 := by norm_num
example : (1 / 4 : ℚ) + 1 / 12 - 1 / 3 = 0 := by norm_num
example : -(1 / 24 : ℚ) + 1 / 36 = -1 / 72 := by norm_num
example : ((1 : ℚ) / 24) ^ 2 = 1 / 576 := by norm_num

-- Step counts: a million swings at 20 steps a swing, 100,000 swings, and the sine counts.
example : 1000000 * 20 = 20000000 := by norm_num
example : 100000 * 20 = 2000000 := by norm_num
example : 20000000 + 1 = 20000001 := by norm_num
example : 4 * 20000000 = 80000000 := by norm_num

#print axioms det_plane
#print axioms det_fderiv_linear
#print axioms det_comp_plane
#print axioms verletStep_eq
#print axioms kickMap_hasFDerivAt
#print axioms kickMap_det
#print axioms driftMap_det
#print axioms kickMap_differentiable
#print axioms driftMap_differentiable
#print axioms kickMap_measurePreserving
#print axioms driftMap_measurePreserving
#print axioms verlet_step_preserves_area
#print axioms verlet_step_pendulum_keeps_every_area
#print axioms rk4_step_spring_area_factor
