-- Edmonds' blossom algorithm: shrinking a blossom the search found keeps a matching largest exactly when the shrunk matching is largest in the shrunk graph, and shrinking removes the k paired lines inside the ring.
import Mathlib.Combinatorics.SimpleGraph.Matching
import Mathlib.Combinatorics.SimpleGraph.Maps
import Mathlib.Combinatorics.SimpleGraph.Coloring.Vertex
import Mathlib.Combinatorics.SimpleGraph.Coloring.Constructions
import Mathlib.Order.Interval.Set.Nat

open SimpleGraph

/-! A matching is a `Subgraph` `M` of `G` in which every dot it uses has exactly one partner
(Mathlib's `Subgraph.IsMatching`); its count of lines is `M.edgeSet.ncard`. A dot is free when
it is not in `M.verts`. The ring is a cycle `c : G.Walk b b` (Mathlib's `Walk.IsCycle`) starting
and ending at its base `b`; its `i`-th line joins `c.getVert i` and `c.getVert (i + 1)`. -/

/-- `M` is a largest matching of `G`: it is a matching and no matching of `G` has more lines. -/
def IsMaximumMatching {V : Type*} {G : SimpleGraph V} (M : G.Subgraph) : Prop :=
  M.IsMatching ∧ ∀ N : G.Subgraph, N.IsMatching → N.edgeSet.ncard ≤ M.edgeSet.ncard

/-- The dots of the shrunk graph `G/B`: every dot outside the ring `S`, plus the base `b`,
which stands for the new single dot B. -/
abbrev ShrunkDot {V : Type*} (S : Set V) (b : V) : Type _ := {v : V // v ∉ S ∨ v = b}

/-- Shrinking the ring `S` to one dot: every dot of `S` goes to B (named by the base `b`),
every other dot stays where it is. -/
def shrink {V : Type*} (S : Set V) [DecidablePred (· ∈ S)] (b : V) (v : V) : ShrunkDot S b :=
  if h : v ∈ S then ⟨b, Or.inr rfl⟩ else ⟨v, Or.inl h⟩

/-- The shrunk graph `G/B` is `G.map f` for the shrinking map `f`: two dots of `G/B` are joined
when they are different and some line of `G` joins dots that go to them. Lines inside the ring
become loops and vanish. The shrunk matching `M/B` is the image of `M` in the same way: its lines
are the lines of `M` that do not lie inside the ring. -/
def shrunkMatching {V W : Type*} {G : SimpleGraph V} (M : G.Subgraph) (f : V → W) :
    (G.map f).Subgraph where
  verts := (M.spanningCoe.map f).support
  Adj := (M.spanningCoe.map f).Adj
  adj_sub h := SimpleGraph.map_monotone f M.spanningCoe_le h
  edge_vert h := ⟨_, h⟩
  symm := (M.spanningCoe.map f).symm

namespace Blossom

variable {V : Type*}

/-- Each dot has at most one partner. -/
def Fn {W : Type*} (H : SimpleGraph W) : Prop := ∀ ⦃u v w : W⦄, H.Adj u v → H.Adj u w → v = w

/-- The lines with both ends in `S`. -/
def inside (S : Set V) : Set (Sym2 V) := {e | ∀ v ∈ e, v ∈ S}

theorem fn_support_ncard {W : Type*} [Finite W] {H : SimpleGraph W} (hH : Fn H) :
    H.support.ncard = 2 * H.edgeSet.ncard := by
  classical
  have := Fintype.ofFinite W
  have hdeg : ∀ v, H.degree v = if v ∈ H.support then 1 else 0 := by
    intro v
    split_ifs with hv
    · obtain ⟨w, hw⟩ := (SimpleGraph.mem_support H).mp hv
      rw [← card_neighborFinset_eq_degree, Finset.card_eq_one]
      refine ⟨w, ?_⟩
      ext x
      simp only [mem_neighborFinset, Finset.mem_singleton]
      exact ⟨fun hx => hH hx hw, fun hx => hx ▸ hw⟩
    · rw [← card_neighborFinset_eq_degree, Finset.card_eq_zero]
      ext x
      simp only [mem_neighborFinset, Finset.notMem_empty, iff_false]
      exact fun hx => hv ((SimpleGraph.mem_support H).mpr ⟨x, hx⟩)
  have h1 := H.sum_degrees_eq_twice_card_edges
  simp only [hdeg, Finset.sum_boole] at h1
  rw [← coe_edgeFinset, Set.ncard_coe_finset, ← h1, Set.ncard_eq_toFinset_card']
  congr 1
  ext v
  simp

/-- A graph's lines as a subgraph whose dots are the dots it uses. -/
def toSub {W : Type*} {G' : SimpleGraph W} (H : SimpleGraph W) (h : H ≤ G') : G'.Subgraph where
  verts := H.support
  Adj := H.Adj
  adj_sub hh := h hh
  edge_vert hh := (SimpleGraph.mem_support _).mpr ⟨_, hh⟩
  symm := H.symm

theorem toSub_isMatching {W : Type*} {G' : SimpleGraph W} {H : SimpleGraph W} (h : H ≤ G')
    (hH : Fn H) : (toSub H h).IsMatching := by
  intro v hv
  obtain ⟨w, hw⟩ := (SimpleGraph.mem_support H).mp hv
  exact ⟨w, hw, fun w' hw' => hH hw' hw⟩

theorem toSub_edgeSet {W : Type*} {G' : SimpleGraph W} {H : SimpleGraph W} (h : H ≤ G') :
    (toSub H h).edgeSet = H.edgeSet := by
  ext e
  induction e using Sym2.ind with
  | _ v w => rfl

theorem fn_of_isMatching {W : Type*} {G' : SimpleGraph W} {M : G'.Subgraph} (hM : M.IsMatching) :
    Fn M.spanningCoe := fun _ _ _ h1 h2 => hM.eq_of_adj_left h1 h2

theorem shrunk_edgeSet {W : Type*} {G : SimpleGraph V} (M : G.Subgraph) (f : V → W) :
    (shrunkMatching M f).edgeSet = (M.spanningCoe.map f).edgeSet := by
  ext e
  induction e using Sym2.ind with
  | _ v w => rfl

theorem shrunk_isMatching {W : Type*} {G : SimpleGraph V} (M : G.Subgraph) (f : V → W)
    (h : Fn (M.spanningCoe.map f)) : (shrunkMatching M f).IsMatching := by
  intro v hv
  obtain ⟨w, hw⟩ := (SimpleGraph.mem_support _).mp hv
  exact ⟨w, hw, fun w' hw' => h hw' hw⟩

section shrinkS
variable {S : Set V} [DecidablePred (· ∈ S)] {b : V}

theorem shrink_of_mem {v : V} (h : v ∈ S) : shrink S b v = ⟨b, Or.inr rfl⟩ := by
  simp [shrink, h]

theorem shrink_of_not_mem {v : V} (h : v ∉ S) : shrink S b v = ⟨v, Or.inl h⟩ := by
  simp [shrink, h]

theorem shrink_eq_iff (hb : b ∈ S) {u v : V} :
    shrink S b u = shrink S b v ↔ u = v ∨ (u ∈ S ∧ v ∈ S) := by
  by_cases hu : u ∈ S <;> by_cases hv : v ∈ S
  · simp [shrink_of_mem hu, shrink_of_mem hv, hu, hv]
  · rw [shrink_of_mem hu, shrink_of_not_mem hv, Subtype.mk.injEq]
    constructor
    · rintro rfl; exact absurd hb hv
    · rintro (rfl | ⟨-, h⟩); exacts [absurd hu hv, absurd h hv]
  · rw [shrink_of_not_mem hu, shrink_of_mem hv, Subtype.mk.injEq]
    constructor
    · rintro rfl; exact absurd hb hu
    · rintro (rfl | ⟨h, -⟩); exacts [absurd hv hu, absurd h hu]
  · rw [shrink_of_not_mem hu, shrink_of_not_mem hv, Subtype.mk.injEq]
    simp [hu]

theorem shrink_eq_B_iff (hb : b ∈ S) {u : V} : shrink S b u = ⟨b, Or.inr rfl⟩ ↔ u ∈ S := by
  rw [← shrink_of_mem (S := S) (b := b) hb, shrink_eq_iff hb]
  constructor
  · rintro (rfl | ⟨h, -⟩); exacts [hb, h]
  · intro h; exact Or.inr ⟨h, hb⟩

theorem map_edgeSet (hb : b ∈ S) (H : SimpleGraph V) :
    (H.map (shrink S b)).edgeSet = Sym2.map (shrink S b) '' (H.edgeSet \ inside S) := by
  ext e
  induction e using Sym2.ind with
  | _ p q =>
  rw [mem_edgeSet, map_adj']
  constructor
  · rintro ⟨hne, u, v, huv, rfl, rfl⟩
    refine ⟨s(u, v), ⟨huv, ?_⟩, rfl⟩
    intro hin
    apply hne
    rw [shrink_eq_iff hb]
    exact Or.inr ⟨hin u (Sym2.mem_mk_left _ _), hin v (Sym2.mem_mk_right _ _)⟩
  · rintro ⟨e', ⟨he', hin⟩, heq⟩
    induction e' using Sym2.ind with
    | _ u v =>
    rw [Sym2.map_mk, Sym2.eq_iff] at heq
    rw [mem_edgeSet] at he'
    have hne : shrink S b u ≠ shrink S b v := by
      rw [Ne, shrink_eq_iff hb]
      rintro (h | ⟨hu, hv⟩)
      · subst h; exact he'.ne rfl
      · apply hin
        intro w hw
        rw [Sym2.mem_iff] at hw
        rcases hw with rfl | rfl <;> assumption
    rcases heq with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
    · exact ⟨hne, u, v, he', rfl, rfl⟩
    · exact ⟨hne.symm, v, u, he'.symm, rfl, rfl⟩

theorem map_pair_inj (hb : b ∈ S) {H : SimpleGraph V} (hH : Fn H) {u1 v1 u2 v2 : V}
    (h1 : H.Adj u1 v1) (h2 : H.Adj u2 v2) (hn : ¬ (u1 ∈ S ∧ v1 ∈ S))
    (hu : shrink S b u1 = shrink S b u2) (hv : shrink S b v1 = shrink S b v2) :
    s(u1, v1) = s(u2, v2) := by
  rw [shrink_eq_iff hb] at hu hv
  rcases hu with rfl | ⟨hu1, hu2⟩ <;> rcases hv with rfl | ⟨hv1, hv2⟩
  · rfl
  · rw [hH h1 h2]
  · rw [hH h1.symm h2.symm]
  · exact absurd ⟨hu1, hv1⟩ hn

theorem injOn_map (hb : b ∈ S) {H : SimpleGraph V} (hH : Fn H) :
    Set.InjOn (Sym2.map (shrink S b)) (H.edgeSet \ inside S) := by
  rintro e1 ⟨h1, n1⟩ e2 ⟨h2, -⟩ heq
  induction e1 using Sym2.ind with
  | _ u1 v1 =>
  induction e2 using Sym2.ind with
  | _ u2 v2 =>
  rw [mem_edgeSet] at h1 h2
  have hn : ¬ (u1 ∈ S ∧ v1 ∈ S) := by
    rintro ⟨hu, hv⟩
    apply n1
    intro w hw
    rw [Sym2.mem_iff] at hw
    rcases hw with rfl | rfl <;> assumption
  rw [Sym2.map_mk, Sym2.map_mk, Sym2.eq_iff] at heq
  rcases heq with ⟨hu, hv⟩ | ⟨hu, hv⟩
  · exact map_pair_inj hb hH h1 h2 hn hu hv
  · rw [map_pair_inj hb hH h1 h2.symm hn hu hv, Sym2.eq_swap]

theorem card_map_add_inside [Finite V] (hb : b ∈ S) {H : SimpleGraph V} (hH : Fn H) :
    (H.map (shrink S b)).edgeSet.ncard + (H.edgeSet ∩ inside S).ncard = H.edgeSet.ncard := by
  rw [map_edgeSet hb, (injOn_map hb hH).ncard_image, add_comm,
    Set.ncard_inter_add_ncard_sdiff_eq_ncard _ _ (Set.toFinite _)]

theorem fn_map (hb : b ∈ S) {H : SimpleGraph V} (hH : Fn H)
    (hcross : ∀ u w, H.Adj u w → u ∈ S → w ∉ S → u = b) : Fn (H.map (shrink S b)) := by
  rintro p q q' ⟨hpq, u, v, huv, rfl, rfl⟩ ⟨hpq', u', v', huv', hu', rfl⟩
  have hu2 := hu'
  rw [shrink_eq_iff hb] at hu'
  rcases hu' with rfl | ⟨hu'S, huS⟩
  · rw [hH huv huv']
  · have hv : v ∉ S := fun hv => hpq ((shrink_eq_iff hb).mpr (Or.inr ⟨huS, hv⟩))
    have hv' : v' ∉ S := fun hv' => hpq' (hu2 ▸ (shrink_eq_iff hb).mpr (Or.inr ⟨hu'S, hv'⟩))
    have e1 := hcross u v huv huS hv
    have e2 := hcross u' v' huv' hu'S hv'
    subst e1 e2
    rw [hH huv huv']

end shrinkS

#print axioms fn_support_ncard
#print axioms toSub_isMatching
#print axioms toSub_edgeSet
#print axioms fn_of_isMatching
#print axioms shrunk_edgeSet
#print axioms shrunk_isMatching
#print axioms shrink_of_mem
#print axioms shrink_of_not_mem
#print axioms shrink_eq_iff
#print axioms shrink_eq_B_iff
#print axioms map_edgeSet
#print axioms map_pair_inj
#print axioms injOn_map
#print axioms card_map_add_inside
#print axioms fn_map

end Blossom

namespace Blossom

variable {V : Type*}

theorem sym2_ne_of {u w a c : V} (h1 : u ≠ a) (h2 : u ≠ c) : s(u, w) ≠ s(a, c) := by
  rw [Ne, Sym2.eq_iff]; tauto

theorem augment {W : Type*} [Finite W] {G' A : SimpleGraph W} (hA : A ≤ G') (hAf : Fn A)
    {p q : W} (hpq : G'.Adj p q) (hp : ∀ w, ¬ A.Adj p w) (hq : ∀ w, ¬ A.Adj q w) :
    ∃ K : SimpleGraph W, K ≤ G' ∧ Fn K ∧ A.edgeSet.ncard < K.edgeSet.ncard := by
  let K := SimpleGraph.fromEdgeSet (insert s(p, q) A.edgeSet)
  have hK : ∀ v w, K.Adj v w ↔ (s(v, w) = s(p, q) ∨ A.Adj v w) ∧ v ≠ w := by
    intro v w; simp [K, fromEdgeSet_adj]
  refine ⟨K, ?_, ?_, ?_⟩
  · intro v w h
    rw [hK] at h
    rcases h with ⟨h | h, -⟩
    · rw [Sym2.eq_iff] at h
      rcases h with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
      exacts [hpq, hpq.symm]
    · exact hA h
  · intro v w w' h h'
    rw [hK] at h h'
    rcases h with ⟨h | h, hne⟩ <;> rcases h' with ⟨h' | h', hne'⟩
    · rw [Sym2.eq_iff] at h h'
      rcases h with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ <;> rcases h' with ⟨h1, rfl⟩ | ⟨h1, rfl⟩ <;> simp_all
    · rw [Sym2.eq_iff] at h
      rcases h with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
      exacts [absurd h' (hp _), absurd h' (hq _)]
    · rw [Sym2.eq_iff] at h'
      rcases h' with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
      exacts [absurd h (hp _), absurd h (hq _)]
    · exact hAf h h'
  · apply Set.ncard_lt_ncard _ (Set.toFinite _)
    rw [Set.ssubset_def]
    constructor
    · intro e he
      induction e using Sym2.ind with
      | _ v w =>
      rw [mem_edgeSet] at he ⊢
      exact (hK v w).mpr ⟨Or.inr he, he.ne⟩
    · intro h
      have : s(p, q) ∈ K.edgeSet := by
        rw [mem_edgeSet]; exact (hK p q).mpr ⟨Or.inl rfl, hpq.ne⟩
      exact hp q (h this)

/-- Pass the partner of `y` from `z` to the free dot `x`. -/
def swap (H : SimpleGraph V) (x y z : V) : SimpleGraph V :=
  SimpleGraph.fromEdgeSet (insert s(x, y) (H.edgeSet \ {s(y, z)}))

theorem swap_adj {H : SimpleGraph V} {x y z u v : V} :
    (swap H x y z).Adj u v ↔ (s(u, v) = s(x, y) ∨ (H.Adj u v ∧ s(u, v) ≠ s(y, z))) ∧ u ≠ v := by
  simp [swap, fromEdgeSet_adj]

theorem swap_adj_of {H : SimpleGraph V} {x y z u v : V} (h1 : s(u, v) ≠ s(x, y))
    (h2 : s(u, v) ≠ s(y, z)) : (swap H x y z).Adj u v ↔ H.Adj u v := by
  rw [swap_adj]
  constructor
  · rintro ⟨h | ⟨h, -⟩, -⟩; exacts [absurd h h1, h]
  · intro h; exact ⟨Or.inr ⟨h, h2⟩, h.ne⟩

theorem swap_le {G H : SimpleGraph V} {x y z : V} (hH : H ≤ G) (hxy : G.Adj x y) :
    swap H x y z ≤ G := by
  intro u v h
  rw [swap_adj] at h
  rcases h with ⟨h | ⟨h, -⟩, -⟩
  · rw [Sym2.eq_iff] at h
    rcases h with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
    exacts [hxy, hxy.symm]
  · exact hH h

theorem swap_fn {H : SimpleGraph V} {x y z : V} (hH : Fn H) (hx : ∀ w, ¬ H.Adj x w)
    (hyz : H.Adj y z) (hxy : x ≠ y) : Fn (swap H x y z) := by
  intro u v w h h'
  rw [swap_adj] at h h'
  rcases h with ⟨h | ⟨h, hn⟩, hne⟩ <;> rcases h' with ⟨h' | ⟨h', hn'⟩, hne'⟩
  · rw [Sym2.eq_iff] at h h'
    rcases h with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ <;> rcases h' with ⟨h1, rfl⟩ | ⟨h1, rfl⟩ <;> simp_all
  · rw [Sym2.eq_iff] at h
    rcases h with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
    · exact absurd h' (hx _)
    · have := hH h' hyz; subst this; exact absurd rfl hn'
  · rw [Sym2.eq_iff] at h'
    rcases h' with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
    · exact absurd h (hx _)
    · have := hH h hyz; subst this; exact absurd rfl hn
  · exact hH h h'

theorem swap_edgeSet {H : SimpleGraph V} {x y z : V} (hxy : x ≠ y) :
    (swap H x y z).edgeSet = insert s(x, y) (H.edgeSet \ {s(y, z)}) := by
  ext e
  induction e using Sym2.ind with
  | _ u v =>
  rw [mem_edgeSet, swap_adj]
  simp only [Set.mem_insert_iff, Set.mem_sdiff, mem_edgeSet, Set.mem_singleton_iff]
  constructor
  · rintro ⟨h, -⟩; exact h
  · rintro (h | h)
    · refine ⟨Or.inl h, ?_⟩
      rintro rfl
      rw [Sym2.eq_iff] at h
      rcases h with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ <;> exact hxy rfl
    · exact ⟨Or.inr h, h.1.ne⟩

theorem swap_card [Finite V] {H : SimpleGraph V} {x y z : V} (hx : ∀ w, ¬ H.Adj x w)
    (hyz : H.Adj y z) (hxy : x ≠ y) : (swap H x y z).edgeSet.ncard = H.edgeSet.ncard := by
  rw [swap_edgeSet hxy, Set.ncard_insert_of_notMem, Set.ncard_sdiff_singleton_add_one]
  · exact hyz
  · rintro ⟨h, -⟩; exact hx y h

theorem swap_z_free {H : SimpleGraph V} {x y z : V} (hH : Fn H) (hx : ∀ w, ¬ H.Adj x w)
    (hyz : H.Adj y z) : ∀ w, ¬ (swap H x y z).Adj z w := by
  intro w h
  rw [swap_adj] at h
  rcases h with ⟨h | ⟨h, hn⟩, -⟩
  · rw [Sym2.eq_iff] at h
    rcases h with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
    · exact hx _ hyz.symm
    · exact hyz.ne rfl
  · have := hH h hyz.symm; subst this
    exact hn (Sym2.eq_swap)

theorem swap_adj_xy {H : SimpleGraph V} {x y z : V} (hxy : x ≠ y) : (swap H x y z).Adj x y :=
  swap_adj.mpr ⟨Or.inl rfl, hxy⟩

#print axioms sym2_ne_of
#print axioms augment
#print axioms swap_adj
#print axioms swap_adj_of
#print axioms swap_le
#print axioms swap_fn
#print axioms swap_edgeSet
#print axioms swap_card
#print axioms swap_z_free
#print axioms swap_adj_xy

end Blossom

namespace Blossom

variable {V : Type*}

section shrinkS
variable {S : Set V} [DecidablePred (· ∈ S)] {b : V}

theorem free_map (hb : b ∈ S) {H : SimpleGraph V} (h1 : ∀ u w, H.Adj u w → u ∈ S → w ∈ S)
    {v : V} (hv : v ∈ S ∨ ∀ w, ¬ H.Adj v w) : ∀ q, ¬ (H.map (shrink S b)).Adj (shrink S b v) q := by
  rintro q ⟨hne, u, w, huw, hu, rfl⟩
  rw [shrink_eq_iff hb] at hu
  rcases hu with rfl | ⟨huS, hvS⟩
  · rcases hv with hvS | hv
    · exact hne ((shrink_eq_iff hb).mpr (Or.inr ⟨hvS, h1 _ _ huw hvS⟩))
    · exact hv _ huw
  · exact hne ((shrink_eq_iff hb).mpr (Or.inr ⟨hvS, h1 _ _ huw huS⟩))

theorem main_aug [Finite V] (hb : b ∈ S) {G N : SimpleGraph V} (hN : N ≤ G) (hNf : Fn N) :
    ∀ n, ∀ H : SimpleGraph V, (N.edgeSet \ H.edgeSet).ncard = n → H ≤ G → Fn H →
      (∀ u w, H.Adj u w → u ∈ S → w ∈ S) → (∀ u ∈ S, u ≠ b → ∃ w, H.Adj u w) →
      H.edgeSet.ncard < N.edgeSet.ncard →
      ∃ K, K ≤ G.map (shrink S b) ∧ Fn K ∧
        (H.map (shrink S b)).edgeSet.ncard < K.edgeSet.ncard := by
  intro n
  induction n using Nat.strong_induction_on with
  | _ n ih =>
  intro H hn hHG hHf h1 h2 hlt
  have hcross : ∀ u w, H.Adj u w → u ∈ S → w ∉ S → u = b :=
    fun u w h hu hw => absurd (h1 u w h hu) hw
  have hAf : Fn (H.map (shrink S b)) := fn_map hb hHf hcross
  have hAG : H.map (shrink S b) ≤ G.map (shrink S b) := SimpleGraph.map_monotone _ hHG
  obtain ⟨x, hxS, hxH, y, hxy⟩ : ∃ x, x ∉ S ∧ (∀ w, ¬ H.Adj x w) ∧ ∃ y, N.Adj x y := by
    by_contra hcon
    push Not at hcon
    have hsub : N.support ⊆ H.support ∪ {b} := by
      intro v hv
      obtain ⟨y, hy⟩ := (SimpleGraph.mem_support N).mp hv
      by_cases hvH : ∃ w, H.Adj v w
      · exact Or.inl ((SimpleGraph.mem_support H).mpr hvH)
      · right
        push Not at hvH
        by_cases hvS : v ∈ S
        · by_contra hvb
          obtain ⟨w, hw⟩ := h2 v hvS hvb
          exact hvH w hw
        · exact absurd hy (hcon v hvS hvH y)
    have e1 := Set.ncard_le_ncard hsub (Set.toFinite _)
    have e2 := Set.ncard_union_le H.support {b}
    rw [fn_support_ncard hNf] at e1
    rw [fn_support_ncard hHf, Set.ncard_singleton] at e2
    omega
  have hGxy : G.Adj x y := hN hxy
  have hfx : ∀ q, ¬ (H.map (shrink S b)).Adj (shrink S b x) q := free_map hb h1 (Or.inr hxH)
  have hadj : (G.map (shrink S b)).Adj (shrink S b x) (shrink S b y) := by
    refine ⟨?_, x, y, hGxy, rfl, rfl⟩
    rw [Ne, shrink_eq_iff hb]
    rintro (h | ⟨h, -⟩)
    exacts [hGxy.ne h, hxS h]
  by_cases hy : ∃ z, H.Adj y z
  · obtain ⟨z, hyz⟩ := hy
    by_cases hyS : y ∈ S
    · obtain ⟨K, hK, hKf, hlt'⟩ := augment hAG hAf hadj hfx (free_map hb h1 (Or.inl hyS))
      exact ⟨K, hK, hKf, hlt'⟩
    · have hzS : z ∉ S := fun hz => hyS (h1 z y hyz.symm hz)
      have hxy' : x ≠ y := hGxy.ne
      have hzx : z ≠ x := fun h => hxH y (h ▸ hyz.symm)
      have hagree : ∀ u w, u ∈ S → ((swap H x y z).Adj u w ↔ H.Adj u w) := by
        intro u w hu
        apply swap_adj_of
        · exact sym2_ne_of (fun h => hxS (h ▸ hu)) (fun h => hyS (h ▸ hu))
        · exact sym2_ne_of (fun h => hyS (h ▸ hu)) (fun h => hzS (h ▸ hu))
      have hsub : N.edgeSet \ (swap H x y z).edgeSet ⊂ N.edgeSet \ H.edgeSet := by
        rw [Set.ssubset_def]
        constructor
        · rintro e ⟨heN, he1⟩
          refine ⟨heN, fun heH => he1 ?_⟩
          induction e using Sym2.ind with
          | _ u v =>
          rw [mem_edgeSet] at heN heH ⊢
          rw [swap_adj]
          refine ⟨Or.inr ⟨heH, ?_⟩, heH.ne⟩
          intro h
          rw [Sym2.eq_iff] at h
          rcases h with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
          · exact hzx (hNf heN hxy.symm)
          · exact hzx (hNf heN.symm hxy.symm)
        · intro h
          have : s(x, y) ∈ N.edgeSet \ H.edgeSet := ⟨hxy, hxH y⟩
          exact (h this).2 (swap_adj_xy hxy')
      have hlt2 := Set.ncard_lt_ncard hsub (Set.toFinite _)
      rw [hn] at hlt2
      have hcard := swap_card (z := z) hxH hyz hxy'
      obtain ⟨K, hK, hKf, hlt'⟩ := ih _ hlt2 (swap H x y z) rfl (swap_le hHG hGxy)
        (swap_fn hHf hxH hyz hxy')
        (fun u w h hu => h1 u w ((hagree u w hu).mp h) hu)
        (fun u hu hub => by
          obtain ⟨w, hw⟩ := h2 u hu hub
          exact ⟨w, (hagree u w hu).mpr hw⟩)
        (by rw [hcard]; exact hlt)
      refine ⟨K, hK, hKf, ?_⟩
      have c1 := card_map_add_inside hb hHf
      have c2 := card_map_add_inside hb (swap_fn hHf hxH hyz hxy')
      have hin : (swap H x y z).edgeSet ∩ inside S = H.edgeSet ∩ inside S := by
        ext e
        induction e using Sym2.ind with
        | _ u v =>
        simp only [Set.mem_inter_iff, mem_edgeSet]
        constructor
        · rintro ⟨h, hi⟩
          exact ⟨(hagree u v (hi u (Sym2.mem_mk_left _ _))).mp h, hi⟩
        · rintro ⟨h, hi⟩
          exact ⟨(hagree u v (hi u (Sym2.mem_mk_left _ _))).mpr h, hi⟩
      rw [hin, hcard] at c2
      omega
  · push Not at hy
    by_cases hyS : y ∈ S
    · exact augment hAG hAf hadj hfx (free_map hb h1 (Or.inl hyS))
    · exact augment hAG hAf hadj hfx (free_map hb h1 (Or.inr hy))

theorem lift [Finite V] (hb : b ∈ S) {G : SimpleGraph V} {k : ℕ}
    (hfc : ∀ u ∈ S, ∃ Q : SimpleGraph V, Q ≤ G ∧ Fn Q ∧ (∀ v w, Q.Adj v w → v ∈ S ∧ v ≠ u) ∧
      k ≤ Q.edgeSet.ncard)
    {K : SimpleGraph (ShrunkDot S b)} (hK : K ≤ G.map (shrink S b)) (hKf : Fn K) :
    ∃ H : SimpleGraph V, H ≤ G ∧ Fn H ∧ K.edgeSet.ncard + k ≤ H.edgeSet.ncard := by
  set f := shrink S b with hf
  set B : ShrunkDot S b := ⟨b, Or.inr rfl⟩ with hB
  obtain ⟨u, huS, hu⟩ : ∃ u ∈ S, ∀ w, w ∉ S → K.Adj B (f w) → G.Adj u w := by
    by_cases h : ∃ q, K.Adj B q
    · obtain ⟨q, hq⟩ := h
      obtain ⟨-, u0, w0, hG, hu0, hw0⟩ := hK hq
      refine ⟨u0, (shrink_eq_B_iff hb).mp hu0, fun w hw hKw => ?_⟩
      have e1 : f w = f w0 := (hKf hKw hq).trans hw0.symm
      rw [hf, shrink_eq_iff hb] at e1
      rcases e1 with rfl | ⟨h, -⟩
      exacts [hG, absurd h hw]
    · push Not at h
      exact ⟨b, hb, fun w _ hKw => absurd hKw (h _)⟩
  obtain ⟨Q, hQG, hQf, hQS, hQk⟩ := hfc u huS
  have hfu : f u = B := shrink_of_mem huS
  let L : SimpleGraph V :=
    { Adj := fun v w => K.Adj (f v) (f w) ∧ (v ∉ S ∨ v = u) ∧ (w ∉ S ∨ w = u)
      symm := ⟨fun v w ⟨h, a, c⟩ => ⟨h.symm, c, a⟩⟩
      loopless := ⟨fun v ⟨h, _, _⟩ => h.ne rfl⟩ }
  have hinj : ∀ v w, (v ∉ S ∨ v = u) → (w ∉ S ∨ w = u) → f v = f w → v = w := by
    intro v w hv hw h
    rw [hf, shrink_eq_iff hb] at h
    rcases h with h | ⟨h1, h2⟩
    · exact h
    · rcases hv with hv | rfl
      · exact absurd h1 hv
      · rcases hw with hw | rfl
        · exact absurd h2 hw
        · rfl
  have hLG1 : ∀ v w, L.Adj v w → w ∉ S → G.Adj v w := by
    rintro v w ⟨h, hv, -⟩ hw
    rcases hv with hv | rfl
    · obtain ⟨-, v', w', hG, hv', hw'⟩ := hK h
      have e1 : v' = v := ((shrink_eq_iff hb).mp hv').resolve_right (fun h => hv h.2)
      have e2 : w' = w := ((shrink_eq_iff hb).mp hw').resolve_right (fun h => hw h.2)
      subst e1 e2
      exact hG
    · rw [hfu] at h
      exact hu w hw h
  let H := L ⊔ Q
  have hHG : H ≤ G := by
    apply sup_le
    · intro v w h
      by_cases hw : w ∈ S
      · have hw' : w = u := h.2.2.resolve_left (not_not.mpr hw)
        subst hw'
        have hv : v ∉ S := by
          intro hv
          have hv' : v = w := h.2.1.resolve_left (not_not.mpr hv)
          subst hv'; exact h.1.ne rfl
        exact (hLG1 w v h.symm hv).symm
      · exact hLG1 v w h hw
    · exact hQG
  have hHf : Fn H := by
    intro v w w' h h'
    rcases h with h | h <;> rcases h' with h' | h'
    · exact hinj w w' h.2.2 h'.2.2 (hKf h.1 h'.1)
    · exact absurd h.2.1 (by have := hQS v w' h'; tauto)
    · exact absurd h'.2.1 (by have := hQS v w h; tauto)
    · exact hQf h h'
  refine ⟨H, hHG, hHf, ?_⟩
  have hmap : H.map f = K := by
    ext p q
    rw [map_adj']
    constructor
    · rintro ⟨hne, v, w, h, rfl, rfl⟩
      rcases h with h | h
      · exact h.1
      · have hv := (hQS v w h).1
        have hw := (hQS w v h.symm).1
        exact absurd ((shrink_eq_iff hb).mpr (Or.inr ⟨hv, hw⟩)) hne
    · intro h
      let rep : ShrunkDot S b → V := fun p => if p.val ∈ S then u else p.val
      have hrep : ∀ p, f (rep p) = p ∧ (rep p ∉ S ∨ rep p = u) := by
        intro p
        by_cases hp : p.val ∈ S
        · have hr : rep p = u := ite_eq_left hp
          rw [hr]
          refine ⟨?_, Or.inr rfl⟩
          rw [hfu]
          rcases p with ⟨pv, hpv | hpv⟩
          · exact absurd hp hpv
          · subst hpv; rfl
        · have hr : rep p = p.val := ite_eq_right hp
          rw [hr]
          refine ⟨?_, Or.inl hp⟩
          rw [hf, shrink_of_not_mem hp]
      refine ⟨h.ne, rep p, rep q, Or.inl ⟨?_, (hrep p).2, (hrep q).2⟩, (hrep p).1, (hrep q).1⟩
      rw [(hrep p).1, (hrep q).1]; exact h
  have hQin : Q.edgeSet ⊆ H.edgeSet ∩ inside S := by
    intro e he
    induction e using Sym2.ind with
    | _ v w =>
    rw [mem_edgeSet] at he
    refine ⟨Or.inr he, ?_⟩
    intro x hx
    rw [Sym2.mem_iff] at hx
    rcases hx with rfl | rfl
    exacts [(hQS _ _ he).1, (hQS _ _ he.symm).1]
  have c1 := card_map_add_inside hb hHf
  rw [← hf, hmap] at c1
  have c2 := Set.ncard_le_ncard hQin (Set.toFinite _)
  omega

end shrinkS

theorem stem [Finite V] {G : SimpleGraph V} (n : ℕ) : ∀ {r b : V} (p : G.Walk r b),
    p.length = 2 * n → p.IsPath → ∀ H : SimpleGraph V, H ≤ G → Fn H → (∀ w, ¬ H.Adj r w) →
    (∀ i < p.length, (H.Adj (p.getVert i) (p.getVert (i + 1)) ↔ Odd i)) →
    ∃ H' : SimpleGraph V, H' ≤ G ∧ Fn H' ∧ H'.edgeSet.ncard = H.edgeSet.ncard ∧
      (∀ w, ¬ H'.Adj b w) ∧ (∀ u, u ∉ p.support → ∀ w, (H'.Adj u w ↔ H.Adj u w)) := by
  induction n with
  | zero =>
    intro r b p hlen _ H hHG hHf hr _
    cases p with
    | nil => exact ⟨H, hHG, hHf, rfl, hr, fun _ _ _ => Iff.rfl⟩
    | cons h q => simp at hlen
  | succ n ih =>
    intro r b p hlen hp H hHG hHf hr hpM
    cases p with
    | nil => simp at hlen
    | cons h01 p' =>
      cases p' with
      | nil => simp at hlen; omega
      | cons h12 q =>
        rename_i v1 v2
        simp only [Walk.cons_isPath_iff, Walk.support_cons, List.mem_cons, not_or] at hp
        obtain ⟨⟨hq, hv1q⟩, hrv1, hrq⟩ := hp
        have hlen' : q.length = 2 * n := by simp at hlen; omega
        have hv12 : H.Adj v1 v2 := by
          have := hpM 1 (by simp)
          simpa using this
        have hxy : r ≠ v1 := h01.ne
        have hagree : ∀ u w, u ≠ r → u ≠ v1 → u ≠ v2 →
            ((swap H r v1 v2).Adj u w ↔ H.Adj u w) := fun u w a c d =>
          swap_adj_of (sym2_ne_of a c) (sym2_ne_of c d)
        obtain ⟨H', h1, h2, h3, h4, h5⟩ := ih q hlen' hq (swap H r v1 v2) (swap_le hHG h01)
          (swap_fn hHf hr hv12 hxy) (swap_z_free hHf hr hv12) (by
            intro i hi
            have hqi := q.getVert_mem_support i
            have hqi1 := q.getVert_mem_support (i + 1)
            rw [swap_adj_of]
            · have := hpM (i + 2) (by simp; omega)
              simp only [Walk.getVert_cons_succ] at this
              rw [this]
              simp [Nat.odd_add]
            · exact sym2_ne_of (fun h => hrq (h ▸ hqi)) (fun h => hv1q (h ▸ hqi))
            · rw [Ne, Sym2.eq_iff]
              rintro (⟨h, -⟩ | ⟨-, h⟩)
              · exact hv1q (h ▸ hqi)
              · exact hv1q (h ▸ hqi1))
        refine ⟨H', h1, h2, h3.trans (swap_card hr hv12 hxy), h4, ?_⟩
        intro u hu w
        simp only [Walk.support_cons, List.mem_cons, not_or] at hu
        obtain ⟨hur, huv1, huq⟩ := hu
        rw [h5 u huq w]
        exact hagree u w hur huv1 (fun h => huq (h ▸ q.start_mem_support))

#print axioms free_map
#print axioms main_aug
#print axioms lift
#print axioms stem

end Blossom

namespace Blossom

variable {V : Type*}

theorem ring_inj {G : SimpleGraph V} {b : V} {c : G.Walk b b} (hc : c.IsCycle) {i j : ℕ}
    (hi1 : 1 ≤ i) (hi2 : i ≤ c.length) (hj1 : 1 ≤ j) (hj2 : j ≤ c.length)
    (h : c.getVert i = c.getVert j) : i = j :=
  hc.getVert_injOn (by simp [hi1, hi2]) (by simp [hj1, hj2]) h

theorem ring_ne_b {G : SimpleGraph V} {b : V} {c : G.Walk b b} (hc : c.IsCycle) {i : ℕ}
    (hi1 : 1 ≤ i) (hi2 : i < c.length) : c.getVert i ≠ b := by
  intro h
  have := ring_inj hc hi1 hi2.le (by omega) le_rfl (h.trans (c.getVert_length).symm)
  omega

theorem ring_vert {G : SimpleGraph V} {b v : V} {c : G.Walk b b} (hv : v ∈ c.support)
    (hvb : v ≠ b) : ∃ i, 1 ≤ i ∧ i < c.length ∧ c.getVert i = v := by
  obtain ⟨n, hn, hnl⟩ := Walk.mem_support_iff_exists_getVert.mp hv
  refine ⟨n, ?_, ?_, hn⟩
  · rcases Nat.eq_zero_or_pos n with rfl | h
    · rw [Walk.getVert_zero] at hn; exact absurd hn.symm hvb
    · exact h
  · rcases lt_or_eq_of_le hnl with h | rfl
    · exact h
    · rw [Walk.getVert_length] at hn; exact absurd hn.symm hvb

theorem ring_image_card [Finite V] {G : SimpleGraph V} {b : V} {c : G.Walk b b} (hc : c.IsCycle)
    {k : ℕ} (hlen : c.length = 2 * k + 1) : (c.getVert '' Set.Icc 1 (2 * k)).ncard = 2 * k := by
  rw [Set.InjOn.ncard_image, Set.ncard_Icc_nat]
  · omega
  · intro i hi j hj h
    simp only [Set.mem_Icc] at hi hj
    exact ring_inj hc hi.1 (by omega) hj.1 (by omega) h

theorem ring_fc [Finite V] {G : SimpleGraph V} {u : V} (c : G.Walk u u) (hc : c.IsCycle) (k : ℕ)
    (hlen : c.length = 2 * k + 1) :
    ∃ Q : SimpleGraph V, Q ≤ G ∧ Fn Q ∧ (∀ v w, Q.Adj v w → v ∈ c.support ∧ v ≠ u) ∧
      k ≤ Q.edgeSet.ncard := by
  let Q := SimpleGraph.fromEdgeSet
    {e | ∃ t < k, e = s(c.getVert (2 * t + 1), c.getVert (2 * t + 2))}
  have hQ : ∀ v w, Q.Adj v w ↔
      (∃ t < k, s(v, w) = s(c.getVert (2 * t + 1), c.getVert (2 * t + 2))) ∧ v ≠ w := by
    intro v w; simp [Q, fromEdgeSet_adj]
  have hQ' : ∀ v w, Q.Adj v w → ∃ t < k,
      (v = c.getVert (2 * t + 1) ∧ w = c.getVert (2 * t + 2)) ∨
      (v = c.getVert (2 * t + 2) ∧ w = c.getVert (2 * t + 1)) := by
    intro v w h
    obtain ⟨⟨t, ht, he⟩, -⟩ := (hQ v w).mp h
    exact ⟨t, ht, Sym2.eq_iff.mp he⟩
  have hinj := fun {i j : ℕ} (hi1 : 1 ≤ i) (hi2 : i ≤ 2 * k + 1) (hj1 : 1 ≤ j)
      (hj2 : j ≤ 2 * k + 1) (h : c.getVert i = c.getVert j) =>
    ring_inj hc hi1 (hlen ▸ hi2) hj1 (hlen ▸ hj2) h
  refine ⟨Q, ?_, ?_, ?_, ?_⟩
  · intro v w h
    obtain ⟨t, ht, ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩⟩ := hQ' v w h
    · exact c.adj_getVert_succ (i := 2 * t + 1) (by omega)
    · exact (c.adj_getVert_succ (i := 2 * t + 1) (by omega)).symm
  · intro v w w' h h'
    obtain ⟨t, ht, ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩⟩ := hQ' _ w h <;>
    obtain ⟨t', ht', ⟨h1, rfl⟩ | ⟨h1, rfl⟩⟩ := hQ' _ w' h'
    · have := hinj (by omega) (by omega) (by omega) (by omega) h1
      have : t = t' := by omega
      subst this; rfl
    · have := hinj (by omega) (by omega) (by omega) (by omega) h1
      omega
    · have := hinj (by omega) (by omega) (by omega) (by omega) h1
      omega
    · have := hinj (by omega) (by omega) (by omega) (by omega) h1
      have : t = t' := by omega
      subst this; rfl
  · intro v w h
    obtain ⟨t, ht, ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩⟩ := hQ' v w h
    · exact ⟨c.getVert_mem_support _, ring_ne_b hc (by omega) (by omega)⟩
    · exact ⟨c.getVert_mem_support _, ring_ne_b hc (by omega) (by omega)⟩
  · have hfn : Fn Q := by
      intro v w w' h h'
      obtain ⟨t, ht, ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩⟩ := hQ' _ w h <;>
      obtain ⟨t', ht', ⟨h1, rfl⟩ | ⟨h1, rfl⟩⟩ := hQ' _ w' h'
      · have := hinj (by omega) (by omega) (by omega) (by omega) h1
        have : t = t' := by omega
        subst this; rfl
      · have := hinj (by omega) (by omega) (by omega) (by omega) h1
        omega
      · have := hinj (by omega) (by omega) (by omega) (by omega) h1
        omega
      · have := hinj (by omega) (by omega) (by omega) (by omega) h1
        have : t = t' := by omega
        subst this; rfl
    have hsub : c.getVert '' Set.Icc 1 (2 * k) ⊆ Q.support := by
      rintro v ⟨j, hj, rfl⟩
      simp only [Set.mem_Icc] at hj
      rw [SimpleGraph.mem_support]
      rcases Nat.even_or_odd' j with ⟨m, rfl | rfl⟩
      · refine ⟨c.getVert (2 * m - 1), (hQ _ _).mpr ⟨⟨m - 1, by omega, ?_⟩, ?_⟩⟩
        · rw [show 2 * (m - 1) + 1 = 2 * m - 1 by omega, show 2 * (m - 1) + 2 = 2 * m by omega,
            Sym2.eq_swap]
        · intro h
          have := hinj (by omega) (by omega) (by omega) (by omega) h
          omega
      · refine ⟨c.getVert (2 * m + 2), (hQ _ _).mpr ⟨⟨m, by omega, rfl⟩, ?_⟩⟩
        intro h
        have := hinj (by omega) (by omega) (by omega) (by omega) h
        omega
    have e1 := Set.ncard_le_ncard hsub (Set.toFinite _)
    rw [ring_image_card hc hlen, fn_support_ncard hfn] at e1
    omega

section ringM
variable {G H : SimpleGraph V} {b : V} {c : G.Walk b b} {k : ℕ}

theorem ring_partner (hc : c.IsCycle) (hlen : c.length = 2 * k + 1)
    (hcM : ∀ i < c.length, (H.Adj (c.getVert i) (c.getVert (i + 1)) ↔ Odd i)) :
    ∀ v ∈ c.support, v ≠ b → ∃ w ∈ c.support, w ≠ b ∧ H.Adj v w := by
  intro v hv hvb
  obtain ⟨i, hi1, hi2, rfl⟩ := ring_vert hv hvb
  rcases Nat.even_or_odd' i with ⟨m, rfl | rfl⟩
  · refine ⟨c.getVert (2 * m - 1), c.getVert_mem_support _, ring_ne_b hc (by omega) (by omega), ?_⟩
    have := (hcM (2 * m - 1) (by omega)).mpr ⟨m - 1, by omega⟩
    rw [show 2 * m - 1 + 1 = 2 * m by omega] at this
    exact this.symm
  · refine ⟨c.getVert (2 * m + 1 + 1), c.getVert_mem_support _,
      ring_ne_b hc (by omega) (by omega), ?_⟩
    exact (hcM (2 * m + 1) hi2).mpr ⟨m, rfl⟩

theorem ring_b_free_inside (hc : c.IsCycle) (hlen : c.length = 2 * k + 1) (hHf : Fn H)
    (hcM : ∀ i < c.length, (H.Adj (c.getVert i) (c.getVert (i + 1)) ↔ Odd i)) :
    ∀ w ∈ c.support, ¬ H.Adj b w := by
  intro w hw h
  by_cases hwb : w = b
  · subst hwb; exact h.ne rfl
  · obtain ⟨w', -, hw'b, hww'⟩ := ring_partner hc hlen hcM w hw hwb
    exact hw'b (hHf hww' h.symm)

theorem ring_cross (hc : c.IsCycle) (hlen : c.length = 2 * k + 1) (hHf : Fn H)
    (hcM : ∀ i < c.length, (H.Adj (c.getVert i) (c.getVert (i + 1)) ↔ Odd i)) :
    ∀ u w, H.Adj u w → u ∈ {v | v ∈ c.support} → w ∉ {v | v ∈ c.support} → u = b := by
  intro u w h hu hw
  by_contra hub
  obtain ⟨w', hw', -, huw'⟩ := ring_partner hc hlen hcM u hu hub
  exact hw ((hHf h huw') ▸ hw')

theorem ring_inside_card [Finite V] (hc : c.IsCycle) (hlen : c.length = 2 * k + 1) (hHf : Fn H)
    (hcM : ∀ i < c.length, (H.Adj (c.getVert i) (c.getVert (i + 1)) ↔ Odd i)) :
    (H.edgeSet ∩ inside {v | v ∈ c.support}).ncard = k := by
  let Hin := SimpleGraph.fromEdgeSet (H.edgeSet ∩ inside {v | v ∈ c.support})
  have hadj : ∀ v w, Hin.Adj v w ↔ H.Adj v w ∧ v ∈ c.support ∧ w ∈ c.support := by
    intro v w
    simp only [Hin, fromEdgeSet_adj, Set.mem_inter_iff, mem_edgeSet, inside, Set.mem_ofPred_eq,
      Sym2.mem_iff, forall_eq_or_imp, forall_eq]
    constructor
    · rintro ⟨⟨h, hv, hw⟩, -⟩; exact ⟨h, hv, hw⟩
    · rintro ⟨h, hv, hw⟩; exact ⟨⟨h, hv, hw⟩, h.ne⟩
  have hfn : Fn Hin := fun u v w h h' => hHf ((hadj _ _).mp h).1 ((hadj _ _).mp h').1
  have hedge : Hin.edgeSet = H.edgeSet ∩ inside {v | v ∈ c.support} := by
    ext e
    induction e using Sym2.ind with
    | _ v w =>
    rw [mem_edgeSet, hadj]
    simp only [Set.mem_inter_iff, mem_edgeSet, inside, Set.mem_ofPred_eq, Sym2.mem_iff,
      forall_eq_or_imp, forall_eq]
  have hsupp : Hin.support = c.getVert '' Set.Icc 1 (2 * k) := by
    ext v
    rw [SimpleGraph.mem_support]
    constructor
    · rintro ⟨w, h⟩
      obtain ⟨hH, hv, hw⟩ := (hadj v w).mp h
      have hvb : v ≠ b := by
        rintro rfl; exact ring_b_free_inside hc hlen hHf hcM w hw hH
      obtain ⟨i, hi1, hi2, rfl⟩ := ring_vert hv hvb
      exact ⟨i, ⟨hi1, by omega⟩, rfl⟩
    · rintro ⟨i, hi, rfl⟩
      simp only [Set.mem_Icc] at hi
      obtain ⟨w, hw, -, h⟩ := ring_partner hc hlen hcM _ (c.getVert_mem_support i)
        (ring_ne_b hc hi.1 (by omega))
      exact ⟨w, (hadj _ _).mpr ⟨h, c.getVert_mem_support i, hw⟩⟩
  have e1 := fn_support_ncard hfn
  rw [hsupp, ring_image_card hc hlen, hedge] at e1
  omega

end ringM

#print axioms ring_inj
#print axioms ring_ne_b
#print axioms ring_vert
#print axioms ring_image_card
#print axioms ring_fc
#print axioms ring_partner
#print axioms ring_b_free_inside
#print axioms ring_cross
#print axioms ring_inside_card

end Blossom

/-- **Edmonds' lemma.** Let `M` be a matching of a graph `G` with finitely many dots, and let
`B` be a blossom the search found: an odd ring `c` of `2k + 1` lines through its base `b` whose
lines, going round from `b`, are unpaired, paired, unpaired, …, unpaired (so `k` paired lines
inside), reached from a free root `r` by the stem `p`: a path of even length from `r` to `b`
whose lines go unpaired, paired, …, paired, meeting the ring only at `b`. Then `M` is a largest
matching of `G` exactly when the shrunk matching `M/B` is a largest matching of the shrunk
graph `G/B`. -/
theorem maximum_iff_shrunk_maximum {V : Type*} [Finite V] [DecidableEq V]
    {G : SimpleGraph V} {M : G.Subgraph} (hM : M.IsMatching)
    {b : V} (c : G.Walk b b) (k : ℕ) (hc : c.IsCycle) (hlen : c.length = 2 * k + 1)
    (hcM : ∀ i < c.length, (M.Adj (c.getVert i) (c.getVert (i + 1)) ↔ Odd i))
    {r : V} (p : G.Walk r b) (hp : p.IsPath) (hr : r ∉ M.verts) (hpe : Even p.length)
    (hpM : ∀ i < p.length, (M.Adj (p.getVert i) (p.getVert (i + 1)) ↔ Odd i))
    (hpc : ∀ v ∈ p.support, v ∈ c.support → v = b) :
    IsMaximumMatching M ↔
      IsMaximumMatching (shrunkMatching M (shrink {v | v ∈ c.support} b)) := by
  have hHf := Blossom.fn_of_isMatching hM
  have hbS : b ∈ {v | v ∈ c.support} := c.start_mem_support
  have hcard : (M.spanningCoe.map (shrink {v | v ∈ c.support} b)).edgeSet.ncard + k =
      M.edgeSet.ncard := by
    rw [← Blossom.ring_inside_card (H := M.spanningCoe) hc hlen hHf hcM,
      Blossom.card_map_add_inside hbS hHf, Subgraph.edgeSet_spanningCoe]
  have hsm : (shrunkMatching M (shrink {v | v ∈ c.support} b)).IsMatching :=
    Blossom.shrunk_isMatching M _
      (Blossom.fn_map hbS hHf (Blossom.ring_cross (H := M.spanningCoe) hc hlen hHf hcM))
  constructor
  · rintro ⟨-, hmax⟩
    refine ⟨hsm, fun N' hN' => ?_⟩
    obtain ⟨H, hHG, hHf', hle⟩ := Blossom.lift hbS (k := k) (fun u hu => by
        obtain ⟨Q, h1, h2, h3, h4⟩ := Blossom.ring_fc (c.rotate u hu)
          ((Walk.isCycle_rotate hu).mpr hc) k (by rw [Walk.length_rotate]; exact hlen)
        exact ⟨Q, h1, h2, fun v w h =>
          ⟨(Walk.mem_support_rotate_iff _ _ _).mp (h3 v w h).1, (h3 v w h).2⟩, h4⟩)
      (Subgraph.spanningCoe_le N') (Blossom.fn_of_isMatching hN')
    have := hmax (Blossom.toSub H hHG) (Blossom.toSub_isMatching hHG hHf')
    rw [Blossom.toSub_edgeSet] at this
    rw [Subgraph.edgeSet_spanningCoe] at hle
    rw [Blossom.shrunk_edgeSet]
    omega
  · rintro ⟨-, hmax⟩
    refine ⟨hM, fun N hN => ?_⟩
    by_contra hlt
    push Not at hlt
    obtain ⟨n, hn⟩ := hpe
    obtain ⟨H', h1, h2, h3, h4, h5⟩ := Blossom.stem n p (by omega) hp M.spanningCoe
      M.spanningCoe_le hHf (fun w h => hr (M.edge_vert h)) hpM
    have hagr : ∀ u ∈ c.support, u ≠ b → ∀ w, (H'.Adj u w ↔ M.Adj u w) :=
      fun u hu hub w => h5 u (fun hup => hub (hpc u hup hu)) w
    obtain ⟨K, hK, hKf, hlt'⟩ := Blossom.main_aug hbS (Subgraph.spanningCoe_le N)
      (Blossom.fn_of_isMatching hN) _ H' rfl h1 h2
      (fun u w h hu => by
        by_cases hub : u = b
        · subst hub; exact absurd h (h4 w)
        · obtain ⟨w', hw', -, huw'⟩ :=
            Blossom.ring_partner (H := M.spanningCoe) hc hlen hcM u hu hub
          have := hHf ((hagr u hu hub w).mp h) huw'
          rw [this]; exact hw')
      (fun u hu hub => by
        obtain ⟨w', -, -, huw'⟩ := Blossom.ring_partner (H := M.spanningCoe) hc hlen hcM u hu hub
        exact ⟨w', (hagr u hu hub w').mpr huw'⟩)
      (by rw [h3, Subgraph.edgeSet_spanningCoe, Subgraph.edgeSet_spanningCoe]; exact hlt)
    have hK' := hmax (Blossom.toSub K hK) (Blossom.toSub_isMatching hK hKf)
    rw [Blossom.toSub_edgeSet, Blossom.shrunk_edgeSet] at hK'
    have c1 := Blossom.card_map_add_inside hbS h2
    have c2 := Blossom.card_map_add_inside hbS hHf
    have hin : H'.edgeSet ∩ Blossom.inside {v | v ∈ c.support} =
        M.spanningCoe.edgeSet ∩ Blossom.inside {v | v ∈ c.support} := by
      ext e
      induction e using Sym2.ind with
      | _ u v =>
      simp only [Set.mem_inter_iff, mem_edgeSet]
      constructor
      · rintro ⟨h, hi⟩
        refine ⟨?_, hi⟩
        have hu : u ∈ c.support := hi u (Sym2.mem_mk_left _ _)
        by_cases hub : u = b
        · subst hub; exact absurd h (h4 v)
        · exact (hagr u hu hub v).mp h
      · rintro ⟨h, hi⟩
        refine ⟨?_, hi⟩
        have hu : u ∈ c.support := hi u (Sym2.mem_mk_left _ _)
        have hv : v ∈ c.support := hi v (Sym2.mem_mk_right _ _)
        by_cases hub : u = b
        · subst hub
          exact absurd h (Blossom.ring_b_free_inside (H := M.spanningCoe) hc hlen hHf hcM v hv)
        · exact (hagr u hu hub v).mpr h
    rw [hin, h3] at c1
    omega

/-- **Shrinking drops the `k` paired lines inside the ring.** For a ring of `2k + 1` lines
through the base `b` whose lines alternate unpaired, paired, …, unpaired, the shrunk matching
`M/B` is a matching of `G/B`, and `|M/B| = |M| - k` (written `|M/B| + k = |M|`). -/
theorem shrunk_is_matching_and_card_add {V : Type*} [Finite V] [DecidableEq V]
    {G : SimpleGraph V} {M : G.Subgraph} (hM : M.IsMatching)
    {b : V} (c : G.Walk b b) (k : ℕ) (hc : c.IsCycle) (hlen : c.length = 2 * k + 1)
    (hcM : ∀ i < c.length, (M.Adj (c.getVert i) (c.getVert (i + 1)) ↔ Odd i)) :
    (shrunkMatching M (shrink {v | v ∈ c.support} b)).IsMatching ∧
      (shrunkMatching M (shrink {v | v ∈ c.support} b)).edgeSet.ncard + k = M.edgeSet.ncard := by
  have hHf := Blossom.fn_of_isMatching hM
  have hbS : b ∈ {v | v ∈ c.support} := c.start_mem_support
  refine ⟨Blossom.shrunk_isMatching M _
    (Blossom.fn_map hbS hHf (Blossom.ring_cross (H := M.spanningCoe) hc hlen hHf hcM)), ?_⟩
  rw [Blossom.shrunk_edgeSet, ← Blossom.ring_inside_card (H := M.spanningCoe) hc hlen hHf hcM,
    Blossom.card_map_add_inside hbS hHf, Subgraph.edgeSet_spanningCoe]

/-- **Step 0: in a two-sided graph a dot's label never changes.** If the dots split into two
groups with every line between the groups (`G.Colorable 2`), then any two routes between the
same two dots are both even or both odd. -/
theorem two_sided_routes_same_parity {V : Type*} {G : SimpleGraph V} (hG : G.Colorable 2)
    {u v : V} (p q : G.Walk u v) : Even p.length ↔ Even q.length := by
  obtain ⟨C⟩ := hG
  let C' : G.Coloring Bool := Coloring.mk (fun v => decide (C v = 0)) (fun {a d} h => by
    have := C.valid h
    revert this
    generalize C a = x
    generalize C d = y
    revert x y
    decide)
  rw [C'.even_length_iff_congr p, C'.even_length_iff_congr q]

/-! The club's graph from the card: dots a, b, c, d, e, f are 0, 1, 2, 3, 4, 5. -/

/-- The willing pairs: the ring a–b–c–d–e–a and the tail d–f. -/
def clubPairs : List (Fin 6 × Fin 6) := [(0, 1), (1, 2), (2, 3), (3, 4), (0, 4), (3, 5)]

def club : SimpleGraph (Fin 6) :=
  SimpleGraph.fromRel fun x y => (x, y) ∈ clubPairs

instance : DecidableRel club.Adj := fun x y =>
  inferInstanceAs (Decidable (x ≠ y ∧ ((x, y) ∈ clubPairs ∨ (y, x) ∈ clubPairs)))

/-- The draft matching: b–c and d–e. -/
def draftPairs : List (Fin 6 × Fin 6) := [(1, 2), (3, 4)]

def draft : SimpleGraph (Fin 6) :=
  SimpleGraph.fromRel fun x y => (x, y) ∈ draftPairs

instance : DecidableRel draft.Adj := fun x y =>
  inferInstanceAs (Decidable (x ≠ y ∧ ((x, y) ∈ draftPairs ∨ (y, x) ∈ draftPairs)))

-- The draft's pairs are lines of the graph, and each dot has at most one partner: a matching.
example : (∀ x y, draft.Adj x y → club.Adj x y) ∧
    (∀ x y z, draft.Adj x y → draft.Adj x z → y = z) := by decide

-- The augmenting path a–e–d–f: its lines are in the graph, a and f are free, and its lines go
-- unpaired (a–e), paired (e–d), unpaired (d–f).
example : club.Adj 0 4 ∧ club.Adj 4 3 ∧ club.Adj 3 5 ∧
    (∀ y, ¬ draft.Adj 0 y ∧ ¬ draft.Adj 5 y) ∧
    ¬ draft.Adj 0 4 ∧ draft.Adj 4 3 ∧ ¬ draft.Adj 3 5 := by decide

-- After the flip, a–e, b–c, d–f are lines of the graph and cover all 6 players: 3 lines.
example : club.Adj 0 4 ∧ club.Adj 1 2 ∧ club.Adj 3 5 ∧
    ({0, 4, 1, 2, 3, 5} : Finset (Fin 6)).card = 2 * 3 := by decide

-- Shrinking the ring a–b–c–d–e (every dot but f) to B, named by its base a, leaves exactly
-- one line, B–f, and the shrunk matching M/B has 0 lines: both draft pairs lay inside the ring.
example : (club.map (shrink {v : Fin 6 | v ≠ 5} 0)).edgeFinset.card = 1 ∧
    (club.map (shrink {v : Fin 6 | v ≠ 5} 0)).Adj (shrink {v : Fin 6 | v ≠ 5} 0 3)
      (shrink {v : Fin 6 | v ≠ 5} 0 5) ∧
    (draft.map (shrink {v : Fin 6 | v ≠ 5} 0)).edgeFinset.card = 0 := by decide

-- Worked numbers: k = 2 paired lines inside a 5-dot ring; |M/B| = 2 - 2 = 0; 2 + 1 = 3 lines.
example : 2 * 2 + 1 = 5 ∧ 2 - 2 = 0 ∧ 2 + 1 = 3 := by norm_num

-- 15 possible lines on 6 dots, so 2^15 = 32,768 graphs are checked.
example : Nat.choose 6 2 = 15 ∧ 2 ^ 15 = 32768 := by decide

#print axioms maximum_iff_shrunk_maximum
#print axioms shrunk_is_matching_and_card_add
#print axioms two_sided_routes_same_parity
