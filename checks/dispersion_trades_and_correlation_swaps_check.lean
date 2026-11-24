-- Dispersion: a short index variance swap against long member variance swaps sized to cancel each share's volatility carries exactly the index strike and pays implied minus realised correlation times the realised cross term.
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Algebra.BigOperators.Field

open Finset

/-- Each member leg's notional times a variance splits into an own term and an implied-correlation
cross term. -/
theorem disp_member_term
    {ι : Type*} [Fintype ι] [DecidableEq ι]
    (w σ s N : ι → ℝ) (ρimpl NI : ℝ)
    (hN : ∀ i, N i = NI * (w i ^ 2 + ρimpl * w i * ∑ j ∈ univ.erase i, w j * σ j / σ i))
    (i : ι) :
    N i * s i ^ 2 = NI * (w i ^ 2 * s i ^ 2
      + ρimpl * ∑ j ∈ univ.erase i, w i * w j * (σ j / σ i) * s i ^ 2) := by
  rw [hN i]
  have h1 : ∑ j ∈ univ.erase i, w i * w j * (σ j / σ i) * s i ^ 2
      = w i * (∑ j ∈ univ.erase i, w j * σ j / σ i) * s i ^ 2 := by
    rw [mul_sum, sum_mul]
    refine sum_congr rfl ?_
    intro j _
    ring
  rw [h1]
  ring

/-- With positive volatilities the square root of the product of variances is the product of
volatilities. -/
theorem disp_sqrt_eq
    {ι : Type*} (σ : ι → ℝ) (hσ : ∀ i, 0 < σ i) (i j : ι) :
    Real.sqrt (σ i ^ 2 * σ j ^ 2) = σ i * σ j := by
  rw [show σ i ^ 2 * σ j ^ 2 = (σ i * σ j) ^ 2 by ring]
  exact Real.sqrt_sq (mul_pos (hσ i) (hσ j)).le

/-- Strike balance, proved before the main theorems so they can use it. -/
theorem disp_balance_aux
    {ι : Type*} [Fintype ι] [DecidableEq ι]
    (w σ N : ι → ℝ) (ρimpl NI KI : ℝ)
    (hσ : ∀ i, 0 < σ i)
    (hKI : KI = ∑ i, w i ^ 2 * σ i ^ 2
      + ρimpl * ∑ i, ∑ j ∈ univ.erase i, w i * w j * Real.sqrt (σ i ^ 2 * σ j ^ 2))
    (hN : ∀ i, N i = NI * (w i ^ 2 + ρimpl * w i * ∑ j ∈ univ.erase i, w j * σ j / σ i)) :
    ∑ i, N i * σ i ^ 2 = NI * KI := by
  have key : ∀ i, N i * σ i ^ 2 = NI * (w i ^ 2 * σ i ^ 2
      + ρimpl * ∑ j ∈ univ.erase i, w i * w j * Real.sqrt (σ i ^ 2 * σ j ^ 2)) := by
    intro i
    rw [disp_member_term w σ σ N ρimpl NI hN i]
    congr 3
    refine sum_congr rfl ?_
    intro j _
    rw [disp_sqrt_eq σ hσ i j]
    have := (hσ i).ne'
    field_simp
  simp_rw [key]
  rw [hKI, ← mul_sum, sum_add_distrib, ← mul_sum]

/-- The general profit identity, proved before the main theorems so they can use it. -/
theorem disp_general_aux
    {ι : Type*} [Fintype ι] [DecidableEq ι]
    (w σ s N : ι → ℝ) (ρimpl ρreal NI KI sI : ℝ)
    (hσ : ∀ i, 0 < σ i)
    (hKI : KI = ∑ i, w i ^ 2 * σ i ^ 2
      + ρimpl * ∑ i, ∑ j ∈ univ.erase i, w i * w j * Real.sqrt (σ i ^ 2 * σ j ^ 2))
    (hsI : sI ^ 2 = ∑ i, w i ^ 2 * s i ^ 2
      + ρreal * ∑ i, ∑ j ∈ univ.erase i, w i * w j * s i * s j)
    (hN : ∀ i, N i = NI * (w i ^ 2 + ρimpl * w i * ∑ j ∈ univ.erase i, w j * σ j / σ i)) :
    NI * (KI - sI ^ 2) + ∑ i, N i * (s i ^ 2 - σ i ^ 2)
      = NI * (ρimpl * ∑ i, ∑ j ∈ univ.erase i, w i * w j * (σ j / σ i) * s i ^ 2
          - ρreal * ∑ i, ∑ j ∈ univ.erase i, w i * w j * s i * s j) := by
  have hbal := disp_balance_aux w σ N ρimpl NI KI hσ hKI hN
  have hs : ∑ i, N i * s i ^ 2 = NI * (∑ i, w i ^ 2 * s i ^ 2
      + ρimpl * ∑ i, ∑ j ∈ univ.erase i, w i * w j * (σ j / σ i) * s i ^ 2) := by
    simp_rw [disp_member_term w σ s N ρimpl NI hN]
    rw [← mul_sum, sum_add_distrib, ← mul_sum]
  simp_rw [mul_sub]
  rw [sum_sub_distrib, hs, hbal, hsI]
  ring

#print axioms disp_member_term
#print axioms disp_sqrt_eq
#print axioms disp_balance_aux
#print axioms disp_general_aux

/-- The dispersion trade pays the correlation gap. Shares numbered by a finite set have index
weights `w i`, implied volatilities `σ i > 0` (variance strikes `σ i ^ 2`) and realised
volatilities `s i`. The index variance strike `KI` is the members' own terms plus implied
correlation `ρimpl` times the cross sum of `w i * w j * √(K i * K j)` over ordered pairs `i ≠ j`.
The index's realised variance `sI ^ 2` is the members' own realised terms plus realised
correlation `ρreal` times the realised cross term `C = ∑_{i ≠ j} w i * w j * s i * s j`
(value weights fixed over each day). Sell `NI` of index variance and buy
`N i = NI * (w i ^ 2 + ρimpl * w i * ∑_{j ≠ i} w j * σ j / σ i)` of each member's.
If every share realises the same multiple `lam` of its implied volatility, the profit at expiry
`NI * (KI - sI ^ 2) + ∑ i, N i * (s i ^ 2 - σ i ^ 2)` equals `NI * (ρimpl - ρreal) * C`. -/
theorem dispersion_profit_eq_correlation_gap_times_cross_term
    {ι : Type*} [Fintype ι] [DecidableEq ι]
    (w σ s N : ι → ℝ) (ρimpl ρreal lam NI KI sI : ℝ)
    (hσ : ∀ i, 0 < σ i)
    (hKI : KI = ∑ i, w i ^ 2 * σ i ^ 2
      + ρimpl * ∑ i, ∑ j ∈ univ.erase i, w i * w j * Real.sqrt (σ i ^ 2 * σ j ^ 2))
    (hsI : sI ^ 2 = ∑ i, w i ^ 2 * s i ^ 2
      + ρreal * ∑ i, ∑ j ∈ univ.erase i, w i * w j * s i * s j)
    (hN : ∀ i, N i = NI * (w i ^ 2 + ρimpl * w i * ∑ j ∈ univ.erase i, w j * σ j / σ i))
    (hprop : ∀ i, s i = lam * σ i) :
    NI * (KI - sI ^ 2) + ∑ i, N i * (s i ^ 2 - σ i ^ 2)
      = NI * (ρimpl - ρreal) * ∑ i, ∑ j ∈ univ.erase i, w i * w j * s i * s j := by
  rw [disp_general_aux w σ s N ρimpl ρreal NI KI sI hσ hKI hsI hN]
  have hA : ∑ i, ∑ j ∈ univ.erase i, w i * w j * (σ j / σ i) * s i ^ 2
      = ∑ i, ∑ j ∈ univ.erase i, w i * w j * s i * s j := by
    refine sum_congr rfl ?_
    intro i _
    refine sum_congr rfl ?_
    intro j _
    rw [hprop i, hprop j]
    have := (hσ i).ne'
    field_simp
  rw [hA]
  ring

/-- The profit identity without proportional volatilities. With the same strikes, realised index
variance and member notionals as above, but any realised volatilities, the profit is
`NI * (ρimpl * ∑_{i ≠ j} w i * w j * (σ j / σ i) * s i ^ 2 - ρreal * ∑_{i ≠ j} w i * w j * s i * s j)`.
The first sum is where the second bet, on the shares' volatilities spreading apart, lives. -/
theorem dispersion_profit_general
    {ι : Type*} [Fintype ι] [DecidableEq ι]
    (w σ s N : ι → ℝ) (ρimpl ρreal NI KI sI : ℝ)
    (hσ : ∀ i, 0 < σ i)
    (hKI : KI = ∑ i, w i ^ 2 * σ i ^ 2
      + ρimpl * ∑ i, ∑ j ∈ univ.erase i, w i * w j * Real.sqrt (σ i ^ 2 * σ j ^ 2))
    (hsI : sI ^ 2 = ∑ i, w i ^ 2 * s i ^ 2
      + ρreal * ∑ i, ∑ j ∈ univ.erase i, w i * w j * s i * s j)
    (hN : ∀ i, N i = NI * (w i ^ 2 + ρimpl * w i * ∑ j ∈ univ.erase i, w j * σ j / σ i)) :
    NI * (KI - sI ^ 2) + ∑ i, N i * (s i ^ 2 - σ i ^ 2)
      = NI * (ρimpl * ∑ i, ∑ j ∈ univ.erase i, w i * w j * (σ j / σ i) * s i ^ 2
          - ρreal * ∑ i, ∑ j ∈ univ.erase i, w i * w j * s i * s j) := by
  exact disp_general_aux w σ s N ρimpl ρreal NI KI sI hσ hKI hsI hN

/-- The legs balance in strike. With the index strike and the volatility-neutral member
notionals above, the bought member legs carry exactly the index's strike:
`∑ i, N i * σ i ^ 2 = NI * KI`. -/
theorem member_strikes_balance_index_strike
    {ι : Type*} [Fintype ι] [DecidableEq ι]
    (w σ N : ι → ℝ) (ρimpl NI KI : ℝ)
    (hσ : ∀ i, 0 < σ i)
    (hKI : KI = ∑ i, w i ^ 2 * σ i ^ 2
      + ρimpl * ∑ i, ∑ j ∈ univ.erase i, w i * w j * Real.sqrt (σ i ^ 2 * σ j ^ 2))
    (hN : ∀ i, N i = NI * (w i ^ 2 + ρimpl * w i * ∑ j ∈ univ.erase i, w j * σ j / σ i)) :
    ∑ i, N i * σ i ^ 2 = NI * KI := by
  exact disp_balance_aux w σ N ρimpl NI KI hσ hKI hN

-- House pair: weights 1/2, implied volatilities 1/5, implied correlation 1/2.
-- Member strikes 1/25; index strike 3/100; implied correlation back from the strikes 1/2.
example : ((1 : ℚ) / 5) ^ 2 = 1 / 25 := by norm_num
example : 2 * ((1 : ℚ) / 2) ^ 2 * (1 / 25) + 1 / 2 * (2 * (1 / 2) * (1 / 2) * (1 / 25)) = 3 / 100 := by
  norm_num
example : ((3 : ℚ) / 100 - 2 / 100) / (2 / 100) = 1 / 2 := by norm_num
-- Member notional 3/8 per unit of index notional; the members' strikes add to the index's.
example : ((1 : ℚ) / 2) ^ 2 + 1 / 2 * (1 / 2) * (1 / 2) = 3 / 8 := by norm_num
example : 2 * ((3 : ℚ) / 8) * (1 / 25) = 3 / 100 := by norm_num
-- Realised correlation 3/10: index realises 26/1000; the trade earns 4/1000 = (1/2 - 3/10) * 2/100.
example : (2 : ℚ) / 100 + 3 / 10 * (2 / 100) = 26 / 1000 := by norm_num
example : (3 : ℚ) / 100 - 26 / 1000 = 4 / 1000 := by norm_num
example : ((1 : ℚ) / 2 - 3 / 10) * (2 * (1 / 2) * (1 / 2) * (1 / 5) * (1 / 5)) = 4 / 1000 := by
  norm_num
-- At correlation 4/5 the trade loses 6/1000; in a 30 percent year at 3/10 it earns 9/1000.
example : ((1 : ℚ) / 2 - 4 / 5) * (2 / 100) = -6 / 1000 := by norm_num
example : ((1 : ℚ) / 2 - 3 / 10) * (2 * (1 / 2) * (1 / 2) * (3 / 10) * (3 / 10)) = 9 / 1000 := by
  norm_num
-- Volatility-gap bet: shares realise 1/4 and 3/20 at correlation 1/2, the trade earns 1/800.
example : 2 * ((1 : ℚ) / 2) * (1 / 2) * ((1 / 2 - 1 / 2) * (1 / 4) * (3 / 20)
    + 1 / 2 * (1 / 2) * (1 / 4 - 3 / 20) ^ 2) = 1 / 800 := by norm_num
-- Two-state world: member strike 9/160, variance-weighted correlation 7/10, fair strike 11/20.
example : (1 : ℚ) / 2 * (3 / 20) ^ 2 + 1 / 2 * (3 / 10) ^ 2 = 9 / 160 := by norm_num
example : ((1 : ℚ) / 2 * (3 / 10) * (3 / 20) ^ 2 + 1 / 2 * (4 / 5) * (3 / 10) ^ 2) / (9 / 160)
    = 7 / 10 := by norm_num
example : (1 : ℚ) / 2 * (3 / 10) + 1 / 2 * (4 / 5) = 11 / 20 := by norm_num
-- Large-index shortcut on two names: 3/100 / (1/5)^2 = 3/4, not 1/2.
example : ((3 : ℚ) / 100) / (1 / 2 * (1 / 5) + 1 / 2 * (1 / 5)) ^ 2 = 3 / 4 := by norm_num

#print axioms dispersion_profit_eq_correlation_gap_times_cross_term
#print axioms dispersion_profit_general
#print axioms member_strikes_balance_index_strike
