-- Modes of convergence: convergence in mean and (on a finite measure space) almost everywhere each force convergence in measure, convergence in measure forces almost everywhere convergence along a subsequence, and the typewriter and growing spike on [0, 1) show the missing arrows fail.
import Mathlib.MeasureTheory.Function.ConvergenceInMeasure
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Data.Nat.Log

open MeasureTheory Filter Set Topology

/-- Number of strips `M = 2^m` in the pass that contains step `n`, where `2^m ≤ n < 2^(m+1)`. -/
def twM (n : ℕ) : ℕ := 2 ^ Nat.log 2 n

/-- Which strip `k` of its pass step `n` lights, counting from 0: `n = M + k`. -/
def twK (n : ℕ) : ℕ := n - twM n

/-- The typewriter sequence: `f_n` is 1 on `[k/M, (k+1)/M)` and 0 elsewhere, where `n = M + k`, `M = 2^m`, `0 ≤ k < M`. -/
noncomputable def typewriter (n : ℕ) : ℝ → ℝ :=
  Set.indicator (Set.Ico ((twK n : ℝ) / twM n) (((twK n : ℝ) + 1) / twM n)) (fun _ => 1)

/-- The growing spike: `g_n` is `n` on `[0, 1/n)` and 0 elsewhere. -/
noncomputable def spike (n : ℕ) : ℝ → ℝ :=
  Set.indicator (Set.Ico (0 : ℝ) (1 / (n : ℝ))) (fun _ => (n : ℝ))

lemma tw_pass (m k : ℕ) (hk : k < 2 ^ m) : twM (2 ^ m + k) = 2 ^ m ∧ twK (2 ^ m + k) = k := by
  have hlog : Nat.log 2 (2 ^ m + k) = m :=
    Nat.log_eq_of_pow_le_of_lt_pow (by omega) (by rw [pow_succ]; omega)
  refine ⟨by simp [twM, hlog], ?_⟩
  simp [twK, twM, hlog]

lemma twK_lt_twM (n : ℕ) : twK n < twM n := by
  have h := Nat.lt_pow_succ_log_self (by norm_num : 1 < 2) n
  rw [pow_succ] at h
  unfold twK twM
  have : 0 < 2 ^ Nat.log 2 n := by positivity
  omega

lemma twM_tendsto : Tendsto (fun n => (twM n : ℝ)) atTop atTop := by
  refine tendsto_natCast_atTop_atTop.comp ?_
  refine tendsto_atTop_atTop.2 fun b => ⟨2 * b, fun n hn => ?_⟩
  have h := Nat.lt_pow_succ_log_self (by norm_num : 1 < 2) n
  rw [pow_succ] at h
  unfold twM
  omega

lemma tw_strip_sub (n : ℕ) :
    Ico ((twK n : ℝ) / twM n) (((twK n : ℝ) + 1) / twM n) ⊆ Ico (0 : ℝ) 1 := by
  have hM : (0 : ℝ) < twM n := by unfold twM; positivity
  have hk : (twK n : ℝ) + 1 ≤ twM n := by exact_mod_cast twK_lt_twM n
  intro x hx
  rw [mem_Ico] at hx ⊢
  constructor
  · exact le_trans (by positivity) hx.1
  · exact lt_of_lt_of_le hx.2 ((div_le_one hM).2 hk)

lemma tw_strip_vol (n : ℕ) :
    volume (Ico ((twK n : ℝ) / twM n) (((twK n : ℝ) + 1) / twM n)) =
      ENNReal.ofReal (1 / twM n) := by
  rw [Real.volume_Ico]
  congr 1
  ring

lemma mem_strip_iff (x : ℝ) (hx : 0 ≤ x) (M k : ℕ) (hM : 0 < M) :
    x ∈ Ico ((k : ℝ) / M) (((k : ℝ) + 1) / M) ↔ ⌊x * M⌋₊ = k := by
  have hM' : (0 : ℝ) < M := by exact_mod_cast hM
  rw [Nat.floor_eq_iff (by positivity), mem_Ico, div_le_iff₀ hM', lt_div_iff₀ hM']

lemma tw_val (m k : ℕ) (hk : k < 2 ^ m) (x : ℝ) (hx : 0 ≤ x) :
    typewriter (2 ^ m + k) x = if ⌊x * ((2 ^ m : ℕ) : ℝ)⌋₊ = k then 1 else 0 := by
  obtain ⟨h1, h2⟩ := tw_pass m k hk
  unfold typewriter
  rw [h1, h2]
  by_cases h : ⌊x * ((2 ^ m : ℕ) : ℝ)⌋₊ = k
  · rw [if_pos h, Set.indicator_of_mem ((mem_strip_iff x hx _ k (by positivity)).2 h)]
  · rw [if_neg h, Set.indicator_of_notMem
      (fun h' => h ((mem_strip_iff x hx _ k (by positivity)).1 h'))]

#print axioms tw_pass
#print axioms twK_lt_twM
#print axioms twM_tendsto
#print axioms tw_strip_sub
#print axioms tw_strip_vol
#print axioms mem_strip_iff
#print axioms tw_val

/-- The map of which mode implies which, for measurable real functions `f_n` and `f` on one
measure space. (1) In mean forces in measure: if `|f_n - f|^p` is integrable for a power
`p ≥ 1` and `∫ |f_n - f|^p dμ → 0`, then `f_n → f` in measure. (2) Almost everywhere forces in
measure when the whole space has finite size. (3) In measure forces almost everywhere
convergence along a subsequence `n_1 < n_2 < ...`. -/
theorem modes_of_convergence_map {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    (f : ℕ → Ω → ℝ) (g : Ω → ℝ) (hf : ∀ n, Measurable (f n)) (hg : Measurable g) :
    (∀ p : ℝ, 1 ≤ p → (∀ n, Integrable (fun x => |f n x - g x| ^ p) μ) →
        Tendsto (fun n => ∫ x, |f n x - g x| ^ p ∂μ) atTop (𝓝 0) →
        TendstoInMeasure μ f atTop g) ∧
    (IsFiniteMeasure μ → (∀ᵐ x ∂μ, Tendsto (fun n => f n x) atTop (𝓝 (g x))) →
        TendstoInMeasure μ f atTop g) ∧
    (TendstoInMeasure μ f atTop g →
        ∃ ns : ℕ → ℕ, StrictMono ns ∧ ∀ᵐ x ∂μ, Tendsto (fun j => f (ns j) x) atTop (𝓝 (g x))) := by
  refine ⟨fun p hp hint hlim => ?_, fun hfin hae => ?_, fun h => h.exists_seq_tendsto_ae⟩
  · rw [tendstoInMeasure_iff_dist]
    intro ε hε
    have hεp : 0 < ε ^ p := Real.rpow_pos_of_pos hε p
    have hεp' : ENNReal.ofReal (ε ^ p) ≠ 0 := by simpa using hεp
    have key : ∀ n, μ {x | ε ≤ dist (f n x) (g x)} ≤
        ENNReal.ofReal (∫ x, |f n x - g x| ^ p ∂μ) / ENNReal.ofReal (ε ^ p) := by
      intro n
      rw [ofReal_integral_eq_lintegral_ofReal (hint n)
        (Eventually.of_forall fun x => by positivity)]
      calc μ {x | ε ≤ dist (f n x) (g x)}
          ≤ μ {x | ENNReal.ofReal (ε ^ p) ≤ ENNReal.ofReal (|f n x - g x| ^ p)} := by
            apply measure_mono
            intro x hx
            simp only [mem_setOf_eq, Real.dist_eq] at hx ⊢
            exact ENNReal.ofReal_le_ofReal (Real.rpow_le_rpow hε.le hx (by linarith))
        _ ≤ _ := meas_ge_le_lintegral_div ((hint n).aemeasurable.ennreal_ofReal) hεp'
              ENNReal.ofReal_ne_top
    have hlim' : Tendsto (fun n => ENNReal.ofReal (∫ x, |f n x - g x| ^ p ∂μ) /
        ENNReal.ofReal (ε ^ p)) atTop (𝓝 0) := by
      have := ENNReal.Tendsto.div_const (ENNReal.tendsto_ofReal hlim) (Or.inr hεp')
      simpa using this
    exact tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds hlim'
      (fun _ => zero_le) key
  · exact tendstoInMeasure_of_tendsto_ae (fun n => (hf n).aestronglyMeasurable) hae

/-- The typewriter on the stage `[0, 1)` with length: it tends to 0 in measure and in mean,
yet at every seat of `[0, 1)` it converges to no limit at all. So neither in measure nor in
mean forces almost everywhere convergence of the whole sequence. -/
theorem typewriter_in_mean_but_settles_nowhere :
    TendstoInMeasure (volume.restrict (Ico (0 : ℝ) 1)) typewriter atTop 0 ∧
    Tendsto (fun n => ∫ x in Ico (0 : ℝ) 1, |typewriter n x|) atTop (𝓝 0) ∧
    ∀ x ∈ Ico (0 : ℝ) 1, ¬ ∃ l : ℝ, Tendsto (fun n => typewriter n x) atTop (𝓝 l) := by
  have habs : ∀ n x, |typewriter n x| = typewriter n x := by
    intro n x
    unfold typewriter
    by_cases h : x ∈ Ico ((twK n : ℝ) / twM n) (((twK n : ℝ) + 1) / twM n)
    · simp [Set.indicator_of_mem h]
    · simp [Set.indicator_of_notMem h]
  have hint : ∀ n, ∫ x in Ico (0 : ℝ) 1, |typewriter n x| = 1 / twM n := by
    intro n
    simp_rw [habs]
    unfold typewriter
    rw [integral_indicator_const _ measurableSet_Ico, measureReal_restrict_apply measurableSet_Ico,
      inter_eq_left.2 (tw_strip_sub n), measureReal_def, tw_strip_vol,
      ENNReal.toReal_ofReal (by positivity), smul_eq_mul, mul_one]
  have hlim : Tendsto (fun n => 1 / (twM n : ℝ)) atTop (𝓝 0) :=
    tendsto_const_nhds.div_atTop twM_tendsto
  refine ⟨?_, ?_, ?_⟩
  · intro ε hε
    have hb : ∀ n, (volume.restrict (Ico (0 : ℝ) 1))
        {x | ε ≤ edist (typewriter n x) ((0 : ℝ → ℝ) x)} ≤ ENNReal.ofReal (1 / twM n) := by
      intro n
      rw [← tw_strip_vol n]
      refine le_trans (measure_mono ?_) (Measure.restrict_apply_le _ _)
      intro x hx
      by_contra h
      simp only [mem_setOf_eq, typewriter, Set.indicator_of_notMem h, Pi.zero_apply,
        edist_self] at hx
      exact absurd hx (not_le.2 hε)
    have h0 : Tendsto (fun n => ENNReal.ofReal (1 / (twM n : ℝ))) atTop (𝓝 0) := by
      simpa using ENNReal.tendsto_ofReal hlim
    exact tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds h0 (fun _ => zero_le) hb
  · simp_rw [hint]
    exact hlim
  · intro x hx ⟨l, hl⟩
    have hx0 : 0 ≤ x := hx.1
    have hfl : ∀ m : ℕ, ⌊x * ((2 ^ (m + 1) : ℕ) : ℝ)⌋₊ < 2 ^ (m + 1) := by
      intro m
      rw [Nat.floor_lt (by positivity)]
      have hpos : (0 : ℝ) < ((2 ^ (m + 1) : ℕ) : ℝ) := by positivity
      exact mul_lt_of_lt_one_left hpos hx.2
    have h2 : ∀ m : ℕ, 2 ≤ 2 ^ (m + 1) := fun m => by
      calc 2 = 2 ^ 1 := by norm_num
        _ ≤ 2 ^ (m + 1) := Nat.pow_le_pow_right (by norm_num) (by omega)
    set k : ℕ → ℕ := fun m => ⌊x * ((2 ^ (m + 1) : ℕ) : ℝ)⌋₊ with hk
    set k' : ℕ → ℕ := fun m => if k m = 0 then 1 else 0 with hk'
    have hk'lt : ∀ m, k' m < 2 ^ (m + 1) := by
      intro m
      have := h2 m
      simp only [hk']
      split_ifs <;> omega
    have hk'ne : ∀ m, k m ≠ k' m := by
      intro m
      simp only [hk']
      split_ifs <;> omega
    have hmono : ∀ (j : ℕ → ℕ), Tendsto (fun m => 2 ^ (m + 1) + j m) atTop atTop := by
      intro j
      refine tendsto_atTop_mono (fun m => ?_) tendsto_id
      have := (m + 1).lt_two_pow_self
      simp only [id]
      omega
    have hone : Tendsto (fun m => typewriter (2 ^ (m + 1) + k m) x) atTop (𝓝 l) :=
      hl.comp (hmono k)
    have hzero : Tendsto (fun m => typewriter (2 ^ (m + 1) + k' m) x) atTop (𝓝 l) :=
      hl.comp (hmono k')
    have e1 : ∀ m, typewriter (2 ^ (m + 1) + k m) x = 1 := by
      intro m
      rw [tw_val (m + 1) (k m) (hfl m) x hx0, if_pos rfl]
    have e0 : ∀ m, typewriter (2 ^ (m + 1) + k' m) x = 0 := by
      intro m
      rw [tw_val (m + 1) (k' m) (hk'lt m) x hx0, if_neg (hk'ne m)]
    simp_rw [e1] at hone
    simp_rw [e0] at hzero
    have l1 := tendsto_nhds_unique tendsto_const_nhds hone
    have l0 := tendsto_nhds_unique tendsto_const_nhds hzero
    norm_num [← l1] at l0

/-- The growing spike on the stage `[0, 1)` with length: it tends to 0 almost everywhere and in
measure, yet its integral is 1 at every step `n ≥ 1`. So almost everywhere convergence does not
force convergence in mean, even on a space of size 1. -/
theorem spike_ae_but_not_in_mean :
    (∀ᵐ x ∂(volume.restrict (Ico (0 : ℝ) 1)), Tendsto (fun n => spike n x) atTop (𝓝 0)) ∧
    TendstoInMeasure (volume.restrict (Ico (0 : ℝ) 1)) spike atTop 0 ∧
    ∀ n : ℕ, 1 ≤ n → ∫ x in Ico (0 : ℝ) 1, |spike n x| = 1 := by
  have hae : ∀ᵐ x ∂(volume.restrict (Ico (0 : ℝ) 1)), Tendsto (fun n => spike n x) atTop (𝓝 0) := by
    refine ae_restrict_of_ae ((Measure.ae_ne volume (0 : ℝ)).mono fun x hx => ?_)
    rcases lt_or_gt_of_ne hx with hneg | hpos
    · refine tendsto_const_nhds.congr fun n => ?_
      unfold spike
      rw [Set.indicator_of_notMem (fun (h : x ∈ Ico (0 : ℝ) (1 / (n : ℝ))) => absurd h.1 (not_le.2 hneg))]
    · obtain ⟨N, hN⟩ := exists_nat_gt (1 / x)
      refine tendsto_const_nhds.congr' ((eventually_ge_atTop N).mono fun n hn => ?_)
      have hNx : 1 < x * N := by
        rw [div_lt_iff₀ hpos] at hN
        linarith
      have hn' : (N : ℝ) ≤ n := by exact_mod_cast hn
      have hnx : 1 < x * n := lt_of_lt_of_le hNx (by gcongr)
      have hnpos : (0 : ℝ) < n := lt_of_lt_of_le (lt_trans (by positivity) hN) hn'
      beta_reduce
      unfold spike
      rw [Set.indicator_of_notMem]
      intro h
      have := h.2
      rw [lt_div_iff₀ hnpos] at this
      linarith
  refine ⟨hae, tendstoInMeasure_of_tendsto_ae
    (fun n => (measurable_const.indicator measurableSet_Ico).aestronglyMeasurable) hae, ?_⟩
  intro n hn
  have hn' : (1 : ℝ) ≤ n := by exact_mod_cast hn
  have hnpos : (0 : ℝ) < n := by linarith
  have habs : ∀ x, |spike n x| = spike n x := by
    intro x
    exact abs_of_nonneg (Set.indicator_nonneg (fun _ _ => hnpos.le) x)
  simp_rw [habs]
  unfold spike
  have hsub : Ico (0 : ℝ) (1 / n) ⊆ Ico 0 1 :=
    Ico_subset_Ico_right ((div_le_one hnpos).2 hn')
  rw [integral_indicator_const _ measurableSet_Ico, measureReal_restrict_apply measurableSet_Ico,
    inter_eq_left.2 hsub, Real.volume_real_Ico, smul_eq_mul]
  rw [sub_zero, max_eq_left (by positivity)]
  field_simp

-- Typewriter, step 10: 10 = 8 + 2, so M = 8 and k = 2, the strip [2/8, 3/8).
example : twM 10 = 8 ∧ twK 10 = 2 := by decide

-- The seat 1/3 is lit at step n exactly when k/M ≤ 1/3 < (k+1)/M, that is 3k ≤ M < 3(k+1).
-- Among steps 1 to 127 this happens at 1, 2, 5, 10, 21, 42, 85: one step in each pass.
example : (List.range 128).filter (fun n => decide (1 ≤ n ∧ 3 * twK n ≤ twM n ∧ twM n < 3 * (twK n + 1)))
    = [1, 2, 5, 10, 21, 42, 85] := by decide

-- The same steps by the formula 2^m + floor(2^m / 3), m = 0 to 6.
example : (List.range 7).map (fun m => 2 ^ m + 2 ^ m / 3) = [1, 2, 5, 10, 21, 42, 85] := by decide

-- The subsequence n_j = 2^j, j = 1 to 4: each lights the left strip [0, 1/2^j).
example : ∀ j ∈ [1, 2, 3, 4], twK (2 ^ j) = 0 ∧ twM (2 ^ j) = 2 ^ j := by decide

-- Markov bound at step 10, tolerance 1/2: lit length 1/8 is at most 2 × 1/8 = 1/4.
example : (2 : ℚ) * (1 / 8) = 1 / 4 ∧ (1 : ℚ) / 8 ≤ 1 / 4 := by norm_num

-- Spike at step 16: integral 16 × 1/16 = 1, and its square integrates to 16^2 × 1/16 = 16.
example : (16 : ℚ) * (1 / 16) = 1 ∧ (16 : ℚ) ^ 2 * (1 / 16) = 16 := by norm_num

-- Egorov for the spike, throwing away [0, 1/10): 1/n ≤ 1/10 first holds at n = 10, and g_9 is
-- still 9 on [1/10, 1/9), a nonempty strip.
example : (1 : ℚ) / 10 ≤ 1 / 10 ∧ ¬ ((1 : ℚ) / 9 ≤ 1 / 10) ∧ (1 : ℚ) / 10 < 1 / 9 := by norm_num

#print axioms modes_of_convergence_map
#print axioms typewriter_in_mean_but_settles_nowhere
#print axioms spike_ae_but_not_in_mean
