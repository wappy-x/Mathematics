-- Regular surface: the tangent plane of a regular surface is the same for every regular patch through the point, graphs of smooth functions are regular surfaces, and the worked numbers for the stadium roof are exact.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.LinearAlgebra.Span.Basic
import Mathlib.Topology.Maps.Basic
import Mathlib.Tactic
import Mathlib.Analysis.Calculus.ContDiff.Operations
import Mathlib.Analysis.Calculus.FDeriv.Prod
import Mathlib.Analysis.Calculus.FDeriv.Equiv
import Mathlib.Analysis.Normed.Module.FiniteDimension

open scoped ContDiff Matrix

open Filter Topology Asymptotics in
theorem tangentCone_image_subset_range {r : ℝ × ℝ → Fin 3 → ℝ} {U : Set (ℝ × ℝ)}
    (hemb : Topology.IsEmbedding (U.domRestrict r)) {u₀ : ℝ × ℝ} (hu₀ : u₀ ∈ U)
    {L : ℝ × ℝ →L[ℝ] Fin 3 → ℝ} (hL : HasFDerivAt r L u₀) (hinj : Function.Injective L) :
    tangentConeAt ℝ (r '' U) (r u₀) ⊆ LinearMap.range (L : ℝ × ℝ →ₗ[ℝ] Fin 3 → ℝ) := by
  intro w hw
  obtain ⟨α, l, hl, c, d, hd0, hds, hcd⟩ := exists_fun_of_mem_tangentConeAt hw
  have key : ∀ n, ∃ v ∈ U, (r u₀ + d n ∈ r '' U → r v = r u₀ + d n) := by
    intro n
    by_cases hn : r u₀ + d n ∈ r '' U
    · obtain ⟨v, hv, hrv⟩ := hn
      exact ⟨v, hv, fun _ => hrv⟩
    · exact ⟨u₀, hu₀, fun h => absurd h hn⟩
  choose u hu hru using key
  have hrud : ∀ᶠ n in l, r (u n) = r u₀ + d n := hds.mono fun n hn => hru n hn
  -- u n → u₀
  have hr_tend : Tendsto (fun n => r (u n)) l (𝓝 (r u₀)) := by
    have : Tendsto (fun n => r u₀ + d n) l (𝓝 (r u₀)) := by
      simpa using tendsto_const_nhds.add hd0
    exact this.congr' (hrud.mono fun n hn => hn.symm)
  have hsub_tend : Tendsto (fun n => (⟨u n, hu n⟩ : U)) l (𝓝 ⟨u₀, hu₀⟩) := by
    rw [hemb.isInducing.tendsto_nhds_iff]
    simpa [Function.comp_def, Set.domRestrict] using hr_tend
  have hu_tend : Tendsto u l (𝓝 u₀) := by
    exact (continuous_subtype_val.tendsto _).comp hsub_tend
  -- antilipschitz bound
  obtain ⟨K, -, hK⟩ := (L : ℝ × ℝ →ₗ[ℝ] Fin 3 → ℝ).exists_antilipschitzWith
    (LinearMap.ker_eq_bot.mpr hinj)
  have hbound : ∀ z, ‖z‖ ≤ K * ‖L z‖ := fun z => by
    simpa using hK.le_mul_dist 0 z
  have A : (fun z => z - u₀) =O[𝓝 u₀] fun z => L (z - u₀) :=
    isBigO_iff.mpr ⟨K, Eventually.of_forall fun z => hbound (z - u₀)⟩
  have E0 : (fun z => r z - r u₀ - L (z - u₀)) =o[𝓝 u₀] fun z => z - u₀ := hL.isLittleO
  have Equiv : (fun z => r z - r u₀) ~[𝓝 u₀] fun z => L (z - u₀) := E0.trans_isBigO A
  have B : (fun z => z - u₀) =O[𝓝 u₀] fun z => r z - r u₀ := A.trans Equiv.isBigO_symm
  have Bn : (fun n => u n - u₀) =O[l] fun n => d n := by
    refine (B.comp_tendsto hu_tend).congr' (EventuallyEq.refl _ _) ?_
    exact hrud.mono fun n hn => by simp [hn]
  have En : (fun n => r (u n) - r u₀ - L (u n - u₀)) =o[l] fun n => u n - u₀ :=
    E0.comp_tendsto hu_tend
  have hcd_bdd : (fun n => c n • d n) =O[l] (fun _ => (1 : ℝ)) := hcd.isBigO_one ℝ
  have h1 : (fun n => c n • (r (u n) - r u₀ - L (u n - u₀))) =o[l] fun _ => (1 : ℝ) :=
    ((isBigO_refl c l).smul_isLittleO En).trans_isBigO
      (((isBigO_refl c l).smul Bn).trans hcd_bdd)
  have h2 : Tendsto (fun n => c n • (r (u n) - r u₀ - L (u n - u₀))) l (𝓝 0) :=
    isLittleO_one_iff ℝ |>.mp h1
  have h3 : Tendsto (fun n => L (c n • (u n - u₀))) l (𝓝 w) := by
    have := hcd.sub h2
    rw [sub_zero] at this
    refine this.congr' (hrud.mono fun n hn => ?_)
    simp only [map_smul, hn]
    rw [← smul_sub]; congr 1; abel
  have hclosed : IsClosed ((LinearMap.range (L : ℝ × ℝ →ₗ[ℝ] Fin 3 → ℝ)) : Set (Fin 3 → ℝ)) :=
    Submodule.closed_of_finiteDimensional _
  exact hclosed.mem_of_tendsto h3 (Eventually.of_forall fun n => ⟨_, rfl⟩)

theorem cross_switch_helper (r_u r_v : Fin 3 → ℝ) (u_σ v_σ u_τ v_τ : ℝ) :
    (u_σ • r_u + v_σ • r_v) ⨯₃ (u_τ • r_u + v_τ • r_v) =
      (u_σ * v_τ - u_τ * v_σ) • (r_u ⨯₃ r_v) := by
  simp only [LinearMap.map_add, LinearMap.map_smul, LinearMap.add_apply, LinearMap.smul_apply,
    cross_self, smul_zero, zero_add, add_zero, smul_smul]
  rw [← cross_anticomm r_u r_v, sub_smul, smul_neg]
  rw [mul_comm v_σ u_τ, mul_comm u_τ v_σ]
  abel

theorem planeMap_apply_eq (L : ℝ × ℝ →L[ℝ] Fin 3 → ℝ) (q : ℝ × ℝ) :
    L q = q.1 • L (1, 0) + q.2 • L (0, 1) := by
  have : q = q.1 • ((1 : ℝ), (0 : ℝ)) + q.2 • ((0 : ℝ), (1 : ℝ)) := by
    ext <;> simp
  conv_lhs => rw [this]
  rw [map_add, map_smul, map_smul]

theorem planeMap_injective_of_cross_ne_zero (L : ℝ × ℝ →L[ℝ] Fin 3 → ℝ)
    (h : L (1, 0) ⨯₃ L (0, 1) ≠ 0) : Function.Injective L := by
  intro q q' hqq
  have h0 : L (q - q') = 0 := by rw [map_sub, hqq, sub_self]
  rw [planeMap_apply_eq] at h0
  set a := (q - q').1 with ha
  set b := (q - q').2 with hb
  have hA : (a • L (1, 0) + b • L (0, 1)) ⨯₃ L (0, 1) = a • (L (1, 0) ⨯₃ L (0, 1)) := by
    simp [cross_self]
  have hB : L (1, 0) ⨯₃ (a • L (1, 0) + b • L (0, 1)) = b • (L (1, 0) ⨯₃ L (0, 1)) := by
    simp [cross_self]
  rw [h0, LinearMap.map_zero, LinearMap.zero_apply] at hA
  rw [h0, LinearMap.map_zero] at hB
  have ha0 : a = 0 := (smul_eq_zero.mp hA.symm).resolve_right h
  have hb0 : b = 0 := (smul_eq_zero.mp hB.symm).resolve_right h
  have : q - q' = 0 := Prod.ext ha0 hb0
  exact sub_eq_zero.mp this

theorem planeMap_range_eq_span (L : ℝ × ℝ →L[ℝ] Fin 3 → ℝ) :
    LinearMap.range (L : ℝ × ℝ →ₗ[ℝ] Fin 3 → ℝ) = Submodule.span ℝ {L (1, 0), L (0, 1)} := by
  apply le_antisymm
  · rintro _ ⟨q, rfl⟩
    simp only [ContinuousLinearMap.coe_coe]
    rw [planeMap_apply_eq L q]
    have h1 : L (1, 0) ∈ Submodule.span ℝ {L (1, 0), L (0, 1)} :=
      Submodule.subset_span (Set.mem_insert _ _)
    have h2 : L (0, 1) ∈ Submodule.span ℝ {L (1, 0), L (0, 1)} :=
      Submodule.subset_span (Set.mem_insert_of_mem _ (Set.mem_singleton _))
    exact Submodule.add_mem _ (Submodule.smul_mem _ _ h1) (Submodule.smul_mem _ _ h2)
  · rw [Submodule.span_le]
    rintro _ (rfl | rfl)
    · exact ⟨(1, 0), rfl⟩
    · exact ⟨(0, 1), rfl⟩

theorem tangentCone_eq_range_of_patch
    (S : Set (Fin 3 → ℝ)) (p : Fin 3 → ℝ)
    (r : ℝ × ℝ → Fin 3 → ℝ) (U : Set (ℝ × ℝ)) (hU : IsOpen U)
    (hr_smooth : ContDiffOn ℝ ∞ r U)
    (hr_emb : Topology.IsEmbedding (U.domRestrict r))
    (hr_reg : ∀ u ∈ U, fderiv ℝ r u (1, 0) ⨯₃ fderiv ℝ r u (0, 1) ≠ 0)
    (hr_cover : ∃ W : Set (Fin 3 → ℝ), IsOpen W ∧ p ∈ W ∧ r '' U = S ∩ W)
    (u₀ : ℝ × ℝ) (hu₀ : u₀ ∈ U) (hrp : r u₀ = p) :
    tangentConeAt ℝ S p =
      (LinearMap.range (fderiv ℝ r u₀ : ℝ × ℝ →ₗ[ℝ] Fin 3 → ℝ) : Set (Fin 3 → ℝ)) := by
  obtain ⟨W, hW, hpW, hrW⟩ := hr_cover
  have hT : tangentConeAt ℝ (r '' U) (r u₀) = tangentConeAt ℝ S p := by
    rw [hrW, hrp, tangentConeAt_inter_nhds (hW.mem_nhds hpW)]
  have hdiff : DifferentiableAt ℝ r u₀ :=
    (hr_smooth.differentiableOn (by simp) u₀ hu₀).differentiableAt (hU.mem_nhds hu₀)
  have hL : HasFDerivAt r (fderiv ℝ r u₀) u₀ := hdiff.hasFDerivAt
  apply Set.Subset.antisymm
  · rw [← hT]
    exact tangentCone_image_subset_range hr_emb hu₀ hL
      (planeMap_injective_of_cross_ne_zero _ (hr_reg u₀ hu₀))
  · rintro _ ⟨v, rfl⟩
    rw [← hT]
    have hv : v ∈ tangentConeAt ℝ U u₀ := by
      rw [tangentConeAt_of_mem_nhds (hU.mem_nhds hu₀)]; trivial
    exact hL.hasFDerivWithinAt.mapsTo_tangent_cone hv

/-- The tangent plane does not depend on the patch. Let `r(u, v)` and `s(σ, τ)` be two patches
of a set `S` in space, each defined on an open set of map points, each smooth, each one-to-one
with a continuous inverse (an embedding), each covering all of `S` near `p`, and each with tangent
arrows whose cross product is never zero. If `r(u₀) = p = s(σ₀)`, then the arrows `r_u, r_v` and
the arrows `s_σ, s_τ` span the same plane `T_pS`, and the two cross products differ by a non-zero
factor, so the unit normal is the same up to sign. -/
theorem tangent_plane_independent_of_patch
    (S : Set (Fin 3 → ℝ)) (p : Fin 3 → ℝ)
    (r s : ℝ × ℝ → Fin 3 → ℝ) (U V : Set (ℝ × ℝ))
    (hU : IsOpen U) (hV : IsOpen V)
    (hr_smooth : ContDiffOn ℝ ∞ r U) (hs_smooth : ContDiffOn ℝ ∞ s V)
    (hr_emb : Topology.IsEmbedding (U.domRestrict r))
    (hs_emb : Topology.IsEmbedding (V.domRestrict s))
    (hr_reg : ∀ u ∈ U, fderiv ℝ r u (1, 0) ⨯₃ fderiv ℝ r u (0, 1) ≠ 0)
    (hs_reg : ∀ σ ∈ V, fderiv ℝ s σ (1, 0) ⨯₃ fderiv ℝ s σ (0, 1) ≠ 0)
    (hr_cover : ∃ W : Set (Fin 3 → ℝ), IsOpen W ∧ p ∈ W ∧ r '' U = S ∩ W)
    (hs_cover : ∃ W : Set (Fin 3 → ℝ), IsOpen W ∧ p ∈ W ∧ s '' V = S ∩ W)
    (u₀ σ₀ : ℝ × ℝ) (hu₀ : u₀ ∈ U) (hσ₀ : σ₀ ∈ V)
    (hrp : r u₀ = p) (hsp : s σ₀ = p) :
    Submodule.span ℝ {fderiv ℝ r u₀ (1, 0), fderiv ℝ r u₀ (0, 1)} =
        Submodule.span ℝ {fderiv ℝ s σ₀ (1, 0), fderiv ℝ s σ₀ (0, 1)} ∧
      ∃ c : ℝ, c ≠ 0 ∧
        fderiv ℝ s σ₀ (1, 0) ⨯₃ fderiv ℝ s σ₀ (0, 1) =
          c • (fderiv ℝ r u₀ (1, 0) ⨯₃ fderiv ℝ r u₀ (0, 1)) := by
  have hr := tangentCone_eq_range_of_patch S p r U hU hr_smooth hr_emb hr_reg hr_cover u₀ hu₀ hrp
  have hs := tangentCone_eq_range_of_patch S p s V hV hs_smooth hs_emb hs_reg hs_cover σ₀ hσ₀ hsp
  have hrange : LinearMap.range (fderiv ℝ r u₀ : ℝ × ℝ →ₗ[ℝ] Fin 3 → ℝ) =
      LinearMap.range (fderiv ℝ s σ₀ : ℝ × ℝ →ₗ[ℝ] Fin 3 → ℝ) :=
    SetLike.coe_injective (hr.symm.trans hs)
  refine ⟨by rw [← planeMap_range_eq_span, ← planeMap_range_eq_span, hrange], ?_⟩
  have h1 : fderiv ℝ s σ₀ (1, 0) ∈ LinearMap.range (fderiv ℝ r u₀ : ℝ × ℝ →ₗ[ℝ] Fin 3 → ℝ) := by
    rw [hrange]; exact ⟨(1, 0), rfl⟩
  have h2 : fderiv ℝ s σ₀ (0, 1) ∈ LinearMap.range (fderiv ℝ r u₀ : ℝ × ℝ →ₗ[ℝ] Fin 3 → ℝ) := by
    rw [hrange]; exact ⟨(0, 1), rfl⟩
  obtain ⟨q₁, hq₁⟩ := h1
  obtain ⟨q₂, hq₂⟩ := h2
  simp only [ContinuousLinearMap.coe_coe] at hq₁ hq₂
  rw [planeMap_apply_eq (fderiv ℝ r u₀) q₁] at hq₁
  rw [planeMap_apply_eq (fderiv ℝ r u₀) q₂] at hq₂
  have hc := cross_switch_helper (fderiv ℝ r u₀ (1, 0)) (fderiv ℝ r u₀ (0, 1)) q₁.1 q₁.2 q₂.1 q₂.2
  rw [hq₁, hq₂] at hc
  refine ⟨q₁.1 * q₂.2 - q₂.1 * q₁.2, ?_, hc⟩
  intro h0
  apply hs_reg σ₀ hσ₀
  rw [hc, h0, zero_smul]

/-- Every graph of a smooth function is a regular surface, covered by one patch. For a smooth
height function `h`, the plan patch `r(x, y) = (x, y, h(x, y))` is smooth, one-to-one with a
continuous inverse (an embedding), covers the whole graph `z = h(x, y)`, and its tangent arrows
`r_x = (1, 0, h_x)`, `r_y = (0, 1, h_y)` have cross product `N = (-h_x, -h_y, 1)`, which is never
zero. -/
theorem graph_is_regular_surface (h : ℝ × ℝ → ℝ) (hh : ContDiff ℝ ∞ h) :
    let r : ℝ × ℝ → Fin 3 → ℝ := fun q => ![q.1, q.2, h q]
    ContDiff ℝ ∞ r ∧ Topology.IsEmbedding r ∧
      Set.range r = {X : Fin 3 → ℝ | X 2 = h (X 0, X 1)} ∧
      ∀ q : ℝ × ℝ,
        fderiv ℝ r q (1, 0) ⨯₃ fderiv ℝ r q (0, 1) =
            ![-(fderiv ℝ h q (1, 0)), -(fderiv ℝ h q (0, 1)), 1] ∧
          fderiv ℝ r q (1, 0) ⨯₃ fderiv ℝ r q (0, 1) ≠ 0 := by
  intro r
  have hcont : ContDiff ℝ ∞ r := by
    refine contDiff_pi' fun i => ?_
    fin_cases i
    · simpa [r] using contDiff_fst
    · simpa [r] using contDiff_snd
    · simpa [r] using hh
  have hderiv : ∀ q : ℝ × ℝ, ∀ v : ℝ × ℝ, fderiv ℝ r q v = ![v.1, v.2, fderiv ℝ h q v] := by
    intro q v
    let L : ℝ × ℝ →L[ℝ] Fin 3 → ℝ := ContinuousLinearMap.pi
      (fun i => (![ContinuousLinearMap.fst ℝ ℝ ℝ, ContinuousLinearMap.snd ℝ ℝ ℝ, fderiv ℝ h q] :
        Fin 3 → (ℝ × ℝ →L[ℝ] ℝ)) i)
    have hL : HasFDerivAt r L q := by
      refine hasFDerivAt_pi'' fun i => ?_
      have hd : DifferentiableAt ℝ h q := hh.differentiable (by simp) q
      fin_cases i
      · simpa [r, L] using hasFDerivAt_fst
      · simpa [r, L] using hasFDerivAt_snd
      · simpa [r, L] using hd.hasFDerivAt
    rw [hL.fderiv]
    ext i; fin_cases i <;> simp [L]
  refine ⟨hcont, ?_, ?_, ?_⟩
  · refine Function.LeftInverse.isEmbedding (g := r) (f := fun X : Fin 3 → ℝ => (X 0, X 1))
      (fun q => by simp [r]) (by fun_prop) hcont.continuous
  · ext X
    simp only [Set.mem_range, Set.mem_ofPred_eq]
    constructor
    · rintro ⟨q, rfl⟩; simp [r]
    · intro hX
      refine ⟨(X 0, X 1), ?_⟩
      ext i; fin_cases i <;> simp [r, hX]
  · intro q
    have hc : fderiv ℝ r q (1, 0) ⨯₃ fderiv ℝ r q (0, 1) =
        ![-(fderiv ℝ h q (1, 0)), -(fderiv ℝ h q (0, 1)), 1] := by
      rw [hderiv, hderiv]
      ext i; fin_cases i <;> simp [cross_apply]
    refine ⟨hc, ?_⟩
    rw [hc]
    intro h0
    have := congrFun h0 2
    simp at this

/-- Switching patches multiplies the cross product by the Jacobian determinant. If the new
arrows are `s_σ = u_σ r_u + v_σ r_v` and `s_τ = u_τ r_u + v_τ r_v` (the chain rule), then
`s_σ × s_τ = (u_σ v_τ - u_τ v_σ) (r_u × r_v) = det J (r_u × r_v)`. -/
theorem cross_of_switch_eq_det_smul (r_u r_v : Fin 3 → ℝ) (u_σ v_σ u_τ v_τ : ℝ) :
    (u_σ • r_u + v_σ • r_v) ⨯₃ (u_τ • r_u + v_τ • r_v) =
      (u_σ * v_τ - u_τ * v_σ) • (r_u ⨯₃ r_v) := by
  simp only [LinearMap.map_add, LinearMap.map_smul, LinearMap.add_apply, LinearMap.smul_apply,
    cross_self, smul_zero, zero_add, add_zero, smul_smul]
  rw [← cross_anticomm r_u r_v, sub_smul, smul_neg]
  rw [mul_comm v_σ u_τ, mul_comm u_τ v_σ]
  abel

-- Worked numbers at P = (20, 25) on the roof h(x, y) = 40 + x²(120 - x)/40000 - y²/250.
-- Height 38.5 m.
example : (40 : ℝ) + 20 ^ 2 * (120 - 20) / 40000 - 25 ^ 2 / 250 = 77 / 2 := by norm_num
-- Slopes h_x = 0.09 and h_y = -0.2.
example : ((240 : ℝ) * 20 - 3 * 20 ^ 2) / 40000 = 9 / 100 := by norm_num
example : (-2 : ℝ) * 25 / 250 = -1 / 5 := by norm_num
-- N = r_x × r_y = (-0.09, 0.2, 1).
example : ![(1 : ℝ), 0, 9 / 100] ⨯₃ ![0, 1, -1 / 5] = ![-9 / 100, 1 / 5, 1] := by
  ext i; fin_cases i <;> simp [cross_apply] <;> norm_num
-- |N|² = 1.0481, so |N| = 1.023768 to six places.
example : ![(-9 : ℝ) / 100, 1 / 5, 1] ⬝ᵥ ![-9 / 100, 1 / 5, 1] = 10481 / 10000 := by
  simp [dotProduct, Fin.sum_univ_succ]; norm_num
-- Tangent plane: -0.09x + 0.2y + z = 41.7.
example : ![(-9 : ℝ) / 100, 1 / 5, 1] ⬝ᵥ ![20, 25, 77 / 2] = 417 / 10 := by
  simp [dotProduct, Fin.sum_univ_succ]; norm_num
-- Polar patch about the crown at P: r_ρ × r_θ = (-5.85, 13, 65) = 65 N.
example : ![(-12 : ℝ) / 13, 5 / 13, -4 / 25] ⨯₃ ![-25, -60, 39 / 4] =
    (65 : ℝ) • ![-9 / 100, 1 / 5, 1] := by
  ext i; fin_cases i <;> simp [cross_apply] <;> norm_num
-- Q = (100, -15) on the dome: height 44.1 m, N = (0.15, -0.12, 1).
example : (40 : ℝ) + 100 ^ 2 * (120 - 100) / 40000 - (-15) ^ 2 / 250 = 441 / 10 := by norm_num
example : ![(1 : ℝ), 0, -3 / 20] ⨯₃ ![0, 1, 3 / 25] = ![3 / 20, -3 / 25, 1] := by
  ext i; fin_cases i <;> simp [cross_apply] <;> norm_num

#print axioms tangentCone_image_subset_range
#print axioms cross_switch_helper
#print axioms planeMap_apply_eq
#print axioms planeMap_injective_of_cross_ne_zero
#print axioms planeMap_range_eq_span
#print axioms tangentCone_eq_range_of_patch
#print axioms tangent_plane_independent_of_patch
#print axioms graph_is_regular_surface
#print axioms cross_of_switch_eq_det_smul
