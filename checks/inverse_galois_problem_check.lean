-- The inverse Galois problem: every finite abelian group is the Galois group of some finite Galois extension of the rationals, found inside a field of roots of 1, using infinitely many primes leaving remainder 1 on division by n.
import Mathlib.NumberTheory.Cyclotomic.Gal
import Mathlib.NumberTheory.PrimesCongruentOne
import Mathlib.RingTheory.Polynomial.Cyclotomic.Roots
import Mathlib.FieldTheory.Galois.Basic
import Mathlib.Algebra.Group.Pi.Units
import Mathlib.GroupTheory.SpecificGroups.Alternating
import Mathlib.Tactic.NormNum.Prime

open Polynomial

/-- The field of m-th roots of 1 over ℚ is a cyclotomic extension (Mathlib's instance, made
findable for the statement below). -/
local instance (m : ℕ) [NeZero m] : IsCyclotomicExtension {m} ℚ (CyclotomicField m ℚ) :=
  CyclotomicField.isCyclotomicExtension m ℚ

/-- Helper: the fixed field of the image of the kernel is Galois over ℚ with group the
quotient, and so with group G (the same claim as the second theorem below, stated first so
the first theorem can use it). -/
theorem fixed_field_in_cyclotomic_field_aux
    (m : ℕ) [NeZero m] {G : Type} [Group G] (f : (ZMod m)ˣ →* G)
    (hf : Function.Surjective f) :
    let σ : (ZMod m)ˣ ≃* Gal(CyclotomicField m ℚ/ℚ) :=
      (IsCyclotomicExtension.autEquivPow (n := m) (K := ℚ) (CyclotomicField m ℚ)
        (cyclotomic.irreducible_rat (NeZero.pos m))).symm
    let K := IntermediateField.fixedField (f.ker.map σ.toMonoidHom)
    IsGalois ℚ K ∧ Nonempty (Gal(K/ℚ) ≃* (ZMod m)ˣ ⧸ f.ker) ∧ Nonempty (Gal(K/ℚ) ≃* G) := by
  intro σ K
  have : FiniteDimensional ℚ (CyclotomicField m ℚ) :=
    IsCyclotomicExtension.finiteDimensional {m} ℚ _
  have : IsGalois ℚ (CyclotomicField m ℚ) := IsCyclotomicExtension.isGalois {m} ℚ _
  have hN : (f.ker.map σ.toMonoidHom).Normal := (MonoidHom.normal_ker f).map _ σ.surjective
  have hmap : (f.ker.map σ.toMonoidHom).map σ.symm.toMonoidHom = f.ker := by
    rw [Subgroup.map_map]
    ext x
    simp
  have e1 : Gal(K/ℚ) ≃* (ZMod m)ˣ ⧸ f.ker :=
    (IsGalois.normalAutEquivQuotient (f.ker.map σ.toMonoidHom)).symm.trans
      (QuotientGroup.congr _ _ σ.symm hmap)
  exact ⟨IsGalois.of_fixedField_normal_subgroup _, ⟨e1⟩,
    ⟨e1.trans (QuotientGroup.quotientKerEquivOfSurjective f hf)⟩⟩

#print axioms fixed_field_in_cyclotomic_field_aux

/-- The abelian case of the inverse Galois problem: for every finite abelian group G there is a
field K, of finite degree over the rationals and Galois over them (it holds every root of its
polynomial), whose group of symmetries Gal(K/ℚ) is the same group as G up to renaming. -/
theorem every_finite_abelian_group_is_a_galois_group_over_rat
    (G : Type) [CommGroup G] [Finite G] :
    ∃ (K : Type) (_ : Field K) (_ : Algebra ℚ K),
      FiniteDimensional ℚ K ∧ IsGalois ℚ K ∧ Nonempty (Gal(K/ℚ) ≃* G) := by
  classical
  have : Fintype G := Fintype.ofFinite G
  have hn : Fintype.card G ≠ 0 := Fintype.card_ne_zero
  have hinf := Nat.infinite_setOfPred_prime_modEq_one hn
  let emb : G ↪ {p : ℕ | p.Prime ∧ p ≡ 1 [MOD Fintype.card G]} :=
    (Fintype.equivFin G).toEmbedding.trans (Fin.valEmbedding.trans hinf.natEmbedding)
  let p : G → ℕ := fun g => (emb g : ℕ)
  have hp : ∀ g, (p g).Prime ∧ p g ≡ 1 [MOD Fintype.card G] := fun g => (emb g).2
  have hpinj : Function.Injective p := Subtype.val_injective.comp emb.injective
  have hcop : Pairwise (Function.onFun Nat.Coprime p) := fun a b hab =>
    (Nat.coprime_primes (hp a).1 (hp b).1).2 (hpinj.ne hab)
  have hm : NeZero (∏ g, p g) :=
    ⟨Finset.prod_ne_zero_iff.2 fun g _ => (hp g).1.ne_zero⟩
  let e : (ZMod (∏ g, p g))ˣ ≃* Π g, (ZMod (p g))ˣ :=
    (Units.mapEquiv (ZMod.prodEquivPi p hcop).toMulEquiv).trans MulEquiv.piUnits
  have hφ : ∀ g : G, ∃ φ : (ZMod (p g))ˣ →* G, g ∈ φ.range := by
    intro g
    have : Fact (p g).Prime := ⟨(hp g).1⟩
    obtain ⟨z, hz⟩ := IsCyclic.exists_generator (α := (ZMod (p g))ˣ)
    have hdvd : orderOf g ∣ orderOf z := by
      rw [orderOf_eq_card_of_forall_mem_zpowers hz, Nat.card_eq_fintype_card, ZMod.card_units]
      exact (orderOf_dvd_card).trans
        ((Nat.modEq_iff_dvd' (hp g).1.one_lt.le).1 (hp g).2.symm)
    exact ⟨monoidHomOfForallMemZpowers hz hdvd, z, monoidHomOfForallMemZpowers_apply_gen hz hdvd⟩
  choose φ hφ using hφ
  let F : (Π g, (ZMod (p g))ˣ) →* G :=
    { toFun := fun x => ∏ g, φ g (x g)
      map_one' := by simp
      map_mul' := fun x y => by simp [Finset.prod_mul_distrib] }
  have hF : Function.Surjective F := by
    intro y
    obtain ⟨z, hz⟩ := hφ y
    refine ⟨Pi.mulSingle (M := fun g => (ZMod (p g))ˣ) y z, ?_⟩
    change ∏ g, φ g (Pi.mulSingle (M := fun g => (ZMod (p g))ˣ) y z g) = y
    rw [Fintype.prod_eq_single y (fun g hg => by simp [Pi.mulSingle_eq_of_ne hg])]
    simpa using hz
  have hf : Function.Surjective (F.comp e.toMonoidHom) := hF.comp e.surjective
  obtain ⟨hgal, -, ⟨iso⟩⟩ :=
    fixed_field_in_cyclotomic_field_aux _ (F.comp e.toMonoidHom) hf
  have : FiniteDimensional ℚ (CyclotomicField (∏ g, p g) ℚ) :=
    IsCyclotomicExtension.finiteDimensional {∏ g, p g} ℚ _
  exact ⟨_, inferInstance, inferInstance, inferInstance, hgal, ⟨iso⟩⟩

/-- The card's one-line formula: if the invertible remainders mod m map onto a group G, with
kernel H, then the numbers in the field of m-th roots of 1 that H leaves fixed form a field
that is Galois over ℚ, with group (ℤ mod m)ˣ / H, and so with group G. Here a remainder k acts
as the symmetry sending ζ_m to ζ_m^k. -/
theorem galois_group_of_fixed_field_in_cyclotomic_field
    (m : ℕ) [NeZero m] {G : Type} [Group G] (f : (ZMod m)ˣ →* G)
    (hf : Function.Surjective f) :
    let σ : (ZMod m)ˣ ≃* Gal(CyclotomicField m ℚ/ℚ) :=
      (IsCyclotomicExtension.autEquivPow (n := m) (K := ℚ) (CyclotomicField m ℚ)
        (cyclotomic.irreducible_rat (NeZero.pos m))).symm
    let K := IntermediateField.fixedField (f.ker.map σ.toMonoidHom)
    IsGalois ℚ K ∧ Nonempty (Gal(K/ℚ) ≃* (ZMod m)ˣ ⧸ f.ker) ∧ Nonempty (Gal(K/ℚ) ≃* G) := by
  exact fixed_field_in_cyclotomic_field_aux m f hf

/-- Step 2: for every whole number n ≥ 1 there are infinitely many primes p that leave
remainder 1 on division by n. -/
theorem infinitely_many_primes_one_mod (n : ℕ) (hn : n ≠ 0) :
    Set.Infinite {p : ℕ | p.Prime ∧ p ≡ 1 [MOD n]} := by
  exact Nat.infinite_setOfPred_prime_modEq_one hn

-- The cubes mod 7 are 1 and 6, so H = {1, 6} for the group of order 3 from the 7th roots of 1;
-- 6 invertible remainders divided by 2 in H gives degree 3.
example : (Finset.Icc 1 6).image (fun x => x ^ 3 % 7) = {1, 6} ∧ Nat.totient 7 / 2 = 3 := by
  decide
-- The cubes mod 13 are 1, 5, 8 and 12.
example : (Finset.Icc 1 12).image (fun x => x ^ 3 % 13) = {1, 5, 8, 12} := by decide
-- Φ_3(a) = a^2 + a + 1 gives the primes Φ_3(2) = 7 and Φ_3(3) = 13, both 1 mod 3.
example : (cyclotomic 3 ℤ).eval 2 = 7 ∧ (cyclotomic 3 ℤ).eval 3 = 13 := by
  norm_num [cyclotomic_three]
example : Nat.Prime 7 ∧ Nat.Prime 13 ∧ 7 % 3 = 1 ∧ 13 % 3 = 1 ∧ 7 * 13 = 91 := by norm_num
-- a^2 + a + 1 for a from 1 to 12 is 3, 7, 13, 21, 31, 43, 57, 73, 91, 111, 133, 157, and every
-- factor of these not divisible by 3 (the primes 7, 13, 19, 31, 37, 43, 73, 157 among them)
-- leaves remainder 1 mod 3.
example : (Finset.Icc 1 12).image (fun a => a ^ 2 + a + 1) =
      {3, 7, 13, 21, 31, 43, 57, 73, 91, 111, 133, 157} ∧
    ∀ a ∈ Finset.Icc 1 12, ∀ q ∈ Finset.Icc 1 157,
      q ∣ a ^ 2 + a + 1 → ¬ 3 ∣ q → q % 3 = 1 := by decide +kernel
-- There are 72 invertible remainders mod 91.
example : Nat.totient 91 = 72 := by decide
-- The kernel H: remainders that are a cube mod 7 and a cube mod 13; 8 members, degree 72 / 8 = 9.
example : (Finset.range 91).filter (fun k => k % 7 ∈ ({1, 6} : Finset ℕ) ∧
    k % 13 ∈ ({1, 5, 8, 12} : Finset ℕ)) = {1, 8, 27, 34, 57, 64, 83, 90} ∧ 72 / 8 = 9 := by
  decide
-- x^3 = 1 has 9 solutions mod 91 but only 3 mod 49: reusing the prime 7 breaks the quotient.
example : ((Finset.range 91).filter (fun x => x ^ 3 % 91 = 1)).card = 9 ∧
    ((Finset.range 49).filter (fun x => x ^ 3 % 49 = 1)).card = 3 := by decide
-- Mod 7, x^3 + x^2 - 2x - 1 is (x - 2)^3: the two differ by 7(x - 1)^2.
example : (X ^ 3 + X ^ 2 - 2 * X - 1 : ℤ[X]) = (X - 2) ^ 3 + 7 * (X - 1) ^ 2 := by ring
-- x^3 - 2 has exactly one root mod 5 (pattern (2, 1)), so its group holds a swap.
example : (Finset.range 5).filter (fun x => x ^ 3 % 5 = 2) = {3} := by decide
-- The two trinomials that factor as a quadratic times a cubic.
example : (X ^ 2 + X + 1) * (X ^ 3 - X ^ 2 + 1) = (X ^ 5 + X + 1 : ℤ[X]) := by ring
example : (X ^ 2 - X + 1) * (X ^ 3 + X ^ 2 - 1) = (X ^ 5 + X - 1 : ℤ[X]) := by ring
-- x^5 - x - 1 has no root mod 3; mod 2 it has none either, and splits as (x^2 + x + 1)(x^3 + x^2 + 1).
example : ∀ x : ZMod 3, x ^ 5 - x - 1 ≠ 0 := by decide
example : ∀ x : ZMod 2, x ^ 5 - x - 1 = (x ^ 2 + x + 1) * (x ^ 3 + x ^ 2 + 1) ∧ x ^ 5 - x - 1 ≠ 0 := by
  decide
-- x^5 - 5x + 12: discriminant 5^5 · 12^4 + 4^4 · (-5)^5 = 64,000,000 = 8,000^2, a square.
example : (5 : ℤ) ^ 5 * 12 ^ 4 + 4 ^ 4 * (-5) ^ 5 = 64000000 ∧ (64000000 : ℤ) = 8000 ^ 2 := by
  norm_num
-- S_5 has 120 members; A_5, the smallest group that is not solvable, has 60.
example : Fintype.card (Equiv.Perm (Fin 5)) = 120 ∧
    Fintype.card (alternatingGroup (Fin 5)) = 60 := by
  rw [Fintype.card_perm, card_alternatingGroup]; decide

#print axioms every_finite_abelian_group_is_a_galois_group_over_rat
#print axioms galois_group_of_fixed_field_in_cyclotomic_field
#print axioms infinitely_many_primes_one_mod
