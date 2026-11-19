-- Domains, principal ideals and unique factorisation: every Euclidean domain is a principal ideal domain and every principal ideal domain factors uniquely, while polynomials in x and y factor uniquely but have no single generator for ⟨x, y⟩ and no Euclidean size.
import Mathlib.RingTheory.PrincipalIdealDomain
import Mathlib.RingTheory.Polynomial.UniqueFactorization
import Mathlib.NumberTheory.Zsqrtd.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.Ring
import Mathlib.Algebra.MvPolynomial.Division
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.LinearCombination

open MvPolynomial

/-- Euclidean implies principal implies unique factorisation: if a domain has a size
`s` with division by any nonzero `b` leaving a remainder that is 0 or of smaller size,
then every ideal is the multiples of one member, and every nonzero non-unit is a unit
times irreducibles in exactly one way, up to order and unit factors. -/
theorem euclidean_implies_pid_implies_ufd {R : Type*} [CommRing R] [IsDomain R]
    (s : R → ℕ)
    (hdiv : ∀ a b : R, b ≠ 0 → ∃ q r : R, a = q * b + r ∧ (r = 0 ∨ s r < s b)) :
    IsPrincipalIdealRing R ∧ UniqueFactorizationMonoid R := by
  have hpid : IsPrincipalIdealRing R := by
    refine ⟨fun I => ?_⟩
    classical
    by_cases hI : ∃ x ∈ I, x ≠ 0
    · have hex : ∃ n : ℕ, ∃ x ∈ I, x ≠ 0 ∧ s x = n := by
        obtain ⟨x, hx, hx0⟩ := hI
        exact ⟨s x, x, hx, hx0, rfl⟩
      obtain ⟨b, hb, hb0, hbs⟩ := Nat.find_spec hex
      refine ⟨⟨b, ?_⟩⟩
      apply le_antisymm
      · intro a ha
        obtain ⟨q, r, hqr, hr⟩ := hdiv a b hb0
        have hrI : r ∈ I := by
          have : r = a - q * b := by rw [hqr]; ring
          rw [this]
          exact I.sub_mem ha (I.mul_mem_left q hb)
        by_cases hr0 : r = 0
        · rw [Ideal.submodule_span_eq, Ideal.mem_span_singleton]
          exact ⟨q, by rw [hqr, hr0]; ring⟩
        · exfalso
          rcases hr with hr | hr
          · exact hr0 hr
          · have := Nat.find_min' hex ⟨r, hrI, hr0, rfl⟩
            omega
      · rw [Ideal.submodule_span_eq, Ideal.span_le]
        simpa using hb
    · push Not at hI
      refine ⟨⟨0, ?_⟩⟩
      rw [Ideal.submodule_span_eq, Ideal.span_singleton_eq_bot.mpr rfl]
      exact (Submodule.eq_bot_iff I).mpr hI
  exact ⟨hpid, inferInstance⟩

/-- In a principal ideal domain the gcd is a combination and irreducible means prime:
any two members have a common divisor `d = u a + v b` that every common divisor divides,
and an irreducible dividing a product divides one factor (Euclid's lemma). -/
theorem pid_gcd_is_combination_and_irreducible_is_prime {R : Type*} [CommRing R] [IsDomain R]
    [IsPrincipalIdealRing R] :
    (∀ a b : R, ∃ d u v : R, d ∣ a ∧ d ∣ b ∧ (∀ e : R, e ∣ a → e ∣ b → e ∣ d) ∧
      d = u * a + v * b) ∧
    (∀ p : R, Irreducible p → Prime p) := by
  refine ⟨fun a b => ?_, fun p hp => ?_⟩
  · obtain ⟨d, hd⟩ := (IsPrincipalIdealRing.principal (Ideal.span {a, b})).principal
    have hd' : Ideal.span {a, b} = Ideal.span {d} := hd
    have ha : a ∈ Ideal.span {d} := hd' ▸ Ideal.subset_span (by simp)
    have hb : b ∈ Ideal.span {d} := hd' ▸ Ideal.subset_span (by simp)
    have hdm : d ∈ Ideal.span {a, b} := hd' ▸ Ideal.mem_span_singleton_self d
    obtain ⟨u, v, huv⟩ := Ideal.mem_span_pair.mp hdm
    refine ⟨d, u, v, Ideal.mem_span_singleton.mp ha, Ideal.mem_span_singleton.mp hb, ?_, huv.symm⟩
    intro e hea heb
    rw [← huv]
    exact dvd_add (dvd_mul_of_dvd_right hea u) (dvd_mul_of_dvd_right heb v)
  · exact UniqueFactorizationMonoid.irreducible_iff_prime.mp hp

/-- Polynomials in x and y over any field `k` are a unique factorisation domain, yet the
ideal ⟨x, y⟩ of polynomials vanishing at the origin has no single generator, so `k[x, y]`
is not a principal ideal domain and has no Euclidean size. -/
theorem polynomials_in_x_and_y_ufd_not_pid (k : Type*) [Field k] :
    UniqueFactorizationMonoid (MvPolynomial (Fin 2) k) ∧
    ¬ (Ideal.span {X 0, X 1} : Ideal (MvPolynomial (Fin 2) k)).IsPrincipal ∧
    ¬ IsPrincipalIdealRing (MvPolynomial (Fin 2) k) ∧
    ¬ ∃ s : MvPolynomial (Fin 2) k → ℕ, ∀ a b : MvPolynomial (Fin 2) k, b ≠ 0 →
      ∃ q r : MvPolynomial (Fin 2) k, a = q * b + r ∧ (r = 0 ∨ s r < s b) := by
  have hnp : ¬ (Ideal.span {X 0, X 1} : Ideal (MvPolynomial (Fin 2) k)).IsPrincipal := by
    rintro ⟨f, hf⟩
    have hf' : (Ideal.span {X 0, X 1} : Ideal (MvPolynomial (Fin 2) k)) = Ideal.span {f} := hf
    have h0 : (X 0 : MvPolynomial (Fin 2) k) ∈ Ideal.span {f} := hf' ▸ Ideal.subset_span (by simp)
    have h1 : (X 1 : MvPolynomial (Fin 2) k) ∈ Ideal.span {f} := hf' ▸ Ideal.subset_span (by simp)
    rw [Ideal.mem_span_singleton] at h0 h1
    have hirr : Irreducible (X 0 : MvPolynomial (Fin 2) k) := (MvPolynomial.prime_X).irreducible
    obtain ⟨g, hg⟩ := h0
    rcases hirr.isUnit_or_isUnit hg with hu | hu
    · have hfm : f ∈ Ideal.span {X 0, X 1} := hf' ▸ Ideal.mem_span_singleton_self f
      have htop : (Ideal.span {X 0, X 1} : Ideal (MvPolynomial (Fin 2) k)) = ⊤ :=
        Ideal.eq_top_of_isUnit_mem _ hfm hu
      have h1m : (1 : MvPolynomial (Fin 2) k) ∈ Ideal.span {X 0, X 1} := htop ▸ Submodule.mem_top
      obtain ⟨a, b, hab⟩ := Ideal.mem_span_pair.mp h1m
      have := congrArg (MvPolynomial.constantCoeff (R := k) (σ := Fin 2)) hab
      simp at this
    · have hassoc : Associated f (X 0 : MvPolynomial (Fin 2) k) := ⟨hu.unit, by rw [hg, IsUnit.unit_spec]⟩
      have : (X 0 : MvPolynomial (Fin 2) k) ∣ X 1 := hassoc.symm.dvd.trans h1
      rw [MvPolynomial.X_dvd_X] at this
      exact absurd this (by decide)
  have hnpid : ¬ IsPrincipalIdealRing (MvPolynomial (Fin 2) k) := by
    intro h
    exact hnp (h.principal _)
  refine ⟨inferInstance, hnp, hnpid, ?_⟩
  rintro ⟨s, hs⟩
  exact hnpid (euclidean_implies_pid_implies_ufd s hs).1

-- Euclid on the rods 1071 mm and 462 mm: three divisions, gcd 21, and 21 = 7 × 462 − 3 × 1071.
example : (1071 : ℤ) = 2 * 462 + 147 ∧ (462 : ℤ) = 3 * 147 + 21 ∧ (147 : ℤ) = 7 * 21 + 0 := by
  norm_num
example : Int.gcd 1071 462 = 21 := by decide
example : (21 : ℤ) = 7 * 462 - 3 * 1071 := by norm_num

-- One letter over ℚ: f = (x − 6) g + (12x − 12), g = (x + 1)(x − 1), and x − 1 = u f + v g.
example : (Polynomial.X ^ 3 - 6 * Polynomial.X ^ 2 + 11 * Polynomial.X - 6 : Polynomial ℚ) =
    (Polynomial.X - 6) * (Polynomial.X ^ 2 - 1) + (12 * Polynomial.X - 12) := by ring
example : (Polynomial.X ^ 2 - 1 : Polynomial ℚ) = (Polynomial.X + 1) * (Polynomial.X - 1) := by
  ring
example : Polynomial.C (1 / 12 : ℚ) * (Polynomial.X ^ 3 - 6 * Polynomial.X ^ 2 + 11 * Polynomial.X - 6)
    + (Polynomial.C (-1 / 12 : ℚ) * Polynomial.X + Polynomial.C (1 / 2 : ℚ)) * (Polynomial.X ^ 2 - 1)
    = Polynomial.X - 1 := by
  have h1 : Polynomial.C (-1 / 12 : ℚ) = - Polynomial.C (1 / 12) := by
    rw [← Polynomial.C_neg]; norm_num
  have h2 : Polynomial.C (1 / 2 : ℚ) = 6 * Polynomial.C (1 / 12) := by
    rw [← map_ofNat Polynomial.C 6, ← Polynomial.C_mul]; norm_num
  have h3 : Polynomial.C (1 / 12 : ℚ) * 12 = 1 := by
    rw [← map_ofNat Polynomial.C 12, ← Polynomial.C_mul]; norm_num
  rw [h1, h2]
  linear_combination (Polynomial.X - 1 : Polynomial ℚ) * h3

-- Two letters: x²y − y³ = y (x − y)(x + y).
example : (X 0 ^ 2 * X 1 - X 1 ^ 3 : MvPolynomial (Fin 2) ℚ) =
    X 1 * (X 0 - X 1) * (X 0 + X 1) := by ring

-- Zero divisors on the 12-hour clock: 3 × 4 = 0, and 4 = 2 × 2 = 4 × 4 = 2 × 8.
example : (3 * 4 : ZMod 12) = 0 := by decide
example : (2 * 2 : ZMod 12) = 4 ∧ (4 * 4 : ZMod 12) = 4 ∧ (2 * 8 : ZMod 12) = 4 := by decide

-- ℤ[√−5]: 6 = 2 × 3 = (1 + √−5)(1 − √−5), with norms 4 × 9 = 36 = 6 × 6.
example : (⟨2, 0⟩ * ⟨3, 0⟩ : ℤ√(-5)) = 6 ∧ (⟨1, 1⟩ * ⟨1, -1⟩ : ℤ√(-5)) = 6 := by decide
example : Zsqrtd.norm (⟨2, 0⟩ : ℤ√(-5)) = 4 ∧ Zsqrtd.norm (⟨3, 0⟩ : ℤ√(-5)) = 9 ∧
    Zsqrtd.norm (⟨1, 1⟩ : ℤ√(-5)) = 6 ∧ Zsqrtd.norm (⟨1, -1⟩ : ℤ√(-5)) = 6 := by decide

#print axioms euclidean_implies_pid_implies_ufd
#print axioms pid_gcd_is_combination_and_irreducible_is_prime
#print axioms polynomials_in_x_and_y_ufd_not_pid
