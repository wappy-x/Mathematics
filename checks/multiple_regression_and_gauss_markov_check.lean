-- Multiple regression: when the columns of the design matrix are independent and the errors average zero with one common variance and no correlation, the least-squares fit is unbiased with covariance σ²(XᵀX)⁻¹, each coefficient is a one-column slope on its column's leftover, and no linear unbiased rule has a smaller variance for any mix of coefficients (Gauss–Markov).
import Mathlib.Probability.Moments.Covariance
import Mathlib.Probability.Moments.Variance
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.LinearIndependent.Defs
import Mathlib.LinearAlgebra.Span.Defs
import Mathlib.Tactic.NormNum
import Mathlib.LinearAlgebra.Matrix.ToLinearEquiv
import Mathlib.LinearAlgebra.Matrix.DotProduct

/-! Notation as on the card. `n` sales, `p` coefficients. `X` is the design matrix (one row per
sale, one column per predictor, the 1s column included); its column `j` is `fun i => X i j`.
`β` is the true coefficient column, `ε i` the error on sale `i`, a random number on the
probability space `(Ω, μ)`, and the prices are `y = Xβ + ε`. The least-squares weights are
`L = (XᵀX)⁻¹ Xᵀ`, and the fitted coefficients are `β̂ = L y`. A rival rule is a fixed table `A`
of `p` by `n` weights, applied as `A y`; it is unbiased exactly when `A X = I`. -/

open MeasureTheory ProbabilityTheory Matrix

theorem gm_adj {n p : ℕ} (X : Matrix (Fin n) (Fin p) ℝ) (v : Fin p → ℝ) (y : Fin n → ℝ) :
    (X *ᵥ v) ⬝ᵥ y = v ⬝ᵥ (Xᵀ *ᵥ y) := by
  rw [mulVec_transpose, dotProduct_comm, dotProduct_mulVec, dotProduct_comm]

#print axioms gm_adj

theorem gm_mulVec_eq_zero_of_linIndep {n p : ℕ} (X : Matrix (Fin n) (Fin p) ℝ)
    (hX : LinearIndependent ℝ (fun j : Fin p => fun i : Fin n => X i j))
    (v : Fin p → ℝ) (hv : X *ᵥ v = 0) : v = 0 := by
  rw [Fintype.linearIndependent_iff] at hX
  funext j
  apply hX v _ j
  funext i
  have := congrFun hv i
  simpa [mulVec, dotProduct, Finset.sum_apply, mul_comm] using this

#print axioms gm_mulVec_eq_zero_of_linIndep

theorem gm_gram_isUnit {n p : ℕ} (X : Matrix (Fin n) (Fin p) ℝ)
    (hX : LinearIndependent ℝ (fun j : Fin p => fun i : Fin n => X i j)) :
    IsUnit (Xᵀ * X).det := by
  rw [isUnit_iff_ne_zero, Ne, ← exists_mulVec_eq_zero_iff]
  rintro ⟨v, hv0, hv⟩
  apply hv0
  apply gm_mulVec_eq_zero_of_linIndep X hX
  have h1 : (X *ᵥ v) ⬝ᵥ (X *ᵥ v) = 0 := by
    rw [gm_adj, mulVec_mulVec, hv, dotProduct_zero]
  exact dotProduct_self_eq_zero.mp h1

#print axioms gm_gram_isUnit

theorem gm_left_inv {n p : ℕ} (X : Matrix (Fin n) (Fin p) ℝ)
    (hX : LinearIndependent ℝ (fun j : Fin p => fun i : Fin n => X i j)) :
    ((Xᵀ * X)⁻¹ * Xᵀ) * X = 1 := by
  rw [Matrix.mul_assoc, nonsing_inv_mul _ (gm_gram_isUnit X hX)]

#print axioms gm_left_inv

theorem gm_LLt {n p : ℕ} (X : Matrix (Fin n) (Fin p) ℝ)
    (hX : LinearIndependent ℝ (fun j : Fin p => fun i : Fin n => X i j)) :
    ((Xᵀ * X)⁻¹ * Xᵀ) * ((Xᵀ * X)⁻¹ * Xᵀ)ᵀ = (Xᵀ * X)⁻¹ := by
  have hsym : (Xᵀ * X)ᵀ = Xᵀ * X := by rw [transpose_mul, transpose_transpose]
  rw [transpose_mul, transpose_transpose, transpose_nonsing_inv, hsym, ← Matrix.mul_assoc,
    gm_left_inv X hX, Matrix.one_mul]

#print axioms gm_LLt

theorem gm_apply {n p : ℕ} (X : Matrix (Fin n) (Fin p) ℝ) (M : Matrix (Fin p) (Fin n) ℝ)
    (hM : M * X = 1) (β : Fin p → ℝ) (e : Fin n → ℝ) (j : Fin p) :
    (M *ᵥ (X *ᵥ β + e)) j = β j + (fun i => M j i) ⬝ᵥ e := by
  rw [mulVec_add, mulVec_mulVec, hM, one_mulVec]
  rfl

#print axioms gm_apply

theorem gm_dot_apply {n p : ℕ} (X : Matrix (Fin n) (Fin p) ℝ) (M : Matrix (Fin p) (Fin n) ℝ)
    (hM : M * X = 1) (β : Fin p → ℝ) (e : Fin n → ℝ) (c : Fin p → ℝ) :
    c ⬝ᵥ (M *ᵥ (X *ᵥ β + e)) = c ⬝ᵥ β + (Mᵀ *ᵥ c) ⬝ᵥ e := by
  rw [mulVec_add, mulVec_mulVec, hM, one_mulVec, dotProduct_add, dotProduct_mulVec,
    mulVec_transpose]

#print axioms gm_dot_apply

theorem gm_integrable {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    {n : ℕ} (ε : Fin n → Ω → ℝ) (hε : ∀ i, MemLp (ε i) 2 μ) (u : Fin n → ℝ) :
    Integrable (fun ω => u ⬝ᵥ (fun i => ε i ω)) μ := by
  simp only [dotProduct]
  exact integrable_finsetSum (f := fun i ω => u i * ε i ω) _
    fun i _ => ((hε i).const_mul (u i)).integrable one_le_two

#print axioms gm_integrable

theorem gm_cov_lin {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    {n : ℕ} (ε : Fin n → Ω → ℝ) (hε : ∀ i, MemLp (ε i) 2 μ) (σ : ℝ)
    (hcov : ∀ i k, cov[ε i, ε k; μ] = if i = k then σ ^ 2 else 0)
    (a b : ℝ) (w w' : Fin n → ℝ) :
    cov[fun ω => a + w ⬝ᵥ (fun i => ε i ω), fun ω => b + w' ⬝ᵥ (fun i => ε i ω); μ]
      = σ ^ 2 * (w ⬝ᵥ w') := by
  have hm : ∀ (u : Fin n → ℝ) i, MemLp (fun ω => u i * ε i ω) 2 μ :=
    fun u i => (hε i).const_mul (u i)
  rw [covariance_const_add_left (gm_integrable μ ε hε w),
    covariance_const_add_right (gm_integrable μ ε hε w')]
  simp only [dotProduct]
  rw [covariance_fun_sum_fun_sum (hm w) (hm w')]
  simp only [covariance_const_mul_left, covariance_const_mul_right, hcov]
  simp only [mul_ite, mul_zero, Finset.sum_ite_eq, Finset.mem_univ, ite_true, Finset.mul_sum]
  exact Finset.sum_congr rfl fun i _ => by ring

#print axioms gm_cov_lin

/-- **Gauss–Markov: least squares is best among linear unbiased rules.** Take the model
`y = Xβ + ε` with fixed columns, no column a weighted sum of the others, errors that average
zero and have finite variance, and one common variance `σ²` with no correlation between
different errors (`Cov(ε) = σ² I`). Let `A` be any fixed table of weights with `A X = I`, a
linear unbiased rule. Then for every fixed mix `c` of the coefficients,
`Var(cᵀ A y) ≥ Var(cᵀ β̂)`, where `β̂ = (XᵀX)⁻¹ Xᵀ y` is the least-squares fit.
Normal errors are not assumed. -/
theorem gauss_markov_least_squares_best_linear_unbiased
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ] {n p : ℕ}
    (X : Matrix (Fin n) (Fin p) ℝ)
    (hX : LinearIndependent ℝ (fun j : Fin p => fun i : Fin n => X i j))
    (β : Fin p → ℝ) (ε : Fin n → Ω → ℝ) (hε : ∀ i, MemLp (ε i) 2 μ)
    (hmean : ∀ i, ∫ ω, ε i ω ∂μ = 0) (σ : ℝ)
    (hcov : ∀ i k, cov[ε i, ε k; μ] = if i = k then σ ^ 2 else 0)
    (A : Matrix (Fin p) (Fin n) ℝ) (hA : A * X = 1) (c : Fin p → ℝ) :
    Var[fun ω => c ⬝ᵥ (((Xᵀ * X)⁻¹ * Xᵀ) *ᵥ (X *ᵥ β + fun i => ε i ω)); μ]
      ≤ Var[fun ω => c ⬝ᵥ (A *ᵥ (X *ᵥ β + fun i => ε i ω)); μ] := by
  have hL := gm_left_inv X hX
  simp_rw [gm_dot_apply X _ hL β, gm_dot_apply X A hA β]
  rw [← covariance_self ((gm_integrable μ ε hε _).aemeasurable.const_add _),
    ← covariance_self ((gm_integrable μ ε hε _).aemeasurable.const_add _),
    gm_cov_lin μ ε hε σ hcov, gm_cov_lin μ ε hε σ hcov]
  apply mul_le_mul_of_nonneg_left _ (sq_nonneg σ)
  set L := (Xᵀ * X)⁻¹ * Xᵀ with hLdef
  have key : ∀ M : Matrix (Fin p) (Fin n) ℝ, M * X = 1 → Xᵀ *ᵥ (Mᵀ *ᵥ c) = c := by
    intro M hM
    rw [mulVec_mulVec, ← transpose_mul, hM, transpose_one, one_mulVec]
  have hl : Lᵀ *ᵥ c = X *ᵥ ((Xᵀ * X)⁻¹ᵀ *ᵥ c) := by
    rw [hLdef, transpose_mul, transpose_transpose, mulVec_mulVec]
  have h1 : (Lᵀ *ᵥ c) ⬝ᵥ (Aᵀ *ᵥ c) = ((Xᵀ * X)⁻¹ᵀ *ᵥ c) ⬝ᵥ c := by
    rw [hl, gm_adj, key A hA]
  have h2 : (Lᵀ *ᵥ c) ⬝ᵥ (Lᵀ *ᵥ c) = ((Xᵀ * X)⁻¹ᵀ *ᵥ c) ⬝ᵥ c := by
    nth_rewrite 1 [hl]; rw [gm_adj, key L hL]
  set l := Lᵀ *ᵥ c
  set a := Aᵀ *ᵥ c
  have hld : l ⬝ᵥ (a - l) = 0 := by
    rw [dotProduct_sub, h1, h2, sub_self]
  have hdd : 0 ≤ (a - l) ⬝ᵥ (a - l) := Finset.sum_nonneg fun i _ => mul_self_nonneg _
  have : a = l + (a - l) := by abel
  rw [this, add_dotProduct, dotProduct_add, dotProduct_add, hld, dotProduct_comm (a - l) l, hld]
  linarith

/-- **The fit is right on average, and its spread is `σ² (XᵀX)⁻¹`.** Under the same model
(independent columns, errors averaging zero with finite variance, `Cov(ε) = σ² I`), each
least-squares coefficient `β̂ⱼ` averages to the true `βⱼ`, and the covariance of `β̂ⱼ` and
`β̂ₖ` is `σ²` times entry `(j, k)` of `(XᵀX)⁻¹`. -/
theorem least_squares_unbiased_and_covariance
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ] {n p : ℕ}
    (X : Matrix (Fin n) (Fin p) ℝ)
    (hX : LinearIndependent ℝ (fun j : Fin p => fun i : Fin n => X i j))
    (β : Fin p → ℝ) (ε : Fin n → Ω → ℝ) (hε : ∀ i, MemLp (ε i) 2 μ)
    (hmean : ∀ i, ∫ ω, ε i ω ∂μ = 0) (σ : ℝ)
    (hcov : ∀ i k, cov[ε i, ε k; μ] = if i = k then σ ^ 2 else 0) :
    (∀ j, ∫ ω, (((Xᵀ * X)⁻¹ * Xᵀ) *ᵥ (X *ᵥ β + fun i => ε i ω)) j ∂μ = β j) ∧
      ∀ j k, cov[fun ω => (((Xᵀ * X)⁻¹ * Xᵀ) *ᵥ (X *ᵥ β + fun i => ε i ω)) j,
                 fun ω => (((Xᵀ * X)⁻¹ * Xᵀ) *ᵥ (X *ᵥ β + fun i => ε i ω)) k; μ]
        = σ ^ 2 * (Xᵀ * X)⁻¹ j k := by
  have hL := gm_left_inv X hX
  simp_rw [gm_apply X _ hL β]
  refine ⟨fun j => ?_, fun j k => ?_⟩
  · rw [integral_add (integrable_const _) (gm_integrable μ ε hε _), integral_const]
    simp only [dotProduct]
    rw [integral_finsetSum _ fun i _ => ((hε i).const_mul _).integrable one_le_two]
    simp [integral_const_mul, hmean]
  · rw [gm_cov_lin μ ε hε σ hcov]
    have h := congrFun (congrFun (gm_LLt X hX) j) k
    rw [Matrix.mul_apply] at h
    rw [← h]
    rfl

/-- **"Holding the others fixed" (Frisch–Waugh–Lovell).** Let the columns of `X` be independent,
and let `r` be column `j` after removing all it shares with the other columns: `r` is
perpendicular to every other column, and column `j` minus `r` is a weighted sum of the other
columns. Then for any prices `y`, the least-squares coefficient on column `j` is the one-column
slope of `y` on that leftover: `β̂ⱼ = rᵀy / rᵀr`. -/
theorem least_squares_coefficient_eq_slope_on_leftover {n p : ℕ}
    (X : Matrix (Fin n) (Fin p) ℝ)
    (hX : LinearIndependent ℝ (fun j : Fin p => fun i : Fin n => X i j))
    (y : Fin n → ℝ) (j : Fin p) (r : Fin n → ℝ)
    (hperp : ∀ k, k ≠ j → r ⬝ᵥ (fun i => X i k) = 0)
    (hrest : (fun i => X i j) - r ∈
      Submodule.span ℝ ((fun k : Fin p => fun i : Fin n => X i k) '' {k | k ≠ j})) :
    (((Xᵀ * X)⁻¹ * Xᵀ) *ᵥ y) j = (r ⬝ᵥ y) / (r ⬝ᵥ r) := by
  have hG := gm_gram_isUnit X hX
  -- every vector in the span of the other columns is perpendicular to r
  have hspan : ∀ z ∈ Submodule.span ℝ ((fun k : Fin p => fun i : Fin n => X i k) '' {k | k ≠ j}),
      z ⬝ᵥ r = 0 := by
    intro z hz
    induction hz using Submodule.span_induction with
    | mem x hx =>
      obtain ⟨k, hk, rfl⟩ := hx
      rw [dotProduct_comm]; exact hperp k hk
    | zero => exact zero_dotProduct _
    | add x y _ _ hx hy => rw [add_dotProduct, hx, hy, add_zero]
    | smul a x _ hx => rw [smul_dotProduct, hx, smul_zero]
  have hjr : (fun i => X i j) ⬝ᵥ r = r ⬝ᵥ r := by
    have := hspan _ hrest
    rw [sub_dotProduct] at this
    linarith
  have hr0 : r ≠ 0 := by
    rintro rfl
    exact hX.notMem_span_image (s := {k | k ≠ j}) (x := j) (by simp) (by simpa using hrest)
  have hrr : r ⬝ᵥ r ≠ 0 := fun h => hr0 (dotProduct_self_eq_zero.mp h)
  -- r lies in the column space: r = X v
  have hmem : (fun i => X i j) - r ∈
      Submodule.span ℝ (Set.range (fun k : Fin p => fun i : Fin n => X i k)) :=
    Submodule.span_mono (Set.image_subset_range _ _) hrest
  obtain ⟨w, hw⟩ := (Submodule.mem_span_range_iff_exists_fun ℝ).mp hmem
  have hXw : X *ᵥ w = (fun i => X i j) - r := by
    rw [← hw]; funext i
    simp [mulVec, dotProduct, Finset.sum_apply, mul_comm]
  set v : Fin p → ℝ := Pi.single j 1 - w
  have hv : X *ᵥ v = r := by
    simp only [v, mulVec_sub, mulVec_single_one, hXw]
    funext i; simp
  have hXtr : Xᵀ *ᵥ r = Pi.single j (r ⬝ᵥ r) := by
    funext k
    by_cases hk : k = j
    · subst hk
      rw [Pi.single_eq_same, ← hjr]
      simp [mulVec, dotProduct]
    · rw [Pi.single_eq_of_ne hk, ← hperp k hk]
      simp [mulVec, dotProduct, mul_comm]
  set b := ((Xᵀ * X)⁻¹ * Xᵀ) *ᵥ y with hb
  have hGb : (Xᵀ * X) *ᵥ b = Xᵀ *ᵥ y := by
    rw [hb, mulVec_mulVec, ← Matrix.mul_assoc, mul_nonsing_inv _ hG, Matrix.one_mul]
  have hry : r ⬝ᵥ y = b j * (r ⬝ᵥ r) := by
    rw [← hv, gm_adj, ← hGb, ← mulVec_mulVec, ← gm_adj, hv, dotProduct_comm, gm_adj, hXtr,
      dotProduct_single]
  rw [hry, mul_div_assoc, div_self hrr, mul_one]

/-! The card's worked numbers: the entries of `XᵀX` and `Xᵀy` for the twelve sales. Areas in
square metres, ages in years, prices in thousands of dollars. Distances are written in tenths of
a kilometre (0.5 km is 5), so a sum with one distance factor is 10 times the card's number and
the sum of squared distances is 100 times it. -/

-- First row of XᵀX: 12 sales; areas add to 1301, ages to 226, distances to 21.50 km.
example : 62 + 75 + 80 + 88 + 95 + 104 + 110 + 118 + 125 + 136 + 148 + 160 = 1301 := by norm_num
example : 35 + 12 + 28 + 5 + 40 + 18 + 8 + 30 + 15 + 22 + 10 + 3 = 226 := by norm_num
example : 5 + 18 + 6 + 14 + 9 + 26 + 10 + 15 + 30 + 22 + 24 + 36 = 215 := by norm_num
-- Area row: area against area 151103, against age 22669, against distance 2585.50.
example : 62 * 62 + 75 * 75 + 80 * 80 + 88 * 88 + 95 * 95 + 104 * 104 + 110 * 110 + 118 * 118
    + 125 * 125 + 136 * 136 + 148 * 148 + 160 * 160 = 151103 := by norm_num
example : 62 * 35 + 75 * 12 + 80 * 28 + 88 * 5 + 95 * 40 + 104 * 18 + 110 * 8 + 118 * 30
    + 125 * 15 + 136 * 22 + 148 * 10 + 160 * 3 = 22669 := by norm_num
example : 62 * 5 + 75 * 18 + 80 * 6 + 88 * 14 + 95 * 9 + 104 * 26 + 110 * 10 + 118 * 15
    + 125 * 30 + 136 * 22 + 148 * 24 + 160 * 36 = 25855 := by norm_num
-- Age row: age against age 5884, against distance 326.90.
example : 35 * 35 + 12 * 12 + 28 * 28 + 5 * 5 + 40 * 40 + 18 * 18 + 8 * 8 + 30 * 30
    + 15 * 15 + 22 * 22 + 10 * 10 + 3 * 3 = 5884 := by norm_num
example : 35 * 5 + 12 * 18 + 28 * 6 + 5 * 14 + 40 * 9 + 18 * 26 + 8 * 10 + 30 * 15
    + 15 * 30 + 22 * 22 + 10 * 24 + 3 * 36 = 3269 := by norm_num
-- Distance row: distance against distance 49.19.
example : 5 * 5 + 18 * 18 + 6 * 6 + 14 * 14 + 9 * 9 + 26 * 26 + 10 * 10 + 15 * 15
    + 30 * 30 + 22 * 22 + 24 * 24 + 36 * 36 = 4919 := by norm_num
-- Xᵀy: prices add to 2532; area against price 292290, age 43288, distance 4902.
example : 124 + 140 + 172 + 200 + 180 + 171 + 260 + 210 + 226 + 250 + 301 + 298 = 2532 := by
  norm_num
example : 62 * 124 + 75 * 140 + 80 * 172 + 88 * 200 + 95 * 180 + 104 * 171 + 110 * 260
    + 118 * 210 + 125 * 226 + 136 * 250 + 148 * 301 + 160 * 298 = 292290 := by norm_num
example : 35 * 124 + 12 * 140 + 28 * 172 + 5 * 200 + 40 * 180 + 18 * 171 + 8 * 260
    + 30 * 210 + 15 * 226 + 22 * 250 + 10 * 301 + 3 * 298 = 43288 := by norm_num
example : 5 * 124 + 18 * 140 + 6 * 172 + 14 * 200 + 9 * 180 + 26 * 171 + 10 * 260
    + 15 * 210 + 30 * 226 + 22 * 250 + 24 * 301 + 36 * 298 = 49020 := by norm_num

#print axioms gauss_markov_least_squares_best_linear_unbiased
#print axioms least_squares_unbiased_and_covariance
#print axioms least_squares_coefficient_eq_slope_on_leftover
