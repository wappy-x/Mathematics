-- Fredholm alternative: for a compact operator K on a Hilbert space, either u - Ku = f has exactly one answer for every f, or u - Ku = 0 has d > 0 independent answers, the adjoint equation v - K*v = 0 has the same number d, and f has an answer exactly when it is perpendicular to every answer of the adjoint equation.
import Mathlib.Analysis.InnerProductSpace.Adjoint
import Mathlib.Analysis.Normed.Operator.Compact.Basic
import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.LinearAlgebra.Dimension.Finrank
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Data.Matrix.Mul
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

import Mathlib.Analysis.InnerProductSpace.Spectrum
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Normed.Operator.Compact.FredholmAlternative
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Periodic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.LinearAlgebra.Matrix.Rank
import Mathlib.LinearAlgebra.Matrix.DotProduct
import Mathlib.LinearAlgebra.FiniteDimensional.Lemmas
open scoped InnerProductSpace

section FredholmHelpers

variable {𝕜 E : Type*} [RCLike 𝕜] [NormedAddCommGroup E] [InnerProductSpace 𝕜 E] [CompleteSpace E]

/-- The adjoint of a compact operator on a Hilbert space is compact. -/
theorem fa_adjoint_isCompactOperator (K : E →L[𝕜] E) (hK : IsCompactOperator K) :
    IsCompactOperator (ContinuousLinearMap.adjoint K) := by
  set A := ContinuousLinearMap.adjoint K with hA
  have hKA : IsCompactOperator (K.comp A) := hK.comp_clm A
  obtain ⟨C, hC, hCsub⟩ := hKA.image_closedBall_subset_compact 1
  have htb : TotallyBounded ((K.comp A) '' Metric.closedBall 0 1) := hC.totallyBounded.subset hCsub
  have key : ∀ w : E, ‖A w‖ ^ 2 ≤ ‖w‖ * ‖K (A w)‖ := by
    intro w
    rw [@norm_sq_eq_re_inner 𝕜, hA, ContinuousLinearMap.adjoint_inner_left]
    exact (RCLike.re_le_norm _).trans (norm_inner_le_norm _ _)
  have hAtb : TotallyBounded (A '' Metric.closedBall 0 1) := by
    rw [Metric.totallyBounded_iff]
    intro ε hε
    obtain ⟨t, hts, htfin, htcov⟩ := Metric.finite_approx_of_totallyBounded htb (ε ^ 2 / 4)
      (by positivity)
    have hpre : ∀ y ∈ t, ∃ x ∈ Metric.closedBall (0 : E) 1, K (A x) = y := by
      intro y hy
      obtain ⟨x, hx, rfl⟩ := hts hy
      exact ⟨x, hx, rfl⟩
    choose! g hgB hg using hpre
    refine ⟨(fun y => A (g y)) '' t, htfin.image _, ?_⟩
    rintro _ ⟨x, hx, rfl⟩
    have hmem : K (A x) ∈ (K.comp A) '' Metric.closedBall 0 1 := ⟨x, hx, rfl⟩
    have := htcov hmem
    simp only [Set.mem_iUnion] at this
    obtain ⟨y, hy, hdist⟩ := this
    simp only [Set.mem_iUnion]
    refine ⟨A (g y), ⟨y, hy, rfl⟩, ?_⟩
    rw [Metric.mem_ball, dist_eq_norm] at hdist ⊢
    have hk := key (x - g y)
    have hxn : ‖x‖ ≤ 1 := by simpa using hx
    have hgn : ‖g y‖ ≤ 1 := by simpa using hgB y hy
    have hwn : ‖x - g y‖ ≤ 2 := (norm_sub_le _ _).trans (by linarith)
    rw [map_sub, map_sub, hg y hy] at hk
    have h2 : ‖A x - A (g y)‖ ^ 2 < ε ^ 2 := by
      calc ‖A x - A (g y)‖ ^ 2 ≤ ‖x - g y‖ * ‖K (A x) - y‖ := hk
        _ ≤ 2 * (ε ^ 2 / 4) := by
          apply mul_le_mul hwn hdist.le (norm_nonneg _) (by norm_num)
        _ < ε ^ 2 := by nlinarith
    exact lt_of_pow_lt_pow_left₀ 2 hε.le h2
  exact (isCompactOperator_iff_isCompact_closure_image_closedBall (A : E →ₗ[𝕜] E) one_pos).mpr
    (hAtb.closure.isCompact_of_isClosed isClosed_closure)

/-- A compact operator plus a finite-rank piece: if `1 - K - F` has no kernel, it is onto. -/
theorem fa_surj {ι : Type*} [Fintype ι] (K : E →L[𝕜] E) (hK : IsCompactOperator K)
    (e f : ι → E) (hf : Orthonormal 𝕜 f)
    (hfN : ∀ j, ContinuousLinearMap.adjoint K (f j) = f j)
    (he : ∀ x, K x = x → (∀ j, ⟪e j, x⟫_𝕜 = 0) → x = 0) (y : E) :
    ∃ x, x - K x - ∑ j, ⟪e j, x⟫_𝕜 • f j = y := by
  classical
  let F : E →L[𝕜] E := ∑ j, (innerSL 𝕜 (e j)).smulRight (f j)
  have hF : ∀ x, F x = ∑ j, ⟪e j, x⟫_𝕜 • f j := by
    intro x; simp [F]
  have hrank : ∀ j, IsCompactOperator ((innerSL 𝕜 (e j)).smulRight (f j)) := by
    intro j
    have := ((isCompactOperator_id (E := 𝕜)).comp_clm (innerSL 𝕜 (e j))).continuous_comp
      (g := fun c : 𝕜 => c • f j) (by fun_prop)
    convert this using 1
    ext x
    simp
  have hFc : IsCompactOperator F := by
    have : ∀ s : Finset ι, IsCompactOperator (∑ j ∈ s, (innerSL 𝕜 (e j)).smulRight (f j)) := by
      intro s
      induction s using Finset.induction_on with
      | empty => simpa using (isCompactOperator_zero : IsCompactOperator (0 : E → E))
      | insert a s ha ih =>
        rw [Finset.sum_insert ha]
        exact (hrank a).add ih
    have hcoe : (F : E → E) = ∑ j, ⇑((innerSL 𝕜 (e j)).smulRight (f j)) := FunLike.coe_sum _ _
    rw [hcoe]
    exact this Finset.univ
  have hT : IsCompactOperator (K + F) := by
    rw [FunLike.coe_add]; exact hK.add hFc
  rcases IsCompactOperator.hasEigenvalue_or_mem_resolventSet hT (μ := (1 : 𝕜)) one_ne_zero with
    h | h
  · exfalso
    obtain ⟨x, hx⟩ := h.exists_hasEigenvector
    apply hx.2
    have hTx : K x + F x = x := by
      have := hx.apply_eq_smul
      simpa using this
    have hsF : x - K x = F x := by
      calc x - K x = (K x + F x) - K x := by rw [hTx]
        _ = F x := by abel
    have hfs : ∀ j, ⟪f j, x - K x⟫_𝕜 = 0 := by
      intro j
      rw [inner_sub_right, ← ContinuousLinearMap.adjoint_inner_left, hfN j, sub_self]
    have hFF : ⟪F x, F x⟫_𝕜 = 0 := by
      calc ⟪F x, F x⟫_𝕜 = ⟪F x, x - K x⟫_𝕜 := by rw [hsF]
        _ = 0 := by
          rw [hF, sum_inner]
          simp [inner_smul_left, hfs]
    have hF0 : F x = 0 := inner_self_eq_zero.mp hFF
    apply he x
    · have := hsF; rw [hF0, sub_eq_zero] at this; exact this.symm
    · intro i
      have := hf.inner_right_fintype (fun j => ⟪e j, x⟫_𝕜) i
      rw [← hF, hF0, inner_zero_right] at this
      exact this.symm
  · rw [spectrum.mem_resolventSet_iff, ContinuousLinearMap.isUnit_iff_bijective] at h
    obtain ⟨x, hx⟩ := h.2 y
    refine ⟨x, ?_⟩
    rw [← hx, ← hF]
    simp only [map_one, ContinuousLinearMap.sub_apply, ContinuousLinearMap.add_apply,
      ContinuousLinearMap.one_apply]
    abel

/-- Under the same hypotheses, every `y` perpendicular to the fixed points of the adjoint is
in the range of `1 - K`. -/
theorem fa_range {ι : Type*} [Fintype ι] (K : E →L[𝕜] E) (hK : IsCompactOperator K)
    (e f : ι → E) (hf : Orthonormal 𝕜 f)
    (hfN : ∀ j, ContinuousLinearMap.adjoint K (f j) = f j)
    (he : ∀ x, K x = x → (∀ j, ⟪e j, x⟫_𝕜 = 0) → x = 0) (y : E)
    (hy : ∀ v, ContinuousLinearMap.adjoint K v = v → ⟪v, y⟫_𝕜 = 0) :
    ∃ x, x - K x = y := by
  obtain ⟨x, hx⟩ := fa_surj K hK e f hf hfN he y
  set Fx := ∑ j, ⟪e j, x⟫_𝕜 • f j with hFx
  have hfs : ∀ j, ⟪f j, x - K x⟫_𝕜 = 0 := by
    intro j
    rw [inner_sub_right, ← ContinuousLinearMap.adjoint_inner_left, hfN j, sub_self]
  have h1 : ⟪Fx, x - K x⟫_𝕜 = 0 := by
    rw [hFx, sum_inner]
    simp [inner_smul_left, hfs]
  have hFxN : ContinuousLinearMap.adjoint K Fx = Fx := by
    rw [hFx, map_sum]
    simp [hfN]
  have h2 : ⟪Fx, y⟫_𝕜 = 0 := hy Fx hFxN
  have h3 : Fx = x - K x - y := by rw [← hx]; abel
  have hFF : ⟪Fx, Fx⟫_𝕜 = 0 := by
    conv_lhs => arg 3; rw [h3]
    rw [inner_sub_right, h1, h2, sub_zero]
  have hF0 : Fx = 0 := inner_self_eq_zero.mp hFF
  refine ⟨x, ?_⟩
  rw [← hx, hF0, sub_zero]

/-- The fixed points of the adjoint are no more numerous than those of `K`. -/
theorem fa_finrank_le (K : E →L[𝕜] E) (hK : IsCompactOperator K) (V W : Submodule 𝕜 E)
    [FiniteDimensional 𝕜 V] [FiniteDimensional 𝕜 W] (hV : ∀ x, K x = x → x ∈ V)
    (hW : ∀ w ∈ W, ContinuousLinearMap.adjoint K w = w) :
    Module.finrank 𝕜 W ≤ Module.finrank 𝕜 V := by
  by_contra hlt
  push Not at hlt
  let bV := stdOrthonormalBasis 𝕜 V
  let bW := stdOrthonormalBasis 𝕜 W
  let e : Fin (Module.finrank 𝕜 V) → E := fun j => (bV j : E)
  have hbW : Orthonormal 𝕜 (fun i => (bW i : E)) := bW.orthonormal.comp_linearIsometry W.subtypeₗᵢ
  let f : Fin (Module.finrank 𝕜 V) → E := fun j => (bW (Fin.castLE hlt.le j) : E)
  have hf : Orthonormal 𝕜 f := hbW.comp _ (Fin.castLE_injective _)
  have hfN : ∀ j, ContinuousLinearMap.adjoint K (f j) = f j := fun j => hW _ (bW _).2
  have he : ∀ x, K x = x → (∀ j, ⟪e j, x⟫_𝕜 = 0) → x = 0 := by
    intro x hx hc
    have hxV := hV x hx
    have hrep : bV.repr ⟨x, hxV⟩ = 0 := by
      ext j
      rw [bV.repr_apply_apply]
      simpa [e, Submodule.coe_inner] using hc j
    have := bV.repr.injective (hrep.trans (map_zero _).symm)
    simpa using congrArg Subtype.val this
  let g : E := bW ⟨Module.finrank 𝕜 V, hlt⟩
  obtain ⟨x, hx⟩ := fa_surj K hK e f hf hfN he g
  have hgN : ContinuousLinearMap.adjoint K g = g := hW _ (bW _).2
  have hgf : ∀ j, ⟪g, f j⟫_𝕜 = 0 := by
    intro j
    have := orthonormal_iff_ite.mp hbW ⟨Module.finrank 𝕜 V, hlt⟩ (Fin.castLE hlt.le j)
    rw [if_neg] at this
    · exact this
    · intro h
      have := congrArg Fin.val h
      simp at this
      omega
  have hgg : ⟪g, g⟫_𝕜 = 0 := by
    conv_lhs => arg 3; rw [← hx]
    rw [inner_sub_right, inner_sub_right, inner_sum, ← ContinuousLinearMap.adjoint_inner_left, hgN]
    simp [inner_smul_right, hgf]
  have hg0 : g = 0 := inner_self_eq_zero.mp hgg
  have hn : ‖g‖ = 1 := hbW.1 _
  rw [hg0, norm_zero] at hn
  exact zero_ne_one hn

end FredholmHelpers

#print axioms fa_adjoint_isCompactOperator
#print axioms fa_surj
#print axioms fa_range
#print axioms fa_finrank_le

/-- The Fredholm alternative. Let K be a compact operator on a Hilbert space and look at the
equation u - Ku = f. Either u - Ku = 0 has only the answer u = 0, and then every f has exactly
one answer u; or u - Ku = 0 has a finite number d > 0 of independent answers, the adjoint
equation v - K*v = 0 has the same number d of independent answers, and f has an answer exactly
when f is perpendicular to every answer v of the adjoint equation. -/
theorem fredholm_alternative {𝕜 E : Type*} [RCLike 𝕜] [NormedAddCommGroup E]
    [InnerProductSpace 𝕜 E] [CompleteSpace E] (K : E →L[𝕜] E) (hK : IsCompactOperator K) :
    (LinearMap.ker (((1 : E →L[𝕜] E) - K : E →L[𝕜] E) : E →ₗ[𝕜] E) = ⊥ ∧ ∀ f : E, ∃! u : E, u - K u = f) ∨
    (∃ d : ℕ, 0 < d ∧
      Module.finrank 𝕜 (LinearMap.ker (((1 : E →L[𝕜] E) - K : E →L[𝕜] E) : E →ₗ[𝕜] E)) = d ∧
      Module.finrank 𝕜
          (LinearMap.ker
            (((1 : E →L[𝕜] E) - ContinuousLinearMap.adjoint K : E →L[𝕜] E) : E →ₗ[𝕜] E)) = d ∧
      ∀ f : E, (∃ u : E, u - K u = f) ↔
        ∀ v : E, v - ContinuousLinearMap.adjoint K v = 0 → ⟪v, f⟫_𝕜 = 0) := by
  set N := LinearMap.ker (((1 : E →L[𝕜] E) - K : E →L[𝕜] E) : E →ₗ[𝕜] E) with hNdef
  set N' := LinearMap.ker
    (((1 : E →L[𝕜] E) - ContinuousLinearMap.adjoint K : E →L[𝕜] E) : E →ₗ[𝕜] E) with hN'def
  have memN : ∀ x, x ∈ N ↔ K x = x := by
    intro x; simp only [N, LinearMap.mem_ker, ContinuousLinearMap.coe_coe]
    simp
    rw [sub_eq_zero, eq_comm]
  have memN' : ∀ x, x ∈ N' ↔ ContinuousLinearMap.adjoint K x = x := by
    intro x; simp only [N', LinearMap.mem_ker, ContinuousLinearMap.coe_coe]
    simp
    rw [sub_eq_zero, eq_comm]
  have hKa := fa_adjoint_isCompactOperator K hK
  have hNe : N = Module.End.eigenspace (K : E →ₗ[𝕜] E) 1 := by
    ext x; rw [memN, Module.End.mem_eigenspace_iff, one_smul]; rfl
  have hN'e : N' = Module.End.eigenspace
      ((ContinuousLinearMap.adjoint K : E →L[𝕜] E) : E →ₗ[𝕜] E) 1 := by
    ext x; rw [memN', Module.End.mem_eigenspace_iff, one_smul]; rfl
  have : FiniteDimensional 𝕜 N := by
    rw [hNe]; exact ContinuousLinearMap.finite_dimensional_eigenspace hK 1 one_ne_zero
  have : FiniteDimensional 𝕜 N' := by
    rw [hN'e]; exact ContinuousLinearMap.finite_dimensional_eigenspace hKa 1 one_ne_zero
  have hle1 : Module.finrank 𝕜 N' ≤ Module.finrank 𝕜 N :=
    fa_finrank_le K hK N N' (fun x hx => (memN x).2 hx) (fun w hw => (memN' w).1 hw)
  have hle2 : Module.finrank 𝕜 N ≤ Module.finrank 𝕜 N' :=
    fa_finrank_le (ContinuousLinearMap.adjoint K) hKa N' N (fun x hx => (memN' x).2 hx)
      (fun w hw => by rw [ContinuousLinearMap.adjoint_adjoint]; exact (memN w).1 hw)
  by_cases h0 : N = ⊥
  · left
    refine ⟨h0, fun y => ?_⟩
    have hf0 : Orthonormal 𝕜 (Fin.elim0 : Fin 0 → E) := ⟨fun i => i.elim0, fun i => i.elim0⟩
    obtain ⟨x, hx⟩ := fa_surj K hK (Fin.elim0 : Fin 0 → E) Fin.elim0 hf0 (fun i => i.elim0)
      (fun x hx _ => by
        have : x ∈ N := (memN x).2 hx
        rw [h0] at this; exact this) y
    simp only [Finset.univ_eq_empty, Finset.sum_empty, sub_zero] at hx
    refine ⟨x, hx, fun u hu => ?_⟩
    have hmem : u - x ∈ N := by
      rw [memN, map_sub]
      have h3 : (u - K u) - (x - K x) = 0 := by rw [hu, hx, sub_self]
      rw [eq_comm, ← sub_eq_zero, ← h3]
      abel
    rw [h0, Submodule.mem_bot, sub_eq_zero] at hmem
    exact hmem
  · right
    refine ⟨Module.finrank 𝕜 N, ?_, rfl, le_antisymm hle1 hle2, ?_⟩
    · exact Nat.pos_of_ne_zero (fun h => h0 (Submodule.finrank_eq_zero.mp h))
    · intro y
      constructor
      · rintro ⟨u, rfl⟩ v hv
        rw [inner_sub_right, ← ContinuousLinearMap.adjoint_inner_left, (sub_eq_zero.mp hv).symm,
          sub_self]
      · intro hy
        let bN := stdOrthonormalBasis 𝕜 N
        let bN' := stdOrthonormalBasis 𝕜 N'
        have hbN' : Orthonormal 𝕜 (fun i => (bN' i : E)) :=
          bN'.orthonormal.comp_linearIsometry N'.subtypeₗᵢ
        let e : Fin (Module.finrank 𝕜 N) → E := fun j => (bN j : E)
        let f : Fin (Module.finrank 𝕜 N) → E := fun j => (bN' (Fin.castLE hle2 j) : E)
        have hf : Orthonormal 𝕜 f := hbN'.comp _ (Fin.castLE_injective _)
        have hfN : ∀ j, ContinuousLinearMap.adjoint K (f j) = f j :=
          fun j => (memN' _).1 (bN' _).2
        have he : ∀ x, K x = x → (∀ j, ⟪e j, x⟫_𝕜 = 0) → x = 0 := by
          intro x hx hc
          have hxN := (memN x).2 hx
          have hrep : bN.repr ⟨x, hxN⟩ = 0 := by
            ext j
            rw [bN.repr_apply_apply]
            simpa [e, Submodule.coe_inner] using hc j
          have := bN.repr.injective (hrep.trans (map_zero _).symm)
          simpa using congrArg Subtype.val this
        exact fa_range K hK e f hf hfN he y (fun v hv => hy v (by rw [hv, sub_self]))

/-- The matrix case, proved on the card from rank and nullity. For a square N by N real matrix
A: the equations A x = 0 and Aᵀ v = 0 have the same number of independent answers; A x = b has
an answer exactly when b is perpendicular to every v with Aᵀ v = 0; and if A x = 0 has only the
answer x = 0, then every b has exactly one answer. -/
theorem matrix_fredholm_alternative {N : ℕ} (A : Matrix (Fin N) (Fin N) ℝ) :
    Module.finrank ℝ (LinearMap.ker A.mulVecLin) =
        Module.finrank ℝ (LinearMap.ker A.transpose.mulVecLin) ∧
      (∀ b : Fin N → ℝ, (∃ x, A.mulVec x = b) ↔
        ∀ v : Fin N → ℝ, A.transpose.mulVec v = 0 → v ⬝ᵥ b = 0) ∧
      ((∀ x : Fin N → ℝ, A.mulVec x = 0 → x = 0) →
        ∀ b : Fin N → ℝ, ∃! x, A.mulVec x = b) := by
  have h1 := LinearMap.finrank_range_add_finrank_ker A.mulVecLin
  have h2 := LinearMap.finrank_range_add_finrank_ker A.transpose.mulVecLin
  have hr : Module.finrank ℝ (LinearMap.range A.transpose.mulVecLin) =
      Module.finrank ℝ (LinearMap.range A.mulVecLin) := A.rank_transpose
  have hdim : Module.finrank ℝ (LinearMap.ker A.mulVecLin) =
      Module.finrank ℝ (LinearMap.ker A.transpose.mulVecLin) := by
    simp only [Module.finrank_fin_fun] at h1 h2
    omega
  refine ⟨hdim, ?_, ?_⟩
  · intro b
    constructor
    · rintro ⟨x, rfl⟩ v hv
      rw [Matrix.dotProduct_mulVec, ← Matrix.mulVec_transpose, hv, zero_dotProduct]
    · intro hb
      have hdisj : Disjoint (LinearMap.range A.mulVecLin) (LinearMap.ker A.transpose.mulVecLin) := by
        rw [Submodule.disjoint_def]
        rintro v ⟨x, rfl⟩ hv
        rw [LinearMap.mem_ker, Matrix.mulVecLin_apply] at hv
        simp only [Matrix.mulVecLin_apply] at hv ⊢
        rw [← dotProduct_self_eq_zero, Matrix.dotProduct_mulVec, ← Matrix.mulVec_transpose, hv,
          zero_dotProduct]
      have hcompl : IsCompl (LinearMap.range A.mulVecLin) (LinearMap.ker A.transpose.mulVecLin) := by
        rw [Submodule.isCompl_iff_disjoint]
        · exact hdisj
        · simp only [Module.finrank_fin_fun] at h1 h2 ⊢
          omega
      have hb' : b ∈ LinearMap.range A.mulVecLin ⊔ LinearMap.ker A.transpose.mulVecLin := by
        rw [hcompl.sup_eq_top]; trivial
      obtain ⟨y, ⟨x, rfl⟩, v, hv, hsum⟩ := Submodule.mem_sup.mp hb'
      rw [LinearMap.mem_ker, Matrix.mulVecLin_apply] at hv
      have hvb := hb v hv
      have hv0 : v = 0 := by
        rw [← hsum, dotProduct_add, Matrix.mulVecLin_apply,
          Matrix.dotProduct_mulVec, ← Matrix.mulVec_transpose, hv, zero_dotProduct, zero_add,
          dotProduct_self_eq_zero] at hvb
        exact hvb
      refine ⟨x, ?_⟩
      rw [← hsum, hv0, add_zero, Matrix.mulVecLin_apply]
  · intro hinj b
    have hi : Function.Injective A.mulVecLin := by
      rw [← LinearMap.ker_eq_bot, LinearMap.ker_eq_bot']
      intro x hx
      exact hinj x hx
    have hs : Function.Surjective A.mulVecLin := LinearMap.injective_iff_surjective.mp hi
    obtain ⟨x, hx⟩ := hs b
    refine ⟨x, hx, fun y hy => hi ?_⟩
    simp only [Matrix.mulVecLin_apply]
    rw [hy, ← hx, Matrix.mulVecLin_apply]

/-- The round tunnel's patterns. The view-factor kernel k(x, y) = (1/4)|sin((x - y)/2)| sends the
pattern cos(n y) to 1/(1 - 4n²) times cos(n x): each cos(n x) is an eigenvector of K with
eigenvalue λ_n = 1/(1 - 4n²), so λ_0 = 1, λ_1 = -1/3, λ_2 = -1/15. -/
theorem round_tunnel_eigenvalue (n : ℕ) (x : ℝ) :
    ∫ y in (-Real.pi)..Real.pi, (1 / 4 : ℝ) * |Real.sin ((x - y) / 2)| * Real.cos (n * y) =
      1 / (1 - 4 * (n : ℝ) ^ 2) * Real.cos (n * x) := by
  have hn1 : ((n : ℝ) - 1 / 2) ≠ 0 := by
    rcases n with _ | n
    · norm_num
    · push_cast; have := n.cast_nonneg (α := ℝ); intro h; linarith
  have hn2 : ((n : ℝ) + 1 / 2) ≠ 0 := by
    have := n.cast_nonneg (α := ℝ); intro h; linarith
  have hper : Function.Periodic
      (fun y : ℝ => (1 / 4 : ℝ) * |Real.sin ((x - y) / 2)| * Real.cos (n * y)) (2 * Real.pi) := by
    intro y
    simp only
    have h1 : (x - (y + 2 * Real.pi)) / 2 = (x - y) / 2 - Real.pi := by ring
    have h2 : (n : ℝ) * (y + 2 * Real.pi) = n * y + n * (2 * Real.pi) := by ring
    rw [h1, h2, Real.sin_sub_pi, abs_neg, Real.cos_add_nat_mul_two_pi]
  have hshift := hper.intervalIntegral_add_eq (-Real.pi) (x - 2 * Real.pi)
  rw [show -Real.pi + 2 * Real.pi = Real.pi by ring,
    show x - 2 * Real.pi + 2 * Real.pi = x by ring] at hshift
  rw [hshift]
  have hcongr : ∫ y in (x - 2 * Real.pi)..x,
      (1 / 4 : ℝ) * |Real.sin ((x - y) / 2)| * Real.cos (n * y) =
      ∫ y in (x - 2 * Real.pi)..x, (1 / 4 : ℝ) * Real.sin ((x - y) / 2) * Real.cos (n * y) := by
    apply intervalIntegral.integral_congr
    intro y hy
    rw [Set.uIcc_of_le (by linarith [Real.pi_pos])] at hy
    simp only
    rw [abs_of_nonneg]
    apply Real.sin_nonneg_of_nonneg_of_le_pi
    · linarith [hy.2]
    · linarith [hy.1]
  rw [hcongr]
  let G : ℝ → ℝ := fun y => (1 / 8 : ℝ) *
    (-Real.cos (x / 2 + ((n : ℝ) - 1 / 2) * y) / ((n : ℝ) - 1 / 2) +
      Real.cos (x / 2 - ((n : ℝ) + 1 / 2) * y) / ((n : ℝ) + 1 / 2))
  have hderiv : ∀ y, HasDerivAt G ((1 / 4 : ℝ) * Real.sin ((x - y) / 2) * Real.cos (n * y)) y := by
    intro y
    have hA : HasDerivAt (fun y : ℝ => x / 2 + ((n : ℝ) - 1 / 2) * y) ((n : ℝ) - 1 / 2) y := by
      simpa using ((hasDerivAt_id y).const_mul ((n : ℝ) - 1 / 2)).const_add (x / 2)
    have hB : HasDerivAt (fun y : ℝ => x / 2 - ((n : ℝ) + 1 / 2) * y) (-((n : ℝ) + 1 / 2)) y := by
      simpa using ((hasDerivAt_id y).const_mul ((n : ℝ) + 1 / 2)).const_sub (x / 2)
    have := ((hA.cos.neg.div_const ((n : ℝ) - 1 / 2)).add (hB.cos.div_const ((n : ℝ) + 1 / 2))).const_mul (1 / 8 : ℝ)
    convert this using 1
    have e1 : x / 2 + ((n : ℝ) - 1 / 2) * y = (x - y) / 2 + n * y := by ring
    have e2 : x / 2 - ((n : ℝ) + 1 / 2) * y = (x - y) / 2 - n * y := by ring
    have k1 : -(-Real.sin (x / 2 + ((n : ℝ) - 1 / 2) * y) * ((n : ℝ) - 1 / 2)) / ((n : ℝ) - 1 / 2)
        = Real.sin (x / 2 + ((n : ℝ) - 1 / 2) * y) := by
      rw [neg_mul, neg_neg, mul_div_cancel_right₀ _ hn1]
    have k2 : -Real.sin (x / 2 - ((n : ℝ) + 1 / 2) * y) * -((n : ℝ) + 1 / 2) / ((n : ℝ) + 1 / 2)
        = Real.sin (x / 2 - ((n : ℝ) + 1 / 2) * y) := by
      rw [neg_mul_neg, mul_div_cancel_right₀ _ hn2]
    rw [k1, k2, e1, e2, Real.sin_add, Real.sin_sub]
    ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun y _ => hderiv y)
    ((by fun_prop : Continuous fun y : ℝ =>
      (1 / 4 : ℝ) * Real.sin ((x - y) / 2) * Real.cos (n * y)).intervalIntegrable _ _)]
  simp only [G]
  have e3 : x / 2 + ((n : ℝ) - 1 / 2) * x = n * x := by ring
  have e4 : x / 2 - ((n : ℝ) + 1 / 2) * x = -(n * x) := by ring
  have e5 : x / 2 + ((n : ℝ) - 1 / 2) * (x - 2 * Real.pi) = (n * x + Real.pi) - (n : ℝ) * (2 * Real.pi) := by
    ring
  have e6 : x / 2 - ((n : ℝ) + 1 / 2) * (x - 2 * Real.pi) = (-(n * x) + Real.pi) + (n : ℝ) * (2 * Real.pi) := by
    ring
  rw [e3, e4, e5, e6, Real.cos_sub_nat_mul_two_pi, Real.cos_add_nat_mul_two_pi, Real.cos_add_pi,
    Real.cos_add_pi, Real.cos_neg]
  have h4 : (1 - 4 * (n : ℝ) ^ 2) ≠ 0 := by
    have : (1 - 4 * (n : ℝ) ^ 2) = -4 * (((n : ℝ) - 1 / 2) * ((n : ℝ) + 1 / 2)) := by ring
    rw [this]; exact mul_ne_zero (by norm_num) (mul_ne_zero hn1 hn2)
  have hc1 : (n : ℝ) - 1 / 2 = (2 * n - 1) / 2 := by ring
  have hc2 : (n : ℝ) + 1 / 2 = (2 * n + 1) / 2 := by ring
  have hc3 : (1 - 4 * (n : ℝ) ^ 2) = -((2 * n - 1) * (2 * n + 1)) := by ring
  have ha : (2 * (n : ℝ) - 1) ≠ 0 := by rw [hc1] at hn1; intro h; apply hn1; rw [h]; norm_num
  have hb : (2 * (n : ℝ) + 1) ≠ 0 := by rw [hc2] at hn2; intro h; apply hn2; rw [h]; norm_num
  have ha' : (-1 + (n : ℝ) * 2) ≠ 0 := by intro h; apply ha; linarith
  have hb' : (1 + (n : ℝ) * 2) ≠ 0 := by intro h; apply hb; linarith
  rw [hc1, hc2, hc3]
  generalize Real.cos (n * x) = c
  rw [show 2 * (n : ℝ) + 1 = (2 * n - 1) + 2 by ring] at hb ⊢
  generalize 2 * (n : ℝ) - 1 = a at ha hb ⊢
  field_simp
  ring

-- The first three eigenvalues 1/(1 - 4n²) of the round tunnel.
example : (1 : ℚ) / (1 - 4 * 0 ^ 2) = 1 := by norm_num
example : (1 : ℚ) / (1 - 4 * 1 ^ 2) = -1 / 3 := by norm_num
example : (1 : ℚ) / (1 - 4 * 2 ^ 2) = -1 / 15 := by norm_num

-- Square tunnel, by hand. Balanced net outputs q = (100, 0, -100, 0) pass the test against
-- a = (1, 1, 1, 1); with the floor at -80 the sum is 20 W/m², an obstruction.
example : ![(1 : ℚ), 1, 1, 1] ⬝ᵥ ![100, 0, -100, 0] = 0 := by
  simp [dotProduct, Fin.sum_univ_four]
example : ![(1 : ℚ), 1, 1, 1] ⬝ᵥ ![100, 0, -80, 0] = 20 := by
  simp [dotProduct, Fin.sum_univ_four]; norm_num

-- Square tunnel, painted walls (ρ = 4/5): absorbed equals emitted, (1/5) · mean = 100/4,
-- so the mean radiosity is 125 W/m².
example : ((100 : ℚ) / 4) / (1 - 4 / 5) = 125 := by norm_num

/-- The 4 m by 3 m corridor's view factors (floor, right wall, ceiling, left wall), from the
crossed-strings rule with diagonal 5 m. -/
def corridorF : Matrix (Fin 4) (Fin 4) ℚ :=
  !![0, 1/4, 1/2, 1/4;
     1/3, 0, 1/3, 1/3;
     1/2, 1/4, 0, 1/4;
     1/3, 1/3, 1/3, 0]

-- The corridor's own null vector is all 1s: every row of F sums to 1.
example : (1 - corridorF).mulVec ![1, 1, 1, 1] = 0 := by
  ext i; fin_cases i <;>
    simp [corridorF, Matrix.mulVec, dotProduct, Fin.sum_univ_four, Matrix.one_apply] <;> norm_num

-- The adjoint's null vector is the wall widths (4, 3, 4, 3), not all 1s.
example : (1 - corridorF).transpose.mulVec ![4, 3, 4, 3] = 0 := by
  ext i; fin_cases i <;>
    simp [corridorF, Matrix.mulVec, dotProduct, Fin.sum_univ_four, Matrix.one_apply] <;> norm_num

-- q = (0, -100, 100, 0): the wrong test (plain sum) gives 0, the true test gives 100 W/m.
example : ![(1 : ℚ), 1, 1, 1] ⬝ᵥ ![0, -100, 100, 0] = 0 := by
  simp [dotProduct, Fin.sum_univ_four]
example : ![(4 : ℚ), 3, 4, 3] ⬝ᵥ ![0, -100, 100, 0] = 100 := by
  simp [dotProduct, Fin.sum_univ_four]; norm_num

#print axioms fredholm_alternative
#print axioms matrix_fredholm_alternative
#print axioms round_tunnel_eigenvalue
