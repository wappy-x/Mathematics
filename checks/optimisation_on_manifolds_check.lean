-- Riemannian gradient descent: every step of projected, retracted and transported gradient descent stays on the unit sphere, its search direction lies in the tangent plane, the projected gradient is the steepest tangent direction, and a zero projected gradient of the misfit means the weights are an eigenvector.
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.InnerProductSpace.Calculus
import Mathlib.Analysis.Matrix.Hermitian
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.LinearAlgebra.Matrix.Notation

open RealInnerProductSpace Matrix

/-- Weights `w = (w₁, w₂, w₃)` live in ℝ³ with the ordinary dot product. -/
local notation "ℝ³" => EuclideanSpace ℝ (Fin 3)

/-- The Riemannian gradient on the sphere: the ordinary gradient `∇f(w)` with its part along `w`
removed, `grad f(w) = ∇f(w) - (w · ∇f(w)) w`. -/
noncomputable def rgrad (f : ℝ³ → ℝ) (w : ℝ³) : ℝ³ :=
  gradient f w - ⟪w, gradient f w⟫ • w

/-- The retraction `R_w(v) = (w + v) / |w + v|`: step in the tangent plane, then rescale. -/
noncomputable def retract (w v : ℝ³) : ℝ³ :=
  ‖w + v‖⁻¹ • (w + v)

/-- The vector transport `𝒯_w(d) = d - (w · d) w`: drop the part of `d` along `w`. -/
noncomputable def transport (w d : ℝ³) : ℝ³ :=
  d - ⟪w, d⟫ • w

/-- Riemannian gradient descent with step `α` and momentum share `β`, started at `w₀`.
Entry `k` is the pair `(w_k, d_{k-1})`, with `d_{-1} = 0`. The update is
`d_k = -grad f(w_k) + β 𝒯_{w_k}(d_{k-1})` and `w_{k+1} = R_{w_k}(α d_k)`. -/
noncomputable def rgdState (f : ℝ³ → ℝ) (α β : ℝ) (w₀ : ℝ³) : ℕ → ℝ³ × ℝ³
  | 0 => (w₀, 0)
  | k + 1 =>
      let s := rgdState f α β w₀ k
      let d := -rgrad f s.1 + β • transport s.1 s.2
      (retract s.1 (α • d), d)

/-- Removing the part along a unit vector `w` leaves a vector orthogonal to `w`. -/
theorem inner_sub_inner_smul_self_eq_zero (w g : ℝ³) (hw : ‖w‖ = 1) :
    ⟪w, g - ⟪w, g⟫ • w⟫ = 0 := by
  rw [inner_sub_right, inner_smul_right, real_inner_self_eq_norm_sq, hw]; ring

/-- The retraction of a tangent step at a unit vector is again a unit vector. -/
theorem norm_retract_of_tangent (w v : ℝ³) (hw : ‖w‖ = 1) (hv : ⟪w, v⟫ = 0) :
    ‖retract w v‖ = 1 := by
  have hne : w + v ≠ 0 := by
    intro h
    have hv' : v = -w := eq_neg_of_add_eq_zero_right h
    rw [hv', inner_neg_right, real_inner_self_eq_norm_sq, hw] at hv
    norm_num at hv
  unfold retract
  rw [norm_smul, norm_inv, norm_norm, inv_mul_cancel₀ (norm_ne_zero_iff.mpr hne)]

/-- The inner product with the gradient is the derivative. -/
theorem inner_gradient_eq_fderiv (f : ℝ³ → ℝ) (w v : ℝ³) :
    ⟪gradient f w, v⟫ = fderiv ℝ f w v := by
  unfold gradient
  exact InnerProductSpace.toDual_symm_apply


/-- Riemannian gradient descent keeps every step on the curved set. Start from unit-length
weights `w₀`. For any function `f`, any step size `α` and any momentum share `β`, every iterate
`w_k` has length 1, and every search direction `d_k` (the downhill projected gradient plus the
transported old direction) lies in the tangent plane at `w_k`, that is `w_k · d_k = 0`. -/
theorem riemannian_gradient_descent_stays_on_sphere (f : ℝ³ → ℝ) (α β : ℝ) (w₀ : ℝ³)
    (hw₀ : ‖w₀‖ = 1) (k : ℕ) :
    ‖(rgdState f α β w₀ k).1‖ = 1 ∧
      ⟪(rgdState f α β w₀ k).1, (rgdState f α β w₀ (k + 1)).2⟫ = 0 := by
  have hT : ∀ w d : ℝ³, ‖w‖ = 1 → ⟪w, -rgrad f w + β • transport w d⟫ = 0 := by
    intro w d hw
    rw [inner_add_right, inner_neg_right, inner_smul_right]
    unfold rgrad transport
    rw [inner_sub_inner_smul_self_eq_zero _ _ hw, inner_sub_inner_smul_self_eq_zero _ _ hw]
    ring
  have hN : ∀ k, ‖(rgdState f α β w₀ k).1‖ = 1 := by
    intro k
    induction k with
    | zero => simpa [rgdState] using hw₀
    | succ n ih =>
      simp only [rgdState]
      apply norm_retract_of_tangent _ _ ih
      rw [inner_smul_right, hT _ _ ih, mul_zero]
  refine ⟨hN k, ?_⟩
  simp only [rgdState]
  exact hT _ _ (hN k)

/-- The projected gradient is the steepest direction on the sphere. At a unit vector `w`, the
Riemannian gradient lies in the tangent plane; the rate of change of `f` along a tangent arrow `v`
is `grad f(w) · v`; over unit tangent arrows this rate is never below `-|grad f(w)|`; and when
`grad f(w) ≠ 0` the rate `-|grad f(w)|` is reached along `-grad f(w) / |grad f(w)|`. -/
theorem rgrad_is_steepest_tangent_direction (f : ℝ³ → ℝ) (w : ℝ³) (hw : ‖w‖ = 1) :
    ⟪w, rgrad f w⟫ = 0 ∧
      (∀ v : ℝ³, ⟪w, v⟫ = 0 → fderiv ℝ f w v = ⟪rgrad f w, v⟫) ∧
      (∀ v : ℝ³, ⟪w, v⟫ = 0 → ‖v‖ = 1 → -‖rgrad f w‖ ≤ fderiv ℝ f w v) ∧
      (rgrad f w ≠ 0 → fderiv ℝ f w (-(‖rgrad f w‖⁻¹ • rgrad f w)) = -‖rgrad f w‖) := by
  have h0 : ⟪w, rgrad f w⟫ = 0 := inner_sub_inner_smul_self_eq_zero _ _ hw
  have h1 : ∀ v : ℝ³, ⟪w, v⟫ = 0 → fderiv ℝ f w v = ⟪rgrad f w, v⟫ := by
    intro v hv
    unfold rgrad
    rw [inner_sub_left, inner_smul_left, hv, inner_gradient_eq_fderiv]
    simp
  refine ⟨h0, h1, ?_, ?_⟩
  · intro v hv hv1
    rw [h1 v hv]
    have := abs_real_inner_le_norm (rgrad f w) v
    rw [hv1, mul_one] at this
    exact neg_le_of_abs_le this
  · intro hg
    have ht : ⟪w, -(‖rgrad f w‖⁻¹ • rgrad f w)⟫ = 0 := by
      rw [inner_neg_right, inner_smul_right, h0]; simp
    rw [h1 _ ht, inner_neg_right, inner_smul_right, real_inner_self_eq_norm_sq]
    have hn : ‖rgrad f w‖ ≠ 0 := norm_ne_zero_iff.mpr hg
    field_simp

/-- Zero Riemannian gradient is the Lagrange condition. For a symmetric (covariance) matrix `A`
and the misfit `f(w) = trace A - w · Aw`, a unit vector `w` has zero Riemannian gradient exactly
when `Aw = λ w` for some number `λ`, that is, when `w` is an eigenvector of `A`. -/
theorem rgrad_misfit_eq_zero_iff_eigenvector (A : Matrix (Fin 3) (Fin 3) ℝ) (hA : A.IsHermitian)
    (w : ℝ³) (hw : ‖w‖ = 1) :
    rgrad (fun x => A.trace - ⟪x, Matrix.toEuclideanLin A x⟫) w = 0 ↔
      ∃ μ : ℝ, Matrix.toEuclideanLin A w = μ • w := by
  set T := Matrix.toEuclideanLin A with hTdef
  have hS : T.IsSymmetric := Matrix.isSymmetric_toEuclideanLin_iff.mpr hA
  set Tc : ℝ³ →L[ℝ] ℝ³ := LinearMap.toContinuousLinearMap T with hTc
  have hD : HasFDerivAt (fun x : ℝ³ => A.trace - ⟪x, T x⟫)
      ((-(2 : ℝ)) • (InnerProductSpace.toDual ℝ ℝ³ (T w) : ℝ³ →L[ℝ] ℝ)) w := by
    have hi := HasFDerivAt.inner ℝ (hasFDerivAt_id (𝕜 := ℝ) w) (Tc.hasFDerivAt (x := w))
    have hc := (hasFDerivAt_const (A.trace) w).sub hi
    refine hc.congr_fderiv ?_
    ext v
    simp only [sub_apply, ContinuousLinearMap.comp_apply,
      ContinuousLinearMap.prod_apply, fderivInnerCLM_apply, smul_apply,
      InnerProductSpace.toDual_apply_apply, zero_apply,
      ContinuousLinearMap.id_apply, hTc, LinearMap.coe_toContinuousLinearMap']
    simp only [id, smul_eq_mul]
    linarith [hS w v, real_inner_comm v (T w)]
  have hG : gradient (fun x : ℝ³ => A.trace - ⟪x, T x⟫) w = (-(2 : ℝ)) • T w := by
    apply HasGradientAt.gradient
    rw [hasGradientAt_iff_hasFDerivAt, map_smul]
    exact hD
  unfold rgrad
  rw [hG, inner_smul_right, sub_eq_zero]
  constructor
  · intro h
    refine ⟨⟪w, T w⟫, ?_⟩
    have h2 := congrArg (fun x : ℝ³ => (-(1/2 : ℝ)) • x) h
    simp only [smul_smul] at h2
    norm_num at h2
    simpa [mul_comm] using h2
  · rintro ⟨μ, hμ⟩
    rw [hμ, inner_smul_right, real_inner_self_eq_norm_sq, hw, smul_smul]
    simp

/-! The card's whole-number arithmetic for the school's covariance matrix, in points². -/

-- The diagonal adds to the total spread, 469 points².
example : Matrix.trace !![(225 : ℚ), 144, 45; 144, 144, 30; 45, 30, 100] = 469 := by
  norm_num [Matrix.trace, Fin.sum_univ_three]

-- The row sums of A are (414, 318, 175).
example : !![(225 : ℚ), 144, 45; 144, 144, 30; 45, 30, 100] *ᵥ ![1, 1, 1] = ![414, 318, 175] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_three]

-- Equal weights (1, 1, 1)/√3: spread of the combined score (225 + 144 + 100 + 2·144 + 2·45 + 2·30)/3.
example : (1 / 3 : ℚ) * (![1, 1, 1] ⬝ᵥ (!![(225 : ℚ), 144, 45; 144, 144, 30; 45, 30, 100] *ᵥ ![1, 1, 1]))
    = 907 / 3 := by
  norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_three]

-- Misfit at equal weights 469 - 907/3 = 500/3 (166.667), and the gradient's part along w₀, -2 · 907/3.
example : (469 : ℚ) - 907 / 3 = 500 / 3 ∧ (-2 : ℚ) * (907 / 3) = -1814 / 3 := by norm_num

-- Standard deviations 15, 12, 10 points and correlations 0.80, 0.30, 0.25.
example : (15 : ℚ) ^ 2 = 225 ∧ (12 : ℚ) ^ 2 = 144 ∧ (10 : ℚ) ^ 2 = 100 ∧
    (144 : ℚ) / (15 * 12) = 4 / 5 ∧ (45 : ℚ) / (15 * 10) = 3 / 10 ∧ (30 : ℚ) / (12 * 10) = 1 / 4 := by
  norm_num

#print axioms inner_sub_inner_smul_self_eq_zero
#print axioms norm_retract_of_tangent
#print axioms inner_gradient_eq_fderiv
#print axioms riemannian_gradient_descent_stays_on_sphere
#print axioms rgrad_is_steepest_tangent_direction
#print axioms rgrad_misfit_eq_zero_iff_eigenvector
