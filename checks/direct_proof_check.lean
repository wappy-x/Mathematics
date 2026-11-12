-- Direct proof: two even whole numbers always add to an even number, and an 8 by 8 chessboard has 32 black and 32 white squares.
import Mathlib.Algebra.Group.Nat.Even
import Mathlib.Data.Finset.Prod
import Mathlib.Data.Finset.Card

/-- Two even counts add to an even count: if m and n are both even whole numbers,
then m + n is even. -/
theorem even_add_even (m n : ℕ) (hm : Even m) (hn : Even n) : Even (m + n) := by
  obtain ⟨a, ha⟩ := hm
  obtain ⟨b, hb⟩ := hn
  exact ⟨a + b, by omega⟩

/-- Proof by cases on a chessboard: on an 8 by 8 board coloured alternately, with the
square in row r and column c black when r + c is even, exactly 32 squares are black. -/
theorem chessboard_black_squares :
    ((Finset.range 8 ×ˢ Finset.range 8).filter (fun p : ℕ × ℕ => (p.1 + p.2) % 2 = 0)).card
      = 32 := by
  decide

/-- The same board has exactly 32 white squares, those where r + c is odd. -/
theorem chessboard_white_squares :
    ((Finset.range 8 ×ˢ Finset.range 8).filter (fun p : ℕ × ℕ => (p.1 + p.2) % 2 = 1)).card
      = 32 := by
  decide

-- The egg trays: 12 = 2 × 6 and 18 = 2 × 9, and the proof's chain gives 30 = 2 × 15.
example : (12 : ℕ) = 2 * 6 ∧ (18 : ℕ) = 2 * 9 := by decide
example : (12 : ℕ) + 18 = 2 * 6 + 2 * 9 ∧ 2 * 6 + 2 * 9 = 2 * (6 + 9) ∧
    2 * (6 + 9) = 2 * 15 ∧ 2 * 15 = (30 : ℕ) := by decide
example : Even (12 + 18 : ℕ) := by decide

-- Thirty eggs make 15 pairs with none over.
example : (30 : ℕ) / 2 = 15 ∧ (30 : ℕ) % 2 = 0 := by decide

-- One tray odd: 12 + 15 = 27, which is 13 pairs and 1 over, so not even.
example : (12 : ℕ) + 15 = 27 ∧ (27 : ℕ) = 2 * 13 + 1 := by decide
example : ¬ Even (12 + 15 : ℕ) := by decide

-- The 2 pulled from one part only: 2 × 6 + 9 = 21, not 30.
example : 2 * 6 + 9 = (21 : ℕ) := by decide

-- Each row has 4 black and 4 white; 8 rows give 32 and 32; only half the rows give 16.
example : ((Finset.range 8).filter (fun c : ℕ => c % 2 = 0)).card = 4 := by decide
example : ((Finset.range 8).filter (fun c : ℕ => c % 2 = 1)).card = 4 := by decide
example : 8 * 4 = (32 : ℕ) ∧ 4 * 4 = (16 : ℕ) ∧ 32 + 32 = (64 : ℕ) := by decide

#print axioms even_add_even
#print axioms chessboard_black_squares
#print axioms chessboard_white_squares
