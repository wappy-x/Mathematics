-- The risk-neutral probability: on a one-step fork with d < R < u, the cost of the share-and-cash copy of any payoff equals its q-weighted average carried back through the bank, with q = (R - d)/(u - d) strictly between 0 and 1, q is the only weight that averages the share to its growth, and q lies strictly between 0 and 1 exactly when no trade in the share and the bank makes free money.
import Mathlib.Analysis.Complex.Exponential
import Mathlib.Tactic.LinearCombination

/-! The model, one step of length `t` years.
* `S` is the share price today, `u` and `d` the up and down factors, so the share ends at `S * u` or `S * d`.
* `r` is the bank rate and `y` the dividend yield, both continuously compounded;
  a dollar in the bank grows to `exp (r * t)`, and dividends are reinvested in more shares,
  so one share today becomes `exp (y * t)` shares by the end of the step.
* `R = exp ((r - y) * t)` is the factor the share's own price grows by.
* The weight on the up branch is `q = (R - d) / (u - d)`.
* No real-world chance of an up move appears anywhere: the copy matches the payoff in both endings. -/

/-- The risk-neutral weight on the up branch: `q = (R - d) / (u - d)`. -/
noncomputable def riskNeutralWeight (R u d : ℝ) : ℝ := (R - d) / (u - d)

/-- The card's theorem: when the fork straddles the share's growth factor, `d < R < u`,
any copy of a payoff made from `Δ` shares (dividends reinvested) and some cash, matching the
payments `C_u` and `C_d` in the two endings, costs exactly
`exp (-(r t)) * (q * C_u + (1 - q) * C_d)`, and the weight `q` sits strictly between 0 and 1. -/
theorem copy_cost_eq_discounted_risk_neutral_average
    (S u d r y t Cu Cd Δ cash : ℝ)
    (hdR : d < Real.exp ((r - y) * t)) (hRu : Real.exp ((r - y) * t) < u)
    (h_up : Δ * S * u * Real.exp (y * t) + cash * Real.exp (r * t) = Cu)
    (h_down : Δ * S * d * Real.exp (y * t) + cash * Real.exp (r * t) = Cd) :
    0 < riskNeutralWeight (Real.exp ((r - y) * t)) u d ∧
      riskNeutralWeight (Real.exp ((r - y) * t)) u d < 1 ∧
      Δ * S + cash =
        Real.exp (-(r * t)) *
          (riskNeutralWeight (Real.exp ((r - y) * t)) u d * Cu +
            (1 - riskNeutralWeight (Real.exp ((r - y) * t)) u d) * Cd) := by
  have hud : 0 < u - d := by linarith
  have hE : Real.exp (r * t) = Real.exp ((r - y) * t) * Real.exp (y * t) := by
    rw [← Real.exp_add]; ring_nf
  have hinv : Real.exp (-(r * t)) * Real.exp (r * t) = 1 := by
    rw [← Real.exp_add]; simp
  unfold riskNeutralWeight
  refine ⟨div_pos (by linarith) hud, (div_lt_one hud).2 (by linarith), ?_⟩
  have key : (Real.exp ((r - y) * t) - d) / (u - d) * Cu
      + (1 - (Real.exp ((r - y) * t) - d) / (u - d)) * Cd
      = (Δ * S + cash) * Real.exp (r * t) := by
    rw [← h_up, ← h_down, hE]
    field_simp
    ring
  rw [key]
  calc Δ * S + cash = (Δ * S + cash) * (Real.exp (-(r * t)) * Real.exp (r * t)) := by
        rw [hinv, mul_one]
    _ = Real.exp (-(r * t)) * ((Δ * S + cash) * Real.exp (r * t)) := by ring

/-- Step 2: the same weight prices the share itself. With two different factors, a weight `w`
makes the share's weighted end price, carried back through the bank, equal to the prepaid share
`S * exp (-(y t))` exactly when `w` is the risk-neutral weight `q`. -/
theorem risk_neutral_weight_unique_share_martingale
    (S u d r y t w : ℝ) (hS : 0 < S) (hud : u ≠ d) :
    Real.exp (-(r * t)) * (w * (S * u) + (1 - w) * (S * d)) = S * Real.exp (-(y * t)) ↔
      w = riskNeutralWeight (Real.exp ((r - y) * t)) u d := by
  unfold riskNeutralWeight
  have hud' : u - d ≠ 0 := sub_ne_zero.mpr hud
  have hpos : 0 < Real.exp (-(r * t)) := Real.exp_pos _
  have hR : Real.exp (-(y * t)) = Real.exp (-(r * t)) * Real.exp ((r - y) * t) := by
    rw [← Real.exp_add]; ring_nf
  rw [hR, eq_div_iff hud']
  constructor
  · intro h
    have h2 : (Real.exp (-(r * t)) * S) * (w * (u - d) - (Real.exp ((r - y) * t) - d)) = 0 := by
      linear_combination h
    rcases mul_eq_zero.mp h2 with h3 | h3
    · exact absurd h3 (mul_pos hpos hS).ne'
    · linarith
  · intro h
    linear_combination (Real.exp (-(r * t)) * S) * h

/-- Step 3: free money is a holding of `a` shares at the end (bought today for
`a * S * exp (-(y t))`, dividends reinvested) and `b` dollars in the bank that costs nothing or
less today, never loses in either ending, and gains in at least one place. On a fork with
`d < u` and a positive share price, there is no such trade exactly when `0 < q < 1`. -/
theorem no_free_money_iff_risk_neutral_weight_strictly_between_zero_and_one
    (S u d r y t : ℝ) (hS : 0 < S) (hdu : d < u) :
    (¬ ∃ a b : ℝ,
        a * S * Real.exp (-(y * t)) + b ≤ 0 ∧
        0 ≤ a * S * u + b * Real.exp (r * t) ∧
        0 ≤ a * S * d + b * Real.exp (r * t) ∧
        (a * S * Real.exp (-(y * t)) + b < 0 ∨
          0 < a * S * u + b * Real.exp (r * t) ∨
          0 < a * S * d + b * Real.exp (r * t))) ↔
      (0 < riskNeutralWeight (Real.exp ((r - y) * t)) u d ∧
        riskNeutralWeight (Real.exp ((r - y) * t)) u d < 1) := by
  unfold riskNeutralWeight
  have hud : 0 < u - d := by linarith
  have hEpos : 0 < Real.exp (r * t) := Real.exp_pos _
  have hkey : S * Real.exp (-(y * t)) * Real.exp (r * t) = S * Real.exp ((r - y) * t) := by
    rw [mul_assoc, ← Real.exp_add]; ring_nf
  have hiff : (0 < (Real.exp ((r - y) * t) - d) / (u - d) ∧
      (Real.exp ((r - y) * t) - d) / (u - d) < 1) ↔
      (d < Real.exp ((r - y) * t) ∧ Real.exp ((r - y) * t) < u) := by
    rw [lt_div_iff₀ hud, div_lt_one hud]
    constructor
    · rintro ⟨h1, h2⟩; constructor <;> linarith
    · rintro ⟨h1, h2⟩; constructor <;> linarith
  rw [hiff]
  constructor
  · intro hno
    constructor
    · by_contra hR
      push Not at hR
      apply hno
      refine ⟨1, -(S * Real.exp (-(y * t))), by linarith, ?_, ?_, ?_⟩
      · nlinarith [mul_pos hS (show 0 < u - Real.exp ((r - y) * t) by linarith)]
      · nlinarith [mul_nonneg hS.le (show 0 ≤ d - Real.exp ((r - y) * t) by linarith)]
      · right; left
        nlinarith [mul_pos hS (show 0 < u - Real.exp ((r - y) * t) by linarith)]
    · by_contra hR
      push Not at hR
      apply hno
      refine ⟨-1, S * Real.exp (-(y * t)), by linarith, ?_, ?_, ?_⟩
      · nlinarith [mul_nonneg hS.le (show 0 ≤ Real.exp ((r - y) * t) - u by linarith)]
      · nlinarith [mul_pos hS (show 0 < Real.exp ((r - y) * t) - d by linarith)]
      · right; right
        nlinarith [mul_pos hS (show 0 < Real.exp ((r - y) * t) - d by linarith)]
  · rintro ⟨hdR, hRu⟩ ⟨a, b, h1, h2, h3, h4⟩
    have hZ : a * S * Real.exp ((r - y) * t) + b * Real.exp (r * t)
        = (a * S * Real.exp (-(y * t)) + b) * Real.exp (r * t) := by
      linear_combination (-a) * hkey
    have hid : (Real.exp ((r - y) * t) - d) * (a * S * u + b * Real.exp (r * t))
        + (u - Real.exp ((r - y) * t)) * (a * S * d + b * Real.exp (r * t))
        = (u - d) * (a * S * Real.exp ((r - y) * t) + b * Real.exp (r * t)) := by ring
    have hX := mul_nonneg (show 0 ≤ Real.exp ((r - y) * t) - d by linarith) h2
    have hY := mul_nonneg (show 0 ≤ u - Real.exp ((r - y) * t) by linarith) h3
    rcases h4 with h4 | h4 | h4
    · have hZneg := mul_neg_of_neg_of_pos h4 hEpos
      nlinarith [mul_neg_of_pos_of_neg hud (show a * S * Real.exp ((r - y) * t) + b * Real.exp (r * t) < 0 by linarith)]
    · have hZle := mul_nonpos_iff.mpr (Or.inr ⟨h1, hEpos.le⟩)
      nlinarith [mul_pos (show 0 < Real.exp ((r - y) * t) - d by linarith) h4,
        mul_nonpos_iff.mpr (Or.inl ⟨hud.le, (show a * S * Real.exp ((r - y) * t) + b * Real.exp (r * t) ≤ 0 by linarith)⟩)]
    · have hZle := mul_nonpos_iff.mpr (Or.inr ⟨h1, hEpos.le⟩)
      nlinarith [mul_pos (show 0 < u - Real.exp ((r - y) * t) by linarith) h4,
        mul_nonpos_iff.mpr (Or.inl ⟨hud.le, (show a * S * Real.exp ((r - y) * t) + b * Real.exp (r * t) ≤ 0 by linarith)⟩)]

#print axioms copy_cost_eq_discounted_risk_neutral_average
#print axioms risk_neutral_weight_unique_share_martingale
#print axioms no_free_money_iff_risk_neutral_weight_strictly_between_zero_and_one
