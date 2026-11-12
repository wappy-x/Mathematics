-- Superposition: for a second-order linear equation y'' + p y' + q y = f, weighted sums of solutions solve the equation with the same weighted sum of forcings, every solution is one forced solution plus a unique mix of two independent free solutions, and for the spring y'' + y = 0 (and y'' + y = t/2) the starting height and speed fix the mix.
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.ODE.ExistUnique
import Mathlib.Tactic.NormNum

set_option autoImplicit false

open Real

/-- `y` solves the second-order linear equation `y'' + p(t) y' + q(t) y = f(t)` at every time:
`y` and its rate `y'` are differentiable, and the acceleration plus `p` times the speed plus
`q` times the height equals the forcing `f`. With `f = 0` the solution is free (homogeneous). -/
def IsSolution (p q f : ℝ → ℝ) (y : ℝ → ℝ) : Prop :=
  Differentiable ℝ y ∧ Differentiable ℝ (deriv y) ∧
    ∀ t, deriv (deriv y) t + p t * deriv y t + q t * y t = f t

theorem slin_deriv_comb (y₁ y₂ : ℝ → ℝ) (a b : ℝ) (h₁ : Differentiable ℝ y₁)
    (h₂ : Differentiable ℝ y₂) :
    deriv (fun t => a * y₁ t + b * y₂ t) = fun t => a * deriv y₁ t + b * deriv y₂ t := by
  funext t
  exact (((h₁ t).hasDerivAt.const_mul a).add ((h₂ t).hasDerivAt.const_mul b)).deriv

#print axioms slin_deriv_comb

theorem slin_comb_solution
    (p q f₁ f₂ y₁ y₂ : ℝ → ℝ) (a b : ℝ)
    (h₁ : IsSolution p q f₁ y₁) (h₂ : IsSolution p q f₂ y₂) :
    IsSolution p q (fun t => a * f₁ t + b * f₂ t) (fun t => a * y₁ t + b * y₂ t) := by
  obtain ⟨d₁, dd₁, e₁⟩ := h₁
  obtain ⟨d₂, dd₂, e₂⟩ := h₂
  have hd := slin_deriv_comb y₁ y₂ a b d₁ d₂
  have hdd := slin_deriv_comb (deriv y₁) (deriv y₂) a b dd₁ dd₂
  refine ⟨(d₁.const_mul a).add (d₂.const_mul b), ?_, ?_⟩
  · rw [hd]; exact (dd₁.const_mul a).add (dd₂.const_mul b)
  · intro t
    rw [hd, hdd]
    linear_combination a * e₁ t + b * e₂ t

#print axioms slin_comb_solution

theorem slin_congr (p q f f' y y' : ℝ → ℝ) (h : IsSolution p q f y)
    (hf : ∀ t, f t = f' t) (hy : ∀ t, y t = y' t) : IsSolution p q f' y' := by
  have e1 : f = f' := funext hf
  have e2 : y = y' := funext hy
  subst e1 e2
  exact h

#print axioms slin_congr

theorem slin_free_unique (p q : ℝ → ℝ) (hp : Continuous p) (hq : Continuous q)
    (w : ℝ → ℝ) (hw : IsSolution p q 0 w) (h0 : w 0 = 0) (h1 : deriv w 0 = 0) :
    ∀ t, w t = 0 := by
  intro t
  obtain ⟨hd, hdd, heq⟩ := hw
  set R : ℝ := |t| + 1 with hR
  have hc : IsCompact (Set.Icc (-R) R) := isCompact_Icc
  obtain ⟨Cp, hCp⟩ := hc.exists_bound_of_continuousOn hp.continuousOn
  obtain ⟨Cq, hCq⟩ := hc.exists_bound_of_continuousOn hq.continuousOn
  let v : ℝ → ℝ × ℝ → ℝ × ℝ := fun s x => (x.2, -(p s * x.2) - q s * x.1)
  let F : ℝ → ℝ × ℝ := fun s => (w s, deriv w s)
  have hF : ∀ s, HasDerivAt F (v s (F s)) s := by
    intro s
    have h := ((hd s).hasDerivAt).prodMk ((hdd s).hasDerivAt)
    convert h using 1
    have := heq s
    simp only [Pi.zero_apply] at this
    simp only [v, F, Prod.mk.injEq, true_and]
    linarith
  have hG : ∀ s, HasDerivAt (fun _ => (0 : ℝ × ℝ)) (v s 0) s := by
    intro s
    have h0v : v s 0 = 0 := by simp [v]
    rw [h0v]
    exact hasDerivAt_const s (0 : ℝ × ℝ)
  let K : NNReal := ⟨1 + |Cp| + |Cq|, by positivity⟩
  have hlip : ∀ s ∈ Set.Ioo (-R) R, LipschitzOnWith K (v s) Set.univ := by
    intro s hs
    have hs' : s ∈ Set.Icc (-R) R := Set.Ioo_subset_Icc_self hs
    have hps : |p s| ≤ |Cp| := by
      have := hCp s hs'; rw [Real.norm_eq_abs] at this; exact this.trans (le_abs_self _)
    have hqs : |q s| ≤ |Cq| := by
      have := hCq s hs'; rw [Real.norm_eq_abs] at this; exact this.trans (le_abs_self _)
    refine (LipschitzWith.of_dist_le_mul fun x y => ?_).lipschitzOnWith
    have hK : (K : ℝ) = 1 + |Cp| + |Cq| := rfl
    rw [hK]
    simp only [Prod.dist_eq, Real.dist_eq, v]
    set M := max |x.1 - y.1| |x.2 - y.2|
    have ha : |x.1 - y.1| ≤ M := le_max_left _ _
    have hb : |x.2 - y.2| ≤ M := le_max_right _ _
    have hM : 0 ≤ M := (abs_nonneg _).trans ha
    have hCp0 : 0 ≤ |Cp| := abs_nonneg _
    have hCq0 : 0 ≤ |Cq| := abs_nonneg _
    apply max_le
    · nlinarith
    · have e : -(p s * x.2) - q s * x.1 - (-(p s * y.2) - q s * y.1)
          = -(p s * (x.2 - y.2)) + -(q s * (x.1 - y.1)) := by ring
      rw [e]
      calc |-(p s * (x.2 - y.2)) + -(q s * (x.1 - y.1))|
          ≤ |-(p s * (x.2 - y.2))| + |-(q s * (x.1 - y.1))| := abs_add_le _ _
        _ = |p s| * |x.2 - y.2| + |q s| * |x.1 - y.1| := by rw [abs_neg, abs_neg, abs_mul, abs_mul]
        _ ≤ |Cp| * M + |Cq| * M := by
            gcongr
        _ ≤ (1 + |Cp| + |Cq|) * M := by nlinarith
  have hRpos : (0 : ℝ) ∈ Set.Ioo (-R) R := by
    constructor <;> [skip; skip] <;> (have := abs_nonneg t; linarith)
  have htR : t ∈ Set.Ioo (-R) R := by
    constructor
    · have := neg_abs_le t; linarith
    · have := le_abs_self t; linarith
  have key := ODE_solution_unique_of_mem_Ioo hlip hRpos
    (fun s _ => ⟨hF s, Set.mem_univ _⟩) (fun s _ => ⟨hG s, Set.mem_univ _⟩)
    (by simp [F, h0, h1]) htR
  have := congrArg Prod.fst key
  simpa [F] using this

#print axioms slin_free_unique

theorem slin_ivp_unique (p q f : ℝ → ℝ) (hp : Continuous p) (hq : Continuous q)
    (y g : ℝ → ℝ) (hy : IsSolution p q f y) (hg : IsSolution p q f g)
    (h0 : y 0 = g 0) (h1 : deriv y 0 = deriv g 0) : ∀ t, y t = g t := by
  have hw := slin_congr _ _ _ 0 _ (fun t => y t - g t)
    (slin_comb_solution p q f f y g 1 (-1) hy hg) (fun t => by simp) (fun t => by ring)
  have hd : deriv (fun t => y t - g t) 0 = 0 := by
    have hc := slin_deriv_comb y g 1 (-1) hy.1 hg.1
    have e : (fun t => y t - g t) = fun t => 1 * y t + (-1) * g t := by funext t; ring
    rw [e, hc]
    simp [h1]
  intro t
  have := slin_free_unique p q hp hq _ hw (by simp [h0]) hd t
  exact sub_eq_zero.mp this

#print axioms slin_ivp_unique

theorem slin_mix_solution (p q f yp y₁ y₂ : ℝ → ℝ) (c₁ c₂ : ℝ)
    (hyp : IsSolution p q f yp) (h₁ : IsSolution p q 0 y₁) (h₂ : IsSolution p q 0 y₂) :
    IsSolution p q f (fun t => yp t + c₁ * y₁ t + c₂ * y₂ t) ∧
      deriv (fun t => yp t + c₁ * y₁ t + c₂ * y₂ t) =
        fun t => deriv yp t + c₁ * deriv y₁ t + c₂ * deriv y₂ t := by
  have hu := slin_comb_solution p q 0 0 y₁ y₂ c₁ c₂ h₁ h₂
  have hs := slin_comb_solution p q f _ yp _ 1 1 hyp hu
  constructor
  · exact slin_congr _ _ _ _ _ _ hs (fun t => by simp) (fun t => by ring)
  · have e : (fun t => yp t + c₁ * y₁ t + c₂ * y₂ t)
        = fun t => 1 * yp t + 1 * (c₁ * y₁ t + c₂ * y₂ t) := by funext t; ring
    rw [e, slin_deriv_comb yp (fun t => c₁ * y₁ t + c₂ * y₂ t) 1 1 hyp.1 hu.1,
      slin_deriv_comb y₁ y₂ c₁ c₂ h₁.1 h₂.1]
    funext t
    ring

#print axioms slin_mix_solution

/-- Superposition for any second-order linear equation `y'' + p(t) y' + q(t) y = f(t)` with
continuous coefficients `p`, `q` and continuous forcing `f`. Take two free solutions `y₁`, `y₂`
that are independent (their starting table has determinant
`y₁(0) y₂'(0) - y₂(0) y₁'(0) ≠ 0`) and one forced solution `yp`. Then a curve `y` solves the
forced equation exactly when it is `yp` plus a weighted sum `c₁ y₁ + c₂ y₂`, and the
weights are unique: the forced solutions are one forced solution plus the free family, and two
independent free solutions cover that family. -/
theorem solutions_are_one_forced_plus_free_mix
    (p q f : ℝ → ℝ) (hp : Continuous p) (hq : Continuous q) (hf : Continuous f)
    (y₁ y₂ yp : ℝ → ℝ) (h₁ : IsSolution p q 0 y₁) (h₂ : IsSolution p q 0 y₂)
    (hind : y₁ 0 * deriv y₂ 0 - y₂ 0 * deriv y₁ 0 ≠ 0)
    (hyp : IsSolution p q f yp) (y : ℝ → ℝ) :
    IsSolution p q f y ↔ ∃! c : ℝ × ℝ, ∀ t, y t = yp t + c.1 * y₁ t + c.2 * y₂ t := by
  constructor
  · intro hy
    set W := y₁ 0 * deriv y₂ 0 - y₂ 0 * deriv y₁ 0 with hW
    set z₀ := y 0 - yp 0 with hz₀
    set z₁ := deriv y 0 - deriv yp 0 with hz₁
    set c₁ := (z₀ * deriv y₂ 0 - y₂ 0 * z₁) / W with hc₁
    set c₂ := (y₁ 0 * z₁ - z₀ * deriv y₁ 0) / W with hc₂
    obtain ⟨hg, hgd⟩ := slin_mix_solution p q f yp y₁ y₂ c₁ c₂ hyp h₁ h₂
    have hex : ∀ t, y t = yp t + c₁ * y₁ t + c₂ * y₂ t := by
      refine slin_ivp_unique p q f hp hq y _ hy hg ?_ ?_
      · show y 0 = yp 0 + c₁ * y₁ 0 + c₂ * y₂ 0
        rw [hc₁, hc₂]
        field_simp
        rw [hz₀, hz₁, hW]
        ring
      · rw [hgd]
        show deriv y 0 = deriv yp 0 + c₁ * deriv y₁ 0 + c₂ * deriv y₂ 0
        rw [hc₁, hc₂]
        field_simp
        rw [hz₀, hz₁, hW]
        ring
    refine ⟨(c₁, c₂), hex, fun c' hc' => ?_⟩
    have hfun : (fun t => yp t + c'.1 * y₁ t + c'.2 * y₂ t)
        = (fun t => yp t + c₁ * y₁ t + c₂ * y₂ t) :=
      funext fun t => (hc' t).symm.trans (hex t)
    have hdd : deriv (fun t => yp t + c'.1 * y₁ t + c'.2 * y₂ t) 0
        = deriv (fun t => yp t + c₁ * y₁ t + c₂ * y₂ t) 0 := by rw [hfun]
    rw [(slin_mix_solution p q f yp y₁ y₂ c'.1 c'.2 hyp h₁ h₂).2, hgd] at hdd
    have e₁ : (c'.1 - c₁) * y₁ 0 + (c'.2 - c₂) * y₂ 0 = 0 := by
      have := (hc' 0).symm.trans (hex 0); linarith
    have e₂ : (c'.1 - c₁) * deriv y₁ 0 + (c'.2 - c₂) * deriv y₂ 0 = 0 := by linarith
    have ha : (c'.1 - c₁) * W = 0 := by
      rw [hW]; linear_combination (deriv y₂ 0) * e₁ - (y₂ 0) * e₂
    have hb : (c'.2 - c₂) * W = 0 := by
      rw [hW]; linear_combination (y₁ 0) * e₂ - (deriv y₁ 0) * e₁
    have ha' := (mul_eq_zero.mp ha).resolve_right hind
    have hb' := (mul_eq_zero.mp hb).resolve_right hind
    exact Prod.ext (by linarith) (by linarith)
  · rintro ⟨c, hc, -⟩
    exact slin_congr _ _ _ _ _ _ (slin_mix_solution p q f yp y₁ y₂ c.1 c.2 hyp h₁ h₂).1
      (fun _ => rfl) (fun t => (hc t).symm)

/-- Step 0: the machine `L[y] = y'' + p y' + q y` respects sums and multiples. If `y₁` meets
forcing `f₁` and `y₂` meets forcing `f₂`, then `a y₁ + b y₂` meets forcing `a f₁ + b f₂`,
for any numbers `a`, `b` and any coefficients `p`, `q`. So any weighted sum of free solutions
is free (`f₁ = f₂ = 0`), two forced solutions add to one with the forcing doubled, and twice a
motion needs twice the forcing. -/
theorem linear_operator_respects_weighted_sums
    (p q f₁ f₂ y₁ y₂ : ℝ → ℝ) (a b : ℝ)
    (h₁ : IsSolution p q f₁ y₁) (h₂ : IsSolution p q f₂ y₂) :
    IsSolution p q (fun t => a * f₁ t + b * f₂ t) (fun t => a * y₁ t + b * y₂ t) := by
  exact slin_comb_solution p q f₁ f₂ y₁ y₂ a b h₁ h₂

/-- The spring, Steps 2 to 4: every free motion of `y'' + y = 0` is
`y(0) cos t + y'(0) sin t`, so the starting height and speed are the two weights; and every
motion of `y'' + y = t/2`, with the hook rising, is `t/2 + y(0) cos t + (y'(0) - 1/2) sin t`. -/
theorem spring_motion_fixed_by_start (y : ℝ → ℝ) :
    (IsSolution 0 1 0 y → ∀ t, y t = y 0 * cos t + deriv y 0 * sin t) ∧
    (IsSolution 0 1 (fun t => t / 2) y →
      ∀ t, y t = t / 2 + y 0 * cos t + (deriv y 0 - 1 / 2) * sin t) := by
  have hdc : deriv (fun x => -sin x) = fun x => -cos x := by
    funext x; exact (hasDerivAt_sin x).neg.deriv
  have hcos : IsSolution 0 1 0 cos := by
    refine ⟨differentiable_cos, ?_, fun t => ?_⟩
    · rw [deriv_cos']; exact differentiable_sin.neg
    · rw [deriv_cos', hdc]; simp
  have hsin : IsSolution 0 1 0 sin := by
    refine ⟨differentiable_sin, ?_, fun t => ?_⟩
    · rw [Real.deriv_sin]; exact differentiable_cos
    · rw [Real.deriv_sin, deriv_cos']; simp
  have hl : deriv (fun t : ℝ => t / 2) = fun _ => 1 / 2 := by
    funext t; exact ((hasDerivAt_id' t).div_const 2).deriv
  have hlin : IsSolution 0 1 (fun t => t / 2) (fun t => t / 2) := by
    refine ⟨fun t => ((hasDerivAt_id' t).div_const 2).differentiableAt, ?_, fun t => ?_⟩
    · rw [hl]; exact differentiable_const _
    · rw [hl]; simp
  constructor
  · intro hy
    have hg := slin_congr _ _ _ 0 _ _
      (slin_comb_solution 0 1 0 0 cos sin (y 0) (deriv y 0) hcos hsin)
      (fun t => by simp) (fun _ => rfl)
    refine slin_ivp_unique 0 1 0 continuous_zero continuous_one y _ hy hg (by simp) ?_
    have h : HasDerivAt (fun t => y 0 * cos t + deriv y 0 * sin t)
        (y 0 * -sin 0 + deriv y 0 * cos 0) 0 :=
      ((hasDerivAt_cos 0).const_mul (y 0)).add ((hasDerivAt_sin 0).const_mul (deriv y 0))
    rw [h.deriv]
    simp
  · intro hy
    have hu := slin_congr _ _ _ 0 _ _
      (slin_comb_solution 0 1 0 0 cos sin (y 0) (deriv y 0 - 1 / 2) hcos hsin)
      (fun t => by simp) (fun _ => rfl)
    have hg := slin_congr _ _ _ (fun t => t / 2) _
      (fun t => t / 2 + y 0 * cos t + (deriv y 0 - 1 / 2) * sin t)
      (slin_comb_solution 0 1 _ _ _ _ 1 1 hlin hu) (fun t => by simp) (fun t => by ring)
    refine slin_ivp_unique 0 1 _ continuous_zero continuous_one y _ hy hg (by simp) ?_
    have h : HasDerivAt (fun t => t / 2 + y 0 * cos t + (deriv y 0 - 1 / 2) * sin t)
        (1 / 2 + y 0 * -sin 0 + (deriv y 0 - 1 / 2) * cos 0) 0 :=
      (((hasDerivAt_id' 0).div_const 2).add ((hasDerivAt_cos 0).const_mul (y 0))).add
        ((hasDerivAt_sin 0).const_mul (deriv y 0 - 1 / 2))
    rw [h.deriv]
    simp

-- Free weights from the start 3 cm, -2 cm/s, and twice the energy per kg: (-2)^2 + 3^2 = 13.
example : (-2 : ℤ) ^ 2 + 3 ^ 2 = 13 := by norm_num
-- Forced weights with the hook: 3 = 0 + c₁ and -2 = 1/2 + c₂ give c₁ = 3 and c₂ = -5/2.
example : (3 : ℚ) = 0 + 3 ∧ (-2 : ℚ) = 1 / 2 + (-5 / 2) := by norm_num
-- The starting table of cos t and sin t has determinant 1; of cos t and 2 cos t, determinant 0.
example : cos 0 * cos 0 - sin 0 * (-sin 0) = 1 ∧
    cos 0 * (2 * -sin 0) - 2 * cos 0 * (-sin 0) = 0 := by simp
-- The forcing t/2 at t = 2 s is 1; two forced solutions added carry forcing 2, not 1.
example : (2 : ℚ) / 2 = 1 ∧ (2 : ℚ) / 2 + 2 / 2 = 2 := by norm_num
-- The pendulum y'' + sin y = 0: the balance y = π leaves residual 0, its half y = π/2 leaves 1.
example : sin π = 0 ∧ sin (π / 2) = 1 := ⟨sin_pi, sin_pi_div_two⟩
-- Doubled hook and start: 1 cm/s = 2 × 1/2, 6 = 2 × 3, -4 = 2 × (-2).
example : (1 : ℚ) = 2 * (1 / 2) ∧ (6 : ℤ) = 2 * 3 ∧ (-4 : ℤ) = 2 * (-2) := by norm_num

#print axioms solutions_are_one_forced_plus_free_mix
#print axioms linear_operator_respects_weighted_sums
#print axioms spring_motion_fixed_by_start
