-- Q-learning: the Q-learning targets average, at the true values, to the values themselves and, from any other table, to one sweep of value iteration that shrinks the worst error by the discount factor, and the card's step sizes 10/(9 + n) meet the Robbins–Monro conditions.
import Mathlib.Analysis.Normed.Group.Constructions
import Mathlib.Analysis.Normed.Order.Lattice
import Mathlib.Analysis.PSeries
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Data.Finset.Lattice.Fold

open Filter Topology

/-- The Q-learning target after one month: the money `r s a w` earned when the month's random
outcome (the rain) is `w`, plus `γ` times the best table entry at the level `next s a w` where
the month ends. Tables are `(s : S) → A s → ℝ`, one cell per state and allowed action. -/
noncomputable def qTarget {S W : Type*} {A : S → Type*} [∀ s, Fintype (A s)] [∀ s, Nonempty (A s)]
    (r : (s : S) → A s → W → ℝ) (next : (s : S) → A s → W → S) (γ : ℝ)
    (Q : (s : S) → A s → ℝ) (s : S) (a : A s) (w : W) : ℝ :=
  r s a w + γ * Finset.univ.sup' Finset.univ_nonempty (Q (next s a w))

/-- One sweep of value iteration for Q (the Bellman operator): each cell becomes the average of
its Q-learning targets, weighted by the chances `p w` of the outcomes. -/
noncomputable def qBellman {S W : Type*} [Fintype W] {A : S → Type*} [∀ s, Fintype (A s)]
    [∀ s, Nonempty (A s)] (p : W → ℝ) (r : (s : S) → A s → W → ℝ) (next : (s : S) → A s → W → S)
    (γ : ℝ) (Q : (s : S) → A s → ℝ) : (s : S) → A s → ℝ :=
  fun s a => ∑ w, p w * qTarget r next γ Q s a w

/-- Helper: the largest entries of two finite tables differ by at most the largest gap. -/
theorem sup'_sub_sup'_abs_le {ι : Type*} [Fintype ι] [Nonempty ι] (f g : ι → ℝ) :
    |Finset.univ.sup' Finset.univ_nonempty f - Finset.univ.sup' Finset.univ_nonempty g|
      ≤ ‖f - g‖ := by
  rw [abs_sub_le_iff]
  constructor
  · rw [sub_le_iff_le_add]
    apply Finset.sup'_le
    intro i _
    have h1 := norm_le_pi_norm (f - g) i
    rw [Pi.sub_apply, Real.norm_eq_abs] at h1
    have h2 := Finset.le_sup' g (Finset.mem_univ i)
    linarith [le_abs_self (f i - g i)]
  · rw [sub_le_iff_le_add]
    apply Finset.sup'_le
    intro i _
    have h1 := norm_le_pi_norm (f - g) i
    rw [Pi.sub_apply, Real.norm_eq_abs] at h1
    have h2 := Finset.le_sup' f (Finset.mem_univ i)
    linarith [neg_abs_le (f i - g i)]

#print axioms sup'_sub_sup'_abs_le

/-- The card's main claim: with finitely many states, a nonempty finite set of allowed actions in
each state, finitely many outcomes with chances that are non-negative and add up to 1, and a
discount `0 ≤ γ < 1`, let `Q*` be the true values (they satisfy the Bellman equation
`Q* = T Q*`). Then for any table `Q`, the targets built from `Q` average to one sweep `T Q`,
which is at most `γ` times as far from `Q*` in the worst cell: `‖T Q - Q*‖∞ ≤ γ ‖Q - Q*‖∞`.
(Mathlib's norm on tables over finite types is the sup norm, the largest gap over cells.) -/
theorem q_learning_target_shrinks_worst_error {S W : Type*} [Fintype S] [Fintype W]
    {A : S → Type*} [∀ s, Fintype (A s)] [∀ s, Nonempty (A s)]
    (p : W → ℝ) (r : (s : S) → A s → W → ℝ) (next : (s : S) → A s → W → S) (γ : ℝ)
    (hp_nonneg : ∀ w, 0 ≤ p w) (hp_sum : ∑ w, p w = 1) (hγ0 : 0 ≤ γ) (hγ1 : γ < 1)
    (Qstar : (s : S) → A s → ℝ) (hstar : qBellman p r next γ Qstar = Qstar)
    (Q : (s : S) → A s → ℝ) :
    ‖qBellman p r next γ Q - Qstar‖ ≤ γ * ‖Q - Qstar‖ := by
  have hr : 0 ≤ γ * ‖Q - Qstar‖ := mul_nonneg hγ0 (norm_nonneg _)
  rw [pi_norm_le_iff_of_nonneg hr]
  intro s
  rw [pi_norm_le_iff_of_nonneg hr]
  intro a
  have h := congrFun (congrFun hstar s) a
  rw [Pi.sub_apply, Pi.sub_apply, Real.norm_eq_abs, ← h]
  simp only [qBellman, qTarget]
  rw [← Finset.sum_sub_distrib]
  calc _ ≤ ∑ w, |p w * (r s a w + γ * Finset.univ.sup' Finset.univ_nonempty (Q (next s a w)))
          - p w * (r s a w + γ * Finset.univ.sup' Finset.univ_nonempty (Qstar (next s a w)))| :=
        Finset.abs_sum_le_sum_abs _ _
    _ ≤ ∑ w, p w * (γ * ‖Q - Qstar‖) := by
        apply Finset.sum_le_sum
        intro w _
        have e : p w * (r s a w + γ * Finset.univ.sup' Finset.univ_nonempty (Q (next s a w)))
            - p w * (r s a w + γ * Finset.univ.sup' Finset.univ_nonempty (Qstar (next s a w)))
            = p w * (γ * (Finset.univ.sup' Finset.univ_nonempty (Q (next s a w))
              - Finset.univ.sup' Finset.univ_nonempty (Qstar (next s a w)))) := by ring
        rw [e, abs_mul, abs_mul, abs_of_nonneg (hp_nonneg w), abs_of_nonneg hγ0]
        have h1 := sup'_sub_sup'_abs_le (Q (next s a w)) (Qstar (next s a w))
        have h2 := norm_le_pi_norm (Q - Qstar) (next s a w)
        rw [Pi.sub_apply] at h2
        exact mul_le_mul_of_nonneg_left (mul_le_mul_of_nonneg_left (h1.trans h2) hγ0)
          (hp_nonneg w)
    _ = γ * ‖Q - Qstar‖ := by rw [← Finset.sum_mul, hp_sum, one_mul]

/-- Step 2 of the card: at the true values `Q*` (a solution of the Bellman equation), the
temporal-difference error `δ = target - Q*(s, a)` averages to zero over the outcomes, in every
cell, so `Q*` is the table where the updates stop pushing on average. -/
theorem td_error_averages_to_zero_at_true_values {S W : Type*} [Fintype W]
    {A : S → Type*} [∀ s, Fintype (A s)] [∀ s, Nonempty (A s)]
    (p : W → ℝ) (r : (s : S) → A s → W → ℝ) (next : (s : S) → A s → W → S) (γ : ℝ)
    (hp_nonneg : ∀ w, 0 ≤ p w) (hp_sum : ∑ w, p w = 1)
    (Qstar : (s : S) → A s → ℝ) (hstar : qBellman p r next γ Qstar = Qstar) :
    ∀ s a, ∑ w, p w * (qTarget r next γ Qstar s a w - Qstar s a) = 0 := by
  intro s a
  have h := congrFun (congrFun hstar s) a
  simp only [qBellman] at h
  simp only [mul_sub, Finset.sum_sub_distrib, ← Finset.sum_mul, hp_sum, one_mul, h, sub_self]

/-- Step 4 of the card: the step sizes `α_n = 10/(9 + n)`, `n = 1, 2, 3, …`, meet the
Robbins–Monro conditions: their sum grows without limit, while the sum of their squares is
finite. -/
theorem card_step_sizes_meet_robbins_monro :
    Tendsto (fun N : ℕ => ∑ n ∈ Finset.range N, (10 : ℝ) / (9 + ((n : ℝ) + 1))) atTop atTop ∧
    Summable (fun n : ℕ => ((10 : ℝ) / (9 + ((n : ℝ) + 1))) ^ 2) := by
  constructor
  · refine tendsto_atTop_mono (fun N => ?_) Real.tendsto_sum_range_one_div_nat_succ_atTop
    apply Finset.sum_le_sum
    intro n _
    have hn : (0 : ℝ) ≤ n := Nat.cast_nonneg n
    rw [div_le_div_iff₀ (by positivity) (by positivity)]
    nlinarith
  · have hs : Summable (fun n : ℕ => 100 * (1 / ((n : ℝ) + 1) ^ 2)) := by
      have := (summable_nat_add_iff 1).mpr (Real.summable_one_div_nat_pow.mpr one_lt_two)
      push_cast at this
      exact this.mul_left 100
    refine Summable.of_nonneg_of_le (fun n => by positivity) (fun n => ?_) hs
    have hn : (0 : ℝ) ≤ n := Nat.cast_nonneg n
    rw [div_pow, mul_one_div, div_le_div_iff₀ (by positivity) (by positivity)]
    nlinarith

/-- The card's reservoir month, in units of 10 million m³ and thousands of pounds: from level `s`,
release `a`, rain `w`; earn 0, 80 or 120 for the release, pay 100 per unit spilled above 4, and
pay 120 if the month ends empty. Returns the money and the new level `min (s - a + w) 4`. -/
def reservoirMonth (s a w : ℤ) : ℤ × ℤ :=
  let x := s - a + w
  let s' := min x 4
  ((if a = 0 then 0 else if a = 1 then 80 else 120) - 100 * max (x - 4) 0
    - (if s' = 0 then 120 else 0), s')

-- The first five months of the learning run: (money, new level) for each (level, release, rain).
example : reservoirMonth 2 0 2 = (0, 4) := by decide
example : reservoirMonth 4 0 1 = (-100, 4) := by decide
example : reservoirMonth 4 1 2 = (-20, 4) := by decide
example : reservoirMonth 4 2 1 = (120, 3) := by decide
example : reservoirMonth 3 0 0 = (0, 3) := by decide
-- Month 2's update: first visit, so α = 10/(9 + 1) = 1, and the target is -100 + 0.9 × 0 = -100.
example : (10 : ℚ) / (9 + 1) = 1 := by norm_num
example : (0 : ℚ) + 10 / (9 + 1) * ((-100 + 9/10 * 0) - 0) = -100 := by norm_num
-- The second visit to a cell uses α = 10/11 (printed as 0.909).
example : (10 : ℚ) / (9 + 2) = 10 / 11 := by norm_num
-- The rain's chances 30%, 40%, 30% add up to 1.
example : (3 : ℚ) / 10 + 4 / 10 + 3 / 10 = 1 := by norm_num
-- Levels 0 to 4 allow 1, 2, 3, 3, 3 releases: 12 table cells and 1 × 2 × 3 × 3 × 3 = 54 rules.
example : ∑ s ∈ Finset.range 5, (min s 2 + 1) = 12 := by decide
example : ∏ s ∈ Finset.range 5, (min s 2 + 1) = 54 := by decide
-- The twelve cells' visit counts add up to the 20,000 simulated months.
example : 202 + 3459 + 228 + 273 + 6617 + 257 + 242 + 4854 + 1411 + 77 + 90 + 2290 = 20000 := by
  norm_num

#print axioms q_learning_target_shrinks_worst_error
#print axioms td_error_averages_to_zero_at_true_values
#print axioms card_step_sizes_meet_robbins_monro
