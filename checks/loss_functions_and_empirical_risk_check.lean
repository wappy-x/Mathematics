-- Loss and empirical risk: for any finite list of values, the mean minimises the average squared miss with exactly a squared-distance penalty, any median minimises the average absolute miss, and log loss is lowest at the true chance, with the card's five-order example checked.
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum

open Finset Real

namespace LossAndEmpiricalRisk

/-- **Squared loss is minimised by the mean** (Step 1). Take `n ≥ 1` values `y₁, …, yₙ` and
use one fixed guess `c` for all of them. Let `ȳ` be their mean and `R(c)` the empirical risk
under squared loss, the average of `(yᵢ - c)²`. Then `R(c) = R(ȳ) + (c - ȳ)²` for every `c`,
so the mean is the one best guess and every other guess scores strictly worse. -/
theorem squared_loss_minimised_by_mean (n : ℕ) (hn : 0 < n) (y : Fin n → ℝ) :
    let ybar : ℝ := (∑ i, y i) / n
    let R : ℝ → ℝ := fun c => (∑ i, (y i - c) ^ 2) / n
    (∀ c : ℝ, R c = R ybar + (c - ybar) ^ 2) ∧ (∀ c : ℝ, c ≠ ybar → R ybar < R c) := by
  intro ybar R
  have hn' : (n : ℝ) ≠ 0 := by positivity
  have hsum : ∑ i, (y i - ybar) = 0 := by
    rw [Finset.sum_sub_distrib]
    simp only [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul, ybar]
    field_simp
    ring
  have key : ∀ c : ℝ, ∑ i, (y i - c) ^ 2 = ∑ i, (y i - ybar) ^ 2 + n * (c - ybar) ^ 2 := by
    intro c
    have h : ∀ i, (y i - c) ^ 2
        = (y i - ybar) ^ 2 + 2 * (ybar - c) * (y i - ybar) + (c - ybar) ^ 2 := fun i => by ring
    simp only [h, Finset.sum_add_distrib, ← Finset.mul_sum, hsum, Finset.sum_const,
      Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
    ring
  have h1 : ∀ c : ℝ, R c = R ybar + (c - ybar) ^ 2 := by
    intro c
    simp only [R]
    rw [key c, key ybar]
    field_simp
  refine ⟨h1, fun c hc => ?_⟩
  rw [h1 c]
  have : 0 < (c - ybar) ^ 2 := by
    have : c - ybar ≠ 0 := sub_ne_zero.mpr hc
    positivity
  linarith

/-- **Absolute loss is minimised by the median** (Step 2). Take `n` values `y₁, …, yₙ` and a
median `m`: at least half the values lie at or below `m`, and at least half at or above it
(with an even count, any guess between the two middle values is one). Then no fixed guess `c`
has a smaller average absolute miss: the average of `|yᵢ - m|` is at most the average of
`|yᵢ - c|`. -/
theorem absolute_loss_minimised_by_median (n : ℕ) (y : Fin n → ℝ) (m : ℝ)
    (hbelow : n ≤ 2 * (univ.filter (fun i => y i ≤ m)).card)
    (habove : n ≤ 2 * (univ.filter (fun i => m ≤ y i)).card) (c : ℝ) :
    (∑ i, |y i - m|) / n ≤ (∑ i, |y i - c|) / n := by
  have hn0 : (0 : ℝ) ≤ n := by positivity
  apply div_le_div_of_nonneg_right _ hn0
  rcases le_total m c with hmc | hcm
  · -- guess above the median
    have hpt : ∀ i, (c - m) * (2 * (if y i ≤ m then (1 : ℝ) else 0) - 1)
        ≤ |y i - c| - |y i - m| := by
      intro i
      by_cases h : y i ≤ m
      · simp only [h, ↓reduceIte]
        rw [ abs_of_nonpos (by linarith), abs_of_nonpos (by linarith)]
        linarith
      · simp only [h, ↓reduceIte]
        have := abs_sub_abs_le_abs_sub (y i - m) (y i - c)
        have e : y i - m - (y i - c) = c - m := by ring
        rw [e, abs_of_nonneg (show (0 : ℝ) ≤ c - m by linarith)] at this
        linarith
    have hs := Finset.sum_le_sum (fun i (_ : i ∈ (univ : Finset (Fin n))) => hpt i)
    rw [← Finset.mul_sum, Finset.sum_sub_distrib, ← Finset.mul_sum, Finset.sum_boole,
      Finset.sum_sub_distrib] at hs
    simp only [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul,
      mul_one] at hs
    have hc : (n : ℝ) ≤ 2 * ((univ.filter (fun i => y i ≤ m)).card : ℝ) := by
      exact_mod_cast hbelow
    have : 0 ≤ (c - m) * (2 * ((univ.filter (fun i => y i ≤ m)).card : ℝ) - n) :=
      mul_nonneg (by linarith) (by linarith)
    linarith
  · -- guess below the median
    have hpt : ∀ i, (m - c) * (2 * (if m ≤ y i then (1 : ℝ) else 0) - 1)
        ≤ |y i - c| - |y i - m| := by
      intro i
      by_cases h : m ≤ y i
      · simp only [h, ↓reduceIte]
        rw [ abs_of_nonneg (by linarith), abs_of_nonneg (by linarith)]
        linarith
      · simp only [h, ↓reduceIte]
        have := abs_sub_abs_le_abs_sub (y i - m) (y i - c)
        have e : y i - m - (y i - c) = c - m := by ring
        rw [e, abs_of_nonpos (show c - m ≤ (0 : ℝ) by linarith)] at this
        linarith
    have hs := Finset.sum_le_sum (fun i (_ : i ∈ (univ : Finset (Fin n))) => hpt i)
    rw [← Finset.mul_sum, Finset.sum_sub_distrib, ← Finset.mul_sum, Finset.sum_boole,
      Finset.sum_sub_distrib] at hs
    simp only [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul,
      mul_one] at hs
    have hc : (n : ℝ) ≤ 2 * ((univ.filter (fun i => m ≤ y i)).card : ℝ) := by
      exact_mod_cast habove
    have : 0 ≤ (m - c) * (2 * ((univ.filter (fun i => m ≤ y i)).card : ℝ) - n) :=
      mul_nonneg (by linarith) (by linarith)
    linarith

/-- **Log loss rewards the honest chance** (Step 5). If a yes-or-no outcome comes true with
chance `q`, strictly between 0 and 1, a forecast `p` (also strictly between 0 and 1) pays on
average `-(q ln p + (1 - q) ln (1 - p))`. Every forecast `p ≠ q` pays strictly more than the
honest forecast `p = q`: log loss is proper. -/
theorem log_loss_lowest_at_true_chance (q p : ℝ) (hq0 : 0 < q) (hq1 : q < 1)
    (hp0 : 0 < p) (hp1 : p < 1) (hpq : p ≠ q) :
    -(q * log q + (1 - q) * log (1 - q)) < -(q * log p + (1 - q) * log (1 - p)) := by
  have hq1' : 0 < 1 - q := by linarith
  have hp1' : 0 < 1 - p := by linarith
  have ha : log (p / q) < p / q - 1 :=
    Real.log_lt_sub_one_of_pos (div_pos hp0 hq0) (fun h => hpq ((div_eq_one_iff_eq hq0.ne').mp h))
  have hb : log ((1 - p) / (1 - q)) < (1 - p) / (1 - q) - 1 :=
    Real.log_lt_sub_one_of_pos (div_pos hp1' hq1')
      (fun h => hpq (by have := (div_eq_one_iff_eq hq1'.ne').mp h; linarith))
  rw [Real.log_div hp0.ne' hq0.ne'] at ha
  rw [Real.log_div hp1'.ne' hq1'.ne'] at hb
  have ha' : q * (log p - log q) < p - q := by
    have := mul_lt_mul_of_pos_left ha hq0
    rw [show q * (p / q - 1) = p - q by field_simp] at this
    linarith
  have hb' : (1 - q) * (log (1 - p) - log (1 - q)) < q - p := by
    have := mul_lt_mul_of_pos_left hb hq1'
    rw [show (1 - q) * ((1 - p) / (1 - q) - 1) = q - p by field_simp; ring] at this
    linarith
  nlinarith

/-- The card's five made-up orders, in pounds. -/
def five : Fin 5 → ℤ := ![14, 22, 27, 35, 102]

-- Mean (14 + 22 + 27 + 35 + 102) / 5 = 40.
example : ∑ i, five i = 200 ∧ (200 : ℤ) / 5 = 40 := by decide
-- 27 is the median: 3 of the 5 lie at or below it and 3 at or above it.
example : 5 ≤ 2 * (univ.filter (fun i => five i ≤ 27)).card ∧
    5 ≤ 2 * (univ.filter (fun i => 27 ≤ five i)).card := by decide
-- Squared losses at £40: 676 + 324 + 169 + 25 + 3,844 = 5,038; at £27: 169 + 25 + 0 + 64 + 5,625 = 5,883.
example : ∑ i, (five i - 40) ^ 2 = 5038 := by decide
example : ∑ i, (five i - 27) ^ 2 = 5883 := by decide
-- The £102 order alone supplies 3,844 of the 5,038.
example : (102 - 40 : ℤ) ^ 2 = 3844 := by decide
-- Squared risks 5,038 / 5 = 1,007.60 and 5,883 / 5 = 1,176.60; Step 1's check: 1,007.60 + (27 − 40)² = 1,176.60.
example : (5038 : ℚ) / 5 = 100760 / 100 ∧ (5883 : ℚ) / 5 = 117660 / 100 ∧
    (5038 : ℚ) / 5 + (27 - 40) ^ 2 = 5883 / 5 := by norm_num
-- Absolute losses: 124 at £40 and 101 at £27, so absolute risks 24.80 and 20.20.
example : ∑ i, |five i - 40| = 124 ∧ ∑ i, |five i - 27| = 101 := by decide
example : (124 : ℚ) / 5 = 2480 / 100 ∧ (101 : ℚ) / 5 = 2020 / 100 := by norm_num
-- Hinge loss at score −1 averages 2q: 1/5 when q = 1/10 and 4/5 when q = 2/5.
example : (1 / 10 : ℚ) * max 0 (1 - (-1)) + (1 - 1 / 10) * max 0 (1 + (-1)) = 1 / 5 := by norm_num
example : (2 / 5 : ℚ) * max 0 (1 - (-1)) + (1 - 2 / 5) * max 0 (1 + (-1)) = 4 / 5 := by norm_num

#print axioms squared_loss_minimised_by_mean
#print axioms absolute_loss_minimised_by_median
#print axioms log_loss_lowest_at_true_chance

end LossAndEmpiricalRisk
