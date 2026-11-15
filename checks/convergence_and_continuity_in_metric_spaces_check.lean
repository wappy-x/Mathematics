-- Limits and continuity with distances: in any metric space a map passes the epsilon-delta test at a point exactly when it passes the sequence test there, a limit is unique, and a set is closed exactly when it keeps the limits of its convergent lists.
import Mathlib.Topology.MetricSpace.Basic
import Mathlib.Topology.Sequences
import Mathlib.Data.Rat.Defs
import Mathlib.Tactic.NormNum

/-- The sequence test. A map `f` from one metric space to another passes the epsilon-delta test
at `a` (for every tolerance `ε > 0` there is a window `δ > 0` such that `d(x, a) < δ` forces
`d(f x, f a) < ε`) exactly when it sends every list converging to `a` (for every `ε > 0` there
is a cutoff `N` with `d(x_n, a) < ε` for all `n > N`) to a list converging to `f a`. -/
theorem continuous_at_iff_sequence_test {X Y : Type*} [MetricSpace X] [MetricSpace Y]
    (f : X → Y) (a : X) :
    (∀ ε > 0, ∃ δ > 0, ∀ x : X, dist x a < δ → dist (f x) (f a) < ε) ↔
      (∀ x : ℕ → X, (∀ ε > 0, ∃ N : ℕ, ∀ n > N, dist (x n) a < ε) →
        ∀ ε > 0, ∃ N : ℕ, ∀ n > N, dist (f (x n)) (f a) < ε) := by
  have h1 : (∀ ε > 0, ∃ δ > 0, ∀ x : X, dist x a < δ → dist (f x) (f a) < ε) ↔
      ContinuousAt f a := by
    rw [Metric.continuousAt_iff]
  rw [h1, ContinuousAt, tendsto_nhds_iff_seq_tendsto]
  simp only [Metric.tendsto_atTop', Function.comp_apply]

/-- A limit is unique. In a metric space (distance zero only from a point to itself), a list
that converges to `p` and also converges to `q` has `p = q`. -/
theorem limit_unique {X : Type*} [MetricSpace X] (x : ℕ → X) (p q : X)
    (hp : ∀ ε > 0, ∃ N : ℕ, ∀ n > N, dist (x n) p < ε)
    (hq : ∀ ε > 0, ∃ N : ℕ, ∀ n > N, dist (x n) q < ε) :
    p = q := by
  exact tendsto_nhds_unique (Metric.tendsto_atTop'.mpr hp) (Metric.tendsto_atTop'.mpr hq)

/-- A closed set keeps the limits of its lists. In a metric space, a set `S` is closed (the
points outside it form an open set) exactly when every list drawn from `S` that converges to a
point `L` has `L` in `S`. -/
theorem closed_iff_keeps_limits {X : Type*} [MetricSpace X] (S : Set X) :
    IsClosed S ↔
      ∀ (x : ℕ → X) (L : X), (∀ n, x n ∈ S) →
        (∀ ε > 0, ∃ N : ℕ, ∀ n > N, dist (x n) L < ε) → L ∈ S := by
  rw [← isSeqClosed_iff_isClosed]
  constructor
  · intro h x L hx hL
    exact h hx (Metric.tendsto_atTop'.mpr hL)
  · intro h x L hx hL
    exact h x L hx (Metric.tendsto_atTop'.mp hL)

/-- One spreadsheet recalculation with profit 43,000 dollars: the bonus becomes a tenth of what
is left after both items, the tax a quarter of what is left after the bonus. -/
def recalc (r : ℚ × ℚ) : ℚ × ℚ := ((43000 - r.1 - r.2) / 10, (43000 - r.1) / 4)

-- The first three passes from blank cells: (4300, 10750), (2795, 9675), (3053, 10051.25).
example : recalc (0, 0) = (4300, 10750) := by norm_num [recalc]
example : recalc (4300, 10750) = (2795, 9675) := by norm_num [recalc]
example : recalc (2795, 9675) = (3053, 40205 / 4) := by norm_num [recalc]

-- The resting point (3000, 10000) satisfies both formulas: it is a fixed point.
example : recalc (3000, 10000) = (3000, 10000) := by norm_num [recalc]

-- Cramer's rule on 11B + T = P, B + 4T = P: denominator 43, B = 3P/43, T = 10P/43.
example : 11 * 4 - 1 * 1 = 43 ∧ 3 * 43000 / 43 = 3000 ∧ 10 * 43000 / 43 = 10000 := by decide

-- Distances from (3000, 10000) in the largest-change metric: 1300, 325, 53.
example : max |(4300 : ℚ) - 3000| |10750 - 10000| = 1300 := by norm_num
example : max |(2795 : ℚ) - 3000| |9675 - 10000| = 325 := by norm_num
example : max |(3053 : ℚ) - 3000| |40205 / 4 - 10000| = 53 := by norm_num

-- Proved ceiling 10000 / 4^n for n = 1, 2, 3: 2500, 625, 625/4.
example : (10000 : ℚ) / 4 = 2500 ∧ (10000 : ℚ) / 4 ^ 2 = 625 ∧ (10000 : ℚ) / 4 ^ 3 = 625 / 4 := by
  norm_num

-- Cutoff for a tolerance of 1/1000: 4^11 = 4194304 < 10^7 < 16777216 = 4^12.
example : 4 ^ 11 = 4194304 ∧ 4 ^ 12 = 16777216 ∧ 4 ^ 11 < 10 ^ 7 ∧ 10 ^ 7 < 4 ^ 12 := by decide

-- Two passes on the misses alone (no profit term): a bonus miss of 1 becomes (7/200, 1/40),
-- a tax miss of 1 becomes (1/100, 1/40).
example : let m : ℚ × ℚ → ℚ × ℚ := fun r => ((-r.1 - r.2) / 10, -r.1 / 4)
    m (m (1, 0)) = (7 / 200, 1 / 40) ∧ m (m (0, 1)) = (1 / 100, 1 / 40) := by
  norm_num

#print axioms continuous_at_iff_sequence_test
#print axioms limit_unique
#print axioms closed_iff_keeps_limits
