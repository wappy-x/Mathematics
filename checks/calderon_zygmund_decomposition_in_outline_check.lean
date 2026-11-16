-- Calderon-Zygmund decomposition: every integrable function on the line has disjoint dyadic boxes with averages between the level and twice it, total length at most the total over the level, the function at most the level a.e. outside them, and a good part and bad part with the card's bounds.
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.MeasureTheory.Covering.DensityTheorem
import Mathlib.MeasureTheory.Measure.Lebesgue.EqHaar

open MeasureTheory

namespace CalderonZygmund

/-- The dyadic interval `[m 2^n, (m+1) 2^n)` named by the pair `p = (m, n)` of whole numbers. -/
noncomputable def dyadic (p : ℤ × ℤ) : Set ℝ :=
  Set.Ico ((p.1 : ℝ) * (2 : ℝ) ^ p.2) (((p.1 : ℝ) + 1) * (2 : ℝ) ^ p.2)

lemma dyadic_meas (p : ℤ × ℤ) : MeasurableSet (dyadic p) := measurableSet_Ico

#print axioms dyadic_meas

lemma volume_dyadic (p : ℤ × ℤ) : volume (dyadic p) = ENNReal.ofReal ((2 : ℝ) ^ p.2) := by
  rw [dyadic, Real.volume_Ico]; congr 1; ring

#print axioms volume_dyadic

lemma pairwise_sub (S : Set (ℤ × ℤ)) (hS : S.PairwiseDisjoint dyadic) :
    Pairwise (Function.onFun Disjoint fun p : S => dyadic p) :=
  fun a b hab => hS a.2 b.2 (fun h => hab (Subtype.ext h))

#print axioms pairwise_sub

lemma union_meas (S : Set (ℤ × ℤ)) : MeasurableSet (⋃ p ∈ S, dyadic p) :=
  MeasurableSet.biUnion S.to_countable (fun p _ => dyadic_meas p)

#print axioms union_meas

lemma lintegral_split (S : Set (ℤ × ℤ)) (hS : S.PairwiseDisjoint dyadic) (φ : ℝ → ENNReal) :
    ∫⁻ x, φ x = (∫⁻ x in (⋃ p ∈ S, dyadic p)ᶜ, φ x) + ∑' p : S, ∫⁻ x in dyadic p, φ x := by
  have hU : (⋃ p : S, dyadic p) = ⋃ p ∈ S, dyadic p := by ext x; simp
  rw [← lintegral_iUnion (fun p => dyadic_meas _) (pairwise_sub S hS), hU]
  exact (lintegral_add_compl _ (union_meas S)).symm.trans (add_comm _ _)

#print axioms lintegral_split

lemma tsum_le (S : Set (ℤ × ℤ)) (hS : S.PairwiseDisjoint dyadic) (φ : ℝ → ENNReal) :
    ∑' p : S, ∫⁻ x in dyadic p, φ x ≤ ∫⁻ x, φ x := by
  rw [lintegral_split S hS φ]
  exact le_add_self

#print axioms tsum_le

lemma ofReal_setIntegral_abs (f : ℝ → ℝ) (hf : Integrable f) (s : Set ℝ) :
    ENNReal.ofReal (∫ x in s, |f x|) = ∫⁻ x in s, ‖f x‖ₑ := by
  rw [← ofReal_integral_norm_eq_lintegral_enorm hf.integrableOn]; rfl

#print axioms ofReal_setIntegral_abs

lemma ofReal_integral_abs (f : ℝ → ℝ) (hf : Integrable f) :
    ENNReal.ofReal (∫ x, |f x|) = ∫⁻ x, ‖f x‖ₑ := by
  rw [← ofReal_integral_norm_eq_lintegral_enorm hf]; rfl

#print axioms ofReal_integral_abs

/-- The parent of a dyadic interval: the dyadic interval twice as long that contains it. -/
def parent (p : ℤ × ℤ) : ℤ × ℤ := (p.1 / 2, p.2 + 1)

#print axioms parent

lemma dyadic_subset_parent (p : ℤ × ℤ) : dyadic p ⊆ dyadic (parent p) := by
  intro x hx
  obtain ⟨m, n⟩ := p
  simp only [dyadic, parent, Set.mem_Ico] at hx ⊢
  have h1 : (m / 2) * 2 ≤ m := by omega
  have h2 : m + 1 ≤ (m / 2 + 1) * 2 := by omega
  have h1' : ((m / 2 : ℤ) : ℝ) * 2 ≤ m := by exact_mod_cast h1
  have h2' : (m : ℝ) + 1 ≤ (((m / 2 : ℤ) : ℝ) + 1) * 2 := by exact_mod_cast h2
  have hpos : (0 : ℝ) < 2 ^ n := by positivity
  rw [zpow_add_one₀ two_ne_zero]
  constructor <;> nlinarith

#print axioms dyadic_subset_parent

lemma iterate_parent_snd (k : ℕ) (p : ℤ × ℤ) : (parent^[k] p).2 = p.2 + k := by
  induction k with
  | zero => simp
  | succ k ih => rw [Function.iterate_succ_apply', parent]; simp only [ih]; push_cast; ring

#print axioms iterate_parent_snd

lemma dyadic_subset_iterate (k : ℕ) (p : ℤ × ℤ) : dyadic p ⊆ dyadic (parent^[k] p) := by
  induction k with
  | zero => simp
  | succ k ih => rw [Function.iterate_succ_apply']; exact ih.trans (dyadic_subset_parent _)

#print axioms dyadic_subset_iterate

lemma mem_dyadic_iff (x : ℝ) (p : ℤ × ℤ) : x ∈ dyadic p ↔ p.1 = ⌊x / 2 ^ p.2⌋ := by
  have hpos : (0 : ℝ) < 2 ^ p.2 := by positivity
  simp only [dyadic, Set.mem_Ico]
  rw [eq_comm, Int.floor_eq_iff, le_div_iff₀ hpos, div_lt_iff₀ hpos]

#print axioms mem_dyadic_iff

lemma eq_of_mem_of_snd (x : ℝ) (p q : ℤ × ℤ) (hp : x ∈ dyadic p) (hq : x ∈ dyadic q)
    (h : p.2 = q.2) : p = q := by
  rw [mem_dyadic_iff] at hp hq
  exact Prod.ext (by rw [hp, hq, h]) h

#print axioms eq_of_mem_of_snd

lemma eq_iterate_of_mem (x : ℝ) (p q : ℤ × ℤ) (hp : x ∈ dyadic p) (hq : x ∈ dyadic q)
    (hle : p.2 ≤ q.2) : q = parent^[(q.2 - p.2).toNat] p :=
  eq_of_mem_of_snd x q _ hq (dyadic_subset_iterate _ _ hp)
    (by rw [iterate_parent_snd]; omega)

#print axioms eq_iterate_of_mem

/-- The Calderón-Zygmund decomposition on the line. For every `f` in `L¹(ℝ)` and every level
`α > 0` there are dyadic intervals `Q_k`, no two overlapping, such that each `Q_k` has an
average of `|f|` above `α` and at most `2α`, their lengths add up to at most `‖f‖₁ / α`, and
`|f| ≤ α` at almost every point outside every `Q_k`. -/
theorem calderon_zygmund_decomposition (f : ℝ → ℝ) (hf : Integrable f) (α : ℝ) (hα : 0 < α) :
    ∃ S : Set (ℤ × ℤ), S.PairwiseDisjoint dyadic ∧
      (∀ p ∈ S, α < ((2 : ℝ) ^ p.2)⁻¹ * ∫ x in dyadic p, |f x| ∧
                ((2 : ℝ) ^ p.2)⁻¹ * ∫ x in dyadic p, |f x| ≤ 2 * α) ∧
      ∑' p : S, volume (dyadic p) ≤ ENNReal.ofReal ((∫ x, |f x|) / α) ∧
      ∀ᵐ x ∂volume, x ∉ ⋃ p ∈ S, dyadic p → |f x| ≤ α := by
  set A : ℤ × ℤ → ℝ := fun p => ((2 : ℝ) ^ p.2)⁻¹ * ∫ x in dyadic p, |f x| with hAdef
  have hA_parent : ∀ p, A p ≤ 2 * A (parent p) := by
    intro p
    have hI : ∫ x in dyadic p, |f x| ≤ ∫ x in dyadic (parent p), |f x| :=
      setIntegral_mono_set hf.abs.integrableOn (Filter.Eventually.of_forall (fun x => abs_nonneg _))
        (dyadic_subset_parent p).eventuallyLE
    have hpos : (0 : ℝ) < 2 ^ p.2 := by positivity
    have hsnd : (parent p).2 = p.2 + 1 := rfl
    have e : 2 * A (parent p) = ((2 : ℝ) ^ p.2)⁻¹ * ∫ x in dyadic (parent p), |f x| := by
      simp only [hAdef]
      rw [hsnd, zpow_add_one₀ two_ne_zero, mul_inv]; ring
    rw [e]
    exact mul_le_mul_of_nonneg_left hI (by positivity)
  have hA_bound : ∀ p, A p ≤ ((2 : ℝ) ^ p.2)⁻¹ * ∫ x, |f x| := fun p =>
    mul_le_mul_of_nonneg_left (setIntegral_le_integral hf.abs
      (Filter.Eventually.of_forall (fun x => abs_nonneg _))) (by positivity)
  have hA_small : ∀ p, ∃ K : ℕ, ∀ k, K ≤ k → A (parent^[k] p) ≤ α := by
    intro p
    obtain ⟨K, hK⟩ := pow_unbounded_of_one_lt ((∫ x, |f x|) / α / 2 ^ p.2) (one_lt_two : (1 : ℝ) < 2)
    refine ⟨K, fun k hk => (hA_bound _).trans ?_⟩
    have hpos : (0 : ℝ) < 2 ^ p.2 := by positivity
    have hk2 : (2 : ℝ) ^ K ≤ 2 ^ k := pow_le_pow_right₀ one_le_two hk
    rw [iterate_parent_snd, zpow_add₀ two_ne_zero, zpow_natCast, inv_mul_le_iff₀ (by positivity)]
    rw [div_lt_iff₀ hpos, div_lt_iff₀ hα] at hK
    have : (2 : ℝ) ^ K * (2 ^ p.2 * α) ≤ 2 ^ k * (2 ^ p.2 * α) :=
      mul_le_mul_of_nonneg_right hk2 (by positivity)
    nlinarith
  set S : Set (ℤ × ℤ) := {p | α < A p ∧ ∀ k : ℕ, 1 ≤ k → A (parent^[k] p) ≤ α} with hSdef
  have hmax : ∀ p, α < A p → ∃ q ∈ S, dyadic p ⊆ dyadic q := by
    intro p hp
    obtain ⟨K, hK⟩ := hA_small p
    classical
    set k0 := Nat.findGreatest (fun k => α < A (parent^[k] p)) K with hk0def
    have hk0 : α < A (parent^[k0] p) := Nat.findGreatest_spec (P := fun k => α < A (parent^[k] p))
      (Nat.zero_le K) (by simpa using hp)
    refine ⟨parent^[k0] p, ⟨hk0, fun j hj => ?_⟩, dyadic_subset_iterate _ _⟩
    rw [← Function.iterate_add_apply]
    by_cases hjK : j + k0 ≤ K
    · exact not_lt.mp (Nat.findGreatest_is_greatest (P := fun k => α < A (parent^[k] p))
        (by omega) hjK)
    · exact hK _ (by omega)
  have key : ∀ p ∈ S, ∀ q ∈ S, ∀ x, x ∈ dyadic p → x ∈ dyadic q → p.2 ≤ q.2 → p = q := by
    intro p hp q hq x hxp hxq hle
    have hq' := eq_iterate_of_mem x p q hxp hxq hle
    by_cases hk : (q.2 - p.2).toNat = 0
    · rw [hk] at hq'; exact hq'.symm
    · have h1 := hp.2 _ (Nat.one_le_iff_ne_zero.mpr hk)
      rw [← hq'] at h1
      exact absurd hq.1 (not_lt.mpr h1)
  have hS : S.PairwiseDisjoint dyadic := by
    intro p hp q hq hpq
    rw [Function.onFun, Set.disjoint_left]
    intro x hxp hxq
    rcases le_total p.2 q.2 with h | h
    · exact hpq (key p hp q hq x hxp hxq h)
    · exact hpq (key q hq p hp x hxq hxp h).symm
  refine ⟨S, hS, fun p hp => ⟨hp.1, ?_⟩, ?_, ?_⟩
  · have h1 := hA_parent p
    have h2 := hp.2 1 le_rfl
    simp only [Function.iterate_one] at h2
    change A p ≤ 2 * α
    linarith
  · have hvol : ∀ p : S, volume (dyadic p) ≤
        ENNReal.ofReal α⁻¹ * ∫⁻ x in dyadic p, ‖f x‖ₑ := by
      intro p
      have hp := p.2.1
      have hpos : (0 : ℝ) < 2 ^ (p : ℤ × ℤ).2 := by positivity
      have h1 : (2 : ℝ) ^ (p : ℤ × ℤ).2 * α < ∫ x in dyadic p, |f x| := by
        have := mul_lt_mul_of_pos_left hp hpos
        simp only [hAdef] at this
        rwa [← mul_assoc, mul_inv_cancel₀ hpos.ne', one_mul] at this
      have h2 : (2 : ℝ) ^ (p : ℤ × ℤ).2 ≤ α⁻¹ * ∫ x in dyadic p, |f x| := by
        rw [inv_mul_eq_div, le_div_iff₀ hα]; exact h1.le
      rw [volume_dyadic, ← ofReal_setIntegral_abs f hf, ← ENNReal.ofReal_mul (inv_nonneg.mpr hα.le)]
      exact ENNReal.ofReal_le_ofReal h2
    calc _ ≤ ∑' p : S, ENNReal.ofReal α⁻¹ * ∫⁻ x in dyadic p, ‖f x‖ₑ := tsum_le_tsum hvol
      _ = ENNReal.ofReal α⁻¹ * ∑' p : S, ∫⁻ x in dyadic p, ‖f x‖ₑ := ENNReal.tsum_mul_left
      _ ≤ ENNReal.ofReal α⁻¹ * ∫⁻ x, ‖f x‖ₑ := by gcongr; exact tsum_le S hS _
      _ = ENNReal.ofReal ((∫ x, |f x|) / α) := by
        rw [← ofReal_integral_abs f hf, ← ENNReal.ofReal_mul (inv_nonneg.mpr hα.le), div_eq_inv_mul]
  · have hdiff := IsUnifLocDoublingMeasure.ae_tendsto_average (μ := volume) (f := fun y => |f y|)
      hf.abs.locallyIntegrable 1
    filter_upwards [hdiff] with x hx hxU
    have hle : ∀ p, x ∈ dyadic p → A p ≤ α := by
      intro p hxp
      by_contra h
      push Not at h
      obtain ⟨q, hq, hsub⟩ := hmax p h
      exact hxU (Set.mem_iUnion₂.mpr ⟨q, hq, hsub hxp⟩)
    let n : ℕ → ℤ := fun j => -(j : ℤ)
    let m : ℕ → ℤ := fun j => ⌊x / 2 ^ (n j)⌋
    have hball : ∀ j, Metric.closedBall (((m j : ℝ) + 1 / 2) * 2 ^ (n j)) ((2 : ℝ) ^ (n j) / 2) =
        Set.Icc ((m j : ℝ) * 2 ^ (n j)) (((m j : ℝ) + 1) * 2 ^ (n j)) := by
      intro j; rw [Real.closedBall_eq_Icc]; congr 1 <;> ring
    have hmem : ∀ j, x ∈ dyadic (m j, n j) := fun j => (mem_dyadic_iff x _).mpr rfl
    have havg : ∀ j, ⨍ y in Metric.closedBall (((m j : ℝ) + 1 / 2) * 2 ^ (n j))
        ((2 : ℝ) ^ (n j) / 2), |f y| = A (m j, n j) := by
      intro j
      have hpos : (0 : ℝ) < 2 ^ (n j) := by positivity
      rw [hball, setAverage_eq, smul_eq_mul, Real.volume_real_Icc_of_le (by nlinarith),
        setIntegral_congr_set Ico_ae_eq_Icc.symm]
      simp only [hAdef, dyadic]
      congr 2; ring
    have δlim : Filter.Tendsto (fun j : ℕ => (2 : ℝ) ^ (n j) / 2) Filter.atTop (nhdsWithin 0 (Set.Ioi 0)) := by
      rw [tendsto_nhdsWithin_iff]
      constructor
      · have : (fun j : ℕ => (2 : ℝ) ^ (n j) / 2) = fun j => (1 / 2 : ℝ) ^ j / 2 := by
          funext j; simp [n, zpow_neg, zpow_natCast, inv_pow]
        rw [this]
        simpa using (tendsto_pow_atTop_nhds_zero_of_lt_one (by norm_num)
          (by norm_num : (1 / 2 : ℝ) < 1)).div_const 2
      · exact Filter.Eventually.of_forall (fun j => by simp only [Set.mem_Ioi]; positivity)
    have xmem : ∀ᶠ j in Filter.atTop, x ∈ Metric.closedBall (((m j : ℝ) + 1 / 2) * 2 ^ (n j))
        (1 * ((2 : ℝ) ^ (n j) / 2)) :=
      Filter.Eventually.of_forall (fun j => by rw [one_mul, hball]; exact Set.Ico_subset_Icc_self (hmem j))
    have ht := hx (fun j => ((m j : ℝ) + 1 / 2) * 2 ^ (n j)) (fun j => (2 : ℝ) ^ (n j) / 2)
      δlim xmem
    exact le_of_tendsto' ht (fun j => by rw [havg]; exact hle _ (hmem j))

/-- The good part. Given disjoint dyadic boxes from the decomposition (averages of `|f|` at most
`2α`, and `|f| ≤ α` a.e. outside them), the function `g` that equals `f` outside the boxes and
the box's average `f_Q` on each box is integrable, at most `2α` a.e., has total at most `‖f‖₁`,
and has energy `‖g‖₂²` at most `2α ‖f‖₁`. -/
theorem good_part_bounds (f : ℝ → ℝ) (hf : Integrable f) (α : ℝ) (hα : 0 < α)
    (S : Set (ℤ × ℤ)) (hS : S.PairwiseDisjoint dyadic)
    (hupper : ∀ p ∈ S, ((2 : ℝ) ^ p.2)⁻¹ * ∫ x in dyadic p, |f x| ≤ 2 * α)
    (hout : ∀ᵐ x ∂volume, x ∉ ⋃ p ∈ S, dyadic p → |f x| ≤ α)
    (g : ℝ → ℝ)
    (hg_in : ∀ p ∈ S, ∀ x ∈ dyadic p, g x = ((2 : ℝ) ^ p.2)⁻¹ * ∫ y in dyadic p, f y)
    (hg_out : ∀ x, x ∉ ⋃ p ∈ S, dyadic p → g x = f x) :
    Integrable g ∧ (∀ᵐ x ∂volume, |g x| ≤ 2 * α) ∧ ∫ x, |g x| ≤ ∫ x, |f x| ∧
      Integrable (fun x => g x ^ 2) ∧ ∫ x, g x ^ 2 ≤ 2 * α * ∫ x, |f x| := by
  have hmeas : AEStronglyMeasurable g volume := by
    rw [← Measure.restrict_add_restrict_compl (μ := volume) (union_meas S)]
    refine AEStronglyMeasurable.add_measure ?_ ?_
    · have hU' : (⋃ p ∈ S, dyadic p) = ⋃ p : S, dyadic p := by ext x; simp
      rw [hU', aestronglyMeasurable_iUnion_iff]
      intro p
      refine (aestronglyMeasurable_const
        (b := ((2 : ℝ) ^ (p : ℤ × ℤ).2)⁻¹ * ∫ y in dyadic p, f y)).congr ?_
      filter_upwards [ae_restrict_mem (dyadic_meas p)] with x hx
      exact (hg_in p p.2 x hx).symm
    · refine hf.aestronglyMeasurable.restrict.congr ?_
      filter_upwards [ae_restrict_mem (union_meas S).compl] with x hx
      exact (hg_out x hx).symm
  have hle : ∫⁻ x, ‖g x‖ₑ ≤ ∫⁻ x, ‖f x‖ₑ := by
    rw [lintegral_split S hS (fun x => ‖g x‖ₑ), lintegral_split S hS (fun x => ‖f x‖ₑ)]
    refine add_le_add (le_of_eq (setLIntegral_congr_fun (union_meas S).compl
        (fun x hx => by simp only [hg_out x hx]))) (tsum_le_tsum (fun p => ?_))
    rw [setLIntegral_congr_fun (dyadic_meas p)
        (g := fun _ => ‖((2 : ℝ) ^ (p : ℤ × ℤ).2)⁻¹ * ∫ y in dyadic p, f y‖ₑ)
        (fun x hx => by simp only [hg_in p p.2 x hx]),
      setLIntegral_const, volume_dyadic, ← Real.enorm_eq_ofReal (by positivity), ← enorm_mul]
    have : (2 : ℝ) ^ (p : ℤ × ℤ).2 ≠ 0 := by positivity
    rw [mul_comm, ← mul_assoc, mul_inv_cancel₀ this, one_mul]
    exact enorm_integral_le_lintegral_enorm _
  have hfin : ∫⁻ x, ‖f x‖ₑ < ⊤ := hasFiniteIntegral_iff_enorm.mp hf.2
  have hg : Integrable g := ⟨hmeas, hasFiniteIntegral_iff_enorm.mpr (lt_of_le_of_lt hle hfin)⟩
  have hbound : ∀ᵐ x ∂volume, |g x| ≤ 2 * α := by
    filter_upwards [hout] with x hx
    by_cases hxU : x ∈ ⋃ p ∈ S, dyadic p
    · obtain ⟨p, hp, hxp⟩ := Set.mem_iUnion₂.mp hxU
      rw [hg_in p hp x hxp]
      have hpos : (0 : ℝ) < 2 ^ p.2 := by positivity
      rw [abs_mul, abs_inv, abs_of_pos hpos]
      exact le_trans (mul_le_mul_of_nonneg_left abs_integral_le_integral_abs (by positivity))
        (hupper p hp)
    · rw [hg_out x hxU]; linarith [hx hxU]
  have habs : ∫ x, |g x| ≤ ∫ x, |f x| := by
    have h1 := integral_norm_eq_lintegral_enorm hmeas
    have h2 := integral_norm_eq_lintegral_enorm hf.aestronglyMeasurable
    simp only [Real.norm_eq_abs] at h1 h2
    rw [h1, h2]
    exact ENNReal.toReal_mono hfin.ne hle
  have hsq : ∀ᵐ x ∂volume, g x ^ 2 ≤ 2 * α * |g x| := by
    filter_upwards [hbound] with x hx
    rw [← sq_abs]; nlinarith [abs_nonneg (g x)]
  have hsqint : Integrable (fun x => g x ^ 2) := by
    refine Integrable.mono' (hg.abs.const_mul (2 * α)) (hmeas.pow 2) ?_
    filter_upwards [hsq] with x hx
    rw [Real.norm_eq_abs, abs_of_nonneg (sq_nonneg _)]; exact hx
  refine ⟨hg, hbound, habs, hsqint, ?_⟩
  calc ∫ x, g x ^ 2 ≤ ∫ x, 2 * α * |g x| := integral_mono_ae hsqint (hg.abs.const_mul _) hsq
    _ = 2 * α * ∫ x, |g x| := integral_const_mul _ _
    _ ≤ 2 * α * ∫ x, |f x| := mul_le_mul_of_nonneg_left habs (by positivity)

/-- The bad part. On disjoint dyadic boxes, each bad piece `b_k = (f - f_{Q_k}) 1_{Q_k}` adds up
to zero over its box, and the sizes `‖b_k‖₁` add up to at most `2 ‖f‖₁`. -/
theorem bad_part_bounds (f : ℝ → ℝ) (hf : Integrable f)
    (S : Set (ℤ × ℤ)) (hS : S.PairwiseDisjoint dyadic) :
    (∀ p ∈ S, ∫ x in dyadic p, (f x - ((2 : ℝ) ^ p.2)⁻¹ * ∫ y in dyadic p, f y) = 0) ∧
      ∑' p : S, ENNReal.ofReal
          (∫ x in dyadic p, |f x - ((2 : ℝ) ^ (p : ℤ × ℤ).2)⁻¹ * ∫ y in dyadic p, f y|)
        ≤ ENNReal.ofReal (2 * ∫ x, |f x|) := by
  have hvol : ∀ p, volume (dyadic p) ≠ ⊤ := by simp [volume_dyadic]
  have hreal : ∀ p, volume.real (dyadic p) = (2 : ℝ) ^ p.2 := by
    intro p; rw [measureReal_def, volume_dyadic, ENNReal.toReal_ofReal (by positivity)]
  refine ⟨fun p _ => ?_, ?_⟩
  · rw [integral_sub hf.integrableOn (integrableOn_const (hvol p)), setIntegral_const, smul_eq_mul,
      hreal]
    have : (2 : ℝ) ^ p.2 ≠ 0 := by positivity
    field_simp; ring
  · have key : ∀ p : ℤ × ℤ, ENNReal.ofReal
        (∫ x in dyadic p, |f x - ((2 : ℝ) ^ p.2)⁻¹ * ∫ y in dyadic p, f y|) ≤
        2 * ∫⁻ x in dyadic p, ‖f x‖ₑ := by
      intro p
      set c := ((2 : ℝ) ^ p.2)⁻¹ * ∫ y in dyadic p, f y
      have hpos : (0 : ℝ) < 2 ^ p.2 := by positivity
      have hc : |c| ≤ ((2 : ℝ) ^ p.2)⁻¹ * ∫ y in dyadic p, |f y| := by
        rw [abs_mul, abs_inv, abs_of_pos hpos]
        exact mul_le_mul_of_nonneg_left (abs_integral_le_integral_abs) (by positivity)
      have h1 : ∫ x in dyadic p, |f x - c| ≤ ∫ x in dyadic p, (|f x| + |c|) := by
        apply integral_mono_of_nonneg
        · exact Filter.Eventually.of_forall (fun x => abs_nonneg _)
        · exact hf.integrableOn.abs.add (integrableOn_const (hvol p))
        · exact Filter.Eventually.of_forall (fun x => abs_sub _ _)
      rw [integral_add hf.integrableOn.abs (integrableOn_const (hvol p)), setIntegral_const,
        smul_eq_mul, hreal] at h1
      have h2 : (2 : ℝ) ^ p.2 * |c| ≤ ∫ y in dyadic p, |f y| := by
        calc (2 : ℝ) ^ p.2 * |c| ≤ 2 ^ p.2 * (((2 : ℝ) ^ p.2)⁻¹ * ∫ y in dyadic p, |f y|) :=
              mul_le_mul_of_nonneg_left hc hpos.le
          _ = ∫ y in dyadic p, |f y| := by field_simp
      rw [← ofReal_setIntegral_abs f hf, ← ENNReal.ofReal_ofNat 2, ← ENNReal.ofReal_mul (by norm_num)]
      exact ENNReal.ofReal_le_ofReal (by linarith)
    calc _ ≤ ∑' p : S, 2 * ∫⁻ x in dyadic p, ‖f x‖ₑ := tsum_le_tsum (fun p => key p)
      _ = 2 * ∑' p : S, ∫⁻ x in dyadic p, ‖f x‖ₑ := ENNReal.tsum_mul_left
      _ ≤ 2 * ∫⁻ x, ‖f x‖ₑ := by gcongr; exact tsum_le S hS _
      _ = ENNReal.ofReal (2 * ∫ x, |f x|) := by
        rw [ENNReal.ofReal_mul (by norm_num), ENNReal.ofReal_ofNat, ofReal_integral_abs f hf]

/-! The card's rainfall record: 32 days of whole millimetres, level 10 mm a day. -/

/-- Rain on days 0 to 31, in mm. -/
def rain : List ℕ :=
  [0, 2, 0, 14, 4, 0, 1, 0, 3, 0, 0, 25, 30, 2, 0, 0,
   0, 0, 6, 8, 9, 7, 0, 0, 0, 0, 0, 0, 0, 48, 0, 0]

/-- Rain in mm over the `n` days starting on day `a`. -/
def boxSum (a n : ℕ) : ℕ := ((rain.drop a).take n).sum

-- The whole record: 159 mm over 32 days, not above 10 mm a day, so the halving can start.
example : boxSum 0 32 = 159 ∧ boxSum 0 32 ≤ 10 * 32 := by decide

-- The four stopped boxes [3,4), [10,12), [12,14), [28,32): each averages above 10 and at most 20.
example : 10 * 1 < boxSum 3 1 ∧ boxSum 3 1 ≤ 20 * 1 := by decide
example : 10 * 2 < boxSum 10 2 ∧ boxSum 10 2 ≤ 20 * 2 := by decide
example : 10 * 2 < boxSum 12 2 ∧ boxSum 12 2 ≤ 20 * 2 := by decide
example : 10 * 4 < boxSum 28 4 ∧ boxSum 28 4 ≤ 20 * 4 := by decide

-- Their parents [2,4), [8,12), [12,16), [24,32) are not above 10, so they were halved.
example : boxSum 2 2 ≤ 10 * 2 ∧ boxSum 8 4 ≤ 10 * 4 ∧ boxSum 12 4 ≤ 10 * 4 ∧
    boxSum 24 8 ≤ 10 * 8 := by decide

-- [12,14) averages exactly 16, twice its parent's 8: the bound reached.
example : boxSum 12 2 = 2 * 16 ∧ boxSum 12 4 = 4 * 8 := by decide

-- Total length 9 days: 9 × 10 < 119 mm of rain in the boxes ≤ 159 mm in all.
example : boxSum 3 1 + boxSum 10 2 + boxSum 12 2 + boxSum 28 4 = 119 ∧
    (1 + 2 + 2 + 4) * 10 < 119 ∧ 119 ≤ 159 := by decide

-- Outside the boxes, every day has at most 10 mm.
example : ∀ d < 32, ¬ (d = 3 ∨ (10 ≤ d ∧ d < 14) ∨ 28 ≤ d) → rain.getD d 0 ≤ 10 := by decide

-- The bad part on [28,32): 0 − 12, 48 − 12, 0 − 12, 0 − 12 adds up to zero; its size is 72.
example : ((0 : ℤ) - 12) + (48 - 12) + (0 - 12) + (0 - 12) = 0 ∧
    |(0 : ℤ) - 12| + |(48 : ℤ) - 12| + |(0 : ℤ) - 12| + |(0 : ℤ) - 12| = 72 := by decide

-- Size of the bad part, by box 0, 25, 28 and 72: 125 mm, under 2 × 119 = 238.
example : (0 + 25 + 28 + 72 : ℕ) = 125 ∧ 125 ≤ 2 * 119 := by decide

#print axioms calderon_zygmund_decomposition
#print axioms good_part_bounds
#print axioms bad_part_bounds

end CalderonZygmund
