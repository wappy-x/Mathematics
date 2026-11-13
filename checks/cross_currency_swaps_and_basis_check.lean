-- Cross-currency swaps: a floating leg discounted on its own curve is worth its principal, the fair basis is the unique spread that puts the euro leg at par, and the bootstrapped curve matches every quote exactly when each year's rate is the floating rate plus the basis.
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Positivity
import Mathlib.Algebra.BigOperators.Ring.Finset

open Finset

/-- Fair basis (Step 3). Let `D i` be today's price of one euro paid in year `i`
on the dollar-funded euro curve, all positive, and let `f i` be the euro floating
rate paid in year `i`. For a swap of `T ≥ 1` years, a spread `s` puts the euro leg
at par, `∑_{i=1}^T (f i + s) D i + D T = 1`, if and only if
`s = (1 - D T - ∑_{i=1}^T f i D i) / A`, where `A = ∑_{i=1}^T D i` is the annuity.
So the fair basis exists and is unique. -/
theorem fair_basis_unique (D f : ℕ → ℝ) (T : ℕ) (hT : 1 ≤ T)
    (hD : ∀ i, 0 < D i) (s : ℝ) :
    (∑ i ∈ Icc 1 T, (f i + s) * D i) + D T = 1 ↔
      s = (1 - D T - ∑ i ∈ Icc 1 T, f i * D i) / ∑ i ∈ Icc 1 T, D i := by
  have hA : 0 < ∑ i ∈ Icc 1 T, D i :=
    Finset.sum_pos (fun i _ => hD i) ⟨1, Finset.mem_Icc.mpr ⟨le_refl 1, hT⟩⟩
  have hsplit : (∑ i ∈ Icc 1 T, (f i + s) * D i)
      = (∑ i ∈ Icc 1 T, f i * D i) + s * ∑ i ∈ Icc 1 T, D i := by
    rw [Finset.mul_sum, ← Finset.sum_add_distrib]
    refine Finset.sum_congr rfl (fun i _ => ?_)
    ring
  rw [hsplit, eq_div_iff hA.ne']
  constructor <;> intro h <;> linarith

/-- A floating leg is worth its principal on its own curve (Step 1). If `P` is a
discount curve with `P 0 = 1` and all `P i > 0`, and the rate paid in year `i` is
set by the curve, `1 + f i = P (i - 1) / P i`, then for every number of years `T`
the discounted coupons plus the discounted principal add up to 1 per unit of
principal: `∑_{i=1}^T f i P i + P T = 1`. The rates need not be flat. -/
theorem floating_leg_at_par (P f : ℕ → ℝ) (hP0 : P 0 = 1) (hP : ∀ i, 0 < P i)
    (hf : ∀ i, 1 ≤ i → 1 + f i = P (i - 1) / P i) (T : ℕ) :
    (∑ i ∈ Icc 1 T, f i * P i) + P T = 1 := by
  induction T with
  | zero => simp [hP0]
  | succ n ih =>
    rw [Finset.sum_Icc_succ_top (by omega)]
    have h1 := hf (n + 1) (by omega)
    simp only [Nat.add_sub_cancel] at h1
    have hpos := hP (n + 1)
    have h2 : f (n + 1) * P (n + 1) = P n - P (n + 1) := by
      have : (1 + f (n + 1)) * P (n + 1) = P n := by
        rw [h1]; exact div_mul_cancel₀ _ hpos.ne'
      linarith
    linarith

/-- The bootstrap (Step 4). Let `D` be a positive curve with `D 0 = 1`, `f i` the
euro floating rates, and `s` a basis quoted the same at every maturity. The swap at
basis `s` is at par for every maturity `T ≥ 1` if and only if each year's rate on
the curve is the floating rate plus the basis: `D (i - 1) / D i = 1 + f i + s`
for every `i ≥ 1`. So the curve that matches all quotes exists and is unique. -/
theorem bootstrap_matches_every_quote_iff (D f : ℕ → ℝ) (s : ℝ)
    (hD0 : D 0 = 1) (hD : ∀ i, 0 < D i) :
    (∀ T, 1 ≤ T → (∑ i ∈ Icc 1 T, (f i + s) * D i) + D T = 1) ↔
      (∀ i, 1 ≤ i → D (i - 1) / D i = 1 + f i + s) := by
  constructor
  · intro h i hi
    obtain ⟨n, rfl⟩ : ∃ n, i = n + 1 := ⟨i - 1, by omega⟩
    simp only [Nat.add_sub_cancel]
    have hprev : (∑ j ∈ Icc 1 n, (f j + s) * D j) + D n = 1 := by
      rcases Nat.eq_zero_or_pos n with hn | hn
      · subst hn; simp [hD0]
      · exact h n hn
    have hcur := h (n + 1) (by omega)
    rw [Finset.sum_Icc_succ_top (by omega)] at hcur
    have hpos := hD (n + 1)
    rw [div_eq_iff hpos.ne']
    linarith
  · intro h T _
    clear ‹1 ≤ T›
    induction T with
    | zero => simp [hD0]
    | succ n ih =>
      rw [Finset.sum_Icc_succ_top (by omega)]
      have h1 := h (n + 1) (by omega)
      simp only [Nat.add_sub_cancel] at h1
      have hpos := hD (n + 1)
      rw [div_eq_iff hpos.ne'] at h1
      linarith

-- At spot 1.10 dollars per euro, EUR 100 million is USD 110 million.
example : (100000000 : ℚ) * (11 / 10) = 110000000 := by norm_num

-- Just after the start, the swap is worth 100m × spot − 110m dollars:
-- spot 1.20 gives +10m, spot 1.00 gives −10m, spot 1.05 gives −5m.
example : (100 : ℚ) * (6 / 5) - 110 = 10 := by norm_num
example : (100 : ℚ) * 1 - 110 = -10 := by norm_num
example : (100 : ℚ) * (21 / 20) - 110 = -5 := by norm_num

#print axioms fair_basis_unique
#print axioms floating_leg_at_par
#print axioms bootstrap_matches_every_quote_iff
