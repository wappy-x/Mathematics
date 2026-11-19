-- Multiplicative functions: a multiplicative function is fixed by its values on prime powers, adding Euler's totient over the divisors of n gives n back, and the Dirichlet inverse of a multiplicative function is again multiplicative.
import Mathlib.NumberTheory.ArithmeticFunction.Misc
import Mathlib.NumberTheory.ArithmeticFunction.Moebius
import Mathlib.Data.Nat.Totient
import Mathlib.Tactic.NormNum.Prime

open Finset ArithmeticFunction
open scoped ArithmeticFunction.Moebius

/-- Helper: a multiplicative function at 720720 is the product of its values on the six
prime-power blocks 16, 9, 5, 7, 11, 13. -/
theorem mult_720720 {R : Type*} [CommMonoidWithZero R] (f : ArithmeticFunction R)
    (hf : f.IsMultiplicative) : f 720720 = f 16 * f 9 * f 5 * f 7 * f 11 * f 13 := by
  rw [show (720720 : ℕ) = 16 * (9 * (5 * (7 * (11 * 13)))) by norm_num,
    hf.map_mul_of_coprime (by decide), hf.map_mul_of_coprime (by decide),
    hf.map_mul_of_coprime (by decide), hf.map_mul_of_coprime (by decide),
    hf.map_mul_of_coprime (by decide)]
  simp only [mul_assoc]

/-- Helper: the totient of 720720 is the product of the totients of its six prime-power blocks. -/
theorem totient_720720 : Nat.totient 720720 =
    Nat.totient 16 * Nat.totient 9 * Nat.totient 5 * Nat.totient 7 * Nat.totient 11 *
      Nat.totient 13 := by
  rw [show (720720 : ℕ) = 16 * (9 * (5 * (7 * (11 * 13)))) by norm_num,
    Nat.totient_mul (by decide), Nat.totient_mul (by decide),
    Nat.totient_mul (by decide), Nat.totient_mul (by decide),
    Nat.totient_mul (by decide)]
  simp only [mul_assoc]

/-- A multiplicative function is fixed by its prime powers. Let f be an arithmetic function with
f(1) = 1 and f(mn) = f(m) f(n) whenever m and n are coprime. Then for every whole number n ≥ 1,
f(n) is the product of f(p^a) over the prime-power blocks p^a of n, where a is the exponent of
the prime p in n (so p^a exactly divides n). -/
theorem multiplicative_eq_prod_over_prime_power_blocks {R : Type*} [CommRing R]
    (f : ArithmeticFunction R) (hf : f.IsMultiplicative) {n : ℕ} (hn : 0 < n) :
    f n = ∏ p ∈ n.primeFactors, f (p ^ n.factorization p) := by
  exact IsMultiplicative.multiplicative_factorization f hf hn.ne'

/-- Adding Euler's totient over the divisors gives n back, φ * 1 = id: for every whole number
n ≥ 1, the sum of φ(d) over all divisors d of n equals n. -/
theorem sum_totient_over_divisors_eq_self (n : ℕ) (hn : 0 < n) :
    ∑ d ∈ n.divisors, Nat.totient d = n := by
  exact Nat.sum_totient n

/-- The inverse of a multiplicative function is multiplicative. If f is multiplicative and g is
its Dirichlet inverse, meaning f * g = ε (Mathlib's `1` for arithmetic functions: 1 at 1 and 0
elsewhere), then g is multiplicative too, so it can be found one prime at a time. -/
theorem dirichlet_inverse_of_multiplicative_is_multiplicative {R : Type*} [CommRing R]
    (f g : ArithmeticFunction R) (hf : f.IsMultiplicative) (hfg : f * g = 1) :
    g.IsMultiplicative := by
  classical
  have hg1 : g 1 = 1 := by
    have h1 := congrArg (fun F : ArithmeticFunction R => F 1) hfg
    simpa [mul_apply, hf.map_one] using h1
  obtain ⟨h, hdef⟩ : ∃ h : ArithmeticFunction R,
      ∀ n, n ≠ 0 → h n = n.factorization.prod fun p k => g (p ^ k) :=
    ⟨⟨fun n => if n = 0 then 0 else n.factorization.prod fun p k => g (p ^ k), by simp⟩,
      fun n hn => ite_eq_right_of_eq_false _ _ (eq_false hn)⟩
  have hh : h.IsMultiplicative := by
    rw [IsMultiplicative.iff_ne_zero]
    refine ⟨by rw [hdef 1 one_ne_zero]; simp, ?_⟩
    intro m n hm hn hmn
    rw [hdef _ (mul_ne_zero hm hn), hdef m hm, hdef n hn, Nat.factorization_mul_of_coprime hmn,
      Finsupp.prod_add_index_of_disjoint]
    simpa [Nat.support_factorization] using hmn.disjoint_primeFactors
  have hpow : ∀ p j : ℕ, p.Prime → h (p ^ j) = g (p ^ j) := by
    intro p j hp
    rw [hdef _ (pow_ne_zero _ hp.ne_zero), hp.factorization_pow,
      Finsupp.prod_single_index (by simpa using hg1)]
  have hfh : f * h = 1 := by
    rw [IsMultiplicative.eq_iff_eq_on_prime_powers _ (hf.mul hh) _ isMultiplicative_one]
    intro p i hp
    rw [← hfg, mul_apply, mul_apply]
    refine Finset.sum_congr rfl fun x hx => ?_
    rw [Nat.mem_divisorsAntidiagonal] at hx
    obtain ⟨j, -, hj⟩ := (Nat.dvd_prime_pow hp).1 (Dvd.intro_left _ hx.1)
    rw [hj, hpow p j hp]
  have hgh : g = h := by
    calc g = g * (f * h) := by rw [hfh, mul_one]
      _ = (f * g) * h := by rw [← mul_assoc, mul_comm g f]
      _ = h := by rw [hfg, one_mul]
  rw [hgh]
  exact hh

-- 720720 cut into prime-power blocks: 2^4 × 3^2 × 5 × 7 × 11 × 13 = 16 × 9 × 5 × 7 × 11 × 13.
example : (720720 : ℕ) = 2 ^ 4 * 3 ^ 2 * 5 * 7 * 11 * 13 ∧ (720720 : ℕ) = 16 * 9 * 5 * 7 * 11 * 13 := by
  norm_num
-- The blocks share no prime, and 720720 = 16 × 45045 is a coprime split.
example : Nat.Coprime 16 45045 ∧ 16 * 45045 = 720720 := by decide
-- The block 16: τ = 5, σ = 31, σ₂ = 341, φ = 8.
example : #(Nat.divisors 16) = 5 ∧ ∑ d ∈ Nat.divisors 16, d = 31 ∧
    ∑ d ∈ Nat.divisors 16, d ^ 2 = 341 ∧ Nat.totient 16 = 8 := by decide
-- The block 9: τ = 3, σ = 13, σ₂ = 91, φ = 6.
example : #(Nat.divisors 9) = 3 ∧ ∑ d ∈ Nat.divisors 9, d = 13 ∧
    ∑ d ∈ Nat.divisors 9, d ^ 2 = 91 ∧ Nat.totient 9 = 6 := by decide
-- The four prime blocks 5, 7, 11, 13: τ = 2; σ = 6, 8, 12, 14; σ₂ = 26, 50, 122, 170; φ = 4, 6, 10, 12.
example : #(Nat.divisors 5) = 2 ∧ ∑ d ∈ Nat.divisors 5, d = 6 ∧
    ∑ d ∈ Nat.divisors 5, d ^ 2 = 26 ∧ Nat.totient 5 = 4 := by decide
example : #(Nat.divisors 7) = 2 ∧ ∑ d ∈ Nat.divisors 7, d = 8 ∧
    ∑ d ∈ Nat.divisors 7, d ^ 2 = 50 ∧ Nat.totient 7 = 6 := by decide
example : #(Nat.divisors 11) = 2 ∧ ∑ d ∈ Nat.divisors 11, d = 12 ∧
    ∑ d ∈ Nat.divisors 11, d ^ 2 = 122 ∧ Nat.totient 11 = 10 := by decide
example : #(Nat.divisors 13) = 2 ∧ ∑ d ∈ Nat.divisors 13, d = 14 ∧
    ∑ d ∈ Nat.divisors 13, d ^ 2 = 170 ∧ Nat.totient 13 = 12 := by decide
-- Multiply down each column: 240, 3,249,792, 836,657,822,000 and 138,240.
example : 5 * 3 * 2 * 2 * 2 * 2 = 240 ∧ 31 * 13 * 6 * 8 * 12 * 14 = 3249792 ∧
    341 * 91 * 26 * 50 * 122 * 170 = 836657822000 ∧ 8 * 6 * 4 * 6 * 10 * 12 = 138240 := by
  norm_num
-- The values at 720720 itself: τ = 240, σ = 3,249,792, σ₂ = 836,657,822,000, φ = 138,240.
example : #(Nat.divisors 720720) = 240 := by
  rw [← sigma_zero_apply, mult_720720 _ isMultiplicative_sigma]
  simp only [sigma_zero_apply]
  decide
example : ∑ d ∈ Nat.divisors 720720, d = 3249792 := by
  rw [← sigma_one_apply, mult_720720 _ isMultiplicative_sigma]
  simp only [sigma_one_apply]
  decide
example : ∑ d ∈ Nat.divisors 720720, d ^ 2 = 836657822000 := by
  rw [← sigma_apply, mult_720720 _ isMultiplicative_sigma]
  simp only [sigma_apply]
  decide
example : Nat.totient 720720 = 138240 := by
  rw [totient_720720]
  decide
-- 720720 = 16 × 45045: 240 divisors = 5 × 48.
example : #(Nat.divisors 45045) = 48 := by decide +kernel
-- (φ * 1)(16) = 1 + 1 + 2 + 4 + 8 = 16, and the six blocks multiply back to 720720.
example : ∑ d ∈ Nat.divisors 16, Nat.totient d = 16 ∧ 1 + 1 + 2 + 4 + 8 = 16 := by decide
example : 16 * 9 * 5 * 7 * 11 * 13 = 720720 := by norm_num
-- φ⁻¹(720720) = (1 − 2)(1 − 3)(1 − 5)(1 − 7)(1 − 11)(1 − 13) = 5760.
example : ((1 - 2) * (1 - 3) * (1 - 5) * (1 - 7) * (1 - 11) * (1 - 13) : ℤ) = 5760 ∧
    ((-1) * (-2) * (-4) * (-6) * (-10) * (-12) : ℤ) = 5760 := by norm_num
-- id⁻¹(30) = μ(30) × 30 = −30.
example : μ 30 * 30 = -30 := by decide +kernel
-- τ⁻¹ = μ * μ takes the values 1, −2, 1, 0 at 1, 2, 4, 8; μτ at 4 gives 0, not 1.
example : ((μ : ArithmeticFunction ℤ) * μ) 1 = 1 ∧ ((μ : ArithmeticFunction ℤ) * μ) 2 = -2 ∧
    ((μ : ArithmeticFunction ℤ) * μ) 4 = 1 ∧ ((μ : ArithmeticFunction ℤ) * μ) 8 = 0 := by
  decide +kernel
example : μ 4 * (#(Nat.divisors 4) : ℤ) = 0 := by decide +kernel
-- What breaks: 360 × 2002 = 720720 but gcd(360, 2002) = 2, and τ(360) × τ(2002) = 24 × 16 = 384.
example : 360 * 2002 = 720720 ∧ Nat.gcd 360 2002 = 2 := by decide
example : #(Nat.divisors 360) = 24 ∧ #(Nat.divisors 2002) = 16 ∧ 24 * 16 = 384 := by decide +kernel
-- The same split for φ: φ(360) × φ(2002) = 96 × 720 = 69,120, not 138,240.
example : Nat.totient 360 = 96 ∧ Nat.totient 2002 = 720 ∧ 96 * 720 = 69120 := by decide +kernel
-- φ(p^a) taken as p^a − 1: 15 × 8 × 4 × 6 × 10 × 12 = 345,600.
example : 15 * 8 * 4 * 6 * 10 * 12 = 345600 := by norm_num

#print axioms mult_720720
#print axioms totient_720720
#print axioms multiplicative_eq_prod_over_prime_power_blocks
#print axioms sum_totient_over_divisors_eq_self
#print axioms dirichlet_inverse_of_multiplicative_is_multiplicative
