-- Convergence: for every 2π-periodic wave made of finitely many smooth pieces per cycle, the Fourier partial sums at each point tend to the midpoint of the left and right values; the square wave's peak beside its jump tends to (2/π) Si(π) however many tones are kept; and the square wave at π/2 gives Leibniz's π/4 = 1 − 1/3 + 1/5 − ⋯.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Tactic.NormNum
import Mathlib

open Real Filter Topology Finset

/-- The Fourier partial sum with every harmonic up to n:
`a_0/2 + ∑_{k=1}^{n} (a_k cos(kx) + b_k sin(kx))`, with the coefficients
`a_k = (1/π) ∫_{−π}^{π} f(t) cos(kt) dt` and `b_k = (1/π) ∫_{−π}^{π} f(t) sin(kt) dt`. -/
noncomputable def fourierPartialSum (f : ℝ → ℝ) (n : ℕ) (x : ℝ) : ℝ :=
  (1 / π) * (∫ t in (-π)..π, f t) / 2 +
    ∑ k ∈ Icc 1 n,
      ((1 / π) * (∫ t in (-π)..π, f t * cos (k * t)) * cos (k * x) +
        (1 / π) * (∫ t in (-π)..π, f t * sin (k * t)) * sin (k * x))

/-- The card's square-wave stack of the first N odd harmonics:
`S_N(x) = (4/π) ∑_{k=1}^{N} sin((2k−1)x)/(2k−1)`. -/
noncomputable def squareWavePartialSum (N : ℕ) (x : ℝ) : ℝ :=
  4 / π * ∑ k ∈ Icc 1 N, sin ((2 * k - 1) * x) / (2 * k - 1)

noncomputable def dk (n : ℕ) (u : ℝ) : ℝ := 1 / 2 + ∑ k ∈ Icc 1 n, cos (k * u)

lemma dk_continuous (n : ℕ) : Continuous (dk n) := by
  unfold dk; fun_prop

lemma dk_periodic (n : ℕ) : Function.Periodic (dk n) (2 * π) := by
  intro u
  simp only [dk]
  congr 1
  apply sum_congr rfl
  intro k _
  rw [mul_add, cos_add_nat_mul_two_pi]

lemma dk_neg (n : ℕ) (u : ℝ) : dk n (-u) = dk n u := by
  simp [dk, mul_neg, cos_neg]

lemma dk_mul_sin (n : ℕ) (u : ℝ) : dk n u * (2 * sin (u / 2)) = sin ((n + 1 / 2) * u) := by
  induction n with
  | zero => simp [dk]; ring_nf
  | succ n ih =>
    rw [dk, Finset.sum_Icc_succ_top (by omega), ← add_assoc]
    rw [dk] at ih
    rw [add_mul, ih]
    push_cast
    have e1 : ((n:ℝ) + 1 + 1 / 2) * u = (n + 1) * u + u / 2 := by ring
    have e2 : ((n:ℝ) + 1 / 2) * u = (n + 1) * u - u / 2 := by ring
    rw [e1, e2, sin_add, sin_sub]
    ring

lemma dk_integral (n : ℕ) : ∫ u in (0:ℝ)..π, dk n u = π / 2 := by
  unfold dk
  rw [intervalIntegral.integral_add intervalIntegrable_const
      ((by fun_prop : Continuous fun u : ℝ => ∑ k ∈ Icc 1 n, cos (k * u)).intervalIntegrable _ _),
    intervalIntegral.integral_finsetSum (fun k _ => by
      exact (by fun_prop : Continuous fun u : ℝ => cos (k * u)).intervalIntegrable _ _)]
  have h : ∀ k ∈ Icc 1 n, ∫ u in (0:ℝ)..π, cos (k * u) = 0 := by
    intro k hk
    have hk0 : (k:ℝ) ≠ 0 := by
      have := (mem_Icc.mp hk).1
      exact_mod_cast (by omega : k ≠ 0)
    rw [intervalIntegral.integral_comp_mul_left (fun u => cos u) hk0, integral_cos]
    simp [sin_nat_mul_pi]
  rw [sum_congr rfl h]
  simp
  ring

/-- Riemann–Lebesgue for a sine on `[0, π]`. -/
lemma rl_sin (φ : ℝ → ℝ) (hφ : MeasureTheory.IntegrableOn φ (Set.Ioc 0 π)) :
    Tendsto (fun lam : ℝ => ∫ u in (0:ℝ)..π, φ u * sin (lam * u)) atTop (𝓝 0) := by
  set G : ℝ → ℂ := Set.indicator (Set.Ioc 0 π) (fun u => (φ u : ℂ)) with hGdef
  have hG : MeasureTheory.Integrable G :=
    (MeasureTheory.integrable_indicator_iff measurableSet_Ioc).mpr hφ.ofReal
  have h := Real.tendsto_integral_exp_smul_cocompact G
  have h2 : Tendsto (fun lam : ℝ => lam / (2 * π)) atTop (cocompact ℝ) :=
    (tendsto_id.atTop_div_const (by positivity)).mono_right atTop_le_cocompact
  have h3 := (Complex.continuous_im.tendsto 0).comp (h.comp h2)
  simp only [Complex.zero_im] at h3
  have key : ∀ lam : ℝ, ∫ u in (0:ℝ)..π, φ u * sin (lam * u) =
      -(Complex.im (∫ v : ℝ, Real.fourierChar (-(v * (lam / (2 * π)))) • G v)) := by
    intro lam
    have hint : MeasureTheory.Integrable (fun v : ℝ => Real.fourierChar (-(v * (lam / (2 * π)))) • G v) := by
      have := (Real.fourierIntegral_convergent_iff (μ := MeasureTheory.volume) (f := G)
        (lam / (2 * π))).mpr hG
      simpa [mul_comm] using this
    have him := integral_im hint
    simp only [RCLike.im_to_complex] at him
    rw [← him, intervalIntegral.integral_of_le pi_pos.le,
      ← MeasureTheory.integral_neg, ← MeasureTheory.integral_indicator measurableSet_Ioc]
    congr 1
    ext v
    by_cases hv : v ∈ Set.Ioc 0 π
    · simp only [Set.indicator_of_mem hv, hGdef, Circle.smul_def, Real.fourierChar_apply]
      rw [show ((2 * π * -(v * (lam / (2 * π))) : ℝ) : ℂ) = ((-(lam * v) : ℝ) : ℂ) by
        congr 1; field_simp]
      rw [smul_eq_mul, Complex.mul_im, Complex.exp_ofReal_mul_I_im, Complex.exp_ofReal_mul_I_re]
      simp [sin_neg, mul_comm]
    · simp [Set.indicator_of_notMem hv, hGdef]
  simp_rw [key]
  have := h3.neg
  simpa [Function.comp_def] using this

lemma exists_piece_Ico {m : ℕ} (a : Fin (m + 1) → ℝ) {z : ℝ} (h0 : a 0 ≤ z)
    (h1 : z < a (Fin.last m)) : ∃ i : Fin m, a i.castSucc ≤ z ∧ z < a i.succ := by
  by_contra hcon
  simp only [not_exists, not_and, not_lt] at hcon
  have key : ∀ j (hj : j ≤ m), a ⟨j, by omega⟩ ≤ z := by
    intro j
    induction j with
    | zero => intro _; simpa using h0
    | succ j ih =>
      intro hj
      exact hcon ⟨j, by omega⟩ (ih (by omega))
  exact absurd (key m le_rfl) (not_le.mpr h1)

lemma exists_piece_Ioc {m : ℕ} (a : Fin (m + 1) → ℝ) {z : ℝ} (h0 : a 0 < z)
    (h1 : z ≤ a (Fin.last m)) : ∃ i : Fin m, a i.castSucc < z ∧ z ≤ a i.succ := by
  by_contra hcon
  simp only [not_exists, not_and, not_le] at hcon
  have key : ∀ j (hj : j ≤ m), a ⟨j, by omega⟩ < z := by
    intro j
    induction j with
    | zero => intro _; simpa using h0
    | succ j ih =>
      intro hj
      exact hcon ⟨j, by omega⟩ (ih (by omega))
  exact absurd (key m le_rfl) (not_lt.mpr h1)

lemma right_piece (f : ℝ → ℝ) (hper : Function.Periodic f (2 * π)) {m : ℕ}
    {a : Fin (m + 1) → ℝ} (hlast : a (Fin.last m) = a 0 + 2 * π)
    (hg : ∀ i : Fin m, ∃ g : ℝ → ℝ, ContDiff ℝ 1 g ∧ Set.EqOn f g (Set.Ioo (a i.castSucc) (a i.succ)))
    (y : ℝ) : ∃ δ > 0, ∃ g : ℝ → ℝ, ContDiff ℝ 1 g ∧ Set.EqOn f g (Set.Ioo y (y + δ)) := by
  have hp : (0:ℝ) < 2 * π := by positivity
  have hz := toIcoMod_mem_Ico hp (a 0) y
  have hyz := self_sub_toIcoDiv_zsmul hp (a 0) y
  set k := toIcoDiv hp (a 0) y
  set z := toIcoMod hp (a 0) y
  obtain ⟨i, hi1, hi2⟩ := exists_piece_Ico a hz.1 (by rw [hlast]; exact hz.2)
  obtain ⟨g, hgc, hgeq⟩ := hg i
  refine ⟨a i.succ - z, by linarith, fun t => g (t - k • (2 * π)), ?_, ?_⟩
  · exact hgc.comp (contDiff_id.sub contDiff_const)
  · intro t ht
    have hmem : t - k • (2 * π) ∈ Set.Ioo (a i.castSucc) (a i.succ) := by
      constructor <;> linarith [ht.1, ht.2]
    show f t = g (t - k • (2 * π))
    rw [← hgeq hmem, hper.sub_zsmul_eq]

lemma left_piece (f : ℝ → ℝ) (hper : Function.Periodic f (2 * π)) {m : ℕ}
    {a : Fin (m + 1) → ℝ} (hlast : a (Fin.last m) = a 0 + 2 * π)
    (hg : ∀ i : Fin m, ∃ g : ℝ → ℝ, ContDiff ℝ 1 g ∧ Set.EqOn f g (Set.Ioo (a i.castSucc) (a i.succ)))
    (y : ℝ) : ∃ δ > 0, ∃ g : ℝ → ℝ, ContDiff ℝ 1 g ∧ Set.EqOn f g (Set.Ioo (y - δ) y) := by
  have hp : (0:ℝ) < 2 * π := by positivity
  have hz := toIocMod_mem_Ioc hp (a 0) y
  have hyz := self_sub_toIocDiv_zsmul hp (a 0) y
  set k := toIocDiv hp (a 0) y
  set z := toIocMod hp (a 0) y
  obtain ⟨i, hi1, hi2⟩ := exists_piece_Ioc a hz.1 (by rw [hlast]; exact hz.2)
  obtain ⟨g, hgc, hgeq⟩ := hg i
  refine ⟨z - a i.castSucc, by linarith, fun t => g (t - k • (2 * π)), ?_, ?_⟩
  · exact hgc.comp (contDiff_id.sub contDiff_const)
  · intro t ht
    have hmem : t - k • (2 * π) ∈ Set.Ioo (a i.castSucc) (a i.succ) := by
      constructor <;> linarith [ht.1, ht.2]
    show f t = g (t - k • (2 * π))
    rw [← hgeq hmem, hper.sub_zsmul_eq]

lemma piecewise_intervalIntegrable (f : ℝ → ℝ) (hper : Function.Periodic f (2 * π)) {m : ℕ}
    {a : Fin (m + 1) → ℝ} (ha : StrictMono a) (hlast : a (Fin.last m) = a 0 + 2 * π)
    (hg : ∀ i : Fin m, ∃ g : ℝ → ℝ, ContDiff ℝ 1 g ∧ Set.EqOn f g (Set.Ioo (a i.castSucc) (a i.succ)))
    (b c : ℝ) : IntervalIntegrable f MeasureTheory.volume b c := by
  have hstep : ∀ i : Fin m, IntervalIntegrable f MeasureTheory.volume (a i.castSucc) (a i.succ) := by
    intro i
    obtain ⟨g, hgc, hgeq⟩ := hg i
    have hle : a i.castSucc ≤ a i.succ := ha.monotone (Fin.castSucc_lt_succ (i := i)).le
    rw [intervalIntegrable_iff_integrableOn_Ioo_of_le hle]
    exact ((hgc.continuous.integrableOn_Icc).mono_set Set.Ioo_subset_Icc_self).congr_fun
      hgeq.symm measurableSet_Ioo
  have hchain : ∀ j (hj : j ≤ m),
      IntervalIntegrable f MeasureTheory.volume (a 0) (a ⟨j, by omega⟩) := by
    intro j
    induction j with
    | zero => intro _; simp
    | succ j ih =>
      intro hj
      exact (ih (by omega)).trans (hstep ⟨j, by omega⟩)
  have hper_int : IntervalIntegrable f MeasureTheory.volume (a 0) (a 0 + 2 * π) := by
    rw [← hlast]; exact hchain m le_rfl
  exact hper.intervalIntegrable (by positivity) hper_int b c

lemma fourierPartialSum_eq_kernel (f : ℝ → ℝ) (hper : Function.Periodic f (2 * π))
    (hfi : ∀ b c, IntervalIntegrable f MeasureTheory.volume b c) (n : ℕ) (x : ℝ) :
    fourierPartialSum f n x = (1 / π) * ∫ u in (0:ℝ)..π, (f (x + u) + f (x - u)) * dk n u := by
  have hc : ∀ k : ℕ, IntervalIntegrable (fun t => f t * cos (k * t)) MeasureTheory.volume (-π) π :=
    fun k => (hfi _ _).mul_continuousOn (by fun_prop : Continuous fun t : ℝ => cos (k * t)).continuousOn
  have hs : ∀ k : ℕ, IntervalIntegrable (fun t => f t * sin (k * t)) MeasureTheory.volume (-π) π :=
    fun k => (hfi _ _).mul_continuousOn (by fun_prop : Continuous fun t : ℝ => sin (k * t)).continuousOn
  have hterm : ∀ k : ℕ, IntervalIntegrable
      (fun t => f t * cos (k * t) * cos (k * x) + f t * sin (k * t) * sin (k * x))
      MeasureTheory.volume (-π) π := fun k => ((hc k).mul_const _).add ((hs k).mul_const _)
  have step1 : fourierPartialSum f n x = (1 / π) * ∫ t in (-π)..π, f t * dk n (t - x) := by
    have h1 : (fun t => f t * dk n (t - x)) = fun t => f t * (1 / 2) + ∑ k ∈ Icc 1 n,
        (f t * cos (k * t) * cos (k * x) + f t * sin (k * t) * sin (k * x)) := by
      ext t
      simp only [dk, mul_add, Finset.mul_sum]
      congr 1
      apply sum_congr rfl
      intro k _
      rw [mul_sub, cos_sub]
      ring
    have hsum : IntervalIntegrable (fun t => ∑ k ∈ Icc 1 n,
        (f t * cos (k * t) * cos (k * x) + f t * sin (k * t) * sin (k * x)))
        MeasureTheory.volume (-π) π := by
      have := IntervalIntegrable.sum (Icc 1 n) (fun k _ => hterm k)
      convert this using 1
      ext t
      simp [Finset.sum_apply]
    rw [h1, intervalIntegral.integral_add ((hfi _ _).mul_const _) hsum,
      intervalIntegral.integral_finsetSum (fun k _ => hterm k)]
    rw [sum_congr rfl (fun k _ => intervalIntegral.integral_add ((hc k).mul_const _)
      ((hs k).mul_const _))]
    simp only [intervalIntegral.integral_mul_const, fourierPartialSum]
    rw [mul_add, Finset.mul_sum]
    congr 1
    · ring
    · apply sum_congr rfl
      intro k _
      ring
  have hh : Function.Periodic (fun u => f (x + u) * dk n u) (2 * π) := by
    intro u
    simp only
    rw [← add_assoc, hper, dk_periodic]
  have step2 : ∫ t in (-π)..π, f t * dk n (t - x) = ∫ u in (-π)..π, f (x + u) * dk n u := by
    have e1 := intervalIntegral.integral_comp_sub_right (a := -π) (b := π)
      (fun u => f (x + u) * dk n u) x
    simp only [show ∀ t, x + (t - x) = t from fun t => by ring] at e1
    rw [e1]
    have := hh.intervalIntegral_add_eq (-π - x) (-π)
    rw [show -π - x + 2 * π = π - x by ring, show -π + 2 * π = π by ring] at this
    exact this
  have hp1 : ∀ b c, IntervalIntegrable (fun u => f (x + u)) MeasureTheory.volume b c := by
    intro b c
    simpa using (hfi (x + b) (x + c)).comp_add_left x
  have hp2 : ∀ b c, IntervalIntegrable (fun u => f (x - u)) MeasureTheory.volume b c := by
    intro b c
    simpa using (hfi (x - b) (x - c)).comp_sub_left x
  have hint : ∀ b c, IntervalIntegrable (fun u => f (x + u) * dk n u) MeasureTheory.volume b c :=
    fun b c => (hp1 b c).mul_continuousOn (dk_continuous n).continuousOn
  have hint2 : ∀ b c, IntervalIntegrable (fun u => f (x - u) * dk n u) MeasureTheory.volume b c :=
    fun b c => (hp2 b c).mul_continuousOn (dk_continuous n).continuousOn
  have step3 : ∫ u in (-π)..π, f (x + u) * dk n u =
      ∫ u in (0:ℝ)..π, (f (x + u) + f (x - u)) * dk n u := by
    rw [← intervalIntegral.integral_add_adjacent_intervals (hint (-π) 0) (hint 0 π)]
    have e := intervalIntegral.integral_comp_neg (a := 0) (b := π) (fun u => f (x + u) * dk n u)
    simp only [neg_zero, dk_neg, ← sub_eq_add_neg] at e
    rw [← e, ← intervalIntegral.integral_add (hint2 0 π) (hint 0 π)]
    congr 1
    ext u
    ring
  rw [step1, step2, step3]

noncomputable def oddCosSum (N : ℕ) (x : ℝ) : ℝ := ∑ k ∈ Icc 1 N, cos ((2 * k - 1) * x)

lemma oddCosSum_mul (N : ℕ) (x : ℝ) : oddCosSum N x * (2 * sin x) = sin (2 * N * x) := by
  induction N with
  | zero => simp [oddCosSum]
  | succ N ih =>
    rw [oddCosSum, Finset.sum_Icc_succ_top (by omega), ← oddCosSum, add_mul, ih]
    push_cast
    have e1 : 2 * ((N:ℝ) + 1) * x = (2 * N + 1) * x + x := by ring
    have e2 : 2 * (N:ℝ) * x = (2 * N + 1) * x - x := by ring
    have e3 : (2 * ((N:ℝ) + 1) - 1) = 2 * N + 1 := by ring
    rw [e1, e2, e3, sin_add, sin_sub]
    ring

lemma oddCosSum_continuous (N : ℕ) : Continuous (oddCosSum N) := by
  unfold oddCosSum
  fun_prop

lemma abs_oddCosSum_le (N : ℕ) (x : ℝ) : |oddCosSum N x| ≤ N := by
  unfold oddCosSum
  calc |∑ k ∈ Icc 1 N, cos ((2 * k - 1) * x)| ≤ ∑ k ∈ Icc 1 N, |cos ((2 * (k:ℝ) - 1) * x)| :=
        Finset.abs_sum_le_sum_abs _ _
    _ ≤ ∑ k ∈ Icc 1 N, (1:ℝ) := Finset.sum_le_sum (fun k _ => abs_cos_le_one _)
    _ = N := by simp

lemma hasDerivAt_squareWave (N : ℕ) (x : ℝ) :
    HasDerivAt (squareWavePartialSum N) (4 / π * oddCosSum N x) x := by
  unfold oddCosSum
  have h : ∀ k ∈ Icc 1 N, HasDerivAt (fun y : ℝ => sin ((2 * (k:ℝ) - 1) * y) / (2 * k - 1))
      (cos ((2 * (k:ℝ) - 1) * x)) x := by
    intro k hk
    have hk1 : (1:ℝ) ≤ k := by exact_mod_cast (mem_Icc.mp hk).1
    have hne : (2 * (k:ℝ) - 1) ≠ 0 := by linarith
    have := (((hasDerivAt_id' x).const_mul (2 * (k:ℝ) - 1)).sin).div_const (2 * (k:ℝ) - 1)
    convert this using 1
    field_simp
  have := (HasDerivAt.sum (u := Icc 1 N)
    (A := fun (k : ℕ) (y : ℝ) => sin ((2 * (k:ℝ) - 1) * y) / (2 * k - 1)) h).const_mul (4 / π)
  convert this using 1
  ext y
  simp only [squareWavePartialSum, Finset.sum_apply]

lemma squareWave_pi_sub (N : ℕ) (x : ℝ) :
    squareWavePartialSum N (π - x) = squareWavePartialSum N x := by
  unfold squareWavePartialSum
  congr 1
  apply sum_congr rfl
  intro k hk
  obtain ⟨j, rfl⟩ : ∃ j, k = j + 1 := ⟨k - 1, by have := (mem_Icc.mp hk).1; omega⟩
  push_cast
  rw [show (2 * ((j:ℝ) + 1) - 1) * (π - x) = (π - (2 * ((j:ℝ) + 1) - 1) * x) + (j:ℝ) * (2 * π) by
    ring, sin_add_nat_mul_two_pi, sin_pi_sub]

lemma squareWave_le_peak_half (N : ℕ) (hN : 1 ≤ N) (x : ℝ) (hx0 : 0 < x) (hx : x ≤ π / 2) :
    squareWavePartialSum N x ≤ squareWavePartialSum N (π / (2 * N)) := by
  have hN' : (1:ℝ) ≤ N := by exact_mod_cast hN
  set a := π / (2 * N) with ha_def
  have ha0 : 0 < a := div_pos pi_pos (by linarith)
  have ha2 : a ≤ π / 2 := by
    rw [ha_def]; apply div_le_div_of_nonneg_left pi_pos.le (by norm_num) (by linarith)
  have hNa : 2 * (N:ℝ) * a = π := by rw [ha_def]; field_simp
  rcases le_total x a with hxa | hxa
  · -- increasing part
    have hmono : MonotoneOn (squareWavePartialSum N) (Set.Icc 0 a) := by
      apply monotoneOn_of_hasDerivWithinAt_nonneg (convex_Icc 0 a)
        (fun t _ => (hasDerivAt_squareWave N t).continuousAt.continuousWithinAt)
        (fun t _ => (hasDerivAt_squareWave N t).hasDerivWithinAt)
      intro t ht
      rw [interior_Icc] at ht
      have hs : 0 < sin t := sin_pos_of_pos_of_lt_pi ht.1 (by linarith [ht.2])
      have h2 : 0 ≤ sin (2 * N * t) := by
        apply sin_nonneg_of_nonneg_of_le_pi (mul_nonneg (by positivity) ht.1.le)
        have : 2 * (N:ℝ) * t ≤ 2 * N * a := by
          apply mul_le_mul_of_nonneg_left ht.2.le (by positivity)
        linarith
      have hC : 0 ≤ oddCosSum N t := by
        have := oddCosSum_mul N t
        by_contra hneg
        have hneg := not_le.mp hneg
        nlinarith [mul_neg_of_neg_of_pos hneg (by linarith : (0:ℝ) < 2 * sin t)]
      exact mul_nonneg (by positivity) hC
    exact hmono ⟨hx0.le, hxa⟩ ⟨ha0.le, le_rfl⟩ hxa
  · -- decreasing part, through an auxiliary function
    set Ψ : ℝ → ℝ := fun t => squareWavePartialSum N t + 2 / π * (1 + cos (2 * N * t)) / (2 * N * sin t)
      with hΨ
    have hderiv : ∀ t, sin t ≠ 0 → HasDerivAt Ψ
        (-(2 / π * (1 + cos (2 * N * t)) * cos t / (2 * N * sin t ^ 2))) t := by
      intro t hst
      have h1 : HasDerivAt (fun y : ℝ => 2 * (N:ℝ) * y) (2 * N) t := by
        simpa using (hasDerivAt_id t).const_mul (2 * (N:ℝ))
      have hc : HasDerivAt (fun y => 2 / π * (1 + cos (2 * N * y)))
          (2 / π * (-sin (2 * N * t) * (2 * N))) t := ((h1.cos).const_add 1).const_mul (2 / π)
      have hd : HasDerivAt (fun y => 2 * (N:ℝ) * sin y) (2 * N * cos t) t :=
        (hasDerivAt_sin t).const_mul _
      have hne : 2 * (N:ℝ) * sin t ≠ 0 := by positivity
      have := (hasDerivAt_squareWave N t).add (hc.div hd hne)
      convert this using 1
      have hC := oddCosSum_mul N t
      rw [← hC]
      field_simp
      ring
    have hanti : AntitoneOn Ψ (Set.Icc a (π / 2)) := by
      have hsin : ∀ t ∈ Set.Icc a (π / 2), sin t ≠ 0 := fun t ht =>
        (sin_pos_of_pos_of_lt_pi (by linarith [ht.1]) (by linarith [ht.2, pi_pos])).ne'
      apply antitoneOn_of_hasDerivWithinAt_nonpos (convex_Icc a (π / 2))
        (fun t ht => (hderiv t (hsin t ht)).continuousAt.continuousWithinAt)
        (fun t ht => (hderiv t (hsin t (interior_subset ht))).hasDerivWithinAt)
      intro t ht
      rw [interior_Icc] at ht
      have hc1 : 0 ≤ 1 + cos (2 * N * t) := by linarith [neg_one_le_cos (2 * N * t)]
      have hc2 : 0 ≤ cos t := cos_nonneg_of_mem_Icc ⟨by linarith [ht.1, pi_pos], ht.2.le⟩
      have hs : 0 < sin t := sin_pos_of_pos_of_lt_pi (by linarith [ht.1]) (by linarith [ht.2, pi_pos])
      rw [neg_nonpos]
      apply div_nonneg (mul_nonneg (mul_nonneg (by positivity) hc1) hc2) (by positivity)
    have hsx : 0 < sin x := sin_pos_of_pos_of_lt_pi hx0 (by linarith [pi_pos])
    have h1 : squareWavePartialSum N x ≤ Ψ x := by
      simp only [hΨ]
      have : 0 ≤ 2 / π * (1 + cos (2 * N * x)) / (2 * N * sin x) := by
        apply div_nonneg (mul_nonneg (by positivity) (by linarith [neg_one_le_cos (2 * N * x)]))
          (by positivity)
      linarith
    have h2 : Ψ x ≤ Ψ a := hanti ⟨le_rfl, ha2⟩ ⟨hxa, hx⟩ hxa
    have h3 : Ψ a = squareWavePartialSum N a := by
      simp only [hΨ, hNa, cos_pi]; simp
    linarith

lemma squareWave_le_peak (N : ℕ) (hN : 1 ≤ N) (x : ℝ) (hx : x ∈ Set.Ioo 0 π) :
    squareWavePartialSum N x ≤ squareWavePartialSum N (π / (2 * N)) := by
  rcases le_total x (π / 2) with h | h
  · exact squareWave_le_peak_half N hN x hx.1 h
  · rw [← squareWave_pi_sub N x]
    exact squareWave_le_peak_half N hN (π - x) (by linarith [hx.2]) (by linarith)

lemma squareWave_sSup (N : ℕ) (hN : 1 ≤ N) :
    sSup (squareWavePartialSum N '' Set.Ioo 0 π) = squareWavePartialSum N (π / (2 * N)) := by
  have hN' : (1:ℝ) ≤ N := by exact_mod_cast hN
  have ha0 : 0 < π / (2 * N) := div_pos pi_pos (by linarith)
  have ha : π / (2 * N) < π := by
    rw [div_lt_iff₀ (by positivity)]; nlinarith [pi_pos]
  apply IsGreatest.csSup_eq
  refine ⟨⟨π / (2 * N), ⟨ha0, ha⟩, rfl⟩, ?_⟩
  rintro _ ⟨x, hx, rfl⟩
  exact squareWave_le_peak N hN x hx

lemma squareWave_peak_eq_integral (N : ℕ) (hN : 1 ≤ N) :
    squareWavePartialSum N (π / (2 * N)) =
      ∫ u in (0:ℝ)..π, 4 / π * oddCosSum N (u / (2 * N)) / (2 * N) := by
  have hN' : (1:ℝ) ≤ N := by exact_mod_cast hN
  have h2N : (2 * (N:ℝ)) ≠ 0 := by positivity
  have hftc := intervalIntegral.integral_eq_sub_of_hasDerivAt (a := 0) (b := π / (2 * N))
    (fun t _ => hasDerivAt_squareWave N t)
    ((continuous_const.mul (oddCosSum_continuous N)).intervalIntegrable _ _)
  have h0 : squareWavePartialSum N 0 = 0 := by simp [squareWavePartialSum]
  rw [intervalIntegral.integral_div,
    intervalIntegral.integral_comp_div (fun t => 4 / π * oddCosSum N t) h2N]
  simp only [zero_div, smul_eq_mul]
  rw [hftc, h0, sub_zero]
  field_simp

lemma squareWave_peak_tendsto :
    Tendsto (fun N : ℕ => squareWavePartialSum N (π / (2 * N))) atTop
        (𝓝 (2 / π * ∫ u in (0 : ℝ)..π, sin u / u)) := by
  have hlim := intervalIntegral.tendsto_integral_filter_of_dominated_convergence
    (μ := MeasureTheory.volume) (a := 0) (b := π) (l := atTop)
    (F := fun (N : ℕ) (u : ℝ) => 4 / π * oddCosSum N (u / (2 * N)) / (2 * N))
    (f := fun u => 2 / π * (sin u / u)) (fun _ => 2 / π) ?meas ?bound intervalIntegrable_const ?lim
  · rw [intervalIntegral.integral_const_mul] at hlim
    refine hlim.congr' ?_
    filter_upwards [eventually_ge_atTop 1] with N hN
    exact (squareWave_peak_eq_integral N hN).symm
  · refine Eventually.of_forall (fun N => ?_)
    apply Continuous.aestronglyMeasurable
    have := oddCosSum_continuous N
    fun_prop
  · filter_upwards [eventually_ge_atTop 1] with N hN
    refine MeasureTheory.ae_of_all _ (fun u _ => ?_)
    have hN' : (1:ℝ) ≤ N := by exact_mod_cast hN
    rw [Real.norm_eq_abs, abs_div, abs_mul, abs_of_pos (by positivity : (0:ℝ) < 4 / π),
      abs_of_pos (by positivity : (0:ℝ) < 2 * N), div_le_iff₀ (by positivity)]
    have := abs_oddCosSum_le N (u / (2 * N))
    have h4 : (0:ℝ) < 4 / π := by positivity
    calc 4 / π * |oddCosSum N (u / (2 * N))| ≤ 4 / π * N := by gcongr
      _ = 2 / π * (2 * N) := by ring
  · refine MeasureTheory.ae_of_all _ (fun u hu => ?_)
    rw [Set.uIoc_of_le pi_pos.le] at hu
    have hu0 : 0 < u := hu.1
    have hv : Tendsto (fun N : ℕ => u / (2 * (N:ℝ))) atTop (𝓝 0) :=
      tendsto_const_nhds.div_atTop (Tendsto.const_mul_atTop two_pos tendsto_natCast_atTop_atTop)
    have hs : Tendsto (fun N : ℕ => sinc (u / (2 * (N:ℝ)))) atTop (𝓝 1) := by
      have := (continuous_sinc.tendsto 0).comp hv
      simpa [sinc_zero, Function.comp_def] using this
    have hlim2 : Tendsto (fun N : ℕ => 2 / π * (sin u / (u * sinc (u / (2 * (N:ℝ)))))) atTop
        (𝓝 (2 / π * (sin u / (u * 1)))) :=
      (tendsto_const_nhds.div (tendsto_const_nhds.mul hs) (by simpa using hu0.ne')).const_mul _
    rw [mul_one] at hlim2
    refine hlim2.congr' ?_
    filter_upwards [eventually_ge_atTop 1] with N hN
    have hN' : (1:ℝ) ≤ N := by exact_mod_cast hN
    have hv0 : 0 < u / (2 * N) := by positivity
    have hvpi : u / (2 * N) < π := by
      rw [div_lt_iff₀ (by positivity)]; nlinarith [hu.2]
    have hsv : 0 < sin (u / (2 * N)) := sin_pos_of_pos_of_lt_pi hv0 hvpi
    have hC := oddCosSum_mul N (u / (2 * N))
    have e : 2 * (N:ℝ) * (u / (2 * N)) = u := by field_simp
    rw [e] at hC
    rw [sinc_of_ne_zero hv0.ne']
    have hC' : oddCosSum N (u / (2 * N)) = sin u / (2 * sin (u / (2 * N))) := by
      field_simp; linarith
    rw [hC']
    field_simp
    ring

/-- **Dirichlet's theorem: the series lands on the midpoint.** Let f repeat every 2π and be made
of finitely many smooth pieces per cycle, jumps allowed: there are break points
a_0 < a_1 < ⋯ < a_m = a_0 + 2π, and on each open piece (a_i, a_(i+1)) f agrees with a
continuously differentiable function. Let x be any point where f has a value L approached from
the left and a value R approached from the right. Then the Fourier partial sums at x tend to the
midpoint (L + R)/2. Where f is smooth, L = R = f(x), so the series lands on the function; the
value of f at a jump itself plays no part. -/
theorem fourier_partial_sums_tend_to_midpoint (f : ℝ → ℝ) (hper : Function.Periodic f (2 * π))
    (hpieces : ∃ (m : ℕ) (a : Fin (m + 1) → ℝ), StrictMono a ∧ a (Fin.last m) = a 0 + 2 * π ∧
      ∀ i : Fin m, ∃ g : ℝ → ℝ, ContDiff ℝ 1 g ∧ Set.EqOn f g (Set.Ioo (a i.castSucc) (a i.succ)))
    (x L R : ℝ) (hL : Tendsto f (𝓝[<] x) (𝓝 L)) (hR : Tendsto f (𝓝[>] x) (𝓝 R)) :
    Tendsto (fun n : ℕ => fourierPartialSum f n x) atTop (𝓝 ((L + R) / 2)) := by
  obtain ⟨m, a, ha, hlast, hpc⟩ := hpieces
  have hfi := piecewise_intervalIntegrable f hper ha hlast hpc
  obtain ⟨δR, hδR, gR, hgR, hfR⟩ := right_piece f hper hlast hpc x
  obtain ⟨δL, hδL, gL, hgL, hfL⟩ := left_piece f hper hlast hpc x
  have hRx : R = gR x := by
    have h1 : Tendsto f (𝓝[>] x) (𝓝 (gR x)) := by
      have : Tendsto gR (𝓝[>] x) (𝓝 (gR x)) :=
        hgR.continuous.continuousAt.tendsto.mono_left nhdsWithin_le_nhds
      apply this.congr'
      filter_upwards [Ioo_mem_nhdsGT (by linarith : x < x + δR)] with t ht using (hfR ht).symm
    exact tendsto_nhds_unique hR h1
  have hLx : L = gL x := by
    have h1 : Tendsto f (𝓝[<] x) (𝓝 (gL x)) := by
      have : Tendsto gL (𝓝[<] x) (𝓝 (gL x)) :=
        hgL.continuous.continuousAt.tendsto.mono_left nhdsWithin_le_nhds
      apply this.congr'
      filter_upwards [Ioo_mem_nhdsLT (by linarith : x - δL < x)] with t ht using (hfL ht).symm
    exact tendsto_nhds_unique hL h1
  have hp1 : ∀ b c, IntervalIntegrable (fun u => f (x + u)) MeasureTheory.volume b c := by
    intro b c
    simpa using (hfi (x + b) (x + c)).comp_add_left x
  have hp2 : ∀ b c, IntervalIntegrable (fun u => f (x - u)) MeasureTheory.volume b c := by
    intro b c
    simpa using (hfi (x - b) (x - c)).comp_sub_left x
  set φ : ℝ → ℝ := fun u => (f (x + u) + f (x - u) - (L + R)) / (2 * sin (u / 2)) with hφdef
  -- the key identity
  have key : ∀ n : ℕ, fourierPartialSum f n x - (L + R) / 2 =
      (1 / π) * ∫ u in (0:ℝ)..π, φ u * sin (((n:ℝ) + 1 / 2) * u) := by
    intro n
    have hA : IntervalIntegrable (fun u => (f (x + u) + f (x - u)) * dk n u)
        MeasureTheory.volume 0 π :=
      ((hp1 0 π).add (hp2 0 π)).mul_continuousOn (dk_continuous n).continuousOn
    have hB : IntervalIntegrable (fun u => (L + R) * dk n u) MeasureTheory.volume 0 π :=
      (continuous_const.mul (dk_continuous n)).intervalIntegrable _ _
    have e : ∫ u in (0:ℝ)..π, φ u * sin (((n:ℝ) + 1 / 2) * u) =
        (∫ u in (0:ℝ)..π, (f (x + u) + f (x - u)) * dk n u) - (L + R) * (π / 2) := by
      rw [← dk_integral n, ← intervalIntegral.integral_const_mul,
        ← intervalIntegral.integral_sub hA hB]
      apply intervalIntegral.integral_congr_ae
      refine Eventually.of_forall (fun u hu => ?_)
      rw [Set.uIoc_of_le pi_pos.le] at hu
      have hs : 0 < sin (u / 2) :=
        sin_pos_of_pos_of_lt_pi (by linarith [hu.1]) (by linarith [hu.2, pi_pos])
      rw [← dk_mul_sin n u]
      simp only [hφdef]
      field_simp
    rw [fourierPartialSum_eq_kernel f hper hfi n x, e]
    field_simp
  -- integrability of φ on (0, π]
  set δ := min (min δR δL) 1 with hδ
  have hδ0 : 0 < δ := lt_min (lt_min hδR hδL) one_pos
  have hδ1 : δ ≤ 1 := min_le_right _ _
  have hδR' : δ ≤ δR := le_trans (min_le_left _ _) (min_le_left _ _)
  have hδL' : δ ≤ δL := le_trans (min_le_left _ _) (min_le_right _ _)
  have hdR : Differentiable ℝ gR := hgR.differentiable (by norm_num)
  have hdL : Differentiable ℝ gL := hgL.differentiable (by norm_num)
  set G : ℝ → ℝ := fun u => gR (x + u) + gL (x - u) - (L + R) with hGdef
  have hGd : Differentiable ℝ G := by
    rw [hGdef]; fun_prop
  have hG0 : G 0 = 0 := by simp [hGdef, hRx, hLx]; ring
  set ψ : ℝ → ℝ := fun u => dslope G 0 u / sinc (u / 2) with hψdef
  have hψc : ContinuousOn ψ (Set.Icc 0 δ) := by
    have hd : Continuous (dslope G 0) := continuous_iff_continuousAt.mpr (fun b => by
      by_cases hb : b = 0
      · subst hb; exact continuousAt_dslope_same.mpr (hGd 0)
      · exact (continuousAt_dslope_of_ne hb).mpr hGd.continuous.continuousAt)
    apply ContinuousOn.div hd.continuousOn
      (continuous_sinc.comp (continuous_id.div_const 2)).continuousOn
    intro u hu
    apply (sinc_pos _).ne'
    show |u / 2| < π
    rw [abs_lt]
    constructor <;> linarith [hu.1, hu.2, pi_gt_three]
  have hEq1 : Set.EqOn φ ψ (Set.Ioo 0 δ) := by
    intro u hu
    have hfr : f (x + u) = gR (x + u) := hfR ⟨by linarith [hu.1], by linarith [hu.2]⟩
    have hfl : f (x - u) = gL (x - u) := hfL ⟨by linarith [hu.2], by linarith [hu.1]⟩
    have hs : 0 < sin (u / 2) :=
      sin_pos_of_pos_of_lt_pi (by linarith [hu.1]) (by linarith [hu.2, pi_gt_three])
    have hu0 : u ≠ 0 := hu.1.ne'
    simp only [hφdef, hψdef]
    rw [dslope_of_ne _ hu0, slope_def_field, hG0, sinc_of_ne_zero (by positivity : u / 2 ≠ 0)]
    simp only [hGdef, hfr, hfl]
    field_simp
    ring
  have hI1 : MeasureTheory.IntegrableOn φ (Set.Ioo 0 δ) :=
    ((hψc.integrableOn_Icc).mono_set Set.Ioo_subset_Icc_self).congr_fun hEq1.symm measurableSet_Ioo
  have hI2 : MeasureTheory.IntegrableOn φ (Set.Icc δ π) := by
    have hF : MeasureTheory.IntegrableOn (fun u => f (x + u) + f (x - u) - (L + R))
        (Set.Icc δ π) := by
      rw [integrableOn_Icc_iff_integrableOn_Ioc]
      exact (((hp1 δ π).add (hp2 δ π)).sub intervalIntegrable_const).1
    have hcont : ContinuousOn (fun u => 1 / (2 * sin (u / 2))) (Set.Icc δ π) := by
      apply continuousOn_const.div (by fun_prop)
      intro u hu
      have : 0 < sin (u / 2) :=
        sin_pos_of_pos_of_lt_pi (by linarith [hu.1]) (by linarith [hu.2, pi_pos])
      positivity
    exact (hF.mul_continuousOn hcont isCompact_Icc).congr_fun
      (fun u _ => by simp only [hφdef]; ring) measurableSet_Icc
  have hφ : MeasureTheory.IntegrableOn φ (Set.Ioc 0 π) := by
    apply (hI1.union hI2).mono_set
    intro u hu
    rcases lt_or_ge u δ with h | h
    · exact Or.inl ⟨hu.1, h⟩
    · exact Or.inr ⟨h, hu.2⟩
  have hlim0 : Tendsto (fun n : ℕ => (1 / π) * ∫ u in (0:ℝ)..π, φ u * sin (((n:ℝ) + 1 / 2) * u))
      atTop (𝓝 0) := by
    have h1 : Tendsto (fun n : ℕ => (n:ℝ) + 1 / 2) atTop atTop :=
      tendsto_atTop_add_const_right _ _ tendsto_natCast_atTop_atTop
    have := ((rl_sin φ hφ).comp h1).const_mul (1 / π)
    simpa [Function.comp_def] using this
  have := hlim0.add_const ((L + R) / 2)
  simp only [← key, sub_add_cancel, zero_add] at this
  exact this

/-- **Gibbs: the overshoot beside the jump does not go away.** For the square wave (−1 then +1,
jumping at x = 0), the highest value of the stack of N odd harmonics on (0, π), and its value
at the first peak x = π/(2N), both tend to (2/π) Si(π) = (2/π) ∫_0^π (sin u)/u du as N grows:
a fixed height above 1 (about 9% of the jump 2), whose place moves in towards the jump. -/
theorem square_wave_peak_tends_to_gibbs_limit :
    Tendsto (fun N : ℕ => sSup (squareWavePartialSum N '' Set.Ioo 0 π)) atTop
        (𝓝 (2 / π * ∫ u in (0 : ℝ)..π, sin u / u)) ∧
      Tendsto (fun N : ℕ => squareWavePartialSum N (π / (2 * N))) atTop
        (𝓝 (2 / π * ∫ u in (0 : ℝ)..π, sin u / u)) := by
  refine ⟨?_, squareWave_peak_tendsto⟩
  refine squareWave_peak_tendsto.congr' ?_
  filter_upwards [eventually_ge_atTop 1] with N hN
  exact (squareWave_sSup N hN).symm

/-- **Leibniz's formula, read off the square wave at π/2.** The partial sums of
1 − 1/3 + 1/5 − 1/7 + ⋯ tend to π/4. -/
theorem leibniz_sum_tends_to_pi_div_four :
    Tendsto (fun n : ℕ => ∑ k ∈ range n, (-1 : ℝ) ^ k / (2 * k + 1)) atTop (𝓝 (π / 4)) := by
  exact Real.tendsto_sum_pi_div_four

-- One tone at x = π/2: 4/π × 1.
example : squareWavePartialSum 1 (π / 2) = 4 / π := by
  simp [squareWavePartialSum]; norm_num
-- Two tones at x = π/2: 4/π × (1 − 1/3) = 4/π × 2/3.
example : squareWavePartialSum 2 (π / 2) = 4 / π * (2 / 3) := by
  have h1 : sin (3 * (π / 2)) = -1 := by
    rw [show 3 * (π / 2) = π / 2 + π by ring, sin_add_pi, sin_pi_div_two]
  simp only [squareWavePartialSum, Finset.sum_Icc_succ_top, Nat.reduceLeDiff, Finset.Icc_self,
    Finset.sum_singleton, Nat.cast_one]
  norm_num
  rw [h1]; norm_num
-- Three tones at x = π/2: 4/π × (1 − 1/3 + 1/5) = 4/π × 13/15.
example : squareWavePartialSum 3 (π / 2) = 4 / π * (13 / 15) := by
  have h1 : sin (3 * (π / 2)) = -1 := by
    rw [show 3 * (π / 2) = π / 2 + π by ring, sin_add_pi, sin_pi_div_two]
  have h2 : sin (5 * (π / 2)) = 1 := by
    rw [show 5 * (π / 2) = π / 2 + ((1 : ℕ) : ℝ) * (2 * π) by push_cast; ring,
      sin_add_nat_mul_two_pi, sin_pi_div_two]
  simp only [squareWavePartialSum, Finset.sum_Icc_succ_top, Nat.reduceLeDiff, Finset.Icc_self,
    Finset.sum_singleton, Nat.cast_one]
  norm_num
  rw [h1, h2]; norm_num
-- At the jump every tone is zero: the stack of 50 tones gives 0, the midpoint of −1 and +1.
example : squareWavePartialSum 50 0 = 0 := by simp [squareWavePartialSum]
-- Where the first peak sits for N = 50: π/(2 × 50) = π/100.
example : π / (2 * (50 : ℕ)) = π / 100 := by push_cast; ring

#print axioms fourier_partial_sums_tend_to_midpoint
#print axioms square_wave_peak_tends_to_gibbs_limit
#print axioms leibniz_sum_tends_to_pi_div_four
#print axioms dk_continuous
#print axioms dk_periodic
#print axioms dk_neg
#print axioms dk_mul_sin
#print axioms dk_integral
#print axioms rl_sin
#print axioms exists_piece_Ico
#print axioms exists_piece_Ioc
#print axioms right_piece
#print axioms left_piece
#print axioms piecewise_intervalIntegrable
#print axioms fourierPartialSum_eq_kernel
#print axioms oddCosSum_mul
#print axioms oddCosSum_continuous
#print axioms abs_oddCosSum_le
#print axioms hasDerivAt_squareWave
#print axioms squareWave_pi_sub
#print axioms squareWave_le_peak_half
#print axioms squareWave_le_peak
#print axioms squareWave_sSup
#print axioms squareWave_peak_eq_integral
#print axioms squareWave_peak_tendsto
