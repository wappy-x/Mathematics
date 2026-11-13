-- Convergence to equilibrium: a finite irreducible aperiodic Markov chain has a stationary law that every row of its n-step table approaches, at a geometric rate set by the share every row of some block table holds in common.
import Mathlib.LinearAlgebra.Matrix.Irreducible.Defs
import Mathlib.LinearAlgebra.Matrix.Stochastic
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.LinearAlgebra.Matrix.ToLinearEquiv
import Mathlib.NumberTheory.FrobeniusNumber
import Mathlib.Analysis.SpecificLimits.Basic

open Finset Matrix Filter Topology

/-- Total variation distance between two laws on a finite set of states: half the sum of their
gaps, state by state. -/
noncomputable def tvDist {ι : Type*} [Fintype ι] (μ ν : ι → ℝ) : ℝ :=
  (1 / 2) * ∑ j, |μ j - ν j|

/-- A transition table `P` is aperiodic when, at every state `i`, the lengths `k` of the routes
from `i` back to `i` (those with `0 < (P ^ k) i i`) have no common divisor above 1: the chain is
not locked into a cycle. -/
def Aperiodic {ι : Type*} [Fintype ι] [DecidableEq ι] (P : Matrix ι ι ℝ) : Prop :=
  ∀ i : ι, ∀ d : ℕ, (∀ k : ℕ, 0 < (P ^ k) i i → d ∣ k) → d = 1

/-- Helper: one step of a stochastic-type table shrinks the L1 size of a zero-sum vector by the
common share `∑ c`. -/
theorem cte_l1_vecMul_le {ι : Type*} [Fintype ι] (Q : Matrix ι ι ℝ) (c : ι → ℝ)
    (hc : ∀ i j, c j ≤ Q i j) (hrow : ∀ i, ∑ j, Q i j = 1) (d : ι → ℝ) (hd : ∑ i, d i = 0) :
    ∑ j, |vecMul d Q j| ≤ (1 - ∑ j, c j) * ∑ i, |d i| := by
  have h1 : ∀ j, |vecMul d Q j| ≤ ∑ i, |d i| * (Q i j - c j) := by
    intro j
    have : vecMul d Q j = ∑ i, d i * (Q i j - c j) := by
      simp only [vecMul, dotProduct, mul_sub, Finset.sum_sub_distrib, ← Finset.sum_mul, hd,
        zero_mul, sub_zero]
    rw [this]
    refine (Finset.abs_sum_le_sum_abs _ _).trans (le_of_eq ?_)
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [abs_mul, abs_of_nonneg (sub_nonneg.2 (hc i j))]
  calc ∑ j, |vecMul d Q j| ≤ ∑ j, ∑ i, |d i| * (Q i j - c j) :=
        Finset.sum_le_sum fun j _ => h1 j
    _ = ∑ i, |d i| * ∑ j, (Q i j - c j) := by
        rw [Finset.sum_comm]; simp_rw [Finset.mul_sum]
    _ = (1 - ∑ j, c j) * ∑ i, |d i| := by
        simp_rw [Finset.sum_sub_distrib, hrow]
        rw [Finset.mul_sum]
        exact Finset.sum_congr rfl fun _ _ => mul_comm _ _

#print axioms cte_l1_vecMul_le

/-- Helper: a table whose rows add to 1 keeps the total of a vector. -/
theorem cte_sum_vecMul {ι : Type*} [Fintype ι] (Q : Matrix ι ι ℝ) (hrow : ∀ i, ∑ j, Q i j = 1)
    (d : ι → ℝ) : ∑ j, vecMul d Q j = ∑ i, d i := by
  simp only [vecMul, dotProduct]
  rw [Finset.sum_comm]
  simp [← Finset.mul_sum, hrow]

#print axioms cte_sum_vecMul

/-- Helper: Doeblin's bound, stated before the main theorem so that it can use it. -/
theorem cte_doeblin
    {ι : Type*} [Fintype ι] [DecidableEq ι]
    (P : Matrix ι ι ℝ) (hP : P ∈ rowStochastic ℝ ι)
    (r : ℕ) (ν : ι → ℝ) (_hν0 : ∀ j, 0 ≤ ν j) (hν1 : ∑ j, ν j = 1)
    (ε : ℝ) (_hε0 : 0 < ε) (hε1 : ε ≤ 1)
    (hmin : ∀ i j, ε * ν j ≤ (P ^ r) i j)
    (π : ι → ℝ) (hπ0 : ∀ j, 0 ≤ π j) (hπ1 : ∑ j, π j = 1) (hπP : vecMul π P = π) :
    ∀ n : ℕ, ∀ i : ι, (1 / 2) * ∑ j, |(P ^ n) i j - π j| ≤ (1 - ε) ^ (n / r) := by
  have hPn : ∀ n, P ^ n ∈ rowStochastic ℝ ι := fun n => pow_mem hP n
  have hrow : ∀ n i, ∑ j, (P ^ n) i j = 1 := fun n i => sum_row_of_mem_rowStochastic (hPn n) i
  have hnn : ∀ n i j, (0 : ℝ) ≤ (P ^ n) i j := fun n i j => nonneg_of_mem_rowStochastic (hPn n)
  have hε : 0 ≤ 1 - ε := by linarith
  have key : ∀ n, ∀ d : ι → ℝ, ∑ i, d i = 0 →
      ∑ j, |vecMul d (P ^ n) j| ≤ (1 - ε) ^ (n / r) * ∑ i, |d i| := by
    intro n
    induction n using Nat.strong_induction_on with
    | _ n ih =>
      intro d hd
      by_cases h : 0 < r ∧ r ≤ n
      · obtain ⟨hr, hrn⟩ := h
        have hpow : P ^ n = P ^ r * P ^ (n - r) := by
          rw [← pow_add]; congr 1; omega
        rw [hpow, ← Matrix.vecMul_vecMul]
        have hd' : ∑ i, vecMul d (P ^ r) i = 0 := by rw [cte_sum_vecMul _ (hrow r), hd]
        have h1 := ih (n - r) (by omega) _ hd'
        have h2 := cte_l1_vecMul_le (P ^ r) (fun j => ε * ν j) hmin (hrow r) d hd
        rw [← Finset.mul_sum, hν1, mul_one] at h2
        rw [Nat.div_eq_sub_div hr hrn, pow_succ]
        calc _ ≤ (1 - ε) ^ ((n - r) / r) * ∑ i, |vecMul d (P ^ r) i| := h1
          _ ≤ (1 - ε) ^ ((n - r) / r) * ((1 - ε) * ∑ i, |d i|) :=
              mul_le_mul_of_nonneg_left h2 (pow_nonneg hε _)
          _ = _ := by ring
      · have hn : n / r = 0 := by
          rcases Nat.eq_zero_or_pos r with h0 | h0
          · simp [h0]
          · exact Nat.div_eq_of_lt (by omega)
        rw [hn, pow_zero, one_mul]
        have := cte_l1_vecMul_le (P ^ n) (fun _ => 0) (fun i j => hnn n i j) (hrow n) d hd
        simpa using this
  have hπn : ∀ n, vecMul π (P ^ n) = π := by
    intro n
    induction n with
    | zero => simp
    | succ n ih => rw [pow_succ, ← Matrix.vecMul_vecMul, ih, hπP]
  intro n i
  set d : ι → ℝ := fun j => (if j = i then 1 else 0) - π j with hd_def
  have hd : ∑ j, d j = 0 := by
    simp [hd_def, Finset.sum_sub_distrib, hπ1]
  have hvd : ∀ j, vecMul d (P ^ n) j = (P ^ n) i j - π j := by
    intro j
    have := congrFun (hπn n) j
    rw [← this]
    simp only [hd_def, vecMul, dotProduct, sub_mul, Finset.sum_sub_distrib, ite_mul, one_mul,
      zero_mul, Finset.sum_ite_eq', Finset.mem_univ, ite_true]
  have hd2 : ∑ j, |d j| ≤ 2 := by
    have : ∀ j, |d j| ≤ (if j = i then 1 else 0) + π j := by
      intro j
      have h0 : (0 : ℝ) ≤ if j = i then 1 else 0 := by split_ifs <;> norm_num
      rw [abs_le]; constructor <;> simp only [hd_def] <;> linarith [hπ0 j]
    calc ∑ j, |d j| ≤ ∑ j, ((if j = i then 1 else 0) + π j) := Finset.sum_le_sum fun j _ => this j
      _ = 2 := by rw [Finset.sum_add_distrib, hπ1]; simp; norm_num
  have := key n d hd
  simp_rw [hvd] at this
  calc (1 / 2) * ∑ j, |(P ^ n) i j - π j| ≤ (1 / 2) * ((1 - ε) ^ (n / r) * ∑ i, |d i|) :=
        mul_le_mul_of_nonneg_left this (by norm_num)
    _ ≤ (1 / 2) * ((1 - ε) ^ (n / r) * 2) := by
        gcongr
    _ = _ := by ring

#print axioms cte_doeblin
/-- Helper: total variation as the largest event gap. -/
theorem cte_gap {ι : Type*} [Fintype ι] (μ ν : ι → ℝ)
    (_hμ0 : ∀ j, 0 ≤ μ j) (hμ1 : ∑ j, μ j = 1) (_hν0 : ∀ j, 0 ≤ ν j) (hν1 : ∑ j, ν j = 1) :
    (∀ B : Finset ι, ∑ j ∈ B, (μ j - ν j) ≤ (1 / 2) * ∑ j, |μ j - ν j|) ∧
      ∃ A : Finset ι, ∑ j ∈ A, (μ j - ν j) = (1 / 2) * ∑ j, |μ j - ν j| := by
  classical
  have h0 : ∑ j, (μ j - ν j) = 0 := by rw [Finset.sum_sub_distrib, hμ1, hν1, sub_self]
  constructor
  · intro B
    have e1 := Finset.sum_add_sum_compl B (fun j => μ j - ν j)
    have e2 := Finset.sum_add_sum_compl B (fun j => |μ j - ν j|)
    have l1 : ∑ j ∈ B, (μ j - ν j) ≤ ∑ j ∈ B, |μ j - ν j| :=
      Finset.sum_le_sum fun j _ => le_abs_self _
    have l2 : -∑ j ∈ Bᶜ, (μ j - ν j) ≤ ∑ j ∈ Bᶜ, |μ j - ν j| := by
      rw [← Finset.sum_neg_distrib]; exact Finset.sum_le_sum fun j _ => neg_le_abs _
    linarith
  · refine ⟨univ.filter (fun j => 0 ≤ μ j - ν j), ?_⟩
    have e1 := Finset.sum_filter_add_sum_filter_not univ (fun j => 0 ≤ μ j - ν j)
      (fun j => μ j - ν j)
    have e2 := Finset.sum_filter_add_sum_filter_not univ (fun j => 0 ≤ μ j - ν j)
      (fun j => |μ j - ν j|)
    have l1 : ∑ j ∈ univ.filter (fun j => 0 ≤ μ j - ν j), |μ j - ν j|
        = ∑ j ∈ univ.filter (fun j => 0 ≤ μ j - ν j), (μ j - ν j) :=
      Finset.sum_congr rfl fun j hj => abs_of_nonneg (Finset.mem_filter.1 hj).2
    have l2 : ∑ j ∈ univ.filter (fun j => ¬ 0 ≤ μ j - ν j), |μ j - ν j|
        = -∑ j ∈ univ.filter (fun j => ¬ 0 ≤ μ j - ν j), (μ j - ν j) := by
      rw [← Finset.sum_neg_distrib]
      exact Finset.sum_congr rfl fun j hj => abs_of_neg (not_le.1 (Finset.mem_filter.1 hj).2)
    linarith

#print axioms cte_gap

/-- Helper: entries of a product of powers of a nonnegative table. -/
theorem cte_pow_add_ge {ι : Type*} [Fintype ι] [DecidableEq ι] (P : Matrix ι ι ℝ)
    (hnn : ∀ i j, 0 ≤ P i j) (a b : ℕ) (i k j : ι) :
    (P ^ a) i k * (P ^ b) k j ≤ (P ^ (a + b)) i j := by
  rw [pow_add, Matrix.mul_apply]
  exact Finset.single_le_sum (f := fun l => (P ^ a) i l * (P ^ b) l j)
    (fun l _ => mul_nonneg (pow_apply_nonneg hnn a i l) (pow_apply_nonneg hnn b l j))
    (Finset.mem_univ k)

#print axioms cte_pow_add_ge

/-- Helper: an irreducible aperiodic nonnegative table has a power with every entry positive. -/
theorem cte_primitive {ι : Type*} [Fintype ι] [DecidableEq ι] (P : Matrix ι ι ℝ)
    (hnn : ∀ i j, 0 ≤ P i j) (hirr : P.IsIrreducible)
    (hap : ∀ i : ι, ∀ d : ℕ, (∀ k : ℕ, 0 < (P ^ k) i i → d ∣ k) → d = 1) :
    ∃ r : ℕ, 0 < r ∧ ∀ i j, 0 < (P ^ r) i j := by
  have hpath := (isIrreducible_iff_exists_pow_pos hnn).1 hirr
  have hN : ∀ i : ι, ∃ N : ℕ, ∀ m ≥ N, 0 < (P ^ m) i i := by
    intro i
    let S : Set ℕ := {k | 0 < (P ^ k) i i}
    have hg : Nat.setGcd S = 1 := hap i _ fun k hk => Nat.setGcd_dvd_of_mem hk
    have hcl : ∀ m ∈ AddSubmonoid.closure S, 0 < (P ^ m) i i := by
      intro m hm
      induction hm using AddSubmonoid.closure_induction with
      | mem x hx => exact hx
      | zero => simp
      | add x y _ _ hx hy =>
        exact lt_of_lt_of_le (mul_pos hx hy) (cte_pow_add_ge P hnn x y i i i)
    obtain ⟨N, hN⟩ := Nat.exists_mem_closure_of_ge S
    exact ⟨N, fun m hm => hcl m (hN m hm (by rw [hg]; exact one_dvd m))⟩
  choose N hN using hN
  choose m hm0 hm using hpath
  let K := univ.sup N
  let M := univ.sup fun i => univ.sup (m i)
  refine ⟨K + M + 1, by omega, fun i j => ?_⟩
  have hKi : N i ≤ K := Finset.le_sup (f := N) (Finset.mem_univ i)
  have hMij : m i j ≤ M := le_trans (Finset.le_sup (f := m i) (Finset.mem_univ j))
    (Finset.le_sup (f := fun i => univ.sup (m i)) (Finset.mem_univ i))
  have he : K + M + 1 = (K + M + 1 - m i j) + m i j := by omega
  rw [he]
  exact lt_of_lt_of_le (mul_pos (hN i _ (by omega)) (hm i j))
    (cte_pow_add_ge P hnn _ _ i i j)

#print axioms cte_primitive

/-- Helper: a stochastic table has a stationary law. -/
theorem cte_stationary {ι : Type*} [Fintype ι] [DecidableEq ι] [Nonempty ι]
    (P : Matrix ι ι ℝ) (hP : P ∈ rowStochastic ℝ ι) :
    ∃ π : ι → ℝ, (∀ j, 0 ≤ π j) ∧ ∑ j, π j = 1 ∧ vecMul π P = π := by
  have hnn : ∀ i j, 0 ≤ P i j := fun i j => nonneg_of_mem_rowStochastic hP
  have hrow : ∀ i, ∑ j, P i j = 1 := sum_row_of_mem_rowStochastic hP
  have hdet : (P - 1).det = 0 := by
    rw [← Matrix.exists_mulVec_eq_zero_iff]
    refine ⟨fun _ => 1, ?_, ?_⟩
    · intro h
      have := congrFun h (Classical.arbitrary ι)
      simp at this
    · ext i
      simp [mulVec, dotProduct, hrow, Matrix.one_apply]
  obtain ⟨v, hv0, hv⟩ := Matrix.exists_vecMul_eq_zero_iff.2 hdet
  have hvP : vecMul v P = v := by
    rw [Matrix.vecMul_sub, Matrix.vecMul_one, sub_eq_zero] at hv; exact hv
  set w : ι → ℝ := fun j => |v j| with hw
  have hle : ∀ j, w j ≤ vecMul w P j := by
    intro j
    simp only [hw]
    conv_lhs => rw [← hvP]
    simp only [vecMul, dotProduct]
    refine (Finset.abs_sum_le_sum_abs _ _).trans (le_of_eq ?_)
    exact Finset.sum_congr rfl fun i _ => by rw [abs_mul, abs_of_nonneg (hnn i j)]
  have hsum : ∑ j, (vecMul w P j - w j) = 0 := by
    rw [Finset.sum_sub_distrib, cte_sum_vecMul P hrow, sub_self]
  have heq : vecMul w P = w := by
    ext j
    have := (Finset.sum_eq_zero_iff_of_nonneg (fun j _ => sub_nonneg.2 (hle j))).1 hsum j
      (Finset.mem_univ j)
    linarith
  have hS : 0 < ∑ j, w j := by
    obtain ⟨j, hj⟩ := Function.ne_iff.1 hv0
    exact Finset.sum_pos' (fun j _ => abs_nonneg _) ⟨j, Finset.mem_univ j, abs_pos.2 hj⟩
  refine ⟨fun j => w j / ∑ j, w j, fun j => div_nonneg (abs_nonneg _) hS.le, ?_, ?_⟩
  · rw [← Finset.sum_div, div_self hS.ne']
  · ext j
    have := congrFun heq j
    simp only [vecMul, dotProduct] at this ⊢
    simp_rw [div_mul_eq_mul_div]
    rw [← Finset.sum_div, this]

#print axioms cte_stationary

/-- The convergence theorem. A Markov chain on finitely many states (a row-stochastic table `P`)
in which every state can reach every other (irreducible) and which is not locked into a cycle
(aperiodic) forgets where it started. It has a stationary law `π` (`π P = π`); from every start
`i`, the chance `(P ^ n) i j` of state `j` on day `n` tends to `π j`. The distance shrinks at
least geometrically: some block of `r` days has every entry of `P ^ r` positive, and with
`ε = ∑ j, min_i (P ^ r) i j`, the share every row of `P ^ r` holds in common, the total variation
distance from row `i` of `P ^ n` to `π` is at most `(1 - ε) ^ ⌊n / r⌋`. -/
theorem irreducible_aperiodic_chain_converges_to_equilibrium
    {ι : Type*} [Fintype ι] [DecidableEq ι] [Nonempty ι]
    (P : Matrix ι ι ℝ) (hP : P ∈ rowStochastic ℝ ι)
    (hirr : P.IsIrreducible) (hap : Aperiodic P) :
    ∃ π : ι → ℝ, (∀ j, 0 ≤ π j) ∧ ∑ j, π j = 1 ∧ vecMul π P = π ∧
      (∀ i j, Tendsto (fun n : ℕ => (P ^ n) i j) atTop (𝓝 (π j))) ∧
      ∃ r : ℕ, 0 < r ∧ (∀ i j, 0 < (P ^ r) i j) ∧
        ∀ n : ℕ, ∀ i : ι, tvDist ((P ^ n) i) π ≤
          (1 - ∑ j, univ.inf' univ_nonempty (fun i' => (P ^ r) i' j)) ^ (n / r) := by
  have hnn : ∀ i j, 0 ≤ P i j := fun i j => nonneg_of_mem_rowStochastic hP
  obtain ⟨π, hπ0, hπ1, hπP⟩ := cte_stationary P hP
  obtain ⟨r, hr, hpos⟩ := cte_primitive P hnn hirr hap
  have hc : ∀ j, 0 < univ.inf' univ_nonempty (fun i' => (P ^ r) i' j) := fun j =>
    (Finset.lt_inf'_iff _).2 fun i _ => hpos i j
  set ε := ∑ j, univ.inf' univ_nonempty (fun i' => (P ^ r) i' j) with hε
  have hε0 : 0 < ε := Finset.sum_pos (fun j _ => hc j) univ_nonempty
  have hε1 : ε ≤ 1 := by
    have i0 := Classical.arbitrary ι
    calc ε ≤ ∑ j, (P ^ r) i0 j :=
          Finset.sum_le_sum fun j _ => Finset.inf'_le _ (Finset.mem_univ i0)
      _ = 1 := sum_row_of_mem_rowStochastic (pow_mem hP r) i0
  have hbound : ∀ n i, tvDist ((P ^ n) i) π ≤ (1 - ε) ^ (n / r) := by
    intro n i
    exact cte_doeblin P hP r (fun j => univ.inf' univ_nonempty (fun i' => (P ^ r) i' j) / ε)
      (fun j => div_nonneg (hc j).le hε0.le)
      (by rw [← Finset.sum_div, div_self hε0.ne'])
      ε hε0 hε1
      (fun i j => by
        rw [mul_div_cancel₀ _ hε0.ne']; exact Finset.inf'_le _ (Finset.mem_univ i))
      π hπ0 hπ1 hπP n i
  have hlim : Tendsto (fun n : ℕ => 2 * (1 - ε) ^ (n / r)) atTop (𝓝 0) := by
    have := (tendsto_pow_atTop_nhds_zero_of_lt_one (by linarith) (by linarith : 1 - ε < 1)).comp
      (Nat.tendsto_div_const_atTop hr.ne')
    simpa using this.const_mul 2
  refine ⟨π, hπ0, hπ1, hπP, fun i j => ?_, r, hr, hpos, hbound⟩
  rw [tendsto_iff_norm_sub_tendsto_zero]
  refine squeeze_zero (fun n => norm_nonneg _) (fun n => ?_) hlim
  have h1 : |(P ^ n) i j - π j| ≤ ∑ j', |(P ^ n) i j' - π j'| :=
    Finset.single_le_sum (f := fun j' => |(P ^ n) i j' - π j'|) (fun _ _ => abs_nonneg _)
      (Finset.mem_univ j)
  have h2 := hbound n i
  unfold tvDist at h2
  rw [Real.norm_eq_abs]
  linarith

/-- Doeblin's bound. If for some block of `r` days every row of `P ^ r` gives each state `j` at
least `ε * ν j`, for one fixed law `ν` and a number `0 < ε ≤ 1`, then from every start `i` the
total variation distance between day `n`'s forecast and the stationary law `π` is at most
`(1 - ε) ^ ⌊n / r⌋`. -/
theorem doeblin_bound
    {ι : Type*} [Fintype ι] [DecidableEq ι]
    (P : Matrix ι ι ℝ) (hP : P ∈ rowStochastic ℝ ι)
    (r : ℕ) (ν : ι → ℝ) (hν0 : ∀ j, 0 ≤ ν j) (hν1 : ∑ j, ν j = 1)
    (ε : ℝ) (hε0 : 0 < ε) (hε1 : ε ≤ 1)
    (hmin : ∀ i j, ε * ν j ≤ (P ^ r) i j)
    (π : ι → ℝ) (hπ0 : ∀ j, 0 ≤ π j) (hπ1 : ∑ j, π j = 1) (hπP : vecMul π P = π) :
    ∀ n : ℕ, ∀ i : ι, tvDist ((P ^ n) i) π ≤ (1 - ε) ^ (n / r) := by
  intro n i
  exact cte_doeblin P hP r ν hν0 hν1 ε hε0 hε1 hmin π hπ0 hπ1 hπP n i

/-- Total variation is the largest gap on an event: for two laws `μ` and `ν` on finitely many
states, no event `B` shows a gap `μ(B) - ν(B)` above `TV(μ, ν)`, and some event `A` (the states
where `μ` gives more than `ν`) shows exactly that gap. -/
theorem tvDist_eq_largest_event_gap
    {ι : Type*} [Fintype ι] (μ ν : ι → ℝ)
    (hμ0 : ∀ j, 0 ≤ μ j) (hμ1 : ∑ j, μ j = 1) (hν0 : ∀ j, 0 ≤ ν j) (hν1 : ∑ j, ν j = 1) :
    (∀ B : Finset ι, ∑ j ∈ B, (μ j - ν j) ≤ tvDist μ ν) ∧
      ∃ A : Finset ι, ∑ j ∈ A, (μ j - ν j) = tvDist μ ν := by
  exact cte_gap μ ν hμ0 hμ1 hν0 hν1

/-! ### The card's worked numbers, in exact whole numbers

The weather table in tenths: rows sunny, cloudy, rainy. -/

/-- The weather table times 10. -/
def W10 : Matrix (Fin 3) (Fin 3) ℤ := !![8, 1, 1; 5, 4, 1; 1, 3, 6]

/-- The stationary law 0.6, 0.2, 0.2, in fifths. -/
def pi5 : Fin 3 → ℤ := ![3, 1, 1]

-- The table is stochastic: every row adds to 10 tenths.
example : ∀ i : Fin 3, ∑ j, W10 i j = 10 := by decide
-- π P = π: 0.6 × 0.8 + 0.2 × 0.5 + 0.2 × 0.1 = 0.6, and likewise for cloudy and rainy.
example : ∀ j : Fin 3, ∑ i, pi5 i * W10 i j = 10 * pi5 j := by decide
-- The common share: every column's smallest entry is 1 tenth, so ε = 3 tenths = 0.3.
example : ∑ j : Fin 3, univ.inf' univ_nonempty (fun i => W10 i j) = 3 := by decide
-- Trace 1.8 and determinant 0.15 (in tenths: 18, and 150 thousandths).
example : W10.trace = 18 := by decide
example : W10.det = 150 := by simp [W10, Matrix.det_fin_three]
-- The other two eigenvalues 0.5 and 0.3: they add to 0.8 and multiply to 0.15.
example : (5 : ℤ) + 3 = 18 - 10 ∧ (5 : ℤ) * 3 * 10 = 150 := by norm_num
-- From a rainy start, the chance of sun on days 1, 2, 3, 7: 0.1, 0.29, 0.427, 0.5877187.
example : (W10 ^ 1) 2 0 = 1 := by decide
example : (W10 ^ 2) 2 0 = 29 := by decide
example : (W10 ^ 3) 2 0 = 427 := by decide
example : (W10 ^ 7) 2 0 = 5877187 := by decide
-- The by-hand formula 0.6 - 1.6 × 0.5^n + 0.3^n gives the same day-7 value 0.5877187.
example : (3 / 5 : ℚ) - 8 / 5 * (1 / 2) ^ 7 + (3 / 10) ^ 7 = 5877187 / 10 ^ 7 := by norm_num
-- Day 8 is the first day every start is within 0.01 of the mix: on day 7 the rainy start is
-- 0.0122813 away (more than 0.01), and on day 8 every start is within 0.01.
example : 100 * ∑ j, |5 * (W10 ^ 7) 2 j - pi5 j * 10 ^ 7| > 2 * 5 * 10 ^ 7 := by decide
example : ∀ i : Fin 3, 100 * ∑ j, |5 * (W10 ^ 8) i j - pi5 j * 10 ^ 8| ≤ 2 * 5 * 10 ^ 8 := by
  decide
-- The guarantee on day 7: 0.7^7 = 0.0823543, above the exact distance 0.0122813.
example : (7 / 10 : ℚ) ^ 7 = 823543 / 10 ^ 7 ∧ (1228130 : ℚ) / 10 ^ 8 ≤ 823543 / 10 ^ 7 := by
  norm_num

/-! ### What breaks -/

/-- Weather forced round sunny → cloudy → rainy (period 3). -/
def cyc : Matrix (Fin 3) (Fin 3) ℤ := !![0, 1, 0; 0, 0, 1; 1, 0, 0]

-- On day 30 the sunny start is certainly sunny again, so its distance from one third each is
-- (2/3 + 1/3 + 1/3) / 2 = 2/3; on day 29 it is certainly rainy, again distance 2/3.
set_option maxRecDepth 20000 in
example : cyc ^ 30 = 1 := by decide
set_option maxRecDepth 20000 in
example : (cyc ^ 29) 0 = ![0, 0, 1] := by decide
-- Two climates: rain never ends, and sun and cloud never bring it. The sunny start gives rain
-- chance 0 on day 30, the rainy start gives it chance 1: distance 1.
def twoClimates : Matrix (Fin 3) (Fin 3) ℤ := !![8, 2, 0; 5, 5, 0; 0, 0, 10]
set_option maxRecDepth 20000 in
example : (twoClimates ^ 30) 0 2 = 0 ∧ (twoClimates ^ 30) 2 2 = 10 ^ 30 := by decide

/-! ### The town of stationary distributions -/

/-- Rows 0.6, 0.3, 0.1; 0.4, 0.4, 0.2; 0.4, 0.3, 0.3. -/
def town : Matrix (Fin 3) (Fin 3) ℚ := !![6/10, 3/10, 1/10; 4/10, 4/10, 2/10; 4/10, 3/10, 3/10]

-- Column minima 0.4, 0.3, 0.1 give ε = 0.8, and the mix 1/2, 1/3, 1/6 is stationary.
example : (4 / 10 : ℚ) + 3 / 10 + 1 / 10 = 8 / 10 := by norm_num
example : vecMul ![1/2, 1/3, 1/6] town = ![1/2, 1/3, 1/6] := by
  ext j; fin_cases j <;> simp [town, vecMul, dotProduct, Fin.sum_univ_three] <;> norm_num

#print axioms irreducible_aperiodic_chain_converges_to_equilibrium
#print axioms doeblin_bound
#print axioms tvDist_eq_largest_event_gap
