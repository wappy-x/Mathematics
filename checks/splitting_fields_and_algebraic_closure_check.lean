-- Splitting fields: every polynomial over a field has a splitting field, built one root at a time by remainder arithmetic, of degree at most n! and unique up to relabelling, with at most [L:K] relabellings and exactly that many when the roots are distinct; for x^4 - 2 over the fractions the degree is 8.
import Mathlib.FieldTheory.SplittingField.Construction
import Mathlib.FieldTheory.Galois.Basic
import Mathlib.FieldTheory.SeparableDegree
import Mathlib.RingTheory.AdjoinRoot
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.Ring
import Mathlib.FieldTheory.SeparableClosure
import Mathlib.RingTheory.Polynomial.Eisenstein.Basic
import Mathlib.RingTheory.Polynomial.GaussLemma
import Mathlib.Data.Nat.Prime.Int
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Complex.Polynomial.Basic

open Polynomial
open scoped IntermediateField

universe u v w

theorem splittingFieldAux_finrank_le_factorial (n : ℕ) :
    ∀ {K : Type u} [Field K] (f : K[X]), f.natDegree = n →
      Module.finrank K (SplittingFieldAux n f) ≤ n.factorial := by
  induction n with
  | zero =>
    intro K _ f _
    show Module.finrank K K ≤ 1
    simp
  | succ n ih =>
    intro K _ f hf
    have hf0 : f ≠ 0 := by rintro rfl; simp at hf
    have hnd : f.natDegree ≠ 0 := by omega
    have := Polynomial.fact_irreducible_factor f
    have h1 := ih f.removeFactor (natDegree_removeFactor' hf)
    have h2 : Module.finrank K (AdjoinRoot f.factor) ≤ n + 1 := by
      rw [(AdjoinRoot.powerBasis (irreducible_factor f).ne_zero).finrank, AdjoinRoot.powerBasis_dim,
        ← hf]
      exact natDegree_le_of_dvd (factor_dvd_of_natDegree_ne_zero hnd) hf0
    have h3 := Module.finrank_mul_finrank K (AdjoinRoot f.factor)
      (SplittingFieldAux n f.removeFactor)
    change Module.finrank K (SplittingFieldAux n f.removeFactor) ≤ (n+1).factorial
    rw [← h3, Nat.factorial_succ]
    exact Nat.mul_le_mul h2 h1

#print axioms splittingFieldAux_finrank_le_factorial

theorem irreducible_X_pow_four_sub_two_rat : Irreducible (X ^ 4 - C 2 : ℚ[X]) := by
  have hm : (X ^ 4 - C 2 : ℤ[X]).Monic := monic_X_pow_sub_C 2 (by norm_num)
  have hnd : (X ^ 4 - C 2 : ℤ[X]).natDegree = 4 := natDegree_X_pow_sub_C (2 : ℤ)
  have he : (X ^ 4 - C 2 : ℤ[X]).IsEisensteinAt (Ideal.span {(2 : ℤ)}) := by
    refine ⟨?_, ?_, ?_⟩
    · rw [hm.leadingCoeff, Ideal.mem_span_singleton]; norm_num
    · intro n hn
      rw [hnd] at hn
      rw [Ideal.mem_span_singleton]
      interval_cases n <;> simp
    · rw [Ideal.span_singleton_pow, Ideal.mem_span_singleton]
      simp
  have hi : Irreducible (X ^ 4 - C 2 : ℤ[X]) :=
    he.irreducible ((Ideal.span_singleton_prime (by norm_num)).mpr (Nat.prime_iff_prime_int.mp Nat.prime_two))
      hm.isPrimitive (by rw [hnd]; norm_num)
  have := (IsPrimitive.Int.irreducible_iff_irreducible_map_cast hm.isPrimitive).mp hi
  rw [show (C 2 : ℚ[X]) = 2 from map_ofNat C 2]
  simpa using this

#print axioms irreducible_X_pow_four_sub_two_rat

/-- Splitting fields exist, are built by Kronecker's step, have degree at most n!, and are unique.
For any polynomial f over any field K:
(1) Kronecker's step: for an irreducible g over K, remainder arithmetic modulo g, K[x]/(g), is a
field; the class of x is a root of g; its degree over K is the degree of g; and for any root r
of g in any field, K(r) is the same field as K[x]/(g) under new names;
(2) a splitting field L of f over K exists, with degree [L:K] at most n!, where n is the degree of f;
(3) any two splitting fields of f over K are matched by a relabelling that fixes every element of K. -/
theorem splitting_field_exists_degree_le_factorial_and_unique {K : Type u} [Field K] (f : K[X]) :
    (∀ g : K[X], Irreducible g →
      IsField (AdjoinRoot g) ∧ aeval (AdjoinRoot.root g) g = 0 ∧
      Module.finrank K (AdjoinRoot g) = g.natDegree ∧
      ∀ (E : Type w) [Field E] [Algebra K E] (r : E), aeval r g = 0 →
        Nonempty (K⟮r⟯ ≃ₐ[K] AdjoinRoot g)) ∧
    (∃ (L : Type u) (_ : Field L) (_ : Algebra K L),
      IsSplittingField K L f ∧ Module.finrank K L ≤ f.natDegree.factorial) ∧
    (∀ (L : Type v) (M : Type w) [Field L] [Field M] [Algebra K L] [Algebra K M],
      IsSplittingField K L f → IsSplittingField K M f → Nonempty (L ≃ₐ[K] M)) := by
  refine ⟨fun g hg => ?_, ⟨f.SplittingField, inferInstance, inferInstance, inferInstance, ?_⟩,
    fun L M _ _ _ _ hL hM => ⟨(IsSplittingField.algEquiv L f).trans
      (IsSplittingField.algEquiv M f).symm⟩⟩
  · have := Fact.mk hg
    refine ⟨Field.toIsField _, by rw [AdjoinRoot.aeval_eq, AdjoinRoot.mk_self], ?_, ?_⟩
    · rw [(AdjoinRoot.powerBasis hg.ne_zero).finrank, AdjoinRoot.powerBasis_dim]
    · intro E _ _ r hr
      have hi : IsIntegral K r := (show IsAlgebraic K r from ⟨g, hg.ne_zero, hr⟩).isIntegral
      have ha : Associated (minpoly K r) g :=
        (minpoly.irreducible hi).associated_of_dvd hg (minpoly.dvd K r hr)
      exact ⟨(IntermediateField.adjoinRootEquivAdjoin K hi).symm.trans
        (AdjoinRoot.algEquivOfAssociated K _ _ ha)⟩
  · rw [(SplittingField.algEquivSplittingFieldAux f).toLinearEquiv.finrank_eq]
    exact splittingFieldAux_finrank_le_factorial _ f rfl

/-- Counting the relabellings: if L and M are both splitting fields of f over K, the number of
relabellings L → M fixing K is at most the degree [L:K], and equals [L:K] when every irreducible
factor of f has distinct roots (is separable). -/
theorem card_relabellings_le_degree_and_eq_of_distinct_roots {K : Type u} {L : Type v}
    {M : Type w} [Field K] [Field L] [Field M] [Algebra K L] [Algebra K M] (f : K[X])
    [IsSplittingField K L f] [IsSplittingField K M f] :
    Nat.card (L ≃ₐ[K] M) ≤ Module.finrank K L ∧
    ((∀ g : K[X], Irreducible g → g ∣ f → g.Separable) →
      Nat.card (L ≃ₐ[K] M) = Module.finrank K L) := by
  have := IsSplittingField.finiteDimensional L f
  let e : L ≃ₐ[K] M := (IsSplittingField.algEquiv L f).trans (IsSplittingField.algEquiv M f).symm
  have hc : Nat.card (L ≃ₐ[K] M) = Nat.card (L ≃ₐ[K] L) := Nat.card_congr
    { toFun := fun σ => σ.trans e.symm
      invFun := fun τ => τ.trans e
      left_inv := fun σ => by ext x; simp
      right_inv := fun τ => by ext x; simp }
  rw [hc]
  refine ⟨by rw [Nat.card_eq_fintype_card]; exact AlgEquiv.card_le, fun hsep => ?_⟩
  have : Normal K L := Normal.of_isSplittingField f
  have : Algebra.IsSeparable K L := by
    rw [← separableClosure.eq_top_iff, eq_top_iff]
    have h1 : IntermediateField.adjoin K (f.rootSet L) ≤ separableClosure K L := by
      rw [IntermediateField.adjoin_le_iff]
      intro x hx
      rw [mem_rootSet] at hx
      rw [SetLike.mem_coe, mem_separableClosure_iff]
      have hi : IsIntegral K x := (show IsAlgebraic K x from ⟨f, hx.1, hx.2⟩).isIntegral
      exact hsep _ (minpoly.irreducible hi) (minpoly.dvd K x hx.2)
    refine le_trans ?_ h1
    rw [← IntermediateField.toSubalgebra_le_toSubalgebra, IntermediateField.top_toSubalgebra,
      ← IsSplittingField.adjoin_rootSet L f]
    exact IntermediateField.algebra_adjoin_le_adjoin K _
  have : IsGalois K L := ⟨⟩
  exact IsGalois.card_aut_eq_finrank K L

/-- The house example: the splitting field of x^4 - 2 over the fractions has degree 8. -/
theorem finrank_splittingField_X_pow_four_sub_two :
    Module.finrank ℚ (X ^ 4 - C 2 : ℚ[X]).SplittingField = 8 := by
  set f : ℚ[X] := X ^ 4 - C 2 with hf
  have hf0 : f ≠ 0 := (monic_X_pow_sub_C 2 (by norm_num)).ne_zero
  let E : IntermediateField ℚ ℂ := IntermediateField.adjoin ℚ (f.rootSet ℂ)
  have : IsSplittingField ℚ E f :=
    IntermediateField.adjoin_rootSet_isSplittingField (IsAlgClosed.splits _)
  rw [← (IsSplittingField.algEquiv E f).toLinearEquiv.finrank_eq]
  set a : ℝ := (2 : ℝ) ^ ((1 : ℝ) / 4) with ha
  have ha4 : a ^ 4 = 2 := by
    rw [ha, ← Real.rpow_natCast, ← Real.rpow_mul (by norm_num)]; norm_num
  set α : ℂ := (a : ℂ) with hα
  have hα4 : α ^ 4 = 2 := by rw [hα, ← Complex.ofReal_pow, ha4]; norm_num
  have hα0 : α ≠ 0 := by rintro h; rw [h] at hα4; norm_num at hα4
  have hroot : ∀ r : ℂ, r ∈ f.rootSet ℂ ↔ r ^ 4 = 2 := by
    intro r
    rw [mem_rootSet_of_ne hf0, hf]
    simp [sub_eq_zero]
  have hE : E = ℚ⟮α, Complex.I⟯ := by
    apply le_antisymm
    · rw [IntermediateField.adjoin_le_iff]
      intro r hr
      rw [hroot] at hr
      have hIα : α ∈ ℚ⟮α, Complex.I⟯ := IntermediateField.subset_adjoin _ _ (by simp)
      have hII : Complex.I ∈ ℚ⟮α, Complex.I⟯ := IntermediateField.subset_adjoin _ _ (by simp)
      have hprod : (r - α) * (r + α) * (r - Complex.I * α) * (r + Complex.I * α) = 0 := by
        linear_combination hr - hα4 - (r ^ 2 - α ^ 2) * α ^ 2 * Complex.I_sq
      rcases mul_eq_zero.mp hprod with h | h
      · rcases mul_eq_zero.mp h with h | h
        · rcases mul_eq_zero.mp h with h | h
          · rw [sub_eq_zero.mp h]; exact hIα
          · rw [eq_neg_of_add_eq_zero_left h]; exact neg_mem hIα
        · rw [sub_eq_zero.mp h]; exact mul_mem hII hIα
      · rw [eq_neg_of_add_eq_zero_left h]; exact neg_mem (mul_mem hII hIα)
    · rw [IntermediateField.adjoin_le_iff]
      have h1 : α ∈ E := IntermediateField.subset_adjoin _ _ ((hroot α).mpr hα4)
      have h2 : Complex.I * α ∈ E := IntermediateField.subset_adjoin _ _ ((hroot _).mpr (by
        rw [mul_pow, hα4]; simp [show Complex.I ^ 4 = 1 from by rw [show 4 = 2 * 2 from rfl, pow_mul]; simp]))
      intro x hx
      simp only [Set.mem_insert_iff, Set.mem_singleton_iff] at hx
      rcases hx with rfl | rfl
      · exact h1
      · have : Complex.I = (Complex.I * α) / α := by field_simp
        rw [this]; exact div_mem h2 h1
  rw [hE, ← IntermediateField.adjoin_simple_adjoin_simple]
  have hmin : minpoly ℚ α = f := by
    refine (minpoly.eq_of_irreducible_of_monic irreducible_X_pow_four_sub_two_rat ?_
      (monic_X_pow_sub_C 2 (by norm_num))).symm
    simp [hα4]
  have hαi : IsIntegral ℚ α := by
    refine ⟨f, monic_X_pow_sub_C 2 (by norm_num), ?_⟩
    simp [hf, hα4, eval₂_sub]
  have h4 : Module.finrank ℚ ℚ⟮α⟯ = 4 := by
    rw [IntermediateField.adjoin.finrank hαi, hmin, hf, natDegree_X_pow_sub_C]
  have hreal : ∀ z ∈ ℚ⟮α⟯, z.im = 0 := by
    have hle : ℚ⟮α⟯ ≤ (Complex.ofRealAm.restrictScalars ℚ).fieldRange := by
      rw [IntermediateField.adjoin_simple_le_iff]
      exact ⟨a, rfl⟩
    intro z hz
    obtain ⟨x, rfl⟩ := hle hz
    simp
  have hIi : IsIntegral ℚ⟮α⟯ Complex.I := by
    refine ⟨X ^ 2 + 1, by monicity!, ?_⟩
    simp
  have h2 : Module.finrank ℚ⟮α⟯ ℚ⟮α⟯⟮Complex.I⟯ = 2 := by
    have hle : Module.finrank ℚ⟮α⟯ ℚ⟮α⟯⟮Complex.I⟯ ≤ 2 := by
      rw [IntermediateField.adjoin.finrank hIi]
      have hp0 : (X ^ 2 + 1 : (ℚ⟮α⟯)[X]) ≠ 0 := (by monicity! : (X ^ 2 + 1 : (ℚ⟮α⟯)[X]).Monic).ne_zero
      have := minpoly.degree_le_of_ne_zero (A := ℚ⟮α⟯) (x := Complex.I) hp0 (by simp)
      have h22 : (X ^ 2 + 1 : (ℚ⟮α⟯)[X]).natDegree = 2 := by compute_degree!
      rw [← h22]
      exact natDegree_le_natDegree this
    have hne : Module.finrank ℚ⟮α⟯ ℚ⟮α⟯⟮Complex.I⟯ ≠ 1 := by
      rw [Ne, IntermediateField.finrank_eq_one_iff, IntermediateField.adjoin_simple_eq_bot_iff,
        IntermediateField.mem_bot]
      rintro ⟨y, hy⟩
      have := hreal y y.2
      rw [show (y : ℂ) = Complex.I from hy] at this
      simp at this
    have := IntermediateField.adjoin.finiteDimensional hIi
    have hpos : 0 < Module.finrank ℚ⟮α⟯ ℚ⟮α⟯⟮Complex.I⟯ := Module.finrank_pos
    omega
  have key := Module.finrank_mul_finrank ℚ ℚ⟮α⟯ ℚ⟮α⟯⟮Complex.I⟯
  rw [h4, h2] at key
  exact key.symm

-- The tower: [L:Q] = 4 × 2 = 8, well under the bound 4! = 24; relabellings 4 × 2 = 8.
example : 4 * 2 = 8 ∧ Nat.factorial 4 = 24 ∧ 4 * 2 ≤ Nat.factorial 4 := by decide

-- x^4 - 2 has no root modulo 5.
example : ∀ x : ZMod 5, x ^ 4 - 2 ≠ 0 := by decide

-- x^4 - 2 has no factorisation into two monic quadratics modulo 5:
-- (x^2 + a x + b)(x^2 + c x + d) = x^4 - 2 would need these four coefficient equations.
example : ∀ a b c d : ZMod 5,
    ¬ (a + c = 0 ∧ b + d + a * c = 0 ∧ a * d + b * c = 0 ∧ b * d = -2) := by decide

-- Kronecker's step on the reducible x^4 - 1 gives zero divisors: (x - 1)(x^3 + x^2 + x + 1) is x^4 - 1.
example : (X - 1) * (X ^ 3 + X ^ 2 + X + 1) = (X ^ 4 - 1 : ℤ[X]) := by ring

#print axioms splitting_field_exists_degree_le_factorial_and_unique
#print axioms card_relabellings_le_degree_and_eq_of_distinct_roots
#print axioms finrank_splittingField_X_pow_four_sub_two
