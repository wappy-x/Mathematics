-- Division with a remainder: for a whole number b and a divisor a of 1 or more, exactly one pair of whole numbers q and r gives b = q × a + r with r smaller than a, that pair is b / a and b % a, and without the rule r < a the answer is no longer one.
import Mathlib.Basic.ExistsUnique
import Mathlib.Data.Nat.Init

theorem aux_div_mod_unique (b a q r : ℕ) (ha : 1 ≤ a)
    (h : b = q * a + r) (hr : r < a) :
    q = b / a ∧ r = b % a := by
  have hpos : 0 < a := ha
  have hq : b / a = q := by
    rw [h, Nat.add_comm, Nat.add_mul_div_right _ _ hpos, Nat.div_eq_of_lt hr, Nat.zero_add]
  have hm := Nat.div_add_mod' b a
  refine ⟨hq.symm, ?_⟩
  rw [hq] at hm
  omega

#print axioms aux_div_mod_unique

/-- Division with a remainder. Take a whole number b (0 or more) and a divisor a (1 or more).
There is exactly one pair of whole numbers, a quotient q and a remainder r, with
b = q × a + r and r smaller than a. -/
theorem quotient_and_remainder_exist_and_are_unique (b a : ℕ) (ha : 1 ≤ a) :
    ∃! p : ℕ × ℕ, b = p.1 * a + p.2 ∧ p.2 < a := by
  refine ⟨(b / a, b % a), ⟨(Nat.div_add_mod' b a).symm, Nat.mod_lt _ ha⟩, ?_⟩
  rintro ⟨q, r⟩ ⟨h, hr⟩
  obtain ⟨h1, h2⟩ := aux_div_mod_unique b a q r ha h hr
  simp only [Prod.mk.injEq]
  exact ⟨h1, h2⟩

/-- The one pair is what whole-number division gives: if b = q × a + r with r smaller than a,
then q is b / a (whole copies, Python's //) and r is b % a (the leftover, Python's %). -/
theorem quotient_and_remainder_are_div_and_mod (b a q r : ℕ) (ha : 1 ≤ a)
    (h : b = q * a + r) (hr : r < a) :
    q = b / a ∧ r = b % a := by
  exact aux_div_mod_unique b a q r ha h hr

/-- Drop the rule that the leftover is under the divisor and the answer is no longer one:
whenever b is at least a, two different pairs (q, r) give b = q × a + r. -/
theorem without_leftover_rule_answer_is_not_unique (b a : ℕ) (ha : 1 ≤ a) (hb : a ≤ b) :
    ∃ p p' : ℕ × ℕ, p ≠ p' ∧ b = p.1 * a + p.2 ∧ b = p'.1 * a + p'.2 := by
  have hpos : 0 < a := ha
  have hq : 1 ≤ b / a := (Nat.le_div_iff_mul_le hpos).2 (by omega)
  obtain ⟨k, hk⟩ : ∃ k, b / a = k + 1 := ⟨b / a - 1, by omega⟩
  have hm := Nat.div_add_mod' b a
  rw [hk] at hm
  refine ⟨(k + 1, b % a), (k, b % a + a), ?_, ?_, ?_⟩
  · simp
  · simp only; omega
  · simp only; rw [Nat.add_mul] at hm; omega

-- An ordinary year: 365 = 52 × 7 + 1, and 1 is smaller than 7.
example : 365 = 52 * 7 + 1 ∧ 1 < 7 := by decide
-- A leap year: 366 = 52 × 7 + 2, and 2 is smaller than 7.
example : 366 = 52 * 7 + 2 ∧ 2 < 7 := by decide
-- The code's // and %: 52 weeks with 1 day over, then 52 weeks with 2 days over.
example : 365 / 7 = 52 ∧ 365 % 7 = 1 ∧ 366 / 7 = 52 ∧ 366 % 7 = 2 := by decide
-- Whole weeks in a year, and the days over.
example : 52 * 7 = 364 ∧ 365 - 364 = 1 ∧ 366 - 364 = 2 := by decide
-- Stopping at 51 weeks: 365 = 51 × 7 + 8 is true arithmetic, but 8 is not under 7.
example : 365 = 51 * 7 + 8 ∧ ¬ (8 < 7) := by decide
-- Trying every week count from 0 to 99: only 52 leaves a leftover under 7, and that leftover is 1.
example : (List.range 100).filter (fun q => 7 * q ≤ 365 ∧ 365 - 7 * q < 7) = [52] ∧
    365 - 7 * 52 = 1 := by decide
-- The birthday drifts 0, then 1, then 3, then 4 weekdays (Sunday, Monday, Wednesday, Thursday).
example : (0 + 365 % 7) % 7 = 1 ∧ (1 + 366 % 7) % 7 = 3 ∧ (3 + 365 % 7) % 7 = 4 := by decide
-- Giving every year 365 days lands on 3 (Wednesday) in 2029, not 4.
example : (0 + 3 * (365 % 7)) % 7 = 3 := by decide
-- Taking 5 away instead of 7: a quotient of 73, nothing over.
example : 365 / 5 = 73 ∧ 365 % 5 = 0 ∧ 365 = 73 * 5 + 0 := by decide
-- Clocks: 100 minutes is 1 hour and 40 minutes.
example : 100 / 60 = 1 ∧ 100 % 60 = 40 := by decide

#print axioms quotient_and_remainder_exist_and_are_unique
#print axioms quotient_and_remainder_are_div_and_mod
#print axioms without_leftover_rule_answer_is_not_unique
