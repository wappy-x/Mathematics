-- Character tables: a finite group has as many irreducible representations as conjugacy classes and their squared dimensions add up to its size, its dimension-1 pieces number the index of its commutator subgroup, and the tile group and Q8 are different groups although they share one character table.
import Mathlib.RepresentationTheory.Character
import Mathlib.FieldTheory.IsAlgClosed.Basic
import Mathlib.Algebra.Group.ConjFinite
import Mathlib.GroupTheory.Commutator.Basic
import Mathlib.GroupTheory.Index
import Mathlib.GroupTheory.SpecificGroups.Dihedral
import Mathlib.GroupTheory.SpecificGroups.Quaternion
import Mathlib.GroupTheory.Perm.Fin
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.RepresentationTheory.FinGroupCharZero
import Mathlib.RingTheory.SimpleModule.IsAlgClosed
import Mathlib.Algebra.Central.Matrix
import Mathlib.Algebra.Central.End
import Mathlib.Algebra.Algebra.Subalgebra.Pi
import Mathlib.GroupTheory.FiniteAbelian.Duality
import Mathlib.RingTheory.RootsOfUnity.AlgebraicallyClosed

open CategoryTheory

namespace CharacterTables

theorem mem_center_monoidAlgebra_iff {k G : Type} [Field k] [Group G] (x : MonoidAlgebra k G) :
    x ∈ Subalgebra.center k (MonoidAlgebra k G) ↔
      ∀ g h : G, x.coeff (h * g * h⁻¹) = x.coeff g := by
  rw [Subalgebra.mem_center_iff]
  constructor
  · intro hx g h
    have := congrArg (fun y => y.coeff (h * g)) (hx (MonoidAlgebra.single h 1))
    simp at this
    simpa [mul_assoc] using this.symm
  · intro hx a
    induction a using MonoidAlgebra.induction_linear with
    | zero => simp
    | add a b ha hb => rw [add_mul, mul_add, ha, hb]
    | single m r =>
      ext y
      have := hx (m⁻¹ * y) m
      simp only [mul_inv_cancel_left] at this
      simp [this, mul_comm]

#print axioms mem_center_monoidAlgebra_iff

theorem finrank_center_monoidAlgebra {k G : Type} [Field k] [Group G] [Finite G] :
    Module.finrank k (Subalgebra.center k (MonoidAlgebra k G)) = Nat.card (ConjClasses G) := by
  classical
  have := Fintype.ofFinite G
  let ψ : (ConjClasses G → k) →ₗ[k] MonoidAlgebra k G :=
    (MonoidAlgebra.coeffLinearEquiv k).symm.toLinearMap ∘ₗ
      (Finsupp.linearEquivFunOnFinite k k G).symm.toLinearMap ∘ₗ
      LinearMap.funLeft k k ConjClasses.mk
  have hψ : ∀ f g, (ψ f).coeff g = f (ConjClasses.mk g) := fun f g => rfl
  have hinj : Function.Injective ψ := by
    intro f f' h
    funext c
    obtain ⟨g, rfl⟩ := ConjClasses.mk_surjective c
    have := congrArg (fun y => y.coeff g) h
    simpa only [hψ] using this
  have hrange : LinearMap.range ψ = Subalgebra.toSubmodule (Subalgebra.center k _) := by
    ext x
    simp only [LinearMap.mem_range, Subalgebra.mem_toSubmodule, mem_center_monoidAlgebra_iff]
    constructor
    · rintro ⟨f, rfl⟩ g h
      rw [hψ, hψ]
      exact congrArg f (ConjClasses.mk_eq_mk_iff_isConj.mpr (isConj_iff.mpr ⟨h, rfl⟩).symm)
    · intro hx
      refine ⟨fun c => x.coeff (Function.surjInv ConjClasses.mk_surjective c), ?_⟩
      ext g
      rw [hψ]
      set s := Function.surjInv ConjClasses.mk_surjective (ConjClasses.mk g) with hs
      have h1 := Function.surjInv_eq ConjClasses.mk_surjective (ConjClasses.mk g)
      rw [← hs, ConjClasses.mk_eq_mk_iff_isConj, isConj_iff] at h1
      obtain ⟨c, hc⟩ := h1
      show x.coeff s = x.coeff g
      rw [← hc, hx]
  rw [← Subalgebra.finrank_toSubmodule, ← hrange, LinearMap.finrank_range_of_inj hinj,
    Module.finrank_fintype_fun_eq_card, Nat.card_eq_fintype_card]

#print axioms finrank_center_monoidAlgebra

theorem finrank_center_pi_matrix {k : Type} [Field k] (n : ℕ) (d : Fin n → ℕ)
    (hd : ∀ i, NeZero (d i)) :
    Module.finrank k (Subalgebra.center k (Π i, Matrix (Fin (d i)) (Fin (d i)) k)) = n := by
  let ψ : (Fin n → k) →ₗ[k] (Π i, Matrix (Fin (d i)) (Fin (d i)) k) :=
    LinearMap.pi (fun i => (Algebra.linearMap k _) ∘ₗ LinearMap.proj i)
  have hψ : ∀ c i, ψ c i = algebraMap k _ (c i) := fun c i => rfl
  have hinj : Function.Injective ψ := by
    intro c c' h
    funext i
    have := congrFun h i
    rw [hψ, hψ] at this
    exact (algebraMap k (Matrix (Fin (d i)) (Fin (d i)) k)).injective this
  have hrange : LinearMap.range ψ = Subalgebra.toSubmodule (Subalgebra.center k _) := by
    ext z
    simp only [LinearMap.mem_range, Subalgebra.mem_toSubmodule, Subalgebra.center_pi,
      Subalgebra.mem_pi, Set.mem_univ, true_implies, Algebra.IsCentral.mem_center_iff]
    constructor
    · rintro ⟨c, rfl⟩ i
      exact ⟨c i, rfl⟩
    · intro h
      choose c hc using h
      exact ⟨c, funext fun i => (hc i).symm⟩
  rw [← Subalgebra.finrank_toSubmodule, ← hrange, LinearMap.finrank_range_of_inj hinj,
    Module.finrank_fin_fun]

#print axioms finrank_center_pi_matrix

theorem finrank_center_eq_of_algEquiv {k A B : Type} [Field k] [Ring A] [Ring B] [Algebra k A]
    [Algebra k B] (e : A ≃ₐ[k] B) :
    Module.finrank k (Subalgebra.center k A) = Module.finrank k (Subalgebra.center k B) := by
  have h : (Subalgebra.center k A).map e.toAlgHom = Subalgebra.center k B := by
    ext y
    simp only [Subalgebra.mem_map, Subalgebra.mem_center_iff]
    constructor
    · rintro ⟨x, hx, rfl⟩ b
      have := congrArg e (hx (e.symm b))
      simpa using this
    · intro hy
      refine ⟨e.symm y, fun b => ?_, by simp⟩
      have := congrArg e.symm (hy (e b))
      simpa using this
  rw [← h]
  exact (Subalgebra.equivMapOfInjective _ e.toAlgHom e.injective).toLinearEquiv.finrank_eq

#print axioms finrank_center_eq_of_algEquiv

theorem fdrep_hom_comm {k G : Type} [Field k] [Group G] {V W : FDRep k G} (f : V ⟶ W) (g : G) :
    f.hom.hom.hom ∘ₗ V.ρ g = W.ρ g ∘ₗ f.hom.hom.hom := by
  simpa using congrArg (fun x => x.hom.hom) (f.comm g)

#print axioms fdrep_hom_comm

theorem algHom_single {k G V : Type} [Field k] [Group G] [AddCommGroup V] [Module k V]
    (φ : MonoidAlgebra k G →ₐ[k] Module.End k V) (m : G) (r : k) :
    φ (MonoidAlgebra.single m r) = r • φ (MonoidAlgebra.of k G m) := by
  rw [MonoidAlgebra.of_apply, ← map_smul, MonoidAlgebra.smul_single', mul_one]

#print axioms algHom_single

theorem simple_of_surjective {k G V : Type} [Field k] [IsAlgClosed k] [Group G] [Finite G]
    [NeZero (Nat.card G : k)] [AddCommGroup V] [Module k V] [FiniteDimensional k V]
    [Nontrivial V] (φ : MonoidAlgebra k G →ₐ[k] Module.End k V) (hφ : Function.Surjective φ) :
    Simple (FDRep.of ((φ : MonoidAlgebra k G →* Module.End k V).comp (MonoidAlgebra.of k G))) := by
  set U := FDRep.of ((φ : MonoidAlgebra k G →* Module.End k V).comp (MonoidAlgebra.of k G))
  rw [FDRep.simple_iff_end_is_rank_one]
  apply le_antisymm
  · apply finrank_le_one (𝟙 U)
    intro f
    let L : V →ₗ[k] V := f.hom.hom.hom
    have hL : ∀ a, L ∘ₗ φ a = φ a ∘ₗ L := by
      intro a
      induction a using MonoidAlgebra.induction_linear with
      | zero => simp
      | add a b ha hb => rw [map_add, LinearMap.comp_add, LinearMap.add_comp, ha, hb]
      | single m r =>
        rw [algHom_single, LinearMap.comp_smul, LinearMap.smul_comp]
        congr 1
        exact fdrep_hom_comm f m
    have hc : L ∈ Subalgebra.center k (Module.End k V) := by
      rw [Subalgebra.mem_center_iff]
      intro T
      obtain ⟨a, rfl⟩ := hφ T
      exact (hL a).symm
    obtain ⟨c, hc⟩ := (Algebra.IsCentral.mem_center_iff k).mp hc
    refine ⟨c, ?_⟩
    ext x
    show c • x = L x
    rw [hc]
    simp [Algebra.algebraMap_eq_smul_one]
  · rw [Nat.one_le_iff_ne_zero, ← Nat.pos_iff_ne_zero, Module.finrank_pos_iff_exists_ne_zero]
    refine ⟨𝟙 U, fun h => ?_⟩
    obtain ⟨v, hv⟩ := exists_ne (0 : V)
    apply hv
    have := congrArg (fun f : U ⟶ U => f.hom.hom.hom v) h
    simpa using this

#print axioms simple_of_surjective

theorem not_iso_of_separating {k G V W : Type} [Field k] [Group G] [AddCommGroup V] [Module k V]
    [FiniteDimensional k V] [Nontrivial V] [AddCommGroup W] [Module k W] [FiniteDimensional k W]
    (φ : MonoidAlgebra k G →ₐ[k] Module.End k V) (ψ : MonoidAlgebra k G →ₐ[k] Module.End k W)
    (ε : MonoidAlgebra k G) (h1 : φ ε = 1) (h2 : ψ ε = 0) :
    ¬ Nonempty (FDRep.of ((φ : MonoidAlgebra k G →* Module.End k V).comp (MonoidAlgebra.of k G)) ≅
      FDRep.of ((ψ : MonoidAlgebra k G →* Module.End k W).comp (MonoidAlgebra.of k G))) := by
  rintro ⟨I⟩
  let L : V ≃ₗ[k] W := FDRep.isoToLinearEquiv I
  have hρ : ∀ g, ψ (MonoidAlgebra.of k G g) = L.conj (φ (MonoidAlgebra.of k G g)) :=
    fun g => FDRep.Iso.conj_ρ I g
  have hall : ∀ a, ψ a = L.conj (φ a) := by
    intro a
    induction a using MonoidAlgebra.induction_linear with
    | zero => simp
    | add a b ha hb => rw [map_add, map_add, map_add, ha, hb]
    | single m r => rw [algHom_single, algHom_single, map_smul, hρ]
  have h3 := hall ε
  rw [h1, h2, Module.End.one_eq_id, LinearEquiv.conj_id, ← Module.End.one_eq_id] at h3
  have : Nontrivial W := L.symm.toEquiv.nontrivial
  exact zero_ne_one h3

#print axioms not_iso_of_separating

theorem card_le_card_conjClasses {k G ι : Type} [Field k] [IsAlgClosed k] [Group G] [Fintype G]
    [Invertible (Nat.card G : k)] [Fintype ι] (U : ι → FDRep k G) [hU : ∀ i, Simple (U i)]
    (h : ∀ i j, Nonempty (U i ≅ U j) → i = j) :
    Fintype.card ι ≤ Nat.card (ConjClasses G) := by
  classical
  let v : ι → (ConjClasses G → k) :=
    fun i c => (U i).character (Function.surjInv ConjClasses.mk_surjective c)
  have hv : ∀ i x, v i (ConjClasses.mk x) = (U i).character x := by
    intro i x
    set s := Function.surjInv ConjClasses.mk_surjective (ConjClasses.mk x) with hs
    have h1 := Function.surjInv_eq ConjClasses.mk_surjective (ConjClasses.mk x)
    rw [← hs, ConjClasses.mk_eq_mk_iff_isConj, isConj_iff] at h1
    obtain ⟨c, hc⟩ := h1
    have := FDRep.char_conj (U i) s c
    rw [hc] at this
    exact this.symm
  have hli : LinearIndependent k v := by
    rw [Fintype.linearIndependent_iff]
    intro c hc b
    have hx : ∀ x : G, ∑ a, c a * (U a).character x = 0 := by
      intro x
      have := congrFun hc (ConjClasses.mk x)
      simpa [Finset.sum_apply, hv] using this
    have orth : ∀ a, (Nat.card G : k)⁻¹ * ∑ x : G, (U a).character x * (U b).character x⁻¹ =
        if a = b then 1 else 0 := by
      intro a
      rw [FDRep.char_orthonormal]
      by_cases hab : a = b
      · subst hab; simp [Nonempty.intro (Iso.refl (U a))]
      · have : ¬ Nonempty (U a ≅ U b) := fun hn => hab (h a b hn)
        simp [hab, this]
    calc c b = ∑ a, c a * (if a = b then 1 else 0) := by simp
      _ = ∑ a, ∑ x : G, (Nat.card G : k)⁻¹ * (c a * (U a).character x * (U b).character x⁻¹) := by
          refine Finset.sum_congr rfl fun a _ => ?_
          rw [← orth, Finset.mul_sum, Finset.mul_sum]
          refine Finset.sum_congr rfl fun x _ => ?_
          ring
      _ = ∑ x : G, ∑ a, (Nat.card G : k)⁻¹ * (c a * (U a).character x * (U b).character x⁻¹) :=
          Finset.sum_comm
      _ = (Nat.card G : k)⁻¹ * ∑ x : G, (∑ a, c a * (U a).character x) * (U b).character x⁻¹ := by
          rw [Finset.mul_sum]
          refine Finset.sum_congr rfl fun x _ => ?_
          rw [Finset.sum_mul, Finset.mul_sum]
      _ = 0 := by simp [hx]
  have := hli.fintype_card_le_finrank
  rw [Module.finrank_fintype_fun_eq_card] at this
  simpa only [Nat.card_eq_fintype_card] using this

#print axioms card_le_card_conjClasses

/-- If every commutator is a power of `x` and `x` itself is a commutator, then the commutator
subgroup is the subgroup generated by `x`. -/
theorem commutator_eq_zpowers_of {G : Type} [Group G] (x : G) (n : ℕ)
    (h1 : ∀ a b : G, ∃ m : Fin n, a * b * a⁻¹ * b⁻¹ = x ^ (m : ℕ)) (h2 : ∃ a b : G, a * b * a⁻¹ * b⁻¹ = x) :
    commutator G = Subgroup.zpowers x := by
  apply le_antisymm
  · rw [commutator_def, Subgroup.commutator_le]
    intro a _ b _
    obtain ⟨m, hm⟩ := h1 a b
    rw [commutatorElement_def, hm]; exact Subgroup.npow_mem_zpowers x m
  · rw [Subgroup.zpowers_le]
    obtain ⟨a, b, hab⟩ := h2
    rw [← hab, commutator_def]
    have := Subgroup.commutator_mem_commutator (Subgroup.mem_top a) (Subgroup.mem_top b)
    rwa [commutatorElement_def] at this

#print axioms commutator_eq_zpowers_of

/-- **As many irreducible pieces as conjugacy classes, and their dimensions squared add up to
the group's size.** Let `G` be a finite group and `k` a field in which every polynomial has a
root (like the complex numbers) and in which one can divide by `|G|`. Then there is a list of
irreducible (simple) finite-dimensional representations `V i` of `G` over `k`, no two of them
isomorphic, such that every irreducible representation is isomorphic to one on the list; the
list has exactly as many entries as `G` has conjugacy classes; and
`d₁² + d₂² + ⋯ + d_s² = |G|`, where `dᵢ` is the dimension of `V i`. -/
theorem irreducibles_count_classes_and_squares_sum_to_card
    {k : Type} [Field k] [IsAlgClosed k] {G : Type} [Group G] [Fintype G]
    [Invertible (Nat.card G : k)] :
    ∃ (ι : Type) (_ : Fintype ι) (V : ι → FDRep k G),
      (∀ i, Simple (V i)) ∧
      (∀ i j, Nonempty (V i ≅ V j) → i = j) ∧
      (∀ W : FDRep k G, Simple W → ∃ i, Nonempty (W ≅ V i)) ∧
      Fintype.card ι = Nat.card (ConjClasses G) ∧
      ∑ i, Module.finrank k (V i) ^ 2 = Fintype.card G := by
  classical
  have hG : NeZero (Nat.card G : k) := ⟨(isUnit_of_invertible (Nat.card G : k)).ne_zero⟩
  obtain ⟨n, d, hd, ⟨e⟩⟩ :=
    IsSemisimpleRing.exists_algEquiv_pi_matrix_of_isAlgClosed k (MonoidAlgebra k G)
  let φ : ∀ i : Fin n, MonoidAlgebra k G →ₐ[k] Module.End k (Fin (d i) → k) := fun i =>
    (Matrix.toLinAlgEquiv' : Matrix (Fin (d i)) (Fin (d i)) k ≃ₐ[k] _).toAlgHom.comp
      ((Pi.evalAlgHom k (fun j => Matrix (Fin (d j)) (Fin (d j)) k) i).comp e.toAlgHom)
  have hφ : ∀ i a, φ i a = Matrix.toLin' (e a i) := fun i a => rfl
  have hsurj : ∀ i, Function.Surjective (φ i) := by
    intro i T
    refine ⟨e.symm (Pi.single i (LinearMap.toMatrix' T)), ?_⟩
    rw [hφ]
    simp
  let V : Fin n → FDRep k G := fun i =>
    FDRep.of ((φ i : MonoidAlgebra k G →* Module.End k (Fin (d i) → k)).comp
      (MonoidAlgebra.of k G))
  have hsimple : ∀ i, Simple (V i) := fun i => simple_of_surjective (φ i) (hsurj i)
  have hiso : ∀ i j, Nonempty (V i ≅ V j) → i = j := by
    intro i j hij
    by_contra hne
    refine not_iso_of_separating (φ i) (φ j) (e.symm (Pi.single i 1)) ?_ ?_ hij
    · rw [hφ]
      simp [Module.End.one_eq_id]
    · rw [hφ]
      simp [Ne.symm hne]
  have hcard : n = Nat.card (ConjClasses G) := by
    rw [← finrank_center_pi_matrix (k := k) n d hd, ← finrank_center_eq_of_algEquiv e,
      finrank_center_monoidAlgebra]
  have hdim : ∀ i, Module.finrank k (V i) = d i := fun i => Module.finrank_fin_fun k
  refine ⟨Fin n, inferInstance, V, hsimple, hiso, ?_, ?_, ?_⟩
  · intro W hW
    by_contra hno
    simp only [not_exists] at hno
    let U : Option (Fin n) → FDRep k G := fun a => a.elim W V
    have hU : ∀ a, Simple (U a) := by
      rintro (_ | i)
      exacts [hW, hsimple i]
    have hUiso : ∀ a b, Nonempty (U a ≅ U b) → a = b := by
      rintro (_ | i) (_ | j) h
      · rfl
      · exact absurd h (hno j)
      · exact absurd (h.map Iso.symm) (hno i)
      · exact congrArg some (hiso i j h)
    have := card_le_card_conjClasses U hUiso
    simp only [Fintype.card_option, Fintype.card_fin] at this
    omega
  · simp [hcard]
  · have hA : Module.finrank k (MonoidAlgebra k G) = Fintype.card G := by
      rw [(MonoidAlgebra.coeffLinearEquiv k).finrank_eq, Module.finrank_finsupp_self]
    rw [← hA, e.toLinearEquiv.finrank_eq, Module.finrank_pi_fintype]
    simp [hdim, Module.finrank_matrix, sq]

/-- **Dimension-1 pieces, by commutators.** A dimension-1 piece sends each member of `G` to a
nonzero number, multiplicatively: a group homomorphism `G →* kˣ`. Over the same fields as
above, the number of these equals `|G|` divided by the size of the commutator subgroup, that is,
the commutator subgroup's index. For the tile: 8 / 2 = 4. -/
theorem card_one_dim_pieces_eq_index_commutator
    {k : Type} [Field k] [IsAlgClosed k] {G : Type} [Group G] [Fintype G]
    [Invertible (Nat.card G : k)] :
    Nat.card (G →* kˣ) = (commutator G).index := by
  have hA : Nat.card (Abelianization G) = (commutator G).index := rfl
  have hdvd : Monoid.exponent (Abelianization G) ∣ Nat.card G :=
    (Group.exponent_dvd_nat_card).trans (hA ▸ Subgroup.index_dvd_card _)
  have : NeZero ((Monoid.exponent (Abelianization G) : ℕ) : k) := by
    refine ⟨fun h => ?_⟩
    obtain ⟨c, hc⟩ := hdvd
    have : ((Nat.card G : ℕ) : k) = 0 := by rw [hc, Nat.cast_mul, h, zero_mul]
    exact (isUnit_of_invertible (Nat.card G : k)).ne_zero this
  have : Finite (Abelianization G) := Finite.of_surjective _ (QuotientGroup.mk_surjective)
  rw [← hA, ← CommGroup.card_monoidHom_of_hasEnoughRootsOfUnity (Abelianization G) k]
  exact Nat.card_congr Abelianization.lift

/-- **The table is a fingerprint, not proof of sameness.** The tile group (the eight moves of a
square, `DihedralGroup 4`) and Q8 (the eight quaternions ±1, ±i, ±j, ±k, `QuaternionGroup 2`)
share one character table (checked entry by entry below), yet no relabelling turns one group
into the other. -/
theorem tile_group_not_iso_quaternion :
    IsEmpty (DihedralGroup 4 ≃* QuaternionGroup 2) := by
  refine ⟨fun e => ?_⟩
  have h1 : (Finset.univ.filter
    (fun g : DihedralGroup 4 => g ≠ 1 ∧ g * g = 1)).card = 5 := by decide
  have h2 : (Finset.univ.filter
    (fun g : QuaternionGroup 2 => g ≠ 1 ∧ g * g = 1)).card = 1 := by decide
  have : (Finset.univ.filter
    (fun g : DihedralGroup 4 => g ≠ 1 ∧ g * g = 1)).card = (Finset.univ.filter
    (fun g : QuaternionGroup 2 => g ≠ 1 ∧ g * g = 1)).card := by
    refine Finset.card_bij (fun g _ => e g) ?_ ?_ ?_
    · intro g hg
      simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hg ⊢
      exact ⟨by simpa using hg.1, by rw [← map_mul, hg.2, map_one]⟩
    · intro a _ b _ h; exact e.injective h
    · intro b hb
      refine ⟨e.symm b, ?_, by simp⟩
      simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hb ⊢
      exact ⟨by simpa using hb.1, by rw [← map_mul, hb.2, map_one]⟩
  omega

/-! ### The card's worked numbers -/

/-- Squared dimensions: the tile, 1 + 1 + 1 + 1 + 4 = 8; S3, 1 + 1 + 4 = 6. -/
example : (1 : ℕ) ^ 2 + 1 ^ 2 + 1 ^ 2 + 1 ^ 2 + 2 ^ 2 = 8 := by norm_num
example : (1 : ℕ) ^ 2 + 1 ^ 2 + 2 ^ 2 = 6 := by norm_num

/-- Mistake 1, dimensions added, not squared: tile 6, S3 4. -/
example : (1 : ℕ) + 1 + 1 + 1 + 2 = 6 ∧ (1 : ℕ) + 1 + 2 = 4 := by norm_num

/-- Group sizes and class counts: the tile has 8 members in 5 classes, Q8 has 8 in 5,
S3 has 6 in 3. -/
example : Fintype.card (DihedralGroup 4) = 8 := by decide
example : Fintype.card (QuaternionGroup 2) = 8 := by decide
example : Fintype.card (Equiv.Perm (Fin 3)) = 6 := by decide
example : Fintype.card (ConjClasses (DihedralGroup 4)) = 5 := by decide
example : Fintype.card (ConjClasses (QuaternionGroup 2)) = 5 := by decide
example : Fintype.card (ConjClasses (Equiv.Perm (Fin 3))) = 3 := by decide

/-- The commutator subgroups: size 2 for the tile and Q8, size 3 for S3; so the tile has
8 / 2 = 4 dimension-1 pieces and S3 has 6 / 3 = 2. -/
example : Nat.card (commutator (DihedralGroup 4)) = 2 := by
  rw [commutator_eq_zpowers_of (DihedralGroup.r 2) 2 (by decide)
    ⟨DihedralGroup.r 1, DihedralGroup.sr 0, by decide⟩, Nat.card_zpowers]
  exact orderOf_eq_prime (by decide) (by decide)
example : Nat.card (commutator (QuaternionGroup 2)) = 2 := by
  rw [commutator_eq_zpowers_of (QuaternionGroup.a 2) 2 (by decide)
    ⟨QuaternionGroup.a 1, QuaternionGroup.xa 0, by decide⟩, Nat.card_zpowers]
  exact orderOf_eq_prime (by decide) (by decide)
example : Nat.card (commutator (Equiv.Perm (Fin 3))) = 3 := by
  rw [commutator_eq_zpowers_of (finRotate 3) 3 (by decide)
    ⟨Equiv.swap 0 1, Equiv.swap 0 2, by decide⟩, Nat.card_zpowers]
  have : Fact (Nat.Prime 3) := ⟨Nat.prime_three⟩
  exact orderOf_eq_prime (by decide) (by decide)

/-- Members of order 2 (not `e`, but done twice give `e`): 5 in the tile, 1 in Q8. -/
example : (Finset.univ.filter
    (fun g : DihedralGroup 4 => g ≠ 1 ∧ g * g = 1)).card = 5 := by decide
example : (Finset.univ.filter
    (fun g : QuaternionGroup 2 => g ≠ 1 ∧ g * g = 1)).card = 1 := by decide

/-- The house matrices: the quarter turn `[[0, -1], [1, 0]]` and the diagonal flip
`[[1, 0], [0, -1]]` obey `r⁴ = e`, `f² = e` and `f r f = r⁻¹ = r³`. -/
example :
    let r : Matrix (Fin 2) (Fin 2) ℤ := !![0, -1; 1, 0]
    let f : Matrix (Fin 2) (Fin 2) ℤ := !![1, 0; 0, -1]
    r ^ 4 = 1 ∧ f ^ 2 = 1 ∧ f * r * f = r ^ 3 := by
  intro r f
  refine ⟨?_, ?_, ?_⟩ <;> ext i j <;> fin_cases i <;> fin_cases j <;>
    simp [r, f, pow_succ, Matrix.mul_apply, Fin.sum_univ_two]

/-- The 2-by-2 row of the tile's table from the house matrices: traces 2 at `e`, −2 at `r²`,
0 at `r`, at `f` and at `r f`. -/
example :
    let r : Matrix (Fin 2) (Fin 2) ℤ := !![0, -1; 1, 0]
    let f : Matrix (Fin 2) (Fin 2) ℤ := !![1, 0; 0, -1]
    ((1 : Matrix (Fin 2) (Fin 2) ℤ).trace, (r ^ 2).trace, r.trace, f.trace, (r * f).trace)
      = (2, -2, 0, 0, 0) := by
  intro r f
  simp [r, f, pow_two, Matrix.trace_fin_two]

/-- The tile's table (rows: trivial, flip sign, diagonal sign, edge sign, 2-by-2), columns
`e`, `r²`, `r`, `f`, `r f`. Q8's table, columns `1`, `−1`, `±i`, `±j`, `±k`, is the same. -/
def tileTable : Fin 5 → Fin 5 → ℤ :=
  ![![1, 1, 1, 1, 1],
    ![1, 1, 1, -1, -1],
    ![1, 1, -1, 1, -1],
    ![1, 1, -1, -1, 1],
    ![2, -2, 0, 0, 0]]

/-- The tile's class sizes, 1, 1, 2, 2, 2. -/
def tileSizes : Fin 5 → ℤ := ![1, 1, 2, 2, 2]

/-- Orthogonality of the tile's rows: weighted by class sizes, a row against itself gives
|G| = 8 and two different rows give 0 (so `⟨χᵢ, χⱼ⟩` is 1 or 0 after dividing by 8). -/
example : ∀ i j : Fin 5,
    ∑ c, tileSizes c * tileTable i c * tileTable j c = if i = j then 8 else 0 := by decide

/-- The regular representation: the rows weighted by their dimensions add to 8 at `e` and 0
at every other class. -/
example : ∀ c : Fin 5,
    ∑ i, tileTable i 0 * tileTable i c = if c = 0 then 8 else 0 := by decide

/-- The tile's 4-by-4 corner shuffle has character (4, 0, 0, 2, 0): one trivial piece, one
diagonal sign piece and one 2-by-2 piece, found by inner products with the rows. -/
example : (fun i => ∑ c, tileSizes c * tileTable i c * ![4, 0, 0, 2, 0] c)
    = ![8, 0, 8, 0, 8] := by
  funext i; fin_cases i <;> decide

/-- S3's table on `e` (1), turns (2), swaps (3): rows (1, 1, 1), (1, 1, −1), (2, −1, 0);
trivial against sign, weighted: 1 + 2 − 3 = 0; the same sum without class sizes is 1, so
mistake 2 gives 1/6, not 0. -/
example : (1 : ℤ) * 1 * 1 + 2 * 1 * 1 + 3 * 1 * (-1) = 0 := by norm_num
example : (1 : ℤ) * 1 + 1 * 1 + 1 * (-1) = 1 := by norm_num

/-- S3's two-dimensional row by fixed corners minus the trivial row:
(3, 0, 1) − (1, 1, 1) = (2, −1, 0). -/
example : (3 - 1, 0 - 1, 1 - 1) = ((2 : ℤ), (-1 : ℤ), (0 : ℤ)) := by norm_num

#print axioms irreducibles_count_classes_and_squares_sum_to_card
#print axioms card_one_dim_pieces_eq_index_commutator
#print axioms tile_group_not_iso_quaternion

end CharacterTables
