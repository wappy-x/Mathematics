-- Prime factorisation: every whole number bigger than 1 is a product of primes, and any two lists of primes with that product are the same list apart from order.
import Mathlib.Data.Nat.Factors
import Mathlib.Tactic.Simproc.Factors
import Mathlib.Tactic.NormNum.Prime
import Mathlib.NumberTheory.Divisors

/-- The fundamental theorem of arithmetic, as the card states it: every whole number bigger
than 1 is a product of primes (the factor tree always finishes), and apart from the order it
is that product and no other (every route ends at the same primes, repeats and all). -/
theorem prime_factorisation_exists_unique (n : ℕ) (hn : 1 < n) :
    ∃ l : List ℕ, (∀ p ∈ l, p.Prime) ∧ l.prod = n ∧
      ∀ l' : List ℕ, (∀ p ∈ l', p.Prime) → l'.prod = n → l'.Perm l := by
  refine ⟨Nat.primeFactorsList n, fun p hp => Nat.prime_of_mem_primeFactorsList hp,
    Nat.prod_primeFactorsList (by omega), fun l' hl' hprod => ?_⟩
  exact Nat.primeFactorsList_unique hprod hl'

/-- The splitting always finishes: every whole number bigger than 1 can be split until every
piece is prime, so it is a product of a list of primes. -/
theorem factor_tree_finishes (n : ℕ) (hn : 1 < n) :
    ∃ l : List ℕ, (∀ p ∈ l, p.Prime) ∧ l.prod = n := by
  exact ⟨Nat.primeFactorsList n, fun p hp => Nat.prime_of_mem_primeFactorsList hp,
    Nat.prod_primeFactorsList (by omega)⟩

/-- Every route reaches the same atoms: two lists of primes with the same product hold the
same primes, each the same number of times, so they match once sorted. -/
theorem same_primes_whichever_route (l₁ l₂ : List ℕ) (h₁ : ∀ p ∈ l₁, p.Prime)
    (h₂ : ∀ p ∈ l₂, p.Prime) (h : l₁.prod = l₂.prod) : l₁.Perm l₂ := by
  exact (Nat.primeFactorsList_unique h h₁).trans (Nat.primeFactorsList_unique rfl h₂).symm

-- 360 = 2 × 2 × 2 × 3 × 3 × 5, and those six are primes.
example : 2 * 2 * 2 * 3 * 3 * 5 = 360 := by norm_num
example : Nat.Prime 2 ∧ Nat.Prime 3 ∧ Nat.Prime 5 := by norm_num
example : Nat.primeFactorsList 360 = [2, 2, 2, 3, 3, 5] := by simp
-- Road one: take out a 2 three times, then a 3 twice: 180, 90, 45, 15, 5.
example : 360 / 2 = 180 ∧ 180 / 2 = 90 ∧ 90 / 2 = 45 ∧ 45 / 3 = 15 ∧ 15 / 3 = 5 := by norm_num
-- Road two, the hand tree: 360 = 6 × 60, 60 = 6 × 10, 6 = 2 × 3, 10 = 2 × 5.
example : 6 * 60 = 360 ∧ 6 * 10 = 60 ∧ 2 * 3 = 6 ∧ 2 * 5 = 10 := by norm_num
-- The three roads end at the same primes once sorted.
example : [2, 3, 2, 3, 2, 5].Perm [2, 2, 2, 3, 3, 5] := by decide
example : [5, 3, 3, 2, 2, 2].Perm [2, 2, 2, 3, 3, 5] := by decide
-- 360 has 24 divisors: 24 equal whole-degree cuts of a circle.
example : (Nat.divisors 360).card = 24 := by decide
-- Stopping at 36 × 10 gives 360, but neither piece is prime.
example : 36 * 10 = 360 ∧ ¬ Nat.Prime 36 ∧ ¬ Nat.Prime 10 := by norm_num
-- Dropping one 2 gives 180; listing each prime once gives 30.
example : 2 * 2 * 3 * 3 * 5 = 180 := by norm_num
example : 2 * 3 * 5 = 30 := by norm_num
-- 7 is already finished: a tree with no branches.
example : Nat.Prime 7 := by norm_num

#print axioms prime_factorisation_exists_unique
#print axioms factor_tree_finishes
#print axioms same_primes_whichever_route
