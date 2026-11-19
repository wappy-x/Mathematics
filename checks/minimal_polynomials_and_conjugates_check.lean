-- Minimal polynomials: an algebraic number has exactly one monic irreducible polynomial of least degree that it satisfies, that polynomial divides every other equation it satisfies, its conjugates satisfy all the same equations, and its degree is the dimension of the field the number generates.
import Mathlib.FieldTheory.Minpoly.Field
import Mathlib.FieldTheory.IntermediateField.Adjoin.Basic
import Mathlib.FieldTheory.Separable
import Mathlib.Algebra.Polynomial.Roots
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Complex.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Analysis.Complex.Polynomial.Basic
import Mathlib.RingTheory.Polynomial.Eisenstein.Criterion
import Mathlib.RingTheory.Polynomial.GaussLemma
import Mathlib.Tactic.ComputeDegree
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.IntervalCases
import Mathlib.RingTheory.Int.Basic

open Polynomial IntermediateField

/-- Eisenstein at 2 for a monic integer quartic, read over the rationals. -/
theorem quartic_eisenstein_two_irreducible (p : ℤ[X]) (hm : p.Monic) (hd : p.natDegree = 4)
    (hc : ∀ n < 4, (2 : ℤ) ∣ p.coeff n) (h0 : ¬ (4 : ℤ) ∣ p.coeff 0) :
    Irreducible (p.map (Int.castRingHom ℚ)) := by
  have hP : (Ideal.span {(2 : ℤ)}).IsPrime :=
    (Ideal.span_singleton_prime (by norm_num)).2 (Int.prime_iff_natAbs_prime.2 Nat.prime_two)
  refine (IsPrimitive.Int.irreducible_iff_irreducible_map_cast hm.isPrimitive).1 ?_
  refine irreducible_of_eisenstein_criterion hP ?_ ?_ ?_ ?_ hm.isPrimitive
  · rw [hm.leadingCoeff, Ideal.mem_span_singleton]; norm_num
  · intro n hn
    rw [Ideal.mem_span_singleton]
    apply hc
    have := (degree_eq_natDegree hm.ne_zero) ▸ hn
    rw [hd] at this
    exact_mod_cast this
  · rw [degree_eq_natDegree hm.ne_zero, hd]; norm_num
  · rw [Ideal.span_singleton_pow, Ideal.mem_span_singleton]; norm_num; exact h0
#print axioms quartic_eisenstein_two_irreducible

/-- The card's main claim. Let `K` be a field, `L` a bigger field, and `α` a number of `L`
that is algebraic over `K` (a root of some nonzero polynomial with coefficients in `K`).
Then its minimal polynomial `m_α` (Mathlib's `minpoly K α`)
* is monic (top coefficient 1) and irreducible over `K`;
* has least degree: every nonzero polynomial over `K` with `α` as a root has degree at least
  that of `m_α`;
* divides every other equation: a polynomial `f` over `K` has `α` as a root exactly when
  `m_α` divides `f`;
* is the only one: any monic irreducible polynomial over `K` with `α` as a root equals `m_α`;
* and its other roots, the conjugates `α'` of `α`, satisfy every equation over `K` that `α`
  satisfies, so no such equation can tell them apart. -/
theorem minimal_polynomial_divides_every_equation {K L : Type*} [Field K] [Field L]
    [Algebra K L] {α : L} (hα : IsIntegral K α) :
    (minpoly K α).Monic ∧ Irreducible (minpoly K α) ∧
      (∀ f : K[X], f ≠ 0 → aeval α f = 0 → (minpoly K α).natDegree ≤ f.natDegree) ∧
      (∀ f : K[X], aeval α f = 0 ↔ minpoly K α ∣ f) ∧
      (∀ p : K[X], p.Monic → Irreducible p → aeval α p = 0 → p = minpoly K α) ∧
      (∀ α' : L, aeval α' (minpoly K α) = 0 → ∀ f : K[X], aeval α f = 0 → aeval α' f = 0) := by
  refine ⟨minpoly.monic hα, minpoly.irreducible hα, ?_, ?_, ?_, ?_⟩
  · intro f hf h
    exact natDegree_le_natDegree (minpoly.degree_le_of_ne_zero K α hf h)
  · intro f
    exact (minpoly.dvd_iff).symm
  · intro p hp hi h
    exact minpoly.eq_of_irreducible_of_monic hi h hp
  · intro α' h' f hf
    obtain ⟨q, rfl⟩ := minpoly.dvd K α hf
    simp [map_mul, h']

/-- The card's formula, in a field inside the complex numbers. Let `K` be a subfield of `ℂ`
and `α` a complex number algebraic over `K`, with minimal polynomial `m_α` of degree `d`.
Then `d` is the degree `[K(α) : K]`, the dimension of the smallest field holding `K` and `α`;
the roots of `m_α` in `ℂ` (the conjugates of `α`) are all different; and `m_α` factors over
`ℂ` as `(x - α₁)(x - α₂)⋯(x - α_d)`, one bracket per conjugate. -/
theorem minpoly_degree_eq_finrank_and_distinct_conjugates (K : Subfield ℂ) {α : ℂ}
    (hα : IsIntegral K α) :
    (minpoly K α).natDegree = Module.finrank K K⟮α⟯ ∧
      ((minpoly K α).map (algebraMap K ℂ)).roots.Nodup ∧
      (minpoly K α).map (algebraMap K ℂ) =
        (((minpoly K α).map (algebraMap K ℂ)).roots.map (fun a => X - C a)).prod := by
  refine ⟨(IntermediateField.adjoin.finrank hα).symm, ?_, ?_⟩
  · exact nodup_roots ((minpoly.irreducible hα).separable.map)
  · exact (IsAlgClosed.splits _).eq_prod_roots_of_monic ((minpoly.monic hα).map _)

/-- The card's example. For the A0 number `α = 2^(1/4)`, the minimal polynomial over the
fractions is `x⁴ - 2`, and for `β = α + α²` it is `x⁴ - 4x² - 8x + 2`. -/
theorem minpoly_fourth_root_two_and_beta :
    minpoly ℚ ((2 : ℝ) ^ ((1 : ℝ) / 4)) = X ^ 4 - C 2 ∧
      minpoly ℚ ((2 : ℝ) ^ ((1 : ℝ) / 4) + ((2 : ℝ) ^ ((1 : ℝ) / 4)) ^ 2) =
        X ^ 4 - C 4 * X ^ 2 - C 8 * X + C 2 := by
  set α : ℝ := (2 : ℝ) ^ ((1 : ℝ) / 4) with hαdef
  have h4 : α ^ 4 = 2 := by
    rw [hαdef, ← Real.rpow_natCast, ← Real.rpow_mul (by norm_num)]
    norm_num
  constructor
  · have hmap : (X ^ 4 - C 2 : ℚ[X]) = (X ^ 4 - C 2 : ℤ[X]).map (Int.castRingHom ℚ) := by
      simp only [Polynomial.map_sub, Polynomial.map_pow,
        map_X, map_C]
      rfl
    have hmon : (X ^ 4 - C 2 : ℤ[X]).Monic := by monicity!
    have hdeg : (X ^ 4 - C 2 : ℤ[X]).natDegree = 4 := by compute_degree!
    symm
    apply minpoly.eq_of_irreducible_of_monic
    · rw [hmap]
      refine quartic_eisenstein_two_irreducible _ hmon hdeg ?_ ?_
      · intro n hn
        interval_cases n <;> simp [coeff_X_pow]
      · simp [coeff_X_pow]
    · simp [h4]
    · monicity!
  · have hmap : (X ^ 4 - C 4 * X ^ 2 - C 8 * X + C 2 : ℚ[X]) =
        (X ^ 4 - C 4 * X ^ 2 - C 8 * X + C 2 : ℤ[X]).map (Int.castRingHom ℚ) := by
      simp only [Polynomial.map_sub, Polynomial.map_add, Polynomial.map_mul, Polynomial.map_pow,
        map_X, map_C]
      rfl
    have hmon : (X ^ 4 - C 4 * X ^ 2 - C 8 * X + C 2 : ℤ[X]).Monic := by monicity!
    have hdeg : (X ^ 4 - C 4 * X ^ 2 - C 8 * X + C 2 : ℤ[X]).natDegree = 4 := by
      compute_degree!
    symm
    apply minpoly.eq_of_irreducible_of_monic
    · rw [hmap]
      refine quartic_eisenstein_two_irreducible _ hmon hdeg ?_ ?_
      · intro n hn
        interval_cases n <;> simp [coeff_X_pow, coeff_X]
      · simp [coeff_X_pow, coeff_X]
    · simp
      linear_combination (-1 + 4 * α + 6 * α ^ 2 + 4 * α ^ 3 + α ^ 4) * h4
    · monicity!

-- Step 0: x⁸ - 4 also kills α, and it is a multiple of x⁴ - 2: x⁸ - 4 = (x⁴ - 2)(x⁴ + 2).
example : (X ^ 8 - 4 : ℤ[X]) = (X ^ 4 - 2) * (X ^ 4 + 2) := by ring

-- Rational root test: x⁴ - 2 at 1, -1, 2, -2 is -1, -1, 14, 14, never 0.
example : ([1, -1, 2, -2] : List ℤ).map (fun x => x ^ 4 - 2) = [-1, -1, 14, 14] := by decide

-- Eisenstein at 2 for x⁴ - 2: 2 divides 0, 0, 0 and -2; 4 does not divide -2.
example : (2 : ℤ) ∣ -2 ∧ ¬ (4 : ℤ) ∣ -2 := by decide

-- Worked numbers: the powers of β = α + α² in the basis 1, α, α², α³, using α⁴ = 2,
-- written as polynomial identities in α: β² = [2, 0, 1, 2], β³ = [6, 6, 2, 1], β⁴ = [6, 8, 12, 8].
example : ((X + X ^ 2) ^ 2 : ℤ[X]) = (2 + X ^ 2 + 2 * X ^ 3) + (X ^ 4 - 2) * 1 := by ring
example : ((X + X ^ 2) ^ 3 : ℤ[X]) =
    (6 + 6 * X + 2 * X ^ 2 + X ^ 3) + (X ^ 4 - 2) * (3 + 3 * X + X ^ 2) := by ring
example : ((X + X ^ 2) ^ 4 : ℤ[X]) =
    (6 + 8 * X + 12 * X ^ 2 + 8 * X ^ 3) + (X ^ 4 - 2) * (3 + 4 * X + 6 * X ^ 2 + 4 * X ^ 3 + X ^ 4) := by
  ring

-- The elimination: c₀ = -2, c₁ = 8, c₂ = 4, c₃ = 0 solve the four column equations,
-- so β⁴ = -2 + 8β + 4β².
example : (-2 : ℤ) + 2 * 4 + 6 * 0 = 6 ∧ (8 : ℤ) + 6 * 0 = 8 ∧ (8 : ℤ) + 4 + 2 * 0 = 12 ∧
    (2 : ℤ) * 4 + 0 = 8 := by norm_num

-- So β⁴ - 4β² - 8β + 2 = 0: substituting α + α² into it leaves a multiple of α⁴ - 2.
example : ((X + X ^ 2) ^ 4 - 4 * (X + X ^ 2) ^ 2 - 8 * (X + X ^ 2) + 2 : ℤ[X]) =
    (X ^ 4 - 2) * (-1 + 4 * X + 6 * X ^ 2 + 4 * X ^ 3 + X ^ 4) := by ring

-- Eisenstein at 2 for x⁴ - 4x² - 8x + 2: 2 divides -4, -8 and 2; 4 does not divide 2.
example : (2 : ℤ) ∣ -4 ∧ (2 : ℤ) ∣ -8 ∧ (2 : ℤ) ∣ 2 ∧ ¬ (4 : ℤ) ∣ 2 := by decide

-- What breaks: x⁴ + 4 has no rational root (values 5, 5, 20, 20, 260, 260 at ±1, ±2, ±4),
-- yet it factors as (x² + 2x + 2)(x² - 2x + 2).
example : ([1, -1, 2, -2, 4, -4] : List ℤ).map (fun x => x ^ 4 + 4) = [5, 5, 20, 20, 260, 260] := by
  decide
example : (X ^ 4 + 4 : ℤ[X]) = (X ^ 2 + 2 * X + 2) * (X ^ 2 - 2 * X + 2) := by ring

-- The π search covers 11⁵ - 1 = 161,050 nonzero polynomials of degree at most 4
-- with coefficients from -5 to 5.
example : 11 ^ 5 - 1 = 161050 := by norm_num

#print axioms minimal_polynomial_divides_every_equation
#print axioms minpoly_degree_eq_finrank_and_distinct_conjugates
#print axioms minpoly_fourth_root_two_and_beta
