-- Benders decomposition: every cut built from dual prices between 0 and the tanker price is a true floor under the expected recourse, the master's value is a lower bound on every booking's real cost, so a booking whose real cost meets it is optimal, and a master that proposes a booking whose touching cut it already holds has met its upper bound.
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Data.Real.Basic
import Mathlib.Tactic

open Finset

/-! The card's notation, for its two-stage problem with simple recourse.
* `x` is the first-stage choice (water booked now), with `x ≥ 0`, bought at price `c` each.
* `ι` indexes the scenarios (kinds of summer); `p s ≥ 0` is the chance of scenario `s` and
  `d s` its demand.
* `q` is the tanker price per unit short. A repair in scenario `s` is `y ≥ 0` with `y ≥ d s - x`;
  the scenario's linear program is `Q(x, s) = min { q y : y ≥ 0, y ≥ d s - x }`, whose value is
  `q * max 0 (d s - x)`. The expected cost of a booking is
  `f x = c * x + ∑ s, p s * (q * max 0 (d s - x))`, to be minimised over `x ≥ 0`.
* A dual price vector is `λ : ι → ℝ` with `0 ≤ λ s ≤ q`. It gives the single (averaged) cut
  `θ ≥ ∑ s, p s * λ s * (d s - x)`.
* The master holds the cuts indexed by a finite set `K`, the cut `j` coming from prices `lam j`.
  A pair `(x, θ)` is master-feasible when `x ≥ 0`, `θ ≥ 0` (the known floor) and `θ` sits on or
  above every held cut. The master's value `c * xk + θk` at its optimum `(xk, θk)` is `LB`. -/

/-- Each held cut sits under the real expected recourse at every booking. -/
theorem benders_cut_le_recourse
    {ι : Type*} [Fintype ι]
    (q x : ℝ) (p d lam : ι → ℝ) (hp : ∀ s, 0 ≤ p s)
    (hlam : ∀ s, 0 ≤ lam s ∧ lam s ≤ q) :
    ∑ s, p s * lam s * (d s - x) ≤ ∑ s, p s * (q * max 0 (d s - x)) := by
  apply Finset.sum_le_sum
  intro s _
  have h1 : lam s * (d s - x) ≤ lam s * max 0 (d s - x) :=
    mul_le_mul_of_nonneg_left (le_max_right _ _) (hlam s).1
  have h2 : lam s * max 0 (d s - x) ≤ q * max 0 (d s - x) :=
    mul_le_mul_of_nonneg_right (hlam s).2 (le_max_left _ _)
  rw [mul_assoc]
  exact mul_le_mul_of_nonneg_left (h1.trans h2) (hp s)

#print axioms benders_cut_le_recourse

/-- The bounds meeting certifies optimality. Let every held cut come from prices between 0 and
the tanker price `q ≥ 0`, and let `(xk, θk)` be a best point of the master. Then the master's value
`LB = c xk + θk` is at most the real expected cost of every booking `x ≥ 0`, and any booking
`x̂ ≥ 0` whose real expected cost equals `LB` is optimal: no booking costs less. -/
theorem benders_bounds_meet_certify_optimal
    {ι κ : Type*} [Fintype ι]
    (c q : ℝ) (p d : ι → ℝ) (hp : ∀ s, 0 ≤ p s) (hq : 0 ≤ q)
    (K : Finset κ) (lam : κ → ι → ℝ) (hlam : ∀ j ∈ K, ∀ s, 0 ≤ lam j s ∧ lam j s ≤ q)
    (xk θk : ℝ)
    (hmaster : ∀ x θ : ℝ, 0 ≤ x → 0 ≤ θ →
      (∀ j ∈ K, ∑ s, p s * lam j s * (d s - x) ≤ θ) → c * xk + θk ≤ c * x + θ) :
    (∀ x : ℝ, 0 ≤ x → c * xk + θk ≤ c * x + ∑ s, p s * (q * max 0 (d s - x))) ∧
    ∀ xh : ℝ, 0 ≤ xh → c * xh + ∑ s, p s * (q * max 0 (d s - xh)) = c * xk + θk →
      ∀ x : ℝ, 0 ≤ x →
        c * xh + ∑ s, p s * (q * max 0 (d s - xh)) ≤ c * x + ∑ s, p s * (q * max 0 (d s - x)) := by
  have part1 : ∀ x : ℝ, 0 ≤ x → c * xk + θk ≤ c * x + ∑ s, p s * (q * max 0 (d s - x)) := by
    intro x hx
    apply hmaster x _ hx
    · apply Finset.sum_nonneg
      intro s _
      exact mul_nonneg (hp s) (mul_nonneg hq (le_max_left _ _))
    · intro j hj
      exact benders_cut_le_recourse q x p d (lam j) hp (hlam j hj)
  refine ⟨part1, ?_⟩
  intro xh _ hxh x hx
  rw [hxh]
  exact part1 x hx

/-- Every cut is a true lower bound (weak duality). Take prices `0 ≤ λ s ≤ q` and any repairs
`y s ≥ 0` with `y s ≥ d s - x` in every scenario. Then each scenario's tanker bill is at least
`λ s (d s - x)`, and averaging with the chances `p s ≥ 0` gives the cut: the expected bill of the
repairs is at least `∑ s, p s λ s (d s - x)`, at every booking `x`. -/
theorem cut_le_expected_recourse
    {ι : Type*} [Fintype ι]
    (q x : ℝ) (p d lam y : ι → ℝ) (hp : ∀ s, 0 ≤ p s)
    (hlam : ∀ s, 0 ≤ lam s ∧ lam s ≤ q)
    (hy : ∀ s, 0 ≤ y s ∧ d s - x ≤ y s) :
    (∀ s, lam s * (d s - x) ≤ q * y s) ∧
    ∑ s, p s * lam s * (d s - x) ≤ ∑ s, p s * (q * y s) := by
  refine ⟨fun s => ?_, ?_⟩
  · exact (mul_le_mul_of_nonneg_left (hy s).2 (hlam s).1).trans
      (mul_le_mul_of_nonneg_right (hlam s).2 (hy s).1)
  · apply Finset.sum_le_sum
    intro s _
    rw [mul_assoc]
    exact mul_le_mul_of_nonneg_left
      ((mul_le_mul_of_nonneg_left (hy s).2 (hlam s).1).trans
        (mul_le_mul_of_nonneg_right (hlam s).2 (hy s).1)) (hp s)

/-- The loop stops when the new cut is already held. Let every held cut come from prices between
0 and `q ≥ 0`, let `(xk, θk)` be a master-feasible best point of the master, and suppose the master
already holds the cut with the touching prices at `xk` (`λ s = q` if the summer is short,
`d s > xk`, and `0` if not). Then the lower bound equals the real expected cost of `xk`, and `xk`
is optimal. -/
theorem benders_stops_when_cut_repeats
    {ι κ : Type*} [Fintype ι]
    (c q : ℝ) (p d : ι → ℝ) (hp : ∀ s, 0 ≤ p s) (hq : 0 ≤ q)
    (K : Finset κ) (lam : κ → ι → ℝ) (hlam : ∀ j ∈ K, ∀ s, 0 ≤ lam j s ∧ lam j s ≤ q)
    (xk θk : ℝ) (hxk : 0 ≤ xk) (hθk : 0 ≤ θk)
    (hfeas : ∀ j ∈ K, ∑ s, p s * lam j s * (d s - xk) ≤ θk)
    (hmaster : ∀ x θ : ℝ, 0 ≤ x → 0 ≤ θ →
      (∀ j ∈ K, ∑ s, p s * lam j s * (d s - x) ≤ θ) → c * xk + θk ≤ c * x + θ)
    (hheld : ∃ j ∈ K, ∀ s, lam j s = if xk < d s then q else 0) :
    c * xk + θk = c * xk + ∑ s, p s * (q * max 0 (d s - xk)) ∧
    ∀ x : ℝ, 0 ≤ x →
      c * xk + ∑ s, p s * (q * max 0 (d s - xk)) ≤ c * x + ∑ s, p s * (q * max 0 (d s - x)) := by
  have hR : 0 ≤ ∑ s, p s * (q * max 0 (d s - xk)) := by
    apply Finset.sum_nonneg
    intro s _
    exact mul_nonneg (hp s) (mul_nonneg hq (le_max_left _ _))
  have part1 : ∀ x : ℝ, 0 ≤ x → c * xk + θk ≤ c * x + ∑ s, p s * (q * max 0 (d s - x)) := by
    intro x hx
    apply hmaster x _ hx
    · apply Finset.sum_nonneg
      intro s _
      exact mul_nonneg (hp s) (mul_nonneg hq (le_max_left _ _))
    · intro j hj
      exact benders_cut_le_recourse q x p d (lam j) hp (hlam j hj)
  obtain ⟨j, hj, hjs⟩ := hheld
  have hcut := hfeas j hj
  have heq : ∑ s, p s * lam j s * (d s - xk) = ∑ s, p s * (q * max 0 (d s - xk)) := by
    apply Finset.sum_congr rfl
    intro s _
    rw [hjs s, mul_assoc]
    congr 1
    split_ifs with h
    · rw [max_eq_right (by linarith)]
    · rw [max_eq_left (by linarith)]; ring
  have hle := part1 xk hxk
  have hEq : c * xk + θk = c * xk + ∑ s, p s * (q * max 0 (d s - xk)) := by
    linarith
  refine ⟨hEq, ?_⟩
  intro x hx
  rw [← hEq]
  exact part1 x hx

-- k = 0: at x = 0 every summer is short (100, 200, 300 at price 2); the average is 200, so UB = 200.
example : (1 : ℚ) * 0 + 1 / 3 * (2 * max 0 (50 - 0)) + 1 / 3 * (2 * max 0 (100 - 0)) +
    1 / 3 * (2 * max 0 (150 - 0)) = 200 := by
  norm_num

-- Cut 1, prices 2, 2, 2 at x = 0: θ ≥ 200 - 2x.
example : ∀ x : ℚ, 1 / 3 * 2 * (50 - x) + 1 / 3 * 2 * (100 - x) + 1 / 3 * 2 * (150 - x) =
    200 - 2 * x := by
  intro x; ring

-- k = 1: the master books 100 (cut 1 reaches 0 there), LB = 100; the real cost is 100 + 100/3.
example : (200 : ℚ) - 2 * 100 = 0 ∧ (1 : ℚ) * 100 + 0 = 100 ∧
    (1 : ℚ) * 100 + 1 / 3 * (2 * max 0 (50 - 100)) + 1 / 3 * (2 * max 0 (100 - 100)) +
      1 / 3 * (2 * max 0 (150 - 100)) = 400 / 3 := by
  norm_num

-- Cut 2, prices 0, 0, 2 at x = 100: θ ≥ 100 - (2/3)x.
example : ∀ x : ℚ, 1 / 3 * 0 * (50 - x) + 1 / 3 * 0 * (100 - x) + 1 / 3 * 2 * (150 - x) =
    100 - 2 / 3 * x := by
  intro x; ring

-- k = 2: cuts 1 and 2 cross at x = 75 with θ = 50, LB = 125; the real cost there is 425/3.
example : (200 : ℚ) - 2 * 75 = 50 ∧ (100 : ℚ) - 2 / 3 * 75 = 50 ∧ (75 : ℚ) + 50 = 125 ∧
    (1 : ℚ) * 75 + 1 / 3 * (2 * max 0 (50 - 75)) + 1 / 3 * (2 * max 0 (100 - 75)) +
      1 / 3 * (2 * max 0 (150 - 75)) = 425 / 3 ∧ (400 / 3 : ℚ) < 425 / 3 := by
  norm_num

-- Cut 3, prices 0, 2, 2 at x = 75: θ ≥ 500/3 - (4/3)x.
example : ∀ x : ℚ, 1 / 3 * 0 * (50 - x) + 1 / 3 * 2 * (100 - x) + 1 / 3 * 2 * (150 - x) =
    500 / 3 - 4 / 3 * x := by
  intro x; ring

-- k = 3: cuts 2 and 3 cross at x = 100 with θ = 100/3, so LB = 400/3 = UB.
example : (100 : ℚ) - 2 / 3 * 100 = 100 / 3 ∧ (500 / 3 : ℚ) - 4 / 3 * 100 = 100 / 3 ∧
    (100 : ℚ) + 100 / 3 = 400 / 3 := by
  norm_num

-- Multi-cut: the three cuts from x = 0 are θ_s ≥ 2(d_s - x); at x = 100 they give
-- θ = 0, 0, 100, and 100 + 100/3 = 400/3 at once.
example : (1 : ℚ) * 100 + 1 / 3 * max 0 (2 * (50 - 100)) + 1 / 3 * max 0 (2 * (100 - 100)) +
    1 / 3 * max 0 (2 * (150 - 100)) = 400 / 3 := by
  norm_num

-- The extensive form's dual prices 0, 1/3, 2/3 sum to the booking price 1, none exceeds
-- (1/3) × 2, and their bound 1/3 × 100 + 2/3 × 150 meets the cost 400/3.
example : (0 : ℚ) + 1 / 3 + 2 / 3 = 1 ∧ (2 / 3 : ℚ) ≤ 1 / 3 * 2 ∧
    (0 : ℚ) * 50 + 1 / 3 * 100 + 2 / 3 * 150 = 400 / 3 := by
  norm_num

-- The real cost at the kinks 0, 50, 100, 150: 200, 150, 400/3, 150.
example : (1 : ℚ) * 50 + 1 / 3 * (2 * max 0 (50 - 50)) + 1 / 3 * (2 * max 0 (100 - 50)) +
      1 / 3 * (2 * max 0 (150 - 50)) = 150 ∧
    (1 : ℚ) * 150 + 1 / 3 * (2 * max 0 (50 - 150)) + 1 / 3 * (2 * max 0 (100 - 150)) +
      1 / 3 * (2 * max 0 (150 - 150)) = 150 := by
  norm_num

-- Each scenario's dual has two corners (0 and 2), so there are at most 2^3 = 8 single cuts.
example : 2 ^ 3 = 8 := by decide

-- Tanker cap 30: feasibility cuts x ≥ 20, 70, 120; at 120 the cost is 120 + (2/3) × 30 = 140.
example : 50 - 30 = 20 ∧ 100 - 30 = 70 ∧ 150 - 30 = 120 ∧
    (1 : ℚ) * 120 + 1 / 3 * (2 * (150 - 120)) = 140 := by
  norm_num

-- Blocks of 35: the enumeration f(0..175) = 200, 165, 430/3, 135, 440/3, 175, best at 105.
example : (35 : ℚ) + 2 / 3 * ((50 - 35) + (100 - 35) + (150 - 35)) = 165 ∧
    (70 : ℚ) + 2 / 3 * ((100 - 70) + (150 - 70)) = 430 / 3 ∧
    (105 : ℚ) + 2 / 3 * (150 - 105) = 135 ∧
    (140 : ℚ) + 2 / 3 * (150 - 140) = 440 / 3 ∧ (175 : ℚ) = 175 := by
  norm_num

-- Whole tankers of 40 at 80: booking 110 leaves 40 short only in the 150 summer, one tanker,
-- so the cost is 110 + 80/3 = 410/3, above the LP floor 400/3.
example : (150 - 110 + 39) / 40 = 1 ∧ (110 : ℚ) + 1 / 3 * 80 = 410 / 3 ∧
    (400 / 3 : ℚ) < 410 / 3 := by
  norm_num

-- A flat cut θ ≥ 200 from x = 0 claims a lower bound of 200, above the optimum 400/3.
example : (400 / 3 : ℚ) < 200 := by norm_num

-- Try changing: at booking price 3/2 the best booking is 50 at cost 175;
-- at tanker price 4 the best is 150 at cost 150.
example : (3 / 2 : ℚ) * 50 + 2 / 3 * ((100 - 50) + (150 - 50)) = 175 ∧
    (1 : ℚ) * 150 + 0 = 150 := by
  norm_num

#print axioms benders_bounds_meet_certify_optimal
#print axioms cut_le_expected_recourse
#print axioms benders_stops_when_cut_repeats
