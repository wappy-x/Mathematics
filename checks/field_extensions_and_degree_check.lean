-- Field extensions: adding one root of an irreducible polynomial of degree n to a field gives an extension of degree n with basis 1, α, …, α^(n−1), degrees multiply up a tower, and so the fourth root of 2 has degree 4 over the fractions, reached in two steps of 2 through √2.
import Mathlib.FieldTheory.IntermediateField.Adjoin.Basic
import Mathlib.FieldTheory.Minpoly.Field
import Mathlib.LinearAlgebra.Dimension.Free
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.RingTheory.Polynomial.Eisenstein.Basic
import Mathlib.RingTheory.Polynomial.GaussLemma
import Mathlib.FieldTheory.IntermediateField.Algebraic
import Mathlib.RingTheory.Int.Basic

universe u

open Polynomial IntermediateField

/-- Helper: `X^n − 2` is irreducible over `ℚ` for `n ≥ 1` (Eisenstein at 2, then Gauss's lemma). -/
theorem X_pow_sub_two_irreducible_rat {n : ℕ} (hn : 0 < n) :
    Irreducible (X ^ n - C (2 : ℚ)) := by
  have hm : (X ^ n - C (2 : ℤ)).Monic := monic_X_pow_sub_C _ hn.ne'
  have hdeg : (X ^ n - C (2 : ℤ)).natDegree = n := natDegree_X_pow_sub_C _
  have hE : (X ^ n - C (2 : ℤ)).IsEisensteinAt (Ideal.span {2}) := by
    refine hm.isEisensteinAt_of_mem_of_notMem ?_ ?_ ?_
    · rw [Ne, Ideal.span_singleton_eq_top]; decide
    · intro k hk
      rw [hdeg] at hk
      rw [Ideal.mem_span_singleton, coeff_sub, coeff_X_pow, coeff_C]
      split_ifs <;> simp_all
    · rw [Ideal.span_singleton_pow, Ideal.mem_span_singleton, coeff_sub, coeff_X_pow, coeff_C]
      simp only [hn.ne, ite_false, ite_true, zero_sub]
      decide
  have h2p : Prime (2 : ℤ) := Int.prime_iff_natAbs_prime.mpr Nat.prime_two
  have hirr := hE.irreducible ((Ideal.span_singleton_prime (by norm_num)).mpr h2p)
    hm.isPrimitive (by rw [hdeg]; exact hn)
  have := (IsPrimitive.Int.irreducible_iff_irreducible_map_cast hm.isPrimitive).mp hirr
  have e : (X ^ n - C (2 : ℤ)).map (Int.castRingHom ℚ) = X ^ n - C (2 : ℚ) := by
    rw [Polynomial.map_sub, Polynomial.map_pow, map_X, map_C]
    norm_num
  rwa [e] at this

#print axioms X_pow_sub_two_irreducible_rat

/-- The degree of a simple extension. Let `α` be a root of a polynomial `f` that is irreducible
over the field `K`, and let `n` be the degree of `f`. Then the field `K(α)`, the smallest field
holding `K` and `α`, has degree `[K(α) : K] = n` over `K`, and the first `n` powers
`1, α, α², …, α^(n−1)` are a basis of it as a vector space over `K`. -/
theorem degree_adjoin_root_of_irreducible {K L : Type*} [Field K] [Field L] [Algebra K L]
    {f : K[X]} (hf : Irreducible f) {α : L} (hα : aeval α f = 0) :
    Module.finrank K K⟮α⟯ = f.natDegree ∧
      ∃ b : Module.Basis (Fin f.natDegree) K K⟮α⟯, ∀ i, (b i : L) = α ^ (i : ℕ) := by
  have hint : IsIntegral K α := (show IsAlgebraic K α from ⟨f, hf.ne_zero, hα⟩).isIntegral
  have hd : (minpoly K α).natDegree = f.natDegree := by
    rw [← minpoly.eq_of_irreducible hf hα,
      natDegree_mul_C (inv_ne_zero (leadingCoeff_ne_zero.mpr hf.ne_zero))]
  refine ⟨by rw [adjoin.finrank hint, hd], (adjoin.powerBasis hint).basis.reindex (finCongr hd),
    fun i => ?_⟩
  simp [Module.Basis.reindex_apply, PowerBasis.basis_eq_pow]
  rfl

/-- The tower law. For fields `K ⊆ L ⊆ M`, each inside the next, the degree from the bottom to
the top is the degree of the top step times the degree of the bottom step:
`[M : K] = [M : L] · [L : K]`. Degrees are dimensions (cardinals here), so if either step has
infinite degree, so does `M` over `K`. -/
theorem tower_law {K L M : Type u} [Field K] [Field L] [Field M] [Algebra K L] [Algebra L M]
    [Algebra K M] [IsScalarTower K L M] :
    Module.rank K M = Module.rank L M * Module.rank K L := by
  rw [mul_comm, rank_mul_rank]

/-- The card's house example. Let `α` be a real fourth root of 2 (the card's `α = 2^(1/4)`), so
`α² = √2`. Then `[ℚ(√2) : ℚ] = 2`, `α` has degree 2 over `ℚ(√2)`, and `[ℚ(α) : ℚ] = 2 × 2 = 4`. -/
theorem fourth_root_two_degree_four {α : ℝ} (hα : α ^ 4 = 2) :
    Module.finrank ℚ ℚ⟮α ^ 2⟯ = 2 ∧
      Module.finrank ℚ⟮α ^ 2⟯ ℚ⟮α ^ 2⟯⟮α⟯ = 2 ∧
      Module.finrank ℚ ℚ⟮α⟯ = 4 := by
  have h4 : Module.finrank ℚ ℚ⟮α⟯ = 4 := by
    have := (degree_adjoin_root_of_irreducible (X_pow_sub_two_irreducible_rat (n := 4)
      (by norm_num)) (α := α) (by simp [hα])).1
    rwa [natDegree_X_pow_sub_C] at this
  have h2 : Module.finrank ℚ ℚ⟮α ^ 2⟯ = 2 := by
    have := (degree_adjoin_root_of_irreducible (X_pow_sub_two_irreducible_rat (n := 2)
      (by norm_num)) (α := α ^ 2) (by simp [← pow_mul, hα])).1
    rwa [natDegree_X_pow_sub_C] at this
  refine ⟨h2, ?_, h4⟩
  set E := ℚ⟮α ^ 2⟯ with hEdef
  have hintQ : IsIntegral ℚ α :=
    ⟨X ^ 4 - C 2, monic_X_pow_sub_C _ (by norm_num), by simp [hα]⟩
  have hint : IsIntegral E α := hintQ.tower_top
  have hfinE : FiniteDimensional ℚ E := adjoin.finiteDimensional (hintQ.pow 2)
  have hnot : α ∉ E := by
    intro h
    have hle : ℚ⟮α⟯ ≤ E := adjoin_simple_le_iff.mpr h
    have := finrank_le_of_le_right hle
    rw [h4, h2] at this
    norm_num at this
  have hle2 : Module.finrank E E⟮α⟯ ≤ 2 := by
    rw [adjoin.finrank hint]
    have hp : (X ^ 2 - C (AdjoinSimple.gen ℚ (α ^ 2)) : E[X]) ≠ 0 :=
      X_pow_sub_C_ne_zero (by norm_num) _
    have := minpoly.degree_le_of_ne_zero E α hp (by simp)
    rw [degree_X_pow_sub_C (by norm_num)] at this
    exact natDegree_le_iff_degree_le.mpr this
  have hne1 : Module.finrank E E⟮α⟯ ≠ 1 := by
    intro h1
    rw [IntermediateField.finrank_eq_one_iff, adjoin_simple_eq_bot_iff, mem_bot] at h1
    obtain ⟨y, hy⟩ := h1
    exact hnot (hy ▸ y.2)
  have hpos : 0 < Module.finrank E E⟮α⟯ := by
    have := adjoin.finiteDimensional hint
    exact Module.finrank_pos
  omega

-- The tower over ℚ: 2 × 2 = 4, and adding i on top gives 4 × 2 = 8.
example : 2 * 2 = 4 ∧ 4 * 2 = 8 := by norm_num

-- Bottom step: no candidate 1, −1, 2, −2 of the rational root test is a root of x² − 2.
example : ∀ t ∈ ([1, -1, 2, -2] : List ℤ), t ^ 2 - 2 ≠ 0 := by decide

-- Top step: no candidate 1, −1, 1/2, −1/2 is a root of 2t⁴ + 1.
example : ∀ t ∈ ([1, -1, 1/2, -1/2] : List ℚ), 2 * t ^ 4 + 1 ≠ 0 := by norm_num

-- Eisenstein at 2 on x⁴ − 2: 2 divides 0 and −2, and 4 does not divide −2.
example : (2 : ℤ) ∣ 0 ∧ (2 : ℤ) ∣ -2 ∧ ¬ (4 : ℤ) ∣ -2 := by decide

-- The reciprocal: (1 + x)(1 − x + x² − x³) = 1 − x⁴, which is 1 − 2 = −1 when x⁴ = 2,
-- so 1/(1 + α) = −1 + α − α² + α³, coordinates [−1, 1, −1, 1].
example : ((1 + X) * (1 - X + X ^ 2 - X ^ 3) : ℤ[X]) = 1 - X ^ 4 := by ring
example : (1 : ℤ) - 2 = -1 := by norm_num

-- What breaks: x⁴ + 4 has no rational root, yet it splits into two quadratics.
example : (X ^ 4 + 4 : ℤ[X]) = (X ^ 2 - 2 * X + 2) * (X ^ 2 + 2 * X + 2) := by ring
example : ∀ t ∈ ([1, -1, 2, -2, 4, -4] : List ℤ), t ^ 4 + 4 ≠ 0 := by decide

-- Adding degrees up ℚ ⊆ ℚ(2^(1/3)) ⊆ ℚ(2^(1/6)) gives 3 + 2 = 5; the true degree is 3 × 2 = 6.
example : 3 + 2 = 5 ∧ 3 * 2 = 6 := by norm_num

-- Finite fields: degree k over GF(2) gives 2^k elements: GF(8), GF(16), GF(256).
example : 2 ^ 3 = 8 ∧ 2 ^ 4 = 16 ∧ 2 ^ 8 = 256 := by norm_num

-- Every degree of a number of ℚ(α) divides 4: the card's degrees 1, 4, 2, 4, 4, 2 do, and 3 does not.
example : ∀ d ∈ ([1, 4, 2, 4, 4, 2] : List ℕ), d ∣ 4 := by decide
example : ¬ (3 : ℕ) ∣ 4 := by decide

#print axioms degree_adjoin_root_of_irreducible
#print axioms tower_law
#print axioms fourth_root_two_degree_four
