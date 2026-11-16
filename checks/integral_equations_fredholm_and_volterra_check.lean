-- Integral equations: a classical sag solves the ponding boundary problem exactly when it solves the Fredholm equation with the tent kernel, it solves the problem started from one end exactly when it solves the Volterra equation, and below λ = π² the cosine formula is a solution.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.MeanValue

open Real Set

noncomputable section

/-- The wing 08 tent `G(x, y) = min(x, y) (1 − max(x, y))` on the 1 m span: the sag at `x`
from a unit load at `y`, with both ends held at 0. It is the kernel `K(x, y)` here. -/
def greenKernel (x y : ℝ) : ℝ := min x y * (1 - max x y)

/-- The rain-alone sag `f(x) = λ h₀ x (1 − x) / 2`. -/
def rainSag (lam h0 x : ℝ) : ℝ := lam * h0 * x * (1 - x) / 2

/-- The card's closed form for the ponded sag,
`u(x) = h₀ (cos(√λ (x − ½)) / cos(√λ / 2) − 1)`. -/
def pondedSag (lam h0 x : ℝ) : ℝ := h0 * (Real.cos (√lam * (x - 1 / 2)) / Real.cos (√lam / 2) - 1)

lemma deriv_eqOn_of_eqOn_Icc {u V W : ℝ → ℝ} (hu : Differentiable ℝ u)
    (heq : EqOn u V (Icc 0 1)) (hV : ∀ x, HasDerivAt V (W x) x) :
    EqOn (deriv u) W (Icc 0 1) := by
  intro x hx
  have h1 : HasDerivWithinAt u (W x) (Icc 0 1) x :=
    (hV x).hasDerivWithinAt.congr heq (heq hx)
  have h2 : HasDerivWithinAt u (deriv u x) (Icc 0 1) x := (hu x).hasDerivAt.hasDerivWithinAt
  exact (uniqueDiffOn_Icc zero_lt_one x hx).eq_deriv _ h2 h1

#print axioms deriv_eqOn_of_eqOn_Icc

lemma affine_of_deriv2_zero {w w' : ℝ → ℝ} (hw : ∀ x, HasDerivAt w (w' x) x)
    (hw' : ∀ x ∈ Icc (0:ℝ) 1, HasDerivAt w' 0 x) :
    ∀ x ∈ Icc (0:ℝ) 1, w x = w 0 + w' 0 * x := by
  have hc : ∀ x ∈ Icc (0:ℝ) 1, w' x = w' 0 :=
    constant_of_has_deriv_right_zero
      (fun x hx => (hw' x hx).continuousAt.continuousWithinAt)
      (fun x hx => (hw' x (Ico_subset_Icc_self hx)).hasDerivWithinAt)
  have hg := constant_of_has_deriv_right_zero (f := fun x => w x - w' 0 * x) (a := 0) (b := 1)
    (fun x _ => ((hw x).continuousAt.sub (continuousAt_const.mul continuousAt_id)).continuousWithinAt)
    (fun x hx => by
      have := (hw x).sub ((hasDerivAt_id x).const_mul (w' 0))
      rw [hc x (Ico_subset_Icc_self hx)] at this
      have e : w' 0 - w' 0 * 1 = 0 := by ring
      rw [e] at this
      exact this.hasDerivWithinAt)
  intro x hx
  have := hg x hx
  simp at this
  linarith

#print axioms affine_of_deriv2_zero

/-- **Boundary problem = Fredholm equation.** For a classical (twice continuously
differentiable) sag `u`, the ponding boundary problem `−u'' = λ (h₀ + u)` on `[0, 1]` with
`u(0) = u(1) = 0` holds exactly when `u` solves the Fredholm equation of the second kind
`u(x) = f(x) + λ ∫₀¹ G(x, y) u(y) dy` on `[0, 1]`, where `f` is the rain-alone sag and `G`
is the tent kernel. Neither form loses or gains a solution. -/
theorem boundary_problem_iff_fredholm_equation (lam h0 : ℝ) (u : ℝ → ℝ)
    (hu : ContDiff ℝ 2 u) :
    ((∀ x ∈ Icc (0 : ℝ) 1, -deriv (deriv u) x = lam * (h0 + u x)) ∧ u 0 = 0 ∧ u 1 = 0) ↔
      ∀ x ∈ Icc (0 : ℝ) 1,
        u x = rainSag lam h0 x + lam * ∫ y in (0 : ℝ)..1, greenKernel x y * u y := by
  have hu2 := contDiff_succ_iff_deriv.mp (show ContDiff ℝ (1 + 1) u from hu)
  have hud : Differentiable ℝ u := hu2.1
  have hu'd : Differentiable ℝ (deriv u) :=
    (contDiff_succ_iff_deriv.mp (show ContDiff ℝ (0 + 1) (deriv u) by simpa using hu2.2.2)).1
  have huc : Continuous u := hud.continuous
  have hyu : Continuous fun y => y * u y := continuous_id.mul huc
  have h1u : Continuous fun y => (1 - y) * u y := (continuous_const.sub continuous_id).mul huc
  set A : ℝ → ℝ := fun x => ∫ y in (0:ℝ)..x, y * u y
  set B : ℝ → ℝ := fun x => ∫ y in (0:ℝ)..x, (1 - y) * u y
  set C : ℝ := ∫ y in (0:ℝ)..1, (1 - y) * u y with hC
  set W : ℝ → ℝ := fun x => rainSag lam h0 x + lam * ((1 - x) * A x + x * (C - B x)) with hW
  set W' : ℝ → ℝ := fun x => lam * h0 * (1 - 2 * x) / 2 + lam * (C - B x - A x) with hW'
  have hA : ∀ x, HasDerivAt A (x * u x) x := fun x => (hyu.integral_hasStrictDerivAt 0 x).hasDerivAt
  have hB : ∀ x, HasDerivAt B ((1 - x) * u x) x :=
    fun x => (h1u.integral_hasStrictDerivAt 0 x).hasDerivAt
  have hWd : ∀ x, HasDerivAt W (W' x) x := by
    intro x
    have hr : HasDerivAt (fun x => rainSag lam h0 x) (lam * h0 * (1 - 2 * x) / 2) x := by
      have h := (((hasDerivAt_id' x).const_mul (lam * h0)).mul
        ((hasDerivAt_id' x).const_sub 1)).div_const 2
      unfold rainSag
      convert h using 1
      ring
    have h := hr.add (((((hasDerivAt_id' x).const_sub 1).mul (hA x)).add
      ((hasDerivAt_id' x).mul ((hB x).const_sub C))).const_mul lam)
    convert h using 1
    simp only [hW']; ring
  have hW'd : ∀ x, HasDerivAt W' (-lam * h0 - lam * u x) x := by
    intro x
    have h := ((((hasDerivAt_id' x).const_mul 2).const_sub 1).const_mul (lam * h0) |>.div_const
      2).add ((((hB x).const_sub C).sub (hA x)).const_mul lam)
    convert h using 1
    ring
  have hsplit : ∀ x ∈ Icc (0:ℝ) 1,
      (∫ y in (0 : ℝ)..1, greenKernel x y * u y) = (1 - x) * A x + x * (C - B x) := by
    intro x hx
    have hcont : Continuous fun y => greenKernel x y * u y := by
      unfold greenKernel; fun_prop
    rw [← intervalIntegral.integral_add_adjacent_intervals (b := x)
      (hcont.intervalIntegrable 0 x) (hcont.intervalIntegrable x 1)]
    have e1 : (∫ y in (0:ℝ)..x, greenKernel x y * u y) = ∫ y in (0:ℝ)..x, (1 - x) * (y * u y) := by
      apply intervalIntegral.integral_congr
      intro y hy
      rw [uIcc_of_le hx.1] at hy
      simp only [greenKernel, min_eq_right hy.2, max_eq_left hy.2]; ring
    have e2 : (∫ y in x..1, greenKernel x y * u y) = ∫ y in x..1, x * ((1 - y) * u y) := by
      apply intervalIntegral.integral_congr
      intro y hy
      rw [uIcc_of_le hx.2] at hy
      simp only [greenKernel, min_eq_left hy.1, max_eq_right hy.1]; ring
    rw [e1, e2, intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul,
      ← intervalIntegral.integral_interval_sub_left (h1u.intervalIntegrable 0 1)
        (h1u.intervalIntegrable 0 x)]
  have hW0 : W 0 = 0 := by simp [hW, A, B, rainSag]
  have hW1 : W 1 = 0 := by simp [hW, B, rainSag, hC]
  constructor
  · rintro ⟨hode, h0u, h1u'⟩ x hx
    have key := affine_of_deriv2_zero (w := fun x => u x - W x) (w' := fun x => deriv u x - W' x)
      (fun x => (hud x).hasDerivAt.sub (hWd x))
      (fun x hx => by
        have h := (hu'd x).hasDerivAt.sub (hW'd x)
        have e : deriv (deriv u) x - (-lam * h0 - lam * u x) = 0 := by
          have := hode x hx; linarith
        rw [e] at h
        exact h)
    have k1 := key 1 ⟨zero_le_one, le_refl _⟩
    have kx := key x hx
    simp only [h0u, hW0, h1u', hW1, sub_self, zero_add, mul_one] at k1 kx
    rw [hsplit x hx]
    rw [← k1, zero_mul] at kx
    have : u x = W x := by linarith
    rw [this]
  · intro h
    have heq : EqOn u W (Icc 0 1) := fun x hx => by rw [h x hx, hsplit x hx]
    have hd1 := deriv_eqOn_of_eqOn_Icc hud heq hWd
    have hd2 := deriv_eqOn_of_eqOn_Icc hu'd hd1 hW'd
    refine ⟨fun x hx => ?_, ?_, ?_⟩
    · rw [hd2 hx]; ring
    · rw [heq ⟨le_refl _, zero_le_one⟩, hW0]
    · rw [heq ⟨zero_le_one, le_refl _⟩, hW1]

/-- **Conditions at one end give a Volterra equation.** For a classical sag `u`, the same
equation `−u'' = λ (h₀ + u)` on `[0, 1]`, started from the left beam with `u(0) = 0` and slope
`u'(0) = s₀`, holds exactly when `u` solves the Volterra equation of the second kind
`u(x) = s₀ x − λ ∫₀ˣ (x − y) (h₀ + u(y)) dy` on `[0, 1]`: the integral stops at `x`. -/
theorem initial_problem_iff_volterra_equation (lam h0 s0 : ℝ) (u : ℝ → ℝ)
    (hu : ContDiff ℝ 2 u) :
    ((∀ x ∈ Icc (0 : ℝ) 1, -deriv (deriv u) x = lam * (h0 + u x)) ∧ u 0 = 0 ∧
        deriv u 0 = s0) ↔
      ∀ x ∈ Icc (0 : ℝ) 1, u x = s0 * x - lam * ∫ y in (0 : ℝ)..x, (x - y) * (h0 + u y) := by
  have hu2 := contDiff_succ_iff_deriv.mp (show ContDiff ℝ (1 + 1) u from hu)
  have hud : Differentiable ℝ u := hu2.1
  have hu'd : Differentiable ℝ (deriv u) :=
    (contDiff_succ_iff_deriv.mp (show ContDiff ℝ (0 + 1) (deriv u) by simpa using hu2.2.2)).1
  set g : ℝ → ℝ := fun y => h0 + u y with hg
  have hgc : Continuous g := continuous_const.add hud.continuous
  have hyg : Continuous fun y => y * g y := continuous_id.mul hgc
  set G1 : ℝ → ℝ := fun x => ∫ y in (0:ℝ)..x, g y
  set G2 : ℝ → ℝ := fun x => ∫ y in (0:ℝ)..x, y * g y
  set V : ℝ → ℝ := fun x => s0 * x - lam * (x * G1 x - G2 x) with hV
  set V' : ℝ → ℝ := fun x => s0 - lam * G1 x with hV'
  have hG1 : ∀ x, HasDerivAt G1 (g x) x := fun x => (hgc.integral_hasStrictDerivAt 0 x).hasDerivAt
  have hG2 : ∀ x, HasDerivAt G2 (x * g x) x :=
    fun x => (hyg.integral_hasStrictDerivAt 0 x).hasDerivAt
  have hVd : ∀ x, HasDerivAt V (V' x) x := by
    intro x
    have h := ((hasDerivAt_id' x).const_mul s0).sub
      ((((hasDerivAt_id' x).mul (hG1 x)).sub (hG2 x)).const_mul lam)
    convert h using 1
    simp only [hV']; ring
  have hV'd : ∀ x, HasDerivAt V' (-lam * g x) x := by
    intro x
    have h := ((hG1 x).const_mul lam).const_sub s0
    convert h using 1
    ring
  have hrep : ∀ x, (∫ y in (0 : ℝ)..x, (x - y) * (h0 + u y)) = x * G1 x - G2 x := by
    intro x
    have e : (fun y => (x - y) * (h0 + u y)) = fun y => x * g y - y * g y := by
      funext y; simp only [hg]; ring
    rw [e, intervalIntegral.integral_sub
      ((show Continuous fun y => x * g y by fun_prop).intervalIntegrable 0 x)
      (hyg.intervalIntegrable 0 x), intervalIntegral.integral_const_mul]
  have hV0 : V 0 = 0 := by simp [hV, G1, G2]
  have hV'0 : V' 0 = s0 := by simp [hV', G1]
  constructor
  · rintro ⟨hode, h0u, h0d⟩ x hx
    have key := affine_of_deriv2_zero (w := fun x => u x - V x) (w' := fun x => deriv u x - V' x)
      (fun x => (hud x).hasDerivAt.sub (hVd x))
      (fun x hx => by
        have h := (hu'd x).hasDerivAt.sub (hV'd x)
        have e : deriv (deriv u) x - -lam * g x = 0 := by
          have := hode x hx; simp only [hg]; linarith
        rw [e] at h
        exact h) x hx
    simp only [h0u, hV0, h0d, hV'0, sub_self, zero_mul, add_zero] at key
    rw [hrep]
    linarith
  · intro h
    have heq : EqOn u V (Icc 0 1) := fun x hx => by rw [h x hx, hrep]
    have hd1 := deriv_eqOn_of_eqOn_Icc hud heq hVd
    have hd2 := deriv_eqOn_of_eqOn_Icc hu'd hd1 hV'd
    have h0mem : (0:ℝ) ∈ Icc (0:ℝ) 1 := ⟨le_refl _, zero_le_one⟩
    refine ⟨fun x hx => ?_, ?_, ?_⟩
    · rw [hd2 hx]; simp only [hg]; ring
    · rw [heq h0mem, hV0]
    · rw [hd1 h0mem, hV'0]

/-- **The ponded sag in closed form.** With the feedback parameter `λ = ρg/T` below `π²`,
the sag `u(x) = h₀ (cos(√λ (x − ½)) / cos(√λ / 2) − 1)` is a classical solution of the
ponding boundary problem: `−u'' = λ (h₀ + u)` on `[0, 1]` and `u(0) = u(1) = 0`. -/
theorem ponded_sag_solves_boundary_problem (lam h0 : ℝ) (hlam0 : 0 ≤ lam)
    (hlam : lam < π ^ 2) :
    ContDiff ℝ 2 (pondedSag lam h0) ∧
      (∀ x ∈ Icc (0 : ℝ) 1,
        -deriv (deriv (pondedSag lam h0)) x = lam * (h0 + pondedSag lam h0 x)) ∧
      pondedSag lam h0 0 = 0 ∧ pondedSag lam h0 1 = 0 := by
  set s := √lam with hs
  set c := Real.cos (s / 2) with hc
  have hs0 : 0 ≤ s := Real.sqrt_nonneg _
  have hsπ : s < π := by
    rw [hs, Real.sqrt_lt' Real.pi_pos]; exact hlam
  have hcpos : 0 < c := Real.cos_pos_of_mem_Ioo ⟨by linarith [Real.pi_pos], by linarith⟩
  have hss : s * s = lam := Real.mul_self_sqrt hlam0
  have hP : pondedSag lam h0 = fun x => h0 * (Real.cos (s * (x - 1/2)) / c - 1) := rfl
  have hd1 : ∀ x, HasDerivAt (pondedSag lam h0) (h0 * (-(Real.sin (s * (x - 1/2)) * s) / c)) x := by
    intro x
    have h := (((((hasDerivAt_id' x).sub_const (1/2 : ℝ)).const_mul s).cos.div_const c).sub_const
      1).const_mul h0
    rw [hP]
    convert h using 1
    ring
  have hd2 : ∀ x, HasDerivAt (fun x => h0 * (-(Real.sin (s * (x - 1/2)) * s) / c))
      (h0 * (-(Real.cos (s * (x - 1/2)) * s * s) / c)) x := by
    intro x
    have h := (((((hasDerivAt_id' x).sub_const (1/2 : ℝ)).const_mul s).sin.mul_const
      s).fun_neg.div_const c).const_mul h0
    convert h using 1
    ring
  have hD1 : deriv (pondedSag lam h0) = fun x => h0 * (-(Real.sin (s * (x - 1/2)) * s) / c) :=
    funext fun x => (hd1 x).deriv
  refine ⟨?_, ?_, ?_, ?_⟩
  · rw [hP]; fun_prop
  · intro x _
    rw [hD1, (hd2 x).deriv, hP]
    rw [← hss]
    field_simp
    ring
  · rw [hP]
    have : s * (0 - 1/2) = -(s/2) := by ring
    simp only
    rw [this, Real.cos_neg, ← hc, div_self hcpos.ne']; ring
  · rw [hP]
    have : s * (1 - 1/2) = s/2 := by ring
    simp only
    rw [this, ← hc, div_self hcpos.ne']; ring

/-! The card's roof: ρ = 1000 kg/m³, g = 981/100 m/s², T = 1962 N/m, h₀ = 1/100 m. -/

-- The feedback parameter λ = ρ g / T is exactly 5 per m².
example : (1000 : ℚ) * (981 / 100) / 1962 = 5 := by norm_num

-- The rain-alone sag at the middle, λ h₀ (½)(1 − ½)/2 = λ h₀ / 8, is 1/160 m = 6.25 mm.
example : (5 : ℚ) * (1 / 100) * (1 / 2) * (1 - 1 / 2) / 2 = 1 / 160 := by norm_num
example : (1000 : ℚ) * (1 / 160) = 25 / 4 := by norm_num

-- The second Fredholm term at the middle, λ² h₀ · 5/384, is 5/1536 m (3.2552 mm).
example : (5 : ℚ) ^ 2 * (1 / 100) * (5 / 384) = 5 / 1536 := by norm_num

-- The rain load ρ g h₀ is 981/10 Pa (98.10 Pa).
example : (1000 : ℚ) * (981 / 100) * (1 / 100) = 981 / 10 := by norm_num

-- The safe shrink per Fredholm term, λ / 8, is 5/8, below 1.
example : (5 : ℚ) / 8 < 1 := by norm_num

-- Cutting the tension to 817.5 N/m raises λ to exactly 12 per m².
example : (1000 : ℚ) * (981 / 100) / (8175 / 10) = 12 := by norm_num

#print axioms boundary_problem_iff_fredholm_equation
#print axioms initial_problem_iff_volterra_equation
#print axioms ponded_sag_solves_boundary_problem
