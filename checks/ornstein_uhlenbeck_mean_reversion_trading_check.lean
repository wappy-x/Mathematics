-- Mean reversion: a fitted daily slope β converts back to a pull speed κ = −ln β and a level θ = α/(1 − β) exactly when 0 < β < 1, the expected gap then shrinks by e^(−κ) a day and halves at h = ln 2/κ, and the steady scatter is sd(ε)/√(1 − β²) = σ/√(2κ).
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Independence.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open MeasureTheory ProbabilityTheory

/-- **The fitted line maps back to the model, and only for a slope strictly between 0 and 1
(Step 2).** The daily OU step is the line `X (t + 1) = α + β · X t + noise` with
`β = e^(−κ)` and `α = (1 − β) · θ`, for a pull speed `κ > 0` and a level `θ`.
Given a fitted intercept `α` and slope `β`, a pull speed and level producing them exist
exactly when `0 < β < 1`, and then they are unique: `κ = −ln β` and `θ = α / (1 − β)`.
A slope of 1 or more, or of 0 or less, comes from no OU process at all. -/
theorem ou_line_maps_back_iff_slope_in_unit_interval (α β κ θ : ℝ) :
    (0 < κ ∧ β = Real.exp (-κ) ∧ α = (1 - β) * θ) ↔
      (0 < β ∧ β < 1 ∧ κ = -Real.log β ∧ θ = α / (1 - β)) := by
  constructor
  · rintro ⟨hκ, hβ, hα⟩
    have hb0 : 0 < β := hβ ▸ Real.exp_pos _
    have hb1 : β < 1 := by rw [hβ]; exact Real.exp_lt_one_iff.mpr (by linarith)
    have hne : (1 - β) ≠ 0 := by linarith
    refine ⟨hb0, hb1, ?_, ?_⟩
    · rw [hβ, Real.log_exp]; ring
    · rw [hα]; field_simp
  · rintro ⟨hb0, hb1, hκ, hθ⟩
    have hne : (1 - β) ≠ 0 := by linarith
    have hlog : Real.log β < 0 := Real.log_neg hb0 hb1
    refine ⟨by linarith, ?_, ?_⟩
    · rw [hκ, neg_neg, Real.exp_log hb0]
    · rw [hθ]; field_simp

/-- **The expected gap shrinks by a fixed share a day and halves every half-life (Step 3).**
On a probability space, let the spread follow the daily OU step
`X (t + 1) = θ + e^(−κ) · (X t − θ) + ε (t + 1)` with pull speed `κ > 0`, an integrable
start `X 0`, and integrable fresh noise `ε (t + 1)` that averages zero. Then the expected
gap after `n` days is the starting expected gap times `e^(−κ n)`, and the factor `e^(−κ h)`
equals one half exactly at the half-life `h = ln 2 / κ`. -/
theorem ou_expected_gap_halves_at_half_life {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X ε : ℕ → Ω → ℝ) (κ θ : ℝ) (hκ : 0 < κ)
    (hX0 : Integrable (X 0) P)
    (hε : ∀ t, Integrable (ε (t + 1)) P)
    (hmean : ∀ t, ∫ ω, ε (t + 1) ω ∂P = 0)
    (hstep : ∀ t ω, X (t + 1) ω = θ + Real.exp (-κ) * (X t ω - θ) + ε (t + 1) ω) :
    (∀ n : ℕ, (∫ ω, X n ω ∂P) - θ = Real.exp (-κ * n) * ((∫ ω, X 0 ω ∂P) - θ)) ∧
      ∀ h : ℝ, Real.exp (-κ * h) = 1 / 2 ↔ h = Real.log 2 / κ := by
  have hint : ∀ n, Integrable (X n) P := by
    intro n
    induction n with
    | zero => exact hX0
    | succ t ih =>
      have : X (t + 1) = fun ω => θ + Real.exp (-κ) * (X t ω - θ) + ε (t + 1) ω := by
        funext ω; exact hstep t ω
      rw [this]
      exact ((integrable_const θ).add ((ih.sub (integrable_const θ)).const_mul _)).add (hε t)
  refine ⟨?_, ?_⟩
  · intro n
    induction n with
    | zero => simp
    | succ t ih =>
      have : X (t + 1) = fun ω => θ + Real.exp (-κ) * (X t ω - θ) + ε (t + 1) ω := by
        funext ω; exact hstep t ω
      have h2 : Integrable (fun ω => Real.exp (-κ) * (X t ω - θ)) P :=
        ((hint t).sub (integrable_const θ)).const_mul _
      have h1 : Integrable (fun ω => θ + Real.exp (-κ) * (X t ω - θ)) P :=
        (integrable_const θ).add h2
      have e1 := integral_add h1 (hε t)
      have e2 := integral_add (integrable_const θ) h2
      have e3 := integral_sub (hint t) (integrable_const θ)
      rw [this]
      beta_reduce
      rw [e1, e2, integral_const_mul, e3, hmean t]
      simp only [integral_const, probReal_univ, smul_eq_mul, one_mul]
      have he : Real.exp (-κ * ((t + 1 : ℕ) : ℝ)) = Real.exp (-κ * t) * Real.exp (-κ) := by
        rw [← Real.exp_add]; push_cast; ring_nf
      rw [he]; linear_combination Real.exp (-κ) * ih
  · intro h
    constructor
    · intro hh
      have := congrArg Real.log hh
      rw [Real.log_exp, one_div, Real.log_inv] at this
      field_simp
      linarith
    · intro hh
      rw [hh]
      have : -κ * (Real.log 2 / κ) = Real.log (1 / 2) := by
        rw [one_div, Real.log_inv]; field_simp
      rw [this, Real.exp_log (by norm_num)]

/-- **The long-run scatter balances shrinkage against fresh noise (Step 4).** On a
probability space, let today's spread `X` and tomorrow's fresh noise `ε` be independent with
finite variance, and let the slope satisfy `0 < β < 1`. If the spread has settled, so that
tomorrow's spread `α + β · X + ε` has the same variance as today's, then the long-run
standard deviation is `s = sd(ε) / √(1 − β²)`. If moreover `β = e^(−κ)` with `κ > 0` and the
noise has the exact OU variance `σ² (1 − e^(−2κ)) / (2κ)`, then `s² = σ² / (2κ)`. -/
theorem ou_steady_scatter {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X ε : Ω → ℝ) (α β : ℝ)
    (hX : MemLp X 2 P) (hε : MemLp ε 2 P) (hind : IndepFun X ε P)
    (hβ : 0 < β ∧ β < 1)
    (hsteady : variance (fun ω => α + β * X ω + ε ω) P = variance X P) :
    Real.sqrt (variance X P) = Real.sqrt (variance ε P) / Real.sqrt (1 - β ^ 2) ∧
      ∀ κ σ : ℝ, 0 < κ → β = Real.exp (-κ) →
        variance ε P = σ ^ 2 * (1 - Real.exp (-2 * κ)) / (2 * κ) →
        variance X P = σ ^ 2 / (2 * κ) := by
  obtain ⟨hb0, hb1⟩ := hβ
  have hvar : variance (fun ω => α + β * X ω + ε ω) P = β ^ 2 * variance X P + variance ε P := by
    have e1 : (fun ω => α + β * X ω + ε ω) = fun ω => α + (β * X ω + ε ω) := by
      funext ω; ring
    have hind' : IndepFun (fun ω => β * X ω) ε P :=
      hind.comp (φ := fun x => β * x) (ψ := id) (measurable_const_mul β) measurable_id
    rw [e1, variance_const_add (X := fun ω => β * X ω + ε ω) ((hX.const_mul β).aestronglyMeasurable.add hε.aestronglyMeasurable),
      hind'.variance_fun_add (hX.const_mul β) hε, variance_const_mul]
  rw [hvar] at hsteady
  have hpos : 0 < 1 - β ^ 2 := by nlinarith
  have hVX : variance X P = variance ε P / (1 - β ^ 2) := by
    field_simp; linarith
  refine ⟨?_, ?_⟩
  · rw [hVX, Real.sqrt_div' _ hpos.le]
  · intro κ σ hκ hβe hε2
    have hb2 : β ^ 2 = Real.exp (-2 * κ) := by
      rw [hβe, ← Real.exp_nat_mul]; ring_nf
    have hne : 1 - Real.exp (-2 * κ) ≠ 0 := by rw [← hb2]; linarith
    rw [hVX, hε2, hb2, div_right_comm, mul_div_assoc, div_self hne, mul_one]

-- The card's trade: level $10, long-run scatter $2, entry at z = 2.
-- Short entry θ + 2s = 14, long entry θ − 2s = 6.
example : (10 : ℤ) + 2 * 2 = 14 := by norm_num
example : (10 : ℤ) - 2 * 2 = 6 := by norm_num
-- Today's $14 reading is a gap of $4, which is z = 4 / 2 = 2; reaching the level gains $4.
example : (14 : ℚ) - 10 = 4 ∧ ((14 : ℚ) - 10) / 2 = 2 := by norm_num
-- Twelve days on (one half-life, factor 1/2): expected spread 10 + 4 × 1/2 = 12.
example : (10 : ℚ) + 4 * (1 / 2) = 12 := by norm_num
-- Its standard deviation 2 × √(1 − (1/2)²) = √3, about 1.7321: the variance is 4 × 3/4 = 3.
example : (2 : ℚ) ^ 2 * (1 - (1 / 2) ^ 2) = 3 := by norm_num
-- After two half-lives (day 24) the expected spread is 10 + 4 × 1/4 = 11.
example : (10 : ℚ) + 4 * (1 / 2) ^ 2 = 11 := by norm_num

#print axioms ou_line_maps_back_iff_slope_in_unit_interval
#print axioms ou_expected_gap_halves_at_half_life
#print axioms ou_steady_scatter
