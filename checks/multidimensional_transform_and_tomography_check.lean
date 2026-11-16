-- Transforms in two and three dimensions: the one-dimensional transform of a picture's shadow at angle θ equals the picture's two-dimensional transform along the line through the centre in direction θ, and the two-dimensional transform splits over separable pictures and turns with rotated ones.
import Mathlib.Analysis.Fourier.FourierTransform
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.MeasureTheory.Measure.Haar.InnerProductSpace
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Tactic.NormNum

open MeasureTheory Real
open scoped FourierTransform

/-- The plane of the slice, points `x = (x₁, x₂)` in cm. Mathlib's `𝓕 f ξ` on it is the card's
`f̂(ξ) = ∬ f(x) e^(−2πi ξ·x) dx`, with `ξ = (ξ₁, ξ₂)` in cycles per cm; on `ℝ` it is the card's
one-dimensional `f̂(σ) = ∫ f(s) e^(−2πiσs) ds`. -/
abbrev Plane := EuclideanSpace ℝ (Fin 2)

/-- `u_θ = (cos θ, sin θ)`: the unit step along the detector at scanner angle `θ`. -/
noncomputable def detDir (θ : ℝ) : Plane := !₂[Real.cos θ, Real.sin θ]

/-- `u_θ^⊥ = (−sin θ, cos θ)`: the unit step along the rays at scanner angle `θ`. -/
noncomputable def rayDir (θ : ℝ) : Plane := !₂[-Real.sin θ, Real.cos θ]

noncomputable def planeEquiv : ℝ × ℝ ≃ᵐ Plane :=
  MeasurableEquiv.finTwoArrow.symm.trans (MeasurableEquiv.toLp 2 (Fin 2 → ℝ))

lemma planeEquiv_apply (p : ℝ × ℝ) : planeEquiv p = !₂[p.1, p.2] := by
  ext i; fin_cases i <;> rfl

lemma planeEquiv_mp : MeasurePreserving planeEquiv volume volume :=
  (volume_preserving_finTwoArrow ℝ).symm.trans (PiLp.volume_preserving_toLp (Fin 2))

lemma orthonormal_dirs (θ : ℝ) : Orthonormal ℝ ![detDir θ, rayDir θ] := by
  rw [orthonormal_iff_ite]
  intro i j
  fin_cases i <;> fin_cases j <;>
    simp [detDir, rayDir, PiLp.inner_apply, Fin.sum_univ_two, EuclideanSpace.norm_eq] <;> ring_nf

noncomputable def dirBasis (θ : ℝ) : OrthonormalBasis (Fin 2) ℝ Plane :=
  (basisOfOrthonormalOfCardEqFinrank (orthonormal_dirs θ) (by simp)).toOrthonormalBasis
    (by rw [coe_basisOfOrthonormalOfCardEqFinrank]; exact orthonormal_dirs θ)

lemma dirBasis_repr_symm (θ : ℝ) (p : Plane) :
    (dirBasis θ).repr.symm p = p 0 • detDir θ + p 1 • rayDir θ := by
  rw [← OrthonormalBasis.sum_repr_symm, Fin.sum_univ_two]
  simp [dirBasis]

noncomputable def dirEquiv (θ : ℝ) : ℝ × ℝ ≃ᵐ Plane :=
  planeEquiv.trans (dirBasis θ).repr.symm.toMeasurableEquiv

lemma dirEquiv_apply (θ : ℝ) (p : ℝ × ℝ) : dirEquiv θ p = p.1 • detDir θ + p.2 • rayDir θ := by
  change (dirBasis θ).repr.symm (planeEquiv p) = _
  rw [dirBasis_repr_symm, planeEquiv_apply]
  simp

lemma dirEquiv_mp (θ : ℝ) : MeasurePreserving (dirEquiv θ) volume volume :=
  planeEquiv_mp.trans (dirBasis θ).repr.symm.measurePreserving

lemma inner_dirEquiv (θ σ : ℝ) (p : ℝ × ℝ) :
    inner ℝ (dirEquiv θ p) (σ • detDir θ) = p.1 * σ := by
  rw [dirEquiv_apply]
  simp [detDir, rayDir, PiLp.inner_apply, Fin.sum_univ_two]
  linear_combination (p.1 * σ) * sin_sq_add_cos_sq θ

/-- The shadow `P_θ f(s) = ∫ f(s u_θ + t u_θ^⊥) dt`: the total of the picture `f` along the ray
that meets the detector at position `s`. -/
noncomputable def shadow (θ : ℝ) (f : Plane → ℂ) (s : ℝ) : ℂ :=
  ∫ t : ℝ, f (s • detDir θ + t • rayDir θ)

/-- The projection-slice theorem. For an absolutely integrable picture `f` on the plane, the
one-dimensional transform of its shadow at angle `θ`, at frequency `σ` along the detector, equals
the picture's two-dimensional transform at the point `σ u_θ`, `σ` steps out from the centre in the
direction `θ`: `(P_θ f)^(σ) = f̂(σ u_θ)`. -/
theorem fourier_shadow_eq_slice (f : Plane → ℂ) (hf : Integrable f) (θ σ : ℝ) :
    𝓕 (shadow θ f) σ = 𝓕 f (σ • detDir θ) := by
  have hG : Integrable (fun p : ℝ × ℝ ↦
      (fun x : Plane ↦ Real.fourierChar (-inner ℝ x (σ • detDir θ)) • f x) (dirEquiv θ p)) :=
    (dirEquiv_mp θ).integrable_comp_emb (dirEquiv θ).measurableEmbedding
      |>.mpr ((fourierIntegral_convergent_iff _).mpr hf)
  rw [fourier_real_eq, fourier_eq f, ← (dirEquiv_mp θ).integral_comp', Measure.volume_eq_prod,
    integral_prod _ (by simpa [Measure.volume_eq_prod] using hG)]
  refine integral_congr_ae (Filter.Eventually.of_forall fun s ↦ ?_)
  simp only [inner_dirEquiv]
  simp only [dirEquiv_apply, shadow]
  simp only [Circle.smul_def]
  exact (integral_smul (𝕜 := ℂ) _ _).symm

/-- Separability. A separable picture `f(x₁, x₂) = g(x₁) h(x₂)`, with both factors absolutely
integrable, has the separable transform `f̂(ξ₁, ξ₂) = ĝ(ξ₁) ĥ(ξ₂)`. -/
theorem fourier_separable_eq_mul (g h : ℝ → ℂ) (hg : Integrable g) (hh : Integrable h) (ξ : Plane) :
    𝓕 (fun x : Plane ↦ g (x 0) * h (x 1)) ξ = 𝓕 g (ξ 0) * 𝓕 h (ξ 1) := by
  rw [fourier_real_eq, fourier_real_eq, fourier_eq, ← planeEquiv_mp.integral_comp',
    Measure.volume_eq_prod, ← integral_prod_mul]
  refine integral_congr_ae (Filter.Eventually.of_forall fun p ↦ ?_)
  simp only [planeEquiv_apply, Circle.smul_def, PiLp.inner_apply, Fin.sum_univ_two]
  simp [AddChar.map_add_eq_mul]
  rw [mul_comm (ξ.ofLp 1), mul_comm (ξ.ofLp 0)]
  ring

/-- Rotation invariance. Rotating an absolutely integrable picture by a rotation (or reflection)
`A` of the plane rotates its transform the same way: the transform of `x ↦ f(A x)` at `ξ` is
`f̂(A ξ)`. -/
theorem fourier_rotate_eq_rotate_fourier (A : Plane ≃ₗᵢ[ℝ] Plane) (f : Plane → ℂ)
    (hf : Integrable f) (ξ : Plane) :
    𝓕 (fun x ↦ f (A x)) ξ = 𝓕 f (A ξ) := by
  exact fourier_comp_linearIsometry A f ξ

-- The phantom, attenuations as fractions per cm: the ray through the middle crosses 20 cm of
-- water at 1/5 per cm, total 4.
example : (1 / 5 : ℚ) * 20 = 4 := by norm_num
-- The horizontal ray through the middle also crosses the 4 cm rod, which adds 3/10 per cm:
-- total 26/5 = 5.2, the top of the teal shadow.
example : (1 / 5 : ℚ) * 20 + 3 / 10 * 4 = 26 / 5 := by norm_num

#print axioms fourier_shadow_eq_slice
#print axioms fourier_separable_eq_mul
#print axioms fourier_rotate_eq_rotate_fourier
#print axioms planeEquiv_apply
#print axioms planeEquiv_mp
#print axioms orthonormal_dirs
#print axioms dirBasis_repr_symm
#print axioms dirEquiv_apply
#print axioms dirEquiv_mp
#print axioms inner_dirEquiv
#print axioms planeEquiv
#print axioms dirBasis
#print axioms dirEquiv
