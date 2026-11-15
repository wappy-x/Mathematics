-- Metric space: in every metric space a distance d(x, z) lies between |d(x, y) - d(y, z)| and d(x, y) + d(y, z), and walking and straight-line distance on the city grid both obey the three rules.
import Mathlib.Topology.MetricSpace.Defs
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Data.ZMod.Defs
import Mathlib.Data.Int.Interval
import Mathlib.Tactic.NormNum

/-- Minkowski's inequality in the plane: the straight line beats two legs. -/
theorem plane_sqrt_triangle (c d e f : ℝ) :
    Real.sqrt ((c + e) ^ 2 + (d + f) ^ 2) ≤
      Real.sqrt (c ^ 2 + d ^ 2) + Real.sqrt (e ^ 2 + f ^ 2) := by
  have hP : 0 ≤ c ^ 2 + d ^ 2 := by positivity
  have hQ : 0 ≤ e ^ 2 + f ^ 2 := by positivity
  have hCS : c * e + d * f ≤ Real.sqrt (c ^ 2 + d ^ 2) * Real.sqrt (e ^ 2 + f ^ 2) := by
    rw [← Real.sqrt_mul hP]
    refine le_trans (le_abs_self _) (Real.abs_le_sqrt ?_)
    nlinarith [sq_nonneg (c * f - d * e)]
  rw [Real.sqrt_le_iff]
  refine ⟨by positivity, ?_⟩
  have h1 := Real.sq_sqrt hP
  have h2 := Real.sq_sqrt hQ
  nlinarith [h1, h2, hCS]

/-- The two-sided bound. In any metric space, if you know how far x and z each are from a third
point y, their own distance is at least the difference of the two and at most their sum:
|d(x, y) - d(y, z)| ≤ d(x, z) ≤ d(x, y) + d(y, z). -/
theorem metric_two_sided_bound {X : Type*} [MetricSpace X] (x y z : X) :
    |dist x y - dist y z| ≤ dist x z ∧ dist x z ≤ dist x y + dist y z := by
  refine ⟨?_, dist_triangle x y z⟩
  rw [abs_sub_le_iff]
  constructor
  · linarith [dist_triangle x z y, dist_comm z y]
  · linarith [dist_triangle y x z, dist_comm x y]

/-- Walking distance on the city grid: a corner is (blocks east, blocks north) of home, and the
walk is the east-west blocks plus the north-south blocks. -/
def walk (p q : ℤ × ℤ) : ℤ := |p.1 - q.1| + |p.2 - q.2|

/-- Straight-line distance between two corners, by Pythagoras. -/
noncomputable def line (p q : ℤ × ℤ) : ℝ :=
  Real.sqrt (((p.1 - q.1 : ℤ) : ℝ) ^ 2 + ((p.2 - q.2 : ℤ) : ℝ) ^ 2)

/-- Walking distance is a metric on the corners of the city grid: it is zero exactly for the same
corner, it reads the same both ways, and a stop on the way never makes the walk shorter. -/
theorem walking_distance_obeys_three_rules :
    (∀ x y : ℤ × ℤ, walk x y = 0 ↔ x = y) ∧
    (∀ x y : ℤ × ℤ, walk x y = walk y x) ∧
    (∀ x y z : ℤ × ℤ, walk x z ≤ walk x y + walk y z) := by
  refine ⟨?_, ?_, ?_⟩
  · intro x y
    unfold walk
    constructor
    · intro h
      have ha := abs_nonneg (x.1 - y.1)
      have hb := abs_nonneg (x.2 - y.2)
      have h1 : |x.1 - y.1| = 0 := by linarith
      have h2 : |x.2 - y.2| = 0 := by linarith
      rw [abs_eq_zero, sub_eq_zero] at h1 h2
      exact Prod.ext h1 h2
    · rintro rfl
      simp
  · intro x y
    unfold walk
    rw [abs_sub_comm x.1, abs_sub_comm x.2]
  · intro x y z
    unfold walk
    linarith [abs_sub_le x.1 y.1 z.1, abs_sub_le x.2 y.2 z.2]

/-- Straight-line distance is a metric on the corners of the city grid: it is zero exactly for the
same corner, it reads the same both ways, and a stop on the way never makes the line shorter. -/
theorem straight_line_obeys_three_rules :
    (∀ x y : ℤ × ℤ, line x y = 0 ↔ x = y) ∧
    (∀ x y : ℤ × ℤ, line x y = line y x) ∧
    (∀ x y z : ℤ × ℤ, line x z ≤ line x y + line y z) := by
  refine ⟨?_, ?_, ?_⟩
  · intro x y
    unfold line
    rw [Real.sqrt_eq_zero']
    constructor
    · intro h
      have ha := sq_nonneg (((x.1 - y.1 : ℤ) : ℝ))
      have hb := sq_nonneg (((x.2 - y.2 : ℤ) : ℝ))
      have h1 : (((x.1 - y.1 : ℤ) : ℝ)) ^ 2 = 0 := by linarith
      have h2 : (((x.2 - y.2 : ℤ) : ℝ)) ^ 2 = 0 := by linarith
      rw [pow_eq_zero_iff two_ne_zero, Int.cast_eq_zero, sub_eq_zero] at h1 h2
      exact Prod.ext h1 h2
    · rintro rfl
      simp
  · intro x y
    unfold line
    congr 1
    push_cast
    ring
  · intro x y z
    unfold line
    have h := plane_sqrt_triangle (((x.1 - y.1 : ℤ) : ℝ)) (((x.2 - y.2 : ℤ) : ℝ))
      (((y.1 - z.1 : ℤ) : ℝ)) (((y.2 - z.2 : ℤ) : ℝ))
    have e1 : (((x.1 - z.1 : ℤ) : ℝ)) = ((x.1 - y.1 : ℤ) : ℝ) + ((y.1 - z.1 : ℤ) : ℝ) := by
      push_cast; ring
    have e2 : (((x.2 - z.2 : ℤ) : ℝ)) = ((x.2 - y.2 : ℤ) : ℝ) + ((y.2 - z.2 : ℤ) : ℝ) := by
      push_cast; ring
    rw [e1, e2]
    exact h

/-- Squared straight-line distance, the candidate that fails rule 3. -/
def lineSq (p q : ℤ × ℤ) : ℤ := (p.1 - q.1) ^ 2 + (p.2 - q.2) ^ 2

/-- East-west blocks only, the candidate that fails rule 1. -/
def eastWest (p q : ℤ × ℤ) : ℤ := |p.1 - q.1|

/-- One-way driving round a block of four corners, clockwise: the candidate that fails rule 2. -/
def drive (p q : ZMod 4) : ℕ := (q - p).val

-- Home (0, 0) to the café (3, 4): 7 blocks on foot, 5 as the crow flies.
example : walk (0, 0) (3, 4) = 7 := by decide
example : lineSq (0, 0) (3, 4) = 25 := by decide
example : line (0, 0) (3, 4) = 5 := by
  unfold line
  rw [show (((0 : ℤ) - 3 : ℤ) : ℝ) ^ 2 + (((0 : ℤ) - 4 : ℤ) : ℝ) ^ 2 = (5 : ℝ) ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)
-- Stopping at the turn (3, 0) is free for the walk: 3 + 4 = 7.
example : walk (0, 0) (3, 0) + walk (3, 0) (3, 4) = walk (0, 0) (3, 4) := by decide
-- 35 shortest walks: choose which 3 of the 7 blocks go east.
example : Nat.choose 7 3 = 35 := by decide
-- 20 of the 36 corners of the 6 by 6 grid are free stops for the walk.
example : ((Finset.Icc (0 : ℤ) 5 ×ˢ Finset.Icc (0 : ℤ) 5).filter
    (fun y => walk (0, 0) y + walk y (3, 4) = walk (0, 0) (3, 4))).card = 20 := by decide
-- 36 corners give 36 ^ 2 = 1296 pairs and 36 ^ 3 = 46656 triples.
example : 36 ^ 2 = 1296 ∧ 36 ^ 3 = 46656 := by decide
-- Squared distance fails rule 3 on one street: 4 direct against 1 + 1 via the middle corner.
example : lineSq (0, 0) (0, 2) = 4 ∧ lineSq (0, 0) (0, 1) + lineSq (0, 1) (0, 2) = 2 ∧
    ¬ (lineSq (0, 0) (0, 2) ≤ lineSq (0, 0) (0, 1) + lineSq (0, 1) (0, 2)) := by decide
-- East-west blocks only fails rule 1: two different corners come out 0 apart.
example : eastWest (0, 0) (0, 1) = 0 ∧ ((0, 0) : ℤ × ℤ) ≠ (0, 1) := by decide
-- One-way driving fails rule 2: A to B is 1 block, back is 3; the lower bound then puts A at
-- least 2 from itself, yet A to A is 0.
example : drive 0 1 = 1 ∧ drive 1 0 = 3 ∧ drive 0 0 = 0 := by decide
example : |((drive 0 1 : ℤ) - (drive 1 0 : ℤ))| = 2 := by decide
-- Ana 7 blocks and Ben 3 blocks from the park: the bound is 4 to 10 blocks.
example : |(7 : ℤ) - 3| = 4 ∧ (7 : ℤ) + 3 = 10 := by decide
-- Brute force round the park (0, 0): 28 corners at 7 blocks, 12 at 3 blocks, 336 placings.
example : ((Finset.Icc (-10 : ℤ) 10 ×ˢ Finset.Icc (-10 : ℤ) 10).filter
    (fun p => walk p (0, 0) = 7)).card = 28 := by decide
example : ((Finset.Icc (-10 : ℤ) 10 ×ˢ Finset.Icc (-10 : ℤ) 10).filter
    (fun p => walk p (0, 0) = 3)).card = 12 := by decide
example : 28 * 12 = 336 := by decide
-- Both ends of the bound really happen: Ana at (7, 0), Ben at (3, 0) or at (-3, 0).
example : walk (7, 0) (0, 0) = 7 ∧ walk (3, 0) (0, 0) = 3 ∧ walk (-3, 0) (0, 0) = 3 ∧
    walk (7, 0) (3, 0) = 4 ∧ walk (7, 0) (-3, 0) = 10 := by decide
-- Ben also 7 out: the bound is 0 to 14.
example : |(7 : ℤ) - 7| = 0 ∧ (7 : ℤ) + 7 = 14 := by decide
-- Dropping the bars in the lower bound: 3 - 7 = -4 says nothing.
example : (3 : ℤ) - 7 = -4 := by decide

#print axioms plane_sqrt_triangle
#print axioms metric_two_sided_bound
#print axioms walking_distance_obeys_three_rules
#print axioms straight_line_obeys_three_rules
