-- Total return swaps: the dealer's hedge ledger leaves it flat on every share-price, dividend and SOFR path exactly when the spread equals its funding spread minus the borrow fee, and between resets a takeover hedge pays the swap's mark carried at SOFR.
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Finset

/-- The dealer's cash at the end of one quarter of the swap, item by item, on `n` shares bought
at the reset price `Sa` (reset notional `n Sa`) and worth `Sb` at the next reset, with dividends
`D` per share, SOFR fixing `L`, quarter length `α`, funding spread `f`, borrow fee `b` and swap
spread `s`: sell the shares, receive the dividends, earn the fee for lending the shares, repay the
loan at SOFR plus `f`, pay the fund the price return plus dividends, and receive SOFR plus `s`. -/
def dealerQuarter (n Sa Sb D L α f b s : ℝ) : ℝ :=
  n * Sb + n * D + n * Sa * α * b - n * Sa * (1 + α * (L + f))
    - (n * (Sb - Sa) + n * D) + n * Sa * α * (L + s)

/-- The mark to the fund, `τ` years before the next reset:
`V_t = (n S_t (1 + τ (L_t + s*)) + C - N_{i-1} (1 + α (L_i + s))) / (1 + L_t τ)`. -/
noncomputable def markToFund (n St τ Lt sStar C Nprev α Li s : ℝ) : ℝ :=
  (n * St * (1 + τ * (Lt + sStar)) + C - Nprev * (1 + α * (Li + s))) / (1 + Lt * τ)

/-- The payment the fund receives at the next reset: the price return on `n` shares since the
last reset price `Sprev`, the dividends `C` already paid since that reset, the dividends `n Drest`
still to come, less the funding leg `SOFR + s` on the reset notional `n Sprev`. -/
def swapPayment (n Si Sprev C Drest α Li s : ℝ) : ℝ :=
  n * (Si - Sprev) + C + n * Drest - n * Sprev * α * (Li + s)

/-- A new dealer's takeover hedge, valued at the next reset: buy `n` shares at today's price
`St` with money borrowed at SOFR `Lt` plus `f` for `τ` years, lend them out at fee `b`, collect
the dividends `n Drest` still to come, and sell at the reset price `Si`. -/
def takeoverHedge (n St τ Lt f b Si Drest : ℝ) : ℝ :=
  n * Si + n * Drest + n * St * τ * b - n * St * (1 + τ * (Lt + f))

/-- **The fair spread is the funding spread minus the borrow fee.** A dealer that hedges a total
return swap on `n > 0` shares by buying them with money borrowed at SOFR plus `f` and lending them
out at fee `b`, over `k ≥ 1` quarters of length `α > 0`, ends with zero cash on every path of
positive share prices, dividends and SOFR fixings exactly when the swap spread is `s = f - b`. -/
theorem fair_spread_eq_funding_minus_fee (n α f b s : ℝ) (k : ℕ)
    (hn : 0 < n) (hα : 0 < α) (hk : 0 < k) :
    (∀ S D L : ℕ → ℝ, (∀ i, 0 < S i) →
        ∑ i ∈ range k, dealerQuarter n (S i) (S (i + 1)) (D i) (L i) α f b s = 0)
      ↔ s = f - b := by
  constructor
  · intro h
    have h1 := h (fun _ => 1) (fun _ => 0) (fun _ => 0) (fun _ => one_pos)
    have hq : ∀ i ∈ range k, dealerQuarter n ((fun _ : ℕ => (1 : ℝ)) i) ((fun _ : ℕ => (1 : ℝ)) (i + 1))
        ((fun _ : ℕ => (0 : ℝ)) i) ((fun _ : ℕ => (0 : ℝ)) i) α f b s = n * α * (s - f + b) := by
      intro i _
      simp only [dealerQuarter]
      ring
    rw [sum_congr rfl hq, sum_const, card_range, nsmul_eq_mul] at h1
    have hk' : (k : ℝ) ≠ 0 := by exact_mod_cast hk.ne'
    have h2 : n * α * (s - f + b) = 0 := by
      rcases mul_eq_zero.mp h1 with h3 | h3
      · exact absurd h3 hk'
      · exact h3
    have hnα : n * α ≠ 0 := mul_ne_zero hn.ne' hα.ne'
    rcases mul_eq_zero.mp h2 with h3 | h3
    · exact absurd h3 hnα
    · linarith
  · intro hs S D L _
    apply sum_eq_zero
    intro i _
    simp only [dealerQuarter]
    rw [hs]
    ring

/-- **Everything that depends on the share cancels.** On any path of share prices, dividends and
SOFR fixings, the dealer's hedge ledger over `k` quarters comes to the interest and fee left on
each reset notional: `∑ N_{i-1} α (s - f + b)`, with `N_{i-1} = n S_{i-1}`. -/
theorem dealer_ledger_eq_spread_gap (n α f b s : ℝ) (k : ℕ) (S D L : ℕ → ℝ) :
    ∑ i ∈ range k, dealerQuarter n (S i) (S (i + 1)) (D i) (L i) α f b s
      = ∑ i ∈ range k, n * S i * α * (s - f + b) := by
  apply sum_congr rfl
  intro i _
  simp only [dealerQuarter]
  ring

/-- **Between resets the mark is the takeover hedge's gap.** With the fair spread `s* = f - b`
and SOFR growth `1 + L_t τ` to the next reset, for every reset price `S_i` and every dividend
still to come, the swap's payment to the fund at the reset equals the takeover hedge's result
plus the mark `V_t` carried at SOFR: `payment = hedge + V_t (1 + L_t τ)`. -/
theorem mark_eq_takeover_hedge_gap (n St Sprev τ Lt C α Li f b s Si Drest : ℝ)
    (hgrowth : 0 < 1 + Lt * τ) :
    swapPayment n Si Sprev C Drest α Li s
      = takeoverHedge n St τ Lt f b Si Drest
        + markToFund n St τ Lt (f - b) C (n * Sprev) α Li s * (1 + Lt * τ) := by
  simp only [swapPayment, takeoverHedge, markToFund]
  rw [div_mul_cancel₀ _ hgrowth.ne']
  ring

/-- The card's fair spread: funding 0.40 percent less a 1 percent fee is -0.60 percent. -/
example : (4 / 1000 : ℝ) - 1 / 100 = -6 / 1000 := by norm_num

/-- Quarter 1 of the dealer's ledger (Acme 100 to 105, dividend 0.50) nets to zero at the fair spread. -/
example : dealerQuarter 10000 100 105 (1 / 2) (1 / 20) (1 / 4) (4 / 1000) (1 / 100) (-6 / 1000) = 0 := by
  norm_num [dealerQuarter]

/-- At 0.10 percent above the fair spread the dealer gains `1,000,000 × 0.25 × 0.001 = 250` a quarter. -/
example : dealerQuarter 10000 100 105 (1 / 2) (1 / 20) (1 / 4) (4 / 1000) (1 / 100) (-5 / 1000) = 250 := by
  norm_num [dealerQuarter]

/-- The mark at three months, before the exchange: `1,050,000 + 5,000 - 1,011,000 = 44,000`. -/
example : markToFund 10000 105 0 (1 / 20) (-6 / 1000) 5000 1000000 (1 / 4) (1 / 20) (-6 / 1000) = 44000 := by
  norm_num [markToFund]

/-- Month 4, Acme at 107, two months to the reset: the mark is `1,955,600 / 121`, about 16,161.98. -/
example : markToFund 10000 107 (1 / 6) (1 / 20) (-6 / 1000) 0 1050000 (1 / 4) (1 / 20) (-6 / 1000)
    = 1955600 / 121 := by
  norm_num [markToFund]

/-- Spread set to the dealer's funding only: the three-month mark comes out at 41,500. -/
example : markToFund 10000 105 0 (1 / 20) (-6 / 1000) 5000 1000000 (1 / 4) (1 / 20) (4 / 1000) = 41500 := by
  norm_num [markToFund]

/-- Dividends left out: the three-month mark comes out at 39,000. -/
example : markToFund 10000 105 0 (1 / 20) (-6 / 1000) 0 1000000 (1 / 4) (1 / 20) (-6 / 1000) = 39000 := by
  norm_num [markToFund]

/-- Acme at 95 after three months: the mark is -56,000. -/
example : markToFund 10000 95 0 (1 / 20) (-6 / 1000) 5000 1000000 (1 / 4) (1 / 20) (-6 / 1000) = -56000 := by
  norm_num [markToFund]

/-- The cash at the four resets on the card's path (44,000, 3,450, -86,660 and 54,220) totals 15,010. -/
example :
    markToFund 10000 105 0 (1 / 20) (-6 / 1000) 5000 1000000 (1 / 4) (1 / 20) (-6 / 1000)
      + markToFund 10000 106 0 (1 / 20) (-6 / 1000) 5000 1050000 (1 / 4) (1 / 20) (-6 / 1000)
      + markToFund 10000 98 0 (1 / 20) (-6 / 1000) 5000 1060000 (1 / 4) (1 / 20) (-6 / 1000)
      + markToFund 10000 104 0 (1 / 20) (-6 / 1000) 5000 980000 (1 / 4) (1 / 20) (-6 / 1000)
      = 15010 := by
  norm_num [markToFund]

#print axioms fair_spread_eq_funding_minus_fee
#print axioms dealer_ledger_eq_spread_gap
#print axioms mark_eq_takeover_hedge_gap
