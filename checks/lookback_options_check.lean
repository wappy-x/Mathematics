-- Lookback options: a floating-strike lookback call never pays a negative amount, it is worth the prepaid share minus today's value of the expected lowest price (that expectation being the layer-cake integral of the chance the low stays above each level), it pays at least the vanilla call struck at the recorded minimum, and daily watching pays no more than continuous watching.
import Mathlib.MeasureTheory.Integral.Layercake
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Order.CompleteLattice.Basic
import Mathlib.Tactic.NormNum

open MeasureTheory

/-- The lowest price over the contract's life `[0, T]` along one price path `f`, with the
minimum `m` already recorded before today carried over. -/
noncomputable def lifeLow (f : ℝ → ℝ) (m T : ℝ) : ℝ :=
  min m (⨅ t : Set.Icc (0 : ℝ) T, f t)

/-- On a closed interval where `f` is continuous, the infimum of `f` sits at or below each value. -/
theorem lookback_iInf_le_of_mem (f : ℝ → ℝ) (T : ℝ) (hf : ContinuousOn f (Set.Icc 0 T))
    (t : ℝ) (ht : t ∈ Set.Icc (0 : ℝ) T) :
    (⨅ s : Set.Icc (0 : ℝ) T, f s) ≤ f t := by
  have hb : BddBelow (Set.range fun s : Set.Icc (0 : ℝ) T => f s) := by
    rw [← Set.image_eq_range]
    exact isCompact_Icc.bddBelow_image hf
  exact ciInf_le hb ⟨t, ht⟩

/-- For a continuous path on `[0, T]` with `T > 0`, the infimum over the interval equals the
infimum over the rational times in it. -/
theorem lookback_iInf_eq_rat (g : ℝ → ℝ) (T : ℝ) (hT : 0 < T) (hg : ContinuousOn g (Set.Icc 0 T)) :
    (⨅ t : Set.Icc (0 : ℝ) T, g t) = ⨅ q : {q : ℚ // (q : ℝ) ∈ Set.Icc (0 : ℝ) T}, g q := by
  have hb : BddBelow (Set.range fun s : Set.Icc (0 : ℝ) T => g s) := by
    rw [← Set.image_eq_range]
    exact isCompact_Icc.bddBelow_image hg
  have bddQ : BddBelow (Set.range fun q : {q : ℚ // (q : ℝ) ∈ Set.Icc (0 : ℝ) T} => g q) := by
    obtain ⟨b, hb'⟩ := hb
    refine ⟨b, ?_⟩
    rintro _ ⟨q, rfl⟩
    exact hb' ⟨⟨q, q.2⟩, rfl⟩
  have : Nonempty {q : ℚ // (q : ℝ) ∈ Set.Icc (0 : ℝ) T} :=
    ⟨⟨0, by simp only [Rat.cast_zero, Set.mem_Icc, le_refl, true_and]; exact hT.le⟩⟩
  have : Nonempty (Set.Icc (0 : ℝ) T) := ⟨⟨0, le_refl _, hT.le⟩⟩
  apply le_antisymm
  · exact le_ciInf fun q => ciInf_le hb ⟨q, q.2⟩
  · refine le_ciInf fun t => ?_
    refine le_of_forall_pos_lt_add fun ε hε => ?_
    obtain ⟨δ, hδ, hball⟩ := Metric.continuousWithinAt_iff.mp (hg t t.2) ε hε
    have ht0 : (0 : ℝ) ≤ t := t.2.1
    have htT : (t : ℝ) ≤ T := t.2.2
    obtain ⟨q, hq1, hq2⟩ := exists_rat_btwn
      (show max 0 ((t : ℝ) - δ) < min T ((t : ℝ) + δ) from
        max_lt (lt_min hT (by linarith)) (lt_min (by linarith) (by linarith)))
    have hm1 := le_max_left (0 : ℝ) ((t : ℝ) - δ)
    have hm2 := le_max_right (0 : ℝ) ((t : ℝ) - δ)
    have hn1 := min_le_left T ((t : ℝ) + δ)
    have hn2 := min_le_right T ((t : ℝ) + δ)
    have hqI : (q : ℝ) ∈ Set.Icc (0 : ℝ) T := ⟨by linarith, by linarith⟩
    have hd : dist (q : ℝ) t < δ := by
      rw [Real.dist_eq, abs_lt]; constructor <;> linarith
    have h := hball hqI hd
    rw [Real.dist_eq, abs_lt] at h
    calc (⨅ q : {q : ℚ // (q : ℝ) ∈ Set.Icc (0 : ℝ) T}, g q) ≤ g q := ciInf_le bddQ ⟨q, hqI⟩
      _ < g t + ε := by linarith [h.2]

#print axioms lookback_iInf_le_of_mem
#print axioms lookback_iInf_eq_rat

/-- The card's main claim (Steps 0 and 2). The floating-strike lookback call pays the final price
minus the lowest price, and that payment is never negative. So, with the price paths continuous
(continuous watching) and positive, the recorded minimum `m` carried over, and the pretend-world
average of the final price equal to `S₀ e^{(r-q)T}` (constant bank rate `r` and dividend yield `q`),
its price `e^{-rT} E[S_T - m_T]` is the prepaid share `S₀ e^{-qT}` minus `e^{-rT}` times the
expected lowest price, and that expected lowest price is the sum over levels `h` from 0 up to `m`
of the chance that the low stays above `h` (the layer-cake rule). -/
theorem floating_lookback_call_eq_prepaid_share_sub_discounted_expected_low
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (S : ℝ → Ω → ℝ) (S₀ m r q T : ℝ)
    (hT : 0 < T) (hm : 0 < m) (hmS : m ≤ S₀)
    (h_today : ∀ ω, S 0 ω = S₀)
    (h_pos : ∀ t ω, 0 < S t ω)
    (h_cont : ∀ ω, ContinuousOn (fun t => S t ω) (Set.Icc 0 T))
    (h_meas : ∀ t, Measurable (S t))
    (h_int : Integrable (S T) P)
    (h_mean : ∫ ω, S T ω ∂P = S₀ * Real.exp ((r - q) * T)) :
    (∀ ω, 0 ≤ S T ω - lifeLow (fun t => S t ω) m T) ∧
    Real.exp (-r * T) * ∫ ω, (S T ω - lifeLow (fun t => S t ω) m T) ∂P =
      S₀ * Real.exp (-q * T) -
        Real.exp (-r * T) * ∫ h in (0 : ℝ)..m, P.real {ω | h < lifeLow (fun t => S t ω) m T} := by
  constructor
  · intro ω
    have h1 := lookback_iInf_le_of_mem (fun t => S t ω) T (h_cont ω) T ⟨hT.le, le_refl T⟩
    have h2 := min_le_right m (⨅ t : Set.Icc (0 : ℝ) T, S t ω)
    simp only [lifeLow]
    linarith
  · set L : Ω → ℝ := fun ω => lifeLow (fun t => S t ω) m T with hLdef
    have : Nonempty (Set.Icc (0 : ℝ) T) := ⟨⟨0, le_refl _, hT.le⟩⟩
    have hL_nn : ∀ ω, 0 ≤ L ω := fun ω =>
      le_min hm.le (le_ciInf fun t => (h_pos _ _).le)
    have hL_le : ∀ ω, L ω ≤ m := fun ω => min_le_left _ _
    have hinf_meas : Measurable fun ω => ⨅ t : Set.Icc (0 : ℝ) T, S t ω := by
      have : (fun ω => ⨅ t : Set.Icc (0 : ℝ) T, S t ω) =
          fun ω => ⨅ q : {q : ℚ // (q : ℝ) ∈ Set.Icc (0 : ℝ) T}, S q ω :=
        funext fun ω => lookback_iInf_eq_rat (fun t => S t ω) T hT (h_cont ω)
      rw [this]
      exact Measurable.iInf fun q => h_meas _
    have hL_meas : Measurable L := measurable_const.min hinf_meas
    have hL_int : Integrable L P := by
      refine Integrable.of_bound hL_meas.aestronglyMeasurable m (ae_of_all _ fun ω => ?_)
      rw [Real.norm_eq_abs, abs_of_nonneg (hL_nn ω)]
      exact hL_le ω
    have hsub : ∫ ω, (S T ω - lifeLow (fun t => S t ω) m T) ∂P = ∫ ω, S T ω ∂P - ∫ ω, L ω ∂P :=
      integral_sub h_int hL_int
    have hcake : ∫ ω, L ω ∂P = ∫ h in (0 : ℝ)..m, P.real {ω | h < L ω} := by
      rw [hL_int.integral_eq_integral_meas_lt (ae_of_all _ hL_nn),
        intervalIntegral.integral_of_le hm.le]
      apply setIntegral_eq_of_subset_of_ae_sdiff_eq_zero nullMeasurableSet_Ioi Set.Ioc_subset_Ioi_self
      refine ae_of_all _ fun x hx => ?_
      have hxm : m < x := by
        simp only [Set.mem_sdiff, Set.mem_Ioi, Set.mem_Ioc, not_and, not_le] at hx
        exact hx.2 hx.1
      have hempty : {a | x < L a} = ∅ := by
        ext a
        simp only [Set.mem_ofPred_eq, Set.mem_empty_iff_false, iff_false, not_lt]
        linarith [hL_le a]
      rw [hempty, measureReal_empty]
    rw [hsub, hcake, h_mean, mul_sub, ← mul_assoc, mul_comm (Real.exp (-r * T)) S₀, mul_assoc,
      ← Real.exp_add]
    congr 3
    ring

/-- Step 4: on every path the lookback call pays at least the vanilla call struck at the minimum
recorded so far, because the life's low can only be at or below that minimum. -/
theorem lookback_call_pays_at_least_vanilla
    (f : ℝ → ℝ) (m T : ℝ) (hT : 0 ≤ T) (hf : ContinuousOn f (Set.Icc 0 T)) :
    max (f T - m) 0 ≤ f T - lifeLow f m T := by
  have h1 := lookback_iInf_le_of_mem f T hf T ⟨hT, le_refl T⟩
  have h2 := min_le_right m (⨅ t : Set.Icc (0 : ℝ) T, f t)
  have h3 := min_le_left m (⨅ t : Set.Icc (0 : ℝ) T, f t)
  simp only [lifeLow]
  exact max_le (by linarith) (by linarith)

/-- Step 5: a contract that reads the price only at finitely many times (say one close a day)
records a low no lower than the true continuous low, so on every path it pays no more than the
continuously watched lookback call. -/
theorem daily_lookback_pays_at_most_continuous
    (f : ℝ → ℝ) (m T : ℝ) (hf : ContinuousOn f (Set.Icc 0 T))
    (D : Finset ℝ) (hD : D.Nonempty) (hDT : ∀ t ∈ D, t ∈ Set.Icc 0 T) :
    f T - min m (D.inf' hD f) ≤ f T - lifeLow f m T := by
  obtain ⟨t, ht, heq⟩ := D.exists_mem_eq_inf' hD f
  have h1 := lookback_iInf_le_of_mem f T hf t (hDT t ht)
  have h2 : lifeLow f m T ≤ min m (D.inf' hD f) := by
    rw [heq]
    exact min_le_min_left m h1
  linarith

-- The card's illustrative year: Acme's month-end prices, months 0 to 12.
-- The lowest price so far, month by month, is the card's second line.
example :
    (List.range 13).map
        (fun i => ([100, 96, 91, 88, 93, 97, 94, 99, 104, 101, 107, 110, 108].take (i + 1)).foldl
          min (100 : ℤ)) =
      [100, 96, 91, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88] := by decide
-- The floating lookback call pays $108 - $88 = $20.
example : (108 : ℤ) - [100, 96, 91, 88, 93, 97, 94, 99, 104, 101, 107, 110, 108].foldl min 100 = 20 := by
  decide
-- The vanilla call struck at $100 pays $8.
example : max ((108 : ℤ) - 100) 0 = 8 := by decide
-- The fixed-strike lookback call, strike $100, pays the high $110 minus $100 = $10.
example :
    max ([100, 96, 91, 88, 93, 97, 94, 99, 104, 101, 107, 110, 108].foldl max (100 : ℤ) - 100) 0 = 10 := by
  decide
-- Fixed-strike call payoff splits into the floating put's payoff plus S_T - K on this path.
example : (110 : ℤ) - 100 = (110 - 108) + (108 - 100) := by decide

#print axioms floating_lookback_call_eq_prepaid_share_sub_discounted_expected_low
#print axioms lookback_call_pays_at_least_vanilla
#print axioms daily_lookback_pays_at_most_continuous
