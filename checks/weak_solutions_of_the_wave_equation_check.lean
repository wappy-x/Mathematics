-- Weak waves: every Galerkin sum of the wave equation keeps its energy and never holds more than the start, two weak solutions with the same start are equal, and the plucked string's sine shares have the card's closed form.
import Mathlib.Analysis.InnerProductSpace.Projection.FiniteDimensional
import Mathlib.Analysis.InnerProductSpace.Calculus
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.LinearAlgebra.BilinearForm.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus

open Real Set

/-- A weak solution of the string's wave equation `ρ u'' = T u_xx` on the time span `[0, τ]`,
held at both ends, with start shape `f` and start speed `g`.
`H` is the space of finite-stretch-energy shapes held at the ends (`H¹₀`), sitting inside the
space `E` of finite-size shapes (`L²`, with the product `(w, v)`) through `ι`; `a v w` is the
stretch form `(v_x, w_x)`, continuous on `H`.
The motion `u` is continuous in `H`, its speed `u'` is continuous in `E`, and its acceleration
`u''(t)` is a load: a continuous linear functional on `H` (an element of `H⁻¹`), given by the
time rate of `(u', v)` for each fixed test shape `v`. For every test shape `v`,
`ρ ⟨u'', v⟩ + T (u_x, v_x) = 0`, and `u(0) = f`, `u'(0) = g`. -/
def IsWeakWaveSolution {E H : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    [NormedAddCommGroup H] [NormedSpace ℝ H]
    (ι : H →L[ℝ] E) (a : H →L[ℝ] H →L[ℝ] ℝ) (ρ T τ : ℝ) (f : H) (g : E)
    (u : ℝ → H) (u' : ℝ → E) (u'' : ℝ → (H →L[ℝ] ℝ)) : Prop :=
  ContinuousOn u (Icc 0 τ) ∧ ContinuousOn u' (Icc 0 τ) ∧
  (∀ t ∈ Icc 0 τ, HasDerivWithinAt (fun s => ι (u s)) (u' t) (Icc 0 τ) t) ∧
  (∀ v : H, ∀ t ∈ Icc 0 τ,
    HasDerivWithinAt (fun s => inner ℝ (u' s) (ι v)) (u'' t v) (Icc 0 τ) t) ∧
  (∀ v : H, ∀ t ∈ Icc 0 τ, ρ * u'' t v + T * a (u t) v = 0) ∧
  u 0 = f ∧ u' 0 = g

/-- Product rule for `t ↦ (p t, ι (q t))` when `p` is only continuous but has a derivative
against each fixed test vector, and `q` is differentiable. -/
theorem hasDerivWithinAt_inner_weak {E H : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    [NormedAddCommGroup H] [NormedSpace ℝ H] (ι : H →L[ℝ] E)
    {p : ℝ → E} {q : ℝ → H} {q' : H} {L : ℝ} {S : Set ℝ} {x : ℝ}
    (hp : ContinuousWithinAt p S x) (hq : HasDerivWithinAt q q' S x)
    (hw : HasDerivWithinAt (fun s => inner ℝ (p s) (ι (q x))) L S x) :
    HasDerivWithinAt (fun s => inner ℝ (p s) (ι (q s))) (L + inner ℝ (p x) (ι q')) S x := by
  rw [hasDerivWithinAt_iff_tendsto_slope] at hq hw ⊢
  have h2 : Filter.Tendsto (fun s => inner ℝ (p s) (ι (slope q x s))) (nhdsWithin x (S \ {x}))
      (nhds (inner ℝ (p x) (ι q'))) :=
    (hp.mono sdiff_subset).tendsto.inner ((ι.continuous.tendsto q').comp hq)
  refine (hw.add h2).congr' (Filter.Eventually.of_forall fun s => ?_)
  simp only [slope_def_module, map_smul, map_sub, inner_smul_right, inner_sub_right,
    smul_eq_mul]
  ring

#print axioms hasDerivWithinAt_inner_weak

/-- The energy estimate of Step 3, the same for every number of modes.
`E` is the space of shapes with the product `(w, v)`, `V` the finite-dimensional Galerkin space
of the chosen modes, and `a v w` the stretch form `(v_x, w_x)`: symmetric, never negative
(fixed ends do no work), and the modes in `V` bend only into `V` (`a v w = 0` when `v` is in `V`
and `w` is orthogonal to `V`), as the sine shapes do. Mass per metre `ρ` and tension `T` are
positive and fixed. If the Galerkin sum `u_N` stays in `V`, has speed `u_N'` and acceleration
`u_N''`, obeys `ρ (u_N'', v) + T (∂ₓu_N, v_x) = 0` for every `v` in `V`, and starts from the
projections of the start shape `f` and start speed `g`, then at every time its energy
`(ρ/2) ‖u_N'‖² + (T/2) (∂ₓu_N, ∂ₓu_N)` equals its start value, and that is at most the start's
energy `(ρ/2) ‖g‖² + (T/2) (f_x, f_x)`. -/
theorem galerkin_sum_keeps_its_energy_and_never_exceeds_the_start
    {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (V : Submodule ℝ E) [FiniteDimensional ℝ V]
    (a : LinearMap.BilinForm ℝ E) (ha_symm : ∀ v w, a v w = a w v)
    (ha_nonneg : ∀ v, 0 ≤ a v v) (hmodes : ∀ v ∈ V, ∀ w ∈ Vᗮ, a v w = 0)
    (ρ T : ℝ) (hρ : 0 < ρ) (hT : 0 < T)
    (f g : E) (u u' u'' : ℝ → E)
    (hV : ∀ t, u t ∈ V)
    (hu : ∀ t, HasDerivAt u (u' t) t)
    (hu' : ∀ t, HasDerivAt u' (u'' t) t)
    (hgalerkin : ∀ t, ∀ v ∈ V, ρ * inner ℝ (u'' t) v + T * a (u t) v = 0)
    (hf : u 0 = V.starProjection f) (hg : u' 0 = V.starProjection g) :
    ∀ t, ρ / 2 * ‖u' t‖ ^ 2 + T / 2 * a (u t) (u t)
          = ρ / 2 * ‖u' 0‖ ^ 2 + T / 2 * a (u 0) (u 0) ∧
        ρ / 2 * ‖u' 0‖ ^ 2 + T / 2 * a (u 0) (u 0) ≤ ρ / 2 * ‖g‖ ^ 2 + T / 2 * a f f := by
  have hPu : ∀ t, V.starProjection (u t) = u t :=
    fun t => Submodule.starProjection_eq_self_iff.mpr (hV t)
  have hV' : ∀ t, u' t ∈ V := by
    intro t
    have h1 : HasDerivAt (fun s => V.starProjection (u s)) (V.starProjection (u' t)) t :=
      (V.starProjection).hasFDerivAt.comp_hasDerivAt t (hu t)
    have h2 : (fun s => V.starProjection (u s)) = u := funext hPu
    rw [h2] at h1
    rw [(hu t).unique h1]
    exact (V.orthogonalProjectionOnto (u' t)).2
  set Pr := V.orthogonalProjectionOnto
  have hPr : ∀ x ∈ V, ((Pr x : V) : E) = x := by
    intro x hx
    have := Submodule.orthogonalProjectionOnto_mem_subspace_eq_self (K := V) ⟨x, hx⟩
    simpa [Pr] using congrArg Subtype.val this
  let B0 : V →ₗ[ℝ] V →ₗ[ℝ] ℝ := a.compl₁₂ V.subtype V.subtype
  let B : V →L[ℝ] V →L[ℝ] ℝ := LinearMap.toContinuousLinearMap
    ((LinearMap.toContinuousLinearMap : (V →ₗ[ℝ] ℝ) ≃ₗ[ℝ] (V →L[ℝ] ℝ)).toLinearMap ∘ₗ B0)
  have hB : ∀ x y : V, B x y = a x y := fun x y => rfl
  have hEa : ∀ t, a (u t) (u t) = B (Pr (u t)) (Pr (u t)) := by
    intro t; rw [hB, hPr _ (hV t)]
  set En : ℝ → ℝ := fun t => ρ / 2 * ‖u' t‖ ^ 2 + T / 2 * a (u t) (u t) with hEn
  have hEn2 : En = fun t => ρ / 2 * ‖u' t‖ ^ 2 + T / 2 * B (Pr (u t)) (Pr (u t)) := by
    funext t; simp only [hEn, hEa]
  have hder : ∀ t, HasDerivAt En 0 t := by
    intro t
    have hd : HasDerivAt (fun s => Pr (u s)) (Pr (u' t)) t := Pr.hasFDerivAt.comp_hasDerivAt t (hu t)
    have hc := hasDerivWithinAt_univ.mp
      (B.hasDerivWithinAt_of_bilinear hd.hasDerivWithinAt hd.hasDerivWithinAt)
    have h3 := ((hu' t).norm_sq.const_mul (ρ / 2)).add (hc.const_mul (T / 2))
    rw [hEn2]
    convert h3 using 1
    rw [hB, hB, hPr _ (hV t), hPr _ (hV' t), ha_symm (u' t) (u t)]
    have := hgalerkin t (u' t) (hV' t)
    rw [real_inner_comm] at this
    linarith
  intro t
  refine ⟨?_, ?_⟩
  · have hdiff : Differentiable ℝ En := fun t => (hder t).differentiableAt
    exact is_const_of_deriv_eq_zero hdiff (fun t => (hder t).deriv) t 0
  · have h1 : ‖u' 0‖ ^ 2 ≤ ‖g‖ ^ 2 := by
      rw [hg]
      have := V.norm_starProjection_apply_le g
      gcongr
    have h2 : a (u 0) (u 0) ≤ a f f := by
      set p := V.starProjection f
      have hp : p ∈ V := (V.orthogonalProjectionOnto f).2
      have hw : f - p ∈ Vᗮ := V.sub_starProjection_mem_orthogonal f
      have hf' : f = p + (f - p) := by abel
      have e1 : a p (f - p) = 0 := hmodes p hp _ hw
      have e2 : a (f - p) p = 0 := by rw [ha_symm]; exact e1
      have : a f f = a p p + a (f - p) (f - p) := by
        conv_lhs => rw [hf']
        simp only [map_add, LinearMap.add_apply, e1, e2]
        ring
      rw [hf, this]
      linarith [ha_nonneg (f - p)]
    nlinarith

/-- Uniqueness, Step 5: with mass per metre `ρ > 0` and tension `T > 0`, a stretch form that is
symmetric and never negative, and `H¹₀` complete and sitting inside `L²` one-to-one, two weak
solutions of the wave equation on `[0, τ]` with the same start shape `f` and start speed `g`
are equal at every time in `[0, τ]`. -/
theorem weak_wave_solution_unique
    {E H : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    [NormedAddCommGroup H] [NormedSpace ℝ H] [CompleteSpace H]
    (ι : H →L[ℝ] E) (hι : Function.Injective ι)
    (a : H →L[ℝ] H →L[ℝ] ℝ) (ha_symm : ∀ v w, a v w = a w v) (ha_nonneg : ∀ v, 0 ≤ a v v)
    (ρ T τ : ℝ) (hρ : 0 < ρ) (hT : 0 < T) (f : H) (g : E)
    (u ũ : ℝ → H) (u' ũ' : ℝ → E) (u'' ũ'' : ℝ → (H →L[ℝ] ℝ))
    (hu : IsWeakWaveSolution ι a ρ T τ f g u u' u'')
    (hũ : IsWeakWaveSolution ι a ρ T τ f g ũ ũ' ũ'') :
    ∀ t ∈ Icc 0 τ, u t = ũ t := by
  obtain ⟨hc, hc', hd, hdd, heq, h0, h0'⟩ := hu
  obtain ⟨kc, kc', kd, kdd, keq, k0, k0'⟩ := hũ
  intro s hs
  set w : ℝ → H := fun t => u t - ũ t with hw_def
  set w' : ℝ → E := fun t => u' t - ũ' t with hw'_def
  set w'' : ℝ → (H →L[ℝ] ℝ) := fun t => u'' t - ũ'' t with hw''_def
  have hwc : ContinuousOn w (Icc 0 τ) := hc.sub kc
  have hwc' : ContinuousOn w' (Icc 0 τ) := hc'.sub kc'
  have hwd : ∀ t ∈ Icc 0 τ, HasDerivWithinAt (fun r => ι (w r)) (w' t) (Icc 0 τ) t := by
    intro t ht
    convert (hd t ht).sub (kd t ht) using 1
    funext r; simp only [w, map_sub, Pi.sub_apply]
  have hwdd : ∀ v, ∀ t ∈ Icc 0 τ,
      HasDerivWithinAt (fun r => inner ℝ (w' r) (ι v)) (w'' t v) (Icc 0 τ) t := by
    intro v t ht
    convert (hdd v t ht).sub (kdd v t ht) using 1
    funext r; simp only [w', inner_sub_left, Pi.sub_apply]
  have hweq : ∀ v, ∀ t ∈ Icc 0 τ, ρ * w'' t v + T * a (w t) v = 0 := by
    intro v t ht
    have e1 := heq v t ht
    have e2 := keq v t ht
    simp only [w, w'', map_sub, sub_apply]
    linarith
  have hw0 : w 0 = 0 := by simp [w, h0, k0]
  have hw0' : w' 0 = 0 := by simp [w', h0', k0']
  have hs0 : 0 ≤ s := hs.1
  have hsub : Icc 0 s ⊆ Icc 0 τ := Icc_subset_Icc_right hs.2
  set cl : ℝ → ℝ := fun r => (projIcc 0 s hs0 r : ℝ) with hcl_def
  have hcl : Continuous cl := continuous_subtype_val.comp continuous_projIcc
  have hclmem : ∀ r, cl r ∈ Icc 0 τ := fun r => hsub (projIcc 0 s hs0 r).2
  have hcl_eq : ∀ r ∈ Icc 0 s, cl r = r := fun r hr => by simp [cl, projIcc_of_mem hs0 hr]
  set W : ℝ → H := fun r => w (cl r) with hW_def
  have hW : Continuous W := hwc.comp_continuous hcl hclmem
  set v : ℝ → H := fun t => -∫ r in s..t, W r with hv_def
  have hv : ∀ t, HasDerivAt v (-W t) t :=
    fun t => (hW.integral_hasStrictDerivAt s t).hasDerivAt.neg
  have hvs : v s = 0 := by simp [v]
  set Φ : ℝ → ℝ := fun t =>
    ρ * inner ℝ (w' t) (ι (v t)) + ρ / 2 * ‖ι (w t)‖ ^ 2 - T / 2 * a (v t) (v t) with hΦ_def
  have hΦ : ∀ t ∈ Icc 0 s, HasDerivWithinAt Φ 0 (Icc 0 τ) t := by
    intro t ht
    have ht' := hsub ht
    have hWt : W t = w t := by simp only [W, hcl_eq t ht]
    have h1 := hasDerivWithinAt_inner_weak ι (hwc' t ht') (hv t).hasDerivWithinAt
      (hwdd (v t) t ht')
    have h2 := (hwd t ht').norm_sq
    have h3 := a.hasDerivWithinAt_of_bilinear (hv t).hasDerivWithinAt (hv t).hasDerivWithinAt
      (s := Icc 0 τ)
    have h4 := ((h1.const_mul ρ).add (h2.const_mul (ρ / 2))).sub (h3.const_mul (T / 2))
    convert h4 using 1
    rw [hWt]
    simp only [map_neg, inner_neg_right, neg_apply]
    have e := hweq (v t) t ht'
    have e2 := ha_symm (w t) (v t)
    have e3 := real_inner_comm (w' t) (ι (w t))
    rw [e3, e2]
    rw [e2] at e
    linarith
  have hcont : ContinuousOn Φ (Icc 0 s) := fun t ht => ((hΦ t ht).continuousWithinAt).mono hsub
  have hderiv : ∀ x ∈ Ico 0 s, HasDerivWithinAt Φ 0 (Ici x) x := by
    intro x hx
    refine (hΦ x (Ico_subset_Icc_self hx)).mono_of_mem_nhdsWithin ?_
    exact Filter.mem_of_superset (Icc_mem_nhdsGE (hx.2.trans_le hs.2)) (Icc_subset_Icc_left hx.1)
  have hconst := constant_of_has_deriv_right_zero hcont hderiv s (right_mem_Icc.mpr hs0)
  simp only [Φ, hvs, hw0, hw0', map_zero, inner_zero_right, inner_zero_left, mul_zero,
    norm_zero] at hconst
  have hnn := ha_nonneg (v 0)
  have hsq : ‖ι (w s)‖ ^ 2 = 0 := by
    have : 0 ≤ ‖ι (w s)‖ ^ 2 := by positivity
    nlinarith
  have hz : ι (w s) = ι 0 := by
    rw [map_zero]; exact norm_eq_zero.mp (pow_eq_zero_iff (n := 2) (by norm_num) |>.mp hsq)
  have := hι hz
  exact sub_eq_zero.mp this

/-- The pluck's share of each sine shape, Step 2: for the triangle of height `H` at `a` on a
string of length `L` (`0 < a < L`), and every mode `k ≥ 1`,
`b_k = (2/L) ∫₀ᴸ f(x) sin(kπx/L) dx = 2 H L² sin(kπa/L) / (k² π² a (L − a))`,
the integral split at the corner into its two straight pieces. -/
theorem plucked_string_sine_share (H a L : ℝ) (ha : 0 < a) (haL : a < L) (k : ℕ) (hk : 1 ≤ k) :
    2 / L * ((∫ x in (0 : ℝ)..a, H * x / a * Real.sin (k * π * x / L)) +
        ∫ x in a..L, H * (L - x) / (L - a) * Real.sin (k * π * x / L))
      = 2 * H * L ^ 2 * Real.sin (k * π * a / L) / (k ^ 2 * π ^ 2 * a * (L - a)) := by
  have hL : 0 < L := ha.trans haL
  have hLa : 0 < L - a := sub_pos.mpr haL
  have hk0 : (0 : ℝ) < k := by exact_mod_cast hk
  have hc : (0 : ℝ) < k * π / L := by positivity
  set c : ℝ := k * π / L with hc_def
  have harg : ∀ x : ℝ, (k : ℝ) * π * x / L = c * x := fun x => by rw [hc_def]; ring
  simp only [harg]
  have hlin : ∀ x : ℝ, HasDerivAt (fun x : ℝ => c * x) c x := fun x => by
    simpa using (hasDerivAt_id x).const_mul c
  have hne : c ≠ 0 := hc.ne'
  -- antiderivatives
  have h1 : ∀ x ∈ uIcc (0 : ℝ) a,
      HasDerivAt (fun x => H / a * (-(x * Real.cos (c * x)) / c + Real.sin (c * x) / c ^ 2))
        (H * x / a * Real.sin (c * x)) x := by
    intro x _
    have hs := (hlin x).sin
    have hcos := (hlin x).cos
    have := ((((hasDerivAt_id' x).mul hcos).neg.div_const c).add (hs.div_const (c ^ 2))).const_mul
      (H / a)
    convert this using 1
    field_simp
    ring
  have h2 : ∀ x ∈ uIcc a L,
      HasDerivAt
        (fun x => H / (L - a) * (-((L - x) * Real.cos (c * x)) / c - Real.sin (c * x) / c ^ 2))
        (H * (L - x) / (L - a) * Real.sin (c * x)) x := by
    intro x _
    have hs := (hlin x).sin
    have hcos := (hlin x).cos
    have hLx : HasDerivAt (fun x : ℝ => L - x) (-1) x := by
      simpa using (hasDerivAt_id x).const_sub L
    have := (((hLx.mul hcos).neg.div_const c).sub (hs.div_const (c ^ 2))).const_mul (H / (L - a))
    convert this using 1
    field_simp
    ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt h1
      (Continuous.intervalIntegrable (by fun_prop) _ _),
    intervalIntegral.integral_eq_sub_of_hasDerivAt h2
      (Continuous.intervalIntegrable (by fun_prop) _ _)]
  have hsL : Real.sin (c * L) = 0 := by
    rw [hc_def, div_mul_cancel₀ _ hL.ne']; exact Real.sin_nat_mul_pi k
  simp only [hsL, mul_zero, Real.sin_zero, Real.cos_zero, sub_self, zero_mul, neg_zero, zero_div]
  rw [hc_def]
  field_simp
  ring

-- The two slopes of the pluck: 4 mm over 160 mm, and −4 mm over 490 mm.
example : (4 : ℚ) / 160 = 1 / 40 := by norm_num
example : -(4 : ℚ) / 490 = -2 / 245 := by norm_num

-- The energy factor 1/a + 1/(L − a) with a = 0.16 m and L − a = 0.49 m, in 1/m.
example : 1 / ((16 : ℚ) / 100) + 1 / ((49 : ℚ) / 100) = 1625 / 196 := by norm_num

-- Corners at 1 ms, in hundredths of a centimetre: 1600 + 4285 = 5885 and 4285 − 1600 = 2685.
example : (1600 : ℕ) + 4285 = 5885 ∧ (4285 : ℕ) - 1600 = 2685 := by decide

#print axioms galerkin_sum_keeps_its_energy_and_never_exceeds_the_start
#print axioms weak_wave_solution_unique
#print axioms plucked_string_sine_share
