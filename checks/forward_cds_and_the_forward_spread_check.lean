-- The forward CDS: the forward par spread, forward protection over forward annuity, is the only premium that makes the long-minus-short package worth zero, it lies above, on or below the long spot spread as the curve rises, is flat or falls, and on a flat hazard every window has the same spread.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Algebra.BigOperators.Intervals

open Real

theorem geom_tel (q : ℝ) (m n : ℕ) :
    (∑ j ∈ Finset.Ioc m (m + n), q ^ j) * (1 - q) = q ^ (m + 1) - q ^ (m + n + 1) := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [show m + (n + 1) = (m + n) + 1 by omega, Finset.sum_Ioc_succ_top (by omega), add_mul, ih]
    ring

theorem int_exp_neg (k a b : ℝ) (hk : k ≠ 0) :
    (∫ t in a..b, exp (-k * t)) * k = exp (-k * a) - exp (-k * b) := by
  have hk' : -k ≠ 0 := neg_ne_zero.mpr hk
  rw [intervalIntegral.integral_comp_mul_left (fun x => exp x) hk', integral_exp, smul_eq_mul]
  field_simp
  ring

#print axioms geom_tel
#print axioms int_exp_neg

/-- A forward CDS from `T₁` to `T₂` is protection to `T₂` bought and protection to `T₁` sold at one
premium `K`, so on notional `N ≠ 0` it is worth `N[(P(T₂) - K A(T₂)) - (P(T₁) - K A(T₁))]`.
The premium that makes this zero is exactly the forward par spread
`F = (P(T₂) - P(T₁)) / (A(T₂) - A(T₁))`. When both spot contracts are at par
(`P(T₁) = s₁ A(T₁)`, `P(T₂) = s₂ A(T₂)`) and the annuities satisfy `0 < A(T₁) < A(T₂)`,
`F` sits above the long spot spread `s₂` when the curve rises (`s₁ < s₂`), equals it when the
curve is flat, and sits below it when the curve falls. -/
theorem forward_par_spread_against_long_spot_spread
    (A₁ A₂ P₁ P₂ s₁ s₂ N : ℝ) (hA₁ : 0 < A₁) (hA : A₁ < A₂)
    (hP₁ : P₁ = s₁ * A₁) (hP₂ : P₂ = s₂ * A₂) (hN : N ≠ 0) :
    (∀ K : ℝ, N * ((P₂ - K * A₂) - (P₁ - K * A₁)) = 0 ↔ K = (P₂ - P₁) / (A₂ - A₁)) ∧
    (s₁ < s₂ → s₂ < (P₂ - P₁) / (A₂ - A₁)) ∧
    (s₁ = s₂ → (P₂ - P₁) / (A₂ - A₁) = s₂) ∧
    (s₂ < s₁ → (P₂ - P₁) / (A₂ - A₁) < s₂) := by
  have hd : 0 < A₂ - A₁ := sub_pos.mpr hA
  refine ⟨fun K => ?_, fun h => ?_, fun h => ?_, fun h => ?_⟩
  · rw [mul_eq_zero, or_iff_right hN, eq_div_iff hd.ne']
    constructor <;> intro h <;> linarith
  · rw [lt_div_iff₀ hd, hP₁, hP₂]; nlinarith
  · rw [div_eq_iff hd.ne', hP₁, hP₂, h]; ring
  · rw [div_lt_iff₀ hd, hP₁, hP₂]; nlinarith

/-- The annuity-weighted identity: with both spot contracts at par and `A(T₁) < A(T₂)`, the long
spot spread times its annuity is the short spot spread times its annuity plus the forward spread
times the forward annuity, and so `F = s₂ + (s₂ - s₁) A(T₁) / (A(T₂) - A(T₁))`. -/
theorem annuity_weighted_identity
    (A₁ A₂ P₁ P₂ s₁ s₂ : ℝ) (hA : A₁ < A₂)
    (hP₁ : P₁ = s₁ * A₁) (hP₂ : P₂ = s₂ * A₂) :
    s₂ * A₂ = s₁ * A₁ + (P₂ - P₁) / (A₂ - A₁) * (A₂ - A₁) ∧
    (P₂ - P₁) / (A₂ - A₁) = s₂ + (s₂ - s₁) * A₁ / (A₂ - A₁) := by
  have hd : A₂ - A₁ ≠ 0 := (sub_pos.mpr hA).ne'
  constructor
  · rw [div_mul_cancel₀ _ hd, hP₁, hP₂]; ring
  · rw [eq_comm, ← sub_eq_zero]
    field_simp
    rw [hP₁, hP₂]; ring

/-- On a flat hazard `haz ≥ 0` and a flat rate `r ≥ 0`, not both zero, with `k = r + haz`, the
window from `m/4` to `(m+n)/4` (`n ≥ 1`) has forward annuity `∑ 0.25 e^{-k j/4}` over the premium
dates `j/4` inside it and forward protection `L haz ∫ e^{-k t} dt` over it. Their ratio is
`(L haz / k) (1 - e^{-k/4}) / (0.25 e^{-k/4})` whatever the window's start and length, so every
spot and every forward par spread is this one number. -/
theorem flat_hazard_forward_spread_is_tenor_free
    (L haz r : ℝ) (hhaz : 0 ≤ haz) (hr : 0 ≤ r) (hk : r + haz ≠ 0) (m n : ℕ) (hn : 1 ≤ n) :
    (L * haz * ∫ t in ((m : ℝ) / 4)..(((m + n : ℕ) : ℝ) / 4), exp (-(r + haz) * t)) /
      (∑ j ∈ Finset.Ioc m (m + n), (1 / 4 : ℝ) * exp (-(r + haz) * ((j : ℝ) / 4))) =
    L * haz / (r + haz) * (1 - exp (-(r + haz) / 4)) / ((1 / 4) * exp (-(r + haz) / 4)) := by
  set k := r + haz with hkdef
  have kpos : 0 < k := lt_of_le_of_ne (by positivity) (Ne.symm hk)
  set q := exp (-k / 4) with hq
  have qpos : 0 < q := exp_pos _
  have hpow : ∀ x : ℕ, exp (-k * ((x : ℝ) / 4)) = q ^ x := by
    intro x; rw [hq, ← exp_nat_mul]; ring_nf
  have hI := int_exp_neg k ((m : ℝ) / 4) (((m + n : ℕ) : ℝ) / 4) hk
  rw [hpow, hpow] at hI
  have hS : ∑ j ∈ Finset.Ioc m (m + n), (1 / 4 : ℝ) * exp (-k * ((j : ℝ) / 4))
      = (1/4) * ∑ j ∈ Finset.Ioc m (m + n), q ^ j := by
    rw [Finset.mul_sum]; simp_rw [hpow]
  have hG := geom_tel q m n
  have Spos : 0 < ∑ j ∈ Finset.Ioc m (m + n), q ^ j := by
    apply Finset.sum_pos (fun j _ => pow_pos qpos j)
    exact ⟨m + 1, by simp; omega⟩
  rw [hS]
  set I := ∫ t in ((m : ℝ) / 4)..(((m + n : ℕ) : ℝ) / 4), exp (-k * t)
  set S := ∑ j ∈ Finset.Ioc m (m + n), q ^ j
  rw [div_eq_div_iff (by positivity) (by positivity)]
  have e1 : q ^ (m + 1) - q ^ (m + n + 1) = q * (q ^ m - q ^ (m + n)) := by ring
  rw [e1, ← hI] at hG
  clear_value k I S q
  field_simp
  linear_combination (-(L * haz)) * hG

-- The card's "time weights instead of annuity weights" mistake: (5 × 250 − 1 × 120) / 4 = 282.50 bp.
example : ((5 * 250 - 1 * 120 : ℚ) / 4) = 565 / 2 := by norm_num

-- The curve's slope on the card's quotes: 250 bp − 120 bp = 130 bp.
example : (250 : ℤ) - 120 = 130 := by norm_num

#print axioms forward_par_spread_against_long_spot_spread
#print axioms annuity_weighted_identity
#print axioms flat_hazard_forward_spread_is_tenor_free
