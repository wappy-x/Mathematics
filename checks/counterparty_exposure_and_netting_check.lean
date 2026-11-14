-- Counterparty exposure: netting trades into sets never raises current exposure, every netting arrangement lies between full netting and no netting, and inside one set netting saves exactly the smaller of the amounts owed each way.
import Mathlib.Algebra.Order.Group.PosPart
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Order.Partition.Finpartition
import Mathlib.Basic.Real.Basic
import Mathlib.Data.Fin.VecNotation

/-! Trades are indexed by a finite type `ι`; `V i` is the value of trade `i` to the bank today
(plus: the counterparty owes the bank, minus: the bank owes the counterparty).
An arrangement of netting sets is a `Finpartition` of all trades: the sets do not overlap and
cover every trade once. `x⁺ = max x 0` is Mathlib's positive part and `x⁻ = max (-x) 0` its
negative part. Current exposure under arrangement `S` is
`∑ A ∈ S.parts, (∑ i ∈ A, V i)⁺`: add inside each set, floor each total at zero, add the totals.
In Mathlib, `fine ≤ coarse` for finpartitions means every set of `fine` lies inside one set
of `coarse`, so `coarse` nets at least as much as `fine`. -/

open Finset

/-- The positive part of a sum is at most the sum of the positive parts. -/
theorem posPart_sum_le_sum_posPart {ι : Type*} (s : Finset ι) (f : ι → ℝ) :
    (∑ i ∈ s, f i)⁺ ≤ ∑ i ∈ s, (f i)⁺ := by
  classical
  induction s using Finset.induction_on with
  | empty => simp
  | insert a s ha ih =>
    rw [sum_insert ha, sum_insert ha]
    rw [posPart_def]
    refine sup_le ?_ ?_
    · exact add_le_add (le_posPart _) ((le_posPart _).trans ih)
    · exact add_nonneg (posPart_nonneg _) (sum_nonneg fun i _ => posPart_nonneg _)

/-- Summing over the parts of a finpartition and then inside each part gives the full sum. -/
theorem sum_parts_sum_eq {ι : Type*} [DecidableEq ι] {s : Finset ι} (P : Finpartition s)
    (f : ι → ℝ) : ∑ A ∈ P.parts, ∑ i ∈ A, f i = ∑ i ∈ s, f i := by
  have h := (Finset.sum_biUnion (s := P.parts) (t := id) (f := f) P.disjoint)
  rw [P.biUnion_parts] at h
  simpa using h.symm

#print axioms posPart_sum_le_sum_posPart
#print axioms sum_parts_sum_eq

/-- Netting never raises exposure: if every netting set of one arrangement lies inside a single
netting set of another (the second nets more), then the exposure under the second arrangement
is at most the exposure under the first. -/
theorem netting_never_raises_exposure {ι : Type*} [Fintype ι] [DecidableEq ι] (V : ι → ℝ)
    (fine coarse : Finpartition (univ : Finset ι)) (h : fine ≤ coarse) :
    ∑ A ∈ coarse.parts, (∑ i ∈ A, V i)⁺ ≤ ∑ A ∈ fine.parts, (∑ i ∈ A, V i)⁺ := by
  classical
  have hsplit : ∀ B ∈ coarse.parts,
      ∑ i ∈ B, V i = ∑ A ∈ fine.parts.filter (· ⊆ B), ∑ i ∈ A, V i := by
    intro B hB
    have hd : ((fine.parts.filter (· ⊆ B) : Finset (Finset ι)) : Set (Finset ι)).PairwiseDisjoint
        id := fine.disjoint.subset (Finset.coe_subset.2 (filter_subset _ _))
    have hb := Finset.sum_biUnion (t := id) (f := V) hd
    simp only [id] at hb
    rw [← hb]
    congr 1
    ext i
    simp only [mem_biUnion, mem_filter, id]
    constructor
    · intro hi
      obtain ⟨A, hA, hiA⟩ := fine.exists_mem (mem_univ i)
      obtain ⟨B', hB', hAB'⟩ := h hA
      have : B' = B := coarse.eq_of_mem_parts hB' hB (hAB' hiA) hi
      subst this
      exact ⟨A, ⟨hA, hAB'⟩, hiA⟩
    · rintro ⟨A, ⟨_, hAB⟩, hiA⟩
      exact hAB hiA
  calc ∑ B ∈ coarse.parts, (∑ i ∈ B, V i)⁺
      = ∑ B ∈ coarse.parts, (∑ A ∈ fine.parts.filter (· ⊆ B), ∑ i ∈ A, V i)⁺ :=
        sum_congr rfl fun B hB => by rw [hsplit B hB]
    _ ≤ ∑ B ∈ coarse.parts, ∑ A ∈ fine.parts.filter (· ⊆ B), (∑ i ∈ A, V i)⁺ :=
        sum_le_sum fun B _ => posPart_sum_le_sum_posPart _ _
    _ = ∑ A ∈ fine.parts, ∑ B ∈ coarse.parts.filter (A ⊆ ·), (∑ i ∈ A, V i)⁺ := by
        refine Finset.sum_comm' ?_
        intro B A
        simp only [mem_filter]
        tauto
    _ = ∑ A ∈ fine.parts, (∑ i ∈ A, V i)⁺ := by
        refine sum_congr rfl fun A hA => ?_
        obtain ⟨B0, hB0, hAB0⟩ := h hA
        rw [Finset.sum_eq_single_of_mem B0 (mem_filter.2 ⟨hB0, hAB0⟩)]
        intro B hB hne
        exfalso
        obtain ⟨a, ha⟩ := fine.nonempty_of_mem_parts hA
        rw [mem_filter] at hB
        exact hne (coarse.eq_of_mem_parts hB.1 hB0 (hB.2 ha) (hAB0 ha))

/-- Every arrangement of netting sets lies between the two extremes: the net exposure
(one agreement over all trades, add then floor) is at most the exposure `E`, and `E` is at most
the gross exposure `G` (no agreement, floor each trade then add). -/
theorem exposure_between_net_and_gross {ι : Type*} [Fintype ι] [DecidableEq ι] (V : ι → ℝ)
    (S : Finpartition (univ : Finset ι)) :
    (∑ i, V i)⁺ ≤ ∑ A ∈ S.parts, (∑ i ∈ A, V i)⁺ ∧
      ∑ A ∈ S.parts, (∑ i ∈ A, V i)⁺ ≤ ∑ i, (V i)⁺ := by
  refine ⟨?_, ?_⟩
  · rw [← sum_parts_sum_eq S V]
    exact posPart_sum_le_sum_posPart _ _
  · rw [← sum_parts_sum_eq S (fun i => (V i)⁺)]
    exact sum_le_sum fun A _ => posPart_sum_le_sum_posPart _ _

/-- Inside one netting set, the saving from netting is exactly the smaller side:
gross minus net exposure equals `min P Q`, where `P` is the total the bank is owed trade by trade
and `Q` the total it owes trade by trade. -/
theorem netting_saving_eq_min {ι : Type*} (s : Finset ι) (V : ι → ℝ) :
    ∑ i ∈ s, (V i)⁺ - (∑ i ∈ s, V i)⁺ = min (∑ i ∈ s, (V i)⁺) (∑ i ∈ s, (V i)⁻) := by
  have hP : ∀ i ∈ s, (V i)⁺ - (V i)⁻ = V i := fun i _ => posPart_sub_negPart (V i)
  have hsum : ∑ i ∈ s, V i = ∑ i ∈ s, (V i)⁺ - ∑ i ∈ s, (V i)⁻ := by
    rw [← sum_sub_distrib]
    exact (sum_congr rfl hP).symm
  rw [hsum, posPart_def]
  rcases le_total (∑ i ∈ s, (V i)⁺) (∑ i ∈ s, (V i)⁻) with hle | hle
  · rw [min_eq_left hle, max_eq_right (sub_nonpos.2 hle), sub_zero]
  · rw [min_eq_right hle, max_eq_left (sub_nonneg.2 hle), sub_sub_cancel]

/-! The card's Northwind book: trades +5, -3, +2 ($ million). -/

-- gross exposure, every trade floored on its own: 5 + 0 + 2 = 7
example : ∑ i : Fin 3, (![(5 : ℤ), -3, 2] i)⁺ = 7 := by decide
-- net exposure, one master agreement: (5 - 3 + 2)⁺ = 4
example : (∑ i : Fin 3, ![(5 : ℤ), -3, 2] i)⁺ = 4 := by decide
-- P, owed to the bank trade by trade: 7; Q, owed by the bank trade by trade: 3
example : ∑ i : Fin 3, (![(5 : ℤ), -3, 2] i)⁻ = 3 := by decide
-- saving from netting: 7 - 4 = min 7 3 = 3
example : ∑ i : Fin 3, (![(5 : ℤ), -3, 2] i)⁺ - (∑ i : Fin 3, ![(5 : ℤ), -3, 2] i)⁺
    = min (∑ i : Fin 3, (![(5 : ℤ), -3, 2] i)⁺) (∑ i : Fin 3, (![(5 : ℤ), -3, 2] i)⁻) := by
  decide
-- trade 2 under a separate agreement: sets {1, 3} and {2}: 7 + 0 = 7
example : ((5 : ℤ) + 2)⁺ + (-3 : ℤ)⁺ = 7 := by decide
-- the +2 trade apart instead: sets {1, 2} and {3}: 2 + 2 = 4
example : ((5 : ℤ) + -3)⁺ + (2 : ℤ)⁺ = 4 := by decide
-- the +5 trade apart instead: sets {2, 3} and {1}: 0 + 5 = 5
example : ((-3 : ℤ) + 2)⁺ + (5 : ℤ)⁺ = 5 := by decide
-- chart: trade 2 at -9, one agreement: (5 - 9 + 2)⁺ = 0, gross stays 7
example : ((5 : ℤ) + -9 + 2)⁺ = 0 ∧ (5 : ℤ)⁺ + (-9 : ℤ)⁺ + (2 : ℤ)⁺ = 7 := by decide

#print axioms netting_never_raises_exposure
#print axioms exposure_between_net_and_gross
#print axioms netting_saving_eq_min
