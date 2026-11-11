-- The Catalan generating function: the series whose coefficient of x^n counts merge plans with n merges satisfies C = 1 + x C^2, iterating that equation from C = 1 settles one more coefficient each round, and over the reals the quadratic x C^2 - C + 1 = 0 has exactly the two roots (1 ± sqrt(1 - 4x))/(2x), the minus root being 2/(1 + sqrt(1 - 4x)).
import Mathlib.Combinatorics.Enumerative.Catalan.Tree
import Mathlib.RingTheory.PowerSeries.Catalan
import Mathlib.Data.Real.Sqrt
import Mathlib.Tactic.NormNum

open PowerSeries BinaryTree

/-- The first-return split becomes `C = 1 + x C^2`. A merge plan with `n` merges is a binary
tree with `n` internal nodes: each node is a merge, its two subtrees are the plans for the left
and right blocks, and the empty tree is the do-nothing plan for one stack. Hang the number of
such plans on `X ^ n` and the resulting power series `C` satisfies `C = 1 + X * C ^ 2`. -/
theorem plan_series_eq_one_add_X_mul_sq :
    PowerSeries.mk (fun n => (treesOfNumNodesEq n).card) =
      1 + X * (PowerSeries.mk (fun n => (treesOfNumNodesEq n).card)) ^ 2 := by
  have h : PowerSeries.mk (fun n => (treesOfNumNodesEq n).card) = catalanSeries := by
    ext n
    simp [treesOfNumNodesEq_card_eq_catalan]
  rw [h]
  rw [← catalanSeries_sq_mul_X_add_one]
  nth_rewrite 1 [← catalanSeries_sq_mul_X_add_one]
  ring

/-- Iterating settles one coefficient a round: start from the series `C = 1` and apply
`C ↦ 1 + X * C ^ 2` a total of `k` times. Every coefficient of `X ^ n` with `n ≤ k` is then the
Catalan number `C_n`, and it never moves again in later rounds. -/
theorem iterate_settles_catalan_coeff (k n : ℕ) (hn : n ≤ k) :
    coeff n ((fun C : PowerSeries ℕ => 1 + X * C ^ 2)^[k] 1) = catalan n := by
  have hfix : (fun C : PowerSeries ℕ => 1 + X * C ^ 2) catalanSeries = catalanSeries := by
    simp only
    rw [← catalanSeries_sq_mul_X_add_one]
    nth_rewrite 2 [← catalanSeries_sq_mul_X_add_one]
    ring
  have key : ∀ (A : PowerSeries ℕ) (m : ℕ),
      (∀ i ≤ m, coeff i A = coeff i catalanSeries) →
      ∀ j ≤ m + 1, coeff j (1 + X * A ^ 2) = coeff j (1 + X * catalanSeries ^ 2) := by
    intro A m hA j hj
    rcases j with _ | j
    · simp
    · rw [map_add, map_add, coeff_succ_X_mul, coeff_succ_X_mul, sq, sq, coeff_mul, coeff_mul]
      congr 1
      apply Finset.sum_congr rfl
      intro p hp
      have h1 := (Finset.mem_antidiagonal.mp hp)
      rw [hA p.1 (by omega), hA p.2 (by omega)]
  induction k generalizing n with
  | zero =>
    have : n = 0 := by omega
    subst this
    simp
  | succ k ih =>
    rw [Function.iterate_succ_apply']
    rw [key _ k (fun i hi => by rw [ih i hi, catalanSeries_coeff]) n hn]
    have := congrArg (coeff n) hfix
    simp only at this
    rw [this, catalanSeries_coeff]

/-- The quadratic formula names the series: for a real number `x` with `x ≠ 0` and
`x ≤ 1/4`, the solutions of `x C^2 - C + 1 = 0` are exactly `(1 - √(1 - 4x))/(2x)` and
`(1 + √(1 - 4x))/(2x)`, and the minus root equals `2/(1 + √(1 - 4x))`. -/
theorem catalan_quadratic_roots (x : ℝ) (hx0 : x ≠ 0) (hx : x ≤ 1 / 4) :
    (∀ c : ℝ, x * c ^ 2 - c + 1 = 0 ↔
      c = (1 - Real.sqrt (1 - 4 * x)) / (2 * x) ∨ c = (1 + Real.sqrt (1 - 4 * x)) / (2 * x)) ∧
    (1 - Real.sqrt (1 - 4 * x)) / (2 * x) = 2 / (1 + Real.sqrt (1 - 4 * x)) := by
  have hs0 : 0 ≤ Real.sqrt (1 - 4 * x) := Real.sqrt_nonneg _
  have hs2 : Real.sqrt (1 - 4 * x) ^ 2 = 1 - 4 * x := Real.sq_sqrt (by linarith)
  set s := Real.sqrt (1 - 4 * x) with hs
  have h2x : 2 * x ≠ 0 := by positivity
  refine ⟨fun c => ?_, ?_⟩
  · constructor
    · intro h
      have h' : (2 * x * c - 1 - s) * (2 * x * c - 1 + s) = 0 := by nlinarith
      rcases mul_eq_zero.mp h' with h'' | h''
      · right
        field_simp
        linarith
      · left
        field_simp
        linarith
    · rintro (h | h)
      · rw [h]
        field_simp
        nlinarith
      · rw [h]
        field_simp
        nlinarith
  · have h1s : 1 + s ≠ 0 := by positivity
    rw [div_eq_div_iff h2x h1s]
    nlinarith

-- The counts for one to six stacks: 1, 1, 2, 5, 14, 42.
example : catalan 0 = 1 ∧ catalan 1 = 1 ∧ catalan 2 = 2 ∧ catalan 3 = 5 ∧ catalan 4 = 14 ∧
    catalan 5 = 42 := by
  simp only [catalan_eq_centralBinom_div, Nat.centralBinom]
  decide

-- Four stacks (three merges) allow five plans, counted from the trees themselves.
example : (treesOfNumNodesEq 3).card = 5 := by decide +kernel

-- Six stacks (five merges) allow 42 plans, counted from the trees themselves.
example : (treesOfNumNodesEq 5).card = 42 := by decide +kernel

-- The closed count C(2n, n)/(n + 1) at n = 5 is 42.
example : Nat.choose 10 5 / (5 + 1) = 42 := by decide

-- Five merges can be done in 120 orders, but they build only 42 nestings.
example : Nat.factorial 5 = 120 := by decide

#print axioms plan_series_eq_one_add_X_mul_sq
#print axioms iterate_settles_catalan_coeff
#print axioms catalan_quadratic_roots
