-- RSA in full: decrypting on the two prime clocks and gluing with the Chinese remainder theorem gives back every message, and a non-trivial square root of 1 or a faulty CRT half splits n.
import Mathlib.Data.Nat.ModEq
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Data.Int.GCD
import Mathlib.Tactic.NormNum.Prime
import Mathlib.FieldTheory.Finite.Basic

/-- Fermat on one prime clock: if n ≡ 1 (mod r - 1) and n ≥ 1, then x^n ≡ x (mod r). -/
theorem rsa_pow_modEq_self_of_modEq_one (r n x : ℕ) (hr : r.Prime) (hn : n ≡ 1 [MOD r - 1])
    (hn1 : 1 ≤ n) : x ^ n ≡ x [MOD r] := by
  have := Fact.mk hr
  obtain ⟨k, hk⟩ := (Nat.modEq_iff_dvd' hn1).1 hn.symm
  have hn' : n = (r - 1) * k + 1 := by omega
  rw [← ZMod.natCast_eq_natCast_iff]
  push_cast
  by_cases hx : (x : ZMod r) = 0
  · rw [hx, zero_pow (by omega)]
  · rw [hn', pow_succ, pow_mul, ZMod.pow_card_sub_one_eq_one hx, one_pow, one_mul]

#print axioms rsa_pow_modEq_self_of_modEq_one

/-- Decryption on the clock of an odd prime factor p of n gives back m mod p. -/
theorem rsa_clock_decrypt (p n e d m : ℕ) (hp : p.Prime) (hp2 : p ≠ 2) (hpn : p ∣ n)
    (hd : e * d ≡ 1 [MOD p - 1]) :
    (m ^ e % n) ^ (d % (p - 1)) % p = m % p := by
  have hp3 : 3 ≤ p := by have := hp.two_le; omega
  have h1 : e * (d % (p - 1)) ≡ 1 [MOD p - 1] :=
    ((Nat.mod_modEq d (p - 1)).mul_left e).trans hd
  have hpos : 1 ≤ e * (d % (p - 1)) := by
    by_contra h0
    have h0' : e * (d % (p - 1)) = 0 := by omega
    rw [h0'] at h1
    have : 1 % (p - 1) = 1 := Nat.mod_eq_of_lt (by omega)
    unfold Nat.ModEq at h1
    rw [this, Nat.zero_mod] at h1
    exact absurd h1 (by norm_num)
  have hc : m ^ e % n ≡ m ^ e [MOD p] := Nat.mod_mod_of_dvd _ hpn
  have h2 : (m ^ e) ^ (d % (p - 1)) ≡ m [MOD p] := by
    rw [← pow_mul]; exact rsa_pow_modEq_self_of_modEq_one p _ m hp h1 hpos
  exact (hc.pow (d % (p - 1))).trans h2

#print axioms rsa_clock_decrypt

/-- RSA decryption on two prime clocks: let p and q be distinct primes, n = p q, and let d undo
e on the clock of size phi(n) = (p - 1)(q - 1), that is e d ≡ 1 (mod phi(n)). Encrypt any
message m < n as c = m^e mod n. Raise c to d_p = d mod (p - 1) on the p clock and to
d_q = d mod (q - 1) on the q clock, and glue the two remainders with the Chinese remainder
theorem. The glued number is m again. The primes are odd, as the card's key generation draws
only odd numbers: for p = 2, d mod (p - 1) = 0 and every even m would glue back wrong. -/
theorem rsa_crt_decryption_recovers_message (p q e d m : ℕ) (hp : p.Prime) (hq : q.Prime)
    (hpq : p ≠ q) (hp2 : p ≠ 2) (hq2 : q ≠ 2) (hd : e * d ≡ 1 [MOD (p - 1) * (q - 1)]) (hm : m < p * q) :
    let c := m ^ e % (p * q)
    (Nat.chineseRemainder ((Nat.coprime_primes hp hq).2 hpq)
        (c ^ (d % (p - 1)) % p) (c ^ (d % (q - 1)) % q) : ℕ) = m := by
  intro c
  have co := (Nat.coprime_primes hp hq).2 hpq
  have hdp : e * d ≡ 1 [MOD p - 1] := hd.of_dvd (dvd_mul_right _ _)
  have hdq : e * d ≡ 1 [MOD q - 1] := hd.of_dvd (dvd_mul_left _ _)
  have hcp : c ^ (d % (p - 1)) % p = m % p :=
    rsa_clock_decrypt p (p * q) e d m hp hp2 (dvd_mul_right _ _) hdp
  have hcq : c ^ (d % (q - 1)) % q = m % q :=
    rsa_clock_decrypt q (p * q) e d m hq hq2 (dvd_mul_left _ _) hdq
  rw [hcp, hcq]
  have hu := Nat.chineseRemainder_modEq_unique co (z := m)
    (a := m % p) (b := m % q) (Nat.mod_modEq m p).symm (Nat.mod_modEq m q).symm
  have hlt := Nat.chineseRemainder_lt_mul co (m % p) (m % q) hp.ne_zero hq.ne_zero
  exact (Nat.ModEq.eq_of_lt_of_lt hu hm hlt).symm

/-- d gives the factors: on n = p q with p and q distinct primes, a square root x of 1 that is
neither 1 nor -1 (that is, not n - 1) shares exactly one prime with n, so gcd(x - 1, n) is p
or q. -/
theorem rsa_extra_square_root_of_one_splits_n (p q x : ℕ) (hp : p.Prime) (hq : q.Prime)
    (hpq : p ≠ q) (hx : x < p * q) (hsq : x * x % (p * q) = 1) (h1 : x ≠ 1)
    (hneg : x ≠ p * q - 1) :
    Nat.gcd (x - 1) (p * q) = p ∨ Nat.gcd (x - 1) (p * q) = q := by
  have hp2 := hp.two_le
  have hq2 := hq.two_le
  have hn4 : 4 ≤ p * q := Nat.mul_le_mul hp2 hq2
  have hx2 : 2 ≤ x := by
    rcases Nat.lt_or_ge x 2 with h | h
    · interval_cases x
      · simp at hsq
      · exact absurd rfl h1
    · exact h
  have hdvd : p * q ∣ (x - 1) * (x + 1) := by
    have h := Nat.div_add_mod (x * x) (p * q)
    rw [hsq] at h
    have he : (x - 1) * (x + 1) = x * x - 1 := by
      obtain ⟨y, rfl⟩ : ∃ y, x = y + 1 := ⟨x - 1, by omega⟩
      simp only [Nat.add_sub_cancel]
      ring_nf
      omega
    rw [he]
    exact ⟨x * x / (p * q), by omega⟩
  set g := Nat.gcd (x - 1) (p * q) with hg
  have hgd : g ∣ p * q := Nat.gcd_dvd_right _ _
  obtain ⟨a, b, ha, hb, hab⟩ := Nat.dvd_mul.1 hgd
  rcases (Nat.dvd_prime hp).1 ha with ha' | ha' <;>
    rcases (Nat.dvd_prime hq).1 hb with hb' | hb' <;> rw [ha', hb'] at hab
  · -- g = 1: then p q divides x + 1, so x = p q - 1
    exfalso
    have hcop : Nat.Coprime (p * q) (x - 1) := by
      rw [Nat.Coprime, Nat.gcd_comm, ← hg, ← hab]
    have h2 : p * q ∣ x + 1 := hcop.dvd_of_dvd_mul_left hdvd
    have h3 := Nat.le_of_dvd (by omega) h2
    have h4 : x + 1 = p * q := by
      obtain ⟨k, hk⟩ := h2
      rcases k with _ | _ | k
      · omega
      · omega
      · nlinarith
    omega
  · right; rw [← hab]; ring
  · left; rw [← hab]; ring
  · -- g = p q: then p q divides x - 1, impossible since 0 < x - 1 < p q
    exfalso
    have h2 : p * q ∣ x - 1 := by rw [hab, hg]; exact Nat.gcd_dvd_left _ _
    have h3 := Nat.le_of_dvd (by omega) h2
    omega

/-- Break 3, a CRT fault: with an RSA key (distinct primes p, q, n = p q, e d ≡ 1 mod phi(n))
and ciphertext c = m^e mod n, a faulty decryption "bad" that is right mod p but wrong mod q
gives gcd(bad^e - c, n) = p. -/
theorem rsa_crt_fault_reveals_prime (p q e d m bad : ℕ) (hp : p.Prime) (hq : q.Prime)
    (hpq : p ≠ q) (hd : e * d ≡ 1 [MOD (p - 1) * (q - 1)])
    (hbp : bad ≡ m [MOD p]) (hbq : ¬ bad ≡ m [MOD q]) :
    Int.gcd ((bad : ℤ) ^ e - ((m ^ e % (p * q) : ℕ) : ℤ)) ((p * q : ℕ) : ℤ) = p := by
  have hp2 := hp.two_le
  have hq2 := hq.two_le
  -- e d ≥ 1, since phi(n) ≥ 2 for distinct primes
  have hed : 1 ≤ e * d := by
    by_contra h0
    have h0' : e * d = 0 := by omega
    have h := hd
    unfold Nat.ModEq at h
    rw [h0', Nat.zero_mod] at h
    have h1 : (p - 1) * (q - 1) ∣ 1 := Nat.dvd_of_mod_eq_zero h.symm
    have h2 := mul_eq_one.1 (Nat.dvd_one.1 h1)
    omega
  have hdq : e * d ≡ 1 [MOD q - 1] := hd.of_dvd (dvd_mul_left _ _)
  -- the difference as a natural-number congruence statement
  set D : ℤ := (bad : ℤ) ^ e - ((m ^ e % (p * q) : ℕ) : ℤ) with hD
  have hcast : ∀ r : ℕ, r ∣ p * q →
      (((r : ℕ) : ℤ) ∣ D ↔ m ^ e % (p * q) ≡ bad ^ e [MOD r]) := by
    intro r _
    rw [← Int.natCast_modEq_iff, Int.modEq_iff_dvd, hD]
    push_cast
    rfl
  have hpD : (p : ℤ) ∣ D := by
    rw [hcast p (dvd_mul_right _ _)]
    exact (Nat.mod_mod_of_dvd _ (dvd_mul_right p q)).trans (hbp.pow e).symm
  have hqD : ¬ (q : ℤ) ∣ D := by
    rw [hcast q (dvd_mul_left _ _)]
    intro h
    have h' : bad ^ e ≡ m ^ e [MOD q] :=
      (h.symm.trans (Nat.mod_mod_of_dvd _ (dvd_mul_left q p)))
    have h'' := h'.pow d
    rw [← pow_mul, ← pow_mul] at h''
    exact hbq ((rsa_pow_modEq_self_of_modEq_one q _ bad hq hdq hed).symm.trans
      (h''.trans (rsa_pow_modEq_self_of_modEq_one q _ m hq hdq hed)))
  rw [Int.gcd_eq_natAbs, Int.natAbs_natCast]
  have hpg : p ∣ Nat.gcd D.natAbs (p * q) :=
    Nat.dvd_gcd (Int.ofNat_dvd_left.1 hpD) (dvd_mul_right _ _)
  have hqg : ¬ q ∣ Nat.gcd D.natAbs (p * q) := fun h =>
    hqD (Int.ofNat_dvd_left.2 (h.trans (Nat.gcd_dvd_left _ _)))
  obtain ⟨k, hk⟩ := hpg
  have hkq : k ∣ q := by
    have := Nat.gcd_dvd_right D.natAbs (p * q)
    rw [hk] at this
    exact (Nat.mul_dvd_mul_iff_left hp.pos).1 this
  rcases (Nat.dvd_prime hq).1 hkq with hk' | hk'
  · rw [hk, hk', mul_one]
  · exact absurd (hk ▸ hk' ▸ dvd_mul_left q p) hqg

-- The 1978 paper's test vector: p = 47, q = 59, e = 17.
example : Nat.Prime 47 ∧ Nat.Prime 59 ∧ 47 * 59 = 2773 := by norm_num
example : 17 * 157 % (46 * 58) = 1 := by decide
example : 920 ^ 17 % 2773 = 948 := by decide
example : 948 ^ 157 % 2773 = 920 := by decide
-- The same decryption on the two prime clocks: d_p = 157 mod 46 = 19, d_q = 157 mod 58 = 41.
example : 157 % 46 = 19 ∧ 157 % 58 = 41 := by decide
example : 948 ^ 19 % 47 = 920 % 47 ∧ 948 ^ 41 % 59 = 920 % 59 := by decide
-- The 64-bit toy key: two 32-bit primes whose product has 64 bits.
set_option maxRecDepth 100000 in
example : Nat.Prime 3516228229 ∧ Nat.Prime 4270626263 := by norm_num
example : 3516228229 * 4270626263 = 15016496621469378227 := by norm_num
example : 2 ^ 63 ≤ 15016496621469378227 ∧ 15016496621469378227 < 2 ^ 64 := by norm_num
-- Break 2: the doubled textbook amount; OAEP's largest message at 2048 bits (256-byte key).
example : 500 * 2 = 1000 := by decide
example : 256 - 2 * 32 - 2 = 190 := by decide

#print axioms rsa_crt_decryption_recovers_message
#print axioms rsa_extra_square_root_of_one_splits_n
#print axioms rsa_crt_fault_reveals_prime
