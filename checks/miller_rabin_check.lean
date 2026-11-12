-- The Miller-Rabin test: on a prime clock the chain of squarings of any base either starts at 1 or shows one-below the number, so a chain with neither shape proves the number composite, as bases 18 and 137 do for 221 = 13 × 17 while base 174 lies.
import Mathlib.Data.Nat.ModEq
import Mathlib.Data.Nat.Prime.Defs
import Mathlib.Data.Finset.Card
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Data.ZMod.Basic
import Mathlib.FieldTheory.Finite.Basic

/-- A prime's chain of squarings has only two allowed shapes. Take an odd number `n` under
test and a base `a` below it. Halve one-below until it is odd: `n - 1 = 2 ^ s * d` with `d`
odd. The chain is the base to the `d`th, then that squared, again and again, `s` values in
all. If `n` is prime, the chain starts at 1 or shows `n - 1` somewhere. So a chain with
neither shape proves `n` composite. -/
theorem miller_rabin_prime_chain_starts_at_one_or_shows_minus_one
    (n a s d : ℕ) (hn : Odd n) (ha : 1 ≤ a) (han : a < n)
    (hd : Odd d) (hsplit : n - 1 = 2 ^ s * d) (hp : n.Prime) :
    a ^ d ≡ 1 [MOD n] ∨ ∃ r < s, a ^ (2 ^ r * d) ≡ n - 1 [MOD n] := by
  have : Fact n.Prime := ⟨hp⟩
  have hn1 : 1 ≤ n := hp.one_lt.le
  have hcast : ((n - 1 : ℕ) : ZMod n) = -1 := by
    rw [Nat.cast_sub hn1]; simp
  by_contra hcon
  push Not at hcon
  obtain ⟨h0, hr⟩ := hcon
  have h0' : ((a : ZMod n)) ^ d ≠ 1 := by
    intro h
    apply h0
    rw [← ZMod.natCast_eq_natCast_iff]
    simpa using h
  have hr' : ∀ r < s, ((a : ZMod n)) ^ (2 ^ r * d) ≠ -1 := by
    intro r hrs h
    apply hr r hrs
    rw [← ZMod.natCast_eq_natCast_iff, hcast]
    simpa using h
  have step : ∀ r ≤ s, ((a : ZMod n)) ^ (2 ^ r * d) ≠ 1 := by
    intro r
    induction r with
    | zero => intro _; simpa using h0'
    | succ r ih =>
      intro hrs h
      have hrs' : r < s := hrs
      have h2 : (((a : ZMod n)) ^ (2 ^ r * d)) * (((a : ZMod n)) ^ (2 ^ r * d)) = 1 := by
        rw [← pow_add, ← h]
        congr 1
        ring
      rcases mul_self_eq_one_iff.mp h2 with h3 | h3
      · exact ih hrs'.le h3
      · exact hr' r hrs' h3
  have ha0 : (a : ZMod n) ≠ 0 := by
    intro h
    rw [ZMod.natCast_eq_zero_iff] at h
    have := Nat.le_of_dvd (by omega) h
    omega
  have hf := ZMod.pow_card_sub_one_eq_one ha0
  apply step s le_rfl
  rw [← hsplit]
  exact hf

/-- On a prime clock, only two numbers square to 1: a number whose square lands on 1 is
itself 1 or one-below the prime. -/
theorem prime_clock_square_roots_of_one (p x : ℕ) (hp : p.Prime) (hx : x * x ≡ 1 [MOD p]) :
    x ≡ 1 [MOD p] ∨ x ≡ p - 1 [MOD p] := by
  have : Fact p.Prime := ⟨hp⟩
  have hp1 : 1 ≤ p := hp.one_lt.le
  have hcast : ((p - 1 : ℕ) : ZMod p) = -1 := by
    rw [Nat.cast_sub hp1]; simp
  have h : (x : ZMod p) * (x : ZMod p) = 1 := by
    have := (ZMod.natCast_eq_natCast_iff _ _ _).mpr hx
    simpa using this
  rcases mul_self_eq_one_iff.mp h with h1 | h1
  · left
    rw [← ZMod.natCast_eq_natCast_iff]
    simpa using h1
  · right
    rw [← ZMod.natCast_eq_natCast_iff, hcast]
    exact h1

-- 221 = 13 × 17 is composite; one-below is 220 = 4 × 55, halved twice to the odd part 55.
example : 13 * 17 = 221 ∧ 221 - 1 = 220 ∧ 220 = 2 ^ 2 * 55 := by decide
example : ¬ Nat.Prime 221 := by norm_num
-- Trial division: 2, 3, 5, 7 and 11 do not divide 221, and 13 does.
example : 221 % 2 ≠ 0 ∧ 221 % 3 ≠ 0 ∧ 221 % 5 ≠ 0 ∧ 221 % 7 ≠ 0 ∧ 221 % 11 ≠ 0 ∧ 221 % 13 = 0 := by
  decide
-- Base 174: to the 55th is 47, and 47 squared is 220 = 221 - 1. A liar: it says prime.
example : 174 ^ 55 % 221 = 47 ∧ 47 * 47 % 221 = 220 := by decide +kernel
-- Base 18: to the 55th is 86, squared is 103, and 103 squares to 1. A witness.
example : 18 ^ 55 % 221 = 86 ∧ 86 * 86 % 221 = 103 ∧ 103 * 103 % 221 = 1 := by decide +kernel
-- Base 137: to the 55th is 188, squared is 205: neither shape. A witness.
example : 137 ^ 55 % 221 = 188 ∧ 188 * 188 % 221 = 205 := by decide +kernel
-- On the 221 clock four numbers square to 1: 1, 103, 118 and 220.
example : (Finset.range 221).filter (fun x => x * x % 221 = 1) = {1, 103, 118, 220} := by
  decide +kernel
-- The Fermat test reads only the top: bases 174 and 18 land on 1 there, base 137 on 35.
example : 174 ^ 220 % 221 = 1 ∧ 18 ^ 220 % 221 = 1 ∧ 137 ^ 220 % 221 = 35 := by decide +kernel
-- Of the 220 bases, 16 fool Fermat but only 6 fool Miller-Rabin; 4 × 6 is at most 220.
example : ((Finset.range 221).filter (fun a => 0 < a ∧ a ^ 220 % 221 = 1)).card = 16 := by decide +kernel
example : ((Finset.range 221).filter
    (fun a => 0 < a ∧ (a ^ 55 % 221 = 1 ∨ a ^ 55 % 221 = 220 ∨ a ^ 110 % 221 = 220))).card = 6 := by
  decide +kernel
example : 4 * 6 ≤ 221 - 1 ∧ 220 - 6 = 214 := by decide
-- Base 13, a factor of 221, is a witness: its chain is neither 1 first nor 220 anywhere.
example : 13 ^ 55 % 221 ≠ 1 ∧ 13 ^ 55 % 221 ≠ 220 ∧ 13 ^ 110 % 221 ≠ 220 := by decide +kernel

#print axioms miller_rabin_prime_chain_starts_at_one_or_shows_minus_one
#print axioms prime_clock_square_roots_of_one
