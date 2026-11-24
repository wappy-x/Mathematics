-- Universal approximation: one hidden layer of non-polynomial units comes within any tolerance of a continuous function on a closed, bounded region, and in one input the ReLU join-the-dots network has error at most M h^2 / 8.
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Algebra.Polynomial.Degree.Lemmas
import Mathlib.Topology.MetricSpace.Bounded
import Mathlib

open Finset

/-- `u` is exactly a one-input network with activation `g`. -/
def UANet1 (g : ℝ → ℝ) (u : ℝ → ℝ) : Prop :=
  ∃ (N : ℕ) (a w b : Fin N → ℝ) (c : ℝ), ∀ t, u t = c + ∑ k, a k * g (w k * t + b k)

/-- `u` is a limit of one-input networks, uniformly on every interval `[-R, R]`. -/
def UAApprox1 (g : ℝ → ℝ) (u : ℝ → ℝ) : Prop :=
  ∀ R ε : ℝ, 0 < ε → ∃ v, UANet1 g v ∧ ∀ t ∈ Set.Icc (-R) R, |u t - v t| < ε

theorem uanet1_const (g : ℝ → ℝ) (c : ℝ) : UANet1 g (fun _ => c) :=
  ⟨0, Fin.elim0, Fin.elim0, Fin.elim0, c, fun t => by simp⟩

theorem uanet1_add (g : ℝ → ℝ) {u v : ℝ → ℝ} (hu : UANet1 g u) (hv : UANet1 g v) :
    UANet1 g (fun t => u t + v t) := by
  obtain ⟨N, a, w, b, c, hu⟩ := hu
  obtain ⟨M, a', w', b', c', hv⟩ := hv
  refine ⟨N + M, Fin.append a a', Fin.append w w', Fin.append b b', c + c', fun t => ?_⟩
  simp only
  rw [hu, hv, Fin.sum_univ_add]
  simp only [Fin.append_left, Fin.append_right]
  ring

theorem uanet1_smul (g : ℝ → ℝ) {u : ℝ → ℝ} (r : ℝ) (hu : UANet1 g u) :
    UANet1 g (fun t => r * u t) := by
  obtain ⟨N, a, w, b, c, hu⟩ := hu
  refine ⟨N, fun k => r * a k, w, b, r * c, fun t => ?_⟩
  simp only
  rw [hu, mul_add, Finset.mul_sum]
  simp only [mul_assoc]

theorem uanet1_comp (g : ℝ → ℝ) {u : ℝ → ℝ} (α β : ℝ) (hu : UANet1 g u) :
    UANet1 g (fun t => u (α * t + β)) := by
  obtain ⟨N, a, w, b, c, hu⟩ := hu
  refine ⟨N, a, fun k => w k * α, fun k => w k * β + b k, c, fun t => ?_⟩
  simp only
  rw [hu]
  congr 1
  refine Finset.sum_congr rfl (fun k _ => ?_)
  congr 2
  ring

theorem uanet1_self (g : ℝ → ℝ) : UANet1 g g :=
  ⟨1, fun _ => 1, fun _ => 1, fun _ => 0, 0, fun t => by simp⟩

theorem uaapprox1_of_net (g : ℝ → ℝ) {u : ℝ → ℝ} (hu : UANet1 g u) : UAApprox1 g u :=
  fun _ _ hε => ⟨u, hu, fun t _ => by simpa using hε⟩

theorem uaapprox1_lim (g : ℝ → ℝ) {u : ℝ → ℝ}
    (h : ∀ R ε : ℝ, 0 < ε → ∃ v, UAApprox1 g v ∧ ∀ t ∈ Set.Icc (-R) R, |u t - v t| < ε) :
    UAApprox1 g u := by
  intro R ε hε
  obtain ⟨v, hv, hv'⟩ := h R (ε / 2) (by linarith)
  obtain ⟨w, hw, hw'⟩ := hv R (ε / 2) (by linarith)
  refine ⟨w, hw, fun t ht => ?_⟩
  have h1 := hv' t ht
  have h2 := hw' t ht
  calc |u t - w t| = |(u t - v t) + (v t - w t)| := by ring_nf
    _ ≤ |u t - v t| + |v t - w t| := abs_add_le _ _
    _ < ε := by linarith

theorem uaapprox1_add (g : ℝ → ℝ) {u v : ℝ → ℝ} (hu : UAApprox1 g u) (hv : UAApprox1 g v) :
    UAApprox1 g (fun t => u t + v t) := by
  intro R ε hε
  obtain ⟨u', hu', hu''⟩ := hu R (ε / 2) (by linarith)
  obtain ⟨v', hv', hv''⟩ := hv R (ε / 2) (by linarith)
  refine ⟨_, uanet1_add g hu' hv', fun t ht => ?_⟩
  have h1 := hu'' t ht
  have h2 := hv'' t ht
  calc |u t + v t - (u' t + v' t)| = |(u t - u' t) + (v t - v' t)| := by ring_nf
    _ ≤ |u t - u' t| + |v t - v' t| := abs_add_le _ _
    _ < ε := by linarith

theorem uaapprox1_smul (g : ℝ → ℝ) {u : ℝ → ℝ} (r : ℝ) (hu : UAApprox1 g u) :
    UAApprox1 g (fun t => r * u t) := by
  intro R ε hε
  obtain ⟨u', hu', hu''⟩ := hu R (ε / (|r| + 1)) (by positivity)
  refine ⟨_, uanet1_smul g r hu', fun t ht => ?_⟩
  have h1 := hu'' t ht
  have hr : 0 < |r| + 1 := by positivity
  calc |r * u t - r * u' t| = |r| * |u t - u' t| := by rw [← mul_sub, abs_mul]
    _ ≤ (|r| + 1) * |u t - u' t| := by gcongr; linarith
    _ < (|r| + 1) * (ε / (|r| + 1)) := by gcongr
    _ = ε := by field_simp

theorem uaapprox1_sum (g : ℝ → ℝ) (m : ℕ) (F : ℕ → ℝ → ℝ) (hF : ∀ j < m, UAApprox1 g (F j)) :
    UAApprox1 g (fun t => ∑ j ∈ range m, F j t) := by
  induction m with
  | zero => simpa using uaapprox1_of_net g (uanet1_const g 0)
  | succ m ih =>
    simp only [Finset.sum_range_succ]
    exact uaapprox1_add g (ih fun j hj => hF j (by omega)) (hF m (by omega))

theorem uaapprox1_comp (g : ℝ → ℝ) {u : ℝ → ℝ} (α β : ℝ) (hu : UAApprox1 g u) :
    UAApprox1 g (fun t => u (α * t + β)) := by
  intro R ε hε
  obtain ⟨u', hu', hu''⟩ := hu (|α| * |R| + |β|) ε hε
  refine ⟨_, uanet1_comp g α β hu', fun t ht => hu'' _ ?_⟩
  have h1 : |t| ≤ |R| := by
    rw [abs_le]; constructor <;> cases abs_cases R <;> linarith [ht.1, ht.2]
  have h2 : |α * t + β| ≤ |α| * |R| + |β| := by
    calc |α * t + β| ≤ |α * t| + |β| := abs_add_le _ _
      _ = |α| * |t| + |β| := by rw [abs_mul]
      _ ≤ |α| * |R| + |β| := by gcongr
  exact abs_le.1 h2

/-- The moving average of `u` over a window of length `c`. -/
noncomputable def uaAvg (c : ℝ) (u : ℝ → ℝ) (t : ℝ) : ℝ := (1 / c) * ∫ s in (0 : ℝ)..c, u (t + s)

theorem uaAvg_eq (c : ℝ) {u : ℝ → ℝ} (hu : Continuous u) (t : ℝ) :
    uaAvg c u t = (1 / c) * ((∫ s in (0 : ℝ)..(t + c), u s) - ∫ s in (0 : ℝ)..t, u s) := by
  unfold uaAvg
  rw [intervalIntegral.integral_comp_add_left (fun s => u s) t,
    intervalIntegral.integral_interval_sub_left (hu.intervalIntegrable _ _)
      (hu.intervalIntegrable _ _), add_zero]

theorem uaAvg_hasDerivAt (c : ℝ) {u : ℝ → ℝ} (hu : Continuous u) (t : ℝ) :
    HasDerivAt (uaAvg c u) ((1 / c) * (u (t + c) - u t)) t := by
  have e : uaAvg c u = fun t =>
      (1 / c) * ((∫ s in (0 : ℝ)..(t + c), u s) - ∫ s in (0 : ℝ)..t, u s) :=
    funext (uaAvg_eq c hu)
  rw [e]
  have h1 : HasDerivAt (fun t => ∫ s in (0 : ℝ)..(t + c), u s) (u (t + c)) t := by
    have := (hu.integral_hasStrictDerivAt 0 (t + c)).hasDerivAt
    have h3 := this.comp t ((hasDerivAt_id' t).add_const c)
    simpa [Function.comp_def] using h3
  have h2 : HasDerivAt (fun t => ∫ s in (0 : ℝ)..t, u s) (u t) t :=
    (hu.integral_hasStrictDerivAt 0 t).hasDerivAt
  exact (h1.sub h2).const_mul (1 / c)

theorem uaAvg_contDiff (c : ℝ) {u : ℝ → ℝ} (j : ℕ) (hu : ContDiff ℝ j u) :
    ContDiff ℝ (j + 1 : ℕ) (uaAvg c u) := by
  have hc := hu.continuous
  have hd : deriv (uaAvg c u) = fun t => (1 / c) * (u (t + c) - u t) :=
    funext fun t => (uaAvg_hasDerivAt c hc t).deriv
  rw [Nat.cast_add, Nat.cast_one, contDiff_succ_iff_deriv]
  refine ⟨fun t => (uaAvg_hasDerivAt c hc t).differentiableAt, by simp, ?_⟩
  rw [hd]
  exact contDiff_const.mul ((hu.comp (contDiff_id.add contDiff_const)).sub hu)

theorem uaAvg_continuous (c : ℝ) {u : ℝ → ℝ} (hu : Continuous u) : Continuous (uaAvg c u) :=
  continuous_iff_continuousAt.2 fun t => (uaAvg_hasDerivAt c hu t).continuousAt

theorem uaAvg_close (c : ℝ) (hc : 0 < c) {u : ℝ → ℝ} (hu : Continuous u) (t C η : ℝ)
    (h : ∀ s ∈ Set.Icc 0 c, |u (t + s) - C| ≤ η) : |uaAvg c u t - C| ≤ η := by
  have e : uaAvg c u t - C = (1 / c) * ∫ s in (0 : ℝ)..c, (u (t + s) - C) := by
    unfold uaAvg
    have hi : IntervalIntegrable (fun s => u (t + s)) MeasureTheory.volume 0 c :=
      (hu.comp (continuous_const.add continuous_id)).intervalIntegrable _ _
    rw [intervalIntegral.integral_sub hi intervalIntegrable_const, intervalIntegral.integral_const]
    simp only [sub_zero, smul_eq_mul]
    field_simp
  rw [e, abs_mul, abs_of_pos (by positivity : (0 : ℝ) < 1 / c)]
  have hb : ‖∫ s in (0 : ℝ)..c, (u (t + s) - C)‖ ≤ η * |c - 0| := by
    refine intervalIntegral.norm_integral_le_of_norm_le_const (fun s hs => ?_)
    rw [Set.uIoc_of_le hc.le] at hs
    exact h s ⟨hs.1.le, hs.2⟩
  rw [Real.norm_eq_abs, sub_zero, abs_of_pos hc] at hb
  calc 1 / c * |∫ s in (0 : ℝ)..c, (u (t + s) - C)| ≤ 1 / c * (η * c) := by gcongr
    _ = η := by field_simp

theorem uaapprox1_avg (g : ℝ → ℝ) (c : ℝ) (hc : 0 < c) {u : ℝ → ℝ} (hu : Continuous u)
    (hA : UAApprox1 g u) : UAApprox1 g (uaAvg c u) := by
  apply uaapprox1_lim
  intro R ε hε
  set K := Set.Icc (-(|R| + c)) (|R| + c)
  have hK : IsCompact K := isCompact_Icc
  obtain ⟨δ, hδ, hδ'⟩ := Metric.uniformContinuousOn_iff.1
    (hK.uniformContinuousOn_of_continuous hu.continuousOn) (ε / 2) (by linarith)
  obtain ⟨m, hm⟩ := exists_nat_gt (c / δ)
  have hm0 : (0 : ℝ) < m := lt_of_le_of_lt (by positivity) hm
  have hcm : c / m < δ := by
    rw [div_lt_iff₀ hm0]; rw [div_lt_iff₀ hδ] at hm; linarith
  set x : ℕ → ℝ := fun j => j * (c / m) with hx
  refine ⟨fun t => (1 / c) * ∑ j ∈ range m, (c / m) * u (t + x j), ?_, ?_⟩
  · refine uaapprox1_smul g _ (uaapprox1_sum g m _ (fun j _ => uaapprox1_smul g _ ?_))
    simpa only [one_mul] using uaapprox1_comp g 1 (x j) hA
  · intro t ht
    have hint : ∀ j < m, IntervalIntegrable (fun s => u (t + s)) MeasureTheory.volume (x j) (x (j + 1)) :=
      fun j _ => (hu.comp (continuous_const.add continuous_id)).intervalIntegrable _ _
    have hsplit := intervalIntegral.sum_integral_adjacent_intervals hint
    have hx0 : x 0 = 0 := by simp [hx]
    have hxm : x m = c := by simp only [hx]; field_simp
    rw [hx0, hxm] at hsplit
    have hcell : ∀ j ∈ range m, (c / m) * u (t + x j) = ∫ s in (x j)..(x (j + 1)), u (t + x j) := by
      intro j _
      rw [intervalIntegral.integral_const, smul_eq_mul]
      congr 1; simp only [hx]; push_cast; ring
    simp only
    rw [Finset.sum_congr rfl hcell]
    unfold uaAvg
    rw [← hsplit, ← mul_sub, ← Finset.sum_sub_distrib]
    have hbound : ∀ j ∈ range m, |(∫ s in (x j)..(x (j + 1)), u (t + s)) -
        ∫ s in (x j)..(x (j + 1)), u (t + x j)| ≤ ε / 2 * (c / m) := by
      intro j _
      rw [← intervalIntegral.integral_sub (hint j (by simp_all)) intervalIntegrable_const]
      have hxx : x j ≤ x (j + 1) := by simp only [hx]; push_cast; nlinarith [hc, hm0, div_pos hc hm0]
      have hlen : x (j + 1) - x j = c / m := by simp only [hx]; push_cast; ring
      have := intervalIntegral.norm_integral_le_of_norm_le_const
        (f := fun s => u (t + s) - u (t + x j)) (a := x j) (b := x (j + 1)) (C := ε / 2) ?_
      · rwa [Real.norm_eq_abs, hlen, abs_of_pos (div_pos hc hm0)] at this
      intro s hs
      rw [Set.uIoc_of_le hxx] at hs
      have hxj0 : 0 ≤ x j := by simp only [hx]; positivity
      have hxjc : x (j + 1) ≤ c := by
        simp only [hx]
        have : ((j + 1 : ℕ) : ℝ) ≤ m := by exact_mod_cast (show j + 1 ≤ m by simp_all)
        calc ((j + 1 : ℕ) : ℝ) * (c / m) ≤ m * (c / m) := by gcongr
          _ = c := by field_simp
      have htR : -|R| ≤ t ∧ t ≤ |R| := by
        constructor <;> cases abs_cases R <;> linarith [ht.1, ht.2]
      have h1 : t + s ∈ K := ⟨by linarith [hs.1], by linarith [hs.2]⟩
      have h2 : t + x j ∈ K := ⟨by linarith, by linarith⟩
      have hd : dist (t + s) (t + x j) < δ := by
        rw [Real.dist_eq]
        rw [abs_of_nonneg (by linarith [hs.1])]
        linarith [hs.1, hs.2]
      have := hδ' _ h1 _ h2 hd
      rw [Real.dist_eq] at this
      rw [Real.norm_eq_abs]; exact this.le
    rw [abs_mul, abs_of_pos (by positivity : (0 : ℝ) < 1 / c)]
    calc 1 / c * |∑ j ∈ range m, ((∫ s in (x j)..(x (j + 1)), u (t + s)) -
          ∫ s in (x j)..(x (j + 1)), u (t + x j))|
        ≤ 1 / c * ∑ j ∈ range m, ε / 2 * (c / m) := by
          gcongr
          exact (Finset.abs_sum_le_sum_abs _ _).trans (Finset.sum_le_sum hbound)
      _ = ε / 2 := by rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul]; field_simp
      _ < ε := by linarith

theorem uaIter_continuous (c : ℝ) {u : ℝ → ℝ} (hu : Continuous u) (j : ℕ) :
    Continuous ((uaAvg c)^[j] u) := by
  induction j with
  | zero => simpa using hu
  | succ j ih => rw [Function.iterate_succ_apply']; exact uaAvg_continuous c ih

theorem uaIter_contDiff (c : ℝ) {u : ℝ → ℝ} (hu : Continuous u) (j : ℕ) :
    ContDiff ℝ j ((uaAvg c)^[j] u) := by
  induction j with
  | zero => simpa [contDiff_zero] using hu
  | succ j ih => rw [Function.iterate_succ_apply']; exact uaAvg_contDiff c j ih

theorem uaIter_approx (g : ℝ → ℝ) (c : ℝ) (hc : 0 < c) {u : ℝ → ℝ} (hu : Continuous u)
    (hA : UAApprox1 g u) (j : ℕ) : UAApprox1 g ((uaAvg c)^[j] u) := by
  induction j with
  | zero => simpa using hA
  | succ j ih =>
    rw [Function.iterate_succ_apply']
    exact uaapprox1_avg g c hc (uaIter_continuous c hu j) ih

theorem uaIter_close (c : ℝ) (hc : 0 < c) {u : ℝ → ℝ} (hu : Continuous u) (C η : ℝ) (j : ℕ) :
    ∀ t, (∀ s ∈ Set.Icc 0 (j * c), |u (t + s) - C| ≤ η) → |(uaAvg c)^[j] u t - C| ≤ η := by
  induction j with
  | zero =>
    intro t h
    simpa using h 0 (by simp)
  | succ j ih =>
    intro t h
    rw [Function.iterate_succ_apply']
    refine uaAvg_close c hc (uaIter_continuous c hu j) t C η (fun s hs => ?_)
    refine ih (t + s) (fun s' hs' => ?_)
    have := h (s + s') ⟨by linarith [hs.1, hs'.1], by push_cast; linarith [hs.2, hs'.2]⟩
    rwa [add_assoc]

theorem uaIter_tendsto {u : ℝ → ℝ} (hu : Continuous u) (j : ℕ) (t : ℝ) :
    Filter.Tendsto (fun n : ℕ => (uaAvg (1 / ((n : ℝ) + 1)))^[j] u t) Filter.atTop
      (nhds (u t)) := by
  rw [Metric.tendsto_atTop]
  intro ε hε
  obtain ⟨δ, hδ, hδ'⟩ := Metric.continuous_iff.1 hu t (ε / 2) (by linarith)
  obtain ⟨N, hN⟩ := exists_nat_gt (j / δ)
  refine ⟨N, fun n hn => ?_⟩
  have hc : (0 : ℝ) < 1 / ((n : ℝ) + 1) := by positivity
  have hjc : (j : ℝ) * (1 / ((n : ℝ) + 1)) < δ := by
    have hn' : (N : ℝ) ≤ n := by exact_mod_cast hn
    rw [div_lt_iff₀ hδ] at hN
    rw [mul_one_div, div_lt_iff₀ (by positivity)]
    nlinarith
  have := uaIter_close _ hc hu (u t) (ε / 2) j t (fun s hs => by
    have h1 := hδ' (t + s) (by
      rw [Real.dist_eq, add_sub_cancel_left, abs_of_nonneg hs.1]; linarith [hs.2])
    rw [Real.dist_eq] at h1; exact h1.le)
  rw [Real.dist_eq]; linarith

theorem ua_poly_of_iteratedDeriv_zero (k : ℕ) : ∀ (F : ℝ → ℝ), ContDiff ℝ k F →
    (∀ t, iteratedDeriv k F t = 0) →
    ∃ p : Polynomial ℝ, p.degree < k ∧ ∀ t, F t = p.eval t := by
  induction k with
  | zero =>
    intro F _ hF
    refine ⟨0, by simp, fun t => ?_⟩
    simpa using hF t
  | succ k ih =>
    intro F hF hz
    have hF' : ContDiff ℝ (k + 1 : ℕ) F := hF
    rw [Nat.cast_add, Nat.cast_one, contDiff_succ_iff_deriv] at hF'
    obtain ⟨hdiff, -, hdF⟩ := hF'
    obtain ⟨q, hqdeg, hq⟩ := ih (deriv F) hdF (fun t => by rw [← iteratedDeriv_succ']; exact hz t)
    open Polynomial in
    let Q : Polynomial ℝ := ∑ i ∈ range k, C (q.coeff i / (i + 1)) * X ^ (i + 1)
    have hQeval : ∀ t, Q.eval t = ∑ i ∈ range k, q.coeff i / (i + 1) * t ^ (i + 1) := by
      intro t; simp [Q, Polynomial.eval_finsetSum]
    have hqeval : ∀ t, q.eval t = ∑ i ∈ range k, q.coeff i * t ^ i := by
      intro t
      have hnat : q.natDegree < k + 1 :=
        Nat.lt_succ_of_le (Polynomial.natDegree_le_of_degree_le hqdeg.le)
      rw [Polynomial.eval_eq_sum_range' hnat, Finset.sum_range_succ,
        Polynomial.coeff_eq_zero_of_degree_lt hqdeg, zero_mul, add_zero]
    have hQd : ∀ t, HasDerivAt (fun t => Q.eval t) (q.eval t) t := by
      intro t
      have e : (fun t => Q.eval t) = fun t => ∑ i ∈ range k, q.coeff i / (i + 1) * t ^ (i + 1) :=
        funext hQeval
      rw [e, hqeval]
      have := HasDerivAt.fun_sum (u := range k)
        (A := fun i t => q.coeff i / (i + 1) * t ^ (i + 1))
        (A' := fun i => q.coeff i / (i + 1) * (((i + 1 : ℕ) : ℝ) * t ^ i))
        (fun i _ => (hasDerivAt_pow (i + 1) t).const_mul _)
      convert this using 1
      refine Finset.sum_congr rfl (fun i _ => ?_)
      push_cast
      field_simp
    have hQdeg : Q.degree < ((k + 1 : ℕ) : WithBot ℕ) := by
      have : Q.natDegree ≤ k := by
        refine Polynomial.natDegree_sum_le_of_forall_le _ _ (fun i hi => ?_)
        refine (Polynomial.natDegree_C_mul_X_pow_le _ _).trans ?_
        simp at hi; omega
      exact (Polynomial.degree_le_of_natDegree_le this).trans_lt (by exact_mod_cast Nat.lt_succ_self k)
    have hconst : ∀ t, F t - Q.eval t = F 0 - Q.eval 0 := by
      intro t
      refine is_const_of_deriv_eq_zero (f := fun t => F t - Q.eval t)
        (fun t => (hdiff t).sub (hQd t).differentiableAt) (fun t => ?_) t 0
      rw [((hdiff t).hasDerivAt.fun_sub (hQd t)).deriv, hq t, sub_self]
    refine ⟨Q + Polynomial.C (F 0 - Q.eval 0), ?_, fun t => ?_⟩
    · refine (Polynomial.degree_add_le _ _).trans_lt (max_lt hQdeg ?_)
      exact (Polynomial.degree_C_le).trans_lt (by exact_mod_cast Nat.succ_pos k)
    · rw [Polynomial.eval_add, Polynomial.eval_C, ← hconst t]; ring

theorem ua_poly_of_lim (k : ℕ) (Fn : ℕ → ℝ → ℝ) (g : ℝ → ℝ)
    (hp : ∀ n, ∃ p : Polynomial ℝ, p.degree < k ∧ ∀ t, Fn n t = p.eval t)
    (hlim : ∀ t, Filter.Tendsto (fun n => Fn n t) Filter.atTop (nhds (g t))) :
    ∃ P : Polynomial ℝ, ∀ t, g t = P.eval t := by
  classical
  let s : Finset ℕ := range k
  let v : ℕ → ℝ := fun i => (i : ℝ)
  have hinj : Set.InjOn v s := fun a _ b _ h => by simpa [v] using h
  have key : ∀ n t, Fn n t = ∑ i ∈ s, Fn n (v i) * (Lagrange.basis s v i).eval t := by
    intro n t
    obtain ⟨p, hpd, hpe⟩ := hp n
    have hcard : p.degree < (#s : WithBot ℕ) := by simpa [s] using hpd
    rw [hpe t, Lagrange.eq_interpolate hinj hcard]
    simp [Lagrange.interpolate_apply, Polynomial.eval_finsetSum, hpe]
  refine ⟨∑ i ∈ s, Polynomial.C (g (v i)) * Lagrange.basis s v i, fun t => ?_⟩
  have h1 : Filter.Tendsto (fun n => ∑ i ∈ s, Fn n (v i) * (Lagrange.basis s v i).eval t)
      Filter.atTop (nhds (∑ i ∈ s, g (v i) * (Lagrange.basis s v i).eval t)) :=
    tendsto_finsetSum _ (fun i _ => (hlim (v i)).mul_const _)
  have h2 : Filter.Tendsto (fun n => Fn n t) Filter.atTop
      (nhds (∑ i ∈ s, g (v i) * (Lagrange.basis s v i).eval t)) := by
    simpa only [← key] using h1
  rw [tendsto_nhds_unique (hlim t) h2]
  simp [Polynomial.eval_finsetSum]

theorem ua_exists_smooth (g : ℝ → ℝ) (hg : Continuous g)
    (hpoly : ¬ ∃ p : Polynomial ℝ, ∀ z, g z = p.eval z) (k : ℕ) :
    ∃ F : ℝ → ℝ, ContDiff ℝ k F ∧ UAApprox1 g F ∧ ∃ β, iteratedDeriv k F β ≠ 0 := by
  by_contra H
  push Not at H
  apply hpoly
  refine ua_poly_of_lim k (fun n => (uaAvg (1 / ((n : ℝ) + 1)))^[k] g) g (fun n => ?_)
    (fun t => uaIter_tendsto hg k t)
  have hc : (0 : ℝ) < 1 / ((n : ℝ) + 1) := by positivity
  exact ua_poly_of_iteratedDeriv_zero k _ (uaIter_contDiff _ hg k)
    (H _ (uaIter_contDiff _ hg k) (uaIter_approx g _ hc hg (uaapprox1_of_net g (uanet1_self g)) k))

theorem uaapprox1_congr (g : ℝ → ℝ) {u v : ℝ → ℝ} (hu : UAApprox1 g u) (h : ∀ t, u t = v t) :
    UAApprox1 g v := by
  have : u = v := funext h
  rwa [← this]

theorem ua_deriv_step (g : ℝ → ℝ) (F : ℝ → ℝ) (k : ℕ) (hF : ContDiff ℝ k F)
    (hA : UAApprox1 g F) :
    ∀ j ≤ k, ∀ α β : ℝ, UAApprox1 g (fun t => t ^ j * iteratedDeriv j F (α * t + β)) := by
  intro j
  induction j with
  | zero =>
    intro _ α β
    simpa using uaapprox1_comp g α β hA
  | succ j ih =>
    intro hjk α β
    set G := iteratedDeriv j F with hG
    set G' := iteratedDeriv (j + 1) F with hG'
    have hGd : ∀ z, HasDerivAt G (G' z) z := by
      intro z
      have hd : Differentiable ℝ G :=
        hF.differentiable_iteratedDeriv j (by exact_mod_cast (show j < k by omega))
      rw [hG', iteratedDeriv_succ]
      exact (hd z).hasDerivAt
    have hG'c : Continuous G' := hF.continuous_iteratedDeriv (j + 1) (by exact_mod_cast hjk)
    apply uaapprox1_lim
    intro R ε hε
    set ρ := |R| with hρ
    have hρ0 : 0 ≤ ρ := abs_nonneg R
    set K := Set.Icc (-((|α| + 1) * ρ + |β|)) ((|α| + 1) * ρ + |β|)
    set η := ε / (2 * (ρ ^ (j + 1) + 1)) with hη
    have hη0 : 0 < η := by positivity
    obtain ⟨δ, hδ, hδ'⟩ := Metric.uniformContinuousOn_iff.1
      (isCompact_Icc.uniformContinuousOn_of_continuous hG'c.continuousOn) η hη0
    set h := min 1 (δ / (ρ + 1)) / 2 with hh
    have hh0 : 0 < h := by positivity
    have hh1 : h ≤ 1 := by
      have := min_le_left 1 (δ / (ρ + 1)); rw [hh]; linarith
    have hhρ : h * ρ < δ := by
      have h2 : h ≤ δ / (ρ + 1) / 2 := by
        have := min_le_right 1 (δ / (ρ + 1)); rw [hh]; linarith
      have h3 : δ / (ρ + 1) * ρ < δ := by
        rw [div_mul_eq_mul_div, div_lt_iff₀ (by positivity)]; nlinarith
      calc h * ρ ≤ δ / (ρ + 1) / 2 * ρ := by gcongr
        _ ≤ δ / (ρ + 1) * ρ := by
          have : 0 ≤ δ / (ρ + 1) * ρ := by positivity
          linarith
        _ < δ := h3
    refine ⟨fun t => (1 / h) * (t ^ j * G ((α + h) * t + β)) +
      (-(1 / h)) * (t ^ j * G (α * t + β)), ?_, ?_⟩
    · exact uaapprox1_add g (uaapprox1_smul g _ (ih (by omega) (α + h) β))
        (uaapprox1_smul g _ (ih (by omega) α β))
    · intro t ht
      have htρ : |t| ≤ ρ := by
        rw [hρ, abs_le]; constructor <;> cases abs_cases R <;> linarith [ht.1, ht.2]
      set x := α * t + β with hx
      set y := (α + h) * t + β with hy
      have hyx : y - x = h * t := by rw [hx, hy]; ring
      have hxK : ∀ z ∈ Set.uIcc x y, z ∈ K ∧ |z - x| < δ := by
        intro z hz
        have hzx : |z - x| ≤ |y - x| := Set.abs_sub_left_of_mem_uIcc hz
        rw [hyx, abs_mul, abs_of_pos hh0] at hzx
        have hzx' : |z - x| ≤ h * ρ := hzx.trans (by gcongr)
        have hxb : |x| ≤ |α| * ρ + |β| := by
          calc |x| ≤ |α * t| + |β| := abs_add_le _ _
            _ = |α| * |t| + |β| := by rw [abs_mul]
            _ ≤ |α| * ρ + |β| := by gcongr
        have hzb : |z| ≤ (|α| + 1) * ρ + |β| := by
          calc |z| = |(z - x) + x| := by ring_nf
            _ ≤ |z - x| + |x| := abs_add_le _ _
            _ ≤ h * ρ + (|α| * ρ + |β|) := add_le_add hzx' hxb
            _ ≤ 1 * ρ + (|α| * ρ + |β|) := by gcongr
            _ = (|α| + 1) * ρ + |β| := by ring
        exact ⟨abs_le.1 hzb, lt_of_le_of_lt hzx' hhρ⟩
      have hxK' : x ∈ K := (hxK x Set.left_mem_uIcc).1
      have hmv := Convex.norm_image_sub_le_of_norm_hasDerivWithin_le
        (f := fun z => G z - G' x * z) (f' := fun z => G' z - G' x) (C := η)
        (s := Set.uIcc x y) (x := x) (y := y)
        (fun z _ => (((hGd z).sub ((hasDerivAt_id' z).const_mul (G' x))).congr_deriv
          (by ring)).hasDerivWithinAt)
        (fun z hz => by
          have := hδ' z (hxK z hz).1 x hxK' (by rw [Real.dist_eq]; exact (hxK z hz).2)
          rw [Real.dist_eq] at this
          rw [Real.norm_eq_abs]; exact this.le)
        (convex_uIcc x y) Set.left_mem_uIcc Set.right_mem_uIcc
      simp only [Real.norm_eq_abs] at hmv
      have e : t ^ (j + 1) * G' (α * t + β) -
          ((1 / h) * (t ^ j * G ((α + h) * t + β)) + (-(1 / h)) * (t ^ j * G (α * t + β))) =
          -(t ^ j / h) * ((G y - G' x * y) - (G x - G' x * x)) := by
        rw [← hx, ← hy]
        have : G' x * y - G' x * x = G' x * (h * t) := by rw [← mul_sub, hyx]
        field_simp
        linear_combination (-(t ^ j) * h) * this
      rw [hyx, abs_mul, abs_of_pos hh0] at hmv
      rw [e, abs_mul, abs_neg, abs_div, abs_of_pos hh0, abs_pow]
      have hpow : |t| ^ j * |t| ≤ ρ ^ (j + 1) := by
        rw [← pow_succ]; exact pow_le_pow_left₀ (abs_nonneg t) htρ _
      calc |t| ^ j / h * |G y - G' x * y - (G x - G' x * x)|
          ≤ |t| ^ j / h * (η * (h * |t|)) := by gcongr
        _ = η * (|t| ^ j * |t|) := by field_simp
        _ ≤ η * ρ ^ (j + 1) := by gcongr
        _ < ε := by
          rw [hη, div_mul_eq_mul_div, div_lt_iff₀ (by positivity)]
          nlinarith [pow_nonneg hρ0 (j + 1)]

theorem ua_monomial (g : ℝ → ℝ) (hg : Continuous g)
    (hpoly : ¬ ∃ p : Polynomial ℝ, ∀ z, g z = p.eval z) (k : ℕ) :
    UAApprox1 g (fun t => t ^ k) := by
  obtain ⟨F, hF, hA, β, hβ⟩ := ua_exists_smooth g hg hpoly k
  have := uaapprox1_smul g (1 / iteratedDeriv k F β) (ua_deriv_step g F k hF hA k le_rfl 0 β)
  refine uaapprox1_congr g this (fun t => ?_)
  simp only [zero_mul, zero_add]
  field_simp

theorem ua_polynomial (g : ℝ → ℝ) (hg : Continuous g)
    (hpoly : ¬ ∃ p : Polynomial ℝ, ∀ z, g z = p.eval z) (p : Polynomial ℝ) :
    UAApprox1 g (fun t => p.eval t) := by
  refine uaapprox1_congr g (uaapprox1_sum g (p.natDegree + 1) (fun i t => p.coeff i * t ^ i)
    (fun i _ => uaapprox1_smul g _ (ua_monomial g hg hpoly i))) (fun t => ?_)
  rw [Polynomial.eval_eq_sum_range]

theorem ua_continuous (g : ℝ → ℝ) (hg : Continuous g)
    (hpoly : ¬ ∃ p : Polynomial ℝ, ∀ z, g z = p.eval z) (u : ℝ → ℝ) (hu : Continuous u) :
    UAApprox1 g u := by
  apply uaapprox1_lim
  intro R ε hε
  obtain ⟨p, hp⟩ := exists_polynomial_near_of_continuousOn (-R) R u hu.continuousOn ε hε
  exact ⟨_, ua_polynomial g hg hpoly p, fun t ht => by rw [abs_sub_comm]; exact hp t ht⟩

/-- `v` is exactly a network with `d` inputs and activation `g`. -/
def UANetD (g : ℝ → ℝ) {d : ℕ} (v : (Fin d → ℝ) → ℝ) : Prop :=
  ∃ (N : ℕ) (a : Fin N → ℝ) (w : Fin N → Fin d → ℝ) (b : Fin N → ℝ) (c : ℝ),
    ∀ x, v x = c + ∑ k, a k * g ((∑ i, w k i * x i) + b k)

/-- The continuous function `F` on `S` is within any tolerance of some network. -/
def UAApproxS (g : ℝ → ℝ) {d : ℕ} (S : Set (Fin d → ℝ)) (F : C(S, ℝ)) : Prop :=
  ∀ ε : ℝ, 0 < ε → ∃ v, UANetD g v ∧ ∀ x : S, |F x - v x.1| < ε

theorem uanetD_add (g : ℝ → ℝ) {d : ℕ} {u v : (Fin d → ℝ) → ℝ} (hu : UANetD g u)
    (hv : UANetD g v) : UANetD g (fun x => u x + v x) := by
  obtain ⟨N, a, w, b, c, hu⟩ := hu
  obtain ⟨M, a', w', b', c', hv⟩ := hv
  refine ⟨N + M, Fin.append a a', Fin.append w w', Fin.append b b', c + c', fun x => ?_⟩
  simp only
  rw [hu, hv, Fin.sum_univ_add]
  simp only [Fin.append_left, Fin.append_right]
  ring

theorem uanetD_smul (g : ℝ → ℝ) {d : ℕ} {u : (Fin d → ℝ) → ℝ} (r : ℝ) (hu : UANetD g u) :
    UANetD g (fun x => r * u x) := by
  obtain ⟨N, a, w, b, c, hu⟩ := hu
  refine ⟨N, fun k => r * a k, w, b, r * c, fun x => ?_⟩
  simp only
  rw [hu, mul_add, Finset.mul_sum]
  simp only [mul_assoc]

theorem uaapproxS_zero (g : ℝ → ℝ) {d : ℕ} (S : Set (Fin d → ℝ)) : UAApproxS g S 0 :=
  fun ε hε => ⟨fun _ => 0, ⟨0, Fin.elim0, Fin.elim0, Fin.elim0, 0, fun x => by simp⟩,
    fun x => by simpa using hε⟩

theorem uaapproxS_add (g : ℝ → ℝ) {d : ℕ} (S : Set (Fin d → ℝ)) {F G : C(S, ℝ)}
    (hF : UAApproxS g S F) (hG : UAApproxS g S G) : UAApproxS g S (F + G) := by
  intro ε hε
  obtain ⟨u, hu, hu'⟩ := hF (ε / 2) (by linarith)
  obtain ⟨v, hv, hv'⟩ := hG (ε / 2) (by linarith)
  refine ⟨_, uanetD_add g hu hv, fun x => ?_⟩
  have h1 := hu' x
  have h2 := hv' x
  rw [ContinuousMap.add_apply]
  calc |F x + G x - (u x.1 + v x.1)| = |(F x - u x.1) + (G x - v x.1)| := by ring_nf
    _ ≤ |F x - u x.1| + |G x - v x.1| := abs_add_le _ _
    _ < ε := by linarith

theorem uaapproxS_smul (g : ℝ → ℝ) {d : ℕ} (S : Set (Fin d → ℝ)) (r : ℝ) {F : C(S, ℝ)}
    (hF : UAApproxS g S F) : UAApproxS g S (r • F) := by
  intro ε hε
  obtain ⟨u, hu, hu'⟩ := hF (ε / (|r| + 1)) (by positivity)
  refine ⟨_, uanetD_smul g r hu, fun x => ?_⟩
  have h1 := hu' x
  have hr : 0 < |r| + 1 := by positivity
  rw [ContinuousMap.smul_apply, smul_eq_mul]
  calc |r * F x - r * u x.1| = |r| * |F x - u x.1| := by rw [← mul_sub, abs_mul]
    _ ≤ (|r| + 1) * |F x - u x.1| := by gcongr; linarith
    _ < (|r| + 1) * (ε / (|r| + 1)) := by gcongr
    _ = ε := by field_simp

theorem uaapproxS_ridge (g : ℝ → ℝ) {d : ℕ} (S : Set (Fin d → ℝ)) (hSb : Bornology.IsBounded S)
    {φ : ℝ → ℝ} (hφ : UAApprox1 g φ) (w : Fin d → ℝ) (F : C(S, ℝ))
    (hF : ∀ x : S, F x = φ (∑ i, w i * x.1 i)) : UAApproxS g S F := by
  intro ε hε
  obtain ⟨C, hC⟩ := (isBounded_iff_forall_norm_le).1 hSb
  obtain ⟨v, hv, hv'⟩ := hφ (∑ i, |w i| * C) ε hε
  obtain ⟨N, a, w', b, c, hvn⟩ := hv
  refine ⟨fun x => v (∑ i, w i * x i), ⟨N, a, fun k i => w' k * w i, b, c, fun x => ?_⟩,
    fun x => ?_⟩
  · simp only
    rw [hvn]
    congr 1
    refine Finset.sum_congr rfl (fun k _ => ?_)
    rw [Finset.mul_sum]
    simp only [mul_assoc]
  · rw [hF x]
    refine hv' _ (abs_le.1 ?_)
    calc |∑ i, w i * x.1 i| ≤ ∑ i, |w i * x.1 i| := Finset.abs_sum_le_sum_abs _ _
      _ = ∑ i, |w i| * |x.1 i| := by simp only [abs_mul]
      _ ≤ ∑ i, |w i| * C := by
        refine Finset.sum_le_sum (fun i _ => ?_)
        gcongr
        exact (norm_le_pi_norm x.1 i).trans (hC x.1 x.2)

/-- Linear interpolation error on one piece. -/
theorem lin_interp_err (f : ℝ → ℝ) (hf : Differentiable ℝ f) (hf' : Differentiable ℝ (deriv f))
    (a b M : ℝ) (hab : a < b) (hM : ∀ t ∈ Set.Icc a b, |deriv (deriv f) t| ≤ M)
    (x : ℝ) (hx : x ∈ Set.Icc a b) :
    |f x - (f a + (f b - f a) / (b - a) * (x - a))| ≤ M / 2 * ((x - a) * (b - x)) := by
  set s := (f b - f a) / (b - a) with hs
  have hba : b - a ≠ 0 := by linarith
  have hsb : f a + s * (b - a) = f b := by rw [hs]; field_simp; ring
  have hD : Convex ℝ (Set.Icc a b) := convex_Icc a b
  have hint : interior (Set.Icc a b) = Set.Ioo a b := interior_Icc
  have hseg : x ∈ segment ℝ a b := by rw [segment_eq_Icc hab.le]; exact hx
  have ha : a ∈ Set.Icc a b := ⟨le_rfl, hab.le⟩
  have hb : b ∈ Set.Icc a b := ⟨hab.le, le_rfl⟩
  -- lower bound by concavity
  have h1 : ∀ σ : ℝ, σ = 1 ∨ σ = -1 →
      ∀ t, HasDerivAt (fun t => f t - (f a + s * (t - a)) - σ * (M / 2) * ((t - a) * (t - b)))
        (deriv f t - s - σ * (M / 2) * (2 * t - a - b)) t := by
    intro σ _ t
    have e1 := (hf t).hasDerivAt
    have e2 : HasDerivAt (fun t => f a + s * (t - a)) s t := by
      simpa using ((hasDerivAt_id t).sub_const a).const_mul s |>.const_add (f a)
    have e3 : HasDerivAt (fun t => (t - a) * (t - b)) (2 * t - a - b) t := by
      have := ((hasDerivAt_id' t).sub_const a).mul ((hasDerivAt_id' t).sub_const b)
      convert this using 1; ring
    exact (e1.sub e2).sub (e3.const_mul (σ * (M / 2)))
  have h2 : ∀ σ : ℝ, ∀ t, HasDerivAt (fun t => deriv f t - s - σ * (M / 2) * (2 * t - a - b))
        (deriv (deriv f) t - σ * M) t := by
    intro σ t
    have e1 := (hf' t).hasDerivAt
    have e3 : HasDerivAt (fun t => 2 * t - a - b) 2 t := by
      simpa using (((hasDerivAt_id t).const_mul 2).sub_const a).sub_const b
    convert (e1.sub_const s).sub (e3.const_mul (σ * (M / 2))) using 1; ring
  have hcont : ∀ σ : ℝ, σ = 1 ∨ σ = -1 → ContinuousOn
      (fun t => f t - (f a + s * (t - a)) - σ * (M / 2) * ((t - a) * (t - b))) (Set.Icc a b) :=
    fun σ hσ => (continuous_iff_continuousAt.2 fun t => (h1 σ hσ t).continuousAt).continuousOn
  have hcc : ConcaveOn ℝ (Set.Icc a b)
      (fun t => f t - (f a + s * (t - a)) - 1 * (M / 2) * ((t - a) * (t - b))) := by
    refine concaveOn_of_hasDerivWithinAt2_nonpos hD (hcont 1 (Or.inl rfl))
      (fun t _ => (h1 1 (Or.inl rfl) t).hasDerivWithinAt) (fun t _ => (h2 1 t).hasDerivWithinAt) ?_
    intro t ht
    rw [hint] at ht
    have := (abs_le.1 (hM t ⟨ht.1.le, ht.2.le⟩)).2
    linarith
  have hcv : ConvexOn ℝ (Set.Icc a b)
      (fun t => f t - (f a + s * (t - a)) - (-1) * (M / 2) * ((t - a) * (t - b))) := by
    refine convexOn_of_hasDerivWithinAt2_nonneg hD (hcont (-1) (Or.inr rfl))
      (fun t _ => (h1 (-1) (Or.inr rfl) t).hasDerivWithinAt) (fun t _ => (h2 (-1) t).hasDerivWithinAt) ?_
    intro t ht
    rw [hint] at ht
    have := (abs_le.1 (hM t ⟨ht.1.le, ht.2.le⟩)).1
    linarith
  have l1 := hcc.ge_on_segment ha hb hseg
  have l2 := hcv.le_on_segment ha hb hseg
  simp only [sub_self, mul_zero, zero_mul, add_zero, hsb, min_self, max_self] at l1 l2
  rw [abs_le]
  constructor <;> nlinarith

/-- The universal approximation theorem. Let the activation `g` be continuous and not a
polynomial. Let `f` be continuous on a closed, bounded set `S` of points with `d` coordinates.
Then for every error allowance `ε > 0` there are a width `N`, output weights `a k`, unit
weights `w k`, biases `b k` and an output bias `c` such that the one-hidden-layer network
`c + ∑ a k * g (w k · x + b k)` is within `ε` of `f` at every point of `S`. -/
theorem universal_approximation {d : ℕ} (g : ℝ → ℝ) (hg : Continuous g)
    (hpoly : ¬ ∃ p : Polynomial ℝ, ∀ z, g z = p.eval z)
    (S : Set (Fin d → ℝ)) (hSc : IsClosed S) (hSb : Bornology.IsBounded S)
    (f : (Fin d → ℝ) → ℝ) (hf : ContinuousOn f S) (ε : ℝ) (hε : 0 < ε) :
    ∃ (N : ℕ) (a : Fin N → ℝ) (w : Fin N → Fin d → ℝ) (b : Fin N → ℝ) (c : ℝ),
      ∀ x ∈ S, |f x - (c + ∑ k, a k * g ((∑ i, w k i * x i) + b k))| < ε := by
  have : CompactSpace S :=
    isCompact_iff_compactSpace.1 (Metric.isCompact_of_isClosed_isBounded hSc hSb)
  let E : (Fin d → ℝ) → C(S, ℝ) := fun w =>
    ⟨fun x => Real.exp (∑ i, w i * x.1 i), Real.continuous_exp.comp
      (continuous_finsetSum _ fun i _ =>
        continuous_const.mul ((continuous_apply i).comp continuous_subtype_val))⟩
  let A : Subalgebra ℝ C(S, ℝ) := Algebra.adjoin ℝ (Set.range E)
  have hsep : A.SeparatesPoints := by
    intro x y hxy
    have hne : x.1 ≠ y.1 := fun h => hxy (Subtype.ext h)
    obtain ⟨i, hi⟩ := Function.ne_iff.1 hne
    refine ⟨E (Pi.single i 1), ⟨E (Pi.single i 1), Algebra.subset_adjoin ⟨_, rfl⟩, rfl⟩, ?_⟩
    simp only [E, ContinuousMap.coe_mk, Pi.single_apply, ite_mul, one_mul, zero_mul,
      Finset.sum_ite_eq', Finset.mem_univ, ite_true]
    exact fun h => hi (Real.exp_injective h)
  have hexp : UAApprox1 g Real.exp := ua_continuous g hg hpoly _ Real.continuous_exp
  have hA : ∀ F ∈ A, UAApproxS g S F := by
    intro F hF
    have hF' : F ∈ Submodule.span ℝ (Submonoid.closure (Set.range E) : Set C(S, ℝ)) := by
      rw [← Algebra.adjoin_eq_span]; exact hF
    clear hF
    induction hF' using Submodule.span_induction with
    | mem x hx =>
      have : ∃ w, x = E w := by
        induction hx using Submonoid.closure_induction with
        | mem x hx => obtain ⟨w, rfl⟩ := hx; exact ⟨w, rfl⟩
        | one => exact ⟨0, by ext x; simp [E]⟩
        | mul x y _ _ hx hy =>
          obtain ⟨w, rfl⟩ := hx
          obtain ⟨v, rfl⟩ := hy
          refine ⟨w + v, ?_⟩
          ext x
          simp [E, ← Real.exp_add, add_mul, Finset.sum_add_distrib]
      obtain ⟨w, rfl⟩ := this
      exact uaapproxS_ridge g S hSb hexp w _ (fun x => rfl)
    | zero => exact uaapproxS_zero g S
    | add x y _ _ hx hy => exact uaapproxS_add g S hx hy
    | smul r x _ hx => exact uaapproxS_smul g S r hx
  obtain ⟨F, hFf⟩ := ContinuousMap.exists_mem_subalgebra_near_continuous_of_separatesPoints A hsep
    (S.domRestrict f) hf.domRestrict (ε / 2) (by linarith)
  obtain ⟨v, hv, hv'⟩ := hA F F.2 (ε / 2) (by linarith)
  obtain ⟨N, a, w, b, c, hvn⟩ := hv
  refine ⟨N, a, w, b, c, fun x hx => ?_⟩
  rw [← hvn]
  have h1 : |(F : C(S, ℝ)) ⟨x, hx⟩ - f x| < ε / 2 := by
    simpa [Real.norm_eq_abs] using hFf ⟨x, hx⟩
  have h2 := hv' ⟨x, hx⟩
  calc |f x - v x| = |((F : C(S, ℝ)) ⟨x, hx⟩ - v x) - ((F : C(S, ℝ)) ⟨x, hx⟩ - f x)| := by ring_nf
    _ ≤ |(F : C(S, ℝ)) ⟨x, hx⟩ - v x| + |(F : C(S, ℝ)) ⟨x, hx⟩ - f x| := abs_sub _ _
    _ < ε := by linarith

/-- The one-input ReLU case with its price. On `[l, r]` put `N + 1` knots `x_k = l + k h`
with spacing `h = (r - l) / N`, let `s_k` be the slope of the chord on piece `k`, and give
the network output bias `c = f(x_0)`, first output weight `a_0 = s_0` and later output
weights `a_k = s_k - s_(k-1)`, with unit `k` computing `ReLU(x - x_k) = max 0 (x - x_k)`.
Then the network passes through every knot (it is the join of the dots), and if the second
derivative of `f` stays between `-M` and `M` on `[l, r]`, its error is at most `M h^2 / 8`. -/
theorem relu_join_error_le (f : ℝ → ℝ) (l r M : ℝ) (N : ℕ) (hlr : l < r) (hN : 0 < N)
    (hf : Differentiable ℝ f) (hf' : Differentiable ℝ (deriv f))
    (hM : ∀ x ∈ Set.Icc l r, |deriv (deriv f) x| ≤ M) :
    let h : ℝ := (r - l) / N
    let knot : ℕ → ℝ := fun k => l + k * h
    let s : ℕ → ℝ := fun k => (f (knot (k + 1)) - f (knot k)) / h
    let a : ℕ → ℝ := fun k => if k = 0 then s 0 else s k - s (k - 1)
    let net : ℝ → ℝ := fun x => f (knot 0) + ∑ k ∈ range N, a k * max 0 (x - knot k)
    (∀ k ≤ N, net (knot k) = f (knot k)) ∧
      ∀ x ∈ Set.Icc l r, |f x - net x| ≤ M * h ^ 2 / 8 := by
  intro h knot s a net
  have hNpos : (0 : ℝ) < N := by exact_mod_cast hN
  have hh : 0 < h := div_pos (by linarith) hNpos
  have hknotN : knot N = r := by
    show l + (N : ℝ) * ((r - l) / N) = r
    field_simp; ring
  have hknot_succ : ∀ k, knot (k + 1) = knot k + h := by
    intro k; show l + ((k + 1 : ℕ) : ℝ) * h = l + k * h + h; push_cast; ring
  have hknot_mono : ∀ j k : ℕ, j ≤ k → knot j ≤ knot k := by
    intro j k hjk
    show l + (j : ℝ) * h ≤ l + k * h
    have : (j : ℝ) ≤ k := by exact_mod_cast hjk
    nlinarith
  have hs_mul : ∀ k, s k * h = f (knot (k + 1)) - f (knot k) := by
    intro k; show (f (knot (k + 1)) - f (knot k)) / h * h = _; field_simp
  have hpart : ∀ k x, ∑ j ∈ range (k + 1), a j * (x - knot j) =
      f (knot k) - f (knot 0) + s k * (x - knot k) := by
    intro k x
    induction k with
    | zero => simp [a]
    | succ k ih =>
      rw [Finset.sum_range_succ, ih]
      have : a (k + 1) = s (k + 1) - s k := by simp [a]
      rw [this, hknot_succ k]
      have := hs_mul k
      rw [hknot_succ k] at this
      linear_combination this
  have hpiece : ∀ k < N, ∀ x, knot k ≤ x → x ≤ knot (k + 1) →
      net x = f (knot k) + s k * (x - knot k) := by
    intro k hk x hx1 hx2
    show f (knot 0) + ∑ j ∈ range N, a j * max 0 (x - knot j) = _
    rw [← Finset.sum_range_add_sum_Ico _ (show k + 1 ≤ N by omega)]
    have e1 : ∑ j ∈ range (k + 1), a j * max 0 (x - knot j) =
        ∑ j ∈ range (k + 1), a j * (x - knot j) := by
      refine Finset.sum_congr rfl (fun j hj => ?_)
      have : knot j ≤ knot k := hknot_mono j k (by simp at hj; omega)
      rw [max_eq_right (by linarith)]
    have e2 : ∑ j ∈ Finset.Ico (k + 1) N, a j * max 0 (x - knot j) = 0 := by
      refine Finset.sum_eq_zero (fun j hj => ?_)
      have : knot (k + 1) ≤ knot j := hknot_mono _ _ (Finset.mem_Ico.1 hj).1
      rw [max_eq_left (by linarith), mul_zero]
    rw [e1, e2, hpart]; ring
  refine ⟨?_, ?_⟩
  · intro k hk
    cases k with
    | zero =>
      show f (knot 0) + ∑ j ∈ range N, a j * max 0 (knot 0 - knot j) = f (knot 0)
      rw [Finset.sum_eq_zero (fun j _ => by
        rw [max_eq_left (by linarith [hknot_mono 0 j (Nat.zero_le j)]), mul_zero]), add_zero]
    | succ m =>
      rw [hpiece m (by omega) (knot (m + 1)) (by rw [hknot_succ]; linarith) le_rfl, hknot_succ,
        add_sub_cancel_left, hs_mul, ← hknot_succ]
      ring
  · intro x hx
    have hM0 : 0 ≤ M := (abs_nonneg _).trans (hM l ⟨le_rfl, hlr.le⟩)
    set q := (x - l) / h with hq
    have hq0 : 0 ≤ q := div_nonneg (by linarith [hx.1]) hh.le
    have hqN : q ≤ N := by
      rw [hq, div_le_iff₀ hh]
      have : (N : ℝ) * h = r - l := by
        show (N : ℝ) * ((r - l) / N) = r - l; field_simp
      linarith [hx.2]
    have hxq : x = l + q * h := by rw [hq]; field_simp; ring
    set k := min (⌊q⌋₊) (N - 1) with hk
    have hkN : k < N := by omega
    have hlo : knot k ≤ x := by
      show l + (k : ℝ) * h ≤ x
      have : (k : ℝ) ≤ q := (Nat.cast_le.2 (min_le_left _ _)).trans (Nat.floor_le hq0)
      rw [hxq]; nlinarith
    have hhi : x ≤ knot (k + 1) := by
      rcases le_or_gt (⌊q⌋₊) (N - 1) with hc | hc
      · have hk' : k = ⌊q⌋₊ := min_eq_left hc
        show x ≤ l + ((k + 1 : ℕ) : ℝ) * h
        have : q ≤ ((k + 1 : ℕ) : ℝ) := by
          rw [hk']; push_cast; exact (Nat.lt_floor_add_one q).le
        rw [hxq]; nlinarith
      · have hk' : k + 1 = N := by omega
        rw [hk', hknotN]; exact hx.2
    have hlk : l ≤ knot k := by
      have := hknot_mono 0 k (Nat.zero_le k)
      simpa [knot] using this
    have hkr : knot (k + 1) ≤ r := by
      rw [← hknotN]; exact hknot_mono _ _ (by omega)
    have hab : knot k < knot (k + 1) := by rw [hknot_succ]; linarith
    have herr := lin_interp_err f hf hf' (knot k) (knot (k + 1)) M hab
      (fun t ht => hM t ⟨hlk.trans ht.1, ht.2.trans hkr⟩) x ⟨hlo, hhi⟩
    have hsk : (f (knot (k + 1)) - f (knot k)) / (knot (k + 1) - knot k) = s k := by
      rw [show knot (k + 1) - knot k = h by rw [hknot_succ k]; ring]
    rw [hsk, ← hpiece k hkN x hlo hhi] at herr
    refine herr.trans ?_
    have hw : knot (k + 1) - knot k = h := by rw [hknot_succ k]; ring
    have : (x - knot k) * (knot (k + 1) - x) ≤ h ^ 2 / 4 := by
      rw [← hw]; nlinarith [sq_nonneg (x - (knot k + knot (k + 1)) / 2)]
    calc M / 2 * ((x - knot k) * (knot (k + 1) - x)) ≤ M / 2 * (h ^ 2 / 4) :=
          mul_le_mul_of_nonneg_left this (by linarith)
      _ = M * h ^ 2 / 8 := by ring

/-- Why the activation must not be a polynomial. If every unit uses a polynomial `p` of
degree `m`, then every one-input network `c + ∑ a k * p (w k * x + b k)`, of any width, is
itself a polynomial of degree at most `m`: width adds no new shapes. -/
theorem polynomial_activation_net_is_polynomial (p : Polynomial ℝ) (N : ℕ)
    (a w b : Fin N → ℝ) (c : ℝ) :
    ∃ q : Polynomial ℝ, q.natDegree ≤ p.natDegree ∧
      ∀ x : ℝ, c + ∑ k, a k * p.eval (w k * x + b k) = q.eval x := by
  open Polynomial in
  refine ⟨C c + ∑ k, C (a k) * p.comp (C (w k) * X + C (b k)), ?_, ?_⟩
  · refine natDegree_add_le_of_degree_le (by simp) ?_
    refine natDegree_sum_le_of_forall_le _ _ (fun k _ => ?_)
    refine (natDegree_C_mul_le _ _).trans ?_
    refine natDegree_comp_le.trans ?_
    calc p.natDegree * (C (w k) * X + C (b k)).natDegree ≤ p.natDegree * 1 :=
          Nat.mul_le_mul_left _ natDegree_linear_le
      _ = p.natDegree := by simp
  · intro x
    simp [Polynomial.eval_finsetSum]

-- The 10-unit network holds 10 weights, 10 biases, 10 output weights and 1 output bias.
example : 10 + 10 + 10 + 1 = 31 := by norm_num

-- Halving the bound (pi/n)^2/8 below (pi/10)^2/16 needs n^2 >= 2 * 10^2: 14 units fail, 15 suffice.
example : 14 ^ 2 < 2 * 10 ^ 2 ∧ 2 * 10 ^ 2 ≤ 15 ^ 2 := by decide

-- A grid of 10 pieces per input needs 10^d pieces: 100 for two inputs, 1000 for three.
example : 10 ^ 2 = 100 ∧ 10 ^ 3 = 1000 := by norm_num

#print axioms uanet1_const
#print axioms uanet1_add
#print axioms uanet1_smul
#print axioms uanet1_comp
#print axioms uanet1_self
#print axioms uaapprox1_of_net
#print axioms uaapprox1_lim
#print axioms uaapprox1_add
#print axioms uaapprox1_smul
#print axioms uaapprox1_sum
#print axioms uaapprox1_comp
#print axioms uaAvg_eq
#print axioms uaAvg_hasDerivAt
#print axioms uaAvg_contDiff
#print axioms uaAvg_continuous
#print axioms uaAvg_close
#print axioms uaapprox1_avg
#print axioms uaIter_continuous
#print axioms uaIter_contDiff
#print axioms uaIter_approx
#print axioms uaIter_close
#print axioms uaIter_tendsto
#print axioms ua_poly_of_iteratedDeriv_zero
#print axioms ua_poly_of_lim
#print axioms ua_exists_smooth
#print axioms uaapprox1_congr
#print axioms ua_deriv_step
#print axioms ua_monomial
#print axioms ua_polynomial
#print axioms ua_continuous
#print axioms uanetD_add
#print axioms uanetD_smul
#print axioms uaapproxS_zero
#print axioms uaapproxS_add
#print axioms uaapproxS_smul
#print axioms uaapproxS_ridge
#print axioms lin_interp_err
#print axioms universal_approximation
#print axioms relu_join_error_le
#print axioms polynomial_activation_net_is_polynomial
