-- Mapping spaces: on a compact metric domain the compact-open topology on continuous maps is the worst-gap (sup distance) topology, evaluation is continuous on a locally compact Hausdorff domain, and maps of two variables correspond exactly to continuous families of maps of one.
import Mathlib.Topology.CompactOpen
import Mathlib.Topology.MetricSpace.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Topology.ContinuousMap.Compact

open ContinuousMap Topology

/-- On a compact metric domain `X` with a metric target `Y`, a set of continuous maps is open in
the compact-open topology exactly when it is open for the worst-gap distance: round each of its
maps `f` there is a tolerance `ε > 0` such that every map `g` within `ε` of `f` at every point
also lies in the set. -/
theorem compactOpen_eq_worst_gap_topology {X Y : Type*} [MetricSpace X] [CompactSpace X]
    [MetricSpace Y] (S : Set C(X, Y)) :
    IsOpen[ContinuousMap.compactOpen] S ↔
      ∀ f ∈ S, ∃ ε > 0, ∀ g : C(X, Y), (∀ x, dist (g x) (f x) < ε) → g ∈ S := by
  rw [Metric.isOpen_iff]
  refine forall₂_congr fun f _ => exists_congr fun ε => and_congr_right fun hε => ?_
  constructor
  · intro h g hg
    exact h (Metric.mem_ball.mpr ((ContinuousMap.dist_lt_iff hε).mpr hg))
  · intro h g hg
    exact h g ((ContinuousMap.dist_lt_iff hε).mp (Metric.mem_ball.mp hg))

/-- On a locally compact Hausdorff domain `X`, evaluation `(f, x) ↦ f(x)` is a continuous map
from (mapping space) × (domain) to the target, for any target space `Y`. -/
theorem evaluation_continuous_of_locally_compact {X Y : Type*} [TopologicalSpace X]
    [LocallyCompactSpace X] [T2Space X] [TopologicalSpace Y] :
    Continuous (fun p : C(X, Y) × X => p.1 p.2) := by
  exact continuous_eval

/-- The exponential law: when `Y` is locally compact Hausdorff, continuous maps
`F : X × Y → Z` of two variables correspond one for one with continuous families
`x ↦ F(x, ·)`, that is with continuous maps `X → C(Y, Z)` into the mapping space. -/
theorem exponential_law {X Y Z : Type*} [TopologicalSpace X] [TopologicalSpace Y]
    [TopologicalSpace Z] [LocallyCompactSpace Y] [T2Space Y] :
    ∃ e : C(X × Y, Z) ≃ C(X, C(Y, Z)), ∀ (F : C(X × Y, Z)) (x : X) (y : Y), e F x y = F (x, y) := by
  refine ⟨⟨ContinuousMap.curry, ContinuousMap.uncurry, fun F => ?_, fun G => ?_⟩,
    fun F x y => rfl⟩
  · ext ⟨x, y⟩; rfl
  · ext x y; rfl

-- The card's worked numbers, exactly, as fractions (heights in metres).
-- worst gap between the drafts s and s^2, at s = 1/2
example : (1 / 2 : ℚ) - (1 / 2) ^ 2 = 1 / 4 := by norm_num
-- frame 1/2 of the morph at s = 1/2
example : (1 - 1 / 2 : ℚ) * (1 / 2) ^ 2 + (1 / 2) * (1 / 2) = 3 / 8 := by norm_num
-- frames 0.3 and 0.7 are |t - t'| / 4 apart; frames 0 and 1 are 1/4 apart
example : |(3 / 10 : ℚ) - 7 / 10| / 4 = 1 / 10 := by norm_num
example : |(0 : ℚ) - 1| / 4 = 1 / 4 := by norm_num
-- room round f([0, 1/2]) = [0, 1/4] inside the window (-1/10, 3/10)
example : min ((0 : ℚ) + 1 / 10) (3 / 10 - 1 / 4) = 1 / 20 := by norm_num
-- rise of s^2 on a piece of width 1/40: bound 2 x 1/40, worst actual rise on [39/40, 1]
example : (2 : ℚ) * (1 / 40) = 1 / 20 := by norm_num
example : (1 : ℚ) ^ 2 - (39 / 40) ^ 2 = 79 / 1600 := by norm_num
-- the coarse grid s = 0, 1/3, 2/3, 1 sees a worst gap s - s^2 of only 2/9, not 1/4
example : (1 / 3 : ℚ) - (1 / 3) ^ 2 = 2 / 9 ∧ (2 / 3 : ℚ) - (2 / 3) ^ 2 = 2 / 9 := by norm_num

#print axioms compactOpen_eq_worst_gap_topology
#print axioms evaluation_continuous_of_locally_compact
#print axioms exponential_law
