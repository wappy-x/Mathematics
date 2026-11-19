-- Riemannian Hessian: on the unit sphere, the Riemannian Hessian is the projected ordinary Hessian minus the outward part of the gradient times the step, and the trust-region ratio for the rank-1 recommender is 1/(1 + |v|^2).
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.InnerProductSpace.Calculus
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Data.Matrix.Mul
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

open Matrix

/-! The surrounding space is a real inner product space `E` (ordinary 3D space on the card).
A point `x` of the unit sphere has `‖x‖ = 1`; its tangent plane is all `v` with `⟪x, v⟫ = 0`;
the projection onto it is `P_x u = u - ⟪x, u⟫ x`.
`∇f` is Mathlib's `gradient f`, and the ordinary Hessian applied to `v` is
`fderiv ℝ (gradient f) x v`. The Riemannian gradient field is `grad f(y) = ∇f(y) - ⟪y, ∇f(y)⟫ y`,
and the Riemannian Hessian is its derivative along `v`, projected back onto the tangent plane. -/

/-- The sphere formula for the Riemannian Hessian: differentiating the Riemannian gradient field
along a tangent vector `v` and projecting onto the tangent plane gives the projected ordinary
Hessian minus the outward part of the ordinary gradient times the step,
`Hess f(x)[v] = P_x(∇²f(x) v) - (x ⬝ ∇f(x)) v`, for a twice differentiable `f`. -/
theorem riemannian_hessian_sphere_formula {E : Type*} [NormedAddCommGroup E]
    [InnerProductSpace ℝ E] [CompleteSpace E]
    (f : E → ℝ) (hf : Differentiable ℝ f) (hf2 : Differentiable ℝ (gradient f))
    (x v : E) (hx : ‖x‖ = 1) (hxv : inner ℝ x v = 0) :
    let P : E → E := fun u => u - inner ℝ x u • x
    let rgrad : E → E := fun y => gradient f y - inner ℝ y (gradient f y) • y
    P (fderiv ℝ rgrad x v) = P (fderiv ℝ (gradient f) x v) - inner ℝ x (gradient f x) • v := by
  intro P rgrad
  have hxx : inner ℝ x x = (1:ℝ) := by
    rw [real_inner_self_eq_norm_sq, hx]; norm_num
  have hg := hf2 x
  have hin : DifferentiableAt ℝ (fun y => inner ℝ y (gradient f y)) x :=
    differentiableAt_id.inner ℝ hg
  have h1 : fderiv ℝ rgrad x v = fderiv ℝ (gradient f) x v
      - ((inner ℝ x (gradient f x)) • v
        + (inner ℝ x (fderiv ℝ (gradient f) x v) + inner ℝ v (gradient f x)) • x) := by
    have := (hg.hasFDerivAt.sub ((hin.hasFDerivAt).smul (hasFDerivAt_id x)))
    rw [show rgrad
      = gradient f - (fun y => inner ℝ y (gradient f y)) • id from rfl, this.fderiv]
    have hI : fderiv ℝ (fun y => inner ℝ y (gradient f y)) x v
        = inner ℝ x (fderiv ℝ (gradient f) x v) + inner ℝ v (gradient f x) := by
      have h := fderiv_inner_apply ℝ (f := fun y : E => y) differentiableAt_fun_id hg v
      rw [h, fderiv_fun_id, ContinuousLinearMap.id_apply]
    simp only [sub_apply, add_apply, smul_apply, ContinuousLinearMap.smulRight_apply,
      ContinuousLinearMap.id_apply, id, hI]
  rw [h1]
  simp only [P, inner_sub_right, inner_add_right, inner_smul_right, hxv, hxx]
  module

/-- Step 1: the second derivative of `f` along the great circle `γ(t) = cos t · x + sin t · v`
through a point `x` of the sphere, in a unit tangent direction `v`, is the ordinary curvature
along `v` minus the outward part of the gradient:
`d²/dt² f(γ(t)) at t = 0 = vᵀ ∇²f(x) v - xᵀ ∇f(x) = ⟪v, Hess f(x)[v]⟫`. -/
theorem second_derivative_along_great_circle {E : Type*} [NormedAddCommGroup E]
    [InnerProductSpace ℝ E] [CompleteSpace E]
    (f : E → ℝ) (hf : Differentiable ℝ f) (hf2 : Differentiable ℝ (gradient f))
    (x v : E) (hx : ‖x‖ = 1) (hv : ‖v‖ = 1) (hxv : inner ℝ x v = 0) :
    deriv (deriv fun t : ℝ => f (Real.cos t • x + Real.sin t • v)) 0
      = inner ℝ v (fderiv ℝ (gradient f) x v) - inner ℝ x (gradient f x) := by
  set γ : ℝ → E := fun t => Real.cos t • x + Real.sin t • v with hγdef
  set γ' : ℝ → E := fun t => (-Real.sin t) • x + Real.cos t • v with hγ'def
  have hγ : ∀ t, HasDerivAt γ (γ' t) t := fun t =>
    ((Real.hasDerivAt_cos t).smul_const x).add ((Real.hasDerivAt_sin t).smul_const v)
  have hγ'' : HasDerivAt γ' ((-Real.cos 0) • x + (-Real.sin 0) • v) 0 :=
    ((Real.hasDerivAt_sin 0).neg.smul_const x).add ((Real.hasDerivAt_cos 0).smul_const v)
  have h1 : deriv (fun t => f (γ t)) = fun t => inner ℝ (gradient f (γ t)) (γ' t) := by
    funext t
    have := (hf (γ t)).hasGradientAt.hasFDerivAt.comp_hasDerivAt t (hγ t)
    rw [show (fun t => f (γ t)) = f ∘ γ from rfl, this.deriv]
    simp
  show deriv (deriv fun t => f (γ t)) 0 = _
  rw [h1]
  have h2 : HasDerivAt (fun t => gradient f (γ t)) (fderiv ℝ (gradient f) x v) 0 := by
    have := (hf2 (γ 0)).hasFDerivAt.comp_hasDerivAt 0 (hγ 0)
    simpa [γ, γ', Function.comp_def] using this
  have h3 := h2.inner ℝ hγ''
  rw [h3.deriv]
  simp [γ, γ', real_inner_comm]
  ring

/-- Step 3: for the rank-1 error `f(y) = ‖M‖² - yᵀ C y` with `C = Mᵀ M`, at a unit `x` and a
tangent step `v`, the fall delivered by the retraction `R_x(v) = (x + v)/|x + v|` equals the
fall promised by the quadratic model with the Riemannian gradient and Hessian, divided by
`1 + |v|²`. So the trust-region ratio is `ρ = 1/(1 + |v|²)` whenever the promise is nonzero. -/
theorem trust_region_ratio_closed_form {m n : ℕ} (M : Matrix (Fin m) (Fin n) ℝ)
    (x v : Fin n → ℝ) (hx : x ⬝ᵥ x = 1) (hxv : x ⬝ᵥ v = 0) :
    let C := Mᵀ * M
    let f : (Fin n → ℝ) → ℝ := fun y => (∑ i, ∑ j, M i j ^ 2) - y ⬝ᵥ (C *ᵥ y)
    let P : (Fin n → ℝ) → (Fin n → ℝ) := fun u => u - (x ⬝ᵥ u) • x
    let egrad : Fin n → ℝ := -(2 : ℝ) • (C *ᵥ x)
    let rgrad : Fin n → ℝ := P egrad
    let hess : (Fin n → ℝ) → (Fin n → ℝ) := fun w => P (-(2 : ℝ) • (C *ᵥ w)) - (x ⬝ᵥ egrad) • w
    let R : Fin n → ℝ := (Real.sqrt ((x + v) ⬝ᵥ (x + v)))⁻¹ • (x + v)
    let promised : ℝ := -(rgrad ⬝ᵥ v + (1 / 2) * (v ⬝ᵥ hess v))
    f x - f R = promised / (1 + v ⬝ᵥ v) := by
  intro C f P egrad rgrad hess R promised
  have hvx : v ⬝ᵥ x = 0 := by rw [dotProduct_comm]; exact hxv
  have hsymm : v ⬝ᵥ (C *ᵥ x) = x ⬝ᵥ (C *ᵥ v) := by
    have hC : Cᵀ = C := by simp [C, transpose_mul]
    rw [dotProduct_mulVec, ← mulVec_transpose, hC, dotProduct_comm]
  have hnorm : (x + v) ⬝ᵥ (x + v) = 1 + v ⬝ᵥ v := by
    simp only [add_dotProduct, dotProduct_add, hx, hxv, hvx]; ring
  have hq : 0 ≤ v ⬝ᵥ v := by
    simp only [dotProduct]; exact Finset.sum_nonneg fun i _ => mul_self_nonneg (v i)
  have hpos : 0 < 1 + v ⬝ᵥ v := by linarith
  set s := Real.sqrt ((x + v) ⬝ᵥ (x + v)) with hs
  have hs2 : s ^ 2 = 1 + v ⬝ᵥ v := by
    rw [hs, Real.sq_sqrt (by rw [hnorm]; exact hpos.le), hnorm]
  have hspos : 0 < s := by rw [hs, hnorm]; exact Real.sqrt_pos.mpr hpos
  have hfR : f x - f R = s⁻¹ ^ 2 * ((x + v) ⬝ᵥ (C *ᵥ (x + v))) - x ⬝ᵥ (C *ᵥ x) := by
    simp only [f, R, mulVec_smul, dotProduct_smul, smul_dotProduct, smul_eq_mul]
    ring
  have hexp : (x + v) ⬝ᵥ (C *ᵥ (x + v))
      = x ⬝ᵥ (C *ᵥ x) + 2 * (x ⬝ᵥ (C *ᵥ v)) + v ⬝ᵥ (C *ᵥ v) := by
    simp only [mulVec_add, add_dotProduct, dotProduct_add, hsymm]; ring
  have hprom : promised = 2 * (x ⬝ᵥ (C *ᵥ v)) + v ⬝ᵥ (C *ᵥ v)
      - (x ⬝ᵥ (C *ᵥ x)) * (v ⬝ᵥ v) := by
    have hsymm' : (C *ᵥ x) ⬝ᵥ v = x ⬝ᵥ (C *ᵥ v) := by rw [dotProduct_comm, hsymm]
    simp only [promised, rgrad, hess, P, egrad, sub_dotProduct, smul_dotProduct,
      dotProduct_sub, dotProduct_smul, smul_eq_mul, hvx, hxv, hsymm']
    ring
  rw [hfR, hexp, hprom, inv_pow, hs2]
  field_simp
  ring

/-! The card's whole-number worked examples. -/

/-- The ratings table: 4 listeners by 3 songs. -/
def ratings : Matrix (Fin 4) (Fin 3) ℤ := !![5, 4, 1; 4, 5, 2; 1, 2, 5; 2, 1, 4]

/-- The co-rating table `C = Mᵀ M`. -/
def corating : Matrix (Fin 3) (Fin 3) ℤ := !![46, 44, 26; 44, 46, 28; 26, 28, 46]

-- C = Mᵀ M has rows (46, 44, 26), (44, 46, 28), (26, 28, 46).
example : ratingsᵀ * ratings = corating := by decide
-- ‖M‖² = 138.
example : ∑ i, ∑ j, ratings i j ^ 2 = 138 := by decide
-- Error at the start x₀ = (0, 0, 1): 138 - x₀ᵀ C x₀ = 92.
example : 138 - ![0, 0, 1] ⬝ᵥ (corating *ᵥ ![0, 0, 1]) = 92 := by decide
-- Ordinary gradient at x₀: -2 C x₀ = (-52, -56, -92); its outward part is -92.
example : -(2 : ℤ) • (corating *ᵥ ![0, 0, 1]) = ![-52, -56, -92] := by decide
-- Riemannian Hessian at x₀ on songs 1 and 2: the projected part (-92, -88), (-88, -92)
-- plus the correction +92 on the diagonal gives (0, -88), (-88, 0).
example : !![(-92 : ℤ), -88; -88, -92] + 92 • (1 : Matrix (Fin 2) (Fin 2) ℤ)
    = !![0, -88; -88, 0] := by decide
-- Its determinant is -88², so its eigenvalues are -88 and 88.
example : (!![(0 : ℤ), -88; -88, 0]).det = -88 ^ 2 := by
  simp [Matrix.det_fin_two]
-- Road one: ⟪v, Hess v⟫ = -176 along v = (1, 1, 0) and 352 along v = (1, -2, 0).
example : ![(1 : ℤ), 1] ⬝ᵥ (!![0, -88; -88, 0] *ᵥ ![1, 1]) = -176 := by decide
example : ![(1 : ℤ), -2] ⬝ᵥ (!![0, -88; -88, 0] *ᵥ ![1, -2]) = 352 := by decide
-- The saddle: the song mix (5, 4, -11) is an eigenvector of C with eigenvalue λ₂ = 24.
example : corating *ᵥ ![5, 4, -11] = (24 : ℤ) • ![5, 4, -11] := by decide
-- The other two eigenvalues satisfy λ₁ + λ₃ = 138 - 24 = 114 and λ₁ λ₃ = det C / 24 = 216.
example : corating.det = 24 * 216 := by
  simp [Matrix.det_fin_three, corating]

#print axioms riemannian_hessian_sphere_formula
#print axioms second_derivative_along_great_circle
#print axioms trust_region_ratio_closed_form
