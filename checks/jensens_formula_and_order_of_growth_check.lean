-- Jensen's formula: the average of ln|f| round a circle equals ln|f(0)| plus ln(R/|a|) for each zero a inside, so a bound on |f| on the doubled circle bounds the zeros within radius r, and finite order gives at most C r^(ρ+ε) of them.
import Mathlib.Analysis.Complex.JensenFormula
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Complex.AbsMax
import Mathlib.Analysis.Complex.Liouville

open Filter Metric Real MeromorphicOn

/-- **Jensen's formula.** Let `f` be holomorphic on the whole closed disk of radius `R > 0`
about 0, with `f(0) ≠ 0`. Then the average of `ln |f|` round the circle `|z| = R`,
`(1/(2π)) ∫₀^{2π} ln |f(R e^{it})| dt`, equals `ln |f(0)|` plus `ln (R / |a|)` for each zero
`a` with `|a| < R`, each zero counted with its multiplicity (`divisor f (ball 0 R) a` is the
multiplicity of the zero at `a` inside the open disk, and 0 elsewhere). -/
theorem jensen_formula {f : ℂ → ℂ} {R : ℝ} (hR : 0 < R)
    (hf : AnalyticOnNhd ℂ f (closedBall (0 : ℂ) R)) (h0 : f 0 ≠ 0) :
    (1 / (2 * π)) * ∫ t in (0 : ℝ)..2 * π, Real.log ‖f (R * Complex.exp (t * Complex.I))‖
      = Real.log ‖f 0‖ + ∑ᶠ a, (divisor f (ball (0 : ℂ) R) a : ℝ) * Real.log (R / ‖a‖) := by
  have hf' : AnalyticOnNhd ℂ f (closedBall (0 : ℂ) |R|) := by rwa [abs_of_pos hR]
  have J := hf'.circleAverage_log_norm hR.ne' h0
  rw [circleAverage_def, abs_of_pos hR] at J
  simp only [circleMap, zero_add, smul_eq_mul] at J
  rw [one_div, J, add_comm]
  congr 1
  refine finsum_congr fun u => ?_
  rw [zero_sub, norm_neg, ← div_eq_mul_inv]
  by_cases hu : u ∈ ball (0 : ℂ) R
  · rw [hf.divisor_apply (ball_subset_closedBall hu),
      (hf.mono ball_subset_closedBall).divisor_apply hu]
  · rw [Function.locallyFinsuppWithin.apply_eq_zero_of_notMem _ hu]
    by_cases hu' : u ∈ closedBall (0 : ℂ) R
    · have : ‖u‖ = R := by
        simp only [mem_ball, mem_closedBall, dist_zero_right, not_lt] at hu hu'
        linarith
      rw [this, div_self hR.ne', Real.log_one]; simp
    · rw [Function.locallyFinsuppWithin.apply_eq_zero_of_notMem _ hu']

/-- **Slow growth means few zeros.** Let `f` be holomorphic on the closed disk of radius `2r`
about 0, with `f(0) ≠ 0`, and let `M` bound `|f|` on the circle `|z| = 2r` (for example
`M = M(2r)`, the largest size of `f` there). Then `n(r)`, the number of zeros with `|a| < r`
counted with multiplicity, satisfies `n(r) ≤ (ln M − ln |f(0)|) / ln 2`. -/
theorem zero_count_le_log_growth_div_log_two {f : ℂ → ℂ} {r M : ℝ} (hr : 0 < r)
    (hf : AnalyticOnNhd ℂ f (closedBall (0 : ℂ) (2 * r))) (h0 : f 0 ≠ 0)
    (hM : ∀ z : ℂ, ‖z‖ = 2 * r → ‖f z‖ ≤ M) :
    (∑ᶠ a, (divisor f (ball (0 : ℂ) r) a : ℝ)) ≤ (Real.log M - Real.log ‖f 0‖) / Real.log 2 := by
  have h2r : (2 * r) ≠ 0 := by positivity
  -- maximum modulus: ‖f 0‖ ≤ M
  have hf0M : ‖f 0‖ ≤ M := by
    refine Complex.norm_le_of_forall_mem_frontier_norm_le (U := ball (0 : ℂ) (2 * r))
      isBounded_ball ?_ ?_ ?_
    · exact hf.differentiableOn.diffContOnCl_ball subset_rfl
    · intro z hz
      rw [frontier_ball _ h2r, mem_sphere_iff_norm, sub_zero] at hz
      exact hM z hz
    · rw [closure_ball _ h2r]; simp; positivity
  have hf0 : 0 < ‖f 0‖ := norm_pos_iff.mpr h0
  have hMpos : 0 < M := hf0.trans_le hf0M
  set g : ℂ → ℂ := ((M : ℂ)⁻¹) • f with hg
  have hMc : ((M : ℂ)⁻¹) ≠ 0 := by
    simp [hMpos.ne']
  have hg_an : AnalyticOnNhd ℂ g (closedBall (0 : ℂ) |2 * r|) := by
    rw [abs_of_pos (by positivity)]
    exact fun z hz => (hf z hz).const_smul
  have hg0 : g 0 ≠ 0 := by simp [hg, hMpos.ne', h0]
  have hg_bound : ∀ z ∈ sphere (0 : ℂ) |2 * r|, ‖g z‖ ≤ 1 := by
    intro z hz
    rw [abs_of_pos (by positivity), mem_sphere_iff_norm, sub_zero] at hz
    simp only [hg, Pi.smul_apply, smul_eq_mul, norm_mul, norm_inv, Complex.norm_real,
      Real.norm_eq_abs, abs_of_pos hMpos]
    rw [inv_mul_le_iff₀ hMpos, mul_one]
    exact hM z hz
  have key := hg_an.sum_divisor_le (r := r) (by simp [hr.ne'])
    (by rw [abs_of_pos hr, abs_of_pos (by positivity)]; linarith) le_rfl hg0 hg_bound
  rw [divisor_const_smul hMc] at key
  have hlog : Real.log (1 / ‖g 0‖) / Real.log (2 * r / r)
      = (Real.log M - Real.log ‖f 0‖) / Real.log 2 := by
    have : 2 * r / r = 2 := by field_simp
    rw [this]
    congr 1
    simp only [hg, Pi.smul_apply, smul_eq_mul, norm_mul, norm_inv, Complex.norm_real,
      Real.norm_eq_abs, abs_of_pos hMpos]
    rw [one_div, Real.log_inv, Real.log_mul (by positivity) hf0.ne', Real.log_inv]
    ring
  rw [hlog] at key
  refine le_trans ?_ key
  have hfin := (divisor f (closedBall (0 : ℂ) |r|)).finiteSupport (isCompact_closedBall _ _)
  have hcast := map_finsum (Int.castRingHom ℝ) hfin
  simp only [eq_intCast] at hcast
  rw [hcast]
  refine finsum_le_finsum ?_ ?_ fun u => ?_
  · exact hfin.subset fun u hu => by
      simp only [Function.mem_support, ne_eq, Int.cast_eq_zero] at hu ⊢
      by_contra h
      apply hu
      by_cases hb : u ∈ ball (0 : ℂ) r
      · have hsub : ball (0 : ℂ) r ⊆ closedBall (0 : ℂ) |r| := by
          rw [abs_of_pos hr]; exact ball_subset_closedBall
        have hc : closedBall (0 : ℂ) |r| ⊆ closedBall (0 : ℂ) (2 * r) := by
          rw [abs_of_pos hr]; exact closedBall_subset_closedBall (by linarith)
        rw [← divisor_restrict ((hf.mono hc).meromorphicOn) hsub,
          Function.locallyFinsuppWithin.restrict_apply]
        simpa [hb] using h
      · exact Function.locallyFinsuppWithin.apply_eq_zero_of_notMem _ hb
  · exact hfin.subset fun u hu => by simpa using hu
  · have hc : closedBall (0 : ℂ) |r| ⊆ closedBall (0 : ℂ) (2 * r) := by
      rw [abs_of_pos hr]; exact closedBall_subset_closedBall (by linarith)
    have hsub : ball (0 : ℂ) r ⊆ closedBall (0 : ℂ) |r| := by
      rw [abs_of_pos hr]; exact ball_subset_closedBall
    simp only [Int.cast_le]
    rw [← divisor_restrict ((hf.mono hc).meromorphicOn) hsub,
      Function.locallyFinsuppWithin.restrict_apply]
    split_ifs
    · exact le_rfl
    · exact (hf.mono hc).divisor_nonneg u

/-- **Order bounds the zero count.** Let `f` be entire with `f(0) ≠ 0` and of order at most `ρ`,
in the card's form: for every slack `ε > 0` and all large `r`, `ln M(r) ≤ r^(ρ+ε)`, that is,
`ln |f(z)| ≤ r^(ρ+ε)` on the whole circle `|z| = r`. Then for every `ε > 0` there is a constant
`C` with `n(r) ≤ C r^(ρ+ε)` for all large `r`, where `n(r)` counts the zeros with `|a| < r`
with multiplicity. -/
theorem zero_count_le_const_mul_rpow_of_order_le {f : ℂ → ℂ} {ρ : ℝ}
    (hf : Differentiable ℂ f) (h0 : f 0 ≠ 0)
    (hρ : ∀ ε > 0, ∀ᶠ r in atTop, ∀ z : ℂ, ‖z‖ = r → Real.log ‖f z‖ ≤ r ^ (ρ + ε)) :
    ∀ ε > 0, ∃ C : ℝ, ∀ᶠ r in atTop,
      (∑ᶠ a, (divisor f (ball (0 : ℂ) r) a : ℝ)) ≤ C * r ^ (ρ + ε) := by
  intro ε hε
  obtain ⟨R0, hR0⟩ := eventually_atTop.mp (hρ ε hε)
  set s := ρ + ε with hs
  -- size bound from the log bound
  have hnorm : ∀ z : ℂ, R0 ≤ ‖z‖ → ‖f z‖ ≤ Real.exp (‖z‖ ^ s) := by
    intro z hz
    by_cases hfz : f z = 0
    · rw [hfz, norm_zero]; exact (Real.exp_pos _).le
    · have hpos : 0 < ‖f z‖ := norm_pos_iff.mpr hfz
      rw [← Real.exp_log hpos]
      exact Real.exp_le_exp.mpr (hR0 _ hz z rfl)
  by_cases hs0 : 0 < s
  · refine ⟨(2 ^ s + |Real.log ‖f 0‖|) / Real.log 2, ?_⟩
    filter_upwards [eventually_ge_atTop (max R0 1)] with r hr
    have hr1 : 1 ≤ r := le_of_max_le_right hr
    have hrR0 : R0 ≤ r := le_of_max_le_left hr
    have hr0 : 0 < r := by linarith
    have key := zero_count_le_log_growth_div_log_two (M := Real.exp ((2 * r) ^ s)) hr0
      (fun z _ => hf.analyticAt z) h0 (fun z hz => by
        have := hnorm z (by rw [hz]; linarith)
        rwa [hz] at this)
    rw [Real.log_exp] at key
    refine key.trans ?_
    have hlog2 : 0 < Real.log 2 := Real.log_pos (by norm_num)
    rw [div_mul_eq_mul_div]
    gcongr
    rw [Real.mul_rpow (by norm_num) hr0.le, add_mul]
    have h1 : 1 ≤ r ^ s := Real.one_le_rpow hr1 hs0.le
    have h2 : -Real.log ‖f 0‖ ≤ |Real.log ‖f 0‖| := neg_le_abs _
    nlinarith [abs_nonneg (Real.log ‖f 0‖)]
  · push Not at hs0
    -- f is bounded, hence constant by Liouville
    obtain ⟨B, hB⟩ := (isCompact_closedBall (0 : ℂ) (max R0 1)).exists_bound_of_continuousOn
      hf.continuous.continuousOn
    have hbdd : Bornology.IsBounded (Set.range f) := by
      rw [isBounded_iff_forall_norm_le]
      refine ⟨max B (Real.exp 1), ?_⟩
      rintro _ ⟨z, rfl⟩
      by_cases hz : ‖z‖ ≤ max R0 1
      · exact (hB z (by simpa using hz)).trans (le_max_left _ _)
      · push Not at hz
        refine (hnorm z (le_of_max_le_left hz.le)).trans ((Real.exp_le_exp.mpr ?_).trans
          (le_max_right _ _))
        exact Real.rpow_le_one_of_one_le_of_nonpos (le_of_max_le_right hz.le) hs0
    have hconst : f = fun _ => f 0 := funext fun z => hf.apply_eq_apply_of_bounded hbdd z 0
    refine ⟨0, Eventually.of_forall fun r => ?_⟩
    rw [hconst, divisor_const]
    simp

-- The card's correction for the zero of z - 1/2 on the unit circle: ln(1/(1/2)) = ln 2.
example : Real.log (1 / (1 / 2 : ℝ)) = Real.log 2 := by norm_num

#print axioms jensen_formula
#print axioms zero_count_le_log_growth_div_log_two
#print axioms zero_count_le_const_mul_rpow_of_order_le
