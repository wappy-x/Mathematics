-- Error propagation: for a formula that is a straight line in independent inputs, the answer's variance is the sum of each slope squared times that input's variance, with the percentage rule for a product of powers and the fact that adding in squares never exceeds straight addition.
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Independence.Basic
import Mathlib.Analysis.Calculus.Deriv.ZPow
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.SpecialFunctions.Sqrt

open MeasureTheory ProbabilityTheory

/-- The law of propagation of uncertainty, exact for a straight-line formula. Let the answer
`f` be a straight line in its inputs near the true values `x`, with slope (sensitivity
coefficient) `c i` along input `i`, so an input error `d` moves the answer by `∑ c i * d i`.
If the input errors `δ i` are independent and each has a finite variance `u(xᵢ)²`, then the
answer's squared uncertainty is the sum over the inputs of the slope squared times that
input's squared uncertainty: `u(y)² = ∑ cᵢ² u(xᵢ)²`. -/
theorem uncertainty_sq_eq_sum_sensitivity_sq_mul_uncertainty_sq
    {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω} [IsProbabilityMeasure μ] {n : ℕ}
    (f : (Fin n → ℝ) → ℝ) (x c : Fin n → ℝ)
    (hf : ∀ d : Fin n → ℝ, f (x + d) = f x + ∑ i, c i * d i)
    (δ : Fin n → Ω → ℝ) (hδ : ∀ i, MemLp (δ i) 2 μ) (hind : iIndepFun δ μ) :
    variance (fun ω => f (x + fun i => δ i ω)) μ = ∑ i, c i ^ 2 * variance (δ i) μ := by
  have hL : ∀ i ∈ (Finset.univ : Finset (Fin n)), MemLp (fun ω => c i * δ i ω) 2 μ :=
    fun i _ => (hδ i).const_mul (c i)
  have h1 : (fun ω => f (x + fun i => δ i ω))
      = fun ω => f x + (∑ i, (fun ω => c i * δ i ω)) ω := by
    funext ω; rw [hf]; simp [Finset.sum_apply]
  rw [h1, variance_const_add (memLp_finsetSum' _ hL).aestronglyMeasurable, IndepFun.variance_sum hL]
  · simp [variance_const_mul]
  · intro i _ j _ hij
    exact (hind.indepFun hij).comp (measurable_const_mul (c i)) (measurable_const_mul (c j))

/-- The shortcut for a product of powers. If `y = k * x₁^n₁ * x₂^n₂ * ⋯` with a fixed nonzero
number `k` and nonzero readings, then the slope along input `i` (the partial derivative, other
inputs held still) is `cᵢ`, and the answer's relative squared uncertainty is the sum of each
power squared times that input's relative squared uncertainty:
`(u(y)/y)² = ∑ nᵢ² (u(xᵢ)/xᵢ)²`, where `u(y)² = ∑ cᵢ² u(xᵢ)²`. -/
theorem relative_uncertainty_sq_of_product_of_powers {m : ℕ} (k : ℝ) (hk : k ≠ 0)
    (x : Fin m → ℝ) (hx : ∀ j, x j ≠ 0) (p : Fin m → ℤ) (u : Fin m → ℝ) :
    (∑ i, (deriv (fun t => k * ∏ j, Function.update x i t j ^ p j) (x i)) ^ 2 * u i ^ 2)
        / (k * ∏ j, x j ^ p j) ^ 2
      = ∑ i, (p i : ℝ) ^ 2 * (u i / x i) ^ 2 := by
  have hP : k * ∏ j, x j ^ p j ≠ 0 :=
    mul_ne_zero hk (Finset.prod_ne_zero_iff.2 fun j _ => zpow_ne_zero _ (hx j))
  have hd : ∀ i, deriv (fun t => k * ∏ j, Function.update x i t j ^ p j) (x i)
      = (p i : ℝ) * (k * ∏ j, x j ^ p j) / x i := by
    intro i
    set C := ∏ j ∈ Finset.univ \ {i}, x j ^ p j with hC
    have hfun : (fun t => k * ∏ j, Function.update x i t j ^ p j) = fun t => k * (t ^ p i * C) := by
      funext t
      rw [Finset.prod_eq_mul_prod_sdiff_singleton_of_mem (Finset.mem_univ i)]
      simp only [Function.update_self]
      congr 2
      refine Finset.prod_congr rfl fun j hj => ?_
      have : j ≠ i := by simpa using hj
      simp [Function.update_of_ne this]
    have hprod : ∏ j, x j ^ p j = x i ^ p i * C :=
      Finset.prod_eq_mul_prod_sdiff_singleton_of_mem (Finset.mem_univ i) _
    rw [hfun, hprod]
    have := ((hasDerivAt_zpow (p i) (x i) (Or.inl (hx i))).mul_const C).const_mul k
    rw [this.deriv, zpow_sub_one₀ (hx i)]
    field_simp
  simp_rw [hd, Finset.sum_div]
  refine Finset.sum_congr rfl fun i _ => ?_
  have := hx i
  have hQ : ∏ j, x j ^ p j ≠ 0 := Finset.prod_ne_zero_iff.2 fun j _ => zpow_ne_zero _ (hx j)
  field_simp

/-- Adding in quadrature never gives more than adding straight: the square root of the sum of
the squared terms is at most the sum of the terms' sizes (the worst case, every error at full
size in the same direction). -/
theorem quadrature_sum_le_straight_sum {m : ℕ} (a : Fin m → ℝ) :
    Real.sqrt (∑ i, a i ^ 2) ≤ ∑ i, |a i| := by
  rw [Real.sqrt_le_iff]
  refine ⟨Finset.sum_nonneg fun i _ => abs_nonneg _, ?_⟩
  calc ∑ i, a i ^ 2 = ∑ i, |a i| ^ 2 := by simp
    _ ≤ (∑ i, |a i|) ^ 2 := Finset.sum_sq_le_sq_sum_of_nonneg fun i _ => abs_nonneg _

-- The card's worked numbers, exactly, as fractions.
-- Bottom of the formula: 1.204 × 12.00² × 0.400 = 69.3504.
example : (1204 / 1000 : ℚ) * 12 ^ 2 * (400 / 1000) = 693504 / 10000 := by norm_num
-- Percentage terms, power times percentage error: force 1 %, speed 3 %, area 2 %,
-- density 150/301 % (about 0.498 %).
example : (1 : ℚ) * ((24 / 100) / 24) * 100 = 1 := by norm_num
example : (2 : ℚ) * ((18 / 100) / 12) * 100 = 3 := by norm_num
example : (1 : ℚ) * ((8 / 1000) / (400 / 1000)) * 100 = 2 := by norm_num
example : (1 : ℚ) * ((6 / 1000) / (1204 / 1000)) * 100 = 150 / 301 := by norm_num
-- Squares added: 1 + 9 + 4 + 0.2483 = 14.2483 (to four places).
example : (142483 / 10000 : ℚ) < 1 ^ 2 + 3 ^ 2 + 2 ^ 2 + (150 / 301) ^ 2 ∧
    1 ^ 2 + 3 ^ 2 + 2 ^ 2 + (150 / 301) ^ 2 < (142484 / 10000 : ℚ) := by norm_num
-- The speed's square, 9, is the biggest, so the speed is the input to fix.
example : (1 : ℚ) ^ 2 < 3 ^ 2 ∧ (2 : ℚ) ^ 2 < 3 ^ 2 ∧ (150 / 301 : ℚ) ^ 2 < 3 ^ 2 := by norm_num
-- Straight addition: 1 + 3 + 2 + 0.498 = 6.498 %, against 3.775 % in quadrature
-- (3.7745² < 14.2483 < 3.7755², so the root rounds to 3.775).
example : (6498 / 1000 : ℚ) < 1 + 3 + 2 + 150 / 301 ∧ 1 + 3 + 2 + 150 / 301 < (6499 / 1000 : ℚ) := by
  norm_num
example : (37745 / 10000 : ℚ) ^ 2 < 1 ^ 2 + 3 ^ 2 + 2 ^ 2 + (150 / 301) ^ 2 ∧
    1 ^ 2 + 3 ^ 2 + 2 ^ 2 + (150 / 301) ^ 2 < (37755 / 10000 : ℚ) ^ 2 := by norm_num

#print axioms uncertainty_sq_eq_sum_sensitivity_sq_mul_uncertainty_sq
#print axioms relative_uncertainty_sq_of_product_of_powers
#print axioms quadrature_sum_le_straight_sum
