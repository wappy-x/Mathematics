-- The hockey stick: adding the binomial coefficients C(k,k) + C(k+1,k) + ... + C(n,k) down one column of Pascal's triangle gives C(n+1,k+1), the picks of k+1 labels from n+1 split by their largest label give that same sum, and a triangular layer of m rows holds C(m+1,2) tins.
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Data.Finset.Powerset
import Mathlib.Data.Finset.Prod
import Mathlib.Order.Interval.Finset.Nat

open Finset

/-- The hockey stick. For whole numbers n ≥ k, adding the entries of column k of Pascal's
triangle from its top entry C(k,k) down to row n gives the entry one row below and one column
right: C(k,k) + C(k+1,k) + ... + C(n,k) = C(n+1,k+1). -/
theorem column_sum_equals_entry_one_row_down_one_column_right (n k : ℕ) (h : k ≤ n) :
    ∑ i ∈ Icc k n, i.choose k = (n + 1).choose (k + 1) := by
  exact Nat.sum_Icc_choose n k

/-- The second route, by largest label. Among the picks of k+1 labels from the labels 1 to n+1,
those whose largest label is i+1 (for a row i from k to n) number C(i,k): the other k labels
come from the i labels below it. -/
theorem picks_with_largest_label_count (n k i : ℕ) (hk : k ≤ i) (hi : i ≤ n) :
    (((Icc 1 (n + 1)).powersetCard (k + 1)).filter
        (fun s => i + 1 ∈ s ∧ ∀ x ∈ s, x ≤ i + 1)).card = i.choose k := by
  have key : (((Icc 1 (n + 1)).powersetCard (k + 1)).filter
        (fun s => i + 1 ∈ s ∧ ∀ x ∈ s, x ≤ i + 1)).card = ((Icc 1 i).powersetCard k).card := by
    apply Finset.card_nbij' (fun s => s.erase (i + 1)) (fun t => insert (i + 1) t)
    · intro s hs
      rw [mem_coe, mem_filter, mem_powersetCard] at hs
      obtain ⟨⟨hsub, hcard⟩, hmem, hle⟩ := hs
      rw [mem_coe, mem_powersetCard]
      refine ⟨?_, ?_⟩
      · intro x hx
        rw [mem_erase] at hx
        have h1 := hsub hx.2
        have h2 := hle x hx.2
        simp only [mem_Icc] at h1 ⊢
        omega
      · rw [card_erase_of_mem hmem, hcard]; rfl
    · intro t ht
      rw [mem_coe, mem_powersetCard] at ht
      obtain ⟨hsub, hcard⟩ := ht
      have hnot : i + 1 ∉ t := by
        intro hm; have := hsub hm; simp at this
      rw [mem_coe, mem_filter, mem_powersetCard]
      refine ⟨⟨?_, ?_⟩, mem_insert_self _ _, ?_⟩
      · intro x hx
        rw [mem_insert] at hx
        rcases hx with rfl | hx
        · simp; omega
        · have := hsub hx; simp only [mem_Icc] at this ⊢; omega
      · rw [card_insert_of_notMem hnot, hcard]
      · intro x hx
        rw [mem_insert] at hx
        rcases hx with rfl | hx
        · exact le_refl _
        · have := hsub hx; simp only [mem_Icc] at this; omega
    · intro s hs
      rw [mem_coe, mem_filter] at hs
      exact insert_erase hs.2.1
    · intro t ht
      rw [mem_coe, mem_powersetCard] at ht
      have hnot : i + 1 ∉ t := by
        intro hm; have := ht.1 hm; simp at this
      exact erase_insert hnot
  rw [key, card_powersetCard, Nat.card_Icc, Nat.add_sub_cancel]

/-- Why a layer of tins is an entry of the triangle. A triangular layer m rows deep, with
places c = 1 to r in row r, holds C(m+1,2) tins. -/
theorem triangular_layer_holds_choose_two (m : ℕ) :
    ((Icc 1 m ×ˢ Icc 1 m).filter (fun p : ℕ × ℕ => p.2 ≤ p.1)).card = (m + 1).choose 2 := by
  rw [← Nat.sum_Icc_choose m 1, card_filter, sum_product]
  apply sum_congr rfl
  intro x hx
  rw [mem_Icc] at hx
  rw [Nat.choose_one_right, sum_boole]
  have : (Icc 1 m).filter (fun y => y ≤ x) = Icc 1 x := by
    ext y; simp only [mem_filter, mem_Icc]; omega
  simp only [Nat.cast_id]
  rw [this, Nat.card_Icc, Nat.add_sub_cancel]

-- The tins: five layers 1, 3, 6, 10, 15 are C(2,2) to C(6,2).
example : Nat.choose 2 2 = 1 ∧ Nat.choose 3 2 = 3 ∧ Nat.choose 4 2 = 6 ∧
    Nat.choose 5 2 = 10 ∧ Nat.choose 6 2 = 15 := by decide
-- Their total is 35, the blade C(7,3).
example : 1 + 3 + 6 + 10 + 15 = 35 ∧ Nat.choose 7 3 = 35 := by decide
example : ∑ i ∈ Icc 2 6, i.choose 2 = Nat.choose 7 3 := by decide
-- The blade from the factorial formula: 7 × 6 × 5 ÷ (3 × 2 × 1) = 35.
example : 7 * 6 * 5 / (3 * 2 * 1) = 35 := by decide
-- Running totals 1, 4, 10, 20, 35 are column 3: C(3,3), C(4,3), C(5,3), C(6,3), C(7,3).
example : Nat.choose 3 3 = 1 ∧ Nat.choose 4 3 = 4 ∧ Nat.choose 5 3 = 10 ∧
    Nat.choose 6 3 = 20 ∧ Nat.choose 7 3 = 35 := by decide
-- The telescope's empty term: three tins from a pool of two is none.
example : Nat.choose 2 3 = 0 := by decide
-- Gaps: 3 = 4 - 1, 6 = 10 - 4, 10 = 20 - 10, 15 = 35 - 20.
example : 4 - 1 = 3 ∧ 10 - 4 = 6 ∧ 20 - 10 = 10 ∧ 35 - 20 = 15 := by decide
-- Picks of 3 from 7 labels, split by largest label 3 to 7: 1, 3, 6, 10, 15.
example : ((Icc 1 7).powersetCard 3).card = 35 := by decide
example : (List.range' 3 5).map (fun m =>
    (((Icc 1 7).powersetCard 3).filter (fun s => m ∈ s ∧ ∀ x ∈ s, x ≤ m)).card) =
    [1, 3, 6, 10, 15] := by decide
-- Two more shafts: column 1 to row 6 gives 21 = C(7,2); column 3 to row 7 gives 70 = C(8,4).
example : ∑ i ∈ Icc 1 6, i.choose 1 = 21 ∧ Nat.choose 7 2 = 21 := by decide
example : ∑ i ∈ Icc 3 7, i.choose 3 = 70 ∧ Nat.choose 8 4 = 70 := by decide
-- The mistakes: start late gives 34; C(6,3) = 20; C(7,2) = 21; row 6 adds to 64.
example : ∑ i ∈ Icc 3 6, i.choose 2 = 34 := by decide
example : Nat.choose 6 3 = 20 ∧ Nat.choose 7 2 = 21 := by decide
example : ∑ j ∈ range 7, Nat.choose 6 j = 64 := by decide

#print axioms column_sum_equals_entry_one_row_down_one_column_right
#print axioms picks_with_largest_label_count
#print axioms triangular_layer_holds_choose_two
