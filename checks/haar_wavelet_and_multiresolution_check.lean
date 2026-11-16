-- The Haar wavelet: the stretched and shifted Haar steps ψ_{j,k} are perpendicular with energy 1 and form an orthonormal basis of all finite-energy signals on the line, and the step-function views V_j nest, scale, shift, lose everything and miss nothing.
import Mathlib.Analysis.InnerProductSpace.l2Space
import Mathlib.MeasureTheory.Function.L2Space
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.MeasureTheory.Function.ContinuousMapDense
import Mathlib.MeasureTheory.Function.Floor
import Mathlib.Topology.UniformSpace.HeineCantor

open MeasureTheory

/-! Signals are real functions of time `t : ℝ` (in days on the card). Energy and overlaps use
Lebesgue measure `volume` on the whole line. `Lp ℝ 2 volume` is Mathlib's L²(ℝ): finite-energy
signals, two signals that agree except on a set of length zero counted as one. -/

/-- The scaling function φ: a box of height 1 on 0 ≤ t < 1, zero elsewhere. -/
noncomputable def haarPhi (t : ℝ) : ℝ :=
  if 0 ≤ t ∧ t < 1 then 1 else 0

/-- The Haar wavelet ψ: +1 on 0 ≤ t < 1/2, −1 on 1/2 ≤ t < 1, zero elsewhere. -/
noncomputable def haarPsi (t : ℝ) : ℝ :=
  if 0 ≤ t ∧ t < 1 / 2 then 1 else if 1 / 2 ≤ t ∧ t < 1 then -1 else 0

/-- The Haar function ψ_{j,k}(t) = 2^(−j/2) ψ(2^(−j) t − k): a step of width 2^j starting at
k · 2^j, of height 2^(−j/2). -/
noncomputable def haarPsiJK (j k : ℤ) (t : ℝ) : ℝ :=
  (2 : ℝ) ^ (-(j : ℝ) / 2) * haarPsi ((2 : ℝ) ^ (-j) * t - k)

/-- A signal is constant on every dyadic interval of level `j`, from k · 2^j to (k + 1) · 2^j. -/
def ConstOnDyadic (j : ℤ) (f : ℝ → ℝ) : Prop :=
  ∀ k : ℤ, ∀ s ∈ Set.Ico ((k : ℝ) * 2 ^ j) (((k : ℝ) + 1) * 2 ^ j),
    ∀ t ∈ Set.Ico ((k : ℝ) * 2 ^ j) (((k : ℝ) + 1) * 2 ^ j), f s = f t

/-- The view V_j at width 2^j: finite-energy signals constant on each level-`j` dyadic interval. -/
def haarView (j : ℤ) : Set (ℝ → ℝ) :=
  {f | MemLp f 2 volume ∧ ConstOnDyadic j f}

/-- The dyadic cell of level `j` and index `k`. -/
noncomputable def dcell (j k : ℤ) : Set ℝ := Set.Ico ((k : ℝ) * 2 ^ j) (((k : ℝ) + 1) * 2 ^ j)

lemma mem_dcell_iff (j k : ℤ) (t : ℝ) : t ∈ dcell j k ↔ ⌊t / 2 ^ j⌋ = k := by
  have h := zpow_pos (two_pos : (0:ℝ) < 2) j
  rw [Int.floor_eq_iff, dcell, Set.mem_Ico, le_div_iff₀ h, div_lt_iff₀ h]

lemma mem_dcell_floor (j : ℤ) (t : ℝ) : t ∈ dcell j ⌊t / 2 ^ j⌋ :=
  (mem_dcell_iff j _ t).2 rfl

lemma measurableSet_dcell (j k : ℤ) : MeasurableSet (dcell j k) := measurableSet_Ico

lemma volume_dcell (j k : ℤ) : volume (dcell j k) = ENNReal.ofReal (2 ^ j) := by
  rw [dcell, Real.volume_Ico]; congr 1; ring

lemma volume_real_dcell (j k : ℤ) : volume.real (dcell j k) = 2 ^ j := by
  rw [measureReal_def, volume_dcell, ENNReal.toReal_ofReal (zpow_pos two_pos j).le]

lemma dcell_disjoint {j k k' : ℤ} (h : k ≠ k') : Disjoint (dcell j k) (dcell j k') := by
  rw [Set.disjoint_left]
  intro t h1 h2
  rw [mem_dcell_iff] at h1 h2
  exact h (h1.symm.trans h2)

lemma two_zpow_sub_one (j : ℤ) : (2:ℝ) ^ j = 2 * 2 ^ (j - 1) := by
  rw [← zpow_one_add₀ two_ne_zero]; congr 1; ring

lemma dcell_sub_one_subset (j k : ℤ) : dcell (j - 1) k ⊆ dcell j (k / 2) := by
  have he := two_zpow_sub_one j
  have hpos : (0:ℝ) < 2 ^ (j - 1) := zpow_pos two_pos _
  have h1 : ((2 * (k / 2) : ℤ) : ℝ) ≤ k := by exact_mod_cast (by omega : 2 * (k / 2) ≤ k)
  have h2 : (k : ℝ) + 1 ≤ ((2 * (k / 2) + 2 : ℤ) : ℝ) := by
    exact_mod_cast (by omega : k + 1 ≤ 2 * (k / 2) + 2)
  push_cast at h1 h2
  intro t ⟨ht1, ht2⟩
  simp only [dcell, Set.mem_Ico]
  rw [he]
  constructor <;> nlinarith

lemma dcell_halves (j k : ℤ) : dcell (j - 1) (2 * k) ∪ dcell (j - 1) (2 * k + 1) = dcell j k := by
  have he := two_zpow_sub_one j
  have hpos : (0:ℝ) < 2 ^ (j - 1) := zpow_pos two_pos _
  simp only [dcell]
  have hm : (((2 * k + 1 : ℤ) : ℝ)) * 2 ^ (j - 1) = (((2 * k : ℤ) : ℝ) + 1) * 2 ^ (j - 1) := by
    push_cast; ring
  rw [hm, Set.Ico_union_Ico_eq_Ico (by nlinarith) (by push_cast; nlinarith), he]
  push_cast
  congr 1 <;> ring

lemma dcell_halves_disjoint (j k : ℤ) : Disjoint (dcell (j - 1) (2 * k)) (dcell (j - 1) (2 * k + 1)) :=
  dcell_disjoint (by omega)

lemma iUnion_dcell (j : ℤ) : (⋃ k, dcell j k) = Set.univ :=
  Set.eq_univ_of_forall fun t => Set.mem_iUnion.2 ⟨_, mem_dcell_floor j t⟩

lemma constOnDyadic_pred {j : ℤ} {f : ℝ → ℝ} (hf : ConstOnDyadic j f) :
    ConstOnDyadic (j - 1) f := fun k s hs t ht =>
  hf (k / 2) s (dcell_sub_one_subset j k hs) t (dcell_sub_one_subset j k ht)

lemma constOnDyadic_mono {j j' : ℤ} {f : ℝ → ℝ} (hf : ConstOnDyadic j f) (hj : j' ≤ j) :
    ConstOnDyadic j' f := by
  obtain ⟨n, rfl⟩ : ∃ n : ℕ, j = j' + n := ⟨(j - j').toNat, by omega⟩
  clear hj
  induction n with
  | zero => simpa using hf
  | succ n ih =>
    apply ih
    have := constOnDyadic_pred hf
    rwa [show j' + ((n + 1 : ℕ) : ℤ) - 1 = j' + n by push_cast; ring] at this

lemma constOnDyadic_indicator (j m : ℤ) (c : ℝ) :
    ConstOnDyadic j ((dcell j m).indicator (fun _ => c)) := by
  intro k s hs t ht
  have hs' : s ∈ dcell j k := hs
  have ht' : t ∈ dcell j k := ht
  by_cases hkm : k = m
  · subst hkm
    rw [Set.indicator_of_mem hs', Set.indicator_of_mem ht']
  · have h1 : s ∉ dcell j m := fun h => Set.disjoint_left.1 (dcell_disjoint hkm) hs' h
    have h2 : t ∉ dcell j m := fun h => Set.disjoint_left.1 (dcell_disjoint hkm) ht' h
    rw [Set.indicator_of_notMem h1, Set.indicator_of_notMem h2]

lemma integrable_indicator_dcell (j k : ℤ) (c : ℝ) :
    Integrable ((dcell j k).indicator (fun _ => c)) volume :=
  (integrableOn_const (by rw [volume_dcell]; exact ENNReal.ofReal_ne_top)).integrable_indicator
    (measurableSet_dcell j k)

lemma integral_indicator_dcell (j k : ℤ) (c : ℝ) :
    ∫ t, (dcell j k).indicator (fun _ => c) t = 2 ^ j * c := by
  rw [integral_indicator_const _ (measurableSet_dcell j k), volume_real_dcell, smul_eq_mul]

lemma haarPsi_eq_indicator (u : ℝ) : haarPsi u =
    (Set.Ico (0:ℝ) (1/2)).indicator (fun _ => (1:ℝ)) u -
      (Set.Ico (1/2:ℝ) 1).indicator (fun _ => (1:ℝ)) u := by
  unfold haarPsi
  simp only [Set.indicator_apply, Set.mem_Ico]
  by_cases h1 : 0 ≤ u ∧ u < 1/2
  · have h2 : ¬ (1/2 ≤ u ∧ u < 1) := fun h => by linarith [h.1, h1.2]
    simp only [if_pos h1, if_neg h2]; ring
  · by_cases h2 : 1/2 ≤ u ∧ u < 1
    · simp only [if_neg h1, if_pos h2]; ring
    · simp only [if_neg h1, if_neg h2]; ring

lemma mem_dcell_pred_iff (j m : ℤ) (t : ℝ) :
    t ∈ dcell (j - 1) m ↔ (m : ℝ) ≤ 2 * ((2:ℝ) ^ (-j) * t) ∧ 2 * ((2:ℝ) ^ (-j) * t) < m + 1 := by
  rw [mem_dcell_iff, Int.floor_eq_iff]
  have h : t / 2 ^ (j - 1) = 2 * ((2:ℝ) ^ (-j) * t) := by
    have hpos : (0:ℝ) < 2 ^ (j - 1) := zpow_pos two_pos _
    rw [zpow_neg, two_zpow_sub_one j]
    field_simp
  rw [h]

lemma haarPsiJK_eq_indicator (j k : ℤ) (t : ℝ) : haarPsiJK j k t =
    (2:ℝ) ^ (-(j:ℝ) / 2) * ((dcell (j - 1) (2 * k)).indicator (fun _ => (1:ℝ)) t -
      (dcell (j - 1) (2 * k + 1)).indicator (fun _ => (1:ℝ)) t) := by
  unfold haarPsiJK
  rw [haarPsi_eq_indicator]
  congr 1
  have hA : ((2:ℝ) ^ (-j) * t - k ∈ Set.Ico (0:ℝ) (1/2)) ↔ t ∈ dcell (j - 1) (2 * k) := by
    rw [mem_dcell_pred_iff, Set.mem_Ico]; push_cast
    constructor <;> rintro ⟨h1, h2⟩ <;> constructor <;> linarith
  have hB : ((2:ℝ) ^ (-j) * t - k ∈ Set.Ico (1/2:ℝ) 1) ↔ t ∈ dcell (j - 1) (2 * k + 1) := by
    rw [mem_dcell_pred_iff, Set.mem_Ico]; push_cast
    constructor <;> rintro ⟨h1, h2⟩ <;> constructor <;> linarith
  have e1 : (Set.Ico (0:ℝ) (1/2)).indicator (fun _ => (1:ℝ)) ((2:ℝ) ^ (-j) * t - k) =
      (dcell (j - 1) (2 * k)).indicator (fun _ => (1:ℝ)) t := by
    by_cases h1 : t ∈ dcell (j - 1) (2 * k)
    · rw [Set.indicator_of_mem h1, Set.indicator_of_mem (hA.2 h1)]
    · rw [Set.indicator_of_notMem h1, Set.indicator_of_notMem (mt hA.1 h1)]
  have e2 : (Set.Ico (1/2:ℝ) 1).indicator (fun _ => (1:ℝ)) ((2:ℝ) ^ (-j) * t - k) =
      (dcell (j - 1) (2 * k + 1)).indicator (fun _ => (1:ℝ)) t := by
    by_cases h1 : t ∈ dcell (j - 1) (2 * k + 1)
    · rw [Set.indicator_of_mem h1, Set.indicator_of_mem (hB.2 h1)]
    · rw [Set.indicator_of_notMem h1, Set.indicator_of_notMem (mt hB.1 h1)]
  rw [e1, e2]

lemma constOnDyadic_haarPsiJK (j k : ℤ) : ConstOnDyadic (j - 1) (haarPsiJK j k) := by
  intro m s hs t ht
  rw [haarPsiJK_eq_indicator, haarPsiJK_eq_indicator,
    constOnDyadic_indicator (j - 1) (2 * k) 1 m s hs t ht,
    constOnDyadic_indicator (j - 1) (2 * k + 1) 1 m s hs t ht]

lemma haarPsiJK_eq_zero_of_notMem {j k : ℤ} {t : ℝ} (ht : t ∉ dcell j k) : haarPsiJK j k t = 0 := by
  rw [← dcell_halves j k, Set.mem_union, not_or] at ht
  rw [haarPsiJK_eq_indicator, Set.indicator_of_notMem ht.1, Set.indicator_of_notMem ht.2]
  ring

lemma integral_haarPsiJK (j k : ℤ) : ∫ t, haarPsiJK j k t = 0 := by
  simp_rw [haarPsiJK_eq_indicator]
  rw [integral_const_mul, integral_sub (integrable_indicator_dcell _ _ _)
    (integrable_indicator_dcell _ _ _), integral_indicator_dcell, integral_indicator_dcell]
  ring

lemma rpow_half_mul_self (j : ℤ) :
    (2:ℝ) ^ (-(j:ℝ) / 2) * (2:ℝ) ^ (-(j:ℝ) / 2) = ((2:ℝ) ^ j)⁻¹ := by
  rw [← Real.rpow_add two_pos, show -(j:ℝ) / 2 + -(j:ℝ) / 2 = ((-j : ℤ) : ℝ) by push_cast; ring,
    Real.rpow_intCast, zpow_neg]

lemma haarPsiJK_mul_self (j k : ℤ) (t : ℝ) :
    haarPsiJK j k t * haarPsiJK j k t = ((2:ℝ) ^ j)⁻¹ * (dcell j k).indicator (fun _ => (1:ℝ)) t := by
  have hd := dcell_halves_disjoint j k
  rw [haarPsiJK_eq_indicator]
  by_cases hA : t ∈ dcell (j - 1) (2 * k)
  · have hB : t ∉ dcell (j - 1) (2 * k + 1) := Set.disjoint_left.1 hd hA
    have hC : t ∈ dcell j k := by rw [← dcell_halves]; exact Or.inl hA
    rw [Set.indicator_of_mem hA, Set.indicator_of_notMem hB, Set.indicator_of_mem hC,
      ← rpow_half_mul_self]
    ring
  · by_cases hB : t ∈ dcell (j - 1) (2 * k + 1)
    · have hC : t ∈ dcell j k := by rw [← dcell_halves]; exact Or.inr hB
      rw [Set.indicator_of_notMem hA, Set.indicator_of_mem hB, Set.indicator_of_mem hC,
        ← rpow_half_mul_self]
      ring
    · have hC : t ∉ dcell j k := by rw [← dcell_halves, Set.mem_union]; tauto
      rw [Set.indicator_of_notMem hA, Set.indicator_of_notMem hB, Set.indicator_of_notMem hC]
      ring

lemma integral_haarPsiJK_mul_self (j k : ℤ) : ∫ t, haarPsiJK j k t * haarPsiJK j k t = 1 := by
  simp_rw [haarPsiJK_mul_self]
  rw [integral_const_mul, integral_indicator_dcell, mul_one,
    inv_mul_cancel₀ (zpow_pos two_pos j).ne']

lemma integral_haarPsiJK_mul_of_lt {j j' : ℤ} (k k' : ℤ) (h : j' < j) :
    ∫ t, haarPsiJK j k t * haarPsiJK j' k' t = 0 := by
  have hc : ConstOnDyadic j' (haarPsiJK j k) := constOnDyadic_mono (constOnDyadic_haarPsiJK j k)
    (by omega)
  have hpt : ∀ t, haarPsiJK j k t * haarPsiJK j' k' t =
      haarPsiJK j k ((k' : ℝ) * 2 ^ j') * haarPsiJK j' k' t := by
    intro t
    by_cases ht : t ∈ dcell j' k'
    · rw [hc k' t ht ((k' : ℝ) * 2 ^ j') ⟨le_refl _, by
        have := zpow_pos (two_pos : (0:ℝ) < 2) j'; nlinarith⟩]
    · rw [haarPsiJK_eq_zero_of_notMem ht, mul_zero, mul_zero]
  simp_rw [hpt]
  rw [integral_const_mul, integral_haarPsiJK, mul_zero]

lemma haarPsiJK_mul_of_ne {j k k' : ℤ} (h : k ≠ k') (t : ℝ) :
    haarPsiJK j k t * haarPsiJK j k' t = 0 := by
  by_cases ht : t ∈ dcell j k
  · have ht' : t ∉ dcell j k' := Set.disjoint_left.1 (dcell_disjoint h) ht
    rw [haarPsiJK_eq_zero_of_notMem ht', mul_zero]
  · rw [haarPsiJK_eq_zero_of_notMem ht, zero_mul]

lemma haar_orthonormal_aux (j k j' k' : ℤ) :
    ∫ t, haarPsiJK j k t * haarPsiJK j' k' t =
      if (j, k) = (j', k') then (1 : ℝ) else 0 := by
  rcases lt_trichotomy j' j with h | rfl | h
  · rw [if_neg (by intro e; simp only [Prod.mk.injEq] at e; omega),
      integral_haarPsiJK_mul_of_lt k k' h]
  · by_cases hk : k = k'
    · subst hk
      rw [if_pos rfl, integral_haarPsiJK_mul_self]
    · rw [if_neg (by intro e; simp only [Prod.mk.injEq] at e; omega)]
      simp_rw [haarPsiJK_mul_of_ne hk]
      simp
  · rw [if_neg (by intro e; simp only [Prod.mk.injEq] at e; omega)]
    simp_rw [mul_comm (haarPsiJK j k _)]
    exact integral_haarPsiJK_mul_of_lt k' k h

lemma memLp_comp_mul_left {g : ℝ → ℝ} (hg : MemLp g 2 volume) {c : ℝ} (hc : c ≠ 0) :
    MemLp (fun t => g (c * t)) 2 volume := by
  have h : MemLp g 2 (Measure.map (fun t => c * t) volume) := by
    rw [Real.map_volume_mul_left hc]; exact hg.smul_measure ENNReal.ofReal_ne_top
  exact h.comp_of_map (measurable_const_mul c).aemeasurable

lemma haarView_scale (j : ℤ) (f : ℝ → ℝ) :
    f ∈ haarView j ↔ (fun t => f (2 * t)) ∈ haarView (j - 1) := by
  have he := two_zpow_sub_one j
  have hpos : (0:ℝ) < 2 ^ (j - 1) := zpow_pos two_pos _
  constructor
  · rintro ⟨hm, hc⟩
    refine ⟨memLp_comp_mul_left hm two_ne_zero, fun k s hs t ht => ?_⟩
    obtain ⟨hs1, hs2⟩ := hs
    obtain ⟨ht1, ht2⟩ := ht
    apply hc k <;> rw [he] <;> constructor <;> nlinarith
  · rintro ⟨hm, hc⟩
    refine ⟨?_, fun k s hs t ht => ?_⟩
    · have := memLp_comp_mul_left hm (c := 1 / 2) (by norm_num)
      convert this using 1
      funext t; congr 1; ring
    · obtain ⟨hs1, hs2⟩ := hs
      obtain ⟨ht1, ht2⟩ := ht
      rw [he] at hs1 hs2 ht1 ht2
      have := hc k (s / 2) ⟨by nlinarith, by nlinarith⟩ (t / 2) ⟨by nlinarith, by nlinarith⟩
      simpa [mul_div_cancel₀] using this

lemma haarView_shift (f : ℝ → ℝ) (hf : f ∈ haarView 0) (k : ℤ) :
    (fun t => f (t - k)) ∈ haarView 0 := by
  obtain ⟨hm, hc⟩ := hf
  refine ⟨hm.comp_measurePreserving (measurePreserving_sub_right volume (k:ℝ)),
    fun m s hs t ht => ?_⟩
  simp only [zpow_zero, mul_one, Set.mem_Ico] at hs ht
  apply hc (m - k) <;> simp only [zpow_zero, mul_one, Set.mem_Ico] <;> push_cast <;>
    constructor <;> linarith [hs.1, hs.2, ht.1, ht.2]

lemma haarView_sep (f : ℝ → ℝ) (hf : ∀ j : ℤ, f ∈ haarView j) : f = 0 := by
  funext t
  have hint := (hf 0).1.integrable_sq
  have key : ∀ n : ℕ, f t ^ 2 * 2 ^ n ≤ ∫ s, f s ^ 2 := by
    intro n
    have hc := (hf n).2
    have h1 : ∫ s in dcell n ⌊t / 2 ^ (n:ℤ)⌋, f s ^ 2 = 2 ^ n * f t ^ 2 := by
      rw [setIntegral_congr_fun (measurableSet_dcell _ _) (g := fun _ => f t ^ 2) ?_,
        setIntegral_const, volume_real_dcell, smul_eq_mul, zpow_natCast]
      intro s hs
      simp only
      rw [hc _ s hs t (mem_dcell_floor _ t)]
    calc f t ^ 2 * 2 ^ n = ∫ s in dcell n ⌊t / 2 ^ (n:ℤ)⌋, f s ^ 2 := by rw [h1]; ring
      _ ≤ ∫ s, f s ^ 2 :=
        setIntegral_le_integral hint (Filter.Eventually.of_forall fun s => sq_nonneg _)
  by_contra hne
  have hne' : f t ≠ 0 := by simpa using hne
  have hpos : 0 < f t ^ 2 := lt_of_le_of_ne (sq_nonneg _) (Ne.symm (pow_ne_zero 2 hne'))
  obtain ⟨n, hn⟩ := pow_unbounded_of_one_lt ((∫ s, f s ^ 2) / f t ^ 2) (by norm_num : (1:ℝ) < 2)
  have := key n
  rw [div_lt_iff₀ hpos] at hn
  linarith

lemma haar_density (f : ℝ → ℝ) (hf : MemLp f 2 volume) (ε : ℝ) (hε : 0 < ε) :
    ∃ J : ℤ, ∀ j ≤ J, ∃ g ∈ haarView j, eLpNorm (f - g) 2 volume < ENNReal.ofReal ε := by
  obtain ⟨h, hsupp, hfh, hcont, hmem⟩ := hf.exists_hasCompactSupport_eLpNorm_sub_le
    (by norm_num : (2:ENNReal) ≠ ⊤) (ε := ENNReal.ofReal (ε / 4)) (by simp; linarith)
  obtain ⟨R0, hR0⟩ := hsupp.isBounded.subset_closedBall 0
  set R := max R0 0 with hRdef
  have hR0' : 0 ≤ R := le_max_right _ _
  have hR : ∀ t, R < |t| → h t = 0 := by
    intro t ht
    by_contra hne
    have h1 := hR0 (subset_tsupport _ hne)
    rw [Metric.mem_closedBall, Real.dist_eq, sub_zero] at h1
    have : R0 ≤ R := le_max_left _ _
    linarith
  set η := ε / (4 * (R + 1)) with hη
  have hηpos : 0 < η := by positivity
  obtain ⟨δ, hδ, hδh⟩ := Metric.uniformContinuous_iff.1
    (hsupp.uniformContinuous_of_continuous hcont) η hηpos
  obtain ⟨n, hn⟩ := exists_pow_lt_of_lt_one hδ (by norm_num : (1/2:ℝ) < 1)
  refine ⟨-n, fun j hj => ?_⟩
  have h2j : (2:ℝ) ^ j ≤ (1/2) ^ n := by
    calc (2:ℝ) ^ j ≤ 2 ^ (-(n:ℤ)) := zpow_le_zpow_right₀ (by norm_num) hj
      _ = (1/2) ^ n := by rw [zpow_neg, zpow_natCast, one_div, inv_pow]
  have hjpos : (0:ℝ) < 2 ^ j := zpow_pos two_pos j
  have h2j1 : (2:ℝ) ^ j ≤ 1 := h2j.trans (pow_le_one₀ (by norm_num) (by norm_num))
  set g : ℝ → ℝ := fun t => h (⌊t / 2 ^ j⌋ * 2 ^ j) with hg
  have hfl : ∀ t : ℝ, (⌊t / 2 ^ j⌋ : ℝ) * 2 ^ j ≤ t ∧ t < (⌊t / 2 ^ j⌋ : ℝ) * 2 ^ j + 2 ^ j := by
    intro t
    have := mem_dcell_floor j t
    simp only [dcell, Set.mem_Ico] at this
    constructor <;> nlinarith [this.1, this.2]
  have hgm : Measurable g := hcont.measurable.comp
    (((measurable_of_countable (fun z : ℤ => (z:ℝ))).comp
      (Int.measurable_floor.comp (measurable_id.div_const _))).mul_const _)
  have hdiff : ∀ t, ‖h t - g t‖ ≤ η := by
    intro t
    have := hδh (a := t) (b := ⌊t / 2 ^ j⌋ * 2 ^ j)
      (by rw [Real.dist_eq, abs_lt]; constructor <;> linarith [(hfl t).1, (hfl t).2])
    rw [Real.dist_eq] at this; rw [Real.norm_eq_abs]; exact this.le
  set S := Set.Icc (-(R + 1)) (R + 1) with hS
  have hsupp' : ∀ t, t ∉ S → h t - g t = 0 := by
    intro t ht
    simp only [hS, Set.mem_Icc, not_and_or, not_le] at ht
    have h1 : R < |t| := by
      rw [lt_abs]; rcases ht with ht | ht
      · right; linarith
      · left; linarith
    have h2 : R < |(⌊t / 2 ^ j⌋ : ℝ) * 2 ^ j| := by
      rw [lt_abs]; rcases ht with ht | ht
      · right; linarith [(hfl t).1]
      · left; linarith [(hfl t).2]
    simp only [g, hR t h1, hR _ h2, sub_zero]
  have hind : (fun t => h t - g t) = S.indicator (fun t => h t - g t) := by
    funext t; by_cases ht : t ∈ S
    · rw [Set.indicator_of_mem ht]
    · rw [Set.indicator_of_notMem ht, hsupp' t ht]
  have hSvol : volume S = ENNReal.ofReal (2 * (R + 1)) := by
    rw [hS, Real.volume_Icc]; congr 1; ring
  have : IsFiniteMeasure (volume.restrict S) :=
    isFiniteMeasure_restrict.2 (by rw [hSvol]; exact ENNReal.ofReal_ne_top)
  have hmemd : MemLp (fun t => h t - g t) 2 volume := by
    rw [hind, memLp_indicator_iff_restrict measurableSet_Icc.nullMeasurableSet]
    exact MemLp.of_bound (hcont.measurable.sub hgm).aestronglyMeasurable η
      (Filter.Eventually.of_forall hdiff)
  have hgmem : MemLp g 2 volume := by
    have := hmem.sub hmemd
    convert this using 1; funext t; simp
  have hcg : ConstOnDyadic j g := by
    intro k s hs t ht
    simp only [g]
    rw [(mem_dcell_iff j k s).1 hs, (mem_dcell_iff j k t).1 ht]
  refine ⟨g, ⟨hgmem, hcg⟩, ?_⟩
  have hnorm : eLpNorm (fun t => h t - g t) 2 volume ≤ ENNReal.ofReal (ε / 2) := by
    rw [hind, eLpNorm_indicator_eq_eLpNorm_restrict measurableSet_Icc.nullMeasurableSet]
    refine (eLpNorm_le_of_ae_bound (hcont.measurable.sub hgm).aestronglyMeasurable
      (Filter.Eventually.of_forall hdiff)).trans ?_
    rw [Measure.restrict_apply_univ, hSvol]
    calc ENNReal.ofReal (2 * (R + 1)) ^ (2:ENNReal).toReal⁻¹ * ENNReal.ofReal η
        ≤ ENNReal.ofReal (2 * (R + 1)) * ENNReal.ofReal η := by
          gcongr
          have h1 : (1:ENNReal) ≤ ENNReal.ofReal (2 * (R + 1)) := by
            rw [← ENNReal.ofReal_one]; exact ENNReal.ofReal_le_ofReal (by linarith)
          calc ENNReal.ofReal (2 * (R + 1)) ^ (2:ENNReal).toReal⁻¹
              ≤ ENNReal.ofReal (2 * (R + 1)) ^ (1:ℝ) :=
                ENNReal.rpow_le_rpow_of_exponent_le h1 (by norm_num)
            _ = ENNReal.ofReal (2 * (R + 1)) := ENNReal.rpow_one _
      _ = ENNReal.ofReal (ε / 2) := by
          rw [← ENNReal.ofReal_mul (by linarith)]; congr 1; rw [hη]; field_simp; ring
  have hsplit : f - g = (f - h) + (fun t => h t - g t) := by funext t; simp
  rw [hsplit]
  calc eLpNorm ((f - h) + fun t => h t - g t) 2 volume
      ≤ eLpNorm (f - h) 2 volume + eLpNorm (fun t => h t - g t) 2 volume :=
        eLpNorm_add_le (by norm_num)
    _ ≤ ENNReal.ofReal (ε / 4) + ENNReal.ofReal (ε / 2) := add_le_add hfh hnorm
    _ = ENNReal.ofReal (3 * ε / 4) := by
        rw [← ENNReal.ofReal_add (by linarith) (by linarith)]; congr 1; ring
    _ < ENNReal.ofReal ε := (ENNReal.ofReal_lt_ofReal_iff hε).2 (by linarith)

lemma memLp_haarPsiJK (j k : ℤ) : MemLp (haarPsiJK j k) 2 volume := by
  have hfun : haarPsiJK j k = fun t => (2:ℝ) ^ (-(j:ℝ) / 2) *
      ((dcell (j - 1) (2 * k)).indicator (fun _ => (1:ℝ)) t -
        (dcell (j - 1) (2 * k + 1)).indicator (fun _ => (1:ℝ)) t) :=
    funext (haarPsiJK_eq_indicator j k)
  rw [hfun]
  have hA := memLp_indicator_const (μ := volume) 2 (measurableSet_dcell (j - 1) (2 * k)).nullMeasurableSet
    (1:ℝ) (Or.inr (by rw [volume_dcell]; exact ENNReal.ofReal_ne_top))
  have hB := memLp_indicator_const (μ := volume) 2
    (measurableSet_dcell (j - 1) (2 * k + 1)).nullMeasurableSet
    (1:ℝ) (Or.inr (by rw [volume_dcell]; exact ENNReal.ofReal_ne_top))
  exact (hA.sub hB).const_mul _

/-- The Haar function ψ_{j,k} as an element of L²(ℝ). -/
noncomputable def haarLp (p : ℤ × ℤ) : Lp ℝ 2 (volume : Measure ℝ) :=
  (memLp_haarPsiJK p.1 p.2).toLp (haarPsiJK p.1 p.2)

lemma coeFn_haarLp (p : ℤ × ℤ) : (haarLp p : ℝ → ℝ) =ᵐ[volume] haarPsiJK p.1 p.2 :=
  MemLp.coeFn_toLp _

lemma inner_haarLp (p q : ℤ × ℤ) :
    inner ℝ (haarLp p) (haarLp q) = ∫ t, haarPsiJK p.1 p.2 t * haarPsiJK q.1 q.2 t := by
  rw [L2.inner_def]
  apply integral_congr_ae
  filter_upwards [coeFn_haarLp p, coeFn_haarLp q] with t h1 h2
  rw [h1, h2, RCLike.inner_apply, conj_trivial, mul_comm]

lemma haarLp_orthonormal : Orthonormal ℝ haarLp := by
  classical
  rw [orthonormal_iff_ite]
  rintro ⟨j, k⟩ ⟨j', k'⟩
  rw [inner_haarLp, haar_orthonormal_aux]

lemma integrableOn_Lp_dcell (f : Lp ℝ 2 (volume : Measure ℝ)) (j k : ℤ) :
    IntegrableOn f (dcell j k) volume :=
  (((Lp.memLp f).locallyIntegrable (by norm_num)).integrableOn_isCompact isCompact_Icc).mono_set
    Set.Ico_subset_Icc_self

lemma cell_integral_halves (f : Lp ℝ 2 (volume : Measure ℝ))
    (hf : ∀ j k : ℤ, ∫ t, haarPsiJK j k t * f t = 0) (j k : ℤ) :
    2 * ∫ t in dcell (j - 1) (2 * k), f t = ∫ t in dcell j k, f t ∧
      2 * ∫ t in dcell (j - 1) (2 * k + 1), f t = ∫ t in dcell j k, f t := by
  have hA := integrableOn_Lp_dcell f (j - 1) (2 * k)
  have hB := integrableOn_Lp_dcell f (j - 1) (2 * k + 1)
  have hsum : ∫ t in dcell j k, f t =
      (∫ t in dcell (j - 1) (2 * k), f t) + ∫ t in dcell (j - 1) (2 * k + 1), f t := by
    rw [← dcell_halves, setIntegral_union (dcell_halves_disjoint j k) (measurableSet_dcell _ _) hA hB]
  have heq : (∫ t in dcell (j - 1) (2 * k), f t) = ∫ t in dcell (j - 1) (2 * k + 1), f t := by
    have h0 := hf j k
    have hpt : ∀ t, haarPsiJK j k t * f t = (2:ℝ) ^ (-(j:ℝ) / 2) *
        ((dcell (j - 1) (2 * k)).indicator f t - (dcell (j - 1) (2 * k + 1)).indicator f t) := by
      intro t; rw [haarPsiJK_eq_indicator]
      by_cases h1 : t ∈ dcell (j - 1) (2 * k) <;> by_cases h2 : t ∈ dcell (j - 1) (2 * k + 1) <;>
        simp [Set.indicator_of_mem, Set.indicator_of_notMem, h1, h2]
    simp_rw [hpt] at h0
    rw [integral_const_mul, integral_sub (hA.integrable_indicator (measurableSet_dcell _ _))
      (hB.integrable_indicator (measurableSet_dcell _ _)), integral_indicator (measurableSet_dcell _ _),
      integral_indicator (measurableSet_dcell _ _)] at h0
    have hc : (2:ℝ) ^ (-(j:ℝ) / 2) ≠ 0 := (Real.rpow_pos_of_pos two_pos _).ne'
    have := (mul_eq_zero.1 h0).resolve_left hc
    linarith
  constructor <;> linarith

lemma cell_integral_step (f : Lp ℝ 2 (volume : Measure ℝ))
    (hf : ∀ j k : ℤ, ∫ t, haarPsiJK j k t * f t = 0) (j m : ℤ) :
    2 * ∫ t in dcell (j - 1) m, f t = ∫ t in dcell j (m / 2), f t := by
  obtain ⟨k, hk⟩ : ∃ k, k = m / 2 := ⟨_, rfl⟩
  rw [← hk]
  rcases (by omega : m = 2 * k ∨ m = 2 * k + 1) with hm | hm <;> subst hm
  · exact (cell_integral_halves f hf j k).1
  · exact (cell_integral_halves f hf j k).2

lemma cell_integral_iter (f : Lp ℝ 2 (volume : Measure ℝ))
    (hf : ∀ j k : ℤ, ∫ t, haarPsiJK j k t * f t = 0) (n : ℕ) :
    ∀ j k : ℤ, ∃ k' : ℤ, 2 ^ n * ∫ t in dcell j k, f t = ∫ t in dcell (j + n) k', f t := by
  induction n with
  | zero => intro j k; exact ⟨k, by simp⟩
  | succ n ih =>
    intro j k
    obtain ⟨k', hk'⟩ := ih j k
    refine ⟨k' / 2, ?_⟩
    have := cell_integral_step f hf (j + ((n + 1 : ℕ) : ℤ)) k'
    rw [show j + ((n + 1 : ℕ) : ℤ) - 1 = j + n by push_cast; ring] at this
    rw [← this, ← hk']
    ring

lemma cell_integral_sq_le (f : Lp ℝ 2 (volume : Measure ℝ)) (j k : ℤ) :
    (∫ t in dcell j k, f t) ^ 2 ≤ ‖f‖ ^ 2 * 2 ^ j := by
  have hμ : volume (dcell j k) ≠ ⊤ := by rw [volume_dcell]; exact ENNReal.ofReal_ne_top
  rw [← L2.inner_indicatorConstLp_one (measurableSet_dcell j k) hμ f]
  have h1 := abs_real_inner_le_norm (indicatorConstLp 2 (measurableSet_dcell j k) hμ (1:ℝ)) f
  rw [norm_indicatorConstLp (by norm_num) (by norm_num), volume_real_dcell, ENNReal.toReal_ofNat,
    norm_one, one_mul, ← Real.sqrt_eq_rpow] at h1
  have hj : (0:ℝ) ≤ 2 ^ j := (zpow_pos two_pos j).le
  calc (inner ℝ (indicatorConstLp 2 (measurableSet_dcell j k) hμ (1:ℝ)) f) ^ 2
      = |inner ℝ (indicatorConstLp 2 (measurableSet_dcell j k) hμ (1:ℝ)) f| ^ 2 := (sq_abs _).symm
    _ ≤ (Real.sqrt (2 ^ j) * ‖f‖) ^ 2 := pow_le_pow_left₀ (abs_nonneg _) h1 2
    _ = ‖f‖ ^ 2 * 2 ^ j := by rw [mul_pow, Real.sq_sqrt hj]; ring

lemma cell_integral_zero (f : Lp ℝ 2 (volume : Measure ℝ))
    (hf : ∀ j k : ℤ, ∫ t, haarPsiJK j k t * f t = 0) (j k : ℤ) :
    ∫ t in dcell j k, f t = 0 := by
  set I := ∫ t in dcell j k, f t with hI
  have key : ∀ n : ℕ, I ^ 2 * 2 ^ n ≤ ‖f‖ ^ 2 * 2 ^ j := by
    intro n
    obtain ⟨k', hk'⟩ := cell_integral_iter f hf n j k
    have h := cell_integral_sq_le f (j + n) k'
    rw [← hk', zpow_add₀ two_ne_zero, zpow_natCast] at h
    have h2n : (0:ℝ) < 2 ^ n := by positivity
    refine le_of_mul_le_mul_left ?_ h2n
    have e1 : (2:ℝ) ^ n * (I ^ 2 * 2 ^ n) = (2 ^ n * I) ^ 2 := by ring
    have e2 : (2:ℝ) ^ n * (‖f‖ ^ 2 * 2 ^ j) = ‖f‖ ^ 2 * (2 ^ j * 2 ^ n) := by ring
    rw [e1, e2]; exact h
  by_contra hne
  have hpos : 0 < I ^ 2 := lt_of_le_of_ne (sq_nonneg _) (Ne.symm (pow_ne_zero 2 hne))
  obtain ⟨n, hn⟩ := pow_unbounded_of_one_lt (‖f‖ ^ 2 * 2 ^ j / I ^ 2) (by norm_num : (1:ℝ) < 2)
  rw [div_lt_iff₀ hpos] at hn
  linarith [key n]

lemma integral_mul_haarView_zero (f : Lp ℝ 2 (volume : Measure ℝ))
    (hcell : ∀ j k : ℤ, ∫ t in dcell j k, f t = 0) {j : ℤ} {g : ℝ → ℝ} (hg : g ∈ haarView j) :
    ∫ t, g t * f t = 0 := by
  have hint : Integrable (fun t => g t * f t) volume := hg.1.integrable_mul (Lp.memLp f)
  rw [← setIntegral_univ, ← iUnion_dcell j, integral_iUnion (fun k => measurableSet_dcell j k)
    (fun a b hab => dcell_disjoint hab) (by rw [iUnion_dcell]; exact hint.integrableOn)]
  have : ∀ k, ∫ t in dcell j k, g t * f t = 0 := by
    intro k
    rw [setIntegral_congr_fun (measurableSet_dcell j k) (g := fun t => g (k * 2 ^ j) * f t) ?_,
      integral_const_mul, hcell, mul_zero]
    intro t ht
    simp only
    rw [hg.2 k t ht (k * 2 ^ j) ⟨le_refl _, by
      have := zpow_pos (two_pos : (0:ℝ) < 2) j; nlinarith⟩]
  simp [this]

lemma Lp_eq_zero_of_orth (f : Lp ℝ 2 (volume : Measure ℝ))
    (hf : ∀ j k : ℤ, ∫ t, haarPsiJK j k t * f t = 0) : f = 0 := by
  have hcell := cell_integral_zero f hf
  have key : ∀ ε > 0, ‖f‖ ^ 2 ≤ ‖f‖ * ε := by
    intro ε hε
    obtain ⟨J, hJ⟩ := haar_density f (Lp.memLp f) ε hε
    obtain ⟨g, hg, hfg⟩ := hJ J le_rfl
    set G := hg.1.toLp g
    have hinner : inner ℝ f G = 0 := by
      rw [L2.inner_def, integral_congr_ae (g := fun t => g t * f t) ?_]
      · exact integral_mul_haarView_zero f hcell hg
      filter_upwards [MemLp.coeFn_toLp hg.1] with t ht
      rw [ht, RCLike.inner_apply, conj_trivial]
    have hnorm : ‖f - G‖ ≤ ε := by
      rw [Lp.norm_def, eLpNorm_congr_ae (Lp.coeFn_sub f G),
        eLpNorm_congr_ae ((Filter.EventuallyEq.refl _ _).sub (MemLp.coeFn_toLp hg.1))]
      exact (ENNReal.le_ofReal_iff_toReal_le (ne_top_of_lt hfg) hε.le).1 hfg.le
    calc ‖f‖ ^ 2 = inner ℝ f f := (real_inner_self_eq_norm_sq f).symm
      _ = inner ℝ f (f - G) := by rw [inner_sub_right, hinner, sub_zero]
      _ ≤ ‖f‖ * ‖f - G‖ := real_inner_le_norm _ _
      _ ≤ ‖f‖ * ε := mul_le_mul_of_nonneg_left hnorm (norm_nonneg _)
  have h0 : ‖f‖ = 0 := by
    by_contra hne
    have hpos : 0 < ‖f‖ := lt_of_le_of_ne (norm_nonneg _) (Ne.symm hne)
    have := key (‖f‖ / 2) (by positivity)
    nlinarith
  exact norm_eq_zero.1 h0

lemma haarLp_orth : (Submodule.span ℝ (Set.range haarLp))ᗮ = ⊥ := by
  rw [Submodule.eq_bot_iff]
  intro f hf
  apply Lp_eq_zero_of_orth f
  intro j k
  have h := (Submodule.mem_orthogonal _ f).1 hf (haarLp (j, k)) (Submodule.subset_span ⟨(j, k), rfl⟩)
  rw [L2.inner_def] at h
  rw [← h]
  apply integral_congr_ae
  filter_upwards [coeFn_haarLp (j, k)] with t ht
  rw [ht, RCLike.inner_apply, conj_trivial, mul_comm]

#print axioms mem_dcell_iff
#print axioms mem_dcell_floor
#print axioms measurableSet_dcell
#print axioms volume_dcell
#print axioms volume_real_dcell
#print axioms dcell_disjoint
#print axioms two_zpow_sub_one
#print axioms dcell_sub_one_subset
#print axioms dcell_halves
#print axioms dcell_halves_disjoint
#print axioms iUnion_dcell
#print axioms constOnDyadic_pred
#print axioms constOnDyadic_mono
#print axioms constOnDyadic_indicator
#print axioms integrable_indicator_dcell
#print axioms integral_indicator_dcell
#print axioms haarPsi_eq_indicator
#print axioms mem_dcell_pred_iff
#print axioms haarPsiJK_eq_indicator
#print axioms constOnDyadic_haarPsiJK
#print axioms haarPsiJK_eq_zero_of_notMem
#print axioms integral_haarPsiJK
#print axioms rpow_half_mul_self
#print axioms haarPsiJK_mul_self
#print axioms integral_haarPsiJK_mul_self
#print axioms integral_haarPsiJK_mul_of_lt
#print axioms haarPsiJK_mul_of_ne
#print axioms haar_orthonormal_aux
#print axioms memLp_comp_mul_left
#print axioms haarView_scale
#print axioms haarView_shift
#print axioms haarView_sep
#print axioms haar_density
#print axioms memLp_haarPsiJK
#print axioms coeFn_haarLp
#print axioms inner_haarLp
#print axioms haarLp_orthonormal
#print axioms integrableOn_Lp_dcell
#print axioms cell_integral_halves
#print axioms cell_integral_step
#print axioms cell_integral_iter
#print axioms cell_integral_sq_le
#print axioms cell_integral_zero
#print axioms integral_mul_haarView_zero
#print axioms Lp_eq_zero_of_orth
#print axioms haarLp_orth

/-- The card's main claim: the Haar functions ψ_{j,k}, for all whole numbers j and k, form an
orthonormal basis of all finite-energy signals on the line. That is, there is a Hilbert basis of
L²(ℝ), indexed by the pairs (j, k), whose member (j, k) is the signal ψ_{j,k}; so every
finite-energy signal is the sum, converging in energy, of its pieces ⟨f, ψ_{j,k}⟩ ψ_{j,k}. -/
theorem haar_functions_form_orthonormal_basis :
    ∃ b : HilbertBasis (ℤ × ℤ) ℝ (Lp ℝ 2 (volume : Measure ℝ)),
      ∀ p : ℤ × ℤ, (b p : ℝ → ℝ) =ᵐ[volume] haarPsiJK p.1 p.2 := by
  refine ⟨HilbertBasis.mkOfOrthogonalEqBot haarLp_orthonormal haarLp_orth, fun p => ?_⟩
  rw [HilbertBasis.coe_mkOfOrthogonalEqBot]
  exact coeFn_haarLp p

/-- Steps 1 and 2: every Haar function has energy 1, and any two different ones are perpendicular:
∫ ψ_{j,k}(t) ψ_{j',k'}(t) dt over the whole line is 1 when (j, k) = (j', k') and 0 otherwise. -/
theorem haar_functions_orthonormal (j k j' k' : ℤ) :
    ∫ t, haarPsiJK j k t * haarPsiJK j' k' t =
      if (j, k) = (j', k') then (1 : ℝ) else 0 := by
  exact haar_orthonormal_aux j k j' k'

/-- The multiresolution axioms for Haar's ladder of views V_j:
1. nested, V_j ⊆ V_(j−1);
2. scaling, f(t) is in V_j exactly when f(2t) is in V_(j−1);
3. shifts, if f(t) is in V_0 so is f(t − k) for every whole number k;
4. separation, only the zero signal lies in every V_j;
5. density, every finite-energy signal is a limit in energy of signals from V_j as j → −∞:
   for every tolerance ε > 0 there is a level J such that at every level j ≤ J some signal of V_j
   is within ε of it in energy. -/
theorem haar_views_are_multiresolution :
    (∀ j : ℤ, haarView j ⊆ haarView (j - 1)) ∧
    (∀ (j : ℤ) (f : ℝ → ℝ), f ∈ haarView j ↔ (fun t => f (2 * t)) ∈ haarView (j - 1)) ∧
    (∀ f ∈ haarView 0, ∀ k : ℤ, (fun t => f (t - k)) ∈ haarView 0) ∧
    (∀ f : ℝ → ℝ, (∀ j : ℤ, f ∈ haarView j) → f = 0) ∧
    (∀ f : ℝ → ℝ, MemLp f 2 volume → ∀ ε : ℝ, 0 < ε → ∃ J : ℤ, ∀ j ≤ J,
      ∃ g ∈ haarView j, eLpNorm (f - g) 2 volume < ENNReal.ofReal ε) := by
  exact ⟨fun j f hf => ⟨hf.1, constOnDyadic_mono hf.2 (by omega)⟩, haarView_scale,
    haarView_shift, haarView_sep, haar_density⟩

-- The bakery's eight days, in dollars: 820, 760, 900, 980, 1240, 1300, 640, 600.
-- Level 1 averages 790, 940, 1270, 620 and half-differences 30, −40, −30, 20.
example : ((820 + 760) / 2, (900 + 980) / 2, (1240 + 1300) / 2, (640 + 600) / 2)
    = ((790 : ℤ), (940 : ℤ), (1270 : ℤ), (620 : ℤ)) := by norm_num
example : ((820 - 760) / 2, (900 - 980) / 2, (1240 - 1300) / 2, (640 - 600) / 2)
    = ((30 : ℤ), (-40 : ℤ), (-30 : ℤ), (20 : ℤ)) := by norm_num
-- Level 2: averages 865, 945 and half-differences −75, 325. Level 3: average 905, half-difference −40.
example : ((790 + 940) / 2, (1270 + 620) / 2, (790 - 940) / 2, (1270 - 620) / 2)
    = ((865 : ℤ), (945 : ℤ), (-75 : ℤ), (325 : ℤ)) := by norm_num
example : ((865 + 945) / 2, (865 - 945) / 2) = ((905 : ℤ), (-40 : ℤ)) := by norm_num
-- Total takings 7240, and the energy by days, 7,017,600 dollars² per day.
example : (820 + 760 + 900 + 980 + 1240 + 1300 + 640 + 600 : ℤ) = 7240 := by norm_num
example : (820 ^ 2 + 760 ^ 2 + 900 ^ 2 + 980 ^ 2 + 1240 ^ 2 + 1300 ^ 2 + 640 ^ 2 + 600 ^ 2 : ℤ)
    = 7017600 := by norm_num
-- Energy by pieces, each coefficient squared being 2^j times the average or half-difference squared:
-- coarse 8 · 905² = 7240²/8 = 6,552,200; level 3 8 · 40² = 12,800;
-- level 2 4 · (75² + 325²) = 445,000; level 1 2 · (30² + 40² + 30² + 20²) = 7,600.
example : (8 * 905 ^ 2 : ℤ) = 6552200 ∧ (7240 ^ 2 / 8 : ℤ) = 6552200 := by norm_num
example : (8 * 40 ^ 2 : ℤ) = 12800 ∧ (4 * (75 ^ 2 + 325 ^ 2) : ℤ) = 445000 ∧
    (2 * (30 ^ 2 + 40 ^ 2 + 30 ^ 2 + 20 ^ 2) : ℤ) = 7600 := by norm_num
-- The energy ledger: pieces against days.
example : (6552200 + 12800 + 445000 + 7600 : ℤ) = 7017600 := by norm_num
-- The level-2 coefficients 2 · (−75) = −150 and 2 · 325 = 650.
example : (2 * (-75) : ℤ) = -150 ∧ (2 * 325 : ℤ) = 650 := by norm_num
-- What breaks: the averages and half-differences used as coordinates give 935,675, not 7,017,600.
example : (905 ^ 2 + 40 ^ 2 + 75 ^ 2 + 325 ^ 2 + 30 ^ 2 + 40 ^ 2 + 30 ^ 2 + 20 ^ 2 : ℤ) = 935675 := by
  norm_num

#print axioms haar_functions_form_orthonormal_basis
#print axioms haar_functions_orthonormal
#print axioms haar_views_are_multiresolution
