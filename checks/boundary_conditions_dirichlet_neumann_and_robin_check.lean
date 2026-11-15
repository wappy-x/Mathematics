-- Boundary conditions: on a rectangular plate whose temperature solves Laplace's equation, the heat flows given on all four edges add up to zero, two solutions with the same edge flows differ by a constant, and the air-cooled (Robin) plate solves its problem and tends to the held plate as the film coefficient grows.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.MeasureTheory.Integral.DivergenceTheorem
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Tactic.NormNum

open Real Set Filter Topology

/-- The total bend of the temperature `u` at the point `(x, y)`, the Laplacian
`Δu = u_xx + u_yy`, each second slope taken with the other variable held still. -/
noncomputable def laplacian2 (u : ℝ → ℝ → ℝ) (x y : ℝ) : ℝ :=
  deriv (fun s => deriv (fun r => u r y) s) x + deriv (fun s => deriv (fun r => u x r) s) y

/-- The card's plate with an air-cooled top: sides held at 20 C, bottom edge at
`20 + 60 sin(πx)` C, top edge cooled by 20 C air with film coefficient `h` and steel conductivity
`k`, so `u = 20 + 60 sin(πx) Y(y)` with
`Y(y) = (π cosh π(1 - y) + (h/k) sinh π(1 - y)) / (π cosh π + (h/k) sinh π)`. -/
noncomputable def airCooledPlate (h k : ℝ) (x y : ℝ) : ℝ :=
  20 + 60 * sin (π * x) *
    ((π * cosh (π * (1 - y)) + h / k * sinh (π * (1 - y))) / (π * cosh π + h / k * sinh π))

/-- A partial slope in the first variable is the full derivative applied to `(1, 0)`. -/
lemma bc_deriv_fst (F : ℝ × ℝ → ℝ) (x y : ℝ) (hF : DifferentiableAt ℝ F (x, y)) :
    deriv (fun r => F (r, y)) x = fderiv ℝ F (x, y) (1, 0) := by
  have h1 : HasDerivAt (fun r : ℝ => (r, y)) ((1 : ℝ), (0 : ℝ)) x :=
    (hasDerivAt_id x).prodMk (hasDerivAt_const x y)
  exact (hF.hasFDerivAt.comp_hasDerivAt x h1).deriv

/-- A partial slope in the second variable is the full derivative applied to `(0, 1)`. -/
lemma bc_deriv_snd (F : ℝ × ℝ → ℝ) (x y : ℝ) (hF : DifferentiableAt ℝ F (x, y)) :
    deriv (fun r => F (x, r)) y = fderiv ℝ F (x, y) (0, 1) := by
  have h1 : HasDerivAt (fun r : ℝ => (x, r)) ((0 : ℝ), (1 : ℝ)) y :=
    (hasDerivAt_const y x).prodMk (hasDerivAt_id y)
  exact (hF.hasFDerivAt.comp_hasDerivAt y h1).deriv

/-- A directional slope of a twice continuously differentiable function is continuously
differentiable. -/
lemma bc_c1 {F : ℝ × ℝ → ℝ} (hF : ContDiff ℝ 2 F) (v : ℝ × ℝ) :
    ContDiff ℝ 1 (fun p => fderiv ℝ F p v) :=
  (hF.fderiv_right (m := 1) (by norm_num)).clm_apply contDiff_const

/-- The Laplacian `laplacian2` written with full derivatives. -/
lemma bc_lap (u : ℝ → ℝ → ℝ) (hu : ContDiff ℝ 2 (Function.uncurry u)) (x y : ℝ) :
    laplacian2 u x y =
      fderiv ℝ (fun p => fderiv ℝ (Function.uncurry u) p (1, 0)) (x, y) (1, 0) +
      fderiv ℝ (fun p => fderiv ℝ (Function.uncurry u) p (0, 1)) (x, y) (0, 1) := by
  have hd : Differentiable ℝ (Function.uncurry u) := hu.differentiable (by norm_num)
  have e1 : (fun s => deriv (fun r => u r y) s) =
      fun s => (fun p => fderiv ℝ (Function.uncurry u) p (1, 0)) (s, y) := by
    funext s; exact bc_deriv_fst (Function.uncurry u) s y (hd _)
  have e2 : (fun s => deriv (fun r => u x r) s) =
      fun s => (fun p => fderiv ℝ (Function.uncurry u) p (0, 1)) (x, s) := by
    funext s; exact bc_deriv_snd (Function.uncurry u) x s (hd _)
  unfold laplacian2
  rw [e1, e2, bc_deriv_fst _ x y (((bc_c1 hu _).differentiable one_ne_zero) _),
    bc_deriv_snd _ x y (((bc_c1 hu _).differentiable one_ne_zero) _)]

/-- The full-derivative Laplacian is zero on the closed rectangle once it is zero inside. -/
lemma bc_lap_closed (F : ℝ × ℝ → ℝ) (hF : ContDiff ℝ 2 F) (W H : ℝ) (hW : 0 < W) (hH : 0 < H)
    (h0 : ∀ p ∈ Ioo 0 W ×ˢ Ioo 0 H,
      fderiv ℝ (fun q => fderiv ℝ F q (1, 0)) p (1, 0) +
        fderiv ℝ (fun q => fderiv ℝ F q (0, 1)) p (0, 1) = 0) :
    ∀ p ∈ Icc 0 W ×ˢ Icc 0 H,
      fderiv ℝ (fun q => fderiv ℝ F q (1, 0)) p (1, 0) +
        fderiv ℝ (fun q => fderiv ℝ F q (0, 1)) p (0, 1) = 0 := by
  have hc : Continuous fun p => fderiv ℝ (fun q => fderiv ℝ F q (1, 0)) p (1, 0) +
      fderiv ℝ (fun q => fderiv ℝ F q (0, 1)) p (0, 1) :=
    (((bc_c1 hF _).continuous_fderiv one_ne_zero).clm_apply continuous_const).add
      (((bc_c1 hF _).continuous_fderiv one_ne_zero).clm_apply continuous_const)
  have hcl : closure (Ioo 0 W ×ˢ Ioo 0 H) = Icc 0 W ×ˢ Icc 0 H := by
    rw [closure_prod_eq, closure_Ioo hW.ne, closure_Ioo hH.ne]
  intro p hp
  rw [← hcl] at hp
  exact ((isClosed_eq hc continuous_const).closure_subset_iff.2 h0) hp

/-- A continuous function that is never negative and has zero integral on `[a, b]`
is zero on `[a, b]`. -/
lemma bc_zero_of_integral1 (g : ℝ → ℝ) (a b : ℝ) (hab : a < b) (hg : ContinuousOn g (Icc a b))
    (hnn : ∀ x ∈ Icc a b, 0 ≤ g x) (h0 : ∫ x in a..b, g x = 0) : ∀ x ∈ Icc a b, g x = 0 := by
  intro x hx
  by_contra hne
  have := intervalIntegral.integral_pos hab hg (fun y hy => hnn y (Ioc_subset_Icc_self hy))
    ⟨x, hx, lt_of_le_of_ne (hnn x hx) (Ne.symm hne)⟩
  linarith

/-- The two-variable version on a rectangle. -/
lemma bc_zero_of_integral2 (E : ℝ → ℝ → ℝ) (hE : Continuous (Function.uncurry E))
    (hnn : ∀ x y, 0 ≤ E x y) (W H : ℝ) (hW : 0 < W) (hH : 0 < H)
    (h0 : ∫ x in (0 : ℝ)..W, ∫ y in (0 : ℝ)..H, E x y = 0) :
    ∀ x ∈ Icc 0 W, ∀ y ∈ Icc 0 H, E x y = 0 := by
  have hψ : ∀ x ∈ Icc 0 W, ∫ y in (0 : ℝ)..H, E x y = 0 :=
    bc_zero_of_integral1 (fun x => ∫ y in (0 : ℝ)..H, E x y) 0 W hW
      (intervalIntegral.continuous_parametric_intervalIntegral_of_continuous' hE 0 H).continuousOn
      (fun x _ => intervalIntegral.integral_nonneg hH.le (fun y _ => hnn x y)) h0
  intro x hx
  exact bc_zero_of_integral1 (E x) 0 H hH (hE.uncurry_left x).continuousOn
    (fun y _ => hnn x y) (hψ x hx)

/-- **The Neumann compatibility condition, the card's main claim (Step 4).** Take a rectangular
plate `0 ≤ x ≤ W`, `0 ≤ y ≤ H` with `W > 0` and `H > 0`, a twice continuously differentiable
temperature `u` that solves Laplace's equation `u_xx + u_yy = 0` inside (no heater inside), and
a conductivity `k`. Suppose every edge has a given heat flow `q` leaving it, `-k ∂u/∂n = q`, where
the outward normal makes `∂u/∂n` equal `-u_y` on the bottom, `u_y` on the top, `-u_x` on the left
side and `u_x` on the right side. Then going once round the edge, the flows add up to zero:
`∮ q ds = 0`. Whatever comes in must go out. -/
theorem neumann_flows_round_edge_sum_to_zero (W H : ℝ) (hW : 0 < W) (hH : 0 < H) (k : ℝ)
    (u : ℝ → ℝ → ℝ) (hu : ContDiff ℝ 2 (Function.uncurry u))
    (hlap : ∀ x ∈ Ioo 0 W, ∀ y ∈ Ioo 0 H, laplacian2 u x y = 0)
    (qB qT qL qR : ℝ → ℝ)
    (hB : ∀ x ∈ Icc 0 W, -k * -deriv (fun r => u x r) 0 = qB x)
    (hT : ∀ x ∈ Icc 0 W, -k * deriv (fun r => u x r) H = qT x)
    (hL : ∀ y ∈ Icc 0 H, -k * -deriv (fun r => u r y) 0 = qL y)
    (hR : ∀ y ∈ Icc 0 H, -k * deriv (fun r => u r y) W = qR y) :
    (∫ x in (0 : ℝ)..W, qB x) + (∫ x in (0 : ℝ)..W, qT x)
      + (∫ y in (0 : ℝ)..H, qL y) + (∫ y in (0 : ℝ)..H, qR y) = 0 := by
  set U := Function.uncurry u with hUdef
  have hUd : Differentiable ℝ U := hu.differentiable (by norm_num)
  have hx1 := bc_c1 hu (1, 0)
  have hy1 := bc_c1 hu (0, 1)
  have hcont : Continuous fun p => fderiv ℝ (fun q => fderiv ℝ U q (1, 0)) p (1, 0) +
      fderiv ℝ (fun q => fderiv ℝ U q (0, 1)) p (0, 1) :=
    ((hx1.continuous_fderiv one_ne_zero).clm_apply continuous_const).add
      ((hy1.continuous_fderiv one_ne_zero).clm_apply continuous_const)
  have hdiv := MeasureTheory.integral2_divergence_prod_of_hasFDerivAt (fun p => fderiv ℝ U p (1, 0))
    (fun p => fderiv ℝ U p (0, 1)) (fderiv ℝ (fun p => fderiv ℝ U p (1, 0)))
    (fderiv ℝ (fun p => fderiv ℝ U p (0, 1))) 0 0 W H hx1.continuous.continuousOn
    hy1.continuous.continuousOn
    (fun p _ => ((hx1.differentiable one_ne_zero) p).hasFDerivAt)
    (fun p _ => ((hy1.differentiable one_ne_zero) p).hasFDerivAt)
    (ContinuousOn.integrableOn_compact (isCompact_uIcc.prod isCompact_uIcc) hcont.continuousOn)
  have hzero := bc_lap_closed U hu W H hW hH (fun p hp => by
    obtain ⟨hx, hy⟩ := hp
    have := hlap p.1 hx p.2 hy
    rwa [bc_lap u hu] at this)
  have hlhs : (∫ x in (0 : ℝ)..W, ∫ y in (0 : ℝ)..H,
      fderiv ℝ (fun p => fderiv ℝ U p (1, 0)) (x, y) (1, 0) +
        fderiv ℝ (fun p => fderiv ℝ U p (0, 1)) (x, y) (0, 1)) = 0 := by
    rw [intervalIntegral.integral_congr (g := fun _ => (0 : ℝ)), intervalIntegral.integral_zero]
    intro x hx
    rw [uIcc_of_le hW.le] at hx
    simp only
    rw [intervalIntegral.integral_congr (g := fun _ => (0 : ℝ)), intervalIntegral.integral_zero]
    intro y hy
    rw [uIcc_of_le hH.le] at hy
    exact hzero (x, y) ⟨hx, hy⟩
  have eB : ∫ x in (0 : ℝ)..W, qB x = k * ∫ x in (0 : ℝ)..W, fderiv ℝ U (x, 0) (0, 1) := by
    rw [← intervalIntegral.integral_const_mul]
    apply intervalIntegral.integral_congr
    intro x hx
    rw [uIcc_of_le hW.le] at hx
    simp only
    rw [← hB x hx]
    rw [show deriv (fun r => u x r) 0 = fderiv ℝ U (x, 0) (0, 1) from bc_deriv_snd U x 0 (hUd _)]
    ring
  have eT : ∫ x in (0 : ℝ)..W, qT x = -k * ∫ x in (0 : ℝ)..W, fderiv ℝ U (x, H) (0, 1) := by
    rw [← intervalIntegral.integral_const_mul]
    apply intervalIntegral.integral_congr
    intro x hx
    rw [uIcc_of_le hW.le] at hx
    simp only
    rw [← hT x hx]
    rw [show deriv (fun r => u x r) H = fderiv ℝ U (x, H) (0, 1) from bc_deriv_snd U x H (hUd _)]
  have eL : ∫ y in (0 : ℝ)..H, qL y = k * ∫ y in (0 : ℝ)..H, fderiv ℝ U (0, y) (1, 0) := by
    rw [← intervalIntegral.integral_const_mul]
    apply intervalIntegral.integral_congr
    intro y hy
    rw [uIcc_of_le hH.le] at hy
    simp only
    rw [← hL y hy]
    rw [show deriv (fun r => u r y) 0 = fderiv ℝ U (0, y) (1, 0) from bc_deriv_fst U 0 y (hUd _)]
    ring
  have eR : ∫ y in (0 : ℝ)..H, qR y = -k * ∫ y in (0 : ℝ)..H, fderiv ℝ U (W, y) (1, 0) := by
    rw [← intervalIntegral.integral_const_mul]
    apply intervalIntegral.integral_congr
    intro y hy
    rw [uIcc_of_le hH.le] at hy
    simp only
    rw [← hR y hy]
    rw [show deriv (fun r => u r y) W = fderiv ℝ U (W, y) (1, 0) from bc_deriv_fst U W y (hUd _)]
  rw [hlhs] at hdiv
  rw [eB, eT, eL, eR]
  linear_combination k * hdiv

/-- **Flows alone fix the answer only up to a constant (Step 5).** On the rectangular plate
`0 ≤ x ≤ W`, `0 ≤ y ≤ H`, let `u` and `v` be twice continuously differentiable temperatures that
both solve Laplace's equation inside and have the same outward slope `∂u/∂n = ∂v/∂n` at every
point of all four edges. Then they differ by one constant `C` across the whole plate; and adding
any constant to a solution gives another one with the same edge flows, so the constant is free. -/
theorem same_edge_flows_differ_by_constant (W H : ℝ) (hW : 0 < W) (hH : 0 < H)
    (u v : ℝ → ℝ → ℝ) (hu : ContDiff ℝ 2 (Function.uncurry u))
    (hv : ContDiff ℝ 2 (Function.uncurry v))
    (hu_lap : ∀ x ∈ Ioo 0 W, ∀ y ∈ Ioo 0 H, laplacian2 u x y = 0)
    (hv_lap : ∀ x ∈ Ioo 0 W, ∀ y ∈ Ioo 0 H, laplacian2 v x y = 0)
    (hB : ∀ x ∈ Icc 0 W, deriv (fun r => u x r) 0 = deriv (fun r => v x r) 0)
    (hT : ∀ x ∈ Icc 0 W, deriv (fun r => u x r) H = deriv (fun r => v x r) H)
    (hL : ∀ y ∈ Icc 0 H, deriv (fun r => u r y) 0 = deriv (fun r => v r y) 0)
    (hR : ∀ y ∈ Icc 0 H, deriv (fun r => u r y) W = deriv (fun r => v r y) W) :
    (∃ C : ℝ, ∀ x ∈ Icc 0 W, ∀ y ∈ Icc 0 H, u x y = v x y + C) ∧
    (∀ C : ℝ, (∀ x y, laplacian2 (fun x y => u x y + C) x y = laplacian2 u x y) ∧
      (∀ x y, deriv (fun r => u x r + C) y = deriv (fun r => u x r) y) ∧
      (∀ x y, deriv (fun r => u r y + C) x = deriv (fun r => u r y) x)) := by
  refine ⟨?_, fun C => ⟨fun x y => by simp only [laplacian2, deriv_add_const],
    fun x y => deriv_add_const _, fun x y => deriv_add_const _⟩⟩
  set U := Function.uncurry u with hUdef
  set V := Function.uncurry v with hVdef
  set Wf : ℝ × ℝ → ℝ := fun q => U q - V q with hWfdef
  have hw : ContDiff ℝ 2 Wf := hu.sub hv
  have hUd : Differentiable ℝ U := hu.differentiable (by norm_num)
  have hVd : Differentiable ℝ V := hv.differentiable (by norm_num)
  have hWd : Differentiable ℝ Wf := hw.differentiable (by norm_num)
  -- slopes of the difference are differences of slopes
  have hsub : ∀ (F G : ℝ × ℝ → ℝ), Differentiable ℝ F → Differentiable ℝ G → ∀ v : ℝ × ℝ,
      (fun p => fderiv ℝ (fun q => F q - G q) p v) =
        fun p => fderiv ℝ F p v - fderiv ℝ G p v := by
    intro F G hF hG v
    funext p
    have d : HasFDerivAt (fun q => F q - G q) (fderiv ℝ F p - fderiv ℝ G p) p :=
      (hF p).hasFDerivAt.sub (hG p).hasFDerivAt
    rw [d.fderiv]
    rfl
  have hWx : (fun p => fderiv ℝ Wf p (1, 0)) =
      fun p => fderiv ℝ U p (1, 0) - fderiv ℝ V p (1, 0) := hsub U V hUd hVd (1, 0)
  have hWy : (fun p => fderiv ℝ Wf p (0, 1)) =
      fun p => fderiv ℝ U p (0, 1) - fderiv ℝ V p (0, 1) := hsub U V hUd hVd (0, 1)
  -- the difference has zero Laplacian on the closed plate
  have hlapU := bc_lap_closed U hu W H hW hH (fun p hp => by
    obtain ⟨hx, hy⟩ := hp
    have := hu_lap p.1 hx p.2 hy
    rwa [bc_lap u hu] at this)
  have hlapV := bc_lap_closed V hv W H hW hH (fun p hp => by
    obtain ⟨hx, hy⟩ := hp
    have := hv_lap p.1 hx p.2 hy
    rwa [bc_lap v hv] at this)
  have hlapW : ∀ p ∈ Icc 0 W ×ˢ Icc 0 H,
      fderiv ℝ (fun q => fderiv ℝ Wf q (1, 0)) p (1, 0) +
        fderiv ℝ (fun q => fderiv ℝ Wf q (0, 1)) p (0, 1) = 0 := by
    intro p hp
    have d1 := hsub _ _ ((bc_c1 hu (1, 0)).differentiable one_ne_zero)
      ((bc_c1 hv (1, 0)).differentiable one_ne_zero) (1, 0)
    have d2 := hsub _ _ ((bc_c1 hu (0, 1)).differentiable one_ne_zero)
      ((bc_c1 hv (0, 1)).differentiable one_ne_zero) (0, 1)
    rw [hWx, hWy]
    rw [show fderiv ℝ (fun p => fderiv ℝ U p (1, 0) - fderiv ℝ V p (1, 0)) p (1, 0) =
      fderiv ℝ (fun p => fderiv ℝ U p (1, 0)) p (1, 0) -
        fderiv ℝ (fun p => fderiv ℝ V p (1, 0)) p (1, 0) from congrFun d1 p,
      show fderiv ℝ (fun p => fderiv ℝ U p (0, 1) - fderiv ℝ V p (0, 1)) p (0, 1) =
      fderiv ℝ (fun p => fderiv ℝ U p (0, 1)) p (0, 1) -
        fderiv ℝ (fun p => fderiv ℝ V p (0, 1)) p (0, 1) from congrFun d2 p]
    have h1 := hlapU p hp
    have h2 := hlapV p hp
    linarith
  -- edge slopes of the difference vanish
  have eB : ∀ x ∈ Icc 0 W, fderiv ℝ Wf (x, 0) (0, 1) = 0 := by
    intro x hx
    have h := hB x hx
    rw [show deriv (fun r => u x r) 0 = fderiv ℝ U (x, 0) (0, 1) from
      bc_deriv_snd U x 0 (hUd _), show deriv (fun r => v x r) 0 = fderiv ℝ V (x, 0) (0, 1) from
      bc_deriv_snd V x 0 (hVd _)] at h
    have := congrFun hWy (x, 0)
    rw [this, h, sub_self]
  have eT : ∀ x ∈ Icc 0 W, fderiv ℝ Wf (x, H) (0, 1) = 0 := by
    intro x hx
    have h := hT x hx
    rw [show deriv (fun r => u x r) H = fderiv ℝ U (x, H) (0, 1) from
      bc_deriv_snd U x H (hUd _), show deriv (fun r => v x r) H = fderiv ℝ V (x, H) (0, 1) from
      bc_deriv_snd V x H (hVd _)] at h
    have := congrFun hWy (x, H)
    rw [this, h, sub_self]
  have eL : ∀ y ∈ Icc 0 H, fderiv ℝ Wf (0, y) (1, 0) = 0 := by
    intro y hy
    have h := hL y hy
    rw [show deriv (fun r => u r y) 0 = fderiv ℝ U (0, y) (1, 0) from
      bc_deriv_fst U 0 y (hUd _), show deriv (fun r => v r y) 0 = fderiv ℝ V (0, y) (1, 0) from
      bc_deriv_fst V 0 y (hVd _)] at h
    have := congrFun hWx (0, y)
    rw [this, h, sub_self]
  have eR : ∀ y ∈ Icc 0 H, fderiv ℝ Wf (W, y) (1, 0) = 0 := by
    intro y hy
    have h := hR y hy
    rw [show deriv (fun r => u r y) W = fderiv ℝ U (W, y) (1, 0) from
      bc_deriv_fst U W y (hUd _), show deriv (fun r => v r y) W = fderiv ℝ V (W, y) (1, 0) from
      bc_deriv_fst V W y (hVd _)] at h
    have := congrFun hWx (W, y)
    rw [this, h, sub_self]
  -- the energy identity from the divergence theorem
  have hx1 := bc_c1 hw (1, 0)
  have hy1 := bc_c1 hw (0, 1)
  have hWc : Continuous Wf := hw.continuous
  have hWfc : Continuous (fderiv ℝ Wf) := hw.continuous_fderiv (by norm_num)
  have hx1c : Continuous (fderiv ℝ (fun p => fderiv ℝ Wf p (1, 0))) :=
    hx1.continuous_fderiv one_ne_zero
  have hy1c : Continuous (fderiv ℝ (fun p => fderiv ℝ Wf p (0, 1))) :=
    hy1.continuous_fderiv one_ne_zero
  have hcont : Continuous fun p =>
      (Wf p • fderiv ℝ (fun q => fderiv ℝ Wf q (1, 0)) p + fderiv ℝ Wf p (1, 0) • fderiv ℝ Wf p)
        (1, 0) +
      (Wf p • fderiv ℝ (fun q => fderiv ℝ Wf q (0, 1)) p + fderiv ℝ Wf p (0, 1) • fderiv ℝ Wf p)
        (0, 1) := by
    have a1 : Continuous fun p => fderiv ℝ Wf p (1, 0) := hx1.continuous
    have a2 : Continuous fun p => fderiv ℝ Wf p (0, 1) := hy1.continuous
    exact (((hWc.smul hx1c).add (a1.smul hWfc)).clm_apply continuous_const).add
      (((hWc.smul hy1c).add (a2.smul hWfc)).clm_apply continuous_const)
  have hdiv := MeasureTheory.integral2_divergence_prod_of_hasFDerivAt
    (fun p => Wf p * fderiv ℝ Wf p (1, 0)) (fun p => Wf p * fderiv ℝ Wf p (0, 1))
    (fun p => Wf p • fderiv ℝ (fun q => fderiv ℝ Wf q (1, 0)) p +
      fderiv ℝ Wf p (1, 0) • fderiv ℝ Wf p)
    (fun p => Wf p • fderiv ℝ (fun q => fderiv ℝ Wf q (0, 1)) p +
      fderiv ℝ Wf p (0, 1) • fderiv ℝ Wf p) 0 0 W H
    (hWc.mul hx1.continuous).continuousOn (hWc.mul hy1.continuous).continuousOn
    (fun p _ => (hWd p).hasFDerivAt.mul ((hx1.differentiable one_ne_zero) p).hasFDerivAt)
    (fun p _ => (hWd p).hasFDerivAt.mul ((hy1.differentiable one_ne_zero) p).hasFDerivAt)
    (ContinuousOn.integrableOn_compact (isCompact_uIcc.prod isCompact_uIcc) hcont.continuousOn)
  have hb1 : (∫ x in (0 : ℝ)..W, Wf (x, H) * fderiv ℝ Wf (x, H) (0, 1)) = 0 := by
    rw [intervalIntegral.integral_congr (g := fun _ => (0 : ℝ)), intervalIntegral.integral_zero]
    intro x hx
    rw [uIcc_of_le hW.le] at hx
    simp only [eT x hx, mul_zero]
  have hb2 : (∫ x in (0 : ℝ)..W, Wf (x, 0) * fderiv ℝ Wf (x, 0) (0, 1)) = 0 := by
    rw [intervalIntegral.integral_congr (g := fun _ => (0 : ℝ)), intervalIntegral.integral_zero]
    intro x hx
    rw [uIcc_of_le hW.le] at hx
    simp only [eB x hx, mul_zero]
  have hb3 : (∫ y in (0 : ℝ)..H, Wf (W, y) * fderiv ℝ Wf (W, y) (1, 0)) = 0 := by
    rw [intervalIntegral.integral_congr (g := fun _ => (0 : ℝ)), intervalIntegral.integral_zero]
    intro y hy
    rw [uIcc_of_le hH.le] at hy
    simp only [eR y hy, mul_zero]
  have hb4 : (∫ y in (0 : ℝ)..H, Wf (0, y) * fderiv ℝ Wf (0, y) (1, 0)) = 0 := by
    rw [intervalIntegral.integral_congr (g := fun _ => (0 : ℝ)), intervalIntegral.integral_zero]
    intro y hy
    rw [uIcc_of_le hH.le] at hy
    simp only [eL y hy, mul_zero]
  rw [hb1, hb2, hb3, hb4] at hdiv
  set E : ℝ → ℝ → ℝ := fun x y => fderiv ℝ Wf (x, y) (1, 0) ^ 2 + fderiv ℝ Wf (x, y) (0, 1) ^ 2
    with hEdef
  have hE0 : ∫ x in (0 : ℝ)..W, ∫ y in (0 : ℝ)..H, E x y = 0 := by
    rw [sub_self, add_zero, sub_self] at hdiv
    refine Eq.trans ?_ hdiv
    apply intervalIntegral.integral_congr
    intro x hx
    rw [uIcc_of_le hW.le] at hx
    apply intervalIntegral.integral_congr
    intro y hy
    rw [uIcc_of_le hH.le] at hy
    have := hlapW (x, y) ⟨hx, hy⟩
    simp only [add_apply, smul_apply, smul_eq_mul, hEdef]
    linear_combination (-Wf (x, y)) * this
  have hEc : Continuous (Function.uncurry E) := by
    have a1 : Continuous fun p => fderiv ℝ Wf p (1, 0) := hx1.continuous
    have a2 : Continuous fun p => fderiv ℝ Wf p (0, 1) := hy1.continuous
    exact (a1.pow 2).add (a2.pow 2)
  have hEz := bc_zero_of_integral2 E hEc (fun x y => by positivity) W H hW hH hE0
  -- the slopes vanish on the plate, so the difference is constant there
  have hfd0 : ∀ p ∈ Icc 0 W ×ˢ Icc 0 H, fderiv ℝ Wf p = 0 := by
    rintro ⟨x, y⟩ ⟨hx, hy⟩
    have h := hEz x hx y hy
    simp only [hEdef] at h
    have h1 : fderiv ℝ Wf (x, y) (1, 0) = 0 := by
      have := sq_nonneg (fderiv ℝ Wf (x, y) (0, 1))
      exact pow_eq_zero_iff (n := 2) (by norm_num) |>.1 (by nlinarith [sq_nonneg (fderiv ℝ Wf (x, y) (1, 0))])
    have h2 : fderiv ℝ Wf (x, y) (0, 1) = 0 := by
      have := sq_nonneg (fderiv ℝ Wf (x, y) (1, 0))
      exact pow_eq_zero_iff (n := 2) (by norm_num) |>.1 (by nlinarith [sq_nonneg (fderiv ℝ Wf (x, y) (0, 1))])
    ext
    · simpa using h1
    · simpa using h2
  have hconv : Convex ℝ (Icc (0 : ℝ) W ×ˢ Icc (0 : ℝ) H) := (convex_Icc 0 W).prod (convex_Icc 0 H)
  have h00 : ((0 : ℝ), (0 : ℝ)) ∈ Icc (0 : ℝ) W ×ˢ Icc (0 : ℝ) H :=
    ⟨⟨le_refl 0, hW.le⟩, ⟨le_refl 0, hH.le⟩⟩
  refine ⟨Wf (0, 0), fun x hx y hy => ?_⟩
  have hmv := hconv.norm_image_sub_le_of_norm_fderiv_le (f := Wf) (C := 0)
    (fun p _ => hWd p) (fun p hp => by rw [hfd0 p hp, norm_zero]) h00
    (show (x, y) ∈ Icc (0 : ℝ) W ×ˢ Icc (0 : ℝ) H from ⟨hx, hy⟩)
  rw [zero_mul, norm_le_zero_iff, sub_eq_zero] at hmv
  have : Wf (x, y) = u x y - v x y := rfl
  linarith

/-- **The air-cooled plate, and Robin between insulated and held (Steps 2 and 3).** Take a film
coefficient `h ≥ 0` and a conductivity `k > 0`. The temperature
`u = 20 + 60 sin(πx) Y(y)` with the air-cooled profile `Y` solves Laplace's equation at every
point, reads 20 C on both sides `x = 0` and `x = 1`, reads `20 + 60 sin(πx)` C on the bottom
edge, and meets the Robin condition on the top edge against 20 C air,
`-k u_y(x, 1) = h (u(x, 1) - 20)`; at `h = 0` that is the insulated edge `u_y(x, 1) = 0`. As the
film coefficient grows without limit, the temperature at every point tends to the held-top plate
`20 + 60 sin(πx) sinh π(1 - y) / sinh π`. -/
theorem air_cooled_plate_solves_robin_problem (h k : ℝ) (hh : 0 ≤ h) (hk : 0 < k) :
    (∀ x y, laplacian2 (airCooledPlate h k) x y = 0) ∧
    (∀ y, airCooledPlate h k 0 y = 20 ∧ airCooledPlate h k 1 y = 20) ∧
    (∀ x, airCooledPlate h k x 0 = 20 + 60 * sin (π * x)) ∧
    (∀ x, -k * deriv (fun r => airCooledPlate h k x r) 1 = h * (airCooledPlate h k x 1 - 20)) ∧
    (∀ x y, Tendsto (fun h' => airCooledPlate h' k x y) atTop
      (𝓝 (20 + 60 * sin (π * x) * (sinh (π * (1 - y)) / sinh π)))) := by
  have hS : 0 < sinh π := Real.sinh_pos_iff.2 Real.pi_pos
  have hC : 0 < cosh π := Real.cosh_pos π
  obtain ⟨c, hc⟩ : ∃ c, c = h / k := ⟨_, rfl⟩
  have hc0 : 0 ≤ c := hc ▸ div_nonneg hh hk.le
  obtain ⟨D, hDdef⟩ : ∃ D, D = π * cosh π + c * sinh π := ⟨_, rfl⟩
  have hD : 0 < D := by rw [hDdef]; positivity
  have hfun : airCooledPlate h k = fun x y =>
      20 + 60 * sin (π * x) * ((π * cosh (π * (1 - y)) + c * sinh (π * (1 - y))) / D) := by
    funext x y
    simp only [airCooledPlate, hc, hDdef]
  -- slopes across (in x)
  have dx1 : ∀ y, (fun s => deriv (fun r =>
      20 + 60 * sin (π * r) * ((π * cosh (π * (1 - y)) + c * sinh (π * (1 - y))) / D)) s) =
      fun s => 60 * π * cos (π * s) * ((π * cosh (π * (1 - y)) + c * sinh (π * (1 - y))) / D) := by
    intro y; funext s
    apply HasDerivAt.deriv
    have := ((((hasDerivAt_id' s).const_mul π).sin.const_mul 60).mul_const
      ((π * cosh (π * (1 - y)) + c * sinh (π * (1 - y))) / D)).const_add 20
    convert this using 1; ring
  have dx2 : ∀ x y, deriv (fun s => deriv (fun r =>
      20 + 60 * sin (π * r) * ((π * cosh (π * (1 - y)) + c * sinh (π * (1 - y))) / D)) s) x =
      -(60 * π ^ 2 * sin (π * x) * ((π * cosh (π * (1 - y)) + c * sinh (π * (1 - y))) / D)) := by
    intro x y
    rw [dx1 y]
    apply HasDerivAt.deriv
    have := (((hasDerivAt_id' x).const_mul π).cos.const_mul (60 * π)).mul_const
      ((π * cosh (π * (1 - y)) + c * sinh (π * (1 - y))) / D)
    convert this using 1; ring
  -- slopes along (in y)
  have hin : ∀ s, HasDerivAt (fun r : ℝ => π * (1 - r)) (-π) s := by
    intro s
    have := ((hasDerivAt_id' s).const_sub 1).const_mul π
    convert this using 1; ring
  have dy1 : ∀ x, (fun s => deriv (fun r =>
      20 + 60 * sin (π * x) * ((π * cosh (π * (1 - r)) + c * sinh (π * (1 - r))) / D)) s) =
      fun s => 60 * sin (π * x) * (-(π ^ 2 * sinh (π * (1 - s)) + c * π * cosh (π * (1 - s))) / D) := by
    intro x; funext s
    apply HasDerivAt.deriv
    have := (((((hin s).cosh.const_mul π).add ((hin s).sinh.const_mul c)).div_const D).const_mul
      (60 * sin (π * x))).const_add 20
    convert this using 1
    ring
  have dy2 : ∀ x y, deriv (fun s => deriv (fun r =>
      20 + 60 * sin (π * x) * ((π * cosh (π * (1 - r)) + c * sinh (π * (1 - r))) / D)) s) y =
      60 * π ^ 2 * sin (π * x) * ((π * cosh (π * (1 - y)) + c * sinh (π * (1 - y))) / D) := by
    intro x y
    rw [dy1 x]
    apply HasDerivAt.deriv
    have := (((((hin y).sinh.const_mul (π ^ 2)).add ((hin y).cosh.const_mul (c * π))).neg.div_const
      D).const_mul (60 * sin (π * x)))
    convert this using 1
    ring
  rw [hfun]
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  rotate_left 4
  · -- the limit as the film coefficient grows
    intro x y
    have hlim : Tendsto (fun h' : ℝ => k / h') atTop (𝓝 0) :=
      tendsto_const_nhds.div_atTop tendsto_id
    have ht : Tendsto (fun h' : ℝ => 20 + 60 * sin (π * x) *
        ((π * cosh (π * (1 - y)) * (k / h') + sinh (π * (1 - y))) /
          (π * cosh π * (k / h') + sinh π))) atTop
        (𝓝 (20 + 60 * sin (π * x) *
          ((π * cosh (π * (1 - y)) * 0 + sinh (π * (1 - y))) / (π * cosh π * 0 + sinh π)))) := by
      refine tendsto_const_nhds.add (tendsto_const_nhds.mul ?_)
      refine ((tendsto_const_nhds.mul hlim).add tendsto_const_nhds).div
        ((tendsto_const_nhds.mul hlim).add tendsto_const_nhds) ?_
      simp only [mul_zero, zero_add]
      exact hS.ne'
    simp only [mul_zero, zero_add] at ht
    refine ht.congr' ?_
    filter_upwards [eventually_gt_atTop 0] with h' hpos
    simp only [airCooledPlate]
    congr 2
    have h1 : 0 < π * cosh π * (k / h') + sinh π := by positivity
    have h2 : 0 < π * cosh π + h' / k * sinh π := by positivity
    rw [div_eq_div_iff h1.ne' h2.ne']
    field_simp
  · intro x y
    unfold laplacian2
    rw [dx2, dy2]
    ring
  · intro y
    simp
  · intro x
    simp only [sub_zero, mul_one]
    rw [← hDdef, div_self hD.ne', mul_one]
  · intro x
    rw [show deriv (fun r => 20 + 60 * sin (π * x) *
        ((π * cosh (π * (1 - r)) + c * sinh (π * (1 - r))) / D)) 1 = _ from congrFun (dy1 x) 1]
    simp only [sub_self, mul_zero, Real.sinh_zero, Real.cosh_zero]
    rw [hc]
    field_simp
    ring

/-! The card's whole-number worked examples. -/

-- The fan's film coefficient over the steel's conductivity: h/k = 25/50 = 1/2 per m.
example : (25 : ℚ) / 50 = 1 / 2 := by norm_num

-- 60 W over a 1 m by 10 mm edge face is 6000 W/m^2; over k = 50 W/(m K) that needs 120 K/m.
example : (60 : ℚ) / (1 * (1 / 100)) = 6000 ∧ (6000 : ℚ) / 50 = 120 := by norm_num

-- Fed 60 W, drained 50 W: a 10 W surplus, so the compatibility condition fails.
example : (60 : ℚ) - 50 = 10 ∧ (60 : ℚ) - 50 ≠ 0 := by norm_num

-- The sign mistake: u_y on the bottom too gives an edge sum of -120 - 120 = -240 K,
-- and books 2 × 6000 W/m^2 × 1/100 m = 120 W as leaving.
example : (-120 : ℚ) - 120 = -240 ∧ (2 : ℚ) * 6000 * (1 / 100) = 120 := by norm_num

-- The tube: the even part 30(1 - y) carries k d × 30 = 50 × 1/100 × 30 = 15 W in and out.
example : (50 : ℚ) * (1 / 100) * 30 = 15 := by norm_num

-- The smooth tube profile 50 - 30 cos(2πx): 80 C opposite the seam, 20 C on it.
example : (50 : ℚ) + 30 = 80 ∧ (50 : ℚ) - 30 = 20 ∧ (20 : ℚ) + 60 = 80 := by norm_num

-- Try changing: a drain gradient of 120, 110 or 100 K/m carries 60, 55 or 50 W.
example : (120 : ℚ) * 50 * (1 / 100) = 60 ∧ (110 : ℚ) * 50 * (1 / 100) = 55 ∧
    (100 : ℚ) * 50 * (1 / 100) = 50 := by norm_num

#print axioms bc_deriv_fst
#print axioms bc_deriv_snd
#print axioms bc_c1
#print axioms bc_lap
#print axioms bc_lap_closed
#print axioms bc_zero_of_integral1
#print axioms bc_zero_of_integral2
#print axioms neumann_flows_round_edge_sum_to_zero
#print axioms same_edge_flows_differ_by_constant
#print axioms air_cooled_plate_solves_robin_problem
