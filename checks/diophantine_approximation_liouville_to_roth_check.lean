-- Chasing an algebraic number with fractions: an algebraic number of degree d stays at least c/q^d from every other fraction p/q, every irrational has infinitely many fractions within 1/q^2, and Liouville's constant is transcendental.
import Mathlib.NumberTheory.Transcendental.Liouville.LiouvilleNumber
import Mathlib.NumberTheory.DiophantineApproximation.Basic
import Mathlib.FieldTheory.Minpoly.Field
import Mathlib.RingTheory.Localization.Integral
import Mathlib.NumberTheory.Transcendental.Liouville.LiouvilleWith

open Polynomial

theorem rat_bound (r : ℚ) : ∀ p : ℤ, ∀ q : ℕ, 1 ≤ q → (p : ℝ) / q ≠ (r : ℝ) →
    (1 / (r.den : ℝ)) / q ≤ |(r : ℝ) - (p : ℝ) / q| := by
  intro p q hq hne
  have hq0 : (0 : ℝ) < q := by exact_mod_cast hq
  have hd0 : (0 : ℝ) < r.den := by exact_mod_cast r.den_pos
  have hr : (r : ℝ) = r.num / r.den := by exact_mod_cast (Rat.num_div_den r).symm
  have hk : r.num * q - p * r.den ≠ 0 := by
    intro h
    apply hne
    rw [hr, div_eq_div_iff hq0.ne' hd0.ne']
    have : ((r.num * q - p * r.den : ℤ) : ℝ) = 0 := by exact_mod_cast h
    push_cast at this
    linarith
  have h1 : (1 : ℝ) ≤ |((r.num * q - p * r.den : ℤ) : ℝ)| := by
    rw [← Int.cast_abs]; exact_mod_cast Int.one_le_abs hk
  have heq : (r : ℝ) - p / q = ((r.num * q - p * r.den : ℤ) : ℝ) / (r.den * q) := by
    rw [hr]; push_cast; field_simp
  rw [heq, abs_div, abs_of_pos (by positivity : (0:ℝ) < r.den * q), div_div]
  exact div_le_div_of_nonneg_right h1 (by positivity)
#print axioms rat_bound

theorem int_poly_of_minpoly (α : ℝ) (hα : IsAlgebraic ℚ α) :
    ∃ f : ℤ[X], f ≠ 0 ∧ f.natDegree = (minpoly ℚ α).natDegree ∧
      eval α (map (algebraMap ℤ ℝ) f) = 0 := by
  obtain ⟨b, hb, hf⟩ := IsLocalization.integerNormalization_spec (nonZeroDivisors ℤ) (minpoly ℚ α)
  set f := IsLocalization.integerNormalization (nonZeroDivisors ℤ) (minpoly ℚ α)
  have hb0 : (b : ℚ) ≠ 0 := by
    have := nonZeroDivisors.ne_zero hb
    exact_mod_cast this
  have hsmul : b • minpoly ℚ α = C (b : ℚ) * minpoly ℚ α := by
    rw [← smul_eq_C_mul]; exact (Int.cast_smul_eq_zsmul ℚ b (minpoly ℚ α)).symm
  have hdeg : f.natDegree = (minpoly ℚ α).natDegree := by
    rw [← natDegree_map_eq_of_injective (algebraMap ℤ ℚ).injective_int f, hf, hsmul,
      natDegree_C_mul hb0]
  have hpos := minpoly.natDegree_pos hα.isIntegral
  refine ⟨f, ?_, hdeg, ?_⟩
  · intro h0; rw [h0, natDegree_zero] at hdeg; omega
  · have : eval α (map (algebraMap ℤ ℝ) f) = aeval α (map (algebraMap ℤ ℚ) f) := by
      rw [aeval_map_algebraMap, eval_map_algebraMap]
    rw [this, hf, hsmul, map_mul, minpoly.aeval, mul_zero]

#print axioms int_poly_of_minpoly

/-- Liouville's bound: for every real algebraic number α of degree d (the degree of its minimal
polynomial over the rationals) there is a positive number c such that every fraction p/q with
q ≥ 1 and p/q ≠ α lies at distance at least c/q^d from α. -/
theorem liouville_bound (α : ℝ) (hα : IsAlgebraic ℚ α) :
    ∃ c : ℝ, 0 < c ∧ ∀ p : ℤ, ∀ q : ℕ, 1 ≤ q → (p : ℝ) / q ≠ α →
      c / (q : ℝ) ^ (minpoly ℚ α).natDegree ≤ |α - (p : ℝ) / q| := by
  have hpos := minpoly.natDegree_pos hα.isIntegral
  by_cases hirr : Irrational α
  · obtain ⟨f, f0, fdeg, fa⟩ := int_poly_of_minpoly α hα
    obtain ⟨A, hA, h⟩ := Liouville.exists_pos_real_of_irrational_root hirr f0 fa
    refine ⟨1 / A, by positivity, fun p q hq _ => ?_⟩
    obtain ⟨b, rfl⟩ : ∃ b, q = b + 1 := ⟨q - 1, by omega⟩
    have hb := h p b
    rw [fdeg] at hb
    push_cast
    have hpow : (0 : ℝ) < ((b : ℝ) + 1) ^ (minpoly ℚ α).natDegree := by positivity
    rw [div_div, div_le_iff₀ (by positivity)]
    nlinarith
  · obtain ⟨r, rfl⟩ : ∃ r : ℚ, (r : ℝ) = α := by
      unfold Irrational at hirr; push Not at hirr; simpa using hirr
    refine ⟨1 / r.den, by positivity, fun p q hq hne => ?_⟩
    refine le_trans ?_ (rat_bound r p q hq hne)
    have hq1 : (1 : ℝ) ≤ q := by exact_mod_cast hq
    have : (q : ℝ) ≤ (q : ℝ) ^ (minpoly ℚ (r : ℝ)).natDegree :=
      le_self_pow₀ hq1 (by omega)
    gcongr

/-- Dirichlet's bound: every irrational number α has infinitely many fractions p/q
(in lowest terms, with denominator q) within 1/q^2 of it. -/
theorem dirichlet_bound (α : ℝ) (hα : Irrational α) :
    {r : ℚ | |α - (r : ℝ)| < 1 / (r.den : ℝ) ^ 2}.Infinite := by
  exact Real.infinite_rat_abs_sub_lt_one_div_den_sq_of_irrational hα

/-- Liouville's constant L = 10^(-1!) + 10^(-2!) + 10^(-3!) + ... = 0.110001000... is
transcendental: no nonzero polynomial with whole-number coefficients has it as a root. -/
theorem liouville_constant_transcendental :
    Transcendental ℤ (∑' k : ℕ, (1 : ℝ) / 10 ^ (k + 1).factorial) := by
  have hs : Summable fun i : ℕ => (1 : ℝ) / 10 ^ i.factorial :=
    LiouvilleNumber.summable (by norm_num)
  have h1 : liouvilleNumber 10 =
      1 / 10 ^ (0 : ℕ).factorial + ∑' k : ℕ, (1 : ℝ) / 10 ^ (k + 1).factorial :=
    hs.tsum_eq_zero_add
  have hL : Liouville (liouvilleNumber 10) := by
    have := liouville_liouvilleNumber (m := 10) (by norm_num)
    simpa using this
  have h2 : (∑' k : ℕ, (1 : ℝ) / 10 ^ (k + 1).factorial) =
      liouvilleNumber 10 - ((1 / 10 : ℚ) : ℝ) := by
    rw [h1]; push_cast; simp
  rw [h2]
  exact (forall_liouvilleWith_iff.mp fun p => (hL.liouvilleWith p).sub_rat _).transcendental

-- Cutting L after its third 1 gives 0.110001 = 110001/10^6, with denominator q_3 = 10^(3!).
example : (1 : ℚ) / 10 ^ Nat.factorial 1 + 1 / 10 ^ Nat.factorial 2 + 1 / 10 ^ Nat.factorial 3
    = 110001 / 10 ^ 6 := by
  norm_num [Nat.factorial]

-- The next 1 sits at place 4! = 24 and then 5! = 120; exponents seen 24 / 6 = 4 and 120 / 24 = 5.
example : Nat.factorial 3 = 6 ∧ Nat.factorial 4 = 24 ∧ Nat.factorial 5 = 120 ∧
    Nat.factorial 4 / Nat.factorial 3 = 4 ∧ Nat.factorial 5 / Nat.factorial 4 = 5 := by
  decide

-- Testing degree 3: q^3 times the error is 10^18 * 10^-24 = 10^-6 at n = 3, and 10^72 * 10^-120 = 10^-48 at n = 4.
example : ((10 : ℚ) ^ 6) ^ 3 * (1 / 10 ^ 24) = 1 / 10 ^ 6 ∧
    ((10 : ℚ) ^ 24) ^ 3 * (1 / 10 ^ 120) = 1 / 10 ^ 48 := by
  norm_num

-- The tops p^3 - 2q^3 of the 14 convergents p/q of the cube root of 2 with q ≤ 10^6 (sizes as in the card's table).
example : [(1, 1), (4, 3), (5, 4), (29, 23), (34, 27), (63, 50), (286, 227), (349, 277),
    (635, 504), (5429, 4309), (6064, 4813), (90325, 71691), (96389, 76504), (1054215, 836731)].map
      (fun pq : ℤ × ℤ => pq.1 ^ 3 - 2 * pq.2 ^ 3)
    = [-1, 10, -3, 55, -62, 47, -510, 683, -253, 17331, -1450, 293383, -32259, 1376593] := by
  decide

-- Inside Bennett's box |y| ≤ 11 (which forces |x| ≤ 13), x^3 - 2y^3 = 1 has exactly the solutions (1, 0) and (-1, -1).
example : ∀ x ∈ Finset.Icc (-14 : ℤ) 14, ∀ y ∈ Finset.Icc (-11 : ℤ) 11,
    (x ^ 3 - 2 * y ^ 3 = 1 ↔ (x, y) = (1, 0) ∨ (x, y) = (-1, -1)) := by
  decide +kernel

#print axioms liouville_bound
#print axioms dirichlet_bound
#print axioms liouville_constant_transcendental
