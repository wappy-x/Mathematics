-- Bochner's theorem: a continuous function on the line is positive definite exactly when it is the transform of a finite spectrum that is never negative, with Herglotz's version for whole-number steps and Pólya's criterion for even bowls that fall to 0.
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Complex.Order
import Mathlib.Analysis.Convex.Function
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.MeasureTheory.Measure.LevyConvergence
import Mathlib.MeasureTheory.Measure.Prokhorov
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.Convex.Slope
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Function.LocallyIntegrable
import Mathlib.Algebra.Order.Round

open MeasureTheory Complex Filter Topology
open scoped ComplexOrder



theorem pd_sum_integral_nonneg {α : Type*} [MeasurableSpace α] (μ : Measure α) {m : ℕ}
    (f : Fin m → α → ℂ) (c : Fin m → ℂ)
    (hf : ∀ j k, Integrable (fun x => f j x * (starRingEnd ℂ) (f k x)) μ) :
    0 ≤ ∑ j, ∑ k, c j * (starRingEnd ℂ) (c k) * ∫ x, f j x * (starRingEnd ℂ) (f k x) ∂μ := by
  have hi : ∀ j k, Integrable (fun x => (c j * f j x) * (starRingEnd ℂ) (c k * f k x)) μ := by
    intro j k
    refine ((hf j k).const_mul (c j * (starRingEnd ℂ) (c k))).congr (ae_of_all _ fun x => ?_)
    simp only [map_mul]; ring
  have h1 : ∀ j k, c j * (starRingEnd ℂ) (c k) * ∫ x, f j x * (starRingEnd ℂ) (f k x) ∂μ
      = ∫ x, (c j * f j x) * (starRingEnd ℂ) (c k * f k x) ∂μ := by
    intro j k
    rw [← integral_const_mul]
    congr 1; ext x; simp only [map_mul]; ring
  simp_rw [h1]
  have h2 : ∀ j, ∑ k, ∫ x, (c j * f j x) * (starRingEnd ℂ) (c k * f k x) ∂μ
      = ∫ x, ∑ k, (c j * f j x) * (starRingEnd ℂ) (c k * f k x) ∂μ := by
    intro j
    rw [integral_finsetSum]
    intro k _
    exact hi j k
  simp_rw [h2]
  rw [← integral_finsetSum _ (fun j _ => integrable_finsetSum _ fun k _ => hi j k)]
  have h3 : ∀ x, ∑ j, ∑ k, (c j * f j x) * (starRingEnd ℂ) (c k * f k x)
      = ((Complex.normSq (∑ j, c j * f j x) : ℝ) : ℂ) := by
    intro x
    rw [Complex.normSq_eq_conj_mul_self, map_sum, Finset.sum_mul_sum, Finset.sum_comm]
    exact Finset.sum_congr rfl fun _ _ => Finset.sum_congr rfl fun _ _ => mul_comm _ _
  simp_rw [h3]
  rw [integral_complex_ofReal]
  exact Complex.zero_le_real.mpr (integral_nonneg fun x => Complex.normSq_nonneg _)

#print axioms pd_sum_integral_nonneg

theorem pd_triangle {m : ℕ} (τ : Fin m → ℝ) (c : Fin m → ℂ) (s : ℝ) :
    0 ≤ ∑ j, ∑ k, c j * (starRingEnd ℂ) (c k) * ((max (s - |τ j - τ k|) 0 : ℝ) : ℂ) := by
  let f : Fin m → ℝ → ℂ := fun j => (Set.Icc (τ j) (τ j + s)).indicator (fun _ => (1 : ℂ))
  have hprod : ∀ j k, (fun x => f j x * (starRingEnd ℂ) (f k x))
      = (Set.Icc (τ j) (τ j + s) ∩ Set.Icc (τ k) (τ k + s)).indicator (fun _ => (1 : ℂ)) := by
    intro j k; ext x
    simp only [f, Set.indicator, Set.mem_inter_iff]
    split_ifs <;> simp_all
  have hint : ∀ j k, ∫ x, f j x * (starRingEnd ℂ) (f k x) = ((max (s - |τ j - τ k|) 0 : ℝ) : ℂ) := by
    intro j k
    rw [hprod, integral_indicator_const _ (measurableSet_Icc.inter measurableSet_Icc),
      Set.Icc_inter_Icc, Real.volume_real_Icc]
    simp only [real_smul, mul_one]
    congr 2
    rcases le_total (τ j) (τ k) with h | h
    · rw [max_eq_right h, min_eq_left (by linarith), abs_of_nonpos (by linarith)]; ring
    · rw [max_eq_left h, min_eq_right (by linarith), abs_of_nonneg (by linarith)]; ring
  have := pd_sum_integral_nonneg volume f c (fun j k => by
    rw [hprod]
    exact (integrableOn_const (by rw [Set.Icc_inter_Icc]; exact measure_Icc_lt_top.ne)).integrable_indicator
      (measurableSet_Icc.inter measurableSet_Icc))
  simpa only [hint] using this

#print axioms pd_triangle

theorem polya_rep : ∀ (n : ℕ) (φ : ℝ → ℝ) (D : Finset ℝ) (hD : D.Nonempty), D.card = n + 1 →
    (∀ d ∈ D, 0 ≤ d) → ConvexOn ℝ (Set.Icc 0 (D.max' hD)) φ →
    AntitoneOn φ (Set.Icc 0 (D.max' hD)) →
    ∃ (k : ℕ) (a s : Fin k → ℝ), (∀ i, 0 ≤ a i) ∧ (∀ i, s i ≤ D.max' hD) ∧
      ∀ d ∈ D, φ d = φ (D.max' hD) + ∑ i, a i * max (s i - d) 0 := by
  intro n
  induction n with
  | zero =>
    intro φ D hD hcard _ _ _
    obtain ⟨x, rfl⟩ := Finset.card_eq_one.1 hcard
    refine ⟨0, Fin.elim0, Fin.elim0, fun i => i.elim0, fun i => i.elim0, ?_⟩
    intro d hd
    rw [Finset.mem_singleton.1 hd]
    simp
  | succ n ih =>
    intro φ D hD hcard hnn hconv hanti
    set M := D.max' hD with hM
    have hMD : M ∈ D := D.max'_mem hD
    set D' := D.erase M with hD'
    have hcard' : D'.card = n + 1 := by rw [Finset.card_erase_of_mem hMD, hcard]; rfl
    have hD'ne : D'.Nonempty := by
      rw [← Finset.card_pos, hcard']; omega
    set M' := D'.max' hD'ne with hM'
    have hM'D' : M' ∈ D' := D'.max'_mem hD'ne
    have hM'lt : M' < M := by
      have h1 := Finset.mem_erase.1 hM'D'
      exact lt_of_le_of_ne (D.le_max' _ h1.2) h1.1
    have hM'nn : 0 ≤ M' := hnn _ (Finset.mem_erase.1 hM'D').2
    have hsub : Set.Icc 0 M' ⊆ Set.Icc 0 M := Set.Icc_subset_Icc le_rfl hM'lt.le
    have hM'mem : M' ∈ Set.Icc 0 M := ⟨hM'nn, hM'lt.le⟩
    have hMmem : M ∈ Set.Icc 0 M := ⟨hM'nn.trans hM'lt.le, le_rfl⟩
    set σ := (φ M' - φ M) / (M - M') with hσ
    have hpos : 0 < M - M' := by linarith
    have hσM : σ * (M - M') = φ M' - φ M := by rw [hσ]; field_simp
    have hσnn : 0 ≤ σ := div_nonneg (by linarith [hanti hM'mem hMmem hM'lt.le]) hpos.le
    let ψ : ℝ → ℝ := fun x => φ x - φ M - σ * (M - x)
    have hψconv : ConvexOn ℝ (Set.Icc 0 (D'.max' hD'ne)) ψ := by
      refine ⟨convex_Icc _ _, fun x hx y hy a b ha hb hab => ?_⟩
      have := (hconv.subset hsub (convex_Icc _ _)).2 hx hy ha hb hab
      simp only [smul_eq_mul, ψ] at this ⊢
      have hb' : b = 1 - a := by linarith
      subst hb'
      nlinarith
    have hψanti : AntitoneOn ψ (Set.Icc 0 (D'.max' hD'ne)) := by
      intro x hx y hy hxy
      simp only [ψ]
      rcases eq_or_lt_of_le hxy with rfl | hxy'
      · exact le_rfl
      have hxM : x ∈ Set.Icc 0 M := hsub hx
      have hyM : y ∈ Set.Icc 0 M := hsub hy
      have hyM' : y ≤ M' := hy.2
      have hxM' : x < M' := lt_of_lt_of_le hxy' hyM'
      have k1 := hconv.secant_mono_aux1 hxM hMmem hxy' (lt_of_le_of_lt hyM' hM'lt)
      have k2 := hconv.secant_mono_aux1 hxM hMmem hxM' hM'lt
      have hMx : 0 < M - x := by linarith
      have hyx : 0 < y - x := by linarith
      have hprod : (φ y - φ x + σ * (y - x)) * ((M - x) * (M - M')) ≤ 0 := by
        have e1 : σ * (y - x) * ((M - x) * (M - M')) = (φ M' - φ M) * (y - x) * (M - x) := by
          rw [← hσM]; ring
        have q1 := mul_le_mul_of_nonneg_right k1 hpos.le
        have q2 := mul_le_mul_of_nonneg_left k2 hyx.le
        nlinarith
      have hpp : 0 < (M - x) * (M - M') := mul_pos hMx hpos
      have : φ y - φ x + σ * (y - x) ≤ 0 := by
        by_contra hc
        have hc := not_le.1 hc
        linarith [mul_pos hc hpp]
      linarith
    obtain ⟨k, a, s, ha, hs, hrep⟩ := ih ψ D' hD'ne hcard' (fun d hd => hnn d (Finset.mem_erase.1 hd).2)
      hψconv hψanti
    have hψM' : ψ M' = 0 := by simp only [ψ]; linarith
    refine ⟨k + 1, Fin.cons σ a, Fin.cons M s, ?_, ?_, ?_⟩
    · intro i; refine Fin.cases hσnn (fun i => ha i) i
    · intro i; refine Fin.cases le_rfl (fun i => (hs i).trans hM'lt.le) i
    · intro d hd
      rw [Fin.sum_univ_succ]
      simp only [Fin.cons_zero, Fin.cons_succ]
      by_cases hdM : d = M
      · subst hdM
        have : ∑ i, a i * max (s i - M) 0 = 0 :=
          Finset.sum_eq_zero fun i _ => by
            rw [max_eq_right (by linarith [hs i]), mul_zero]
        rw [this]; simp
      · have hdD' : d ∈ D' := Finset.mem_erase.2 ⟨hdM, hd⟩
        have hdle : d ≤ M' := D'.le_max' _ hdD'
        have := hrep d hdD'
        rw [hψM', zero_add] at this
        rw [max_eq_left (by linarith), ← this]
        simp only [ψ]; ring

#print axioms polya_rep

theorem convexOn_Ici_of_Ioi (g : ℝ → ℝ) (hcont : Continuous g) (hconv : ConvexOn ℝ (Set.Ioi 0) g) :
    ConvexOn ℝ (Set.Ici 0) g := by
  refine ⟨convex_Ici _, fun x hx y hy a b ha hb hab => ?_⟩
  simp only [smul_eq_mul] at *
  have hsh : ∀ z : ℝ, Tendsto (fun ε => g (z + ε)) (𝓝[>] 0) (𝓝 (g z)) := by
    intro z
    have hc' : Continuous (fun ε : ℝ => g (z + ε)) := hcont.comp (continuous_const.add continuous_id)
    have := hc'.tendsto (0 : ℝ)
    simp only [add_zero] at this
    exact this.mono_left nhdsWithin_le_nhds
  refine le_of_tendsto_of_tendsto (hsh (a * x + b * y))
    (((hsh x).const_mul a).add ((hsh y).const_mul b)) ?_
  filter_upwards [self_mem_nhdsWithin] with ε hε
  have hε' : (0 : ℝ) < ε := hε
  have hx' : x + ε ∈ Set.Ioi (0 : ℝ) := by simp only [Set.mem_Ici, Set.mem_Ioi] at *; linarith
  have hy' : y + ε ∈ Set.Ioi (0 : ℝ) := by simp only [Set.mem_Ici, Set.mem_Ioi] at *; linarith
  have := hconv.2 hx' hy' ha hb hab
  simp only [smul_eq_mul] at this
  have e : a * (x + ε) + b * (y + ε) = a * x + b * y + ε := by
    have : a * ε + b * ε = ε := by rw [← add_mul, hab, one_mul]
    linarith
  rw [e] at this
  exact this

#print axioms convexOn_Ici_of_Ioi

theorem antitoneOn_Ici_of_convex_tendsto (g : ℝ → ℝ) (hconv : ConvexOn ℝ (Set.Ici 0) g)
    (hlim : Tendsto g atTop (𝓝 0)) : AntitoneOn g (Set.Ici 0) := by
  intro x hx y hy hxy
  by_contra hc
  have hc := not_le.1 hc
  have hxy' : x < y := lt_of_le_of_ne hxy (by rintro rfl; exact lt_irrefl _ hc)
  set δ := (g y - g x) / (y - x) with hδ
  have hδpos : 0 < δ := div_pos (by linarith) (by linarith)
  have hlow : ∀ z, y < z → g y + (z - y) * δ ≤ g z := by
    intro z hz
    have hz' : z ∈ Set.Ici (0 : ℝ) := by simp only [Set.mem_Ici] at *; linarith
    have k := hconv.secant_mono_aux1 hx hz' hxy' hz
    have hyx : 0 < y - x := by linarith
    have : (z - y) * δ * (y - x) = (z - y) * (g y - g x) := by rw [hδ]; field_simp
    nlinarith
  have htop : Tendsto (fun z => g y + (z - y) * δ) atTop atTop := by
    apply tendsto_atTop_add_const_left
    exact (tendsto_atTop_add_const_right _ _ tendsto_id).atTop_mul_const hδpos
  have : Tendsto g atTop atTop :=
    tendsto_atTop_mono' _ (eventually_atTop.2 ⟨y + 1, fun z hz => hlow z (by linarith)⟩) htop
  exact not_tendsto_atTop_of_tendsto_nhds hlim this

#print axioms antitoneOn_Ici_of_convex_tendsto

theorem integral_exp_int_mul (m : ℤ) :
    ∫ θ in (-Real.pi)..Real.pi, exp (m * θ * I) = if m = 0 then 2 * Real.pi else 0 := by
  split_ifs with hm
  · subst hm; simp; ring
  · have hc : (m : ℂ) * I ≠ 0 := mul_ne_zero (by exact_mod_cast hm) I_ne_zero
    have e : ∀ θ : ℝ, exp (m * θ * I) = exp ((m * I) * θ) := fun θ => by ring_nf
    simp_rw [e]
    rw [integral_exp_mul_complex hc]
    have h2 : exp (m * I * Real.pi) = exp (m * I * ((-Real.pi : ℝ) : ℂ)) := by
      have := exp_int_mul_two_pi_mul_I m
      rw [show (m : ℂ) * I * Real.pi = m * I * ((-Real.pi : ℝ) : ℂ) + m * (2 * Real.pi * I) by
        push_cast; ring, exp_add, this, mul_one]
    rw [h2, sub_self, zero_div, Complex.ofReal_zero]

#print axioms integral_exp_int_mul

theorem count_row (N : ℕ) : ∀ k : ℤ,
    ∑ a ∈ Finset.range N, (if (a : ℤ) - N = k then (1 : ℤ) else 0) =
      if -(N : ℤ) ≤ k ∧ k < 0 then 1 else 0 := by
  induction N with
  | zero => intro k; simp
  | succ N ih =>
    intro k
    rw [Finset.sum_range_succ]
    have : ∀ a : ℕ, ((a : ℤ) - ((N + 1 : ℕ) : ℤ) = k) ↔ ((a : ℤ) - N = k + 1) := fun a => by
      push_cast; omega
    simp_rw [this, ih (k + 1)]
    split_ifs <;> omega

#print axioms count_row

theorem count_pairs (N : ℕ) : ∀ k : ℤ,
    ∑ a ∈ Finset.range N, ∑ b ∈ Finset.range N, (if (a : ℤ) - b = k then (1 : ℤ) else 0) =
      max ((N : ℤ) - |k|) 0 := by
  induction N with
  | zero => intro k; simp
  | succ N ih =>
    intro k
    rw [Finset.sum_range_succ]
    simp_rw [Finset.sum_range_succ]
    rw [Finset.sum_add_distrib, ih k]
    have h1 := count_row N k
    have h2 : ∑ b ∈ Finset.range N, (if (N : ℤ) - b = k then (1 : ℤ) else 0) =
        if -(N : ℤ) ≤ -k ∧ -k < 0 then 1 else 0 := by
      rw [← count_row N (-k)]
      refine Finset.sum_congr rfl fun b _ => ?_
      have : ((N : ℤ) - b = k) ↔ ((b : ℤ) - N = -k) := by omega
      simp only [this]
    rw [h1, h2]
    simp only [sub_self]
    push_cast
    rcases abs_cases k with ⟨hk, _⟩ | ⟨hk, _⟩ <;> rw [hk] <;> split_ifs <;> omega

#print axioms count_pairs

noncomputable def fejerSum (r : ℤ → ℂ) (N : ℕ) (θ : ℝ) : ℂ :=
  ∑ a : Fin N, ∑ b : Fin N, r ((a : ℤ) - (b : ℤ)) * exp (-(((a : ℤ) - (b : ℤ) : ℤ) : ℂ) * θ * I)

theorem fejerSum_nonneg (r : ℤ → ℂ) (hpd : ∀ (m : ℕ) (n : Fin m → ℤ) (c : Fin m → ℂ),
    0 ≤ ∑ j, ∑ k, c j * (starRingEnd ℂ) (c k) * r (n j - n k)) (N : ℕ) (θ : ℝ) :
    0 ≤ fejerSum r N θ := by
  have := hpd N (fun a => (a : ℤ)) (fun a => exp (-((a : ℤ) : ℂ) * θ * I))
  unfold fejerSum
  refine this.trans_eq (Finset.sum_congr rfl fun a _ => Finset.sum_congr rfl fun b _ => ?_)
  simp only [← exp_conj, map_mul, map_neg, conj_ofReal, conj_I, map_intCast]
  rw [mul_comm, ← exp_add]
  congr 2
  push_cast
  ring

#print axioms fejerSum_nonneg

theorem fejerSum_continuous (r : ℤ → ℂ) (N : ℕ) : Continuous (fejerSum r N) := by
  unfold fejerSum; fun_prop

#print axioms fejerSum_continuous

theorem fejer_integral (r : ℤ → ℂ) (N : ℕ) (k : ℤ) :
    ∫ θ in (-Real.pi)..Real.pi, exp (k * θ * I) * fejerSum r N θ =
      2 * Real.pi * r k * ((max ((N : ℤ) - |k|) 0 : ℤ) : ℂ) := by
  unfold fejerSum
  simp_rw [Finset.mul_sum]
  rw [intervalIntegral.integral_finsetSum (fun a _ => by
    apply Continuous.intervalIntegrable; fun_prop)]
  have hterm : ∀ a b : Fin N, ∫ θ in (-Real.pi)..Real.pi,
      exp (k * θ * I) * (r ((a : ℤ) - (b : ℤ)) * exp (-(((a : ℤ) - (b : ℤ) : ℤ) : ℂ) * θ * I)) =
      if (a : ℤ) - (b : ℤ) = k then 2 * Real.pi * r k else 0 := by
    intro a b
    have e : ∀ θ : ℝ, exp (k * θ * I) * (r ((a : ℤ) - (b : ℤ)) *
        exp (-(((a : ℤ) - (b : ℤ) : ℤ) : ℂ) * θ * I)) =
        r ((a : ℤ) - (b : ℤ)) * exp (((k - ((a : ℤ) - (b : ℤ)) : ℤ) : ℂ) * θ * I) := by
      intro θ
      rw [mul_left_comm, ← exp_add]
      congr 2
      push_cast; ring
    simp_rw [e]
    rw [intervalIntegral.integral_const_mul, integral_exp_int_mul]
    split_ifs with h1 h2 h2
    · rw [h2]; push_cast; ring
    · omega
    · omega
    · simp
  have hinner : ∀ a : Fin N, ∫ θ in (-Real.pi)..Real.pi, ∑ b : Fin N,
      exp (k * θ * I) * (r ((a : ℤ) - (b : ℤ)) * exp (-(((a : ℤ) - (b : ℤ) : ℤ) : ℂ) * θ * I)) =
      ∑ b : Fin N, ∫ θ in (-Real.pi)..Real.pi,
      exp (k * θ * I) * (r ((a : ℤ) - (b : ℤ)) * exp (-(((a : ℤ) - (b : ℤ) : ℤ) : ℂ) * θ * I)) :=
    fun a => intervalIntegral.integral_finsetSum (fun b _ => by
      apply Continuous.intervalIntegrable; fun_prop)
  simp_rw [hinner, hterm]
  have hc := count_pairs N k
  have : ∀ a b : Fin N, (if (a : ℤ) - (b : ℤ) = k then 2 * Real.pi * r k else 0) =
      2 * Real.pi * r k * ((if ((a : ℕ) : ℤ) - ((b : ℕ) : ℤ) = k then (1 : ℤ) else 0 : ℤ) : ℂ) := by
    intro a b; split_ifs <;> simp
  simp_rw [this, ← Finset.mul_sum]
  congr 1
  rw [← hc]
  push_cast
  rw [Fin.sum_univ_eq_sum_range (fun a => ∑ b : Fin N,
    (if ((a : ℕ) : ℤ) - ((b : ℕ) : ℤ) = k then (1 : ℂ) else 0)) N]
  refine Finset.sum_congr rfl fun a _ => ?_
  exact Fin.sum_univ_eq_sum_range (fun b => (if ((a : ℕ) : ℤ) - ((b : ℕ) : ℤ) = k then (1 : ℂ) else 0)) N

#print axioms fejer_integral

theorem exists_limit_of_tight (μ : ℕ → Measure ℝ) [hμ : ∀ n, IsProbabilityMeasure (μ n)]
    (htight : IsTightMeasureSet (Set.range μ)) :
    ∃ ν : Measure ℝ, IsProbabilityMeasure ν ∧ ∀ (f : BoundedContinuousFunction ℝ ℂ) (L : ℂ),
      Tendsto (fun n => ∫ x, f x ∂(μ n)) atTop (𝓝 L) → ∫ x, f x ∂ν = L := by
  let P : ℕ → ProbabilityMeasure ℝ := fun n => ⟨μ n, hμ n⟩
  have hc : IsCompact (closure (Set.range P)) := by
    apply isCompact_closure_of_isTightMeasureSet
    convert htight using 1
    ext m
    constructor
    · rintro ⟨_, ⟨n, rfl⟩, rfl⟩; exact ⟨n, rfl⟩
    · rintro ⟨n, rfl⟩; exact ⟨P n, ⟨n, rfl⟩, rfl⟩
  let U : Ultrafilter ℕ := Ultrafilter.of atTop
  obtain ⟨ν, -, hν⟩ := hc.ultrafilter_le_nhds (U.map P)
    (.trans (by simp) (monotone_principal subset_closure))
  refine ⟨ν, inferInstance, fun f L hL => ?_⟩
  have hν' : Tendsto P U (𝓝 ν) := hν
  rw [ProbabilityMeasure.tendsto_iff_forall_integral_rclike_tendsto ℂ] at hν'
  exact tendsto_nhds_unique (hν' f) (hL.mono_left (Ultrafilter.of_le _))

#print axioms exists_limit_of_tight

theorem norm_exp_mul_mul_I (a b : ℝ) : ‖exp (a * b * I)‖ = 1 := by
  rw [← ofReal_mul]; exact norm_exp_ofReal_mul_I _

#print axioms norm_exp_mul_mul_I

noncomputable def expBCF (t : ℝ) : BoundedContinuousFunction ℝ ℂ :=
  BoundedContinuousFunction.mkOfBound ⟨fun x => exp (t * x * I), by fun_prop⟩ 2 (fun x y => by
    calc dist _ _ ≤ ‖exp (t * x * I)‖ + ‖exp (t * y * I)‖ := dist_le_norm_add_norm _ _
      _ = 2 := by rw [norm_exp_mul_mul_I, norm_exp_mul_mul_I]; norm_num)

theorem expBCF_apply (t x : ℝ) : expBCF t x = exp (t * x * I) := rfl

#print axioms expBCF_apply

noncomputable def cutFun (x : ℝ) : ℝ := min 1 (max 0 (|x| - Real.pi))

theorem cutFun_mem (x : ℝ) : 0 ≤ cutFun x ∧ cutFun x ≤ 1 :=
  ⟨le_min zero_le_one (le_max_left _ _), min_le_left _ _⟩

#print axioms cutFun_mem

theorem cutFun_eq_zero_iff (x : ℝ) : cutFun x = 0 ↔ x ∈ Set.Icc (-Real.pi) Real.pi := by
  unfold cutFun
  rw [Set.mem_Icc, ← abs_le]
  constructor
  · intro h
    by_contra hc
    have hc := not_le.1 hc
    have : min 1 (max 0 (|x| - Real.pi)) > 0 :=
      lt_min zero_lt_one (lt_max_of_lt_right (by linarith))
    linarith
  · intro h
    rw [max_eq_left (by linarith), min_eq_right zero_le_one]

#print axioms cutFun_eq_zero_iff

noncomputable def cutBCF : BoundedContinuousFunction ℝ ℂ :=
  BoundedContinuousFunction.mkOfBound ⟨fun x => ((cutFun x : ℝ) : ℂ), by unfold cutFun; fun_prop⟩ 2
    (fun x y => by
      calc dist _ _ ≤ ‖((cutFun x : ℝ) : ℂ)‖ + ‖((cutFun y : ℝ) : ℂ)‖ := dist_le_norm_add_norm _ _
        _ ≤ 1 + 1 := by
          gcongr <;> rw [Complex.norm_real, Real.norm_eq_abs, abs_le] <;>
            constructor <;> linarith [cutFun_mem x, cutFun_mem y]
        _ = 2 := by norm_num)

theorem cutBCF_apply (x : ℝ) : cutBCF x = ((cutFun x : ℝ) : ℂ) := rfl

#print axioms cutBCF_apply

/-- integral of the cut function vanishes iff measure lives on Icc -/

theorem integral_cut_eq_zero_of_support (μ : Measure ℝ) (h : μ (Set.Icc (-Real.pi) Real.pi)ᶜ = 0) :
    ∫ x, cutBCF x ∂μ = 0 := by
  apply integral_eq_zero_of_ae
  rw [Filter.EventuallyEq, ae_iff]
  refine measure_mono_null (fun x hx => ?_) h
  simp only [Set.mem_ofPred_eq, cutBCF_apply, Pi.zero_apply, ofReal_eq_zero] at hx
  exact fun h' => hx ((cutFun_eq_zero_iff x).2 h')

#print axioms integral_cut_eq_zero_of_support

theorem support_of_integral_cut_eq_zero (μ : Measure ℝ) [IsFiniteMeasure μ]
    (h : ∫ x, cutBCF x ∂μ = 0) : μ (Set.Icc (-Real.pi) Real.pi)ᶜ = 0 := by
  simp only [cutBCF_apply, integral_complex_ofReal, ofReal_eq_zero] at h
  have hint : Integrable cutFun μ := by
    refine Integrable.of_bound (Continuous.aestronglyMeasurable (by unfold cutFun; fun_prop)) 1
      (ae_of_all _ fun x => ?_)
    rw [Real.norm_eq_abs, abs_le]; constructor <;> linarith [cutFun_mem x]
  have := (integral_eq_zero_iff_of_nonneg (fun x => (cutFun_mem x).1) hint).1 h
  rw [Filter.EventuallyEq, ae_iff] at this
  refine measure_mono_null (fun x hx => ?_) this
  simp only [Set.mem_ofPred_eq, Pi.zero_apply]
  exact fun h' => hx ((cutFun_eq_zero_iff x).1 h')

#print axioms support_of_integral_cut_eq_zero

noncomputable def fejerDens (r : ℤ → ℂ) (N : ℕ) (θ : ℝ) : ℝ :=
  (fejerSum r N θ).re / (2 * Real.pi * N)

noncomputable def fejerMeasure (r : ℤ → ℂ) (N : ℕ) : Measure ℝ :=
  (volume.restrict (Set.Ioc (-Real.pi) Real.pi)).withDensity
    (fun θ => ((fejerDens r N θ).toNNReal : ENNReal))

theorem fejerDens_continuous (r : ℤ → ℂ) (N : ℕ) : Continuous (fejerDens r N) := by
  unfold fejerDens
  exact (continuous_re.comp (fejerSum_continuous r N)).div_const _

#print axioms fejerDens_continuous

theorem fejerMeasure_finite (r : ℤ → ℂ) (N : ℕ) : IsFiniteMeasure (fejerMeasure r N) := by
  have h := (Continuous.integrableOn_Ioc (μ := volume) (a := -Real.pi) (b := Real.pi)
    (fejerDens_continuous r N)).2
  exact isFiniteMeasure_withDensity_ofReal h

#print axioms fejerMeasure_finite

theorem fejerMeasure_support (r : ℤ → ℂ) (N : ℕ) :
    fejerMeasure r N (Set.Icc (-Real.pi) Real.pi)ᶜ = 0 := by
  apply withDensity_absolutelyContinuous
  rw [Measure.restrict_apply (measurableSet_Icc.compl)]
  convert measure_empty (μ := volume)
  ext x
  simp only [Set.mem_empty_iff_false, iff_false]
  rintro ⟨h1, h2⟩
  exact h1 ⟨h2.1.le, h2.2⟩

#print axioms fejerMeasure_support

theorem fejerMeasure_integral (r : ℤ → ℂ) (hpd : ∀ (m : ℕ) (n : Fin m → ℤ) (c : Fin m → ℂ),
    0 ≤ ∑ j, ∑ k, c j * (starRingEnd ℂ) (c k) * r (n j - n k)) (N : ℕ) (hN : 0 < N) (k : ℤ) :
    ∫ θ, exp (k * θ * I) ∂(fejerMeasure r N) =
      r k * (((max ((N : ℤ) - |k|) 0 : ℤ) : ℂ) / N) := by
  unfold fejerMeasure
  rw [integral_withDensity_eq_integral_smul (by
    exact (fejerDens_continuous r N).measurable.real_toNNReal)]
  have hreal : ∀ θ, fejerSum r N θ = ((fejerSum r N θ).re : ℂ) := fun θ =>
    Complex.ext rfl (by simp [← (Complex.nonneg_iff.1 (fejerSum_nonneg r hpd N θ)).2])
  have hpt : ∀ θ, (fejerDens r N θ).toNNReal • exp (k * θ * I) =
      (2 * Real.pi * N : ℂ)⁻¹ * (exp (k * θ * I) * fejerSum r N θ) := by
    intro θ
    have hnn : 0 ≤ fejerDens r N θ := div_nonneg
      (Complex.nonneg_iff.1 (fejerSum_nonneg r hpd N θ)).1 (by positivity)
    rw [NNReal.smul_def, Real.coe_toNNReal _ hnn, Complex.real_smul, hreal θ]
    unfold fejerDens
    push_cast
    ring
  simp_rw [hpt]
  rw [integral_const_mul, ← intervalIntegral.integral_of_le (by linarith [Real.pi_pos]),
    fejer_integral]
  have : (N : ℂ) ≠ 0 := by exact_mod_cast hN.ne'
  have hpi : (Real.pi : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
  field_simp

#print axioms fejerMeasure_integral

theorem fejerMeasure_real_univ (r : ℤ → ℂ) (hpd : ∀ (m : ℕ) (n : Fin m → ℤ) (c : Fin m → ℂ),
    0 ≤ ∑ j, ∑ k, c j * (starRingEnd ℂ) (c k) * r (n j - n k)) (N : ℕ) (hN : 0 < N) :
    ((fejerMeasure r N).real Set.univ : ℂ) = r 0 := by
  have := fejerMeasure_integral r hpd N hN 0
  simp only [Int.cast_zero, zero_mul, exp_zero, integral_const, abs_zero,
    sub_zero] at this
  rw [Complex.real_smul, mul_one] at this
  rw [this]
  have : (N : ℂ) ≠ 0 := by exact_mod_cast hN.ne'
  rw [max_eq_left (by positivity)]
  push_cast
  field_simp

#print axioms fejerMeasure_real_univ

theorem exp_int_mul_pi (k : ℤ) :
    exp (k * (Real.pi : ℝ) * I) = exp (k * ((-Real.pi : ℝ) : ℂ) * I) := by
  rw [show (k : ℂ) * (Real.pi : ℝ) * I = k * ((-Real.pi : ℝ) : ℂ) * I + k * (2 * Real.pi * I) by
    push_cast; ring, exp_add, exp_int_mul_two_pi_mul_I, mul_one]

#print axioms exp_int_mul_pi

noncomputable def wrapPi (x : ℝ) : ℝ := if x = -Real.pi then Real.pi else x

theorem wrapPi_measurable : Measurable wrapPi :=
  Measurable.ite (measurableSet_singleton (-Real.pi)) measurable_const measurable_id

#print axioms wrapPi_measurable

theorem exp_wrapPi (k : ℤ) (x : ℝ) : exp (k * (wrapPi x : ℝ) * I) = exp (k * x * I) := by
  unfold wrapPi
  split_ifs with h
  · rw [h, exp_int_mul_pi]
  · rfl

#print axioms exp_wrapPi

theorem wrapPi_preimage : wrapPi ⁻¹' (Set.Ioc (-Real.pi) Real.pi)ᶜ ⊆ (Set.Icc (-Real.pi) Real.pi)ᶜ := by
  intro x hx hx'
  apply hx
  unfold wrapPi
  split_ifs with h
  · exact ⟨by linarith [Real.pi_pos], le_rfl⟩
  · exact ⟨lt_of_le_of_ne hx'.1 (Ne.symm h), hx'.2⟩

#print axioms wrapPi_preimage

theorem frac_tendsto_one (k : ℤ) :
    Tendsto (fun N : ℕ => ((((max (((N + 1 : ℕ) : ℤ) - |k|) 0 : ℤ) : ℝ) / ((N + 1 : ℕ) : ℝ)) : ℂ))
      atTop (𝓝 1) := by
  have h1 : Tendsto (fun N : ℕ => 1 - (|k| : ℝ) / ((N + 1 : ℕ) : ℝ)) atTop (𝓝 1) := by
    have := (tendsto_const_div_atTop_nhds_zero_nat (|k| : ℝ)).comp (tendsto_add_atTop_nat 1)
    simpa using tendsto_const_nhds.sub this
  have h2 : Tendsto (fun N : ℕ => (((max (((N + 1 : ℕ) : ℤ) - |k|) 0 : ℤ) : ℝ) / ((N + 1 : ℕ) : ℝ)))
      atTop (𝓝 1) := by
    refine h1.congr' (eventually_atTop.2 ⟨k.natAbs, fun N hN => ?_⟩)
    have hk : |k| ≤ ((N + 1 : ℕ) : ℤ) := by
      have := Int.abs_eq_natAbs k
      push_cast; omega
    dsimp only
    rw [max_eq_left (by linarith)]
    have : ((N + 1 : ℕ) : ℝ) ≠ 0 := by positivity
    push_cast
    field_simp
  have := (continuous_ofReal.tendsto 1).comp h2
  rw [ofReal_one] at this
  exact this.congr fun N => by simp only [Function.comp_apply, Complex.ofReal_div]

#print axioms frac_tendsto_one

theorem herglotz_forward (r : ℤ → ℂ) (hpd : ∀ (m : ℕ) (n : Fin m → ℤ) (c : Fin m → ℂ),
    0 ≤ ∑ j, ∑ k, c j * (starRingEnd ℂ) (c k) * r (n j - n k)) :
    ∃ μ : Measure ℝ, IsFiniteMeasure μ ∧ μ (Set.Ioc (-Real.pi) Real.pi)ᶜ = 0 ∧
        ∀ k : ℤ, r k = ∫ θ, exp (k * θ * I) ∂μ := by
  have hF := fun N => fejerMeasure_finite r N
  set r0 := (r 0).re with hr0def
  have huniv : ∀ N : ℕ, (fejerMeasure r (N + 1)).real Set.univ = r0 := by
    intro N
    have := fejerMeasure_real_univ r hpd (N + 1) N.succ_pos
    rw [hr0def, ← this, ofReal_re]
  have hr0nn : 0 ≤ r0 := by rw [← huniv 0]; exact measureReal_nonneg
  have hint : ∀ (N : ℕ) (k : ℤ), ∫ θ, exp (k * θ * I) ∂(fejerMeasure r (N + 1)) =
      r k * ((((max (((N + 1 : ℕ) : ℤ) - |k|) 0 : ℤ) : ℝ) / ((N + 1 : ℕ) : ℝ)) : ℂ) := by
    intro N k
    rw [fejerMeasure_integral r hpd (N + 1) N.succ_pos k,
      Complex.ofReal_intCast, Complex.ofReal_natCast]
  rcases hr0nn.eq_or_lt with h0 | hpos
  · -- zero mass: r vanishes
    refine ⟨0, inferInstance, by simp, fun k => ?_⟩
    rw [integral_zero_measure]
    have hz : fejerMeasure r (k.natAbs + 1) = 0 := by
      have := huniv k.natAbs
      rw [← h0, measureReal_eq_zero_iff (measure_ne_top _ _)] at this
      exact Measure.measure_univ_eq_zero.1 this
    have := hint k.natAbs k
    rw [hz, integral_zero_measure] at this
    have hq : ((((max (((k.natAbs + 1 : ℕ) : ℤ) - |k|) 0 : ℤ) : ℝ) /
        ((k.natAbs + 1 : ℕ) : ℝ)) : ℂ) ≠ 0 := by
      have : max (((k.natAbs + 1 : ℕ) : ℤ) - |k|) 0 = 1 := by
        rw [Int.abs_eq_natAbs]; push_cast; simp
      rw [this]
      norm_num
      positivity
    exact (mul_eq_zero.1 this.symm).resolve_right hq
  · -- positive mass: normalize
    have hc0 : ENNReal.ofReal r0 ≠ 0 := by simpa using hpos
    let P : ℕ → Measure ℝ := fun N => (ENNReal.ofReal r0)⁻¹ • fejerMeasure r (N + 1)
    have hPprob : ∀ N, IsProbabilityMeasure (P N) := by
      intro N
      constructor
      have h1 : fejerMeasure r (N + 1) Set.univ = ENNReal.ofReal r0 := by
        rw [← huniv N, ofReal_measureReal (measure_ne_top _ _)]
      simp only [P, Measure.smul_apply, smul_eq_mul, h1]
      exact ENNReal.inv_mul_cancel hc0 ENNReal.ofReal_ne_top
    have htight : IsTightMeasureSet (Set.range P) := by
      rw [isTightMeasureSet_iff_exists_isCompact_measure_compl_le]
      refine fun ε _ => ⟨Set.Icc (-Real.pi) Real.pi, isCompact_Icc, ?_⟩
      rintro _ ⟨N, rfl⟩
      simp [P, fejerMeasure_support]
    obtain ⟨ν, hνprob, hν⟩ := exists_limit_of_tight P htight
    have hPint : ∀ (f : BoundedContinuousFunction ℝ ℂ) N, ∫ x, f x ∂(P N) = (r0⁻¹ : ℝ) • ∫ x, f x ∂(fejerMeasure r (N + 1)) := by
      intro f N
      simp only [P, integral_smul_measure, ENNReal.toReal_inv, ENNReal.toReal_ofReal hpos.le]
    have hνexp : ∀ k : ℤ, ∫ x, exp (k * x * I) ∂ν = (r0⁻¹ : ℝ) • r k := by
      intro k
      refine hν (expBCF k) ((r0⁻¹ : ℝ) • r k) ?_
      have e : ∀ N, ∫ x, expBCF k x ∂(P N) = (r0⁻¹ : ℝ) • (r k *
          ((((max (((N + 1 : ℕ) : ℤ) - |k|) 0 : ℤ) : ℝ) / ((N + 1 : ℕ) : ℝ)) : ℂ)) := by
        intro N
        rw [hPint]
        exact congrArg _ (hint N k)
      simp_rw [e]
      refine Tendsto.const_smul ?_ _
      simpa using (frac_tendsto_one k).const_mul (r k)
    have hνsupp : ν (Set.Icc (-Real.pi) Real.pi)ᶜ = 0 := by
      apply support_of_integral_cut_eq_zero
      refine hν cutBCF 0 ?_
      refine tendsto_const_nhds.congr fun N => ?_
      rw [integral_cut_eq_zero_of_support]
      simp [P, fejerMeasure_support]
    refine ⟨r0.toNNReal • ν.map wrapPi, inferInstance, ?_, fun k => ?_⟩
    · rw [Measure.smul_apply, Measure.map_apply wrapPi_measurable measurableSet_Ioc.compl,
        measure_mono_null wrapPi_preimage hνsupp, smul_zero]
    · rw [integral_smul_nnreal_measure, integral_map wrapPi_measurable.aemeasurable
        (Continuous.aestronglyMeasurable (by fun_prop))]
      simp_rw [exp_wrapPi]
      rw [hνexp, NNReal.smul_def, Real.coe_toNNReal _ hpos.le, smul_smul, mul_inv_cancel₀ hpos.ne', one_smul]

#print axioms herglotz_forward

theorem norm_exp_I_sub_one_le_aux (x θ : ℝ) (hxθ : |x| ≤ |θ|) (hθ : |θ| ≤ Real.pi) (ε : ℝ) (hε : 0 < ε) :
    ‖exp (x * I) - 1‖ ≤ ε + (2 - 2 * Real.cos θ) / ε := by
  have hsq : ‖exp (x * I) - 1‖ ^ 2 = 2 - 2 * Real.cos x := by
    rw [Complex.sq_norm, Complex.normSq_apply]
    simp only [sub_re, sub_im, exp_ofReal_mul_I_re, exp_ofReal_mul_I_im, one_re, one_im, sub_zero]
    nlinarith [Real.sin_sq_add_cos_sq x]
  have hcos : Real.cos θ ≤ Real.cos x := by
    rw [← Real.cos_abs x, ← Real.cos_abs θ]
    exact Real.cos_le_cos_of_nonneg_of_le_pi (abs_nonneg x) hθ hxθ
  set a := ‖exp (x * I) - 1‖
  have ha : 0 ≤ a := norm_nonneg _
  have h1 : a ≤ ε + a ^ 2 / ε := by
    have : a * ε ≤ ε * ε + a ^ 2 := by nlinarith [sq_nonneg (a - ε)]
    have : a ≤ (ε * ε + a ^ 2) / ε := by rw [le_div_iff₀ hε]; linarith
    calc a ≤ (ε * ε + a ^ 2) / ε := this
      _ = ε + a ^ 2 / ε := by field_simp
  calc a ≤ ε + a ^ 2 / ε := h1
    _ ≤ ε + (2 - 2 * Real.cos θ) / ε := by
      rw [hsq]; gcongr

#print axioms norm_exp_I_sub_one_le_aux

theorem approx_bound (ν : Measure ℝ) [IsFiniteMeasure ν]
    (hsupp : ν (Set.Ioc (-Real.pi) Real.pi)ᶜ = 0) (k : ℤ) (s : ℝ) (hs : |s - k| ≤ 1 / 2)
    (ε : ℝ) (hε : 0 < ε) :
    ‖∫ θ, exp (s * θ * I) ∂ν - ∫ θ, exp (k * θ * I) ∂ν‖ ≤
      ε * ν.real Set.univ +
        (2 * ν.real Set.univ - 2 * (∫ θ, exp (((1 : ℤ) : ℂ) * θ * I) ∂ν).re) / ε := by
  have hiexp : ∀ s : ℝ, Integrable (fun θ : ℝ => exp (s * θ * I)) ν := fun s =>
    Integrable.of_bound (Continuous.aestronglyMeasurable (by fun_prop)) 1
      (ae_of_all _ fun θ => (norm_exp_mul_mul_I s θ).le)
  have hiexpk : Integrable (fun θ : ℝ => exp (k * θ * I)) ν := by
    simpa using hiexp (k : ℝ)
  have hicos : Integrable (fun θ : ℝ => Real.cos θ) ν :=
    Integrable.of_bound (Continuous.aestronglyMeasurable (by fun_prop)) 1
      (ae_of_all _ fun θ => by rw [Real.norm_eq_abs]; exact Real.abs_cos_le_one θ)
  rw [← integral_sub (hiexp s) hiexpk]
  refine (norm_integral_le_integral_norm _).trans ?_
  have hmem : ∀ᵐ θ ∂ν, θ ∈ Set.Ioc (-Real.pi) Real.pi := by
    rw [ae_iff]; exact hsupp
  have hpt : ∀ᵐ (θ : ℝ) ∂ν, ‖exp (s * θ * I) - exp (k * θ * I)‖ ≤
      ε + (2 - 2 * Real.cos θ) / ε := by
    filter_upwards [hmem] with θ hθ
    have e : exp (s * θ * I) - exp (k * θ * I) =
        exp (k * θ * I) * (exp (((s - k) * θ : ℝ) * I) - 1) := by
      rw [mul_sub, ← exp_add, mul_one]; congr 2; push_cast; ring
    rw [e, norm_mul]
    rw [show ‖exp (k * θ * I)‖ = 1 by simpa using norm_exp_mul_mul_I (k : ℝ) θ, one_mul]
    apply norm_exp_I_sub_one_le_aux _ θ _ _ ε hε
    · rw [abs_mul]; nlinarith [abs_nonneg θ]
    · exact abs_le.2 ⟨by linarith [hθ.1], hθ.2⟩
  have hre : (∫ θ, exp (((1 : ℤ) : ℂ) * θ * I) ∂ν).re = ∫ θ, Real.cos θ ∂ν := by
    have := integral_re (hiexp 1)
    simp only [ofReal_one, one_mul, RCLike.re_to_complex] at this
    simp only [Int.cast_one, one_mul]
    rw [← this]
    congr 1; ext θ
    exact exp_ofReal_mul_I_re θ
  calc ∫ θ, ‖exp (s * θ * I) - exp (k * θ * I)‖ ∂ν
      ≤ ∫ θ, (ε + (2 - 2 * Real.cos θ) / ε) ∂ν :=
        integral_mono_ae ((hiexp s).sub hiexpk).norm
          ((integrable_const ε).add (((integrable_const 2).sub (hicos.const_mul 2)).div_const ε)) hpt
    _ = ε * ν.real Set.univ + (2 * ν.real Set.univ - 2 * (∫ θ, Real.cos θ ∂ν)) / ε := by
      have e1 : (∫ θ, (ε + (2 - 2 * Real.cos θ) / ε) ∂ν) =
          ∫ θ, ((ε + 2 / ε) - (2 / ε) * Real.cos θ) ∂ν := by
        congr 1; ext θ; ring
      rw [e1, integral_sub (integrable_const _) (hicos.const_mul _), integral_const,
        integral_const_mul, smul_eq_mul]
      field_simp
      ring
    _ = _ := by rw [hre]

#print axioms approx_bound

theorem bochner_conv (g : ℝ → ℂ) (hg : Continuous g) (h : ℕ → ℝ) (hpos : ∀ n, 0 < h n)
    (hlim : Tendsto h atTop (𝓝 0)) (ν : ℕ → Measure ℝ) [hfin : ∀ n, IsFiniteMeasure (ν n)]
    (hsupp : ∀ n, ν n (Set.Ioc (-Real.pi) Real.pi)ᶜ = 0)
    (hrep : ∀ n (k : ℤ), g (k * h n) = ∫ θ, exp (k * θ * I) ∂(ν n)) (t : ℝ) :
    Tendsto (fun n => ∫ θ, exp ((t / h n : ℝ) * θ * I) ∂(ν n)) atTop (𝓝 (g t)) := by
  set m0 := (g 0).re with hm0
  have hmass : ∀ n, (ν n).real Set.univ = m0 := by
    intro n
    have := hrep n 0
    simp only [Int.cast_zero, zero_mul, exp_zero, integral_const, Complex.real_smul,
      mul_one] at this
    rw [hm0, this, ofReal_re]
  have hre1 : ∀ n, (∫ θ, exp (((1 : ℤ) : ℂ) * θ * I) ∂(ν n)).re = (g (h n)).re := by
    intro n
    rw [← hrep n 1]
    simp
  let kk : ℕ → ℤ := fun n => round (t / h n)
  let B : ℕ → ℝ := fun n => 2 * m0 - 2 * (g (h n)).re
  let ε : ℕ → ℝ := fun n => Real.sqrt (|B n| + h n)
  have hεpos : ∀ n, 0 < ε n := fun n =>
    Real.sqrt_pos.2 (by have := hpos n; positivity)
  have hbound : ∀ n, ‖∫ θ, exp ((t / h n : ℝ) * θ * I) ∂(ν n) - g t‖ ≤
      ε n * (m0 + 1) + ‖g (kk n * h n) - g t‖ := by
    intro n
    refine (norm_sub_le_norm_sub_add_norm_sub _ (g (kk n * h n)) _).trans ?_
    gcongr
    rw [hrep n (kk n)]
    have hab := approx_bound (ν n) (hsupp n) (kk n) (t / h n) (abs_sub_round _) (ε n) (hεpos n)
    rw [hmass, hre1] at hab
    refine hab.trans ?_
    have hsq : ε n ^ 2 = |B n| + h n := Real.sq_sqrt (by have := hpos n; positivity)
    have h1 : B n / ε n ≤ ε n := by
      rw [div_le_iff₀ (hεpos n)]
      nlinarith [le_abs_self (B n), hpos n]
    change ε n * m0 + B n / ε n ≤ ε n * (m0 + 1)
    nlinarith
  have hε0 : Tendsto ε atTop (𝓝 0) := by
    have hgh : Tendsto (fun n => (g (h n)).re) atTop (𝓝 m0) :=
      (continuous_re.tendsto _).comp ((hg.tendsto 0).comp hlim)
    have hB : Tendsto (fun n => |B n| + h n) atTop (𝓝 (|2 * m0 - 2 * m0| + 0)) :=
      ((tendsto_const_nhds.sub (hgh.const_mul 2)).abs).add hlim
    rw [sub_self, abs_zero, add_zero] at hB
    have := (Real.continuous_sqrt.tendsto 0).comp hB
    rw [Real.sqrt_zero] at this
    exact this
  have hk : Tendsto (fun n => (kk n : ℝ) * h n) atTop (𝓝 t) := by
    rw [tendsto_iff_norm_sub_tendsto_zero]
    have h2 : Tendsto (fun n => h n / 2) atTop (𝓝 0) := by simpa using hlim.div_const 2
    refine squeeze_zero (fun n => norm_nonneg _) (fun n => ?_) h2
    show ‖(kk n : ℝ) * h n - t‖ ≤ h n / 2
    have e : (kk n : ℝ) * h n - t = h n * ((kk n : ℝ) - t / h n) := by
      rw [mul_sub, mul_div_cancel₀ _ (hpos n).ne']; ring
    rw [e, norm_mul, Real.norm_eq_abs, abs_of_pos (hpos n), Real.norm_eq_abs, abs_sub_comm]
    have := abs_sub_round (t / h n)
    nlinarith [hpos n]
  have hgk : Tendsto (fun n => g (kk n * h n)) atTop (𝓝 (g t)) := (hg.tendsto t).comp hk
  rw [tendsto_iff_norm_sub_tendsto_zero]
  refine squeeze_zero (fun n => norm_nonneg _) hbound ?_
  have := (hε0.mul_const (m0 + 1)).add (tendsto_iff_norm_sub_tendsto_zero.1 hgk)
  simpa using this

#print axioms bochner_conv

theorem bochner_forward (g : ℝ → ℂ) (hg : Continuous g)
    (hpd : ∀ (m : ℕ) (τ : Fin m → ℝ) (c : Fin m → ℂ),
        0 ≤ ∑ j, ∑ k, c j * (starRingEnd ℂ) (c k) * g (τ j - τ k)) :
    ∃ μ : Measure ℝ, IsFiniteMeasure μ ∧
        ∀ τ : ℝ, g τ = ∫ ξ, exp (2 * Real.pi * ξ * τ * I) ∂μ := by
  let h : ℕ → ℝ := fun n => 1 / ((n : ℝ) + 1)
  have hpos : ∀ n, 0 < h n := fun n => by positivity
  have hlim : Tendsto h atTop (𝓝 0) := tendsto_one_div_add_atTop_nhds_zero_nat
  have hpdn : ∀ n, ∀ (m : ℕ) (nn : Fin m → ℤ) (c : Fin m → ℂ),
      0 ≤ ∑ j, ∑ k, c j * (starRingEnd ℂ) (c k) * (fun k : ℤ => g (k * h n)) (nn j - nn k) := by
    intro n m nn c
    have := hpd m (fun j => (nn j : ℝ) * h n) c
    refine this.trans_eq (Finset.sum_congr rfl fun j _ => Finset.sum_congr rfl fun k _ => ?_)
    congr 2; push_cast; ring
  choose ν hνfin hνsupp hνrep using fun n => herglotz_forward (fun k : ℤ => g (k * h n)) (hpdn n)
  have hconv := bochner_conv g hg h hpos hlim ν hνsupp hνrep
  set m0 := (g 0).re with hm0
  have hmass : ∀ n, (ν n).real Set.univ = m0 := by
    intro n
    have := hνrep n 0
    simp only [Int.cast_zero, zero_mul, exp_zero, integral_const, Complex.real_smul,
      mul_one] at this
    rw [hm0, this, ofReal_re]
  have hm0nn : 0 ≤ m0 := by rw [← hmass 0]; exact measureReal_nonneg
  rcases hm0nn.eq_or_lt with h0 | hm0pos
  · have hz : ∀ n, ν n = 0 := by
      intro n
      have := hmass n
      rw [← h0, measureReal_eq_zero_iff (measure_ne_top _ _)] at this
      exact Measure.measure_univ_eq_zero.1 this
    have hg0 : ∀ t, g t = 0 := by
      intro t
      have := hconv t
      simp only [hz, integral_zero_measure] at this
      exact tendsto_nhds_unique this tendsto_const_nhds
    exact ⟨0, inferInstance, fun τ => by rw [integral_zero_measure, hg0]⟩
  · have hmeas : ∀ n, Measurable (fun θ : ℝ => θ / h n) := fun n => measurable_id.div_const _
    have hc0 : ENNReal.ofReal m0 ≠ 0 := by simpa using hm0pos
    let Q : ℕ → Measure ℝ := fun n => (ENNReal.ofReal m0)⁻¹ • (ν n).map (fun θ => θ / h n)
    have hQprob : ∀ n, IsProbabilityMeasure (Q n) := by
      intro n
      constructor
      have h1 : (ν n).map (fun θ => θ / h n) Set.univ = ENNReal.ofReal m0 := by
        rw [Measure.map_apply (hmeas n) MeasurableSet.univ, Set.preimage_univ, ← hmass n,
          ofReal_measureReal (measure_ne_top _ _)]
      simp only [Q, Measure.smul_apply, smul_eq_mul, h1]
      exact ENNReal.inv_mul_cancel hc0 ENNReal.ofReal_ne_top
    have hQchar : ∀ n t, charFun (Q n) t =
        (m0⁻¹ : ℝ) • ∫ θ, exp ((t / h n : ℝ) * θ * I) ∂(ν n) := by
      intro n t
      rw [charFun_apply_real, integral_smul_measure, integral_map (hmeas n).aemeasurable
        (Continuous.aestronglyMeasurable (by fun_prop)), ENNReal.toReal_inv,
        ENNReal.toReal_ofReal hm0pos.le]
      congr 1
      refine integral_congr_ae (ae_of_all _ fun θ => ?_)
      simp only
      congr 1
      push_cast
      ring
    have hQconv : ∀ t, Tendsto (fun n => charFun (Q n) t) atTop (𝓝 ((m0⁻¹ : ℝ) • g t)) := by
      intro t
      simp_rw [hQchar]
      exact (hconv t).const_smul _
    have htight : IsTightMeasureSet (Set.range Q) :=
      isTightMeasureSet_of_tendsto_charFun (f := fun t => (m0⁻¹ : ℝ) • g t)
        ((by fun_prop : Continuous fun t => (m0⁻¹ : ℝ) • g t).continuousAt) hQconv
    obtain ⟨ν', hprob, hlimν⟩ := exists_limit_of_tight Q htight
    have hνexp : ∀ t : ℝ, ∫ x, exp (t * x * I) ∂ν' = (m0⁻¹ : ℝ) • g t := by
      intro t
      refine hlimν (expBCF t) _ ?_
      have := hQconv t
      simp only [charFun_apply_real] at this
      exact this
    have hmeas2 : Measurable (fun x : ℝ => x / (2 * Real.pi)) := measurable_id.div_const _
    refine ⟨m0.toNNReal • ν'.map (fun x => x / (2 * Real.pi)), inferInstance, fun τ => ?_⟩
    rw [integral_smul_nnreal_measure, integral_map hmeas2.aemeasurable
      (Continuous.aestronglyMeasurable (by fun_prop))]
    have e : ∀ x : ℝ, exp (2 * Real.pi * ((x / (2 * Real.pi) : ℝ) : ℂ) * τ * I) =
        exp (τ * x * I) := by
      intro x
      congr 1
      have : (Real.pi : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
      push_cast
      field_simp
    simp_rw [e]
    rw [hνexp, NNReal.smul_def, Real.coe_toNNReal _ hm0pos.le, smul_smul, mul_inv_cancel₀ hm0pos.ne',
      one_smul]

#print axioms bochner_forward

/-- Bochner's theorem: a continuous function `g` on the line is positive definite (for any lags
`τ₁, …, τₘ` and any complex weights `c₁, …, cₘ`, the double sum `∑ⱼ ∑ₖ cⱼ · conj cₖ · g(τⱼ − τₖ)`
is a real number that is 0 or more) exactly when `g(τ) = ∫ e^(2πiξτ) dμ(ξ)` for a spectrum `μ`:
a finite measure on the frequencies, which gives every set a weight of 0 or more. -/
theorem bochner_positive_definite_iff_spectrum (g : ℝ → ℂ) (hg : Continuous g) :
    (∀ (m : ℕ) (τ : Fin m → ℝ) (c : Fin m → ℂ),
        0 ≤ ∑ j, ∑ k, c j * (starRingEnd ℂ) (c k) * g (τ j - τ k)) ↔
      ∃ μ : Measure ℝ, IsFiniteMeasure μ ∧
        ∀ τ : ℝ, g τ = ∫ ξ, exp (2 * Real.pi * ξ * τ * I) ∂μ := by
  constructor
  · exact bochner_forward g hg
  · rintro ⟨μ, hμ, hrep⟩ m τ c
    have := pd_sum_integral_nonneg μ (fun j ξ => exp (((2 * Real.pi * ξ * τ j : ℝ) : ℂ) * I)) c
      (fun j k => Integrable.of_bound (Continuous.aestronglyMeasurable (by fun_prop)) 1
        (ae_of_all _ fun ξ => by
          rw [norm_mul, Complex.norm_conj, norm_exp_ofReal_mul_I, norm_exp_ofReal_mul_I, one_mul]))
    refine this.trans_eq (Finset.sum_congr rfl fun j _ => Finset.sum_congr rfl fun k _ => ?_)
    rw [hrep]
    congr 1
    refine integral_congr_ae (ae_of_all _ fun ξ => ?_)
    simp only
    rw [← exp_conj, ← exp_add]
    congr 1
    simp only [map_mul, conj_ofReal, conj_I]
    push_cast
    ring

/-- Herglotz's theorem: a sequence `r[k]` at whole-number steps is positive definite (for any
whole-number lags `n₁, …, nₘ` and any complex weights `c₁, …, cₘ`, the double sum
`∑ⱼ ∑ₖ cⱼ · conj cₖ · r[nⱼ − nₖ]` is 0 or more) exactly when `r[k] = ∫ e^(ikθ) dμ(θ)` for a
spectrum `μ` on the circle of angles: a finite measure carried by the angles `−π < θ ≤ π`. -/
theorem herglotz_positive_definite_iff_circle_spectrum (r : ℤ → ℂ) :
    (∀ (m : ℕ) (n : Fin m → ℤ) (c : Fin m → ℂ),
        0 ≤ ∑ j, ∑ k, c j * (starRingEnd ℂ) (c k) * r (n j - n k)) ↔
      ∃ μ : Measure ℝ, IsFiniteMeasure μ ∧ μ (Set.Ioc (-Real.pi) Real.pi)ᶜ = 0 ∧
        ∀ k : ℤ, r k = ∫ θ, exp (k * θ * I) ∂μ := by
  constructor
  · exact herglotz_forward r
  · rintro ⟨μ, hμ, -, hrep⟩ m n c
    have := pd_sum_integral_nonneg μ (fun j θ => exp ((((n j : ℝ) * θ : ℝ) : ℂ) * I)) c
      (fun j k => Integrable.of_bound (Continuous.aestronglyMeasurable (by fun_prop)) 1
        (ae_of_all _ fun θ => by
          rw [norm_mul, Complex.norm_conj, norm_exp_ofReal_mul_I, norm_exp_ofReal_mul_I, one_mul]))
    refine this.trans_eq (Finset.sum_congr rfl fun j _ => Finset.sum_congr rfl fun k _ => ?_)
    rw [hrep]
    congr 1
    refine integral_congr_ae (ae_of_all _ fun θ => ?_)
    simp only
    rw [← exp_conj, ← exp_add]
    congr 1
    simp only [map_mul, conj_ofReal, conj_I]
    push_cast
    ring

/-- Pólya's criterion: if `g` is real, even and continuous, `g(0) = 1`, `g` is convex (a bowl)
for `τ > 0`, and `g(τ) → 0` as `τ → ∞`, then `g` is positive definite. -/
theorem polya_bowl_positive_definite (g : ℝ → ℝ) (hcont : Continuous g)
    (heven : ∀ τ, g (-τ) = g τ) (h0 : g 0 = 1) (hconv : ConvexOn ℝ (Set.Ioi 0) g)
    (hlim : Tendsto g atTop (𝓝 0)) :
    ∀ (m : ℕ) (τ : Fin m → ℝ) (c : Fin m → ℂ),
      0 ≤ ∑ j, ∑ k, c j * (starRingEnd ℂ) (c k) * (g (τ j - τ k) : ℂ) := by
  intro m τ c
  rcases Nat.eq_zero_or_pos m with rfl | hm
  · simp
  have hconvI := convexOn_Ici_of_Ioi g hcont hconv
  have hantiI := antitoneOn_Ici_of_convex_tendsto g hconvI hlim
  let D := Finset.univ.image (fun p : Fin m × Fin m => |τ p.1 - τ p.2|)
  have hmem : ∀ j k, |τ j - τ k| ∈ D := fun j k =>
    Finset.mem_image_of_mem (fun p : Fin m × Fin m => |τ p.1 - τ p.2|) (Finset.mem_univ (j, k))
  have hD : D.Nonempty := ⟨_, hmem ⟨0, hm⟩ ⟨0, hm⟩⟩
  have hnn : ∀ d ∈ D, 0 ≤ d := by
    intro d hd
    obtain ⟨p, -, rfl⟩ := Finset.mem_image.1 hd
    exact abs_nonneg _
  obtain ⟨K, a, s, ha, -, hrep⟩ := polya_rep (D.card - 1) g D hD
    (by have := Finset.card_pos.2 hD; omega) hnn
    (hconvI.subset Set.Icc_subset_Ici_self (convex_Icc _ _)) (hantiI.mono Set.Icc_subset_Ici_self)
  set M := D.max' hD
  have hMnn : 0 ≤ g M := by
    have hM0 : 0 ≤ M := hnn _ (D.max'_mem hD)
    refine le_of_tendsto hlim (eventually_atTop.2 ⟨M, fun z hz => ?_⟩)
    exact hantiI (Set.mem_Ici.2 hM0) (Set.mem_Ici.2 (hM0.trans hz)) hz
  have hval : ∀ j k, g (τ j - τ k) = g M + ∑ i, a i * max (s i - |τ j - τ k|) 0 := by
    intro j k
    rw [← hrep _ (hmem j k)]
    rcases abs_cases (τ j - τ k) with ⟨h, -⟩ | ⟨h, -⟩
    · rw [h]
    · rw [h, heven]
  have hsq : ∑ j, ∑ k, c j * (starRingEnd ℂ) (c k) = ((Complex.normSq (∑ j, c j) : ℝ) : ℂ) := by
    rw [Complex.normSq_eq_conj_mul_self, map_sum, Finset.sum_mul_sum, Finset.sum_comm]
    exact Finset.sum_congr rfl fun _ _ => Finset.sum_congr rfl fun _ _ => mul_comm _ _
  have hexp : ∑ j, ∑ k, c j * (starRingEnd ℂ) (c k) * (g (τ j - τ k) : ℂ)
      = (g M : ℂ) * ∑ j, ∑ k, c j * (starRingEnd ℂ) (c k)
        + ∑ i, (a i : ℂ) * ∑ j, ∑ k, c j * (starRingEnd ℂ) (c k) *
            ((max (s i - |τ j - τ k|) 0 : ℝ) : ℂ) := by
    simp_rw [hval, Complex.ofReal_add, Complex.ofReal_sum, Complex.ofReal_mul, mul_add,
      Finset.sum_add_distrib, Finset.mul_sum]
    congr 1
    · exact Finset.sum_congr rfl fun _ _ => Finset.sum_congr rfl fun _ _ => by ring
    · refine (Finset.sum_congr rfl fun j _ => Finset.sum_comm).trans ?_
      rw [Finset.sum_comm]
      exact Finset.sum_congr rfl fun _ _ => Finset.sum_congr rfl fun _ _ =>
        Finset.sum_congr rfl fun _ _ => by ring
  rw [hexp, hsq]
  refine add_nonneg (mul_nonneg (Complex.zero_le_real.2 hMnn)
    (Complex.zero_le_real.2 (Complex.normSq_nonneg _))) (Finset.sum_nonneg fun i _ => ?_)
  exact mul_nonneg (Complex.zero_le_real.2 (ha i)) (pd_triangle τ c (s i))

/-- The flat top's table at lags 0, 0.8 and 1.6 chips: weights (1, −√2, 1) give the mean square
4 − 4√2, which is negative (the card's −1.656854). -/
example :
    let A : Matrix (Fin 3) (Fin 3) ℝ := !![1, 1, 0; 1, 1, 1; 0, 1, 1]
    let c : Fin 3 → ℝ := ![1, -Real.sqrt 2, 1]
    ∑ j, ∑ k, c j * c k * A j k = 4 - 4 * Real.sqrt 2 ∧ 4 - 4 * Real.sqrt 2 < 0 := by
  norm_num [Fin.sum_univ_three]
  constructor
  · ring_nf
  · nlinarith [Real.sq_sqrt (show (0 : ℝ) ≤ 2 by norm_num), Real.sqrt_nonneg 2]

/-- The flat top's table has the eigenvalue 1 − √2: subtracting it from the diagonal leaves a
table with determinant 0. -/
example :
    (!![1, 1, 0; 1, 1, 1; 0, 1, 1] - (1 - Real.sqrt 2) • (1 : Matrix (Fin 3) (Fin 3) ℝ)).det
      = 0 := by
  norm_num [Matrix.det_fin_three]
  ring_nf

/-- Samples every quarter chip: `r[k] = 1 − k/4` gives 1, 0.75, 0.5, 0.25, then 0. -/
example : (List.range 5).map (fun k : ℕ => max 0 (1 - (k : ℚ) / 4)) = [1, 3/4, 1/2, 1/4, 0] := by
  decide +kernel

/-- The Herglotz spectrum `F₄(θ) = ∑_{|k|<4} (1 − |k|/4) e^(ikθ)` is 4 at θ = 0. -/
example : ∑ k ∈ Finset.Icc (-3 : ℤ) 3, (1 - (|k| : ℚ) / 4) = 4 := by
  decide +kernel

#print axioms bochner_positive_definite_iff_spectrum
#print axioms herglotz_positive_definite_iff_circle_spectrum
#print axioms polya_bowl_positive_definite
