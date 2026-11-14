-- Graph algorithms as code: with a consistent heuristic, A*'s shifted street times are never negative and shift every route by the same amount, so the heuristic never overshoots and A* is Dijkstra on non-negative times; and breadth-first search does exactly stations plus twice the streets in work.
import Mathlib.Combinatorics.SimpleGraph.Walk.Basic
import Mathlib.Combinatorics.SimpleGraph.DegreeSum
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring

open SimpleGraph

/-- A* is Dijkstra on shifted street times. Let the heuristic h be consistent:
h(u) ≤ w(u, v) + h(v) on every street, and h(target) = 0. Give each street the shifted time
w'(u, v) = w(u, v) - h(u) + h(v). Then (1) no shifted time is negative; (2) along any route from
s to any station v the middle h terms cancel, so the shifted length is the true length
- h(s) + h(v), which is why Dijkstra on w' settles in order of d[v] + h(v); (3) every route from
s to the target is shifted by the same amount, its length - h(s); and (4) so the fastest route
is unchanged: one route beats another on shifted times exactly when it beats it on true times. -/
theorem astar_is_dijkstra_on_shifted_times {V : Type*} (G : SimpleGraph V)
    (w : V → V → ℝ) (h : V → ℝ) (t : V)
    (hcons : ∀ u v, G.Adj u v → h u ≤ w u v + h v) (ht : h t = 0) :
    (∀ u v, G.Adj u v → 0 ≤ w u v - h u + h v) ∧
    (∀ (s v : V) (p : G.Walk s v),
      (p.darts.map fun d => w d.fst d.snd - h d.fst + h d.snd).sum
        = (p.darts.map fun d => w d.fst d.snd).sum - h s + h v) ∧
    (∀ (s : V) (p : G.Walk s t),
      (p.darts.map fun d => w d.fst d.snd - h d.fst + h d.snd).sum
        = (p.darts.map fun d => w d.fst d.snd).sum - h s) ∧
    (∀ (s : V) (p q : G.Walk s t),
      (p.darts.map fun d => w d.fst d.snd - h d.fst + h d.snd).sum
          ≤ (q.darts.map fun d => w d.fst d.snd - h d.fst + h d.snd).sum
        ↔ (p.darts.map fun d => w d.fst d.snd).sum ≤ (q.darts.map fun d => w d.fst d.snd).sum) := by
  have h2 : ∀ (s v : V) (p : G.Walk s v),
      (p.darts.map fun d => w d.fst d.snd - h d.fst + h d.snd).sum
        = (p.darts.map fun d => w d.fst d.snd).sum - h s + h v := by
    intro s v p
    induction p with
    | nil => simp
    | cons hadj p ih =>
      simp only [Walk.darts_cons, List.map_cons, List.sum_cons]
      rw [ih]
      ring
  refine ⟨fun u v huv => by linarith [hcons u v huv], h2, ?_, ?_⟩
  · intro s p
    rw [h2, ht]
    ring
  · intro s p q
    rw [h2, h2]
    constructor <;> intro hle <;> linarith

/-- A consistent heuristic is "a guess, never too high": if h(u) ≤ w(u, v) + h(v) on every street
and h(target) = 0, then from every station v, h(v) is at most the riding time of any route from
v to the target. -/
theorem consistent_heuristic_never_too_high {V : Type*} (G : SimpleGraph V)
    (w : V → V → ℝ) (h : V → ℝ) (t : V)
    (hcons : ∀ u v, G.Adj u v → h u ≤ w u v + h v) (ht : h t = 0) :
    ∀ (v : V) (p : G.Walk v t), h v ≤ (p.darts.map fun d => w d.fst d.snd).sum := by
  intro v p
  induction p with
  | nil => simp [ht]
  | cons hadj p ih =>
    simp only [Walk.darts_cons, List.map_cons, List.sum_cons]
    linarith [hcons _ _ hadj, ih ht]

/-- Breadth-first search on adjacency lists: each station leaves the queue once and its street
list is read once, and each street has two ends, so the work is V removals plus 2E street looks,
V + 2E in all. -/
theorem bfs_work_is_stations_plus_twice_streets {V : Type*} [Fintype V] (G : SimpleGraph V)
    [DecidableRel G.Adj] :
    ∑ v, (1 + G.degree v) = Fintype.card V + 2 * G.edgeFinset.card := by
  rw [Finset.sum_add_distrib, sum_degrees_eq_twice_card_edges]
  simp

-- The city: a 40 by 30 grid has 1,200 stations and 39 x 30 + 40 x 29 = 2,330 streets.
example : 40 * 30 = 1200 ∧ 39 * 30 + 40 * 29 = 2330 := by decide
-- BFS work: 1,200 removals + 2 x 2,330 street looks = 5,860.
example : 2 * 2330 = 4660 ∧ 1200 + 2 * 2330 = 5860 := by decide
-- Growth table: BFS looks are exactly 2E at all three sizes (20 x 15, 40 x 30, 80 x 60 grids).
example : 19 * 15 + 20 * 14 = 565 ∧ 2 * 565 = 1130 := by decide
example : 79 * 60 + 80 * 59 = 9460 ∧ 2 * 9460 = 18920 ∧ 80 * 60 = 4800 := by decide
-- The trip is 28 blocks; h = 60 s per block guesses 1,680 s at the start, below the true 2,124 s.
example : (26 - 8) + (20 - 10) = 28 ∧ 60 * 28 = 1680 ∧ 1680 ≤ 2124 := by decide
-- Tripled to 180 s per block, the guess at the start is 5,040 s, far above the true 2,124 s.
example : 180 * 28 = 5040 ∧ 2124 < 5040 := by decide
-- A spanning tree of 1,200 stations keeps 1,199 streets; 92,026 s at 5 m/s is 460,130 m.
example : 1200 - 1 = 1199 ∧ 92026 * 5 = 460130 := by decide
-- Union by rank: top rank 5 means at least 2^5 = 32 stations, and 2^10 ≤ 1,200 < 2^11.
example : 2 ^ 5 = 32 ∧ 2 ^ 10 ≤ 1200 ∧ 1200 < 2 ^ 11 ∧ 4 ≤ 5 := by decide
-- After the one-way plan: 2 x 2,330 - 956 = 3,704 arrows, and the pieces 1,195 + 2 + 1 + 1 + 1 = 1,200.
example : 2 * 2330 - 956 = 3704 ∧ 1195 + 2 + 1 + 1 + 1 = 1200 := by decide

#print axioms astar_is_dijkstra_on_shifted_times
#print axioms consistent_heuristic_never_too_high
#print axioms bfs_work_is_stations_plus_twice_streets
