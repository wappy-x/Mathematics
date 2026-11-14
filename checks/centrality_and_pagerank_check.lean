-- Centrality: in every finite two-way network the shortest rides from s to t through v number exactly the shortest rides from s to v times those from v to t when v lies on a shortest way and none otherwise, the distance is the first power of the adjacency matrix with a nonzero entry, the degrees add up to twice the routes, and the card's ten-station numbers check out.
import Mathlib.Combinatorics.SimpleGraph.AdjMatrix
import Mathlib.Combinatorics.SimpleGraph.DegreeSum
import Mathlib.Combinatorics.SimpleGraph.Metric
import Mathlib.Combinatorics.SimpleGraph.Walk.Counting

namespace CentralityAndPagerank

open SimpleGraph

variable {V : Type*} [Fintype V] [DecidableEq V]

/-- `σ s t`: the number of shortest rides from `s` to `t`, that is, walks from `s` to `t` whose
number of routes equals the distance `d(s, t)`. -/
noncomputable def numShortest (G : SimpleGraph V) [DecidableRel G.Adj] (s t : V) : ℕ :=
  (G.finsetWalkLength (G.dist s t) s t).card

/-- `σ s t (v)`: the number of shortest rides from `s` to `t` that pass through station `v`. -/
noncomputable def numShortestThrough (G : SimpleGraph V) [DecidableRel G.Adj] (s t v : V) : ℕ :=
  ((G.finsetWalkLength (G.dist s t) s t).filter (fun p => v ∈ p.support)).card

omit [Fintype V] [DecidableEq V] in
/-- Splitting a walk at a fixed length of its first part is injective. -/
theorem append_inj_of_length_eq {G : SimpleGraph V} {s v t : V} {q q' : G.Walk s v}
    {r r' : G.Walk v t} (hl : q.length = q'.length) (h : q.append r = q'.append r') :
    q = q' ∧ r = r' := by
  have e := congrArg Walk.support h
  rw [Walk.support_append, Walk.support_append] at e
  obtain ⟨h1, h2⟩ := List.append_inj e (by simp [Walk.length_support, hl])
  refine ⟨Walk.ext_support h1, Walk.ext_support ?_⟩
  rw [← r.cons_tail_support, ← r'.cons_tail_support, h2]

#print axioms append_inj_of_length_eq

/-- The card's main result (Step 3), the fact that makes betweenness exact and cheap. On any
finite two-way network (a simple graph `G`), for any start `s`, target `t` and station `v`: the
number of shortest rides from `s` to `t` that pass through `v` is the number of shortest rides
from `s` to `v` times the number from `v` to `t` when `d(s, v) + d(v, t) = d(s, t)`, and 0
otherwise. -/
theorem shortest_rides_through_eq_mul (G : SimpleGraph V) [DecidableRel G.Adj] (s t v : V) :
    numShortestThrough G s t v =
      if G.dist s v + G.dist v t = G.dist s t then numShortest G s v * numShortest G v t
      else 0 := by
  classical
  unfold numShortestThrough numShortest
  have hsplit : ∀ p : G.Walk s t, ∀ h : v ∈ p.support,
      p.length = G.dist s t → G.dist s v + G.dist v t = G.dist s t ∧
        (p.takeUntil v h).length = G.dist s v ∧ (p.dropUntil v h).length = G.dist v t := by
    intro p h hp
    have e := congrArg Walk.length (p.take_spec h)
    rw [Walk.length_append] at e
    have h1 := G.dist_le (p.takeUntil v h)
    have h2 := G.dist_le (p.dropUntil v h)
    obtain ⟨q0, hq0⟩ := (p.takeUntil v h).reachable.exists_walk_length_eq_dist
    obtain ⟨r0, hr0⟩ := (p.dropUntil v h).reachable.exists_walk_length_eq_dist
    have h3 := G.dist_le (q0.append r0)
    rw [Walk.length_append] at h3
    omega
  split_ifs with hc
  · rw [← Finset.card_product]
    symm
    refine Finset.card_bij (fun x _ => x.1.append x.2) ?_ ?_ ?_
    · rintro ⟨q, r⟩ hx
      simp only [Finset.mem_product, mem_finsetWalkLength_iff] at hx
      simp only [Finset.mem_filter, mem_finsetWalkLength_iff, Walk.length_append]
      refine ⟨by omega, ?_⟩
      rw [Walk.mem_support_append_iff]
      exact Or.inr r.start_mem_support
    · rintro ⟨q, r⟩ hx ⟨q', r'⟩ hx' heq
      simp only [Finset.mem_product, mem_finsetWalkLength_iff] at hx hx' heq
      obtain ⟨e1, e2⟩ := append_inj_of_length_eq (by omega) heq
      rw [e1, e2]
    · intro p hp
      simp only [Finset.mem_filter, mem_finsetWalkLength_iff] at hp
      obtain ⟨hp, h⟩ := hp
      obtain ⟨-, h1, h2⟩ := hsplit p h hp
      refine ⟨(p.takeUntil v h, p.dropUntil v h), ?_, p.take_spec h⟩
      simp only [Finset.mem_product, mem_finsetWalkLength_iff]
      exact ⟨h1, h2⟩
  · rw [Finset.card_eq_zero, Finset.filter_eq_empty_iff]
    intro p hp hv
    rw [mem_finsetWalkLength_iff] at hp
    exact hc (hsplit p hv hp).1

/-- Step 2: distances come out in layers. When `w` can be reached from `v`, the distance
`d(v, w)` is the first power `k` at which the entry in row `v`, column `w` of `A ^ k` (the
number of walks of exactly `k` routes) is above zero. -/
theorem dist_eq_first_nonzero_adjMatrix_power (G : SimpleGraph V) [DecidableRel G.Adj]
    {v w : V} (h : G.Reachable v w) :
    (G.adjMatrix ℕ ^ G.dist v w) v w ≠ 0 ∧ ∀ k < G.dist v w, (G.adjMatrix ℕ ^ k) v w = 0 := by
  constructor
  · obtain ⟨p, hp⟩ := h.exists_walk_length_eq_dist
    rw [adjMatrix_pow_apply_eq_card_walk, Nat.cast_id]
    exact (Fintype.card_pos_iff.mpr ⟨⟨p, hp⟩⟩).ne'
  · intro k hk
    rw [adjMatrix_pow_apply_eq_card_walk, Nat.cast_id, Fintype.card_eq_zero_iff]
    refine ⟨fun ⟨p, hp⟩ => ?_⟩
    have := G.dist_le p
    simp only [Set.mem_ofPred_eq] at hp
    omega

/-- Step 1: every route has two ends, so the degrees of all stations add up to twice the
number of routes, `∑ deg(v) = 2m`. -/
theorem sum_degree_eq_two_mul_routes (G : SimpleGraph V) [DecidableRel G.Adj] :
    ∑ v, G.degree v = 2 * G.edgeFinset.card := by
  exact G.sum_degrees_eq_twice_card_edges

/-! The card's ten stations: Arcade, Bus Station, Cathedral, Market, East Gate, Fountain,
Guildhall, Hill Top, Riverside and Quay are `0` to `9`. Degree, closeness and betweenness read
the street map with every route two-way. -/

/-- The eighteen routes: AB AC AM AF BM BE BG CM CF ME MF MG EG FG FH GH HR RQ. -/
def routes : List (Fin 10 × Fin 10) :=
  [(0, 1), (0, 2), (0, 3), (0, 5), (1, 3), (1, 4), (1, 6), (2, 3), (2, 5), (3, 4), (3, 5),
   (3, 6), (4, 6), (5, 6), (5, 7), (6, 7), (7, 8), (8, 9)]

/-- The street map as a simple graph. -/
def streets : SimpleGraph (Fin 10) where
  Adj x y := (x, y) ∈ routes ∨ (y, x) ∈ routes
  symm := ⟨fun _ _ h => h.symm⟩
  loopless := ⟨by decide⟩

instance : DecidableRel streets.Adj := fun _ _ => inferInstanceAs (Decidable (_ ∨ _))

-- Degrees A to Q are 4 4 3 6 3 5 5 3 2 1; they add to 36 = 2 × 18 routes.
example : (List.finRange 10).map (fun v => streets.degree v) = [4, 4, 3, 6, 3, 5, 5, 3, 2, 1] := by
  decide
example : ∑ v, streets.degree v = 36 ∧ streets.edgeFinset.card = 18 := by decide
-- Market has the most routes, 6: every other station has fewer.
example : ∀ v : Fin 10, v ≠ 3 → streets.degree v < streets.degree 3 := by decide

/-- The card's distances from Fountain to A, B, C, M, E, F, G, H, R, Q. -/
def fromFountain : Fin 10 → ℕ := ![1, 2, 1, 1, 2, 0, 1, 1, 2, 3]

-- Fountain's layers: each distance is the first power of `A` with a nonzero entry, and they add to 14.
example : ∀ w : Fin 10, (streets.adjMatrix ℕ ^ fromFountain w) 5 w ≠ 0 ∧
    ∀ k < fromFountain w, (streets.adjMatrix ℕ ^ k) 5 w = 0 := by decide
example : ∑ w, fromFountain w = 14 := by decide
-- Market to Hill Top: distance 2, two shortest rides, one of them through Fountain.
example : streets.adjMatrix ℕ 3 7 = 0 ∧ (streets.finsetWalkLength 2 3 7).card = 2 ∧
    ((streets.finsetWalkLength 2 3 7).filter (fun p => (5 : Fin 10) ∈ p.support)).card = 1 := by
  decide
-- Arcade to Guildhall: distance 2, three shortest rides (via Market, Bus Station or Fountain), one through Fountain.
example : streets.adjMatrix ℕ 0 6 = 0 ∧ (streets.finsetWalkLength 2 0 6).card = 3 ∧
    ((streets.finsetWalkLength 2 0 6).filter (fun p => (5 : Fin 10) ∈ p.support)).card = 1 := by
  decide

#print axioms shortest_rides_through_eq_mul
#print axioms dist_eq_first_nonzero_adjMatrix_power
#print axioms sum_degree_eq_two_mul_routes

end CentralityAndPagerank
