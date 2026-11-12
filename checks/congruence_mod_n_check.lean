-- Congruence: for whole numbers a and b and a modulus n of 1 or more, a and b leave the same remainder on division by n exactly when n divides a - b; every whole number has one remainder from 0 to n - 1; and adding whole turns of n never changes it.
import Mathlib.Data.Int.ModEq
import Mathlib.Data.List.Range

/-- The remainder test and the difference test always agree. Take whole numbers a and b and a
modulus n of 1 or more. Then a and b leave the same remainder on division by n (the remainder
running from 0 to n - 1, so -3 leaves 9 on 12) exactly when n divides their difference a - b. -/
theorem same_remainder_iff_modulus_divides_difference (a b n : ℤ) (hn : 1 ≤ n) :
    a % n = b % n ↔ n ∣ a - b := by
  have h := Int.modEq_iff_dvd (n := n) (a := b) (b := a)
  constructor
  · intro h1
    exact h.mp h1.symm
  · intro h2
    exact (h.mpr h2).symm

/-- Every whole number has exactly one remainder. With a modulus n of 1 or more, any whole number
a is some whole number of turns times n plus a remainder from 0 to n - 1, and only one choice of
turns and remainder works: the remainder is a % n and the turns are a / n. -/
theorem remainder_exists_and_is_unique (a n : ℤ) (hn : 1 ≤ n) :
    (0 ≤ a % n ∧ a % n < n ∧ a = n * (a / n) + a % n) ∧
      ∀ q r : ℤ, 0 ≤ r → r < n → a = n * q + r → q = a / n ∧ r = a % n := by
  have hpos : 0 < n := by omega
  refine ⟨⟨Int.emod_nonneg a (by omega), Int.emod_lt_of_pos a hpos, (Int.mul_ediv_add_emod a n).symm⟩, ?_⟩
  intro q r hr0 hrn h
  have hr : a % n = r := by
    rw [h, Int.add_comm, Int.add_mul_emod_self_left]
    exact Int.emod_eq_of_lt hr0 hrn
  have hdiv := Int.mul_ediv_add_emod a n
  have hq : n * (a / n) = n * q := by omega
  exact ⟨(Int.eq_of_mul_eq_mul_left (by omega) hq).symm, hr.symm⟩

/-- A whole turn changes nothing. Adding or taking out any whole number k of turns of n, forwards
or backwards, leaves the remainder on division by n where it was. -/
theorem whole_turns_do_not_move_the_remainder (a k n : ℤ) (hn : 1 ≤ n) :
    (a + k * n) % n = a % n := by
  simp

-- 100 hours: 4 days and 4 over, or 8 turns of the face and 4 over.
example : (100 : ℤ) = 4 * 24 + 4 ∧ (100 : ℤ) = 8 * 12 + 4 := by decide
example : (100 : ℤ) % 24 = 4 ∧ (100 : ℤ) % 12 = 4 := by decide
-- 9 am plus 100 hours is count 109 = 9 × 12 + 1, and the face reads 1.
example : (9 : ℤ) + 100 = 109 ∧ (109 : ℤ) = 9 * 12 + 1 ∧ (109 : ℤ) % 12 = 1 := by decide
-- 109 ≡ 1 (mod 12): the same remainder, and 12 divides 109 - 1 = 108 = 9 × 12.
example : (109 : ℤ) % 12 = 1 % 12 := by decide
example : (109 : ℤ) ≡ 1 [ZMOD 12] := by decide
example : (109 : ℤ) - 1 = 108 ∧ (108 : ℤ) = 9 * 12 ∧ (12 : ℤ) ∣ 109 - 1 := by decide
-- Three hours before midnight: -3 = (-1) × 12 + 9, so -3 leaves 9, and 9 - (-3) = 12.
example : (-3 : ℤ) = (-1) * 12 + 9 ∧ (-3 : ℤ) % 12 = 9 ∧ (9 : ℤ) - (-3) = 12 := by decide
example : (-3 : ℤ) ≡ 9 [ZMOD 12] := by decide
-- The wrong pair: 109 and 2 differ by 107, which leaves 11, so they are not congruent mod 12.
example : (109 : ℤ) - 2 = 107 ∧ (107 : ℤ) % 12 = 11 ∧ ¬ ((109 : ℤ) ≡ 2 [ZMOD 12]) := by decide
-- The picture: hour counts 96 to 110 leave 0, 1, ..., 11, 0, 1, 2 on the 12-hour face.
example : ((List.range 15).map fun i : ℕ => ((96 + i : ℕ) : ℤ) % 12) =
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 0, 1, 2] := by decide

#print axioms same_remainder_iff_modulus_divides_difference
#print axioms remainder_exists_and_is_unique
#print axioms whole_turns_do_not_move_the_remainder
