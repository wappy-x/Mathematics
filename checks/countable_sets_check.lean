-- Countable sets: the integers and the fractions each pair off exactly with the counting numbers, a set fits in one queue exactly when it is finite or pairs off with the counting numbers, the card's bounce-out-from-zero rule gives every integer exactly one room, and the card's room numbers for integers and fractions come out as it says.
import Mathlib.Data.Rat.Denumerable
import Mathlib.Basic.Finite.Defs
import Mathlib.Data.Nat.GCD.Basic

/-- The card's integer queue, read room to guest: room 1 holds 0, an even room `r` holds
`r / 2`, and an odd room `r` past the first holds `-((r - 1) / 2)`. -/
def intGuest (r : ℕ) : ℤ :=
  if r % 2 = 0 then ((r / 2 : ℕ) : ℤ) else -(((r - 1) / 2 : ℕ) : ℤ)

/-- The same queue read guest to room: 0 is in room 1, a positive `k` in room `2k`, and a
negative `k` in room `1 - 2k`. -/
def roomOf (k : ℤ) : ℕ :=
  if k = 0 then 1 else if 0 < k then (2 * k).toNat else (1 - 2 * k).toNat

/-- One diagonal of the fraction grid: the cells top/bottom whose top and bottom add to `h`,
by rising top. A cell is written as the pair (top, bottom). -/
def diagonal (h : ℕ) : List (ℕ × ℕ) :=
  (List.range' 1 (h - 1)).map fun t => (t, h - t)

/-- The card's fraction queue: 0 (written 0/1) in room 1, then the diagonals adding to
2, 3, ..., `n + 1`, with renamed cells (top and bottom sharing a factor) skipped. Room `r`
is entry `r - 1` of the list. -/
def fractionQueue (n : ℕ) : List (ℕ × ℕ) :=
  (0, 1) :: ((List.range' 2 n).flatMap diagonal).filter fun p => Nat.gcd p.1 p.2 = 1

/-- The same walk with the repeats left in. -/
def fractionQueueWithRepeats (n : ℕ) : List (ℕ × ℕ) :=
  (0, 1) :: (List.range' 2 n).flatMap diagonal

/-- The integers fit in one queue, and so do the fractions: each can be paired off with the
counting numbers, every member in exactly one place, the queue never ending. -/
theorem integers_and_fractions_fit_in_one_queue :
    Nonempty (ℕ ≃ ℤ) ∧ Nonempty (ℕ ≃ ℚ) := by
  exact ⟨⟨(Denumerable.eqv ℤ).symm⟩, ⟨(Denumerable.eqv ℚ).symm⟩⟩

/-- What "countable" means: a collection fits in one queue (Mathlib's `Countable`) exactly
when it is finite, so the queue stops, or it pairs off exactly with the counting numbers,
so the queue never stops. -/
theorem countable_iff_finite_or_pairs_with_counting_numbers (α : Type*) :
    Countable α ↔ Finite α ∨ Nonempty (α ≃ ℕ) := by
  constructor
  · intro h
    by_cases hf : Finite α
    · exact Or.inl hf
    · right
      have hi : Infinite α := not_finite_iff_infinite.mp hf
      exact nonempty_equiv_of_countable
  · rintro (h | h)
    · exact Finite.to_countable
    · obtain ⟨e⟩ := h
      exact e.injective.countable

/-- The card's bounce-out-from-zero queue is a real queue: every integer gets exactly one
room, a counting number 1, 2, 3, ..., and the room-from-guest rule finds that room. -/
theorem every_integer_gets_exactly_one_room :
    ∀ k : ℤ, (∃! r : ℕ, 1 ≤ r ∧ intGuest r = k) ∧ 1 ≤ roomOf k ∧ intGuest (roomOf k) = k := by
  have key : ∀ k : ℤ, 1 ≤ roomOf k ∧ intGuest (roomOf k) = k := by
    intro k
    unfold roomOf intGuest
    split_ifs <;> omega
  intro k
  refine ⟨⟨roomOf k, ⟨(key k).1, (key k).2⟩, ?_⟩, (key k).1, (key k).2⟩
  rintro r ⟨hr, h⟩
  unfold intGuest at h
  unfold roomOf
  split_ifs at h ⊢ <;> omega

-- The integer queue, rooms 1 to 9, and those integers read back.
example : (List.range' 1 9).map intGuest = [0, 1, -1, 2, -2, 3, -3, 4, -4] := by decide
example : [0, 1, -1, 2, -2, 3, -3, 4, -4].map roomOf = List.range' 1 9 := by decide
-- Worked numbers: 2 is in room 4, and -2 in room 5 (1 minus 2 times -2).
example : roomOf 2 = 4 ∧ roomOf (-2) = 5 := by decide
example : (1 : ℤ) - 2 * (-2) = 5 := by decide
-- The fraction queue, rooms 1 to 10.
example : fractionQueue 4 =
    [(0, 1), (1, 1), (1, 2), (2, 1), (1, 3), (3, 1), (1, 4), (2, 3), (3, 2), (4, 1)] := by
  decide
-- 1/2 is in room 3, 2/1 in room 4, 2/3 in room 8.
example : (fractionQueue 4)[2]? = some (1, 2) ∧ (fractionQueue 4)[3]? = some (2, 1) ∧
    (fractionQueue 4)[7]? = some (2, 3) := by decide
-- The grid, rows 1 to 3.
example : diagonal 2 = [(1, 1)] ∧ diagonal 3 = [(1, 2), (2, 1)] ∧
    diagonal 4 = [(1, 3), (2, 2), (3, 1)] := by decide
-- Repeats left in: 2/2 takes room 6.
example : (fractionQueueWithRepeats 3)[5]? = some (2, 2) := by decide
-- The 0 dropped: 1/2 takes room 2 and 2/1 room 3.
example : (fractionQueue 4).tail[1]? = some (1, 2) ∧ (fractionQueue 4).tail[2]? = some (2, 1) := by
  decide

#print axioms integers_and_fractions_fit_in_one_queue
#print axioms countable_iff_finite_or_pairs_with_counting_numbers
#print axioms every_integer_gets_exactly_one_room
