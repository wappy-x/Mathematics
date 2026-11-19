-- Norm, trace and discriminant: in a number field the norm and trace of an algebraic integer are the product and sum of its conjugates, both are whole numbers, the norm multiplies and the trace adds, the discriminant of an integral basis does not depend on the basis, and in Z[√-5] the number 6 = 2 · 3 = (1 + √-5)(1 - √-5) splits into irreducibles two genuinely different ways.
import Mathlib.NumberTheory.NumberField.Discriminant.Defs
import Mathlib.RingTheory.Norm.Transitivity
import Mathlib.RingTheory.Trace.Basic
import Mathlib.NumberTheory.Zsqrtd.Basic
import Mathlib.Analysis.Complex.Polynomial.Basic
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic

open NumberField

/-- Norm and trace collapse an algebraic integer into whole numbers that remember products and
sums. Let K be a number field and α, β members of its ring of integers 𝓞 K. The norm N(α) is
the product of the conjugates σ(α) over all n embeddings σ of K into the complex numbers, and
the trace Tr(α) is their sum. Both are whole numbers. The norm multiplies,
N(αβ) = N(α) N(β), and the trace adds, Tr(α + β) = Tr(α) + Tr(β). -/
theorem norm_trace_of_algebraic_integer_are_integers_multiply_and_add
    (K : Type*) [Field K] [NumberField K] (α β : 𝓞 K) :
    algebraMap ℚ ℂ (Algebra.norm ℚ (α : K)) = ∏ σ : K →ₐ[ℚ] ℂ, σ (α : K) ∧
      algebraMap ℚ ℂ (Algebra.trace ℚ K (α : K)) = ∑ σ : K →ₐ[ℚ] ℂ, σ (α : K) ∧
      (∃ n : ℤ, Algebra.norm ℚ (α : K) = n) ∧
      (∃ t : ℤ, Algebra.trace ℚ K (α : K) = t) ∧
      Algebra.norm ℚ ((α * β : 𝓞 K) : K) = Algebra.norm ℚ (α : K) * Algebra.norm ℚ (β : K) ∧
      Algebra.trace ℚ K ((α + β : 𝓞 K) : K) =
        Algebra.trace ℚ K (α : K) + Algebra.trace ℚ K (β : K) := by
  refine ⟨Algebra.norm_eq_prod_embeddings ℚ ℂ (α : K),
    trace_eq_sum_embeddings ℂ, ?_, ?_, ?_, ?_⟩
  · have h : IsIntegral ℤ (Algebra.norm ℚ (α : K)) :=
      Algebra.isIntegral_norm ℚ (RingOfIntegers.isIntegral_coe α)
    obtain ⟨n, hn⟩ := IsIntegrallyClosed.isIntegral_iff.mp h
    exact ⟨n, by rw [← hn]; simp⟩
  · have h : IsIntegral ℤ (Algebra.trace ℚ K (α : K)) :=
      Algebra.isIntegral_trace (RingOfIntegers.isIntegral_coe α)
    obtain ⟨t, ht⟩ := IsIntegrallyClosed.isIntegral_iff.mp h
    exact ⟨t, by rw [← ht]; simp⟩
  · push_cast
    exact map_mul _ _ _
  · push_cast
    exact map_add _ _ _

/-- The discriminant belongs to the field, not the basis. For any two integral bases
w_1, …, w_n and w'_1, …, w'_n of the ring of integers 𝓞 K, the determinants of their trace
tables agree: det [Tr(w_i w_j)] = det [Tr(w'_i w'_j)]. This common value is d_K. -/
theorem discriminant_does_not_depend_on_integral_basis
    (K : Type*) [Field K] [NumberField K] {ι ι' : Type*} [Fintype ι] [DecidableEq ι]
    [Fintype ι'] [DecidableEq ι'] (b : Module.Basis ι ℤ (𝓞 K)) (b' : Module.Basis ι' ℤ (𝓞 K)) :
    (Algebra.traceMatrix ℤ b).det = (Algebra.traceMatrix ℤ b').det ∧
      Algebra.discr ℤ b = NumberField.discr K := by
  have h1 : Algebra.discr ℤ b = NumberField.discr K := NumberField.discr_eq_discr K b
  have h2 : Algebra.discr ℤ b' = NumberField.discr K := NumberField.discr_eq_discr K b'
  rw [Algebra.discr_def] at h1 h2
  exact ⟨h1.trans h2.symm, by rw [Algebra.discr_def]; exact h1⟩

/-- No element of Z[√-5] has norm 2 or 3. -/
theorem zsqrt5_norm_ne_two_three (z : ℤ√(-5)) : z.norm ≠ 2 ∧ z.norm ≠ 3 := by
  rw [Zsqrtd.norm_def]
  rcases eq_or_ne z.im 0 with h | h
  · rw [h]
    have hb : z.re * z.re ≠ 2 ∧ z.re * z.re ≠ 3 := by
      constructor <;> intro he
      · have : -2 ≤ z.re ∧ z.re ≤ 2 := ⟨by nlinarith, by nlinarith⟩
        obtain ⟨l, u⟩ := this
        interval_cases z.re <;> omega
      · have : -2 ≤ z.re ∧ z.re ≤ 2 := ⟨by nlinarith, by nlinarith⟩
        obtain ⟨l, u⟩ := this
        interval_cases z.re <;> omega
    simpa using hb
  · have h1 : 1 ≤ z.im * z.im := by
      rcases lt_or_gt_of_ne h with h' | h' <;> nlinarith
    constructor <;> nlinarith [mul_self_nonneg z.re]

/-- An element of Z[√-5] whose norm is 4, 6 or 9 is irreducible. -/
theorem zsqrt5_irreducible_of_norm (p : ℤ√(-5)) (hn : 4 ≤ p.norm) (hn' : p.norm ≤ 9 ∧
    p.norm ≠ 5 ∧ p.norm ≠ 7 ∧ p.norm ≠ 8) : Irreducible p := by
  have hd : (-5 : ℤ) ≤ 0 := by norm_num
  refine ⟨fun hu => ?_, fun a b hab => ?_⟩
  · have := (Zsqrtd.norm_eq_one_iff' hd p).mpr hu
    omega
  · have hnorm := congrArg Zsqrtd.norm hab
    rw [Zsqrtd.norm_mul] at hnorm
    have ha := Zsqrtd.norm_nonneg hd a
    have hb := Zsqrtd.norm_nonneg hd b
    obtain ⟨ha2, ha3⟩ := zsqrt5_norm_ne_two_three a
    obtain ⟨hb2, hb3⟩ := zsqrt5_norm_ne_two_three b
    have key : a.norm = 1 ∨ b.norm = 1 := by
      have hb1 : 1 ≤ b.norm := by
        rcases eq_or_lt_of_le hb with h | h
        · rw [← h] at hnorm; omega
        · omega
      have ha9 : a.norm ≤ 9 := by nlinarith
      have ha1 : 1 ≤ a.norm := by
        rcases eq_or_lt_of_le ha with h | h
        · rw [← h] at hnorm; omega
        · omega
      generalize a.norm = x at *
      generalize b.norm = y at *
      interval_cases x <;> omega
    rcases key with h | h
    · exact Or.inl ((Zsqrtd.norm_eq_one_iff' hd a).mp h)
    · exact Or.inr ((Zsqrtd.norm_eq_one_iff' hd b).mp h)

/-- Six factors two different ways in Z[√-5]: 6 = 2 · 3 = (1 + √-5)(1 - √-5). All four factors
are irreducible (no split into two non-units), and the two factorisations are genuinely
different: 2 divides neither 1 + √-5 nor 1 - √-5. -/
theorem six_factors_two_ways_in_zsqrt_neg_five :
    (2 : ℤ√(-5)) * 3 = 6 ∧
      (⟨1, 1⟩ : ℤ√(-5)) * ⟨1, -1⟩ = 6 ∧
      Irreducible (2 : ℤ√(-5)) ∧ Irreducible (3 : ℤ√(-5)) ∧
      Irreducible (⟨1, 1⟩ : ℤ√(-5)) ∧ Irreducible (⟨1, -1⟩ : ℤ√(-5)) ∧
      ¬ (2 : ℤ√(-5)) ∣ ⟨1, 1⟩ ∧ ¬ (2 : ℤ√(-5)) ∣ ⟨1, -1⟩ := by
  refine ⟨by decide, by decide, zsqrt5_irreducible_of_norm _ (by decide) (by decide),
    zsqrt5_irreducible_of_norm _ (by decide) (by decide),
    zsqrt5_irreducible_of_norm _ (by decide) (by decide),
    zsqrt5_irreducible_of_norm _ (by decide) (by decide), ?_, ?_⟩
  · rintro ⟨c, hc⟩
    have h := congrArg Zsqrtd.norm hc
    rw [Zsqrtd.norm_mul] at h
    have h4 : Zsqrtd.norm (2 : ℤ√(-5)) = 4 := by decide
    have h6 : Zsqrtd.norm (⟨1, 1⟩ : ℤ√(-5)) = 6 := by decide
    rw [h4, h6] at h
    omega
  · rintro ⟨c, hc⟩
    have h := congrArg Zsqrtd.norm hc
    rw [Zsqrtd.norm_mul] at h
    have h4 : Zsqrtd.norm (2 : ℤ√(-5)) = 4 := by decide
    have h6 : Zsqrtd.norm (⟨1, -1⟩ : ℤ√(-5)) = 6 := by decide
    rw [h4, h6] at h
    omega

-- The norm a^2 + 5b^2 in Z[√-5]: N(1 + √-5) = 6, N(1 - √-5) = 6, N(2) = 4, N(3) = 9.
example : Zsqrtd.norm (⟨1, 1⟩ : ℤ√(-5)) = 6 := by decide
example : Zsqrtd.norm (⟨1, -1⟩ : ℤ√(-5)) = 6 := by decide
example : Zsqrtd.norm (⟨2, 0⟩ : ℤ√(-5)) = 4 := by decide
example : Zsqrtd.norm (⟨3, 0⟩ : ℤ√(-5)) = 9 := by decide
-- Trace: (1 + √-5) + (1 - √-5) = 2.
example : (⟨1, 1⟩ : ℤ√(-5)) + ⟨1, -1⟩ = 2 := by decide
-- (1 + √-5)^2 = -4 + 2√-5, and alpha^2 - 2 alpha + 6 = 0.
example : (⟨1, 1⟩ : ℤ√(-5)) * ⟨1, 1⟩ = ⟨-4, 2⟩ := by decide
example : (⟨1, 1⟩ : ℤ√(-5)) * ⟨1, 1⟩ - 2 * ⟨1, 1⟩ + 6 = 0 := by decide
-- The matrix of multiply-by-(1 + √-5): determinant 6, trace 2.
example : (!![1, -5; 1, 1] : Matrix (Fin 2) (Fin 2) ℤ).det = 6 := by
  norm_num [Matrix.det_fin_two_of]
example : (!![1, -5; 1, 1] : Matrix (Fin 2) (Fin 2) ℤ).trace = 2 := by
  norm_num [Matrix.trace_fin_two]
-- Trace tables: basis 1, √-5 gives -20; basis 1, (1 + √5)/2 gives 5; the smaller ring's
-- basis 1, √5 gives 20; basis 1, ∛2, ∛4 gives -108.
example : (!![2, 0; 0, -10] : Matrix (Fin 2) (Fin 2) ℤ).det = -20 := by
  norm_num [Matrix.det_fin_two_of]
example : (!![2, 1; 1, 3] : Matrix (Fin 2) (Fin 2) ℤ).det = 5 := by
  norm_num [Matrix.det_fin_two_of]
example : (!![2, 0; 0, 10] : Matrix (Fin 2) (Fin 2) ℤ).det = 20 := by
  norm_num [Matrix.det_fin_two_of]
example : (!![3, 0, 0; 0, 0, 6; 0, 6, 0] : Matrix (Fin 3) (Fin 3) ℤ).det = -108 := by
  norm_num [Matrix.det_fin_three]
-- -20 = -(2^2 · 5), and the polynomial formula -4 · 0^3 - 27 · (-2)^2 = -108.
example : (-20 : ℤ) = -(2 ^ 2 * 5) := by norm_num
example : (-4 * 0 ^ 3 - 27 * (-2) ^ 2 : ℤ) = -108 := by norm_num
-- The cubic field: N(1 + ∛2) = -f(-1) = 3 for f = x^3 - 2, and
-- (1 + ∛2)(1 - ∛2 + ∛4) = 3 for any θ with θ^3 = 2.
example : -((-1 : ℤ) ^ 3 - 2) = 3 := by norm_num
example (θ : ℝ) (h : θ ^ 3 = 2) : (1 + θ) * (1 - θ + θ ^ 2) = 3 := by
  linear_combination h

#print axioms zsqrt5_norm_ne_two_three
#print axioms zsqrt5_irreducible_of_norm
#print axioms norm_trace_of_algebraic_integer_are_integers_multiply_and_add
#print axioms discriminant_does_not_depend_on_integral_basis
#print axioms six_factors_two_ways_in_zsqrt_neg_five
