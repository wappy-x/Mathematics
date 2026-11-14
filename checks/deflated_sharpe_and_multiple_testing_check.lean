-- Trying many strategies: the best of M independent bell-curve draws is at most z with chance exactly N(z)^M, and when no strategy has skill the in-sample winner lands in the bottom half out of sample with chance exactly one half.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Probability.Independence.Basic
import Mathlib.Data.Finset.Lattice.Fold
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory

theorem rank_card_half {M : ℕ} (y : Fin M → ℝ) (hy : Function.Injective y) :
    (Finset.univ.filter
      (fun k => (Finset.univ.filter (fun j => y j < y k)).card < M / 2)).card = M / 2 := by
  classical
  set f : Fin M → ℕ := fun k => (Finset.univ.filter (fun j => y j < y k)).card with hf
  have hlt : ∀ k, f k < M := by
    intro k
    have : (Finset.univ.filter (fun j => y j < y k)) ⊂ Finset.univ :=
      Finset.filter_ssubset.mpr ⟨k, Finset.mem_univ _, lt_irrefl _⟩
    simpa [f] using Finset.card_lt_card this
  have hmono : ∀ a b, y a < y b → f a < f b := by
    intro a b hab
    apply Finset.card_lt_card
    rw [Finset.ssubset_iff_of_subset]
    · exact ⟨a, by simp [hab], by simp⟩
    · intro j hj
      simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hj ⊢
      exact hj.trans hab
  have hinj : Function.Injective (fun k => (⟨f k, hlt k⟩ : Fin M)) := by
    intro a b h
    simp only [Fin.mk.injEq] at h
    by_contra hne
    rcases lt_or_gt_of_ne (hy.ne hne) with h1 | h1
    · have := hmono _ _ h1; omega
    · have := hmono _ _ h1; omega
  have hbij := (Finite.injective_iff_bijective).mp hinj
  rw [Finset.card_equiv (Equiv.ofBijective _ hbij)
    (t := Finset.univ.filter (fun m : Fin M => (m : ℕ) < M / 2)) (by simp [f]),
    Fin.card_filter_val_lt]
  omega

#print axioms rank_card_half

theorem null_tie_of_indep {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (U V : Ω → ℝ) (hU : Measurable U) (hV : Measurable V) (hind : IndepFun U V μ)
    (ν : Measure ℝ) [NullSingletonClass ν] (hUlaw : μ.map U = ν) :
    μ {ω | U ω = V ω} = 0 := by
  have : IsFiniteMeasure ν := hUlaw ▸ inferInstance
  have hpair := (indepFun_iff_map_prod_eq_prod_map_map hU.aemeasurable hV.aemeasurable).mp hind
  have hset : {ω | U ω = V ω} = (fun ω => (U ω, V ω)) ⁻¹' Set.diagonal ℝ := rfl
  rw [hset, ← Measure.map_apply (hU.prodMk hV) measurableSet_diagonal, hpair, hUlaw,
    Measure.prod_apply_symm measurableSet_diagonal]
  have : ∀ y : ℝ, (fun x => (x, y)) ⁻¹' Set.diagonal ℝ = {y} := by
    intro y; ext x; simp
  simp [this]

theorem rank_set_measurable {M : ℕ} (k : Fin M) :
    MeasurableSet {y : Fin M → ℝ | (Finset.univ.filter (fun j => y j < y k)).card < M / 2} := by
  classical
  have : Measurable (fun y : Fin M → ℝ => (Finset.univ.filter (fun j => y j < y k)).card) := by
    simp_rw [Finset.card_filter]
    refine Finset.measurable_sum _ (fun j _ => ?_)
    exact Measurable.ite (measurableSet_lt (measurable_pi_apply j) (measurable_pi_apply k))
      measurable_const measurable_const
  exact this (measurableSet_Iio (a := M / 2))

theorem rank_set_symm {M : ℕ} (ν : Measure ℝ) [SigmaFinite ν] (k k0 : Fin M) :
    Measure.pi (fun _ : Fin M => ν)
        {y : Fin M → ℝ | (Finset.univ.filter (fun j => y j < y k)).card < M / 2}
      = Measure.pi (fun _ : Fin M => ν)
        {y : Fin M → ℝ | (Finset.univ.filter (fun j => y j < y k0)).card < M / 2} := by
  classical
  have hmp := measurePreserving_piCongrLeft (fun _ : Fin M => ν) (Equiv.swap k k0)
  rw [← hmp.measure_preimage (rank_set_measurable k0).nullMeasurableSet]
  congr 1
  ext y
  simp only [Set.mem_preimage, Set.mem_ofPred_eq, MeasurableEquiv.coe_piCongrLeft]
  have h : ∀ j, (Equiv.piCongrLeft (fun _ => ℝ) (Equiv.swap k k0)) y j = y (Equiv.swap k k0 j) := by
    intro j; rw [Equiv.piCongrLeft_apply_eq_cast]; simp
  simp_rw [h, Equiv.swap_apply_right]
  have hc : (Finset.univ.filter (fun j => y (Equiv.swap k k0 j) < y k)).card
      = (Finset.univ.filter (fun j => y j < y k)).card :=
    Finset.card_equiv (Equiv.swap k k0) (by simp)
  rw [hc]

#print axioms null_tie_of_indep
#print axioms rank_set_measurable
#print axioms rank_set_symm

/-- The maximum law. Let `Z 1, ..., Z M` (with `M ≥ 1`) be independent no-skill Sharpe ratios,
each divided by its width, so each is a standard bell-curve draw. The best of them is at most `z`
with chance exactly `N(z)^M`, where `N` is the standard bell-curve distribution function. -/
theorem prob_best_of_M_at_most_eq_cdf_pow
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (M : ℕ) (hM : 0 < M)
    (Z : Fin M → Ω → ℝ) (hmeas : ∀ j, Measurable (Z j)) (hind : iIndepFun Z μ)
    (hnormal : ∀ j, μ.map (Z j) = gaussianReal 0 1) (z : ℝ) :
    μ.real {ω | Finset.univ.sup' (Finset.univ_nonempty_iff.mpr ⟨⟨0, hM⟩⟩) (fun j => Z j ω) ≤ z}
      = (cdf (gaussianReal 0 1) z) ^ M := by
  have hset : {ω | Finset.univ.sup' (Finset.univ_nonempty_iff.mpr ⟨⟨0, hM⟩⟩) (fun j => Z j ω) ≤ z}
      = ⋂ j, Z j ⁻¹' Set.Iic z := by
    ext ω; simp [Finset.sup'_le_iff]
  rw [hset, measureReal_def, hind.meas_iInter (fun j => ⟨Set.Iic z, measurableSet_Iic, rfl⟩),
    ENNReal.toReal_prod]
  have h : ∀ j, (μ (Z j ⁻¹' Set.Iic z)).toReal = cdf (gaussianReal 0 1) z := by
    intro j
    rw [cdf_eq_real, ← hnormal j, measureReal_def, Measure.map_apply (hmeas j) measurableSet_Iic]
  simp [h]

/-- Pure noise gives a probability of backtest overfitting of one half. Take `M` strategies
(`M` even). `X j` is strategy j's in-sample score and `Y j` its out-of-sample score; the two halves
use different days, so the in-sample scores are independent of the out-of-sample ones. With no
skill, the out-of-sample scores are independent with one common distribution `ν`, which puts no
weight on any single value (no ties). The in-sample winner `g (X 1, ..., X M)` depends only on the
in-sample scores. Then the winner's out-of-sample rank (1 = worst) is `M / 2` or worse with chance
exactly one half. -/
theorem pbo_eq_half_of_no_skill
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (M : ℕ) (hM : 0 < M) (hEven : Even M)
    (X Y : Fin M → Ω → ℝ) (hX : ∀ j, Measurable (X j)) (hY : ∀ j, Measurable (Y j))
    (hXY : IndepFun (fun ω j => X j ω) (fun ω j => Y j ω) μ)
    (hYind : iIndepFun Y μ) (ν : Measure ℝ) [NullSingletonClass ν] (hYlaw : ∀ j, μ.map (Y j) = ν)
    (g : (Fin M → ℝ) → Fin M) (hg : Measurable g) :
    μ.real {ω | (Finset.univ.filter
        (fun j => Y j ω < Y (g (fun i => X i ω)) ω)).card + 1 ≤ M / 2} = 1 / 2 := by
  classical
  have hνprob : IsProbabilityMeasure ν := by
    rw [← hYlaw ⟨0, hM⟩]; infer_instance
  set Yv : Ω → (Fin M → ℝ) := fun ω j => Y j ω with hYv_def
  set Xv : Ω → (Fin M → ℝ) := fun ω j => X j ω with hXv_def
  have hYv : Measurable Yv := measurable_pi_iff.mpr hY
  have hXv : Measurable Xv := measurable_pi_iff.mpr hX
  set A : Fin M → Set (Fin M → ℝ) :=
    fun k => {y | (Finset.univ.filter (fun j => y j < y k)).card < M / 2} with hA_def
  have hA : ∀ k, MeasurableSet (A k) := rank_set_measurable
  have hlaw : μ.map Yv = Measure.pi (fun _ : Fin M => ν) := by
    rw [(iIndepFun_iff_map_fun_eq_pi_map (fun i => (hY i).aemeasurable)).mp hYind]
    simp_rw [hYlaw]
  have hpre : ∀ k, μ (Yv ⁻¹' A k) = Measure.pi (fun _ : Fin M => ν) (A k) := by
    intro k; rw [← hlaw, Measure.map_apply hYv (hA k)]
  have hinj : ∀ᵐ ω ∂μ, Function.Injective (Yv ω) := by
    have h1 : ∀ i j : Fin M, ∀ᵐ ω ∂μ, Y i ω = Y j ω → i = j := by
      intro i j
      by_cases hij : i = j
      · exact Filter.Eventually.of_forall (fun _ _ => hij)
      · have h0 := null_tie_of_indep μ (Y i) (Y j) (hY i) (hY j) (hYind.indepFun hij) ν (hYlaw i)
        rw [ae_iff]; simpa [hij] using h0
    have h2 : ∀ᵐ ω ∂μ, ∀ i j : Fin M, Y i ω = Y j ω → i = j := by
      rw [ae_all_iff]; intro i; rw [ae_all_iff]; exact h1 i
    filter_upwards [h2] with ω hω i j hij using hω i j hij
  have hsum : ∑ k, μ (Yv ⁻¹' A k) = ((M / 2 : ℕ) : ENNReal) := by
    simp_rw [← lintegral_indicator_one (hYv (hA _))]
    rw [← lintegral_finsetSum _ (fun k _ => (measurable_one.indicator (hYv (hA k))))]
    have hae : (fun ω => ∑ k, (Yv ⁻¹' A k).indicator 1 ω)
        =ᵐ[μ] (fun _ => ((M / 2 : ℕ) : ENNReal)) := by
      filter_upwards [hinj] with ω hω
      simp only [Set.indicator_apply, Pi.one_apply, Set.mem_preimage, Finset.sum_boole]
      congr 1
      exact rank_card_half (Yv ω) hω
    rw [lintegral_congr_ae hae, lintegral_const, measure_univ, mul_one]
  have hsym : ∀ k, μ (Yv ⁻¹' A k) = μ (Yv ⁻¹' A ⟨0, hM⟩) := by
    intro k; rw [hpre, hpre]; exact rank_set_symm ν k ⟨0, hM⟩
  have hhalf : ∀ k, μ.real (Yv ⁻¹' A k) = 1 / 2 := by
    intro k
    rw [measureReal_def, hsym k]
    simp_rw [hsym] at hsum
    rw [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul] at hsum
    have hr := congrArg ENNReal.toReal hsum
    rw [ENNReal.toReal_mul] at hr
    obtain ⟨m, rfl⟩ := hEven
    have hm : (m + m) / 2 = m := by omega
    rw [hm] at hr
    rw [ENNReal.toReal_natCast, ENNReal.toReal_natCast] at hr
    push_cast at hr
    have hm0 : (0 : ℝ) < m := by exact_mod_cast (show 0 < m by omega)
    field_simp
    nlinarith
  have hE : {ω | (Finset.univ.filter
        (fun j => Y j ω < Y (g (fun i => X i ω)) ω)).card + 1 ≤ M / 2}
      = ⋃ k, (Xv ⁻¹' (g ⁻¹' {k}) ∩ Yv ⁻¹' A k) := by
    ext ω
    simp [A, Xv, Yv]
  have hdisj : Pairwise (Function.onFun Disjoint fun k : Fin M => Xv ⁻¹' (g ⁻¹' {k})) := by
    intro a b hab
    exact Set.disjoint_left.mpr (fun ω h1 h2 => hab (h1.symm.trans h2))
  rw [hE, measureReal_iUnion_fintype
    (fun a b hab => (hdisj hab).mono Set.inter_subset_left Set.inter_subset_left)
    (fun k => (hXv (hg (measurableSet_singleton k))).inter (hYv (hA k)))]
  have hmul : ∀ k, μ.real (Xv ⁻¹' (g ⁻¹' {k}) ∩ Yv ⁻¹' A k)
      = μ.real (Xv ⁻¹' (g ⁻¹' {k})) * (1 / 2) := by
    intro k
    rw [← hhalf k, measureReal_def, measureReal_def, measureReal_def,
      hXY.measure_inter_preimage_eq_mul _ _ (hg (measurableSet_singleton k)) (hA k),
      ENNReal.toReal_mul]
  simp_rw [hmul]
  rw [← Finset.sum_mul, ← measureReal_iUnion_fintype hdisj
    (fun k => hXv (hg (measurableSet_singleton k)))]
  have hU : (⋃ k, Xv ⁻¹' (g ⁻¹' {k})) = Set.univ := by
    ext ω; simp
  rw [hU]; simp

/-- CSCV splits: 6 blocks give 20 ways to choose the in-sample half; 4 blocks give 6. -/
example : Nat.choose 6 3 = 20 := by decide
example : Nat.choose 4 2 = 6 := by decide

/-- CSCV by hand: rules A to D with block profits (8, 8, -2, -2), (2, 2, 2, 2), (-2, -2, 8, 8),
(1, 1, 1, 1); in-sample halves {1,2}, {3,4}, {1,3}, {1,4}, {2,3}, {2,4}; ties go to the earlier
rule; rank 1 is worst. The winners' out-of-sample ranks are 1, 1, 4, 4, 4, 4. -/
example :
    let cols : List (List ℤ) := [[8, 8, -2, -2], [2, 2, 2, 2], [-2, -2, 8, 8], [1, 1, 1, 1]]
    let mean : ℕ → List ℕ → ℤ := fun j S => (S.map (fun b => (cols.getD j []).getD b 0)).sum / 2
    let other : List ℕ → List ℕ := fun S => [0, 1, 2, 3].filter (fun b => b ∉ S)
    let pick : List ℕ → ℕ := fun S =>
      [1, 2, 3].foldl (fun best j => if mean best S < mean j S then j else best) 0
    let rank : List ℕ → ℕ := fun S =>
      1 + ([0, 1, 2, 3].filter (fun j => decide (mean j (other S) < mean (pick S) (other S) ∨
        (mean j (other S) = mean (pick S) (other S) ∧ pick S < j)))).length
    [[0, 1], [2, 3], [0, 2], [0, 3], [1, 2], [1, 3]].map rank = [1, 1, 4, 4, 4, 4] := by
  decide

/-- The hand PBO: two of the six ranks are 2 or worse, so PBO = 2/6 = 1/3. -/
example : (([1, 1, 4, 4, 4, 4] : List ℕ).filter (· ≤ 4 / 2)).length = 2 := by decide
example : ((2 : ℚ) / Nat.choose 4 2) = 1 / 3 := by norm_num [Nat.choose]

#print axioms prob_best_of_M_at_most_eq_cdf_pow
#print axioms pbo_eq_half_of_no_skill
