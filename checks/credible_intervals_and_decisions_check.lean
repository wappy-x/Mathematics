-- Credible intervals and decisions: under a flat prior a credible recipe's coverage averages to its level, the posterior mean minimizes expected squared loss, and the Beta(8, 4) area up to any point is a binomial tail.
import Mathlib.Probability.Moments.Variance
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Data.Nat.Choose.Basic

open MeasureTheory ProbabilityTheory Finset

/-- Average coverage equals the credible level. With `n` flips and a flat prior,
the posterior for `x` heads has density `(n + 1) * C(n, x) * θ^x * (1 - θ)^(n - x)` on `[0, 1]`.
If, for every count `x`, the interval `[lo x, hi x]` inside `[0, 1]` holds share `1 - α`
of that posterior, then the recipe's coverage at a fixed chance `θ`
(the chance of a count whose interval contains `θ`), averaged over the flat prior,
is exactly `1 - α`. -/
theorem credible_coverage_averages_to_level (n : ℕ) (α : ℝ) (lo hi : ℕ → ℝ)
    (h_lo : ∀ x, 0 ≤ lo x) (h_le : ∀ x, lo x ≤ hi x) (h_hi : ∀ x, hi x ≤ 1)
    (h_mass : ∀ x ∈ range (n + 1),
      ∫ θ in lo x..hi x, ((n : ℝ) + 1) * (n.choose x : ℝ) * θ ^ x * (1 - θ) ^ (n - x) = 1 - α) :
    ∫ θ in (0 : ℝ)..1,
      ∑ x ∈ range (n + 1),
        Set.indicator (Set.Icc (lo x) (hi x))
          (fun t => (n.choose x : ℝ) * t ^ x * (1 - t) ^ (n - x)) θ = 1 - α := by
  have hc : ∀ x, Continuous (fun t : ℝ => (n.choose x : ℝ) * t ^ x * (1 - t) ^ (n - x)) := by
    intro x; fun_prop
  rw [intervalIntegral.integral_finsetSum (fun x _ => by
    rw [intervalIntegrable_iff_integrableOn_Icc_of_le zero_le_one]
    exact ((hc x).integrableOn_Icc).indicator measurableSet_Icc)]
  have step : ∀ x ∈ range (n + 1),
      ∫ θ in (0:ℝ)..1, Set.indicator (Set.Icc (lo x) (hi x))
          (fun t => (n.choose x : ℝ) * t ^ x * (1 - t) ^ (n - x)) θ = (1 - α) / ((n:ℝ) + 1) := by
    intro x hx
    rw [intervalIntegral.integral_of_le zero_le_one, setIntegral_indicator measurableSet_Icc]
    have hae : (Set.Ioc (0:ℝ) 1 ∩ Set.Icc (lo x) (hi x) : Set ℝ) =ᵐ[volume] Set.Icc (lo x) (hi x) := by
      have h1 : (Set.Ioc (0:ℝ) 1 ∩ Set.Icc (lo x) (hi x) : Set ℝ) =ᵐ[volume]
          (Set.Icc (0:ℝ) 1 ∩ Set.Icc (lo x) (hi x) : Set ℝ) :=
        Ioc_ae_eq_Icc.inter (Filter.EventuallyEq.refl _ _)
      have h2 : (Set.Icc (0:ℝ) 1 ∩ Set.Icc (lo x) (hi x) : Set ℝ) = Set.Icc (lo x) (hi x) :=
        Set.inter_eq_right.mpr (Set.Icc_subset_Icc (h_lo x) (h_hi x))
      rw [h2] at h1; exact h1
    rw [setIntegral_congr_set hae, integral_Icc_eq_integral_Ioc,
      ← intervalIntegral.integral_of_le (h_le x)]
    have hm := h_mass x hx
    have e : (fun θ : ℝ => ((n : ℝ) + 1) * (n.choose x : ℝ) * θ ^ x * (1 - θ) ^ (n - x)) =
        fun θ => ((n : ℝ) + 1) * ((n.choose x : ℝ) * θ ^ x * (1 - θ) ^ (n - x)) := by
      funext θ; ring
    rw [e, intervalIntegral.integral_const_mul] at hm
    have hpos : ((n:ℝ) + 1) ≠ 0 := by positivity
    field_simp
    linarith
  rw [Finset.sum_congr rfl step, Finset.sum_const, card_range, nsmul_eq_mul]
  push_cast
  have hpos : ((n:ℝ) + 1) ≠ 0 := by positivity
  field_simp

/-- Reporting one number under squared loss: for any posterior law `μ` on the line with a
finite second moment, the expected squared miss of a report `d` is the posterior variance
plus the squared distance from `d` to the posterior mean, so the posterior mean gives the
smallest expected squared loss. -/
theorem posterior_mean_minimizes_squared_loss (μ : Measure ℝ) [IsProbabilityMeasure μ]
    (h2 : MemLp id 2 μ) :
    (∀ d : ℝ, ∫ θ, (d - θ) ^ 2 ∂μ = variance id μ + (d - ∫ θ, θ ∂μ) ^ 2) ∧
    (∀ d : ℝ, ∫ θ, ((∫ s, s ∂μ) - θ) ^ 2 ∂μ ≤ ∫ θ, (d - θ) ^ 2 ∂μ) := by
  have hi1 : Integrable (fun θ : ℝ => θ) μ := h2.integrable one_le_two
  have hi2 : Integrable (fun θ : ℝ => θ ^ 2) μ := h2.integrable_sq
  have key : ∀ d : ℝ, ∫ θ, (d - θ) ^ 2 ∂μ = variance id μ + (d - ∫ θ, θ ∂μ) ^ 2 := by
    intro d
    rw [variance_eq_sub h2]
    have e : (fun θ : ℝ => (d - θ) ^ 2) = fun θ => (d ^ 2 - 2 * d * θ) + θ ^ 2 := by
      funext θ; ring
    have ha : Integrable (fun θ : ℝ => d ^ 2 - 2 * d * θ) μ :=
      (integrable_const _).sub (hi1.const_mul _)
    rw [e, integral_add ha hi2,
      integral_sub (integrable_const _) (hi1.const_mul _), integral_const_mul, integral_const]
    simp only [Pi.pow_apply, id]
    simp
    ring
  refine ⟨key, fun d => ?_⟩
  rw [key, key d]
  simp
  positivity

/-- The area up to any point, by counting: the Beta(8, 4) posterior (7 heads in 10 flips,
flat prior) has density `1320 θ^7 (1 - θ)^3`, and its area from 0 to any mark `t` equals the
chance that at least 8 of 11 uniform points fall at or below `t`. -/
theorem beta_8_4_area_eq_binomial_tail (t : ℝ) :
    ∫ θ in (0 : ℝ)..t, (1320 : ℝ) * θ ^ 7 * (1 - θ) ^ 3 =
      ∑ j ∈ Icc 8 11, ((Nat.choose 11 j : ℕ) : ℝ) * t ^ j * (1 - t) ^ (11 - j) := by
  have hF : ∀ x ∈ Set.uIcc (0:ℝ) t, HasDerivAt
      (fun θ : ℝ => 165 * θ ^ 8 - 440 * θ ^ 9 + 396 * θ ^ 10 - 120 * θ ^ 11)
      ((1320 : ℝ) * x ^ 7 * (1 - x) ^ 3) x := by
    intro x _
    have := (((((hasDerivAt_pow 8 x).const_mul (165:ℝ)).sub
      ((hasDerivAt_pow 9 x).const_mul (440:ℝ))).add
      ((hasDerivAt_pow 10 x).const_mul (396:ℝ))).sub
      ((hasDerivAt_pow 11 x).const_mul (120:ℝ)))
    convert this using 1
    push_cast
    ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hF (by
    apply Continuous.intervalIntegrable; fun_prop)]
  have : Icc 8 11 = ({8, 9, 10, 11} : Finset ℕ) := by decide
  rw [this]
  simp [Finset.sum_insert, Nat.choose]
  ring

-- The density's constant: 1/B(8, 4) = 11 * C(10, 7) = 1320.
example : 11 * Nat.choose 10 7 = 1320 := by decide

-- The counts in Step 1: C(11, 8), C(11, 9), C(11, 10), C(11, 11).
example : Nat.choose 11 8 = 165 ∧ Nat.choose 11 9 = 55 ∧ Nat.choose 11 10 = 11 ∧
    Nat.choose 11 11 = 1 := by decide

-- F(1/2) = (165 + 55 + 11 + 1) / 2048 = 232 / 2048 = 29/256.
example : 165 + 55 + 11 + 1 = 232 ∧ 2 ^ 11 = 2048 := by decide
example : ((165 + 55 + 11 + 1 : ℚ) / 2048) = 29 / 256 := by norm_num

-- Posterior mean 8/(8 + 4) = 2/3 and variance 8 * 4 / (12^2 * 13) = 2/117.
example : ((8 : ℚ) / (8 + 4)) = 2 / 3 := by norm_num
example : ((8 * 4 : ℚ) / ((8 + 4) ^ 2 * (8 + 4 + 1))) = 2 / 117 := by norm_num

-- Bet heads: 10 (2m - 1) = 10/3 dollars a flip; heads wins $8, tails loses $10: 18m - 10 = 2;
-- the payout that breaks even is 10 (1 - m) / m = 5.
example : (10 : ℚ) * (2 * (2 / 3) - 1) = 10 / 3 := by norm_num
example : (18 : ℚ) * (2 / 3) - 10 = 2 := by norm_num
example : (10 : ℚ) * (1 - 2 / 3) / (2 / 3) = 5 := by norm_num

-- Plugging in the observed share 7/10 instead: 10 (2 * 7/10 - 1) = 4 dollars a flip.
example : (10 : ℚ) * (2 * (7 / 10) - 1) = 4 := by norm_num

#print axioms credible_coverage_averages_to_level
#print axioms posterior_mean_minimizes_squared_loss
#print axioms beta_8_4_area_eq_binomial_tail
