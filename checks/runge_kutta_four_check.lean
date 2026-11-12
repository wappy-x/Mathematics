-- Runge-Kutta four: on a law whose gap from a resting value decays, one RK4 step over the real numbers multiplies the gap by e^z cut after z^4, and inside the stability edge the error at time n h is at most a constant times h^4, while the weights pass all eight order conditions.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Pow

open Finset

noncomputable section

/-- One RK4 step for the law `y' = f t y`, from time `t` and value `y`, with step `h`:
four slopes, one at the start, two at the middle, one at the end, weighted 1, 2, 2, 1 over 6. -/
def rk4Step (f : ℝ → ℝ → ℝ) (t h y : ℝ) : ℝ :=
  let k1 := f t y
  let k2 := f (t + h / 2) (y + h / 2 * k1)
  let k3 := f (t + h / 2) (y + h / 2 * k2)
  let k4 := f (t + h) (y + h * k3)
  y + h / 6 * (k1 + 2 * k2 + 2 * k3 + k4)

/-- `n` RK4 steps of size `h`, starting at time 0 from the value `y0`. -/
def rk4Iter (f : ℝ → ℝ → ℝ) (h : ℝ) : ℕ → ℝ → ℝ
  | 0, y0 => y0
  | n + 1, y0 => rk4Step f (n * h) h (rk4Iter f h n y0)

/-- The gap factor of one step: `e^z` cut after the fourth power. -/
def rk4Factor (z : ℝ) : ℝ :=
  1 + z + z ^ 2 / 2 + z ^ 3 / 6 + z ^ 4 / 24

theorem rk4_nonneg_of_hasDerivAt (f f' : ℝ → ℝ) (hf : ∀ x, HasDerivAt f (f' x) x)
    (h0 : f 0 = 0) (hd : ∀ x, 0 ≤ x → 0 ≤ f' x) : ∀ x, 0 ≤ x → 0 ≤ f x := by
  intro x hx
  have hmono : MonotoneOn f (Set.Ici 0) := by
    apply monotoneOn_of_deriv_nonneg (convex_Ici 0)
    · exact (fun t => (hf t).continuousAt) |> continuous_iff_continuousAt.mpr |>.continuousOn
    · exact fun t _ => (hf t).differentiableAt.differentiableWithinAt
    · intro t ht
      rw [interior_Ici] at ht
      rw [(hf t).deriv]
      exact hd t (le_of_lt ht)
  have := hmono (Set.mem_Ici.mpr le_rfl) (Set.mem_Ici.mpr hx) hx
  linarith

theorem rk4_exp_neg_bounds (x : ℝ) (hx : 0 ≤ x) :
    0 ≤ (1 - x + x^2/2 - x^3/6 + x^4/24) - Real.exp (-x) ∧
    (1 - x + x^2/2 - x^3/6 + x^4/24) - Real.exp (-x) ≤ x^5/120 := by
  have hE : ∀ t, HasDerivAt (fun t => Real.exp (-t)) (-Real.exp (-t)) t := by
    intro t
    exact (hasDerivAt_neg t).exp.congr_deriv (by ring)
  have hP : ∀ (c : ℝ) (k : ℕ) t, HasDerivAt (fun t : ℝ => t ^ (k+1) / c) ((k+1) * t ^ k / c) t := by
    intro c k t
    exact ((hasDerivAt_pow (k+1) t).div_const c).congr_deriv (by push_cast; simp)
  have p1 : ∀ x, 0 ≤ x → 0 ≤ Real.exp (-x) - 1 + x := by
    intro x _; linarith [Real.add_one_le_exp (-x)]
  have p2 : ∀ x, 0 ≤ x → 0 ≤ 1 - x + x^2/2 - Real.exp (-x) := by
    apply rk4_nonneg_of_hasDerivAt _ (fun t => Real.exp (-t) - 1 + t)
    · intro t
      have := (((hasDerivAt_const t (1:ℝ)).sub (hasDerivAt_id t)).add (hP 2 1 t)).sub (hE t)
      exact this.congr_deriv (by push_cast; ring)
    · simp
    · exact p1
  have p3 : ∀ x, 0 ≤ x → 0 ≤ Real.exp (-x) - (1 - x + x^2/2 - x^3/6) := by
    apply rk4_nonneg_of_hasDerivAt _ (fun t => 1 - t + t^2/2 - Real.exp (-t))
    · intro t
      have := (hE t).sub ((((hasDerivAt_const t (1:ℝ)).sub (hasDerivAt_id t)).add (hP 2 1 t)).sub (hP 6 2 t))
      exact this.congr_deriv (by push_cast; ring)
    · simp
    · exact p2
  have p4 : ∀ x, 0 ≤ x → 0 ≤ (1 - x + x^2/2 - x^3/6 + x^4/24) - Real.exp (-x) := by
    apply rk4_nonneg_of_hasDerivAt _ (fun t => Real.exp (-t) - (1 - t + t^2/2 - t^3/6))
    · intro t
      have := (((((hasDerivAt_const t (1:ℝ)).sub (hasDerivAt_id t)).add (hP 2 1 t)).sub (hP 6 2 t)).add (hP 24 3 t)).sub (hE t)
      exact this.congr_deriv (by push_cast; ring)
    · simp
    · exact p3
  have p5 : ∀ x, 0 ≤ x → 0 ≤ Real.exp (-x) - (1 - x + x^2/2 - x^3/6 + x^4/24 - x^5/120) := by
    apply rk4_nonneg_of_hasDerivAt _ (fun t => (1 - t + t^2/2 - t^3/6 + t^4/24) - Real.exp (-t))
    · intro t
      have := (hE t).sub (((((((hasDerivAt_const t (1:ℝ)).sub (hasDerivAt_id t)).add (hP 2 1 t)).sub (hP 6 2 t)).add (hP 24 3 t)).sub (hP 120 4 t)))
      exact this.congr_deriv (by push_cast; ring)
    · simp
    · exact p4
  constructor
  · exact p4 x hx
  · linarith [p5 x hx]

theorem rk4_pow_sub_pow_le (a b : ℝ) (ha : |a| ≤ 1) (hb : |b| ≤ 1) (n : ℕ) :
    |a ^ n - b ^ n| ≤ n * |a - b| := by
  induction n with
  | zero => simp
  | succ k ih =>
    have h1 : a ^ (k+1) - b ^ (k+1) = a * (a ^ k - b ^ k) + b ^ k * (a - b) := by ring
    have hbk : |b ^ k| ≤ 1 := by rw [abs_pow]; exact pow_le_one₀ (abs_nonneg _) hb
    rw [h1]
    calc |a * (a ^ k - b ^ k) + b ^ k * (a - b)|
        ≤ |a * (a ^ k - b ^ k)| + |b ^ k * (a - b)| := abs_add_le _ _
      _ = |a| * |a ^ k - b ^ k| + |b ^ k| * |a - b| := by rw [abs_mul, abs_mul]
      _ ≤ 1 * |a ^ k - b ^ k| + 1 * |a - b| := by
          gcongr
      _ ≤ k * |a - b| + |a - b| := by linarith
      _ = ((k + 1 : ℕ) : ℝ) * |a - b| := by push_cast; ring

theorem rk4_linear_solution (rate e : ℝ) (y : ℝ → ℝ)
    (hode : ∀ t, HasDerivAt y (rate * (y t - e)) t) (t : ℝ) :
    y t - e = (y 0 - e) * Real.exp (rate * t) := by
  let g : ℝ → ℝ := fun s => (y s - e) * Real.exp (-(rate * s))
  have hg : ∀ s, HasDerivAt g 0 s := by
    intro s
    have h1 : HasDerivAt (fun s => y s - e) (rate * (y s - e)) s := (hode s).sub_const e
    have h2 : HasDerivAt (fun s => Real.exp (-(rate * s))) (Real.exp (-(rate * s)) * (-(rate * 1))) s :=
      (((hasDerivAt_id s).const_mul rate).neg).exp
    exact (h1.mul h2).congr_deriv (by ring)
  have hconst : g t = g 0 :=
    is_const_of_deriv_eq_zero (fun s => (hg s).differentiableAt) (fun s => (hg s).deriv) t 0
  simp only [g, mul_zero, neg_zero, Real.exp_zero, mul_one] at hconst
  have hpos : Real.exp (rate * t) * Real.exp (-(rate * t)) = 1 := by
    rw [← Real.exp_add]; simp
  calc y t - e = (y t - e) * (Real.exp (-(rate * t)) * Real.exp (rate * t)) := by
          rw [mul_comm (Real.exp _), hpos, mul_one]
    _ = (y t - e) * Real.exp (-(rate * t)) * Real.exp (rate * t) := by ring
    _ = (y 0 - e) * Real.exp (rate * t) := by rw [hconst]

theorem rk4_step_gap_helper (rate e t h v : ℝ) :
    rk4Step (fun _ w => rate * (w - e)) t h v - e = rk4Factor (h * rate) * (v - e) := by
  simp only [rk4Step, rk4Factor]
  ring

/-- Fourth-order accuracy on a decaying law. Take the law `y' = rate * (y - e)`: the gap from
the resting value `e` decays at rate `rate < 0` (the skydiver: `rate = -0.2`, `e = 49`). Let `y`
be its true solution from `y 0 = y0`, and let the step `h > 0` be inside the stability edge,
`|R(h * rate)| ≤ 1`. Then after `n` RK4 steps the error at time `n h` is at most
`|y0 - e| * |rate|^5 / 120 * (n h) * h^4`: a constant times `h^4` for a fixed end time,
so halving the step divides the bound by 16. -/
theorem rk4_global_error_le_const_mul_h_pow_four
    (rate e y0 h : ℝ) (y : ℝ → ℝ) (n : ℕ)
    (hrate : rate < 0) (hh : 0 < h)
    (hode : ∀ t, HasDerivAt y (rate * (y t - e)) t) (hy0 : y 0 = y0)
    (hstab : |rk4Factor (h * rate)| ≤ 1) :
    |rk4Iter (fun _ v => rate * (v - e)) h n y0 - y (n * h)|
      ≤ |y0 - e| * |rate| ^ 5 / 120 * (n * h) * h ^ 4 := by
  set z := h * rate with hzdef
  have hz : z ≤ 0 := by rw [hzdef]; nlinarith
  have habsz : |z| = h * |rate| := by rw [hzdef, abs_mul, abs_of_pos hh]
  -- gap of the iterates
  have hit : ∀ m : ℕ, rk4Iter (fun _ v => rate * (v - e)) h m y0 - e
      = rk4Factor z ^ m * (y0 - e) := by
    intro m
    induction m with
    | zero => simp [rk4Iter]
    | succ k ih =>
      simp only [rk4Iter]
      rw [rk4_step_gap_helper, ih]
      ring
  -- the true solution
  have hsol : y (n * h) - e = Real.exp z ^ n * (y0 - e) := by
    rw [rk4_linear_solution rate e y hode, hy0, ← Real.exp_nat_mul, hzdef]
    ring_nf
  -- one-step error
  obtain ⟨hlo, hhi⟩ := rk4_exp_neg_bounds (-z) (by linarith)
  rw [neg_neg] at hlo hhi
  have hR : rk4Factor z = 1 - -z + (-z) ^ 2 / 2 - (-z) ^ 3 / 6 + (-z) ^ 4 / 24 := by
    simp only [rk4Factor]; ring
  have hone : |rk4Factor z - Real.exp z| ≤ |z| ^ 5 / 120 := by
    rw [abs_of_nonpos hz, hR, abs_of_nonneg hlo]
    exact hhi
  have hE : |Real.exp z| ≤ 1 := by
    rw [abs_of_pos (Real.exp_pos z)]; exact Real.exp_le_one_iff.mpr hz
  have hpow := rk4_pow_sub_pow_le (rk4Factor z) (Real.exp z) hstab hE n
  have hdiff : rk4Iter (fun _ v => rate * (v - e)) h n y0 - y (n * h)
      = (rk4Factor z ^ n - Real.exp z ^ n) * (y0 - e) := by
    have a := hit n
    linear_combination a - hsol
  rw [hdiff, abs_mul]
  have hn : (0 : ℝ) ≤ n := Nat.cast_nonneg n
  calc |rk4Factor z ^ n - Real.exp z ^ n| * |y0 - e|
      ≤ (n * (|z| ^ 5 / 120)) * |y0 - e| := by
        gcongr
        exact hpow.trans (mul_le_mul_of_nonneg_left hone hn)
    _ = |y0 - e| * |rate| ^ 5 / 120 * (n * h) * h ^ 4 := by
        rw [habsz]; ring

/-- One RK4 step on the law `y' = rate * (y - e)` multiplies the gap from `e` by
`R(z) = 1 + z + z^2/2 + z^3/6 + z^4/24`, with `z = h * rate`. -/
theorem rk4_step_multiplies_gap_by_factor
    (rate e t h v : ℝ) :
    rk4Step (fun _ w => rate * (w - e)) t h v - e = rk4Factor (h * rate) * (v - e) := by
  simp only [rk4Step, rk4Factor]
  ring

/-- The weights `b = (1/6, 1/3, 1/3, 1/6)`. -/
def rk4b : Fin 4 → ℝ := ![1 / 6, 1 / 3, 1 / 3, 1 / 6]

/-- Where each slope is read, as a fraction of the step: `c = (0, 1/2, 1/2, 1)`. -/
def rk4c : Fin 4 → ℝ := ![0, 1 / 2, 1 / 2, 1]

/-- The links: stage 2 uses 1/2 of k1, stage 3 uses 1/2 of k2, stage 4 all of k3. -/
def rk4A : Fin 4 → Fin 4 → ℝ :=
  ![![0, 0, 0, 0], ![1 / 2, 0, 0, 0], ![0, 1 / 2, 0, 0], ![0, 0, 1, 0]]

/-- The eight order conditions through `h^4`: the sums of b, bc, bc^2, b(Ac), bc^3, bc(Ac),
b(Ac^2) and b(AAc) are 1, 1/2, 1/3, 1/6, 1/4, 1/8, 1/12 and 1/24. -/
theorem rk4_satisfies_eight_order_conditions :
    ∑ i, rk4b i = 1 ∧
    ∑ i, rk4b i * rk4c i = 1 / 2 ∧
    ∑ i, rk4b i * rk4c i ^ 2 = 1 / 3 ∧
    ∑ i, rk4b i * (∑ j, rk4A i j * rk4c j) = 1 / 6 ∧
    ∑ i, rk4b i * rk4c i ^ 3 = 1 / 4 ∧
    ∑ i, rk4b i * rk4c i * (∑ j, rk4A i j * rk4c j) = 1 / 8 ∧
    ∑ i, rk4b i * (∑ j, rk4A i j * rk4c j ^ 2) = 1 / 12 ∧
    ∑ i, rk4b i * (∑ j, rk4A i j * ∑ k, rk4A j k * rk4c k) = 1 / 24 := by
  simp [Fin.sum_univ_four, rk4b, rk4c, rk4A]
  norm_num

-- The skydiver, v' = 9.8 - 0.2 v from v = 0 with h = 2 s: k1 = 9.8, k2 = 7.84, k3 = 8.232, k4 = 6.5072.
example : (49 / 5 - 0 / 5 : ℝ) = 49 / 5 ∧
    (49 / 5 - (0 + 1 * (49 / 5)) / 5 : ℝ) = 196 / 25 ∧
    (49 / 5 - (0 + 1 * (196 / 25)) / 5 : ℝ) = 1029 / 125 ∧
    (49 / 5 - (0 + 2 * (1029 / 125)) / 5 : ℝ) = 4067 / 625 := by norm_num

-- The weighted slope is 8.0752 and the step lands at 16.1504 m/s.
example : ((49 / 5 + 2 * (196 / 25) + 2 * (1029 / 125) + 4067 / 625) / 6 : ℝ) = 5047 / 625 ∧
    rk4Step (fun _ v : ℝ => 49 / 5 - v / 5) 0 2 0 = 10094 / 625 := by
  norm_num [rk4Step]

-- The weights 1, 2, 2, 1 over 6 add to 1, and halving the step divides h^4 by 2^4 = 16.
example : ((1 + 2 + 2 + 1) / 6 : ℝ) = 1 ∧ 2 ^ 4 = 16 := by norm_num

end

#print axioms rk4_global_error_le_const_mul_h_pow_four
#print axioms rk4_step_multiplies_gap_by_factor
#print axioms rk4_satisfies_eight_order_conditions
#print axioms rk4_nonneg_of_hasDerivAt
#print axioms rk4_exp_neg_bounds
#print axioms rk4_pow_sub_pow_le
#print axioms rk4_linear_solution
#print axioms rk4_step_gap_helper
