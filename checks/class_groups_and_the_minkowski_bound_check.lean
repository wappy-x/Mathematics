-- Class groups: every ideal class of a number field holds an ideal of norm at most Minkowski's bound, so the class group is finite; the class number is 1 exactly when factorisation is unique; and in Z[√-5] the number 6 factors two ways because no number has norm 2.
import Mathlib.NumberTheory.NumberField.ClassNumber
import Mathlib.NumberTheory.Zsqrtd.Basic
import Mathlib.RingTheory.DedekindDomain.PID

open NumberField Module Real
open scoped nonZeroDivisors

/-- No number of `ℤ[√-5]` has norm 2 or norm 3. -/
theorem zsqrt_neg_five_norm_ne_two_three (z : ℤ√(-5)) : z.norm ≠ 2 ∧ z.norm ≠ 3 := by
  rw [Zsqrtd.norm_def]
  have h1 : 0 ≤ z.re * z.re := mul_self_nonneg _
  have h2 : 0 ≤ z.im * z.im := mul_self_nonneg _
  constructor
  · intro h
    have hre : z.re ≤ 2 := by nlinarith
    have hre' : -2 ≤ z.re := by nlinarith
    have him : z.im ≤ 1 := by nlinarith
    have him' : -1 ≤ z.im := by nlinarith
    revert h
    generalize z.re = a at *
    generalize z.im = b at *
    interval_cases a <;> interval_cases b <;> norm_num
  · intro h
    have hre : z.re ≤ 2 := by nlinarith
    have hre' : -2 ≤ z.re := by nlinarith
    have him : z.im ≤ 1 := by nlinarith
    have him' : -1 ≤ z.im := by nlinarith
    revert h
    generalize z.re = a at *
    generalize z.im = b at *
    interval_cases a <;> interval_cases b <;> norm_num

/-- In `ℤ[√-5]`, a number of norm 4, 6 or 9 is irreducible, since a proper factor would
have norm 2 or 3. -/
theorem zsqrt_neg_five_irreducible_of_norm (x : ℤ√(-5))
    (hx : x.norm = 4 ∨ x.norm = 6 ∨ x.norm = 9) : Irreducible x := by
  rw [irreducible_iff]
  constructor
  · rw [← Zsqrtd.norm_eq_one_iff' (by norm_num)]
    omega
  · intro a b h
    have hn := congrArg Zsqrtd.norm h
    rw [Zsqrtd.norm_mul] at hn
    have ha := Zsqrtd.norm_nonneg (by norm_num) a
    have hb := Zsqrtd.norm_nonneg (by norm_num) b
    have ha23 := zsqrt_neg_five_norm_ne_two_three a
    have hb23 := zsqrt_neg_five_norm_ne_two_three b
    rw [← Zsqrtd.norm_eq_one_iff' (by norm_num), ← Zsqrtd.norm_eq_one_iff' (by norm_num)]
    generalize a.norm = p at *
    generalize b.norm = q at *
    have hp1 : 1 ≤ p := by
      rcases hx with h' | h' | h' <;> rw [h'] at hn <;>
        (by_contra hc; have : p = 0 := by omega
         subst this; simp at hn)
    have hq1 : 1 ≤ q := by
      rcases hx with h' | h' | h' <;> rw [h'] at hn <;>
        (by_contra hc; have : q = 0 := by omega
         subst this; simp at hn)
    have hp9 : p ≤ 9 := by rcases hx with h' | h' | h' <;> rw [h'] at hn <;> nlinarith
    interval_cases p <;> omega

#print axioms zsqrt_neg_five_norm_ne_two_three
#print axioms zsqrt_neg_five_irreducible_of_norm

/-- Minkowski's bound: for a number field `K` of degree `n` with `r₂` pairs of complex
embeddings and discriminant `d_K`, the class group of its ring of integers is finite, and every
class contains a nonzero ideal `𝔟` with `N(𝔟) ≤ M_K = (n!/n^n) (4/π)^{r₂} √|d_K|`. -/
theorem every_class_contains_ideal_of_norm_le_minkowski_bound
    (K : Type*) [Field K] [NumberField K] :
    Finite (ClassGroup (𝓞 K)) ∧
      ∀ C : ClassGroup (𝓞 K), ∃ I : (Ideal (𝓞 K))⁰, ClassGroup.mk0 I = C ∧
        (Ideal.absNorm (I : Ideal (𝓞 K)) : ℝ) ≤
          ((finrank ℚ K).factorial / (finrank ℚ K : ℝ) ^ (finrank ℚ K)) *
            (4 / π) ^ InfinitePlace.nrComplexPlaces K * √|(discr K : ℝ)| := by
  refine ⟨inferInstance, fun C => ?_⟩
  obtain ⟨I, hI, hle⟩ := exists_ideal_in_class_of_norm_le C
  refine ⟨I, hI, le_of_le_of_eq hle ?_⟩
  ring

/-- The class number of a number field is 1 exactly when every number of its ring of
integers factors uniquely into irreducibles (up to units and order). -/
theorem classNumber_eq_one_iff_unique_factorisation
    (K : Type*) [Field K] [NumberField K] :
    classNumber K = 1 ↔ UniqueFactorizationMonoid (𝓞 K) := by
  rw [classNumber_eq_one_iff]
  exact ⟨fun _ => inferInstance,
    fun _ => IsPrincipalIdealRing.of_isDedekindDomain_of_uniqueFactorizationMonoid _⟩

/-- The house example in `ℤ[√-5]`: no number `a + b√-5` has norm `a² + 5b² = 2`, and
`6 = 2 × 3 = (1 + √-5)(1 - √-5)` with all four factors irreducible and `2` associated to
neither `1 + √-5` nor `1 - √-5`, so 6 has two different factorisations into irreducibles. -/
theorem six_factors_two_ways_in_zsqrt_neg_five :
    (∀ z : ℤ√(-5), z.norm ≠ 2) ∧
    (2 * 3 : ℤ√(-5)) = (1 + Zsqrtd.sqrtd) * (1 - Zsqrtd.sqrtd) ∧
    Irreducible (2 : ℤ√(-5)) ∧ Irreducible (3 : ℤ√(-5)) ∧
    Irreducible (1 + Zsqrtd.sqrtd : ℤ√(-5)) ∧ Irreducible (1 - Zsqrtd.sqrtd : ℤ√(-5)) ∧
    ¬ Associated (2 : ℤ√(-5)) (1 + Zsqrtd.sqrtd) ∧
    ¬ Associated (2 : ℤ√(-5)) (1 - Zsqrtd.sqrtd) := by
  have h2 : (2 : ℤ√(-5)).norm = 4 := by decide
  have h3 : (3 : ℤ√(-5)).norm = 9 := by decide
  have hp : (1 + Zsqrtd.sqrtd : ℤ√(-5)).norm = 6 := by decide
  have hm : (1 - Zsqrtd.sqrtd : ℤ√(-5)).norm = 6 := by decide
  refine ⟨fun z => (zsqrt_neg_five_norm_ne_two_three z).1, by decide,
    zsqrt_neg_five_irreducible_of_norm _ (by omega),
    zsqrt_neg_five_irreducible_of_norm _ (by omega),
    zsqrt_neg_five_irreducible_of_norm _ (by omega),
    zsqrt_neg_five_irreducible_of_norm _ (by omega), ?_, ?_⟩
  · intro h
    have := Zsqrtd.norm_eq_of_associated (by norm_num) h
    omega
  · intro h
    have := Zsqrtd.norm_eq_of_associated (by norm_num) h
    omega

-- The card's worked numbers.
-- The discriminant of Q(√-5) is 4 × (-5) = -20.
example : (4 : ℤ) * (-5) = -20 := by norm_num
-- Minkowski's bound for Q(√-5): (2!/2²)(4/π)√20 = (2/π)√20 is below 3, so only norms 1 and 2 matter.
example : (2 / π) * √20 < 3 := by
  have hpi := Real.pi_gt_three
  have hs : √20 < 9 / 2 := by
    rw [Real.sqrt_lt' (by norm_num)]; norm_num
  rw [div_mul_eq_mul_div, div_lt_iff₀ (by positivity)]
  nlinarith [Real.sqrt_nonneg 20]
-- No a² + 5b² equals 2 (|a| ≤ 2, |b| ≤ 1 covers every candidate).
example : ∀ a b : Fin 3, (a : ℕ) ^ 2 + 5 * (b : ℕ) ^ 2 ≠ 2 := by decide
-- N(1 + √-5) = 6, and (1 + √-5)(1 - √-5) = 6 in Z[√-5].
example : (1 + Zsqrtd.sqrtd : ℤ√(-5)).norm = 6 := by decide
example : ((⟨1, 1⟩ : ℤ√(-5)) * ⟨1, -1⟩) = ⟨6, 0⟩ := by decide
-- 21 = 3 × 7 = (1 + 2√-5)(1 - 2√-5) = (4 + √-5)(4 - √-5).
example : ((⟨1, 2⟩ : ℤ√(-5)) * ⟨1, -2⟩) = ⟨21, 0⟩ := by decide
example : ((⟨4, 1⟩ : ℤ√(-5)) * ⟨4, -1⟩) = ⟨21, 0⟩ := by decide
-- The two reduced forms of discriminant -20: x² + 5y² and 2x² + 2xy + 3y².
example : (0 : ℤ) ^ 2 - 4 * 1 * 5 = -20 ∧ (2 : ℤ) ^ 2 - 4 * 2 * 3 = -20 := by norm_num
-- The class number formula sum: 1 + 3 + 7 + 9 - 11 - 13 - 17 - 19 = -40, and h = 40/20 = 2.
example : (1 + 3 + 7 + 9 - 11 - 13 - 17 - 19 : ℤ) = -40 ∧ (40 : ℤ) / 20 = 2 := by norm_num
-- Primes of each form: 29 = 3² + 5·2², 41 = 6² + 5·1², 7 = 2 + 2 + 3, 23 = 2·2² + 2·2·(-3) + 3·(-3)².
example : (29 : ℤ) = 3 ^ 2 + 5 * 2 ^ 2 ∧ (41 : ℤ) = 6 ^ 2 + 5 * 1 ^ 2 ∧
    (7 : ℤ) = 2 * 1 ^ 2 + 2 * 1 * 1 + 3 * 1 ^ 2 ∧
    (23 : ℤ) = 2 * 2 ^ 2 + 2 * 2 * (-3) + 3 * (-3) ^ 2 := by norm_num

#print axioms every_class_contains_ideal_of_norm_le_minkowski_bound
#print axioms classNumber_eq_one_iff_unique_factorisation
#print axioms six_factors_two_ways_in_zsqrt_neg_five
