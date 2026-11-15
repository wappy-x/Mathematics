-- Compactness with no distances, and Tychonoff: any product of compact spaces is compact, compactness by open covers equals compactness by closed sets with the finite intersection property, and a compact Hausdorff space is normal.
import Mathlib.Topology.Compactness.Compact
import Mathlib.Topology.Separation.Regular
import Mathlib.Data.Fintype.Powerset
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Algebra.Order.Field.Rat
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.IntervalCases

open Set

universe u

/-- Tychonoff's theorem: if every factor `X i` is compact, then the product of all of them,
with the product topology, is compact, however many factors there are. -/
theorem tychonoff_product_of_compact_spaces_is_compact
    {I : Type*} {X : I → Type*} [∀ i, TopologicalSpace (X i)]
    (h : ∀ i, CompactSpace (X i)) : CompactSpace (∀ i, X i) := by
  exact Pi.compactSpace

/-- A space is compact exactly when every open cover has a finite subcover, and exactly when
every family of closed sets with the finite intersection property (every finite batch has a
point in common) has a point common to all its sets. -/
theorem compact_iff_finite_subcover_iff_closed_fip {X : Type u} [TopologicalSpace X] :
    (CompactSpace X ↔
      ∀ (I : Type u) (U : I → Set X), (∀ i, IsOpen (U i)) → (⋃ i, U i) = univ →
        ∃ t : Finset I, (⋃ i ∈ t, U i) = univ) ∧
    (CompactSpace X ↔
      ∀ (I : Type u) (C : I → Set X), (∀ i, IsClosed (C i)) →
        (∀ t : Finset I, (⋂ i ∈ t, C i).Nonempty) → (⋂ i, C i).Nonempty) := by
  constructor
  · rw [← isCompact_univ_iff, isCompact_iff_finite_subcover]
    constructor
    · intro h I U hU hcov
      obtain ⟨t, ht⟩ := h U hU (by rw [hcov])
      exact ⟨t, univ_subset_iff.mp ht⟩
    · intro h ι U hU hs
      obtain ⟨t, ht⟩ := h ι U hU (univ_subset_iff.mp hs)
      exact ⟨t, by rw [ht]⟩
  · rw [← isCompact_univ_iff, isCompact_iff_finite_subfamily_closed]
    constructor
    · intro h I C hC hfip
      by_contra hne
      rw [not_nonempty_iff_eq_empty] at hne
      obtain ⟨u, hu⟩ := h C hC (by rw [hne]; exact disjoint_empty _)
      exact (nonempty_iff_ne_empty.mp (hfip u)) (univ_disjoint.mp hu)
    · intro h ι t ht hd
      by_contra hne
      push Not at hne
      have hfip : ∀ u : Finset ι, (⋂ i ∈ u, t i).Nonempty := fun u =>
        nonempty_iff_ne_empty.mpr fun he => hne u (by rw [he]; exact disjoint_empty _)
      exact nonempty_iff_ne_empty.mp (h ι t ht hfip) (univ_disjoint.mp hd)

/-- A compact Hausdorff space is normal: any two disjoint closed sets lie in disjoint
open sets. -/
theorem compact_hausdorff_space_is_normal {X : Type u} [TopologicalSpace X]
    [CompactSpace X] [T2Space X] : NormalSpace X := by
  infer_instance

/-! The card's exact checks. The circle is measured in turns from the glue point, and for
`n ≥ 1` the arc `U_n` is the open arc from `1/(n+2)` to `1/n` of a turn. -/

/-- With the glue point removed: `U_1, ..., U_10` all miss the point 1/12 of a turn. -/
example : ∀ n ∈ Finset.Icc (1 : ℕ) 10,
    ¬ ((1 : ℚ) / ((n : ℚ) + 2) < 1 / 12 ∧ (1 : ℚ) / 12 < 1 / (n : ℚ)) := by
  intro n hn
  simp only [Finset.mem_Icc] at hn
  obtain ⟨h1, h2⟩ := hn
  interval_cases n <;> norm_num

/-- `U_11`, the arc from 1/13 to 1/11, holds the point 1/12. -/
example : (1 : ℚ) / 13 < 1 / 12 ∧ (1 : ℚ) / 12 < 1 / 11 := by norm_num

/-- Each point 1/k of a turn, k = 2, ..., 10, lies in exactly one of `U_1, ..., U_13`,
namely `U_(k-1)`; so these nine points need nine different arcs. -/
example : ∀ k ∈ Finset.Icc (2 : ℕ) 10, ∀ n ∈ Finset.Icc (1 : ℕ) 13,
    ((1 : ℚ) / ((n : ℚ) + 2) < 1 / (k : ℚ) ∧ (1 : ℚ) / (k : ℚ) < 1 / (n : ℚ)) ↔ n = k - 1 := by
  intro k hk n hn
  simp only [Finset.mem_Icc] at hk hn
  obtain ⟨hk1, hk2⟩ := hk
  obtain ⟨hn1, hn2⟩ := hn
  interval_cases k <;> interval_cases n <;> norm_num

/-- On the 3-point set, 38 of the 256 families of subsets have the finite intersection
property (counting the empty family). -/
example :
    ((Finset.univ : Finset (Fin 3)).powerset.powerset.filter
      (fun F => ∀ G ∈ F.powerset, ∃ x : Fin 3, ∀ A ∈ G, x ∈ A)).card = 38 := by
  decide +kernel

/-- On the 3-point set, exactly 3 families with the finite intersection property are maximal. -/
example :
    let fip := (Finset.univ : Finset (Fin 3)).powerset.powerset.filter
      (fun F => ∀ G ∈ F.powerset, ∃ x : Fin 3, ∀ A ∈ G, x ∈ A)
    (fip.filter (fun F => ∀ H ∈ fip, ¬ F ⊂ H)).card = 3 := by
  decide +kernel

/-- Inclusion-exclusion gives the same 38, and ten boxes of two socks give 2^10 = 1024 full
picks among 3^10 = 59049 points, and three of the sets F_i share 2^3 * 3^7 = 17496 points. -/
example : 3 * 2 ^ 4 - 3 * 2 ^ 2 + 1 * 2 ^ 1 = 38 ∧ 2 ^ 10 = 1024 ∧ 3 ^ 10 = 59049 ∧
    2 ^ 3 * 3 ^ 7 = 17496 := by
  norm_num

#print axioms tychonoff_product_of_compact_spaces_is_compact
#print axioms compact_iff_finite_subcover_iff_closed_fip
#print axioms compact_hausdorff_space_is_normal
