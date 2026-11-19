-- Normal and separable: a finite field extension has as many automorphisms as its degree exactly when it is normal and separable.
import Mathlib.FieldTheory.Galois.Basic
import Mathlib.FieldTheory.Perfect

open Polynomial IntermediateField

/-- A finite field extension `L/K` has as many symmetries (automorphisms of `L` fixing `K`)
as its degree `[L : K]` exactly when it is normal (it holds every conjugate of its members)
and separable (no minimal polynomial has a repeated root). Drop either and symmetries go
missing. -/
theorem card_aut_eq_degree_iff_normal_and_separable
    {K L : Type*} [Field K] [Field L] [Algebra K L] [FiniteDimensional K L] :
    Nat.card (L ≃ₐ[K] L) = Module.finrank K L ↔ Normal K L ∧ Algebra.IsSeparable K L := by
  constructor
  · intro h
    have := IsGalois.of_card_aut_eq_finrank K L h
    exact ⟨inferInstance, inferInstance⟩
  · rintro ⟨hn, hs⟩
    have : IsGalois K L := ⟨⟩
    exact IsGalois.card_aut_eq_finrank K L

/-- For a field `K(α)` made by adjoining one number `α`, the symmetries of `K(α)` fixing `K`
match, one for one, the roots of the minimal polynomial `m_α` that lie inside `K(α)`. -/
theorem card_aut_adjoin_eq_roots_inside
    {K L : Type*} [Field K] [Field L] [Algebra K L] {α : L} (hα : IsIntegral K α) :
    Nat.card (K⟮α⟯ ≃ₐ[K] K⟮α⟯) = {γ : K⟮α⟯ | aeval γ (minpoly K α) = 0}.ncard := by
  have : FiniteDimensional K K⟮α⟯ := adjoin.finiteDimensional hα
  rw [Nat.card_congr (Algebra.IsAlgebraic.algEquivEquivAlgHom K K⟮α⟯).toEquiv,
    Nat.card_congr (algHomAdjoinIntegralEquiv K (K := K⟮α⟯) hα), ← Nat.card_coe_set_eq]
  apply Nat.card_congr
  apply Equiv.subtypeEquivRight
  intro γ
  rw [mem_aroots]
  simp only [Set.mem_ofPred_eq, and_iff_right_iff_imp]
  intro _
  exact minpoly.ne_zero hα

/-- In characteristic 0, or over a finite field, every irreducible polynomial is separable:
it has no repeated root, so only normality needs checking. -/
theorem irreducible_separable_of_charZero_or_finite
    {K : Type*} [Field K] (hK : CharZero K ∨ Finite K) {f : K[X]} (hf : Irreducible f) :
    f.Separable := by
  rcases hK with hK | hK
  · exact PerfectField.separable_of_irreducible hf
  · exact PerfectField.separable_of_irreducible hf

-- Discriminant -4a^3 - 27b^2 of x^3 + ax + b: x^3 - 2 gives -108, x^3 - 3x + 1 gives 81,
-- x^3 - 3x + 2 gives 0 (a repeated root).
example : -4 * (0 : ℤ) ^ 3 - 27 * (-2) ^ 2 = -108 := by norm_num
example : -4 * (-3 : ℤ) ^ 3 - 27 * 1 ^ 2 = 81 := by norm_num
example : -4 * (-3 : ℤ) ^ 3 - 27 * 2 ^ 2 = 0 := by norm_num

-- x^3 - 3x + 2 = (x - 1)^2 (x + 2): the repeated root 1.
example : ∀ x : ℤ, x ^ 3 - 3 * x + 2 = (x - 1) ^ 2 * (x + 2) := by intro x; ring

-- Degrees multiply up the tower Q ⊂ Q(α) ⊂ Q(α, ω): 3 × 2 = 6.
example : 3 * 2 = 6 := by norm_num

-- In characteristic p the middle binomial coefficients of (x - s)^p vanish: p = 2 and p = 3.
example : Nat.choose 2 1 % 2 = 0 := by decide
example : (List.range 2).map (fun k => Nat.choose 3 (k + 1) % 3) = [0, 0] := by decide

-- x^3 - 2 has exactly one root mod 5 and mod 11 (primes leaving remainder 2 on division by 3).
example : (Finset.univ.filter (fun x : ZMod 5 => x ^ 3 = 2)).card = 1 := by decide
example : (Finset.univ.filter (fun x : ZMod 11 => x ^ 3 = 2)).card = 1 := by decide

#print axioms card_aut_eq_degree_iff_normal_and_separable
#print axioms card_aut_adjoin_eq_roots_inside
#print axioms irreducible_separable_of_charZero_or_finite
