-- Inclusion-exclusion for any number of sets: for finite sets A₁, …, Aₙ the size of their union is S₁ − S₂ + S₃ − ⋯ ± Sₙ, where Sⱼ adds the sizes of all j-at-a-time overlaps, because a member of k ≥ 1 sets is counted C(k, 1) − C(k, 2) + ⋯ = 1 time.
import Mathlib.Data.Set.Card
import Mathlib.Data.Finset.Powerset
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Order.Ring.Int
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Tactic.NormNum

import Mathlib.Combinatorics.Enumerative.InclusionExclusion
import Mathlib.Data.Nat.Choose.Sum

open Finset

/-- The intersection of the sets indexed by a nonempty `t`, as a `Finset` infimum. -/
lemma ie_helper_inter_ncard {α : Type*} [DecidableEq α] {n : ℕ} (A : Fin n → Set α) (hA : ∀ i, (A i).Finite)
    (t : Finset (Fin n)) (ht : t.Nonempty) :
    ((t.inf' ht (fun i => (hA i).toFinset)).card : ℤ) = ((⋂ i ∈ t, A i).ncard : ℤ) := by
  rw [← Set.ncard_coe_finset]
  congr 2
  ext x
  simp [Finset.mem_inf']


/-- **Inclusion-exclusion for `n` sets.** For finite sets `A₁, …, Aₙ`, let layer `Sⱼ` add up the
sizes `|A_{i₁} ∩ ⋯ ∩ A_{iⱼ}|` over every choice of `j` of the sets. Then the number of members in at
least one set is `|A₁ ∪ ⋯ ∪ Aₙ| = S₁ − S₂ + S₃ − ⋯ + (−1)^(n+1) Sₙ`: add the sets, subtract every
pair, add every triple, flipping the sign down to the last overlap. -/
theorem card_union_eq_alternating_sum_of_layers {α : Type*} (n : ℕ) (A : Fin n → Set α)
    (hA : ∀ i, (A i).Finite) :
    ((⋃ i, A i).ncard : ℤ) =
      ∑ j ∈ Icc 1 n, (-1 : ℤ) ^ (j + 1) *
        ∑ t ∈ (univ : Finset (Fin n)).powersetCard j, ((⋂ i ∈ t, A i).ncard : ℤ) := by
  classical
  have hU : (⋃ i, A i) = ((univ : Finset (Fin n)).biUnion (fun i => (hA i).toFinset) : Set α) := by
    ext x; simp
  rw [hU, Set.ncard_coe_finset, inclusion_exclusion_card_biUnion]
  rw [Fintype.sum_congr _ (fun t => (-1 : ℤ) ^ (t.1.card + 1) * ((⋂ i ∈ t.1, A i).ncard : ℤ))
    (fun t => by rw [ie_helper_inter_ncard])]
  rw [Finset.sum_coe_sort ((univ : Finset (Fin n)).powerset.filter (·.Nonempty))
    (fun t => (-1 : ℤ) ^ (t.card + 1) * ((⋂ i ∈ t, A i).ncard : ℤ))]
  rw [← Finset.sum_fiberwise_of_maps_to (g := Finset.card) (t := Icc 1 n)]
  · apply Finset.sum_congr rfl
    intro j hj
    rw [Finset.mul_sum]
    have hj1 : 1 ≤ j := (Finset.mem_Icc.1 hj).1
    have hs : ((univ : Finset (Fin n)).powerset.filter (·.Nonempty)).filter (fun t => t.card = j)
        = (univ : Finset (Fin n)).powersetCard j := by
      ext t
      simp only [Finset.mem_filter, Finset.mem_powerset, Finset.mem_powersetCard]
      constructor
      · rintro ⟨⟨h1, _⟩, h3⟩; exact ⟨h1, h3⟩
      · rintro ⟨h1, h3⟩
        refine ⟨⟨h1, ?_⟩, h3⟩
        rw [← Finset.card_pos]; omega
    rw [hs]
    apply Finset.sum_congr rfl
    intro t ht
    rw [(Finset.mem_powersetCard.1 ht).2]
  · intro t ht
    simp only [Finset.mem_filter, Finset.mem_powerset] at ht
    rw [Finset.mem_Icc]
    refine ⟨Finset.card_pos.2 ht.2, ?_⟩
    simpa using Finset.card_le_card ht.1

/-- **One member's count.** A member that lies in exactly `k` of the sets, with `k` at least 1, is
counted `C(k, 1) − C(k, 2) + C(k, 3) − ⋯ + (−1)^(k+1) C(k, k)` times by the layers, and that
alternating sum is always exactly 1. -/
theorem alternating_sum_choose_eq_one (k : ℕ) (hk : 1 ≤ k) :
    ∑ j ∈ Icc 1 k, (-1 : ℤ) ^ (j + 1) * (k.choose j : ℤ) = 1 := by
  have h := Int.alternating_sum_range_choose (n := k)
  rw [ite_eq_right_iff.2 (fun h0 => absurd h0 (by omega))] at h
  have hr : range (k + 1) = insert 0 (Icc 1 k) := by
    ext x; simp; omega
  rw [hr, Finset.sum_insert (by simp)] at h
  have h2 : ∑ j ∈ Icc 1 k, (-1 : ℤ) ^ (j + 1) * (k.choose j : ℤ)
      = - ∑ j ∈ Icc 1 k, (-1 : ℤ) ^ j * (k.choose j : ℤ) := by
    rw [← Finset.sum_neg_distrib]
    apply Finset.sum_congr rfl
    intro j _
    ring
  rw [h2]
  simp at h
  linarith

/-- **The sieve: members in none of the sets.** Inside a finite pool `P` holding the sets
`A₁, …, Aₙ`, the members in none of them number `|P| − S₁ + S₂ − S₃ + ⋯ + (−1)ⁿ Sₙ`, the pool
minus the union. -/
theorem card_pool_diff_union_eq_sieve {α : Type*} (n : ℕ) (P : Set α) (hP : P.Finite)
    (A : Fin n → Set α) (hAP : ∀ i, A i ⊆ P) :
    ((P \ ⋃ i, A i).ncard : ℤ) =
      (P.ncard : ℤ) + ∑ j ∈ Icc 1 n, (-1 : ℤ) ^ j *
        ∑ t ∈ (univ : Finset (Fin n)).powersetCard j, ((⋂ i ∈ t, A i).ncard : ℤ) := by
  have hU : (⋃ i, A i) ⊆ P := Set.iUnion_subset hAP
  have hA : ∀ i, (A i).Finite := fun i => hP.subset (hAP i)
  have hUf : (⋃ i, A i).Finite := hP.subset hU
  have h1 := card_union_eq_alternating_sum_of_layers n A hA
  have h2 : (P \ ⋃ i, A i).ncard + (⋃ i, A i).ncard = P.ncard := by
    rw [← Set.ncard_union_eq Set.disjoint_sdiff_left (hP.sdiff) hUf, Set.sdiff_union_of_subset hU]
  have h3 : ∑ j ∈ Icc 1 n, (-1 : ℤ) ^ j *
        ∑ t ∈ (univ : Finset (Fin n)).powersetCard j, ((⋂ i ∈ t, A i).ncard : ℤ)
      = - ∑ j ∈ Icc 1 n, (-1 : ℤ) ^ (j + 1) *
        ∑ t ∈ (univ : Finset (Fin n)).powersetCard j, ((⋂ i ∈ t, A i).ncard : ℤ) := by
    rw [← Finset.sum_neg_distrib]
    apply Finset.sum_congr rfl
    intro j _
    ring
  rw [h3, ← h1]
  have h2' : ((P \ ⋃ i, A i).ncard : ℤ) + ((⋃ i, A i).ncard : ℤ) = (P.ncard : ℤ) := by
    exact_mod_cast h2
  linarith

-- The hotel: layers 50 + 40 + 30 = 120, 20 + 15 + 10 = 45, and 5; union 120 − 45 + 5 = 80; none 20.
example : (50 + 40 + 30 : ℤ) = 120 ∧ (20 + 15 + 10 : ℤ) = 45 ∧ (120 - 45 + 5 : ℤ) = 80 ∧
    (100 - 80 : ℤ) = 20 := by norm_num

-- The three mistakes: stop after adding 120, stop after the pairs 75, subtract the triple 70.
example : (120 - 45 : ℤ) = 75 ∧ (120 - 45 - 5 : ℤ) = 70 := by norm_num

-- One member's count off Pascal's triangle: 1; 2 − 1; 3 − 3 + 1; 4 − 6 + 4 − 1 all equal 1.
example : (1 : ℤ) = 1 ∧ (2 - 1 : ℤ) = 1 ∧ (3 - 3 + 1 : ℤ) = 1 ∧ (4 - 6 + 4 - 1 : ℤ) = 1 := by
  norm_num

-- Overlaps holding the breakfast-and-parking guest: C(2, 1) = 2 in layer 1, C(2, 2) = 1 in layer 2.
example : Nat.choose 2 1 = 2 ∧ Nat.choose 2 2 = 1 := by decide

-- Layers hold C(n, j) counts, 2ⁿ − 1 in all: 7 for three sets, 15 for four, 31 for five.
example : Nat.choose 3 1 + Nat.choose 3 2 + Nat.choose 3 3 = 7 ∧ 2 ^ 4 - 1 = 15 ∧
    2 ^ 5 - 1 = 31 := by decide

-- Sieve 1 to 1000 by 2, 3, 5, 7: layers 1175, 478, 79, 4; union 772; none 228.
example : 1000 / 2 + 1000 / 3 + 1000 / 5 + 1000 / 7 = 1175 ∧
    1000 / 6 + 1000 / 10 + 1000 / 14 + 1000 / 15 + 1000 / 21 + 1000 / 35 = 478 ∧
    1000 / 30 + 1000 / 42 + 1000 / 70 + 1000 / 105 = 79 ∧ 1000 / 210 = 4 ∧
    (1175 - 478 + 79 - 4 : ℤ) = 772 ∧ (1000 - 772 : ℤ) = 228 := by norm_num

-- The same 228, by testing every number from 1 to 1000.
example : ((Icc 1 1000).filter (fun x => ¬ 2 ∣ x ∧ ¬ 3 ∣ x ∧ ¬ 5 ∣ x ∧ ¬ 7 ∣ x)).card = 228 := by
  decide +kernel

-- Sieve 1 to 1000 by 2, 3, 5: layers 1033, 332, 33; union 734; none 266 = 33 × 8 + 2.
example : 1000 / 2 + 1000 / 3 + 1000 / 5 = 1033 ∧ 1000 / 6 + 1000 / 10 + 1000 / 15 = 332 ∧
    1000 / 30 = 33 ∧ (1033 - 332 + 33 : ℤ) = 734 ∧ (1000 - 734 : ℤ) = 266 ∧
    33 * 8 + 2 = 266 := by norm_num

-- Euler's totient by the sieve: 8 of 1 to 30 dodge 2, 3 and 5.
example : ((Icc 1 30).filter (fun x => ¬ 2 ∣ x ∧ ¬ 3 ∣ x ∧ ¬ 5 ∣ x)).card = 8 := by decide

#print axioms ie_helper_inter_ncard
#print axioms card_union_eq_alternating_sum_of_layers
#print axioms alternating_sum_choose_eq_one
#print axioms card_pool_diff_union_eq_sieve
