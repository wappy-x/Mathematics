-- Integer partitions: for every n and every cap k, the partitions of n with at most k parts are exactly as many as those with every part at most k, because turning the dot diagram swaps the part count with the biggest part and undoes itself.
import Mathlib.Combinatorics.Enumerative.Partition.YoungDiagram
import Mathlib.Tactic.NormNum.Basic

theorem ip_helper_rowLens_sup (μ : YoungDiagram) :
    (μ.rowLens : Multiset ℕ).sup = μ.rowLen 0 := by
  apply le_antisymm
  · apply Multiset.sup_le.mpr
    intro b hb
    rw [Multiset.mem_coe, YoungDiagram.rowLens, List.mem_map] at hb
    obtain ⟨i, -, rfl⟩ := hb
    exact μ.rowLen_anti 0 i (Nat.zero_le i)
  · rcases Nat.eq_zero_or_pos (μ.rowLen 0) with h | h
    · rw [h]; exact Nat.zero_le _
    · apply Multiset.le_sup
      rw [Multiset.mem_coe, YoungDiagram.rowLens, List.mem_map]
      refine ⟨0, ?_, rfl⟩
      rw [List.mem_range, ← YoungDiagram.mem_iff_lt_colLen, YoungDiagram.mem_iff_lt_rowLen]
      exact h

theorem ip_helper_card_conjugate {n : ℕ} (p : Nat.Partition n) :
    Multiset.card p.conjugate.parts = p.parts.sup := by
  have h1 : p.parts = ((YoungDiagram.ofPartition p).rowLens : Multiset ℕ) := by
    rw [YoungDiagram.rowLens_ofPartition_eq_sort_parts, Multiset.sort_eq]
  have h2 : p.conjugate.parts = ((YoungDiagram.ofPartition p).transpose.rowLens : Multiset ℕ) :=
    rfl
  rw [h2, h1, ip_helper_rowLens_sup, Multiset.coe_card, YoungDiagram.length_rowLens,
    YoungDiagram.colLen_transpose]

theorem ip_helper_sup_conjugate {n : ℕ} (p : Nat.Partition n) :
    p.conjugate.parts.sup = Multiset.card p.parts := by
  have := ip_helper_card_conjugate p.conjugate
  rw [Nat.Partition.conjugate_conjugate] at this
  exact this.symm

/-- Add one part `a` to a partition of `n`, giving a partition of `n + a`. -/
def ip_helper_cons {n : ℕ} (a : ℕ) (ha : 0 < a) (q : Nat.Partition n) : Nat.Partition (n + a) where
  parts := a ::ₘ q.parts
  parts_pos := by
    intro i hi
    rcases Multiset.mem_cons.mp hi with rfl | hi
    · exact ha
    · exact q.parts_pos hi
  parts_sum := by rw [Multiset.sum_cons, q.parts_sum, Nat.add_comm]

theorem ip_helper_parts_at_most_recurrence (n k : ℕ) :
    (Finset.univ.filter (fun p : Nat.Partition (n + (k + 1)) => ∀ i ∈ p.parts, i ≤ k + 1)).card =
      (Finset.univ.filter (fun p : Nat.Partition n => ∀ i ∈ p.parts, i ≤ k + 1)).card +
        (Finset.univ.filter (fun p : Nat.Partition (n + (k + 1)) => ∀ i ∈ p.parts, i ≤ k)).card := by
  rw [← Finset.card_filter_add_card_filter_not
    (fun p : Nat.Partition (n + (k + 1)) => k + 1 ∈ p.parts)]
  congr 1
  · symm
    apply Finset.card_bij (fun q _ => ip_helper_cons (k + 1) (Nat.succ_pos k) q)
    · intro q hq
      simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hq ⊢
      refine ⟨?_, Multiset.mem_cons_self _ _⟩
      intro i hi
      rcases Multiset.mem_cons.mp hi with rfl | hi
      · exact le_rfl
      · exact hq i hi
    · intro q₁ _ q₂ _ h
      have := congrArg Nat.Partition.parts h
      exact Nat.Partition.ext ((Multiset.cons_inj_right _).mp this)
    · intro p hp
      simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hp
      obtain ⟨hle, hmem⟩ := hp
      refine ⟨⟨p.parts.erase (k + 1), fun hi => p.parts_pos (Multiset.mem_of_mem_erase hi), ?_⟩,
        ?_, ?_⟩
      · have := Multiset.sum_erase hmem
        rw [p.parts_sum] at this
        omega
      · simp only [Finset.mem_filter, Finset.mem_univ, true_and]
        intro i hi
        exact hle i (Multiset.mem_of_mem_erase hi)
      · apply Nat.Partition.ext
        exact Multiset.cons_erase hmem
  · congr 1
    ext p
    simp only [Finset.mem_filter, Finset.mem_univ, true_and]
    constructor
    · rintro ⟨h1, h2⟩ i hi
      have := h1 i hi
      rcases Nat.lt_or_ge i (k + 1) with h | h
      · omega
      · have : i = k + 1 := by omega
        subst this; exact absurd hi h2
    · intro h
      refine ⟨fun i hi => (h i hi).trans (Nat.le_succ k), fun hi => ?_⟩
      have := h _ hi; omega

#print axioms ip_helper_rowLens_sup
#print axioms ip_helper_card_conjugate
#print axioms ip_helper_sup_conjugate
#print axioms ip_helper_cons
#print axioms ip_helper_parts_at_most_recurrence

/-- Few parts or small parts, the same count. For every whole number n and every cap k, the
partitions of n with at most k parts are exactly as many as the partitions of n whose every
part is at most k: R_k(n) = C_k(n). -/
theorem card_at_most_k_parts_eq_card_parts_at_most_k (n k : ℕ) :
    (Finset.univ.filter (fun p : Nat.Partition n => Multiset.card p.parts ≤ k)).card =
      (Finset.univ.filter (fun p : Nat.Partition n => ∀ i ∈ p.parts, i ≤ k)).card := by
  apply Finset.card_nbij' Nat.Partition.conjugate Nat.Partition.conjugate
  · intro p hp
    simp only [Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq] at hp ⊢
    intro i hi
    exact (Multiset.le_sup hi).trans ((ip_helper_sup_conjugate p) ▸ hp)
  · intro p hp
    simp only [Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq] at hp ⊢
    rw [ip_helper_card_conjugate]
    exact Multiset.sup_le.mpr hp
  · intro p _; exact Nat.Partition.conjugate_conjugate p
  · intro p _; exact Nat.Partition.conjugate_conjugate p

/-- The turn. Reading a partition's dot diagram down its columns (its conjugate) gives a
partition of the same number; turning twice gives back the original; and the turn trades the
number of parts with the biggest part (both read as 0 for the empty partition of 0). -/
theorem conjugate_swaps_part_count_and_biggest_part (n : ℕ)
    (p : Nat.Partition n) :
    p.conjugate.conjugate = p ∧
      Multiset.card p.conjugate.parts = p.parts.sup ∧
      p.conjugate.parts.sup = Multiset.card p.parts := by
  exact ⟨Nat.Partition.conjugate_conjugate p, ip_helper_card_conjugate p,
    ip_helper_sup_conjugate p⟩

/-- The capped count without listing. Zero has one partition into at most k parts (the empty
sum); a positive number has none into at most 0 parts; and for a cap k of at least one and n of
at least k, R_k(n) = R_k(n - k) + R_{k-1}(n): either exactly k parts, and one unit comes off
each, or fewer than k parts. -/
theorem at_most_k_parts_recurrence (n k : ℕ) :
    (Finset.univ.filter (fun p : Nat.Partition 0 => Multiset.card p.parts ≤ k)).card = 1 ∧
      (Finset.univ.filter (fun p : Nat.Partition (n + 1) => Multiset.card p.parts ≤ 0)).card = 0 ∧
      (Finset.univ.filter
          (fun p : Nat.Partition (n + (k + 1)) => Multiset.card p.parts ≤ k + 1)).card =
        (Finset.univ.filter (fun p : Nat.Partition n => Multiset.card p.parts ≤ k + 1)).card +
          (Finset.univ.filter
            (fun p : Nat.Partition (n + (k + 1)) => Multiset.card p.parts ≤ k)).card := by
  refine ⟨?_, ?_, ?_⟩
  · rw [Finset.card_eq_one]
    refine ⟨⟨0, by simp, by simp⟩, ?_⟩
    ext p
    simp only [Finset.mem_filter, Finset.mem_univ, true_and, Finset.mem_singleton]
    have hp : p.parts = 0 := by
      have h := p.parts_sum
      rw [Multiset.sum_eq_zero_iff] at h
      exact Multiset.eq_zero_of_forall_notMem fun i hi => by
        have := p.parts_pos hi; have := h i hi; omega
    constructor
    · intro _; exact Nat.Partition.ext hp
    · intro _; rw [hp]; simp
  · rw [Finset.card_eq_zero, Finset.filter_eq_empty_iff]
    intro p _ h
    have h0 : p.parts = 0 := Multiset.card_eq_zero.mp (Nat.le_zero.mp h)
    have := p.parts_sum
    rw [h0, Multiset.sum_zero] at this
    omega
  · rw [card_at_most_k_parts_eq_card_parts_at_most_k, card_at_most_k_parts_eq_card_parts_at_most_k,
      card_at_most_k_parts_eq_card_parts_at_most_k]
    exact ip_helper_parts_at_most_recurrence n k

-- The card's worked numbers for a bar of 8 beats.
-- Splits by note count, 1 to 8 notes, add to 22; so do splits by biggest note.
example : 1 + 4 + 5 + 5 + 3 + 2 + 1 + 1 = 22 := by norm_num
-- At most three notes: a ≥ b ≥ c ≥ 0 with a + b + c = 8 (a 0 means an unused note): 10 splits.
example : ((Finset.range 9 ×ˢ Finset.range 9 ×ˢ Finset.range 9).filter
    (fun t => t.2.2 ≤ t.2.1 ∧ t.2.1 ≤ t.1 ∧ t.1 + t.2.1 + t.2.2 = 8)).card = 10 := by decide
-- No note over three beats: x ones, y twos and z threes with x + 2y + 3z = 8: also 10 splits.
example : ((Finset.range 9 ×ˢ Finset.range 9 ×ˢ Finset.range 9).filter
    (fun t => t.1 + 2 * t.2.1 + 3 * t.2.2 = 8)).card = 10 := by decide
-- Exactly three notes: 5 splits, half of the 10 ("at most" read as "exactly").
example : ((Finset.range 9 ×ˢ Finset.range 9 ×ˢ Finset.range 9).filter
    (fun t => 1 ≤ t.2.2 ∧ t.2.2 ≤ t.2.1 ∧ t.2.1 ≤ t.1 ∧ t.1 + t.2.1 + t.2.2 = 8)).card = 5 := by
  decide
-- The recurrence: R_3(8) = R_3(5) + R_2(8) = 5 + 5 = 10.
example : ((Finset.range 6 ×ˢ Finset.range 6 ×ˢ Finset.range 6).filter
    (fun t => t.2.2 ≤ t.2.1 ∧ t.2.1 ≤ t.1 ∧ t.1 + t.2.1 + t.2.2 = 5)).card = 5 := by decide
example : ((Finset.range 9 ×ˢ Finset.range 9).filter
    (fun t => t.2 ≤ t.1 ∧ t.1 + t.2 = 8)).card = 5 := by decide
example : 5 + 5 = 10 := by norm_num
-- Mismatched caps: parts of at most four beats give 15 splits, not 10.
example : ((Finset.range 9 ×ˢ Finset.range 5 ×ˢ Finset.range 3 ×ˢ Finset.range 3).filter
    (fun t => t.1 + 2 * t.2.1 + 3 * t.2.2.1 + 4 * t.2.2.2 = 8)).card = 15 := by decide
-- The turn of 6+1+1: column heights 3, 1, 1, 1, 1, 1; turning again gives 6, 1, 1.
example : (List.range 6).map (fun j => ([6, 1, 1].filter (fun a => j + 1 ≤ a)).length)
    = [3, 1, 1, 1, 1, 1] := by decide
example : (List.range 3).map (fun j => ([3, 1, 1, 1, 1, 1].filter (fun a => j + 1 ≤ a)).length)
    = [6, 1, 1] := by decide
-- Stars and bars for three named notes: 21 ordered triples of at least 1 adding to 8, not 5.
example : ((Finset.range 9 ×ˢ Finset.range 9 ×ˢ Finset.range 9).filter
    (fun t => 1 ≤ t.1 ∧ 1 ≤ t.2.1 ∧ 1 ≤ t.2.2 ∧ t.1 + t.2.1 + t.2.2 = 8)).card = 21 := by decide
-- Rhythms with order kept: 2 ^ 7 = 128 for eight beats, not 22.
example : 2 ^ (8 - 1) = 128 := by norm_num

#print axioms card_at_most_k_parts_eq_card_parts_at_most_k
#print axioms conjugate_swaps_part_count_and_biggest_part
#print axioms at_most_k_parts_recurrence
