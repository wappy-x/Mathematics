-- Valuing an existing CDS: the mark of a contract at spread c is (par spread minus c) times the risky annuity for any survival curve, two contracts on one name differ by the spread gap times the annuity, and under a flat hazard the upfront rises strictly with the hazard.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Order.Monotone.Basic

open Finset

/-- The mark of an existing CDS is the spread gap times the risky annuity.
Take any hazard curve: fee dates `i`, each paying a period of length `Δ`, with a
positive discount factor `d i` and a positive survival chance `q i`, and any
protection leg value `P`. The risky annuity is `A = ∑ Δ dᵢ qᵢ` and the par spread is
`s = P / A`. Then the contract at spread `c`, worth protection leg minus fee leg
`P - ∑ c Δ dᵢ qᵢ` to the buyer, is worth exactly `(s - c) A`. -/
theorem mark_eq_spread_gap_mul_risky_annuity {n : ℕ} (hn : 0 < n)
    (Δ P c : ℝ) (d q : Fin n → ℝ)
    (hΔ : 0 < Δ) (hd : ∀ i, 0 < d i) (hq : ∀ i, 0 < q i) :
    P - ∑ i, c * Δ * d i * q i
      = (P / (∑ i, Δ * d i * q i) - c) * (∑ i, Δ * d i * q i) := by
  have hA : 0 < ∑ i, Δ * d i * q i := by
    have : Nonempty (Fin n) := ⟨⟨0, hn⟩⟩
    exact Finset.sum_pos (fun i _ => by have := hd i; have := hq i; positivity) Finset.univ_nonempty
  have hs : ∑ i, c * Δ * d i * q i = c * ∑ i, Δ * d i * q i := by
    rw [Finset.mul_sum]; refine Finset.sum_congr rfl (fun i _ => by ring)
  rw [hs, sub_mul, div_mul_cancel₀ _ hA.ne']

/-- Two contracts on the same name, same dates, same protection leg `P`, differing
only in their spreads `c₁` and `c₂`, differ in value by `(c₂ - c₁)` times the
risky annuity: the protection legs cancel exactly. -/
theorem mark_difference_eq_coupon_gap_mul_annuity {n : ℕ}
    (Δ P c₁ c₂ : ℝ) (d q : Fin n → ℝ) :
    (P - ∑ i, c₁ * Δ * d i * q i) - (P - ∑ i, c₂ * Δ * d i * q i)
      = (c₂ - c₁) * ∑ i, Δ * d i * q i := by
  rw [Finset.mul_sum]
  have : ∑ i, (c₂ - c₁) * (Δ * d i * q i) = ∑ i, c₂ * Δ * d i * q i - ∑ i, c₁ * Δ * d i * q i := by
    rw [← Finset.sum_sub_distrib]
    exact Finset.sum_congr rfl (fun i _ => by ring)
  rw [this]; ring

/-- Under one flat hazard `h`, with recovery `R < 1`, riskless rate `r ≥ 0`,
maturity `T > 0`, and fee dates `Δ, 2Δ, …, nΔ`, the upfront on a contract with
coupon `c ≥ 0`,
`U(h) = (1 - R) · h/(r + h) · (1 - e^{-(r+h)T}) - c · ∑ Δ e^{-(r+h) Δ i}`,
is strictly increasing in the hazard `h ≥ 0`. This is why every upfront in range
converts back to exactly one hazard, and hence one spread. -/
theorem upfront_strictMonoOn_hazard (R r T Δ c : ℝ) (n : ℕ)
    (hR : R < 1) (hr : 0 ≤ r) (hT : 0 < T) (hΔ : 0 < Δ) (hc : 0 ≤ c) :
    StrictMonoOn
      (fun h : ℝ => (1 - R) * (h / (r + h)) * (1 - Real.exp (-(r + h) * T))
        - c * ∑ i ∈ Icc 1 n, Δ * Real.exp (-(r + h) * (Δ * i)))
      (Set.Ici 0) := by
  intro x hx y hy hxy
  simp only [Set.mem_Ici] at hx hy
  have hy0 : 0 < y := lt_of_le_of_lt hx hxy
  -- fee sum is antitone
  have hsum : ∑ i ∈ Icc 1 n, Δ * Real.exp (-(r + y) * (Δ * i))
      ≤ ∑ i ∈ Icc 1 n, Δ * Real.exp (-(r + x) * (Δ * i)) := by
    refine Finset.sum_le_sum (fun i _ => ?_)
    have hi : (0:ℝ) ≤ i := Nat.cast_nonneg i
    have : 0 ≤ Δ * (i:ℝ) := by positivity
    apply mul_le_mul_of_nonneg_left _ hΔ.le
    apply Real.exp_le_exp.mpr
    nlinarith
  have hfee := mul_le_mul_of_nonneg_left hsum hc
  -- protection part
  have ha1 : 0 ≤ x / (r + x) := by positivity
  have ha2 : 0 < y / (r + y) := by positivity
  have ha : x / (r + x) ≤ y / (r + y) := by
    rcases hx.eq_or_lt with h0 | h0
    · subst h0; simp; positivity
    · rw [div_le_div_iff₀ (by linarith) (by linarith)]
      nlinarith
  have hb1 : 0 ≤ 1 - Real.exp (-(r + x) * T) := by
    have : Real.exp (-(r + x) * T) ≤ 1 := Real.exp_le_one_iff.mpr (by nlinarith)
    linarith
  have hb : 1 - Real.exp (-(r + x) * T) < 1 - Real.exp (-(r + y) * T) := by
    have : Real.exp (-(r + y) * T) < Real.exp (-(r + x) * T) := Real.exp_lt_exp.mpr (by nlinarith)
    linarith
  have hprod : x / (r + x) * (1 - Real.exp (-(r + x) * T))
      < y / (r + y) * (1 - Real.exp (-(r + y) * T)) :=
    calc x / (r + x) * (1 - Real.exp (-(r + x) * T))
        ≤ y / (r + y) * (1 - Real.exp (-(r + x) * T)) := mul_le_mul_of_nonneg_right ha hb1
      _ < y / (r + y) * (1 - Real.exp (-(r + y) * T)) := mul_lt_mul_of_pos_left hb ha2
  have hR' : 0 < 1 - R := by linarith
  have := mul_lt_mul_of_pos_left hprod hR'
  simp only
  rw [mul_assoc, mul_assoc]
  linarith

-- The card's whole-number figures.
-- Spread gap on the old trade: 200 bp today against 120 bp on the contract.
example : (200 : ℤ) - 120 = 80 := by norm_num
-- The usual mistake: 80 bp a year for 5 years on $10,000,000, with no discounting
-- and no survival, is $400,000.
example : (80 : ℕ) * 5 * 10000000 / 10000 = 400000 := by norm_num
-- Coupon gap between the two standard coupons: 500 bp minus 100 bp.
example : (500 : ℤ) - 100 = 400 := by norm_num
-- Upfront signs at 250 bp: positive gap on coupon 100, negative on coupon 500.
example : (250 : ℤ) - 100 = 150 ∧ (250 : ℤ) - 500 = -250 := by norm_num

#print axioms mark_eq_spread_gap_mul_risky_annuity
#print axioms mark_difference_eq_coupon_gap_mul_annuity
#print axioms upfront_strictMonoOn_hazard
