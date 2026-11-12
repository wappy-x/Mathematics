-- Counting divisors: for every positive whole number n, the number of positive divisors of n is the product, over the primes in n's factorisation, of one more than how many times that prime appears; the count is odd exactly when n is a square, and otherwise the rectangle shapes are half the divisors.
import Mathlib.NumberTheory.ArithmeticFunction.Misc
import Mathlib.NumberTheory.Divisors
import Mathlib.Algebra.Group.Even
import Mathlib.Tactic.NormNum.Prime

open Finset

theorem cd_card_antidiag (n : ℕ) (hn : 0 < n) : #n.divisorsAntidiagonal = #n.divisors := by
  rw [← Nat.image_fst_divisorsAntidiagonal]
  symm
  apply Finset.card_image_of_injOn
  intro p hp q hq h
  have h1 := (Nat.mem_divisorsAntidiagonal.mp hp).1
  have h2 := (Nat.mem_divisorsAntidiagonal.mp hq).1
  have hp1 : 0 < p.1 := Nat.pos_of_ne_zero (Nat.left_ne_zero_of_mem_divisorsAntidiagonal hp)
  have h' : p.1 = q.1 := h
  have : p.2 = q.2 := by
    apply Nat.eq_of_mul_eq_mul_left hp1
    rw [h1, h', h2]
  exact Prod.ext h' this

theorem cd_gt_eq_lt (n : ℕ) :
    #(n.divisorsAntidiagonal.filter (fun p => p.2 < p.1)) =
      #(n.divisorsAntidiagonal.filter (fun p => p.1 < p.2)) := by
  apply Finset.card_nbij' Prod.swap Prod.swap
  · intro p hp
    simp only [Finset.mem_coe, Finset.mem_filter, Nat.swap_mem_divisorsAntidiagonal] at hp ⊢
    exact ⟨hp.1, by simpa using hp.2⟩
  · intro p hp
    simp only [Finset.mem_coe, Finset.mem_filter, Nat.swap_mem_divisorsAntidiagonal] at hp ⊢
    exact ⟨hp.1, by simpa using hp.2⟩
  · intro p _; simp
  · intro p _; simp

theorem cd_key (n : ℕ) (hn : 0 < n) :
    2 * #(n.divisorsAntidiagonal.filter (fun p => p.1 ≤ p.2)) =
      #n.divisors + #(n.divisorsAntidiagonal.filter (fun p => p.1 = p.2)) := by
  have h1 := Finset.card_filter_add_card_filter_not (s := n.divisorsAntidiagonal)
    (fun p : ℕ × ℕ => p.1 ≤ p.2)
  have h2 : (n.divisorsAntidiagonal.filter (fun p => ¬ p.1 ≤ p.2)) =
      n.divisorsAntidiagonal.filter (fun p => p.2 < p.1) := by
    apply Finset.filter_congr; intro p _; simp
  have h3 := Finset.card_filter_add_card_filter_not
    (s := n.divisorsAntidiagonal.filter (fun p => p.1 ≤ p.2)) (fun p : ℕ × ℕ => p.1 = p.2)
  have h4 : (n.divisorsAntidiagonal.filter (fun p => p.1 ≤ p.2)).filter (fun p => p.1 = p.2)
      = n.divisorsAntidiagonal.filter (fun p => p.1 = p.2) := by
    ext p; simp only [Finset.mem_filter]; constructor
    · rintro ⟨⟨a, _⟩, c⟩; exact ⟨a, c⟩
    · rintro ⟨a, c⟩; exact ⟨⟨a, c.le⟩, c⟩
  have h5 : (n.divisorsAntidiagonal.filter (fun p => p.1 ≤ p.2)).filter (fun p => ¬ p.1 = p.2)
      = n.divisorsAntidiagonal.filter (fun p => p.1 < p.2) := by
    ext p; simp only [Finset.mem_filter]; constructor
    · rintro ⟨⟨a, b⟩, c⟩; exact ⟨a, lt_of_le_of_ne b c⟩
    · rintro ⟨a, c⟩; exact ⟨⟨a, c.le⟩, c.ne⟩
  rw [h2, cd_gt_eq_lt] at h1
  rw [h4, h5] at h3
  rw [← cd_card_antidiag n hn]
  omega

theorem cd_eq_nonsquare (n : ℕ) (hsq : ¬ IsSquare n) :
    #(n.divisorsAntidiagonal.filter (fun p => p.1 = p.2)) = 0 := by
  rw [Finset.card_eq_zero, Finset.filter_eq_empty_iff]
  intro p hp h
  apply hsq
  exact ⟨p.1, by rw [← (Nat.mem_divisorsAntidiagonal.mp hp).1, ← h]⟩

theorem cd_eq_square (n : ℕ) (hn : 0 < n) (hsq : IsSquare n) :
    #(n.divisorsAntidiagonal.filter (fun p => p.1 = p.2)) = 1 := by
  obtain ⟨m, rfl⟩ := hsq
  rw [Finset.card_eq_one]
  refine ⟨(m, m), ?_⟩
  ext p
  simp only [Finset.mem_filter, Nat.mem_divisorsAntidiagonal, Finset.mem_singleton]
  constructor
  · rintro ⟨⟨h, _⟩, h2⟩
    obtain ⟨a, b⟩ := p
    simp only at h h2
    subst h2
    have : a * a = m * m := h
    have : a = m := by nlinarith [Nat.mul_self_le_mul_self_iff (m := a) (n := m)]
    simp [this]
  · rintro rfl
    exact ⟨⟨rfl, hn.ne'⟩, rfl⟩

#print axioms cd_card_antidiag
#print axioms cd_gt_eq_lt
#print axioms cd_key
#print axioms cd_eq_nonsquare
#print axioms cd_eq_square

/-- Counting divisors. Take any positive whole number n and break it all the way down to primes.
For each prime, add one to how many times it appears in the factorisation, then multiply those
numbers together: the result is how many positive divisors n has. -/
theorem card_divisors_eq_prod_factorization_add_one (n : ℕ) (hn : 0 < n) :
    #n.divisors = ∏ p ∈ n.primeFactors, (n.factorization p + 1) := by
  exact Nat.card_divisors hn.ne'

/-- A square has one side that pairs with itself, so its count is odd: a positive whole number
has an odd number of positive divisors exactly when it is a square. -/
theorem card_divisors_odd_iff_is_square (n : ℕ) (hn : 0 < n) :
    Odd #n.divisors ↔ IsSquare n := by
  have key := cd_key n hn
  by_cases hsq : IsSquare n
  · have := cd_eq_square n hn hsq
    simp only [hsq, iff_true]
    rw [this] at key
    exact ⟨#(n.divisorsAntidiagonal.filter (fun p => p.1 ≤ p.2)) - 1, by omega⟩
  · have := cd_eq_nonsquare n hsq
    rw [this] at key
    simp only [hsq, iff_false, Nat.not_odd_iff_even]
    exact ⟨#(n.divisorsAntidiagonal.filter (fun p => p.1 ≤ p.2)), by omega⟩

/-- Divisors pair off, each pair multiplying to n. A rectangle shape is one such pair a × b = n,
with turning it round not counted as new (so a ≤ b). When n is positive and not a square, the
number of shapes is exactly half the number of divisors. -/
theorem shapes_are_half_the_divisors_when_not_square (n : ℕ) (hn : 0 < n) (hsq : ¬ IsSquare n) :
    2 * #(n.divisorsAntidiagonal.filter (fun p => p.1 ≤ p.2)) = #n.divisors := by
  have key := cd_key n hn
  rw [cd_eq_nonsquare n hsq] at key
  omega

-- The box: 96 = 2 × 2 × 2 × 2 × 2 × 3, five 2s and one 3.
example : (96 : ℕ) = 2 * 2 * 2 * 2 * 2 * 3 ∧ (96 : ℕ) = 2 ^ 5 * 3 ^ 1 := by norm_num
-- (5 + 1) × (1 + 1) = 12, and 96 really has 12 divisors.
example : (5 + 1) * (1 + 1) = 12 ∧ #(Nat.divisors 96) = 12 := by decide
-- The 12 divisors of 96, listed.
example : Nat.divisors 96 = {1, 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 96} := by decide
-- The grid: 2 ^ i × 3 ^ j, i from 0 to 5 and j from 0 to 1, fills every cell exactly once.
example : (range 6 ×ˢ range 2).image (fun ij : ℕ × ℕ => 2 ^ ij.1 * 3 ^ ij.2) = Nat.divisors 96 ∧
    #((range 6 ×ˢ range 2).image (fun ij : ℕ × ℕ => 2 ^ ij.1 * 3 ^ ij.2)) = 6 * 2 := by decide
-- The six rectangles: 1 by 96, 2 by 48, 3 by 32, 4 by 24, 6 by 16, 8 by 12.
example : (Nat.divisorsAntidiagonal 96).filter (fun p => p.1 ≤ p.2) =
    {(1, 96), (2, 48), (3, 32), (4, 24), (6, 16), (8, 12)} := by decide
example : #((Nat.divisorsAntidiagonal 96).filter (fun p => p.1 ≤ p.2)) = 12 / 2 := by decide
-- 360 = 2 × 2 × 2 × 3 × 3 × 5, so (3 + 1) × (2 + 1) × (1 + 1) = 24 divisors.
example : (360 : ℕ) = 2 ^ 3 * 3 ^ 2 * 5 ^ 1 ∧ (3 + 1) * (2 + 1) * (1 + 1) = 24 := by norm_num
example : #(Nat.divisors 360) = 24 := by decide
-- Adding the divisors: 1 + 2 + 4 + 8 + 16 + 32 = 63, and the whole grid adds to 63 × 4 = 252.
example : 1 + 2 + 4 + 8 + 16 + 32 = 63 ∧ 63 * 3 = 189 ∧ ∑ d ∈ Nat.divisors 96, d = 63 * 4 ∧
    63 * 4 = 252 := by decide
-- The three mistakes come out at 5, 8 and 10.
example : 5 * 1 = 5 ∧ (5 + 1) + (1 + 1) = 8 ∧ #((Nat.divisors 96).erase 1 |>.erase 96) = 10 := by
  decide
-- Try changing: 100 = 2 × 2 × 5 × 5 has (2 + 1) × (2 + 1) = 9 divisors, an odd count, as 10 × 10 = 100.
example : (100 : ℕ) = 2 ^ 2 * 5 ^ 2 ∧ #(Nat.divisors 100) = (2 + 1) * (2 + 1) ∧ 10 * 10 = 100 := by
  decide
-- 97 is prime, so it splits no way but 1 by 97.
example : Nat.Prime 97 := by norm_num
example : #(Nat.divisors 97) = 2 := by decide

#print axioms card_divisors_eq_prod_factorization_add_one
#print axioms card_divisors_odd_iff_is_square
#print axioms shapes_are_half_the_divisors_when_not_square
