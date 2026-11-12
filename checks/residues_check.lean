-- Residues: a small loop round an isolated bad point returns 2πi times the coefficient of 1/(z - a) in the function's series there, and that coefficient is also given by a derivative limit at a pole of order m and by p(a)/q'(a) when p and q are analytic at a with q(a) = 0 and q'(a) ≠ 0.
import Mathlib.MeasureTheory.Integral.CircleIntegral
import Mathlib.Analysis.Complex.CauchyIntegral
import Mathlib.Analysis.Analytic.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Tactic.NormNum
import Mathlib

/-! The plane is `ℂ`; `I` is i. `Metric.ball a R \ {a}` is the punctured disc `0 < |z - a| < R`
round the bad point `a`. `∮ z in C(a, r), f z` is the integral of `f` once anticlockwise round
the circle `|z - a| = r`. `HasSum (fun n : ℤ ↦ c n * (z - a) ^ n) (f z)` says the two-sided
series `∑ c n (z - a)ⁿ`, over every whole number `n`, adds up to `f z`. `iteratedDeriv k g z`
is the `k`-th complex derivative of `g` at `z`, and `𝓝[≠] a` means "as `z` arrives at `a`,
never equal to `a`". -/

open Complex Real Filter Topology Metric

lemma laurent_aux {f : ℂ → ℂ} {a : ℂ} {R : ℝ} {c : ℤ → ℂ}
    (hc : ∀ z ∈ ball a R \ {a}, HasSum (fun n : ℤ ↦ c n * (z - a) ^ n) (f z))
    {r : ℝ} (hr : 0 < r) (hrR : r < R) :
    (∮ z in C(a, r), f z) = c (-1) * (2 * π * I) := by
  have hmem : ∀ θ : ℝ, circleMap a r θ ∈ ball a R \ {a} := by
    intro θ
    refine ⟨?_, ?_⟩
    · rw [mem_ball, dist_eq_norm, circleMap_sub_center, norm_circleMap_zero, abs_of_pos hr]
      exact hrR
    · exact circleMap_ne_center hr.ne'
  have hsum0 : Summable (fun n : ℤ ↦ ‖c n‖ * r ^ n) := by
    have h := (hc _ (hmem 0)).summable
    rw [← summable_norm_iff] at h
    refine h.congr fun n => ?_
    rw [norm_mul, norm_zpow, circleMap_sub_center, norm_circleMap_zero, abs_of_pos hr]
  have key : HasSum (fun n : ℤ ↦ ∫ θ in (0:ℝ)..2 * π,
      deriv (circleMap a r) θ • (c n * (circleMap a r θ - a) ^ n))
      (∫ θ in (0:ℝ)..2 * π, deriv (circleMap a r) θ • f (circleMap a r θ)) := by
    refine intervalIntegral.hasSum_integral_of_dominated_convergence
      (fun n _ => ‖c n‖ * r ^ n * r) (fun n => ?_) (fun n => ?_) ?_ ?_ ?_
    · apply Continuous.aestronglyMeasurable
      simp only [deriv_circleMap, circleMap_sub_center]
      refine ((continuous_circleMap 0 r).mul continuous_const).smul (continuous_const.mul ?_)
      exact (continuous_circleMap 0 r).zpow₀ n fun θ => Or.inl (circleMap_ne_center hr.ne')
    · refine Eventually.of_forall fun θ _ => le_of_eq ?_
      simp only [deriv_circleMap, circleMap_sub_center, smul_eq_mul, norm_mul, norm_zpow,
        norm_circleMap_zero, abs_of_pos hr, norm_I]
      ring
    · exact Eventually.of_forall fun θ _ => hsum0.mul_right r
    · exact intervalIntegrable_const
    · refine Eventually.of_forall fun θ _ => ?_
      exact (hc _ (hmem θ)).const_smul (deriv (circleMap a r) θ)
  have key2 : HasSum (fun n : ℤ ↦ c n * ∮ z in C(a, r), (z - a) ^ n) (∮ z in C(a, r), f z) := by
    convert key using 1
    swap; · rfl
    funext n
    rw [← circleIntegral.integral_const_mul]
    rfl
  have key3 : HasSum (fun n : ℤ ↦ c n * ∮ z in C(a, r), (z - a) ^ n) (c (-1) * (2 * π * I)) := by
    convert hasSum_single (-1 : ℤ) (fun n hn => ?_) using 1
    · simp [circleIntegral.integral_sub_center_inv a hr.ne']
    · simp [circleIntegral.integral_sub_zpow_of_ne hn]
  exact key2.unique key3

#print axioms laurent_aux

lemma pole_integral_aux {f H : ℂ → ℂ} {a : ℂ} {R : ℝ} {m : ℕ}
    (hm : 1 ≤ m) (hH : DifferentiableOn ℂ H (ball a R))
    (hHf : ∀ z ∈ ball a R \ {a}, H z = (z - a) ^ m * f z)
    {r : ℝ} (hr : 0 < r) (hrR : r < R) :
    (∮ z in C(a, r), f z) = (2 * π * I / (m - 1).factorial) * iteratedDeriv (m - 1) H a := by
  have hcl : closedBall a r ⊆ ball a R := closedBall_subset_ball hrR
  have h := (hH.mono hcl).circleIntegral_one_div_sub_center_pow_smul hr (m - 1)
  rw [Nat.sub_add_cancel hm, smul_eq_mul] at h
  rw [← h]
  refine circleIntegral.integral_congr hr.le fun z hz => ?_
  have hz' : z ∈ ball a R \ {a} := by
    refine ⟨hcl (sphere_subset_closedBall hz), ?_⟩
    intro h0
    rw [Set.mem_singleton_iff] at h0
    subst h0
    simp at hz
    linarith
  have hza : z - a ≠ 0 := sub_ne_zero.mpr hz'.2
  simp only [smul_eq_mul, hHf z hz']
  field_simp

#print axioms pole_integral_aux

lemma iterDeriv_cont_aux {H : ℂ → ℂ} {s : Set ℂ} (hs : IsOpen s) (hH : DifferentiableOn ℂ H s)
    (k : ℕ) : DifferentiableOn ℂ (iteratedDeriv k H) s := by
  induction k with
  | zero => simpa using hH
  | succ k ih => rw [iteratedDeriv_succ]; exact ih.deriv hs

#print axioms iterDeriv_cont_aux

lemma div_aux {p q : ℂ → ℂ} {a : ℂ} {R : ℝ}
    (hp : DifferentiableOn ℂ p (ball a R)) (hq : DifferentiableOn ℂ q (ball a R))
    (hqa : q a = 0) (hq' : deriv q a ≠ 0) (hq0 : ∀ z ∈ ball a R \ {a}, q z ≠ 0)
    (hRpos : 0 < R) :
    Tendsto (fun z ↦ (z - a) * (p z / q z)) (𝓝[≠] a) (𝓝 (p a / deriv q a)) ∧
    ∀ r : ℝ, 0 < r → r < R →
      (2 * π * I)⁻¹ * (∮ z in C(a, r), p z / q z) = p a / deriv q a := by
  set H : ℂ → ℂ := fun z => p z / dslope q a z with hHdef
  have hslope : ∀ z ∈ ball a R \ {a}, dslope q a z = q z / (z - a) := by
    intro z hz
    rw [dslope_of_ne _ hz.2, slope_def_field, hqa, sub_zero]
  have hne : ∀ z ∈ ball a R, dslope q a z ≠ 0 := by
    intro z hz
    by_cases h : z = a
    · subst h; rw [dslope_same]; exact hq'
    · have hz' : z ∈ ball a R \ {a} := ⟨hz, h⟩
      rw [hslope z hz']
      exact div_ne_zero (hq0 z hz') (sub_ne_zero.mpr h)
  have hHf : ∀ z ∈ ball a R \ {a}, H z = (z - a) ^ 1 * (p z / q z) := by
    intro z hz
    have hza : z - a ≠ 0 := sub_ne_zero.mpr hz.2
    have := hq0 z hz
    simp only [hHdef, hslope z hz]
    field_simp
  have hR : 0 < R ∨ R ≤ 0 := Or.inl hRpos
  have hH : DifferentiableOn ℂ H (ball a R) :=
    hp.div (by
      rcases hR with hR | hR
      · exact (Complex.differentiableOn_dslope (isOpen_ball.mem_nhds (mem_ball_self hR))).mpr hq
      · rw [ball_eq_empty.mpr hR]; exact differentiableOn_empty) hne
  have hHa : H a = p a / deriv q a := by simp [hHdef, dslope_same]
  constructor
  · rcases hR with hR | hR
    · rw [← hHa]
      have hcont : ContinuousAt H a :=
        (hH.differentiableAt (isOpen_ball.mem_nhds (mem_ball_self hR))).continuousAt
      refine (hcont.tendsto.mono_left nhdsWithin_le_nhds).congr' ?_
      have hev : ∀ᶠ z in 𝓝[≠] a, z ∈ ball a R \ {a} :=
            by
          filter_upwards [self_mem_nhdsWithin,
            nhdsWithin_le_nhds (isOpen_ball.mem_nhds (mem_ball_self hR))] with z h1 h2
          exact ⟨h2, h1⟩
      filter_upwards [hev] with z hz
      rw [hHf z hz, pow_one]
    · exact absurd hRpos (not_lt.mpr hR)
  · intro r hr hrR
    rw [pole_integral_aux le_rfl hH hHf hr hrR]
    have : (2 * π * I : ℂ) ≠ 0 := two_pi_I_ne_zero
    simp only [Nat.sub_self, Nat.factorial_zero, Nat.cast_one, div_one, iteratedDeriv_zero]
    rw [hHa]
    field_simp

#print axioms div_aux

/-- **The residue is the one coefficient a loop does not cancel.** Let `f` be holomorphic (have
a complex derivative) on the punctured disc `0 < |z - a| < R`, so `a` is an isolated bad point,
and let `f(z) = ∑ c n (z - a)ⁿ` be its series there, negative powers included. Then for every
loop radius `r` with `0 < r < R`, the loop integral divided by `2πi` is `c (-1)`, the
coefficient of `1/(z - a)`: `Res(f, a) = c₋₁ = (1/2πi) ∮_{|z - a| = r} f(z) dz`. -/
theorem residue_eq_laurent_coeff_neg_one {f : ℂ → ℂ} {a : ℂ} {R : ℝ}
    (hf : DifferentiableOn ℂ f (ball a R \ {a})) {c : ℤ → ℂ}
    (hc : ∀ z ∈ ball a R \ {a}, HasSum (fun n : ℤ ↦ c n * (z - a) ^ n) (f z))
    {r : ℝ} (hr : 0 < r) (hrR : r < R) :
    (2 * π * I)⁻¹ * (∮ z in C(a, r), f z) = c (-1) := by
  rw [laurent_aux hc hr hrR]
  field_simp [two_pi_I_ne_zero]

/-- **At a pole of order m: cancel m factors, differentiate m − 1 times, take the limit.**
Let `f` be holomorphic on the punctured disc `0 < |z - a| < R`, and let `m ≥ 1` be at least the
true order of the pole: the tamed factor `(z - a)^m f(z)` extends to a function `H` holomorphic
on the whole disc. Then the residue (the small loop's integral divided by `2πi`) is
`(1/(m - 1)!) lim_{z → a} d^(m-1)/dz^(m-1) [(z - a)^m f(z)]`. With `m = 1` this is the
simple-pole limit `lim_{z → a} (z - a) f(z)`. -/
theorem residue_eq_lim_iteratedDeriv_div_factorial {f H : ℂ → ℂ} {a : ℂ} {R : ℝ} {m : ℕ}
    (hm : 1 ≤ m) (hf : DifferentiableOn ℂ f (ball a R \ {a}))
    (hH : DifferentiableOn ℂ H (ball a R))
    (hHf : ∀ z ∈ ball a R \ {a}, H z = (z - a) ^ m * f z)
    {r : ℝ} (hr : 0 < r) (hrR : r < R) :
    Tendsto (fun z ↦ iteratedDeriv (m - 1) (fun w ↦ (w - a) ^ m * f w) z / (m - 1).factorial)
      (𝓝[≠] a) (𝓝 ((2 * π * I)⁻¹ * (∮ z in C(a, r), f z))) := by
  rw [pole_integral_aux hm hH hHf hr hrR]
  have hR : 0 < R := hr.trans hrR
  have hval : (2 * π * I)⁻¹ * (2 * π * I / (m - 1).factorial * iteratedDeriv (m - 1) H a)
      = iteratedDeriv (m - 1) H a / (m - 1).factorial := by
    have : (2 * π * I : ℂ) ≠ 0 := two_pi_I_ne_zero
    have : ((m - 1).factorial : ℂ) ≠ 0 := by exact_mod_cast (m - 1).factorial_ne_zero
    field_simp
  rw [hval]
  have hcont : ContinuousAt (iteratedDeriv (m - 1) H) a :=
    ((iterDeriv_cont_aux isOpen_ball hH (m - 1)).differentiableAt
      (isOpen_ball.mem_nhds (mem_ball_self hR))).continuousAt
  refine ((hcont.tendsto.mono_left nhdsWithin_le_nhds).div_const _).congr' ?_
  have hev : ∀ᶠ z in 𝓝[≠] a, z ∈ ball a R \ {a} :=
    by
      filter_upwards [self_mem_nhdsWithin,
        nhdsWithin_le_nhds (isOpen_ball.mem_nhds (mem_ball_self hR))] with z h1 h2
      exact ⟨h2, h1⟩
  filter_upwards [hev] with z hz
  congr 1
  refine Filter.EventuallyEq.iteratedDeriv_eq _ ?_
  filter_upwards [(isOpen_ball.sdiff isClosed_singleton).mem_nhds hz] with w hw
  exact hHf w hw

/-- **At a simple pole of a fraction: top at a over the bottom's slope at a.** Let `p` and `q`
be analytic at `a` (each is its own convergent power series near `a`), with `q(a) = 0` and
`q'(a) ≠ 0`, so `f = p/q` has a simple pole (or no pole, if `p(a) = 0`) at `a`. Then the
simple-pole limit `(z - a) f(z)` tends to `p(a)/q'(a)` as `z` arrives at `a`, and every small
enough loop round `a` gives `(1/2πi) ∮ p/q = p(a)/q'(a)`: `Res(p/q, a) = p(a)/q'(a)`. -/
theorem residue_of_div_eq_div_deriv {p q : ℂ → ℂ} {a : ℂ}
    (hp : AnalyticAt ℂ p a) (hq : AnalyticAt ℂ q a) (hqa : q a = 0) (hq' : deriv q a ≠ 0) :
    Tendsto (fun z ↦ (z - a) * (p z / q z)) (𝓝[≠] a) (𝓝 (p a / deriv q a)) ∧
    ∀ᶠ r in 𝓝[>] (0 : ℝ), (2 * π * I)⁻¹ * (∮ z in C(a, r), p z / q z) = p a / deriv q a := by
  have hd : HasDerivAt q (deriv q a) a := hq.differentiableAt.hasDerivAt
  have h1 : ∀ᶠ z in 𝓝 a, z ≠ a → q z ≠ 0 := by
    have := hd.eventually_ne (c := (0 : ℂ)) hq'
    rwa [eventually_nhdsWithin_iff] at this
  obtain ⟨R, hR, hRprop⟩ := Metric.eventually_nhds_iff_ball.mp
    (h1.and (hp.eventually_analyticAt.and hq.eventually_analyticAt))
  have hpd : DifferentiableOn ℂ p (ball a R) := fun z hz =>
    (hRprop z hz).2.1.differentiableAt.differentiableWithinAt
  have hqd : DifferentiableOn ℂ q (ball a R) := fun z hz =>
    (hRprop z hz).2.2.differentiableAt.differentiableWithinAt
  have hq0 : ∀ z ∈ ball a R \ {a}, q z ≠ 0 := fun z hz => (hRprop z hz.1).1 hz.2
  have key := div_aux hpd hqd hqa hq' hq0 hR
  refine ⟨key.1, ?_⟩
  filter_upwards [Ioo_mem_nhdsGT hR] with r hr
  exact key.2 r hr.1 hr.2

/-! ### The card's worked numbers -/

-- The booth at i: the loop of radius 1/2 round i pays π for 1/(z^2 + 1).
example : (∮ z in C(I, (1 / 2 : ℝ)), (1 : ℂ) / (z ^ 2 + 1)) = (π : ℂ) := by
  have hd : HasDerivAt (fun z : ℂ => z ^ 2 + 1) (2 * I) I := by
    simpa using (hasDerivAt_pow 2 I).add_const (1 : ℂ)
  have h := (div_aux (p := fun _ => (1 : ℂ)) (q := fun z => z ^ 2 + 1)
    (a := I) (R := 1) (differentiableOn_const _) (by fun_prop) (by simp)
    (by rw [hd.deriv]; simp [I_ne_zero]) (by
      intro z hz hq
      have h1 : (z - I) * (z + I) = 0 := by
        have : z ^ 2 + 1 = (z - I) * (z + I) := by ring_nf; rw [I_sq]; ring
        rw [← this]; exact hq
      rcases mul_eq_zero.mp h1 with h2 | h2
      · exact hz.2 (sub_eq_zero.mp h2)
      · have : z = -I := eq_neg_of_add_eq_zero_left h2
        have hb := hz.1
        rw [this, mem_ball, dist_eq_norm] at hb
        have : -I - I = -(2 * I) := by ring
        rw [this, norm_neg, norm_mul, norm_I] at hb
        norm_num at hb) one_pos).2 (1 / 2) (by norm_num) (by norm_num)
  rw [hd.deriv] at h
  have h2 : (2 * π * I : ℂ) ≠ 0 := two_pi_I_ne_zero
  have hπ : (π : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
  field_simp at h
  exact h

-- The booth at 0 for e^z/z^3: the loop of radius 1 gives residue 1/2.
example : (2 * π * I)⁻¹ * (∮ z in C((0 : ℂ), 1), Complex.exp z / z ^ 3) = 1 / 2 := by
  rw [pole_integral_aux (H := Complex.exp) (R := 2) (m := 3) (by norm_num)
    Complex.differentiable_exp.differentiableOn (by
      intro z hz
      have : z ≠ 0 := hz.2
      field_simp; ring) one_pos (by norm_num)]
  rw [iteratedDeriv_eq_iterate, Complex.iter_deriv_exp]
  have h2 : (2 * π * I : ℂ) ≠ 0 := two_pi_I_ne_zero
  norm_num [Nat.factorial]
  field_simp
  rw [I_sq]; ring

-- p/q' for 1/(z^2 + 1): q' = 2z, so 1/(2i) = −i/2 at i and 1/(−2i) = i/2 at −i.
example : (1 : ℂ) / (2 * I) = -I / 2 := by
  field_simp; rw [I_sq]; ring
example : (1 : ℂ) / (-2 * I) = I / 2 := by
  field_simp; rw [I_sq]

-- The toll: 2πi × (−i/2) = π. A loop round both booths: −i/2 + i/2 = 0.
example : 2 * (π : ℂ) * I * (-I / 2) = π := by
  ring_nf; rw [I_sq]; ring
example : -I / 2 + I / 2 = 0 := by
  ring

-- e^z/z^3: m = 3, H''(0) = 1, divided by (m − 1)! = 2! = 2 gives 1/2.
example : (1 : ℚ) / (Nat.factorial (3 - 1)) = 1 / 2 := by
  norm_num [Nat.factorial]

-- z e^(1/z): the only 1/z term is z × 1/(2! z^2), coefficient 1/2! = 1/2.
example : (1 : ℚ) / (Nat.factorial 2) = 1 / 2 := by
  norm_num [Nat.factorial]

#print axioms residue_eq_laurent_coeff_neg_one
#print axioms residue_eq_lim_iteratedDeriv_div_factorial
#print axioms residue_of_div_eq_div_deriv
