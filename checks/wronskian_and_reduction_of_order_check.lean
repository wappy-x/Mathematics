-- The Wronskian: for two solutions of y'' + p y' + q y = 0 with p and q continuous on an open interval, the Wronskian is never zero or always zero, it is non-zero exactly when the solutions are linearly independent, it obeys Abel's identity, and reduction of order turns one non-vanishing solution into a second.
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.LinearAlgebra.LinearIndependent.Defs
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Analysis.ODE.Gronwall
import Mathlib.LinearAlgebra.LinearIndependent.Lemmas
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.FieldSimp

open Real

/-- Gronwall step: a solution with zero value and zero slope at the left end of [a, b]
is zero at the right end. -/
lemma wr_zero_right (a b : ℝ) (hab : a ≤ b) (p q : ℝ → ℝ)
    (hp : ContinuousOn p (Set.Icc a b)) (hq : ContinuousOn q (Set.Icc a b))
    (z z' : ℝ → ℝ)
    (hz : ∀ t ∈ Set.Icc a b, HasDerivAt z (z' t) t ∧ HasDerivAt z' (-(p t) * z' t - q t * z t) t)
    (h0 : z a = 0) (h0' : z' a = 0) : z b = 0 := by
  obtain ⟨M1, hM1⟩ := isCompact_Icc.exists_bound_of_continuousOn hp
  obtain ⟨M2, hM2⟩ := isCompact_Icc.exists_bound_of_continuousOn hq
  have key := norm_le_gronwallBound_of_norm_deriv_right_le (f := fun t => (z t, z' t))
    (f' := fun t => (z' t, -(p t) * z' t - q t * z t)) (δ := 0) (K := 1 + |M1| + |M2|) (ε := 0)
    (fun t ht => (((hz t ht).1.continuousAt).prodMk
      ((hz t ht).2.continuousAt)).continuousWithinAt)
    (fun t ht => (HasDerivAt.prodMk (hz t (Set.Ico_subset_Icc_self ht)).1
      (hz t (Set.Ico_subset_Icc_self ht)).2).hasDerivWithinAt)
    (by simp [h0, h0'])
    (by
      intro t ht
      have ht' := Set.Ico_subset_Icc_self ht
      have h1 := hM1 t ht'
      have h2 := hM2 t ht'
      rw [Real.norm_eq_abs] at h1 h2
      simp only [Prod.norm_def, Real.norm_eq_abs, add_zero]
      have hm1 : |z t| ≤ max |z t| |z' t| := le_max_left _ _
      have hm2 : |z' t| ≤ max |z t| |z' t| := le_max_right _ _
      have hm0 : 0 ≤ max |z t| |z' t| := le_trans (abs_nonneg _) hm1
      have hM1' : |p t| ≤ |M1| := h1.trans (le_abs_self _)
      have hM2' : |q t| ≤ |M2| := h2.trans (le_abs_self _)
      apply max_le
      · nlinarith [abs_nonneg M1, abs_nonneg M2]
      · have e1 : |-(p t) * z' t - q t * z t| ≤ |p t| * |z' t| + |q t| * |z t| := by
          rw [show -(p t) * z' t - q t * z t = -(p t * z' t + q t * z t) by ring, abs_neg,
            ← abs_mul, ← abs_mul]
          exact abs_add_le _ _
        have e2 : |p t| * |z' t| ≤ |M1| * max |z t| |z' t| :=
          mul_le_mul hM1' hm2 (abs_nonneg _) (abs_nonneg _)
        have e3 : |q t| * |z t| ≤ |M2| * max |z t| |z' t| :=
          mul_le_mul hM2' hm1 (abs_nonneg _) (abs_nonneg _)
        nlinarith)
  have hb := key b ⟨hab, le_rfl⟩
  rw [gronwallBound_ε0_δ0] at hb
  have h := norm_le_zero_iff.mp hb
  exact congrArg Prod.fst h

/-- Mirror image of `wr_zero_right`: zero value and zero slope at the right end of [a, b]
give zero at the left end. -/
lemma wr_zero_left (a b : ℝ) (hab : a ≤ b) (p q : ℝ → ℝ)
    (hp : ContinuousOn p (Set.Icc a b)) (hq : ContinuousOn q (Set.Icc a b))
    (z z' : ℝ → ℝ)
    (hz : ∀ t ∈ Set.Icc a b, HasDerivAt z (z' t) t ∧ HasDerivAt z' (-(p t) * z' t - q t * z t) t)
    (h0 : z b = 0) (h0' : z' b = 0) : z a = 0 := by
  have hmaps : Set.MapsTo (fun s : ℝ => -s) (Set.Icc (-b) (-a)) (Set.Icc a b) := by
    intro s hs
    simp only [Set.mem_Icc] at hs ⊢
    constructor <;> linarith [hs.1, hs.2]
  have := wr_zero_right (-b) (-a) (by linarith) (fun s => -p (-s)) (fun s => q (-s))
    ((hp.comp continuousOn_neg hmaps).neg) (hq.comp continuousOn_neg hmaps)
    (fun s => z (-s)) (fun s => -z' (-s)) ?_ (by simpa using h0) (by simpa using h0')
  · simpa using this
  · intro s hs
    obtain ⟨h1, h2⟩ := hz (-s) (hmaps hs)
    constructor
    · exact (h1.comp s (hasDerivAt_neg s)).congr_deriv (by ring)
    · exact (h2.comp s (hasDerivAt_neg s)).neg.congr_deriv (by ring)

/-- Uniqueness: a solution with zero value and zero slope at one time of I is zero on I. -/
lemma wr_zero_on (I : Set ℝ) (hIc : I.OrdConnected) (p q : ℝ → ℝ)
    (hp : ContinuousOn p I) (hq : ContinuousOn q I) (z z' : ℝ → ℝ)
    (hz : ∀ t ∈ I, HasDerivAt z (z' t) t ∧ HasDerivAt z' (-(p t) * z' t - q t * z t) t)
    (t0 : ℝ) (ht0 : t0 ∈ I) (h0 : z t0 = 0) (h0' : z' t0 = 0) : ∀ t ∈ I, z t = 0 := by
  intro t ht
  rcases le_total t0 t with h | h
  · have hsub : Set.Icc t0 t ⊆ I := hIc.out ht0 ht
    exact wr_zero_right t0 t h p q (hp.mono hsub) (hq.mono hsub) z z'
      (fun s hs => hz s (hsub hs)) h0 h0'
  · have hsub : Set.Icc t t0 ⊆ I := hIc.out ht ht0
    exact wr_zero_left t t0 h p q (hp.mono hsub) (hq.mono hsub) z z'
      (fun s hs => hz s (hsub hs)) h0 h0'

/-- The slope of t ↦ ∫ p from t0 to t is p(t), inside I. -/
lemma wr_integral_hasDerivAt (I : Set ℝ) (hI : IsOpen I) (hIc : I.OrdConnected) (p : ℝ → ℝ)
    (hp : ContinuousOn p I) (t0 t : ℝ) (ht0 : t0 ∈ I) (ht : t ∈ I) :
    HasDerivAt (fun s => ∫ u in t0..s, p u) (p t) t :=
  intervalIntegral.integral_hasDerivAt_right
    ((hp.mono (hIc.uIcc_subset ht0 ht)).intervalIntegrable)
    (hp.stronglyMeasurableAtFilter hI t ht) (hp.continuousAt (hI.mem_nhds ht))


/-- Abel's identity (helper copy, so the first theorem can use it). -/
lemma wr_abel
    (I : Set ℝ) (hI : IsOpen I) (hIc : I.OrdConnected)
    (p q : ℝ → ℝ) (hp : ContinuousOn p I) (_hq : ContinuousOn q I)
    (y1 y1' y2 y2' : ℝ → ℝ)
    (hy1 : ∀ t ∈ I, HasDerivAt y1 (y1' t) t ∧ HasDerivAt y1' (-(p t) * y1' t - q t * y1 t) t)
    (hy2 : ∀ t ∈ I, HasDerivAt y2 (y2' t) t ∧ HasDerivAt y2' (-(p t) * y2' t - q t * y2 t) t)
    (t0 : ℝ) (ht0 : t0 ∈ I) :
    ∀ t ∈ I, y1 t * y2' t - y1' t * y2 t
      = (y1 t0 * y2' t0 - y1' t0 * y2 t0) * exp (-∫ u in t0..t, p u) := by
  intro t ht
  have hderiv : ∀ s ∈ I, HasDerivAt
      (fun s => (y1 s * y2' s - y1' s * y2 s) * exp (∫ u in t0..s, p u)) 0 s := by
    intro s hs
    obtain ⟨a1, b1⟩ := hy1 s hs
    obtain ⟨a2, b2⟩ := hy2 s hs
    have hint := wr_integral_hasDerivAt I hI hIc p hp t0 s ht0 hs
    have := ((a1.mul b2).sub (b1.mul a2)).mul hint.exp
    convert this using 1
    simp only [Pi.mul_apply, Pi.sub_apply]
    ring
  have hconst := hI.is_const_of_deriv_eq_zero hIc.isPreconnected
    (fun s hs => (hderiv s hs).differentiableAt.differentiableWithinAt)
    (fun s hs => (hderiv s hs).deriv) ht ht0
  simp only [intervalIntegral.integral_same, exp_zero, mul_one] at hconst
  rw [← hconst, mul_assoc, ← exp_add]
  simp

/-- Two solutions y1, y2 of one linear equation y'' + p(t) y' + q(t) y = 0 in standard form,
with p and q continuous on an open interval I, have a Wronskian W = y1·y2' − y1'·y2 that is
either zero at every time in I or zero at no time in I; and at any time t0 in I it is non-zero
exactly when the two solutions are genuinely different (linearly independent as functions on I).
Here y1' and y2' are the slopes of y1 and y2, and each solution's slope has slope
−p·(its slope) − q·(its value). -/
theorem wronskian_ne_zero_iff_linearIndependent
    (I : Set ℝ) (hI : IsOpen I) (hIc : I.OrdConnected)
    (p q : ℝ → ℝ) (hp : ContinuousOn p I) (hq : ContinuousOn q I)
    (y1 y1' y2 y2' : ℝ → ℝ)
    (hy1 : ∀ t ∈ I, HasDerivAt y1 (y1' t) t ∧ HasDerivAt y1' (-(p t) * y1' t - q t * y1 t) t)
    (hy2 : ∀ t ∈ I, HasDerivAt y2 (y2' t) t ∧ HasDerivAt y2' (-(p t) * y2' t - q t * y2 t) t)
    (t0 : ℝ) (ht0 : t0 ∈ I) :
    ((∀ t ∈ I, y1 t * y2' t - y1' t * y2 t = 0) ∨ (∀ t ∈ I, y1 t * y2' t - y1' t * y2 t ≠ 0)) ∧
    (y1 t0 * y2' t0 - y1' t0 * y2 t0 ≠ 0 ↔ LinearIndependent ℝ ![I.restrict y1, I.restrict y2]) := by
  have habel := wr_abel I hI hIc p q hp hq y1 y1' y2 y2' hy1 hy2 t0 ht0
  refine ⟨?_, ?_⟩
  · by_cases h : y1 t0 * y2' t0 - y1' t0 * y2 t0 = 0
    · left
      intro t ht
      rw [habel t ht, h, zero_mul]
    · right
      intro t ht
      rw [habel t ht]
      exact mul_ne_zero h (exp_ne_zero _)
  · rw [LinearIndependent.pair_iff]
    constructor
    · intro hW a b hab
      have hpt : ∀ s ∈ I, a * y1 s + b * y2 s = 0 := by
        intro s hs
        have := congrFun hab ⟨s, hs⟩
        simp at this
        exact this
      have hd : HasDerivAt (fun s => a * y1 s + b * y2 s) (a * y1' t0 + b * y2' t0) t0 :=
        ((hy1 t0 ht0).1.const_mul a).add ((hy2 t0 ht0).1.const_mul b)
      have hev : (fun s => a * y1 s + b * y2 s) =ᶠ[nhds t0] fun _ => (0:ℝ) := by
        filter_upwards [hI.mem_nhds ht0] with s hs using hpt s hs
      have hd0 : HasDerivAt (fun s => a * y1 s + b * y2 s) 0 t0 :=
        (hasDerivAt_const t0 (0:ℝ)).congr_of_eventuallyEq hev
      have e2 : a * y1' t0 + b * y2' t0 = 0 := hd.unique hd0
      have e1 := hpt t0 ht0
      have ha : a * (y1 t0 * y2' t0 - y1' t0 * y2 t0) = 0 := by
        linear_combination y2' t0 * e1 - y2 t0 * e2
      have hb : b * (y1 t0 * y2' t0 - y1' t0 * y2 t0) = 0 := by
        linear_combination y1 t0 * e2 - y1' t0 * e1
      exact ⟨(mul_eq_zero.mp ha).resolve_right hW, (mul_eq_zero.mp hb).resolve_right hW⟩
    · intro hind
      intro hW
      obtain ⟨a, b, hab, e1, e2⟩ : ∃ a b : ℝ, ¬ (a = 0 ∧ b = 0) ∧
          a * y1 t0 + b * y2 t0 = 0 ∧ a * y1' t0 + b * y2' t0 = 0 := by
        by_cases c1 : y1 t0 = 0
        · by_cases c2 : y1' t0 = 0
          · exact ⟨1, 0, by simp, by simp [c1], by simp [c2]⟩
          · exact ⟨y2' t0, -y1' t0, by simp [c2], by linear_combination hW, by ring⟩
        · exact ⟨y2 t0, -y1 t0, by simp [c1], by ring, by linear_combination -hW⟩
      apply hab
      apply hind a b
      funext ⟨s, hs⟩
      simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul, Pi.zero_apply]
      refine wr_zero_on I hIc p q hp hq (fun s => a * y1 s + b * y2 s)
        (fun s => a * y1' s + b * y2' s) ?_ t0 ht0 e1 e2 s hs
      intro s hs
      obtain ⟨a1, b1⟩ := hy1 s hs
      obtain ⟨a2, b2⟩ := hy2 s hs
      refine ⟨(a1.const_mul a).add (a2.const_mul b), ?_⟩
      have := (b1.const_mul a).add (b2.const_mul b)
      convert this using 1
      ring

/-- Abel's identity: for two solutions of y'' + p(t) y' + q(t) y = 0 with p and q continuous on
an open interval I, the Wronskian at any time t in I is its value at the anchor time t0 times
e to the minus the integral of p from t0 to t. -/
theorem abel_identity
    (I : Set ℝ) (hI : IsOpen I) (hIc : I.OrdConnected)
    (p q : ℝ → ℝ) (hp : ContinuousOn p I) (hq : ContinuousOn q I)
    (y1 y1' y2 y2' : ℝ → ℝ)
    (hy1 : ∀ t ∈ I, HasDerivAt y1 (y1' t) t ∧ HasDerivAt y1' (-(p t) * y1' t - q t * y1 t) t)
    (hy2 : ∀ t ∈ I, HasDerivAt y2 (y2' t) t ∧ HasDerivAt y2' (-(p t) * y2' t - q t * y2 t) t)
    (t0 : ℝ) (ht0 : t0 ∈ I) :
    ∀ t ∈ I, y1 t * y2' t - y1' t * y2 t
      = (y1 t0 * y2' t0 - y1' t0 * y2 t0) * exp (-∫ u in t0..t, p u) := by
  exact wr_abel I hI hIc p q hp hq y1 y1' y2 y2' hy1 hy2 t0 ht0

/-- Reduction of order: if y1 solves y'' + p(t) y' + q(t) y = 0 on an open interval I where p and
q are continuous, and y1 is never zero on I, then any v whose slope is v' = e^(−∫ p) / y1^2
gives a second solution y2 = v·y1, whose Wronskian with y1 is e^(−∫ p), never zero. -/
theorem reduction_of_order
    (I : Set ℝ) (hI : IsOpen I) (hIc : I.OrdConnected)
    (p q : ℝ → ℝ) (hp : ContinuousOn p I) (hq : ContinuousOn q I)
    (y1 y1' : ℝ → ℝ)
    (hy1 : ∀ t ∈ I, HasDerivAt y1 (y1' t) t ∧ HasDerivAt y1' (-(p t) * y1' t - q t * y1 t) t)
    (hy1ne : ∀ t ∈ I, y1 t ≠ 0)
    (t0 : ℝ) (ht0 : t0 ∈ I) (v : ℝ → ℝ)
    (hv : ∀ t ∈ I, HasDerivAt v (exp (-∫ u in t0..t, p u) / y1 t ^ 2) t) :
    let y2 : ℝ → ℝ := fun t => v t * y1 t
    let y2' : ℝ → ℝ := fun t => exp (-∫ u in t0..t, p u) / y1 t ^ 2 * y1 t + v t * y1' t
    (∀ t ∈ I, HasDerivAt y2 (y2' t) t ∧ HasDerivAt y2' (-(p t) * y2' t - q t * y2 t) t) ∧
    (∀ t ∈ I, y1 t * y2' t - y1' t * y2 t = exp (-∫ u in t0..t, p u)) := by
  intro y2 y2'
  have hE : ∀ t ∈ I, HasDerivAt (fun s => exp (-∫ u in t0..s, p u))
      (exp (-∫ u in t0..t, p u) * -(p t)) t :=
    fun t ht => (wr_integral_hasDerivAt I hI hIc p hp t0 t ht0 ht).neg.exp
  refine ⟨fun t ht => ⟨?_, ?_⟩, fun t ht => ?_⟩
  · exact (hv t ht).mul (hy1 t ht).1
  · obtain ⟨a1, b1⟩ := hy1 t ht
    have hne := hy1ne t ht
    have h := (((hE t ht).div (a1.pow 2) (pow_ne_zero 2 hne)).mul a1).add ((hv t ht).mul b1)
    convert h using 1
    simp only [y2, y2', Pi.div_apply, Pi.pow_apply, Nat.cast_ofNat]
    norm_num
    field_simp
    ring
  · simp only [y2, y2']
    have := hy1ne t ht
    field_simp
    ring

-- The spring y'' − 2y' + y = 0: trying e^(rt) gives r^2 − 2r + 1 = (r − 1)^2, a double root at 1.
example (r : ℤ) : r ^ 2 - 2 * r + 1 = (r - 1) ^ 2 := by ring
-- Direct check that t e^t solves it: (2 + t) − 2(1 + t) + t = 0.
example (t : ℝ) : (2 + t) - 2 * (1 + t) + t = 0 := by ring
-- The Wronskian of e^t and t e^t, from their slopes: e^t (1 + t)e^t − e^t · t e^t = e^(2t).
example (t : ℝ) : exp t * ((1 + t) * exp t) - exp t * (t * exp t) = exp (2 * t) := by
  rw [two_mul, Real.exp_add]; ring
-- Reduction of order: v' = e^(2t) / (e^t)^2 = 1.
example (t : ℝ) : exp (2 * t) / exp t ^ 2 = 1 := by
  rw [two_mul, Real.exp_add, sq, div_self (mul_ne_zero (exp_ne_zero t) (exp_ne_zero t))]
-- e^t and 2e^t: the same arrow twice, Wronskian zero.
example (t : ℝ) : exp t * (2 * exp t) - exp t * (2 * exp t) = 0 := by ring
-- Fit 2 cm at −1 cm/s: c1 = 2 and c1 + c2 = −1 give c1 = 2, c2 = −3.
example : (2 : ℤ) = 2 ∧ (2 : ℤ) + (-3) = -1 := by norm_num
-- Back to the rest position: 2 − 3t = 0 at t = 2/3 s.
example : (2 : ℚ) - 3 * (2 / 3) = 0 := by norm_num
-- t^2 and t|t| at t = 1 and t = −1: the system a t^2 + b t|t| = 0 has determinant −2.
example : (1 : ℤ) ^ 2 * ((-1) * |(-1 : ℤ)|) - (1 * |(1 : ℤ)|) * (-1) ^ 2 = -2 := by norm_num

#print axioms wr_zero_right
#print axioms wr_zero_left
#print axioms wr_zero_on
#print axioms wr_integral_hasDerivAt
#print axioms wr_abel
#print axioms wronskian_ne_zero_iff_linearIndependent
#print axioms abel_identity
#print axioms reduction_of_order
