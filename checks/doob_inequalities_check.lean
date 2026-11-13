-- Doob's inequalities: for a never-negative submartingale, the level times the chance the running peak reaches it is at most the final value averaged over the paths that reached it, which is at most the average final value; the same bound holds for the size of any martingale; and the average squared peak size of a martingale with finite average square is at most four times its average squared final value.
import Mathlib.Probability.Martingale.Basic
import Mathlib.MeasureTheory.Function.LpSeminorm.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Probability.Martingale.OptionalStopping
import Mathlib.MeasureTheory.Function.ConditionalExpectation.Real
import Mathlib.MeasureTheory.Function.ConditionalExpectation.PullOut
import Mathlib.MeasureTheory.Function.L2Space
import Mathlib.MeasureTheory.Function.LpOrder

open MeasureTheory Finset

theorem doob_sup'_range_succ (x : ℕ → ℝ) (n : ℕ) :
    (range (n + 2)).sup' nonempty_range_add_one x =
      max ((range (n + 1)).sup' nonempty_range_add_one x) (x (n + 1)) := by
  apply le_antisymm
  · refine sup'_le _ _ fun k hk => ?_
    rw [mem_range] at hk
    rcases Nat.lt_succ_iff_lt_or_eq.1 hk with h | h
    · exact le_max_of_le_left (le_sup' x (mem_range.2 h))
    · subst h; exact le_max_right _ _
  · refine max_le (sup'_le _ _ fun k hk => le_sup' x ?_) (le_sup' x (mem_range.2 (by omega)))
    rw [mem_range] at hk ⊢; omega

theorem doob_pathwise_aux (x : ℕ → ℝ) (N : ℕ) :
    ((range (N + 1)).sup' nonempty_range_add_one x) ^ 2 ≤
      2 * (range (N + 1)).sup' nonempty_range_add_one x * x N -
        2 * ∑ n ∈ range N, (range (n + 1)).sup' nonempty_range_add_one x * (x (n + 1) - x n) := by
  induction N with
  | zero => simp; nlinarith [sq_nonneg (x 0)]
  | succ N ih =>
    rw [doob_sup'_range_succ, sum_range_succ]
    set b := (range (N + 1)).sup' nonempty_range_add_one x
    rcases le_total b (x (N + 1)) with h | h
    · rw [max_eq_right h]; nlinarith [sq_nonneg (x (N + 1) - b)]
    · rw [max_eq_left h]; nlinarith

theorem doob_pathwise (x : ℕ → ℝ) (N : ℕ) :
    ((range (N + 1)).sup' nonempty_range_add_one x) ^ 2 ≤
      4 * x N ^ 2 -
        4 * ∑ n ∈ range N, (range (n + 1)).sup' nonempty_range_add_one x * (x (n + 1) - x n) := by
  have := doob_pathwise_aux x N
  nlinarith [sq_nonneg ((range (N + 1)).sup' nonempty_range_add_one x - 2 * x N)]

theorem doob_abs_submartingale {Ω : Type*} {m0 : MeasurableSpace Ω}
    (P : Measure Ω) (ℱ : Filtration ℕ m0) (M : ℕ → Ω → ℝ)
    (hmart : Martingale M ℱ P) : Submartingale (fun n ω => |M n ω|) ℱ P := by
  refine ⟨fun n => (hmart.stronglyAdapted n).norm, fun i j hij => ?_, fun n => (hmart.integrable n).abs⟩
  filter_upwards [hmart.condExp_ae_eq hij, abs_condExp_ae_le_condExp_abs (m := ℱ i) (μ := P) (M j)]
    with ω h1 h2
  rw [← h1]
  exact h2

#print axioms doob_sup'_range_succ
#print axioms doob_pathwise_aux
#print axioms doob_pathwise
#print axioms doob_abs_submartingale

/-- Doob's maximal inequality: on a probability space with a filtration, let `X` be a submartingale
(a fair or favourable game) that is never negative. Then for every level `λ > 0` and every number of
rounds `N`, writing `X*_N = max_{0 ≤ n ≤ N} X n` for the running peak,
`λ · P(X*_N ≥ λ) ≤ E[X N ; X*_N ≥ λ] ≤ E[X N]`: the level times the chance of reaching it is at most
the final value averaged over the paths that reached it, which is at most the average final value. -/
theorem doob_maximal_inequality {Ω : Type*} {m0 : MeasurableSpace Ω}
    (P : Measure Ω) [IsProbabilityMeasure P] (ℱ : Filtration ℕ m0) (X : ℕ → Ω → ℝ)
    (hsub : Submartingale X ℱ P) (hnonneg : ∀ n ω, 0 ≤ X n ω) (lam : ℝ) (hlam : 0 < lam)
    (N : ℕ) :
    lam * P.real {ω | lam ≤ (range (N + 1)).sup' nonempty_range_add_one (fun n => X n ω)} ≤
        ∫ ω in {ω | lam ≤ (range (N + 1)).sup' nonempty_range_add_one (fun n => X n ω)},
          X N ω ∂P ∧
      ∫ ω in {ω | lam ≤ (range (N + 1)).sup' nonempty_range_add_one (fun n => X n ω)},
          X N ω ∂P ≤ ∫ ω, X N ω ∂P := by
  have hS : MeasurableSet
      {ω | lam ≤ (range (N + 1)).sup' nonempty_range_add_one (fun n => X n ω)} :=
    measurableSet_le measurable_const (measurable_range_sup'' fun n _ =>
      (hsub.stronglyMeasurable n).measurable.le (ℱ.le n))
  have h := maximal_ineq hsub (fun n ω => hnonneg n ω) (ε := lam.toNNReal) N
  simp only [Real.coe_toNNReal _ hlam.le] at h
  have hI : 0 ≤ ∫ ω in {ω | lam ≤ (range (N + 1)).sup' nonempty_range_add_one (fun n => X n ω)},
      X N ω ∂P := setIntegral_nonneg hS (fun ω _ => hnonneg N ω)
  constructor
  · have h' := ENNReal.toReal_mono ENNReal.ofReal_ne_top h
    rw [ENNReal.toReal_mul, ENNReal.toReal_ofReal hI, ENNReal.coe_toReal,
      Real.coe_toNNReal _ hlam.le] at h'
    exact h'
  · exact setIntegral_le_integral (hsub.integrable N) (ae_of_all _ (hnonneg N))

/-- The maximal inequality for a martingale that can go negative, applied to its size: for every
martingale `M`, every level `λ > 0` and every `N`,
`λ · P(max_{0 ≤ n ≤ N} |M n| ≥ λ) ≤ E[|M N|]`. -/
theorem doob_maximal_inequality_for_size {Ω : Type*} {m0 : MeasurableSpace Ω}
    (P : Measure Ω) [IsProbabilityMeasure P] (ℱ : Filtration ℕ m0) (M : ℕ → Ω → ℝ)
    (hmart : Martingale M ℱ P) (lam : ℝ) (hlam : 0 < lam) (N : ℕ) :
    lam * P.real {ω | lam ≤ (range (N + 1)).sup' nonempty_range_add_one (fun n => |M n ω|)} ≤
      ∫ ω, |M N ω| ∂P := by
  have h := doob_maximal_inequality P ℱ _ (doob_abs_submartingale P ℱ M hmart)
    (fun n ω => abs_nonneg _) lam hlam N
  exact h.1.trans h.2

/-- Doob's L2 inequality: for a martingale `X` whose final value has a finite average square,
the squared peak size `(max_{0 ≤ n ≤ N} |X n|)^2` has a finite average, and that average is at most
four times the average squared final value: `E[(max_{n ≤ N} |X n|)^2] ≤ 4 · E[(X N)^2]`. -/
theorem doob_L2_inequality {Ω : Type*} {m0 : MeasurableSpace Ω}
    (P : Measure Ω) [IsProbabilityMeasure P] (ℱ : Filtration ℕ m0) (X : ℕ → Ω → ℝ)
    (hmart : Martingale X ℱ P) (N : ℕ) (hL2 : MemLp (X N) 2 P) :
    Integrable (fun ω => ((range (N + 1)).sup' nonempty_range_add_one (fun n => |X n ω|)) ^ 2) P ∧
      ∫ ω, ((range (N + 1)).sup' nonempty_range_add_one (fun n => |X n ω|)) ^ 2 ∂P ≤
        4 * ∫ ω, (X N ω) ^ 2 ∂P := by
  set Y : ℕ → Ω → ℝ := fun n ω => |X n ω| with hY
  have hsubY : Submartingale Y ℱ P := doob_abs_submartingale P ℱ X hmart
  set mx : ℕ → Ω → ℝ := fun n ω => (range (n + 1)).sup' nonempty_range_add_one (fun k => |X k ω|)
    with hmx
  have hL2n : ∀ n ≤ N, MemLp (X n) 2 P := fun n hn =>
    (hL2.condExp (m := ℱ n) (by norm_num)).ae_eq (hmart.condExp_ae_eq hn)
  have hY2 : ∀ n ≤ N, MemLp (Y n) 2 P := fun n hn => (hL2n n hn).abs
  have hmeas : ∀ n k, n ≤ k → StronglyMeasurable[ℱ k] (mx n) := fun n k hnk =>
    (@Finset.measurable_range_sup'' ℝ _ Ω (ℱ k) _ _ (fun j ω => |X j ω|) n (fun j hj =>
      (((hmart.stronglyAdapted j).mono (ℱ.mono (by omega))).norm).measurable)).stronglyMeasurable
  have hmeas' : ∀ n, StronglyMeasurable (mx n) := fun n => (hmeas n n le_rfl).mono (ℱ.le n)
  have hmx_nonneg : ∀ n ω, 0 ≤ mx n ω := fun n ω =>
    (abs_nonneg _).trans (le_sup' (fun k => |X k ω|) (mem_range.2 (Nat.succ_pos n)))
  have hbound : ∀ n ω, mx n ω ^ 2 ≤ ∑ k ∈ range (n + 1), X k ω ^ 2 := by
    intro n ω
    obtain ⟨k, hk, hkeq⟩ := exists_mem_eq_sup' nonempty_range_add_one (fun k => |X k ω|)
    simp only [hmx]
    rw [hkeq, sq_abs]
    exact single_le_sum (f := fun k => X k ω ^ 2) (fun i _ => sq_nonneg _) hk
  have hint : ∀ n ≤ N, Integrable (fun ω => mx n ω ^ 2) P := fun n hn =>
    Integrable.mono' (integrable_finsetSum (range (n + 1)) (f := fun k ω => X k ω ^ 2)
        fun k hk => (hL2n k (by rw [mem_range] at hk; omega)).integrable_sq)
      ((hmeas' n).aestronglyMeasurable.pow 2)
      (ae_of_all _ fun ω => by
        rw [Real.norm_eq_abs, abs_of_nonneg (sq_nonneg _)]; exact hbound n ω)
  have hmx2 : ∀ n ≤ N, MemLp (mx n) 2 P := fun n hn =>
    (memLp_two_iff_integrable_sq (hmeas' n).aestronglyMeasurable).2 (hint n hn)
  have hprod : ∀ n < N, Integrable (mx n * Y (n + 1)) P ∧ Integrable (mx n * Y n) P :=
    fun n hn => ⟨(hmx2 n (by omega)).integrable_mul (hY2 (n + 1) (by omega)),
      (hmx2 n (by omega)).integrable_mul (hY2 n (by omega))⟩
  have hkey : ∀ n < N, 0 ≤ ∫ ω, mx n ω * (Y (n + 1) ω - Y n ω) ∂P := by
    intro n hn
    obtain ⟨hi1, hi0⟩ := hprod n hn
    have hce := condExp_mul_of_stronglyMeasurable_left (hmeas n n le_rfl) hi1
      (hsubY.integrable (n + 1))
    have h1 : ∫ ω, mx n ω * Y (n + 1) ω ∂P = ∫ ω, (mx n * P[Y (n + 1) | ℱ n]) ω ∂P := by
      rw [← integral_condExp (ℱ.le n)]; exact integral_congr_ae hce
    have hi2 : Integrable (mx n * P[Y (n + 1) | ℱ n]) P := integrable_condExp.congr hce
    have h2 : ∫ ω, mx n ω * Y n ω ∂P ≤ ∫ ω, (mx n * P[Y (n + 1) | ℱ n]) ω ∂P :=
      integral_mono_ae hi0 hi2 (by
        filter_upwards [hsubY.ae_le_condExp (Nat.le_succ n)] with ω hω
        exact mul_le_mul_of_nonneg_left hω (hmx_nonneg n ω))
    have h3 : (fun ω => mx n ω * (Y (n + 1) ω - Y n ω)) =
        fun ω => mx n ω * Y (n + 1) ω - mx n ω * Y n ω := by ext; ring
    have h4 : ∫ ω, mx n ω * Y (n + 1) ω - mx n ω * Y n ω ∂P =
        ∫ ω, mx n ω * Y (n + 1) ω ∂P - ∫ ω, mx n ω * Y n ω ∂P := integral_sub hi1 hi0
    rw [h3, h4]
    linarith
  have hpw : ∀ ω, mx N ω ^ 2 ≤
      4 * X N ω ^ 2 - 4 * ∑ n ∈ range N, mx n ω * (Y (n + 1) ω - Y n ω) := fun ω => by
    have := doob_pathwise (fun k => |X k ω|) N
    simp only [sq_abs] at this
    exact this
  have hsumint : ∀ n ∈ range N, Integrable (fun ω => mx n ω * (Y (n + 1) ω - Y n ω)) P :=
    fun n hn => by
      obtain ⟨hi1, hi0⟩ := hprod n (mem_range.1 hn)
      refine (hi1.sub hi0).congr (ae_of_all _ fun ω => ?_)
      simp only [Pi.sub_apply, Pi.mul_apply]; ring
  have hR : Integrable (fun ω =>
      4 * X N ω ^ 2 - 4 * ∑ n ∈ range N, mx n ω * (Y (n + 1) ω - Y n ω)) P :=
    (hL2.integrable_sq.const_mul 4).sub ((integrable_finsetSum _ hsumint).const_mul 4)
  refine ⟨hint N le_rfl, ?_⟩
  calc ∫ ω, mx N ω ^ 2 ∂P
      ≤ ∫ ω, (4 * X N ω ^ 2 - 4 * ∑ n ∈ range N, mx n ω * (Y (n + 1) ω - Y n ω)) ∂P :=
        integral_mono (hint N le_rfl) hR hpw
    _ = 4 * ∫ ω, X N ω ^ 2 ∂P -
          4 * ∑ n ∈ range N, ∫ ω, mx n ω * (Y (n + 1) ω - Y n ω) ∂P := by
        rw [integral_sub (hL2.integrable_sq.const_mul 4)
          ((integrable_finsetSum _ hsumint).const_mul 4), integral_const_mul, integral_const_mul,
          integral_finsetSum _ hsumint]
    _ ≤ 4 * ∫ ω, X N ω ^ 2 ∂P := by
        have := sum_nonneg (fun n hn => hkey n (mem_range.1 hn))
        linarith

-- The gambler: start $10, level $31. Doob's bound E[X_N]/λ = 10/31 is just under 1 in 3.
example : (10 : ℚ) / 31 < 1 / 3 ∧ 1 / 4 < (10 : ℚ) / 31 := by norm_num
-- Reaching $31 from $10 takes a gain of $21, so round 21 at the earliest; squared, 21^2 = 441.
example : (10 : ℕ) + 21 = 31 ∧ (21 : ℕ) ^ 2 = 441 := by norm_num
-- Layer-cake for a whole-number peak m: the layers (2k - 1) for k = 1 to m add up to m^2.
example : (∑ k ∈ Icc 1 31, (2 * k - 1) : ℕ) = 31 ^ 2 := by decide
example : ∀ m ≤ 110, (∑ k ∈ Icc 1 m, (2 * k - 1) : ℕ) = m ^ 2 := by decide

#print axioms doob_maximal_inequality
#print axioms doob_maximal_inequality_for_size
#print axioms doob_L2_inequality
