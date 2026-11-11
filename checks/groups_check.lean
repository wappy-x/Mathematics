-- Groups: the moves that fit a square tile into its recess form a group of eight that is not abelian, each move is "negate the corner number or not, then add a shift, wrapping at 4", and the nonzero hours of a prime clock form a group under multiplication.
import Mathlib.Data.ZMod.Basic
import Mathlib.GroupTheory.Perm.Basic
import Mathlib.Algebra.Group.Subgroup.Defs
import Mathlib.Algebra.Group.Submonoid.Defs
import Mathlib.SetTheory.Cardinal.Finite
import Mathlib.Tactic.NormNum.Basic
import Mathlib.Data.Fintype.Perm
import Mathlib.Algebra.Field.ZMod

/-- Corners i and j of the square sit side by side: going round the square, one comes straight
after the other. Corners are numbered 0, 1, 2, 3 clockwise and counted mod 4. -/
def Beside (i j : ZMod 4) : Prop := j = i + 1 ∨ i = j + 1

/-- The tile's moves: the rearrangements of the four corner positions that keep neighbouring
corners neighbours, so the tile still fits the square recess. -/
def tileMoves : Set (Equiv.Perm (ZMod 4)) :=
  {σ | ∀ i j : ZMod 4, Beside i j ↔ Beside (σ i) (σ j)}

instance (i j : ZMod 4) : Decidable (Beside i j) := by unfold Beside; infer_instance

theorem tile_aux (σ : Equiv.Perm (ZMod 4)) :
    σ ∈ tileMoves ↔ ∃ s k : ZMod 4, (s = 1 ∨ s = -1) ∧ ∀ i, σ i = s * i + k := by
  revert σ
  unfold tileMoves
  simp only [Set.mem_ofPred_eq]
  decide +kernel

#print axioms tile_aux

theorem tile_card : Nat.card tileMoves = 8 := by
  classical
  unfold tileMoves
  simp only [Set.coe_ofPred]
  rw [Nat.card_eq_fintype_card, Fintype.card_subtype]
  decide +kernel

#print axioms tile_card

/-- The tile is a group, and not an abelian one. The ways to lay the square tile pass all four
rules under "do one move, then the other": combining two moves gives a move, brackets move
freely, doing nothing is a move, and every move has an undo among the moves. So they form a
group (a subgroup of all rearrangements of the corners). There are exactly eight of them, and
order matters: some move followed by another differs from the same two in the other order. -/
theorem tile_moves_form_a_nonabelian_group_of_eight :
    ∃ H : Subgroup (Equiv.Perm (ZMod 4)),
      (H : Set (Equiv.Perm (ZMod 4))) = tileMoves ∧ Nat.card H = 8 ∧
        ∃ a ∈ H, ∃ b ∈ H, a * b ≠ b * a := by
  let H : Subgroup (Equiv.Perm (ZMod 4)) :=
    { carrier := tileMoves
      mul_mem' := by
        intro a b ha hb i j
        exact (hb i j).trans (ha (b i) (b j))
      one_mem' := by
        intro i j
        exact Iff.rfl
      inv_mem' := by
        intro a ha i j
        have := ha (a⁻¹ i) (a⁻¹ j)
        simpa using this.symm }
  refine ⟨H, rfl, tile_card, ?_⟩
  refine ⟨Equiv.addRight 1, ?_, Equiv.neg _, ?_, ?_⟩
  · exact (tile_aux _).2 ⟨1, 1, Or.inl rfl, fun i => by simp⟩
  · exact (tile_aux _).2 ⟨-1, 0, Or.inr rfl, fun i => by simp⟩
  · decide +revert

/-- Every move has one shape: keep the corner number or negate it, then add a fixed shift,
wrapping at 4. A rearrangement of the corners fits the tile exactly when it sends each corner
i to sign × i + shift, with sign 1 (a turn) or −1 (a flip). -/
theorem tile_move_is_sign_then_shift (σ : Equiv.Perm (ZMod 4)) :
    σ ∈ tileMoves ↔ ∃ s k : ZMod 4, (s = 1 ∨ s = -1) ∧ ∀ i, σ i = s * i + k := by
  exact tile_aux σ

/-- A prime clock without 0 is a group under multiplication. For a prime p, the nonzero hours
of a p-hour clock are closed under multiplication and contain 1 (a submonoid), and every one of
them has an undo among them: some nonzero b with a × b = b × a = 1. -/
theorem nonzero_hours_of_prime_clock_form_a_group (p : ℕ) (hp : p.Prime) :
    ∃ M : Submonoid (ZMod p), (M : Set (ZMod p)) = {x | x ≠ 0} ∧
      ∀ a ∈ M, ∃ b ∈ M, a * b = 1 ∧ b * a = 1 := by
  have : Fact p.Prime := ⟨hp⟩
  refine ⟨{ carrier := {x | x ≠ 0}
            mul_mem' := fun {a b} ha hb => mul_ne_zero ha hb
            one_mem' := one_ne_zero }, rfl, ?_⟩
  intro a ha
  have ha' : a ≠ 0 := ha
  exact ⟨a⁻¹, inv_ne_zero ha', mul_inv_cancel₀ ha', inv_mul_cancel₀ ha'⟩

-- One quarter turn sends corners 0 1 2 3 to 1 2 3 0; the flip sends them to 0 3 2 1.
example : [0, 1, 2, 3].map (fun i : ZMod 4 => i + 1) = [1, 2, 3, 0] := by decide
example : [0, 1, 2, 3].map (fun i : ZMod 4 => -i) = [0, 3, 2, 1] := by decide

-- Turn, then flip: corners go to 3 2 1 0, which is "negate, then add 3".
example : [0, 1, 2, 3].map ((fun i : ZMod 4 => -i) ∘ (fun i => i + 1)) = [3, 2, 1, 0] := by
  decide
example : ∀ i : ZMod 4, -(i + 1) = -i + 3 := by decide

-- Flip, then turn: corners go to 1 0 3 2, which is "negate, then add 1". Corner 0 lands at 1, not 3.
example : [0, 1, 2, 3].map ((fun i : ZMod 4 => i + 1) ∘ (fun i => -i)) = [1, 0, 3, 2] := by
  decide

-- The undo of one quarter turn is three more, and the flip undoes itself.
example : ∀ i : ZMod 4, (i + 1) + 3 = i ∧ (i + 3) + 1 = i := by decide
example : ∀ i : ZMod 4, -(-i) = i := by decide

-- Whole numbers: 3 + (−3) = 0. Under multiplication, nothing multiplies 2 up to 1.
example : (3 : ℤ) + (-3) = 0 := by norm_num
example : ¬ ∃ b : ℤ, 2 * b = 1 := by omega

-- The 12-hour clock: 9 + 5 reads as 2, and the undo of 7 is 5.
example : (9 + 5 : ZMod 12) = 2 := by decide
example : (7 + 5 : ZMod 12) = 0 := by decide

-- The 7-hour clock under multiplication: the undos of 1, 2, 3, 4, 5, 6 are 1, 4, 5, 2, 3, 6,
-- and 0 has no undo, since 0 times any hour is 0, never 1.
example : [(1, 1), (2, 4), (3, 5), (4, 2), (5, 3), (6, 6)].map (fun q : ZMod 7 × ZMod 7 => q.1 * q.2)
    = [1, 1, 1, 1, 1, 1] := by decide
example : ∀ b : ZMod 7, 0 * b ≠ 1 := by decide

-- The 6-hour clock without 0 is not closed: 2 times 3 is 0.
example : (2 * 3 : ZMod 6) = 0 := by decide

#print axioms tile_moves_form_a_nonabelian_group_of_eight
#print axioms tile_move_is_sign_then_shift
#print axioms nonzero_hours_of_prime_clock_form_a_group
