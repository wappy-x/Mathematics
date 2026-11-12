-- Perfect shuffles: eight perfect out-riffles put every 52-card deck back in its starting order, because one riffle sends the card at position p to 2p on a clock of 2m - 1 spots, so t riffles restore a deck of 2m cards exactly when 2^t leaves 1 on that clock.
import Mathlib.Data.Nat.ModEq
import Mathlib.Logic.Function.Iterate
import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Finset.Card
import Mathlib.Tactic.NormNum

/-- A deck of `2 * m` cards is a function giving the card at each position, `0` the top card.
A perfect riffle (out-shuffle) cuts it into a top half (positions `0 … m - 1`) and a bottom
half (positions `m … 2m - 1`) and lets the cards fall strictly one from each hand, the top
half first: new position `2k` gets the top half's `k`-th card, new position `2k + 1` gets
the bottom half's `k`-th card. The top card stays on top. -/
def riffle {α : Type*} {m : ℕ} (deck : Fin (2 * m) → α) : Fin (2 * m) → α :=
  fun i => if i.val % 2 = 0 then deck ⟨i.val / 2, by have := i.isLt; omega⟩
    else deck ⟨m + i.val / 2, by have := i.isLt; omega⟩

/-- The other perfect riffle (in-shuffle): the bottom half's card falls first, so the top
card is buried at position 1. -/
def inRiffle {α : Type*} {m : ℕ} (deck : Fin (2 * m) → α) : Fin (2 * m) → α :=
  fun i => if i.val % 2 = 0 then deck ⟨m + i.val / 2, by have := i.isLt; omega⟩
    else deck ⟨i.val / 2, by have := i.isLt; omega⟩

theorem riffle_eq_comp_aux {α : Type*} {m : ℕ} (deck : Fin (2 * m) → α) :
    riffle deck = deck ∘ riffle (id : Fin (2 * m) → Fin (2 * m)) := by
  funext i
  simp only [riffle, Function.comp, id]
  split_ifs <;> rfl

#print axioms riffle_eq_comp_aux

theorem riffle_iterate_aux {α : Type*} {m : ℕ} (deck : Fin (2 * m) → α) (t : ℕ) :
    (riffle (m := m))^[t] deck = deck ∘ (riffle (id : Fin (2 * m) → Fin (2 * m)))^[t] := by
  induction t with
  | zero => rfl
  | succ t ih =>
    rw [Function.iterate_succ_apply', ih, riffle_eq_comp_aux, Function.iterate_succ]
    rfl

#print axioms riffle_iterate_aux

theorem riffle_id_key_aux {m : ℕ} (p q : Fin (2 * m))
    (hq : q.val = if p.val = 2 * m - 1 then p.val else 2 * p.val % (2 * m - 1)) :
    riffle (id : Fin (2 * m) → Fin (2 * m)) q = p := by
  apply Fin.ext
  have hp := p.isLt
  have hq2 := q.isLt
  simp only [riffle, id]
  by_cases h : p.val = 2 * m - 1
  · rw [if_pos h] at hq
    have hodd : q.val % 2 = 1 := by omega
    rw [if_neg (by omega)]
    simp only
    omega
  · rw [if_neg h] at hq
    by_cases h2 : 2 * p.val < 2 * m - 1
    · rw [Nat.mod_eq_of_lt h2] at hq
      rw [if_pos (by omega)]
      simp only
      omega
    · have h3 : 2 * p.val % (2 * m - 1) = 2 * p.val - (2 * m - 1) := by
        rw [Nat.mod_eq_sub_mod (by omega), Nat.mod_eq_of_lt (by omega)]
      rw [h3] at hq
      rw [if_neg (by omega)]
      simp only
      omega

#print axioms riffle_id_key_aux

theorem riffle_id_pow_aux {m : ℕ} (t : ℕ) :
    ∀ (p q : Fin (2 * m)), p.val < 2 * m - 1 → q.val = 2 ^ t * p.val % (2 * m - 1) →
      (riffle (id : Fin (2 * m) → Fin (2 * m)))^[t] q = p := by
  induction t with
  | zero =>
    intro p q hp hq
    apply Fin.ext
    simp only [Function.iterate_zero, id_eq]
    rw [hq]
    simp [Nat.mod_eq_of_lt hp]
  | succ t ih =>
    intro p q hp hq
    have hn : 0 < 2 * m - 1 := by omega
    have hp2 : 2 * p.val % (2 * m - 1) < 2 * m := by
      have := Nat.mod_lt (2 * p.val) hn
      omega
    let p' : Fin (2 * m) := ⟨2 * p.val % (2 * m - 1), hp2⟩
    have hp' : p'.val < 2 * m - 1 := Nat.mod_lt _ hn
    have hq' : q.val = 2 ^ t * p'.val % (2 * m - 1) := by
      rw [hq]
      have : 2 ^ t * (2 * p.val % (2 * m - 1)) ≡ 2 ^ t * (2 * p.val) [MOD 2 * m - 1] :=
        Nat.ModEq.mul_left _ (Nat.mod_modEq _ _)
      have h2 : 2 ^ (t + 1) * p.val = 2 ^ t * (2 * p.val) := by rw [pow_succ, mul_assoc]
      rw [h2]
      exact this.symm
    have e := ih p' q hp' hq'
    rw [Function.iterate_succ_apply', e]
    apply riffle_id_key_aux
    rw [if_neg (by omega)]

#print axioms riffle_id_pow_aux

/-- Eight perfect riffles restore a 52-card deck: whatever the cards and their order,
after eight perfect out-riffles of a 52-card deck every card is back where it started. -/
theorem eight_perfect_riffles_restore_52_card_deck {α : Type*} (deck : Fin (2 * 26) → α) :
    (riffle (m := 26))^[8] deck = deck := by
  rw [riffle_iterate_aux]
  have h : ∀ i : Fin (2 * 26),
      (riffle (id : Fin (2 * 26) → Fin (2 * 26)))^[8] i = i := by decide +kernel
  funext i
  simp only [Function.comp, h]

/-- A perfect riffle doubles a card's position on a clock of `2m - 1` spots: in a deck of
`2m` cards, the card at position `p` lands at position `2p mod (2m - 1)`, except the bottom
card, position `2m - 1`, which stays put. -/
theorem perfect_riffle_doubles_position_mod_deck_size_minus_one {α : Type*} {m : ℕ}
    (deck : Fin (2 * m) → α) (p q : Fin (2 * m))
    (hq : q.val = if p.val = 2 * m - 1 then p.val else 2 * p.val % (2 * m - 1)) :
    riffle deck q = deck p := by
  rw [riffle_eq_comp_aux]
  simp only [Function.comp]
  rw [riffle_id_key_aux p q hq]

/-- Any (non-empty) even deck runs the same way on a clock one spot smaller: `t` perfect
riffles put every deck of `2m` cards back in order exactly when `2^t` leaves `1` on the
clock of `2m - 1` spots. -/
theorem riffles_restore_deck_iff_two_pow_eq_one_mod {m : ℕ} (hm : 0 < m) (t : ℕ) :
    (∀ (α : Type) (deck : Fin (2 * m) → α), (riffle (m := m))^[t] deck = deck) ↔
      2 ^ t ≡ 1 [MOD 2 * m - 1] := by
  constructor
  · intro h
    by_cases hm1 : m = 1
    · subst hm1
      exact Nat.modEq_one
    · have hn : 1 < 2 * m - 1 := by omega
      have h1 := h (Fin (2 * m)) id
      rw [riffle_iterate_aux] at h1
      have h2 : ∀ x : Fin (2 * m),
          (riffle (id : Fin (2 * m) → Fin (2 * m)))^[t] x = x := fun x => congrFun h1 x
      have hlt : 2 ^ t % (2 * m - 1) < 2 * m := by
        have := Nat.mod_lt (2 ^ t) (show 0 < 2 * m - 1 by omega)
        omega
      have key := riffle_id_pow_aux (m := m) t ⟨1, by omega⟩ ⟨2 ^ t % (2 * m - 1), hlt⟩
        (by simpa using hn) (by simp)
      rw [h2] at key
      have := congrArg Fin.val key
      simp only at this
      show 2 ^ t % (2 * m - 1) = 1 % (2 * m - 1)
      rw [this, Nat.mod_eq_of_lt hn]
  · intro h α deck
    rw [riffle_iterate_aux]
    funext i
    simp only [Function.comp]
    congr 1
    by_cases hi : i.val = 2 * m - 1
    · apply Function.iterate_fixed
      exact riffle_id_key_aux i i (by rw [if_pos hi])
    · apply riffle_id_pow_aux t i i (by have := i.isLt; omega)
      have h3 : 2 ^ t * i.val ≡ 1 * i.val [MOD 2 * m - 1] := Nat.ModEq.mul_right _ h
      have h4 : i.val < 2 * m - 1 := by have := i.isLt; omega
      have h5 : 2 ^ t * i.val % (2 * m - 1) = 1 * i.val % (2 * m - 1) := h3
      rw [h5, one_mul, Nat.mod_eq_of_lt h4]

-- The card at position 10, riffle by riffle: 10, 20, 40, 29, 7, 14, 28, 5, 10.
-- (Label each card by its starting position; `d q = p` means card `p` now sits at `q`.)
example : (riffle (m := 26))^[1] id (20 : Fin 52) = 10 := by decide
example : (riffle (m := 26))^[2] id (40 : Fin 52) = 10 := by decide
example : (riffle (m := 26))^[3] id (29 : Fin 52) = 10 := by decide
example : (riffle (m := 26))^[4] id (7 : Fin 52) = 10 := by decide
example : (riffle (m := 26))^[5] id (14 : Fin 52) = 10 := by decide
example : (riffle (m := 26))^[6] id (28 : Fin 52) = 10 := by decide
example : (riffle (m := 26))^[7] id (5 : Fin 52) = 10 := by decide
example : (riffle (m := 26))^[8] id (10 : Fin 52) = 10 := by decide
-- The arithmetic on the 51-clock: 40 doubled is 80, less 51 is 29; position 26 lands at 1.
example : 2 * 40 % 51 = 29 ∧ 80 - 51 = 29 ∧ 2 * 26 % 51 = 1 := by norm_num
example : (riffle (m := 26)) id (1 : Fin 52) = 26 := by decide
-- Seat 1 doubled on the 51-clock: 2, 4, 8, 16, 32, 13, 26, 1.
example : (List.range 8).map (fun t => 2 ^ (t + 1) % 51) = [2, 4, 8, 16, 32, 13, 26, 1] := by
  decide
-- 256 = 5 × 51 + 1.
example : 2 ^ 8 = 256 ∧ 256 = 5 * 51 + 1 := by norm_num
-- Only the top and bottom cards, positions 0 and 51, never move.
example : ∀ p : Fin 52, (riffle (m := 26)) id p = p ↔ p = 0 ∨ p = 51 := by decide +kernel
-- Eight riffles bring the deck home and no fewer do; seven leave 50 cards out of place.
example : ∀ p : Fin 52, (riffle (m := 26))^[8] id p = p := by decide +kernel
example : ∀ t < 8, 0 < t → ∃ p : Fin 52, (riffle (m := 26))^[t] id p ≠ p := by decide +kernel
example : (Finset.univ.filter (fun p : Fin 52 => (riffle (m := 26))^[7] id p ≠ p)).card = 50 := by
  decide +kernel
-- The mistake: a 52-clock puts position 10 at 12 after eight doublings.
example : 10 * 2 ^ 8 % 52 = 12 := by norm_num
-- Decks of 8, 10 and 64 come home after 3, 6 and 6 riffles, and not sooner.
example : (∀ p : Fin 8, (riffle (m := 4))^[3] id p = p) ∧
    ∀ t < 3, 0 < t → ∃ p : Fin 8, (riffle (m := 4))^[t] id p ≠ p := by decide +kernel
example : (∀ p : Fin 10, (riffle (m := 5))^[6] id p = p) ∧
    ∀ t < 6, 0 < t → ∃ p : Fin 10, (riffle (m := 5))^[t] id p ≠ p := by decide +kernel
example : (∀ p : Fin 64, (riffle (m := 32))^[6] id p = p) ∧
    ∀ t < 6, 0 < t → ∃ p : Fin 64, (riffle (m := 32))^[t] id p ≠ p := by decide +kernel
-- Burying the top card, the in-shuffle, needs 52 riffles, and 51 is not enough. On the
-- 53-clock, 2 first returns to 1 at the 52nd power.
example : ∀ p : Fin 52, (inRiffle (m := 26))^[52] id p = p := by decide +kernel
example : ∀ t < 52, 0 < t → ∃ p : Fin 52, (inRiffle (m := 26))^[t] id p ≠ p := by decide +kernel
example : 2 ^ 52 % 53 = 1 ∧ ∀ t < 52, 0 < t → 2 ^ t % 53 ≠ 1 := by decide +kernel

#print axioms eight_perfect_riffles_restore_52_card_deck
#print axioms perfect_riffle_doubles_position_mod_deck_size_minus_one
#print axioms riffles_restore_deck_iff_two_pow_eq_one_mod
