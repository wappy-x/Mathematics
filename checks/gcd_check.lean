-- Greatest common divisor: for two whole numbers bigger than zero, their gcd is the largest number going into both, it equals the product of the primes they share with each prime kept as often as the poorer side holds it, and every number going into both goes into the gcd.
import Mathlib.Data.Nat.Factorization.Basic
import Mathlib.NumberTheory.Divisors
import Mathlib.Order.Bounds.Defs
import Mathlib.Tactic.NormNum.GCD
import Mathlib.Tactic.Simproc.Factors

/-- The card's main claim. For two whole numbers a and b, both bigger than zero, the greatest
common divisor gcd(a, b) is the largest number that goes into both with nothing left over: it
goes into a, it goes into b, and every number going into both is no bigger than it. -/
theorem gcd_is_largest_common_divisor (a b : ℕ) (ha : 0 < a) (hb : 0 < b) :
    IsGreatest {d : ℕ | d ∣ a ∧ d ∣ b} (Nat.gcd a b) := by
  refine ⟨⟨Nat.gcd_dvd_left a b, Nat.gcd_dvd_right a b⟩, ?_⟩
  rintro d ⟨h1, h2⟩
  exact Nat.le_of_dvd (Nat.gcd_pos_of_pos_left b ha) (Nat.dvd_gcd h1 h2)

/-- Road two, the shared primes. For two whole numbers bigger than zero, the gcd is the product
of the primes both of them hold, each prime kept only as often as the poorer side holds it. -/
theorem gcd_eq_product_of_shared_primes (a b : ℕ) (ha : 0 < a) (hb : 0 < b) :
    Nat.gcd a b =
      ∏ p ∈ a.primeFactors ∩ b.primeFactors, p ^ min (a.factorization p) (b.factorization p) := by
  have hg : Nat.gcd a b ≠ 0 := (Nat.gcd_pos_of_pos_left b ha).ne'
  have hf : (Nat.gcd a b).factorization = a.factorization ⊓ b.factorization :=
    Nat.factorization_gcd ha.ne' hb.ne'
  conv_lhs => rw [← Nat.prod_factorization_pow_eq_self hg]
  rw [Finsupp.prod]
  have hs : (Nat.gcd a b).factorization.support = a.primeFactors ∩ b.primeFactors := by
    ext p
    rw [Finsupp.mem_support_iff, hf, Finset.mem_inter, Nat.mem_primeFactors_of_ne_zero ha.ne',
      Nat.mem_primeFactors_of_ne_zero hb.ne']
    simp only [Finsupp.inf_apply, ne_eq]
    have ha0 := ha.ne'
    have hb0 := hb.ne'
    by_cases hp : p.Prime
    · by_cases hpa : p ∣ a
      · by_cases hpb : p ∣ b
        · have := hp.factorization_pos_of_dvd ha0 hpa
          have := hp.factorization_pos_of_dvd hb0 hpb
          simp only [hp, hpa, hpb, and_self, iff_true]
          exact Nat.pos_iff_ne_zero.mp (lt_min ‹0 < a.factorization p› ‹0 < b.factorization p›)
        · simp [Nat.factorization_eq_zero_of_not_dvd hpb, hpb]
      · simp [Nat.factorization_eq_zero_of_not_dvd hpa, hpa]
    · simp [Nat.factorization_eq_zero_of_not_prime _ hp, hp]
  rw [hs]
  refine Finset.prod_congr rfl fun p _ => ?_
  rw [hf]
  rfl

/-- Every shared number hides inside the gcd. For two whole numbers bigger than zero, a number
goes into both of them exactly when it goes into their gcd. -/
theorem common_divisors_are_divisors_of_gcd (a b : ℕ) (ha : 0 < a) (hb : 0 < b) (d : ℕ) :
    (d ∣ a ∧ d ∣ b) ↔ d ∣ Nat.gcd a b := by
  exact (Nat.dvd_gcd_iff).symm

-- The floor: gcd(180, 300) = 60.
example : Nat.gcd 180 300 = 60 := by norm_num
-- Road one: 180 and 300 each have 18 divisors; the 12 they share are exactly the divisors of 60.
example : (Nat.divisors 180).card = 18 ∧ (Nat.divisors 300).card = 18 := by decide
example : Nat.divisors 180 ∩ Nat.divisors 300 = {1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 60} ∧
    Nat.divisors 180 ∩ Nat.divisors 300 = Nat.divisors 60 ∧ (Nat.divisors 60).card = 12 := by
  decide
-- Nothing from 61 up to 180 goes into both walls.
example : ∀ d ∈ Finset.Icc 61 180, ¬(d ∣ 180 ∧ d ∣ 300) := by decide
-- Road two: 180 = 2 × 2 × 3 × 3 × 5, 300 = 2 × 2 × 3 × 5 × 5, shared 2 × 2 × 3 × 5 = 60.
example : Nat.primeFactorsList 180 = [2, 2, 3, 3, 5] ∧ Nat.primeFactorsList 300 = [2, 2, 3, 5, 5] := by
  norm_num
example : 2 * 2 * 3 * 5 = 60 := by decide
-- 12 = 2 × 2 × 3 goes into 180 with 15 left over; 8 = 2 × 2 × 2 does not, 180 has only two 2s.
example : 12 * 15 = 180 ∧ ¬ 8 ∣ 180 := by decide
-- The tiling: 180 ÷ 60 = 3 across, 300 ÷ 60 = 5 down, 15 tiles.
example : 180 / 60 = 3 ∧ 300 / 60 = 5 ∧ 3 * 5 = 15 := by decide
-- Tiles needed at 10, 12, 15, 20, 30 and 60 cm: 540, 375, 240, 135, 60, 15.
example : [10, 12, 15, 20, 30, 60].map (fun s => (180 / s) * (300 / s)) =
    [540, 375, 240, 135, 60, 15] := by decide
-- The three mistakes: every prime gives 900, which does not go into 180; keeping the spare 5
-- gives 300, which does not go into 180; 30 fits both but costs 60 tiles.
example : 2 * 2 * 3 * 3 * 5 * 5 = 900 ∧ ¬ 900 ∣ 180 ∧ 60 * 5 = 300 ∧ ¬ 300 ∣ 180 ∧
    30 ∣ 180 ∧ 30 ∣ 300 ∧ (180 / 30) * (300 / 30) = 60 := by decide
-- Lowest terms: 180 over 300 becomes 3 over 5, which share nothing but 1.
example : 180 / Nat.gcd 180 300 = 3 ∧ 300 / Nat.gcd 180 300 = 5 ∧ Nat.gcd 3 5 = 1 := by norm_num
-- Try changing: a square room gives gcd 180; a 200 cm wall gives 2 × 2 × 5 = 20.
example : Nat.gcd 180 180 = 180 ∧ Nat.gcd 180 200 = 20 ∧ 2 * 2 * 5 = 20 := by norm_num

#print axioms gcd_is_largest_common_divisor
#print axioms gcd_eq_product_of_shared_primes
#print axioms common_divisors_are_divisors_of_gcd
