-- Momentum and Adam: with Polyak's tuning every curvature between μ and L shrinks at the one rate (√κ - 1)/(√κ + 1), Nesterov's tuning gives a double root 1 - 1/√κ along the floor, and Adam's path in one variable does not change when that variable's slopes are scaled.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Complex.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

/-! ### How the card's objects are written here

On a quadratic bowl each main direction runs its own one-number walk. Along a direction of
curvature `lam`, with step `α` and momentum fraction `β`, put `s = α * lam`.

* Heavy ball: `e (k+1) = (1 + β - s) e k - β e (k-1)`. Trying `e k = r ^ k` gives the
  characteristic equation `r ^ 2 - (1 + β - s) r + β = 0`. Its roots, complex in general, are the
  shrink factors per step along that direction.
* Nesterov: `e (k+1) = (1 + β)(1 - s) e k - β (1 - s) e (k-1)`, with characteristic polynomial
  `r ^ 2 - (1 + β)(1 - s) r + β (1 - s)`.

The gentlest and steepest curvatures are `μ` and `L`, and `κ = L / μ` is the stretch ratio. -/

/-- Polyak's tuned step size, `α = 4 / (√L + √μ) ^ 2`. -/
noncomputable def polyakStep (μ L : ℝ) : ℝ := 4 / (Real.sqrt L + Real.sqrt μ) ^ 2

/-- Polyak's tuned momentum fraction, `β = ((√κ - 1) / (√κ + 1)) ^ 2` with `κ = L / μ`. -/
noncomputable def polyakMomentum (μ L : ℝ) : ℝ :=
  ((Real.sqrt (L / μ) - 1) / (Real.sqrt (L / μ) + 1)) ^ 2

/-- Nesterov's tuned momentum fraction, `β = (√κ - 1) / (√κ + 1)` with `κ = L / μ`
(his step size is `α = 1 / L`). -/
noncomputable def nesterovMomentum (μ L : ℝ) : ℝ :=
  (Real.sqrt (L / μ) - 1) / (Real.sqrt (L / μ) + 1)

/-- Helper: a root `x + i y` of `z ^ 2 - t z + B` with real `t`, `B` and `t ^ 2 ≤ 4 B` has
`x ^ 2 + y ^ 2 = B`. -/
theorem sum_sq_eq_of_quadratic (x y t B : ℝ) (hdisc : t ^ 2 ≤ 4 * B)
    (hre : x ^ 2 - y ^ 2 - t * x + B = 0) (him : 2 * x * y - t * y = 0) :
    x ^ 2 + y ^ 2 = B := by
  have h : y * (2 * x - t) = 0 := by linear_combination him
  rcases mul_eq_zero.mp h with hy | hx
  · subst hy
    have h2 : (2 * x - t) ^ 2 = t ^ 2 - 4 * B := by linear_combination 4 * hre
    have h3 : 2 * x - t = 0 := by
      apply pow_eq_zero_iff (two_ne_zero) |>.mp
      exact le_antisymm (by linarith) (sq_nonneg _)
    have ht : t = 2 * x := by linarith
    subst ht
    linear_combination -hre
  · have ht : t = 2 * x := by linarith
    subst ht
    linear_combination -hre

#print axioms sum_sq_eq_of_quadratic

/-- The card's main theorem for heavy ball (Step 2 and its detailed proof). Take the bowl's
curvatures between `μ > 0` and `L ≥ μ`, and Polyak's settings `α = 4 / (√L + √μ) ^ 2`,
`β = ((√κ - 1) / (√κ + 1)) ^ 2`. Then for every curvature `lam` between `μ` and `L`, every root `r`
(a complex number) of that direction's characteristic equation
`r ^ 2 - (1 + β - α lam) r + β = 0` has the same size, `√β = (√κ - 1) / (√κ + 1)`: every direction
shrinks at that one rate per step, whatever its curvature. -/
theorem heavy_ball_every_curvature_shrinks_at_one_rate (μ L lam : ℝ) (hμ : 0 < μ)
    (hμlam : μ ≤ lam) (hlamL : lam ≤ L) (r : ℂ)
    (hr : r ^ 2 - ((1 + polyakMomentum μ L - polyakStep μ L * lam : ℝ) : ℂ) * r
        + ((polyakMomentum μ L : ℝ) : ℂ) = 0) :
    ‖r‖ = (Real.sqrt (L / μ) - 1) / (Real.sqrt (L / μ) + 1) := by
  set s := Real.sqrt (L / μ) with hs_def
  have hLμ : μ ≤ L := le_trans hμlam hlamL
  have hs1 : 1 ≤ s := by
    rw [hs_def, ← Real.sqrt_one]
    exact Real.sqrt_le_sqrt (by rw [le_div_iff₀ hμ]; linarith)
  have hs2 : s ^ 2 = L / μ := Real.sq_sqrt (div_nonneg (by linarith) hμ.le)
  have hsqL : Real.sqrt L = s * Real.sqrt μ := by
    have : Real.sqrt L = Real.sqrt (L / μ * μ) := by
      congr 1; field_simp
    rw [this, Real.sqrt_mul' _ hμ.le]
  have hsμ : Real.sqrt μ ^ 2 = μ := Real.sq_sqrt hμ.le
  have hsμpos : 0 < Real.sqrt μ := Real.sqrt_pos.mpr hμ
  have hL : L = s ^ 2 * μ := by rw [hs2]; field_simp
  set q := (s - 1) / (s + 1) with hq_def
  have hq0 : 0 ≤ q := div_nonneg (by linarith) (by linarith)
  have hβ : polyakMomentum μ L = q ^ 2 := by
    simp only [polyakMomentum, hs_def, hq_def]
  have hα : polyakStep μ L = 4 / (μ * (s + 1) ^ 2) := by
    simp only [polyakStep]
    rw [hsqL]
    congr 1
    rw [show s * Real.sqrt μ + Real.sqrt μ = (s + 1) * Real.sqrt μ by ring, mul_pow, hsμ]
    ring
  set t : ℝ := 1 + polyakMomentum μ L - polyakStep μ L * lam with ht_def
  have ht : t = (2 * (s ^ 2 + 1) - 4 * (lam / μ)) / (s + 1) ^ 2 := by
    rw [ht_def, hβ, hα, hq_def]
    field_simp
    ring
  have hu1 : 1 ≤ lam / μ := by rw [le_div_iff₀ hμ]; linarith
  have hu2 : lam / μ ≤ s ^ 2 := by rw [div_le_iff₀ hμ, ← hL]; exact hlamL
  have hs1pos : 0 < (s + 1) ^ 2 := by positivity
  have htle : t ≤ 2 * q := by
    rw [ht, hq_def, div_le_iff₀ hs1pos]
    have : 2 * ((s - 1) / (s + 1)) * (s + 1) ^ 2 = 2 * (s - 1) * (s + 1) := by
      field_simp
    rw [this]; nlinarith
  have htge : -(2 * q) ≤ t := by
    rw [ht, hq_def, le_div_iff₀ hs1pos]
    have : -(2 * ((s - 1) / (s + 1))) * (s + 1) ^ 2 = -(2 * (s - 1) * (s + 1)) := by
      field_simp
    rw [this]; nlinarith
  have hdisc : t ^ 2 ≤ 4 * q ^ 2 := by nlinarith
  have hre := congrArg Complex.re hr
  have him := congrArg Complex.im hr
  simp only [sq, Complex.sub_re, Complex.add_re, Complex.mul_re, Complex.ofReal_re,
    Complex.ofReal_im, Complex.zero_re, Complex.sub_im, Complex.add_im, Complex.mul_im,
    Complex.zero_im] at hre him
  rw [hβ] at hre
  have key : r.re ^ 2 + r.im ^ 2 = q ^ 2 :=
    sum_sq_eq_of_quadratic r.re r.im t (q ^ 2) hdisc (by linear_combination hre)
      (by linear_combination him)
  have hn : ‖r‖ ^ 2 = q ^ 2 := by
    rw [← Complex.normSq_eq_norm_sq, Complex.normSq_apply, ← key]; ring
  exact (pow_left_inj₀ (norm_nonneg r) hq0 two_ne_zero).mp hn

/-- Step 3 and its detailed proof: with Nesterov's settings `α = 1 / L` and
`β = (√κ - 1) / (√κ + 1)`, along the floor (curvature `μ`, so `s = α μ = 1 / κ`) the
characteristic polynomial `r ^ 2 - (1 + β)(1 - s) r + β (1 - s)` is exactly `(r - ρ) ^ 2` with
`ρ = 1 - 1 / √κ`: the two roots coincide at the rate `1 - 1 / √κ`. -/
theorem nesterov_double_root_along_floor (μ L : ℝ) (hμ : 0 < μ) (hμL : μ ≤ L) (r : ℝ) :
    r ^ 2 - (1 + nesterovMomentum μ L) * (1 - 1 / L * μ) * r
        + nesterovMomentum μ L * (1 - 1 / L * μ)
      = (r - (1 - 1 / Real.sqrt (L / μ))) ^ 2 := by
  set s := Real.sqrt (L / μ) with hs_def
  have hs1 : 1 ≤ s := by
    rw [hs_def, ← Real.sqrt_one]
    exact Real.sqrt_le_sqrt (by rw [le_div_iff₀ hμ]; linarith)
  have hs2 : s ^ 2 = L / μ := Real.sq_sqrt (div_nonneg (by linarith) hμ.le)
  have hLpos : 0 < L := by linarith
  have hfrac : 1 / L * μ = 1 / s ^ 2 := by
    rw [hs2]; field_simp
  rw [hfrac]
  simp only [nesterovMomentum, ← hs_def]
  have hs0 : s ≠ 0 := by positivity
  have hs1' : s + 1 ≠ 0 := by positivity
  field_simp
  ring

/-! ### Adam in one variable

Adam works on each variable separately. On the bowl the slope of a variable is its curvature
`lam` times its value, `g k = lam * x (k-1)`. The state after step `k` is `(x k, m k, v k)`,
starting from `(x₀, 0, 0)`, and step `k = 1, 2, …` is
`m k = β₁ m (k-1) + (1 - β₁) g k`, `v k = β₂ v (k-1) + (1 - β₂) g k ^ 2`,
`x k = x (k-1) - α k * (m k / (1 - β₁ ^ k)) / √(v k / (1 - β₂ ^ k))`,
with any step-size schedule `α`. The guard `ε` is taken as 0, the card's "apart from the
tiny ε". -/

/-- Adam's state `(x, m, v)` after `k` steps in one variable whose slope is `lam * x`. -/
noncomputable def adamRun (lam : ℝ) (α : ℕ → ℝ) (β₁ β₂ x₀ : ℝ) : ℕ → ℝ × ℝ × ℝ
  | 0 => (x₀, 0, 0)
  | k + 1 =>
    let p := adamRun lam α β₁ β₂ x₀ k
    let g := lam * p.1
    let m := β₁ * p.2.1 + (1 - β₁) * g
    let v := β₂ * p.2.2 + (1 - β₂) * g ^ 2
    (p.1 - α (k + 1) * (m / (1 - β₁ ^ (k + 1))) / Real.sqrt (v / (1 - β₂ ^ (k + 1))), m, v)

/-- Step 4: multiply every slope of one variable by a constant `c > 0` (here, make its wall
curve `c` times more sharply). Then `m` grows by `c`, `v` by `c ^ 2`, the ratio
`m̂ / √v̂` does not change, and Adam's path for that variable is exactly the same at every step,
whatever the step-size schedule and memory fractions. -/
theorem adam_path_ignores_slope_scale (lam c : ℝ) (hc : 0 < c) (α : ℕ → ℝ) (β₁ β₂ x₀ : ℝ)
    (k : ℕ) :
    (adamRun (c * lam) α β₁ β₂ x₀ k).1 = (adamRun lam α β₁ β₂ x₀ k).1 := by
  have key : ∀ n : ℕ, adamRun (c * lam) α β₁ β₂ x₀ n =
      ((adamRun lam α β₁ β₂ x₀ n).1, c * (adamRun lam α β₁ β₂ x₀ n).2.1,
        c ^ 2 * (adamRun lam α β₁ β₂ x₀ n).2.2) := by
    intro n
    induction n with
    | zero => simp [adamRun]
    | succ n ih =>
      rw [adamRun, ih, adamRun]
      simp only
      set x := (adamRun lam α β₁ β₂ x₀ n).1
      set m := (adamRun lam α β₁ β₂ x₀ n).2.1
      set v := (adamRun lam α β₁ β₂ x₀ n).2.2
      have hm : β₁ * (c * m) + (1 - β₁) * (c * lam * x)
          = c * (β₁ * m + (1 - β₁) * (lam * x)) := by ring
      have hv : β₂ * (c ^ 2 * v) + (1 - β₂) * (c * lam * x) ^ 2
          = c ^ 2 * (β₂ * v + (1 - β₂) * (lam * x) ^ 2) := by ring
      rw [hm, hv]
      refine Prod.ext ?_ (Prod.ext rfl rfl)
      simp only
      congr 1
      set M := β₁ * m + (1 - β₁) * (lam * x)
      set V := β₂ * v + (1 - β₂) * (lam * x) ^ 2
      have hsq : Real.sqrt (c ^ 2 * V / (1 - β₂ ^ (n + 1)))
          = c * Real.sqrt (V / (1 - β₂ ^ (n + 1))) := by
        rw [mul_div_assoc, Real.sqrt_mul (sq_nonneg c), Real.sqrt_sq hc.le]
      rw [hsq, mul_div_assoc, mul_div_assoc, mul_div_assoc, mul_div_assoc]
      congr 1
      rw [← mul_div_assoc, mul_div_mul_left _ _ hc.ne']
  rw [key k]

/-! ### The card's worked numbers, checked exactly (μ = 1, L = 100, so κ = 100 and √κ = 10) -/

/-- Heavy ball's settings: `α = 4/121` and `β = 81/121 = (9/11) ^ 2`. -/
example : polyakStep 1 100 = 4 / 121 ∧ polyakMomentum 1 100 = 81 / 121 := by
  have h : Real.sqrt 100 = 10 := by
    rw [show (100 : ℝ) = 10 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]
  have h1 : Real.sqrt 1 = 1 := Real.sqrt_one
  refine ⟨?_, ?_⟩
  · rw [polyakStep, h, h1]; norm_num
  · rw [polyakMomentum, div_one, h]; norm_num

/-- Nesterov's momentum fraction: `β = 9/11`. -/
example : nesterovMomentum 1 100 = 9 / 11 := by
  have h : Real.sqrt 100 = 10 := by
    rw [show (100 : ℝ) = 10 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]
  rw [nesterovMomentum, div_one, h]; norm_num

/-- Plain descent: step `2/(1 + 100) = 2/101`, rate `(100 - 1)/(100 + 1) = 99/101`, and the step
factors along and across the floor are `+99/101` and `-99/101`. -/
example : (2 / (1 + 100) : ℚ) = 2 / 101 ∧ ((100 - 1) / (100 + 1) : ℚ) = 99 / 101 ∧
    (1 - 2 / 101 * 1 : ℚ) = 99 / 101 ∧ (1 - 2 / 101 * 100 : ℚ) = -(99 / 101) := by
  norm_num

/-- Heavy-ball stability: `α L = 400/121` is below `2 (1 + β) = 404/121`, but above plain
descent's limit of 2; and the heavy-ball rate `√β = 9/11` squares to `β`. -/
example : (4 / 121 * 100 : ℚ) = 400 / 121 ∧ (2 * (1 + 81 / 121) : ℚ) = 404 / 121 ∧
    (400 / 121 : ℚ) < 404 / 121 ∧ (2 : ℚ) < 400 / 121 ∧ ((9 / 11) ^ 2 : ℚ) = 81 / 121 := by
  norm_num

/-- Nesterov with κ = 100: across the floor `1 - (1/100) * 100 = 0`, and along it the
recurrence `r ^ 2 - 1.8 r + 0.81` is `(r - 0.9) ^ 2`, rate `1 - 1/10 = 9/10`. -/
example : (1 - 1 / 100 * 100 : ℚ) = 0 ∧
    (1 + 9 / 11 : ℚ) * (1 - 1 / 100) = 9 / 5 ∧ (9 / 11 : ℚ) * (1 - 1 / 100) = 81 / 100 ∧
    ∀ r : ℚ, r ^ 2 - 9 / 5 * r + 81 / 100 = (r - 9 / 10) ^ 2 := by
  refine ⟨by norm_num, by norm_num, by norm_num, fun r => by ring⟩

/-- Adam's first step from `(10, 1)` with `α = 0.3`, `β₁ = 0.9`, `β₂ = 0.999` (and ε = 0): the
slopes are 10 along the floor and 100 across it, yet both variables move exactly 0.3, to
`(9.7, 0.7)`. -/
example : (adamRun 1 (fun _ => 3 / 10) (9 / 10) (999 / 1000) 10 1).1 = 97 / 10 ∧
    (adamRun 100 (fun _ => 3 / 10) (9 / 10) (999 / 1000) 1 1).1 = 7 / 10 := by
  have h : Real.sqrt 100 = 10 := by
    rw [show (100 : ℝ) = 10 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]
  have h2 : Real.sqrt 10000 = 100 := by
    rw [show (10000 : ℝ) = 100 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]
  constructor
  · simp only [adamRun]; norm_num [h]
  · simp only [adamRun]; norm_num [h2]

#print axioms heavy_ball_every_curvature_shrinks_at_one_rate
#print axioms nesterov_double_root_along_floor
#print axioms adam_path_ignores_slope_scale
