-- Carleson's theorem in outline: Carleson's maximal inequality makes the Fourier series of every finite-energy signal converge to it off a set of length zero, fast energy errors already give this along a subsequence, and a continuous signal can still diverge at a point.
import Mathlib.Analysis.Fourier.AddCircle
import Mathlib.NumberTheory.Harmonic.Defs
import Mathlib.NumberTheory.Harmonic.Bounds
import Mathlib.Analysis.Normed.Operator.BanachSteinhaus

open MeasureTheory Filter Topology Real

namespace CarlesonInOutline

/-! Notation, as on the card. The phase `x` runs over one cycle of length `2π`, with the two
ends joined: the circle `𝕋` is `AddCircle (2 * π)`. Its `volume` is length `λ`, `2π` in all.
Mathlib's `haarAddCircle` is length divided by `2π`, so for a signal `f` in `L²(𝕋)` (Mathlib's
`Lp ℂ 2 haarAddCircle`, signals equal off a set of length zero counted as one) the energy
`‖f‖₂² = (1/2π) ∫ |f(x)|² dx` is `‖f‖ ^ 2`. Mathlib's `fourierCoeff f n` is the card's
`f̂(n) = (1/2π) ∫ f(x) e^{-inx} dx`, and `fourier n x` is the wave `e^{inx}`.

Carleson's maximal inequality is not in Mathlib, and the card states it with sources but does
not prove it. So this file proves what the card proves: the step from that inequality to
almost-everywhere convergence (Why it works, Step 2), the fast-subsequence argument (Step 1),
and, given the classical bound on `∑ sin(jx)/j` that the card also uses without proof,
Fejér's continuous signal that diverges at a point (Step 4). -/

local instance : Fact (0 < 2 * π) := ⟨Real.two_pi_pos⟩

/-- The finite-energy signals on the circle, `L²(𝕋)`. -/
abbrev L2Circle : Type := Lp ℂ 2 (@AddCircle.haarAddCircle (2 * π) _)

/-- The partial sum at the instant `x`, `S_N f(x) = ∑_{n=-N}^{N} f̂(n) e^{inx}`. -/
noncomputable def partialSum (f : AddCircle (2 * π) → ℂ) (N : ℕ) (x : AddCircle (2 * π)) : ℂ :=
  ∑ n ∈ Finset.Icc (-(N : ℤ)) N, fourierCoeff f n * fourier n x

/-! Helper lemmas for the proofs below. -/

/-- A partial sum is a continuous signal. -/
lemma exists_continuousMap_partialSum (f : AddCircle (2 * π) → ℂ) (N : ℕ) :
    ∃ g : C(AddCircle (2 * π), ℂ), ⇑g = partialSum f N :=
  ⟨∑ n ∈ Finset.Icc (-(N : ℤ)) N, fourierCoeff f n • fourier n, by
    ext x; simp [partialSum]⟩

#print axioms exists_continuousMap_partialSum

/-- A partial sum has finite energy. -/
lemma memLp_partialSum (f : AddCircle (2 * π) → ℂ) (N : ℕ) :
    MemLp (partialSum f N) 2 (@AddCircle.haarAddCircle (2 * π) _) := by
  obtain ⟨g, hg⟩ := exists_continuousMap_partialSum f N
  rw [← hg]
  exact MemLp.of_bound g.continuous.aestronglyMeasurable ‖g‖
    (ae_of_all _ fun x => g.norm_coe_le_norm x)

#print axioms memLp_partialSum

/-- Almost everywhere for length is almost everywhere for normalised length. -/
lemma ae_volume_iff (P : AddCircle (2 * π) → Prop) :
    (∀ᵐ x ∂(volume : Measure (AddCircle (2 * π))), P x) ↔
      ∀ᵐ x ∂(@AddCircle.haarAddCircle (2 * π) _), P x := by
  rw [AddCircle.volume_eq_smul_haarAddCircle]
  exact Measure.ae_ennreal_smul_measure_iff (by simp [Real.pi_pos])

#print axioms ae_volume_iff

/-- For a finite-energy signal the coefficients are its coordinates in the Fourier basis. -/
lemma partialSum_Lp (g : L2Circle) (N : ℕ) (x : AddCircle (2 * π)) :
    partialSum (⇑g) N x =
      ∑ n ∈ Finset.Icc (-(N : ℤ)) N, (fourierBasis (T := 2 * π)).repr g n * fourier n x := by
  simp [partialSum, fourierBasis_repr]
#print axioms partialSum_Lp


lemma partialSum_Lp_add (g h : L2Circle) (N : ℕ) (x : AddCircle (2 * π)) :
    partialSum (⇑(g + h)) N x = partialSum (⇑g) N x + partialSum (⇑h) N x := by
  simp only [partialSum_Lp, map_add, lp.coeFn_add, Pi.add_apply, add_mul, Finset.sum_add_distrib]
#print axioms partialSum_Lp_add


lemma partialSum_Lp_sub (g h : L2Circle) (N : ℕ) (x : AddCircle (2 * π)) :
    partialSum (⇑(g - h)) N x = partialSum (⇑g) N x - partialSum (⇑h) N x := by
  simp only [partialSum_Lp, map_sub, lp.coeFn_sub, Pi.sub_apply, sub_mul, Finset.sum_sub_distrib]
#print axioms partialSum_Lp_sub


lemma partialSum_Lp_smul (c : ℂ) (g : L2Circle) (N : ℕ) (x : AddCircle (2 * π)) :
    partialSum (⇑(c • g)) N x = c * partialSum (⇑g) N x := by
  simp only [partialSum_Lp, map_smul, lp.coeFn_smul, Pi.smul_apply, smul_eq_mul, mul_assoc,
    Finset.mul_sum]
#print axioms partialSum_Lp_smul


lemma partialSum_Lp_zero (N : ℕ) (x : AddCircle (2 * π)) :
    partialSum (⇑(0 : L2Circle)) N x = 0 := by
  rw [partialSum_Lp]; simp
#print axioms partialSum_Lp_zero


/-- The partial sums of a trigonometric polynomial are the polynomial itself, once the cut-off
passes its degree. -/
lemma exists_partialSum_eq_of_mem_span (p : L2Circle)
    (hp : p ∈ Submodule.span ℂ (Set.range (fourierLp (T := 2 * π) 2))) :
    ∃ D : ℕ, ∀ᵐ x ∂(@AddCircle.haarAddCircle (2 * π) _),
      ∀ N : ℕ, D ≤ N → partialSum (⇑p) N x = p x := by
  induction hp using Submodule.span_induction with
  | mem q hq =>
    obtain ⟨k, rfl⟩ := hq
    refine ⟨k.natAbs, ?_⟩
    filter_upwards [coeFn_fourierLp (T := 2 * π) 2 k] with x hx
    intro N hN
    rw [partialSum_Lp, hx, ← coe_fourierBasis, HilbertBasis.repr_self]
    simp only [lp.single_apply, Pi.single_apply]
    rw [Finset.sum_eq_single k]
    · simp
    · intro b _ hb; simp [hb]
    · intro hk; exfalso; apply hk; rw [Finset.mem_Icc]; omega
  | zero =>
    refine ⟨0, ?_⟩
    filter_upwards [Lp.coeFn_zero ℂ 2 (@AddCircle.haarAddCircle (2 * π) _)] with x hx
    intro N _
    rw [partialSum_Lp_zero, hx, Pi.zero_apply]
  | add q r _ _ hq hr =>
    obtain ⟨D₁, h₁⟩ := hq
    obtain ⟨D₂, h₂⟩ := hr
    refine ⟨max D₁ D₂, ?_⟩
    filter_upwards [h₁, h₂, Lp.coeFn_add q r] with x hx₁ hx₂ hx
    intro N hN
    rw [partialSum_Lp_add, hx, Pi.add_apply, hx₁ N (le_of_max_le_left hN),
      hx₂ N (le_of_max_le_right hN)]
  | smul c q _ hq =>
    obtain ⟨D, h⟩ := hq
    refine ⟨D, ?_⟩
    filter_upwards [h, Lp.coeFn_smul c q] with x hx₁ hx
    intro N hN
    rw [partialSum_Lp_smul, hx, Pi.smul_apply, hx₁ N hN, smul_eq_mul]

#print axioms exists_partialSum_eq_of_mem_span

/-- Chebyshev's inequality for a finite-energy signal, with normalised length. -/
lemma haar_le_enorm_le (g : L2Circle) {β : ℝ} (hβ : 0 < β) :
    (@AddCircle.haarAddCircle (2 * π) _) {x | ENNReal.ofReal β ≤ ‖g x‖ₑ} ≤
      ENNReal.ofReal (‖g‖ ^ 2 / β ^ 2) := by
  have h := mul_meas_ge_le_pow_eLpNorm' (@AddCircle.haarAddCircle (2 * π) _)
    (p := 2) two_ne_zero ENNReal.ofNat_ne_top (f := ⇑g) (ENNReal.ofReal β)
  have he : eLpNorm (⇑g) 2 (@AddCircle.haarAddCircle (2 * π) _) = ENNReal.ofReal ‖g‖ := by
    rw [Lp.norm_def, ENNReal.ofReal_toReal (Lp.eLpNorm_ne_top g)]
  rw [he, ENNReal.toReal_ofNat, ENNReal.rpow_two, ENNReal.rpow_two,
    ← ENNReal.ofReal_pow hβ.le, ← ENNReal.ofReal_pow (norm_nonneg _)] at h
  rw [ENNReal.ofReal_div_of_pos (by positivity), ENNReal.le_div_iff_mul_le
    (Or.inl (ENNReal.ofReal_pos.mpr (by positivity)).ne') (Or.inl ENNReal.ofReal_ne_top), mul_comm]
  exact h

#print axioms haar_le_enorm_le

/-- The core of Step 2: from the maximal inequality, for each tolerance `ε`, almost every
instant has its partial sums eventually within `ε` of the signal. -/
lemma eventually_close_of_carleson (A : ℝ)
    (hCarleson : ∀ (g : L2Circle) (α : ℝ), 0 < α →
      volume {x : AddCircle (2 * π) | ∃ N : ℕ, α < ‖partialSum (⇑g) N x‖} ≤
        ENNReal.ofReal (A * ‖g‖ ^ 2 / α ^ 2))
    (f : L2Circle) {ε : ℝ} (hε : 0 < ε) :
    ∀ᵐ x ∂(volume : Measure (AddCircle (2 * π))),
      ∀ᶠ N in atTop, ‖partialSum (⇑f) N x - f x‖ ≤ ε := by
  set μ := @AddCircle.haarAddCircle (2 * π) _ with hμ
  set ν := (volume : Measure (AddCircle (2 * π))) with hν
  rw [ae_iff]
  set B := {x | ¬∀ᶠ N in atTop, ‖partialSum (⇑f) N x - f x‖ ≤ ε} with hB
  refine le_antisymm (ENNReal.le_of_forall_pos_le_add fun η hη _ => ?_) zero_le
  rw [zero_add]
  have hε2 : 0 < ε / 2 := by positivity
  set K : ℝ := (|A| + 2 * π) / (ε / 2) ^ 2 with hK
  have hKpos : 0 < K := by positivity
  set δ : ℝ := Real.sqrt (η / K) with hδ
  have hδpos : 0 < δ := Real.sqrt_pos.mpr (by positivity)
  have hKδ : K * δ ^ 2 = η := by
    rw [hδ, Real.sq_sqrt (by positivity)]; field_simp
  -- A trigonometric polynomial `p` within `δ` of `f`.
  have hf : f ∈ closure (Submodule.span ℂ (Set.range (fourierLp (T := 2 * π) 2)) :
      Set L2Circle) := by
    rw [← Submodule.topologicalClosure_coe, span_fourierLp_closure_eq_top (by norm_num)]
    trivial
  obtain ⟨p, hp, hfp⟩ := Metric.mem_closure_iff.mp hf δ hδpos
  set g : L2Circle := f - p with hg
  have hgδ : ‖g‖ < δ := by rw [hg, ← dist_eq_norm]; exact hfp
  obtain ⟨D, hD⟩ := exists_partialSum_eq_of_mem_span p hp
  have hgood : ∀ᵐ x ∂ν, (∀ N : ℕ, D ≤ N → partialSum (⇑p) N x = p x) ∧ g x = f x - p x :=
    (ae_volume_iff _).2 (hD.and (Lp.coeFn_sub f p))
  set E₀ := {x | ¬((∀ N : ℕ, D ≤ N → partialSum (⇑p) N x = p x) ∧ g x = f x - p x)} with hE₀
  set S₁ := {x : AddCircle (2 * π) | ∃ N : ℕ, ε / 2 < ‖partialSum (⇑g) N x‖} with hS₁
  set S₂ := {x : AddCircle (2 * π) | ENNReal.ofReal (ε / 2) ≤ ‖g x‖ₑ} with hS₂
  have hsub : B ⊆ E₀ ∪ S₁ ∪ S₂ := by
    intro x hxB
    by_contra hcon
    simp only [hE₀, hS₁, hS₂, Set.mem_union, Set.mem_ofPred_eq, not_or, not_not, not_exists,
      not_le, not_lt] at hcon
    obtain ⟨⟨⟨hpx, hgx⟩, h₁⟩, h₂⟩ := hcon
    apply hxB
    filter_upwards [eventually_ge_atTop D] with N hN
    have h₂' : ‖g x‖ < ε / 2 := by
      rw [← ofReal_norm] at h₂
      exact (ENNReal.ofReal_lt_ofReal_iff hε2).mp h₂
    have hsplit : partialSum (⇑f) N x - f x = partialSum (⇑g) N x - g x := by
      have := partialSum_Lp_sub f p N x
      rw [← hg] at this
      rw [this, hpx N hN, hgx]; ring
    calc ‖partialSum (⇑f) N x - f x‖ = ‖partialSum (⇑g) N x - g x‖ := by rw [hsplit]
      _ ≤ ‖partialSum (⇑g) N x‖ + ‖g x‖ := norm_sub_le _ _
      _ ≤ ε / 2 + ε / 2 := add_le_add (h₁ N) h₂'.le
      _ = ε := by ring
  have hE₀0 : ν E₀ = 0 := ae_iff.1 hgood
  have hS₁le : ν S₁ ≤ ENNReal.ofReal (|A| * ‖g‖ ^ 2 / (ε / 2) ^ 2) :=
    (hCarleson g (ε / 2) hε2).trans (ENNReal.ofReal_le_ofReal (by
      gcongr; exact le_abs_self A))
  have hS₂le : ν S₂ ≤ ENNReal.ofReal (2 * π * ‖g‖ ^ 2 / (ε / 2) ^ 2) := by
    rw [hν, AddCircle.volume_eq_smul_haarAddCircle, Measure.smul_apply, smul_eq_mul]
    calc ENNReal.ofReal (2 * π) * μ S₂
        ≤ ENNReal.ofReal (2 * π) * ENNReal.ofReal (‖g‖ ^ 2 / (ε / 2) ^ 2) := by
          gcongr; exact haar_le_enorm_le g hε2
      _ = ENNReal.ofReal (2 * π * ‖g‖ ^ 2 / (ε / 2) ^ 2) := by
          rw [← ENNReal.ofReal_mul (by positivity)]; ring_nf
  calc ν B ≤ ν (E₀ ∪ S₁ ∪ S₂) := measure_mono hsub
    _ ≤ ν E₀ + ν S₁ + ν S₂ := (measure_union_le _ _).trans (add_le_add_left (measure_union_le _ _) _)
    _ ≤ 0 + ENNReal.ofReal (|A| * ‖g‖ ^ 2 / (ε / 2) ^ 2) +
          ENNReal.ofReal (2 * π * ‖g‖ ^ 2 / (ε / 2) ^ 2) := by
        rw [hE₀0]; gcongr
    _ = ENNReal.ofReal (K * ‖g‖ ^ 2) := by
        rw [zero_add, ← ENNReal.ofReal_add (by positivity) (by positivity), hK]
        congr 1; ring
    _ ≤ ENNReal.ofReal (K * δ ^ 2) := by
        apply ENNReal.ofReal_le_ofReal
        gcongr
    _ = η := by rw [hKδ, ENNReal.ofReal_coe_nnreal]

#print axioms eventually_close_of_carleson

/-- The partial sum at `0`, as a continuous linear functional on continuous signals. -/
noncomputable def partialSumAtZeroCLM (N : ℕ) : C(AddCircle (2 * π), ℂ) →L[ℂ] ℂ :=
  ∑ n ∈ Finset.Icc (-(N : ℤ)) N,
    (innerSL ℂ (fourierLp (T := 2 * π) 2 n)).comp
      (ContinuousMap.toLp (E := ℂ) 2 (@AddCircle.haarAddCircle (2 * π) _) ℂ)

lemma partialSumAtZeroCLM_apply (N : ℕ) (f : C(AddCircle (2 * π), ℂ)) :
    partialSumAtZeroCLM N f = partialSum (⇑f) N 0 := by
  simp only [partialSumAtZeroCLM, partialSum, FunLike.coe_sum,
    Finset.sum_apply, ContinuousLinearMap.comp_apply, innerSL_apply_apply, fourier_eval_zero,
    mul_one]
  refine Finset.sum_congr rfl fun n _ => ?_
  rw [← fourierCoeff_toLp, ← fourierBasis_repr, HilbertBasis.repr_apply_apply, coe_fourierBasis]

#print axioms partialSumAtZeroCLM_apply

lemma partialSum_fourier_zero (N : ℕ) (k : ℤ) :
    partialSum (⇑(fourier (T := 2 * π) k)) N 0 =
      if k ∈ Finset.Icc (-(N : ℤ)) N then 1 else 0 := by
  simp only [partialSum, fourierCoeff_fourier, fourier_eval_zero, mul_one]
  rw [Finset.sum_pi_single']
#print axioms partialSum_fourier_zero



lemma fourier_add_fourier_neg (k : ℤ) (t : ℝ) :
    fourier (T := 2 * π) k (t : AddCircle (2 * π)) + fourier (-k) (t : AddCircle (2 * π)) =
      ((2 * Real.cos (k * t) : ℝ) : ℂ) := by
  rw [fourier_coe_apply, fourier_coe_apply]
  have h1 : 2 * (π : ℂ) * Complex.I * (k : ℂ) * (t : ℂ) / (2 * (π : ℝ) : ℝ) = (k * t : ℝ) * Complex.I := by
    push_cast; field_simp
  have h2 : 2 * (π : ℂ) * Complex.I * ((-k : ℤ) : ℂ) * (t : ℂ) / (2 * (π : ℝ) : ℝ) = -(k * t : ℝ) * Complex.I := by
    push_cast; field_simp
  rw [h1, h2, ← Complex.two_cos]
  push_cast; ring
#print axioms fourier_add_fourier_neg


/-- Fejér's test polynomial: `2 sin((n+1)x) ∑_{j=1}^{n} sin(jx)/j`, written with waves. -/
noncomputable def fejerTest (n : ℕ) : C(AddCircle (2 * π), ℂ) :=
  ∑ j ∈ Finset.Icc 1 n, ((1 : ℂ) / (2 * j)) •
    (fourier ((n : ℤ) + 1 - j) + fourier (-((n : ℤ) + 1 - j)) - fourier ((n : ℤ) + 1 + j) -
      fourier (-((n : ℤ) + 1 + j)))

lemma fejerTest_coe (n : ℕ) (t : ℝ) :
    fejerTest n (t : AddCircle (2 * π)) =
      ((2 * Real.sin ((n + 1) * t) * ∑ j ∈ Finset.Icc 1 n, Real.sin (j * t) / j : ℝ) : ℂ) := by
  simp only [fejerTest, ContinuousMap.coe_sum, Finset.sum_apply, ContinuousMap.coe_smul,
    Pi.smul_apply, ContinuousMap.coe_sub, ContinuousMap.coe_add, Pi.sub_apply, Pi.add_apply,
    smul_eq_mul]
  rw [Finset.mul_sum, Complex.ofReal_sum]
  refine Finset.sum_congr rfl fun j hj => ?_
  have hj0 : (j : ℝ) ≠ 0 := by
    have := (Finset.mem_Icc.mp hj).1; positivity
  have hre : ∀ a b c d : ℂ, a + b - c - d = (a + b) - (c + d) := fun a b c d => by ring
  rw [hre, fourier_add_fourier_neg, fourier_add_fourier_neg]
  have e1 : (((n : ℤ) + 1 - j : ℤ) : ℝ) * t = (n + 1) * t - j * t := by push_cast; ring
  have e2 : (((n : ℤ) + 1 + j : ℤ) : ℝ) * t = (n + 1) * t + j * t := by push_cast; ring
  rw [e1, e2, Real.cos_sub, Real.cos_add]
  push_cast
  field_simp
  ring

#print axioms fejerTest_coe

lemma norm_fejerTest_le (C : ℝ)
    (hC : ∀ (M : ℕ) (x : ℝ), |∑ j ∈ Finset.Icc 1 M, Real.sin (j * x) / j| ≤ C) (n : ℕ) :
    ‖fejerTest n‖ ≤ 2 * C := by
  have hC0 : 0 ≤ C := le_trans (abs_nonneg _) (hC 0 0)
  refine (ContinuousMap.norm_le _ (by positivity)).mpr fun x => ?_
  obtain ⟨t, rfl⟩ := QuotientAddGroup.mk_surjective x
  rw [show (QuotientAddGroup.mk t : AddCircle (2 * π)) = (t : AddCircle (2 * π)) from rfl,
    fejerTest_coe, Complex.norm_real, Real.norm_eq_abs, abs_mul, abs_mul]
  have h1 : |Real.sin ((n + 1) * t)| ≤ 1 := Real.abs_sin_le_one _
  have h2 := hC n t
  calc |(2 : ℝ)| * |Real.sin ((n + 1) * t)| * |∑ j ∈ Finset.Icc 1 n, Real.sin (j * t) / j|
      ≤ 2 * 1 * C := by
        rw [abs_two]
        gcongr
    _ = 2 * C := by ring
#print axioms norm_fejerTest_le


lemma partialSum_fejerTest (n : ℕ) :
    partialSum (⇑(fejerTest n)) n 0 = ∑ j ∈ Finset.Icc 1 n, (1 : ℂ) / j := by
  rw [← partialSumAtZeroCLM_apply, fejerTest, map_sum]
  refine Finset.sum_congr rfl fun j hj => ?_
  have hj' := Finset.mem_Icc.mp hj
  simp only [map_smul, map_sub, map_add, partialSumAtZeroCLM_apply, partialSum_fourier_zero,
    Finset.mem_Icc, smul_eq_mul]
  have hj0 : (j : ℂ) ≠ 0 := by exact_mod_cast (show j ≠ 0 by omega)
  split_ifs <;> try omega
  field_simp
  norm_num

#print axioms partialSum_fejerTest

/-- **Carleson's theorem, from Carleson's maximal inequality** (The formula; Why it works,
Steps 0 and 2). Suppose Carleson's maximal inequality holds with some fixed constant `A`: for
every finite-energy signal `g` and every level `α > 0`, the instants where some partial sum of
`g` climbs above `α` have total length at most `A ‖g‖₂² / α²`. Then for every finite-energy
signal `f` the Fourier partial sums `S_N f(x)` converge to `f(x)` at every instant `x` outside
a set of total length zero. -/
theorem carleson_inequality_gives_convergence_almost_everywhere (A : ℝ)
    (hCarleson : ∀ (g : L2Circle) (α : ℝ), 0 < α →
      volume {x : AddCircle (2 * π) | ∃ N : ℕ, α < ‖partialSum (⇑g) N x‖} ≤
        ENNReal.ofReal (A * ‖g‖ ^ 2 / α ^ 2))
    (f : L2Circle) :
    ∀ᵐ x ∂(volume : Measure (AddCircle (2 * π))),
      Tendsto (fun N : ℕ => partialSum (⇑f) N x) atTop (𝓝 (f x)) := by
  have hall := ae_all_iff.2 fun m : ℕ =>
    eventually_close_of_carleson A hCarleson f (ε := 1 / ((m : ℝ) + 1)) Nat.one_div_pos_of_nat
  filter_upwards [hall] with x hx
  rw [Metric.tendsto_nhds]
  intro ε hε
  obtain ⟨m, hm⟩ := exists_nat_one_div_lt hε
  filter_upwards [hx m] with N hN
  rw [dist_eq_norm]
  exact lt_of_le_of_lt hN hm

/-- **Summable energy errors give convergence almost everywhere** (Why it works, Step 1).
For a finite-energy signal `f` and any list of cut-offs `N_j` whose energy errors
`‖f - S_{N_j} f‖₂² = (1/2π) ∫ |f(x) - S_{N_j} f(x)|² dx` add up to a finite total, the partial
sums `S_{N_j} f(x)` converge to `f(x)` as `j → ∞` at every instant outside a set of total
length zero. -/
theorem summable_energy_errors_give_convergence_almost_everywhere (f : L2Circle)
    (Nj : ℕ → ℕ)
    (hsum : Summable fun j : ℕ =>
      ∫ x, ‖f x - partialSum (⇑f) (Nj j) x‖ ^ 2 ∂(@AddCircle.haarAddCircle (2 * π) _)) :
    ∀ᵐ x ∂(volume : Measure (AddCircle (2 * π))),
      Tendsto (fun j : ℕ => partialSum (⇑f) (Nj j) x) atTop (𝓝 (f x)) := by
  rw [ae_volume_iff]
  set μ := @AddCircle.haarAddCircle (2 * π) _ with hμ
  set h : ℕ → AddCircle (2 * π) → ℂ := fun j x => f x - partialSum (⇑f) (Nj j) x with hh
  have hmem : ∀ j, MemLp (h j) 2 μ := fun j => (Lp.memLp f).sub (memLp_partialSum _ _)
  have hint : ∀ j, Integrable (fun x => ‖h j x‖ ^ 2) μ := fun j =>
    (hmem j).integrable_norm_pow (by norm_num)
  have hmeas : ∀ j, AEMeasurable (fun x => ENNReal.ofReal (‖h j x‖ ^ 2)) μ := fun j =>
    ((hmem j).aestronglyMeasurable.aemeasurable.norm.pow_const 2).ennreal_ofReal
  have hlint : ∀ j, ∫⁻ x, ENNReal.ofReal (‖h j x‖ ^ 2) ∂μ =
      ENNReal.ofReal (∫ x, ‖h j x‖ ^ 2 ∂μ) := fun j =>
    (ofReal_integral_eq_lintegral_ofReal (hint j) (ae_of_all _ fun x => by positivity)).symm
  have htot : ∫⁻ x, ∑' j, ENNReal.ofReal (‖h j x‖ ^ 2) ∂μ ≠ ⊤ := by
    rw [lintegral_tsum hmeas]
    simp_rw [hlint]
    rw [← ENNReal.ofReal_tsum_of_nonneg (fun j => integral_nonneg fun x => pow_nonneg (norm_nonneg _) 2) hsum]
    exact ENNReal.ofReal_ne_top
  filter_upwards [ae_lt_top' (AEMeasurable.tsum hmeas) htot] with x hx
  have h1 := ENNReal.tendsto_atTop_zero_of_tsum_ne_top hx.ne
  have h2 : Tendsto (fun j => ‖h j x‖ ^ 2) atTop (𝓝 0) := by
    have := (ENNReal.tendsto_toReal ENNReal.zero_ne_top).comp h1
    have e : ∀ j, (ENNReal.ofReal (‖h j x‖ ^ 2)).toReal = ‖h j x‖ ^ 2 := fun j =>
      ENNReal.toReal_ofReal (pow_nonneg (norm_nonneg _) 2)
    simpa only [Function.comp_def, e, ENNReal.toReal_zero] using this
  have h3 : Tendsto (fun j => ‖h j x‖) atTop (𝓝 0) := by
    have := (Real.continuous_sqrt.tendsto 0).comp h2
    simpa [Function.comp_def, Real.sqrt_sq (norm_nonneg _)] using this
  rw [tendsto_iff_norm_sub_tendsto_zero]
  simpa [hh, norm_sub_rev] using h3

/-- **A continuous signal whose series diverges at a point** (Why it works, Step 4: Fejér's form
of du Bois-Reymond's example). Given the classical fact that the sums `∑_{j=1}^{M} sin(jx)/j`
stay below some fixed bound `C` in size for every `M` and every `x`, there is a continuous
signal `f` on the circle with `f(0) = 0` whose partial sums at `0` grow without bound. -/
theorem continuous_signal_with_divergent_series_at_a_point (C : ℝ)
    (hC : ∀ (M : ℕ) (x : ℝ), |∑ j ∈ Finset.Icc 1 M, Real.sin (j * x) / j| ≤ C) :
    ∃ f : C(AddCircle (2 * π), ℂ), f 0 = 0 ∧
      ∀ B : ℝ, ∃ N : ℕ, B < ‖partialSum (⇑f) N 0‖ := by
  by_contra hne
  push Not at hne
  -- Every continuous signal has bounded partial sums at `0`.
  have hbdd : ∀ f : C(AddCircle (2 * π), ℂ), ∃ B, ∀ N, ‖partialSumAtZeroCLM N f‖ ≤ B := by
    intro f
    set g : C(AddCircle (2 * π), ℂ) := f - ContinuousMap.const _ (f 0) with hg
    have hg0 : g 0 = 0 := by simp [hg]
    obtain ⟨B, hB⟩ := hne g hg0
    refine ⟨B + ‖f 0‖, fun N => ?_⟩
    have hconst : ContinuousMap.const (AddCircle (2 * π)) (f 0) = f 0 • fourier 0 := by
      ext x; simp
    have h1 : partialSumAtZeroCLM N g = partialSumAtZeroCLM N f - f 0 := by
      rw [hg, map_sub, hconst, map_smul, partialSumAtZeroCLM_apply (f := fourier 0),
        partialSum_fourier_zero, ite_eq_left_iff.mpr (fun h => absurd (by simp) h), smul_eq_mul,
        mul_one]
    have h2 := hB N
    rw [← partialSumAtZeroCLM_apply, h1] at h2
    calc ‖partialSumAtZeroCLM N f‖ = ‖(partialSumAtZeroCLM N f - f 0) + f 0‖ := by ring_nf
      _ ≤ ‖partialSumAtZeroCLM N f - f 0‖ + ‖f 0‖ := norm_add_le _ _
      _ ≤ B + ‖f 0‖ := by gcongr
  obtain ⟨C', hC'⟩ := banach_steinhaus hbdd
  -- But the test polynomials force the harmonic numbers to stay bounded.
  have hH : ∀ n : ℕ, (harmonic n : ℝ) ≤ C' * (2 * C) := by
    intro n
    have h1 := (partialSumAtZeroCLM n).le_opNorm (fejerTest n)
    rw [partialSumAtZeroCLM_apply, partialSum_fejerTest] at h1
    have h2 : ‖∑ j ∈ Finset.Icc 1 n, (1 : ℂ) / j‖ = (harmonic n : ℝ) := by
      have e : (∑ j ∈ Finset.Icc 1 n, (1 : ℂ) / j) =
          ((∑ j ∈ Finset.Icc 1 n, ((j : ℝ))⁻¹ : ℝ) : ℂ) := by
        push_cast; simp [one_div]
      rw [e, Complex.norm_real, Real.norm_of_nonneg (Finset.sum_nonneg fun _ _ => by positivity),
        harmonic_eq_sum_Icc]
      push_cast; rfl
    rw [h2] at h1
    calc (harmonic n : ℝ) ≤ ‖partialSumAtZeroCLM n‖ * ‖fejerTest n‖ := h1
      _ ≤ C' * (2 * C) := by
        exact mul_le_mul (hC' n) (norm_fejerTest_le C hC n) (norm_nonneg _)
          (le_trans (norm_nonneg _) (hC' 0))
  obtain ⟨n, hn⟩ := exists_nat_gt (Real.exp (C' * (2 * C)))
  have h1 := log_add_one_le_harmonic n
  push_cast at h1
  have h2 := hH n
  have h3 : C' * (2 * C) < Real.log (n + 1) := by
    rw [Real.lt_log_iff_exp_lt (by positivity)]
    linarith
  linarith

/-! The card's whole-number worked examples. -/

-- The octave stack at t = 0: after K octaves the partial sum is the harmonic number H_K;
-- the chart reads 1.5000 V at K = 2 and 2.0833 V at K = 4.
example : harmonic 2 = 3 / 2 := by
  simp [harmonic, Finset.sum_range_succ]; norm_num
example : harmonic 4 = 25 / 12 := by
  simp [harmonic, Finset.sum_range_succ]; norm_num

-- At t = 1/660 s, x = 2π/3: wave 2^(k-1) has phase 2^(k-1) mod 3, which is never 0, so every
-- cosine is -1/2 and every term is -1/(2k). Checked for the first 1,024 octaves.
example : ∀ k : Fin 1024, 2 ^ (k : ℕ) % 3 ≠ 0 := by
  intro k h
  have h3 : 3 ∣ 2 ^ (k : ℕ) := Nat.dvd_of_mod_eq_zero h
  have := (Nat.Prime.dvd_of_dvd_pow Nat.prime_three h3)
  omega

-- Fejér's blocks: M_k = 2^(k^3), so M_2 = 256, and block k (frequencies M_k to 3 M_k) ends
-- before block k + 1 starts, for the nine blocks in the card's bar chart.
example : 2 ^ (2 ^ 3) = 256 := by
  norm_num
example : ∀ k : Fin 9, 3 * 2 ^ ((k : ℕ) + 1) ^ 3 < 2 ^ ((k : ℕ) + 2) ^ 3 := by
  intro k
  have h : ((k : ℕ) + 1) ^ 3 + 2 ≤ ((k : ℕ) + 2) ^ 3 := by
    generalize (k : ℕ) = n
    ring_nf
    nlinarith [Nat.zero_le n, Nat.zero_le (n ^ 2)]
  have h2 : 2 ^ (((k : ℕ) + 1) ^ 3 + 2) ≤ 2 ^ (((k : ℕ) + 2) ^ 3) :=
    Nat.pow_le_pow_right (by norm_num) h
  have h3 : 0 < 2 ^ (((k : ℕ) + 1) ^ 3) := by positivity
  rw [pow_add] at h2
  omega

-- Fejér's block 1 (M_1 = 2): the partial sum at 0 halfway through it is H_2 = 1.5000.
example : harmonic (2 ^ (1 ^ 3)) / 1 ^ 2 = 3 / 2 := by
  simp [harmonic, Finset.sum_range_succ]; norm_num

#print axioms carleson_inequality_gives_convergence_almost_everywhere
#print axioms summable_energy_errors_give_convergence_almost_everywhere
#print axioms continuous_signal_with_divergent_series_at_a_point

end CarlesonInOutline
