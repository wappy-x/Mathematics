-- Representations: a finite group's representation over the complex numbers splits into irreducible kept pieces, because averaging a projection over the group gives every kept subspace a kept partner.
import Mathlib.RepresentationTheory.Maschke
import Mathlib.LinearAlgebra.FiniteDimensional.Defs
import Mathlib.Algebra.DirectSum.Module
import Mathlib.Basic.Complex.Basic
import Mathlib.Data.Matrix.Mul
import Mathlib.LinearAlgebra.Matrix.Notation

open scoped BigOperators

theorem avg_proj_aux
    {k G V : Type*} [Field k] [Group G] [Fintype G] [AddCommGroup V] [Module k V]
    (ρ : Representation k G V) (hG : (Fintype.card G : k) ≠ 0)
    (W : Submodule k V) (hW : ∀ g : G, ∀ v ∈ W, ρ g v ∈ W)
    (P : V →ₗ[k] V) (hPW : ∀ v, P v ∈ W) (hPfix : ∀ w ∈ W, P w = w) :
    let Pavg : V →ₗ[k] V := (Fintype.card G : k)⁻¹ • ∑ g : G, ρ g ∘ₗ P ∘ₗ ρ g⁻¹
    (∀ h : G, ρ h ∘ₗ Pavg = Pavg ∘ₗ ρ h) ∧ (∀ v, Pavg v ∈ W) ∧ (∀ w ∈ W, Pavg w = w) := by
  intro Pavg
  have hfix : ∀ w ∈ W, ∀ g : G, (ρ g ∘ₗ P ∘ₗ ρ g⁻¹) w = w := by
    intro w hw g
    simp only [LinearMap.comp_apply]
    rw [hPfix _ (hW _ _ hw), ← Module.End.mul_apply, ← map_mul, mul_inv_cancel, map_one,
      Module.End.one_apply]
  refine ⟨?_, ?_, ?_⟩
  · intro h
    ext v
    simp only [Pavg, LinearMap.comp_apply, LinearMap.smul_apply, LinearMap.sum_apply, map_smul,
      map_sum]
    congr 1
    have hinv : ∀ x, ρ h⁻¹ (ρ h x) = x := fun x => by
      rw [← Module.End.mul_apply, ← map_mul, inv_mul_cancel, map_one, Module.End.one_apply]
    conv_rhs => rw [← Equiv.sum_comp (Equiv.mulLeft h)]
    refine Finset.sum_congr rfl fun g _ => ?_
    simp only [Equiv.coe_mulLeft, mul_inv_rev, map_mul, Module.End.mul_apply, hinv]
  · intro v
    simp only [Pavg, LinearMap.smul_apply, LinearMap.sum_apply]
    exact W.smul_mem _ (W.sum_mem fun g _ => hW g _ (hPW _))
  · intro w hw
    simp only [Pavg, LinearMap.smul_apply, LinearMap.sum_apply]
    rw [Finset.sum_congr rfl fun g _ => hfix w hw g, Finset.sum_const, Finset.card_univ,
      ← Nat.cast_smul_eq_nsmul k, smul_smul, inv_mul_cancel₀ hG, one_smul]

#print axioms avg_proj_aux

theorem kept_partner_aux
    {k G V : Type*} [Field k] [Group G] [Fintype G] [AddCommGroup V] [Module k V]
    (ρ : Representation k G V) (hG : (Fintype.card G : k) ≠ 0)
    (W : Submodule k V) (hW : ∀ g : G, ∀ v ∈ W, ρ g v ∈ W) :
    ∃ W' : Submodule k V, (∀ g : G, ∀ v ∈ W', ρ g v ∈ W') ∧ IsCompl W W' := by
  obtain ⟨W₀, hW₀⟩ := W.exists_isCompl
  let P : V →ₗ[k] V := W.subtype ∘ₗ W.projectionOnto W₀ hW₀
  have hPW : ∀ v, P v ∈ W := fun v => (W.projectionOnto W₀ hW₀ v).2
  have hPfix : ∀ w ∈ W, P w = w := fun w hw => by
    simp [P, Submodule.projectionOnto_apply_left hW₀ ⟨w, hw⟩]
  obtain ⟨h1, h2, h3⟩ := avg_proj_aux ρ hG W hW P hPW hPfix
  set Pavg : V →ₗ[k] V := (Fintype.card G : k)⁻¹ • ∑ g : G, ρ g ∘ₗ P ∘ₗ ρ g⁻¹ with hPavg
  refine ⟨LinearMap.ker Pavg, ?_, ?_⟩
  · intro g v hv
    rw [LinearMap.mem_ker] at hv ⊢
    have := LinearMap.congr_fun (h1 g) v
    simp only [LinearMap.comp_apply] at this
    rw [← this, hv, map_zero]
  · have := LinearMap.isCompl_of_proj (f := Pavg.codRestrict W h2) (fun x => Subtype.ext (h3 x x.2))
    rwa [LinearMap.ker_codRestrict] at this

#print axioms kept_partner_aux

/-- Maschke's theorem: for a finite group G acting by a representation ρ on a finite-dimensional
complex space V, the space is a direct sum V = W₁ ⊕ ⋯ ⊕ Wₖ of kept subspaces (each ρ(g) maps each
piece into itself), and each piece is irreducible: it is not zero, and the only kept subspaces
inside it are zero and the whole piece. -/
theorem finite_group_rep_splits_into_irreducibles
    {G V : Type*} [Group G] [Finite G] [AddCommGroup V] [Module ℂ V] [FiniteDimensional ℂ V]
    (ρ : Representation ℂ G V) :
    ∃ (k : ℕ) (W : Fin k → Submodule ℂ V),
      DirectSum.IsInternal W ∧
      ∀ i, (∀ g : G, ∀ v ∈ W i, ρ g v ∈ W i) ∧ W i ≠ ⊥ ∧
        ∀ U : Submodule ℂ V, (∀ g : G, ∀ v ∈ U, ρ g v ∈ U) → U ≤ W i → U = ⊥ ∨ U = W i := by
  classical
  have : Fintype G := Fintype.ofFinite G
  have hG : (Fintype.card G : ℂ) ≠ 0 := by exact_mod_cast Fintype.card_ne_zero
  -- induction on dimension: every kept subspace U is an independent family of irreducible pieces
  have key : ∀ (n : ℕ) (U : Submodule ℂ V), Module.finrank ℂ U = n →
      (∀ g : G, ∀ v ∈ U, ρ g v ∈ U) →
      ∃ s : Finset (Submodule ℂ V), s.SupIndep id ∧ s.sup id = U ∧
        ∀ X ∈ s, (∀ g : G, ∀ v ∈ X, ρ g v ∈ X) ∧ X ≠ ⊥ ∧
          ∀ U' : Submodule ℂ V, (∀ g : G, ∀ v ∈ U', ρ g v ∈ U') → U' ≤ X → U' = ⊥ ∨ U' = X := by
    intro n
    induction n using Nat.strong_induction_on with
    | _ n ih =>
    intro U hUn hU
    by_cases hU0 : U = ⊥
    · exact ⟨∅, Finset.supIndep_empty _, by simp [hU0], by simp⟩
    let S : Set (Submodule ℂ V) := {X | (∀ g : G, ∀ v ∈ X, ρ g v ∈ X) ∧ X ≠ ⊥ ∧ X ≤ U}
    obtain ⟨X, ⟨hXinv, hX0, hXU⟩, hXmin⟩ :=
      (measure fun X : Submodule ℂ V => Module.finrank ℂ X).wf.has_min S ⟨U, hU, hU0, le_rfl⟩
    have hXirr : ∀ U' : Submodule ℂ V, (∀ g : G, ∀ v ∈ U', ρ g v ∈ U') → U' ≤ X →
        U' = ⊥ ∨ U' = X := by
      intro U' hU' hU'X
      by_cases h0 : U' = ⊥
      · exact Or.inl h0
      · right
        by_contra hne
        exact hXmin U' ⟨hU', h0, hU'X.trans hXU⟩
          (Submodule.finrank_lt_finrank_of_lt (lt_of_le_of_ne hU'X hne))
    obtain ⟨Y, hYinv, hXY⟩ := kept_partner_aux ρ hG X hXinv
    have hU'inv : ∀ g : G, ∀ v ∈ U ⊓ Y, ρ g v ∈ U ⊓ Y := fun g v hv =>
      ⟨hU g v hv.1, hYinv g v hv.2⟩
    have hlt : U ⊓ Y < U := by
      refine lt_of_le_of_ne inf_le_left fun h => hX0 ?_
      have : X ≤ Y := hXU.trans (h ▸ inf_le_right)
      exact hXY.disjoint.eq_bot_of_le this
    obtain ⟨s, hs, hsup, hsprop⟩ := ih _ (hUn ▸ Submodule.finrank_lt_finrank_of_lt hlt)
      (U ⊓ Y) rfl hU'inv
    have hdisj : Disjoint X (s.sup id) := by
      rw [hsup]; exact hXY.disjoint.mono_right inf_le_right
    have hXs : X ∉ s := by
      intro hm
      have : X ≤ s.sup id := Finset.le_sup (f := id) hm
      exact hX0 (hdisj.eq_bot_of_le this)
    refine ⟨insert X s, hs.insert hdisj, ?_, ?_⟩
    · rw [Finset.sup_insert, hsup, id, inf_comm, ← sup_inf_assoc_of_le _ hXU, hXY.sup_eq_top,
        top_inf_eq]
    · intro Z hZ
      rcases Finset.mem_insert.mp hZ with rfl | hZ
      · exact ⟨hXinv, hX0, hXirr⟩
      · exact hsprop Z hZ
  obtain ⟨s, hs, hsup, hsprop⟩ := key _ ⊤ rfl (fun _ _ _ => Submodule.mem_top)
  let e := s.equivFin
  refine ⟨s.card, fun i => (e.symm i : Submodule ℂ V), ?_, fun i => hsprop _ (e.symm i).2⟩
  have hind : iSupIndep (id ∘ ((↑) : s → Submodule ℂ V)) := hs.independent
  apply DirectSum.isInternal_submodule_of_iSupIndep_of_iSup_eq_top
  · exact hind.comp e.symm.injective
  · rw [← hsup, Finset.sup_eq_iSup]
    rw [show (⨆ i, ((e.symm i : s) : Submodule ℂ V)) = ⨆ x : s, (x : Submodule ℂ V) from
      e.symm.iSup_comp (g := fun x : s => (x : Submodule ℂ V))]
    rw [iSup_subtype']
    rfl

/-- The splitting step: when the group is finite and its size can be divided by in the field k,
every kept subspace W has a kept partner W′, so that every vector is one member of W plus one of
W′ in exactly one way (W and W′ are complements). -/
theorem kept_subspace_has_kept_partner
    {k G V : Type*} [Field k] [Group G] [Fintype G] [AddCommGroup V] [Module k V]
    (ρ : Representation k G V) (hG : (Fintype.card G : k) ≠ 0)
    (W : Submodule k V) (hW : ∀ g : G, ∀ v ∈ W, ρ g v ∈ W) :
    ∃ W' : Submodule k V, (∀ g : G, ∀ v ∈ W', ρ g v ∈ W') ∧ IsCompl W W' := by
  exact kept_partner_aux ρ hG W hW

/-- The averaging trick: if P is a projection onto a kept subspace W (it sends every vector into W
and leaves members of W unchanged), then its average P° = (1/|G|) Σ_g ρ(g) P ρ(g)⁻¹ is still a
projection onto W and commutes with every ρ(h). -/
theorem averaged_projection_commutes
    {k G V : Type*} [Field k] [Group G] [Fintype G] [AddCommGroup V] [Module k V]
    (ρ : Representation k G V) (hG : (Fintype.card G : k) ≠ 0)
    (W : Submodule k V) (hW : ∀ g : G, ∀ v ∈ W, ρ g v ∈ W)
    (P : V →ₗ[k] V) (hPW : ∀ v, P v ∈ W) (hPfix : ∀ w ∈ W, P w = w) :
    let Pavg : V →ₗ[k] V := (Fintype.card G : k)⁻¹ • ∑ g : G, ρ g ∘ₗ P ∘ₗ ρ g⁻¹
    (∀ h : G, ρ h ∘ₗ Pavg = Pavg ∘ₗ ρ h) ∧ (∀ v, Pavg v ∈ W) ∧ (∀ w ∈ W, Pavg w = w) := by
  exact avg_proj_aux ρ hG W hW P hPW hPfix

-- The tile's heights 6, 2, 4, 0 mm split as height + twist + tilt.
example : (![3, 3, 3, 3] : Fin 4 → ℤ) + ![2, -2, 2, -2] + ![1, 1, -1, -1] = ![6, 2, 4, 0] := by
  decide

-- The three pieces meet at right angles, and their squared sizes add: 36 + 16 + 4 = 56.
example : (∑ i, (![3, 3, 3, 3] : Fin 4 → ℤ) i * ![2, -2, 2, -2] i) = 0 ∧
    (∑ i, (![3, 3, 3, 3] : Fin 4 → ℤ) i * ![1, 1, -1, -1] i) = 0 ∧
    (∑ i, (![2, -2, 2, -2] : Fin 4 → ℤ) i * ![1, 1, -1, -1] i) = 0 ∧
    (∑ i, (![3, 3, 3, 3] : Fin 4 → ℤ) i ^ 2) = 36 ∧ (∑ i, (![2, -2, 2, -2] : Fin 4 → ℤ) i ^ 2) = 16 ∧
    (∑ i, (![1, 1, -1, -1] : Fin 4 → ℤ) i ^ 2) = 4 ∧
    (36 + 16 + 4 : ℤ) = ∑ i, (![6, 2, 4, 0] : Fin 4 → ℤ) i ^ 2 := by
  decide

-- The quarter turn r1 as a corner shuffle: (6, 2, 4, 0) goes to (0, 6, 2, 4), which splits as
-- height 3, twist −2, tilt (−1, 1).
example : (!![0, 0, 0, 1; 1, 0, 0, 0; 0, 1, 0, 0; 0, 0, 1, 0] : Matrix (Fin 4) (Fin 4) ℤ).mulVec
      ![6, 2, 4, 0] = ![0, 6, 2, 4] ∧
    (![3, 3, 3, 3] : Fin 4 → ℤ) + ![-2, 2, -2, 2] + ![-1, 1, 1, -1] = ![0, 6, 2, 4] := by
  decide

-- On the tilt plane, with u = e0 − e2 and w = e1 − e3: the quarter turn sends u to w and w to −u
-- (matrix [[0, −1], [1, 0]]); the flip r0f keeps u and sends w to −w (matrix [[1, 0], [0, −1]]).
example :
    (!![0, 0, 0, 1; 1, 0, 0, 0; 0, 1, 0, 0; 0, 0, 1, 0] : Matrix (Fin 4) (Fin 4) ℤ).mulVec
      ![1, 0, -1, 0] = ![0, 1, 0, -1] ∧
    (!![0, 0, 0, 1; 1, 0, 0, 0; 0, 1, 0, 0; 0, 0, 1, 0] : Matrix (Fin 4) (Fin 4) ℤ).mulVec
      ![0, 1, 0, -1] = -![1, 0, -1, 0] ∧
    (!![1, 0, 0, 0; 0, 0, 0, 1; 0, 0, 1, 0; 0, 1, 0, 0] : Matrix (Fin 4) (Fin 4) ℤ).mulVec
      ![1, 0, -1, 0] = ![1, 0, -1, 0] ∧
    (!![1, 0, 0, 0; 0, 0, 0, 1; 0, 0, 1, 0; 0, 1, 0, 0] : Matrix (Fin 4) (Fin 4) ℤ).mulVec
      ![0, 1, 0, -1] = -![0, 1, 0, -1] := by
  decide

-- 8 times the averaged height projection is the all-2 matrix; it squares to 8 times itself.
example : (!![2, 2, 2, 2; 2, 2, 2, 2; 2, 2, 2, 2; 2, 2, 2, 2] : Matrix (Fin 4) (Fin 4) ℤ) *
      !![2, 2, 2, 2; 2, 2, 2, 2; 2, 2, 2, 2; 2, 2, 2, 2] =
    8 • !![2, 2, 2, 2; 2, 2, 2, 2; 2, 2, 2, 2; 2, 2, 2, 2] := by
  decide

#print axioms finite_group_rep_splits_into_irreducibles
#print axioms kept_subspace_has_kept_partner
#print axioms averaged_projection_commutes
