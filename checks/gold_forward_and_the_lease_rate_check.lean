-- Gold forward: with one dollar rate r and one gold lease rate l (paid in ounces), the only forward quote that leaves neither the cash-and-carry seller nor the reverse cash-and-carry buyer a sure profit is F = S e^((r - l) T), each ledger locks in exactly the mispricing whatever gold's price on delivery day, and a quote reveals the lease rate l = r - ln(F/S)/T.
import Mathlib.Analysis.SpecialFunctions.Log.Basic

open Real

/-- The gold forward is forced, as an equality. Spot is `S` dollars per ounce, the dollar rate
is `r`, the gold lease rate is `l` (interest paid in ounces), both continuously compounded, and
delivery is in `T` years. A dealer quotes `Fq` for one ounce at `T`; `ST` is gold's unknown spot
price on delivery day.

Seller (cash-and-carry): borrow `S e^(-lT)` dollars, buy `e^(-lT)` ounces, lend them at `l`, sell
one ounce forward at `Fq`. At `T` it receives `Fq`, repays `S e^(-lT) e^(rT)` dollars, and is left
with `e^(-lT) e^(lT) - 1` loose ounces worth `ST` each.

Buyer (reverse cash-and-carry): borrow `e^(-lT)` ounces, sell them, deposit `S e^(-lT)` dollars
at `r`, buy one ounce forward at `Fq`. At `T` it collects `S e^(-lT) e^(rT)`, pays `Fq`, and is
left with `1 - e^(-lT) e^(lT)` loose ounces.

Both cost nothing today. If neither strategy pays a positive amount whatever `ST` turns out to
be (no arbitrage in either direction), then the quote is `Fq = S e^((r - l) T)`. -/
theorem gold_forward_eq_spot_mul_exp_rate_gap (S r l T Fq : ℝ)
    (no_seller_arb : ¬ ∀ ST : ℝ,
      0 < Fq - S * exp (-l * T) * exp (r * T) + ST * (exp (-l * T) * exp (l * T) - 1))
    (no_buyer_arb : ¬ ∀ ST : ℝ,
      0 < S * exp (-l * T) * exp (r * T) - Fq + ST * (1 - exp (-l * T) * exp (l * T))) :
    Fq = S * exp ((r - l) * T) := by
  have h1 : exp (-l * T) * exp (l * T) = 1 := by
    rw [← exp_add]; simp
  have h2 : S * exp (-l * T) * exp (r * T) = S * exp ((r - l) * T) := by
    rw [mul_assoc, ← exp_add]; ring_nf
  rw [h1, h2] at no_seller_arb no_buyer_arb
  simp only [sub_self, mul_zero, add_zero, not_forall, not_lt] at no_seller_arb no_buyer_arb
  obtain ⟨_, hs⟩ := no_seller_arb
  obtain ⟨_, hb⟩ := no_buyer_arb
  linarith

/-- Each ledger locks in exactly the mispricing. Lending `e^(-lT)` ounces today returns exactly
one ounce at `T`; and for every delivery-day gold price `ST`, the seller's net dollars at `T` are
`Fq - S e^((r - l) T)` and the buyer's are `S e^((r - l) T) - Fq`, with no dependence on `ST`. -/
theorem gold_ledgers_lock_in_mispricing (S r l T Fq : ℝ) :
    exp (-l * T) * exp (l * T) = 1 ∧
    (∀ ST : ℝ, Fq - S * exp (-l * T) * exp (r * T) + ST * (exp (-l * T) * exp (l * T) - 1)
        = Fq - S * exp ((r - l) * T)) ∧
    (∀ ST : ℝ, S * exp (-l * T) * exp (r * T) - Fq + ST * (1 - exp (-l * T) * exp (l * T))
        = S * exp ((r - l) * T) - Fq) := by
  have h1 : exp (-l * T) * exp (l * T) = 1 := by
    rw [← exp_add]; simp
  have h2 : S * exp (-l * T) * exp (r * T) = S * exp ((r - l) * T) := by
    rw [mul_assoc, ← exp_add]; ring_nf
  refine ⟨h1, fun ST => ?_, fun ST => ?_⟩ <;> rw [h1, h2] <;> ring

/-- A forward quote reveals the lease rate. For positive spot `S`, positive quote `Fq` and
`T > 0` years, the quote equals `S e^((r - l) T)` exactly when `l = r - ln(Fq / S) / T`: every
positive quote has one and only one implied lease rate. -/
theorem implied_lease_rate (S r l T Fq : ℝ) (hS : 0 < S) (hFq : 0 < Fq) (hT : 0 < T) :
    Fq = S * exp ((r - l) * T) ↔ l = r - log (Fq / S) / T := by
  have hq : 0 < Fq / S := div_pos hFq hS
  constructor
  · intro h
    have : Fq / S = exp ((r - l) * T) := by
      rw [h]; field_simp
    rw [this, log_exp]
    field_simp
    ring
  · intro h
    have hlog : (r - l) * T = log (Fq / S) := by
      rw [h]; field_simp; ring
    rw [hlog, exp_log hq]
    field_simp

-- The rate gap at dollars 5%, lease 1%, one year: 0.04.
example : ((5 : ℚ) / 100 - 1 / 100) * 1 = 4 / 100 := by norm_num

-- Wrong answer "simple rate gap" S (1 + (r - l) T) at 2,000, 5%, 1%, one year: 2,080.
example : (2000 : ℚ) * (1 + (5 / 100 - 1 / 100) * 1) = 2080 := by norm_num

-- "Try: lease 5%": when the lease rate equals the dollar rate the forward is spot, 2,000.
example : (2000 : ℝ) * exp ((5 / 100 - 5 / 100) * 1) = 2000 := by norm_num

-- At T = 0 the forward is spot, whatever the two rates.
example (r l : ℝ) : (2000 : ℝ) * exp ((r - l) * 0) = 2000 := by norm_num

-- The five-year forward at lease 1% equals the four-year forward with no lease (both 2,442.81).
example : (2000 : ℝ) * exp ((5 / 100 - 1 / 100) * 5) = 2000 * exp ((5 / 100 - 0) * 4) := by
  norm_num

-- Implied lease at a 2,100 quote: 0.05 - ln(2100/2000) / 1 = 0.05 - ln(21/20).
example : (5 / 100 : ℝ) - log (2100 / 2000) / 1 = 5 / 100 - log (21 / 20) := by norm_num

#print axioms gold_forward_eq_spot_mul_exp_rate_gap
#print axioms gold_ledgers_lock_in_mispricing
#print axioms implied_lease_rate
