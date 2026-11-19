-- Partition of unity: bumps divided by their total are smooth weights adding to 1, the six globe bumps cover the sphere, and stitching bump-scaled charts gives a smooth embedding of a compact manifold into flat space.
import Mathlib.Geometry.Manifold.PartitionOfUnity
import Mathlib.Analysis.SpecialFunctions.Exp

open Function Set Topology
open scoped Manifold ContDiff

/-- The one-sided smooth ramp of the card: `f(s) = e^(-1/s^2)` for `s > 0`, and `0` for `s ≤ 0`. -/
noncomputable def ramp (s : ℝ) : ℝ := if 0 < s then Real.exp (-1 / s ^ 2) else 0

/-- The ramp is never negative. -/
theorem ramp_nonneg (s : ℝ) : 0 ≤ ramp s := by
  unfold ramp; split_ifs <;> positivity

/-- The ramp is positive for positive input. -/
theorem ramp_pos {s : ℝ} (hs : 0 < s) : 0 < ramp s := by
  unfold ramp; simp only [hs, ↓reduceIte]; positivity

/-- A sheet's bump is positive once the coordinate passes half the radius. -/
theorem ramp_sheet_pos {R t : ℝ} (hR : 0 < R) (ht : R / 2 < t) :
    0 < ramp ((t / R - 1 / 2) / (1 / 10)) := by
  apply ramp_pos
  have : 1 / 2 < t / R := by rw [lt_div_iff₀ hR]; linarith
  exact div_pos (by linarith) (by norm_num)

/-- **Gluing charts into flat space.** Let `M` be a compact smooth manifold (Hausdorff and second
countable) with finitely many charts `x_i` (the chart at `c i`, on its patch `U_i`), and smooth,
never-negative bumps `ψ_i`, each with support inside its own chart's patch, whose positive sets
cover `M`. Then the stitched map `F = (ψ_1 x_1, ψ_1, …, ψ_k x_k, ψ_k)`, with `k(n + 1)` coordinates,
is smooth, one-to-one, has a one-to-one differential at every point, and is a faithful copy
(a closed embedding): a smooth embedding of `M` into flat space. -/
theorem stitched_charts_embed_compact_manifold
    {ι : Type*} [Fintype ι]
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E]
    {H : Type*} [TopologicalSpace H] (I : ModelWithCorners ℝ E H)
    {M : Type*} [TopologicalSpace M] [ChartedSpace H M] [IsManifold I ∞ M]
    [T2Space M] [SecondCountableTopology M] [CompactSpace M]
    (c : ι → M) (ψ : ι → M → ℝ)
    (hψ_smooth : ∀ i, ContMDiff I 𝓘(ℝ) ∞ (ψ i))
    (hψ_nonneg : ∀ i x, 0 ≤ ψ i x)
    (hψ_supp : ∀ i, tsupport (ψ i) ⊆ (chartAt H (c i)).source)
    (hcover : ∀ x, ∃ i, 0 < ψ i x) :
    let F : M → (ι → E × ℝ) := fun x i => (ψ i x • extChartAt I (c i) x, ψ i x)
    ContMDiff I 𝓘(ℝ, ι → E × ℝ) ∞ F ∧ Injective F ∧
      (∀ x, Injective (mfderiv I 𝓘(ℝ, ι → E × ℝ) F x)) ∧ IsClosedEmbedding F := by
  intro F
  have hsupp : ∀ i x, ψ i x ≠ 0 → x ∈ (chartAt H (c i)).source :=
    fun i x h => hψ_supp i (subset_tsupport _ h)
  have hsmooth : ContMDiff I 𝓘(ℝ, ι → E × ℝ) ∞ F := by
    refine contMDiff_pi_module_iff.2 fun i => ContMDiff.prodMk_space ?_ (hψ_smooth i)
    refine contMDiff_of_tsupport fun x hx => ?_
    have hx' : x ∈ (chartAt H (c i)).source := hψ_supp i (tsupport_smul_subset_left _ _ hx)
    exact (hψ_smooth i x).smul (((contMDiffOn_extChartAt (I := I) (x := c i)) x hx').contMDiffAt
      ((chartAt H (c i)).open_source.mem_nhds hx'))
  have hinj : Injective F := by
    intro x y h
    obtain ⟨i, hi⟩ := hcover x
    have h' := congr_fun h i
    simp only [F, Prod.mk.injEq] at h'
    obtain ⟨h1, h2⟩ := h'
    rw [← h2] at h1
    have hx := hsupp i x hi.ne'
    have hy := hsupp i y (h2 ▸ hi.ne')
    have h3 := smul_right_injective E hi.ne' h1
    exact (extChartAt I (c i)).injOn (by simpa using hx) (by simpa using hy) h3
  have hmd : ∀ x, Injective (mfderiv I 𝓘(ℝ, ι → E × ℝ) F x) := by
    intro x
    obtain ⟨i, hi⟩ := hcover x
    have hx : x ∈ (chartAt H (c i)).source := hsupp i x hi.ne'
    let g : (ι → E × ℝ) → E := fun z => (z i).2⁻¹ • (z i).1
    have hgd : DifferentiableAt ℝ g (F x) := by
      have h0 : (F x i).2 ≠ 0 := hi.ne'
      have hl : DifferentiableAt ℝ (fun z : ι → E × ℝ => (z i).2) (F x) := by fun_prop
      have hr : DifferentiableAt ℝ (fun z : ι → E × ℝ => (z i).1) (F x) := by fun_prop
      exact (hl.inv h0).smul hr
    have hF := (hsmooth.mdifferentiableAt (x := x) (by simp)).hasMFDerivAt
    have hcomp := hgd.hasFDerivAt.hasMFDerivAt.comp x hF
    have heq : (g ∘ F) =ᶠ[𝓝 x] extChartAt I (c i) := by
      have hne : ∀ᶠ y in 𝓝 x, ψ i y ≠ 0 :=
        (hψ_smooth i).continuous.continuousAt.eventually_ne hi.ne'
      filter_upwards [hne] with y hy
      simp [g, F, smul_smul, inv_mul_cancel₀ hy]
    have h2 := hasMFDerivAt_unique (hcomp.congr_of_eventuallyEq heq.symm)
      (hasMFDerivAt_extChartAt hx)
    have hk := (mdifferentiable_chart (I := I) (c i)).ker_mfderiv_eq_bot hx
    have hker : (mfderiv I 𝓘(ℝ, ι → E × ℝ) F x).ker = ⊥ := by
      apply bot_unique
      rw [← hk]
      intro v hv
      have hv' : (mfderiv I 𝓘(ℝ, ι → E × ℝ) F x) v = 0 := hv
      have h3 := congrArg (fun L => L v) h2
      simp only [ContinuousLinearMap.comp_apply] at h3
      show (mfderiv I I (chartAt H (c i)) x) v = 0
      have h4 : (fderiv ℝ g (F x)).comp (mfderiv I 𝓘(ℝ, ι → E × ℝ) F x) v = 0 := by
        change fderiv ℝ g (F x) ((mfderiv I 𝓘(ℝ, ι → E × ℝ) F x) v) = 0
        rw [hv']
        exact (fderiv ℝ g (F x)).map_zero
      erw [h4] at h3
      exact h3.symm.trans rfl
    exact LinearMap.ker_eq_bot.1 hker
  exact ⟨hsmooth, hinj, hmd, hsmooth.continuous.isClosedEmbedding hinj⟩

/-- **Bumps divided by their total form a partition of unity.** If finitely many smooth,
never-negative bumps `ψ_i`, each with support inside its own chart's patch, have positive sets
covering the manifold, then the weights `ρ_i = ψ_i / (ψ_1 + … + ψ_k)` are smooth, never negative,
each zero outside its own chart's patch (support inside the patch), and add to 1 at every point. -/
theorem bumps_over_total_are_partition_of_unity
    {ι : Type*} [Fintype ι]
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {H : Type*} [TopologicalSpace H] (I : ModelWithCorners ℝ E H)
    {M : Type*} [TopologicalSpace M] [ChartedSpace H M] [IsManifold I ∞ M]
    (c : ι → M) (ψ : ι → M → ℝ)
    (hψ_smooth : ∀ i, ContMDiff I 𝓘(ℝ) ∞ (ψ i))
    (hψ_nonneg : ∀ i x, 0 ≤ ψ i x)
    (hψ_supp : ∀ i, tsupport (ψ i) ⊆ (chartAt H (c i)).source)
    (hcover : ∀ x, ∃ i, 0 < ψ i x) :
    let ρ : ι → M → ℝ := fun i x => ψ i x / ∑ j, ψ j x
    (∀ i, ContMDiff I 𝓘(ℝ) ∞ (ρ i)) ∧ (∀ i x, 0 ≤ ρ i x) ∧
      (∀ i, tsupport (ρ i) ⊆ (chartAt H (c i)).source) ∧ (∀ x, ∑ i, ρ i x = 1) := by
  intro ρ
  have hpos : ∀ x, 0 < ∑ j, ψ j x := fun x => by
    obtain ⟨i, hi⟩ := hcover x
    exact lt_of_lt_of_le hi
      (Finset.single_le_sum (fun j _ => hψ_nonneg j x) (Finset.mem_univ i))
  have hsum : ContMDiff I 𝓘(ℝ) ∞ (fun x => ∑ j, ψ j x) :=
    contMDiff_finsetSum (fun j _ => hψ_smooth j)
  refine ⟨fun i => (hψ_smooth i).div₀ hsum (fun x => (hpos x).ne'),
    fun i x => div_nonneg (hψ_nonneg i x) (hpos x).le, fun i => ?_, fun x => ?_⟩
  · refine subset_trans (closure_mono ?_) (hψ_supp i)
    intro x hx
    simp only [mem_support] at hx ⊢
    intro h
    apply hx
    simp [ρ, h]
  · simp only [ρ]
    rw [← Finset.sum_div, div_self (hpos x).ne']

/-- **The six globe bumps cover the globe.** On the sphere `X² + Y² + Z² = R²` of radius `R > 0`,
the six sheets' bumps `f((t - 1/2)/(1/10))`, where `t` is `Z/R`, `-Z/R`, `X/R`, `-X/R`, `Y/R`,
`-Y/R` (North, South, Greenwich, date line, East, West), have a positive total at every point,
so dividing by that total always works. -/
theorem six_globe_bumps_cover_sphere (R X Y Z : ℝ) (hR : 0 < R)
    (hsphere : X ^ 2 + Y ^ 2 + Z ^ 2 = R ^ 2) :
    0 < (([Z, -Z, X, -X, Y, -Y] : List ℝ).map fun t => ramp ((t / R - 1 / 2) / (1 / 10))).sum := by
  simp only [List.map_cons, List.map_nil, List.sum_cons, List.sum_nil]
  have key : R / 2 < Z ∨ R / 2 < -Z ∨ R / 2 < X ∨ R / 2 < -X ∨ R / 2 < Y ∨ R / 2 < -Y := by
    by_contra h
    push Not at h
    obtain ⟨h1, h2, h3, h4, h5, h6⟩ := h
    nlinarith [mul_nonneg (sub_nonneg.2 h1) (sub_nonneg.2 (show -Z ≤ R / 2 from h2)),
      mul_nonneg (sub_nonneg.2 h3) (sub_nonneg.2 (show -X ≤ R / 2 from h4)),
      mul_nonneg (sub_nonneg.2 h5) (sub_nonneg.2 (show -Y ≤ R / 2 from h6))]
  have a1 := ramp_nonneg ((Z / R - 1 / 2) / (1 / 10))
  have a2 := ramp_nonneg ((-Z / R - 1 / 2) / (1 / 10))
  have a3 := ramp_nonneg ((X / R - 1 / 2) / (1 / 10))
  have a4 := ramp_nonneg ((-X / R - 1 / 2) / (1 / 10))
  have a5 := ramp_nonneg ((Y / R - 1 / 2) / (1 / 10))
  have a6 := ramp_nonneg ((-Y / R - 1 / 2) / (1 / 10))
  rcases key with h | h | h | h | h | h <;> have := ramp_sheet_pos hR h <;> linarith

-- The stitched map for the globe: 6 sheets, each with 2 chart coordinates and 1 bump entry.
example : 6 * (2 + 1) = 18 := by norm_num
-- Whitney's bound 2n for the globe (n = 2).
example : 2 * 2 = 4 := by norm_num

#print axioms ramp_nonneg
#print axioms ramp_pos
#print axioms ramp_sheet_pos
#print axioms stitched_charts_embed_compact_manifold
#print axioms bumps_over_total_are_partition_of_unity
#print axioms six_globe_bumps_cover_sphere
