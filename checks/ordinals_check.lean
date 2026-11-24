-- Ordinals: one guest in front of the endless queue is absorbed (1 + ω = ω) but one guest behind it makes a longer line-up (ω < ω + 1), and the same holds for pairings that keep order.
import Mathlib.SetTheory.Ordinal.Arithmetic
import Mathlib.Order.Hom.Lex
import Mathlib.Tactic.NormNum
import Mathlib.SetTheory.Ordinal.Principal

open Ordinal

/-- The card's main claim: one person put in front of the endless queue ω still gives the
shape ω, so 1 + ω = ω; but the endless queue with one person put behind it is a longer shape,
so ω < ω + 1. (Mathlib's `Ordinal` is the order type of a well-order, and `α + β` puts the
line-up `β` behind the line-up `α`.) -/
theorem one_add_omega_eq_omega_and_omega_lt_omega_add_one :
    (1 : Ordinal) + ω = ω ∧ ω < ω + 1 := by
  refine ⟨one_add_omega0, ?_⟩
  exact Order.lt_add_one_iff.2 le_rfl

/-- The same claim told with line-ups and order-keeping pairings (Steps 1 and 2): the line
"late guest, then rooms 0, 1, 2, ..." can be paired with the counting numbers person to person
keeping the order, but the line "rooms 0, 1, 2, ..., then the late guest" cannot. -/
theorem guest_in_front_pairs_in_order_guest_behind_does_not :
    Nonempty (Unit ⊕ₗ ℕ ≃o ℕ) ∧ IsEmpty (ℕ ⊕ₗ Unit ≃o ℕ) := by
  have hU : typeLT Unit = 1 := type_eq_one_of_unique _
  constructor
  · have h : typeLT (Unit ⊕ₗ ℕ) = typeLT ℕ := by
      rw [type_lt_sum_lex, hU, type_nat_lt, one_add_omega0]
    obtain ⟨e⟩ := type_eq.1 h
    exact ⟨OrderIso.ofRelIsoLT e⟩
  · refine ⟨fun e => ?_⟩
    have h := e.ordinalType_congr
    rw [type_lt_sum_lex, hU, type_nat_lt] at h
    exact (Order.lt_add_one_iff.2 le_rfl).ne' h

/-- Products are copies in a row (Step 4): two hotels in a row, ω · 2, are longer than one
hotel, but guests arriving in pairs, 2 · ω (ω copies of 2), still give ω. -/
theorem omega_lt_omega_mul_two_and_two_mul_omega_eq_omega :
    ω < ω * 2 ∧ (2 : Ordinal) * ω = ω := by
  refine ⟨?_, ?_⟩
  · have h : ω * 2 = ω + ω := by
      rw [show (2 : Ordinal) = 1 + 1 by norm_num, mul_add, mul_one]
    rw [h]
    exact lt_add_of_pos_right _ omega0_pos
  · exact_mod_cast natCast_mul_omega0 (n := 2) (by norm_num)

-- Finite line-ups commute: 2 + 3 and 3 + 2 are both 5.
example : (2 : Ordinal) + 3 = 5 ∧ (3 : Ordinal) + 2 = 5 := by norm_num

-- The front guest re-paired: L (written 0 here) and guests 1 to 5 go to places 1 to 6, in order.
example : List.map (fun g => if g = 0 then 1 else g + 1) [0, 1, 2, 3, 4, 5]
    = [1, 2, 3, 4, 5, 6] := by decide

-- The back guest sent to place 5: only 4 places lie ahead of it, but guests 1 to 5 all stand ahead of him.
example : (List.range' 1 4).length = 4 ∧ (List.range' 1 5).length = 5 ∧ 4 < 5 := by decide

-- Guests in pairs: pair k takes places 2k - 1 and 2k, so pairs 1 to 3 fill places 1 to 6 in order.
example : List.flatMap (fun k => [2 * k - 1, 2 * k]) [1, 2, 3] = [1, 2, 3, 4, 5, 6] := by decide

#print axioms one_add_omega_eq_omega_and_omega_lt_omega_add_one
#print axioms guest_in_front_pairs_in_order_guest_behind_does_not
#print axioms omega_lt_omega_mul_two_and_two_mul_omega_eq_omega
