-- Gaussian integers: a whole number is a sum of two squares exactly when it is a Gaussian integer times its mirror image, exactly when every prime leaving remainder 3 on division by 4 divides it an even number of times; norms multiply; and the only units are 1, -1, i and -i.
import Mathlib.NumberTheory.SumTwoSquares
import Mathlib.NumberTheory.Zsqrtd.GaussianInt
import Mathlib.Data.Nat.Factorization.Basic

/-- Which whole numbers are a sum of two squares. For every whole number n, three things are the
same: n is a² + b² for some whole numbers a and b; n is a Gaussian integer z times its mirror
image (its conjugate, written `star z`); and every ordinary prime q leaving remainder 3 on
division by 4 appears in the prime factorisation of n to an even power. -/
theorem sum_of_two_squares_iff_splits_iff_remainder_three_primes_even (n : ℕ) :
    ((∃ a b : ℕ, n = a ^ 2 + b ^ 2) ↔ ∃ z : GaussianInt, z * star z = (n : GaussianInt)) ∧
      ((∃ a b : ℕ, n = a ^ 2 + b ^ 2) ↔
        ∀ q : ℕ, q.Prime → q % 4 = 3 → Even (n.factorization q)) := by
  have hA : (∃ a b : ℕ, n = a ^ 2 + b ^ 2) ↔ ∃ z : GaussianInt, z * star z = (n : GaussianInt) := by
    constructor
    · rintro ⟨a, b, h⟩
      refine ⟨⟨a, b⟩, ?_⟩
      rw [← Zsqrtd.norm_eq_mul_conj, Zsqrtd.norm_def, h]
      apply Zsqrtd.ext <;> simp [sq]
    · rintro ⟨z, hz⟩
      have h2 : Zsqrtd.norm z = (n : ℤ) := by
        have h1 : ((Zsqrtd.norm z : ℤ) : GaussianInt) = ((n : ℤ) : GaussianInt) := by
          rw [Zsqrtd.norm_eq_mul_conj, hz]; simp
        exact Int.cast_injective h1
      refine ⟨z.re.natAbs, z.im.natAbs, ?_⟩
      rw [Zsqrtd.norm_def] at h2
      zify
      rw [sq_abs, sq_abs, ← h2]
      simp; ring
  have hB : (∃ a b : ℕ, n = a ^ 2 + b ^ 2) ↔
      ∀ q : ℕ, q.Prime → q % 4 = 3 → Even (n.factorization q) := by
    rw [Nat.eq_sq_add_sq_iff]
    constructor
    · intro h q hq h4
      rw [Nat.factorization_def n hq]
      by_cases hmem : q ∈ n.primeFactors
      · exact h q hmem h4
      · rcases eq_or_ne n 0 with hn | hn
        · subst hn; simp
        · have hd : ¬ q ∣ n := fun hd => hmem (Nat.mem_primeFactors.mpr ⟨hq, hd, hn⟩)
          have : Fact q.Prime := ⟨hq⟩
          rw [padicValNat.eq_zero_of_not_dvd hd]; exact Even.zero
    · intro h q hq h4
      have := h q (Nat.prime_of_mem_primeFactors hq) h4
      rwa [Nat.factorization_def n (Nat.prime_of_mem_primeFactors hq)] at this
  exact ⟨hA, hB⟩

/-- Norms multiply. The norm of a + bi is a² + b², and the norm of a product of two Gaussian
integers is the product of their norms; in coordinates,
(ac - bd)² + (ad + bc)² = (a² + b²)(c² + d²). So a sum of two squares times a sum of two
squares is again a sum of two squares. -/
theorem norm_of_product_is_product_of_norms (z w : GaussianInt) :
    Zsqrtd.norm z = z.re ^ 2 + z.im ^ 2 ∧
      Zsqrtd.norm (z * w) = Zsqrtd.norm z * Zsqrtd.norm w := by
  refine ⟨?_, Zsqrtd.norm_mul z w⟩
  rw [Zsqrtd.norm_def]; ring

/-- The units. A Gaussian integer has a reciprocal on the grid exactly when it is 1, -1, i or -i,
the four points of norm 1. -/
theorem units_are_one_minus_one_i_minus_i (z : GaussianInt) :
    IsUnit z ↔ z = ⟨1, 0⟩ ∨ z = ⟨-1, 0⟩ ∨ z = ⟨0, 1⟩ ∨ z = ⟨0, -1⟩ := by
  rw [← Zsqrtd.norm_eq_one_iff' (by norm_num : (-1 : ℤ) ≤ 0)]
  obtain ⟨a, b⟩ := z
  simp only [Zsqrtd.norm_def, Zsqrtd.mk.injEq]
  constructor
  · intro h
    have ha : a * a ≤ 1 := by nlinarith [mul_self_nonneg b]
    have hb : b * b ≤ 1 := by nlinarith [mul_self_nonneg a]
    have ha1 : -1 ≤ a := by nlinarith
    have ha2 : a ≤ 1 := by nlinarith
    have hb1 : -1 ≤ b := by nlinarith
    have hb2 : b ≤ 1 := by nlinarith
    interval_cases a <;> interval_cases b <;> simp_all
  · rintro (⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩) <;> norm_num

-- The wire: 2 across, 1 up, squared length 5; and 13 = 9 + 4.
example : 2 ^ 2 + 1 ^ 2 = 5 ∧ 3 ^ 2 + 2 ^ 2 = 13 := by decide
-- 21 is not a sum of two squares: no two of 0, 1, 4, 9, 16 add to 21 (and 5² is already too big).
example : ∀ a ∈ Finset.range 5, ∀ b ∈ Finset.range 5, a ^ 2 + b ^ 2 ≠ 21 := by decide
example : 5 ^ 2 > 21 := by decide
-- No point has norm 3 or 7.
example : ∀ a ∈ Finset.range 3, ∀ b ∈ Finset.range 3, a ^ 2 + b ^ 2 ≠ 3 ∧ a ^ 2 + b ^ 2 ≠ 7 := by
  decide
-- i × i = -1.
example : (⟨0, 1⟩ * ⟨0, 1⟩ : GaussianInt) = ⟨-1, 0⟩ := by decide
-- (2 + i) + (3 + 2i) = 5 + 3i.
example : (⟨2, 1⟩ + ⟨3, 2⟩ : GaussianInt) = ⟨5, 3⟩ := by decide
-- 5 = (2 + i)(2 - i) and 13 = (3 + 2i)(3 - 2i).
example : (⟨2, 1⟩ * ⟨2, -1⟩ : GaussianInt) = ⟨5, 0⟩ ∧ (⟨3, 2⟩ * ⟨3, -2⟩ : GaussianInt) = ⟨13, 0⟩ :=
  by decide
-- Both factors of 5 have norm 5, so neither is a unit; the norm of 5 + 0i is 25, not 5.
example : Zsqrtd.norm (⟨2, 1⟩ : GaussianInt) = 5 ∧ Zsqrtd.norm (⟨2, -1⟩ : GaussianInt) = 5 ∧
    Zsqrtd.norm (⟨1, 2⟩ : GaussianInt) = 5 ∧ Zsqrtd.norm (⟨5, 0⟩ : GaussianInt) = 25 := by decide
-- (2 + i)(3 + 2i) = 4 + 7i, whose norm 65 = 5 × 13 = 4² + 7².
example : (⟨2, 1⟩ * ⟨3, 2⟩ : GaussianInt) = ⟨4, 7⟩ ∧ Zsqrtd.norm (⟨4, 7⟩ : GaussianInt) = 65 ∧
    (65 : ℤ) = 5 * 13 ∧ (4 : ℤ) ^ 2 + 7 ^ 2 = 65 := by decide
-- 5 over 2 + i: numerators (10, -5) over 5, quotient 2 - i, exact.
example : (⟨5, 0⟩ * ⟨2, -1⟩ : GaussianInt) = ⟨10, -5⟩ ∧ (⟨2, 1⟩ * ⟨2, -1⟩ : GaussianInt) = ⟨5, 0⟩ :=
  by decide
-- 2 + i over 2 - i: numerators (3, 4) over 5, off the grid, though both norms are 5.
example : (⟨2, 1⟩ * ⟨2, 1⟩ : GaussianInt) = ⟨3, 4⟩ ∧ ¬ (5 : ℤ) ∣ 3 ∧ ¬ (5 : ℤ) ∣ 4 := by decide
-- Fermat's rule on small primes: 5 and 13 leave remainder 1; 3 and 7 leave remainder 3.
example : 5 % 4 = 1 ∧ 13 % 4 = 1 ∧ 3 % 4 = 3 ∧ 7 % 4 = 3 := by decide
-- 2 = (1 + i)(1 - i).
example : (⟨1, 1⟩ * ⟨1, -1⟩ : GaussianInt) = ⟨2, 0⟩ := by decide
-- 21 = 3 × 7, each once; 45 = 3² × 5, and 45 = 3² + 6².
example : 21 = 3 * 7 ∧ 45 = 3 ^ 2 * 5 ∧ 45 = 3 ^ 2 + 6 ^ 2 := by decide
-- 65 = 5 × 13 in two ways: 1² + 8² and 4² + 7².
example : 65 = 1 ^ 2 + 8 ^ 2 ∧ 65 = 4 ^ 2 + 7 ^ 2 := by decide
-- The mistakes: reading i × i as +1 gives 3; 21 leaves remainder 1 yet fails.
example : 2 * 2 - 1 * 1 = 3 ∧ 21 % 4 = 1 := by decide
-- The norm grid, rows b = 3 down to 0, columns a = 0 to 4.
example : (List.range 5).map (fun a => a ^ 2 + 3 ^ 2) = [9, 10, 13, 18, 25] ∧
    (List.range 5).map (fun a => a ^ 2 + 2 ^ 2) = [4, 5, 8, 13, 20] ∧
    (List.range 5).map (fun a => a ^ 2 + 1 ^ 2) = [1, 2, 5, 10, 17] ∧
    (List.range 5).map (fun a => a ^ 2 + 0 ^ 2) = [0, 1, 4, 9, 16] := by decide

#print axioms sum_of_two_squares_iff_splits_iff_remainder_three_primes_even
#print axioms norm_of_product_is_product_of_norms
#print axioms units_are_one_minus_one_i_minus_i
