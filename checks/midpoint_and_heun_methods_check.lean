-- Midpoint and Heun: for a rule that is a straight line in speed both methods shrink the gap to the balance speed by q = 1 - x + x²/2 and err by at most a constant times the step squared at a fixed end time, and for every smooth rule a two-sample step with b₁ + b₂ = 1 and b₂ c = 1/2 misses the true curve by a multiple of the step cubed.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Asymptotics.Defs
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.ContDiff.RCLike
import Mathlib.Analysis.Calculus.ContDiff.Comp
import Mathlib.Analysis.Calculus.Deriv.Shift
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Asymptotics.Lemmas

open Asymptotics Filter Topology

/-! The rule `f t v` gives the rate of the speed `v` at time `t`. A step of length `h` turns the
speed `v` at time `t` into the next speed. -/

/-- Heun's step: walk a whole step on the first slope `k₁ = f t v`, read the slope `k₂` there,
and step with the average of the two. -/
noncomputable def heunStep (f : ℝ → ℝ → ℝ) (h t v : ℝ) : ℝ :=
  v + h / 2 * (f t v + f (t + h) (v + h * f t v))

/-- The midpoint step: walk half a step on the first slope, read the slope there, and use it
for the whole step. -/
noncomputable def midpointStep (f : ℝ → ℝ → ℝ) (h t v : ℝ) : ℝ :=
  v + h * f (t + h / 2) (v + h / 2 * f t v)

/-- The two-sample family: `k₂ = f (t + c h) (v + c h k₁)` and `v + h (b₁ k₁ + b₂ k₂)`. -/
noncomputable def twoSampleStep (b₁ b₂ c : ℝ) (f : ℝ → ℝ → ℝ) (h t v : ℝ) : ℝ :=
  v + h * (b₁ * f t v + b₂ * f (t + c * h) (v + c * h * f t v))

/-- Run a step rule from `v₀` with steps of length `h`: entry `n` is the speed after `n` steps,
the `n`-th step starting at time `t_n = n h`. -/
noncomputable def stepRun (step : ℝ → ℝ → ℝ) (h v₀ : ℝ) : ℕ → ℝ
  | 0 => v₀
  | n + 1 => step (n * h) (stepRun step h v₀ n)


/-- Helper: a function vanishing at `0` whose derivative is `O(s^n)` is `O(s^(n+1))`. -/
lemma mvh_isBigO_of_deriv {φ φ' : ℝ → ℝ} {n : ℕ} (h0 : φ 0 = 0)
    (hd : ∀ᶠ s in 𝓝 (0:ℝ), HasDerivAt φ (φ' s) s)
    (hb : φ' =O[𝓝 0] (fun s => s ^ n)) : φ =O[𝓝 0] (fun s => s ^ (n + 1)) := by
  obtain ⟨C, hC, hCw⟩ := hb.exists_pos
  have hev := hd.and hCw.bound
  obtain ⟨ε, hε, hball⟩ := Metric.eventually_nhds_iff.1 hev
  refine Asymptotics.IsBigO.of_bound C ?_
  filter_upwards [Metric.ball_mem_nhds (0:ℝ) hε] with h hh
  have hh' : |h| < ε := by simpa [Real.dist_eq] using hh
  have hsub : ∀ s ∈ Metric.closedBall (0:ℝ) |h|, dist s 0 < ε := fun s hs =>
    lt_of_le_of_lt (by simpa using hs) hh'
  have key := Convex.norm_image_sub_le_of_norm_hasDerivWithin_le (f := φ) (f' := φ')
    (C := C * |h| ^ n) (s := Metric.closedBall (0:ℝ) |h|) (x := 0) (y := h)
    (fun s hs => ((hball (hsub s hs)).1).hasDerivWithinAt)
    (fun s hs => by
      have h1 := (hball (hsub s hs)).2
      have hs' : |s| ≤ |h| := by simpa using hs
      calc ‖φ' s‖ ≤ C * ‖s ^ n‖ := h1
        _ ≤ C * |h| ^ n := by
          rw [norm_pow, Real.norm_eq_abs]
          exact mul_le_mul_of_nonneg_left (pow_le_pow_left₀ (abs_nonneg _) hs' n) hC.le)
    (convex_closedBall _ _) (by simp) (by simp)
  rw [h0, sub_zero, sub_zero] at key
  rw [norm_pow, Real.norm_eq_abs, pow_succ]
  calc ‖φ h‖ ≤ C * |h| ^ n * ‖h‖ := key
    _ = C * (|h| ^ n * |h|) := by rw [Real.norm_eq_abs]; ring

/-- Helper: second-order Taylor bound for a `C²` function of two variables. -/
lemma mvh_taylor2 {F : ℝ × ℝ → ℝ} (hF : ContDiff ℝ 2 F) (P : ℝ × ℝ) :
    (fun Δ => F (P + Δ) - F P - fderiv ℝ F P Δ) =O[𝓝 0] (fun Δ => ‖Δ‖ ^ 2) := by
  have hF1 : ContDiff ℝ 1 (fderiv ℝ F) := hF.fderiv_right (by norm_num)
  obtain ⟨K, U, hU, hL⟩ := (hF1.contDiffAt (x := P)).exists_lipschitzOnWith
  obtain ⟨r, hr, hrU⟩ := Metric.mem_nhds_iff.1 hU
  have hdiff : Differentiable ℝ F := hF.differentiable (by norm_num)
  refine Asymptotics.IsBigO.of_bound (K : ℝ) ?_
  filter_upwards [Metric.ball_mem_nhds (0 : ℝ × ℝ) hr] with Δ hΔ
  have hΔ' : ‖Δ‖ < r := by simpa using hΔ
  have hSU : Metric.closedBall P ‖Δ‖ ⊆ U := fun x hx =>
    hrU (Metric.mem_ball.2 (lt_of_le_of_lt (Metric.mem_closedBall.1 hx) hΔ'))
  have hPS : P ∈ Metric.closedBall P ‖Δ‖ := Metric.mem_closedBall_self (norm_nonneg _)
  have key := Convex.norm_image_sub_le_of_norm_hasFDerivWithin_le
    (f := fun x => F x - fderiv ℝ F P x)
    (f' := fun x => fderiv ℝ F x - fderiv ℝ F P) (C := K * ‖Δ‖)
    (s := Metric.closedBall P ‖Δ‖) (x := P) (y := P + Δ)
    (fun x _ => ((hdiff x).hasFDerivAt.sub (fderiv ℝ F P).hasFDerivAt).hasFDerivWithinAt)
    (fun x hx => by
      have := hL.dist_le_mul x (hSU hx) P (hSU hPS)
      rw [dist_eq_norm, dist_eq_norm] at this
      calc _ ≤ (K : ℝ) * ‖x - P‖ := this
        _ ≤ K * ‖Δ‖ := mul_le_mul_of_nonneg_left
            (by simpa [dist_eq_norm] using hx) K.coe_nonneg)
    (convex_closedBall _ _) hPS (by simp [dist_eq_norm])
  rw [norm_pow, norm_norm, sq]
  calc ‖F (P + Δ) - F P - fderiv ℝ F P Δ‖
      = ‖F (P + Δ) - fderiv ℝ F P (P + Δ) - (F P - fderiv ℝ F P P)‖ := by
        rw [map_add]; congr 1; ring
    _ ≤ K * ‖Δ‖ * ‖P + Δ - P‖ := key
    _ = K * (‖Δ‖ * ‖Δ‖) := by rw [add_sub_cancel_left]; ring

/-- Helper: `q = 1 - x + x²/2` is within `3 x³` of `e^(-x)` for `x ≥ 0`. -/
lemma mvh_q_close (x : ℝ) (hx : 0 ≤ x) : |(1 - x + x ^ 2 / 2) - Real.exp (-x)| ≤ 3 * x ^ 3 := by
  rcases le_or_gt x 1 with h1 | h1
  · have hb := Real.exp_bound (x := -x) (by rw [abs_neg, abs_of_nonneg hx]; exact h1)
      (n := 3) (by norm_num)
    simp [Finset.sum_range_succ, Nat.factorial, abs_neg, abs_of_nonneg hx] at hb
    rw [abs_sub_comm]
    calc _ = |Real.exp (-x) - (1 + -x + x ^ 2 / 2)| := by ring_nf
      _ ≤ x ^ 3 * (4 / 18) := by convert hb using 2 <;> norm_num
      _ ≤ 3 * x ^ 3 := by nlinarith [pow_nonneg hx 3]
  · have hr0 : 0 < Real.exp (-x) := Real.exp_pos _
    have hr1 : Real.exp (-x) ≤ 1 := Real.exp_le_one_iff.2 (by linarith)
    have hx2 : x ^ 2 ≤ x ^ 3 := by nlinarith
    have hx3 : 1 ≤ x ^ 3 := one_le_pow₀ h1.le
    rw [abs_le]; constructor <;> nlinarith

/-- Helper: `|q^n - r^n| ≤ n |q - r| M^n` when `0 ≤ q, r ≤ M` and `1 ≤ M`. -/
lemma mvh_pow_sub (q r M : ℝ) (hq : 0 ≤ q) (hr : 0 ≤ r) (hqM : q ≤ M) (hrM : r ≤ M)
    (hM : 1 ≤ M) (n : ℕ) : |q ^ n - r ^ n| ≤ n * |q - r| * M ^ n := by
  induction n with
  | zero => simp
  | succ n ih =>
    have hrn : r ^ n ≤ M ^ n := pow_le_pow_left₀ hr hrM n
    have hMn : M ^ n ≤ M ^ (n + 1) := pow_le_pow_right₀ hM (Nat.le_succ n)
    have hd : 0 ≤ |q - r| := abs_nonneg _
    have hpn : 0 ≤ |q ^ n - r ^ n| := abs_nonneg _
    calc |q ^ (n + 1) - r ^ (n + 1)| = |q * (q ^ n - r ^ n) + r ^ n * (q - r)| := by ring_nf
      _ ≤ |q * (q ^ n - r ^ n)| + |r ^ n * (q - r)| := abs_add_le _ _
      _ = q * |q ^ n - r ^ n| + r ^ n * |q - r| := by
        rw [abs_mul, abs_mul, abs_of_nonneg hq, abs_of_nonneg (pow_nonneg hr n)]
      _ ≤ M * (n * |q - r| * M ^ n) + M ^ (n + 1) * |q - r| := by
        gcongr
        exact hrn.trans hMn
      _ = (↑(n + 1)) * |q - r| * M ^ (n + 1) := by push_cast; ring

/-- Helper: the gap identity for both steps (same statement as Step 4 below). -/
lemma mvh_gap (a k h t v : ℝ) (hk : k ≠ 0) :
    heunStep (fun _ u => a - k * u) h t v - a / k
        = (1 - k * h + (k * h) ^ 2 / 2) * (v - a / k) ∧
      midpointStep (fun _ u => a - k * u) h t v - a / k
        = (1 - k * h + (k * h) ^ 2 / 2) * (v - a / k) := by
  unfold heunStep midpointStep
  constructor <;> field_simp <;> ring

/-- Helper: running a step that multiplies the gap by `q` multiplies it by `q^n`. -/
lemma mvh_run (step : ℝ → ℝ → ℝ) (b q h v₀ : ℝ) (hs : ∀ t v, step t v - b = q * (v - b))
    (n : ℕ) : stepRun step h v₀ n - b = q ^ n * (v₀ - b) := by
  induction n with
  | zero => simp [stepRun]
  | succ n ih =>
    rw [stepRun, hs, ih]; ring

/-- The card's main claim, for a rule that is a straight line in speed, `v' = a - k v` with drag
`k > 0` (the skydiver has `a = 9.8`, `k = 0.2`). The exact speed is
`a/k + (v₀ - a/k) e^(-k t)`. Fix the end time `T > 0` and reach it in `N` equal steps of length
`h = T/N`. Then there is one constant `C`, the same for every `N`, such that Heun's answer and the
midpoint answer at `T` are both within `C h²` of the exact speed: the error at a fixed time falls
with the square of the step, so halving the step quarters it. -/
theorem heun_and_midpoint_error_falls_with_step_squared (a k v₀ T : ℝ) (hk : 0 < k)
    (hT : 0 < T) :
    ∃ C : ℝ, ∀ N : ℕ, 0 < N →
      |stepRun (heunStep (fun _ v => a - k * v) (T / N)) (T / N) v₀ N
          - (a / k + (v₀ - a / k) * Real.exp (-k * T))| ≤ C * (T / N) ^ 2 ∧
      |stepRun (midpointStep (fun _ v => a - k * v) (T / N)) (T / N) v₀ N
          - (a / k + (v₀ - a / k) * Real.exp (-k * T))| ≤ C * (T / N) ^ 2 := by
  refine ⟨|v₀ - a / k| * (3 * k ^ 3 * T * Real.exp (k ^ 2 * T ^ 2 / 2)), fun N hN => ?_⟩
  have hNr : (0 : ℝ) < N := by exact_mod_cast hN
  have hN1 : (1 : ℝ) ≤ N := by exact_mod_cast hN
  set h := T / N with hh
  have hh0 : 0 ≤ h := div_nonneg hT.le hNr.le
  set x := k * h with hx
  have hx0 : 0 ≤ x := mul_nonneg hk.le hh0
  set q := 1 - x + x ^ 2 / 2 with hq
  have hexp : Real.exp (-k * T) = Real.exp (-x) ^ N := by
    rw [← Real.exp_nat_mul]; congr 1; rw [hx, hh]; field_simp
  have hbound : |v₀ - a / k| * |q ^ N - Real.exp (-x) ^ N|
      ≤ |v₀ - a / k| * (3 * k ^ 3 * T * Real.exp (k ^ 2 * T ^ 2 / 2)) * h ^ 2 := by
    have hq0 : 0 ≤ q := by nlinarith [sq_nonneg (1 - x)]
    set M := Real.exp (x ^ 2 / 2) with hM
    have hM1 : 1 ≤ M := Real.one_le_exp (by positivity)
    have hqM : q ≤ M := by
      have := Real.add_one_le_exp (x ^ 2 / 2)
      rw [hq]; nlinarith
    have hrM : Real.exp (-x) ≤ M := (Real.exp_le_one_iff.2 (by linarith)).trans hM1
    have hp := mvh_pow_sub q (Real.exp (-x)) M hq0 (Real.exp_pos _).le hqM hrM hM1 N
    have hc := mvh_q_close x hx0
    have hMN : M ^ N ≤ Real.exp (k ^ 2 * T ^ 2 / 2) := by
      rw [hM, ← Real.exp_nat_mul]
      apply Real.exp_le_exp.2
      have : (N : ℝ) * (x ^ 2 / 2) = k ^ 2 * T ^ 2 / 2 / N := by
        rw [hx, hh]; field_simp
      rw [this]
      exact div_le_self (by positivity) hN1
    have hNx : (N : ℝ) * x ^ 3 = k ^ 3 * T * h ^ 2 := by
      rw [hx, hh]; field_simp
    have hM0 : 0 ≤ M ^ N := by positivity
    calc |v₀ - a / k| * |q ^ N - Real.exp (-x) ^ N|
        ≤ |v₀ - a / k| * (N * (3 * x ^ 3) * Real.exp (k ^ 2 * T ^ 2 / 2)) := by
          gcongr
          calc _ ≤ N * |q - Real.exp (-x)| * M ^ N := hp
            _ ≤ _ := by gcongr
      _ = _ := by
        rw [show (N : ℝ) * (3 * x ^ 3) = 3 * (N * x ^ 3) by ring, hNx]; ring
  have hrun : ∀ step : ℝ → ℝ → ℝ, (∀ t v, step t v - a / k = q * (v - a / k)) →
      |stepRun step h v₀ N - (a / k + (v₀ - a / k) * Real.exp (-k * T))|
        ≤ |v₀ - a / k| * (3 * k ^ 3 * T * Real.exp (k ^ 2 * T ^ 2 / 2)) * h ^ 2 := by
    intro step hs
    have hr := mvh_run step (a / k) q h v₀ hs N
    rw [show stepRun step h v₀ N - (a / k + (v₀ - a / k) * Real.exp (-k * T))
        = (v₀ - a / k) * (q ^ N - Real.exp (-x) ^ N) by rw [hexp]; linear_combination hr,
      abs_mul]
    exact hbound
  exact ⟨hrun _ (fun t v => (mvh_gap a k h t v hk.ne').1),
    hrun _ (fun t v => (mvh_gap a k h t v hk.ne').2)⟩

/-- Step 4 of the card: for a rule that is a straight line in speed, `v' = a - k v` with `k ≠ 0`,
one Heun step and one midpoint step both multiply the gap to the balance speed `a/k` by
`q = 1 - x + x²/2`, where `x = k h`: the first three terms of the series for `e^(-x)`. -/
theorem heun_and_midpoint_multiply_gap_by_q (a k h t v : ℝ) (hk : k ≠ 0) :
    heunStep (fun _ u => a - k * u) h t v - a / k
        = (1 - k * h + (k * h) ^ 2 / 2) * (v - a / k) ∧
      midpointStep (fun _ u => a - k * u) h t v - a / k
        = (1 - k * h + (k * h) ^ 2 / 2) * (v - a / k) := by
  exact mvh_gap a k h t v hk

/-- Step 3 of the card: the local error. Take a smooth rule `f` (twice continuously
differentiable in time and speed together) and a true solution `y` of `y' = f t y` near the time
`t`. If the weights and the reading place satisfy `b₁ + b₂ = 1` and `b₂ c = 1/2` (midpoint:
`0, 1, 1/2`; Heun: `1/2, 1/2, 1`), then one two-sample step from the true speed `y t` misses the
true speed `y (t + h)` by at most a constant times `h³` as the step `h` shrinks. -/
theorem two_sample_step_local_error_cubic (f : ℝ → ℝ → ℝ)
    (hf : ContDiff ℝ 2 (Function.uncurry f)) (y : ℝ → ℝ) (t : ℝ)
    (hy : ∀ᶠ s in 𝓝 t, HasDerivAt y (f s (y s)) s) (b₁ b₂ c : ℝ)
    (hb : b₁ + b₂ = 1) (hc : b₂ * c = 1 / 2) :
    (fun h => y (t + h) - twoSampleStep b₁ b₂ c f h t (y t)) =O[𝓝 0] (fun h => h ^ 3) := by
  set F := Function.uncurry f with hFdef
  set P0 : ℝ × ℝ := (t, y t) with hP0
  set k₁ := f t (y t) with hk₁
  set D := fderiv ℝ F P0 with hD
  set v : ℝ × ℝ := (1, k₁) with hv
  set R : ℝ × ℝ → ℝ := fun Δ => F (P0 + Δ) - F P0 - D Δ with hR
  have hRO : R =O[𝓝 0] (fun Δ => ‖Δ‖ ^ 2) := mvh_taylor2 hf P0
  have hFP0 : F P0 = k₁ := rfl
  have ht : Tendsto (fun s : ℝ => t + s) (𝓝 0) (𝓝 t) := by
    simpa using (tendsto_const_nhds (x := t)).add (tendsto_id (x := 𝓝 (0:ℝ)))
  have hyd : ∀ᶠ s in 𝓝 (0:ℝ), HasDerivAt (fun s => y (t + s)) (f (t + s) (y (t + s))) s := by
    filter_upwards [ht.eventually hy] with s hs
    exact HasDerivAt.comp_const_add t s hs
  set Δ : ℝ → ℝ × ℝ := fun s => (s, y (t + s) - y t) with hΔ
  have hyO : (fun s => y (t + s) - y t) =O[𝓝 0] (fun s : ℝ => s) := by
    have h1 := (hy.self_of_nhds).isBigO_sub.comp_tendsto ht
    simpa [Function.comp_def] using h1
  have hΔO : Δ =O[𝓝 0] (fun s : ℝ => s) := (isBigO_refl _ _).prod_left hyO
  have hΔt : Tendsto Δ (𝓝 0) (𝓝 0) := hΔO.trans_tendsto tendsto_id
  have hFΔ : ∀ s, F (P0 + Δ s) = f (t + s) (y (t + s)) := by
    intro s; simp [P0, Δ, F]
  have hRΔ : (fun s => R (Δ s)) =O[𝓝 0] (fun s : ℝ => s ^ 2) :=
    (hRO.comp_tendsto hΔt).trans (hΔO.norm_left.pow 2)
  -- first order: e(s) = y(t+s) - y t - s k₁ is O(s²)
  have hF1 : (fun s => f (t + s) (y (t + s)) - k₁) =O[𝓝 0] (fun s : ℝ => s) := by
    have hFd : HasFDerivAt F D P0 :=
      ((hf.differentiable (by norm_num)) P0).hasFDerivAt
    have htP : Tendsto (fun s => P0 + Δ s) (𝓝 0) (𝓝 P0) := by
      simpa using (tendsto_const_nhds (x := P0)).add hΔt
    have h2 := hFd.isBigO_sub.comp_tendsto htP
    refine (h2.trans ?_).congr (fun s => ?_) (fun s => rfl)
    · exact hΔO.congr (fun s => by simp) (fun s => rfl)
    · simp only [Function.comp_def]; rw [hFΔ, hFP0]
  have heO : (fun s => y (t + s) - y t - s * k₁) =O[𝓝 0] (fun s : ℝ => s ^ 2) := by
    refine mvh_isBigO_of_deriv (n := 1) (φ' := fun s => f (t + s) (y (t + s)) - k₁)
      (by simp) ?_ (by simpa using hF1)
    filter_upwards [hyd] with s hs
    exact (hs.sub_const (y t)).sub (hasDerivAt_mul_const k₁)
  -- second order
  have hD2 : ∀ s, D (Δ s) = s * D v + (y (t + s) - y t - s * k₁) * D (0, 1) := by
    intro s
    have : Δ s = s • v + (y (t + s) - y t - s * k₁) • ((0 : ℝ), (1 : ℝ)) := by
      simp only [Δ, v, Prod.smul_mk, smul_eq_mul, Prod.mk_add_mk]
      ext <;> simp <;> ring
    rw [this, map_add, map_smul, map_smul, smul_eq_mul, smul_eq_mul]
  have hψ' : (fun s => f (t + s) (y (t + s)) - k₁ - s * D v) =O[𝓝 0] (fun s : ℝ => s ^ 2) := by
    refine ((heO.const_mul_left (D (0, 1))).add hRΔ).congr (fun s => ?_) (fun s => rfl)
    simp only [R]
    rw [hFΔ, hD2 s, hFP0]
    ring
  have hψ : (fun s => y (t + s) - y t - s * k₁ - s ^ 2 / 2 * D v) =O[𝓝 0]
      (fun s : ℝ => s ^ 3) := by
    refine mvh_isBigO_of_deriv (n := 2) (φ' := fun s => f (t + s) (y (t + s)) - k₁ - s * D v)
      (by simp) ?_ hψ'
    filter_upwards [hyd] with s hs
    have := ((hs.sub_const (y t)).sub (hasDerivAt_mul_const k₁)).sub
      (((hasDerivAt_pow 2 s).div_const 2).mul_const (D v))
    convert this using 1
    simp
  -- the step's own error term
  have hcv : (fun h : ℝ => (c * h) • v) =O[𝓝 0] (fun h : ℝ => h) := by
    refine isBigO_of_le' (c := |c| * ‖v‖) _ (fun h => ?_)
    rw [norm_smul, Real.norm_eq_abs, Real.norm_eq_abs, abs_mul]
    ring_nf; rfl
  have hR2 : (fun h : ℝ => R ((c * h) • v)) =O[𝓝 0] (fun h : ℝ => h ^ 2) :=
    (hRO.comp_tendsto (hcv.trans_tendsto tendsto_id)).trans (hcv.norm_left.pow 2)
  have hR3 : (fun h : ℝ => h * b₂ * R ((c * h) • v)) =O[𝓝 0] (fun h : ℝ => h ^ 3) :=
    (((isBigO_refl (fun h : ℝ => h) _).mul hR2).const_mul_left b₂).congr
      (fun h => by ring) (fun h => by ring)
  refine (hψ.sub hR3).congr (fun h => ?_) (fun h => rfl)
  have hstep : f (t + c * h) (y t + c * h * k₁) = k₁ + c * h * D v + R ((c * h) • v) := by
    have e1 : P0 + (c * h) • v = (t + c * h, y t + c * h * k₁) := by
      simp [P0, v, Prod.smul_mk, smul_eq_mul]
    simp only [R, e1, map_smul, smul_eq_mul]
    simp [F, P0, k₁]
  simp only [twoSampleStep]
  rw [← hk₁, hstep]
  linear_combination (h * k₁) * hb + (h ^ 2 * D v) * hc

/-! The card's worked numbers, in exact fractions: the skydiver `v' = 9.8 - 0.2 v`, `v(0) = 0`,
with 2 s steps. -/

-- Heun's first step: k₁ = 9.80, k₂ = 9.8 - 0.2 × 19.60 = 5.88, and 2 × (9.80 + 5.88)/2 = 15.68.
example : (49 / 5 : ℚ) - 1 / 5 * (2 * (49 / 5)) = 147 / 25 ∧
    (2 : ℚ) * ((49 / 5 + 147 / 25) / 2) = 392 / 25 := by norm_num

-- The midpoint's first step: slope 9.8 - 0.2 × 9.80 = 7.84 at the half step, and 2 × 7.84 = 15.68.
example : (49 / 5 : ℚ) - 1 / 5 * (49 / 5) = 196 / 25 ∧ (2 : ℚ) * (196 / 25) = 392 / 25 := by
  norm_num

-- One Heun step and one midpoint step, run on the rule itself, both land at 15.68.
example : heunStep (fun _ v => 49 / 5 - 1 / 5 * v) 2 0 0 = 392 / 25 ∧
    midpointStep (fun _ v => 49 / 5 - 1 / 5 * v) 2 0 0 = 392 / 25 := by
  constructor <;> norm_num [heunStep, midpointStep]

-- At h = 2 s, x = 0.4 and q = 1 - 0.4 + 0.08 = 0.68.
example : (1 : ℚ) - 2 / 5 + (2 / 5) ^ 2 / 2 = 17 / 25 := by norm_num

-- Five Heun steps of 2 s land exactly on 49 (1 - q⁵), which is 41.8757 to four places.
example : stepRun (heunStep (fun _ v => 49 / 5 - 1 / 5 * v) 2) 2 0 5
    = 49 * (1 - (17 / 25) ^ 5) := by
  norm_num [stepRun, heunStep]

example : (418757 / 10000 : ℚ) ≤ 49 * (1 - (17 / 25) ^ 5) ∧
    49 * (1 - (17 / 25) ^ 5) < (418758 / 10000 : ℚ) := by norm_num

-- Past h = 10 s the step stops shrinking the gap: at x = 2, q = 1 - 2 + 2 = 1.
example : (1 : ℚ) - 2 + 2 ^ 2 / 2 = 1 := by norm_num

-- Midpoint (b₁, b₂, c) = (0, 1, 1/2) and Heun (1/2, 1/2, 1) both meet b₁ + b₂ = 1, b₂ c = 1/2.
example : (0 : ℚ) + 1 = 1 ∧ (1 : ℚ) * (1 / 2) = 1 / 2 ∧
    (1 / 2 : ℚ) + 1 / 2 = 1 ∧ (1 / 2 : ℚ) * 1 = 1 / 2 := by norm_num

-- Midpoint and Heun are the family's members with those weights.
example (f : ℝ → ℝ → ℝ) (h t v : ℝ) :
    midpointStep f h t v = twoSampleStep 0 1 (1 / 2) f h t v ∧
      heunStep f h t v = twoSampleStep (1 / 2) (1 / 2) 1 f h t v := by
  unfold midpointStep heunStep twoSampleStep
  constructor
  · rw [show t + 1 / 2 * h = t + h / 2 by ring, show v + 1 / 2 * h * f t v = v + h / 2 * f t v by ring]
    ring
  · simp only [one_mul]; ring

#print axioms mvh_isBigO_of_deriv
#print axioms mvh_taylor2
#print axioms mvh_q_close
#print axioms mvh_pow_sub
#print axioms mvh_gap
#print axioms mvh_run
#print axioms heun_and_midpoint_error_falls_with_step_squared
#print axioms heun_and_midpoint_multiply_gap_by_q
#print axioms two_sample_step_local_error_cubic
