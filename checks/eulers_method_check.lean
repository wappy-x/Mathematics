-- Euler's method: for a rule that reacts to the unknown at a bounded rate L and a true curve that bends at most M, Euler's error at every step up to time T is at most (M / 2L)(e^(LT) - 1) h, and for the skydiver the steps have the closed form 49(1 - (1 - h/5)^n) that tends to the exact speed.
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.SpecialFunctions.Complex.LogBounds

open Filter Topology Set

/-- Local error of one Euler step: a second-order Taylor bound. -/
theorem euler_local_error_le (y g g' : ℝ → ℝ) (T M a b : ℝ) (ha : 0 ≤ a) (hab : a ≤ b)
    (hb : b ≤ T)
    (hy : ∀ t ∈ Icc 0 T, HasDerivWithinAt y (g t) (Icc 0 T) t)
    (hg : ∀ t ∈ Icc 0 T, HasDerivWithinAt g (g' t) (Icc 0 T) t)
    (hM : ∀ t ∈ Icc 0 T, |g' t| ≤ M) :
    |y b - y a - (b - a) * g a| ≤ M / 2 * (b - a) ^ 2 := by
  have hsub : Icc a b ⊆ Icc 0 T := Icc_subset_Icc ha hb
  have h1 : ∀ s ∈ Icc a b, ‖g s - g a‖ ≤ M * (s - a) := by
    refine norm_image_sub_le_of_norm_deriv_le_segment' (f' := g')
      (fun x hx => (hg x (hsub hx)).mono hsub) (fun x hx => ?_)
    exact hM x (hsub (Ico_subset_Icc_self hx))
  have hcont : ContinuousOn (fun s => y s - y a - (s - a) * g a) (Icc a b) := by
    have : ContinuousOn y (Icc a b) := fun x hx =>
      ((hy x (hsub hx)).continuousWithinAt).mono hsub
    fun_prop
  have hder : ∀ x ∈ Ico a b, HasDerivWithinAt (fun s => y s - y a - (s - a) * g a)
      (g x - g a) (Ici x) x := by
    intro x hx
    have hx' : x ∈ Icc a b := Ico_subset_Icc_self hx
    have h2 : HasDerivWithinAt y (g x) (Ici x) x :=
      ((hy x (hsub hx')).mono hsub).mono_of_mem_nhdsWithin (Icc_mem_nhdsGE_of_mem hx)
    have h3 : HasDerivWithinAt (fun s => (s - a) * g a) (1 * g a) (Ici x) x :=
      ((hasDerivWithinAt_id x _).sub_const a).mul_const (g a)
    exact ((h2.sub_const (y a)).sub h3).congr_deriv (by ring)
  have hB : ∀ x, HasDerivAt (fun s => M / 2 * (s - a) ^ 2) (M * (x - a)) x := by
    intro x
    have := (((hasDerivAt_id' x).sub_const a).pow 2).const_mul (M / 2)
    convert this using 1
    norm_num; ring
  have key := image_norm_le_of_norm_deriv_right_le_deriv_boundary hcont hder
    (by simp) hB (fun x hx => h1 x (Ico_subset_Icc_self hx)) ⟨hab, le_rfl⟩
  simpa [Real.norm_eq_abs] using key

#print axioms euler_local_error_le

/-- Euler's error bound for any rule. Let `y` be the true solution of `y' = f(t, y)` on
`0 ≤ t ≤ T`, whose slope `t ↦ f(t, y(t))` has derivative `y''` there with `|y''| ≤ M` (the
curve bends a bounded amount), and let the rule react to `y` at a bounded rate:
`|f(t, a) - f(t, b)| ≤ L |a - b|`. Start Euler's steps of length `h > 0` at the true value,
`y₀ = y(0)`, `y_{n+1} = y_n + h f(t_n, y_n)` with `t_n = n h`. Then at every step time
`t_n ≤ T` the error is at most `(M / 2L)(e^(LT) - 1) h`: proportional to the step. -/
theorem euler_error_le_proportional_to_step
    (f : ℝ → ℝ → ℝ) (y y'' : ℝ → ℝ) (yE : ℕ → ℝ) (T L M h : ℝ)
    (hL : 0 < L) (hh : 0 < h)
    (hy : ∀ t ∈ Icc 0 T, HasDerivWithinAt y (f t (y t)) (Icc 0 T) t)
    (hy'' : ∀ t ∈ Icc 0 T, HasDerivWithinAt (fun s => f s (y s)) (y'' t) (Icc 0 T) t)
    (hM : ∀ t ∈ Icc 0 T, |y'' t| ≤ M)
    (hLip : ∀ t ∈ Icc 0 T, ∀ a b : ℝ, |f t a - f t b| ≤ L * |a - b|)
    (h0 : yE 0 = y 0)
    (hstep : ∀ n : ℕ, yE (n + 1) = yE n + h * f (n * h) (yE n)) :
    ∀ n : ℕ, (n : ℝ) * h ≤ T →
      |yE n - y (n * h)| ≤ M / (2 * L) * (Real.exp (L * T) - 1) * h := by
  have claim : ∀ n : ℕ, (n : ℝ) * h ≤ T →
      |yE n - y (n * h)| ≤ M * h / (2 * L) * ((1 + h * L) ^ n - 1) := by
    intro n
    induction n with
    | zero => intro _; simp [h0]
    | succ n ih =>
      intro hn
      have hn0 : (0 : ℝ) ≤ n * h := by positivity
      have hnT : (n : ℝ) * h ≤ T := by push_cast at hn; nlinarith
      have hT : 0 ≤ T := hn0.trans hnT
      have hM0 : 0 ≤ M := (abs_nonneg _).trans (hM 0 ⟨le_rfl, hT⟩)
      have ihn := ih hnT
      have hmem : (n : ℝ) * h ∈ Icc 0 T := ⟨hn0, hnT⟩
      have hloc := euler_local_error_le y (fun s => f s (y s)) y'' T M (n * h) ((n + 1 : ℕ) * h)
        hn0 (by push_cast; nlinarith) hn hy hy'' hM
      have hlip := hLip (n * h) hmem (yE n) (y (n * h))
      have hcast : ((n + 1 : ℕ) : ℝ) * h - n * h = h := by push_cast; ring
      rw [hcast] at hloc
      have hid : yE (n + 1) - y ((n + 1 : ℕ) * h) =
          (yE n - y (n * h)) + h * (f (n * h) (yE n) - f (n * h) (y (n * h)))
            - (y ((n + 1 : ℕ) * h) - y (n * h) - h * f (n * h) (y (n * h))) := by
        rw [hstep]; ring
      rw [hid]
      have hpow : (1 + h * L) ^ (n + 1) = (1 + h * L) * (1 + h * L) ^ n := by ring
      calc |(yE n - y (n * h)) + h * (f (n * h) (yE n) - f (n * h) (y (n * h)))
            - (y ((n + 1 : ℕ) * h) - y (n * h) - h * f (n * h) (y (n * h)))|
          ≤ |yE n - y (n * h)| + h * |f (n * h) (yE n) - f (n * h) (y (n * h))|
            + |y ((n + 1 : ℕ) * h) - y (n * h) - h * f (n * h) (y (n * h))| := by
            have := abs_sub (yE n - y (n * h) + h * (f (n * h) (yE n) - f (n * h) (y (n * h))))
              (y ((n + 1 : ℕ) * h) - y (n * h) - h * f (n * h) (y (n * h)))
            have := abs_add_le (yE n - y (n * h)) (h * (f (n * h) (yE n) - f (n * h) (y (n * h))))
            rw [abs_mul, abs_of_pos hh] at this
            linarith
        _ ≤ |yE n - y (n * h)| + h * (L * |yE n - y (n * h)|) + M / 2 * h ^ 2 := by
            gcongr
        _ = (1 + h * L) * |yE n - y (n * h)| + M / 2 * h ^ 2 := by ring
        _ ≤ (1 + h * L) * (M * h / (2 * L) * ((1 + h * L) ^ n - 1)) + M / 2 * h ^ 2 := by
            gcongr
        _ = M * h / (2 * L) * ((1 + h * L) ^ (n + 1) - 1) := by
            rw [hpow]; field_simp; ring
  intro n hn
  have hT : 0 ≤ T := (by positivity : (0 : ℝ) ≤ n * h).trans hn
  have hM0 : 0 ≤ M := (abs_nonneg _).trans (hM 0 ⟨le_rfl, hT⟩)
  refine (claim n hn).trans ?_
  have hp : (1 + h * L) ^ n ≤ Real.exp (L * T) := by
    calc (1 + h * L) ^ n ≤ Real.exp (h * L) ^ n := by
          exact pow_le_pow_left₀ (by positivity) (by linarith [Real.add_one_le_exp (h * L)]) n
      _ = Real.exp (n * (h * L)) := by rw [← Real.exp_nat_mul]
      _ ≤ Real.exp (L * T) := by
          apply Real.exp_le_exp.mpr
          nlinarith
  have hc : 0 ≤ M * h / (2 * L) := by positivity
  calc M * h / (2 * L) * ((1 + h * L) ^ n - 1)
      ≤ M * h / (2 * L) * (Real.exp (L * T) - 1) := by gcongr
    _ = M / (2 * L) * (Real.exp (L * T) - 1) * h := by ring

/-- The skydiver's steps in closed form: Euler for `v' = 9.8 - 0.2 v` from rest, with any step
`h`, gives `v_n = 49 (1 - (1 - 0.2 h)^n)`, because each step multiplies the gap to 49 m/s by
`1 - 0.2 h`. -/
theorem skydiver_euler_closed_form
    (h : ℝ) (v : ℕ → ℝ) (h0 : v 0 = 0)
    (hstep : ∀ n : ℕ, v (n + 1) = v n + h * (49 / 5 - v n / 5)) :
    ∀ n : ℕ, v n = 49 * (1 - (1 - h / 5) ^ n) := by
  intro n
  induction n with
  | zero => simp [h0]
  | succ n ih => rw [hstep, ih]; ring

/-- The smaller the step, the closer you land: reaching time `t` in `n` equal steps of
`h = t / n`, the skydiver's Euler speed `49 (1 - (1 - 0.2 h)^n)` tends to the exact speed
`49 (1 - e^(-0.2 t))` as the number of steps grows. -/
theorem skydiver_euler_tendsto_exact (t : ℝ) :
    Tendsto (fun n : ℕ => 49 * (1 - (1 - (t / n) / 5) ^ n)) atTop
      (𝓝 (49 * (1 - Real.exp (-(t / 5))))) := by
  have h := Real.tendsto_one_add_div_pow_exp (-(t / 5))
  have h' : (fun n : ℕ => (1 + -(t / 5) / (n : ℝ)) ^ n) = fun n : ℕ => (1 - (t / n) / 5) ^ n := by
    funext n; congr 1; ring
  rw [h'] at h
  exact (h.const_sub 1).const_mul 49

-- Terminal speed: drag 0.2 v cancels gravity 9.8 at v = 49 m/s.
example : (49 : ℚ) / 5 - 49 / 5 = 0 := by norm_num

-- Steps of 2 s from rest: 19.60, 31.36, 38.416, 42.6496, 45.18976 m/s, exactly.
example : (fun v : ℚ => v + 2 * (49 / 5 - v / 5))^[1] 0 = 98 / 5 ∧
    (fun v : ℚ => v + 2 * (49 / 5 - v / 5))^[2] 0 = 784 / 25 ∧
    (fun v : ℚ => v + 2 * (49 / 5 - v / 5))^[3] 0 = 4802 / 125 ∧
    (fun v : ℚ => v + 2 * (49 / 5 - v / 5))^[4] 0 = 26656 / 625 ∧
    (fun v : ℚ => v + 2 * (49 / 5 - v / 5))^[5] 0 = 141218 / 3125 := by
  norm_num [Function.iterate_succ_apply']

-- The closed form at h = 2 after 5 steps gives the loop's 45.18976 m/s.
example : (49 : ℚ) * (1 - (1 - 2 / 5) ^ 5) = 141218 / 3125 := by norm_num

-- Steps of 1 s: ten steps reach 43.7387... m/s at 10 s.
example : (fun v : ℚ => v + 1 * (49 / 5 - v / 5))^[10] 0 = 427135401 / 9765625 := by
  norm_num [Function.iterate_succ_apply']

-- Mistake, h left out: five steps of v + f give 32.94... m/s "at 10 s".
example : (fun v : ℚ => v + (49 / 5 - v / 5))^[5] 0 = 102949 / 3125 := by
  norm_num [Function.iterate_succ_apply']

-- Mistake, slope never updated: 9.8 × 10 = 98 m/s.
example : (49 : ℚ) / 5 * 10 = 98 := by norm_num

-- Mistake, step of 15 s: four steps reach -735 m/s at 60 s; the factor 1 - 0.2 × 15 is -2.
example : (fun v : ℚ => v + 15 * (49 / 5 - v / 5))^[4] 0 = -735 := by
  norm_num [Function.iterate_succ_apply']

-- The stability limit: the factor 1 - 0.2 h equals -1 at h = 10, and is 0 at h = 5.
example : (1 : ℚ) - 10 / 5 = -1 ∧ (1 : ℚ) - 5 / 5 = 0 := by norm_num

#print axioms euler_error_le_proportional_to_step
#print axioms skydiver_euler_closed_form
#print axioms skydiver_euler_tendsto_exact
