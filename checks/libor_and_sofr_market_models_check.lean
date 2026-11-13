-- Market models: with the terminal-bond drift, each bond exchange rate is a product of later forward factors whose log drift is exactly minus half its squared volatility, so it is a fair bet.
import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Algebra.BigOperators.Intervals

open Finset


/-- The weight `a = δ L / (1 + δ L)` of a forward rate `L` over a period of length `δ`:
how far a 1% relative move in `L` moves `log (1 + δ L)`. -/
noncomputable def marketWeight (δ L : ℝ) : ℝ := δ * L / (1 + δ * L)

/-- The drift of forward rate `i` (as a fraction of its level per year) in the unit of the
terminal bond, for rates numbered `0, …, n-1`:
`μ_i = - ∑_{j = i+1}^{n-1} a_j σ_i · σ_j`. -/
noncomputable def marketTerminalDrift {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (n : ℕ) (δ : ℝ) (L : ℕ → ℝ) (σ : ℕ → E) (i : ℕ) : ℝ :=
  -∑ j ∈ Ioo i n, marketWeight δ (L j) * inner ℝ (σ i) (σ j)

lemma market_Ioo_succ_insert (i n : ℕ) (h : i + 1 < n) :
    Ioo i n = insert (i + 1) (Ioo (i + 1) n) := by
  ext x; simp only [mem_Ioo, mem_insert]; omega

lemma market_Ioo_empty (i n : ℕ) (h : n ≤ i + 1) : Ioo i n = ∅ := by
  ext x; simp only [mem_Ioo, Finset.notMem_empty, iff_false]; omega

lemma market_drift_eq_inner {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (n : ℕ) (δ : ℝ) (L : ℕ → ℝ) (σ : ℕ → E) (i : ℕ) :
    marketTerminalDrift n δ L σ i
      = -inner ℝ (σ i) (∑ j ∈ Ioo i n, marketWeight δ (L j) • σ j) := by
  unfold marketTerminalDrift
  rw [inner_sum]
  simp only [inner_smul_right]

lemma market_drift_sum_aux {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (n : ℕ) (δ : ℝ) (L : ℕ → ℝ) (σ : ℕ → E) :
    ∀ m i : ℕ, n - i = m →
    (∑ j ∈ Ioo i n, (marketWeight δ (L j) * marketTerminalDrift n δ L σ j
        - (1 / 2) * marketWeight δ (L j) ^ 2 * inner ℝ (σ j) (σ j)))
      = -(1 / 2) * ‖∑ j ∈ Ioo i n, marketWeight δ (L j) • σ j‖ ^ 2 := by
  intro m
  induction m with
  | zero =>
    intro i hi
    rw [market_Ioo_empty i n (by omega)]
    simp
  | succ m ih =>
    intro i hi
    by_cases h : i + 1 < n
    · rw [market_Ioo_succ_insert i n h, sum_insert (by simp), sum_insert (by simp),
        ih (i + 1) (by omega), market_drift_eq_inner, norm_add_sq_real, inner_smul_left,
        norm_smul, real_inner_self_eq_norm_sq]
      simp only [Real.norm_eq_abs, conj_trivial]
      rw [mul_pow, sq_abs]
      ring
    · rw [market_Ioo_empty i n (by omega)]
      simp

lemma market_telescope_aux (n : ℕ) (δ : ℝ) (L P : ℕ → ℝ)
    (hP : ∀ j ≤ n, 0 < P j) (hbond : ∀ j < n, 1 + δ * L j = P j / P (j + 1)) :
    ∀ m i : ℕ, i < n → n - i = m → P (i + 1) / P n = ∏ j ∈ Ioo i n, (1 + δ * L j) := by
  intro m
  induction m with
  | zero => intro i hi hm; omega
  | succ m ih =>
    intro i hi hm
    by_cases h : i + 1 < n
    · rw [market_Ioo_succ_insert i n h, prod_insert (by simp), ← ih (i + 1) h (by omega),
        hbond (i + 1) h]
      have h1 := hP (i + 2) (by omega)
      have h2 := hP n le_rfl
      field_simp
    · have : i + 1 = n := by omega
      rw [market_Ioo_empty i n (by omega), prod_empty, this]
      exact div_self (hP n le_rfl).ne'

#print axioms market_Ioo_succ_insert
#print axioms market_Ioo_empty
#print axioms market_drift_eq_inner
#print axioms market_drift_sum_aux
#print axioms market_telescope_aux

/-- **The terminal-measure drift is the right one.** Take forward rates `L_0, …, L_{n-1}`, a
period length `δ`, volatility vectors `σ_j` (one entry per shock), weights
`a_j = δ L_j / (1 + δ L_j)`, and give each rate the terminal-bond drift
`μ_j = - ∑_{k > j} a_k σ_j · σ_k`. Let `θ_i = ∑_{j > i} a_j σ_j` be the volatility of the
exchange rate `D_i = ∏_{j > i} (1 + δ L_j)`. Then
(1) the drift of `log D_i`, which by Itô's lemma is `∑_{j > i} (a_j μ_j - ½ a_j² σ_j · σ_j)`,
equals exactly `-½ |θ_i|²`, so `D_i` is a stochastic exponential (a fair bet); and
(2) `μ_i = - σ_i · θ_i`, so shifting the shock by `θ_i` (Girsanov) leaves rate `i` driftless
in its own payment bond's unit. -/
theorem terminal_drift_makes_exchange_rate_fair_bet
    {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (n i : ℕ) (δ : ℝ) (L : ℕ → ℝ) (σ : ℕ → E) :
    (∑ j ∈ Ioo i n, (marketWeight δ (L j) * marketTerminalDrift n δ L σ j
        - (1 / 2) * marketWeight δ (L j) ^ 2 * inner ℝ (σ j) (σ j)))
      = -(1 / 2) * ‖∑ j ∈ Ioo i n, marketWeight δ (L j) • σ j‖ ^ 2
    ∧ marketTerminalDrift n δ L σ i = -inner ℝ (σ i) (∑ j ∈ Ioo i n, marketWeight δ (L j) • σ j) := by
  exact ⟨market_drift_sum_aux n δ L σ (n - i) i rfl, market_drift_eq_inner n δ L σ i⟩

/-- **The exchange rate telescopes.** If bond prices `P_0, …, P_n` are positive and each forward
rate satisfies the bond identity `1 + δ L_j = P_j / P_{j+1}`, then the `T_{i+1}` bond counted in
terminal bonds is the product of the later forward factors:
`P_{i+1} / P_n = ∏_{j = i+1}^{n-1} (1 + δ L_j)` (an empty product, 1, for the last rate). -/
theorem exchange_rate_telescopes (n i : ℕ) (hi : i < n) (δ : ℝ) (L P : ℕ → ℝ)
    (hP : ∀ j ≤ n, 0 < P j) (hbond : ∀ j < n, 1 + δ * L j = P j / P (j + 1)) :
    P (i + 1) / P n = ∏ j ∈ Ioo i n, (1 + δ * L j) := by
  exact market_telescope_aux n δ L P hP hbond (n - i) i hi rfl

/-- **The weight is the log sensitivity, and lies between 0 and 1.** For a positive rate `L` and
a positive period length `δ`, a relative bump `L ↦ L eˣ` moves `log (1 + δ L)` at rate
`a = δ L / (1 + δ L)` at `x = 0`, and `0 < a < 1`. -/
theorem weight_is_log_sensitivity (δ L : ℝ) (hδ : 0 < δ) (hL : 0 < L) :
    HasDerivAt (fun x : ℝ => Real.log (1 + δ * (L * Real.exp x))) (marketWeight δ L) 0
      ∧ 0 < marketWeight δ L ∧ marketWeight δ L < 1 := by
  have hpos : 0 < 1 + δ * L := by positivity
  refine ⟨?_, ?_, ?_⟩
  · have hd : HasDerivAt (fun x : ℝ => 1 + δ * (L * Real.exp x)) (δ * (L * Real.exp 0)) 0 :=
      (((Real.hasDerivAt_exp 0).const_mul L).const_mul δ).const_add 1
    have := hd.log (by simp; exact hpos.ne')
    convert this using 1
    simp [marketWeight]
  · unfold marketWeight; positivity
  · unfold marketWeight
    rw [div_lt_one hpos]
    linarith

/-! The card's exact hand arithmetic for one step of `L_0` with `σ_0 = (0.20, 0.08)`,
`h = 1/4` and `ΔW = (0.1, -0.2)`. -/

-- shock: 0.20 × 0.1 + 0.08 × (−0.2) = 0.004
example : (20 / 100 : ℚ) * (1 / 10) + (8 / 100) * (-2 / 10) = 4 / 1000 := by norm_num

-- half-variance: ½ × (0.20² + 0.08²) × 0.25 = 0.0058
example : (1 / 2 : ℚ) * ((20 / 100) ^ 2 + (8 / 100) ^ 2) * (1 / 4) = 58 / 10000 := by norm_num

-- the last of ten rates (i = 9) has no later rates, so its sum and product are empty
example : Ioo 9 10 = (∅ : Finset ℕ) := by decide


#print axioms terminal_drift_makes_exchange_rate_fair_bet
#print axioms exchange_rate_telescopes
#print axioms weight_is_log_sensitivity
