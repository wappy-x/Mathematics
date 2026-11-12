-- Yes-or-no variables: a rule g ≤ M·(1 − δ) with a 0-or-1 switch δ is exactly "the rule when δ = 1, no rule when δ = 0" if and only if M is at least every overshoot g a plan can reach; a smaller M never gives a higher fractional best, and every price π ≥ 0 gives a ceiling on that fractional best.
import Mathlib.Basic.Real.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Order.Bounds.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring

open Finset

/-- The fractional version (relaxation) of the festival model with `k` acts, `K` main-stage slots
and big-M value `M`: each act's booking `x i` and the stage-2 switch `y` may be anywhere from 0 to 1,
and the acts past `K` may not exceed `M` times the switch: `∑ x i − K ≤ M · y`. -/
def relaxedPlans (k : ℕ) (K M : ℝ) : Set ((Fin k → ℝ) × ℝ) :=
  {p | (∀ i, 0 ≤ p.1 i ∧ p.1 i ≤ 1) ∧ 0 ≤ p.2 ∧ p.2 ≤ 1 ∧ (∑ i, p.1 i) - K ≤ M * p.2}

/-- A plan's net takings: each act's value `v i` times its booking, minus the fixed charge `F`
times the stage-2 switch. -/
def planValue {k : ℕ} (v : Fin k → ℝ) (F : ℝ) (p : (Fin k → ℝ) × ℝ) : ℝ :=
  (∑ i, v i * p.1 i) - F * p.2

/-- Big-M is exact exactly when M covers the largest overshoot. Let `S` be the plans that obey
every other rule and `g x` how far plan `x` breaks the switched rule. The switched rule
`g x ≤ M · (1 − δ)`, with `δ` equal to 0 or 1, means "the rule `g x ≤ 0` holds when `δ = 1`, and
there is no rule when `δ = 0`" for every plan in `S`, if and only if `M` is at least `g x` for
every plan `x` in `S`. With a smaller `M`, the plan with the largest overshoot is cut off even
with the rule switched off. -/
theorem big_m_switch_exact_iff_m_covers_overshoot {X : Type*} (S : Set X) (g : X → ℝ) (M : ℝ) :
    (∀ x ∈ S, ∀ δ : ℝ, (δ = 0 ∨ δ = 1) → (g x ≤ M * (1 - δ) ↔ (δ = 1 → g x ≤ 0))) ↔
      ∀ x ∈ S, g x ≤ M := by
  constructor
  · intro h x hx
    have := (h x hx 0 (Or.inl rfl)).2 (fun h01 => absurd h01 (by norm_num))
    simpa using this
  · intro h x hx δ hδ
    rcases hδ with rfl | rfl
    · simp only [sub_zero, mul_one]
      exact ⟨fun _ h01 => absurd h01 (by norm_num), fun _ => h x hx⟩
    · simp

/-- The smallest valid M gives the tightest relaxation. If `M' ≤ M`, every fractional plan
allowed with `M'` is allowed with `M`, so the best fractional value with `M'` is at most the best
fractional value with `M`: `z_LP(M') ≤ z_LP(M)`. -/
theorem relaxed_best_le_of_smaller_m {k : ℕ} (v : Fin k → ℝ) (F K M' M : ℝ) (hM : M' ≤ M)
    (z' z : ℝ)
    (hz' : IsGreatest (planValue v F '' relaxedPlans k K M') z')
    (hz : IsGreatest (planValue v F '' relaxedPlans k K M) z) :
    z' ≤ z := by
  obtain ⟨p, hp, rfl⟩ := hz'.1
  apply hz.2
  refine ⟨p, ?_, rfl⟩
  obtain ⟨h1, h2, h3, h4⟩ := hp
  exact ⟨h1, h2, h3, le_trans h4 (mul_le_mul_of_nonneg_right hM h2)⟩

/-- A price on the stage rule proves a ceiling. For every price `π ≥ 0` per act past `K`, every
fractional plan obeying `∑ x i − K ≤ M · y` has net takings at most
`∑ max(0, v i − π) + max(0, π·M − F) + K·π`. -/
theorem relaxed_value_le_price_bound {k : ℕ} (v : Fin k → ℝ) (F K M π : ℝ) (hπ : 0 ≤ π)
    (p : (Fin k → ℝ) × ℝ) (hp : p ∈ relaxedPlans k K M) :
    planValue v F p ≤ (∑ i, max 0 (v i - π)) + max 0 (π * M - F) + K * π := by
  obtain ⟨h1, h2, h3, h4⟩ := hp
  unfold planValue
  have key : ∀ i ∈ (univ : Finset (Fin k)), v i * p.1 i ≤ max 0 (v i - π) + π * p.1 i := by
    intro i _
    obtain ⟨a, b⟩ := h1 i
    have hm1 : (v i - π) * p.1 i ≤ max 0 (v i - π) * p.1 i :=
      mul_le_mul_of_nonneg_right (le_max_right _ _) a
    have hm2 : max 0 (v i - π) * p.1 i ≤ max 0 (v i - π) * 1 :=
      mul_le_mul_of_nonneg_left b (le_max_left _ _)
    nlinarith
  have hs := Finset.sum_le_sum key
  rw [Finset.sum_add_distrib, ← Finset.mul_sum] at hs
  have hy : (π * M - F) * p.2 ≤ max 0 (π * M - F) := by
    rcases le_or_gt (π * M - F) 0 with h | h
    · have : (π * M - F) * p.2 ≤ 0 := mul_nonpos_of_nonpos_of_nonneg h h2
      linarith [le_max_left 0 (π * M - F)]
    · have : (π * M - F) * p.2 ≤ (π * M - F) * 1 := mul_le_mul_of_nonneg_left h3 h.le
      linarith [le_max_right 0 (π * M - F)]
  have hpi : π * (∑ i, p.1 i) ≤ π * (K + M * p.2) := mul_le_mul_of_nonneg_left (by linarith) hπ
  nlinarith

/-! The card's festival: acts A to L, values in £k, 8 main-stage slots, a £40k charge. -/

-- Stage 2 shut, the best 8 acts: £332k.
example : ([62, 55, 48, 41, 37, 33, 30, 26] : List ℤ).sum = 332 := by decide
-- Stage 2 open, all 12 acts, less the £40k charge: £381k − £40k = £341k, £9k better.
example : ([62, 55, 48, 41, 37, 33, 30, 26, 18, 14, 11, 6] : List ℤ).sum = 381 := by decide
example : (381 : ℤ) - 40 = 341 ∧ (341 : ℤ) - 332 = 9 := by decide
-- The smallest valid M: 12 acts − 8 slots = 4; settings listed: 2^12 × 2 = 8,192.
example : (12 : ℤ) - 8 = 4 ∧ 2 ^ 12 * 2 = 8192 := by decide
-- The 12-act plan passes n − 8 ≤ M·y with M = 4 and y = 1, and is cut off with M = 2.
example : (12 : ℤ) - 8 ≤ 4 * 1 ∧ ¬ ((12 : ℤ) - 8 ≤ 2 * 1) := by decide
-- The toll 40 / 4 = 10, and the price bound at M = 4: 8 × 10 + 265 + 0 = 345.
example : ([62, 55, 48, 41, 37, 33, 30, 26, 18, 14, 11, 6].map (fun v : ℤ => max 0 (v - 10))).sum
    = 265 := by decide
example : (8 : ℤ) * 10 + 265 + max 0 (10 * 4 - 40) = 345 := by decide
-- The relaxed plan at M = 4 (acts A to K booked, L out, y = 3/4) is allowed and is worth £345k:
-- 332 + (18 − 10) + (14 − 10) + (11 − 10).
example : ((![1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0], 3 / 4) : (Fin 12 → ℝ) × ℝ)
    ∈ relaxedPlans 12 8 4 := by
  refine ⟨fun i => ?_, by norm_num, by norm_num, ?_⟩
  · fin_cases i <;> norm_num
  · norm_num [Fin.sum_univ_succ]
example : planValue ![62, 55, 48, 41, 37, 33, 30, 26, 18, 14, 11, 6] 40
    ((![1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0], 3 / 4) : (Fin 12 → ℝ) × ℝ) = 345 := by
  norm_num [planValue, Fin.sum_univ_succ]
example : (332 : ℤ) + (18 - 10) + (14 - 10) + (11 - 10) = 345 := by decide

/-! The headliners: start times in quarter hours after 18:00; A plays 6 (90 min), B plays 4
(60 min), the night ends at 20 (23:00). So A starts at 0..14 and B at 0..16. -/

-- 255 start pairs, of which 132 have no clash.
example : ((List.range 15).product (List.range 17)).length = 255 := by decide +kernel
example : (((List.range 15).product (List.range 17)).filter
    (fun p : ℕ × ℕ => p.1 + 6 ≤ p.2 ∨ p.2 + 4 ≤ p.1)).length = 132 := by decide +kernel
-- With M = 20 quarter hours (5 hours) the either-or model keeps exactly those 132 pairs.
example : (((List.range 15).product (List.range 17)).filter (fun p : ℕ × ℕ =>
    ((p.1 : ℤ) + 6 - p.2 ≤ 20 * (1 - 0) ∧ (p.2 : ℤ) + 4 - p.1 ≤ 20 * 0) ∨
    ((p.1 : ℤ) + 6 - p.2 ≤ 20 * (1 - 1) ∧ (p.2 : ℤ) + 4 - p.1 ≤ 20 * 1))).length = 132 := by
  decide +kernel
-- With M = 16 quarter hours (4 hours) it keeps only 112: B at 18:00 with A at 21:30 is lost.
example : (((List.range 15).product (List.range 17)).filter (fun p : ℕ × ℕ =>
    ((p.1 : ℤ) + 6 - p.2 ≤ 16 * (1 - 0) ∧ (p.2 : ℤ) + 4 - p.1 ≤ 16 * 0) ∨
    ((p.1 : ℤ) + 6 - p.2 ≤ 16 * (1 - 1) ∧ (p.2 : ℤ) + 4 - p.1 ≤ 16 * 1))).length = 112 := by
  decide +kernel

#print axioms big_m_switch_exact_iff_m_covers_overshoot
#print axioms relaxed_best_le_of_smaller_m
#print axioms relaxed_value_le_price_bound
