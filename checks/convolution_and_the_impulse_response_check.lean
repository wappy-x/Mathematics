-- Convolution: for a linear equation with constant coefficients and a continuous input, the solution started at rest is exactly the impulse response convolved with the input, the one-sided Laplace transform turns that convolution into a product, and for the card's car the two worked convolutions come out in closed form.
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Integral.IntegrableOn
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Analysis.Calculus.FDeriv.Partial
import Mathlib.Analysis.Calculus.ParametricIntervalIntegral
import Mathlib.Analysis.Convolution
import Mathlib.Analysis.ODE.ExistUnique
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.MeasureTheory.Integral.ExpDecay
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Tactic

/-! Setting, in the card's notation.
* Signals are functions `ℝ → ℝ` of the time `t`.
* The equation has order `n + 1` and constant coefficients `a 0, …, a n`, leading coefficient 1
  (the card works per unit mass):
  `y⁽ⁿ⁺¹⁾ + a n y⁽ⁿ⁾ + ⋯ + a 0 y = f`, written with Mathlib's `iteratedDeriv`.
  The car is `n = 1`, `a 0 = 5`, `a 1 = 2`.
* "y has n + 1 derivatives" is `∀ k ≤ n, Differentiable ℝ (iteratedDeriv k y)`.
* The impulse response `g` solves the free equation with `g(0) = ⋯ = g⁽ⁿ⁻¹⁾(0) = 0` and
  `g⁽ⁿ⁾(0) = 1` (for the car: height 0, velocity 1 cm/s after the kick).
* "Started at rest" is `y(0) = ⋯ = y⁽ⁿ⁾(0) = 0`.
* The card's convolution `(g * f)(t) = ∫₀ᵗ g(t − τ) f(τ) dτ` is `conv g f t`.
* The one-sided Laplace transform at a real rate `s` is `∫ t in (0, ∞), e^(−st) h(t)`. -/

open MeasureTheory Set

namespace ConvolutionImpulse

/-- The card's convolution: `(g * f)(t) = ∫₀ᵗ g(t − τ) f(τ) dτ`, each earlier push `f(τ)`
weighted by the impulse response at its age `t − τ`. -/
noncomputable def conv (g f : ℝ → ℝ) (t : ℝ) : ℝ :=
  ∫ τ in (0 : ℝ)..t, g (t - τ) * f τ

theorem conv_hasDerivAt (h h' f : ℝ → ℝ) (hh : ∀ x, HasDerivAt h (h' x) x)
    (hh' : Continuous h') (hf : Continuous f) (t : ℝ) :
    HasDerivAt (conv h f) (h 0 * f t + conv h' f t) t := by
  have hc : Continuous h := continuous_iff_continuousAt.2 fun x => (hh x).continuousAt
  let Φ : ℝ → ℝ → ℝ := fun s u => ∫ τ in (0 : ℝ)..s, h (u - τ) * f τ
  let f₁ : ℝ → ℝ → ℝ →L[ℝ] ℝ := fun s u =>
    ContinuousLinearMap.smulRight (1 : ℝ →L[ℝ] ℝ) (h (u - s) * f s)
  let f₂ : ℝ → ℝ → ℝ →L[ℝ] ℝ := fun s u =>
    ContinuousLinearMap.smulRight (1 : ℝ →L[ℝ] ℝ) (∫ τ in (0 : ℝ)..s, h' (u - τ) * f τ)
  have df₁ : ∀ v : ℝ × ℝ, HasFDerivAt (Φ · v.2) (↿f₁ v) v.1 := by
    intro v
    have hcont : Continuous fun τ => h (v.2 - τ) * f τ := by fun_prop
    exact (hcont.integral_hasStrictDerivAt 0 v.1).hasDerivAt.hasFDerivAt
  have df₂ : ∀ v : ℝ × ℝ, HasFDerivAt (Φ v.1 ·) (↿f₂ v) v.2 := by
    intro v
    obtain ⟨C, hC⟩ : ∃ C, ∀ p ∈ (Metric.closedBall v.2 1 ×ˢ uIcc 0 v.1),
        ‖h' (p.1 - p.2) * f p.2‖ ≤ C :=
      ((isCompact_closedBall _ _).prod isCompact_uIcc).exists_bound_of_continuousOn
        (by fun_prop)
    refine HasDerivAt.hasFDerivAt ?_
    refine (intervalIntegral.hasDerivAt_integral_of_dominated_loc_of_deriv_le
      (F := fun u τ => h (u - τ) * f τ) (F' := fun u τ => h' (u - τ) * f τ)
      (bound := fun _ => C) (Metric.closedBall_mem_nhds v.2 one_pos) ?_ ?_ ?_ ?_ ?_ ?_).2
    · exact Filter.Eventually.of_forall fun u => (by fun_prop : Continuous fun τ => h (u - τ) * f τ).aestronglyMeasurable
    · exact (by fun_prop : Continuous fun τ => h (v.2 - τ) * f τ).intervalIntegrable _ _
    · exact (by fun_prop : Continuous fun τ => h' (v.2 - τ) * f τ).aestronglyMeasurable
    · refine Filter.Eventually.of_forall fun τ hτ u hu => hC (u, τ) ⟨hu, uIoc_subset_uIcc hτ⟩
    · exact intervalIntegrable_const
    · refine Filter.Eventually.of_forall fun τ _ u _ => ?_
      have := ((hh (u - τ)).comp u ((hasDerivAt_id u).sub_const τ)).mul_const (f τ)
      simpa using this
  have hsr : Continuous fun c : ℝ => ContinuousLinearMap.smulRight (1 : ℝ →L[ℝ] ℝ) c :=
    (ContinuousLinearMap.smulRightL ℝ ℝ ℝ (1 : ℝ →L[ℝ] ℝ)).continuous
  have cf₁ : Continuous ↿f₁ := by
    have : Continuous fun p : ℝ × ℝ => h (p.2 - p.1) * f p.1 := by fun_prop
    exact hsr.comp this
  have cf₂ : Continuous ↿f₂ := by
    have : Continuous fun p : ℝ × ℝ => ∫ τ in (0 : ℝ)..p.1, h' (p.2 - τ) * f τ :=
      intervalIntegral.continuous_parametric_intervalIntegral_of_continuous
        (f := fun (p : ℝ × ℝ) τ => h' (p.2 - τ) * f τ) (by fun_prop) continuous_fst
    exact hsr.comp this
  have key := hasStrictFDerivAt_uncurry_coprod (u := (t, t)) (f := Φ) (f₁ := f₁) (f₂ := f₂)
    (Filter.Eventually.of_forall df₁) (Filter.Eventually.of_forall df₂) cf₁.continuousAt cf₂.continuousAt
  have hd : HasDerivAt (fun x : ℝ => (x, x)) ((1 : ℝ), (1 : ℝ)) t :=
    (hasDerivAt_id t).prodMk (hasDerivAt_id t)
  have := HasFDerivAt.comp_hasDerivAt (f := fun x : ℝ => (x, x)) t key.hasFDerivAt hd
  convert this using 1
  · rfl
  · simp [f₁, f₂, conv, Function.HasUncurry.uncurry]

#print axioms conv_hasDerivAt

theorem state_hasDerivAt (n : ℕ) (a : Fin (n + 1) → ℝ) (f y : ℝ → ℝ)
    (hy : ∀ k ≤ n, Differentiable ℝ (iteratedDeriv k y))
    (heq : ∀ t, iteratedDeriv (n + 1) y t + ∑ i : Fin (n + 1), a i * iteratedDeriv i y t = f t)
    (t : ℝ) :
    HasDerivAt (fun t (k : Fin (n + 1)) => iteratedDeriv k y t)
      (fun k : Fin (n + 1) => if _hk : (k : ℕ) < n then iteratedDeriv (k + 1) y t
        else f t - ∑ i : Fin (n + 1), a i * iteratedDeriv i y t) t := by
  rw [hasDerivAt_pi]
  intro k
  have hd := ((hy k (by omega)) t).hasDerivAt
  rw [← iteratedDeriv_succ] at hd
  by_cases hk : (k : ℕ) < n
  · simpa [hk] using hd
  · simp only [hk, dite_false]
    have hkn : (k : ℕ) = n := by omega
    rw [hkn] at hd ⊢
    have : f t - ∑ i : Fin (n + 1), a i * iteratedDeriv i y t = iteratedDeriv (n + 1) y t := by
      linarith [heq t]
    rw [this]
    exact hd

#print axioms state_hasDerivAt

theorem system_lipschitz (n : ℕ) (a : Fin (n + 1) → ℝ) (c : ℝ) :
    LipschitzWith (1 + ∑ i, |a i|).toNNReal
      (fun (x : Fin (n + 1) → ℝ) (k : Fin (n + 1)) =>
        if hk : (k : ℕ) < n then x ⟨k + 1, by omega⟩ else c - ∑ i : Fin (n + 1), a i * x i) := by
  refine LipschitzWith.of_dist_le_mul fun x y => ?_
  have hS : 0 ≤ ∑ i, |a i| := by positivity
  rw [dist_pi_le_iff (by positivity)]
  intro k
  rw [Real.coe_toNNReal _ (by positivity)]
  by_cases hk : (k : ℕ) < n
  · simp only [hk, dite_true]
    have := dist_le_pi_dist x y ⟨k + 1, by omega⟩
    have := dist_nonneg (x := x) (y := y)
    nlinarith
  · simp only [hk, dite_false]
    rw [Real.dist_eq]
    have h1 : c - ∑ i, a i * x i - (c - ∑ i, a i * y i) = ∑ i, a i * (y i - x i) := by
      rw [← sub_eq_zero]; simp only [mul_sub, Finset.sum_sub_distrib]; ring
    rw [h1]
    calc |∑ i, a i * (y i - x i)| ≤ ∑ i, |a i * (y i - x i)| := Finset.abs_sum_le_sum_abs _ _
      _ ≤ ∑ i, |a i| * dist x y := by
          apply Finset.sum_le_sum
          intro i _
          rw [abs_mul]
          have := dist_le_pi_dist y x i
          rw [Real.dist_eq, dist_comm] at this
          exact mul_le_mul_of_nonneg_left this (abs_nonneg _)
      _ = (∑ i, |a i|) * dist x y := by rw [Finset.sum_mul]
      _ ≤ (1 + ∑ i, |a i|) * dist x y := by
          have := dist_nonneg (x := x) (y := y); nlinarith

#print axioms system_lipschitz

theorem laplace_integrableOn (f : ℝ → ℝ) (M a s : ℝ)
    (hf_loc : ∀ T > 0, IntegrableOn f (Ioc 0 T))
    (hf_grow : ∀ t ≥ 0, |f t| ≤ M * Real.exp (a * t)) (hs : a < s) :
    IntegrableOn (fun t => Real.exp (-(s * t)) * f t) (Ioi 0) := by
  have hmeas : AEStronglyMeasurable f (volume.restrict (Ioi (0 : ℝ))) := by
    have : Ioi (0 : ℝ) = ⋃ k : ℕ, Ioc 0 ((k : ℝ) + 1) := by
      ext x
      simp only [mem_Ioi, mem_iUnion, mem_Ioc]
      constructor
      · intro hx
        obtain ⟨k, hk⟩ := exists_nat_ge x
        exact ⟨k, hx, by linarith⟩
      · rintro ⟨k, hx, _⟩; exact hx
    rw [this, aestronglyMeasurable_iUnion_iff]
    intro k
    exact (hf_loc _ (by positivity)).aestronglyMeasurable
  have hbound : IntegrableOn (fun t => M * Real.exp (-(s - a) * t)) (Ioi 0) :=
    (exp_neg_integrableOn_Ioi 0 (by linarith)).const_mul M
  refine hbound.mono' ((Real.continuous_exp.comp (by fun_prop)).aestronglyMeasurable.mul hmeas) ?_
  refine (ae_restrict_iff' measurableSet_Ioi).2 (Filter.Eventually.of_forall fun t ht => ?_)
  have ht0 : (0 : ℝ) ≤ t := le_of_lt ht
  rw [norm_mul, Real.norm_eq_abs, Real.abs_exp, Real.norm_eq_abs]
  calc Real.exp (-(s * t)) * |f t| ≤ Real.exp (-(s * t)) * (M * Real.exp (a * t)) :=
        mul_le_mul_of_nonneg_left (hf_grow t ht0) (Real.exp_pos _).le
    _ = M * Real.exp (-(s - a) * t) := by
        rw [mul_left_comm, ← Real.exp_add]; ring_nf

#print axioms laplace_integrableOn

/-- **The response to any input is the impulse response convolved with that input.**
Take a linear equation with constant coefficients,
`y⁽ⁿ⁺¹⁾ + a n y⁽ⁿ⁾ + ⋯ + a 0 y = f`, with a continuous input `f`, and let `g` be its impulse
response: `g` solves the free equation, starts at 0 with its first `n − 1` derivatives 0, and has
`g⁽ⁿ⁾(0) = 1`. Then the convolution `g * f` has `n + 1` derivatives, solves the forced equation at
every time, and starts at rest; and any signal `y` with `n + 1` derivatives solves the forced
equation from rest exactly when `y = g * f` at every time. -/
theorem response_from_rest_is_impulse_response_convolved_with_input
    (n : ℕ) (a : Fin (n + 1) → ℝ) (f g : ℝ → ℝ) (hf : Continuous f)
    (hg_diff : ∀ k ≤ n, Differentiable ℝ (iteratedDeriv k g))
    (hg_free : ∀ t, iteratedDeriv (n + 1) g t + ∑ i : Fin (n + 1), a i * iteratedDeriv i g t = 0)
    (hg_zero : ∀ k < n, iteratedDeriv k g 0 = 0)
    (hg_top : iteratedDeriv n g 0 = 1) :
    ((∀ k ≤ n, Differentiable ℝ (iteratedDeriv k (conv g f))) ∧
      (∀ t, iteratedDeriv (n + 1) (conv g f) t
          + ∑ i : Fin (n + 1), a i * iteratedDeriv i (conv g f) t = f t) ∧
      (∀ k ≤ n, iteratedDeriv k (conv g f) 0 = 0)) ∧
    ∀ y : ℝ → ℝ, (∀ k ≤ n, Differentiable ℝ (iteratedDeriv k y)) →
      (((∀ t, iteratedDeriv (n + 1) y t + ∑ i : Fin (n + 1), a i * iteratedDeriv i y t = f t) ∧
          (∀ k ≤ n, iteratedDeriv k y 0 = 0)) ↔
        ∀ t, y t = conv g f t) := by
  have hgd : ∀ k ≤ n, ∀ x, HasDerivAt (iteratedDeriv k g) (iteratedDeriv (k + 1) g x) x := by
    intro k hk x
    have := ((hg_diff k hk) x).hasDerivAt
    rwa [← iteratedDeriv_succ] at this
  have htop_eq : iteratedDeriv (n + 1) g =
      fun t => -∑ i : Fin (n + 1), a i * iteratedDeriv i g t := by
    funext t; have := hg_free t; linarith
  have hgc : ∀ k ≤ n + 1, Continuous (iteratedDeriv k g) := by
    intro k hk
    rcases Nat.lt_or_ge k (n + 1) with h | h
    · exact (hg_diff k (by omega)).continuous
    · have hk' : k = n + 1 := by omega
      subst hk'
      rw [htop_eq]
      refine Continuous.neg (continuous_finsetSum _ fun i _ => ?_)
      exact continuous_const.mul (hg_diff i (by omega)).continuous
  have hconv : ∀ k ≤ n, ∀ x, HasDerivAt (conv (iteratedDeriv k g) f)
      (iteratedDeriv k g 0 * f x + conv (iteratedDeriv (k + 1) g) f x) x := fun k hk x =>
    conv_hasDerivAt _ _ f (hgd k hk) (hgc (k + 1) (by omega)) hf x
  set F := conv g f with hFdef
  have hF : ∀ k ≤ n, iteratedDeriv k F = conv (iteratedDeriv k g) f := by
    intro k
    induction k with
    | zero => intro _; simp [hFdef]
    | succ k ih =>
      intro hk
      rw [iteratedDeriv_succ, ih (by omega)]
      funext x
      rw [(hconv k (by omega) x).deriv, hg_zero k (by omega)]
      simp
  have hFn : ∀ x, iteratedDeriv (n + 1) F x = f x + conv (iteratedDeriv (n + 1) g) f x := by
    intro x
    rw [iteratedDeriv_succ, hF n le_rfl, (hconv n le_rfl x).deriv, hg_top, one_mul]
  have hcancel : ∀ x, conv (iteratedDeriv (n + 1) g) f x
      + ∑ i : Fin (n + 1), a i * conv (iteratedDeriv i g) f x = 0 := by
    intro x
    have hint : ∀ i : Fin (n + 1), IntervalIntegrable
        (fun τ => a i * (iteratedDeriv i g (x - τ) * f τ)) volume 0 x := by
      intro i
      exact (continuous_const.mul (((hgc i (by omega)).comp (continuous_sub_left x)).mul hf)
        ).intervalIntegrable _ _
    have h1 : conv (iteratedDeriv (n + 1) g) f x =
        -∑ i : Fin (n + 1), a i * conv (iteratedDeriv i g) f x := by
      unfold conv
      rw [htop_eq]
      simp only [Finset.sum_mul, neg_mul]
      rw [intervalIntegral.integral_neg, intervalIntegral.integral_finsetSum (fun i _ => ?_)]
      · congr 1
        refine Finset.sum_congr rfl fun i _ => ?_
        rw [← intervalIntegral.integral_const_mul]
        congr 1; funext τ; ring
      · simpa only [mul_assoc] using hint i
    rw [h1]; ring
  have hode : ∀ t, iteratedDeriv (n + 1) F t
      + ∑ i : Fin (n + 1), a i * iteratedDeriv i F t = f t := by
    intro t
    rw [hFn]
    have : ∑ i : Fin (n + 1), a i * iteratedDeriv i F t
        = ∑ i : Fin (n + 1), a i * conv (iteratedDeriv i g) f t := by
      refine Finset.sum_congr rfl fun i _ => ?_
      rw [hF i (by omega)]
    rw [this]
    linarith [hcancel t]
  have hdiff : ∀ k ≤ n, Differentiable ℝ (iteratedDeriv k F) := by
    intro k hk
    rw [hF k hk]
    exact fun x => (hconv k hk x).differentiableAt
  have hzero : ∀ k ≤ n, iteratedDeriv k F 0 = 0 := by
    intro k hk
    rw [hF k hk]
    simp [conv]
  refine ⟨⟨hdiff, hode, hzero⟩, fun y hy => ⟨fun ⟨hyeq, hy0⟩ => ?_, fun hyF => ?_⟩⟩
  · have hS := ODE_solution_unique_univ (K := (1 + ∑ i, |a i|).toNNReal)
      (v := fun t (x : Fin (n + 1) → ℝ) (k : Fin (n + 1)) =>
        if hk : (k : ℕ) < n then x ⟨k + 1, by omega⟩ else f t - ∑ i : Fin (n + 1), a i * x i)
      (s := fun _ => univ) (t₀ := 0)
      (f := fun t (k : Fin (n + 1)) => iteratedDeriv k y t)
      (g := fun t (k : Fin (n + 1)) => iteratedDeriv k F t)
      (fun t => (system_lipschitz n a (f t)).lipschitzOnWith)
      (fun t => ⟨state_hasDerivAt n a f y hy hyeq t, trivial⟩)
      (fun t => ⟨state_hasDerivAt n a f F hdiff hode t, trivial⟩)
      (by funext k; rw [hy0 k (by omega), hzero k (by omega)])
    intro t
    have := congrFun (congrFun hS t) 0
    simpa using this
  · have : y = F := funext hyF
    subst this
    exact ⟨hode, hzero⟩

/-- **Under the Laplace transform the convolution becomes a plain product** (the detailed
proof). Let `g` and `f` have finite area on every finite stretch `(0, T]` and size at most
`M e^(at)` for `t ≥ 0`. Then at every rate `s > a` the signal `e^(−st) (g * f)(t)` has finite area
on `(0, ∞)`, and the transform of `g * f` is the transform of `g` times the transform of `f`. -/
theorem laplace_transform_of_convolution_is_product
    (f g : ℝ → ℝ) (M a : ℝ)
    (hf_loc : ∀ T > 0, IntegrableOn f (Ioc 0 T))
    (hg_loc : ∀ T > 0, IntegrableOn g (Ioc 0 T))
    (hf_grow : ∀ t ≥ 0, |f t| ≤ M * Real.exp (a * t))
    (hg_grow : ∀ t ≥ 0, |g t| ≤ M * Real.exp (a * t))
    (s : ℝ) (hs : a < s) :
    IntegrableOn (fun t => Real.exp (-(s * t)) * conv g f t) (Ioi 0) ∧
      ∫ t in Ioi (0 : ℝ), Real.exp (-(s * t)) * conv g f t =
        (∫ t in Ioi (0 : ℝ), Real.exp (-(s * t)) * g t) *
          (∫ t in Ioi (0 : ℝ), Real.exp (-(s * t)) * f t) := by
  have hF := laplace_integrableOn f M a s hf_loc hf_grow hs
  have hG := laplace_integrableOn g M a s hg_loc hg_grow hs
  have hrw : (fun t => Real.exp (-(s * t)) * conv g f t) = fun x =>
      ∫ t in (0 : ℝ)..x, ContinuousLinearMap.mul ℝ ℝ (Real.exp (-(s * t)) * f t)
        (Real.exp (-(s * (x - t))) * g (x - t)) := by
    funext x
    unfold conv
    rw [← intervalIntegral.integral_const_mul]
    congr 1
    funext t
    simp only [ContinuousLinearMap.mul_apply']
    have : Real.exp (-(s * x)) = Real.exp (-(s * t)) * Real.exp (-(s * (x - t))) := by
      rw [← Real.exp_add]; ring_nf
    rw [this]; ring
  have hint := integrable_posConvolution hF hG (ContinuousLinearMap.mul ℝ ℝ)
  rw [posConvolution, integrable_indicator_iff measurableSet_Ioi] at hint
  refine ⟨?_, ?_⟩
  · rw [hrw]; exact hint
  · rw [hrw, integral_posConvolution hF hG (ContinuousLinearMap.mul ℝ ℝ)]
    simp only [ContinuousLinearMap.mul_apply']
    ring

/-- **The card's worked convolutions** (Steps 1, 4 and 5). The warm-up:
`e^(−t) * e^(−2t) = e^(−t) − e^(−2t)` at every time. The car `y'' + 2y' + 5y = f`: its impulse
response `g(t) = ½ e^(−t) sin 2t` starts at height 0 with velocity 1 and solves the free equation,
and blended with the steady push `f = 10` it gives `2 − e^(−t)(2 cos 2t + sin 2t)` at every time,
the round-trip answer. -/
theorem car_impulse_response_and_steady_push :
    (∀ t, conv (fun u => Real.exp (-u)) (fun u => Real.exp (-(2 * u))) t =
        Real.exp (-t) - Real.exp (-(2 * t))) ∧
    (let g : ℝ → ℝ := fun t => 1 / 2 * Real.exp (-t) * Real.sin (2 * t)
     g 0 = 0 ∧ deriv g 0 = 1 ∧
       (∀ t, deriv (deriv g) t + 2 * deriv g t + 5 * g t = 0) ∧
       ∀ t, conv g (fun _ => 10) t =
         2 - Real.exp (-t) * (2 * Real.cos (2 * t) + Real.sin (2 * t))) := by
  refine ⟨fun t => ?_, ?_⟩
  · unfold conv
    have hd : ∀ τ, HasDerivAt (fun τ => -(Real.exp (-(t - τ)) * Real.exp (-(2 * τ))))
        (Real.exp (-(t - τ)) * Real.exp (-(2 * τ))) τ := by
      intro τ
      have h1 : HasDerivAt (fun τ => Real.exp (-(t - τ))) (Real.exp (-(t - τ)) * 1) τ := by
        have := ((hasDerivAt_id τ).const_sub t).neg.exp
        convert this using 1 <;> simp
      have h2 : HasDerivAt (fun τ => Real.exp (-(2 * τ))) (Real.exp (-(2 * τ)) * (-2)) τ := by
        have := (((hasDerivAt_id τ).const_mul 2).neg).exp
        convert this using 1 <;> simp
      convert (h1.mul h2).neg using 1
      ring
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun τ _ => hd τ)
      ((by fun_prop : Continuous fun τ => Real.exp (-(t - τ)) * Real.exp (-(2 * τ))).intervalIntegrable _ _)]
    simp
    ring
  · intro g
    have hE : ∀ x : ℝ, HasDerivAt (fun x => Real.exp (-x)) (-Real.exp (-x)) x := by
      intro x
      have := (hasDerivAt_neg x).exp
      convert this using 1; ring
    have hS : ∀ x : ℝ, HasDerivAt (fun x => Real.sin (2 * x)) (2 * Real.cos (2 * x)) x := by
      intro x
      have := ((hasDerivAt_id' x).const_mul 2).sin
      convert this using 1; ring
    have hC : ∀ x : ℝ, HasDerivAt (fun x => Real.cos (2 * x)) (-(2 * Real.sin (2 * x))) x := by
      intro x
      have := ((hasDerivAt_id' x).const_mul 2).cos
      convert this using 1; ring
    have hg1 : ∀ t, HasDerivAt g
        (1 / 2 * (-Real.exp (-t) * Real.sin (2 * t) + 2 * Real.exp (-t) * Real.cos (2 * t))) t := by
      intro t
      have := ((hE t).const_mul (1 / 2 : ℝ)).mul (hS t)
      convert this using 1; ring
    have hdg : deriv g = fun t =>
        1 / 2 * (-Real.exp (-t) * Real.sin (2 * t) + 2 * Real.exp (-t) * Real.cos (2 * t)) :=
      funext fun t => (hg1 t).deriv
    have hg2 : ∀ t, HasDerivAt (deriv g)
        (1 / 2 * (-3 * Real.exp (-t) * Real.sin (2 * t) - 4 * Real.exp (-t) * Real.cos (2 * t))) t := by
      intro t
      rw [hdg]
      have := ((((hE t).neg).mul (hS t)).add (((hE t).const_mul 2).mul (hC t))).const_mul (1 / 2 : ℝ)
      convert this using 1; simp only [Pi.neg_apply]; ring
    refine ⟨by simp [g], by rw [hdg]; simp, fun t => ?_, fun t => ?_⟩
    · rw [(hg2 t).deriv, hdg]
      simp only [g]
      ring
    · unfold conv
      let P : ℝ → ℝ := fun u => Real.exp (-u) * (Real.sin (2 * u) + 2 * Real.cos (2 * u))
      have hP : ∀ u, HasDerivAt P (-(5 * Real.exp (-u) * Real.sin (2 * u))) u := by
        intro u
        have := (hE u).mul ((hS u).add ((hC u).const_mul 2))
        convert this using 1; simp only [Pi.add_apply]; ring
      have hd : ∀ τ, HasDerivAt (fun τ => P (t - τ)) (g (t - τ) * 10) τ := by
        intro τ
        have := (hP (t - τ)).comp τ ((hasDerivAt_id τ).const_sub t)
        refine this.congr_deriv ?_
        simp only [g]; ring
      rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun τ _ => hd τ)
        ((by fun_prop : Continuous fun τ => g (t - τ) * 10).intervalIntegrable _ _)]
      simp only [P, sub_self, sub_zero, neg_zero, Real.exp_zero, mul_zero, Real.sin_zero,
        Real.cos_zero]
      ring

-- The car's polynomial: s² + 2s + 5 = (s + 1)² + 4, so G(s) = 1/((s + 1)² + 4).
example : ∀ s : ℝ, s ^ 2 + 2 * s + 5 = (s + 1) ^ 2 + 4 := by intro s; ring
-- Warm-up transforms at s = 1, both ways: (1/2)(1/3) = 1/2 − 1/3 = 1/6.
example : (1 / 2 : ℚ) * (1 / 3) = 1 / 6 ∧ (1 / 2 : ℚ) - 1 / 3 = 1 / 6 := by norm_num
-- Partial fractions for the warm-up: 1/(s + 1) − 1/(s + 2) = 1/((s + 1)(s + 2)) at s = 1.
example : (1 : ℚ) / (1 + 1) - 1 / (1 + 2) = 1 / ((1 + 1) * (1 + 2)) := by norm_num
-- Long after: P(0) = 5, and the body settles at 10/P(0) = 10/5 = 2 cm.
example : (0 : ℚ) ^ 2 + 2 * 0 + 5 = 5 ∧ (10 : ℚ) / 5 = 2 := by norm_num
-- The steady-push formula starts at rest: 2 − e⁰(2 cos 0 + sin 0) = 2 − 1 × (2 × 1 + 0) = 0.
example : (2 : ℚ) - 1 * (2 * 1 + 0) = 0 := by norm_num
-- The impulse response starts with velocity ½ (2 cos 0 − sin 0) = ½ (2 × 1 − 0) = 1 cm/s.
example : (1 / 2 : ℚ) * (2 * 1 - 0) = 1 := by norm_num
-- Step 5's antiderivative at t = 0 is (2 − 1 × (0 + 2 × 1))/5 = 0, and 5 × (2/5) = 2.
example : ((2 : ℚ) - 1 * (0 + 2 * 1)) / 5 = 0 ∧ (5 : ℚ) * (2 / 5) = 2 := by norm_num

#print axioms response_from_rest_is_impulse_response_convolved_with_input
#print axioms laplace_transform_of_convolution_is_product
#print axioms car_impulse_response_and_steady_push

end ConvolutionImpulse
