-- Dirichlet's theorem: the Fourier partial sums of a piecewise smooth 2π-periodic signal tend at every point to the midpoint of its left and right values, a continuous signal with summable coefficient sizes is matched to within the tail of those sizes at every point at once, and two signals that agree near a point have partial sums there whose difference tends to 0.
import Mathlib.Analysis.Fourier.AddCircle
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Topology.UniformSpace.UniformConvergence
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Fourier.RiemannLebesgueLemma
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open Real Filter Topology Finset

/-- The cycle runs from −π to π. -/
lemma cycle_neg_pi_lt_pi : -π < π := by linarith [Real.pi_pos]

/-- The card's coefficient `f̂(n) = (1/2π) ∫_{−π}^{π} f(x) e^{−inx} dx` of a real signal f,
as Mathlib's `fourierCoeffOn` over the cycle [−π, π]. -/
noncomputable def coeff (f : ℝ → ℝ) (n : ℤ) : ℂ :=
  fourierCoeffOn cycle_neg_pi_lt_pi (fun t => (f t : ℂ)) n

/-- The card's partial sum `S_N f(x) = ∑_{n=−N}^{N} f̂(n) e^{inx}`. -/
noncomputable def partialSum (f : ℝ → ℝ) (N : ℕ) (x : ℝ) : ℂ :=
  ∑ n ∈ Icc (-(N : ℤ)) N, coeff f n * Complex.exp (n * x * Complex.I)

open MeasureTheory

lemma coeff_eq_integral_shift (f : ℝ → ℝ) (hper : Function.Periodic f (2 * π)) (n : ℤ) (x : ℝ) :
    coeff f n = (1 / (2 * π) : ℂ) * ∫ t in (x - π)..(x + π),
      Complex.exp (-(n * t * Complex.I)) * (f t : ℂ) := by
  unfold coeff
  rw [fourierCoeffOn_eq_integral]
  have key : ∀ t : ℝ, fourier (-n) (t : AddCircle (π - -π)) • ((f t : ℂ)) =
      Complex.exp (-(n * t * Complex.I)) * (f t : ℂ) := by
    intro t
    rw [fourier_coe_apply, smul_eq_mul]
    congr 2
    have : (π : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
    push_cast
    field_simp
    ring
  simp_rw [key]
  have hp : Function.Periodic (fun t : ℝ => Complex.exp (-(n * t * Complex.I)) * (f t : ℂ))
      (2 * π) := by
    intro t
    simp only
    rw [hper t]
    congr 1
    rw [show -((n : ℂ) * ((t + 2 * π : ℝ) : ℂ) * Complex.I) =
      -(n * t * Complex.I) + ((-n : ℤ) : ℂ) * (2 * π * Complex.I) by push_cast; ring]
    rw [Complex.exp_add, Complex.exp_int_mul_two_pi_mul_I, mul_one]
  have h1 := hp.intervalIntegral_add_eq (-π) (x - π)
  rw [show -π + 2 * π = π by ring, show x - π + 2 * π = x + π by ring] at h1
  rw [h1, show π - -π = 2 * π by ring, Complex.real_smul]
  push_cast
  ring

lemma rl_seq (F : ℝ → ℂ) (a b : ℝ) (hab : a ≤ b) (u : ℕ → ℝ)
    (hu : Tendsto u atTop (Filter.cocompact ℝ)) :
    Tendsto (fun N => ∫ t in a..b, Complex.exp (-(u N * t * Complex.I)) * F t) atTop (𝓝 0) := by
  have hcc : Tendsto (fun N => u N / (2 * π)) atTop (Filter.cocompact ℝ) := by
    have hm : Tendsto (fun w : ℝ => w / (2 * π)) (Filter.cocompact ℝ) (Filter.cocompact ℝ) := by
      have := (Homeomorph.mulRight₀ (1 / (2 * π)) (by positivity)).toCocompactMap.cocompact_tendsto'
      convert this using 1
      ext w
      simp [div_eq_mul_inv]
    exact hm.comp hu
  have h := (Real.tendsto_integral_exp_smul_cocompact ((Set.Ioc a b).indicator F)).comp hcc
  refine h.congr' (Eventually.of_forall fun N => ?_)
  simp only [Function.comp]
  rw [intervalIntegral.integral_of_le hab, ← integral_indicator measurableSet_Ioc]
  congr 1
  ext v
  by_cases hv : v ∈ Set.Ioc a b
  · rw [Set.indicator_of_mem hv, Set.indicator_of_mem hv, Circle.smul_def,
      Real.fourierChar_apply, smul_eq_mul]
    congr 2
    have : (π : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
    push_cast
    field_simp
  · simp [Set.indicator_of_notMem hv]

lemma norm_one_sub_exp_ge (u : ℝ) (hu : |u| ≤ π) :
    2 / π * |u| ≤ ‖1 - Complex.exp (u * Complex.I)‖ := by
  rw [norm_sub_rev, mul_comm (u : ℂ), Complex.norm_exp_I_mul_ofReal_sub_one, Real.norm_eq_abs,
    abs_mul, abs_two]
  rcases le_total 0 u with h | h
  · rw [abs_of_nonneg h] at hu ⊢
    have := Real.mul_le_sin (x := u / 2) (by linarith) (by linarith)
    have h0 : 0 ≤ 2 / π * (u / 2) := by positivity
    rw [abs_of_nonneg (by linarith)]
    have : 2 / π * u = 2 * (2 / π * (u / 2)) := by ring
    linarith
  · rw [abs_of_nonpos h] at hu ⊢
    have h1 := Real.mul_le_sin (x := -u / 2) (by linarith) (by linarith)
    have h0 : 0 ≤ 2 / π * (-u / 2) := by
      apply mul_nonneg (by positivity); linarith
    rw [show -u / 2 = -(u / 2) by ring, Real.sin_neg] at h1
    rw [abs_of_nonpos (by linarith)]
    have : 2 / π * -u = 2 * (2 / π * -(u / 2)) := by ring
    linarith

lemma sum_Icc_telescope (A : ℤ → ℂ) (N : ℕ) :
    ∑ n ∈ Icc (-(N : ℤ)) N, (A n - A (n - 1)) = A N - A (-(N : ℤ) - 1) := by
  induction N with
  | zero => simp
  | succ k ih =>
    have hs : Icc (-((k + 1 : ℕ) : ℤ)) ((k + 1 : ℕ) : ℤ) =
        insert (-((k + 1 : ℕ) : ℤ)) (insert ((k + 1 : ℕ) : ℤ) (Icc (-(k : ℤ)) k)) := by
      ext n; simp only [mem_Icc, mem_insert]; push_cast; omega
    rw [hs, sum_insert (by simp only [mem_insert, mem_Icc]; push_cast; omega),
      sum_insert (by simp only [mem_Icc]; push_cast; omega), ih]
    have e1 : ((k : ℤ) + 1 - 1) = k := by ring
    have e2 : -(k : ℤ) - 1 = -((k : ℤ) + 1) := by ring
    push_cast
    rw [e1, e2]
    ring

lemma partialSum_sub_tendsto_of_dini (f g : ℝ → ℝ) (hfper : Function.Periodic f (2 * π))
    (hgper : Function.Periodic g (2 * π)) (x : ℝ)
    (hf : IntervalIntegrable f volume (x - π) (x + π))
    (hg : IntervalIntegrable g volume (x - π) (x + π))
    (ε K : ℝ) (hε : 0 < ε) (hK : 0 ≤ K)
    (hnear : ∀ t, t ≠ x → |t - x| < ε → |f t - g t| ≤ K * |t - x|) :
    Tendsto (fun N : ℕ => partialSum f N x - partialSum g N x) atTop (𝓝 0) := by
  have hab : x - π ≤ x + π := by linarith [Real.pi_pos]
  set h : ℝ → ℂ := fun t => ((f t - g t : ℝ) : ℂ) with hh_def
  set d : ℝ → ℂ := fun t => 1 - Complex.exp (((t - x : ℝ) : ℂ) * Complex.I) with hd_def
  set φ : ℝ → ℂ := fun t => h t / d t with hφ_def
  have hfC : IntervalIntegrable (fun t => (f t : ℂ)) volume (x - π) (x + π) :=
    ⟨hf.1.ofReal, hf.2.ofReal⟩
  have hgC : IntervalIntegrable (fun t => (g t : ℂ)) volume (x - π) (x + π) :=
    ⟨hg.1.ofReal, hg.2.ofReal⟩
  have hhI : IntervalIntegrable h volume (x - π) (x + π) := by
    have := hfC.sub hgC
    simpa [hh_def] using this
  have hdge : ∀ t ∈ Set.uIcc (x - π) (x + π), 2 / π * |t - x| ≤ ‖d t‖ := by
    intro t ht
    rw [Set.uIcc_of_le hab] at ht
    exact norm_one_sub_exp_ge (t - x) (abs_le.2 ⟨by linarith [ht.1], by linarith [ht.2]⟩)
  have hdne : ∀ t ∈ Set.uIcc (x - π) (x + π), t ≠ x → d t ≠ 0 := by
    intro t ht htx hd0
    have h1 := hdge t ht
    rw [hd0, norm_zero] at h1
    have : 0 < |t - x| := abs_pos.2 (sub_ne_zero.2 htx)
    have : 0 < 2 / π * |t - x| := by positivity
    linarith
  have hφI : IntervalIntegrable φ volume (x - π) (x + π) := by
    refine IntervalIntegrable.mono_fun' (g := fun t => π / (2 * ε) * ‖h t‖ + K * π / 2)
      ((hhI.norm.const_mul _).add intervalIntegrable_const) ?_ ?_
    · have hm : Measurable fun t => (d t)⁻¹ := by
        apply Measurable.inv
        simp only [hd_def]
        fun_prop
      have := (hhI.def'.aestronglyMeasurable).mul hm.aestronglyMeasurable
      convert this using 1
      ext t
      simp [hφ_def, div_eq_mul_inv]
    · refine (ae_restrict_iff' measurableSet_uIoc).2 (Eventually.of_forall fun t ht => ?_)
      have ht' : t ∈ Set.uIcc (x - π) (x + π) := Set.uIoc_subset_uIcc ht
      have hB : 0 ≤ π / (2 * ε) * ‖h t‖ := by positivity
      have hC : 0 ≤ K * π / 2 := by positivity
      simp only [hφ_def]
      by_cases htx : t = x
      · subst htx
        simp only [hd_def, sub_self, Complex.ofReal_zero, zero_mul, Complex.exp_zero, div_zero,
          norm_zero]
        linarith
      have hpos : 0 < |t - x| := abs_pos.2 (sub_ne_zero.2 htx)
      have hd := hdge t ht'
      rw [norm_div]
      by_cases hc : |t - x| < ε
      · have hn : ‖h t‖ ≤ K * |t - x| := by
          simp only [hh_def, Complex.norm_real, Real.norm_eq_abs]; exact hnear t htx hc
        calc ‖h t‖ / ‖d t‖ ≤ K * |t - x| / (2 / π * |t - x|) := by
              apply div_le_div₀ (by positivity) hn (by positivity) hd
          _ = K * π / 2 := by field_simp
          _ ≤ _ := by linarith
      · replace hc := not_lt.1 hc
        calc ‖h t‖ / ‖d t‖ ≤ ‖h t‖ / (2 / π * ε) := by
              apply div_le_div_of_nonneg_left (norm_nonneg _) (by positivity)
              calc 2 / π * ε ≤ 2 / π * |t - x| := by gcongr
                _ ≤ ‖d t‖ := hd
          _ = π / (2 * ε) * ‖h t‖ := by field_simp
          _ ≤ _ := by linarith
  set A : ℤ → ℂ := fun n => (∫ t in (x - π)..(x + π),
      Complex.exp (-(n * t * Complex.I)) * φ t) * Complex.exp (n * x * Complex.I) with hA_def
  have hint : ∀ n : ℤ, IntervalIntegrable (fun t => Complex.exp (-(n * t * Complex.I)) * φ t)
      volume (x - π) (x + π) := fun n => hφI.continuousOn_mul (by fun_prop)
  have hterm : ∀ n : ℤ, (coeff f n - coeff g n) * Complex.exp (n * x * Complex.I) =
      (1 / (2 * π) : ℂ) * (A n - A (n - 1)) := by
    intro n
    rw [coeff_eq_integral_shift f hfper n x, coeff_eq_integral_shift g hgper n x, ← mul_sub,
      ← intervalIntegral.integral_sub (hfC.continuousOn_mul (by fun_prop))
        (hgC.continuousOn_mul (by fun_prop))]
    have hcongr : ∫ t in (x - π)..(x + π), (Complex.exp (-(n * t * Complex.I)) * (f t : ℂ) -
        Complex.exp (-(n * t * Complex.I)) * (g t : ℂ)) =
        ∫ t in (x - π)..(x + π), (Complex.exp (-(n * t * Complex.I)) * φ t -
          Complex.exp (-(x * Complex.I)) *
            (Complex.exp (-(((n - 1 : ℤ) : ℂ) * t * Complex.I)) * φ t)) := by
      apply intervalIntegral.integral_congr_ae
      filter_upwards [Measure.ae_ne volume x] with t htx ht
      have ht' : t ∈ Set.uIcc (x - π) (x + π) := Set.uIoc_subset_uIcc ht
      have hd0 := hdne t ht' htx
      have hφd : φ t * (1 - Complex.exp (((t - x : ℝ) : ℂ) * Complex.I)) = (f t : ℂ) - g t := by
        simp only [hφ_def, hh_def]
        rw [div_mul_cancel₀ _ hd0]
        push_cast; ring
      have hexp : Complex.exp (-(n * t * Complex.I)) * Complex.exp (((t - x : ℝ) : ℂ) * Complex.I)
          = Complex.exp (-(x * Complex.I)) * Complex.exp (-(((n - 1 : ℤ) : ℂ) * t * Complex.I)) := by
        rw [← Complex.exp_add, ← Complex.exp_add]
        congr 1
        push_cast
        ring
      linear_combination (-Complex.exp (-(n * t * Complex.I))) * hφd + (-φ t) * hexp
    rw [hcongr, intervalIntegral.integral_sub (hint n) ((hint (n - 1)).const_mul _),
      intervalIntegral.integral_const_mul]
    have hexp2 : Complex.exp (-(x * Complex.I)) * Complex.exp (n * x * Complex.I) =
        Complex.exp (((n - 1 : ℤ) : ℂ) * x * Complex.I) := by
      rw [← Complex.exp_add]
      congr 1
      push_cast
      ring
    simp only [hA_def]
    linear_combination (-(1 / (2 * π) : ℂ) * ∫ t in (x - π)..(x + π),
      Complex.exp (-(((n - 1 : ℤ) : ℂ) * t * Complex.I)) * φ t) * hexp2
  have hsum : ∀ N : ℕ, partialSum f N x - partialSum g N x =
      (1 / (2 * π) : ℂ) * (A N - A (-(N : ℤ) - 1)) := by
    intro N
    unfold partialSum
    rw [← sum_sub_distrib]
    simp_rw [← sub_mul, hterm]
    rw [← mul_sum, sum_Icc_telescope]
  have hA0 : ∀ u : ℕ → ℤ, Tendsto (fun N => ((u N : ℤ) : ℝ)) atTop (Filter.cocompact ℝ) →
      Tendsto (fun N => A (u N)) atTop (𝓝 0) := by
    intro u hu
    have h1 := rl_seq φ _ _ hab (fun N => ((u N : ℤ) : ℝ)) hu
    have h2 := tendsto_zero_iff_norm_tendsto_zero.1 h1
    refine tendsto_zero_iff_norm_tendsto_zero.2 (h2.congr fun N => ?_)
    simp only [hA_def, norm_mul, Complex.ofReal_intCast]
    rw [show ((u N : ℤ) : ℂ) * (x : ℂ) * Complex.I = (((u N : ℝ) * x : ℝ) : ℂ) * Complex.I by
      push_cast; ring, Complex.norm_exp_ofReal_mul_I, mul_one]
  have hT1 : Tendsto (fun N : ℕ => A N) atTop (𝓝 0) := by
    apply hA0 (fun N => (N : ℤ))
    simp only [Int.cast_natCast]
    exact tendsto_natCast_atTop_atTop.mono_right atTop_le_cocompact
  have hT2 : Tendsto (fun N : ℕ => A (-(N : ℤ) - 1)) atTop (𝓝 0) := by
    apply hA0 (fun N => -(N : ℤ) - 1)
    push_cast
    refine Tendsto.mono_right ?_ atBot_le_cocompact
    exact tendsto_atBot_add_const_right _ _
      (tendsto_neg_atTop_atBot.comp tendsto_natCast_atTop_atTop)
  have := (tendsto_const_nhds (x := (1 / (2 * π) : ℂ))).mul (hT1.sub hT2)
  simp only [sub_zero, mul_zero] at this
  exact this.congr fun N => (hsum N).symm

lemma ii_two_pieces (F : ℝ → ℝ) (p q r c₁ c₂ : ℝ) (hpq : p ≤ q) (hqr : q ≤ r)
    (h1 : Set.EqOn F (fun _ => c₁) (Set.Ioo p q)) (h2 : Set.EqOn F (fun _ => c₂) (Set.Ioo q r)) :
    IntervalIntegrable F volume p r :=
  ((intervalIntegrable_const (c := c₁)).congr_uIoo (by rw [Set.uIoo_of_le hpq]; exact h1.symm)).trans
    ((intervalIntegrable_const (c := c₂)).congr_uIoo (by rw [Set.uIoo_of_le hqr]; exact h2.symm))

lemma intervalIntegrable_of_pieces (f : ℝ → ℝ) (hper : Function.Periodic f (2 * π))
    (hpieces : ∃ (m : ℕ) (a : Fin (m + 1) → ℝ), StrictMono a ∧ a (Fin.last m) = a 0 + 2 * π ∧
      ∀ i : Fin m, ∃ g : ℝ → ℝ, ContDiff ℝ 1 g ∧ Set.EqOn f g (Set.Ioo (a i.castSucc) (a i.succ)))
    (u v : ℝ) : IntervalIntegrable f volume u v := by
  obtain ⟨m, a, hmono, hlast, hg⟩ := hpieces
  let b : ℕ → ℝ := fun k => a ⟨min k m, by omega⟩
  have hb0 : b 0 = a 0 := by
    show a _ = a _; congr 1
  have hbm : b m = a (Fin.last m) := by
    show a _ = a _; congr 1; ext; simp
  have hint : IntervalIntegrable f volume (b 0) (b m) := by
    apply IntervalIntegrable.trans_iterate
    intro k hk
    obtain ⟨g, hgc, hgeq⟩ := hg ⟨k, hk⟩
    have e1 : b k = a (Fin.castSucc ⟨k, hk⟩) := by
      show a _ = a _; congr 1; ext; simp; try omega
    have e2 : b (k + 1) = a (Fin.succ ⟨k, hk⟩) := by
      show a _ = a _; congr 1; ext; simp; try omega
    rw [e1, e2]
    have hle : a (Fin.castSucc ⟨k, hk⟩) ≤ a (Fin.succ ⟨k, hk⟩) :=
      (hmono Fin.castSucc_lt_succ).le
    refine (hgc.continuous.intervalIntegrable _ _).congr_uIoo ?_
    rw [Set.uIoo_of_le hle]
    exact hgeq.symm
  rw [hb0, hbm, hlast] at hint
  exact hper.intervalIntegrable (by positivity) hint u v

lemma local_right (f : ℝ → ℝ) (hper : Function.Periodic f (2 * π))
    (hpieces : ∃ (m : ℕ) (a : Fin (m + 1) → ℝ), StrictMono a ∧ a (Fin.last m) = a 0 + 2 * π ∧
      ∀ i : Fin m, ∃ g : ℝ → ℝ, ContDiff ℝ 1 g ∧ Set.EqOn f g (Set.Ioo (a i.castSucc) (a i.succ)))
    (x : ℝ) : ∃ G : ℝ → ℝ, ContDiff ℝ 1 G ∧ ∃ ε > 0, ∀ t ∈ Set.Ioo x (x + ε), f t = G t := by
  obtain ⟨m, a, hmono, hlast, hg⟩ := hpieces
  have hp : (0 : ℝ) < 2 * π := by positivity
  have hymem : toIcoMod hp (a 0) x ∈ Set.Ico (a 0) (a 0 + 2 * π) := toIcoMod_mem_Ico hp (a 0) x
  have hxy := toIcoMod_add_toIcoDiv_zsmul hp (a 0) x
  set y := toIcoMod hp (a 0) x
  set k := toIcoDiv hp (a 0) x
  let S := Finset.univ.filter (fun j : Fin (m + 1) => a j ≤ y)
  have hS : S.Nonempty := ⟨0, by simp only [S, Finset.mem_filter, Finset.mem_univ, true_and]; exact hymem.1⟩
  have hjS : a (S.max' hS) ≤ y := by
    have := S.max'_mem hS
    simp only [S, Finset.mem_filter, Finset.mem_univ, true_and] at this
    exact this
  have hjne : S.max' hS ≠ Fin.last m := by
    intro h; rw [h, hlast] at hjS; linarith [hymem.2]
  set i := (S.max' hS).castPred hjne
  have hji : i.castSucc = S.max' hS := Fin.castSucc_castPred _ hjne
  have hsucc : y < a i.succ := by
    by_contra hc
    have hmem : i.succ ∈ S := by
      simp only [S, Finset.mem_filter, Finset.mem_univ, true_and]; exact not_lt.1 hc
    have h1 := S.le_max' _ hmem
    rw [← hji] at h1
    exact absurd h1 (not_le.2 Fin.castSucc_lt_succ)
  obtain ⟨g, hgc, hgeq⟩ := hg i
  refine ⟨fun t => g (t - k • (2 * π)), hgc.comp (contDiff_id.sub contDiff_const),
    a i.succ - y, by linarith, ?_⟩
  intro t ht
  rw [← hper.sub_zsmul_eq k]
  apply hgeq
  rw [hji]
  constructor <;> linarith [ht.1, ht.2]

lemma local_left (f : ℝ → ℝ) (hper : Function.Periodic f (2 * π))
    (hpieces : ∃ (m : ℕ) (a : Fin (m + 1) → ℝ), StrictMono a ∧ a (Fin.last m) = a 0 + 2 * π ∧
      ∀ i : Fin m, ∃ g : ℝ → ℝ, ContDiff ℝ 1 g ∧ Set.EqOn f g (Set.Ioo (a i.castSucc) (a i.succ)))
    (x : ℝ) : ∃ G : ℝ → ℝ, ContDiff ℝ 1 G ∧ ∃ ε > 0, ∀ t ∈ Set.Ioo (x - ε) x, f t = G t := by
  obtain ⟨m, a, hmono, hlast, hg⟩ := hpieces
  have hp : (0 : ℝ) < 2 * π := by positivity
  have hymem : toIocMod hp (a 0) x ∈ Set.Ioc (a 0) (a 0 + 2 * π) := toIocMod_mem_Ioc hp (a 0) x
  have hxy := toIocMod_add_toIocDiv_zsmul hp (a 0) x
  set y := toIocMod hp (a 0) x
  set k := toIocDiv hp (a 0) x
  let S := Finset.univ.filter (fun j : Fin (m + 1) => a j < y)
  have hS : S.Nonempty := ⟨0, by simp only [S, Finset.mem_filter, Finset.mem_univ, true_and]; exact hymem.1⟩
  have hjS : a (S.max' hS) < y := by
    have := S.max'_mem hS
    simp only [S, Finset.mem_filter, Finset.mem_univ, true_and] at this
    exact this
  have hjne : S.max' hS ≠ Fin.last m := by
    intro h; rw [h, hlast] at hjS; linarith [hymem.2]
  set i := (S.max' hS).castPred hjne
  have hji : i.castSucc = S.max' hS := Fin.castSucc_castPred _ hjne
  have hsucc : y ≤ a i.succ := by
    by_contra hc
    have hmem : i.succ ∈ S := by
      simp only [S, Finset.mem_filter, Finset.mem_univ, true_and]; exact not_le.1 hc
    have h1 := S.le_max' _ hmem
    rw [← hji] at h1
    exact absurd h1 (not_le.2 Fin.castSucc_lt_succ)
  obtain ⟨g, hgc, hgeq⟩ := hg i
  refine ⟨fun t => g (t - k • (2 * π)), hgc.comp (contDiff_id.sub contDiff_const),
    y - a (S.max' hS), by linarith, ?_⟩
  intro t ht
  rw [← hper.sub_zsmul_eq k]
  apply hgeq
  rw [hji]
  constructor <;> linarith [ht.1, ht.2]

lemma integral_exp_neg_int_mul (n : ℤ) :
    ∫ u in (-π)..π, Complex.exp (-(n * u * Complex.I)) = if n = 0 then (2 * π : ℂ) else 0 := by
  split_ifs with hn
  · subst hn
    simp only [Int.cast_zero, zero_mul, neg_zero, Complex.exp_zero, intervalIntegral.integral_const,
      sub_neg_eq_add, Complex.real_smul, mul_one]
    push_cast; ring
  · have hc : (-(n * Complex.I) : ℂ) ≠ 0 := by
      simp [Complex.I_ne_zero, hn]
    have : (fun u : ℝ => Complex.exp (-(n * u * Complex.I))) =
        fun u : ℝ => Complex.exp (-(n * Complex.I) * u) := by
      ext u; congr 1; ring
    rw [this, integral_exp_mul_complex hc]
    have h2 : Complex.exp (-(n * Complex.I) * ((-π : ℝ) : ℂ)) =
        Complex.exp (-(n * Complex.I) * (π : ℂ)) * Complex.exp (n * (2 * π * Complex.I)) := by
      rw [← Complex.exp_add]; congr 1; push_cast; ring
    rw [h2, Complex.exp_int_mul_two_pi_mul_I, mul_one, sub_self, zero_div]

lemma step_partialSum (x L R : ℝ) (N : ℕ) :
    partialSum (fun t => if 0 < Real.sin (t - x) then R else if Real.sin (t - x) < 0 then L
      else (L + R) / 2) N x = (((L + R) / 2 : ℝ) : ℂ) := by
  set σ : ℝ → ℝ := fun t => if 0 < Real.sin (t - x) then R else if Real.sin (t - x) < 0 then L
      else (L + R) / 2 with hσ
  set s : ℝ → ℝ := fun u => if 0 < Real.sin u then R else if Real.sin u < 0 then L
      else (L + R) / 2 with hs
  have hσper : Function.Periodic σ (2 * π) := by
    intro t; simp only [hσ]; rw [show t + 2 * π - x = (t - x) + 2 * π by ring, Real.sin_add_two_pi]
  have hsI : IntervalIntegrable s volume (-π) π := by
    refine ii_two_pieces s (-π) 0 π L R (by linarith [Real.pi_pos]) Real.pi_pos.le ?_ ?_
    · intro u hu
      have : Real.sin u < 0 := Real.sin_neg_of_neg_of_neg_pi_lt hu.2 hu.1
      simp [hs, this, not_lt.2 this.le]
    · intro u hu
      have : 0 < Real.sin u := Real.sin_pos_of_pos_of_lt_pi hu.1 hu.2
      simp [hs, this]
  have hsC : IntervalIntegrable (fun u => (s u : ℂ)) volume (-π) π := ⟨hsI.1.ofReal, hsI.2.ofReal⟩
  have hJI : ∀ n : ℤ, IntervalIntegrable (fun u => Complex.exp (-(n * u * Complex.I)) * (s u : ℂ))
      volume (-π) π := fun n => hsC.continuousOn_mul (by fun_prop)
  set J : ℤ → ℂ := fun n => ∫ u in (-π)..π, Complex.exp (-(n * u * Complex.I)) * (s u : ℂ)
    with hJ
  have hcoeff : ∀ n : ℤ, coeff σ n * Complex.exp (n * x * Complex.I) =
      (1 / (2 * π) : ℂ) * J n := by
    intro n
    rw [coeff_eq_integral_shift σ hσper n x, mul_assoc, ← intervalIntegral.integral_mul_const]
    congr 1
    have h := intervalIntegral.integral_comp_sub_right (a := x - π) (b := x + π)
      (fun u => Complex.exp (-(n * u * Complex.I)) * (s u : ℂ)) x
    rw [show x - π - x = -π by ring, show x + π - x = π by ring] at h
    show _ = ∫ u in (-π)..π, Complex.exp (-(n * u * Complex.I)) * (s u : ℂ)
    rw [← h]
    apply intervalIntegral.integral_congr
    intro t _
    simp only [hσ, hs]
    rw [mul_right_comm, ← Complex.exp_add]
    congr 2
    push_cast
    ring
  have hpair : ∀ n : ℤ, J n + J (-n) = ((L + R : ℝ) : ℂ) * (if n = 0 then (2 * π : ℂ) else 0) := by
    intro n
    have hneg : J (-n) = ∫ u in (-π)..π, Complex.exp (-(n * u * Complex.I)) * (s (-u) : ℂ) := by
      have h := intervalIntegral.integral_comp_neg (a := -π) (b := π)
        (fun v => Complex.exp (n * v * Complex.I) * (s v : ℂ))
      rw [neg_neg] at h
      calc J (-n) = ∫ v in (-π)..π, Complex.exp (n * v * Complex.I) * (s v : ℂ) := by
            simp only [hJ]
            apply intervalIntegral.integral_congr
            intro u _
            simp only
            congr 2
            push_cast
            ring
        _ = _ := by
            rw [← h]
            apply intervalIntegral.integral_congr
            intro u _
            simp only
            congr 2
            push_cast
            ring
    rw [hneg, ← integral_exp_neg_int_mul n, ← intervalIntegral.integral_const_mul]
    simp only [hJ]
    rw [← intervalIntegral.integral_add (hJI n)]
    · apply intervalIntegral.integral_congr
      intro u _
      have hsum : s u + s (-u) = L + R := by
        simp only [hs, Real.sin_neg]
        rcases lt_trichotomy (Real.sin u) 0 with h | h | h
        · simp [h, not_lt.2 h.le]
        · simp [h]
        · simp [h, not_lt.2 h.le]; ring
      simp only
      rw [← mul_add, ← Complex.ofReal_add, hsum]
      ring
    · have hsI' : IntervalIntegrable (fun u => s (-u)) volume (-π) π := by
        refine ii_two_pieces _ (-π) 0 π R L (by linarith [Real.pi_pos]) Real.pi_pos.le ?_ ?_
        · intro u hu
          have : Real.sin u < 0 := Real.sin_neg_of_neg_of_neg_pi_lt hu.2 hu.1
          simp [hs, Real.sin_neg, this]
        · intro u hu
          have : 0 < Real.sin u := Real.sin_pos_of_pos_of_lt_pi hu.1 hu.2
          simp [hs, Real.sin_neg, this, not_lt.2 this.le]
      have hsC' : IntervalIntegrable (fun u => (s (-u) : ℂ)) volume (-π) π :=
        ⟨hsI'.1.ofReal, hsI'.2.ofReal⟩
      exact hsC'.continuousOn_mul (by fun_prop)
  have hsymm : ∑ n ∈ Icc (-(N : ℤ)) N, J (-n) = ∑ n ∈ Icc (-(N : ℤ)) N, J n :=
    Finset.sum_nbij' (fun n => -n) (fun n => -n)
      (by intro a ha; simp only [mem_Icc] at ha ⊢; omega)
      (by intro a ha; simp only [mem_Icc] at ha ⊢; omega)
      (by intro a _; simp) (by intro a _; simp) (by intro a _; simp)
  have htot : ∑ n ∈ Icc (-(N : ℤ)) N, J n = ((L + R : ℝ) : ℂ) * π := by
    have h2 : ∑ n ∈ Icc (-(N : ℤ)) N, (J n + J (-n)) = ((L + R : ℝ) : ℂ) * (2 * π) := by
      simp_rw [hpair]
      rw [← mul_sum, Finset.sum_ite_eq']
      simp
    rw [sum_add_distrib, hsymm] at h2
    linear_combination h2 / 2
  unfold partialSum
  simp_rw [hcoeff]
  rw [← mul_sum, htot]
  have : (π : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
  push_cast
  field_simp

/-- **Dirichlet's theorem.** Let f repeat every 2π and be piecewise smooth: there are break
points a_0 < a_1 < ⋯ < a_m = a_0 + 2π, and on each open piece (a_i, a_(i+1)) f agrees with a
function whose slope is continuous, so the slope has limits at the piece's ends; jumps between
pieces are allowed. At any point x, let L = f(x⁻) be the value approached from the left and
R = f(x⁺) the value approached from the right. Then the partial sums S_N f(x) tend to the
midpoint (L + R)/2; where f has no jump, that midpoint is f(x). -/
theorem partial_sums_tend_to_midpoint_of_piecewise_smooth (f : ℝ → ℝ)
    (hper : Function.Periodic f (2 * π))
    (hpieces : ∃ (m : ℕ) (a : Fin (m + 1) → ℝ), StrictMono a ∧ a (Fin.last m) = a 0 + 2 * π ∧
      ∀ i : Fin m, ∃ g : ℝ → ℝ, ContDiff ℝ 1 g ∧ Set.EqOn f g (Set.Ioo (a i.castSucc) (a i.succ)))
    (x L R : ℝ) (hL : Tendsto f (𝓝[<] x) (𝓝 L)) (hR : Tendsto f (𝓝[>] x) (𝓝 R)) :
    Tendsto (fun N : ℕ => partialSum f N x) atTop (𝓝 (((L + R) / 2 : ℝ) : ℂ)) := by
  set σ : ℝ → ℝ := fun t => if 0 < Real.sin (t - x) then R else if Real.sin (t - x) < 0 then L
      else (L + R) / 2 with hσ
  have hσper : Function.Periodic σ (2 * π) := by
    intro t; simp only [hσ]; rw [show t + 2 * π - x = (t - x) + 2 * π by ring, Real.sin_add_two_pi]
  have hfI := intervalIntegrable_of_pieces f hper hpieces (x - π) (x + π)
  have hσI : IntervalIntegrable σ volume (x - π) (x + π) := by
    refine ii_two_pieces σ (x - π) x (x + π) L R (by linarith [Real.pi_pos])
      (by linarith [Real.pi_pos]) ?_ ?_
    · intro t ht
      have : Real.sin (t - x) < 0 :=
        Real.sin_neg_of_neg_of_neg_pi_lt (by linarith [ht.2]) (by linarith [ht.1])
      simp [hσ, this, not_lt.2 this.le]
    · intro t ht
      have : 0 < Real.sin (t - x) :=
        Real.sin_pos_of_pos_of_lt_pi (by linarith [ht.1]) (by linarith [ht.2])
      simp [hσ, this]
  obtain ⟨G₂, hG₂, ε₂, hε₂, hfG₂⟩ := local_right f hper hpieces x
  obtain ⟨G₁, hG₁, ε₁, hε₁, hfG₁⟩ := local_left f hper hpieces x
  have hR' : G₂ x = R := by
    have h1 : Tendsto G₂ (𝓝[>] x) (𝓝 R) :=
      hR.congr' (Filter.eventually_of_mem (Ioo_mem_nhdsGT (by linarith : x < x + ε₂)) hfG₂)
    have h2 : Tendsto G₂ (𝓝[>] x) (𝓝 (G₂ x)) :=
      hG₂.continuous.continuousAt.tendsto.mono_left nhdsWithin_le_nhds
    exact tendsto_nhds_unique h2 h1
  have hL' : G₁ x = L := by
    have h1 : Tendsto G₁ (𝓝[<] x) (𝓝 L) :=
      hL.congr' (Filter.eventually_of_mem (Ioo_mem_nhdsLT (by linarith : x - ε₁ < x)) hfG₁)
    have h2 : Tendsto G₁ (𝓝[<] x) (𝓝 (G₁ x)) :=
      hG₁.continuous.continuousAt.tendsto.mono_left nhdsWithin_le_nhds
    exact tendsto_nhds_unique h2 h1
  obtain ⟨K₂, s₂, hs₂, hlip₂⟩ := hG₂.contDiffAt.exists_lipschitzOnWith (x := x)
  obtain ⟨K₁, s₁, hs₁, hlip₁⟩ := hG₁.contDiffAt.exists_lipschitzOnWith (x := x)
  obtain ⟨η₂, hη₂, hb₂⟩ := Metric.mem_nhds_iff.1 hs₂
  obtain ⟨η₁, hη₁, hb₁⟩ := Metric.mem_nhds_iff.1 hs₁
  set ε := min (min ε₁ ε₂) (min (min η₁ η₂) π) with hε
  have hεpos : 0 < ε := by
    simp only [hε, lt_min_iff]; exact ⟨⟨hε₁, hε₂⟩, ⟨hη₁, hη₂⟩, Real.pi_pos⟩
  have hε1 : ε ≤ ε₁ := le_trans (min_le_left _ _) (min_le_left _ _)
  have hε2 : ε ≤ ε₂ := le_trans (min_le_left _ _) (min_le_right _ _)
  have hεη1 : ε ≤ η₁ := le_trans (min_le_right _ _) (le_trans (min_le_left _ _) (min_le_left _ _))
  have hεη2 : ε ≤ η₂ := le_trans (min_le_right _ _) (le_trans (min_le_left _ _) (min_le_right _ _))
  have hεπ : ε ≤ π := le_trans (min_le_right _ _) (min_le_right _ _)
  have hxs₁ : x ∈ s₁ := hb₁ (Metric.mem_ball_self hη₁)
  have hxs₂ : x ∈ s₂ := hb₂ (Metric.mem_ball_self hη₂)
  have hnear : ∀ t, t ≠ x → |t - x| < ε → |f t - σ t| ≤ (max K₁ K₂ : ℝ) * |t - x| := by
    intro t htx ht
    have hts₁ : t ∈ s₁ := hb₁ (by rw [Metric.mem_ball, Real.dist_eq]; linarith)
    have hts₂ : t ∈ s₂ := hb₂ (by rw [Metric.mem_ball, Real.dist_eq]; linarith)
    rw [abs_lt] at ht
    rcases lt_or_gt_of_ne htx with hlt | hgt
    · have hsin : Real.sin (t - x) < 0 :=
        Real.sin_neg_of_neg_of_neg_pi_lt (by linarith) (by linarith)
      have hσt : σ t = L := by simp [hσ, hsin, not_lt.2 hsin.le]
      rw [hfG₁ t ⟨by linarith, hlt⟩, hσt, ← hL']
      have := hlip₁.dist_le_mul t hts₁ x hxs₁
      rw [Real.dist_eq, Real.dist_eq] at this
      calc |G₁ t - G₁ x| ≤ K₁ * |t - x| := this
        _ ≤ (max K₁ K₂ : ℝ) * |t - x| := by
          gcongr; exact_mod_cast le_max_left K₁ K₂
    · have hsin : 0 < Real.sin (t - x) :=
        Real.sin_pos_of_pos_of_lt_pi (by linarith) (by linarith)
      have hσt : σ t = R := by simp [hσ, hsin]
      rw [hfG₂ t ⟨hgt, by linarith⟩, hσt, ← hR']
      have := hlip₂.dist_le_mul t hts₂ x hxs₂
      rw [Real.dist_eq, Real.dist_eq] at this
      calc |G₂ t - G₂ x| ≤ K₂ * |t - x| := this
        _ ≤ (max K₁ K₂ : ℝ) * |t - x| := by
          gcongr; exact_mod_cast le_max_right K₁ K₂
  have hd := partialSum_sub_tendsto_of_dini f σ hper hσper x hfI hσI ε (max K₁ K₂ : ℝ) hεpos
    (by positivity) hnear
  have hstep : ∀ N : ℕ, partialSum σ N x = (((L + R) / 2 : ℝ) : ℂ) := step_partialSum x L R
  have := hd.add_const (((L + R) / 2 : ℝ) : ℂ)
  rw [zero_add] at this
  refine this.congr fun N => ?_
  rw [hstep N, sub_add_cancel]

/-- **Uniform convergence from summable coefficients.** If a 2π-periodic signal f is continuous
and the sizes of its coefficients add up, ∑ₙ |f̂(n)| < ∞, then for every N and every x the error
|f(x) − S_N f(x)| is at most the M-test tail R_N = ∑_{|n| > N} |f̂(n)|, one bound for the whole
cycle; so the partial sums converge to f uniformly. -/
theorem error_le_tail_of_summable_coeff (f : ℝ → ℝ) (hper : Function.Periodic f (2 * π))
    (hcont : Continuous f) (hsum : Summable (fun n : ℤ => ‖coeff f n‖)) :
    (∀ (N : ℕ) (x : ℝ),
      ‖(f x : ℂ) - partialSum f N x‖ ≤ ∑' n : {n : ℤ // (N : ℤ) < |n|}, ‖coeff f n‖) ∧
    TendstoUniformly (fun (N : ℕ) (x : ℝ) => partialSum f N x) (fun x => (f x : ℂ)) atTop := by
  have hT : (0 : ℝ) < π - -π := by linarith [Real.pi_pos]
  have : Fact (0 < π - -π) := ⟨hT⟩
  have hper' : Function.Periodic f (π - -π) := by
    rw [show π - -π = 2 * π by ring]; exact hper
  let F : C(AddCircle (π - -π), ℂ) :=
    ⟨AddCircle.liftIoc (π - -π) (-π) (fun t => (f t : ℂ)),
      AddCircle.liftIoc_continuous
        (by show (f (-π) : ℂ) = f (-π + (π - -π)); rw [hper'])
        (Complex.continuous_ofReal.comp hcont).continuousOn⟩
  have hFc : ∀ n, fourierCoeff F n = coeff f n := fun n => rfl
  have hFx : ∀ x : ℝ, F (x : AddCircle (π - -π)) = (f x : ℂ) := by
    intro x
    show (f (AddCircle.equivIoc (π - -π) (-π) (x : AddCircle (π - -π)) : ℝ) : ℂ) = f x
    have hy : (((AddCircle.equivIoc (π - -π) (-π) (x : AddCircle (π - -π)) : ℝ)) :
        AddCircle (π - -π)) = x := AddCircle.coe_equivIoc
    obtain ⟨k, hk⟩ := AddSubgroup.mem_zmultiples_iff.1 (QuotientAddGroup.eq_iff_sub_mem.1 hy)
    rw [show ((AddCircle.equivIoc (π - -π) (-π) (x : AddCircle (π - -π)) : ℝ)) =
      x + k • (π - -π) by rw [hk]; ring, hper'.zsmul k x]
  have hfour : ∀ (n : ℤ) (x : ℝ),
      fourier n (x : AddCircle (π - -π)) = Complex.exp (n * x * Complex.I) := by
    intro n x
    rw [fourier_coe_apply]
    congr 1
    have : (π : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
    push_cast
    field_simp
    ring
  have hsumC : Summable (fourierCoeff F) := by
    rw [show fourierCoeff F = coeff f from funext hFc]; exact hsum.of_norm
  have hHas : ∀ x : ℝ, HasSum (fun n : ℤ => coeff f n * Complex.exp (n * x * Complex.I))
      (f x : ℂ) := by
    intro x
    have := has_pointwise_sum_fourier_series_of_summable hsumC (x : AddCircle (π - -π))
    simpa only [hFc, hFx, hfour, smul_eq_mul] using this
  have hnormeq : ∀ (x : ℝ) (n : ℤ), ‖coeff f n * Complex.exp (n * x * Complex.I)‖ = ‖coeff f n‖ := by
    intro x n
    rw [norm_mul, show (n : ℂ) * (x : ℂ) * Complex.I = ((n * x : ℝ) : ℂ) * Complex.I by
      push_cast; ring, Complex.norm_exp_ofReal_mul_I, mul_one]
  have hequiv : ∀ N : ℕ, ∑' n : {n : ℤ // (N : ℤ) < |n|}, ‖coeff f n‖ =
      ∑' n : ↑((Icc (-(N : ℤ)) N : Finset ℤ) : Set ℤ)ᶜ, ‖coeff f n‖ := by
    intro N
    exact Equiv.tsum_eq (Equiv.subtypeEquivRight (fun n => by
      simp only [Set.mem_compl_iff, Finset.mem_coe, Finset.mem_Icc, lt_abs]; omega))
      (fun m : ↑((Icc (-(N : ℤ)) N : Finset ℤ) : Set ℤ)ᶜ => ‖coeff f m.1‖)
  have hbound : ∀ (N : ℕ) (x : ℝ), ‖(f x : ℂ) - partialSum f N x‖ ≤
      ∑' n : {n : ℤ // (N : ℤ) < |n|}, ‖coeff f n‖ := by
    intro N x
    rw [hequiv N]
    have h1 := (hHas x).summable.sum_add_tsum_compl (s := Icc (-(N : ℤ)) N)
    rw [(hHas x).tsum_eq] at h1
    have h2 : (f x : ℂ) - partialSum f N x = ∑' n : ↑((Icc (-(N : ℤ)) N : Finset ℤ) : Set ℤ)ᶜ,
        coeff f n * Complex.exp (n * x * Complex.I) := by
      rw [← h1]; unfold partialSum; ring
    rw [h2]
    have hs2 : Summable (fun n : ↑((Icc (-(N : ℤ)) N : Finset ℤ) : Set ℤ)ᶜ => ‖coeff f n‖) :=
      hsum.subtype _
    refine (norm_tsum_le_tsum_norm ?_).trans (le_of_eq ?_)
    · simpa only [hnormeq] using hs2
    · simp only [hnormeq]
  refine ⟨hbound, ?_⟩
  rw [Metric.tendstoUniformly_iff]
  intro ε hε
  have htail : Tendsto (fun N : ℕ => ∑' n : {n : ℤ // n ∉ Icc (-(N : ℤ)) N}, ‖coeff f n‖)
      atTop (𝓝 0) :=
    (tendsto_tsum_compl_atTop_zero (fun n => ‖coeff f n‖)).comp
      (tendsto_atTop_finset_of_monotone
        (fun a b hab => Finset.Icc_subset_Icc (by omega) (by omega))
        (fun n => ⟨n.natAbs, by rw [mem_Icc, Int.natCast_natAbs]; exact abs_le.1 le_rfl⟩))
  filter_upwards [htail.eventually (gt_mem_nhds hε)] with N hN x
  rw [dist_eq_norm]
  refine (hbound N x).trans_lt ?_
  convert hN using 1
  exact Equiv.tsum_eq (Equiv.subtypeEquivRight (fun n => by
      simp only [Finset.mem_Icc, lt_abs]; omega))
      (fun m : {n : ℤ // n ∉ Icc (-(N : ℤ)) N} => ‖coeff f m.1‖)

/-- **Riemann's localisation principle.** If two 2π-periodic signals f and g, each integrable over
the cycle, agree on a window (x − δ, x + δ) around x with δ > 0, then S_N f(x) − S_N g(x) tends
to 0: whether the series settles at x, and on what value, is decided by the signal near x. -/
theorem partial_sums_difference_tends_to_zero_of_eq_near (f g : ℝ → ℝ)
    (hfper : Function.Periodic f (2 * π)) (hgper : Function.Periodic g (2 * π))
    (hf : IntervalIntegrable f MeasureTheory.volume (-π) π)
    (hg : IntervalIntegrable g MeasureTheory.volume (-π) π)
    (x δ : ℝ) (hδ : 0 < δ) (heq : Set.EqOn f g (Set.Ioo (x - δ) (x + δ))) :
    Tendsto (fun N : ℕ => partialSum f N x - partialSum g N x) atTop (𝓝 0) := by
  have h2π : (2 * π) ≠ 0 := by positivity
  have hf' := hfper.intervalIntegrable h2π (t := -π) (by rwa [show -π + 2 * π = π by ring])
    (x - π) (x + π)
  have hg' := hgper.intervalIntegrable h2π (t := -π) (by rwa [show -π + 2 * π = π by ring])
    (x - π) (x + π)
  refine partialSum_sub_tendsto_of_dini f g hfper hgper x hf' hg' δ 0 hδ le_rfl ?_
  intro t _ ht
  rw [abs_lt] at ht
  rw [heq ⟨by linarith, by linarith⟩, sub_self, abs_zero, zero_mul]

-- The card's whole-number facts: at 220 Hz the harmonics below 20,000 Hz are n = 1 to 90,
-- the 90th at 19,800 Hz and the 91st already past the limit.
example : 20000 / 220 = 90 := by norm_num
example : 220 * 90 = 19800 := by norm_num
example : 20000 < 220 * 91 := by norm_num

-- The sawtooth's sums at x = π/2 by hand, before the factor 2/π: 1, 1 − 1/3, 1 − 1/3 + 1/5.
example : (1 : ℚ) - 1 / 3 = 2 / 3 := by norm_num
example : (1 : ℚ) - 1 / 3 + 1 / 5 = 13 / 15 := by norm_num

-- At the snap x = π every term sin(nπ) of the sawtooth's real form
-- (2/π) ∑_{n=1}^{N} (−1)^(n+1) sin(nx)/n is 0, so S_N f(π) = 0 for every N: the midpoint of +1 and −1.
example (N : ℕ) :
    2 / π * ∑ n ∈ Icc 1 N, (-1 : ℝ) ^ (n + 1) * Real.sin (n * π) / n = 0 := by
  simp [Real.sin_nat_mul_pi]

#print axioms partial_sums_tend_to_midpoint_of_piecewise_smooth
#print axioms error_le_tail_of_summable_coeff
#print axioms partial_sums_difference_tends_to_zero_of_eq_near
#print axioms cycle_neg_pi_lt_pi
#print axioms coeff_eq_integral_shift
#print axioms rl_seq
#print axioms norm_one_sub_exp_ge
#print axioms sum_Icc_telescope
#print axioms partialSum_sub_tendsto_of_dini
#print axioms ii_two_pieces
#print axioms intervalIntegrable_of_pieces
#print axioms local_right
#print axioms local_left
#print axioms integral_exp_neg_int_mul
#print axioms step_partialSum
