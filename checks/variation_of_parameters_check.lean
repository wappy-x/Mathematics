-- Variation of parameters: with two free solutions whose Wronskian never vanishes, the formula y_p = -y₁ ∫ y₂ g / W + y₂ ∫ y₁ g / W solves y'' + p y' + q y = g from rest, every forced solution is y_p plus a free motion, and for the cart y'' + y = sec t it gives cos t ln cos t + t sin t.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Log.Deriv

open Real

theorem vop_ftc_on (I : Set ℝ) (hIo : IsOpen I) (hIc : I.OrdConnected) (t₀ : ℝ) (ht₀ : t₀ ∈ I)
    (f : ℝ → ℝ) (hf : ContinuousOn f I) :
    ∀ t ∈ I, HasDerivAt (fun u => ∫ x in t₀..u, f x) (f t) t := by
  intro t ht
  apply intervalIntegral.integral_hasDerivAt_right
  · exact (hf.mono (hIc.uIcc_subset ht₀ ht)).intervalIntegrable
  · exact hf.stronglyMeasurableAtFilter hIo t ht
  · exact hf.continuousAt (hIo.mem_nhds ht)

#print axioms vop_ftc_on

/-- The method works: let p, q and g be continuous on an open interval I containing the start t₀,
and let y₁, y₂ be free solutions of y'' + p y' + q y = 0 on I (with velocities y₁', y₂') whose
Wronskian W = y₁ y₂' − y₂ y₁' is never zero on I. Then
y_p(t) = −y₁(t) ∫_{t₀}^t y₂ g / W + y₂(t) ∫_{t₀}^t y₁ g / W
starts at 0 with velocity 0, keeps the fixed-weight velocity
y_p'(t) = −y₁'(t) ∫_{t₀}^t y₂ g / W + y₂'(t) ∫_{t₀}^t y₁ g / W,
and solves the forced equation y'' + p y' + q y = g at every point of I. -/
theorem variation_of_parameters_solves_forced_equation
    (I : Set ℝ) (hIo : IsOpen I) (hIc : I.OrdConnected) (t₀ : ℝ) (ht₀ : t₀ ∈ I)
    (p q g : ℝ → ℝ) (hp : ContinuousOn p I) (hq : ContinuousOn q I) (hg : ContinuousOn g I)
    (y₁ y₁' y₂ y₂' : ℝ → ℝ)
    (hy₁ : ∀ t ∈ I, HasDerivAt y₁ (y₁' t) t)
    (hy₁' : ∀ t ∈ I, HasDerivAt y₁' (-(p t * y₁' t) - q t * y₁ t) t)
    (hy₂ : ∀ t ∈ I, HasDerivAt y₂ (y₂' t) t)
    (hy₂' : ∀ t ∈ I, HasDerivAt y₂' (-(p t * y₂' t) - q t * y₂ t) t)
    (hW : ∀ t ∈ I, y₁ t * y₂' t - y₂ t * y₁' t ≠ 0) :
    let W : ℝ → ℝ := fun t => y₁ t * y₂' t - y₂ t * y₁' t
    let yp : ℝ → ℝ := fun t =>
      -y₁ t * (∫ s in t₀..t, y₂ s * g s / W s) + y₂ t * (∫ s in t₀..t, y₁ s * g s / W s)
    let yp' : ℝ → ℝ := fun t =>
      -y₁' t * (∫ s in t₀..t, y₂ s * g s / W s) + y₂' t * (∫ s in t₀..t, y₁ s * g s / W s)
    yp t₀ = 0 ∧ yp' t₀ = 0 ∧
      ∀ t ∈ I, HasDerivAt yp (yp' t) t ∧
        HasDerivAt yp' (g t - p t * yp' t - q t * yp t) t := by
  intro W yp yp'
  have c1 : ContinuousOn y₁ I := fun t ht => (hy₁ t ht).continuousAt.continuousWithinAt
  have c2 : ContinuousOn y₂ I := fun t ht => (hy₂ t ht).continuousAt.continuousWithinAt
  have c1' : ContinuousOn y₁' I := fun t ht => (hy₁' t ht).continuousAt.continuousWithinAt
  have c2' : ContinuousOn y₂' I := fun t ht => (hy₂' t ht).continuousAt.continuousWithinAt
  have cW : ContinuousOn W I := (c1.mul c2').sub (c2.mul c1')
  have hA := vop_ftc_on I hIo hIc t₀ ht₀ (fun s => y₂ s * g s / W s)
    ((c2.mul hg).div cW hW)
  have hB := vop_ftc_on I hIo hIc t₀ ht₀ (fun s => y₁ s * g s / W s)
    ((c1.mul hg).div cW hW)
  refine ⟨by simp [yp], by simp [yp'], fun t ht => ⟨?_, ?_⟩⟩
  · have h := (((hy₁ t ht).neg).mul (hA t ht)).add ((hy₂ t ht).mul (hB t ht))
    convert h using 1
    simp only [yp', Pi.neg_apply]
    ring
  · have h := (((hy₁' t ht).neg).mul (hA t ht)).add ((hy₂' t ht).mul (hB t ht))
    convert h using 1
    have hWt : W t ≠ 0 := hW t ht
    have key : y₂' t * (y₁ t * g t / W t) - y₁' t * (y₂ t * g t / W t) = g t := by
      have hw : W t = y₁ t * y₂' t - y₂ t * y₁' t := rfl
      field_simp
      rw [hw]
      ring
    simp only [yp', yp, Pi.neg_apply]
    linear_combination -key

/-- Nothing is lost: under the same conditions, every solution y of the forced equation
y'' + p y' + q y = g on I is the particular solution y_p plus a free motion c₁ y₁ + c₂ y₂,
for some constants c₁ and c₂. -/
theorem every_forced_solution_is_particular_plus_free
    (I : Set ℝ) (hIo : IsOpen I) (hIc : I.OrdConnected) (t₀ : ℝ) (ht₀ : t₀ ∈ I)
    (p q g : ℝ → ℝ) (hp : ContinuousOn p I) (hq : ContinuousOn q I) (hg : ContinuousOn g I)
    (y₁ y₁' y₂ y₂' : ℝ → ℝ)
    (hy₁ : ∀ t ∈ I, HasDerivAt y₁ (y₁' t) t)
    (hy₁' : ∀ t ∈ I, HasDerivAt y₁' (-(p t * y₁' t) - q t * y₁ t) t)
    (hy₂ : ∀ t ∈ I, HasDerivAt y₂ (y₂' t) t)
    (hy₂' : ∀ t ∈ I, HasDerivAt y₂' (-(p t * y₂' t) - q t * y₂ t) t)
    (hW : ∀ t ∈ I, y₁ t * y₂' t - y₂ t * y₁' t ≠ 0)
    (y y' : ℝ → ℝ)
    (hy : ∀ t ∈ I, HasDerivAt y (y' t) t)
    (hy' : ∀ t ∈ I, HasDerivAt y' (g t - p t * y' t - q t * y t) t) :
    ∃ c₁ c₂ : ℝ, ∀ t ∈ I, y t = c₁ * y₁ t + c₂ * y₂ t +
      (-y₁ t * (∫ s in t₀..t, y₂ s * g s / (y₁ s * y₂' s - y₂ s * y₁' s)) +
        y₂ t * (∫ s in t₀..t, y₁ s * g s / (y₁ s * y₂' s - y₂ s * y₁' s))) := by
  obtain ⟨-, -, hP⟩ := variation_of_parameters_solves_forced_equation I hIo hIc t₀ ht₀ p q g
    hp hq hg y₁ y₁' y₂ y₂' hy₁ hy₁' hy₂ hy₂' hW
  set W : ℝ → ℝ := fun t => y₁ t * y₂' t - y₂ t * y₁' t with hWdef
  set yp : ℝ → ℝ := fun t =>
      -y₁ t * (∫ s in t₀..t, y₂ s * g s / W s) + y₂ t * (∫ s in t₀..t, y₁ s * g s / W s)
    with hypdef
  set yp' : ℝ → ℝ := fun t =>
      -y₁' t * (∫ s in t₀..t, y₂ s * g s / W s) + y₂' t * (∫ s in t₀..t, y₁ s * g s / W s)
    with hyp'def
  -- z = y - yp solves the free equation
  set z : ℝ → ℝ := fun t => y t - yp t with hz
  set z' : ℝ → ℝ := fun t => y' t - yp' t with hz'
  have hzd : ∀ t ∈ I, HasDerivAt z (z' t) t := fun t ht => (hy t ht).sub (hP t ht).1
  have hzd' : ∀ t ∈ I, HasDerivAt z' (-(p t * z' t) - q t * z t) t := by
    intro t ht
    convert (hy' t ht).sub (hP t ht).2 using 1
    simp only [z, z']; ring
  -- the coefficients a, b are constant
  set a : ℝ → ℝ := fun t => (z t * y₂' t - z' t * y₂ t) / W t with ha
  set b : ℝ → ℝ := fun t => (z' t * y₁ t - z t * y₁' t) / W t with hb
  have hWd : ∀ t ∈ I, HasDerivAt W (-(p t) * W t) t := by
    intro t ht
    convert ((hy₁ t ht).mul (hy₂' t ht)).sub ((hy₂ t ht).mul (hy₁' t ht)) using 1
    simp only [W]; ring
  have had : ∀ t ∈ I, HasDerivAt a 0 t := by
    intro t ht
    have h := (((hzd t ht).mul (hy₂' t ht)).sub ((hzd' t ht).mul (hy₂ t ht))).div (hWd t ht)
      (hW t ht)
    convert h using 1
    have : W t ≠ 0 := hW t ht
    field_simp
    simp only [Pi.sub_apply, Pi.mul_apply]
    ring
  have hbd : ∀ t ∈ I, HasDerivAt b 0 t := by
    intro t ht
    have h := (((hzd' t ht).mul (hy₁ t ht)).sub ((hzd t ht).mul (hy₁' t ht))).div (hWd t ht)
      (hW t ht)
    convert h using 1
    have : W t ≠ 0 := hW t ht
    field_simp
    simp only [Pi.sub_apply, Pi.mul_apply]
    ring
  have hconst : ∀ (f : ℝ → ℝ), (∀ t ∈ I, HasDerivAt f 0 t) → ∀ t ∈ I, f t = f t₀ := by
    intro f hf t ht
    exact hIo.is_const_of_deriv_eq_zero hIc.isPreconnected
      (fun x hx => (hf x hx).differentiableAt.differentiableWithinAt)
      (fun x hx => (hf x hx).deriv) ht ht₀
  refine ⟨a t₀, b t₀, fun t ht => ?_⟩
  rw [← hconst a had t ht, ← hconst b hbd t ht]
  have hWt : W t ≠ 0 := hW t ht
  have key : y t = z t + yp t := by simp only [z]; ring
  have hzab : z t = a t * y₁ t + b t * y₂ t := by
    simp only [a, b]
    field_simp
    simp only [W]
    ring
  rw [key, hzab]

/-- The cart: for y'' + y = sec t with free pair cos t, sin t (Wronskian 1), on |t| < π/2 the
weights are u₁(t) = ∫₀ᵗ −sin s sec s ds = ln cos t and u₂(t) = ∫₀ᵗ cos s sec s ds = t, and
y_p(t) = cos t ln cos t + t sin t starts at rest at balance and solves y'' + y = sec t. -/
theorem cart_pushed_by_sec_solution :
    let yp : ℝ → ℝ := fun t => Real.cos t * Real.log (Real.cos t) + t * Real.sin t
    let yp' : ℝ → ℝ := fun t => -Real.sin t * Real.log (Real.cos t) + t * Real.cos t
    yp 0 = 0 ∧ yp' 0 = 0 ∧
      ∀ t ∈ Set.Ioo (-(π / 2)) (π / 2),
        (∫ s in (0 : ℝ)..t, -(Real.sin s * (1 / Real.cos s))) = Real.log (Real.cos t) ∧
        (∫ s in (0 : ℝ)..t, Real.cos s * (1 / Real.cos s)) = t ∧
        HasDerivAt yp (yp' t) t ∧ HasDerivAt yp' (1 / Real.cos t - yp t) t := by
  intro yp yp'
  refine ⟨by simp [yp], by simp [yp'], fun t ht => ?_⟩
  have hcos : ∀ s ∈ Set.Ioo (-(π / 2)) (π / 2), Real.cos s ≠ 0 :=
    fun s hs => (Real.cos_pos_of_mem_Ioo hs).ne'
  have hsub : Set.uIcc 0 t ⊆ Set.Ioo (-(π / 2)) (π / 2) :=
    Set.OrdConnected.uIcc_subset Set.ordConnected_Ioo
      ⟨by linarith [Real.pi_pos], by linarith [Real.pi_pos]⟩ ht
  have hct := hcos t ht
  refine ⟨?_, ?_, ?_, ?_⟩
  · have h := intervalIntegral.integral_eq_sub_of_hasDerivAt
      (f := fun s => Real.log (Real.cos s)) (f' := fun s => -(Real.sin s * (1 / Real.cos s)))
      (a := 0) (b := t) ?_ ?_
    · simpa using h
    · intro x hx
      have hx' := hcos x (hsub hx)
      convert ((Real.hasDerivAt_cos x).log hx') using 1
      field_simp
    · apply ContinuousOn.intervalIntegrable
      apply ContinuousOn.neg
      apply Real.continuous_sin.continuousOn.mul
      apply ContinuousOn.div continuousOn_const Real.continuous_cos.continuousOn
      intro x hx; exact hcos x (hsub hx)
  · rw [intervalIntegral.integral_congr (g := fun _ => (1 : ℝ))]
    · simp
    · intro x hx
      have hx' := hcos x (hsub hx)
      field_simp
  · have h := ((Real.hasDerivAt_cos t).mul ((Real.hasDerivAt_cos t).log hct)).add
      ((hasDerivAt_id t).mul (Real.hasDerivAt_sin t))
    convert h using 1
    · rfl
    simp only [yp', id]
    field_simp
    ring
  · have h := (((Real.hasDerivAt_sin t).neg).mul ((Real.hasDerivAt_cos t).log hct)).add
      ((hasDerivAt_id t).mul (Real.hasDerivAt_cos t))
    convert h using 1
    · rfl
    simp only [yp, id, Pi.neg_apply]
    field_simp
    linear_combination (-1 : ℝ) * Real.sin_sq_add_cos_sq t

-- The cart's free pair cos t, sin t has Wronskian cos t · cos t − sin t · (−sin t) = 1.
example (t : ℝ) : Real.cos t * Real.cos t - Real.sin t * (-Real.sin t) = 1 := by
  nlinarith [Real.sin_sq_add_cos_sq t]
-- The rescaled pair 2 cos t, 3 sin t has Wronskian 6.
example (t : ℝ) :
    2 * Real.cos t * (3 * Real.cos t) - 3 * Real.sin t * (-2 * Real.sin t) = 6 := by
  nlinarith [Real.sin_sq_add_cos_sq t]
-- The dependent pair cos t, 2 cos t has Wronskian 0.
example (t : ℝ) : Real.cos t * (-2 * Real.sin t) - 2 * Real.cos t * (-Real.sin t) = 0 := by
  ring
-- The push at t = π/3 is sec(π/3) = 2 N.
example : 1 / Real.cos (π / 3) = 2 := by
  rw [Real.cos_pi_div_three]; norm_num
-- Dropping W with the pair 2 cos t, 3 sin t makes the answer 6 times too big: 2 · 3 = 6.
example : (2 : ℤ) * 3 = 6 := by norm_num

#print axioms variation_of_parameters_solves_forced_equation
#print axioms every_forced_solution_is_particular_plus_free
#print axioms cart_pushed_by_sec_solution
