-- Why the factorisation is unique: every whole number above 1 is a product of primes, any two such prime lists are the same up to order, a prime dividing a product of primes is one of them, and in the world 1, 5, 9, 13, ... uniqueness fails at 441.
import Mathlib.Data.Nat.Factors
import Mathlib.Data.List.Prime
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Tactic.Simproc.Factors
import Mathlib.Tactic.IntervalCases

/-- The fundamental theorem of arithmetic. Every whole number n above 1 is a product of primes,
and in exactly one way: any two lists of primes that multiply to n hold the same primes the same
number of times, so one list is just the other in a different order. -/
theorem every_number_above_one_has_exactly_one_prime_list (n : ℕ) (hn : 1 < n) :
    (∃ l : List ℕ, (∀ p ∈ l, p.Prime) ∧ l.prod = n) ∧
      ∀ l₁ l₂ : List ℕ, (∀ p ∈ l₁, p.Prime) → l₁.prod = n →
        (∀ p ∈ l₂, p.Prime) → l₂.prod = n → l₁.Perm l₂ := by
  refine ⟨⟨n.primeFactorsList, fun p hp => Nat.prime_of_mem_primeFactorsList hp,
    Nat.prod_primeFactorsList (by omega)⟩, ?_⟩
  intro l₁ l₂ h₁ e₁ h₂ e₂
  exact (Nat.primeFactorsList_unique e₁ h₁).trans (Nat.primeFactorsList_unique e₂ h₂).symm

/-- Step 3 of the proof: Euclid's lemma run along a list. If a prime p divides a product of
primes, then p divides one of them, and since that one is prime, p is equal to it: p is on the
list. -/
theorem prime_dividing_a_product_of_primes_is_on_the_list (p : ℕ) (hp : p.Prime) (l : List ℕ)
    (hl : ∀ q ∈ l, q.Prime) (h : p ∣ l.prod) : p ∈ l := by
  induction l with
  | nil =>
    simp at h
    exact absurd h hp.one_lt.ne'
  | cons x t ih =>
    rw [List.prod_cons] at h
    rcases (Nat.Prime.dvd_mul hp).mp h with h1 | h1
    · have := (Nat.prime_dvd_prime_iff_eq hp (hl x (by simp))).mp h1
      simp [this]
    · exact List.mem_cons_of_mem _ (ih (fun q hq => hl q (List.mem_cons_of_mem _ hq)) h1)

/-- A world where uniqueness is false: keep only 1, 5, 9, 13, ... (the numbers that leave 1 on
division by 4). 9, 21 and 49 live there and cannot be split into two members of that world other
than 1 and themselves, yet 441 = 9 × 49 = 21 × 21, two lists that are not the same up to order,
because 9 divides 21 × 21 without dividing 21. -/
theorem uniqueness_fails_in_the_one_mod_four_world :
    (∀ m ∈ [9, 21, 49], m % 4 = 1 ∧
        ∀ a b : ℕ, a % 4 = 1 → b % 4 = 1 → a * b = m → a = 1 ∨ b = 1) ∧
      9 * 49 = 441 ∧ 21 * 21 = 441 ∧ ¬ [9, 49].Perm [21, 21] ∧
      9 ∣ 21 * 21 ∧ ¬ 9 ∣ 21 := by
  refine ⟨?_, by norm_num, by norm_num, ?_, by decide, by decide⟩
  · intro m hm
    simp only [List.mem_cons, List.not_mem_nil, or_false] at hm
    rcases hm with rfl | rfl | rfl
    all_goals
      refine ⟨by norm_num, ?_⟩
      intro a b ha hb hab
      have hle : a ≤ _ := Nat.le_of_dvd (by norm_num) ⟨b, hab.symm⟩
      interval_cases a <;> omega
  · intro h
    have := (List.perm_iff_count.mp h) 9
    simp at this

-- A day is 86,400 seconds: 24 × 3,600 and 1,440 × 60.
example : 24 * 3600 = 86400 ∧ 1440 * 60 = 86400 := by norm_num
-- Each branch, split to primes.
example : [2, 2, 2, 3].prod = 24 ∧ [2, 2, 2, 2, 3, 3, 5, 5].prod = 3600 := by decide
example : [2, 2, 2, 2, 2, 3, 3, 5].prod = 1440 ∧ [2, 2, 3, 5].prod = 60 := by decide
-- Both trees pool to the same twelve leaves: seven 2s, three 3s, two 5s.
example : ([2, 2, 2, 3] ++ [2, 2, 2, 2, 3, 3, 5, 5]).Perm
    ([2, 2, 2, 2, 2, 3, 3, 5] ++ [2, 2, 3, 5]) := by decide
example : Nat.primeFactorsList 86400 = [2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 5, 5] := by
  simp [Nat.primeFactorsList_ofNat]
example : [2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 5, 5].length = 12 ∧
    [2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 5, 5].count 2 = 7 ∧
    [2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 5, 5].count 3 = 3 ∧
    [2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 5, 5].count 5 = 2 := by decide
example : Nat.Prime 2 ∧ Nat.Prime 3 ∧ Nat.Prime 5 := by norm_num
-- Multiplied back: 128 × 27 × 25 = 86,400.
example : 2 ^ 7 = 128 ∧ 3 ^ 3 = 27 ∧ 5 ^ 2 = 25 ∧ 128 * 27 * 25 = 86400 := by norm_num
-- Stopping at 24 × 3,600 leaves 2 pieces that still split.
example : ¬ Nat.Prime 24 ∧ ¬ Nat.Prime 3600 := by norm_num
-- Letting 1 in pads the list to 13, then 14, with the product unchanged; 1 is not a prime.
example : (1 :: [2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 5, 5]).prod = 86400 ∧
    (1 :: [2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 5, 5]).length = 13 ∧
    (1 :: 1 :: [2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 5, 5]).prod = 86400 ∧
    (1 :: 1 :: [2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 5, 5]).length = 14 ∧ ¬ Nat.Prime 1 := by
  norm_num
-- Euclid's lemma on the day: 3 divides 86,400, and it divides 24.
example : 3 ∣ 86400 ∧ 3 ∣ 24 := by decide
-- The world 1, 5, 9, 13, ...: 441 = 9 × 49 = 21 × 21, and 9 divides 21 × 21 but not 21.
example : 9 * 49 = 441 ∧ 21 * 21 = 441 ∧ 9 ∣ 21 * 21 ∧ ¬ 9 ∣ 21 := by decide
-- Grow a third tree: 96 × 900 also makes 86,400.
example : 96 * 900 = 86400 := by norm_num

#print axioms every_number_above_one_has_exactly_one_prime_list
#print axioms prime_dividing_a_product_of_primes_is_on_the_list
#print axioms uniqueness_fails_in_the_one_mod_four_world
