-- Hausdorff and its ladder: in a Hausdorff space every sequence has at most one limit, normal implies regular implies Hausdorff implies T1, and every metric space is normal.
import Mathlib.Topology.Separation.Hausdorff
import Mathlib.Topology.Separation.Regular
import Mathlib.Topology.MetricSpace.Basic
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Tactic.NormNum

open Filter Topology

/-- In a Hausdorff space (any two different points lie in two open sets that do not
overlap), a sequence that converges to `L` and also to `M` forces `L = M`:
every sequence has at most one limit. -/
theorem hausdorff_sequence_limit_unique {X : Type*} [TopologicalSpace X] [T2Space X]
    {a : ℕ → X} {L M : X}
    (hL : Tendsto a atTop (𝓝 L)) (hM : Tendsto a atTop (𝓝 M)) : L = M := by
  exact tendsto_nhds_unique hL hM

/-- The ladder: each rung implies the one below. Normal (with points closed) implies
regular (with points closed); regular (with points closed) implies Hausdorff;
Hausdorff implies that every single point is a closed set (T1). -/
theorem separation_ladder (X : Type*) [TopologicalSpace X] :
    ((T1Space X ∧ NormalSpace X) → (T1Space X ∧ RegularSpace X)) ∧
    ((T1Space X ∧ RegularSpace X) → T2Space X) ∧
    (T2Space X → T1Space X) := by
  refine ⟨fun ⟨h1, h2⟩ => ⟨h1, inferInstance⟩, fun ⟨h1, h2⟩ => inferInstance,
    fun h => inferInstance⟩

/-- Every distance (metric) space is normal: points are closed, and any two disjoint
closed sets lie in two open sets that do not overlap. -/
theorem metric_space_normal (X : Type*) [MetricSpace X] : T1Space X ∧ NormalSpace X := by
  exact ⟨inferInstance, inferInstance⟩

-- Worked numbers: two bands of radius 1/10 and 1/1000 share the point min(r, s)/2 = 1/2000.
example : min (1 / 10 : ℚ) (1 / 1000) / 2 = 1 / 2000 := by norm_num

-- Cutoff 10 for tolerance 1/10: the 11th share is inside the band, the 10th is not.
example : (1 / 11 : ℚ) < 1 / 10 ∧ ¬ ((1 / 10 : ℚ) < 1 / 10) := by norm_num

-- The circle: P = (1, 0) and Q = (3/5, 4/5); Q is on the circle and the gap squared is 4/5.
example : (3 / 5 : ℚ) ^ 2 + (4 / 5) ^ 2 = 1 := by norm_num
example : (1 - 3 / 5 : ℚ) ^ 2 + (0 - 4 / 5) ^ 2 = 4 / 5 := by norm_num

-- The nearer-to-which rule switches at n + 1/(2n): 9/4, 19/6, 201/20, 20001/200.
example : (2 + 1 / (2 * 2) : ℚ) = 9 / 4 := by norm_num
example : (3 + 1 / (2 * 3) : ℚ) = 19 / 6 := by norm_num
example : (10 + 1 / (2 * 10) : ℚ) = 201 / 20 := by norm_num
example : (100 + 1 / (2 * 100) : ℚ) = 20001 / 200 := by norm_num

-- A fixed buffer of width 1/100 first fails at n = 51: the gap 1/51 is under 2/100, while 1/50 is not.
example : (1 / 51 : ℚ) < 2 / 100 ∧ ¬ ((1 / 50 : ℚ) < 2 / 100) := by norm_num

-- K-topology: with n = 11 the shared point 1/n - e/2 is 1989/22000 (e = 1/1000)
-- and 1999989/22000000 (e = 1/1000000); both lie strictly between 1/12 and 1/11.
example : (1 / 11 - (1 / 1000) / 2 : ℚ) = 1989 / 22000 := by norm_num
example : (1 / 11 - (1 / 1000000) / 2 : ℚ) = 1999989 / 22000000 := by norm_num
example : (1 / 12 : ℚ) < 1989 / 22000 ∧ (1989 / 22000 : ℚ) < 1 / 11 := by norm_num
example : (1 / 12 : ℚ) < 1999989 / 22000000 ∧ (1999989 / 22000000 : ℚ) < 1 / 11 := by norm_num

#print axioms hausdorff_sequence_limit_unique
#print axioms separation_ladder
#print axioms metric_space_normal
