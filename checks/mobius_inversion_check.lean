-- The Mobius function: weighting a divisor sum by the Möbius signs gives back the function that was summed, for any function at all, and inverting Gauss's identity gives the totient as n times the product of (1 - 1/p).
import Mathlib.NumberTheory.ArithmeticFunction.Moebius
import Mathlib.Data.Nat.Totient
import Mathlib.Data.Nat.Squarefree
import Mathlib.Data.Real.Archimedean
import Mathlib.Tactic.Simproc.Factors
import Mathlib.Tactic.Simproc.Divisors
import Mathlib.Algebra.Order.Floor.Semifield

open ArithmeticFunction ArithmeticFunction.Moebius

theorem moebius_divisor_sum_eq (k : ℕ) :
    ∑ d ∈ k.divisors, μ d = if k = 1 then 1 else 0 := by
  rw [← coe_mul_zeta_apply, moebius_mul_coe_zeta, ArithmeticFunction.one_apply]

#print axioms moebius_divisor_sum_eq

theorem sum_Icc_div_eq_sum_antidiag {R : Type*} [AddCommMonoid R] (N : ℕ) (H : ℕ → ℕ → R) :
    ∑ n ∈ Finset.Icc 1 N, ∑ m ∈ Finset.Icc 1 (N / n), H n m =
      ∑ k ∈ Finset.Icc 1 N, ∑ p ∈ k.divisorsAntidiagonal, H p.1 p.2 := by
  rw [Finset.sum_sigma', Finset.sum_sigma']
  refine Finset.sum_bij' (fun p _ => ⟨p.1 * p.2, (p.1, p.2)⟩) (fun p _ => ⟨p.2.1, p.2.2⟩)
    ?_ ?_ ?_ ?_ ?_
  · rintro ⟨n, m⟩ h
    simp only [Finset.mem_sigma, Finset.mem_Icc, Nat.mem_divisorsAntidiagonal] at h ⊢
    obtain ⟨⟨hn1, hnN⟩, hm1, hmN⟩ := h
    have h0 : n * m ≠ 0 := Nat.mul_ne_zero (by omega) (by omega)
    have := (Nat.le_div_iff_mul_le (by omega)).mp hmN
    have hmn : n * m ≤ N := by linarith [mul_comm m n]
    exact ⟨⟨by omega, hmn⟩, by simp [h0]⟩
  · rintro ⟨k, a, b⟩ h
    simp only [Finset.mem_sigma, Finset.mem_Icc, Nat.mem_divisorsAntidiagonal] at h ⊢
    obtain ⟨⟨hk1, hkN⟩, hab, hk0⟩ := h
    subst hab
    have ha : a ≠ 0 := left_ne_zero_of_mul hk0
    have hb : b ≠ 0 := right_ne_zero_of_mul hk0
    refine ⟨⟨by omega, ?_⟩, by omega, ?_⟩
    · exact le_trans (Nat.le_mul_of_pos_right a (by omega)) hkN
    · rw [Nat.le_div_iff_mul_le (by omega)]; linarith [mul_comm a b]
  · rintro ⟨n, m⟩ _; rfl
  · rintro ⟨k, a, b⟩ h
    simp only [Finset.mem_sigma, Nat.mem_divisorsAntidiagonal] at h
    obtain ⟨_, hab, _⟩ := h
    subst hab; rfl
  · rintro ⟨n, m⟩ _; rfl

#print axioms sum_Icc_div_eq_sum_antidiag

/-- Möbius inversion. Let f and g be any functions on the whole numbers, with values in any
additive group (no condition on f at all). Then g adds up f over the divisors of every n,
g(n) = ∑_{d ∣ n} f(d), exactly when f comes back from g by the Möbius-weighted sum
f(n) = ∑_{d ∣ n} μ(d) g(n/d), for every n ≥ 1. Here μ(d) is +1 or −1 when d is a product of
an even or odd number of different primes, and 0 when a prime squared divides d. -/
theorem mobius_inversion {R : Type*} [AddCommGroup R] (f g : ℕ → R) :
    (∀ n > 0, g n = ∑ d ∈ n.divisors, f d) ↔
      ∀ n > 0, f n = ∑ d ∈ n.divisors, μ d • g (n / d) := by
  have := sum_eq_iff_sum_smul_moebius_eq (f := f) (g := g)
  simp only [Nat.sum_divisorsAntidiagonal (f := fun a b => μ a • g b)] at this
  constructor
  · intro h n hn; exact (this.mp (fun n hn => (h n hn).symm) n hn).symm
  · intro h n hn; exact (this.mpr (fun n hn => (h n hn).symm) n hn).symm

/-- The totient, three ways. Gauss's identity: the totients of the divisors of n add up to n.
Inverting it: φ(n) = ∑_{d ∣ n} μ(d) · n/d. Expanding the signs: φ(n) = n ∏_{p ∣ n} (1 − 1/p),
one bracket for each different prime p dividing n. -/
theorem totient_by_mobius_inversion (n : ℕ) :
    ∑ d ∈ n.divisors, Nat.totient d = n ∧
      (Nat.totient n : ℤ) = ∑ d ∈ n.divisors, μ d * ((n / d : ℕ) : ℤ) ∧
      (Nat.totient n : ℚ) = n * ∏ p ∈ n.primeFactors, (1 - 1 / (p : ℚ)) := by
  refine ⟨Nat.sum_totient n, ?_, ?_⟩
  · rcases Nat.eq_zero_or_pos n with rfl | hn
    · simp
    have := (sum_eq_iff_sum_mul_moebius_eq (R := ℤ) (f := fun d => (Nat.totient d : ℤ))
      (g := fun d => (d : ℤ))).mp (fun m _ => by exact_mod_cast Nat.sum_totient m) n hn
    simp only [Int.cast_id] at this
    rw [Nat.sum_divisorsAntidiagonal (f := fun a b => μ a * (b : ℤ))] at this
    simpa using this.symm
  · simpa only [one_div] using Nat.totient_eq_mul_prod_factors n

/-- The two more forms of inversion.
Product form: when every value of f and g is nonzero, g(n) = ∏_{d ∣ n} f(d) for every n ≥ 1
exactly when f(n) = ∏_{d ∣ n} g(n/d)^μ(d) for every n ≥ 1.
Running-total form: for functions F and G of a real bound x, G(x) = ∑_{n ≤ x} F(x/n) for every
x ≥ 1 exactly when F(x) = ∑_{n ≤ x} μ(n) G(x/n) for every x ≥ 1. -/
theorem mobius_inversion_product_form_and_running_total
    {K : Type*} [CommGroupWithZero K] (f g : ℕ → K)
    (hf : ∀ n > 0, f n ≠ 0) (hg : ∀ n > 0, g n ≠ 0)
    {R : Type*} [AddCommGroup R] (F G : ℝ → R) :
    ((∀ n > 0, g n = ∏ d ∈ n.divisors, f d) ↔
        ∀ n > 0, f n = ∏ d ∈ n.divisors, g (n / d) ^ μ d) ∧
      ((∀ x : ℝ, 1 ≤ x → G x = ∑ n ∈ Finset.Icc 1 ⌊x⌋₊, F (x / n)) ↔
        ∀ x : ℝ, 1 ≤ x → F x = ∑ n ∈ Finset.Icc 1 ⌊x⌋₊, μ n • G (x / n)) := by
  constructor
  · have := prod_eq_iff_prod_pow_moebius_eq_of_ne_zero (f := f) (g := g) hf hg
    simp only [Nat.prod_divisorsAntidiagonal (f := fun a b => g b ^ μ a)] at this
    constructor
    · intro h n hn; exact (this.mp (fun n hn => (h n hn).symm) n hn).symm
    · intro h n hn; exact (this.mpr (fun n hn => (h n hn).symm) n hn).symm
  -- facts about x / n
  have hge : ∀ x : ℝ, 1 ≤ x → ∀ n ∈ Finset.Icc 1 ⌊x⌋₊, 1 ≤ x / n := by
    intro x hx n hn
    rw [Finset.mem_Icc] at hn
    have hn0 : (0 : ℝ) < n := by exact_mod_cast hn.1
    rw [one_le_div hn0]
    exact (Nat.le_floor_iff (by linarith)).mp hn.2
  have hdiv : ∀ x : ℝ, ∀ a b : ℕ, x / a / b = x / ((a * b : ℕ) : ℝ) := by
    intro x a b; push_cast; rw [div_div]
  have hone : ∀ x : ℝ, 1 ≤ x → 1 ∈ Finset.Icc 1 ⌊x⌋₊ := by
    intro x hx; rw [Finset.mem_Icc]; exact ⟨le_rfl, Nat.le_floor (by simpa using hx)⟩
  constructor
  · intro h x hx
    have e : ∑ n ∈ Finset.Icc 1 ⌊x⌋₊, μ n • G (x / n) =
        ∑ n ∈ Finset.Icc 1 ⌊x⌋₊, ∑ m ∈ Finset.Icc 1 (⌊x⌋₊ / n), μ n • F (x / n / m) := by
      refine Finset.sum_congr rfl fun n hn => ?_
      rw [h (x / n) (hge x hx n hn), Nat.floor_div_natCast, Finset.smul_sum]
    rw [e, sum_Icc_div_eq_sum_antidiag, Finset.sum_eq_single_of_mem 1 (hone x hx)]
    · simp [Nat.divisorsAntidiagonal_one]
    · intro k _ hk1
      have e2 : ∑ p ∈ k.divisorsAntidiagonal, μ p.1 • F (x / p.1 / p.2) =
          ∑ p ∈ k.divisorsAntidiagonal, μ p.1 • F (x / k) := by
        refine Finset.sum_congr rfl fun p hp => ?_
        rw [Nat.mem_divisorsAntidiagonal] at hp
        rw [hdiv, hp.1]
      rw [e2, ← Finset.sum_smul,
        Nat.sum_divisorsAntidiagonal (f := fun a _ => μ a), moebius_divisor_sum_eq]
      simp [hk1]
  · intro h x hx
    have e : ∑ n ∈ Finset.Icc 1 ⌊x⌋₊, F (x / n) =
        ∑ n ∈ Finset.Icc 1 ⌊x⌋₊, ∑ m ∈ Finset.Icc 1 (⌊x⌋₊ / n), μ m • G (x / n / m) := by
      refine Finset.sum_congr rfl fun n hn => ?_
      rw [h (x / n) (hge x hx n hn), Nat.floor_div_natCast]
    rw [e, sum_Icc_div_eq_sum_antidiag, Finset.sum_eq_single_of_mem 1 (hone x hx)]
    · simp [Nat.divisorsAntidiagonal_one]
    · intro k _ hk1
      have e2 : ∑ p ∈ k.divisorsAntidiagonal, μ p.2 • G (x / p.1 / p.2) =
          ∑ p ∈ k.divisorsAntidiagonal, μ p.2 • G (x / k) := by
        refine Finset.sum_congr rfl fun p hp => ?_
        rw [Nat.mem_divisorsAntidiagonal] at hp
        rw [hdiv, hp.1]
      rw [e2, ← Finset.sum_smul,
        Nat.sum_divisorsAntidiagonal' (f := fun _ b => μ b), moebius_divisor_sum_eq]
      simp [hk1]

-- The 60 dial: the divisors of 60, and the 60 jumps sorted by loop length add back to 60.
example : Nat.divisors 60 = {1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 60} := by decide
example : ∑ d ∈ Nat.divisors 60, Nat.totient d = 60 := by decide

-- The 16 jumps that tour the whole dial, and φ(60) = 16.
example : (Finset.range 61).filter (fun k => Nat.Coprime k 60) =
    {1, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 49, 53, 59} := by decide
example : Nat.totient 60 = 16 := by decide

-- Möbius signs from the symbol table: μ(6) = 1, μ(30) = −1, μ(4) = 0.
example : μ 6 = 1 := by
  simp [moebius_apply_of_squarefree, Nat.squarefree_iff_nodup_primeFactorsList, cardFactors_apply,
    Nat.primeFactorsList_ofNat]
example : μ 30 = -1 := by
  simp [moebius_apply_of_squarefree, Nat.squarefree_iff_nodup_primeFactorsList, cardFactors_apply,
    Nat.primeFactorsList_ofNat]
example : μ 4 = 0 := moebius_eq_zero_of_not_squarefree (by decide)

-- Step 0: the signs over the divisors of 60 add to 0.
example : ∑ d ∈ Nat.divisors 60, μ d = 0 := by
  simp only [Nat.divisors_ofNat]
  simp [Finset.sum_insert, moebius_apply_of_squarefree, moebius_eq_zero_of_not_squarefree,
    Nat.squarefree_iff_nodup_primeFactorsList, cardFactors_apply, Nat.primeFactorsList_ofNat]

-- Inversion at 60: 60 − 30 − 20 − 12 + 10 + 6 + 4 − 2 = 16.
example : ∑ d ∈ Nat.divisors 60, μ d * ((60 / d : ℕ) : ℤ) = 16 := by
  simp only [Nat.divisors_ofNat]
  simp [Finset.sum_insert, moebius_apply_of_squarefree, moebius_eq_zero_of_not_squarefree,
    Nat.squarefree_iff_nodup_primeFactorsList, cardFactors_apply, Nat.primeFactorsList_ofNat]
example : (60 - 30 - 20 - 12 + 10 + 6 + 4 - 2 : ℤ) = 16 := by norm_num

-- Product of brackets at 60: 60 × 1/2 × 2/3 × 4/5 = 16.
example : (60 : ℚ) * (1 - 1 / 2) * (1 - 1 / 3) * (1 - 1 / 5) = 16 := by norm_num

-- The house number: 720720 = 2⁴ × 3² × 5 × 7 × 11 × 13, with 240 divisors, 64 of them squarefree,
-- and φ(720720) = 138,240 by the product of brackets.
example : 2 ^ 4 * 3 ^ 2 * 5 * 7 * 11 * 13 = 720720 := by norm_num
example : (4 + 1) * (2 + 1) * 2 * 2 * 2 * 2 = 240 := by norm_num
example : 2 ^ 6 = 64 := by norm_num
example : (720720 : ℚ) * (1 - 1 / 2) * (1 - 1 / 3) * (1 - 1 / 5) * (1 - 1 / 7) * (1 - 1 / 11)
    * (1 - 1 / 13) = 138240 := by norm_num

-- Product form: r(8) = 8 ÷ 4 = 2 and r(12) = 12 × 2 ÷ (6 × 4) = 1.
example : ∏ d ∈ Nat.divisors 8, ((8 / d : ℕ) : ℚ) ^ μ d = 2 := by
  simp only [Nat.divisors_ofNat]
  simp [Finset.prod_insert, moebius_apply_of_squarefree, moebius_eq_zero_of_not_squarefree,
    Nat.squarefree_iff_nodup_primeFactorsList, cardFactors_apply, Nat.primeFactorsList_ofNat]
  norm_num
example : ∏ d ∈ Nat.divisors 12, ((12 / d : ℕ) : ℚ) ^ μ d = 1 := by
  simp only [Nat.divisors_ofNat]
  simp [Finset.prod_insert, moebius_apply_of_squarefree, moebius_eq_zero_of_not_squarefree,
    Nat.squarefree_iff_nodup_primeFactorsList, cardFactors_apply, Nat.primeFactorsList_ofNat]
  norm_num

-- Running-total form at x = 60: T(60) = φ(1) + … + φ(60) = 1,102, and the inverted pair count
-- ∑_{n ≤ 60} μ(n) ⌊60/n⌋(⌊60/n⌋ + 1)/2 gives the same 1,102 with no totient; 60 × 61/2 = 1,830.
example : ∑ n ∈ Finset.Icc 1 60, Nat.totient n = 1102 := by decide
example : ∑ n ∈ Finset.Icc 1 60, μ n * ((60 / n * (60 / n + 1) / 2 : ℕ) : ℤ) = 1102 := by
  rw [show Finset.Icc 1 60 = Finset.Ico 1 61 from rfl, Finset.sum_Ico_eq_sum_range]
  simp [Finset.sum_range_succ, moebius_apply_of_squarefree, moebius_eq_zero_of_not_squarefree,
    Nat.squarefree_iff_nodup_primeFactorsList, cardFactors_apply, Nat.primeFactorsList_ofNat]
example : 60 * 61 / 2 = 1830 := by norm_num

-- Eight-bit strings that are no shorter block repeated: ∑_{d ∣ 8} μ(d) 2^(8/d) = 240, and 240/8 = 30.
example : ∑ d ∈ Nat.divisors 8, μ d * (2 : ℤ) ^ (8 / d) = 240 := by
  simp only [Nat.divisors_ofNat]
  simp [Finset.sum_insert, moebius_apply_of_squarefree, moebius_eq_zero_of_not_squarefree,
    Nat.squarefree_iff_nodup_primeFactorsList, cardFactors_apply, Nat.primeFactorsList_ofNat]
example : 240 / 8 = 30 := by norm_num

-- What breaks. Signs that count repeated primes, (−1) to the number of prime factors with
-- repeats: 24, not 16. Signs dropped: 144. The term d = 1 left out: −44.
example : ∑ d ∈ Nat.divisors 60, (-1 : ℤ) ^ cardFactors d * ((60 / d : ℕ) : ℤ) = 24 := by
  simp only [Nat.divisors_ofNat]
  simp [Finset.sum_insert, cardFactors_apply, Nat.primeFactorsList_ofNat]
example : 60 + 30 + 20 + 12 + 10 + 6 + 4 + 2 = 144 := by norm_num
example : (-30 - 20 - 12 + 10 + 6 + 4 - 2 : ℤ) = -44 := by norm_num

-- φ(360) × φ(2002) = 96 × 720 = 69,120, not φ(720720) = 138,240: 360 and 2002 share a 2.
example : Nat.totient 360 = 96 := by decide
example : (2002 : ℚ) * (1 - 1 / 2) * (1 - 1 / 7) * (1 - 1 / 11) * (1 - 1 / 13) = 720 := by norm_num
example : 96 * 720 = 69120 := by norm_num
example : Nat.gcd 360 2002 = 2 := by decide

#print axioms mobius_inversion
#print axioms totient_by_mobius_inversion
#print axioms mobius_inversion_product_form_and_running_total
