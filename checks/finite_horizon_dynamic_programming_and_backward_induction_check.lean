-- Backward induction: in a finite-horizon problem where each choice comes before the chance outcome, the table solved from the last stage back is the best average any rule can earn, even one that remembers the whole past, and the table's own rule earns it.
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.Finset.Lattice.Fold
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Data.Finset.Max
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Tactic.GCongr

open Finset

/-- A finite-horizon decision problem with chance, as on the card.
Stages (months) are `k = 0, …, N - 1`; stage `N` is the end (31 December).
At stage `k` and state `x` the controller picks an allowed action `u` (a finite, nonempty set),
earns `reward k x u`, and then a chance outcome `w` (the rain) arrives with probability `P k w`,
which depends on the stage only, not on the past; the next state is `next k x u w`.
A state still held at the end is worth `endValue x`. -/
structure DecisionProblem (S A W : Type*) [Fintype W] where
  N : ℕ
  allowed : ℕ → S → Finset A
  allowed_nonempty : ∀ k x, (allowed k x).Nonempty
  P : ℕ → W → ℝ
  P_nonneg : ∀ k w, 0 ≤ P k w
  P_sum : ∀ k, ∑ w, P k w = 1
  reward : ℕ → S → A → ℝ
  next : ℕ → S → A → W → S
  endValue : S → ℝ

namespace DecisionProblem

variable {S A W : Type*} [Fintype W] (D : DecisionProblem S A W)

/-- The table `V_k(x)`, filled by backward induction:
`V_N(x) = endValue x` and `V_k(x) = max_u (reward + Σ_w P_k(w) V_{k+1}(next))`.
The maximum sits outside the average: the action is chosen before the chance outcome. -/
noncomputable def V (k : ℕ) (x : S) : ℝ :=
  if D.N ≤ k then D.endValue x
  else (D.allowed k x).sup' (D.allowed_nonempty k x)
    fun u => D.reward k x u + ∑ w, D.P k w * V (k + 1) (D.next k x u w)
termination_by D.N - k

/-- The quantity maximised at stage `k`: this stage's reward for `u` plus the average of
next stage's table value. -/
noncomputable def Q (k : ℕ) (x : S) (u : A) : ℝ :=
  D.reward k x u + ∑ w, D.P k w * D.V (k + 1) (D.next k x u w)

/-- The average earnings from stage `k` to the end under a rule `π` that may use the whole
history `h` (every past state, action and outcome) and the current state `x`, but not the
current stage's outcome, which has not happened yet. -/
noncomputable def J (π : ℕ → List (S × A × W) → S → A) (k : ℕ) (h : List (S × A × W)) (x : S) : ℝ :=
  if D.N ≤ k then D.endValue x
  else D.reward k x (π k h x) +
    ∑ w, D.P k w * J π (k + 1) (h ++ [(x, π k h x, w)]) (D.next k x (π k h x) w)
termination_by D.N - k

/-- The wrong table from the card's "What breaks": choose each action after seeing the stage's
outcome, so the maximum moves inside the average. -/
noncomputable def Vpeek (k : ℕ) (x : S) : ℝ :=
  if D.N ≤ k then D.endValue x
  else ∑ w, D.P k w * (D.allowed k x).sup' (D.allowed_nonempty k x)
    fun u => D.reward k x u + Vpeek (k + 1) (D.next k x u w)
termination_by D.N - k

end DecisionProblem

variable {S A W : Type*} [Fintype W]

/-- Helper: a rule that wins the maximum of `Q` at every stage and state earns the table value. -/
theorem table_rule_helper {S A W : Type*} [Fintype W] (D : DecisionProblem S A W)
    (μ : ℕ → S → A) (hμ : ∀ k x, μ k x ∈ D.allowed k x)
    (hmax : ∀ k x, ∀ u ∈ D.allowed k x, D.Q k x u ≤ D.Q k x (μ k x)) :
    ∀ k h x, D.J (fun k _ x => μ k x) k h x = D.V k x := by
  have key : ∀ n k, D.N ≤ k + n → ∀ h x, D.J (fun k _ x => μ k x) k h x = D.V k x := by
    intro n
    induction n with
    | zero =>
      intro k hk h x
      have hN : D.N ≤ k := by omega
      simp only [DecisionProblem.J.eq_1, DecisionProblem.V.eq_1, hN, ↓reduceIte]
    | succ n ih =>
      intro k hk h x
      by_cases hN : D.N ≤ k
      · rw [DecisionProblem.J.eq_1, DecisionProblem.V.eq_1]; simp only [hN, ↓reduceIte]
      · rw [DecisionProblem.J.eq_1, DecisionProblem.V.eq_1]; simp only [hN, ↓reduceIte]
        apply le_antisymm
        · refine le_trans (le_of_eq ?_) (Finset.le_sup' (fun u => D.reward k x u +
            ∑ w, D.P k w * D.V (k + 1) (D.next k x u w)) (hμ k x))
          congr 1
          refine Finset.sum_congr rfl fun w _ => ?_
          rw [ih (k + 1) (by omega)]
        · refine Finset.sup'_le _ _ fun u hu => ?_
          have := hmax k x u hu
          simp only [DecisionProblem.Q] at this
          refine this.trans (le_of_eq ?_)
          congr 1
          refine Finset.sum_congr rfl fun w _ => ?_
          rw [ih (k + 1) (by omega)]
  intro k h x
  exact key (D.N - k) k (by omega) h x

#print axioms table_rule_helper

/-- Backward induction gives the best rule. With finitely many stages, states, actions and
outcomes, the action chosen before the outcome, outcomes whose chances do not depend on the
past, rewards that add stage by stage plus an end value, and the average as the target:
no rule, even one that remembers the whole history, averages more than the table `V_k(x)`
from any stage and state; and a rule that looks only at the current stage and state averages
exactly `V_k(x)` from every stage and state. -/
theorem backward_induction_gives_best_rule [Fintype S] (D : DecisionProblem S A W) :
    (∀ π : ℕ → List (S × A × W) → S → A, (∀ k h x, π k h x ∈ D.allowed k x) →
      ∀ k h x, D.J π k h x ≤ D.V k x) ∧
    ∃ μ : ℕ → S → A, (∀ k x, μ k x ∈ D.allowed k x) ∧
      ∀ k h x, D.J (fun k _ x => μ k x) k h x = D.V k x := by
  classical
  have hex : ∀ k x, ∃ u ∈ D.allowed k x, ∀ v ∈ D.allowed k x, D.Q k x v ≤ D.Q k x u :=
    fun k x => Finset.exists_max_image _ _ (D.allowed_nonempty k x)
  refine ⟨?_, fun k x => Classical.choose (hex k x),
    fun k x => (Classical.choose_spec (hex k x)).1, ?_⟩
  · intro π hπ
    have key : ∀ n k, D.N ≤ k + n → ∀ h x, D.J π k h x ≤ D.V k x := by
      intro n
      induction n with
      | zero =>
        intro k hk h x
        have hN : D.N ≤ k := by omega
        simp only [DecisionProblem.J.eq_1, DecisionProblem.V.eq_1, hN, ↓reduceIte, le_refl]
      | succ n ih =>
        intro k hk h x
        by_cases hN : D.N ≤ k
        · rw [DecisionProblem.J.eq_1, DecisionProblem.V.eq_1]; simp only [hN, ↓reduceIte, le_refl]
        · rw [DecisionProblem.J.eq_1, DecisionProblem.V.eq_1]; simp only [hN, ↓reduceIte]
          refine le_trans ?_ (Finset.le_sup' (fun u => D.reward k x u +
            ∑ w, D.P k w * D.V (k + 1) (D.next k x u w)) (hπ k h x))
          gcongr with w _
          · exact D.P_nonneg k w
          · exact ih (k + 1) (by omega) _ _
    intro k h x
    exact key (D.N - k) k (by omega) h x
  · exact table_rule_helper D _ (fun k x => (Classical.choose_spec (hex k x)).1)
      (fun k x => (Classical.choose_spec (hex k x)).2)

/-- The rule read off the table, a release that wins the maximum at every stage and state,
earns exactly the table value from every stage and state, whatever the past. -/
theorem table_rule_earns_table_value (D : DecisionProblem S A W) (μ : ℕ → S → A)
    (hμ : ∀ k x, μ k x ∈ D.allowed k x)
    (hmax : ∀ k x, ∀ u ∈ D.allowed k x, D.Q k x u ≤ D.Q k x (μ k x)) :
    ∀ k h x, D.J (fun k _ x => μ k x) k h x = D.V k x := by
  exact table_rule_helper D μ hμ hmax

/-- Peeking at the rain: choosing each action after seeing the outcome (maximum inside the
average) never gives a smaller number than the true table (maximum outside the average). -/
theorem peeking_at_outcome_never_lowers_value (D : DecisionProblem S A W) : ∀ k x, D.V k x ≤ D.Vpeek k x := by
  have key : ∀ n k, D.N ≤ k + n → ∀ x, D.V k x ≤ D.Vpeek k x := by
    intro n
    induction n with
    | zero =>
      intro k hk x
      have hN : D.N ≤ k := by omega
      simp only [DecisionProblem.Vpeek.eq_1, DecisionProblem.V.eq_1, hN, ↓reduceIte, le_refl]
    | succ n ih =>
      intro k hk x
      by_cases hN : D.N ≤ k
      · rw [DecisionProblem.V.eq_1, DecisionProblem.Vpeek.eq_1]; simp only [hN, ↓reduceIte, le_refl]
      · rw [DecisionProblem.V.eq_1, DecisionProblem.Vpeek.eq_1]; simp only [hN, ↓reduceIte]
        refine Finset.sup'_le _ _ fun u hu => ?_
        have hr : D.reward k x u = ∑ w, D.P k w * D.reward k x u := by
          rw [← Finset.sum_mul, D.P_sum, one_mul]
        rw [hr, ← Finset.sum_add_distrib]
        gcongr with w _
        rw [← mul_add]
        apply mul_le_mul_of_nonneg_left _ (D.P_nonneg k w)
        refine le_trans ?_ (Finset.le_sup' (fun u => D.reward k x u +
            D.Vpeek (k + 1) (D.next k x u w)) hu)
        gcongr
        exact ih (k + 1) (by omega) _
  intro k x
  exact key (D.N - k) k (by omega) x

/-! The card's own whole-number arithmetic: water in blocks of 10 million m³, money in
thousands of pounds, wet-month rain chances 2/10, 5/10, 3/10, 31 December water worth 100 a block. -/

-- December, storage 2: releases 0, 1, 2 give 310, 360, 410, so V₁₁(2) = 410 with release 2.
example : (0 : ℚ) + 100 * (2/10 * 2 + 5/10 * 3 + 3/10 * 4) = 310 := by norm_num
example : (150 : ℚ) + 100 * (2/10 * 1 + 5/10 * 2 + 3/10 * 3) = 360 := by norm_num
example : (300 : ℚ) + 100 * (2/10 * 0 + 5/10 * 1 + 3/10 * 2) = 410 := by norm_num
-- December, storage 4: release 0 spills all the rain (400); release 2 gives 610.
example : (0 : ℚ) + 100 * (2/10 * 4 + 5/10 * 4 + 3/10 * 4) = 400 := by norm_num
example : (300 : ℚ) + 100 * (2/10 * 2 + 5/10 * 3 + 3/10 * 4) = 610 := by norm_num
-- December, storage 0, 1, 3: 110, 260, 510.
example : (0 : ℚ) + 100 * (2/10 * 0 + 5/10 * 1 + 3/10 * 2) = 110 := by norm_num
example : (150 : ℚ) + 100 * (2/10 * 0 + 5/10 * 1 + 3/10 * 2) = 260 := by norm_num
example : (300 : ℚ) + 100 * (2/10 * 1 + 5/10 * 2 + 3/10 * 3) = 510 := by norm_num
-- November, storage 2, price 140: releases 0, 1, 2 give 520, 550, 555, so V₁₀(2) = 555.
example : (0 : ℚ) + 2/10 * 410 + 5/10 * 510 + 3/10 * 610 = 520 := by norm_num
example : (140 : ℚ) + 2/10 * 260 + 5/10 * 410 + 3/10 * 510 = 550 := by norm_num
example : (280 : ℚ) + 2/10 * 110 + 5/10 * 260 + 3/10 * 410 = 555 := by norm_num

-- Rules per month: storage 0..4 allows 1, 2, 3, 3, 3 releases, so 54 rule tables a month,
-- 157464 for October to December, and 614787626176508399616 for the year.
example : 1 * 2 * 3 * 3 * 3 = 54 := by norm_num
example : 54 ^ 3 = 157464 := by norm_num
example : 54 ^ 12 = 614787626176508399616 := by norm_num

/-- The card's rule table: blocks to release at storage 0..4, January to December. -/
def cardRule : List (List ℕ) :=
  [[0,1,2,2,2], [0,1,2,2,2], [0,1,2,2,2], [0,1,2,2,2], [0,0,1,2,2], [0,0,0,1,2],
   [0,0,0,1,2], [0,0,0,0,1], [0,0,0,0,1], [0,0,0,1,2], [0,1,2,2,2], [0,1,2,2,2]]

/-- Prices per block, January to December, thousand pounds. -/
def cardPrice : List ℕ := [150, 140, 120, 100, 90, 80, 85, 90, 100, 115, 140, 150]

/-- Run one year under a rule table, month by month: returns (storage on 31 Dec, income). -/
def runYear : List (List ℕ) → List ℕ → List ℕ → ℕ → ℕ → ℕ × ℕ
  | r :: rs, c :: cs, w :: ws, x, inc =>
      runYear rs cs ws (min (x - r.getD x 0 + w) 4) (inc + c * r.getD x 0)
  | _, _, _, x, inc => (x, inc)

-- The traced year: rain 2 1 0 0 1 0 0 0 1 1 2 2 from 2 blocks ends with 3 blocks and income 1280.
example : runYear cardRule cardPrice [2, 1, 0, 0, 1, 0, 0, 0, 1, 1, 2, 2] 2 0 = (3, 1280) := by
  decide

#print axioms backward_induction_gives_best_rule
#print axioms table_rule_earns_table_value
#print axioms peeking_at_outcome_never_lowers_value
