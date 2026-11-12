-- Boundary value problems: for y'' + p y' + q y = g on [0, L] with one linear condition at each end, the solutions number exactly one, none or infinitely many, the determinant D of the end conditions applied to the two standard solutions decides which, and the strut y'' + y = 0 has one shape at L = 1, a whole family at L = π with ends 0 and 0, and none at L = π with ends 0 and 1.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Data.Set.Card
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.ODE.ExistUnique
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Topology.Order.ProjIcc
import Mathlib.Analysis.Calculus.TangentCone.Real

open Set Real

/-- The solutions of the two-point boundary value problem
`y'' + p y' + q y = g` on `[0, L]`, with end conditions
`α₀ y(0) + β₀ y'(0) = γ₀` at the foot and `α_L y(L) + β_L y'(L) = γ_L` at the top.
A solution is a function `y` with slope `y'` on `[0, L]` (one-sided at the ends) whose slope
`y'` has slope `g - p y' - q y` there. Each solution is recorded by its values on `[0, L]`,
so two solutions count as the same exactly when they agree at every point of the interval. -/
def bvpSolutions (L : ℝ) (p q g : ℝ → ℝ) (α₀ β₀ γ₀ αL βL γL : ℝ) : Set (Icc (0 : ℝ) L → ℝ) :=
  {f | ∃ y y' : ℝ → ℝ,
    (∀ x ∈ Icc (0 : ℝ) L, HasDerivWithinAt y (y' x) (Icc 0 L) x ∧
      HasDerivWithinAt y' (g x - p x * y' x - q x * y x) (Icc 0 L) x) ∧
    α₀ * y 0 + β₀ * y' 0 = γ₀ ∧ αL * y L + βL * y' L = γL ∧
    ∀ x : Icc (0 : ℝ) L, f x = y x}

open Filter Topology NNReal

/-- Combining two solutions linearly. -/
theorem bvp_lin {L : ℝ} {p q g₁ g₂ y₁ y₁' y₂ y₂' : ℝ → ℝ}
    (h₁ : ∀ x ∈ Icc (0 : ℝ) L, HasDerivWithinAt y₁ (y₁' x) (Icc 0 L) x ∧
      HasDerivWithinAt y₁' (g₁ x - p x * y₁' x - q x * y₁ x) (Icc 0 L) x)
    (h₂ : ∀ x ∈ Icc (0 : ℝ) L, HasDerivWithinAt y₂ (y₂' x) (Icc 0 L) x ∧
      HasDerivWithinAt y₂' (g₂ x - p x * y₂' x - q x * y₂ x) (Icc 0 L) x) (a b : ℝ) :
    ∀ x ∈ Icc (0 : ℝ) L,
      HasDerivWithinAt (fun t => a * y₁ t + b * y₂ t) (a * y₁' x + b * y₂' x) (Icc 0 L) x ∧
      HasDerivWithinAt (fun t => a * y₁' t + b * y₂' t)
        ((a * g₁ x + b * g₂ x) - p x * (a * y₁' x + b * y₂' x) - q x * (a * y₁ x + b * y₂ x))
        (Icc 0 L) x := by
  intro x hx
  obtain ⟨h1a, h1b⟩ := h₁ x hx
  obtain ⟨h2a, h2b⟩ := h₂ x hx
  refine ⟨(h1a.const_mul a).add (h2a.const_mul b), ?_⟩
  convert (h1b.const_mul a).add (h2b.const_mul b) using 1
  ring

/-- `Icc 0 L` is a right neighbourhood of each point of `Ico 0 L`. -/
theorem icc_mem_nhdsGE_of_mem {L x : ℝ} (hx : x ∈ Ico (0 : ℝ) L) :
    Icc (0 : ℝ) L ∈ 𝓝[≥] x :=
  mem_of_superset (Icc_mem_nhdsGE hx.2) (Icc_subset_Icc hx.1 le_rfl)

/-- Uniqueness for the homogeneous initial value problem with zero data. -/
theorem hom_unique {L : ℝ} {p q : ℝ → ℝ} (hp : ContinuousOn p (Icc 0 L))
    (hq : ContinuousOn q (Icc 0 L)) (z z' : ℝ → ℝ)
    (hz : ∀ x ∈ Icc (0 : ℝ) L, HasDerivWithinAt z (z' x) (Icc 0 L) x ∧
      HasDerivWithinAt z' (-(p x * z' x) - q x * z x) (Icc 0 L) x)
    (h0 : z 0 = 0) (h0' : z' 0 = 0) : ∀ x ∈ Icc (0 : ℝ) L, z x = 0 ∧ z' x = 0 := by
  obtain ⟨Cp, hCp⟩ := isCompact_Icc.exists_bound_of_continuousOn hp
  obtain ⟨Cq, hCq⟩ := isCompact_Icc.exists_bound_of_continuousOn hq
  have hK : ((Real.toNNReal (1 + |Cp| + |Cq|) : ℝ≥0) : ℝ) = 1 + |Cp| + |Cq| :=
    Real.coe_toNNReal _ (by positivity)
  have key := ODE_solution_unique_of_mem_Icc_right
    (v := fun t (w : ℝ × ℝ) => (w.2, -(p t * w.2) - q t * w.1)) (s := fun _ => univ)
    (K := Real.toNNReal (1 + |Cp| + |Cq|)) (f := fun t => (z t, z' t)) (g := fun _ => 0)
    (a := 0) (b := L) ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_
  · intro x hx
    have := key hx
    simpa [Prod.ext_iff] using this
  · intro t ht
    have ht' : t ∈ Icc (0 : ℝ) L := Ico_subset_Icc_self ht
    have hp' : |p t| ≤ |Cp| := (hCp t ht').trans (le_abs_self _)
    have hq' : |q t| ≤ |Cq| := (hCq t ht').trans (le_abs_self _)
    apply LipschitzOnWith.of_dist_le_mul
    intro x _ y _
    rw [dist_eq_norm, dist_eq_norm, hK]
    simp only [Prod.mk_sub_mk, Prod.norm_def, Real.norm_eq_abs, Prod.fst_sub, Prod.snd_sub]
    set m := max |x.1 - y.1| |x.2 - y.2|
    have h1 : |x.1 - y.1| ≤ m := le_max_left _ _
    have h2 : |x.2 - y.2| ≤ m := le_max_right _ _
    have hm : 0 ≤ m := (abs_nonneg _).trans h1
    have e : -(p t * x.2) - q t * x.1 - (-(p t * y.2) - q t * y.1)
        = -(p t * (x.2 - y.2)) - q t * (x.1 - y.1) := by ring
    rw [e]
    have hb : |-(p t * (x.2 - y.2)) - q t * (x.1 - y.1)| ≤ |Cp| * m + |Cq| * m := by
      calc |-(p t * (x.2 - y.2)) - q t * (x.1 - y.1)|
          ≤ |-(p t * (x.2 - y.2))| + |q t * (x.1 - y.1)| := abs_sub _ _
        _ = |p t| * |x.2 - y.2| + |q t| * |x.1 - y.1| := by rw [abs_neg, abs_mul, abs_mul]
        _ ≤ |Cp| * m + |Cq| * m := by
          gcongr
    apply max_le
    · nlinarith [abs_nonneg Cp, abs_nonneg Cq]
    · nlinarith [abs_nonneg Cp, abs_nonneg Cq]
  · exact ContinuousOn.prodMk (fun x hx => (hz x hx).1.continuousWithinAt)
      (fun x hx => (hz x hx).2.continuousWithinAt)
  · intro t ht
    have ht' : t ∈ Icc (0 : ℝ) L := Ico_subset_Icc_self ht
    exact ((hz t ht').1.prodMk (hz t ht').2).mono_of_mem_nhdsWithin (icc_mem_nhdsGE_of_mem ht)
  · intro t _; exact mem_univ _
  · exact continuousOn_const
  · intro t _
    convert hasDerivWithinAt_const t (Ici t) (0 : ℝ × ℝ) using 1
    simp
  · intro t _; exact mem_univ _
  · simp [h0, h0']

/-- A primitive of a function continuous on `[0, L]`. -/
theorem prim_exists {L : ℝ} (hL : 0 ≤ L) {h : ℝ → ℝ} (hh : ContinuousOn h (Icc 0 L)) :
    ∃ H : ℝ → ℝ, H 0 = 0 ∧ ∀ x ∈ Icc (0 : ℝ) L, HasDerivWithinAt H (h x) (Icc 0 L) x := by
  let e : ℝ → ℝ := IccExtend hL (fun t : Icc (0 : ℝ) L => h t)
  have hc : Continuous e := continuous_IccExtend_iff.2 hh.domRestrict
  refine ⟨fun x => ∫ t in (0 : ℝ)..x, e t, by simp, fun x hx => ?_⟩
  have hex : e x = h x := IccExtend_of_mem hL _ hx
  have := (hc.integral_hasStrictDerivAt 0 x).hasDerivAt.hasDerivWithinAt (s := Icc 0 L)
  rwa [hex] at this

/-- The Wronskian of two homogeneous solutions starting at 1 never vanishes. -/
theorem wronskian_ne {L : ℝ} (hL : 0 ≤ L) {p q u u' v v' : ℝ → ℝ}
    (hp : ContinuousOn p (Icc 0 L))
    (hu : ∀ x ∈ Icc (0 : ℝ) L, HasDerivWithinAt u (u' x) (Icc 0 L) x ∧
      HasDerivWithinAt u' (-(p x * u' x) - q x * u x) (Icc 0 L) x)
    (hv : ∀ x ∈ Icc (0 : ℝ) L, HasDerivWithinAt v (v' x) (Icc 0 L) x ∧
      HasDerivWithinAt v' (-(p x * v' x) - q x * v x) (Icc 0 L) x)
    (hW0 : u 0 * v' 0 - u' 0 * v 0 = 1) :
    ∀ x ∈ Icc (0 : ℝ) L, u x * v' x - u' x * v x ≠ 0 := by
  obtain ⟨P, hP0, hP⟩ := prim_exists hL hp
  have hF : ∀ x ∈ Icc (0 : ℝ) L, HasDerivWithinAt
      (fun t => (u t * v' t - u' t * v t) * exp (P t)) 0 (Icc 0 L) x := by
    intro x hx
    obtain ⟨hu1, hu2⟩ := hu x hx
    obtain ⟨hv1, hv2⟩ := hv x hx
    convert ((hu1.mul hv2).sub (hu2.mul hv1)).mul (hP x hx).exp using 1
    simp only [Pi.mul_apply, Pi.sub_apply]
    ring
  have hconst := constant_of_has_deriv_right_zero
    (f := fun t => (u t * v' t - u' t * v t) * exp (P t)) (a := 0) (b := L)
    (fun x hx => (hF x hx).continuousWithinAt)
    (fun x hx => (hF x (Ico_subset_Icc_self hx)).mono_of_mem_nhdsWithin
      (icc_mem_nhdsGE_of_mem hx))
  intro x hx hW
  have := hconst x hx
  simp only [hW, zero_mul, hW0, hP0, exp_zero, one_mul] at this
  norm_num at this

/-- A solution of the strut equation `y'' + y = 0` is `y(0) cos x + y'(0) sin x`. -/
theorem strut_shape {L : ℝ} (y y' : ℝ → ℝ)
    (hy : ∀ x ∈ Icc (0 : ℝ) L, HasDerivWithinAt y (y' x) (Icc 0 L) x ∧
      HasDerivWithinAt y' ((0 : ℝ → ℝ) x - (0 : ℝ → ℝ) x * y' x - (1 : ℝ → ℝ) x * y x)
        (Icc 0 L) x) :
    ∀ x ∈ Icc (0 : ℝ) L, y x = y 0 * cos x + y' 0 * sin x := by
  have key := hom_unique (L := L) (p := fun _ => 0) (q := fun _ => 1) continuousOn_const
    continuousOn_const (fun t => y t - y 0 * cos t - y' 0 * sin t)
    (fun t => y' t + y 0 * sin t - y' 0 * cos t) ?_ (by simp) (by simp)
  · intro x hx
    have := (key x hx).1
    linarith
  · intro x hx
    obtain ⟨h1, h2⟩ := hy x hx
    constructor
    · convert (h1.sub ((hasDerivAt_cos x).hasDerivWithinAt.const_mul (y 0))).sub
        ((hasDerivAt_sin x).hasDerivWithinAt.const_mul (y' 0)) using 1
      ring
    · convert (h2.add ((hasDerivAt_sin x).hasDerivWithinAt.const_mul (y 0))).sub
        ((hasDerivAt_cos x).hasDerivWithinAt.const_mul (y' 0)) using 1
      simp only [Pi.zero_apply, Pi.one_apply]
      ring

#print axioms bvp_lin
#print axioms icc_mem_nhdsGE_of_mem
#print axioms hom_unique
#print axioms prim_exists
#print axioms wronskian_ne
#print axioms strut_shape

/-- One answer, none, or infinitely many. Take a linear second-order equation
`y'' + p y' + q y = g` on a finite interval `[0, L]` with `p`, `q`, `g` continuous there, and one
linear condition at each end, `α₀ y(0) + β₀ y'(0) = γ₀` and `α_L y(L) + β_L y'(L) = γ_L`, each a
genuine condition (its two weights not both 0). Then the problem has no solution, exactly one
solution, or infinitely many solutions; never exactly two, three or any other finite number. -/
theorem boundary_problem_one_none_or_infinitely_many (L : ℝ) (hL : 0 < L) (p q g : ℝ → ℝ)
    (hp : ContinuousOn p (Icc 0 L)) (hq : ContinuousOn q (Icc 0 L)) (hg : ContinuousOn g (Icc 0 L))
    (α₀ β₀ γ₀ αL βL γL : ℝ) (h₀ : α₀ ≠ 0 ∨ β₀ ≠ 0) (hLc : αL ≠ 0 ∨ βL ≠ 0) :
    bvpSolutions L p q g α₀ β₀ γ₀ αL βL γL = ∅ ∨
      (∃ f, bvpSolutions L p q g α₀ β₀ γ₀ αL βL γL = {f}) ∨
      (bvpSolutions L p q g α₀ β₀ γ₀ αL βL γL).Infinite := by
  by_cases hE : bvpSolutions L p q g α₀ β₀ γ₀ αL βL γL = ∅
  · exact Or.inl hE
  right
  obtain ⟨f₁, hf₁⟩ := nonempty_iff_ne_empty.2 hE
  by_cases hU : ∀ f ∈ bvpSolutions L p q g α₀ β₀ γ₀ αL βL γL, f = f₁
  · exact Or.inl ⟨f₁, eq_singleton_iff_unique_mem.2 ⟨hf₁, hU⟩⟩
  right
  push Not at hU
  obtain ⟨f₂, hf₂, hne⟩ := hU
  obtain ⟨y₁, y₁', h₁, hb₁, hL₁, hy₁⟩ := hf₁
  obtain ⟨y₂, y₂', h₂, hb₂, hL₂, hy₂⟩ := hf₂
  obtain ⟨x₀, hx₀⟩ := Function.ne_iff.1 hne
  refine infinite_of_injective_forall_mem
    (f := fun t : ℝ => fun x : Icc (0 : ℝ) L => (1 - t) * y₁ x + t * y₂ x) ?_ ?_
  · intro s t hst
    have h := congrFun hst x₀
    simp only at h
    have hd : y₂ x₀ - y₁ x₀ ≠ 0 := by
      rw [← hy₁, ← hy₂]; exact sub_ne_zero.2 hx₀
    have : (s - t) * (y₂ x₀ - y₁ x₀) = 0 := by linear_combination h
    exact sub_eq_zero.1 ((mul_eq_zero.1 this).resolve_right hd)
  · intro t
    have hc := bvp_lin h₁ h₂ (1 - t) t
    refine ⟨fun x => (1 - t) * y₁ x + t * y₂ x, fun x => (1 - t) * y₁' x + t * y₂' x,
      fun x hx => ⟨(hc x hx).1, (hc x hx).2.congr_deriv (by ring)⟩, ?_, ?_, fun x => rfl⟩
    · linear_combination (1 - t) * hb₁ + t * hb₂
    · linear_combination (1 - t) * hL₁ + t * hL₂

/-- One number decides which. With the same setting, let `u` and `v` solve the equation with
nothing on the right (`g = 0`), `u` starting at value 1 and slope 0, `v` at value 0 and slope 1.
Let `D` be the determinant of the end conditions applied to `u` and `v`:
`D = B₀(u) B_L(v) − B₀(v) B_L(u)`, where `B₀(y) = α₀ y(0) + β₀ y'(0)` and
`B_L(y) = α_L y(L) + β_L y'(L)`. If `D ≠ 0`, then for every pair of targets `γ₀`, `γ_L` the
problem has exactly one solution. If `D = 0`, then for every pair of targets it has none or
infinitely many. -/
theorem determinant_decides (L : ℝ) (hL : 0 < L) (p q g : ℝ → ℝ)
    (hp : ContinuousOn p (Icc 0 L)) (hq : ContinuousOn q (Icc 0 L)) (hg : ContinuousOn g (Icc 0 L))
    (α₀ β₀ αL βL : ℝ) (h₀ : α₀ ≠ 0 ∨ β₀ ≠ 0) (hLc : αL ≠ 0 ∨ βL ≠ 0)
    (u u' v v' : ℝ → ℝ)
    (hu : ∀ x ∈ Icc (0 : ℝ) L, HasDerivWithinAt u (u' x) (Icc 0 L) x ∧
      HasDerivWithinAt u' (-(p x * u' x) - q x * u x) (Icc 0 L) x)
    (hv : ∀ x ∈ Icc (0 : ℝ) L, HasDerivWithinAt v (v' x) (Icc 0 L) x ∧
      HasDerivWithinAt v' (-(p x * v' x) - q x * v x) (Icc 0 L) x)
    (hu0 : u 0 = 1) (hu'0 : u' 0 = 0) (hv0 : v 0 = 0) (hv'0 : v' 0 = 1) :
    let D := (α₀ * u 0 + β₀ * u' 0) * (αL * v L + βL * v' L) -
      (α₀ * v 0 + β₀ * v' 0) * (αL * u L + βL * u' L)
    (D ≠ 0 → ∀ γ₀ γL, ∃ f, bvpSolutions L p q g α₀ β₀ γ₀ αL βL γL = {f}) ∧
      (D = 0 → ∀ γ₀ γL, bvpSolutions L p q g α₀ β₀ γ₀ αL βL γL = ∅ ∨
        (bvpSolutions L p q g α₀ β₀ γ₀ αL βL γL).Infinite) := by
  intro D
  have hDdef : D = α₀ * (αL * v L + βL * v' L) - β₀ * (αL * u L + βL * u' L) := by
    show (α₀ * u 0 + β₀ * u' 0) * (αL * v L + βL * v' L) -
      (α₀ * v 0 + β₀ * v' 0) * (αL * u L + βL * u' L) = _
    rw [hu0, hu'0, hv0, hv'0]; ring
  have hu₀ : ∀ x ∈ Icc (0 : ℝ) L, HasDerivWithinAt u (u' x) (Icc 0 L) x ∧
      HasDerivWithinAt u' ((fun _ => (0 : ℝ)) x - p x * u' x - q x * u x) (Icc 0 L) x :=
    fun x hx => ⟨(hu x hx).1, (hu x hx).2.congr_deriv (by ring)⟩
  have hv₀ : ∀ x ∈ Icc (0 : ℝ) L, HasDerivWithinAt v (v' x) (Icc 0 L) x ∧
      HasDerivWithinAt v' ((fun _ => (0 : ℝ)) x - p x * v' x - q x * v x) (Icc 0 L) x :=
    fun x hx => ⟨(hv x hx).1, (hv x hx).2.congr_deriv (by ring)⟩
  refine ⟨fun hD γ₀ γL => ?_, fun hD γ₀ γL => ?_⟩
  · rw [hDdef] at hD
    -- uniqueness
    have huniq : ∀ f₁ ∈ bvpSolutions L p q g α₀ β₀ γ₀ αL βL γL,
        ∀ f₂ ∈ bvpSolutions L p q g α₀ β₀ γ₀ αL βL γL, f₁ = f₂ := by
      rintro f₁ ⟨y₁, y₁', h₁, hb₁, hL₁, hy₁⟩ f₂ ⟨y₂, y₂', h₂, hb₂, hL₂, hy₂⟩
      have hz : ∀ x ∈ Icc (0 : ℝ) L,
          HasDerivWithinAt (fun t => y₁ t - y₂ t - (y₁ 0 - y₂ 0) * u t - (y₁' 0 - y₂' 0) * v t)
            (y₁' x - y₂' x - (y₁ 0 - y₂ 0) * u' x - (y₁' 0 - y₂' 0) * v' x) (Icc 0 L) x ∧
          HasDerivWithinAt
            (fun t => y₁' t - y₂' t - (y₁ 0 - y₂ 0) * u' t - (y₁' 0 - y₂' 0) * v' t)
            (-(p x * (y₁' x - y₂' x - (y₁ 0 - y₂ 0) * u' x - (y₁' 0 - y₂' 0) * v' x)) -
              q x * (y₁ x - y₂ x - (y₁ 0 - y₂ 0) * u x - (y₁' 0 - y₂' 0) * v x)) (Icc 0 L) x := by
        intro x hx
        obtain ⟨h1a, h1b⟩ := h₁ x hx
        obtain ⟨h2a, h2b⟩ := h₂ x hx
        obtain ⟨hua, hub⟩ := hu x hx
        obtain ⟨hva, hvb⟩ := hv x hx
        refine ⟨((h1a.sub h2a).sub (hua.const_mul _)).sub (hva.const_mul _), ?_⟩
        convert ((h1b.sub h2b).sub (hub.const_mul (y₁ 0 - y₂ 0))).sub
          (hvb.const_mul (y₁' 0 - y₂' 0)) using 1
        ring
      have key := hom_unique hp hq _ _ hz (by rw [hu0, hv0]; ring)
        (by rw [hu'0, hv'0]; ring)
      have hkL := key L (right_mem_Icc.2 hL.le)
      obtain ⟨hzL, hz'L⟩ := hkL
      have e1 : α₀ * (y₁ 0 - y₂ 0) + β₀ * (y₁' 0 - y₂' 0) = 0 := by
        linear_combination hb₁ - hb₂
      have e2 : (αL * u L + βL * u' L) * (y₁ 0 - y₂ 0) +
          (αL * v L + βL * v' L) * (y₁' 0 - y₂' 0) = 0 := by
        linear_combination hL₁ - hL₂ - αL * hzL - βL * hz'L
      have ha : y₁ 0 - y₂ 0 = 0 := by
        have : (α₀ * (αL * v L + βL * v' L) - β₀ * (αL * u L + βL * u' L)) *
            (y₁ 0 - y₂ 0) = 0 := by
          linear_combination (αL * v L + βL * v' L) * e1 - β₀ * e2
        exact (mul_eq_zero.1 this).resolve_left hD
      have hb : y₁' 0 - y₂' 0 = 0 := by
        have : (α₀ * (αL * v L + βL * v' L) - β₀ * (αL * u L + βL * u' L)) *
            (y₁' 0 - y₂' 0) = 0 := by
          linear_combination α₀ * e2 - (αL * u L + βL * u' L) * e1
        exact (mul_eq_zero.1 this).resolve_left hD
      funext x
      have := (key x x.2).1
      rw [ha, hb] at this
      rw [hy₁, hy₂]
      linarith
    -- existence
    have hcu : ContinuousOn u (Icc 0 L) := fun x hx => (hu x hx).1.continuousWithinAt
    have hcv : ContinuousOn v (Icc 0 L) := fun x hx => (hv x hx).1.continuousWithinAt
    have hcu' : ContinuousOn u' (Icc 0 L) := fun x hx => (hu x hx).2.continuousWithinAt
    have hcv' : ContinuousOn v' (Icc 0 L) := fun x hx => (hv x hx).2.continuousWithinAt
    have hW := wronskian_ne hL.le hp hu hv (by rw [hu0, hu'0, hv0, hv'0]; ring)
    have hcW : ContinuousOn (fun x => u x * v' x - u' x * v x) (Icc 0 L) :=
      (hcu.mul hcv').sub (hcu'.mul hcv)
    obtain ⟨H1, -, hH1⟩ := prim_exists hL.le
      (h := fun x => v x * g x / (u x * v' x - u' x * v x)) ((hcv.mul hg).div hcW hW)
    obtain ⟨H2, -, hH2⟩ := prim_exists hL.le
      (h := fun x => u x * g x / (u x * v' x - u' x * v x)) ((hcu.mul hg).div hcW hW)
    obtain ⟨yp, yp', hyp⟩ : ∃ yp yp' : ℝ → ℝ, ∀ x ∈ Icc (0 : ℝ) L,
        HasDerivWithinAt yp (yp' x) (Icc 0 L) x ∧
        HasDerivWithinAt yp' (g x - p x * yp' x - q x * yp x) (Icc 0 L) x := by
      refine ⟨fun t => -u t * H1 t + v t * H2 t, fun t => -u' t * H1 t + v' t * H2 t,
        fun x hx => ?_⟩
      obtain ⟨hu1, hu2⟩ := hu x hx
      obtain ⟨hv1, hv2⟩ := hv x hx
      have hWx := hW x hx
      constructor
      · convert (hu1.neg.mul (hH1 x hx)).add (hv1.mul (hH2 x hx)) using 1
        simp only [Pi.neg_apply]
        ring
      · convert (hu2.neg.mul (hH1 x hx)).add (hv2.mul (hH2 x hx)) using 1
        simp only [Pi.neg_apply]
        have e : -u' x * (v x * g x / (u x * v' x - u' x * v x)) +
            v' x * (u x * g x / (u x * v' x - u' x * v x)) = g x := by
          field_simp
          ring
        linear_combination -e
    obtain ⟨a, b, hab1, hab2⟩ : ∃ a b : ℝ,
        α₀ * a + β₀ * b = γ₀ - (α₀ * yp 0 + β₀ * yp' 0) ∧
        (αL * u L + βL * u' L) * a + (αL * v L + βL * v' L) * b =
          γL - (αL * yp L + βL * yp' L) := by
      have cramer : ∀ A B C E c₀ c₁ : ℝ, A * E - B * C ≠ 0 →
          ∃ a b : ℝ, A * a + B * b = c₀ ∧ C * a + E * b = c₁ := by
        intro A B C E c₀ c₁ h
        refine ⟨(c₀ * E - B * c₁) / (A * E - B * C), (A * c₁ - c₀ * C) / (A * E - B * C), ?_, ?_⟩
        · rw [mul_div_assoc', mul_div_assoc', ← add_div, div_eq_iff h]; ring
        · rw [mul_div_assoc', mul_div_assoc', ← add_div, div_eq_iff h]; ring
      exact cramer _ _ _ _ _ _ hD
    have hc1 := bvp_lin hu₀ hv₀ a b
    have hc2 := bvp_lin hyp hc1 1 1
    refine ⟨fun x => yp x + (a * u x + b * v x),
      eq_singleton_iff_unique_mem.2 ⟨?_, fun f hf => huniq f hf _ ?_⟩⟩ <;>
    · refine ⟨fun t => 1 * yp t + 1 * (a * u t + b * v t),
        fun t => 1 * yp' t + 1 * (a * u' t + b * v' t),
        fun x hx => ⟨(hc2 x hx).1, (hc2 x hx).2.congr_deriv (by ring)⟩, ?_, ?_,
        fun x => by simp⟩
      · beta_reduce; rw [hu0, hu'0, hv0, hv'0]; linear_combination hab1
      · beta_reduce; linear_combination hab2
  · rw [hDdef] at hD
    rcases boundary_problem_one_none_or_infinitely_many L hL p q g hp hq hg α₀ β₀ γ₀ αL βL γL
      h₀ hLc with h | ⟨f, hf⟩ | h
    · exact Or.inl h
    · exfalso
      have hmem : f ∈ bvpSolutions L p q g α₀ β₀ γ₀ αL βL γL := hf ▸ mem_singleton f
      obtain ⟨y, y', hy, hb0, hbL, hfy⟩ := hmem
      have hc1 := bvp_lin hu₀ hv₀ β₀ (-α₀)
      have hc2 := bvp_lin hy hc1 1 1
      have hmem2 : (fun x : Icc (0 : ℝ) L => 1 * y x + 1 * (β₀ * u x + -α₀ * v x)) ∈
          bvpSolutions L p q g α₀ β₀ γ₀ αL βL γL := by
        refine ⟨fun t => 1 * y t + 1 * (β₀ * u t + -α₀ * v t),
          fun t => 1 * y' t + 1 * (β₀ * u' t + -α₀ * v' t),
          fun x hx => ⟨(hc2 x hx).1, (hc2 x hx).2.congr_deriv (by ring)⟩, ?_, ?_,
          fun x => rfl⟩
        · beta_reduce; rw [hu0, hu'0, hv0, hv'0]; linear_combination hb0
        · beta_reduce; linear_combination hbL - hD
      rw [hf, mem_singleton_iff] at hmem2
      have hw : ∀ x ∈ Icc (0 : ℝ) L, β₀ * u x + -α₀ * v x = 0 := by
        intro x hx
        have h1 := congrFun hmem2 ⟨x, hx⟩
        rw [hfy] at h1
        simp only at h1
        linarith
      have hβ : β₀ = 0 := by
        have := hw 0 (left_mem_Icc.2 hL.le)
        rw [hu0, hv0] at this; linarith
      have hα : α₀ = 0 := by
        have hd1 := (hc1 0 (left_mem_Icc.2 hL.le)).1
        have hd2 : HasDerivWithinAt (fun t => β₀ * u t + -α₀ * v t) 0 (Icc 0 L) 0 :=
          (hasDerivWithinAt_const (0 : ℝ) (Icc 0 L) (0 : ℝ)).congr_of_mem hw
            (left_mem_Icc.2 hL.le)
        have := (uniqueDiffOn_Icc hL 0 (left_mem_Icc.2 hL.le)).eq_deriv _ hd1 hd2
        rw [hu'0, hv'0] at this; linarith
      rcases h₀ with h | h <;> contradiction
    · exact Or.inr h

/-- Three struts, one law `y'' + y = 0`, foot pinned at `y(0) = 0`. The 1 m strut with its top
pushed 1 cm has exactly one shape, `sin x / sin 1`. The π m strut with both ends on the line
takes exactly the shapes `C sin x`, one for every real `C`. The π m strut with its top pushed
1 cm has no shape at all. -/
theorem three_struts :
    bvpSolutions 1 0 1 0 1 0 0 1 0 1 = {fun x : Icc (0 : ℝ) 1 => sin (x : ℝ) / sin 1} ∧
      bvpSolutions π 0 1 0 1 0 0 1 0 0 =
        range (fun C : ℝ => fun x : Icc (0 : ℝ) π => C * sin (x : ℝ)) ∧
      bvpSolutions π 0 1 0 1 0 0 1 0 1 = ∅ := by
  refine ⟨?_, ?_, ?_⟩
  · have hs1 : sin 1 ≠ 0 := (sin_pos_of_pos_of_lt_pi one_pos (by linarith [two_le_pi])).ne'
    have key := determinant_decides 1 one_pos 0 1 0 continuousOn_const continuousOn_const
      continuousOn_const 1 0 1 0 (Or.inl one_ne_zero) (Or.inl one_ne_zero)
      cos (fun x => -sin x) sin cos
      (fun x _ => ⟨(hasDerivAt_cos x).hasDerivWithinAt,
        (hasDerivAt_sin x).neg.hasDerivWithinAt.congr_deriv (by simp)⟩)
      (fun x _ => ⟨(hasDerivAt_sin x).hasDerivWithinAt,
        (hasDerivAt_cos x).hasDerivWithinAt.congr_deriv (by simp)⟩)
      cos_zero (by simp) sin_zero cos_zero
    obtain ⟨f, hf⟩ := key.1 (by simpa using hs1) 0 1
    have hmem : (fun x : Icc (0 : ℝ) 1 => sin (x : ℝ) / sin 1) ∈
        bvpSolutions 1 0 1 0 1 0 0 1 0 1 := by
      refine ⟨fun x => sin x / sin 1, fun x => cos x / sin 1, fun x _ =>
        ⟨((hasDerivAt_sin x).div_const _).hasDerivWithinAt,
          ((hasDerivAt_cos x).div_const _).hasDerivWithinAt.congr_deriv (by simp; ring)⟩,
        by simp, by simp [hs1], fun x => rfl⟩
    rw [hf] at hmem ⊢
    rw [mem_singleton_iff.1 hmem]
  · ext f
    constructor
    · rintro ⟨y, y', hy, hb0, -, hfy⟩
      have hs := strut_shape y y' hy
      have hy0 : y 0 = 0 := by simpa using hb0
      refine ⟨y' 0, funext fun x => ?_⟩
      rw [hfy, hs x x.2, hy0]
      simp
    · rintro ⟨C, rfl⟩
      exact ⟨fun x => C * sin x, fun x => C * cos x, fun x _ =>
        ⟨((hasDerivAt_sin x).const_mul C).hasDerivWithinAt,
          ((hasDerivAt_cos x).const_mul C).hasDerivWithinAt.congr_deriv (by simp)⟩,
        by simp, by simp, fun x => rfl⟩
  · ext f
    simp only [mem_empty_iff_false, iff_false]
    rintro ⟨y, y', hy, hb0, hbL, -⟩
    have hs := strut_shape y y' hy π (right_mem_Icc.2 Real.pi_pos.le)
    have hy0 : y 0 = 0 := by simpa using hb0
    rw [hy0, cos_pi, sin_pi] at hs
    simp [hs] at hbL

-- The determinant for value conditions on y = A cos x + B sin x: rows (1, 0) and (cos L, sin L) give D = sin L.
example (L : ℝ) : Matrix.det !![1, 0; cos L, sin L] = sin L := by
  simp [Matrix.det_fin_two]

-- Step 3: at the π m top, cos π = −1 and sin π = 0, so y(π) = −A whatever B is.
example : cos π = -1 ∧ sin π = 0 := by norm_num

-- Step 5, Neumann ends on the π m strut: the slope −A sin x + B cos x is B at 0 and −B at π.
example (A B : ℝ) : -A * sin 0 + B * cos 0 = B ∧ -A * sin π + B * cos π = -B := by norm_num

#print axioms boundary_problem_one_none_or_infinitely_many
#print axioms determinant_decides
#print axioms three_struts
