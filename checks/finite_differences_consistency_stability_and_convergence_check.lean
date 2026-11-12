-- Finite differences on a grid: a linear grid rule that is consistent and stable converges, with the error bounded by the stability constant times the summed truncation errors, and the explicit heat step is stable and consistent of order 2 when r ≤ 1/2.
import Mathlib.Analysis.Normed.Group.Basic
import Mathlib.Analysis.Normed.Module.Basic
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Data.Matrix.Mul
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Data.Matrix.Basic
import Mathlib.Analysis.Calculus.Taylor
import Mathlib.Analysis.Normed.Group.Constructions

open Matrix

/-- The step matrix of the explicit scheme for the heat equation on N inside nodes, with both
ends held at 0: row j has 1 - 2r on the diagonal and r next to it on each side, so that
(A u)_j = r u_(j-1) + (1 - 2r) u_j + r u_(j+1), a missing neighbour (an end) counting as 0. -/
def heatMatrix (N : ℕ) (r : ℝ) : Matrix (Fin N) (Fin N) ℝ :=
  fun i j => if i = j then 1 - 2 * r else if (i : ℕ) + 1 = j ∨ (j : ℕ) + 1 = i then r else 0

/-- The global error after m steps is the sum of the pushed truncation errors. -/
theorem grid_error_eq_sum {N : ℕ} (Δt : ℝ) (A : Matrix (Fin N) (Fin N) ℝ)
    (U u τ : ℕ → Fin N → ℝ) (n : ℕ)
    (hU : ∀ m < n, U (m + 1) = A *ᵥ U m + Δt • τ m) (h0 : u 0 = U 0)
    (hu : ∀ m < n, u (m + 1) = A *ᵥ u m) :
    ∀ m ≤ n, U m - u m = ∑ j ∈ Finset.range m, (A ^ (m - 1 - j)) *ᵥ (Δt • τ j) := by
  intro m hm
  induction m with
  | zero => simp [h0]
  | succ m ih =>
    have hmn : m < n := by omega
    rw [hU m hmn, hu m hmn, Finset.sum_range_succ]
    have hs : A *ᵥ (∑ j ∈ Finset.range m, (A ^ (m - 1 - j)) *ᵥ (Δt • τ j)) =
        ∑ j ∈ Finset.range m, (A ^ (m + 1 - 1 - j)) *ᵥ (Δt • τ j) := by
      rw [mulVec_sum]
      refine Finset.sum_congr rfl fun j hj => ?_
      have hj' : j < m := Finset.mem_range.1 hj
      rw [mulVec_mulVec, ← pow_succ']
      congr 2
      omega
    have h1 : m + 1 - 1 - m = 0 := by omega
    rw [h1, pow_zero, one_mulVec, ← hs, ← ih (by omega), mulVec_sub]
    abel

#print axioms grid_error_eq_sum

/-- One explicit heat step never raises the largest absolute value when 0 ≤ r ≤ 1/2. -/
theorem heat_step_le (r : ℝ) (hr0 : 0 ≤ r) (hr : r ≤ 1 / 2) (N : ℕ) (w : Fin N → ℝ) :
    ‖heatMatrix N r *ᵥ w‖ ≤ ‖w‖ := by
  refine (pi_norm_le_iff_of_nonneg (norm_nonneg w)).2 fun i => ?_
  have hnn : ∀ j, 0 ≤ heatMatrix N r i j := by
    intro j; unfold heatMatrix; split_ifs <;> linarith
  have hpt : ∀ j, heatMatrix N r i j ≤ (if j = i then 1 - 2 * r else 0) +
      (if (j : ℕ) = i + 1 then r else 0) + (if (j : ℕ) + 1 = i then r else 0) := by
    intro j; unfold heatMatrix
    by_cases hij : i = j
    · subst hij; simp
    · have hji : ¬ j = i := fun h => hij h.symm
      have hv : (i : ℕ) ≠ j := fun h => hij (Fin.ext h)
      simp only [hij, hji, ite_false]
      split_ifs <;> first | linarith | omega
  have hone : ∀ c : ℕ, (∑ j : Fin N, if (j : ℕ) = c then r else 0) ≤ r := by
    intro c
    rw [Finset.sum_ite, Finset.sum_const_zero, add_zero, Finset.sum_const, nsmul_eq_mul]
    have hc : (Finset.univ.filter fun j : Fin N => (j : ℕ) = c).card ≤ 1 :=
      Finset.card_le_one.2 fun a ha b hb => by
        simp only [Finset.mem_filter, Finset.mem_univ, true_and] at ha hb
        exact Fin.ext (by omega)
    have : ((Finset.univ.filter fun j : Fin N => (j : ℕ) = c).card : ℝ) ≤ 1 := by exact_mod_cast hc
    nlinarith
  have hrow : ∑ j, heatMatrix N r i j ≤ 1 := by
    calc ∑ j, heatMatrix N r i j
        ≤ ∑ j : Fin N, ((if j = i then 1 - 2 * r else 0) +
          (if (j : ℕ) = i + 1 then r else 0) + (if (j : ℕ) + 1 = i then r else 0)) :=
          Finset.sum_le_sum fun j _ => hpt j
      _ ≤ (1 - 2 * r) + r + r := by
          rw [Finset.sum_add_distrib, Finset.sum_add_distrib, Finset.sum_ite_eq']
          simp only [Finset.mem_univ, ite_true]
          have h2 := hone (i + 1)
          have h3 : (∑ j : Fin N, if (j : ℕ) + 1 = i then r else 0) ≤ r := by
            rcases Nat.eq_zero_or_pos (i : ℕ) with h | h
            · simp [h]; exact hr0
            · have := hone ((i : ℕ) - 1)
              calc (∑ j : Fin N, if (j : ℕ) + 1 = i then r else 0)
                  = ∑ j : Fin N, if (j : ℕ) = (i : ℕ) - 1 then r else 0 :=
                    Finset.sum_congr rfl fun j _ => by
                      congr 1; apply propext; omega
                _ ≤ r := this
          linarith
      _ = 1 := by ring
  calc ‖(heatMatrix N r *ᵥ w) i‖
      = ‖∑ j, heatMatrix N r i j * w j‖ := rfl
    _ ≤ ∑ j, ‖heatMatrix N r i j * w j‖ := norm_sum_le _ _
    _ ≤ ∑ j, heatMatrix N r i j * ‖w‖ := Finset.sum_le_sum fun j _ => by
        rw [norm_mul, Real.norm_of_nonneg (hnn j)]
        exact mul_le_mul_of_nonneg_left (norm_le_pi_norm w j) (hnn j)
    _ = (∑ j, heatMatrix N r i j) * ‖w‖ := (Finset.sum_mul _ _ _).symm
    _ ≤ 1 * ‖w‖ := mul_le_mul_of_nonneg_right hrow (norm_nonneg w)
    _ = ‖w‖ := one_mul _

#print axioms heat_step_le

/-- Taylor's theorem with the Lagrange remainder, with every derivative taken on the whole line. -/
theorem taylor_lagrange_line {f : ℝ → ℝ} (n : ℕ) {a b : ℝ} (hab : a ≠ b)
    (hf : ContDiff ℝ (n + 1) f) :
    ∃ ξ ∈ Set.uIoo a b, f b = ∑ k ∈ Finset.range (n + 1),
      ((k.factorial : ℝ)⁻¹ * (b - a) ^ k) * iteratedDeriv k f a +
      iteratedDeriv (n + 1) f ξ * (b - a) ^ (n + 1) / (n + 1).factorial := by
  obtain ⟨ξ, hξ, heq⟩ := taylor_mean_remainder_lagrange_iteratedDeriv hab hf.contDiffOn
  refine ⟨ξ, hξ, ?_⟩
  rw [← heq, taylor_within_apply]
  have hsum : ∑ k ∈ Finset.range (n + 1),
      ((k.factorial : ℝ)⁻¹ * (b - a) ^ k) • iteratedDerivWithin k f (Set.uIcc a b) a =
      ∑ k ∈ Finset.range (n + 1), ((k.factorial : ℝ)⁻¹ * (b - a) ^ k) * iteratedDeriv k f a := by
    refine Finset.sum_congr rfl fun k hk => ?_
    have hk' : k ≤ n + 1 := by have := Finset.mem_range.1 hk; omega
    rw [smul_eq_mul, iteratedDerivWithin_eq_iteratedDeriv (uniqueDiffOn_uIcc hab)
      (hf.contDiffAt.of_le (by exact_mod_cast hk')) Set.left_mem_uIcc]
  rw [hsum]
  ring

#print axioms taylor_lagrange_line

/-- Consistency plus stability gives convergence (the sufficiency half of the Lax equivalence
theorem). Fix a stability constant C ≥ 0, a consistency constant K ≥ 0, an order p and an end
time T, none depending on the grid. Take any grid: N values (max norm), spacing h > 0, time
step Δt > 0 and n steps with nΔt ≤ T, and a linear step u^(m+1) = A u^m with start
u^0 = U^0, where U^m are the exact values on the grid. Suppose the exact values satisfy the
rule up to the local truncation error, U^(m+1) = A U^m + Δt τ^m (this defines τ), that the
scheme is stable, ‖A^k v‖ ≤ C ‖v‖ for every k ≤ n, and consistent, ‖τ^m‖ ≤ K h^p. Then the grid
error is at most C times the summed pushes, ‖U^n - u^n‖ ≤ C Σ_(m<n) Δt ‖τ^m‖, and so at most
C T K h^p: the error shrinks at the same rate as the truncation error. -/
theorem consistent_and_stable_implies_convergent (C K T : ℝ) (p : ℕ) (hC : 0 ≤ C)
    (hK : 0 ≤ K) :
    ∀ (N : ℕ) (h Δt : ℝ) (A : Matrix (Fin N) (Fin N) ℝ) (U u τ : ℕ → Fin N → ℝ) (n : ℕ),
      0 < h → 0 < Δt → n * Δt ≤ T →
      (∀ k ≤ n, ∀ v : Fin N → ℝ, ‖(A ^ k) *ᵥ v‖ ≤ C * ‖v‖) →
      (∀ m < n, U (m + 1) = A *ᵥ U m + Δt • τ m) →
      (∀ m < n, ‖τ m‖ ≤ K * h ^ p) →
      u 0 = U 0 →
      (∀ m < n, u (m + 1) = A *ᵥ u m) →
      ‖U n - u n‖ ≤ C * ∑ m ∈ Finset.range n, Δt * ‖τ m‖ ∧
      ‖U n - u n‖ ≤ C * T * K * h ^ p := by
  intro N h Δt A U u τ n hh hΔt hT hstab hU hτ h0 hu
  have herr := grid_error_eq_sum Δt A U u τ n hU h0 hu n le_rfl
  have hfirst : ‖U n - u n‖ ≤ C * ∑ m ∈ Finset.range n, Δt * ‖τ m‖ := by
    rw [herr, Finset.mul_sum]
    refine (norm_sum_le _ _).trans (Finset.sum_le_sum fun j hj => ?_)
    have hj' : j < n := Finset.mem_range.1 hj
    calc ‖(A ^ (n - 1 - j)) *ᵥ (Δt • τ j)‖ ≤ C * ‖Δt • τ j‖ := hstab _ (by omega) _
      _ = C * (Δt * ‖τ j‖) := by rw [norm_smul, Real.norm_of_nonneg hΔt.le]
  refine ⟨hfirst, hfirst.trans ?_⟩
  have hKh : 0 ≤ K * h ^ p := mul_nonneg hK (pow_nonneg hh.le p)
  have hsum : ∑ m ∈ Finset.range n, Δt * ‖τ m‖ ≤ T * (K * h ^ p) := by
    calc ∑ m ∈ Finset.range n, Δt * ‖τ m‖ ≤ ∑ m ∈ Finset.range n, Δt * (K * h ^ p) :=
          Finset.sum_le_sum fun m hm =>
            mul_le_mul_of_nonneg_left (hτ m (Finset.mem_range.1 hm)) hΔt.le
      _ = (n * Δt) * (K * h ^ p) := by rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul]; ring
      _ ≤ T * (K * h ^ p) := mul_le_mul_of_nonneg_right hT hKh
  calc C * ∑ m ∈ Finset.range n, Δt * ‖τ m‖ ≤ C * (T * (K * h ^ p)) :=
        mul_le_mul_of_nonneg_left hsum hC
    _ = C * T * K * h ^ p := by ring

/-- The explicit heat step is stable with C = 1 when r ≤ 1/2. For 0 ≤ r ≤ 1/2 the weights
r, 1 - 2r, r are not negative and add to at most 1 on each row, so on every grid (every N)
any number k of steps never makes the largest absolute value bigger:
‖A^k v‖ ≤ ‖v‖ in the max norm. -/
theorem explicit_heat_step_stable (r : ℝ) (hr0 : 0 ≤ r) (hr : r ≤ 1 / 2) (N k : ℕ)
    (v : Fin N → ℝ) :
    ‖(heatMatrix N r ^ k) *ᵥ v‖ ≤ ‖v‖ := by
  induction k with
  | zero => simp
  | succ k ih =>
    rw [pow_succ', ← mulVec_mulVec]
    exact (heat_step_le r hr0 hr N _).trans ih

/-- The explicit heat step is consistent of order 2. Let u(x, t) solve the heat equation
u_t = α u_xx at the point (x, t), with α > 0, spacing h > 0 and time step Δt > 0. If u is twice
continuously differentiable in t with |u_tt| ≤ M₂ on [t, t + Δt], and four times continuously
differentiable in x with |u_xxxx| ≤ M₄ on [x - h, x + h], then the local truncation error
τ = (u(x, t + Δt) - u(x, t))/Δt - α (u(x + h, t) - 2u(x, t) + u(x - h, t))/h² satisfies
|τ| ≤ (Δt/2) M₂ + (α h²/12) M₄; with Δt = r h²/α this is h² (r M₂/(2α) + α M₄/12). -/
theorem heat_truncation_error_bound (u : ℝ → ℝ → ℝ) (α x t h Δt M₂ M₄ : ℝ) (hα : 0 < α)
    (hh : 0 < h) (hΔt : 0 < Δt)
    (hut : ContDiff ℝ 2 (fun s => u x s))
    (hux : ContDiff ℝ 4 (fun y => u y t))
    (hM₂ : ∀ s ∈ Set.Icc t (t + Δt), |iteratedDeriv 2 (fun s => u x s) s| ≤ M₂)
    (hM₄ : ∀ y ∈ Set.Icc (x - h) (x + h), |iteratedDeriv 4 (fun y => u y t) y| ≤ M₄)
    (hheat : deriv (fun s => u x s) t = α * iteratedDeriv 2 (fun y => u y t) x) :
    |(u x (t + Δt) - u x t) / Δt - α * (u (x + h) t - 2 * u x t + u (x - h) t) / h ^ 2| ≤
      Δt / 2 * M₂ + α * h ^ 2 / 12 * M₄ := by
  obtain ⟨η, hη, hT⟩ := taylor_lagrange_line (f := fun s => u x s) 1
    (a := t) (b := t + Δt) (by linarith) (hut.of_le (by norm_num))
  obtain ⟨ξ₁, hξ₁, hP⟩ := taylor_lagrange_line (f := fun y => u y t) 3
    (a := x) (b := x + h) (by linarith) (hux.of_le (by norm_num))
  obtain ⟨ξ₂, hξ₂, hM⟩ := taylor_lagrange_line (f := fun y => u y t) 3
    (a := x) (b := x - h) (by linarith) (hux.of_le (by norm_num))
  rw [Set.uIoo_of_le (by linarith)] at hη hξ₁
  rw [Set.uIoo_of_ge (by linarith)] at hξ₂
  simp only [Finset.sum_range_succ, Finset.sum_range_zero, iteratedDeriv_zero,
    iteratedDeriv_one, Nat.factorial] at hT hP hM
  push_cast at hT hP hM
  have b₂ := hM₂ η ⟨hη.1.le, hη.2.le⟩
  have b₄₁ := hM₄ ξ₁ ⟨by linarith [hξ₁.1], hξ₁.2.le⟩
  have b₄₂ := hM₄ ξ₂ ⟨hξ₂.1.le, by linarith [hξ₂.2]⟩
  set D2 := iteratedDeriv 2 (fun s => u x s) η
  set E1 := iteratedDeriv 4 (fun y => u y t) ξ₁
  set E2 := iteratedDeriv 4 (fun y => u y t) ξ₂
  have key : (u x (t + Δt) - u x t) / Δt - α * (u (x + h) t - 2 * u x t + u (x - h) t) / h ^ 2 =
      Δt / 2 * D2 - α * h ^ 2 / 24 * (E1 + E2) := by
    rw [hT, hP, hM]
    field_simp
    rw [hheat]
    ring
  rw [key]
  have hM₂0 : 0 ≤ M₂ := le_trans (abs_nonneg _) b₂
  calc |Δt / 2 * D2 - α * h ^ 2 / 24 * (E1 + E2)|
      ≤ |Δt / 2 * D2| + |α * h ^ 2 / 24 * (E1 + E2)| := abs_sub _ _
    _ = Δt / 2 * |D2| + α * h ^ 2 / 24 * |E1 + E2| := by
        rw [abs_mul, abs_mul, abs_of_pos (by positivity : (0:ℝ) < Δt / 2),
          abs_of_pos (by positivity : (0:ℝ) < α * h ^ 2 / 24)]
    _ ≤ Δt / 2 * M₂ + α * h ^ 2 / 24 * (M₄ + M₄) := by
        gcongr
        exact (abs_add_le _ _).trans (add_le_add b₄₁ b₄₂)
    _ = Δt / 2 * M₂ + α * h ^ 2 / 12 * M₄ := by ring

-- The 2 cm grid with 10 s steps: r = 1.2e-5 × 10 ÷ 0.02² = 0.3.
example : (12 : ℚ) / 10 ^ 6 * 10 / (2 / 100) ^ 2 = 3 / 10 := by norm_num
-- Weights r, 1 - 2r, r = 0.3, 0.4, 0.3, adding to 1.
example : 1 - 2 * ((3 : ℚ) / 10) = 4 / 10 ∧ (3 : ℚ) / 10 + 4 / 10 + 3 / 10 = 1 := by norm_num
-- The safe time step h²/(2α) = 0.0004 ÷ 0.000024 = 50/3 s, about 16.667 s; 10 s is inside it.
example : ((2 : ℚ) / 100) ^ 2 / (2 * (12 / 10 ^ 6)) = 50 / 3 ∧ (10 : ℚ) ≤ 50 / 3 := by norm_num
-- One hour in 10 s steps: 360 steps.
example : (3600 : ℚ) / 10 = 360 := by norm_num
-- 17 s steps on the 2 cm grid: r = 0.51, weights 0.51, -0.02, 0.51, absolute row sum 1.04.
example : (12 : ℚ) / 10 ^ 6 * 17 / (2 / 100) ^ 2 = 51 / 100 ∧
    1 - 2 * ((51 : ℚ) / 100) = -2 / 100 ∧
    (51 : ℚ) / 100 + |(-2 : ℚ) / 100| + 51 / 100 = 104 / 100 := by norm_num
-- The mistake αΔt/h, forgetting the square: 1.2e-5 × 10 ÷ 0.02 = 0.006.
example : (12 : ℚ) / 10 ^ 6 * 10 / (2 / 100) = 6 / 1000 := by norm_num
-- h halved to 0.01 m with Δt kept at 10 s: r = 1.2, past 1/2.
example : (12 : ℚ) / 10 ^ 6 * 10 / (1 / 100) ^ 2 = 12 / 10 ∧ (1 : ℚ) / 2 < 12 / 10 := by norm_num
-- At r = 0.3 the time step is r h²/α: 40, 10, 2.5 and 0.625 s at h = 0.04, 0.02, 0.01, 0.005,
-- giving 90, 360, 1440 and 5760 steps to 3600 s.
example : (3 : ℚ) / 10 * (4 / 100) ^ 2 / (12 / 10 ^ 6) = 40 ∧
    (3 : ℚ) / 10 * (1 / 100) ^ 2 / (12 / 10 ^ 6) = 5 / 2 ∧
    (3 : ℚ) / 10 * (5 / 1000) ^ 2 / (12 / 10 ^ 6) = 5 / 8 ∧
    (3600 : ℚ) / 40 = 90 ∧ (3600 : ℚ) / (5 / 2) = 1440 ∧ (3600 : ℚ) / (5 / 8) = 5760 := by
  norm_num
-- Node updates to 3600 s (inside nodes × steps): 2160, 17640, 142560, 1146240.
example : 24 * 90 = 2160 ∧ 49 * 360 = 17640 ∧ 99 * 1440 = 142560 ∧ 199 * 5760 = 1146240 := by
  norm_num

#print axioms consistent_and_stable_implies_convergent
#print axioms explicit_heat_step_stable
#print axioms heat_truncation_error_bound
