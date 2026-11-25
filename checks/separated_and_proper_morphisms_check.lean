-- Separated and proper: a map from a Noetherian scheme is separated exactly when every curve on every little disc has at most one limit, and proper (when of finite type) exactly when it has exactly one; projective space is proper and the affine line is not.
import Mathlib.AlgebraicGeometry.ValuativeCriterion
import Mathlib.AlgebraicGeometry.ProjectiveSpectrum.Proper
import Mathlib.AlgebraicGeometry.Noetherian
import Mathlib.RingTheory.MvPolynomial.Homogeneous
import Mathlib.Algebra.Polynomial.Expand
import Mathlib.Data.ZMod.Basic

universe u

open CategoryTheory AlgebraicGeometry

/-- **The limit test (valuative criteria).** Let `f : X → S` be a map of schemes with `X`
Noetherian. A curve on a punctured disc is a map `Spec K → X`, where `K` is the fraction
field of a valuation ring `R` (the disc), and a limit is an extension of it to the whole disc
`Spec R → X` that agrees with the given map `Spec R → S`. Then `f` is separated exactly when
every such curve has at most one limit. If `f` is also of finite type, `f` is proper exactly
when every such curve has exactly one limit. (Mathlib tests every valuation ring, the form the
card gives for the general case; the card's discrete-valuation-ring shortcut is not used.) -/
theorem separated_iff_at_most_one_limit_and_proper_iff_exactly_one_limit
    {X S : Scheme.{u}} (f : X ⟶ S) [IsNoetherian X] [QuasiCompact f]
    [LocallyOfFiniteType f] :
    (IsSeparated f ↔ ValuativeCriterion.Uniqueness f) ∧
      (IsProper f ↔ ValuativeCriterion f) := by
  have : QuasiSeparated f := inferInstance
  refine ⟨⟨fun _ ↦ IsSeparated.valuativeCriterion f,
    fun h ↦ IsSeparated.of_valuativeCriterion f h⟩, ⟨fun hp ↦ ?_,
    fun h ↦ IsProper.of_valuativeCriterion f h⟩⟩
  rw [IsProper.eq_valuativeCriterion] at hp
  exact hp.1.1.1

attribute [local instance] MvPolynomial.gradedAlgebra

/-- **Projective space is proper.** Projective space `P^n` over a field `k`, built as `Proj` of
the polynomial ring `k[x_0, …, x_n]` graded by degree, is proper over the spectrum of the
degree-0 part (the constants `k`): nothing escapes to infinity. -/
theorem projective_space_is_proper (k : Type u) [Field k] (n : ℕ) :
    IsProper (Proj.toSpecZero (MvPolynomial.homogeneousSubmodule (Fin (n + 1)) k)) := by
  have : IsScalarTower k (MvPolynomial.homogeneousSubmodule (Fin (n + 1)) k 0)
      (MvPolynomial (Fin (n + 1)) k) :=
    IsScalarTower.of_algebraMap_eq (R := k)
      (S := MvPolynomial.homogeneousSubmodule (Fin (n + 1)) k 0) (fun _ ↦ rfl)
  have : Algebra.FiniteType (MvPolynomial.homogeneousSubmodule (Fin (n + 1)) k 0)
      (MvPolynomial (Fin (n + 1)) k) := Algebra.FiniteType.of_restrictScalars_finiteType k _ _
  infer_instance

/-- **The affine line is not proper.** The affine line `A^1 = Spec k[x]` over a field `k`,
with its map to the point `Spec k` (from the inclusion of constants `k → k[x]`), is not proper:
after base change to the x-line the hyperbola `xy = 1` has a shadow that is not closed. -/
theorem affine_line_is_not_proper (k : Type u) [Field k] :
    ¬ IsProper (Spec.map (CommRingCat.ofHom (Polynomial.C : k →+* Polynomial k))) := by
  intro h
  have : IsFinite (Spec.map (CommRingCat.ofHom (Polynomial.C : k →+* Polynomial k))) :=
    IsFinite.iff_isProper_and_isAffineHom.mpr ⟨h, inferInstance⟩
  rw [IsFinite.SpecMap_iff, CommRingCat.hom_ofHom, ← Polynomial.algebraMap_eq,
    RingHom.finite_algebraMap] at this
  exact Polynomial.not_finite (R := k) this

open Polynomial in
-- The even and odd split for x ↦ x²: x⁵ + 3x² − x + 2 = (3u + 2) + x(u² − 1) with u = x².
-- `expand ℤ 2` substitutes x² for the variable.
example : (X ^ 5 + 3 * X ^ 2 - X + 2 : ℤ[X]) =
    expand ℤ 2 (3 * X + 2) + X * expand ℤ 2 (X ^ 2 - 1) := by
  simp only [map_add, map_sub, map_mul, map_pow, map_ofNat, expand_X, map_one]
  ring

-- Over F_7 the hyperbola xy = 1 casts a shadow of 6 of the 7 points of the x-line.
example : ((Finset.univ : Finset (ZMod 7)).filter (fun x => ∃ y : ZMod 7, x * y = 1)).card = 6 := by
  decide

-- Its closure x·y₀ = y₁ in A^1 × P^1, with (y₀ : y₁) not (0 : 0), casts a shadow of all 7.
example : ((Finset.univ : Finset (ZMod 7)).filter
    (fun x => ∃ y₀ y₁ : ZMod 7, (y₀ ≠ 0 ∨ y₁ ≠ 0) ∧ x * y₀ = y₁)).card = 7 := by
  decide

-- On the doubled line, the diagonal in chart (A, B) holds the 6 points of x = y with x ≠ 0.
example : ((Finset.univ : Finset (ZMod 7)).filter (fun x => x ≠ 0)).card = 6 := by
  decide

-- Fibres of x ↦ x² over F_7: the number of x with x² = c, for c = 0, …, 6.
example : (List.range 7).map (fun c => ((Finset.univ : Finset (ZMod 7)).filter
    (fun x => x ^ 2 = (c : ZMod 7))).card) = [1, 2, 2, 0, 2, 0, 0] := by
  decide

#print axioms separated_iff_at_most_one_limit_and_proper_iff_exactly_one_limit
#print axioms projective_space_is_proper
#print axioms affine_line_is_not_proper
