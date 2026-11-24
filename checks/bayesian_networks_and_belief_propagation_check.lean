-- Graphical models: for the delivery network with any tables, variable elimination gives exactly the brute-force chance of a breakdown given the alarm, traffic and breakdown are independent when nothing is seen, a sum over a tree's separate branches splits into a product of messages, and the card's whole-number counts are exact.
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Algebra.BigOperators.Group.Finset.Sigma
import Mathlib.Data.Fintype.Pi
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Finset

/-- Variable elimination is exact (the card's main claim, Step 3). Take the delivery network
T → L ← B, L → A, with the joint chance P(t, b, l, a) = P(t) P(b) P(l | t, b) P(a | l), for any
finite sets of values and any tables. Fix the seen alarm value a. The brute-force answer, the
sum of the product over every unseen value divided by the sum over every value of B as well,
equals the elimination answer: sum out L to get g(t, b) = Σ_l P(l | t, b) P(a | l), then sum
out T to get h(b) = Σ_t P(t) g(t, b), and return P(b) h(b) / Σ_b' P(b') h(b'). -/
theorem variable_elimination_eq_brute_force
    {T B L A : Type*} [Fintype T] [Fintype B] [Fintype L]
    (pT : T → ℝ) (pB : B → ℝ) (pL : T → B → L → ℝ) (pA : L → A → ℝ) (a : A) (b : B) :
    (∑ t, ∑ l, pT t * pB b * pL t b l * pA l a) /
        (∑ t, ∑ b', ∑ l, pT t * pB b' * pL t b' l * pA l a) =
      pB b * (∑ t, pT t * ∑ l, pL t b l * pA l a) /
        ∑ b', pB b' * (∑ t, pT t * ∑ l, pL t b' l * pA l a) := by
  have hnum : ∀ c : B, ∑ t, ∑ l, pT t * pB c * pL t c l * pA l a =
      pB c * (∑ t, pT t * ∑ l, pL t c l * pA l a) := by
    intro c
    rw [Finset.mul_sum]
    refine Finset.sum_congr rfl fun t _ => ?_
    rw [Finset.mul_sum, Finset.mul_sum]
    refine Finset.sum_congr rfl fun l _ => ?_
    ring
  rw [Finset.sum_comm (s := (Finset.univ : Finset T)) (t := (Finset.univ : Finset B)), hnum b]
  congr 1
  exact Finset.sum_congr rfl fun c _ => hnum c

/-- Independence from sums that equal 1 (Step 2). In the delivery network, when the late table
P(l | t, b) adds to 1 over l for every t and b, and the alarm table P(a | l) adds to 1 over a for
every l, summing the joint chance over the unseen L and A leaves P(t, b) = P(t) P(b): with nothing
seen, traffic and breakdown are independent. -/
theorem traffic_breakdown_independent_when_nothing_seen
    {T B L A : Type*} [Fintype L] [Fintype A]
    (pT : T → ℝ) (pB : B → ℝ) (pL : T → B → L → ℝ) (pA : L → A → ℝ)
    (hL : ∀ t b, ∑ l, pL t b l = 1) (hA : ∀ l, ∑ a, pA l a = 1) (t : T) (b : B) :
    ∑ l, ∑ a, pT t * pB b * pL t b l * pA l a = pT t * pB b := by
  calc ∑ l, ∑ a, pT t * pB b * pL t b l * pA l a
      = ∑ l, pT t * pB b * pL t b l * ∑ a, pA l a := by
        refine Finset.sum_congr rfl fun l _ => ?_
        rw [Finset.mul_sum]
    _ = ∑ l, pT t * pB b * pL t b l := by
        refine Finset.sum_congr rfl fun l _ => ?_
        rw [hA l, mul_one]
    _ = pT t * pB b := by
        rw [← Finset.mul_sum, hL t b, mul_one]

/-- On a tree, a sum over a factor's branches splits into a product of messages (Step 4 and the
detailed proof). A factor f uses x and y_1, ..., y_k. Behind each y_j lies a branch whose factors
multiply to F_j, a function of y_j and that branch's own other variables V_j; on a tree the
branches share no variables. Then eliminating everything on f's side of x, the sum over every
y and every branch's variables of f times F_1 ⋯ F_k, equals the sum over y of f times the product
of the separate branch sums Σ_{V_j} F_j, each of which depends on y_j alone (the message from
y_j to f). -/
theorem tree_branch_sum_splits_into_messages
    {ι X : Type*} [Fintype ι] [DecidableEq ι] {Y V : ι → Type*}
    [∀ j, Fintype (Y j)] [∀ j, Fintype (V j)]
    (f : X → (∀ j, Y j) → ℝ) (F : ∀ j, Y j → V j → ℝ) (x : X) :
    ∑ y : (∀ j, Y j), f x y * ∑ v : (∀ j, V j), ∏ j, F j (y j) (v j) =
      ∑ y : (∀ j, Y j), f x y * ∏ j, ∑ w : V j, F j (y j) w := by
  refine Finset.sum_congr rfl fun y _ => ?_
  rw [Fintype.prod_sum (fun j w => F j (y j) w)]

-- Four yes-or-no facts: the full table has 2 × 2 × 2 × 2 = 16 rows.
example : 2 * 2 * 2 * 2 = 16 := by norm_num
-- The distributive law of Step 0.
example : 2 * 5 + 3 * 5 = (2 + 3) * 5 := by norm_num
-- Brute force with the alarm seen: 8 states, each a product of 4 tables, 3 multiplications each.
example : 8 * (4 - 1) = 24 := by norm_num
-- The worked numbers in exact fractions: P(alarm) = 0.118218 and P(breakdown | alarm) = 0.016347 / 0.118218.
example :
    (98 / 100 : ℚ) * (9 / 10 * (5 / 100 * (90 / 100) + 95 / 100 * (3 / 100))
        + 1 / 10 * (40 / 100 * (90 / 100) + 60 / 100 * (3 / 100)))
      + 2 / 100 * (9 / 10 * (90 / 100 * (90 / 100) + 10 / 100 * (3 / 100))
        + 1 / 10 * (95 / 100 * (90 / 100) + 5 / 100 * (3 / 100))) = 118218 / 1000000 := by
  norm_num
example :
    (2 / 100 : ℚ) * (9 / 10 * (90 / 100 * (90 / 100) + 10 / 100 * (3 / 100))
        + 1 / 10 * (95 / 100 * (90 / 100) + 5 / 100 * (3 / 100))) / (118218 / 1000000)
      = 16347 / 118218 := by
  norm_num
-- With nothing seen, P(T = 1, B = 1) = 0.10 × 0.02 = 0.002.
example : (1 / 10 : ℚ) * (2 / 100) = 2 / 1000 := by norm_num
-- The week chain: brute force 2^N (2N - 1) multiplications, elimination 8 (N - 1) + 2.
example : 2 ^ 5 * (2 * 5 - 1) = 288 ∧ 8 * (5 - 1) + 2 = 34 := by norm_num
example : 2 ^ 10 * (2 * 10 - 1) = 19456 ∧ 8 * (10 - 1) + 2 = 74 := by norm_num
example : 2 ^ 20 * (2 * 20 - 1) = 40894464 ∧ 8 * (20 - 1) + 2 = 154 := by norm_num
example : 2 ^ 30 * (2 * 30 - 1) = 63350767616 ∧ 8 * (30 - 1) + 2 = 234 := by norm_num

#print axioms variable_elimination_eq_brute_force
#print axioms traffic_breakdown_independent_when_nothing_seen
#print axioms tree_branch_sum_splits_into_messages
