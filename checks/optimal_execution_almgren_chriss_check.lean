-- Almgren-Chriss: minimising expected cost plus lam times variance over sales schedules gives the sinh schedule, or the even schedule when lam = 0, and the cost and risk sums regroup as the card says.
import Mathlib.Analysis.Complex.Trigonometric
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp

open Finset

/-! Time is cut into `N` slices of length `τ`, so the horizon is `T = N * τ`.
A schedule `x : ℕ → ℝ` gives `x k`, the shares still held after slice `k`;
`x (k - 1) - x k` is the number sold in slice `k`. Only `x 0, …, x N` matter.
`ηt` is the corrected temporary impact `η - γ τ / 2`. -/

/-- Expected shortfall `E = γ X² / 2 + ε X + (ηt / τ) Σ_{k=1}^{N} n_k²`, with `n_k = x_{k-1} - x_k`. -/
noncomputable def expectedCost (N : ℕ) (τ γ ε ηt X : ℝ) (x : ℕ → ℝ) : ℝ :=
  1 / 2 * γ * X ^ 2 + ε * X + ηt / τ * ∑ k ∈ Icc 1 N, (x (k - 1) - x k) ^ 2

/-- Variance of the shortfall `V = σ² τ Σ_{k=1}^{N} x_k²`. -/
noncomputable def shortfallVariance (N : ℕ) (τ σ : ℝ) (x : ℕ → ℝ) : ℝ :=
  σ ^ 2 * τ * ∑ k ∈ Icc 1 N, x k ^ 2

/-- The trader's objective `U = E + lam V`. -/
noncomputable def objective (N : ℕ) (τ σ γ ε ηt lam X : ℝ) (x : ℕ → ℝ) : ℝ :=
  expectedCost N τ γ ε ηt X x + lam * shortfallVariance N τ σ x

/-- `y` sells exactly the order (`y 0 = X`, `y N = 0`), and among all such schedules it has the
smallest value of `f`, and it is the only schedule with that value. -/
def IsUniqueBestSchedule (N : ℕ) (X : ℝ) (f : (ℕ → ℝ) → ℝ) (y : ℕ → ℝ) : Prop :=
  y 0 = X ∧ y N = 0 ∧
    ∀ x : ℕ → ℝ, x 0 = X → x N = 0 → f y ≤ f x ∧ (f x = f y → ∀ k ≤ N, x k = y k)

/-- Summation by parts for the cross term, up to slice `M`. -/
theorem ac_cross_partial (N : ℕ) (a b : ℝ) (y d : ℕ → ℝ)
    (hEL : ∀ k, 1 ≤ k → k < N → a * (2 * y k - y (k - 1) - y (k + 1)) + b * y k = 0)
    (hd0 : d 0 = 0) :
    ∀ M, 1 ≤ M → M ≤ N →
      a * ∑ k ∈ Icc 1 M, (y (k - 1) - y k) * (d (k - 1) - d k) + b * ∑ k ∈ Icc 1 M, y k * d k
        = (b * y M - a * (y (M - 1) - y M)) * d M := by
  intro M hM1 hMN
  induction M with
  | zero => omega
  | succ m ih =>
    rcases Nat.eq_zero_or_pos m with h | h
    · subst h
      simp [hd0]
      ring
    · rw [sum_Icc_succ_top (by omega), sum_Icc_succ_top (by omega), mul_add, mul_add,
        add_add_add_comm, ih h (by omega)]
      have e := hEL m h (by omega)
      have hm : m + 1 - 1 = m := by omega
      rw [hm]
      linear_combination (d m) * e

/-- The objective's quadratic part splits around a schedule satisfying the discrete
Euler-Lagrange equation. -/
theorem ac_split (N : ℕ) (a b : ℝ) (y x : ℕ → ℝ)
    (hEL : ∀ k, 1 ≤ k → k < N → a * (2 * y k - y (k - 1) - y (k + 1)) + b * y k = 0)
    (h0 : x 0 = y 0) (hN : x N = y N) :
    a * ∑ k ∈ Icc 1 N, (x (k - 1) - x k) ^ 2 + b * ∑ k ∈ Icc 1 N, x k ^ 2
      = a * ∑ k ∈ Icc 1 N, (y (k - 1) - y k) ^ 2 + b * ∑ k ∈ Icc 1 N, y k ^ 2
        + (a * ∑ k ∈ Icc 1 N, ((x (k - 1) - y (k - 1)) - (x k - y k)) ^ 2
          + b * ∑ k ∈ Icc 1 N, (x k - y k) ^ 2) := by
  set d : ℕ → ℝ := fun k => x k - y k with hd
  have hd0 : d 0 = 0 := by simp [hd, h0]
  have hcross : a * ∑ k ∈ Icc 1 N, (y (k - 1) - y k) * (d (k - 1) - d k)
      + b * ∑ k ∈ Icc 1 N, y k * d k = 0 := by
    rcases Nat.eq_zero_or_pos N with h | h
    · subst h; simp
    · rw [ac_cross_partial N a b y d hEL hd0 N h le_rfl]
      simp [hd, hN]
  have e1 : ∑ k ∈ Icc 1 N, (x (k - 1) - x k) ^ 2
      = ∑ k ∈ Icc 1 N, (y (k - 1) - y k) ^ 2
        + 2 * ∑ k ∈ Icc 1 N, (y (k - 1) - y k) * (d (k - 1) - d k)
        + ∑ k ∈ Icc 1 N, ((x (k - 1) - y (k - 1)) - (x k - y k)) ^ 2 := by
    rw [mul_sum, ← sum_add_distrib, ← sum_add_distrib]
    refine sum_congr rfl (fun k _ => ?_)
    simp only [hd]; ring
  have e2 : ∑ k ∈ Icc 1 N, x k ^ 2
      = ∑ k ∈ Icc 1 N, y k ^ 2 + 2 * ∑ k ∈ Icc 1 N, y k * d k
        + ∑ k ∈ Icc 1 N, (x k - y k) ^ 2 := by
    rw [mul_sum, ← sum_add_distrib, ← sum_add_distrib]
    refine sum_congr rfl (fun k _ => ?_)
    simp only [hd]; ring
  rw [e1, e2]
  linear_combination 2 * hcross

/-- A schedule satisfying the Euler-Lagrange equation with the right ends is the unique
minimiser of `C + a Σ n_k² + b Σ x_k²` when `a > 0`, `b ≥ 0`. -/
theorem ac_unique_min (N : ℕ) (a b C X : ℝ) (ha : 0 < a) (hb : 0 ≤ b) (y : ℕ → ℝ)
    (hEL : ∀ k, 1 ≤ k → k < N → a * (2 * y k - y (k - 1) - y (k + 1)) + b * y k = 0)
    (hy0 : y 0 = X) (hyN : y N = 0) (f : (ℕ → ℝ) → ℝ)
    (hf : ∀ x, f x = C + (a * ∑ k ∈ Icc 1 N, (x (k - 1) - x k) ^ 2
      + b * ∑ k ∈ Icc 1 N, x k ^ 2)) :
    IsUniqueBestSchedule N X f y := by
  refine ⟨hy0, hyN, fun x hx0 hxN => ?_⟩
  have hs := ac_split N a b y x hEL (by rw [hx0, hy0]) (by rw [hxN, hyN])
  have q1 : 0 ≤ ∑ k ∈ Icc 1 N, ((x (k - 1) - y (k - 1)) - (x k - y k)) ^ 2 :=
    sum_nonneg (fun k _ => sq_nonneg _)
  have q2 : 0 ≤ ∑ k ∈ Icc 1 N, (x k - y k) ^ 2 := sum_nonneg (fun k _ => sq_nonneg _)
  have q1' : 0 ≤ a * ∑ k ∈ Icc 1 N, ((x (k - 1) - y (k - 1)) - (x k - y k)) ^ 2 :=
    mul_nonneg ha.le q1
  have q2' : 0 ≤ b * ∑ k ∈ Icc 1 N, (x k - y k) ^ 2 := mul_nonneg hb q2
  rw [hf x, hf y, hs]
  refine ⟨by linarith, fun heq k hk => ?_⟩
  have hz : a * ∑ k ∈ Icc 1 N, ((x (k - 1) - y (k - 1)) - (x k - y k)) ^ 2 = 0 := by linarith
  have hz' : ∑ k ∈ Icc 1 N, ((x (k - 1) - y (k - 1)) - (x k - y k)) ^ 2 = 0 := by
    rcases mul_eq_zero.mp hz with h | h
    · exact absurd h ha.ne'
    · exact h
  have hterm := (sum_eq_zero_iff_of_nonneg (fun k _ => sq_nonneg _)).mp hz'
  induction k with
  | zero => rw [hx0, hy0]
  | succ m ih =>
    have h1 := hterm (m + 1) (by simp; omega)
    have h2 := ih (by omega)
    simp only [Nat.add_sub_cancel] at h1
    have h3 : (x m - y m) - (x (m + 1) - y (m + 1)) = 0 := by
      exact pow_eq_zero_iff (n := 2) (by norm_num) |>.mp h1
    linarith

/-- The card's main claim. Minimise expected cost plus `lam` times variance over every schedule
that sells `X` shares in `N` slices of length `τ`. If risk costs nothing (`lam = 0`) the unique best
schedule sells evenly, `x_k = X (1 - k / N)`. If `lam > 0`, the unique best schedule is
`x_k = X sinh(κ (T - t_k)) / sinh(κ T)` with `t_k = k τ`, `T = N τ`, where the urgency `κ` solves
`(2 / τ²)(cosh(κ τ) - 1) = lam σ² / ηt`. -/
theorem optimal_schedule_is_sinh_or_even
    (N : ℕ) (hN : 0 < N) (τ σ γ ε ηt lam X : ℝ)
    (hτ : 0 < τ) (hσ : 0 < σ) (hηt : 0 < ηt) (hlam : 0 ≤ lam) :
    (lam = 0 →
      IsUniqueBestSchedule N X (objective N τ σ γ ε ηt lam X)
        (fun k => X * (1 - (k : ℝ) / N))) ∧
    (0 < lam → ∀ κ : ℝ, 2 / τ ^ 2 * (Real.cosh (κ * τ) - 1) = lam * σ ^ 2 / ηt →
      IsUniqueBestSchedule N X (objective N τ σ γ ε ηt lam X)
        (fun k => X * Real.sinh (κ * (N * τ - k * τ)) / Real.sinh (κ * (N * τ)))) := by
  have ha : 0 < ηt / τ := div_pos hηt hτ
  have hf : ∀ x, objective N τ σ γ ε ηt lam X x = (1 / 2 * γ * X ^ 2 + ε * X)
      + (ηt / τ * ∑ k ∈ Icc 1 N, (x (k - 1) - x k) ^ 2
        + lam * σ ^ 2 * τ * ∑ k ∈ Icc 1 N, x k ^ 2) := by
    intro x
    simp only [objective, expectedCost, shortfallVariance]
    ring
  have hNr : (N : ℝ) ≠ 0 := by exact_mod_cast hN.ne'
  refine ⟨fun h0 => ?_, fun hpos κ hκ => ?_⟩
  · subst h0
    refine ac_unique_min N (ηt / τ) (0 * σ ^ 2 * τ) _ X ha (by simp) _ ?_ ?_ ?_ _ hf
    · intro k hk1 _
      have hc : ((k - 1 : ℕ) : ℝ) = (k : ℝ) - 1 := by
        rw [Nat.cast_sub hk1]; simp
      simp only [hc]
      push_cast
      field_simp
      ring
    · simp
    · simp [hNr]
  · have hb : 0 ≤ lam * σ ^ 2 * τ := by positivity
    have hcosh : Real.cosh (κ * τ) = 1 + lam * σ ^ 2 * τ ^ 2 / (2 * ηt) := by
      field_simp at hκ ⊢
      linarith
    have hκ0 : κ ≠ 0 := by
      intro h
      rw [h, zero_mul, Real.cosh_zero] at hcosh
      have : 0 < lam * σ ^ 2 * τ ^ 2 / (2 * ηt) := by positivity
      linarith
    have hs : Real.sinh (κ * (N * τ)) ≠ 0 := by
      rw [Ne, Real.sinh_eq_zero]
      have : (N : ℝ) * τ ≠ 0 := mul_ne_zero hNr hτ.ne'
      exact mul_ne_zero hκ0 this
    refine ac_unique_min N (ηt / τ) (lam * σ ^ 2 * τ) _ X ha hb _ ?_ ?_ ?_ _ hf
    · intro k hk1 _
      have hc : ((k - 1 : ℕ) : ℝ) = (k : ℝ) - 1 := by
        rw [Nat.cast_sub hk1]; simp
      have e1 : κ * (N * τ - ((k - 1 : ℕ) : ℝ) * τ) = κ * (N * τ - k * τ) + κ * τ := by
        rw [hc]; ring
      have e2 : κ * (N * τ - ((k + 1 : ℕ) : ℝ) * τ) = κ * (N * τ - k * τ) - κ * τ := by
        push_cast; ring
      simp only [e1, e2, Real.sinh_add, Real.sinh_sub, hcosh]
      field_simp
      ring
    · simp only [Nat.cast_zero, zero_mul, sub_zero]
      field_simp
    · simp

/-- Step 2: the permanent-impact cost. Each share sold in slice `k` pays the dents `γ n_j` of all
earlier slices; summed, this is `γ (X² - Σ n_k²) / 2`, where `X = Σ n_k` is the whole order. -/
theorem permanent_impact_cost (N : ℕ) (γ X : ℝ) (n : ℕ → ℝ)
    (hX : ∑ k ∈ Icc 1 N, n k = X) :
    γ * ∑ k ∈ Icc 1 N, n k * ∑ j ∈ Ico 1 k, n j
      = 1 / 2 * γ * (X ^ 2 - ∑ k ∈ Icc 1 N, n k ^ 2) := by
  subst hX
  induction N with
  | zero => simp
  | succ m ih =>
    rw [sum_Icc_succ_top (by omega), sum_Icc_succ_top (by omega), sum_Icc_succ_top (by omega),
      Ico_add_one_right_eq_Icc]
    have ih' := ih
    linear_combination ih'

/-- Step 3: regrouping the random part by shock. If the order ends empty (`x N = 0`), the sum over
trades of shares sold times the wander before the sale equals the sum over shocks of the shock
times the shares still held: `Σ_k n_k Σ_{j<k} ξ_j = Σ_j ξ_j x_j`. -/
theorem shocks_hit_shares_held (N : ℕ) (x ξ : ℕ → ℝ) (hxN : x N = 0) :
    ∑ k ∈ Icc 1 N, (x (k - 1) - x k) * ∑ j ∈ Ico 1 k, ξ j
      = ∑ j ∈ Icc 1 N, ξ j * x j := by
  suffices h : ∀ M, ∑ k ∈ Icc 1 M, (x (k - 1) - x k) * ∑ j ∈ Ico 1 k, ξ j
      = ∑ j ∈ Icc 1 M, ξ j * x j - x M * ∑ j ∈ Icc 1 M, ξ j by
    rw [h N, hxN]; ring
  intro M
  induction M with
  | zero => simp
  | succ m ih =>
    rw [sum_Icc_succ_top (by omega), sum_Icc_succ_top (by omega), sum_Icc_succ_top (by omega),
      ih, Ico_add_one_right_eq_Icc, Nat.add_sub_cancel]
    ring

-- The card's numbers, exactly: X = 100,000, N = 13, τ = 1/13, ε = 1/100, γ = 2/10^7, η = 2/10^6.
-- The corrected impact ηt = η - γ τ / 2 = 259 / (13 * 10^7), shown on the card as 1.992308e-6.
example : (2 : ℚ) / 10 ^ 6 - 1 / 2 * (2 / 10 ^ 7) * (1 / 13) = 259 / (13 * 10 ^ 7) := by
  norm_num
-- Permanent cost γ X² / 2 = $1,000 and spread cost ε X = $1,000.
example : (1 : ℚ) / 2 * (2 / 10 ^ 7) * 100000 ^ 2 = 1000 := by
  norm_num
example : (1 : ℚ) / 100 * 100000 = 1000 := by
  norm_num
-- Selling it all in the first slice: E = 1000 + 1000 + (ηt / τ) * 100000² = $261,000.
example : (1000 : ℚ) + 1000 + 259 / (13 * 10 ^ 7) / (1 / 13) * 100000 ^ 2 = 261000 := by
  norm_num
-- One block of 100,000 costs 13 times the temporary impact of 13 equal blocks.
example : (100000 : ℚ) ^ 2 = 13 * (13 * (100000 / 13) ^ 2) := by
  norm_num
-- Selling evenly: E = 1000 + 1000 + (ηt / τ) * 13 * (100000 / 13)² = 285000 / 13, shown as $21,923.08.
example : (1000 : ℚ) + 1000 + 259 / (13 * 10 ^ 7) / (1 / 13) * (13 * (100000 / 13) ^ 2)
    = 285000 / 13 := by
  norm_num

#print axioms ac_cross_partial
#print axioms ac_split
#print axioms ac_unique_min
#print axioms optimal_schedule_is_sinh_or_even
#print axioms permanent_impact_cost
#print axioms shocks_hit_shares_held
