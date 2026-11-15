-- Compact and symmetric: a compact self-adjoint operator on a Hilbert space has an orthonormal basis of eigenvectors with real eigenvalues dying away to zero, a positive one has the top of its Rayleigh ratio as its largest eigenvalue, and the string's sag operator has the modes √2 sin(nπx) with eigenvalues 1/(n²π²).
import Mathlib.Analysis.InnerProductSpace.Spectrum
import Mathlib.Analysis.InnerProductSpace.Rayleigh
import Mathlib.Analysis.InnerProductSpace.l2Space
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Tactic.NormNum

open scoped InnerProductSpace Topology
open Filter Real

universe u

/-- The spectral theorem for compact self-adjoint operators. Let `E` be a Hilbert space (complete,
with real or complex scalars `𝕜`) and `K` a bounded operator on it that is compact and
self-adjoint. Then `E` has an orthonormal basis `e i` made of eigenvectors of `K`
(`K (e i) = μ i • e i`; the ones with `μ i = 0` are a basis of the null space `ker K`). Every
eigenvalue `μ i` is real, the eigenvalues die away to zero (for each `ε > 0` only finitely many
have `|μ i| ≥ ε`), and `K f = ∑ μ i ⟨e i, f⟩ e i` for every `f`. -/
theorem compact_self_adjoint_has_orthonormal_eigenbasis
    {𝕜 : Type*} {E : Type u} [RCLike 𝕜] [NormedAddCommGroup E] [InnerProductSpace 𝕜 E]
    [CompleteSpace E]
    (K : E →L[𝕜] E) (hK : IsCompactOperator K) (hsa : IsSelfAdjoint K) :
    ∃ (ι : Type u) (e : HilbertBasis ι 𝕜 E) (μ : ι → ℝ),
      (∀ i, K (e i) = (μ i : 𝕜) • e i) ∧
      Tendsto μ cofinite (𝓝 0) ∧
      ∀ f : E, HasSum (fun i => ((μ i : 𝕜) * ⟪e i, f⟫_𝕜) • e i) (K f) := by
  classical
  have hsym : (K : E →ₗ[𝕜] E).IsSymmetric := hsa.isSymmetric
  let P : Set (Set E) :=
    {s | Orthonormal 𝕜 (Subtype.val : s → E) ∧ ∀ v ∈ s, ∃ c : 𝕜, K v = c • v}
  obtain ⟨w, -, hwmax⟩ := zorn_subset_nonempty P (fun c hc cc _ => ⟨⋃₀ c,
      ⟨orthonormal_sUnion_of_directed cc.directedOn fun x xc => (hc xc).1,
       fun v hv => by
         obtain ⟨s, hs, hvs⟩ := Set.mem_sUnion.1 hv
         exact (hc hs).2 v hvs⟩,
      fun _ => Set.subset_sUnion_of_mem⟩) ∅ ⟨by simp, by simp⟩
  obtain ⟨hw_on, hw_eig⟩ := hwmax.prop
  have hinv : Submodule.span 𝕜 w ≤ (Submodule.span 𝕜 w).comap (K : E →ₗ[𝕜] E) := by
    refine Submodule.span_le.mpr fun v hv => ?_
    obtain ⟨c, hc⟩ := hw_eig v hv
    show K v ∈ Submodule.span 𝕜 w
    rw [hc]
    exact Submodule.smul_mem _ _ (Submodule.subset_span hv)
  set V := (Submodule.span 𝕜 w)ᗮ with hVdef
  have hVinv : ∀ x ∈ V, K x ∈ V := by
    intro x hx
    rw [Submodule.mem_orthogonal] at hx ⊢
    intro u hu
    have h := hsym u x
    simp only [ContinuousLinearMap.coe_coe] at h
    rw [← h]
    exact hx _ (hinv hu)
  have hVbot : V = ⊥ := by
    by_contra hV
    have hex : ∃ x ∈ V, x ≠ 0 ∧ ∃ c : 𝕜, K x = c • x := by
      by_contra! hne
      let S : V →L[𝕜] V := K.restrict hVinv
      have hSc : IsCompactOperator S := hK.restrict' hVinv
      have hSs : (S : V →ₗ[𝕜] V).IsSymmetric := hsym.restrict_invariant hVinv
      have hall : ∀ μ, Module.End.HasEigenvalue (S : Module.End 𝕜 V) μ → μ = 0 := by
        intro μ hμ
        obtain ⟨x, hx⟩ := hμ.exists_hasEigenvector
        exfalso
        refine hne x x.2 (by simpa using hx.2) μ ?_
        have := congrArg Subtype.val hx.apply_eq_smul
        simpa [S] using this
      have hS0 : S = 0 := (ContinuousLinearMap.eq_zero_of_forall_hasEigenvalue_eq_zero hSc hSs).1 hall
      obtain ⟨x, hxV, hx0⟩ := (Submodule.ne_bot_iff V).1 hV
      have hKx : K x = 0 := by
        have := congrArg (fun T : V →L[𝕜] V => ((T ⟨x, hxV⟩ : V) : E)) hS0
        simpa [S] using this
      exact hne x hxV hx0 0 (by simp [hKx])
    obtain ⟨x, hxV, hx0, c, hc⟩ := hex
    let y := ((‖x‖⁻¹ : ℝ) : 𝕜) • x
    have hy1 : ‖y‖ = 1 := by simp [y, norm_smul_inv_norm hx0]
    have hyV : y ∈ V := V.smul_mem _ hxV
    have hyc : K y = c • y := by simp only [y, map_smul, hc, smul_comm c]
    have h_end : ∀ a ∈ w, ⟪a, y⟫_𝕜 = 0 := fun a ha =>
      (Submodule.mem_orthogonal _ _).1 hyV a (Submodule.subset_span ha)
    have hins : insert y w ∈ P := by
      refine ⟨⟨?_, ?_⟩, ?_⟩
      · rintro ⟨a, ha'⟩
        rcases Set.eq_or_mem_of_mem_insert ha' with ha | ha
        · simp [ha, hy1]
        · exact hw_on.1 ⟨a, ha⟩
      · rintro ⟨a, ha'⟩ ⟨b, hb'⟩ hab'
        rcases Set.eq_or_mem_of_mem_insert ha' with ha | ha <;>
          rcases Set.eq_or_mem_of_mem_insert hb' with hb | hb
        · exact absurd (Subtype.ext (ha.trans hb.symm)) hab'
        · simp only
          rw [ha, inner_eq_zero_symm]
          exact h_end b hb
        · simp only
          rw [hb]
          exact h_end a ha
        · have : (⟨a, ha⟩ : w) ≠ ⟨b, hb⟩ := fun h => hab' (Subtype.ext (show a = b from congrArg Subtype.val h))
          exact hw_on.2 this
      · intro v hv
        rcases Set.eq_or_mem_of_mem_insert hv with h | h
        · exact ⟨c, h ▸ hyc⟩
        · exact hw_eig v h
    have hyw : y ∈ w := hwmax.2 hins (Set.subset_insert y w) (Set.mem_insert y w)
    have : y ∈ Submodule.span 𝕜 w ⊓ V := ⟨Submodule.subset_span hyw, hyV⟩
    rw [(Submodule.span 𝕜 w).inf_orthogonal_eq_bot] at this
    have : y = 0 := by simpa using this
    simp [this] at hy1
  let e : HilbertBasis w 𝕜 E :=
    HilbertBasis.mkOfOrthogonalEqBot hw_on (by simpa [Subtype.range_coe] using hVbot)
  have he : ∀ i, e i = (i : E) := fun i => by simp [e]
  let c : w → 𝕜 := fun i => Classical.choose (hw_eig i i.2)
  have hc : ∀ i : w, K (i : E) = c i • (i : E) := fun i => Classical.choose_spec (hw_eig i i.2)
  let μ : w → ℝ := fun i => RCLike.re (c i)
  have hμc : ∀ i, (μ i : 𝕜) = c i := by
    intro i
    have hev : Module.End.HasEigenvalue (K : Module.End 𝕜 E) (c i) :=
      Module.End.hasEigenvalue_of_hasEigenvector
        ⟨by simpa [Module.End.mem_eigenspace_iff] using hc i, hw_on.ne_zero i⟩
    exact RCLike.conj_eq_iff_re.1 (hsym.conj_eigenvalue_eq_self hev)
  have hμ : ∀ i, K (e i) = (μ i : 𝕜) • e i := fun i => by rw [he, hμc, hc]
  refine ⟨w, e, μ, hμ, ?_, ?_⟩
  · have key : ∀ i j, i ≠ j → |μ i| ≤ dist (K (e i)) (K (e j)) := by
      intro i j hij
      have h1 : ⟪e i, K (e i) - K (e j)⟫_𝕜 = (μ i : 𝕜) := by
        rw [inner_sub_right, hμ i, hμ j, inner_smul_right, inner_smul_right,
          e.orthonormal.2 hij, inner_self_eq_norm_sq_to_K, e.orthonormal.1 i]
        simp
      calc |μ i| = ‖(μ i : 𝕜)‖ := (RCLike.norm_ofReal _).symm
        _ = ‖⟪e i, K (e i) - K (e j)⟫_𝕜‖ := by rw [h1]
        _ ≤ ‖e i‖ * ‖K (e i) - K (e j)‖ := norm_inner_le_norm _ _
        _ = dist (K (e i)) (K (e j)) := by rw [e.orthonormal.1 i, one_mul, dist_eq_norm]
    rw [Metric.tendsto_nhds]
    intro ε hε
    rw [Filter.eventually_cofinite]
    by_contra hinf
    let f := Set.Infinite.natEmbedding _ hinf
    obtain ⟨C, hC, hsub⟩ :=
      IsCompactOperator.image_closedBall_subset_compact (f := (K : E →ₗ[𝕜] E)) hK 1
    have hxC : ∀ n, K (e (f n)) ∈ C := fun n =>
      hsub ⟨e (f n), by simp [e.orthonormal.1], rfl⟩
    obtain ⟨a, -, φ, hφ, hlim⟩ := hC.tendsto_subseq hxC
    obtain ⟨N, hN⟩ := Metric.cauchySeq_iff'.1 hlim.cauchySeq ε hε
    have h1 := hN (N + 1) (by omega)
    have hne : ((f (φ (N + 1)) : w)) ≠ f (φ N) := by
      intro h
      have := f.injective (Subtype.ext h)
      exact absurd (hφ.injective this) (by omega)
    have h2 := key _ _ hne
    have h3 := (f (φ (N + 1))).2
    simp only [Set.mem_ofPred_eq, not_lt, Real.dist_0_eq_abs] at h3
    simp only [Function.comp] at h1
    linarith
  · intro f
    have := (e.hasSum_repr f).mapL K
    convert this using 1
    funext i
    simp only [map_smul, hμ i, smul_smul, HilbertBasis.repr_apply_apply]
    rw [mul_comm]

/-- The top of the Rayleigh ratio is the largest eigenvalue. Let `K` be a compact, self-adjoint,
positive (`⟨f, K f⟩ ≥ 0` for every `f`) operator on a nonzero Hilbert space, and let `M` be the
top of the ratio `R(f) = ⟨f, K f⟩ / ⟨f, f⟩` over nonzero `f`. Then the top is reached by some
nonzero load, `M` is an eigenvalue of `K`, and every eigenvalue of `K` has size at most `M`. -/
theorem rayleigh_top_is_largest_eigenvalue
    {𝕜 E : Type*} [RCLike 𝕜] [NormedAddCommGroup E] [InnerProductSpace 𝕜 E] [CompleteSpace E]
    [Nontrivial E]
    (K : E →L[𝕜] E) (hK : IsCompactOperator K) (hsa : IsSelfAdjoint K)
    (hpos : ∀ f : E, 0 ≤ RCLike.re ⟪f, K f⟫_𝕜) :
    (∃ e : E, e ≠ 0 ∧ K.rayleighQuotient e = ⨆ f : {f : E // f ≠ 0}, K.rayleighQuotient f) ∧
    Module.End.HasEigenvalue (K : Module.End 𝕜 E)
      ((⨆ f : {f : E // f ≠ 0}, K.rayleighQuotient f : ℝ) : 𝕜) ∧
    ∀ μ : 𝕜, Module.End.HasEigenvalue (K : Module.End 𝕜 E) μ →
      ‖μ‖ ≤ ⨆ f : {f : E // f ≠ 0}, K.rayleighQuotient f := by
  have hsym : (K : E →ₗ[𝕜] E).IsSymmetric := hsa.isSymmetric
  obtain ⟨y0, hy0⟩ := exists_ne (0 : E)
  have : Nonempty {f : E // f ≠ 0} := ⟨⟨y0, hy0⟩⟩
  have hR0 : ∀ x, 0 ≤ K.rayleighQuotient x := by
    intro x
    apply div_nonneg _ (by positivity)
    rw [ContinuousLinearMap.reApplyInnerSelf_apply, inner_re_symm]
    exact hpos x
  have hbdd : BddAbove (Set.range fun x : E => K.rayleighQuotient x) :=
    ⟨‖K‖, fun _ ⟨y, h⟩ => h ▸ (le_abs_self _).trans (K.rayleighQuotient_le_norm y)⟩
  have hbdd' : BddAbove (Set.range fun f : {f : E // f ≠ 0} => K.rayleighQuotient f) :=
    ⟨‖K‖, fun _ ⟨y, h⟩ => h ▸ (le_abs_self _).trans (K.rayleighQuotient_le_norm y)⟩
  have hMnorm : (⨆ f : {f : E // f ≠ 0}, K.rayleighQuotient f) = ‖K‖ := by
    rw [K.norm_eq_iSup_rayleighQuotient hsym]
    simp_rw [abs_of_nonneg (hR0 _)]
    apply le_antisymm
    · exact ciSup_le fun f => le_ciSup hbdd (f : E)
    · refine ciSup_le fun x => ?_
      by_cases hx : x = 0
      · rw [hx, K.rayleighQuotient_apply_zero]
        exact (hR0 y0).trans (le_ciSup hbdd' ⟨y0, hy0⟩)
      · exact le_ciSup hbdd' ⟨x, hx⟩
  rw [hMnorm]
  have hev : Module.End.HasEigenvalue (K : Module.End 𝕜 E) ((‖K‖ : ℝ) : 𝕜) := by
    by_cases hK0 : K = 0
    · subst hK0
      simp only [norm_zero, RCLike.ofReal_zero]
      exact Module.End.hasEigenvalue_of_hasEigenvector
        ⟨by simp, hy0⟩
    · have hn : ((‖K‖ : ℝ) : 𝕜) ≠ 0 := by simpa using hK0
      rw [hK.hasEigenvalue_iff_mem_spectrum hn]
      by_contra hns
      have hres : algebraMap ℝ 𝕜 ‖K‖ ∈ resolventSet 𝕜 K := by
        rw [spectrum.mem_resolventSet_iff, ← spectrum.notMem_iff]
        simpa [RCLike.algebraMap_eq_ofReal] using hns
      obtain ⟨ε, hε, hle⟩ := K.rayleighQuotient_le_of_norm_mem_resolventSet hres
      have : (⨆ f : {f : E // f ≠ 0}, K.rayleighQuotient f) ≤ ‖K‖ - ε :=
        ciSup_le fun f => hle f
      linarith
  refine ⟨?_, hev, ?_⟩
  · obtain ⟨v, hv⟩ := hev.exists_hasEigenvector
    refine ⟨v, hv.2, ?_⟩
    have hv0 : ‖v‖ ≠ 0 := norm_ne_zero_iff.2 hv.2
    rw [ContinuousLinearMap.rayleighQuotient, ContinuousLinearMap.reApplyInnerSelf_apply]
    have : K v = ((‖K‖ : ℝ) : 𝕜) • v := hv.apply_eq_smul
    rw [this, inner_smul_real_left, RCLike.smul_re, inner_self_eq_norm_sq]
    field_simp
  · intro μ hμ
    obtain ⟨v, hv⟩ := hμ.exists_hasEigenvector
    have hvpos : 0 < ‖v‖ := norm_pos_iff.2 hv.2
    have h1 : ‖K v‖ = ‖μ‖ * ‖v‖ := by
      have : K v = μ • v := hv.apply_eq_smul
      rw [this, norm_smul]
    have h2 := K.le_opNorm v
    rw [h1] at h2
    exact le_of_mul_le_mul_right h2 hvpos

/-- The string's modes. For the sag operator of a 1 m string,
`(K f)(x) = ∫₀¹ min(x, y) (1 - max(x, y)) f(y) dy`, the n-th mode `e_n(x) = √2 sin(nπx)` has size 1
in `L²(0, 1)` and is an eigenfunction with eigenvalue `1/(n²π²)`, for every `n ≥ 1` and every
point `x` of the string. -/
theorem string_modes_are_unit_eigenfunctions (n : ℕ) (hn : 1 ≤ n) :
    (∫ y in (0 : ℝ)..1, (√2 * sin (n * π * y)) ^ 2) = 1 ∧
    ∀ x ∈ Set.Icc (0 : ℝ) 1,
      (∫ y in (0 : ℝ)..1, min x y * (1 - max x y) * (√2 * sin (n * π * y))) =
        1 / (n ^ 2 * π ^ 2) * (√2 * sin (n * π * x)) := by
  have hk : (n : ℝ) * π ≠ 0 := by
    have : (1 : ℝ) ≤ n := by exact_mod_cast hn
    positivity
  have hsk : sin (n * π) = 0 := Real.sin_nat_mul_pi n
  set k : ℝ := n * π with hkdef
  have h2 : (√2) ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  -- derivatives of the basic pieces
  have dsin : ∀ y, HasDerivAt (fun y => sin (k * y)) (k * cos (k * y)) y := fun y => by
    refine (((hasDerivAt_id y).const_mul k).sin).congr_deriv ?_
    simp only [id]; ring
  have dcos : ∀ y, HasDerivAt (fun y => cos (k * y)) (-(k * sin (k * y))) y := fun y => by
    refine (((hasDerivAt_id y).const_mul k).cos).congr_deriv ?_
    simp only [id]; ring
  constructor
  · have hF : ∀ y, HasDerivAt (fun y => y - sin (k * y) * cos (k * y) / k)
        ((√2 * sin (k * y)) ^ 2) y := fun y => by
      refine ((hasDerivAt_id y).sub (((dsin y).mul (dcos y)).div_const k)).congr_deriv ?_
      field_simp
      rw [h2]
      nlinarith [sin_sq_add_cos_sq (k * y)]
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun y _ => hF y)
      (by apply Continuous.intervalIntegrable; fun_prop)]
    simp [hsk]
  · intro x hx
    have hcont : Continuous fun y : ℝ => min x y * (1 - max x y) * (√2 * sin (k * y)) := by
      fun_prop
    rw [← intervalIntegral.integral_add_adjacent_intervals (b := x)
      (hcont.intervalIntegrable _ _) (hcont.intervalIntegrable _ _)]
    have e1 : (∫ y in (0 : ℝ)..x, min x y * (1 - max x y) * (√2 * sin (k * y))) =
        ∫ y in (0 : ℝ)..x, (1 - x) * √2 * (y * sin (k * y)) := by
      apply intervalIntegral.integral_congr
      intro y hy
      rw [Set.uIcc_of_le hx.1] at hy
      simp only [min_eq_right hy.2, max_eq_left hy.2]
      ring
    have e2 : (∫ y in x..1, min x y * (1 - max x y) * (√2 * sin (k * y))) =
        ∫ y in x..1, x * √2 * ((1 - y) * sin (k * y)) := by
      apply intervalIntegral.integral_congr
      intro y hy
      rw [Set.uIcc_of_le hx.2] at hy
      simp only [min_eq_left hy.1, max_eq_right hy.1]
      ring
    have hG1 : ∀ y, HasDerivAt (fun y => (1 - x) * √2 * (-(y * cos (k * y)) / k + sin (k * y) / k ^ 2))
        ((1 - x) * √2 * (y * sin (k * y))) y := fun y => by
      refine (((((hasDerivAt_id y).mul (dcos y)).neg.div_const k).add ((dsin y).div_const (k ^ 2))).const_mul ((1 - x) * √2)).congr_deriv ?_
      simp only [id]
      field_simp
      ring
    have hG2 : ∀ y, HasDerivAt (fun y => x * √2 * (-((1 - y) * cos (k * y)) / k - sin (k * y) / k ^ 2))
        (x * √2 * ((1 - y) * sin (k * y))) y := fun y => by
      refine ((((((hasDerivAt_id y).const_sub 1).mul (dcos y)).neg.div_const k).sub ((dsin y).div_const (k ^ 2))).const_mul (x * √2)).congr_deriv ?_
      simp only [id]
      field_simp
      ring
    rw [e1, e2, intervalIntegral.integral_eq_sub_of_hasDerivAt (fun y _ => hG1 y)
      (by apply Continuous.intervalIntegrable; fun_prop),
      intervalIntegral.integral_eq_sub_of_hasDerivAt (fun y _ => hG2 y)
      (by apply Continuous.intervalIntegrable; fun_prop)]
    simp only [mul_one, mul_zero, hsk, sin_zero, cos_zero]
    rw [hkdef] at *
    field_simp
    ring


/- The card's exact worked numbers. -/

-- Push 1 N at the middle at 100 N tension: k(1/2, 1/2) = 1/4, so the middle moves 2.5 mm.
example : min (1 / 2 : ℚ) (1 / 2) * (1 - max (1 / 2 : ℚ) (1 / 2)) = 1 / 4 := by norm_num
example : 1000 * (min (1 / 2 : ℚ) (1 / 2) * (1 - max (1 / 2 : ℚ) (1 / 2))) / 100 = 5 / 2 := by
  norm_num
-- Uniform load of 1 N/m: the middle sags by (1/2)(1/2)/2 per newton of tension, 1.25 mm at 100 N.
example : 1000 * ((1 / 2 : ℚ) * (1 - 1 / 2) / 2) / 100 = 5 / 4 := by norm_num
-- Hand steps for f = x(1 - x), with K f = (x - 2x³ + x⁴)/12:
-- the bottom of the ratio, ∫ f² = 1/30.
example : (∫ x in (0 : ℝ)..1, (x * (1 - x)) ^ 2) = 1 / 30 := by
  have hF : ∀ x : ℝ, HasDerivAt (fun x => x ^ 3 / 3 - x ^ 4 / 2 + x ^ 5 / 5) ((x * (1 - x)) ^ 2) x :=
    fun x => by
      have := (((hasDerivAt_pow 3 x).div_const 3).sub ((hasDerivAt_pow 4 x).div_const 2)).add
        ((hasDerivAt_pow 5 x).div_const 5)
      convert this using 1
      push_cast
      ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun y _ => hF y)
    (by apply Continuous.intervalIntegrable; fun_prop)]
  norm_num
-- the top of the ratio, ∫ f · K f = 17/5040.
example : (∫ x in (0 : ℝ)..1, x * (1 - x) * ((x - 2 * x ^ 3 + x ^ 4) / 12)) = 17 / 5040 := by
  -- x(1-x)(x - 2x³ + x⁴)/12 = (x² - x³ - 2x⁴ + 3x⁵ - x⁶)/12
  have hF : ∀ x : ℝ, HasDerivAt
      (fun x => (x ^ 3 / 3 - x ^ 4 / 4 - 2 * x ^ 5 / 5 + x ^ 6 / 2 - x ^ 7 / 7) / 12)
      (x * (1 - x) * ((x - 2 * x ^ 3 + x ^ 4) / 12)) x :=
    fun x => by
      have := (((((hasDerivAt_pow 3 x).div_const 3).sub ((hasDerivAt_pow 4 x).div_const 4)).sub
        (((hasDerivAt_pow 5 x).const_mul 2).div_const 5)).add
        ((hasDerivAt_pow 6 x).div_const 2)).sub ((hasDerivAt_pow 7 x).div_const 7) |>.div_const 12
      convert this using 1
      push_cast
      ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun y _ => hF y)
    (by apply Continuous.intervalIntegrable; fun_prop)]
  norm_num
-- the ratio, 17/5040 × 30 = 17/168.
example : (17 / 5040 : ℚ) / (1 / 30) = 17 / 168 := by norm_num
-- The trial ratios climb toward 1/π²: R(1) = 1/12 < 17/168 < 691/6820.
example : (1 / 12 : ℚ) < 17 / 168 ∧ (17 / 168 : ℚ) < 691 / 6820 := by norm_num
-- The trace: the eigenvalues add up to ∫₀¹ x(1 - x) dx = 1/6.
example : (∫ x in (0 : ℝ)..1, x * (1 - x)) = 1 / 6 := by
  have hF : ∀ x : ℝ, HasDerivAt (fun x => x ^ 2 / 2 - x ^ 3 / 3) (x * (1 - x)) x :=
    fun x => by
      have := ((hasDerivAt_pow 2 x).div_const 2).sub ((hasDerivAt_pow 3 x).div_const 3)
      convert this using 1
      push_cast
      ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun y _ => hF y)
    (by apply Continuous.intervalIntegrable; fun_prop)]
  norm_num

#print axioms compact_self_adjoint_has_orthonormal_eigenbasis
#print axioms rayleigh_top_is_largest_eigenvalue
#print axioms string_modes_are_unit_eigenfunctions
