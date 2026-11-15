-- Two evolutions: on a list of mode amounts with eigenvalues at least 0, heat shrinks and smooths while the Schrödinger group keeps every size, their generators are -A and -iA exactly on A's domain, and the wave revives.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Topology.Algebra.InfiniteSum.Real
import Mathlib.Analysis.Normed.Group.Tannery
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds
import Mathlib.Analysis.Calculus.Deriv.Slope
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Sqrt

open Complex Filter Topology

/-! A profile is its list of mode amounts `c n` (Parseval: its size squared is `∑ ‖c n‖²`).
A self-adjoint `A` with a full list of modes acts on mode `n` as the real number `lam n`
(on the bar, `lam n = (n π)²`). The profile is in the domain `D(A)` when `∑ ‖lam n * c n‖²` is finite.
Heat after spread time `z` multiplies mode `n` by `e^(-lam n * z)`;
the Schrödinger group after time `s` multiplies it by `e^(-i lam n s)`. -/

lemma hs_norm_cexp_neg_I (x : ℝ) : ‖cexp (-(I * (x : ℂ)))‖ = 1 := by
  have : -(I * (x : ℂ)) = I * ((-x : ℝ) : ℂ) := by push_cast; ring
  rw [this, Complex.norm_exp_I_mul_ofReal]

#print axioms hs_norm_cexp_neg_I

lemma hs_summable_sub_sq {a b : ℕ → ℂ} (ha : Summable fun n => ‖a n‖ ^ 2)
    (hb : Summable fun n => ‖b n‖ ^ 2) : Summable fun n => ‖a n - b n‖ ^ 2 := by
  refine Summable.of_nonneg_of_le (fun n => by positivity) (fun n => ?_) ((ha.add hb).mul_left 2)
  have h1 := norm_sub_le (a n) (b n)
  have h2 := norm_nonneg (a n - b n)
  nlinarith [sq_nonneg (‖a n‖ - ‖b n‖), norm_nonneg (a n), norm_nonneg (b n)]

#print axioms hs_summable_sub_sq

lemma hs_k_le {k : ℂ} (hk : ‖k‖ ≤ 1) (c : ℂ) : ‖k * c‖ ^ 2 ≤ ‖c‖ ^ 2 := by
  rw [norm_mul]
  have := norm_nonneg c
  have := norm_nonneg k
  have : ‖k‖ * ‖c‖ ≤ ‖c‖ := by nlinarith
  exact pow_le_pow_left₀ (by positivity) this 2

#print axioms hs_k_le

lemma hs_sum_quot (k : ℕ → ℂ) (hk : ∀ n, ‖k n‖ ≤ 1) (c v : ℕ → ℂ)
    (hc : Summable fun n => ‖c n‖ ^ 2) (hv : Summable fun n => ‖v n‖ ^ 2) (t : ℝ) :
    Summable fun n => ‖(k n * c n - c n) / t - v n‖ ^ 2 := by
  apply hs_summable_sub_sq _ hv
  have h1 : Summable fun n => ‖k n * c n‖ ^ 2 :=
    Summable.of_nonneg_of_le (fun n => by positivity) (fun n => hs_k_le (hk n) (c n)) hc
  have h2 := (hs_summable_sub_sq h1 hc).div_const (‖(t : ℂ)‖ ^ 2)
  refine h2.congr (fun n => ?_)
  rw [norm_div, div_pow]

#print axioms hs_sum_quot

lemma hs_tendsto_zero {F : Filter ℝ} (q : ℝ → ℕ → ℂ) (g : ℕ → ℂ) (B : ℕ → ℝ)
    (hB : Summable fun n => B n ^ 2) (hq : ∀ n, Tendsto (fun t => q t n) F (𝓝 (g n)))
    (hqB : ∀ᶠ t in F, ∀ n, ‖q t n‖ ≤ B n) (hgB : ∀ n, ‖g n‖ ≤ B n) :
    Tendsto (fun t => ∑' n, ‖q t n - g n‖ ^ 2) F (𝓝 0) := by
  have h := tendsto_tsum_of_dominated_convergence (𝓕 := F) (f := fun t n => ‖q t n - g n‖ ^ 2)
    (g := fun _ => (0:ℝ)) (bound := fun n => 4 * B n ^ 2) (hB.mul_left 4) ?_ ?_
  · simpa using h
  · intro n
    have : Tendsto (fun t => q t n - g n) F (𝓝 0) := by
      simpa using (hq n).sub_const (g n)
    simpa using (this.norm.pow 2)
  · filter_upwards [hqB] with t ht n
    have h1 := norm_sub_le (q t n) (g n)
    have h2 := ht n
    have h3 := hgB n
    rw [Real.norm_eq_abs, abs_of_nonneg (by positivity)]
    nlinarith [norm_nonneg (q t n - g n), norm_nonneg (q t n), norm_nonneg (g n)]

#print axioms hs_tendsto_zero

lemma hs_coord {F : Filter ℝ} [F.NeBot] (q : ℝ → ℕ → ℂ) (g v : ℕ → ℂ)
    (hq : ∀ n, Tendsto (fun t => q t n) F (𝓝 (g n)))
    (hsum : ∀ᶠ t in F, Summable fun n => ‖q t n - v n‖ ^ 2)
    (hT : Tendsto (fun t => ∑' n, ‖q t n - v n‖ ^ 2) F (𝓝 0)) : v = g := by
  funext n
  have h1 : Tendsto (fun t => ‖q t n - v n‖ ^ 2) F (𝓝 0) := by
    refine tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds hT
      (Eventually.of_forall fun t => by positivity) ?_
    filter_upwards [hsum] with t ht
    exact ht.le_tsum n (fun j _ => by positivity)
  have h2 : Tendsto (fun t => ‖q t n - v n‖) F (𝓝 0) := by
    have := h1.sqrt
    simpa [Real.sqrt_sq (norm_nonneg _)] using this
  have h3 : Tendsto (fun t => q t n) F (𝓝 (v n)) := tendsto_iff_norm_sub_tendsto_zero.2 h2
  exact tendsto_nhds_unique h3 (hq n)

#print axioms hs_coord

lemma hs_slope (a c : ℂ) :
    Tendsto (fun t : ℝ => (cexp ((t : ℂ) * a) * c - c) / t) (𝓝[≠] 0) (𝓝 (a * c)) := by
  have h1 : HasDerivAt (fun t : ℝ => (t : ℂ) * a) (1 * a) 0 :=
    (hasDerivAt_id (0:ℝ)).ofReal_comp.mul_const _
  have h2 := ((h1.cexp).mul_const c).tendsto_slope_zero
  convert h2 using 2 with t
  · simp [div_eq_inv_mul]
  · simp

#print axioms hs_slope

lemma hs_heat_coord (l : ℝ) (c : ℂ) :
    Tendsto (fun z : ℝ => ((Real.exp (-l * z) : ℂ) * c - c) / z) (𝓝[≠] 0)
      (𝓝 (-((l : ℂ) * c))) := by
  have h := hs_slope (-(l : ℂ)) c
  convert h using 2 with t
  · push_cast; ring_nf
  · ring

#print axioms hs_heat_coord

lemma hs_wave_coord (l : ℝ) (c : ℂ) :
    Tendsto (fun s : ℝ => (cexp (-(I * (l * s : ℝ))) * c - c) / s) (𝓝[≠] 0)
      (𝓝 (-(I * ((l : ℂ) * c)))) := by
  have h := hs_slope (-(I * (l : ℂ))) c
  convert h using 2 with t
  · push_cast; ring_nf
  · ring

#print axioms hs_wave_coord

lemma hs_heat_bound (l : ℝ) (hl : 0 ≤ l) (c : ℂ) {z : ℝ} (hz : 0 < z) :
    ‖((Real.exp (-l * z) : ℂ) * c - c) / z‖ ≤ l * ‖c‖ := by
  have e : ((Real.exp (-l * z) : ℂ) * c - c) / z
      = (((Real.exp (-l * z) - 1) / z : ℝ) : ℂ) * c := by
    push_cast; ring
  rw [e, norm_mul, Complex.norm_real, Real.norm_eq_abs]
  gcongr
  have h1 := Real.add_one_le_exp (-l * z)
  have h2 : Real.exp (-l * z) ≤ 1 := Real.exp_le_one_iff.2 (by nlinarith)
  rw [abs_le]; constructor
  · rw [le_div_iff₀ hz]; nlinarith
  · rw [div_le_iff₀ hz]; nlinarith

#print axioms hs_heat_bound

lemma hs_wave_bound (l : ℝ) (hl : 0 ≤ l) (c : ℂ) {s : ℝ} (hs : s ≠ 0) :
    ‖(cexp (-(I * (l * s : ℝ))) * c - c) / s‖ ≤ l * ‖c‖ := by
  have e1 : I * ((-(l * s) : ℝ) : ℂ) = -(I * ((l * s : ℝ) : ℂ)) := by push_cast; ring
  have e : (cexp (-(I * (l * s : ℝ))) * c - c) / s
      = (cexp (I * ((-(l * s) : ℝ) : ℂ)) - 1) * c / s := by
    rw [e1]; ring
  rw [e, norm_div, norm_mul, Complex.norm_real, Real.norm_eq_abs]
  have h1 := Real.norm_exp_I_mul_ofReal_sub_one_le (x := -(l * s))
  rw [Real.norm_eq_abs, abs_neg, abs_mul, abs_of_nonneg hl] at h1
  have hs' : 0 < |s| := abs_pos.2 hs
  rw [div_le_iff₀ hs']
  calc ‖cexp (I * ((-(l * s) : ℝ) : ℂ)) - 1‖ * ‖c‖ ≤ (l * |s|) * ‖c‖ := by gcongr
    _ = l * ‖c‖ * |s| := by ring

#print axioms hs_wave_bound

/-- Heat smooths at once, the wave only rotates. For eigenvalues `lam n ≥ 0`, a profile of finite
size and a spread time `z > 0`: heat never grows the size; after heat the profile is in `A`'s domain
with bend at most its size over `e z`; the wave keeps the size exactly, keeps the profile in `A`'s
domain exactly when it started there (no smoothing), and runs backward as easily as forward. -/
theorem heat_smooths_schrodinger_keeps_size (lam : ℕ → ℝ) (hlam : ∀ n, 0 ≤ lam n)
    (c : ℕ → ℂ) (hc : Summable fun n => ‖c n‖ ^ 2) (z : ℝ) (hz : 0 < z) (s : ℝ) :
    -- heat contracts: ‖T(z) c‖ ≤ ‖c‖
    ((Summable fun n => ‖(Real.exp (-lam n * z) : ℂ) * c n‖ ^ 2) ∧
      ∑' n, ‖(Real.exp (-lam n * z) : ℂ) * c n‖ ^ 2 ≤ ∑' n, ‖c n‖ ^ 2) ∧
    -- heat smooths: T(z) c ∈ D(A) and ‖A T(z) c‖ ≤ ‖c‖ / (e z)
    ((Summable fun n => ‖(lam n : ℂ) * ((Real.exp (-lam n * z) : ℂ) * c n)‖ ^ 2) ∧
      ∑' n, ‖(lam n : ℂ) * ((Real.exp (-lam n * z) : ℂ) * c n)‖ ^ 2
        ≤ (∑' n, ‖c n‖ ^ 2) / (Real.exp 1 * z) ^ 2) ∧
    -- the wave keeps the size: ‖U(s) c‖ = ‖c‖
    (∑' n, ‖cexp (-(I * (lam n * s : ℝ))) * c n‖ ^ 2 = ∑' n, ‖c n‖ ^ 2) ∧
    -- the wave neither smooths nor roughens: U(s) c ∈ D(A) ↔ c ∈ D(A)
    ((Summable fun n => ‖(lam n : ℂ) * (cexp (-(I * (lam n * s : ℝ))) * c n)‖ ^ 2) ↔
      Summable fun n => ‖(lam n : ℂ) * c n‖ ^ 2) ∧
    -- the wave runs both ways: U(-s) U(s) = I
    (∀ n, cexp (-(I * (lam n * (-s) : ℝ))) * (cexp (-(I * (lam n * s : ℝ))) * c n) = c n) := by
  have hk : ∀ n, ‖((Real.exp (-lam n * z) : ℝ) : ℂ)‖ ≤ 1 := fun n => by
    rw [Complex.norm_real, Real.norm_eq_abs, abs_of_pos (Real.exp_pos _)]
    exact Real.exp_le_one_iff.2 (by nlinarith [hlam n])
  have hU : ∀ n, ‖cexp (-(I * (lam n * s : ℝ)))‖ = 1 := fun n => hs_norm_cexp_neg_I _
  have hS1 : Summable fun n => ‖(Real.exp (-lam n * z) : ℂ) * c n‖ ^ 2 :=
    Summable.of_nonneg_of_le (fun n => by positivity) (fun n => hs_k_le (hk n) (c n)) hc
  have hE : ∀ n, ‖(lam n : ℂ) * ((Real.exp (-lam n * z) : ℂ) * c n)‖ ^ 2
      ≤ ‖c n‖ ^ 2 / (Real.exp 1 * z) ^ 2 := by
    intro n
    have ha : ‖(lam n : ℂ) * ((Real.exp (-lam n * z) : ℂ) * c n)‖
        = (lam n * Real.exp (-lam n * z)) * ‖c n‖ := by
      rw [norm_mul, norm_mul, Complex.norm_real, Complex.norm_real, Real.norm_eq_abs,
        Real.norm_eq_abs, abs_of_nonneg (hlam n), abs_of_pos (Real.exp_pos _)]
      ring
    have h1 := Real.mul_exp_neg_le_exp_neg_one (lam n * z)
    have h2 : Real.exp (-1) * Real.exp 1 = 1 := by rw [← Real.exp_add]; simp
    have hA : 0 ≤ lam n * Real.exp (-lam n * z) := mul_nonneg (hlam n) (Real.exp_pos _).le
    have hB : (lam n * Real.exp (-lam n * z)) * (Real.exp 1 * z) ≤ 1 := by
      have : -(lam n * z) = -lam n * z := by ring
      rw [this] at h1
      calc (lam n * Real.exp (-lam n * z)) * (Real.exp 1 * z)
          = (lam n * z * Real.exp (-lam n * z)) * Real.exp 1 := by ring
        _ ≤ Real.exp (-1) * Real.exp 1 := by gcongr
        _ = 1 := h2
    rw [ha, le_div_iff₀ (by positivity)]
    have hB2 : ((lam n * Real.exp (-lam n * z)) * (Real.exp 1 * z)) ^ 2 ≤ 1 :=
      pow_le_one₀ (by positivity) hB
    calc (lam n * Real.exp (-lam n * z) * ‖c n‖) ^ 2 * (Real.exp 1 * z) ^ 2
        = ((lam n * Real.exp (-lam n * z)) * (Real.exp 1 * z)) ^ 2 * ‖c n‖ ^ 2 := by ring
      _ ≤ 1 * ‖c n‖ ^ 2 := by gcongr
      _ = ‖c n‖ ^ 2 := one_mul _
  have hS2 : Summable fun n => ‖(lam n : ℂ) * ((Real.exp (-lam n * z) : ℂ) * c n)‖ ^ 2 :=
    Summable.of_nonneg_of_le (fun n => by positivity) hE (hc.div_const _)
  refine ⟨⟨hS1, hS1.tsum_le_tsum (fun n => hs_k_le (hk n) (c n)) hc⟩, ⟨hS2, ?_⟩, ?_, ?_, ?_⟩
  · rw [← tsum_div_const]
    exact hS2.tsum_le_tsum hE (hc.div_const _)
  · congr 1
    funext n
    rw [norm_mul, hU n, one_mul]
  · have : (fun n => ‖(lam n : ℂ) * (cexp (-(I * (lam n * s : ℝ))) * c n)‖ ^ 2)
        = fun n => ‖(lam n : ℂ) * c n‖ ^ 2 := by
      funext n
      simp only [norm_mul, hU, one_mul]
    rw [this]
  · intro n
    rw [← mul_assoc, ← Complex.exp_add]
    have : -(I * ((lam n * -s : ℝ) : ℂ)) + -(I * ((lam n * s : ℝ) : ℂ)) = 0 := by
      push_cast; ring
    rw [this, Complex.exp_zero, one_mul]

/-- The generators are `-A` for heat and `-iA` for the wave, and each rate exists exactly for
profiles in `A`'s domain: if the profile is in `D(A)`, the difference quotients converge in size
to `-A c` and `-i A c`; if a quotient converges in size to any profile `v`, then the start was in
`D(A)` and `v` is that rate. -/
theorem generators_exactly_on_domain (lam : ℕ → ℝ) (hlam : ∀ n, 0 ≤ lam n)
    (c : ℕ → ℂ) (hc : Summable fun n => ‖c n‖ ^ 2) :
    -- heat: (T(z) c - c) / z → -A c as z → 0⁺, exactly on D(A)
    ((Summable fun n => ‖(lam n : ℂ) * c n‖ ^ 2) →
      Tendsto (fun z : ℝ => ∑' n,
          ‖((Real.exp (-lam n * z) : ℂ) * c n - c n) / z - (-((lam n : ℂ) * c n))‖ ^ 2)
        (𝓝[>] 0) (𝓝 0)) ∧
    (∀ v : ℕ → ℂ, (Summable fun n => ‖v n‖ ^ 2) →
      Tendsto (fun z : ℝ => ∑' n, ‖((Real.exp (-lam n * z) : ℂ) * c n - c n) / z - v n‖ ^ 2)
        (𝓝[>] 0) (𝓝 0) →
      (Summable fun n => ‖(lam n : ℂ) * c n‖ ^ 2) ∧ v = fun n => -((lam n : ℂ) * c n)) ∧
    -- wave: (U(s) c - c) / s → -i A c as s → 0, exactly on D(A)
    ((Summable fun n => ‖(lam n : ℂ) * c n‖ ^ 2) →
      Tendsto (fun s : ℝ => ∑' n,
          ‖(cexp (-(I * (lam n * s : ℝ))) * c n - c n) / s - (-(I * ((lam n : ℂ) * c n)))‖ ^ 2)
        (𝓝[≠] 0) (𝓝 0)) ∧
    (∀ v : ℕ → ℂ, (Summable fun n => ‖v n‖ ^ 2) →
      Tendsto (fun s : ℝ => ∑' n, ‖(cexp (-(I * (lam n * s : ℝ))) * c n - c n) / s - v n‖ ^ 2)
        (𝓝[≠] 0) (𝓝 0) →
      (Summable fun n => ‖(lam n : ℂ) * c n‖ ^ 2) ∧ v = fun n => -(I * ((lam n : ℂ) * c n))) := by
  have hheatq : ∀ n, Tendsto (fun z : ℝ => ((Real.exp (-lam n * z) : ℂ) * c n - c n) / z)
      (𝓝[>] 0) (𝓝 (-((lam n : ℂ) * c n))) := fun n =>
    (hs_heat_coord (lam n) (c n)).mono_left
      (nhdsWithin_mono _ (fun x hx => (show (0:ℝ) < x from hx).ne'))
  have hwaveq : ∀ n, Tendsto (fun s : ℝ => (cexp (-(I * (lam n * s : ℝ))) * c n - c n) / s)
      (𝓝[≠] 0) (𝓝 (-(I * ((lam n : ℂ) * c n)))) := fun n => hs_wave_coord (lam n) (c n)
  have hnormA : ∀ n, ‖(lam n : ℂ) * c n‖ = lam n * ‖c n‖ := fun n => by
    rw [norm_mul, Complex.norm_real, Real.norm_eq_abs, abs_of_nonneg (hlam n)]
  have hk : ∀ z : ℝ, 0 < z → ∀ n, ‖((Real.exp (-lam n * z) : ℝ) : ℂ)‖ ≤ 1 := fun z hz n => by
    rw [Complex.norm_real, Real.norm_eq_abs, abs_of_pos (Real.exp_pos _)]
    exact Real.exp_le_one_iff.2 (by nlinarith [hlam n])
  refine ⟨fun hA => ?_, fun v hv hT => ?_, fun hA => ?_, fun v hv hT => ?_⟩
  · refine hs_tendsto_zero (fun z n => ((Real.exp (-lam n * z) : ℂ) * c n - c n) / z)
      (fun n => -((lam n : ℂ) * c n)) (fun n => lam n * ‖c n‖) ?_ hheatq ?_ ?_
    · exact hA.congr (fun n => by rw [hnormA])
    · filter_upwards [self_mem_nhdsWithin] with z hz n
      exact hs_heat_bound _ (hlam n) _ hz
    · intro n
      rw [norm_neg, hnormA]
  · have hv' := hs_coord (F := 𝓝[>] (0:ℝ))
      (fun z n => ((Real.exp (-lam n * z) : ℂ) * c n - c n) / z)
      (fun n => -((lam n : ℂ) * c n)) v hheatq ?_ hT
    · refine ⟨?_, hv'⟩
      have : Summable fun n => ‖v n‖ ^ 2 := hv
      rw [hv'] at this
      simpa only [norm_neg] using this
    · filter_upwards [self_mem_nhdsWithin] with z hz
      exact hs_sum_quot (fun n => (Real.exp (-lam n * z) : ℂ)) (hk z hz) c v hc hv z
  · refine hs_tendsto_zero (fun s n => (cexp (-(I * (lam n * s : ℝ))) * c n - c n) / s)
      (fun n => -(I * ((lam n : ℂ) * c n))) (fun n => lam n * ‖c n‖) ?_ hwaveq ?_ ?_
    · exact hA.congr (fun n => by rw [hnormA])
    · filter_upwards [self_mem_nhdsWithin] with s hs n
      exact hs_wave_bound _ (hlam n) _ hs
    · intro n
      rw [norm_neg, norm_mul, Complex.norm_I, one_mul, hnormA]
  · have hv' := hs_coord (F := 𝓝[≠] (0:ℝ))
      (fun s n => (cexp (-(I * (lam n * s : ℝ))) * c n - c n) / s)
      (fun n => -(I * ((lam n : ℂ) * c n))) v hwaveq ?_ hT
    · refine ⟨?_, hv'⟩
      have : Summable fun n => ‖v n‖ ^ 2 := hv
      rw [hv'] at this
      exact this.congr (fun n => by rw [norm_neg, norm_mul, Complex.norm_I, one_mul])
    · refine Eventually.of_forall (fun s => ?_)
      exact hs_sum_quot (fun n => cexp (-(I * (lam n * s : ℝ))))
        (fun n => (hs_norm_cexp_neg_I _).le) c v hc hv s

/-- Revival on the bar, where mode `n` has eigenvalue `(n π)²`: at `s = 2/π` every start returns
exactly, and at `s = 1/(4π)` a start made of odd modes only (like the symmetric pulse) returns
whole, every mode turned by the same angle `π/4`. -/
theorem schrodinger_revival_on_the_bar (c : ℕ → ℂ) :
    (∀ n : ℕ, cexp (-(I * ((((n : ℝ) * Real.pi) ^ 2 * (2 / Real.pi) : ℝ) : ℂ))) * c n = c n) ∧
    ((∀ n : ℕ, Even n → c n = 0) →
      ∀ n : ℕ, cexp (-(I * ((((n : ℝ) * Real.pi) ^ 2 * (1 / (4 * Real.pi)) : ℝ) : ℂ))) * c n
        = cexp (-(I * ((Real.pi / 4 : ℝ) : ℂ))) * c n) := by
  constructor
  · intro n
    have e : ((((n : ℝ) * Real.pi) ^ 2 * (2 / Real.pi) : ℝ) : ℂ) = (n : ℂ) ^ 2 * (2 * Real.pi) := by
      have hp : (Real.pi : ℂ) ≠ 0 := Complex.ofReal_ne_zero.2 Real.pi_ne_zero
      push_cast
      field_simp
    have : cexp (-(I * ((((n : ℝ) * Real.pi) ^ 2 * (2 / Real.pi) : ℝ) : ℂ))) = 1 := by
      rw [e, ← Complex.exp_int_mul_two_pi_mul_I (-(n : ℤ) ^ 2)]
      congr 1
      push_cast
      ring
    rw [this, one_mul]
  · intro hev n
    rcases Nat.even_or_odd n with he | ho
    · rw [hev n he, mul_zero, mul_zero]
    · obtain ⟨k, rfl⟩ := ho
      obtain ⟨j, hj⟩ := Nat.even_mul_succ_self k
      have hsq : (((2 * k + 1 : ℕ) : ℝ)) ^ 2 = 8 * j + 1 := by
        have : (k : ℝ) * (k + 1) = j + j := by exact_mod_cast hj
        push_cast
        nlinarith [this]
      congr 1
      have e : ((((2 * k + 1 : ℕ) : ℝ) * Real.pi) ^ 2 * (1 / (4 * Real.pi)) : ℝ)
          = Real.pi / 4 + j * (2 * Real.pi) := by
        have hp : Real.pi ≠ 0 := Real.pi_ne_zero
        rw [mul_pow, hsq]
        field_simp
        ring
      rw [e]
      rw [show -(I * (((Real.pi / 4 + j * (2 * Real.pi) : ℝ)) : ℂ))
          = -(I * ((Real.pi / 4 : ℝ) : ℂ)) + ((-(j : ℤ) : ℤ) : ℂ) * (2 * Real.pi * I) by
        push_cast; ring]
      rw [Complex.exp_add, Complex.exp_int_mul_two_pi_mul_I, mul_one]

-- Step 6: for odd n, n² - 1 is a multiple of 8 (checked for every odd n below 200).
set_option maxRecDepth 20000 in
example : ∀ n < 200, n % 2 = 1 → (n ^ 2 - 1) % 8 = 0 := by decide

-- The struck bar's size squared: 100 °C squared over a band 0.2 m wide is 2000.
example : (100 : ℚ) ^ 2 * (6 / 10 - 4 / 10) = 2000 := by norm_num

#print axioms heat_smooths_schrodinger_keeps_size
#print axioms generators_exactly_on_domain
#print axioms schrodinger_revival_on_the_bar
