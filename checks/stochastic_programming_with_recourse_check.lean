-- Two-stage stochastic programming: the one large linear program (the extensive form) has the same best cost and the same best now-decision as the two-stage problem, and for the card's reservoir the best plan lets out 30 million m³ at an expected cost of £220,000.
import Mathlib.Data.Matrix.Mul
import Mathlib.Order.ConditionallyCompleteLattice.Basic
import Mathlib.Algebra.Order.Archimedean.Real.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Topology.Algebra.Module.FiniteDimension
import Mathlib.Topology.Order.Monotone
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Tactic

open Matrix

theorem cone_closed_aux {ι E : Type*} [Fintype ι] [DecidableEq ι] [AddCommGroup E] [Module ℝ E]
    [TopologicalSpace E] [IsTopologicalAddGroup E] [ContinuousSMul ℝ E] [T2Space E]
    (L : (ι → ℝ) →ₗ[ℝ] E) (S : Finset ι) :
    IsClosed (L '' {μ | 0 ≤ μ ∧ ∀ i ∉ S, μ i = 0}) := by
  induction S using Finset.strongInduction with
  | H S ih =>
  by_cases hind : ∀ μ : ι → ℝ, (∀ i ∉ S, μ i = 0) → L μ = 0 → μ = 0
  · let V : Submodule ℝ (ι → ℝ) :=
      { carrier := {μ | ∀ i ∉ S, μ i = 0}
        add_mem' := by
          intro a b ha hb i hi
          simp [ha i hi, hb i hi]
        zero_mem' := by intro i _; rfl
        smul_mem' := by
          intro c a ha i hi
          simp [ha i hi] }
    have hker : LinearMap.ker (L.domRestrict V) = ⊥ := by
      rw [LinearMap.ker_eq_bot']
      intro v hv
      exact Subtype.ext (hind v v.2 hv)
    have hemb := LinearMap.isClosedEmbedding_of_injective hker
    have hcl : IsClosed {v : V | 0 ≤ (v : ι → ℝ)} :=
      isClosed_le continuous_const continuous_subtype_val
    have := hemb.isClosedMap _ hcl
    convert this using 1
    ext x
    constructor
    · rintro ⟨μ, ⟨h0, hS⟩, rfl⟩
      exact ⟨⟨μ, hS⟩, h0, rfl⟩
    · rintro ⟨v, hv, rfl⟩
      exact ⟨v, ⟨hv, v.2⟩, rfl⟩
  · push Not at hind
    obtain ⟨g0, hg0S, hLg0, hg0⟩ := hind
    obtain ⟨j0, hj0⟩ : ∃ j, g0 j ≠ 0 := by
      by_contra hc
      push Not at hc
      exact hg0 (funext hc)
    -- choose a sign so that some coordinate is positive
    obtain ⟨g, hgS, hLg, j1, hj1⟩ : ∃ g : ι → ℝ, (∀ i ∉ S, g i = 0) ∧ L g = 0 ∧
        ∃ j, 0 < g j := by
      rcases lt_or_gt_of_ne hj0 with h | h
      · refine ⟨-g0, fun i hi => by simp [hg0S i hi], by simp [hLg0], j0, by simp; linarith⟩
      · exact ⟨g0, hg0S, hLg0, j0, h⟩
    have hj1S : j1 ∈ S := by
      by_contra hc
      rw [hgS j1 hc] at hj1
      exact lt_irrefl _ hj1
    let P := S.filter (fun i => 0 < g i)
    have hP : P.Nonempty := ⟨j1, Finset.mem_filter.mpr ⟨hj1S, hj1⟩⟩
    have key : L '' {μ | 0 ≤ μ ∧ ∀ i ∉ S, μ i = 0} =
        ⋃ j ∈ P, L '' {μ | 0 ≤ μ ∧ ∀ i ∉ S.erase j, μ i = 0} := by
      ext x
      simp only [Set.mem_iUnion, Set.mem_image, Set.mem_ofPred_eq]
      constructor
      · rintro ⟨μ, ⟨h0, hS⟩, rfl⟩
        obtain ⟨j, hjP, hjmin⟩ := P.exists_min_image (fun i => μ i / g i) hP
        have hjP' := Finset.mem_filter.mp hjP
        set t := μ j / g j with ht
        have ht0 : 0 ≤ t := div_nonneg (h0 j) hjP'.2.le
        refine ⟨j, hjP, μ - t • g, ⟨?_, ?_⟩, ?_⟩
        · intro i
          simp only [Pi.zero_apply, Pi.sub_apply, Pi.smul_apply, smul_eq_mul]
          by_cases hgi : 0 < g i
          · have hiS : i ∈ S := by
              by_contra hc
              rw [hgS i hc] at hgi
              exact lt_irrefl _ hgi
            have := hjmin i (Finset.mem_filter.mpr ⟨hiS, hgi⟩)
            rw [le_div_iff₀ hgi] at this
            linarith
          · push Not at hgi
            have := h0 i
            have : t * g i ≤ 0 := mul_nonpos_of_nonneg_of_nonpos ht0 hgi
            simp only [Pi.zero_apply] at *
            linarith
        · intro i hi
          simp only [Pi.sub_apply, Pi.smul_apply, smul_eq_mul]
          by_cases hij : i = j
          · subst hij
            rw [ht]
            field_simp [hjP'.2.ne']
            ring
          · have hiS : i ∉ S := fun h => hi (Finset.mem_erase.mpr ⟨hij, h⟩)
            simp [hS i hiS, hgS i hiS]
        · simp [map_sub, map_smul, hLg]
      · rintro ⟨j, _, μ, ⟨h0, hS⟩, rfl⟩
        exact ⟨μ, ⟨h0, fun i hi => hS i (fun h => hi (Finset.mem_of_mem_erase h))⟩, rfl⟩
    rw [key]
    refine isClosed_biUnion_finset fun j hj => ih _ ?_
    exact Finset.erase_ssubset (Finset.mem_filter.mp hj).1

theorem lp_attains {m k : ℕ} (q : Fin m → ℝ) (W : Matrix (Fin k) (Fin m) ℝ) (d b : Fin k → ℝ)
    (hne : {y : Fin m → ℝ | 0 ≤ y ∧ b ≤ d + W *ᵥ y}.Nonempty)
    (hbdd : BddBelow ((fun y => q ⬝ᵥ y) '' {y : Fin m → ℝ | 0 ≤ y ∧ b ≤ d + W *ᵥ y})) :
    ∃ y ∈ {y : Fin m → ℝ | 0 ≤ y ∧ b ≤ d + W *ᵥ y},
      ∀ y' ∈ {y : Fin m → ℝ | 0 ≤ y ∧ b ≤ d + W *ᵥ y}, q ⬝ᵥ y ≤ q ⬝ᵥ y' := by
  classical
  let L : (Fin m ⊕ Fin k → ℝ) →ₗ[ℝ] ℝ × (Fin k → ℝ) :=
    { toFun := fun μ => (q ⬝ᵥ (fun j => μ (Sum.inl j)),
        W *ᵥ (fun j => μ (Sum.inl j)) - fun i => μ (Sum.inr i))
      map_add' := by
        intro a b
        have e : (fun j => (a + b) (Sum.inl j)) =
            (fun j => a (Sum.inl j)) + (fun j => b (Sum.inl j)) := rfl
        have e2 : (fun i => (a + b) (Sum.inr i)) =
            (fun i => a (Sum.inr i)) + (fun i => b (Sum.inr i)) := rfl
        rw [e, e2, dotProduct_add, Matrix.mulVec_add, Prod.mk_add_mk]
        congr 1
        abel
      map_smul' := by
        intro c a
        have e : (fun j => (c • a) (Sum.inl j)) = c • (fun j => a (Sum.inl j)) := rfl
        have e2 : (fun i => (c • a) (Sum.inr i)) = c • (fun i => a (Sum.inr i)) := rfl
        rw [e, e2, dotProduct_smul, Matrix.mulVec_smul, RingHom.id_apply, Prod.smul_mk, smul_sub] }
  have hC := cone_closed_aux L Finset.univ
  set Pset := {y : Fin m → ℝ | 0 ≤ y ∧ b ≤ d + W *ᵥ y} with hPset
  let T : Set ℝ := (fun τ : ℝ => (τ, b - d)) ⁻¹' (L '' {μ | 0 ≤ μ ∧ ∀ i ∉ Finset.univ, μ i = 0})
  have hTcl : IsClosed T := hC.preimage (continuous_id.prodMk continuous_const)
  have hmemT : ∀ y ∈ Pset, q ⬝ᵥ y ∈ T := by
    rintro y ⟨hy0, hyb⟩
    refine ⟨Sum.elim y (d + W *ᵥ y - b), ⟨?_, by simp⟩, ?_⟩
    · intro i
      cases i with
      | inl j => exact hy0 j
      | inr i => simpa using hyb i
    · refine Prod.ext rfl ?_
      ext i
      simp [L]
      ring
  have hTsub : ∀ τ ∈ T, ∃ y ∈ Pset, q ⬝ᵥ y = τ := by
    rintro τ ⟨μ, ⟨h0, -⟩, hμ⟩
    simp only [L, LinearMap.coe_mk, AddHom.coe_mk, Prod.mk.injEq] at hμ
    refine ⟨fun j => μ (Sum.inl j), ⟨fun j => h0 (Sum.inl j), ?_⟩, hμ.1⟩
    intro i
    have h2 := congrFun hμ.2 i
    have h3 := h0 (Sum.inr i)
    simp only [Pi.sub_apply, Pi.zero_apply] at h2 h3
    simp only [Pi.add_apply]
    linarith
  obtain ⟨y0, hy0⟩ := hne
  have hTne : T.Nonempty := ⟨_, hmemT y0 hy0⟩
  have hTbdd : BddBelow T := by
    obtain ⟨B, hB⟩ := hbdd
    refine ⟨B, fun τ hτ => ?_⟩
    obtain ⟨y, hy, rfl⟩ := hTsub τ hτ
    exact hB ⟨y, hy, rfl⟩
  obtain ⟨y, hy, hyq⟩ := hTsub _ (hTcl.csInf_mem hTne hTbdd)
  refine ⟨y, hy, fun y' hy' => ?_⟩
  rw [hyq]
  exact csInf_le hTbdd (hmemT y' hy')

namespace TwoStage

variable {σ : Type*} {n m k : ℕ}

/-- The repairs allowed in scenario `s` once the now-decision `x` is fixed: recourse amounts
`y ≥ 0` with `T x + W y ≥ h s` (the card's `W y ≥ h_s - T x`). -/
def recourseSet (W : Matrix (Fin k) (Fin m) ℝ) (T : Matrix (Fin k) (Fin n) ℝ)
    (h : σ → Fin k → ℝ) (x : Fin n → ℝ) (s : σ) : Set (Fin m → ℝ) :=
  {y | 0 ≤ y ∧ h s ≤ T *ᵥ x + W *ᵥ y}

/-- The recourse cost `Q(x, s)`: the cheapest repair in scenario `s`, given `x`. -/
noncomputable def Q (q : Fin m → ℝ) (W : Matrix (Fin k) (Fin m) ℝ)
    (T : Matrix (Fin k) (Fin n) ℝ) (h : σ → Fin k → ℝ) (x : Fin n → ℝ) (s : σ) : ℝ :=
  sInf ((fun y => q ⬝ᵥ y) '' recourseSet W T h x s)

/-- The two-stage objective: now-cost plus the chance-weighted cheapest repairs,
`cᵀx + Σ_s p_s Q(x, s)`. -/
noncomputable def twoStageCost [Fintype σ] (p : σ → ℝ) (c : Fin n → ℝ) (q : Fin m → ℝ)
    (W : Matrix (Fin k) (Fin m) ℝ) (T : Matrix (Fin k) (Fin n) ℝ) (h : σ → Fin k → ℝ)
    (x : Fin n → ℝ) : ℝ :=
  c ⬝ᵥ x + ∑ s, p s * Q q W T h x s

/-- The extensive form's objective: one shared `x`, one copy `y s` of the repair per leaf,
`cᵀx + Σ_s p_s qᵀy_s`. -/
def extensiveCost [Fintype σ] (p : σ → ℝ) (c : Fin n → ℝ) (q : Fin m → ℝ)
    (x : Fin n → ℝ) (y : σ → Fin m → ℝ) : ℝ :=
  c ⬝ᵥ x + ∑ s, p s * (q ⬝ᵥ y s)

/-- A point of the extensive form is allowed when the shared `x` is an allowed now-decision
and every leaf's copy `y s` meets that leaf's rows `T x + W y_s ≥ h_s`, `y_s ≥ 0`. -/
def extensiveFeasible (X : Set (Fin n → ℝ)) (W : Matrix (Fin k) (Fin m) ℝ)
    (T : Matrix (Fin k) (Fin n) ℝ) (h : σ → Fin k → ℝ)
    (x : Fin n → ℝ) (y : σ → Fin m → ℝ) : Prop :=
  x ∈ X ∧ ∀ s, y s ∈ recourseSet W T h x s

theorem Q_le_of_mem (q : Fin m → ℝ) (W : Matrix (Fin k) (Fin m) ℝ)
    (T : Matrix (Fin k) (Fin n) ℝ) (h : σ → Fin k → ℝ) (x : Fin n → ℝ) (s : σ)
    (hb : BddBelow ((fun y => q ⬝ᵥ y) '' recourseSet W T h x s))
    (y : Fin m → ℝ) (hy : y ∈ recourseSet W T h x s) : Q q W T h x s ≤ q ⬝ᵥ y :=
  csInf_le hb ⟨y, hy, rfl⟩

theorem twoStage_le_extensive [Fintype σ] (p : σ → ℝ) (hp : ∀ s, 0 ≤ p s)
    (X : Set (Fin n → ℝ)) (c : Fin n → ℝ) (q : Fin m → ℝ)
    (W : Matrix (Fin k) (Fin m) ℝ) (T : Matrix (Fin k) (Fin n) ℝ) (h : σ → Fin k → ℝ)
    (hfinite : ∀ x ∈ X, ∀ s, BddBelow ((fun y => q ⬝ᵥ y) '' recourseSet W T h x s))
    (x : Fin n → ℝ) (y : σ → Fin m → ℝ) (hf : extensiveFeasible X W T h x y) :
    twoStageCost p c q W T h x ≤ extensiveCost p c q x y := by
  unfold twoStageCost extensiveCost
  gcongr with s
  · exact hp s
  · exact Q_le_of_mem q W T h x s (hfinite x hf.1 s) (y s) (hf.2 s)

theorem exists_extensive_eq_twoStage [Fintype σ] (p : σ → ℝ)
    (X : Set (Fin n → ℝ)) (c : Fin n → ℝ) (q : Fin m → ℝ)
    (W : Matrix (Fin k) (Fin m) ℝ) (T : Matrix (Fin k) (Fin n) ℝ) (h : σ → Fin k → ℝ)
    (hrepair : ∀ x ∈ X, ∀ s, (recourseSet W T h x s).Nonempty)
    (hfinite : ∀ x ∈ X, ∀ s, BddBelow ((fun y => q ⬝ᵥ y) '' recourseSet W T h x s))
    (x : Fin n → ℝ) (hx : x ∈ X) :
    ∃ y, extensiveFeasible X W T h x y ∧
      extensiveCost p c q x y = twoStageCost p c q W T h x := by
  have hmin : ∀ s, ∃ y ∈ recourseSet W T h x s, ∀ y' ∈ recourseSet W T h x s,
      q ⬝ᵥ y ≤ q ⬝ᵥ y' := fun s =>
    lp_attains q W (T *ᵥ x) (h s) (hrepair x hx s) (hfinite x hx s)
  choose y hy hymin using hmin
  refine ⟨y, ⟨hx, hy⟩, ?_⟩
  unfold extensiveCost twoStageCost
  congr 1
  refine Finset.sum_congr rfl fun s _ => ?_
  congr 1
  symm
  exact (show IsLeast ((fun y => q ⬝ᵥ y) '' recourseSet W T h x s) (q ⬝ᵥ y s) from
    ⟨⟨y s, hy s, rfl⟩, by rintro _ ⟨y', hy', rfl⟩; exact hymin s y' hy'⟩).csInf_eq

/-- The extensive form equals the two-stage problem (value). Take finitely many scenarios with
chances `p s ≥ 0` adding to 1, an allowed set `X` of now-decisions, and linear costs and rows.
Suppose every leaf has a repair whatever allowed `x` is chosen, and every repair cost `Q(x, s)`
is finite (the leaf's costs are bounded below). Then the one large linear program over
`(x, y_1, …, y_S)` and the two-stage problem `min_x cᵀx + Σ_s p_s Q(x, s)` are bounded below
together, and they have the same best value. -/
theorem extensive_form_value_eq_two_stage_value [Fintype σ]
    (p : σ → ℝ) (hp : ∀ s, 0 ≤ p s) (hsum : ∑ s, p s = 1)
    (X : Set (Fin n → ℝ)) (c : Fin n → ℝ) (q : Fin m → ℝ)
    (W : Matrix (Fin k) (Fin m) ℝ) (T : Matrix (Fin k) (Fin n) ℝ) (h : σ → Fin k → ℝ)
    (hrepair : ∀ x ∈ X, ∀ s, (recourseSet W T h x s).Nonempty)
    (hfinite : ∀ x ∈ X, ∀ s, BddBelow ((fun y => q ⬝ᵥ y) '' recourseSet W T h x s)) :
    (BddBelow {v | ∃ x y, extensiveFeasible X W T h x y ∧ v = extensiveCost p c q x y} ↔
        BddBelow (twoStageCost p c q W T h '' X)) ∧
      sInf {v | ∃ x y, extensiveFeasible X W T h x y ∧ v = extensiveCost p c q x y} =
        sInf (twoStageCost p c q W T h '' X) := by
  classical
  set E := {v | ∃ x y, extensiveFeasible X W T h x y ∧ v = extensiveCost p c q x y} with hE
  set S := twoStageCost p c q W T h '' X with hS
  have hSE : S ⊆ E := by
    rintro _ ⟨x, hx, rfl⟩
    obtain ⟨y, hy, hyeq⟩ := exists_extensive_eq_twoStage p X c q W T h hrepair hfinite x hx
    exact ⟨x, y, hy, hyeq.symm⟩
  have hES : ∀ e ∈ E, ∃ s ∈ S, s ≤ e := by
    rintro _ ⟨x, y, hf, rfl⟩
    exact ⟨_, ⟨x, hf.1, rfl⟩, twoStage_le_extensive p hp X c q W T h hfinite x y hf⟩
  have hlb : lowerBounds E = lowerBounds S := by
    ext B
    constructor
    · intro hB s hs
      exact hB (hSE hs)
    · intro hB e he
      obtain ⟨s, hs, hse⟩ := hES e he
      exact (hB hs).trans hse
  have hbdd : BddBelow E ↔ BddBelow S := by
    unfold BddBelow
    rw [hlb]
  refine ⟨hbdd, ?_⟩
  rcases X.eq_empty_or_nonempty with hX | hX
  · have hS0 : S = ∅ := by rw [hS, hX, Set.image_empty]
    have hE0 : E = ∅ := by
      apply Set.eq_empty_of_forall_notMem
      intro e he
      obtain ⟨s, hs, -⟩ := hES e he
      rw [hS0] at hs
      exact hs
    rw [hS0, hE0]
  · have hSne : S.Nonempty := hX.image _
    have hEne : E.Nonempty := hSne.mono hSE
    by_cases hB : BddBelow S
    · have hBE : BddBelow E := hbdd.mpr hB
      apply le_antisymm
      · exact le_csInf hSne fun s hs => csInf_le hBE (hSE hs)
      · refine le_csInf hEne fun e he => ?_
        obtain ⟨s, hs, hse⟩ := hES e he
        exact (csInf_le hB hs).trans hse
    · rw [Real.sInf_of_not_bddBelow hB, Real.sInf_of_not_bddBelow (fun h' => hB (hbdd.mp h'))]

/-- The extensive form and the two-stage problem have the same best now-decision. Under the
same conditions, an allowed `x` is best for the two-stage problem exactly when it is the shared
now-decision of some best point `(x, y_1, …, y_S)` of the one large linear program. -/
theorem same_best_now_decision [Fintype σ]
    (p : σ → ℝ) (hp : ∀ s, 0 ≤ p s) (hsum : ∑ s, p s = 1)
    (X : Set (Fin n → ℝ)) (c : Fin n → ℝ) (q : Fin m → ℝ)
    (W : Matrix (Fin k) (Fin m) ℝ) (T : Matrix (Fin k) (Fin n) ℝ) (h : σ → Fin k → ℝ)
    (hrepair : ∀ x ∈ X, ∀ s, (recourseSet W T h x s).Nonempty)
    (hfinite : ∀ x ∈ X, ∀ s, BddBelow ((fun y => q ⬝ᵥ y) '' recourseSet W T h x s))
    (x : Fin n → ℝ) (hx : x ∈ X) :
    (∀ x' ∈ X, twoStageCost p c q W T h x ≤ twoStageCost p c q W T h x') ↔
      ∃ y, extensiveFeasible X W T h x y ∧
        ∀ x' y', extensiveFeasible X W T h x' y' →
          extensiveCost p c q x y ≤ extensiveCost p c q x' y' := by
  constructor
  · intro hopt
    obtain ⟨y, hy, hyeq⟩ := exists_extensive_eq_twoStage p X c q W T h hrepair hfinite x hx
    refine ⟨y, hy, fun x' y' hf' => ?_⟩
    rw [hyeq]
    exact (hopt x' hf'.1).trans (twoStage_le_extensive p hp X c q W T h hfinite x' y' hf')
  · rintro ⟨y, hy, hymin⟩ x' hx'
    obtain ⟨y', hy', hyeq'⟩ := exists_extensive_eq_twoStage p X c q W T h hrepair hfinite x' hx'
    calc twoStageCost p c q W T h x ≤ extensiveCost p c q x y :=
          twoStage_le_extensive p hp X c q W T h hfinite x y hy
      _ ≤ extensiveCost p c q x' y' := hymin x' y' hy'
      _ = twoStageCost p c q W T h x' := hyeq'

end TwoStage

namespace Reservoir

/-- November rain in million m³: dry, normal, wet. -/
def rain : Fin 3 → ℝ := ![10, 30, 90]

/-- The chances of a dry, normal and wet month. -/
noncomputable def chance : Fin 3 → ℝ := ![3 / 10, 1 / 2, 1 / 5]

/-- End-of-November level in scenario `s`: 70 in store, plus rain, minus `x` let out now, minus
what the turbine ran (`20 - g s`), minus overflow `f s`. -/
def level (x : ℝ) (g f : Fin 3 → ℝ) (s : Fin 3) : ℝ :=
  70 + rain s - x - (20 - g s) - f s

/-- The extensive form's rows: `0 ≤ x ≤ 70`; in each leaf `g, f, b ≥ 0`, level at most 100
(room), level plus shortfall at least 50 (reserve), `g ≤ 20` (turbine), level at least 0. -/
def feasible (x : ℝ) (g f b : Fin 3 → ℝ) : Prop :=
  0 ≤ x ∧ x ≤ 70 ∧
    ∀ s, 0 ≤ g s ∧ 0 ≤ f s ∧ 0 ≤ b s ∧ level x g f s ≤ 100 ∧
      50 ≤ level x g f s + b s ∧ g s ≤ 20 ∧ 0 ≤ level x g f s

/-- Expected cost in thousand pounds: 2 per million m³ let out now, then per leaf 10 per
million m³ of power bought, 50 per million m³ of overflow, 30 per million m³ below the reserve. -/
noncomputable def cost (x : ℝ) (g f b : Fin 3 → ℝ) : ℝ :=
  2 * x + ∑ s, chance s * (10 * g s + 50 * f s + 30 * b s)

/-- The card's answer for the reservoir: letting out 30 million m³ now, then buying power for 20
in a dry month, doing nothing in a normal month and overflowing 10 in a wet month, is an allowed
plan with expected cost 220 (£220,000); no allowed plan costs less; and every best plan lets out
exactly 30. -/
theorem reservoir_best_release_30_expected_cost_220 :
    feasible 30 ![20, 0, 0] ![0, 0, 10] ![0, 0, 0] ∧
      cost 30 ![20, 0, 0] ![0, 0, 10] ![0, 0, 0] = 220 ∧
      (∀ x g f b, feasible x g f b → 220 ≤ cost x g f b) ∧
      (∀ x g f b, feasible x g f b → cost x g f b = 220 → x = 30) := by
  refine ⟨?_, ?_, ?_, ?_⟩
  · refine ⟨by norm_num, by norm_num, ?_⟩
    intro s
    fin_cases s <;> simp [level, rain] <;> norm_num
  · simp [cost, chance, Fin.sum_univ_three]
    norm_num
  · rintro x g f b ⟨hx0, hx70, hs⟩
    obtain ⟨a1, a2, a3, a4, a5, a6, a7⟩ := hs 0
    obtain ⟨b1, b2, b3, b4, b5, b6, b7⟩ := hs 1
    obtain ⟨c1, c2, c3, c4, c5, c6, c7⟩ := hs 2
    simp [level, rain] at a4 a5 a7 b4 b5 b7 c4 c5 c7
    simp [cost, chance, Fin.sum_univ_three]
    linarith
  · rintro x g f b ⟨hx0, hx70, hs⟩ hcost
    obtain ⟨a1, a2, a3, a4, a5, a6, a7⟩ := hs 0
    obtain ⟨b1, b2, b3, b4, b5, b6, b7⟩ := hs 1
    obtain ⟨c1, c2, c3, c4, c5, c6, c7⟩ := hs 2
    simp [level, rain] at a4 a5 a7 b4 b5 b7 c4 c5 c7
    simp [cost, chance, Fin.sum_univ_three] at hcost
    apply le_antisymm <;> linarith

/-- The card's repair rule for `L` million m³ on hand after the rain (in whole numbers): run the
turbine up to 20 without dipping below the 50 reserve, buy the rest of the power at 10, pay 50
per million m³ still over 100 and 30 per million m³ below 50. -/
def repair (L : ℤ) : ℤ :=
  let run := max 0 (min 20 (L - 50))
  10 * (20 - run) + 50 * max 0 (L - run - 100) + 30 * max 0 (50 - L)

/-- Ten times the expected cost of letting out `x` now (chances 3/10, 1/2, 1/5 become 3, 5, 2),
kept in whole numbers. -/
def tenTimesExpected (x : ℤ) : ℤ :=
  10 * (2 * x) + 3 * repair (70 + 10 - x) + 5 * repair (70 + 30 - x) + 2 * repair (70 + 90 - x)

end Reservoir

open Reservoir in
-- Worked numbers at x = 30: gates 60; water on hand 50, 70, 130; repairs 200, 0, 500.
example : 2 * 30 = 60 ∧ 70 + 10 - 30 = 50 ∧ 70 + 30 - 30 = 70 ∧ 70 + 90 - 30 = 130 := by decide
open Reservoir in
example : repair 50 = 200 ∧ repair 70 = 0 ∧ repair 130 = 500 := by decide
-- Expected repair 3/10 × 200 + 1/2 × 0 + 1/5 × 500 = 160, and 60 + 160 = 220.
example : (3 / 10 : ℚ) * 200 + 1 / 2 * 0 + 1 / 5 * 500 = 160 ∧ (60 : ℚ) + 160 = 220 := by norm_num
open Reservoir in
-- The expected cost at x = 30 is 220; its neighbours at x = 20 and 40 cost 270 and 280.
example : tenTimesExpected 30 = 2200 ∧ tenTimesExpected 20 = 2700 ∧ tenTimesExpected 40 = 2800 := by
  decide
open Reservoir in
-- The chart: expected cost at x = 0, 5, …, 60 is 400, 360, 320, 295, 270, 245, 220, 250, 280, 360, 440, 570, 700.
example : (List.range 13).map (fun i => tenTimesExpected (5 * i)) =
    [4000, 3600, 3200, 2950, 2700, 2450, 2200, 2500, 2800, 3600, 4400, 5700, 7000] := by decide
open Reservoir in
-- Road 3: scanning every whole x from 0 to 70, nothing beats 220.
example : ∀ x : Fin 71, 2200 ≤ tenTimesExpected x := by decide
-- The dual bound: prices 8, 5, 10 on rows with right-hand sides -10, -20, 40 give 220; in the x
-- column, 2 for the gates plus 8 from the dry reserve row equals 10 from the wet room row.
example : 8 * (-10) + 5 * (-20) + 10 * 40 = (220 : ℤ) ∧ 2 + 8 = 10 := by decide
-- Average rain 3/10 × 10 + 1/2 × 30 + 1/5 × 90 = 36.
example : (3 / 10 : ℚ) * 10 + 1 / 2 * 30 + 1 / 5 * 90 = 36 := by norm_num
open Reservoir in
-- The average-rain plan lets out nothing: its real expected cost EEV is 400.
example : tenTimesExpected 0 = 4000 := by decide
open Reservoir in
-- Wait-and-see: a clairvoyant pays 0 in a dry or normal month and 80 in a wet one (x = 40);
-- WS = 1/5 × 80 = 16.
example : repair (70 + 10 - 0) = 0 ∧ repair (70 + 30 - 0) = 0 ∧ 2 * 40 + repair (70 + 90 - 40) = 80 := by
  decide
example : (3 / 10 : ℚ) * 0 + 1 / 2 * 0 + 1 / 5 * 80 = 16 := by norm_num
-- VSS = 400 - 220 = 180, EVPI = 220 - 16 = 204, and 16 ≤ 220 ≤ 400.
example : 400 - 220 = 180 ∧ 220 - 16 = 204 ∧ 16 ≤ 220 ∧ 220 ≤ 400 := by decide
open Reservoir in
-- Averaging the clairvoyant plans, 1/5 × 40 = 8, costs 336.
example : tenTimesExpected 8 = 3360 := by decide
-- A year of monthly decisions with three kinds of month gives 3 ^ 12 = 531441 leaves.
example : 3 ^ 12 = 531441 := by norm_num

open TwoStage Reservoir

#print axioms extensive_form_value_eq_two_stage_value
#print axioms same_best_now_decision
#print axioms reservoir_best_release_30_expected_cost_220
#print axioms cone_closed_aux
#print axioms lp_attains
#print axioms Q_le_of_mem
#print axioms twoStage_le_extensive
#print axioms exists_extensive_eq_twoStage
