-- Method of moments: for positive data with nonzero spread, exactly one gamma law has the sample's mean and average square, namely shape x̄²/v and rate x̄/v, because the gamma law's k-th moment is α(α+1)…(α+k−1)/λ^k; and the delta-method variance of the moment shape collapses to 2α(α+1).
import Mathlib.Probability.Distributions.Gamma
import Mathlib.Analysis.SpecialFunctions.Gamma.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory Real

/-- Gamma at `a + k` is the rising product times Gamma at `a`. -/
theorem gamma_add_nat_eq_prod_mul_gamma {a : ℝ} (ha : 0 < a) (k : ℕ) :
    Gamma (a + k) = (∏ j ∈ Finset.range k, (a + j)) * Gamma a := by
  induction k with
  | zero => simp
  | succ k ih =>
    have hne : a + (k : ℝ) ≠ 0 := by positivity
    rw [Nat.cast_succ, ← add_assoc, Gamma_add_one hne, ih, Finset.prod_range_succ]
    ring

#print axioms gamma_add_nat_eq_prod_mul_gamma

/-- The gamma law's moments as formulas in its dials (Step 1). For a gamma law with shape
`α > 0` and rate `r > 0` (the card's λ), the k-th moment (the average of `X^k`) is
`α(α+1)⋯(α+k−1) / r^k`, for every whole number `k`. -/
theorem gamma_moment_eq_rising_product_div_rate_pow {α r : ℝ} (hα : 0 < α) (hr : 0 < r)
    (k : ℕ) :
    ∫ x, x ^ k ∂(gammaMeasure α r) = (∏ j ∈ Finset.range k, (α + j)) / r ^ k := by
  have hmeas : Measurable (gammaPDF α r) := (measurable_gammaPDFReal α r).ennreal_ofReal
  rw [gammaMeasure, integral_withDensity_eq_integral_toReal_smul hmeas
    (ae_of_all _ fun _ => ENNReal.ofReal_lt_top)]
  have h1 : (fun x : ℝ => (gammaPDF α r x).toReal • x ^ k) =
      Set.indicator (Set.Ici 0)
        (fun x : ℝ => r ^ α / Gamma α * x ^ (α - 1) * exp (-(r * x)) * x ^ k) := by
    funext x
    rw [gammaPDF, ENNReal.toReal_ofReal (gammaPDFReal_nonneg hα hr x), smul_eq_mul]
    by_cases hx : 0 ≤ x
    · simp [gammaPDFReal, hx]
    · simp [gammaPDFReal, hx]
  rw [h1, integral_indicator measurableSet_Ici, integral_Ici_eq_integral_Ioi]
  have h2 : ∫ x in Set.Ioi (0 : ℝ), r ^ α / Gamma α * x ^ (α - 1) * exp (-(r * x)) * x ^ k =
      ∫ x in Set.Ioi (0 : ℝ), r ^ α / Gamma α * (x ^ ((α + k) - 1) * exp (-(r * x))) := by
    refine setIntegral_congr_fun measurableSet_Ioi fun x (hx : 0 < x) => ?_
    have : x ^ ((α + k) - 1) = x ^ (α - 1) * x ^ k := by
      rw [show (α + k) - 1 = (α - 1) + (k : ℝ) by ring, rpow_add hx, rpow_natCast]
    rw [this]; ring
  have hak : 0 < α + k := by positivity
  rw [h2, integral_const_mul, integral_rpow_mul_exp_neg_mul_Ioi hak hr,
    gamma_add_nat_eq_prod_mul_gamma hα k]
  have hG : Gamma α ≠ 0 := (Gamma_pos_of_pos hα).ne'
  rw [div_rpow zero_le_one hr.le, one_rpow, rpow_add hr, rpow_natCast]
  have hra : r ^ α ≠ 0 := (rpow_pos_of_pos hr α).ne'
  have hrk : r ^ k ≠ 0 := pow_ne_zero _ hr.ne'
  field_simp

/-- The method of moments for the gamma law. Take `n ≥ 1` positive observations `x_1, …, x_n`
with sample mean `x̄ = (1/n) ∑ x_i`, second moment `m₂ = (1/n) ∑ x_i²` and variance
`v = m₂ − x̄²` (dividing by `n`), and suppose `v > 0`. Then a gamma law with shape `α > 0` and
rate `r > 0` (the card's λ) has mean `x̄` and second moment `m₂` exactly when `α = x̄²/v` and `r = x̄/v`; and
these two numbers are positive, so exactly one gamma law matches the sample's two moments. -/
theorem gamma_method_of_moments_unique_fit {n : ℕ} (hn : 0 < n) (x : Fin n → ℝ)
    (hpos : ∀ i, 0 < x i)
    (hv : 0 < (∑ i, x i ^ 2) / n - ((∑ i, x i) / n) ^ 2) :
    let xbar := (∑ i, x i) / n
    let m2 := (∑ i, x i ^ 2) / n
    let v := m2 - xbar ^ 2
    (0 < xbar ^ 2 / v ∧ 0 < xbar / v) ∧
      ∀ α r : ℝ, 0 < α → 0 < r →
        ((∫ y, y ∂(gammaMeasure α r)) = xbar ∧ (∫ y, y ^ 2 ∂(gammaMeasure α r)) = m2 ↔
          α = xbar ^ 2 / v ∧ r = xbar / v) := by
  intro xbar m2 v
  have hxbar : 0 < xbar := by
    have : 0 < ∑ i, x i := Finset.sum_pos (fun i _ => hpos i) ⟨⟨0, hn⟩, Finset.mem_univ _⟩
    exact div_pos this (by exact_mod_cast hn)
  have hv' : 0 < v := hv
  refine ⟨⟨by positivity, by positivity⟩, fun α r hα hr => ?_⟩
  have h1 : ∫ y, y ∂(gammaMeasure α r) = α / r := by
    simpa using gamma_moment_eq_rising_product_div_rate_pow hα hr 1
  have h2 : ∫ y, y ^ 2 ∂(gammaMeasure α r) = α * (α + 1) / r ^ 2 := by
    simpa [Finset.prod_range_succ] using gamma_moment_eq_rising_product_div_rate_pow hα hr 2
  have hvdef : v = m2 - xbar ^ 2 := rfl
  rw [h1, h2]
  clear_value xbar m2 v
  subst hvdef
  constructor
  · rintro ⟨ha, hb⟩
    subst ha
    have hm : m2 - (α / r) ^ 2 = α / r ^ 2 := by rw [← hb]; field_simp; ring
    rw [hm]
    constructor <;> field_simp
  · rintro ⟨ha, hb⟩
    have hne : (m2 - xbar ^ 2) ≠ 0 := hv'.ne'
    have hx0 : xbar ≠ 0 := hxbar.ne'
    subst ha hb
    constructor
    · field_simp
    · field_simp; ring

/-- How far off, by the slopes of the solution (Step 4). Write `μ_k` for the gamma law's k-th
moment and `d = μ₂ − μ₁²`. The moment shape is `g = μ₁²/d`, with slopes `2μ₁μ₂/d²` in `μ₁` and
`−μ₁²/d²` in `μ₂`. The delta-method quadratic form
(slope₁)² Var(X) + 2 (slope₁)(slope₂) Cov(X, X²) + (slope₂)² Var(X²)
equals `2α(α+1)` for every gamma law with shape `α > 0` and rate `r > 0` (the card's λ). -/
theorem gamma_moment_shape_delta_variance {α r : ℝ} (hα : 0 < α) (hr : 0 < r) :
    let μ : ℕ → ℝ := fun k => ∫ x, x ^ k ∂(gammaMeasure α r)
    let d := μ 2 - μ 1 ^ 2
    let s₁ := 2 * μ 1 * μ 2 / d ^ 2
    let s₂ := -(μ 1 ^ 2) / d ^ 2
    s₁ ^ 2 * (μ 2 - μ 1 ^ 2) + 2 * s₁ * s₂ * (μ 3 - μ 1 * μ 2) + s₂ ^ 2 * (μ 4 - μ 2 ^ 2) =
      2 * α * (α + 1) := by
  intro μ d s₁ s₂
  have hμ : ∀ k, μ k = (∏ j ∈ Finset.range k, (α + j)) / r ^ k :=
    fun k => gamma_moment_eq_rising_product_div_rate_pow hα hr k
  have hd : d = α / r ^ 2 := by
    simp only [d, hμ, Finset.prod_range_succ, Finset.prod_range_zero]
    push_cast; field_simp; ring
  simp only [s₁, s₂, hd]
  simp only [hμ, Finset.prod_range_succ, Finset.prod_range_zero]
  push_cast
  field_simp
  ring

/-! The ten claims, in thousands of dollars: 0.5, 1, 1, 2, 2.5, 3, 3.5, 3.5, 5, 8. -/

-- Sum 30, mean 3; sum of squares 135, second moment 13.5; variance 4.5.
example : ([1/2, 1, 1, 2, 5/2, 3, 7/2, 7/2, 5, 8] : List ℚ).sum = 30 := by norm_num
example : ([1/4, 1, 1, 4, 25/4, 9, 49/4, 49/4, 25, 64] : List ℚ).sum = 135 := by norm_num
example : (1/2 : ℚ) ^ 2 = 1/4 ∧ (5/2 : ℚ) ^ 2 = 25/4 ∧ (7/2 : ℚ) ^ 2 = 49/4 := by norm_num
example : (30 : ℚ) / 10 = 3 ∧ (135 : ℚ) / 10 = 27/2 ∧ (27/2 : ℚ) - 3 ^ 2 = 9/2 := by norm_num

-- Shape 3²/4.5 = 2, rate 3/4.5 = 2/3 per $1,000, scale 4.5/3 = 1.5 ($1,500).
example : (3 : ℚ) ^ 2 / (9/2) = 2 ∧ (3 : ℚ) / (9/2) = 2/3 ∧ (9/2 : ℚ) / 3 = 3/2 := by norm_num

-- The fitted law returns the sample's moments: α/r = 3 and α(α+1)/r² = 13.5.
example : (2 : ℚ) / (2/3) = 3 ∧ (2 : ℚ) * (2 + 1) / (2/3) ^ 2 = 27/2 := by norm_num

-- Squared standard error of the shape: 2 × 2 × 3 / 10 = 1.2.
example : (2 : ℚ) * 2 * 3 / 10 = 6/5 := by norm_num

-- Step 4's bracket at shape 2: 4α(α+1)² − 8α(α+1)² + α(α+1)(4α+6) = 12 = 2α(α+1).
example : (4 * 2 * 3 ^ 2 - 8 * 2 * 3 ^ 2 + 2 * 3 * (4 * 2 + 6) : ℤ) = 12 ∧ (2 * 2 * 3 : ℤ) = 12 := by
  norm_num

-- One dial: the exponential rate is 1 over the mean, 1/3; the poll gives 520/1000 = 0.52.
example : (1 : ℚ) / 3 = 1/3 ∧ (520 : ℚ) / 1000 = 13/25 := by norm_num

-- The $8,000 claim is 64 of the 135 in the sum of squares.
example : (8 : ℚ) ^ 2 = 64 := by norm_num

-- Rate read as scale: shape 2 times 2/3 gives an average claim of 4/3 ($1,333), not 3.
example : (2 : ℚ) * (2/3) = 4/3 := by norm_num

-- Dividing the variance by n − 1: (135 − 90)/9 = 5, shape 9/5 = 1.80.
example : ((135 : ℚ) - 10 * 3 ^ 2) / 9 = 5 ∧ (3 : ℚ) ^ 2 / 5 = 9/5 := by norm_num

-- A $40,000 claim joins: sum 70, sum of squares 1735, n = 11, shape 980/2837 (0.3454).
example : (30 : ℚ) + 40 = 70 ∧ (135 : ℚ) + 40 ^ 2 = 1735 := by norm_num
example : ((70 : ℚ) / 11) ^ 2 / ((1735 : ℚ) / 11 - ((70 : ℚ) / 11) ^ 2) = 980 / 2837 := by norm_num

#print axioms gamma_moment_eq_rising_product_div_rate_pow
#print axioms gamma_method_of_moments_unique_fit
#print axioms gamma_moment_shape_delta_variance
