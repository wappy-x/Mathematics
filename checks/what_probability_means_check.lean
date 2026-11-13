-- Probability: ticket prices that are not chances summing to 1 can be beaten in every weather while coherent ones cannot, the Brier score is lowest exactly at the honest forecast, and every probability lies between 0 and 1 with the chances of an event and its opposite summing to 1.
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

/-! Two tickets each pay 1 dollar: the rain ticket costs `a`, the no-rain ticket costs `b`.
A holding is `h` rain tickets and `k` no-rain tickets, whole numbers, negative meaning sold.
It costs `h * a + k * b`, so it nets `h - (h * a + k * b)` if it rains and
`k - (h * a + k * b)` if it stays dry.
A Dutch book is a holding that nets more than 0 in both weathers.

The Brier score of an announced chance `q`, when the true chance is `p`, is the average
squared miss `p * (1 - q) ^ 2 + (1 - p) * q ^ 2`. -/

/-- The Brier score: announcing the chance `q` when the true chance is `p`
costs `(1 - q) ^ 2` on a rainy day and `q ^ 2` on a dry one, weighed by how often each happens. -/
def brier (p q : ℝ) : ℝ := p * (1 - q) ^ 2 + (1 - p) * q ^ 2

/-- Incoherent prices lose for sure, coherent ones cannot be beaten:
some holding of rain and no-rain tickets wins in both weathers exactly when the prices
are not chances, that is, unless both prices are at least 0 and they sum to 1. -/
theorem dutch_book_iff_prices_not_coherent (a b : ℝ) :
    (∃ h k : ℤ, 0 < (h : ℝ) - (h * a + k * b) ∧ 0 < (k : ℝ) - (h * a + k * b)) ↔
      ¬ (0 ≤ a ∧ 0 ≤ b ∧ a + b = 1) := by
  constructor
  · rintro ⟨h, k, hr, hd⟩ ⟨ha, hb, hab⟩
    set c : ℝ := (h : ℝ) * a + (k : ℝ) * b with hc
    have key : a * ((h : ℝ) - c) + b * ((k : ℝ) - c) = 0 := by
      have : a * ((h : ℝ) - c) + b * ((k : ℝ) - c) = c - c * (a + b) := by rw [hc]; ring
      rw [this, hab]; ring
    rcases lt_or_eq_of_le ha with ha' | ha'
    · have h1 : 0 < a * ((h : ℝ) - c) := mul_pos ha' hr
      have h2 : 0 ≤ b * ((k : ℝ) - c) := mul_nonneg hb hd.le
      linarith
    · have hb' : 0 < b := by linarith
      have h1 : 0 ≤ a * ((h : ℝ) - c) := mul_nonneg ha hr.le
      have h2 : 0 < b * ((k : ℝ) - c) := mul_pos hb' hd
      linarith
  · intro hn
    by_cases ha : a < 0
    · exact ⟨1, 0, by push_cast; linarith, by push_cast; linarith⟩
    by_cases hb : b < 0
    · exact ⟨0, 1, by push_cast; linarith, by push_cast; linarith⟩
    push_neg at ha hb
    rcases lt_trichotomy (a + b) 1 with h | h | h
    · exact ⟨1, 1, by push_cast; linarith, by push_cast; linarith⟩
    · exact absurd ⟨ha, hb, h⟩ hn
    · exact ⟨-1, -1, by push_cast; linarith, by push_cast; linarith⟩

/-- Honest forecasts score best: the Brier score splits as `p * (1 - p) + (q - p) ^ 2`,
so announcing the true chance `p` scores strictly lower than announcing any other `q`. -/
theorem brier_lowest_at_true_chance (p q : ℝ) :
    brier p q = p * (1 - p) + (q - p) ^ 2 ∧ (q ≠ p → brier p p < brier p q) := by
  have e : brier p q = p * (1 - p) + (q - p) ^ 2 := by unfold brier; ring
  refine ⟨e, fun hq => ?_⟩
  have e' : brier p p = p * (1 - p) := by unfold brier; ring
  have hpos : 0 < (q - p) ^ 2 :=
    lt_of_le_of_ne (sq_nonneg _) (Ne.symm (pow_ne_zero 2 (sub_ne_zero.mpr hq)))
  rw [e, e']
  linarith

/-- The rules every reading obeys: for a probability measure `μ` and an event `A`,
the chance of `A` lies between 0 and 1, and the chance of `A` plus the chance of
not `A` is 1. -/
theorem probability_rules {Ω : Type*} [MeasurableSpace Ω] (μ : MeasureTheory.Measure Ω)
    [MeasureTheory.IsProbabilityMeasure μ] {A : Set Ω} (hA : MeasurableSet A) :
    0 ≤ μ.real A ∧ μ.real A ≤ 1 ∧ μ.real A + μ.real Aᶜ = 1 := by
  exact ⟨ENNReal.toReal_nonneg, MeasureTheory.measureReal_le_one,
    MeasureTheory.probReal_add_probReal_compl hA⟩

/-! The card's worked numbers, exactly, with the 30 percent chance written as 3/10. -/

-- The chance of no rain: 1 - 3/10 = 7/10.
example : (1 : ℚ) - 3 / 10 = 7 / 10 := by norm_num
-- Odds against rain: (7/10) / (3/10) = 7/3, that is 7 to 3.
example : ((7 : ℚ) / 10) / (3 / 10) = 7 / 3 := by norm_num
-- Fair bet, stake 3 to win 7: 3/10 * 7 - 7/10 * 3 = 0.
example : (3 : ℚ) / 10 * 7 - 7 / 10 * 3 = 0 := by norm_num
-- Back from odds to a chance: 3 wins in 3 + 7 cases is 3/10, not 3/7.
example : (3 : ℚ) / (3 + 7) = 3 / 10 ∧ (3 : ℚ) / 7 ≠ 3 / 10 := by norm_num
-- The bookmaker's prices, 30 and 60 cents: buying both nets 10 cents in either weather.
example : (1 : ℚ) - (3 / 10 + 6 / 10) = 1 / 10 := by norm_num
example : (1 : ℝ) - (1 * (3 / 10) + 1 * (6 / 10)) = 1 / 10 := by norm_num
-- Brier score with true chance 3/10: honest 21/100, announcing 1/2 gives 1/4, announcing 0 gives 3/10.
example : brier (3 / 10) (3 / 10) = 21 / 100 := by norm_num [brier]
example : brier (3 / 10) (1 / 2) = 1 / 4 := by norm_num [brier]
example : brier (3 / 10) 0 = 3 / 10 := by norm_num [brier]
-- Squared misses of the honest forecast: 49/100 if rain, 9/100 if dry.
example : (1 - (3 : ℚ) / 10) ^ 2 = 49 / 100 ∧ ((3 : ℚ) / 10) ^ 2 = 9 / 100 := by norm_num
-- The plain miss rewards exaggeration: with true chance 3/10, announcing 0 averages 3/10,
-- below the 21/50 that the honest 3/10 averages.
example : (3 : ℚ) / 10 * (1 - 0) + 7 / 10 * 0 = 3 / 10 ∧
    (3 : ℚ) / 10 * (1 - 3 / 10) + 7 / 10 * (3 / 10) = 21 / 50 := by norm_num

#print axioms dutch_book_iff_prices_not_coherent
#print axioms brier_lowest_at_true_chance
#print axioms probability_rules
