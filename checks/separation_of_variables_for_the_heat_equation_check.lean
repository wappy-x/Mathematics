-- Separation of variables: a product X(x)T(t) that solves the heat equation on a bar with both ends held at 0 must be a multiple of e^(−κn²π²t) sin(nπx), every finite sum of such modes solves it, and the shapes sin(nπx) are orthogonal on the bar with ∫ sin² = 1/2.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus

open Real Finset

namespace SeparationOfVariables

/-- A finite sum of cold-end modes on the bar from 0 to 1:
`u(x, t) = ∑_{n ∈ s} b_n e^(−κ n² π² t) sin(nπx)`. -/
noncomputable def modeSum (κ : ℝ) (s : Finset ℕ) (b : ℕ → ℝ) (x t : ℝ) : ℝ :=
  ∑ n ∈ s, b n * exp (-κ * (n : ℝ) ^ 2 * π ^ 2 * t) * sin (n * π * x)

theorem sov_const_on_Ioo (F : ℝ → ℝ) (h : ∀ x ∈ Set.Ioo (0 : ℝ) 1, HasDerivAt F 0 x) :
    ∀ x ∈ Set.Ioo (0 : ℝ) 1, F x = F (1 / 2) := by
  intro x hx
  have hd : DifferentiableOn ℝ F (Set.Ioo 0 1) := fun y hy => (h y hy).differentiableAt.differentiableWithinAt
  exact isOpen_Ioo.is_const_of_deriv_eq_zero isPreconnected_Ioo hd
    (fun y hy => (h y hy).deriv) hx (by norm_num)

theorem sov_ode_neg (f g : ℝ → ℝ) (ω : ℝ) (hω : 0 < ω)
    (hf : ∀ x ∈ Set.Ioo (0 : ℝ) 1, HasDerivAt f (g x) x)
    (hg : ∀ x ∈ Set.Ioo (0 : ℝ) 1, HasDerivAt g (-ω ^ 2 * f x) x) :
    ∃ A B : ℝ, ∀ x ∈ Set.Ioo (0 : ℝ) 1, f x = A * cos (ω * x) + B * sin (ω * x) := by
  have hω0 : ω ≠ 0 := hω.ne'
  set FA : ℝ → ℝ := fun y => f y * cos (ω * y) - g y * sin (ω * y) / ω with hFA
  set FB : ℝ → ℝ := fun y => f y * sin (ω * y) + g y * cos (ω * y) / ω with hFB
  have hA : ∀ x ∈ Set.Ioo (0 : ℝ) 1, HasDerivAt FA 0 x := by
    intro x hx
    have hc := ((hasDerivAt_id' x).const_mul ω).cos
    have hs := ((hasDerivAt_id' x).const_mul ω).sin
    have := ((hf x hx).mul hc).sub (((hg x hx).mul hs).div_const ω)
    convert this using 1
    field_simp
    ring
  have hB : ∀ x ∈ Set.Ioo (0 : ℝ) 1, HasDerivAt FB 0 x := by
    intro x hx
    have hc := ((hasDerivAt_id' x).const_mul ω).cos
    have hs := ((hasDerivAt_id' x).const_mul ω).sin
    have := ((hf x hx).mul hs).add (((hg x hx).mul hc).div_const ω)
    convert this using 1
    field_simp
    ring
  refine ⟨FA (1 / 2), FB (1 / 2), fun x hx => ?_⟩
  rw [← sov_const_on_Ioo FA hA x hx, ← sov_const_on_Ioo FB hB x hx]
  have := sin_sq_add_cos_sq (ω * x)
  simp only [hFA, hFB]
  linear_combination (-f x) * this

theorem sov_ode_pos (f g : ℝ → ℝ) (ω : ℝ) (hω : 0 < ω)
    (hf : ∀ x ∈ Set.Ioo (0 : ℝ) 1, HasDerivAt f (g x) x)
    (hg : ∀ x ∈ Set.Ioo (0 : ℝ) 1, HasDerivAt g (ω ^ 2 * f x) x) :
    ∃ A B : ℝ, ∀ x ∈ Set.Ioo (0 : ℝ) 1, f x = A * cosh (ω * x) + B * sinh (ω * x) := by
  have hω0 : ω ≠ 0 := hω.ne'
  set FA : ℝ → ℝ := fun y => f y * cosh (ω * y) - g y * sinh (ω * y) / ω with hFA
  set FB : ℝ → ℝ := fun y => g y * cosh (ω * y) / ω - f y * sinh (ω * y) with hFB
  have hA : ∀ x ∈ Set.Ioo (0 : ℝ) 1, HasDerivAt FA 0 x := by
    intro x hx
    have hc := ((hasDerivAt_id' x).const_mul ω).cosh
    have hs := ((hasDerivAt_id' x).const_mul ω).sinh
    have := ((hf x hx).mul hc).sub (((hg x hx).mul hs).div_const ω)
    convert this using 1
    field_simp
    ring
  have hB : ∀ x ∈ Set.Ioo (0 : ℝ) 1, HasDerivAt FB 0 x := by
    intro x hx
    have hc := ((hasDerivAt_id' x).const_mul ω).cosh
    have hs := ((hasDerivAt_id' x).const_mul ω).sinh
    have := (((hg x hx).mul hc).div_const ω).sub ((hf x hx).mul hs)
    convert this using 1
    field_simp
    ring
  refine ⟨FA (1 / 2), FB (1 / 2), fun x hx => ?_⟩
  rw [← sov_const_on_Ioo FA hA x hx, ← sov_const_on_Ioo FB hB x hx]
  have := cosh_sq_sub_sinh_sq (ω * x)
  simp only [hFA, hFB]
  linear_combination (-f x) * this

theorem sov_ode_zero (f g : ℝ → ℝ)
    (hf : ∀ x ∈ Set.Ioo (0 : ℝ) 1, HasDerivAt f (g x) x)
    (hg : ∀ x ∈ Set.Ioo (0 : ℝ) 1, HasDerivAt g (0 * f x) x) :
    ∃ A B : ℝ, ∀ x ∈ Set.Ioo (0 : ℝ) 1, f x = A + B * x := by
  set FB : ℝ → ℝ := fun y => f y - y * g y with hFB
  have hA : ∀ x ∈ Set.Ioo (0 : ℝ) 1, HasDerivAt g 0 x := by
    intro x hx
    simpa using hg x hx
  have hB : ∀ x ∈ Set.Ioo (0 : ℝ) 1, HasDerivAt FB 0 x := by
    intro x hx
    have := (hf x hx).sub ((hasDerivAt_id' x).mul (hA x hx))
    convert this using 1
    ring
  refine ⟨FB (1 / 2), g (1 / 2), fun x hx => ?_⟩
  rw [← sov_const_on_Ioo FB hB x hx, ← sov_const_on_Ioo g hA x hx]
  simp only [hFB]
  ring


theorem sov_T_formula (T : ℝ → ℝ) (a t0 : ℝ) (ht0 : 0 < t0)
    (hT : ∀ t > 0, HasDerivAt T (a * T t) t) :
    ∀ t > 0, T t = T t0 * exp (a * (t - t0)) := by
  set G : ℝ → ℝ := fun t => T t * exp (-a * t) with hG
  have hd : ∀ t ∈ Set.Ioi (0 : ℝ), HasDerivAt G 0 t := by
    intro t ht
    have he := ((hasDerivAt_id' t).const_mul (-a)).exp
    have := (hT t ht).mul he
    convert this using 1
    ring
  have hdo : DifferentiableOn ℝ G (Set.Ioi 0) := fun y hy => (hd y hy).differentiableAt.differentiableWithinAt
  intro t ht
  have hc : G t = G t0 := isOpen_Ioi.is_const_of_deriv_eq_zero isPreconnected_Ioi hdo
    (fun y hy => (hd y hy).deriv) ht ht0
  simp only [hG] at hc
  calc T t = T t * exp (-a * t) * exp (a * t) := by
        rw [mul_assoc, ← exp_add]; simp
    _ = T t0 * exp (-a * t0) * exp (a * t) := by rw [hc]
    _ = T t0 * exp (a * (t - t0)) := by
        rw [mul_assoc, ← exp_add]; congr 2; ring

theorem sov_sin_div_hasDerivAt (a x : ℝ) (ha : a ≠ 0) :
    HasDerivAt (fun y => sin (a * y) / a) (cos (a * x)) x := by
  have := (((hasDerivAt_id' x).const_mul a).sin).div_const a
  convert this using 1
  field_simp

#print axioms sov_const_on_Ioo
#print axioms sov_ode_neg
#print axioms sov_ode_pos
#print axioms sov_ode_zero
#print axioms sov_T_formula
#print axioms sov_sin_div_hasDerivAt

/-- **Separation of variables, the card's main claim (Steps 1 to 3).** Take a bar from x = 0 to
x = 1 with diffusivity κ > 0. Guess a temperature that is a space shape times a time factor,
`u(x, t) = X(x) T(t)`, with X twice differentiable inside the bar and continuous up to its ends,
and T differentiable for t > 0. Suppose it solves the heat equation `u_t = κ u_xx`, that is
`X T' = κ X'' T`, inside the bar for t > 0, that both ends are held at 0
(`u(0, t) = u(1, t) = 0`), and that u is not zero everywhere. Then the equation splits and the
cold ends choose the shape: for some mode number n ≥ 1 and some constant c,
`X(x) T(t) = c e^(−κ n² π² t) sin(nπx)` on the whole bar for every t > 0. -/
theorem separated_solution_with_cold_ends_is_a_sine_mode (κ : ℝ) (hκ : 0 < κ) (X T : ℝ → ℝ)
    (hX : ContDiffOn ℝ 2 X (Set.Ioo 0 1)) (hXc : ContinuousOn X (Set.Icc 0 1))
    (hT : DifferentiableOn ℝ T (Set.Ioi 0))
    (heat : ∀ x ∈ Set.Ioo (0 : ℝ) 1, ∀ t > 0,
      X x * deriv T t = κ * (deriv (deriv X) x * T t))
    (ends : ∀ t > 0, X 0 * T t = 0 ∧ X 1 * T t = 0)
    (nonzero : ∃ x ∈ Set.Ioo (0 : ℝ) 1, ∃ t > 0, X x * T t ≠ 0) :
    ∃ n : ℕ, 1 ≤ n ∧ ∃ c : ℝ, ∀ x ∈ Set.Icc (0 : ℝ) 1, ∀ t > 0,
      X x * T t = c * exp (-κ * (n : ℝ) ^ 2 * π ^ 2 * t) * sin (n * π * x) := by
  obtain ⟨x0, hx0, t0, ht0, hne⟩ := nonzero
  have hX0 : X x0 ≠ 0 := left_ne_zero_of_mul hne
  have hT0 : T t0 ≠ 0 := right_ne_zero_of_mul hne
  have hκ0 : κ ≠ 0 := hκ.ne'
  set μ := deriv (deriv X) x0 / X x0 with hμ
  have hTd : ∀ t > 0, deriv T t = κ * μ * T t := by
    intro t ht
    have h := heat x0 hx0 t ht
    rw [hμ]
    field_simp
    linarith
  have hXd : ∀ x ∈ Set.Ioo (0 : ℝ) 1, deriv (deriv X) x = μ * X x := by
    intro x hx
    have h := heat x hx t0 ht0
    rw [hTd t0 ht0] at h
    have h2 : (deriv (deriv X) x - μ * X x) * (κ * T t0) = 0 := by linear_combination -h
    rcases mul_eq_zero.mp h2 with h3 | h3
    · linarith
    · exact absurd h3 (mul_ne_zero hκ0 hT0)
  have hXzero : X 0 = 0 := (mul_eq_zero.mp (ends t0 ht0).1).resolve_right hT0
  have hXone : X 1 = 0 := (mul_eq_zero.mp (ends t0 ht0).2).resolve_right hT0
  have hdX : ∀ x ∈ Set.Ioo (0 : ℝ) 1, HasDerivAt X (deriv X x) x := fun x hx =>
    (((hX.differentiableOn (by norm_num)) x hx).differentiableAt
      (isOpen_Ioo.mem_nhds hx)).hasDerivAt
  have hX1 : ContDiffOn ℝ 1 (deriv X) (Set.Ioo 0 1) :=
    hX.deriv_of_isOpen isOpen_Ioo (by norm_num)
  have hdX' : ∀ x ∈ Set.Ioo (0 : ℝ) 1, HasDerivAt (deriv X) (μ * X x) x := fun x hx => by
    rw [← hXd x hx]
    exact (((hX1.differentiableOn (by norm_num)) x hx).differentiableAt
      (isOpen_Ioo.mem_nhds hx)).hasDerivAt
  have hTform := sov_T_formula T (κ * μ) t0 ht0 (fun t ht => by
    rw [← hTd t ht]
    exact ((hT t ht).differentiableAt (isOpen_Ioi.mem_nhds ht)).hasDerivAt)
  have hcl : Set.Icc (0 : ℝ) 1 ⊆ closure (Set.Ioo 0 1) := by
    rw [closure_Ioo (by norm_num)]
  have h0mem : (0 : ℝ) ∈ Set.Icc (0 : ℝ) 1 := by norm_num
  have h1mem : (1 : ℝ) ∈ Set.Icc (0 : ℝ) 1 := by norm_num
  rcases lt_trichotomy μ 0 with hneg | hzero | hpos
  · -- oscillating case
    set ω := Real.sqrt (-μ) with hω
    have hωpos : 0 < ω := Real.sqrt_pos.mpr (by linarith)
    have hω2 : ω ^ 2 = -μ := Real.sq_sqrt (by linarith)
    obtain ⟨A, B, hAB⟩ := sov_ode_neg X (deriv X) ω hωpos hdX
      (fun x hx => by rw [hω2, neg_neg]; exact hdX' x hx)
    have hext : Set.EqOn X (fun x => A * cos (ω * x) + B * sin (ω * x)) (Set.Icc 0 1) :=
      Set.EqOn.of_subset_closure hAB hXc (by fun_prop) Set.Ioo_subset_Icc_self hcl
    have hA0 : A = 0 := by
      have := hext h0mem
      simp only [mul_zero, cos_zero, sin_zero, mul_one, add_zero] at this
      rw [← this, hXzero]
    have hB0 : B ≠ 0 := by
      intro hB
      apply hX0
      rw [hAB x0 hx0, hA0, hB]
      ring
    have hsin : sin ω = 0 := by
      have := hext h1mem
      simp only [mul_one, hA0, zero_mul, zero_add] at this
      rw [hXone] at this
      exact (mul_eq_zero.mp this.symm).resolve_left hB0
    obtain ⟨k, hk⟩ := Real.sin_eq_zero_iff.mp hsin
    have hkpos : (0 : ℝ) < k := by
      by_contra hcon
      rw [not_lt] at hcon
      have : (k : ℝ) * π ≤ 0 := mul_nonpos_of_nonpos_of_nonneg hcon pi_pos.le
      linarith
    have hk1 : 0 < k := by exact_mod_cast hkpos
    refine ⟨k.toNat, by omega, B * T t0 * exp (κ * (k.toNat : ℝ) ^ 2 * π ^ 2 * t0), ?_⟩
    have hkn : ((k.toNat : ℕ) : ℝ) = (k : ℝ) := by
      have : ((k.toNat : ℤ) : ℝ) = (k : ℝ) := by
        congr 1; omega
      exact_mod_cast this
    intro x hx t ht
    rw [hext hx, hTform t ht, hA0, hkn]
    have hμk : μ = -((k : ℝ) * π) ^ 2 := by rw [hk, hω2]; ring
    rw [hμk, ← hk]
    have : exp (κ * -((k : ℝ) * π) ^ 2 * (t - t0)) =
        exp (-κ * (k : ℝ) ^ 2 * π ^ 2 * t) * exp (κ * (k : ℝ) ^ 2 * π ^ 2 * t0) := by
      rw [← exp_add]; congr 1; ring
    rw [this]
    ring_nf
  · -- linear case
    obtain ⟨A, B, hAB⟩ := sov_ode_zero X (deriv X) hdX
      (fun x hx => by rw [← hzero]; exact hdX' x hx)
    have hext : Set.EqOn X (fun x => A + B * x) (Set.Icc 0 1) :=
      Set.EqOn.of_subset_closure hAB hXc (by fun_prop) Set.Ioo_subset_Icc_self hcl
    have e0 := hext h0mem
    have e1 := hext h1mem
    simp only at e0 e1
    rw [hXzero] at e0
    rw [hXone] at e1
    exfalso
    apply hX0
    rw [hAB x0 hx0]
    have hA : A = 0 := by linarith
    have hB : B = 0 := by linarith
    rw [hA, hB]; ring
  · -- exponential case
    set ω := Real.sqrt μ with hω
    have hωpos : 0 < ω := Real.sqrt_pos.mpr hpos
    have hω2 : ω ^ 2 = μ := Real.sq_sqrt hpos.le
    obtain ⟨A, B, hAB⟩ := sov_ode_pos X (deriv X) ω hωpos hdX
      (fun x hx => by rw [hω2]; exact hdX' x hx)
    have hext : Set.EqOn X (fun x => A * cosh (ω * x) + B * sinh (ω * x)) (Set.Icc 0 1) :=
      Set.EqOn.of_subset_closure hAB hXc (by fun_prop) Set.Ioo_subset_Icc_self hcl
    have e0 := hext h0mem
    have e1 := hext h1mem
    simp only [mul_zero, cosh_zero, sinh_zero, mul_one, add_zero] at e0 e1
    rw [hXzero] at e0
    rw [hXone, ← e0, zero_mul, zero_add] at e1
    have hsh : 0 < sinh ω := Real.sinh_pos_iff.mpr hωpos
    have hB : B = 0 := (mul_eq_zero.mp e1.symm).resolve_right hsh.ne'
    exfalso
    apply hX0
    rw [hAB x0 hx0, ← e0, hB]
    ring

/-- **Adding modes gives solutions (Step 4).** The equation is linear, so any finite sum of
modes `u(x, t) = ∑ b_n e^(−κ n² π² t) sin(nπx)`, with any sizes b_n, solves the heat equation
`u_t = κ u_xx` and keeps both ends at 0. -/
theorem sum_of_modes_solves_heat_equation_with_cold_ends (κ : ℝ) (s : Finset ℕ) (b : ℕ → ℝ) :
    (∀ x t : ℝ, deriv (fun t' => modeSum κ s b x t') t =
      κ * deriv (deriv (fun x' => modeSum κ s b x' t)) x) ∧
    (∀ t : ℝ, modeSum κ s b 0 t = 0 ∧ modeSum κ s b 1 t = 0) := by
  refine ⟨fun x t => ?_, fun t => ⟨?_, ?_⟩⟩
  · have ht : HasDerivAt (fun t' => modeSum κ s b x t')
        (∑ n ∈ s, b n * (exp (-κ * (n : ℝ) ^ 2 * π ^ 2 * t) * (-κ * (n : ℝ) ^ 2 * π ^ 2))
          * sin (n * π * x)) t := by
      unfold modeSum
      apply HasDerivAt.fun_sum
      intro n _
      convert (((hasDerivAt_id' t).const_mul (-κ * (n : ℝ) ^ 2 * π ^ 2)).exp.const_mul (b n)).mul_const
        (sin (n * π * x)) using 1
      ring
    have hx1 : deriv (fun x' => modeSum κ s b x' t) = fun y =>
        ∑ n ∈ s, b n * exp (-κ * (n : ℝ) ^ 2 * π ^ 2 * t) * (cos (n * π * y) * (n * π)) := by
      funext y
      apply HasDerivAt.deriv
      unfold modeSum
      apply HasDerivAt.fun_sum
      intro n _
      convert ((hasDerivAt_id' y).const_mul ((n : ℝ) * π)).sin.const_mul
        (b n * exp (-κ * (n : ℝ) ^ 2 * π ^ 2 * t)) using 1
      ring
    have hx2 : HasDerivAt (fun y =>
        ∑ n ∈ s, b n * exp (-κ * (n : ℝ) ^ 2 * π ^ 2 * t) * (cos (n * π * y) * (n * π)))
        (∑ n ∈ s, b n * exp (-κ * (n : ℝ) ^ 2 * π ^ 2 * t) *
          (-sin (n * π * x) * (n * π) * (n * π))) x := by
      apply HasDerivAt.fun_sum
      intro n _
      convert (((hasDerivAt_id' x).const_mul ((n : ℝ) * π)).cos.mul_const ((n : ℝ) * π)).const_mul
        (b n * exp (-κ * (n : ℝ) ^ 2 * π ^ 2 * t)) using 1
      ring
    rw [ht.deriv, hx1, hx2.deriv, Finset.mul_sum]
    apply Finset.sum_congr rfl
    intro n _
    ring
  · simp [modeSum]
  · simp [modeSum, Real.sin_nat_mul_pi]

/-- **The shapes are perpendicular (Step 4).** For mode numbers m, n ≥ 1, the integral from 0 to
1 of `sin(mπx) sin(nπx)` is 0 when m ≠ n and 1/2 when m = n. This 1/2 is why the coefficient
formula is `b_n = 2 ∫_0^1 f(x) sin(nπx) dx`. -/
theorem sine_modes_are_orthogonal_on_the_bar (m n : ℕ) (hm : 1 ≤ m) (hn : 1 ≤ n) :
    ∫ x in (0 : ℝ)..1, sin (m * π * x) * sin (n * π * x) = if m = n then 1 / 2 else 0 := by
  have hint : IntervalIntegrable (fun x : ℝ => sin (m * π * x) * sin (n * π * x))
      MeasureTheory.volume 0 1 := by
    apply Continuous.intervalIntegrable; fun_prop
  have hprod : ∀ x : ℝ, sin (m * π * x) * sin (n * π * x) =
      (cos (((m : ℝ) - n) * π * x) - cos (((m : ℝ) + n) * π * x)) / 2 := by
    intro x
    rw [show ((m : ℝ) - n) * π * x = m * π * x - n * π * x by ring,
      show ((m : ℝ) + n) * π * x = m * π * x + n * π * x by ring, cos_sub, cos_add]
    ring
  split_ifs with hmn
  · subst hmn
    have ha : (2 * (m : ℝ) * π) ≠ 0 := by
      have : (0 : ℝ) < m := by exact_mod_cast hm
      positivity
    have hF : ∀ x ∈ Set.uIcc (0 : ℝ) 1, HasDerivAt
        (fun y => (y - sin (2 * (m : ℝ) * π * y) / (2 * (m : ℝ) * π)) / 2)
        (sin (m * π * x) * sin (m * π * x)) x := by
      intro x _
      have := (((hasDerivAt_id' x).sub (sov_sin_div_hasDerivAt _ x ha))).div_const 2
      convert this using 1
      rw [hprod x, show ((m : ℝ) + m) * π * x = 2 * (m : ℝ) * π * x by ring]
      simp
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hF hint]
    have : sin (2 * (m : ℝ) * π) = 0 := by
      rw [show (2 * (m : ℝ) * π) = ((2 * m : ℕ) : ℝ) * π by push_cast; ring]
      exact sin_nat_mul_pi _
    simp [this]
  · have hd : ((m : ℝ) - n) * π ≠ 0 := by
      have : (m : ℝ) ≠ n := by exact_mod_cast hmn
      exact mul_ne_zero (sub_ne_zero.mpr this) pi_pos.ne'
    have hs : ((m : ℝ) + n) * π ≠ 0 := by
      have : (0 : ℝ) < m := by exact_mod_cast hm
      have : (0 : ℝ) < n := by exact_mod_cast hn
      positivity
    have hF : ∀ x ∈ Set.uIcc (0 : ℝ) 1, HasDerivAt
        (fun y => (sin (((m : ℝ) - n) * π * y) / (((m : ℝ) - n) * π)
          - sin (((m : ℝ) + n) * π * y) / (((m : ℝ) + n) * π)) / 2)
        (sin (m * π * x) * sin (n * π * x)) x := by
      intro x _
      have := ((sov_sin_div_hasDerivAt _ x hd).sub (sov_sin_div_hasDerivAt _ x hs)).div_const 2
      convert this using 1
      exact hprod x
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hF hint]
    have h1 : sin (((m : ℝ) - n) * π * 1) = 0 := by
      rw [show ((m : ℝ) - n) * π * 1 = (((m : ℤ) - n : ℤ) : ℝ) * π by push_cast; ring]
      exact sin_int_mul_pi _
    have h2 : sin (((m : ℝ) + n) * π * 1) = 0 := by
      rw [show ((m : ℝ) + n) * π * 1 = ((m + n : ℕ) : ℝ) * π by push_cast; ring]
      exact sin_nat_mul_pi _
    simp only [h1, h2, mul_zero, sin_zero]
    simp

-- Three humps fade nine times as fast as one: λ_3 = 3²π² = 9 × 1²π² = 9 λ_1.
example : (3 : ℕ) ^ 2 = 9 * 1 ^ 2 := by norm_num
-- Twice as thick, four times as long: the slowest mode's clock scales with thickness squared.
example : (2 : ℕ) ^ 2 = 4 := by norm_num
-- Flat 100 C start: b_3 / b_1 = (400/(3π)) / (400/π) = 1/3 (42.441 against 127.324).
example : ((400 : ℚ) / 3) / 400 = 1 / 3 := by norm_num
-- Insulated ramp: a_3 / a_1 = (400/(3π)²) / (400/π²) = 1/9 (4.503 against 40.528).
example : ((400 : ℚ) / 3 ^ 2) / 400 = 1 / 9 := by norm_num

#print axioms separated_solution_with_cold_ends_is_a_sine_mode
#print axioms sum_of_modes_solves_heat_equation_with_cold_ends
#print axioms sine_modes_are_orthogonal_on_the_bar

end SeparationOfVariables
