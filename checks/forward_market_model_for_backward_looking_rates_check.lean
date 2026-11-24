-- The forward market model: extended bonds keep every bond ratio a product of compounded-forward factors at every date, and the terminal and spot drifts that follow make each bond ratio a fair bet and keep the rate accruing now in the spot drift.
import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Algebra.BigOperators.Intervals

open Finset

/-- **The terminal drift is the right one.** Periods are numbered `1, …, M`. At one instant, rate
`k` has weight `a_k` (on the card `a_k = τ / (1 + τ R_k)`) and volatility vector `v_k` (its decayed
volatility spread over independent shocks), so `⟨v_j, v_k⟩ = ρ_{jk} σ_j g_j σ_k g_k` is the
covariance of rates `j` and `k`. Give every rate the terminal-bond drift
`μ_k = - ∑_{l = k+1}^{M} a_l ⟨v_k, v_l⟩`. The `T_j` bond counted in `T_M` bonds is
`D_j = ∏_{k = j+1}^{M} (1 + τ R_k)`; by Itô's lemma its log has drift
`∑_{k > j} (a_k μ_k - ½ a_k² |v_k|²)` and shock loading `θ_j = ∑_{k > j} a_k v_k`. Then
(1) that drift is exactly `-½ |θ_j|²`, so `D_j` has no drift: it is a fair bet in the terminal unit;
(2) `μ_j = -⟨v_j, θ_j⟩`, so the Girsanov shift by `θ_j` leaves rate `j` driftless in its own
payment bond's unit. -/
theorem terminal_drift_makes_bond_ratio_fair_bet
    {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (M j : ℕ) (a μ : ℕ → ℝ) (v : ℕ → E)
    (hμ : ∀ k, μ k = -∑ l ∈ Ioc k M, a l * inner ℝ (v k) (v l)) :
    (∑ k ∈ Ioc j M, (a k * μ k - (1 / 2) * a k ^ 2 * ‖v k‖ ^ 2))
        = -(1 / 2) * ‖∑ k ∈ Ioc j M, a k • v k‖ ^ 2
      ∧ μ j = -inner ℝ (v j) (∑ k ∈ Ioc j M, a k • v k) := by
  have h2 : ∀ i, μ i = -inner ℝ (v i) (∑ k ∈ Ioc i M, a k • v k) := by
    intro i
    rw [hμ i, inner_sum]
    simp only [inner_smul_right]
  refine ⟨?_, h2 j⟩
  have key : ∀ d i, i + d = M →
      (∑ k ∈ Ioc i M, (a k * μ k - (1 / 2) * a k ^ 2 * ‖v k‖ ^ 2))
        = -(1 / 2) * ‖∑ k ∈ Ioc i M, a k • v k‖ ^ 2 := by
    intro d
    induction d with
    | zero => intro i hi; subst hi; simp
    | succ d ih =>
      intro i hi
      have hsplit : ∀ f : ℕ → ℝ, ∑ k ∈ Ioc i M, f k = f (i + 1) + ∑ k ∈ Ioc (i + 1) M, f k := by
        intro f
        rw [← Finset.sum_Ioc_consecutive f (Nat.le_succ i) (by omega : i + 1 ≤ M),
          Nat.Ioc_succ_singleton, Finset.sum_singleton]
      have hsplitv : ∑ k ∈ Ioc i M, a k • v k
          = a (i + 1) • v (i + 1) + ∑ k ∈ Ioc (i + 1) M, a k • v k := by
        rw [← Finset.sum_Ioc_consecutive _ (Nat.le_succ i) (by omega : i + 1 ≤ M),
          Nat.Ioc_succ_singleton, Finset.sum_singleton]
      rw [hsplit, ih (i + 1) (by omega), hsplitv, h2 (i + 1),
        @norm_add_sq_real E _ _, norm_smul, inner_smul_left, mul_pow, Real.norm_eq_abs, sq_abs]
      simp only [conj_trivial]
      ring
  by_cases hjM : j ≤ M
  · exact key (M - j) j (by omega)
  · have : Ioc j M = ∅ := Finset.Ioc_eq_empty (by omega)
    simp [this]

/-- **The spot drift keeps the rate accruing now.** At a time inside period `n`, the bank account
counted in `T_M` bonds is `B(T_{n-1}) ∏_{k = n}^{M} (1 + τ R_k)`, so moving from the terminal unit
to the bank-account unit adds `∑_{k = n}^{M} a_k ⟨v_j, v_k⟩` to the terminal drift of rate `j`.
For `1 ≤ n ≤ j ≤ M` the result is `μ_j^B = ∑_{k = n}^{j} a_k ⟨v_j, v_k⟩`: the terms with `k > j`
cancel and the accruing rate `k = n` stays in. If every finished period has zero volatility
(`v_k = 0` for `k < n`), the sum may start at `k = 1`, as in the card's formula. -/
theorem spot_drift_keeps_accruing_rate
    {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (M n j : ℕ) (hn : 1 ≤ n) (hnj : n ≤ j) (hj : j ≤ M) (a : ℕ → ℝ) (v : ℕ → E) :
    (-∑ k ∈ Ioc j M, a k * inner ℝ (v j) (v k)) + ∑ k ∈ Icc n M, a k * inner ℝ (v j) (v k)
        = ∑ k ∈ Icc n j, a k * inner ℝ (v j) (v k)
      ∧ ((∀ k < n, v k = 0) →
        (-∑ k ∈ Ioc j M, a k * inner ℝ (v j) (v k)) + ∑ k ∈ Icc n M, a k * inner ℝ (v j) (v k)
          = ∑ k ∈ Icc 1 j, a k * inner ℝ (v j) (v k)) := by
  have hIcc : ∀ m, 1 ≤ m → ∀ f : ℕ → ℝ, ∑ k ∈ Icc m j, f k = ∑ k ∈ Ioc (m - 1) j, f k := by
    intro m hm f
    congr 1
    ext k
    simp only [Finset.mem_Icc, Finset.mem_Ioc]
    omega
  have hIccM : ∀ f : ℕ → ℝ, ∑ k ∈ Icc n M, f k = ∑ k ∈ Ioc (n - 1) M, f k := by
    intro f
    congr 1
    ext k
    simp only [Finset.mem_Icc, Finset.mem_Ioc]
    omega
  have h1 : (-∑ k ∈ Ioc j M, a k * inner ℝ (v j) (v k)) + ∑ k ∈ Icc n M, a k * inner ℝ (v j) (v k)
        = ∑ k ∈ Icc n j, a k * inner ℝ (v j) (v k) := by
    rw [hIccM, hIcc n hn, ← Finset.sum_Ioc_consecutive _ (by omega : n - 1 ≤ j) hj]
    ring
  refine ⟨h1, fun hv => ?_⟩
  rw [h1, hIcc n hn, hIcc 1 le_rfl,
    ← Finset.sum_Ioc_consecutive _ (by omega : 1 - 1 ≤ n - 1) (by omega : n - 1 ≤ j)]
  have : ∑ k ∈ Ioc (1 - 1) (n - 1), a k * inner ℝ (v j) (v k) = 0 := by
    apply Finset.sum_eq_zero
    intro k hk
    simp only [Finset.mem_Ioc] at hk
    rw [hv k (by omega), inner_zero_right, mul_zero]
  rw [this, zero_add]

/-- **Extended bonds telescope, inside a period too.** Take the bond prices `P_0, …, P_M` at one
time `t` (`P_k` pays at `T_k`; a matured bond is extended, its $1 rolled overnight), all positive,
and define each compounded forward by `1 + τ R_k = P_{k-1} / P_k` for `k = 1, …, M`. Then
(1) for `i ≤ j ≤ M`, `P_i / P_j = ∏_{k = i+1}^{j} (1 + τ R_k)`; and
(2) at a time inside period `n`, where the bank account is its known value `B(T_{n-1})` times the
extended bond `P_{n-1}`, the bank account counted in the `T_j` bond, for `1 ≤ n ≤ j ≤ M`, is
`B(T_{n-1}) ∏_{k = n}^{j} (1 + τ R_k)`: the rate accruing now, `k = n`, is in the product. -/
theorem extended_bond_ratios_telescope (M : ℕ) (τ : ℝ) (R P : ℕ → ℝ)
    (hP : ∀ k ≤ M, 0 < P k)
    (hbond : ∀ k, 1 ≤ k → k ≤ M → 1 + τ * R k = P (k - 1) / P k) :
    (∀ i j, i ≤ j → j ≤ M → P i / P j = ∏ k ∈ Ioc i j, (1 + τ * R k))
      ∧ (∀ (n j : ℕ) (Bn B : ℝ), 1 ≤ n → n ≤ j → j ≤ M → B = Bn * P (n - 1) →
          B / P j = Bn * ∏ k ∈ Icc n j, (1 + τ * R k)) := by
  have h1 : ∀ i j, i ≤ j → j ≤ M → P i / P j = ∏ k ∈ Ioc i j, (1 + τ * R k) := by
    intro i j hij hjM
    induction j, hij using Nat.le_induction with
    | base => simp [(hP i hjM).ne']
    | succ m him ih =>
      rw [Finset.prod_Ioc_succ_top him, ← ih (by omega), hbond (m + 1) (by omega) hjM,
        Nat.add_sub_cancel]
      have h1 := (hP m (by omega)).ne'
      have h2 := (hP (m + 1) hjM).ne'
      field_simp
  refine ⟨h1, ?_⟩
  intro n j Bn B hn hnj hjM hB
  have hI : Icc n j = Ioc (n - 1) j := by
    ext k
    simp only [Finset.mem_Icc, Finset.mem_Ioc]
    omega
  rw [hB, hI, ← h1 (n - 1) j (by omega) hjM, mul_div_assoc]

/- The card's numbers, as exact fractions. -/

-- No-arbitrage target in the terminal unit: 1 / P(0,2) = (1 + R_1)(1 + R_2) = 1.0868 exactly.
example : (1 + 4 / 100 : ℚ) * (1 + 45 / 1000) = 10868 / 10000 := by norm_num

-- Variance times by the one-third rule T_{j-1} + τ/3 with τ = 1: 1/3 and 4/3.
example : (0 + 1 / 3 : ℚ) = 1 / 3 ∧ (1 + 1 / 3 : ℚ) = 4 / 3 := by norm_num

-- μ_1^{T_2}(0) = -0.01 × 0.9 × 0.009 / 1.045 × 10,000 rounds to -0.7751 bp a year.
example : |-(1 / 100 : ℚ) * (9 / 10) * (9 / 1000) / (1045 / 1000) * 10000 - (-7751 / 10000)|
    < 1 / 20000 := by
  rw [abs_lt]; constructor <;> norm_num

-- The accruing rate's term in μ_2^B(0), 0.9 × 0.009 × 0.01 / 1.04 × 10,000, rounds to 0.7788.
example : |(9 / 10 : ℚ) * (9 / 1000) * (1 / 100) / (104 / 100) * 10000 - 7788 / 10000|
    < 1 / 20000 := by
  rw [abs_lt]; constructor <;> norm_num

-- μ_2^B(0): that term plus 0.009² / 1.045 × 10,000 rounds to 1.5540 bp a year.
example : |((9 / 10 : ℚ) * (9 / 1000) * (1 / 100) / (104 / 100) + (9 / 1000) ^ 2 / (1045 / 1000))
    * 10000 - 15540 / 10000| < 1 / 20000 := by
  rw [abs_lt]; constructor <;> norm_num

#print axioms terminal_drift_makes_bond_ratio_fair_bet
#print axioms spot_drift_keeps_accruing_rate
#print axioms extended_bond_ratios_telescope
