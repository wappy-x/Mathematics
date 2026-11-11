-- Polynomials behave like integers: over a field, polynomials divide with exactly one quotient and a remainder of lower degree, Euclid's swap keeps every common divisor and leads to exactly one monic greatest common divisor, and every polynomial of degree 1 or more is a constant times monic irreducibles that are the same every time up to order.
import Mathlib.Algebra.Polynomial.FieldDivision
import Mathlib.RingTheory.PrincipalIdealDomain
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.LinearCombination
import Mathlib.RingTheory.Polynomial.Content

open Polynomial

/-- Division with remainder over a field. Take coefficients from a field F and a divisor g that
is not the zero polynomial. Then every polynomial f splits as f = q g + r, a quotient times the
divisor plus a remainder that is either nothing at all or of lower degree than the divisor,
and there is exactly one such pair q, r. -/
theorem polynomials_over_a_field_divide_with_remainder {F : Type*} [Field F]
    (f g : F[X]) (hg : g ≠ 0) :
    ∃! qr : F[X] × F[X], f = qr.1 * g + qr.2 ∧ (qr.2 = 0 ∨ qr.2.degree < g.degree) := by
  classical
  refine ⟨(f / g, f % g), ⟨?_, ?_⟩, ?_⟩
  · simp only
    rw [mul_comm]
    exact (EuclideanDomain.div_add_mod f g).symm
  · by_cases h : f % g = 0
    · exact Or.inl h
    · exact Or.inr (Polynomial.degree_mod_lt f hg)
  · rintro ⟨q, r⟩ ⟨h1, h2⟩
    simp only at h1 h2
    have hlt : (r - f % g).degree < g.degree := by
      have hr : r.degree < g.degree := by
        rcases h2 with h | h
        · rw [h]; simpa using bot_lt_iff_ne_bot.mpr (by simpa using hg)
        · exact h
      exact lt_of_le_of_lt (Polynomial.degree_sub_le _ _) (max_lt hr (Polynomial.degree_mod_lt f hg))
    have heq : (q - f / g) * g = f % g - r := by
      have h3 : f = f / g * g + f % g := (EuclideanDomain.div_add_mod' f g).symm
      linear_combination h3 - h1
    have hr : r = f % g := by
      by_contra hne
      have hne' : (q - f / g) * g ≠ 0 := by
        rw [heq]; exact sub_ne_zero.mpr (Ne.symm hne)
      have hq0 : q - f / g ≠ 0 := left_ne_zero_of_mul hne'
      have : (g).degree ≤ ((q - f / g) * g).degree := by
        rw [Polynomial.degree_mul]
        have : (0 : WithBot ℕ) ≤ (q - f / g).degree := by
          exact Polynomial.zero_le_degree_iff.mpr hq0
        calc g.degree = 0 + g.degree := by simp
          _ ≤ _ := add_le_add_left this _
      have hc : (f % g - r).degree = (r - f % g).degree := by
        rw [← Polynomial.degree_neg, neg_sub]
      rw [heq, hc] at this
      exact absurd (lt_of_le_of_lt this hlt) (lt_irrefl _)
    subst hr
    have : (q - f / g) * g = 0 := by rw [heq]; ring
    have hq : q = f / g := by
      rcases mul_eq_zero.mp this with h | h
      · exact sub_eq_zero.mp h
      · exact absurd h hg
    rw [hq]

/-- Euclid's algorithm works on polynomials. Over a field, if f = q g + r, then swapping the pair
(f, g) for (g, r) keeps exactly the same common divisors. And when f and g are not both zero,
they have exactly one monic greatest common divisor h: a polynomial with top coefficient 1 that
divides both, and that every common divisor of f and g divides. -/
theorem euclid_swap_keeps_common_divisors_and_monic_gcd_is_unique {F : Type*} [Field F]
    (f g : F[X]) :
    (∀ q r : F[X], f = q * g + r → ∀ d : F[X], (d ∣ f ∧ d ∣ g ↔ d ∣ g ∧ d ∣ r)) ∧
      (f ≠ 0 ∨ g ≠ 0 →
        ∃! h : F[X], h.Monic ∧ h ∣ f ∧ h ∣ g ∧ ∀ d : F[X], d ∣ f → d ∣ g → d ∣ h) := by
  classical
  refine ⟨?_, ?_⟩
  · intro q r hqr d
    subst hqr
    constructor
    · rintro ⟨h1, h2⟩
      refine ⟨h2, ?_⟩
      exact (dvd_add_right (dvd_mul_of_dvd_right h2 q)).mp h1
    · rintro ⟨h1, h2⟩
      exact ⟨dvd_add (dvd_mul_of_dvd_right h1 q) h2, h1⟩
  · intro hne
    have hgcd : gcd f g ≠ 0 := by
      intro h0
      rcases hne with h | h
      · exact h (zero_dvd_iff.mp (h0 ▸ gcd_dvd_left f g))
      · exact h (zero_dvd_iff.mp (h0 ▸ gcd_dvd_right f g))
    refine ⟨normalize (gcd f g), ⟨Polynomial.monic_normalize hgcd, ?_, ?_, ?_⟩, ?_⟩
    · exact (normalize_dvd_iff).mpr (gcd_dvd_left f g)
    · exact (normalize_dvd_iff).mpr (gcd_dvd_right f g)
    · intro d h1 h2
      exact (dvd_normalize_iff).mpr (dvd_gcd h1 h2)
    · rintro h ⟨hm, h1, h2, h3⟩
      apply Polynomial.eq_of_monic_of_associated hm (Polynomial.monic_normalize hgcd)
      apply associated_of_dvd_dvd
      · exact (dvd_normalize_iff).mpr (dvd_gcd h1 h2)
      · exact h3 _ ((normalize_dvd_iff).mpr (gcd_dvd_left f g)) ((normalize_dvd_iff).mpr (gcd_dvd_right f g))

/-- Unique factorisation in F[x]. Over a field, every polynomial of degree 1 or more is a nonzero
constant times a product of irreducible polynomials, and once each irreducible factor is made
monic (top coefficient 1) the factors are the same every time, up to order: there is exactly one
collection of monic irreducibles that works. -/
theorem polynomial_factorises_uniquely_into_monic_irreducibles {F : Type*} [Field F]
    (f : F[X]) (hf : 0 < f.degree) :
    ∃! s : Multiset F[X], (∀ p ∈ s, p.Monic ∧ Irreducible p) ∧ ∃ c : F, f = C c * s.prod := by
  classical
  have hf0 : f ≠ 0 := by
    intro h; rw [h] at hf; simp at hf
  refine ⟨UniqueFactorizationMonoid.normalizedFactors f, ⟨?_, ?_⟩, ?_⟩
  · intro p hp
    refine ⟨?_, UniqueFactorizationMonoid.irreducible_of_normalized_factor p hp⟩
    have h0 : p ≠ 0 := (UniqueFactorizationMonoid.irreducible_of_normalized_factor p hp).ne_zero
    have := Polynomial.monic_normalize h0
    rwa [UniqueFactorizationMonoid.normalize_normalized_factor p hp] at this
  · obtain ⟨u, hu⟩ := UniqueFactorizationMonoid.prod_normalizedFactors hf0
    obtain ⟨c, hc, hcu⟩ := Polynomial.isUnit_iff.mp u.isUnit
    refine ⟨c, ?_⟩
    rw [hcu, mul_comm]
    exact hu.symm
  · rintro s ⟨hs, c, hc⟩
    have hc0 : c ≠ 0 := by
      rintro rfl
      apply hf0
      rw [hc]; simp
    have hirr : ∀ p ∈ s, Irreducible p := fun p hp => (hs p hp).2
    have hassoc : Associated s.prod f := by
      rw [hc, mul_comm]
      exact ⟨Units.map C.toMonoidHom (Units.mk0 c hc0), by simp⟩
    have hrel := UniqueFactorizationMonoid.factors_unique hirr
      (fun x hx => UniqueFactorizationMonoid.irreducible_of_normalized_factor x hx)
      (hassoc.trans (UniqueFactorizationMonoid.prod_normalizedFactors hf0).symm)
    rw [← Multiset.rel_eq]
    refine hrel.mono ?_
    intro a ha b hb hab
    have h1 : normalize a = a := (hs a ha).1.normalize_eq_self
    have h2 : normalize b = b := UniqueFactorizationMonoid.normalize_normalized_factor b hb
    rw [← h1, ← h2]
    exact normalize_eq_normalize_iff.mpr ⟨hab.dvd, hab.symm.dvd⟩

-- The whole-number loop: 84 = 2 × 36 + 12, then 36 = 3 × 12 + 0, so they share 12.
example : (84 : ℕ) = 2 * 36 + 12 ∧ (36 : ℕ) = 3 * 12 + 0 ∧ Nat.gcd 84 36 = 12 := by decide
-- Round one: the cubic divided by x^2 - 1 gives quotient x - 6 and remainder 12x - 12.
example : (X ^ 3 - 6 * X ^ 2 + 11 * X - 6 : ℚ[X]) = (X - 6) * (X ^ 2 - 1) + (12 * X - 12) := by
  ring
-- The long division, one top term at a time: take away x times g, then -6 times g.
example : (X ^ 3 - 6 * X ^ 2 + 11 * X - 6 : ℚ[X]) - (X ^ 3 - X) = -6 * X ^ 2 + 12 * X - 6 := by
  ring
example : (-6 * X ^ 2 + 12 * X - 6 : ℚ[X]) - (-6 * X ^ 2 + 6) = 12 * X - 12 := by ring
-- Strip the constant: 12x - 12 is 12 times x - 1.
example : (12 * X - 12 : ℚ[X]) = 12 * (X - 1) := by ring
-- Round two: x^2 - 1 divided by x - 1 gives x + 1, remainder 0.
example : (X ^ 2 - 1 : ℚ[X]) = (X + 1) * (X - 1) + 0 := by ring
-- x - 1 divides both: it leaves x^2 - 5x + 6 in the cubic and x + 1 in x^2 - 1.
example : (X ^ 3 - 6 * X ^ 2 + 11 * X - 6 : ℚ[X]) = (X - 1) * (X ^ 2 - 5 * X + 6) ∧
    (X ^ 2 - 1 : ℚ[X]) = (X - 1) * (X + 1) := by
  constructor <;> ring
-- Another route: the cubic is (x - 1)(x - 2)(x - 3).
example : (X ^ 3 - 6 * X ^ 2 + 11 * X - 6 : ℚ[X]) = (X - 1) * (X - 2) * (X - 3) := by ring
-- x + 1 divides x^2 - 1 but leaves -24 in the cubic, and the cubic at x = -1 is -24.
example : (X ^ 3 - 6 * X ^ 2 + 11 * X - 6 : ℚ[X]) = (X + 1) * (X ^ 2 - 7 * X + 18) + (-24) := by
  ring
example : (X ^ 3 - 6 * X ^ 2 + 11 * X - 6 : ℚ[X]).eval (-1) = -24 := by norm_num
-- The cubic's whole-number roots from -9 to 9 are 1, 2, 3; those of x^2 - 1 are -1, 1.
example : ((List.range 19).map (fun n : ℕ => (n : ℤ) - 9)).filter
    (fun t => t ^ 3 - 6 * t ^ 2 + 11 * t - 6 == 0) = [1, 2, 3] := by decide
example : ((List.range 19).map (fun n : ℕ => (n : ℤ) - 9)).filter
    (fun t => t ^ 2 - 1 == 0) = [-1, 1] := by decide
-- Constants are units: 2x^2 - 2 strips to x^2 - 1.
example : (2 * X ^ 2 - 2 : ℚ[X]) = 2 * (X ^ 2 - 1) := by ring
-- x^2 - 2 at x = -2, -1, 1, 2 is 2, -1, -1, 2: no whole-number root.
example : [-2, -1, 1, 2].map (fun t : ℤ => t ^ 2 - 2) = [2, -1, -1, 2] := by decide

#print axioms polynomials_over_a_field_divide_with_remainder
#print axioms euclid_swap_keeps_common_divisors_and_monic_gcd_is_unique
#print axioms polynomial_factorises_uniquely_into_monic_irreducibles
