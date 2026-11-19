-- Splitting and ramification: a prime p ramifies in a number field exactly when p divides the field discriminant, and when O_K = ℤ[θ] each monic irreducible factor of θ's polynomial mod p gives a prime ideal (p, g(θ)) whose ramification index is the factor's multiplicity and whose residue degree is its degree.
import Mathlib.NumberTheory.NumberField.Discriminant.Different
import Mathlib.NumberTheory.NumberField.Ideal.KummerDedekind
import Mathlib.NumberTheory.Zsqrtd.Basic
import Mathlib.NumberTheory.LegendreSymbol.QuadraticReciprocity
import Mathlib.Tactic.NormNum.LegendreSymbol

open NumberField Polynomial

/-- Dedekind's discriminant rule: in any number field `K`, a prime `p` ramifies (some prime
ideal `𝔭` of `O_K` containing `p` has ramification index `e ≥ 2`) exactly when `p` divides the
field discriminant `d_K`. -/
theorem ramifies_iff_dvd_discr (K : Type*) [Field K] [NumberField K] (p : ℕ) (hp : p.Prime) :
    (∃ P : Ideal (𝓞 K), P.IsPrime ∧ (p : 𝓞 K) ∈ P ∧ 2 ≤ P.ramificationIdx ℤ) ↔
      (p : ℤ) ∣ discr K := by
  have hpZ : Prime (p : ℤ) := Nat.prime_iff_prime_int.mp hp
  have h := NumberField.not_dvd_discr_iff_forall_mem K (𝓞 K) hpZ
  have : Ring.HasFiniteQuotients ℤ := .of_module_finite ℤ _
  rw [← not_iff_not, h]
  push Not
  apply forall_congr'; intro P
  apply forall_congr'; intro hP
  have hcast : (((p : ℤ) : 𝓞 K)) = (p : 𝓞 K) := Int.cast_natCast p
  rw [hcast]
  apply imp_congr_right; intro _
  rw [← Ideal.ramificationIdx_eq_one_iff]
  have := Ideal.ramificationIdx_pos ℤ P
  omega

/-- The Kummer–Dedekind factoring rule: suppose `O_K = ℤ[θ]` and `g` is a monic irreducible
factor of `f`, the monic polynomial of `θ`, modulo `p`, with `Q` any whole-number polynomial
reducing to `g`. Then `(p, Q(θ))` is a prime ideal; its ramification index is how often `g`
repeats in `f` mod `p`, and its residue degree is the degree of `g`. Every prime ideal
containing `p` arises this way. -/
theorem kummer_dedekind_factoring_rule (K : Type*) [Field K] [NumberField K] (θ : 𝓞 K)
    (hθ : Algebra.adjoin ℤ {θ} = ⊤) (p : ℕ) (hp : p.Prime) :
    (∀ Q : ℤ[X], (Q.map (Int.castRingHom (ZMod p))).Monic →
        Irreducible (Q.map (Int.castRingHom (ZMod p))) →
        Q.map (Int.castRingHom (ZMod p)) ∣ (minpoly ℤ θ).map (Int.castRingHom (ZMod p)) →
        (Ideal.span {(p : 𝓞 K), aeval θ Q}).IsPrime ∧
        (Ideal.span {(p : 𝓞 K), aeval θ Q}).ramificationIdx ℤ =
          multiplicity (Q.map (Int.castRingHom (ZMod p)))
            ((minpoly ℤ θ).map (Int.castRingHom (ZMod p))) ∧
        (Ideal.span {(p : 𝓞 K), aeval θ Q}).inertiaDeg ℤ =
          (Q.map (Int.castRingHom (ZMod p))).natDegree) ∧
    (∀ P : Ideal (𝓞 K), P.IsPrime → (p : 𝓞 K) ∈ P →
      ∃ Q : ℤ[X], (Q.map (Int.castRingHom (ZMod p))).Monic ∧
        Irreducible (Q.map (Int.castRingHom (ZMod p))) ∧
        Q.map (Int.castRingHom (ZMod p)) ∣ (minpoly ℤ θ).map (Int.castRingHom (ZMod p)) ∧
        P = Ideal.span {(p : 𝓞 K), aeval θ Q}) := by
  have : Fact p.Prime := ⟨hp⟩
  have hexp : ¬ p ∣ RingOfIntegers.exponent θ := by
    rw [RingOfIntegers.exponent_eq_one_iff.mpr hθ]
    exact hp.not_dvd_one
  refine ⟨fun Q hmon hirr hdvd ↦ ?_, fun P hP hmem ↦ ?_⟩
  · have hQ : Q.map (Int.castRingHom (ZMod p)) ∈ RingOfIntegers.monicFactorsMod θ p :=
      RingOfIntegers.mem_monicFactorsMod_iff.mpr ⟨hirr, hmon, hdvd⟩
    have hspan := NumberField.Ideal.primesOverSpanEquivMonicFactorsMod_symm_apply_eq_span hexp hQ
    refine ⟨?_, ?_, ?_⟩
    · rw [← hspan]
      exact ((NumberField.Ideal.primesOverSpanEquivMonicFactorsMod hexp).symm ⟨_, hQ⟩).prop.1
    · rw [← hspan]
      exact NumberField.Ideal.ramificationIdx_primesOverSpanEquivMonicFactorsMod_symm_apply hexp hQ
    · rw [← hspan]
      exact NumberField.Ideal.inertiaDeg_primesOverSpanEquivMonicFactorsMod_symm_apply hexp hQ
  · have hlies : P.LiesOver (Ideal.span {(p : ℤ)}) := by
      rw [Ideal.liesOver_span_iff hP.ne_top (Nat.prime_iff_prime_int.mp hp)]
      simpa using hmem
    let P' : (Ideal.span {(p : ℤ)}).primesOver (𝓞 K) := ⟨P, hP, hlies⟩
    let F := NumberField.Ideal.primesOverSpanEquivMonicFactorsMod (K := K) hexp P'
    obtain ⟨Q, hQ⟩ := (map_surjective _ (ZMod.ringHom_surjective (Int.castRingHom (ZMod p))))
      (F : (ZMod p)[X])
    have hF : Q.map (Int.castRingHom (ZMod p)) ∈ RingOfIntegers.monicFactorsMod θ p := by
      rw [hQ]; exact F.2
    obtain ⟨hirr, hmon, hdvd⟩ := RingOfIntegers.mem_monicFactorsMod_iff.mp hF
    refine ⟨Q, hmon, hirr, hdvd, ?_⟩
    rw [← NumberField.Ideal.primesOverSpanEquivMonicFactorsMod_symm_apply_eq_span hexp hF]
    have : (⟨Q.map (Int.castRingHom (ZMod p)), hF⟩ : RingOfIntegers.monicFactorsMod θ p) = F :=
      Subtype.ext hQ
    rw [this, Equiv.symm_apply_apply]

/-- The rule modulo 20 for `ℤ[√-5]`: for a prime `p` other than 2 and 5, `-5` is a square
modulo `p` (so `x² + 5` has two roots and `p` splits) exactly when `p ≡ 1, 3, 7` or `9`
modulo 20; otherwise `p` is inert. -/
theorem neg_five_square_iff_mod_twenty (p : ℕ) (hp : p.Prime) (h2 : p ≠ 2) (h5 : p ≠ 5) :
    IsSquare (-5 : ZMod p) ↔ p % 20 = 1 ∨ p % 20 = 3 ∨ p % 20 = 7 ∨ p % 20 = 9 := by
  have := Fact.mk hp
  have : Fact (Nat.Prime 5) := ⟨Nat.prime_five⟩
  have hne : (((-5 : ℤ)) : ZMod p) ≠ 0 := by
    intro h
    have h' : ((5 : ℤ) : ZMod p) = 0 := by
      have := congrArg Neg.neg h
      simpa using this
    rw [ZMod.intCast_zmod_eq_zero_iff_dvd] at h'
    have : p ∣ 5 := by exact_mod_cast h'
    have := (Nat.prime_dvd_prime_iff_eq hp Nat.prime_five).mp this
    exact h5 this
  have key : IsSquare (-5 : ZMod p) ↔ legendreSym p (-5) = 1 := by
    rw [legendreSym.eq_one_iff p hne]; push_cast; rfl
  rw [key, show (-5 : ℤ) = -1 * 5 by norm_num, legendreSym.mul, legendreSym.at_neg_one h2]
  have qr : legendreSym p ((5 : ℕ) : ℤ) = legendreSym 5 (p : ℤ) :=
    legendreSym.quadratic_reciprocity_one_mod_four (p := 5) (q := p) (by norm_num) h2
  simp only [Nat.cast_ofNat] at qr
  rw [qr, legendreSym.mod 5 (p : ℤ), ZMod.χ₄_nat_mod_four]
  have h4 : p % 2 = 1 := (Nat.Prime.mod_two_eq_one_iff_ne_two (Fact.out)).mpr h2
  have h5' : p % 5 ≠ 0 := by
    intro h
    have : 5 ∣ p := Nat.dvd_of_mod_eq_zero h
    exact h5 ((Nat.prime_dvd_prime_iff_eq Nat.prime_five hp).mp this).symm
  have hcast : ((p : ℤ) % ((5 : ℕ) : ℤ)) = ((p % 5 : ℕ) : ℤ) := by push_cast; rfl
  rw [hcast]
  have : p % 20 = 1 ∨ p % 20 = 3 ∨ p % 20 = 7 ∨ p % 20 = 9 ∨ p % 20 = 11 ∨ p % 20 = 13 ∨
      p % 20 = 17 ∨ p % 20 = 19 := by omega
  rcases this with h | h | h | h | h | h | h | h <;>
  · rw [show p % 4 = (p % 20) % 4 by omega, show p % 5 = (p % 20) % 5 by omega, h]
    norm_num

-- The card's worked numbers.
-- The discriminant of x² + 5 is 0² - 4 × 5 = -20 = -2² × 5.
example : (0 : ℤ) ^ 2 - 4 * 5 = -20 ∧ (-20 : ℤ) = -(2 ^ 2 * 5) := by norm_num
-- Modulo 29, x² + 5 has exactly the two roots 13 and 16, so 29 splits.
example : ∀ x : ZMod 29, x ^ 2 + 5 = 0 ↔ x = 13 ∨ x = 16 := by decide
-- 13² = 169 = 5 × 29 + 24, and 3 + 2 × 13 = 29.
example : (13 : ℤ) ^ 2 = 5 * 29 + 24 ∧ (3 : ℤ) + 2 * 13 = 29 := by norm_num
-- 29 = (3 + 2√-5)(3 - 2√-5), and N(3 + 2√-5) = 3² + 5 × 2² = 29.
example : ((⟨3, 2⟩ : ℤ√(-5)) * ⟨3, -2⟩) = ⟨29, 0⟩ := by decide
example : (⟨3, 2⟩ : ℤ√(-5)).norm = 29 := by decide
-- Modulo 5, x² + 5 has the single root 0, and (√-5)² = -5: 5 ramifies.
example : ∀ x : ZMod 5, x ^ 2 + 5 = 0 ↔ x = 0 := by decide
example : (Zsqrtd.sqrtd : ℤ√(-5)) * Zsqrtd.sqrtd = -5 := by decide
-- Modulo 11, x² + 5 has no root: 11 is inert.
example : ∀ x : ZMod 11, x ^ 2 + 5 ≠ 0 := by decide
-- Modulo 2, x² + 5 = (x + 1)², and (1 + √-5)² = -4 + 2√-5; 2 + 2√-5 - (-4 + 2√-5) - 4 = 2.
example : ∀ x : ZMod 2, x ^ 2 + 5 = (x + 1) ^ 2 := by decide
example : ((⟨1, 1⟩ : ℤ√(-5)) * ⟨1, 1⟩) = ⟨-4, 2⟩ ∧
    (⟨2, 2⟩ : ℤ√(-5)) - ⟨-4, 2⟩ - 4 = 2 := by decide
-- Modulo 3, x² + 5 has roots 1 and 2, so 3 splits, yet no a² + 5b² equals 3.
example : ∀ x : ZMod 3, x ^ 2 + 5 = 0 ↔ x = 1 ∨ x = 2 := by decide
example : ∀ a b : Fin 2, (a : ℕ) ^ 2 + 5 * (b : ℕ) ^ 2 ≠ 3 := by decide
-- 6 = 2 × 3 = (1 + √-5)(1 - √-5), with N(1 + √-5) = 6 = 2 × 3.
example : ((⟨1, 1⟩ : ℤ√(-5)) * ⟨1, -1⟩) = 2 * 3 := by decide
-- Gaussian integers: x² + 1 has two roots mod 5 and 13, none mod 3 and 7, one double root mod 2.
example : (∀ x : ZMod 5, x ^ 2 + 1 = 0 ↔ x = 2 ∨ x = 3) ∧
    (∀ x : ZMod 13, x ^ 2 + 1 = 0 ↔ x = 5 ∨ x = 8) ∧
    (∀ x : ZMod 3, x ^ 2 + 1 ≠ 0) ∧ (∀ x : ZMod 7, x ^ 2 + 1 ≠ 0) ∧
    (∀ x : ZMod 2, x ^ 2 + 1 = (x + 1) ^ 2) := by decide
-- The cubic x³ - 2: d = -27 × 2² = -108 = -(2² × 3³).
example : (-27 : ℤ) * 2 ^ 2 = -108 ∧ (-108 : ℤ) = -(2 ^ 2 * 3 ^ 3) := by norm_num
-- Roots of x³ - 2: mod 2 only 0, mod 3 only 2, mod 5 only 3, mod 7 none, mod 31 exactly 4, 7, 20.
example : (∀ x : ZMod 2, x ^ 3 - 2 = 0 ↔ x = 0) ∧ (∀ x : ZMod 3, x ^ 3 - 2 = 0 ↔ x = 2) ∧
    (∀ x : ZMod 5, x ^ 3 - 2 = 0 ↔ x = 3) ∧ (∀ x : ZMod 7, x ^ 3 - 2 ≠ 0) ∧
    (∀ x : ZMod 31, x ^ 3 - 2 = 0 ↔ x = 4 ∨ x = 7 ∨ x = 20) := by decide
-- What breaks: x² - 5 has the double root 1 mod 2, but x² - x - 1 has no root mod 2.
example : (∀ x : ZMod 2, x ^ 2 - 5 = (x + 1) ^ 2) ∧ (∀ x : ZMod 2, x ^ 2 - x - 1 ≠ 0) := by decide
-- The field discriminant of Q(√5) is 1² - 4 × (-1) = 5, while x² - 5 has discriminant 20.
example : (1 : ℤ) ^ 2 - 4 * (-1) = 5 ∧ (0 : ℤ) ^ 2 - 4 * (-5) = 20 := by norm_num

#print axioms ramifies_iff_dvd_discr
#print axioms kummer_dedekind_factoring_rule
#print axioms neg_five_square_iff_mod_twenty
