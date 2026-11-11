-- Trees: for a finite simple graph, being connected with no cycle, having exactly one path between each pair of vertices, being connected with one edge fewer than vertices, and having no cycle with one edge fewer than vertices are the same thing; every such tree on two or more vertices has at least two leaves, a forest has as many edges as vertices minus pieces, and the card's village numbers check out.
import Mathlib.Combinatorics.SimpleGraph.Acyclic
import Mathlib.Combinatorics.SimpleGraph.DegreeSum
import Mathlib.Combinatorics.SimpleGraph.Connectivity.Finite

open Finset

variable {V : Type*} [Fintype V] [DecidableEq V]

omit [DecidableEq V] in
lemma trees_ncard_edgeSet_eq (G : SimpleGraph V) [DecidableRel G.Adj] :
    G.edgeSet.ncard = G.edgeFinset.card := by
  rw [← Nat.card_coe_set_eq, Nat.card_eq_fintype_card, SimpleGraph.edgeFinset_card]

omit [DecidableEq V] in
lemma trees_isTree_iff_connected_card [Nonempty V] (G : SimpleGraph V) [DecidableRel G.Adj] :
    G.IsTree ↔ G.Connected ∧ G.edgeFinset.card + 1 = Fintype.card V := by
  rw [SimpleGraph.isTree_iff_connected_and_card, Nat.card_coe_set_eq,
    trees_ncard_edgeSet_eq, Nat.card_eq_fintype_card]

omit [DecidableEq V] in
lemma trees_isTree_iff_acyclic_card [Nonempty V] (G : SimpleGraph V) [DecidableRel G.Adj] :
    G.IsTree ↔ G.IsAcyclic ∧ G.edgeFinset.card + 1 = Fintype.card V := by
  rw [SimpleGraph.isTree_iff_isAcyclic_and_ncard_edgeSet_add_one_eq_card,
    trees_ncard_edgeSet_eq, Nat.card_eq_fintype_card]

/-- Four descriptions, one kind of map. On finitely many houses (at least one), with lanes running
both ways, at most one lane per pair and none from a house to itself, these say the same thing:
(1) connected with no cycle; (2) exactly one route (a path, repeating no house) between every
pair; (3) connected with one lane fewer than houses, `m + 1 = n`; (4) no cycle with one lane
fewer than houses. -/
theorem tree_four_descriptions_equivalent [Nonempty V] (G : SimpleGraph V) [DecidableRel G.Adj] :
    List.TFAE
      [G.Connected ∧ G.IsAcyclic,
       ∀ v w : V, ∃! p : G.Walk v w, p.IsPath,
       G.Connected ∧ G.edgeFinset.card + 1 = Fintype.card V,
       G.IsAcyclic ∧ G.edgeFinset.card + 1 = Fintype.card V] := by
  have h1 : G.IsTree ↔ G.Connected ∧ G.IsAcyclic := SimpleGraph.isTree_iff G
  have h2 : G.IsTree ↔ ∀ v w : V, ∃! p : G.Walk v w, p.IsPath := by
    rw [SimpleGraph.isTree_iff_existsUnique_path]
    exact ⟨fun h => h.2, fun h => ⟨inferInstance, h⟩⟩
  tfae_have 1 ↔ 2 := h1.symm.trans h2
  tfae_have 1 ↔ 3 := h1.symm.trans (trees_isTree_iff_connected_card G)
  tfae_have 1 ↔ 4 := h1.symm.trans (trees_isTree_iff_acyclic_card G)
  tfae_finish

/-- Two leaves at least. A finite tree with two houses or more has at least two houses served by
a single lane. -/
theorem tree_has_two_leaves (G : SimpleGraph V) [DecidableRel G.Adj] (hG : G.IsTree)
    (hn : 2 ≤ Fintype.card V) :
    2 ≤ (univ.filter (fun v => G.degree v = 1)).card := by
  have : Nontrivial V := Fintype.one_lt_card_iff_nontrivial.mp (by omega)
  obtain ⟨u, v, huv, hu, hv⟩ := hG.exists_ne_and_degree_eq_one
  have hsub : ({u, v} : Finset V) ⊆ univ.filter (fun v => G.degree v = 1) := by
    intro x hx
    simp only [Finset.mem_insert, Finset.mem_singleton] at hx
    simp only [Finset.mem_filter, Finset.mem_univ, true_and]
    rcases hx with rfl | rfl
    · convert hu
    · convert hv
  calc 2 = ({u, v} : Finset V).card := (Finset.card_pair huv).symm
    _ ≤ _ := Finset.card_le_card hsub

/-- The forest law. A finite map with no cycle anywhere, joined up or not, has as many lanes as
houses minus pieces: `m + c(G) = n`, that is `m = n - c(G)`. -/
theorem forest_edges_add_components_eq_vertices (G : SimpleGraph V) [DecidableRel G.Adj]
    (hG : G.IsAcyclic) :
    G.edgeFinset.card + Fintype.card G.ConnectedComponent = Fintype.card V := by
  have := hG.ncard_edgeSet_add_card_connectedComponent
  rwa [trees_ncard_edgeSet_eq, Nat.card_eq_fintype_card, Nat.card_eq_fintype_card] at this

/-- A map on seven houses from a list of lanes, each running both ways. Houses A to G are
`0` to `6`. -/
def mapOf (L : List (Fin 7 × Fin 7)) (hL : ∀ p ∈ L, p.1 ≠ p.2) : SimpleGraph (Fin 7) where
  Adj u v := (u, v) ∈ L ∨ (v, u) ∈ L
  symm := ⟨fun _ _ h => h.symm⟩
  loopless := ⟨fun _ h => by rcases h with h | h <;> exact hL _ h rfl⟩

instance (L : List (Fin 7 × Fin 7)) (hL) : DecidableRel (mapOf L hL).Adj :=
  fun u v => inferInstanceAs (Decidable ((u, v) ∈ L ∨ (v, u) ∈ L))

/-- The village lanes A-B, B-C, B-D, D-E, D-F, F-G. -/
def villageLanes : List (Fin 7 × Fin 7) := [(0, 1), (1, 2), (1, 3), (3, 4), (3, 5), (5, 6)]
/-- The trap: triangle A-B-C beside the path D-E-F-G. -/
def trapLanes : List (Fin 7 × Fin 7) := [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 6)]

abbrev village : SimpleGraph (Fin 7) := mapOf villageLanes (by decide)
abbrev trap : SimpleGraph (Fin 7) := mapOf trapLanes (by decide)

-- Seven houses, six lanes: 6 = 7 − 1.
example : village.edgeFinset.card = 6 ∧ village.edgeFinset.card + 1 = Fintype.card (Fin 7) := by
  decide
-- Degrees A to G are 1 3 1 3 1 2 1, adding to 12 = 2 × 6 lanes.
example : (List.finRange 7).map (fun v => village.degree v) = [1, 3, 1, 3, 1, 2, 1] := by decide
example : ∑ v, village.degree v = 12 ∧ 12 = 2 * 6 := by decide
-- The leaves are A, C, E and G: four of them.
example : univ.filter (fun v => village.degree v = 1) = ({0, 2, 4, 6} : Finset (Fin 7)) := by decide
-- 21 pairs of houses, 15 of them with no lane.
example : Nat.choose 7 2 = 21 ∧ 21 - 6 = 15 := by decide
-- The trap also spends six lanes on seven houses.
example : trap.edgeFinset.card = 6 := by decide
-- Cut B-D: 5 = 7 − 2; cut D-F too: 4 = 7 − 3.
example : 5 + 2 = 7 ∧ 4 + 3 = 7 := by decide
-- Five houses: 2^10 = 1024 lane maps, C(10, 4) = 210 use four lanes, 85 of those not trees.
example : 2 ^ Nat.choose 5 2 = 1024 ∧ Nat.choose 10 4 = 210 ∧ 210 - 125 = 85 := by decide

#print axioms trees_ncard_edgeSet_eq
#print axioms trees_isTree_iff_connected_card
#print axioms trees_isTree_iff_acyclic_card
#print axioms tree_four_descriptions_equivalent
#print axioms tree_has_two_leaves
#print axioms forest_edges_add_components_eq_vertices
