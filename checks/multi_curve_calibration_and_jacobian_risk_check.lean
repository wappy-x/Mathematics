-- Solving every curve at once: when the model quotes have an invertible Jacobian J at the solved nodes, rebuilding the curves from the quotes moves the nodes at rates J⁻¹, so a trade's quote risk is (J⁻¹)ᵀ times its node risk, the unique solution of Jᵀ Rq = Rz.
import Mathlib.Analysis.Calculus.InverseFunctionTheorem.FDeriv
import Mathlib.Analysis.Calculus.FDeriv.Mul
import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Topology.Algebra.Module.FiniteDimension

open Matrix Filter Topology

variable {m : ℕ}

/-- A risk vector `R` read as a derivative: the linear map `v ↦ ∑ⱼ R j * v j`.
Node risk is the value's derivative in the nodes in this form, quote risk its derivative in the
quotes (both per unit move; times 1 bp they are dollars per bp). -/
noncomputable def riskMap (R : Fin m → ℝ) : (Fin m → ℝ) →L[ℝ] ℝ :=
  ∑ j, R j • ContinuousLinearMap.proj j

/-- A risk map evaluated on a vector is the dot product of the risk vector with it. -/
theorem riskMap_apply (R v : Fin m → ℝ) : riskMap R v = R ⬝ᵥ v := by
  simp [riskMap, dotProduct, smul_eq_mul]

#print axioms riskMap_apply

/-- The rebuild and the risk conversion (Step 4).
Let `q` send the `m` nodes to the `m` model quotes, smooth near the solved nodes `x₀`, with
Jacobian `J` there, and let `J` be invertible (as many independent quotes as nodes). Let a trade's
value `V` have node risk `Rz` at `x₀`. Then there is a rebuild `x(p)` of the nodes from the quotes:
it gives back `x₀` at today's quotes `q x₀`, it reprices every nearby quote list `p` exactly, and
it moves the nodes at rates `J⁻¹`. The rebuilt value `p ↦ V(x(p))` has quote risk `(J⁻¹)ᵀ Rz`. -/
theorem quote_risk_eq_inverse_transpose (q : (Fin m → ℝ) → (Fin m → ℝ))
    (V : (Fin m → ℝ) → ℝ) (x₀ : Fin m → ℝ) (J : Matrix (Fin m) (Fin m) ℝ)
    (hJ : IsUnit J.det) (Rz : Fin m → ℝ)
    (hq : HasStrictFDerivAt q (LinearMap.toContinuousLinearMap (Matrix.toLin' J)) x₀)
    (hV : HasFDerivAt V (riskMap Rz) x₀) :
    ∃ x : (Fin m → ℝ) → (Fin m → ℝ), x (q x₀) = x₀ ∧ (∀ᶠ p in 𝓝 (q x₀), q (x p) = p) ∧
      HasFDerivAt x (LinearMap.toContinuousLinearMap (Matrix.toLin' J⁻¹)) (q x₀) ∧
      HasFDerivAt (fun p => V (x p)) (riskMap (J⁻¹ᵀ *ᵥ Rz)) (q x₀) := by
  have : Invertible J := J.invertibleOfIsUnitDet hJ
  let e : (Fin m → ℝ) ≃L[ℝ] (Fin m → ℝ) :=
    (Matrix.toLinearEquiv' J ‹Invertible J›).toContinuousLinearEquiv
  have he : (e : (Fin m → ℝ) →L[ℝ] (Fin m → ℝ)) =
      LinearMap.toContinuousLinearMap (Matrix.toLin' J) := by
    ext v i; rfl
  have hq' : HasStrictFDerivAt q (e : (Fin m → ℝ) →L[ℝ] (Fin m → ℝ)) x₀ := by rw [he]; exact hq
  have hsymm : (e.symm : (Fin m → ℝ) →L[ℝ] (Fin m → ℝ)) =
      LinearMap.toContinuousLinearMap (Matrix.toLin' J⁻¹) := by
    ext1 v
    apply e.injective
    show e (e.symm v) = _
    rw [e.apply_symm_apply]
    show v = J *ᵥ (J⁻¹ *ᵥ v)
    rw [Matrix.mulVec_mulVec, Matrix.mul_nonsing_inv _ hJ, Matrix.one_mulVec]
  refine ⟨hq'.localInverse q e x₀, hq'.localInverse_apply_image, hq'.eventually_right_inverse,
    ?_, ?_⟩
  · rw [← hsymm]; exact hq'.to_localInverse.hasFDerivAt
  · have hx := hq'.to_localInverse.hasFDerivAt
    rw [hsymm] at hx
    have hV' : HasFDerivAt V (riskMap Rz) (hq'.localInverse q e x₀ (q x₀)) := by
      rw [hq'.localInverse_apply_image]; exact hV
    refine (hV'.comp (q x₀) hx).congr_fderiv ?_
    ext1 v
    rw [ContinuousLinearMap.comp_apply, riskMap_apply, riskMap_apply,
      LinearMap.coe_toContinuousLinearMap', Matrix.toLin'_apply, Matrix.dotProduct_mulVec,
      Matrix.mulVec_transpose]

/-- Quote risk `(J⁻¹)ᵀ Rz` solves `Jᵀ Rq = Rz`, and it is the only solution, when `J` is
invertible. -/
theorem quote_risk_solves (J : Matrix (Fin m) (Fin m) ℝ) (hJ : IsUnit J.det)
    (Rz : Fin m → ℝ) :
    Jᵀ *ᵥ (J⁻¹ᵀ *ᵥ Rz) = Rz ∧ ∀ R : Fin m → ℝ, Jᵀ *ᵥ R = Rz → R = J⁻¹ᵀ *ᵥ Rz := by
  have hT : IsUnit Jᵀ.det := by rwa [Matrix.det_transpose]
  have h1 : Jᵀ * J⁻¹ᵀ = 1 := by
    rw [Matrix.transpose_nonsing_inv, Matrix.mul_nonsing_inv _ hT]
  have h2 : J⁻¹ᵀ * Jᵀ = 1 := by
    rw [Matrix.transpose_nonsing_inv, Matrix.nonsing_inv_mul _ hT]
  refine ⟨by rw [Matrix.mulVec_mulVec, h1, Matrix.one_mulVec], fun R hR => ?_⟩
  rw [← hR, Matrix.mulVec_mulVec, h2, Matrix.one_mulVec]

/-- A par calibration swap has risk to its own quote only (Step 5). After every rebuild its
value is `N (p k - K) A(p)`, with `A` the annuity on the rebuilt curve and `K = p₀ k` its fixed
rate, today's quote. Its quote risk at today's quotes is `N A(p₀)` on quote `k` and zero on every
other. -/
theorem par_swap_own_quote_only (A : (Fin m → ℝ) → ℝ) (A' : (Fin m → ℝ) →L[ℝ] ℝ)
    (p₀ : Fin m → ℝ) (k : Fin m) (N : ℝ) (hA : HasFDerivAt A A' p₀) :
    HasFDerivAt (fun p => N * ((p k - p₀ k) * A p))
      (riskMap (Pi.single k (N * A p₀))) p₀ := by
  have h1 : HasFDerivAt (fun p : Fin m → ℝ => p k - p₀ k)
      (ContinuousLinearMap.proj k : (Fin m → ℝ) →L[ℝ] ℝ) p₀ :=
    (hasFDerivAt_apply k p₀).sub_const _
  have h2 := (h1.mul hA).const_mul N
  convert h2 using 1
  ext1 v
  simp only [riskMap_apply, sub_self, zero_smul, zero_add, smul_apply,
    ContinuousLinearMap.proj_apply, smul_eq_mul, dotProduct, Pi.single_apply]
  simp [mul_assoc]

#print axioms quote_risk_eq_inverse_transpose
#print axioms quote_risk_solves
#print axioms par_swap_own_quote_only
