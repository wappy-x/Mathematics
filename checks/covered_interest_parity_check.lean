-- Covered interest parity: a quoted forward rate leaves neither the seller's nor the buyer's cash-and-carry trade a riskless profit exactly when it equals S e^((r_d - r_f) T), and the same holds for money-market rates.
import Mathlib.Analysis.Complex.Exponential

/-- Covered interest parity. One continuously compounded rate to borrow and lend in each
currency (`r_d` on dollars, `r_f` on euros), no fees, both sides deliver. Spot is `S` dollars
per euro and the market quotes a forward `F_q` for delivery in `T` years.
The seller's trade (borrow `S` dollars, buy one euro, deposit it, sell the grown euros forward)
nets `F_q e^(r_f T) - S e^(r_d T)` dollars on delivery day; the buyer's trade (borrow one euro,
sell it spot, deposit the dollars, buy the euros back forward) nets `S e^(r_d T) - F_q e^(r_f T)`.
Both trades cost nothing today. Neither pays a positive amount for certain exactly when the
quote is the forward rate `F = S e^((r_d - r_f) T)`. -/
theorem covered_interest_parity (S r_d r_f T F_q : ℝ) :
    (¬ 0 < F_q * Real.exp (r_f * T) - S * Real.exp (r_d * T) ∧
      ¬ 0 < S * Real.exp (r_d * T) - F_q * Real.exp (r_f * T)) ↔
    F_q = S * Real.exp ((r_d - r_f) * T) := by
  have key : S * Real.exp (r_d * T) = Real.exp (r_f * T) * (S * Real.exp ((r_d - r_f) * T)) := by
    rw [mul_left_comm, ← Real.exp_add]; ring_nf
  have hE : 0 < Real.exp (r_f * T) := Real.exp_pos _
  rw [key]
  set E := Real.exp (r_f * T)
  set G := S * Real.exp ((r_d - r_f) * T)
  constructor
  · rintro ⟨h1, h2⟩
    rw [not_lt] at h1 h2
    have a : E * (F_q - G) ≤ 0 := by linarith
    have b : E * (G - F_q) ≤ 0 := by linarith
    have a' : F_q - G ≤ 0 := by
      by_contra hc; rw [not_le] at hc; linarith [mul_pos hE hc]
    have b' : G - F_q ≤ 0 := by
      by_contra hc; rw [not_le] at hc; linarith [mul_pos hE hc]
    linarith
  · intro h
    rw [h]
    constructor <;> simp [mul_comm]

/-- The two ledgers in closed form: the seller's profit is `e^(r_f T) (F_q - F)` and the
buyer's is `e^(r_f T) (F - F_q)`, where `F = S e^((r_d - r_f) T)`. Since `e^(r_f T) > 0`,
the sign of the profit is the sign of the gap between the quote and `F`. -/
theorem cash_and_carry_ledgers_closed_form (S r_d r_f T F_q : ℝ) :
    F_q * Real.exp (r_f * T) - S * Real.exp (r_d * T) =
        Real.exp (r_f * T) * (F_q - S * Real.exp ((r_d - r_f) * T)) ∧
      S * Real.exp (r_d * T) - F_q * Real.exp (r_f * T) =
        Real.exp (r_f * T) * (S * Real.exp ((r_d - r_f) * T) - F_q) := by
  have key : S * Real.exp (r_d * T) = Real.exp (r_f * T) * (S * Real.exp ((r_d - r_f) * T)) := by
    rw [mul_left_comm, ← Real.exp_add]; ring_nf
  rw [key]
  constructor <;> ring

/-- The money-market form. With simple interest over a day-count fraction `τ`, a deposit of 1
grows to `1 + R τ`. The seller's trade nets `F_q (1 + R_f τ) - S (1 + R_d τ)` and the buyer's
nets the negative of that. Neither pays a positive amount exactly when
`F_q = S (1 + R_d τ) / (1 + R_f τ)`. -/
theorem covered_interest_parity_money_market (S R_d R_f τ F_q : ℝ) (h : 1 + R_f * τ ≠ 0) :
    (¬ 0 < F_q * (1 + R_f * τ) - S * (1 + R_d * τ) ∧
      ¬ 0 < S * (1 + R_d * τ) - F_q * (1 + R_f * τ)) ↔
    F_q = S * (1 + R_d * τ) / (1 + R_f * τ) := by
  rw [eq_div_iff h]
  constructor
  · rintro ⟨h1, h2⟩
    rw [not_lt] at h1 h2
    linarith
  · intro h'
    constructor <;> linarith

-- The card's "try: rd = rf = 0.04" row: with equal rates the one-year forward is spot, 1.10.
example : (11 / 10 : ℝ) * Real.exp ((4 / 100 - 4 / 100) * 1) = 11 / 10 := by
  norm_num

#print axioms covered_interest_parity
#print axioms cash_and_carry_ledgers_closed_form
#print axioms covered_interest_parity_money_market
