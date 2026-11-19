-- Gauss map and second fundamental form: for a smooth regular patch with its unit normal, the normal turns by the shape operator W = I⁻¹ II (the Weingarten equations), det W is the globe area its normals cover per unit of surface area, and det W and trace W do not depend on the chart.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.Tactic
import Mathlib.Analysis.Calculus.FDeriv.Bilinear
import Mathlib.Analysis.Calculus.FDeriv.Symmetric
import Mathlib.Topology.Algebra.Module.FiniteDimension
import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.Analysis.Calculus.ContDiff.Operations

open scoped ContDiff Matrix

namespace GaussMap

/-- The tangent arrow `r_u`: the rate of change of the patch `r(u, v)` as `u` grows. -/
noncomputable def ru (r : ℝ × ℝ → Fin 3 → ℝ) (q : ℝ × ℝ) : Fin 3 → ℝ := fderiv ℝ r q (1, 0)

/-- The tangent arrow `r_v`: the rate of change of the patch `r(u, v)` as `v` grows. -/
noncomputable def rv (r : ℝ × ℝ → Fin 3 → ℝ) (q : ℝ × ℝ) : Fin 3 → ℝ := fderiv ℝ r q (0, 1)

/-- The Gauss map: the unit normal `n = (r_u × r_v) / ‖r_u × r_v‖`, the cross product divided by
its Euclidean length. -/
noncomputable def normal (r : ℝ × ℝ → Fin 3 → ℝ) (q : ℝ × ℝ) : Fin 3 → ℝ :=
  (Real.sqrt ((ru r q ⨯₃ rv r q) ⬝ᵥ (ru r q ⨯₃ rv r q)))⁻¹ • (ru r q ⨯₃ rv r q)

/-- The first fundamental form `I = (E, F; F, G)`, with `E = r_u · r_u`, `F = r_u · r_v`,
`G = r_v · r_v`. -/
noncomputable def firstForm (r : ℝ × ℝ → Fin 3 → ℝ) (q : ℝ × ℝ) : Matrix (Fin 2) (Fin 2) ℝ :=
  !![ru r q ⬝ᵥ ru r q, ru r q ⬝ᵥ rv r q; ru r q ⬝ᵥ rv r q, rv r q ⬝ᵥ rv r q]

/-- The second fundamental form `II = (L, M; M, N)`, with `L = r_uu · n`, `M = r_uv · n`,
`N = r_vv · n`. -/
noncomputable def secondForm (r : ℝ × ℝ → Fin 3 → ℝ) (q : ℝ × ℝ) : Matrix (Fin 2) (Fin 2) ℝ :=
  !![fderiv ℝ (ru r) q (1, 0) ⬝ᵥ normal r q, fderiv ℝ (ru r) q (0, 1) ⬝ᵥ normal r q;
     fderiv ℝ (ru r) q (0, 1) ⬝ᵥ normal r q, fderiv ℝ (rv r) q (0, 1) ⬝ᵥ normal r q]

/-- The shape operator `W = I⁻¹ II`. -/
noncomputable def shapeOperator (r : ℝ × ℝ → Fin 3 → ℝ) (q : ℝ × ℝ) : Matrix (Fin 2) (Fin 2) ℝ :=
  (firstForm r q)⁻¹ * secondForm r q

lemma fderiv_bilin_aux {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    [FiniteDimensional ℝ X]
    (B : (Fin 3 → ℝ) →ₗ[ℝ] (Fin 3 → ℝ) →ₗ[ℝ] X) {f g : ℝ × ℝ → Fin 3 → ℝ} {q : ℝ × ℝ}
    (hf : DifferentiableAt ℝ f q) (hg : DifferentiableAt ℝ g q) :
    DifferentiableAt ℝ (fun y => B (f y) (g y)) q ∧
      ∀ v, fderiv ℝ (fun y => B (f y) (g y)) q v =
        B (fderiv ℝ f q v) (g q) + B (f q) (fderiv ℝ g q v) := by
  let B' : (Fin 3 → ℝ) →L[ℝ] (Fin 3 → ℝ) →L[ℝ] X :=
    LinearMap.toContinuousLinearMap (LinearMap.toContinuousLinearMap.toLinearMap ∘ₗ B)
  have hB : (fun y => B (f y) (g y)) = fun y => B' (f y) (g y) := by
    funext y; simp [B']
  have h := B'.hasFDerivAt_of_bilinear hf.hasFDerivAt hg.hasFDerivAt
  rw [hB]
  refine ⟨h.differentiableAt, fun v => ?_⟩
  rw [h.fderiv]
  simp [B', add_comm]

#print axioms fderiv_bilin_aux

/-- If `x` is orthogonal to `a × b ≠ 0`, it is the combination of `a` and `b` whose
coefficients solve the first-form system. -/
lemma decomp_aux (a b x : Fin 3 → ℝ) (hN : a ⨯₃ b ≠ 0) (II : Matrix (Fin 2) (Fin 2) ℝ)
    (j : Fin 2) (hxN : x ⬝ᵥ (a ⨯₃ b) = 0) (hxa : x ⬝ᵥ a = II 0 j) (hxb : x ⬝ᵥ b = II 1 j) :
    x = ((!![a ⬝ᵥ a, a ⬝ᵥ b; a ⬝ᵥ b, b ⬝ᵥ b])⁻¹ * II) 0 j • a +
      ((!![a ⬝ᵥ a, a ⬝ᵥ b; a ⬝ᵥ b, b ⬝ᵥ b])⁻¹ * II) 1 j • b := by
  set I : Matrix (Fin 2) (Fin 2) ℝ := !![a ⬝ᵥ a, a ⬝ᵥ b; a ⬝ᵥ b, b ⬝ᵥ b] with hIdef
  set W := I⁻¹ * II with hW
  have hNN : (a ⨯₃ b) ⬝ᵥ (a ⨯₃ b) ≠ 0 := by
    intro h; exact hN (dotProduct_self_eq_zero.1 h)
  have hdet : I.det = (a ⨯₃ b) ⬝ᵥ (a ⨯₃ b) := by
    rw [hIdef, Matrix.det_fin_two_of, cross_dot_cross, dotProduct_comm b a]
  have hIW : I * W = II := Matrix.mul_nonsing_inv_cancel_left _ _ (by rw [hdet]; exact hNN.isUnit)
  have e0 : a ⬝ᵥ a * W 0 j + a ⬝ᵥ b * W 1 j = II 0 j := by
    rw [← hIW]; simp [Matrix.mul_apply, Fin.sum_univ_two, hIdef]
  have e1 : a ⬝ᵥ b * W 0 j + b ⬝ᵥ b * W 1 j = II 1 j := by
    rw [← hIW]; simp [Matrix.mul_apply, Fin.sum_univ_two, hIdef]
  set z := x - (W 0 j • a + W 1 j • b) with hz
  have za : z ⬝ᵥ a = 0 := by
    rw [hz, sub_dotProduct, add_dotProduct, smul_dotProduct, smul_dotProduct, hxa, ← e0,
      dotProduct_comm b a]
    simp only [smul_eq_mul]; ring
  have zb : z ⬝ᵥ b = 0 := by
    rw [hz, sub_dotProduct, add_dotProduct, smul_dotProduct, smul_dotProduct, hxb, ← e1]
    simp only [smul_eq_mul]; ring
  have zN : z ⬝ᵥ (a ⨯₃ b) = 0 := by
    rw [hz, sub_dotProduct, add_dotProduct, smul_dotProduct, smul_dotProduct, hxN,
      dot_self_cross, dot_cross_self]
    simp
  have zc : z ⨯₃ (a ⨯₃ b) = 0 := by
    rw [cross_cross_eq_smul_sub_smul', zb, dotProduct_comm a z, za]; simp
  have hzz : (z ⬝ᵥ z) * ((a ⨯₃ b) ⬝ᵥ (a ⨯₃ b)) = 0 := by
    have := cross_dot_cross z (a ⨯₃ b) z (a ⨯₃ b)
    rw [zc, zero_dotProduct, zN, dotProduct_comm (a ⨯₃ b) z, zN] at this
    linarith
  have hz0 : z = 0 := by
    rcases mul_eq_zero.1 hzz with h | h
    · exact dotProduct_self_eq_zero.1 h
    · exact absurd h hNN
  exact sub_eq_zero.1 hz0

#print axioms decomp_aux

lemma dot_aux {f g : ℝ × ℝ → Fin 3 → ℝ} {q : ℝ × ℝ}
    (hf : DifferentiableAt ℝ f q) (hg : DifferentiableAt ℝ g q) :
    DifferentiableAt ℝ (fun y => f y ⬝ᵥ g y) q ∧
      ∀ v, fderiv ℝ (fun y => f y ⬝ᵥ g y) q v =
        fderiv ℝ f q v ⬝ᵥ g q + f q ⬝ᵥ fderiv ℝ g q v := by
  simpa using fderiv_bilin_aux (dotProductBilin ℝ ℝ) hf hg

#print axioms dot_aux

lemma cross_aux {f g : ℝ × ℝ → Fin 3 → ℝ} {q : ℝ × ℝ}
    (hf : DifferentiableAt ℝ f q) (hg : DifferentiableAt ℝ g q) :
    DifferentiableAt ℝ (fun y => f y ⨯₃ g y) q :=
  (fderiv_bilin_aux crossProduct hf hg).1

#print axioms cross_aux

lemma smooth_aux (r : ℝ × ℝ → Fin 3 → ℝ) (U : Set (ℝ × ℝ)) (hU : IsOpen U)
    (hr : ContDiffOn ℝ ∞ r U) (q : ℝ × ℝ) (hq : q ∈ U) :
    DifferentiableAt ℝ (ru r) q ∧ DifferentiableAt ℝ (rv r) q ∧
      fderiv ℝ (ru r) q (0, 1) = fderiv ℝ (rv r) q (1, 0) := by
  have hfd : ContDiffOn ℝ ∞ (fderiv ℝ r) U := ((contDiffOn_infty_iff_fderiv_of_isOpen hU).1 hr).2
  have hfdq : DifferentiableAt ℝ (fderiv ℝ r) q :=
    (hfd.contDiffAt (hU.mem_nhds hq)).differentiableAt (by simp)
  have hsymm : IsSymmSndFDerivAt ℝ r q :=
    (hr.contDiffAt (hU.mem_nhds hq)).isSymmSndFDerivAt (by simp)
  have eu : ru r = fun y => fderiv ℝ r y (1, 0) := rfl
  have ev : rv r = fun y => fderiv ℝ r y (0, 1) := rfl
  have du : ∀ w, fderiv ℝ (ru r) q w = fderiv ℝ (fderiv ℝ r) q w (1, 0) := by
    intro w
    rw [eu, fderiv_clm_apply hfdq (differentiableAt_const _)]
    simp
  have dv : ∀ w, fderiv ℝ (rv r) q w = fderiv ℝ (fderiv ℝ r) q w (0, 1) := by
    intro w
    rw [ev, fderiv_clm_apply hfdq (differentiableAt_const _)]
    simp
  refine ⟨?_, ?_, ?_⟩
  · rw [eu]; exact hfdq.clm_apply (differentiableAt_const _)
  · rw [ev]; exact hfdq.clm_apply (differentiableAt_const _)
  · rw [du, dv]; exact hsymm _ _

#print axioms smooth_aux

lemma dot_self_pos_aux (v : Fin 3 → ℝ) (h : v ≠ 0) : 0 < v ⬝ᵥ v := by
  have h0 : 0 ≤ v ⬝ᵥ v := Finset.sum_nonneg fun i _ => mul_self_nonneg (v i)
  exact lt_of_le_of_ne h0 fun h' => h (dotProduct_self_eq_zero.1 h'.symm)

#print axioms dot_self_pos_aux

lemma normal_dot_ru (r : ℝ × ℝ → Fin 3 → ℝ) (y : ℝ × ℝ) : normal r y ⬝ᵥ ru r y = 0 := by
  rw [normal, smul_dotProduct, dotProduct_comm _ (ru r y), dot_self_cross, smul_zero]

#print axioms normal_dot_ru

lemma normal_dot_rv (r : ℝ × ℝ → Fin 3 → ℝ) (y : ℝ × ℝ) : normal r y ⬝ᵥ rv r y = 0 := by
  rw [normal, smul_dotProduct, dotProduct_comm _ (rv r y), dot_cross_self, smul_zero]

#print axioms normal_dot_rv

lemma normal_dot_normal (r : ℝ × ℝ → Fin 3 → ℝ) (y : ℝ × ℝ) (h : ru r y ⨯₃ rv r y ≠ 0) :
    normal r y ⬝ᵥ normal r y = 1 := by
  have hpos : 0 < (ru r y ⨯₃ rv r y) ⬝ᵥ (ru r y ⨯₃ rv r y) := by
    exact dot_self_pos_aux _ h
  rw [normal, smul_dotProduct, dotProduct_smul, smul_eq_mul, smul_eq_mul]
  have hs := Real.mul_self_sqrt hpos.le
  have hs0 : Real.sqrt ((ru r y ⨯₃ rv r y) ⬝ᵥ (ru r y ⨯₃ rv r y)) ≠ 0 :=
    (Real.sqrt_pos.2 hpos).ne'
  field_simp
  linarith

#print axioms normal_dot_normal

lemma normal_differentiableAt (r : ℝ × ℝ → Fin 3 → ℝ) (q : ℝ × ℝ)
    (hu : DifferentiableAt ℝ (ru r) q) (hv : DifferentiableAt ℝ (rv r) q)
    (h : ru r q ⨯₃ rv r q ≠ 0) : DifferentiableAt ℝ (normal r) q := by
  have hN := cross_aux hu hv
  have hD := (dot_aux hN hN).1
  have hpos : 0 < (ru r q ⨯₃ rv r q) ⬝ᵥ (ru r q ⨯₃ rv r q) := by
    exact dot_self_pos_aux _ h
  have hS := hD.sqrt hpos.ne'
  have hI := hS.inv (Real.sqrt_pos.2 hpos).ne'
  exact hI.smul hN

#print axioms normal_differentiableAt

lemma normal_deriv_aux (r : ℝ × ℝ → Fin 3 → ℝ) (U : Set (ℝ × ℝ)) (hU : IsOpen U)
    (hr : ContDiffOn ℝ ∞ r U) (hreg : ∀ q ∈ U, ru r q ⨯₃ rv r q ≠ 0)
    (q : ℝ × ℝ) (hq : q ∈ U) (e : ℝ × ℝ) :
    -fderiv ℝ (normal r) q e ⬝ᵥ (ru r q ⨯₃ rv r q) = 0 ∧
      -fderiv ℝ (normal r) q e ⬝ᵥ ru r q = fderiv ℝ (ru r) q e ⬝ᵥ normal r q ∧
      -fderiv ℝ (normal r) q e ⬝ᵥ rv r q = fderiv ℝ (rv r) q e ⬝ᵥ normal r q := by
  obtain ⟨hu, hv, -⟩ := smooth_aux r U hU hr q hq
  have hn := normal_differentiableAt r q hu hv (hreg q hq)
  -- n · r_u is identically zero
  have h1 := (dot_aux hn hu).2 e
  have c1 : (fun y => normal r y ⬝ᵥ ru r y) = fun _ => (0 : ℝ) := funext (normal_dot_ru r)
  rw [c1, fderiv_const_apply] at h1
  have h2 := (dot_aux hn hv).2 e
  have c2 : (fun y => normal r y ⬝ᵥ rv r y) = fun _ => (0 : ℝ) := funext (normal_dot_rv r)
  rw [c2, fderiv_const_apply] at h2
  have h3 := (dot_aux hn hn).2 e
  have c3 : (fun y => normal r y ⬝ᵥ normal r y) =ᶠ[nhds q] fun _ => (1 : ℝ) :=
    Filter.eventuallyEq_of_mem (hU.mem_nhds hq) fun y hy => normal_dot_normal r y (hreg y hy)
  rw [c3.fderiv_eq, fderiv_const_apply] at h3
  simp only [zero_apply] at h1 h2 h3
  rw [dotProduct_comm (normal r q)] at h3
  have hnn : fderiv ℝ (normal r) q e ⬝ᵥ normal r q = 0 := by linarith
  have hc : (Real.sqrt ((ru r q ⨯₃ rv r q) ⬝ᵥ (ru r q ⨯₃ rv r q)))⁻¹ ≠ 0 := by
    have hpos : 0 < (ru r q ⨯₃ rv r q) ⬝ᵥ (ru r q ⨯₃ rv r q) := by
      exact dot_self_pos_aux _ (hreg q hq)
    exact inv_ne_zero (Real.sqrt_pos.2 hpos).ne'
  rw [normal, dotProduct_smul, smul_eq_mul] at hnn
  refine ⟨?_, ?_, ?_⟩
  · rw [neg_dotProduct, (mul_eq_zero.1 hnn).resolve_left hc, neg_zero]
  · rw [neg_dotProduct, dotProduct_comm (fderiv ℝ (ru r) q e)]; linarith
  · rw [neg_dotProduct, dotProduct_comm (fderiv ℝ (rv r) q e)]; linarith

#print axioms normal_deriv_aux

/-- The Weingarten equations: the shape operator says how fast the normal turns. Let `r(u, v)` be
a patch that is smooth on an open set `U` of plan points and regular there (`r_u × r_v ≠ 0`), and
let `n` be its unit normal `(r_u × r_v)/‖r_u × r_v‖`. At every point of `U`, with
`W = I⁻¹ II`,
`-n_u = W₁₁ r_u + W₂₁ r_v` and `-n_v = W₁₂ r_u + W₂₂ r_v`. -/
theorem weingarten_equations (r : ℝ × ℝ → Fin 3 → ℝ) (U : Set (ℝ × ℝ)) (hU : IsOpen U)
    (hr : ContDiffOn ℝ ∞ r U) (hreg : ∀ q ∈ U, ru r q ⨯₃ rv r q ≠ 0)
    (q : ℝ × ℝ) (hq : q ∈ U) :
    -fderiv ℝ (normal r) q (1, 0) =
        shapeOperator r q 0 0 • ru r q + shapeOperator r q 1 0 • rv r q ∧
      -fderiv ℝ (normal r) q (0, 1) =
        shapeOperator r q 0 1 • ru r q + shapeOperator r q 1 1 • rv r q := by
  obtain ⟨-, -, hsym⟩ := smooth_aux r U hU hr q hq
  obtain ⟨a1, a2, a3⟩ := normal_deriv_aux r U hU hr hreg q hq (1, 0)
  obtain ⟨b1, b2, b3⟩ := normal_deriv_aux r U hU hr hreg q hq (0, 1)
  constructor
  · exact decomp_aux (ru r q) (rv r q) _ (hreg q hq) (secondForm r q) 0 a1
      (by rw [a2]; simp [secondForm]) (by rw [a3, ← hsym]; simp [secondForm])
  · exact decomp_aux (ru r q) (rv r q) _ (hreg q hq) (secondForm r q) 1 b1
      (by rw [b2]; simp [secondForm]) (by rw [b3]; simp [secondForm])

/-- The area rule: `det W` is the Gauss map's area stretch. Under the same hypotheses,
`n_u × n_v = det W (r_u × r_v)`: a small patch of surface with area vector `r_u × r_v` sends its
normals over a patch of the unit globe with area vector `det W` times as large, traced the other
way round when `det W < 0`. -/
theorem gauss_map_area_rule (r : ℝ × ℝ → Fin 3 → ℝ) (U : Set (ℝ × ℝ)) (hU : IsOpen U)
    (hr : ContDiffOn ℝ ∞ r U) (hreg : ∀ q ∈ U, ru r q ⨯₃ rv r q ≠ 0)
    (q : ℝ × ℝ) (hq : q ∈ U) :
    fderiv ℝ (normal r) q (1, 0) ⨯₃ fderiv ℝ (normal r) q (0, 1) =
      (shapeOperator r q).det • (ru r q ⨯₃ rv r q) := by
  obtain ⟨h1, h2⟩ := weingarten_equations r U hU hr hreg q hq
  rw [← neg_neg (fderiv ℝ (normal r) q (1, 0)), ← neg_neg (fderiv ℝ (normal r) q (0, 1)),
    h1, h2, Matrix.det_fin_two]
  ext i
  fin_cases i <;> simp [cross_apply] <;> ring

/-- The determinant and trace of `W` ignore the chart. A change of chart with Jacobian matrix `J`
(`det J ≠ 0`) changes the first form to `Jᵀ I J` and, with the same normal, the second form to
`Jᵀ II J`; then `W' = (Jᵀ I J)⁻¹ (Jᵀ II J)` has the same determinant and trace as `W = I⁻¹ II`.
If the new chart's normal points the other way, the second form is `-(Jᵀ II J)`: the determinant
is still the same and the trace changes sign. -/
theorem det_trace_shape_operator_chart_invariant (I II J : Matrix (Fin 2) (Fin 2) ℝ)
    (hI : I.det ≠ 0) (hJ : J.det ≠ 0) :
    ((Jᵀ * I * J)⁻¹ * (Jᵀ * II * J)).det = (I⁻¹ * II).det ∧
      ((Jᵀ * I * J)⁻¹ * (Jᵀ * II * J)).trace = (I⁻¹ * II).trace ∧
      ((Jᵀ * I * J)⁻¹ * -(Jᵀ * II * J)).det = (I⁻¹ * II).det ∧
      ((Jᵀ * I * J)⁻¹ * -(Jᵀ * II * J)).trace = -(I⁻¹ * II).trace := by
  have hJt : IsUnit Jᵀ.det := by rw [Matrix.det_transpose]; exact hJ.isUnit
  have hJu : IsUnit J := (Matrix.isUnit_iff_isUnit_det J).2 hJ.isUnit
  have key : (Jᵀ * I * J)⁻¹ * (Jᵀ * II * J) = J⁻¹ * (I⁻¹ * II) * J := by
    rw [Matrix.mul_inv_rev, Matrix.mul_inv_rev]
    simp only [Matrix.mul_assoc]
    rw [Matrix.nonsing_inv_mul_cancel_left (h := hJt)]
  have hd : (J⁻¹ * (I⁻¹ * II) * J).det = (I⁻¹ * II).det := Matrix.det_conj' hJu _
  have ht : (J⁻¹ * (I⁻¹ * II) * J).trace = (I⁻¹ * II).trace := by
    rw [Matrix.mul_assoc, Matrix.trace_mul_comm, Matrix.mul_assoc,
      Matrix.mul_nonsing_inv _ hJ.isUnit, Matrix.mul_one]
  refine ⟨by rw [key, hd], by rw [key, ht], ?_, ?_⟩
  · rw [Matrix.mul_neg, key, Matrix.det_neg, hd]; simp
  · rw [Matrix.mul_neg, key, Matrix.trace_neg, ht]

open Matrix

-- The saddle r(u, v) = (u, v, 30 + (u² - v²)/120) at the lamp fixing P = (30, 20).
-- r_u × r_v = (1, 0, 1/2) × (0, 1, -1/3) = (-1/2, 1/3, 1), with squared length 49/36.
example : ![(1 : ℝ), 0, 1 / 2] ⨯₃ ![0, 1, -1 / 3] = ![-1 / 2, 1 / 3, 1] := by
  ext i; fin_cases i <;> simp [cross_apply] <;> norm_num
example : ![(-1 : ℝ) / 2, 1 / 3, 1] ⬝ᵥ ![-1 / 2, 1 / 3, 1] = 49 / 36 := by
  simp [dotProduct, Fin.sum_univ_succ]; norm_num
-- The unit normal is (-3, 2, 6)/7.
example : (Real.sqrt (49 / 36))⁻¹ • ![(-1 : ℝ) / 2, 1 / 3, 1] = ![-3 / 7, 2 / 7, 6 / 7] := by
  have h : Real.sqrt (49 / 36) = 7 / 6 := by
    rw [Real.sqrt_eq_iff_mul_self_eq] <;> norm_num
  rw [h]; ext i; fin_cases i <;> simp <;> norm_num
-- L = r_uu · n = 1/70 and N = r_vv · n = -1/70.
example : ![(0 : ℝ), 0, 1 / 60] ⬝ᵥ ![-3 / 7, 2 / 7, 6 / 7] = 1 / 70 := by
  simp [dotProduct, Fin.sum_univ_succ]; norm_num
example : ![(0 : ℝ), 0, -1 / 60] ⬝ᵥ ![-3 / 7, 2 / 7, 6 / 7] = -1 / 70 := by
  simp [dotProduct, Fin.sum_univ_succ]; norm_num
-- E, F, G = 5/4, -1/6, 10/9, so EG - F² = 49/36.
example : (!![5 / 4, -1 / 6; -1 / 6, 10 / 9] : Matrix (Fin 2) (Fin 2) ℝ).det = 49 / 36 := by
  rw [det_fin_two_of]; norm_num
-- det W = -9/60025 and trace W = -1/686 at P.
example : ((!![5 / 4, -1 / 6; -1 / 6, 10 / 9] : Matrix (Fin 2) (Fin 2) ℝ)⁻¹ *
    !![1 / 70, 0; 0, -1 / 70]).det = -9 / 60025 := by
  rw [inv_def, det_fin_two_of, adjugate_fin_two_of]; simp [det_fin_two_of]; norm_num
example : ((!![5 / 4, -1 / 6; -1 / 6, 10 / 9] : Matrix (Fin 2) (Fin 2) ℝ)⁻¹ *
    !![1 / 70, 0; 0, -1 / 70]).trace = -1 / 686 := by
  rw [inv_def, det_fin_two_of, adjugate_fin_two_of]; simp [trace_fin_two]; norm_num
-- The seam chart u = p + q, v = p - q: det J = -2, and the second form becomes L, M, N = 0, 1/35, 0.
example : (!![1, 1; 1, -1] : Matrix (Fin 2) (Fin 2) ℝ).det = -2 := by
  rw [det_fin_two_of]; norm_num
example : (!![1, 1; 1, -1] : Matrix (Fin 2) (Fin 2) ℝ)ᵀ * !![1 / 70, 0; 0, -1 / 70] *
    !![1, 1; 1, -1] = !![0, 1 / 35; 1 / 35, 0] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_succ] <;> norm_num
-- Ten metres east of P the roof stands II/2 = (1/2)(1/70)(10²) = 5/7 m off its tangent plane.
example : (1 / 2 : ℝ) * (1 / 70) * 10 ^ 2 = 5 / 7 := by norm_num
-- The dome of radius 60 m: W = -(1/60) times the identity, so det W = 1/3600.
example : (!![-1 / 60, 0; 0, -1 / 60] : Matrix (Fin 2) (Fin 2) ℝ).det = 1 / 3600 := by
  rw [det_fin_two_of]; norm_num

#print axioms weingarten_equations
#print axioms gauss_map_area_rule
#print axioms det_trace_shape_operator_chart_invariant

end GaussMap
