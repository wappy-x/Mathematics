-- Cyclotomic fields: the field made by a primitive nth root of unity has degree φ(n) over the rationals, its symmetries are the invertible remainders mod n, and its middle fields match their subgroups.
import Mathlib.NumberTheory.Cyclotomic.Gal
import Mathlib.RingTheory.Polynomial.Cyclotomic.Roots
import Mathlib.FieldTheory.Galois.Basic
import Mathlib.Analysis.Complex.Polynomial.Basic
import Mathlib.Tactic.LinearCombination
import Mathlib.RingTheory.Polynomial.Cyclotomic.Expand

open Polynomial IntermediateField

/-- The nth roots of unity generate a field of degree φ(n) over the rationals: for a primitive
nth root of unity ζ in the complex numbers, the field ℚ(ζ) has degree φ(n), and its symmetries
match the invertible remainders mod n, the symmetry for k sending ζ to ζ^k. -/
theorem cyclotomic_field_degree_totient_and_galois_units {n : ℕ} (hn : 0 < n) {ζ : ℂ}
    (hζ : IsPrimitiveRoot ζ n) :
    Module.finrank ℚ ℚ⟮ζ⟯ = n.totient ∧
      ∃ e : (ℚ⟮ζ⟯ ≃ₐ[ℚ] ℚ⟮ζ⟯) ≃* (ZMod n)ˣ,
        ∀ σ, ((σ (AdjoinSimple.gen ℚ ζ) : ℚ⟮ζ⟯) : ℂ) = ζ ^ ((e σ : ZMod n).val) := by
  have : NeZero n := ⟨hn.ne'⟩
  have : IsCyclotomicExtension {n} ℚ ℚ⟮ζ⟯ := by
    change IsCyclotomicExtension {n} ℚ (IntermediateField.adjoin ℚ {ζ}).toSubalgebra
    rw [IntermediateField.adjoin_simple_toSubalgebra_of_isAlgebraic
      ((hζ.isIntegral hn).tower_top (A := ℚ)).isAlgebraic]
    exact hζ.adjoin_isCyclotomicExtension ℚ
  have hirr : Irreducible (cyclotomic n ℚ) := cyclotomic.irreducible_rat hn
  refine ⟨IsCyclotomicExtension.finrank ℚ⟮ζ⟯ hirr, IsCyclotomicExtension.autEquivPow ℚ⟮ζ⟯ hirr,
    fun σ => ?_⟩
  have hx : (AdjoinSimple.gen ℚ ζ) ^ n = 1 := by
    apply Subtype.ext
    simp [hζ.pow_eq_one]
  rw [IsCyclotomicExtension.autEquivPow_apply_of_pow_eq_one ℚ⟮ζ⟯ hirr σ hx]
  simp

/-- Every middle field matches a subgroup of the invertible remainders: sending a field F
between ℚ and ℚ(ζ) to the remainders k whose symmetry (ζ ↦ ζ^k) fixes every number in F is an
order-reversing one-to-one match of middle fields with subgroups, and the degree of F times the
size of its subgroup is φ(n). -/
theorem middle_fields_match_subgroups_of_units {n : ℕ} (hn : 0 < n) {ζ : ℂ}
    (hζ : IsPrimitiveRoot ζ n) :
    ∃ e : (ℚ⟮ζ⟯ ≃ₐ[ℚ] ℚ⟮ζ⟯) ≃* (ZMod n)ˣ,
      (∀ σ, ((σ (AdjoinSimple.gen ℚ ζ) : ℚ⟮ζ⟯) : ℂ) = ζ ^ ((e σ : ZMod n).val)) ∧
      ∃ c : IntermediateField ℚ ℚ⟮ζ⟯ ≃o (Subgroup (ZMod n)ˣ)ᵒᵈ,
        (∀ (F : IntermediateField ℚ ℚ⟮ζ⟯) k, k ∈ OrderDual.ofDual (c F) ↔ ∀ x ∈ F, e.symm k x = x) ∧
        ∀ F : IntermediateField ℚ ℚ⟮ζ⟯,
          Module.finrank ℚ F * Nat.card ↥(OrderDual.ofDual (c F)) = n.totient := by
  have : NeZero n := ⟨hn.ne'⟩
  have : IsCyclotomicExtension {n} ℚ ℚ⟮ζ⟯ := by
    change IsCyclotomicExtension {n} ℚ (IntermediateField.adjoin ℚ {ζ}).toSubalgebra
    rw [IntermediateField.adjoin_simple_toSubalgebra_of_isAlgebraic
      ((hζ.isIntegral hn).tower_top (A := ℚ)).isAlgebraic]
    exact hζ.adjoin_isCyclotomicExtension ℚ
  have : IsGalois ℚ ℚ⟮ζ⟯ := IsCyclotomicExtension.isGalois {n} ℚ ℚ⟮ζ⟯
  have : FiniteDimensional ℚ ℚ⟮ζ⟯ := IsCyclotomicExtension.finiteDimensional {n} ℚ ℚ⟮ζ⟯
  obtain ⟨hdeg, e, he⟩ := cyclotomic_field_degree_totient_and_galois_units hn hζ
  refine ⟨e, he, (IsGalois.intermediateFieldEquivSubgroup).trans (MulEquiv.mapSubgroup e).dual,
    fun F k => ?_, fun F => ?_⟩
  · simp only [OrderIso.trans_apply, IsGalois.intermediateFieldEquivSubgroup_apply,
      OrderIso.dual_apply, OrderDual.ofDual_toDual, MulEquiv.coe_mapSubgroup]
    rw [Subgroup.mem_map_equiv, IntermediateField.mem_fixingSubgroup_iff]
  · simp only [OrderIso.trans_apply, IsGalois.intermediateFieldEquivSubgroup_apply,
      OrderIso.dual_apply, OrderDual.ofDual_toDual, MulEquiv.coe_mapSubgroup]
    have hcard : Nat.card ↥(Subgroup.map e.toMonoidHom F.fixingSubgroup) =
        Nat.card F.fixingSubgroup :=
      (Nat.card_congr (F.fixingSubgroup.equivMapOfInjective e.toMonoidHom e.injective)).symm
    rw [hcard, IsGalois.card_fixingSubgroup_eq_finrank, Module.finrank_mul_finrank, hdeg]

/-- The cyclotomic polynomial Φ_n has integer coefficients and degree φ(n), it is the minimal
polynomial of any primitive nth root of unity over the rationals, and x^n − 1 is the product of
Φ_d over the divisors d of n. -/
theorem cyclotomic_poly_minpoly_degree_totient {n : ℕ} (hn : 0 < n) {ζ : ℂ}
    (hζ : IsPrimitiveRoot ζ n) :
    minpoly ℚ ζ = (cyclotomic n ℤ).map (Int.castRingHom ℚ) ∧
      (cyclotomic n ℤ).natDegree = n.totient ∧
      ∏ d ∈ n.divisors, cyclotomic d ℤ = X ^ n - 1 := by
  refine ⟨?_, natDegree_cyclotomic n ℤ, prod_cyclotomic_eq_X_pow_sub_one hn ℤ⟩
  rw [map_cyclotomic, cyclotomic_eq_minpoly_rat hζ hn]

-- The exponents from 1 to 12 sharing no factor with 12 are 1, 5, 7, 11; φ(12) = 4.
example : (Finset.range 13).filter (fun k => Nat.Coprime k 12) = {1, 5, 7, 11} := by decide
example : Nat.totient 12 = 4 := by decide

-- Degree of Φ_n for n = 1 to 12, read as φ(n).
example : (List.range 12).map (fun n => Nat.totient (n + 1)) = [1, 1, 2, 2, 4, 2, 6, 4, 6, 4, 10, 4] := by
  decide

-- Φ_12 = x^4 − x^2 + 1, and the six boxes of the picture rebuild x^12 − 1.
example : cyclotomic 12 ℤ = X ^ 4 - X ^ 2 + 1 := by
  have h6 : cyclotomic 6 ℤ = X ^ 2 - X + 1 := by
    have h := cyclotomic_expand_eq_cyclotomic_mul Nat.prime_two (by decide : ¬ 2 ∣ 3) ℤ
    rw [cyclotomic_three] at h
    have hne : (X ^ 2 + X + 1 : ℤ[X]) ≠ 0 := by
      rw [← cyclotomic_three]; exact cyclotomic_ne_zero 3 ℤ
    apply mul_right_cancel₀ hne
    rw [show (3 * 2 : ℕ) = 6 from rfl] at h
    rw [← h]
    simp only [map_add, map_pow, expand_X, map_one]
    ring
  have h := cyclotomic_expand_eq_cyclotomic Nat.prime_two (by decide : 2 ∣ 6) ℤ
  rw [show (6 * 2 : ℕ) = 12 from rfl, h6] at h
  rw [← h]
  simp only [map_add, map_sub, map_pow, expand_X, map_one]
  ring
example : (X ^ 12 - 1 : ℤ[X]) = (X - 1) * (X + 1) * (X ^ 2 + X + 1) * (X ^ 2 + 1) *
    (X ^ 2 - X + 1) * (X ^ 4 - X ^ 2 + 1) := by ring
example : (X ^ 2 + 1 : ℤ[X]) * (X ^ 4 - X ^ 2 + 1) = X ^ 6 + 1 := by ring

-- The multiplication table mod 12: every invertible remainder is its own undo, so none has order 4.
example : ∀ k : (ZMod 12)ˣ, k ^ 2 = 1 := by decide
example : (5 * 7 : ZMod 12) = 11 ∧ (5 * 11 : ZMod 12) = 7 ∧ (7 * 11 : ZMod 12) = 5 := by decide

-- The three numbers fixed by the symmetries square to 3, −1 and −3.
example (z : ℂ) (h : z ^ 4 - z ^ 2 + 1 = 0) : (z + z ^ 11) ^ 2 = 3 := by
  linear_combination (-3 - 2 * z ^ 2 + z ^ 4 + 3 * z ^ 6 + 2 * z ^ 8 - z ^ 10 - z ^ 12
    + z ^ 16 + z ^ 18) * h
example (z : ℂ) (h : z ^ 4 - z ^ 2 + 1 = 0) : (z ^ 3) ^ 2 = -1 := by
  linear_combination (z ^ 2 + 1) * h
example (z : ℂ) (h : z ^ 4 - z ^ 2 + 1 = 0) : (2 * z ^ 2 - 1) ^ 2 = -3 := by
  linear_combination 4 * h

-- Mod 5, Φ_12 = (x^2 + 2x + 4)(x^2 + 3x + 4): the difference is a multiple of 5.
example : (X ^ 2 + 2 * X + 4 : ℤ[X]) * (X ^ 2 + 3 * X + 4) =
    X ^ 4 - X ^ 2 + 1 + 5 * (X ^ 3 + 3 * X ^ 2 + 4 * X + 3) := by ring

-- Among the 23 primes from 5 to 97, Φ_12 has four roots mod p exactly for 13, 37, 61, 73, 97,
-- the primes leaving remainder 1 on division by 12, and no roots for the other 18.
example : ([5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89,
    97].filter fun p => ((List.range p).filter fun x => (x ^ 4 + 1) % p = x ^ 2 % p).length = 4)
    = [13, 37, 61, 73, 97] := by decide
example : ([5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89,
    97].filter fun p => ((List.range p).filter fun x => (x ^ 4 + 1) % p = x ^ 2 % p).length = 0)
    = [5, 7, 11, 17, 19, 23, 29, 31, 41, 43, 47, 53, 59, 67, 71, 79, 83, 89] := by decide
example : ([5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89,
    97].filter fun p => p % 12 = 1) = [13, 37, 61, 73, 97] := by decide

#print axioms cyclotomic_field_degree_totient_and_galois_units
#print axioms middle_fields_match_subgroups_of_units
#print axioms cyclotomic_poly_minpoly_degree_totient
