-- Sheaf cohomology: every short exact sequence of sheaves gives a long exact sequence of sheaf cohomology groups, a cohomology group trapped between two zeros is carried one-to-one and onto by the connecting map, and the plane's twist minus d has (d - 1)(d - 2)/2 top-degree monomials.
import Mathlib.CategoryTheory.Sites.SheafCohomology.ExactSequences
import Mathlib.Data.Set.Card
import Mathlib.Data.Int.Interval
import Mathlib.Tactic.NormNum

open CategoryTheory

universe w' w v u

section Cohomology

variable {C : Type u} [Category.{v} C] {J : GrothendieckTopology C}
  [HasSheafify J AddCommGrpCat.{w}] [HasExt.{w'} (Sheaf J AddCommGrpCat.{w})]

/-- The long exact sequence: for a short exact sequence of sheaves 0 → A → B → C → 0
(exact near every point, not just on global sections), the cohomology groups
Hⁿ(A) → Hⁿ(B) → Hⁿ(C) → Hⁿ⁺¹(A) → Hⁿ⁺¹(B) → Hⁿ⁺¹(C), linked by the connecting map δ,
form an exact chain in every degree n. Here Hⁿ is Mathlib's sheaf cohomology, defined
as the derived functors Extⁿ from the constant sheaf (the card's Hⁱ = Extⁱ(𝒪, 𝓕)); the
hypothesis `HasExt` is Mathlib's form of the card's "enough injectives" condition that
makes these derived functors exist. -/
theorem long_exact_sequence_of_short_exact_sequence_of_sheaves
    {S : ShortComplex (Sheaf J AddCommGrpCat.{w})} (hS : S.ShortExact) (n : ℕ) :
    (Sheaf.H.longSequence hS n (n + 1) rfl).Exact :=
  Sheaf.H.longSequence_exact hS n (n + 1) rfl

/-- Trapped between two zeros: in the long exact sequence of a short exact sequence of
sheaves 0 → A → B → C → 0, if Hⁿ(B) = 0 and Hⁿ⁺¹(B) = 0, then the connecting map
δ : Hⁿ(C) → Hⁿ⁺¹(A) is one-to-one and onto. This is the card's genus step with
A = 𝒪(−d), B = 𝒪, C = 𝒪_C and n = 1: H¹(𝒪_C) ≅ H²(𝒪(−d)). -/
theorem connecting_map_bijective_of_trapped_between_zeros
    {S : ShortComplex (Sheaf J AddCommGrpCat.{w})} (hS : S.ShortExact) (n : ℕ)
    (h₀ : Subsingleton (Sheaf.H S.X₂ n)) (h₁ : Subsingleton (Sheaf.H S.X₂ (n + 1))) :
    Function.Bijective (Sheaf.H.δ hS n (n + 1) rfl) := by
  constructor
  · rw [injective_iff_map_eq_zero]
    intro x hx
    obtain ⟨y, rfl⟩ := Sheaf.H.longSequence_exact₃ hS x rfl hx
    rw [Subsingleton.elim y 0, map_zero]
  · intro x
    exact Sheaf.H.longSequence_exact₁ hS x (Subsingleton.elim _ _) rfl

end Cohomology

theorem monomial_set_finite (d : ℕ) :
    {e : ℤ × ℤ × ℤ | e.1 ≤ -1 ∧ e.2.1 ≤ -1 ∧ e.2.2 ≤ -1 ∧ e.1 + e.2.1 + e.2.2 = -(d : ℤ)}.Finite := by
  refine ((Set.finite_Icc (-(d : ℤ)) (-1)).prod
    ((Set.finite_Icc (-(d : ℤ)) (-1)).prod (Set.finite_Icc (-(d : ℤ)) (-1)))).subset ?_
  rintro ⟨a, b, c⟩ ⟨ha, hb, hc, hs⟩
  simp only [Set.mem_prod, Set.mem_Icc] at *
  omega

theorem monomial_count_succ (d : ℕ) :
    {e : ℤ × ℤ × ℤ | e.1 ≤ -1 ∧ e.2.1 ≤ -1 ∧ e.2.2 ≤ -1 ∧ e.1 + e.2.1 + e.2.2 = -((d + 1 : ℕ) : ℤ)}.ncard
      = {e : ℤ × ℤ × ℤ | e.1 ≤ -1 ∧ e.2.1 ≤ -1 ∧ e.2.2 ≤ -1 ∧ e.1 + e.2.1 + e.2.2 = -(d : ℤ)}.ncard
        + (d - 1) := by
  set S := {e : ℤ × ℤ × ℤ | e.1 ≤ -1 ∧ e.2.1 ≤ -1 ∧ e.2.2 ≤ -1 ∧ e.1 + e.2.1 + e.2.2 = -(d : ℤ)}
  have hsplit : {e : ℤ × ℤ × ℤ | e.1 ≤ -1 ∧ e.2.1 ≤ -1 ∧ e.2.2 ≤ -1 ∧
      e.1 + e.2.1 + e.2.2 = -((d + 1 : ℕ) : ℤ)}
      = (fun e : ℤ × ℤ × ℤ => (e.1 - 1, e.2)) '' S
        ∪ (fun b : ℤ => ((-1 : ℤ), b, -(d : ℤ) - b)) '' Set.Icc (1 - (d : ℤ)) (-1) := by
    ext ⟨a, b, c⟩
    simp only [Set.mem_ofPred_eq, Set.mem_union, Set.mem_image, Set.mem_Icc, Prod.mk.injEq, S,
      Prod.exists]
    push_cast
    constructor
    · rintro ⟨ha, hb, hc, hs⟩
      by_cases h : a = -1
      · right; exact ⟨⟨by omega, hb⟩, h.symm, rfl, by omega⟩
      · left; exact ⟨a + 1, ⟨by omega, hb, hc, by omega⟩, by omega, rfl, rfl⟩
    · rintro (⟨a', ⟨h1, h2, h3, h4⟩, rfl, -, -⟩ | ⟨⟨h1, h2⟩, rfl, -, rfl⟩)
      · omega
      · omega
  have hinj1 : Function.Injective (fun e : ℤ × ℤ × ℤ => (e.1 - 1, e.2)) := by
    rintro ⟨a, b⟩ ⟨a', b'⟩ h
    simp only [Prod.mk.injEq] at h
    obtain ⟨h1, h2⟩ := h
    simp [h2]; omega
  have hinj2 : Function.Injective (fun b : ℤ => ((-1 : ℤ), b, -(d : ℤ) - b)) := by
    intro b b' h
    simp only [Prod.mk.injEq] at h
    exact h.2.1
  rw [hsplit, Set.ncard_union_eq _ ((monomial_set_finite d).image _) ((Set.finite_Icc _ _).image _),
    Set.ncard_image_of_injective _ hinj1,
    Set.ncard_image_of_injective _ hinj2, ← Finset.coe_Icc, Set.ncard_coe_finset, Int.card_Icc]
  · congr 1; omega
  · rw [Set.disjoint_left]
    rintro _ ⟨⟨a, b, c⟩, ⟨ha, -, -, -⟩, rfl⟩ ⟨b', -, h⟩
    simp only [Prod.mk.injEq] at h
    omega

#print axioms monomial_set_finite
#print axioms monomial_count_succ

/-- The count behind h²(ℙ², 𝒪(−d)): the Laurent monomials x^a y^b z^c with every exponent
at most −1 and a + b + c = −d number exactly (d − 1)(d − 2)/2. For the quartic (d = 4)
these are x⁻²y⁻¹z⁻¹, x⁻¹y⁻²z⁻¹ and x⁻¹y⁻¹z⁻², three, the Klein quartic's genus. -/
theorem h2_twist_minus_d_monomial_count (d : ℕ) :
    {e : ℤ × ℤ × ℤ | e.1 ≤ -1 ∧ e.2.1 ≤ -1 ∧ e.2.2 ≤ -1 ∧ e.1 + e.2.1 + e.2.2 = -(d : ℤ)}.ncard
      = (d - 1) * (d - 2) / 2 := by
  induction d with
  | zero =>
    rw [show {e : ℤ × ℤ × ℤ | e.1 ≤ -1 ∧ e.2.1 ≤ -1 ∧ e.2.2 ≤ -1 ∧
        e.1 + e.2.1 + e.2.2 = -((0 : ℕ) : ℤ)} = ∅ from ?_, Set.ncard_empty]
    ext ⟨a, b, c⟩
    simp only [Set.mem_ofPred_eq, Set.mem_empty_iff_false, iff_false]
    omega
  | succ k ih =>
    rw [monomial_count_succ, ih]
    rcases k with _ | k
    · rfl
    · simp only [Nat.add_sub_cancel]
      rcases k with _ | k
      · rfl
      · have : (k + 1 + 1) * (k + 1) = (k + 1) * k + (k + 1) * 2 := by ring
        rw [show k + 1 + 1 + 1 - 2 = k + 1 by omega, this,
          Nat.add_mul_div_right _ _ (by norm_num), show k + 1 + 1 - 2 = k by omega]

-- The card's H² monomials of 𝒪(−d), counted in the box of exponents from −d to −1
-- (no exponent can be below −d + 2): 3 for the quartic, 1 for the cubic.
example : ((Finset.Icc (-4 : ℤ) (-1) ×ˢ Finset.Icc (-4 : ℤ) (-1) ×ˢ Finset.Icc (-4 : ℤ) (-1)).filter
    (fun e : ℤ × ℤ × ℤ => e.1 + e.2.1 + e.2.2 = -4)).card = 3 := by decide
example : ((Finset.Icc (-3 : ℤ) (-1) ×ˢ Finset.Icc (-3 : ℤ) (-1) ×ˢ Finset.Icc (-3 : ℤ) (-1)).filter
    (fun e : ℤ × ℤ × ℤ => e.1 + e.2.1 + e.2.2 = -3)).card = 1 := by decide

-- The genus by degree, d = 1..6: 0, 0, 1, 3, 6, 10.
example : [1, 2, 3, 4, 5, 6].map (fun d : ℕ => (d - 1) * (d - 2) / 2) = [0, 0, 1, 3, 6, 10] := by
  decide

-- h²(𝒪(k)) = C(−k − 1, 2) for k = −6..−3 and h⁰(𝒪(k)) = C(k + 2, 2) for k = 0..2.
example : [Nat.choose 5 2, Nat.choose 4 2, Nat.choose 3 2, Nat.choose 2 2] = [10, 6, 3, 1] := by
  decide
example : [Nat.choose 2 2, Nat.choose 3 2, Nat.choose 4 2] = [1, 3, 6] := by decide

-- The quartic's Euler characteristic: χ(𝒪_C) = h⁰ − h¹ = 1 − 3 = −2 = HP(0) for HP(n) = 4n − 2.
example : (1 : ℤ) - 3 = 4 * 0 - 2 := by norm_num

#print axioms long_exact_sequence_of_short_exact_sequence_of_sheaves
#print axioms connecting_map_bijective_of_trapped_between_zeros
#print axioms h2_twist_minus_d_monomial_count
