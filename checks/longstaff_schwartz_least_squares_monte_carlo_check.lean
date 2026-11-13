-- Longstaff-Schwartz: the conditional average of the cash collected given the share price is the least-squares predictor among all curves in the price, plus whole-number checks of the card's eight-future example.
import Mathlib.MeasureTheory.Function.ConditionalExpectation.Real
import Mathlib.Probability.ConditionalExpectation
import Mathlib.Tactic.NormNum
import Mathlib.MeasureTheory.Function.ConditionalExpectation.PullOut

open MeasureTheory

theorem ls_split_helper
    {Ω : Type*} [mΩ : MeasurableSpace Ω] {μ : Measure Ω} [IsProbabilityMeasure μ]
    (S Y : Ω → ℝ) (F : ℝ → ℝ)
    (hS : Measurable S) (hF : Measurable F)
    (hY : MemLp Y 2 μ) (hFS : MemLp (fun ω => F (S ω)) 2 μ) :
    ∫ ω, (Y ω - F (S ω)) ^ 2 ∂μ
      = ∫ ω, (Y ω - μ[Y | MeasurableSpace.comap S inferInstance] ω) ^ 2 ∂μ
        + ∫ ω, (μ[Y | MeasurableSpace.comap S inferInstance] ω - F (S ω)) ^ 2 ∂μ := by
  set m : MeasurableSpace Ω := MeasurableSpace.comap S inferInstance with hm_def
  have hm : m ≤ mΩ := hS.comap_le
  set M := μ[Y | m] with hM
  have hMLp : MemLp M 2 μ := hY.condExp (by norm_num)
  have hGm : StronglyMeasurable[m] (fun ω => F (S ω)) :=
    (hF.comp (comap_measurable S)).stronglyMeasurable
  have hMm : StronglyMeasurable[m] M := stronglyMeasurable_condExp
  set D : Ω → ℝ := fun ω => M ω - F (S ω) with hD
  have hDm : StronglyMeasurable[m] D := hMm.sub hGm
  have hDLp : MemLp D 2 μ := hMLp.sub hFS
  have hDY : Integrable (D * Y) μ := hDLp.integrable_mul hY
  have hDM : Integrable (D * M) μ := hDLp.integrable_mul hMLp
  have horth : ∫ ω, D ω * Y ω ∂μ = ∫ ω, D ω * M ω ∂μ := by
    have h1 : ∫ ω, (μ[D * Y | m]) ω ∂μ = ∫ ω, (D * Y) ω ∂μ := integral_condExp hm
    have h2 : μ[D * Y | m] =ᵐ[μ] D * M :=
      condExp_mul_of_stronglyMeasurable_left hDm hDY (hY.integrable one_le_two)
    rw [integral_congr_ae h2] at h1
    simpa using h1.symm
  have hYM : MemLp (fun ω => Y ω - M ω) 2 μ := hY.sub hMLp
  have i1 : Integrable (fun ω => (Y ω - M ω) ^ 2) μ := hYM.integrable_sq
  have i2 : Integrable (fun ω => D ω ^ 2) μ := hDLp.integrable_sq
  have key : (fun ω => (Y ω - F (S ω)) ^ 2) =
      fun ω => ((Y ω - M ω) ^ 2 + D ω ^ 2) + 2 * (D ω * Y ω - D ω * M ω) := by
    funext ω; simp only [hD]; ring
  have i3 : Integrable (fun ω => 2 * (D ω * Y ω - D ω * M ω)) μ :=
    (hDY.sub hDM).const_mul 2
  have i12 : Integrable (fun ω => (Y ω - M ω) ^ 2 + D ω ^ 2) μ := i1.add i2
  rw [key, integral_add i12 i3, integral_add i1 i2, integral_const_mul,
    integral_sub (f := fun ω => D ω * Y ω) (g := fun ω => D ω * M ω) hDY hDM, horth]
  simp [hD]

#print axioms ls_split_helper

/-- The conditional average is the least-squares predictor: for a square-integrable cash
amount `Y` and a share price `S`, no curve `F` in the price misses `Y` by less, in mean
square, than the conditional average `M(S) = E[Y | S]`. -/
theorem conditional_average_minimises_mean_square_miss
    {Ω : Type*} [mΩ : MeasurableSpace Ω] {μ : Measure Ω} [IsProbabilityMeasure μ]
    (S Y : Ω → ℝ) (F : ℝ → ℝ)
    (hS : Measurable S) (hF : Measurable F)
    (hY : MemLp Y 2 μ) (hFS : MemLp (fun ω => F (S ω)) 2 μ) :
    ∫ ω, (Y ω - μ[Y | MeasurableSpace.comap S inferInstance] ω) ^ 2 ∂μ
      ≤ ∫ ω, (Y ω - F (S ω)) ^ 2 ∂μ := by
  rw [ls_split_helper S Y F hS hF hY hFS]
  have : 0 ≤ ∫ ω, (μ[Y | MeasurableSpace.comap S inferInstance] ω - F (S ω)) ^ 2 ∂μ :=
    integral_nonneg fun ω => sq_nonneg _
  linarith

/-- The split of the miss used in the card's proof: the mean-square miss of any curve `F`
in the price equals the part no curve can explain, `E[(Y - M(S))^2]`, plus the curve's own
error, `E[(M(S) - F(S))^2]`. -/
theorem mean_square_miss_eq_unexplained_add_fit_error
    {Ω : Type*} [mΩ : MeasurableSpace Ω] {μ : Measure Ω} [IsProbabilityMeasure μ]
    (S Y : Ω → ℝ) (F : ℝ → ℝ)
    (hS : Measurable S) (hF : Measurable F)
    (hY : MemLp Y 2 μ) (hFS : MemLp (fun ω => F (S ω)) 2 μ) :
    ∫ ω, (Y ω - F (S ω)) ^ 2 ∂μ
      = ∫ ω, (Y ω - μ[Y | MeasurableSpace.comap S inferInstance] ω) ^ 2 ∂μ
        + ∫ ω, (μ[Y | MeasurableSpace.comap S inferInstance] ω - F (S ω)) ^ 2 ∂μ := by
  exact ls_split_helper S Y F hS hF hY hFS

/-- Equality holds only where the two curves agree: a curve `F` in the price attains the
smallest mean-square miss exactly when `F(S)` equals the conditional average almost surely. -/
theorem mean_square_miss_eq_min_iff
    {Ω : Type*} [mΩ : MeasurableSpace Ω] {μ : Measure Ω} [IsProbabilityMeasure μ]
    (S Y : Ω → ℝ) (F : ℝ → ℝ)
    (hS : Measurable S) (hF : Measurable F)
    (hY : MemLp Y 2 μ) (hFS : MemLp (fun ω => F (S ω)) 2 μ) :
    ∫ ω, (Y ω - F (S ω)) ^ 2 ∂μ
        = ∫ ω, (Y ω - μ[Y | MeasurableSpace.comap S inferInstance] ω) ^ 2 ∂μ
      ↔ (fun ω => F (S ω)) =ᵐ[μ] μ[Y | MeasurableSpace.comap S inferInstance] := by
  rw [ls_split_helper S Y F hS hF hY hFS]
  have hMLp : MemLp (μ[Y | MeasurableSpace.comap S inferInstance]) 2 μ :=
    hY.condExp (by norm_num)
  have hint : Integrable
      (fun ω => (μ[Y | MeasurableSpace.comap S inferInstance] ω - F (S ω)) ^ 2) μ :=
    (hMLp.sub hFS).integrable_sq
  constructor
  · intro h
    have h0 : ∫ ω, (μ[Y | MeasurableSpace.comap S inferInstance] ω - F (S ω)) ^ 2 ∂μ = 0 := by
      linarith
    rw [integral_eq_zero_iff_of_nonneg (fun ω => sq_nonneg _) hint] at h0
    filter_upwards [h0] with ω hω
    have : (μ[Y | MeasurableSpace.comap S inferInstance] ω - F (S ω)) ^ 2 = 0 := hω
    have := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp this
    linarith
  · intro h
    have h0 : ∫ ω, (μ[Y | MeasurableSpace.comap S inferInstance] ω - F (S ω)) ^ 2 ∂μ = 0 := by
      rw [integral_eq_zero_iff_of_nonneg (fun ω => sq_nonneg _) hint]
      filter_upwards [h] with ω hω
      simp [← hω]
    linarith

/-! Whole-number checks of the card's eight made-up futures (strike 100). -/

-- Cash at month 12, `max(100 - S, 0)` (truncated subtraction on ℕ), for the eight futures.
example : [118, 91, 101, 97, 96, 89, 99, 107].map (fun s : ℕ => 100 - s)
    = [0, 9, 0, 3, 4, 11, 1, 0] := by decide

-- Month 8: five futures are in the money (Acme below 100): futures 2, 3, 5, 6 and 7.
example : ([112, 94, 99, 101, 90, 96, 93, 104].filter (fun s : ℕ => s < 100))
    = [94, 99, 90, 96, 93] := by decide

-- Month 8: cash now for those five futures is 6, 1, 10, 4 and 7.
example : [94, 99, 90, 96, 93].map (fun s : ℕ => 100 - s) = [6, 1, 10, 4, 7] := by decide

-- Month 8 normal equations: with x = S / 100, the sums are 5, 4.7200 and 4.4602.
example : (([94, 99, 90, 96, 93] : List ℚ).map (fun s => s / 100)).sum = 472 / 100 := by
  norm_num
example : (([94, 99, 90, 96, 93] : List ℚ).map (fun s => (s / 100) ^ 2)).sum
    = 44602 / 10000 := by
  norm_num

-- Month 4: four futures are in the money: futures 2, 4, 5 and 7.
example : ([106, 98, 103, 95, 88, 100, 97, 109].filter (fun s : ℕ => s < 100))
    = [98, 95, 88, 97] := by decide

-- Month 4: cash now for those four futures is 2, 5, 12 and 3.
example : [98, 95, 88, 97].map (fun s : ℕ => 100 - s) = [2, 5, 12, 3] := by decide

-- Month 4 normal equations: the sums are 4, 3.7800 and 3.5782.
example : (([98, 95, 88, 97] : List ℚ).map (fun s => s / 100)).sum = 378 / 100 := by
  norm_num
example : (([98, 95, 88, 97] : List ℚ).map (fun s => (s / 100) ^ 2)).sum
    = 35782 / 10000 := by
  norm_num

#print axioms conditional_average_minimises_mean_square_miss
#print axioms mean_square_miss_eq_unexplained_add_fit_error
#print axioms mean_square_miss_eq_min_iff
