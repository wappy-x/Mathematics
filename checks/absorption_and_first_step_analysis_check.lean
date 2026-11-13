-- Absorption: in a finite absorbing chain where every transient square can reach a trap, the fundamental matrix N = (I - Q)⁻¹ = I + Q + Q² + ⋯ exists, the first-step equations have exactly one solution N c, the trap chances add to 1, the game ends fast, and the card's board numbers check out.
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Topology.Instances.Matrix
import Mathlib.Topology.Algebra.InfiniteSum.Basic
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Data.Matrix.Mul
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Topology.Algebra.InfiniteSum.Real
import Mathlib.LinearAlgebra.Matrix.ToLinearEquiv
import Mathlib.Algebra.Ring.GeomSum

namespace AbsorptionAndFirstStepAnalysis

open Matrix

/-! Setting. `T` is the finite set of transient squares and `A` the finite set of absorbing
states (traps). `Q i j` is the chance that one turn moves square `i` to square `j`, and `R i a`
the chance that one turn moves square `i` straight into trap `a`. Each row of chances is
non-negative and adds to 1. The same `Q` and `R` serve every turn: the same die, nothing
remembered. `(Q ^ n * R) i a` is the chance of staying on transient squares for `n` turns
and then stepping into `a`, so "every transient square can reach a trap" says that for
each `i` this is positive for some `n` and some `a`. The row sum `∑ j, (Q ^ n) i j` is the
chance that the game is still running after `n` turns. -/

variable {T A : Type*} [Fintype T] [DecidableEq T] [Fintype A]

section Helpers

open Filter Topology

theorem helper_pow_nonneg (Q : Matrix T T ℝ) (hQ : ∀ i j, 0 ≤ Q i j) :
    ∀ n i j, 0 ≤ (Q ^ n) i j := by
  intro n
  induction n with
  | zero => intro i j; simp [Matrix.one_apply]; split_ifs <;> norm_num
  | succ n ih =>
    intro i j
    rw [pow_succ, Matrix.mul_apply]
    exact Finset.sum_nonneg fun l _ => mul_nonneg (ih i l) (hQ l j)

theorem helper_powR_nonneg (Q : Matrix T T ℝ) (R : Matrix T A ℝ)
    (hQ : ∀ i j, 0 ≤ Q i j) (hR : ∀ i a, 0 ≤ R i a) :
    ∀ (n : ℕ) i a, 0 ≤ (Q ^ n * R) i a := by
  intro n i a
  rw [Matrix.mul_apply]
  exact Finset.sum_nonneg fun l _ => mul_nonneg (helper_pow_nonneg Q hQ n i l) (hR l a)

theorem helper_rowsum_succ (Q : Matrix T T ℝ) (R : Matrix T A ℝ)
    (hrow : ∀ i, ∑ j, Q i j + ∑ a, R i a = 1) (n : ℕ) (i : T) :
    ∑ j, (Q ^ (n + 1)) i j = ∑ j, (Q ^ n) i j - ∑ a, (Q ^ n * R) i a := by
  simp only [pow_succ, Matrix.mul_apply]
  rw [Finset.sum_comm]
  simp_rw [← Finset.mul_sum]
  have h : ∀ l, ∑ j, Q l j = 1 - ∑ a, R l a := fun l => by linarith [hrow l]
  simp_rw [h, mul_sub, mul_one, Finset.sum_sub_distrib, Finset.mul_sum]
  rw [Finset.sum_comm (f := fun x y => (Q ^ n) i x * R x y)]

theorem helper_rowsum_antitone (Q : Matrix T T ℝ) (R : Matrix T A ℝ)
    (hQ : ∀ i j, 0 ≤ Q i j) (hR : ∀ i a, 0 ≤ R i a)
    (hrow : ∀ i, ∑ j, Q i j + ∑ a, R i a = 1) (i : T) :
    Antitone (fun n => ∑ j, (Q ^ n) i j) := by
  apply antitone_nat_of_succ_le
  intro n
  rw [helper_rowsum_succ Q R hrow n i]
  have := Finset.sum_nonneg fun a (_ : a ∈ Finset.univ) => helper_powR_nonneg Q R hQ hR n i a
  linarith

theorem helper_rowsum_le_one (Q : Matrix T T ℝ) (R : Matrix T A ℝ)
    (hQ : ∀ i j, 0 ≤ Q i j) (hR : ∀ i a, 0 ≤ R i a)
    (hrow : ∀ i, ∑ j, Q i j + ∑ a, R i a = 1) (n : ℕ) (i : T) :
    ∑ j, (Q ^ n) i j ≤ 1 := by
  have := helper_rowsum_antitone Q R hQ hR hrow i (Nat.zero_le n)
  simp only [pow_zero, Matrix.one_apply, Finset.sum_ite_eq, Finset.mem_univ, ite_true] at this
  exact this

theorem helper_block (Q : Matrix T T ℝ) (R : Matrix T A ℝ)
    (hQ : ∀ i j, 0 ≤ Q i j) (hR : ∀ i a, 0 ≤ R i a)
    (hrow : ∀ i, ∑ j, Q i j + ∑ a, R i a = 1)
    (hreach : ∀ i, ∃ n : ℕ, ∃ a, 0 < (Q ^ n * R) i a) :
    ∃ m : ℕ, ∃ η : ℝ, 0 < m ∧ 0 < η ∧ η ≤ 1 ∧ ∀ i, ∑ j, (Q ^ m) i j ≤ 1 - η := by
  choose nn aa hpos using hreach
  let f : T → ℝ := fun i => (Q ^ nn i * R) i (aa i)
  have hη : ∃ η : ℝ, 0 < η ∧ η ≤ 1 ∧ ∀ i, η ≤ f i := by
    by_cases hT : Nonempty T
    · obtain ⟨i0, -, hmin⟩ := Finset.exists_min_image Finset.univ f Finset.univ_nonempty
      exact ⟨min (f i0) 1, lt_min (hpos i0) one_pos, min_le_right _ _,
        fun i => (min_le_left _ _).trans (hmin i (Finset.mem_univ _))⟩
    · exact ⟨1, one_pos, le_rfl, fun i => (hT ⟨i⟩).elim⟩
  obtain ⟨η, hη0, hη1, hηf⟩ := hη
  refine ⟨Finset.univ.sup nn + 1, η, Nat.succ_pos _, hη0, hη1, fun i => ?_⟩
  have hle : nn i + 1 ≤ Finset.univ.sup nn + 1 :=
    Nat.succ_le_succ (Finset.le_sup (Finset.mem_univ i))
  have h1 := helper_rowsum_antitone Q R hQ hR hrow i hle
  have h2 := helper_rowsum_succ Q R hrow (nn i) i
  have h3 := helper_rowsum_le_one Q R hQ hR hrow (nn i) i
  have h4 : f i ≤ ∑ a, (Q ^ nn i * R) i a :=
    Finset.single_le_sum (fun a _ => helper_powR_nonneg Q R hQ hR (nn i) i a) (Finset.mem_univ (aa i))
  have h5 := hηf i
  simp only at h1
  linarith

theorem helper_geometric (Q : Matrix T T ℝ) (hQ : ∀ i j, 0 ≤ Q i j) (m : ℕ) (η : ℝ)
    (hη1 : η ≤ 1) (hm : ∀ i, ∑ j, (Q ^ m) i j ≤ 1 - η) :
    ∀ (k : ℕ) i, ∑ j, (Q ^ (k * m)) i j ≤ (1 - η) ^ k := by
  intro k
  induction k with
  | zero => intro i; simp [Matrix.one_apply]
  | succ k ih =>
    intro i
    have e : (k + 1) * m = m + k * m := by ring
    rw [e, pow_add]
    simp only [Matrix.mul_apply]
    rw [Finset.sum_comm]
    simp_rw [← Finset.mul_sum]
    calc ∑ l, (Q ^ m) i l * ∑ j, (Q ^ (k * m)) l j
        ≤ ∑ l, (Q ^ m) i l * (1 - η) ^ k :=
          Finset.sum_le_sum fun l _ => mul_le_mul_of_nonneg_left (ih l) (helper_pow_nonneg Q hQ m i l)
      _ = (∑ l, (Q ^ m) i l) * (1 - η) ^ k := by rw [Finset.sum_mul]
      _ ≤ (1 - η) * (1 - η) ^ k :=
          mul_le_mul_of_nonneg_right (hm i) (pow_nonneg (by linarith) _)
      _ = (1 - η) ^ (k + 1) := by ring


theorem helper_tendsto (Q : Matrix T T ℝ) (R : Matrix T A ℝ)
    (hQ : ∀ i j, 0 ≤ Q i j) (hR : ∀ i a, 0 ≤ R i a)
    (hrow : ∀ i, ∑ j, Q i j + ∑ a, R i a = 1)
    (hreach : ∀ i, ∃ n : ℕ, ∃ a, 0 < (Q ^ n * R) i a) (i j : T) :
    Tendsto (fun n : ℕ => (Q ^ n) i j) atTop (𝓝 0) := by
  obtain ⟨m, η, hm, hη0, hη1, hblock⟩ := helper_block Q R hQ hR hrow hreach
  have hgeo := helper_geometric Q hQ m η hη1 hblock
  have hup : Tendsto (fun n : ℕ => (1 - η) ^ (n / m)) atTop (𝓝 0) :=
    (tendsto_pow_atTop_nhds_zero_of_lt_one (by linarith) (by linarith)).comp
      (Nat.tendsto_div_const_atTop hm.ne')
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds hup
    (fun n => helper_pow_nonneg Q hQ n i j) (fun n => ?_)
  calc (Q ^ n) i j ≤ ∑ l, (Q ^ n) i l :=
        Finset.single_le_sum (fun l _ => helper_pow_nonneg Q hQ n i l) (Finset.mem_univ j)
    _ ≤ ∑ l, (Q ^ (n / m * m)) i l :=
        helper_rowsum_antitone Q R hQ hR hrow i (Nat.div_mul_le_self n m)
    _ ≤ (1 - η) ^ (n / m) := hgeo (n / m) i

#print axioms helper_pow_nonneg
#print axioms helper_powR_nonneg
#print axioms helper_rowsum_succ
#print axioms helper_rowsum_antitone
#print axioms helper_rowsum_le_one
#print axioms helper_block
#print axioms helper_geometric
#print axioms helper_tendsto

end Helpers

/-- The card's main result. In a chain with finitely many squares, where every transient square
can reach a trap, the fundamental matrix `N = (I - Q)⁻¹` exists and equals the series
`I + Q + Q² + Q³ + ⋯` (expected visits), and the first-step equations `y = c + Q y` have exactly
one solution, `y = N c`. With `c = 1` this is the expected wait `t = N 1`
(`t_i = 1 + ∑_j q_ij t_j`); with `c` the column of `R` for one trap it is the chance `h = N r`
of ending in that trap (`h_i = r_i + ∑_j q_ij h_j`), so `B = N R`. -/
theorem first_step_equations_have_one_solution (Q : Matrix T T ℝ) (R : Matrix T A ℝ)
    (hQ : ∀ i j, 0 ≤ Q i j) (hR : ∀ i a, 0 ≤ R i a)
    (hrow : ∀ i, ∑ j, Q i j + ∑ a, R i a = 1)
    (hreach : ∀ i, ∃ n : ℕ, ∃ a, 0 < (Q ^ n * R) i a) :
    IsUnit (1 - Q) ∧ HasSum (fun n : ℕ => Q ^ n) (1 - Q)⁻¹ ∧
      ∀ c y : T → ℝ, y = c + Q *ᵥ y ↔ y = (1 - Q)⁻¹ *ᵥ c := by
  have htend := helper_tendsto Q R hQ hR hrow hreach
  have hdet : IsUnit (1 - Q).det := by
    rw [isUnit_iff_ne_zero]
    intro hdet0
    obtain ⟨v, hv0, hv⟩ := Matrix.exists_mulVec_eq_zero_iff.mpr hdet0
    rw [sub_mulVec, one_mulVec, sub_eq_zero] at hv
    have hpow : ∀ n : ℕ, Q ^ n *ᵥ v = v := by
      intro n
      induction n with
      | zero => simp
      | succ n ih => rw [pow_succ', ← mulVec_mulVec, ih, ← hv]
    apply hv0
    funext i
    have h1 : Filter.Tendsto (fun n : ℕ => (Q ^ n *ᵥ v) i) Filter.atTop (nhds 0) := by
      have : Filter.Tendsto (fun n : ℕ => ∑ l, (Q ^ n) i l * v l) Filter.atTop (nhds (∑ l : T, (0 : ℝ) * v l)) :=
        tendsto_finsetSum _ fun l _ => (htend i l).mul_const (v l)
      simpa [mulVec, dotProduct] using this
    simp only [hpow] at h1
    exact tendsto_nhds_unique tendsto_const_nhds h1
  refine ⟨(Matrix.isUnit_iff_isUnit_det _).mpr hdet, ?_, ?_⟩
  · refine Pi.hasSum.mpr fun i => Pi.hasSum.mpr fun j => ?_
    rw [hasSum_iff_tendsto_nat_of_nonneg (fun n => helper_pow_nonneg Q hQ n i j)]
    have heq : ∀ K : ℕ, ∑ n ∈ Finset.range K, Q ^ n = (1 - Q)⁻¹ - Q ^ K * (1 - Q)⁻¹ := by
      intro K
      have h := congrArg (· * (1 - Q)⁻¹) (geom_sum_mul_neg Q K)
      simp only [mul_assoc, mul_nonsing_inv _ hdet, mul_one, sub_mul, one_mul] at h
      exact h
    have heq' : ∀ K : ℕ, ∑ n ∈ Finset.range K, (Q ^ n) i j =
        (1 - Q)⁻¹ i j - ∑ l, (Q ^ K) i l * (1 - Q)⁻¹ l j := by
      intro K
      rw [← Matrix.sum_apply, heq K, Matrix.sub_apply, Matrix.mul_apply]
    simp_rw [heq']
    have : Filter.Tendsto (fun K : ℕ => ∑ l, (Q ^ K) i l * (1 - Q)⁻¹ l j) Filter.atTop
        (nhds (∑ l : T, (0 : ℝ) * (1 - Q)⁻¹ l j)) :=
      tendsto_finsetSum _ fun l _ => (htend i l).mul_const _
    simpa using tendsto_const_nhds.sub this
  · intro c y
    constructor
    · intro h
      have h1 : (1 - Q) *ᵥ y = c := by
        rw [sub_mulVec, one_mulVec]
        exact sub_eq_of_eq_add h
      calc y = ((1 - Q)⁻¹ * (1 - Q)) *ᵥ y := by rw [nonsing_inv_mul _ hdet, one_mulVec]
        _ = (1 - Q)⁻¹ *ᵥ c := by rw [← mulVec_mulVec, h1]
    · intro h
      have h1 : (1 - Q) *ᵥ y = c := by
        rw [h, mulVec_mulVec, mul_nonsing_inv _ hdet, one_mulVec]
      rw [sub_mulVec, one_mulVec] at h1
      exact sub_eq_iff_eq_add.mp h1

/-- Every game ends in some trap: under the same conditions, the chances of ending in each trap,
the row of `B = N R`, add to exactly 1 from every transient square. -/
theorem trap_chances_add_to_one (Q : Matrix T T ℝ) (R : Matrix T A ℝ)
    (hQ : ∀ i j, 0 ≤ Q i j) (hR : ∀ i a, 0 ≤ R i a)
    (hrow : ∀ i, ∑ j, Q i j + ∑ a, R i a = 1)
    (hreach : ∀ i, ∃ n : ℕ, ∃ a, 0 < (Q ^ n * R) i a) (i : T) :
    ∑ a, ((1 - Q)⁻¹ * R) i a = 1 := by
  have hdet : IsUnit (1 - Q).det := (Matrix.isUnit_iff_isUnit_det _).mp
    (first_step_equations_have_one_solution Q R hQ hR hrow hreach).1
  have hR1 : R *ᵥ (1 : A → ℝ) = (1 - Q) *ᵥ (1 : T → ℝ) := by
    funext l
    have := hrow l
    simp only [mulVec, dotProduct, Pi.one_apply, mul_one, Matrix.sub_apply, Matrix.one_apply]
    rw [Finset.sum_sub_distrib]
    simp
    linarith
  have : ((1 - Q)⁻¹ * R) *ᵥ (1 : A → ℝ) = 1 := by
    rw [← mulVec_mulVec, hR1, mulVec_mulVec, nonsing_inv_mul _ hdet, one_mulVec]
  have := congrFun this i
  simpa [mulVec, dotProduct] using this

/-- The game ends, and fast: under the same conditions there is a block length `m` and a floor
`η > 0` such that, from every transient square, the game survives `k` blocks of `m` turns with
chance at most `(1 - η) ^ k`, and the expected wait, the row sum of `N`, is at most `m / η`. -/
theorem game_ends_with_geometric_tail (Q : Matrix T T ℝ) (R : Matrix T A ℝ)
    (hQ : ∀ i j, 0 ≤ Q i j) (hR : ∀ i a, 0 ≤ R i a)
    (hrow : ∀ i, ∑ j, Q i j + ∑ a, R i a = 1)
    (hreach : ∀ i, ∃ n : ℕ, ∃ a, 0 < (Q ^ n * R) i a) :
    ∃ m : ℕ, ∃ η : ℝ, 0 < η ∧
      (∀ i (k : ℕ), ∑ j, (Q ^ (k * m)) i j ≤ (1 - η) ^ k) ∧
      ∀ i, ∑ j, ((1 - Q)⁻¹) i j ≤ m / η := by
  obtain ⟨m, η, hm, hη0, hη1, hblock⟩ := helper_block Q R hQ hR hrow hreach
  have hgeo := helper_geometric Q hQ m η hη1 hblock
  refine ⟨m, η, hη0, fun i k => hgeo k i, fun i => ?_⟩
  have hsum := (first_step_equations_have_one_solution Q R hQ hR hrow hreach).2.1
  have hent : ∀ j, HasSum (fun n : ℕ => (Q ^ n) i j) ((1 - Q)⁻¹ i j) := fun j =>
    Pi.hasSum.mp (Pi.hasSum.mp hsum i) j
  have hrs : HasSum (fun n : ℕ => ∑ j, (Q ^ n) i j) (∑ j, (1 - Q)⁻¹ i j) :=
    hasSum_sum fun j _ => hent j
  rw [← hrs.tsum_eq]
  have hnn : ∀ n : ℕ, 0 ≤ ∑ j, (Q ^ n) i j := fun n =>
    Finset.sum_nonneg fun j _ => helper_pow_nonneg Q hQ n i j
  have hblocks : ∀ k : ℕ, ∑ n ∈ Finset.range (k * m), ∑ j, (Q ^ n) i j ≤
      m * ∑ r ∈ Finset.range k, (1 - η) ^ r := by
    intro k
    induction k with
    | zero => simp
    | succ k ih =>
      rw [show (k + 1) * m = k * m + m by ring, Finset.sum_range_add, Finset.sum_range_succ,
        mul_add]
      have : ∑ x ∈ Finset.range m, ∑ j, (Q ^ (k * m + x)) i j ≤ m * (1 - η) ^ k := by
        calc ∑ x ∈ Finset.range m, ∑ j, (Q ^ (k * m + x)) i j
            ≤ ∑ x ∈ Finset.range m, (1 - η) ^ k :=
              Finset.sum_le_sum fun x _ =>
                (helper_rowsum_antitone Q R hQ hR hrow i (Nat.le_add_right (k * m) x)).trans
                  (hgeo k i)
          _ = m * (1 - η) ^ k := by simp
      linarith
  have hgeom : ∀ k : ℕ, (m : ℝ) * ∑ r ∈ Finset.range k, (1 - η) ^ r ≤ m / η := by
    intro k
    have h := geom_sum_mul_neg (1 - η) k
    rw [sub_sub_cancel] at h
    have hp : 0 ≤ (1 - η) ^ k := pow_nonneg (by linarith) k
    have hm0 : (0 : ℝ) ≤ m := Nat.cast_nonneg m
    rw [le_div_iff₀ hη0, mul_assoc, h]
    nlinarith
  apply Real.tsum_le_of_sum_range_le hnn
  intro K
  calc ∑ n ∈ Finset.range K, ∑ j, (Q ^ n) i j
      ≤ ∑ n ∈ Finset.range (K * m), ∑ j, (Q ^ n) i j :=
        Finset.sum_le_sum_of_subset_of_nonneg
          (Finset.range_subset_range.mpr (Nat.le_mul_of_pos_right K hm)) (fun n _ _ => hnn n)
    _ ≤ m * ∑ r ∈ Finset.range K, (1 - η) ^ r := hblocks K
    _ ≤ m / η := hgeom K

/-! The card's board. Resting squares 0, 1, 2, 4, 5, 6, 7, 9 are indices 0 to 7; the finish is
the one trap. Entries are counts of die faces, divided by 6. -/

/-- Moves between resting squares on the house board (ladder 3 → 7, snake 8 → 2). -/
def boardQ : Matrix (Fin 8) (Fin 8) ℚ := (1 / 6 : ℚ) •
  !![0, 1, 1, 1, 1, 1, 1, 0;
     0, 0, 1, 1, 1, 1, 2, 0;
     0, 0, 1, 1, 1, 1, 2, 0;
     0, 0, 1, 0, 1, 1, 1, 1;
     0, 0, 1, 0, 0, 1, 1, 1;
     0, 0, 1, 0, 0, 0, 1, 1;
     0, 0, 1, 0, 0, 0, 0, 1;
     0, 0, 0, 0, 0, 0, 0, 0]

/-- One-turn chances of reaching or passing 10. -/
def finishR : Matrix (Fin 8) (Fin 1) ℚ := (1 / 6 : ℚ) • !![0; 0; 0; 1; 2; 3; 4; 6]

/-- The second chain: the snake's head 8 made a trap, so no move slides back to 2. -/
def snakeQ : Matrix (Fin 8) (Fin 8) ℚ := (1 / 6 : ℚ) •
  !![0, 1, 1, 1, 1, 1, 1, 0;
     0, 0, 1, 1, 1, 1, 2, 0;
     0, 0, 0, 1, 1, 1, 2, 0;
     0, 0, 0, 0, 1, 1, 1, 1;
     0, 0, 0, 0, 0, 1, 1, 1;
     0, 0, 0, 0, 0, 0, 1, 1;
     0, 0, 0, 0, 0, 0, 0, 1;
     0, 0, 0, 0, 0, 0, 0, 0]

/-- In the second chain, one-turn chances of landing on the snake's head (column 0) and of
finishing (column 1). -/
def snakeR : Matrix (Fin 8) (Fin 2) ℚ := (1 / 6 : ℚ) •
  !![0, 0; 0, 0; 1, 0; 1, 1; 1, 2; 1, 3; 1, 4; 0, 6]

-- The board's rows of chances each add to 1.
example : ∀ i, ∑ j, boardQ i j + ∑ a, finishR i a = 1 := by
  intro i; fin_cases i <;> simp [boardQ, finishR, Fin.sum_univ_succ] <;> norm_num
-- Expected turns, squares 0, 1, 2, 4, 5, 6, 7, 9: they solve t = 1 + Q t, and t at 0 is 110305/30954.
example : (![110305 / 30954, 17023 / 5159, 17023 / 5159, 2009 / 737, 1722 / 737, 1476 / 737,
    8856 / 5159, 1] : Fin 8 → ℚ) =
    1 + boardQ *ᵥ ![110305 / 30954, 17023 / 5159, 17023 / 5159, 2009 / 737, 1722 / 737,
      1476 / 737, 8856 / 5159, 1] := by
  ext i; fin_cases i <;> simp [boardQ] <;> norm_num
-- The chance of meeting the snake before finishing solves h = r + Q' h; from 0 it is 66025/279936.
example : (![66025 / 279936, 10543 / 46656, 2617 / 7776, 343 / 1296, 49 / 216, 7 / 36, 1 / 6, 0] :
    Fin 8 → ℚ) = (fun i => snakeR i 0) +
    snakeQ *ᵥ ![66025 / 279936, 10543 / 46656, 2617 / 7776, 343 / 1296, 49 / 216, 7 / 36, 1 / 6, 0] := by
  ext i; fin_cases i <;> simp [snakeQ, snakeR] <;> norm_num
-- The chance of finishing first solves the same equations with the finish column, and the two add to 1.
example : (![213911 / 279936, 36113 / 46656, 5159 / 7776, 953 / 1296, 167 / 216, 29 / 36, 5 / 6, 1] :
    Fin 8 → ℚ) = (fun i => snakeR i 1) +
    snakeQ *ᵥ ![213911 / 279936, 36113 / 46656, 5159 / 7776, 953 / 1296, 167 / 216, 29 / 36, 5 / 6, 1] := by
  ext i; fin_cases i <;> simp [snakeQ, snakeR] <;> norm_num
example : (66025 / 279936 : ℚ) + 213911 / 279936 = 1 := by norm_num
-- The hand table for the snake chance, from the top down.
example : ((1 / 6 : ℚ) + 1 + 0) / 6 = 7 / 36 := by norm_num
example : ((7 / 36 : ℚ) + 1 / 6 + 1 + 0) / 6 = 49 / 216 := by norm_num
example : ((49 / 216 : ℚ) + 7 / 36 + 1 / 6 + 1 + 0) / 6 = 343 / 1296 := by norm_num
example : ((1 / 6 : ℚ) + 343 / 1296 + 49 / 216 + 7 / 36 + 1 / 6 + 1) / 6 = 2617 / 7776 := by norm_num
example : ((2617 / 7776 : ℚ) + 1 / 6 + 343 / 1296 + 49 / 216 + 7 / 36 + 1 / 6) / 6 = 10543 / 46656 := by
  norm_num
example : ((10543 / 46656 : ℚ) + 2617 / 7776 + 1 / 6 + 343 / 1296 + 49 / 216 + 7 / 36) / 6 =
    66025 / 279936 := by norm_num
-- The hand table for the wait: x = t at 2 = 17023/5159, and t at 0 = 110305/30954.
example : (17023 / 5159 : ℚ) =
    1 + (2 * (8856 / 5159) + 2009 / 737 + 1722 / 737 + 1476 / 737 + 17023 / 5159) / 6 := by norm_num
example : (110305 / 30954 : ℚ) =
    1 + (17023 / 5159 + 17023 / 5159 + 8856 / 5159 + 2009 / 737 + 1722 / 737 + 1476 / 737) / 6 := by
  norm_num
-- Step 1: from every square the chance of finishing within 2 turns is at least 10/36
-- (so every square can reach the finish), and the expected wait is at most 2 × 36/10 = 36/5 turns.
example : ∀ i, (10 / 36 : ℚ) ≤ finishR i 0 + (boardQ * finishR) i 0 := by
  intro i; fin_cases i <;> simp [boardQ, finishR, Matrix.mul_apply, Fin.sum_univ_succ] <;> norm_num
example : (2 : ℚ) * (36 / 10) = 36 / 5 := by norm_num
-- No game ends on turn 1; 5/18 of games (27.78 percent) end on turn 2.
example : finishR 0 0 = 0 ∧ (boardQ * finishR) 0 0 = 5 / 18 := by
  simp [boardQ, finishR, Matrix.mul_apply, Fin.sum_univ_succ]; norm_num

#print axioms first_step_equations_have_one_solution
#print axioms trap_chances_add_to_one
#print axioms game_ends_with_geometric_tail

end AbsorptionAndFirstStepAnalysis
