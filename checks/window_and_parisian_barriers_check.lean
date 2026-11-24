-- Window and Parisian barriers: in any price model, a call knocked out only by touches inside a late window, or only by a run of D daily closes below the barrier, is worth at least the whole-life knock-out and at most the plain call.
import Mathlib.MeasureTheory.Integral.Lebesgue.Basic
import Mathlib.Analysis.SpecialFunctions.Exp

open MeasureTheory Set

/-- The discounted pricing-world average of the call payoff `(S_T - K)^+`, paid only on the
paths in `alive` (the paths the contract does not cancel):
`e^{-rT} E[(S_T - K)^+ 1{alive}]`. The average is a Lebesgue integral of a payoff that is never
negative, so it needs no integrability or measurability assumption. `alive = univ` is the plain
call `C(S,T)`. -/
noncomputable def alivePrice {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    (S : ℝ → Ω → ℝ) (K r T : ℝ) (alive : Set Ω) : ENNReal :=
  ENNReal.ofReal (Real.exp (-(r * T))) *
    ∫⁻ ω, alive.indicator (fun ω => ENNReal.ofReal (max (S T ω - K) 0)) ω ∂P

/-- Helper: a contract that kills fewer paths is worth at least as much. -/
theorem alivePrice_mono_helper {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    (S : ℝ → Ω → ℝ) (K r T : ℝ) {A B : Set Ω} (h : A ⊆ B) :
    alivePrice P S K r T A ≤ alivePrice P S K r T B := by
  unfold alivePrice
  gcongr

#print axioms alivePrice_mono_helper

/-- Window bounds, path by path, in any model. A down-and-out call with barrier `H` that watches
the price only on the window `[t₀, T]` (and so also dies if the price is at or under `H` on the
day the window opens) is worth at least the down-and-out call that watches the whole life
`[0, T]`, and at most the plain call: `DO(S,T) ≤ V_win ≤ C(S,T)`. Here `S t ω` is the share
price at time `t` on path `ω`, a touch is `S t ω ≤ H`, and `t₀ ≥ 0` is the opening date in
years from today. -/
theorem knockout_le_window_le_call
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) (S : ℝ → Ω → ℝ)
    (K H r T t₀ : ℝ) (ht₀ : 0 ≤ t₀) :
    alivePrice P S K r T {ω | ∀ t ∈ Icc 0 T, H < S t ω}
        ≤ alivePrice P S K r T {ω | ∀ t ∈ Icc t₀ T, H < S t ω} ∧
      alivePrice P S K r T {ω | ∀ t ∈ Icc t₀ T, H < S t ω}
        ≤ alivePrice P S K r T univ := by
  refine ⟨alivePrice_mono_helper P S K r T ?_, alivePrice_mono_helper P S K r T (subset_univ _)⟩
  intro ω hω t ht
  exact hω t ⟨le_trans ht₀ ht.1, ht.2⟩

/-- Parisian bounds, path by path, in any model. Take `n` daily closes at dates `c 0, …, c (n-1)`
inside the life `[0, T]`. The daily-checked knock-out dies at the first close below `H`; the
Parisian call dies only after `D ≥ 1` closes in a row below `H` (closes `j, …, j + D - 1`).
Then the whole-life knock-out ≤ the daily-checked knock-out ≤ the Parisian call ≤ the plain call:
`DO(S,T) ≤ V_daily ≤ V_Par ≤ C(S,T)`. -/
theorem knockout_le_daily_le_parisian_le_call
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) (S : ℝ → Ω → ℝ)
    (K H r T : ℝ) (n D : ℕ) (c : ℕ → ℝ) (hc : ∀ i < n, c i ∈ Icc 0 T) (hD : 0 < D) :
    alivePrice P S K r T {ω | ∀ t ∈ Icc 0 T, H < S t ω}
        ≤ alivePrice P S K r T {ω | ∀ i < n, H ≤ S (c i) ω} ∧
      alivePrice P S K r T {ω | ∀ i < n, H ≤ S (c i) ω}
        ≤ alivePrice P S K r T
            {ω | ¬ ∃ j, j + D ≤ n ∧ ∀ i, j ≤ i → i < j + D → S (c i) ω < H} ∧
      alivePrice P S K r T
            {ω | ¬ ∃ j, j + D ≤ n ∧ ∀ i, j ≤ i → i < j + D → S (c i) ω < H}
        ≤ alivePrice P S K r T univ := by
  refine ⟨alivePrice_mono_helper P S K r T ?_, alivePrice_mono_helper P S K r T ?_,
    alivePrice_mono_helper P S K r T (subset_univ _)⟩
  · intro ω hω i hi
    exact le_of_lt (hω (c i) (hc i hi))
  · intro ω hω ⟨j, hj, hall⟩
    have h1 : S (c j) ω < H := hall j le_rfl (by omega)
    have h2 : H ≤ S (c j) ω := hω j (by omega)
    exact absurd h2 (not_le.mpr h1)

/-- A longer wait kills fewer paths: if the Parisian call needs `D'` closes in a row below `H`
instead of `D ≤ D'`, it is worth at least as much. -/
theorem parisian_price_mono_in_wait
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) (S : ℝ → Ω → ℝ)
    (K H r T : ℝ) (n D D' : ℕ) (c : ℕ → ℝ) (hDD' : D ≤ D') :
    alivePrice P S K r T
        {ω | ¬ ∃ j, j + D ≤ n ∧ ∀ i, j ≤ i → i < j + D → S (c i) ω < H}
      ≤ alivePrice P S K r T
        {ω | ¬ ∃ j, j + D' ≤ n ∧ ∀ i, j ≤ i → i < j + D' → S (c i) ω < H} := by
  apply alivePrice_mono_helper
  intro ω hω ⟨j, hj, hall⟩
  exact hω ⟨j, by omega, fun i hi1 hi2 => hall i hi1 (by omega)⟩

-- House market, exact fractions: r = 5/100, q = 2/100, σ = 20/100 give the log drift
-- ν = r - q - σ²/2 = 1/100.
example : (5 : ℚ) / 100 - 2 / 100 - (1 / 2) * (20 / 100) ^ 2 = 1 / 100 := by norm_num
-- Centre of the log price at the opening t₀ = 1/2: ν t₀ = 5/1000.
example : (1 : ℚ) / 100 * (1 / 2) = 5 / 1000 := by norm_num
-- μ = ν/σ² = 1/4.
example : ((1 : ℚ) / 100) / (20 / 100) ^ 2 = 1 / 4 := by norm_num
-- Variance of the log price at the opening: σ² t₀ = 2/100, so the spread is √0.02 = 0.141421….
example : ((20 : ℚ) / 100) ^ 2 * (1 / 2) = 2 / 100 := by norm_num
-- Time left at the opening: τ = T - t₀ = 1/2.
example : (1 : ℚ) - 1 / 2 = 1 / 2 := by norm_num

#print axioms knockout_le_window_le_call
#print axioms knockout_le_daily_le_parisian_le_call
#print axioms parisian_price_mono_in_wait
