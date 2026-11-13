-- Milstein and the two kinds of error: for silver on geometric Brownian motion, the Milstein loop's path error at the horizon is at most a constant times the step, Euler's path error divided by the square root of the step tends to S₀ e^((2μ+σ²)T/2) σ² √(T/2), and both loops' average error in the squared price is at most a constant times the step.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.MeasureTheory.Constructions.Pi
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic.NormNum
import Mathlib.Probability.Moments.MGFAnalytic
import Mathlib.MeasureTheory.Integral.Pi

open MeasureTheory ProbabilityTheory Filter Topology
open scoped NNReal

/-! Setting, as in the card's Detailed proof. The horizon is `T` years, cut into `n` steps of
length `h = T / n`. The shoves `ΔW_0, ..., ΔW_{n-1}` are independent normal draws with mean 0 and
variance `h`: a point `ω : Fin n → ℝ` drawn from the product measure
`Measure.pi (fun _ => gaussianReal 0 h)`, with `ΔW_k = ω k`. The Brownian value at the horizon is
their sum, so the exact price on the same path is `S_T = S₀ e^((μ - σ²/2) T + σ ∑ ΔW_k)`.

The loops are written for a general one-noise equation `dX = b(X) dt + s(X) dW`; silver is
`b x = μ x`, `s x = σ x`. The slope `σ'` of the card is `deriv s`. -/

/-- One Euler-Maruyama step from `y` with shove `dw`: `y + b(y) h + s(y) dw`. -/
noncomputable def eulerStep (b s : ℝ → ℝ) (h y dw : ℝ) : ℝ :=
  y + b y * h + s y * dw

/-- One Milstein step: the Euler step plus `½ s(y) s'(y) (dw² - h)`. -/
noncomputable def milsteinStep (b s : ℝ → ℝ) (h y dw : ℝ) : ℝ :=
  y + b y * h + s y * dw + 1 / 2 * s y * deriv s y * (dw ^ 2 - h)

/-- The loop's value after all `n` steps, `Y_n`, started from `y₀` and fed the shoves in order. -/
noncomputable def runScheme (step : ℝ → ℝ → ℝ) (y₀ : ℝ) {n : ℕ} (ω : Fin n → ℝ) : ℝ :=
  (List.ofFn ω).foldl step y₀

/-- The exact silver price at the horizon on the same Brownian path. -/
noncomputable def gbmExact (S₀ μ σ T : ℝ) {n : ℕ} (ω : Fin n → ℝ) : ℝ :=
  S₀ * Real.exp ((μ - σ ^ 2 / 2) * T + σ * ∑ k, ω k)

/-- The `n` independent shoves of variance `h = T / n`. -/
noncomputable def shoves (T : ℝ≥0) (n : ℕ) : Measure (Fin n → ℝ) :=
  Measure.pi (fun _ : Fin n => gaussianReal 0 (T / n))

/-- The path error (strong error): `ε_s = √(E[(Y_n - S_T)²])`, scheme and truth on shared shoves. -/
noncomputable def pathError (step : ℝ → ℝ → ℝ) (S₀ μ σ : ℝ) (T : ℝ≥0) (n : ℕ) : ℝ :=
  Real.sqrt (∫ ω, (runScheme step S₀ ω - gbmExact S₀ μ σ T ω) ^ 2 ∂(shoves T n))

/-- The average error (weak error) for the card's test function `f(x) = x²`:
`ε_w = E[Y_n²] - E[S_T²]`. -/
noncomputable def avgErrorSq (step : ℝ → ℝ → ℝ) (S₀ μ σ : ℝ) (T : ℝ≥0) (n : ℕ) : ℝ :=
  (∫ ω, (runScheme step S₀ ω) ^ 2 ∂(shoves T n)) - ∫ ω, (gbmExact S₀ μ σ T ω) ^ 2 ∂(shoves T n)



lemma gm_iter (v : ℝ≥0) (k : ℕ) (t : ℝ) :
    ∫ x, x ^ k * Real.exp (t * x) ∂(gaussianReal 0 v)
      = iteratedDeriv k (fun s : ℝ => Real.exp ((v : ℝ) * s ^ 2 / 2)) t := by
  have h := iteratedDeriv_mgf (X := fun x : ℝ => x) (μ := gaussianReal 0 v) (t := t)
    (by simp) k
  rw [← h, mgf_fun_id_gaussianReal]
  simp

#print axioms gm_iter

lemma gm_int (v : ℝ≥0) (k : ℕ) (t : ℝ) :
    Integrable (fun x => x ^ k * Real.exp (t * x)) (gaussianReal 0 v) :=
  integrable_pow_mul_exp_of_mem_interior_integrableExpSet (X := fun x : ℝ => x) (by simp) k

#print axioms gm_int

lemma gm_d1 (v : ℝ) : deriv (fun s : ℝ => Real.exp (v * s ^ 2 / 2))
    = fun s => (v * s) * Real.exp (v * s ^ 2 / 2) := by
  funext s
  have := ((hasDerivAt_pow 2 s).const_mul v |>.div_const 2).exp
  convert this.deriv using 1
  push_cast; ring

#print axioms gm_d1

lemma gm_dpoly (v : ℝ) (P P' : ℝ → ℝ) (hP : ∀ s, HasDerivAt P (P' s) s) :
    deriv (fun s : ℝ => P s * Real.exp (v * s ^ 2 / 2))
      = fun s => (P' s + P s * (v * s)) * Real.exp (v * s ^ 2 / 2) := by
  funext s
  have h2 := ((hasDerivAt_pow 2 s).const_mul v |>.div_const 2).exp
  have := (hP s).mul h2
  convert this.deriv using 1
  push_cast; ring

#print axioms gm_dpoly

lemma gm_D (v : ℝ) :
    iteratedDeriv 1 (fun s : ℝ => Real.exp (v * s ^ 2 / 2)) = (fun s => (v * s) * Real.exp (v * s ^ 2 / 2)) ∧
    iteratedDeriv 2 (fun s : ℝ => Real.exp (v * s ^ 2 / 2)) = (fun s => (v + v^2 * s^2) * Real.exp (v * s ^ 2 / 2)) ∧
    iteratedDeriv 3 (fun s : ℝ => Real.exp (v * s ^ 2 / 2)) = (fun s => (3 * v^2 * s + v^3 * s^3) * Real.exp (v * s ^ 2 / 2)) ∧
    iteratedDeriv 4 (fun s : ℝ => Real.exp (v * s ^ 2 / 2)) = (fun s => (3 * v^2 + 6 * v^3 * s^2 + v^4 * s^4) * Real.exp (v * s ^ 2 / 2)) := by
  have h1 : iteratedDeriv 1 (fun s : ℝ => Real.exp (v * s ^ 2 / 2)) = (fun s => (v * s) * Real.exp (v * s ^ 2 / 2)) := by
    rw [iteratedDeriv_one, gm_d1]
  have h2 : iteratedDeriv 2 (fun s : ℝ => Real.exp (v * s ^ 2 / 2)) = (fun s => (v + v^2 * s^2) * Real.exp (v * s ^ 2 / 2)) := by
    rw [iteratedDeriv_succ, h1, gm_dpoly v (fun s => v * s) (fun _ => v)]
    · funext s; ring_nf
    · intro s; simpa using (hasDerivAt_id s).const_mul v
  have h3 : iteratedDeriv 3 (fun s : ℝ => Real.exp (v * s ^ 2 / 2)) = (fun s => (3 * v^2 * s + v^3 * s^3) * Real.exp (v * s ^ 2 / 2)) := by
    rw [iteratedDeriv_succ, h2, gm_dpoly v (fun s => v + v^2 * s^2) (fun s => v^2 * (2 * s))]
    · funext s; ring_nf
    · intro s; simpa using ((hasDerivAt_pow 2 s).const_mul (v^2)).const_add v
  have h4 : iteratedDeriv 4 (fun s : ℝ => Real.exp (v * s ^ 2 / 2)) = (fun s => (3 * v^2 + 6 * v^3 * s^2 + v^4 * s^4) * Real.exp (v * s ^ 2 / 2)) := by
    rw [iteratedDeriv_succ, h3, gm_dpoly v (fun s => 3 * v^2 * s + v^3 * s^3) (fun s => 3 * v^2 + v^3 * (3 * s^2))]
    · funext s; ring_nf
    · intro s
      have := ((hasDerivAt_id s).const_mul (3 * v^2)).add ((hasDerivAt_pow 3 s).const_mul (v^3))
      convert this using 1
      · funext y; simp
      · simp
  exact ⟨h1, h2, h3, h4⟩

#print axioms gm_D

/-- Gaussian integral of a quartic times an exponential. -/

lemma gm_poly (v : ℝ≥0) (t c0 c1 c2 c3 c4 : ℝ) :
    Integrable (fun x => (c0 + c1 * x + c2 * x ^ 2 + c3 * x ^ 3 + c4 * x ^ 4) * Real.exp (t * x))
      (gaussianReal 0 v) ∧
    ∫ x, (c0 + c1 * x + c2 * x ^ 2 + c3 * x ^ 3 + c4 * x ^ 4) * Real.exp (t * x) ∂(gaussianReal 0 v)
      = (c0 + c1 * (v * t) + c2 * (v + v ^ 2 * t ^ 2) + c3 * (3 * v ^ 2 * t + v ^ 3 * t ^ 3)
          + c4 * (3 * v ^ 2 + 6 * v ^ 3 * t ^ 2 + v ^ 4 * t ^ 4)) * Real.exp (v * t ^ 2 / 2) := by
  have e : (fun x => (c0 + c1 * x + c2 * x ^ 2 + c3 * x ^ 3 + c4 * x ^ 4) * Real.exp (t * x))
      = fun x => c0 * (x ^ 0 * Real.exp (t * x)) + c1 * (x ^ 1 * Real.exp (t * x))
          + c2 * (x ^ 2 * Real.exp (t * x)) + c3 * (x ^ 3 * Real.exp (t * x))
          + c4 * (x ^ 4 * Real.exp (t * x)) := by
    funext x; ring
  have i0 := (gm_int v 0 t).const_mul c0
  have i1 := (gm_int v 1 t).const_mul c1
  have i2 := (gm_int v 2 t).const_mul c2
  have i3 := (gm_int v 3 t).const_mul c3
  have i4 := (gm_int v 4 t).const_mul c4
  rw [e]
  refine ⟨((((i0.add i1).add i2).add i3).add i4), ?_⟩
  rw [integral_add ?a4 i4, integral_add ?a3 i3, integral_add ?a2 i2, integral_add i0 i1]
  rotate_left
  all_goals try first
    | exact ((i0.add i1).add i2).add i3
    | exact (i0.add i1).add i2
    | exact i0.add i1
  simp only [integral_const_mul, gm_iter]
  obtain ⟨h1, h2, h3, h4⟩ := gm_D (v : ℝ)
  rw [h1, h2, h3, h4, iteratedDeriv_zero]
  ring

#print axioms gm_poly

lemma lpow (u : ℝ) (n : ℕ) (hn : 1 ≤ n) (h : (n : ℝ) * |u| ≤ 1) :
    |(1 + u) ^ n - 1 - n * u| ≤ ((n : ℝ) * u) ^ 2 := by
  have hn' : (1 : ℝ) ≤ n := by exact_mod_cast hn
  have hu : |u| ≤ 1 := by nlinarith [abs_nonneg u]
  have hu1 : -1 ≤ u := by linarith [neg_abs_le u]
  have lo : 1 + n * u ≤ (1 + u) ^ n := one_add_mul_le_pow (by linarith) n
  have up1 : (1 + u) ^ n ≤ Real.exp u ^ n :=
    pow_le_pow_left₀ (by linarith) (by linarith [Real.add_one_le_exp u]) n
  have hnu : |(n : ℝ) * u| ≤ 1 := by rw [abs_mul, Nat.abs_cast]; exact h
  have up2 := Real.abs_exp_sub_one_sub_id_le hnu
  rw [Real.exp_nat_mul] at up2
  have := (abs_le.mp up2).2
  rw [abs_le]; constructor <;> nlinarith [sq_nonneg ((n : ℝ) * u)]

#print axioms lpow

lemma lexp (p q h : ℝ) (h0 : 0 ≤ h) (h1 : h ≤ 1) (hp : |p| * h ≤ 1) :
    |(1 + p * h + q * h ^ 2) * Real.exp (-(p * h)) - 1 - (q - p ^ 2 / 2) * h ^ 2|
      ≤ (|p| ^ 3 / 2 + |p| * |q| + |q| * p ^ 2 / 2 + |p| ^ 3 * (1 + |p| + |q|)) * h ^ 3 := by
  have hx : |-(p * h)| ≤ 1 := by rw [abs_neg, abs_mul, abs_of_nonneg h0]; exact hp
  have hb := Real.exp_bound hx (n := 3) (by norm_num)
  simp [Finset.sum_range_succ, Nat.factorial] at hb
  set r := Real.exp (-(p * h)) - (1 + -(p * h) + (p * h) ^ 2 / 2) with hr
  have hr' : |r| ≤ |p| ^ 3 * h ^ 3 := by
    have : |r| ≤ |p * h| ^ 3 * (4 / 18) := by
      rw [hr]; convert hb using 2 <;> norm_num
    rw [abs_mul, abs_of_nonneg h0] at this
    nlinarith [pow_nonneg (mul_nonneg (abs_nonneg p) h0) 3]
  have he : Real.exp (-(p * h)) = 1 - p * h + p ^ 2 * h ^ 2 / 2 + r := by rw [hr]; ring
  rw [he]
  have key : (1 + p * h + q * h ^ 2) * (1 - p * h + p ^ 2 * h ^ 2 / 2 + r) - 1 - (q - p ^ 2 / 2) * h ^ 2
      = h ^ 3 * (p ^ 3 / 2 - p * q + h * (q * p ^ 2 / 2)) + r * (1 + p * h + q * h ^ 2) := by ring
  rw [key]
  have hh3 : 0 ≤ h ^ 3 := by positivity
  have A1 : |p ^ 3 / 2 - p * q + h * (q * p ^ 2 / 2)| ≤ |p| ^ 3 / 2 + |p| * |q| + |q| * p ^ 2 / 2 := by
    calc _ ≤ |p ^ 3 / 2 - p * q| + |h * (q * p ^ 2 / 2)| := abs_add_le _ _
      _ ≤ |p ^ 3 / 2| + |p * q| + |h * (q * p ^ 2 / 2)| := by gcongr; exact abs_sub _ _
      _ = |p| ^ 3 / 2 + |p| * |q| + h * (|q| * p ^ 2 / 2) := by
          rw [abs_div, abs_pow, abs_mul, abs_mul, abs_of_nonneg h0, abs_div, abs_mul,
            abs_of_nonneg (sq_nonneg p)]; norm_num
      _ ≤ _ := by
          have : 0 ≤ |q| * p ^ 2 / 2 := by positivity
          nlinarith
  have A2 : |1 + p * h + q * h ^ 2| ≤ 1 + |p| + |q| := by
    calc _ ≤ |1 + p * h| + |q * h ^ 2| := abs_add_le _ _
      _ ≤ |1| + |p * h| + |q * h ^ 2| := by gcongr; exact abs_add_le _ _
      _ = 1 + |p| * h + |q| * h ^ 2 := by
          rw [abs_mul, abs_mul, abs_of_nonneg h0, abs_of_nonneg (sq_nonneg h)]; norm_num
      _ ≤ _ := by
          have : h ^ 2 ≤ 1 := by nlinarith
          nlinarith [abs_nonneg p, abs_nonneg q]
  calc _ ≤ |h ^ 3 * (p ^ 3 / 2 - p * q + h * (q * p ^ 2 / 2))| + |r * (1 + p * h + q * h ^ 2)| :=
        abs_add_le _ _
    _ = h ^ 3 * |p ^ 3 / 2 - p * q + h * (q * p ^ 2 / 2)| + |r| * |1 + p * h + q * h ^ 2| := by
        rw [abs_mul, abs_mul, abs_of_nonneg hh3]
    _ ≤ h ^ 3 * (|p| ^ 3 / 2 + |p| * |q| + |q| * p ^ 2 / 2) + (|p| ^ 3 * h ^ 3) * (1 + |p| + |q|) := by
        gcongr
    _ = _ := by ring

#print axioms lexp

lemma powQ (p q T : ℝ) (hT : 0 ≤ T) : ∃ M : ℝ, ∀ᶠ n : ℕ in atTop,
    |((1 + p * (T / n) + q * (T / n) ^ 2) * Real.exp (-(p * (T / n)))) ^ n - 1
        - T ^ 2 * (q - p ^ 2 / 2) / n| ≤ M / (n : ℝ) ^ 2 := by
  set C0 := |p| ^ 3 / 2 + |p| * |q| + |q| * p ^ 2 / 2 + |p| ^ 3 * (1 + |p| + |q|) with hC0
  have hC0n : 0 ≤ C0 := by positivity
  set C1 := |q - p ^ 2 / 2| + C0 with hC1
  have hC1n : 0 ≤ C1 := by positivity
  refine ⟨C0 * T ^ 3 + C1 ^ 2 * T ^ 4, ?_⟩
  filter_upwards [eventually_ge_atTop (⌈T + |p| * T + C1 * T ^ 2⌉₊ + 1)] with n hn
  have hN : T + |p| * T + C1 * T ^ 2 + 1 ≤ (n : ℝ) := by
    have h1 := Nat.le_ceil (T + |p| * T + C1 * T ^ 2)
    have h2 : ((⌈T + |p| * T + C1 * T ^ 2⌉₊ + 1 : ℕ) : ℝ) ≤ n := by exact_mod_cast hn
    push_cast at h2; linarith
  have hpT : 0 ≤ |p| * T := by positivity
  have hCT : 0 ≤ C1 * T ^ 2 := by positivity
  have hn0 : (0 : ℝ) < n := by linarith
  have hn1 : 1 ≤ n := by
    have : (1 : ℝ) ≤ n := by linarith
    exact_mod_cast this
  set h := T / (n : ℝ) with hh
  have hh0 : 0 ≤ h := by positivity
  have hhn : h * n = T := by rw [hh]; field_simp
  have hh1 : h ≤ 1 := by rw [hh, div_le_one hn0]; linarith
  have hph : |p| * h ≤ 1 := by
    rw [hh, ← mul_div_assoc, div_le_one hn0]; linarith
  have hL := lexp p q h hh0 hh1 hph
  rw [← hC0] at hL
  set u := (1 + p * h + q * h ^ 2) * Real.exp (-(p * h)) - 1 with hu
  have hQ : (1 + p * h + q * h ^ 2) * Real.exp (-(p * h)) = 1 + u := by rw [hu]; ring
  rw [hQ]
  have hL' : |u - (q - p ^ 2 / 2) * h ^ 2| ≤ C0 * h ^ 3 := by rw [hu]; exact hL
  have hh32 : h ^ 3 ≤ h ^ 2 := by nlinarith [sq_nonneg h]
  have hub : |u| ≤ C1 * h ^ 2 := by
    calc |u| = |(u - (q - p ^ 2 / 2) * h ^ 2) + (q - p ^ 2 / 2) * h ^ 2| := by ring_nf
      _ ≤ |u - (q - p ^ 2 / 2) * h ^ 2| + |(q - p ^ 2 / 2) * h ^ 2| := abs_add_le _ _
      _ ≤ C0 * h ^ 2 + |q - p ^ 2 / 2| * h ^ 2 := by
          rw [abs_mul, abs_of_nonneg (sq_nonneg h)]
          gcongr
          exact hL'.trans (by gcongr)
      _ = C1 * h ^ 2 := by rw [hC1]; ring
  have hnh2 : (n : ℝ) * h ^ 2 = T ^ 2 / n := by rw [hh]; field_simp
  have hnh3 : (n : ℝ) * h ^ 3 = T ^ 3 / n ^ 2 := by rw [hh]; field_simp
  have hnu : (n : ℝ) * |u| ≤ C1 * T ^ 2 / n := by
    calc (n : ℝ) * |u| ≤ n * (C1 * h ^ 2) := by gcongr
      _ = C1 * (n * h ^ 2) := by ring
      _ = C1 * T ^ 2 / n := by rw [hnh2]; ring
  have hnu1 : (n : ℝ) * |u| ≤ 1 := by
    refine hnu.trans ?_
    rw [div_le_one hn0]; linarith
  have hP := lpow u n hn1 hnu1
  have hsq : ((n : ℝ) * u) ^ 2 ≤ C1 ^ 2 * T ^ 4 / n ^ 2 := by
    have e1 : ((n : ℝ) * u) ^ 2 = ((n : ℝ) * |u|) ^ 2 := by rw [← sq_abs, abs_mul, Nat.abs_cast]
    rw [e1]
    calc ((n : ℝ) * |u|) ^ 2 ≤ (C1 * T ^ 2 / n) ^ 2 := by
          gcongr
      _ = C1 ^ 2 * T ^ 4 / n ^ 2 := by ring
  have hlin : |(n : ℝ) * u - T ^ 2 * (q - p ^ 2 / 2) / n| ≤ C0 * T ^ 3 / n ^ 2 := by
    have e2 : (n : ℝ) * u - T ^ 2 * (q - p ^ 2 / 2) / n = n * (u - (q - p ^ 2 / 2) * h ^ 2) := by
      have : T ^ 2 * (q - p ^ 2 / 2) / (n : ℝ) = (q - p ^ 2 / 2) * (T ^ 2 / n) := by ring
      rw [this, ← hnh2]; ring
    rw [e2, abs_mul, Nat.abs_cast]
    calc (n : ℝ) * |u - (q - p ^ 2 / 2) * h ^ 2| ≤ n * (C0 * h ^ 3) := by gcongr
      _ = C0 * (n * h ^ 3) := by ring
      _ = C0 * T ^ 3 / n ^ 2 := by rw [hnh3]; ring
  calc |(1 + u) ^ n - 1 - T ^ 2 * (q - p ^ 2 / 2) / n|
      = |((1 + u) ^ n - 1 - n * u) + (n * u - T ^ 2 * (q - p ^ 2 / 2) / n)| := by ring_nf
    _ ≤ |(1 + u) ^ n - 1 - n * u| + |n * u - T ^ 2 * (q - p ^ 2 / 2) / n| := abs_add_le _ _
    _ ≤ C1 ^ 2 * T ^ 4 / n ^ 2 + C0 * T ^ 3 / n ^ 2 := by linarith
    _ = (C0 * T ^ 3 + C1 ^ 2 * T ^ 4) / n ^ 2 := by ring

#print axioms powQ

lemma runScheme_mul (step : ℝ → ℝ → ℝ) (A : ℝ → ℝ) (hstep : ∀ y dw, step y dw = y * A dw) :
    ∀ {n : ℕ} (y₀ : ℝ) (ω : Fin n → ℝ), runScheme step y₀ ω = y₀ * ∏ k, A (ω k) := by
  intro n
  induction n with
  | zero => intro y₀ ω; simp [runScheme]
  | succ n ih =>
    intro y₀ ω
    have := ih (step y₀ (ω 0)) (fun i => ω i.succ)
    simp only [runScheme] at this ⊢
    rw [List.ofFn_succ, List.foldl_cons, this, hstep, Fin.prod_univ_succ]
    ring

#print axioms runScheme_mul

lemma gbmExact_prod (S₀ μ σ : ℝ) (T : ℝ≥0) {n : ℕ} (hn : 1 ≤ n) (ω : Fin n → ℝ) :
    gbmExact S₀ μ σ T ω
      = S₀ * ∏ k, Real.exp ((μ - σ ^ 2 / 2) * ((T : ℝ) / n) + σ * ω k) := by
  rw [gbmExact, ← Real.exp_sum, Finset.sum_add_distrib, ← Finset.mul_sum, Finset.sum_const,
    Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
  have : (n : ℝ) ≠ 0 := by exact_mod_cast (show n ≠ 0 by omega)
  congr 3
  all_goals first | rw [Finset.mul_sum] | field_simp

#print axioms gbmExact_prod

lemma path_formula (γ : Measure ℝ) [IsProbabilityMeasure γ] (A B : ℝ → ℝ)
    (iA : Integrable (fun x => A x ^ 2) γ) (iAB : Integrable (fun x => A x * B x) γ)
    (iB : Integrable (fun x => B x ^ 2) γ) (S₀ : ℝ) (n : ℕ) :
    ∫ ω, (S₀ * ∏ k, A (ω k) - S₀ * ∏ k, B (ω k)) ^ 2 ∂(Measure.pi fun _ : Fin n => γ)
      = S₀ ^ 2 * ((∫ x, A x ^ 2 ∂γ) ^ n - 2 * (∫ x, A x * B x ∂γ) ^ n
          + (∫ x, B x ^ 2 ∂γ) ^ n) := by
  have e : (fun ω : Fin n → ℝ => (S₀ * ∏ k, A (ω k) - S₀ * ∏ k, B (ω k)) ^ 2)
      = fun ω => S₀ ^ 2 * (∏ k, A (ω k) ^ 2) - 2 * S₀ ^ 2 * (∏ k, A (ω k) * B (ω k))
          + S₀ ^ 2 * (∏ k, B (ω k) ^ 2) := by
    funext ω
    rw [Finset.prod_mul_distrib, Finset.prod_pow, Finset.prod_pow]
    ring
  have j1 := (Integrable.fintype_prod (μ := fun _ : Fin n => γ) (fun _ => iA)).const_mul (S₀ ^ 2)
  have j2 := (Integrable.fintype_prod (μ := fun _ : Fin n => γ) (fun _ => iAB)).const_mul
    (2 * S₀ ^ 2)
  have j3 := (Integrable.fintype_prod (μ := fun _ : Fin n => γ) (fun _ => iB)).const_mul (S₀ ^ 2)
  rw [e, integral_add ?_ j3, integral_sub j1 j2, integral_const_mul, integral_const_mul,
    integral_const_mul, integral_fintype_prod_eq_pow (fun x => A x ^ 2),
    integral_fintype_prod_eq_pow (fun x => A x * B x), integral_fintype_prod_eq_pow (fun x => B x ^ 2)]
  · simp only [Fintype.card_fin]
    ring
  · exact j1.sub j2

#print axioms path_formula

lemma sq_formula (γ : Measure ℝ) [IsProbabilityMeasure γ] (A : ℝ → ℝ) (S₀ : ℝ) (n : ℕ) :
    ∫ ω, (S₀ * ∏ k, A (ω k)) ^ 2 ∂(Measure.pi fun _ : Fin n => γ)
      = S₀ ^ 2 * (∫ x, A x ^ 2 ∂γ) ^ n := by
  have e : (fun ω : Fin n → ℝ => (S₀ * ∏ k, A (ω k)) ^ 2)
      = fun ω => S₀ ^ 2 * (∏ k, A (ω k) ^ 2) := by
    funext ω; rw [Finset.prod_pow]; ring
  rw [e, integral_const_mul, integral_fintype_prod_eq_pow (fun x => A x ^ 2)]
  simp

#print axioms sq_formula

lemma assemble (n : ℕ) (a c b E α γ : ℝ) (ha : a = E * α) (hc : c = E * γ) (hb : b = E) :
    a ^ n - 2 * c ^ n + b ^ n = E ^ n * (α ^ n - 2 * γ ^ n + 1) := by
  subst ha hc hb; rw [mul_pow, mul_pow]; ring

#print axioms assemble

lemma exp_pow_T (K T : ℝ) {n : ℕ} (hn : 1 ≤ n) : Real.exp (K * (T / n)) ^ n = Real.exp (K * T) := by
  rw [← Real.exp_nat_mul]
  have : (n : ℝ) ≠ 0 := by exact_mod_cast (show n ≠ 0 by omega)
  congr 1; field_simp

#print axioms exp_pow_T

lemma shoves_eq (T : ℝ≥0) (n : ℕ) :
    shoves T n = Measure.pi (fun _ : Fin n => gaussianReal 0 (T / n)) := rfl

#print axioms shoves_eq

lemma coe_Tn (T : ℝ≥0) (n : ℕ) : (((T / n : ℝ≥0)) : ℝ) = (T : ℝ) / n := by push_cast; rfl

#print axioms coe_Tn

lemma euler_closed (S₀ μ σ : ℝ) (T : ℝ≥0) {n : ℕ} (hn : 1 ≤ n) :
    (∫ ω, (runScheme (eulerStep (fun x => μ * x) (fun x => σ * x) ((T : ℝ) / n)) S₀ ω
        - gbmExact S₀ μ σ T ω) ^ 2 ∂(shoves T n))
      = S₀ ^ 2 * Real.exp ((2 * μ + σ ^ 2) * T) *
        (((1 + (2 * μ + σ ^ 2) * ((T : ℝ) / n) + μ ^ 2 * ((T : ℝ) / n) ^ 2)
            * Real.exp (-((2 * μ + σ ^ 2) * ((T : ℝ) / n)))) ^ n
          - 2 * ((1 + (μ + σ ^ 2) * ((T : ℝ) / n) + 0 * ((T : ℝ) / n) ^ 2)
            * Real.exp (-((μ + σ ^ 2) * ((T : ℝ) / n)))) ^ n + 1) ∧
    avgErrorSq (eulerStep (fun x => μ * x) (fun x => σ * x) ((T : ℝ) / n)) S₀ μ σ T n
      = S₀ ^ 2 * Real.exp ((2 * μ + σ ^ 2) * T) *
        (((1 + (2 * μ + σ ^ 2) * ((T : ℝ) / n) + μ ^ 2 * ((T : ℝ) / n) ^ 2)
            * Real.exp (-((2 * μ + σ ^ 2) * ((T : ℝ) / n)))) ^ n - 1) := by
  set h : ℝ := (T : ℝ) / n with hh
  set v : ℝ≥0 := T / n with hv
  have hvh : (v : ℝ) = h := coe_Tn T n
  set A : ℝ → ℝ := fun x => 1 + μ * h + σ * x with hA
  set B : ℝ → ℝ := fun x => Real.exp ((μ - σ ^ 2 / 2) * h + σ * x) with hB
  have hstep : ∀ y dw, eulerStep (fun x => μ * x) (fun x => σ * x) h y dw = y * A dw := by
    intro y dw; simp only [eulerStep, hA]; ring
  have hR : ∀ ω : Fin n → ℝ, runScheme (eulerStep (fun x => μ * x) (fun x => σ * x) h) S₀ ω
      = S₀ * ∏ k, A (ω k) := fun ω => runScheme_mul _ A hstep S₀ ω
  have hG : ∀ ω : Fin n → ℝ, gbmExact S₀ μ σ T ω = S₀ * ∏ k, B (ω k) :=
    fun ω => gbmExact_prod S₀ μ σ T hn ω
  -- Gaussian integrals
  have fA : (fun x => A x ^ 2) = fun x => ((1 + μ * h) ^ 2 + (2 * (1 + μ * h) * σ) * x
      + σ ^ 2 * x ^ 2 + 0 * x ^ 3 + 0 * x ^ 4) * Real.exp (0 * x) := by
    funext x; simp only [hA, zero_mul, Real.exp_zero]; ring
  have fAB : (fun x => A x * B x) = fun x => (Real.exp ((μ - σ ^ 2 / 2) * h) * (1 + μ * h)
      + (Real.exp ((μ - σ ^ 2 / 2) * h) * σ) * x + 0 * x ^ 2 + 0 * x ^ 3 + 0 * x ^ 4)
      * Real.exp (σ * x) := by
    funext x; simp only [hA, hB, Real.exp_add]; ring
  have fB : (fun x => B x ^ 2) = fun x => (Real.exp (2 * ((μ - σ ^ 2 / 2) * h)) + 0 * x
      + 0 * x ^ 2 + 0 * x ^ 3 + 0 * x ^ 4) * Real.exp ((2 * σ) * x) := by
    funext x
    simp only [hB, sq, ← Real.exp_add, zero_mul, add_zero]
    congr 1; ring
  obtain ⟨iA, vA⟩ := gm_poly v 0 ((1 + μ * h) ^ 2) (2 * (1 + μ * h) * σ) (σ ^ 2) 0 0
  obtain ⟨iAB, vAB⟩ := gm_poly v σ (Real.exp ((μ - σ ^ 2 / 2) * h) * (1 + μ * h))
    (Real.exp ((μ - σ ^ 2 / 2) * h) * σ) 0 0 0
  obtain ⟨iB, vB⟩ := gm_poly v (2 * σ) (Real.exp (2 * ((μ - σ ^ 2 / 2) * h))) 0 0 0 0
  rw [← fA] at iA vA
  rw [← fAB] at iAB vAB
  rw [← fB] at iB vB
  rw [hvh] at vA vAB vB
  set K := 2 * μ + σ ^ 2 with hK
  have eA : (∫ x, A x ^ 2 ∂(gaussianReal 0 v)) = Real.exp (K * h) *
      ((1 + K * h + μ ^ 2 * h ^ 2) * Real.exp (-(K * h))) := by
    rw [vA]
    have : Real.exp (K * h) * Real.exp (-(K * h)) = 1 := by rw [← Real.exp_add]; simp
    simp only [zero_mul, mul_zero, zero_pow two_ne_zero, Real.exp_zero, zero_div]
    linear_combination (-(1 + K * h + μ ^ 2 * h ^ 2)) * this
  have eAB : (∫ x, A x * B x ∂(gaussianReal 0 v)) = Real.exp (K * h) *
      ((1 + (μ + σ ^ 2) * h + 0 * h ^ 2) * Real.exp (-((μ + σ ^ 2) * h))) := by
    rw [vAB]
    have E1 : Real.exp ((μ - σ ^ 2 / 2) * h) * Real.exp (h * σ ^ 2 / 2) = Real.exp (μ * h) := by
      rw [← Real.exp_add]; congr 1; ring
    have E2 : Real.exp (K * h) * Real.exp (-((μ + σ ^ 2) * h)) = Real.exp (μ * h) := by
      rw [← Real.exp_add]; congr 1; rw [hK]; ring
    linear_combination (1 + μ * h + σ * (h * σ)) * E1 - (1 + (μ + σ ^ 2) * h) * E2
  have eB : (∫ x, B x ^ 2 ∂(gaussianReal 0 v)) = Real.exp (K * h) := by
    rw [vB]
    simp only [zero_mul, add_zero]
    rw [← Real.exp_add]
    congr 1; rw [hK]; ring
  have hE := exp_pow_T K T hn
  rw [← hh] at hE
  constructor
  · rw [show (fun ω : Fin n → ℝ => (runScheme (eulerStep (fun x => μ * x) (fun x => σ * x) h) S₀ ω
        - gbmExact S₀ μ σ T ω) ^ 2) = fun ω => (S₀ * ∏ k, A (ω k) - S₀ * ∏ k, B (ω k)) ^ 2 from
        funext fun ω => by rw [hR, hG]]
    rw [shoves_eq, path_formula _ A B iA iAB iB, assemble n _ _ _ _ _ _ eA eAB eB, hE]
    ring
  · rw [avgErrorSq, shoves_eq]
    simp only [hR, hG]
    rw [sq_formula, sq_formula, eA, eB, mul_pow, hE]
    ring

#print axioms euler_closed

lemma milstein_closed (S₀ μ σ : ℝ) (T : ℝ≥0) {n : ℕ} (hn : 1 ≤ n) :
    (∫ ω, (runScheme (milsteinStep (fun x => μ * x) (fun x => σ * x) ((T : ℝ) / n)) S₀ ω
        - gbmExact S₀ μ σ T ω) ^ 2 ∂(shoves T n))
      = S₀ ^ 2 * Real.exp ((2 * μ + σ ^ 2) * T) *
        (((1 + (2 * μ + σ ^ 2) * ((T : ℝ) / n) + (μ ^ 2 + σ ^ 4 / 2) * ((T : ℝ) / n) ^ 2)
            * Real.exp (-((2 * μ + σ ^ 2) * ((T : ℝ) / n)))) ^ n
          - 2 * ((1 + (μ + σ ^ 2) * ((T : ℝ) / n) + σ ^ 4 / 2 * ((T : ℝ) / n) ^ 2)
            * Real.exp (-((μ + σ ^ 2) * ((T : ℝ) / n)))) ^ n + 1) ∧
    avgErrorSq (milsteinStep (fun x => μ * x) (fun x => σ * x) ((T : ℝ) / n)) S₀ μ σ T n
      = S₀ ^ 2 * Real.exp ((2 * μ + σ ^ 2) * T) *
        (((1 + (2 * μ + σ ^ 2) * ((T : ℝ) / n) + (μ ^ 2 + σ ^ 4 / 2) * ((T : ℝ) / n) ^ 2)
            * Real.exp (-((2 * μ + σ ^ 2) * ((T : ℝ) / n)))) ^ n - 1) := by
  set h : ℝ := (T : ℝ) / n with hh
  set v : ℝ≥0 := T / n with hv
  have hvh : (v : ℝ) = h := coe_Tn T n
  set a0 : ℝ := 1 + μ * h - σ ^ 2 * h / 2 with ha0
  set A : ℝ → ℝ := fun x => a0 + σ * x + σ ^ 2 / 2 * x ^ 2 with hA
  set B : ℝ → ℝ := fun x => Real.exp ((μ - σ ^ 2 / 2) * h + σ * x) with hB
  have hstep : ∀ y dw, milsteinStep (fun x => μ * x) (fun x => σ * x) h y dw = y * A dw := by
    intro y dw
    have hd : deriv (fun x : ℝ => σ * x) y = σ := by
      simp
    simp only [milsteinStep, hA, ha0, hd]; ring
  have hR : ∀ ω : Fin n → ℝ, runScheme (milsteinStep (fun x => μ * x) (fun x => σ * x) h) S₀ ω
      = S₀ * ∏ k, A (ω k) := fun ω => runScheme_mul _ A hstep S₀ ω
  have hG : ∀ ω : Fin n → ℝ, gbmExact S₀ μ σ T ω = S₀ * ∏ k, B (ω k) :=
    fun ω => gbmExact_prod S₀ μ σ T hn ω
  have fA : (fun x => A x ^ 2) = fun x => (a0 ^ 2 + (2 * a0 * σ) * x
      + (σ ^ 2 + 2 * a0 * (σ ^ 2 / 2)) * x ^ 2 + (2 * σ * (σ ^ 2 / 2)) * x ^ 3
      + (σ ^ 2 / 2) ^ 2 * x ^ 4) * Real.exp (0 * x) := by
    funext x; simp only [hA, zero_mul, Real.exp_zero]; ring
  have fAB : (fun x => A x * B x) = fun x => (Real.exp ((μ - σ ^ 2 / 2) * h) * a0
      + (Real.exp ((μ - σ ^ 2 / 2) * h) * σ) * x
      + (Real.exp ((μ - σ ^ 2 / 2) * h) * (σ ^ 2 / 2)) * x ^ 2 + 0 * x ^ 3 + 0 * x ^ 4)
      * Real.exp (σ * x) := by
    funext x; simp only [hA, hB, Real.exp_add]; ring
  have fB : (fun x => B x ^ 2) = fun x => (Real.exp (2 * ((μ - σ ^ 2 / 2) * h)) + 0 * x
      + 0 * x ^ 2 + 0 * x ^ 3 + 0 * x ^ 4) * Real.exp ((2 * σ) * x) := by
    funext x
    simp only [hB, sq, ← Real.exp_add, zero_mul, add_zero]
    congr 1; ring
  obtain ⟨iA, vA⟩ := gm_poly v 0 (a0 ^ 2) (2 * a0 * σ) (σ ^ 2 + 2 * a0 * (σ ^ 2 / 2))
    (2 * σ * (σ ^ 2 / 2)) ((σ ^ 2 / 2) ^ 2)
  obtain ⟨iAB, vAB⟩ := gm_poly v σ (Real.exp ((μ - σ ^ 2 / 2) * h) * a0)
    (Real.exp ((μ - σ ^ 2 / 2) * h) * σ) (Real.exp ((μ - σ ^ 2 / 2) * h) * (σ ^ 2 / 2)) 0 0
  obtain ⟨iB, vB⟩ := gm_poly v (2 * σ) (Real.exp (2 * ((μ - σ ^ 2 / 2) * h))) 0 0 0 0
  rw [← fA] at iA vA
  rw [← fAB] at iAB vAB
  rw [← fB] at iB vB
  rw [hvh] at vA vAB vB
  set K := 2 * μ + σ ^ 2 with hK
  have eA : (∫ x, A x ^ 2 ∂(gaussianReal 0 v)) = Real.exp (K * h) *
      ((1 + K * h + (μ ^ 2 + σ ^ 4 / 2) * h ^ 2) * Real.exp (-(K * h))) := by
    rw [vA]
    have : Real.exp (K * h) * Real.exp (-(K * h)) = 1 := by rw [← Real.exp_add]; simp
    simp only [mul_zero, zero_pow two_ne_zero, Real.exp_zero, zero_div]
    rw [ha0, hK] at *
    linear_combination (-(1 + (2 * μ + σ ^ 2) * h + (μ ^ 2 + σ ^ 4 / 2) * h ^ 2)) * this
  have eAB : (∫ x, A x * B x ∂(gaussianReal 0 v)) = Real.exp (K * h) *
      ((1 + (μ + σ ^ 2) * h + σ ^ 4 / 2 * h ^ 2) * Real.exp (-((μ + σ ^ 2) * h))) := by
    rw [vAB]
    have E1 : Real.exp ((μ - σ ^ 2 / 2) * h) * Real.exp (h * σ ^ 2 / 2) = Real.exp (μ * h) := by
      rw [← Real.exp_add]; congr 1; ring
    have E2 : Real.exp (K * h) * Real.exp (-((μ + σ ^ 2) * h)) = Real.exp (μ * h) := by
      rw [← Real.exp_add]; congr 1; rw [hK]; ring
    rw [ha0]
    linear_combination (1 + μ * h - σ ^ 2 * h / 2 + σ * (h * σ) + σ ^ 2 / 2 * (h + h ^ 2 * σ ^ 2))
      * E1 - (1 + (μ + σ ^ 2) * h + σ ^ 4 / 2 * h ^ 2) * E2
  have eB : (∫ x, B x ^ 2 ∂(gaussianReal 0 v)) = Real.exp (K * h) := by
    rw [vB]
    simp only [zero_mul, add_zero]
    rw [← Real.exp_add]
    congr 1; rw [hK]; ring
  have hE := exp_pow_T K T hn
  rw [← hh] at hE
  constructor
  · rw [show (fun ω : Fin n → ℝ => (runScheme (milsteinStep (fun x => μ * x) (fun x => σ * x) h)
        S₀ ω - gbmExact S₀ μ σ T ω) ^ 2) = fun ω => (S₀ * ∏ k, A (ω k) - S₀ * ∏ k, B (ω k)) ^ 2
        from funext fun ω => by rw [hR, hG]]
    rw [shoves_eq, path_formula _ A B iA iAB iB, assemble n _ _ _ _ _ _ eA eAB eB, hE]
    ring
  · rw [avgErrorSq, shoves_eq]
    simp only [hR, hG]
    rw [sq_formula, sq_formula, eA, eB, mul_pow, hE]
    ring

#print axioms milstein_closed

lemma bound_of_eventually (T : ℝ) (hT : 0 < T) (f : ℕ → ℝ) (C₀ : ℝ)
    (hf : ∀ᶠ n : ℕ in atTop, f n ≤ C₀ * (T / n)) :
    ∃ C : ℝ, ∀ n : ℕ, 1 ≤ n → f n ≤ C * (T / n) := by
  obtain ⟨N, hN⟩ := eventually_atTop.mp hf
  have hS : 0 ≤ ∑ k ∈ Finset.range N, |f k| * k / T := by
    apply Finset.sum_nonneg; intro k _; positivity
  refine ⟨|C₀| + ∑ k ∈ Finset.range N, |f k| * k / T, fun n hn => ?_⟩
  have hn0 : (0 : ℝ) < n := by exact_mod_cast hn
  have hTn : 0 ≤ T / n := by positivity
  by_cases hnN : N ≤ n
  · calc f n ≤ C₀ * (T / n) := hN n hnN
      _ ≤ |C₀| * (T / n) := by gcongr; exact le_abs_self _
      _ ≤ _ := by gcongr; linarith
  · have hk : |f n| * n / T ≤ ∑ k ∈ Finset.range N, |f k| * k / T :=
      Finset.single_le_sum (f := fun k : ℕ => |f k| * k / T) (fun k _ => by positivity)
        (Finset.mem_range.mpr (by omega))
    calc f n ≤ |f n| := le_abs_self _
      _ = (|f n| * n / T) * (T / n) := by field_simp
      _ ≤ (|C₀| + ∑ k ∈ Finset.range N, |f k| * k / T) * (T / n) := by
          gcongr; linarith [abs_nonneg C₀]

#print axioms bound_of_eventually

lemma tendsto_of_bound (f : ℕ → ℝ) (L M : ℝ) (h : ∀ᶠ n : ℕ in atTop, |f n - L| ≤ M / n) :
    Tendsto f atTop (𝓝 L) := by
  rw [tendsto_iff_norm_sub_tendsto_zero]
  refine squeeze_zero' (Eventually.of_forall (fun n => norm_nonneg _)) ?_
    (tendsto_const_div_atTop_nhds_zero_nat M)
  filter_upwards [h] with n hn
  rwa [Real.norm_eq_abs]

#print axioms tendsto_of_bound

/-- **Milstein has path error of order one.** For silver on geometric Brownian motion, with any
starting price `S₀`, drift `μ`, volatility `σ` and horizon `T`, there is one constant `C` such that
for every number of steps `n ≥ 1` the Milstein loop's root-mean-square gap to the exact price on the
same Brownian path is at most `C` times the step `Δt = T / n`: each halving of the step halves the
path error. -/
theorem milstein_path_error_order_one (S₀ μ σ : ℝ) (T : ℝ≥0) :
    ∃ C : ℝ, ∀ n : ℕ, 1 ≤ n →
      pathError (milsteinStep (fun x => μ * x) (fun x => σ * x) ((T : ℝ) / n)) S₀ μ σ T n
        ≤ C * ((T : ℝ) / n) := by
  rcases (NNReal.coe_nonneg T).eq_or_lt with hT0 | hT
  · refine ⟨0, fun n hn => ?_⟩
    rw [pathError, (milstein_closed S₀ μ σ T hn).1, ← hT0]
    norm_num
  set K := 2 * μ + σ ^ 2 with hK
  obtain ⟨M1, hM1⟩ := powQ K (μ ^ 2 + σ ^ 4 / 2) T hT.le
  obtain ⟨M2, hM2⟩ := powQ (μ + σ ^ 2) (σ ^ 4 / 2) T hT.le
  set W := S₀ ^ 2 * Real.exp (K * T) * (M1 + 2 * M2) with hW
  apply bound_of_eventually T hT _ ((W + 1) / T)
  filter_upwards [hM1, hM2, eventually_ge_atTop 1] with n h1 h2 hn
  have hn0 : (0 : ℝ) < n := by exact_mod_cast hn
  rw [pathError, (milstein_closed S₀ μ σ T hn).1]
  set α := ((1 + K * ((T : ℝ) / n) + (μ ^ 2 + σ ^ 4 / 2) * ((T : ℝ) / n) ^ 2)
            * Real.exp (-(K * ((T : ℝ) / n)))) ^ n with hα
  set γ := ((1 + (μ + σ ^ 2) * ((T : ℝ) / n) + σ ^ 4 / 2 * ((T : ℝ) / n) ^ 2)
            * Real.exp (-((μ + σ ^ 2) * ((T : ℝ) / n)))) ^ n with hγ
  have hX : |α - 2 * γ + 1| ≤ (M1 + 2 * M2) / (n : ℝ) ^ 2 := by
    have e : α - 2 * γ + 1 = (α - 1 - (T : ℝ) ^ 2 * (μ ^ 2 + σ ^ 4 / 2 - K ^ 2 / 2) / n)
        - 2 * (γ - 1 - (T : ℝ) ^ 2 * (σ ^ 4 / 2 - (μ + σ ^ 2) ^ 2 / 2) / n) := by
      rw [hK]; ring
    rw [e]
    calc _ ≤ |α - 1 - (T : ℝ) ^ 2 * (μ ^ 2 + σ ^ 4 / 2 - K ^ 2 / 2) / n|
          + |2 * (γ - 1 - (T : ℝ) ^ 2 * (σ ^ 4 / 2 - (μ + σ ^ 2) ^ 2 / 2) / n)| := abs_sub _ _
      _ = |α - 1 - (T : ℝ) ^ 2 * (μ ^ 2 + σ ^ 4 / 2 - K ^ 2 / 2) / n|
          + 2 * |γ - 1 - (T : ℝ) ^ 2 * (σ ^ 4 / 2 - (μ + σ ^ 2) ^ 2 / 2) / n| := by
          rw [abs_mul, abs_two]
      _ ≤ M1 / (n : ℝ) ^ 2 + 2 * (M2 / (n : ℝ) ^ 2) := by gcongr
      _ = _ := by ring
  have hC : 0 ≤ S₀ ^ 2 * Real.exp (K * T) := by positivity
  have hY : S₀ ^ 2 * Real.exp (K * T) * (α - 2 * γ + 1) ≤ W / (n : ℝ) ^ 2 := by
    calc _ ≤ S₀ ^ 2 * Real.exp (K * T) * |α - 2 * γ + 1| := by gcongr; exact le_abs_self _
      _ ≤ S₀ ^ 2 * Real.exp (K * T) * ((M1 + 2 * M2) / (n : ℝ) ^ 2) := by gcongr
      _ = W / (n : ℝ) ^ 2 := by rw [hW]; ring
  rw [Real.sqrt_le_iff]
  have hTT : (W + 1) / T * (T / n) = (W + 1) / n := by field_simp
  rw [hTT]
  constructor
  · -- nonnegativity: W ≥ 0 is not needed; use that the square bound forces it
    have hWn : 0 ≤ W := by
      have hM : 0 ≤ M1 + 2 * M2 := by
        have := (abs_nonneg _).trans hX
        have hn2 : (0 : ℝ) < (n : ℝ) ^ 2 := by positivity
        exact (div_nonneg_iff.mp this).elim (fun h => h.1) (fun h => absurd h.2 (not_le.mpr hn2))
      rw [hW]; positivity
    positivity
  · refine hY.trans ?_
    rw [div_pow]
    gcongr ?_ / _
    nlinarith [sq_nonneg (W + 1 / 2)]

/-- **Euler's path error has order exactly one half.** For silver on geometric Brownian motion,
the Euler loop's root-mean-square gap to the exact price, divided by `√Δt`, tends to
`S₀ e^((2μ + σ²) T / 2) σ² √(T / 2)` as the number of steps grows (2.0995 for the card's ounce).
So when `S₀`, `σ` and `T` are not zero, Euler's path error falls only like the square root of the
step, and Milstein's correction is what raises the rate to the step itself. -/
theorem euler_path_error_order_half (S₀ μ σ : ℝ) (T : ℝ≥0) :
    Tendsto
      (fun n : ℕ =>
        pathError (eulerStep (fun x => μ * x) (fun x => σ * x) ((T : ℝ) / n)) S₀ μ σ T n
          / Real.sqrt ((T : ℝ) / n))
      atTop
      (𝓝 (|S₀| * Real.exp ((2 * μ + σ ^ 2) * T / 2) * σ ^ 2 * Real.sqrt ((T : ℝ) / 2))) := by
  rcases (NNReal.coe_nonneg T).eq_or_lt with hT0 | hT
  · rw [← hT0]; simp
  set K := 2 * μ + σ ^ 2 with hK
  obtain ⟨M1, hM1⟩ := powQ K (μ ^ 2) T hT.le
  obtain ⟨M2, hM2⟩ := powQ (μ + σ ^ 2) 0 T hT.le
  set D := S₀ ^ 2 * Real.exp (K * T) with hD
  have hDn : 0 ≤ D := by positivity
  set L := D * ((T : ℝ) * σ ^ 4 / 2) with hL
  have hlim : Tendsto (fun n : ℕ => D * ((((1 + K * ((T : ℝ) / n) + μ ^ 2 * ((T : ℝ) / n) ^ 2)
            * Real.exp (-(K * ((T : ℝ) / n)))) ^ n
          - 2 * ((1 + (μ + σ ^ 2) * ((T : ℝ) / n) + 0 * ((T : ℝ) / n) ^ 2)
            * Real.exp (-((μ + σ ^ 2) * ((T : ℝ) / n)))) ^ n + 1) * n / T)) atTop (𝓝 L) := by
    apply tendsto_of_bound _ L (D * (|M1| + 2 * |M2|) / T)
    filter_upwards [hM1, hM2, eventually_ge_atTop 1] with n h1 h2 hn
    have hn0 : (0 : ℝ) < n := by exact_mod_cast hn
    set α := ((1 + K * ((T : ℝ) / n) + μ ^ 2 * ((T : ℝ) / n) ^ 2)
            * Real.exp (-(K * ((T : ℝ) / n)))) ^ n with hα
    set γ := ((1 + (μ + σ ^ 2) * ((T : ℝ) / n) + 0 * ((T : ℝ) / n) ^ 2)
            * Real.exp (-((μ + σ ^ 2) * ((T : ℝ) / n)))) ^ n with hγ
    set E1 := α - 1 - (T : ℝ) ^ 2 * (μ ^ 2 - K ^ 2 / 2) / n with hE1
    set E2 := γ - 1 - (T : ℝ) ^ 2 * (0 - (μ + σ ^ 2) ^ 2 / 2) / n with hE2
    have e : D * ((α - 2 * γ + 1) * n / T) - L = D * (E1 - 2 * E2) * n / T := by
      rw [hE1, hE2, hL, hK]; field_simp; ring
    rw [e]
    have hb : |E1 - 2 * E2| ≤ (|M1| + 2 * |M2|) / (n : ℝ) ^ 2 := by
      calc |E1 - 2 * E2| ≤ |E1| + |2 * E2| := abs_sub _ _
        _ = |E1| + 2 * |E2| := by rw [abs_mul, abs_two]
        _ ≤ M1 / (n : ℝ) ^ 2 + 2 * (M2 / (n : ℝ) ^ 2) := by gcongr
        _ ≤ |M1| / (n : ℝ) ^ 2 + 2 * (|M2| / (n : ℝ) ^ 2) := by
            gcongr <;> exact le_abs_self _
        _ = _ := by ring
    calc |D * (E1 - 2 * E2) * n / T| = D * |E1 - 2 * E2| * n / T := by
          rw [abs_div, abs_mul, abs_mul, abs_of_nonneg hDn, Nat.abs_cast, abs_of_pos hT]
      _ ≤ D * ((|M1| + 2 * |M2|) / (n : ℝ) ^ 2) * n / T := by gcongr
      _ = D * (|M1| + 2 * |M2|) / T / n := by field_simp
  have hs := (Real.continuous_sqrt.tendsto L).comp hlim
  have htarget : Real.sqrt L
      = |S₀| * Real.exp ((2 * μ + σ ^ 2) * T / 2) * σ ^ 2 * Real.sqrt ((T : ℝ) / 2) := by
    have hnn : 0 ≤ |S₀| * Real.exp ((2 * μ + σ ^ 2) * T / 2) * σ ^ 2 * Real.sqrt ((T : ℝ) / 2) := by
      positivity
    rw [← Real.sqrt_sq hnn]
    congr 1
    have h1 : Real.exp ((2 * μ + σ ^ 2) * T / 2) ^ 2 = Real.exp (K * T) := by
      rw [← Real.exp_nat_mul]; congr 1; rw [hK]; push_cast; ring
    have h2 : Real.sqrt ((T : ℝ) / 2) ^ 2 = (T : ℝ) / 2 := Real.sq_sqrt (by positivity)
    rw [hL, hD, mul_pow, mul_pow, mul_pow, h1, h2, sq_abs]
    ring
  rw [← htarget]
  refine hs.congr' ?_
  filter_upwards [eventually_ge_atTop 1] with n hn
  have hn0 : (0 : ℝ) < n := by exact_mod_cast hn
  simp only [Function.comp]
  rw [pathError, (euler_closed S₀ μ σ T hn).1, ← Real.sqrt_div' _ (by positivity)]
  congr 1
  rw [hD, hK]
  field_simp

/-- **Both loops have average error of order one.** For silver on geometric Brownian motion and
the test function `f(x) = x²`, there is one constant `C` such that for every `n ≥ 1` the gap between
the loop's average squared price and the true average squared price is at most `C` times the step
`Δt = T / n`, for Euler and for Milstein alike: the correction buys no faster rate on averages. -/
theorem average_error_order_one_both_schemes (S₀ μ σ : ℝ) (T : ℝ≥0) :
    ∃ C : ℝ, ∀ n : ℕ, 1 ≤ n →
      |avgErrorSq (eulerStep (fun x => μ * x) (fun x => σ * x) ((T : ℝ) / n)) S₀ μ σ T n|
          ≤ C * ((T : ℝ) / n) ∧
      |avgErrorSq (milsteinStep (fun x => μ * x) (fun x => σ * x) ((T : ℝ) / n)) S₀ μ σ T n|
          ≤ C * ((T : ℝ) / n) := by
  rcases (NNReal.coe_nonneg T).eq_or_lt with hT0 | hT
  · refine ⟨0, fun n hn => ⟨?_, ?_⟩⟩
    · rw [(euler_closed S₀ μ σ T hn).2, ← hT0]; simp
    · rw [(milstein_closed S₀ μ σ T hn).2, ← hT0]; simp
  set K := 2 * μ + σ ^ 2 with hK
  have hD : 0 ≤ S₀ ^ 2 * Real.exp (K * T) := by positivity
  have key : ∀ q : ℝ, ∃ C : ℝ, ∀ n : ℕ, 1 ≤ n →
      |S₀ ^ 2 * Real.exp (K * T) * (((1 + K * ((T : ℝ) / n) + q * ((T : ℝ) / n) ^ 2)
            * Real.exp (-(K * ((T : ℝ) / n)))) ^ n - 1)| ≤ C * ((T : ℝ) / n) := by
    intro q
    obtain ⟨M, hM⟩ := powQ K q T hT.le
    set B := |(T : ℝ) ^ 2 * (q - K ^ 2 / 2)| + |M| with hB
    apply bound_of_eventually T hT _ (S₀ ^ 2 * Real.exp (K * T) * B / T)
    filter_upwards [hM, eventually_ge_atTop 1] with n h1 hn
    have hn0 : (0 : ℝ) < n := by exact_mod_cast hn
    have hn1 : (1 : ℝ) ≤ n := by exact_mod_cast hn
    set α := ((1 + K * ((T : ℝ) / n) + q * ((T : ℝ) / n) ^ 2)
            * Real.exp (-(K * ((T : ℝ) / n)))) ^ n with hα
    have hb : |α - 1| ≤ B / n := by
      have e : α - 1 = (α - 1 - (T : ℝ) ^ 2 * (q - K ^ 2 / 2) / n)
          + (T : ℝ) ^ 2 * (q - K ^ 2 / 2) / n := by ring
      have hnn : (n : ℝ) ≤ (n : ℝ) ^ 2 := by nlinarith
      rw [e]
      calc _ ≤ |α - 1 - (T : ℝ) ^ 2 * (q - K ^ 2 / 2) / n|
            + |(T : ℝ) ^ 2 * (q - K ^ 2 / 2) / n| := abs_add_le _ _
        _ ≤ |M| / n + |(T : ℝ) ^ 2 * (q - K ^ 2 / 2)| / n := by
            gcongr
            · refine h1.trans ?_
              calc M / (n : ℝ) ^ 2 ≤ |M| / (n : ℝ) ^ 2 := by gcongr; exact le_abs_self _
                _ ≤ |M| / n := by gcongr
            · rw [abs_div, Nat.abs_cast]
        _ = B / n := by rw [hB]; ring
    calc |S₀ ^ 2 * Real.exp (K * T) * (α - 1)| = S₀ ^ 2 * Real.exp (K * T) * |α - 1| := by
          rw [abs_mul, abs_of_nonneg hD]
      _ ≤ S₀ ^ 2 * Real.exp (K * T) * (B / n) := by gcongr
      _ = S₀ ^ 2 * Real.exp (K * T) * B / T * (T / n) := by field_simp
  obtain ⟨C1, hC1⟩ := key (μ ^ 2)
  obtain ⟨C2, hC2⟩ := key (μ ^ 2 + σ ^ 4 / 2)
  refine ⟨max C1 C2, fun n hn => ⟨?_, ?_⟩⟩
  · rw [(euler_closed S₀ μ σ T hn).2]
    refine (hC1 n hn).trans ?_
    gcongr; exact le_max_left _ _
  · rw [(milstein_closed S₀ μ σ T hn).2]
    refine (hC2 n hn).trans ?_
    gcongr; exact le_max_right _ _

/-! The card's worked month, with exact fractions: `μ = 0.05 = 1/20`, `σ = 0.30 = 3/10`,
`Δt = 1/12`, from `$30`, with the shove `ΔW = -0.60 = -3/5` and then `+0.60`. -/

-- For silver σσ' = 0.30 × 0.30 = 0.09, and ½σ² = 0.045.
example : (3 / 10 : ℚ) * (3 / 10) = 9 / 100 ∧ (1 / 2 : ℚ) * (3 / 10) ^ 2 = 9 / 200 := by norm_num
-- Drift part μΔt = 0.05 × (1/12) = 1/240, and noise part σΔW = 0.30 × (-0.60) = -0.18.
example : (1 / 20 : ℚ) * (1 / 12) = 1 / 240 ∧ (3 / 10 : ℚ) * (-3 / 5) = -9 / 50 := by norm_num
-- Euler factor 1 + 1/240 - 0.18 = 989/1200 (0.824167).
example : (1 : ℚ) + 1 / 240 - 9 / 50 = 989 / 1200 := by norm_num
-- The correction ½σ²(ΔW² - Δt) = 0.045 × (0.36 - 1/12) = 0.01245 exactly.
example : (9 / 200 : ℚ) * ((-3 / 5) ^ 2 - 1 / 12) = 1245 / 100000 := by norm_num
-- Milstein factor 989/1200 + 0.01245 (0.836617).
example : (989 / 1200 : ℚ) + 1245 / 100000 = 50197 / 60000 := by norm_num
-- Euler price 30 × 989/1200 = $24.7250, and Milstein price 30 × 50197/60000 = $25.0985.
example : (30 : ℚ) * (989 / 1200) = 24725 / 1000 ∧ (30 : ℚ) * (50197 / 60000) = 250985 / 10000 := by
  norm_num
-- With the shove +0.60 the same correction is added: Euler $35.5250, Milstein $35.8985.
example : (30 : ℚ) * (1 + 1 / 240 + 9 / 50) = 355250 / 10000 ∧
    (30 : ℚ) * (1 + 1 / 240 + 9 / 50 + 9 / 200 * ((3 / 5) ^ 2 - 1 / 12)) = 358985 / 10000 := by
  norm_num

#print axioms milstein_path_error_order_one
#print axioms euler_path_error_order_half
#print axioms average_error_order_one_both_schemes
