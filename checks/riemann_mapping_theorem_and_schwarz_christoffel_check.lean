-- The Riemann mapping theorem: every open simply connected region of the plane other than the whole plane has exactly one one-to-one holomorphic map onto the unit disc sending a chosen point to 0 with real positive derivative there, every such self-map of the disc is a Blaschke factor times a turn, and sin z maps the half strip of width π one-to-one onto the upper half plane.
import Mathlib.AlgebraicTopology.FundamentalGroupoid.SimplyConnected
import Mathlib.Analysis.Complex.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum
import Mathlib

open Set Metric Complex

-- Helper lemmas. The disc shift, Hurwitz-type limit lemmas and the existence proof are adapted from
-- Yury Kudryashov's Riemann mapping draft, mathlib4 pull request #33505 (Apache 2.0 license).

open Set Metric Function Filter
open scoped Pointwise Topology ComplexConjugate Real BigOperators Uniformity

noncomputable section

namespace Complex.UnitDisc


lemma shift_den_ne_zero (z w : 𝔻) : 1 + conj (z : ℂ) * w ≠ 0 :=
  (star z * w).one_add_coe_ne_zero

#print axioms shift_den_ne_zero

lemma shift_den_ne_zero' (z w : 𝔻) : 1 + z * conj (w : ℂ) ≠ 0 :=
  (z * star w).one_add_coe_ne_zero


#print axioms shift_den_ne_zero'

theorem norm_shiftFun_le (z w : 𝔻) :
    ‖(z + w : ℂ) / (1 + conj ↑z * w)‖ ≤ (‖(z : ℂ)‖ + ‖(w : ℂ)‖) / (1 + ‖(z : ℂ)‖ * ‖(w : ℂ)‖) := by
  have hz := z.sq_norm_lt_one
  have hw := w.sq_norm_lt_one
  have hzw : z.re * w.re + z.im * w.im ≤ ‖(z : ℂ)‖ * ‖(w : ℂ)‖ := by
    rw [norm_def, norm_def, ← Real.sqrt_mul, normSq_apply, normSq_apply]
    · apply Real.le_sqrt_of_sq_le
      linear_combination (norm := {apply le_of_eq; simp; ring})
        sq_nonneg (z.re * w.im - z.im * w.re)
    · apply normSq_nonneg
  rw [norm_div, div_le_div_iff₀, ← sq_le_sq₀]
  · rw [← sub_nonneg] at hzw
    simp [mul_pow, RCLike.norm_sq_eq_def, add_sq] at hz hw ⊢
    linear_combination 2 * mul_nonneg hzw (mul_nonneg (sub_nonneg.2 hz.le) (sub_nonneg.2 hw.le))
  any_goals positivity
  simpa using shift_den_ne_zero z w

#print axioms norm_shiftFun_le

/-- Auxiliary definition for `shift` below. This function is not a part of the public API. -/
def shiftFun (z w : 𝔻) : 𝔻 :=
  mk ((z + w : ℂ) / (1 + conj ↑z * w)) <| by
    refine (norm_shiftFun_le _ _).trans_lt ?_
    rw [div_lt_one (by positivity)]
    nlinarith only [z.norm_lt_one, w.norm_lt_one]

theorem coe_shiftFun (z w : 𝔻) : (shiftFun z w : ℂ) = (z + w) / (1 + conj ↑z * w) := rfl

#print axioms coe_shiftFun

theorem shiftFun_eq_iff {z w u : 𝔻} : shiftFun z w = u ↔ (z + w : ℂ) = u + u * conj ↑z * w := by
  rw [← coe_inj, coe_shiftFun, div_eq_iff (shift_den_ne_zero _ _)]
  ring_nf

#print axioms shiftFun_eq_iff

theorem shiftFun_neg_apply_shiftFun (z w : 𝔻) : shiftFun (-z) (shiftFun z w) = w := by
  rw [shiftFun_eq_iff, coe_shiftFun, add_div_eq_mul_add_div, ← mul_div_assoc,
    add_div_eq_mul_add_div]
  · simp; ring
  all_goals exact shift_den_ne_zero z w


#print axioms shiftFun_neg_apply_shiftFun

/-- The automorphism of the unit disc that sends zero to `z`. -/
def shift (z : 𝔻) : 𝔻 ≃ 𝔻 where
  toFun := shiftFun z
  invFun := shiftFun (-z)
  left_inv := shiftFun_neg_apply_shiftFun _
  right_inv := fun w ↦ by simpa using shiftFun_neg_apply_shiftFun (-z) w

/-- An explicit formula for `shift z w`.

Note that the definition of `shift` is not exposed, so this is not a `dsimp` lemma. -/
theorem coe_shift (z w : 𝔻) : (shift z w : ℂ) = (z + w) / (1 + conj ↑z * w) := by rfl

#print axioms coe_shift

theorem shift_eq_iff {z w u : 𝔻} : shift z w = u ↔ (z + w : ℂ) = u + u * conj ↑z * w :=
  shiftFun_eq_iff

#print axioms shift_eq_iff

theorem symm_shift (z : 𝔻) : (shift z).symm = shift (-z) := by
  ext1
  rfl

#print axioms symm_shift

@[simp]
theorem star_shift (z w : 𝔻) : star (shift z w) = shift (star z) (star w) :=
  coe_injective <| by simp [coe_shift]

#print axioms star_shift

theorem norm_shift_swap (z w : 𝔻) : ‖(shift z w : ℂ)‖ = ‖(shift w z : ℂ)‖ := by
  rw [coe_shift, norm_div, ← norm_conj (1 + _)]
  simp [coe_shift, add_comm, mul_comm]

#print axioms norm_shift_swap

theorem neg_shift (z w : 𝔻) : -shift z w = shift (-z) (-w) := by
  ext1
  simp [coe_shift, ← neg_add_rev, add_comm, neg_div]

#print axioms neg_shift

@[simp]
theorem shift_zero : shift 0 = .refl 𝔻 := by
  ext z
  simp [coe_shift]

#print axioms shift_zero

@[simp]
theorem shift_apply_zero (z : 𝔻) : shift z 0 = z := by simp [shift_eq_iff]

#print axioms shift_apply_zero

@[simp]
theorem shift_eq_zero_iff {z w : 𝔻} : shift z w = 0 ↔ w = -z := by
  rw [← Equiv.eq_symm_apply, symm_shift, shift_apply_zero]

#print axioms shift_eq_zero_iff

@[simp]
theorem shift_apply_neg_self (z : 𝔻) : shift z (-z) = 0 := by simp

#print axioms shift_apply_neg_self

@[simp]
theorem shift_neg_apply_self (z : 𝔻) : shift (-z) z = 0 := by simp

#print axioms shift_neg_apply_self

@[simp]
theorem shift_neg_apply_shift (z w : 𝔻) : shift (-z) (shift z w) = w := by
  rw [← symm_shift, Equiv.symm_apply_apply]

#print axioms shift_neg_apply_shift

@[simp]
theorem shift_apply_shift_neg (z w : 𝔻) : shift z (shift (-z) w) = w := by
  simpa using shift_neg_apply_shift (-z) w

#print axioms shift_apply_shift_neg

theorem neg_shift_neg (z w : 𝔻) : -z.shift (-w) = (-z).shift w := by
  rw [eq_comm, shift_eq_iff, coe_neg, coe_neg, coe_shift]
  field_simp (disch := apply shift_den_ne_zero')
  simp; ring

#print axioms neg_shift_neg

theorem involutive_shift_comp_neg (z : 𝔻) : (shift z <| -·).Involutive := by
  intro x
  simp [neg_shift_neg]

#print axioms involutive_shift_comp_neg

theorem norm_shift_le (z w : 𝔻) :
    ‖(z.shift w : ℂ)‖ ≤ (‖(z : ℂ)‖ + ‖(w : ℂ)‖) / (1 + ‖(z : ℂ)‖ * ‖(w : ℂ)‖) :=
  norm_shiftFun_le z w

#print axioms norm_shift_le

/-- A shift by `0` is the identity map, and all other shifts have no fixed points. -/
@[simp]
theorem shift_eq_self_iff {z w : 𝔻} : shift z w = w ↔ z = 0 := by
  rcases eq_or_ne z 0 with rfl | hz
  · simp
  suffices (z : ℂ) ≠ w * conj ↑z * w by
    simpa [shift_eq_iff, hz, add_comm (z : ℂ)] using this
  refine ne_of_apply_ne norm (ne_of_gt ?_)
  calc
    _ = ‖(z : ℂ)‖ * ‖(w : ℂ)‖ ^ 2 := by simp; ring
    _ < ‖(z : ℂ)‖ := mul_lt_of_lt_one_right (by simpa) <| by
      rw [← Complex.normSq_eq_norm_sq]; exact w.normSq_lt_one

#print axioms shift_eq_self_iff

lemma shift_apply_circle_smul (c : Circle) (z w : 𝔻) :
    shift z (c • w) = c • shift (c⁻¹ • z) w := by
  ext1
  simp only [coe_shift, coe_circle_smul, ← mul_div_assoc, mul_add,
    map_mul, Circle.coe_inv_eq_conj, Complex.conj_conj, ← mul_assoc]
  rw [← Circle.coe_inv_eq_conj, ← Circle.coe_mul]
  simp [mul_comm (c : ℂ)]

#print axioms shift_apply_circle_smul

/-- The composition of two shifts is a rotation by `shiftCompCoeff z w` composed with a shift. -/
@[simps! coe]
def shiftCompCoeff (z w : 𝔻) : Circle :=
  .ofConjDivSelf (1 + conj ↑z * w) (shift_den_ne_zero _ _)

theorem shift_apply_shift (z w u : 𝔻) :
    shift z (shift w u) = shiftCompCoeff z w • shift (shift w z) u := by
  ext1
  have H₁ (z w u : 𝔻) : 1 + u * conj (w : ℂ) + (w + u) * conj (z : ℂ) ≠ 0 := by
    have := shift_den_ne_zero' (shift w u) z
    rw [coe_shift, div_mul_eq_mul_div₀, add_div_eq_mul_add_div, div_ne_zero_iff] at this
    · simpa [mul_comm] using this.left
    · apply shift_den_ne_zero
  have H₂ : 1 + w * conj (z : ℂ) + u * (conj ↑w + conj ↑z) ≠ 0 := by
    simpa [mul_comm] using H₁ (star u) (star w) (star z)
  simp [coe_shift]
  field_simp
    (disch := first | apply shift_den_ne_zero | apply shift_den_ne_zero' | apply H₁ | exact H₂)
  ring

#print axioms shift_apply_shift

theorem shift_trans_shift (z w : 𝔻) :
    (shift z).trans (shift w) =
      (shift (shift z w)).trans (MulAction.toPerm (shiftCompCoeff w z)) := by
  ext1 u
  simp [shift_apply_shift]

#print axioms shift_trans_shift

end UnitDisc

end Complex


theorem TendstoUniformly.fun_const_of_tendsto {ι α X : Type*} [UniformSpace X] {f : ι → X}
    {l : Filter ι} {x : X} (h : Tendsto f l (𝓝 x)) :
    TendstoUniformly (fun i (_ : α) ↦ f i) (fun _ : α ↦ x) l := by
  intro U hU
  filter_upwards [(tendsto_left_nhds_uniformity (a := x)).comp h hU] with i hi y using hi

#print axioms TendstoUniformly.fun_const_of_tendsto

alias Filter.Tendsto.tendstoUniformly_fun_const := TendstoUniformly.fun_const_of_tendsto

theorem AnalyticOnNhd.exists_finset_eq_prod_smul_nonzero
    {𝕜 E : Type*} [NontriviallyNormedField 𝕜]
    [NormedAddCommGroup E] [NormedSpace 𝕜 E] {f : 𝕜 → E} {s : Set 𝕜}
    (hfs : AnalyticOnNhd 𝕜 f s) (hs_comp : IsCompact s) (hs_conn : IsPreconnected s)
    (hf₀ : ¬EqOn f 0 s) :
    ∃ (t : Finset 𝕜), (∀ x, x ∈ t ↔ x ∈ s ∧ f x = 0) ∧
      ∃ (g : 𝕜 → E), AnalyticOnNhd 𝕜 g s ∧
        (f = fun z ↦ (∏ x ∈ t, (z - x) ^ analyticOrderNatAt f x) • g z) ∧
        (∀ z ∈ s, g z ≠ 0) := by
  have hf_top : ∀ {f : 𝕜 → E}, AnalyticOnNhd 𝕜 f s → ¬EqOn f 0 s → ∀ x ∈ s,
      analyticOrderAt f x ≠ ⊤ := by
    intro f hfs hf₀ x hx hfx
    rw [analyticOrderAt_eq_top] at hfx
    exact hf₀ <| hfs.eqOn_zero_of_preconnected_of_eventuallyEq_zero hs_conn hx hfx
  obtain ⟨t, hts⟩ : ∃ t : Finset 𝕜, ∀ x, x ∈ t ↔ x ∈ s ∧ f x = 0 := by
    use hs_comp.finite_diff_of_mem_codiscreteWithin
      hfs.codiscreteWithin_setOf_analyticOrderAt_eq_zero_or_top |>.toFinset
    simp only [Finite.mem_toFinset, mem_diff, mem_setOf_eq, not_or, analyticOrderAt_eq_zero,
      and_congr_right_iff]
    push_neg
    intro x hx
    simp [hfs _ hx, hf_top hfs hf₀ x hx]
  use t, hts
  induction t using Finset.cons_induction generalizing f with
  | empty =>
    use f, hfs
    simpa using hts
  | cons a t hat iht =>
    simp only [Finset.mem_cons] at hts
    have has : a ∈ s := (hts a).mp (.inl rfl) |>.1
    -- TODO: upgrade `AnalyticAt.analyticOrderAt_ne_top`
    obtain ⟨g, hga, hg₀, hfg⟩ : ∃ g, AnalyticOnNhd 𝕜 g s ∧ g a ≠ 0 ∧
        f = fun z ↦ (z - a) ^ analyticOrderNatAt f a • g z := by
      classical
      rcases hfs a has |>.analyticOrderAt_ne_top |>.mp
        (hf_top hfs hf₀ a has) with ⟨g, hga, hg₀, hfg⟩
      set g' := update (fun z ↦ (z - a) ^ (-analyticOrderNatAt f a : ℤ) • f z) a (g a)
      have hgg' : g =ᶠ[𝓝 a] g' := by
        refine hfg.mono fun z hz ↦ ?_
        rcases eq_or_ne z a with rfl | hza
        · simp [g']
        · simp [g', hza, hz, sub_eq_zero]
      refine ⟨g', ?_, ?_, ?_⟩
      · intro z hz
        rcases eq_or_ne z a with rfl | hza
        · exact hga.congr hgg'
        · have : g' =ᶠ[𝓝 z] fun z ↦ (z - a) ^ (-analyticOrderNatAt f a : ℤ) • f z :=
            eventually_ne_nhds hza |>.mono fun w hw ↦ by simp [g', hw]
          rw [analyticAt_congr this]
          refine .smul (.zpow ?_ (by rwa [sub_ne_zero])) (hfs z hz)
          fun_prop
      · simp [g', hg₀]
      · ext z
        rcases eq_or_ne z a with rfl | hza
        · simpa [g'] using hfg.self_of_nhds
        · simp [g', hza, sub_eq_zero]
    have hgt : ∀ z, z ∈ t ↔ z ∈ s ∧ g z = 0 := by
      rw [hfg] at hts
      intro z
      rcases eq_or_ne z a with rfl | hza
      · simp [hg₀, hat]
      · simpa [hza, sub_eq_zero] using hts z
    have hgs₀ : ¬EqOn g 0 s := by
      intro hgs₀
      exact hg₀ <| hgs₀ has
    rcases iht hga hgs₀ hgt with ⟨g', hg's, hgg', hg'₀⟩
    use g', hg's, ?_, hg'₀
    ext z
    rw [congrFun hfg, congrFun hgg', Finset.prod_cons, mul_smul]
    congr 2
    refine Finset.prod_congr rfl fun x hx ↦ ?_
    congr 1
    -- TODO: avoid unfolding `analyticOrderNatAt` by adding lemmas
    conv_rhs => rw [hfg, analyticOrderNatAt]
    rw [← Pi.smul_def', analyticOrderAt_smul]
    · suffices analyticOrderAt (fun z ↦ (z - a) ^ analyticOrderNatAt f a) x = 0 by
        rw [this]; simp [analyticOrderNatAt]
      rw [analyticOrderAt_eq_zero]
      right
      simp [sub_eq_zero, ne_of_mem_of_not_mem hx hat]
    · fun_prop
    · exact hga _ <| ((hts _).mp <| .inr hx).1

#print axioms AnalyticOnNhd.exists_finset_eq_prod_smul_nonzero

namespace Complex

-- TODO: replace `AnalyticOnNhd` with `AnalyticOn`?
theorem circleIntegral_logDeriv_eq_finsum_analyticOrderNatAdd {f : ℂ → ℂ} {c : ℂ} {R : ℝ}
    (hf : AnalyticOnNhd ℂ f (closedBall c R)) (hf₀ : ∀ z ∈ sphere c R, f z ≠ 0) (hR : 0 ≤ R) :
    ∮ z in C(c, R), logDeriv f z = (2 * π * I) * ∑ᶠ z ∈ ball c R, analyticOrderNatAt f z := by
  rcases hf.exists_finset_eq_prod_smul_nonzero (isCompact_closedBall _ _) isPreconnected_closedBall
    (fun hf₀' ↦ ((NormedSpace.sphere_nonempty (x := c)).mpr hR).elim fun x hx ↦
      hf₀ x hx <| hf₀' <| sphere_subset_closedBall hx)
    with ⟨t, htR, g, hgR, hfg, hg₀⟩
  have hne : ∀ z ∈ sphere c R, ∀ w ∈ t, z - w ≠ 0 := by
    intro z hz w hw
    rw [sub_ne_zero]
    rintro rfl
    rw [htR] at hw
    exact hf₀ _ hz hw.2
  have ht_sub : ↑t ⊆ ball c R := by
    intro w hw
    rw [Finset.mem_coe, htR, ← sphere_union_ball, mem_union] at hw
    exact hw.1.resolve_left fun hw' ↦ hf₀ w hw' hw.2
  have hleft : EqOn (logDeriv f)
      (fun z ↦ (∑ w ∈ t, analyticOrderNatAt f w / (z - w)) + logDeriv g z) (sphere c R) := by
    intro z hz
    conv_lhs => rw [hfg]
    simp only [smul_eq_mul]
    rw [logDeriv_fun_mul, logDeriv_fun_prod]
    · congr 1
      refine Finset.sum_congr rfl fun w hw ↦ ?_
      rw [logDeriv_fun_pow (by fun_prop), logDeriv, Pi.div_apply, deriv_sub_const, deriv_id'']
      simp [div_eq_mul_inv]
    · intro w hw
      apply pow_ne_zero
      exact hne z hz w hw
    · intros
      fun_prop
    · rw [Finset.prod_ne_zero_iff]
      exact fun w hw ↦ pow_ne_zero _ (hne z hz w hw)
    · exact hg₀ z (sphere_subset_closedBall hz)
    · fun_prop
    · exact hgR _ (sphere_subset_closedBall hz) |>.differentiableAt
  rw [finsum_mem_eq_sum_of_subset (t := t), circleIntegral.integral_congr hR hleft]
  · have hdg : AnalyticOnNhd ℂ (logDeriv g) (closedBall c R) :=
      hgR.deriv.div hgR hg₀
    have hi : ∀ w ∈ t, CircleIntegrable (fun z ↦ analyticOrderNatAt f w / (z - w)) c R := by
      intro w hw
      simp only [div_eq_mul_inv]
      refine .const_mul (circleIntegrable_sub_inv_iff.mpr <| .inr fun hw' ↦ ?_) _
      rw [abs_of_nonneg hR] at hw'
      exact hne w hw' w hw (sub_self _)
    rw [circleIntegral.integral_add, circleIntegral.integral_fun_sum,
      DiffContOnCl.circleIntegral_eq_zero hR, add_zero, Nat.cast_sum, Finset.mul_sum]
    · refine Finset.sum_congr rfl fun w hw ↦ ?_
      rw [circleIntegral_div_sub_of_differentiable_on_off_countable countable_empty]
      · exact ht_sub hw
      · fun_prop
      · intros; fun_prop
    · exact hdg.differentiableOn.diffContOnCl_ball subset_rfl
    · exact hi
    · exact .fun_sum _ hi
    · exact hdg.continuousOn.mono sphere_subset_closedBall |>.circleIntegrable hR
  · rintro z ⟨hzc, hz⟩
    rw [mem_support, analyticOrderNatAt, ne_eq, ENat.toNat_eq_zero, not_or,
      analyticOrderAt_eq_zero, not_or, not_not, ne_eq, not_not] at hz
    replace hz := hz.1.2
    rw [hfg, smul_eq_zero, Finset.prod_eq_zero_iff] at hz
    rcases hz.resolve_right (hg₀ z <| ball_subset_closedBall hzc) with ⟨w, hwt, hzw⟩
    have hzw' : z = w := sub_eq_zero.mp (eq_zero_of_pow_eq_zero hzw)
    subst hzw'
    exact_mod_cast hwt
  · exact ht_sub

#print axioms circleIntegral_logDeriv_eq_finsum_analyticOrderNatAdd

theorem eqOn_zero_or_forall_ne_zero_of_tendstoLocallyUniformlyOn {ι : Type*} {U : Set ℂ}
    {l : Filter ι} [l.NeBot] [l.IsCountablyGenerated] {F : ι → ℂ → ℂ} {f : ℂ → ℂ}
    (hUo : IsOpen U) (hUc : IsPreconnected U) (hF : ∀ᶠ i in l, ∀ x ∈ U, F i x ≠ 0)
    (hFd : ∀ᶠ i in l, DifferentiableOn ℂ (F i) U) (hf : TendstoLocallyUniformlyOn F f l U) :
    EqOn f 0 U ∨ ∀ x ∈ U, f x ≠ 0 := by
  have hfd : DifferentiableOn ℂ f U := hf.differentiableOn hFd hUo
  rw [or_iff_not_imp_left]
  intro hf₀ c hc hfc
  rcases hfd.analyticAt (hUo.mem_nhds hc) |>.eventually_eq_zero_or_eventually_ne_zero
    with hfc₀ | hfc₀
  · exact hf₀ <| hfd.analyticOnNhd hUo |>.eqOn_zero_of_preconnected_of_eventuallyEq_zero hUc hc hfc₀
  · obtain ⟨R, hR₀, hRU, hfR⟩ : ∃ R > 0, closedBall c R ⊆ U ∧ ∀ w ∈ sphere c R, f w ≠ 0 := by
      rw [eventually_nhdsWithin_iff] at hfc₀
      rcases Metric.nhds_basis_closedBall.eventually_iff.mp (hfc₀.and <| hUo.eventually_mem hc)
        with ⟨R, hR₀, hR⟩
      refine ⟨R, hR₀, fun w hw ↦ (hR hw).2, fun w hw ↦ (hR <| sphere_subset_closedBall hw).1 ?_⟩
      exact ne_of_mem_sphere hw hR₀.ne'
    have hRU' : sphere c R ⊆ U := sphere_subset_closedBall.trans hRU
    have hlogDeriv : TendstoUniformlyOn (fun i ↦ logDeriv (F i)) (logDeriv f) l (sphere c R) := by
      simp only [logDeriv]
      have := (hf.deriv hFd hUo).mono hRU'
      rw [← tendstoLocallyUniformlyOn_iff_tendstoUniformlyOn_of_compact
        (isCompact_sphere c R)]
      refine this.fun_div₀ (hf.mono hRU') ?_ ?_ ?_
      · exact hfd.analyticOnNhd hUo |>.deriv |>.continuousOn |>.mono hRU'
      · exact hfd.continuousOn.mono hRU'
      · exact hfR
    have hcirc : Tendsto (fun i ↦ ∮ z in C(c, R), logDeriv (F i) z) l
        (𝓝 (∮ z in C(c, R), logDeriv f z)) := by
      apply hlogDeriv.tendsto_circleIntegral_of_continuousOn hR₀.le
      filter_upwards [hF, hFd] with i hi₀ hiD
      refine .div ?_ (hiD.continuousOn.mono hRU') ?_
      · exact hiD.analyticOnNhd hUo |>.deriv |>.continuousOn |>.mono hRU'
      · exact fun x hx ↦ hi₀ x (hRU' hx)
    have H₀ : ∀ᶠ i in l, ∮ (z : ℂ) in C(c, R), logDeriv (F i) z = 0 := by
      filter_upwards [hF, hFd] with i hi hid
      apply DiffContOnCl.circleIntegral_eq_zero hR₀.le
      exact (hid.deriv hUo).div hid hi |>.diffContOnCl_ball hRU
    have := hcirc.congr' H₀
    rw [tendsto_const_nhds_iff, eq_comm,
      circleIntegral_logDeriv_eq_finsum_analyticOrderNatAdd, mul_eq_zero] at this
    · replace this := this.resolve_left (by simp)
      norm_cast at this
      refine ne_of_gt ?_ this
      apply finsum_cond_pos
      · simp
      · use c
        suffices ∃ᶠ (x : ℂ) in 𝓝 c, f x ≠ 0 by
          simpa [pos_iff_ne_zero, analyticOrderNatAt, analyticOrderAt_eq_zero, hfc,
            analyticOrderAt_eq_top, hfd.analyticAt (hUo.mem_nhds hc), hR₀]
        rw [eventually_nhdsWithin_iff] at hfc₀
        refine Frequently.mp ?_ hfc₀
        rw [frequently_iff_neBot, setOf_mem_eq, ← nhdsWithin]
        infer_instance
      · have := (isCompact_closedBall c R).finite_diff_of_mem_codiscreteWithin
          ((hfd.analyticOnNhd hUo).mono hRU).codiscreteWithin_setOf_analyticOrderAt_eq_zero_or_top
        refine this.subset ?_
        simp +contextual [subset_def, analyticOrderNatAt, le_of_lt]
    · exact hfd.analyticOnNhd hUo |>.mono hRU
    · exact hfR
    · exact hR₀.le

#print axioms eqOn_zero_or_forall_ne_zero_of_tendstoLocallyUniformlyOn

theorem eqOn_const_or_injOn_of_tendstoLocallyUniformlyOn {ι : Type*} {U : Set ℂ}
    {l : Filter ι} [l.NeBot] [l.IsCountablyGenerated] {F : ι → ℂ → ℂ} {f : ℂ → ℂ}
    (hUo : IsOpen U) (hUc : IsPreconnected U) (hF : ∀ᶠ i in l, InjOn (F i) U)
    (hFd : ∀ᶠ i in l, DifferentiableOn ℂ (F i) U) (hf : TendstoLocallyUniformlyOn F f l U) :
    (∃ C, ∀ x ∈ U, f x = C) ∨ InjOn f U := by
  rw [or_iff_not_imp_left]
  intro hfU x hx y hy hxy
  by_contra! hne
  obtain ⟨r, hr₀, hrU, hry⟩ : ∃ r > 0, ball x r ⊆ U ∧ y ∉ ball x r := by
    simp_rw [← subset_compl_singleton_iff, ← subset_inter_iff, ← Metric.mem_nhds_iff]
    simp [hUo.mem_nhds hx, hne]
  have hf_sub : TendstoLocallyUniformlyOn (fun i z ↦ F i z - F i y) (f · - f y) l (ball x r) := by
    refine (hf.mono hrU).fun_sub <|
      (Tendsto.tendstoUniformly_fun_const ?_).tendstoUniformlyOn.tendstoLocallyUniformlyOn
    exact hf.tendsto_at hy
  refine eqOn_zero_or_forall_ne_zero_of_tendstoLocallyUniformlyOn isOpen_ball isPreconnected_ball
    (hF.mono fun i hi z hz ↦ ?_) ?_ hf_sub |>.resolve_left ?_ x (by simpa) (by rwa [sub_eq_zero])
  · rw [sub_ne_zero, hi.ne_iff (hrU hz) hy]
    exact ne_of_mem_of_not_mem hz hry
  · exact hFd.mono fun i hi ↦ hi.mono hrU |>.sub_const _
  · intro heq
    refine hfU ⟨f y, ?_⟩
    refine hf.differentiableOn hFd hUo |>.analyticOnNhd hUo
      |>.eqOn_of_preconnected_of_eventuallyEq analyticOnNhd_const hUc hx ?_
    exact heq.eventuallyEq_of_mem (ball_mem_nhds _ hr₀) |>.mono fun z hz ↦ sub_eq_zero.mp hz

#print axioms eqOn_const_or_injOn_of_tendstoLocallyUniformlyOn

namespace UnitDisc

@[fun_prop]
theorem continuous_shift (z : 𝔻) : Continuous z.shift := by
  simp only [isEmbedding_coe.continuous_iff, Function.comp_def, coe_shift]
  exact .div (by fun_prop) (by fun_prop) fun _ ↦ shift_den_ne_zero _ _

#print axioms continuous_shift

end UnitDisc

theorem exists_mapsTo_unitBall_injOn_deriv_ne_zero_rmt {U : Set ℂ} (hUo : IsOpen U)
    (hUc : IsSimplyConnected U) (hU : U ≠ univ) {x : ℂ} (hx : x ∈ U) :
    ∃ f : ℂ → ℂ, MapsTo f U (ball 0 1) ∧ InjOn f U ∧ ∀ z ∈ U, deriv f z ≠ 0 := by
  wlog hU₀ : 0 ∉ U
  · rw [ne_univ_iff_exists_notMem] at hU
    rcases hU with ⟨a, ha⟩
    specialize this (hUo.vadd (-a)) (by simpa) (by simp [hU]) (x := -a + x)
      (by simpa [mem_vadd_set_iff_neg_vadd_mem]) (by simpa [mem_vadd_set_iff_neg_vadd_mem])
    rcases this with ⟨f, hf₁, hf_inj, hdf⟩
    refine ⟨f ∘ (-a + ·), hf₁.comp (mapsTo_image _ _),
      hf_inj.comp (by simp [InjOn]) (mapsTo_image _ _), fun z hz ↦ ?_⟩
    simpa [Function.comp_def, deriv_comp_const_add] using hdf (-a + z) (mapsTo_image _ _ hz)
  rcases exists_continuousOn_pow_eq hUc hUo continuousOn_id (by rwa [image_id]) two_ne_zero
    with ⟨f, hfc, hf_inv⟩
  replace hf_inv : LeftInverse (· ^ 2) f := hf_inv
  have hf₀ : ∀ z ∈ U, f z ≠ 0 := by
    intro z hz hfz
    simpa [hfz, (ne_of_mem_of_not_mem hz hU₀).symm] using hf_inv z
  have hdf : ∀ z ∈ U, HasStrictDerivAt f (2 * f z)⁻¹ z := by
    intro z hz
    apply HasStrictDerivAt.of_local_left_inverse
    · exact hfc.continuousAt <| hUo.mem_nhds hz
    · simpa using hasStrictDerivAt_pow 2 (f z)
    · simpa using hf₀ z hz
    · exact .of_forall hf_inv
  have hdf' : DifferentiableOn ℂ f U := fun z hz ↦
    (hdf z hz).hasDerivAt.differentiableAt.differentiableWithinAt
  have hfUx : f '' U ∈ 𝓝 (f x) := by
    rw [← (hdf x hx).map_nhds_eq (by simpa using hf₀ x hx)]
    exact Filter.image_mem_map <| hUo.mem_nhds hx
  have hdisj : ∀ a ∈ U, ∀ b ∈ U, f a + f b ≠ 0 := by
    intro a ha b hb hfab
    obtain rfl : b = a := by
      rw [← hf_inv a, ← hf_inv b]
      simp [eq_neg_iff_add_eq_zero.mpr hfab]
    have : f b = 0 := by linear_combination hfab / 2
    exact hf₀ b hb this
  have hfUxc : (f '' U)ᶜ ∈ 𝓝 (-f x) := by
    rw [nhds_neg, Filter.mem_neg]
    filter_upwards [hfUx]
    rintro _ ⟨a, ha, rfl⟩ ⟨b, hb, hab⟩
    exact hdisj a ha b hb (by linear_combination hab)
  rcases Metric.nhds_basis_closedBall.mem_iff.mp hfUxc with ⟨ε, hε₀, hε⟩
  use fun z ↦ ε / (f x + f z)
  refine ⟨?mapsTo, ?injOn, ?deriv⟩
  case mapsTo =>
    intro z hz
    rw [mem_ball_zero_iff, norm_div, norm_real, Real.norm_of_nonneg hε₀.le, div_lt_one₀]
    · by_contra! hle
      refine @hε (f z) ?_ (mem_image_of_mem f hz)
      simpa [dist_eq_norm, add_comm] using hle
    · simpa using hdisj x hx z hz
  case injOn =>
    intro z hz w hw heq
    simpa [div_eq_mul_inv, hε₀.ne', hf_inv.injective.eq_iff] using heq
  case deriv =>
    intro z hz
    rw [(hasDerivAt_const _ _).fun_div ((hdf z hz).hasDerivAt.const_add _) _ |>.deriv]
    · simp [hε₀.ne', hf₀ z hz, hdisj x hx z hz]
    · exact hdisj x hx z hz

#print axioms exists_mapsTo_unitBall_injOn_deriv_ne_zero_rmt

theorem UnitDisc.hasDerivWithinAt_shift_comp {f : ℂ → UnitDisc} {z f' : ℂ} {s : Set ℂ}
    (w : UnitDisc) (hf : HasDerivWithinAt (fun x ↦ ↑(f x)) f' s z) :
    HasDerivWithinAt (fun x ↦ w.shift (f x) : ℂ → ℂ)
      ((1 - ‖(w : ℂ)‖ ^ 2) / (1 + conj ↑w * f z) ^ 2 * f') s z := by
  simp only [coe_shift]
  convert (hf.const_add _).fun_div ((hf.const_mul _).const_add _) _ using 1
  · rw [← mul_conj']
    ring
  · apply UnitDisc.shift_den_ne_zero

#print axioms UnitDisc.hasDerivWithinAt_shift_comp

theorem UnitDisc.hasDerivAt_shift_comp {f : ℂ → UnitDisc} {z f' : ℂ} (w : UnitDisc)
    (hf : HasDerivAt (fun x ↦ ↑(f x)) f' z) :
    HasDerivAt (fun x ↦ w.shift (f x) : ℂ → ℂ)
      ((1 - ‖(w : ℂ)‖ ^ 2) / (1 + conj ↑w * f z) ^ 2 * f') z :=
  (hasDerivWithinAt_shift_comp w hf.hasDerivWithinAt).hasDerivAt univ_mem

#print axioms UnitDisc.hasDerivAt_shift_comp

@[simp]
theorem UnitDisc.differentiableWithinAt_shift_comp_iff {f : ℂ → UnitDisc} {z : ℂ} {s : Set ℂ}
    (w : UnitDisc) :
    DifferentiableWithinAt ℂ (fun x ↦ w.shift (f x) : ℂ → ℂ) s z ↔
      DifferentiableWithinAt ℂ (f · : ℂ → ℂ) s z := by
  refine ⟨fun h ↦ ?_, fun h ↦
    (hasDerivWithinAt_shift_comp w h.hasDerivWithinAt).differentiableWithinAt⟩
  simpa using (hasDerivWithinAt_shift_comp (-w) h.hasDerivWithinAt).differentiableWithinAt

#print axioms UnitDisc.differentiableWithinAt_shift_comp_iff

@[simp]
theorem UnitDisc.differentiableOn_shift_comp_iff {f : ℂ → UnitDisc} {s : Set ℂ} (w : UnitDisc) :
    DifferentiableOn ℂ (fun x ↦ w.shift (f x) : ℂ → ℂ) s ↔
      DifferentiableOn ℂ (f · : ℂ → ℂ) s := by
  simp [DifferentiableOn]

#print axioms UnitDisc.differentiableOn_shift_comp_iff

@[simp]
theorem UnitDisc.differentiableAt_shift_comp_iff {f : ℂ → UnitDisc} {z : ℂ} (w : UnitDisc) :
    DifferentiableAt ℂ (fun x ↦ w.shift (f x) : ℂ → ℂ) z ↔
      DifferentiableAt ℂ (f · : ℂ → ℂ) z := by
  refine ⟨fun h ↦ ?_, fun h ↦ (hasDerivAt_shift_comp w h.hasDerivAt).differentiableAt⟩
  simpa using (hasDerivAt_shift_comp (-w) h.hasDerivAt).differentiableAt

#print axioms UnitDisc.differentiableAt_shift_comp_iff

@[simp]
theorem UnitDisc.deriv_shift_comp (f : ℂ → UnitDisc) (z : ℂ) (w : UnitDisc) :
    deriv (fun x ↦ w.shift (f x) : ℂ → ℂ) z =
      (1 - ‖(w : ℂ)‖ ^ 2) / (1 + conj ↑w * f z) ^ 2 * deriv (f · : ℂ → ℂ) z := by
  by_cases hfd : DifferentiableAt ℂ (f · : ℂ → ℂ) z
  · exact (hasDerivAt_shift_comp w hfd.hasDerivAt).deriv
  · rw [deriv_zero_of_not_differentiableAt hfd, deriv_zero_of_not_differentiableAt, mul_zero]
    simpa using hfd

#print axioms UnitDisc.deriv_shift_comp

theorem UnitDisc.deriv_shift_comp_eq_zero (f : ℂ → UnitDisc) (z : ℂ) (w : UnitDisc) :
    deriv (fun x ↦ w.shift (f x) : ℂ → ℂ) z = 0 ↔ deriv (f · : ℂ → ℂ) z = 0 := by
  simp only [deriv_shift_comp, mul_eq_zero, div_eq_zero_iff, pow_eq_zero_iff two_ne_zero,
    shift_den_ne_zero, or_false]
  apply or_iff_right
  exact mod_cast sub_ne_zero.mpr w.sq_norm_lt_one.ne'

#print axioms UnitDisc.deriv_shift_comp_eq_zero

theorem exists_map_unitDisc_injOn_deriv_ne_zero₀ {U : Set ℂ} (hUo : IsOpen U)
    (hUc : IsSimplyConnected U) (hU : U ≠ univ) {x : ℂ} (hx : x ∈ U) :
    ∃ f : ℂ → UnitDisc, f x = 0 ∧ InjOn f U ∧ (∀ z ∈ U, deriv (UnitDisc.coe ∘ f) z ≠ 0) := by
  classical
  obtain ⟨f, hf_inj, hf_deriv⟩ :
      ∃ f : ℂ → UnitDisc, InjOn f U ∧ ∀ z ∈ U, deriv (UnitDisc.coe ∘ f) z ≠ 0 := by
    rcases exists_mapsTo_unitBall_injOn_deriv_ne_zero_rmt hUo hUc hU hx with ⟨f, hfU, hf_inj, hdf⟩
    use fun z ↦ if hz : z ∈ U then .mk (f z) (by simpa using hfU hz) else 0
    constructor
    · simp +contextual [InjOn, UnitDisc.mk_inj, hf_inj.eq_iff]
    · intro z hz
      convert hdf z hz using 1
      apply Filter.EventuallyEq.deriv_eq
      filter_upwards [hUo.mem_nhds hz] with w hw
      simp [hw]
  use fun z ↦ (-f x).shift (f z)
  refine ⟨?map_x, (-f x).shift.injective.comp_injOn hf_inj, ?deriv⟩
  case map_x => simp
  case deriv =>
    simpa only [Function.comp_def, ne_eq, UnitDisc.deriv_shift_comp_eq_zero]

#print axioms exists_map_unitDisc_injOn_deriv_ne_zero₀

theorem exist_map_unitDisc_injOn_norm_deriv_gt {U : Set ℂ} (hUo : IsOpen U)
    (hUc : IsSimplyConnected U) (hU : U ≠ univ) {x : ℂ} (hx : x ∈ U) {f : ℂ → UnitDisc}
    (hdf : DifferentiableOn ℂ (UnitDisc.coe ∘ f) U) (hf₀ : f x = 0) (hf_inj : InjOn f U)
    (hsurj : ¬SurjOn f U univ) :
    ∃ g : ℂ → UnitDisc, g x = 0 ∧ InjOn g U ∧ DifferentiableOn ℂ (UnitDisc.coe ∘ g) U ∧
      ‖deriv (UnitDisc.coe ∘ f) x‖ < ‖deriv (UnitDisc.coe ∘ g) x‖ := by
  by_cases hdf₀ : deriv (UnitDisc.coe ∘ f) x = 0
  · rcases exists_map_unitDisc_injOn_deriv_ne_zero₀ hUo hUc hU hx with ⟨g, hg₀, hg_inj, hdg⟩
    refine ⟨g, hg₀, hg_inj, fun z hz ↦ ?_, ?_⟩
    · exact (differentiableAt_of_deriv_ne_zero (hdg z hz)).differentiableWithinAt
    · simpa [hdf₀] using hdg x hx
  obtain ⟨c, hc⟩ : ∃ c, ∀ z ∈ U, f z ≠ c := by simpa [SurjOn, eq_univ_iff_forall] using hsurj
  have hcf : ContinuousOn f U := by
    rw [UnitDisc.isEmbedding_coe.continuousOn_iff]
    exact hdf.continuousOn
  rcases UnitDisc.exists_continuousOn_pow_eq hUc hUo ((-c).continuous_shift.comp_continuousOn hcf)
    (by simpa) 2 with ⟨g, hgc, hgf⟩
  have hg₀ : ∀ z ∈ U, g z ≠ 0 := by
    intro z hz
    suffices g z ^ (2 : ℕ+) ≠ 0 by simpa using this
    simp [hgf, hc z hz]
  have hdg : ∀ z ∈ U, HasDerivAt (g · : ℂ → ℂ)
      ((1 - ‖(c : ℂ)‖ ^ 2) / (2 * g z * (1 - conj ↑c * f z) ^ 2) * deriv (f · : ℂ → ℂ) z) z := by
    intro z hz
    convert (hasDerivAt_pow 2 _).of_comp_left
      (UnitDisc.continuous_coe.continuousAt.comp <| hgc.continuousAt <| hUo.mem_nhds hz)
      (UnitDisc.hasDerivAt_shift_comp _ <| (hdf.hasDerivAt <| hUo.mem_nhds hz)) _
      (.of_forall fun x ↦ congr(UnitDisc.coe $(hgf x))) using 1
    all_goals first
      | rfl
      | (simp [UnitDisc.coe_eq_zero, hg₀ z hz]; done)
      | (simp only [Function.comp_def, UnitDisc.coe_neg, map_neg, norm_neg, neg_mul,
            ← sub_eq_add_neg, show (2 : ℕ) - 1 = 1 from rfl, pow_one, Nat.cast_ofNat]
         generalize (1 - (starRingEnd ℂ) ↑c * ↑(f z)) = A
         ring)
  have hg_sq_norm (z : ℂ) : ‖(g z : ℂ)‖ ^ 2 = ‖((-c).shift (f z) : ℂ)‖ := by
    rw [← norm_pow, ← PNat.val_ofNat, ← UnitDisc.coe_pow, hgf, Function.comp_apply]
  have hg_norm (z : ℂ) : ‖(g z : ℂ)‖ = √‖((-c).shift (f z) : ℂ)‖ := by
    rw [← Real.sqrt_sq (norm_nonneg _), hg_sq_norm]
  refine ⟨(-g x).shift ∘ g, ?map_x, ?injOn, ?deriv, ?norm_deriv⟩
  case map_x => simp
  case injOn =>
    refine (-g x).shift.injective.comp_injOn fun z hz w hw hzw ↦ ?_
    simpa [hgf, hf_inj.eq_iff hz hw] using congr($hzw ^ (2 : ℕ+))
  case deriv =>
    exact (-g x).differentiableOn_shift_comp_iff.mpr fun z hz ↦
      (hdg z hz).differentiableAt.differentiableWithinAt
  case norm_deriv =>
    have hkey : ‖deriv (UnitDisc.coe ∘ ⇑(-g x).shift ∘ g) x‖ =
        ‖deriv (f · : ℂ → ℂ) x‖ * (√‖(c : ℂ)‖ + √‖(c⁻¹ : ℂ)‖) / 2 := by
      have hgx : ‖(g x : ℂ)‖ = √‖(c : ℂ)‖ := by simp [hg_norm, hf₀]
      simp only [Function.comp_def, UnitDisc.deriv_shift_comp, (hdg x hx).deriv, norm_mul, norm_div,
        ← mul_assoc, conj_mul', UnitDisc.coe_neg, map_neg, neg_mul]
      conv_rhs => rw [mul_comm, mul_div_right_comm]
      congr 1
      norm_cast
      have hpos₁ : 0 < 1 - ‖(c : ℂ)‖ := sub_pos.2 c.norm_lt_one
      have hpos₂ : 0 < 1 - ‖(c : ℂ)‖ ^ 2 := sub_pos.2 c.sq_norm_lt_one
      simp [field, hgx, hf₀, ← sub_eq_add_neg, abs_of_pos, hpos₁, hpos₂]
      ring
    rw [hkey, mul_div_assoc]
    apply lt_mul_of_one_lt_right
    · simpa using hdf₀
    · have hc₀ : 0 < ‖(c : ℂ)‖ := by simpa [hf₀] using (hc x hx).symm
      suffices √‖(c : ℂ)‖ * 2 < ‖(c : ℂ)‖ + 1 by simpa [field] using this
      have : √‖(c : ℂ)‖ ≠ 1 := by simp [c.norm_ne_one]
      rw [← sub_ne_zero, ← sq_pos_iff, sub_sq, Real.sq_sqrt] at this
      · linear_combination this
      · apply norm_nonneg

#print axioms exist_map_unitDisc_injOn_norm_deriv_gt

theorem uniformEquicontinuousOn_of_thickening_subset_of_forall_norm_le {ι E F : Type*}
    [NormedAddCommGroup E] [NormedSpace ℂ E] [NormedAddCommGroup F] [NormedSpace ℂ F]
    {f : ι → E → F} {s U : Set E} {r : ℝ} (hr₀ : 0 < r) (hU : thickening r s ⊆ U)
    (hfd : ∀ i, DifferentiableOn ℂ (f i) U) (hf : ∃ C, ∀ i, ∀ z ∈ U, ‖f i z‖ ≤ C) :
    UniformEquicontinuousOn f s := by
  have hsU : s ⊆ U := (self_subset_thickening hr₀ _).trans hU
  rw [(uniformity_basis_dist.inf_principal _).uniformEquicontinuousOn_iff uniformity_basis_dist_le]
  intro ε hε
  rcases hf with ⟨C, hC⟩
  rcases exists_pos_mul_lt hε (2 * C / r) with ⟨δ, hδ₀, hδ⟩
  use min δ r, by positivity
  simp only [mem_setOf, mem_inter_iff, prodMk_mem_set_prod_eq]
  rintro x y ⟨hdist, hx, hy⟩ i
  rw [lt_min_iff] at hdist
  rw [thickening_eq_biUnion_ball, iUnion₂_subset_iff] at hU
  calc
    dist (f i x) (f i y) ≤ (2 * C / r) * dist x y := by
      apply dist_le_div_mul_dist_of_mapsTo_ball
      · exact (hfd i).mono (hU _ hy)
      · intro z hz
        rw [mem_closedBall, two_mul]
        exact dist_le_norm_add_norm _ _ |>.trans <|
          add_le_add (hC _ _ <| hU y hy hz) (hC _ _ <| hsU hy)
      · exact hdist.2
    _ ≤ _ := by
      grw [hdist.1]
      · exact hδ.le
      · have := (norm_nonneg _).trans (hC i x (hsU hx))
        positivity

#print axioms uniformEquicontinuousOn_of_thickening_subset_of_forall_norm_le

theorem equicontinuousAt_of_forall_norm_le {ι E F : Type*}
    [NormedAddCommGroup E] [NormedSpace ℂ E] [NormedAddCommGroup F] [NormedSpace ℂ F]
    {f : ι → E → F} {U : Set E} {x : E} (hU : U ∈ 𝓝 x)
    (hfd : ∀ i, DifferentiableOn ℂ (f i) U) (hf : ∃ C, ∀ i, ∀ z ∈ U, ‖f i z‖ ≤ C) :
    EquicontinuousAt f x := by
  rcases nhds_basis_ball.mem_iff.mp hU with ⟨r, hr₀, hr⟩
  have : thickening (r / 2) (ball x (r / 2)) ⊆ U := by
    grw [Metric.thickening_ball]
    rwa [add_halves]
  have := uniformEquicontinuousOn_of_thickening_subset_of_forall_norm_le (by positivity) this
    hfd hf |>.equicontinuousOn x (by simpa)
  rwa [EquicontinuousWithinAt, nhdsWithin_eq_nhds.mpr (ball_mem_nhds _ (by positivity))] at this

#print axioms equicontinuousAt_of_forall_norm_le

open scoped UniformConvergence in
theorem exists_bijOn_unitBall_map_eq_zero {U : Set ℂ} (hUo : IsOpen U) (hUc : IsSimplyConnected U)
    (hU : U ≠ univ) {x₀ : ℂ} (hx₀ : x₀ ∈ U) :
    ∃ f : ℂ → ℂ, DifferentiableOn ℂ f U ∧ BijOn f U (ball 0 1) ∧ f x₀ = 0 := by
  set 𝔖 : Set (Set ℂ) := {K | K ⊆ U ∧ IsCompact K}
  have h𝔖K : ∀ K ∈ 𝔖, IsCompact K := fun _ ↦ And.right
  have hcnt : (𝓤 (ℂ →ᵤ[𝔖] ℂ)).IsCountablyGenerated := by
    have := hUo.locallyCompactSpace
    have : SigmaCompactSpace U := sigmaCompactSpace_of_locallyCompact_secondCountable
    set φ : CompactExhaustion U := default
    apply UniformOnFun.isCountablyGenerated_uniformity (t := fun n ↦ (↑) '' φ n)
    · intro n
      exact ⟨image_val_subset, φ.isCompact n |>.image continuous_subtype_val⟩
    · exact monotone_image.comp φ.subset
    · rintro K ⟨hKU, hKc⟩
      lift K to Set U using hKU
      rw [← Subtype.isCompact_iff] at hKc
      exact (φ.exists_superset_of_isCompact hKc).imp fun n hn ↦ by gcongr
  set F : (ℂ →ᵤ[𝔖] ℂ) → (ℂ → ℂ) := fun f ↦ UniformOnFun.toFun _ f
  have hF : ∀ {f : ℂ →ᵤ[𝔖] ℂ} {s}, TendstoLocallyUniformlyOn F (F f) (𝓝[s] f) U := by
    intro f s
    have : Tendsto id (𝓝[s] f) (𝓝 f) := tendsto_id'.mpr nhdsWithin_le_nhds
    simpa [tendstoLocallyUniformlyOn_iff_forall_isCompact hUo,
      UniformOnFun.tendsto_iff_tendstoUniformlyOn, 𝔖] using this
  set s : Set (ℂ →ᵤ[𝔖] ℂ) :=
    {f : ℂ →ᵤ[𝔖] ℂ |
      MapsTo (F f) U (ball 0 1) ∧
      InjOn (F f) U ∧
      DifferentiableOn ℂ (F f) U ∧
      deriv (F f) x₀ ≠ 0 ∧
      F f x₀ = 0}
  have hsd : ∀ f ∈ s, DifferentiableOn ℂ (F f) U := fun f hf ↦ hf.2.2.1
  have hs_ne : s.Nonempty := by
    rcases exists_map_unitDisc_injOn_deriv_ne_zero₀ hUo hUc hU hx₀ with ⟨f, hf₀, hf_inj, hfd⟩
    exact ⟨UniformOnFun.ofFun 𝔖 (f ·), fun x hx ↦ (f x).2,
      by simpa [F, InjOn] using hf_inj, fun z hz ↦
        differentiableAt_of_deriv_ne_zero (hfd z hz) |>.differentiableWithinAt,
      hfd x₀ hx₀, by simp [F, hf₀]⟩
  have hcmpct := ArzelaAscoli.isCompact_closure_of_isClosedEmbedding h𝔖K (α := ℂ) (s := s) (F := F)
    .id ?eqcont ?bdd
  case eqcont =>
    rintro K ⟨hKU, -⟩ z hz
    refine equicontinuousAt_of_forall_norm_le (hUo.mem_nhds <| hKU hz) (fun i ↦ hsd _ i.2)
      ⟨1, fun i z hz ↦ le_of_lt ?_⟩ |>.equicontinuousWithinAt _
    simpa using i.2.1 hz
  case bdd =>
    intro K hK x hx
    exact ⟨closedBall 0 1, isCompact_closedBall _ _, fun i hi ↦
      ball_subset_closedBall <| hi.1 (hK.1 hx)⟩
  have hcl : closure s ⊆
      {f | MapsTo (F f) U (ball 0 1) ∧
           ((∃ C, EqOn (F f) (const ℂ C) U) ∨ InjOn (F f) U) ∧
           DifferentiableOn ℂ (F f) U ∧
           F f x₀ = 0} := by
    intro f hf
    rw [mem_closure_iff_nhdsWithin_neBot] at hf
    have htendsto : TendstoLocallyUniformlyOn F (F f) (𝓝[s] f) U := hF
    have hdf : DifferentiableOn ℂ (F f) U := htendsto.differentiableOn
      (eventually_mem_nhdsWithin.mono hsd) hUo
    have hf_le : ∀ z ∈ U, ‖F f z‖ ≤ 1 := by
      intro z hz
      refine le_of_tendsto (htendsto.tendsto_at hz).norm <| eventually_mem_nhdsWithin.mono ?_
      intro g hg
      apply le_of_lt
      simpa using hg.1 hz
    have hfx₀ : F f x₀ = 0 := by
      refine tendsto_nhds_unique (htendsto.tendsto_at hx₀) ?_
      refine tendsto_const_nhds.congr' <| eventually_mem_nhdsWithin.mono fun g hg ↦ ?_
      exact hg.2.2.2.2.symm
    refine ⟨?_, ?_, hdf, hfx₀⟩
    · by_contra hf_ball
      obtain ⟨z, hzU, hz⟩ : ∃ z ∈ U, 1 ≤ ‖F f z‖ := by simpa [MapsTo] using hf_ball
      have : IsMaxOn (‖F f ·‖) U z := by
        intro y hy
        simpa using (hf_le y hy).trans hz
      have : F f x₀ = F f z := Complex.eqOn_of_isPreconnected_of_isMaxOn_norm
        hUc.isPathConnected.isConnected.isPreconnected hUo hdf hzU this hx₀
      norm_num [← this, hfx₀] at hz
    · exact eqOn_const_or_injOn_of_tendstoLocallyUniformlyOn hUo
        hUc.isPathConnected.isConnected.isPreconnected
        (eventually_mem_nhdsWithin.mono fun g (hg : g ∈ s) ↦ hg.2.1)
        (eventually_mem_nhdsWithin.mono hsd)
        htendsto
  have hcont : ContinuousOn (fun f ↦ ‖deriv (F f) x₀‖) (closure s) := by
    refine .mono (.norm fun f hf ↦ ?_) hcl
    refine TendstoLocallyUniformlyOn.tendsto_at (.deriv hF ?_ hUo) hx₀
    refine eventually_mem_nhdsWithin.mono fun g hg ↦ ?_
    exact hg.2.2.1
  rcases hcmpct.exists_isMaxOn hs_ne.closure hcont with ⟨f₀, hf₀_mem, hf₀_max⟩
  have hdf₀_x₀ : 0 < ‖deriv (F f₀) x₀‖ := by
    rcases hs_ne with ⟨f', hf'⟩
    refine lt_of_lt_of_le ?_ (hf₀_max <| subset_closure hf')
    simpa using hf'.2.2.2.1
  rcases hcl hf₀_mem with ⟨hf₀_mapsTo, hf₀_inj, hf₀_diff, hf₀_x₀⟩
  replace hf₀_inj : InjOn (F f₀) U := by
    refine hf₀_inj.resolve_left ?_
    rintro ⟨C, hC⟩
    rw [hC.eventuallyEq_of_mem (hUo.mem_nhds hx₀) |>.deriv_eq] at hdf₀_x₀
    unfold const at hdf₀_x₀
    simp at hdf₀_x₀
  refine ⟨F f₀, hf₀_diff, ⟨hf₀_mapsTo, hf₀_inj, ?_⟩, hf₀_x₀⟩
  by_contra! hsurj
  clear hf₀_mem hdf₀_x₀
  rw [isMaxOn_iff] at hf₀_max
  wlog hf₀_lt : ∀ z, ‖F f₀ z‖ < 1 generalizing f₀
  · classical
    apply this (UniformOnFun.ofFun _ <| U.indicator (F f₀))
    · have : deriv (U.indicator (F f₀)) x₀ = deriv (F f₀) x₀ :=
        U.eqOn_indicator.eventuallyEq_of_mem (hUo.mem_nhds hx₀) |>.deriv_eq
      simpa [this, F] using hf₀_max
    · simpa [F, U.eqOn_indicator.mapsTo_iff]
    · simpa [F, differentiableOn_congr U.eqOn_indicator]
    · simp [F, hf₀_x₀]
    · simpa [F, U.eqOn_indicator.injOn_iff]
    · simpa [F, U.eqOn_indicator.surjOn_iff]
    · intro z
      by_cases hz : z ∈ U <;> simp [F, hz, mem_ball_zero_iff.mp (hf₀_mapsTo _)]
  lift F f₀ to ℂ → UnitDisc using hf₀_lt with f hf
  replace hsurj : ¬SurjOn f U univ := by
    simpa [SurjOn, eq_univ_iff_forall, subset_def, UnitDisc.exists, ← UnitDisc.coe_inj] using hsurj
  rcases exist_map_unitDisc_injOn_norm_deriv_gt hUo hUc hU hx₀ hf₀_diff (by simpa using hf₀_x₀)
    (by simpa [InjOn] using hf₀_inj) hsurj with ⟨g, hg₀, hg_inj, hdg, hg_lt⟩
  refine hf₀_max (UniformOnFun.ofFun _ (g · : ℂ → ℂ)) (subset_closure ?_) |>.not_gt hg_lt
  refine ⟨fun z _ ↦ (g z).2, by simpa [F, InjOn] using hg_inj, hdg, ?_, by simpa [F] using hg₀⟩
  rw [← norm_pos_iff]
  exact (norm_nonneg _).trans_lt hg_lt

#print axioms exists_bijOn_unitBall_map_eq_zero

end Complex

namespace RMT

open Complex

theorem deriv_ne_zero_of_injOn {U : Set ℂ} (hUo : IsOpen U) {f : ℂ → ℂ}
    (hfd : DifferentiableOn ℂ f U) (hinj : InjOn f U) {a : ℂ} (ha : a ∈ U) :
    deriv f a ≠ 0 := by
  intro hda
  have hfa : AnalyticAt ℂ f a := hfd.analyticAt (hUo.mem_nhds ha)
  set F : ℂ → ℂ := fun z ↦ f z - f a with hF
  have hFa : AnalyticAt ℂ F a := hfa.sub analyticAt_const
  have htop : analyticOrderAt F a ≠ ⊤ := by
    intro h
    rw [analyticOrderAt_eq_top] at h
    obtain ⟨ε, hε, hεb⟩ := Metric.eventually_nhds_iff_ball.mp (h.and (hUo.mem_nhds ha))
    have hz : a + (ε / 2 : ℝ) ∈ ball a ε := by
      rw [mem_ball, dist_eq_norm, add_sub_cancel_left, norm_real, Real.norm_of_nonneg (by positivity)]
      linarith
    obtain ⟨h1, h2⟩ := hεb _ hz
    have h3 : f (a + (ε / 2 : ℝ)) = f a := sub_eq_zero.mp h1
    have h4 := hinj h2 ha h3
    have h5 : ((ε / 2 : ℝ) : ℂ) = 0 := by linear_combination h4
    have h6 : ε / 2 = 0 := by exact_mod_cast h5
    linarith
  obtain ⟨g, hga, hg0, hfg⟩ := hFa.analyticOrderAt_ne_top.mp htop
  set n := analyticOrderNatAt F a with hn
  have hn0 : n ≠ 0 := by
    intro h0
    have := hfg.self_of_nhds
    rw [h0] at this
    simp [F] at this
    exact hg0 this.symm
  have hn1 : n ≠ 1 := by
    intro h1
    rw [h1] at hfg
    have hd1 : HasDerivAt (fun z ↦ (z - a) ^ 1 • g z) (g a) a := by
      have := ((hasDerivAt_id a).sub_const a).fun_mul hga.differentiableAt.hasDerivAt
      convert this using 1
      · ext z; simp
      · simp
    have hd2 : deriv F a = g a := (hd1.congr_of_eventuallyEq hfg).deriv
    have hd3 : deriv F a = deriv f a := by simp [F]
    exact hg0 (hd2.symm.trans (hd3.trans hda))
  have hn2 : 2 ≤ n := by omega
  have hgc : ContinuousAt g a := hga.continuousAt
  obtain ⟨ε, hε, hεb⟩ := Metric.eventually_nhds_iff_ball.mp (hfg.and (hUo.mem_nhds ha))
  set t : ℕ → ℝ := fun k ↦ ε / ((k : ℝ) + 2) with ht
  have ht0 : ∀ k, 0 < t k := fun k ↦ by positivity
  have htε : ∀ k, t k < ε := fun k ↦ by
    simp only [t]
    rw [div_lt_iff₀ (by positivity)]
    have : (0 : ℝ) ≤ k := Nat.cast_nonneg k
    nlinarith
  set G : ℕ → ℂ → ℂ := fun k z ↦ F (a + (t k : ℂ) * z) / (t k : ℂ) ^ n with hG
  have hmem : ∀ k, ∀ z ∈ ball (0 : ℂ) 1, a + (t k : ℂ) * z ∈ ball a ε := by
    intro k z hz
    rw [mem_ball, dist_eq_norm, add_sub_cancel_left, norm_mul, norm_real,
      Real.norm_of_nonneg (ht0 k).le]
    have : ‖z‖ < 1 := mem_ball_zero_iff.mp hz
    calc t k * ‖z‖ ≤ t k * 1 := by gcongr
      _ < ε := by linarith [htε k]
  have hGeq : ∀ k, ∀ z ∈ ball (0 : ℂ) 1, G k z = z ^ n * g (a + (t k : ℂ) * z) := by
    intro k z hz
    have h := (hεb _ (hmem k z hz)).1
    have htne : ((t k : ℝ) : ℂ) ≠ 0 := by exact_mod_cast (ht0 k).ne'
    simp only [G, h, add_sub_cancel_left, smul_eq_mul, mul_pow]
    field_simp
  have hInj : ∀ᶠ k in atTop, InjOn (G k) (ball (0 : ℂ) 1) := by
    refine Eventually.of_forall fun k z hz w hw hzw ↦ ?_
    have htne : ((t k : ℝ) : ℂ) ≠ 0 := by exact_mod_cast (ht0 k).ne'
    have h1 : F (a + (t k : ℂ) * z) = F (a + (t k : ℂ) * w) := by
      have := hzw
      simp only [G] at this
      exact (div_left_inj' (pow_ne_zero _ htne)).mp this
    have h2 : f (a + (t k : ℂ) * z) = f (a + (t k : ℂ) * w) := by
      simpa [F] using h1
    have h3 := hinj (hεb _ (hmem k z hz)).2 (hεb _ (hmem k w hw)).2 h2
    have h4 : (t k : ℂ) * z = (t k : ℂ) * w := by linear_combination h3
    exact mul_left_cancel₀ htne h4
  have hDiff : ∀ᶠ k in atTop, DifferentiableOn ℂ (G k) (ball (0 : ℂ) 1) := by
    refine Eventually.of_forall fun k z hz ↦ ?_
    have hfz : DifferentiableAt ℂ f (a + (t k : ℂ) * z) :=
      hfd.differentiableAt (hUo.mem_nhds (hεb _ (hmem k z hz)).2)
    have : DifferentiableAt ℂ (fun z ↦ f (a + (t k : ℂ) * z)) z :=
      hfz.comp z (by fun_prop)
    exact ((this.sub_const (f a)).div_const _).differentiableWithinAt
  have hT : TendstoUniformlyOn G (fun z ↦ z ^ n * g a) atTop (ball (0 : ℂ) 1) := by
    rw [Metric.tendstoUniformlyOn_iff]
    intro η hη
    obtain ⟨δ, hδ, hδg⟩ := Metric.continuousAt_iff.mp hgc η hη
    obtain ⟨N, hN⟩ := exists_nat_gt (ε / δ)
    filter_upwards [eventually_ge_atTop N] with k hk z hz
    have hz1 : ‖z‖ < 1 := mem_ball_zero_iff.mp hz
    have htk : t k < δ := by
      simp only [t]
      rw [div_lt_iff₀ (by positivity)]
      rw [div_lt_iff₀ hδ] at hN
      have : (N : ℝ) ≤ k := by exact_mod_cast hk
      nlinarith
    have hgd : ‖g (a + (t k : ℂ) * z) - g a‖ < η := by
      rw [← dist_eq_norm]
      apply hδg
      rw [dist_eq_norm, add_sub_cancel_left, norm_mul, norm_real,
        Real.norm_of_nonneg (ht0 k).le]
      calc t k * ‖z‖ ≤ t k * 1 := by gcongr
        _ < δ := by linarith
    rw [hGeq k z hz, dist_eq_norm, ← mul_sub, norm_mul, norm_pow, norm_sub_rev]
    calc ‖z‖ ^ n * ‖g (a + (t k : ℂ) * z) - g a‖ ≤ 1 * ‖g (a + (t k : ℂ) * z) - g a‖ := by
          gcongr
          exact pow_le_one₀ (norm_nonneg _) hz1.le
      _ < η := by linarith
  have H := Complex.eqOn_const_or_injOn_of_tendstoLocallyUniformlyOn (l := atTop) isOpen_ball
    (convex_ball (0 : ℂ) 1).isPreconnected hInj hDiff hT.tendstoLocallyUniformlyOn
  have hhalf : (1 / 2 : ℂ) ∈ ball (0 : ℂ) 1 := by
    rw [mem_ball_zero_iff]; norm_num
  rcases H with ⟨C, hC⟩ | hinj'
  · have h0 := hC 0 (by simp)
    have h1 := hC (1 / 2) hhalf
    rw [zero_pow hn0, zero_mul] at h0
    rw [← h0] at h1
    exact mul_ne_zero (pow_ne_zero _ (by norm_num)) hg0 h1
  · set ω : ℂ := exp (2 * π * I / n)
    have hω : IsPrimitiveRoot ω n := Complex.isPrimitiveRoot_exp n hn0
    have hω1 : ω ≠ 1 := hω.ne_one (by omega)
    have hωn : ω ^ n = 1 := hω.pow_eq_one
    have hωnorm : ‖ω‖ = 1 := hω.norm'_eq_one hn0
    have hmem2 : ω * (1 / 2) ∈ ball (0 : ℂ) 1 := by
      rw [mem_ball_zero_iff, norm_mul, hωnorm]; norm_num
    have := hinj' hhalf hmem2 (by simp only [mul_pow, hωn, one_mul])
    apply hω1
    linear_combination -(2 : ℂ) * this

#print axioms deriv_ne_zero_of_injOn

end RMT

namespace RMT

open Complex

theorem hasDerivAt_invFunOn {U : Set ℂ} (hUo : IsOpen U) {f : ℂ → ℂ}
    (hfd : DifferentiableOn ℂ f U) (hinj : InjOn f U) {z : ℂ} (hz : z ∈ U) :
    HasDerivAt (invFunOn f U) (deriv f z)⁻¹ (f z) := by
  have hfa : AnalyticAt ℂ f z := hfd.analyticAt (hUo.mem_nhds hz)
  have hs := hfa.hasStrictDerivAt
  have hne := deriv_ne_zero_of_injOn hUo hfd hinj hz
  have hg := hs.to_localInverse hne
  have hgz : hs.localInverse f (deriv f z) z hne (f z) = z :=
    (hs.eventually_left_inverse hne).self_of_nhds
  have hgc : ContinuousAt (hs.localInverse f (deriv f z) z hne) (f z) :=
    hg.hasDerivAt.continuousAt
  have hev : invFunOn f U =ᶠ[𝓝 (f z)] hs.localInverse f (deriv f z) z hne := by
    have h1 : ∀ᶠ y in 𝓝 (f z), hs.localInverse f (deriv f z) z hne y ∈ U :=
      hgc.preimage_mem_nhds (by rw [hgz]; exact hUo.mem_nhds hz)
    filter_upwards [h1, hs.eventually_right_inverse hne] with y hy1 hy2
    have hex : ∃ x ∈ U, f x = y := ⟨_, hy1, hy2⟩
    exact hinj (invFunOn_mem hex) hy1 ((invFunOn_eq hex).trans hy2.symm)
  exact hg.hasDerivAt.congr_of_eventuallyEq hev

#print axioms hasDerivAt_invFunOn

theorem disc_aut_fix_zero {φ : ℂ → ℂ} (hd : DifferentiableOn ℂ φ (ball 0 1))
    (hinj : InjOn φ (ball 0 1)) (him : φ '' ball 0 1 = ball 0 1) (h0 : φ 0 = 0) :
    ∃ c : ℂ, ‖c‖ = 1 ∧ ∀ u ∈ ball (0 : ℂ) 1, φ u = c * u := by
  have hex : ∀ v ∈ ball (0 : ℂ) 1, ∃ u ∈ ball (0 : ℂ) 1, φ u = v := fun v hv ↦ by
    rw [← him] at hv; exact hv
  have hψmem : ∀ v ∈ ball (0 : ℂ) 1, invFunOn φ (ball (0 : ℂ) 1) v ∈ ball (0 : ℂ) 1 :=
    fun v hv ↦ invFunOn_mem (hex v hv)
  have hψeq : ∀ v ∈ ball (0 : ℂ) 1, φ (invFunOn φ (ball (0 : ℂ) 1) v) = v :=
    fun v hv ↦ invFunOn_eq (hex v hv)
  have hψd : DifferentiableOn ℂ (invFunOn φ (ball (0 : ℂ) 1)) (ball 0 1) := by
    intro v hv
    obtain ⟨u, hu, rfl⟩ := hex v hv
    exact (hasDerivAt_invFunOn isOpen_ball hd hinj hu).differentiableAt.differentiableWithinAt
  have h0mem : (0 : ℂ) ∈ ball (0 : ℂ) 1 := by simp
  have hψ0 : invFunOn φ (ball (0 : ℂ) 1) 0 = 0 :=
    hinj (hψmem 0 h0mem) h0mem (by rw [hψeq 0 h0mem, h0])
  have hψφ : ∀ u ∈ ball (0 : ℂ) 1, invFunOn φ (ball (0 : ℂ) 1) (φ u) = u :=
    fun u hu ↦ hinj.leftInvOn_invFunOn hu
  have hmapsφ : MapsTo φ (ball 0 1) (ball 0 1) := fun u hu ↦ him ▸ mem_image_of_mem φ hu
  have hle : ∀ u ∈ ball (0 : ℂ) 1, ‖φ u‖ ≤ ‖u‖ := fun u hu ↦
    norm_le_norm_of_mapsTo_ball hd (hmapsφ.mono_right ball_subset_closedBall) h0
      (mem_ball_zero_iff.mp hu)
  have hge : ∀ u ∈ ball (0 : ℂ) 1, ‖u‖ ≤ ‖φ u‖ := fun u hu ↦ by
    have := norm_le_norm_of_mapsTo_ball hψd (fun v hv ↦ ball_subset_closedBall (hψmem v hv))
      hψ0 (mem_ball_zero_iff.mp (hmapsφ hu))
    rwa [hψφ u hu] at this
  have hhalf : (1 / 2 : ℂ) ∈ ball (0 : ℂ) 1 := by
    rw [mem_ball_zero_iff]; norm_num
  have hn : ‖φ (1 / 2)‖ = 1 / 2 := by
    have := le_antisymm (hle _ hhalf) (hge _ hhalf)
    rw [this]; norm_num
  obtain ⟨C, hC, hEq⟩ := affine_of_mapsTo_ball_of_exists_norm_dslope_eq_div' (c := 0) (R₁ := 1)
    (R₂ := 1) hd (by rw [h0]; exact hmapsφ.mono_right ball_subset_closedBall)
    ⟨1 / 2, hhalf, by
      rw [dslope_of_ne _ (by norm_num), slope_def_field, h0, sub_zero, sub_zero, norm_div, hn]
      norm_num⟩
  refine ⟨C, by simpa using hC, fun u hu ↦ ?_⟩
  rw [hEq hu]
  simp [h0, smul_eq_mul, mul_comm]

#print axioms disc_aut_fix_zero

/-- A Möbius map of the disc. -/
def mob (a u : ℂ) : ℂ := (a + u) / (1 + conj a * u)

theorem mob_eq_shift {a u : ℂ} (ha : ‖a‖ < 1) (hu : ‖u‖ < 1) :
    mob a u = (UnitDisc.shift (UnitDisc.mk a ha) (UnitDisc.mk u hu) : ℂ) := by
  rw [UnitDisc.coe_shift]
  simp [mob, UnitDisc.coe_mk]

#print axioms mob_eq_shift

theorem mob_den_ne {a u : ℂ} (ha : ‖a‖ < 1) (hu : ‖u‖ < 1) : 1 + conj a * u ≠ 0 := by
  have := UnitDisc.shift_den_ne_zero (UnitDisc.mk a ha) (UnitDisc.mk u hu)
  simpa [UnitDisc.coe_mk] using this

#print axioms mob_den_ne

theorem norm_mob_lt {a u : ℂ} (ha : ‖a‖ < 1) (hu : ‖u‖ < 1) : ‖mob a u‖ < 1 := by
  rw [mob_eq_shift ha hu]
  exact UnitDisc.norm_lt_one _

#print axioms norm_mob_lt

theorem mob_neg_mob {a u : ℂ} (ha : ‖a‖ < 1) (hu : ‖u‖ < 1) : mob (-a) (mob a u) = u := by
  have := congrArg UnitDisc.coe (UnitDisc.shift_neg_apply_shift (UnitDisc.mk a ha)
    (UnitDisc.mk u hu))
  simp only [UnitDisc.coe_shift, UnitDisc.coe_neg, UnitDisc.coe_mk] at this
  simpa [mob] using this

#print axioms mob_neg_mob

theorem mob_mob_neg {a u : ℂ} (ha : ‖a‖ < 1) (hu : ‖u‖ < 1) : mob a (mob (-a) u) = u := by
  simpa using mob_neg_mob (a := -a) (by simpa using ha) hu

#print axioms mob_mob_neg

theorem mapsTo_mob {a : ℂ} (ha : ‖a‖ < 1) : MapsTo (mob a) (ball 0 1) (ball 0 1) :=
  fun u hu ↦ mem_ball_zero_iff.mpr (norm_mob_lt ha (mem_ball_zero_iff.mp hu))

#print axioms mapsTo_mob

theorem differentiableOn_mob {a : ℂ} (ha : ‖a‖ < 1) : DifferentiableOn ℂ (mob a) (ball 0 1) := by
  intro u hu
  have hu' : ‖u‖ < 1 := mem_ball_zero_iff.mp hu
  have : DifferentiableAt ℂ (fun u ↦ (a + u) / (1 + conj a * u)) u :=
    (by fun_prop : DifferentiableAt ℂ (fun u ↦ a + u) u).div (by fun_prop) (mob_den_ne ha hu')
  exact this.differentiableWithinAt

#print axioms differentiableOn_mob

theorem mob_neg_eq (a u : ℂ) : mob (-a) u = (u - a) / (1 - conj a * u) := by
  unfold mob
  rw [map_neg]
  congr 1 <;> ring

#print axioms mob_neg_eq

end RMT

end


/-- **The Riemann mapping theorem.** Let D be a region without holes (an open, simply connected
set in the plane) that is not the whole plane, and let z₀ be a point of D. Then there is a map F
that is holomorphic on D, one-to-one on D, and carries D onto the unit disc, with F(z₀) = 0 and
F'(z₀) real and positive. It is the only one: any other map G with all these properties agrees
with F at every point of D. -/
theorem riemann_mapping_exists_unique {D : Set ℂ} {z₀ : ℂ}
    (hDo : IsOpen D) (hDs : IsSimplyConnected D) (hD : D ≠ univ) (hz₀ : z₀ ∈ D) :
    ∃ F : ℂ → ℂ,
      (DifferentiableOn ℂ F D ∧ InjOn F D ∧ F '' D = ball 0 1 ∧ F z₀ = 0 ∧
        (deriv F z₀).im = 0 ∧ 0 < (deriv F z₀).re) ∧
      ∀ G : ℂ → ℂ,
        DifferentiableOn ℂ G D → InjOn G D → G '' D = ball 0 1 → G z₀ = 0 →
          (deriv G z₀).im = 0 → 0 < (deriv G z₀).re → EqOn G F D := by
  obtain ⟨f, hfd, hbij, hf0⟩ := Complex.exists_bijOn_unitBall_map_eq_zero hDo hDs hD hz₀
  have hfinj : InjOn f D := hbij.injOn
  have hd0 : deriv f z₀ ≠ 0 := RMT.deriv_ne_zero_of_injOn hDo hfd hfinj hz₀
  have hdn : (0 : ℝ) < ‖deriv f z₀‖ := norm_pos_iff.mpr hd0
  have hdnc : ((‖deriv f z₀‖ : ℝ) : ℂ) ≠ 0 := Complex.ofReal_ne_zero.mpr hdn.ne'
  obtain ⟨c, hc⟩ : ∃ c : ℂ, c = (starRingEnd ℂ) (deriv f z₀) / ((‖deriv f z₀‖ : ℝ) : ℂ) := ⟨_, rfl⟩
  have hcn : ‖c‖ = 1 := by
    rw [hc, norm_div, Complex.norm_conj, Complex.norm_real, Real.norm_of_nonneg (norm_nonneg _),
      div_self hdn.ne']
  have hc0 : c ≠ 0 := by
    intro h
    rw [h, norm_zero] at hcn
    exact zero_ne_one hcn
  obtain ⟨F, hF⟩ : ∃ F : ℂ → ℂ, F = fun z ↦ c * f z := ⟨_, rfl⟩
  have hFd : DifferentiableOn ℂ F D := hF ▸ hfd.const_mul c
  have hFinj : InjOn F D := fun x hx y hy h ↦ by
    rw [hF] at h
    exact hfinj hx hy (mul_left_cancel₀ hc0 h)
  have hFim : F '' D = ball 0 1 := by
    ext v
    constructor
    · rintro ⟨z, hz, rfl⟩
      have := hbij.mapsTo hz
      rw [mem_ball_zero_iff] at this ⊢
      rw [hF, norm_mul, hcn, one_mul]
      exact this
    · intro hv
      have hv' : c⁻¹ * v ∈ ball (0 : ℂ) 1 := by
        rw [mem_ball_zero_iff] at hv ⊢
        rw [norm_mul, norm_inv, hcn, inv_one, one_mul]
        exact hv
      obtain ⟨z, hz, hfz⟩ := hbij.surjOn hv'
      refine ⟨z, hz, ?_⟩
      rw [hF]
      simp only [hfz]
      field_simp
  have hF0 : F z₀ = 0 := by simp [hF, hf0]
  have hFderiv : deriv F z₀ = ((‖deriv f z₀‖ : ℝ) : ℂ) := by
    have hdiff : DifferentiableAt ℂ f z₀ := hfd.differentiableAt (hDo.mem_nhds hz₀)
    rw [hF, deriv_const_mul _ hdiff, hc, div_mul_eq_mul_div, Complex.conj_mul']
    field_simp
  refine ⟨F, ⟨hFd, hFinj, hFim, hF0, by rw [hFderiv]; simp, by rw [hFderiv]; simpa using hdn⟩, ?_⟩
  intro G hGd hGinj hGim hG0 hGim0 hGre
  have hex : ∀ v ∈ ball (0 : ℂ) 1, ∃ z ∈ D, F z = v := fun v hv ↦ by
    rw [← hFim] at hv
    exact hv
  have hFinv_mem : ∀ v ∈ ball (0 : ℂ) 1, invFunOn F D v ∈ D := fun v hv ↦ invFunOn_mem (hex v hv)
  have hFinvF : ∀ z ∈ D, invFunOn F D (F z) = z := fun z hz ↦ hFinj.leftInvOn_invFunOn hz
  have hFFinv : ∀ v ∈ ball (0 : ℂ) 1, F (invFunOn F D v) = v := fun v hv ↦ invFunOn_eq (hex v hv)
  have hFinvd : DifferentiableOn ℂ (invFunOn F D) (ball 0 1) := by
    intro v hv
    obtain ⟨u, hu, rfl⟩ := hex v hv
    exact (RMT.hasDerivAt_invFunOn hDo hFd hFinj hu).differentiableAt.differentiableWithinAt
  have hFz : ∀ z ∈ D, F z ∈ ball (0 : ℂ) 1 := fun z hz ↦ hFim ▸ mem_image_of_mem F hz
  have hφd : DifferentiableOn ℂ (fun v ↦ G (invFunOn F D v)) (ball 0 1) :=
    hGd.comp hFinvd hFinv_mem
  have hφinj : InjOn (fun v ↦ G (invFunOn F D v)) (ball 0 1) := fun v hv w hw h ↦ by
    have := hGinj (hFinv_mem v hv) (hFinv_mem w hw) h
    rw [← hFFinv v hv, ← hFFinv w hw, this]
  have hφim : (fun v ↦ G (invFunOn F D v)) '' ball 0 1 = ball 0 1 := by
    refine Eq.trans ?_ hGim
    ext y
    constructor
    · rintro ⟨v, hv, rfl⟩
      exact ⟨invFunOn F D v, hFinv_mem v hv, rfl⟩
    · rintro ⟨z, hz, rfl⟩
      exact ⟨F z, hFz z hz, by simp only [hFinvF z hz]⟩
  have hφ0 : (fun v ↦ G (invFunOn F D v)) 0 = 0 := by
    have : invFunOn F D 0 = z₀ := by
      rw [← hF0]
      exact hFinvF z₀ hz₀
    simp only [this, hG0]
  obtain ⟨k, hk, hφk⟩ := RMT.disc_aut_fix_zero hφd hφinj hφim hφ0
  have hGF : ∀ z ∈ D, G z = k * F z := fun z hz ↦ by
    have := hφk (F z) (hFz z hz)
    simp only [hFinvF z hz] at this
    exact this
  have hdG : deriv G z₀ = k * deriv F z₀ := by
    have hev : G =ᶠ[nhds z₀] fun z ↦ k * F z := Filter.eventually_of_mem (hDo.mem_nhds hz₀) hGF
    rw [hev.deriv_eq, deriv_const_mul _ (hFd.differentiableAt (hDo.mem_nhds hz₀))]
  rw [hFderiv] at hdG
  have hGre' : deriv G z₀ = (((deriv G z₀).re : ℝ) : ℂ) := by
    apply Complex.ext <;> simp [hGim0]
  have hk1 : k = 1 := by
    have h1 : k = deriv G z₀ / ((‖deriv f z₀‖ : ℝ) : ℂ) := by
      rw [hdG]
      field_simp
    rw [h1, hGre', ← Complex.ofReal_div] at hk ⊢
    rw [Complex.norm_real, Real.norm_of_nonneg (by positivity)] at hk
    rw [hk]
    simp
  intro z hz
  rw [hGF z hz, hk1, one_mul]

/-- **The disc's self-maps.** A map ψ is a conformal map of the unit disc onto itself (holomorphic
on the disc, one-to-one there, and carrying the disc onto the disc) exactly when there are a point
a inside the disc and an angle θ with ψ(u) = e^{iθ} (u − a)/(1 − ā u) for every u in the disc:
a Blaschke factor times a turn. -/
theorem disc_self_map_iff_blaschke_times_turn (ψ : ℂ → ℂ) :
    (DifferentiableOn ℂ ψ (ball 0 1) ∧ InjOn ψ (ball 0 1) ∧ ψ '' ball 0 1 = ball 0 1) ↔
      ∃ a ∈ ball (0 : ℂ) 1, ∃ θ : ℝ, ∀ u ∈ ball (0 : ℂ) 1,
        ψ u = exp (θ * I) * ((u - a) / (1 - (starRingEnd ℂ) a * u)) := by
  constructor
  · rintro ⟨hd, hinj, him⟩
    have hex : ∀ v ∈ ball (0 : ℂ) 1, ∃ u ∈ ball (0 : ℂ) 1, ψ u = v := fun v hv ↦ by
      rw [← him] at hv
      exact hv
    obtain ⟨a, ha, hψa⟩ := hex 0 (by simp)
    have ha' : ‖a‖ < 1 := mem_ball_zero_iff.mp ha
    have hna' : ‖-a‖ < 1 := by simpa using ha'
    have hχd : DifferentiableOn ℂ (fun v ↦ ψ (RMT.mob a v)) (ball 0 1) :=
      hd.comp (RMT.differentiableOn_mob ha') (RMT.mapsTo_mob ha')
    have hχinj : InjOn (fun v ↦ ψ (RMT.mob a v)) (ball 0 1) := fun v hv w hw h ↦ by
      have := hinj (RMT.mapsTo_mob ha' hv) (RMT.mapsTo_mob ha' hw) h
      rw [← RMT.mob_neg_mob ha' (mem_ball_zero_iff.mp hv),
        ← RMT.mob_neg_mob ha' (mem_ball_zero_iff.mp hw), this]
    have hχim : (fun v ↦ ψ (RMT.mob a v)) '' ball 0 1 = ball 0 1 := by
      ext v
      constructor
      · rintro ⟨w, hw, rfl⟩
        exact him ▸ mem_image_of_mem ψ (RMT.mapsTo_mob ha' hw)
      · intro hv
        obtain ⟨u, hu, rfl⟩ := hex v hv
        exact ⟨RMT.mob (-a) u, RMT.mapsTo_mob hna' hu, by
          simp only [RMT.mob_mob_neg ha' (mem_ball_zero_iff.mp hu)]⟩
    have hχ0 : (fun v ↦ ψ (RMT.mob a v)) 0 = 0 := by
      simp only [RMT.mob, mul_zero, add_zero, div_one, hψa]
    obtain ⟨c, hc, hχc⟩ := RMT.disc_aut_fix_zero hχd hχinj hχim hχ0
    refine ⟨a, ha, Complex.arg c, fun u hu ↦ ?_⟩
    have hu' : ‖u‖ < 1 := mem_ball_zero_iff.mp hu
    have h1 : ψ u = ψ (RMT.mob a (RMT.mob (-a) u)) := by rw [RMT.mob_mob_neg ha' hu']
    have h2 := hχc (RMT.mob (-a) u) (RMT.mapsTo_mob hna' hu)
    have h3 : exp (Complex.arg c * I) = c := by
      have := Complex.norm_mul_exp_arg_mul_I c
      rwa [hc, Complex.ofReal_one, one_mul] at this
    rw [h1, h2, h3, RMT.mob_neg_eq]
  · rintro ⟨a, ha, θ, hψ⟩
    have ha' : ‖a‖ < 1 := mem_ball_zero_iff.mp ha
    have hna' : ‖-a‖ < 1 := by simpa using ha'
    have hform : ∀ u ∈ ball (0 : ℂ) 1, ψ u = exp (θ * I) * RMT.mob (-a) u := by
      intro u hu
      rw [hψ u hu, RMT.mob_neg_eq]
    have he : ‖exp (θ * I)‖ = 1 := Complex.norm_exp_ofReal_mul_I θ
    have he0 : exp (θ * I) ≠ 0 := Complex.exp_ne_zero _
    refine ⟨?_, ?_, ?_⟩
    · exact ((RMT.differentiableOn_mob hna').const_mul (exp (θ * I))).congr hform
    · intro u hu w hw h
      rw [hform u hu, hform w hw] at h
      have h' := mul_left_cancel₀ he0 h
      rw [← RMT.mob_mob_neg ha' (mem_ball_zero_iff.mp hu),
        ← RMT.mob_mob_neg ha' (mem_ball_zero_iff.mp hw), h']
    · ext v
      constructor
      · rintro ⟨u, hu, rfl⟩
        rw [hform u hu, mem_ball_zero_iff, norm_mul, he, one_mul]
        exact RMT.norm_mob_lt hna' (mem_ball_zero_iff.mp hu)
      · intro hv
        have hv' : (exp (θ * I))⁻¹ * v ∈ ball (0 : ℂ) 1 := by
          rw [mem_ball_zero_iff] at hv ⊢
          rw [norm_mul, norm_inv, he, inv_one, one_mul]
          exact hv
        refine ⟨RMT.mob a ((exp (θ * I))⁻¹ * v), RMT.mapsTo_mob ha' hv', ?_⟩
        rw [hform _ (RMT.mapsTo_mob ha' hv'), RMT.mob_neg_mob ha' (mem_ball_zero_iff.mp hv')]
        field_simp

/-- **sin z on the half strip.** The function sin z sends the half strip of width π (the points
x + iy with −π/2 < x < π/2 and y > 0) one-to-one onto the upper half plane (the points with
positive imaginary part). -/
theorem sin_bijOn_half_strip_upper_half_plane :
    BijOn Complex.sin {z : ℂ | |z.re| < Real.pi / 2 ∧ 0 < z.im} {w : ℂ | 0 < w.im} := by
  have him : ∀ z : ℂ, (Complex.sin z).im = Real.cos z.re * Real.sinh z.im := by
    intro z
    have h := Complex.sin_add_mul_I (z.re : ℂ) (z.im : ℂ)
    rw [Complex.re_add_im] at h
    rw [h]
    simp [Complex.cos_ofReal_re, Complex.sinh_ofReal_re, Complex.sin_ofReal_im,
      Complex.cosh_ofReal_im]
  have hcos : ∀ z : ℂ, |z.re| < Real.pi / 2 → 0 < Real.cos z.re := fun z hz ↦
    Real.cos_pos_of_mem_Ioo ⟨by linarith [(abs_lt.mp hz).1], (abs_lt.mp hz).2⟩
  refine ⟨?_, ?_, ?_⟩
  · rintro z ⟨hzr, hzi⟩
    show 0 < (Complex.sin z).im
    rw [him]
    exact mul_pos (hcos z hzr) (Real.sinh_pos_iff.mpr hzi)
  · rintro z₁ ⟨h1r, h1i⟩ z₂ ⟨h2r, h2i⟩ h
    have h0 : Complex.sin z₁ - Complex.sin z₂ = 0 := sub_eq_zero.mpr h
    rw [Complex.sin_sub_sin] at h0
    have hc : Complex.cos ((z₁ + z₂) / 2) ≠ 0 := by
      intro hc
      obtain ⟨k, hk⟩ := Complex.cos_eq_zero_iff.mp hc
      have := congrArg Complex.im hk
      simp at this
      linarith
    have hs : Complex.sin ((z₁ - z₂) / 2) = 0 := by
      rcases mul_eq_zero.mp h0 with h' | h'
      · rcases mul_eq_zero.mp h' with h'' | h''
        · norm_num at h''
        · exact h''
      · exact absurd h' hc
    obtain ⟨k, hk⟩ := Complex.sin_eq_zero_iff.mp hs
    have hre := congrArg Complex.re hk
    simp at hre
    have hpi := Real.pi_pos
    have hb1 := abs_lt.mp h1r
    have hb2 := abs_lt.mp h2r
    have hk1 : (k : ℝ) < 1 := by
      by_contra hcon
      push_neg at hcon
      nlinarith
    have hk2 : (-1 : ℝ) < k := by
      by_contra hcon
      push_neg at hcon
      nlinarith
    have hk1' : k < 1 := by exact_mod_cast hk1
    have hk2' : -1 < k := by exact_mod_cast hk2
    have hk0 : k = 0 := by omega
    rw [hk0] at hk
    simp at hk
    linear_combination hk
  · intro w hw
    have hw : 0 < w.im := hw
    obtain ⟨s, hs⟩ := IsAlgClosed.exists_eq_mul_self (1 - w ^ 2)
    have hprod : (I * w + s) * (-(I * w - s)) = 1 := by
      linear_combination (-(w ^ 2)) * Complex.I_sq - hs
    have hz1 : I * w + s ≠ 0 := left_ne_zero_of_mul_eq_one hprod
    have hinv1 : (I * w + s)⁻¹ = -(I * w - s) := inv_eq_of_mul_eq_one_right hprod
    have hroot1 : (I * w + s) - (I * w + s)⁻¹ = 2 * I * w := by
      rw [hinv1]; ring
    obtain ⟨ζ, hζ0, hζre, hζ⟩ : ∃ ζ : ℂ, ζ ≠ 0 ∧ 0 < ζ.re ∧ ζ - ζ⁻¹ = 2 * I * w := by
      have hsum : (I * w + s).re + (-(I * w + s)⁻¹).re = -2 * w.im := by
        have := congrArg Complex.re hroot1
        simp only [Complex.sub_re] at this
        rw [Complex.neg_re, ← sub_eq_add_neg, this]
        simp
      have hns : 0 < Complex.normSq (I * w + s) := Complex.normSq_pos.mpr hz1
      have hre2 : (-(I * w + s)⁻¹).re = -(I * w + s).re / Complex.normSq (I * w + s) := by
        rw [Complex.neg_re, Complex.inv_re, neg_div]
      by_cases hpos : 0 < (I * w + s).re
      · exact ⟨I * w + s, hz1, hpos, hroot1⟩
      · refine ⟨-(I * w + s)⁻¹, by simpa using hz1, ?_, ?_⟩
        · rw [hre2]
          push_neg at hpos
          rcases hpos.lt_or_eq with hlt | heq
          · exact div_pos (by linarith) hns
          · rw [hre2, heq] at hsum
            simp at hsum
            linarith
        · rw [inv_neg, inv_inv]
          linear_combination hroot1
    set z : ℂ := -I * Complex.log ζ with hzdef
    have hzI : z * I = Complex.log ζ := by
      rw [hzdef]
      linear_combination (-(Complex.log ζ)) * Complex.I_sq
    have hexp1 : Complex.exp (z * I) = ζ := by rw [hzI, Complex.exp_log hζ0]
    have hexp2 : Complex.exp (-z * I) = ζ⁻¹ := by
      rw [neg_mul, Complex.exp_neg, hexp1]
    have hsin : Complex.sin z = w := by
      rw [Complex.sin, hexp1, hexp2]
      have : ζ⁻¹ - ζ = -(2 * I * w) := by linear_combination -hζ
      rw [this]
      linear_combination (-w) * Complex.I_sq
    have hzre : z.re = Complex.arg ζ := by
      rw [hzdef]
      simp [Complex.log_im]
    have hzr : |z.re| < Real.pi / 2 := by
      rw [hzre]
      exact Complex.abs_arg_lt_pi_div_two_iff.mpr (Or.inl hζre)
    refine ⟨z, ⟨hzr, ?_⟩, hsin⟩
    have h1 := him z
    rw [hsin] at h1
    have h2 : 0 < Real.cos z.re * Real.sinh z.im := h1 ▸ hw
    have h3 : 0 < Real.sinh z.im := pos_of_mul_pos_right h2 (hcos z hzr).le
    exact Real.sinh_pos_iff.mp h3

-- The card's exact worked numbers.
-- The corners: sin(±π/2) = ±1.
example : Real.sin (Real.pi / 2) = 1 := by norm_num
example : Real.sin (-(Real.pi / 2)) = -1 := by norm_num
-- The Cayley map C(w) = (w − i)/(w + i) sends i to 0, so F(z₀) = i C(i) = 0.
example : I * ((I - I) / (I + I)) = 0 := by norm_num
-- The Cayley stretch at i: C'(i) = 2i/(i + i)² = −i/2.
example : 2 * I / (I + I) ^ 2 = -I / 2 := by
  have h : (I + I) ^ 2 = -4 := by ring_nf; norm_num
  rw [h]; ring
-- The second map's centre: a = i C(1 + 2i) = 1/5 + (2/5) i, the card's 0.2 + 0.4i.
example : I * ((1 + 2 * I - I) / (1 + 2 * I + I)) = 1 / 5 + 2 / 5 * I := by
  have h : (1 + 2 * I + I) ≠ 0 := by
    intro h; have := congrArg Complex.im h; norm_num at this
  rw [mul_div_assoc', div_eq_iff h]
  ring_nf; rw [I_sq]; ring
-- The stretch of F at z₀: i × (−i/2) × √2 = √2/2.
example : I * (-I / 2) * (Real.sqrt 2 : ℂ) = (Real.sqrt 2 : ℂ) / 2 := by
  ring_nf; norm_num

#print axioms riemann_mapping_exists_unique
#print axioms disc_self_map_iff_blaschke_times_turn
#print axioms sin_bijOn_half_strip_upper_half_plane
