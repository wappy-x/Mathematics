-- Fermat's little theorem: for a prime p and a whole number a that p does not divide, a to the power p − 1 leaves remainder 1 on division by p, and a to the power p always reads a.
import Mathlib.FieldTheory.Finite.Basic
import Mathlib.Data.Int.GCD
import Mathlib.Tactic.NormNum.Prime

/-- Fermat's little theorem, as the card states it: on a prime-sized dial p, take a number a
that the dial size does not divide, start at 1 and multiply by a one time fewer than there are
positions (p − 1 times); the dial reads 1, that is a ^ (p − 1) ≡ 1 (mod p). -/
theorem fermat_little_pow_pred_eq_one (p : ℕ) (hp : p.Prime) (a : ℤ) (ha : ¬ (p : ℤ) ∣ a) :
    a ^ (p - 1) ≡ 1 [ZMOD p] := by
  have hcop : IsCoprime a (p : ℤ) := by
    have hirr : Irreducible (p : ℤ) := (Nat.prime_iff_prime_int.mp hp).irreducible
    exact ((Irreducible.coprime_iff_not_dvd hirr).mpr ha).symm
  exact Int.ModEq.pow_card_sub_one_eq_one hp hcop

/-- The second form, which needs no condition on the number: on a prime-sized dial p, multiply
by a as many times as there are positions and the dial reads a, that is a ^ p ≡ a (mod p). -/
theorem fermat_little_pow_self (p : ℕ) (hp : p.Prime) (a : ℤ) :
    a ^ p ≡ a [ZMOD p] := by
  exact Int.ModEq.pow_prime_eq_self hp a

/-- The engine of the proof: on a prime dial p, multiplying every live position 1, …, p − 1 by a
number a that p does not divide deals the same p − 1 positions out again, shuffled; nothing
lands on 0 and nothing lands twice. -/
theorem fermat_multiply_shuffles_live_positions (p : ℕ) (hp : p.Prime) (a : ℕ) (ha : ¬ p ∣ a) :
    (Finset.Icc 1 (p - 1)).image (fun k => a * k % p) = Finset.Icc 1 (p - 1) := by
  have hcop : Nat.gcd p a = 1 := (Nat.Prime.coprime_iff_not_dvd hp).mpr ha
  have hsub : (Finset.Icc 1 (p - 1)).image (fun k => a * k % p) ⊆ Finset.Icc 1 (p - 1) := by
    intro x hx
    simp only [Finset.mem_image, Finset.mem_Icc] at hx ⊢
    obtain ⟨k, ⟨hk1, hk2⟩, rfl⟩ := hx
    constructor
    · rcases Nat.eq_zero_or_pos (a * k % p) with h | h
      · exfalso
        have hdvd : p ∣ a * k := Nat.dvd_of_mod_eq_zero h
        rcases (Nat.Prime.dvd_mul hp).mp hdvd with h' | h'
        · exact ha h'
        · have := Nat.le_of_dvd (by omega) h'
          omega
      · omega
    · have := Nat.mod_lt (a * k) hp.pos
      omega
  have hinj : Set.InjOn (fun k => a * k % p) (Finset.Icc 1 (p - 1) : Set ℕ) := by
    intro k hk l hl hkl
    simp only [Finset.coe_Icc, Set.mem_Icc] at hk hl
    have h : a * k ≡ a * l [MOD p] := hkl
    have h2 : k ≡ l [MOD p] := Nat.ModEq.cancel_left_of_coprime hcop h
    unfold Nat.ModEq at h2
    rwa [Nat.mod_eq_of_lt (by omega), Nat.mod_eq_of_lt (by omega)] at h2
  apply Finset.eq_of_subset_of_card_le hsub
  rw [Finset.card_image_of_injOn hinj]

-- 13 is prime; twelve doublings make 4,096 = 315 × 13 + 1, so the 13-dial reads 1.
example : Nat.Prime 13 := by norm_num
example : 2 ^ 12 = 4096 ∧ 4096 = 315 * 13 + 1 := by norm_num
example : 2 ^ 12 % 13 = 1 := by norm_num
example : (2 : ℤ) ^ 12 ≡ 1 [ZMOD 13] := by decide
-- One more doubling: 2 ^ 13 = 8,192, and the dial reads 2.
example : 2 ^ 13 = 8192 ∧ 2 ^ 13 % 13 = 2 := by norm_num
-- Doubling deals 1 to 12 out again: 2, 4, 6, 8, 10, 12, 1, 3, 5, 7, 9, 11.
example : (List.range' 1 12).map (fun k => 2 * k % 13) = [2, 4, 6, 8, 10, 12, 1, 3, 5, 7, 9, 11] := by
  decide
-- The row multiplied, and the doubled row: both read 12 on the 13-dial.
example : Nat.factorial 12 = 479001600 := by decide
example : 4096 * 479001600 = 1961990553600 := by norm_num
example : 479001600 % 13 = 12 ∧ 1961990553600 % 13 = 12 := by norm_num
-- 2 taken a thousand times over: 1000 = 83 × 12 + 4, 2 ^ 4 = 16 reads 3, and so does 2 ^ 1000.
example : 1000 = 83 * 12 + 4 := by norm_num
example : 2 ^ 4 % 13 = 3 := by norm_num
example : 2 ^ 1000 % 13 = 3 := by decide +kernel
-- What breaks: splitting 1000 by 13 leaves 12, which reads 1; 26 reads 0; a 15-dial reads 4.
example : 1000 % 13 = 12 ∧ 2 ^ 12 % 13 = 1 := by norm_num
example : 26 ^ 12 % 13 = 0 := by decide
example : 2 ^ 14 = 16384 ∧ 2 ^ 14 % 15 = 4 ∧ ¬ Nat.Prime 15 := by norm_num
-- The undo of 2 on the 13-dial: 2 ^ 11 reads 7, and 2 × 7 is one dial and 1 over.
example : 2 ^ 11 % 13 = 7 ∧ 2 * 7 = 1 * 13 + 1 := by norm_num

#print axioms fermat_little_pow_pred_eq_one
#print axioms fermat_little_pow_self
#print axioms fermat_multiply_shuffles_live_positions
