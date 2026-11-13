-- American options on a grid: on a mesh whose band has non-negative side weights and a diagonal larger than their sum, the floor-and-slack complementarity problem has exactly one solution, it is the fixed point of "row value, then lift onto the floor", and projected over-relaxation sweeps converge to it for every weight 0 < ω < 2/(1 + κ₀).
import Mathlib.Basic.Real.Basic
import Mathlib
import Mathlib.Topology.Algebra.Order.Field
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Order.Filter.AtTopBot.Basic

open Filter Topology

namespace AmericanLCP

/-- One date's values on a mesh of `n` nodes, read at position `k`; zero past the top.
The mesh's known end values are folded into the right-hand side `b`, as on the card. -/
noncomputable def val {n : ℕ} (x : Fin n → ℝ) (k : ℕ) : ℝ :=
  if h : k < n then x ⟨k, h⟩ else 0

/-- The lower neighbour of node `i` (zero for the bottom node). -/
noncomputable def below {n : ℕ} (x : Fin n → ℝ) (i : Fin n) : ℝ :=
  if i.val = 0 then 0 else val x (i.val - 1)

/-- The upper neighbour of node `i` (zero for the top node). -/
noncomputable def above {n : ℕ} (x : Fin n → ℝ) (i : Fin n) : ℝ :=
  val x (i.val + 1)

/-- The slack `w = A x - b` of row `i`, where the band `A` has diagonal `d`, lower weight `ℓ`
and upper weight `u`: `w_i = d x_i - ℓ x_{i-1} - u x_{i+1} - b_i`. -/
noncomputable def slack {n : ℕ} (d ℓ u : ℝ) (b x : Fin n → ℝ) (i : Fin n) : ℝ :=
  d * x i - ℓ * below x i - u * above x i - b i

/-- The linear complementarity problem: every value clears its floor `g`, no row's slack is
negative, and at every node one of the two is tight. -/
def IsLCP {n : ℕ} (d ℓ u : ℝ) (b g x : Fin n → ℝ) : Prop :=
  ∀ i, g i ≤ x i ∧ 0 ≤ slack d ℓ u b x i ∧ (x i - g i) * slack d ℓ u b x i = 0

/-- One PSOR sweep, node by node from the bottom, as a function of the node position:
relax using the lower neighbour already updated in this sweep and the old upper neighbour,
then lift onto the floor. -/
noncomputable def sweepAux {n : ℕ} (d ℓ u ω : ℝ) (b g x : Fin n → ℝ) : ℕ → ℝ
  | 0 =>
      if h : 0 < n then
        max (g ⟨0, h⟩) ((1 - ω) * x ⟨0, h⟩ + ω / d * (b ⟨0, h⟩ + ℓ * 0 + u * val x 1))
      else 0
  | k + 1 =>
      if h : k + 1 < n then
        max (g ⟨k + 1, h⟩) ((1 - ω) * x ⟨k + 1, h⟩
          + ω / d * (b ⟨k + 1, h⟩ + ℓ * sweepAux d ℓ u ω b g x k + u * val x (k + 2)))
      else 0

/-- One projected SOR sweep:
`x_i⁺ = max(g_i, (1-ω) x_i + (ω/d)(b_i + ℓ x_{i-1}⁺ + u x_{i+1}))`. -/
noncomputable def psorSweep {n : ℕ} (d ℓ u ω : ℝ) (b g x : Fin n → ℝ) : Fin n → ℝ :=
  fun i => sweepAux d ℓ u ω b g x i.val

theorem abs_max_left_sub_le (c a a' : ℝ) : |max c a - max c a'| ≤ |a - a'| := by
  rw [max_comm c a, max_comm c a']; exact abs_max_sub_max_le_abs _ _ _

theorem val_sub_le {n : ℕ} (x y : Fin n → ℝ) {E : ℝ} (hE : 0 ≤ E)
    (h : ∀ i, |x i - y i| ≤ E) (k : ℕ) : |val x k - val y k| ≤ E := by
  unfold val
  split_ifs with hk
  · exact h _
  · simpa using hE

theorem below_sub_le {n : ℕ} (x y : Fin n → ℝ) {E : ℝ} (hE : 0 ≤ E)
    (h : ∀ i, |x i - y i| ≤ E) (i : Fin n) : |below x i - below y i| ≤ E := by
  unfold below
  split_ifs with hi
  · simpa using hE
  · exact val_sub_le x y hE h _

theorem above_sub_le {n : ℕ} (x y : Fin n → ℝ) {E : ℝ} (hE : 0 ≤ E)
    (h : ∀ i, |x i - y i| ≤ E) (i : Fin n) : |above x i - above y i| ≤ E :=
  val_sub_le x y hE h _

theorem comb_le (ω d ℓ u p q s E : ℝ) (hd : 0 < d) (hω : 0 ≤ ω) (hℓ : 0 ≤ ℓ) (hu : 0 ≤ u)
    (hp : |p| ≤ E) (hq : |q| ≤ E) (hs : |s| ≤ E) :
    |(1 - ω) * p + ω / d * (ℓ * q + u * s)| ≤ (|1 - ω| + ω * ((ℓ + u) / d)) * E := by
  have hE : 0 ≤ E := (abs_nonneg p).trans hp
  have h1 : |(1 - ω) * p| ≤ |1 - ω| * E := by
    rw [abs_mul]; exact mul_le_mul_of_nonneg_left hp (abs_nonneg _)
  have h2 : |ℓ * q + u * s| ≤ (ℓ + u) * E := by
    calc |ℓ * q + u * s| ≤ |ℓ * q| + |u * s| := abs_add_le _ _
      _ = ℓ * |q| + u * |s| := by rw [abs_mul, abs_mul, abs_of_nonneg hℓ, abs_of_nonneg hu]
      _ ≤ ℓ * E + u * E := by gcongr
      _ = (ℓ + u) * E := by ring
  have hωd : 0 ≤ ω / d := div_nonneg hω hd.le
  have h3 : |ω / d * (ℓ * q + u * s)| ≤ ω / d * ((ℓ + u) * E) := by
    rw [abs_mul, abs_of_nonneg hωd]; exact mul_le_mul_of_nonneg_left h2 hωd
  calc |(1 - ω) * p + ω / d * (ℓ * q + u * s)|
      ≤ |(1 - ω) * p| + |ω / d * (ℓ * q + u * s)| := abs_add_le _ _
    _ ≤ |1 - ω| * E + ω / d * ((ℓ + u) * E) := add_le_add h1 h3
    _ = (|1 - ω| + ω * ((ℓ + u) / d)) * E := by field_simp

theorem row_sub_le {n : ℕ} (d ℓ u : ℝ) (hd : 0 < d) (hℓ : 0 ≤ ℓ) (hu : 0 ≤ u)
    (b x y : Fin n → ℝ) {E : ℝ} (hE : 0 ≤ E) (h : ∀ i, |x i - y i| ≤ E) (i : Fin n) :
    |(b i + ℓ * below x i + u * above x i) / d - (b i + ℓ * below y i + u * above y i) / d|
      ≤ (ℓ + u) / d * E := by
  have := comb_le 1 d ℓ u 0 (below x i - below y i) (above x i - above y i) E hd zero_le_one
    hℓ hu (by simpa using hE) (below_sub_le x y hE h i) (above_sub_le x y hE h i)
  have e : (b i + ℓ * below x i + u * above x i) / d - (b i + ℓ * below y i + u * above y i) / d
      = (1 - 1) * 0 + 1 / d * (ℓ * (below x i - below y i) + u * (above x i - above y i)) := by
    field_simp; ring
  rw [e]; simpa using this

theorem lcp_iff_aux (n : ℕ) (d ℓ u : ℝ) (hd : 0 < d) (b g x : Fin n → ℝ) :
    IsLCP d ℓ u b g x ↔
      ∀ i, x i = max (g i) ((b i + ℓ * below x i + u * above x i) / d) := by
  have hs : ∀ i, slack d ℓ u b x i = d * (x i - (b i + ℓ * below x i + u * above x i) / d) := by
    intro i; unfold slack; field_simp; ring
  unfold IsLCP
  refine forall_congr' fun i => ?_
  rw [hs i]
  set r := (b i + ℓ * below x i + u * above x i) / d
  constructor
  · rintro ⟨h1, h2, h3⟩
    have hr : r ≤ x i := by
      have := (mul_nonneg_iff_of_pos_left hd).1 h2; linarith
    rcases mul_eq_zero.1 h3 with h | h
    · rw [max_eq_left (by linarith)]; linarith
    · rcases mul_eq_zero.1 h with h | h
      · linarith
      · rw [max_eq_right (by linarith)]; linarith
  · intro h
    refine ⟨h ▸ le_max_left _ _, ?_, ?_⟩
    · exact mul_nonneg hd.le (by rw [h]; linarith [le_max_right (g i) r])
    · rcases max_choice (g i) r with hm | hm
      · rw [hm] at h; rw [h]; ring
      · rw [hm] at h; rw [h]; ring

theorem fixed_relaxed {n : ℕ} (d ℓ u ω : ℝ) (hd : 0 < d) (hω : 0 < ω) (b g x : Fin n → ℝ)
    (hx : ∀ i, x i = max (g i) ((b i + ℓ * below x i + u * above x i) / d)) (i : Fin n) :
    x i = max (g i) ((1 - ω) * x i + ω / d * (b i + ℓ * below x i + u * above x i)) := by
  have e : ω / d * (b i + ℓ * below x i + u * above x i)
      = ω * ((b i + ℓ * below x i + u * above x i) / d) := by field_simp
  rw [e]
  set r := (b i + ℓ * below x i + u * above x i) / d
  have h := hx i
  rcases le_total r (g i) with hr | hr
  · rw [max_eq_left hr] at h
    rw [h, max_eq_left]; nlinarith
  · rw [max_eq_right hr] at h
    rw [h, max_eq_right]
    · ring
    · nlinarith

theorem sweep_err {n : ℕ} (d ℓ u ω : ℝ) (hd : 0 < d) (hω : 0 < ω) (hℓ : 0 ≤ ℓ) (hu : 0 ≤ u)
    (hρ : |1 - ω| + ω * ((ℓ + u) / d) ≤ 1)
    (b g x y : Fin n → ℝ)
    (hx : ∀ i, x i = max (g i) ((b i + ℓ * below x i + u * above x i) / d))
    {E : ℝ} (hE : 0 ≤ E) (hy : ∀ i, |y i - x i| ≤ E) :
    ∀ k (hk : k < n), |sweepAux d ℓ u ω b g y k - x ⟨k, hk⟩|
      ≤ (|1 - ω| + ω * ((ℓ + u) / d)) * E := by
  have hvx : ∀ j, |val y j - val x j| ≤ E := val_sub_le y x hE hy
  intro k
  induction k with
  | zero =>
    intro hk
    rw [fixed_relaxed d ℓ u ω hd hω b g x hx ⟨0, hk⟩]
    simp only [sweepAux, hk, ↓reduceDIte]
    refine (abs_max_left_sub_le _ _ _).trans ?_
    have e : (1 - ω) * y ⟨0, hk⟩ + ω / d * (b ⟨0, hk⟩ + ℓ * 0 + u * val y 1)
        - ((1 - ω) * x ⟨0, hk⟩ + ω / d * (b ⟨0, hk⟩ + ℓ * below x ⟨0, hk⟩ + u * above x ⟨0, hk⟩))
        = (1 - ω) * (y ⟨0, hk⟩ - x ⟨0, hk⟩) + ω / d * (ℓ * 0 + u * (val y 1 - val x 1)) := by
      simp [below, above]; ring
    rw [e]
    exact comb_le ω d ℓ u _ _ _ E hd hω.le hℓ hu (hy _) (by simpa using hE) (hvx 1)
  | succ k ih =>
    intro hk
    have hk' : k < n := by omega
    have ihk := ih hk'
    rw [fixed_relaxed d ℓ u ω hd hω b g x hx ⟨k + 1, hk⟩]
    simp only [sweepAux, hk, ↓reduceDIte]
    refine (abs_max_left_sub_le _ _ _).trans ?_
    have hb : below x ⟨k + 1, hk⟩ = x ⟨k, hk'⟩ := by simp [below, val, hk']
    have e : (1 - ω) * y ⟨k + 1, hk⟩ + ω / d * (b ⟨k + 1, hk⟩
          + ℓ * sweepAux d ℓ u ω b g y k + u * val y (k + 2))
        - ((1 - ω) * x ⟨k + 1, hk⟩ + ω / d * (b ⟨k + 1, hk⟩ + ℓ * below x ⟨k + 1, hk⟩
          + u * above x ⟨k + 1, hk⟩))
        = (1 - ω) * (y ⟨k + 1, hk⟩ - x ⟨k + 1, hk⟩) + ω / d * (ℓ * (sweepAux d ℓ u ω b g y k
          - x ⟨k, hk'⟩) + u * (val y (k + 2) - val x (k + 2))) := by
      rw [hb]; simp only [above]; ring
    rw [e]
    have hρE : (|1 - ω| + ω * ((ℓ + u) / d)) * E ≤ E := by nlinarith
    exact comb_le ω d ℓ u _ _ _ E hd hω.le hℓ hu (hy _) (ihk.trans hρE) (hvx _)

/-- The card's main claim: on a well-behaved band (both side weights non-negative and the
diagonal larger than their sum), the three conditions "every value clears its floor, no row's
slack is negative, and one of the two is tight at every node" have exactly one solution, for
every number of nodes, every right-hand side and every floor. -/
theorem lcp_exists_unique_of_diagonal_dominant
    (n : ℕ) (d ℓ u : ℝ) (hℓ : 0 ≤ ℓ) (hu : 0 ≤ u) (hd : ℓ + u < d)
    (b g : Fin n → ℝ) :
    ∃! x : Fin n → ℝ, IsLCP d ℓ u b g x := by
  have hd0 : 0 < d := by linarith
  have hκ0 : 0 ≤ (ℓ + u) / d := div_nonneg (by linarith) hd0.le
  have hκ1 : (ℓ + u) / d < 1 := (div_lt_one hd0).2 hd
  let f : (Fin n → ℝ) → (Fin n → ℝ) :=
    fun x i => max (g i) ((b i + ℓ * below x i + u * above x i) / d)
  have hc : ContractingWith (Real.toNNReal ((ℓ + u) / d)) f := by
    refine ⟨Real.toNNReal_lt_one.2 hκ1, LipschitzWith.of_dist_le_mul fun x y => ?_⟩
    rw [Real.coe_toNNReal _ hκ0]
    refine (dist_pi_le_iff (mul_nonneg hκ0 dist_nonneg)).2 fun i => ?_
    rw [Real.dist_eq]
    refine (abs_max_left_sub_le _ _ _).trans ?_
    exact row_sub_le d ℓ u hd0 hℓ hu b x y dist_nonneg
      (fun j => by rw [← Real.dist_eq]; exact dist_le_pi_dist x y j) i
  have key : ∀ x, IsLCP d ℓ u b g x ↔ Function.IsFixedPt f x := by
    intro x
    rw [lcp_iff_aux n d ℓ u hd0 b g x, Function.IsFixedPt, funext_iff]
    exact forall_congr' fun i => eq_comm
  exact ⟨ContractingWith.fixedPoint f hc, (key _).2 hc.fixedPoint_isFixedPt,
    fun y hy => hc.fixedPoint_unique ((key y).1 hy)⟩

/-- Step 2: with a positive diagonal, a list of values solves the complementarity problem
exactly when every node equals the larger of its floor and its row value
`(b_i + ℓ x_{i-1} + u x_{i+1}) / d`. -/
theorem lcp_iff_fixed_point_of_max
    (n : ℕ) (d ℓ u : ℝ) (hd : 0 < d) (b g x : Fin n → ℝ) :
    IsLCP d ℓ u b g x ↔
      ∀ i, x i = max (g i) ((b i + ℓ * below x i + u * above x i) / d) := by
  exact lcp_iff_aux n d ℓ u hd b g x

/-- Step 3: on a well-behaved band, with the relaxation weight strictly inside
`0 < ω < 2/(1 + κ₀)`, `κ₀ = (ℓ + u)/d`, repeated projected SOR sweeps from any start that
clears the floors converge to the solution of the complementarity problem. -/
theorem psor_tendsto_lcp_solution
    (n : ℕ) (d ℓ u ω : ℝ) (hℓ : 0 ≤ ℓ) (hu : 0 ≤ u) (hd : ℓ + u < d)
    (hω0 : 0 < ω) (hω2 : ω < 2 / (1 + (ℓ + u) / d))
    (b g x₀ x : Fin n → ℝ) (hx₀ : ∀ i, g i ≤ x₀ i) (hx : IsLCP d ℓ u b g x) :
    Tendsto (fun k : ℕ => (psorSweep d ℓ u ω b g)^[k] x₀) atTop (𝓝 x) := by
  have hd0 : 0 < d := by linarith
  have hκ0 : 0 ≤ (ℓ + u) / d := div_nonneg (by linarith) hd0.le
  have hκ1 : (ℓ + u) / d < 1 := (div_lt_one hd0).2 hd
  have hω2' : ω * (1 + (ℓ + u) / d) < 2 := by
    have := (lt_div_iff₀ (by linarith : (0:ℝ) < 1 + (ℓ + u) / d)).1 hω2; linarith
  have hρ1 : |1 - ω| + ω * ((ℓ + u) / d) < 1 := by
    rcases le_total ω 1 with h | h
    · rw [abs_of_nonneg (by linarith)]; nlinarith
    · rw [abs_of_nonpos (by linarith)]; nlinarith
  have hρ0 : 0 ≤ |1 - ω| + ω * ((ℓ + u) / d) := add_nonneg (abs_nonneg _) (mul_nonneg hω0.le hκ0)
  have hfix := (lcp_iff_aux n d ℓ u hd0 b g x).1 hx
  have hE0n : 0 ≤ ∑ i, |x₀ i - x i| := Finset.sum_nonneg fun i _ => abs_nonneg _
  have bound : ∀ m : ℕ, ∀ i, |(psorSweep d ℓ u ω b g)^[m] x₀ i - x i|
      ≤ (|1 - ω| + ω * ((ℓ + u) / d)) ^ m * ∑ i, |x₀ i - x i| := by
    intro m
    induction m with
    | zero =>
      intro i
      simpa using Finset.single_le_sum (f := fun i => |x₀ i - x i|)
        (fun j _ => abs_nonneg _) (Finset.mem_univ i)
    | succ m ih =>
      intro i
      rw [Function.iterate_succ_apply']
      have := sweep_err d ℓ u ω hd0 hω0 hℓ hu hρ1.le b g x _ hfix
        (mul_nonneg (pow_nonneg hρ0 m) hE0n) ih i.val i.isLt
      calc |psorSweep d ℓ u ω b g ((psorSweep d ℓ u ω b g)^[m] x₀) i - x i|
          = |sweepAux d ℓ u ω b g ((psorSweep d ℓ u ω b g)^[m] x₀) i.val - x ⟨i.val, i.isLt⟩| :=
            rfl
        _ ≤ _ := this
        _ = _ := by ring
  rw [tendsto_pi_nhds]
  intro i
  rw [tendsto_iff_dist_tendsto_zero]
  have hlim : Tendsto (fun m : ℕ => (|1 - ω| + ω * ((ℓ + u) / d)) ^ m * ∑ i, |x₀ i - x i|)
      atTop (𝓝 0) := by
    simpa using (tendsto_pow_atTop_nhds_zero_of_lt_one hρ0 hρ1).mul_const (∑ i, |x₀ i - x i|)
  refine squeeze_zero (fun m => dist_nonneg) (fun m => ?_) hlim
  rw [Real.dist_eq]; exact bound m i

/-! The card's exact worked cases. -/

-- Step 1: the waiting equations 3 x1 - x2 = 0 and -x1 + 3 x2 = 3 with floors 1 and 0.
-- The true answer is (1, 4/3), with slacks 5/3 and 0.
example : IsLCP (n := 2) 3 1 1 ![0, 3] ![1, 0] ![1, 4 / 3] := by
  refine Fin.forall_fin_two.2 ⟨?_, ?_⟩ <;> norm_num [slack, below, above, val]

example : slack (n := 2) 3 1 1 ![0, 3] ![1, 4 / 3] 0 = 5 / 3 ∧
    slack (n := 2) 3 1 1 ![0, 3] ![1, 4 / 3] 1 = 0 := by
  norm_num [slack, below, above, val]

-- Step 1: the free solve (3/8, 9/8) falls through the first floor, and lifting it to
-- (1, 9/8) leaves the second row's slack at -5/8, so the lifted pair is no solution.
example : slack (n := 2) 3 1 1 ![0, 3] ![3 / 8, 9 / 8] 0 = 0 ∧
    slack (n := 2) 3 1 1 ![0, 3] ![3 / 8, 9 / 8] 1 = 0 := by
  norm_num [slack, below, above, val]

example : slack (n := 2) 3 1 1 ![0, 3] ![1, 9 / 8] 1 = -5 / 8 ∧
    ¬ IsLCP (n := 2) 3 1 1 ![0, 3] ![1, 0] ![1, 9 / 8] := by
  refine ⟨by norm_num [slack, below, above, val], fun h => ?_⟩
  have := (h 1).2.1
  norm_num [slack, below, above, val] at this

-- Step 4: one node, diagonal 1, right-hand side 0, floor 1, value 2, ω = 3/2.
-- The rule gives 1; projecting before relaxing gives 1/2, under the floor.
example : psorSweep (n := 1) 1 0 0 (3 / 2) ![0] ![1] ![2] 0 = 1 := by
  norm_num [psorSweep, sweepAux, val]

example : (1 - (3 / 2 : ℝ)) * 2 + 3 / 2 * max 1 ((0 : ℝ) / 1) = 1 / 2 := by
  norm_num

-- Step 4: one node, diagonal 1, right-hand side 1, floor 0, at the excluded weight ω = 2,
-- the sweep sends 0 to 2 and 2 back to 0, for ever.
example : psorSweep (n := 1) 1 0 0 2 ![1] ![0] ![0] = ![2] ∧
    psorSweep (n := 1) 1 0 0 2 ![1] ![0] ![2] = ![0] := by
  constructor <;> (funext i; fin_cases i; norm_num [psorSweep, sweepAux, val])

end AmericanLCP

open AmericanLCP

#print axioms lcp_exists_unique_of_diagonal_dominant
#print axioms lcp_iff_fixed_point_of_max
#print axioms psor_tendsto_lcp_solution
#print axioms abs_max_left_sub_le
#print axioms val_sub_le
#print axioms below_sub_le
#print axioms above_sub_le
#print axioms comb_le
#print axioms row_sub_le
#print axioms lcp_iff_aux
#print axioms fixed_relaxed
#print axioms sweep_err
