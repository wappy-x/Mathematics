-- Pullback: pulling a 2-form f dx∧dy back through a smooth map of the plane gives (f ∘ F) det J_F du∧dv, pullbacks of two maps in a row come in reverse order, and integrating a pullback is change of variables with the sign of det J_F kept.
import Mathlib.Analysis.Calculus.DifferentialForm.Basic
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Normed.Module.Alternating.Basic
import Mathlib.Topology.Algebra.Module.Determinant
import Mathlib.LinearAlgebra.Determinant
import Mathlib.MeasureTheory.Function.Jacobian
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open MeasureTheory

/-! The plane is `Fin 2 → ℝ`: an arrow `v` has coordinates `v 0` (x) and `v 1` (y).
A 2-form field is `ω : (Fin 2 → ℝ) → (Fin 2 → ℝ) [⋀^Fin 2]→L[ℝ] ℝ`.
`dx ∧ dy` (and likewise `du ∧ dv` on the input plane) is the standard area form
`(Pi.basisFun ℝ (Fin 2)).det`, which sends two arrows to the signed area they span.
The pullback of `ω` through `F` at `p` is Mathlib's
`(ω (F p)).compContinuousLinearMap (fderiv ℝ F p)`: carry the two arrows forward through
the differential of `F`, then measure them with `ω` at `F p`. -/

/-- Helper: a 2-form on the plane evaluated on the images of the unit arrows under a linear
map `A` is `det A` times its value on the unit arrows. -/
theorem form_comp_basis (η : (Fin 2 → ℝ) [⋀^Fin 2]→L[ℝ] ℝ) (A : (Fin 2 → ℝ) →L[ℝ] (Fin 2 → ℝ)) :
    η.compContinuousLinearMap A (Pi.basisFun ℝ (Fin 2))
      = A.det * η (Pi.basisFun ℝ (Fin 2)) := by
  have h := congrArg (fun g : (Fin 2 → ℝ) [⋀^Fin 2]→ₗ[ℝ] ℝ =>
      g ((A : (Fin 2 → ℝ) →ₗ[ℝ] (Fin 2 → ℝ)) ∘ Pi.basisFun ℝ (Fin 2)))
    (η.toAlternatingMap.eq_smul_basis_det (Pi.basisFun ℝ (Fin 2)))
  rw [_root_.smul_apply, smul_eq_mul, Module.Basis.det_comp,
    Module.Basis.det_self, mul_one] at h
  rw [ContinuousAlternatingMap.compContinuousLinearMap_apply, ContinuousLinearMap.det]
  exact h.trans (mul_comm _ _)

#print axioms form_comp_basis

/-- Determinant rule. If `F` is a smooth map of the plane and `ω = f dx ∧ dy`, then the
pullback `F*ω` at every point `p` is `(f ∘ F)(p) · det J_F(p) · du ∧ dv`: the pulled-back
form is the form's coefficient at the image place times the signed area stretch of `F`. -/
theorem pullback_two_form_eq_comp_mul_det
    (F : (Fin 2 → ℝ) → (Fin 2 → ℝ)) (hF : ContDiff ℝ ((⊤ : ℕ∞) : WithTop ℕ∞) F)
    (f : (Fin 2 → ℝ) → ℝ) (ω : (Fin 2 → ℝ) → (Fin 2 → ℝ) [⋀^Fin 2]→L[ℝ] ℝ)
    (hω : ∀ y v, ω y v = f y * (Pi.basisFun ℝ (Fin 2)).det v)
    (p : Fin 2 → ℝ) (v : Fin 2 → (Fin 2 → ℝ)) :
    (ω (F p)).compContinuousLinearMap (fderiv ℝ F p) v
      = (f (F p) * (fderiv ℝ F p).det) * (Pi.basisFun ℝ (Fin 2)).det v := by
  have hw : (ω (F p)).compContinuousLinearMap (fderiv ℝ F p) v
      = ω (F p) ((fderiv ℝ F p : (Fin 2 → ℝ) →ₗ[ℝ] (Fin 2 → ℝ)) ∘ v) := rfl
  rw [hw, hω, Module.Basis.det_comp]
  simp only [ContinuousLinearMap.det]
  ring

/-- Order reversal. For smooth maps `H` then `G` of the plane, pulling a 2-form back through
the composite `G ∘ H` is the same as pulling it back through `G` first and then through `H`:
`(G ∘ H)* = H* G*`. -/
theorem pullback_comp_eq_pullback_pullback
    (G H : (Fin 2 → ℝ) → (Fin 2 → ℝ))
    (hG : ContDiff ℝ ((⊤ : ℕ∞) : WithTop ℕ∞) G) (hH : ContDiff ℝ ((⊤ : ℕ∞) : WithTop ℕ∞) H)
    (ω : (Fin 2 → ℝ) → (Fin 2 → ℝ) [⋀^Fin 2]→L[ℝ] ℝ) (p : Fin 2 → ℝ) :
    (ω ((G ∘ H) p)).compContinuousLinearMap (fderiv ℝ (G ∘ H) p)
      = ((ω (G (H p))).compContinuousLinearMap (fderiv ℝ G (H p))).compContinuousLinearMap
          (fderiv ℝ H p) := by
  have hGd : Differentiable ℝ G := hG.differentiable (by simp)
  have hHd : Differentiable ℝ H := hH.differentiable (by simp)
  rw [fderiv_comp p (hGd (H p)) (hHd p)]
  ext v
  rfl

/-- Integral identity. Let `F` be a smooth map of the plane, one-to-one on a region `S`,
whose Jacobian determinant has one sign `ε = ±1` on `S` except on a set of zero area.
Integrate 2-forms with the standard orientation, so `∫_S h du∧dv = ∫_S h`, the value of a
form on the unit arrows `e_u, e_v` being its coefficient. Then the integral of the pullback
over `S` is `ε` times the integral of the form over the image `F(S)`: `+` when `F` keeps
orientation, `−` when it reverses it. -/
theorem integral_pullback_eq_sign_mul_integral
    (F : (Fin 2 → ℝ) → (Fin 2 → ℝ)) (hF : ContDiff ℝ ((⊤ : ℕ∞) : WithTop ℕ∞) F)
    (S : Set (Fin 2 → ℝ)) (hS : MeasurableSet S) (hinj : Set.InjOn F S)
    (ε : ℝ) (hε : ε = 1 ∨ ε = -1)
    (hsign : ∀ᵐ x ∂(volume.restrict S), 0 < ε * (fderiv ℝ F x).det)
    (ω : (Fin 2 → ℝ) → (Fin 2 → ℝ) [⋀^Fin 2]→L[ℝ] ℝ) :
    ∫ x in S, (ω (F x)).compContinuousLinearMap (fderiv ℝ F x) (Pi.basisFun ℝ (Fin 2))
      = ε * ∫ y in F '' S, ω y (Pi.basisFun ℝ (Fin 2)) := by
  have hHd : Differentiable ℝ F := hF.differentiable (by simp)
  have key : ∀ x, (ω (F x)).compContinuousLinearMap (fderiv ℝ F x) (Pi.basisFun ℝ (Fin 2))
      = (fderiv ℝ F x).det * ω (F x) (Pi.basisFun ℝ (Fin 2)) := by
    intro x
    exact form_comp_basis _ _
  simp_rw [key]
  rw [integral_image_eq_integral_abs_det_fderiv_smul volume hS
    (fun x _ => (hHd x).hasFDerivAt.hasFDerivWithinAt) hinj, ← integral_const_mul]
  refine integral_congr_ae ?_
  filter_upwards [hsign] with x hx
  simp only [smul_eq_mul]
  rcases hε with rfl | rfl
  · rw [abs_of_pos (by simpa using hx)]; ring
  · rw [abs_of_neg (by linarith)]; ring

/-! The card's worked numbers, exactly (the card's decimals written as fractions). -/

-- The radar map (r sin α, r cos α) has Jacobian determinant x_r y_α − x_α y_r = −r.
example (r a : ℝ) :
    Real.sin a * (-(r * Real.sin a)) - r * Real.cos a * Real.cos a = -r := by
  have h := Real.sin_sq_add_cos_sq a
  linear_combination (-r) * h

-- Rain at the marked cell's centre: 20 + 10 × 2.25 = 42.5 mm.
example : (20 : ℚ) + 10 * (9 / 4) = 85 / 2 := by
  norm_num

-- Pulled-back rain coefficient there: 42.5 × (−2.25) = −95.625.
example : (85 / 2 : ℚ) * (-(9 / 4)) = -765 / 8 := by
  norm_num

-- The raster map G(c, k) = (0.25c, 3 − 0.25k) has determinant −0.0625.
example : Matrix.det !![(1 / 4 : ℚ), 0; 0, -(1 / 4)] = -1 / 16 := by
  simp [Matrix.det_fin_two]; norm_num

-- Two stages agree with one: 42.5 × (−0.0625) × 36 = −95.625.
example : (85 / 2 : ℚ) * (-1 / 16) * 36 = -765 / 8 := by
  norm_num

-- Range part over the whole valley: ∫₀³ (20 + 10r) r dr = 90 + 90 = 180.
example : ∫ r in (0 : ℝ)..3, (20 + 10 * r) * r = 180 := by
  have : (fun r : ℝ => (20 + 10 * r) * r) = fun r => 20 * r + 10 * r ^ 2 := by
    funext r; ring
  rw [this, intervalIntegral.integral_add, intervalIntegral.integral_const_mul,
    intervalIntegral.integral_const_mul, integral_id, integral_pow]
  · norm_num
  · exact (continuous_const.mul continuous_id).intervalIntegrable _ _
  · exact (continuous_const.mul (continuous_pow 2)).intervalIntegrable _ _

-- Pullback integral in the order (r, α): −(π/2 − π/6) × 180 = −60π; flipped once, 60π.
example : -((Real.pi / 2 - Real.pi / 6) * 180) = -(60 * Real.pi) := by
  ring

#print axioms pullback_two_form_eq_comp_mul_det
#print axioms pullback_comp_eq_pullback_pullback
#print axioms integral_pullback_eq_sign_mul_integral
