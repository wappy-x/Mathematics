-- Regular value theorem: if the derivative of a smooth map from an open set of ℝ^n to ℝ^k is onto at every point of a level set, that level set is, near each of its points, a flat (n − k)-dimensional slice in smooth coordinates, and its tangent directions are exactly the directions the derivative sends to zero.
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.Calculus.TangentCone.Defs
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Topology.OpenPartialHomeomorph.Defs
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Analysis.Calculus.InverseFunctionTheorem.FDeriv
import Mathlib.Analysis.Calculus.ContDiff.Operations
import Mathlib.Analysis.Calculus.ContDiff.RCLike
import Mathlib.Analysis.Calculus.TangentCone.Real
import Mathlib.Analysis.Normed.Operator.BoundedLinearMaps

open scoped ContDiff Matrix


/-- Helper: an onto linear map `A` from `ℝ^n` to `ℝ^k` can be completed by a linear map `L` to
`ℝ^(n − k)` so that `x ↦ (L x, A x)` is a linear isomorphism. -/
theorem exists_complement_equiv_of_surjective {n k : ℕ}
    (A : EuclideanSpace ℝ (Fin n) →L[ℝ] EuclideanSpace ℝ (Fin k)) (hA : Function.Surjective A) :
    ∃ L : EuclideanSpace ℝ (Fin n) →L[ℝ] EuclideanSpace ℝ (Fin (n - k)),
      ∃ e : EuclideanSpace ℝ (Fin n) ≃L[ℝ]
          (EuclideanSpace ℝ (Fin (n - k)) × EuclideanSpace ℝ (Fin k)),
        (e : EuclideanSpace ℝ (Fin n) →L[ℝ] _) = L.prod A := by
  have hrange : LinearMap.range (A : EuclideanSpace ℝ (Fin n) →ₗ[ℝ] EuclideanSpace ℝ (Fin k)) = ⊤ :=
    LinearMap.range_eq_top.mpr hA
  have hrn := LinearMap.finrank_range_add_finrank_ker
    (A : EuclideanSpace ℝ (Fin n) →ₗ[ℝ] EuclideanSpace ℝ (Fin k))
  rw [hrange, finrank_top, finrank_euclideanSpace_fin, finrank_euclideanSpace_fin] at hrn
  obtain ⟨π, hπ⟩ := (LinearMap.ker
    (A : EuclideanSpace ℝ (Fin n) →ₗ[ℝ] EuclideanSpace ℝ (Fin k))).subtype.exists_leftInverse_of_injective
    (by simp)
  let e1 := LinearEquiv.ofFinrankEq (LinearMap.ker
    (A : EuclideanSpace ℝ (Fin n) →ₗ[ℝ] EuclideanSpace ℝ (Fin k)))
    (EuclideanSpace ℝ (Fin (n - k))) (by rw [finrank_euclideanSpace_fin]; omega)
  let L : EuclideanSpace ℝ (Fin n) →L[ℝ] EuclideanSpace ℝ (Fin (n - k)) :=
    LinearMap.toContinuousLinearMap (e1.toLinearMap ∘ₗ π)
  let M : EuclideanSpace ℝ (Fin n) →ₗ[ℝ]
      (EuclideanSpace ℝ (Fin (n - k)) × EuclideanSpace ℝ (Fin k)) := (L.prod A : _)
  have hinj : Function.Injective M := by
    rw [← LinearMap.ker_eq_bot, LinearMap.ker_eq_bot']
    intro x hx
    have h1 : L x = 0 := congrArg Prod.fst hx
    have h2 : A x = 0 := congrArg Prod.snd hx
    have hxk : x ∈ LinearMap.ker
        (A : EuclideanSpace ℝ (Fin n) →ₗ[ℝ] EuclideanSpace ℝ (Fin k)) := h2
    have hπx : π x = ⟨x, hxk⟩ := by
      have := LinearMap.congr_fun hπ ⟨x, hxk⟩
      simpa using this
    have : e1 ⟨x, hxk⟩ = 0 := by
      have : L x = e1 (π x) := rfl
      rw [← hπx, ← this, h1]
    have := congrArg Subtype.val (e1.map_eq_zero_iff.mp this)
    simpa using this
  have hsurj : Function.Surjective M := by
    rwa [← LinearMap.injective_iff_surjective_of_finrank_eq_finrank]
    rw [Module.finrank_prod, finrank_euclideanSpace_fin, finrank_euclideanSpace_fin,
      finrank_euclideanSpace_fin]
    omega
  refine ⟨L, (LinearEquiv.ofBijective M ⟨hinj, hsurj⟩).toContinuousLinearEquiv, ?_⟩
  ext x : 1
  rfl

#print axioms exists_complement_equiv_of_surjective

/-- **Regular value theorem.** Let `F` be smooth on an open set `U` of `ℝ^n`, with values in
`ℝ^k`, and let `c` be a regular value: at every point `p` of `U` with `F p = c` the differential
`dF_p` is onto. Then the level set `M = {q ∈ U | F q = c}` is an embedded submanifold of
dimension `n − k`: near each of its points `p` there are smooth coordinates `Φ`, with a smooth
inverse, taking values in `ℝ^(n − k) × ℝ^k`, in which `M` is exactly the flat slice where the last
`k` coordinates are zero. And its tangent space at `p` (the tangent cone of `M`, the limiting
directions of `M` at `p`) is the kernel of `dF_p`, the directions the derivative sends to zero. -/
theorem regular_level_set_is_embedded_submanifold {n k : ℕ}
    {U : Set (EuclideanSpace ℝ (Fin n))} (hU : IsOpen U)
    {F : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin k)} (hF : ContDiffOn ℝ ∞ F U)
    {c : EuclideanSpace ℝ (Fin k)}
    (hc : ∀ p ∈ U, F p = c → Function.Surjective (fderiv ℝ F p)) :
    ∀ p ∈ U, F p = c →
      (∃ Φ : OpenPartialHomeomorph (EuclideanSpace ℝ (Fin n))
          (EuclideanSpace ℝ (Fin (n - k)) × EuclideanSpace ℝ (Fin k)),
        p ∈ Φ.source ∧ Φ.source ⊆ U ∧
        ContDiffOn ℝ ∞ Φ Φ.source ∧ ContDiffOn ℝ ∞ Φ.symm Φ.target ∧
        ∀ q ∈ Φ.source, (F q = c ↔ (Φ q).2 = 0)) ∧
      tangentConeAt ℝ {q | q ∈ U ∧ F q = c} p = {v | fderiv ℝ F p v = 0} := by
  intro p hp hFp
  obtain ⟨L, E0, hE0⟩ := exists_complement_equiv_of_surjective (fderiv ℝ F p) (hc p hp hFp)
  have hFa : ∀ x ∈ U, ContDiffAt ℝ ∞ F x := fun x hx => hF.contDiffAt (hU.mem_nhds hx)
  have hFd : ∀ x ∈ U, HasFDerivAt F (fderiv ℝ F x) x := fun x hx =>
    ((hFa x hx).differentiableAt (by simp)).hasFDerivAt
  set Ψ : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin (n - k)) × EuclideanSpace ℝ (Fin k) :=
    fun x => (L x, F x - c) with hΨdef
  have hΨd : ∀ x ∈ U, HasFDerivAt Ψ (L.prod (fderiv ℝ F x)) x := fun x hx =>
    L.hasFDerivAt.prodMk ((hFd x hx).sub_const c)
  have hΨs : ContDiffOn ℝ ∞ Ψ U := L.contDiff.contDiffOn.prodMk (hF.sub contDiffOn_const)
  have hΨa : ∀ x ∈ U, ContDiffAt ℝ ∞ Ψ x := fun x hx => hΨs.contDiffAt (hU.mem_nhds hx)
  have hΨp : HasFDerivAt Ψ (E0 : EuclideanSpace ℝ (Fin n) →L[ℝ] _) p := by
    rw [hE0]; exact hΨd p hp
  have hstrict : HasStrictFDerivAt Ψ (E0 : EuclideanSpace ℝ (Fin n) →L[ℝ] _) p :=
    (hΨa p hp).hasStrictFDerivAt' hΨp (by simp)
  set W := U ∩ fderiv ℝ Ψ ⁻¹' Set.range
    ((↑) : (EuclideanSpace ℝ (Fin n) ≃L[ℝ]
      (EuclideanSpace ℝ (Fin (n - k)) × EuclideanSpace ℝ (Fin k))) → _) with hWdef
  have hW : IsOpen W :=
    (hΨs.continuousOn_fderiv_of_isOpen hU (by simp)).isOpen_inter_preimage hU
      ContinuousLinearEquiv.isOpen
  have hpW : p ∈ W := ⟨hp, E0, (hΨp.fderiv).symm⟩
  set Φ := (hstrict.toOpenPartialHomeomorph Ψ).restrOpen W hW with hΦdef
  have hΦcoe : (Φ : EuclideanSpace ℝ (Fin n) → _) = Ψ := rfl
  have hΦsrc : Φ.source = (hstrict.toOpenPartialHomeomorph Ψ).source ∩ W :=
    OpenPartialHomeomorph.restrOpen_source _ _ _
  have hsrcU : Φ.source ⊆ U := fun x hx => (hΦsrc ▸ hx).2.1
  have hpsrc : p ∈ Φ.source := hΦsrc ▸ ⟨hstrict.mem_toOpenPartialHomeomorph_source, hpW⟩
  have hlevel : ∀ q ∈ Φ.source, (F q = c ↔ (Φ q).2 = 0) := by
    intro q _
    rw [hΦcoe]
    simp [Ψ, sub_eq_zero]
  refine ⟨⟨Φ, hpsrc, hsrcU, ?_, ?_, hlevel⟩, ?_⟩
  · rw [hΦcoe]; exact hΨs.mono hsrcU
  · intro y hy
    have hx : Φ.symm y ∈ Φ.source := Φ.map_target hy
    obtain ⟨e, he⟩ := (hΦsrc ▸ hx).2.2
    have hxU : Φ.symm y ∈ U := hsrcU hx
    refine (Φ.contDiffAt_symm hy (f₀' := e) ?_ ?_).contDiffWithinAt
    · rw [hΦcoe, he]
      exact ((hΨa _ hxU).differentiableAt (by simp)).hasFDerivAt
    · rw [hΦcoe]; exact hΨa _ hxU
  · ext v
    constructor
    · intro hv
      have hFw : HasFDerivWithinAt F (fderiv ℝ F p) {q | q ∈ U ∧ F q = c} p :=
        (hFd p hp).hasFDerivWithinAt
      have h1 := hFw.mapsTo_tangent_cone hv
      have hsub : F '' {q | q ∈ U ∧ F q = c} ⊆ {c} := by
        rintro _ ⟨q, hq, rfl⟩; exact hq.2
      have h2 := tangentConeAt_mono hsub (hFp ▸ h1)
      have hacc : ¬ AccPt c (Filter.principal ({c} : Set (EuclideanSpace ℝ (Fin k)))) := by
        rw [accPt_iff_frequently]
        simp
      have h3 := tangentConeAt_subset_zero hacc h2
      simpa using h3
    · intro hv
      have hv' : fderiv ℝ F p v = 0 := hv
      have hE0v : E0 v = (L v, 0) := by
        have := congrArg (fun T : EuclideanSpace ℝ (Fin n) →L[ℝ] _ => T v) hE0
        simp only [ContinuousLinearEquiv.coe_coe] at this
        rw [this]; simp [hv']
      have hΦp : Φ p = (L p, 0) := by rw [hΦcoe]; simp [Ψ, hFp]
      have htp : Φ p ∈ Φ.target := Φ.map_source hpsrc
      have hsymm : HasFDerivAt Φ.symm (E0.symm : _ →L[ℝ] EuclideanSpace ℝ (Fin n)) (Φ p) := by
        apply Φ.hasFDerivAt_symm htp
        rw [Φ.left_inv hpsrc, hΦcoe]; exact hΨp
      set S := {y : EuclideanSpace ℝ (Fin (n - k)) × EuclideanSpace ℝ (Fin k) | y.2 = 0}
        ∩ Φ.target with hSdef
      have hw : ((L v, 0) : EuclideanSpace ℝ (Fin (n - k)) × EuclideanSpace ℝ (Fin k)) ∈
          tangentConeAt ℝ S (Φ p) := by
        rw [hSdef, tangentConeAt_inter_nhds (Φ.open_target.mem_nhds htp)]
        have := mem_tangentConeAt_of_segment_subset (s := {y : EuclideanSpace ℝ (Fin (n - k)) ×
            EuclideanSpace ℝ (Fin k) | y.2 = 0}) (x := Φ p) (y := Φ p + (L v, 0)) ?_
        · simpa using this
        · rintro z ⟨a, b, -, -, -, rfl⟩
          simp [hΦp]
      have h1 := hsymm.hasFDerivWithinAt (s := S) |>.mapsTo_tangent_cone hw
      rw [Φ.left_inv hpsrc] at h1
      have hsub : Φ.symm '' S ⊆ {q | q ∈ U ∧ F q = c} := by
        rintro _ ⟨y, ⟨hy2, hyt⟩, rfl⟩
        have hs := Φ.map_target hyt
        refine ⟨hsrcU hs, (hlevel _ hs).mpr ?_⟩
        rw [Φ.right_inv hyt]; exact hy2
      have h2 := tangentConeAt_mono hsub h1
      have : (E0.symm : _ →L[ℝ] EuclideanSpace ℝ (Fin n))
          ((L v, 0) : EuclideanSpace ℝ (Fin (n - k)) × EuclideanSpace ℝ (Fin k)) = v := by
        rw [← hE0v]; simp
      rwa [this] at h2

/-- **The budget loop passes the rank test everywhere.** Split $10,000 as `x, y, z` dollars in
funds with yearly swings of 10%, 20% and 30%, so `F = (x + y + z, (x/10)² + (y/5)² + (3z/10)²)`
and `dF` has rows `(1, 1, 1)` and `(x/50, 2y/25, 9z/50)`. At every split with total 10000 and
risk exactly 900 (risk squared 810000), at least one of the three 2 × 2 minors of `dF`, for the
columns (x, y), (x, z) and (y, z), is not zero. So `dF` has rank 2 there, `(10000, 810000)` is a
regular value, and the loop is a smooth curve of dimension 3 − 2 = 1. -/
theorem budget_loop_passes_rank_test (x y z : ℝ) (htotal : x + y + z = 10000)
    (hrisk : (x / 10) ^ 2 + (y / 5) ^ 2 + (3 * z / 10) ^ 2 = 810000) :
    ¬ (1 * (2 * y / 25) - 1 * (x / 50) = 0 ∧ 1 * (9 * z / 50) - 1 * (x / 50) = 0 ∧
        1 * (9 * z / 50) - 1 * (2 * y / 25) = 0) := by
  rintro ⟨h1, h2, -⟩
  have hx : x = 360000 / 49 := by linarith
  have hy : y = 90000 / 49 := by linarith
  have hz : z = 40000 / 49 := by linarith
  subst hx hy hz
  norm_num at hrisk

/-- **The least risk is $6000/7, at one split only.** Every split of $10,000 has risk squared at
least `(6000/7)²` (risk at least 857.142857 dollars), and it equals `(6000/7)²` exactly at the
least-risk split `(360000/49, 90000/49, 40000/49)`, about (7346.94, 1836.73, 816.33). This is
the one split where the two rows of `dF` are parallel; a risk target of $850 has no splits. -/
theorem least_risk_split (x y z : ℝ) (htotal : x + y + z = 10000) :
    (6000 / 7 : ℝ) ^ 2 ≤ (x / 10) ^ 2 + (y / 5) ^ 2 + (3 * z / 10) ^ 2 ∧
      ((x / 10) ^ 2 + (y / 5) ^ 2 + (3 * z / 10) ^ 2 = (6000 / 7 : ℝ) ^ 2 ↔
        x = 360000 / 49 ∧ y = 90000 / 49 ∧ z = 40000 / 49) := by
  have key : (x / 10) ^ 2 + (y / 5) ^ 2 + (3 * z / 10) ^ 2 - (6000 / 7 : ℝ) ^ 2 =
      (x / 10 - 36000 / 49) ^ 2 + (y / 5 - 18000 / 49) ^ 2 + (3 * z / 10 - 12000 / 49) ^ 2 := by
    have hz : z = 10000 - x - y := by linarith
    subst hz
    ring
  refine ⟨by nlinarith [sq_nonneg (x / 10 - 36000 / 49), sq_nonneg (y / 5 - 18000 / 49),
    sq_nonneg (3 * z / 10 - 12000 / 49)], ⟨fun h => ?_, ?_⟩⟩
  · have h0 : (x / 10 - 36000 / 49) ^ 2 + (y / 5 - 18000 / 49) ^ 2 +
        (3 * z / 10 - 12000 / 49) ^ 2 = 0 := by linarith
    have ha := sq_nonneg (x / 10 - 36000 / 49)
    have hb := sq_nonneg (y / 5 - 18000 / 49)
    have hc := sq_nonneg (3 * z / 10 - 12000 / 49)
    have e1 : (x / 10 - 36000 / 49) ^ 2 = 0 := by linarith
    have e2 : (y / 5 - 18000 / 49) ^ 2 = 0 := by linarith
    have e3 : (3 * z / 10 - 12000 / 49) ^ 2 = 0 := by linarith
    have f1 := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp e1
    have f2 := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp e2
    have f3 := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp e3
    refine ⟨by linarith, by linarith, by linarith⟩
  · rintro ⟨rfl, rfl, rfl⟩
    norm_num


-- The split p = (6000, 3000, 1000): total 10000, risk squared 600² + 600² + 300² = 810000 = 900².
example : (6000 : ℤ) + 3000 + 1000 = 10000 := by norm_num
example : (6000 / 10 : ℚ) = 600 ∧ (3000 / 5 : ℚ) = 600 ∧ (3 * 1000 / 10 : ℚ) = 300 := by norm_num
example : (600 : ℤ) ^ 2 + 600 ^ 2 + 300 ^ 2 = 810000 ∧ (900 : ℤ) ^ 2 = 810000 := by norm_num
-- Row 2 of dF_p: 2 × 0.01 × 6000, 2 × 0.04 × 3000, 2 × 0.09 × 1000 = 120, 240, 180.
example : 2 * (1 / 100 : ℚ) * 6000 = 120 ∧ 2 * (4 / 100 : ℚ) * 3000 = 240 ∧
    2 * (9 / 100 : ℚ) * 1000 = 180 := by norm_num
-- Minors (x, y), (x, z), (y, z): 120, 60, −60, so rank 2 and dimension 3 − 2 = 1.
example : (1 : ℤ) * 240 - 1 * 120 = 120 ∧ (1 : ℤ) * 180 - 1 * 120 = 60 ∧
    (1 : ℤ) * 180 - 1 * 240 = -60 := by norm_num
-- Tangent: (1, 1, 1) × (120, 240, 180) = (−60, −60, 120); per $1 into z, (−1/2, −1/2, 1).
example : (![1, 1, 1] : Fin 3 → ℤ) ⨯₃ ![120, 240, 180] = ![-60, -60, 120] := by decide
example : (-60 / 120 : ℚ) = -1 / 2 ∧ (120 / 120 : ℚ) = 1 := by norm_num
-- Implicit function slopes dx/dz = dy/dz = −1/2: both rows of dF_p send (−1/2, −1/2, 1) to 0.
example : (1 : ℚ) * (-1 / 2) + 1 * (-1 / 2) + 1 * 1 = 0 ∧
    (120 : ℚ) * (-1 / 2) + 240 * (-1 / 2) + 180 * 1 = 0 := by norm_num
-- Budget plane in risk coordinates: normal (10, 5, 10/3) has length 35/3, unit normal
-- (6/7, 3/7, 2/7), distance from the origin 10000 / (35/3) = 6000/7.
example : (10 : ℚ) ^ 2 + 5 ^ 2 + (10 / 3) ^ 2 = (35 / 3) ^ 2 := by norm_num
example : (10 : ℚ) / (35 / 3) = 6 / 7 ∧ (5 : ℚ) / (35 / 3) = 3 / 7 ∧
    (10 / 3 : ℚ) / (35 / 3) = 2 / 7 ∧ (10000 : ℚ) / (35 / 3) = 6000 / 7 := by norm_num
-- Loop radius squared 900² − (6000/7)² = 3690000/49 (radius 274.42); at risk 850 it is
-- 850² − (6000/7)² = −597500/49 (−12193.88), so no split at all.
example : (900 : ℚ) ^ 2 - (6000 / 7) ^ 2 = 3690000 / 49 := by norm_num
example : (850 : ℚ) ^ 2 - (6000 / 7) ^ 2 = -597500 / 49 := by norm_num
-- The least-risk split (360000/49, 90000/49, 40000/49) totals 10000 and has risk 6000/7.
example : (360000 / 49 : ℚ) + 90000 / 49 + 40000 / 49 = 10000 := by norm_num
example : ((360000 / 49 : ℚ) / 10) ^ 2 + ((90000 / 49) / 5) ^ 2 + (3 * (40000 / 49) / 10) ^ 2 =
    (6000 / 7) ^ 2 := by norm_num
-- Globe: 3 unknowns, 1 equation, a surface of dimension 2; |dF| = 2R = 2 × 6371 = 12742 km.
example : 3 - 1 = 2 ∧ 2 * 6371 = 12742 := by decide
-- O(3): AᵀA = I has 9 entries, 6 independent equations, so dimension 9 − 6 = 3.
example : 9 - 6 = 3 := by decide

#print axioms regular_level_set_is_embedded_submanifold
#print axioms budget_loop_passes_rank_test
#print axioms least_risk_split
