-- Graph isomorphism: a renaming keeps the edge count, the degree list and the triangle count, K(3,3) and the prism share degrees but are not isomorphic, and the die's two corner lists are the same graph under the card's secret renaming.
import Mathlib.Combinatorics.SimpleGraph.Maps
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.Combinatorics.SimpleGraph.Clique
import Mathlib.Combinatorics.SimpleGraph.CycleGraph
import Mathlib.Combinatorics.SimpleGraph.Prod
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Data.Fin.VecNotation

open SimpleGraph

namespace GraphIsomorphismCard

/-! ## The die's two corner lists -/

/-- Graph A: the 20-sided die's corners, numbered ring by ring
(0 on top, 1 to 5 the upper ring, 6 to 10 the lower ring, 11 at the bottom). -/
def edgesA : List (Fin 12 × Fin 12) :=
  [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (11, 6), (11, 7), (11, 8), (11, 9), (11, 10),
   (1, 2), (2, 3), (3, 4), (4, 5), (5, 1), (6, 7), (7, 8), (8, 9), (9, 10), (10, 6),
   (1, 6), (2, 7), (3, 8), (4, 9), (5, 10), (1, 7), (2, 8), (3, 9), (4, 10), (5, 6)]

/-- Graph B: the second person's list, with letters a to l written as 0 to 11. -/
def edgesB : List (Fin 12 × Fin 12) :=
  [(0, 2), (0, 3), (0, 7), (0, 9), (0, 11), (1, 4), (1, 5), (1, 6), (1, 8), (1, 10),
   (2, 5), (2, 7), (2, 9), (2, 10), (3, 6), (3, 8), (3, 9), (3, 11), (4, 7), (4, 8),
   (4, 10), (4, 11), (5, 6), (5, 9), (5, 10), (6, 8), (6, 9), (7, 10), (7, 11), (8, 11)]

/-- Graph A as a simple graph on 12 vertices. -/
def A : SimpleGraph (Fin 12) := SimpleGraph.fromRel (fun u v => (u, v) ∈ edgesA)

/-- Graph B as a simple graph on 12 vertices. -/
def B : SimpleGraph (Fin 12) := SimpleGraph.fromRel (fun u v => (u, v) ∈ edgesB)

instance : DecidableRel A.Adj := fun u v =>
  inferInstanceAs (Decidable (u ≠ v ∧ ((u, v) ∈ edgesA ∨ (v, u) ∈ edgesA)))

instance : DecidableRel B.Adj := fun u v =>
  inferInstanceAs (Decidable (u ≠ v ∧ ((u, v) ∈ edgesB ∨ (v, u) ∈ edgesB)))

/-- The secret renaming used to build B: corner i of A is letter `secret i` of B
(0h 1c 2k 3e 4l 5a 6j 7f 8b 9i 10d 11g). -/
def secret : Fin 12 → Fin 12 := ![7, 2, 10, 4, 11, 0, 9, 5, 1, 8, 3, 6]

/-- The first renaming the card's search finds
(0a 1c 2h 3l 4d 5j 6f 7k 8e 9i 10g 11b). -/
def firstFound : Fin 12 → Fin 12 := ![0, 2, 7, 11, 3, 9, 5, 10, 4, 8, 6, 1]

/-! ## K(3,3) and the triangular prism -/

/-- K(3,3), Mathlib's complete bipartite graph on two sides of 3. -/
abbrev K33 : SimpleGraph (Fin 3 ⊕ Fin 3) := completeBipartiteGraph (Fin 3) (Fin 3)

instance : DecidableRel K33.Adj := fun v w =>
  inferInstanceAs (Decidable (v.isLeft ∧ w.isRight ∨ v.isRight ∧ w.isLeft))

/-- The triangular prism: a triangle (the 3-cycle) times an edge (K₂), as a box product. -/
abbrev prism : SimpleGraph (Fin 3 × Fin 2) := cycleGraph 3 □ (⊤ : SimpleGraph (Fin 2))

instance : DecidableRel prism.Adj := fun x y =>
  inferInstanceAs (Decidable ((cycleGraph 3).Adj x.1 y.1 ∧ x.2 = y.2 ∨
    (⊤ : SimpleGraph (Fin 2)).Adj x.2 y.2 ∧ x.1 = y.1))

/-! ## Helper lemmas -/

/-- A graph isomorphism carries n-cliques to n-cliques. -/
theorem iso_isNClique_map_iff {V W : Type*} [DecidableEq V] [DecidableEq W]
    {G : SimpleGraph V} {H : SimpleGraph W} (e : G ≃g H) (n : ℕ) (s : Finset V) :
    H.IsNClique n (s.map e.toEquiv.toEmbedding) ↔ G.IsNClique n s := by
  rw [isNClique_iff, isNClique_iff, Finset.card_map]
  refine and_congr_left' ?_
  simp only [IsClique, Finset.coe_map, Set.Pairwise, Set.mem_image, Finset.mem_coe]
  constructor
  · intro h a ha b hb hab
    have := h ⟨a, ha, rfl⟩ ⟨b, hb, rfl⟩ (by simpa using hab)
    simpa [e.map_adj_iff] using this
  · rintro h _ ⟨a, ha, rfl⟩ _ ⟨b, hb, rfl⟩ hab
    have := h ha hb (fun h' => hab (by rw [h']))
    simpa [e.map_adj_iff] using this

/-- A graph isomorphism keeps the number of n-cliques. -/
theorem iso_cliqueFinset_card_eq {V W : Type*} [Fintype V] [Fintype W]
    [DecidableEq V] [DecidableEq W] {G : SimpleGraph V} {H : SimpleGraph W}
    [DecidableRel G.Adj] [DecidableRel H.Adj] (e : G ≃g H) (n : ℕ) :
    (G.cliqueFinset n).card = (H.cliqueFinset n).card := by
  refine Finset.card_bij' (fun s _ => s.map e.toEquiv.toEmbedding)
    (fun t _ => t.map e.symm.toEquiv.toEmbedding) ?_ ?_ ?_ ?_
  · intro s hs
    rw [mem_cliqueFinset_iff] at hs ⊢
    exact (iso_isNClique_map_iff e n s).2 hs
  · intro t ht
    rw [mem_cliqueFinset_iff] at ht ⊢
    exact (iso_isNClique_map_iff e.symm n t).2 ht
  · intro s _
    rw [Finset.map_map]
    have h : e.toEquiv.toEmbedding.trans e.symm.toEquiv.toEmbedding =
        Function.Embedding.refl _ := Function.Embedding.ext (fun x => e.symm_apply_apply x)
    rw [h, Finset.map_refl]
  · intro t _
    rw [Finset.map_map]
    have h : e.symm.toEquiv.toEmbedding.trans e.toEquiv.toEmbedding =
        Function.Embedding.refl _ := Function.Embedding.ext (fun x => e.apply_symm_apply x)
    rw [h, Finset.map_refl]

#print axioms iso_isNClique_map_iff
#print axioms iso_cliqueFinset_card_eq

/-! ## The theorems -/

/-- Invariants: a renaming that turns one graph into the other cannot change the number of
edges, the list of degrees (edges at each vertex), or the number of triangles. So if any of
these differs, the two graphs are not isomorphic. -/
theorem iso_preserves_edges_degrees_triangles {V W : Type*} [Fintype V] [Fintype W]
    [DecidableEq V] [DecidableEq W] {G : SimpleGraph V} {H : SimpleGraph W}
    [DecidableRel G.Adj] [DecidableRel H.Adj] (e : G ≃g H) :
    G.edgeFinset.card = H.edgeFinset.card ∧
      Multiset.map (fun v => G.degree v) Finset.univ.val =
        Multiset.map (fun w => H.degree w) Finset.univ.val ∧
      (G.cliqueFinset 3).card = (H.cliqueFinset 3).card := by
  refine ⟨e.card_edgeFinset_eq, ?_, iso_cliqueFinset_card_eq e 3⟩
  have h1 : (fun v => G.degree v) = (fun w => H.degree w) ∘ e := by
    funext v; simp
  rw [h1, ← Multiset.map_map]
  congr 1
  have h2 := congrArg Finset.val (Finset.map_univ_equiv e.toEquiv)
  rw [Finset.map_val] at h2
  exact h2

/-- K(3,3) and the triangular prism both have every degree equal to 3,
yet they are not isomorphic: no renaming turns one into the other. -/
theorem k33_prism_same_degrees_not_isomorphic :
    K33.IsRegularOfDegree 3 ∧ prism.IsRegularOfDegree 3 ∧ IsEmpty (K33 ≃g prism) := by
  refine ⟨fun v => by revert v; decide, fun v => by revert v; decide, ⟨fun e => ?_⟩⟩
  have h := (iso_preserves_edges_degrees_triangles e).2.2
  have h0 : (K33.cliqueFinset 3).card = 0 := by decide
  have h2 : (prism.cliqueFinset 3).card = 2 := by decide
  omega

/-- The die's two corner lists are the same graph: the secret renaming is an isomorphism
from graph A to graph B. -/
theorem die_drawings_isomorphic : ∃ e : A ≃g B, ∀ i, e i = secret i := by
  have hb : Function.Bijective secret := by decide
  have hadj : ∀ i j, B.Adj (secret i) (secret j) ↔ A.Adj i j := by decide
  exact ⟨⟨Equiv.ofBijective secret hb, fun {i j} => hadj i j⟩, fun i => rfl⟩

/-! ## The card's worked numbers -/

-- Both drawings: 30 edges, degree 5 at every corner, 20 triangles.
set_option maxRecDepth 20000 in
example : A.edgeFinset.card = 30 := by decide
set_option maxRecDepth 20000 in
example : B.edgeFinset.card = 30 := by decide
set_option maxRecDepth 20000 in
example : ∀ v, A.degree v = 5 := by decide
set_option maxRecDepth 20000 in
example : ∀ v, B.degree v = 5 := by decide
example : (A.cliqueFinset 3).card = 20 := by decide +kernel
example : (B.cliqueFinset 3).card = 20 := by decide +kernel

-- The certificate check: under the secret renaming, all 66 pairs agree.
example : ∀ i j, A.Adj i j ↔ B.Adj (secret i) (secret j) := by decide
example : Function.Bijective secret := by decide

-- The search's first renaming also works.
example : ∀ i j, A.Adj i j ↔ B.Adj (firstFound i) (firstFound j) := by decide
example : Function.Bijective firstFound := by decide

-- Reading the labels as already matched (corner i = letter i): 12 of 30 edges line up.
example : (Finset.univ.filter
    (fun p : Fin 12 × Fin 12 => p.1 < p.2 ∧ A.Adj p.1 p.2 ∧ B.Adj p.1 p.2)).card = 12 := by
  decide

-- Blind search: 12! renamings; by hand, 12 × 5 × 2 = 120 symmetries.
example : Nat.factorial 12 = 479001600 := by decide
example : 12 * 5 * 2 = 120 := by decide

-- K(3,3): 0 triangles; the prism: 2 triangles.
example : (K33.cliqueFinset 3).card = 0 := by decide
example : (prism.cliqueFinset 3).card = 2 := by decide

#print axioms iso_preserves_edges_degrees_triangles
#print axioms k33_prism_same_degrees_not_isomorphic
#print axioms die_drawings_isomorphic

end GraphIsomorphismCard
