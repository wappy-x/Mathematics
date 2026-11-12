-- Value and policy iteration: in a finite discounted decision problem, value iteration's stopping test guarantees a rule within ε of the best, the greedy switch never lowers a rule's values, and policy iteration stops after finitely many rounds at a rule no other rule beats.
import Mathlib.Analysis.Normed.Group.Constructions
import Mathlib.Analysis.Normed.Order.Lattice
import Mathlib.Topology.Algebra.InfiniteSum.Real
import Mathlib.Data.Matrix.Mul
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.Fintype.Lattice
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Finset.Lattice.Fold
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Analysis.Normed.Group.InfiniteSum

open Finset

/-! A finite discounted decision problem, as on the card: finitely many states `S` (the bands),
in each state `s` a finite nonempty set `A s` of allowed actions (the releases), rewards `r s a`,
transition chances `p s a s'` (the chance of state `s'` next month after action `a` in state `s`)
and a discount `γ`. A rule (policy) `π : (s : S) → A s` picks one allowed action in each state.
Value tables are `S → ℝ`; Mathlib's norm on `S → ℝ` is the sup norm `‖U - W‖ = max_s |U s - W s|`. -/

variable {S : Type*} [Fintype S] [DecidableEq S] {A : S → Type*}
  [∀ s, Fintype (A s)] [∀ s, Nonempty (A s)]

/-- The bracket `r(s, a) + γ ∑_{s'} p(s' | s, a) V(s')`: this month's money for action `a` in
state `s` plus `γ` times the average worth `V` of next month's state. -/
def vpQ (r : (s : S) → A s → ℝ) (p : (s : S) → A s → S → ℝ) (γ : ℝ) (V : S → ℝ) (s : S)
    (a : A s) : ℝ :=
  r s a + γ * ∑ s', p s a s' * V s'

/-- One sweep of value iteration (the Bellman operator): `(T V)(s) = max_a [bracket]`. -/
noncomputable def vpBellman (r : (s : S) → A s → ℝ) (p : (s : S) → A s → S → ℝ) (γ : ℝ)
    (V : S → ℝ) : S → ℝ :=
  fun s => univ.sup' univ_nonempty (vpQ r p γ V s)

/-- The table of chances `P_π` of the chain that rule `π` produces: row `s` holds `p(s' | s, π s)`. -/
def vpPolicyMatrix (p : (s : S) → A s → S → ℝ) (π : (s : S) → A s) : Matrix S S ℝ :=
  fun s s' => p s (π s) s'

/-- A rule's own value `V^π(s)`: the expected total of discounted money when the process starts in
`s` and follows `π` for ever, `∑ₖ γᵏ (P_πᵏ r_π)(s)`. -/
noncomputable def vpPolicyValue (r : (s : S) → A s → ℝ) (p : (s : S) → A s → S → ℝ) (γ : ℝ)
    (π : (s : S) → A s) : S → ℝ :=
  fun s => ∑' k : ℕ, γ ^ k * ((vpPolicyMatrix p π ^ k).mulVec (fun t => r t (π t))) s

/-- One round of policy iteration: evaluate `π` exactly, then at each state switch to an action
with the largest bracket against `V^π`, keeping the old action `π s` on a tie. -/
noncomputable def vpImprove (r : (s : S) → A s → ℝ) (p : (s : S) → A s → S → ℝ) (γ : ℝ)
    (π : (s : S) → A s) : (s : S) → A s := fun s =>
  if ∀ a, vpQ r p γ (vpPolicyValue r p γ π) s a ≤ vpQ r p γ (vpPolicyValue r p γ π) s (π s) then
    π s
  else (Finite.exists_max (vpQ r p γ (vpPolicyValue r p γ π) s)).choose

/-- Helper: a weighted average with nonnegative weights adding to 1 is at most any upper bound. -/
theorem vp_avg_le (q : S → ℝ) (hq0 : ∀ s', 0 ≤ q s') (hq1 : ∑ s', q s' = 1) (D : S → ℝ) (m : ℝ)
    (hm : ∀ s', D s' ≤ m) : ∑ s', q s' * D s' ≤ m := by
  calc ∑ s', q s' * D s' ≤ ∑ s', q s' * m :=
        Finset.sum_le_sum fun s' _ => mul_le_mul_of_nonneg_left (hm s') (hq0 s')
    _ = m := by rw [← Finset.sum_mul, hq1, one_mul]

#print axioms vp_avg_le

/-- Helper: the absolute value of such an average is at most any bound on `|D|`. -/
theorem vp_abs_avg_le (q : S → ℝ) (hq0 : ∀ s', 0 ≤ q s') (hq1 : ∑ s', q s' = 1) (D : S → ℝ)
    (m : ℝ) (hm : ∀ s', |D s'| ≤ m) : |∑ s', q s' * D s'| ≤ m := by
  rw [abs_le]
  constructor
  · have := vp_avg_le q hq0 hq1 (fun s' => - D s') m (fun s' => by
      have := hm s'; rw [abs_le] at this; linarith)
    simp only [mul_neg, Finset.sum_neg_distrib] at this
    linarith
  · exact vp_avg_le q hq0 hq1 D m (fun s' => (le_abs_self _).trans (hm s'))

#print axioms vp_abs_avg_le

/-- Helper: if `D ≤ γ P D` for a stochastic `P` and `0 ≤ γ < 1`, then `D ≤ 0`. -/
theorem vp_nonpos_of_le_disc (q : S → S → ℝ) (hq0 : ∀ s s', 0 ≤ q s s')
    (hq1 : ∀ s, ∑ s', q s s' = 1) (γ : ℝ) (hγ0 : 0 ≤ γ) (hγ1 : γ < 1) (D : S → ℝ)
    (h : ∀ s, D s ≤ γ * ∑ s', q s s' * D s') : ∀ s, D s ≤ 0 := by
  intro s
  have : Nonempty S := ⟨s⟩
  obtain ⟨s0, hs0⟩ := Finite.exists_max D
  have h1 := vp_avg_le (q s0) (hq0 s0) (hq1 s0) D (D s0) hs0
  have h2 := h s0
  have h3 : D s0 ≤ γ * D s0 := h2.trans (mul_le_mul_of_nonneg_left h1 hγ0)
  have h4 : D s0 ≤ 0 := by nlinarith
  exact (hs0 s).trans h4

#print axioms vp_nonpos_of_le_disc

/-- Helper: the rows of `P_π ^ k` applied to a table stay within the table's sup norm. -/
theorem vp_pow_mulVec_abs_le (p : (s : S) → A s → S → ℝ) (hp_nonneg : ∀ s a s', 0 ≤ p s a s')
    (hp_sum : ∀ s a, ∑ s', p s a s' = 1) (π : (s : S) → A s) (R : S → ℝ) (B : ℝ)
    (hB : ∀ s, |R s| ≤ B) (k : ℕ) (s : S) :
    |((vpPolicyMatrix p π ^ k).mulVec R) s| ≤ B := by
  induction k generalizing s with
  | zero => simpa using hB s
  | succ k ih =>
    rw [pow_succ', ← Matrix.mulVec_mulVec]
    exact vp_abs_avg_le (p s (π s)) (hp_nonneg s (π s)) (hp_sum s (π s)) _ B ih

#print axioms vp_pow_mulVec_abs_le

/-- Helper: a rule's value solves `V^π = r_π + γ P_π V^π`. -/
theorem vp_policyValue_eq (r : (s : S) → A s → ℝ) (p : (s : S) → A s → S → ℝ) (γ : ℝ)
    (hp_nonneg : ∀ s a s', 0 ≤ p s a s') (hp_sum : ∀ s a, ∑ s', p s a s' = 1)
    (hγ0 : 0 ≤ γ) (hγ1 : γ < 1) (π : (s : S) → A s) (s : S) :
    vpPolicyValue r p γ π s = vpQ r p γ (vpPolicyValue r p γ π) s (π s) := by
  set M := vpPolicyMatrix p π
  set R : S → ℝ := fun t => r t (π t)
  set g : ℕ → S → ℝ := fun k s => γ ^ k * (M ^ k).mulVec R s with hg
  have hR : ∀ t, |R t| ≤ ∑ u, |R u| := fun t =>
    Finset.single_le_sum (f := fun u => |R u|) (fun u _ => abs_nonneg _) (Finset.mem_univ t)
  have hsum : ∀ t, Summable (fun k => g k t) := by
    intro t
    refine Summable.of_norm_bounded ((summable_geometric_of_lt_one hγ0 hγ1).mul_left
      (∑ u, |R u|)) (fun k => ?_)
    rw [Real.norm_eq_abs, abs_mul, abs_pow, abs_of_nonneg hγ0, mul_comm]
    exact mul_le_mul_of_nonneg_right (vp_pow_mulVec_abs_le p hp_nonneg hp_sum π R _ hR k t)
      (pow_nonneg hγ0 k)
  have hV : ∀ t, vpPolicyValue r p γ π t = ∑' k, g k t := fun t => rfl
  have hshift : ∀ k, g (k + 1) s = γ * ∑ s', p s (π s) s' * g k s' := by
    intro k
    simp only [hg]
    rw [show M ^ (k + 1) = M * M ^ k from pow_succ' M k, ← Matrix.mulVec_mulVec]
    simp only [Matrix.mulVec, dotProduct, M, vpPolicyMatrix, Finset.mul_sum]
    refine Finset.sum_congr rfl fun s' _ => ?_
    ring
  have htail : HasSum (fun k => g (k + 1) s) (γ * ∑ s', p s (π s) s' * vpPolicyValue r p γ π s') := by
    simp only [hshift]
    refine HasSum.mul_left γ ?_
    refine hasSum_sum fun s' _ => ?_
    rw [hV s']
    exact (hsum s').hasSum.mul_left _
  rw [hV s, (hsum s).tsum_eq_zero_add, htail.tsum_eq]
  simp [hg, vpQ, R]

#print axioms vp_policyValue_eq

/-- Helper: the bracket is monotone in the value table. -/
theorem vp_Q_mono (r : (s : S) → A s → ℝ) (p : (s : S) → A s → S → ℝ) (γ : ℝ)
    (hp_nonneg : ∀ s a s', 0 ≤ p s a s') (hγ0 : 0 ≤ γ) (U W : S → ℝ) (hUW : ∀ t, U t ≤ W t)
    (s : S) (a : A s) : vpQ r p γ U s a ≤ vpQ r p γ W s a := by
  unfold vpQ
  have : ∑ s', p s a s' * U s' ≤ ∑ s', p s a s' * W s' :=
    Finset.sum_le_sum fun s' _ => mul_le_mul_of_nonneg_left (hUW s') (hp_nonneg s a s')
  nlinarith

#print axioms vp_Q_mono

/-- Helper: the difference of two brackets. -/
theorem vp_Q_sub (r : (s : S) → A s → ℝ) (p : (s : S) → A s → S → ℝ) (γ : ℝ) (U W : S → ℝ)
    (s : S) (a : A s) :
    vpQ r p γ U s a - vpQ r p γ W s a = γ * ∑ s', p s a s' * (U s' - W s') := by
  unfold vpQ
  simp only [mul_sub, Finset.sum_sub_distrib]
  ring

#print axioms vp_Q_sub

/-- Helper: brackets against two tables differ by at most `γ` times the tables' distance. -/
theorem vp_Q_sub_abs (r : (s : S) → A s → ℝ) (p : (s : S) → A s → S → ℝ) (γ : ℝ)
    (hp_nonneg : ∀ s a s', 0 ≤ p s a s') (hp_sum : ∀ s a, ∑ s', p s a s' = 1) (hγ0 : 0 ≤ γ)
    (U W : S → ℝ) (s : S) (a : A s) :
    |vpQ r p γ U s a - vpQ r p γ W s a| ≤ γ * ‖U - W‖ := by
  rw [vp_Q_sub, abs_mul, abs_of_nonneg hγ0]
  refine mul_le_mul_of_nonneg_left (vp_abs_avg_le (p s a) (hp_nonneg s a) (hp_sum s a) _ _
    fun s' => ?_) hγ0
  have := norm_le_pi_norm (U - W) s'
  rwa [Pi.sub_apply, Real.norm_eq_abs] at this

#print axioms vp_Q_sub_abs

/-- Helper: a sweep shrinks distances by the factor `γ`. -/
theorem vp_bellman_contract (r : (s : S) → A s → ℝ) (p : (s : S) → A s → S → ℝ) (γ : ℝ)
    (hp_nonneg : ∀ s a s', 0 ≤ p s a s') (hp_sum : ∀ s a, ∑ s', p s a s' = 1) (hγ0 : 0 ≤ γ)
    (U W : S → ℝ) : ‖vpBellman r p γ U - vpBellman r p γ W‖ ≤ γ * ‖U - W‖ := by
  refine (pi_norm_le_iff_of_nonneg (mul_nonneg hγ0 (norm_nonneg _))).2 fun s => ?_
  rw [Pi.sub_apply, Real.norm_eq_abs, abs_sub_le_iff]
  have key : ∀ X Y : S → ℝ, ‖X - Y‖ = ‖U - W‖ →
      vpBellman r p γ X s - vpBellman r p γ Y s ≤ γ * ‖U - W‖ := by
    intro X Y hXY
    unfold vpBellman
    rw [sub_le_iff_le_add]
    refine Finset.sup'_le _ _ fun a _ => ?_
    have h1 := vp_Q_sub_abs r p γ hp_nonneg hp_sum hγ0 X Y s a
    have h2 : vpQ r p γ Y s a ≤ univ.sup' univ_nonempty (vpQ r p γ Y s) :=
      Finset.le_sup' _ (Finset.mem_univ a)
    rw [abs_le, hXY] at h1
    linarith
  exact ⟨key U W rfl, key W U (norm_sub_rev W U)⟩

#print axioms vp_bellman_contract

/-- Helper: `x ≤ γ x + γ d` with `γ < 1` gives `x ≤ γ / (1 - γ) * d`. -/
theorem vp_le_of_le_disc (x d γ : ℝ) (hγ1 : γ < 1) (h : x ≤ γ * x + γ * d) :
    x ≤ γ / (1 - γ) * d := by
  rw [div_mul_eq_mul_div, le_div_iff₀ (by linarith)]
  linarith

#print axioms vp_le_of_le_disc

/-- Helper: the improvement step never lowers the bracket against `V^π`. -/
theorem vp_improve_ge (r : (s : S) → A s → ℝ) (p : (s : S) → A s → S → ℝ) (γ : ℝ)
    (π : (s : S) → A s) (s : S) :
    vpQ r p γ (vpPolicyValue r p γ π) s (π s)
      ≤ vpQ r p γ (vpPolicyValue r p γ π) s (vpImprove r p γ π s) := by
  unfold vpImprove
  split_ifs with hc
  · exact le_rfl
  · exact (Finite.exists_max (vpQ r p γ (vpPolicyValue r p γ π) s)).choose_spec (π s)

#print axioms vp_improve_ge

/-- Helper: where the improvement step switches, the bracket rises strictly. -/
theorem vp_improve_gt (r : (s : S) → A s → ℝ) (p : (s : S) → A s → S → ℝ) (γ : ℝ)
    (π : (s : S) → A s) (s : S) (hs : vpImprove r p γ π s ≠ π s) :
    vpQ r p γ (vpPolicyValue r p γ π) s (π s)
      < vpQ r p γ (vpPolicyValue r p γ π) s (vpImprove r p γ π s) := by
  unfold vpImprove at hs ⊢
  split_ifs at hs ⊢ with hc
  · exact absurd rfl hs
  · obtain ⟨a, ha⟩ := not_forall.1 hc
    exact (not_le.1 ha).trans_le ((Finite.exists_max (vpQ r p γ (vpPolicyValue r p γ π) s)).choose_spec a)

#print axioms vp_improve_gt

/-- Helper: a rule the improvement step leaves unchanged is greedy against its own values. -/
theorem vp_improve_fixed (r : (s : S) → A s → ℝ) (p : (s : S) → A s → S → ℝ) (γ : ℝ)
    (π : (s : S) → A s) (hfix : vpImprove r p γ π = π) (s : S) (a : A s) :
    vpQ r p γ (vpPolicyValue r p γ π) s a ≤ vpQ r p γ (vpPolicyValue r p γ π) s (π s) := by
  have h := congrFun hfix s
  by_contra hc
  unfold vpImprove at h
  split_ifs at h with hc'
  · exact hc (hc' a)
  have := (Finite.exists_max (vpQ r p γ (vpPolicyValue r p γ π) s)).choose_spec a
  rw [h] at this
  exact hc this

#print axioms vp_improve_fixed

/-- Helper: the policy improvement theorem, proved here so the main theorem can use it. -/
theorem vp_policy_improvement_aux (r : (s : S) → A s → ℝ) (p : (s : S) → A s → S → ℝ) (γ : ℝ)
    (hp_nonneg : ∀ s a s', 0 ≤ p s a s') (hp_sum : ∀ s a, ∑ s', p s a s' = 1)
    (hγ0 : 0 ≤ γ) (hγ1 : γ < 1) (π π' : (s : S) → A s)
    (h : ∀ s, vpQ r p γ (vpPolicyValue r p γ π) s (π s)
      ≤ vpQ r p γ (vpPolicyValue r p γ π) s (π' s)) :
    (∀ s, vpPolicyValue r p γ π s ≤ vpPolicyValue r p γ π' s) ∧
    ∀ s, vpQ r p γ (vpPolicyValue r p γ π) s (π s) < vpQ r p γ (vpPolicyValue r p γ π) s (π' s) →
      vpPolicyValue r p γ π s < vpPolicyValue r p γ π' s := by
  have hfix := vp_policyValue_eq r p γ hp_nonneg hp_sum hγ0 hγ1
  have hle : ∀ s, vpPolicyValue r p γ π s ≤ vpPolicyValue r p γ π' s := by
    have := vp_nonpos_of_le_disc (fun s s' => p s (π' s) s') (fun s s' => hp_nonneg s _ s')
      (fun s => hp_sum s _) γ hγ0 hγ1
      (fun s => vpPolicyValue r p γ π s - vpPolicyValue r p γ π' s) (fun s => by
        have e := vp_Q_sub r p γ (vpPolicyValue r p γ π) (vpPolicyValue r p γ π') s (π' s)
        have h1 := hfix π s
        have h2 := hfix π' s
        have h3 := h s
        linarith)
    intro s
    linarith [this s]
  refine ⟨hle, fun s hs => ?_⟩
  have h1 := hfix π s
  have h2 := hfix π' s
  have h3 := vp_Q_mono r p γ hp_nonneg hγ0 _ _ hle s (π' s)
  linarith

#print axioms vp_policy_improvement_aux

/-- Card's main claim: policy iteration stops, and where it stops is the best. With finitely many
states and actions, transition chances that are nonnegative and add to 1, and a discount
`0 ≤ γ < 1`: from any starting rule, after fewer rounds than there are rules, a round switches
nothing; the rule reached then satisfies the Bellman optimality equation and no rule earns more
than it from any state. -/
theorem policy_iteration_stops_at_best_rule (r : (s : S) → A s → ℝ) (p : (s : S) → A s → S → ℝ)
    (γ : ℝ) (hp_nonneg : ∀ s a s', 0 ≤ p s a s') (hp_sum : ∀ s a, ∑ s', p s a s' = 1)
    (hγ0 : 0 ≤ γ) (hγ1 : γ < 1) (π₀ : (s : S) → A s) :
    ∃ n < Fintype.card ((s : S) → A s),
      vpImprove r p γ ((vpImprove r p γ)^[n] π₀) = (vpImprove r p γ)^[n] π₀ ∧
      vpBellman r p γ (vpPolicyValue r p γ ((vpImprove r p γ)^[n] π₀))
        = vpPolicyValue r p γ ((vpImprove r p γ)^[n] π₀) ∧
      ∀ (σ : (s : S) → A s) (s : S),
        vpPolicyValue r p γ σ s ≤ vpPolicyValue r p γ ((vpImprove r p γ)^[n] π₀) s := by
  have hval := vp_policyValue_eq r p γ hp_nonneg hp_sum hγ0 hγ1
  have step : ∀ π, vpImprove r p γ π ≠ π →
      vpPolicyValue r p γ π < vpPolicyValue r p γ (vpImprove r p γ π) := by
    intro π hne
    obtain ⟨hle, hlt⟩ := vp_policy_improvement_aux r p γ hp_nonneg hp_sum hγ0 hγ1 π
      (vpImprove r p γ π) (vp_improve_ge r p γ π)
    obtain ⟨s, hs⟩ := Function.ne_iff.1 hne
    exact Pi.lt_def.2 ⟨hle, s, hlt s (vp_improve_gt r p γ π s hs)⟩
  have hex : ∃ n < Fintype.card ((s : S) → A s),
      vpImprove r p γ ((vpImprove r p γ)^[n] π₀) = (vpImprove r p γ)^[n] π₀ := by
    by_contra hcon
    have hcon' : ∀ n < Fintype.card ((s : S) → A s),
        vpImprove r p γ ((vpImprove r p γ)^[n] π₀) ≠ (vpImprove r p γ)^[n] π₀ :=
      fun n hn h => hcon ⟨n, hn, h⟩
    have key : ∀ n < Fintype.card ((s : S) → A s),
        vpPolicyValue r p γ ((vpImprove r p γ)^[n] π₀)
          < vpPolicyValue r p γ ((vpImprove r p γ)^[n + 1] π₀) := by
      intro n hn
      rw [Function.iterate_succ_apply']
      exact step _ (hcon' n hn)
    have chain : ∀ d i, i + d + 1 ≤ Fintype.card ((s : S) → A s) →
        vpPolicyValue r p γ ((vpImprove r p γ)^[i] π₀)
          < vpPolicyValue r p γ ((vpImprove r p γ)^[i + d + 1] π₀) := by
      intro d
      induction d with
      | zero => intro i hi; exact key i (by omega)
      | succ d ih =>
        intro i hi
        have h2 := key (i + d + 1) (by omega)
        rw [show i + d + 1 + 1 = i + (d + 1) + 1 by omega] at h2
        exact (ih i (by omega)).trans h2
    have hinj : Function.Injective
        (fun i : Fin (Fintype.card ((s : S) → A s) + 1) => (vpImprove r p γ)^[i.1] π₀) := by
      have aux : ∀ i j : Fin (Fintype.card ((s : S) → A s) + 1), i.1 < j.1 →
          (vpImprove r p γ)^[i.1] π₀ ≠ (vpImprove r p γ)^[j.1] π₀ := by
        intro i j hij heq
        have := chain (j.1 - i.1 - 1) i.1 (by omega)
        rw [show i.1 + (j.1 - i.1 - 1) + 1 = j.1 by omega, ← heq] at this
        exact lt_irrefl _ this
      intro i j hij
      simp only at hij
      by_contra hne
      rcases lt_or_gt_of_ne (Fin.val_ne_of_ne hne) with h | h
      · exact aux i j h hij
      · exact aux j i h hij.symm
    have := Fintype.card_le_of_injective _ hinj
    simp at this
  obtain ⟨n, hn, hfix⟩ := hex
  have hgreedy := vp_improve_fixed r p γ _ hfix
  refine ⟨n, hn, hfix, ?_, ?_⟩
  · funext s
    unfold vpBellman
    refine le_antisymm (Finset.sup'_le _ _ fun a _ => (hgreedy s a).trans_eq (hval _ s).symm) ?_
    rw [hval _ s]
    exact Finset.le_sup' _ (Finset.mem_univ _)
  · intro σ
    have := vp_nonpos_of_le_disc (fun s s' => p s (σ s) s') (fun s s' => hp_nonneg s _ s')
      (fun s => hp_sum s _) γ hγ0 hγ1
      (fun s => vpPolicyValue r p γ σ s - vpPolicyValue r p γ ((vpImprove r p γ)^[n] π₀) s)
      (fun s => by
        have e := vp_Q_sub r p γ (vpPolicyValue r p γ σ)
          (vpPolicyValue r p γ ((vpImprove r p γ)^[n] π₀)) s (σ s)
        have h1 := hval σ s
        have h2 := hval ((vpImprove r p γ)^[n] π₀) s
        have h3 := hgreedy s (σ s)
        linarith)
    intro s
    linarith [this s]

/-- The policy improvement theorem: if a rule `π'` takes, at every state, an action that does at
least as well as `π s` against the values `V^π`, then `V^{π'}(s) ≥ V^π(s)` at every state; and
where it does strictly better, the gain is strict. -/
theorem policy_improvement (r : (s : S) → A s → ℝ) (p : (s : S) → A s → S → ℝ) (γ : ℝ)
    (hp_nonneg : ∀ s a s', 0 ≤ p s a s') (hp_sum : ∀ s a, ∑ s', p s a s' = 1)
    (hγ0 : 0 ≤ γ) (hγ1 : γ < 1) (π π' : (s : S) → A s)
    (h : ∀ s, vpQ r p γ (vpPolicyValue r p γ π) s (π s)
      ≤ vpQ r p γ (vpPolicyValue r p γ π) s (π' s)) :
    (∀ s, vpPolicyValue r p γ π s ≤ vpPolicyValue r p γ π' s) ∧
    ∀ s, vpQ r p γ (vpPolicyValue r p γ π) s (π s) < vpQ r p γ (vpPolicyValue r p γ π) s (π' s) →
      vpPolicyValue r p γ π s < vpPolicyValue r p γ π' s := by
  exact vp_policy_improvement_aux r p γ hp_nonneg hp_sum hγ0 hγ1 π π' h

/-- Value iteration's error bounds and stopping test. With `V*` the table a sweep leaves unchanged
and `V_k` the table after `k` sweeps from any start: each sweep shrinks the error by `γ`,
`‖V_{k+1} - V*‖ ≤ γ ‖V_k - V*‖`; the error is at most `γ / (1 - γ)` times the last change; and
if the last change is below `ε (1 - γ) / (2γ)`, the table is within `ε / 2` of `V*` and every
rule read off it (an action winning the maximum at each state) has values within `ε` of `V*`. -/
theorem value_iteration_stopping_bound (r : (s : S) → A s → ℝ) (p : (s : S) → A s → S → ℝ)
    (γ : ℝ) (hp_nonneg : ∀ s a s', 0 ≤ p s a s') (hp_sum : ∀ s a, ∑ s', p s a s' = 1)
    (hγ0 : 0 ≤ γ) (hγ1 : γ < 1) (Vstar : S → ℝ) (hfix : vpBellman r p γ Vstar = Vstar)
    (V₀ : S → ℝ) (k : ℕ) (ε : ℝ) :
    ‖(vpBellman r p γ)^[k + 1] V₀ - Vstar‖ ≤ γ * ‖(vpBellman r p γ)^[k] V₀ - Vstar‖ ∧
    ‖(vpBellman r p γ)^[k + 1] V₀ - Vstar‖
      ≤ γ / (1 - γ) * ‖(vpBellman r p γ)^[k + 1] V₀ - (vpBellman r p γ)^[k] V₀‖ ∧
    (‖(vpBellman r p γ)^[k + 1] V₀ - (vpBellman r p γ)^[k] V₀‖ < ε * (1 - γ) / (2 * γ) →
      ‖(vpBellman r p γ)^[k + 1] V₀ - Vstar‖ < ε / 2 ∧
      ∀ π : (s : S) → A s,
        (∀ s a, vpQ r p γ ((vpBellman r p γ)^[k + 1] V₀) s a
          ≤ vpQ r p γ ((vpBellman r p γ)^[k + 1] V₀) s (π s)) →
        ‖vpPolicyValue r p γ π - Vstar‖ < ε) := by
  have hT := vp_bellman_contract r p γ hp_nonneg hp_sum hγ0
  have hsucc : (vpBellman r p γ)^[k + 1] V₀ = vpBellman r p γ ((vpBellman r p γ)^[k] V₀) :=
    Function.iterate_succ_apply' _ _ _
  set Vk := (vpBellman r p γ)^[k] V₀
  set V1 := (vpBellman r p γ)^[k + 1] V₀
  have h1 : ‖V1 - Vstar‖ ≤ γ * ‖Vk - Vstar‖ := by
    have := hT Vk Vstar
    rwa [hfix, ← hsucc] at this
  have htri : ‖Vk - Vstar‖ ≤ ‖V1 - Vk‖ + ‖V1 - Vstar‖ := by
    have := norm_sub_le_norm_sub_add_norm_sub Vk V1 Vstar
    rwa [norm_sub_rev Vk V1] at this
  have h2 : ‖V1 - Vstar‖ ≤ γ / (1 - γ) * ‖V1 - Vk‖ :=
    vp_le_of_le_disc _ _ γ hγ1 (by nlinarith)
  refine ⟨h1, h2, fun hd => ?_⟩
  have hγpos : 0 < γ := by
    rcases hγ0.lt_or_eq with h | h
    · exact h
    · rw [← h] at hd; simp at hd; exact absurd hd (not_lt.2 (norm_nonneg _))
  have hc : γ / (1 - γ) * ‖V1 - Vk‖ < ε / 2 := by
    have h1γ : 0 < 1 - γ := by linarith
    calc γ / (1 - γ) * ‖V1 - Vk‖ < γ / (1 - γ) * (ε * (1 - γ) / (2 * γ)) :=
          mul_lt_mul_of_pos_left hd (div_pos hγpos h1γ)
      _ = ε / 2 := by field_simp
  refine ⟨h2.trans_lt hc, fun π hπ => ?_⟩
  -- the greedy rule's one-step value from `V1` is a sweep of `V1`
  have hgreedy : ∀ s, vpBellman r p γ V1 s = vpQ r p γ V1 s (π s) := by
    intro s
    unfold vpBellman
    exact le_antisymm (Finset.sup'_le _ _ fun a _ => hπ s a) (Finset.le_sup' _ (Finset.mem_univ _))
  have hstep : ‖vpBellman r p γ V1 - V1‖ ≤ γ * ‖V1 - Vk‖ := by
    have := hT V1 Vk
    rwa [← hsucc] at this
  set W := vpPolicyValue r p γ π
  have hW : ‖W - V1‖ ≤ γ * ‖W - V1‖ + γ * ‖V1 - Vk‖ := by
    refine (pi_norm_le_iff_of_nonneg (by positivity)).2 fun s => ?_
    rw [Pi.sub_apply, Real.norm_eq_abs]
    have e1 : W s = vpQ r p γ W s (π s) := vp_policyValue_eq r p γ hp_nonneg hp_sum hγ0 hγ1 π s
    have e2 := vp_Q_sub_abs r p γ hp_nonneg hp_sum hγ0 W V1 s (π s)
    have e3 := norm_le_pi_norm (vpBellman r p γ V1 - V1) s
    rw [Pi.sub_apply, Real.norm_eq_abs, hgreedy s] at e3
    rw [e1]
    calc |vpQ r p γ W s (π s) - V1 s|
        ≤ |vpQ r p γ W s (π s) - vpQ r p γ V1 s (π s)| + |vpQ r p γ V1 s (π s) - V1 s| :=
          abs_sub_le _ _ _
      _ ≤ γ * ‖W - V1‖ + γ * ‖V1 - Vk‖ := add_le_add e2 (e3.trans hstep)
  have hW' := vp_le_of_le_disc _ _ γ hγ1 hW
  calc ‖W - Vstar‖ ≤ ‖W - V1‖ + ‖V1 - Vstar‖ := norm_sub_le_norm_sub_add_norm_sub _ _ _
    _ < ε / 2 + ε / 2 := add_lt_add (hW'.trans_lt hc) (h2.trans_lt hc)
    _ = ε := by ring

/-! The card's exact worked numbers, money in thousand pounds, as fractions. -/

-- Money at band 10 for release 0, 1, 2: -7, 1 × (10 + 10) = 20, 2 × 20 = 40; sweep 1 takes 40.
example : max (max (-7 : ℚ) (1 * (10 + 10))) (2 * (10 + 10)) = 40 := by norm_num
-- Sweep 1 at bands 8 to 13: 2 × (10 + s).
example : (2 * (10 + 8), 2 * (10 + 9), 2 * (10 + 10), 2 * (10 + 11), 2 * (10 + 12), 2 * (10 + 13))
    = (36, 38, 40, 42, 44, 46) := by norm_num
-- Sweep 2 at band 10, releases 2, 1, 0: 77.05, 58.95, 33.85.
example : (40 : ℚ) + 95/100 * (2/10 * 36 + 3/10 * 38 + 3/10 * 40 + 2/10 * 42) = 7705/100 := by
  norm_num
example : (20 : ℚ) + 95/100 * (2/10 * 38 + 3/10 * 40 + 3/10 * 42 + 2/10 * 44) = 5895/100 := by
  norm_num
example : (-7 : ℚ) + 95/100 * (2/10 * 40 + 3/10 * 42 + 3/10 * 44 + 2/10 * 46) = 3385/100 := by
  norm_num
-- Money at band 19 for release 0, 1, 2: -67, 1, 50 (fine, sales and flood damage on overflow).
example : (-7 : ℚ) - 40 * (3/10 * 1 + 3/10 * 2 + 2/10 * 3) = -67 := by norm_num
example : (1 * (10 + 19) : ℚ) - 40 * (3/10 * 1 + 2/10 * 2) = 1 := by norm_num
example : (2 * (10 + 19) : ℚ) - 40 * (2/10 * 1) = 50 := by norm_num
-- Stopping threshold ε(1 - γ)/(2γ) with ε = 10, γ = 0.95 is exactly 5/19 (0.2632 rounded),
-- the factor γ/(1 - γ) is 19, and 19 × 5/19 = 5 = ε/2.
example : (10 : ℚ) * (1 - 95/100) / (2 * (95/100)) = 5/19 := by norm_num
example : (95/100 : ℚ) / (1 - 95/100) = 19 := by norm_num
example : (95/100 : ℚ) / (1 - 95/100) * (5/19) = 10 / 2 := by norm_num
-- Rules on the 6-band reservoir: band 0 allows 1 release, band 1 allows 2, bands 2 to 5 allow 3.
example : ∏ s ∈ range 6, (min s 2 + 1) = 162 := by decide
-- Work: a sweep is 4 rain outcomes per allowed release per band, 4 × (1 + 2 + 18 × 3) = 228;
-- 94 sweeps make 21,432; 5 rounds of 3,288 make 16,440.
example : 4 * ∑ s ∈ range 20, (min s 2 + 1) = 228 := by decide
example : 228 * 94 = 21432 ∧ 3288 * 5 = 16440 := by norm_num

#print axioms policy_iteration_stops_at_best_rule
#print axioms policy_improvement
#print axioms value_iteration_stopping_bound
