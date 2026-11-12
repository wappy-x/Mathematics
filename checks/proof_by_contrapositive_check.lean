-- Proof by contrapositive: an if-then and its contrapositive are the same claim, so if a whole number times itself is odd, the number is odd.
import Mathlib.Algebra.Ring.Parity
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Data.Finset.Card

/-- An if-then and its contrapositive are one claim: when each half is either true or false,
"if A then B" holds exactly when "if not B then not A" holds. -/
theorem imp_iff_contrapositive (A B : Prop) (hA : A ∨ ¬A) (hB : B ∨ ¬B) :
    (A → B) ↔ (¬B → ¬A) := by
  constructor
  · intro h hnB ha
    exact hnB (h ha)
  · intro h ha
    rcases hB with hb | hnb
    · exact hb
    · exact absurd ha (h hnb)

/-- The twin claim: for every whole number n, if n × n is odd, then n is odd. -/
theorem odd_of_odd_mul_self (n : ℕ) (h : Odd (n * n)) : Odd n := by
  by_contra hn
  rw [Nat.not_odd_iff_even] at hn
  exact (Nat.not_even_iff_odd.mpr h) (hn.mul_right n)

/-- The flipped version the card actually proves: for every whole number n,
if n is even, then n × n is even. -/
theorem even_mul_self_of_even (n : ℕ) (h : Even n) : Even (n * n) := by
  exact h.mul_right n

-- The four drivers as (validated, paid nothing). An if-then is kept unless the if part holds
-- and the then part fails. The sign reads 1, 0, 1, 1.
example : [(true, true), (true, false), (false, true), (false, false)].map
    (fun p : Bool × Bool => !p.1 || p.2) = [true, false, true, true] := by decide

-- The contrapositive (paid something, so not validated) reads 1, 0, 1, 1: it disagrees on nobody.
example : [(true, true), (true, false), (false, true), (false, false)].map
    (fun p : Bool × Bool => !(!p.2) || !p.1) = [true, false, true, true] := by decide

-- The converse (paid nothing, so validated) reads 1, 1, 0, 1: it disagrees on Wes and Yaz, 2 rows.
example : [(true, true), (true, false), (false, true), (false, false)].map
    (fun p : Bool × Bool => !p.2 || p.1) = [true, true, false, true] := by decide
example : (([(true, true), (true, false), (false, true), (false, false)].map
    (fun p : Bool × Bool => ((!p.1 || p.2) != (!p.2 || p.1)))).filter id).length = 2 := by decide

-- The twin claim at n = 6: 6 = 2 × 3, so 6 × 6 = 2 × (3 × 6) = 2 × 18 = 36, even.
example : (6 : ℕ) = 2 * 3 ∧ 6 * 6 = 2 * (3 * 6) ∧ 2 * (3 * 6) = 2 * 18 ∧ 2 * 18 = (36 : ℕ) := by
  decide
example : Even (6 * 6 : ℕ) := by decide

-- 7 × 7 = 49, odd: it agrees with the claim and proves nothing.
example : (7 : ℕ) * 7 = 49 ∧ Odd (7 * 7 : ℕ) := by decide

-- Of the whole numbers 1 to 20, exactly 10 have n × n odd, and they are exactly the odd ones.
example : ((Finset.Icc 1 20).filter (fun n : ℕ => (n * n) % 2 = 1)).card = 10 := by decide
example : (Finset.Icc 1 20).filter (fun n : ℕ => (n * n) % 2 = 1)
    = (Finset.Icc 1 20).filter (fun n : ℕ => n % 2 = 1) := by decide

#print axioms imp_iff_contrapositive
#print axioms odd_of_odd_mul_self
#print axioms even_mul_self_of_even
