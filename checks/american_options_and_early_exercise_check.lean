-- American options: on a binomial tree the backward walk equals the best stopping rule, and the American put and call obey the parity band and the premium cap.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Order.Bounds.Basic
import Mathlib.Data.Fintype.Pi
import Mathlib.Algebra.BigOperators.Group.Finset.Basic

open Finset

namespace AmericanOption

/-- Acme's price at the tree node on date `n` reached after `j` rises: `S * u ^ (2 j - n)`
(each fall divides by `u`, the Cox–Ross–Rubinstein down factor `1 / u`). -/
noncomputable def node (S u : ℝ) (n j : ℕ) : ℝ := S * u ^ ((2 * j : ℤ) - n)

/-- The backward walk with `k` steps left, at the node on date `n` with `j` rises:
the larger of the payoff now and the discounted average of the two values one step ahead. -/
noncomputable def walk (g : ℝ → ℝ) (S u p D : ℝ) : ℕ → ℕ → ℕ → ℝ
  | 0, n, j => g (node S u n j)
  | k + 1, n, j => max (g (node S u n j))
      (D * (p * walk g S u p D k (n + 1) (j + 1) + (1 - p) * walk g S u p D k (n + 1) j))

/-- The same walk with the max dropped: the European option on the same tree. -/
noncomputable def euro (g : ℝ → ℝ) (S u p D : ℝ) : ℕ → ℕ → ℕ → ℝ
  | 0, n, j => g (node S u n j)
  | k + 1, n, j =>
      D * (p * euro g S u p D k (n + 1) (j + 1) + (1 - p) * euro g S u p D k (n + 1) j)

/-- Number of rises among the first `n` moves of a path of `N` up (`true`) or down moves. -/
def ups {N : ℕ} (ω : Fin N → Bool) (n : ℕ) : ℕ :=
  (univ.filter (fun i : Fin N => i.val < n ∧ ω i = true)).card

/-- Risk-neutral probability of one whole path: `p` per rise, `1 - p` per fall. -/
noncomputable def pathProb (p : ℝ) {N : ℕ} (ω : Fin N → Bool) : ℝ :=
  p ^ ups ω N * (1 - p) ^ (N - ups ω N)

/-- A stopping rule on an `N`-step tree: it picks a date `0 … N` for each path, and whether it
stops on date `n` depends only on the first `n` moves (it looks back, never forward). -/
def IsStoppingRule (N : ℕ) (τ : (Fin N → Bool) → ℕ) : Prop :=
  (∀ ω, τ ω ≤ N) ∧
    ∀ (n : ℕ) (ω ω' : Fin N → Bool), (∀ i : Fin N, i.val < n → ω i = ω' i) → (τ ω = n ↔ τ ω' = n)

/-- The price of a stopping rule: the risk-neutral average of its payoff,
discounted by `D` per step back to today. -/
noncomputable def ruleValue (g : ℝ → ℝ) (S u p D : ℝ) (N : ℕ) (τ : (Fin N → Bool) → ℕ) : ℝ :=
  ∑ ω : Fin N → Bool, pathProb p ω * D ^ τ ω * g (node S u (τ ω) (ups ω (τ ω)))

/-- Up factor of the Cox–Ross–Rubinstein tree: `u = e^{σ √Δt}` with `Δt = T / N`. -/
noncomputable def crrU (σ T : ℝ) (N : ℕ) : ℝ := Real.exp (σ * Real.sqrt (T / N))

/-- Risk-neutral weight on up: `p = (e^{(r - q) Δt} - 1/u) / (u - 1/u)`. -/
noncomputable def crrP (r q σ T : ℝ) (N : ℕ) : ℝ :=
  (Real.exp ((r - q) * (T / N)) - 1 / crrU σ T N) / (crrU σ T N - 1 / crrU σ T N)

/-- One-step discount `e^{-r Δt}`. -/
noncomputable def crrD (r T : ℝ) (N : ℕ) : ℝ := Real.exp (-(r * (T / N)))

theorem ups_zero {N : ℕ} (ω : Fin N → Bool) : ups ω 0 = 0 := by
  simp [ups]

theorem ups_le {N : ℕ} (ω : Fin N → Bool) : ups ω N ≤ N := by
  unfold ups
  exact (card_filter_le _ _).trans (by simp)

theorem ups_cons_succ {k : ℕ} (b : Bool) (ω : Fin k → Bool) (m : ℕ) :
    ups (Fin.cons b ω : Fin (k + 1) → Bool) (m + 1) = (if b then 1 else 0) + ups ω m := by
  unfold ups
  rw [card_filter, card_filter, Fin.sum_univ_succ]
  simp [Fin.cons_zero, Fin.cons_succ]

theorem pathProb_cons (p : ℝ) {k : ℕ} (b : Bool) (ω : Fin k → Bool) :
    pathProb p (Fin.cons b ω : Fin (k + 1) → Bool) = (if b then p else 1 - p) * pathProb p ω := by
  unfold pathProb
  rw [ups_cons_succ]
  have h := ups_le ω
  cases b
  · simp only [Bool.false_eq_true, ite_false, zero_add]
    rw [show k + 1 - ups ω k = (k - ups ω k) + 1 by omega, pow_succ]
    ring
  · simp only [ite_true]
    rw [show k + 1 - (1 + ups ω k) = k - ups ω k by omega, add_comm 1, pow_succ]
    ring

theorem sum_cons {k : ℕ} (F : (Fin (k + 1) → Bool) → ℝ) :
    ∑ ω, F ω = ∑ ω : Fin k → Bool, F (Fin.cons true ω) + ∑ ω : Fin k → Bool, F (Fin.cons false ω) := by
  rw [← (Fin.consEquiv (fun _ => Bool)).sum_comp, Fintype.sum_prod_type, Fintype.sum_bool]
  simp

theorem sum_pathProb (p : ℝ) : ∀ k : ℕ, ∑ ω : Fin k → Bool, pathProb p ω = 1
  | 0 => by simp [pathProb, ups]
  | k + 1 => by
    rw [sum_cons]
    simp only [pathProb_cons, ite_true, Bool.false_eq_true, ite_false, ← mul_sum, sum_pathProb p k]
    ring

noncomputable def subValue (g : ℝ → ℝ) (S u p D : ℝ) (k n j : ℕ) (τ : (Fin k → Bool) → ℕ) : ℝ :=
  ∑ ω : Fin k → Bool, pathProb p ω * D ^ τ ω * g (node S u (n + τ ω) (j + ups ω (τ ω)))

theorem rule_zero_or_pos {k : ℕ} {τ : (Fin k → Bool) → ℕ} (h : IsStoppingRule k τ) :
    (∀ ω, τ ω = 0) ∨ (∀ ω, 0 < τ ω) := by
  by_cases h0 : τ (fun _ => false) = 0
  · left
    intro ω
    exact (h.2 0 ω (fun _ => false) (fun i hi => absurd hi (Nat.not_lt_zero _))).2 h0
  · right
    intro ω
    rw [Nat.pos_iff_ne_zero]
    intro hω
    exact h0 ((h.2 0 ω (fun _ => false) (fun i hi => absurd hi (Nat.not_lt_zero _))).1 hω)

theorem subValue_of_zero (g : ℝ → ℝ) (S u p D : ℝ) {k : ℕ} (n j : ℕ) {τ : (Fin k → Bool) → ℕ}
    (hτ : ∀ ω, τ ω = 0) : subValue g S u p D k n j τ = g (node S u n j) := by
  simp [subValue, hτ, ups_zero, ← sum_mul, sum_pathProb]

theorem sub_rule {k : ℕ} {τ : (Fin (k + 1) → Bool) → ℕ} (h : IsStoppingRule (k + 1) τ)
    (hpos : ∀ ω, 0 < τ ω) (b : Bool) : IsStoppingRule k (fun ω => τ (Fin.cons b ω) - 1) := by
  constructor
  · intro ω
    have := h.1 (Fin.cons b ω)
    show τ (Fin.cons b ω) - 1 ≤ k
    omega
  · intro m ω ω' hag
    have key := h.2 (m + 1) (Fin.cons b ω) (Fin.cons b ω') (by
      intro i hi
      cases i using Fin.cases with
      | zero => simp
      | succ i =>
        simp only [Fin.cons_succ]
        exact hag i (by simp at hi; omega))
    have p1 := hpos (Fin.cons b ω)
    have p2 := hpos (Fin.cons b ω')
    simp only
    omega

theorem subValue_succ (g : ℝ → ℝ) (S u p D : ℝ) {k : ℕ} (n j : ℕ) {τ : (Fin (k + 1) → Bool) → ℕ}
    (hpos : ∀ ω, 0 < τ ω) :
    subValue g S u p D (k + 1) n j τ =
      D * (p * subValue g S u p D k (n + 1) (j + 1) (fun ω => τ (Fin.cons true ω) - 1) +
        (1 - p) * subValue g S u p D k (n + 1) j (fun ω => τ (Fin.cons false ω) - 1)) := by
  unfold subValue
  rw [sum_cons, mul_sum, mul_sum, ← sum_add_distrib, ← sum_add_distrib, mul_sum]
  refine sum_congr rfl (fun ω _ => ?_)
  obtain ⟨m, hm⟩ : ∃ m, τ (Fin.cons true ω) = m + 1 :=
    ⟨_, (Nat.succ_pred_eq_of_pos (hpos _)).symm⟩
  obtain ⟨m', hm'⟩ : ∃ m, τ (Fin.cons false ω) = m + 1 :=
    ⟨_, (Nat.succ_pred_eq_of_pos (hpos _)).symm⟩
  beta_reduce
  rw [hm, hm', Nat.add_sub_cancel, Nat.add_sub_cancel, ups_cons_succ, ups_cons_succ,
    pathProb_cons, pathProb_cons]
  simp only [ite_true, Bool.false_eq_true, ite_false]
  rw [show n + (m + 1) = n + 1 + m by omega, show j + (1 + ups ω m) = j + 1 + ups ω m by omega,
    show n + (m' + 1) = n + 1 + m' by omega, zero_add, pow_succ, pow_succ]
  ring

/-- Wait one step, then follow `τ1` after a rise or `τ0` after a fall. -/
def comb {k : ℕ} (τ1 τ0 : (Fin k → Bool) → ℕ) (ω : Fin (k + 1) → Bool) : ℕ :=
  (if ω 0 then τ1 (Fin.tail ω) else τ0 (Fin.tail ω)) + 1

theorem comb_rule {k : ℕ} {τ1 τ0 : (Fin k → Bool) → ℕ} (h1 : IsStoppingRule k τ1)
    (h0 : IsStoppingRule k τ0) : IsStoppingRule (k + 1) (comb τ1 τ0) := by
  constructor
  · intro ω
    unfold comb
    split
    · have := h1.1 (Fin.tail ω); omega
    · have := h0.1 (Fin.tail ω); omega
  · intro m ω ω' hag
    cases m with
    | zero => simp [comb]
    | succ m =>
      have e0 : ω 0 = ω' 0 := hag 0 (by simp)
      have ht : ∀ i : Fin k, i.val < m → Fin.tail ω i = Fin.tail ω' i :=
        fun i hi => hag i.succ (by simp; omega)
      simp only [comb, e0, Nat.add_right_cancel_iff]
      split
      · exact h1.2 m _ _ ht
      · exact h0.2 m _ _ ht

theorem zero_rule (k : ℕ) : IsStoppingRule k (fun _ => 0) :=
  ⟨fun _ => Nat.zero_le _, fun _ _ _ _ => Iff.rfl⟩

theorem walk_ge (g : ℝ → ℝ) (S u p D : ℝ) (hD : 0 ≤ D) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) :
    ∀ (k n j : ℕ) (τ : (Fin k → Bool) → ℕ), IsStoppingRule k τ →
      subValue g S u p D k n j τ ≤ walk g S u p D k n j
  | 0, n, j, τ, h => by
    rw [subValue_of_zero g S u p D n j (fun ω => by have := h.1 ω; omega)]
    rfl
  | k + 1, n, j, τ, h => by
    rw [walk]
    rcases rule_zero_or_pos h with h0 | hpos
    · rw [subValue_of_zero g S u p D n j h0]
      exact le_max_left _ _
    · rw [subValue_succ g S u p D n j hpos]
      refine le_max_of_le_right (mul_le_mul_of_nonneg_left (add_le_add ?_ ?_) hD)
      · exact mul_le_mul_of_nonneg_left
          (walk_ge g S u p D hD hp0 hp1 k _ _ _ (sub_rule h hpos true)) hp0
      · exact mul_le_mul_of_nonneg_left
          (walk_ge g S u p D hD hp0 hp1 k _ _ _ (sub_rule h hpos false)) (by linarith)

theorem walk_attained (g : ℝ → ℝ) (S u p D : ℝ) :
    ∀ (k n j : ℕ), ∃ τ : (Fin k → Bool) → ℕ, IsStoppingRule k τ ∧
      subValue g S u p D k n j τ = walk g S u p D k n j
  | 0, n, j => ⟨fun _ => 0, zero_rule 0, by rw [subValue_of_zero g S u p D n j (fun _ => rfl)]; rfl⟩
  | k + 1, n, j => by
    obtain ⟨τ1, h1, e1⟩ := walk_attained g S u p D k (n + 1) (j + 1)
    obtain ⟨τ0, h0, e0⟩ := walk_attained g S u p D k (n + 1) j
    rw [walk]
    by_cases hc : D * (p * walk g S u p D k (n + 1) (j + 1) + (1 - p) * walk g S u p D k (n + 1) j)
        ≤ g (node S u n j)
    · exact ⟨fun _ => 0, zero_rule _, by
        rw [subValue_of_zero g S u p D n j (fun _ => rfl), max_eq_left hc]⟩
    · refine ⟨comb τ1 τ0, comb_rule h1 h0, ?_⟩
      rw [subValue_succ g S u p D (τ := comb τ1 τ0) n j (fun ω => Nat.succ_pos _), max_eq_right (le_of_not_ge hc)]
      have c1 : (fun ω => comb τ1 τ0 (Fin.cons true ω) - 1) = τ1 := by
        funext ω; simp [comb]
      have c0 : (fun ω => comb τ1 τ0 (Fin.cons false ω) - 1) = τ0 := by
        funext ω; simp [comb]
      rw [c1, c0, e1, e0]

theorem ruleValue_eq (g : ℝ → ℝ) (S u p D : ℝ) (N : ℕ) (τ : (Fin N → Bool) → ℕ) :
    ruleValue g S u p D N τ = subValue g S u p D N 0 0 τ := by
  simp [ruleValue, subValue]

theorem node_up (S : ℝ) {u : ℝ} (hu : u ≠ 0) (n j : ℕ) :
    node S u (n + 1) (j + 1) = node S u n j * u := by
  unfold node
  rw [show (2 * ((j + 1 : ℕ) : ℤ) - ((n + 1 : ℕ) : ℤ)) = (2 * (j : ℤ) - n) + 1 by push_cast; ring,
    zpow_add₀ hu, zpow_one, mul_assoc]

theorem node_down (S : ℝ) {u : ℝ} (hu : u ≠ 0) (n j : ℕ) :
    node S u (n + 1) j = node S u n j * u⁻¹ := by
  unfold node
  rw [show (2 * (j : ℤ) - ((n + 1 : ℕ) : ℤ)) = (2 * (j : ℤ) - n) + (-1) by push_cast; ring,
    zpow_add₀ hu, zpow_neg_one, mul_assoc]

theorem node_nonneg {S u : ℝ} (hS : 0 ≤ S) (hu : 0 < u) (n j : ℕ) : 0 ≤ node S u n j :=
  mul_nonneg hS (zpow_nonneg hu.le _)

theorem node_exp {S u p D δ : ℝ} (hu : u ≠ 0) (hE : D * (p * u + (1 - p) * u⁻¹) = δ) (n j : ℕ) :
    D * (p * node S u (n + 1) (j + 1) + (1 - p) * node S u (n + 1) j) = δ * node S u n j := by
  rw [node_up S hu, node_down S hu, ← hE]
  ring

theorem walk_succ (g : ℝ → ℝ) (S u p D : ℝ) (k n j : ℕ) :
    walk g S u p D (k + 1) n j = max (g (node S u n j))
      (D * (p * walk g S u p D k (n + 1) (j + 1) + (1 - p) * walk g S u p D k (n + 1) j)) := by
  rw [walk]

theorem euro_succ (g : ℝ → ℝ) (S u p D : ℝ) (k n j : ℕ) :
    euro g S u p D (k + 1) n j =
      D * (p * euro g S u p D k (n + 1) (j + 1) + (1 - p) * euro g S u p D k (n + 1) j) := by
  rw [euro]

theorem walk_ge_pay (g : ℝ → ℝ) (S u p D : ℝ) (k n j : ℕ) :
    g (node S u n j) ≤ walk g S u p D k n j := by
  cases k with
  | zero => exact le_refl _
  | succ k => rw [walk]; exact le_max_left _ _

theorem walk_cont (g : ℝ → ℝ) (S u p D : ℝ) (k n j : ℕ) :
    D * (p * walk g S u p D k (n + 1) (j + 1) + (1 - p) * walk g S u p D k (n + 1) j)
      ≤ walk g S u p D (k + 1) n j := by
  rw [walk_succ]
  exact le_max_right _ _

theorem parity_upper (S K u p D δ : ℝ) (hu : 0 < u) (hp0 : 0 ≤ p) (hp1 : p ≤ 1)
    (hD0 : 0 ≤ D) (hD1 : D ≤ 1) (hδ1 : δ ≤ 1)
    (hE : D * (p * u + (1 - p) * u⁻¹) = δ) (hS : 0 ≤ S) (hK : 0 ≤ K) :
    ∀ k n j : ℕ, walk (fun s => max (s - K) 0) S u p D k n j
        - walk (fun s => max (K - s) 0) S u p D k n j ≤ node S u n j - K * D ^ k
  | 0, n, j => by
    simp only [walk, pow_zero, mul_one]
    rcases le_total (node S u n j) K with h | h
    · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; linarith
    · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; linarith
  | k + 1, n, j => by
    have ih1 := parity_upper S K u p D δ hu hp0 hp1 hD0 hD1 hδ1 hE hS hK k (n + 1) (j + 1)
    have ih0 := parity_upper S K u p D δ hu hp0 hp1 hD0 hD1 hδ1 hE hS hK k (n + 1) j
    have hE' := node_exp (S := S) hu.ne' hE n j
    have hs := node_nonneg hS hu n j
    have hPpay := walk_ge_pay (fun s => max (K - s) 0) S u p D (k + 1) n j
    have hPcont := walk_cont (fun s => max (K - s) 0) S u p D k n j
    have hm1 := le_max_left (K - node S u n j) 0
    have hm2 := le_max_right (K - node S u n j) 0
    have hDk : K * (D ^ k * D) ≤ K := mul_le_of_le_one_right hK (by
      rw [← pow_succ]; exact pow_le_one₀ hD0 hD1)
    have hδs : δ * node S u n j ≤ node S u n j := mul_le_of_le_one_left hs hδ1
    have h1 : D * p * (walk (fun s => max (s - K) 0) S u p D k (n + 1) (j + 1)
        - walk (fun s => max (K - s) 0) S u p D k (n + 1) (j + 1)
        - (node S u (n + 1) (j + 1) - K * D ^ k)) ≤ 0 :=
      mul_nonpos_of_nonneg_of_nonpos (mul_nonneg hD0 hp0) (by linarith)
    have h0 : D * (1 - p) * (walk (fun s => max (s - K) 0) S u p D k (n + 1) j
        - walk (fun s => max (K - s) 0) S u p D k (n + 1) j
        - (node S u (n + 1) j - K * D ^ k)) ≤ 0 :=
      mul_nonpos_of_nonneg_of_nonpos (mul_nonneg hD0 (by linarith)) (by linarith)
    rw [walk_succ (fun s => max (s - K) 0), pow_succ]
    have key : max (max (node S u n j - K) 0)
        (D * (p * walk (fun s => max (s - K) 0) S u p D k (n + 1) (j + 1)
          + (1 - p) * walk (fun s => max (s - K) 0) S u p D k (n + 1) j))
        ≤ walk (fun s => max (K - s) 0) S u p D (k + 1) n j + node S u n j - K * (D ^ k * D) :=
      max_le (max_le (by linarith) (by linarith)) (by linarith)
    linarith


theorem parity_lower (S K u p D δ : ℝ) (hu : 0 < u) (hp0 : 0 ≤ p) (hp1 : p ≤ 1)
    (hD0 : 0 ≤ D) (hD1 : D ≤ 1) (hδ0 : 0 ≤ δ) (hδ1 : δ ≤ 1)
    (hE : D * (p * u + (1 - p) * u⁻¹) = δ) (hS : 0 ≤ S) (hK : 0 ≤ K) :
    ∀ k n j : ℕ, node S u n j * δ ^ k - K ≤ walk (fun s => max (s - K) 0) S u p D k n j
        - walk (fun s => max (K - s) 0) S u p D k n j
  | 0, n, j => by
    simp only [walk, pow_zero, mul_one]
    rcases le_total (node S u n j) K with h | h
    · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; linarith
    · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; linarith
  | k + 1, n, j => by
    have ih1 := parity_lower S K u p D δ hu hp0 hp1 hD0 hD1 hδ0 hδ1 hE hS hK k (n + 1) (j + 1)
    have ih0 := parity_lower S K u p D δ hu hp0 hp1 hD0 hD1 hδ0 hδ1 hE hS hK k (n + 1) j
    have hE' := node_exp (S := S) hu.ne' hE n j
    have hE'' : D * (p * (node S u (n + 1) (j + 1) * δ ^ k) + (1 - p) * (node S u (n + 1) j * δ ^ k))
        = δ ^ k * δ * node S u n j := by linear_combination δ ^ k * hE'
    have hs := node_nonneg hS hu n j
    have hCpay := walk_ge_pay (fun s => max (s - K) 0) S u p D (k + 1) n j
    have hCcont := walk_cont (fun s => max (s - K) 0) S u p D k n j
    have hm1 := le_max_left (node S u n j - K) 0
    have hm2 := le_max_right (node S u n j - K) 0
    have hKD : K * D ≤ K := mul_le_of_le_one_right hK hD1
    have hδs : δ ^ k * δ * node S u n j ≤ node S u n j := mul_le_of_le_one_left hs (by
      rw [← pow_succ]; exact pow_le_one₀ hδ0 hδ1)
    have h1 : D * p * (node S u (n + 1) (j + 1) * δ ^ k - K
        - (walk (fun s => max (s - K) 0) S u p D k (n + 1) (j + 1)
        - walk (fun s => max (K - s) 0) S u p D k (n + 1) (j + 1))) ≤ 0 :=
      mul_nonpos_of_nonneg_of_nonpos (mul_nonneg hD0 hp0) (by linarith)
    have h0 : D * (1 - p) * (node S u (n + 1) j * δ ^ k - K
        - (walk (fun s => max (s - K) 0) S u p D k (n + 1) j
        - walk (fun s => max (K - s) 0) S u p D k (n + 1) j)) ≤ 0 :=
      mul_nonpos_of_nonneg_of_nonpos (mul_nonneg hD0 (by linarith)) (by linarith)
    rw [walk_succ (fun s => max (K - s) 0), pow_succ]
    have key : max (max (K - node S u n j) 0)
        (D * (p * walk (fun s => max (K - s) 0) S u p D k (n + 1) (j + 1)
          + (1 - p) * walk (fun s => max (K - s) 0) S u p D k (n + 1) j))
        ≤ walk (fun s => max (s - K) 0) S u p D (k + 1) n j + K - node S u n j * (δ ^ k * δ) :=
      max_le (max_le (by linarith) (by linarith)) (by linarith)
    linarith

theorem euro_le_walk (g : ℝ → ℝ) (S u p D : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) (hD0 : 0 ≤ D) :
    ∀ k n j : ℕ, euro g S u p D k n j ≤ walk g S u p D k n j
  | 0, n, j => le_refl _
  | k + 1, n, j => by
    rw [euro_succ, walk_succ]
    exact le_max_of_le_right (mul_le_mul_of_nonneg_left (add_le_add
      (mul_le_mul_of_nonneg_left (euro_le_walk g S u p D hp0 hp1 hD0 k _ _) hp0)
      (mul_le_mul_of_nonneg_left (euro_le_walk g S u p D hp0 hp1 hD0 k _ _) (by linarith))) hD0)

theorem euro_nonneg (g : ℝ → ℝ) (hg : ∀ s, 0 ≤ g s) (S u p D : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1)
    (hD0 : 0 ≤ D) : ∀ k n j : ℕ, 0 ≤ euro g S u p D k n j
  | 0, n, j => hg _
  | k + 1, n, j => by
    rw [euro_succ]
    exact mul_nonneg hD0 (add_nonneg
      (mul_nonneg hp0 (euro_nonneg g hg S u p D hp0 hp1 hD0 k _ _))
      (mul_nonneg (by linarith) (euro_nonneg g hg S u p D hp0 hp1 hD0 k _ _)))

theorem euro_put_lower (S K u p D δ : ℝ) (hu : 0 < u) (hp0 : 0 ≤ p) (hp1 : p ≤ 1)
    (hD0 : 0 ≤ D) (hE : D * (p * u + (1 - p) * u⁻¹) = δ) :
    ∀ k n j : ℕ, K * D ^ k - node S u n j * δ ^ k ≤ euro (fun s => max (K - s) 0) S u p D k n j
  | 0, n, j => by
    simp only [euro, pow_zero, mul_one]
    exact le_max_left _ _
  | k + 1, n, j => by
    have ih1 := euro_put_lower S K u p D δ hu hp0 hp1 hD0 hE k (n + 1) (j + 1)
    have ih0 := euro_put_lower S K u p D δ hu hp0 hp1 hD0 hE k (n + 1) j
    have hE' := node_exp (S := S) hu.ne' hE n j
    have hE'' : D * (p * (node S u (n + 1) (j + 1) * δ ^ k) + (1 - p) * (node S u (n + 1) j * δ ^ k))
        = δ ^ k * δ * node S u n j := by linear_combination δ ^ k * hE'
    have h1 : D * p * (K * D ^ k - node S u (n + 1) (j + 1) * δ ^ k
        - euro (fun s => max (K - s) 0) S u p D k (n + 1) (j + 1)) ≤ 0 :=
      mul_nonpos_of_nonneg_of_nonpos (mul_nonneg hD0 hp0) (by linarith)
    have h0 : D * (1 - p) * (K * D ^ k - node S u (n + 1) j * δ ^ k
        - euro (fun s => max (K - s) 0) S u p D k (n + 1) j) ≤ 0 :=
      mul_nonpos_of_nonneg_of_nonpos (mul_nonneg hD0 (by linarith)) (by linarith)
    rw [euro_succ, pow_succ, pow_succ]
    linarith

theorem premium_upper (S K u p D δ : ℝ) (hu : 0 < u) (hp0 : 0 ≤ p) (hp1 : p ≤ 1)
    (hD0 : 0 ≤ D) (hD1 : D ≤ 1) (hδ0 : 0 ≤ δ) (hδ1 : δ ≤ 1)
    (hE : D * (p * u + (1 - p) * u⁻¹) = δ) (hS : 0 ≤ S) (hK : 0 ≤ K) :
    ∀ k n j : ℕ, walk (fun s => max (K - s) 0) S u p D k n j
        - euro (fun s => max (K - s) 0) S u p D k n j ≤ K * (1 - D ^ k)
  | 0, n, j => by simp [walk, euro]
  | k + 1, n, j => by
    have ih1 := premium_upper S K u p D δ hu hp0 hp1 hD0 hD1 hδ0 hδ1 hE hS hK k (n + 1) (j + 1)
    have ih0 := premium_upper S K u p D δ hu hp0 hp1 hD0 hD1 hδ0 hδ1 hE hS hK k (n + 1) j
    have hs := node_nonneg hS hu n j
    have hEl := euro_put_lower S K u p D δ hu hp0 hp1 hD0 hE (k + 1) n j
    have hEn := euro_nonneg (fun s => max (K - s) 0) (fun s => le_max_right _ _) S u p D hp0 hp1
      hD0 (k + 1) n j
    have hEq := euro_succ (fun s => max (K - s) 0) S u p D k n j
    have hKD : K * D ≤ K := mul_le_of_le_one_right hK hD1
    have hDk : K * D ^ (k + 1) ≤ K := mul_le_of_le_one_right hK (pow_le_one₀ hD0 hD1)
    have hδs : node S u n j * δ ^ (k + 1) ≤ node S u n j :=
      mul_le_of_le_one_right hs (pow_le_one₀ hδ0 hδ1)
    have h1 : D * p * (walk (fun s => max (K - s) 0) S u p D k (n + 1) (j + 1)
        - euro (fun s => max (K - s) 0) S u p D k (n + 1) (j + 1) - K * (1 - D ^ k)) ≤ 0 :=
      mul_nonpos_of_nonneg_of_nonpos (mul_nonneg hD0 hp0) (by linarith)
    have h0 : D * (1 - p) * (walk (fun s => max (K - s) 0) S u p D k (n + 1) j
        - euro (fun s => max (K - s) 0) S u p D k (n + 1) j - K * (1 - D ^ k)) ≤ 0 :=
      mul_nonpos_of_nonneg_of_nonpos (mul_nonneg hD0 (by linarith)) (by linarith)
    have hpow : D ^ (k + 1) = D ^ k * D := pow_succ D k
    have key : max (max (K - node S u n j) 0)
        (D * (p * walk (fun s => max (K - s) 0) S u p D k (n + 1) (j + 1)
          + (1 - p) * walk (fun s => max (K - s) 0) S u p D k (n + 1) j))
        ≤ euro (fun s => max (K - s) 0) S u p D (k + 1) n j + K * (1 - D ^ (k + 1)) := by
      refine max_le (max_le (by linarith) (by linarith)) ?_
      rw [hEq, hpow]
      linarith
    rw [walk_succ (fun s => max (K - s) 0)]
    linarith

theorem crr_facts (r q σ T : ℝ) (N : ℕ) (hr : 0 ≤ r) (hq : 0 ≤ q) (hσ : 0 < σ) (hT : 0 < T)
    (hN : 0 < N) :
    0 < crrU σ T N ∧ 0 ≤ crrD r T N ∧ crrD r T N ≤ 1 ∧
      0 ≤ Real.exp (-(q * (T / N))) ∧ Real.exp (-(q * (T / N))) ≤ 1 ∧
      crrD r T N * (crrP r q σ T N * crrU σ T N + (1 - crrP r q σ T N) * (crrU σ T N)⁻¹)
        = Real.exp (-(q * (T / N))) ∧
      crrD r T N ^ N = Real.exp (-(r * T)) ∧ Real.exp (-(q * (T / N))) ^ N = Real.exp (-(q * T)) := by
  have hNpos : (0 : ℝ) < N := Nat.cast_pos.mpr hN
  have htN : 0 < T / N := div_pos hT hNpos
  have hu1 : 1 < crrU σ T N := by
    unfold crrU
    rw [Real.one_lt_exp_iff]
    exact mul_pos hσ (Real.sqrt_pos.mpr htN)
  have hu0 : 0 < crrU σ T N := by linarith
  have hinv : 1 / crrU σ T N < 1 := (div_lt_one hu0).mpr hu1
  have hne : crrU σ T N - 1 / crrU σ T N ≠ 0 := by linarith
  have hpu : crrP r q σ T N * (crrU σ T N - 1 / crrU σ T N)
      = Real.exp ((r - q) * (T / N)) - 1 / crrU σ T N := by
    unfold crrP
    exact div_mul_cancel₀ _ hne
  refine ⟨hu0, (Real.exp_pos _).le, ?_, (Real.exp_pos _).le, ?_, ?_, ?_, ?_⟩
  · unfold crrD
    rw [Real.exp_le_one_iff]
    nlinarith
  · rw [Real.exp_le_one_iff]
    nlinarith
  · have : crrP r q σ T N * crrU σ T N + (1 - crrP r q σ T N) * (crrU σ T N)⁻¹
        = Real.exp ((r - q) * (T / N)) := by
      rw [← one_div]
      linear_combination hpu
    rw [this]
    unfold crrD
    rw [← Real.exp_add]
    congr 1
    ring
  · unfold crrD
    rw [← Real.exp_nat_mul]
    congr 1
    field_simp
  · rw [← Real.exp_nat_mul]
    congr 1
    field_simp

#print axioms ups_zero
#print axioms ups_le
#print axioms ups_cons_succ
#print axioms pathProb_cons
#print axioms sum_cons
#print axioms sum_pathProb
#print axioms rule_zero_or_pos
#print axioms subValue_of_zero
#print axioms sub_rule
#print axioms subValue_succ
#print axioms comb_rule
#print axioms zero_rule
#print axioms walk_ge
#print axioms walk_attained
#print axioms ruleValue_eq
#print axioms node_up
#print axioms node_down
#print axioms node_nonneg
#print axioms node_exp
#print axioms walk_succ
#print axioms euro_succ
#print axioms walk_ge_pay
#print axioms walk_cont
#print axioms parity_upper
#print axioms parity_lower
#print axioms euro_le_walk
#print axioms euro_nonneg
#print axioms euro_put_lower
#print axioms premium_upper
#print axioms crr_facts

/-- **The backward walk finds the best stopping rule.** On an `N`-step tree, for any payoff `g`,
the value found by comparing "exercise now" with "wait" at every node, working backwards from
expiry, is the price of some stopping rule and no stopping rule is worth more:
the American option's price is the best over all rules. -/
theorem backward_walk_is_best_stopping_rule (N : ℕ) (g : ℝ → ℝ) (S u p r dt : ℝ)
    (hp0 : 0 ≤ p) (hp1 : p ≤ 1) :
    IsGreatest
      {v | ∃ τ, IsStoppingRule N τ ∧ v = ruleValue g S u p (Real.exp (-(r * dt))) N τ}
      (walk g S u p (Real.exp (-(r * dt))) N 0 0) := by
  constructor
  · obtain ⟨τ, hτ, e⟩ := walk_attained g S u p (Real.exp (-(r * dt))) N 0 0
    exact ⟨τ, hτ, by rw [ruleValue_eq, e]⟩
  · rintro v ⟨τ, hτ, rfl⟩
    rw [ruleValue_eq]
    exact walk_ge g S u p _ (Real.exp_pos _).le hp0 hp1 N 0 0 τ hτ

/-- **The parity band.** On the Cox–Ross–Rubinstein tree, with a non-negative rate and dividend
yield, the American call minus the American put lies between `S e^{-qT} - K` and `S - K e^{-rT}`. -/
theorem american_parity_band (S K r q σ T : ℝ) (N : ℕ)
    (hS : 0 ≤ S) (hK : 0 ≤ K) (hr : 0 ≤ r) (hq : 0 ≤ q) (hσ : 0 < σ) (hT : 0 < T) (hN : 0 < N)
    (hp0 : 0 ≤ crrP r q σ T N) (hp1 : crrP r q σ T N ≤ 1) :
    let CA := walk (fun s => max (s - K) 0) S (crrU σ T N) (crrP r q σ T N) (crrD r T N) N 0 0
    let PA := walk (fun s => max (K - s) 0) S (crrU σ T N) (crrP r q σ T N) (crrD r T N) N 0 0
    S * Real.exp (-(q * T)) - K ≤ CA - PA ∧ CA - PA ≤ S - K * Real.exp (-(r * T)) := by
  obtain ⟨hu, hD0, hD1, hδ0, hδ1, hE, hDN, hδN⟩ := crr_facts r q σ T N hr hq hσ hT hN
  have h1 := parity_upper S K _ _ _ _ hu hp0 hp1 hD0 hD1 hδ1 hE hS hK N 0 0
  have h2 := parity_lower S K _ _ _ _ hu hp0 hp1 hD0 hD1 hδ0 hδ1 hE hS hK N 0 0
  have hn : node S (crrU σ T N) 0 0 = S := by simp [node]
  rw [hn, hDN] at h1
  rw [hn, hδN] at h2
  exact ⟨h2, h1⟩

/-- **The early-exercise premium is never negative and at most the interest on the strike.**
On the Cox–Ross–Rubinstein tree, `0 ≤ P_A - P_E ≤ K (1 - e^{-rT})`. -/
theorem early_exercise_premium_bounds (S K r q σ T : ℝ) (N : ℕ)
    (hS : 0 ≤ S) (hK : 0 ≤ K) (hr : 0 ≤ r) (hq : 0 ≤ q) (hσ : 0 < σ) (hT : 0 < T) (hN : 0 < N)
    (hp0 : 0 ≤ crrP r q σ T N) (hp1 : crrP r q σ T N ≤ 1) :
    let PA := walk (fun s => max (K - s) 0) S (crrU σ T N) (crrP r q σ T N) (crrD r T N) N 0 0
    let PE := euro (fun s => max (K - s) 0) S (crrU σ T N) (crrP r q σ T N) (crrD r T N) N 0 0
    0 ≤ PA - PE ∧ PA - PE ≤ K * (1 - Real.exp (-(r * T))) := by
  obtain ⟨hu, hD0, hD1, hδ0, hδ1, hE, hDN, hδN⟩ := crr_facts r q σ T N hr hq hσ hT hN
  have h1 := euro_le_walk (fun s => max (K - s) 0) S (crrU σ T N) (crrP r q σ T N) (crrD r T N)
    hp0 hp1 hD0 N 0 0
  have h2 := premium_upper S K _ _ _ _ hu hp0 hp1 hD0 hD1 hδ0 hδ1 hE hS hK N 0 0
  rw [hDN] at h2
  exact ⟨sub_nonneg.mpr h1, h2⟩

#print axioms backward_walk_is_best_stopping_rule
#print axioms american_parity_band
#print axioms early_exercise_premium_bounds

end AmericanOption
