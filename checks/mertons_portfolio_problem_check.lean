-- Merton's problem: the certainty-equivalent growth rate r + π(μ - r) - ½γσ²π² of a constant share π is a hill whose single top is the Merton fraction (μ - r)/(γσ²), any other share loses exactly ½γσ² times the squared gap, with no borrowing or shorting the best share is that fraction clipped to [0, 1], and the card's example numbers check out.
import Mathlib.Data.Real.Basic
import Mathlib.Order.Interval.Set.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.FieldSimp

namespace MertonsPortfolioProblem

/-! Setting. `r` is the bank rate, `μ` the fund's expected return (drift), `σ` its volatility,
and `γ` the saver's relative risk aversion, all constants per year. The card shows (Steps 2 to 4)
that, for a saver with power utility facing a fund that follows geometric Brownian motion, the
expected rate of change of utility under a share `π` is a positive factor `W^(1-γ)` times the
certainty-equivalent growth rate `g(π) = r + π(μ - r) - ½γσ²π²`, and that the HJB bracket is
the same hill at every date and wealth. Mathlib has no Itô calculus, so the file checks the
exact algebraic core the card's proof rests on: the hill, its top, the squared-gap loss used in
the verification step (Step 4), and the clipped answer when borrowing and shorting are banned. -/

/-- The Merton fraction `π* = (μ - r) / (γ σ²)`. -/
noncomputable def mertonFraction (r μ σ γ : ℝ) : ℝ := (μ - r) / (γ * σ ^ 2)

/-- The certainty-equivalent growth rate of keeping the constant share `π` in the fund:
`g(π) = r + π(μ - r) - ½ γ σ² π²`. -/
noncomputable def ceGrowth (r μ σ γ π : ℝ) : ℝ := r + π * (μ - r) - (1 / 2) * γ * σ ^ 2 * π ^ 2

/-- Helper: the hill written around its top. -/
theorem ceGrowth_eq_top_sub (r μ σ γ π : ℝ) (hγ : 0 < γ) (hσ : 0 < σ) :
    ceGrowth r μ σ γ π = ceGrowth r μ σ γ (mertonFraction r μ σ γ)
      - (1 / 2) * γ * σ ^ 2 * (π - mertonFraction r μ σ γ) ^ 2 := by
  have hk : γ * σ ^ 2 ≠ 0 := by positivity
  have hμ : μ - r = γ * σ ^ 2 * mertonFraction r μ σ γ := by
    rw [mertonFraction]; field_simp
  unfold ceGrowth
  rw [hμ]; ring

/-- The card's main claim. For a saver with positive risk aversion `γ` and a fund with positive
volatility `σ`, the Merton fraction `(μ - r)/(γσ²)` gives the highest certainty-equivalent growth
rate of any share of wealth (borrowing and short selling allowed, so any real share), and it is
the only share that does: the hill has one top. -/
theorem merton_fraction_is_the_unique_best_share (r μ σ γ : ℝ) (hγ : 0 < γ) (hσ : 0 < σ) :
    ∀ π : ℝ, ceGrowth r μ σ γ π ≤ ceGrowth r μ σ γ (mertonFraction r μ σ γ) ∧
      (ceGrowth r μ σ γ π = ceGrowth r μ σ γ (mertonFraction r μ σ γ) →
        π = mertonFraction r μ σ γ) := by
  intro π
  have h := ceGrowth_eq_top_sub r μ σ γ π hγ hσ
  have hk : 0 < γ * σ ^ 2 := by positivity
  have hsq : 0 ≤ (π - mertonFraction r μ σ γ) ^ 2 := sq_nonneg _
  refine ⟨by nlinarith, fun he => ?_⟩
  have h0 : (π - mertonFraction r μ σ γ) ^ 2 = 0 := by
    have : γ * σ ^ 2 * (π - mertonFraction r μ σ γ) ^ 2 = 0 := by linarith
    rcases mul_eq_zero.mp this with h1 | h1
    · exact absurd h1 hk.ne'
    · exact h1
  have := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp h0
  linarith

/-- What the best plan is worth, and what straying costs (Steps 4 and 5). The best rate is
`g* = r + (μ - r)²/(2γσ²)`, and any share `π` falls short of it by exactly `½ γ σ² (π - π*)²`,
the square of the gap times half of risk aversion times variance. -/
theorem shortfall_is_half_gamma_sigma_sq_times_squared_gap (r μ σ γ : ℝ) (hγ : 0 < γ)
    (hσ : 0 < σ) :
    ceGrowth r μ σ γ (mertonFraction r μ σ γ) = r + (μ - r) ^ 2 / (2 * γ * σ ^ 2) ∧
      ∀ π : ℝ, ceGrowth r μ σ γ π - ceGrowth r μ σ γ (mertonFraction r μ σ γ) =
        -((1 / 2) * γ * σ ^ 2 * (π - mertonFraction r μ σ γ) ^ 2) := by
  refine ⟨?_, fun π => ?_⟩
  · have hk : γ * σ ^ 2 ≠ 0 := by positivity
    unfold ceGrowth mertonFraction
    field_simp
    ring
  · rw [ceGrowth_eq_top_sub r μ σ γ π hγ hσ]; ring

/-- If borrowing and short selling are both forbidden, so the share must lie between 0 and 1,
the best feasible share is the Merton fraction clipped to between 0 and 1, and no other feasible
share does as well. -/
theorem clipped_merton_fraction_is_best_without_borrowing_or_shorting (r μ σ γ : ℝ)
    (hγ : 0 < γ) (hσ : 0 < σ) :
    max 0 (min 1 (mertonFraction r μ σ γ)) ∈ Set.Icc (0 : ℝ) 1 ∧
      ∀ π ∈ Set.Icc (0 : ℝ) 1,
        ceGrowth r μ σ γ π ≤ ceGrowth r μ σ γ (max 0 (min 1 (mertonFraction r μ σ γ))) ∧
          (ceGrowth r μ σ γ π = ceGrowth r μ σ γ (max 0 (min 1 (mertonFraction r μ σ γ))) →
            π = max 0 (min 1 (mertonFraction r μ σ γ))) := by
  set m := mertonFraction r μ σ γ with hm
  have hk : 0 < γ * σ ^ 2 := by positivity
  have key : ∀ x, ceGrowth r μ σ γ x = ceGrowth r μ σ γ m - (1 / 2) * γ * σ ^ 2 * (x - m) ^ 2 :=
    fun x => ceGrowth_eq_top_sub r μ σ γ x hγ hσ
  have hc : max 0 (min 1 m) ∈ Set.Icc (0 : ℝ) 1 :=
    ⟨le_max_left _ _, max_le (by norm_num) (min_le_left _ _)⟩
  refine ⟨hc, fun π hπ => ?_⟩
  obtain ⟨h0, h1⟩ := hπ
  -- distance comparison
  have hd : (max 0 (min 1 m) - m) ^ 2 ≤ (π - m) ^ 2 ∧
      ((max 0 (min 1 m) - m) ^ 2 = (π - m) ^ 2 → π = max 0 (min 1 m)) := by
    rcases le_total m 0 with hm0 | hm0
    · have hc0 : max 0 (min 1 m) = 0 := by
        rw [min_eq_right (by linarith)]; exact max_eq_left hm0
      rw [hc0]
      refine ⟨by nlinarith, fun he => ?_⟩
      nlinarith
    · rcases le_total m 1 with hm1 | hm1
      · have hcm : max 0 (min 1 m) = m := by
          rw [min_eq_right hm1]; exact max_eq_right hm0
        rw [hcm]
        refine ⟨by nlinarith [sq_nonneg (π - m)], fun he => ?_⟩
        have : (π - m) ^ 2 = 0 := by simpa using he.symm
        have := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp this
        linarith
      · have hc1 : max 0 (min 1 m) = 1 := by
          rw [min_eq_left hm1]; exact max_eq_right (by norm_num)
        rw [hc1]
        refine ⟨by nlinarith, fun he => ?_⟩
        nlinarith
  obtain ⟨hle, heq⟩ := hd
  refine ⟨?_, fun he => heq ?_⟩
  · rw [key π, key (max 0 (min 1 m))]
    nlinarith [mul_le_mul_of_nonneg_left hle hk.le]
  · rw [key π, key (max 0 (min 1 m))] at he
    have : γ * σ ^ 2 * ((max 0 (min 1 m) - m) ^ 2 - (π - m) ^ 2) = 0 := by linarith
    rcases mul_eq_zero.mp this with h | h
    · exact absurd h hk.ne'
    · linarith

/-! The card's worked numbers, as exact fractions: bank 2%, fund 6%, volatility 20%,
risk aversion 2. -/

-- Risk aversion times variance: 2 × 0.04 = 0.08.
example : (2 : ℝ) * (20 / 100) ^ 2 = 8 / 100 := by norm_num
-- The Merton fraction: 0.04 / 0.08 = one half.
example : mertonFraction (2 / 100) (6 / 100) (20 / 100) 2 = 1 / 2 := by
  norm_num [mertonFraction]
-- Dollars in the fund today: half of $100,000.
example : (1 / 2 : ℝ) * 100000 = 50000 := by norm_num
-- Premium kept after the risk charge: 0.04² / (2 × 0.08) = 0.01.
example : ((6 / 100 : ℝ) - 2 / 100) ^ 2 / (2 * 2 * (20 / 100) ^ 2) = 1 / 100 := by norm_num
-- Best certainty-equivalent rate g* = 0.02 + 0.01 = 0.03.
example : ceGrowth (2 / 100) (6 / 100) (20 / 100) 2 (1 / 2) = 3 / 100 := by
  norm_num [ceGrowth]
-- All in the bank and all in the fund give the same rate, 2 percent.
example : ceGrowth (2 / 100) (6 / 100) (20 / 100) 2 0 = 2 / 100 := by norm_num [ceGrowth]
example : ceGrowth (2 / 100) (6 / 100) (20 / 100) 2 1 = 2 / 100 := by norm_num [ceGrowth]
-- One input at a time: risk aversion 1, 4; volatility 15%, 30%; excess return 2%, 6%.
example : mertonFraction (2 / 100) (6 / 100) (20 / 100) 1 = 1 := by norm_num [mertonFraction]
example : mertonFraction (2 / 100) (6 / 100) (20 / 100) 4 = 1 / 4 := by norm_num [mertonFraction]
example : mertonFraction (2 / 100) (6 / 100) (15 / 100) 2 = 8 / 9 := by norm_num [mertonFraction]
example : mertonFraction (2 / 100) (6 / 100) (30 / 100) 2 = 2 / 9 := by norm_num [mertonFraction]
example : mertonFraction (2 / 100) (4 / 100) (20 / 100) 2 = 1 / 4 := by norm_num [mertonFraction]
example : mertonFraction (2 / 100) (8 / 100) (20 / 100) 2 = 3 / 4 := by norm_num [mertonFraction]
-- Try changing: volatility 10% gives 200 percent; drift 10% gives 100 percent.
example : mertonFraction (2 / 100) (6 / 100) (10 / 100) 2 = 2 := by norm_num [mertonFraction]
example : mertonFraction (2 / 100) (10 / 100) (20 / 100) 2 = 1 := by norm_num [mertonFraction]
-- The usual slips: volatility for variance gives 10%; total return for excess gives 75%.
example : ((6 / 100 : ℝ) - 2 / 100) / (2 * (20 / 100)) = 1 / 10 := by norm_num
example : (6 / 100 : ℝ) / (2 * (20 / 100) ^ 2) = 3 / 4 := by norm_num

#print axioms ceGrowth_eq_top_sub
#print axioms merton_fraction_is_the_unique_best_share
#print axioms shortfall_is_half_gamma_sigma_sq_times_squared_gap
#print axioms clipped_merton_fraction_is_best_without_borrowing_or_shorting

end MertonsPortfolioProblem
