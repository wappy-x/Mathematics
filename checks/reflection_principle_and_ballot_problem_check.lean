-- The reflection principle: when a votes for A and b votes for B (with a larger than b) are counted one at a time, the counting orders that keep A strictly ahead after every vote number (a - b) / (a + b) times C(a + b, a), which is C(a + b - 1, a - 1) - C(a + b - 1, a), because mirroring up to the first level score pairs the spoiled A-openers one for one with the B-openers.
import Mathlib.Data.Finset.Powerset
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Data.Rat.Defs
import Mathlib.Algebra.Order.Field.Rat
import Mathlib.Tactic.NormNum
import Mathlib.Data.Finset.SymmDiff
import Mathlib.Order.SymmDiff
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Positivity
import Mathlib.Data.Nat.Find
import Mathlib.Tactic.Ring

open Finset

/-! A counting order of a votes for A and b votes for B is recorded by the set `S` of slots
(numbered 0, 1, …, a + b - 1) that hold the A's: a subset of `range (a + b)` with `a` elements.
There are `C(a + b, a)` of them. Votes are read one at a time, slot 0 first. -/

/-- The counting orders: which `a` of the `a + b` slots hold the votes for A. -/
def countingOrders (a b : ℕ) : Finset (Finset ℕ) :=
  powersetCard a (range (a + b))

/-- A's lead after the first `k` votes: A's votes so far minus B's votes so far. -/
def lead (S : Finset ℕ) (k : ℕ) : ℤ :=
  (#(S.filter (· < k)) : ℤ) - #((range k).filter (· ∉ S))

/-- The orders in which A is strictly ahead after every vote, from the first to the last. -/
def aheadOrders (a b : ℕ) : Finset (Finset ℕ) :=
  (countingOrders a b).filter (fun S => ∀ k ∈ Icc (1 : ℕ) (a + b), 0 < lead S k)

/-- The orders that open with a vote for B. -/
def bOpeners (a b : ℕ) : Finset (Finset ℕ) :=
  (countingOrders a b).filter (fun S => 0 ∉ S)

/-- The spoiled A-openers: orders that open with a vote for A and reach a level score later. -/
def spoiledAOpeners (a b : ℕ) : Finset (Finset ℕ) :=
  (countingOrders a b).filter (fun S => 0 ∈ S ∧ ∃ k ∈ Icc (1 : ℕ) (a + b), lead S k = 0)

open scoped symmDiff

lemma lead_zero (S : Finset ℕ) : lead S 0 = 0 := by simp [lead]

lemma lead_succ (S : Finset ℕ) (k : ℕ) :
    lead S (k + 1) = lead S k + if k ∈ S then 1 else -1 := by
  unfold lead
  by_cases hk : k ∈ S
  · have h1 : S.filter (· < k + 1) = insert k (S.filter (· < k)) := by
      ext i; simp only [mem_filter, mem_insert]
      constructor
      · rintro ⟨hi, hlt⟩
        rcases Nat.lt_succ_iff_lt_or_eq.1 hlt with h | h
        · exact Or.inr ⟨hi, h⟩
        · exact Or.inl h
      · rintro (rfl | ⟨hi, hlt⟩)
        · exact ⟨hk, Nat.lt_succ_self _⟩
        · exact ⟨hi, by omega⟩
    have h2 : (range (k + 1)).filter (· ∉ S) = (range k).filter (· ∉ S) := by
      rw [range_add_one, filter_insert]; simp [hk]
    rw [h1, h2, card_insert_of_notMem (by simp), if_pos hk]
    push_cast; ring
  · have h1 : S.filter (· < k + 1) = S.filter (· < k) := by
      ext i; simp only [mem_filter]
      constructor
      · rintro ⟨hi, hlt⟩
        refine ⟨hi, ?_⟩
        rcases Nat.lt_succ_iff_lt_or_eq.1 hlt with h | h
        · exact h
        · exact absurd (h ▸ hi) hk
      · rintro ⟨hi, hlt⟩; exact ⟨hi, by omega⟩
    have h2 : (range (k + 1)).filter (· ∉ S) = insert k ((range k).filter (· ∉ S)) := by
      rw [range_add_one, filter_insert]; simp [hk]
    rw [h1, h2, card_insert_of_notMem (by simp), if_neg hk]
    push_cast; ring

lemma lead_one (S : Finset ℕ) : lead S 1 = if 0 ∈ S then 1 else -1 := by
  rw [lead_succ, lead_zero, zero_add]

lemma lead_card (S : Finset ℕ) (n : ℕ) (h : S ⊆ range n) : lead S n = 2 * #S - n := by
  unfold lead
  have h1 : S.filter (· < n) = S := filter_true_of_mem (fun i hi => mem_range.1 (h hi))
  have h2 := card_filter_add_card_filter_not (s := range n) (fun i => i ∉ S)
  have h3 : (range n).filter (fun i => ¬ (i ∉ S)) = S := by
    ext i; simp only [mem_filter, mem_range, not_not]
    exact ⟨fun h' => h'.2, fun hi => ⟨mem_range.1 (h hi), hi⟩⟩
  rw [h3, card_range] at h2
  rw [h1]
  have : ((#((range n).filter (· ∉ S)) : ℕ) : ℤ) + (#S : ℤ) = n := by exact_mod_cast h2
  linarith

lemma lead_symmDiff_le (S : Finset ℕ) (m k : ℕ) (hk : k ≤ m) :
    lead (S ∆ range m) k = - lead S k := by
  induction k with
  | zero => simp [lead_zero]
  | succ k ih =>
    rw [lead_succ, lead_succ, ih (by omega)]
    have hkm : k < m := by omega
    by_cases hS : k ∈ S
    · have : k ∉ S ∆ range m := by simp [mem_symmDiff, hS, hkm]
      rw [if_neg this, if_pos hS]; ring
    · have : k ∈ S ∆ range m := by simp [mem_symmDiff, hS, hkm]
      rw [if_pos this, if_neg hS]; ring

lemma lead_symmDiff_ge (S : Finset ℕ) (m j : ℕ) :
    lead (S ∆ range m) (m + j) = lead S (m + j) - 2 * lead S m := by
  induction j with
  | zero => rw [add_zero, lead_symmDiff_le S m m le_rfl]; ring
  | succ j ih =>
    rw [← add_assoc, lead_succ, lead_succ, ih]
    have hiff : m + j ∈ S ∆ range m ↔ m + j ∈ S := by simp [mem_symmDiff]
    by_cases hS : m + j ∈ S
    · rw [if_pos (hiff.2 hS), if_pos hS]; ring
    · rw [if_neg (fun h => hS (hiff.1 h)), if_neg hS]; ring

lemma exists_level (S : Finset ℕ) (h1 : lead S 1 ≤ 0) :
    ∀ j, 0 ≤ lead S (1 + j) → ∃ k, 1 ≤ k ∧ k ≤ 1 + j ∧ lead S k = 0 := by
  intro j
  induction j with
  | zero => intro h; exact ⟨1, le_rfl, le_rfl, le_antisymm h1 h⟩
  | succ j ih =>
    intro h
    by_cases h' : 0 ≤ lead S (1 + j)
    · obtain ⟨k, hk1, hk2, hk3⟩ := ih h'
      exact ⟨k, hk1, by omega, hk3⟩
    · have hs := lead_succ S (1 + j)
      rw [show 1 + (j + 1) = 1 + j + 1 by ring] at h
      refine ⟨1 + j + 1, by omega, by omega, ?_⟩
      split_ifs at hs <;> omega

lemma pos_of_no_level (S : Finset ℕ) (n : ℕ) (h0 : 0 ∈ S)
    (hno : ∀ k, 1 ≤ k → k ≤ n → lead S k ≠ 0) : ∀ k, 1 ≤ k → k ≤ n → 0 < lead S k := by
  intro k
  induction k with
  | zero => intro h; omega
  | succ k ih =>
    intro _ hkn
    rcases Nat.eq_zero_or_pos k with rfl | hk
    · rw [lead_one, if_pos h0]; norm_num
    · have hp := ih hk (by omega)
      have hne := hno (k + 1) (by omega) hkn
      have hs := lead_succ S k
      split_ifs at hs <;> omega

open Classical in
/-- The first vote after which the score is level (0 if it never is). -/
noncomputable def firstLevel (S : Finset ℕ) : ℕ :=
  if h : ∃ k, 1 ≤ k ∧ lead S k = 0 then Nat.find h else 0

lemma firstLevel_spec (S : Finset ℕ) (h : ∃ k, 1 ≤ k ∧ lead S k = 0) :
    1 ≤ firstLevel S ∧ lead S (firstLevel S) = 0 ∧
      ∀ j, 1 ≤ j → j < firstLevel S → lead S j ≠ 0 := by
  unfold firstLevel
  rw [dif_pos h]
  exact ⟨(Nat.find_spec h).1, (Nat.find_spec h).2,
    fun j hj hjl hz => Nat.find_min h hjl ⟨hj, hz⟩⟩

lemma firstLevel_eq (S : Finset ℕ) (m : ℕ) (h1 : 1 ≤ m) (hz : lead S m = 0)
    (hmin : ∀ j, 1 ≤ j → j < m → lead S j ≠ 0) : firstLevel S = m := by
  obtain ⟨a1, a2, a3⟩ := firstLevel_spec S ⟨m, h1, hz⟩
  rcases lt_trichotomy (firstLevel S) m with hl | he | hg
  · exact absurd a2 (hmin _ a1 hl)
  · exact he
  · exact absurd hz (a3 m h1 hg)

/-- Swap every vote up to the first level score. -/
noncomputable def mirror (S : Finset ℕ) : Finset ℕ := S ∆ range (firstLevel S)

lemma firstLevel_mirror (S : Finset ℕ) (h : ∃ k, 1 ≤ k ∧ lead S k = 0) :
    firstLevel (mirror S) = firstLevel S := by
  obtain ⟨a1, a2, a3⟩ := firstLevel_spec S h
  unfold mirror
  refine firstLevel_eq _ _ a1 ?_ ?_
  · rw [lead_symmDiff_le _ _ _ le_rfl, a2, neg_zero]
  · intro j hj hjm
    rw [lead_symmDiff_le _ _ _ hjm.le]
    exact neg_ne_zero.mpr (a3 j hj hjm)

lemma mirror_mirror (S : Finset ℕ) (h : ∃ k, 1 ≤ k ∧ lead S k = 0) :
    mirror (mirror S) = S := by
  have hfl := firstLevel_mirror S h
  show mirror S ∆ range (firstLevel (mirror S)) = S
  rw [hfl]
  exact symmDiff_symmDiff_cancel_right _ _

lemma mirror_spec (a b : ℕ) (S : Finset ℕ) (hS : S ∈ countingOrders a b)
    (h : ∃ k, 1 ≤ k ∧ k ≤ a + b ∧ lead S k = 0) :
    mirror S ∈ countingOrders a b ∧ (0 ∈ mirror S ↔ 0 ∉ S) ∧
      (∃ k, 1 ≤ k ∧ k ≤ a + b ∧ lead (mirror S) k = 0) := by
  obtain ⟨k, hk1, hkn, hkz⟩ := h
  obtain ⟨a1, a2, a3⟩ := firstLevel_spec S ⟨k, hk1, hkz⟩
  have hmk : firstLevel S ≤ k := by
    by_contra hc
    exact a3 k hk1 (by omega) hkz
  have hmn : firstLevel S ≤ a + b := le_trans hmk hkn
  rw [countingOrders, mem_powersetCard] at hS ⊢
  obtain ⟨hsub, hcard⟩ := hS
  have hsub' : mirror S ⊆ range (a + b) := by
    intro x hx
    unfold mirror at hx
    rw [mem_symmDiff] at hx
    rcases hx with ⟨hx, _⟩ | ⟨hx, _⟩
    · exact hsub hx
    · exact mem_range.2 (lt_of_lt_of_le (mem_range.1 hx) hmn)
  refine ⟨⟨hsub', ?_⟩, ?_, ?_⟩
  · have e1 := lead_card S (a + b) hsub
    have e2 := lead_card (mirror S) (a + b) hsub'
    have e3 := lead_symmDiff_ge S (firstLevel S) (a + b - firstLevel S)
    rw [Nat.add_sub_cancel' hmn, a2] at e3
    unfold mirror at e2
    rw [e3, e1] at e2
    have : ((#(mirror S) : ℕ) : ℤ) = (a : ℤ) := by
      unfold mirror; push_cast [hcard] at e2 ⊢; linarith
    exact_mod_cast this
  · unfold mirror
    simp only [mem_symmDiff, mem_range]
    constructor
    · rintro (⟨_, h⟩ | ⟨_, h⟩)
      · omega
      · exact h
    · intro h; exact Or.inr ⟨by omega, h⟩
  · refine ⟨firstLevel S, a1, hmn, ?_⟩
    unfold mirror
    rw [lead_symmDiff_le _ _ _ le_rfl, a2, neg_zero]

lemma card_bOpeners (a b : ℕ) (hn : 0 < a + b) : #(bOpeners a b) = (a + b - 1).choose a := by
  have : bOpeners a b = powersetCard a ((range (a + b)).erase 0) := by
    ext S
    simp only [bOpeners, countingOrders, mem_filter, mem_powersetCard]
    constructor
    · rintro ⟨⟨hs, hc⟩, h0⟩
      exact ⟨fun x hx => mem_erase.2 ⟨by rintro rfl; exact h0 hx, hs hx⟩, hc⟩
    · rintro ⟨hs, hc⟩
      exact ⟨⟨fun x hx => (mem_erase.1 (hs hx)).2, hc⟩, fun h => (mem_erase.1 (hs h)).1 rfl⟩
  rw [this, card_powersetCard, card_erase_of_mem (by simp [hn]), card_range]

lemma level_iff (S : Finset ℕ) (n : ℕ) :
    (∃ k ∈ Icc (1 : ℕ) n, lead S k = 0) ↔ ∃ k, 1 ≤ k ∧ k ≤ n ∧ lead S k = 0 := by
  simp only [mem_Icc, and_assoc]

lemma card_spoiled_aux (a b : ℕ) (hab : b < a) :
    #(spoiledAOpeners a b) = #(bOpeners a b) := by
  apply card_nbij' mirror mirror
  · intro S hS
    simp only [spoiledAOpeners, mem_coe, mem_filter, level_iff] at hS
    obtain ⟨hS, h0, hz⟩ := hS
    obtain ⟨m1, m2, _⟩ := mirror_spec a b S hS hz
    simp only [bOpeners, mem_coe, mem_filter]
    exact ⟨m1, fun h => m2.1 h h0⟩
  · intro S hS
    simp only [bOpeners, mem_coe, mem_filter] at hS
    obtain ⟨hS, h0⟩ := hS
    have hsub := (mem_powersetCard.1 hS)
    have hz : ∃ k, 1 ≤ k ∧ k ≤ a + b ∧ lead S k = 0 := by
      have h1 : lead S 1 ≤ 0 := by rw [lead_one, if_neg h0]; norm_num
      have hn := lead_card S (a + b) hsub.1
      rw [hsub.2] at hn
      have := exists_level S h1 (a + b - 1) (by
        rw [show 1 + (a + b - 1) = a + b by omega, hn]; push_cast; omega)
      obtain ⟨k, hk1, hk2, hk3⟩ := this
      exact ⟨k, hk1, by omega, hk3⟩
    obtain ⟨m1, m2, m3⟩ := mirror_spec a b S hS hz
    simp only [spoiledAOpeners, mem_coe, mem_filter, level_iff]
    exact ⟨m1, m2.2 h0, m3⟩
  · intro S hS
    simp only [spoiledAOpeners, mem_coe, mem_filter, level_iff] at hS
    obtain ⟨_, _, k, hk1, _, hk3⟩ := hS
    exact mirror_mirror S ⟨k, hk1, hk3⟩
  · intro S hS
    simp only [bOpeners, mem_coe, mem_filter] at hS
    obtain ⟨hS, h0⟩ := hS
    have hsub := (mem_powersetCard.1 hS)
    have h1 : lead S 1 ≤ 0 := by rw [lead_one, if_neg h0]; norm_num
    have hn := lead_card S (a + b) hsub.1
    rw [hsub.2] at hn
    obtain ⟨k, hk1, _, hk3⟩ := exists_level S h1 (a + b - 1) (by
        rw [show 1 + (a + b - 1) = a + b by omega, hn]; push_cast; omega)
    exact mirror_mirror S ⟨k, hk1, hk3⟩

lemma card_ahead_aux (a b : ℕ) (hab : b < a) :
    #(aheadOrders a b) + 2 * #(bOpeners a b) = (a + b).choose a := by
  have e1 := card_filter_add_card_filter_not (s := countingOrders a b) (fun S => 0 ∈ S)
  have e2 := card_filter_add_card_filter_not (s := (countingOrders a b).filter (fun S => 0 ∈ S))
    (fun S => ∃ k ∈ Icc (1 : ℕ) (a + b), lead S k = 0)
  rw [filter_filter, filter_filter] at e2
  have hsp : (countingOrders a b).filter
      (fun S => 0 ∈ S ∧ ∃ k ∈ Icc (1 : ℕ) (a + b), lead S k = 0) = spoiledAOpeners a b := rfl
  have hb : (countingOrders a b).filter (fun S => ¬ 0 ∈ S) = bOpeners a b := rfl
  have hah : (countingOrders a b).filter
      (fun S => 0 ∈ S ∧ ¬ ∃ k ∈ Icc (1 : ℕ) (a + b), lead S k = 0) = aheadOrders a b := by
    unfold aheadOrders
    apply filter_congr
    intro S _
    rw [level_iff]
    constructor
    · rintro ⟨h0, hno⟩ k hk
      rw [mem_Icc] at hk
      exact pos_of_no_level S (a + b) h0 (fun j hj1 hj2 hz => hno ⟨j, hj1, hj2, hz⟩) k hk.1 hk.2
    · intro h
      constructor
      · have := h 1 (by rw [mem_Icc]; omega)
        rw [lead_one] at this
        split_ifs at this with h0
        · exact h0
        · norm_num at this
      · rintro ⟨k, hk1, hk2, hz⟩
        have := h k (by rw [mem_Icc]; omega)
        omega
  rw [hsp, hah, card_spoiled_aux a b hab] at e2
  rw [hb, ← e2] at e1
  rw [countingOrders, card_powersetCard, card_range] at e1
  omega

lemma card_ahead_int (a b : ℕ) (hab : b < a) :
    (#(aheadOrders a b) : ℤ) = ((a + b - 1).choose (a - 1) : ℤ) - (a + b - 1).choose a := by
  have h := card_ahead_aux a b hab
  rw [card_bOpeners a b (by omega)] at h
  obtain ⟨a', rfl⟩ : ∃ a', a = a' + 1 := ⟨a - 1, by omega⟩
  rw [show a' + 1 + b - 1 = a' + b by omega, show a' + 1 - 1 = a' by omega]
  rw [show a' + 1 + b - 1 = a' + b by omega, show a' + 1 + b = a' + b + 1 by omega,
    Nat.choose_succ_succ'] at h
  have h' : ((#(aheadOrders (a' + 1) b) : ℕ) : ℤ) + 2 * ((a' + b).choose (a' + 1) : ℕ) =
      ((a' + b).choose a' : ℕ) + ((a' + b).choose (a' + 1) : ℕ) := by exact_mod_cast h
  linarith

#print axioms lead_zero
#print axioms lead_succ
#print axioms lead_one
#print axioms lead_card
#print axioms lead_symmDiff_le
#print axioms lead_symmDiff_ge
#print axioms exists_level
#print axioms pos_of_no_level
#print axioms firstLevel_spec
#print axioms firstLevel_eq
#print axioms firstLevel_mirror
#print axioms mirror_mirror
#print axioms mirror_spec
#print axioms card_bOpeners
#print axioms level_iff
#print axioms card_spoiled_aux
#print axioms card_ahead_aux
#print axioms card_ahead_int

/-- The ballot problem. When A gets a votes and B gets b votes, with a larger than b, and the
votes are counted one at a time, the number of counting orders in which A is strictly ahead
after every vote is the winning margin over the total vote, (a - b) / (a + b), times the number
of all orders, C(a + b, a). -/
theorem ballot_orders_keeping_A_ahead (a b : ℕ) (hab : b < a) :
    (#(aheadOrders a b) : ℚ) = ((a : ℚ) - b) / (a + b) * ((a + b).choose a : ℕ) := by
  have h := card_ahead_int a b hab
  obtain ⟨a', rfl⟩ : ∃ a', a = a' + 1 := ⟨a - 1, by omega⟩
  rw [show a' + 1 + b - 1 = a' + b by omega, show a' + 1 - 1 = a' by omega] at h
  have hq : (#(aheadOrders (a' + 1) b) : ℚ) =
      ((a' + b).choose a' : ℕ) - ((a' + b).choose (a' + 1) : ℕ) := by
    have := congrArg (fun z : ℤ => (z : ℚ)) h
    push_cast at this ⊢
    exact this
  rw [hq]
  have i1 := Nat.add_one_mul_choose_eq (a' + b) a'
  have i2 := Nat.choose_mul_succ_eq (a' + b) (a' + 1)
  rw [show a' + b + 1 - (a' + 1) = b by omega] at i2
  rw [show a' + 1 + b = a' + b + 1 by omega]
  have j1 : ((a' + b : ℕ) + 1 : ℚ) * ((a' + b).choose a' : ℕ) =
      ((a' + b + 1).choose (a' + 1) : ℕ) * ((a' : ℚ) + 1) := by exact_mod_cast i1
  have j2 : (((a' + b).choose (a' + 1) : ℕ) : ℚ) * ((a' + b : ℕ) + 1 : ℚ) =
      ((a' + b + 1).choose (a' + 1) : ℕ) * (b : ℚ) := by exact_mod_cast i2
  have hpos : (0 : ℚ) < ((a' + 1 : ℕ) : ℚ) + b := by positivity
  push_cast at j1 j2 hpos ⊢
  rw [div_mul_eq_mul_div, eq_div_iff hpos.ne']
  linear_combination j1 - j2

/-- The subtraction form. With n = a + b votes and a larger than b, the orders keeping A strictly
ahead are the orders opening with A, C(n - 1, a - 1), less those opening with B, C(n - 1, a). -/
theorem ballot_orders_eq_choose_sub_choose (a b : ℕ) (hab : b < a) :
    (#(aheadOrders a b) : ℤ) = ((a + b - 1).choose (a - 1) : ℤ) - (a + b - 1).choose a := by
  exact card_ahead_int a b hab

/-- The reflection principle. With a larger than b, swapping every vote up to the first level
score pairs the orders that open with A and later go level one for one with the orders that
open with B, so the two piles are the same size. -/
theorem card_spoiled_A_openers_eq_card_B_openers (a b : ℕ) (hab : b < a) :
    #(spoiledAOpeners a b) = #(bOpeners a b) := by
  exact card_spoiled_aux a b hab

-- The election: 5 votes for A, 3 for B, so C(8, 5) = 56 counting orders.
example : #(countingOrders 5 3) = 56 ∧ Nat.choose 8 5 = 56 := by decide
-- 21 orders open with B, C(7, 5) = 21; the other 35 open with A, C(7, 4) = 35.
example : #(bOpeners 5 3) = 21 ∧ Nat.choose 7 5 = 21 := by decide
example : #(countingOrders 5 3) - #(bOpeners 5 3) = 35 ∧ Nat.choose 7 4 = 35 := by decide
-- The mirror: 21 of the A-openers go level later, as many as the B-openers.
example : #(spoiledAOpeners 5 3) = 21 := by decide
-- Exactly 14 orders keep A strictly ahead throughout: 35 - 21 = 14.
example : #(aheadOrders 5 3) = 14 ∧ 35 - 21 = 14 := by decide
-- The share form: (5 - 3) / (5 + 3) × 56 = 14, one in four.
example : ((5 : ℚ) - 3) / (5 + 3) * 56 = 14 ∧ (14 : ℚ) / 56 = 1 / 4 := by norm_num
-- The good order A A B A B A B A (A's in slots 0, 1, 3, 5, 7): leads 1, 2, 1, 2, 1, 2, 1, 2.
example : ({0, 1, 3, 5, 7} : Finset ℕ) ∈ aheadOrders 5 3 ∧
    (List.range' 1 8).map (lead {0, 1, 3, 5, 7}) = [1, 2, 1, 2, 1, 2, 1, 2] := by decide
-- The spoiled order A B A B B A A A (A's in slots 0, 2, 5, 6, 7): leads 1, 0, 1, 0, -1, 0, 1, 2.
example : ({0, 2, 5, 6, 7} : Finset ℕ) ∈ spoiledAOpeners 5 3 ∧
    (List.range' 1 8).map (lead {0, 2, 5, 6, 7}) = [1, 0, 1, 0, -1, 0, 1, 2] := by decide
-- Its mirror B A A B B A A A (A's in slots 1, 2, 5, 6, 7): leads -1, 0, 1, 0, -1, 0, 1, 2.
example : ({1, 2, 5, 6, 7} : Finset ℕ) ∈ bOpeners 5 3 ∧
    (List.range' 1 8).map (lead {1, 2, 5, 6, 7}) = [-1, 0, 1, 0, -1, 0, 1, 2] := by decide
-- Mistake 1: counting a level score as still ahead gives 28 orders, not 14.
example : #((countingOrders 5 3).filter (fun S => ∀ k ∈ Icc (1 : ℕ) 8, 0 ≤ lead S k)) = 28 := by
  decide
-- Mistake 2: subtracting only the mirrored orders leaves 56 - 21 = 35, not 14.
example : #(countingOrders 5 3) - #(spoiledAOpeners 5 3) = 35 := by decide
-- Mistake 3: dividing the margin by A's votes alone, (5 - 3) / 5 × 56, is not a whole count.
example : ¬ (5 ∣ (5 - 3) * 56) := by decide
-- Ten steps back to the start: C(10, 5) = 252 paths, and 42 = 252 - 210 never dip below zero.
example : #(countingOrders 5 5) = 252 ∧ Nat.choose 10 4 = 210 ∧
    #((countingOrders 5 5).filter (fun S => ∀ k ∈ range 11, 0 ≤ lead S k)) = 252 - 210 := by
  decide +kernel
-- Dropping the floor to -1 lets 132 paths through, not 42.
example : #((countingOrders 5 5).filter (fun S => ∀ k ∈ range 11, -1 ≤ lead S k)) = 132 := by
  decide +kernel

#print axioms ballot_orders_keeping_A_ahead
#print axioms ballot_orders_eq_choose_sub_choose
#print axioms card_spoiled_A_openers_eq_card_B_openers
