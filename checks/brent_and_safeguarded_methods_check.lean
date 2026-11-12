-- Brent's method: a guarded root search keeps a root within twice the tolerance and stops within (k + 1)(k + 2) evaluations, and its inverse quadratic step has the error law behind order 1.839.
import Mathlib.Analysis.SpecialFunctions.Log.Base
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.Analysis.Complex.Basic
import Mathlib.Order.Interval.Set.UnorderedInterval
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Analysis.Calculus.LocalExtr.Rolle
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Data.Finset.Sort
import Mathlib.Tactic.IntervalCases

open Filter Topology

namespace BrentSafeguarded

/-- The state of a guarded run: `a` is the previous best end, `b` the best end,
`c` the other end of the bracket, `s1` the length of the last step and `s2` the
length of the step before it. -/
structure GuardedState where
  a : ℝ
  b : ℝ
  c : ℝ
  s1 : ℝ
  s2 : ℝ

/-- Inverse quadratic interpolation: fit `t` as a quadratic in `f` through
`(fa, a)`, `(fb, b)`, `(fc, c)` and read it at `f = 0`. -/
noncomputable def iqi (a b c fa fb fc : ℝ) : ℝ :=
  a * fb * fc / ((fa - fb) * (fa - fc)) + b * fa * fc / ((fb - fa) * (fb - fc)) +
    c * fa * fb / ((fc - fa) * (fc - fb))

/-- Brent's fast-step proposal: IQI through `a`, `b`, `c` when `a ≠ c` and the three
residuals differ; otherwise the secant through `a` and `b` when `f a ≠ f b`;
otherwise `none` (no chord). -/
noncomputable def brentPropose (f : ℝ → ℝ) (a b c : ℝ) : Option ℝ :=
  if a ≠ c ∧ f a ≠ f b ∧ f a ≠ f c ∧ f b ≠ f c then some (iqi a b c (f a) (f b) (f c))
  else if f a ≠ f b then some (b - f b * (b - a) / (f b - f a))
  else none

/-- The next point a guarded step evaluates. With no chord, the midpoint `m`.
A proposal `p` is taken only if it lies on `c`'s side of `b`, within three quarters
of the bracket, and `max |p - b| δ < s2 / 2`; a taken proposal shorter than `δ` is
stretched to exactly `δ` toward `c` (a nudge). Otherwise the midpoint `m`. -/
noncomputable def guardedPoint (propose : ℝ → ℝ → ℝ → Option ℝ) (δ : ℝ)
    (s : GuardedState) : ℝ :=
  match propose s.a s.b s.c with
  | none => (s.b + s.c) / 2
  | some p =>
    if 0 < (p - s.b) * (s.c - s.b) ∧ |p - s.b| < 3 / 4 * |s.c - s.b| ∧
        max |p - s.b| δ < s.s2 / 2 then
      (if |p - s.b| < δ then (if s.b < s.c then s.b + δ else s.b - δ) else p)
    else (s.b + s.c) / 2

/-- One guarded step: evaluate `f` at the new point, keep the half with the sign
change, make the end with the smaller `|f|` the best end, and record the step length. -/
noncomputable def guardedStep (f : ℝ → ℝ) (propose : ℝ → ℝ → ℝ → Option ℝ) (δ : ℝ)
    (s : GuardedState) : GuardedState :=
  let new := guardedPoint propose δ s
  let c' := if (f new < 0 ↔ f s.c < 0) then s.b else s.c
  if |f c'| < |f new| then ⟨s.b, c', new, |new - s.b|, s.s1⟩
  else ⟨s.b, new, c', |new - s.b|, s.s1⟩

/-- The start of a run on `[lo, hi]`: the end with the smaller `|f|` is the best end,
the previous best end is the other end, and both earlier step lengths are the width. -/
noncomputable def guardedStart (f : ℝ → ℝ) (lo hi : ℝ) : GuardedState :=
  if |f lo| < |f hi| then ⟨hi, lo, hi, |hi - lo|, |hi - lo|⟩
  else ⟨lo, hi, lo, |hi - lo|, |hi - lo|⟩

/-- The run stops when half the bracket width is at most `δ`, or the best end is a root. -/
def GuardedStopped (f : ℝ → ℝ) (δ : ℝ) (s : GuardedState) : Prop :=
  |s.c - s.b| / 2 ≤ δ ∨ f s.b = 0

/-- Bisection's count of halvings: `k = ⌈log₂ (W₀ / (2δ))⌉`. -/
noncomputable def bisectionCount (W₀ δ : ℝ) : ℕ :=
  ⌈Real.logb 2 (W₀ / (2 * δ))⌉₊

/-- Where a guarded step lands: inside the bracket, and either a fast step of length
between `δ` and `s2 / 2`, or the midpoint. -/
lemma guardedPoint_spec (propose : ℝ → ℝ → ℝ → Option ℝ) {δ : ℝ} (hδ : 0 < δ)
    (s : GuardedState) (hw : 2 * δ < |s.c - s.b|) :
    guardedPoint propose δ s ∈ Set.uIcc s.b s.c ∧
      ((δ ≤ |guardedPoint propose δ s - s.b| ∧ |guardedPoint propose δ s - s.b| < s.s2 / 2) ∨
        guardedPoint propose δ s = (s.b + s.c) / 2) := by
  have hmid : (s.b + s.c) / 2 ∈ Set.uIcc s.b s.c := by
    rw [Set.mem_uIcc]
    rcases le_total s.b s.c with h | h
    · left; constructor <;> linarith
    · right; constructor <;> linarith
  unfold guardedPoint
  rcases hp : propose s.a s.b s.c with _ | p
  · exact ⟨hmid, Or.inr rfl⟩
  · simp only
    split_ifs with hg hlt hbc
    · have hcb : |s.c - s.b| = s.c - s.b := abs_of_pos (by linarith)
      rw [hcb] at hw
      refine ⟨Set.mem_uIcc.mpr (Or.inl ⟨by linarith, by linarith⟩), Or.inl ?_⟩
      rw [show s.b + δ - s.b = δ by ring, abs_of_pos hδ]
      exact ⟨le_rfl, lt_of_le_of_lt (le_max_right _ _) hg.2.2⟩
    · have hne : s.c ≠ s.b := by
        intro h; rw [h, sub_self, mul_zero] at hg; exact lt_irrefl _ hg.1
      have hcb' : s.c < s.b := lt_of_le_of_ne (not_lt.mp hbc) hne
      have hcb : |s.c - s.b| = s.b - s.c := by rw [abs_of_neg (by linarith)]; ring
      rw [hcb] at hw
      refine ⟨Set.mem_uIcc.mpr (Or.inr ⟨by linarith, by linarith⟩), Or.inl ?_⟩
      rw [show s.b - δ - s.b = -δ by ring, abs_neg, abs_of_pos hδ]
      exact ⟨le_rfl, lt_of_le_of_lt (le_max_right _ _) hg.2.2⟩
    · obtain ⟨h1, h2, h3⟩ := hg
      refine ⟨?_, Or.inl ⟨not_lt.mp hlt, lt_of_le_of_lt (le_max_left _ _) h3⟩⟩
      rw [Set.mem_uIcc]
      rcases lt_trichotomy s.b s.c with h | h | h
      · have hpb : 0 < p - s.b := by
          by_contra hc; push Not at hc; nlinarith
        rw [abs_of_pos hpb, abs_of_pos (by linarith : (0:ℝ) < s.c - s.b)] at h2
        left; constructor <;> linarith
      · rw [h, sub_self, mul_zero] at h1; exact absurd h1 (lt_irrefl _)
      · have hpb : p - s.b < 0 := by
          by_contra hc; push Not at hc; nlinarith
        rw [abs_of_neg hpb, abs_of_neg (by linarith : s.c - s.b < (0:ℝ))] at h2
        right; constructor <;> linarith
    · exact ⟨hmid, Or.inr rfl⟩

#print axioms guardedPoint_spec

/-- The shape of one guarded step: the new bracket is the new point and one old end. -/
lemma guardedStep_spec (f : ℝ → ℝ) (propose : ℝ → ℝ → ℝ → Option ℝ) (δ : ℝ)
    (s : GuardedState) :
    ∃ c' : ℝ, (c' = s.b ∨ c' = s.c) ∧
      ((f (guardedPoint propose δ s) < 0 ↔ f s.c < 0) → c' = s.b) ∧
      (¬(f (guardedPoint propose δ s) < 0 ↔ f s.c < 0) → c' = s.c) ∧
      (guardedStep f propose δ s = ⟨s.b, c', guardedPoint propose δ s,
          |guardedPoint propose δ s - s.b|, s.s1⟩ ∨
        guardedStep f propose δ s = ⟨s.b, guardedPoint propose δ s, c',
          |guardedPoint propose δ s - s.b|, s.s1⟩) := by
  by_cases h : (f (guardedPoint propose δ s) < 0 ↔ f s.c < 0)
  · refine ⟨s.b, Or.inl rfl, fun _ => rfl, fun h' => absurd h h', ?_⟩
    simp only [guardedStep, h, ↓reduceIte]
    split_ifs
    · left; rfl
    · right; rfl
  · refine ⟨s.c, Or.inr rfl, fun h' => absurd h' h, fun _ => rfl, ?_⟩
    simp only [guardedStep, h, ↓reduceIte]
    split_ifs
    · left; rfl
    · right; rfl

#print axioms guardedStep_spec

/-- The invariant of a run that has not yet stopped, after `n` steps. `M` counts the
halvings so far, and `a`, `b'` are levels of the last two step lengths. -/
def GInv (f : ℝ → ℝ) (lo hi δ : ℝ) (k n : ℕ) (s : GuardedState) : Prop :=
  ∃ M a b' : ℕ, M ≤ k ∧ a ≤ k ∧ b' ≤ k ∧ n ≤ a + b' + M * k ∧
    |s.c - s.b| * 2 ^ M ≤ 2 ^ (k + 1) * δ ∧ s.s1 * 2 ^ a ≤ 2 ^ (k + 1) * δ ∧
    s.s2 * 2 ^ b' ≤ 2 ^ (k + 1) * δ ∧ s.b ∈ Set.uIcc lo hi ∧ s.c ∈ Set.uIcc lo hi ∧
    ¬(f s.b < 0 ↔ f s.c < 0)

lemma two_pow_lt_imp {i j : ℕ} {δ : ℝ} (hδ : 0 < δ) (h : δ * 2 ^ i < 2 ^ j * δ) : i < j := by
  by_contra hc
  push Not at hc
  have : (2 : ℝ) ^ j ≤ 2 ^ i := pow_le_pow_right₀ (by norm_num) hc
  nlinarith

#print axioms two_pow_lt_imp

lemma ginv_step (f : ℝ → ℝ) (propose : ℝ → ℝ → ℝ → Option ℝ) {lo hi δ : ℝ} (hδ : 0 < δ)
    (k n : ℕ) (s : GuardedState) (hI : GInv f lo hi δ k n s) (hns : ¬ GuardedStopped f δ s) :
    GInv f lo hi δ k (n + 1) (guardedStep f propose δ s) := by
  obtain ⟨M, a, b', hM, ha, hb, hn, hw, h1, h2, hbm, hcm, hsg⟩ := hI
  have hw2 : 2 * δ < |s.c - s.b| := by
    unfold GuardedStopped at hns; push Not at hns; linarith [hns.1]
  obtain ⟨hx, hcase⟩ := guardedPoint_spec propose hδ s hw2
  set x := guardedPoint propose δ s with hxdef
  obtain ⟨c', hc', hc1, hc2, hst⟩ := guardedStep_spec f propose δ s
  rw [← hxdef] at hc1 hc2 hst
  have hsub : Set.uIcc s.b s.c ⊆ Set.uIcc lo hi := Set.uIcc_subset_uIcc hbm hcm
  have hxm : x ∈ Set.uIcc lo hi := hsub hx
  have hc'm : c' ∈ Set.uIcc lo hi := by rcases hc' with h | h <;> rw [h] <;> assumption
  have hsign : ¬(f x < 0 ↔ f c' < 0) := by
    by_cases h : (f x < 0 ↔ f s.c < 0)
    · rw [hc1 h]; tauto
    · rw [hc2 h]; exact h
  have hwid : |x - c'| ≤ |s.c - s.b| := by
    rcases hc' with h | h <;> rw [h]
    · exact Set.abs_sub_left_of_mem_uIcc hx
    · rw [abs_sub_comm]; exact Set.abs_sub_right_of_mem_uIcc hx
  have hp2M : (0 : ℝ) < 2 ^ M := by positivity
  have hp2b : (0 : ℝ) < 2 ^ b' := by positivity
  rcases hcase with ⟨hL1, hL2⟩ | hmid
  · -- a fast step
    have hnew1 : |x - s.b| * 2 ^ (b' + 1) ≤ 2 ^ (k + 1) * δ := by
      rw [pow_succ]; nlinarith
    have hbk : b' + 1 ≤ k := by
      have : δ * 2 ^ (b' + 1) < 2 ^ (k + 1) * δ := by
        rw [pow_succ] at hnew1 ⊢; nlinarith
      have := two_pow_lt_imp hδ this
      omega
    have hwid' : |x - c'| * 2 ^ M ≤ 2 ^ (k + 1) * δ := by nlinarith
    refine ⟨M, b' + 1, a, hM, hbk, ha, by linarith, ?_⟩
    rcases hst with h | h <;> rw [h] <;> dsimp only
    · exact ⟨hwid', hnew1, h1, hc'm, hxm, fun h' => hsign h'.symm⟩
    · exact ⟨by rw [abs_sub_comm]; exact hwid', hnew1, h1, hxm, hc'm, hsign⟩
  · -- a halving
    have hhalf : |x - s.b| = |s.c - s.b| / 2 := by
      rw [hmid, show (s.b + s.c) / 2 - s.b = (s.c - s.b) / 2 by ring, abs_div,
        abs_of_pos (by norm_num : (0:ℝ) < 2)]
    have hhalf' : |x - c'| = |s.c - s.b| / 2 := by
      rcases hc' with h | h <;> rw [h]
      · exact hhalf
      · rw [hmid, show (s.b + s.c) / 2 - s.c = -((s.c - s.b) / 2) by ring, abs_neg, abs_div,
          abs_of_pos (by norm_num : (0:ℝ) < 2)]
    have hnew : |s.c - s.b| / 2 * 2 ^ (M + 1) ≤ 2 ^ (k + 1) * δ := by
      rw [pow_succ]; nlinarith
    have hMk : M + 1 ≤ k := by
      have : δ * 2 ^ (M + 1) < 2 ^ (k + 1) * δ := by
        rw [pow_succ]; nlinarith
      have := two_pow_lt_imp hδ this
      omega
    refine ⟨M + 1, M + 1, a, hMk, hMk, ha, ?_, ?_⟩
    · have : (M + 1) * k = M * k + k := by ring
      rw [this]; linarith
    rcases hst with h | h <;> rw [h] <;> dsimp only
    · exact ⟨by rw [hhalf']; exact hnew, by rw [hhalf]; exact hnew, h1, hc'm, hxm,
        fun h' => hsign h'.symm⟩
    · exact ⟨by rw [abs_sub_comm, hhalf']; exact hnew, by rw [hhalf]; exact hnew, h1, hxm, hc'm,
        hsign⟩

#print axioms ginv_step

lemma width_le_pow (W δ : ℝ) (hW : 0 < W) (hδ : 0 < δ) :
    W ≤ 2 ^ (bisectionCount W δ + 1) * δ := by
  have hx : 0 < W / (2 * δ) := by positivity
  have h1 : W / (2 * δ) ≤ 2 ^ bisectionCount W δ := by
    calc W / (2 * δ) = (2 : ℝ) ^ (Real.logb 2 (W / (2 * δ))) :=
          (Real.rpow_logb (by norm_num) (by norm_num) hx).symm
      _ ≤ (2 : ℝ) ^ ((bisectionCount W δ : ℕ) : ℝ) :=
          Real.rpow_le_rpow_of_exponent_le (by norm_num) (Nat.le_ceil _)
      _ = 2 ^ bisectionCount W δ := Real.rpow_natCast _ _
  rw [div_le_iff₀ (by positivity)] at h1
  rw [pow_succ]; linarith

#print axioms width_le_pow

lemma ginv_start (f : ℝ → ℝ) {lo hi δ : ℝ} (hsign : f lo * f hi < 0) (hδ : 0 < δ) :
    GInv f lo hi δ (bisectionCount |hi - lo| δ) 0 (guardedStart f lo hi) := by
  have hne : lo ≠ hi := by
    intro h; rw [h] at hsign; nlinarith [mul_self_nonneg (f hi)]
  have hW : 0 < |hi - lo| := abs_pos.mpr (sub_ne_zero.mpr (Ne.symm hne))
  have hD := width_le_pow |hi - lo| δ hW hδ
  set k := bisectionCount |hi - lo| δ
  have hs : ¬(f lo < 0 ↔ f hi < 0) := by
    intro h
    by_cases h1 : f lo < 0
    · nlinarith [h.mp h1]
    · have h2 : ¬ f hi < 0 := fun h2 => h1 (h.mpr h2)
      push Not at h1 h2; nlinarith
  refine ⟨0, 0, 0, Nat.zero_le _, Nat.zero_le _, Nat.zero_le _, by simp, ?_⟩
  unfold guardedStart
  split_ifs
  · dsimp only
    simp only [pow_zero, mul_one]
    exact ⟨hD, hD, hD, Set.left_mem_uIcc, Set.right_mem_uIcc, hs⟩
  · dsimp only
    simp only [pow_zero, mul_one]
    rw [abs_sub_comm lo hi]
    exact ⟨hD, hD, hD, Set.right_mem_uIcc, Set.left_mem_uIcc, fun h => hs h.symm⟩

#print axioms ginv_start

/-- **Brent's guarantee.** For a residual `f` continuous on the bracket, with opposite
signs at its two ends, and a tolerance `δ > 0`, the guarded method, with Brent's
IQI-or-secant proposal or any other choice of fast step, stops after `n` steps with
`n + 2 ≤ (k + 1)(k + 2)` evaluations in all, `k` being bisection's count of halvings;
and the answer it returns lies within `2δ` of a root inside the starting bracket. -/
theorem guarded_method_keeps_root_within_square_of_bisection_count
    (f : ℝ → ℝ) (propose : ℝ → ℝ → ℝ → Option ℝ) {lo hi δ : ℝ}
    (hcont : ContinuousOn f (Set.uIcc lo hi)) (hsign : f lo * f hi < 0) (hδ : 0 < δ) :
    ∃ n : ℕ,
      n + 2 ≤ (bisectionCount |hi - lo| δ + 1) * (bisectionCount |hi - lo| δ + 2) ∧
      GuardedStopped f δ ((guardedStep f propose δ)^[n] (guardedStart f lo hi)) ∧
      (∀ m < n, ¬ GuardedStopped f δ ((guardedStep f propose δ)^[m] (guardedStart f lo hi))) ∧
      ∃ t ∈ Set.uIcc lo hi, f t = 0 ∧
        |((guardedStep f propose δ)^[n] (guardedStart f lo hi)).b - t| ≤ 2 * δ := by
  classical
  set k := bisectionCount |hi - lo| δ with hk
  have hinv : ∀ n, (∀ m < n, ¬ GuardedStopped f δ
      ((guardedStep f propose δ)^[m] (guardedStart f lo hi))) →
      GInv f lo hi δ k n ((guardedStep f propose δ)^[n] (guardedStart f lo hi)) := by
    intro n
    induction n with
    | zero => intro _; exact ginv_start f hsign hδ
    | succ n ih =>
      intro hm
      have h := ginv_step f propose hδ k n _ (ih fun m hm' => hm m (by omega)) (hm n (by omega))
      rwa [Function.iterate_succ_apply']
  have hbound : ∃ m ≤ k * k + 2 * k,
      GuardedStopped f δ ((guardedStep f propose δ)^[m] (guardedStart f lo hi)) := by
    by_contra hno
    push Not at hno
    obtain ⟨M, a, b', hM, ha, hb, hn, -⟩ :=
      hinv (k * k + 2 * k + 1) (fun m hm => hno m (by omega))
    nlinarith
  have hex : ∃ m, GuardedStopped f δ ((guardedStep f propose δ)^[m] (guardedStart f lo hi)) :=
    let ⟨m, _, hm⟩ := hbound; ⟨m, hm⟩
  obtain ⟨m0, hm0, hm0s⟩ := hbound
  refine ⟨Nat.find hex, ?_, Nat.find_spec hex, fun m hm => Nat.find_min hex hm, ?_⟩
  · have := Nat.find_min' hex hm0s
    nlinarith
  obtain ⟨M, a, b', -, -, -, -, -, -, -, hbm, hcm, hsg⟩ :=
    hinv (Nat.find hex) (fun m hm => Nat.find_min hex hm)
  set s := (guardedStep f propose δ)^[Nat.find hex] (guardedStart f lo hi)
  rcases Nat.find_spec hex with hw | hroot
  · have hc : ContinuousOn f (Set.uIcc s.b s.c) := hcont.mono (Set.uIcc_subset_uIcc hbm hcm)
    have h0 : (0 : ℝ) ∈ Set.uIcc (f s.b) (f s.c) := by
      rw [Set.mem_uIcc]
      by_cases h1 : f s.b < 0
      · have h2 : ¬ f s.c < 0 := fun h2 => hsg ⟨fun _ => h2, fun _ => h1⟩
        left; constructor <;> linarith
      · have h2 : f s.c < 0 := by by_contra h2; exact hsg ⟨fun h => absurd h h1, fun h => absurd h h2⟩
        right; constructor <;> linarith
    obtain ⟨t, ht, hft⟩ := intermediate_value_uIcc hc h0
    refine ⟨t, Set.uIcc_subset_uIcc hbm hcm ht, hft, ?_⟩
    rw [abs_sub_comm]
    have := Set.abs_sub_left_of_mem_uIcc ht
    linarith
  · exact ⟨s.b, hbm, hroot, by simp; linarith⟩

/-- Rolle's theorem applied `n` times: if `D 0` vanishes at `n + 1` increasing points of an
interval on which each `D m` has derivative `D (m + 1)`, then `D n` vanishes between the
first and the last point. -/
lemma rolle_chain : ∀ (n : ℕ) (D : ℕ → ℝ → ℝ) (I : Set ℝ), I.OrdConnected →
    (∀ m < n, ∀ x ∈ I, HasDerivAt (D m) (D (m + 1) x) x) →
    ∀ t : Fin (n + 1) → ℝ, StrictMono t → (∀ i, t i ∈ I) → (∀ i, D 0 (t i) = 0) →
    ∃ ξ ∈ Set.Icc (t 0) (t (Fin.last n)), D n ξ = 0 := by
  intro n
  induction n with
  | zero =>
    intro D I _ _ t _ _ hz
    exact ⟨t 0, ⟨le_rfl, le_rfl⟩, hz 0⟩
  | succ n ih =>
    intro D I hI hD t ht htI hz
    have hstep : ∀ i : Fin (n + 1), ∃ u ∈ Set.Ioo (t i.castSucc) (t i.succ), D 1 u = 0 := by
      intro i
      have hlt : t i.castSucc < t i.succ := ht (Fin.castSucc_lt_succ)
      have hsub : Set.Icc (t i.castSucc) (t i.succ) ⊆ I := hI.out (htI _) (htI _)
      apply exists_hasDerivAt_eq_zero hlt
      · intro x hx
        exact (hD 0 (by omega) x (hsub hx)).continuousAt.continuousWithinAt
      · rw [hz, hz]
      · intro x hx
        exact hD 0 (by omega) x (hsub (Set.Ioo_subset_Icc_self hx))
    choose u hu hu0 using hstep
    have humono : StrictMono u := by
      rw [Fin.strictMono_iff_lt_succ]
      intro i
      have h1 := (hu i.castSucc).2
      have h2 := (hu i.succ).1
      rw [Fin.succ_castSucc] at h1
      exact lt_trans h1 h2
    have huI : ∀ i, u i ∈ I := fun i =>
      hI.out (htI _) (htI _) (Set.Ioo_subset_Icc_self (hu i))
    obtain ⟨ξ, hξ, hξ0⟩ := ih (fun m => D (m + 1)) I hI
      (fun m hm x hx => hD (m + 1) (by omega) x hx) u humono huI hu0
    refine ⟨ξ, ⟨?_, ?_⟩, hξ0⟩
    · have := (hu 0).1
      simp only [Fin.castSucc_zero] at this
      linarith [hξ.1]
    · have := (hu (Fin.last n)).2
      simp only [Fin.succ_last] at this
      linarith [hξ.2]

#print axioms rolle_chain

/-- The same for `n + 1` distinct points given as a finite set, in any order. -/
lemma rolle_finset (n : ℕ) (D : ℕ → ℝ → ℝ) (I : Set ℝ) (hI : I.OrdConnected)
    (hD : ∀ m < n, ∀ x ∈ I, HasDerivAt (D m) (D (m + 1) x) x)
    (s : Finset ℝ) (hs : s.card = n + 1) (hsI : ∀ x ∈ s, x ∈ I) (hz : ∀ x ∈ s, D 0 x = 0) :
    ∃ ξ, ∃ a ∈ s, ∃ b ∈ s, a ≤ ξ ∧ ξ ≤ b ∧ D n ξ = 0 := by
  obtain ⟨ξ, hξ, hξ0⟩ := rolle_chain n D I hI hD (s.orderEmbOfFin hs)
    (s.orderEmbOfFin hs).strictMono (fun i => hsI _ (s.orderEmbOfFin_mem hs i))
    (fun i => hz _ (s.orderEmbOfFin_mem hs i))
  exact ⟨ξ, _, s.orderEmbOfFin_mem hs 0, _, s.orderEmbOfFin_mem hs (Fin.last n), hξ.1, hξ.2, hξ0⟩

#print axioms rolle_finset

/-- The IQI value is the constant term of the quadratic in `y` through the three points. -/
lemma iqi_interp (x0 x1 x2 y0 y1 y2 : ℝ) (h01 : y0 ≠ y1) (h02 : y0 ≠ y2) (h12 : y1 ≠ y2) :
    ∃ c1 c2 : ℝ, iqi x0 x1 x2 y0 y1 y2 + c1 * y0 + c2 * (y0 * y0) = x0 ∧
      iqi x0 x1 x2 y0 y1 y2 + c1 * y1 + c2 * (y1 * y1) = x1 ∧
      iqi x0 x1 x2 y0 y1 y2 + c1 * y2 + c2 * (y2 * y2) = x2 := by
  have a1 : y0 - y1 ≠ 0 := sub_ne_zero.mpr h01
  have a2 : y0 - y2 ≠ 0 := sub_ne_zero.mpr h02
  have a3 : y1 - y2 ≠ 0 := sub_ne_zero.mpr h12
  have a4 : y1 - y0 ≠ 0 := sub_ne_zero.mpr h01.symm
  have a5 : y2 - y0 ≠ 0 := sub_ne_zero.mpr h02.symm
  have a6 : y2 - y1 ≠ 0 := sub_ne_zero.mpr h12.symm
  refine ⟨-(x0 * (y1 + y2) / ((y0 - y1) * (y0 - y2)) + x1 * (y0 + y2) / ((y1 - y0) * (y1 - y2)) +
      x2 * (y0 + y1) / ((y2 - y0) * (y2 - y1))),
    x0 / ((y0 - y1) * (y0 - y2)) + x1 / ((y1 - y0) * (y1 - y2)) + x2 / ((y2 - y0) * (y2 - y1)),
    ?_, ?_, ?_⟩ <;>
  · unfold iqi
    field_simp
    ring

#print axioms iqi_interp

/-- One IQI step, by Rolle's theorem: the interpolating quadratic's coefficients satisfy two
equations at points `η`, `ζ` near the root, and the error ratio a third at a point `ξ`. -/
lemma iqi_rolle (f f1 f2 f3 : ℝ → ℝ) (I : Set ℝ) (hI : I.OrdConnected)
    (hd0 : ∀ x ∈ I, HasDerivAt f (f1 x) x) (hd1 : ∀ x ∈ I, HasDerivAt f1 (f2 x) x)
    (hd2 : ∀ x ∈ I, HasDerivAt f2 (f3 x) x)
    (r x0 x1 x2 : ℝ) (hr : r ∈ I) (h0 : x0 ∈ I) (h1 : x1 ∈ I) (h2 : x2 ∈ I)
    (hroot : f r = 0) (hinj : ∀ u ∈ I, ∀ v ∈ I, u ≠ v → f u ≠ f v)
    (h01 : x0 ≠ x1) (h02 : x0 ≠ x2) (h12 : x1 ≠ x2) (h0r : x0 ≠ r) (h1r : x1 ≠ r)
    (h2r : x2 ≠ r) :
    ∃ c1 c2 η ζ ξ : ℝ,
      |η - r| ≤ max |x0 - r| (max |x1 - r| |x2 - r|) ∧
      |ζ - r| ≤ max |x0 - r| (max |x1 - r| |x2 - r|) ∧
      |ξ - r| ≤ max |x0 - r| (max |x1 - r| |x2 - r|) ∧
      c1 * f1 η + c2 * (2 * f η * f1 η) - 1 = 0 ∧
      c1 * f2 ζ + c2 * (2 * (f1 ζ * f1 ζ + f ζ * f2 ζ)) = 0 ∧
      c1 * f3 ξ + c2 * (6 * f1 ξ * f2 ξ + 2 * f ξ * f3 ξ) +
        6 * ((iqi x0 x1 x2 (f x0) (f x1) (f x2) - r) / ((x2 - r) * (x1 - r) * (x0 - r))) = 0 := by
  set Mx := max |x0 - r| (max |x1 - r| |x2 - r|) with hMx
  have hmem : ∀ a, (a = x0 ∨ a = x1 ∨ a = x2 ∨ a = r) → |a - r| ≤ Mx := by
    intro a ha
    rcases ha with rfl | rfl | rfl | rfl
    · exact le_max_left _ _
    · exact le_trans (le_max_left _ _) (le_max_right _ _)
    · exact le_trans (le_max_right _ _) (le_max_right _ _)
    · simp only [sub_self, abs_zero, hMx]; positivity
  have hbetween : ∀ ξ a b, |a - r| ≤ Mx → |b - r| ≤ Mx → a ≤ ξ → ξ ≤ b → |ξ - r| ≤ Mx := by
    intro ξ a b ha hb h1 h2
    rw [abs_le] at *
    constructor <;> linarith [ha.1, hb.2]
  obtain ⟨c1, c2, e0, e1, e2⟩ := iqi_interp x0 x1 x2 (f x0) (f x1) (f x2)
    (hinj _ h0 _ h1 h01) (hinj _ h0 _ h2 h02) (hinj _ h1 _ h2 h12)
  set c0 := iqi x0 x1 x2 (f x0) (f x1) (f x2) with hc0
  set Q0 : ℝ → ℝ := fun t => c0 + c1 * f t + c2 * (f t * f t) - t with hQ0
  set Q1 : ℝ → ℝ := fun t => c1 * f1 t + c2 * (2 * f t * f1 t) - 1 with hQ1
  set Q2 : ℝ → ℝ := fun t => c1 * f2 t + c2 * (2 * (f1 t * f1 t + f t * f2 t)) with hQ2
  set Q3 : ℝ → ℝ := fun t => c1 * f3 t + c2 * (6 * f1 t * f2 t + 2 * f t * f3 t) with hQ3
  have dQ0 : ∀ x ∈ I, HasDerivAt Q0 (Q1 x) x := by
    intro x hx
    have := (((hasDerivAt_const x c0).add ((hd0 x hx).const_mul c1)).add
      (((hd0 x hx).mul (hd0 x hx)).const_mul c2)).sub (hasDerivAt_id' x)
    exact this.congr_deriv (by simp only [hQ1]; ring)
  have dQ1 : ∀ x ∈ I, HasDerivAt Q1 (Q2 x) x := by
    intro x hx
    have := (((hd1 x hx).const_mul c1).add
      ((((hd0 x hx).const_mul 2).mul (hd1 x hx)).const_mul c2)).sub (hasDerivAt_const x (1:ℝ))
    exact this.congr_deriv (by simp only [hQ2]; ring)
  have dQ2 : ∀ x ∈ I, HasDerivAt Q2 (Q3 x) x := by
    intro x hx
    have := ((hd2 x hx).const_mul c1).add
      (((((hd1 x hx).mul (hd1 x hx)).add ((hd0 x hx).mul (hd2 x hx))).const_mul 2).const_mul c2)
    exact this.congr_deriv (by simp only [hQ3]; ring)
  have hQx0 : Q0 x0 = 0 := by simp only [hQ0]; linarith
  have hQx1 : Q0 x1 = 0 := by simp only [hQ0]; linarith
  have hQx2 : Q0 x2 = 0 := by simp only [hQ0]; linarith
  set DQ : ℕ → ℝ → ℝ := fun m => match m with
    | 0 => Q0 | 1 => Q1 | 2 => Q2 | _ => Q3 with hDQ
  have hDQ' : ∀ m < 3, ∀ x ∈ I, HasDerivAt (DQ m) (DQ (m + 1) x) x := by
    intro m hm x hx
    interval_cases m
    · exact dQ0 x hx
    · exact dQ1 x hx
    · exact dQ2 x hx
  -- η: Q0 vanishes at x0, x1
  obtain ⟨η, a, ha, b, hb, hab1, hab2, hη⟩ := rolle_finset 1 DQ I hI
    (fun m hm x hx => hDQ' m (by omega) x hx) {x0, x1} (Finset.card_pair h01)
    (by intro a ha; simp only [Finset.mem_insert, Finset.mem_singleton] at ha
        rcases ha with rfl | rfl <;> assumption)
    (by intro a ha; simp only [Finset.mem_insert, Finset.mem_singleton] at ha
        rcases ha with rfl | rfl <;> assumption)
  have hηb : |η - r| ≤ Mx := by
    simp only [Finset.mem_insert, Finset.mem_singleton] at ha hb
    exact hbetween η a b (hmem a (by tauto)) (hmem b (by tauto)) hab1 hab2
  -- ζ: Q0 vanishes at x0, x1, x2
  have hc3 : ({x0, x1, x2} : Finset ℝ).card = 2 + 1 := by
    rw [Finset.card_insert_of_notMem (by simp [h01, h02]), Finset.card_pair h12]
  obtain ⟨ζ, a', ha', b', hb', hab1', hab2', hζ⟩ := rolle_finset 2 DQ I hI
    (fun m hm x hx => hDQ' m (by omega) x hx) {x0, x1, x2} hc3
    (by intro a ha; simp only [Finset.mem_insert, Finset.mem_singleton] at ha
        rcases ha with rfl | rfl | rfl <;> assumption)
    (by intro a ha; simp only [Finset.mem_insert, Finset.mem_singleton] at ha
        rcases ha with rfl | rfl | rfl <;> assumption)
  have hζb : |ζ - r| ≤ Mx := by
    simp only [Finset.mem_insert, Finset.mem_singleton] at ha' hb'
    exact hbetween ζ a' b' (hmem a' (by tauto)) (hmem b' (by tauto)) hab1' hab2'
  -- ξ: the error function vanishes at x0, x1, x2, r
  have hd : (x2 - r) * (x1 - r) * (x0 - r) ≠ 0 := by
    have := sub_ne_zero.mpr h0r; have := sub_ne_zero.mpr h1r; have := sub_ne_zero.mpr h2r
    positivity
  set K : ℝ := -((c0 - r) / ((x2 - r) * (x1 - r) * (x0 - r))) with hK
  set H0 : ℝ → ℝ := fun t => Q0 t - K * ((t - x0) * (t - x1) * (t - x2)) with hH0
  set H1 : ℝ → ℝ := fun t => Q1 t - K * ((t - x1) * (t - x2) + (t - x0) * (t - x2) +
    (t - x0) * (t - x1)) with hH1
  set H2 : ℝ → ℝ := fun t => Q2 t - K * (2 * ((t - x0) + (t - x1) + (t - x2))) with hH2
  set H3 : ℝ → ℝ := fun t => Q3 t - K * 6 with hH3
  have dH0 : ∀ x ∈ I, HasDerivAt H0 (H1 x) x := by
    intro x hx
    have := (dQ0 x hx).sub (((((hasDerivAt_id' x).sub_const x0).mul
      ((hasDerivAt_id' x).sub_const x1)).mul ((hasDerivAt_id' x).sub_const x2)).const_mul K)
    exact this.congr_deriv (by simp only [hH1, Pi.mul_apply]; ring)
  have dH1 : ∀ x ∈ I, HasDerivAt H1 (H2 x) x := by
    intro x hx
    have := (dQ1 x hx).sub ((((((hasDerivAt_id' x).sub_const x1).mul
      ((hasDerivAt_id' x).sub_const x2)).add (((hasDerivAt_id' x).sub_const x0).mul
      ((hasDerivAt_id' x).sub_const x2))).add (((hasDerivAt_id' x).sub_const x0).mul
      ((hasDerivAt_id' x).sub_const x1))).const_mul K)
    exact this.congr_deriv (by simp only [hH2]; ring)
  have dH2 : ∀ x ∈ I, HasDerivAt H2 (H3 x) x := by
    intro x hx
    have := (dQ2 x hx).sub ((((((hasDerivAt_id' x).sub_const x0).add
      ((hasDerivAt_id' x).sub_const x1)).add ((hasDerivAt_id' x).sub_const x2)).const_mul
      (2:ℝ)).const_mul K)
    exact this.congr_deriv (by simp only [hH3]; ring)
  set DH : ℕ → ℝ → ℝ := fun m => match m with
    | 0 => H0 | 1 => H1 | 2 => H2 | _ => H3 with hDH
  have hDH' : ∀ m < 3, ∀ x ∈ I, HasDerivAt (DH m) (DH (m + 1) x) x := by
    intro m hm x hx
    interval_cases m
    · exact dH0 x hx
    · exact dH1 x hx
    · exact dH2 x hx
  have hc4 : ({x0, x1, x2, r} : Finset ℝ).card = 3 + 1 := by
    rw [Finset.card_insert_of_notMem (by simp [h01, h02, h0r]),
      Finset.card_insert_of_notMem (by simp [h12, h1r]), Finset.card_pair h2r]
  have hHr : H0 r = 0 := by
    simp only [hH0, hQ0, hroot, hK]
    field_simp
    ring
  obtain ⟨ξ, a'', ha'', b'', hb'', hab1'', hab2'', hξ⟩ := rolle_finset 3 DH I hI hDH'
    {x0, x1, x2, r} hc4
    (by intro a ha; simp only [Finset.mem_insert, Finset.mem_singleton] at ha
        rcases ha with rfl | rfl | rfl | rfl <;> assumption)
    (by intro a ha; simp only [Finset.mem_insert, Finset.mem_singleton] at ha
        rcases ha with rfl | rfl | rfl | rfl
        · simp [DH, hH0]; exact hQx0
        · simp [DH, hH0]; exact hQx1
        · simp [DH, hH0]; exact hQx2
        · exact hHr)
  have hξb : |ξ - r| ≤ Mx := by
    simp only [Finset.mem_insert, Finset.mem_singleton] at ha'' hb''
    exact hbetween ξ a'' b'' (hmem a'' (by tauto)) (hmem b'' (by tauto)) hab1'' hab2''
  refine ⟨c1, c2, η, ζ, ξ, hηb, hζb, hξb, hη, hζ, ?_⟩
  have : H3 ξ = 0 := hξ
  simp only [hH3, hQ3, hK] at this
  linarith

#print axioms iqi_rolle

/-- **The IQI error law.** Near a simple root `r` of a residual with three continuous
derivatives, pure inverse quadratic interpolation iterates that converge to `r` satisfy
`e_(k+1) / (e_k e_(k-1) e_(k-2)) → C = (3 f''(r)² - f'(r) f'''(r)) / (6 f'(r)²)`. -/
theorem iqi_error_ratio_tendsto {f : ℝ → ℝ} {r : ℝ} (hf : ContDiffAt ℝ 3 f r)
    (hroot : f r = 0) (hsimple : deriv f r ≠ 0) (x : ℕ → ℝ)
    (hiqi : ∀ k, x (k + 3) =
      iqi (x k) (x (k + 1)) (x (k + 2)) (f (x k)) (f (x (k + 1))) (f (x (k + 2))))
    (hdistinct : ∀ k, x k ≠ x (k + 1) ∧ x k ≠ x (k + 2) ∧ x (k + 1) ≠ x (k + 2))
    (hne : ∀ k, x k ≠ r) (hlim : Tendsto x atTop (𝓝 r)) :
    Tendsto (fun k => (x (k + 3) - r) / ((x (k + 2) - r) * (x (k + 1) - r) * (x k - r)))
      atTop (𝓝 ((3 * iteratedDeriv 2 f r ^ 2 - deriv f r * iteratedDeriv 3 f r) /
        (6 * deriv f r ^ 2))) := by
  -- Regularity on a ball around the root.
  obtain ⟨u, hu, hfu⟩ := hf.contDiffOn (m := 3) le_rfl (by simp)
  obtain ⟨ε0, hε0, hball⟩ := Metric.mem_nhds_iff.mp hu
  set B := Metric.ball r ε0 with hBdef
  have hBo : IsOpen B := Metric.isOpen_ball
  have hrB : r ∈ B := Metric.mem_ball_self hε0
  have hB : ContDiffOn ℝ 3 f B := hfu.mono hball
  set f1 := deriv f with hf1
  set f2 := deriv f1 with hf2
  set f3 := deriv f2 with hf3
  have hc1 : ContDiffOn ℝ 2 f1 B := hB.deriv_of_isOpen hBo (by norm_num)
  have hc2 : ContDiffOn ℝ 1 f2 B := hc1.deriv_of_isOpen hBo (by norm_num)
  have hc3 : ContDiffOn ℝ 0 f3 B := hc2.deriv_of_isOpen hBo (by norm_num)
  have hd0 : ∀ y ∈ B, HasDerivAt f (f1 y) y := fun y hy =>
    ((hB.differentiableOn (by norm_num) y hy).differentiableAt (hBo.mem_nhds hy)).hasDerivAt
  have hd1 : ∀ y ∈ B, HasDerivAt f1 (f2 y) y := fun y hy =>
    ((hc1.differentiableOn (by norm_num) y hy).differentiableAt (hBo.mem_nhds hy)).hasDerivAt
  have hd2 : ∀ y ∈ B, HasDerivAt f2 (f3 y) y := fun y hy =>
    ((hc2.differentiableOn (by norm_num) y hy).differentiableAt (hBo.mem_nhds hy)).hasDerivAt
  have hct0 : ContinuousAt f r := hB.continuousOn.continuousAt (hBo.mem_nhds hrB)
  have hct1 : ContinuousAt f1 r := hc1.continuousOn.continuousAt (hBo.mem_nhds hrB)
  have hct2 : ContinuousAt f2 r := hc2.continuousOn.continuousAt (hBo.mem_nhds hrB)
  have hct3 : ContinuousAt f3 r := hc3.continuousOn.continuousAt (hBo.mem_nhds hrB)
  -- A smaller interval on which `f'` does not vanish.
  obtain ⟨ε1, hε1, hne1⟩ := Metric.eventually_nhds_iff.mp (hct1.eventually_ne hsimple)
  set ρ := min ε0 ε1 with hρ
  have hρpos : 0 < ρ := lt_min hε0 hε1
  set I := Set.Ioo (r - ρ) (r + ρ) with hIdef
  have hI : I.OrdConnected := Set.ordConnected_Ioo
  have hIB : ∀ y ∈ I, y ∈ B ∧ f1 y ≠ 0 := by
    intro y hy
    have h : dist y r < ρ := by
      rw [Real.dist_eq, abs_sub_lt_iff]; rw [Set.mem_Ioo] at hy; constructor <;> linarith
    exact ⟨lt_of_lt_of_le h (min_le_left _ _), hne1 (lt_of_lt_of_le h (min_le_right _ _))⟩
  have hd0' : ∀ y ∈ I, HasDerivAt f (f1 y) y := fun y hy => hd0 y (hIB y hy).1
  have hd1' : ∀ y ∈ I, HasDerivAt f1 (f2 y) y := fun y hy => hd1 y (hIB y hy).1
  have hd2' : ∀ y ∈ I, HasDerivAt f2 (f3 y) y := fun y hy => hd2 y (hIB y hy).1
  have hrI : r ∈ I := ⟨by linarith, by linarith⟩
  have hinj : ∀ v ∈ I, ∀ w ∈ I, v ≠ w → f v ≠ f w := by
    have key : ∀ v ∈ I, ∀ w ∈ I, v < w → f v ≠ f w := by
      intro v hv w hw hvw heq
      have hsub : Set.Icc v w ⊆ I := hI.out hv hw
      obtain ⟨c, hc, hc0⟩ := exists_hasDerivAt_eq_zero hvw
        (fun y hy => (hd0' y (hsub hy)).continuousAt.continuousWithinAt) heq
        (fun y hy => hd0' y (hsub (Set.Ioo_subset_Icc_self hy)))
      exact (hIB c (hsub (Set.Ioo_subset_Icc_self hc))).2 hc0
    intro v hv w hw hvw
    rcases lt_or_gt_of_ne hvw with h | h
    · exact key v hv w hw h
    · exact fun h' => key w hw v hv h h'.symm
  -- From some index on, three consecutive iterates lie in the interval.
  obtain ⟨K0, hK0⟩ := Filter.eventually_atTop.mp
    (hlim.eventually (Ioo_mem_nhds (by linarith : r - ρ < r) (by linarith : r < r + ρ)))
  set Mk : ℕ → ℝ := fun k => max |x k - r| (max |x (k + 1) - r| |x (k + 2) - r|) with hMk
  have hex : ∀ k, ∃ η ζ ξ : ℝ, |η - r| ≤ Mk k ∧ |ζ - r| ≤ Mk k ∧ |ξ - r| ≤ Mk k ∧
      (K0 ≤ k → ∃ c1 c2 : ℝ,
        c1 * f1 η + c2 * (2 * f η * f1 η) - 1 = 0 ∧
        c1 * f2 ζ + c2 * (2 * (f1 ζ * f1 ζ + f ζ * f2 ζ)) = 0 ∧
        c1 * f3 ξ + c2 * (6 * f1 ξ * f2 ξ + 2 * f ξ * f3 ξ) +
          6 * ((x (k + 3) - r) / ((x (k + 2) - r) * (x (k + 1) - r) * (x k - r))) = 0) := by
    intro k
    by_cases hk : K0 ≤ k
    · obtain ⟨h01, h02, h12⟩ := hdistinct k
      obtain ⟨c1, c2, η, ζ, ξ, hη, hζ, hξ, e1, e2, e3⟩ := iqi_rolle f f1 f2 f3 I hI hd0' hd1'
        hd2' r (x k) (x (k + 1)) (x (k + 2)) hrI (hK0 k hk) (hK0 (k + 1) (by omega))
        (hK0 (k + 2) (by omega)) hroot hinj h01 h02 h12 (hne k) (hne (k + 1)) (hne (k + 2))
      refine ⟨η, ζ, ξ, hη, hζ, hξ, fun _ => ⟨c1, c2, e1, e2, ?_⟩⟩
      rw [hiqi k]; exact e3
    · have h0 : 0 ≤ Mk k := le_trans (abs_nonneg _) (le_max_left _ _)
      refine ⟨r, r, r, ?_, ?_, ?_, fun h => absurd h hk⟩ <;> simpa using h0
  choose η ζ ξ hηb hζb hξb heq using hex
  -- The comparison points converge to the root.
  have hMk0 : Tendsto Mk atTop (𝓝 0) := by
    have ha : Tendsto (fun k => |x k - r|) atTop (𝓝 0) := by
      have := (continuous_abs.tendsto (r - r)).comp (hlim.sub_const r)
      simpa [Function.comp_def] using this
    have h1 := ha.comp (tendsto_add_atTop_nat 1)
    have h2 := ha.comp (tendsto_add_atTop_nat 2)
    have := ha.max (h1.max h2)
    simpa [Function.comp_def] using this
  have hconv : ∀ p : ℕ → ℝ, (∀ k, |p k - r| ≤ Mk k) → Tendsto p atTop (𝓝 r) := by
    intro p hp
    rw [tendsto_iff_dist_tendsto_zero]
    exact squeeze_zero (fun k => dist_nonneg) (fun k => by rw [Real.dist_eq]; exact hp k) hMk0
  have hη := hconv η hηb
  have hζ := hconv ζ hζb
  have hξ := hconv ξ hξb
  have tA := hct1.tendsto.comp hη
  have tB := hct0.tendsto.comp hη
  have tG := hct2.tendsto.comp hζ
  have tP := hct1.tendsto.comp hζ
  have tR := hct0.tendsto.comp hζ
  have tU := hct1.tendsto.comp hξ
  have tV := hct2.tendsto.comp hξ
  have tW := hct0.tendsto.comp hξ
  have tZ := hct3.tendsto.comp hξ
  rw [hroot] at tB tR tW
  -- The determinant of the two linear equations for the coefficients.
  set det : ℕ → ℝ := fun k => f1 (η k) * (2 * (f1 (ζ k) * f1 (ζ k) + f (ζ k) * f2 (ζ k))) -
    2 * f (η k) * f1 (η k) * f2 (ζ k) with hdet
  set num : ℕ → ℝ := fun k => -(2 * (f1 (ζ k) * f1 (ζ k) + f (ζ k) * f2 (ζ k)) * f3 (ξ k) -
    f2 (ζ k) * (6 * f1 (ξ k) * f2 (ξ k) + 2 * f (ξ k) * f3 (ξ k))) with hnum
  have tdet : Tendsto det atTop (𝓝 (f1 r * (2 * (f1 r * f1 r + 0 * f2 r)) -
      2 * 0 * f1 r * f2 r)) :=
    (tA.mul (((tP.mul tP).add (tR.mul tG)).const_mul 2)).sub
      ((((tB.const_mul 2).mul tA)).mul tG)
  have tnum : Tendsto num atTop (𝓝 (-(2 * (f1 r * f1 r + 0 * f2 r) * f3 r -
      f2 r * (6 * f1 r * f2 r + 2 * 0 * f3 r)))) :=
    ((((tP.mul tP).add (tR.mul tG)).const_mul 2).mul tZ |>.sub
      (tG.mul ((((tU.const_mul 6).mul tV)).add ((tW.const_mul 2).mul tZ)))).neg
  have hd1ne : f1 r ≠ 0 := hsimple
  have hdetne : f1 r * (2 * (f1 r * f1 r + 0 * f2 r)) - 2 * 0 * f1 r * f2 r ≠ 0 := by
    have : f1 r * (2 * (f1 r * f1 r + 0 * f2 r)) - 2 * 0 * f1 r * f2 r = 2 * f1 r ^ 3 := by ring
    rw [this]; positivity
  have tF := tnum.div (tdet.const_mul 6) (mul_ne_zero (by norm_num) hdetne)
  have hev : ∀ᶠ k in atTop, num k / (6 * det k) =
      (x (k + 3) - r) / ((x (k + 2) - r) * (x (k + 1) - r) * (x k - r)) := by
    filter_upwards [tdet.eventually (eventually_ne_nhds hdetne), Filter.eventually_ge_atTop K0]
      with k hk hkK
    obtain ⟨c1, c2, e1, e2, e3⟩ := heq k hkK
    set ratio := (x (k + 3) - r) / ((x (k + 2) - r) * (x (k + 1) - r) * (x k - r))
    have hc1 : c1 * det k = 2 * (f1 (ζ k) * f1 (ζ k) + f (ζ k) * f2 (ζ k)) := by
      simp only [hdet]
      linear_combination (2 * (f1 (ζ k) * f1 (ζ k) + f (ζ k) * f2 (ζ k))) * e1 -
        (2 * f (η k) * f1 (η k)) * e2
    have hc2 : c2 * det k = -f2 (ζ k) := by
      simp only [hdet]
      linear_combination f1 (η k) * e2 - f2 (ζ k) * e1
    rw [div_eq_iff (mul_ne_zero (by norm_num) hk)]
    simp only [hnum]
    linear_combination (-(det k)) * e3 +
      f3 (ξ k) * hc1 + (6 * f1 (ξ k) * f2 (ξ k) + 2 * f (ξ k) * f3 (ξ k)) * hc2
  have hlimit := tF.congr' hev
  have e2 : iteratedDeriv 2 f = f2 := by rw [iteratedDeriv_succ, iteratedDeriv_one]
  have e3 : iteratedDeriv 3 f = f3 := by rw [iteratedDeriv_succ, e2]
  rw [e2, e3]
  convert hlimit using 2
  field_simp
  ring

/-- **The order equation.** `p³ = p² + p + 1` has exactly one real root, which lies
between 1.839286 and 1.839287, and its two non-real roots have size below 1. -/
theorem iqi_order_equation_roots :
    (∃! p : ℝ, p ^ 3 = p ^ 2 + p + 1) ∧
    (∀ p : ℝ, p ^ 3 = p ^ 2 + p + 1 → 1839286 / 1000000 < p ∧ p < 1839287 / 1000000) ∧
    (∀ z : ℂ, z ^ 3 = z ^ 2 + z + 1 → z.im ≠ 0 → ‖z‖ < 1) := by
  have hb : ∀ p : ℝ, p ^ 3 = p ^ 2 + p + 1 → 1839286 / 1000000 < p ∧ p < 1839287 / 1000000 := by
    intro p hp
    constructor
    · by_contra h
      rw [not_lt] at h
      nlinarith [mul_nonneg (sub_nonneg.mpr h) (sq_nonneg (p + (1839286 / 1000000 - 1) / 2))]
    · by_contra h
      rw [not_lt] at h
      nlinarith [mul_nonneg (sub_nonneg.mpr h) (sq_nonneg (p + (1839287 / 1000000 - 1) / 2))]
  refine ⟨?_, hb, ?_⟩
  · obtain ⟨p, hp1, hp2⟩ : ∃ p ∈ Set.Icc (1 : ℝ) 2, p ^ 3 - p ^ 2 - p - 1 = 0 := by
      have hc : ContinuousOn (fun p : ℝ => p ^ 3 - p ^ 2 - p - 1) (Set.Icc 1 2) := by fun_prop
      have := intermediate_value_Icc (by norm_num : (1 : ℝ) ≤ 2) hc
      exact this ⟨by norm_num, by norm_num⟩
    refine ⟨p, by linarith, fun q hq => ?_⟩
    have h1 := hb q hq
    have h2 := hb p (by linarith)
    have : (q - p) * (q ^ 2 + q * p + p ^ 2 - q - p - 1) = 0 := by nlinarith
    rcases mul_eq_zero.mp this with h | h
    · linarith
    · nlinarith
  · intro z hz him
    have hre := congrArg Complex.re hz
    have hi := congrArg Complex.im hz
    simp [pow_succ, Complex.mul_re, Complex.mul_im] at hre hi
    set x := z.re
    set y := z.im
    have hy2 : y ^ 2 = 3 * x ^ 2 - 2 * x - 1 := by
      have : y * (3 * x ^ 2 - y ^ 2 - 2 * x - 1) = 0 := by nlinarith
      rcases mul_eq_zero.mp this with h | h
      · exact absurd h him
      · linarith
    have hx : 4 * x ^ 3 - 4 * x ^ 2 + 1 = 0 := by nlinarith
    have hypos : 0 < y ^ 2 := by positivity
    have hxlt : x < 1 := by
      by_contra h
      rw [not_lt] at h
      nlinarith
    have hxgt : -1 / 2 < x := by
      by_contra h
      rw [not_lt] at h
      nlinarith [mul_nonneg (sub_nonneg.mpr h) (sq_nonneg x)]
    have hn : ‖z‖ ^ 2 < 1 := by
      rw [Complex.sq_norm, Complex.normSq_apply]
      nlinarith
    nlinarith [norm_nonneg z]

/-- Kiln: `W₀ = 500`, `δ = 10⁻⁶`, so `W₀ / (2δ) = 250,000,000`, which lies between
`2²⁷` and `2²⁸`: `k = 28`, and the bound is `29 × 30 = 870` evaluations (Brent used 9). -/
example : 2 ^ 27 < 250000000 ∧ 250000000 ≤ 2 ^ 28 ∧ (28 + 1) * (28 + 2) = 870 ∧ 9 ≤ 870 := by
  norm_num

/-- `x⁹` on `[-1, 1.3]`: `W₀ / (2δ) = 1,150,000`, between `2²⁰` and `2²¹`: `k = 21`,
and the bound is `22 × 23 = 506` (Brent used 36, bisection 23). -/
example : 2 ^ 20 < 1150000 ∧ 1150000 ≤ 2 ^ 21 ∧ (21 + 1) * (21 + 2) = 506 ∧ 36 ≤ 506 := by
  norm_num

/-- The proof's tally for `k = 28`: `2(k - i) + 1` fast steps in run `i`, plus `k`
halvings and 2 end evaluations, make `(k + 1)(k + 2) = 870`. -/
example : (∑ i ∈ Finset.range 28, (2 * (28 - i) + 1)) + 28 + 2 = 870 := by
  decide

/-- The same tally for `k = 21` gives 506. -/
example : (∑ i ∈ Finset.range 21, (2 * (21 - i) + 1)) + 21 + 2 = 506 := by
  decide

#print axioms guarded_method_keeps_root_within_square_of_bisection_count
#print axioms iqi_error_ratio_tendsto
#print axioms iqi_order_equation_roots

end BrentSafeguarded
