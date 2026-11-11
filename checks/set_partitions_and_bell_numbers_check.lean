-- Set partitions and Bell numbers: the number B(n) of ways to split n named people into unnamed non-empty groups satisfies B(0) = 1 and B(n + 1) = C(n,0) B(0) + ... + C(n,n) B(n), equals Mathlib's Bell number for any finite set, and the card's counts 15, 52, ..., 4140 come out as it says.
import Mathlib.Order.Partition.Finpartition
import Mathlib.Combinatorics.Enumerative.Bell

section BellHelpers

open Finset

/-- The finsets of blocks that split `s`: every block inside `s`, every member of `s` in some
block, two blocks sharing a member are equal, and no block is empty. -/
noncomputable def splitBlocks {α : Type*} [DecidableEq α] (s : Finset α) : Finset (Finset (Finset α)) := by
  classical
  exact s.powerset.powerset.filter fun F =>
    (∀ x ∈ s, ∃ p ∈ F, x ∈ p) ∧ (∀ p ∈ F, ∀ q ∈ F, ∀ x, x ∈ p → x ∈ q → p = q) ∧ ∅ ∉ F

theorem mem_splitBlocks {α : Type*} [DecidableEq α] (s : Finset α) (F : Finset (Finset α)) :
    F ∈ splitBlocks s ↔ (∀ p ∈ F, p ⊆ s) ∧ (∀ x ∈ s, ∃ p ∈ F, x ∈ p) ∧
      (∀ p ∈ F, ∀ q ∈ F, ∀ x, x ∈ p → x ∈ q → p = q) ∧ ∅ ∉ F := by
  classical
  unfold splitBlocks
  simp only [mem_filter, mem_powerset]
  constructor
  · rintro ⟨h1, h2⟩
    exact ⟨fun p hp => mem_powerset.mp (h1 hp), h2⟩
  · rintro ⟨h1, h2⟩
    exact ⟨fun p hp => mem_powerset.mpr (h1 p hp), h2⟩

/-- A finpartition is the same thing as its set of blocks. -/
noncomputable def finpartitionEquivSplitBlocks {α : Type*} [DecidableEq α] (s : Finset α) :
    Finpartition s ≃ {F // F ∈ splitBlocks s} where
  toFun P := ⟨P.parts, (mem_splitBlocks s _).mpr
    ⟨fun _ hp => P.subset hp, fun _ hx => P.exists_mem hx,
     fun _ hp _ hq _ hxp hxq => P.eq_of_mem_parts hp hq hxp hxq, P.empty_notMem_parts⟩⟩
  invFun F := by
    have h := (mem_splitBlocks s F.1).mp F.2
    exact Finpartition.ofExistsUnique F.1 h.1
      (fun x hx => by
        obtain ⟨p, hp, hxp⟩ := h.2.1 x hx
        exact ⟨p, ⟨hp, hxp⟩, fun q hq => h.2.2.1 q hq.1 p hp x hq.2 hxp⟩) h.2.2.2
  left_inv P := by ext1; rfl
  right_inv F := Subtype.ext rfl

theorem card_finpartition_eq_card_splitBlocks {α : Type*} [DecidableEq α] (s : Finset α) :
    Fintype.card (Finpartition s) = #(splitBlocks s) := by
  rw [Fintype.card_congr (finpartitionEquivSplitBlocks s), Fintype.card_coe]

theorem splitBlocks_empty {α : Type*} [DecidableEq α] :
    splitBlocks (∅ : Finset α) = {∅} := by
  ext F
  rw [mem_splitBlocks, mem_singleton]
  constructor
  · rintro ⟨h1, -, -, h4⟩
    rw [Finset.eq_empty_iff_forall_notMem]
    intro p hp
    have := h1 p hp
    rw [Finset.subset_empty] at this
    exact h4 (this ▸ hp)
  · rintro rfl
    simp

/-- Blocks of `insert a s` whose block holding `a` is `insert a t`, versus blocks of `s \ t`. -/
theorem card_splitBlocks_fiber {α : Type*} [DecidableEq α] {a : α} {s t : Finset α}
    (ha : a ∉ s) (ht : t ⊆ s) :
    #((splitBlocks (insert a s)).filter (insert a t ∈ ·)) = #(splitBlocks (s \ t)) := by
  refine Finset.card_nbij' (fun F => F.erase (insert a t)) (fun G => insert (insert a t) G)
    ?_ ?_ ?_ ?_
  · intro F hF
    simp only [coe_filter, Set.mem_ofPred_eq] at hF
    obtain ⟨hF, hat⟩ := hF
    rw [mem_splitBlocks] at hF
    obtain ⟨h1, h2, h3, h4⟩ := hF
    rw [mem_coe, mem_splitBlocks]
    refine ⟨?_, ?_, ?_, ?_⟩
    · intro p hp x hx
      rw [mem_erase] at hp
      have hxs := h1 p hp.2 hx
      rw [mem_insert] at hxs
      rw [mem_sdiff]
      rcases hxs with rfl | hxs
      · exact absurd (h3 p hp.2 _ hat x hx (mem_insert_self _ _)) hp.1
      · refine ⟨hxs, fun hxt => hp.1 (h3 p hp.2 _ hat x hx (mem_insert_of_mem hxt))⟩
    · intro x hx
      rw [mem_sdiff] at hx
      obtain ⟨p, hp, hxp⟩ := h2 x (mem_insert_of_mem hx.1)
      refine ⟨p, mem_erase.mpr ⟨?_, hp⟩, hxp⟩
      rintro rfl
      rw [mem_insert] at hxp
      rcases hxp with rfl | hxp
      · exact ha hx.1
      · exact hx.2 hxp
    · intro p hp q hq x hxp hxq
      exact h3 p (mem_of_mem_erase hp) q (mem_of_mem_erase hq) x hxp hxq
    · intro h
      exact h4 (mem_of_mem_erase h)
  · intro G hG
    rw [mem_coe, mem_splitBlocks] at hG
    obtain ⟨h1, h2, h3, h4⟩ := hG
    have key : ∀ p ∈ G, ∀ x, x ∈ p → x ∉ insert a t := by
      intro p hp x hxp hx
      have := h1 p hp hxp
      rw [mem_sdiff] at this
      rw [mem_insert] at hx
      rcases hx with rfl | hx
      · exact ha this.1
      · exact this.2 hx
    simp only [coe_filter, Set.mem_ofPred_eq]
    refine ⟨?_, mem_insert_self _ _⟩
    rw [mem_splitBlocks]
    refine ⟨?_, ?_, ?_, ?_⟩
    · intro p hp
      rw [mem_insert] at hp
      rcases hp with rfl | hp
      · exact insert_subset_insert _ ht
      · intro x hx
        exact mem_insert_of_mem (mem_sdiff.mp (h1 p hp hx)).1
    · intro x hx
      by_cases hxt : x ∈ insert a t
      · exact ⟨_, mem_insert_self _ _, hxt⟩
      · rw [mem_insert] at hx
        rcases hx with rfl | hx
        · exact absurd (mem_insert_self _ _) hxt
        · have : x ∈ s \ t := mem_sdiff.mpr ⟨hx, fun h => hxt (mem_insert_of_mem h)⟩
          obtain ⟨p, hp, hxp⟩ := h2 x this
          exact ⟨p, mem_insert_of_mem hp, hxp⟩
    · intro p hp q hq x hxp hxq
      rw [mem_insert] at hp hq
      rcases hp with rfl | hp <;> rcases hq with rfl | hq
      · rfl
      · exact absurd hxp (key q hq x hxq)
      · exact absurd hxq (key p hp x hxp)
      · exact h3 p hp q hq x hxp hxq
    · intro h
      rw [mem_insert] at h
      rcases h with h | h
      · exact absurd h.symm (insert_ne_empty _ _)
      · exact h4 h
  · intro F hF
    simp only [coe_filter, Set.mem_ofPred_eq] at hF
    exact insert_erase hF.2
  · intro G hG
    rw [mem_coe, mem_splitBlocks] at hG
    apply erase_insert
    intro h
    have := hG.1 _ h (mem_insert_self a t)
    exact ha (mem_sdiff.mp this).1

theorem card_splitBlocks_insert {α : Type*} [DecidableEq α] {a : α} {s : Finset α}
    (ha : a ∉ s) :
    #(splitBlocks (insert a s)) = ∑ t ∈ s.powerset, #(splitBlocks (s \ t)) := by
  have hcover : splitBlocks (insert a s) =
      s.powerset.biUnion (fun t => (splitBlocks (insert a s)).filter (insert a t ∈ ·)) := by
    ext F
    simp only [mem_biUnion, mem_filter, mem_powerset]
    constructor
    · intro hF
      have h := (mem_splitBlocks _ F).mp hF
      obtain ⟨p, hp, hap⟩ := h.2.1 a (mem_insert_self a s)
      refine ⟨p.erase a, ?_, hF, ?_⟩
      · intro x hx
        rw [mem_erase] at hx
        have := h.1 p hp hx.2
        rw [mem_insert] at this
        exact this.resolve_left hx.1
      · rw [insert_erase hap]; exact hp
    · rintro ⟨_, _, hF, _⟩; exact hF
  rw [hcover, card_biUnion]
  · refine sum_congr rfl fun t ht => ?_
    exact card_splitBlocks_fiber ha (mem_powerset.mp ht)
  · intro t ht u hu htu
    rw [Function.onFun, disjoint_left]
    intro F hFt hFu
    rw [mem_filter] at hFt hFu
    have h := (mem_splitBlocks _ F).mp hFt.1
    have heq := h.2.2.1 _ hFt.2 _ hFu.2 a (mem_insert_self a t) (mem_insert_self a u)
    apply htu
    have hat : a ∉ t := fun h => ha (mem_powerset.mp ht h)
    have hau : a ∉ u := fun h => ha (mem_powerset.mp hu h)
    rw [← erase_insert hat, heq, erase_insert hau]

theorem card_splitBlocks_eq_bell {α : Type*} [DecidableEq α] (n : ℕ) :
    ∀ s : Finset α, #s = n → #(splitBlocks s) = Nat.bell n := by
  induction n using Nat.strong_induction_on with
  | _ n ih =>
    intro s hs
    rcases n with _ | n
    · rw [card_eq_zero] at hs
      subst hs
      rw [splitBlocks_empty, card_singleton, Nat.bell_zero]
    · have hne : s.Nonempty := by rw [← card_pos, hs]; omega
      obtain ⟨a, ha⟩ := hne
      have hs' : #(s.erase a) = n := by rw [card_erase_of_mem ha, hs]; rfl
      rw [← insert_erase ha, card_splitBlocks_insert (notMem_erase a s)]
      have : ∀ t ∈ (s.erase a).powerset, #(splitBlocks ((s.erase a) \ t)) = Nat.bell (n - #t) := by
        intro t ht
        rw [mem_powerset] at ht
        apply ih
        · have := card_le_card ht; omega
        · rw [card_sdiff_of_subset ht, hs']
      rw [sum_congr rfl this, sum_powerset_apply_card (fun m => Nat.bell (n - m)), hs',
        Nat.bell_succ, ← Nat.range_succ_eq_Iic]
      simp only [smul_eq_mul]

#print axioms splitBlocks
#print axioms mem_splitBlocks
#print axioms finpartitionEquivSplitBlocks
#print axioms card_finpartition_eq_card_splitBlocks
#print axioms splitBlocks_empty
#print axioms card_splitBlocks_fiber
#print axioms card_splitBlocks_insert
#print axioms card_splitBlocks_eq_bell

end BellHelpers

/-- B(n): the number of set partitions of `n` named people (the members of `Fin n`). A
`Finpartition` of the whole set is a set of blocks with no names, none empty, that cover every
person without overlapping; how many blocks there are is free. -/
def setSplits (n : ℕ) : ℕ := Fintype.card (Finpartition (Finset.univ : Finset (Fin n)))

/-- B(n) agrees with Mathlib's Bell number. -/
theorem setSplits_eq_bell (n : ℕ) : setSplits n = Nat.bell n := by
  unfold setSplits
  convert (card_finpartition_eq_card_splitBlocks (Finset.univ : Finset (Fin n))).trans
    (card_splitBlocks_eq_bell _ _ rfl) using 2
  simp

#print axioms setSplits_eq_bell

/-- The card's recurrence: splitting `n + 1` named people into unnamed non-empty groups, by
choosing who is left out of the newest person's group and splitting those left out, gives
B(n + 1) = C(n,0) B(0) + C(n,1) B(1) + ... + C(n,n) B(n), for every `n`. -/
theorem set_partitions_bell_recurrence (n : ℕ) :
    setSplits (n + 1) = ∑ k ∈ Finset.range (n + 1), n.choose k * setSplits k := by
  rw [setSplits_eq_bell, Nat.bell_succ, ← Nat.range_succ_eq_Iic,
    ← Finset.sum_range_reflect]
  refine Finset.sum_congr rfl fun j hj => ?_
  rw [Finset.mem_range] at hj
  rw [setSplits_eq_bell, Nat.add_sub_cancel, Nat.choose_symm (by omega), Nat.sub_sub_self (by omega)]

/-- The floor: an empty crowd splits exactly one way, into no groups at all, so B(0) = 1. -/
theorem set_partitions_of_empty_crowd : setSplits 0 = 1 := by
  rw [setSplits_eq_bell, Nat.bell_zero]

/-- For any finite set of named people, the number of ways to split it into unnamed non-empty
groups is the Bell number of its size (Mathlib's `Nat.bell`, A000110). -/
theorem card_set_partitions_eq_bell {α : Type*} [DecidableEq α] (s : Finset α) :
    Fintype.card (Finpartition s) = Nat.bell s.card := by
  rw [card_finpartition_eq_card_splitBlocks]
  exact card_splitBlocks_eq_bell _ s rfl

-- B(0) to B(8): 1, 1, 2, 5, 15, 52, 203, 877, 4140.
example : [Nat.bell 0, Nat.bell 1, Nat.bell 2, Nat.bell 3, Nat.bell 4, Nat.bell 5, Nat.bell 6,
    Nat.bell 7, Nat.bell 8] = [1, 1, 2, 5, 15, 52, 203, 877, 4140] := by
  norm_num [Nat.bell_succ, ← Nat.range_succ_eq_Iic, Finset.sum_range_succ, Nat.choose]
-- Four friends, sorted by Dara's company: 1 x B(0) + 3 x B(1) + 3 x B(2) + 1 x B(3) = 1 + 3 + 6 + 5 = 15.
example : Nat.choose 3 0 * 1 = 1 ∧ Nat.choose 3 1 * 1 = 3 ∧ Nat.choose 3 2 * 2 = 6 ∧
    Nat.choose 3 3 * 5 = 5 ∧ 1 + 3 + 6 + 5 = 15 := by decide
-- The fifteen listed, sorted by taxis used: 1 + 7 + 6 + 1 = 15.
example : 1 + 7 + 6 + 1 = 15 := by decide
-- A fifth friend: 1 x 1 + 4 x 1 + 6 x 2 + 4 x 5 + 1 x 15 = 52.
example : Nat.choose 4 0 * 1 + Nat.choose 4 1 * 1 + Nat.choose 4 2 * 2 + Nat.choose 4 3 * 5 +
    Nat.choose 4 4 * 15 = 52 := by decide
-- Two numbered taxis, neither empty: 14 ways (2 ^ 4 - 2), twice the 7 with unnamed taxis.
example : Fintype.card {f : Fin 4 → Fin 2 // Function.Surjective f} = 14 := by decide
example : 2 ^ 4 - 2 = 14 ∧ 14 = 2 * 7 := by decide
-- The index slipped: C(4,0) B(0) + ... + C(4,4) B(4) is 52, which is B(5), not B(4) = 15.
example : Nat.choose 4 0 * 1 + Nat.choose 4 1 * 1 + Nat.choose 4 2 * 2 + Nat.choose 4 3 * 5 +
    Nat.choose 4 4 * 15 ≠ 15 := by decide

#print axioms set_partitions_bell_recurrence
#print axioms set_partitions_of_empty_crowd
#print axioms card_set_partitions_eq_bell
