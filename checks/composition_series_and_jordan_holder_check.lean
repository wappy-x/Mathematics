-- Composition series: every finite group has a composition series, any two have the same simple pieces up to reordering, and the group is solvable exactly when every piece is a cyclic group of prime size.
import Mathlib.Order.RelSeries
import Mathlib.GroupTheory.QuotientGroup.Basic
import Mathlib.GroupTheory.Solvable
import Mathlib.Order.JordanHolder
import Mathlib.GroupTheory.SpecificGroups.Alternating.Simple
import Mathlib.GroupTheory.SpecificGroups.Dihedral
import Mathlib.GroupTheory.SpecificGroups.Alternating
import Mathlib.Tactic.Simproc.Factors
import Mathlib.Tactic.NormNum.Prime

open scoped SetRel

section QuotientSimple

variable {K : Type*} [Group K]

theorem simple_quot_iff (N : Subgroup K) [N.Normal] :
    IsSimpleGroup (K ⧸ N) ↔ N ≠ ⊤ ∧ ∀ M : Subgroup K, M.Normal → N ≤ M → M = N ∨ M = ⊤ := by
  constructor
  · intro hs
    refine ⟨?_, fun M hM hNM => ?_⟩
    · rintro rfl
      have := QuotientGroup.subsingleton_quotient_top (G := K)
      exact not_nontrivial _ hs.toNontrivial
    · have hmap : (M.map (QuotientGroup.mk' N)).Normal :=
        hM.map _ (QuotientGroup.mk'_surjective N)
      rcases hmap.eq_bot_or_eq_top with h | h
      · left
        refine le_antisymm ?_ hNM
        rw [← QuotientGroup.ker_mk' N, ← Subgroup.map_eq_bot_iff]
        exact h
      · right
        have := congrArg (Subgroup.comap (QuotientGroup.mk' N)) h
        rwa [Subgroup.comap_map_eq, QuotientGroup.ker_mk', sup_eq_left.mpr hNM,
          Subgroup.comap_top] at this
  · rintro ⟨hne, hmax⟩
    refine { exists_pair_ne := ?_, eq_bot_or_eq_top_of_normal := fun L hL => ?_ }
    · obtain ⟨g, hg⟩ : ∃ g, g ∉ N := by
        by_contra h
        push Not at h
        exact hne (eq_top_iff.mpr fun g _ => h g)
      exact ⟨(g : K ⧸ N), 1, fun h => hg ((QuotientGroup.eq_one_iff g).mp h)⟩
    · have hc : (L.comap (QuotientGroup.mk' N)).Normal := hL.comap _
      have hle : N ≤ L.comap (QuotientGroup.mk' N) := by
        intro g hg
        show (g : K ⧸ N) ∈ L
        rw [(QuotientGroup.eq_one_iff g).mpr hg]
        exact L.one_mem
      rcases hmax _ hc hle with h | h
      · left
        have := congrArg (Subgroup.map (QuotientGroup.mk' N)) h
        rw [Subgroup.map_comap_eq_self_of_surjective (QuotientGroup.mk'_surjective N)] at this
        exact this.trans ((Subgroup.map_eq_bot_iff _).mpr (QuotientGroup.ker_mk' N).ge)
      · right
        have := congrArg (Subgroup.map (QuotientGroup.mk' N)) h
        rwa [Subgroup.map_comap_eq_self_of_surjective (QuotientGroup.mk'_surjective N),
          Subgroup.map_top_of_surjective _ (QuotientGroup.mk'_surjective N)] at this

end QuotientSimple

namespace CompositionSeriesCard

variable {G : Type*} [Group G]

/-- One step down a composition series: `B` sits inside `A`, `B` is normal in `A`
(not necessarily in the whole group), and the quotient `A/B` is a simple group. -/
def IsSimpleStep (A B : Subgroup G) : Prop :=
  B ≤ A ∧ ∃ _ : (B.subgroupOf A).Normal, IsSimpleGroup (A ⧸ B.subgroupOf A)

variable (G) in
/-- The relation "one simple step down", as a relation on the subgroups of `G`. -/
def simpleStep : SetRel (Subgroup G) (Subgroup G) :=
  {p | IsSimpleStep p.1 p.2}

/-- A chain `G_0 > G_1 > ... > G_r` of subgroups in which every step is a simple step. -/
abbrev SimpleChain (G : Type*) [Group G] := RelSeries (simpleStep G)

/-- A composition series of `G`: a chain of simple steps from `G_0 = G` down to `G_r = 1`. -/
def IsCompositionSeries (s : SimpleChain G) : Prop :=
  s.head = ⊤ ∧ s.last = ⊥

/-- Each step is normal in the step above it. -/
instance step_normal (s : SimpleChain G) (i : Fin s.length) :
    ((s i.succ).subgroupOf (s i.castSucc)).Normal :=
  (show IsSimpleStep (s i.castSucc) (s i.succ) from s.step i).2.fst

/-- The `i`-th composition factor `G_i / G_(i+1)`. -/
def factor (s : SimpleChain G) (i : Fin s.length) : Type _ :=
  s i.castSucc ⧸ (s i.succ).subgroupOf (s i.castSucc)

instance (s : SimpleChain G) (i : Fin s.length) : Group (factor s i) :=
  inferInstanceAs (Group (s i.castSucc ⧸ (s i.succ).subgroupOf (s i.castSucc)))

theorem step_iff_normalizer {A B : Subgroup G} (h : B ≤ A) :
    (B.subgroupOf A).Normal ↔ A ≤ Subgroup.normalizer (B : Set G) :=
  Subgroup.normal_subgroupOf_iff_le_normalizer h

theorem step_lt {A B : Subgroup G} (h : IsSimpleStep A B) : B < A := by
  obtain ⟨hle, hn, hs⟩ := h
  refine lt_of_le_of_ne hle fun hEq => ?_
  subst hEq
  exact ((simple_quot_iff _).mp hs).1 (Subgroup.subgroupOf_self B)

theorem step_eq {A B C : Subgroup G} (h : IsSimpleStep A B) (hBC : B ≤ C) (hCA : C ≤ A)
    (hn : A ≤ Subgroup.normalizer (C : Set G)) : C = B ∨ C = A := by
  obtain ⟨hle, hBn, hs⟩ := h
  have hCn : (C.subgroupOf A).Normal := (step_iff_normalizer hCA).mpr hn
  rcases ((simple_quot_iff _).mp hs).2 (C.subgroupOf A) hCn
      (Subgroup.comap_mono hBC) with h | h
  · left
    rw [Subgroup.subgroupOf_inj, inf_of_le_left hCA, inf_of_le_left hle] at h
    exact h
  · right
    exact le_antisymm hCA (Subgroup.subgroupOf_eq_top.mp h)

theorem step_mk {A B : Subgroup G} (hlt : B < A) (hn : A ≤ Subgroup.normalizer (B : Set G))
    (hmax : ∀ C, B ≤ C → C ≤ A → A ≤ Subgroup.normalizer (C : Set G) → C = B ∨ C = A) : IsSimpleStep A B := by
  have hBn : (B.subgroupOf A).Normal := (step_iff_normalizer hlt.le).mpr hn
  refine ⟨hlt.le, hBn, (simple_quot_iff _).mpr ⟨?_, fun M hM hBM => ?_⟩⟩
  · intro h
    exact hlt.not_ge (Subgroup.subgroupOf_eq_top.mp h)
  · have hsub : (M.map A.subtype).subgroupOf A = M :=
      Subgroup.comap_map_eq_self_of_injective A.subtype_injective M
    have hBC : B ≤ M.map A.subtype := by
      rw [← Subgroup.map_subgroupOf_eq_of_le hlt.le]
      exact Subgroup.map_mono hBM
    have hCA : M.map A.subtype ≤ A := Subgroup.map_subtype_le M
    have hCn : A ≤ Subgroup.normalizer ((M.map A.subtype : Subgroup G) : Set G) := by
      rw [← step_iff_normalizer hCA, hsub]; exact hM
    rcases hmax _ hBC hCA hCn with h | h
    · left; rw [← hsub, h]
    · right; rw [← hsub, h, Subgroup.subgroupOf_self]

/-- Equal subgroups give the same quotient. -/
def quotCongr {A A' B : Subgroup G} (h : A = A') [(B.subgroupOf A).Normal]
    [(B.subgroupOf A').Normal] : A ⧸ B.subgroupOf A ≃* A' ⧸ B.subgroupOf A' := by
  subst h; exact MulEquiv.refl _

theorem second_iso_step {x y : Subgroup G} (h : IsSimpleStep (x ⊔ y) x) :
    ∃ (_ : ((x ⊓ y).subgroupOf y).Normal) (_ : (x.subgroupOf (x ⊔ y)).Normal),
      Nonempty (y ⧸ (x ⊓ y).subgroupOf y ≃* (x ⊔ y : Subgroup G) ⧸ x.subgroupOf (x ⊔ y)) := by
  obtain ⟨hle, hxn, hs⟩ := h
  have hN : x ⊔ y ≤ Subgroup.normalizer (x : Set G) := (step_iff_normalizer hle).mp hxn
  have hy : y ≤ Subgroup.normalizer (x : Set G) := le_sup_right.trans hN
  have h1 : (x.subgroupOf y).Normal := Subgroup.normal_subgroupOf_of_le_normalizer hy
  have h1' : ((x ⊓ y).subgroupOf y).Normal := by
    rw [Subgroup.inf_subgroupOf_right]; exact h1
  have h2 : (x.subgroupOf (y ⊔ x)).Normal := Subgroup.normal_subgroupOf_sup_of_le_normalizer hy
  refine ⟨h1', hxn, ⟨?_⟩⟩
  refine (QuotientGroup.quotientMulEquivOfEq (Subgroup.inf_subgroupOf_right x y)).trans
    ((QuotientGroup.quotientInfEquivProdNormalizerQuotient y x hy).trans ?_)
  exact quotCongr (sup_comm y x)

theorem step_inf {x y : Subgroup G} (h : IsSimpleStep (x ⊔ y) x) : IsSimpleStep y (x ⊓ y) := by
  obtain ⟨h1, h2, ⟨e⟩⟩ := second_iso_step h
  have hs := h.2.2
  exact ⟨inf_le_right, h1, e.isSimpleGroup⟩

theorem step_sup_eq {x y z : Subgroup G} (hx : IsSimpleStep z x) (hy : IsSimpleStep z y)
    (hne : x ≠ y) : x ⊔ y = z := by
  have hzx : z ≤ Subgroup.normalizer (x : Set G) := (step_iff_normalizer hx.1).mp hx.2.1
  have hzy : z ≤ Subgroup.normalizer (y : Set G) := (step_iff_normalizer hy.1).mp hy.2.1
  have hzs : z ≤ Subgroup.normalizer ((x ⊔ y : Subgroup G) : Set G) :=
    (le_inf hzx hzy).trans (Subgroup.inf_normalizer_le_normalizer_sup x y)
  rcases step_eq hx le_sup_left (sup_le hx.1 hy.1) hzs with h | h
  · have hyx : y ≤ x := sup_eq_left.mp h
    rcases step_eq hy hyx hx.1 hzx with h' | h'
    · exact absurd h' hne
    · exact absurd h' (step_lt hx).ne
  · exact h

/-- Subgroups with "one simple step down" form a Jordan-Holder lattice. -/
@[instance_reducible]
def jhl : JordanHolderLattice (Subgroup G) where
  IsMaximal x y := IsSimpleStep y x
  lt_of_isMaximal h := step_lt h
  sup_eq_of_isMaximal hx hy hne := step_sup_eq hx hy hne
  isMaximal_inf_left_of_isMaximal_sup {x y} _ hy := by
    have h : IsSimpleStep (y ⊔ x) y := by rw [sup_comm]; exact hy
    have := step_inf h
    rwa [inf_comm] at this

/-- Two steps (lower, upper) with isomorphic quotients. -/
def QIso (p q : Subgroup G × Subgroup G) : Prop :=
  p = q ∨ ∃ (_ : (p.1.subgroupOf p.2).Normal) (_ : (q.1.subgroupOf q.2).Normal),
    Nonempty (p.2 ⧸ p.1.subgroupOf p.2 ≃* q.2 ⧸ q.1.subgroupOf q.2)

theorem qiso_of_iso {p q : Subgroup G × Subgroup G}
    (h : @JordanHolderLattice.Iso (Subgroup G) _ jhl p q) : QIso p q := by
  let := jhl (G := G)
  refine JordanHolderLattice.Iso.rel QIso (Or.inl rfl) ?_ ?_ ?_ h
  · rintro x y (rfl | ⟨h1, h2, ⟨e⟩⟩)
    · exact Or.inl rfl
    · exact Or.inr ⟨h2, h1, ⟨e.symm⟩⟩
  · rintro x y z (rfl | ⟨h1, h2, ⟨e⟩⟩) (rfl | ⟨h3, h4, ⟨e'⟩⟩)
    · exact Or.inl rfl
    · exact Or.inr ⟨h3, h4, ⟨e'⟩⟩
    · exact Or.inr ⟨h1, h2, ⟨e⟩⟩
    · exact Or.inr ⟨h1, h4, ⟨e.trans e'⟩⟩
  · intro x y hm
    obtain ⟨h1, h2, ⟨e⟩⟩ := second_iso_step (show IsSimpleStep (x ⊔ y) x from hm)
    exact Or.inr ⟨h2, h1, ⟨e.symm⟩⟩

/-- A chain read from the bottom up, as a Mathlib composition series. -/
abbrev revSeries (s : SimpleChain G) : @CompositionSeries (Subgroup G) _ jhl where
  length := s.length
  toFun i := s (Fin.rev i)
  step i := by
    show IsSimpleStep (s (Fin.rev i.succ)) (s (Fin.rev i.castSucc))
    rw [Fin.rev_succ, Fin.rev_castSucc]
    exact s.step (Fin.rev i)

theorem revSeries_apply (s : SimpleChain G) (i) :
    (revSeries s : @CompositionSeries (Subgroup G) _ jhl) i = s (Fin.rev i) := rfl

theorem revSeries_head (s : SimpleChain G) :
    RelSeries.head (revSeries s : @CompositionSeries (Subgroup G) _ jhl) = s.last := by
  show s (Fin.rev 0) = s (Fin.last _)
  rw [Fin.rev_zero]

theorem revSeries_last (s : SimpleChain G) :
    RelSeries.last (revSeries s : @CompositionSeries (Subgroup G) _ jhl) = s.head := by
  show s (Fin.rev (Fin.last _)) = s 0
  rw [Fin.rev_last]

theorem exists_chain [Finite G] (H : Subgroup G) :
    ∃ s : SimpleChain G, s.head = H ∧ s.last = ⊥ := by
  have : Finite (Subgroup G) :=
    Finite.of_injective (fun H : Subgroup G => (H : Set G)) SetLike.coe_injective
  induction H using WellFoundedLT.induction with
  | _ H ih =>
  by_cases hH : H = ⊥
  · exact ⟨RelSeries.singleton _ ⊥, by simp [hH], by simp⟩
  · let S : Set (Subgroup G) := {N | N < H ∧ H ≤ Subgroup.normalizer (N : Set G)}
    have hne : S.Nonempty := ⟨⊥, bot_lt_iff_ne_bot.mpr hH, Subgroup.le_normalizer_of_normal⟩
    obtain ⟨N, hN⟩ := S.toFinite.exists_maximal hne
    have hstep : IsSimpleStep H N := by
      refine step_mk hN.1.1 hN.1.2 fun C hBC hCA hn => ?_
      by_cases hCH : C = H
      · exact Or.inr hCH
      · exact Or.inl ((hN.2 ⟨lt_of_le_of_ne hCA hCH, hn⟩ hBC).antisymm hBC)
    obtain ⟨s, hs1, hs2⟩ := ih N hN.1.1
    have hrel : (H, s.head) ∈ simpleStep G := by rw [hs1]; exact hstep
    exact ⟨s.cons H hrel, by simp, by simp [hs2]⟩

/-- Equal steps give the same quotient. -/
def quotCongr2 {A A' B B' : Subgroup G} (hA : A = A') (hB : B = B') [(B.subgroupOf A).Normal]
    [(B'.subgroupOf A').Normal] : A ⧸ B.subgroupOf A ≃* A' ⧸ B'.subgroupOf A' := by
  subst hA hB; exact MulEquiv.refl _

/-- **Jordan-Holder.** Every finite group breaks down, one simple step at a time, into
simple pieces; and any two such breakdowns have the same length, with their pieces
matching in pairs as isomorphic groups, perhaps in a different order. -/
theorem jordan_holder [Finite G] :
    (∃ s : SimpleChain G, IsCompositionSeries s) ∧
    ∀ s t : SimpleChain G, IsCompositionSeries s → IsCompositionSeries t →
      s.length = t.length ∧
      ∃ σ : Fin s.length ≃ Fin t.length, ∀ i, Nonempty (factor s i ≃* factor t (σ i)) := by
  refine ⟨?_, fun s t hs ht => ?_⟩
  · obtain ⟨s, h1, h2⟩ := exists_chain (⊤ : Subgroup G)
    exact ⟨s, h1, h2⟩
  · let := jhl (G := G)
    obtain ⟨f, hf⟩ := CompositionSeries.jordan_holder (revSeries s) (revSeries t)
      (by rw [revSeries_head, revSeries_head, hs.2, ht.2])
      (by rw [revSeries_last, revSeries_last, hs.1, ht.1])
    have hlen : s.length = t.length := by
      simpa using Fintype.card_congr f
    let σ : Fin s.length ≃ Fin t.length :=
      { toFun := fun i => Fin.rev (f (Fin.rev i))
        invFun := fun j => Fin.rev (f.symm (Fin.rev j))
        left_inv := fun i => by simp
        right_inv := fun j => by simp }
    refine ⟨hlen, σ, fun i => ?_⟩
    have h := qiso_of_iso (hf (Fin.rev i))
    simp only [Fin.rev_castSucc, Fin.rev_succ, Fin.rev_rev] at h
    show Nonempty (factor s i ≃* factor t (Fin.rev (f (Fin.rev i))))
    rcases h with h | ⟨h1, h2, ⟨e⟩⟩
    · simp only [Prod.mk.injEq] at h
      exact ⟨quotCongr2 h.2 h.1⟩
    · exact ⟨e⟩

/-- A finite group is solvable exactly when every piece of a composition series is a
clock of prime size: a cyclic group whose number of members is prime. -/
theorem isSolvable_iff_factors_cyclic_of_prime_order [Finite G]
    (s : SimpleChain G) (hs : IsCompositionSeries s) :
    Group.IsSolvable G ↔ ∀ i, IsCyclic (factor s i) ∧ (Nat.card (factor s i)).Prime := by
  constructor
  · intro hG i
    have hsimple : IsSimpleGroup (factor s i) := (s.step i).2.2
    have hsolv : Group.IsSolvable (factor s i) :=
      inferInstanceAs (Group.IsSolvable (s i.castSucc ⧸ (s i.succ).subgroupOf (s i.castSucc)))
    have hcomm := (IsSimpleGroup.comm_iff_isSolvable (G := factor s i)).mpr hsolv
    let _ : CommGroup (factor s i) := { mul_comm := hcomm }
    exact ⟨IsSimpleGroup.isCyclic, IsSimpleGroup.prime_card⟩
  · intro hf
    have key : ∀ j : Fin (s.length + 1), Group.IsSolvable (s j) := by
      intro j
      induction j using Fin.reverseInduction with
      | last =>
        have : s (Fin.last _) = ⊥ := hs.2
        rw [this]; infer_instance
      | cast i ih =>
        have hle : s i.succ ≤ s i.castSucc := (s.step i).1
        have : Group.IsSolvable ((s i.succ).subgroupOf (s i.castSucc)) :=
          Group.isSolvable_of_isSolvable_injective (f := (Subgroup.subgroupOfEquivOfLe hle).toMonoidHom)
            (Subgroup.subgroupOfEquivOfLe hle).injective
        have : IsCyclic (factor s i) := (hf i).1
        have : Group.IsSolvable (factor s i) :=
          Group.isSolvable_of_comm (IsCyclic.commGroup (α := factor s i)).mul_comm
        have : Group.IsSolvable (s i.castSucc ⧸ (s i.succ).subgroupOf (s i.castSucc)) :=
          inferInstanceAs (Group.IsSolvable (factor s i))
        refine Group.isSolvable_of_ker_le_range ((s i.succ).subgroupOf (s i.castSucc)).subtype
          (QuotientGroup.mk' ((s i.succ).subgroupOf (s i.castSucc))) ?_
        rw [QuotientGroup.ker_mk', Subgroup.range_subtype]
    have h0 : s 0 = ⊤ := hs.1
    have := key 0
    rw [h0] at this
    exact Group.isSolvable_of_surjective (f := (Subgroup.topEquiv (G := G)).toMonoidHom)
      Subgroup.topEquiv.surjective

end CompositionSeriesCard

/-- The shuffles of 4 cards form a solvable group; the shuffles of 5 cards do not. -/
theorem s4_solvable_and_s5_not_solvable :
    Group.IsSolvable (Equiv.Perm (Fin 4)) ∧ ¬ Group.IsSolvable (Equiv.Perm (Fin 5)) := by
  exact ⟨Equiv.Perm.isSolvable (by simp), Equiv.Perm.not_isSolvable_fin_5⟩

-- Z mod 12, first route down: sizes 12, 6, 3, 1 give factors 2, 2, 3.
example : (12 / 6, 6 / 3, 3 / 1) = (2, 2, 3) := by decide
-- Second route: sizes 12, 4, 2, 1 give factors 3, 2, 2.
example : (12 / 4, 4 / 2, 2 / 1) = (3, 2, 2) := by decide
-- Both routes give the prime factorisation of 12.
example : Nat.primeFactorsList 12 = [2, 2, 3] := by simp
-- The diamond: |H| |K| / |H ∩ K| = 6 × 4 / 2 = 12, and the pieces pair off.
example : 6 * 4 / 2 = 12 ∧ 12 / 6 = 4 / 2 ∧ 12 / 4 = 6 / 2 := by decide
-- S4 route: sizes 24, 12, 4, 2, 1 give factors 2, 3, 2, 2, all prime.
example : (24 / 12, 12 / 4, 4 / 2, 2 / 1) = (2, 3, 2, 2) := by decide
example : Nat.Prime 2 ∧ Nat.Prime 3 := by norm_num
-- S5 route: sizes 120, 60, 1 give factors 2 and 60, and 60 is not prime.
example : (120 / 60, 60 / 1) = (2, 60) := by decide
example : ¬ Nat.Prime 60 := by norm_num
-- The group sizes used: S4 has 24 members, S5 has 120, A4 has 12, A5 has 60.
example : Fintype.card (Equiv.Perm (Fin 4)) = 24 := by simp [Fintype.card_perm, Nat.factorial]
example : Fintype.card (Equiv.Perm (Fin 5)) = 120 := by simp [Fintype.card_perm, Nat.factorial]
-- The square tile (8 moves) has 40 commuting ordered pairs; Z mod 8 has all 64.
example : (Finset.univ.filter
    (fun p : DihedralGroup 4 × DihedralGroup 4 => p.1 * p.2 = p.2 * p.1)).card = 40 := by
  decide
example : (Finset.univ.filter
    (fun p : Multiplicative (ZMod 8) × Multiplicative (ZMod 8) => p.1 * p.2 = p.2 * p.1)).card
      = 64 := by
  decide

open CompositionSeriesCard in
#print axioms jordan_holder
open CompositionSeriesCard in
#print axioms isSolvable_iff_factors_cyclic_of_prime_order
#print axioms s4_solvable_and_s5_not_solvable
#print axioms simple_quot_iff
open CompositionSeriesCard in
#print axioms step_iff_normalizer
open CompositionSeriesCard in
#print axioms step_lt
open CompositionSeriesCard in
#print axioms step_eq
open CompositionSeriesCard in
#print axioms step_mk
open CompositionSeriesCard in
#print axioms quotCongr
open CompositionSeriesCard in
#print axioms second_iso_step
open CompositionSeriesCard in
#print axioms step_inf
open CompositionSeriesCard in
#print axioms step_sup_eq
open CompositionSeriesCard in
#print axioms jhl
open CompositionSeriesCard in
#print axioms QIso
open CompositionSeriesCard in
#print axioms qiso_of_iso
open CompositionSeriesCard in
#print axioms revSeries
open CompositionSeriesCard in
#print axioms revSeries_apply
open CompositionSeriesCard in
#print axioms revSeries_head
open CompositionSeriesCard in
#print axioms revSeries_last
open CompositionSeriesCard in
#print axioms exists_chain
open CompositionSeriesCard in
#print axioms quotCongr2
