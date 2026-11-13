-- Marking a variance swap: under a linear no-arbitrage price, a running variance swap is worth the discounted notional times the time-weighted banked plus quoted variance minus the strike, and two quoted expiries fix the fair forward variance between them.
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Algebra.Module.LinearMap.Defs
import Mathlib.Analysis.SpecialFunctions.Exp

open Finset

/-- **Marking a running variance swap.** Scenarios are `Ω`; `ret ω i` is the daily log return on
trading day `i` in scenario `ω`. The swap lives `n` trading days, `m ≤ n` of them are gone, and
those returns `ρ i` are already known in every scenario. Realised variance is annualised with
252 trading days: the banked part is `σR² = (252/m) Σ_{i<m} ρ i²`, the rest is
`(252/(n-m)) Σ_{m ≤ i < n} ret ω i²`, and at expiry the buyer receives
`N * ((252/n) Σ_{i<n} ret ω i² - Kvar)`.
Prices today form a linear functional `P` on payoffs paid at expiry (law of one price). A sure
dollar at expiry costs `exp(-r τ)`, with `τ = (n - m)/252` years left, and a fresh swap on the
rest struck at the quoted `Krem` costs nothing to enter. Then the swap's mark is
`D * N * ((m/n) σR² + ((n-m)/n) Krem - Kvar)` with `D = exp(-r τ)`: no model of the price enters. -/
theorem variance_swap_mark {Ω : Type*} (P : (Ω → ℝ) →ₗ[ℝ] ℝ)
    (ret : Ω → ℕ → ℝ) (ρ : ℕ → ℝ) (m n : ℕ) (hmn : m ≤ n)
    (hpast : ∀ ω i, i < m → ret ω i = ρ i)
    (N Kvar Krem r : ℝ)
    (hbond : P (fun _ => 1) = Real.exp (-r * (((n : ℝ) - m) / 252)))
    (hfresh : P (fun ω => (252 / ((n : ℝ) - m)) * ∑ i ∈ Ico m n, ret ω i ^ 2 - Krem) = 0) :
    P (fun ω => N * ((252 / (n : ℝ)) * ∑ i ∈ range n, ret ω i ^ 2 - Kvar)) =
      Real.exp (-r * (((n : ℝ) - m) / 252)) * N *
        ((m : ℝ) / n * ((252 / (m : ℝ)) * ∑ i ∈ range m, ρ i ^ 2)
          + ((n : ℝ) - m) / n * Krem - Kvar) := by
  set S := ∑ i ∈ range m, ρ i ^ 2 with hS
  have hpastsum : ∀ ω, ∑ i ∈ range m, ret ω i ^ 2 = S := fun ω =>
    Finset.sum_congr rfl (fun i hi => by rw [hpast ω i (Finset.mem_range.mp hi)])
  have hmS : (m : ℝ) / n * ((252 / (m : ℝ)) * S) = 252 / (n : ℝ) * S := by
    rcases Nat.eq_zero_or_pos m with h0 | hpos
    · subst h0; simp [hS]
    · have : (m : ℝ) ≠ 0 := by exact_mod_cast hpos.ne'
      field_simp
  rw [hmS]
  rcases eq_or_lt_of_le hmn with heq | hlt
  · subst heq
    simp only [sub_self, zero_div, mul_zero, Real.exp_zero, zero_mul] at hbond ⊢
    have : (fun ω => N * ((252 / (m : ℝ)) * ∑ i ∈ range m, ret ω i ^ 2 - Kvar))
        = (N * ((252 / (m : ℝ)) * S - Kvar)) • (fun _ : Ω => (1 : ℝ)) := by
      funext ω; simp [hpastsum ω]
    rw [this, map_smul, hbond, smul_eq_mul]; ring
  · have hnm : (n : ℝ) - m ≠ 0 := by
      have : (m : ℝ) < n := by exact_mod_cast hlt
      linarith
    have hn : (n : ℝ) ≠ 0 := by
      have : (m : ℝ) < n := by exact_mod_cast hlt
      have : (0 : ℝ) ≤ m := Nat.cast_nonneg m
      linarith
    have key : (fun ω => N * ((252 / (n : ℝ)) * ∑ i ∈ range n, ret ω i ^ 2 - Kvar))
        = (N * (252 / (n : ℝ) * S + ((n : ℝ) - m) / n * Krem - Kvar)) • (fun _ : Ω => (1 : ℝ))
          + (N * (((n : ℝ) - m) / n)) •
            (fun ω => (252 / ((n : ℝ) - m)) * ∑ i ∈ Ico m n, ret ω i ^ 2 - Krem) := by
      funext ω
      simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]
      rw [← Finset.sum_range_add_sum_Ico _ hmn, hpastsum ω]
      field_simp
      ring
    rw [key, map_add, map_smul, map_smul, hbond, hfresh, smul_eq_mul, smul_eq_mul]
    ring

/-- **Forward variance from two expiries.** Take two variance swaps quoted today, to expiries
`0 < T₁ < T₂`, struck at `σ₁²` and `σ₂²` (total variances `w₁ = σ₁² T₁`, `w₂ = σ₂² T₂`).
Realised variance adds along the calendar: `v₀₂ = (T₁/T₂) v₀₁ + ((T₂-T₁)/T₂) v₁₂` in every
scenario. If prices are linear and both swaps cost nothing to enter, then a swap on the variance
`v₁₂` between the expiries, struck at `ξ = (w₂ - w₁)/(T₂ - T₁)`, also costs nothing: `ξ` is the
fair forward variance. And `ξ` is a possible variance (`0 ≤ ξ`) exactly when `w₁ ≤ w₂`. -/
theorem forward_variance_fair_strike {Ω : Type*} (P : (Ω → ℝ) →ₗ[ℝ] ℝ)
    (T₁ T₂ σ₁ σ₂ : ℝ) (h₁ : 0 < T₁) (h₁₂ : T₁ < T₂)
    (v₀₁ v₀₂ v₁₂ : Ω → ℝ)
    (hsplit : ∀ ω, v₀₂ ω = T₁ / T₂ * v₀₁ ω + (T₂ - T₁) / T₂ * v₁₂ ω)
    (hnear : P (fun ω => v₀₁ ω - σ₁ ^ 2) = 0)
    (hfar : P (fun ω => v₀₂ ω - σ₂ ^ 2) = 0) :
    P (fun ω => v₁₂ ω - (σ₂ ^ 2 * T₂ - σ₁ ^ 2 * T₁) / (T₂ - T₁)) = 0 ∧
      (0 ≤ (σ₂ ^ 2 * T₂ - σ₁ ^ 2 * T₁) / (T₂ - T₁) ↔ σ₁ ^ 2 * T₁ ≤ σ₂ ^ 2 * T₂) := by
  have hd : T₂ - T₁ ≠ 0 := by linarith
  have hT2 : T₂ ≠ 0 := by linarith
  refine ⟨?_, ?_⟩
  · have key : (fun ω => v₁₂ ω - (σ₂ ^ 2 * T₂ - σ₁ ^ 2 * T₁) / (T₂ - T₁))
        = (T₂ / (T₂ - T₁)) • (fun ω => v₀₂ ω - σ₂ ^ 2)
          - (T₁ / (T₂ - T₁)) • (fun ω => v₀₁ ω - σ₁ ^ 2) := by
      funext ω
      simp only [Pi.sub_apply, Pi.smul_apply, smul_eq_mul]
      rw [hsplit ω]
      field_simp
      ring
    rw [key, map_sub, map_smul, map_smul, hnear, hfar]; simp
  · have hpos : 0 < T₂ - T₁ := by linarith
    rw [div_nonneg_iff]
    constructor
    · rintro (⟨h, _⟩ | ⟨_, h⟩)
      · linarith
      · linarith
    · intro h; left; exact ⟨by linarith, hpos.le⟩

/-- **The running swap breaks even at the forward variance.** A swap over `[0, T₂]` struck at
the inception quote `σ₂²`, marked at `T₁` with the first stretch realised at the near quote `σ₁²`
and the rest quoted at the forward variance `ξ = (σ₂² T₂ - σ₁² T₁)/(T₂ - T₁)`, has mark zero. -/
theorem mark_zero_at_forward_variance (T₁ T₂ σ₁ σ₂ D N : ℝ) (h₁ : 0 < T₁) (h₁₂ : T₁ < T₂) :
    D * N * (T₁ / T₂ * σ₁ ^ 2 + (T₂ - T₁) / T₂ * ((σ₂ ^ 2 * T₂ - σ₁ ^ 2 * T₁) / (T₂ - T₁))
      - σ₂ ^ 2) = 0 := by
  have hd : T₂ - T₁ ≠ 0 := by linarith
  have hT2 : T₂ ≠ 0 := by linarith
  have : T₁ / T₂ * σ₁ ^ 2 + (T₂ - T₁) / T₂ * ((σ₂ ^ 2 * T₂ - σ₁ ^ 2 * T₁) / (T₂ - T₁))
      - σ₂ ^ 2 = 0 := by
    field_simp
    ring
  rw [this, mul_zero]

-- Card's worked numbers, in variance points (volatility points squared).
-- Variance notional: 100,000 vega notional over twice the 20-point strike.
example : (100000 : ℚ) / (2 * 20) = 2500 := by norm_num
-- Expected year minus strike: half a year at 18 banked, half quoted at 20, strike 20 squared.
example : (1 / 2 : ℚ) * 18 ^ 2 + 1 / 2 * 20 ^ 2 - 20 ^ 2 = -38 := by norm_num
-- Payoff if the rest comes in at 20: 2,500 dollars times minus 38 points.
example : (2500 : ℚ) * ((1 / 2) * 18 ^ 2 + 1 / 2 * 20 ^ 2 - 20 ^ 2) = -95000 := by norm_num
-- Forward variance, 18 to half a year then 20 to a year: 476 points (0.0476).
example : ((20 : ℚ) ^ 2 * 1 - 18 ^ 2 * (1 / 2)) / (1 - 1 / 2) = 476 := by norm_num
-- Break-even: half at 18 squared plus half at the forward variance equals the strike.
example : (1 / 2 : ℚ) * 18 ^ 2 + 1 / 2 * 476 - 20 ^ 2 = 0 := by norm_num
-- No forward: 24 to half a year and 16 to a year give a negative forward variance.
example : ((16 : ℚ) ^ 2 * 1 - 24 ^ 2 * (1 / 2)) / (1 - 1 / 2) = -64 := by norm_num
-- Averaging the vols is wrong: 19 squared is 361, not the 362 the year expects.
example : (19 : ℚ) ^ 2 = 361 ∧ (1 / 2 : ℚ) * 18 ^ 2 + 1 / 2 * 20 ^ 2 = 362 := by norm_num
-- Settlement at month 12: 20.5 percent realised, 2,500 dollars per point.
example : (2500 : ℚ) * ((41 / 2) ^ 2 - 20 ^ 2) = 50625 := by norm_num

#print axioms variance_swap_mark
#print axioms forward_variance_fair_strike
#print axioms mark_zero_at_forward_variance
