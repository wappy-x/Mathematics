-- Forward points and the FX swap: at the parity forward F = S e^((r_d - r_f) T) the points (F - S)/p equal S (e^((r_d - r_f) T) - 1)/p and rebuild the outright, their sign is the sign of r_d - r_f, and the swap's points leg is the dollar interest minus the euro interest at the forward rate.
import Mathlib.Analysis.SpecialFunctions.Exp

/-- Forward points. Spot is `S` dollars per euro, the pip size is `p`, and the forward for
delivery in `T` years is fair (covered interest parity): `F = S e^((r_d - r_f) T)`, with `r_d`
the dollar rate and `r_f` the euro rate, both continuously compounded. Then the points, the
forward minus spot counted in pips, are `P = (F - S)/p = S (e^((r_d - r_f) T) - 1)/p`, and
adding the points back to spot gives the outright: `F = S + P p`. -/
theorem forward_points_eq_carry (S F p r_d r_f T : ℝ) (hp : p ≠ 0)
    (hF : F = S * Real.exp ((r_d - r_f) * T)) :
    (F - S) / p = S * (Real.exp ((r_d - r_f) * T) - 1) / p ∧
      F = S + (F - S) / p * p := by
  subst hF
  refine ⟨by ring, ?_⟩
  rw [div_mul_cancel₀ _ hp]; ring

/-- The FX swap is a secured dollar loan paying the rate gap. On `N` euros, at the fair
forward `F = S e^((r_d - r_f) T)`: the dollar lender's far leg plus the euro interest sold
forward, `N F e^(r_f T)`, equals `N S e^(r_d T)`, a dollar deposit at `r_d`; the points leg is
the dollar interest minus the euro interest valued at the forward,
`N (F - S) = N S (e^(r_d T) - 1) - N (e^(r_f T) - 1) F`; and the swap is worth nothing at
inception, `N F e^(-r_d T) - N S e^(-r_f T) = 0`. -/
theorem fx_swap_points_leg_eq_rate_gap (N S F r_d r_f T : ℝ)
    (hF : F = S * Real.exp ((r_d - r_f) * T)) :
    N * F * Real.exp (r_f * T) = N * S * Real.exp (r_d * T) ∧
      N * (F - S) = N * S * (Real.exp (r_d * T) - 1) - N * (Real.exp (r_f * T) - 1) * F ∧
      N * F * Real.exp (-(r_d * T)) - N * S * Real.exp (-(r_f * T)) = 0 := by
  have h1 : Real.exp ((r_d - r_f) * T) * Real.exp (r_f * T) = Real.exp (r_d * T) := by
    rw [← Real.exp_add]; ring_nf
  have h2 : Real.exp ((r_d - r_f) * T) * Real.exp (-(r_d * T)) = Real.exp (-(r_f * T)) := by
    rw [← Real.exp_add]; ring_nf
  have hA : N * F * Real.exp (r_f * T) = N * S * Real.exp (r_d * T) := by
    subst hF; linear_combination N * S * h1
  refine ⟨hA, by linear_combination hA, ?_⟩
  subst hF; linear_combination N * S * h2

/-- The sign says which currency pays more. With a positive spot rate, a positive pip size,
a forward date `T > 0` years out and the fair forward `F = S e^((r_d - r_f) T)`, the points are
positive (a forward premium) exactly when the dollar rate is above the euro rate, and negative
(a forward discount) exactly when it is below. -/
theorem forward_points_sign (S F p r_d r_f T : ℝ) (hS : 0 < S) (hp : 0 < p) (hT : 0 < T)
    (hF : F = S * Real.exp ((r_d - r_f) * T)) :
    (0 < (F - S) / p ↔ r_f < r_d) ∧ ((F - S) / p < 0 ↔ r_d < r_f) := by
  have key : ∀ x : ℝ, (0 < x ↔ 0 < Real.exp x - 1) ∧ (x < 0 ↔ Real.exp x - 1 < 0) := by
    intro x
    constructor
    · rw [sub_pos, Real.one_lt_exp_iff]
    · rw [sub_neg, Real.exp_lt_one_iff]
  have hP : (F - S) / p = S * (Real.exp ((r_d - r_f) * T) - 1) / p := by subst hF; ring
  obtain ⟨k1, k2⟩ := key ((r_d - r_f) * T)
  rw [hP]
  constructor
  · rw [div_pos_iff_of_pos_right hp, mul_pos_iff_of_pos_left hS, ← k1,
      mul_pos_iff_of_pos_right hT, sub_pos]
  · have e1 : ∀ y : ℝ, S * y < 0 ↔ y < 0 := fun y => by
      constructor <;> intro h <;> nlinarith
    have e2 : ∀ y : ℝ, y * T < 0 ↔ y < 0 := fun y => by
      constructor <;> intro h <;> nlinarith
    rw [div_lt_iff₀ hp, zero_mul, e1, ← k2, e2, sub_neg]

-- One pip on the EUR 10,000,000 swap is 1,000 dollars, and the near leg at spot 1.1000 is 11,000,000 dollars.
example : (10000000 : ℚ) * (1 / 10000) = 1000 := by norm_num
example : (10000000 : ℚ) * (11 / 10) = 11000000 := by norm_num

-- Rule of thumb S (r_d - r_f) T / p at spot 1.1000, dollars 5%, euros 3%: 55.00 pips at 3M, 220.00 at 1Y.
example : (11 / 10 : ℚ) * (5 / 100 - 3 / 100) * (1 / 4) / (1 / 10000) = 55 := by norm_num
example : (11 / 10 : ℚ) * (5 / 100 - 3 / 100) * 1 / (1 / 10000) = 220 := by norm_num

-- The 1Y square term S ((r_d - r_f) T)^2 / (2 p) is 2.20 pips.
example : (11 / 10 : ℚ) * (2 / 100) ^ 2 / 2 / (1 / 10000) = 11 / 5 := by norm_num

-- Two-way quote: spot 1.0999/1.1001 with points "55.0/55.3" (low/high, add) gives 1.105400/1.105630.
example : (10999 / 10000 : ℚ) + 550 / 10 * (1 / 10000) = 110540 / 100000 ∧
    (11001 / 10000 : ℚ) + 553 / 10 * (1 / 10000) = 110563 / 100000 := by norm_num

-- Points "55.3/55.0" (high/low, subtract) give 1.094370/1.094600.
example : (10999 / 10000 : ℚ) - 553 / 10 * (1 / 10000) = 109437 / 100000 ∧
    (11001 / 10000 : ℚ) - 550 / 10 * (1 / 10000) = 109460 / 100000 := by norm_num

-- Adding the high/low quote by mistake gives 1.105430/1.105600, a spread narrower than spot's 0.0002.
example : (11001 / 10000 : ℚ) + 550 / 10 * (1 / 10000) - ((10999 / 10000) + 553 / 10 * (1 / 10000))
    < 11001 / 10000 - 10999 / 10000 := by norm_num

#print axioms forward_points_eq_carry
#print axioms fx_swap_points_leg_eq_rate_gap
#print axioms forward_points_sign
