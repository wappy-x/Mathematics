-- Open balls, open sets and closed sets: in any metric space an open ball is open, a closed ball is closed, and a set is open exactly when it is the union of one ball inside it round each of its points.
import Mathlib.Topology.MetricSpace.Defs
import Mathlib.Topology.MetricSpace.Pseudo.Lemmas
import Mathlib.Tactic.NormNum

open Metric

/-- Every open set is built from balls. In a metric space, a set U is open exactly when there is
a radius r x > 0 for each member x such that the ball B(x, r x) lies inside U and the union of all
these balls, one round each member, is U itself. -/
theorem open_iff_union_of_balls {X : Type*} [MetricSpace X] (U : Set X) :
    IsOpen U ↔ ∃ r : X → ℝ, (∀ x ∈ U, 0 < r x ∧ ball x (r x) ⊆ U) ∧
      U = ⋃ x ∈ U, ball x (r x) := by
  classical
  constructor
  · intro hU
    rw [Metric.isOpen_iff] at hU
    refine ⟨fun x => if h : x ∈ U then Classical.choose (hU x h) else 1, ?_, ?_⟩
    · intro x hx
      simp only [hx, ↓reduceDIte]
      exact Classical.choose_spec (hU x hx)
    · apply Set.Subset.antisymm
      · intro x hx
        refine Set.mem_iUnion₂.mpr ⟨x, hx, ?_⟩
        simp only [hx, ↓reduceDIte]
        exact Metric.mem_ball_self (Classical.choose_spec (hU x hx)).1
      · refine Set.iUnion₂_subset fun x hx => ?_
        simp only [hx, ↓reduceDIte]
        exact (Classical.choose_spec (hU x hx)).2
  · rintro ⟨r, hr, -⟩
    rw [Metric.isOpen_iff]
    intro x hx
    exact ⟨r x, (hr x hx).1, (hr x hx).2⟩

/-- An open ball is open, with its room given exactly. If y is in the ball B(c, r), then its room
r - d(c, y) is positive and the ball round y of that radius lies inside B(c, r). -/
theorem open_ball_room {X : Type*} [MetricSpace X] (c y : X) (r : ℝ) (hy : y ∈ ball c r) :
    0 < r - dist c y ∧ ball y (r - dist c y) ⊆ ball c r := by
  have h : dist y c < r := hy
  refine ⟨by rw [dist_comm]; linarith, ?_⟩
  intro z hz
  have hz' : dist z y < r - dist c y := hz
  show dist z c < r
  calc dist z c ≤ dist z y + dist y c := dist_triangle z y c
    _ < r := by rw [dist_comm y c]; linarith

/-- A closed ball is closed. In a metric space the closed ball B[c, r], every point at distance
at most r from c, has an open outside. -/
theorem closed_ball_is_closed {X : Type*} [MetricSpace X] (c : X) (r : ℝ) :
    IsClosed (closedBall c r) := by
  exact Metric.isClosed_closedBall

-- The card's worked numbers on the street grid, Central Station at (0, 0), in whole blocks.
-- Café (2, 1): walks 3, room 5 - 3 = 2 inside "under 5".
example : |(2 : ℤ) - 0| + |(1 : ℤ) - 0| = 3 := by norm_num
example : (5 : ℤ) - 3 = 2 := by norm_num
-- Library (3, 2): walks exactly 5, on the rim.
example : |(3 : ℤ) - 0| + |(2 : ℤ) - 0| = 5 := by norm_num
-- Stadium (4, 3): walks 7, straight line 5 (4² + 3² = 5²), room 7 - 5 = 2 outside "at most 5".
example : |(4 : ℤ) - 0| + |(3 : ℤ) - 0| = 7 := by norm_num
example : (4 : ℤ) ^ 2 + 3 ^ 2 = 5 ^ 2 := by norm_num
example : (7 : ℤ) - 5 = 2 := by norm_num
-- Four places alone: Café–Library and Library–Stadium are 2 blocks apart; 2^4 = 16 sets of places.
example : |(3 : ℤ) - 2| + |(2 : ℤ) - 1| = 2 := by norm_num
example : |(4 : ℤ) - 3| + |(3 : ℤ) - 2| = 2 := by norm_num
example : 2 ^ 4 = 16 := by decide
-- Downtown, stage k: grid points 1/2^k apart strictly inside the 6 by 4 rectangle,
-- (6·2^k - 1)(4·2^k - 1) balls: 15, 77, 345, 1457 at stages 0 to 3.
example : (6 * 2 ^ 0 - 1) * (4 * 2 ^ 0 - 1) = 15 := by decide
example : (6 * 2 ^ 1 - 1) * (4 * 2 ^ 1 - 1) = 77 := by decide
example : (6 * 2 ^ 2 - 1) * (4 * 2 ^ 2 - 1) = 345 := by decide
example : (6 * 2 ^ 3 - 1) * (4 * 2 ^ 3 - 1) = 1457 := by decide

#print axioms open_iff_union_of_balls
#print axioms open_ball_room
#print axioms closed_ball_is_closed
