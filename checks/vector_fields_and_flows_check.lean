-- Vector field and its flow: a smooth vector field on a compact manifold without edge has exactly one integral curve through each point, it lasts for all time, and these curves form a flow on the globe.
import Mathlib.Geometry.Manifold.IntegralCurve.UniformTime
import Mathlib.Geometry.Manifold.Instances.Sphere

open Set
open scoped Manifold ContDiff

section Helpers

open Metric
open scoped Topology


variable
  {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
  {H : Type*} [TopologicalSpace H] {I : ModelWithCorners ℝ E H}
  {M : Type*} [TopologicalSpace M] [ChartedSpace H M] [IsManifold I 1 M]

set_option backward.isDefEq.respectTransparency false in
/-- Local existence with a uniform time: near each point, every start point has an integral
curve defined on one common interval `Ioo (-ε) ε`. -/
theorem vf_local_uniform_time [CompleteSpace E] [BoundarylessManifold I M]
    {v : (x : M) → TangentSpace I x}
    (hv : CMDiff 1 (fun x ↦ (⟨x, v x⟩ : TangentBundle I M))) (x₀ : M) :
    ∃ U ∈ 𝓝 x₀, ∃ ε > (0 : ℝ), ∀ x ∈ U,
      ∃ γ : ℝ → M, γ 0 = x ∧ IsMIntegralCurveOn γ v (Ioo (-ε) ε) := by
  have hx₀ : I.IsInteriorPoint x₀ := BoundarylessManifold.isInteriorPoint
  have hv' := hv x₀
  rw [contMDiffAt_iff] at hv'
  obtain ⟨_, hv'⟩ := hv'
  have hcd := (hv'.contDiffAt (range_mem_nhds_isInteriorPoint hx₀)).snd
  obtain ⟨ε, hε, a, r, L, K, hr, hpl⟩ := IsPicardLindelof.of_contDiffAt_one hcd
  obtain ⟨α, hα1, hα2⟩ := (hpl 0).exists_forall_mem_closedBall_eq_hasDerivWithinAt_continuousOn
  set y₀ := extChartAt I x₀ x₀ with hy₀
  have hS : closedBall y₀ r ×ˢ Icc (0 - ε) (0 + ε) ∈ 𝓝 (y₀, (0 : ℝ)) :=
    prod_mem_nhds (closedBall_mem_nhds _ hr) (Icc_mem_nhds (by linarith) (by linarith))
  have hcont : ContinuousAt α (y₀, 0) := hα2.continuousAt hS
  have hαy₀ : α (y₀, 0) = y₀ := (hα1 y₀ (mem_closedBall_self hr.le)).1
  have hint : interior (extChartAt I x₀).target ∈ 𝓝 (α (y₀, 0)) := by
    rw [hαy₀]
    exact isOpen_interior.mem_nhds (I.isInteriorPoint_iff.mp hx₀)
  have hpre : α ⁻¹' interior (extChartAt I x₀).target ∈ 𝓝 (y₀, (0 : ℝ)) :=
    hcont.preimage_mem_nhds hint
  obtain ⟨A, hA, B, hB, hAB⟩ := mem_nhds_prod_iff.mp hpre
  obtain ⟨ρ, hρ, hρA⟩ := Metric.mem_nhds_iff.mp hA
  obtain ⟨δ, hδ, hδB⟩ := Metric.mem_nhds_iff.mp hB
  refine ⟨(extChartAt I x₀).source ∩ extChartAt I x₀ ⁻¹' ball y₀ (min ρ r), ?_, min δ ε,
    lt_min hδ hε, ?_⟩
  · exact Filter.inter_mem (extChartAt_source_mem_nhds x₀)
      ((continuousAt_extChartAt x₀).preimage_mem_nhds (ball_mem_nhds _ (lt_min hρ hr)))
  rintro x ⟨hxs, hxb⟩
  set y := extChartAt I x₀ x with hy
  have hyr : y ∈ closedBall y₀ r :=
    ball_subset_closedBall (ball_subset_ball (min_le_right _ _) hxb)
  have hyA : y ∈ A := hρA (ball_subset_ball (min_le_left _ _) hxb)
  refine ⟨(extChartAt I x₀).symm ∘ (fun t ↦ α (y, t)), ?_, ?_⟩
  · have h0 : α (y, 0) = y := (hα1 y hyr).1
    rw [Function.comp_apply, h0]
    exact (extChartAt I x₀).left_inv hxs
  intro t ht
  have htδ : t ∈ Ioo (-δ) δ := ⟨lt_of_le_of_lt (neg_le_neg (min_le_left _ _)) ht.1,
    lt_of_lt_of_le ht.2 (min_le_left _ _)⟩
  have htε : t ∈ Ioo (0 - ε) (0 + ε) := by
    refine ⟨?_, ?_⟩
    · have := ht.1; have := min_le_right δ ε; linarith
    · have := ht.2; have := min_le_right δ ε; linarith
  have htB : t ∈ B := hδB (by rw [Real.ball_eq_Ioo]; simpa using htδ)
  have hf3 : α (y, t) ∈ interior (extChartAt I x₀).target := hAB (mk_mem_prod hyA htB)
  let xₜ : M := (extChartAt I x₀).symm (α (y, t))
  have h : HasDerivAt (fun t ↦ α (y, t)) (x := t) <|
      fderivWithin ℝ (extChartAt I x₀ ∘ (extChartAt I xₜ).symm)
      (range I) (extChartAt I xₜ xₜ) (v xₜ) :=
    ((hα1 y hyr).2 t (Ioo_subset_Icc_self htε)).hasDerivAt (Icc_mem_nhds htε.1 htε.2)
  rw [← tangentCoordChange_def] at h
  have hf3' := mem_of_mem_of_subset hf3 interior_subset
  have hft1 := mem_preimage.mp <|
    mem_of_mem_of_subset hf3' (extChartAt I x₀).target_subset_preimage_source
  have hft2 := mem_extChartAt_source (I := I) xₜ
  apply HasMFDerivAt.hasMFDerivWithinAt
  refine ⟨ContinuousAt.comp (f := fun s ↦ α (y, s)) (continuousAt_extChartAt_symm'' hf3') h.continuousAt,
    HasDerivWithinAt.hasFDerivWithinAt ?_⟩
  simp only [mfld_simps, hasDerivWithinAt_univ]
  change HasDerivAt ((extChartAt I xₜ ∘ (extChartAt I x₀).symm) ∘ (fun t ↦ α (y, t)))
    (v xₜ) t
  rw [← tangentCoordChange_self (I := I) (x := xₜ) (z := xₜ) (v := v xₜ) hft2,
    ← tangentCoordChange_comp (x := x₀) ⟨⟨hft2, hft1⟩, hft2⟩]
  apply HasFDerivAt.comp_hasDerivAt _ _ h
  apply HasFDerivWithinAt.hasFDerivAt (s := range I) _ <|
    mem_nhds_iff.mpr ⟨interior (extChartAt I x₀).target,
      subset_trans interior_subset (extChartAt_target_subset_range ..),
      isOpen_interior, hf3⟩
  rw [← (extChartAt I x₀).right_inv hf3']
  exact hasFDerivWithinAt_tangentCoordChange ⟨hft1, hft2⟩

/-- On a compact manifold with no edge, one time `ε > 0` works for every start point. -/
theorem vf_uniform_time_of_compact [CompleteSpace E] [BoundarylessManifold I M] [CompactSpace M]
    {v : (x : M) → TangentSpace I x}
    (hv : CMDiff 1 (fun x ↦ (⟨x, v x⟩ : TangentBundle I M))) :
    ∃ ε > (0 : ℝ), ∀ x : M, ∃ γ : ℝ → M, γ 0 = x ∧ IsMIntegralCurveOn γ v (Ioo (-ε) ε) := by
  let P : ℝ → M → Prop := fun δ x ↦
    ∃ γ : ℝ → M, γ 0 = x ∧ IsMIntegralCurveOn γ v (Ioo (-|δ|) |δ|)
  have hloc : ∀ x₀ ∈ (univ : Set M), ∀ᶠ z : ℝ × M in 𝓝 ((0 : ℝ), x₀), P z.1 z.2 := by
    intro x₀ _
    obtain ⟨U, hU, ε, hε, hx⟩ := vf_local_uniform_time hv x₀
    filter_upwards [prod_mem_nhds (ball_mem_nhds (0 : ℝ) hε) hU] with z hz
    obtain ⟨γ, h0, hγ⟩ := hx z.2 hz.2
    have hz1 : |z.1| < ε := by simpa [Real.dist_eq] using hz.1
    exact ⟨γ, h0, hγ.mono (Ioo_subset_Ioo (by linarith) hz1.le)⟩
  have hall := isCompact_univ.eventually_forall_of_forall_eventually hloc
  obtain ⟨ρ, hρ, hball⟩ := Metric.eventually_nhds_iff.mp hall
  have hρ2 : (0 : ℝ) < ρ / 2 := by positivity
  have hd : dist (ρ / 2) 0 < ρ := by
    rw [Real.dist_eq, sub_zero, abs_of_pos hρ2]; linarith
  refine ⟨ρ / 2, hρ2, fun x ↦ ?_⟩
  obtain ⟨γ, h0, hγ⟩ := hball hd x (mem_univ x)
  rw [abs_of_pos hρ2] at hγ
  exact ⟨γ, h0, hγ⟩

end Helpers

section General

variable
  {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E]
  {H : Type*} [TopologicalSpace H] {I : ModelWithCorners ℝ E H}
  {M : Type*} [TopologicalSpace M] [ChartedSpace H M] [IsManifold I ∞ M] [T2Space M]
  [BoundarylessManifold I M]

/-- Fundamental theorem on flows, global form: on a compact smooth manifold with no edge
(such as the sphere), a smooth vector field `v` has, through every point `x`, exactly one
integral curve `γ` with `γ 0 = x`, and that curve is defined for all time `t ∈ ℝ`. -/
theorem exists_unique_global_integral_curve_of_compact [CompactSpace M]
    {v : (x : M) → TangentSpace I x}
    (hv : CMDiff ∞ (fun x ↦ (⟨x, v x⟩ : TangentBundle I M))) (x : M) :
    ∃! γ : ℝ → M, γ 0 = x ∧ IsMIntegralCurve γ v := by
  have : CompleteSpace E := FiniteDimensional.complete ℝ E
  have hv1 : CMDiff 1 (fun x ↦ (⟨x, v x⟩ : TangentBundle I M)) := hv.of_le (by simp)
  obtain ⟨ε, hε, h⟩ := vf_uniform_time_of_compact hv1
  obtain ⟨γ, h0, hγ⟩ := exists_isMIntegralCurve_of_isMIntegralCurveOn hv1 hε h x
  refine ⟨γ, ⟨h0, hγ⟩, fun γ' ⟨h0', hγ'⟩ ↦ ?_⟩
  exact isMIntegralCurve_Ioo_eq_of_contMDiff_boundaryless (t₀ := 0) hv1 hγ' hγ
    (h0'.trans h0.symm)

/-- The flow: on a compact smooth manifold with no edge, a smooth vector field `v` has a flow
`φ : ℝ → M → M`. Each `t ↦ φ t p` is the integral curve through `p`, `φ 0` moves no point, and
waiting `t` and then `s` is the same as waiting `s + t`: `φ s (φ t p) = φ (s + t) p`. -/
theorem exists_flow_of_compact [CompactSpace M]
    {v : (x : M) → TangentSpace I x}
    (hv : CMDiff ∞ (fun x ↦ (⟨x, v x⟩ : TangentBundle I M))) :
    ∃ φ : ℝ → M → M, (∀ p, IsMIntegralCurve (fun t ↦ φ t p) v) ∧ (∀ p, φ 0 p = p) ∧
      ∀ s t p, φ s (φ t p) = φ (s + t) p := by
  have : CompleteSpace E := FiniteDimensional.complete ℝ E
  have hv1 : CMDiff 1 (fun x ↦ (⟨x, v x⟩ : TangentBundle I M)) := hv.of_le (by simp)
  choose γ hγ using fun p ↦ (exists_unique_global_integral_curve_of_compact hv p).exists
  refine ⟨fun t p ↦ γ p t, fun p ↦ (hγ p).2, fun p ↦ (hγ p).1, fun s t p ↦ ?_⟩
  have heq : γ (γ p t) = γ p ∘ (· + t) :=
    isMIntegralCurve_Ioo_eq_of_contMDiff_boundaryless (t₀ := 0) hv1 (hγ _).2
      ((hγ p).2.comp_add t) (by simp [(hγ _).1])
  simpa using congrFun heq s

end General

/-- On the globe, modelled as the unit sphere in three-dimensional space: every smooth vector
field `v` has, through every point `x`, exactly one integral curve with `γ 0 = x`, defined for
all time. -/
theorem sphere_exists_unique_global_integral_curve
    {v : (x : Metric.sphere (0 : EuclideanSpace ℝ (Fin 3)) 1) → TangentSpace (𝓡 2) x}
    (hv : ContMDiff (𝓡 2) (𝓡 2).tangent ∞ (fun x ↦ (⟨x, v x⟩ : TangentBundle (𝓡 2)
      (Metric.sphere (0 : EuclideanSpace ℝ (Fin 3)) 1))))
    (x : Metric.sphere (0 : EuclideanSpace ℝ (Fin 3)) 1) :
    ∃! γ : ℝ → Metric.sphere (0 : EuclideanSpace ℝ (Fin 3)) 1,
      γ 0 = x ∧ IsMIntegralCurve γ v := by
  exact exists_unique_global_integral_curve_of_compact hv x

-- Worked numbers by hand: 365 days at 7 km a day is 2555 km of arc.
example : (365 : ℕ) * 7 = 2555 := by norm_num
-- The start, 77°N, is 13° from the North Pole.
example : (90 : ℕ) - 77 = 13 := by norm_num

#print axioms vf_local_uniform_time
#print axioms vf_uniform_time_of_compact
#print axioms exists_unique_global_integral_curve_of_compact
#print axioms exists_flow_of_compact
#print axioms sphere_exists_unique_global_integral_curve
