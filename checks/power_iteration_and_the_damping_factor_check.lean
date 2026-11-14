-- PageRank by power iteration: for any links and any damping factor 0 ≤ α < 1, the damped pass keeps the total score at 1, has exactly one resting list (PageRank), pulls every start towards it by at least α a pass, and its stopping rule certifies the order.
import Mathlib.Data.Real.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Topology.MetricSpace.Contracting
import Mathlib.Tactic

open Finset

namespace PageRankPowerIteration

/-- One pass of damped power iteration on `n` pages. `L i` is the set of pages that page `i`
links to; a page with `L i = ∅` is dangling. Page `j` gets `α` times the score flowing in along
links, `x i / out(i)` from each page `i` linking to it, plus an even share of the score parked on
dangling pages (times `α`) and of the jump mass `1 - α`. -/
noncomputable def pass {n : ℕ} (α : ℝ) (L : Fin n → Finset (Fin n)) (x : Fin n → ℝ) (j : Fin n) : ℝ :=
  α * ∑ i ∈ univ.filter (fun i => j ∈ L i), x i / ((L i).card : ℝ)
    + (α * ∑ i ∈ univ.filter (fun i => L i = ∅), x i + (1 - α)) / (n : ℝ)

/-- A list of scores: non-negative, adding to 1. -/
def IsScoreList {n : ℕ} (x : Fin n → ℝ) : Prop :=
  (∀ j, 0 ≤ x j) ∧ ∑ j, x j = 1

/-- Column-sum identity: every page passes on all of its score. -/
lemma col_sum {n : ℕ} (hn : 0 < n) (L : Fin n → Finset (Fin n)) (f : Fin n → ℝ) :
    ∑ j, ((∑ i ∈ univ.filter (fun i => j ∈ L i), f i / ((L i).card : ℝ))
      + (∑ i ∈ univ.filter (fun i => L i = ∅), f i) / (n : ℝ)) = ∑ i, f i := by
  have hn' : (n : ℝ) ≠ 0 := by positivity
  rw [sum_add_distrib]
  simp only [sum_const, card_univ, Fintype.card_fin, nsmul_eq_mul]
  rw [mul_div_cancel₀ _ hn']
  simp_rw [sum_filter]
  rw [sum_comm]
  simp_rw [sum_ite_mem, univ_inter, sum_const, nsmul_eq_mul]
  rw [← sum_add_distrib]
  refine sum_congr rfl fun i _ => ?_
  by_cases h : L i = ∅
  · simp [h]
  · have : ((L i).card : ℝ) ≠ 0 := by
      have := Finset.nonempty_iff_ne_empty.mpr h
      exact_mod_cast this.card_pos.ne'
    simp [h, mul_div_cancel₀ _ this]

lemma pass_sum {n : ℕ} (hn : 0 < n) (L : Fin n → Finset (Fin n)) (α : ℝ) (x : Fin n → ℝ) :
    ∑ j, pass α L x j = α * ∑ j, x j + (1 - α) := by
  have hn' : (n : ℝ) ≠ 0 := by positivity
  have h : ∀ j, pass α L x j = α * ((∑ i ∈ univ.filter (fun i => j ∈ L i), x i / ((L i).card : ℝ))
      + (∑ i ∈ univ.filter (fun i => L i = ∅), x i) / (n : ℝ)) + (1 - α) / n := by
    intro j; unfold pass; ring
  simp_rw [h]
  rw [sum_add_distrib, ← mul_sum, col_sum hn]
  simp only [sum_const, card_univ, Fintype.card_fin, nsmul_eq_mul]
  rw [mul_div_cancel₀ _ hn']

lemma pass_score {n : ℕ} (hn : 0 < n) (L : Fin n → Finset (Fin n)) (α : ℝ) (hα0 : 0 ≤ α)
    (hα1 : α < 1) (x : Fin n → ℝ) (hx : IsScoreList x) : IsScoreList (pass α L x) := by
  refine ⟨fun j => ?_, ?_⟩
  · unfold pass
    have h1 : 0 ≤ ∑ i ∈ univ.filter (fun i => j ∈ L i), x i / ((L i).card : ℝ) :=
      sum_nonneg fun i _ => div_nonneg (hx.1 i) (by positivity)
    have h2 : 0 ≤ ∑ i ∈ univ.filter (fun i => L i = ∅), x i := sum_nonneg fun i _ => hx.1 i
    have h3 : 0 ≤ 1 - α := by linarith
    positivity
  · rw [pass_sum hn, hx.2]; ring

lemma pass_contract {n : ℕ} (L : Fin n → Finset (Fin n)) (α : ℝ) (hα0 : 0 ≤ α)
    (x y : Fin n → ℝ) :
    ∑ j, |pass α L x j - pass α L y j| ≤ α * ∑ j, |x j - y j| := by
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp
  have key : ∀ j, |pass α L x j - pass α L y j| ≤
      α * ((∑ i ∈ univ.filter (fun i => j ∈ L i), |x i - y i| / ((L i).card : ℝ))
      + (∑ i ∈ univ.filter (fun i => L i = ∅), |x i - y i|) / (n : ℝ)) := by
    intro j
    have e : pass α L x j - pass α L y j =
        α * ((∑ i ∈ univ.filter (fun i => j ∈ L i), (x i - y i) / ((L i).card : ℝ))
        + (∑ i ∈ univ.filter (fun i => L i = ∅), (x i - y i)) / (n : ℝ)) := by
      unfold pass
      simp_rw [sub_div, sum_sub_distrib]
      ring
    rw [e, abs_mul, abs_of_nonneg hα0]
    refine mul_le_mul_of_nonneg_left ?_ hα0
    refine (abs_add_le _ _).trans (add_le_add ?_ ?_)
    · refine (abs_sum_le_sum_abs _ _).trans (le_of_eq (sum_congr rfl fun i _ => ?_))
      rw [abs_div, Nat.abs_cast]
    · rw [abs_div, Nat.abs_cast]
      exact div_le_div_of_nonneg_right (abs_sum_le_sum_abs _ _) (by positivity)
  calc ∑ j, |pass α L x j - pass α L y j|
      ≤ ∑ j, α * ((∑ i ∈ univ.filter (fun i => j ∈ L i), |x i - y i| / ((L i).card : ℝ))
      + (∑ i ∈ univ.filter (fun i => L i = ∅), |x i - y i|) / (n : ℝ)) := sum_le_sum fun j _ => key j
    _ = α * ∑ j, |x j - y j| := by rw [← mul_sum, col_sum hn]

lemma pass_continuous {n : ℕ} (L : Fin n → Finset (Fin n)) (α : ℝ) :
    Continuous (pass α L) := by
  refine continuous_pi fun j => ?_
  unfold pass
  fun_prop

#print axioms col_sum
#print axioms pass_sum
#print axioms pass_score
#print axioms pass_contract
#print axioms pass_continuous

/-- The card's main claim. Whatever the links, with damping factor `0 ≤ α < 1`: there is exactly
one PageRank (a list of scores the pass leaves unchanged), and from any start that is a list of
scores, after `k` passes the total is still 1 and the error `e_k = ∑ |x_k(j) - π(j)|` is at most
`α ^ k * e_0`. -/
theorem damped_pass_keeps_total_and_shrinks_error
    (n : ℕ) (hn : 0 < n) (L : Fin n → Finset (Fin n)) (α : ℝ) (hα0 : 0 ≤ α) (hα1 : α < 1) :
    (∃! π : Fin n → ℝ, IsScoreList π ∧ pass α L π = π) ∧
    ∀ π : Fin n → ℝ, IsScoreList π → pass α L π = π →
      ∀ x : Fin n → ℝ, IsScoreList x → ∀ k : ℕ,
        ∑ j, (pass α L)^[k] x j = 1 ∧
        ∑ j, |(pass α L)^[k] x j - π j| ≤ α ^ k * ∑ j, |x j - π j| := by
  have hscore_iter : ∀ x : Fin n → ℝ, IsScoreList x → ∀ k : ℕ, IsScoreList ((pass α L)^[k] x) := by
    intro x hx k
    induction k with
    | zero => simpa using hx
    | succ k ih =>
      rw [Function.iterate_succ_apply']
      exact pass_score hn L α hα0 hα1 _ ih
  have hfix_score : ∀ π : Fin n → ℝ, pass α L π = π → ∑ j, π j = 1 := by
    intro π hπ
    have h := pass_sum hn L α π
    rw [hπ] at h
    have : (1 - α) * (∑ j, π j - 1) = 0 := by linarith
    rcases mul_eq_zero.mp this with h1 | h1
    · linarith
    · linarith
  refine ⟨?_, ?_⟩
  · -- existence by a Cauchy sequence of passes from the even start
    set u : Fin n → ℝ := fun _ => 1 / (n : ℝ) with hu
    have hn' : (n : ℝ) ≠ 0 := by positivity
    have hu_score : IsScoreList u := by
      refine ⟨fun j => by positivity, ?_⟩
      simp [hu, hn']
    set s : ℕ → (Fin n → ℝ) := fun k => (pass α L)^[k] u with hs
    have hstep : ∀ k, ∑ j, |s k j - s (k + 1) j| ≤ (∑ j, |u j - pass α L u j|) * α ^ k := by
      intro k
      induction k with
      | zero => simp [hs]
      | succ k ih =>
        have e1 : s (k + 1) = pass α L (s k) := by
          simp only [hs]; rw [Function.iterate_succ_apply']
        have e2 : s (k + 1 + 1) = pass α L (s (k + 1)) := by
          simp only [hs]; rw [Function.iterate_succ_apply']
        calc ∑ j, |s (k + 1) j - s (k + 1 + 1) j|
            = ∑ j, |pass α L (s k) j - pass α L (s (k + 1)) j| := by rw [e2, ← e1]
          _ ≤ α * ∑ j, |s k j - s (k + 1) j| := pass_contract L α hα0 _ _
          _ ≤ α * ((∑ j, |u j - pass α L u j|) * α ^ k) := mul_le_mul_of_nonneg_left ih hα0
          _ = (∑ j, |u j - pass α L u j|) * α ^ (k + 1) := by ring
    have hdist : ∀ k, dist (s k) (s (k + 1)) ≤ (∑ j, |u j - pass α L u j|) * α ^ k := by
      intro k
      refine (dist_pi_le_iff (le_trans (sum_nonneg fun j _ => abs_nonneg _) (hstep k))).mpr
        fun b => ?_
      rw [Real.dist_eq]
      exact le_trans (single_le_sum (f := fun j => |s k j - s (k + 1) j|)
        (fun j _ => abs_nonneg _) (mem_univ b)) (hstep k)
    have hcauchy : CauchySeq s := cauchySeq_of_le_geometric α _ hα1 hdist
    obtain ⟨π, hlim⟩ := cauchySeq_tendsto_of_complete hcauchy
    have hpfix : pass α L π = π := by
      have h1 : Filter.Tendsto (fun k => pass α L (s k)) Filter.atTop (nhds (pass α L π)) :=
        ((pass_continuous L α).tendsto π).comp hlim
      have h2 : Filter.Tendsto (fun k => s (k + 1)) Filter.atTop (nhds π) :=
        hlim.comp (Filter.tendsto_add_atTop_nat 1)
      have h3 : (fun k => pass α L (s k)) = (fun k => s (k + 1)) := by
        funext k; simp only [hs]; rw [Function.iterate_succ_apply']
      rw [h3] at h1
      exact tendsto_nhds_unique h1 h2
    have hπscore : IsScoreList π := by
      refine ⟨fun j => ?_, hfix_score π hpfix⟩
      exact ge_of_tendsto' (((continuous_apply j).tendsto π).comp hlim)
        (fun k => (hscore_iter u hu_score k).1 j)
    refine ⟨π, ⟨hπscore, hpfix⟩, ?_⟩
    rintro y ⟨hy, hyfix⟩
    have hle : ∑ j, |y j - π j| ≤ α * ∑ j, |y j - π j| := by
      have := pass_contract L α hα0 y π
      rwa [hyfix, hpfix] at this
    have hnn : 0 ≤ ∑ j, |y j - π j| := sum_nonneg fun j _ => abs_nonneg _
    have hz : ∑ j, |y j - π j| = 0 := by nlinarith
    funext j
    have := (sum_eq_zero_iff_of_nonneg (fun j _ => abs_nonneg (y j - π j))).mp hz j (mem_univ j)
    have := abs_eq_zero.mp this
    linarith
  · intro π hπ hpfix x hx k
    refine ⟨(hscore_iter x hx k).2, ?_⟩
    induction k with
    | zero => simp
    | succ k ih =>
      rw [Function.iterate_succ_apply']
      calc ∑ j, |pass α L ((pass α L)^[k] x) j - π j|
          = ∑ j, |pass α L ((pass α L)^[k] x) j - pass α L π j| := by rw [hpfix]
        _ ≤ α * ∑ j, |(pass α L)^[k] x j - π j| := pass_contract L α hα0 _ _
        _ ≤ α * (α ^ k * ∑ j, |x j - π j|) := mul_le_mul_of_nonneg_left ih hα0
        _ = α ^ (k + 1) * ∑ j, |x j - π j| := by ring

/-- Step 0 and Step 2: run the pass on two lists of scores; the total size of their difference
shrinks by at least the damping factor `α`. -/
theorem pass_pulls_two_lists_together
    (n : ℕ) (L : Fin n → Finset (Fin n)) (α : ℝ) (hα0 : 0 ≤ α) (hα1 : α < 1)
    (x y : Fin n → ℝ) (hx : IsScoreList x) (hy : IsScoreList y) :
    ∑ j, |pass α L x j - pass α L y j| ≤ α * ∑ j, |x j - y j| := by
  exact pass_contract L α hα0 x y

/-- Step 3, the stopping rule: if `x'` is one pass after a list of scores `x` and `δ` is the change
`∑ |x'(j) - x(j)|`, then the error of `x'` against PageRank is at most `α / (1 - α) * δ`, and
whenever that bound is smaller than the gap `x'(i) - x'(j)`, PageRank also ranks `i` above `j`. -/
theorem change_bounds_error_and_gap_certifies_order
    (n : ℕ) (L : Fin n → Finset (Fin n)) (α : ℝ) (hα0 : 0 ≤ α) (hα1 : α < 1)
    (π : Fin n → ℝ) (hπ : IsScoreList π) (hfix : pass α L π = π)
    (x : Fin n → ℝ) (hx : IsScoreList x) :
    ∑ j, |pass α L x j - π j| ≤ α / (1 - α) * ∑ j, |pass α L x j - x j| ∧
    ∀ i j : Fin n,
      α / (1 - α) * ∑ k, |pass α L x k - x k| < pass α L x i - pass α L x j → π j < π i := by
  have hcon : ∑ j, |pass α L x j - π j| ≤ α * ∑ j, |x j - π j| := by
    have := pass_contract L α hα0 x π
    rwa [hfix] at this
  have htri : ∑ j, |x j - π j| ≤ ∑ j, |pass α L x j - x j| + ∑ j, |pass α L x j - π j| := by
    rw [← sum_add_distrib]
    refine sum_le_sum fun j _ => ?_
    calc |x j - π j| = |(x j - pass α L x j) + (pass α L x j - π j)| := by ring_nf
      _ ≤ |x j - pass α L x j| + |pass α L x j - π j| := abs_add_le _ _
      _ = |pass α L x j - x j| + |pass α L x j - π j| := by rw [abs_sub_comm]
  have h1α : 0 < 1 - α := by linarith
  have herr : ∑ j, |pass α L x j - π j| ≤ α / (1 - α) * ∑ j, |pass α L x j - x j| := by
    rw [div_mul_eq_mul_div, le_div_iff₀ h1α]
    nlinarith
  refine ⟨herr, fun i j hgap => ?_⟩
  have hδ : 0 ≤ ∑ k, |pass α L x k - x k| := sum_nonneg fun k _ => abs_nonneg _
  have hB : 0 ≤ α / (1 - α) * ∑ k, |pass α L x k - x k| :=
    mul_nonneg (div_nonneg hα0 h1α.le) hδ
  by_cases hij : i = j
  · subst hij; linarith
  have hpair : |pass α L x i - π i| + |pass α L x j - π j| ≤ ∑ k, |pass α L x k - π k| := by
    have := sum_le_sum_of_subset_of_nonneg (f := fun k => |pass α L x k - π k|)
      (subset_univ ({i, j} : Finset (Fin n))) (fun k _ _ => abs_nonneg _)
    rwa [sum_pair hij] at this
  have hi := le_abs_self (pass α L x i - π i)
  have hj := neg_abs_le (pass α L x j - π j)
  linarith

/-- The six-page site: Home 0, Map 1, Prices 2, Join 3, Help 4, Terms 5 (a PDF, no links out). -/
def site : Fin 6 → Finset (Fin 6) := ![{1, 2, 5}, {0}, {0, 3}, {1, 4, 5}, {0, 5}, ∅]

-- The site has eleven links, and Terms is its only dangling page.
example : ∑ i, (site i).card = 11 := by decide
example : univ.filter (fun i => site i = ∅) = {5} := by decide

-- Worked by hand: Home after one pass from the even start, with α = 0.85 = 17/20, is 239/720 ≈ 0.3319.
example : pass (17 / 20) site (fun _ => 1 / 6) 0 = 239 / 720 := by 
  have h1 : univ.filter (fun i => (0 : Fin 6) ∈ site i) = {1, 2, 4} := by decide
  have h2 : univ.filter (fun i => site i = ∅) = {5} := by decide
  unfold pass
  rw [h1, h2]
  simp [site]
  norm_num

-- The stopping-rule factor α / (1 - α) at α = 0.85 is 17/3 ≈ 5.67.
example : ((17 : ℝ) / 20) / (1 - 17 / 20) = 17 / 3 := by norm_num

-- No damping, two pages linking only to each other: the scores (1, 0) become (0, 1).
example : pass (1 : ℝ) (![{1}, {0}] : Fin 2 → Finset (Fin 2)) ![1, 0] = ![0, 1] := by 
  refine funext (Fin.forall_fin_two.mpr ⟨?_, ?_⟩)
  · have h1 : univ.filter (fun i => (0 : Fin 2) ∈ (![{1}, {0}] : Fin 2 → Finset (Fin 2)) i) = {1} := by decide
    have h2 : univ.filter (fun i => (![{1}, {0}] : Fin 2 → Finset (Fin 2)) i = ∅) = ∅ := by decide
    simp only [pass]
    rw [h1, h2]
    simp
  · have h1 : univ.filter (fun i => (1 : Fin 2) ∈ (![{1}, {0}] : Fin 2 → Finset (Fin 2)) i) = {0} := by decide
    have h2 : univ.filter (fun i => (![{1}, {0}] : Fin 2 → Finset (Fin 2)) i = ∅) = ∅ := by decide
    simp only [pass]
    rw [h1, h2]
    simp

-- The 5,000-person network: additions per pass, the full table, and totals over 16 passes.
example : 50642 + 5000 = 55642 := by norm_num
example : 5000 * 5000 = 25000000 := by norm_num
example : 16 * 55642 = 890272 := by norm_num
example : 16 * 25000000 = 400000000 := by norm_num

-- The promise 2 × 0.85^k < 10^-6 first holds at k = 90.
example : (2 : ℚ) * (17 / 20) ^ 90 < 1 / 10 ^ 6 := by norm_num
example : ¬ ((2 : ℚ) * (17 / 20) ^ 89 < 1 / 10 ^ 6) := by norm_num

#print axioms damped_pass_keeps_total_and_shrinks_error
#print axioms pass_pulls_two_lists_together
#print axioms change_bounds_error_and_gap_certifies_order

end PageRankPowerIteration
