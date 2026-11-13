-- Least squares: when the x-values are not all equal, the line through the average point with slope S_xy / S_xx is the one and only line with the smallest sum of squared vertical misses, its misses balance to zero, and the spread S_yy splits into S_xy² / S_xx plus that smallest sum.
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.Ring
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Linarith
import Mathlib.Algebra.Order.BigOperators.Group.Finset

/-! Notation as on the card. The data are `n` points, point `i` having `x i` (floor area) and
`y i` (price). A bar is an average; `S_xx`, `S_xy`, `S_yy` are sums of products of gaps from the
averages; `SSE a b` is the score of the line `a + b x`: its squared vertical misses, added. -/

open Finset

noncomputable section

namespace LeastSquares

variable {n : ℕ}

/-- The average of a list of `n` readings, `x̄ = (∑ xᵢ) / n`. -/
def mean (x : Fin n → ℝ) : ℝ := (∑ i, x i) / n

/-- `S_xx = ∑ (xᵢ - x̄)²`, the spread of the x-values. -/
def Sxx (x : Fin n → ℝ) : ℝ := ∑ i, (x i - mean x) ^ 2

/-- `S_xy = ∑ (xᵢ - x̄)(yᵢ - ȳ)`, how x and y move together. -/
def Sxy (x y : Fin n → ℝ) : ℝ := ∑ i, (x i - mean x) * (y i - mean y)

/-- `SSE(a, b) = ∑ (yᵢ - a - b xᵢ)²`, the score of the line `ŷ = a + b x`. -/
def SSE (x y : Fin n → ℝ) (a b : ℝ) : ℝ := ∑ i, (y i - a - b * x i) ^ 2

/-- The least-squares slope `b = S_xy / S_xx`. -/
def slope (x y : Fin n → ℝ) : ℝ := Sxy x y / Sxx x

/-- The least-squares intercept `a = ȳ - b x̄`. -/
def intercept (x y : Fin n → ℝ) : ℝ := mean y - slope x y * mean x

theorem sum_sub_mean (x : Fin n → ℝ) : ∑ i, (x i - mean x) = 0 := by
  rw [Finset.sum_sub_distrib, Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul,
    mean]
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp
  · have : (n : ℝ) ≠ 0 := by positivity
    field_simp
    ring

theorem SSE_expand (x y : Fin n → ℝ) (a b : ℝ) :
    SSE x y a b = Sxx x * b ^ 2 - 2 * b * Sxy x y + Sxx y +
      (n : ℝ) * (mean y - a - b * mean x) ^ 2 := by
  set c := mean y - a - b * mean x with hc
  have h : ∀ i, (y i - a - b * x i) ^ 2 =
      b ^ 2 * (x i - mean x) ^ 2 - 2 * b * ((x i - mean x) * (y i - mean y)) + (y i - mean y) ^ 2
        + 2 * c * (y i - mean y) - 2 * c * b * (x i - mean x) + c ^ 2 := by
    intro i; rw [hc]; ring
  rw [SSE, Finset.sum_congr rfl (fun i _ => h i)]
  simp only [Finset.sum_add_distrib, Finset.sum_sub_distrib, ← Finset.mul_sum, Finset.sum_const,
    Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
  have ex : ∑ i, x i - (n : ℝ) * mean x = 0 := by
    have := sum_sub_mean x
    rwa [Finset.sum_sub_distrib, Finset.sum_const, Finset.card_univ, Fintype.card_fin,
      nsmul_eq_mul] at this
  have ey : ∑ i, y i - (n : ℝ) * mean y = 0 := by
    have := sum_sub_mean y
    rwa [Finset.sum_sub_distrib, Finset.sum_const, Finset.card_univ, Fintype.card_fin,
      nsmul_eq_mul] at this
  rw [Sxx, Sxx, Sxy, ex, ey]
  ring

theorem Sxx_pos (x : Fin n → ℝ) (hx : ∃ i j, x i ≠ x j) : 0 < Sxx x := by
  obtain ⟨i, j, hij⟩ := hx
  have hnn : 0 ≤ Sxx x := Finset.sum_nonneg (fun k _ => sq_nonneg _)
  rcases hnn.lt_or_eq with h | h
  · exact h
  · exfalso
    have := (Finset.sum_eq_zero_iff_of_nonneg (fun k _ => sq_nonneg (x k - mean x))).1 h.symm
    have hi := this i (Finset.mem_univ _)
    have hj := this j (Finset.mem_univ _)
    have hi' : x i - mean x = 0 := pow_eq_zero_iff (n := 2) (by norm_num) |>.1 hi
    have hj' : x j - mean x = 0 := pow_eq_zero_iff (n := 2) (by norm_num) |>.1 hj
    exact hij (by linarith)

/-- **The least-squares line is the unique best line.** For any `n` points whose x-values are not
all equal, the line with slope `b = S_xy / S_xx` and intercept `a = ȳ - b x̄` passes through the
average point `(x̄, ȳ)`, and every other line `(a', b')` has a strictly larger sum of squared
vertical misses. -/
theorem least_squares_line_unique_minimiser (x y : Fin n → ℝ) (hx : ∃ i j, x i ≠ x j) :
    intercept x y + slope x y * mean x = mean y ∧
      ∀ a b : ℝ, (a, b) ≠ (intercept x y, slope x y) →
        SSE x y (intercept x y) (slope x y) < SSE x y a b := by
  have hS := Sxx_pos x hx
  have hn : (0 : ℝ) < n := by
    obtain ⟨i, _, _⟩ := hx
    exact_mod_cast Fin.pos i
  refine ⟨by rw [intercept]; ring, ?_⟩
  intro a b hab
  rw [SSE_expand, SSE_expand]
  have key : Sxx x * b ^ 2 - 2 * b * Sxy x y + Sxx y + (n : ℝ) * (mean y - a - b * mean x) ^ 2
      - (Sxx x * slope x y ^ 2 - 2 * slope x y * Sxy x y + Sxx y +
        (n : ℝ) * (mean y - intercept x y - slope x y * mean x) ^ 2)
      = Sxx x * (b - slope x y) ^ 2 + (n : ℝ) * (mean y - a - b * mean x) ^ 2 := by
    rw [intercept, slope]
    field_simp
    ring
  have hpos : 0 < Sxx x * (b - slope x y) ^ 2 + (n : ℝ) * (mean y - a - b * mean x) ^ 2 := by
    by_cases hb : b = slope x y
    · have ha : a ≠ intercept x y := by
        intro ha; exact hab (by rw [ha, hb])
      have : mean y - a - b * mean x ≠ 0 := by
        intro h0; apply ha; rw [intercept, ← hb]; linarith
      have : 0 < (mean y - a - b * mean x) ^ 2 := by positivity
      nlinarith [sq_nonneg (b - slope x y)]
    · have : b - slope x y ≠ 0 := sub_ne_zero.mpr hb
      have : 0 < (b - slope x y) ^ 2 := by positivity
      nlinarith [sq_nonneg (mean y - a - b * mean x)]
  linarith

/-- **The normal equations.** When the x-values are not all equal, the residuals of the
least-squares line add to zero, and so do the residuals weighted by `x`. -/
theorem least_squares_normal_equations (x y : Fin n → ℝ) (hx : ∃ i j, x i ≠ x j) :
    ∑ i, (y i - intercept x y - slope x y * x i) = 0 ∧
      ∑ i, (y i - intercept x y - slope x y * x i) * x i = 0 := by
  have hS := Sxx_pos x hx
  have ex := sum_sub_mean x
  have ey := sum_sub_mean y
  have h1 : ∀ i, y i - intercept x y - slope x y * x i =
      (y i - mean y) - slope x y * (x i - mean x) := by
    intro i; rw [intercept]; ring
  have h2 : ∀ i, (y i - intercept x y - slope x y * x i) * x i =
      (x i - mean x) * (y i - mean y) - slope x y * (x i - mean x) ^ 2
        + mean x * ((y i - mean y) - slope x y * (x i - mean x)) := by
    intro i; rw [intercept]; ring
  constructor
  · rw [Finset.sum_congr rfl (fun i _ => h1 i), Finset.sum_sub_distrib, ← Finset.mul_sum, ex, ey]
    ring
  · rw [Finset.sum_congr rfl (fun i _ => h2 i), Finset.sum_add_distrib, Finset.sum_sub_distrib,
      ← Finset.mul_sum, ← Finset.mul_sum, Finset.sum_sub_distrib, ← Finset.mul_sum, ex, ey]
    rw [← Sxy, ← Sxx, slope]
    field_simp
    ring

/-- **Total spread = explained + left over.** When the x-values are not all equal,
`S_yy = S_xy² / S_xx + SSE` at the least-squares line (here `S_yy` is `Sxx y`); so `R² = 1 - SSE / S_yy` is the explained
share `S_xy² / (S_xx S_yy)`, the squared correlation. -/
theorem least_squares_spread_split (x y : Fin n → ℝ) (hx : ∃ i j, x i ≠ x j) :
    Sxx y = Sxy x y ^ 2 / Sxx x + SSE x y (intercept x y) (slope x y) := by
  have hS := Sxx_pos x hx
  rw [SSE_expand]
  have : mean y - intercept x y - slope x y * mean x = 0 := by rw [intercept]; ring
  rw [this, slope]
  field_simp
  ring

end LeastSquares

open LeastSquares

/-! The card's six house sales: areas in square metres, prices in thousands of dollars. -/

/-- Floor areas of the six sales. -/
def area : Fin 6 → ℝ := ![60, 70, 90, 110, 130, 140]
/-- Prices of the six sales, in thousands of dollars. -/
def price : Fin 6 → ℝ := ![165, 205, 229, 267, 327, 337]

-- Averages: 100 m² and 255 thousand.
example : mean area = 100 ∧ mean price = 255 := by
  simp only [mean, area, price, Fin.sum_univ_succ, Fin.sum_univ_zero]; norm_num
-- S_xx = 5,200, S_xy = 10,920, S_yy = 23,328.
example : Sxx area = 5200 ∧ Sxy area price = 10920 ∧ Sxx price = 23328 := by
  simp only [Sxx, Sxy, mean, area, price, Fin.sum_univ_succ, Fin.sum_univ_zero]; norm_num
-- Slope 2.1 thousand dollars per m² ($2,100), intercept 45 thousand ($45,000).
example : slope area price = 21 / 10 ∧ intercept area price = 45 := by
  simp only [intercept, slope, Sxx, Sxy, mean, area, price, Fin.sum_univ_succ, Fin.sum_univ_zero]
  norm_num
-- Residuals −6, 13, −5, −9, 9, −2 from the line 45 + 2.1 × area.
example : (fun i => price i - 45 - 21 / 10 * area i) = ![-6, 13, -5, -9, 9, -2] := by
  funext i; fin_cases i <;> simp [area, price] <;> norm_num
-- They add to 0, and weighted by area they add to 0: the normal equations.
example : (∑ i, (price i - 45 - 21 / 10 * area i)) = 0 ∧
    (∑ i, (price i - 45 - 21 / 10 * area i) * area i) = 0 := by
  simp only [area, price, Fin.sum_univ_succ, Fin.sum_univ_zero]; norm_num
-- SSE = 396, and 23,328 = 10,920² / 5,200 + 396, that is 22,932 + 396.
example : SSE area price 45 (21 / 10) = 396 ∧ (10920 : ℝ) ^ 2 / 5200 = 22932 ∧
    (23328 : ℝ) = 22932 + 396 := by
  simp only [SSE, area, price, Fin.sum_univ_succ, Fin.sum_univ_zero]; norm_num
-- R² = 1 − 396 / 23,328 = 22,932 / 23,328 = 637/648 (0.9830).
example : (1 : ℚ) - 396 / 23328 = 22932 / 23328 ∧ (22932 : ℚ) / 23328 = 637 / 648 := by norm_num
-- Covariance over variance: 10,920 / 6 = 1,820 and 5,200 / 6 have ratio 2.1.
example : ((10920 : ℚ) / 6) / (5200 / 6) = 21 / 10 := by norm_num
-- Mistakes: area on price inverted is 23,328 / 10,920 (2.13626); the two end houses give 2.15.
example : (23328 : ℚ) / 10920 = (21 / 10) / (637 / 648) ∧ ((337 : ℚ) - 165) / (140 - 60) = 43 / 20 := by
  norm_num
-- Try changing: the mansion at 437 gives slope 373/130 (2.86923); every price + 20 keeps the
-- slope 2.1 and lifts the intercept to 65.
example : slope area ![165, 205, 229, 267, 327, 437] = 373 / 130 ∧
    slope area (fun i => price i + 20) = 21 / 10 ∧ intercept area (fun i => price i + 20) = 65 := by
  simp only [intercept, slope, Sxx, Sxy, mean, area, price, Fin.sum_univ_succ, Fin.sum_univ_zero]
  norm_num

#print axioms sum_sub_mean
#print axioms SSE_expand
#print axioms Sxx_pos
#print axioms least_squares_line_unique_minimiser
#print axioms least_squares_normal_equations
#print axioms least_squares_spread_split
