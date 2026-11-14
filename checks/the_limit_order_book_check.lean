-- The order book: the size-weighted mid equals the mid plus imbalance times half the spread, the imbalance lies strictly between -1 and 1, and an incoming buy leaves the book uncrossed.
import Mathlib.Data.Real.Basic
import Mathlib.Data.Set.Insert
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Ring
import Mathlib.Algebra.Order.Field.Basic

/-- Weighted mid identity. While both sides of the book hold orders (shares `Qb > 0` waiting at
the best bid `b`, shares `Qa > 0` waiting at the best ask `a`), the size-weighted mid
`(a Qb + b Qa) / (Qb + Qa)` equals the mid `m = (a + b) / 2` plus the imbalance
`I = (Qb - Qa) / (Qb + Qa)` times half the spread `s = a - b`. -/
theorem weighted_mid_eq_mid_add_imbalance_mul_half_spread (a b Qb Qa : ℝ)
    (hQb : 0 < Qb) (hQa : 0 < Qa) :
    (a * Qb + b * Qa) / (Qb + Qa)
      = (a + b) / 2 + (Qb - Qa) / (Qb + Qa) * ((a - b) / 2) := by
  have h : Qb + Qa ≠ 0 := by positivity
  field_simp
  ring

/-- While both sides hold orders, the top imbalance `I = (Qb - Qa) / (Qb + Qa)` lies strictly
between -1 and +1. -/
theorem imbalance_strictly_between_neg_one_and_one (Qb Qa : ℝ) (hQb : 0 < Qb) (hQa : 0 < Qa) :
    -1 < (Qb - Qa) / (Qb + Qa) ∧ (Qb - Qa) / (Qb + Qa) < 1 := by
  have h : 0 < Qb + Qa := by linarith
  constructor
  · rw [lt_div_iff₀ h]; linarith
  · rw [div_lt_one h]; linarith

/-- Step 1 of the card: the book never ends up crossed after a buy. Start from an uncrossed book
(every bid price `B` below every ask price `A`). An incoming buy with limit `p` only removes asks,
so the asks left over `A'` are a subset of `A`. It stops either with nothing resting, so the bids
are unchanged, or because every ask left is above `p`, and then its rest joins the bids at `p`.
Either way every bid left is below every ask left. -/
theorem buy_leaves_book_uncrossed (B A B' A' : Set ℝ) (p : ℝ)
    (huncrossed : ∀ b ∈ B, ∀ a ∈ A, b < a) (hA' : A' ⊆ A)
    (hstop : B' = B ∨ (B' = insert p B ∧ ∀ a ∈ A', p < a)) :
    ∀ b ∈ B', ∀ a ∈ A', b < a := by
  intro b hb a ha
  rcases hstop with rfl | ⟨rfl, hp⟩
  · exact huncrossed b hb a (hA' ha)
  · rcases hb with rfl | hb
    · exact hp a ha
    · exact huncrossed b hb a (hA' ha)

-- The card's book after order 10, prices in cents: bid 10000 x 200, ask 10001 x 50.
-- Top imbalance (200 - 50) / (200 + 50) = 0.600.
example : ((200 : ℚ) - 50) / (200 + 50) = 3 / 5 := by norm_num

-- Weighted mid by weights and by mid + I s/2 are both 10000.8 cents ($100.008).
example : ((10001 : ℚ) * 200 + 10000 * 50) / (200 + 50) = 50004 / 5 := by norm_num
example : ((10001 : ℚ) + 10000) / 2 + 3 / 5 * ((10001 - 10000) / 2) = 50004 / 5 := by norm_num

-- Depth over three levels: bids 200 + 200 + 300 = 700, asks 50 + 200 + 400 = 650.
example : 200 + 200 + 300 = 700 ∧ 50 + 200 + 400 = 650 := by decide

-- Every share accounted for: 2250 submitted = 1350 resting + 2 x 450 traded.
example : 2250 = 1350 + 2 * 450 := by decide

-- Order flow imbalance over orders 3 to 10 adds to +350 shares.
example : (100 : ℤ) - 300 + 200 - 100 + 0 + 350 - 100 + 200 = 350 := by decide

-- Imbalance snapshots: imbalance after order 6 is (300 - 400) / (300 + 400) = -1/7 (-0.143),
-- and after order 8 it is (300 - 50) / (300 + 50) = 5/7 (0.714).
example : ((300 : ℚ) - 400) / (300 + 400) = -1 / 7 := by norm_num
example : ((300 : ℚ) - 50) / (300 + 50) = 5 / 7 := by norm_num

#print axioms weighted_mid_eq_mid_add_imbalance_mul_half_spread
#print axioms imbalance_strictly_between_neg_one_and_one
#print axioms buy_leaves_book_uncrossed
