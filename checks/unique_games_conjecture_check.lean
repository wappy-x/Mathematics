-- The unique games conjecture: a unique game on a ring with shift rules can meet every rule exactly when its offsets add to a multiple of k, and then in exactly k ways, and max-cut on an odd ring cuts every link but one.
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Fintype.Pi
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.Ring

open Finset

/-- One step round the ring raises the value by one, except at the last node. -/
theorem zmod_val_add_one_of_lt {n : ℕ} [NeZero n] (i : ZMod n) (h : i.val + 1 < n) :
    (i + 1).val = i.val + 1 := by
  rw [ZMod.val_add, ZMod.val_one_eq_one_mod, Nat.add_mod_mod, Nat.mod_eq_of_lt h]

/-- Summing over the ring is summing over the indices 0, ..., n - 1. -/
theorem zmod_sum_eq_sum_range {n : ℕ} [NeZero n] {M : Type*} [AddCommMonoid M]
    (f : ZMod n → M) : ∑ i, f i = ∑ t ∈ range n, f (t : ZMod n) := by
  refine Finset.sum_nbij' (fun i => i.val) (fun t => (t : ZMod n)) ?_ ?_ ?_ ?_ ?_
  · intro i _; simpa using ZMod.val_lt i
  · intro t _; simp
  · intro i _; exact ZMod.natCast_zmod_val i
  · intro t ht; exact ZMod.val_cast_of_lt (by simpa using ht)
  · intro i _; show f i = f ((i.val : ℕ) : ZMod n); rw [ZMod.natCast_zmod_val]

/-- A labelling that does not change across any link is constant. -/
theorem zmod_const_of_step {n : ℕ} [NeZero n] {α : Type*} (d : ZMod n → α)
    (h : ∀ i, d (i + 1) = d i) (i : ZMod n) : d i = d 0 := by
  have key : ∀ j : ℕ, d (j : ZMod n) = d 0 := by
    intro j
    induction j with
    | zero => simp
    | succ j ih => rw [Nat.cast_succ, h, ih]
  rw [← ZMod.natCast_zmod_val i]
  exact key _

/-- A unique game on a ring of n nodes with k labels, where the rule on link i says
"the label of node i + 1 is the label of node i plus c i, counted round a clock of k",
can have all its rules met exactly when the offsets c i add up to a multiple of k. -/
theorem ring_game_all_rules_met_iff_offsets_sum_zero (n k : ℕ) [NeZero n]
    (c : ZMod n → ZMod k) :
    (∃ x : ZMod n → ZMod k, ∀ i, x (i + 1) = x i + c i) ↔ ∑ i, c i = 0 := by
  constructor
  · rintro ⟨x, hx⟩
    have hc : ∀ i, c i = x (i + 1) - x i := fun i => by rw [hx]; ring
    simp only [hc, Finset.sum_sub_distrib]
    rw [sub_eq_zero]
    exact Fintype.sum_equiv (Equiv.addRight 1) _ _ (fun _ => rfl)
  · intro hsum
    refine ⟨fun j => ∑ t ∈ range j.val, c (t : ZMod n), fun i => ?_⟩
    have hi := ZMod.val_lt i
    rcases Nat.lt_or_ge (i.val + 1) n with h | h
    · simp only [zmod_val_add_one_of_lt i h, Finset.sum_range_succ, ZMod.natCast_zmod_val]
    · have hn : i.val + 1 = n := by omega
      have h0 : i + 1 = 0 := by
        have := congrArg (Nat.cast : ℕ → ZMod n) hn
        push_cast [ZMod.natCast_zmod_val, ZMod.natCast_self] at this
        exact this
      simp only [h0, ZMod.val_zero, Finset.sum_range_zero]
      have := Finset.sum_range_succ (fun t => c (t : ZMod n)) i.val
      simp only [ZMod.natCast_zmod_val] at this
      rw [← this, hn, ← zmod_sum_eq_sum_range, hsum]

/-- Fixing one node's label forces all the others, so a ring game with k labels has exactly
k labellings that meet every rule when its offsets add to a multiple of k, and none otherwise. -/
theorem ring_game_full_labellings_count (n k : ℕ) [NeZero n] [NeZero k]
    (c : ZMod n → ZMod k) :
    (univ.filter fun x : ZMod n → ZMod k => ∀ i, x (i + 1) = x i + c i).card
      = if ∑ i, c i = 0 then k else 0 := by
  split_ifs with hsum
  · obtain ⟨x₀, hx₀⟩ := (ring_game_all_rules_met_iff_offsets_sum_zero n k c).2 hsum
    have himg : (univ.filter fun x : ZMod n → ZMod k => ∀ i, x (i + 1) = x i + c i)
        = univ.image (fun a : ZMod k => fun j => x₀ j + a) := by
      ext x
      simp only [mem_filter, mem_univ, true_and, mem_image]
      constructor
      · intro hx
        refine ⟨x 0 - x₀ 0, funext fun j => ?_⟩
        have := zmod_const_of_step (fun j => x j - x₀ j)
          (fun i => by simp only [hx, hx₀]; ring) j
        rw [← this]; ring
      · rintro ⟨a, rfl⟩ i
        show x₀ (i + 1) + a = x₀ i + a + c i
        rw [hx₀]; ring
    rw [himg, Finset.card_image_of_injective, card_univ, ZMod.card]
    intro a b hab
    have := congrFun hab 0
    simpa using this
  · rw [Finset.card_eq_zero, Finset.filter_eq_empty_iff]
    intro x _ hx
    exact hsum ((ring_game_all_rules_met_iff_offsets_sum_zero n k c).1 ⟨x, hx⟩)

/-- Max-cut is the unique game with two labels and the rule "the sides differ": on a ring
with an odd number 2m + 1 of nodes, no split cuts every link, and the best splits cut 2m. -/
theorem odd_ring_max_cut (m : ℕ) :
    (∀ x : ZMod (2 * m + 1) → ZMod 2, (univ.filter fun i => x (i + 1) ≠ x i).card ≤ 2 * m) ∧
    ∃ x : ZMod (2 * m + 1) → ZMod 2, (univ.filter fun i => x (i + 1) ≠ x i).card = 2 * m := by
  constructor
  · intro x
    have hle : (univ.filter fun i => x (i + 1) ≠ x i).card ≤ 2 * m + 1 := by
      simpa [ZMod.card] using Finset.card_filter_le (univ : Finset (ZMod (2 * m + 1)))
        (fun i => x (i + 1) ≠ x i)
    by_contra hgt
    have heq : (univ.filter fun i => x (i + 1) ≠ x i) = univ := by
      apply Finset.eq_univ_of_card
      rw [ZMod.card]; omega
    have hall : ∀ i, x (i + 1) = x i + 1 := by
      intro i
      have hi : i ∈ (univ.filter fun i => x (i + 1) ≠ x i) := by rw [heq]; exact mem_univ i
      have hne : x (i + 1) ≠ x i := (mem_filter.1 hi).2
      have key : ∀ a b : ZMod 2, a ≠ b → a = b + 1 := by decide
      exact key _ _ hne
    have hs := (ring_game_all_rules_met_iff_offsets_sum_zero (2 * m + 1) 2
      (fun _ => 1)).1 ⟨x, hall⟩
    rw [Finset.sum_const, Finset.card_univ, ZMod.card, nsmul_eq_mul, mul_one,
      ZMod.natCast_eq_zero_iff_even] at hs
    exact (Nat.not_even_two_mul_add_one m) hs
  · refine ⟨fun i => (i.val : ZMod 2), ?_⟩
    have hset : (univ.filter fun i : ZMod (2 * m + 1) =>
        ((i + 1).val : ZMod 2) ≠ (i.val : ZMod 2)) = univ.erase (-1) := by
      ext i
      simp only [mem_filter, mem_univ, true_and, mem_erase, and_true]
      have hi := ZMod.val_lt i
      have hneg : (-1 : ZMod (2 * m + 1)).val = 2 * m := ZMod.val_neg_one (2 * m)
      rcases Nat.lt_or_ge (i.val + 1) (2 * m + 1) with h | h
      · have hne : i ≠ -1 := by
          intro e; rw [e, hneg] at h; omega
        have key : ∀ a : ZMod 2, a + 1 ≠ a := by decide
        rw [zmod_val_add_one_of_lt i h, Nat.cast_succ]
        exact ⟨fun _ => hne, fun _ => key _⟩
      · have he : i = -1 := by
          apply ZMod.val_injective; rw [hneg]; omega
        subst he
        simp only [ne_eq, not_true_eq_false, iff_false, not_not, neg_add_cancel, ZMod.val_zero,
          Nat.cast_zero, hneg]
        rw [eq_comm, ZMod.natCast_eq_zero_iff_even]
        exact even_two_mul m
    simp only at hset ⊢
    rw [hset, Finset.card_erase_of_mem (mem_univ _), Finset.card_univ, ZMod.card]
    omega

/-! The camera ring: 5 cameras, 3 labels, offsets 1, 2, 0, 1, 2; then the last reading wrong. -/

def goodOffsets : ZMod 5 → ZMod 3 := ![1, 2, 0, 1, 2]
def badOffsets : ZMod 5 → ZMod 3 := ![1, 2, 0, 1, 1]
def forcedLabels : ZMod 5 → ZMod 3 := ![0, 1, 0, 0, 1]
/-- How many of the ring's 5 rules the labelling x meets. -/
def metCount (c : ZMod 5 → ZMod 3) (x : ZMod 5 → ZMod 3) : ℕ :=
  (univ.filter fun i : ZMod 5 => x (i + 1) = x i + c i).card

-- 1 + 2 + 0 + 1 + 2 = 6, a multiple of 3; 1 + 2 + 0 + 1 + 1 = 5, which leaves 2
example : ∑ i, goodOffsets i = 0 := by decide
example : ∑ i, badOffsets i = 2 := by decide
-- 3^5 = 243 labellings in all
example : Fintype.card (ZMod 5 → ZMod 3) = 243 := by simp
-- camera 0 at 0 forces 0, 1, 0, 0, 1, and all 5 rules hold
example : metCount goodOffsets forcedLabels = 5 := by decide
-- the consistent ring: 3 labellings meet all 5 rules
example : (univ.filter fun x : ZMod 5 → ZMod 3 => metCount goodOffsets x = 5).card = 3 := by
  decide
-- one rule changed: none meets all 5, and 15 meet 4 of 5
example : (univ.filter fun x : ZMod 5 → ZMod 3 => metCount badOffsets x = 5).card = 0 := by
  decide
example : (univ.filter fun x : ZMod 5 → ZMod 3 => metCount badOffsets x = 4).card = 15 := by
  decide
-- 'differ' with 3 colours is not one-to-one: 30 colourings of the ring meet every rule
example : (univ.filter fun x : ZMod 5 → ZMod 3 => ∀ i : ZMod 5, x (i + 1) ≠ x i).card = 30 := by
  decide
-- max-cut on the 5-ring: no split cuts more than 4 links, and 10 splits cut 4
example : ∀ x : ZMod 5 → ZMod 2, (univ.filter fun i : ZMod 5 => x (i + 1) ≠ x i).card ≤ 4 := by
  decide
example : (univ.filter fun x : ZMod 5 → ZMod 2 =>
    (univ.filter fun i : ZMod 5 => x (i + 1) ≠ x i).card = 4).card = 10 := by
  decide

#print axioms zmod_val_add_one_of_lt
#print axioms zmod_sum_eq_sum_range
#print axioms zmod_const_of_step
#print axioms ring_game_all_rules_met_iff_offsets_sum_zero
#print axioms ring_game_full_labellings_count
#print axioms odd_ring_max_cut
