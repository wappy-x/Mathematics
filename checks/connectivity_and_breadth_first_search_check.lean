-- Connected or not: flooding a finite graph round by round from a start vertex halts having marked exactly the vertices some route joins to it, each first marked in the round equal to its fewest steps, fresh floods count the pieces, the graph is connected exactly when one flood marks everything, and the card's town numbers check out.
import Mathlib.Combinatorics.SimpleGraph.Metric
import Mathlib.Combinatorics.SimpleGraph.Connectivity.Finite
import Mathlib.Data.Fintype.Card

open Finset

variable {V : Type*} [Fintype V] [DecidableEq V]

/-- The flood from the start `s`: after round `0` only `s` is marked; each round then also marks
every neighbour of a marked vertex. A vertex's ring number is the first round that marks it. -/
def flood (G : SimpleGraph V) [DecidableRel G.Adj] (s : V) : ℕ → Finset V
  | 0 => {s}
  | k + 1 => flood G s k ∪ univ.filter (fun w => ∃ v ∈ flood G s k, G.Adj v w)

theorem flood_mem_iff_walk (G : SimpleGraph V) [DecidableRel G.Adj] (s : V) :
    ∀ (k : ℕ) (v : V), v ∈ flood G s k ↔ ∃ p : G.Walk s v, p.length ≤ k := by
  intro k
  induction k with
  | zero =>
    intro v
    constructor
    · intro h
      have : v = s := by simpa [flood] using h
      subst this
      exact ⟨SimpleGraph.Walk.nil, le_refl _⟩
    · rintro ⟨p, hp⟩
      have := SimpleGraph.Walk.eq_of_length_eq_zero (Nat.le_zero.mp hp)
      subst this
      simp [flood]
  | succ k ih =>
    intro v
    have e : flood G s (k + 1) =
        flood G s k ∪ univ.filter (fun w => ∃ u ∈ flood G s k, G.Adj u w) := rfl
    rw [e, Finset.mem_union, Finset.mem_filter]
    constructor
    · rintro (h | ⟨-, u, hu, huv⟩)
      · obtain ⟨p, hp⟩ := (ih v).mp h
        exact ⟨p, by omega⟩
      · obtain ⟨p, hp⟩ := (ih u).mp hu
        exact ⟨p.concat huv, by rw [SimpleGraph.Walk.length_concat]; omega⟩
    · rintro ⟨p, hp⟩
      by_cases hk : p.length ≤ k
      · exact Or.inl ((ih v).mpr ⟨p, hk⟩)
      · right
        refine ⟨Finset.mem_univ _, ?_⟩
        have hlen : p.reverse.length = k + 1 := by
          rw [SimpleGraph.Walk.length_reverse]; omega
        cases hq : p.reverse with
        | nil => rw [hq] at hlen; simp at hlen
        | cons h q =>
          rw [hq, SimpleGraph.Walk.length_cons] at hlen
          refine ⟨_, (ih _).mpr ⟨q.reverse, ?_⟩, h.symm⟩
          rw [SimpleGraph.Walk.length_reverse]; omega

theorem flood_mem_iff_reach_dist (G : SimpleGraph V) [DecidableRel G.Adj] (s : V)
    (k : ℕ) (v : V) : v ∈ flood G s k ↔ G.Reachable s v ∧ G.dist s v ≤ k := by
  rw [flood_mem_iff_walk]
  constructor
  · rintro ⟨p, hp⟩
    exact ⟨⟨p⟩, (SimpleGraph.dist_le p).trans hp⟩
  · rintro ⟨hr, hd⟩
    obtain ⟨p, hp⟩ := hr.exists_walk_length_eq_dist
    exact ⟨p, hp ▸ hd⟩

theorem dist_lt_card_of_reachable (G : SimpleGraph V) {s v : V} (h : G.Reachable s v) :
    G.dist s v < Fintype.card V := by
  obtain ⟨p⟩ := h
  exact lt_of_le_of_lt (SimpleGraph.dist_le p.bypass) p.bypass_isPath.length_lt

theorem flood_mem_iff_reach_of_card_le (G : SimpleGraph V) [DecidableRel G.Adj] (s : V)
    {k : ℕ} (hk : Fintype.card V ≤ k) (v : V) : v ∈ flood G s k ↔ G.Reachable s v := by
  rw [flood_mem_iff_reach_dist]
  constructor
  · exact fun h => h.1
  · intro h
    exact ⟨h, (dist_lt_card_of_reachable G h).le.trans hk⟩

theorem flood_card_mem_iff (G : SimpleGraph V) [DecidableRel G.Adj] (v w : V) :
    w ∈ flood G v (Fintype.card V) ↔ G.connectedComponentMk w = G.connectedComponentMk v := by
  rw [flood_mem_iff_reach_of_card_le G v le_rfl, SimpleGraph.ConnectedComponent.eq]
  exact ⟨fun h => h.symm, fun h => h.symm⟩

#print axioms flood_mem_iff_walk
#print axioms flood_mem_iff_reach_dist
#print axioms dist_lt_card_of_reachable
#print axioms flood_mem_iff_reach_of_card_le
#print axioms flood_card_mem_iff

/-- Breadth-first search finds the start's piece and the fewest steps. On a finite graph whose
paths run both ways and all count the same, the flood from `s` has marked a vertex by round `k`
exactly when some route joins `s` to it and the fewest paths such a route needs is at most `k`
(so a vertex's ring number is its fewest steps). The flood halts: some round adds nothing. And
whenever a round adds nothing, the marked vertices are exactly those some route joins to `s`. -/
theorem flood_marks_reachable_numbered_by_fewest_steps (G : SimpleGraph V) [DecidableRel G.Adj]
    (s : V) :
    (∀ (k : ℕ) (v : V), v ∈ flood G s k ↔ G.Reachable s v ∧ G.dist s v ≤ k) ∧
      (∃ k, flood G s (k + 1) = flood G s k) ∧
      (∀ k, flood G s (k + 1) = flood G s k → ∀ v, v ∈ flood G s k ↔ G.Reachable s v) := by
  refine ⟨flood_mem_iff_reach_dist G s, ⟨Fintype.card V, ?_⟩, ?_⟩
  · ext v
    rw [flood_mem_iff_reach_of_card_le G s (Nat.le_succ _),
      flood_mem_iff_reach_of_card_le G s le_rfl]
  · intro k hk
    have hstab : ∀ n, flood G s (k + n) = flood G s k := by
      intro n
      induction n with
      | zero => rfl
      | succ n ih =>
        have e : flood G s (k + (n + 1)) =
            flood G s (k + n) ∪ univ.filter (fun w => ∃ u ∈ flood G s (k + n), G.Adj u w) := rfl
        rw [e, ih]
        exact hk
    intro v
    constructor
    · intro h
      exact ((flood_mem_iff_reach_dist G s k v).mp h).1
    · intro h
      rw [← hstab (G.dist s v), flood_mem_iff_reach_dist]
      exact ⟨h, by omega⟩

/-- Fresh starts count the pieces. Flood from every vertex for as many rounds as there are
vertices: the different marked sets that come out number exactly the graph's components. -/
theorem card_distinct_floods_eq_card_components (G : SimpleGraph V) [DecidableRel G.Adj] :
    (univ.image (fun v => flood G v (Fintype.card V))).card =
      Fintype.card G.ConnectedComponent := by
  classical
  let h : G.ConnectedComponent → Finset V :=
    fun C => univ.filter (fun w => G.connectedComponentMk w = C)
  have hf : (fun v => flood G v (Fintype.card V)) = h ∘ G.connectedComponentMk := by
    funext v
    ext w
    simp [h, flood_card_mem_iff]
  have hinj : Function.Injective h := by
    intro C D hCD
    obtain ⟨w, rfl⟩ := C.exists_rep
    change h (G.connectedComponentMk w) = h D at hCD
    have hw : w ∈ h (G.connectedComponentMk w) := by simp [h]
    rw [hCD] at hw
    have hw' : G.connectedComponentMk w = D := by simpa [h] using hw
    exact hw'
  have hs : Function.Surjective G.connectedComponentMk := fun C => C.exists_rep
  rw [hf, ← Finset.image_image, Finset.card_image_of_injective _ hinj,
    Finset.image_univ_of_surjective hs]
  convert Finset.card_univ

/-- Connected or not. A finite graph is connected exactly when one flood, from any start `s`,
marks every vertex once it halts. -/
theorem connected_iff_flood_marks_all (G : SimpleGraph V) [DecidableRel G.Adj] (s : V) :
    G.Connected ↔ flood G s (Fintype.card V) = univ := by
  rw [SimpleGraph.connected_iff_exists_forall_reachable, Finset.eq_univ_iff_forall]
  simp only [flood_mem_iff_reach_of_card_le G s le_rfl]
  constructor
  · rintro ⟨u, hu⟩ v
    exact (hu s).symm.trans (hu v)
  · intro h
    exact ⟨s, h⟩

/-- The town's eleven cycle paths, junctions numbered S = 0, A = 1, B = 2, C = 3, D = 4, E = 5,
F = 6, G = 7, H = 8. The river bridge D-F is the pair `(4, 6)`. -/
def openPaths : List (Fin 9 × Fin 9) :=
  [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4), (3, 4), (3, 5), (4, 5), (4, 6), (6, 7), (7, 8)]
/-- The ten paths left once the bridge shuts. -/
def shutPaths : List (Fin 9 × Fin 9) := openPaths.erase (4, 6)

/-- The town as a graph on its paths, each running both ways. -/
def townOf (P : List (Fin 9 × Fin 9)) (hP : ∀ p ∈ P, p.1 ≠ p.2) : SimpleGraph (Fin 9) where
  Adj u v := (u, v) ∈ P ∨ (v, u) ∈ P
  symm := ⟨fun _ _ h => h.symm⟩
  loopless := ⟨fun _ h => by rcases h with h | h <;> exact hP _ h rfl⟩

instance (P : List (Fin 9 × Fin 9)) (hP) : DecidableRel (townOf P hP).Adj :=
  fun u v => inferInstanceAs (Decidable ((u, v) ∈ P ∨ (v, u) ∈ P))

/-- The town with the bridge shut, and with it open. -/
abbrev town : SimpleGraph (Fin 9) := townOf shutPaths (by decide)
abbrev townOpen : SimpleGraph (Fin 9) := townOf openPaths (by decide)

-- Nine junctions, ten paths after the bridge shuts.
example : shutPaths.length = 10 ∧ openPaths.length = 11 := by decide
-- Rings 0 to 4 from S: S; A B; C D; E; nothing new, so the flood halts.
example : flood town 0 0 = {0} := by decide
example : flood town 0 1 \ flood town 0 0 = {1, 2} := by decide
example : flood town 0 2 \ flood town 0 1 = {3, 4} := by decide
example : flood town 0 3 \ flood town 0 2 = {5} := by decide
example : flood town 0 4 = flood town 0 3 := by decide
-- The station's piece: 1 + 2 + 2 + 1 = 6 junctions, holding 10 − 2 = 8 paths.
example : flood town 0 3 = {0, 1, 2, 3, 4, 5} ∧ (flood town 0 3).card = 6 := by decide
example : (shutPaths.filter (fun p => p.1 ∈ flood town 0 3 ∧ p.2 ∈ flood town 0 3)).length = 8 := by
  decide
-- A fresh start at F marks F, G, H: 3 junctions, 2 paths.
example : flood town 6 2 = {6, 7, 8} ∧ flood town 6 3 = flood town 6 2 := by decide
example : (shutPaths.filter (fun p => p.1 ∈ flood town 6 2 ∧ p.2 ∈ flood town 6 2)).length = 2 := by
  decide
-- Two pieces, 6 + 3 = 9: not connected.
example : (univ.image (fun v => flood town v 9)).card = 2 ∧ 6 + 3 = 9 := by decide
example : flood town 0 9 ≠ univ := by decide
-- Fewest paths to E is 3, by S-A-C-E.
example : 5 ∉ flood town 0 2 ∧ 5 ∈ flood town 0 3 := by decide
example : town.Adj 0 1 ∧ town.Adj 1 3 ∧ town.Adj 3 5 := by decide
-- Work: 6 queue places, 8 paths seen twice = 16.
example : 2 * 8 = 16 := by decide
-- The dive S-A-B-D-C-E puts E five paths down its chain, against a fewest of three.
example : town.Adj 0 1 ∧ town.Adj 1 2 ∧ town.Adj 2 4 ∧ town.Adj 4 3 ∧ town.Adj 3 5 := by decide
-- Bridge reopened: one flood covers all nine, F, G, H at 3, 4, 5 steps, one piece.
example : flood townOpen 0 5 = univ ∧ 8 ∉ flood townOpen 0 4 := by decide
example : 6 ∈ flood townOpen 0 3 \ flood townOpen 0 2 ∧ 7 ∈ flood townOpen 0 4 \ flood townOpen 0 3 := by
  decide
example : (univ.image (fun v => flood townOpen v 9)).card = 1 := by decide

#print axioms flood_marks_reachable_numbered_by_fewest_steps
#print axioms card_distinct_floods_eq_card_components
#print axioms connected_iff_flood_marks_all
