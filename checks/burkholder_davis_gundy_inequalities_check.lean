-- Burkholder-Davis-Gundy: in discrete time, a fair game that starts at 0 and is stopped at any stopping time has an average squared peak between one and four times the average of its clock (its summed squared steps), and for every power p ≥ 2 the closing step of the proof turns its bound into the constant C_p.
import Mathlib.Probability.Martingale.Basic
import Mathlib.Probability.Process.Stopping
import Mathlib.MeasureTheory.Integral.Lebesgue.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Probability.Martingale.OptionalStopping
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Function.ConditionalExpectation.PullOut
import Mathlib.MeasureTheory.Function.L2Space

open MeasureTheory ProbabilityTheory Finset
open scoped ENNReal

/-! Setting. Mathlib has no continuous local martingales and no bracket `⟨M⟩`, so the card's
theorem is stated here in discrete time, where every step is exact. `M n ω` is the fair game after
`n` rounds on path `ω`; `ℱ` is what is known after each round. The game's clock up to round `N` is
the sum of its squared steps, `[M]_N = ∑_{k < N} (M (k+1) - M k)^2` (the card's "sum of the squared
small steps of M"), and its peak is `M*_N = max_{0 ≤ n ≤ N} |M n|`. The card's horizon `T` is any
stopping time: the game read at the earlier of round `n` and `τ` is Mathlib's
`stoppedProcess M τ n`. Averages are Lebesgue integrals in `[0, ∞]`, so they may be infinite,
as on the card. -/

/-- The peak of a game up to round `N`: `M*_N = max_{0 ≤ n ≤ N} |M n|`. -/
noncomputable def peak {Ω : Type*} (M : ℕ → Ω → ℝ) (N : ℕ) (ω : Ω) : ℝ :=
  (range (N + 1)).sup' nonempty_range_add_one (fun n => |M n ω|)

/-- The clock of a game up to round `N`: its summed squared steps `∑_{k < N} (M (k+1) - M k)^2`. -/
noncomputable def clock {Ω : Type*} (M : ℕ → Ω → ℝ) (N : ℕ) (ω : Ω) : ℝ :=
  ∑ k ∈ range N, (M (k + 1) ω - M k ω) ^ 2

/-- The card's upper constant for `p ≥ 2`: `C_p = (p(p-1)/2 · (p/(p-1))^p)^(p/2)`. -/
noncomputable def bdgUpperConstant (p : ℝ) : ℝ :=
  (p * (p - 1) / 2 * (p / (p - 1)) ^ p) ^ (p / 2)

/-! Helper facts used by the proofs below. -/

theorem bdg_peak_zero {Ω : Type*} (M : ℕ → Ω → ℝ) (ω : Ω) : peak M 0 ω = |M 0 ω| := by
  simp [peak]

theorem bdg_le_peak {Ω : Type*} (M : ℕ → Ω → ℝ) {k n : ℕ} (h : k ≤ n) (ω : Ω) :
    |M k ω| ≤ peak M n ω :=
  Finset.le_sup' (fun j => |M j ω|) (by simp; omega)

theorem bdg_peak_nonneg {Ω : Type*} (M : ℕ → Ω → ℝ) (n : ℕ) (ω : Ω) : 0 ≤ peak M n ω :=
  (abs_nonneg _).trans (bdg_le_peak M (Nat.zero_le n) ω)

theorem bdg_peak_succ {Ω : Type*} (M : ℕ → Ω → ℝ) (n : ℕ) (ω : Ω) :
    peak M (n + 1) ω = max (peak M n ω) |M (n + 1) ω| := by
  apply le_antisymm
  · refine Finset.sup'_le _ _ (fun k hk => ?_)
    rw [Finset.mem_range] at hk
    rcases Nat.lt_succ_iff_lt_or_eq.1 hk with h | h
    · exact (bdg_le_peak M (Nat.lt_succ_iff.1 h) ω).trans (le_max_left _ _)
    · subst h; exact le_max_right _ _
  · refine max_le ?_ (bdg_le_peak M le_rfl ω)
    exact Finset.sup'_le _ _ (fun k hk => bdg_le_peak M
      (by rw [Finset.mem_range] at hk; omega) ω)

theorem bdg_pathwise_aux {Ω : Type*} (M : ℕ → Ω → ℝ) (ω : Ω) (n : ℕ) :
    ∑ k ∈ range n, peak M k ω * (|M (k + 1) ω| - |M k ω|) ≤
      peak M n ω * |M n ω| - peak M n ω ^ 2 / 2 := by
  induction n with
  | zero =>
    simp only [range_zero, sum_empty, bdg_peak_zero]
    nlinarith [abs_nonneg (M 0 ω)]
  | succ n ih =>
    rw [sum_range_succ, bdg_peak_succ]
    rcases le_total (peak M n ω) |M (n + 1) ω| with h | h
    · rw [max_eq_right h]
      nlinarith [sq_nonneg (|M (n + 1) ω| - peak M n ω)]
    · rw [max_eq_left h]
      nlinarith

theorem bdg_pathwise {Ω : Type*} (M : ℕ → Ω → ℝ) (ω : Ω) (n : ℕ) :
    peak M n ω ^ 2 ≤ 4 * M n ω ^ 2 -
      4 * ∑ k ∈ range n, peak M k ω * (|M (k + 1) ω| - |M k ω|) := by
  have h := bdg_pathwise_aux M ω n
  have h2 : M n ω ^ 2 = |M n ω| ^ 2 := (sq_abs _).symm
  nlinarith [sq_nonneg (peak M n ω / 2 - |M n ω|)]

theorem bdg_clock_succ {Ω : Type*} (M : ℕ → Ω → ℝ) (n : ℕ) (ω : Ω) :
    clock M (n + 1) ω = clock M n ω + (M (n + 1) ω - M n ω) ^ 2 := by
  simp [clock, sum_range_succ]

theorem bdg_sq_le_clock {Ω : Type*} (M : ℕ → Ω → ℝ) {k N : ℕ} (hk : k < N) (ω : Ω) :
    (M (k + 1) ω - M k ω) ^ 2 ≤ clock M N ω :=
  Finset.single_le_sum (f := fun k => (M (k + 1) ω - M k ω) ^ 2)
    (fun _ _ => sq_nonneg _) (Finset.mem_range.2 hk)

theorem bdg_clock_nonneg {Ω : Type*} (M : ℕ → Ω → ℝ) (N : ℕ) (ω : Ω) : 0 ≤ clock M N ω :=
  Finset.sum_nonneg (fun _ _ => sq_nonneg _)

theorem bdg_peak_stronglyMeasurable {Ω : Type*} {m0 : MeasurableSpace Ω} (ℱ : Filtration ℕ m0)
    (M : ℕ → Ω → ℝ) (hM : StronglyAdapted ℱ M) (n : ℕ) :
    StronglyMeasurable[ℱ n] (peak M n) := by
  induction n with
  | zero =>
    have : peak M 0 = fun ω => |M 0 ω| := funext (bdg_peak_zero M)
    rw [this]
    exact continuous_abs.comp_stronglyMeasurable (hM 0)
  | succ n ih =>
    have : peak M (n + 1) = fun ω => max (peak M n ω) |M (n + 1) ω| := funext (bdg_peak_succ M n)
    rw [this]
    exact continuous_max.comp_stronglyMeasurable
      ((ih.mono (ℱ.mono (Nat.le_succ n))).prodMk
        (continuous_abs.comp_stronglyMeasurable (hM (n + 1))))

theorem bdg_integrable_mul {Ω : Type*} {m0 : MeasurableSpace Ω} {P : Measure Ω}
    {f g : Ω → ℝ} (hf : MemLp f 2 P) (hg : MemLp g 2 P) : Integrable (f * g) P := by
  refine Integrable.mono' (hf.integrable_sq.add hg.integrable_sq)
    (hf.aestronglyMeasurable.mul hg.aestronglyMeasurable) (ae_of_all _ (fun ω => ?_))
  simp only [Pi.mul_apply, Pi.add_apply, Real.norm_eq_abs, abs_mul]
  nlinarith [sq_nonneg (|f ω| - |g ω|), sq_abs (f ω), sq_abs (g ω)]

theorem bdg_memLp_peak {Ω : Type*} {m0 : MeasurableSpace Ω} (P : Measure Ω)
    (ℱ : Filtration ℕ m0) (M : ℕ → Ω → ℝ) (hM : StronglyAdapted ℱ M) (n : ℕ)
    (hL2 : ∀ j ≤ n, MemLp (M j) 2 P) : MemLp (peak M n) 2 P := by
  have hmeas : AEStronglyMeasurable (peak M n) P :=
    ((bdg_peak_stronglyMeasurable ℱ M hM n).mono (ℱ.le n)).aestronglyMeasurable
  rw [memLp_two_iff_integrable_sq hmeas]
  refine Integrable.mono' (integrable_finsetSum (range (n + 1))
    (fun j hj => (hL2 j (by rw [Finset.mem_range] at hj; omega)).integrable_sq))
    (hmeas.pow 2) (ae_of_all _ (fun ω => ?_))
  rw [Real.norm_eq_abs, abs_of_nonneg (sq_nonneg _)]
  obtain ⟨k, hk, hkeq⟩ := Finset.exists_mem_eq_sup' nonempty_range_add_one (fun j => |M j ω|)
  have : peak M n ω = |M k ω| := hkeq
  rw [this, sq_abs]
  exact Finset.single_le_sum (f := fun j => M j ω ^ 2) (fun _ _ => sq_nonneg _) hk

/-- Pulling a known factor out of a martingale step: `E[g M_{k+1}] = E[g M_k]`. -/
theorem bdg_integral_mul_succ {Ω : Type*} {m0 : MeasurableSpace Ω}
    (P : Measure Ω) [IsProbabilityMeasure P] (ℱ : Filtration ℕ m0) (M : ℕ → Ω → ℝ)
    (hM : Martingale M ℱ P) (k : ℕ) (g : Ω → ℝ) (hg : StronglyMeasurable[ℱ k] g)
    (h1 : Integrable (g * M (k + 1)) P) :
    ∫ ω, g ω * M (k + 1) ω ∂P = ∫ ω, g ω * M k ω ∂P := by
  have hce := condExp_mul_of_stronglyMeasurable_left hg h1 (hM.integrable (k + 1))
  have hm := hM.condExp_ae_eq (Nat.le_succ k)
  calc ∫ ω, g ω * M (k + 1) ω ∂P = ∫ ω, (P[g * M (k + 1) | ℱ k]) ω ∂P :=
        (integral_condExp (ℱ.le k)).symm
    _ = ∫ ω, g ω * M k ω ∂P := by
        refine integral_congr_ae (hce.trans ?_)
        filter_upwards [hm] with ω h
        simp [h]

/-- The submartingale version, for a nonnegative known factor: `E[g Y_k] ≤ E[g Y_{k+1}]`. -/
theorem bdg_integral_mul_succ_le {Ω : Type*} {m0 : MeasurableSpace Ω}
    (P : Measure Ω) [IsProbabilityMeasure P] (ℱ : Filtration ℕ m0) (Y : ℕ → Ω → ℝ)
    (hY : Submartingale Y ℱ P) (k : ℕ) (g : Ω → ℝ) (hg : StronglyMeasurable[ℱ k] g)
    (hg0 : ∀ ω, 0 ≤ g ω) (h1 : Integrable (g * Y (k + 1)) P) (h0 : Integrable (g * Y k) P) :
    ∫ ω, g ω * Y k ω ∂P ≤ ∫ ω, g ω * Y (k + 1) ω ∂P := by
  have hce := condExp_mul_of_stronglyMeasurable_left hg h1 (hY.integrable (k + 1))
  have hm := hY.ae_le_condExp (Nat.le_succ k)
  calc ∫ ω, g ω * Y k ω ∂P ≤ ∫ ω, (P[g * Y (k + 1) | ℱ k]) ω ∂P := by
        refine integral_mono_ae h0 integrable_condExp ?_
        filter_upwards [hce, hm] with ω h1 h2
        rw [h1]
        exact mul_le_mul_of_nonneg_left h2 (hg0 ω)
    _ = ∫ ω, g ω * Y (k + 1) ω ∂P := integral_condExp (ℱ.le k)

theorem bdg_integrable_clock {Ω : Type*} {m0 : MeasurableSpace Ω} (P : Measure Ω)
    (M : ℕ → Ω → ℝ) (N : ℕ) (hL2 : ∀ n ≤ N, MemLp (M n) 2 P) :
    Integrable (clock M N) P := by
  have : clock M N = fun ω => ∑ k ∈ range N, (M (k + 1) ω - M k ω) ^ 2 := rfl
  rw [this]
  refine integrable_finsetSum _ (fun k hk => ?_)
  rw [Finset.mem_range] at hk
  exact ((hL2 (k + 1) (by omega)).sub (hL2 k (by omega))).integrable_sq

/-- The clock is the variance, needing square-integrability only up to round `N`. -/
theorem bdg_sq_mean_eq_clock_mean_aux {Ω : Type*} {m0 : MeasurableSpace Ω}
    (P : Measure Ω) [IsProbabilityMeasure P] (ℱ : Filtration ℕ m0) (M : ℕ → Ω → ℝ)
    (hM : Martingale M ℱ P) (h0 : ∀ ω, M 0 ω = 0) (N : ℕ) (hL2 : ∀ n ≤ N, MemLp (M n) 2 P) :
    ∫ ω, (M N ω) ^ 2 ∂P = ∫ ω, clock M N ω ∂P := by
  induction N with
  | zero => simp [clock, h0]
  | succ n ih =>
    have hn := hL2 n (by omega)
    have hn1 := hL2 (n + 1) le_rfl
    have ih' := ih (fun j hj => hL2 j (by omega))
    have horth := bdg_integral_mul_succ P ℱ M hM n (M n) (hM.stronglyMeasurable n)
      (bdg_integrable_mul hn hn1)
    have hint_inc : Integrable (fun ω => (M (n + 1) ω - M n ω) ^ 2) P :=
      (hn1.sub hn).integrable_sq
    simp_rw [bdg_clock_succ]
    rw [integral_add (bdg_integrable_clock P M n (fun j hj => hL2 j (by omega))) hint_inc, ← ih']
    have hexp : ∀ ω, (M (n + 1) ω - M n ω) ^ 2 =
        M (n + 1) ω ^ 2 - 2 * (M n ω * M (n + 1) ω) + M n ω * M n ω := fun ω => by ring
    simp_rw [hexp]
    have i1 : Integrable (fun ω => M (n + 1) ω ^ 2) P := hn1.integrable_sq
    have i2 : Integrable (fun ω => M n ω * M (n + 1) ω) P := bdg_integrable_mul hn hn1
    have i3 : Integrable (fun ω => M n ω * M n ω) P := bdg_integrable_mul hn hn
    have i4 : Integrable (fun ω => M (n + 1) ω ^ 2 - 2 * (M n ω * M (n + 1) ω)) P :=
      i1.sub (i2.const_mul 2)
    rw [integral_add i4 i3, integral_sub i1 (i2.const_mul 2), integral_const_mul, horth]
    have : ∫ ω, M n ω ^ 2 ∂P = ∫ ω, M n ω * M n ω ∂P := by simp_rw [sq]
    rw [this]
    ring

/-- Doob's L² inequality with constant 4, for a martingale square-integrable up to round `N`. -/
theorem bdg_doob_L2 {Ω : Type*} {m0 : MeasurableSpace Ω}
    (P : Measure Ω) [IsProbabilityMeasure P] (ℱ : Filtration ℕ m0) (M : ℕ → Ω → ℝ)
    (hM : Martingale M ℱ P) (N : ℕ) (hL2 : ∀ n ≤ N, MemLp (M n) 2 P) :
    ∫ ω, peak M N ω ^ 2 ∂P ≤ 4 * ∫ ω, M N ω ^ 2 ∂P := by
  have hY : Submartingale (fun n ω => |M n ω|) ℱ P := by
    have := hM.submartingale.sup hM.neg.submartingale
    convert this using 1
    funext n ω
    simp [abs_eq_max_neg]
  have hpk : ∀ k ≤ N, MemLp (peak M k) 2 P := fun k hk =>
    bdg_memLp_peak P ℱ M hM.stronglyAdapted k (fun j hj => hL2 j (by omega))
  have habs : ∀ k ≤ N, MemLp (fun ω => |M k ω|) 2 P := fun k hk => (hL2 k hk).abs
  have hterm : ∀ k ∈ range N, Integrable (fun ω => peak M k ω * |M (k + 1) ω|) P ∧
      Integrable (fun ω => peak M k ω * |M k ω|) P := fun k hk => by
    rw [Finset.mem_range] at hk
    exact ⟨bdg_integrable_mul (hpk k (by omega)) (habs (k + 1) (by omega)),
      bdg_integrable_mul (hpk k (by omega)) (habs k (by omega))⟩
  set S : Ω → ℝ := fun ω => ∑ k ∈ range N, peak M k ω * (|M (k + 1) ω| - |M k ω|) with hS
  have hSint : Integrable S P := by
    refine integrable_finsetSum _ (fun k hk => ?_)
    simp_rw [mul_sub]
    exact (hterm k hk).1.sub (hterm k hk).2
  have hS0 : 0 ≤ ∫ ω, S ω ∂P := by
    rw [hS, integral_finsetSum _ (fun k hk => by
      simp_rw [mul_sub]; exact (hterm k hk).1.sub (hterm k hk).2)]
    refine Finset.sum_nonneg (fun k hk => ?_)
    simp_rw [mul_sub]
    rw [integral_sub (hterm k hk).1 (hterm k hk).2, sub_nonneg]
    exact bdg_integral_mul_succ_le P ℱ _ hY k (peak M k)
      (bdg_peak_stronglyMeasurable ℱ M hM.stronglyAdapted k) (bdg_peak_nonneg M k)
      (hterm k hk).1 (hterm k hk).2
  have hN2 : Integrable (fun ω => M N ω ^ 2) P := (hL2 N le_rfl).integrable_sq
  calc ∫ ω, peak M N ω ^ 2 ∂P ≤ ∫ ω, (4 * M N ω ^ 2 - 4 * S ω) ∂P :=
        integral_mono (hpk N le_rfl).integrable_sq ((hN2.const_mul 4).sub (hSint.const_mul 4))
          (fun ω => bdg_pathwise M ω N)
    _ = 4 * ∫ ω, M N ω ^ 2 ∂P - 4 * ∫ ω, S ω ∂P := by
        rw [integral_sub (hN2.const_mul 4) (hSint.const_mul 4), integral_const_mul,
          integral_const_mul]
    _ ≤ 4 * ∫ ω, M N ω ^ 2 ∂P := by linarith

/-- BDG at p = 2 for any fair game that starts at 0 (no stopping needed). -/
theorem bdg_two_sided_of_martingale {Ω : Type*} {m0 : MeasurableSpace Ω}
    (P : Measure Ω) [IsProbabilityMeasure P] (ℱ : Filtration ℕ m0) (M : ℕ → Ω → ℝ)
    (hM : Martingale M ℱ P) (h0 : ∀ ω, M 0 ω = 0) (N : ℕ) :
    ∫⁻ ω, ENNReal.ofReal (clock M N ω) ∂P ≤ ∫⁻ ω, ENNReal.ofReal (peak M N ω ^ 2) ∂P ∧
      ∫⁻ ω, ENNReal.ofReal (peak M N ω ^ 2) ∂P ≤
        4 * ∫⁻ ω, ENNReal.ofReal (clock M N ω) ∂P := by
  have hmeas : ∀ n, Measurable (M n) := fun n =>
    ((hM.stronglyMeasurable n).mono (ℱ.le n)).measurable
  have hpm : AEStronglyMeasurable (peak M N) P :=
    ((bdg_peak_stronglyMeasurable ℱ M hM.stronglyAdapted N).mono (ℱ.le N)).aestronglyMeasurable
  have hcm : AEStronglyMeasurable (clock M N) P := by
    have : clock M N = fun ω => ∑ k ∈ range N, (M (k + 1) ω - M k ω) ^ 2 := rfl
    rw [this]
    exact (Finset.measurable_sum _ (fun k _ =>
      ((hmeas (k + 1)).sub (hmeas k)).pow_const 2)).aestronglyMeasurable
  constructor
  · by_cases hfin : ∫⁻ ω, ENNReal.ofReal (peak M N ω ^ 2) ∂P = ⊤
    · rw [hfin]; exact le_top
    have hpi : Integrable (fun ω => peak M N ω ^ 2) P :=
      ⟨hpm.pow 2, (hasFiniteIntegral_iff_ofReal (ae_of_all _ (fun ω => sq_nonneg _))).2
        (lt_top_iff_ne_top.2 hfin)⟩
    have hL2 : ∀ n ≤ N, MemLp (M n) 2 P := fun n hn =>
      (memLp_two_iff_integrable_sq (hM.integrable n).1).2
        (hpi.mono' ((hM.integrable n).1.pow 2) (ae_of_all _ (fun ω => by
          rw [Real.norm_eq_abs, abs_of_nonneg (sq_nonneg _), ← sq_abs]
          exact pow_le_pow_left₀ (abs_nonneg _) (bdg_le_peak M hn ω) 2)))
    rw [← ofReal_integral_eq_lintegral_ofReal (bdg_integrable_clock P M N hL2)
        (ae_of_all _ (bdg_clock_nonneg M N)),
      ← ofReal_integral_eq_lintegral_ofReal hpi (ae_of_all _ (fun ω => sq_nonneg _))]
    refine ENNReal.ofReal_le_ofReal ?_
    rw [← bdg_sq_mean_eq_clock_mean_aux P ℱ M hM h0 N hL2]
    refine integral_mono (hL2 N le_rfl).integrable_sq hpi (fun ω => ?_)
    rw [← sq_abs]
    exact pow_le_pow_left₀ (abs_nonneg _) (bdg_le_peak M le_rfl ω) 2
  · by_cases hfin : ∫⁻ ω, ENNReal.ofReal (clock M N ω) ∂P = ⊤
    · rw [hfin, ENNReal.mul_top (by norm_num)]; exact le_top
    have hci : Integrable (clock M N) P :=
      ⟨hcm, (hasFiniteIntegral_iff_ofReal (ae_of_all _ (bdg_clock_nonneg M N))).2
        (lt_top_iff_ne_top.2 hfin)⟩
    have hinc : ∀ k < N, MemLp (M (k + 1) - M k) 2 P := fun k hk =>
      (memLp_two_iff_integrable_sq ((hmeas (k + 1)).sub (hmeas k)).aestronglyMeasurable).2
        (hci.mono' (((hmeas (k + 1)).sub (hmeas k)).pow_const 2).aestronglyMeasurable
          (ae_of_all _ (fun ω => by
            rw [Real.norm_eq_abs, abs_of_nonneg (sq_nonneg _)]
            exact bdg_sq_le_clock M hk ω)))
    have hL2 : ∀ n ≤ N, MemLp (M n) 2 P := by
      intro n
      induction n with
      | zero =>
        intro _
        have : M 0 = 0 := funext h0
        rw [this]
        exact MemLp.zero
      | succ n ih =>
        intro hn
        have := (ih (by omega)).add (hinc n (by omega))
        simpa using this
    have hpi : Integrable (fun ω => peak M N ω ^ 2) P :=
      (bdg_memLp_peak P ℱ M hM.stronglyAdapted N hL2).integrable_sq
    rw [← ofReal_integral_eq_lintegral_ofReal hci (ae_of_all _ (bdg_clock_nonneg M N)),
      ← ofReal_integral_eq_lintegral_ofReal hpi (ae_of_all _ (fun ω => sq_nonneg _))]
    calc ENNReal.ofReal (∫ ω, peak M N ω ^ 2 ∂P)
        ≤ ENNReal.ofReal (4 * ∫ ω, clock M N ω ∂P) := by
          refine ENNReal.ofReal_le_ofReal ?_
          rw [← bdg_sq_mean_eq_clock_mean_aux P ℱ M hM h0 N hL2]
          exact bdg_doob_L2 P ℱ M hM N hL2
      _ = 4 * ENNReal.ofReal (∫ ω, clock M N ω ∂P) := by
          rw [ENNReal.ofReal_mul (by norm_num)]
          norm_num

/-- A stopped fair game is a fair game. -/
theorem bdg_martingale_stoppedProcess {Ω : Type*} {m0 : MeasurableSpace Ω}
    (P : Measure Ω) [IsProbabilityMeasure P] (ℱ : Filtration ℕ m0) (M : ℕ → Ω → ℝ)
    (hM : Martingale M ℱ P) (τ : Ω → WithTop ℕ) (hτ : IsStoppingTime ℱ τ) :
    Martingale (stoppedProcess M τ) ℱ P := by
  refine martingale_iff.2 ⟨?_, hM.submartingale.stoppedProcess hτ⟩
  have h := (hM.neg.submartingale.stoppedProcess hτ).neg
  have : -stoppedProcess (-M) τ = stoppedProcess M τ := by
    funext n ω; simp [stoppedProcess]
  rwa [this] at h

/-- **BDG at p = 2, with lower constant 1 and upper constant 4.** Let `M` be a fair game
(a martingale) that starts at 0, and stop it at any stopping time `τ`. Then for every horizon `N`,
the average clock is at most the average squared peak, and the average squared peak is at most four
times the average clock:
`E[[M^τ]_N] ≤ E[(M^τ*_N)^2] ≤ 4 · E[[M^τ]_N]`. -/
theorem bdg_peak_squared_between_clock_and_four_clock {Ω : Type*} {m0 : MeasurableSpace Ω}
    (P : Measure Ω) [IsProbabilityMeasure P] (ℱ : Filtration ℕ m0) (M : ℕ → Ω → ℝ)
    (hM : Martingale M ℱ P) (h0 : ∀ ω, M 0 ω = 0)
    (τ : Ω → WithTop ℕ) (hτ : IsStoppingTime ℱ τ) (N : ℕ) :
    ∫⁻ ω, ENNReal.ofReal (clock (stoppedProcess M τ) N ω) ∂P ≤
        ∫⁻ ω, ENNReal.ofReal (peak (stoppedProcess M τ) N ω ^ 2) ∂P ∧
      ∫⁻ ω, ENNReal.ofReal (peak (stoppedProcess M τ) N ω ^ 2) ∂P ≤
        4 * ∫⁻ ω, ENNReal.ofReal (clock (stoppedProcess M τ) N ω) ∂P := by
  exact bdg_two_sided_of_martingale P ℱ (stoppedProcess M τ)
    (bdg_martingale_stoppedProcess P ℱ M hM τ hτ)
    (fun ω => by simp [stoppedProcess, h0]) N

/-- **The clock is the variance** (Step 1, fact 1): for a fair game that starts at 0 and whose
values have finite average squares, the average squared value after `N` rounds equals the
average clock: `E[M_N^2] = E[[M]_N]`. -/
theorem martingale_sq_mean_eq_clock_mean {Ω : Type*} {m0 : MeasurableSpace Ω}
    (P : Measure Ω) [IsProbabilityMeasure P] (ℱ : Filtration ℕ m0) (M : ℕ → Ω → ℝ)
    (hM : Martingale M ℱ P) (h0 : ∀ ω, M 0 ω = 0) (hL2 : ∀ n, MemLp (M n) 2 P) (N : ℕ) :
    ∫ ω, (M N ω) ^ 2 ∂P = ∫ ω, clock M N ω ∂P := by
  exact bdg_sq_mean_eq_clock_mean_aux P ℱ M hM h0 N (fun n _ => hL2 n)

/-- **The closing step of the proof for p ≥ 2** (Step 2, "Solve"): write `A` for the peak's
p-th moment and `D` for the clock's (p/2)-th moment. If Ito, Hölder and Doob give
`A ≤ (p/(p-1))^p · p(p-1)/2 · A^(1 - 2/p) · D^(2/p)`, then `A ≤ C_p · D`. -/
theorem bdg_upper_closing_step (p A D : ℝ) (hp : 2 ≤ p) (hA : 0 ≤ A) (hD : 0 ≤ D)
    (h : A ≤ (p / (p - 1)) ^ p * (p * (p - 1) / 2) * A ^ (1 - 2 / p) * D ^ (2 / p)) :
    A ≤ bdgUpperConstant p * D := by
  have hp0 : 0 < p := by linarith
  have hp1 : 0 < p - 1 := by linarith
  have hK0 : 0 ≤ p * (p - 1) / 2 * (p / (p - 1)) ^ p := by positivity
  unfold bdgUpperConstant
  rcases hA.eq_or_lt with h0 | hpos
  · rw [← h0]; exact mul_nonneg (Real.rpow_nonneg hK0 _) hD
  · have hApos : 0 < A ^ (2 / p) := Real.rpow_pos_of_pos hpos _
    have hsplit : A ^ (1 - 2 / p) = A / A ^ (2 / p) := by rw [Real.rpow_sub hpos, Real.rpow_one]
    rw [hsplit] at h
    have h1 : A * A ^ (2 / p) ≤ A * (p * (p - 1) / 2 * (p / (p - 1)) ^ p * D ^ (2 / p)) := by
      calc A * A ^ (2 / p) ≤ (p / (p - 1)) ^ p * (p * (p - 1) / 2) * (A / A ^ (2 / p)) *
            D ^ (2 / p) * A ^ (2 / p) := mul_le_mul_of_nonneg_right h hApos.le
        _ = A * (p * (p - 1) / 2 * (p / (p - 1)) ^ p * D ^ (2 / p)) := by
            field_simp
    have h2 := le_of_mul_le_mul_left h1 hpos
    have h3 := Real.rpow_le_rpow (Real.rpow_nonneg hA _) h2 (by linarith : (0 : ℝ) ≤ p / 2)
    have he : 2 / p * (p / 2) = 1 := by field_simp
    rwa [← Real.rpow_mul hA, Real.mul_rpow hK0 (Real.rpow_nonneg hD _), ← Real.rpow_mul hD, he,
      Real.rpow_one, Real.rpow_one] at h3

/-! The card's exact worked numbers (house example `M_t = (B_t^2 - t)/2` on one year). -/

-- Average clock: ∫_0^1 s ds = 1/2; the upper bound at p = 2 is 4 × 1/2 = 2.
example : (4 : ℚ) * (1 / 2) = 2 := by norm_num
-- Average squared endpoint: E[(Z^2 - 1)^2]/4 = (3 - 2 + 1)/4 = 1/2, equal to the average clock.
example : ((3 : ℚ) - 2 + 1) / 4 = 1 / 2 := by norm_num
-- Average squared clock: 1/4 + 2 × 1/6 = 7/12.
example : (1 : ℚ) / 4 + 2 * (1 / 6) = 7 / 12 := by norm_num
-- Fourth moment of the endpoint: E[(Z^2 - 1)^4]/16 = (105 - 60 + 18 - 4 + 1)/16 = 15/4.
example : ((105 : ℚ) - 4 * 15 + 6 * 3 - 4 * 1 + 1) / 16 = 15 / 4 := by norm_num
-- The constant's inner base: p = 2 gives 4 (so C_2 = 4^1 = 4), p = 3 gives 81/8, p = 4 gives 512/27.
example : (2 : ℚ) * (2 - 1) / 2 * (2 / (2 - 1)) ^ 2 = 4 := by norm_num
example : (3 : ℚ) * (3 - 1) / 2 * (3 / (3 - 1)) ^ 3 = 81 / 8 := by norm_num
example : (4 : ℚ) * (4 - 1) / 2 * (4 / (4 - 1)) ^ 4 = 512 / 27 := by norm_num
-- C_4 = (512/27)^2 = 262144/729, and the p = 4 bound C_4 × 7/12 = 458752/2187.
example : ((512 : ℚ) / 27) ^ 2 = 262144 / 729 ∧ (262144 : ℚ) / 729 * (7 / 12) = 458752 / 2187 := by
  norm_num
-- Doob at p = 4: (4/3)^4 × 15/4 = 320/27.
example : ((4 : ℚ) / 3) ^ 4 * (15 / 4) = 320 / 27 := by norm_num
-- What breaks: a drift 2t keeps the clock but gives E[X_1^2] = 1/2 + 2^2 = 9/2, above the bound 2.
example : (1 : ℚ) / 2 + 2 ^ 2 = 9 / 2 ∧ (2 : ℚ) < 9 / 2 := by norm_num

#print axioms bdg_peak_squared_between_clock_and_four_clock
#print axioms martingale_sq_mean_eq_clock_mean
#print axioms bdg_upper_closing_step
#print axioms bdg_peak_zero
#print axioms bdg_le_peak
#print axioms bdg_peak_nonneg
#print axioms bdg_peak_succ
#print axioms bdg_pathwise_aux
#print axioms bdg_pathwise
#print axioms bdg_clock_succ
#print axioms bdg_sq_le_clock
#print axioms bdg_clock_nonneg
#print axioms bdg_peak_stronglyMeasurable
#print axioms bdg_integrable_mul
#print axioms bdg_memLp_peak
#print axioms bdg_integral_mul_succ
#print axioms bdg_integral_mul_succ_le
#print axioms bdg_integrable_clock
#print axioms bdg_sq_mean_eq_clock_mean_aux
#print axioms bdg_doob_L2
#print axioms bdg_two_sided_of_martingale
#print axioms bdg_martingale_stoppedProcess
