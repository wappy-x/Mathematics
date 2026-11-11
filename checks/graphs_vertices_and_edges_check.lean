-- Graphs: a finite simple graph on n vertices has at most C(n, 2) = n(n - 1)/2 edges, the named families K(n), C(n), P(n) and K(m, k) have C(n, 2), n, n - 1 and m × k edges, and a renaming that matches two graphs keeps the vertex count, edge count, every vertex's degree and the triangle count, with the card's metro map, tourist leaflet and decoy checked.
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.Combinatorics.SimpleGraph.Maps
import Mathlib.Combinatorics.SimpleGraph.Clique
import Mathlib.Combinatorics.SimpleGraph.Hasse
import Mathlib.Combinatorics.SimpleGraph.CycleGraph
import Mathlib.Combinatorics.SimpleGraph.Bipartite
import Mathlib.Combinatorics.SimpleGraph.Acyclic
import Mathlib.Combinatorics.SimpleGraph.DegreeSum
import Mathlib.Data.Fintype.Perm
import Mathlib.Data.Fin.VecNotation

open SimpleGraph

/-- Whether two vertices of `K(m, k)` are joined can be decided: they must lie on opposite sides. -/
instance (V W : Type*) : DecidableRel (completeBipartiteGraph V W).Adj :=
  fun v w => inferInstanceAs (Decidable (v.isLeft ∧ w.isRight ∨ v.isRight ∧ w.isLeft))

/-- A renaming that matches two graphs carries each `n`-clique of the first onto an `n`-clique
of the second. -/
theorem isNClique_map_iso {X Y : Type*} {A : SimpleGraph X} {B : SimpleGraph Y}
    (g : A ≃g B) (n : ℕ) (s : Finset X) (hs : A.IsNClique n s) :
    B.IsNClique n (s.map g.toEquiv.toEmbedding) := by
  rw [isNClique_iff] at hs ⊢
  refine ⟨?_, by simp [hs.2]⟩
  intro x hx y hy hxy
  simp only [Finset.coe_map, Set.mem_image, Finset.mem_coe] at hx hy
  obtain ⟨a, ha, rfl⟩ := hx
  obtain ⟨b, hb, rfl⟩ := hy
  have hab : a ≠ b := fun h => hxy (h ▸ rfl)
  simpa using g.map_adj_iff.mpr (hs.1 ha hb hab)

/-- The ceiling on lines. In any graph with finitely many vertices, one line at most per pair,
no line from a vertex to itself and no direction on the lines, the edges can never outnumber
the pairs of vertices: with `n` vertices, `|E| ≤ C(n, 2) = n(n − 1)/2`. -/
theorem card_edges_le_choose_two {V : Type*} [Fintype V] [DecidableEq V]
    (G : SimpleGraph V) [DecidableRel G.Adj] :
    G.edgeFinset.card ≤ (Fintype.card V).choose 2 ∧
      (Fintype.card V).choose 2 = Fintype.card V * (Fintype.card V - 1) / 2 := by
  exact ⟨card_edgeFinset_le_card_choose_two, Nat.choose_two_right _⟩

/-- The named families and their line counts, for every size: the complete graph `K(n)` has
`C(n, 2)` edges, the cycle `C(n)` (a closed ring, so at least 3 vertices) has `n`, the path
`P(n)` has `n − 1`, and the complete bipartite graph `K(m, k)` has `m × k`. -/
theorem named_family_edge_counts (n m k : ℕ) :
    (⊤ : SimpleGraph (Fin n)).edgeFinset.card = n.choose 2 ∧
      (3 ≤ n → (cycleGraph n).edgeFinset.card = n) ∧
      (pathGraph n).edgeFinset.card = n - 1 ∧
      (completeBipartiteGraph (Fin m) (Fin k)).edgeFinset.card = m * k := by
  refine ⟨?_, ?_, ?_, ?_⟩
  · simpa using card_edgeFinset_top_eq_card_choose_two (V := Fin n)
  · intro hn
    obtain ⟨j, rfl⟩ : ∃ j, n = j + 3 := ⟨n - 3, by omega⟩
    have h := sum_degrees_eq_twice_card_edges (cycleGraph (j + 3))
    simp only [cycleGraph_degree_three_le, Finset.sum_const, Finset.card_univ,
      Fintype.card_fin, smul_eq_mul] at h
    omega
  · rcases n with _ | j
    · have h := card_edgeFinset_le_card_choose_two (G := pathGraph 0)
      simp only [Fintype.card_fin, Nat.choose_zero_succ, Nat.le_zero] at h
      simpa using h
    · have h := (isTree_pathGraph_add_one j).card_edgeFinset
      simp only [Fintype.card_fin] at h
      omega
  · have h := encard_edgeSet_completeBipartiteGraph (W₁ := Fin m) (W₂ := Fin k)
    rw [← coe_edgeFinset, Set.encard_coe_eq_coe_finsetCard] at h
    simp only [ENat.card_eq_coe_fintype_card, Fintype.card_fin] at h
    exact_mod_cast h

/-- A fingerprint says no, never yes: if a renaming `f` makes two graphs the same graph
(a line stands in the second exactly where one stood in the first), they have the same number
of vertices, the same number of edges, each vertex meets as many lines as its new name does,
and they hold the same number of triangles. -/
theorem iso_keeps_fingerprint {V W : Type*} [Fintype V] [Fintype W] [DecidableEq V]
    [DecidableEq W] {G : SimpleGraph V} {H : SimpleGraph W} [DecidableRel G.Adj]
    [DecidableRel H.Adj] (f : G ≃g H) :
    Fintype.card V = Fintype.card W ∧ G.edgeFinset.card = H.edgeFinset.card ∧
      (∀ v : V, H.degree (f v) = G.degree v) ∧
      (G.cliqueFinset 3).card = (H.cliqueFinset 3).card := by
  refine ⟨Fintype.card_congr f.toEquiv, f.card_edgeFinset_eq, fun v => f.degree_eq v, ?_⟩
  refine Finset.card_bij' (fun s _ => s.map f.toEquiv.toEmbedding)
    (fun s _ => s.map f.symm.toEquiv.toEmbedding) ?_ ?_ ?_ ?_
  · intro s hs
    simp only [mem_cliqueFinset_iff] at hs ⊢
    exact isNClique_map_iso f 3 s hs
  · intro s hs
    simp only [mem_cliqueFinset_iff] at hs ⊢
    exact isNClique_map_iso f.symm 3 s hs
  · intro s _
    rw [Finset.map_map]; convert Finset.map_refl (s := s); ext x; simp
  · intro s _
    rw [Finset.map_map]; convert Finset.map_refl (s := s); ext x; simp

/-- A graph on six stations, numbered 0 to 5, from a list of joined pairs. -/
def ofPairs (l : List (ℕ × ℕ)) : SimpleGraph (Fin 6) where
  Adj a b := a ≠ b ∧ ((a.val, b.val) ∈ l ∨ (b.val, a.val) ∈ l)
  symm := ⟨fun _ _ h => ⟨h.1.symm, h.2.symm⟩⟩
  loopless := ⟨fun _ h => h.1 rfl⟩

instance (l : List (ℕ × ℕ)) : DecidableRel (ofPairs l).Adj :=
  fun a b => inferInstanceAs (Decidable (a ≠ b ∧ ((a.val, b.val) ∈ l ∨ (b.val, a.val) ∈ l)))

/-- The ring map: A to F are 0 to 5; the ring A-B-C-D-E-F-A and the crossings B-E, C-F. -/
abbrev ring : SimpleGraph (Fin 6) :=
  ofPairs [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (1, 4), (2, 5)]

/-- The tourist leaflet: stations 1 to 6 are 0 to 5; lines 1-3 1-5 1-6 2-5 2-6 3-4 4-5 4-6. -/
abbrev tourist : SimpleGraph (Fin 6) :=
  ofPairs [(0, 2), (0, 4), (0, 5), (1, 4), (1, 5), (2, 3), (3, 4), (3, 5)]

/-- The decoy: A-B A-C B-C B-E C-F D-E D-F E-F. -/
abbrev decoy : SimpleGraph (Fin 6) :=
  ofPairs [(0, 1), (0, 2), (1, 2), (1, 4), (2, 5), (3, 4), (3, 5), (4, 5)]

/-- The 3-cube Q(3): 8 corners, joined when they differ in exactly one of 3 coordinates. -/
def cube3 : SimpleGraph (Fin 8) where
  Adj u v := u.val ^^^ v.val ∈ [1, 2, 4]
  symm := ⟨by decide⟩
  loopless := ⟨by decide⟩

instance : DecidableRel cube3.Adj :=
  fun u v => inferInstanceAs (Decidable (u.val ^^^ v.val ∈ [1, 2, 4]))

/-- The leaflet-to-ring renaming: 1 → B, 2 → D, 3 → A, 4 → F, 5 → C, 6 → E. -/
def rename : Fin 6 → Fin 6 := ![1, 3, 0, 5, 2, 4]

-- Six stations, eight lines; 15 pairs available, 7 of them with no line.
example : Fintype.card (Fin 6) = 6 ∧ ring.edgeFinset.card = 8 := by decide
example : Nat.choose 6 2 = 15 ∧ 6 * 5 / 2 = 15 ∧ 15 - 8 = 7 := by decide
-- K(6) 15, C(6) 6, P(6) 5, K(3, 3) 9 lines.
example : (⊤ : SimpleGraph (Fin 6)).edgeFinset.card = 15 := by decide
example : (cycleGraph 6).edgeFinset.card = 6 ∧ (pathGraph 6).edgeFinset.card = 5 := by decide
example : (completeBipartiteGraph (Fin 3) (Fin 3)).edgeFinset.card = 9 := by decide
-- Q(3): 12 lines, 8 × 3 / 2, and every corner meets 3 (a regular graph).
example : cube3.edgeFinset.card = 12 ∧ 8 * 3 / 2 = 12 := by decide
example : ∀ v : Fin 8, cube3.degree v = 3 := by decide
-- The ring map is K(3, 3) (groups A, C, E and B, D, F) less the one line A-D.
example : ∀ a b : Fin 6, ring.Adj a b ↔ (a.val % 2 ≠ b.val % 2 ∧ s(a, b) ≠ s(0, 3)) := by
  decide
-- Its tally of lines per station: 2, 3, 3, 2, 3, 3 for A to F, so 2, 2, 3, 3, 3, 3 sorted.
example : (List.ofFn fun v : Fin 6 => ring.degree v) = [2, 3, 3, 2, 3, 3] := by decide
-- Drop the crossings B-E and C-F: 6 lines left, the ring C(6).
example : ∀ a b : Fin 6,
    (ring.Adj a b ∧ s(a, b) ≠ s(1, 4) ∧ s(a, b) ≠ s(2, 5)) ↔ (cycleGraph 6).Adj a b := by
  decide
-- Keep B, C, E, F and every line between them: 4 lines, B-C, C-F, F-E, E-B.
example : (ring.induce {v | v ∈ ({1, 2, 4, 5} : Finset (Fin 6))}).edgeFinset.card = 4 := by
  decide
-- The renaming 1 → B, 2 → D, 3 → A, 4 → F, 5 → C, 6 → E is one-to-one and carries the
-- leaflet's lines exactly onto the ring map's.
example : Function.Bijective rename ∧
    ∀ a b : Fin 6, tourist.Adj a b ↔ ring.Adj (rename a) (rename b) := by
  decide
-- 720 renamings; 8 of them carry the leaflet onto the ring map, 0 carry the decoy onto it.
example : Fintype.card (Equiv.Perm (Fin 6)) = 720 ∧ 6 * 5 * 4 * 3 * 2 * 1 = 720 := by
  decide +kernel
example : (Finset.univ.filter fun σ : Equiv.Perm (Fin 6) =>
    ∀ a b : Fin 6, tourist.Adj a b ↔ ring.Adj (σ a) (σ b)).card = 8 := by
  decide +kernel
example : (Finset.univ.filter fun σ : Equiv.Perm (Fin 6) =>
    ∀ a b : Fin 6, decoy.Adj a b ↔ ring.Adj (σ a) (σ b)).card = 0 := by
  decide +kernel
-- The fingerprints: all three maps have 8 lines and tally 2, 2, 3, 3, 3, 3; triangles 0, 0, 2.
example : tourist.edgeFinset.card = 8 ∧ decoy.edgeFinset.card = 8 := by decide
example : (List.ofFn fun v : Fin 6 => tourist.degree v) = [3, 2, 2, 3, 3, 3] ∧
    (List.ofFn fun v : Fin 6 => decoy.degree v) = [2, 3, 3, 2, 3, 3] := by decide
example : (ring.cliqueFinset 3).card = 0 ∧ (tourist.cliqueFinset 3).card = 0 ∧
    (decoy.cliqueFinset 3).card = 2 := by decide

#print axioms isNClique_map_iso
#print axioms card_edges_le_choose_two
#print axioms named_family_edge_counts
#print axioms iso_keeps_fingerprint
