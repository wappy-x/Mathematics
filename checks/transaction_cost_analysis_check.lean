-- Measuring execution: the implementation shortfall against the decision price splits exactly into a timing leg plus the cost against the arrival price, the cash ledger with a fee gives the same cost plus the fee's share, and the gap between any two benchmarks' costs depends on neither the fills nor the fee.
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Real.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring

open Finset

/-! ## The objects

An order is filled in pieces: piece `i` in the finite set `S` is `q i` shares at price `p i`.
The order is `Q = ∑ q i` shares. The side `s` is `+1` for a buy and `-1` for a sale.
`pD` is the decision price; every cost is quoted in basis points of it. -/

/-- The share-weighted average price: cash over shares, `p̄ = (∑ q i * p i) / Q`. -/
noncomputable def avgPrice {ι : Type*} (S : Finset ι) (q p : ι → ℝ) : ℝ :=
  (∑ i ∈ S, q i * p i) / ∑ i ∈ S, q i

/-- The card's cost against a reference price `B`, in basis points:
`c(B) = 10,000 * s * (p̄ - B) / pD`. -/
noncomputable def costBp (s pD B pbar : ℝ) : ℝ :=
  10000 * (s * (pbar - B)) / pD

/-- The cost read straight off the cash ledger, with a commission of `F` dollars:
real against paper is `s * (∑ q i * p i - Q * B) + F`, over the decision notional `Q * pD`,
times 10,000. -/
noncomputable def ledgerCostBp {ι : Type*} (S : Finset ι) (q p : ι → ℝ) (s pD F B : ℝ) : ℝ :=
  10000 * (s * (∑ i ∈ S, q i * p i - (∑ i ∈ S, q i) * B) + F) / ((∑ i ∈ S, q i) * pD)

/-- **Implementation shortfall = timing + impact.** For any fills, either side and any decision
and arrival prices, the cost against the decision price is the timing leg
`10,000 * s * (pA - pD) / pD` plus the cost against the arrival price. Nothing is assumed:
it is the add-and-subtract of `pA`. -/
theorem implementation_shortfall_eq_timing_add_impact {ι : Type*} (S : Finset ι) (q p : ι → ℝ)
    (s pD pA : ℝ) :
    costBp s pD pD (avgPrice S q p)
      = 10000 * (s * (pA - pD)) / pD + costBp s pD pA (avgPrice S q p) := by
  unfold costBp
  ring

/-- **The ledger forces the weighted average, and a fee adds alike to every benchmark.**
For an order of `Q = ∑ q i` shares (`Q ≠ 0`), the ledger cost against any reference `B`, with a
commission `F`, equals the formula cost on the share-weighted average price plus
`10,000 * F / (Q * pD)`. With `F = 0` this is the cash-ledger road to the shortfall. -/
theorem ledger_cost_eq_cost_add_fee {ι : Type*} (S : Finset ι) (q p : ι → ℝ) (s pD F B : ℝ)
    (hQ : ∑ i ∈ S, q i ≠ 0) :
    ledgerCostBp S q p s pD F B
      = costBp s pD B (avgPrice S q p) + 10000 * F / ((∑ i ∈ S, q i) * pD) := by
  unfold ledgerCostBp costBp avgPrice
  rcases eq_or_ne pD 0 with h | h
  · subst h; simp
  · field_simp

/-- **The fills and the fee cancel between benchmarks.** For any two references `B₁`, `B₂`, any
fills (with `Q ≠ 0`) and any fee, `c(B₁) - c(B₂) = 10,000 * s * (B₂ - B₁) / pD`. No order of the
prices is required: every leg may be negative. -/
theorem cost_sub_cost_eq_benchmark_gap {ι : Type*} (S : Finset ι) (q p : ι → ℝ)
    (s pD F B₁ B₂ : ℝ) (hQ : ∑ i ∈ S, q i ≠ 0) :
    ledgerCostBp S q p s pD F B₁ - ledgerCostBp S q p s pD F B₂
      = 10000 * (s * (B₂ - B₁)) / pD := by
  rw [ledger_cost_eq_cost_add_fee S q p s pD F B₁ hQ, ledger_cost_eq_cost_add_fee S q p s pD F B₂ hQ]
  unfold costBp
  ring

/-! ## The card's worked numbers, in cents

Sell 100,000 Acme (`s = -1`), decided at 10000 cents, arriving at 9996 cents.
Basis points do not change when every price is scaled, so cents give the same bp as dollars. -/

/-- The fund's six fills: shares. -/
noncomputable def fillQ : Fin 6 → ℝ := ![10000, 15000, 20000, 20000, 20000, 15000]
/-- The fund's six fills: prices in cents. -/
noncomputable def fillP : Fin 6 → ℝ := ![9993, 9992, 9989, 9986, 9985, 9986]
/-- Other traders' tape: shares per hour. -/
noncomputable def tapeV : Fin 6 → ℝ := ![200000, 120000, 100000, 90000, 110000, 280000]
/-- Other traders' tape: average price per hour, in cents. -/
noncomputable def tapeM : Fin 6 → ℝ := ![9997, 9996, 9993, 9990, 9990, 9991]

-- cash raised: 998,800,000 cents = $9,988,000
example : (10000 * 9993 + 15000 * 9992 + 20000 * 9989 + 20000 * 9986 + 20000 * 9985
    + 15000 * 9986 : ℕ) = 998800000 := by norm_num
-- average fill $99.88 and market VWAP $99.93
example : avgPrice univ fillQ fillP = 9988 := by
  norm_num [avgPrice, Fin.sum_univ_succ, fillQ, fillP]
example : avgPrice univ tapeV tapeM = 9993 := by
  norm_num [avgPrice, Fin.sum_univ_succ, tapeV, tapeM]
-- shortfall 12 bp, timing 4 bp, impact 8 bp, drift 3 bp, VWAP cost 5 bp
example : costBp (-1) 10000 10000 9988 = 12 := by norm_num [costBp]
example : 10000 * ((-1 : ℝ) * (9996 - 10000)) / 10000 = 4 := by norm_num
example : costBp (-1) 10000 9996 9988 = 8 := by norm_num [costBp]
example : 10000 * ((-1 : ℝ) * (9993 - 9996)) / 10000 = 3 := by norm_num
example : costBp (-1) 10000 9993 9988 = 5 := by norm_num [costBp]
-- the cash ledger gives the same 12 bp; a $2,000 (200,000-cent) commission makes it 14
example : ledgerCostBp univ fillQ fillP (-1) 10000 0 10000 = 12 := by
  norm_num [ledgerCostBp, Fin.sum_univ_succ, fillQ, fillP]
example : ledgerCostBp univ fillQ fillP (-1) 10000 200000 10000 = 14 := by
  norm_num [ledgerCostBp, Fin.sum_univ_succ, fillQ, fillP]
-- what breaks: the buy sign gives -12; the plain average of the six prices gives 11.5
example : costBp 1 10000 10000 9988 = -12 := by norm_num [costBp]
example : costBp (-1) 10000 10000 ((9993 + 9992 + 9989 + 9986 + 9985 + 9986) / 6) = 23 / 2 := by
  norm_num [costBp]
-- what breaks: counting the fund's own fills in VWAP gives 4.5; the fund as the whole tape gives 0
example : costBp (-1) 10000 ((900000 * 9993 + 100000 * 9988) / 1000000) 9988 = 9 / 2 := by
  norm_num [costBp]
example : costBp (-1) 10000 (avgPrice univ fillQ fillP) (avgPrice univ fillQ fillP) = 0 := by
  norm_num [costBp]
-- the fund is 10% of the day's volume: 100,000 of 1,000,000 shares
example : (100000 : ℚ) / (100000 + 900000) = 1 / 10 := by norm_num
-- partial order: 15,000 unsold, close at 9980 cents; missed shares lose $3,000;
-- sold shares alone give 198/17 ≈ 11.65 bp; with the missed shares the shortfall is 12.90 bp
example : (15000 * (10000 - 9980) : ℕ) = 300000 := by norm_num
example : costBp (-1) 10000 10000 ((998800000 - 15000 * 9986) / 85000) = 198 / 17 := by
  norm_num [costBp]
example : 10000 * ((-1 : ℝ) * ((998800000 - 15000 * 9986 + 15000 * 9980) - 100000 * 10000))
    / (100000 * 10000) = 129 / 10 := by norm_num

#print axioms implementation_shortfall_eq_timing_add_impact
#print axioms ledger_cost_eq_cost_add_fee
#print axioms cost_sub_cost_eq_benchmark_gap
