-- Weierstrass factorization: every entire function other than 0 is e^g times z^m times a locally uniformly convergent product of elementary factors over its nonzero zeros, any list of nonzero zeros running off to infinity is the zero list of such a product, and 1/Γ(z) is z e^(γz) times the product of (1 + z/n)e^(−z/n).
import Mathlib.Analysis.SpecialFunctions.Gamma.Beta
import Mathlib.NumberTheory.Harmonic.EulerMascheroni
import Mathlib.Analysis.Analytic.Order
import Mathlib.Topology.Algebra.InfiniteSum.UniformOn
import Mathlib.SetTheory.Cardinal.Finite
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecialFunctions.Complex.LogBounds
import Mathlib.Analysis.Normed.Module.MultipliableUniformlyOn
import Mathlib.Analysis.Complex.LocallyUniformLimit
import Mathlib.Analysis.Complex.HasPrimitives
import Mathlib.Analysis.Meromorphic.NormalForm
import Mathlib.Analysis.Complex.CauchyIntegral

open Complex Filter Topology Finset

/-- The elementary factor of degree p: E_p(w) = (1 − w) · e^(w + w^2/2 + ⋯ + w^p/p).
Degree 0 is the plain factor 1 − w. -/
noncomputable def elementaryFactor (p : ℕ) (w : ℂ) : ℂ :=
  (1 - w) * Complex.exp (∑ k ∈ Icc 1 p, w ^ k / (k : ℂ))

/-- The logarithm of an elementary factor near 0. -/
noncomputable def efLog (p : ℕ) (w : ℂ) : ℂ :=
  Complex.log (1 - w) + ∑ k ∈ Icc 1 p, w ^ k / (k : ℂ)

lemma ef_differentiable (p : ℕ) : Differentiable ℂ (elementaryFactor p) := by
  unfold elementaryFactor; fun_prop

#print axioms ef_differentiable

lemma ef_eq_exp (p : ℕ) {w : ℂ} (hw : ‖w‖ < 1) : elementaryFactor p w = Complex.exp (efLog p w) := by
  have h1 : (1 : ℂ) - w ≠ 0 := by
    intro h; rw [sub_eq_zero] at h; rw [← h] at hw; simp at hw
  rw [efLog, Complex.exp_add, Complex.exp_log h1, elementaryFactor]

#print axioms ef_eq_exp

lemma logTaylor_neg_eq (p : ℕ) (w : ℂ) :
    logTaylor (p + 1) (-w) = -∑ k ∈ Icc 1 p, w ^ k / (k : ℂ) := by
  induction p with
  | zero => simp [logTaylor]
  | succ p ih =>
    rw [logTaylor_succ, Pi.add_apply, ih, Finset.sum_Icc_succ_top (by omega)]
    have : ((-1 : ℂ) ^ (p + 1 + 1) * (-w) ^ (p + 1)) = -(w ^ (p + 1)) := by
      rw [neg_pow w, ← mul_assoc, ← pow_add]
      have : p + 1 + 1 + (p + 1) = 2 * (p + 1) + 1 := by ring
      rw [this, pow_succ, pow_mul]; norm_num
    simp only [this]
    push_cast
    ring

#print axioms logTaylor_neg_eq

lemma efLog_bound (p : ℕ) {w : ℂ} (hw : ‖w‖ ≤ 1 / 2) : ‖efLog p w‖ ≤ 2 * ‖w‖ ^ (p + 1) := by
  have hw1 : ‖-w‖ < 1 := by rw [norm_neg]; linarith
  have h := Complex.norm_log_sub_logTaylor_le p hw1
  rw [logTaylor_neg_eq, norm_neg, sub_neg_eq_add, ← sub_eq_add_neg] at h
  rw [efLog]
  refine h.trans ?_
  have h0 : 0 ≤ ‖w‖ ^ (p + 1) := by positivity
  have h2 : (1 - ‖w‖)⁻¹ ≤ 2 := by
    rw [inv_le_comm₀ (by linarith) (by norm_num)]; linarith
  have h3 : (1 : ℝ) ≤ p + 1 := by have := p.cast_nonneg (α := ℝ); linarith
  calc ‖w‖ ^ (p + 1) * (1 - ‖w‖)⁻¹ / (p + 1) ≤ ‖w‖ ^ (p + 1) * (1 - ‖w‖)⁻¹ :=
        div_le_self (by have : 0 < 1 - ‖w‖ := by linarith
                        positivity) h3
    _ ≤ ‖w‖ ^ (p + 1) * 2 := mul_le_mul_of_nonneg_left h2 h0
    _ = 2 * ‖w‖ ^ (p + 1) := by ring

#print axioms efLog_bound

lemma efLog_differentiableAt (p : ℕ) {w : ℂ} (hw : ‖w‖ < 1) : DifferentiableAt ℂ (efLog p) w := by
  have hs : 1 - w ∈ slitPlane := by
    rw [sub_eq_add_neg]; exact mem_slitPlane_of_norm_lt_one (by rwa [norm_neg])
  unfold efLog
  refine DifferentiableAt.add ?_ ?_
  · exact (differentiableAt_const _ |>.sub differentiableAt_id).clog hs
  · fun_prop

#print axioms efLog_differentiableAt

lemma ef_order (p : ℕ) {a : ℂ} (ha : a ≠ 0) (w : ℂ) :
    analyticOrderAt (fun z => elementaryFactor p (z / a)) w = if a = w then 1 else 0 := by
  have hA : AnalyticAt ℂ (fun z => elementaryFactor p (z / a)) w :=
    ((ef_differentiable p).comp (differentiable_id.div_const a)).analyticAt w
  split_ifs with h
  · subst h
    have := (hA.analyticOrderAt_eq_natCast (n := 1)).mpr
      ⟨fun z => (-a⁻¹) * Complex.exp (∑ k ∈ Icc 1 p, (z / a) ^ k / (k : ℂ)), by fun_prop,
        mul_ne_zero (neg_ne_zero.mpr (inv_ne_zero ha)) (Complex.exp_ne_zero _),
        Eventually.of_forall fun z => by
          simp only [elementaryFactor, pow_one, smul_eq_mul]; field_simp; ring⟩
    simpa using this
  · rw [analyticOrderAt_eq_zero]
    right
    simp only [elementaryFactor]
    refine mul_ne_zero ?_ (Complex.exp_ne_zero _)
    intro h'
    rw [sub_eq_zero, eq_div_iff ha, one_mul] at h'
    exact h h'

#print axioms ef_order

lemma order_prod {ι : Type*} (s : Finset ι) (f : ι → ℂ → ℂ) (w : ℂ)
    (h : ∀ i ∈ s, AnalyticAt ℂ (f i) w) :
    analyticOrderAt (fun z => ∏ i ∈ s, f i z) w = ∑ i ∈ s, analyticOrderAt (f i) w := by
  classical
  induction s using Finset.induction_on with
  | empty =>
    simp only [Finset.prod_empty, Finset.sum_empty]
    rw [analyticOrderAt_eq_zero]; right; simp
  | insert j s hj ih =>
    simp only [Finset.prod_insert hj, Finset.sum_insert hj]
    rw [← ih (fun i hi => h i (Finset.mem_insert_of_mem hi))]
    exact analyticOrderAt_mul (h j (Finset.mem_insert_self j s))
      (Finset.analyticAt_fun_prod s fun i hi => h i (Finset.mem_insert_of_mem hi))

#print axioms order_prod

lemma tendstoUniformlyOn_mul_left_bdd {β α : Type*} {l : Filter β} {s : Set α}
    {G : β → α → ℂ} {g A : α → ℂ} {B : ℝ} (hB : ∀ x ∈ s, ‖A x‖ ≤ B)
    (h : TendstoUniformlyOn G g l s) :
    TendstoUniformlyOn (fun n x => A x * G n x) (fun x => A x * g x) l s := by
  rw [Metric.tendstoUniformlyOn_iff] at h ⊢
  intro ε hε
  have hB' : 0 < |B| + 1 := by positivity
  filter_upwards [h (ε / (|B| + 1)) (div_pos hε hB')] with n hn x hx
  rw [dist_eq_norm, ← mul_sub, norm_mul]
  have h1 := hn x hx
  rw [dist_eq_norm] at h1
  calc ‖A x‖ * ‖g x - G n x‖ ≤ (|B| + 1) * ‖g x - G n x‖ :=
        mul_le_mul_of_nonneg_right (by linarith [hB x hx, le_abs_self B]) (norm_nonneg _)
    _ < (|B| + 1) * (ε / (|B| + 1)) := mul_lt_mul_of_pos_left h1 hB'
    _ = ε := by field_simp

#print axioms tendstoUniformlyOn_mul_left_bdd

section Core

variable {ι : Type*} (a : ι → ℂ) (p : ι → ℕ)

lemma finite_small (ha : ∀ i, a i ≠ 0)
    (hs : ∀ R : ℝ, Summable (fun i => (R / ‖a i‖) ^ (p i + 1))) (R : ℝ) :
    {i | ‖a i‖ ≤ R}.Finite := by
  have h := (hs R).tendsto_cofinite_zero.eventually (gt_mem_nhds (zero_lt_one' ℝ))
  rw [Filter.eventually_cofinite] at h
  refine h.subset fun i (hi : ‖a i‖ ≤ R) => ?_
  simp only [Set.mem_ofPred_eq, not_lt]
  have hai : 0 < ‖a i‖ := norm_pos_iff.mpr (ha i)
  exact one_le_pow₀ ((one_le_div hai).mpr hi)

#print axioms finite_small

lemma local_struct (ha : ∀ i, a i ≠ 0)
    (hs : ∀ R : ℝ, Summable (fun i => (R / ‖a i‖) ^ (p i + 1))) (R : ℝ) (hR : 0 < R) :
    ∃ F : Finset ι, ∃ S : ℂ → ℂ, (∀ i, a i ∈ Metric.ball (0 : ℂ) R → i ∈ F) ∧
      DifferentiableOn ℂ S (Metric.ball 0 R) ∧
      TendstoUniformlyOn (fun t z => ∏ i ∈ t, elementaryFactor (p i) (z / a i))
        (fun z => (∏ i ∈ F, elementaryFactor (p i) (z / a i)) * Complex.exp (S z)) atTop
        (Metric.ball 0 R) := by
  classical
  set F := (finite_small a p ha hs (2 * R)).toFinset with hFdef
  have hF : ∀ i, i ∈ F ↔ ‖a i‖ ≤ 2 * R := fun i => by simp [hFdef]
  set Lf : ι → ℂ → ℂ := fun i z => if i ∈ F then 0 else efLog (p i) (z / a i) with hLf
  set u : ι → ℝ := fun i => 2 * (R / ‖a i‖) ^ (p i + 1) with hu_def
  have hu : Summable u := (hs R).mul_left 2
  have hsmall : ∀ i, i ∉ F → ∀ z ∈ Metric.ball (0 : ℂ) R,
      ‖z / a i‖ ≤ R / ‖a i‖ ∧ R / ‖a i‖ ≤ 1 / 2 := by
    intro i hi z hz
    rw [hF, not_le] at hi
    rw [Metric.mem_ball, dist_zero_right] at hz
    have hai : 0 < ‖a i‖ := by linarith
    refine ⟨?_, ?_⟩
    · rw [norm_div]; exact div_le_div_of_nonneg_right hz.le hai.le
    · rw [div_le_iff₀ hai]; linarith
  have hbound : ∀ i z, z ∈ Metric.ball (0 : ℂ) R → ‖Lf i z‖ ≤ u i := by
    intro i z hz
    by_cases hi : i ∈ F
    · simp only [hLf, hi, ite_true, norm_zero, hu_def]; positivity
    · simp only [hLf, hi, ite_false, hu_def]
      obtain ⟨h1, h2⟩ := hsmall i hi z hz
      refine (efLog_bound (p i) (h1.trans h2)).trans ?_
      gcongr
  set S : ℂ → ℂ := fun z => ∑' i, Lf i z with hS_def
  have hS : TendstoUniformlyOn (fun t z => ∑ i ∈ t, Lf i z) S atTop (Metric.ball 0 R) :=
    tendstoUniformlyOn_tsum hu hbound
  have hLdiff : ∀ i, DifferentiableOn ℂ (Lf i) (Metric.ball 0 R) := by
    intro i
    by_cases hi : i ∈ F
    · simp only [hLf, hi, ite_true]; exact differentiableOn_const _
    · simp only [hLf, hi, ite_false]
      intro z hz
      obtain ⟨h1, h2⟩ := hsmall i hi z hz
      have : ‖z / a i‖ < 1 := by linarith
      exact ((efLog_differentiableAt (p i) this).comp z
        (differentiableAt_id.div_const (a i))).differentiableWithinAt
  have hSdiff : DifferentiableOn ℂ S (Metric.ball 0 R) :=
    hS.tendstoLocallyUniformlyOn.differentiableOn
      (Eventually.of_forall fun t => DifferentiableOn.fun_sum fun i _ => hLdiff i)
      Metric.isOpen_ball
  have hSbdd : BddAbove ((fun x => (S x).re) '' Metric.ball 0 R) := by
    refine ⟨∑' i, u i, ?_⟩
    rintro _ ⟨z, hz, rfl⟩
    exact (Complex.re_le_norm _).trans (tsum_of_norm_bounded hu.hasSum fun i => hbound i z hz)
  have hexp := hS.comp_cexp hSbdd
  set A : ℂ → ℂ := fun z => ∏ i ∈ F, elementaryFactor (p i) (z / a i) with hA_def
  have hAc : Continuous A :=
    continuous_finsetProd F fun i _ =>
      (ef_differentiable (p i)).continuous.comp (continuous_id.div_const (a i))
  obtain ⟨B, hB⟩ := (isCompact_closedBall (0 : ℂ) R).exists_bound_of_continuousOn hAc.continuousOn
  have hmul := tendstoUniformlyOn_mul_left_bdd (A := A)
    (fun x hx => hB x (Metric.ball_subset_closedBall hx)) hexp
  refine ⟨F, S, fun i hi => ?_, hSdiff, hmul.congr ?_⟩
  · rw [hF]; rw [Metric.mem_ball, dist_zero_right] at hi; linarith
  · filter_upwards [eventually_ge_atTop F] with t ht z hz
    simp only [Function.comp_apply, hA_def]
    have hfac : ∀ i, elementaryFactor (p i) (z / a i) =
        (if i ∈ F then elementaryFactor (p i) (z / a i) else 1) * Complex.exp (Lf i z) := by
      intro i
      by_cases hi : i ∈ F
      · simp [hLf, hi]
      · simp only [hLf, hi, ite_false, one_mul]
        obtain ⟨h1, h2⟩ := hsmall i hi z hz
        exact ef_eq_exp (p i) (by linarith)
    rw [Complex.exp_sum]
    conv_rhs => rw [Finset.prod_congr rfl fun i _ => hfac i, Finset.prod_mul_distrib,
      ← Finset.prod_filter, Finset.filter_mem_eq_inter, Finset.inter_eq_right.mpr ht]

#print axioms local_struct

theorem core_product (ha : ∀ i, a i ≠ 0)
    (hs : ∀ R : ℝ, Summable (fun i => (R / ‖a i‖) ^ (p i + 1))) :
    ∃ P : ℂ → ℂ,
      HasProdLocallyUniformlyOn (fun i z => elementaryFactor (p i) (z / a i)) P Set.univ ∧
      Differentiable ℂ P ∧
      ∀ w, analyticOrderAt P w = ENat.card {i // a i = w} := by
  classical
  set P : ℂ → ℂ := fun z => ∏' i, elementaryFactor (p i) (z / a i) with hP
  have key : ∀ R : ℝ, 0 < R → ∃ F : Finset ι, ∃ S : ℂ → ℂ,
      (∀ i, a i ∈ Metric.ball (0 : ℂ) R → i ∈ F) ∧
      DifferentiableOn ℂ S (Metric.ball 0 R) ∧
      TendstoUniformlyOn (fun t z => ∏ i ∈ t, elementaryFactor (p i) (z / a i)) P atTop
        (Metric.ball 0 R) ∧
      Set.EqOn P (fun z => (∏ i ∈ F, elementaryFactor (p i) (z / a i)) * Complex.exp (S z))
        (Metric.ball 0 R) := by
    intro R hR
    obtain ⟨F, S, hF, hSd, hT⟩ := local_struct a p ha hs R hR
    have hEq : Set.EqOn P (fun z => (∏ i ∈ F, elementaryFactor (p i) (z / a i)) *
        Complex.exp (S z)) (Metric.ball 0 R) := by
      intro z hz
      have h1 : HasProd (fun i => elementaryFactor (p i) (z / a i))
          ((∏ i ∈ F, elementaryFactor (p i) (z / a i)) * Complex.exp (S z)) :=
        hT.tendsto_at hz
      exact h1.tprod_eq
    exact ⟨F, S, hF, hSd, hT.congr_right hEq.symm, hEq⟩
  refine ⟨P, ?_, ?_, ?_⟩
  · refine tendstoLocallyUniformlyOn_of_forall_exists_nhds fun x _ => ?_
    obtain ⟨F, S, -, -, hT, -⟩ := key (‖x‖ + 1) (by positivity)
    refine ⟨Metric.ball 0 (‖x‖ + 1), nhdsWithin_le_nhds
      (Metric.isOpen_ball.mem_nhds (by simp)), hT⟩
  · intro w
    obtain ⟨F, S, -, hSd, -, hEq⟩ := key (‖w‖ + 1) (by positivity)
    have hw : Metric.ball (0 : ℂ) (‖w‖ + 1) ∈ 𝓝 w := Metric.isOpen_ball.mem_nhds (by simp)
    refine DifferentiableAt.congr_of_eventuallyEq ?_ (Filter.eventually_of_mem hw hEq)
    refine DifferentiableAt.mul ?_ ((hSd.differentiableAt hw).cexp)
    exact (Finset.analyticAt_fun_prod F fun i _ =>
      ((ef_differentiable (p i)).comp (differentiable_id.div_const (a i))).analyticAt w).differentiableAt
  · intro w
    obtain ⟨F, S, hF, hSd, -, hEq⟩ := key (‖w‖ + 1) (by positivity)
    have hwb : w ∈ Metric.ball (0 : ℂ) (‖w‖ + 1) := by simp
    have hw : Metric.ball (0 : ℂ) (‖w‖ + 1) ∈ 𝓝 w := Metric.isOpen_ball.mem_nhds hwb
    rw [analyticOrderAt_congr (Filter.eventually_of_mem hw hEq)]
    have hAi : ∀ i ∈ F, AnalyticAt ℂ (fun z => elementaryFactor (p i) (z / a i)) w := fun i _ =>
      ((ef_differentiable (p i)).comp (differentiable_id.div_const (a i))).analyticAt w
    have hA := Finset.analyticAt_fun_prod F hAi
    have hT : AnalyticAt ℂ (fun z => Complex.exp (S z)) w :=
      (hSd.cexp).analyticAt hw
    have hmul := analyticOrderAt_mul hA hT
    have hT0 : analyticOrderAt (fun z => Complex.exp (S z)) w = 0 :=
      analyticOrderAt_eq_zero.mpr (Or.inr (Complex.exp_ne_zero _))
    rw [show (fun z => (∏ i ∈ F, elementaryFactor (p i) (z / a i)) * Complex.exp (S z)) =
      (fun z => ∏ i ∈ F, elementaryFactor (p i) (z / a i)) * (fun z => Complex.exp (S z)) from rfl,
      hmul, hT0, add_zero, order_prod F _ w hAi]
    simp_rw [ef_order (p _) (ha _) w]
    rw [Finset.sum_boole]
    have e : {i // a i = w} ≃ (F.filter (fun i => a i = w)) :=
      Equiv.subtypeEquivRight fun i => by
        simp only [Finset.mem_filter, iff_and_self]
        intro h; exact hF i (h ▸ hwb)
    rw [ENat.card_congr e, ENat.card_eq_coe_fintype_card, Fintype.card_coe]

#print axioms core_product

end Core

lemma entire_exists_log (h : ℂ → ℂ) (hd : Differentiable ℂ h) (hne : ∀ z, h z ≠ 0) :
    ∃ g : ℂ → ℂ, Differentiable ℂ g ∧ ∀ z, h z = Complex.exp (g z) := by
  have hq : Differentiable ℂ (fun z => deriv h z / h z) := fun z =>
    ((hd.analyticAt z).deriv.differentiableAt).div (hd z) (hne z)
  obtain ⟨G, hG⟩ := hq.isExactOn_univ
  have hk : ∀ z, HasDerivAt (fun z => h z * Complex.exp (-G z)) 0 z := by
    intro z
    have h1 := (hd z).hasDerivAt.mul ((hG z (Set.mem_univ z)).neg.cexp)
    convert h1 using 1
    have := hne z
    field_simp
    ring
  have hkd : Differentiable ℂ (fun z => h z * Complex.exp (-G z)) := fun z => (hk z).differentiableAt
  have hc := is_const_of_deriv_eq_zero hkd (fun z => (hk z).deriv)
  set c := h 0 * Complex.exp (-G 0) with hc_def
  have hc0 : c ≠ 0 := mul_ne_zero (hne 0) (Complex.exp_ne_zero _)
  refine ⟨fun z => G z + Complex.log c, ?_, fun z => ?_⟩
  · exact fun z => ((hG z (Set.mem_univ z)).differentiableAt).add_const _
  · have hz := hc z 0
    rw [Complex.exp_add, Complex.exp_log hc0, hc_def, ← hz, mul_comm (h z), ← mul_assoc,
      ← Complex.exp_add, add_neg_cancel, Complex.exp_zero, one_mul]

#print axioms entire_exists_log

lemma entire_div_same_order (f q : ℂ → ℂ) (hf : Differentiable ℂ f) (hq : Differentiable ℂ q)
    (hord : ∀ w, analyticOrderAt q w = analyticOrderAt f w)
    (hntop : ∀ w, analyticOrderAt f w ≠ ⊤) :
    ∃ h : ℂ → ℂ, Differentiable ℂ h ∧ (∀ z, h z ≠ 0) ∧ ∀ z, f z = h z * q z := by
  set k : ℂ → ℂ := f / q with hk_def
  have hkm : MeromorphicOn k Set.univ := fun w _ =>
    (hf.analyticAt w).meromorphicAt.div (hq.analyticAt w).meromorphicAt
  have hko : ∀ w, meromorphicOrderAt k w = 0 := by
    intro w
    rw [hk_def, meromorphicOrderAt_div (hf.analyticAt w).meromorphicAt (hq.analyticAt w).meromorphicAt,
      (hf.analyticAt w).meromorphicOrderAt_eq, (hq.analyticAt w).meromorphicOrderAt_eq, hord w]
    obtain ⟨n, hn⟩ := ENat.ne_top_iff_exists.mp (hntop w)
    rw [← hn]
    simp only [ENat.map_natCast]
    norm_cast; simp
  set h := toMeromorphicNFOn k Set.univ with hh_def
  have hNF : ∀ w, MeromorphicNFAt h w := fun w =>
    meromorphicNFOn_toMeromorphicNFOn k Set.univ (Set.mem_univ w)
  have hho : ∀ w, meromorphicOrderAt h w = 0 := fun w => by
    rw [hh_def, meromorphicOrderAt_toMeromorphicNFOn hkm (Set.mem_univ w), hko w]
  have hha : ∀ w, AnalyticAt ℂ h w := fun w =>
    (hNF w).meromorphicOrderAt_nonneg_iff_analyticAt.mp (by rw [hho w])
  have hh0 : ∀ w, h w ≠ 0 := fun w => (hNF w).meromorphicOrderAt_eq_zero_iff.mp (hho w)
  refine ⟨h, fun w => (hha w).differentiableAt, hh0, fun w => ?_⟩
  -- f and h * q agree on a punctured neighbourhood of w
  have hqne : ∀ᶠ z in 𝓝[≠] w, q z ≠ 0 := by
    rcases (hq.analyticAt w).eventually_eq_zero_or_eventually_ne_zero with h1 | h1
    · exact absurd (analyticOrderAt_eq_top.mpr h1) (by rw [hord w]; exact hntop w)
    · exact h1
  have heq : (fun z => h z * q z) =ᶠ[𝓝[≠] w] f := by
    filter_upwards [hkm.toMeromorphicNFOn_eq_self_on_nhdsNE (Set.mem_univ w), hqne] with z h1 h2
    rw [← hh_def] at h1
    rw [h1, hk_def, Pi.div_apply, div_mul_cancel₀ _ h2]
  have t1 : Tendsto f (𝓝[≠] w) (𝓝 (f w)) :=
    (hf w).continuousAt.tendsto.mono_left nhdsWithin_le_nhds
  have t2 : Tendsto (fun z => h z * q z) (𝓝[≠] w) (𝓝 (h w * q w)) :=
    (((hha w).continuousAt).mul (hq w).continuousAt).tendsto.mono_left nhdsWithin_le_nhds
  exact tendsto_nhds_unique t1 (t2.congr' heq)

#print axioms entire_div_same_order

/-- The fibre of the first projection of a sigma type over a point. -/
def sigmaFiberEquiv {α : Type*} (β : α → Type*) (a0 : α) :
    {i : Σ a, β a // i.1 = a0} ≃ β a0 where
  toFun i := i.2 ▸ i.1.2
  invFun k := ⟨⟨a0, k⟩, rfl⟩
  left_inv := by rintro ⟨⟨a, k⟩, rfl⟩; rfl
  right_inv := fun _ => rfl

lemma gamma_partial_eq (z : ℂ) (N : ℕ) (hN : N ≠ 0) :
    z * Complex.exp (Real.eulerMascheroniConstant * z) *
        ∏ n ∈ range N, elementaryFactor 1 (z / (-((n : ℂ) + 1))) =
      (GammaSeq z N)⁻¹ *
        Complex.exp (z * ((Real.eulerMascheroniConstant : ℂ) -
          (((harmonic N : ℚ) : ℝ) - Real.log N : ℝ))) := by
  have hE : ∀ n : ℕ, elementaryFactor 1 (z / (-((n : ℂ) + 1))) =
      (1 + z / ((n : ℂ) + 1)) * Complex.exp (-(z * ((n : ℂ) + 1)⁻¹)) := by
    intro n
    simp only [elementaryFactor, Finset.Icc_self, Finset.sum_singleton, pow_one, Nat.cast_one,
      div_one]
    simp only [div_neg, sub_neg_eq_add]
    simp only [div_eq_mul_inv]
  simp_rw [hE]
  rw [Finset.prod_mul_distrib, ← Complex.exp_sum, GammaSeq, inv_div, Finset.prod_range_succ',
    cpow_def_of_ne_zero (by exact_mod_cast hN), ← Complex.natCast_log]
  have hfac : ((N.factorial : ℕ) : ℂ) = ∏ n ∈ range N, ((n : ℂ) + 1) := by
    rw [← Finset.prod_range_add_one_eq_factorial]; push_cast; rfl
  have hprod : ∏ n ∈ range N, (z + ((n + 1 : ℕ) : ℂ)) =
      (∏ n ∈ range N, ((n : ℂ) + 1)) * ∏ n ∈ range N, (1 + z / ((n : ℂ) + 1)) := by
    rw [← Finset.prod_mul_distrib]
    refine Finset.prod_congr rfl fun n _ => ?_
    have : (n : ℂ) + 1 ≠ 0 := by exact_mod_cast Nat.succ_ne_zero n
    field_simp; push_cast; ring
  have hsum : ∑ n ∈ range N, -(z * ((n : ℂ) + 1)⁻¹) = -(z * (((harmonic N : ℚ) : ℝ) : ℂ)) := by
    rw [harmonic]; push_cast; rw [Finset.mul_sum, ← Finset.sum_neg_distrib]
  rw [hprod, hfac, hsum]
  have hP : ∏ n ∈ range N, ((n : ℂ) + 1) ≠ 0 :=
    Finset.prod_ne_zero_iff.mpr fun n _ => by exact_mod_cast Nat.succ_ne_zero n
  simp only [Nat.cast_zero, add_zero]
  push_cast
  generalize ((harmonic N : ℚ) : ℂ) = H
  generalize Complex.log (N : ℂ) = L
  generalize (Real.eulerMascheroniConstant : ℂ) = g
  have hx : Complex.exp (z * (g - (H - L))) =
      Complex.exp (g * z) * Complex.exp (-(z * H)) * Complex.exp (L * z) := by
    rw [← Complex.exp_add, ← Complex.exp_add]; ring_nf
  rw [hx]
  have hL : Complex.exp (L * z) ≠ 0 := Complex.exp_ne_zero _
  field_simp

#print axioms gamma_partial_eq

/-- **Weierstrass factorization.** Let f be an entire function (complex-differentiable on the
whole plane) that is not 0 everywhere. Then there are a list of nonzero points a_i, in which each
nonzero zero w of f appears exactly as many times as its order and nothing else appears, degrees
p_i, and an entire function g, such that the product of the elementary factors E_{p_i}(z/a_i)
converges, locally uniformly on the whole plane, to a function P, and
f(z) = e^(g(z)) · z^m · P(z) for every z, where m is the order of the zero of f at 0
(m = 0 when f(0) ≠ 0). -/
theorem weierstrass_factorization (f : ℂ → ℂ) (hf : Differentiable ℂ f) (hne : ∃ z, f z ≠ 0) :
    ∃ (ι : Type) (a : ι → ℂ) (p : ι → ℕ) (P g : ℂ → ℂ),
      (∀ i, a i ≠ 0) ∧
      (∀ w, w ≠ 0 → ENat.card {i // a i = w} = analyticOrderAt f w) ∧
      HasProdLocallyUniformlyOn (fun i z => elementaryFactor (p i) (z / a i)) P Set.univ ∧
      Differentiable ℂ g ∧
      ∀ z, f z = Complex.exp (g z) * z ^ analyticOrderNatAt f 0 * P z := by
  classical
  obtain ⟨z0, hz0⟩ := hne
  have hfa : AnalyticOnNhd ℂ f Set.univ := fun z _ => hf.analyticAt z
  have hntop : ∀ w, analyticOrderAt f w ≠ ⊤ := fun w =>
    hfa.analyticOrderAt_ne_top_of_isPreconnected isPreconnected_univ (Set.mem_univ z0)
      (Set.mem_univ w) (by rw [analyticOrderAt_eq_zero.mpr (Or.inr hz0)]; exact ENat.zero_ne_top)
  have hfin : ∀ R : ℝ, {w : ℂ | f w = 0 ∧ ‖w‖ ≤ R}.Finite := by
    intro R
    have hcod := hfa.preimage_zero_mem_codiscrete hz0
    have := (isCompact_closedBall (0 : ℂ) R).finite_sdiff_of_mem_codiscreteWithin
      (codiscreteWithin_mono (Set.subset_univ _) hcod)
    refine this.subset ?_
    rintro w ⟨h1, h2⟩
    simp [h1, h2]
  set Z := {w : ℂ // w ≠ 0 ∧ f w = 0}
  have hZc : Countable Z := by
    have : {w : ℂ | w ≠ 0 ∧ f w = 0}.Countable := by
      refine (Set.countable_iUnion fun n : ℕ => (hfin n).countable).mono ?_
      rintro w ⟨-, hw⟩
      obtain ⟨n, hn⟩ := exists_nat_ge ‖w‖
      exact Set.mem_iUnion.mpr ⟨n, hw, hn⟩
    exact this.to_subtype
  set ι := Σ w : Z, Fin (analyticOrderNatAt f w.1)
  obtain ⟨e, he⟩ := Countable.exists_injective_nat ι
  set a : ι → ℂ := fun i => i.1.1
  have ha : ∀ i, a i ≠ 0 := fun i => i.1.2.1
  have hs : ∀ R : ℝ, Summable (fun i => (R / ‖a i‖) ^ (e i + 1)) := by
    intro R
    have hZfin : {w : Z | ‖w.1‖ ≤ 2 * |R|}.Finite :=
      ((hfin (2 * |R|)).preimage Subtype.val_injective.injOn).subset fun w hw => ⟨w.2.2, hw⟩
    have hιfin : {i : ι | ‖a i‖ ≤ 2 * |R|}.Finite :=
      (hZfin.preimage' (f := Sigma.fst) fun b _ =>
        (Set.finite_range (Sigma.mk (β := fun w : Z => Fin (analyticOrderNatAt f w.1)) b)).subset
          (by rintro ⟨x, k⟩ (rfl : x = b); exact ⟨k, rfl⟩)).subset fun i hi => hi
    refine Summable.of_norm_bounded_eventually (g := fun i : ι => (1 / 2 : ℝ) ^ (e i + 1))
      ((summable_geometric_of_lt_one (by norm_num) (by norm_num)).comp_injective
        ((add_left_injective 1).comp he)) ?_
    filter_upwards [hιfin.compl_mem_cofinite] with i hi
    simp only [Set.mem_compl_iff, Set.mem_ofPred_eq, not_le] at hi
    have hai : 0 < ‖a i‖ := by linarith [abs_nonneg R]
    rw [norm_pow, Real.norm_eq_abs, abs_div, abs_norm]
    exact pow_le_pow_left₀ (by positivity) (by rw [div_le_iff₀ hai]; linarith) _
  obtain ⟨P, hPprod, hPd, hPord⟩ := core_product a e ha hs
  have hcard : ∀ w, w ≠ 0 → ENat.card {i // a i = w} = analyticOrderAt f w := by
    intro w hw
    by_cases hfw : f w = 0
    · set w' : Z := ⟨w, hw, hfw⟩
      have e1 : {i // a i = w} ≃ {i : ι // i.1 = w'} :=
        Equiv.subtypeEquivRight fun i => by
          simp only [a, w']
          exact ⟨fun h => Subtype.ext h, fun h => congrArg Subtype.val h⟩
      rw [ENat.card_congr (e1.trans (sigmaFiberEquiv _ w')), ENat.card_eq_coe_fintype_card,
        Fintype.card_fin, Nat.cast_analyticOrderNatAt (hntop w)]
    · rw [analyticOrderAt_eq_zero.mpr (Or.inr hfw)]
      have : IsEmpty {i // a i = w} := ⟨fun ⟨i, hi⟩ => hfw (hi ▸ i.1.2.2)⟩
      exact (ENat.card_eq_zero_iff_empty _).mpr this
  set m := analyticOrderNatAt f 0
  set q : ℂ → ℂ := fun z => z ^ m * P z with hq_def
  have hqd : Differentiable ℂ q := (differentiable_id.pow m).mul hPd
  have hord : ∀ w, analyticOrderAt q w = analyticOrderAt f w := by
    intro w
    have hpow : AnalyticAt ℂ (fun z : ℂ => z ^ m) w := (differentiable_id.pow m).analyticAt w
    rw [show q = (fun z : ℂ => z ^ m) * P from rfl, analyticOrderAt_mul hpow (hPd.analyticAt w),
      hPord w]
    by_cases hw : w = 0
    · subst hw
      have h1 : analyticOrderAt (fun z : ℂ => z ^ m) 0 = m := by
        refine (hpow.analyticOrderAt_eq_natCast).mpr ⟨fun _ => 1, analyticAt_const, one_ne_zero,
          Eventually.of_forall fun z => by simp⟩
      have h2 : ENat.card {i // a i = 0} = 0 := by
        have : IsEmpty {i // a i = 0} := ⟨fun ⟨i, hi⟩ => ha i hi⟩
        exact (ENat.card_eq_zero_iff_empty _).mpr this
      rw [h1, h2, add_zero, Nat.cast_analyticOrderNatAt (hntop 0)]
    · have h1 : analyticOrderAt (fun z : ℂ => z ^ m) w = 0 :=
        analyticOrderAt_eq_zero.mpr (Or.inr (pow_ne_zero _ hw))
      rw [h1, zero_add, hcard w hw]
  obtain ⟨h, hhd, hh0, hfh⟩ := entire_div_same_order f q hf hqd hord hntop
  obtain ⟨g, hgd, hg⟩ := entire_exists_log h hhd hh0
  refine ⟨ι, a, e, P, g, ha, hcard, hPprod, hgd, fun z => ?_⟩
  rw [hfh z, hg z, hq_def, mul_assoc]

/-- **Any list of zeros running off to infinity belongs to an entire function.** Let a_0, a_1,
a_2, … be nonzero complex numbers, repeats allowed, with |a_n| → ∞. Then the product of the
elementary factors E_n(z/a_n) (the card's choice p_n = n − 1 when the list starts at n = 1)
converges, locally uniformly on the whole plane, to an entire function P whose zeros are exactly
the a_n: at every point w, the order of the zero of P equals the number of times w appears in the
list. -/
theorem elementary_product_has_prescribed_zeros (a : ℕ → ℂ) (ha : ∀ n, a n ≠ 0)
    (h_inf : Tendsto (fun n => ‖a n‖) atTop atTop) :
    ∃ P : ℂ → ℂ,
      HasProdLocallyUniformlyOn (fun n z => elementaryFactor n (z / a n)) P Set.univ ∧
      Differentiable ℂ P ∧
      ∀ w, analyticOrderAt P w = ENat.card {n // a n = w} := by
  refine core_product a (fun n => n) ha fun R => ?_
  refine Summable.of_norm_bounded_eventually (g := fun n : ℕ => (1 / 2 : ℝ) ^ (n + 1))
    ((summable_geometric_of_lt_one (by norm_num) (by norm_num)).comp_injective
      (add_left_injective 1)) ?_
  rw [Nat.cofinite_eq_atTop]
  filter_upwards [tendsto_atTop.mp h_inf (2 * |R| + 1)] with n hn
  have hai : 0 < ‖a n‖ := by linarith [abs_nonneg R]
  rw [norm_pow, Real.norm_eq_abs, abs_div, abs_norm]
  exact pow_le_pow_left₀ (by positivity) (by rw [div_le_iff₀ hai]; linarith) _

/-- **The card's example: the zeros −1, −2, −3, … give 1/Γ.** For every complex z, the partial
products z · e^(γz) · E_1(z/(−1)) · E_1(z/(−2)) ⋯ E_1(z/(−N)), where
E_1(z/(−n)) = (1 + z/n)e^(−z/n) and γ is Euler's constant, tend to 1/Γ(z) as N grows. -/
theorem one_div_gamma_eq_weierstrass_product (z : ℂ) :
    Tendsto (fun N => z * Complex.exp (Real.eulerMascheroniConstant * z) *
        ∏ n ∈ range N, elementaryFactor 1 (z / (-((n : ℂ) + 1))))
      atTop (𝓝 (Complex.Gamma z)⁻¹) := by
  have hE : Tendsto (fun N : ℕ => Complex.exp (z * ((Real.eulerMascheroniConstant : ℂ) -
          (((harmonic N : ℚ) : ℝ) - Real.log N : ℝ)))) atTop (𝓝 1) := by
    have h1 : Tendsto (fun N : ℕ => (((harmonic N : ℚ) : ℝ) - Real.log N : ℝ)) atTop
        (𝓝 Real.eulerMascheroniConstant) := Real.tendsto_harmonic_sub_log
    have h2 := ((Complex.continuous_ofReal.tendsto _).comp h1)
    have h3 : Tendsto (fun N : ℕ => z * ((Real.eulerMascheroniConstant : ℂ) -
          (((harmonic N : ℚ) : ℝ) - Real.log N : ℝ))) atTop (𝓝 (z * (Real.eulerMascheroniConstant - Real.eulerMascheroniConstant : ℂ))) :=
      tendsto_const_nhds.mul (tendsto_const_nhds.sub h2)
    have h4 := (Complex.continuous_exp.tendsto _).comp h3
    simp only [sub_self, mul_zero, Complex.exp_zero] at h4
    exact h4
  have hG : Tendsto (fun N => (GammaSeq z N)⁻¹) atTop (𝓝 (Complex.Gamma z)⁻¹) := by
    by_cases hz : ∃ m : ℕ, z = -m
    · obtain ⟨m, rfl⟩ := hz
      rw [Complex.Gamma_neg_nat_eq_zero, inv_zero]
      refine tendsto_const_nhds.congr' ?_
      filter_upwards [eventually_ge_atTop m] with N hN
      rw [GammaSeq, Finset.prod_eq_zero (i := m) (by simp; omega) (by simp), div_zero, inv_zero]
    · push Not at hz
      exact (GammaSeq_tendsto_Gamma z).inv₀ (Complex.Gamma_ne_zero hz)
  have := hG.mul hE
  rw [mul_one] at this
  refine this.congr' ?_
  filter_upwards [eventually_ne_atTop 0] with N hN
  exact (gamma_partial_eq z N hN).symm

-- Plain factors 1 + 1/n at z = 1 telescope to N + 1: 11 and 101 after 10 and 100 factors.
example : ∏ n ∈ range 10, (1 + 1 / ((n : ℚ) + 1)) = 11 := by
  norm_num [Finset.prod_range_succ]
example : ∏ n ∈ range 100, (1 + 1 / ((n : ℚ) + 1)) = 101 := by
  norm_num [Finset.prod_range_succ]
-- The first corrected factor at z = 1 is E_1(−1) = 2e^(−1), the card's 0.735759.
example : elementaryFactor 1 (-1) = 2 * Complex.exp (-1) := by
  norm_num [elementaryFactor]
-- Each elementary factor is zero at w = 1.
example (p : ℕ) : elementaryFactor p 1 = 0 := by
  simp [elementaryFactor]
-- Step 5: pairing the factors for the zeros n and −n cancels the exponentials.
example (z : ℂ) (n : ℕ) :
    elementaryFactor 1 (z / n) * elementaryFactor 1 (z / (-(n : ℂ))) = 1 - z ^ 2 / (n : ℂ) ^ 2 := by
  simp only [elementaryFactor, Finset.Icc_self, Finset.sum_singleton, pow_one, Nat.cast_one, div_one]
  rw [mul_mul_mul_comm, ← Complex.exp_add, div_neg, add_neg_cancel, Complex.exp_zero, mul_one]
  ring

#print axioms weierstrass_factorization
#print axioms elementary_product_has_prescribed_zeros
#print axioms one_div_gamma_eq_weierstrass_product
