-- Isolated singularities: for a function with a complex derivative on a punctured disc, the Laurent coefficients on the negative powers decide whether the singularity is removable, a pole of order m or essential, a bounded function has no negative powers and fills in, and near an essential singularity the function comes within any distance of every value.
import Mathlib.Analysis.Complex.RemovableSingularity
import Mathlib.MeasureTheory.Integral.CircleIntegral
import Mathlib.Data.Nat.Factorial.Basic

open Complex Metric Real Filter Topology

/-- The Laurent coefficient on the power n round the point a, read off the circle of radius r:
c_n = (1/(2πi)) ∮_{|z − a| = r} f(z)/(z − a)^(n+1) dz, the loop walked once anticlockwise. -/
noncomputable def laurentCoeff (f : ℂ → ℂ) (a : ℂ) (r : ℝ) (n : ℤ) : ℂ :=
  (2 * π * I)⁻¹ * ∮ z in C(a, r), f z / (z - a) ^ (n + 1)

/-- **Removable:** the hole fills. Some function g with a complex power series at a agrees
with f at every point near a other than a itself. -/
def IsRemovableAt (f : ℂ → ℂ) (a : ℂ) : Prop :=
  ∃ g : ℂ → ℂ, AnalyticAt ℂ g a ∧ ∀ᶠ z in 𝓝[≠] a, f z = g z

/-- **Pole of order m (pole form):** near a, other than at a itself, f(z) = g(z)/(z − a)^m
with g having a complex power series at a and g(a) ≠ 0. -/
def IsPoleOfOrder (f : ℂ → ℂ) (a : ℂ) (m : ℕ) : Prop :=
  ∃ g : ℂ → ℂ, AnalyticAt ℂ g a ∧ g a ≠ 0 ∧ ∀ᶠ z in 𝓝[≠] a, f z = g z / (z - a) ^ m

/-- **Essential:** neither removable nor a pole of any order m ≥ 1. -/
def IsEssentialAt (f : ℂ → ℂ) (a : ℂ) : Prop :=
  ¬ IsRemovableAt f a ∧ ∀ m : ℕ, 0 < m → ¬ IsPoleOfOrder f a m

-- Helper lemmas.

lemma laurentCoeff_eq_of_le {f : ℂ → ℂ} {a : ℂ} {R ρ r : ℝ} (hρ : 0 < ρ) (hρr : ρ ≤ r)
    (hrR : r < R) (hf : DifferentiableOn ℂ f (ball a R \ {a})) (n : ℤ) :
    laurentCoeff f a r n = laurentCoeff f a ρ n := by
  unfold laurentCoeff
  congr 1
  have hU : IsOpen (ball a R \ {a}) := isOpen_ball.sdiff isClosed_singleton
  have key : ∀ z ∈ closedBall a r \ ball a ρ,
      DifferentiableAt ℂ (fun z => f z / (z - a) ^ (n + 1)) z := by
    intro z hz
    have hza : z ≠ a := by
      rintro rfl; exact hz.2 (mem_ball_self hρ)
    have hzU : z ∈ ball a R \ {a} :=
      ⟨mem_ball.2 (lt_of_le_of_lt (mem_closedBall.1 hz.1) hrR), hza⟩
    exact (hf.differentiableAt (hU.mem_nhds hzU)).div
      ((differentiableAt_id.sub_const a).zpow (Or.inl (sub_ne_zero.2 hza)))
      (zpow_ne_zero _ (sub_ne_zero.2 hza))
  exact circleIntegral_eq_of_differentiable_on_annulus_off_countable hρ hρr Set.countable_empty
    (fun z hz => (key z hz).continuousAt.continuousWithinAt)
    (fun z hz => key z ⟨ball_subset_closedBall hz.1.1, fun h => hz.1.2 (ball_subset_closedBall h)⟩)

lemma laurentCoeff_shift {f : ℂ → ℂ} {a : ℂ} {r : ℝ} (hr : 0 < r) (m : ℕ) (n : ℤ) :
    laurentCoeff (fun z => (z - a) ^ m * f z) a r (n + m) = laurentCoeff f a r n := by
  unfold laurentCoeff
  congr 1
  refine circleIntegral.integral_congr hr.le fun z hz => ?_
  have hza : z - a ≠ 0 := by
    intro h
    rw [sub_eq_zero] at h
    subst h
    simp at hz
    exact hr.ne hz
  simp only
  rw [show n + (m : ℤ) + 1 = (n + 1) + (m : ℤ) by ring, zpow_add₀ hza, zpow_natCast]
  field_simp

lemma laurentCoeff_of_removable {f G : ℂ → ℂ} {a : ℂ} {R r : ℝ} (hr : 0 < r) (hrR : r < R)
    (hf : DifferentiableOn ℂ f (ball a R \ {a})) (hG : AnalyticAt ℂ G a)
    (hfG : ∀ᶠ z in 𝓝[≠] a, f z = G z) :
    (∀ k : ℕ, 0 < k → laurentCoeff f a r (-(k : ℤ)) = 0) ∧ laurentCoeff f a r 0 = G a := by
  have h1 : ∀ᶠ z in 𝓝 a, AnalyticAt ℂ G z ∧ (z ≠ a → f z = G z) :=
    hG.eventually_analyticAt.and (eventually_nhdsWithin_iff.1 hfG)
  obtain ⟨ε, hε, hεs⟩ := Metric.eventually_nhds_iff_ball.1 h1
  set ρ := min (ε / 2) r with hρdef
  have hρ : 0 < ρ := lt_min (half_pos hε) hr
  have hρr : ρ ≤ r := min_le_right _ _
  have hρε : ρ < ε := lt_of_le_of_lt (min_le_left _ _) (half_lt_self hε)
  have hcb : closedBall a ρ ⊆ ball a ε := closedBall_subset_ball hρε
  have hGd : ∀ z ∈ closedBall a ρ, DifferentiableAt ℂ G z :=
    fun z hz => (hεs z (hcb hz)).1.differentiableAt
  have hsph : ∀ z ∈ sphere a ρ, z ≠ a ∧ f z = G z := by
    intro z hz
    have hza : z ≠ a := by
      rintro rfl; simp at hz; exact hρ.ne hz
    exact ⟨hza, (hεs z (hcb (sphere_subset_closedBall hz))).2 hza⟩
  refine ⟨fun k hk => ?_, ?_⟩
  · rw [laurentCoeff_eq_of_le hρ hρr hrR hf, laurentCoeff]
    have : (∮ z in C(a, ρ), f z / (z - a) ^ (-(k : ℤ) + 1)) =
        ∮ z in C(a, ρ), G z * (z - a) ^ (k - 1) := by
      refine circleIntegral.integral_congr hρ.le fun z hz => ?_
      obtain ⟨hza, hfz⟩ := hsph z hz
      rw [hfz, show -(k : ℤ) + 1 = -((k - 1 : ℕ) : ℤ) by omega, zpow_neg, zpow_natCast,
        div_inv_eq_mul]
    have h0 : (∮ z in C(a, ρ), G z * (z - a) ^ (k - 1)) = 0 :=
      circleIntegral_eq_zero_of_differentiable_on_off_countable (f := fun z => G z * (z - a) ^ (k - 1))
        hρ.le Set.countable_empty
        (fun z hz => ((hGd z hz).mul ((differentiableAt_id.sub_const a).pow _)).continuousAt
          |>.continuousWithinAt)
        (fun z hz => (hGd z (ball_subset_closedBall hz.1)).mul
          ((differentiableAt_id.sub_const a).pow _))
    rw [this, h0, mul_zero]
  · rw [laurentCoeff_eq_of_le hρ hρr hrR hf, laurentCoeff]
    have : (∮ z in C(a, ρ), f z / (z - a) ^ ((0 : ℤ) + 1)) =
        ∮ z in C(a, ρ), (z - a)⁻¹ • G z := by
      refine circleIntegral.integral_congr hρ.le fun z hz => ?_
      obtain ⟨hza, hfz⟩ := hsph z hz
      simp only [zero_add, zpow_one, smul_eq_mul]
      rw [hfz, div_eq_inv_mul]
    rw [this, circleIntegral_sub_center_inv_smul_of_differentiable_on_off_countable hρ
      Set.countable_empty (fun z hz => (hGd z hz).continuousAt.continuousWithinAt)
      (fun z hz => hGd z (ball_subset_closedBall hz.1)), smul_eq_mul, ← mul_assoc,
      inv_mul_cancel₀ (by simp [Real.pi_ne_zero, I_ne_zero]), one_mul]

lemma hasSum_exterior {f : ℂ → ℂ} {c z : ℂ} {ρ : ℝ} (hf : CircleIntegrable f c ρ) (hρ : 0 < ρ)
    (hz : ρ < ‖z - c‖) :
    HasSum (fun n : ℕ => ∮ w in C(c, ρ), ((w - c) ^ n * ((z - c) ^ (n + 1))⁻¹) * f w)
      (∮ w in C(c, ρ), (z - w)⁻¹ * f w) := by
  have hzc : 0 < ‖z - c‖ := hρ.trans hz
  set q : ℝ := ρ / ‖z - c‖ with hq
  have hq0 : 0 ≤ q := div_nonneg hρ.le hzc.le
  have hq1 : q < 1 := (div_lt_one hzc).2 hz
  refine intervalIntegral.hasSum_integral_of_dominated_convergence
      (fun n θ => ρ * ‖z - c‖⁻¹ * ‖f (circleMap c ρ θ)‖ * q ^ n) (fun n => ?_) (fun n => ?_)
      ?_ ?_ ?_
  · simp only [deriv_circleMap]
    apply_rules [MeasureTheory.AEStronglyMeasurable.smul, MeasureTheory.AEStronglyMeasurable.mul, hf.def'.1] <;>
      apply Measurable.aestronglyMeasurable <;> fun_prop
  · refine Eventually.of_forall fun θ _ => ?_
    simp only [deriv_circleMap, smul_eq_mul, norm_mul, norm_pow, norm_inv, norm_circleMap_zero,
      norm_I, abs_of_pos hρ, circleMap_sub_center]
    rw [hq, div_pow]
    apply le_of_eq
    field_simp
    ring
  · exact Eventually.of_forall fun _ _ => (summable_geometric_of_lt_one hq0 hq1).mul_left _
  · simp only [tsum_mul_left, tsum_geometric_of_lt_one hq0 hq1]
    exact (hf.norm.const_mul _).mul_continuousOn continuousOn_const
  · refine Eventually.of_forall fun θ _ => ?_
    simp only [smul_eq_mul]
    refine HasSum.mul_left _ ?_
    have hw : ‖(circleMap c ρ θ - c) / (z - c)‖ < 1 := by
      rw [norm_div, circleMap_sub_center, norm_circleMap_zero, abs_of_pos hρ]
      exact hq1
    have hne : z - c ≠ 0 := norm_pos_iff.1 hzc
    have hne2 : z - circleMap c ρ θ ≠ 0 := by
      intro h
      rw [sub_eq_zero] at h
      rw [h, circleMap_sub_center, norm_circleMap_zero, abs_of_pos hρ] at hz
      exact lt_irrefl _ hz
    convert ((hasSum_geometric_of_norm_lt_one hw).mul_left ((z - c)⁻¹)).mul_right
      (f (circleMap c ρ θ)) using 1
    · funext n
      rw [div_pow, pow_succ]
      field_simp
    · have h3 : 1 - (circleMap c ρ θ - c) / (z - c) = (z - circleMap c ρ θ) / (z - c) := by
        field_simp; ring
      rw [h3]
      field_simp

lemma removable_of_coeff_zero {f : ℂ → ℂ} {a : ℂ} {R r : ℝ} (hr : 0 < r) (hrR : r < R)
    (hf : DifferentiableOn ℂ f (ball a R \ {a}))
    (h : ∀ k : ℕ, 0 < k → laurentCoeff f a r (-(k : ℤ)) = 0) : IsRemovableAt f a := by
  have hU : IsOpen (ball a R \ {a}) := isOpen_ball.sdiff isClosed_singleton
  have hsphU : ∀ s, 0 < s → s ≤ r → sphere a s ⊆ ball a R \ {a} := by
    intro s hs hsr w hw
    refine ⟨mem_ball.2 (lt_of_le_of_lt (le_of_eq (mem_sphere.1 hw)) (hsr.trans_lt hrR)), ?_⟩
    rintro rfl
    simp at hw
    exact hs.ne hw
  have hfs : ∀ s, 0 < s → s ≤ r → ContinuousOn f (sphere a s) :=
    fun s hs hsr => hf.continuousOn.mono (hsphU s hs hsr)
  have hps := hasFPowerSeriesOn_cauchy_integral (c := a) (R := r.toNNReal)
    (by rw [Real.coe_toNNReal _ hr.le]; exact (hfs r hr le_rfl).circleIntegrable hr.le)
    (by simpa using hr)
  rw [Real.coe_toNNReal _ hr.le] at hps
  refine ⟨_, hps.analyticAt, ?_⟩
  rw [eventually_nhdsWithin_iff]
  filter_upwards [ball_mem_nhds a hr] with z hz hza
  have hza' : z - a ≠ 0 := sub_ne_zero.2 hza
  have hd : 0 < ‖z - a‖ := norm_pos_iff.2 hza'
  have hzr : ‖z - a‖ < r := mem_ball_iff_norm.1 hz
  set ρ := ‖z - a‖ / 2 with hρdef
  have hρ : 0 < ρ := half_pos hd
  have hρz : ρ < ‖z - a‖ := half_lt_self hd
  have hρr : ρ ≤ r := (hρz.trans hzr).le
  have hzU : z ∈ ball a R \ {a} := ⟨mem_ball_iff_norm.2 (hzr.trans hrR), hza⟩
  have hsub : closedBall a r \ ball a ρ ⊆ ball a R \ {a} := by
    intro w hw
    refine ⟨mem_ball.2 (lt_of_le_of_lt (mem_closedBall.1 hw.1) hrR), ?_⟩
    rintro rfl
    exact hw.2 (mem_ball_self hρ)
  have hFc : ContinuousOn (dslope f z) (ball a R \ {a}) :=
    (continuousOn_dslope (hU.mem_nhds hzU)).2 ⟨hf.continuousOn, hf.differentiableAt (hU.mem_nhds hzU)⟩
  have hA := circleIntegral_eq_of_differentiable_on_annulus_off_countable hρ hρr
    (Set.countable_singleton z) (hFc.mono hsub) (fun w hw => (differentiableAt_dslope_of_ne hw.2).2
      (hf.differentiableAt (hU.mem_nhds (hsub ⟨ball_subset_closedBall hw.1.1,
        fun h => hw.1.2 (ball_subset_closedBall h)⟩))))
  have hsplit : ∀ s, 0 < s → s ≤ r → (∀ w ∈ sphere a s, w ≠ z) →
      (∮ w in C(a, s), dslope f z w) =
        (∮ w in C(a, s), (w - z)⁻¹ • f w) - (∮ w in C(a, s), (w - z)⁻¹) • f z := by
    intro s hs hsr hne
    have hc' : ContinuousOn (fun w => (w - z)⁻¹) (sphere a s) :=
      (continuousOn_id.sub continuousOn_const).inv₀ fun w hw => sub_ne_zero.2 (hne w hw)
    rw [← circleIntegral.integral_smul_const, ← circleIntegral.integral_sub]
    · exact circleIntegral.integral_congr hs.le fun w hw => by
        rw [dslope_of_ne _ (hne w hw), slope_def_module, smul_sub]
    · exact (hc'.smul (hfs s hs hsr)).circleIntegrable hs.le
    · exact (hc'.smul continuousOn_const).circleIntegrable hs.le
  have hneR : ∀ w ∈ sphere a r, w ≠ z := by
    rintro w hw rfl
    rw [mem_sphere, dist_eq_norm] at hw
    exact hzr.ne hw
  have hneρ : ∀ w ∈ sphere a ρ, w ≠ z := by
    rintro w hw rfl
    rw [mem_sphere, dist_eq_norm] at hw
    exact hρz.ne' hw
  have hI1 : (∮ w in C(a, r), (w - z)⁻¹) = 2 * π * I :=
    circleIntegral.integral_sub_inv_of_mem_ball hz
  have hI2 : (∮ w in C(a, ρ), (w - z)⁻¹) = 0 := by
    have hcl : ∀ w ∈ closedBall a ρ, w - z ≠ 0 := by
      intro w hw h
      rw [sub_eq_zero] at h
      subst h
      rw [mem_closedBall, dist_eq_norm] at hw
      exact absurd hw (not_le.2 hρz)
    exact circleIntegral_eq_zero_of_differentiable_on_off_countable (f := fun w => (w - z)⁻¹)
      hρ.le Set.countable_empty
      (fun w hw => ((differentiableAt_id (𝕜 := ℂ) (x := w) |>.sub_const z).inv (hcl w hw)).continuousAt.continuousWithinAt)
      (fun w hw => (differentiableAt_id (𝕜 := ℂ) (x := w) |>.sub_const z).inv (hcl w (ball_subset_closedBall hw.1)))
  have hS := hasSum_exterior (c := a) (z := z) ((hfs ρ hρ hρr).circleIntegrable hρ.le) hρ hρz
  have hterm : ∀ n : ℕ,
      (∮ w in C(a, ρ), ((w - a) ^ n * ((z - a) ^ (n + 1))⁻¹) * f w) = 0 := by
    intro n
    have hc := h (n + 1) (Nat.succ_pos n)
    rw [laurentCoeff_eq_of_le hρ hρr hrR hf, laurentCoeff, mul_eq_zero] at hc
    have hc2 : (∮ w in C(a, ρ), f w / (w - a) ^ (-((n + 1 : ℕ) : ℤ) + 1)) = 0 :=
      hc.resolve_left (inv_ne_zero (by simp [Real.pi_ne_zero, I_ne_zero]))
    have : (∮ w in C(a, ρ), ((w - a) ^ n * ((z - a) ^ (n + 1))⁻¹) * f w) =
        ∮ w in C(a, ρ), ((z - a) ^ (n + 1))⁻¹ * (f w / (w - a) ^ (-((n + 1 : ℕ) : ℤ) + 1)) := by
      refine circleIntegral.integral_congr hρ.le fun w _ => ?_
      rw [show -((n + 1 : ℕ) : ℤ) + 1 = -((n : ℕ) : ℤ) by push_cast; ring, zpow_neg, zpow_natCast,
        div_inv_eq_mul]
      ring
    rw [this, circleIntegral.integral_const_mul, hc2, mul_zero]
  have hinner0 : (∮ w in C(a, ρ), (z - w)⁻¹ * f w) = 0 := by
    have hS' := hS
    simp only [hterm] at hS'
    exact hS'.unique hasSum_zero
  have hinner : (∮ w in C(a, ρ), (w - z)⁻¹ • f w) = 0 := by
    have : (∮ w in C(a, ρ), (w - z)⁻¹ • f w) = ∮ w in C(a, ρ), (-1) * ((z - w)⁻¹ * f w) := by
      refine circleIntegral.integral_congr hρ.le fun w hw => ?_
      have : w - z ≠ 0 := sub_ne_zero.2 (hneρ w hw)
      have : z - w ≠ 0 := sub_ne_zero.2 (hneρ w hw).symm
      simp only [smul_eq_mul]
      field_simp
      ring
    rw [this, circleIntegral.integral_const_mul, hinner0, mul_zero]
  rw [hsplit r hr le_rfl hneR, hsplit ρ hρ hρr hneρ, hI1, hI2, hinner, zero_smul, sub_zero,
    sub_eq_zero] at hA
  show f z = (2 * π * I : ℂ)⁻¹ • ∮ w in C(a, r), (w - z)⁻¹ • f w
  rw [hA, smul_smul, inv_mul_cancel₀ (by simp [Real.pi_ne_zero, I_ne_zero]),
    one_smul]

lemma removable_of_bdd {f : ℂ → ℂ} {a : ℂ} {R M : ℝ} (hR : 0 < R)
    (hf : DifferentiableOn ℂ f (ball a R \ {a})) (hM : ∀ z ∈ ball a R \ {a}, ‖f z‖ ≤ M) :
    IsRemovableAt f a := by
  have hb : BddAbove (norm ∘ f '' (ball a R \ {a})) := ⟨M, by
    rintro _ ⟨z, hz, rfl⟩
    exact hM z hz⟩
  have hd := Complex.differentiableOn_update_limUnder_of_bddAbove (ball_mem_nhds a hR) hf hb
  refine ⟨_, hd.analyticAt (ball_mem_nhds a hR), ?_⟩
  filter_upwards [self_mem_nhdsWithin] with z hz
  exact (Function.update_of_ne hz _ _).symm

/-- Casorati–Weierstrass with the radius `R` assumed positive. -/
lemma essential_comes_close_of_pos {f : ℂ → ℂ} {a : ℂ} {R : ℝ} (hR : 0 < R)
    (hf : DifferentiableOn ℂ f (ball a R \ {a})) (hess : IsEssentialAt f a)
    (w : ℂ) (ε : ℝ) (hε : 0 < ε) (δ : ℝ) (hδ : 0 < δ) :
    ∃ z ∈ ball a δ \ {a}, ‖f z - w‖ < ε := by
  by_contra hcon
  push Not at hcon
  set ρ := min δ R with hρdef
  have hρ : 0 < ρ := lt_min hδ hR
  have hsubδ : ball a ρ \ {a} ⊆ ball a δ \ {a} :=
    Set.sdiff_subset_sdiff_left (ball_subset_ball (min_le_left _ _))
  have hsubR : ball a ρ \ {a} ⊆ ball a R \ {a} :=
    Set.sdiff_subset_sdiff_left (ball_subset_ball (min_le_right _ _))
  have hne : ∀ z ∈ ball a ρ \ {a}, f z - w ≠ 0 := fun z hz =>
    norm_pos_iff.1 (hε.trans_le (hcon z (hsubδ hz)))
  have hbd : ∀ z ∈ ball a ρ \ {a}, ‖(fun z => (f z - w)⁻¹) z‖ ≤ ε⁻¹ := by
    intro z hz
    rw [norm_inv]
    exact inv_anti₀ hε (hcon z (hsubδ hz))
  have hd : DifferentiableOn ℂ (fun z => (f z - w)⁻¹) (ball a ρ \ {a}) :=
    ((hf.mono hsubR).sub_const w).inv hne
  obtain ⟨H, hH, hhH⟩ := removable_of_bdd hρ hd hbd
  have hev : ∀ᶠ z in 𝓝[≠] a, (f z - w)⁻¹ = H z ∧ f z - w ≠ 0 := by
    refine hhH.and ?_
    filter_upwards [inter_mem_nhdsWithin {a}ᶜ (ball_mem_nhds a hρ)] with z hz
    exact hne z ⟨hz.2, hz.1⟩
  rcases hH.eventually_eq_zero_or_eventually_ne_zero with h0 | h0
  · obtain ⟨z, ⟨hz1, hz2⟩, hz3⟩ := (hev.and (h0.filter_mono nhdsWithin_le_nhds)).exists
    rw [hz3] at hz1
    exact inv_ne_zero hz2 hz1
  · have hnz : ¬ ∀ᶠ z in 𝓝 a, H z = 0 := by
      intro h
      obtain ⟨z, hz1, hz2⟩ := (h0.and (h.filter_mono nhdsWithin_le_nhds)).exists
      exact hz1 hz2
    obtain ⟨n, K, hK, hKa, hHK⟩ := hH.exists_eventuallyEq_pow_smul_ne_zero_iff.2 hnz
    set g : ℂ → ℂ := fun z => (w * (z - a) ^ n * K z + 1) / K z with hgdef
    have hg : AnalyticAt ℂ g a :=
      (((analyticAt_const.mul ((analyticAt_id.sub analyticAt_const).pow n)).mul hK).add
        analyticAt_const).div hK hKa
    have hfg : ∀ᶠ z in 𝓝[≠] a, f z = g z / (z - a) ^ n := by
      filter_upwards [hev, hHK.filter_mono nhdsWithin_le_nhds, self_mem_nhdsWithin,
        (hK.continuousAt.eventually_ne hKa).filter_mono nhdsWithin_le_nhds]
        with z ⟨h1, h2⟩ h3 hza hKz
      have hzn : (z - a) ^ n ≠ 0 := pow_ne_zero _ (sub_ne_zero.2 hza)
      rw [h3, smul_eq_mul] at h1
      have h4 : f z - w = ((z - a) ^ n * K z)⁻¹ := by rw [← h1, inv_inv]
      have h5 : f z = w + ((z - a) ^ n * K z)⁻¹ := by rw [← h4]; ring
      rw [h5, hgdef]
      field_simp
    rcases Nat.eq_zero_or_pos n with rfl | hn
    · exact hess.1 ⟨g, hg, by simpa using hfg⟩
    · exact hess.2 n hn ⟨g, hg, by simp [hgdef, zero_pow hn.ne', hKa], hfg⟩

/-- **The negative powers tell you which.** Let f have a complex derivative at every point of
the punctured disc 0 < |z − a| < R, and read the Laurent coefficients c_n off any circle of
radius r with 0 < r < R. Then:
* no negative powers (c_{−k} = 0 for every k ≥ 1) exactly when the singularity is removable;
* for m ≥ 1, the lowest negative power is −m (c_{−m} ≠ 0 and c_{−k} = 0 for every k > m)
  exactly when a is a pole of order m;
* infinitely many nonzero negative-power coefficients exactly when a is essential. -/
theorem negative_powers_classify_isolated_singularity {f : ℂ → ℂ} {a : ℂ} {R r : ℝ}
    (hr : 0 < r) (hrR : r < R) (hf : DifferentiableOn ℂ f (ball a R \ {a})) :
    ((∀ k : ℕ, 0 < k → laurentCoeff f a r (-(k : ℤ)) = 0) ↔ IsRemovableAt f a) ∧
    (∀ m : ℕ, 0 < m →
      ((laurentCoeff f a r (-(m : ℤ)) ≠ 0 ∧ ∀ k : ℕ, m < k → laurentCoeff f a r (-(k : ℤ)) = 0)
        ↔ IsPoleOfOrder f a m)) ∧
    ({k : ℕ | 0 < k ∧ laurentCoeff f a r (-(k : ℤ)) ≠ 0}.Infinite ↔ IsEssentialAt f a) := by
  have P1 : (∀ k : ℕ, 0 < k → laurentCoeff f a r (-(k : ℤ)) = 0) ↔ IsRemovableAt f a :=
    ⟨removable_of_coeff_zero hr hrR hf,
      fun ⟨G, hG, hfG⟩ => (laurentCoeff_of_removable hr hrR hf hG hfG).1⟩
  have P2 : ∀ m : ℕ, 0 < m →
      ((laurentCoeff f a r (-(m : ℤ)) ≠ 0 ∧ ∀ k : ℕ, m < k → laurentCoeff f a r (-(k : ℤ)) = 0)
        ↔ IsPoleOfOrder f a m) := by
    intro m hm
    have hhd : DifferentiableOn ℂ (fun z => (z - a) ^ m * f z) (ball a R \ {a}) :=
      ((differentiable_id.sub_const a).pow m).differentiableOn.mul hf
    have hshift : ∀ n : ℤ, laurentCoeff (fun z => (z - a) ^ m * f z) a r (n + m) =
        laurentCoeff f a r n := laurentCoeff_shift hr m
    have hm0 : laurentCoeff (fun z => (z - a) ^ m * f z) a r 0 = laurentCoeff f a r (-(m : ℤ)) := by
      rw [← hshift]; simp
    constructor
    · rintro ⟨hne, hzero⟩
      have hrem : IsRemovableAt (fun z => (z - a) ^ m * f z) a :=
        removable_of_coeff_zero hr hrR hhd (fun k hk => by
          have := hshift (-((k + m : ℕ) : ℤ))
          rw [show -((k + m : ℕ) : ℤ) + m = -(k : ℤ) by push_cast; ring] at this
          rw [this]
          exact hzero (k + m) (by omega))
      obtain ⟨G, hG, hhG⟩ := hrem
      have hc0 := (laurentCoeff_of_removable hr hrR hhd hG hhG).2
      refine ⟨G, hG, by rw [← hc0, hm0]; exact hne, ?_⟩
      filter_upwards [hhG, self_mem_nhdsWithin] with z hz hza
      have hza' : (z - a) ^ m ≠ 0 := pow_ne_zero _ (sub_ne_zero.2 hza)
      rw [← hz]
      field_simp
    · rintro ⟨g, hg, hga, hfg⟩
      have hhg : ∀ᶠ z in 𝓝[≠] a, (fun z => (z - a) ^ m * f z) z = g z := by
        filter_upwards [hfg, self_mem_nhdsWithin] with z hz hza
        have hza' : (z - a) ^ m ≠ 0 := pow_ne_zero _ (sub_ne_zero.2 hza)
        rw [hz]
        field_simp
      obtain ⟨h1, h0⟩ := laurentCoeff_of_removable hr hrR hhd hg hhg
      refine ⟨?_, fun k hk => ?_⟩
      · rw [← hm0, h0]; exact hga
      · rw [← hshift]
        rw [show -(k : ℤ) + m = -((k - m : ℕ) : ℤ) by push_cast [Nat.cast_sub hk.le]; ring]
        exact h1 (k - m) (by omega)
  refine ⟨P1, P2, ⟨fun hinf => ⟨fun hrem => ?_, fun m hm hpole => ?_⟩, ?_⟩⟩
  · apply hinf
    exact Set.finite_empty.subset fun k hk => (hk.2 (P1.2 hrem k hk.1)).elim
  · obtain ⟨_, hz⟩ := (P2 m hm).2 hpole
    apply hinf
    refine (Set.finite_Iic m).subset fun k hk => ?_
    by_contra hkm
    exact hk.2 (hz k (by simp only [Set.mem_Iic, not_le] at hkm; exact hkm))
  · rintro ⟨hnrem, hnpole⟩ hfin
    by_cases hS : {k : ℕ | 0 < k ∧ laurentCoeff f a r (-(k : ℤ)) ≠ 0}.Nonempty
    · have hm := Nat.sSup_mem hS hfin.bddAbove
      refine hnpole _ hm.1 ((P2 _ hm.1).1 ⟨hm.2, fun k hk => ?_⟩)
      by_contra hne
      exact absurd (le_csSup hfin.bddAbove ⟨by omega, hne⟩) (not_le.2 hk)
    · apply hnrem
      apply P1.1
      intro k hk
      by_contra hne
      exact hS ⟨k, hk, hne⟩

/-- **Riemann's removable-singularity theorem.** If f has a complex derivative on the punctured
disc 0 < |z − a| < R and |f(z)| ≤ M there, then every negative-power Laurent coefficient
(read off any circle of radius r, 0 < r < R) is 0, and the singularity is removable. -/
theorem bounded_means_no_negative_powers {f : ℂ → ℂ} {a : ℂ} {R r M : ℝ}
    (hr : 0 < r) (hrR : r < R) (hf : DifferentiableOn ℂ f (ball a R \ {a}))
    (hM : ∀ z ∈ ball a R \ {a}, ‖f z‖ ≤ M) :
    (∀ k : ℕ, 0 < k → laurentCoeff f a r (-(k : ℤ)) = 0) ∧ IsRemovableAt f a := by
  have hR : 0 < R := hr.trans hrR
  have hb : BddAbove (norm ∘ f '' (ball a R \ {a})) := ⟨M, by
    rintro _ ⟨z, hz, rfl⟩
    exact hM z hz⟩
  have hd := Complex.differentiableOn_update_limUnder_of_bddAbove (ball_mem_nhds a hR) hf hb
  have hG := hd.analyticAt (ball_mem_nhds a hR)
  have hfG : ∀ᶠ z in 𝓝[≠] a, f z = Function.update f a (limUnder (𝓝[≠] a) f) z := by
    filter_upwards [self_mem_nhdsWithin] with z hz
    exact (Function.update_of_ne hz _ _).symm
  exact ⟨(laurentCoeff_of_removable hr hrR hf hG hfG).1, _, hG, hfG⟩

/-- **Casorati–Weierstrass theorem.** If f has a complex derivative on a genuine punctured
disc 0 < |z − a| < R (radius R > 0) and a is an essential singularity (neither removable nor
a pole), then for every value w and every tolerance ε > 0, every punctured disc round a,
however small (radius δ > 0), holds a point z with |f(z) − w| < ε. Put another way: f maps every punctured disc round a onto a dense set. -/
theorem essential_comes_close_to_every_value {f : ℂ → ℂ} {a : ℂ} {R : ℝ}
    (hR : 0 < R) (hf : DifferentiableOn ℂ f (ball a R \ {a})) (hess : IsEssentialAt f a)
    (w : ℂ) (ε : ℝ) (hε : 0 < ε) (δ : ℝ) (hδ : 0 < δ) :
    ∃ z ∈ ball a δ \ {a}, ‖f z - w‖ < ε := by
  exact essential_comes_close_of_pos hR hf hess w ε hε δ hδ

-- The card's pole: 1/(z − 2)^2 has a pole of order 2 at 2, with g = 1.
example : IsPoleOfOrder (fun z : ℂ => 1 / (z - 2) ^ 2) 2 2 := by
  exact ⟨fun _ => 1, analyticAt_const, one_ne_zero, Eventually.of_forall fun _ => rfl⟩

-- 1/(z − 2)^2 at distances 1/10 and 1/20 (0.1 and 0.05): sizes 100 and 400.
example : (1 : ℚ) / (1 / 10) ^ 2 = 100 := by norm_num
example : (1 : ℚ) / (1 / 20) ^ 2 = 400 := by norm_num
-- Halving the distance multiplies the size by 2^m = 4 for the order m = 2.
example : (1 : ℚ) / (1 / 20) ^ 2 = 2 ^ 2 * ((1 : ℚ) / (1 / 10) ^ 2) := by norm_num

-- Order test at z = 2.01: (z − 2)^m · f(z) for m = 1, 2, 3 gives 100, 1, 1/100.
example : (1 / 100 : ℚ) ^ 1 * (1 / (1 / 100) ^ 2) = 100 := by norm_num
example : (1 / 100 : ℚ) ^ 2 * (1 / (1 / 100) ^ 2) = 1 := by norm_num
example : (1 / 100 : ℚ) ^ 3 * (1 / (1 / 100) ^ 2) = 1 / 100 := by norm_num

-- e^(1/z): the coefficients on the powers −1, −2, −3 are 1/1!, 1/2!, 1/3! = 1, 1/2, 1/6.
example : (1 : ℚ) / (Nat.factorial 1) = 1 := by norm_num [Nat.factorial]
example : (1 : ℚ) / (Nat.factorial 2) = 1 / 2 := by norm_num [Nat.factorial]
example : (1 : ℚ) / (Nat.factorial 3) = 1 / 6 := by norm_num [Nat.factorial]

#print axioms negative_powers_classify_isolated_singularity
#print axioms bounded_means_no_negative_powers
#print axioms essential_comes_close_to_every_value
#print axioms laurentCoeff_eq_of_le
#print axioms laurentCoeff_shift
#print axioms laurentCoeff_of_removable
#print axioms hasSum_exterior
#print axioms removable_of_coeff_zero
#print axioms removable_of_bdd
#print axioms essential_comes_close_of_pos
