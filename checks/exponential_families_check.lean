-- Exponential families: for a law with chance exp(η T(x) − A(η)) against a fixed base weight, the slope of A is the mean of T, its curvature is the variance, the log-likelihood is concave with its peak where model mean meets sample mean, and a same-shape prior updates by addition.
import Mathlib.Probability.Moments.Tilted
import Mathlib.Probability.Moments.Variance
import Mathlib.Analysis.Convex.Function
import Mathlib.Analysis.SpecialFunctions.Exp

open MeasureTheory ProbabilityTheory Real
open scoped ENNReal

/-- **Slope of the log-partition function is the mean; curvature is the variance.**
The base weight `h(x)` is the measure `μ` (counting weights `h(x)` for a discrete law, the
density `h(x) dx` for a continuous one), `T` is the statistic, and the log-partition function
is `A(η) = log ∑ h(x) e^{η T(x)}`, which is Mathlib's `cgf T μ η = log ∫ exp (η * T x) ∂μ`.
The only hypothesis is the card's: the total defining `A` is finite (for every parameter near
`η`, so that `A` can be differentiated there). Then the law `p(· | η)` (Mathlib's tilted measure
`μ.tilted (η * T ·)`) gives each set the chance `∫ h(x) exp (η T(x) − A(η))`, the mean of `T`
under that law is `A'(η)`, and the variance of `T` under that law is `A''(η)`. -/
theorem log_partition_slope_is_mean_and_curvature_is_variance
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) (T : Ω → ℝ) {η : ℝ}
    (hη : η ∈ interior (integrableExpSet T μ)) :
    (∀ s : Set Ω, MeasurableSet s →
        μ.tilted (η * T ·) s = ∫⁻ x in s, ENNReal.ofReal (exp (η * T x - cgf T μ η)) ∂μ) ∧
    deriv (cgf T μ) η = ∫ x, T x ∂(μ.tilted (η * T ·)) ∧
    iteratedDeriv 2 (cgf T μ) η = Var[T; μ.tilted (η * T ·)] := by
  refine ⟨fun s hs => tilted_mul_apply_cgf' hs (interior_subset (s := integrableExpSet T μ) hη),
    (integral_tilted_mul_self hη).symm, (variance_tilted_mul hη).symm⟩

/-- **The log-likelihood has at most one peak, where the model's mean matches the data's.**
For `n` observations `x 1, …, x n` with one shared natural parameter, the log-likelihood (up to
a constant) is `ℓ(η) = η ∑ T(xᵢ) − n A(η)`. It is concave on the natural parameters where the
total defining `A` is finite, and any such `η̂` at which the model mean of `T` equals the sample
mean `(1/n) ∑ T(xᵢ)` is the peak: the maximum likelihood estimate is moment matching. -/
theorem log_likelihood_concave_and_peak_at_moment_match
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) (T : Ω → ℝ) {n : ℕ} (x : Fin n → Ω) :
    ConcaveOn ℝ (interior (integrableExpSet T μ))
        (fun η => η * ∑ i, T (x i) - n * cgf T μ η) ∧
    ∀ ηhat ∈ interior (integrableExpSet T μ),
      ∫ y, T y ∂(μ.tilted (ηhat * T ·)) = (∑ i, T (x i)) / n →
      IsMaxOn (fun η => η * ∑ i, T (x i) - n * cgf T μ η)
        (interior (integrableExpSet T μ)) ηhat := by
  set D := interior (integrableExpSet T μ) with hD
  set S := ∑ i, T (x i) with hS
  have hDc : Convex ℝ D := convex_integrableExpSet.interior
  have hconv : ConvexOn ℝ D (cgf T μ) := by
    refine convexOn_of_deriv2_nonneg hDc ?_ ?_ ?_ ?_
    · exact analyticOn_cgf.continuousOn
    · rw [hD, interior_interior]; exact analyticOn_cgf.differentiableOn
    · rw [hD, interior_interior]
      exact (analyticOnNhd_cgf.deriv).differentiableOn
    · intro y hy
      rw [hD, interior_interior] at hy
      rw [← iteratedDeriv_eq_iterate, ← variance_tilted_mul hy]
      exact variance_nonneg _ _
  have hn : (0 : ℝ) ≤ n := Nat.cast_nonneg n
  refine ⟨⟨hDc, fun a ha b hb p q hp hq hpq => ?_⟩, fun ηhat hηhat hmean => ?_⟩
  · have h1 := hconv.2 ha hb hp hq hpq
    simp only [smul_eq_mul] at h1 ⊢
    have h2 := mul_le_mul_of_nonneg_left h1 hn
    nlinarith
  · have hm : (n : ℝ) * deriv (cgf T μ) ηhat = S := by
      rw [← integral_tilted_mul_self hηhat, hmean]
      rcases Nat.eq_zero_or_pos n with h0 | hpos
      · subst h0; simp [hS]
      · have : (n : ℝ) ≠ 0 := by positivity
        field_simp
    have hda : HasDerivAt (cgf T μ) (deriv (cgf T μ) ηhat) ηhat :=
      ((analyticAt_cgf hηhat).differentiableAt).hasDerivAt
    have tangent : ∀ y ∈ D, cgf T μ ηhat + deriv (cgf T μ) ηhat * (y - ηhat) ≤ cgf T μ y := by
      intro y hy
      rcases lt_trichotomy ηhat y with hlt | heq | hgt
      · have := hconv.le_slope_of_hasDerivAt hηhat hy hlt hda
        rw [slope_def_field, le_div_iff₀ (by linarith)] at this
        linarith
      · subst heq; simp
      · have := hconv.slope_le_of_hasDerivAt hy hηhat hgt hda
        rw [slope_def_field, div_le_iff₀ (by linarith)] at this
        linarith
    intro y hy
    have ht := mul_le_mul_of_nonneg_left (tangent y hy) hn
    have h3 : (n : ℝ) * deriv (cgf T μ) ηhat * (y - ηhat) = S * (y - ηhat) := by rw [hm]
    show y * S - n * cgf T μ y ≤ ηhat * S - n * cgf T μ ηhat
    nlinarith

/-- **The total is sufficient, and the conjugate prior updates by addition.** With `n`
independent observations sharing one `η`, the joint chance is `(∏ h(xᵢ)) exp (η ∑ T(xᵢ) − n A(η))`,
so `η` meets the data only through the total `∑ T(xᵢ)`. A prior of the same shape,
`exp (τ η − ν A(η))`, times this likelihood is `(∏ h(xᵢ)) exp ((τ + ∑ T(xᵢ)) η − (ν + n) A(η))`:
the data's total is added to `τ` and the sample size to `ν`. -/
theorem conjugate_prior_updates_by_addition {Ω : Type*} (A : ℝ → ℝ) (h T : Ω → ℝ)
    (τ ν η : ℝ) {n : ℕ} (x : Fin n → Ω) :
    exp (τ * η - ν * A η) * ∏ i, (h (x i) * exp (η * T (x i) - A η))
      = (∏ i, h (x i)) * exp ((τ + ∑ i, T (x i)) * η - (ν + n) * A η) := by
  rw [Finset.prod_mul_distrib, ← Real.exp_sum, mul_comm, mul_assoc, ← Real.exp_add]
  congr 2
  rw [Finset.sum_sub_distrib, ← Finset.mul_sum]
  simp only [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
  ring

/-- Week 1 and week 2 at the help desk both total 96 emails in eight hours. -/
example : 11 + 14 + 9 + 12 + 15 + 10 + 13 + 12 = 96 ∧
    6 + 18 + 12 + 12 + 20 + 4 + 12 + 12 = 96 := by
  decide

/-- Week 1's sample mean is 96 / 8 = 12, and the log-likelihood's curvature at the peak is
`-n A'' = -8 × 12 = -96`. -/
example : (96 : ℚ) / 8 = 12 ∧ -(8 : ℤ) * 12 = -96 := by
  norm_num

/-- Gamma-Poisson update: prior shape 24 and rate 2 (prior mean 24 / 2 = 12), then 28 emails
in 2 hours and 17 in 1 hour give shape 69 and rate 5, posterior mean 69 / 5. Forgetting the
3 hours gives 69 / 2 instead. A prior of shape 240 and rate 20 gives 285 / 23. -/
example : (24 : ℚ) / 2 = 12 ∧ 24 + (28 + 17) = (69 : ℕ) ∧ 2 + (2 + 1) = (5 : ℕ) ∧
    ((24 + 45 : ℚ) / (2 + 3) = 69 / 5) ∧ ((24 + 45 : ℚ) / 2 = 69 / 2) ∧
    ((240 + 45 : ℚ) / (20 + 3) = 285 / 23) := by
  norm_num

/-- The poll: 1,000 calls at share 13/25 give mean 520 and variance 1248/5; a dead-even poll
gives variance 250. -/
example : (1000 : ℚ) * (13 / 25) = 520 ∧ (1000 : ℚ) * (13 / 25) * (12 / 25) = 1248 / 5 ∧
    (1000 : ℚ) * (1 / 2) * (1 / 2) = 250 := by
  norm_num

/-- The gamma wait for 3 emails at rate 12 an hour: mean 3/12 = 1/4 hour (15 minutes),
variance 3/144 = 1/48; for one email, mean 1/12 and variance 1/144. -/
example : (3 : ℚ) / 12 = 1 / 4 ∧ 60 * ((3 : ℚ) / 12) = 15 ∧ (3 : ℚ) / 12 ^ 2 = 1 / 48 ∧
    (1 : ℚ) / 12 ^ 2 = 1 / 144 := by
  norm_num

#print axioms log_partition_slope_is_mean_and_curvature_is_variance
#print axioms log_likelihood_concave_and_peak_at_moment_match
#print axioms conjugate_prior_updates_by_addition
