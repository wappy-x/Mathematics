-- An old forward: under a pricing rule with one rate both ways and no fees, a forward signed earlier at delivery price K is worth today's forward price minus K, discounted to today, which equals the share fraction's cost minus the discounted delivery price, and any other price leaves a sure profit.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Algebra.Module.LinearMap.Defs
import Mathlib.Algebra.Module.Pi
import Mathlib.Tactic.NormNum

open Real

/-! Setting, as on the card.

* `Ω` is the set of ways delivery day can turn out, and `S_T ω` is Acme's price on delivery day
  in outcome `ω`. Nothing is assumed about it: no forecast, no volatility.
* A claim paid on delivery day is a function `Ω → ℝ`. `price` gives its value today.
* The card's "When it holds": the share can be bought, held and sold short at one rate for
  borrowing and lending with no fees, so holding two claims adds their prices and scaling a
  claim (selling short is a negative scale) scales its price: `price` is a linear map. The rate
  `r` is known, so a sure dollar on delivery day costs `e^(-rτ)` today, with `τ` the years still
  to run. Nothing is settled before delivery and both sides deliver, so the old contract is
  exactly the claim `S_T - K` on delivery day.
* Today's forward price `F` is the delivery price at which a fresh contract, the claim
  `S_T - F`, costs nothing. -/

/-- The card's main claim. An existing forward with delivery price `K` is worth the gap between
today's forward price `F` and `K`, shrunk back to today's money:
`V_t = (F - K) e^(-rτ)`. -/
theorem old_forward_value_eq_discounted_gap {Ω : Type*} (price : (Ω → ℝ) →ₗ[ℝ] ℝ)
    (S_T : Ω → ℝ) (F K r τ : ℝ)
    (h_bond : price (fun _ => 1) = exp (-(r * τ)))
    (h_fresh : price (fun ω => S_T ω - F) = 0) :
    price (fun ω => S_T ω - K) = (F - K) * exp (-(r * τ)) := by
  have hsplit : (fun ω => S_T ω - K) = (fun ω => S_T ω - F) + (F - K) • (fun _ : Ω => (1 : ℝ)) := by
    funext ω; simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]; ring
  rw [hsplit, map_add, map_smul, h_fresh, h_bond, smul_eq_mul, zero_add]

/-- The share form (Step 3). If `e^(-qτ)` of a share, dividends reinvested, grows into one whole
share by delivery day and so costs `S e^(-qτ)` today, then the old contract is worth
`S e^(-qτ) - K e^(-rτ)`, and today's forward price is the spot carried to delivery day,
`F = S e^((r-q)τ)`, so the two forms of the mark say one thing. -/
theorem old_forward_value_share_form {Ω : Type*} (price : (Ω → ℝ) →ₗ[ℝ] ℝ)
    (S_T : Ω → ℝ) (S F K r q τ : ℝ)
    (h_bond : price (fun _ => 1) = exp (-(r * τ)))
    (h_share : price S_T = S * exp (-(q * τ)))
    (h_fresh : price (fun ω => S_T ω - F) = 0) :
    price (fun ω => S_T ω - K) = S * exp (-(q * τ)) - K * exp (-(r * τ)) ∧
      F = S * exp ((r - q) * τ) := by
  have hsub : ∀ c : ℝ, (fun ω => S_T ω - c) = S_T - c • (fun _ : Ω => (1 : ℝ)) := by
    intro c; funext ω; simp only [Pi.sub_apply, Pi.smul_apply, smul_eq_mul, mul_one]
  have hval : ∀ c : ℝ, price (fun ω => S_T ω - c) = S * exp (-(q * τ)) - c * exp (-(r * τ)) := by
    intro c; rw [hsub, map_sub, map_smul, h_share, h_bond, smul_eq_mul]
  refine ⟨hval K, ?_⟩
  have h0 := hval F
  rw [h_fresh] at h0
  have hpos : 0 < exp (-(r * τ)) := exp_pos _
  have hF : F * exp (-(r * τ)) = S * exp (-(q * τ)) := by linarith
  have hexp : exp ((r - q) * τ) * exp (-(r * τ)) = exp (-(q * τ)) := by
    rw [← exp_add]; congr 1; ring
  apply mul_right_cancel₀ hpos.ne'
  rw [hF, mul_assoc, hexp]

/-- Why no other number can stand (the detailed proof). Hold the old contract on one side at
price `p`, sign a fresh opposite forward at `F` for nothing, and bank or borrow `p` until
delivery day, where it becomes `p / e^(-rτ)`. If `p` is not `(F - K) e^(-rτ)`, one of the two
directions pays a strictly positive sum whatever Acme's delivery-day price `x` turns out to be:
above the mark, sell the old contract; below it, buy it. -/
theorem mispriced_old_forward_gives_sure_profit (F K r τ p : ℝ)
    (h_mis : p ≠ (F - K) * exp (-(r * τ))) :
    (∀ x : ℝ, 0 < -(x - K) + (x - F) + p / exp (-(r * τ))) ∨
      (∀ x : ℝ, 0 < (x - K) + (F - x) - p / exp (-(r * τ))) := by
  have hpos : 0 < exp (-(r * τ)) := exp_pos _
  set d := exp (-(r * τ)) with hd
  have hne : p / d ≠ F - K := by
    intro h; apply h_mis; rw [← h, div_mul_cancel₀ _ hpos.ne']
  rcases lt_or_gt_of_ne hne with h | h
  · right; intro x; linarith
  · left; intro x; linarith

/-! The card's cancelling ledger (Step 1), in cents: the old contract at 103.05, the new short at
106.00. Whatever Acme does on delivery day, the pair pays 2.95. -/

-- Acme at 80.00: the old contract pays -23.05, the new one 26.00, the pair 2.95.
example : (8000 : ℤ) - 10305 = -2305 ∧ (10600 : ℤ) - 8000 = 2600 ∧
    ((8000 : ℤ) - 10305) + (10600 - 8000) = 295 := by norm_num

-- Acme at 95.00: -8.05, 11.00, 2.95.
example : (9500 : ℤ) - 10305 = -805 ∧ (10600 : ℤ) - 9500 = 1100 ∧
    ((9500 : ℤ) - 10305) + (10600 - 9500) = 295 := by norm_num

-- Acme at 110.00: 6.95, -4.00, 2.95.
example : (11000 : ℤ) - 10305 = 695 ∧ (10600 : ℤ) - 11000 = -400 ∧
    ((11000 : ℤ) - 10305) + (10600 - 11000) = 295 := by norm_num

-- Acme at 130.00: 26.95, -24.00, 2.95.
example : (13000 : ℤ) - 10305 = 2695 ∧ (10600 : ℤ) - 13000 = -2400 ∧
    ((13000 : ℤ) - 10305) + (10600 - 13000) = 295 := by norm_num

-- With no time left to run the discount factor is one, and the mark is the raw payoff:
-- Acme at 101.00 against 103.045453 gives -2.045453 (month 12 on the card).
example : ((101 : ℝ) - 103045453 / 1000000) * exp (-((5 / 100) * 0)) = -2045453 / 1000000 := by
  norm_num

#print axioms old_forward_value_eq_discounted_gap
#print axioms old_forward_value_share_form
#print axioms mispriced_old_forward_gives_sure_profit
