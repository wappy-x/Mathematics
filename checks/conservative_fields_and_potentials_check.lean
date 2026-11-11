-- Conservative fields: a field that is the gradient of a potential does work equal to the potential's change along every route inside its region, a potential forces the two cross rates to agree, and the whirlpool round a drain passes that test yet has no potential.
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.MeasureTheory.Integral.DivergenceTheorem
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.FDeriv.Symmetric
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FinCases

open Set

/-- A point of the plane written as a combination of the two unit vectors. -/
lemma vec2_eq (a b : ℝ) : (!₂[a, b] : EuclideanSpace ℝ (Fin 2))
    = a • EuclideanSpace.single 0 1 + b • EuclideanSpace.single 1 1 := by
  ext i; fin_cases i <;> simp

#print axioms vec2_eq

/-- **Work is the potential's change, whatever the route.** Let U be an open, connected region
of n-dimensional space and F a continuous field on U (it does not change with time). Suppose φ
is a potential for F: at every point p of U, the gradient of φ is F(p). Take any route r from
A = r(0) to B = r(1) that stays inside U: r has no jumps on the clock interval [0, 1], and it has
a velocity r'(t) at every clock reading except countably many (such as the corners of
switchbacks), with r' integrable. Then the work of F along the route,
∫ from 0 to 1 of F(r(t)) · r'(t) dt, equals φ(B) − φ(A). -/
theorem work_eq_potential_change {n : ℕ} {U : Set (EuclideanSpace ℝ (Fin n))}
    (hU : IsOpen U) (hUc : IsConnected U)
    {F : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n)} (hF : ContinuousOn F U)
    {φ : EuclideanSpace ℝ (Fin n) → ℝ} (hφ : ∀ p ∈ U, HasGradientAt φ (F p) p)
    {r r' : ℝ → EuclideanSpace ℝ (Fin n)} {A B : EuclideanSpace ℝ (Fin n)}
    (hrA : r 0 = A) (hrB : r 1 = B)
    (hr_in : ∀ t ∈ Icc (0 : ℝ) 1, r t ∈ U) (hr_cont : ContinuousOn r (Icc 0 1))
    {S : Set ℝ} (hS : S.Countable) (hr_deriv : ∀ t ∈ Ioo (0 : ℝ) 1 \ S, HasDerivAt r (r' t) t)
    (hr'_int : IntervalIntegrable r' MeasureTheory.volume 0 1) :
    ∫ t in (0 : ℝ)..1, inner ℝ (F (r t)) (r' t) = φ B - φ A := by
  subst hrA hrB
  have hFr : ContinuousOn (fun t => F (r t)) (Icc 0 1) :=
    hF.comp hr_cont (fun t ht => hr_in t ht)
  have hφr : ContinuousOn (fun t => φ (r t)) (Icc 0 1) := by
    refine ContinuousOn.comp (t := U) ?_ hr_cont (fun t ht => hr_in t ht)
    intro p hp
    exact (hφ p hp).hasFDerivAt.continuousAt.continuousWithinAt
  have hint : IntervalIntegrable (fun t => inner ℝ (F (r t)) (r' t)) MeasureTheory.volume 0 1 := by
    have heq : (fun t => inner ℝ (F (r t)) (r' t))
        = fun t => ∑ i, (F (r t) i) * (EuclideanSpace.proj i : EuclideanSpace ℝ (Fin n) →L[ℝ] ℝ) (r' t) := by
      funext t
      simp [PiLp.inner_apply, mul_comm]
    rw [heq]
    have hsum := IntervalIntegrable.sum (μ := MeasureTheory.volume) (a := 0) (b := 1) Finset.univ
      (f := fun i t => (F (r t) i) * (EuclideanSpace.proj i : EuclideanSpace ℝ (Fin n) →L[ℝ] ℝ) (r' t))
      (fun i _ => ?_)
    · convert hsum using 1
      funext t
      simp [Finset.sum_apply]
    have hi : IntervalIntegrable (fun t => (EuclideanSpace.proj i : EuclideanSpace ℝ (Fin n) →L[ℝ] ℝ) (r' t)) MeasureTheory.volume 0 1 :=
      ⟨(EuclideanSpace.proj (𝕜 := ℝ) (ι := Fin n) i).integrable_comp hr'_int.1,
        (EuclideanSpace.proj (𝕜 := ℝ) (ι := Fin n) i).integrable_comp hr'_int.2⟩
    refine hi.continuousOn_mul ?_
    rw [uIcc_of_le zero_le_one]
    exact (EuclideanSpace.proj i : EuclideanSpace ℝ (Fin n) →L[ℝ] ℝ).continuous.comp_continuousOn hFr
  refine MeasureTheory.integral_eq_of_hasDerivAt_off_countable_of_le (fun t => φ (r t)) _ zero_le_one hS hφr ?_ hint
  intro t ht
  have h1 := HasFDerivAt.comp_hasDerivAt t
    (hφ (r t) (hr_in t (Ioo_subset_Icc_self ht.1))).hasFDerivAt (hr_deriv t ht)
  rw [InnerProductSpace.toDual_apply_apply] at h1
  exact h1

/-- **The test: a potential forces equal cross rates.** Let U be an open region of the plane and
F = (P, Q) a field on U whose parts P and Q have continuous partial rates (P and Q are
continuously differentiable on U). If F has a potential φ on U (the gradient of φ is (P, Q) at
every point of U), then at every point (x, y) of U the upward part's rate going east equals the
east part's rate going up: ∂Q/∂x = ∂P/∂y. So the curl ∂Q/∂x − ∂P/∂y is zero. -/
theorem cross_rates_eq_of_potential {U : Set (EuclideanSpace ℝ (Fin 2))} (hU : IsOpen U)
    {P Q : EuclideanSpace ℝ (Fin 2) → ℝ} (hP : ContDiffOn ℝ 1 P U) (hQ : ContDiffOn ℝ 1 Q U)
    {φ : EuclideanSpace ℝ (Fin 2) → ℝ} (hφ : ∀ p ∈ U, HasGradientAt φ !₂[P p, Q p] p) :
    ∀ x y : ℝ, !₂[x, y] ∈ U →
      deriv (fun s => Q !₂[s, y]) x = deriv (fun s => P !₂[x, s]) y := by
  intro x y hp
  set p : EuclideanSpace ℝ (Fin 2) := !₂[x, y] with hp_def
  set e0 : EuclideanSpace ℝ (Fin 2) := EuclideanSpace.single 0 1
  set e1 : EuclideanSpace ℝ (Fin 2) := EuclideanSpace.single 1 1
  have hPd : HasFDerivAt P (fderiv ℝ P p) p :=
    ((hP.differentiableOn one_ne_zero).differentiableAt (hU.mem_nhds hp)).hasFDerivAt
  have hQd : HasFDerivAt Q (fderiv ℝ Q p) p :=
    ((hQ.differentiableOn one_ne_zero).differentiableAt (hU.mem_nhds hp)).hasFDerivAt
  let G : EuclideanSpace ℝ (Fin 2) → EuclideanSpace ℝ (Fin 2) := fun q => P q • e0 + Q q • e1
  have hGd : HasFDerivAt G ((fderiv ℝ P p).smulRight e0 + (fderiv ℝ Q p).smulRight e1) p :=
    (hPd.smul_const e0).add (hQd.smul_const e1)
  let f' : EuclideanSpace ℝ (Fin 2) → EuclideanSpace ℝ (Fin 2) →L[ℝ] ℝ :=
    fun q => innerSL ℝ (G q)
  have hev : ∀ᶠ q in nhds p, HasFDerivAt φ (f' q) q := by
    filter_upwards [hU.mem_nhds hp] with q hq
    have h := (hφ q hq).hasFDerivAt
    convert h using 1
    ext v
    simp [f', G, e0, e1, vec2_eq]
  have hf' : HasFDerivAt f' ((innerSL ℝ).comp
      ((fderiv ℝ P p).smulRight e0 + (fderiv ℝ Q p).smulRight e1)) p :=
    (innerSL ℝ).hasFDerivAt.comp p hGd
  have hsym := second_derivative_symmetric_of_eventually hev hf' e0 e1
  have hL : deriv (fun s => Q !₂[s, y]) x = fderiv ℝ Q p e0 := by
    have hc : HasDerivAt (fun s : ℝ => s • e0 + y • e1) e0 x := by
      simpa using ((hasDerivAt_id x).smul_const e0).add_const (y • e1)
    have hQd' : HasFDerivAt Q (fderiv ℝ Q p) (x • e0 + y • e1) := by
      rw [← vec2_eq]; exact hQd
    have := (hQd'.comp_hasDerivAt x hc).deriv
    simpa [Function.comp_def, vec2_eq, e0, e1] using this
  have hR : deriv (fun s => P !₂[x, s]) y = fderiv ℝ P p e1 := by
    have hc : HasDerivAt (fun s : ℝ => x • e0 + s • e1) e1 y := by
      simpa using ((hasDerivAt_id y).smul_const e1).const_add (x • e0)
    have hPd' : HasFDerivAt P (fderiv ℝ P p) (x • e0 + y • e1) := by
      rw [← vec2_eq]; exact hPd
    have := (hPd'.comp_hasDerivAt y hc).deriv
    simpa [Function.comp_def, vec2_eq, e0, e1] using this
  rw [hL, hR]
  simp [e0, e1, EuclideanSpace.inner_single_left] at hsym
  linarith

/-- **The hole that breaks the test.** The whirlpool round a drain at the origin has velocity
F(x, y) = (−y, x)/(x^2 + y^2), defined everywhere except the drain. Wherever it is defined its
two cross rates agree (∂Q/∂x = ∂P/∂y, zero curl), yet no single function φ on the plane with the
drain removed has F as its gradient: one lap round the drain adds 2π, so no potential exists. -/
theorem whirlpool_zero_curl_and_no_potential :
    (∀ x y : ℝ, (x, y) ≠ (0, 0) →
      deriv (fun s => s / (s ^ 2 + y ^ 2)) x = deriv (fun s => -s / (x ^ 2 + s ^ 2)) y) ∧
    ¬ ∃ φ : EuclideanSpace ℝ (Fin 2) → ℝ, ∀ p : EuclideanSpace ℝ (Fin 2), p ≠ 0 →
      HasGradientAt φ !₂[-p 1 / (p 0 ^ 2 + p 1 ^ 2), p 0 / (p 0 ^ 2 + p 1 ^ 2)] p := by
  constructor
  · intro x y hxy
    have hne : x ^ 2 + y ^ 2 ≠ 0 := by
      intro h
      apply hxy
      have hx : x = 0 := by nlinarith [sq_nonneg x, sq_nonneg y]
      have hy : y = 0 := by nlinarith [sq_nonneg x, sq_nonneg y]
      simp [hx, hy]
    have h1 := (hasDerivAt_id x).div ((hasDerivAt_pow 2 x).add_const (y ^ 2)) hne
    have h2 := ((hasDerivAt_id y).neg).div ((hasDerivAt_pow 2 y).const_add (x ^ 2)) hne
    rw [show deriv (fun s => s / (s ^ 2 + y ^ 2)) x = deriv (id / fun s => s ^ 2 + y ^ 2) x
        from rfl, h1.deriv,
      show deriv (fun s => -s / (x ^ 2 + s ^ 2)) y = deriv (-id / fun s => x ^ 2 + s ^ 2) y
        from rfl, h2.deriv]
    norm_num
    field_simp
    ring
  · rintro ⟨φ, hφ⟩
    set e0 : EuclideanSpace ℝ (Fin 2) := EuclideanSpace.single 0 1
    set e1 : EuclideanSpace ℝ (Fin 2) := EuclideanSpace.single 1 1
    let r : ℝ → EuclideanSpace ℝ (Fin 2) := fun t =>
      Real.cos (2 * Real.pi * t) • e0 + Real.sin (2 * Real.pi * t) • e1
    let r' : ℝ → EuclideanSpace ℝ (Fin 2) := fun t =>
      (-Real.sin (2 * Real.pi * t) * (2 * Real.pi)) • e0
        + (Real.cos (2 * Real.pi * t) * (2 * Real.pi)) • e1
    have hr0 : ∀ t, r t 0 = Real.cos (2 * Real.pi * t) := by intro t; simp [r, e0, e1]
    have hr1 : ∀ t, r t 1 = Real.sin (2 * Real.pi * t) := by intro t; simp [r, e0, e1]
    have hr : ∀ t, HasDerivAt r (r' t) t := by
      intro t
      have hg : HasDerivAt (fun t : ℝ => 2 * Real.pi * t) (2 * Real.pi) t := by
        simpa using (hasDerivAt_id t).const_mul (2 * Real.pi)
      exact (hg.cos.smul_const e0).add (hg.sin.smul_const e1)
    have hd : ∀ t, HasDerivAt (fun t => φ (r t)) (2 * Real.pi) t := by
      intro t
      have hs := Real.cos_sq_add_sin_sq (2 * Real.pi * t)
      have hne : r t ≠ 0 := by
        intro h
        have a := hr0 t
        have b := hr1 t
        rw [h] at a b
        simp at a b
        rw [← a, ← b] at hs
        norm_num at hs
      have h := HasFDerivAt.comp_hasDerivAt t (hφ (r t) hne).hasFDerivAt (hr t)
      rw [InnerProductSpace.toDual_apply_apply] at h
      show HasDerivAt (φ ∘ r) _ t
      convert h using 1
      rw [hr0, hr1, hs]
      simp [r', e0, e1, PiLp.inner_apply, Fin.sum_univ_two]
      linear_combination (-2 * Real.pi) * hs
    have hconst : ∀ t, φ (r t) - 2 * Real.pi * t = φ (r 0) - 2 * Real.pi * 0 := by
      intro t
      have hdiff : Differentiable ℝ (fun t => φ (r t) - 2 * Real.pi * t) := fun t =>
        ((hd t).sub ((hasDerivAt_id t).const_mul (2 * Real.pi))).differentiableAt
      have hz : ∀ t, deriv (fun t => φ (r t) - 2 * Real.pi * t) t = 0 := by
        intro t
        have : HasDerivAt (fun t => φ (r t) - 2 * Real.pi * t) 0 t := by
          convert (hd t).sub ((hasDerivAt_id t).const_mul (2 * Real.pi)) using 1
          all_goals first | rfl | ring
        exact this.deriv
      exact is_const_of_deriv_eq_zero hdiff hz t 0
    have h1 := hconst 1
    have hr10 : r 1 = r 0 := by simp [r]
    rw [hr10] at h1
    linarith [Real.pi_pos]

-- Gravity on the 2 kg bottle: 2 kg × 9.8 m/s^2 = 19.6 N (9.8 = 98/10, 19.6 = 196/10).
example : (2 : ℚ) * (98 / 10) = 196 / 10 := by norm_num
-- Work from A (0, 0) to B (400, 300) with φ = −19.6 y: φ(B) − φ(A) = −19.6 × 300 − 0 = −5880 J.
example : -(196 / 10 : ℚ) * 300 - (-(196 / 10) * 0) = -5880 := by norm_num
-- Three switchbacks, each climbing 100 m: 3 × (−19.6 × 100) = −5880 J, the same as straight up.
example : 3 * (-(196 / 10 : ℚ) * 100) = -5880 := by norm_num
-- Potential energy U = −φ used by mistake: +19.6 × 300 = +5880 J, the wrong sign.
example : (196 / 10 : ℚ) * 300 = 5880 := by norm_num
-- The whirlpool's cross rate at (1, 2): (y^2 − x^2)/(x^2 + y^2)^2 = (4 − 1)/25 = 3/25 = 0.12.
example : ((2 : ℚ) ^ 2 - 1 ^ 2) / (1 ^ 2 + 2 ^ 2) ^ 2 = 3 / 25 := by norm_num
-- The planet, per kg, with k = gR^2: from R to 2R the work is k/2R − k/R = −gR/2.
example : ∀ g R : ℚ, R ≠ 0 → g * R ^ 2 / (2 * R) - g * R ^ 2 / R = -(g * R / 2) := by
  intro g R hR; field_simp; ring
-- Using g h for a climb of h = R gives −gR, twice the true −gR/2.
example : ∀ g R : ℚ, -(g * R) = 2 * (-(g * R / 2)) := by intro g R; ring

#print axioms work_eq_potential_change
#print axioms cross_rates_eq_of_potential
#print axioms whirlpool_zero_curl_and_no_potential
