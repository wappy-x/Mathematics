-- Choosing a proof strategy: there is exactly one whole number that leaves every sum unchanged, any two such numbers are equal, and every whole number is even or odd.
import Mathlib.Algebra.Ring.Parity
import Mathlib.Data.Finset.Card

/-- Exactly one do-nothing for adding: there is exactly one whole number z that, added to
any whole number n on either side, leaves it unchanged (z + n = n and n + z = n). -/
theorem exists_unique_additive_identity :
    ∃! z : ℕ, ∀ n : ℕ, z + n = n ∧ n + z = n := by
  refine ⟨0, fun n => ⟨Nat.zero_add n, Nat.add_zero n⟩, ?_⟩
  intro y hy
  have := (hy 0).1
  simpa using this

/-- The uniqueness job on its own: if a and b both leave every sum unchanged, then a = b
(read a + b twice: it is a because b does nothing, and b because a does nothing). -/
theorem do_nothings_are_equal (a b : ℕ)
    (ha : ∀ n : ℕ, a + n = n ∧ n + a = n) (hb : ∀ n : ℕ, b + n = n ∧ n + b = n) :
    a = b := by
  have h1 := (ha b).2
  have h2 := (hb a).1
  rw [← h1, h2]

/-- Every whole number is even or odd. -/
theorem every_nat_even_or_odd (n : ℕ) : Even n ∨ Odd n := by
  exact Nat.even_or_odd n

-- Claim 1 by hand: 0 = 2 × 0 is even; 7 = 2 × 3 + 1 is odd; one step on, 8 = 2 × 4 is even.
example : (0 : ℕ) = 2 * 0 ∧ (7 : ℕ) = 2 * 3 + 1 ∧ (8 : ℕ) = 2 * 4 := by decide
example : Even (0 : ℕ) ∧ Odd (7 : ℕ) ∧ Even (8 : ℕ) := by decide
example : 2 * (3 + 1) = (8 : ℕ) := by decide

-- Every number from 0 to 40 is even or odd: all 41 of them.
example : ((Finset.range 41).filter (fun n : ℕ => Even n ∨ Odd n)).card = 41 := by decide

-- Claim 2, the witness checked: 0 + 7 = 7 and 0 + 23 = 23.
example : (0 : ℕ) + 7 = 7 ∧ (0 : ℕ) + 23 = 23 := by decide

-- A guessed witness that fails: 1 + 7 = 8, not 7.
example : (1 : ℕ) + 7 = 8 ∧ (1 : ℕ) + 7 ≠ 7 := by decide

-- Claim 3, the search: among the 41 candidates 0 to 40, exactly one leaves every sum
-- from 0 to 40 unchanged, and it is 0.
example : ((Finset.range 41).filter
    (fun z : ℕ => ∀ n ∈ Finset.range 41, z + n = n)).card = 1 := by decide
example : (Finset.range 41).filter
    (fun z : ℕ => ∀ n ∈ Finset.range 41, z + n = n) = {0} := by decide

#print axioms exists_unique_additive_identity
#print axioms do_nothings_are_equal
#print axioms every_nat_even_or_odd
