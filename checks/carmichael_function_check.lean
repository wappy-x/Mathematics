-- Carmichael's function: lambda(n) is the smallest positive power that sends every number coprime to n back to 1 on the n-clock, it is the lcm of the prime-power pieces' return times, and a composite n fools the Fermat test for every coprime base exactly when lambda(n) divides n - 1, which is Korselt's test.
import Mathlib.NumberTheory.ArithmeticFunction.Carmichael
import Mathlib.NumberTheory.CarmichaelNumber
import Mathlib.Data.Nat.ModEq
import Mathlib.Data.Nat.Totient
import Mathlib.Tactic.NormNum.GCD
import Mathlib.Tactic.NormNum.Pow
import Mathlib.Tactic.NormNum.Prime

open ArithmeticFunction

/-- Carmichael's function. On the n-clock (n at least 1), lambda(n) is the smallest positive power
that sends every number a sharing no factor with n back to 1: a to the lambda(n) leaves remainder 1
on division by n for every such a, and no smaller positive power does that for all of them. -/
theorem carmichael_is_smallest_power_sending_every_coprime_base_home (n : ℕ) (hn : n ≠ 0) :
    IsLeast {e : ℕ | 0 < e ∧ ∀ a : ℕ, Nat.Coprime a n → a ^ e ≡ 1 [MOD n]} (carmichael n) := by
  have : NeZero n := ⟨hn⟩
  refine ⟨⟨Nat.pos_of_dvd_of_pos (carmichael_dvd_totient n) (Nat.totient_pos.2 (Nat.pos_of_ne_zero hn)),
    fun a ha => ?_⟩, ?_⟩
  · rw [← ZMod.natCast_eq_natCast_iff]
    push_cast
    rw [← ZMod.coe_unitOfCoprime a ha, ← Units.val_pow_eq_pow_val, pow_carmichael, Units.val_one]
  · rintro e ⟨he, h⟩
    apply Nat.le_of_dvd he
    rw [carmichael_eq_exponent hn]
    refine Monoid.exponent_dvd_of_forall_pow_eq_one fun u => ?_
    have hu := (ZMod.natCast_eq_natCast_iff _ _ _).2 (h (u : ZMod n).val (ZMod.val_coe_unit_coprime u))
    push_cast at hu
    rw [ZMod.natCast_zmod_val] at hu
    ext
    rw [Units.val_pow_eq_pow_val, hu, Units.val_one]

/-- The formula. Split n into its prime-power pieces p^k. Each piece's return time is
(p - 1) p^(k - 1), except that a power of 2 with k at least 3 has return time 2^(k - 2).
Then lambda(n) is the least common multiple of those return times. -/
theorem carmichael_is_lcm_of_prime_power_return_times (n : ℕ) (hn : n ≠ 0) :
    carmichael n = n.primeFactors.lcm (fun p =>
      if p = 2 ∧ 3 ≤ n.factorization p then 2 ^ (n.factorization p - 2)
      else (p - 1) * p ^ (n.factorization p - 1)) := by
  have : NeZero n := ⟨hn⟩
  rw [carmichael_factorization n]
  refine Finset.lcm_congr rfl fun p hp => ?_
  have hpp := Nat.prime_of_mem_primeFactors hp
  have hk : 0 < n.factorization p :=
    hpp.factorization_pos_of_dvd hn (Nat.dvd_of_mem_primeFactors hp)
  by_cases h2 : p = 2
  · subst h2
    by_cases h3 : 3 ≤ n.factorization 2
    · rw [ite_eq_left ⟨rfl, h3⟩, carmichael_two_pow_of_ne_two (by omega)]
    · rw [ite_eq_right (by tauto), carmichael_two_pow_of_le_two (by omega)]
      simp
  · rw [ite_eq_right (by tauto), carmichael_pow_of_prime_ne_two _ hpp h2, Nat.totient_prime_pow hpp hk,
      mul_comm]

/-- Korselt's test. Take a composite n (above 1 and not prime). It is a Carmichael number, meaning
a to the (n - 1) leaves 1 on the n-clock for every base a sharing no factor with n, exactly when
lambda(n) divides n - 1, and exactly when no prime divides n twice and p - 1 divides n - 1 for
every prime p dividing n. -/
theorem korselt_test (n : ℕ) (h1 : 1 < n) (hnp : ¬ n.Prime) :
    (n.IsCarmichael ↔ carmichael n ∣ n - 1) ∧
    (n.IsCarmichael ↔ Squarefree n ∧ ∀ p : ℕ, p.Prime → p ∣ n → p - 1 ∣ n - 1) := by
  have h2 : 2 < n := by
    by_contra h
    interval_cases n
    exact hnp Nat.prime_two
  refine ⟨⟨Nat.IsCarmichael.carmichael_dvd_sub_one, fun hd => ⟨h2, hnp, fun b hb => ?_⟩⟩, ?_⟩
  · obtain ⟨d, hd⟩ := hd
    have hb0 : b ≠ 0 := by
      rintro rfl
      rw [Nat.coprime_zero_left] at hb
      omega
    rw [Nat.probablePrime_iff_zmod_one n hb0, ← ZMod.coe_unitOfCoprime b hb,
      ← Units.val_pow_eq_pow_val, hd, pow_mul, pow_carmichael, one_pow, Units.val_one]
  · rw [Nat.isCarmichael_iff_korselt]
    tauto

-- 561 = 3 x 11 x 17: return times 2, 10, 16; lcm 80; Euler's count 320; 560 = 7 x 80.
example : 561 = 3 * 11 * 17 := by norm_num
example : Nat.lcm 2 (Nat.lcm 10 16) = 80 := by norm_num
example : 2 * 10 * 16 = 320 := by norm_num
example : 560 = 7 * 80 := by norm_num
example : carmichael 561 = 80 := by 
  rw [show (561 : ℕ) = 3 * (11 * 17) by norm_num, carmichael_mul (by norm_num),
    carmichael_mul (by norm_num), carmichael_of_prime (by norm_num), carmichael_of_prime (by norm_num),
    carmichael_of_prime (by norm_num)]
  norm_num
example : Nat.totient 561 = 320 := by 
  rw [show (561 : ℕ) = 3 * (11 * 17) by norm_num, Nat.totient_mul (by norm_num),
    Nat.totient_mul (by norm_num), Nat.totient_prime (by norm_num), Nat.totient_prime (by norm_num),
    Nat.totient_prime (by norm_num)]
example : Nat.IsCarmichael 561 := by exact Nat.isCarmichael_561

-- 15 = 3 x 5: lambda = lcm(2, 4) = 4, phi = 8, 2^4 = 16 leaves 1.
example : Nat.lcm 2 4 = 4 := by norm_num
example : carmichael 15 = 4 := by 
  rw [show (15 : ℕ) = 3 * 5 by norm_num, carmichael_mul (by norm_num),
    carmichael_of_prime (by norm_num), carmichael_of_prime (by norm_num)]
  norm_num
example : Nat.totient 15 = 8 := by 
  rw [show (15 : ℕ) = 3 * 5 by norm_num, Nat.totient_mul (by norm_num),
    Nat.totient_prime (by norm_num), Nat.totient_prime (by norm_num)]
example : 2 ^ 4 % 15 = 1 := by norm_num

-- When it holds: a base sharing a factor fails; powers of 2 have their own rule.
example : 3 ^ 80 % 561 = 375 := by norm_num
example : 3 ^ 2 % 8 = 1 ∧ 5 ^ 2 % 8 = 1 ∧ 7 ^ 2 % 8 = 1 := by norm_num
example : carmichael 8 = 2 ∧ Nat.totient 8 = 4 := by 
  rw [show (8 : ℕ) = 2 ^ 3 by norm_num, carmichael_two_pow_of_ne_two (by norm_num),
    Nat.totient_prime_pow Nat.prime_two (by norm_num)]
  norm_num

-- On the 561-clock, 2 returns in 40 steps, 13 in 20, 5 in 80.
example : orderOf (2 : ZMod 561) = 40 ∧ orderOf (13 : ZMod 561) = 20 ∧ orderOf (5 : ZMod 561) = 80 := by
  
  refine ⟨orderOf_eq_of_pow_and_pow_div_prime (by norm_num) (by decide) ?_,
    orderOf_eq_of_pow_and_pow_div_prime (by norm_num) (by decide) ?_,
    orderOf_eq_of_pow_and_pow_div_prime (by norm_num) (by decide) ?_⟩ <;>
  · intro p hp hdvd
    have hp80 : p ≤ 80 := Nat.le_of_dvd (by norm_num) (hdvd.trans (by norm_num))
    interval_cases p <;> first | (revert hp hdvd; norm_num; done) | decide

-- Korselt without "no prime twice": 2 divides 8, yet 2^8 leaves 4 on the 9-clock.
example : (3 - 1) ∣ (9 - 1) ∧ 2 ^ 8 % 9 = 4 := by norm_num
example : ¬ Nat.IsCarmichael 9 := by 
  intro h
  have h3 := h.squarefree 3 (by norm_num)
  norm_num at h3

-- RSA, 3233 = 61 x 53, e = 17: lambda = 780, d = 413; 65 locks to 2790 and unlocks back to 65.
example : 3233 = 61 * 53 ∧ Nat.lcm 60 52 = 780 ∧ 17 * 413 % 780 = 1 := by norm_num
example : 65 ^ 17 % 3233 = 2790 ∧ 2790 ^ 413 % 3233 = 65 := by decide
example : carmichael 3233 = 780 := by 
  rw [show (3233 : ℕ) = 61 * 53 by norm_num, carmichael_mul (by norm_num),
    carmichael_of_prime (by norm_num), carmichael_of_prime (by norm_num)]
  norm_num

#print axioms carmichael_is_smallest_power_sending_every_coprime_base_home
#print axioms carmichael_is_lcm_of_prime_power_return_times
#print axioms korselt_test
