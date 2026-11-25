-- Infinite Galois theory: for a Galois extension the fixed-field map matches intermediate fields with closed subgroups of the compact Krull-topology group, and the group for the algebraic closure of GF(p) is the profinite integers with Frobenius dense.
import Mathlib.FieldTheory.Galois.Infinite
import Mathlib.FieldTheory.Galois.Profinite
import Mathlib.FieldTheory.Finite.Basic
import Mathlib.FieldTheory.IsAlgClosed.AlgebraicClosure
import Mathlib.Topology.Instances.ZMod
import Mathlib.Topology.Algebra.ContinuousMonoidHom
import Mathlib.FieldTheory.IsSepClosed
import Mathlib.Topology.Baire.LocallyCompactRegular
import Mathlib.FieldTheory.Finite.GaloisField

open IntermediateField

/-- The profinite integers `Ẑ`, as on the card: the lists `(r₁, r₂, r₃, …)` with `rₙ` in
`ℤ mod n`, compatible in the sense that `rₘ ≡ rₙ (mod n)` whenever `n ∣ m`.
Lists add entry by entry. -/
def profiniteIntegers : AddSubgroup ((n : ℕ+) → ZMod n) where
  carrier := {r | ∀ (n m : ℕ+) (h : (n : ℕ) ∣ m), ZMod.castHom h (ZMod n) (r m) = r n}
  zero_mem' := by
    intro n m h
    simp
  add_mem' := by
    intro a b ha hb n m h
    simp only [Pi.add_apply, map_add]
    rw [ha n m h, hb n m h]
  neg_mem' := by
    intro a ha n m h
    simp only [Pi.neg_apply, map_neg]
    rw [ha n m h]

/-- The list `(1 mod n)`: the element of `Ẑ` that the integer 1, and so Frobenius, gives. -/
def profiniteIntegers.one : profiniteIntegers :=
  ⟨fun _ => 1, fun n _ h => map_one (ZMod.castHom h (ZMod n))⟩

/-! Helper lemmas for the proofs below. -/

namespace GalFp

open Polynomial

variable (p : ℕ) [Fact p.Prime]

theorem frob_pow_apply (L : Type*) [Field L] [Algebra (ZMod p) L] [Algebra.IsAlgebraic (ZMod p) L]
    (k : ℕ) (y : L) :
    (FiniteField.frobeniusAlgEquivOfAlgebraic (ZMod p) L ^ k) y = y ^ p ^ k := by
  induction k with
  | zero => simp
  | succ k ih =>
    rw [pow_succ', AlgEquiv.mul_apply, ih, FiniteField.coe_frobeniusAlgEquivOfAlgebraic]
    simp only [ZMod.card]
    rw [← pow_mul, ← pow_succ]

#print axioms frob_pow_apply

theorem pow_pow_dvd (x : AlgebraicClosure (ZMod p)) {n k : ℕ} (hx : x ^ p ^ n = x) (h : n ∣ k) :
    x ^ p ^ k = x := by
  obtain ⟨c, rfl⟩ := h
  induction c with
  | zero => simp
  | succ c ih => rw [Nat.mul_succ, pow_add, pow_mul, ih, hx]

#print axioms pow_pow_dvd

noncomputable def S (n : ℕ) : IntermediateField (ZMod p) (AlgebraicClosure (ZMod p)) :=
  IntermediateField.adjoin (ZMod p)
    ((X ^ p ^ n - X : Polynomial (ZMod p)).rootSet (AlgebraicClosure (ZMod p)))

instance S_isSplittingField (n : ℕ) :
    IsSplittingField (ZMod p) (S p n) (X ^ p ^ n - X : Polynomial (ZMod p)) :=
  IntermediateField.adjoin_rootSet_isSplittingField (IsAlgClosed.splits _)

instance S_normal (n : ℕ) : Normal (ZMod p) (S p n) :=
  Normal.of_isSplittingField (X ^ p ^ n - X : Polynomial (ZMod p))

instance S_fd (n : ℕ) : FiniteDimensional (ZMod p) (S p n) :=
  IsSplittingField.finiteDimensional _ (X ^ p ^ n - X : Polynomial (ZMod p))

instance S_finite (n : ℕ) : Finite (S p n) := Module.finite_of_finite (ZMod p)

theorem S_finrank {n : ℕ} (hn : n ≠ 0) : Module.finrank (ZMod p) (S p n) = n := by
  rw [(IsSplittingField.algEquiv (S p n) (X ^ p ^ n - X : Polynomial (ZMod p))).toLinearEquiv.finrank_eq]
  exact GaloisField.finrank p hn

#print axioms S_finrank

theorem mem_S_iff {n : ℕ} (hn : n ≠ 0) (x : AlgebraicClosure (ZMod p)) :
    x ∈ S p n ↔ x ^ p ^ n = x := by
  constructor
  · intro hx
    have := Fintype.ofFinite (S p n)
    have hcard : Fintype.card (S p n) = p ^ n := by
      rw [Module.card_eq_pow_finrank (K := ZMod p), ZMod.card, S_finrank p hn]
    have h := FiniteField.pow_card (⟨x, hx⟩ : S p n)
    rw [hcard] at h
    exact congrArg Subtype.val h
  · intro hx
    apply IntermediateField.subset_adjoin
    rw [Polynomial.mem_rootSet]
    refine ⟨X_pow_sub_X_ne_zero ?_, ?_⟩
    · exact Nat.one_lt_pow hn (Fact.out : p.Prime).one_lt
    · simp [hx]

#print axioms mem_S_iff

theorem exists_pow (n : ℕ) (g : Gal(S p n/ZMod p)) :
    ∃ k : ℕ, FiniteField.frobeniusAlgEquivOfAlgebraic (ZMod p) (S p n) ^ k = g := by
  obtain ⟨i, hi⟩ := (FiniteField.bijective_frobeniusAlgEquivOfAlgebraic_pow (ZMod p) (S p n)).2 g
  exact ⟨i.1, hi⟩

#print axioms exists_pow

noncomputable def rrAux (n : ℕ) (g : Gal(S p n/ZMod p)) : ZMod n :=
  ((exists_pow p n g).choose : ZMod n)

noncomputable def rr (n : ℕ) (σ : Gal(AlgebraicClosure (ZMod p)/ZMod p)) : ZMod n :=
  rrAux p n (AlgEquiv.restrictNormalHom (F := ZMod p) (K₁ := AlgebraicClosure (ZMod p)) (S p n) σ)

theorem rr_eq_of {n : ℕ} (hn : n ≠ 0) (σ : Gal(AlgebraicClosure (ZMod p)/ZMod p)) (k : ℕ)
    (h : ∀ x : AlgebraicClosure (ZMod p), x ^ p ^ n = x → σ x = x ^ p ^ k) :
    rr p n σ = k := by
  unfold rr rrAux
  set g := AlgEquiv.restrictNormalHom (F := ZMod p) (K₁ := AlgebraicClosure (ZMod p)) (S p n) σ
  have hspec := (exists_pow p n g).choose_spec
  have hk : FiniteField.frobeniusAlgEquivOfAlgebraic (ZMod p) (S p n) ^ k = g := by
    ext y
    rw [frob_pow_apply, AlgEquiv.restrictNormalHom_apply]
    push_cast
    exact (h y.1 ((mem_S_iff p hn y.1).mp y.2)).symm
  have := pow_eq_pow_iff_modEq.mp (hspec.trans hk.symm)
  rw [FiniteField.orderOf_frobeniusAlgEquivOfAlgebraic, S_finrank p hn] at this
  exact (ZMod.natCast_eq_natCast_iff _ _ _).mpr this

#print axioms rr_eq_of

theorem rr_spec {n : ℕ} (hn : n ≠ 0) (σ : Gal(AlgebraicClosure (ZMod p)/ZMod p)) :
    ∃ k : ℕ, rr p n σ = k ∧
      ∀ x : AlgebraicClosure (ZMod p), x ^ p ^ n = x → σ x = x ^ p ^ k := by
  refine ⟨(exists_pow p n (AlgEquiv.restrictNormalHom (F := ZMod p)
    (K₁ := AlgebraicClosure (ZMod p)) (S p n) σ)).choose, rfl, fun x hx => ?_⟩
  have hspec := (exists_pow p n (AlgEquiv.restrictNormalHom (F := ZMod p)
    (K₁ := AlgebraicClosure (ZMod p)) (S p n) σ)).choose_spec
  have := congrArg (fun g => ((g ⟨x, (mem_S_iff p hn x).mpr hx⟩ : S p n) : AlgebraicClosure (ZMod p)))
    hspec
  simp only [AlgEquiv.restrictNormalHom_apply, frob_pow_apply] at this
  push_cast at this
  exact this.symm

#print axioms rr_spec

theorem rr_ker_iff {n : ℕ} (hn : n ≠ 0) (σ : Gal(AlgebraicClosure (ZMod p)/ZMod p)) :
    rr p n σ = 0 ↔ ∀ x : AlgebraicClosure (ZMod p), x ^ p ^ n = x → σ x = x := by
  constructor
  · intro h0 x hx
    obtain ⟨k, hk, hσ⟩ := rr_spec p hn σ
    rw [h0, eq_comm, CharP.cast_eq_zero_iff (ZMod n) n] at hk
    rw [hσ x hx, pow_pow_dvd p x hx hk]
  · intro h
    have := rr_eq_of p hn σ 0 (fun x hx => by rw [h x hx, pow_zero, pow_one])
    simpa using this

#print axioms rr_ker_iff

theorem rr_mul {n : ℕ} (hn : n ≠ 0) (σ τ : Gal(AlgebraicClosure (ZMod p)/ZMod p)) :
    rr p n (σ * τ) = rr p n σ + rr p n τ := by
  obtain ⟨a, ha, hσ⟩ := rr_spec p hn σ
  obtain ⟨b, hb, hτ⟩ := rr_spec p hn τ
  rw [ha, hb, ← Nat.cast_add]
  apply rr_eq_of p hn
  intro x hx
  have hx' : (x ^ p ^ b) ^ p ^ n = x ^ p ^ b := by rw [pow_right_comm, hx]
  rw [AlgEquiv.mul_apply, hτ x hx, hσ _ hx', ← pow_mul, pow_add, mul_comm]

#print axioms rr_mul

theorem rr_compat {n m : ℕ} (hn : n ≠ 0) (hm : m ≠ 0) (h : n ∣ m)
    (σ : Gal(AlgebraicClosure (ZMod p)/ZMod p)) :
    ZMod.castHom h (ZMod n) (rr p m σ) = rr p n σ := by
  obtain ⟨k, hk, hσ⟩ := rr_spec p hm σ
  rw [hk, map_natCast]
  symm
  exact rr_eq_of p hn σ k fun x hx => hσ x (pow_pow_dvd p x hx h)

#print axioms rr_compat

theorem rr_frob_pow {n : ℕ} (hn : n ≠ 0) (k : ℕ) :
    rr p n (FiniteField.frobeniusAlgEquivOfAlgebraic (ZMod p) (AlgebraicClosure (ZMod p)) ^ k)
      = k :=
  rr_eq_of p hn _ k fun x _ => frob_pow_apply p _ k x

#print axioms rr_frob_pow

theorem rr_continuous (n : ℕ) : Continuous (rr p n) :=
  (continuous_of_discreteTopology (f := rrAux p n)).comp
    (InfiniteGalois.restrictNormalHom_continuous (S p n))

#print axioms rr_continuous

theorem exists_pnat (x : AlgebraicClosure (ZMod p)) : ∃ n : ℕ+, x ^ p ^ (n : ℕ) = x := by
  set E := IntermediateField.adjoin (ZMod p) {x}
  have : FiniteDimensional (ZMod p) E :=
    IntermediateField.adjoin.finiteDimensional (Algebra.IsIntegral.isIntegral x)
  have : Finite E := Module.finite_of_finite (ZMod p)
  have := Fintype.ofFinite E
  refine ⟨⟨Module.finrank (ZMod p) E, Module.finrank_pos⟩, ?_⟩
  have h := FiniteField.pow_card (⟨x, IntermediateField.mem_adjoin_simple_self _ x⟩ : E)
  rw [Module.card_eq_pow_finrank (K := ZMod p), ZMod.card] at h
  exact congrArg Subtype.val h

#print axioms exists_pnat

noncomputable def psiFun (σ : Gal(AlgebraicClosure (ZMod p)/ZMod p)) : profiniteIntegers :=
  ⟨fun n => rr p n σ, fun n m h => rr_compat p n.ne_zero m.ne_zero h σ⟩

noncomputable def psi : Gal(AlgebraicClosure (ZMod p)/ZMod p) →* Multiplicative profiniteIntegers :=
  MonoidHom.mk' (fun σ => Multiplicative.ofAdd (psiFun p σ)) (fun σ τ => by
    rw [← ofAdd_add]
    congr 1
    apply Subtype.ext
    funext n
    exact rr_mul p n.ne_zero σ τ)

theorem psi_continuous : Continuous (psi p) := by
  have : Continuous (psiFun p) :=
    continuous_induced_rng.2 (continuous_pi fun n => rr_continuous p n)
  exact continuous_ofAdd.comp this

#print axioms psi_continuous

theorem psi_injective : Function.Injective (psi p) := by
  refine (injective_iff_map_eq_one (psi p)).mpr fun σ hσ => ?_
  have h0 : ∀ n : ℕ+, rr p n σ = 0 := fun n =>
    congrArg (fun z : Multiplicative profiniteIntegers => (Multiplicative.toAdd z).1 n) hσ
  ext x
  obtain ⟨n, hn⟩ := exists_pnat p x
  exact (rr_ker_iff p n.ne_zero σ).mp (h0 n) x hn

#print axioms psi_injective

theorem psi_surjective : Function.Surjective (psi p) := by
  intro r
  set r' := Multiplicative.toAdd r
  let t : ℕ+ → Set Gal(AlgebraicClosure (ZMod p)/ZMod p) := fun N => {σ | rr p N σ = r'.1 N}
  have hd : Directed (· ⊇ ·) t := by
    intro a b
    have hab : ∀ c d : ℕ+, (c : ℕ) ∣ ((c * d : ℕ+) : ℕ) := fun c d => by
      rw [PNat.mul_coe]; exact Dvd.intro _ rfl
    have key : ∀ c d : ℕ+, t (c * d) ⊆ t c := fun c d σ hσ => by
      simp only [t, Set.mem_ofPred_eq] at hσ ⊢
      rw [← rr_compat p c.ne_zero (c * d).ne_zero (hab c d), hσ]
      exact r'.2 c (c * d) (hab c d)
    refine ⟨a * b, key a b, ?_⟩
    rw [mul_comm]
    exact key b a
  have hn : ∀ N, (t N).Nonempty := fun N =>
    ⟨FiniteField.frobeniusAlgEquivOfAlgebraic (ZMod p) (AlgebraicClosure (ZMod p)) ^ (r'.1 N).val,
      by simp only [t, Set.mem_ofPred_eq]; rw [rr_frob_pow p N.ne_zero, ZMod.natCast_zmod_val]⟩
  have hcl : ∀ N, IsClosed (t N) := fun N => isClosed_singleton.preimage (rr_continuous p N)
  obtain ⟨σ, hσ⟩ := IsCompact.nonempty_iInter_of_directed_nonempty_isCompact_isClosed t hd hn
    (fun N => (hcl N).isCompact) hcl
  refine ⟨σ, ?_⟩
  show Multiplicative.ofAdd (psiFun p σ) = Multiplicative.ofAdd r'
  congr 1
  apply Subtype.ext
  funext N
  exact Set.mem_iInter.mp hσ N

#print axioms psi_surjective

end GalFp

theorem fixedField_frob_eq_bot (p : ℕ) [Fact p.Prime] :
    fixedField (Subgroup.zpowers
      (FiniteField.frobeniusAlgEquivOfAlgebraic (ZMod p) (AlgebraicClosure (ZMod p)))) = ⊥ := by
  set Ω := AlgebraicClosure (ZMod p)
  apply le_antisymm _ bot_le
  intro x hx
  have hfx := (mem_fixedField_iff _ x).mp hx _ (Subgroup.mem_zpowers _)
  rw [FiniteField.coe_frobeniusAlgEquivOfAlgebraic, ZMod.card p] at hfx
  rw [IntermediateField.mem_bot]
  have hinj : Function.Injective (algebraMap (ZMod p) Ω) := (algebraMap (ZMod p) Ω).injective
  have hq : (Polynomial.X ^ Fintype.card (ZMod p) - Polynomial.X : Polynomial (ZMod p)) ≠ 0 :=
    Polynomial.X_pow_sub_X_ne_zero Fintype.one_lt_card
  have hroots := Polynomial.roots_map_of_injective_of_card_eq_natDegree hinj
    (p := (Polynomial.X ^ Fintype.card (ZMod p) - Polynomial.X : Polynomial (ZMod p))) (by
      rw [FiniteField.roots_X_pow_card_sub_X, Polynomial.natDegree_X_pow_sub_X Fintype.one_lt_card]
      simp)
  have hx' : x ∈ ((Polynomial.X ^ Fintype.card (ZMod p) - Polynomial.X : Polynomial (ZMod p)).map
      (algebraMap (ZMod p) Ω)).roots := by
    rw [Polynomial.mem_roots_map_of_injective hinj hq]
    simp [ZMod.card p, hfx]
  rw [← hroots, FiniteField.roots_X_pow_card_sub_X] at hx'
  obtain ⟨a, -, ha⟩ := Multiset.mem_map.mp hx'
  exact ⟨a, ha⟩

#print axioms fixedField_frob_eq_bot

/-- **Krull's theorem.** Let `Ω / K` be a Galois extension, possibly infinite, and give
`Gal(Ω/K)` the Krull topology (symmetries are near when they agree on a finite piece).
Then the group is compact; the subgroup fixing an intermediate field `E` is closed and fixes
exactly `E`; for every subgroup `H`, the symmetries fixing everything `H` fixes are exactly
the closure of `H`, so fields match closed subgroups one to one; and the subgroup fixing `E`
is open exactly when `E` has finite degree over `K`, with that degree equal to its index. -/
theorem krull_galois_correspondence (K Ω : Type*) [Field K] [Field Ω] [Algebra K Ω]
    [IsGalois K Ω] :
    CompactSpace Gal(Ω/K) ∧
    (∀ E : IntermediateField K Ω,
      IsClosed (E.fixingSubgroup : Set Gal(Ω/K)) ∧ fixedField E.fixingSubgroup = E) ∧
    (∀ H : Subgroup Gal(Ω/K), (fixedField H).fixingSubgroup = H.topologicalClosure) ∧
    (∀ E : IntermediateField K Ω,
      (IsOpen (E.fixingSubgroup : Set Gal(Ω/K)) ↔ FiniteDimensional K E) ∧
      Module.finrank K E = E.fixingSubgroup.index) := by
  refine ⟨inferInstance, fun E => ⟨InfiniteGalois.fixingSubgroup_isClosed E,
    InfiniteGalois.fixedField_fixingSubgroup E⟩, fun H => ?_, fun E =>
    ⟨InfiniteGalois.isOpen_iff_finite E, IntermediateField.finrank_eq_fixingSubgroup_index Ω E⟩⟩
  have hcl : IsClosed ((fixedField H).fixingSubgroup : Set Gal(Ω/K)) :=
    InfiniteGalois.fixingSubgroup_isClosed _
  have hle : H ≤ (fixedField H).fixingSubgroup :=
    (IntermediateField.le_fixedField_iff_le_fixingSubgroup _ _).mp le_rfl
  apply le_antisymm
  · let C : ClosedSubgroup Gal(Ω/K) := ⟨H.topologicalClosure, H.isClosed_topologicalClosure⟩
    have h1 : fixedField C.1 ≤ fixedField H :=
      IntermediateField.fixedField_antitone H.le_topologicalClosure
    have h2 : fixedField H ≤ fixedField C.1 :=
      (IntermediateField.le_fixedField_iff_le_fixingSubgroup _ _).mpr
        (H.topologicalClosure_minimal hle hcl)
    rw [le_antisymm h2 h1, InfiniteGalois.fixingSubgroup_fixedField C]
  · exact H.topologicalClosure_minimal hle hcl

/-- **The algebraic closure of GF(p).** Its Galois group is the profinite integers `Ẑ`, as a
group and as a topological space: Frobenius `x ↦ x ^ p` goes to the list `(1 mod n)`, and a
symmetry has reading `rₙ = 0` exactly when it fixes every element of GF(p^n), the roots of
`x ^ (p ^ n) = x`. -/
theorem galois_group_of_algebraic_closure_of_GFp_is_profinite_integers
    (p : ℕ) [Fact p.Prime] :
    ∃ φ : Gal(AlgebraicClosure (ZMod p)/ZMod p) ≃ₜ* Multiplicative profiniteIntegers,
      φ (FiniteField.frobeniusAlgEquivOfAlgebraic (ZMod p) (AlgebraicClosure (ZMod p))) =
          Multiplicative.ofAdd profiniteIntegers.one ∧
      ∀ (σ : Gal(AlgebraicClosure (ZMod p)/ZMod p)) (n : ℕ+),
        ((Multiplicative.toAdd (φ σ)).1 n = 0 ↔
          ∀ x : AlgebraicClosure (ZMod p), x ^ (p ^ (n : ℕ)) = x → σ x = x) := by
  have hbij : Function.Bijective (GalFp.psi p) := ⟨GalFp.psi_injective p, GalFp.psi_surjective p⟩
  let e := MulEquiv.ofBijective (GalFp.psi p) hbij
  let h := Continuous.homeoOfEquivCompactToT2 (f := e.toEquiv) (GalFp.psi_continuous p)
  refine ⟨⟨e, h.continuous_toFun, h.continuous_invFun⟩, ?_, ?_⟩
  · show Multiplicative.ofAdd (GalFp.psiFun p _) = _
    congr 1
    apply Subtype.ext
    funext n
    have := GalFp.rr_frob_pow p n.ne_zero 1
    rw [pow_one, Nat.cast_one] at this
    exact this
  · intro σ n
    exact GalFp.rr_ker_iff p n.ne_zero σ

/-- **Frobenius generates a dense copy of the integers, and only closed subgroups count.**
Over GF(p), the powers of Frobenius are dense in the Galois group of the algebraic closure,
yet are not the whole group; both fix GF(p) and nothing more, so two different subgroups
give one field. -/
theorem frobenius_powers_dense_not_closed (p : ℕ) [Fact p.Prime] :
    let F := FiniteField.frobeniusAlgEquivOfAlgebraic (ZMod p) (AlgebraicClosure (ZMod p))
    Dense (Subgroup.zpowers F : Set Gal(AlgebraicClosure (ZMod p)/ZMod p)) ∧
    Subgroup.zpowers F ≠ ⊤ ∧
    fixedField (Subgroup.zpowers F) = ⊥ ∧
    fixedField (⊤ : Subgroup Gal(AlgebraicClosure (ZMod p)/ZMod p)) = ⊥ := by
  intro F
  set Ω := AlgebraicClosure (ZMod p)
  have hfix : fixedField (Subgroup.zpowers F) = ⊥ := fixedField_frob_eq_bot p
  refine ⟨?_, ?_, hfix, InfiniteGalois.fixedField_bot⟩
  · rw [dense_iff_closure_eq, ← Subgroup.topologicalClosure_coe]
    have := (krull_galois_correspondence (ZMod p) Ω).2.2.1 (Subgroup.zpowers F)
    rw [← this, hfix, IntermediateField.fixingSubgroup_bot, Subgroup.coe_top]
  · intro htop
    have hU : ⋃ k : ℤ, ({F ^ k} : Set Gal(Ω/ZMod p)) = Set.univ := by
      ext σ
      simp only [Set.mem_iUnion, Set.mem_singleton_iff, Set.mem_univ, iff_true]
      have : σ ∈ Subgroup.zpowers F := htop ▸ Subgroup.mem_top σ
      obtain ⟨k, hk⟩ := Subgroup.mem_zpowers_iff.mp this
      exact ⟨k, hk.symm⟩
    obtain ⟨k, hk⟩ := nonempty_interior_of_iUnion_of_closed (fun _ => isClosed_singleton) hU
    have hopen : IsOpen ({F ^ k} : Set Gal(Ω/ZMod p)) := by
      rw [← (Set.Nonempty.subset_singleton_iff hk).mp interior_subset]
      exact isOpen_interior
    have h1 : IsOpen ({1} : Set Gal(Ω/ZMod p)) := by
      have := (Homeomorph.mulLeft (F ^ k)⁻¹).isOpenMap _ hopen
      simpa using this
    have h2 : IsOpen ((⊤ : IntermediateField (ZMod p) Ω).fixingSubgroup : Set Gal(Ω/ZMod p)) := by
      rw [IntermediateField.fixingSubgroup_top, Subgroup.coe_bot]
      exact h1
    have hfd : FiniteDimensional (ZMod p) (⊤ : IntermediateField (ZMod p) Ω) :=
      (InfiniteGalois.isOpen_iff_finite _).mp h2
    have : FiniteDimensional (ZMod p) Ω :=
      IntermediateField.topEquiv.toLinearEquiv.finiteDimensional
    have : Finite Ω := Module.finite_of_finite (ZMod p)
    exact not_finite Ω

/-! The card's whole-number worked examples. -/

-- 1 × 2 × ⋯ × 8 = 40,320 choices of (r₁, …, r₈); lcm(1..8) = 840 of them are compatible.
example : Nat.factorial 8 = 40320 := by decide
example : (List.range' 1 8).foldl Nat.lcm 1 = 840 := by decide
-- lcm(1..12) = 27,720 = 8 × 9 × 5 × 7 × 11, and lcm(1..16) = 720,720.
example : (List.range' 1 12).foldl Nat.lcm 1 = 27720 ∧ 8 * 9 * 5 * 7 * 11 = 27720 := by decide
example : (List.range' 1 16).foldl Nat.lcm 1 = 720720 := by decide
-- The symmetry e: r_n = 1 mod the 2-part of n, 0 mod the odd part; its readings are compatible.
example : ∀ m ∈ List.range' 1 16, ∀ n ∈ List.range' 1 16, n ∣ m →
    ([0, 1, 0, 1, 0, 3, 0, 1, 0, 5, 0, 9, 0, 7, 0, 1].getD (m - 1) 0) % n =
      [0, 1, 0, 1, 0, 3, 0, 1, 0, 5, 0, 9, 0, 7, 0, 1].getD (n - 1) 0 := by decide
-- Frob^3465 agrees with e on GF(2^n) for n ≤ 12; Frob^585585 for n ≤ 16.
example : (List.range' 1 12).map (3465 % ·) = [0, 1, 0, 1, 0, 3, 0, 1, 0, 5, 0, 9] := by decide
example : (List.range' 1 16).map (585585 % ·) =
    [0, 1, 0, 1, 0, 3, 0, 1, 0, 5, 0, 9, 0, 7, 0, 1] := by decide
-- r₁₂ = 9: 9 mod 4 = 1 = r₄, 9 mod 6 = 3 = r₆; e fixes 2^gcd(9,12) = 8 elements of GF(2^12).
example : 9 % 4 = 1 ∧ 9 % 6 = 3 ∧ 2 ^ Nat.gcd 9 12 = 8 := by decide
-- One field later: 3465 mod 13 = 7, so Frob^3465 fixes 2^gcd(7,13) = 2 elements of GF(2^13);
-- e has r₁₃ = 0 and fixes all 2^13 = 8,192.
example : 3465 % 13 = 7 ∧ 2 ^ Nat.gcd 7 13 = 2 ∧ 2 ^ 13 = 8192 := by decide
-- k = 945 agrees with e up to n = 10 and is caught at n = 11.
example : (List.range' 1 10).map (945 % ·) = [0, 1, 0, 1, 0, 3, 0, 1, 0, 5] ∧ 945 % 11 ≠ 0 := by
  decide

#print axioms krull_galois_correspondence
#print axioms galois_group_of_algebraic_closure_of_GFp_is_profinite_integers
#print axioms frobenius_powers_dense_not_closed
