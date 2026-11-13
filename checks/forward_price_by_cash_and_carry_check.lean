-- Forward price: the delivery price that makes a forward contract worth nothing today is exactly S e^((r-q)T), the only quote at which neither cash-and-carry nor its reverse makes a riskless profit, and with a known cash dividend it becomes (S - C e^(-rt)) e^(rT).
import Mathlib.Analysis.SpecialFunctions.Exp

open Real

/-! Notation, as on the card. `S` is the spot price, `r` the bank rate and `q` the dividend yield,
both continuously compounded, `T` the wait to delivery in years and `K` any delivery price written
into a contract. The card's model (one rate both ways, no fees, short selling allowed, known
income, known rate, both sides deliver) is what turns the trades below into prices:

* holding `e^(-qT)` of a share with the dividends reinvested ends as one whole share, and costs
  `S e^(-qT)` today (the prepaid forward);
* a bill of `K` on delivery day costs `K e^(-rT)` today;
* so a contract paying the share minus `K` on delivery day is worth
  `G = S e^(-qT) - K e^(-rT)` today. -/

/-- The card's main claim. The value today of a forward at delivery price `K` is the gap between
the forward price `S e^((r-q)T)` and `K`, discounted: `G = e^(-rT) (S e^((r-q)T) - K)`. So the
contract costs nothing now exactly when `K` is the forward price `S e^((r-q)T)`: today's price of
the share, grown at the bank rate and shrunk by the income it pays before delivery. -/
theorem forward_price_makes_contract_free (S r q T K : ℝ) :
    S * exp (-(q * T)) - K * exp (-(r * T)) = exp (-(r * T)) * (S * exp ((r - q) * T) - K) ∧
    (S * exp (-(q * T)) - K * exp (-(r * T)) = 0 ↔ K = S * exp ((r - q) * T)) := by
  have h : exp (-(q * T)) = exp (-(r * T)) * exp ((r - q) * T) := by
    rw [← exp_add]; congr 1; ring
  have hne : exp (-(r * T)) ≠ 0 := (exp_pos _).ne'
  have key : S * exp (-(q * T)) - K * exp (-(r * T)) =
      exp (-(r * T)) * (S * exp ((r - q) * T) - K) := by rw [h]; ring
  refine ⟨key, ?_⟩
  rw [key, mul_eq_zero, sub_eq_zero]
  constructor
  · rintro (h0 | h0)
    · exact absurd h0 hne
    · exact h0.symm
  · intro h0; exact Or.inr h0.symm

/-- Steps 3 and 4: one number survives. Cash-and-carry against a quote `K` (sell the forward,
borrow `S e^(-qT)`, buy `e^(-qT)` of a share, repay `S e^(-qT) e^(rT)` on delivery day) nets
`K - S e^(-qT) e^(rT)` on delivery day; the reverse trade nets the opposite. Neither trade makes a
strictly positive riskless profit exactly when the quote is the forward price `S e^((r-q)T)`. -/
theorem only_forward_price_survives_cash_and_carry (S r q T K : ℝ) :
    (K - S * exp (-(q * T)) * exp (r * T) ≤ 0 ∧ S * exp (-(q * T)) * exp (r * T) - K ≤ 0) ↔
      K = S * exp ((r - q) * T) := by
  have h : S * exp (-(q * T)) * exp (r * T) = S * exp ((r - q) * T) := by
    rw [mul_assoc, ← exp_add]; congr 2; ring
  rw [h]
  constructor
  · rintro ⟨h1, h2⟩; linarith
  · intro h0; constructor <;> linarith

/-- A known cash payment instead of a yield. Buy one whole share for `S` and borrow
`I = C e^(-rt)`: the payment `C` landing at time `t` clears that debt exactly, and the outlay
`S - I` is all that is carried. A contract at delivery price `K` is then worth
`S - C e^(-rt) - K e^(-rT)` today, which is zero exactly when `K = (S - C e^(-rt)) e^(rT)`. -/
theorem forward_price_with_cash_income (S r T C t K : ℝ) :
    C * exp (-(r * t)) * exp (r * t) = C ∧
    (S - C * exp (-(r * t)) - K * exp (-(r * T)) = 0 ↔
      K = (S - C * exp (-(r * t))) * exp (r * T)) := by
  have h1 : exp (-(r * t)) * exp (r * t) = 1 := by
    rw [← exp_add]; simp
  have h2 : exp (-(r * T)) * exp (r * T) = 1 := by
    rw [← exp_add]; simp
  refine ⟨by rw [mul_assoc, h1, mul_one], ?_⟩
  have hpos : 0 < exp (r * T) := exp_pos _
  constructor
  · intro h0
    have : (S - C * exp (-(r * t)) - K * exp (-(r * T))) * exp (r * T) = 0 := by rw [h0, zero_mul]
    have e : (S - C * exp (-(r * t)) - K * exp (-(r * T))) * exp (r * T) =
        (S - C * exp (-(r * t))) * exp (r * T) - K * (exp (-(r * T)) * exp (r * T)) := by ring
    rw [e, h2] at this; linarith
  · intro h0
    rw [h0]
    have e : (S - C * exp (-(r * t))) * exp (r * T) * exp (-(r * T)) =
        (S - C * exp (-(r * t))) * (exp (-(r * T)) * exp (r * T)) := by ring
    rw [e, h2]; ring

/-! The card's exact numbers. Acme trades at 100, the bank rate is 5 percent. -/

-- Delivery today costs today's price: at T = 0 the forward is 100 (both chart lines start there).
example : (100 : ℝ) * exp ((5 / 100 - 2 / 100) * 0) = 100 := by norm_num

-- When the yield equals the rate, 5 percent against 5 percent, the forward is the spot, 100.
example : (100 : ℝ) * exp ((5 / 100 - 5 / 100) * 1) = 100 := by norm_num

-- A worthless asset costs nothing to carry: at S = 0 the forward is 0.
example : (0 : ℝ) * exp ((5 / 100 - 2 / 100) * 1) = 0 := by norm_num

-- The simple-interest mistake from the card's table: 100 × (1 + 0.05 - 0.02) = 103.00.
example : (100 : ℚ) * (1 + 5 / 100 - 2 / 100) = 103 := by norm_num

#print axioms forward_price_makes_contract_free
#print axioms only_forward_price_survives_cash_and_carry
#print axioms forward_price_with_cash_income
