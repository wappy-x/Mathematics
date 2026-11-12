-- Divides: for whole numbers, a divides b exactly when b is a times a whole number, which is the same as leaving no remainder; divisors of a number come in pairs, one of each pair at most its square root; and 1 divides everything, everything divides 0, and 0 divides only 0.
import Mathlib.NumberTheory.Divisors
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

/-- One number divides another when the second is the first multiplied by a whole number, with
nothing left over: a divides b exactly when b = a × k for some whole number k, and exactly when
the leftover b mod a is 0. -/
theorem divides_iff_whole_multiple_iff_no_leftover (a b : ℕ) :
    (a ∣ b ↔ ∃ k : ℕ, b = a * k) ∧ (a ∣ b ↔ b % a = 0) := by
  refine ⟨Iff.rfl, Nat.dvd_iff_mod_eq_zero⟩

/-- Divisors arrive in pairs: if a divides n (n counted from 1 up), so does its partner n / a,
the two multiply back to n, the partner's partner is a again, and one of the pair is at most the
square root of n, which is why testing can stop once a × a passes n. -/
theorem divisors_come_in_pairs (n a : ℕ) (ha : a ∈ n.divisors) :
    n / a ∈ n.divisors ∧ a * (n / a) = n ∧ n / (n / a) = a ∧
      (a * a ≤ n ∨ (n / a) * (n / a) ≤ n) := by
  rw [Nat.mem_divisors] at ha
  obtain ⟨hd, hn⟩ := ha
  have hdiv : n / a ∈ n.divisors := by
    rw [Nat.mem_divisors]
    exact ⟨Nat.div_dvd_of_dvd hd, hn⟩
  have hmul : a * (n / a) = n := Nat.mul_div_cancel' hd
  have hapos : 0 < a := Nat.pos_of_ne_zero (by
    rintro rfl
    exact hn (Nat.eq_zero_of_zero_dvd hd))
  refine ⟨hdiv, hmul, ?_, ?_⟩
  · exact Nat.div_div_self hd hn
  · by_contra h
    push_neg at h
    obtain ⟨h1, h2⟩ := h
    have : n * n < (a * (n / a)) * (a * (n / a)) := by
      calc n * n < (a * a) * ((n / a) * (n / a)) := Nat.mul_lt_mul'' h1 h2
        _ = (a * (n / a)) * (a * (n / a)) := by ring
    rw [hmul] at this
    exact lt_irrefl _ this

/-- The strange ones: 1 divides every number, every number divides 0, and 0 divides only 0. -/
theorem one_and_zero (n : ℕ) : 1 ∣ n ∧ n ∣ 0 ∧ (0 ∣ n ↔ n = 0) := by
  refine ⟨one_dvd n, dvd_zero n, ?_⟩
  constructor
  · intro h
    exact Nat.eq_zero_of_zero_dvd h
  · rintro rfl
    exact dvd_refl 0

-- The formula: 60 = 4 × 15, so 4 divides 60.
example : (60 : ℕ) = 4 * 15 ∧ (4 : ℕ) ∣ 60 := by decide
-- 60 = 8 × 7 + 4, so 8 does not divide 60.
example : (60 : ℕ) = 8 * 7 + 4 ∧ (60 : ℕ) / 8 = 7 ∧ (60 : ℕ) % 8 = 4 ∧ ¬ (8 : ℕ) ∣ 60 := by decide
-- The order is kept: 12 divides 60, but 60 does not divide 12.
example : (12 : ℕ) ∣ 60 ∧ ¬ (60 : ℕ) ∣ 12 := by decide
-- 1 divides 60, 60 divides 0, 0 does not divide 60, 0 divides 0.
example : (1 : ℕ) ∣ 60 ∧ (60 : ℕ) ∣ 0 ∧ ¬ (0 : ℕ) ∣ 60 ∧ (0 : ℕ) ∣ 0 := by decide
-- The six pairs: 1 × 60, 2 × 30, 3 × 20, 4 × 15, 5 × 12, 6 × 10; 7 leaves 4 over.
example : (1 : ℕ) * 60 = 60 ∧ (2 : ℕ) * 30 = 60 ∧ (3 : ℕ) * 20 = 60 ∧ (4 : ℕ) * 15 = 60 ∧
    (5 : ℕ) * 12 = 60 ∧ (6 : ℕ) * 10 = 60 ∧ (60 : ℕ) = 7 * 8 + 4 := by decide
-- Stop testing at 7: 8 × 8 = 64 is past 60.
example : (8 : ℕ) * 8 = 64 ∧ 60 < 8 * 8 ∧ 7 * 7 ≤ 60 := by decide
-- The twelve divisors of 60, and only those.
example : Nat.divisors 60 = {1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 60} := by decide
example : (Nat.divisors 60).card = 12 := by decide
-- Listing only the lengths tested, 1 to 6, finds 6 of the 12.
example : ((Nat.divisors 60).filter (· ≤ 6)).card = 6 := by decide
-- Try changing: a 59-minute hour has only 1 and 59.
example : Nat.divisors 59 = {1, 59} := by decide

#print axioms divides_iff_whole_multiple_iff_no_leftover
#print axioms divisors_come_in_pairs
#print axioms one_and_zero
