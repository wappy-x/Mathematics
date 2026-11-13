-- Valuing an old currency forward: under a linear dollar pricing rule with one dollar rate and a euro deposit priced at spot, an old forward to buy A euros at K is worth A (F - K) e^(-r_d τ) dollars, that mark divided by spot equals the euro-ledger value A (1 - K/F) e^(-r_f τ), and a book with nonzero net euro amount is flat at exactly the amount-weighted average contract rate.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Algebra.Module.LinearMap.Defs
import Mathlib.Algebra.Module.Pi
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic.NormNum

open Real

/-! Setting, as on the card.

* `Ω` is the set of ways delivery day can turn out, and `S_T ω` is the spot rate (dollars per
  euro) on delivery day in outcome `ω`. Nothing is assumed about it: no forecast, no volatility.
* A claim paid in dollars on delivery day is a function `Ω → ℝ`; `price` gives its value today,
  in dollars. Holding two claims adds their prices and scaling a claim scales its price, so
  `price` is a linear map.
* "One dollar rate to discount with, for exactly the time left": a sure dollar on delivery day
  costs `e^(-r_d τ)` today.
* "Both sides deliver, same delivery day": the old contract to buy `A` euros at `K` is exactly
  the claim `A (S_T - K)` dollars on delivery day, and today's forward rate `F` is the rate at
  which a fresh contract, the claim `S_T - F`, costs nothing.
* "Parity links spot, forward and the two rates": `e^(-r_f τ)` euros on deposit today, costing
  `S e^(-r_f τ)` dollars at today's spot `S`, grow into one euro on delivery day, worth `S_T`
  dollars then. -/

/-- The card's main claim, in dollars. An old forward to buy `A` euros at contract rate `K` is
worth the euro amount times the gap between today's forward rate `F` and `K`, discounted at the
dollar rate: `V_d = A (F - K) e^(-r_d τ)`. -/
theorem old_fx_forward_dollar_mark {Ω : Type*} (price : (Ω → ℝ) →ₗ[ℝ] ℝ)
    (S_T : Ω → ℝ) (A F K r_d τ : ℝ)
    (h_bond : price (fun _ => 1) = exp (-(r_d * τ)))
    (h_fresh : price (fun ω => S_T ω - F) = 0) :
    price (fun ω => A * (S_T ω - K)) = A * (F - K) * exp (-(r_d * τ)) := by
  have hf : (fun ω => A * (S_T ω - K)) =
      A • (fun ω => S_T ω - F) + (A * (F - K)) • (fun _ : Ω => (1 : ℝ)) := by
    funext ω
    simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]
    ring
  rw [hf, map_add, map_smul, map_smul, h_fresh, h_bond, smul_eq_mul, smul_eq_mul]
  ring

/-- The euro count (Step 3). With today's spot `S > 0` and a euro deposit priced at spot, the
dollar mark divided by today's spot rate equals the euro ledger: the euros bought minus the euros
the owed dollars are worth forward, discounted at the euro rate,
`V_d / S = A (1 - K / F) e^(-r_f τ)`. -/
theorem old_fx_forward_euro_mark_eq_dollar_mark_div_spot {Ω : Type*}
    (price : (Ω → ℝ) →ₗ[ℝ] ℝ) (S_T : Ω → ℝ) (A S F K r_d r_f τ : ℝ)
    (hS : 0 < S)
    (h_bond : price (fun _ => 1) = exp (-(r_d * τ)))
    (h_euro : price S_T = S * exp (-(r_f * τ)))
    (h_fresh : price (fun ω => S_T ω - F) = 0) :
    price (fun ω => A * (S_T ω - K)) / S = A * (1 - K / F) * exp (-(r_f * τ)) := by
  have hd := old_fx_forward_dollar_mark price S_T A F K r_d τ h_bond h_fresh
  have hsplit : (fun ω => S_T ω - F) = S_T + (-F) • (fun _ : Ω => (1 : ℝ)) := by
    funext ω
    simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]
    ring
  have hpar : S * exp (-(r_f * τ)) = F * exp (-(r_d * τ)) := by
    rw [hsplit, map_add, map_smul, h_euro, h_bond, smul_eq_mul] at h_fresh
    linarith
  have hEd : 0 < exp (-(r_d * τ)) := exp_pos _
  have hEf : 0 < exp (-(r_f * τ)) := exp_pos _
  have hF : 0 < F := by
    by_contra h
    rw [not_lt] at h
    have : F * exp (-(r_d * τ)) ≤ 0 := mul_nonpos_of_nonpos_of_nonneg h hEd.le
    have : 0 < S * exp (-(r_f * τ)) := mul_pos hS hEf
    linarith
  rw [hd]
  generalize exp (-(r_d * τ)) = Ed at hpar
  generalize exp (-(r_f * τ)) = Ef at hpar
  rw [div_eq_iff hS.ne', one_sub_div hF.ne']
  have hr : A * ((F - K) / F) * Ef * S = A * (F - K) * (S * Ef) / F := by ring
  rw [hr, hpar]
  field_simp

/-- The rate at which a book is flat (Step 5). A book of forwards with euro amounts `A i` at
contract rates `K i`, all for one delivery day, is worth `e^(-r_d τ) Σ A_i (F - K_i)`. When the
net euro amount is not zero, the book is worth zero exactly when the forward rate is the
amount-weighted average of the contract rates, `F* = Σ A_i K_i / Σ A_i`. -/
theorem fx_book_flat_rate_eq_weighted_average {ι : Type*} (legs : Finset ι) (A K : ι → ℝ)
    (F r_d τ : ℝ) (h_net : ∑ i ∈ legs, A i ≠ 0) :
    exp (-(r_d * τ)) * ∑ i ∈ legs, A i * (F - K i) = 0 ↔
      F = (∑ i ∈ legs, A i * K i) / ∑ i ∈ legs, A i := by
  have hE : exp (-(r_d * τ)) ≠ 0 := (exp_pos _).ne'
  have hsum : ∑ i ∈ legs, A i * (F - K i) = F * ∑ i ∈ legs, A i - ∑ i ∈ legs, A i * K i := by
    rw [Finset.mul_sum, ← Finset.sum_sub_distrib]
    refine Finset.sum_congr rfl fun i _ => ?_
    ring
  rw [mul_eq_zero, hsum, eq_div_iff h_net]
  constructor
  · rintro (h | h)
    · exact absurd h hE
    · linarith
  · intro h
    right
    linarith

/-! The card's worked numbers, exactly, with rates written as fractions (1.1500 = 11500/10000). -/

-- Step 1 ledger: pay 11,500,000 dollars, receive 11,055,000 dollars; net -445,000 dollars.
example : (10000000 : ℚ) * (11500 / 10000) = 11500000 := by norm_num
example : (10000000 : ℚ) * (11055 / 10000) = 11055000 := by norm_num
example : (10000000 : ℚ) * (11055 / 10000 - 11500 / 10000) = -445000 := by norm_num
example : (11055 / 10000 : ℚ) - 11500 / 10000 = -445 / 10000 := by norm_num

-- Spot stuck at 1.1000 with zero months left: the mark is the payoff, -500,000 dollars.
example : (10000000 : ℚ) * (11000 / 10000 - 11500 / 10000) = -500000 := by norm_num

-- Step 5 book: +10m at 1.1500 and -4m at 1.1300 is flat at 1.163333..., that is 349/300.
example : ((10000000 : ℚ) * (11500 / 10000) + (-4000000) * (11300 / 10000)) /
    (10000000 + (-4000000)) = 349 / 300 := by norm_num

#print axioms old_fx_forward_dollar_mark
#print axioms old_fx_forward_euro_mark_eq_dollar_mark_div_spot
#print axioms fx_book_flat_rate_eq_weighted_average
