-- Basel capital: the CET1 that clears the 4.5, 6 and 8 percent minimums is at least the largest of the three shortfalls, the buffer requirement reads the same in dollars and as a ratio, and the payout table's percent edges match the dollar quarters of the buffer.
import Mathlib.Order.Bounds.Basic
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

/-! Money is in millions of dollars and rates are exact fractions.
`R` is risk-weighted assets, `C` is Common Equity Tier 1 (CET1),
`A₁` is Additional Tier 1, `T₂` is Tier 2 and `b` is the buffer rate.
The three minimums are `C ≥ 4.5% R`, `C + A₁ ≥ 6% R` and `C + A₁ + T₂ ≥ 8% R`.
`F = max (4.5% R) (6% R - A₁) (8% R - A₁ - T₂)` is the CET1 used up meeting them,
and the payout table reads `q = 4.5% + (C - F) / R`. -/

/-- The CET1 used up by the minimums: the largest of the three shortfalls. -/
noncomputable def cet1ForMinima (R A₁ T₂ : ℝ) : ℝ :=
  max (max (45 / 1000 * R) (60 / 1000 * R - A₁)) (80 / 1000 * R - A₁ - T₂)

/-- CET1 meets the minimums first: whatever the other tiers `A₁` and `T₂` are, the
amounts of CET1 that clear all three minimums (4.5 percent CET1, 6 percent Tier 1,
8 percent total capital) are exactly those at or above `F`, the largest of the three
shortfalls, so `F` is the least CET1 that clears them. -/
theorem cet1_for_minima_is_least (R A₁ T₂ : ℝ) :
    IsLeast {C : ℝ | 45 / 1000 * R ≤ C ∧ 60 / 1000 * R ≤ C + A₁ ∧ 80 / 1000 * R ≤ C + A₁ + T₂}
      (cet1ForMinima R A₁ T₂) := by
  refine ⟨⟨?_, ?_, ?_⟩, ?_⟩
  · unfold cet1ForMinima
    exact le_trans (le_max_left _ _) (le_max_left _ _)
  · unfold cet1ForMinima
    have h : 60 / 1000 * R - A₁ ≤ max (max (45 / 1000 * R) (60 / 1000 * R - A₁)) (80 / 1000 * R - A₁ - T₂) :=
      le_trans (le_max_right _ _) (le_max_left _ _)
    linarith
  · unfold cet1ForMinima
    have h : 80 / 1000 * R - A₁ - T₂ ≤ max (max (45 / 1000 * R) (60 / 1000 * R - A₁)) (80 / 1000 * R - A₁ - T₂) :=
      le_max_right _ _
    linarith
  · rintro C ⟨h1, h2, h3⟩
    unfold cet1ForMinima
    refine max_le (max_le h1 ?_) ?_ <;> linarith

/-- The buffer sits on top of the minimums: for positive risk-weighted assets `R`,
holding CET1 of at least `F + b R` in dollars is the same as a CET1 ratio `C / R`
of at least `(F + b R) / R`. -/
theorem buffer_requirement_as_ratio (R A₁ T₂ C b : ℝ) (hR : 0 < R) :
    cet1ForMinima R A₁ T₂ + b * R ≤ C ↔
      (cet1ForMinima R A₁ T₂ + b * R) / R ≤ C / R := by
  exact (div_le_div_iff_of_pos_right hR).symm

/-- The percent table and the dollar quarters are the same rule: for positive `R`,
the payout-table ratio `q = 4.5% + (C - F) / R` is at most the band edge
`4.5% + n b / 4` exactly when the CET1 left above the minimums, `C - F`,
is at most `n` quarters of the dollar buffer `b R`. -/
theorem payout_table_edge_iff_buffer_quarters (R A₁ T₂ C b : ℝ) (n : ℕ) (hR : 0 < R) :
    45 / 1000 + (C - cet1ForMinima R A₁ T₂) / R ≤ 45 / 1000 + n * (b / 4) ↔
      C - cet1ForMinima R A₁ T₂ ≤ n * (b * R / 4) := by
  rw [add_le_add_iff_left, div_le_iff₀ hR]
  constructor <;> intro h <;> linarith

/-! Worked numbers from the card, exactly. -/

-- credit RWA: 30% of 400 + 100% of 400 + 75% of 200 = 670
example : (30 / 100 : ℝ) * 400 + 1 * 400 + 75 / 100 * 200 = 670 := by norm_num

-- operational charge: 12% of a 120 business indicator is 14.40
example : (12 / 100 : ℝ) * 120 = 1440 / 100 := by norm_num

-- total RWA: 670 + 12.5 × 12 + 12.5 × 14.40 = 1,000
example : (670 : ℝ) + 25 / 2 * 12 + 25 / 2 * (1440 / 100) = 1000 := by norm_num

-- second road: 8% charges added up give 80, times 12.5 is again 1,000
example : (8 / 100 : ℝ) * 670 + 12 + 1440 / 100 = 80 ∧ (25 / 2 : ℝ) * 80 = 1000 := by norm_num

-- CET1 ratio: 120 over 1,000 is 12 percent
example : (120 : ℝ) / 1000 = 12 / 100 := by norm_num

-- F for the CET1-only bank: max(45, 60, 80) = 80
example : cet1ForMinima 1000 0 0 = 80 := by
  norm_num [cet1ForMinima, max_def]

-- F for the bank with 15 of Additional Tier 1 and 20 of Tier 2: max(45, 45, 45) = 45
example : cet1ForMinima 1000 15 20 = 45 := by
  norm_num [cet1ForMinima, max_def]

-- CET1 need: (80 + 25) / 1,000 = 10.5 percent; mixed bank: (45 + 25) / 1,000 = 7 percent
example : ((80 : ℝ) + 25 / 1000 * 1000) / 1000 = 105 / 1000 ∧
    ((45 : ℝ) + 25 / 1000 * 1000) / 1000 = 7 / 100 := by norm_num

-- cushion: 120 − 80 − 25 = 15; buffer quarter 25 / 4 = 6.25
example : (120 : ℝ) - 80 - 25 = 15 ∧ (25 : ℝ) / 4 = 625 / 100 := by norm_num

-- payout-table ratio: q = 4.5% + (120 − 80) / 1,000 = 8.5%, above 7%, so no limit
example : (45 / 1000 : ℝ) + (120 - 80) / 1000 = 85 / 1000 ∧ (7 / 100 : ℝ) < 85 / 1000 := by
  norm_num

-- a loss of exactly 15 gives q = 7.0%, which is inside the 40 percent row (not above 7%)
example : (45 / 1000 : ℝ) + (105 - 80) / 1000 = 7 / 100 := by norm_num

-- after a 20 loss, q = 6.5% is in the 40 percent row; of 10 of earnings, 6 may be paid out
example : (6375 / 100000 : ℝ) < 45 / 1000 + (100 - 80) / 1000 ∧
    (45 / 1000 : ℝ) + (100 - 80) / 1000 ≤ 7 / 100 ∧ (10 : ℝ) * (1 - 40 / 100) = 6 := by
  norm_num

-- breaking points: buffer breached at a loss of 120 − 80 − 25 = 15, minimum at 120 − 80 = 40
example : (120 : ℝ) - 80 - 25 / 1000 * 1000 = 15 ∧ (120 : ℝ) - 80 = 40 := by norm_num

-- RWA growth to breach: 120 / 10.5% = 1,000 × (1 + 1/7), RWA up by one seventh (14.29%)
example : (120 : ℝ) / (105 / 1000) = 1000 * (1 + 1 / 7) := by norm_num

-- a 1 percent countercyclical buffer: need 11.5 percent, cushion 5
example : ((80 : ℝ) + 35 / 1000 * 1000) / 1000 = 115 / 1000 ∧
    (120 : ℝ) - 80 - 35 / 1000 * 1000 = 5 := by norm_num

-- a 10 loss with 5 percent RWA growth: 110 / 1,050 is below the 10.5 percent need
example : (110 : ℝ) / (105 / 100 * 1000) < 105 / 1000 := by norm_num

-- wrong stack (7% read as the need): cushion 50 instead of 15
example : (120 : ℝ) - (45 / 1000 + 25 / 1000) * 1000 = 50 := by norm_num

#print axioms cet1_for_minima_is_least
#print axioms buffer_requirement_as_ratio
#print axioms payout_table_edge_iff_buffer_quarters
