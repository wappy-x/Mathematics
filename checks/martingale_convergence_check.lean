-- Martingale convergence: a fair or unfavourable game whose average size stays below a fixed ceiling K settles, with probability 1, to a finite limit whose average size is at most K, and the upcrossing inequality and the urn's fairness behind it hold.
import Mathlib.Probability.Martingale.Convergence
import Mathlib.Probability.Martingale.Upcrossing
import Mathlib.Algebra.Order.Group.PosPart
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp

open MeasureTheory Filter Topology

/-- A hitting time before `N` depends only on the path at times strictly before `N`. -/
theorem hittingBtwn_congr_of_lt_aux {Ω : Type*} {f g : ℕ → Ω → ℝ} {s : Set ℝ} {i N : ℕ} {ω : Ω}
    (h : ∀ j < N, f j ω = g j ω) :
    hittingBtwn f s i N ω = hittingBtwn g s i N ω := by
  have key : ∀ k, hittingBtwn f s i N ω < k ↔ hittingBtwn g s i N ω < k := by
    intro k
    by_cases hk : k ≤ N
    · rw [hittingBtwn_lt_iff k hk, hittingBtwn_lt_iff k hk]
      constructor <;> rintro ⟨j, hj, hjs⟩ <;> refine ⟨j, hj, ?_⟩
      · rwa [← h j (lt_of_lt_of_le hj.2 hk)]
      · rwa [h j (lt_of_lt_of_le hj.2 hk)]
    · push Not at hk
      exact ⟨fun _ => lt_of_le_of_lt (hittingBtwn_le ω) hk,
        fun _ => lt_of_le_of_lt (hittingBtwn_le ω) hk⟩
  apply le_antisymm
  · exact Nat.lt_succ_iff.1 ((key _).2 (Nat.lt_succ_self _))
  · exact Nat.lt_succ_iff.1 ((key _).1 (Nat.lt_succ_self _))

/-- The crossing times before `N` depend only on the path at times strictly before `N`. -/
theorem crossing_congr_of_lt_aux {Ω : Type*} {f g : ℕ → Ω → ℝ} {a b : ℝ} {N : ℕ} {ω : Ω}
    (h : ∀ j < N, f j ω = g j ω) (k : ℕ) :
    upperCrossingTime a b f N k ω = upperCrossingTime a b g N k ω ∧
      lowerCrossingTime a b f N k ω = lowerCrossingTime a b g N k ω := by
  induction k with
  | zero =>
    refine ⟨rfl, ?_⟩
    simp only [lowerCrossingTime_zero]
    exact hittingBtwn_congr_of_lt_aux h
  | succ k ih =>
    have hu : upperCrossingTime a b f N (k + 1) ω = upperCrossingTime a b g N (k + 1) ω := by
      rw [upperCrossingTime_succ_eq, upperCrossingTime_succ_eq, ih.2]
      exact hittingBtwn_congr_of_lt_aux h
    refine ⟨hu, ?_⟩
    change hittingBtwn f (Set.Iic a) (upperCrossingTime a b f N (k + 1) ω) N ω =
      hittingBtwn g (Set.Iic a) (upperCrossingTime a b g N (k + 1) ω) N ω
    rw [hu]
    exact hittingBtwn_congr_of_lt_aux h

/-- For a submartingale `g` and a betting stake `ξ` between 0 and 1 chosen from the past, the
expected winnings lie between `0` and `E[g m] - E[g 0]`. -/
theorem integral_sum_stake_aux {Ω : Type*} {m0 : MeasurableSpace Ω} {μ : Measure Ω}
    [IsFiniteMeasure μ] {ℱ : Filtration ℕ m0} {g ξ : ℕ → Ω → ℝ} (hg : Submartingale g ℱ μ)
    (hξ : StronglyAdapted ℱ ξ) (h0 : ∀ n ω, 0 ≤ ξ n ω) (h1 : ∀ n ω, ξ n ω ≤ 1) (m : ℕ) :
    Integrable (fun ω => ∑ k ∈ Finset.range m, ξ k ω * (g (k + 1) ω - g k ω)) μ ∧
    0 ≤ ∫ ω, ∑ k ∈ Finset.range m, ξ k ω * (g (k + 1) ω - g k ω) ∂μ ∧
      ∫ ω, ∑ k ∈ Finset.range m, ξ k ω * (g (k + 1) ω - g k ω) ∂μ ≤
        ∫ ω, g m ω ∂μ - ∫ ω, g 0 ω ∂μ := by
  have base : ∀ ζ : ℕ → Ω → ℝ, StronglyAdapted ℱ ζ → (∀ n ω, 0 ≤ ζ n ω) →
      (∀ n ω, ζ n ω ≤ 1) →
      Integrable (fun ω => ∑ k ∈ Finset.range m, ζ k ω * (g (k + 1) ω - g k ω)) μ ∧
      0 ≤ ∫ ω, ∑ k ∈ Finset.range m, ζ k ω * (g (k + 1) ω - g k ω) ∂μ := by
    intro ζ hζ hz0 hz1
    have S := hg.sum_mul_sub hζ hz1 hz0
    have hI := S.integrable m
    have hle := S.setIntegral_le (Nat.zero_le m) MeasurableSet.univ
    simp only [setIntegral_univ, Finset.range_zero, Finset.sum_empty] at hle
    simp only [Finset.sum_apply, Pi.mul_apply, Pi.sub_apply] at hI hle
    refine ⟨?_, by simpa using hle⟩
    convert hI using 1
    ext ω
    simp [Finset.sum_apply]
  obtain ⟨hI, hpos⟩ := base ξ hξ h0 h1
  refine ⟨hI, hpos, ?_⟩
  obtain ⟨hI', hpos'⟩ := base (fun n ω => 1 - ξ n ω)
    (fun n => (stronglyAdapted_const ℱ 1 n).sub (hξ n)) (fun n ω => by linarith [h1 n ω])
    (fun n ω => by linarith [h0 n ω])
  have hid : ∀ ω, ∑ k ∈ Finset.range m, (1 - ξ k ω) * (g (k + 1) ω - g k ω) =
      (g m ω - g 0 ω) - ∑ k ∈ Finset.range m, ξ k ω * (g (k + 1) ω - g k ω) := by
    intro ω
    rw [← Finset.sum_range_sub (fun k => g k ω), ← Finset.sum_sub_distrib]
    refine Finset.sum_congr rfl fun k _ => by ring
  simp_rw [hid] at hpos'
  have e1 : ∫ ω, (g m ω - g 0 ω -
      ∑ k ∈ Finset.range m, ξ k ω * (g (k + 1) ω - g k ω)) ∂μ =
      ∫ ω, (g m ω - g 0 ω) ∂μ - ∫ ω, ∑ k ∈ Finset.range m, ξ k ω * (g (k + 1) ω - g k ω) ∂μ :=
    integral_sub ((hg.integrable m).sub (hg.integrable 0)) hI
  have e2 : ∫ ω, (g m ω - g 0 ω) ∂μ = ∫ ω, g m ω ∂μ - ∫ ω, g 0 ω ∂μ :=
    integral_sub (hg.integrable m) (hg.integrable 0)
  rw [e1, e2] at hpos'
  linarith

/-- **Doob's martingale convergence theorem.** On a probability space with a filtration in
discrete time, let `X` be a martingale or a supermartingale (a supermartingale includes every
martingale) whose average size stays below a fixed ceiling: `E|X n| ≤ K` for every `n`. Then
there is a limit `X∞` such that, with probability 1, each path `X n ω` settles to the finite
number `X∞ ω`; the limit is integrable and its average size is at most `K` too. Different paths
may settle to different limits. -/
theorem martingale_convergence_of_bounded_average_size
    {Ω : Type*} {m0 : MeasurableSpace Ω} (μ : Measure Ω) [IsProbabilityMeasure μ]
    (ℱ : Filtration ℕ m0) (X : ℕ → Ω → ℝ) (hX : Supermartingale X ℱ μ)
    (K : ℝ) (hK : ∀ n, ∫ ω, |X n ω| ∂μ ≤ K) :
    ∃ Xlim : Ω → ℝ,
      (∀ᵐ ω ∂μ, Tendsto (fun n => X n ω) atTop (𝓝 (Xlim ω))) ∧
        Integrable Xlim μ ∧ ∫ ω, |Xlim ω| ∂μ ≤ K := by
  have hK0 : 0 ≤ K := le_trans (integral_nonneg fun ω => abs_nonneg _) (hK 0)
  have hY := hX.neg
  have hbdd : ∀ n, eLpNorm ((-X) n) 1 μ ≤ (K.toNNReal : ENNReal) := by
    intro n
    have hi : Integrable ((-X) n) μ := hY.integrable n
    rw [eLpNorm_one_eq_lintegral_enorm hi.aestronglyMeasurable, ENNReal.ofNNReal_toNNReal]
    rw [← ofReal_integral_norm_eq_lintegral_enorm hi]
    refine ENNReal.ofReal_le_ofReal ?_
    simpa [Real.norm_eq_abs] using hK n
  have hlim := hY.ae_tendsto_limitProcess hbdd
  have hmem := hY.memLp_limitProcess hbdd
  set L := ℱ.limitProcess (-X) μ
  refine ⟨-L, ?_, ?_, ?_⟩
  · filter_upwards [hlim] with ω hω
    simpa using hω.neg
  · exact (memLp_one_iff_integrable.1 hmem).neg
  · have hLm : AEStronglyMeasurable L μ := hmem.aestronglyMeasurable
    have hfat := Lp.eLpNorm_lim_le_liminf_eLpNorm (p := 1)
      (fun n => (hY.integrable n).aestronglyMeasurable) L hLm hlim
    have h2 : eLpNorm L 1 μ ≤ ENNReal.ofReal K := by
      refine hfat.trans ?_
      refine Filter.liminf_le_of_frequently_le' (Frequently.of_forall fun n => ?_)
      simpa [ENNReal.ofNNReal_toNNReal] using hbdd n
    have h3 : ∫ ω, |(-L) ω| ∂μ = ∫ ω, ‖L ω‖ ∂μ := by simp [Real.norm_eq_abs]
    rw [h3, integral_norm_eq_lintegral_enorm hLm, ← eLpNorm_one_eq_lintegral_enorm hLm]
    exact ENNReal.toReal_le_of_le_ofReal hK0 h2

/-- **The upcrossing inequality** (Doob, 1953). For a martingale or supermartingale `X` and a
band from `a` up to `b` with `a < b`, the band's width times the expected number of upcrossings
completed by time `n` is at most the expected shortfall below `a` at time `n`:
`(b - a) E[U_n[a,b]] ≤ E[(X n - a)⁻]`. Mathlib's `upcrossingsBefore a b X (n + 1)` counts the
upcrossings of `[a, b]` finished at a time `≤ n`, which is the card's `U_n[a,b]`. -/
theorem upcrossing_inequality
    {Ω : Type*} {m0 : MeasurableSpace Ω} (μ : Measure Ω) [IsProbabilityMeasure μ]
    (ℱ : Filtration ℕ m0) (X : ℕ → Ω → ℝ) (hX : Supermartingale X ℱ μ)
    (a b : ℝ) (hab : a < b) (n : ℕ) :
    (b - a) * ∫ ω, (upcrossingsBefore a b X (n + 1) ω : ℝ) ∂μ ≤ ∫ ω, (X n ω - a)⁻ ∂μ := by
  set X' : ℕ → Ω → ℝ := fun k => X (min k n) with hX'
  have hagree : ∀ ω, ∀ j < n + 1, X j ω = X' j ω := by
    intro ω j hj
    simp only [hX', min_eq_left (Nat.lt_succ_iff.1 hj)]
  have hU : ∀ ω, upcrossingsBefore a b X (n + 1) ω = upcrossingsBefore a b X' (n + 1) ω := by
    intro ω
    simp only [upcrossingsBefore, (crossing_congr_of_lt_aux (a := a) (b := b) (hagree ω) _).1]
  have hC : ∀ k ω, upcrossingStrat a b X (n + 1) k ω = upcrossingStrat a b X' (n + 1) k ω := by
    intro k ω
    simp only [upcrossingStrat, (crossing_congr_of_lt_aux (a := a) (b := b) (hagree ω) _).1,
      (crossing_congr_of_lt_aux (a := a) (b := b) (hagree ω) _).2]
  set C := upcrossingStrat a b X (n + 1) with hCdef
  have hCpos : ∀ k ω, upcrossingStrat 0 (b - a) (fun k ω => (X' k ω - a)⁺) (n + 1) k ω =
      C k ω := by
    intro k ω
    rw [hC]
    simp only [upcrossingStrat, (crossing_pos_eq hab).1, (crossing_pos_eq hab).2]
  have hpp : ∀ x : ℝ, x⁺ = x + x⁻ := fun x => by linarith [posPart_sub_negPart x]
  -- the pathwise inequality
  have hpath : ∀ ω, (b - a) * (upcrossingsBefore a b X (n + 1) ω : ℝ) ≤
      ∑ k ∈ Finset.range n, C k ω * (X (k + 1) ω - X k ω) +
        ∑ k ∈ Finset.range n, C k ω * ((X (k + 1) ω - a)⁻ - (X k ω - a)⁻) := by
    intro ω
    rw [hU, ← upcrossingsBefore_pos_eq hab]
    have hm := mul_upcrossingsBefore_le (f := fun k ω => (X' k ω - a)⁺) (a := 0) (b := b - a)
      (N := n + 1) (ω := ω) (posPart_nonneg _) (sub_pos.2 hab)
    rw [sub_zero] at hm
    refine hm.trans (le_of_eq ?_)
    rw [Finset.sum_range_succ, ← Finset.sum_add_distrib]
    have hlast : X' (n + 1) ω = X' n ω := by simp [hX']
    simp only [Pi.sub_apply, hlast, sub_self, mul_zero, add_zero]
    refine Finset.sum_congr rfl fun k hk => ?_
    have hk' : k < n := Finset.mem_range.1 hk
    rw [hCpos]
    simp only [hX', min_eq_left hk'.le, min_eq_left (Nat.succ_le_of_lt hk')]
    rw [hpp (X (k + 1) ω - a), hpp (X k ω - a)]
    ring
  have hCad : StronglyAdapted ℱ C := hX.stronglyAdapted.upcrossingStrat
  have hC0 : ∀ k ω, 0 ≤ C k ω := fun _ _ => upcrossingStrat_nonneg
  have hC1 : ∀ k ω, C k ω ≤ 1 := fun _ _ => upcrossingStrat_le_one
  -- the game itself is unfavourable
  obtain ⟨hI1, hE1, -⟩ := integral_sum_stake_aux hX.neg hCad hC0 hC1 n
  have hI1' : Integrable (fun ω => ∑ k ∈ Finset.range n, C k ω * (X (k + 1) ω - X k ω)) μ := by
    have := hI1.neg
    refine this.congr (Eventually.of_forall fun ω => ?_)
    simp only [Pi.neg_apply, ← Finset.sum_neg_distrib]
    refine Finset.sum_congr rfl fun k _ => by ring
  have hE1' : ∫ ω, ∑ k ∈ Finset.range n, C k ω * (X (k + 1) ω - X k ω) ∂μ ≤ 0 := by
    have heq : ∀ ω, ∑ k ∈ Finset.range n, C k ω * ((-X) (k + 1) ω - (-X) k ω) =
        -∑ k ∈ Finset.range n, C k ω * (X (k + 1) ω - X k ω) := by
      intro ω
      simp only [Pi.neg_apply, ← Finset.sum_neg_distrib]
      refine Finset.sum_congr rfl fun k _ => by ring
    simp_rw [heq, integral_neg] at hE1
    linarith
  -- the shortfall below `a` is a submartingale
  have hh : Submartingale (fun k ω => (X k ω - a)⁻) ℱ μ := by
    have := (hX.neg.sub_martingale (martingale_const ℱ μ (-a))).pos
    convert this using 1
    ext k ω
    simp only [Pi.posPart_apply, Pi.sub_apply, Pi.neg_apply]
    rw [← posPart_neg]
    congr 1
    ring
  obtain ⟨hI2, -, hE2⟩ := integral_sum_stake_aux hh hCad hC0 hC1 n
  have h0 : 0 ≤ ∫ ω, (X 0 ω - a)⁻ ∂μ := integral_nonneg fun ω => negPart_nonneg _
  have hUi : Integrable (fun ω => (upcrossingsBefore a b X (n + 1) ω : ℝ)) μ :=
    hX.stronglyAdapted.integrable_upcrossingsBefore hab
  calc (b - a) * ∫ ω, (upcrossingsBefore a b X (n + 1) ω : ℝ) ∂μ
      = ∫ ω, (b - a) * (upcrossingsBefore a b X (n + 1) ω : ℝ) ∂μ := (integral_const_mul _ _).symm
    _ ≤ ∫ ω, (∑ k ∈ Finset.range n, C k ω * (X (k + 1) ω - X k ω) +
        ∑ k ∈ Finset.range n, C k ω * ((X (k + 1) ω - a)⁻ - (X k ω - a)⁻)) ∂μ :=
        integral_mono (hUi.const_mul _) (hI1'.add hI2) hpath
    _ = ∫ ω, ∑ k ∈ Finset.range n, C k ω * (X (k + 1) ω - X k ω) ∂μ +
        ∫ ω, ∑ k ∈ Finset.range n, C k ω * ((X (k + 1) ω - a)⁻ - (X k ω - a)⁻) ∂μ :=
        integral_add hI1' hI2
    _ ≤ ∫ ω, (X n ω - a)⁻ ∂μ := by linarith

/-- **Pólya's urn is a fair game.** With `r` red balls out of `n + 2` after `n` draws, the next
draw is red with chance `r/(n+2)`, making the fraction red `(r+1)/(n+3)`, and otherwise it
becomes `r/(n+3)`. The forecast of the next fraction equals the fraction now, `r/(n+2)`. -/
theorem polya_urn_forecast_eq_fraction_now (n r : ℕ) :
    (r : ℚ) / (n + 2) * ((r + 1) / (n + 3)) + ((n + 2 - r) / (n + 2)) * (r / (n + 3)) =
      r / (n + 2) := by
  have h1 : (n : ℚ) + 2 ≠ 0 := by positivity
  have h2 : (n : ℚ) + 3 ≠ 0 := by positivity
  field_simp
  ring

/-! Worked numbers from the card, in exact fractions. -/

-- After one draw the fraction is 2/3 or 1/3, chance 1/2 each: the forecast is 1/2.
example : (1 : ℚ) / 2 * (2 / 3) + 1 / 2 * (1 / 3) = 1 / 2 := by norm_num

-- Order red, red, blue: 1/2 × 2/3 × 1/4 = 1/12.
example : (1 : ℚ) / 2 * (2 / 3) * (1 / 4) = 1 / 12 := by norm_num

-- Orders red, blue, red and blue, red, red: 1/2 × 1/3 × 2/4 = 1/12 each.
example : (1 : ℚ) / 2 * (1 / 3) * (2 / 4) = 1 / 12 := by norm_num

-- 3 reds of 5 balls after 3 draws: 3 orders × 1/12 = 1/4, like every other count.
example : (3 : ℚ) * (1 / 12) = 1 / 4 := by norm_num

-- The even law for n = 3: each count k of new reds has chance C(3,k) k! (3-k)! / 4!, and
-- C(3,k) k! (3-k)! = 3! = 6 for every k, so each chance is 6/24 = 1/4.
example : ∀ k ∈ Finset.range 4,
    Nat.choose 3 k * (Nat.factorial k * Nat.factorial (3 - k)) = 6 := by
  decide

example : (6 : ℚ) / Nat.factorial 4 = 1 / 4 := by norm_num [Nat.factorial]

-- Average shortfall below 2/5 at draw 16: levels j/18, j = 1..17, each with chance 1/17.
example : (∑ j ∈ Finset.range 17, max ((2 : ℚ) / 5 - (j + 1) / 18) 0) / 17 = 56 / 765 := by
  norm_num [Finset.sum_range_succ]

-- Upcrossing bound at draw 16 for the band 2/5 to 3/5: (56/765) / (1/5) = 56/153.
example : ((56 : ℚ) / 765) / (3 / 5 - 2 / 5) = 56 / 153 := by norm_num

-- The ceiling K = 1/2 caps the average upcrossings at (2/5 + 1/2) / (1/5) = 9/2.
example : ((2 : ℚ) / 5 + 1 / 2) / (3 / 5 - 2 / 5) = 9 / 2 := by norm_num

-- The urn's own cap over all time: (2/5)^2 / 2 = 2/25, and (2/25) / (1/5) = 2/5.
example : ((2 : ℚ) / 5) ^ 2 / 2 = 2 / 25 ∧ ((2 : ℚ) / 25) / (1 / 5) = 2 / 5 := by norm_num

-- Squared travel left after n draws is 1/(6(n+2)): 1/612 after 100 draws, 1/6012 after 1,000.
example : (1 : ℚ) / (6 * (100 + 2)) = 1 / 612 ∧ (1 : ℚ) / (6 * (1000 + 2)) = 1 / 6012 := by
  norm_num

-- Doubling, n = 10 rounds: won with chance 1 - 2^(-10) = 1023/1024, and
-- E|X| = 2 - 2^(1-10) = 1023/512.
example : (1 : ℚ) - 1 / 2 ^ 10 = 1023 / 1024 ∧ (2 : ℚ) - 2 / 2 ^ 10 = 1023 / 512 := by norm_num

#print axioms hittingBtwn_congr_of_lt_aux
#print axioms crossing_congr_of_lt_aux
#print axioms integral_sum_stake_aux
#print axioms martingale_convergence_of_bounded_average_size
#print axioms upcrossing_inequality
#print axioms polya_urn_forecast_eq_fraction_now
