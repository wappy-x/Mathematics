-- Limits: the largest book inside every cap is the smallest cap-over-usage ratio, a no-edge coin-toss book needs n(n+1) days on average to reach a stop n steps below its high, and a patience of m days caps daily VaR at z L / √m.
import Mathlib.Data.Finset.Lattice.Fold
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Tactic.NormNum

/-- First-to-bind rule. Gauge `j` reads `q * a j` for a book of `q` identical units
(every gauge scales with size) and has cap `b j`; each unit adds a positive reading
`a j`. Then the largest book inside every cap is the smallest ratio `b j / a j`. -/
theorem largest_book_is_min_cap_over_usage {ι : Type*} [Fintype ι] [Nonempty ι]
    (a b : ι → ℝ) (ha : ∀ j, 0 < a j) :
    IsGreatest {q : ℝ | ∀ j, q * a j ≤ b j}
      (Finset.univ.inf' Finset.univ_nonempty (fun j => b j / a j)) := by
  refine ⟨fun j => ?_, fun q hq => ?_⟩
  · have h := Finset.inf'_le (fun j => b j / a j) (Finset.mem_univ j)
    exact (le_div_iff₀ (ha j)).1 h
  · exact Finset.le_inf' _ _ (fun j _ => (le_div_iff₀ (ha j)).2 (hq j))

/-- Coin-toss drawdown. Each day the book wins or loses one step with even odds, and the
stop is `n ≥ 1` steps below the high. Let `E k` be the average number of days to reach the
stop from drawdown `k`. The first-step equations (`E n = 0`; from 0 a win stays at 0 and a
loss goes to 1; from `k` between 1 and `n - 1` the drawdown moves one step down or up) hold
exactly when `E k = n(n+1) - k² - k` for every `k ≤ n`; in particular `E 0 = n(n+1)`. -/
theorem coin_drawdown_days_to_stop (n : ℕ) (hn : 1 ≤ n) (E : ℕ → ℝ) :
    (E n = 0 ∧ E 0 = 1 + E 0 / 2 + E 1 / 2 ∧
      ∀ k, 1 ≤ k → k + 1 ≤ n → E k = 1 + E (k - 1) / 2 + E (k + 1) / 2) ↔
    ∀ k ≤ n, E k = (n : ℝ) * (n + 1) - (k : ℝ) ^ 2 - k := by
  constructor
  · rintro ⟨hEn, hE0, hrec⟩
    have pair : ∀ k, k + 1 ≤ n →
        E k = E 0 - (k : ℝ) ^ 2 - k ∧ E (k + 1) = E 0 - ((k + 1 : ℕ) : ℝ) ^ 2 - ((k + 1 : ℕ) : ℝ) := by
      intro k
      induction k with
      | zero =>
        intro _
        refine ⟨by simp, ?_⟩
        push_cast
        linarith
      | succ j ih =>
        intro hj
        obtain ⟨h1, h2⟩ := ih (by omega)
        refine ⟨h2, ?_⟩
        have h3 := hrec (j + 1) (by omega) (by omega)
        simp only [Nat.add_sub_cancel] at h3
        push_cast at h1 h2 h3 ⊢
        linarith
    have hgen : ∀ k ≤ n, E k = E 0 - (k : ℝ) ^ 2 - k := by
      intro k hk
      rcases Nat.lt_or_ge k n with h | h
      · exact (pair k (by omega)).1
      · have hkn : k = n := by omega
        subst hkn
        obtain ⟨j, rfl⟩ : ∃ j, k = j + 1 := ⟨k - 1, by omega⟩
        exact (pair j (by omega)).2
    have h0 : E 0 = (n : ℝ) * (n + 1) := by
      have := hgen n le_rfl
      rw [hEn] at this
      linarith
    intro k hk
    rw [hgen k hk, h0]
  · intro h
    refine ⟨?_, ?_, ?_⟩
    · rw [h n le_rfl]; ring
    · rw [h 0 (Nat.zero_le _), h 1 hn]; push_cast; ring
    · intro k hk1 hk2
      obtain ⟨j, rfl⟩ : ∃ j, k = j + 1 := ⟨k - 1, by omega⟩
      rw [h (j + 1) (by omega), Nat.add_sub_cancel, h j (by omega), h (j + 1 + 1) hk2]
      push_cast
      ring

/-- From the square law to a VaR cap. With stop `L`, daily standard deviation `σ`,
patience `m` days and bell-curve point `z` (all positive), the stop is at least `m` days
away on average, `(L / σ)² ≥ m`, exactly when one-day VaR `z σ` is at most `z L / √m`. -/
theorem var_cap_from_patience (L σ m z : ℝ) (hL : 0 < L) (hσ : 0 < σ) (hm : 0 < m)
    (hz : 0 < z) :
    m ≤ (L / σ) ^ 2 ↔ z * σ ≤ z * L / Real.sqrt m := by
  have hs : 0 < Real.sqrt m := Real.sqrt_pos.2 hm
  rw [mul_div_assoc, mul_le_mul_iff_of_pos_left hz, le_div_iff₀ hs, ← le_div_iff₀' hσ,
    Real.sqrt_le_iff]
  constructor
  · intro h; exact ⟨div_nonneg hL.le hσ.le, h⟩
  · intro h; exact h.2

-- The card's whole-number worked examples.
-- The stop: 3% of $50,000,000.
example : 3 * 50000000 / 100 = 1500000 := by norm_num
-- Delta cap: half the stop over a 20% fall; vega cap: half the stop over 15 vol points.
example : 1500000 / 2 / 20 = 37500 := by norm_num
example : 1500000 / 2 / 15 = 50000 := by norm_num
-- Notional cap: 40% of capital.
example : 40 * 50000000 / 100 = 20000000 := by norm_num
-- Stop left after a $300,000 drawdown, and that drawdown as a share of the stop (20%).
example : 1500000 - 300000 = 1200000 := by norm_num
example : 300000 * 100 / 1500000 = 20 := by norm_num
-- Drawdown from the high, not the start: up $600,000, then down $1,700,000.
example : (0 + 600000 - 1700000 : ℤ) = -1100000 := by norm_num
example : (max (max 0 600000) (0 + 600000 - 1700000) - (0 + 600000 - 1700000) : ℤ) = 1700000 := by
  norm_num
-- Days to the stop at n = 10: 110 for the coin book, 100 in the Brownian limit.
example : 10 * (10 + 1) = 110 := by norm_num
example : (10 : ℕ) ^ 2 = 100 := by norm_num
-- The chart: coin-toss days n(n+1) and Brownian days n² for n = 2, 4, ..., 12.
example : [2, 4, 6, 8, 10, 12].map (fun n : ℕ => n * (n + 1)) = [6, 20, 42, 72, 110, 156] := by
  decide
example : [2, 4, 6, 8, 10, 12].map (fun n : ℕ => n ^ 2) = [4, 16, 36, 64, 100, 144] := by
  decide

#print axioms largest_book_is_min_cap_over_usage
#print axioms coin_drawdown_days_to_stop
#print axioms var_cap_from_patience
