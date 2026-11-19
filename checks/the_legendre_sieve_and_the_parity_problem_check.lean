-- Sieving by inclusion-exclusion: Legendre's signed sum of rounded divisions counts the numbers up to x with no prime factor up to z exactly, and it differs from the main term x ∏ (1 - 1/p) by at most 2 to the power of the number of sieving primes.
import Mathlib.NumberTheory.ArithmeticFunction.Moebius
import Mathlib.NumberTheory.ArithmeticFunction.Liouville
import Mathlib.NumberTheory.PrimeCounting
import Mathlib.NumberTheory.Primorial
import Mathlib.Basic.Real.Basic

open Finset Nat ArithmeticFunction
open scoped ArithmeticFunction.Moebius Nat.Prime

/-- No sieving prime divides `n` exactly when `n` is coprime to the primorial. -/
lemma sieve_cond_iff_coprime (z n : ℕ) :
    (∀ p ∈ primesLE z, ¬ p ∣ n) ↔ Nat.Coprime n (primorial z) := by
  constructor
  · intro h
    refine Nat.coprime_of_dvd fun k hk hkn hkP => ?_
    have : k ∈ primeFactors (primorial z) :=
      Nat.mem_primeFactors.mpr ⟨hk, hkP, primorial_ne_zero z⟩
    rw [primeFactors_primorial] at this
    exact h k this hkn
  · intro hc p hp hpn
    have hpP : p ∣ primorial z := by
      rw [primorial_eq_prod_primesLE]; exact dvd_prod_of_mem _ hp
    have := Nat.dvd_one.mp (hc ▸ Nat.dvd_gcd hpn hpP)
    exact (prime_of_mem_primesLE hp).one_lt.ne' this

/-- The Möbius sum over the divisors of the primorial that divide `n` detects sieve survivors. -/
lemma sum_moebius_divisors_primorial_dvd (z n : ℕ) :
    ∑ d ∈ (primorial z).divisors, (if d ∣ n then μ d else 0)
      = if (∀ p ∈ primesLE z, ¬ p ∣ n) then 1 else 0 := by
  rw [← sum_filter]
  have hfilt : {d ∈ (primorial z).divisors | d ∣ n} = (Nat.gcd n (primorial z)).divisors := by
    ext d
    simp only [mem_filter, Nat.mem_divisors, Nat.dvd_gcd_iff]
    have h1 := primorial_ne_zero z
    have h2 : Nat.gcd n (primorial z) ≠ 0 := Nat.gcd_ne_zero_right h1
    tauto
  rw [hfilt, ← coe_mul_zeta_apply, moebius_mul_coe_zeta, ArithmeticFunction.one_apply]
  exact if_congr (sieve_cond_iff_coprime z n).symm rfl rfl

/-- The count of multiples of `d` in `[1, x]`. -/
lemma card_filter_dvd_Icc_one (x d : ℕ) : #{n ∈ Icc 1 x | d ∣ n} = x / d := by
  rw [← Nat.Ioc_filter_dvd_card_eq_div x d]
  congr 1

/-- Legendre's identity: the sieve count as a Möbius sum over the divisors of the primorial. -/
lemma legendre_identity (x z : ℕ) :
    ((#{n ∈ Icc 1 x | ∀ p ∈ primesLE z, ¬ p ∣ n} : ℕ) : ℤ)
        = ∑ d ∈ (primorial z).divisors, μ d * ((x / d : ℕ) : ℤ) := by
  rw [card_filter, Nat.cast_sum]
  simp_rw [← card_filter_dvd_Icc_one x, card_filter, Nat.cast_sum, mul_sum]
  rw [sum_comm]
  apply sum_congr rfl
  intro n _
  push_cast [Nat.cast_ite]
  rw [← sum_moebius_divisors_primorial_dvd z n]
  apply sum_congr rfl
  intro d _
  split_ifs <;> simp

/-- The divisors of a squarefree number: there are `2 ^ ω(n)` of them; for the primorial,
`2 ^ π(z)`. -/
lemma card_divisors_primorial (z : ℕ) : #(primorial z).divisors = 2 ^ π z := by
  rw [Nat.card_divisors (primorial_ne_zero z)]
  have hsq := squarefree_primorial z
  rw [prod_congr rfl (g := fun _ => 2) (fun p hp => by
    have h1 := hsq.natFactorization_le_one p
    have h2 : 0 < (primorial z).factorization p :=
      Nat.Prime.factorization_pos_of_dvd (Nat.prime_of_mem_primeFactors hp)
        (primorial_ne_zero z) (Nat.dvd_of_mem_primeFactors hp)
    omega)]
  rw [prod_const, primeFactors_primorial, primesLE_card_eq_primeCounting]

/-- The main term: `x ∏ (1 - 1/p)` expands as the Möbius sum of `x/d`. -/
lemma main_term_expand (x z : ℕ) :
    (x : ℝ) * ∏ p ∈ primesLE z, (1 - 1 / (p : ℝ))
      = ∑ d ∈ (primorial z).divisors, (μ d : ℝ) * ((x : ℝ) / d) := by
  let f : ArithmeticFunction ℝ := ⟨fun d => (d : ℝ)⁻¹, by simp⟩
  have hf : f.IsMultiplicative := by
    refine ⟨by simp [f], fun {m n} _ => ?_⟩
    simp [f, mul_comm]
  have key : ∏ p ∈ primesLE z, (1 - (p : ℝ)⁻¹)
      = ∑ d ∈ (primorial z).divisors, (μ d : ℝ) * (d : ℝ)⁻¹ := by
    have := hf.prodPrimeFactors_one_sub_of_squarefree f (squarefree_primorial z)
    rw [primeFactors_primorial] at this
    exact this
  simp_rw [one_div, key, mul_sum]
  apply sum_congr rfl
  intro d _
  rw [div_eq_mul_inv]; ring

lemma abs_floor_div_sub_le (x d : ℕ) : |((x / d : ℕ) : ℝ) - (x : ℝ) / d| ≤ 1 := by
  rcases Nat.eq_zero_or_pos d with rfl | hd
  · simp
  have hd' : (0 : ℝ) < d := by exact_mod_cast hd
  have hx : (x : ℝ) = d * ((x / d : ℕ) : ℝ) + ((x % d : ℕ) : ℝ) := by
    exact_mod_cast (Nat.div_add_mod x d).symm
  have hm : ((x % d : ℕ) : ℝ) < d := by exact_mod_cast Nat.mod_lt x hd
  have hm0 : (0 : ℝ) ≤ ((x % d : ℕ) : ℝ) := by positivity
  have : (x : ℝ) / d = ((x / d : ℕ) : ℝ) + ((x % d : ℕ) : ℝ) / d := by
    rw [hx, add_div, mul_div_cancel_left₀ _ hd'.ne']
  rw [this, abs_le]
  constructor
  · have : ((x % d : ℕ) : ℝ) / d ≤ 1 := by rw [div_le_one hd']; exact hm.le
    linarith
  · have : 0 ≤ ((x % d : ℕ) : ℝ) / d := by positivity
    linarith

lemma liouville_eq_one_or_neg_one {n : ℕ} (hn : n ≠ 0) :
    liouville n = 1 ∨ liouville n = -1 := by
  rw [liouville_apply hn]; exact neg_one_pow_eq_or ℤ _

lemma filter_dvd_Icc_eq_image (x d : ℕ) (hd : 0 < d) :
    {n ∈ Icc 1 x | d ∣ n} = (Icc 1 (x / d)).image (d * ·) := by
  ext n
  simp only [mem_filter, mem_Icc, mem_image]
  constructor
  · rintro ⟨⟨h1, h2⟩, m, rfl⟩
    refine ⟨m, ⟨?_, ?_⟩, rfl⟩
    · rcases Nat.eq_zero_or_pos m with rfl | hm
      · simp at h1
      · exact hm
    · rw [Nat.le_div_iff_mul_le hd, mul_comm]; exact h2
  · rintro ⟨m, ⟨h1, h2⟩, rfl⟩
    refine ⟨⟨?_, ?_⟩, dvd_mul_right d m⟩
    · exact Nat.one_le_iff_ne_zero.mpr (by positivity)
    · rw [Nat.le_div_iff_mul_le hd] at h2; rw [mul_comm]; exact h2

#print axioms sieve_cond_iff_coprime
#print axioms sum_moebius_divisors_primorial_dvd
#print axioms card_filter_dvd_Icc_one
#print axioms legendre_identity
#print axioms card_divisors_primorial
#print axioms main_term_expand
#print axioms abs_floor_div_sub_le
#print axioms liouville_eq_one_or_neg_one
#print axioms filter_dvd_Icc_eq_image

/-- Legendre's sieve. For every whole number x and every z, let S(x, z) count the n from 1 to x
that no prime p ≤ z divides. Then S(x, z) equals the signed sum of ⌊x/d⌋ over the divisors d of
P(z), the product of the primes up to z, with sign μ(d); and S(x, z) differs from the main term
x ∏_{p ≤ z} (1 - 1/p) by at most 2^π(z). -/
theorem legendre_sieve_identity_and_error_bound (x z : ℕ) :
    ((#{n ∈ Icc 1 x | ∀ p ∈ primesLE z, ¬ p ∣ n} : ℕ) : ℤ)
        = ∑ d ∈ (primorial z).divisors, μ d * ((x / d : ℕ) : ℤ) ∧
      |((#{n ∈ Icc 1 x | ∀ p ∈ primesLE z, ¬ p ∣ n} : ℕ) : ℝ)
          - (x : ℝ) * ∏ p ∈ primesLE z, (1 - 1 / (p : ℝ))|
        ≤ 2 ^ π z := by
  refine ⟨legendre_identity x z, ?_⟩
  have hR : ((#{n ∈ Icc 1 x | ∀ p ∈ primesLE z, ¬ p ∣ n} : ℕ) : ℝ)
      = ∑ d ∈ (primorial z).divisors, (μ d : ℝ) * ((x / d : ℕ) : ℝ) := by
    rw [← Int.cast_natCast, legendre_identity x z, Int.cast_sum]
    apply sum_congr rfl
    intro d _
    rw [Int.cast_mul, Int.cast_natCast]
  rw [hR, main_term_expand, ← sum_sub_distrib]
  calc |∑ d ∈ (primorial z).divisors, ((μ d : ℝ) * ((x / d : ℕ) : ℝ) - (μ d : ℝ) * ((x : ℝ) / d))|
      ≤ ∑ d ∈ (primorial z).divisors,
          |(μ d : ℝ) * ((x / d : ℕ) : ℝ) - (μ d : ℝ) * ((x : ℝ) / d)| := abs_sum_le_sum_abs _ _
    _ ≤ ∑ d ∈ (primorial z).divisors, (1 : ℝ) := by
        apply sum_le_sum
        intro d _
        rw [← mul_sub, abs_mul]
        have h1 : |(μ d : ℝ)| ≤ 1 := by exact_mod_cast abs_moebius_le_one
        have h2 := abs_floor_div_sub_le x d
        calc |(μ d : ℝ)| * |((x / d : ℕ) : ℝ) - (x : ℝ) / d| ≤ 1 * 1 :=
              mul_le_mul h1 h2 (abs_nonneg _) zero_le_one
          _ = 1 := one_mul 1
    _ = 2 ^ π z := by
        rw [sum_const, card_divisors_primorial]; simp

/-- When every prime up to √x is a sieving prime (every prime p with p² ≤ x has p ≤ z), the
survivors of the sieve up to x are exactly the number 1 and the primes above z. -/
theorem legendre_survivors_are_one_and_large_primes (x z : ℕ)
    (h : ∀ p, p.Prime → p * p ≤ x → p ≤ z) :
    {n ∈ Icc 1 x | ∀ p ∈ primesLE z, ¬ p ∣ n} = {n ∈ Icc 1 x | n = 1 ∨ (n.Prime ∧ z < n)} := by
  ext n
  simp only [mem_filter, mem_Icc, mem_primesLE]
  constructor
  · rintro ⟨⟨h1, h2⟩, hnd⟩
    refine ⟨⟨h1, h2⟩, ?_⟩
    by_cases hn1 : n = 1
    · exact Or.inl hn1
    right
    have hp : n.minFac.Prime := Nat.minFac_prime hn1
    have hpz : z < n.minFac := by
      by_contra hc
      exact hnd _ ⟨not_lt.mp hc, hp⟩ (Nat.minFac_dvd n)
    have hprime : n.Prime := by
      by_contra hnp
      have hsq := Nat.minFac_sq_le_self (by omega) hnp
      have := h _ hp (by nlinarith)
      omega
    exact ⟨hprime, lt_of_lt_of_le hpz (Nat.minFac_le (by omega))⟩
  · rintro ⟨⟨h1, h2⟩, hn⟩
    refine ⟨⟨h1, h2⟩, ?_⟩
    rintro p ⟨hpz, hp⟩ hpn
    rcases hn with rfl | ⟨hnp, hzn⟩
    · exact hp.one_lt.ne' (Nat.dvd_one.mp hpn)
    · have := (Nat.prime_dvd_prime_iff_eq hp hnp).mp hpn
      omega

/-- Selberg's parity example: the numbers n up to x with Liouville's λ(n) = +1 that d divides
number exactly (⌊x/d⌋ + λ(d) L(x/d)) / 2, where L(y) = ∑_{m ≤ y} λ(m). So each parity half holds
half the multiples of every d, up to the running total L. -/
theorem liouville_half_multiples_count (x d : ℕ) :
    2 * ((#{n ∈ Icc 1 x | d ∣ n ∧ liouville n = 1} : ℕ) : ℤ)
      = ((x / d : ℕ) : ℤ) + liouville d * ∑ m ∈ Icc 1 (x / d), liouville m := by
  rcases Nat.eq_zero_or_pos d with rfl | hd
  · simp
    intro n h1 _ h0; omega
  have key : 2 * ((#{n ∈ Icc 1 x | d ∣ n ∧ liouville n = 1} : ℕ) : ℤ)
      = ∑ n ∈ {n ∈ Icc 1 x | d ∣ n}, (1 + liouville n) := by
    rw [← filter_filter, card_eq_sum_ones, Nat.cast_sum, mul_sum, sum_filter]
    apply sum_congr rfl
    intro n hn
    have hn0 : n ≠ 0 := by
      simp only [mem_filter, mem_Icc] at hn; omega
    rcases liouville_eq_one_or_neg_one hn0 with h | h <;> simp [h]
  rw [key, filter_dvd_Icc_eq_image x d hd, sum_image (by
    intro a _ b _ hab; exact Nat.eq_of_mul_eq_mul_left hd hab)]
  simp only [liouville_apply_mul, sum_add_distrib, ← mul_sum, sum_const, card_Icc]
  simp

-- The card's worked numbers: sieving 1 to 100 by 2, 3, 5 and 7.
example : primorial 7 = 210 := by decide
example : #{n ∈ Icc 1 100 | ∀ p ∈ primesLE 7, ¬ p ∣ n} = 22 := by decide +kernel
example : #{n ∈ Icc 1 100 | ∀ p ∈ primesLE 5, ¬ p ∣ n} = 26 := by decide
example : ∑ d ∈ (210 : ℕ).divisors, μ d * ((100 / d : ℕ) : ℤ) = 22 := by decide +kernel
example : ∑ d ∈ (210 : ℕ).divisors, μ d * ((210 / d : ℕ) : ℤ) = 48 := by decide +kernel
example : ∑ p ∈ primesLE 7, 100 / p = 117 := by decide
example : (100 : ℤ) - 117 + 45 - 6 = 22 := by norm_num
example : π 100 - π 10 + 1 = 22 := by decide +kernel
example : liouville 12 = -1 := by decide +kernel

#print axioms legendre_sieve_identity_and_error_bound
#print axioms legendre_survivors_are_one_and_large_primes
#print axioms liouville_half_multiples_count
