-- The retarded Green's function: the point-source field u(x, t) = q(t - |x|/c) / (4πc²|x|) in three dimensions solves the wave equation away from the source, is zero until sound can arrive, has flux out of a small sphere tending to q(t), and one hall mode driven at its own frequency grows as t sin t or, with damping, settles to the cap F/(2γω).
import Mathlib.Analysis.InnerProductSpace.Laplacian
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.InnerProductSpace.Calculus
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Tactic

open Filter Topology Real Laplacian

/-- The retarded field of a point source of strength `q(t)` at the origin of three-dimensional
space, with wave speed `c`: `u(x, t) = q(t - |x|/c) / (4π c² |x|)`. -/
noncomputable def retardedPointField (c : ℝ) (q : ℝ → ℝ) (x : EuclideanSpace ℝ (Fin 3)) (t : ℝ) :
    ℝ :=
  q (t - ‖x‖ / c) / (4 * π * c ^ 2 * ‖x‖)

open scoped RealInnerProductSpace

lemma rg_hasFDerivAt_norm {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    {x : E} (hx : x ≠ 0) :
    HasFDerivAt (fun y : E => ‖y‖) (‖x‖⁻¹ • innerSL ℝ x) x := by
  have hn : ‖x‖ ≠ 0 := norm_ne_zero_iff.mpr hx
  have h := (hasStrictFDerivAt_norm_sq x).hasFDerivAt.sqrt (pow_ne_zero 2 hn)
  simp only [Real.sqrt_sq (norm_nonneg _)] at h
  convert h using 1
  ext v
  simp
  field_simp

lemma rg_iteratedFDeriv_two_radial {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    {f : E → ℝ} {h : ℝ → ℝ} {h1 : ℝ} {x : E} (hx : x ≠ 0)
    (hf : ∀ᶠ y in 𝓝 x, HasFDerivAt f (h ‖y‖ • innerSL ℝ y) y) (hh : HasDerivAt h h1 ‖x‖)
    (v : E) :
    iteratedFDeriv ℝ 2 f x ![v, v] = h ‖x‖ * ⟪v, v⟫ + h1 * ‖x‖⁻¹ * ⟪x, v⟫ ^ 2 := by
  rw [iteratedFDeriv_two_apply]
  have heq : fderiv ℝ f =ᶠ[𝓝 x] fun y => h ‖y‖ • innerSL ℝ y :=
    hf.mono fun y hy => hy.fderiv
  rw [heq.fderiv_eq]
  have hd : HasFDerivAt (fun y => h ‖y‖ • innerSL ℝ y) _ x :=
    (hh.comp_hasFDerivAt x (rg_hasFDerivAt_norm hx)).smul (innerSL ℝ (E := E)).hasFDerivAt
  rw [hd.fderiv]
  have hvv : innerSL ℝ v v = ‖v‖ ^ 2 := by
    rw [innerSL_apply_apply, real_inner_self_eq_norm_sq]
  simp [hvv]
  ring


lemma rg_laplacian_radial {f : EuclideanSpace ℝ (Fin 3) → ℝ} {h : ℝ → ℝ} {h1 : ℝ}
    {x : EuclideanSpace ℝ (Fin 3)} (hx : x ≠ 0)
    (hf : ∀ᶠ y in 𝓝 x, HasFDerivAt f (h ‖y‖ • innerSL ℝ y) y) (hh : HasDerivAt h h1 ‖x‖) :
    Δ f x = 3 * h ‖x‖ + h1 * ‖x‖ := by
  set b := EuclideanSpace.basisFun (Fin 3) ℝ
  rw [InnerProductSpace.laplacian_eq_iteratedFDeriv_orthonormalBasis f b]
  simp only [rg_iteratedFDeriv_two_radial hx hf hh]
  have h1' : ∀ i, ⟪b i, b i⟫ = 1 := fun i => by
    rw [real_inner_self_eq_norm_sq, b.orthonormal.1 i]; norm_num
  have h2' : ∑ i, ⟪x, b i⟫ ^ 2 = ‖x‖ ^ 2 := by
    rw [← real_inner_self_eq_norm_sq, ← b.sum_inner_mul_inner x x]
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [real_inner_comm (b i) x]; ring
  simp only [h1', Finset.sum_add_distrib, ← Finset.mul_sum, h2']
  have hn : ‖x‖ ≠ 0 := norm_ne_zero_iff.mpr hx
  simp
  field_simp


lemma rg_q_facts {q : ℝ → ℝ} (hq : ContDiff ℝ 2 q) :
    (∀ s, HasDerivAt q (deriv q s) s) ∧ (∀ s, HasDerivAt (deriv q) (deriv (deriv q) s) s) ∧
      Continuous q ∧ Continuous (deriv q) := by
  have h1 : ContDiff ℝ 1 (deriv q) := (contDiff_succ_iff_deriv (n := 1)).mp hq |>.2.2
  refine ⟨fun s => (hq.differentiable (by norm_num) s).hasDerivAt,
    fun s => (h1.differentiable one_ne_zero s).hasDerivAt, hq.continuous, h1.continuous⟩

/-- The radial profile's gradient. -/
lemma rg_hasFDerivAt_field {c : ℝ} (hc : 0 < c) {q : ℝ → ℝ} (hq : ContDiff ℝ 2 q) (t : ℝ)
    {y : EuclideanSpace ℝ (Fin 3)} (hy : y ≠ 0) :
    HasFDerivAt (fun z => retardedPointField c q z t)
      ((-(deriv q (t - ‖y‖ / c) * ‖y‖ / c + q (t - ‖y‖ / c)) / (4 * π * c ^ 2 * ‖y‖ ^ 3)) •
        innerSL ℝ y) y := by
  obtain ⟨hq1, -, -, -⟩ := rg_q_facts hq
  have hr : 0 < ‖y‖ := norm_pos_iff.mpr hy
  have hK : 0 < 4 * π * c ^ 2 := by positivity
  have hg : HasDerivAt (fun r => q (t - r / c) / (4 * π * c ^ 2 * r))
      (-(deriv q (t - ‖y‖ / c) * ‖y‖ / c + q (t - ‖y‖ / c)) / (4 * π * c ^ 2 * ‖y‖ ^ 2))
      ‖y‖ := by
    have ha : HasDerivAt (fun r => q (t - r / c)) (deriv q (t - ‖y‖ / c) * (-(1 / c))) ‖y‖ :=
      (hq1 _).comp _ (((hasDerivAt_id _).div_const c).const_sub t)
    have hb : HasDerivAt (fun r : ℝ => 4 * π * c ^ 2 * r) (4 * π * c ^ 2 * 1) ‖y‖ :=
      (hasDerivAt_id _).const_mul _
    convert ha.div hb (by positivity) using 1
    field_simp
    ring
  have : HasFDerivAt (fun z => retardedPointField c q z t) _ y :=
    hg.comp_hasFDerivAt y (rg_hasFDerivAt_norm hy)
  refine this.congr_fderiv ?_
  ext v
  simp
  field_simp

lemma rg_damped_decay {a b : ℝ} (ha : 0 < a) (hb : 0 < b) (B B' B'' : ℝ → ℝ)
    (h1 : ∀ t, 0 ≤ t → HasDerivAt B (B' t) t) (h2 : ∀ t, 0 ≤ t → HasDerivAt B' (B'' t) t)
    (h3 : ∀ t, 0 ≤ t → B'' t + a * B' t + b * B t = 0) : Tendsto B atTop (𝓝 0) := by
  set k := a * b / (2 * (b + a ^ 2)) with hk
  have hk0 : 0 < k := by positivity
  set V : ℝ → ℝ := fun t => B' t ^ 2 + a * B t * B' t + (b + a ^ 2 / 2) * B t ^ 2 with hV
  set W : ℝ → ℝ := fun t => exp (k * t) * V t with hW
  have hVd : ∀ t, 0 ≤ t → HasDerivAt V
      (2 * B' t * B'' t + a * (B' t * B' t + B t * B'' t) + (b + a ^ 2 / 2) * (2 * B t * B' t))
      t := by
    intro t ht
    have e1 := (h2 t ht).pow 2
    have e2 := ((h1 t ht).const_mul a).mul (h2 t ht)
    have e3 := ((h1 t ht).pow 2).const_mul (b + a ^ 2 / 2)
    refine ((e1.add e2).add e3).congr_deriv ?_
    simp
    ring
  have hWd : ∀ t, 0 ≤ t → HasDerivAt W (exp (k * t) * (k * V t +
      (2 * B' t * B'' t + a * (B' t * B' t + B t * B'' t) + (b + a ^ 2 / 2) * (2 * B t * B' t))))
      t := by
    intro t ht
    have e := ((hasDerivAt_id t).const_mul k).exp.mul (hVd t ht)
    refine e.congr_deriv ?_
    simp
    ring
  have hneg : ∀ t, 0 ≤ t → k * V t +
      (2 * B' t * B'' t + a * (B' t * B' t + B t * B'' t) + (b + a ^ 2 / 2) * (2 * B t * B' t))
        ≤ 0 := by
    intro t ht
    have hB'' : B'' t = -a * B' t - b * B t := by linarith [h3 t ht]
    rw [hB'']
    simp only [hV]
    have hba : 0 < b + a ^ 2 := by positivity
    rw [hk, div_mul_eq_mul_div, div_add' _ _ _ (by positivity), div_nonpos_iff]
    right
    refine ⟨?_, by positivity⟩
    have he : a * b * (B' t ^ 2 + a * B t * B' t + (b + a ^ 2 / 2) * B t ^ 2) +
      (2 * B' t * (-a * B' t - b * B t) + a * (B' t * B' t + B t * (-a * B' t - b * B t)) +
          (b + a ^ 2 / 2) * (2 * B t * B' t)) * (2 * (b + a ^ 2)) =
        -(a * ((a * B' t - b * B t) ^ 2 / 2 + (b + 3 * a ^ 2 / 2) * B' t ^ 2 +
          (b ^ 2 / 2 + 3 * a ^ 2 * b / 2) * B t ^ 2)) := by ring
    rw [he, neg_nonpos]
    positivity
  have hanti : AntitoneOn W (Set.Ici 0) := by
    refine antitoneOn_of_hasDerivWithinAt_nonpos (convex_Ici 0)
      (f' := fun t => exp (k * t) * (k * V t + (2 * B' t * B'' t + a * (B' t * B' t + B t * B'' t)
        + (b + a ^ 2 / 2) * (2 * B t * B' t)))) ?_ ?_ ?_
    · intro t ht
      exact (hWd t ht).continuousAt.continuousWithinAt
    · intro t ht
      rw [interior_Ici] at ht
      exact (hWd t (le_of_lt ht)).hasDerivWithinAt
    · intro t ht
      rw [interior_Ici] at ht
      exact mul_nonpos_of_nonneg_of_nonpos (exp_pos _).le (hneg t (le_of_lt ht))
  have hbound : ∀ t, 0 ≤ t → B t ^ 2 ≤ V 0 / b * exp (-(k * t)) := by
    intro t ht
    have hW0 : W t ≤ W 0 := hanti (Set.mem_Ici.mpr le_rfl) (Set.mem_Ici.mpr ht) ht
    simp only [hW, mul_zero, exp_zero, one_mul] at hW0
    have hVt : b * B t ^ 2 ≤ V t := by
      simp only [hV]
      nlinarith [sq_nonneg (B' t + a / 2 * B t), sq_nonneg (B t), sq_nonneg a]
    have hVle : V t ≤ V 0 * exp (-(k * t)) := by
      rw [exp_neg, ← div_eq_mul_inv, le_div_iff₀ (exp_pos _)]
      linarith [mul_comm (exp (k * t)) (V t)]
    rw [div_mul_eq_mul_div, le_div_iff₀ hb]
    nlinarith
  have hexp : Tendsto (fun t => V 0 / b * exp (-(k * t))) atTop (𝓝 0) := by
    have : Tendsto (fun t => exp (-(k * t))) atTop (𝓝 0) :=
      tendsto_exp_neg_atTop_nhds_zero.comp (tendsto_id.const_mul_atTop hk0)
    simpa using this.const_mul (V 0 / b)
  have hsq : Tendsto (fun t => B t ^ 2) atTop (𝓝 0) := by
    refine tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds hexp ?_ ?_
    · exact Eventually.of_forall fun t => sq_nonneg _
    · filter_upwards [eventually_ge_atTop 0] with t ht using hbound t ht
  rw [tendsto_zero_iff_abs_tendsto_zero]
  have := (continuous_sqrt.tendsto 0).comp hsq
  simpa [Function.comp_def, Real.sqrt_sq_eq_abs] using this

/-- The point-source formula solves the wave equation away from the source, and nothing arrives
before the sound could travel there. Let the wave speed `c` be a positive constant (still,
uniform air) and let the source strength `q` be twice continuously differentiable and zero before
time `0`. Then at every point `x ≠ 0` of three-dimensional space and every time `t`, the field
`u = q(t - |x|/c) / (4π c² |x|)` is twice differentiable in space and satisfies
`u_tt = c² Δu`; and `u(x, t) = 0` whenever `t < |x|/c`. -/
theorem retarded_point_field_solves_wave_equation {c : ℝ} (hc : 0 < c) (q : ℝ → ℝ)
    (hq : ContDiff ℝ 2 q) (hq0 : ∀ t, t < 0 → q t = 0) :
    ∀ x : EuclideanSpace ℝ (Fin 3), x ≠ 0 → ∀ t : ℝ,
      ContDiffAt ℝ 2 (fun y => retardedPointField c q y t) x ∧
        iteratedDeriv 2 (fun s => retardedPointField c q x s) t =
          c ^ 2 * Δ (fun y => retardedPointField c q y t) x ∧
        (t < ‖x‖ / c → retardedPointField c q x t = 0) := by
  intro x hx t
  obtain ⟨hq1, hq2, -, -⟩ := rg_q_facts hq
  have hr : 0 < ‖x‖ := norm_pos_iff.mpr hx
  have hK : 0 < 4 * π * c ^ 2 := by positivity
  refine ⟨?_, ?_, ?_⟩
  · unfold retardedPointField
    have hn : ContDiffAt ℝ 2 (fun y : EuclideanSpace ℝ (Fin 3) => ‖y‖) x := contDiffAt_norm ℝ hx
    exact (hq.contDiffAt.comp x (contDiffAt_const.sub (hn.div_const c))).div
      (contDiffAt_const.mul hn) (by positivity)
  · -- time side
    have hd1 : deriv (fun s => retardedPointField c q x s) =
        fun s => deriv q (s - ‖x‖ / c) / (4 * π * c ^ 2 * ‖x‖) := by
      funext s
      have := ((hq1 (s - ‖x‖ / c)).comp s ((hasDerivAt_id s).sub_const (‖x‖ / c))).div_const
        (4 * π * c ^ 2 * ‖x‖)
      simpa [retardedPointField] using this.deriv
    have hd2 : deriv (fun s => deriv q (s - ‖x‖ / c) / (4 * π * c ^ 2 * ‖x‖)) t =
        deriv (deriv q) (t - ‖x‖ / c) / (4 * π * c ^ 2 * ‖x‖) := by
      have := ((hq2 (t - ‖x‖ / c)).comp t ((hasDerivAt_id t).sub_const (‖x‖ / c))).div_const
        (4 * π * c ^ 2 * ‖x‖)
      simpa using this.deriv
    rw [iteratedDeriv_succ, iteratedDeriv_one, hd1, hd2]
    -- space side
    have hf : ∀ᶠ y in 𝓝 x, HasFDerivAt (fun z => retardedPointField c q z t)
        ((fun r => -(deriv q (t - r / c) * r / c + q (t - r / c)) / (4 * π * c ^ 2 * r ^ 3))
          ‖y‖ • innerSL ℝ y) y := by
      filter_upwards [isOpen_ne.mem_nhds hx] with y hy
      exact rg_hasFDerivAt_field hc hq t hy
    have hP : HasDerivAt (fun r => deriv q (t - r / c) * r / c + q (t - r / c))
        (-(deriv (deriv q) (t - ‖x‖ / c)) * ‖x‖ / c ^ 2) ‖x‖ := by
      have ha : HasDerivAt (fun r => t - r / c) (-(1 / c)) ‖x‖ :=
        ((hasDerivAt_id _).div_const c).const_sub t
      have h1 : HasDerivAt (fun r => deriv q (t - r / c) * r / c) _ ‖x‖ :=
        (((hq2 _).comp _ ha).mul (hasDerivAt_id ‖x‖)).div_const c
      have h2 : HasDerivAt (fun r => q (t - r / c)) _ ‖x‖ := (hq1 _).comp _ ha
      refine (h1.add h2).congr_deriv ?_
      simp
      field_simp
      ring
    have hh : HasDerivAt
        (fun r => -(deriv q (t - r / c) * r / c + q (t - r / c)) / (4 * π * c ^ 2 * r ^ 3))
        ((-(-(deriv (deriv q) (t - ‖x‖ / c)) * ‖x‖ / c ^ 2) * (4 * π * c ^ 2 * ‖x‖ ^ 3) -
          -(deriv q (t - ‖x‖ / c) * ‖x‖ / c + q (t - ‖x‖ / c)) *
            (4 * π * c ^ 2 * (3 * ‖x‖ ^ 2))) / (4 * π * c ^ 2 * ‖x‖ ^ 3) ^ 2) ‖x‖ := by
      have hb : HasDerivAt (fun r : ℝ => 4 * π * c ^ 2 * r ^ 3) (4 * π * c ^ 2 * (3 * ‖x‖ ^ 2))
          ‖x‖ := by
        have := (hasDerivAt_pow 3 ‖x‖).const_mul (4 * π * c ^ 2)
        simpa using this
      exact hP.neg.div hb (by positivity)
    rw [rg_laplacian_radial hx hf hh]
    field_simp
    ring
  · intro ht
    have : t - ‖x‖ / c < 0 := by linarith
    simp [retardedPointField, hq0 _ this]


/-- At the source, the flux out of a small sphere is the source strength. With `c > 0` and `q`
twice continuously differentiable, at every point `x ≠ 0` the outward flux density
`-4π |x|² c² ∂u/∂r` equals `q(t - |x|/c) + (|x|/c) q'(t - |x|/c)`; and along any direction `e`
of length one, this flux at `ε e` tends to `q(t)` as the radius `ε` shrinks to `0`. This is
what makes `u_tt - c² Δu = q(t) δ(x)`. -/
theorem retarded_point_field_flux_tends_to_source {c : ℝ} (hc : 0 < c) (q : ℝ → ℝ)
    (hq : ContDiff ℝ 2 q) (t : ℝ) :
    (∀ x : EuclideanSpace ℝ (Fin 3), x ≠ 0 →
        -4 * π * ‖x‖ ^ 2 * c ^ 2 *
            fderiv ℝ (fun y => retardedPointField c q y t) x (‖x‖⁻¹ • x) =
          q (t - ‖x‖ / c) + ‖x‖ / c * deriv q (t - ‖x‖ / c)) ∧
      ∀ e : EuclideanSpace ℝ (Fin 3), ‖e‖ = 1 →
        Tendsto (fun ε : ℝ => -4 * π * ε ^ 2 * c ^ 2 *
            fderiv ℝ (fun y => retardedPointField c q y t) (ε • e) e) (𝓝[>] 0) (𝓝 (q t)) := by
  obtain ⟨-, -, hqc, hq1c⟩ := rg_q_facts hq
  have key : ∀ x : EuclideanSpace ℝ (Fin 3), x ≠ 0 →
      -4 * π * ‖x‖ ^ 2 * c ^ 2 *
          fderiv ℝ (fun y => retardedPointField c q y t) x (‖x‖⁻¹ • x) =
        q (t - ‖x‖ / c) + ‖x‖ / c * deriv q (t - ‖x‖ / c) := by
    intro x hx
    have hr : 0 < ‖x‖ := norm_pos_iff.mpr hx
    rw [(rg_hasFDerivAt_field hc hq t hx).fderiv]
    simp [innerSL_apply_apply]
    field_simp
    ring
  refine ⟨key, fun e he => ?_⟩
  have hcont : Continuous fun ε : ℝ => q (t - ε / c) + ε / c * deriv q (t - ε / c) := by
    fun_prop
  have hlim : Tendsto (fun ε : ℝ => q (t - ε / c) + ε / c * deriv q (t - ε / c)) (𝓝[>] 0)
      (𝓝 (q t)) := by
    have := (hcont.tendsto 0).mono_left (nhdsWithin_le_nhds (s := Set.Ioi 0))
    simpa using this
  refine hlim.congr' ?_
  filter_upwards [self_mem_nhdsWithin] with ε (hε : 0 < ε)
  have hne : ε • e ≠ 0 := by
    intro h0
    have := congrArg norm h0
    simp [norm_smul, he] at this
    linarith
  have hn : ‖ε • e‖ = ε := by simp [norm_smul, he, abs_of_pos hε]
  have := key (ε • e) hne
  rw [hn] at this
  rw [← this, inv_smul_smul₀ hε.ne']

/-- One hall mode driven at its own frequency. Let `ω > 0` and `F` be the forcing amplitude.
Without losses, `A(t) = F t sin(ωt) / (2ω)` starts from rest (`A(0) = 0`, `A'(0) = 0`) and solves
`A'' + ω² A = F cos(ωt)` for all `t`: the swing grows by `F/(2ω)` every second. With a drain
at rate `γ > 0`, `F sin(ωt) / (2γω)` solves `A'' + 2γ A' + ω² A = F cos(ωt)`, and every solution
for `t ≥ 0` approaches it: the swing is capped at `F/(2γω)`. -/
theorem matched_mode_grows_then_is_capped {ω F : ℝ} (hω : 0 < ω) :
    ((fun t : ℝ => F * t * sin (ω * t) / (2 * ω)) 0 = 0 ∧
      deriv (fun t : ℝ => F * t * sin (ω * t) / (2 * ω)) 0 = 0 ∧
      ∀ t, iteratedDeriv 2 (fun s : ℝ => F * s * sin (ω * s) / (2 * ω)) t +
          ω ^ 2 * (F * t * sin (ω * t) / (2 * ω)) = F * cos (ω * t)) ∧
    ∀ γ : ℝ, 0 < γ →
      (∀ t, iteratedDeriv 2 (fun s : ℝ => F * sin (ω * s) / (2 * γ * ω)) t +
          2 * γ * deriv (fun s : ℝ => F * sin (ω * s) / (2 * γ * ω)) t +
          ω ^ 2 * (F * sin (ω * t) / (2 * γ * ω)) = F * cos (ω * t)) ∧
      ∀ A A' A'' : ℝ → ℝ,
        (∀ t, 0 ≤ t → HasDerivAt A (A' t) t) → (∀ t, 0 ≤ t → HasDerivAt A' (A'' t) t) →
        (∀ t, 0 ≤ t → A'' t + 2 * γ * A' t + ω ^ 2 * A t = F * cos (ω * t)) →
        Tendsto (fun t => A t - F * sin (ω * t) / (2 * γ * ω)) atTop (𝓝 0) := by
  have hω0 : ω ≠ 0 := hω.ne'
  have hsin : ∀ t, HasDerivAt (fun s => sin (ω * s)) (cos (ω * t) * ω) t := fun t => by
    simpa using ((hasDerivAt_id t).const_mul ω).sin
  have hcos : ∀ t, HasDerivAt (fun s => cos (ω * s)) (-sin (ω * t) * ω) t := fun t => by
    simpa using ((hasDerivAt_id t).const_mul ω).cos
  -- undamped
  have hf1 : ∀ t, HasDerivAt (fun s : ℝ => F * s * sin (ω * s) / (2 * ω))
      (F * (sin (ω * t) + t * ω * cos (ω * t)) / (2 * ω)) t := fun t => by
    have := (((hasDerivAt_id t).const_mul F).mul (hsin t)).div_const (2 * ω)
    refine this.congr_deriv ?_
    simp
    ring
  have hd1 : deriv (fun s : ℝ => F * s * sin (ω * s) / (2 * ω)) =
      fun t => F * (sin (ω * t) + t * ω * cos (ω * t)) / (2 * ω) := funext fun t => (hf1 t).deriv
  have hf2 : ∀ t, HasDerivAt (fun t => F * (sin (ω * t) + t * ω * cos (ω * t)) / (2 * ω))
      (F * cos (ω * t) - F * t * ω * sin (ω * t) / 2) t := fun t => by
    have := (((hsin t).add (((hasDerivAt_id t).mul_const ω).mul (hcos t))).const_mul F).div_const
      (2 * ω)
    refine this.congr_deriv ?_
    simp
    field_simp
    ring
  -- damped particular solution
  have hp1 : ∀ γ : ℝ, ∀ t, HasDerivAt (fun s : ℝ => F * sin (ω * s) / (2 * γ * ω))
      (F * ω * cos (ω * t) / (2 * γ * ω)) t := fun γ t => by
    have := ((hsin t).const_mul F).div_const (2 * γ * ω)
    refine this.congr_deriv ?_
    ring
  have hp2 : ∀ γ : ℝ, ∀ t, HasDerivAt (fun t : ℝ => F * ω * cos (ω * t) / (2 * γ * ω))
      (-(F * ω * ω * sin (ω * t)) / (2 * γ * ω)) t := fun γ t => by
    have := ((hcos t).const_mul (F * ω)).div_const (2 * γ * ω)
    refine this.congr_deriv ?_
    ring
  refine ⟨⟨by simp, ?_, ?_⟩, fun γ hγ => ⟨?_, ?_⟩⟩
  · rw [hd1]; simp
  · intro t
    rw [iteratedDeriv_succ, iteratedDeriv_one, hd1, (hf2 t).deriv]
    field_simp
    ring
  · intro t
    have hd : deriv (fun s : ℝ => F * sin (ω * s) / (2 * γ * ω)) =
        fun t => F * ω * cos (ω * t) / (2 * γ * ω) := funext fun t => (hp1 γ t).deriv
    rw [iteratedDeriv_succ, iteratedDeriv_one, hd, (hp2 γ t).deriv]
    field_simp
    ring
  · intro A A' A'' hA hA' hode
    refine rg_damped_decay (a := 2 * γ) (b := ω ^ 2) (by positivity) (by positivity)
      (fun t => A t - F * sin (ω * t) / (2 * γ * ω))
      (fun t => A' t - F * ω * cos (ω * t) / (2 * γ * ω))
      (fun t => A'' t - -(F * ω * ω * sin (ω * t)) / (2 * γ * ω))
      (fun t ht => (hA t ht).sub (hp1 γ t)) (fun t ht => (hA' t ht).sub (hp2 γ t)) ?_
    intro t ht
    have := hode t ht
    field_simp
    linear_combination (2 * γ) * this

/-- The hall is 34.3 m long, exactly 88 half-wavelengths at 440 Hz: mode (88, 0, 0) is at
`88 c / (2 L_x) = 440` Hz with `c = 343` m/s. -/
example : (88 : ℚ) * 343 / (2 * (343 / 10)) = 440 := by norm_num

/-- Arrival time at the seat: `17.15 / 343 = 1/20` s, that is 50 ms. -/
example : ((1715 : ℚ) / 100) / 343 = 1 / 20 := by norm_num

/-- 50 ms is exactly 22 cycles of 440 Hz. -/
example : (440 : ℚ) * (1 / 20) = 22 := by norm_num

/-- The mode size `N = V/2 = 34.3 × 20 × 12 / 2 = 4116` m³. -/
example : (343 / 10 : ℚ) * 20 * 12 / 2 = 4116 := by norm_num

/-- The mode's phase `88 x / L_x` (in units of `π`) is `8.8` at the speaker (3.43 m) and `52.8`
at the seat (20.58 m); they differ by `44`, a whole number of full turns, so the mode has the same
height at both. -/
example : (88 : ℚ) * (343 / 100) / (343 / 10) = 44 / 5 ∧
    (88 : ℚ) * (2058 / 100) / (343 / 10) - 88 * (343 / 100) / (343 / 10) = 44 := by norm_num

#print axioms retarded_point_field_solves_wave_equation
#print axioms retarded_point_field_flux_tends_to_source
#print axioms matched_mode_grows_then_is_capped
#print axioms rg_hasFDerivAt_norm
#print axioms rg_iteratedFDeriv_two_radial
#print axioms rg_laplacian_radial
#print axioms rg_q_facts
#print axioms rg_hasFDerivAt_field
#print axioms rg_damped_decay
