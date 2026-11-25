-- Gauss, Codazzi and Ricci equations: for a smooth n-dimensional patch in flat m-dimensional space, in any codimension, the curvature computed from the metric alone equals the bending term built from the second fundamental form II, the normal part of the second derivatives.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.InnerProductSpace.Projection.FiniteDimensional
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic
import Mathlib.Analysis.Calculus.ContDiff.Comp
import Mathlib.Analysis.Calculus.FDeriv.Symmetric
import Mathlib.Analysis.InnerProductSpace.Calculus
import Mathlib.Analysis.InnerProductSpace.GramMatrix

open scoped ContDiff RealInnerProductSpace

namespace GaussCodazzi

/-! A patch `r` sends a chart point `x = (x¹, …, xⁿ)` to a point of flat space `ℝᵐ`
(`EuclideanSpace ℝ (Fin m)`), the ambient space, whose curvature is 0. The codimension is `m - n`. -/

/-- The partial derivative `∂ᵢ f` at `x`: how fast `f` changes as the coordinate `xⁱ` grows. -/
noncomputable def pd {n : ℕ} {V : Type*} [NormedAddCommGroup V] [NormedSpace ℝ V]
    (i : Fin n) (f : (Fin n → ℝ) → V) (x : Fin n → ℝ) : V :=
  fderiv ℝ f x (Pi.single i 1)

/-- The metric of the patch, the ambient metric on its tangent arrows: `gᵢⱼ = ⟨∂ᵢ r, ∂ⱼ r⟩`. -/
noncomputable def metric {n m : ℕ} (r : (Fin n → ℝ) → EuclideanSpace ℝ (Fin m))
    (i j : Fin n) (x : Fin n → ℝ) : ℝ :=
  ⟪pd i r x, pd j r x⟫

/-- The inverse metric `gⁱʲ` at `x`, the inverse of the matrix `(gᵢⱼ)`. -/
noncomputable def metricInv {n m : ℕ} (r : (Fin n → ℝ) → EuclideanSpace ℝ (Fin m))
    (x : Fin n → ℝ) : Matrix (Fin n) (Fin n) ℝ :=
  (Matrix.of fun i j => metric r i j x)⁻¹

/-- Christoffel symbol of the first kind, from the metric alone:
`Γₖ,ᵢⱼ = ½ (∂ᵢ gⱼₖ + ∂ⱼ gᵢₖ - ∂ₖ gᵢⱼ)`. -/
noncomputable def christoffel {n m : ℕ} (r : (Fin n → ℝ) → EuclideanSpace ℝ (Fin m))
    (k i j : Fin n) (x : Fin n → ℝ) : ℝ :=
  (1 / 2) * (pd i (metric r j k) x + pd j (metric r i k) x - pd k (metric r i j) x)

/-- The curvature tensor `Rm(∂ᵢ, ∂ⱼ, ∂ₖ, ∂ₗ)` of the patch, computed from the metric `g` and its first
and second derivatives only (what an ant living in the patch can measure), with the card's sign
convention, so that the round sphere has positive sectional curvature. -/
noncomputable def intrinsicRm {n m : ℕ} (r : (Fin n → ℝ) → EuclideanSpace ℝ (Fin m))
    (i j k l : Fin n) (x : Fin n → ℝ) : ℝ :=
  (1 / 2) * (pd j (pd l (metric r i k)) x + pd i (pd k (metric r j l)) x
      - pd j (pd k (metric r i l)) x - pd i (pd l (metric r j k)) x)
    + ∑ p, ∑ q, metricInv r x p q *
      (christoffel r p i k x * christoffel r q j l x - christoffel r p i l x * christoffel r q j k x)

/-- The sectional curvature of the plane of the coordinate arrows `∂ᵢ`, `∂ⱼ`, from the metric alone:
`sec = Rm(∂ᵢ, ∂ⱼ, ∂ⱼ, ∂ᵢ) / (gᵢᵢ gⱼⱼ - gᵢⱼ²)`. -/
noncomputable def intrinsicSec {n m : ℕ} (r : (Fin n → ℝ) → EuclideanSpace ℝ (Fin m))
    (i j : Fin n) (x : Fin n → ℝ) : ℝ :=
  intrinsicRm r i j j i x / (metric r i i x * metric r j j x - metric r i j x ^ 2)

/-- The tangent space of the patch at `x`: the span of the arrows `∂₁ r, …, ∂ₙ r`. -/
noncomputable def tangentSpace {n m : ℕ} (r : (Fin n → ℝ) → EuclideanSpace ℝ (Fin m))
    (x : Fin n → ℝ) : Submodule ℝ (EuclideanSpace ℝ (Fin m)) :=
  Submodule.span ℝ (Set.range fun i => pd i r x)

/-- The second fundamental form `II(∂ᵢ, ∂ⱼ)`: the normal part of the second derivative `∂ᵢ ∂ⱼ r`,
its orthogonal projection onto the normal space (the orthogonal complement of the tangent space).
It is a vector in the normal space, not a number, when the codimension is above 1. -/
noncomputable def II {n m : ℕ} (r : (Fin n → ℝ) → EuclideanSpace ℝ (Fin m))
    (x : Fin n → ℝ) (i j : Fin n) : EuclideanSpace ℝ (Fin m) :=
  (tangentSpace r x)ᗮ.starProjection (pd j (pd i r) x)


/-! Helper lemmas. -/

theorem pd_contDiffOn {n : ℕ} {V : Type*} [NormedAddCommGroup V] [NormedSpace ℝ V]
    {U : Set (Fin n → ℝ)} (hU : IsOpen U) {f : (Fin n → ℝ) → V} (hf : ContDiffOn ℝ ∞ f U)
    (i : Fin n) : ContDiffOn ℝ ∞ (pd i f) U := by
  have h1 : ContDiffOn ℝ ∞ (fderiv ℝ f) U := hf.fderiv_of_isOpen hU (by simp)
  exact h1.clm_apply contDiffOn_const

theorem diffAt_of_contDiffOn {n : ℕ} {V : Type*} [NormedAddCommGroup V] [NormedSpace ℝ V]
    {U : Set (Fin n → ℝ)} (hU : IsOpen U) {f : (Fin n → ℝ) → V} (hf : ContDiffOn ℝ ∞ f U)
    {y : Fin n → ℝ} (hy : y ∈ U) : DifferentiableAt ℝ f y :=
  (hf.contDiffAt (hU.mem_nhds hy)).differentiableAt (by simp)

theorem pd_pd_eq_fderiv2 {n : ℕ} {V : Type*} [NormedAddCommGroup V] [NormedSpace ℝ V]
    {f : (Fin n → ℝ) → V} {y : Fin n → ℝ} (hf : ContDiffAt ℝ ∞ f y) (a b : Fin n) :
    pd b (pd a f) y = fderiv ℝ (fderiv ℝ f) y (Pi.single b 1) (Pi.single a 1) := by
  have hd : DifferentiableAt ℝ (fderiv ℝ f) y :=
    (hf.fderiv_right (m := 1) (by simp)).differentiableAt (by simp)
  unfold pd
  rw [fderiv_clm_apply hd (differentiableAt_const _)]
  simp

theorem pd_comm {n : ℕ} {V : Type*} [NormedAddCommGroup V] [NormedSpace ℝ V]
    {U : Set (Fin n → ℝ)} (hU : IsOpen U) {f : (Fin n → ℝ) → V} (hf : ContDiffOn ℝ ∞ f U)
    {y : Fin n → ℝ} (hy : y ∈ U) (a b : Fin n) :
    pd b (pd a f) y = pd a (pd b f) y := by
  have hfy : ContDiffAt ℝ ∞ f y := hf.contDiffAt (hU.mem_nhds hy)
  rw [pd_pd_eq_fderiv2 hfy, pd_pd_eq_fderiv2 hfy]
  exact hfy.isSymmSndFDerivAt (by simp) _ _

theorem pd_congr {n : ℕ} {V : Type*} [NormedAddCommGroup V] [NormedSpace ℝ V]
    {f g : (Fin n → ℝ) → V} {y : Fin n → ℝ} (h : f =ᶠ[nhds y] g) (k : Fin n) :
    pd k f y = pd k g y := by
  unfold pd
  rw [h.fderiv_eq]

theorem pd_add {n : ℕ} {V : Type*} [NormedAddCommGroup V] [NormedSpace ℝ V]
    {f g : (Fin n → ℝ) → V} {y : Fin n → ℝ} (hf : DifferentiableAt ℝ f y)
    (hg : DifferentiableAt ℝ g y) (k : Fin n) :
    pd k (fun z => f z + g z) y = pd k f y + pd k g y := by
  unfold pd
  rw [show (fun z => f z + g z) = f + g from rfl, fderiv_add hf hg]
  rfl

theorem pd_inner {n m : ℕ} {f g : (Fin n → ℝ) → EuclideanSpace ℝ (Fin m)} {y : Fin n → ℝ}
    (hf : DifferentiableAt ℝ f y) (hg : DifferentiableAt ℝ g y) (k : Fin n) :
    pd k (fun z => ⟪f z, g z⟫) y = ⟪pd k f y, g y⟫ + ⟪f y, pd k g y⟫ := by
  unfold pd
  rw [fderiv_inner_apply ℝ hf hg, add_comm]

#print axioms pd_contDiffOn
#print axioms diffAt_of_contDiffOn
#print axioms pd_pd_eq_fderiv2
#print axioms pd_comm
#print axioms pd_congr
#print axioms pd_add
#print axioms pd_inner


theorem pd_metric {n m : ℕ} {r : (Fin n → ℝ) → EuclideanSpace ℝ (Fin m)} {U : Set (Fin n → ℝ)}
    (hU : IsOpen U) (hr : ContDiffOn ℝ ∞ r U) {y : Fin n → ℝ} (hy : y ∈ U) (i k l : Fin n) :
    pd l (metric r i k) y = ⟪pd l (pd i r) y, pd k r y⟫ + ⟪pd i r y, pd l (pd k r) y⟫ :=
  pd_inner (diffAt_of_contDiffOn hU (pd_contDiffOn hU hr i) hy)
    (diffAt_of_contDiffOn hU (pd_contDiffOn hU hr k) hy) l

theorem pd_pd_metric {n m : ℕ} {r : (Fin n → ℝ) → EuclideanSpace ℝ (Fin m)} {U : Set (Fin n → ℝ)}
    (hU : IsOpen U) (hr : ContDiffOn ℝ ∞ r U) {x : Fin n → ℝ} (hx : x ∈ U) (i k l j : Fin n) :
    pd j (pd l (metric r i k)) x =
      ⟪pd j (pd l (pd i r)) x, pd k r x⟫ + ⟪pd l (pd i r) x, pd j (pd k r) x⟫ +
        (⟪pd j (pd i r) x, pd l (pd k r) x⟫ + ⟪pd i r x, pd j (pd l (pd k r)) x⟫) := by
  have hev : pd l (metric r i k) =ᶠ[nhds x]
      fun y => ⟪pd l (pd i r) y, pd k r y⟫ + ⟪pd i r y, pd l (pd k r) y⟫ := by
    filter_upwards [hU.mem_nhds hx] with y hy
    exact pd_metric hU hr hy i k l
  have d1 := fun a => diffAt_of_contDiffOn hU (pd_contDiffOn hU hr a) hx
  have d2 := fun a b => diffAt_of_contDiffOn hU (pd_contDiffOn hU (pd_contDiffOn hU hr a) b) hx
  rw [pd_congr hev, pd_add ((d2 i l).inner ℝ (d1 k)) ((d1 i).inner ℝ (d2 k l)),
    pd_inner (d2 i l) (d1 k), pd_inner (d1 i) (d2 k l)]

theorem christoffel_eq {n m : ℕ} {r : (Fin n → ℝ) → EuclideanSpace ℝ (Fin m)} {U : Set (Fin n → ℝ)}
    (hU : IsOpen U) (hr : ContDiffOn ℝ ∞ r U) {x : Fin n → ℝ} (hx : x ∈ U) (k i j : Fin n) :
    christoffel r k i j x = ⟪pd j (pd i r) x, pd k r x⟫ := by
  unfold christoffel
  rw [pd_metric hU hr hx, pd_metric hU hr hx, pd_metric hU hr hx, pd_comm hU hr hx j i,
    pd_comm hU hr hx k i, pd_comm hU hr hx k j]
  linarith [real_inner_comm (pd j r x) (pd k (pd i r) x)]

theorem inner_split {m : ℕ} (K : Submodule ℝ (EuclideanSpace ℝ (Fin m)))
    [K.HasOrthogonalProjection] (v w : EuclideanSpace ℝ (Fin m)) :
    ⟪v, w⟫ = ⟪K.starProjection v, K.starProjection w⟫ +
      ⟪Kᗮ.starProjection v, Kᗮ.starProjection w⟫ := by
  rw [Submodule.starProjection_orthogonal_val, Submodule.starProjection_orthogonal_val]
  have h1 := K.starProjection_inner_eq_zero v (K.starProjection w) (K.starProjection_apply_mem w)
  have h2 := K.starProjection_inner_eq_zero w (K.starProjection v) (K.starProjection_apply_mem v)
  simp only [inner_sub_left, inner_sub_right] at h1 h2 ⊢
  linarith [real_inner_comm w (K.starProjection v),
    real_inner_comm (K.starProjection w) (K.starProjection v)]

theorem tangent_proj_inner {n m : ℕ} (r : (Fin n → ℝ) → EuclideanSpace ℝ (Fin m))
    (x : Fin n → ℝ) (himm : LinearIndependent ℝ fun i => pd i r x)
    (v w : EuclideanSpace ℝ (Fin m)) :
    ∑ p, ∑ q, metricInv r x p q * (⟪v, pd p r x⟫ * ⟪w, pd q r x⟫) =
      ⟪(tangentSpace r x).starProjection v, (tangentSpace r x).starProjection w⟫ := by
  set K := tangentSpace r x with hK
  set G : Matrix (Fin n) (Fin n) ℝ := Matrix.of fun i j => metric r i j x with hG
  have hdet : G.det ≠ 0 := (Matrix.det_gram_ne_zero_iff_linearIndependent (𝕜 := ℝ)).2 himm
  have hinv : G⁻¹ * G = 1 := Matrix.nonsing_inv_mul G (isUnit_iff_ne_zero.mpr hdet)
  set u : EuclideanSpace ℝ (Fin m) := ∑ p, ∑ q, (G⁻¹ p q * ⟪v, pd p r x⟫) • pd q r x with hu
  have hmem : ∀ q, pd q r x ∈ K := fun q => Submodule.subset_span ⟨q, rfl⟩
  have huK : u ∈ K := Submodule.sum_mem _ fun p _ => Submodule.sum_mem _ fun q _ =>
    Submodule.smul_mem _ _ (hmem q)
  have hTv : K.starProjection v = u := by
    apply Submodule.eq_starProjection_of_mem_of_inner_eq_zero huK
    intro z hz
    refine Submodule.span_induction ?_ ?_ ?_ ?_ hz
    · rintro _ ⟨s, rfl⟩
      rw [inner_sub_left, hu, sum_inner]
      simp_rw [sum_inner, real_inner_smul_left]
      have key : ∀ p, ∑ q, G⁻¹ p q * ⟪v, pd p r x⟫ * ⟪pd q r x, pd s r x⟫ =
          ⟪v, pd p r x⟫ * (G⁻¹ * G) p s := by
        intro p
        rw [Matrix.mul_apply, Finset.mul_sum]
        refine Finset.sum_congr rfl fun q _ => ?_
        simp only [hG, Matrix.of_apply, metric]
        ring
      simp_rw [key, hinv, Matrix.one_apply]
      simp
    · simp
    · intro a b _ _ ha hb
      rw [inner_add_right, ha, hb, add_zero]
    · intro c a _ ha
      rw [real_inner_smul_right, ha, mul_zero]
  have h := K.starProjection_inner_eq_zero w u huK
  rw [inner_sub_left] at h
  rw [hTv, real_inner_comm (K.starProjection w) u]
  have hw : ⟪u, w⟫ = ∑ p, ∑ q, metricInv r x p q * (⟪v, pd p r x⟫ * ⟪w, pd q r x⟫) := by
    rw [hu, sum_inner]
    refine Finset.sum_congr rfl fun p _ => ?_
    rw [sum_inner]
    refine Finset.sum_congr rfl fun q _ => ?_
    rw [real_inner_smul_left, real_inner_comm w (pd q r x)]
    simp only [metricInv, hG]
    ring
  linarith [real_inner_comm w u]

#print axioms pd_metric
#print axioms pd_pd_metric
#print axioms christoffel_eq
#print axioms inner_split
#print axioms tangent_proj_inner


theorem intrinsicRm_eq {n m : ℕ} (r : (Fin n → ℝ) → EuclideanSpace ℝ (Fin m))
    (U : Set (Fin n → ℝ)) (hU : IsOpen U) (hr : ContDiffOn ℝ ∞ r U)
    (x : Fin n → ℝ) (hx : x ∈ U) (himm : LinearIndependent ℝ fun i => pd i r x)
    (i j k l : Fin n) :
    intrinsicRm r i j k l x = ⟪II r x i l, II r x j k⟫ - ⟪II r x i k, II r x j l⟫ := by
  have hp := fun a => pd_contDiffOn hU hr a
  have hs : ∀ a b, pd b (pd a r) x = pd a (pd b r) x := fun a b => pd_comm hU hr hx a b
  have ht1 : ∀ a b c, pd c (pd b (pd a r)) x = pd c (pd a (pd b r)) x := by
    intro a b c
    apply pd_congr
    filter_upwards [hU.mem_nhds hx] with y hy
    exact pd_comm hU hr hy a b
  have ht2 : ∀ a b c, pd c (pd b (pd a r)) x = pd b (pd c (pd a r)) x :=
    fun a b c => pd_comm hU (hp a) hx b c
  unfold intrinsicRm
  rw [pd_pd_metric hU hr hx, pd_pd_metric hU hr hx, pd_pd_metric hU hr hx,
    pd_pd_metric hU hr hx]
  simp_rw [christoffel_eq hU hr hx, mul_sub, Finset.sum_sub_distrib]
  rw [tangent_proj_inner r x himm, tangent_proj_inner r x himm]
  unfold II
  have e1 : pd j (pd l (pd i r)) x = pd i (pd l (pd j r)) x := by
    rw [ht1 i l j, ht2 l i j, ht1 l j i]
  have e3 : pd i (pd k (pd j r)) x = pd j (pd k (pd i r)) x := by
    rw [ht1 j k i, ht2 k j i, ht1 k i j]
  rw [e1, e3, ht1 k l j, ht1 l k i, hs k j, hs l i, hs l j, hs k i, hs j i, hs l k]
  linarith [inner_split (tangentSpace r x) (pd l (pd i r) x) (pd k (pd j r) x),
    inner_split (tangentSpace r x) (pd k (pd i r) x) (pd l (pd j r) x),
    real_inner_comm (pd l (pd i r) x) (pd k (pd j r) x),
    real_inner_comm (pd k (pd i r) x) (pd l (pd j r) x)]


theorem frame_sum {m : ℕ} (K : Submodule ℝ (EuclideanSpace ℝ (Fin m)))
    [K.HasOrthogonalProjection] {ι : Type*} [Fintype ι] (ν : OrthonormalBasis ι ℝ K)
    (a b : EuclideanSpace ℝ (Fin m)) :
    ∑ t, ⟪K.starProjection a, (ν t : EuclideanSpace ℝ (Fin m))⟫ *
        ⟪K.starProjection b, (ν t : EuclideanSpace ℝ (Fin m))⟫ =
      ⟪K.starProjection a, K.starProjection b⟫ := by
  rw [Submodule.starProjection_apply, Submodule.starProjection_apply]
  simp_rw [← Submodule.coe_inner]
  rw [← ν.sum_inner_mul_inner]
  refine Finset.sum_congr rfl fun t _ => ?_
  rw [real_inner_comm (ν t) (K.orthogonalProjectionOnto b)]

theorem II_symm {n m : ℕ} (r : (Fin n → ℝ) → EuclideanSpace ℝ (Fin m))
    (U : Set (Fin n → ℝ)) (hU : IsOpen U) (hr : ContDiffOn ℝ ∞ r U)
    (x : Fin n → ℝ) (hx : x ∈ U) (i j : Fin n) : II r x j i = II r x i j := by
  unfold II
  rw [pd_comm hU hr hx j i]

#print axioms intrinsicRm_eq
#print axioms frame_sum
#print axioms II_symm

/-- **Gauss equation, sectional form.** For a smooth patch of any dimension `n` sitting in flat space
`ℝᵐ` of any codimension, with the metric it inherits from that space, the curvature of the plane of
two coordinate arrows, computed from the metric alone, equals the ambient curvature 0 plus the bending
in the two directions dotted together, minus the square of the mixed bending, per unit squared area:
`sec(∂ᵢ, ∂ⱼ) = 0 + (⟨II(∂ᵢ,∂ᵢ), II(∂ⱼ,∂ⱼ)⟩ - |II(∂ᵢ,∂ⱼ)|²) / (|∂ᵢ|²|∂ⱼ|² - ⟨∂ᵢ,∂ⱼ⟩²)`. -/
theorem gauss_equation {n m : ℕ} (r : (Fin n → ℝ) → EuclideanSpace ℝ (Fin m))
    (U : Set (Fin n → ℝ)) (hU : IsOpen U) (hr : ContDiffOn ℝ ∞ r U)
    (x : Fin n → ℝ) (hx : x ∈ U) (himm : LinearIndependent ℝ fun i => pd i r x)
    (i j : Fin n) :
    intrinsicSec r i j x =
      0 + (⟪II r x i i, II r x j j⟫ - ‖II r x i j‖ ^ 2) /
        (metric r i i x * metric r j j x - metric r i j x ^ 2) := by
  unfold intrinsicSec
  rw [intrinsicRm_eq r U hU hr x hx himm, II_symm r U hU hr x hx j i,
    real_inner_self_eq_norm_sq, zero_add]

/-- **Gauss equation, tensor form** (Step 3 of the card). With flat ambient space, the curvature tensor
of the patch, computed from the metric alone, is built from the bending only:
`Rm(∂ᵢ, ∂ⱼ, ∂ₖ, ∂ₗ) = 0 + ⟨II(∂ᵢ,∂ₗ), II(∂ⱼ,∂ₖ)⟩ - ⟨II(∂ᵢ,∂ₖ), II(∂ⱼ,∂ₗ)⟩`. -/
theorem gauss_equation_tensor {n m : ℕ} (r : (Fin n → ℝ) → EuclideanSpace ℝ (Fin m))
    (U : Set (Fin n → ℝ)) (hU : IsOpen U) (hr : ContDiffOn ℝ ∞ r U)
    (x : Fin n → ℝ) (hx : x ∈ U) (himm : LinearIndependent ℝ fun i => pd i r x)
    (i j k l : Fin n) :
    intrinsicRm r i j k l x =
      0 + ⟪II r x i l, II r x j k⟫ - ⟪II r x i k, II r x j l⟫ := by
  rw [intrinsicRm_eq r U hU hr x hx himm, zero_add]

/-- **One sum, grouped by normal directions.** In codimension `k` the two bendings are vectors, and the
Gauss equation takes their dot product. Written in any orthonormal frame `ν₁, …, νₖ` of the normal
space, with one number `hᵃᵢⱼ = ⟨II(∂ᵢ,∂ⱼ), νₐ⟩` per normal direction, it becomes a sum of `k`
hypersurface terms `hᵃᵢᵢ hᵃⱼⱼ - (hᵃᵢⱼ)²` (for one normal and principal directions, `κ₁ κ₂`):
`sec(∂ᵢ, ∂ⱼ) = Σₐ (hᵃᵢᵢ hᵃⱼⱼ - (hᵃᵢⱼ)²) / (gᵢᵢ gⱼⱼ - gᵢⱼ²)`. -/
theorem gauss_equation_normal_frame {n m : ℕ} (r : (Fin n → ℝ) → EuclideanSpace ℝ (Fin m))
    (U : Set (Fin n → ℝ)) (hU : IsOpen U) (hr : ContDiffOn ℝ ∞ r U)
    (x : Fin n → ℝ) (hx : x ∈ U) (himm : LinearIndependent ℝ fun i => pd i r x)
    {ι : Type*} [Fintype ι] (ν : OrthonormalBasis ι ℝ (tangentSpace r x)ᗮ) (i j : Fin n) :
    intrinsicSec r i j x =
      (∑ a, (⟪II r x i i, (ν a : EuclideanSpace ℝ (Fin m))⟫ * ⟪II r x j j, (ν a : EuclideanSpace ℝ (Fin m))⟫
          - ⟪II r x i j, (ν a : EuclideanSpace ℝ (Fin m))⟫ ^ 2)) /
        (metric r i i x * metric r j j x - metric r i j x ^ 2) := by
  rw [gauss_equation r U hU hr x hx himm i j, zero_add, Finset.sum_sub_distrib]
  congr 1
  have h1 := frame_sum (tangentSpace r x)ᗮ ν (pd i (pd i r) x) (pd j (pd j r) x)
  have h2 := frame_sum (tangentSpace r x)ᗮ ν (pd j (pd i r) x) (pd j (pd i r) x)
  unfold II
  rw [h1, ← real_inner_self_eq_norm_sq, ← h2]
  simp only [sq]

/-! The card's exact worked numbers. -/

-- The globe of radius R in flat space: every direction bends by 1/R, no mixed bending: K = 0 + (1/R)(1/R) - 0² = 1/R².
example (R : ℝ) : 0 + (1 / R) * (1 / R) - 0 ^ 2 = 1 / R ^ 2 := by ring

-- Clifford torus, split 1 (flat 4-space): the two bending vectors are at right angles, K = 0 + 0 - 0 = 0.
example : (0 : ℤ) + 0 - 0 = 0 := by decide

-- Clifford torus, split 2: the 3-sphere's own Gauss equation, ambient curvature (-1)(-1) = 1.
example : (-1 : ℤ) * (-1) = 1 := by decide

-- Clifford torus, split 2: K = 1 + (-1)(1) = 0, a flat torus in a round space.
example : (1 : ℤ) + (-1) * 1 = 0 := by decide

-- Clifford torus in the 3-sphere: mean curvature (-1 + 1)/2 = 0, so it is minimal.
example : ((-1 : ℚ) + 1) / 2 = 0 := by norm_num

-- Clifford torus in 4-space: |II(e₁, e₁)|² = (√2)² = 2.
example : Real.sqrt 2 ^ 2 = 2 := by norm_num

-- Clifford torus: E = G = (1/√2)² = 1/2.
example : (1 / Real.sqrt 2) ^ 2 = 1 / 2 := by norm_num

-- Clifford torus: area (2π)² × 1/2 = 2π².
example : (2 * Real.pi) ^ 2 * (1 / 2) = 2 * Real.pi ^ 2 := by ring

-- The twisted surface w = z²/2 at z = 0.4 + 0.3i: |z|² = 1/4.
example : (4 / 10 : ℚ) ^ 2 + (3 / 10) ^ 2 = 1 / 4 := by norm_num

-- Its curvature, closed form: -2/(1 + 1/4)³ = -128/125, which is -1.024.
example : (-2 : ℚ) / (1 + 1 / 4) ^ 3 = -128 / 125 := by norm_num

-- Dropping the mixed term halves it: -64/125, which is -0.512.
example : (-128 / 125 : ℚ) / 2 = -64 / 125 := by norm_num

#print axioms gauss_equation
#print axioms gauss_equation_tensor
#print axioms gauss_equation_normal_frame

end GaussCodazzi
