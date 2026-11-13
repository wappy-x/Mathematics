-- Stepping the heat equation on a grid: the explicit FTCS step never leaves the starting range of readings when the time step is at most Δx^2/(2κ), a zigzag grows without limit above it, and each sine mode is multiplied by 1 - 4r sin^2(kπΔx/2) every step.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds
import Mathlib.Logic.Function.Iterate

open Real

/-- One FTCS step on the nodes `0, 1, …, N` with `r = κΔt/Δx²`: each inside reading
becomes `r·(left) + (1 − 2r)·(itself) + r·(right)`; the two end readings are held fixed. -/
noncomputable def ftcsStep (N : ℕ) (r : ℝ) (U : ℕ → ℝ) : ℕ → ℝ := fun j =>
  if j = 0 ∨ N ≤ j then U j else r * U (j - 1) + (1 - 2 * r) * U j + r * U (j + 1)

/-- `ftcs N r U₀ n j` is the reading at node `j` after `n` FTCS steps from the start `U₀`. -/
noncomputable def ftcs (N : ℕ) (r : ℝ) (U₀ : ℕ → ℝ) (n : ℕ) : ℕ → ℝ :=
  (ftcsStep N r)^[n] U₀

lemma ftcs_succ_apply (N : ℕ) (r : ℝ) (U₀ : ℕ → ℝ) (n : ℕ) :
    ftcs N r U₀ (n + 1) = ftcsStep N r (ftcs N r U₀ n) := by
  unfold ftcs
  rw [Function.iterate_succ_apply']

#print axioms ftcs_succ_apply

lemma ftcs_bad_factor (r : ℝ) (hr : 1 / 2 < r) :
    ∃ M : ℕ, 1 - 4 * r * Real.sin (((M + 1 : ℕ) : ℝ) * π / (2 * ((M + 2 : ℕ) : ℝ))) ^ 2 < -1 := by
  obtain ⟨M, hM⟩ := exists_nat_gt (4 * r / (r - 1 / 2))
  refine ⟨M, ?_⟩
  have hpos : (0 : ℝ) < r - 1 / 2 := by linarith
  have hM' : 4 * r < (M : ℝ) * (r - 1 / 2) := by
    rwa [div_lt_iff₀ hpos] at hM
  have hN : (0 : ℝ) < (M : ℝ) + 2 := by positivity
  set x : ℝ := π / (2 * ((M : ℝ) + 2)) with hx
  have heq : ((M + 1 : ℕ) : ℝ) * π / (2 * ((M + 2 : ℕ) : ℝ)) = π / 2 - x := by
    push_cast
    rw [hx]
    field_simp
    ring
  rw [heq, Real.sin_pi_div_two_sub]
  have hcs := Real.cos_sq_add_sin_sq x
  have hsx : Real.sin x ^ 2 ≤ x ^ 2 := Real.sin_sq_le_sq
  have hx0 : 0 < x := by rw [hx]; positivity
  have hx2 : x ≤ 2 / ((M : ℝ) + 2) := by
    rw [hx, div_le_div_iff₀ (by positivity) hN]
    nlinarith [Real.pi_le_four]
  have hx3 : x ^ 2 ≤ 4 / ((M : ℝ) + 2) := by
    have h1 : x ^ 2 ≤ (2 / ((M : ℝ) + 2)) ^ 2 := by
      exact pow_le_pow_left₀ hx0.le hx2 2
    have h2 : (2 / ((M : ℝ) + 2)) ^ 2 ≤ 4 / ((M : ℝ) + 2) := by
      rw [div_pow, div_le_div_iff₀ (by positivity) hN]
      nlinarith
    linarith
  have hr4 : r * (4 / ((M : ℝ) + 2)) < r - 1 / 2 := by
    rw [mul_div_assoc', div_lt_iff₀ hN]
    nlinarith
  nlinarith

#print axioms ftcs_bad_factor

lemma ftcs_mode (N k : ℕ) (r : ℝ) (n j : ℕ) (hj : j ≤ N) :
    ftcs N r (fun i => Real.sin (k * π * i / N)) n j =
      (1 - 4 * r * Real.sin (k * π / (2 * N)) ^ 2) ^ n * Real.sin (k * π * j / N) := by
  induction n generalizing j with
  | zero => simp [ftcs]
  | succ n ih =>
    rw [ftcs_succ_apply]
    unfold ftcsStep
    split_ifs with h
    · rw [ih j hj]
      have hs : Real.sin (k * π * j / N) = 0 := by
        rcases h with h | h
        · subst h; simp
        · have : j = N := le_antisymm hj h
          subst this
          rcases Nat.eq_zero_or_pos j with h0 | h0
          · subst h0; simp
          · have : (k : ℝ) * π * j / j = k * π := by
              field_simp
            rw [this, Real.sin_nat_mul_pi]
      rw [hs]; simp
    · push Not at h
      obtain ⟨h0, hN⟩ := h
      rw [ih (j - 1) (by omega), ih j hj, ih (j + 1) (by omega)]
      have hj1 : ((j - 1 : ℕ) : ℝ) = (j : ℝ) - 1 := by
        rw [Nat.cast_sub (by omega)]; simp
      rw [hj1]
      push_cast
      set a := (k : ℝ) * π * j / N
      set b := (k : ℝ) * π / (2 * N)
      have e1 : (k : ℝ) * π * (j - 1) / N = a - 2 * b := by
        simp only [a, b]; field_simp
      have e2 : (k : ℝ) * π * (j + 1) / N = a + 2 * b := by
        simp only [a, b]; field_simp
      rw [e1, e2, Real.sin_sub, Real.sin_add, Real.cos_two_mul]
      have := Real.sin_sq_add_cos_sq b
      rw [pow_succ]
      linear_combination 4 * r * Real.sin a * (1 - 4 * r * Real.sin b ^ 2) ^ n * this

#print axioms ftcs_mode

/-- The explicit scheme works exactly when the time step is small enough.
Take diffusivity `κ > 0`, time step `Δt > 0`, node spacing `Δx > 0`, and step a grid of
nodes `0, …, N` with `r = κΔt/Δx²`, ends held at their given temperatures.
If `Δt ≤ Δx²/(2κ)`, every step is an average: no reading ever goes above the largest
starting reading or below the smallest, for every grid, every start and every number of
steps. If `Δt > Δx²/(2κ)`, then on a fine enough grid there is a start, with both ends
at 0, whose readings grow without limit. -/
theorem ftcs_stable_exactly_when_time_step_small (κ Δt Δx : ℝ)
    (hκ : 0 < κ) (hΔt : 0 < Δt) (hΔx : 0 < Δx) :
    (Δt ≤ Δx ^ 2 / (2 * κ) →
      ∀ (N : ℕ) (U₀ : ℕ → ℝ) (m M : ℝ), (∀ j ≤ N, m ≤ U₀ j ∧ U₀ j ≤ M) →
        ∀ n : ℕ, ∀ j ≤ N,
          m ≤ ftcs N (κ * Δt / Δx ^ 2) U₀ n j ∧ ftcs N (κ * Δt / Δx ^ 2) U₀ n j ≤ M) ∧
    (Δx ^ 2 / (2 * κ) < Δt →
      ∃ (N : ℕ) (U₀ : ℕ → ℝ), U₀ 0 = 0 ∧ U₀ N = 0 ∧
        ∀ C : ℝ, ∃ n : ℕ, ∃ j ≤ N, C < |ftcs N (κ * Δt / Δx ^ 2) U₀ n j|) := by
  set r := κ * Δt / Δx ^ 2 with hr
  have hr0 : 0 < r := by positivity
  constructor
  · intro hdt N U₀ m M hU n
    have hr2 : r ≤ 1 / 2 := by
      rw [hr, div_le_iff₀ (by positivity)]
      rw [le_div_iff₀ (by positivity)] at hdt
      nlinarith
    induction n with
    | zero => simpa [ftcs] using hU
    | succ n ih =>
      intro j hj
      rw [ftcs_succ_apply]
      unfold ftcsStep
      split_ifs with h
      · exact ih j hj
      · push Not at h
        obtain ⟨a1, a2⟩ := ih (j - 1) (by omega)
        obtain ⟨b1, b2⟩ := ih j hj
        obtain ⟨c1, c2⟩ := ih (j + 1) (by omega)
        have hq : 0 ≤ 1 - 2 * r := by linarith
        constructor
        · nlinarith [mul_nonneg hr0.le (sub_nonneg.2 a1), mul_nonneg hq (sub_nonneg.2 b1),
            mul_nonneg hr0.le (sub_nonneg.2 c1)]
        · nlinarith [mul_nonneg hr0.le (sub_nonneg.2 a2), mul_nonneg hq (sub_nonneg.2 b2),
            mul_nonneg hr0.le (sub_nonneg.2 c2)]
  · intro hdt
    have hr2 : 1 / 2 < r := by
      rw [hr, lt_div_iff₀ (by positivity)]
      rw [div_lt_iff₀ (by positivity)] at hdt
      nlinarith
    obtain ⟨M, hM⟩ := ftcs_bad_factor r hr2
    refine ⟨M + 2, fun i => Real.sin (((M + 1 : ℕ) : ℝ) * π * i / ((M + 2 : ℕ) : ℝ)), ?_, ?_, ?_⟩
    · simp
    · show Real.sin (((M + 1 : ℕ) : ℝ) * π * ((M + 2 : ℕ) : ℝ) / ((M + 2 : ℕ) : ℝ)) = 0
      have hne : ((M + 2 : ℕ) : ℝ) ≠ 0 := by positivity
      rw [mul_div_assoc, div_self hne, mul_one]
      exact Real.sin_nat_mul_pi _
    · intro C
      have hs : 0 < Real.sin (((M + 1 : ℕ) : ℝ) * π * ((1 : ℕ) : ℝ) / ((M + 2 : ℕ) : ℝ)) := by
        have e : ((M + 1 : ℕ) : ℝ) * π * ((1 : ℕ) : ℝ) / ((M + 2 : ℕ) : ℝ)
            = π - π / ((M : ℝ) + 2) := by
          push_cast
          field_simp
          ring
        rw [e, Real.sin_pi_sub]
        apply Real.sin_pos_of_pos_of_lt_pi
        · positivity
        · rw [div_lt_iff₀ (by positivity)]
          nlinarith [Real.pi_pos]
      have hg1 : 1 < |1 - 4 * r * Real.sin (((M + 1 : ℕ) : ℝ) * π / (2 * ((M + 2 : ℕ) : ℝ))) ^ 2| := by
        rw [lt_abs]; right; linarith
      obtain ⟨n, hn⟩ := pow_unbounded_of_one_lt (C / Real.sin (((M + 1 : ℕ) : ℝ) * π * ((1 : ℕ) : ℝ) / ((M + 2 : ℕ) : ℝ))) hg1
      refine ⟨n, 1, by omega, ?_⟩
      rw [ftcs_mode (M + 2) (M + 1) r n 1 (by omega)]
      rw [abs_mul, abs_pow, abs_of_pos hs]
      rwa [div_lt_iff₀ hs] at hn

/-- Von Neumann analysis: on the rod `[0, 1]` cut into `N` gaps (`Δx = 1/N`), the mode
`sin(kπx)` keeps its shape under FTCS stepping and is multiplied by
`g = 1 − 4r sin²(kπΔx/2)` every step, so after `n` steps it is `gⁿ sin(kπx)`. -/
theorem ftcs_mode_grows_by_factor (N k : ℕ) (r : ℝ) (n j : ℕ) (hj : j ≤ N) :
    ftcs N r (fun i => Real.sin (k * π * i / N)) n j =
      (1 - 4 * r * Real.sin (k * π / (2 * N)) ^ 2) ^ n * Real.sin (k * π * j / N) := by
  exact ftcs_mode N k r n j hj

/-- The growth factor `g = 1 − 4r sin²(kπ/(2N))` stays at or above −1 for every mode
`k = 1, …, N − 1` on every grid exactly when `r ≤ 1/2`. -/
theorem ftcs_every_mode_factor_ge_neg_one_iff (r : ℝ) :
    (∀ N k : ℕ, 1 ≤ k → k < N → -1 ≤ 1 - 4 * r * Real.sin (k * π / (2 * N)) ^ 2) ↔
      r ≤ 1 / 2 := by
  constructor
  · intro h
    by_contra hr
    push Not at hr
    obtain ⟨M, hM⟩ := ftcs_bad_factor r hr
    have := h (M + 2) (M + 1) (by omega) (by omega)
    linarith
  · intro hr N k _ _
    have h0 := sq_nonneg (Real.sin (k * π / (2 * N)))
    have h1 := Real.sin_sq_le_one (k * π / (2 * N))
    nlinarith

-- Case A: κ = 1, Δx = 0.1 m, Δt = 0.004 s gives r = 0.4, inside the limit.
example : (1 : ℝ) * (4 / 1000) / (1 / 10) ^ 2 = 2 / 5 := by norm_num
-- Case B: Δt = 0.006 s gives r = 0.6, outside the limit.
example : (1 : ℝ) * (6 / 1000) / (1 / 10) ^ 2 = 3 / 5 := by norm_num
-- The limit on this rod: Δt ≤ Δx²/(2κ) = 0.005 s.
example : (1 / 10 : ℝ) ^ 2 / (2 * 1) = 5 / 1000 := by norm_num
-- Case A's weights 0.4, 0.2, 0.4 and case B's weights 0.6, −0.2, 0.6.
example : (1 : ℝ) - 2 * (2 / 5) = 1 / 5 := by norm_num
example : (1 : ℝ) - 2 * (3 / 5) = -1 / 5 := by norm_num
-- The pure zigzag in case B is multiplied by 1 − 4r = −1.4 each step.
example : (1 : ℝ) - 4 * (3 / 5) = -7 / 5 := by norm_num
-- The usual mistake: Δx = 0.05 m with Δt = 0.004 s gives r = 1.6.
example : (1 : ℝ) * (4 / 1000) / (1 / 20) ^ 2 = 8 / 5 := by norm_num
-- Forgetting the square: κΔt/Δx = 0.04.
example : (1 : ℝ) * (4 / 1000) / (1 / 10) = 1 / 25 := by norm_num

#print axioms ftcs_stable_exactly_when_time_step_small
#print axioms ftcs_mode_grows_by_factor
#print axioms ftcs_every_mode_factor_ge_neg_one_iff
