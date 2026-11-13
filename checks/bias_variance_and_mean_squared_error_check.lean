-- Bias and variance: the mean squared error of any guess with a finite variance equals its variance plus its squared bias, the shrunk average c·X̄ of independent readings scores c²σ²/n + (1 − c)²μ², and it beats the plain average exactly when μ² < (σ²/n)(1 + c)/(1 − c).
import Mathlib.Probability.Moments.Variance

open MeasureTheory ProbabilityTheory

/-- **Mean squared error equals variance plus squared bias.** Let `T` be any rule for
guessing a number `θ`, seen as a random variable on a probability space, with finite
variance (its square has a finite average). Then its mean squared error, the average of
`(T − θ)²`, equals its variance plus the square of its bias `E[T] − θ`. No independence,
no bell curve and no particular sample size are needed. -/
theorem mse_eq_variance_add_bias_sq {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (T : Ω → ℝ) (θ : ℝ) (hT : MemLp T 2 P) :
    ∫ ω, (T ω - θ) ^ 2 ∂P = variance T P + (∫ ω, T ω ∂P - θ) ^ 2 := by
  have hint : Integrable T P := hT.integrable one_le_two
  have hsq : Integrable (fun ω => T ω ^ 2) P := hT.integrable_sq
  rw [variance_eq_sub hT]
  have hexp : (fun ω => (T ω - θ) ^ 2) = fun ω => (T ω ^ 2 - 2 * θ * T ω) + θ ^ 2 := by
    ext ω; ring
  have h2 : Integrable (fun ω => T ω ^ 2 - 2 * θ * T ω) P := hsq.sub (hint.const_mul _)
  rw [hexp, integral_add h2 (integrable_const _),
    integral_sub hsq (hint.const_mul _), integral_const_mul, integral_const]
  simp only [Pi.pow_apply, probReal_univ, smul_eq_mul, one_mul]
  ring

/-- **The mean squared error of the shrunk average (Steps 2 and 3).** Let `X 0, …, X (n−1)`
be `n ≥ 1` independent readings, each with average `μ` (the true offset) and variance `σ²`,
and with finite variance. For any fixed shrink factor `c`, the rule `c · X̄`, where `X̄` is
the readings' average, has mean squared error `c² σ²/n + (1 − c)² μ²` about `μ`. With
`c = 1` this is the plain average's `σ²/n`. -/
theorem mse_of_shrunk_average {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (n : ℕ) (hn : n ≠ 0) (X : Fin n → Ω → ℝ) (μ σ c : ℝ)
    (hind : iIndepFun X P)
    (hL2 : ∀ i, MemLp (X i) 2 P)
    (hmean : ∀ i, ∫ ω, X i ω ∂P = μ)
    (hvar : ∀ i, variance (X i) P = σ ^ 2) :
    ∫ ω, (c * ((∑ i, X i ω) / n) - μ) ^ 2 ∂P = c ^ 2 * (σ ^ 2 / n) + (1 - c) ^ 2 * μ ^ 2 := by
  have hS : MemLp (fun ω => ∑ i, X i ω) 2 P := memLp_finsetSum _ (fun i _ => hL2 i)
  have hY : MemLp (fun ω => c * ((∑ i, X i ω) / n)) 2 P := by
    have := hS.const_mul (c / n)
    convert this using 1
    ext ω; ring
  have hnR : (n : ℝ) ≠ 0 := Nat.cast_ne_zero.mpr hn
  rw [mse_eq_variance_add_bias_sq _ μ hY]
  have hvarS : variance (∑ i, X i) P = n * σ ^ 2 := by
    rw [IndepFun.variance_sum (fun i _ => hL2 i)
      (fun i _ j _ hij => hind.indepFun hij)]
    simp [hvar]
  have hvarY : variance (fun ω => c * ((∑ i, X i ω) / n)) P = (c / n) ^ 2 * (n * σ ^ 2) := by
    have : (fun ω => c * ((∑ i, X i ω) / n)) = fun ω => (c / n) * (∑ i, X i) ω := by
      ext ω; simp [Finset.sum_apply]; ring
    rw [this, variance_const_mul, hvarS]
  have hEY : ∫ ω, c * ((∑ i, X i ω) / n) ∂P = c * μ := by
    rw [integral_const_mul, integral_div, integral_finsetSum _ (fun i _ =>
      (hL2 i).integrable one_le_two)]
    simp [hmean]
    field_simp
    simp
  rw [hvarY, hEY]
  field_simp
  ring

/-- **Where shrinking pays (Step 4).** For a fixed shrink factor `c ≠ 1`, the shrunk rule's
score `c² σ²/n + (1 − c)² μ²` is below the plain average's `σ²/n` exactly when
`μ² < (σ²/n) · (1 + c)/(1 − c)`. -/
theorem shrunk_beats_average_iff (μ σ c : ℝ) (n : ℕ) (hc : c ≠ 1) :
    c ^ 2 * (σ ^ 2 / n) + (1 - c) ^ 2 * μ ^ 2 < σ ^ 2 / n ↔
      μ ^ 2 < σ ^ 2 / n * ((1 + c) / (1 - c)) := by
  have h1 : 1 - c ≠ 0 := sub_ne_zero.mpr (Ne.symm hc)
  have hpos : 0 < (1 - c) ^ 2 := by positivity
  set v := σ ^ 2 / n
  have hr : v * ((1 + c) / (1 - c)) = v * (1 + c) * (1 - c) / (1 - c) ^ 2 := by
    field_simp
  rw [hr, lt_div_iff₀ hpos]
  constructor <;> intro h <;> nlinarith

-- The card's record: readings 503, 499, 505, 501 g on a 500 g weight.
example : ((503 : ℤ) - 500, (499 : ℤ) - 500, (505 : ℤ) - 500, (501 : ℤ) - 500) = (3, -1, 5, 1) := by
  decide
-- Their average error is 2 g.
example : ((3 : ℤ) + -1 + 5 + 1) / 4 = 2 := by decide
-- Squared distances from that average add to S = 20.
example : ((3 : ℤ) - 2) ^ 2 + (-1 - 2) ^ 2 + (5 - 2) ^ 2 + (1 - 2) ^ 2 = 20 := by decide
-- Variance of the average: σ²/n = 16/4 = 4.
example : (16 : ℚ) / 4 = 4 := by norm_num
-- MSE of the shrunk rule at μ = 2, c = 4/5: 64/25 + 4/25 = 68/25 (that is, 2.72).
example : ((4 : ℚ) / 5) ^ 2 * (16 / 4) + (1 - 4 / 5) ^ 2 * 2 ^ 2 = 68 / 25 := by norm_num
-- Break-even offset: (σ²/n)(1 + c)/(1 − c) = 4 · 9 = 36 = 6².
example : (16 : ℚ) / 4 * ((1 + 4 / 5) / (1 - 4 / 5)) = 6 ^ 2 := by norm_num
-- At offset 6 the two rules tie; at offset 8 the shrunk rule scores 128/25 (5.12) > 4.
example : ((4 : ℚ) / 5) ^ 2 * 4 + (1 - 4 / 5) ^ 2 * 6 ^ 2 = 4 := by norm_num
example : ((4 : ℚ) / 5) ^ 2 * 4 + (1 - 4 / 5) ^ 2 * 8 ^ 2 = 128 / 25 := by norm_num
-- Best factor at μ = 2: c* = 4/(4 + 4) = 1/2, scoring 2.
example : (2 : ℚ) ^ 2 / (2 ^ 2 + 16 / 4) = 1 / 2 := by norm_num
example : ((1 : ℚ) / 2) ^ 2 * 4 + (1 - 1 / 2) ^ 2 * 2 ^ 2 = 2 := by norm_num
-- Divisor table, bell noise, n = 4, σ⁴ = 256: MSE(S/a) = 256 (2·3 + (3 − a)²)/a².
example : (256 : ℚ) * (2 * 3 + (3 - 3) ^ 2) / 3 ^ 2 = 512 / 3 := by norm_num
example : (256 : ℚ) * (2 * 3 + (3 - 4) ^ 2) / 4 ^ 2 = 112 := by norm_num
example : (256 : ℚ) * (2 * 3 + (3 - 5) ^ 2) / 5 ^ 2 = 512 / 5 := by norm_num

#print axioms mse_eq_variance_add_bias_sq
#print axioms mse_of_shrunk_average
#print axioms shrunk_beats_average_iff
