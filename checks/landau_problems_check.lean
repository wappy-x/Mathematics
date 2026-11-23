-- Landau's four problems: the four problems stated exactly (open, not proved here), the gap argument that turns a prime-gap table into a Legendre check, two facts about n^2 + 1 and n^2 - 1, and the card's whole-number examples.
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Data.Set.Finite.Basic
import Mathlib.Algebra.Order.Group.Nat
import Mathlib.Tactic.NormNum.Prime
import Mathlib.NumberTheory.LegendreSymbol.Basic
import Mathlib.Data.Nat.Find

/-- Landau's problem 1 (open as of 2026-11-23; the card does not prove it):
n^2 + 1 is prime for infinitely many whole numbers n. -/
def LandauSquarePlusOne : Prop :=
  {n : ℕ | (n ^ 2 + 1).Prime}.Infinite

/-- Landau's problem 2, Goldbach (open as of 2026-11-23): every even m ≥ 4 is p + q
with p and q prime. -/
def LandauGoldbach : Prop :=
  ∀ m : ℕ, Even m → 4 ≤ m → ∃ p q : ℕ, p.Prime ∧ q.Prime ∧ m = p + q

/-- Landau's problem 3, twin primes (open as of 2026-11-23): there are infinitely many
primes p with p + 2 also prime, so the twin-pair count π₂(x) grows without bound. -/
def LandauTwinPrimes : Prop :=
  {p : ℕ | p.Prime ∧ (p + 2).Prime}.Infinite

/-- Landau's problem 4, Legendre (open as of 2026-11-23): for every whole number n ≥ 1
there is a prime strictly between n^2 and (n + 1)^2. -/
def LandauLegendre : Prop :=
  ∀ n : ℕ, 1 ≤ n → ∃ p : ℕ, p.Prime ∧ n ^ 2 < p ∧ p < (n + 1) ^ 2

/-- The gap argument behind the Legendre check: for n ≥ 1, if no prime lies strictly
between n^2 and (n + 1)^2, then two consecutive primes p < q (no prime between them)
straddle the interval, p below n^2 and q above (n + 1)^2, and they are at least
2n + 3 apart. So a table of prime gaps all smaller than 2n + 3 proves Legendre at n. -/
theorem legendre_failure_forces_gap (n : ℕ) (hn : 1 ≤ n)
    (hnone : ∀ m : ℕ, n ^ 2 < m → m < (n + 1) ^ 2 → ¬ m.Prime) :
    ∃ p q : ℕ, p.Prime ∧ q.Prime ∧ p < n ^ 2 ∧ (n + 1) ^ 2 < q ∧
      (∀ m : ℕ, p < m → m < q → ¬ m.Prime) ∧ 2 * n + 3 ≤ q - p := by
  by_cases h1 : n = 1
  · subst h1
    exact absurd Nat.prime_two (hnone 2 (by norm_num) (by norm_num))
  have hn2 : 2 ≤ n := by omega
  have hsq : 4 ≤ n ^ 2 := by nlinarith
  have hnp : ¬ (n ^ 2).Prime := by
    rw [pow_two]; exact Nat.not_prime_mul (by omega) (by omega)
  have hnp' : ¬ ((n + 1) ^ 2).Prime := by
    rw [pow_two]; exact Nat.not_prime_mul (by omega) (by omega)
  -- p: the largest prime at most n^2
  set p := Nat.findGreatest Nat.Prime (n ^ 2) with hpdef
  have hpP : p.Prime := Nat.findGreatest_spec (P := Nat.Prime) (by omega : 2 ≤ n ^ 2) Nat.prime_two
  have hple : p ≤ n ^ 2 := Nat.findGreatest_le _
  have hplt : p < n ^ 2 := lt_of_le_of_ne hple (fun h => hnp (h ▸ hpP))
  -- q: the smallest prime above n^2
  have hex : ∃ q, n ^ 2 < q ∧ q.Prime := by
    obtain ⟨q, hq1, hq2⟩ := Nat.exists_infinite_primes (n ^ 2 + 1)
    exact ⟨q, by omega, hq2⟩
  classical
  let q := Nat.find hex
  have hq : n ^ 2 < q ∧ q.Prime := Nat.find_spec hex
  have hqmin : ∀ m, m < q → ¬ (n ^ 2 < m ∧ m.Prime) := fun m hm => Nat.find_min hex hm
  have hqgt : (n + 1) ^ 2 < q := by
    by_contra hc
    push Not at hc
    rcases lt_or_eq_of_le hc with hc | hc
    · exact hnone q hq.1 hc hq.2
    · exact hnp' (hc ▸ hq.2)
  refine ⟨p, q, hpP, hq.2, hplt, hqgt, ?_, ?_⟩
  · intro m hpm hmq hm
    by_cases hmn : m ≤ n ^ 2
    · exact Nat.findGreatest_is_greatest (P := Nat.Prime) hpm hmn hm
    · exact hqmin m hmq ⟨by omega, hm⟩
  · have : (n + 1) ^ 2 = n ^ 2 + 2 * n + 1 := by ring
    omega

/-- An odd prime divides some n^2 + 1 only if it leaves remainder 1 on division by 4. -/
theorem odd_prime_dvd_sq_add_one_mod_four (p n : ℕ) (hp : p.Prime) (hodd : p ≠ 2)
    (hdvd : p ∣ n ^ 2 + 1) : p % 4 = 1 := by
  have := Fact.mk hp
  have h0 : ((n : ZMod p)) ^ 2 = -1 := by
    have : ((n ^ 2 + 1 : ℕ) : ZMod p) = 0 := (ZMod.natCast_eq_zero_iff _ _).2 hdvd
    push_cast at this
    exact eq_neg_of_add_eq_zero_left this
  have h3 := ZMod.mod_four_ne_three_of_sq_eq_neg_one h0
  have hodd' : p % 2 = 1 := hp.eq_two_or_odd.resolve_left hodd
  omega

/-- n^2 - 1 = (n - 1)(n + 1) has a forced factor, so it is prime only at n = 2. -/
theorem sq_sub_one_prime_iff (n : ℕ) : (n ^ 2 - 1).Prime ↔ n = 2 := by
  have hfac : n ^ 2 - 1 = (n + 1) * (n - 1) := by
    have := Nat.sq_sub_sq n 1
    simpa using this
  constructor
  · intro h
    rw [hfac, Nat.prime_mul_iff] at h
    rcases h with ⟨_, h⟩ | ⟨hpr, h⟩
    · omega
    · have h0 : n = 0 := by omega
      subst h0
      exact absurd hpr (by norm_num)
  · rintro rfl
    norm_num

-- The example: 100^2 = 10,000 and 101^2 = 10,201, and 10,007 is a prime between them.
example : 100 ^ 2 = 10000 ∧ 101 ^ 2 = 10201 ∧ Nat.Prime 10007 ∧ 10000 < 10007 ∧ 10007 < 10201 := by
  norm_num
-- Legendre holds at n = 100.
example : ∃ p : ℕ, p.Prime ∧ 100 ^ 2 < p ∧ p < (100 + 1) ^ 2 := by
  refine ⟨10007, ?_, ?_, ?_⟩ <;> norm_num
-- The odd numbers before 10,007 in the interval are not prime.
example : 10001 = 73 * 137 ∧ 10003 = 7 * 1429 ∧ 10005 = 3 * 5 * 23 * 29 ∧
    ¬ Nat.Prime 10001 ∧ ¬ Nat.Prime 10003 ∧ ¬ Nat.Prime 10005 := by
  norm_num
-- 10,007 checked by the primes up to 97: 97 < 101 and 101 * 101 = 10,201 > 10,007.
example : 101 * 101 = 10201 ∧ 10007 < 101 * 101 ∧ 10007 % 97 ≠ 0 := by norm_num
-- 100^2 + 1 = 10,001 = 73 * 137, both factors prime and leaving remainder 1 on division by 4.
example : 100 ^ 2 + 1 = 73 * 137 ∧ Nat.Prime 73 ∧ Nat.Prime 137 ∧ 73 % 4 = 1 ∧ 137 % 4 = 1 := by
  norm_num
-- Goldbach: 10,000 = 59 + 9,941, both prime.
example : 10000 = 59 + 9941 ∧ Nat.Prime 59 ∧ Nat.Prime 9941 := by norm_num
-- The five twin pairs between 10,000 and 10,201.
example : Nat.Prime 10007 ∧ Nat.Prime 10009 ∧ Nat.Prime 10037 ∧ Nat.Prime 10039 ∧
    Nat.Prime 10067 ∧ Nat.Prime 10069 ∧ Nat.Prime 10091 ∧ Nat.Prime 10093 ∧
    Nat.Prime 10139 ∧ Nat.Prime 10141 := by
  norm_num
-- Boundary of Goldbach: 11 is odd and 11 - 2 = 9 is not prime.
example : 11 - 2 = 9 ∧ ¬ Nat.Prime 9 := by norm_num
-- At n = 100 a Legendre failure needs a gap of at least 203.
example : 2 * 100 + 3 = 203 := by norm_num
-- The largest gap below 10^6: 114, from the prime 492,113 to the prime 492,227.
example : Nat.Prime 492113 ∧ Nat.Prime 492227 ∧ 492227 - 492113 = 114 := by norm_num
-- The 2014 record gap 1,476 clears every n from 737 up; the check ends at
-- (n + 1)^2 = 2,000,000,000^2 = 4 * 10^18.
example : (1476 - 3) / 2 + 1 = 737 ∧ 2 * 737 + 3 > 1476 ∧ 2 * 736 + 3 ≤ 1476 ∧
    2000000000 ^ 2 = 4 * 10 ^ 18 := by
  norm_num
-- 2^40 = 1,099,511,627,776.
example : 2 ^ 40 = 1099511627776 := by norm_num
-- n^2 - 1 is prime at n = 2 (it is 3) and not at n = 3 (it is 8 = 2 * 4).
example : Nat.Prime (2 ^ 2 - 1) ∧ ¬ Nat.Prime (3 ^ 2 - 1) := by norm_num

#print axioms legendre_failure_forces_gap
#print axioms odd_prime_dvd_sq_add_one_mod_four
#print axioms sq_sub_one_prime_iff
