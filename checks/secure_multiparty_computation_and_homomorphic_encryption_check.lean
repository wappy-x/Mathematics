-- Computing on secrets: Paillier's product of ciphertexts decrypts to the sum of the messages, a Beaver triple turns published differences into shares of the true product, and additive shares add to the true total while any two of three are uniformly random.
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.NormNum.DivMod
import Mathlib.Tactic.NormNum.GCD
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.Ring
import Mathlib.FieldTheory.Finite.Basic

open Finset

theorem one_add_pow_modEq (n k : ℕ) : (n + 1) ^ k ≡ 1 + k * n [MOD n ^ 2] := by
  induction k with
  | zero => simp [Nat.ModEq]
  | succ k ih =>
    have h1 : (n + 1) ^ (k + 1) ≡ (1 + k * n) * (n + 1) [MOD n ^ 2] := by
      rw [pow_succ]; exact ih.mul_right _
    refine h1.trans ?_
    have : (1 + k * n) * (n + 1) = 1 + (k + 1) * n + k * n ^ 2 := by ring
    rw [this]
    unfold Nat.ModEq
    rw [Nat.add_mul_mod_self_right]

#print axioms one_add_pow_modEq

theorem pow_modEq_one_prime_sq (p q r k : ℕ) (hp : p.Prime) (hr : Nat.Coprime r p) :
    r ^ (p * q * Nat.lcm (p - 1) k) ≡ 1 [MOD p ^ 2] := by
  have ht : r ^ Nat.totient (p ^ 2) ≡ 1 [MOD p ^ 2] :=
    Nat.ModEq.pow_totient (Nat.Coprime.pow_right 2 hr)
  rw [Nat.totient_prime_pow hp (by norm_num)] at ht
  have hd : p ^ (2 - 1) * (p - 1) ∣ p * q * Nat.lcm (p - 1) k := by
    simpa using mul_dvd_mul (dvd_mul_right p q) (Nat.dvd_lcm_left (p - 1) k)
  obtain ⟨c, hc⟩ := hd
  rw [hc, pow_mul]
  simpa using ht.pow c

#print axioms pow_modEq_one_prime_sq

/-- Paillier adds under encryption: let p and q be distinct primes, n = p q, g = n + 1,
λ = lcm(p - 1, q - 1), and μ the number that multiplies λ to 1 mod n. Encrypt m with a random r
sharing no factor with n as Enc(m, r) = g^m r^n mod n², and decrypt c as L(c^λ mod n²) μ mod n
with L(u) = (u - 1)/n. Then the product of two ciphertexts, mod n², decrypts to the sum of the
two messages, provided that sum is below n. -/
theorem paillier_product_decrypts_to_sum (p q μ m₁ m₂ r₁ r₂ : ℕ) (hp : p.Prime) (hq : q.Prime)
    (hpq : p ≠ q) (hμ : Nat.lcm (p - 1) (q - 1) * μ % (p * q) = 1)
    (hr₁ : Nat.Coprime r₁ (p * q)) (hr₂ : Nat.Coprime r₂ (p * q)) (hm : m₁ + m₂ < p * q) :
    let n := p * q
    let g := n + 1
    let lam := Nat.lcm (p - 1) (q - 1)
    let enc := fun m r : ℕ => g ^ m * r ^ n % n ^ 2
    let L := fun u : ℕ => (u - 1) / n
    let dec := fun c : ℕ => L (c ^ lam % n ^ 2) * μ % n
    dec (enc m₁ r₁ * enc m₂ r₂ % n ^ 2) = m₁ + m₂ := by
  intro n g lam enc L dec
  have hp2 := hp.two_le
  have hq2 := hq.two_le
  have hn : 2 ≤ n := by
    show 2 ≤ p * q
    nlinarith
  have hn0 : 0 < n := by omega
  set m := m₁ + m₂ with hm_def
  set r := r₁ * r₂ with hr_def
  have hr : Nat.Coprime r (p * q) := Nat.coprime_mul_iff_left.mpr ⟨hr₁, hr₂⟩
  have hC : (enc m₁ r₁ * enc m₂ r₂ % n ^ 2) ≡ (n + 1) ^ m * r ^ n [MOD n ^ 2] := by
    show (g ^ m₁ * r₁ ^ n % n ^ 2 * (g ^ m₂ * r₂ ^ n % n ^ 2)) % n ^ 2 % n ^ 2 = _
    rw [Nat.mod_mod, ← Nat.mul_mod, hm_def, hr_def, pow_add, mul_pow]
    congr 1
    ring
  have hrp : r ^ (n * lam) ≡ 1 [MOD p ^ 2] :=
    pow_modEq_one_prime_sq p q r (q - 1) hp (Nat.Coprime.coprime_mul_right_right hr)
  have hrq : r ^ (n * lam) ≡ 1 [MOD q ^ 2] := by
    have := pow_modEq_one_prime_sq q p r (p - 1) hq (Nat.Coprime.coprime_mul_left_right hr)
    show r ^ (p * q * Nat.lcm (p - 1) (q - 1)) ≡ 1 [MOD q ^ 2]
    rwa [mul_comm p q, Nat.lcm_comm]
  have hcop : Nat.Coprime (p ^ 2) (q ^ 2) :=
    Nat.Coprime.pow 2 2 ((Nat.coprime_primes hp hq).mpr hpq)
  have hrn : r ^ (n * lam) ≡ 1 [MOD n ^ 2] := by
    have := (Nat.modEq_and_modEq_iff_modEq_mul hcop).mp ⟨hrp, hrq⟩
    show r ^ (n * lam) ≡ 1 [MOD (p * q) ^ 2]
    rwa [mul_pow]
  have hpow : (enc m₁ r₁ * enc m₂ r₂ % n ^ 2) ^ lam ≡ 1 + (m * lam % n) * n [MOD n ^ 2] := by
    have h1 := hC.pow lam
    rw [mul_pow ((n + 1) ^ m) (r ^ n) lam, ← pow_mul, ← pow_mul] at h1
    have h2 := (one_add_pow_modEq n (m * lam)).mul hrn
    rw [mul_one] at h2
    refine (h1.trans h2).trans ?_
    have hdiv := Nat.div_add_mod (m * lam) n
    have : 1 + m * lam * n = 1 + (m * lam % n) * n + (m * lam / n) * n ^ 2 := by
      conv_lhs => rw [← hdiv]
      ring
    rw [this]
    unfold Nat.ModEq
    rw [Nat.add_mul_mod_self_right]
  have hlt : 1 + (m * lam % n) * n < n ^ 2 := by
    have : m * lam % n + 1 ≤ n := Nat.mod_lt _ hn0
    nlinarith
  have hkey : (enc m₁ r₁ * enc m₂ r₂ % n ^ 2) ^ lam % n ^ 2 = 1 + (m * lam % n) * n := by
    rw [hpow]
    exact Nat.mod_eq_of_lt hlt
  show L ((enc m₁ r₁ * enc m₂ r₂ % n ^ 2) ^ lam % n ^ 2) * μ % n = m
  rw [hkey]
  show (1 + (m * lam % n) * n - 1) / n * μ % n = m
  rw [Nat.add_sub_cancel_left, Nat.mul_div_cancel _ hn0, Nat.mod_mul_mod, mul_assoc,
    Nat.mul_mod, hμ, mul_one, Nat.mod_mod, Nat.mod_eq_of_lt hm]

#print axioms paillier_product_decrypts_to_sum

/-- One product from a prepared Beaver triple: the parties hold shares of x, y and of a triple
a, b, c with c = a b, all on a clock of M. They publish d = x - a and e = y - b, each party sets
its share of the product to c_i + d b_i + e a_i, and one party also adds d e. The shares then
add to x y, the true product, since x y = c + d b + e a + d e. -/
theorem beaver_triple_shares_sum_to_product {ι : Type*} [Fintype ι] [DecidableEq ι] (M : ℕ)
    (i₀ : ι) (x y a b c : ι → ZMod M) (hc : ∑ i, c i = (∑ i, a i) * (∑ i, b i)) :
    let d := ∑ i, (x i - a i)
    let e := ∑ i, (y i - b i)
    ∑ i, (c i + d * b i + e * a i + if i = i₀ then d * e else 0) = (∑ i, x i) * (∑ i, y i) := by
  intro d e
  simp only [Finset.sum_add_distrib, ← Finset.mul_sum, Finset.sum_ite_eq', Finset.mem_univ,
    ite_true, hc, d, e, Finset.sum_sub_distrib]
  ring

#print axioms beaver_triple_shares_sum_to_product

/-- Additive shares on a clock of M: if every branch splits its takings x_i into three shares
that add to x_i mod M, then the three published sums (what each share-holder adds up) add to
the true total. And for any input t, splitting it as s₁, s₂, t - s₁ - s₂ from two coins s₁, s₂
makes any two of the three shares a one-to-one, onto function of the coins: with uniform coins,
every pair of share values is equally likely, whatever t is. -/
theorem additive_shares_total_and_privacy {ι : Type*} [Fintype ι] (M : ℕ) (x : ι → ZMod M)
    (sh : ι → Fin 3 → ZMod M) (hsh : ∀ i, ∑ j, sh i j = x i) :
    ∑ j, (∑ i, sh i j) = ∑ i, x i ∧
    ∀ (t : ZMod M) (j k : Fin 3), j ≠ k →
      Function.Bijective (fun s : ZMod M × ZMod M =>
        ((![s.1, s.2, t - s.1 - s.2] : Fin 3 → ZMod M) j,
         (![s.1, s.2, t - s.1 - s.2] : Fin 3 → ZMod M) k)) := by
  refine ⟨?_, ?_⟩
  · rw [Finset.sum_comm]
    exact Finset.sum_congr rfl (fun i _ => hsh i)
  · intro t j k hjk
    rw [Function.bijective_iff_has_inverse]
    fin_cases j <;> fin_cases k <;> simp at hjk
    · exact ⟨fun u => (u.1, u.2), fun s => by simp, fun u => by simp⟩
    · exact ⟨fun u => (u.1, t - u.1 - u.2), fun s => by ext <;> simp <;> ring,
        fun u => by ext <;> simp <;> ring⟩
    · exact ⟨fun u => (u.2, u.1), fun s => by simp, fun u => by simp⟩
    · exact ⟨fun u => (t - u.1 - u.2, u.1), fun s => by ext <;> simp <;> ring,
        fun u => by ext <;> simp <;> ring⟩
    · exact ⟨fun u => (u.2, t - u.1 - u.2), fun s => by ext <;> simp <;> ring,
        fun u => by ext <;> simp <;> ring⟩
    · exact ⟨fun u => (t - u.1 - u.2, u.2), fun s => by ext <;> simp <;> ring,
        fun u => by ext <;> simp <;> ring⟩

#print axioms additive_shares_total_and_privacy

-- Leeds's three shares mod 2^32 add back to its takings, 184,250 p.
example : (2442431779 + 3979691357 + 2167995706) % 2 ^ 32 = 184250 := by norm_num
-- What Leeds, York and Hull each hold: one share from every branch, added mod 2^32.
example : (2442431779 + 3454187662 + 127467337) % 2 ^ 32 = 1729119482 := by norm_num
example : (3979691357 + 3584099570 + 1986288131) % 2 ^ 32 = 960144466 := by norm_num
example : (2167995706 + 1551879035 + 2181362748) % 2 ^ 32 = 1606270193 := by norm_num
-- The three published sums give the total, 566,845 p = £5,668.45, the direct sum.
example : (1729119482 + 960144466 + 1606270193) % 2 ^ 32 = 566845 := by norm_num
example : 184250 + 231675 + 150920 = 566845 := by norm_num
-- Leeds infers York + Hull from the total.
example : 566845 - 184250 = 382595 := by norm_num
-- Beaver by hand: a = 100, b = 1,000, c = 100,000, d = 20, e = 840 give 120 × 1,840 = 220,800.
example : 100000 + 20 * 1000 + 840 * 100 + 20 * 840 = 220800 ∧ 120 * 1840 = 220800 := by norm_num
-- The run's triple and its product shares mod 2^32.
example : 438309620 * 350766914 % 2 ^ 32 = 3735457512 := by norm_num
example : (3283059613 + 2580639875 + 2726455904) % 2 ^ 32 = 220800 := by norm_num
-- Toy Paillier, n = 77: λ = lcm(6, 10) = 30 and μ = 18 multiplies it to 1 mod 77.
example : Nat.lcm 6 10 = 30 ∧ 30 * 18 % 77 = 1 := by norm_num
-- Leeds encrypts 18 with r = 5: g^18 = 1,387, 5^77 = 1,697, Enc = 5,855.
example : 78 ^ 18 % 5929 = 1387 ∧ 5 ^ 77 % 5929 = 1697 ∧ 78 ^ 18 * 5 ^ 77 % 5929 = 5855 := by
  norm_num
-- York's 23 with r = 13 and Hull's 15 with r = 20.
example : 78 ^ 23 * 13 ^ 77 % 5929 = 4451 ∧ 78 ^ 15 * 20 ^ 77 % 5929 = 4822 := by norm_num
-- Multiply the three ciphertexts and decrypt: 1,305; 1,305^30 = 4,852; L = 63; 63 × 18 mod 77 = 56.
example : 5855 * 4451 * 4822 % 5929 = 1305 ∧ 1305 ^ 30 % 5929 = 4852 ∧
    (4852 - 1) / 77 = 63 ∧ 63 * 18 % 77 = 56 := by norm_num
-- Break 3, r = 1: Enc(18) = 1,387 and anyone reads (1,387 - 1)/77 = 18.
example : (1387 - 1) / 77 = 18 := by norm_num
-- Break 4, a week: Enc(56)^7 decrypts to 7, not 392, since 392 wraps mod 77.
example : ((1305 ^ 7 % 5929) ^ 30 % 5929 - 1) / 77 * 18 % 77 = 7 ∧ 392 % 77 = 7 := by norm_num
-- The toy FHE noise 1,157,625 after the 10th multiplication passes K/2 = 500,001.
example : 1000003 / 2 = 500001 ∧ 500001 < 1157625 := by norm_num
