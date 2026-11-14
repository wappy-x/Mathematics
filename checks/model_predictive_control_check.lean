-- Predictive control: when the final state is priced by a Riccati solution and the LQR move at the end of the best plan fits inside the limit, the best plan's cost falls by at least the stage cost each tick; a plan in the box that passes the KKT slope test is the best plan; and a cost that falls by the stage cost drives the state to the target.
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Analysis.Normed.Module.FiniteDimension

open Matrix Filter Topology

/-- The model's prediction: x₀ now, then x_{k+1} = A x_k + B u_k, with one current u_k per tick. -/
def mpcPredict {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (B : Fin n → ℝ) (x₀ : Fin n → ℝ)
    (U : ℕ → ℝ) : ℕ → Fin n → ℝ
  | 0 => x₀
  | k + 1 => A *ᵥ mpcPredict A B x₀ U k + U k • B

/-- The cost of the plan U over N ticks from x₀: the sum of x_kᵀQx_k + R u_k² for k < N,
plus the final price x_NᵀPx_N. -/
def mpcCost {n : ℕ} (A Q P : Matrix (Fin n) (Fin n) ℝ) (B : Fin n → ℝ) (R : ℝ) (N : ℕ)
    (x₀ : Fin n → ℝ) (U : ℕ → ℝ) : ℝ :=
  (∑ k ∈ Finset.range N,
      (mpcPredict A B x₀ U k ⬝ᵥ (Q *ᵥ mpcPredict A B x₀ U k) + R * U k ^ 2)) +
    mpcPredict A B x₀ U N ⬝ᵥ (P *ᵥ mpcPredict A B x₀ U N)

lemma mpc_riccati_step {n : ℕ}
    (A Q P : Matrix (Fin n) (Fin n) ℝ) (B K : Fin n → ℝ) (R : ℝ)
    (hric : P = Q + Aᵀ * P * A -
      (R + B ⬝ᵥ (P *ᵥ B))⁻¹ • vecMulVec ((Aᵀ * P) *ᵥ B) (B ᵥ* (P * A)))
    (hK : K = (R + B ⬝ᵥ (P *ᵥ B))⁻¹ • (B ᵥ* (P * A))) (x : Fin n → ℝ) :
    x ⬝ᵥ (Q *ᵥ x) + R * (-(K ⬝ᵥ x)) ^ 2 +
      (A *ᵥ x + (-(K ⬝ᵥ x)) • B) ⬝ᵥ (P *ᵥ (A *ᵥ x + (-(K ⬝ᵥ x)) • B)) =
      x ⬝ᵥ (P *ᵥ x) := by
  set s := R + B ⬝ᵥ (P *ᵥ B) with hs
  have h1 : x ⬝ᵥ (P *ᵥ x) = x ⬝ᵥ (Q *ᵥ x) + (A *ᵥ x) ⬝ᵥ (P *ᵥ (A *ᵥ x)) -
      s⁻¹ * (((A *ᵥ x) ⬝ᵥ (P *ᵥ B)) * (B ⬝ᵥ (P *ᵥ (A *ᵥ x)))) := by
    conv_lhs => rw [hric]
    simp only [sub_mulVec, add_mulVec, smul_mulVec, vecMulVec_mulVec, dotProduct_sub,
      dotProduct_add, dotProduct_smul, ← mulVec_mulVec, dotProduct_mulVec, vecMul_transpose,
      ← vecMul_vecMul, smul_eq_mul, op_smul_eq_smul]
    simp only [← dotProduct_mulVec]
    ring
  have h2 : K ⬝ᵥ x = s⁻¹ * (B ⬝ᵥ (P *ᵥ (A *ᵥ x))) := by
    rw [hK, smul_dotProduct, smul_eq_mul, ← dotProduct_mulVec, ← mulVec_mulVec]
  rw [h1, h2]
  simp only [mulVec_add, mulVec_smul, add_dotProduct, dotProduct_add, smul_dotProduct,
    dotProduct_smul, smul_eq_mul]
  rcases eq_or_ne s 0 with h0 | h0
  · rw [h0] at hs ⊢; simp
  · have : B ⬝ᵥ (P *ᵥ B) = s - R := by rw [hs]; ring
    rw [this]; field_simp; ring

#print axioms mpc_riccati_step

/-- Step 4 of the card: the optimal cost falls every tick.
Plant x_{k+1} = Ax_k + Bu_k with one motor current u, current limit ū, horizon N ≥ 1.
Let P solve the discrete Riccati equation P = Q + AᵀPA - (R + BᵀPB)⁻¹(AᵀPB)(BᵀPA), and let
K = (R + BᵀPB)⁻¹BᵀPA be the LQR gain. Let U be a best plan from x₀ (every move inside the limit,
and no plan inside the limit costs less). If the LQR move -Kx_N at the plan's final state fits
inside the limit, then after applying the first move, x₁ = Ax₀ + Bu₀, some plan inside the limit
from x₁ costs at most J(x₀) - (x₀ᵀQx₀ + Ru₀²); so the best plan from x₁ costs no more than that. -/
theorem mpc_optimal_cost_falls_by_stage_cost {n : ℕ}
    (A Q P : Matrix (Fin n) (Fin n) ℝ) (B K : Fin n → ℝ) (R ubar : ℝ) (N : ℕ) (hN : 0 < N)
    (hric : P = Q + Aᵀ * P * A -
      (R + B ⬝ᵥ (P *ᵥ B))⁻¹ • vecMulVec ((Aᵀ * P) *ᵥ B) (B ᵥ* (P * A)))
    (hK : K = (R + B ⬝ᵥ (P *ᵥ B))⁻¹ • (B ᵥ* (P * A)))
    (x₀ : Fin n → ℝ) (U : ℕ → ℝ)
    (hUfeas : ∀ k < N, |U k| ≤ ubar)
    (hUopt : ∀ V : ℕ → ℝ, (∀ k < N, |V k| ≤ ubar) →
      mpcCost A Q P B R N x₀ U ≤ mpcCost A Q P B R N x₀ V)
    (hfit : |K ⬝ᵥ mpcPredict A B x₀ U N| ≤ ubar) :
    (∃ V : ℕ → ℝ, (∀ k < N, |V k| ≤ ubar) ∧
      mpcCost A Q P B R N (A *ᵥ x₀ + U 0 • B) V ≤
        mpcCost A Q P B R N x₀ U - (x₀ ⬝ᵥ (Q *ᵥ x₀) + R * U 0 ^ 2)) ∧
    (∀ W : ℕ → ℝ, (∀ k < N, |W k| ≤ ubar) →
      (∀ V : ℕ → ℝ, (∀ k < N, |V k| ≤ ubar) →
        mpcCost A Q P B R N (A *ᵥ x₀ + U 0 • B) W ≤ mpcCost A Q P B R N (A *ᵥ x₀ + U 0 • B) V) →
      mpcCost A Q P B R N (A *ᵥ x₀ + U 0 • B) W ≤
        mpcCost A Q P B R N x₀ U - (x₀ ⬝ᵥ (Q *ᵥ x₀) + R * U 0 ^ 2)) := by
  obtain ⟨M, rfl⟩ : ∃ M, N = M + 1 := ⟨N - 1, by omega⟩
  set xN := mpcPredict A B x₀ U (M + 1) with hxN
  let V : ℕ → ℝ := fun k => if k < M then U (k + 1) else -(K ⬝ᵥ xN)
  have hVfeas : ∀ k < M + 1, |V k| ≤ ubar := by
    intro k hk
    by_cases h : k < M
    · simp only [V, h, ↓reduceIte]; exact hUfeas (k + 1) (by omega)
    · simp only [V, h, ↓reduceIte, abs_neg]; exact hfit
  have hpred : ∀ k ≤ M, mpcPredict A B (A *ᵥ x₀ + U 0 • B) V k = mpcPredict A B x₀ U (k + 1) := by
    intro k hk
    induction k with
    | zero => rfl
    | succ k ih =>
      have hkM : k < M := by omega
      simp only [mpcPredict] at ih ⊢
      rw [ih (by omega)]
      simp only [V, hkM, ↓reduceIte]
  have hlast : mpcPredict A B (A *ᵥ x₀ + U 0 • B) V (M + 1) = A *ᵥ xN + (-(K ⬝ᵥ xN)) • B := by
    simp only [mpcPredict]
    rw [hpred M le_rfl]
    simp only [V, lt_irrefl, ↓reduceIte]
    rfl
  have hcost : mpcCost A Q P B R (M + 1) (A *ᵥ x₀ + U 0 • B) V =
      mpcCost A Q P B R (M + 1) x₀ U - (x₀ ⬝ᵥ (Q *ᵥ x₀) + R * U 0 ^ 2) := by
    have key := mpc_riccati_step A Q P B K R hric hK xN
    unfold mpcCost
    rw [Finset.sum_range_succ, Finset.sum_range_succ', hlast, hpred M le_rfl]
    have hsum : ∑ k ∈ Finset.range M,
        (mpcPredict A B (A *ᵥ x₀ + U 0 • B) V k ⬝ᵥ (Q *ᵥ mpcPredict A B (A *ᵥ x₀ + U 0 • B) V k)
          + R * V k ^ 2) =
        ∑ k ∈ Finset.range M,
        (mpcPredict A B x₀ U (k + 1) ⬝ᵥ (Q *ᵥ mpcPredict A B x₀ U (k + 1)) + R * U (k + 1) ^ 2) := by
      refine Finset.sum_congr rfl fun k hk => ?_
      have hk' := Finset.mem_range.mp hk
      rw [hpred k hk'.le]
      simp only [V, hk', ↓reduceIte]
    rw [hsum]
    simp only [V, lt_irrefl, ↓reduceIte]
    rw [← hxN, ← key]
    simp only [mpcPredict]
    ring
  refine ⟨⟨V, hVfeas, hcost.le⟩, fun W _ hW => ?_⟩
  exact (hW V hVfeas).trans hcost.le

/-- Step 3 of the card: for a convex bowl in a box, the KKT conditions certify the best plan.
Let H be positive semidefinite and the cost be UᵀHU + 2fᵀU, whose slope is g = 2(HU + f).
Let U sit inside the box lo ≤ U ≤ hi, with every move either strictly inside its limits and
slope zero, or on a limit with the slope pointing outwards (g ≥ 0 at the lower limit,
g ≤ 0 at the upper). Then no plan inside the box costs less than U. -/
theorem box_qp_kkt_certifies_best_plan {m : ℕ}
    (H : Matrix (Fin m) (Fin m) ℝ) (hH : H.PosSemidef) (f lo hi U : Fin m → ℝ)
    (hbox : ∀ i, lo i ≤ U i ∧ U i ≤ hi i)
    (hkkt : ∀ i,
      (lo i < U i ∧ U i < hi i → 2 * ((H *ᵥ U) i + f i) = 0) ∧
      (U i = lo i → 0 ≤ 2 * ((H *ᵥ U) i + f i)) ∧
      (U i = hi i → 2 * ((H *ᵥ U) i + f i) ≤ 0)) :
    ∀ V : Fin m → ℝ, (∀ i, lo i ≤ V i ∧ V i ≤ hi i) →
      U ⬝ᵥ (H *ᵥ U) + 2 * (f ⬝ᵥ U) ≤ V ⬝ᵥ (H *ᵥ V) + 2 * (f ⬝ᵥ V) := by
  intro V hV
  set g : Fin m → ℝ := H *ᵥ U + f with hg
  have hsymm : V ⬝ᵥ (H *ᵥ U) = U ⬝ᵥ (H *ᵥ V) := by
    have hT : Hᵀ = H := by
      have := hH.1
      rw [IsHermitian, conjTranspose_eq_transpose_of_trivial] at this
      exact this
    rw [dotProduct_mulVec, ← mulVec_transpose, hT, dotProduct_comm]
  have hquad : 0 ≤ (V - U) ⬝ᵥ (H *ᵥ (V - U)) := by
    simpa using hH.dotProduct_mulVec_nonneg (V - U)
  have hlin : 0 ≤ g ⬝ᵥ (V - U) := by
    refine Finset.sum_nonneg fun i _ => ?_
    simp only [Pi.sub_apply]
    obtain ⟨h1, h2, h3⟩ := hkkt i
    have hgi : g i = (H *ᵥ U) i + f i := rfl
    rcases (hbox i).1.lt_or_eq with hl | hl
    · rcases (hbox i).2.lt_or_eq with hh | hh
      · have h0 : (H *ᵥ U) i + f i = 0 := by linarith [h1 ⟨hl, hh⟩]
        rw [hgi, h0, zero_mul]
      · have := h3 hh
        have := (hV i).2
        rw [hgi]; nlinarith
    · have := h2 hl.symm
      have := (hV i).1
      rw [hgi]; nlinarith
  have hexp : V ⬝ᵥ (H *ᵥ V) + 2 * (f ⬝ᵥ V) - (U ⬝ᵥ (H *ᵥ U) + 2 * (f ⬝ᵥ U)) =
      (V - U) ⬝ᵥ (H *ᵥ (V - U)) + 2 * (g ⬝ᵥ (V - U)) := by
    simp only [hg, mulVec_sub, sub_dotProduct, dotProduct_sub, add_dotProduct]
    rw [dotProduct_comm (H *ᵥ U) V, dotProduct_comm (H *ᵥ U) U, hsymm]
    ring
  linarith

lemma posDef_quadratic_coercive {n : ℕ} (Q : Matrix (Fin n) (Fin n) ℝ) (hQ : Q.PosDef) :
    ∃ c : ℝ, 0 < c ∧ ∀ x : Fin n → ℝ, c * (‖x‖ ^ 2) ≤ x ⬝ᵥ (Q *ᵥ x) := by
  rcases isEmpty_or_nonempty (Fin n) with hn | hn
  · refine ⟨1, one_pos, fun x => ?_⟩
    have : x = 0 := Subsingleton.elim _ _
    subst this; simp
  · have hS : IsCompact (Metric.sphere (0 : Fin n → ℝ) 1) := isCompact_sphere 0 1
    have hne : (Metric.sphere (0 : Fin n → ℝ) 1).Nonempty :=
      (NormedSpace.sphere_nonempty).mpr zero_le_one
    have hcont : Continuous fun x : Fin n → ℝ => x ⬝ᵥ (Q *ᵥ x) := by fun_prop
    obtain ⟨y, hy, hmin⟩ := hS.exists_isMinOn hne hcont.continuousOn
    have hy1 : ‖y‖ = 1 := by simpa using hy
    have hy0 : y ≠ 0 := by rintro rfl; simp at hy1
    have hpos : 0 < y ⬝ᵥ (Q *ᵥ y) := by simpa using hQ.dotProduct_mulVec_pos hy0
    refine ⟨_, hpos, fun x => ?_⟩
    rcases eq_or_ne x 0 with rfl | hx
    · simp
    · have hxn : 0 < ‖x‖ := norm_pos_iff.mpr hx
      have hz : ‖x‖⁻¹ • x ∈ Metric.sphere (0 : Fin n → ℝ) 1 := by
        simp [norm_smul, hxn.ne']
      have h := hmin hz
      simp only [Set.mem_ofPred_eq, mulVec_smul, dotProduct_smul, smul_dotProduct,
        smul_eq_mul] at h
      have h2 : ‖x‖ ^ 2 * (‖x‖⁻¹ * (‖x‖⁻¹ * (x ⬝ᵥ (Q *ᵥ x)))) = x ⬝ᵥ (Q *ᵥ x) := by
        field_simp
      calc y ⬝ᵥ (Q *ᵥ y) * ‖x‖ ^ 2 ≤ ‖x‖⁻¹ * (‖x‖⁻¹ * (x ⬝ᵥ (Q *ᵥ x))) * ‖x‖ ^ 2 :=
            mul_le_mul_of_nonneg_right h (by positivity)
        _ = x ⬝ᵥ (Q *ᵥ x) := by rw [mul_comm]; exact h2

#print axioms posDef_quadratic_coercive

/-- Step 4's conclusion: the cost is a Lyapunov function.
Along the closed loop, states x_k and moves u_k, let the best cost J_k never go below zero and fall
every tick by at least the stage cost x_kᵀQx_k + Ru_k², with Q positive definite and R ≥ 0.
Then the stage costs shrink to zero and the state goes to the target (zero). -/
theorem mpc_cost_fall_drives_state_to_target {n : ℕ}
    (Q : Matrix (Fin n) (Fin n) ℝ) (hQ : Q.PosDef) (R : ℝ) (hR : 0 ≤ R)
    (x : ℕ → Fin n → ℝ) (u J : ℕ → ℝ) (hJ : ∀ k, 0 ≤ J k)
    (hfall : ∀ k, J (k + 1) ≤ J k - (x k ⬝ᵥ (Q *ᵥ x k) + R * u k ^ 2)) :
    Tendsto (fun k => x k ⬝ᵥ (Q *ᵥ x k) + R * u k ^ 2) atTop (𝓝 0) ∧
      Tendsto x atTop (𝓝 0) := by
  obtain ⟨c, hc, hcoer⟩ := posDef_quadratic_coercive Q hQ
  set s : ℕ → ℝ := fun k => x k ⬝ᵥ (Q *ᵥ x k) + R * u k ^ 2 with hs
  have hq : ∀ k, 0 ≤ x k ⬝ᵥ (Q *ᵥ x k) := fun k =>
    le_trans (by positivity) (hcoer (x k))
  have hs0 : ∀ k, 0 ≤ s k := fun k => add_nonneg (hq k) (by positivity)
  have hsum : ∀ m, ∑ k ∈ Finset.range m, s k ≤ J 0 - J m := by
    intro m
    induction m with
    | zero => simp
    | succ m ih =>
      rw [Finset.sum_range_succ]
      have := hfall m
      simp only [hs] at this ⊢
      linarith
  have hsumm : Summable s :=
    summable_of_sum_range_le (c := J 0) hs0 (fun m => (hsum m).trans (by linarith [hJ m]))
  have hlim : Tendsto s atTop (𝓝 0) := hsumm.tendsto_atTop_zero
  refine ⟨hlim, ?_⟩
  rw [tendsto_zero_iff_norm_tendsto_zero]
  have hroot : Tendsto (fun k => Real.sqrt (s k / c)) atTop (𝓝 0) := by
    have h0 : Tendsto (fun k => s k / c) atTop (𝓝 0) := by simpa using hlim.div_const c
    have := (Real.continuous_sqrt.tendsto 0).comp h0
    simpa [Function.comp_def] using this
  refine squeeze_zero (fun k => norm_nonneg _) (fun k => ?_) hroot
  rw [← Real.sqrt_sq (norm_nonneg (x k))]
  apply Real.sqrt_le_sqrt
  rw [le_div_iff₀ hc]
  have h1 := hcoer (x k)
  have h2 : 0 ≤ R * u k ^ 2 := by positivity
  simp only [hs]
  nlinarith

-- First stage cost: 1 × (-2)² + 0.1 × (-1)² = 4.1, and the best cost drops 104.0446 → 99.9446, by 4.1.
example : (1 : ℚ) * (-2) ^ 2 + 1 / 10 * (-1) ^ 2 = 41 / 10 := by norm_num
example : (1040446 : ℚ) / 10000 - 999446 / 10000 = 41 / 10 := by norm_num

-- The 0.5 N push as motor current at 4 N per amp: 0.125 A.
example : (1 / 2 : ℚ) / 4 = 1 / 8 := by norm_num

-- Twenty ticks of 0.05 s is a one-second horizon; 120 ticks is the 6 s run, ending at 5.95 s.
example : (20 : ℚ) * (1 / 20) = 1 ∧ (120 : ℚ) * (1 / 20) = 6 ∧ (119 : ℚ) * (1 / 20) = 119 / 20 := by
  norm_num

#print axioms mpc_optimal_cost_falls_by_stage_cost
#print axioms box_qp_kkt_certifies_best_plan
#print axioms mpc_cost_fall_drives_state_to_target
