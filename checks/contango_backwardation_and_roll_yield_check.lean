-- Contango and backwardation: on a strip priced by carry, F = S e^(c tau), a held futures contract's log return is the spot's log return minus c times the time held, a chain of rolls at delivery earns exactly what the long-dated contract earns, and with spot flat the roll loses exactly when c > 0 and gains exactly when c < 0.
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic.NormNum

open Real

/-- The roll yield identity. Spot at calendar time t is S t (always positive), and the strip
keeps its shape: at every time t the future for delivery tau years away is
F t tau = S t * e^(c tau), with one carry c = r + u - y for the whole strip and for all time.
Buy a contract with tau years left at time t and hold it for Delta years, so it then has
tau - Delta left. Its log return is the spot's log return plus the roll yield -c Delta:
ln(F_end / F_start) = ln(S_end / S_start) - c Delta. -/
theorem futures_log_return_eq_spot_return_minus_carry
    (S : ℝ → ℝ) (F : ℝ → ℝ → ℝ) (c : ℝ)
    (hS : ∀ t, 0 < S t) (hF : ∀ t τ, F t τ = S t * exp (c * τ))
    (t τ Δ : ℝ) :
    log (F (t + Δ) (τ - Δ) / F t τ) = log (S (t + Δ) / S t) - c * Δ := by
  have h1 := hS (t + Δ)
  have h2 := hS t
  rw [hF, hF]
  have key : S (t + Δ) * exp (c * (τ - Δ)) / (S t * exp (c * τ)) =
      (S (t + Δ) / S t) * exp (-(c * Δ)) := by
    rw [show c * (τ - Δ) = c * τ + -(c * Δ) by ring, exp_add]
    field_simp
  rw [key, log_mul (div_pos h1 h2).ne' (exp_pos _).ne', log_exp]
  ring

/-- Rolling at delivery, the months chain. Roll dates are t 0, t 1, ..., t n. At each date
t k the roller buys the contract delivering at the next date t (k+1) (time left
t (k+1) - t k), holds it to delivery, where it is worth spot, and rolls. The growth of the
roller is the product of the holding returns. Its log is the spot's log return minus c
times the total time T = t n - t 0, whatever path spot takes; and the growth equals
S_end divided by the price, on the first day, of the single contract delivering at the end:
a chain of rolls earns exactly what buying the long-dated contract earns. -/
theorem roller_growth_eq_spot_return_minus_carry
    (S : ℝ → ℝ) (F : ℝ → ℝ → ℝ) (c : ℝ)
    (hS : ∀ t, 0 < S t) (hF : ∀ t τ, F t τ = S t * exp (c * τ))
    (t : ℕ → ℝ) (n : ℕ) :
    log (∏ k ∈ Finset.range n, F (t (k + 1)) 0 / F (t k) (t (k + 1) - t k)) =
        log (S (t n) / S (t 0)) - c * (t n - t 0) ∧
      ∏ k ∈ Finset.range n, F (t (k + 1)) 0 / F (t k) (t (k + 1) - t k) =
        S (t n) / F (t 0) (t n - t 0) := by
  have hprod : ∀ m : ℕ, ∏ k ∈ Finset.range m, F (t (k + 1)) 0 / F (t k) (t (k + 1) - t k) =
      S (t m) / (S (t 0) * exp (c * (t m - t 0))) := by
    intro m
    induction m with
    | zero =>
      simp only [Finset.range_zero, Finset.prod_empty, sub_self, mul_zero, exp_zero, mul_one]
      exact (div_self (hS (t 0)).ne').symm
    | succ m ih =>
      rw [Finset.prod_range_succ, ih, hF, hF]
      have a := hS (t m)
      have b := hS (t 0)
      have e : exp (c * (t (m + 1) - t 0)) = exp (c * (t m - t 0)) * exp (c * (t (m + 1) - t m)) := by
        rw [← exp_add]; ring_nf
      rw [e, mul_zero, exp_zero, mul_one]
      have := exp_pos (c * (t m - t 0))
      have := exp_pos (c * (t (m + 1) - t m))
      field_simp
  have hn := hprod n
  have pos : 0 < S (t n) / (S (t 0) * exp (c * (t n - t 0))) :=
    div_pos (hS _) (mul_pos (hS _) (exp_pos _))
  refine ⟨?_, ?_⟩
  · rw [hn, log_div (hS _).ne' (mul_pos (hS _) (exp_pos _)).ne',
      log_mul (hS _).ne' (exp_pos _).ne', log_exp, log_div (hS _).ne' (hS _).ne']
    ring
  · rw [hn, hF]

/-- Contango bleeds, backwardation pays, even when spot never moves. On the same carry strip,
hold a contract for Delta > 0 years while spot ends where it started. Then the contract's
growth F_end / F_start is below 1 exactly when c > 0 (contango) and above 1 exactly when
c < 0 (backwardation). -/
theorem flat_spot_roll_sign
    (S : ℝ → ℝ) (F : ℝ → ℝ → ℝ) (c : ℝ)
    (hS : ∀ t, 0 < S t) (hF : ∀ t τ, F t τ = S t * exp (c * τ))
    (t τ Δ : ℝ) (hΔ : 0 < Δ) (hflat : S (t + Δ) = S t) :
    (F (t + Δ) (τ - Δ) / F t τ < 1 ↔ 0 < c) ∧
      (1 < F (t + Δ) (τ - Δ) / F t τ ↔ c < 0) := by
  have h2 := hS t
  have key : F (t + Δ) (τ - Δ) / F t τ = exp (-(c * Δ)) := by
    rw [hF, hF, hflat, show c * (τ - Δ) = c * τ + -(c * Δ) by ring, exp_add]
    have := exp_pos (c * τ)
    field_simp
  have l1 : exp (-(c * Δ)) < 1 ↔ -(c * Δ) < 0 := by
    rw [show (1 : ℝ) = exp 0 from exp_zero.symm, exp_lt_exp]
  have l2 : 1 < exp (-(c * Δ)) ↔ 0 < -(c * Δ) := by
    rw [show (1 : ℝ) = exp 0 from exp_zero.symm, exp_lt_exp]
  rw [key, l1, l2]
  constructor
  · constructor
    · intro h; by_contra hc; rw [not_lt] at hc; nlinarith
    · intro h; nlinarith
  · constructor
    · intro h; by_contra hc; rw [not_lt] at hc; nlinarith
    · intro h; nlinarith

-- Crude, spot flat at 80 for a year against the 84 twelve-month: 80/84 - 1 = -1/21 (-4.76%).
example : (80 : ℚ) / 84 - 1 = -1 / 21 := by norm_num
-- Copper, spot flat at 9000 against the 8700 twelve-month: 9000/8700 - 1 = 1/29 (+3.45%).
example : (9000 : ℚ) / 8700 - 1 = 1 / 29 := by norm_num
-- Crude roller's year when spot drifts to 76, 80, 84, 88: S_end / 84 - 1 is
-- -2/21 (-9.52%), -1/21 (-4.76%), 0, +1/21 (+4.76%); break-even exactly at 84.
example : (76 : ℚ) / 84 - 1 = -2 / 21 ∧ (80 : ℚ) / 84 - 1 = -1 / 21 ∧
    (84 : ℚ) / 84 - 1 = 0 ∧ (88 : ℚ) / 84 - 1 = 1 / 21 := by norm_num
-- Spot up to 84 (+5%, growth 84/80) and a year of roll (growth 80/84) cancel exactly.
example : ((84 : ℚ) / 80) * (80 / 84) = 1 := by norm_num
-- Full carry r + u with r = 5% and u = 2%: 5/100 + 2/100 = 7/100.
example : (5 : ℚ) / 100 + 2 / 100 = 7 / 100 := by norm_num

#print axioms futures_log_return_eq_spot_return_minus_carry
#print axioms roller_growth_eq_spot_return_minus_carry
#print axioms flat_spot_roll_sign
