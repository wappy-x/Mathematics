-- Baire category theorem: in a complete metric space every ball holds a point outside any countable pile of nowhere dense sets, so no list of points fills the metre stick, and the rationals are meagre in the line while the line is not.
import Mathlib.Topology.Baire.CompleteMetrizable
import Mathlib.Topology.Baire.Lemmas
import Mathlib.Topology.GDelta.Basic
import Mathlib.Topology.MetricSpace.Pseudo.Defs
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Data.Nat.Totient
import Mathlib.Tactic.NormNum

open Set Metric

/-- Helper: a single point of the line is nowhere dense. -/
theorem baire_helper_singleton_isNowhereDense (a : ℝ) : IsNowhereDense ({a} : Set ℝ) := by
  rw [isClosed_singleton.isNowhereDense_iff]
  exact interior_singleton a

#print axioms baire_helper_singleton_isNowhereDense

/-- Baire's theorem, as the card states it. Let `X` be a complete metric space (or one whose
distance can be swapped for an equivalent complete distance, one with the same open sets), and let
`A 1, A 2, A 3, ...` be a countable pile of nowhere dense sets: the closure of each one contains
no ball. Then every open ball `B(x, r)` holds a point that lies in none of the pieces. -/
theorem complete_space_ball_has_point_outside_countable_nowhere_dense_pile
    {X : Type*} [MetricSpace X] [TopologicalSpace.IsCompletelyMetrizableSpace X]
    (A : ℕ → Set X) (hA : ∀ n, IsNowhereDense (A n))
    (x : X) (r : ℝ) (hr : 0 < r) :
    ∃ y ∈ ball x r, y ∉ ⋃ n, A n := by
  by_contra h
  push Not at h
  have hsub : ball x r ⊆ ⋃ n, A n := fun y hy => h y hy
  have hm : IsMeagre (⋃ n, A n) := isMeagre_iUnion fun n => (hA n).isMeagre
  exact not_isMeagre_of_isOpen isOpen_ball (nonempty_ball.2 hr) (hm.mono hsub)

/-- Step 5: one countable decomposition ruled out. The metre stick `[0, 1]` is not
`{p 1} ∪ {p 2} ∪ {p 3} ∪ ...` for any list of points `p`: no list holds every point of the
stick. -/
theorem metre_stick_is_not_a_list_of_points (p : ℕ → ℝ) :
    ¬ Icc (0 : ℝ) 1 ⊆ ⋃ n, {p n} := by
  intro h
  obtain ⟨y, hy, hy'⟩ := complete_space_ball_has_point_outside_countable_nowhere_dense_pile
    (fun n => ({p n} : Set ℝ)) (fun n => baire_helper_singleton_isNowhereDense (p n))
    (1 / 2) (1 / 2) (by norm_num)
  apply hy'
  apply h
  rw [Real.ball_eq_Ioo] at hy
  obtain ⟨h1, h2⟩ := hy
  constructor <;> linarith

/-- The card's example: the rationals are meagre in the line (they fit inside a countable pile
of nowhere dense sets), and the line itself is not meagre. -/
theorem rationals_meagre_in_line_and_line_not_meagre :
    IsMeagre (range ((↑) : ℚ → ℝ)) ∧ ¬ IsMeagre (univ : Set ℝ) := by
  constructor
  · have : range ((↑) : ℚ → ℝ) = ⋃ q : ℚ, ({(q : ℝ)} : Set ℝ) := by
      ext y; simp [eq_comm]
    rw [this]
    exact isMeagre_iUnion fun q => (baire_helper_singleton_isNowhereDense (q : ℝ)).isMeagre
  · exact not_isMeagre_of_isOpen isOpen_univ univ_nonempty

-- The queue: 1 + (totients of 1 to 10) = 33 fractions in [0, 1] with denominator up to 10.
example : 1 + ∑ q ∈ Finset.Icc 1 10, Nat.totient q = 33 := by decide
-- The chase by hand: each kept third is a third as long as the one before.
example : (2 : ℚ) / 3 - 1 / 3 = 1 / 3 := by norm_num
example : (4 : ℚ) / 9 - 1 / 3 = 1 / 9 := by norm_num
example : (10 : ℚ) / 27 - 1 / 3 = 1 / 27 := by norm_num
example : (29 : ℚ) / 81 - 28 / 81 = 1 / 81 := by norm_num
example : (85 : ℚ) / 243 - 28 / 81 = 1 / 243 := by norm_num
example : (253 : ℚ) / 729 - 28 / 81 = 1 / 729 := by norm_num
-- Step 4: 1/3 is the left end of [1/3, 10/27], so the chase keeps the middle third, starting at 28/81.
example : (28 : ℚ) / 81 = 1 / 3 + 1 / 81 := by norm_num
-- The six dodged fractions 0, 1, 1/2, 1/3, 2/3, 1/4 all lie outside [28/81, 253/729].
example : ((0 : ℚ) < 28 / 81) ∧ ((1 : ℚ) / 4 < 28 / 81) ∧ ((1 : ℚ) / 3 < 28 / 81) ∧
    ((253 : ℚ) / 729 < 1 / 2) ∧ ((253 : ℚ) / 729 < 2 / 3) ∧ ((253 : ℚ) / 729 < 1) := by norm_num
-- 9/26 is still inside the 1/729 m interval.
example : (28 : ℚ) / 81 ≤ 9 / 26 ∧ (9 : ℚ) / 26 ≤ 253 / 729 := by norm_num
-- Twenty dodges: width 1/3^20 = 1/3486784401 m.
example : (3 : ℕ) ^ 20 = 3486784401 := by norm_num
-- Fat Cantor dust: length left 1/2 + 1/2^(n+1), longest piece 1/2^(n+1) + 1/2^(2n+1).
example : (1 : ℚ) / 2 + 1 / 2 ^ 2 = 3 / 4 ∧ (1 : ℚ) / 2 ^ 2 + 1 / 2 ^ 3 = 3 / 8 := by norm_num
example : (1 : ℚ) / 2 + 1 / 2 ^ 3 = 5 / 8 ∧ (1 : ℚ) / 2 ^ 3 + 1 / 2 ^ 5 = 5 / 32 := by norm_num
example : (1 : ℚ) / 2 + 1 / 2 ^ 4 = 9 / 16 ∧ (1 : ℚ) / 2 ^ 4 + 1 / 2 ^ 7 = 9 / 128 := by norm_num
example : (1 : ℚ) / 2 + 1 / 2 ^ 5 = 17 / 32 ∧ (1 : ℚ) / 2 ^ 5 + 1 / 2 ^ 9 = 17 / 512 := by norm_num
example : (1 : ℚ) / 2 + 1 / 2 ^ 11 = 1025 / 2048 ∧
    (1 : ℚ) / 2 ^ 11 + 1 / 2 ^ 21 = 1025 / 2097152 := by norm_num
-- The gaps cut add up to 1/2: 1/4 + 2/16 + 4/64 + ... through stage 10 leaves 1/2 - 1/2^11.
example : ∑ n ∈ Finset.Icc 1 10, (2 : ℚ) ^ (n - 1) / 4 ^ n = 1 / 2 - 1 / 2 ^ 11 := by
  norm_num [Finset.sum_Icc_succ_top]
-- Ordinary middle thirds keep (2/3)^10 = 1024/59049; half-size gaps keep 3/4 + 1/2^12 = 3073/4096.
example : ((2 : ℚ) / 3) ^ 10 = 1024 / 59049 := by norm_num
example : (3 : ℚ) / 4 + 1 / (4 * 2 ^ 10) = 3073 / 4096 := by norm_num

#print axioms complete_space_ball_has_point_outside_countable_nowhere_dense_pile
#print axioms metre_stick_is_not_a_list_of_points
#print axioms rationals_meagre_in_line_and_line_not_meagre
