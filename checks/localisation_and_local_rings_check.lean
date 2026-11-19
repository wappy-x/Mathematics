-- Localisation: the fraction rule is an equivalence that gives Mathlib's ring of fractions, the ring at a prime ideal has exactly one maximal ideal, and its primes are the old primes that miss the inverted set.
import Mathlib.RingTheory.Localization.AtPrime.Basic
import Mathlib.RingTheory.Localization.Ideal
import Mathlib.Algebra.Polynomial.Eval.Defs
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.LinearCombination

open Polynomial

/-- The local ring at a prime ideal `p` of a commutative ring `R`: after inverting everything
outside `p`, an ideal is maximal exactly when it is `p R_p`, the fractions with a top in `p`;
so `R_p` has exactly one maximal ideal, and every fraction outside it is a unit. -/
theorem localization_at_prime_has_exactly_one_maximal_ideal
    {R : Type*} [CommRing R] (p : Ideal R) [p.IsPrime] :
    (∀ M : Ideal (Localization.AtPrime p),
        M.IsMaximal ↔ M = p.map (algebraMap R (Localization.AtPrime p))) ∧
      ∀ x : Localization.AtPrime p,
        x ∉ p.map (algebraMap R (Localization.AtPrime p)) → IsUnit x := by
  have hm := IsLocalization.AtPrime.map_eq_maximalIdeal p (Localization.AtPrime p)
  rw [hm]
  refine ⟨fun M => ⟨fun h => IsLocalRing.eq_maximalIdeal h, fun h => h ▸ IsLocalRing.maximalIdeal.isMaximal _⟩,
    fun x hx => IsLocalRing.notMem_maximalIdeal.mp hx⟩

/-- The fraction rule: for a multiplicative set `S` (holding 1, closed under products),
`r/s = r'/s'` when `u (r s' - r' s) = 0` for some `u` in `S`. This rule is reflexive,
symmetric and transitive, and it is exactly equality in the ring of fractions `S⁻¹R`. -/
theorem fraction_rule_is_equivalence_and_defines_ring_of_fractions
    {R : Type*} [CommRing R] (S : Submonoid R) :
    Equivalence (fun (a b : R × S) => ∃ u ∈ S, u * (a.1 * b.2 - b.1 * a.2) = 0) ∧
      ∀ (r r' : R) (s s' : S),
        Localization.mk r s = Localization.mk r' s' ↔ ∃ u ∈ S, u * (r * s' - r' * s) = 0 := by
  have key : ∀ a b : R × S, (∃ u ∈ S, u * (a.1 * b.2 - b.1 * a.2) = 0) ↔ Localization.r S a b := by
    intro a b
    rw [Localization.r_iff_exists]
    constructor
    · rintro ⟨u, hu, h⟩
      refine ⟨⟨u, hu⟩, ?_⟩
      simp only
      linear_combination h
    · rintro ⟨c, h⟩
      refine ⟨c, c.2, ?_⟩
      linear_combination h
  refine ⟨?_, fun r r' s s' => by rw [Localization.mk_eq_mk_iff]; exact (key (r, s) (r', s')).symm⟩
  have he := (Localization.r S).iseqv
  exact ⟨fun a => (key a a).2 (he.refl a), fun h => (key _ _).2 (he.symm ((key _ _).1 h)),
    fun h1 h2 => (key _ _).2 (he.trans ((key _ _).1 h1) ((key _ _).1 h2))⟩

/-- The prime ideals of `S⁻¹R` match, one for one, the prime ideals of `R` that hold no member
of `S`: a prime of `S⁻¹R` goes to its pull-back, and a prime `q` of `R` missing `S` goes to
`q S⁻¹R`. -/
theorem primes_of_localization_are_primes_missing_S
    {R : Type*} [CommRing R] (S : Submonoid R) :
    ∃ e : {P : Ideal (Localization S) // P.IsPrime} ≃
        {q : Ideal R // q.IsPrime ∧ Disjoint (S : Set R) q},
      (∀ P, (e P).1 = P.1.comap (algebraMap R (Localization S))) ∧
        ∀ q, (e.symm q).1 = q.1.map (algebraMap R (Localization S)) := by
  refine ⟨(IsLocalization.orderIsoOfPrime S (Localization S)).toEquiv, fun P => rfl, fun q => rfl⟩

-- f = x^3 - x^2 factors as x^2 (x - 1), and x - 1 has value -1 at 0, so it is a unit near 0.
example : (X ^ 3 - X ^ 2 : ℚ[X]) = X ^ 2 * (X - 1) := by ring
example : (X - 1 : ℚ[X]).eval 0 = -1 := by norm_num
-- f(x + 1) = x^3 + 2x^2 + x, so the order of f at 1 is 1.
example : ((X + 1) ^ 3 - (X + 1) ^ 2 : ℚ[X]) = X ^ 3 + 2 * X ^ 2 + X := by ring
-- (x^2 - x)/(x^2 - 1) = x/(x + 1): both cross products are x^3 - x.
example : ((X ^ 2 - X) * (X + 1) : ℚ[X]) = X ^ 3 - X ∧ (X * (X ^ 2 - 1) : ℚ[X]) = X ^ 3 - X := by
  constructor <;> ring
-- (x + 2)/(x - 1) has value -2 at 0; x^2 (x - 1) = f, so x^2 = f / (x - 1) in the local ring.
example : (X + 2 : ℚ[X]).eval 0 / (X - 1 : ℚ[X]).eval 0 = -2 := by norm_num
-- Z/12 with the odd numbers inverted: (4, 1) ~ (0, 3) by plain cross-multiplication, but 4 ≠ 0,
-- and with u = 3 the full rule gives 4/1 = 0/1.
example : (4 : ZMod 12) * 3 = 0 * 1 ∧ (4 : ZMod 12) * 1 ≠ 0 * 1 ∧ (3 : ZMod 12) * (4 * 1 - 0 * 1) = 0 := by
  decide
-- Points on the figure: f(-3/4) = -63/64, f(2/3) = -4/27, f(3/2) = 9/8.
example : ((-3/4 : ℚ) ^ 3 - (-3/4) ^ 2, (2/3 : ℚ) ^ 3 - (2/3) ^ 2, (3/2 : ℚ) ^ 3 - (3/2) ^ 2)
    = (-63/64, -4/27, 9/8) := by norm_num
-- The finite copy F_3[x]/<f>: 3^3 = 27 elements, against 3^2 = 9 at the origin and 3 at 1.
example : (3 : ℕ) ^ 3 = 27 ∧ (3 : ℕ) ^ 2 * 3 ^ 1 = 27 := by norm_num

#print axioms localization_at_prime_has_exactly_one_maximal_ideal
#print axioms fraction_rule_is_equivalence_and_defines_ring_of_fractions
#print axioms primes_of_localization_are_primes_missing_S
