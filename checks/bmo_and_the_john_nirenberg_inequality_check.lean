-- BMO: a function on the line whose mean oscillation is at most M on every interval strays from its average by more than λ on a share of each interval at most e·exp(-λ/(2eM)), and ln|t| has average ln a - 1 and mean oscillation 2/e on every [0, a].
import Mathlib.MeasureTheory.Integral.Average
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.MeasureTheory.Covering.OneDim
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Algebra.Order.Floor.Semifield
import Mathlib.Tactic.NormNum

open MeasureTheory Set Real

/-- The average of `f` over `[l, r]` differs from a constant `c` by at most the average of
`|f - c|`. -/
theorem jn_abs_avg_sub_le (f : ℝ → ℝ) (c l r : ℝ) (hlr : l < r) (hf : IntegrableOn f (Icc l r)) :
    |(⨍ t in Icc l r, f t) - c| ≤ ⨍ t in Icc l r, |f t - c| := by
  have hv : volume.real (Icc l r) = r - l := Real.volume_real_Icc_of_le hlr.le
  have hpos : 0 < r - l := by linarith
  have key : (⨍ t in Icc l r, f t) - c = ⨍ t in Icc l r, (f t - c) := by
    rw [setAverage_eq, setAverage_eq, integral_sub hf (integrableOn_const measure_Icc_lt_top.ne), setIntegral_const,
      smul_eq_mul, smul_eq_mul, smul_eq_mul, hv]
    field_simp
  rw [key, setAverage_eq, setAverage_eq, smul_eq_mul, smul_eq_mul, abs_mul, hv,
    abs_of_pos (inv_pos.mpr hpos)]
  gcongr
  simpa [Real.norm_eq_abs] using norm_integral_le_integral_norm (μ := volume.restrict (Icc l r))
    (fun t => f t - c)

/-- Dyadic cells: if `x` lies in the cell `j` of generation `n` of `[a, b]`, then
`j = ⌊(x - a) / ((b - a) / 2^n)⌋₊`. -/
theorem jn_cell_index (a b : ℝ) (hab : a < b) (n j : ℕ) (x : ℝ)
    (hx : x ∈ Ico (a + j * ((b - a) / 2 ^ n)) (a + (j + 1) * ((b - a) / 2 ^ n))) :
    j = ⌊(x - a) / ((b - a) / 2 ^ n)⌋₊ := by
  have hS : 0 < (b - a) / 2 ^ n := div_pos (by linarith) (by positivity)
  symm
  rw [Nat.floor_eq_iff (div_nonneg (by nlinarith [hx.1, (Nat.cast_nonneg j : (0:ℝ) ≤ j)]) hS.le)]
  constructor
  · rw [le_div_iff₀ hS]; linarith [hx.1]
  · rw [div_lt_iff₀ hS]; linarith [hx.2]

/-- Every point of `[a, b)` lies in some cell of every generation. -/
theorem jn_cell_exists (a b : ℝ) (hab : a < b) (n : ℕ) (x : ℝ) (hx : x ∈ Ico a b) :
    ∃ j : ℕ, j < 2 ^ n ∧ x ∈ Ico (a + j * ((b - a) / 2 ^ n)) (a + (j + 1) * ((b - a) / 2 ^ n)) := by
  have hS : 0 < (b - a) / 2 ^ n := div_pos (by linarith) (by positivity)
  have hy0 : 0 ≤ (x - a) / ((b - a) / 2 ^ n) := div_nonneg (by linarith [hx.1]) hS.le
  refine ⟨⌊(x - a) / ((b - a) / 2 ^ n)⌋₊, ?_, ?_, ?_⟩
  · rw [Nat.floor_lt hy0, div_lt_iff₀ hS]
    push_cast
    field_simp
    linarith [hx.2]
  · have := Nat.floor_le hy0
    rw [le_div_iff₀ hS] at this
    linarith
  · have := Nat.lt_floor_add_one ((x - a) / ((b - a) / 2 ^ n))
    rw [div_lt_iff₀ hS] at this
    linarith

/-- Cells are nested: the generation-`m` cell holding `x` is the ancestor `j / 2^(n - m)` of the
generation-`n` cell `j` holding `x`. -/
theorem jn_cell_nest (a b : ℝ) (hab : a < b) (m i n j : ℕ) (x : ℝ) (hmn : m ≤ n)
    (hi : x ∈ Ico (a + i * ((b - a) / 2 ^ m)) (a + (i + 1) * ((b - a) / 2 ^ m)))
    (hj : x ∈ Ico (a + j * ((b - a) / 2 ^ n)) (a + (j + 1) * ((b - a) / 2 ^ n))) :
    i = j / 2 ^ (n - m) := by
  rw [jn_cell_index a b hab m i x hi, jn_cell_index a b hab n j x hj, ← Nat.floor_div_natCast]
  congr 1
  obtain ⟨d, rfl⟩ := Nat.exists_eq_add_of_le hmn
  have hba : (b - a) ≠ 0 := by linarith
  simp only [Nat.add_sub_cancel_left, pow_add, Nat.cast_pow, Nat.cast_ofNat]
  field_simp


open scoped ENNReal in
/-- One stopping-time step: if every interval has share at most `C` above level `lam`, then
every interval has measure at most `C · |I| / e` above level `lam + 2eM`. -/
theorem jn_step (f : ℝ → ℝ) (hf : ∀ a b : ℝ, IntegrableOn f (Icc a b)) (M : ℝ) (hM0 : 0 < M)
    (hM : ∀ a b : ℝ, a < b → ⨍ t in Icc a b, |f t - ⨍ s in Icc a b, f s| ≤ M)
    (lam : ℝ) (hlam : 0 ≤ lam) (C : ℝ≥0∞)
    (hC : ∀ c d : ℝ, c < d →
      volume {t ∈ Icc c d | lam < |f t - ⨍ s in Icc c d, f s|} ≤ C * volume (Icc c d))
    (a b : ℝ) (hab : a < b) :
    volume {t ∈ Icc a b | lam + 2 * exp 1 * M < |f t - ⨍ s in Icc a b, f s|}
      ≤ C * ENNReal.ofReal ((b - a) / exp 1) := by
  obtain ⟨e, he⟩ : ∃ e, e = exp 1 := ⟨_, rfl⟩
  rw [← he]
  have he1 : 1 < e := he ▸ one_lt_exp_iff.mpr one_pos
  obtain ⟨fI, hfI⟩ : ∃ fI, fI = ⨍ s in Icc a b, f s := ⟨_, rfl⟩
  rw [← hfI]
  obtain ⟨g, hg⟩ : ∃ g : ℝ → ℝ, g = fun t => |f t - fI| := ⟨_, rfl⟩
  have hg0 : ∀ t, 0 ≤ g t := fun t => by rw [hg]; exact abs_nonneg _
  have hgi : ∀ c d, IntegrableOn g (Icc c d) := fun c d => by
    rw [hg]; exact ((hf c d).sub (integrableOn_const measure_Icc_lt_top.ne)).abs
  obtain ⟨L, hL⟩ : ∃ L : ℕ → ℕ → ℝ, L = fun (n j : ℕ) => a + (j : ℝ) * ((b - a) / 2 ^ n) := ⟨_, rfl⟩
  obtain ⟨R, hR⟩ : ∃ R : ℕ → ℕ → ℝ, R = fun (n j : ℕ) => a + ((j : ℝ) + 1) * ((b - a) / 2 ^ n) := ⟨_, rfl⟩
  have hSpos : ∀ n : ℕ, 0 < (b - a) / 2 ^ n := fun n => div_pos (by linarith) (by positivity)
  have hRL : ∀ n j, R n j - L n j = (b - a) / 2 ^ n := fun n j => by rw [hL, hR]; ring
  have hLR : ∀ n j, L n j < R n j := fun n j => by linarith [hRL n j, hSpos n]
  have hvol : ∀ n j, volume.real (Icc (L n j) (R n j)) = (b - a) / 2 ^ n := fun n j => by
    rw [Real.volume_real_Icc_of_le (hLR n j).le, hRL]
  have hsub : ∀ n j, j < 2 ^ n → Icc (L n j) (R n j) ⊆ Icc a b := by
    intro n j hj
    apply Icc_subset_Icc
    · rw [hL]; exact le_add_of_nonneg_right (mul_nonneg (Nat.cast_nonneg _) (hSpos n).le)
    · rw [hR]; simp only
      have h1 : ((j : ℝ) + 1) ≤ 2 ^ n := by exact_mod_cast hj
      calc a + (j + 1) * ((b - a) / 2 ^ n) ≤ a + 2 ^ n * ((b - a) / 2 ^ n) := by
            gcongr
        _ = b := by field_simp; ring
  obtain ⟨bad, hbad⟩ : ∃ bad : ℕ → ℕ → Prop,
      bad = fun n j => e * M < ⨍ t in Icc (L n j) (R n j), g t := ⟨_, rfl⟩
  obtain ⟨stop, hstop⟩ : ∃ stop : ℕ × ℕ → Prop,
      stop = fun p => p.2 < 2 ^ p.1 ∧ bad p.1 p.2 ∧ ∀ m < p.1, ¬ bad m (p.2 / 2 ^ (p.1 - m)) :=
    ⟨_, rfl⟩
  classical
  obtain ⟨T, hT⟩ : ∃ T : ℕ × ℕ → Set ℝ,
      T = fun p => if stop p then Ico (L p.1 p.2) (R p.1 p.2) else ∅ := ⟨_, rfl⟩
  have hnest : ∀ x m i n j, x ∈ Ico (L m i) (R m i) → x ∈ Ico (L n j) (R n j) → m ≤ n →
      i = j / 2 ^ (n - m) := by
    intro x m i n j hi hj hmn
    rw [hL, hR] at hi hj
    exact jn_cell_nest a b hab m i n j x hmn hi hj
  have hexists : ∀ x ∈ Ico a b, ∀ n, ∃ j : ℕ, j < 2 ^ n ∧ x ∈ Ico (L n j) (R n j) := by
    intro x hx n
    rw [hL, hR]
    exact jn_cell_exists a b hab n x hx
  have hmemT : ∀ p x, x ∈ T p ↔ stop p ∧ x ∈ Ico (L p.1 p.2) (R p.1 p.2) := by
    intro p x; rw [hT]; simp only; split_ifs with h <;> simp [h]
  have hdisj : Pairwise (Function.onFun Disjoint T) := by
    intro p q hpq
    rw [Function.onFun, Set.disjoint_left]
    intro x hxp hxq
    obtain ⟨hsp, hxp⟩ := (hmemT p x).1 hxp
    obtain ⟨hsq, hxq⟩ := (hmemT q x).1 hxq
    rw [hstop] at hsp hsq
    obtain ⟨_, hbp, hmp⟩ := hsp
    obtain ⟨_, hbq, hmq⟩ := hsq
    apply hpq
    rcases lt_trichotomy p.1 q.1 with h | h | h
    · have hn := hnest x p.1 p.2 q.1 q.2 hxp hxq h.le
      rw [hn] at hbp
      exact absurd hbp (hmq p.1 h)
    · have hn := hnest x p.1 p.2 q.1 q.2 hxp hxq h.le
      rw [h, Nat.sub_self, pow_zero, Nat.div_one] at hn
      exact Prod.ext h hn
    · have hn := hnest x q.1 q.2 p.1 p.2 hxq hxp h.le
      rw [hn] at hbq
      exact absurd hbq (hmp q.1 h)
  have hTmeas : ∀ p, MeasurableSet (T p) := by
    intro p; rw [hT]; simp only; split_ifs <;> simp [measurableSet_Ico]
  have hpar : ∀ p, stop p → |(⨍ t in Icc (L p.1 p.2) (R p.1 p.2), f t) - fI| ≤ 2 * e * M := by
    rintro ⟨n, j⟩ hs
    rw [hstop] at hs
    obtain ⟨hj, hb, hm⟩ := hs
    obtain ⟨n, rfl⟩ : ∃ n', n = n' + 1 := by
      rcases n with _ | n
      · exfalso
        have hj0 : j = 0 := by simpa using hj
        subst hj0
        rw [hbad] at hb
        simp only at hb
        have hL0 : L 0 0 = a := by rw [hL]; simp
        have hR0 : R 0 0 = b := by rw [hR]; simp
        rw [hL0, hR0] at hb
        have := hM a b hab
        rw [← hfI] at this
        simp only [hg] at hb
        nlinarith
      · exact ⟨n, rfl⟩
    have hpg := hm n (Nat.lt_succ_self n)
    rw [Nat.add_sub_cancel_left, pow_one, hbad] at hpg
    simp only [not_lt] at hpg
    have hSn := hSpos n
    have hDP : Icc (L (n+1) j) (R (n+1) j) ⊆ Icc (L n (j/2)) (R n (j/2)) := by
      apply Icc_subset_Icc
      · rw [hL]; simp only
        have h2 : ((j / 2 : ℕ) : ℝ) * 2 ≤ j := by exact_mod_cast Nat.div_mul_le_self j 2
        rw [pow_succ]
        calc a + ↑(j / 2) * ((b - a) / 2 ^ n)
            = a + (↑(j / 2) * 2) * ((b - a) / (2 ^ n * 2)) := by field_simp
          _ ≤ a + j * ((b - a) / (2 ^ n * 2)) := by gcongr
      · rw [hR]; simp only
        have h2 : (j : ℝ) + 1 ≤ (((j / 2 : ℕ) : ℝ) + 1) * 2 := by
          have : j + 1 ≤ (j / 2 + 1) * 2 := by omega
          exact_mod_cast this
        rw [pow_succ]
        calc a + (↑j + 1) * ((b - a) / (2 ^ n * 2))
            ≤ a + ((↑(j / 2) + 1) * 2) * ((b - a) / (2 ^ n * 2)) := by gcongr
          _ = a + (↑(j / 2) + 1) * ((b - a) / 2 ^ n) := by field_simp
    have hint : ∫ t in Icc (L (n+1) j) (R (n+1) j), g t
        ≤ ∫ t in Icc (L n (j/2)) (R n (j/2)), g t :=
      setIntegral_mono_set (hgi _ _) (Filter.Eventually.of_forall (fun t => hg0 t))
        (Filter.Eventually.of_forall hDP)
    have havg : ⨍ t in Icc (L (n+1) j) (R (n+1) j), g t ≤ 2 * e * M := by
      rw [setAverage_eq, smul_eq_mul, hvol] at hpg ⊢
      rw [pow_succ]
      calc ((b - a) / (2 ^ n * 2))⁻¹ * ∫ t in Icc (L (n+1) j) (R (n+1) j), g t
          ≤ ((b - a) / (2 ^ n * 2))⁻¹ * ∫ t in Icc (L n (j/2)) (R n (j/2)), g t := by
            gcongr
        _ = 2 * (((b - a) / 2 ^ n)⁻¹ * ∫ t in Icc (L n (j/2)) (R n (j/2)), g t) := by
            field_simp
        _ ≤ 2 * (e * M) := by gcongr
        _ = 2 * e * M := by ring
    calc |(⨍ t in Icc (L (n+1) j) (R (n+1) j), f t) - fI|
        ≤ ⨍ t in Icc (L (n+1) j) (R (n+1) j), |f t - fI| :=
          jn_abs_avg_sub_le f fI _ _ (hLR _ _) (hf _ _)
      _ = ⨍ t in Icc (L (n+1) j) (R (n+1) j), g t := by rw [hg]
      _ ≤ 2 * e * M := havg
  have hgood : ∀ x ∈ Ico a b, (∀ p, x ∉ T p) → ∀ n j, x ∈ Ico (L n j) (R n j) → ¬ bad n j := by
    intro x hx hnot n
    induction n using Nat.strong_induction_on with
    | _ n ih =>
      intro j hxj hb
      obtain ⟨j', hj'lt, hxj'⟩ := hexists x hx n
      have hjj : j' = j / 2 ^ (n - n) := hnest x n j' n j hxj' hxj le_rfl
      rw [Nat.sub_self, pow_zero, Nat.div_one] at hjj
      subst hjj
      apply hnot (n, j')
      rw [hmemT]
      refine ⟨?_, hxj⟩
      rw [hstop]
      refine ⟨hj'lt, hb, fun m hm => ?_⟩
      obtain ⟨i, -, hxi⟩ := hexists x hx m
      have := hnest x m i n j' hxi hxj hm.le
      rw [← this]
      exact ih m hm i hxi
  have hae : ∀ᵐ x, x ∈ Ico a b → (∀ n j, x ∈ Ico (L n j) (R n j) → ¬ bad n j) → g x ≤ e * M := by
    have hgloc : LocallyIntegrable g volume := by
      rw [locallyIntegrable_iff]
      intro k hk
      obtain ⟨r, hr⟩ := hk.bddBelow
      obtain ⟨s, hs⟩ := hk.bddAbove
      exact (hgi r s).mono_set (fun t ht => ⟨hr ht, hs ht⟩)
    filter_upwards [IsUnifLocDoublingMeasure.ae_tendsto_average volume hgloc 1] with x hx hxI hgd
    choose J hJlt hJ using hexists x hxI
    have hlim := hx (l := Filter.atTop) (fun n => (L n (J n) + R n (J n)) / 2)
      (fun n => (R n (J n) - L n (J n)) / 2) ?_ ?_
    · simp only [← Real.Icc_eq_closedBall] at hlim
      refine le_of_tendsto' hlim (fun n => ?_)
      have := hgd n (J n) (hJ n)
      rw [hbad] at this
      exact not_lt.mp this
    · simp only [hRL]
      have h0 : Filter.Tendsto (fun n : ℕ => (b - a) / 2 ^ n / 2) Filter.atTop (nhds 0) := by
        have := (tendsto_pow_atTop_nhds_zero_of_lt_one (by norm_num : (0:ℝ) ≤ 1/2)
          (by norm_num : (1/2:ℝ) < 1)).const_mul ((b - a) / 2)
        rw [mul_zero] at this
        refine this.congr (fun n => ?_)
        field_simp
        rw [← mul_pow]; norm_num
      exact tendsto_nhdsWithin_iff.mpr ⟨h0, Filter.Eventually.of_forall fun n => by
        have := hSpos n; simp only [mem_Ioi]; positivity⟩
    · refine Filter.Eventually.of_forall fun n => ?_
      rw [one_mul, ← Real.Icc_eq_closedBall]
      exact Ico_subset_Icc_self (hJ n)
  obtain ⟨N, hN⟩ : ∃ N : Set ℝ, N = {x | x ∈ Ico a b ∧
      (∀ n j, x ∈ Ico (L n j) (R n j) → ¬ bad n j) ∧ e * M < g x} := ⟨_, rfl⟩
  have hN0 : volume N = 0 := by
    rw [ae_iff] at hae
    refine measure_mono_null (fun x hx => ?_) hae
    rw [hN] at hx
    obtain ⟨h1, h2, h3⟩ := hx
    simp only [mem_ofPred_eq]
    intro h
    exact absurd (h h1 h2) (not_le.mpr h3)
  obtain ⟨U, hU⟩ : ∃ U : ℕ × ℕ → Set ℝ, U = fun p => if stop p then
      {t ∈ Icc (L p.1 p.2) (R p.1 p.2) | lam < |f t - ⨍ s in Icc (L p.1 p.2) (R p.1 p.2), f s|}
      else ∅ := ⟨_, rfl⟩
  have hcover : {t ∈ Icc a b | lam + 2 * e * M < |f t - fI|} ⊆ ({b} ∪ N) ∪ ⋃ p, U p := by
    rintro t ⟨htI, htl⟩
    by_cases htb : t = b
    · left; left; exact htb
    have htI' : t ∈ Ico a b := ⟨htI.1, lt_of_le_of_ne htI.2 htb⟩
    by_cases hex : ∃ p, t ∈ T p
    · obtain ⟨p, hp⟩ := hex
      obtain ⟨hsp, htp⟩ := (hmemT p t).1 hp
      right
      refine mem_iUnion.2 ⟨p, ?_⟩
      rw [hU]
      simp only [hsp, ↓reduceIte]
      refine ⟨Ico_subset_Icc_self htp, ?_⟩
      have h1 := hpar p hsp
      have h2 := abs_sub_le (f t) (⨍ s in Icc (L p.1 p.2) (R p.1 p.2), f s) fI
      linarith
    · push Not at hex
      left; right
      rw [hN]
      refine ⟨htI', hgood t htI' hex, ?_⟩
      rw [hg]
      have : 0 < e * M := by positivity
      linarith
  have hUle : ∀ p, volume (U p) ≤ C * volume (T p) := by
    intro p
    rw [hU, hT]
    simp only
    split_ifs with h
    · rw [Real.volume_Ico, ← Real.volume_Icc]; exact hC _ _ (hLR _ _)
    · simp
  have h1 : volume {t ∈ Icc a b | lam + 2 * e * M < |f t - fI|} ≤ C * volume (⋃ p, T p) := by
    calc _ ≤ volume (({b} ∪ N) ∪ ⋃ p, U p) := measure_mono hcover
      _ ≤ volume ({b} ∪ N) + volume (⋃ p, U p) := measure_union_le _ _
      _ ≤ (volume {b} + volume N) + ∑' p, volume (U p) :=
          add_le_add (measure_union_le _ _) (measure_iUnion_le _)
      _ = ∑' p, volume (U p) := by rw [hN0, measure_singleton, zero_add, zero_add]
      _ ≤ ∑' p, C * volume (T p) := tsum_le_tsum hUle
      _ = C * volume (⋃ p, T p) := by rw [ENNReal.tsum_mul_left, measure_iUnion hdisj hTmeas]
  have hTsub : (⋃ p, T p) ⊆ Icc a b := by
    refine iUnion_subset fun p x hx => ?_
    obtain ⟨hs, hx⟩ := (hmemT p x).1 hx
    rw [hstop] at hs
    exact hsub _ _ hs.1 (Ico_subset_Icc_self hx)
  have hTlint : ∀ p, ENNReal.ofReal (e * M) * volume (T p) ≤ ∫⁻ t in T p, ENNReal.ofReal (g t) := by
    intro p
    by_cases hs : stop p
    · have hTp : T p = Ico (L p.1 p.2) (R p.1 p.2) := by rw [hT]; simp only [hs, ↓reduceIte]
      rw [hTp, setLIntegral_congr Ico_ae_eq_Icc, ← ofReal_integral_eq_lintegral_ofReal (hgi _ _)
        (Filter.Eventually.of_forall fun t => hg0 t), Real.volume_Ico,
        ← ENNReal.ofReal_mul (by positivity)]
      apply ENNReal.ofReal_le_ofReal
      have hb := hs
      rw [hstop] at hb
      have hb2 := hb.2.1
      rw [hbad] at hb2
      rw [setAverage_eq, smul_eq_mul, hvol] at hb2
      rw [hRL]
      have := hSpos p.1
      rw [lt_inv_mul_iff₀ this] at hb2
      linarith
    · have hTp : T p = ∅ := by rw [hT]; simp only [hs, ↓reduceIte]
      simp [hTp]
  have h2 : ENNReal.ofReal (e * M) * volume (⋃ p, T p) ≤ ENNReal.ofReal (M * (b - a)) := by
    calc _ = ∑' p, ENNReal.ofReal (e * M) * volume (T p) := by
          rw [measure_iUnion hdisj hTmeas, ENNReal.tsum_mul_left]
      _ ≤ ∑' p, ∫⁻ t in T p, ENNReal.ofReal (g t) := tsum_le_tsum hTlint
      _ = ∫⁻ t in ⋃ p, T p, ENNReal.ofReal (g t) := (lintegral_iUnion hTmeas hdisj _).symm
      _ ≤ ∫⁻ t in Icc a b, ENNReal.ofReal (g t) := lintegral_mono_set hTsub
      _ = ENNReal.ofReal (∫ t in Icc a b, g t) :=
          (ofReal_integral_eq_lintegral_ofReal (hgi a b)
            (Filter.Eventually.of_forall fun t => hg0 t)).symm
      _ ≤ ENNReal.ofReal (M * (b - a)) := by
        apply ENNReal.ofReal_le_ofReal
        have := hM a b hab
        rw [← hfI, setAverage_eq, smul_eq_mul, Real.volume_real_Icc_of_le hab.le,
          inv_mul_le_iff₀ (by linarith)] at this
        simp only [hg]
        linarith
  have h3 : volume (⋃ p, T p) ≤ ENNReal.ofReal ((b - a) / e) := by
    have hpos : ENNReal.ofReal (e * M) ≠ 0 := by
      rw [ne_eq, ENNReal.ofReal_eq_zero, not_le]; positivity
    rw [← ENNReal.mul_le_mul_iff_right hpos ENNReal.ofReal_ne_top,
      ← ENNReal.ofReal_mul (by positivity)]
    convert h2 using 2
    field_simp
  calc _ ≤ C * volume (⋃ p, T p) := h1
    _ ≤ C * ENNReal.ofReal ((b - a) / e) := by gcongr

/-- Iterating the step `k` times: above level `2eMk + μ` the measure is at most `e^(-k) |I|`. -/
theorem jn_iterate (f : ℝ → ℝ) (hf : ∀ a b : ℝ, IntegrableOn f (Icc a b)) (M : ℝ) (hM0 : 0 < M)
    (hM : ∀ a b : ℝ, a < b → ⨍ t in Icc a b, |f t - ⨍ s in Icc a b, f s| ≤ M) (k : ℕ) :
    ∀ μ : ℝ, 0 ≤ μ → ∀ c d : ℝ, c < d →
      volume {t ∈ Icc c d | 2 * exp 1 * M * k + μ < |f t - ⨍ s in Icc c d, f s|}
        ≤ ENNReal.ofReal (exp (-(k : ℝ))) * volume (Icc c d) := by
  induction k with
  | zero =>
    intro μ hμ c d hcd
    simp only [Nat.cast_zero, mul_zero, zero_add, neg_zero, exp_zero, ENNReal.ofReal_one, one_mul]
    exact measure_mono (fun t ht => ht.1)
  | succ k ih =>
    intro μ hμ c d hcd
    have hstep := jn_step f hf M hM0 hM (2 * exp 1 * M * k + μ) (by positivity) _ (ih μ hμ) c d hcd
    have heq : 2 * exp 1 * M * ((k + 1 : ℕ) : ℝ) + μ = (2 * exp 1 * M * k + μ) + 2 * exp 1 * M := by
      push_cast; ring
    rw [heq]
    refine hstep.trans (le_of_eq ?_)
    rw [Real.volume_Icc, ← ENNReal.ofReal_mul (exp_pos _).le, ← ENNReal.ofReal_mul (exp_pos _).le]
    congr 1
    push_cast
    rw [show -((k : ℝ) + 1) = -k + -1 by ring, exp_add, exp_neg 1]
    ring

/-- The average over `[a, b]` is the interval integral divided by `b - a`. -/
theorem jn_setAverage_Icc_eq_intervalIntegral (g : ℝ → ℝ) (a b : ℝ) (hab : a < b) :
    ⨍ t in Icc a b, g t = (b - a)⁻¹ * ∫ t in a..b, g t := by
  rw [setAverage_eq, smul_eq_mul, intervalIntegral.integral_of_le hab.le,
    integral_Icc_eq_integral_Ioc, Real.volume_real_Icc_of_le hab.le]

/-- The John–Nirenberg inequality on the line. Let f have a finite average on every interval
(it is integrable on every [a, b]), and let M bound its mean oscillation on every interval:
for all a < b, the average over [a, b] of |f(t) − f_I|, where f_I is the average of f over
I = [a, b], is at most M. (The least such M is the BMO norm ‖f‖_BMO, so f is in BMO.)
Then for every interval I = [a, b] and every level λ > 0, the share of I on which
|f(t) − f_I| > λ is at most e · exp(−λ / (2e M)). -/
theorem john_nirenberg_inequality
    (f : ℝ → ℝ) (hf : ∀ a b : ℝ, IntegrableOn f (Icc a b))
    (M : ℝ)
    (hM : ∀ a b : ℝ, a < b →
      ⨍ t in Icc a b, |f t - ⨍ s in Icc a b, f s| ≤ M)
    (a b : ℝ) (hab : a < b) (lam : ℝ) (hlam : 0 < lam) :
    volume.real {t ∈ Icc a b | lam < |f t - ⨍ s in Icc a b, f s|} / (b - a)
      ≤ exp 1 * exp (-(lam / (2 * exp 1 * M))) := by
  have hle : volume.real {t ∈ Icc a b | lam < |f t - ⨍ s in Icc a b, f s|} ≤ b - a := by
    calc _ ≤ volume.real (Icc a b) := measureReal_mono (Set.sep_subset _ _) measure_Icc_lt_top.ne
      _ = b - a := Real.volume_real_Icc_of_le hab.le
  by_cases hM0 : M ≤ 0
  · have h1 : 1 ≤ exp 1 * exp (-(lam / (2 * exp 1 * M))) := by
      have : lam / (2 * exp 1 * M) ≤ 0 :=
        div_nonpos_of_nonneg_of_nonpos hlam.le (by nlinarith [exp_pos 1])
      rw [← exp_add]
      apply one_le_exp
      linarith
    have h2 : volume.real {t ∈ Icc a b | lam < |f t - ⨍ s in Icc a b, f s|} / (b - a) ≤ 1 := by
      rw [div_le_one (by linarith)]
      exact hle
    linarith
  push Not at hM0
  have hc : 0 < 2 * exp 1 * M := by positivity
  obtain ⟨k, hkdef⟩ : ∃ k : ℕ, k = ⌊lam / (2 * exp 1 * M)⌋₊ := ⟨_, rfl⟩
  have hk : (k : ℝ) ≤ lam / (2 * exp 1 * M) := hkdef ▸ Nat.floor_le (by positivity)
  have hk2 : lam / (2 * exp 1 * M) < k + 1 := hkdef ▸ Nat.lt_floor_add_one _
  have hμ : 0 ≤ lam - 2 * exp 1 * M * k := by
    rw [le_div_iff₀ hc] at hk; linarith
  have hmain := jn_iterate f hf M hM0 hM k _ hμ a b hab
  rw [show 2 * exp 1 * M * k + (lam - 2 * exp 1 * M * k) = lam by ring] at hmain
  have hreal : volume.real {t ∈ Icc a b | lam < |f t - ⨍ s in Icc a b, f s|}
      ≤ exp (-(k : ℝ)) * (b - a) := by
    have hfin : ENNReal.ofReal (exp (-(k : ℝ))) * volume (Icc a b) ≠ ⊤ := by
      rw [Real.volume_Icc]
      exact ENNReal.mul_ne_top ENNReal.ofReal_ne_top ENNReal.ofReal_ne_top
    have := ENNReal.toReal_mono hfin hmain
    rw [Real.volume_Icc, ← ENNReal.ofReal_mul (exp_pos _).le,
      ENNReal.toReal_ofReal (mul_nonneg (exp_pos _).le (by linarith))] at this
    exact this
  rw [div_le_iff₀ (by linarith)]
  calc _ ≤ exp (-(k : ℝ)) * (b - a) := hreal
    _ ≤ exp 1 * exp (-(lam / (2 * exp 1 * M))) * (b - a) := by
      gcongr
      rw [← exp_add]
      apply exp_le_exp.mpr
      linarith

/-- The average of ln|t| on [0, a] is ln a − 1, for every a > 0; on [0, 1] it is −1.
So zooming in on 0 only shifts the logarithm down. -/
theorem average_log_abs_Icc_zero
    (a : ℝ) (ha : 0 < a) :
    ⨍ t in Icc 0 a, log |t| = log a - 1 := by
  rw [jn_setAverage_Icc_eq_intervalIntegral _ _ _ ha]
  simp only [log_abs, integral_log]
  field_simp
  ring

/-- The mean oscillation of ln|t| on [0, a] is 2/e, the same for every a > 0:
the average over [0, a] of |ln|t| − (its average on [0, a])| equals 2/e. -/
theorem mean_oscillation_log_abs_Icc_zero
    (a : ℝ) (ha : 0 < a) :
    ⨍ t in Icc 0 a, abs (log |t| - ⨍ s in Icc 0 a, log |s|) = 2 / exp 1 := by
  rw [average_log_abs_Icc_zero a ha, jn_setAverage_Icc_eq_intervalIntegral _ _ _ ha]
  set c := a / exp 1 with hc
  have hc0 : 0 < c := div_pos ha (exp_pos 1)
  have hca : c < a := div_lt_self ha (one_lt_exp_iff.mpr one_pos)
  have hlogc : log c = log a - 1 := by rw [hc, log_div ha.ne' (exp_pos 1).ne', log_exp]
  have hint : ∀ u v : ℝ, IntervalIntegrable (fun t => |log |t| - (log a - 1)|) volume u v := by
    intro u v
    simp only [log_abs]
    exact (intervalIntegral.intervalIntegrable_log'.sub intervalIntegrable_const).abs
  have key : ∀ u v : ℝ, ∫ t in u..v, (log t - (log a - 1)) =
      v * log v - u * log u - v + u - (v - u) * (log a - 1) := by
    intro u v
    rw [intervalIntegral.integral_sub intervalIntegral.intervalIntegrable_log' intervalIntegrable_const,
      integral_log, intervalIntegral.integral_const, smul_eq_mul]
  rw [← intervalIntegral.integral_add_adjacent_intervals (hint 0 c) (hint c a)]
  have h1 : ∫ t in (0:ℝ)..c, |log |t| - (log a - 1)| = ∫ t in (0:ℝ)..c, -(log t - (log a - 1)) := by
    refine intervalIntegral.integral_congr_ae (Filter.Eventually.of_forall fun t ht => ?_)
    rw [uIoc_of_le hc0.le] at ht
    rw [log_abs, abs_of_nonpos]
    have := log_le_log ht.1 ht.2
    linarith
  have h2 : ∫ t in c..a, |log |t| - (log a - 1)| = ∫ t in c..a, (log t - (log a - 1)) := by
    refine intervalIntegral.integral_congr (fun t ht => ?_)
    rw [uIcc_of_le hca.le] at ht
    rw [log_abs, abs_of_nonneg]
    have := log_le_log hc0 ht.1
    linarith
  rw [h1, h2, intervalIntegral.integral_neg, key, key, hlogc]
  simp only [zero_mul, sub_zero, add_zero]
  have : c * exp 1 = a := by rw [hc]; field_simp
  rw [← this]
  field_simp
  ring

-- The grid of Step 2: intervals with ends at the 251 points -2 + k/50 (k = 0 to 250), one per pair
-- of ends i < j, number 31,375.
example : Nat.choose 251 2 = 31375 := by norm_num [Nat.choose_two_right]

-- The stopping-time boxes of Step 4: generation k has length 16^(-k), so lengths
-- 1/16, 1/256, 1/4096, each 16 times smaller than the last.
example : ((1 : ℚ) / 16) ^ 2 = 1 / 256 ∧ ((1 : ℚ) / 16) ^ 3 = 1 / 4096 := by norm_num

#print axioms jn_abs_avg_sub_le
#print axioms jn_cell_index
#print axioms jn_cell_exists
#print axioms jn_cell_nest
#print axioms jn_step
#print axioms jn_iterate
#print axioms jn_setAverage_Icc_eq_intervalIntegral
#print axioms john_nirenberg_inequality
#print axioms average_log_abs_Icc_zero
#print axioms mean_oscillation_log_abs_Icc_zero
