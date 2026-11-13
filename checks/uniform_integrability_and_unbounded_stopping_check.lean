-- Stopping without a bound: a martingale stopped at a time that is finite with probability one keeps its starting average when its capped values are uniformly integrable, bounded capped values qualify, and so a fair fortune kept between 0 and b that ends at 0 or b reaches b with probability a/b.
import Mathlib.Probability.Martingale.Basic
import Mathlib.Probability.Martingale.OptionalStopping
import Mathlib.Probability.Process.Stopping
import Mathlib.MeasureTheory.Function.UniformIntegrable
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open MeasureTheory
open Filter Topology

/-- Each capped value of a martingale has the starting average. -/
theorem integral_stoppedProcess_eq_integral_zero_aux
    {Ω : Type*} {m0 : MeasurableSpace Ω} {μ : Measure Ω} [IsProbabilityMeasure μ]
    {ℱ : Filtration ℕ m0} {M : ℕ → Ω → ℝ} {τ : Ω → WithTop ℕ}
    (hM : Martingale M ℱ μ) (hτ : IsStoppingTime ℱ τ) (n : ℕ) :
    ∫ ω, stoppedProcess M τ n ω ∂μ = ∫ ω, M 0 ω ∂μ := by
  have h0 : IsStoppingTime ℱ (fun _ : Ω => ((0 : ℕ) : WithTop ℕ)) := isStoppingTime_const ℱ 0
  have hπ : IsStoppingTime ℱ (fun ω => min ((n : ℕ) : WithTop ℕ) (τ ω)) :=
    (isStoppingTime_const ℱ n).min hτ
  have hle : (fun _ : Ω => ((0 : ℕ) : WithTop ℕ)) ≤ fun ω => min ((n : ℕ) : WithTop ℕ) (τ ω) :=
    fun ω => by simp
  have hbdd : ∀ ω, min ((n : ℕ) : WithTop ℕ) (τ ω) ≤ n := fun ω => min_le_left _ _
  have h1 := hM.submartingale.expected_stoppedValue_mono h0 hπ hle hbdd
  have h2 := hM.neg.submartingale.expected_stoppedValue_mono h0 hπ hle hbdd
  simp only [stoppedValue_neg, Pi.neg_apply, integral_neg] at h2
  have e0 : ∀ x, stoppedValue M (fun _ : Ω => ((0 : ℕ) : WithTop ℕ)) x = M 0 x := fun x => rfl
  have e1 : ∀ x, stoppedProcess M τ n x =
      stoppedValue M (fun ω => min ((n : ℕ) : WithTop ℕ) (τ ω)) x := fun x => rfl
  simp only [e0] at h1 h2
  simp only [e1]
  linarith

/-- The capped values converge to the stopped value wherever the stopping time is finite. -/
theorem tendsto_stoppedProcess_aux
    {Ω : Type*} {m0 : MeasurableSpace Ω} {μ : Measure Ω}
    {M : ℕ → Ω → ℝ} {τ : Ω → WithTop ℕ} (hfin : ∀ᵐ ω ∂μ, τ ω ≠ ⊤) :
    ∀ᵐ ω ∂μ, Tendsto (fun n => stoppedProcess M τ n ω) atTop (𝓝 (stoppedValue M τ ω)) := by
  filter_upwards [hfin] with ω hω
  obtain ⟨k, hk⟩ := WithTop.ne_top_iff_exists.mp hω
  apply tendsto_atTop_of_eventually_const (i₀ := k)
  intro n hn
  rw [stoppedProcess_eq_of_ge (by rw [← hk]; exact_mod_cast hn)]
  rfl


/-- **Optional stopping without a ceiling.** Let `M` be a martingale for the filtration `ℱ`
on a probability space, and `τ` a stopping time (values in `ℕ ∪ {∞}`) that is finite with
probability one. If the capped values `M (τ ∧ n)`, `n = 0, 1, 2, ...`, are uniformly
integrable (Mathlib's `UniformIntegrable` with exponent 1: on a probability space this is the
card's condition that the part of `E|M (τ ∧ n)|` above a cutoff `K` tends to 0 as `K` grows,
at every cap `n` at once), then the stopped value `M τ` is integrable and
`E[M τ] = E[M 0]`. -/
theorem optional_stopping_of_uniformIntegrable
    {Ω : Type*} {m0 : MeasurableSpace Ω} {μ : Measure Ω} [IsProbabilityMeasure μ]
    {ℱ : Filtration ℕ m0} {M : ℕ → Ω → ℝ} {τ : Ω → WithTop ℕ}
    (hM : Martingale M ℱ μ) (hτ : IsStoppingTime ℱ τ)
    (hfin : ∀ᵐ ω ∂μ, τ ω ≠ ⊤)
    (hUI : UniformIntegrable (stoppedProcess M τ) 1 μ) :
    Integrable (stoppedValue M τ) μ ∧ ∫ ω, stoppedValue M τ ω ∂μ = ∫ ω, M 0 ω ∂μ := by
  have hconv := tendsto_stoppedProcess_aux (M := M) hfin
  have hint : Integrable (stoppedValue M τ) μ := hUI.integrable_of_ae_tendsto hconv
  refine ⟨hint, ?_⟩
  have hL1 := tendsto_Lp_finite_of_tendsto_ae le_rfl ENNReal.one_ne_top
    (fun n => hUI.aestronglyMeasurable n) (memLp_one_iff_integrable.mpr hint) hUI.1 hconv
  have hlim := tendsto_integral_of_L1' (stoppedValue M τ)
    (Eventually.of_forall fun n => memLp_one_iff_integrable.mp (hUI.memLp n)) hL1
  simp_rw [integral_stoppedProcess_eq_integral_zero_aux hM hτ] at hlim
  exact (tendsto_nhds_unique tendsto_const_nhds hlim).symm

/-- **The bounded test.** If the stopping time is finite with probability one and the capped
values of the martingale never exceed a constant `C` in size, `|M (τ ∧ n)| ≤ C` for every
`n`, then optional stopping holds: `M τ` is integrable and `E[M τ] = E[M 0]`. -/
theorem optional_stopping_of_bounded
    {Ω : Type*} {m0 : MeasurableSpace Ω} {μ : Measure Ω} [IsProbabilityMeasure μ]
    {ℱ : Filtration ℕ m0} {M : ℕ → Ω → ℝ} {τ : Ω → WithTop ℕ}
    (hM : Martingale M ℱ μ) (hτ : IsStoppingTime ℱ τ)
    (hfin : ∀ᵐ ω ∂μ, τ ω ≠ ⊤) (C : ℝ)
    (hbdd : ∀ n, ∀ᵐ ω ∂μ, |stoppedProcess M τ n ω| ≤ C) :
    Integrable (stoppedValue M τ) μ ∧ ∫ ω, stoppedValue M τ ω ∂μ = ∫ ω, M 0 ω ∂μ := by
  have hUI : UniformIntegrable (stoppedProcess M τ) 1 μ := by
    refine uniformIntegrable_of le_rfl ENNReal.one_ne_top (fun n => ?_) (fun ε hε => ?_)
    · exact ((hM.submartingale.stoppedProcess hτ).integrable n).aestronglyMeasurable
    · refine ⟨C.toNNReal + 1, fun n => ?_⟩
      have hz : {x | (C.toNNReal + 1 : NNReal) ≤ ‖stoppedProcess M τ n x‖₊}.indicator
          (stoppedProcess M τ n) =ᵐ[μ] 0 := by
        filter_upwards [hbdd n] with ω hω
        apply Set.indicator_of_notMem
        simp only [Set.mem_ofPred_eq, not_le]
        rw [← NNReal.coe_lt_coe, coe_nnnorm, Real.norm_eq_abs]
        push_cast
        have := Real.le_coe_toNNReal C
        linarith
      rw [eLpNorm_congr_ae hz, eLpNorm_zero]
      exact bot_le
  exact optional_stopping_of_uniformIntegrable hM hτ hfin hUI

/-- **The ruin odds in one line.** A fair game (a martingale `X`) starts at the fortune
`a` and stops at a time `τ` that is finite with probability one. Up to that time the fortune
stays between `0` and the goal `b`, where `0 < a < b`, and when the game stops the fortune is
`0` or `b`. Then the chance of reaching the goal is `a / b`. -/
theorem prob_reach_goal_eq_start_div_goal
    {Ω : Type*} {m0 : MeasurableSpace Ω} {μ : Measure Ω} [IsProbabilityMeasure μ]
    {ℱ : Filtration ℕ m0} {X : ℕ → Ω → ℝ} {τ : Ω → WithTop ℕ}
    (hX : Martingale X ℱ μ) (hτ : IsStoppingTime ℱ τ)
    (hfin : ∀ᵐ ω ∂μ, τ ω ≠ ⊤) {a b : ℝ} (ha : 0 < a) (hab : a < b)
    (hX0 : ∀ ω, X 0 ω = a)
    (hbdd : ∀ n ω, 0 ≤ stoppedProcess X τ n ω ∧ stoppedProcess X τ n ω ≤ b)
    (hend : ∀ᵐ ω ∂μ, stoppedValue X τ ω = 0 ∨ stoppedValue X τ ω = b) :
    μ.real {ω | stoppedValue X τ ω = b} = a / b := by
  have hb : ∀ n, ∀ᵐ ω ∂μ, |stoppedProcess X τ n ω| ≤ b := fun n =>
    Eventually.of_forall fun ω => by
      rw [abs_le]; constructor <;> linarith [(hbdd n ω).1, (hbdd n ω).2]
  obtain ⟨hint, heq⟩ := optional_stopping_of_bounded hX hτ hfin b hb
  have h0 : ∫ ω, X 0 ω ∂μ = a := by simp [hX0]
  have hS : NullMeasurableSet {ω | stoppedValue X τ ω = b} μ :=
    hint.aestronglyMeasurable.aemeasurable.nullMeasurableSet_preimage (measurableSet_singleton b)
  have hae : stoppedValue X τ =ᵐ[μ] {ω | stoppedValue X τ ω = b}.indicator (fun _ => b) := by
    filter_upwards [hend] with ω hω
    rcases hω with h | h
    · have hn : ω ∉ {ω | stoppedValue X τ ω = b} := by
        simp only [Set.mem_ofPred_eq, h]; intro h'; linarith
      rw [Set.indicator_of_notMem hn, h]
    · rw [Set.indicator_of_mem (by simpa using h), h]
  rw [integral_congr_ae hae, integral_indicator₀ hS, setIntegral_const, h0, smul_eq_mul] at heq
  have hb0 : b ≠ 0 := by linarith
  rw [eq_div_iff hb0]
  exact heq

/-! ### The card's worked numbers, checked exactly -/

-- Step 3, fair coin from 10 to 30: 30 w + 0 (1 - w) = 10 gives w = 10/30 = 1/3; ruin 2/3.
example : (30 : ℚ) * (10 / 30) + 0 * (1 - 10 / 30) = 10 := by norm_num
example : (10 : ℚ) / 30 = 1 / 3 ∧ 1 - (1 : ℚ) / 3 = 2 / 3 := by norm_num

-- Step 5, the second martingale X^2 - n: from fortune x the next square averages x^2 + 1.
example (x : ℚ) : (1 / 2) * (x + 1) ^ 2 + (1 / 2) * (x - 1) ^ 2 = x ^ 2 + 1 := by ring

-- Step 5, average length: 900 * (1/3) - 10^2 = 200 = a (b - a) = 10 * 20.
example : (30 : ℚ) ^ 2 * (1 / 3) - 10 ^ 2 = 200 ∧ (10 : ℚ) * (30 - 10) = 200 := by norm_num

-- Step 4, roulette: p = 18/38, q = 20/38, r = q/p = 20/18; then p r + q / r = 1, so r^X is fair.
example : (18 / 38 : ℚ) * (20 / 18) + (20 / 38) / (20 / 18) = 1 := by norm_num

-- Step 4, roulette chance of 30, w = (r^10 - 1)/(r^30 - 1), lies between 0.082690 and 0.082692.
example :
    (82690 / 1000000 : ℚ) < ((20 / 18 : ℚ) ^ 10 - 1) / ((20 / 18 : ℚ) ^ 30 - 1) ∧
      ((20 / 18 : ℚ) ^ 10 - 1) / ((20 / 18 : ℚ) ^ 30 - 1) < 82692 / 1000000 := by
  norm_num

-- Step 6, doubling: E[G_n] = (1 - 2^-n) + 2^-n (1 - 2^n) = 0, checked at n = 1, 4, 7, 10.
example : (1 - 1 / (2 : ℚ) ^ 1) + 1 / (2 : ℚ) ^ 1 * (1 - 2 ^ 1) = 0 ∧
    (1 - 1 / (2 : ℚ) ^ 4) + 1 / (2 : ℚ) ^ 4 * (1 - 2 ^ 4) = 0 ∧
    (1 - 1 / (2 : ℚ) ^ 7) + 1 / (2 : ℚ) ^ 7 * (1 - 2 ^ 7) = 0 ∧
    (1 - 1 / (2 : ℚ) ^ 10) + 1 / (2 : ℚ) ^ 10 * (1 - 2 ^ 10) = 0 := by norm_num

-- Step 6, doubling tail above K = 100: 2^-n (2^n - 1) = 1 - 2^-n, which is 127/128 at n = 7
-- (0.992188) and 1023/1024 at n = 10 (0.999023); and 2^n - 1 > 100 at both.
example : (1 / (2 : ℚ) ^ 7) * (2 ^ 7 - 1) = 127 / 128 ∧ (2 : ℕ) ^ 7 - 1 > 100 := by norm_num
example : (1 / (2 : ℚ) ^ 10) * (2 ^ 10 - 1) = 1023 / 1024 ∧ (2 : ℕ) ^ 10 - 1 > 100 := by norm_num

-- Step 6, no goal: ruin before goal b has chance 1 - a/b: 9/10 at b = 100, 99/100 at b = 1000.
example : 1 - (10 : ℚ) / 100 = 9 / 10 ∧ 1 - (10 : ℚ) / 1000 = 99 / 100 := by norm_num

#print axioms integral_stoppedProcess_eq_integral_zero_aux
#print axioms tendsto_stoppedProcess_aux
#print axioms optional_stopping_of_uniformIntegrable
#print axioms optional_stopping_of_bounded
#print axioms prob_reach_goal_eq_start_div_goal
