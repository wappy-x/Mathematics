-- Kelly: with a real edge the stake (bp - q)/b is the one stake that makes expected log growth largest, with no edge the best stake is zero, and on the growth parabola c times Kelly keeps c(2 - c) of the best growth.
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Deriv

/-- Expected log growth per bet, `g(f) = p ln(1 + b f) + q ln(1 - f)` with `q = 1 - p`:
win chance `p`, net odds `b`, stake `f` as a share of the current bankroll. -/
noncomputable def kellyGrowth (p b f : ℝ) : ℝ :=
  p * Real.log (1 + b * f) + (1 - p) * Real.log (1 - f)

/-- The card's main claim. A bet is won with chance `p` (0 < p < 1) and pays net odds `b > 0`;
the loss chance is `q = 1 - p`. When the edge is real (`bp > q`), the Kelly fraction
`f* = (bp - q)/b` is a stake strictly between 0 and 1, and it beats every other stake `f`
with `0 ≤ f < 1`: the expected log growth per bet is largest there and only there. -/
theorem kelly_fraction_maximizes_log_growth (p b : ℝ) (hp0 : 0 < p) (hp1 : p < 1) (hb : 0 < b)
    (hedge : 1 - p < b * p) :
    0 < (b * p - (1 - p)) / b ∧ (b * p - (1 - p)) / b < 1 ∧
      ∀ f : ℝ, 0 ≤ f → f < 1 → f ≠ (b * p - (1 - p)) / b →
        kellyGrowth p b f < kellyGrowth p b ((b * p - (1 - p)) / b) := by
  set s := (b * p - (1 - p)) / b with hs
  have hbs : b * s = b * p - (1 - p) := by rw [hs]; field_simp
  have hq : 0 < 1 - p := by linarith
  have hs0 : 0 < s := by rw [hs]; apply div_pos <;> linarith
  have hs1 : s < 1 := by
    rw [hs, div_lt_one hb]; nlinarith [mul_pos hb hq]
  refine ⟨hs0, hs1, ?_⟩
  intro f hf0 hf1 hfs
  have ha : 1 + b * s = p * (b + 1) := by rw [hbs]; ring
  have hc : 1 - s = (1 - p) * (b + 1) / b := by
    field_simp; nlinarith [hbs]
  have hapos : 0 < 1 + b * s := by rw [ha]; positivity
  have hcpos : 0 < 1 - s := by linarith
  have hx : 0 < 1 + b * f := by positivity
  have hy : 0 < 1 - f := by linarith
  have hne : (1 + b * f) / (1 + b * s) ≠ 1 := by
    intro h
    rw [div_eq_one_iff_eq hapos.ne'] at h
    apply hfs
    have : b * (f - s) = 0 := by linarith
    rcases mul_eq_zero.mp this with h1 | h1
    · linarith
    · linarith
  have h1 := Real.log_lt_sub_one_of_pos (div_pos hx hapos) hne
  have h2 := Real.log_le_sub_one_of_pos (div_pos hy hcpos)
  rw [Real.log_div hx.ne' hapos.ne'] at h1
  rw [Real.log_div hy.ne' hcpos.ne'] at h2
  have key : p * ((1 + b * f) / (1 + b * s) - 1) + (1 - p) * ((1 - f) / (1 - s) - 1) = 0 := by
    rw [ha, hc]
    have hp' : p ≠ 0 := hp0.ne'
    have hq' : 1 - p ≠ 0 := hq.ne'
    have hb' : b ≠ 0 := hb.ne'
    have hb1 : b + 1 ≠ 0 := by linarith
    field_simp
    ring
  unfold kellyGrowth
  nlinarith [mul_lt_mul_of_pos_left h1 hp0, mul_le_mul_of_nonneg_left h2 hq.le]

/-- With no edge (`bp ≤ q`), every positive stake below the whole bankroll has negative
expected log growth, so the best stake is zero: do not bet. -/
theorem no_edge_best_stake_is_zero (p b : ℝ) (hp0 : 0 < p) (hp1 : p < 1) (hb : 0 < b)
    (hnoedge : b * p ≤ 1 - p) :
    ∀ f : ℝ, 0 < f → f < 1 → kellyGrowth p b f < kellyGrowth p b 0 := by
  intro f hf0 hf1
  have hq : 0 < 1 - p := by linarith
  have hx : 0 < 1 + b * f := by positivity
  have hy : 0 < 1 - f := by linarith
  have h1 := Real.log_lt_sub_one_of_pos hx (by nlinarith)
  have h2 := Real.log_lt_sub_one_of_pos hy (by linarith)
  unfold kellyGrowth
  simp only [mul_zero, add_zero, sub_zero, Real.log_one]
  nlinarith [mul_lt_mul_of_pos_left h1 hp0, mul_lt_mul_of_pos_left h2 hq]

/-- The parabola rule for fractional Kelly. On the growth parabola `h(f) = e f - v f² / 2`
(edge `e`, second moment `v > 0`; exact in continuous time with `e = μ - r`, `v = σ²`),
the peak is at `f* = e / v`, and staking `c` times that keeps exactly `c (2 - c)` of the
peak growth: half Kelly keeps three quarters, twice Kelly keeps none. -/
theorem fractional_kelly_keeps_c_two_minus_c (e v c : ℝ) (hv : 0 < v) :
    (∀ f : ℝ, e * f - v * f ^ 2 / 2 ≤ e * (e / v) - v * (e / v) ^ 2 / 2) ∧
      e * (c * (e / v)) - v * (c * (e / v)) ^ 2 / 2
        = c * (2 - c) * (e * (e / v) - v * (e / v) ^ 2 / 2) := by
  constructor
  · intro f
    have key : e * (e / v) - v * (e / v) ^ 2 / 2 - (e * f - v * f ^ 2 / 2)
        = (v * f - e) ^ 2 / (2 * v) := by
      field_simp
      ring
    have : 0 ≤ (v * f - e) ^ 2 / (2 * v) := by positivity
    linarith
  · field_simp
    ring

-- The coin: p = 55/100, q = 45/100, b = 1. The edge and the Kelly fraction are 1/10.
example : ((1 : ℚ) * (55 / 100) - 45 / 100) / 1 = 1 / 10 := by norm_num

-- $100, a win then a loss: $99 at full Kelly (stake 1/10), $99.75 at half Kelly (stake 1/20).
example : (100 : ℚ) * (1 + 1 / 10) * (1 - 1 / 10) = 99 := by norm_num
example : (100 : ℚ) * (1 + 1 / 20) * (1 - 1 / 20) = 399 / 4 := by norm_num

-- c (2 - c): a quarter Kelly keeps 7/16, half and one and a half Kelly keep 3/4, twice Kelly keeps 0.
example : (1 / 4 : ℚ) * (2 - 1 / 4) = 7 / 16 := by norm_num
example : (1 / 2 : ℚ) * (2 - 1 / 2) = 3 / 4 := by norm_num
example : (3 / 2 : ℚ) * (2 - 3 / 2) = 3 / 4 := by norm_num
example : (2 : ℚ) * (2 - 2) = 0 := by norm_num

-- Chance of ever falling to half, x^(2/c - 1): 1/2 at full Kelly, 1/8 at half Kelly.
example : (1 / 2 : ℚ) ^ (2 / 1 - 1 : ℕ) = 1 / 2 := by norm_num
example : (1 / 2 : ℚ) ^ (2 * 2 - 1 : ℕ) = 1 / 8 := by norm_num

-- The saver: r = 4/100, μ = 8/100, σ = 15/100. Kelly stake 16/9, growth 17/225 at Kelly,
-- 1/15 at half Kelly (stake 8/9).
example : ((8 / 100 : ℚ) - 4 / 100) / (15 / 100) ^ 2 = 16 / 9 := by norm_num
example : (4 / 100 : ℚ) + 16 / 9 * (8 / 100 - 4 / 100) - (16 / 9) ^ 2 * (15 / 100) ^ 2 / 2
    = 17 / 225 := by norm_num
example : (4 / 100 : ℚ) + 8 / 9 * (8 / 100 - 4 / 100) - (8 / 9) ^ 2 * (15 / 100) ^ 2 / 2
    = 1 / 15 := by norm_num

#print axioms kelly_fraction_maximizes_log_growth
#print axioms no_edge_best_stake_is_zero
#print axioms fractional_kelly_keeps_c_two_minus_c
