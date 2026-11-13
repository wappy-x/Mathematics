-- Riemann meets Lebesgue: a bounded Riemann-integrable function on a closed interval is Lebesgue integrable with the same value, a bounded function is Riemann integrable exactly when its discontinuities have length zero, and on [a, ∞) Lebesgue integrability means the improper integral of |f| is finite, with the integrals then agreeing.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib

open Set MeasureTheory Filter Topology

/-- A partition of `[a, b]` into `n` strips: the cuts `a = t 0 < t 1 < ... < t n = b`. -/
def IsPartition (a b : ℝ) (n : ℕ) (t : Fin (n + 1) → ℝ) : Prop :=
  StrictMono t ∧ t 0 = a ∧ t (Fin.last n) = b

/-- The lower sum: each strip's lowest value (the infimum of `f` on the strip) times its width. -/
noncomputable def lowerSum (f : ℝ → ℝ) (n : ℕ) (t : Fin (n + 1) → ℝ) : ℝ :=
  ∑ k : Fin n, sInf (f '' Icc (t k.castSucc) (t k.succ)) * (t k.succ - t k.castSucc)

/-- The upper sum: each strip's highest value (the supremum of `f` on the strip) times its width. -/
noncomputable def upperSum (f : ℝ → ℝ) (n : ℕ) (t : Fin (n + 1) → ℝ) : ℝ :=
  ∑ k : Fin n, sSup (f '' Icc (t k.castSucc) (t k.succ)) * (t k.succ - t k.castSucc)

/-- `I` is the Riemann integral of `f` from `a` to `b`: the one number between every lower sum
and every upper sum. -/
def HasRiemannIntegral (f : ℝ → ℝ) (a b I : ℝ) : Prop :=
  (∀ (n : ℕ) (t : Fin (n + 1) → ℝ), IsPartition a b n t →
      lowerSum f n t ≤ I ∧ I ≤ upperSum f n t) ∧
    ∀ J : ℝ, (∀ (n : ℕ) (t : Fin (n + 1) → ℝ), IsPartition a b n t →
      lowerSum f n t ≤ J ∧ J ≤ upperSum f n t) → J = I

/-- `f` is Riemann integrable on `[a, b]`: exactly one number lies between all lower and upper sums. -/
def RiemannIntegrable (f : ℝ → ℝ) (a b : ℝ) : Prop :=
  ∃ I, HasRiemannIntegral f a b I

open Classical in
/-- The Riemann integral `∫_a^b f(x) dx` when it exists (and `0` otherwise). -/
noncomputable def riemannIntegral (f : ℝ → ℝ) (a b : ℝ) : ℝ :=
  if h : RiemannIntegrable f a b then h.choose else 0

/-! Helper lemmas. A "step function" for a partition `t` and heights `c` is
`x ↦ ∑ k, (Ioc (t k.castSucc) (t k.succ)).indicator (fun _ => c k) x`: height `c k` on strip `k`. -/

lemma rl_part_bounds {a b : ℝ} {n : ℕ} {t : Fin (n + 1) → ℝ} (ht : IsPartition a b n t)
    (i : Fin (n + 1)) : a ≤ t i ∧ t i ≤ b := by
  obtain ⟨hm, h0, hl⟩ := ht
  constructor
  · rw [← h0]; exact hm.monotone (Fin.zero_le i)
  · rw [← hl]; exact hm.monotone (Fin.le_last i)

lemma rl_inf_sup {f : ℝ → ℝ} {a b M : ℝ} (hM : ∀ x ∈ Icc a b, |f x| ≤ M) {S : Set ℝ}
    (hS : S ⊆ Icc a b) {y : ℝ} (hy : y ∈ S) :
    sInf (f '' S) ≤ f y ∧ f y ≤ sSup (f '' S) ∧ -M ≤ sInf (f '' S) ∧ sSup (f '' S) ≤ M := by
  have hbb : BddBelow (f '' S) := ⟨-M, by
    rintro _ ⟨z, hz, rfl⟩; exact (abs_le.1 (hM z (hS hz))).1⟩
  have hba : BddAbove (f '' S) := ⟨M, by
    rintro _ ⟨z, hz, rfl⟩; exact (abs_le.1 (hM z (hS hz))).2⟩
  have hne : (f '' S).Nonempty := ⟨f y, y, hy, rfl⟩
  refine ⟨csInf_le hbb ⟨y, hy, rfl⟩, le_csSup hba ⟨y, hy, rfl⟩, ?_, ?_⟩
  · exact le_csInf hne (by rintro _ ⟨z, hz, rfl⟩; exact (abs_le.1 (hM z (hS hz))).1)
  · exact csSup_le hne (by rintro _ ⟨z, hz, rfl⟩; exact (abs_le.1 (hM z (hS hz))).2)

lemma rl_step_measurable {n : ℕ} (t : Fin (n + 1) → ℝ) (c : Fin n → ℝ) :
    Measurable (fun x => ∑ k : Fin n, (Ioc (t k.castSucc) (t k.succ)).indicator (fun _ => c k) x) :=
  Finset.measurable_sum _ (fun _ _ => measurable_const.indicator measurableSet_Ioc)

lemma rl_step_integrable {n : ℕ} (t : Fin (n + 1) → ℝ) (c : Fin n → ℝ) :
    Integrable (fun x => ∑ k : Fin n, (Ioc (t k.castSucc) (t k.succ)).indicator (fun _ => c k) x)
      volume :=
  integrable_finsetSum _ (fun _ _ => (integrable_indicator_iff measurableSet_Ioc).2
    (integrableOn_const measure_Ioc_lt_top.ne))

lemma rl_step_integral {n : ℕ} {t : Fin (n + 1) → ℝ} (hm : Monotone t) (c : Fin n → ℝ) :
    ∫ x, (∑ k : Fin n, (Ioc (t k.castSucc) (t k.succ)).indicator (fun _ => c k) x) =
      ∑ k : Fin n, c k * (t k.succ - t k.castSucc) := by
  rw [integral_finsetSum _ (fun k _ => (integrable_indicator_iff measurableSet_Ioc).2
    (integrableOn_const measure_Ioc_lt_top.ne))]
  refine Finset.sum_congr rfl (fun k _ => ?_)
  rw [integral_indicator_const _ measurableSet_Ioc,
    Real.volume_real_Ioc_of_le (hm (Fin.castSucc_le_succ k)), smul_eq_mul, mul_comm]

lemma rl_step_eq {n : ℕ} {t : Fin (n + 1) → ℝ} (hm : StrictMono t) (c : Fin n → ℝ) (k : Fin n)
    {x : ℝ} (hx : x ∈ Ioo (t k.castSucc) (t k.succ)) :
    (∑ j : Fin n, (Ioc (t j.castSucc) (t j.succ)).indicator (fun _ => c j) x) = c k := by
  rw [Finset.sum_eq_single k]
  · exact indicator_of_mem (Ioo_subset_Ioc_self hx) _
  · intro j _ hjk
    apply indicator_of_notMem
    intro hj
    rcases lt_or_gt_of_ne hjk with h | h
    · have : t j.succ ≤ t k.castSucc := hm.monotone (Fin.succ_le_castSucc_iff.2 h)
      linarith [hj.2, hx.1]
    · have : t k.succ ≤ t j.castSucc := hm.monotone (Fin.succ_le_castSucc_iff.2 h)
      linarith [hj.1, hx.2]
  · intro h; exact absurd (Finset.mem_univ k) h

lemma rl_step_out {a b : ℝ} {n : ℕ} {t : Fin (n + 1) → ℝ} (ht : IsPartition a b n t)
    (c : Fin n → ℝ) {x : ℝ} (hx : x ∉ Icc a b) :
    (∑ j : Fin n, (Ioc (t j.castSucc) (t j.succ)).indicator (fun _ => c j) x) = 0 := by
  refine Finset.sum_eq_zero (fun j _ => indicator_of_notMem (fun hj => hx ?_) _)
  have h1 := rl_part_bounds ht j.castSucc
  have h2 := rl_part_bounds ht j.succ
  exact ⟨by linarith [hj.1], by linarith [hj.2]⟩

lemma rl_exists_strip {a b : ℝ} {n : ℕ} {t : Fin (n + 1) → ℝ} (ht : IsPartition a b n t)
    {x : ℝ} (hx : x ∈ Ioo a b) (hxt : x ∉ range t) :
    ∃ k : Fin n, x ∈ Ioo (t k.castSucc) (t k.succ) := by
  classical
  obtain ⟨hm, h0, hl⟩ := ht
  let S := Finset.univ.filter (fun i : Fin (n + 1) => t i < x)
  have hS : S.Nonempty := ⟨0, by simp [S, h0, hx.1]⟩
  have hiS : S.max' hS ∈ S := S.max'_mem hS
  have hix : t (S.max' hS) < x := (Finset.mem_filter.1 hiS).2
  have hil : S.max' hS ≠ Fin.last n := by
    intro h; rw [h, hl] at hix; linarith [hx.2]
  refine ⟨(S.max' hS).castPred hil, ?_, ?_⟩
  · rw [Fin.castSucc_castPred]; exact hix
  · have hle : x ≤ t ((S.max' hS).castPred hil).succ := by
      by_contra hlt
      rw [not_le] at hlt
      have hmem : ((S.max' hS).castPred hil).succ ∈ S := Finset.mem_filter.2 ⟨Finset.mem_univ _, hlt⟩
      have h1 := S.le_max' _ hmem
      have h3 := Fin.castSucc_lt_succ (i := (S.max' hS).castPred hil)
      rw [Fin.castSucc_castPred] at h3
      exact absurd h1 (not_le.2 h3)
    exact lt_of_le_of_ne hle (fun h => hxt ⟨_, h.symm⟩)

lemma rl_step_cases {a b : ℝ} {n : ℕ} {t : Fin (n + 1) → ℝ} (ht : IsPartition a b n t)
    (c : Fin n → ℝ) {x : ℝ} (hxt : x ∉ range t) :
    (x ∉ Icc a b ∧
        (∑ j : Fin n, (Ioc (t j.castSucc) (t j.succ)).indicator (fun _ => c j) x) = 0) ∨
      (∃ k : Fin n, x ∈ Ioo (t k.castSucc) (t k.succ) ∧
        (∑ j : Fin n, (Ioc (t j.castSucc) (t j.succ)).indicator (fun _ => c j) x) = c k) := by
  by_cases hx : x ∈ Icc a b
  · right
    have hxa : x ≠ a := fun h => hxt ⟨0, ht.2.1.trans h.symm⟩
    have hxb : x ≠ b := fun h => hxt ⟨Fin.last n, ht.2.2.trans h.symm⟩
    obtain ⟨k, hk⟩ := rl_exists_strip ht
      ⟨lt_of_le_of_ne hx.1 (Ne.symm hxa), lt_of_le_of_ne hx.2 hxb⟩ hxt
    exact ⟨k, hk, rl_step_eq ht.1 c k hk⟩
  · left; exact ⟨hx, rl_step_out ht c hx⟩

/-- Off the cut points, the lower step function lies below `f` and the upper one above it,
and both are bounded by `M` on `[a, b]` and vanish outside. -/
lemma rl_step_bounds {f : ℝ → ℝ} {a b M : ℝ} (hM : ∀ x ∈ Icc a b, |f x| ≤ M) {n : ℕ}
    {t : Fin (n + 1) → ℝ} (ht : IsPartition a b n t) {x : ℝ} (hxt : x ∉ range t) :
    (∑ j : Fin n, (Ioc (t j.castSucc) (t j.succ)).indicator
        (fun _ => sInf (f '' Icc (t j.castSucc) (t j.succ))) x) ≤ (Icc a b).indicator f x ∧
      (Icc a b).indicator f x ≤ (∑ j : Fin n, (Ioc (t j.castSucc) (t j.succ)).indicator
        (fun _ => sSup (f '' Icc (t j.castSucc) (t j.succ))) x) ∧
      |∑ j : Fin n, (Ioc (t j.castSucc) (t j.succ)).indicator
        (fun _ => sInf (f '' Icc (t j.castSucc) (t j.succ))) x| ≤
          (Icc a b).indicator (fun _ => M) x ∧
      |∑ j : Fin n, (Ioc (t j.castSucc) (t j.succ)).indicator
        (fun _ => sSup (f '' Icc (t j.castSucc) (t j.succ))) x| ≤
          (Icc a b).indicator (fun _ => M) x := by
  rcases rl_step_cases ht (fun j => sInf (f '' Icc (t j.castSucc) (t j.succ))) hxt with
    ⟨hx, hL⟩ | ⟨k, hk, hL⟩
  · have hU := rl_step_out ht (fun j => sSup (f '' Icc (t j.castSucc) (t j.succ))) hx
    rw [hL, hU, indicator_of_notMem hx, indicator_of_notMem hx]
    simp
  · have hU := rl_step_eq ht.1 (fun j => sSup (f '' Icc (t j.castSucc) (t j.succ))) k hk
    have hS : Icc (t k.castSucc) (t k.succ) ⊆ Icc a b :=
      Icc_subset_Icc (rl_part_bounds ht _).1 (rl_part_bounds ht _).2
    have hxS : x ∈ Icc (t k.castSucc) (t k.succ) := Ioo_subset_Icc_self hk
    have hx : x ∈ Icc a b := hS hxS
    obtain ⟨h1, h2, h3, h4⟩ := rl_inf_sup hM hS hxS
    have hfx := abs_le.1 (hM x hx)
    rw [hL, hU, indicator_of_mem hx, indicator_of_mem hx]
    refine ⟨h1, h2, abs_le.2 ⟨h3, by linarith⟩, abs_le.2 ⟨by linarith, h4⟩⟩

/-- If every strip is at most `h` wide and `f` moves by at most `ε` within `h` of `x`, the step
functions at `x` are within `ε` of `f x`. -/
lemma rl_step_close {f : ℝ → ℝ} {a b M : ℝ} (hM : ∀ x ∈ Icc a b, |f x| ≤ M) {n : ℕ}
    {t : Fin (n + 1) → ℝ} (ht : IsPartition a b n t) {h ε : ℝ}
    (hw : ∀ k : Fin n, t k.succ - t k.castSucc ≤ h) {x : ℝ} (hx : x ∈ Icc a b)
    (hxt : x ∉ range t) (hc : ∀ y ∈ Icc a b, |y - x| ≤ h → |f y - f x| ≤ ε) :
    |(∑ j : Fin n, (Ioc (t j.castSucc) (t j.succ)).indicator
        (fun _ => sInf (f '' Icc (t j.castSucc) (t j.succ))) x) - f x| ≤ ε ∧
      |(∑ j : Fin n, (Ioc (t j.castSucc) (t j.succ)).indicator
        (fun _ => sSup (f '' Icc (t j.castSucc) (t j.succ))) x) - f x| ≤ ε := by
  rcases rl_step_cases ht (fun j => sInf (f '' Icc (t j.castSucc) (t j.succ))) hxt with
    ⟨hx', _⟩ | ⟨k, hk, hL⟩
  · exact absurd hx hx'
  · have hU := rl_step_eq ht.1 (fun j => sSup (f '' Icc (t j.castSucc) (t j.succ))) k hk
    have hS : Icc (t k.castSucc) (t k.succ) ⊆ Icc a b :=
      Icc_subset_Icc (rl_part_bounds ht _).1 (rl_part_bounds ht _).2
    have hxS : x ∈ Icc (t k.castSucc) (t k.succ) := Ioo_subset_Icc_self hk
    obtain ⟨h1, h2, -, -⟩ := rl_inf_sup hM hS hxS
    have hne : (f '' Icc (t k.castSucc) (t k.succ)).Nonempty := ⟨f x, x, hxS, rfl⟩
    have hwk := hw k
    have hnear : ∀ y ∈ Icc (t k.castSucc) (t k.succ), |f y - f x| ≤ ε := by
      intro y hy
      refine hc y (hS hy) (abs_le.2 ⟨?_, ?_⟩)
      · linarith [hy.1, hxS.2]
      · linarith [hy.2, hxS.1]
    have hlo : f x - ε ≤ sInf (f '' Icc (t k.castSucc) (t k.succ)) :=
      le_csInf hne (by rintro _ ⟨y, hy, rfl⟩; linarith [(abs_le.1 (hnear y hy)).1])
    have hhi : sSup (f '' Icc (t k.castSucc) (t k.succ)) ≤ f x + ε :=
      csSup_le hne (by rintro _ ⟨y, hy, rfl⟩; linarith [(abs_le.1 (hnear y hy)).2])
    rw [hL, hU]
    exact ⟨abs_le.2 ⟨by linarith, by linarith⟩, abs_le.2 ⟨by linarith, by linarith⟩⟩

lemma rl_unif_part {a b : ℝ} (hab : a < b) {n : ℕ} (hn : 0 < n) :
    IsPartition a b n (fun i : Fin (n + 1) => a + ((i : ℕ) : ℝ) * ((b - a) / n)) := by
  have hp : 0 < (b - a) / n := div_pos (by linarith) (by exact_mod_cast hn)
  refine ⟨fun i j hij => ?_, by simp, ?_⟩
  · have : ((i : ℕ) : ℝ) < ((j : ℕ) : ℝ) := by exact_mod_cast hij
    simp only
    nlinarith
  · simp only [Fin.val_last]
    have : (n : ℝ) ≠ 0 := by exact_mod_cast hn.ne'
    field_simp
    ring

#print axioms rl_part_bounds
#print axioms rl_inf_sup
#print axioms rl_step_measurable
#print axioms rl_step_integrable
#print axioms rl_step_integral
#print axioms rl_step_eq
#print axioms rl_step_out
#print axioms rl_exists_strip
#print axioms rl_step_cases
#print axioms rl_step_bounds
#print axioms rl_step_close
#print axioms rl_unif_part

/-- If the discontinuities have length zero, `f` is Lebesgue integrable and its Lebesgue integral
is its Riemann integral: the lower and upper sums of the even partitions both converge to it. -/
lemma rl_main_of_null {f : ℝ → ℝ} {a b : ℝ} (hab : a < b)
    (hbdd : ∃ M, ∀ x ∈ Icc a b, |f x| ≤ M)
    (hD : volume {x | x ∈ Icc a b ∧ ¬ ContinuousWithinAt f (Icc a b) x} = 0) :
    IntegrableOn f (Icc a b) volume ∧ HasRiemannIntegral f a b (∫ x in Icc a b, f x) := by
  obtain ⟨M, hM⟩ := hbdd
  have hM0 : 0 ≤ M := (abs_nonneg _).trans (hM a (left_mem_Icc.2 hab.le))
  let u : (n : ℕ) → Fin (n + 1) → ℝ := fun n i => a + ((i : ℕ) : ℝ) * ((b - a) / n)
  have hu : ∀ n, 0 < n → IsPartition a b n (u n) := fun n hn => rl_unif_part hab hn
  have huw : ∀ n (k : Fin n), u n k.succ - u n k.castSucc = (b - a) / n := by
    intro n k; simp only [u, Fin.val_succ, Fin.val_castSucc]; push_cast; ring
  let L : ℕ → ℝ → ℝ := fun n x => ∑ j : Fin n, (Ioc (u n j.castSucc) (u n j.succ)).indicator
        (fun _ => sInf (f '' Icc (u n j.castSucc) (u n j.succ))) x
  let U : ℕ → ℝ → ℝ := fun n x => ∑ j : Fin n, (Ioc (u n j.castSucc) (u n j.succ)).indicator
        (fun _ => sSup (f '' Icc (u n j.castSucc) (u n j.succ))) x
  let F : ℝ → ℝ := (Icc a b).indicator f
  let G : ℝ → ℝ := (Icc a b).indicator (fun _ => M)
  let N : Set ℝ := {x | x ∈ Icc a b ∧ ¬ ContinuousWithinAt f (Icc a b) x} ∪ ⋃ n, range (u n)
  have hN : volume N = 0 :=
    measure_union_null hD (measure_iUnion_null (fun n => (finite_range (u n)).measure_zero _))
  have hNae : ∀ᵐ x ∂volume, x ∉ N := measure_eq_zero_iff_ae_notMem.1 hN
  have hconv : ∀ x ∉ N, Tendsto (fun n => L n x) atTop (𝓝 (F x)) ∧
      Tendsto (fun n => U n x) atTop (𝓝 (F x)) := by
    intro x hxN
    have hxu : ∀ n, x ∉ range (u n) := fun n h => hxN (Or.inr (mem_iUnion.2 ⟨n, h⟩))
    by_cases hx : x ∈ Icc a b
    · have hcont : ContinuousWithinAt f (Icc a b) x := by
        by_contra h; exact hxN (Or.inl ⟨hx, h⟩)
      have hFx : F x = f x := indicator_of_mem hx f
      rw [hFx]
      rw [Metric.continuousWithinAt_iff] at hcont
      have key : ∀ ε > 0, ∃ N0 : ℕ, ∀ n ≥ N0, |L n x - f x| ≤ ε ∧ |U n x - f x| ≤ ε := by
        intro ε hε
        obtain ⟨δ, hδ, hδf⟩ := hcont ε hε
        obtain ⟨N0, hN0⟩ := exists_nat_gt ((b - a) / δ)
        refine ⟨N0, fun n hn => ?_⟩
        have hnN : (N0 : ℝ) ≤ n := by exact_mod_cast hn
        have hn0 : (0 : ℝ) < n :=
          lt_of_lt_of_le (lt_of_le_of_lt (div_nonneg (by linarith) hδ.le) hN0) hnN
        have hnpos : 0 < n := by exact_mod_cast hn0
        have hh : (b - a) / n < δ := by
          rw [div_lt_iff₀ hn0]; rw [div_lt_iff₀ hδ] at hN0
          nlinarith
        refine rl_step_close hM (hu n hnpos) (h := (b - a) / n) (fun k => (huw n k).le) hx
          (hxu n) ?_
        intro y hy hyx
        have := hδf hy (by rw [Real.dist_eq]; linarith)
        rw [Real.dist_eq] at this; exact this.le
      constructor
      · rw [Metric.tendsto_atTop]
        intro ε hε
        obtain ⟨N0, hN0⟩ := key (ε / 2) (by linarith)
        exact ⟨N0, fun n hn => by rw [Real.dist_eq]; linarith [(hN0 n hn).1]⟩
      · rw [Metric.tendsto_atTop]
        intro ε hε
        obtain ⟨N0, hN0⟩ := key (ε / 2) (by linarith)
        exact ⟨N0, fun n hn => by rw [Real.dist_eq]; linarith [(hN0 n hn).2]⟩
    · have hFx : F x = 0 := indicator_of_notMem hx f
      rw [hFx]
      constructor
      · refine tendsto_const_nhds.congr' (eventually_atTop.2 ⟨1, fun n hn => ?_⟩)
        exact (rl_step_out (hu n hn) _ hx).symm
      · refine tendsto_const_nhds.congr' (eventually_atTop.2 ⟨1, fun n hn => ?_⟩)
        exact (rl_step_out (hu n hn) _ hx).symm
  have hLm : ∀ n, AEStronglyMeasurable (L n) volume :=
    fun n => (rl_step_measurable (u n) _).aestronglyMeasurable
  have hUm : ∀ n, AEStronglyMeasurable (U n) volume :=
    fun n => (rl_step_measurable (u n) _).aestronglyMeasurable
  have hFm : AEStronglyMeasurable F volume :=
    aestronglyMeasurable_of_tendsto_ae atTop hLm (hNae.mono fun x hx => (hconv x hx).1)
  have hGi : Integrable G volume :=
    (integrable_indicator_iff measurableSet_Icc).2 (integrableOn_const measure_Icc_lt_top.ne)
  have hFi : Integrable F volume := hGi.mono' hFm (ae_of_all _ fun x => by
      by_cases hx : x ∈ Icc a b
      · simp only [F, G, indicator_of_mem hx, Real.norm_eq_abs]; exact hM x hx
      · simp only [F, G, indicator_of_notMem hx, norm_zero, le_refl])
  have hfI : IntegrableOn f (Icc a b) volume := (integrable_indicator_iff measurableSet_Icc).1 hFi
  have hFint : ∫ x, F x = ∫ x in Icc a b, f x := integral_indicator measurableSet_Icc
  have hP1 : ∀ (n : ℕ) (t : Fin (n + 1) → ℝ), IsPartition a b n t →
      lowerSum f n t ≤ ∫ x, F x ∧ ∫ x, F x ≤ upperSum f n t := by
    intro n t ht
    have hae : ∀ᵐ x ∂volume, x ∉ range t :=
      measure_eq_zero_iff_ae_notMem.1 ((finite_range t).measure_zero _)
    constructor
    · have := integral_mono_ae (rl_step_integrable t (fun j => sInf (f '' Icc (t j.castSucc) (t j.succ))))
        hFi (hae.mono fun x hx => (rl_step_bounds hM ht hx).1)
      rw [rl_step_integral ht.1.monotone] at this
      exact this
    · have := integral_mono_ae hFi
        (rl_step_integrable t (fun j => sSup (f '' Icc (t j.castSucc) (t j.succ))))
        (hae.mono fun x hx => (rl_step_bounds hM ht hx).2.1)
      rw [rl_step_integral ht.1.monotone] at this
      exact this
  have hbound : ∀ n, ∀ᵐ x ∂volume, ‖L n x‖ ≤ G x ∧ ‖U n x‖ ≤ G x := by
    intro n
    rcases Nat.eq_zero_or_pos n with hn | hn
    · subst hn
      refine ae_of_all _ fun x => ?_
      have hG : 0 ≤ G x := indicator_nonneg (fun _ _ => hM0) x
      simp only [L, U, Fin.sum_univ_zero, norm_zero]
      exact ⟨hG, hG⟩
    · have hae : ∀ᵐ x ∂volume, x ∉ range (u n) :=
        measure_eq_zero_iff_ae_notMem.1 ((finite_range _).measure_zero _)
      refine hae.mono fun x hx => ?_
      have := rl_step_bounds hM (hu n hn) hx
      rw [Real.norm_eq_abs, Real.norm_eq_abs]
      exact ⟨this.2.2.1, this.2.2.2⟩
  have hLt : Tendsto (fun n => ∫ x, L n x) atTop (𝓝 (∫ x, F x)) :=
    tendsto_integral_of_dominated_convergence G hLm hGi (fun n => (hbound n).mono fun x hx => hx.1)
      (hNae.mono fun x hx => (hconv x hx).1)
  have hUt : Tendsto (fun n => ∫ x, U n x) atTop (𝓝 (∫ x, F x)) :=
    tendsto_integral_of_dominated_convergence G hUm hGi (fun n => (hbound n).mono fun x hx => hx.2)
      (hNae.mono fun x hx => (hconv x hx).2)
  have hLsum : ∀ n, 0 < n → lowerSum f n (u n) = ∫ x, L n x :=
    fun n hn => (rl_step_integral (hu n hn).1.monotone _).symm
  have hUsum : ∀ n, 0 < n → upperSum f n (u n) = ∫ x, U n x :=
    fun n hn => (rl_step_integral (hu n hn).1.monotone _).symm
  refine ⟨hfI, ?_⟩
  rw [← hFint]
  refine ⟨hP1, fun J hJ => le_antisymm ?_ ?_⟩
  · refine ge_of_tendsto hUt (eventually_atTop.2 ⟨1, fun n hn => ?_⟩)
    rw [← hUsum n hn]; exact (hJ n (u n) (hu n hn)).2
  · refine le_of_tendsto hLt (eventually_atTop.2 ⟨1, fun n hn => ?_⟩)
    rw [← hLsum n hn]; exact (hJ n (u n) (hu n hn)).1

/-- A Riemann-integrable bounded function has discontinuities of length zero: the points where
`f` jumps by at least `ε` sit where the gap between an upper and a lower step function is at
least `ε`, and that gap has integral as small as we like. -/
lemma rl_null_of_riemann {f : ℝ → ℝ} {a b : ℝ} (hbdd : ∃ M, ∀ x ∈ Icc a b, |f x| ≤ M)
    (hR : RiemannIntegrable f a b) :
    volume {x | x ∈ Icc a b ∧ ¬ ContinuousWithinAt f (Icc a b) x} = 0 := by
  obtain ⟨M, hM⟩ := hbdd
  obtain ⟨I, hI⟩ := hR
  have hlow : ∀ η > 0, ∃ n t, IsPartition a b n t ∧ I - η < lowerSum f n t := by
    intro η hη
    by_contra h
    push Not at h
    have := hI.2 (I - η) (fun n t ht => ⟨h n t ht, by linarith [(hI.1 n t ht).2]⟩)
    linarith
  have hup : ∀ η > 0, ∃ n t, IsPartition a b n t ∧ upperSum f n t < I + η := by
    intro η hη
    by_contra h
    push Not at h
    have := hI.2 (I + η) (fun n t ht => ⟨by linarith [(hI.1 n t ht).1], h n t ht⟩)
    linarith
  have hE : ∀ j : ℕ, volume {x | x ∈ Icc a b ∧ ∀ δ > 0, ∃ y ∈ Icc a b, dist y x < δ ∧
      1 / ((j : ℝ) + 1) ≤ dist (f y) (f x)} = 0 := by
    intro j
    set ε : ℝ := 1 / ((j : ℝ) + 1) with hεdef
    have hε : 0 < ε := by positivity
    refine le_antisymm (ENNReal.le_of_forall_pos_le_add fun η hη _ => ?_) bot_le
    rw [zero_add]
    have hη' : (0 : ℝ) < η := NNReal.coe_pos.2 hη
    obtain ⟨n, t, ht, hL⟩ := hlow (ε * η / 2) (by positivity)
    obtain ⟨m, s, hs, hU⟩ := hup (ε * η / 2) (by positivity)
    let lo : ℝ → ℝ := fun x => ∑ j : Fin n, (Ioc (t j.castSucc) (t j.succ)).indicator
      (fun _ => sInf (f '' Icc (t j.castSucc) (t j.succ))) x
    let hi : ℝ → ℝ := fun x => ∑ j : Fin m, (Ioc (s j.castSucc) (s j.succ)).indicator
      (fun _ => sSup (f '' Icc (s j.castSucc) (s j.succ))) x
    let w : ℝ → ℝ := fun x => hi x - lo x
    have hloi : Integrable lo volume := rl_step_integrable t _
    have hhii : Integrable hi volume := rl_step_integrable s _
    have hwi : Integrable w volume := hhii.sub hloi
    have hlo_int : ∫ x, lo x = lowerSum f n t := rl_step_integral ht.1.monotone _
    have hhi_int : ∫ x, hi x = upperSum f m s := rl_step_integral hs.1.monotone _
    have hwint : ∫ x, w x = upperSum f m s - lowerSum f n t := by
      rw [← hlo_int, ← hhi_int]; exact integral_sub hhii hloi
    have hcut : volume (range t ∪ range s) = 0 :=
      ((finite_range t).union (finite_range s)).measure_zero _
    have hae : ∀ᵐ x ∂volume, x ∉ range t ∪ range s := measure_eq_zero_iff_ae_notMem.1 hcut
    have hw0 : 0 ≤ᵐ[volume] w := hae.mono fun x hx => by
      have h1 := (rl_step_bounds hM ht (fun h => hx (Or.inl h))).1
      have h2 := (rl_step_bounds hM hs (fun h => hx (Or.inr h))).2.1
      simp only [Pi.zero_apply, w, hi, lo]; linarith
    have hmk := mul_meas_ge_le_integral_of_nonneg hw0 hwi ε
    have hWsub : {x | ε ≤ w x} ⊆ Icc a b := by
      intro x hx
      by_contra hxab
      have h0 : w x = 0 := by
        simp only [w, hi, lo, rl_step_out hs _ hxab, rl_step_out ht _ hxab, sub_zero]
      have h1 : ε ≤ w x := hx
      linarith
    have hWfin : volume {x | ε ≤ w x} ≠ ⊤ :=
      ((measure_mono hWsub).trans_lt measure_Icc_lt_top).ne
    have hreal : (volume {x | ε ≤ w x}).toReal ≤ η := by
      rw [← measureReal_def]
      have : ε * volume.real {x | ε ≤ w x} < ε * η := by rw [hwint] at hmk; linarith
      exact (lt_of_mul_lt_mul_left this hε.le).le
    have hEsub : {x | x ∈ Icc a b ∧ ∀ δ > 0, ∃ y ∈ Icc a b, dist y x < δ ∧ ε ≤ dist (f y) (f x)} ⊆
        (range t ∪ range s) ∪ {x | ε ≤ w x} := by
      rintro x ⟨hx, hδ⟩
      by_contra hcon
      simp only [mem_union, not_or] at hcon
      obtain ⟨⟨hxt, hxs⟩, hxw⟩ := hcon
      rcases rl_step_cases ht (fun j => sInf (f '' Icc (t j.castSucc) (t j.succ))) hxt with
        ⟨hx', _⟩ | ⟨k, hk, hlo⟩
      · exact hx' hx
      rcases rl_step_cases hs (fun j => sSup (f '' Icc (s j.castSucc) (s j.succ))) hxs with
        ⟨hx', _⟩ | ⟨k', hk', hhi⟩
      · exact hx' hx
      have hδpos : 0 < min (min (x - t k.castSucc) (t k.succ - x))
          (min (x - s k'.castSucc) (s k'.succ - x)) := by
        simp only [lt_min_iff]
        exact ⟨⟨by linarith [hk.1], by linarith [hk.2]⟩, by linarith [hk'.1], by linarith [hk'.2]⟩
      obtain ⟨y, hy, hyx, hfy⟩ := hδ _ hδpos
      rw [Real.dist_eq] at hyx hfy
      have hd1 := min_le_left (min (x - t k.castSucc) (t k.succ - x))
          (min (x - s k'.castSucc) (s k'.succ - x))
      have hd2 := min_le_right (min (x - t k.castSucc) (t k.succ - x))
          (min (x - s k'.castSucc) (s k'.succ - x))
      have hd3 := min_le_left (x - t k.castSucc) (t k.succ - x)
      have hd4 := min_le_right (x - t k.castSucc) (t k.succ - x)
      have hd5 := min_le_left (x - s k'.castSucc) (s k'.succ - x)
      have hd6 := min_le_right (x - s k'.castSucc) (s k'.succ - x)
      obtain ⟨hyx1, hyx2⟩ := abs_lt.1 hyx
      have hyP : y ∈ Icc (t k.castSucc) (t k.succ) := ⟨by linarith, by linarith⟩
      have hyQ : y ∈ Icc (s k'.castSucc) (s k'.succ) := ⟨by linarith, by linarith⟩
      have hSP : Icc (t k.castSucc) (t k.succ) ⊆ Icc a b :=
        Icc_subset_Icc (rl_part_bounds ht _).1 (rl_part_bounds ht _).2
      have hSQ : Icc (s k'.castSucc) (s k'.succ) ⊆ Icc a b :=
        Icc_subset_Icc (rl_part_bounds hs _).1 (rl_part_bounds hs _).2
      have a1 := rl_inf_sup hM hSP hyP
      have a2 := rl_inf_sup hM hSP (Ioo_subset_Icc_self hk)
      have a3 := rl_inf_sup hM hSQ hyQ
      have a4 := rl_inf_sup hM hSQ (Ioo_subset_Icc_self hk')
      apply hxw
      have hwx : w x = sSup (f '' Icc (s k'.castSucc) (s k'.succ)) -
          sInf (f '' Icc (t k.castSucc) (t k.succ)) := by
        simp only [w, hi, lo]; rw [hhi, hlo]
      have habs : |f y - f x| ≤ w x := by
        rw [hwx]; exact abs_le.2 ⟨by linarith [a1.1, a4.2.1], by linarith [a3.2.1, a2.1]⟩
      show ε ≤ w x
      linarith
    calc volume {x | x ∈ Icc a b ∧ ∀ δ > 0, ∃ y ∈ Icc a b, dist y x < δ ∧ ε ≤ dist (f y) (f x)}
        ≤ volume ((range t ∪ range s) ∪ {x | ε ≤ w x}) := measure_mono hEsub
      _ ≤ volume (range t ∪ range s) + volume {x | ε ≤ w x} := measure_union_le _ _
      _ = volume {x | ε ≤ w x} := by rw [hcut, zero_add]
      _ ≤ η := by
        have := (ENNReal.le_ofReal_iff_toReal_le hWfin η.coe_nonneg).2 hreal
        rwa [ENNReal.ofReal_coe_nnreal] at this
  refine measure_mono_null ?_ (measure_iUnion_null hE)
  rintro x ⟨hx, hc⟩
  rw [Metric.continuousWithinAt_iff] at hc
  push Not at hc
  obtain ⟨ε, hε, hδ⟩ := hc
  obtain ⟨j, hj⟩ := exists_nat_one_div_lt hε
  refine mem_iUnion.2 ⟨j, hx, fun δ hδpos => ?_⟩
  obtain ⟨y, hy, h1, h2⟩ := hδ δ hδpos
  exact ⟨y, hy, h1, hj.le.trans h2⟩

lemma rl_riemannIntegral_eq {g : ℝ → ℝ} {a b I : ℝ} (hI : HasRiemannIntegral g a b I) :
    riemannIntegral g a b = I := by
  have h : RiemannIntegrable g a b := ⟨I, hI⟩
  simp only [riemannIntegral, h, ↓reduceDIte]
  exact (h.choose_spec.2 I hI.1).symm

#print axioms rl_main_of_null
#print axioms rl_null_of_riemann
#print axioms rl_riemannIntegral_eq

/-- Theorem (i): every bounded Riemann-integrable function on a closed interval `[a, b]` is
Lebesgue integrable there (measurable with respect to the Lebesgue sets, with finite integral),
and its Lebesgue integral equals its Riemann integral. -/
theorem riemann_integral_is_lebesgue_integral (f : ℝ → ℝ) (a b : ℝ) (hab : a < b)
    (hbdd : ∃ M, ∀ x ∈ Icc a b, |f x| ≤ M) (I : ℝ) (hI : HasRiemannIntegral f a b I) :
    IntegrableOn f (Icc a b) volume ∧ ∫ x in Icc a b, f x = I := by
  have hD := rl_null_of_riemann hbdd ⟨I, hI⟩
  obtain ⟨hint, hHR⟩ := rl_main_of_null hab hbdd hD
  exact ⟨hint, hI.2 _ hHR.1⟩

/-- Theorem (ii), Lebesgue's criterion: a bounded function on `[a, b]` is Riemann integrable
exactly when the set `D_f` of points where it is not continuous has length zero. -/
theorem riemann_integrable_iff_discontinuities_null (f : ℝ → ℝ) (a b : ℝ) (hab : a < b)
    (hbdd : ∃ M, ∀ x ∈ Icc a b, |f x| ≤ M) :
    RiemannIntegrable f a b ↔
      volume {x | x ∈ Icc a b ∧ ¬ ContinuousWithinAt f (Icc a b) x} = 0 := by
  exact ⟨rl_null_of_riemann hbdd, fun h => ⟨_, (rl_main_of_null hab hbdd h).2⟩⟩

/-- Theorem (iii): if `f` is bounded and Riemann integrable on every `[a, b']`, then `f` is
Lebesgue integrable on `[a, ∞)` exactly when the improper integral of `|f|` is finite
(the Riemann integrals of `|f|` from `a` to `b'` settle at a finite limit as `b'` grows),
and then the improper integral of `f` exists and equals its Lebesgue integral. -/
theorem lebesgue_integrable_iff_abs_improper_integral_finite (f : ℝ → ℝ) (a : ℝ)
    (hbdd : ∀ b', a < b' → ∃ M, ∀ x ∈ Icc a b', |f x| ≤ M)
    (hf : ∀ b', a < b' → RiemannIntegrable f a b') :
    (IntegrableOn f (Ici a) volume ↔
        ∃ L : ℝ, Tendsto (fun b' => riemannIntegral (fun x => |f x|) a b') atTop (𝓝 L)) ∧
      (IntegrableOn f (Ici a) volume →
        Tendsto (fun b' => riemannIntegral f a b') atTop (𝓝 (∫ x in Ici a, f x))) := by
  have hfacts : ∀ b', a < b' → IntegrableOn f (Icc a b') volume ∧
      riemannIntegral f a b' = ∫ x in a..b', f x ∧
      riemannIntegral (fun x => |f x|) a b' = ∫ x in a..b', ‖f x‖ := by
    intro b' hb
    obtain ⟨I, hI⟩ := hf b' hb
    have h1 := riemann_integral_is_lebesgue_integral f a b' hb (hbdd b' hb) I hI
    have hD := rl_null_of_riemann (hbdd b' hb) (hf b' hb)
    have hDabs : volume {x | x ∈ Icc a b' ∧
        ¬ ContinuousWithinAt (fun x => |f x|) (Icc a b') x} = 0 := by
      refine measure_mono_null ?_ hD
      intro x hx
      exact ⟨hx.1, fun hc => hx.2 hc.abs⟩
    obtain ⟨M, hM⟩ := hbdd b' hb
    have h2 := rl_main_of_null hb ⟨M, fun x hx => by rw [abs_abs]; exact hM x hx⟩ hDabs
    refine ⟨h1.1, ?_, ?_⟩
    · rw [rl_riemannIntegral_eq hI, intervalIntegral.integral_of_le hb.le,
        ← integral_Icc_eq_integral_Ioc, h1.2]
    · rw [rl_riemannIntegral_eq h2.2, intervalIntegral.integral_of_le hb.le,
        ← integral_Icc_eq_integral_Ioc]
      simp only [Real.norm_eq_abs]
  have hev : ∀ᶠ b' in atTop, a < b' := eventually_gt_atTop a
  refine ⟨⟨fun hint => ?_, fun ⟨L, hL⟩ => ?_⟩, fun hint => ?_⟩
  · have hIoi : IntegrableOn f (Ioi a) volume := hint.mono_set Ioi_subset_Ici_self
    refine ⟨∫ x in Ioi a, ‖f x‖, ?_⟩
    have := intervalIntegral_tendsto_integral_Ioi a hIoi.norm tendsto_id
    exact this.congr' (hev.mono fun b' hb => ((hfacts b' hb).2.2).symm)
  · have hfi : ∀ i, IntegrableOn f (Ioc a (id i)) volume := by
      intro i
      rcases le_or_gt i a with h | h
      · rw [id, Ioc_eq_empty (not_lt.2 h)]; exact integrableOn_empty
      · exact (hfacts i h).1.mono_set Ioc_subset_Icc_self
    have := integrableOn_Ioi_of_intervalIntegral_norm_tendsto L a hfi tendsto_id
      (hL.congr' (hev.mono fun b' hb => (hfacts b' hb).2.2))
    rw [integrableOn_Ici_iff_integrableOn_Ioi]
    exact this
  · rw [integral_Ici_eq_integral_Ioi]
    exact (intervalIntegral_tendsto_integral_Ioi a (hint.mono_set Ioi_subset_Ici_self)
      tendsto_id).congr' (hev.mono fun b' hb => ((hfacts b' hb).2.1).symm)

-- Worked numbers, by hand.
-- The river depth 4x(1 - x) at the 8-strip cuts nearer a bank: 0, 0.4375, 0.75, 0.9375 m.
example : [0, 1/8, 2/8, 3/8].map (fun x : ℚ => 4 * x * (1 - x)) = [0, 7/16, 3/4, 15/16] := by
  norm_num
-- Lower sum over 8 strips: (0 + 0.4375 + 0.75 + 0.9375) × 2 × 0.125 = 0.53125.
example : ((0 : ℚ) + 7/16 + 3/4 + 15/16) * 2 * (1/8) = 53125 / 100000 := by norm_num
-- Level sets: depth ≥ t on [(1 - s)/2, (1 + s)/2] with s = √(1 - t), since the depth there is 1 - s².
example (s : ℚ) : 4 * ((1 - s) / 2) * (1 - (1 - s) / 2) = 1 - s ^ 2 := by ring
-- 1,000 strips: lower sum 0.665666 and upper sum 0.667666, 2/1000 apart.
example : (332833 : ℚ) / 500000 = 0.665666 ∧ (333833 : ℚ) / 500000 = 0.667666 ∧
    (333833 : ℚ) / 500000 - 332833 / 500000 = 2 / 1000 := by norm_num
-- Midpoint error 1/(3 × 1000²) = 1/3000000.
example : (1 : ℚ) / (3 * 1000 ^ 2) = 1 / 3000000 := by norm_num
-- Antiderivative 2x² - (4/3)x³ from 0 to 1: 2/3.
example : (2 : ℚ) * 1 ^ 2 - 4 / 3 * 1 ^ 3 - (2 * 0 ^ 2 - 4 / 3 * 0 ^ 3) = 2 / 3 := by norm_num
-- Depth 1 at fractions: Lebesgue gives 1 × 0 + 0 × 1 = 0.
example : 1 * 0 + 0 * 1 = 0 := by decide
-- Thomae, 10 strips: least denominators 1, 5, 4, 3, 2, 2, 3, 4, 5, 1, upper sum 137/300 = 0.456667 (rounded).
example : ((1 : ℚ) + 1/5 + 1/4 + 1/3 + 1/2 + 1/2 + 1/3 + 1/4 + 1/5 + 1) / 10 = 137 / 300 := by
  norm_num
-- Thomae counting bound at 10 strips with Q = 2 (fractions 0/1, 1/2, 1/1): 2 × 3/10 + 1/2 = 1.1.
example : (2 : ℚ) * 3 / 10 + 1 / 2 = 11 / 10 := by norm_num

#print axioms riemann_integral_is_lebesgue_integral
#print axioms riemann_integrable_iff_discontinuities_null
#print axioms lebesgue_integrable_iff_abs_improper_integral_finite
