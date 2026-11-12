-- The Bellman operator contracts: one sweep of value iteration shrinks the worst-state gap between any two value functions by the discount factor, so the sweeps converge to the one fixed point with the card's three error bounds.
import Mathlib.Analysis.Normed.Group.Constructions
import Mathlib.Analysis.Normed.Order.Lattice
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Data.Finset.Lattice.Fold
import Mathlib.Topology.MetricSpace.Contracting

open Filter Topology

/-- The Bellman operator, one sweep: the new worth of state `s` is the best, over the actions
available in `s`, of the reward now plus `γ` times the average worth of the next state.
Value functions are `S → ℝ`; Mathlib's norm on `S → ℝ` (finite `S`) is the sup norm,
the largest gap over states. -/
noncomputable def bellman {S : Type*} [Fintype S] {A : S → Type*} [∀ s, Fintype (A s)]
    [∀ s, Nonempty (A s)] (r : (s : S) → A s → ℝ) (p : (s : S) → A s → S → ℝ) (γ : ℝ)
    (V : S → ℝ) : S → ℝ :=
  fun s => Finset.univ.sup' Finset.univ_nonempty
    (fun a : A s => r s a + γ * ∑ s', p s a s' * V s')

/-- One-sided bound in a single state: `T U s ≤ T W s + γ ‖U - W‖`. -/
theorem bellman_le_add {S : Type*} [Fintype S] {A : S → Type*}
    [∀ s, Fintype (A s)] [∀ s, Nonempty (A s)]
    (r : (s : S) → A s → ℝ) (p : (s : S) → A s → S → ℝ) (γ : ℝ)
    (hp_nonneg : ∀ s a s', 0 ≤ p s a s') (hp_sum : ∀ s a, ∑ s', p s a s' = 1)
    (hγ0 : 0 ≤ γ) (U W : S → ℝ) (s : S) :
    bellman r p γ U s ≤ bellman r p γ W s + γ * ‖U - W‖ := by
  unfold bellman
  apply Finset.sup'_le
  intro a _
  have hsum : ∑ s', p s a s' * U s' ≤ ∑ s', p s a s' * W s' + ‖U - W‖ := by
    have h1 : ∀ s', p s a s' * U s' ≤ p s a s' * W s' + p s a s' * ‖U - W‖ := by
      intro s'
      have hle : U s' - W s' ≤ ‖U - W‖ := by
        have := norm_le_pi_norm (U - W) s'
        simp only [Pi.sub_apply, Real.norm_eq_abs] at this
        exact (le_abs_self _).trans this
      have := mul_le_mul_of_nonneg_left hle (hp_nonneg s a s')
      linarith
    calc ∑ s', p s a s' * U s' ≤ ∑ s', (p s a s' * W s' + p s a s' * ‖U - W‖) :=
          Finset.sum_le_sum fun s' _ => h1 s'
      _ = ∑ s', p s a s' * W s' + ‖U - W‖ := by
          rw [Finset.sum_add_distrib, ← Finset.sum_mul, hp_sum, one_mul]
  have hle : r s a + γ * ∑ s', p s a s' * W s' ≤
      Finset.univ.sup' Finset.univ_nonempty (fun a : A s => r s a + γ * ∑ s', p s a s' * W s') :=
    Finset.le_sup' (fun a : A s => r s a + γ * ∑ s', p s a s' * W s') (Finset.mem_univ a)
  have := mul_le_mul_of_nonneg_left hsum hγ0
  linarith

#print axioms bellman_le_add

/-- The contraction bound, restated as a helper for later proofs. -/
theorem bellman_contraction_aux {S : Type*} [Fintype S] {A : S → Type*}
    [∀ s, Fintype (A s)] [∀ s, Nonempty (A s)]
    (r : (s : S) → A s → ℝ) (p : (s : S) → A s → S → ℝ) (γ : ℝ)
    (hp_nonneg : ∀ s a s', 0 ≤ p s a s') (hp_sum : ∀ s a, ∑ s', p s a s' = 1)
    (hγ0 : 0 ≤ γ) (U W : S → ℝ) :
    ‖bellman r p γ U - bellman r p γ W‖ ≤ γ * ‖U - W‖ := by
  rw [pi_norm_le_iff_of_nonneg (mul_nonneg hγ0 (norm_nonneg _))]
  intro s
  rw [Pi.sub_apply, Real.norm_eq_abs, abs_le]
  have h1 := bellman_le_add r p γ hp_nonneg hp_sum hγ0 U W s
  have h2 := bellman_le_add r p γ hp_nonneg hp_sum hγ0 W U s
  rw [norm_sub_rev W U] at h2
  constructor <;> linarith

#print axioms bellman_contraction_aux

/-- Distance to a fixed point from any `x` is at most `‖T x - x‖ / (1 - γ)`. -/
theorem bellman_dist_fixed_le {S : Type*} [Fintype S] {A : S → Type*}
    [∀ s, Fintype (A s)] [∀ s, Nonempty (A s)]
    (r : (s : S) → A s → ℝ) (p : (s : S) → A s → S → ℝ) (γ : ℝ)
    (hp_nonneg : ∀ s a s', 0 ≤ p s a s') (hp_sum : ∀ s a, ∑ s', p s a s' = 1)
    (hγ0 : 0 ≤ γ) (hγ1 : γ < 1)
    (Vstar : S → ℝ) (hfix : bellman r p γ Vstar = Vstar) (x : S → ℝ) :
    ‖x - Vstar‖ ≤ ‖bellman r p γ x - x‖ / (1 - γ) := by
  have hc := bellman_contraction_aux r p γ hp_nonneg hp_sum hγ0 x Vstar
  rw [hfix] at hc
  have htri : ‖x - Vstar‖ ≤ ‖x - bellman r p γ x‖ + ‖bellman r p γ x - Vstar‖ :=
    norm_sub_le_norm_sub_add_norm_sub _ _ _
  rw [norm_sub_rev x (bellman r p γ x)] at htri
  rw [le_div_iff₀ (by linarith)]
  nlinarith

#print axioms bellman_dist_fixed_le

/-- Iterates approach a fixed point geometrically. -/
theorem bellman_iterate_le {S : Type*} [Fintype S] {A : S → Type*}
    [∀ s, Fintype (A s)] [∀ s, Nonempty (A s)]
    (r : (s : S) → A s → ℝ) (p : (s : S) → A s → S → ℝ) (γ : ℝ)
    (hp_nonneg : ∀ s a s', 0 ≤ p s a s') (hp_sum : ∀ s a, ∑ s', p s a s' = 1)
    (hγ0 : 0 ≤ γ)
    (Vstar : S → ℝ) (hfix : bellman r p γ Vstar = Vstar) (V₀ : S → ℝ) (k : ℕ) :
    ‖(bellman r p γ)^[k] V₀ - Vstar‖ ≤ γ ^ k * ‖V₀ - Vstar‖ := by
  induction k with
  | zero => simp
  | succ n ih =>
    rw [Function.iterate_succ_apply']
    calc ‖bellman r p γ ((bellman r p γ)^[n] V₀) - Vstar‖
        = ‖bellman r p γ ((bellman r p γ)^[n] V₀) - bellman r p γ Vstar‖ := by rw [hfix]
      _ ≤ γ * ‖(bellman r p γ)^[n] V₀ - Vstar‖ :=
          bellman_contraction_aux r p γ hp_nonneg hp_sum hγ0 _ _
      _ ≤ γ * (γ ^ n * ‖V₀ - Vstar‖) := mul_le_mul_of_nonneg_left ih hγ0
      _ = γ ^ (n + 1) * ‖V₀ - Vstar‖ := by ring

#print axioms bellman_iterate_le

/-- The Bellman operator is a contraction: with finitely many states, a nonempty finite set of
actions in each state, fixed rewards, transition probabilities that are non-negative and add up
to 1, and a discount factor `0 ≤ γ < 1`, one sweep brings any two value functions at least `γ`
times closer in the worst state: `‖T U - T W‖∞ ≤ γ ‖U - W‖∞`. -/
theorem bellman_operator_contraction {S : Type*} [Fintype S] {A : S → Type*}
    [∀ s, Fintype (A s)] [∀ s, Nonempty (A s)]
    (r : (s : S) → A s → ℝ) (p : (s : S) → A s → S → ℝ) (γ : ℝ)
    (hp_nonneg : ∀ s a s', 0 ≤ p s a s') (hp_sum : ∀ s a, ∑ s', p s a s' = 1)
    (hγ0 : 0 ≤ γ) (hγ1 : γ < 1) (U W : S → ℝ) :
    ‖bellman r p γ U - bellman r p γ W‖ ≤ γ * ‖U - W‖ := by
  exact bellman_contraction_aux r p γ hp_nonneg hp_sum hγ0 U W

/-- Value iteration converges: under the same hypotheses there is exactly one value function
`V*` with `T V* = V*`, and from any start `V₀` the sweeps `V_k = T^[k] V₀` converge to it,
with error after `k` sweeps at most `γ^k` times the starting error. -/
theorem value_iteration_converges_to_unique_fixed_point {S : Type*} [Fintype S] {A : S → Type*}
    [∀ s, Fintype (A s)] [∀ s, Nonempty (A s)]
    (r : (s : S) → A s → ℝ) (p : (s : S) → A s → S → ℝ) (γ : ℝ)
    (hp_nonneg : ∀ s a s', 0 ≤ p s a s') (hp_sum : ∀ s a, ∑ s', p s a s' = 1)
    (hγ0 : 0 ≤ γ) (hγ1 : γ < 1) :
    (∃! Vstar : S → ℝ, bellman r p γ Vstar = Vstar) ∧
    ∀ Vstar : S → ℝ, bellman r p γ Vstar = Vstar → ∀ V₀ : S → ℝ,
      Tendsto (fun k : ℕ => (bellman r p γ)^[k] V₀) atTop (𝓝 Vstar) ∧
      ∀ k : ℕ, ‖(bellman r p γ)^[k] V₀ - Vstar‖ ≤ γ ^ k * ‖V₀ - Vstar‖ := by
  have hT := bellman_contraction_aux r p γ hp_nonneg hp_sum hγ0
  have hiter := bellman_iterate_le r p γ hp_nonneg hp_sum hγ0
  have hcon : ContractingWith ⟨γ, hγ0⟩ (bellman r p γ) := by
    refine ⟨by exact_mod_cast hγ1, LipschitzWith.of_dist_le_mul fun x y => ?_⟩
    rw [dist_eq_norm, dist_eq_norm]
    exact hT x y
  refine ⟨⟨ContractingWith.fixedPoint _ hcon, hcon.fixedPoint_isFixedPt, ?_⟩, ?_⟩
  · intro y hy
    exact hcon.fixedPoint_unique hy
  · intro Vstar hfix V₀
    refine ⟨?_, hiter Vstar hfix V₀⟩
    rw [tendsto_iff_norm_sub_tendsto_zero]
    have hlim : Tendsto (fun k : ℕ => γ ^ k * ‖V₀ - Vstar‖) atTop (𝓝 0) := by
      simpa using (tendsto_pow_atTop_nhds_zero_of_lt_one hγ0 hγ1).mul_const ‖V₀ - Vstar‖
    exact squeeze_zero (fun _ => norm_nonneg _) (hiter Vstar hfix V₀) hlim

/-- The stopping rules: with `V*` the fixed point and `V_k = T^[k] V₀`, the first-step bound
`‖V_k - V*‖∞ ≤ γ^k / (1 - γ) · ‖V₁ - V₀‖∞` holds for every `k`, and the last-step bound
`‖V_k - V*‖∞ ≤ γ / (1 - γ) · ‖V_k - V_{k-1}‖∞` holds for every `k ≥ 1`. -/
theorem value_iteration_first_and_last_step_bounds {S : Type*} [Fintype S] {A : S → Type*}
    [∀ s, Fintype (A s)] [∀ s, Nonempty (A s)]
    (r : (s : S) → A s → ℝ) (p : (s : S) → A s → S → ℝ) (γ : ℝ)
    (hp_nonneg : ∀ s a s', 0 ≤ p s a s') (hp_sum : ∀ s a, ∑ s', p s a s' = 1)
    (hγ0 : 0 ≤ γ) (hγ1 : γ < 1)
    (Vstar : S → ℝ) (hfix : bellman r p γ Vstar = Vstar) (V₀ : S → ℝ) (k : ℕ) :
    ‖(bellman r p γ)^[k] V₀ - Vstar‖ ≤ γ ^ k / (1 - γ) * ‖bellman r p γ V₀ - V₀‖ ∧
    (1 ≤ k → ‖(bellman r p γ)^[k] V₀ - Vstar‖ ≤
      γ / (1 - γ) * ‖(bellman r p γ)^[k] V₀ - (bellman r p γ)^[k - 1] V₀‖) := by
  have hT := bellman_contraction_aux r p γ hp_nonneg hp_sum hγ0
  have hd := bellman_dist_fixed_le r p γ hp_nonneg hp_sum hγ0 hγ1 Vstar hfix
  have h1g : 0 < 1 - γ := by linarith
  constructor
  · calc ‖(bellman r p γ)^[k] V₀ - Vstar‖ ≤ γ ^ k * ‖V₀ - Vstar‖ :=
          bellman_iterate_le r p γ hp_nonneg hp_sum hγ0 Vstar hfix V₀ k
      _ ≤ γ ^ k * (‖bellman r p γ V₀ - V₀‖ / (1 - γ)) :=
          mul_le_mul_of_nonneg_left (hd V₀) (pow_nonneg hγ0 k)
      _ = γ ^ k / (1 - γ) * ‖bellman r p γ V₀ - V₀‖ := by ring
  · intro hk
    obtain ⟨n, rfl⟩ : ∃ n, k = n + 1 := ⟨k - 1, by omega⟩
    simp only [Nat.add_sub_cancel]
    rw [Function.iterate_succ_apply']
    set x := (bellman r p γ)^[n] V₀
    calc ‖bellman r p γ x - Vstar‖ = ‖bellman r p γ x - bellman r p γ Vstar‖ := by rw [hfix]
      _ ≤ γ * ‖x - Vstar‖ := hT _ _
      _ ≤ γ * (‖bellman r p γ x - x‖ / (1 - γ)) := mul_le_mul_of_nonneg_left (hd x) hγ0
      _ = γ / (1 - γ) * ‖bellman r p γ x - x‖ := by ring

-- Worked numbers (thousand pounds), exact as fractions: sweep 2 at the full reservoir.
-- Release 2 units: 100 + 0.95 × (0.3 × 100 + 0.5 × 120 + 0.2 × 130) = 210.2.
example : (100 : ℚ) + 95/100 * (3/10 * 100 + 5/10 * 120 + 2/10 * 130) = 2102/10 := by norm_num
-- Releases 0, 1, 3, 4 units: 123.5, 180.65, 207.4, 177.5.
example : (0 : ℚ) + 95/100 * 130 = 1235/10 := by norm_num
example : (60 : ℚ) + 95/100 * (3/10 * 120 + 5/10 * 130 + 2/10 * 130) = 18065/100 := by norm_num
example : (120 : ℚ) + 95/100 * (3/10 * 60 + 5/10 * 100 + 2/10 * 120) = 2074/10 := by norm_num
example : (130 : ℚ) + 95/100 * (3/10 * 0 + 5/10 * 60 + 2/10 * 100) = 1775/10 := by norm_num
-- Release 2 is the best of the five.
example : max (max (max (max (1235/10 : ℚ) (18065/100)) (2102/10)) (2074/10)) (1775/10) = 2102/10 := by
  norm_num
-- First-step constant: 130 / (1 - 0.95) = 2600.
example : (130 : ℚ) / (1 - 95/100) = 2600 := by norm_num
-- The first-step bound 0.95^k × 2600 is above 0.1 at k = 198 and at most 0.1 at k = 199,
-- so 199 sweeps are guaranteed in advance.
example : (1 : ℚ)/10 < (95/100) ^ 198 * 2600 := by norm_num
example : (95/100 : ℚ) ^ 199 * 2600 ≤ 1/10 := by norm_num
-- The last-step multiplier γ / (1 - γ) is 19.
example : (95/100 : ℚ) / (1 - 95/100) = 19 := by norm_num

#print axioms bellman_operator_contraction
#print axioms value_iteration_converges_to_unique_fixed_point
#print axioms value_iteration_first_and_last_step_bounds
