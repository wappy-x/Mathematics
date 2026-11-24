-- Paracompactness: every open cover of a paracompact Hausdorff space carries a partition of unity, such a space is normal, and every metric space is paracompact Hausdorff.
import Mathlib.Topology.Compactness.Paracompact
import Mathlib.Topology.EMetricSpace.Paracompact
import Mathlib.Topology.PartitionOfUnity
import Mathlib.Topology.MetricSpace.Basic
import Mathlib.Tactic.NormNum

open Set

/-- In a paracompact Hausdorff space every open cover `{U i}` carries a partition of unity
subordinate to it: continuous weights `φ i : X → [0, 1]`, the support of each inside `U i`,
the supports locally finite, and at every point the weights add to exactly 1. -/
theorem paracompact_hausdorff_exists_partition_of_unity
    {X : Type*} [TopologicalSpace X] [ParacompactSpace X] [T2Space X]
    {ι : Type*} (U : ι → Set X) (hU : ∀ i, IsOpen (U i)) (hcover : ⋃ i, U i = univ) :
    ∃ φ : ι → C(X, ℝ),
      (∀ i x, φ i x ∈ Icc (0 : ℝ) 1) ∧
      (∀ i, tsupport (φ i) ⊆ U i) ∧
      LocallyFinite (fun i => tsupport (φ i)) ∧
      (∀ x, ∑ᶠ i, φ i x = 1) := by
  obtain ⟨f, hf⟩ := PartitionOfUnity.exists_isSubordinate isClosed_univ U hU (by rw [hcover])
  refine ⟨fun i => f i, fun i x => ⟨f.nonneg i x, f.le_one i x⟩, hf, f.locallyFinite_tsupport,
    fun x => f.sum_eq_one (mem_univ x)⟩

/-- Dieudonné: a paracompact Hausdorff space is normal, so any two disjoint closed sets
lie in two disjoint open sets. -/
theorem paracompact_hausdorff_is_normal
    {X : Type*} [TopologicalSpace X] [ParacompactSpace X] [T2Space X] :
    NormalSpace X := by
  infer_instance

/-- Stone (1948): every metric space is paracompact (and Hausdorff, as this card's
definition of paracompact requires). -/
theorem metric_space_is_paracompact {X : Type*} [MetricSpace X] :
    ParacompactSpace X ∧ T2Space X := by
  exact ⟨inferInstance, inferInstance⟩

-- The tents at 2.3 km: phi_2 = 7/10, phi_3 = 3/10, phi_1 = 0, and they add to 1.
example : max (0 : ℚ) (1 - |23/10 - 2|) = 7/10 := by norm_num [abs_of_pos]
example : max (0 : ℚ) (1 - |23/10 - 3|) = 3/10 := by norm_num [abs_of_neg]
example : max (0 : ℚ) (1 - |23/10 - 1|) = 0 := by norm_num [abs_of_pos]
example : (7/10 : ℚ) + 3/10 = 1 := by norm_num
-- The point 2.3 lies in the stretches U_n = (n - 3/2, n + 3/2) exactly for n = 1, 2, 3
-- (scaled by 10 to whole numbers: |23 - 10 n| < 15), checked over the markers -25 to 25.
example : ((Finset.Icc (-25 : ℤ) 25).filter
    (fun n : ℤ => |23 - 10 * n| < 15)) = {1, 2, 3} := by decide
-- The glued height by tents: 7/10 * 135 + 3/10 * 150 = 279/2 m (139.5 m), the straight line from marker 2 to 3.
example : (7/10 : ℚ) * 135 + 3/10 * 150 = 279/2 := by norm_num
example : (135 : ℚ) + (23/10 - 2) * (150 - 135) = 279/2 := by norm_num
-- The dials of Step 4 at 2.3 km: psi_3 = 5/6, Psi = 11/6, weights 6/11 and 5/11, glued height 1560/11 m.
example : ((6/5 : ℚ) - 7/10) / (6/5 - 3/5) = 5/6 := by norm_num
example : (1 : ℚ) + 5/6 = 11/6 := by norm_num
example : (1 : ℚ) / (11/6) = 6/11 ∧ (5/6 : ℚ) / (11/6) = 5/11 := by norm_num
example : (6/11 : ℚ) * 135 + 5/11 * 150 = 1560/11 := by norm_num
-- Forgetting to divide: 135 + (5/6) * 150 = 260 m.
example : (135 : ℚ) + 5/6 * 150 = 260 := by norm_num
-- The Nagata-Smirnov layer-5 interval (73/32, 75/32) lies inside the ball of radius 1/10 round 23/10.
example : (23/10 : ℚ) - 1/10 ≤ 73/32 ∧ (73/32 : ℚ) < 23/10 ∧ (23/10 : ℚ) < 75/32 ∧
    (75/32 : ℚ) ≤ 23/10 + 1/10 := by norm_num

#print axioms paracompact_hausdorff_exists_partition_of_unity
#print axioms paracompact_hausdorff_is_normal
#print axioms metric_space_is_paracompact
