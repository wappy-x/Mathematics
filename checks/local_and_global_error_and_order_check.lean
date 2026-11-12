-- Order of a method: Euler's method misses by half the step squared times the second derivative in one step, its error at the end of a run is at most (M / 2L)(e^(LT) - 1) times the step, and the order is the base-2 logarithm of the error ratio when the step is halved.
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Log.Base
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Pow

/-- Helper: one Euler step's error as a Taylor remainder (Cauchy mean value theorem). -/
theorem euler_local_error_aux
    (f : ℝ → ℝ → ℝ) (v v' v'' : ℝ → ℝ) (t h : ℝ)
    (hv : ∀ s, HasDerivAt v (v' s) s)
    (hv' : ∀ s, HasDerivAt v' (v'' s) s)
    (hode : ∀ s, v' s = f s (v s))
    (hh : 0 < h) :
    ∃ ξ ∈ Set.Ioo t (t + h), v (t + h) - (v t + h * f t (v t)) = h ^ 2 / 2 * v'' ξ := by
  have hab : t < t + h := by linarith
  set G : ℝ → ℝ := fun s => v s - v t - (s - t) * v' t with hG
  set K : ℝ → ℝ := fun s => (s - t) ^ 2 with hK
  have hGd : ∀ s, HasDerivAt G (v' s - v' t) s := by
    intro s
    have := ((hv s).sub_const (v t)).sub (((hasDerivAt_id s).sub_const t).mul_const (v' t))
    convert this using 1
    · funext x; simp [hG]
    · ring
  have hKd : ∀ s, HasDerivAt K (2 * (s - t)) s := by
    intro s
    have := ((hasDerivAt_id s).sub_const t).pow 2
    convert this using 1
    · funext x; simp [hK]
    · simp
  obtain ⟨c, hc, hceq⟩ := exists_ratio_hasDerivAt_eq_ratio_slope G (fun s => v' s - v' t) hab
    (fun s _ => (hGd s).continuousAt.continuousWithinAt) (fun s _ => hGd s)
    K (fun s => 2 * (s - t)) (fun s _ => (hKd s).continuousAt.continuousWithinAt)
    (fun s _ => hKd s)
  obtain ⟨η, hη, hηeq⟩ := exists_hasDerivAt_eq_slope v' v'' hc.1
    (fun s _ => (hv' s).continuousAt.continuousWithinAt) (fun s _ => hv' s)
  refine ⟨η, ⟨hη.1, lt_trans hη.2 hc.2⟩, ?_⟩
  have hct : 0 < c - t := by linarith [hc.1]
  have h1 : v' c - v' t = v'' η * (c - t) := by
    rw [hηeq]; field_simp
  simp only [hG, hK, sub_self, add_sub_cancel_left] at hceq
  rw [h1] at hceq
  rw [← hode t]
  have : (h ^ 2 * v'' η - 2 * (v (t + h) - v t - h * v' t)) * (c - t) = 0 := by
    nlinarith [hceq]
  rcases mul_eq_zero.1 this with h2 | h2
  · linarith
  · linarith

#print axioms euler_local_error_aux

/-- Euler's global error is at most a constant times the step (order 1). Let `v` solve
`v' = f(t, v)` with a second derivative `v''` of size at most `M` on `[0, T]`, and let `f` react
to a change in `v` by at most `L` times that change (`L > 0`). Run Euler's rule
`u (n+1) = u n + h f(n h, u n)` from `u 0 = v 0` with step `h > 0` for `N` steps, `N h = T`.
Then after every `n ≤ N` steps the error is at most `(M / (2L)) (e^(LT) - 1) h`. -/
theorem euler_global_error_le_const_mul_step
    (f : ℝ → ℝ → ℝ) (v v' v'' : ℝ → ℝ) (M L h T : ℝ) (N : ℕ)
    (hv : ∀ t, HasDerivAt v (v' t) t)
    (hv' : ∀ t, HasDerivAt v' (v'' t) t)
    (hode : ∀ t, v' t = f t (v t))
    (hM : ∀ t ∈ Set.Icc 0 T, |v'' t| ≤ M)
    (hL : 0 < L)
    (hLip : ∀ t x y, |f t x - f t y| ≤ L * |x - y|)
    (hh : 0 < h) (hT : (N : ℝ) * h = T)
    (u : ℕ → ℝ) (hu0 : u 0 = v 0)
    (hu : ∀ n : ℕ, u (n + 1) = u n + h * f (n * h) (u n)) :
    ∀ n ≤ N, |u n - v (n * h)| ≤ M / (2 * L) * (Real.exp (L * T) - 1) * h := by
  have hT0 : 0 ≤ T := by rw [← hT]; positivity
  have hM0 : 0 ≤ M := le_trans (abs_nonneg _) (hM 0 ⟨le_refl 0, hT0⟩)
  -- one-step recursion for the error
  have hstep : ∀ n : ℕ, n < N →
      |u (n + 1) - v ((n + 1 : ℕ) * h)| ≤ (1 + h * L) * |u n - v (n * h)| + h ^ 2 / 2 * M := by
    intro n hn
    obtain ⟨ξ, hξ, hξeq⟩ := euler_local_error_aux f v v' v'' (n * h) h hv hv' hode hh
    have hnN : ((n : ℝ) + 1) ≤ N := by exact_mod_cast hn
    have hξI : ξ ∈ Set.Icc 0 T := by
      constructor
      · have : 0 ≤ (n : ℝ) * h := by positivity
        linarith [hξ.1]
      · have : ((n : ℝ) + 1) * h ≤ N * h := mul_le_mul_of_nonneg_right hnN hh.le
        nlinarith [hξ.2]
    have hcast : ((n + 1 : ℕ) : ℝ) * h = n * h + h := by push_cast; ring
    rw [hcast, hu n]
    have hrw : u n + h * f (n * h) (u n) - v (n * h + h)
        = (u n - v (n * h)) + h * (f (n * h) (u n) - f (n * h) (v (n * h)))
          - h ^ 2 / 2 * v'' ξ := by
      rw [← hξeq]; ring
    rw [hrw]
    have h1 := hLip (n * h) (u n) (v (n * h))
    have h2 := hM ξ hξI
    have h3 : |h ^ 2 / 2 * v'' ξ| ≤ h ^ 2 / 2 * M := by
      rw [abs_mul, abs_of_nonneg (by positivity : (0:ℝ) ≤ h ^ 2 / 2)]
      exact mul_le_mul_of_nonneg_left h2 (by positivity)
    have h4 : |h * (f (n * h) (u n) - f (n * h) (v (n * h)))| ≤ h * (L * |u n - v (n * h)|) := by
      rw [abs_mul, abs_of_pos hh]
      exact mul_le_mul_of_nonneg_left h1 hh.le
    calc |(u n - v (n * h)) + h * (f (n * h) (u n) - f (n * h) (v (n * h))) - h ^ 2 / 2 * v'' ξ|
        ≤ |(u n - v (n * h)) + h * (f (n * h) (u n) - f (n * h) (v (n * h)))|
          + |h ^ 2 / 2 * v'' ξ| := abs_sub _ _
      _ ≤ |u n - v (n * h)| + |h * (f (n * h) (u n) - f (n * h) (v (n * h)))|
          + |h ^ 2 / 2 * v'' ξ| := by gcongr; exact abs_add_le _ _
      _ ≤ |u n - v (n * h)| + h * (L * |u n - v (n * h)|) + h ^ 2 / 2 * M := by linarith
      _ = (1 + h * L) * |u n - v (n * h)| + h ^ 2 / 2 * M := by ring
  -- discrete bound by induction
  have hdisc : ∀ n : ℕ, n ≤ N →
      |u n - v (n * h)| ≤ M / (2 * L) * ((1 + h * L) ^ n - 1) * h := by
    intro n
    induction n with
    | zero => intro _; simp [hu0]
    | succ k ih =>
      intro hk
      have hkN : k < N := hk
      have ihk := ih hkN.le
      have hs := hstep k hkN
      have hpos : 0 ≤ 1 + h * L := by positivity
      have key : (1 + h * L) * (M / (2 * L) * ((1 + h * L) ^ k - 1) * h) + h ^ 2 / 2 * M
          = M / (2 * L) * ((1 + h * L) ^ (k + 1) - 1) * h := by
        field_simp; ring
      calc |u (k + 1) - v (((k + 1 : ℕ) : ℝ) * h)|
          ≤ (1 + h * L) * |u k - v (k * h)| + h ^ 2 / 2 * M := hs
        _ ≤ (1 + h * L) * (M / (2 * L) * ((1 + h * L) ^ k - 1) * h) + h ^ 2 / 2 * M := by
          gcongr
        _ = M / (2 * L) * ((1 + h * L) ^ (k + 1) - 1) * h := key
  intro n hn
  refine le_trans (hdisc n hn) ?_
  have hexp : (1 + h * L) ^ n ≤ Real.exp (L * T) := by
    calc (1 + h * L) ^ n ≤ Real.exp (h * L) ^ n := by
          gcongr
          linarith [Real.add_one_le_exp (h * L)]
      _ = Real.exp (n * (h * L)) := (Real.exp_nat_mul _ _).symm
      _ ≤ Real.exp (L * T) := by
          apply Real.exp_le_exp.2
          have : (n : ℝ) ≤ N := by exact_mod_cast hn
          rw [← hT]
          nlinarith [mul_le_mul_of_nonneg_right this (le_of_lt (mul_pos hh hL))]
  have hc : 0 ≤ M / (2 * L) := by positivity
  gcongr

/-- One Euler step's error, from Taylor's theorem with its remainder: started from the exact
value at time `t`, one step of length `h > 0` misses the solution of `v' = f(t, v)` by exactly
`(h^2 / 2) v''(ξ)` for some time `ξ` inside the step. -/
theorem euler_one_step_error_eq_taylor_remainder
    (f : ℝ → ℝ → ℝ) (v v' v'' : ℝ → ℝ) (t h : ℝ)
    (hv : ∀ s, HasDerivAt v (v' s) s)
    (hv' : ∀ s, HasDerivAt v' (v'' s) s)
    (hode : ∀ s, v' s = f s (v s))
    (hh : 0 < h) :
    ∃ ξ ∈ Set.Ioo t (t + h), v (t + h) - (v t + h * f t (v t)) = h ^ 2 / 2 * v'' ξ := by
  exact euler_local_error_aux f v v' v'' t h hv hv' hode hh

/-- Reading the order off two runs: if the error is `C h^p` at step `h` and `C (h/2)^p` at half
the step, the constant `C` cancels and the base-2 logarithm of the ratio is the order `p`. -/
theorem order_eq_logb_two_of_error_ratio
    (C h p : ℝ) (hC : 0 < C) (hh : 0 < h) :
    Real.logb 2 ((C * h ^ p) / (C * (h / 2) ^ p)) = p := by
  have hp : 0 < h ^ p := Real.rpow_pos_of_pos hh p
  have h2 : 0 < (2:ℝ) ^ p := Real.rpow_pos_of_pos (by norm_num) p
  rw [Real.div_rpow hh.le (by norm_num : (0:ℝ) ≤ 2)]
  have : (C * h ^ p) / (C * (h ^ p / 2 ^ p)) = 2 ^ p := by
    field_simp
  rw [this, Real.logb_rpow (by norm_num) (by norm_num)]

-- Reaching 10 s takes 10/h steps: five 2 s steps, ten 1 s steps, twenty 0.5 s steps.
example : (10 : ℚ) / 2 = 5 ∧ (10 : ℚ) / 1 = 10 ∧ (10 : ℚ) / (1 / 2) = 20 := by norm_num

-- Halving the step cuts an order-1 error twofold, an order-2 error fourfold (the usual
-- mistake's guess) and an order-4 error sixteenfold.
example : 2 ^ 1 = 2 ∧ 2 ^ 2 = 4 ∧ 2 ^ 4 = 16 := by decide

#print axioms euler_global_error_le_const_mul_step
#print axioms euler_one_step_error_eq_taylor_remainder
#print axioms order_eq_logb_two_of_error_ratio
