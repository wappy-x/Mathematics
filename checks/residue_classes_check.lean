-- Residue classes: sorting the whole numbers by their remainder after dividing by n puts each one in exactly one of n buckets, the buckets add and multiply whichever member you pick, and no two non-zero buckets multiply to 0 exactly when n is prime.
import Mathlib.Data.Int.ModEq
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Fintype.Prod
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.Field.ZMod

/-- The buckets add and multiply whichever member you pick. Take any modulus `n`. If `a'` is in
the same bucket as `a` (same remainder after dividing by `n`), and `b'` is in the same bucket as
`b`, then `a' + b'` lands in the same bucket as `a + b`, and `a' * b'` in the same bucket as
`a * b`. -/
theorem buckets_add_and_multiply_whichever_member (n : ℕ) {a a' b b' : ℤ}
    (ha : a' ≡ a [ZMOD n]) (hb : b' ≡ b [ZMOD n]) :
    a' + b' ≡ a + b [ZMOD n] ∧ a' * b' ≡ a * b [ZMOD n] := by
  exact ⟨ha.add hb, ha.mul hb⟩

/-- Every whole number lands in one bucket and no other. For `n` buckets, every whole number,
negatives included, has exactly one remainder `r` from 0 to `n - 1` whose bucket it is in. -/
theorem every_whole_number_lands_in_exactly_one_bucket (n : ℕ) (hn : 0 < n) (x : ℤ) :
    ∃! r : ℕ, r < n ∧ x ≡ r [ZMOD n] := by
  have hn' : (0 : ℤ) < n := by exact_mod_cast hn
  refine ⟨(x % n).toNat, ⟨?_, ?_⟩, ?_⟩
  · have h1 := Int.emod_nonneg x hn'.ne'
    have h2 := Int.emod_lt_of_pos x hn'
    omega
  · have h1 := Int.emod_nonneg x hn'.ne'
    have : (((x % n).toNat : ℕ) : ℤ) = x % n := Int.toNat_of_nonneg h1
    rw [this]
    exact (Int.mod_modEq x n).symm
  · rintro r ⟨hr, hxr⟩
    have h1 := Int.emod_nonneg x hn'.ne'
    have h2 := Int.emod_lt_of_pos x hn'
    have h3 : (r : ℤ) = x % n := by
      have := hxr.symm.eq
      rw [Int.emod_eq_of_lt (by positivity) (by exact_mod_cast hr)] at this
      exact this
    omega

/-- No two non-zero buckets multiply to 0 exactly when the modulus is prime. With more than one
bucket, in `Z mod n` a product of buckets is bucket 0 only when one factor is bucket 0, if and
only if `n` is prime. -/
theorem no_zero_product_of_nonzero_buckets_iff_prime (n : ℕ) (hn : 1 < n) :
    (∀ a b : ZMod n, a * b = 0 → a = 0 ∨ b = 0) ↔ n.Prime := by
  constructor
  · intro h
    have : NoZeroDivisors (ZMod n) := ⟨fun {a b} hab => h a b hab⟩
    exact CharP.char_is_prime_of_two_le (ZMod n) n hn
  · intro hp a b hab
    have : Fact n.Prime := ⟨hp⟩
    exact mul_eq_zero.mp hab

-- Up a fifth twice: 7 + 7 = 14 lands in bucket 2 out of 12. An octave up, 19 + 19 = 38, also bucket 2.
example : (7 + 7 : ℤ) % 12 = 2 := by decide
example : (19 + 19 : ℤ) % 12 = 2 := by decide
-- Bucket 2 out of 12 holds ... -22, -10, 2, 14, 26 ...
example : ∀ x ∈ ([-22, -10, 2, 14, 26] : List ℤ), x % 12 = 2 := by decide
-- Stacking fifths walks through all 12 buckets before coming home.
example : (List.range 12).map (fun k => 7 * k % 12) = [0, 7, 2, 9, 4, 11, 6, 1, 8, 3, 10, 5] ∧
    7 * 12 % 12 = 0 := by decide
-- Stacking 8 semitones instead reaches only 3 buckets: 0, 8, 4, then home.
example : (List.range 3).map (fun k => 8 * k % 12) = [0, 8, 4] ∧ 8 * 3 % 12 = 0 := by decide
-- The mod 5 adding table, row by row.
example : (List.range 5).map (fun a => (List.range 5).map (fun b => (a + b) % 5)) =
    [[0, 1, 2, 3, 4], [1, 2, 3, 4, 0], [2, 3, 4, 0, 1], [3, 4, 0, 1, 2], [4, 0, 1, 2, 3]] := by
  decide
-- The mod 5 multiplying table.
example : (List.range 5).map (fun a => (List.range 5).map (fun b => a * b % 5)) =
    [[0, 0, 0, 0, 0], [0, 1, 2, 3, 4], [0, 2, 4, 1, 3], [0, 3, 1, 4, 2], [0, 4, 3, 2, 1]] := by
  decide
-- The mod 6 multiplying table.
example : (List.range 6).map (fun a => (List.range 6).map (fun b => a * b % 6)) =
    [[0, 0, 0, 0, 0, 0], [0, 1, 2, 3, 4, 5], [0, 2, 4, 0, 2, 4], [0, 3, 0, 3, 0, 3],
     [0, 4, 2, 0, 4, 2], [0, 5, 4, 3, 2, 1]] := by
  decide
-- The tables built again from far-off members, three clocks up and six down, agree.
example : ∀ a ∈ List.range 5, ∀ b ∈ List.range 5,
    ((a + 15 : ℤ) + (b - 30)) % 5 = ((a + b : ℕ) : ℤ) % 5 ∧
    ((a + 15 : ℤ) * (b - 30)) % 5 = ((a * b : ℕ) : ℤ) % 5 := by decide
example : ∀ a ∈ List.range 6, ∀ b ∈ List.range 6,
    ((a + 18 : ℤ) * (b - 36)) % 6 = ((a * b : ℕ) : ℤ) % 6 := by decide
-- Out of 5 there are 0 pairs of non-zero buckets multiplying to 0.
example : (Finset.univ.filter (fun p : ZMod 5 × ZMod 5 => p.1 ≠ 0 ∧ p.2 ≠ 0 ∧ p.1 * p.2 = 0)).card
    = 0 := by decide
-- Out of 6 there are 4: 2 x 3, 3 x 2, 3 x 4, 4 x 3.
example : Finset.univ.filter (fun p : ZMod 6 × ZMod 6 => p.1 ≠ 0 ∧ p.2 ≠ 0 ∧ p.1 * p.2 = 0)
    = {(2, 3), (3, 2), (3, 4), (4, 3)} := by decide
-- Cancelling the 2 in 2 x 3 = 2 x 0, out of 6, would give 3 = 0, which is false.
example : (2 * 3 : ZMod 6) = 2 * 0 ∧ (3 : ZMod 6) ≠ 0 := by decide

#print axioms buckets_add_and_multiply_whichever_member
#print axioms every_whole_number_lands_in_exactly_one_bucket
#print axioms no_zero_product_of_nonzero_buckets_iff_prime
