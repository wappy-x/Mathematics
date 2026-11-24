-- Von Neumann's mean ergodic theorem: for a map that keeps measure, the time averages of an L2 function converge in L2 to its orthogonal projection onto the invariant functions, which is its conditional expectation given the invariant sets.
import Mathlib.Analysis.InnerProductSpace.MeanErgodic
import Mathlib.MeasureTheory.Function.ConditionalExpectation.Basic
import Mathlib.MeasureTheory.Function.L2Space
import Mathlib.MeasureTheory.MeasurableSpace.Invariants

open MeasureTheory Filter Topology

/-- An `L²` function fixed by the Koopman operator has a version measurable for the invariant
σ-algebra. -/
theorem aestronglyMeasurable_invariants_of_koopman_fixed
    {α : Type*} [MeasurableSpace α] {μ : Measure α} {T : α → α}
    (hT : MeasurePreserving T μ μ) (h : Lp ℝ 2 μ)
    (hh : (Lp.compMeasurePreservingₗᵢ ℝ T hT) h = h) :
    AEStronglyMeasurable[MeasurableSpace.invariants T] (h : α → ℝ) μ := by
  have hm := (Lp.aestronglyMeasurable h).aemeasurable
  set g0 := hm.mk _ with hg0
  have hg0m : Measurable g0 := hm.measurable_mk
  have hhg0 : (h : α → ℝ) =ᵐ[μ] g0 := hm.ae_eq_mk
  have hcomp : (h : α → ℝ) ∘ T =ᵐ[μ] (h : α → ℝ) := by
    have h1 := Lp.coeFn_compMeasurePreserving h hT
    have hh' : Lp.compMeasurePreserving T hT h = h := hh
    rw [hh'] at h1
    exact h1.symm
  have hT1 : g0 ∘ T =ᵐ[μ] g0 :=
    ((hT.quasiMeasurePreserving.ae_eq_comp hhg0).symm.trans hcomp).trans hhg0
  have hiter : ∀ n : ℕ, g0 ∘ T^[n] =ᵐ[μ] g0 := by
    intro n
    induction n with
    | zero => exact Filter.EventuallyEq.rfl
    | succ n ih =>
      rw [Function.iterate_succ, ← Function.comp_assoc]
      exact (hT.quasiMeasurePreserving.ae_eq_comp ih).trans hT1
  set G : α → ℝ := fun x => liminf (fun n => g0 (T^[n] x)) atTop with hG
  have hGm : Measurable G :=
    Measurable.liminf fun n => hg0m.comp (hT.measurable.iterate n)
  have hGT : G ∘ T = G := by
    funext x
    simp only [hG, Function.comp_apply]
    have : (fun n => g0 (T^[n] (T x))) = fun n => g0 (T^[n + 1] x) := by
      funext n; rw [Function.iterate_succ_apply]
    rw [this]
    exact liminf_nat_add (fun n => g0 (T^[n] x)) 1
  have hGinv : Measurable[MeasurableSpace.invariants T] G :=
    MeasurableSpace.measurable_invariants_dom.2 ⟨hGm, fun s _ => by rw [hGT]⟩
  have hGae : g0 =ᵐ[μ] G := by
    filter_upwards [ae_all_iff.2 hiter] with x hx
    have : (fun n => g0 (T^[n] x)) = fun _ => g0 x := funext fun n => hx n
    simp only [hG, this, liminf_const]
  exact ⟨G, hGinv.stronglyMeasurable, hhg0.trans hGae⟩

/-- **Von Neumann's mean ergodic theorem.** Let `T` keep the measure `μ`, and let `U` be the
Koopman operator `U f = f ∘ T` on `L²(μ)`. For every `f` in `L²(μ)`, the time averages
`(1/n)(f + U f + ... + U^(n-1) f)` converge in the L2 length to the orthogonal projection of `f`
onto the subspace of invariant functions `{h | U h = h}`. -/
theorem time_averages_tendsto_projection_onto_invariant
    {α : Type*} [MeasurableSpace α] {μ : Measure α} {T : α → α}
    (hT : MeasurePreserving T μ μ) (f : Lp ℝ 2 μ) :
    let U : Lp ℝ 2 μ →L[ℝ] Lp ℝ 2 μ :=
      (Lp.compMeasurePreservingₗᵢ ℝ T hT).toContinuousLinearMap
    Tendsto (fun n => birkhoffAverage ℝ U id n f) atTop
      (𝓝 ((U.eqLocus (1 : Lp ℝ 2 μ →L[ℝ] Lp ℝ 2 μ)).orthogonalProjectionOnto f : Lp ℝ 2 μ)) := by
  intro U
  exact U.tendsto_birkhoffAverage_orthogonalProjection
    (LinearIsometry.norm_toContinuousLinearMap_le _) f

/-- **The limit is the conditional expectation on the invariant sets.** On a space of finite
measure (such as `[0, 1)` with length), the orthogonal projection of `f` onto the invariant
functions `{h | U h = h}` equals, almost everywhere, the conditional expectation of `f` given the
σ-algebra of measurable sets `A` with `T⁻¹ A = A`. -/
theorem projection_onto_invariant_eq_condExp_invariants
    {α : Type*} [MeasurableSpace α] {μ : Measure α} [IsFiniteMeasure μ] {T : α → α}
    (hT : MeasurePreserving T μ μ) (f : Lp ℝ 2 μ) :
    let U : Lp ℝ 2 μ →L[ℝ] Lp ℝ 2 μ :=
      (Lp.compMeasurePreservingₗᵢ ℝ T hT).toContinuousLinearMap
    (((U.eqLocus (1 : Lp ℝ 2 μ →L[ℝ] Lp ℝ 2 μ)).orthogonalProjectionOnto f : Lp ℝ 2 μ) : α → ℝ)
      =ᵐ[μ] μ[(f : α → ℝ) | MeasurableSpace.invariants T] := by
  intro U
  set K := U.eqLocus (1 : Lp ℝ 2 μ →L[ℝ] Lp ℝ 2 μ)
  set P : Lp ℝ 2 μ := (K.orthogonalProjectionOnto f : Lp ℝ 2 μ)
  have hPK : U P = P := (K.orthogonalProjectionOnto f).2
  have hm := MeasurableSpace.invariants_le T
  refine ae_eq_condExp_of_forall_setIntegral_eq hm ?_ ?_ ?_ ?_
  · exact (Lp.memLp f).integrable one_le_two
  · intro s _ _
    exact ((Lp.memLp P).integrable one_le_two).integrableOn
  · intro s hs hμs
    have hsm : MeasurableSet s := hs.1
    set ind := indicatorConstLp 2 hsm hμs.ne (1 : ℝ)
    have hind : ind ∈ K := by
      show U ind = ind
      apply Lp.ext
      have h1 := Lp.coeFn_compMeasurePreserving ind hT
      have h2 : (ind : α → ℝ) =ᵐ[μ] s.indicator fun _ => (1 : ℝ) := indicatorConstLp_coeFn
      refine h1.trans ?_
      refine (hT.quasiMeasurePreserving.ae_eq_comp h2).trans ?_
      refine Filter.EventuallyEq.trans ?_ h2.symm
      refine Filter.Eventually.of_forall fun x => ?_
      show s.indicator (fun _ => (1 : ℝ)) (T x) = s.indicator (fun _ => (1 : ℝ)) x
      have hTs : T x ∈ s ↔ x ∈ s := by rw [← Set.mem_preimage, hs.2]
      by_cases hxs : x ∈ s
      · simp [Set.indicator, hxs, hTs.2 hxs]
      · simp [Set.indicator, hxs, mt hTs.1 hxs]
    have e1 := L2.inner_indicatorConstLp_one (𝕜 := ℝ) hsm hμs.ne P
    have e2 := L2.inner_indicatorConstLp_one (𝕜 := ℝ) hsm hμs.ne f
    have e3 := Submodule.inner_orthogonalProjectionOnto_eq_of_mem_left (K := K) ⟨ind, hind⟩ f
    rw [← e1, ← e2]
    exact e3
  · exact aestronglyMeasurable_invariants_of_koopman_fixed hT P hPK

/-- **L² splits into invariant functions and limits of differences.** The functions at right
angles to every invariant function are exactly the L2 limits of differences `g - U g`, so
`L² = H_inv ⊕ closure {g - U g}`. -/
theorem orthogonal_invariant_eq_closure_differences
    {α : Type*} [MeasurableSpace α] {μ : Measure α} {T : α → α}
    (hT : MeasurePreserving T μ μ) :
    let U : Lp ℝ 2 μ →L[ℝ] Lp ℝ 2 μ :=
      (Lp.compMeasurePreservingₗᵢ ℝ T hT).toContinuousLinearMap
    (U.eqLocus (1 : Lp ℝ 2 μ →L[ℝ] Lp ℝ 2 μ))ᗮ = (LinearMap.range
      (((1 : Lp ℝ 2 μ →L[ℝ] Lp ℝ 2 μ) - U : Lp ℝ 2 μ →L[ℝ] Lp ℝ 2 μ) : Lp ℝ 2 μ →ₗ[ℝ] Lp ℝ 2 μ)).topologicalClosure := by
  intro U
  set V := Lp.compMeasurePreservingₗᵢ (E := ℝ) (p := 2) ℝ T hT
  have hUV : ∀ x, U x = V x := fun x => rfl
  rw [← Submodule.orthogonal_orthogonal_eq_closure]
  congr 1
  apply le_antisymm
  · intro x hx
    rw [Submodule.mem_orthogonal]
    rintro _ ⟨y, rfl⟩
    have hx' : V x = x := hx
    have hr : (((1 - U : Lp ℝ 2 μ →L[ℝ] Lp ℝ 2 μ) : Lp ℝ 2 μ →ₗ[ℝ] Lp ℝ 2 μ) y) = y - V y := rfl
    have hi := V.inner_map_map y x
    rw [hx'] at hi
    rw [hr, inner_sub_left, hi, sub_self]
  · intro x hx
    rw [Submodule.mem_orthogonal] at hx
    have hy : ∀ y, inner ℝ (U y) x = inner ℝ y x := by
      intro y
      have := hx _ ⟨y, rfl⟩
      have hr : (((1 - U : Lp ℝ 2 μ →L[ℝ] Lp ℝ 2 μ) : Lp ℝ 2 μ →ₗ[ℝ] Lp ℝ 2 μ) y) = y - U y := rfl
      rw [hr, inner_sub_left, sub_eq_zero] at this
      exact this.symm
    show U x = x
    refine eq_of_norm_le_re_inner_eq_norm_sq (𝕜 := ℝ) ?_ ?_
    · rw [hUV, LinearIsometry.norm_map]
    · rw [hy x, RCLike.re_to_real, real_inner_self_eq_norm_sq]

/-! Worked numbers from the card. The half turn acts on functions constant on the four quarters
`[0,1/4), [1/4,1/2), [1/2,3/4), [3/4,1)`, stored as four values; `U v` reads quarter `q + 2`. -/

-- Three steps: the average of f = indicator of [0, 1/4) is 2/3 and 1/3 on the two swapped quarters.
example : birkhoffAverage ℚ (fun (v : Fin 4 → ℚ) (q : Fin 4) => v (q + 2)) id 3 ![1, 0, 0, 0]
    = ![2/3, 0, 1/3, 0] := by
  funext q; fin_cases q <;>
    norm_num [birkhoffAverage, birkhoffSum, Finset.sum_range_succ, Matrix.vecHead, Matrix.vecTail]

-- Two steps already give the limit (f + Uf)/2: 1/2 on [0, 1/4) and on [1/2, 3/4).
example : birkhoffAverage ℚ (fun (v : Fin 4 → ℚ) (q : Fin 4) => v (q + 2)) id 2 ![1, 0, 0, 0]
    = ![1/2, 0, 1/2, 0] := by
  funext q; fin_cases q <;>
    norm_num [birkhoffAverage, birkhoffSum, Finset.sum_range_succ, Matrix.vecHead, Matrix.vecTail]

-- The squared distance at n = 3 is 1/72 (its square root is 0.1179); the limit keeps the integral 1/4.
example : (1/4 : ℚ) * (2/3 - 1/2)^2 + (1/4) * (1/3 - 1/2)^2 = 1/72 := by norm_num
example : ((1/2 : ℚ) + 0 + 1/2 + 0) / 4 = 1/4 := by norm_num

-- 101 steps: 51/101 on [0, 1/4), off from 1/2 by 1/202.
example : (51 : ℚ) / 101 - 1/2 = 1/202 := by norm_num

-- Sums without dividing by n: the squared length of S_100 f is 1250 (its square root is 35.36).
example : (1/4 : ℚ) * (50^2 + 50^2) = 1250 := by norm_num

-- Doubling map, n = 10: the squared L2 distance is 1/40 = (1/(2 sqrt 10))^2, by the binomial sum.
example : (∑ k ∈ Finset.range 11, (Nat.choose 10 k : ℚ) * ((k : ℚ) / 10 - 1/2)^2) / 2^10
    = 1/40 := by
  simp [Finset.sum_range_succ, Nat.choose]; norm_num

#print axioms aestronglyMeasurable_invariants_of_koopman_fixed
#print axioms time_averages_tendsto_projection_onto_invariant
#print axioms projection_onto_invariant_eq_condExp_invariants
#print axioms orthogonal_invariant_eq_closure_differences
