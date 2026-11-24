-- Tutte's theorem: a finite graph has a perfect matching exactly when removing any set S of dots leaves at most |S| odd pieces, with Petersen's theorem and the Tutte–Berge formula as consequences.
import Mathlib.Combinatorics.SimpleGraph.Tutte
import Mathlib.Combinatorics.SimpleGraph.Connectivity.Connected
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.Data.Fintype.Lattice

open SimpleGraph

section Helpers

open Finset

lemma card_pairs_eq_sum {V : Type*} [Fintype V] (R : V → V → Prop) [DecidableRel R] :
    #(univ.filter fun p : V × V => R p.1 p.2) = ∑ v, #(univ.filter (R v)) := by
  rw [Finset.card_filter, Fintype.sum_prod_type]
  refine Finset.sum_congr rfl fun v _ => ?_
  rw [Finset.card_filter]

lemma odd_card_out_of_regular {V : Type*} [Fintype V] [DecidableEq V] (G : SimpleGraph V)
    [DecidableRel G.Adj] (hreg : G.IsRegularOfDegree 3) (C : Finset V) (hC : Odd #C) :
    Odd #(univ.filter fun p : V × V => p.1 ∈ C ∧ p.2 ∉ C ∧ G.Adj p.1 p.2) := by
  let K : SimpleGraph V :=
    { Adj := fun v w => G.Adj v w ∧ v ∈ C ∧ w ∈ C
      symm := ⟨fun v w h => ⟨h.1.symm, h.2.2, h.2.1⟩⟩
      loopless := ⟨fun v h => G.loopless.irrefl v h.1⟩ }
  classical
  have hK := K.sum_degrees_eq_twice_card_edges
  have hA : #(univ.filter fun p : V × V => p.1 ∈ C ∧ G.Adj p.1 p.2) = 3 * #C := by
    rw [card_pairs_eq_sum (fun v w => v ∈ C ∧ G.Adj v w)]
    have : ∀ v, #(univ.filter fun w => v ∈ C ∧ G.Adj v w) = if v ∈ C then 3 else 0 := by
      intro v
      split_ifs with hv
      · rw [← hreg v, ← card_neighborFinset_eq_degree, neighborFinset_eq_filter]
        simp [hv]
      · simp [hv]
    simp only [this, Finset.sum_ite_mem, Finset.univ_inter, Finset.sum_const, smul_eq_mul]
    ring
  have hB : #(univ.filter fun p : V × V => p.1 ∈ C ∧ p.2 ∈ C ∧ G.Adj p.1 p.2) =
      ∑ v, K.degree v := by
    rw [card_pairs_eq_sum (fun v w => v ∈ C ∧ w ∈ C ∧ G.Adj v w)]
    refine Finset.sum_congr rfl fun v _ => ?_
    rw [← card_neighborFinset_eq_degree, neighborFinset_eq_filter]
    congr 1
    ext w
    simp [K]
    tauto
  have hsplit := Finset.card_filter_add_card_filter_not
    (s := univ.filter fun p : V × V => p.1 ∈ C ∧ G.Adj p.1 p.2) (fun p => p.2 ∈ C)
  rw [Finset.filter_filter, Finset.filter_filter, hA] at hsplit
  have e1 : (univ.filter fun p : V × V => (p.1 ∈ C ∧ G.Adj p.1 p.2) ∧ p.2 ∈ C) =
      univ.filter fun p : V × V => p.1 ∈ C ∧ p.2 ∈ C ∧ G.Adj p.1 p.2 := by
    ext p; simp; tauto
  have e2 : (univ.filter fun p : V × V => (p.1 ∈ C ∧ G.Adj p.1 p.2) ∧ ¬ p.2 ∈ C) =
      univ.filter fun p : V × V => p.1 ∈ C ∧ p.2 ∉ C ∧ G.Adj p.1 p.2 := by
    ext p; simp; tauto
  rw [e1, e2, hB, hK] at hsplit
  have h3 : Odd (3 * #C) := Nat.odd_mul.mpr ⟨by decide, hC⟩
  rw [← hsplit] at h3
  exact (Nat.odd_add'.mp h3).mpr (even_two_mul _)

lemma odd_pieces_le_of_bridgeless_regular {V : Type*} [Fintype V]
    (G : SimpleGraph V) [DecidableRel G.Adj] (hreg : G.IsRegularOfDegree 3)
    (hbridge : ∀ e ∈ G.edgeSet, ¬ G.IsBridge e) :
    ∀ S : Set V, ((⊤ : G.Subgraph).deleteVerts S).coe.oddComponents.ncard ≤ S.ncard := by
  classical
  intro S
  set H := ((⊤ : G.Subgraph).deleteVerts S).coe with hH
  have : Fintype H.ConnectedComponent := Fintype.ofFinite _
  let Cs : H.ConnectedComponent → Finset V := fun c => (Subtype.val '' c.supp).toFinset
  let P : H.ConnectedComponent → Finset (V × V) := fun c =>
    univ.filter fun p => p.1 ∈ Cs c ∧ p.2 ∉ Cs c ∧ G.Adj p.1 p.2
  have hCs : ∀ c, #(Cs c) = c.supp.ncard := by
    intro c
    rw [← Set.ncard_eq_toFinset_card', Set.ncard_image_of_injective _ Subtype.val_injective]
  -- (a) edges leaving a piece go into `S`
  have hout : ∀ c v w, v ∈ Cs c → G.Adj v w → w ∉ Cs c → w ∈ S := by
    intro c v w hv hadj hw
    by_contra hwS
    simp only [Cs, Set.mem_toFinset, Set.mem_image] at hv hw
    obtain ⟨x, hx, rfl⟩ := hv
    have hwv : w ∈ ((⊤ : G.Subgraph).deleteVerts S).verts := by simp [hwS]
    have hxw : H.Adj x ⟨w, hwv⟩ := by
      rw [hH, Subgraph.coe_adj, Subgraph.deleteVerts_adj]
      have := x.2
      simp only [Subgraph.deleteVerts_verts, Subgraph.verts_top, Set.mem_sdiff,
        Set.mem_univ, true_and] at this
      exact ⟨trivial, this, trivial, hwS, hadj⟩
    exact hw ⟨⟨w, hwv⟩, c.mem_supp_of_adj_mem_supp hx hxw, rfl⟩
  -- (b) each odd piece sends at least three edges out
  have h3 : ∀ c : H.ConnectedComponent, Odd c.supp.ncard → 3 ≤ #(P c) := by
    intro c hc
    have hodd := odd_card_out_of_regular G hreg (Cs c) (by rwa [hCs])
    have hne : #(P c) ≠ 1 := by
      intro h1
      obtain ⟨⟨v, w⟩, hp⟩ := Finset.card_eq_one.mp h1
      have hvw : (v, w) ∈ P c := by rw [hp]; simp
      simp only [P, Finset.mem_filter, Finset.mem_univ, true_and] at hvw
      obtain ⟨hv, hw, hadj⟩ := hvw
      apply hbridge s(v, w) (by simpa using hadj)
      rw [isBridge_iff]
      rintro ⟨p⟩
      obtain ⟨d, -, hd1, hd2⟩ := p.exists_boundary_dart (↑(Cs c) : Set V) hv hw
      have hdadj := d.adj
      rw [deleteEdges_adj] at hdadj
      have hd : (d.fst, d.snd) ∈ P c := by
        simp only [P, Finset.mem_filter, Finset.mem_univ, true_and]
        exact ⟨hd1, hd2, hdadj.1⟩
      rw [hp, Finset.mem_singleton, Prod.mk.injEq] at hd
      exact hdadj.2 (by simp [hd.1, hd.2])
    obtain ⟨k, hk⟩ := hodd
    change #(P c) = 2 * k + 1 at hk
    omega
  -- (c) different pieces give different edges
  have hdisj : ∀ c c', c ≠ c' → Disjoint (P c) (P c') := by
    intro c c' hcc'
    rw [Finset.disjoint_left]
    intro p hp hp'
    simp only [P, Cs, Finset.mem_filter, Finset.mem_univ, true_and, Set.mem_toFinset,
      Set.mem_image] at hp hp'
    obtain ⟨⟨x, hx, hxp⟩, -, -⟩ := hp
    obtain ⟨⟨x', hx', hxp'⟩, -, -⟩ := hp'
    have : x = x' := Subtype.val_injective (hxp.trans hxp'.symm)
    subst this
    exact hcc' (ConnectedComponent.eq_of_common_vertex hx hx')
  -- (d) at most `3 |S|` edges end in `S`
  let Q : Finset (V × V) := univ.filter fun p => p.2 ∈ S.toFinset ∧ G.Adj p.1 p.2
  have hQ : #Q = 3 * #S.toFinset := by
    have hQ' : #(univ.filter fun p : V × V => p.1 ∈ S.toFinset ∧ G.Adj p.1 p.2) =
        3 * #S.toFinset := by
      rw [card_pairs_eq_sum (fun v w => v ∈ S.toFinset ∧ G.Adj v w)]
      have : ∀ v, #(univ.filter fun w => v ∈ S.toFinset ∧ G.Adj v w) =
          if v ∈ S.toFinset then 3 else 0 := by
        intro v
        split_ifs with hv
        · rw [← hreg v, ← card_neighborFinset_eq_degree, neighborFinset_eq_filter]
          simp only [hv, true_and]
        · simp [hv]
      simp only [this, Finset.sum_ite_mem, Finset.univ_inter, Finset.sum_const, smul_eq_mul]
      ring
    rw [← hQ']
    refine Finset.card_bij (fun p _ => p.swap) ?_ ?_ ?_
    · intro p hp
      simp only [Q, Finset.mem_filter, Finset.mem_univ, true_and] at hp ⊢
      exact ⟨hp.1, hp.2.symm⟩
    · intro p _ q _ h
      exact Prod.swap_injective h
    · intro q hq
      refine ⟨q.swap, ?_, q.swap_swap⟩
      simp only [Q, Finset.mem_filter, Finset.mem_univ, true_and] at hq ⊢
      exact ⟨hq.1, hq.2.symm⟩
  let O := univ.filter fun c : H.ConnectedComponent => Odd c.supp.ncard
  have hO : H.oddComponents.ncard = #O := by
    rw [Set.ncard_eq_toFinset_card']
    congr 1
    ext c
    simp [O]
  have hsub : O.biUnion P ⊆ Q := by
    intro p hp
    simp only [Finset.mem_biUnion] at hp
    obtain ⟨c, -, hp⟩ := hp
    simp only [P, Q, Finset.mem_filter, Finset.mem_univ, true_and, Set.mem_toFinset] at hp ⊢
    exact ⟨hout c p.1 p.2 hp.1 hp.2.2 hp.2.1, hp.2.2⟩
  have hsum : 3 * #O ≤ #(O.biUnion P) := by
    rw [Finset.card_biUnion (fun c _ c' _ h => hdisj c c' h), mul_comm, ← smul_eq_mul,
      ← Finset.sum_const]
    exact Finset.sum_le_sum fun c hc => h3 c (by simpa [O] using hc)
  have := Finset.card_le_card hsub
  rw [hO, Set.ncard_eq_toFinset_card']
  omega

lemma ncard_oddComponents_of_iso {α β : Type*} {G : SimpleGraph α} {G' : SimpleGraph β}
    (φ : G ≃g G') : G.oddComponents.ncard = G'.oddComponents.ncard := by
  have hsupp : ∀ C : G.ConnectedComponent, (φ.connectedComponentEquiv C).supp = φ '' C.supp := by
    intro C
    ext v'
    rw [Iso.connectedComponentEquiv_apply, ConnectedComponent.mem_supp_iff,
      ← ConnectedComponent.iso_inv_image_comp_eq_iff_eq_map]
    constructor
    · intro h
      exact ⟨φ.symm v', h, φ.apply_symm_apply v'⟩
    · rintro ⟨v, hv, rfl⟩
      simpa using hv
  have hcard : ∀ C : G.ConnectedComponent,
      (φ.connectedComponentEquiv C).supp.ncard = C.supp.ncard := by
    intro C
    rw [hsupp, Set.ncard_image_of_injective _ φ.injective]
  have : G'.oddComponents = φ.connectedComponentEquiv '' G.oddComponents := by
    ext C'
    constructor
    · intro h
      refine ⟨φ.connectedComponentEquiv.symm C', ?_, by simp⟩
      change Odd _
      rw [← hcard]
      simpa using h
    · rintro ⟨C, hC, rfl⟩
      change Odd _
      rw [hcard]
      exact hC
  rw [this, Set.ncard_image_of_injective _ φ.connectedComponentEquiv.injective]

lemma exists_join {V : Type*} (G : SimpleGraph V) (d : ℕ) :
    ∃ J : SimpleGraph (V ⊕ Fin d), (∀ a b, J.Adj (.inl a) (.inl b) ↔ G.Adj a b) ∧
      (∀ a i, J.Adj (.inl a) (.inr i)) ∧ (∀ i j, i ≠ j → J.Adj (.inr i) (.inr j)) := by
  refine ⟨{ Adj := fun x y => x ≠ y ∧ ∀ a b, x = .inl a → y = .inl b → G.Adj a b
            symm := ⟨fun x y h => ⟨h.1.symm, fun a b hx hy => (h.2 b a hy hx).symm⟩⟩
            loopless := ⟨fun x h => h.1 rfl⟩ }, ?_, ?_, ?_⟩
  · intro a b
    simp only [ne_eq, Sum.inl.injEq]
    constructor
    · intro h; exact h.2 a b rfl rfl
    · intro h
      refine ⟨G.ne_of_adj h, ?_⟩
      rintro a' b' rfl rfl
      exact h
  · intro a i
    simp
  · intro i j hij
    simp [hij]

lemma matching_ncard_verts_eq {V : Type*} [Finite V] {G : SimpleGraph V} {M : G.Subgraph}
    (hM : M.IsMatching) : M.verts.ncard = 2 * M.edgeSet.ncard := by
  classical
  cases nonempty_fintype V
  have h := M.spanningCoe.sum_degrees_eq_twice_card_edges
  rw [← Set.ncard_coe_finset, coe_edgeFinset, Subgraph.edgeSet_spanningCoe] at h
  rw [← h, Set.ncard_eq_toFinset_card']
  rw [← Finset.sum_filter_add_sum_filter_not Finset.univ (· ∈ M.verts)]
  have h1 : ∀ v ∈ Finset.univ.filter (· ∈ M.verts), M.spanningCoe.degree v = 1 := by
    intro v hv
    simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hv
    obtain ⟨w, hw, hu⟩ := hM hv
    rw [← card_neighborFinset_eq_degree, Finset.card_eq_one]
    refine ⟨w, ?_⟩
    ext u
    simp only [mem_neighborFinset, Subgraph.spanningCoe_adj, Finset.mem_singleton]
    exact ⟨hu u, fun h => h ▸ hw⟩
  have h0 : ∀ v ∈ Finset.univ.filter (· ∉ M.verts), M.spanningCoe.degree v = 0 := by
    intro v hv
    simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hv
    rw [← card_neighborFinset_eq_degree, Finset.card_eq_zero]
    ext u
    simp only [mem_neighborFinset, Subgraph.spanningCoe_adj, Finset.notMem_empty, iff_false]
    exact fun h => hv (M.edge_vert h)
  rw [Finset.sum_congr rfl h1, Finset.sum_congr rfl h0, Finset.sum_const_zero, add_zero,
    Finset.sum_const, smul_eq_mul, mul_one]
  congr 1
  ext v
  simp

lemma join_transfer {V : Type*} [Finite V] (G : SimpleGraph V) (d : ℕ)
    (J : SimpleGraph (V ⊕ Fin d)) (hJ1 : ∀ a b, J.Adj (.inl a) (.inl b) ↔ G.Adj a b)
    (S : Set V) :
    ((⊤ : J.Subgraph).deleteVerts (Sum.inl '' S ∪ Set.range Sum.inr)).coe.oddComponents.ncard =
        ((⊤ : G.Subgraph).deleteVerts S).coe.oddComponents.ncard ∧
      (Sum.inl '' S ∪ Set.range Sum.inr : Set (V ⊕ Fin d)).ncard = S.ncard + d := by
  constructor
  · let f : ((⊤ : G.Subgraph).deleteVerts S).verts →
        ((⊤ : J.Subgraph).deleteVerts (Sum.inl '' S ∪ Set.range Sum.inr)).verts :=
      fun x => ⟨.inl x.1, by
        have := x.2
        simp only [Subgraph.deleteVerts_verts, Subgraph.verts_top, Set.mem_sdiff,
          Set.mem_univ, true_and] at this ⊢
        simpa using this⟩
    have hf : Function.Bijective f := by
      constructor
      · intro x y h
        apply Subtype.val_injective
        simpa [f] using h
      · rintro ⟨x, hx⟩
        simp only [Subgraph.deleteVerts_verts, Subgraph.verts_top, Set.mem_sdiff,
          Set.mem_univ, true_and, Set.mem_union, Set.mem_image, Set.mem_range, not_or,
          not_exists, not_and] at hx
        rcases x with a | i
        · refine ⟨⟨a, ?_⟩, rfl⟩
          simp only [Subgraph.deleteVerts_verts, Subgraph.verts_top, Set.mem_sdiff,
            Set.mem_univ, true_and]
          exact fun ha => hx.1 a ha rfl
        · exact absurd rfl (hx.2 i)
    let φ : ((⊤ : G.Subgraph).deleteVerts S).coe ≃g
        ((⊤ : J.Subgraph).deleteVerts (Sum.inl '' S ∪ Set.range Sum.inr)).coe :=
      { toEquiv := Equiv.ofBijective f hf
        map_rel_iff' := by
          intro x y
          simp only [Equiv.ofBijective_apply, Subgraph.coe_adj, Subgraph.deleteVerts_adj,
            Subgraph.top_adj, f]
          have hx := x.2
          have hy := y.2
          simp only [Subgraph.deleteVerts_verts, Subgraph.verts_top, Set.mem_sdiff,
            Set.mem_univ, true_and] at hx hy
          simp [hJ1, hx, hy] }
    exact (ncard_oddComponents_of_iso φ).symm
  · rw [Set.ncard_union_eq, Set.ncard_image_of_injective _ Sum.inl_injective,
      ← Set.image_univ, Set.ncard_image_of_injective _ Sum.inr_injective, Set.ncard_univ,
      Nat.card_eq_fintype_card, Fintype.card_fin]
    rw [Set.disjoint_left]
    rintro x ⟨a, -, rfl⟩ ⟨i, hi⟩
    exact Sum.inr_ne_inl hi

lemma tutte_berge_le {V : Type*} [Finite V] (G : SimpleGraph V) (M : G.Subgraph)
    (hM : M.IsMatching) (S : Set V) :
    2 * M.edgeSet.ncard + ((⊤ : G.Subgraph).deleteVerts S).coe.oddComponents.ncard
      ≤ Nat.card V + S.ncard := by
  classical
  set U := M.vertsᶜ with hU
  set d := Nat.card U with hd
  obtain ⟨J, hJ1, hJ2, -⟩ := exists_join G d
  let e : U ≃ Fin d := Finite.equivFin U
  let ι : G →g J := ⟨Sum.inl, fun h => (hJ1 _ _).2 h⟩
  let M1 : J.Subgraph := M.map ι
  let M2 : J.Subgraph := ⨆ i : Fin d, J.subgraphOfAdj (hJ2 (e.symm i).1 i)
  have hM1 : M1.IsMatching := hM.map ι Sum.inl_injective
  have hM2 : M2.IsMatching := by
    refine Subgraph.IsMatching.iSup (fun i => Subgraph.IsMatching.subgraphOfAdj _) ?_
    intro i j hij
    rw [(Subgraph.IsMatching.subgraphOfAdj _).support_eq_verts,
      (Subgraph.IsMatching.subgraphOfAdj _).support_eq_verts, subgraphOfAdj_verts,
      subgraphOfAdj_verts, Set.disjoint_left]
    intro x hx hx'
    simp only [Set.mem_insert_iff, Set.mem_singleton_iff] at hx hx'
    rcases hx with rfl | rfl <;> rcases hx' with h | h
    · simp only [Sum.inl.injEq] at h
      exact hij (e.symm.injective (Subtype.val_injective h))
    · exact Sum.inl_ne_inr h
    · exact Sum.inr_ne_inl h
    · exact hij (Sum.inr_injective h)
  have hd12 : Disjoint M1.support M2.support := by
    rw [hM1.support_eq_verts, hM2.support_eq_verts, Set.disjoint_left]
    intro x hx hx'
    simp only [M1, M2, Subgraph.map_verts, Subgraph.verts_iSup, subgraphOfAdj_verts,
      Set.mem_image, Set.mem_iUnion, Set.mem_insert_iff, Set.mem_singleton_iff] at hx hx'
    obtain ⟨a, ha, rfl⟩ := hx
    obtain ⟨i, h | h⟩ := hx'
    · simp only [ι, RelHom.coeFn_mk, Sum.inl.injEq] at h
      exact (e.symm i).2 (h ▸ ha)
    · exact Sum.inl_ne_inr h
  have hM' : (M1 ⊔ M2).IsPerfectMatching := by
    refine ⟨hM1.sup hM2 hd12, fun x => ?_⟩
    simp only [M1, M2, Subgraph.verts_sup, Subgraph.map_verts, Subgraph.verts_iSup,
      subgraphOfAdj_verts, Set.mem_union, Set.mem_image, Set.mem_iUnion, Set.mem_insert_iff,
      Set.mem_singleton_iff]
    rcases x with a | i
    · by_cases ha : a ∈ M.verts
      · exact Or.inl ⟨a, ha, rfl⟩
      · exact Or.inr ⟨e ⟨a, ha⟩, Or.inl (by simp)⟩
    · exact Or.inr ⟨i, Or.inr rfl⟩
  have : Finite (V ⊕ Fin d) := by cases nonempty_fintype V; infer_instance
  have ht := not_isTutteViolator_of_isPerfectMatching hM' (Sum.inl '' S ∪ Set.range Sum.inr)
  rw [IsTutteViolator, not_lt] at ht
  obtain ⟨h1, h2⟩ := join_transfer G d J hJ1 S
  rw [h1, h2] at ht
  have hv := matching_ncard_verts_eq hM
  have hc : U.ncard + M.verts.ncard = Nat.card V := Set.ncard_compl_add_ncard _
  have hdU : d = U.ncard := Nat.card_coe_set_eq U
  omega

end Helpers

#print axioms card_pairs_eq_sum
#print axioms odd_card_out_of_regular
#print axioms odd_pieces_le_of_bridgeless_regular
#print axioms ncard_oddComponents_of_iso
#print axioms exists_join
#print axioms matching_ncard_verts_eq
#print axioms join_transfer
#print axioms tutte_berge_le

/-- **Tutte's theorem.** A graph with finitely many dots has a perfect matching exactly when,
for every set `S` of dots, deleting `S` leaves at most `|S|` pieces with an odd number of dots:
`o(G - S) ≤ |S|`. -/
theorem perfect_matching_iff_odd_pieces_le {V : Type*} [Finite V] (G : SimpleGraph V) :
    (∃ M : G.Subgraph, M.IsPerfectMatching) ↔
      ∀ S : Set V, ((⊤ : G.Subgraph).deleteVerts S).coe.oddComponents.ncard ≤ S.ncard := by
  rw [tutte]
  simp only [IsTutteViolator, not_lt]

/-- **Petersen's theorem.** A finite graph with exactly 3 lines at every dot and no bridge
(no line whose removal disconnects its two ends) has a perfect matching. -/
theorem bridgeless_three_regular_has_perfect_matching {V : Type*} [Fintype V]
    (G : SimpleGraph V) [DecidableRel G.Adj] (hreg : G.IsRegularOfDegree 3)
    (hbridge : ∀ e ∈ G.edgeSet, ¬ G.IsBridge e) :
    ∃ M : G.Subgraph, M.IsPerfectMatching := by
  rw [perfect_matching_iff_odd_pieces_le]
  exact odd_pieces_le_of_bridgeless_regular G hreg hbridge

/-- **The Tutte–Berge formula.** In a finite graph, the largest matching has
`min over S of (|V| + |S| - o(G - S)) / 2` lines: every matching `M` and every set `S` satisfy
`2 |M| + o(G - S) ≤ |V| + |S|`, and some matching and some set make this an equality. -/
theorem largest_matching_eq_tutte_berge {V : Type*} [Finite V] (G : SimpleGraph V) :
    (∀ M : G.Subgraph, M.IsMatching → ∀ S : Set V,
        2 * M.edgeSet.ncard + ((⊤ : G.Subgraph).deleteVerts S).coe.oddComponents.ncard
          ≤ Nat.card V + S.ncard) ∧
    ∃ (M : G.Subgraph) (S : Set V), M.IsMatching ∧
        2 * M.edgeSet.ncard + ((⊤ : G.Subgraph).deleteVerts S).coe.oddComponents.ncard
          = Nat.card V + S.ncard := by
  classical
  refine ⟨fun M hM S => tutte_berge_le G M hM S, ?_⟩
  let f : Set V → ℤ := fun S =>
    (((⊤ : G.Subgraph).deleteVerts S).coe.oddComponents.ncard : ℤ) - S.ncard
  obtain ⟨S₀, hS₀⟩ := Finite.exists_max f
  have hf0 : 0 ≤ f S₀ := le_trans (by simp [f]) (hS₀ ∅)
  set d := (f S₀).toNat with hd
  have hdS₀ : ((⊤ : G.Subgraph).deleteVerts S₀).coe.oddComponents.ncard = S₀.ncard + d := by
    have := Int.toNat_of_nonneg hf0
    simp only [f] at this hd
    omega
  have hle : ∀ S : Set V,
      ((⊤ : G.Subgraph).deleteVerts S).coe.oddComponents.ncard ≤ S.ncard + d := by
    intro S
    have := hS₀ S
    have h2 := Int.toNat_of_nonneg hf0
    simp only [f] at this h2 hd
    omega
  obtain ⟨J, hJ1, hJ2, hJ3⟩ := exists_join G d
  have : Finite (V ⊕ Fin d) := by cases nonempty_fintype V; infer_instance
  -- the number of dots of `J` is even
  have hpar : Even (Nat.card V + d) := by
    have h := odd_ncard_oddComponents ((⊤ : G.Subgraph).deleteVerts S₀).coe
    rw [hdS₀, Nat.card_coe_set_eq, Subgraph.deleteVerts_verts, Subgraph.verts_top,
      ← Set.compl_eq_univ_sdiff] at h
    have hc := Set.ncard_compl_add_ncard S₀
    rw [Nat.odd_iff, Nat.odd_iff] at h
    rw [Nat.even_iff]
    rcases Nat.mod_two_eq_zero_or_one (S₀ᶜ.ncard) with h0 | h0
    · have : (S₀.ncard + d) % 2 ≠ 1 := fun h' => by have := h.mp h'; omega
      omega
    · have := h.mpr h0
      omega
  obtain ⟨M', hM'⟩ : ∃ M' : J.Subgraph, M'.IsPerfectMatching := by
    rw [perfect_matching_iff_odd_pieces_le]
    intro S'
    by_cases hS' : ∀ i, Sum.inr i ∈ S'
    · have hS'eq : S' = Sum.inl '' (Sum.inl ⁻¹' S') ∪ Set.range Sum.inr := by
        ext x
        rcases x with a | i <;> simp [hS']
      rw [hS'eq]
      obtain ⟨h1, h2⟩ := join_transfer G d J hJ1 (Sum.inl ⁻¹' S')
      rw [h1, h2]
      exact hle _
    · push Not at hS'
      obtain ⟨i, hi⟩ := hS'
      set H := ((⊤ : J.Subgraph).deleteVerts S').coe with hH
      have hi' : Sum.inr i ∈ ((⊤ : J.Subgraph).deleteVerts S').verts := by simp [hi]
      have hreach : ∀ x, H.Reachable x ⟨_, hi'⟩ := by
        intro x
        by_cases hx : x = ⟨_, hi'⟩
        · rw [hx]
        · apply Adj.reachable
          rw [hH, Subgraph.coe_adj, Subgraph.deleteVerts_adj]
          have hx2 := x.2
          simp only [Subgraph.deleteVerts_verts, Subgraph.verts_top, Set.mem_sdiff,
            Set.mem_univ, true_and] at hx2
          refine ⟨trivial, hx2, trivial, hi, ?_⟩
          obtain ⟨x, hxm⟩ := x
          rcases x with a | j
          · exact hJ2 a i
          · refine hJ3 j i fun hji => hx ?_
            subst hji
            rfl
      have hsub : Subsingleton H.ConnectedComponent := by
        constructor
        intro c c'
        induction c using ConnectedComponent.ind with | h x => ?_
        induction c' using ConnectedComponent.ind with | h y => ?_
        exact ConnectedComponent.sound ((hreach x).trans (hreach y).symm)
      have hle1 := Set.ncard_le_one_of_subsingleton H.oddComponents
      by_cases hS'e : S' = ∅
      · have h := odd_ncard_oddComponents H
        have hcard : ((⊤ : J.Subgraph).deleteVerts S').verts.ncard = Nat.card V + d := by
          rw [hS'e, Subgraph.deleteVerts_verts, Subgraph.verts_top, Set.sdiff_empty,
            Set.ncard_univ, Nat.card_sum, Nat.card_eq_fintype_card (α := Fin d),
            Fintype.card_fin]
        rw [Nat.card_coe_set_eq, hcard] at h
        have : ¬ Odd H.oddComponents.ncard := fun h' =>
          (Nat.not_odd_iff_even.mpr hpar) (h.mp h')
        rw [Nat.odd_iff] at this
        omega
      · have := (Set.ncard_pos (s := S')).mpr (Set.nonempty_iff_ne_empty.mpr hS'e)
        omega
  -- restrict the perfect matching of `J` to `G`
  let M : G.Subgraph :=
    { verts := {a | ∃ b, M'.Adj (.inl a) (.inl b)}
      Adj := fun a b => M'.Adj (.inl a) (.inl b)
      adj_sub := fun h => (hJ1 _ _).1 (M'.adj_sub h)
      edge_vert := fun h => ⟨_, h⟩
      symm := ⟨fun _ _ h => h.symm⟩ }
  have hM : M.IsMatching := by
    rintro a ⟨b, hb⟩
    refine ⟨b, hb, fun c hc => ?_⟩
    exact Sum.inl_injective (hM'.1.eq_of_adj_left hc hb)
  have hcov : M.vertsᶜ.ncard ≤ d := by
    have hex : ∀ a : ↥M.vertsᶜ, ∃ i : Fin d, M'.Adj (.inl a.1) (.inr i) := by
      intro a
      obtain ⟨w, hw, -⟩ := hM'.1 (hM'.2 (.inl a.1))
      rcases w with b | i
      · exact absurd ⟨b, hw⟩ a.2
      · exact ⟨i, hw⟩
    choose g hg using hex
    have hinj : Function.Injective g := by
      intro a a' h
      have := hM'.1.eq_of_adj_right (hg a) (h ▸ hg a')
      exact Subtype.val_injective (Sum.inl_injective this)
    have := Nat.card_le_card_of_injective g hinj
    rwa [Nat.card_coe_set_eq, Nat.card_eq_fintype_card, Fintype.card_fin] at this
  refine ⟨M, S₀, hM, ?_⟩
  have h1 := tutte_berge_le G M hM S₀
  have hv := matching_ncard_verts_eq hM
  have hc := Set.ncard_compl_add_ncard M.verts
  omega

-- The star K(1,3): one centre joined to three outer dots has no perfect matching.
example : ¬ ∃ M : (completeBipartiteGraph (Fin 1) (Fin 3)).Subgraph, M.IsPerfectMatching := by
  rintro ⟨M, hM⟩
  have key : ∀ j : Fin 3, M.Adj (Sum.inr j) (Sum.inl 0) := by
    intro j
    obtain ⟨w, hw, -⟩ := hM.1 (hM.2 (Sum.inr j))
    have := M.adj_sub hw
    rcases w with i | i
    · rwa [Subsingleton.elim i 0] at hw
    · simp at this
  have := hM.1.eq_of_adj_right (key 0) (key 1)
  simp at this

-- Worked numbers from the card's table (Tutte–Berge at the worst set S).
example : (4 + 1 - 3) / 2 = 1 := by norm_num      -- star K(1,3), S = centre
example : (10 + 0 - 0) / 2 = 5 := by norm_num     -- Petersen graph, S empty
example : (16 + 1 - 3) / 2 = 7 := by norm_num     -- 16-dot 3-regular graph with bridges, S = centre
example : (12 + 2 - 4) / 2 = 5 := by norm_num     -- Hall's hotel, S = front desk and accounts

#print axioms perfect_matching_iff_odd_pieces_le
#print axioms bridgeless_three_regular_has_perfect_matching
#print axioms largest_matching_eq_tutte_berge
