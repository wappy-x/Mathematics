-- Standing waves: each harmonic solves the fixed-string wave equation, a pluck sets its amplitudes by one integral, and a tied string's motion is fixed by its start.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.MeasureTheory.Integral.DivergenceTheorem
import Mathlib.Analysis.Calculus.FDeriv.Symmetric

open Real

/-- Slice in the second variable: the partial derivative in `t` is the `(0,1)` direction. -/
theorem swave_hasDerivAt_snd (G : ℝ × ℝ → ℝ) (x t : ℝ) (hG : DifferentiableAt ℝ G (x, t)) :
    HasDerivAt (fun s => G (x, s)) (fderiv ℝ G (x, t) (0, 1)) t := by
  have h1 : HasDerivAt (fun s : ℝ => (x, s)) ((0 : ℝ), (1 : ℝ)) t :=
    (hasDerivAt_const t x).prodMk (hasDerivAt_id t)
  exact hG.hasFDerivAt.comp_hasDerivAt t h1

/-- Slice in the first variable: the partial derivative in `x` is the `(1,0)` direction. -/
theorem swave_hasDerivAt_fst (G : ℝ × ℝ → ℝ) (x t : ℝ) (hG : DifferentiableAt ℝ G (x, t)) :
    HasDerivAt (fun y => G (y, t)) (fderiv ℝ G (x, t) (1, 0)) x := by
  have h1 : HasDerivAt (fun y : ℝ => (y, t)) ((1 : ℝ), (0 : ℝ)) x :=
    (hasDerivAt_id x).prodMk (hasDerivAt_const x t)
  exact hG.hasFDerivAt.comp_hasDerivAt x h1

/-- Slices of a `C^2` function of two variables and of its first partials are differentiable. -/
theorem swave_slices (u : ℝ → ℝ → ℝ) (hu : ContDiff ℝ 2 (Function.uncurry u)) (x t : ℝ) :
    DifferentiableAt ℝ (fun r => u x r) t ∧ DifferentiableAt ℝ (fun z => u z t) x ∧
    DifferentiableAt ℝ (fun s => deriv (fun r => u x r) s) t ∧
    DifferentiableAt ℝ (fun y => deriv (fun z => u z t) y) x := by
  have hd : Differentiable ℝ (Function.uncurry u) := hu.differentiable (by norm_num)
  have hC1 : ContDiff ℝ 1 (fderiv ℝ (Function.uncurry u)) := hu.fderiv_right (by norm_num)
  have hd1 : Differentiable ℝ (fderiv ℝ (Function.uncurry u)) := hC1.differentiable (by norm_num)
  refine ⟨(swave_hasDerivAt_snd _ x t (hd _)).differentiableAt,
    (swave_hasDerivAt_fst _ x t (hd _)).differentiableAt, ?_, ?_⟩
  · have e : (fun s => deriv (fun r => u x r) s)
        = fun s => fderiv ℝ (Function.uncurry u) (x, s) (0, 1) :=
      funext fun s => (swave_hasDerivAt_snd _ x s (hd _)).deriv
    rw [e]
    exact (swave_hasDerivAt_snd (fun p => fderiv ℝ (Function.uncurry u) p (0, 1)) x t
      ((hd1 _).clm_apply (differentiableAt_const _))).differentiableAt
  · have e : (fun y => deriv (fun z => u z t) y)
        = fun y => fderiv ℝ (Function.uncurry u) (y, t) (1, 0) :=
      funext fun y => (swave_hasDerivAt_fst _ y t (hd _)).deriv
    rw [e]
    exact (swave_hasDerivAt_fst (fun p => fderiv ℝ (Function.uncurry u) p (1, 0)) x t
      ((hd1 _).clm_apply (differentiableAt_const _))).differentiableAt

/-- Energy argument: a `C^2` solution of the wave equation, held at both ends,
starting at rest with zero shape, stays zero on the string. -/
theorem swave_zero (c L : ℝ) (w : ℝ → ℝ → ℝ) (hw : ContDiff ℝ 2 (Function.uncurry w))
    (hwave : ∀ x ∈ Set.Icc 0 L, ∀ t : ℝ,
      deriv (fun s => deriv (fun r => w x r) s) t
        = c ^ 2 * deriv (fun y => deriv (fun z => w z t) y) x)
    (hends : ∀ t : ℝ, w 0 t = 0 ∧ w L t = 0)
    (hshape : ∀ x ∈ Set.Icc 0 L, w x 0 = 0)
    (hspeed : ∀ x ∈ Set.Icc 0 L, deriv (fun s => w x s) 0 = 0) :
    ∀ x ∈ Set.Icc 0 L, ∀ t : ℝ, w x t = 0 := by
  intro x₀ hx₀ t₀
  by_cases hL : 0 < L
  swap
  · have : x₀ = 0 := by linarith [hx₀.1, hx₀.2]
    subst this
    exact (hends t₀).1
  set W : ℝ × ℝ → ℝ := Function.uncurry w with hWdef
  have hWd : Differentiable ℝ W := hw.differentiable (by norm_num)
  have hC1 : ContDiff ℝ 1 (fderiv ℝ W) := hw.fderiv_right (by norm_num)
  have hd1 : Differentiable ℝ (fderiv ℝ W) := hC1.differentiable (by norm_num)
  set Wx : ℝ × ℝ → ℝ := fun p => fderiv ℝ W p (1, 0) with hWx
  set Wt : ℝ × ℝ → ℝ := fun p => fderiv ℝ W p (0, 1) with hWt
  have hWxC : ContDiff ℝ 1 Wx := hC1.clm_apply contDiff_const
  have hWtC : ContDiff ℝ 1 Wt := hC1.clm_apply contDiff_const
  have hWxd : Differentiable ℝ Wx := hWxC.differentiable (by norm_num)
  have hWtd : Differentiable ℝ Wt := hWtC.differentiable (by norm_num)
  have hWt_val : ∀ x s, Wt (x, s) = deriv (fun r => w x r) s :=
    fun x s => (swave_hasDerivAt_snd W x s (hWd _)).deriv.symm
  have hWx_val : ∀ y t, Wx (y, t) = deriv (fun z => w z t) y :=
    fun y t => (swave_hasDerivAt_fst W y t (hWd _)).deriv.symm
  -- the wave equation in terms of the partials
  have hwave' : ∀ x ∈ Set.Icc 0 L, ∀ t : ℝ,
      fderiv ℝ Wt (x, t) (0, 1) = c ^ 2 * fderiv ℝ Wx (x, t) (1, 0) := by
    intro x hx t
    have h := hwave x hx t
    rw [show (fun s => deriv (fun r => w x r) s) = fun s => Wt (x, s) from
        funext fun s => (hWt_val x s).symm,
      show (fun y => deriv (fun z => w z t) y) = fun y => Wx (y, t) from
        funext fun y => (hWx_val y t).symm,
      (swave_hasDerivAt_snd Wt x t (hWtd _)).deriv,
      (swave_hasDerivAt_fst Wx x t (hWxd _)).deriv] at h
    exact h
  -- mixed partials agree
  have hsymm : ∀ p, fderiv ℝ Wx p (0, 1) = fderiv ℝ Wt p (1, 0) := by
    intro p
    have e1 : fderiv ℝ Wx p (0, 1) = fderiv ℝ (fderiv ℝ W) p (0, 1) (1, 0) := by
      rw [hWx, fderiv_clm_apply (hd1 p) (differentiableAt_const _)]
      simp
    have e2 : fderiv ℝ Wt p (1, 0) = fderiv ℝ (fderiv ℝ W) p (1, 0) (0, 1) := by
      rw [hWt, fderiv_clm_apply (hd1 p) (differentiableAt_const _)]
      simp
    rw [e1, e2]
    exact (hw.contDiffAt.isSymmSndFDerivAt (by simp)) _ _
  -- energy density and flux
  set g : ℝ × ℝ → ℝ := fun p => Wt p * Wt p + c ^ 2 * (Wx p * Wx p) with hg
  set f : ℝ × ℝ → ℝ := fun p => -(2 * c ^ 2 * (Wx p * Wt p)) with hf
  have hgC : ContDiff ℝ 1 g := (hWtC.mul hWtC).add (contDiff_const.mul (hWxC.mul hWxC))
  have hfC : ContDiff ℝ 1 f := (contDiff_const.mul (hWxC.mul hWtC)).neg
  have hgd : Differentiable ℝ g := hgC.differentiable (by norm_num)
  have hfd : Differentiable ℝ f := hfC.differentiable (by norm_num)
  have hpt : ∀ x ∈ Set.Icc 0 L, ∀ y : ℝ,
      fderiv ℝ f (x, y) (1, 0) + fderiv ℝ g (x, y) (0, 1) = 0 := by
    intro x hx y
    have a1 := swave_hasDerivAt_snd Wt x y (hWtd _)
    have a2 := swave_hasDerivAt_snd Wx x y (hWxd _)
    have b1 := swave_hasDerivAt_fst Wt x y (hWtd _)
    have b2 := swave_hasDerivAt_fst Wx x y (hWxd _)
    have eg := (swave_hasDerivAt_snd g x y (hgd _)).unique
      ((a1.mul a1).add ((a2.mul a2).const_mul (c ^ 2)))
    have ef := (swave_hasDerivAt_fst f x y (hfd _)).unique
      (((b2.mul b1).const_mul (2 * c ^ 2)).neg)
    rw [ef, eg, hwave' x hx y, hsymm (x, y)]
    ring
  have hcontI : Continuous (fun p => fderiv ℝ f p (1, 0) + fderiv ℝ g p (0, 1)) :=
    ((hfC.continuous_fderiv (by norm_num)).clm_apply continuous_const).add
      ((hgC.continuous_fderiv (by norm_num)).clm_apply continuous_const)
  -- the start has zero energy
  have hWx0 : Set.EqOn (fun x => Wx (x, 0)) (fun _ => 0) (Set.Icc 0 L) := by
    refine Set.EqOn.of_subset_closure (s := Set.Ioo 0 L) ?_ (hWxC.continuous.comp (continuous_id.prodMk continuous_const)).continuousOn continuousOn_const
      Set.Ioo_subset_Icc_self (closure_Ioo hL.ne).ge
    intro x hx
    simp only
    rw [hWx_val]
    have : (fun z => w z 0) =ᶠ[nhds x] fun _ => 0 := by
      filter_upwards [Ioo_mem_nhds hx.1 hx.2] with z hz
      exact hshape z (Set.Ioo_subset_Icc_self hz)
    rw [this.deriv_eq]
    simp
  have hg0 : (∫ x in (0 : ℝ)..L, g (x, 0)) = 0 := by
    rw [intervalIntegral.integral_congr (g := fun _ => (0 : ℝ)) ?_]
    · simp
    intro x hx
    rw [Set.uIcc_of_le hL.le] at hx
    have h1 : Wt (x, 0) = 0 := by rw [hWt_val]; exact hspeed x hx
    have h2 : Wx (x, 0) = 0 := hWx0 hx
    simp [hg, h1, h2]
  have hgnn : ∀ p, 0 ≤ g p := fun p => by
    simp only [hg]
    have := mul_self_nonneg (Wt p)
    have := mul_nonneg (sq_nonneg c) (mul_self_nonneg (Wx p))
    linarith
  have key : ∀ τ : ℝ, ∀ x ∈ Set.Icc 0 L, Wt (x, τ) = 0 := by
    intro τ x hx
    have hdiv := MeasureTheory.integral2_divergence_prod_of_hasFDerivAt_off_countable f g
      (fderiv ℝ f) (fderiv ℝ g) 0 0 L τ ∅ Set.countable_empty hfC.continuous.continuousOn
      hgC.continuous.continuousOn (fun p _ => (hfd p).hasFDerivAt) (fun p _ => (hgd p).hasFDerivAt)
      (hcontI.continuousOn.integrableOn_compact (isCompact_uIcc.prod isCompact_uIcc))
    have hLHS : (∫ x in (0 : ℝ)..L, ∫ y in (0 : ℝ)..τ,
        fderiv ℝ f (x, y) (1, 0) + fderiv ℝ g (x, y) (0, 1)) = 0 := by
      rw [intervalIntegral.integral_congr (g := fun _ => (0 : ℝ)) ?_]
      · simp
      intro x hx
      rw [Set.uIcc_of_le hL.le] at hx
      simp only
      rw [intervalIntegral.integral_congr (g := fun _ => (0 : ℝ)) (fun y _ => hpt x hx y)]
      simp
    -- the ends stay at rest
    have hWt_end : ∀ s, Wt (0, s) = 0 ∧ Wt (L, s) = 0 := by
      intro s
      rw [hWt_val, hWt_val, show (fun r => w 0 r) = fun _ => 0 from funext fun r => (hends r).1,
        show (fun r => w L r) = fun _ => 0 from funext fun r => (hends r).2]
      simp
    have hf0 : (∫ y in (0 : ℝ)..τ, f (0, y)) = 0 := by
      simp [hf, (hWt_end _).1]
    have hfL : (∫ y in (0 : ℝ)..τ, f (L, y)) = 0 := by
      simp [hf, (hWt_end _).2]
    rw [hLHS, hf0, hfL, hg0] at hdiv
    have hgt : (∫ x in (0 : ℝ)..L, g (x, τ)) = 0 := by linarith
    have hgx : g (x, τ) = 0 := by
      by_contra hne
      have hpos := intervalIntegral.integral_pos (f := fun y => g (y, τ)) hL
        ((hgC.continuous.comp (continuous_id.prodMk continuous_const)).continuousOn)
        (fun y _ => hgnn (y, τ)) ⟨x, hx, lt_of_le_of_ne (hgnn _) (Ne.symm hne)⟩
      linarith
    simp only [hg] at hgx
    have h1 := mul_self_nonneg (Wt (x, τ))
    have h2 := mul_nonneg (sq_nonneg c) (mul_self_nonneg (Wx (x, τ)))
    exact mul_self_eq_zero.mp (by linarith)
  have hdiff : Differentiable ℝ (fun s => w x₀ s) :=
    fun s => (swave_hasDerivAt_snd W x₀ s (hWd _)).differentiableAt
  have hconst := is_const_of_deriv_eq_zero hdiff
    (fun s => by rw [← hWt_val]; exact key s x₀ hx₀) t₀ 0
  rw [hconst]
  exact hshape x₀ hx₀

/-- Only one motion fits a start (Step 6). Let `u` and `v` be twice continuously
differentiable heights `u x t`, both obeying the wave equation `u_tt = c^2 u_xx`
on the string `0 ≤ x ≤ L`, both held at height 0 at the two ends `x = 0` and `x = L`
for all time. If they start in the same shape and with the same speed at `t = 0`,
then they are the same motion at every place on the string and every time. -/
theorem string_motion_unique (c L : ℝ) (u v : ℝ → ℝ → ℝ)
    (hu : ContDiff ℝ 2 (Function.uncurry u))
    (hv : ContDiff ℝ 2 (Function.uncurry v))
    (hu_wave : ∀ x ∈ Set.Icc 0 L, ∀ t : ℝ,
      deriv (fun s => deriv (fun r => u x r) s) t
        = c ^ 2 * deriv (fun y => deriv (fun z => u z t) y) x)
    (hv_wave : ∀ x ∈ Set.Icc 0 L, ∀ t : ℝ,
      deriv (fun s => deriv (fun r => v x r) s) t
        = c ^ 2 * deriv (fun y => deriv (fun z => v z t) y) x)
    (hu_ends : ∀ t : ℝ, u 0 t = 0 ∧ u L t = 0)
    (hv_ends : ∀ t : ℝ, v 0 t = 0 ∧ v L t = 0)
    (h_shape : ∀ x ∈ Set.Icc 0 L, u x 0 = v x 0)
    (h_speed : ∀ x ∈ Set.Icc 0 L,
      deriv (fun s => u x s) 0 = deriv (fun s => v x s) 0) :
    ∀ x ∈ Set.Icc 0 L, ∀ t : ℝ, u x t = v x t := by
  have hw : ContDiff ℝ 2 (Function.uncurry fun x t => u x t - v x t) := hu.sub hv
  have hdt : ∀ x t, deriv (fun r => u x r - v x r) t
      = deriv (fun r => u x r) t - deriv (fun r => v x r) t :=
    fun x t => deriv_fun_sub (swave_slices u hu x t).1 (swave_slices v hv x t).1
  have hdx : ∀ x t, deriv (fun z => u z t - v z t) x
      = deriv (fun z => u z t) x - deriv (fun z => v z t) x :=
    fun x t => deriv_fun_sub (swave_slices u hu x t).2.1 (swave_slices v hv x t).2.1
  have hwave : ∀ x ∈ Set.Icc 0 L, ∀ t : ℝ,
      deriv (fun s => deriv (fun r => u x r - v x r) s) t
        = c ^ 2 * deriv (fun y => deriv (fun z => u z t - v z t) y) x := by
    intro x hx t
    simp only [hdt, hdx]
    rw [deriv_fun_sub (swave_slices u hu x t).2.2.1 (swave_slices v hv x t).2.2.1,
      deriv_fun_sub (swave_slices u hu x t).2.2.2 (swave_slices v hv x t).2.2.2,
      hu_wave x hx t, hv_wave x hx t]
    ring
  have key := swave_zero c L (fun x t => u x t - v x t) hw hwave
    (fun t => by simp [(hu_ends t).1, (hu_ends t).2, (hv_ends t).1, (hv_ends t).2])
    (fun x hx => by simp [h_shape x hx])
    (fun x hx => by
      show deriv (fun s => u x s - v x s) 0 = 0
      rw [hdt, h_speed x hx, sub_self])
  intro x hx t
  exact sub_eq_zero.mp (key x hx t)

/-- Harmonic `n` is a standing wave (Steps 1 and 2): the shape `sin (n π x / L)`,
with `n` arches, times `cos (ω_n t)` with `ω_n = n π c / L`, obeys the wave equation
`u_tt = c^2 u_xx` everywhere and stays at height 0 at both ends `x = 0` and `x = L`. -/
theorem harmonic_is_standing_wave (c L : ℝ) (n : ℕ) :
    let u : ℝ → ℝ → ℝ := fun x t => sin (n * π * x / L) * cos (n * π * c / L * t)
    (∀ x t : ℝ, deriv (fun s => deriv (fun r => u x r) s) t
        = c ^ 2 * deriv (fun y => deriv (fun z => u z t) y) x) ∧
    (∀ t : ℝ, u 0 t = 0 ∧ u L t = 0) := by
  intro u
  refine ⟨fun x t => ?_, fun t => ?_⟩
  · set A : ℝ := (n : ℝ) * π / L with hA
    set B : ℝ := (n : ℝ) * π * c / L with hB
    have hu : ∀ x r, u x r = sin (A * x) * cos (B * r) := by
      intro x r
      simp only [u, hA, hB]
      congr 2; ring
    have ht : ∀ x s, deriv (fun r => u x r) s = -(sin (A * x) * B) * sin (B * s) := by
      intro x s
      have h := (((hasDerivAt_id' s).const_mul B).cos).const_mul (sin (A * x))
      rw [show (fun r => u x r) = fun r => sin (A * x) * cos (B * r) from funext (hu x), h.deriv]
      ring
    have htt : deriv (fun s => deriv (fun r => u x r) s) t = -(sin (A * x) * B ^ 2 * cos (B * t)) := by
      have h := (((hasDerivAt_id' t).const_mul B).sin).const_mul (-(sin (A * x) * B))
      rw [show (fun s => deriv (fun r => u x r) s) = fun s => -(sin (A * x) * B) * sin (B * s)
        from funext fun s => ht x s, h.deriv]
      ring
    have hx1 : ∀ y, deriv (fun z => u z t) y = (cos (B * t) * A) * cos (A * y) := by
      intro y
      have h := (((hasDerivAt_id' y).const_mul A).sin).mul_const (cos (B * t))
      rw [show (fun z => u z t) = fun z => sin (A * z) * cos (B * t) from funext fun z => hu z t,
        h.deriv]
      ring
    have hxx : deriv (fun y => deriv (fun z => u z t) y) x = -(sin (A * x) * A ^ 2 * cos (B * t)) := by
      have h := (((hasDerivAt_id' x).const_mul A).cos).const_mul (cos (B * t) * A)
      rw [show (fun y => deriv (fun z => u z t) y) = fun y => (cos (B * t) * A) * cos (A * y)
        from funext hx1, h.deriv]
      ring
    have hBA : B = A * c := by rw [hA, hB]; ring
    rw [htt, hxx, hBA]
    ring
  · refine ⟨by simp [u], ?_⟩
    simp only [u]
    by_cases hL : L = 0
    · simp [hL]
    · rw [show (n : ℝ) * π * L / L = n * π by field_simp, sin_nat_mul_pi, zero_mul]

/-- The pluck decides each amplitude (Step 3 and its algebra). Pull a string of
length `L` aside by `h` at the point `a`, so it makes a triangle. Then the amplitude
of harmonic `n`, `b_n = (2/L) ∫₀ᴸ f(x) sin(n π x / L) dx`, equals
`2 h L^2 sin(n π a / L) / (n^2 π^2 a (L - a))`. On the 1 m string this is
`2 h sin(n π a) / (n^2 π^2 a (1 - a))`, and at the middle `8 h sin(n π / 2) / (n^2 π^2)`,
so a harmonic with a node at the pluck point is missing. -/
theorem pluck_amplitude (L h a : ℝ) (ha : 0 < a) (haL : a < L) (n : ℕ) (hn : 1 ≤ n) :
    (2 / L) * ∫ x in (0 : ℝ)..L,
        (if x ≤ a then h * x / a else h * (L - x) / (L - a)) * sin (n * π * x / L)
      = 2 * h * L ^ 2 * sin (n * π * a / L) / (n ^ 2 * π ^ 2 * a * (L - a)) := by
  have hL : 0 < L := ha.trans haL
  have hLa : 0 < L - a := sub_pos.mpr haL
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  set k : ℝ := (n : ℝ) * π / L with hk
  have hk0 : k ≠ 0 := by rw [hk]; positivity
  have hsin : ∀ x, HasDerivAt (fun x : ℝ => sin (n * π * x / L)) (cos (n * π * x / L) * k) x := by
    intro x
    have := (((hasDerivAt_id' x).const_mul ((n : ℝ) * π)).div_const L).sin
    convert this using 1
    rw [hk]; ring
  have hcos : ∀ x, HasDerivAt (fun x : ℝ => cos (n * π * x / L)) (-sin (n * π * x / L) * k) x := by
    intro x
    have := (((hasDerivAt_id' x).const_mul ((n : ℝ) * π)).div_const L).cos
    convert this using 1
    rw [hk]; ring
  have hcont : Continuous (fun x : ℝ =>
      (if x ≤ a then h * x / a else h * (L - x) / (L - a)) * sin (n * π * x / L)) := by
    refine Continuous.mul ?_ (by fun_prop)
    refine Continuous.if_le (by fun_prop) (by fun_prop) continuous_id continuous_const ?_
    intro x (hx : x = a)
    rw [hx]; field_simp
  rw [← intervalIntegral.integral_add_adjacent_intervals (b := a) (hcont.intervalIntegrable _ _)
    (hcont.intervalIntegrable _ _)]
  have e1 : (∫ x in (0 : ℝ)..a,
      (if x ≤ a then h * x / a else h * (L - x) / (L - a)) * sin (n * π * x / L))
      = ∫ x in (0 : ℝ)..a, h * x / a * sin (n * π * x / L) := by
    refine intervalIntegral.integral_congr (fun x hx => ?_)
    rw [Set.uIcc_of_le ha.le] at hx
    simp only [hx.2, ↓reduceIte]
  have e2 : (∫ x in a..L,
      (if x ≤ a then h * x / a else h * (L - x) / (L - a)) * sin (n * π * x / L))
      = ∫ x in a..L, h * (L - x) / (L - a) * sin (n * π * x / L) := by
    refine intervalIntegral.integral_congr (fun x hx => ?_)
    rw [Set.uIcc_of_le haL.le] at hx
    by_cases hxa : x ≤ a
    · have : x = a := le_antisymm hxa hx.1
      subst this
      simp only [hxa, ↓reduceIte]
      congr 1
      field_simp
    · simp only [hxa, ↓reduceIte]
  rw [e1, e2]
  have F1 : ∀ x ∈ Set.uIcc (0 : ℝ) a, HasDerivAt
      (fun x => h / a * (-(x * cos (n * π * x / L)) / k + sin (n * π * x / L) / k ^ 2))
      (h * x / a * sin (n * π * x / L)) x := by
    intro x _
    have := ((((hasDerivAt_id' x).mul (hcos x)).neg.div_const k).add
      ((hsin x).div_const (k ^ 2))).const_mul (h / a)
    convert this using 1
    field_simp
    ring
  have F2 : ∀ x ∈ Set.uIcc a L, HasDerivAt
      (fun x => h / (L - a) * (-((L - x) * cos (n * π * x / L)) / k - sin (n * π * x / L) / k ^ 2))
      (h * (L - x) / (L - a) * sin (n * π * x / L)) x := by
    intro x _
    have := (((((hasDerivAt_id' x).const_sub L).mul (hcos x)).neg.div_const k).sub
      ((hsin x).div_const (k ^ 2))).const_mul (h / (L - a))
    convert this using 1
    field_simp
    ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt F1
      ((by fun_prop : Continuous fun x : ℝ => h * x / a * sin (n * π * x / L)).intervalIntegrable _ _),
    intervalIntegral.integral_eq_sub_of_hasDerivAt F2
      ((by fun_prop : Continuous fun x : ℝ =>
        h * (L - x) / (L - a) * sin (n * π * x / L)).intervalIntegrable _ _)]
  rw [show (n : ℝ) * π * L / L = n * π by field_simp, sin_nat_mul_pi]
  simp only [mul_zero, zero_div, sin_zero, cos_zero, sub_self]
  rw [hk]
  field_simp
  ring

-- Worked numbers from the card (1 m string, c = 1 m/s, pulled 1 cm at the middle).
-- Slope of the pluck: 1 cm over 0.5 m is 2 cm/m; the slope falls by h/(a(1 - a)) = 4h.
example : (1 : ℚ) / (1 / 2) = 2 := by norm_num
example : (1 : ℚ) / ((1 / 2) * (1 - 1 / 2)) = 4 := by norm_num
-- Energy at the start: ½ × 1 × 2 × 2 × 1 m = 2.
example : (1 / 2 : ℚ) * 1 * 2 * 2 * 1 = 2 := by norm_num
-- Energy table: motion + stretch = 2 at t = 0, 0.25 and 0.5 s.
example : (0 : ℚ) + 2 = 2 ∧ (1 : ℚ) + 1 = 2 ∧ (2 : ℚ) + 0 = 2 := by norm_num
-- Middle at 0.25 s: ½ × (0.5 + 0.5) = 0.5 cm.
example : (1 / 2 : ℚ) * (1 / 2 + 1 / 2) = 1 / 2 := by norm_num
-- Harmonic 1's period: 2L/c = 2 s.
example : (2 : ℚ) * 1 / 1 = 2 := by norm_num
-- Ends not held: (t - x)^3 at t = 1 s, x = 0.5 m is 0.125 cm.
example : ((1 : ℚ) - 1 / 2) ^ 3 = 1 / 8 := by norm_num
-- Quarter pluck: the rational part of b_2 = 2h/(2^2 π^2 a(1 - a)) at a = 1/4 is 32/12.
example : (2 : ℚ) / (2 ^ 2 * ((1 / 4) * (1 - 1 / 4))) = 32 / 12 := by norm_num

#print axioms swave_hasDerivAt_snd
#print axioms swave_hasDerivAt_fst
#print axioms swave_slices
#print axioms swave_zero
#print axioms string_motion_unique
#print axioms harmonic_is_standing_wave
#print axioms pluck_amplitude
