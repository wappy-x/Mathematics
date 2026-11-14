-- Extreme value theory: past a rising threshold, the excess of a regularly varying (power-law) loss tends to a generalised Pareto law, and the generalised Pareto VaR formula is the unique solution of the stitched tail equation.
import Mathlib.Probability.ConditionalProbability
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.MeasureTheory.Constructions.BorelSpace.Real

open MeasureTheory ProbabilityTheory Filter Topology

/-- Heavy-tailed case of the Balkema–de Haan–Pickands theorem (card, Step 2).
If the chance that the loss `L` passes `x` is `x ^ (-α) * ℓ x` for every `x` above some floor,
with `α > 0` and `ℓ` slowly varying (`ℓ (t x) / ℓ x → 1` for every fixed `t > 0`), then for every
`s ≥ 0` the chance that the loss passes the threshold `u` by more than `s * u`, given that it passes
`u`, tends to `(1 + s) ^ (-α)` as the threshold rises: the generalised Pareto law with shape
`1/α` and scale `u/α`. -/
theorem excess_over_threshold_tends_to_generalised_pareto
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (L : Ω → ℝ) (hL : Measurable L)
    (α : ℝ) (hα : 0 < α)
    (ℓ : ℝ → ℝ) (hℓ : ∀ t : ℝ, 0 < t → Tendsto (fun x => ℓ (t * x) / ℓ x) atTop (𝓝 1))
    (x₀ : ℝ) (htail : ∀ x : ℝ, x₀ ≤ x → (P {ω | x < L ω}).toReal = x ^ (-α) * ℓ x)
    (s : ℝ) (hs : 0 ≤ s) :
    Tendsto (fun u : ℝ => (P[{ω | s * u < L ω - u} | {ω | u < L ω}]).toReal) atTop
      (𝓝 ((1 + s) ^ (-α))) := by
  have key : ∀ u : ℝ, max x₀ 1 ≤ u →
      (P[{ω | s * u < L ω - u} | {ω | u < L ω}]).toReal
        = (1 + s) ^ (-α) * (ℓ ((1 + s) * u) / ℓ u) := by
    intro u hu
    have hu1 : 1 ≤ u := le_trans (le_max_right _ _) hu
    have hux : x₀ ≤ u := le_trans (le_max_left _ _) hu
    have hu0 : 0 < u := by linarith
    have hsu : 0 ≤ s * u := mul_nonneg hs hu0.le
    have hmeas : MeasurableSet {ω | u < L ω} := measurableSet_lt measurable_const hL
    have hset : {ω | u < L ω} ∩ {ω | s * u < L ω - u} = {ω | (1 + s) * u < L ω} := by
      ext ω
      simp only [Set.mem_inter_iff, Set.mem_ofPred_eq]
      constructor
      · rintro ⟨_, h⟩; linarith
      · intro h; constructor <;> linarith
    rw [cond_apply hmeas, hset, ENNReal.toReal_mul, ENNReal.toReal_inv,
      htail u hux, htail ((1 + s) * u) (by linarith),
      Real.mul_rpow (by linarith) hu0.le]
    have hpos : (0:ℝ) < u ^ (-α) := Real.rpow_pos_of_pos hu0 _
    by_cases hℓ0 : ℓ u = 0
    · simp [hℓ0]
    · field_simp
  have hlim := (hℓ (1 + s) (by linarith)).const_mul ((1 + s) ^ (-α))
  rw [mul_one] at hlim
  refine hlim.congr' ?_
  filter_upwards [eventually_ge_atTop (max x₀ 1)] with u hu
  exact (key u hu).symm

/-- An exact power law gives a generalised Pareto exactly (card, Step 1).
If the chance that the loss passes `x` is `C * x ^ (-α)` for every `x` above a floor `x₀`,
with `C > 0` and `α > 0`, then for every threshold `u > 0` above the floor and every excess
`y ≥ 0`, the chance that the loss passes `u` by more than `y`, given that it passes `u`, is
`(1 + ξ y / β) ^ (-1/ξ)` with shape `ξ = 1/α` and scale `β = u/α`. -/
theorem power_tail_excess_is_generalised_pareto
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (L : Ω → ℝ) (hL : Measurable L)
    (α C x₀ : ℝ) (hα : 0 < α) (hC : 0 < C)
    (htail : ∀ x : ℝ, x₀ ≤ x → (P {ω | x < L ω}).toReal = C * x ^ (-α))
    (u : ℝ) (hu0 : 0 < u) (hux : x₀ ≤ u) (y : ℝ) (hy : 0 ≤ y) :
    (P[{ω | y < L ω - u} | {ω | u < L ω}]).toReal
      = (1 + (1 / α) * y / (u / α)) ^ (-1 / (1 / α)) := by
  have hmeas : MeasurableSet {ω | u < L ω} := measurableSet_lt measurable_const hL
  have hset : {ω | u < L ω} ∩ {ω | y < L ω - u} = {ω | u + y < L ω} := by
    ext ω
    simp only [Set.mem_inter_iff, Set.mem_ofPred_eq]
    constructor
    · rintro ⟨_, h⟩; linarith
    · intro h; constructor <;> linarith
  rw [cond_apply hmeas, hset, ENNReal.toReal_mul, ENNReal.toReal_inv,
    htail u hux, htail (u + y) (by linarith)]
  have hα0 : α ≠ 0 := hα.ne'
  have e1 : (1 / α) * y / (u / α) = y / u := by field_simp
  have e2 : -1 / (1 / α) = -α := by rw [one_div, div_inv_eq_mul]; ring
  have e3 : 1 + y / u = (u + y) / u := by field_simp
  rw [e1, e2, e3, Real.div_rpow (by linarith) hu0.le]
  have hpos : 0 < u ^ (-α) := Real.rpow_pos_of_pos hu0 _
  field_simp

/-- The VaR formula (card, Step 5). For a fitted generalised Pareto tail with scale `β > 0` and
shape `ξ ≠ 0`, stitched to the crossing rate `f = k/n`, and a target chance `q = 1 - p` with
`0 < q < f`, the loss `u + β/ξ * ((q/f) ^ (-ξ) - 1)` lies past the threshold, inside the support,
solves `f * (1 + ξ (x - u)/β) ^ (-1/ξ) = q`, and is the only such solution. -/
theorem gpd_var_formula_unique_solution
    (u β ξ f q : ℝ) (hβ : 0 < β) (hξ : ξ ≠ 0) (hq : 0 < q) (hqf : q < f) :
    let v := u + β / ξ * ((q / f) ^ (-ξ) - 1)
    u ≤ v ∧ 0 < 1 + ξ * (v - u) / β ∧ f * (1 + ξ * (v - u) / β) ^ (-1 / ξ) = q ∧
      ∀ x : ℝ, u ≤ x → 0 < 1 + ξ * (x - u) / β →
        f * (1 + ξ * (x - u) / β) ^ (-1 / ξ) = q → x = v := by
  dsimp only
  have hf : 0 < f := lt_trans hq hqf
  set r := q / f with hr
  have hr0 : 0 < r := div_pos hq hf
  have hr1 : r < 1 := (div_lt_one hf).2 hqf
  have hw : 1 + ξ * (u + β / ξ * (r ^ (-ξ) - 1) - u) / β = r ^ (-ξ) := by
    field_simp; ring
  have hR : 0 < r ^ (-ξ) := Real.rpow_pos_of_pos hr0 _
  refine ⟨?_, ?_, ?_, ?_⟩
  · have : 0 ≤ β / ξ * (r ^ (-ξ) - 1) := by
      rcases lt_or_gt_of_ne hξ with h | h
      · have h1 : r ^ (-ξ) < 1 := Real.rpow_lt_one hr0.le hr1 (by linarith)
        exact mul_nonneg_of_nonpos_of_nonpos (div_neg_of_pos_of_neg hβ h).le (by linarith)
      · have h1 : 1 < r ^ (-ξ) :=
          Real.one_lt_rpow_of_pos_of_lt_one_of_neg hr0 hr1 (by linarith)
        exact mul_nonneg (div_pos hβ h).le (by linarith)
    linarith
  · rw [hw]; exact hR
  · rw [hw, ← Real.rpow_mul hr0.le, show -ξ * (-1 / ξ) = 1 by field_simp, Real.rpow_one, hr]
    field_simp
  · intro x _ hwx hx'
    have h1 : (1 + ξ * (x - u) / β) ^ (-1 / ξ) = r := by
      rw [hr, eq_div_iff hf.ne']; linarith
    have h2 : 1 + ξ * (x - u) / β = r ^ (-ξ) := by
      rw [← h1, ← Real.rpow_mul hwx.le, show -1 / ξ * -ξ = 1 by field_simp, Real.rpow_one]
    rw [← h2]
    field_simp
    ring

-- The card's whole-number arithmetic, checked exactly.
-- Crossing rate k/n: 126 of 2,520 days is one in twenty (0.05).
example : (126 : ℚ) / 2520 = 1 / 20 := by norm_num
-- Rarity ratio: (1 - p)/(k/n) = 0.001 / 0.05 = 0.02, one in fifty.
example : ((1 : ℚ) / 1000) / ((126 : ℚ) / 2520) = 1 / 50 := by norm_num
-- Expected days past the 99.9% VaR in 2,520 days: 2.52.
example : (2520 : ℚ) * (1 / 1000) = 252 / 100 := by norm_num
-- True shape for the Student t law with 4 degrees of freedom: ξ = 1/α = 1/4 (0.25).
example : (1 : ℚ) / 4 = 25 / 100 := by norm_num
-- The 99.9% historical VaR is the third-worst day: 0-based rank ⌈2520 · 999/1000⌉ - 1 = 2517 of 2520.
example : (2520 * 999 + 999) / 1000 - 1 = 2517 ∧ 2520 - 2517 = 3 := by decide
-- The threshold with k = 126 exceedances is the 127th-worst day: 0-based rank n - k - 1.
example : 2520 - 126 - 1 = 2393 ∧ 2520 - 2393 = 127 := by decide

#print axioms excess_over_threshold_tends_to_generalised_pareto
#print axioms power_tail_excess_is_generalised_pareto
#print axioms gpd_var_formula_unique_solution
