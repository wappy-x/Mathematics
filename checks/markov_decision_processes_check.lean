-- Markov decision processes: a policy whose value satisfies the Bellman optimality equation does at least as well as every other policy from every state.
import Mathlib.Data.Matrix.Mul
import Mathlib.Topology.Algebra.InfiniteSum.Real
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Normed.Group.InfiniteSum
import Mathlib.Analysis.SpecificLimits.Basic

open Finset

/-! A finite Markov decision process: states `S`, actions `A`, transition chances
`p s a s'` (the chance of next state `s'` after action `a` in state `s`), rewards `r s a`
and a discount factor `γ`. A policy is a rule `π : S → A` giving one action per state. -/

variable {S A : Type*} [Fintype S] [DecidableEq S] [Fintype A] [Nonempty A]

/-- The transition matrix of the Markov chain that policy `π` produces:
row `s` holds the chances `p(s' | s, π s)`. -/
def mdpPolicyMatrix (p : S → A → S → ℝ) (π : S → A) : Matrix S S ℝ :=
  fun s s' => p s (π s) s'

/-- The value `V_π(s)` of policy `π`: the expected total of discounted rewards when the process
starts in `s` and follows `π` for ever, `∑ₖ γᵏ (P_πᵏ r_π)(s)`. Month `k`'s expected reward is
`(P_πᵏ r_π)(s)`, because `P_πᵏ` gives the chances of each state after `k` months. -/
noncomputable def mdpPolicyValue (p : S → A → S → ℝ) (r : S → A → ℝ) (γ : ℝ) (π : S → A)
    (s : S) : ℝ :=
  ∑' k : ℕ, γ ^ k * ((mdpPolicyMatrix p π ^ k).mulVec (fun t => r t (π t))) s

/-- The bracket `r(s, a) + γ ∑_{s'} p(s' | s, a) V(s')`: the worth of taking action `a` now
in state `s` and then collecting `V` from wherever the process lands. -/
def mdpBracket (p : S → A → S → ℝ) (r : S → A → ℝ) (γ : ℝ) (V : S → ℝ) (s : S) (a : A) : ℝ :=
  r s a + γ * ∑ s', p s a s' * V s'

/-- `V` satisfies the Bellman optimality equation:
`V(s) = max_a [ r(s, a) + γ ∑_{s'} p(s' | s, a) V(s') ]` for every state `s`. -/
def MdpBellmanOptimal (p : S → A → S → ℝ) (r : S → A → ℝ) (γ : ℝ) (V : S → ℝ) : Prop :=
  ∀ s, V s = univ.sup' univ_nonempty (mdpBracket p r γ V s)

/-- Helper: for a row-stochastic nonnegative `q`, the powers of `q` keep every entry of
`q^k *ᵥ v` within `∑ t, |v t|` in absolute value. -/
theorem mdp_helper_pow_mulVec_bound (q : Matrix S S ℝ) (hq_nonneg : ∀ s t, 0 ≤ q s t)
    (hq_sum : ∀ s, ∑ t, q s t = 1) (v : S → ℝ) (k : ℕ) (s : S) :
    |(q ^ k).mulVec v s| ≤ ∑ t, |v t| := by
  induction k generalizing s with
  | zero =>
    simp only [pow_zero, Matrix.one_mulVec]
    exact Finset.single_le_sum (f := fun t => |v t|) (fun t _ => abs_nonneg _) (Finset.mem_univ s)
  | succ k ih =>
    rw [pow_succ', ← Matrix.mulVec_mulVec]
    simp only [Matrix.mulVec, dotProduct] at ih ⊢
    calc |∑ t, q s t * ∑ u, (q ^ k) t u * v u|
        ≤ ∑ t, |q s t * ∑ u, (q ^ k) t u * v u| := Finset.abs_sum_le_sum_abs _ _
      _ ≤ ∑ t, q s t * ∑ u, |v u| := by
          apply Finset.sum_le_sum
          intro t _
          rw [abs_mul, abs_of_nonneg (hq_nonneg s t)]
          exact mul_le_mul_of_nonneg_left (ih t) (hq_nonneg s t)
      _ = ∑ u, |v u| := by rw [← Finset.sum_mul, hq_sum, one_mul]

omit [Fintype A] [Nonempty A] in
/-- Helper: the series defining a policy value converges from every state. -/
theorem mdp_helper_summable (p : S → A → S → ℝ) (r : S → A → ℝ) (γ : ℝ)
    (hp_nonneg : ∀ s a s', 0 ≤ p s a s') (hp_sum : ∀ s a, ∑ s', p s a s' = 1)
    (hγ0 : 0 ≤ γ) (hγ1 : γ < 1) (π : S → A) (s : S) :
    Summable fun k : ℕ =>
      γ ^ k * ((mdpPolicyMatrix p π ^ k).mulVec (fun t => r t (π t))) s := by
  apply Summable.of_norm_bounded
    ((summable_geometric_of_lt_one hγ0 hγ1).mul_right (∑ t, |r t (π t)|))
  intro k
  rw [Real.norm_eq_abs, abs_mul, abs_of_nonneg (pow_nonneg hγ0 k)]
  exact mul_le_mul_of_nonneg_left
    (mdp_helper_pow_mulVec_bound _ (fun s t => hp_nonneg s (π s) t) (fun s => hp_sum s (π s)) _ k s)
    (pow_nonneg hγ0 k)

omit [DecidableEq S] in
/-- Helper: if `D s ≤ γ ∑ q s s' D s'` for every `s`, with `q` nonnegative rows adding to 1 and
`0 ≤ γ < 1`, then `D ≤ 0` everywhere. -/
theorem mdp_helper_contraction (q : S → S → ℝ) (hq_nonneg : ∀ s t, 0 ≤ q s t)
    (hq_sum : ∀ s, ∑ t, q s t = 1) (γ : ℝ) (hγ0 : 0 ≤ γ) (hγ1 : γ < 1) (D : S → ℝ)
    (hD : ∀ s, D s ≤ γ * ∑ t, q s t * D t) (s : S) : D s ≤ 0 := by
  obtain ⟨s0, -, hs0⟩ := Finset.exists_max_image Finset.univ D ⟨s, Finset.mem_univ s⟩
  have hle : ∑ t, q s0 t * D t ≤ D s0 := by
    calc ∑ t, q s0 t * D t ≤ ∑ t, q s0 t * D s0 :=
          Finset.sum_le_sum fun t _ => mul_le_mul_of_nonneg_left (hs0 t (Finset.mem_univ t))
            (hq_nonneg s0 t)
      _ = D s0 := by rw [← Finset.sum_mul, hq_sum, one_mul]
  have h1 := hD s0
  have h2 : γ * ∑ t, q s0 t * D t ≤ γ * D s0 := mul_le_mul_of_nonneg_left hle hγ0
  have h3 : D s0 ≤ 0 := by nlinarith
  exact le_trans (hs0 s (Finset.mem_univ s)) h3

omit [Fintype A] [Nonempty A] in
/-- Helper: the policy equation `V_π(s) = r(s, π s) + γ ∑_{s'} p(s' | s, π s) V_π(s')`. -/
theorem mdp_helper_policy_equation (p : S → A → S → ℝ) (r : S → A → ℝ) (γ : ℝ)
    (hp_nonneg : ∀ s a s', 0 ≤ p s a s') (hp_sum : ∀ s a, ∑ s', p s a s' = 1)
    (hγ0 : 0 ≤ γ) (hγ1 : γ < 1) (π : S → A) (s : S) :
    mdpPolicyValue p r γ π s
      = r s (π s) + γ * ∑ s', p s (π s) s' * mdpPolicyValue p r γ π s' := by
  have hsum := mdp_helper_summable p r γ hp_nonneg hp_sum hγ0 hγ1 π
  unfold mdpPolicyValue
  rw [(hsum s).tsum_eq_zero_add]
  simp only [pow_zero, one_mul, Matrix.one_mulVec]
  congr 1
  have key : ∀ k : ℕ, γ ^ (k + 1) *
      ((mdpPolicyMatrix p π ^ (k + 1)).mulVec (fun t => r t (π t))) s
      = γ * ∑ s', p s (π s) s' *
        (γ ^ k * ((mdpPolicyMatrix p π ^ k).mulVec (fun t => r t (π t))) s') := by
    intro k
    rw [pow_succ' γ, pow_succ' (mdpPolicyMatrix p π), ← Matrix.mulVec_mulVec]
    generalize (mdpPolicyMatrix p π ^ k).mulVec (fun t => r t (π t)) = w
    simp only [Matrix.mulVec, dotProduct, mdpPolicyMatrix, Finset.mul_sum]
    apply Finset.sum_congr rfl
    intro t _
    ring
  simp_rw [key]
  rw [tsum_mul_left, Summable.tsum_finsetSum (fun s' _ => (hsum s').mul_left _)]
  congr 1
  apply Finset.sum_congr rfl
  intro t _
  rw [tsum_mul_left]

/-- Card's main claim. In a Markov decision process with finitely many states and actions,
transition chances that are nonnegative and add to 1 from each state and action, and a discount
factor `0 ≤ γ < 1`: if the value of policy `π` satisfies the Bellman optimality equation, then
`π` is optimal, meaning no other policy `σ` has a larger value from any state. -/
theorem policy_optimal_of_value_satisfies_bellman (p : S → A → S → ℝ) (r : S → A → ℝ) (γ : ℝ)
    (hp_nonneg : ∀ s a s', 0 ≤ p s a s') (hp_sum : ∀ s a, ∑ s', p s a s' = 1)
    (hγ0 : 0 ≤ γ) (hγ1 : γ < 1) (π : S → A)
    (hπ : MdpBellmanOptimal p r γ (mdpPolicyValue p r γ π)) :
    ∀ (σ : S → A) (s : S), mdpPolicyValue p r γ σ s ≤ mdpPolicyValue p r γ π s := by
  intro σ s
  have hV := mdp_helper_policy_equation p r γ hp_nonneg hp_sum hγ0 hγ1 σ
  apply sub_nonpos.mp
  refine mdp_helper_contraction (fun s t => p s (σ s) t) (fun s t => hp_nonneg s (σ s) t)
    (fun s => hp_sum s (σ s)) γ hγ0 hγ1
    (fun u => mdpPolicyValue p r γ σ u - mdpPolicyValue p r γ π u) ?_ s
  intro u
  have hb : mdpBracket p r γ (mdpPolicyValue p r γ π) u (σ u) ≤ mdpPolicyValue p r γ π u := by
    rw [hπ u]
    exact Finset.le_sup' _ (Finset.mem_univ _)
  unfold mdpBracket at hb
  rw [hV u]
  simp only [mul_sub, Finset.sum_sub_distrib]
  linarith

/-- Step 1: the value of a fixed policy satisfies its own linear equations,
`V_π(s) = r(s, π s) + γ ∑_{s'} p(s' | s, π s) V_π(s')` for every state `s`. -/
theorem policy_value_satisfies_policy_equation (p : S → A → S → ℝ) (r : S → A → ℝ) (γ : ℝ)
    (hp_nonneg : ∀ s a s', 0 ≤ p s a s') (hp_sum : ∀ s a, ∑ s', p s a s' = 1)
    (hγ0 : 0 ≤ γ) (hγ1 : γ < 1) (π : S → A) (s : S) :
    mdpPolicyValue p r γ π s
      = r s (π s) + γ * ∑ s', p s (π s) s' * mdpPolicyValue p r γ π s' := by
  exact mdp_helper_policy_equation p r γ hp_nonneg hp_sum hγ0 hγ1 π s

/-- Step 3, part 1: if a list of numbers `V` satisfies the Bellman optimality equation and `π`
takes, in each state, an action with the largest bracket, then `V` is exactly the value of `π`
(and so, by the main theorem, `π` is optimal). -/
theorem value_eq_of_bellman_solution_and_greedy (p : S → A → S → ℝ) (r : S → A → ℝ) (γ : ℝ)
    (hp_nonneg : ∀ s a s', 0 ≤ p s a s') (hp_sum : ∀ s a, ∑ s', p s a s' = 1)
    (hγ0 : 0 ≤ γ) (hγ1 : γ < 1) (V : S → ℝ) (hV : MdpBellmanOptimal p r γ V) (π : S → A)
    (hπ : ∀ s a, mdpBracket p r γ V s a ≤ mdpBracket p r γ V s (π s)) :
    V = mdpPolicyValue p r γ π := by
  have hW := mdp_helper_policy_equation p r γ hp_nonneg hp_sum hγ0 hγ1 π
  have hVeq : ∀ s, V s = r s (π s) + γ * ∑ s', p s (π s) s' * V s' := by
    intro s
    apply le_antisymm
    · rw [hV s]
      exact Finset.sup'_le _ _ (fun a _ => hπ s a)
    · have : mdpBracket p r γ V s (π s) ≤ V s := by
        rw [hV s]
        exact Finset.le_sup' _ (Finset.mem_univ _)
      exact this
  have hq_nonneg : ∀ s t, 0 ≤ p s (π s) t := fun s t => hp_nonneg s (π s) t
  have hq_sum : ∀ s, ∑ t, p s (π s) t = 1 := fun s => hp_sum s (π s)
  funext s
  apply le_antisymm
  · apply sub_nonpos.mp
    apply mdp_helper_contraction (fun s t => p s (π s) t) hq_nonneg hq_sum γ hγ0 hγ1
      (fun u => V u - mdpPolicyValue p r γ π u)
    intro u
    rw [hVeq u, hW u]
    simp only [mul_sub, Finset.sum_sub_distrib]
    linarith
  · apply sub_nonpos.mp
    apply mdp_helper_contraction (fun s t => p s (π s) t) hq_nonneg hq_sum γ hγ0 hγ1
      (fun u => mdpPolicyValue p r γ π u - V u)
    intro u
    rw [hVeq u, hW u]
    simp only [mul_sub, Finset.sum_sub_distrib]
    linarith

/-! The card's exact worked numbers. -/

-- r(2, high) = -1.50: rewards -25, -10, -10, -10, 90 with chances 0.1, 0.2, 0.4, 0.2, 0.1.
example : (1/10 : ℚ) * (-25) + 2/10 * (-10) + 4/10 * (-10) + 2/10 * (-10) + 1/10 * 90 = -3/2 := by
  norm_num

-- r(2, low) = 10: the month ends at level 2 or below for rain 0 or 1 (40 - 100), otherwise 40.
example : (1/10 : ℚ) * (40 - 100) + 2/10 * (40 - 100) + 4/10 * 40 + 2/10 * 40 + 1/10 * 40 = 10 := by
  norm_num

-- r(2, medium) = 5: the month ends at level 2 or below for rain 0, 1 or 2 (75 - 100), otherwise 75.
example : (1/10 : ℚ) * (75 - 100) + 2/10 * (75 - 100) + 4/10 * (75 - 100) + 2/10 * 75 + 1/10 * 75
    = 5 := by
  norm_num

-- The reservoir model has 280 nonzero transition chances: for each level s (0 to 19) and release
-- a (1 to 3), count the distinct next levels min(19, s + w - min(a, s + w)) over rain w = 0 to 4.
example : (∑ s ∈ range 20, ∑ a ∈ Icc 1 3,
    ((range 5).image fun w => min 19 (s + w - min a (s + w))).card) = 280 := by
  decide

-- One reservoir: a table of 20 × 3 × 20 = 1,200 chances and 3^20 = 3,486,784,401 policies.
example : 20 * 3 * 20 = 1200 ∧ 3 ^ 20 = 3486784401 := by norm_num

-- d linked reservoirs: 20^d states, 3^d actions, 20^d · 3^d · 20^d multiply-adds per sweep.
example : 20 ^ 2 = 400 ∧ 3 ^ 2 = 9 ∧ 20 ^ 2 * 3 ^ 2 * 20 ^ 2 = 1440000 := by norm_num
example : 20 ^ 3 = 8000 ∧ 3 ^ 3 = 27 ∧ 20 ^ 3 * 3 ^ 3 * 20 ^ 3 = 1728000000 := by norm_num
example : 20 ^ 10 = 10240000000000 ∧ 3 ^ 10 = 59049 ∧
    20 ^ 10 * 3 ^ 10 * 20 ^ 10 = 6191736422400000000000000000000 := by norm_num

-- The number of policies for d reservoirs is 3^(d · 20^d): 10 digits for d = 1, 382 for d = 2.
-- A whole number has k digits exactly when it lies in [10^(k-1), 10^k).
example : 10 ^ 9 ≤ 3 ^ (1 * 20 ^ 1) ∧ 3 ^ (1 * 20 ^ 1) < 10 ^ 10 := by norm_num
example : 10 ^ 381 ≤ 3 ^ (2 * 20 ^ 2) ∧ 3 ^ (2 * 20 ^ 2) < 10 ^ 382 := by
  set_option exponentiation.threshold 1000 in norm_num

#print axioms mdp_helper_pow_mulVec_bound
#print axioms mdp_helper_summable
#print axioms mdp_helper_contraction
#print axioms mdp_helper_policy_equation
#print axioms policy_optimal_of_value_satisfies_bellman
#print axioms policy_value_satisfies_policy_equation
#print axioms value_eq_of_bellman_solution_and_greedy
