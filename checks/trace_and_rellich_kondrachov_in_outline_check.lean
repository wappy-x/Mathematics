-- Boundary values and compactness: the left-edge trace bound on the unit square with constant 2, its sharp constant coth 1, and the Rellich–Kondrachov compactness in cosine-mode form.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Normed.Lp.lpSpace
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Complex.Trigonometric
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.MeasureTheory.Integral.DominatedConvergence
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Real Filter Topology

theorem trace_helper_sharp (v v' : ℝ → ℝ)
    (hd : ∀ x ∈ Set.Icc (0 : ℝ) 1, HasDerivWithinAt v (v' x) (Set.Icc 0 1) x)
    (hc : ContinuousOn v' (Set.Icc (0 : ℝ) 1)) :
    Real.sinh 1 / Real.cosh 1 * v 0 ^ 2 ≤ ∫ x in (0 : ℝ)..1, (v x ^ 2 + v' x ^ 2) := by
  set a : ℝ → ℝ := fun x => Real.sinh (1 - x) / Real.cosh (1 - x) with ha_def
  have ha_deriv : ∀ x, HasDerivAt a (a x ^ 2 - 1) x := by
    intro x
    have h1 : HasDerivAt (fun x : ℝ => 1 - x) (-1) x := by
      simpa using (hasDerivAt_id x).const_sub 1
    have hs := (Real.hasDerivAt_sinh (1 - x)).comp x h1
    have hc' := (Real.hasDerivAt_cosh (1 - x)).comp x h1
    have hq := hs.div hc' (Real.cosh_pos _).ne'
    have hq' : HasDerivAt a _ x := hq
    refine hq'.congr_deriv ?_
    have hpos := (Real.cosh_pos (1 - x)).ne'
    simp only [ha_def, Function.comp_apply]
    field_simp
    ring
  have hvc : ContinuousOn v (Set.Icc (0 : ℝ) 1) := fun x hx => (hd x hx).continuousWithinAt
  have hac : Continuous a := continuous_iff_continuousAt.2 fun x => (ha_deriv x).continuousAt
  set F : ℝ → ℝ := fun x => -(a x * v x ^ 2) with hF
  set f : ℝ → ℝ := fun x => (1 - a x ^ 2) * v x ^ 2 - 2 * a x * v x * v' x with hf
  have hFc : ContinuousOn F (Set.Icc (0 : ℝ) 1) :=
    ((hac.continuousOn).mul (hvc.pow 2)).neg
  have hFd : ∀ x ∈ Set.Ioo (0 : ℝ) 1, HasDerivWithinAt F (f x) (Set.Ioi x) x := by
    intro x hx
    have hv : HasDerivAt v (v' x) x :=
      (hd x (Set.Ioo_subset_Icc_self hx)).hasDerivAt (Icc_mem_nhds hx.1 hx.2)
    have := ((ha_deriv x).mul (hv.pow 2)).neg
    refine HasDerivAt.hasDerivWithinAt ?_
    convert this using 1
    simp only [hf, Pi.pow_apply]
    ring
  have huIcc : Set.uIcc (0 : ℝ) 1 = Set.Icc 0 1 := Set.uIcc_of_le zero_le_one
  have hfi : IntervalIntegrable f MeasureTheory.volume 0 1 := by
    apply ContinuousOn.intervalIntegrable
    rw [huIcc]
    exact (((continuousOn_const.sub (hac.continuousOn.pow 2)).mul (hvc.pow 2)).sub
      (((continuousOn_const.mul hac.continuousOn).mul hvc).mul hc))
  have hgi : IntervalIntegrable (fun x => v x ^ 2 + v' x ^ 2) MeasureTheory.volume 0 1 := by
    apply ContinuousOn.intervalIntegrable
    rw [huIcc]
    exact (hvc.pow 2).add (hc.pow 2)
  have hFTC := intervalIntegral.integral_eq_sub_of_hasDeriv_right_of_le zero_le_one hFc hFd hfi
  have hval : F 1 - F 0 = Real.sinh 1 / Real.cosh 1 * v 0 ^ 2 := by
    simp [hF, ha_def]
  rw [← hval, ← hFTC]
  apply intervalIntegral.integral_mono_on zero_le_one hfi hgi
  intro x _
  simp only [hf]
  nlinarith [sq_nonneg (a x * v x + v' x)]

theorem half_le_tanh_one : (1 : ℝ) / 2 ≤ Real.sinh 1 / Real.cosh 1 := by
  rw [le_div_iff₀ (Real.cosh_pos 1), Real.sinh_eq, Real.cosh_eq]
  have h1 : 2 ≤ Real.exp 1 := by linarith [Real.add_one_le_exp (1 : ℝ)]
  have h2 : Real.exp (-1) * Real.exp 1 = 1 := by rw [← Real.exp_add]; simp
  have h3 : 0 < Real.exp (-1) := Real.exp_pos _
  nlinarith

theorem lp_two_norm_sq (x : lp (fun _ : ℕ => ℝ) 2) : ‖x‖ ^ 2 = ∑' k, x k ^ 2 := by
  have h := lp.norm_rpow_eq_tsum (p := 2) (by norm_num) x
  have h2 : (2 : ENNReal).toReal = 2 := by norm_num
  rw [h2] at h
  simpa [Real.rpow_two, Real.norm_eq_abs, sq_abs] using h

theorem mode_tail_bound (x : ℕ → ℝ) (M : ℝ)
    (hs : Summable fun k : ℕ => (1 + (k : ℝ) ^ 2 * π ^ 2) * x k ^ 2)
    (hb : ∑' k : ℕ, (1 + (k : ℝ) ^ 2 * π ^ 2) * x k ^ 2 ≤ M) (N : ℕ) :
    Summable (fun k : ℕ => x k ^ 2) ∧
    (1 + (N : ℝ) ^ 2 * π ^ 2) * ∑' k : ℕ, x (k + N) ^ 2 ≤ M := by
  set w : ℕ → ℝ := fun k => 1 + (k : ℝ) ^ 2 * π ^ 2 with hw
  have hw1 : ∀ k, 1 ≤ w k := fun k => by simp only [hw]; nlinarith [sq_nonneg (k : ℝ), sq_nonneg π]
  have hsq : Summable (fun k : ℕ => x k ^ 2) :=
    Summable.of_nonneg_of_le (fun k => sq_nonneg _)
      (fun k => le_mul_of_one_le_left (sq_nonneg _) (hw1 k)) hs
  refine ⟨hsq, ?_⟩
  have hs' : Summable (fun k : ℕ => w (k + N) * x (k + N) ^ 2) := (summable_nat_add_iff N).mpr hs
  have hmono : ∀ k : ℕ, w N * x (k + N) ^ 2 ≤ w (k + N) * x (k + N) ^ 2 := by
    intro k
    apply mul_le_mul_of_nonneg_right _ (sq_nonneg _)
    simp only [hw]
    have : (N : ℝ) ≤ ((k + N : ℕ) : ℝ) := by exact_mod_cast Nat.le_add_left N k
    have hN0 : (0 : ℝ) ≤ N := Nat.cast_nonneg N
    nlinarith [sq_nonneg π, mul_le_mul this this hN0 (by linarith)]
  have hs'' : Summable (fun k : ℕ => w N * x (k + N) ^ 2) :=
    Summable.of_nonneg_of_le (fun k => mul_nonneg (by linarith [hw1 N]) (sq_nonneg _)) hmono hs'
  have hsplit := hs.sum_add_tsum_nat_add N
  have hhead : 0 ≤ ∑ i ∈ Finset.range N, w i * x i ^ 2 :=
    Finset.sum_nonneg fun i _ => mul_nonneg (by linarith [hw1 i]) (sq_nonneg _)
  calc w N * ∑' k : ℕ, x (k + N) ^ 2 = ∑' k : ℕ, w N * x (k + N) ^ 2 := by
        rw [tsum_mul_left]
    _ ≤ ∑' k : ℕ, w (k + N) * x (k + N) ^ 2 := hs''.tsum_le_tsum hmono hs'
    _ ≤ ∑' k : ℕ, w k * x k ^ 2 := by
        simp only [hw] at hsplit ⊢
        linarith
    _ ≤ M := hb

/-- Trace theorem on the plate's left edge (Steps 1 and 2): for a field `u` on the closed unit
square, continuous up to the edge, with a continuous slope `ux` in `x`, the edge integral of `u²`
along `x = 0` is at most twice the inside integral of `u² + u_x²`. -/
theorem trace_bound_left_edge (u ux : ℝ → ℝ → ℝ)
    (hu : ContinuousOn (Function.uncurry u) (Set.Icc (0 : ℝ) 1 ×ˢ Set.Icc (0 : ℝ) 1))
    (hux : ContinuousOn (Function.uncurry ux) (Set.Icc (0 : ℝ) 1 ×ˢ Set.Icc (0 : ℝ) 1))
    (hderiv : ∀ y ∈ Set.Icc (0 : ℝ) 1, ∀ x ∈ Set.Icc (0 : ℝ) 1,
      HasDerivWithinAt (fun x => u x y) (ux x y) (Set.Icc 0 1) x) :
    ∫ y in (0 : ℝ)..1, u 0 y ^ 2
      ≤ 2 * ∫ y in (0 : ℝ)..1, ∫ x in (0 : ℝ)..1, (u x y ^ 2 + ux x y ^ 2) := by
  set P : ℝ → ℝ := fun t => (Set.projIcc (0 : ℝ) 1 zero_le_one t : ℝ) with hPdef
  have hP : ∀ t, P t ∈ Set.Icc (0 : ℝ) 1 := fun t => (Set.projIcc (0 : ℝ) 1 zero_le_one t).2
  have hPc : Continuous P := continuous_subtype_val.comp continuous_projIcc
  have hPid : ∀ t ∈ Set.Icc (0 : ℝ) 1, P t = t := fun t ht => by
    simp [hPdef, Set.projIcc_of_mem _ ht]
  have huIcc : Set.uIcc (0 : ℝ) 1 = Set.Icc 0 1 := Set.uIcc_of_le zero_le_one
  set g : ℝ → ℝ → ℝ := fun y x => u (P x) (P y) ^ 2 + ux (P x) (P y) ^ 2 with hg
  have hgc : Continuous (Function.uncurry g) := by
    have hmap : Continuous (fun p : ℝ × ℝ => (P p.2, P p.1)) :=
      (hPc.comp continuous_snd).prodMk (hPc.comp continuous_fst)
    have hmem : ∀ p : ℝ × ℝ, (P p.2, P p.1) ∈ Set.Icc (0 : ℝ) 1 ×ˢ Set.Icc (0 : ℝ) 1 :=
      fun p => ⟨hP _, hP _⟩
    have h1 := hu.comp_continuous hmap hmem
    have h2 := hux.comp_continuous hmap hmem
    exact (h1.pow 2).add (h2.pow 2)
  have hJ : Continuous fun y => ∫ x in (0 : ℝ)..1, g y x :=
    intervalIntegral.continuous_parametric_intervalIntegral_of_continuous' hgc 0 1
  have hIJ : Set.EqOn (fun y => ∫ x in (0 : ℝ)..1, (u x y ^ 2 + ux x y ^ 2))
      (fun y => ∫ x in (0 : ℝ)..1, g y x) (Set.Icc 0 1) := by
    intro y hy
    apply intervalIntegral.integral_congr
    intro x hx
    rw [huIcc] at hx
    simp [hg, hPid x hx, hPid y hy]
  have hIc : ContinuousOn (fun y => ∫ x in (0 : ℝ)..1, (u x y ^ 2 + ux x y ^ 2))
      (Set.Icc 0 1) := hJ.continuousOn.congr hIJ
  have hLc : ContinuousOn (fun y => u 0 y ^ 2) (Set.Icc 0 1) := by
    have h := hu.comp (continuousOn_const.prodMk continuousOn_id)
      (fun y hy => ⟨⟨le_refl (0 : ℝ), zero_le_one⟩, hy⟩)
    exact h.pow 2
  rw [← intervalIntegral.integral_const_mul]
  apply intervalIntegral.integral_mono_on zero_le_one
  · apply ContinuousOn.intervalIntegrable
    rw [huIcc]
    exact hLc
  · apply ContinuousOn.intervalIntegrable
    rw [huIcc]
    exact continuousOn_const.mul hIc
  · intro y hy
    have hc : ContinuousOn (fun x => ux x y) (Set.Icc (0 : ℝ) 1) :=
      hux.comp (continuousOn_id.prodMk continuousOn_const) (fun x hx => ⟨hx, hy⟩)
    have h := trace_helper_sharp (fun x => u x y) (fun x => ux x y) (hderiv y hy) hc
    have ht := half_le_tanh_one
    have hsq := sq_nonneg (u 0 y)
    nlinarith [mul_le_mul_of_nonneg_right ht hsq]

/-- The best trace constant for the left edge is `coth 1`: every field `u` that is continuously
differentiable on `[0, 1]` (slope `u'`) has `u(0)² ≤ coth 1 · ∫₀¹ (u² + u'²)`, and no smaller
constant works for all such fields. -/
theorem best_trace_constant_is_coth_one :
    IsLeast {C : ℝ | ∀ u u' : ℝ → ℝ,
        (∀ x ∈ Set.Icc (0 : ℝ) 1, HasDerivWithinAt u (u' x) (Set.Icc 0 1) x) →
        ContinuousOn u' (Set.Icc (0 : ℝ) 1) →
        u 0 ^ 2 ≤ C * ∫ x in (0 : ℝ)..1, (u x ^ 2 + u' x ^ 2)}
      (Real.cosh 1 / Real.sinh 1) := by
  have hs : 0 < Real.sinh 1 := Real.sinh_pos_iff.mpr one_pos
  have hc1 : 0 < Real.cosh 1 := Real.cosh_pos 1
  constructor
  · intro u u' hd hc
    have h := trace_helper_sharp u u' hd hc
    rw [div_mul_eq_mul_div, div_le_iff₀ hc1] at h
    rw [div_mul_eq_mul_div, le_div_iff₀ hs]
    linarith
  · intro C hC
    have h1 : ∀ x : ℝ, HasDerivAt (fun x : ℝ => 1 - x) (-1) x := fun x => by
      simpa using (hasDerivAt_id x).const_sub 1
    have hdu : ∀ x : ℝ, HasDerivAt (fun x => Real.cosh (1 - x)) (-Real.sinh (1 - x)) x := by
      intro x
      exact ((Real.hasDerivAt_cosh (1 - x)).comp x (h1 x)).congr_deriv (by ring)
    have hds : ∀ x : ℝ, HasDerivAt (fun x => Real.sinh (1 - x)) (-Real.cosh (1 - x)) x := by
      intro x
      exact ((Real.hasDerivAt_sinh (1 - x)).comp x (h1 x)).congr_deriv (by ring)
    have hu := hC (fun x => Real.cosh (1 - x)) (fun x => -Real.sinh (1 - x))
      (fun x _ => (hdu x).hasDerivWithinAt)
      ((Real.continuous_sinh.comp (continuous_const.sub continuous_id)).neg.continuousOn)
    have hint : ∫ x in (0 : ℝ)..1, (Real.cosh (1 - x) ^ 2 + (-Real.sinh (1 - x)) ^ 2)
        = Real.sinh 1 * Real.cosh 1 := by
      have hF : ∀ x ∈ Set.uIcc (0 : ℝ) 1, HasDerivAt
          (fun x => -(Real.sinh (1 - x) * Real.cosh (1 - x)))
          (Real.cosh (1 - x) ^ 2 + (-Real.sinh (1 - x)) ^ 2) x := by
        intro x _
        have := ((hds x).mul (hdu x)).neg
        convert this using 1
        ring
      rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hF]
      · simp
      · apply Continuous.intervalIntegrable
        fun_prop
    rw [hint] at hu
    simp only [sub_zero] at hu
    rw [div_le_iff₀ hs]
    have : Real.cosh 1 * Real.cosh 1 ≤ (C * Real.sinh 1) * Real.cosh 1 := by nlinarith
    exact le_of_mul_le_mul_right this hc1

/-- Rellich–Kondrachov on an interval, by modes (Step 4): if a list of fields has cosine
coefficients `c n` with bounded energy `∑ₖ (1 + k²π²) c_k² ≤ M`, then some sub-list converges in
the average-square (ℓ², equivalently L²) distance. -/
theorem rellich_kondrachov_by_modes (c : ℕ → lp (fun _ : ℕ => ℝ) 2) (M : ℝ)
    (hsum : ∀ n, Summable fun k : ℕ => (1 + (k : ℝ) ^ 2 * π ^ 2) * (c n k) ^ 2)
    (hbd : ∀ n, ∑' k : ℕ, (1 + (k : ℝ) ^ 2 * π ^ 2) * (c n k) ^ 2 ≤ M) :
    ∃ φ : ℕ → ℕ, StrictMono φ ∧
      ∃ L : lp (fun _ : ℕ => ℝ) 2, Tendsto (fun j => c (φ j)) atTop (𝓝 L) := by
  set s := Set.range c with hsdef
  have hw1 : ∀ k : ℕ, 1 ≤ 1 + (k : ℝ) ^ 2 * π ^ 2 := fun k => by
    nlinarith [sq_nonneg (k : ℝ), sq_nonneg π]
  have hM : 0 ≤ M := le_trans (tsum_nonneg fun k =>
    mul_nonneg (by linarith [hw1 k]) (sq_nonneg _)) (hbd 0)
  -- each coordinate square is at most M
  have hcoord : ∀ n i, c n i ^ 2 ≤ M := by
    intro n i
    have hs := hsum n
    calc c n i ^ 2 ≤ (1 + (i : ℝ) ^ 2 * π ^ 2) * c n i ^ 2 :=
          le_mul_of_one_le_left (sq_nonneg _) (hw1 i)
      _ ≤ ∑' k : ℕ, (1 + (k : ℝ) ^ 2 * π ^ 2) * (c n k) ^ 2 :=
          hs.le_tsum i (fun j _ => mul_nonneg (by linarith [hw1 j]) (sq_nonneg _))
      _ ≤ M := hbd n
  have htb : TotallyBounded s := by
    apply Metric.totallyBounded_of_finite_discretization
    intro ε hε
    have hε2 : 0 < ε ^ 2 := by positivity
    obtain ⟨N, hN⟩ := exists_nat_gt (8 * M / ε ^ 2)
    set wN : ℝ := 1 + (N : ℝ) ^ 2 * π ^ 2 with hwN
    have hwNge : (N : ℝ) + 1 ≤ wN := by
      have hN0 : (0 : ℝ) ≤ N := Nat.cast_nonneg N
      have hpi : (1 : ℝ) ≤ π ^ 2 := by nlinarith [Real.two_le_pi]
      rcases Nat.eq_zero_or_pos N with h0 | hpos
      · simp [hwN, h0]
      · have h1 : (1 : ℝ) ≤ N := by exact_mod_cast hpos
        simp only [hwN]
        nlinarith
    have hwN8 : 8 * M < wN * ε ^ 2 := by
      have := (div_lt_iff₀ hε2).mp hN
      nlinarith
    have hwNpos : 0 < wN := by linarith [hw1 N]
    set δ : ℝ := ε / (2 * ((N : ℝ) + 1)) with hδ
    have hδpos : 0 < δ := by positivity
    have hNδ : (N : ℝ) * δ ^ 2 ≤ ε ^ 2 / 4 := by
      have hN1 : (0 : ℝ) < (N : ℝ) + 1 := by positivity
      have hδ' : δ * (2 * ((N : ℝ) + 1)) = ε := by
        simp only [hδ]; field_simp
      have hNle : (N : ℝ) ≤ ((N : ℝ) + 1) ^ 2 := by nlinarith
      nlinarith [mul_le_mul_of_nonneg_right hNle (sq_nonneg δ)]
    set K : ℤ := ⌈(M + 1) / δ⌉ with hK
    let F0 : s → (Fin N → ℤ) := fun x i => ⌊(x : lp (fun _ : ℕ => ℝ) 2) i / δ⌋
    have hrange : Set.range F0 ⊆ Set.pi Set.univ (fun _ => Set.Icc (-K) K) := by
      rintro _ ⟨⟨x, n, rfl⟩, rfl⟩ i _
      have hsq := hcoord n i
      have hab : |c n i| ≤ M + 1 := by
        rcases le_or_gt (|c n i|) 1 with h | h
        · linarith
        · have : |c n i| ≤ c n i ^ 2 := by
            rw [← sq_abs]; nlinarith
          linarith
      have habs := abs_le.mp hab
      have hKr : (M + 1) / δ ≤ (K : ℝ) := Int.le_ceil _
      have hdiv1 : c n i / δ ≤ (M + 1) / δ := div_le_div_of_nonneg_right habs.2 hδpos.le
      have hdiv2 : -((M + 1) / δ) ≤ c n i / δ := by
        rw [← neg_div]; exact div_le_div_of_nonneg_right habs.1 hδpos.le
      constructor
      · have h1 := Int.lt_floor_add_one (c n i / δ)
        have : ((-K : ℤ) : ℝ) - 1 < (⌊c n i / δ⌋ : ℝ) := by push_cast; linarith
        have : (-K : ℤ) - 1 < ⌊c n i / δ⌋ := by exact_mod_cast this
        show -K ≤ ⌊c n i / δ⌋
        omega
      · have h1 := Int.floor_le (c n i / δ)
        have : (⌊c n i / δ⌋ : ℝ) ≤ (K : ℝ) := by linarith
        show ⌊c n i / δ⌋ ≤ K
        exact_mod_cast this
    have hfin : (Set.range F0).Finite :=
      (Set.Finite.pi (fun _ => Set.finite_Icc (-K) K)).subset hrange
    refine ⟨Set.range F0, hfin.fintype, Set.rangeFactorization F0, ?_⟩
    rintro ⟨_, n, rfl⟩ ⟨_, m, rfl⟩ hxy
    have hF : F0 ⟨c n, n, rfl⟩ = F0 ⟨c m, m, rfl⟩ := congrArg Subtype.val hxy
    have hclose : ∀ i < N, (c n i - c m i) ^ 2 ≤ δ ^ 2 := by
      intro i hi
      have h := congrFun hF ⟨i, hi⟩
      have h2 := Int.abs_sub_lt_one_of_floor_eq_floor h
      rw [← sub_div, abs_div, abs_of_pos hδpos, div_lt_one hδpos] at h2
      have := abs_lt.mp h2
      nlinarith
    obtain ⟨hsn, htn⟩ := mode_tail_bound (fun k => c n k) M (hsum n) (hbd n) N
    obtain ⟨hsm, htm⟩ := mode_tail_bound (fun k => c m k) M (hsum m) (hbd m) N
    have hd : Summable (fun k : ℕ => (c n k - c m k) ^ 2) :=
      Summable.of_nonneg_of_le (fun k => sq_nonneg _)
        (fun k => by nlinarith [sq_nonneg (c n k + c m k)]) ((hsn.add hsm).mul_left 2)
    have hdist : dist (c n) (c m) ^ 2 = ∑' k, (c n k - c m k) ^ 2 := by
      rw [dist_eq_norm, lp_two_norm_sq]
      simp
    have hsplit := hd.sum_add_tsum_nat_add N
    have hhead : ∑ i ∈ Finset.range N, (c n i - c m i) ^ 2 ≤ ε ^ 2 / 4 := by
      calc ∑ i ∈ Finset.range N, (c n i - c m i) ^ 2 ≤ ∑ i ∈ Finset.range N, δ ^ 2 :=
            Finset.sum_le_sum fun i hi => hclose i (Finset.mem_range.mp hi)
        _ = (N : ℝ) * δ ^ 2 := by simp
        _ ≤ ε ^ 2 / 4 := hNδ
    have hsn' : Summable (fun k : ℕ => c n (k + N) ^ 2) := (summable_nat_add_iff N).mpr hsn
    have hsm' : Summable (fun k : ℕ => c m (k + N) ^ 2) := (summable_nat_add_iff N).mpr hsm
    have hd' : Summable (fun k : ℕ => (c n (k + N) - c m (k + N)) ^ 2) :=
      (summable_nat_add_iff N).mpr hd
    have htail : ∑' k : ℕ, (c n (k + N) - c m (k + N)) ^ 2
        ≤ 2 * ∑' k : ℕ, c n (k + N) ^ 2 + 2 * ∑' k : ℕ, c m (k + N) ^ 2 := by
      rw [← tsum_mul_left, ← tsum_mul_left, ← (hsn'.mul_left 2).tsum_add (hsm'.mul_left 2)]
      exact hd'.tsum_le_tsum (fun k => by nlinarith [sq_nonneg (c n (k + N) + c m (k + N))])
        ((hsn'.mul_left 2).add (hsm'.mul_left 2))
    have htail2 : ∑' k : ℕ, (c n (k + N) - c m (k + N)) ^ 2 < ε ^ 2 / 2 := by
      have h4 : wN * ∑' k : ℕ, (c n (k + N) - c m (k + N)) ^ 2 ≤ 4 * M := by
        simp only [hwN]
        nlinarith
      nlinarith
    have hlt : dist (c n) (c m) ^ 2 < ε ^ 2 := by
      rw [hdist, ← hsplit]
      linarith
    have hd0 := dist_nonneg (x := c n) (y := c m)
    nlinarith
  have hcpt : IsCompact (closure s) := htb.closure.isCompact_of_isClosed isClosed_closure
  obtain ⟨L, _, φ, hφ, hlim⟩ := hcpt.tendsto_subseq (x := c) (fun n => subset_closure ⟨n, rfl⟩)
  exact ⟨φ, hφ, L, hlim⟩

-- Edge integral of w² on the plate: 3600 × 1/2 = 1800.
example : (3600 : ℚ) * (1 / 2) = 1800 := by norm_num

-- Hot layer of width ε, 100 above room at the edge: inside size 10000 ε / 3, edge 10000,
-- ratio 3 / ε: 30, 300, 3000 at ε = 1/10, 1/100, 1/1000.
example : (10000 : ℚ) * (1 / 1000) / 3 = 10 / 3 := by norm_num
example : (10000 : ℚ) / (10000 * (1 / 10) / 3) = 30 := by norm_num
example : (10000 : ℚ) / (10000 * (1 / 100) / 3) = 300 := by norm_num
example : (10000 : ℚ) / (10000 * (1 / 1000) / 3) = 3000 := by norm_num

-- Sliding tent: energy 2/3 (values) + 2 (slopes) = 8/3; squared distance between copies 2 × 2/3 = 4/3.
example : (2 : ℚ) / 3 + 2 = 8 / 3 := by norm_num
example : (2 : ℚ) * (2 / 3) = 4 / 3 := by norm_num

#print axioms trace_helper_sharp
#print axioms half_le_tanh_one
#print axioms lp_two_norm_sq
#print axioms mode_tail_bound
#print axioms trace_bound_left_edge
#print axioms best_trace_constant_is_coth_one
#print axioms rellich_kondrachov_by_modes
