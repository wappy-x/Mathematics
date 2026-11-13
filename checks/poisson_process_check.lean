-- Poisson process: when the gaps between calls are independent and exponential with rate λ, the count in every window is Poisson with mean λ times its length, counts in back-to-back windows multiply, and calls never pile up.
import Mathlib.Probability.Distributions.Exponential
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.HasLaw
import Mathlib.Order.ConditionallyCompleteLattice.Basic
import Mathlib.Tactic.NormNum
import Mathlib

namespace PoissonProcess

open MeasureTheory ProbabilityTheory Real
open scoped Nat

/-- The time of call `n`: `T_n = E_1 + ... + E_n`, with the gaps stored as `E 0, E 1, ...`
(so `E i` is the card's `E_(i+1)`), and `T_0 = 0`, nine o'clock. -/
noncomputable def callTime {Ω : Type*} (E : ℕ → Ω → ℝ) (n : ℕ) (ω : Ω) : ℝ :=
  ∑ i ∈ Finset.range n, E i ω

/-- The count of calls by time `t`, a call exactly at `t` included: the largest `n` with
`T_n ≤ t`. When there is no largest one (infinitely many calls by `t`, a set of chance zero),
Lean's `sSup` of an unbounded set of whole numbers is `0`, the card's convention. -/
noncomputable def count {Ω : Type*} (E : ℕ → Ω → ℝ) (t : ℝ) (ω : Ω) : ℕ :=
  sSup {n : ℕ | callTime E n ω ≤ t}

section Helpers

open Filter Set

/-- Call times of a fixed list of gaps. -/
noncomputable def T (e : ℕ → ℝ) (n : ℕ) : ℝ := callTime (fun i (x : ℕ → ℝ) => x i) n e

/-- Count of calls by time `t` for a fixed list of gaps. -/
noncomputable def cnt (e : ℕ → ℝ) (t : ℝ) : ℕ := count (fun i (x : ℕ → ℝ) => x i) t e

/-- Drop the first gap. -/
def tl (e : ℕ → ℝ) : ℕ → ℝ := fun n => e (n + 1)

/-- Put a gap in front. -/
def cs (x : ℝ) (y : ℕ → ℝ) : ℕ → ℝ := fun n =>
  match n with
  | 0 => x
  | m + 1 => y m

/-- Gaps all positive, call times unbounded. -/
def Nice (e : ℕ → ℝ) : Prop := (∀ i, 0 < e i) ∧ ∀ t : ℝ, ∃ n, t < T e n

lemma T_zero (e : ℕ → ℝ) : T e 0 = 0 := by simp [T, callTime]

lemma T_succ (e : ℕ → ℝ) (n : ℕ) : T e (n + 1) = T e n + e n := by
  simp [T, callTime, Finset.sum_range_succ]

lemma T_tl (e : ℕ → ℝ) (n : ℕ) : T (tl e) n = T e (n + 1) - e 0 := by
  simp only [T, callTime, tl]
  rw [Finset.sum_range_succ']
  ring

lemma T_cs_succ (x : ℝ) (y : ℕ → ℝ) (n : ℕ) : T (cs x y) (n + 1) = x + T y n := by
  simp only [T, callTime]
  rw [Finset.sum_range_succ']
  simp [cs]
  ring

lemma T_cs_tl (e : ℕ → ℝ) (d : ℝ) (n : ℕ) : T (cs (e 0 - d) (tl e)) (n + 1) = T e (n + 1) - d := by
  rw [T_cs_succ, T_tl]; ring

lemma T_strictMono {e : ℕ → ℝ} (h : ∀ i, 0 < e i) : StrictMono (T e) :=
  strictMono_nat_of_lt_succ fun n => by rw [T_succ]; linarith [h n]

lemma cnt_def (e : ℕ → ℝ) (t : ℝ) : cnt e t = sSup {n : ℕ | T e n ≤ t} := rfl

lemma cnt_eq_iff {e : ℕ → ℝ} (h : Nice e) {t : ℝ} (ht : 0 ≤ t) (K : ℕ) :
    cnt e t = K ↔ T e K ≤ t ∧ t < T e (K + 1) := by
  have hm := T_strictMono h.1
  obtain ⟨N, hN⟩ := h.2 t
  have hlt : ∀ n, T e n ≤ t → n < N := fun n hn => by
    by_contra hc; push Not at hc; linarith [hm.monotone hc]
  have hbdd : BddAbove {n : ℕ | T e n ≤ t} := ⟨N, fun n hn => (hlt n hn).le⟩
  have hne : ({n : ℕ | T e n ≤ t}).Nonempty := ⟨0, by simp [T_zero, ht]⟩
  rw [cnt_def]
  constructor
  · rintro rfl
    refine ⟨Nat.sSup_mem hne hbdd, ?_⟩
    by_contra hc; push Not at hc
    have := le_csSup hbdd (show sSup {n : ℕ | T e n ≤ t} + 1 ∈ {n : ℕ | T e n ≤ t} from hc)
    omega
  · rintro ⟨h1, h2⟩
    have : {n : ℕ | T e n ≤ t} = Set.Iic K := by
      ext n
      simp only [mem_ofPred_eq, mem_Iic]
      constructor
      · intro hn; by_contra hc; push Not at hc
        linarith [hm.monotone (Nat.succ_le_of_lt hc)]
      · intro hn; exact (hm.monotone hn).trans h1
    rw [this, csSup_Iic]

lemma cnt_zero {e : ℕ → ℝ} (h : Nice e) : cnt e 0 = 0 :=
  (cnt_eq_iff h le_rfl 0).2 ⟨by simp [T_zero], by simpa [T_succ, T_zero] using h.1 0⟩

lemma nice_tl {e : ℕ → ℝ} (h : Nice e) : Nice (tl e) := by
  refine ⟨fun i => h.1 (i + 1), fun t => ?_⟩
  obtain ⟨N, hN⟩ := h.2 (t + e 0)
  refine ⟨N, ?_⟩
  rw [T_tl]
  have := (T_strictMono h.1).monotone (Nat.le_succ N)
  linarith

lemma nice_cs {e : ℕ → ℝ} (h : Nice e) {d : ℝ} (hd : d < e 0) : Nice (cs (e 0 - d) (tl e)) := by
  refine ⟨fun i => ?_, fun t => ?_⟩
  · cases i with
    | zero => simp [cs]; linarith
    | succ m => simpa [cs, tl] using h.1 (m + 1)
  · obtain ⟨N, hN⟩ := h.2 (t + d)
    refine ⟨N + 1, ?_⟩
    rw [T_cs_tl]
    have := (T_strictMono h.1).monotone (Nat.le_succ N)
    linarith

lemma cnt_tl {e : ℕ → ℝ} (h : Nice e) {t : ℝ} (ht : e 0 ≤ t) :
    cnt e t = cnt (tl e) (t - e 0) + 1 := by
  have h0 : 0 ≤ t := le_trans (h.1 0).le ht
  have := (cnt_eq_iff (nice_tl h) (sub_nonneg.2 ht) (cnt (tl e) (t - e 0))).1 rfl
  rw [T_tl, T_tl] at this
  exact (cnt_eq_iff h h0 _).2 ⟨by linarith, by linarith⟩

lemma cnt_cs {e : ℕ → ℝ} (h : Nice e) {d : ℝ} (hd : d < e 0) {t : ℝ} (ht : d ≤ t) (hd0 : 0 ≤ d) :
    cnt e t = cnt (cs (e 0 - d) (tl e)) (t - d) := by
  have := (cnt_eq_iff (nice_cs h hd) (sub_nonneg.2 ht) (cnt (cs (e 0 - d) (tl e)) (t - d))).1 rfl
  apply (cnt_eq_iff h (by linarith) _).2
  generalize cnt (cs (e 0 - d) (tl e)) (t - d) = K at this ⊢
  cases K with
  | zero =>
    rw [T_cs_tl, T_zero] at this
    rw [T_zero, zero_add]
    have h1 := this.2
    rw [zero_add] at h1
    constructor <;> linarith
  | succ m =>
    rw [T_cs_tl, T_cs_tl] at this
    constructor <;> linarith

/-- The count conditions along a list of windows `(length, number of calls)`. -/
def CG : List (ℝ × ℕ) → ℝ → ℕ → (ℕ → ℝ) → Prop
  | [], _, _, _ => True
  | p :: L, D, K, e => cnt e (D + p.1) = K + p.2 ∧ CG L (D + p.1) (K + p.2) e

lemma CG_tl {e : ℕ → ℝ} (h : Nice e) : ∀ (L : List (ℝ × ℕ)) (D : ℝ) (K : ℕ), e 0 ≤ D →
    (∀ p ∈ L, 0 ≤ p.1) → (CG L D (K + 1) e ↔ CG L (D - e 0) K (tl e)) := by
  intro L
  induction L with
  | nil => intros; simp [CG]
  | cons p L ih =>
    intro D K hD hL
    have hp := hL p (List.mem_cons_self ..)
    have hD' : e 0 ≤ D + p.1 := by linarith
    have e1 : D - e 0 + p.1 = D + p.1 - e 0 := by ring
    have e2 : K + 1 + p.2 = (K + p.2) + 1 := by omega
    simp only [CG]
    rw [e1, e2, ih (D + p.1) (K + p.2) hD' (fun q hq => hL q (List.mem_cons_of_mem _ hq)),
      cnt_tl h hD']
    constructor <;> rintro ⟨a, b⟩ <;> exact ⟨by omega, b⟩

lemma CG_cs {e : ℕ → ℝ} (h : Nice e) {d : ℝ} (hd : d < e 0) (hd0 : 0 ≤ d) :
    ∀ (L : List (ℝ × ℕ)) (D : ℝ) (K : ℕ), d ≤ D →
    (∀ p ∈ L, 0 ≤ p.1) → (CG L D K e ↔ CG L (D - d) K (cs (e 0 - d) (tl e))) := by
  intro L
  induction L with
  | nil => intros; simp [CG]
  | cons p L ih =>
    intro D K hD hL
    have hp := hL p (List.mem_cons_self ..)
    have hD' : d ≤ D + p.1 := by linarith
    have e1 : D - d + p.1 = D + p.1 - d := by ring
    simp only [CG]
    rw [e1, ih (D + p.1) (K + p.2) hD' (fun q hq => hL q (List.mem_cons_of_mem _ hq)),
      cnt_cs h hd hD' hd0]

/-- The windows event, built gap by gap. -/
def G (R : Set (ℕ → ℝ)) : ℕ → Set (ℝ × (ℕ → ℝ))
  | 0 => {p | p.1 < p.2 0 ∧ cs (p.2 0 - p.1) (tl p.2) ∈ R}
  | k + 1 => {p | 0 ≤ p.2 0 ∧ p.2 0 ≤ p.1 ∧ (p.1 - p.2 0, tl p.2) ∈ G R k}

def Good : List (ℝ × ℕ) → Set (ℕ → ℝ)
  | [] => univ
  | p :: L => {e | (p.1, e) ∈ G (Good L) p.2}

lemma good_iff : ∀ (L : List (ℝ × ℕ)), (∀ p ∈ L, 0 ≤ p.1) → ∀ e, Nice e →
    (e ∈ Good L ↔ CG L 0 0 e) := by
  intro L
  induction L with
  | nil => intros; simp [Good, CG]
  | cons p L ih =>
    intro hL e he
    have hL' : ∀ q ∈ L, 0 ≤ q.1 := fun q hq => hL q (List.mem_cons_of_mem _ hq)
    have key : ∀ (k : ℕ) (d : ℝ) (e : ℕ → ℝ), 0 ≤ d → Nice e →
        ((d, e) ∈ G (Good L) k ↔ cnt e d = k ∧ CG L d k e) := by
      intro k
      induction k with
      | zero =>
        intro d e hd he
        simp only [G, mem_ofPred_eq]
        rw [cnt_eq_iff he hd, T_zero, T_succ, T_zero, zero_add]
        constructor
        · rintro ⟨h1, h2⟩
          rw [ih hL' _ (nice_cs he h1)] at h2
          refine ⟨⟨hd, h1⟩, ?_⟩
          rw [CG_cs he h1 hd L d 0 le_rfl hL', sub_self]
          exact h2
        · rintro ⟨⟨-, h1⟩, h2⟩
          refine ⟨h1, ?_⟩
          rw [ih hL' _ (nice_cs he h1)]
          rw [CG_cs he h1 hd L d 0 le_rfl hL', sub_self] at h2
          exact h2
      | succ k ihk =>
        intro d e hd he
        simp only [G, mem_ofPred_eq]
        constructor
        · rintro ⟨-, h1, h2⟩
          rw [ihk (d - e 0) (tl e) (by linarith) (nice_tl he)] at h2
          exact ⟨by rw [cnt_tl he h1]; omega, (CG_tl he L d k h1 hL').2 h2.2⟩
        · rintro ⟨h1, h2⟩
          have h0 : e 0 ≤ d := by
            by_contra hc; push Not at hc
            have : cnt e d = 0 := (cnt_eq_iff he hd 0).2
              ⟨by rw [T_zero]; exact hd, by rw [T_succ, T_zero, zero_add]; exact hc⟩
            omega
          refine ⟨(he.1 0).le, h0, ?_⟩
          rw [ihk (d - e 0) (tl e) (by linarith) (nice_tl he)]
          exact ⟨by have := cnt_tl he h0; omega, (CG_tl he L d k h0 hL').1 h2⟩
    simp only [Good, mem_ofPred_eq, CG, zero_add]
    exact key p.2 p.1 e (hL p (List.mem_cons_self ..)) he


lemma measurable_tl : Measurable tl :=
  measurable_pi_iff.2 fun n => measurable_pi_apply (n + 1)

lemma measurable_cs : Measurable (fun q : ℝ × (ℕ → ℝ) => cs q.1 q.2) := by
  refine measurable_pi_iff.2 fun n => ?_
  cases n with
  | zero => simpa [cs] using measurable_fst
  | succ m =>
    show Measurable fun q : ℝ × (ℕ → ℝ) => q.2 m
    exact (measurable_pi_apply m).comp measurable_snd

lemma cs_tl (e : ℕ → ℝ) : cs (e 0) (tl e) = e := by
  funext n; cases n <;> rfl

/-- The Poisson chance of `k` calls in a window of length `d`. -/
noncomputable def poi (r d : ℝ) (k : ℕ) : ℝ := exp (-(r * d)) * (r * d) ^ k / k !

lemma poi_nonneg {r d : ℝ} (hr : 0 ≤ r) (hd : 0 ≤ d) (k : ℕ) : 0 ≤ poi r d k := by
  unfold poi; have := mul_nonneg hr hd; positivity

/-- Law of an independent sequence of exponential gaps. -/
noncomputable abbrev nu (r : ℝ) [IsProbabilityMeasure (expMeasure r)] : Measure (ℕ → ℝ) :=
  Measure.infinitePi (fun _ : ℕ => expMeasure r)

section
variable {r : ℝ}

lemma expMeasure_eq : expMeasure r = volume.withDensity (exponentialPDF r) := rfl

lemma measurable_exponentialPDF : Measurable (exponentialPDF r) :=
  (measurable_exponentialPDFReal r).ennreal_ofReal

/-- Memorylessness, as an integral. -/
lemma lintegral_memoryless {d : ℝ} (hd : 0 ≤ d) {f : ℝ → ENNReal}
    (hf : Measurable f) :
    ∫⁻ x, (Ioi d).indicator (fun x => f (x - d)) x ∂(expMeasure r) =
      ENNReal.ofReal (exp (-(r * d))) * ∫⁻ x, f x ∂(expMeasure r) := by
  have hsing : expMeasure r {d} = 0 := by
    rw [expMeasure_eq, withDensity_apply _ (measurableSet_singleton d),
      Measure.restrict_eq_zero.2 Real.volume_singleton, lintegral_zero_measure]
  have h1 : ∫⁻ x, (Ioi d).indicator (fun x => f (x - d)) x ∂(expMeasure r) =
      ∫⁻ x, (Ici d).indicator (fun x => f (x - d)) x ∂(expMeasure r) := by
    apply lintegral_congr_ae
    filter_upwards [measure_eq_zero_iff_ae_notMem.1 hsing] with x hx
    have hx' : x ≠ d := by simpa using hx
    by_cases h : d < x
    · simp [indicator, h, h.le]
    · have : ¬ d ≤ x := fun h' => h (lt_of_le_of_ne h' hx'.symm)
      simp [indicator, h, this]
  have hg : Measurable fun x => (Ici d).indicator (fun x => f (x - d)) x :=
    (hf.comp (measurable_id.sub_const d)).indicator measurableSet_Ici
  rw [h1, expMeasure_eq, lintegral_withDensity_eq_lintegral_mul _ measurable_exponentialPDF hg,
    lintegral_withDensity_eq_lintegral_mul _ measurable_exponentialPDF hf,
    ← lintegral_add_right_eq_self _ d, ← lintegral_const_mul _ (measurable_exponentialPDF.mul hf)]
  congr 1
  funext y
  simp only [Pi.mul_apply]
  by_cases hy : 0 ≤ y
  · have hyd : d ≤ y + d := by linarith
    simp only [indicator, mem_Ici, hyd, ite_true, add_sub_cancel_right]
    rw [exponentialPDF_of_nonneg (by linarith), exponentialPDF_of_nonneg hy, ← mul_assoc,
      ← ENNReal.ofReal_mul (exp_pos _).le]
    congr 2
    rw [show -(r * (y + d)) = -(r * d) + -(r * y) by ring, exp_add]
    ring
  · push Not at hy
    have hyd : ¬ d ≤ y + d := by linarith
    simp [indicator, hyd, exponentialPDF_of_neg hy]

lemma lintegral_window (hr : 0 < r) {d : ℝ} (hd : 0 ≤ d) (k : ℕ) :
    ∫⁻ x, (Icc 0 d).indicator (fun x => ENNReal.ofReal (poi r (d - x) k)) x ∂(expMeasure r) =
      ENNReal.ofReal (poi r d (k + 1)) := by
  have hg : Measurable fun x => ENNReal.ofReal (poi r (d - x) k) := by
    unfold poi; fun_prop
  rw [lintegral_indicator measurableSet_Icc, expMeasure_eq,
    setLIntegral_withDensity_eq_setLIntegral_mul _ measurable_exponentialPDF hg measurableSet_Icc]
  rw [setLIntegral_congr_fun measurableSet_Icc (g := fun x => ENNReal.ofReal
    (exp (-(r * d)) * r ^ (k + 1) / k ! * (d - x) ^ k))]
  swap
  · intro x hx
    simp only [Pi.mul_apply]
    rw [exponentialPDF_of_nonneg hx.1, ← ENNReal.ofReal_mul (by positivity)]
    congr 1
    unfold poi
    have : exp (-(r * x)) * exp (-(r * (d - x))) = exp (-(r * d)) := by
      rw [← exp_add]; ring_nf
    rw [mul_pow, pow_succ]
    field_simp
    rw [← this]
    ring
  have hcont : Continuous fun x : ℝ => exp (-(r * d)) * r ^ (k + 1) / k ! * (d - x) ^ k := by
    fun_prop
  rw [← ofReal_integral_eq_lintegral_ofReal (hcont.integrableOn_Icc)]
  swap
  · refine ae_restrict_of_forall_mem measurableSet_Icc fun x hx => ?_
    have : 0 ≤ d - x := sub_nonneg.2 hx.2
    positivity
  congr 1
  rw [integral_Icc_eq_integral_Ioc, ← intervalIntegral.integral_of_le hd,
    intervalIntegral.integral_const_mul, intervalIntegral.integral_comp_sub_left (fun x => x ^ k),
    integral_pow]
  simp only [sub_self, sub_zero, ne_eq, Nat.succ_ne_zero, not_false_eq_true, zero_pow]
  unfold poi
  rw [Nat.factorial_succ]
  push_cast
  rw [mul_pow]
  field_simp

end

variable {r : ℝ} [IsProbabilityMeasure (expMeasure r)]

lemma nu_split : (nu r).map (fun e => (e 0, tl e)) = (expMeasure r).prod (nu r) := by
  have hind : iIndepFun (fun i (e : ℕ → ℝ) => e i) (nu r) :=
    iIndepFun_infinitePi (X := fun _ x => x) (fun _ => measurable_id)
  have h2 := hind.indepFun_set {0} {n | n ≠ 0} (by simp) (fun i => measurable_pi_apply i)
  have h3 : IndepFun (fun e : ℕ → ℝ => e 0) tl (nu r) :=
    h2.comp (show Measurable (fun f : ({0} : Set ℕ) → ℝ => f ⟨0, rfl⟩) from measurable_pi_apply _)
      (show Measurable (fun f : {n : ℕ | n ≠ 0} → ℝ => fun n => f ⟨n + 1, Nat.succ_ne_zero n⟩)
        from measurable_pi_iff.2 fun n => measurable_pi_apply _)
  rw [(indepFun_iff_map_prod_eq_prod_map_map (measurable_pi_apply 0).aemeasurable
    measurable_tl.aemeasurable).1 h3]
  congr 1
  · exact Measure.infinitePi_map_eval _ 0
  · exact Measure.map_infinitePi_infinitePi_of_inj (P := fun _ : ℕ => expMeasure r)
      (f := Nat.succ) Nat.succ_injective

lemma nu_split_apply {A : Set (ℝ × (ℕ → ℝ))} (hA : MeasurableSet A) :
    nu r {e | (e 0, tl e) ∈ A} = ∫⁻ x, nu r (Prod.mk x ⁻¹' A) ∂(expMeasure r) := by
  rw [← Measure.prod_apply hA, ← nu_split,
    Measure.map_apply ((measurable_pi_apply 0).prodMk measurable_tl) hA]
  rfl

lemma nu_cs {R : Set (ℕ → ℝ)} (hR : MeasurableSet R) :
    ∫⁻ x, nu r (Prod.mk x ⁻¹' {q : ℝ × (ℕ → ℝ) | cs q.1 q.2 ∈ R}) ∂(expMeasure r) = nu r R := by
  rw [← nu_split_apply (A := {q : ℝ × (ℕ → ℝ) | cs q.1 q.2 ∈ R}) (measurable_cs hR)]
  simp only [mem_ofPred_eq, cs_tl]
  rfl


lemma measurableSet_G {R : Set (ℕ → ℝ)} (hR : MeasurableSet R) : ∀ k, MeasurableSet (G R k) := by
  intro k
  induction k with
  | zero =>
    have hm : Measurable fun p : ℝ × (ℕ → ℝ) => (p.2 0 - p.1, tl p.2) :=
      (((measurable_pi_apply 0).comp measurable_snd).sub measurable_fst).prodMk
          (measurable_tl.comp measurable_snd)
    have h2 : MeasurableSet {p : ℝ × (ℕ → ℝ) | cs (p.2 0 - p.1) (tl p.2) ∈ R} :=
      hR.preimage (measurable_cs.comp hm)
    have h1 : MeasurableSet {p : ℝ × (ℕ → ℝ) | p.1 < p.2 0} :=
      measurableSet_lt measurable_fst ((measurable_pi_apply 0).comp measurable_snd)
    exact h1.inter h2
  | succ k ih =>
    have hm : Measurable fun p : ℝ × (ℕ → ℝ) => (p.1 - p.2 0, tl p.2) :=
      (measurable_fst.sub ((measurable_pi_apply 0).comp measurable_snd)).prodMk
          (measurable_tl.comp measurable_snd)
    have h3 : MeasurableSet {p : ℝ × (ℕ → ℝ) | (p.1 - p.2 0, tl p.2) ∈ G R k} := ih.preimage hm
    have h1 : MeasurableSet {p : ℝ × (ℕ → ℝ) | 0 ≤ p.2 0} :=
      measurableSet_le measurable_const ((measurable_pi_apply 0).comp measurable_snd)
    have h2 : MeasurableSet {p : ℝ × (ℕ → ℝ) | p.2 0 ≤ p.1} :=
      measurableSet_le ((measurable_pi_apply 0).comp measurable_snd) measurable_fst
    exact h1.inter (h2.inter h3)

lemma measurableSet_Good : ∀ L : List (ℝ × ℕ), MeasurableSet (Good L)
  | [] => MeasurableSet.univ
  | p :: L => measurable_prodMk_left (measurableSet_G (measurableSet_Good L) p.2)

lemma nu_G (hr : 0 < r) {R : Set (ℕ → ℝ)} (hR : MeasurableSet R) :
    ∀ (k : ℕ) (d : ℝ), 0 ≤ d → nu r {e | (d, e) ∈ G R k} = ENNReal.ofReal (poi r d k) * nu r R := by
  intro k
  induction k with
  | zero =>
    intro d hd
    have hA1 : MeasurableSet {q : ℝ × (ℕ → ℝ) | d < q.1} :=
      measurableSet_lt measurable_const measurable_fst
    have hm : Measurable fun q : ℝ × (ℕ → ℝ) => (q.1 - d, q.2) :=
      (measurable_fst.sub_const d).prodMk measurable_snd
    have hA2 : MeasurableSet {q : ℝ × (ℕ → ℝ) | cs (q.1 - d) q.2 ∈ R} :=
      hR.preimage (measurable_cs.comp hm)
    have hA : MeasurableSet {q : ℝ × (ℕ → ℝ) | d < q.1 ∧ cs (q.1 - d) q.2 ∈ R} := hA1.inter hA2
    have hB : MeasurableSet {q : ℝ × (ℕ → ℝ) | cs q.1 q.2 ∈ R} := measurable_cs hR
    have hset : {e | (d, e) ∈ G R 0} =
        {e | (e 0, tl e) ∈ {q : ℝ × (ℕ → ℝ) | d < q.1 ∧ cs (q.1 - d) q.2 ∈ R}} := rfl
    rw [hset, nu_split_apply hA]
    have hpt : ∀ x, nu r (Prod.mk x ⁻¹' {q : ℝ × (ℕ → ℝ) | d < q.1 ∧ cs (q.1 - d) q.2 ∈ R}) =
        (Ioi d).indicator (fun x => nu r (Prod.mk (x - d) ⁻¹'
          {q : ℝ × (ℕ → ℝ) | cs q.1 q.2 ∈ R})) x := by
      intro x
      by_cases hx : d < x
      · simp only [indicator, mem_Ioi, hx, ite_true]
        congr 1
        ext y; simp [hx]
      · simp only [indicator, mem_Ioi, hx, ite_false]
        have : Prod.mk x ⁻¹' {q : ℝ × (ℕ → ℝ) | d < q.1 ∧ cs (q.1 - d) q.2 ∈ R} = ∅ := by
          ext y; simp [hx]
        rw [this, measure_empty]
    simp_rw [hpt]
    rw [lintegral_memoryless hd (measurable_measure_prodMk_left hB), nu_cs hR]
    simp [poi]
  | succ k ih =>
    intro d hd
    have hA1 : MeasurableSet {q : ℝ × (ℕ → ℝ) | 0 ≤ q.1} :=
      measurableSet_le measurable_const measurable_fst
    have hA2 : MeasurableSet {q : ℝ × (ℕ → ℝ) | q.1 ≤ d} :=
      measurableSet_le measurable_fst measurable_const
    have hm : Measurable fun q : ℝ × (ℕ → ℝ) => (d - q.1, q.2) :=
      (measurable_const.sub measurable_fst).prodMk measurable_snd
    have hA3 : MeasurableSet {q : ℝ × (ℕ → ℝ) | (d - q.1, q.2) ∈ G R k} :=
      (measurableSet_G hR k).preimage hm
    have hA : MeasurableSet {q : ℝ × (ℕ → ℝ) | 0 ≤ q.1 ∧ q.1 ≤ d ∧ (d - q.1, q.2) ∈ G R k} :=
      hA1.inter (hA2.inter hA3)
    have hset : {e | (d, e) ∈ G R (k + 1)} =
        {e | (e 0, tl e) ∈ {q : ℝ × (ℕ → ℝ) | 0 ≤ q.1 ∧ q.1 ≤ d ∧ (d - q.1, q.2) ∈ G R k}} := rfl
    rw [hset, nu_split_apply hA]
    have hpt : ∀ x, nu r (Prod.mk x ⁻¹'
        {q : ℝ × (ℕ → ℝ) | 0 ≤ q.1 ∧ q.1 ≤ d ∧ (d - q.1, q.2) ∈ G R k}) =
        (Icc 0 d).indicator (fun x => ENNReal.ofReal (poi r (d - x) k)) x * nu r R := by
      intro x
      by_cases hx : x ∈ Icc 0 d
      · simp only [indicator, hx, ite_true]
        rw [← ih (d - x) (sub_nonneg.2 hx.2)]
        congr 1
        ext y; simp [hx.1, hx.2]
      · simp only [indicator, hx, ite_false, zero_mul]
        have : Prod.mk x ⁻¹' {q : ℝ × (ℕ → ℝ) | 0 ≤ q.1 ∧ q.1 ≤ d ∧ (d - q.1, q.2) ∈ G R k} = ∅ := by
          ext y
          simp only [mem_preimage, mem_ofPred_eq, mem_empty_iff_false, iff_false]
          rintro ⟨h1, h2, -⟩
          exact hx ⟨h1, h2⟩
        rw [this, measure_empty]
    simp_rw [hpt]
    rw [lintegral_mul_const _ ((Measurable.ennreal_ofReal (by unfold poi; fun_prop)).indicator
      measurableSet_Icc), lintegral_window hr hd]

lemma nu_Good (hr : 0 < r) : ∀ L : List (ℝ × ℕ), (∀ p ∈ L, 0 ≤ p.1) →
    nu r (Good L) = ENNReal.ofReal ((L.map fun p => poi r p.1 p.2).prod) := by
  intro L
  induction L with
  | nil => intro; simp [Good]
  | cons p L ih =>
    intro hL
    have hp := hL p (List.mem_cons_self ..)
    have hL' : ∀ q ∈ L, 0 ≤ q.1 := fun q hq => hL q (List.mem_cons_of_mem _ hq)
    show nu r {e | (p.1, e) ∈ G (Good L) p.2} = _
    rw [nu_G hr (measurableSet_Good L) p.2 p.1 hp, ih hL', List.map_cons, List.prod_cons,
      ENNReal.ofReal_mul (poi_nonneg hr.le hp _)]

lemma expMeasure_Iic_zero (hr : 0 < r) : expMeasure r (Iic 0) = 0 := by
  have h := cdf_expMeasure_eq hr 0
  rw [cdf_eq_real] at h
  simp at h
  exact (measureReal_eq_zero_iff).1 h

lemma ae_pos (hr : 0 < r) (i : ℕ) : ∀ᵐ e ∂(nu r), 0 < e i := by
  rw [ae_iff]
  have : {e : ℕ → ℝ | ¬ 0 < e i} = (fun e : ℕ → ℝ => e i) ⁻¹' Iic 0 := by
    ext e; simp
  rw [this, ← Measure.map_apply (measurable_pi_apply i) measurableSet_Iic,
    Measure.infinitePi_map_eval, expMeasure_Iic_zero hr]

/-- The truncated gap used with the strong law. -/
noncomputable def trunc (x : ℝ) : ℝ := max (min x 1) 0

lemma measurable_trunc : Measurable trunc := by unfold trunc; fun_prop

lemma ae_nice (hr : 0 < r) : ∀ᵐ e ∂(nu r), Nice e := by
  have hpos : ∀ᵐ e ∂(nu r), ∀ i, 0 < e i := ae_all_iff.2 (ae_pos hr)
  set Y : ℕ → (ℕ → ℝ) → ℝ := fun i e => trunc (e i) with hY
  have hind : iIndepFun (fun i (e : ℕ → ℝ) => e i) (nu r) :=
    iIndepFun_infinitePi (X := fun _ x => x) (fun _ => measurable_id)
  have hindY : iIndepFun Y (nu r) := hind.comp (fun _ => trunc) (fun _ => measurable_trunc)
  have hmY : ∀ i, Measurable (Y i) := fun i => measurable_trunc.comp (measurable_pi_apply i)
  have hint : Integrable (Y 0) (nu r) := by
    refine Integrable.of_bound (hmY 0).aestronglyMeasurable 1 (Eventually.of_forall fun e => ?_)
    simp only [hY, trunc, Real.norm_eq_abs]
    rw [abs_le]; constructor
    · have := le_max_right (min (e 0) 1) 0; linarith
    · exact max_le (min_le_right _ _) zero_le_one
  have hident : ∀ i, IdentDistrib (Y i) (Y 0) (nu r) (nu r) := by
    intro i
    refine ⟨(hmY i).aemeasurable, (hmY 0).aemeasurable, ?_⟩
    have h1 : Y i = trunc ∘ (fun e : ℕ → ℝ => e i) := rfl
    have h2 : Y 0 = trunc ∘ (fun e : ℕ → ℝ => e 0) := rfl
    rw [h1, h2, ← Measure.map_map measurable_trunc (measurable_pi_apply i),
      ← Measure.map_map measurable_trunc (measurable_pi_apply 0),
      Measure.infinitePi_map_eval, Measure.infinitePi_map_eval]
  have hslln := strong_law_ae Y hint (fun i j hij => hindY.indepFun hij) hident
  have hmean : 0 < ∫ e, Y 0 e ∂(nu r) := by
    have hnn : 0 ≤ᵐ[nu r] Y 0 := Eventually.of_forall fun e => le_max_right _ _
    rw [integral_pos_iff_support_of_nonneg_ae hnn hint, pos_iff_ne_zero]
    intro h0
    have h1 := measure_eq_zero_iff_ae_notMem.1 h0
    have : ∀ᵐ e ∂(nu r), False := by
      filter_upwards [h1, hpos] with e h1 h2
      simp only [Function.mem_support, ne_eq, not_not, hY, trunc] at h1
      have : 0 < min (e 0) 1 := lt_min (h2 0) zero_lt_one
      have := le_max_left (min (e 0) 1) 0
      linarith
    rw [Filter.eventually_false_iff_eq_bot, ae_eq_bot] at this
    exact IsProbabilityMeasure.ne_zero _ this
  filter_upwards [hpos, hslln] with e hp hl
  refine ⟨hp, fun t => ?_⟩
  have hS : Tendsto (fun n : ℕ => ∑ i ∈ Finset.range n, Y i e) atTop atTop := by
    have := tendsto_natCast_atTop_atTop.atTop_mul_pos hmean hl
    refine this.congr' ?_
    filter_upwards [eventually_ge_atTop 1] with n hn
    simp only [smul_eq_mul]
    have : (n : ℝ) ≠ 0 := by positivity
    field_simp
  have hle : ∀ n, ∑ i ∈ Finset.range n, Y i e ≤ T e n := by
    intro n
    simp only [T, callTime]
    refine Finset.sum_le_sum fun i _ => ?_
    simp only [hY, trunc]
    exact max_le (min_le_left _ _) (hp i).le
  obtain ⟨n, hn⟩ := (hS.eventually_gt_atTop t).exists
  exact ⟨n, hn.trans_le (hle n)⟩

lemma finite_of_nice {e : ℕ → ℝ} (h : Nice e) (t : ℝ) : {n : ℕ | T e n ≤ t}.Finite := by
  obtain ⟨N, hN⟩ := h.2 t
  refine (Set.finite_lt_nat N).subset fun n hn => ?_
  by_contra hc
  simp only [mem_ofPred_eq, not_lt] at hn hc
  linarith [(T_strictMono h.1).monotone hc]

lemma CG_ofFn : ∀ (q : ℕ) (t : Fin (q + 1) → ℝ) (k : Fin q → ℕ) (K : ℕ) (e : ℕ → ℝ),
    cnt e (t 0) = K →
    (CG (List.ofFn fun j : Fin q => (t j.succ - t j.castSucc, k j)) (t 0) K e ↔
      ∀ j : Fin q, (cnt e (t j.succ) : ℤ) - cnt e (t j.castSucc) = k j) := by
  intro q
  induction q with
  | zero => intros; simp [CG]
  | succ q ih =>
    intro t k K e hK
    rw [List.ofFn_succ, Fin.forall_fin_succ]
    simp only [CG]
    have ht : t 0 + (t (Fin.succ 0) - t (Fin.castSucc 0)) = t (Fin.succ 0) := by
      simp
    rw [ht]
    have := ih (fun i => t i.succ) (fun i => k i.succ) (K + k 0) e
    simp only [Fin.succ_castSucc] at this
    simp only [Fin.castSucc_zero]
    constructor
    · rintro ⟨h1, h2⟩
      refine ⟨by rw [h1, hK]; push_cast; ring, (this h1).1 h2⟩
    · rintro ⟨h1, h2⟩
      have h1' : cnt e (t (Fin.succ 0)) = K + k 0 := by rw [hK] at h1; omega
      exact ⟨h1', (this h1').2 h2⟩

lemma law {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {E : ℕ → Ω → ℝ} (hind : iIndepFun E P) (hexp : ∀ n, HasLaw (E n) (expMeasure r) P) :
    HasLaw (fun ω i => E i ω) (nu r) P :=
  hind.hasLaw_infinitePi hexp (aemeasurable_pi_iff.2 fun i => (hexp i).aemeasurable)

end Helpers

#print axioms T_zero
#print axioms T_succ
#print axioms T_tl
#print axioms T_cs_succ
#print axioms T_cs_tl
#print axioms T_strictMono
#print axioms cnt_def
#print axioms cnt_eq_iff
#print axioms cnt_zero
#print axioms nice_tl
#print axioms nice_cs
#print axioms cnt_tl
#print axioms cnt_cs
#print axioms CG_tl
#print axioms CG_cs
#print axioms good_iff
#print axioms measurable_tl
#print axioms measurable_cs
#print axioms cs_tl
#print axioms poi_nonneg
#print axioms expMeasure_eq
#print axioms measurable_exponentialPDF
#print axioms lintegral_memoryless
#print axioms lintegral_window
#print axioms nu_split
#print axioms nu_split_apply
#print axioms nu_cs
#print axioms measurableSet_G
#print axioms measurableSet_Good
#print axioms nu_G
#print axioms nu_Good
#print axioms expMeasure_Iic_zero
#print axioms ae_pos
#print axioms measurable_trunc
#print axioms ae_nice
#print axioms finite_of_nice
#print axioms CG_ofFn
#print axioms law

/-- **Counts in a window are Poisson.** Let the gaps between calls `E_1, E_2, ...` be
independent, each exponential with rate `λ > 0`. Build the call times `T_n = E_1 + ... + E_n`
and the count `N(t)` = the largest `n` with `T_n ≤ t`. Then for every window from `s` to
`s + t` (with `s, t ≥ 0`) and every whole number `k`, the chance of exactly `k` calls in the
window is `e^(-λt) (λt)^k / k!`: the Poisson chance with mean rate times length, wherever the
window sits. -/
theorem increment_is_poisson {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (rate : ℝ) (hrate : 0 < rate) (E : ℕ → Ω → ℝ)
    (hind : iIndepFun E P) (hexp : ∀ n, HasLaw (E n) (expMeasure rate) P)
    (s t : ℝ) (hs : 0 ≤ s) (ht : 0 ≤ t) (k : ℕ) :
    P.real {ω | ((count E (s + t) ω : ℤ) - count E s ω) = k} =
      exp (-(rate * t)) * (rate * t) ^ k / k ! := by
  have := isProbabilityMeasure_expMeasure hrate
  have hL := law (r := rate) hind hexp
  have hsum : HasSum (fun n => poi rate s n) 1 := by
    have := hasSum_one_poissonMeasure ⟨rate * s, mul_nonneg hrate.le hs⟩
    exact this
  set Z : Set (ℕ → ℝ) := {e | ((cnt e (s + t) : ℤ) - cnt e s) = k} with hZdef
  set ZK : ℕ → Set (ℕ → ℝ) := fun K => {e | cnt e s = K ∧ cnt e (s + t) = K + k} with hZKdef
  have hZ : Z = ⋃ K, ZK K := by
    ext e
    simp only [hZdef, hZKdef, Set.mem_ofPred_eq, Set.mem_iUnion]
    constructor
    · intro h; exact ⟨cnt e s, rfl, by omega⟩
    · rintro ⟨K, h1, h2⟩; rw [h1, h2]; push_cast; ring
  have hLnn : ∀ K : ℕ, ∀ p ∈ [(s, K), (t, k)], 0 ≤ p.1 := by
    intro K p hp
    simp only [List.mem_cons, List.not_mem_nil, or_false] at hp
    rcases hp with rfl | rfl <;> assumption
  have hae : ∀ K, ZK K =ᵐ[nu rate] Good [(s, K), (t, k)] := by
    intro K
    rw [Filter.eventuallyEqSet_iff]
    filter_upwards [ae_nice hrate] with e he
    rw [good_iff _ (hLnn K) e he]
    simp only [hZKdef, Set.mem_ofPred_eq, CG, zero_add, and_true]
  have hnm : ∀ K, NullMeasurableSet (ZK K) (nu rate) := fun K =>
    (measurableSet_Good _).nullMeasurableSet.congr (hae K).symm
  have hdisj : Pairwise (Function.onFun (AEDisjoint (nu rate)) ZK) := by
    intro K K' hKK'
    refine Disjoint.aedisjoint (Set.disjoint_left.2 fun e h1 h2 => hKK' ?_)
    exact h1.1.symm.trans h2.1
  have hZm : NullMeasurableSet Z (nu rate) := by rw [hZ]; exact NullMeasurableSet.iUnion hnm
  have hset : {ω | ((count E (s + t) ω : ℤ) - count E s ω) = k} = (fun ω i => E i ω) ⁻¹' Z := rfl
  rw [hset, measureReal_def, ← Measure.map_apply₀ hL.aemeasurable (by rw [hL.map_eq]; exact hZm),
    hL.map_eq, hZ, measure_iUnion₀ hdisj hnm,
    tsum_congr (fun K => (measure_congr (hae K)).trans (nu_Good hrate _ (hLnn K)))]
  simp only [List.map_cons, List.map_nil, List.prod_cons, List.prod_nil, mul_one]
  simp_rw [ENNReal.ofReal_mul (poi_nonneg hrate.le hs _)]
  rw [ENNReal.tsum_mul_right, ← ENNReal.ofReal_tsum_of_nonneg (fun n => poi_nonneg hrate.le hs n)
    hsum.summable, hsum.tsum_eq, ENNReal.ofReal_one, one_mul,
    ENNReal.toReal_ofReal (poi_nonneg hrate.le ht k)]
  rfl

/-- **Counts in back-to-back windows are independent.** With the same gaps, take window ends
`0 = t_0 < t_1 < ... < t_q`. For every choice of counts `k_1, ..., k_q`, the chance of exactly
`k_j` calls in window `j` for every `j` at once is the product over the windows of the Poisson
chances `e^(-λ(t_j - t_(j-1))) (λ(t_j - t_(j-1)))^(k_j) / k_j!`. -/
theorem increments_independent {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (rate : ℝ) (hrate : 0 < rate) (E : ℕ → Ω → ℝ)
    (hind : iIndepFun E P) (hexp : ∀ n, HasLaw (E n) (expMeasure rate) P)
    (q : ℕ) (t : Fin (q + 1) → ℝ) (ht0 : t 0 = 0) (hmono : StrictMono t) (k : Fin q → ℕ) :
    P.real (⋂ j : Fin q,
        {ω | ((count E (t j.succ) ω : ℤ) - count E (t j.castSucc) ω) = k j}) =
      ∏ j : Fin q, exp (-(rate * (t j.succ - t j.castSucc))) *
        (rate * (t j.succ - t j.castSucc)) ^ (k j) / (k j) ! := by
  have := isProbabilityMeasure_expMeasure hrate
  have hL := law (r := rate) hind hexp
  set L := List.ofFn fun j : Fin q => (t j.succ - t j.castSucc, k j) with hLdef
  have hLnn : ∀ p ∈ L, 0 ≤ p.1 := by
    intro p hp
    rw [hLdef, List.mem_ofFn] at hp
    obtain ⟨j, rfl⟩ := hp
    exact sub_nonneg.2 (hmono Fin.castSucc_lt_succ).le
  set Y : Set (ℕ → ℝ) :=
    {e | ∀ j : Fin q, (cnt e (t j.succ) : ℤ) - cnt e (t j.castSucc) = k j} with hYdef
  have hset : (⋂ j : Fin q,
      {ω | ((count E (t j.succ) ω : ℤ) - count E (t j.castSucc) ω) = k j}) =
      (fun ω i => E i ω) ⁻¹' Y := by
    ext ω
    simp only [Set.mem_iInter, Set.mem_ofPred_eq, Set.mem_preimage, hYdef]
    rfl
  have hae : Y =ᵐ[nu rate] Good L := by
    rw [Filter.eventuallyEqSet_iff]
    filter_upwards [ae_nice hrate] with e he
    rw [good_iff L hLnn e he]
    have h0 : cnt e (t 0) = 0 := by rw [ht0]; exact cnt_zero he
    have := CG_ofFn q t k 0 e h0
    rw [ht0] at this
    exact this.symm
  have hY : NullMeasurableSet Y (Measure.map (fun ω i => E i ω) P) := by
    rw [hL.map_eq]; exact (measurableSet_Good L).nullMeasurableSet.congr hae.symm
  have hprod : 0 ≤ (L.map fun p => poi rate p.1 p.2).prod :=
    List.prod_nonneg fun a ha => by
      obtain ⟨p, hp, rfl⟩ := List.mem_map.1 ha
      exact poi_nonneg hrate.le (hLnn p hp) _
  rw [hset, measureReal_def, ← Measure.map_apply₀ hL.aemeasurable hY, hL.map_eq,
    measure_congr hae, nu_Good hrate L hLnn, ENNReal.toReal_ofReal hprod, hLdef, List.map_ofFn,
    List.prod_ofFn]
  rfl

/-- **The calls never pile up.** With the same gaps, with probability one only finitely many
calls come by any time `t`: the set of `n` with `T_n ≤ t` is finite for every `t`. -/
theorem calls_never_pile_up {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (rate : ℝ) (hrate : 0 < rate) (E : ℕ → Ω → ℝ)
    (hind : iIndepFun E P) (hexp : ∀ n, HasLaw (E n) (expMeasure rate) P) :
    ∀ᵐ ω ∂P, ∀ t : ℝ, {n : ℕ | callTime E n ω ≤ t}.Finite := by
  have := isProbabilityMeasure_expMeasure hrate
  have hL := law (r := rate) hind hexp
  have h : ∀ᵐ ω ∂P, Nice (fun i => E i ω) :=
    ae_of_ae_map hL.aemeasurable (by rw [hL.map_eq]; exact ae_nice hrate)
  filter_upwards [h] with ω hω t
  exact finite_of_nice hω t

/-! The card's worked numbers: `λ = 4` calls an hour, a quarter hour `t = 1/4`. -/

-- Expected calls in the quarter hour: λt = 4 × 1/4 = 1; the mean gap is 1/4 hour = 15 minutes.
example : (4 : ℝ) * (1 / 4) = 1 ∧ (1 : ℚ) / 4 * 60 = 15 := by norm_num
-- No call: e^(-1). Exactly one: e^(-1) × 1^1 / 1!. Exactly two: e^(-1) / 2. Exactly three: e^(-1) / 6.
example : exp (-((4 : ℝ) * (1 / 4))) * ((4 : ℝ) * (1 / 4)) ^ 0 / (0 ! : ℝ) = exp (-1) := by
  norm_num
example : exp (-((4 : ℝ) * (1 / 4))) * ((4 : ℝ) * (1 / 4)) ^ 1 / (1 ! : ℝ) = exp (-1) := by
  norm_num
example : exp (-((4 : ℝ) * (1 / 4))) * ((4 : ℝ) * (1 / 4)) ^ 2 / (2 ! : ℝ) = exp (-1) / 2 := by
  norm_num [Nat.factorial]
example : exp (-((4 : ℝ) * (1 / 4))) * ((4 : ℝ) * (1 / 4)) ^ 3 / (3 ! : ℝ) = exp (-1) / 6 := by
  norm_num [Nat.factorial]
-- Four or more: 1 - e^(-1) (1 + 1 + 1/2 + 1/6) = 1 - (8/3) e^(-1).
example : 1 - (exp (-1) + exp (-1) + exp (-1) / 2 + exp (-1) / 6) = 1 - 8 / 3 * exp (-1) := by
  ring
-- Three calls in the half hour: λt = 4 × 1/2 = 2, and e^(-2) × 2^3 / 3! = (4/3) e^(-2).
example : exp (-((4 : ℝ) * (1 / 2))) * ((4 : ℝ) * (1 / 2)) ^ 3 / (3 ! : ℝ) = 4 / 3 * exp (-2) := by
  norm_num [Nat.factorial]; ring
-- Running totals: variances 4 × 1/4 = 1 and 4 × 1/2 = 2, covariance 4 × 1/4 = 1,
-- correlation 1 / √(1 × 2) = 1/√2.
example : (4 : ℝ) * (1 / 4) / √((4 * (1 / 4)) * (4 * (1 / 2))) = 1 / √2 := by norm_num
-- The chart's mean line: 4 calls an hour over two hours is 8.
example : (4 : ℕ) * 2 = 8 := by norm_num

#print axioms increment_is_poisson
#print axioms increments_independent
#print axioms calls_never_pile_up

end PoissonProcess
