-- Random walks on a graph: on every finite connected simple graph the walk that steps to a uniformly chosen neighbour spends a long-run share of time on each vertex equal to its degree over twice the number of edges, that share is left unchanged by one step, the chance of being at each vertex settles to it once the graph also has an odd cycle, and the card's six-page site numbers check out exactly.
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.Combinatorics.SimpleGraph.Connectivity.Connected
import Mathlib.Combinatorics.SimpleGraph.Paths
import Mathlib.Data.Matrix.Mul
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Combinatorics.SimpleGraph.DegreeSum
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Algebra.BigOperators.Field

namespace RandomWalksOnGraphsAndMixing

open SimpleGraph Filter Topology

variable {V : Type*} [Fintype V]

/-- The click-chance table `P` of the random walk on `G`: from `i`, each of the `deg(i)` links is
clicked with the same chance, so `P i j = 1 / deg(i)` when `i` and `j` are linked, else `0`. -/
def walkMatrix (R : Type*) [DivisionRing R] (G : SimpleGraph V) [DecidableRel G.Adj] :
    Matrix V V R :=
  fun i j => if G.Adj i j then ((G.degree i : R))⁻¹ else 0

/-- The degree shares `π(i) = deg(i) / 2m`, where `m` is the number of links. -/
def degreeShare (R : Type*) [DivisionRing R] [DecidableEq V] (G : SimpleGraph V)
    [DecidableRel G.Adj] (i : V) : R :=
  (G.degree i : R) / (2 * G.edgeFinset.card)

/-! Helper lemmas for the proofs below. -/

section Helpers

lemma rw_sum_le_sub (q f : V → ℝ) (hq : ∀ z, 0 ≤ q z) (hs : ∑ z, q z = 1) (M : ℝ)
    (hf : ∀ z, f z ≤ M) (k : V) : ∑ z, q z * f z ≤ M - q k * (M - f k) := by
  have h1 : q k * (M - f k) ≤ ∑ z, q z * (M - f z) :=
    Finset.single_le_sum (f := fun z => q z * (M - f z))
      (fun z _ => mul_nonneg (hq z) (sub_nonneg.2 (hf z))) (Finset.mem_univ k)
  have h2 : ∑ z, q z * (M - f z) = M - ∑ z, q z * f z := by
    simp_rw [mul_sub, Finset.sum_sub_distrib, ← Finset.sum_mul, hs, one_mul]
  linarith

lemma rw_le_sum_add (q f : V → ℝ) (hq : ∀ z, 0 ≤ q z) (hs : ∑ z, q z = 1) (a : ℝ)
    (hf : ∀ z, a ≤ f z) (k : V) : a + q k * (f k - a) ≤ ∑ z, q z * f z := by
  have := rw_sum_le_sub q (fun z => -f z) hq hs (-a) (fun z => neg_le_neg (hf z)) k
  simp only [mul_neg, Finset.sum_neg_distrib] at this
  linarith

lemma rw_convex_bounds (q f : V → ℝ) (hq : ∀ z, 0 ≤ q z) (hs : ∑ z, q z = 1) (a b : ℝ)
    (hf : ∀ z, a ≤ f z ∧ f z ≤ b) : a ≤ ∑ z, q z * f z ∧ ∑ z, q z * f z ≤ b := by
  constructor
  · calc a = ∑ z, q z * a := by rw [← Finset.sum_mul, hs, one_mul]
      _ ≤ ∑ z, q z * f z := Finset.sum_le_sum fun z _ => mul_le_mul_of_nonneg_left (hf z).1 (hq z)
  · calc ∑ z, q z * f z ≤ ∑ z, q z * b :=
          Finset.sum_le_sum fun z _ => mul_le_mul_of_nonneg_left (hf z).2 (hq z)
      _ = b := by rw [← Finset.sum_mul, hs, one_mul]

variable (G : SimpleGraph V) [DecidableRel G.Adj]

lemma rw_walkMatrix_nonneg (i j : V) : 0 ≤ walkMatrix ℝ G i j := by
  unfold walkMatrix; split_ifs <;> positivity

lemma rw_row_sum (i : V) (hpos : 0 < G.degree i) : ∑ j, walkMatrix ℝ G i j = 1 := by
  unfold walkMatrix
  rw [Finset.sum_ite, Finset.sum_const_zero, add_zero, Finset.sum_const, nsmul_eq_mul]
  have : (Finset.univ.filter (fun j => G.Adj i j)) = G.neighborFinset i := by ext; simp
  rw [this, card_neighborFinset_eq_degree]
  have : (G.degree i : ℝ) ≠ 0 := by positivity
  field_simp

lemma rw_all_pos (hconn : G.Connected) (u w : V) (h : G.Adj u w) : ∀ x, 0 < G.degree x := by
  intro x
  obtain ⟨p⟩ := hconn.preconnected x u
  cases p with
  | nil => exact (G.degree_pos_iff_exists_adj _).2 ⟨w, h⟩
  | cons h' _ => exact (G.degree_pos_iff_exists_adj _).2 ⟨_, h'⟩

variable [DecidableEq V]

lemma rw_pow_nonneg (t : ℕ) (i j : V) : 0 ≤ (walkMatrix ℝ G ^ t) i j := by
  induction t generalizing i j with
  | zero => rw [pow_zero, Matrix.one_apply]; split_ifs <;> norm_num
  | succ t ih =>
    rw [pow_succ, Matrix.mul_apply]
    exact Finset.sum_nonneg fun k _ => mul_nonneg (ih _ _) (rw_walkMatrix_nonneg G _ _)

lemma rw_pow_row_sum (hpos : ∀ i, 0 < G.degree i) (t : ℕ) (i : V) :
    ∑ j, (walkMatrix ℝ G ^ t) i j = 1 := by
  induction t generalizing i with
  | zero => simp [Matrix.one_apply]
  | succ t ih =>
    rw [pow_succ']
    simp_rw [Matrix.mul_apply]
    rw [Finset.sum_comm]
    simp_rw [← Finset.mul_sum, ih, mul_one]
    exact rw_row_sum G i (hpos i)

lemma rw_pow_le_one (hpos : ∀ i, 0 < G.degree i) (t : ℕ) (i j : V) :
    (walkMatrix ℝ G ^ t) i j ≤ 1 := by
  rw [← rw_pow_row_sum G hpos t i]
  exact Finset.single_le_sum (f := fun j => (walkMatrix ℝ G ^ t) i j)
    (fun k _ => rw_pow_nonneg G t i k) (Finset.mem_univ j)

lemma rw_compose (s t : ℕ) (x y z : V) (h1 : 0 < (walkMatrix ℝ G ^ s) x y)
    (h2 : 0 < (walkMatrix ℝ G ^ t) y z) : 0 < (walkMatrix ℝ G ^ (s + t)) x z := by
  rw [pow_add, Matrix.mul_apply]
  exact lt_of_lt_of_le (mul_pos h1 h2)
    (Finset.single_le_sum (f := fun k => (walkMatrix ℝ G ^ s) x k * (walkMatrix ℝ G ^ t) k z)
      (fun k _ => mul_nonneg (rw_pow_nonneg G s x k) (rw_pow_nonneg G t k z)) (Finset.mem_univ y))

lemma rw_walk_pos {u w : V} (p : G.Walk u w) : 0 < (walkMatrix ℝ G ^ p.length) u w := by
  induction p with
  | nil => simp
  | cons h p ih =>
    rename_i a b c
    have h1 : 0 < (walkMatrix ℝ G ^ 1) a b := by
      rw [pow_one]
      unfold walkMatrix
      simp only [h, ↓reduceIte]
      have : 0 < G.degree a := (G.degree_pos_iff_exists_adj _).2 ⟨b, h⟩
      positivity
    have := rw_compose G 1 p.length a b c h1 ih
    rwa [add_comm] at this

lemma rw_balance (i j : V) (h : G.Adj i j) :
    degreeShare ℝ G i * walkMatrix ℝ G i j = (2 * (G.edgeFinset.card : ℝ))⁻¹ := by
  unfold walkMatrix degreeShare
  simp only [h, ↓reduceIte]
  have hd : (G.degree i : ℝ) ≠ 0 := by
    have : 0 < G.degree i := (G.degree_pos_iff_exists_adj _).2 ⟨j, h⟩
    positivity
  rw [div_mul_eq_mul_div, mul_inv_cancel₀ hd, one_div]

lemma rw_stationary :
    Matrix.vecMul (degreeShare ℝ G) (walkMatrix ℝ G) = degreeShare ℝ G := by
  ext j
  simp only [Matrix.vecMul, dotProduct]
  have : ∀ i, degreeShare ℝ G i * walkMatrix ℝ G i j =
      if G.Adj i j then (2 * (G.edgeFinset.card : ℝ))⁻¹ else 0 := by
    intro i
    split_ifs with h
    · exact rw_balance G i j h
    · simp [walkMatrix, h]
  simp_rw [this]
  rw [Finset.sum_ite, Finset.sum_const_zero, add_zero, Finset.sum_const, nsmul_eq_mul]
  have : (Finset.univ.filter (fun i => G.Adj i j)) = G.neighborFinset j := by
    ext; simp [adj_comm]
  rw [this, card_neighborFinset_eq_degree]
  unfold degreeShare
  rw [div_eq_mul_inv]

lemma rw_stationary_pow (t : ℕ) (j : V) :
    ∑ x, degreeShare ℝ G x * (walkMatrix ℝ G ^ t) x j = degreeShare ℝ G j := by
  have : Matrix.vecMul (degreeShare ℝ G) (walkMatrix ℝ G ^ t) = degreeShare ℝ G := by
    induction t with
    | zero => simp
    | succ t ih => rw [pow_succ, ← Matrix.vecMul_vecMul, ih, rw_stationary]
  have h := congrFun this j
  simpa [Matrix.vecMul, dotProduct] using h

lemma rw_share_nonneg (i : V) : 0 ≤ degreeShare ℝ G i := by
  unfold degreeShare; positivity

lemma rw_share_sum (u w : V) (h : G.Adj u w) : ∑ i, degreeShare ℝ G i = 1 := by
  unfold degreeShare
  have hm : 0 < G.edgeFinset.card :=
    Finset.card_pos.2 ⟨s(u, w), (G.mem_edgeFinset).2 h⟩
  rw [← Finset.sum_div, ← Nat.cast_sum, G.sum_degrees_eq_twice_card_edges]
  have : (G.edgeFinset.card : ℝ) ≠ 0 := by positivity
  push_cast
  field_simp

end Helpers

#print axioms rw_sum_le_sub
#print axioms rw_le_sum_add
#print axioms rw_convex_bounds
#print axioms rw_walkMatrix_nonneg
#print axioms rw_row_sum
#print axioms rw_all_pos
#print axioms rw_pow_nonneg
#print axioms rw_pow_row_sum
#print axioms rw_pow_le_one
#print axioms rw_compose
#print axioms rw_walk_pos
#print axioms rw_balance
#print axioms rw_stationary
#print axioms rw_stationary_pow
#print axioms rw_share_nonneg
#print axioms rw_share_sum

/-- The card's main result. On a finite connected network with two-way links (a connected simple
graph `G`) that also has a loop of odd length (a cycle with an odd number of edges), the chance
that the random walk started at any page `x` is on page `j` after `t` clicks, `(P ^ t) x j`,
settles as `t` grows to `deg(j) / 2m`, whatever the start. -/
theorem walk_chance_tendsto_degree_share [DecidableEq V] (G : SimpleGraph V) [DecidableRel G.Adj]
    (hconn : G.Connected) (hodd : ∃ (v : V) (c : G.Walk v v), c.IsCycle ∧ Odd c.length)
    (x j : V) :
    Tendsto (fun t : ℕ => (walkMatrix ℝ G ^ t) x j) atTop (𝓝 (degreeShare ℝ G j)) := by
  obtain ⟨v, c, -, hL⟩ := hodd
  have hnb : ∃ u, G.Adj v u := by
    cases c with
    | nil => simp at hL
    | cons h _ => exact ⟨_, h⟩
  obtain ⟨u, hvu⟩ := hnb
  have hpos := rw_all_pos G hconn v u hvu
  have h2 : ∀ a : ℕ, 0 < (walkMatrix ℝ G ^ (2 * a)) v v := by
    intro a
    induction a with
    | zero => simp
    | succ a ih =>
      have h2' : 0 < (walkMatrix ℝ G ^ 2) v v := by
        simpa using rw_walk_pos G (Walk.cons hvu (Walk.cons hvu.symm Walk.nil))
      have := rw_compose G (2 * a) 2 v v v ih h2'
      rwa [show 2 * a + 2 = 2 * (a + 1) by ring] at this
  have hc := rw_walk_pos G c
  have hN : ∀ y, 0 < (walkMatrix ℝ G ^ (Fintype.card V + c.length)) y v := by
    intro y
    obtain ⟨p⟩ := hconn.preconnected y v
    have hlt : p.bypass.length < Fintype.card V := p.bypass_isPath.length_lt
    have hp := rw_walk_pos G p.bypass
    have hr : 0 < (walkMatrix ℝ G ^ (Fintype.card V + c.length - p.bypass.length)) v v := by
      rcases Nat.even_or_odd (Fintype.card V + c.length - p.bypass.length) with ⟨a, ha⟩ | hodd'
      · rw [ha, ← two_mul]; exact h2 a
      · obtain ⟨a, ha⟩ : Even (Fintype.card V + c.length - p.bypass.length - c.length) :=
          Nat.Odd.sub_odd hodd' hL
        have := rw_compose G c.length (2 * a) v v v hc (h2 a)
        rwa [two_mul, ← ha, Nat.add_sub_cancel' (by omega)] at this
    have := rw_compose G _ _ y v v hp hr
    rwa [Nat.add_sub_cancel' (by omega)] at this
  have : Nonempty V := ⟨v⟩
  obtain ⟨x1, hx1⟩ := Finite.exists_min (fun y => (walkMatrix ℝ G ^ (Fintype.card V + c.length)) y v)
  obtain ⟨N, hNdef⟩ : ∃ N, N = Fintype.card V + c.length := ⟨_, rfl⟩
  rw [← hNdef] at hN hx1
  obtain ⟨δ, hδdef⟩ : ∃ δ, δ = (walkMatrix ℝ G ^ N) x1 v := ⟨_, rfl⟩
  have hδpos : 0 < δ := hδdef ▸ hN x1
  have hδ1 : δ ≤ 1 := hδdef ▸ rw_pow_le_one G hpos N x1 v
  have key : ∀ m s : ℕ, ∃ a b : ℝ, b - a ≤ (1 - δ) ^ m ∧
      ∀ y, a ≤ (walkMatrix ℝ G ^ (m * N + s)) y j ∧ (walkMatrix ℝ G ^ (m * N + s)) y j ≤ b := by
    intro m s
    induction m with
    | zero => exact ⟨0, 1, by simp, fun y => ⟨rw_pow_nonneg G _ y j, rw_pow_le_one G hpos _ y j⟩⟩
    | succ m ih =>
      obtain ⟨a, b, hab, hf⟩ := ih
      obtain ⟨f, hfdef⟩ : ∃ f : V → ℝ, f = fun z => (walkMatrix ℝ G ^ (m * N + s)) z j :=
        ⟨_, rfl⟩
      have hf' : ∀ z, a ≤ f z ∧ f z ≤ b := by rw [hfdef]; exact hf
      refine ⟨a + δ * (f v - a), b - δ * (b - f v), ?_, fun y => ?_⟩
      · have : 0 ≤ 1 - δ := by linarith
        calc b - δ * (b - f v) - (a + δ * (f v - a)) = (1 - δ) * (b - a) := by ring
          _ ≤ (1 - δ) * (1 - δ) ^ m := mul_le_mul_of_nonneg_left hab this
          _ = (1 - δ) ^ (m + 1) := by ring
      · have he : (walkMatrix ℝ G ^ ((m + 1) * N + s)) y j =
            ∑ z, (walkMatrix ℝ G ^ N) y z * f z := by
          rw [show (m + 1) * N + s = N + (m * N + s) by ring, pow_add, Matrix.mul_apply, hfdef]
        rw [he]
        have hq := fun z => rw_pow_nonneg G N y z
        have hs := rw_pow_row_sum G hpos N y
        have h1 := rw_le_sum_add _ f hq hs a (fun z => (hf' z).1) v
        have h2 := rw_sum_le_sub _ f hq hs b (fun z => (hf' z).2) v
        have hfv := hf' v
        have hd : δ ≤ (walkMatrix ℝ G ^ N) y v := hδdef ▸ hx1 y
        have k1 := mul_le_mul_of_nonneg_right hd (sub_nonneg.2 hfv.1)
        have k2 := mul_le_mul_of_nonneg_right hd (sub_nonneg.2 hfv.2)
        constructor <;> linarith
  rw [Metric.tendsto_atTop]
  intro ε hε
  obtain ⟨m, hm⟩ := exists_pow_lt_of_lt_one hε (show 1 - δ < 1 by linarith)
  refine ⟨m * N, fun t ht => ?_⟩
  obtain ⟨a, b, hab, hf⟩ := key m (t - m * N)
  rw [Nat.add_sub_cancel' ht] at hf
  have hπ := rw_convex_bounds (degreeShare ℝ G) (fun y => (walkMatrix ℝ G ^ t) y j)
    (rw_share_nonneg G) (rw_share_sum G v u hvu) a b hf
  rw [rw_stationary_pow] at hπ
  rw [Real.dist_eq, abs_sub_lt_iff]
  have := hf x
  constructor <;> linarith

/-- The long-run share of time. On a finite connected network with two-way links, the average
over the first `T` clicks of the chance of being on page `j`, from any start `x`, tends to
`deg(j) / 2m`. No odd loop is needed for this. -/
theorem time_average_tendsto_degree_share [DecidableEq V] (G : SimpleGraph V)
    [DecidableRel G.Adj] (hconn : G.Connected) (x j : V) :
    Tendsto (fun T : ℕ => (T : ℝ)⁻¹ * ∑ t ∈ Finset.range T, (walkMatrix ℝ G ^ t) x j) atTop
      (𝓝 (degreeShare ℝ G j)) := by
  have := hconn.nonempty
  by_cases hE : ∃ u w, G.Adj u w
  swap
  · simp only [not_exists] at hE
    have hP : walkMatrix ℝ G = 0 := by ext a b; simp [walkMatrix, hE a b]
    have hdeg : G.degree j = 0 := by
      by_contra h
      obtain ⟨w, hw⟩ := (G.degree_pos_iff_exists_adj j).1 (Nat.pos_of_ne_zero h)
      exact hE j w hw
    have hπ : degreeShare ℝ G j = 0 := by simp [degreeShare, hdeg]
    rw [hπ]
    have heq : ∀ T : ℕ, (T : ℝ)⁻¹ * ∑ t ∈ Finset.range T, (walkMatrix ℝ G ^ t) x j =
        (T : ℝ)⁻¹ * (1 : Matrix V V ℝ) x j := by
      intro T
      cases T with
      | zero => simp
      | succ T => rw [Finset.sum_range_succ', hP]; simp
    simp_rw [heq]
    have := (tendsto_inv_atTop_zero.comp tendsto_natCast_atTop_atTop).mul_const
      ((1 : Matrix V V ℝ) x j)
    simpa using this
  obtain ⟨u, w, huw⟩ := hE
  have hpos := rw_all_pos G hconn u w huw
  have hn0 : (0 : ℝ) ≤ Fintype.card V := Nat.cast_nonneg _
  have main : ∀ T : ℕ, 1 ≤ T →
      |(T : ℝ)⁻¹ * ∑ t ∈ Finset.range T, (walkMatrix ℝ G ^ t) x j - degreeShare ℝ G j| ≤
        ((Fintype.card V : ℝ) + 1) ^ Fintype.card V * (T : ℝ)⁻¹ := by
    intro T hT
    obtain ⟨ε, hεdef⟩ : ∃ ε : ℝ, ε = (T : ℝ)⁻¹ := ⟨_, rfl⟩
    rw [← hεdef]
    obtain ⟨f, hf⟩ : ∃ f : V → ℝ,
        f = fun y => ε * ∑ t ∈ Finset.range T, (walkMatrix ℝ G ^ t) y j := ⟨_, rfl⟩
    have hfx : ε * ∑ t ∈ Finset.range T, (walkMatrix ℝ G ^ t) x j = f x := by rw [hf]
    rw [hfx]
    have hε : 0 ≤ ε := by rw [hεdef]; positivity
    have hharm : ∀ y, f y - ε ≤ ∑ z, walkMatrix ℝ G y z * f z := by
      intro y
      have e1 : ∑ z, walkMatrix ℝ G y z * f z =
          ε * ∑ t ∈ Finset.range T, (walkMatrix ℝ G ^ (t + 1)) y j := by
        rw [hf]
        simp_rw [pow_succ', Matrix.mul_apply, Finset.mul_sum]
        rw [Finset.sum_comm]
        exact Finset.sum_congr rfl fun _ _ => Finset.sum_congr rfl fun _ _ => by ring
      have tel1 := Finset.sum_range_succ (fun t => (walkMatrix ℝ G ^ t) y j) T
      have tel2 := Finset.sum_range_succ' (fun t => (walkMatrix ℝ G ^ t) y j) T
      have g0 : (walkMatrix ℝ G ^ 0) y j ≤ 1 := rw_pow_le_one G hpos 0 y j
      have gT : 0 ≤ (walkMatrix ℝ G ^ T) y j := rw_pow_nonneg G T y j
      have hfy : f y = ε * ∑ t ∈ Finset.range T, (walkMatrix ℝ G ^ t) y j := by rw [hf]
      rw [e1, hfy]
      nlinarith
    obtain ⟨x0, hx0⟩ := Finite.exists_max f
    have step : ∀ y a, G.Adj y a → f x0 - f a ≤ Fintype.card V * (f x0 - f y + ε) := by
      intro y a hya
      have h1 := rw_sum_le_sub (walkMatrix ℝ G y) f (rw_walkMatrix_nonneg G y)
        (rw_row_sum G y (hpos y)) (f x0) hx0 a
      have h2 := hharm y
      have hPya : walkMatrix ℝ G y a = ((G.degree y : ℝ))⁻¹ := by simp [walkMatrix, hya]
      rw [hPya] at h1
      have hdpos : (0 : ℝ) < G.degree y := by exact_mod_cast hpos y
      have hdn : (G.degree y : ℝ) ≤ Fintype.card V := by
        exact_mod_cast (G.degree_lt_card_verts y).le
      have h3 : (G.degree y : ℝ)⁻¹ * (f x0 - f a) ≤ f x0 - f y + ε := by linarith
      have h4 : f x0 - f a ≤ G.degree y * (f x0 - f y + ε) := by
        have := mul_le_mul_of_nonneg_left h3 hdpos.le
        rwa [← mul_assoc, mul_inv_cancel₀ hdpos.ne', one_mul] at this
      have h5 : 0 ≤ f x0 - f y + ε := by have := hx0 y; linarith
      calc f x0 - f a ≤ G.degree y * (f x0 - f y + ε) := h4
        _ ≤ Fintype.card V * (f x0 - f y + ε) := mul_le_mul_of_nonneg_right hdn h5
    have walkb : ∀ {a b : V} (p : G.Walk a b), b = x0 →
        f x0 - f a ≤ (((Fintype.card V : ℝ) + 1) ^ p.length - 1) * ε := by
      intro a b p
      induction p with
      | nil => intro h; simp [h]
      | cons h p ih =>
        intro hb
        have ih' := ih hb
        rename_i a' b' c'
        have hs := step b' a' h.symm
        rw [Walk.length_cons, pow_succ]
        have hX : (1 : ℝ) ≤ ((Fintype.card V : ℝ) + 1) ^ p.length := one_le_pow₀ (by linarith)
        nlinarith [mul_nonneg (sub_nonneg.2 hX) hε, mul_le_mul_of_nonneg_left ih' hn0]
    have hK : ∀ y, f x0 - ((Fintype.card V : ℝ) + 1) ^ Fintype.card V * ε ≤ f y ∧ f y ≤ f x0 := by
      intro y
      obtain ⟨p⟩ := hconn.preconnected y x0
      have h1 := walkb p.bypass rfl
      have hlen : p.bypass.length ≤ Fintype.card V := (p.bypass_isPath.length_lt).le
      have : ((Fintype.card V : ℝ) + 1) ^ p.bypass.length ≤
          ((Fintype.card V : ℝ) + 1) ^ Fintype.card V := pow_le_pow_right₀ (by linarith) hlen
      constructor
      · nlinarith
      · exact hx0 y
    have hπ := rw_convex_bounds (degreeShare ℝ G) f (rw_share_nonneg G) (rw_share_sum G u w huw) _ _ hK
    have hsum : ∑ z, degreeShare ℝ G z * f z = degreeShare ℝ G j := by
      rw [hf]
      simp_rw [Finset.mul_sum]
      rw [Finset.sum_comm]
      have : ∀ t, ∑ z, degreeShare ℝ G z * (ε * (walkMatrix ℝ G ^ t) z j) =
          ε * degreeShare ℝ G j := by
        intro t
        rw [← rw_stationary_pow G t j, Finset.mul_sum]
        exact Finset.sum_congr rfl fun _ _ => by ring
      simp_rw [this]
      rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul, hεdef, ← mul_assoc,
        mul_inv_cancel₀ (by exact_mod_cast (show T ≠ 0 by omega)), one_mul]
    have hx := hK x
    rw [hsum] at hπ
    rw [abs_sub_le_iff]
    constructor <;> linarith
  rw [Metric.tendsto_atTop]
  intro e he
  obtain ⟨T0, hT0⟩ := exists_nat_gt ((((Fintype.card V : ℝ) + 1) ^ Fintype.card V) / e)
  refine ⟨T0 + 1, fun T hT => ?_⟩
  rw [Real.dist_eq]
  refine lt_of_le_of_lt (main T (by omega)) ?_
  have hTpos : (0 : ℝ) < T := by exact_mod_cast (show 0 < T by omega)
  have hTT : (T0 : ℝ) + 1 ≤ T := by exact_mod_cast hT
  rw [← div_eq_mul_inv, div_lt_iff₀ hTpos]
  rw [div_lt_iff₀ he] at hT0
  nlinarith

/-- Steps 0 and 1 of the card. With `π(i) = deg(i) / 2m`, every link carries traffic
`π(i) P i j = 1 / 2m` in each direction (detailed balance), and one click leaves `π` unchanged:
`π P = π`. -/
theorem degree_share_balanced_and_stationary [DecidableEq V] (G : SimpleGraph V)
    [DecidableRel G.Adj] :
    (∀ i j, G.Adj i j →
        degreeShare ℝ G i * walkMatrix ℝ G i j = (2 * (G.edgeFinset.card : ℝ))⁻¹) ∧
      Matrix.vecMul (degreeShare ℝ G) (walkMatrix ℝ G) = degreeShare ℝ G := by
  exact ⟨fun i j h => rw_balance G i j h, rw_stationary G⟩

/-! The card's six-page site: Home, About, Blog, Shop, Contact, FAQ are `0` to `5`. -/

/-- The eight two-way links. -/
def siteLinks : List (Fin 6 × Fin 6) :=
  [(0, 1), (0, 2), (0, 3), (0, 4), (2, 3), (2, 5), (3, 4), (3, 5)]

/-- The six-page site as a simple graph. -/
def site : SimpleGraph (Fin 6) where
  Adj x y := (x, y) ∈ siteLinks ∨ (y, x) ∈ siteLinks
  symm := ⟨fun _ _ h => h.symm⟩
  loopless := ⟨by decide⟩

instance : DecidableRel site.Adj := fun _ _ => inferInstanceAs (Decidable (_ ∨ _))

/-- Total variation distance from the degree shares after `t` clicks from page `x`:
half the sum of the six gaps. -/
def siteTV (t : ℕ) (x : Fin 6) : ℚ :=
  (1 / 2) * ∑ j, |(walkMatrix ℚ site ^ t) x j - degreeShare ℚ site j|

/-- Six pages in a ring: every loop is even. -/
def ring6 : SimpleGraph (Fin 6) where
  Adj x y := (x.val + 1) % 6 = y.val ∨ (y.val + 1) % 6 = x.val
  symm := ⟨fun _ _ h => h.symm⟩
  loopless := ⟨by decide⟩

instance : DecidableRel ring6.Adj := fun _ _ => inferInstanceAs (Decidable (_ ∨ _))

-- Degrees 4 1 3 4 2 2; 8 links; 4 + 1 + 3 + 4 + 2 + 2 = 16 = 2 × 8 link ends.
example : (List.finRange 6).map (fun i => site.degree i) = [4, 1, 3, 4, 2, 2] := by decide +kernel
example : site.edgeFinset.card = 8 ∧ ∑ i, site.degree i = 2 * 8 := by decide +kernel
-- The shares: 1/4, 1/16, 3/16, 1/4, 1/8, 1/8 (0.2500, 0.0625, 0.1875, 0.2500, 0.1250, 0.1250).
example : (List.finRange 6).map (degreeShare ℚ site) = [1/4, 1/16, 3/16, 1/4, 1/8, 1/8] := by
  decide +kernel
-- Every link carries 1/16 each way, and Home's inflow is four links × 1/16 = 1/4, its own share.
example : ∀ i j, site.Adj i j → degreeShare ℚ site i * walkMatrix ℚ site i j = 1 / 16 := by decide +kernel
example : ∑ i, degreeShare ℚ site i * walkMatrix ℚ site i 0 = 1 / 4 := by decide +kernel
-- Home, Blog and Shop form a triangle: an odd loop.
example : site.Adj 0 2 ∧ site.Adj 2 3 ∧ site.Adj 3 0 := by decide +kernel
-- From About: Home for sure after 1 click; About, Blog, Shop, Contact 1/4 each after 2;
-- after 3: Home 25/48 (0.5208), Blog 1/16, Shop 5/24 (0.2083), Contact 1/16, FAQ 7/48 (0.1458).
example : (List.finRange 6).map (fun j => (walkMatrix ℚ site ^ 1) 1 j) = [1, 0, 0, 0, 0, 0] := by
  decide +kernel
example : (List.finRange 6).map (fun j => (walkMatrix ℚ site ^ 2) 1 j) =
    [0, 1/4, 1/4, 1/4, 1/4, 0] := by decide +kernel
example : (List.finRange 6).map (fun j => (walkMatrix ℚ site ^ 3) 1 j) =
    [25/48, 0, 1/16, 5/24, 1/16, 7/48] := by decide +kernel
-- The distance from About falls 15/16, 3/4, 3/8, 7/24, 19/96 (0.9375, 0.7500, 0.3750, 0.2917, 0.1979).
example : (List.range 5).map (fun t => siteTV t 1) = [15/16, 3/4, 3/8, 7/24, 19/96] := by decide +kernel
-- About is the worst start at every one of those clicks, and t_mix = 4: after 3 clicks the
-- worst distance is above a quarter, after 4 every start is within a quarter.
example : ∀ t < 5, ∀ x, siteTV t x ≤ siteTV t 1 := by decide +kernel
example : 1 / 4 < siteTV 3 1 ∧ ∀ x, siteTV 4 x ≤ 1 / 4 := by decide +kernel
-- Sum of squared eigenvalues = trace of P², which is 49/24 (2.0417).
example : Matrix.trace (walkMatrix ℚ site ^ 2) = 49 / 24 := by decide +kernel
-- Average clicks between visits to About: 1 / π(About) = 16.
example : (degreeShare ℚ site 1)⁻¹ = 16 := by decide +kernel
-- The ring of six has eigenvalue −1: the list +1, −1, +1, −1, +1, −1 flips sign at each click,
-- and a walk started on page 0 is on the even pages after 60 clicks, so its distance from the
-- even shares 1/6 is 1/2.
example : Matrix.mulVec (walkMatrix ℚ ring6) ![1, -1, 1, -1, 1, -1] = -![1, -1, 1, -1, 1, -1] := by decide +kernel
example : (1 / 2 : ℚ) * ∑ j, |(walkMatrix ℚ ring6 ^ 60) 0 j - 1 / 6| = 1 / 2 := by decide +kernel

#print axioms walk_chance_tendsto_degree_share
#print axioms time_average_tendsto_degree_share
#print axioms degree_share_balanced_and_stationary

end RandomWalksOnGraphsAndMixing
