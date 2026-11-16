-- Subharmonic functions: an under shape stays under every harmonic function above it on the wall, and on a bounded plane region with bounded wall data and a barrier at each wall point, the top of all under shapes is harmonic and meets the wall data wherever the data are continuous.
import Mathlib.Analysis.InnerProductSpace.Harmonic.Basic
import Mathlib.MeasureTheory.Integral.CircleAverage
import Mathlib.Analysis.Complex.Harmonic.Poisson
import Mathlib.Analysis.Complex.Harmonic.MeanValue
import Mathlib.Analysis.InnerProductSpace.Harmonic.Constructions

open Metric Filter Real InnerProductSpace
open scoped Topology

namespace Perron

/-- The card's subharmonic: `v` is continuous on `Ω`, and at each point its value is at most its
average round every circle whose closed disc fits inside `Ω`. -/
def IsSubharmonicOn (v : ℂ → ℝ) (Ω : Set ℂ) : Prop :=
  ContinuousOn v Ω ∧ ∀ x : ℂ, ∀ r : ℝ, 0 < r → closedBall x r ⊆ Ω → v x ≤ circleAverage v x r

/-- The card's superharmonic: the same with the inequality reversed. -/
def IsSuperharmonicOn (w : ℂ → ℝ) (Ω : Set ℂ) : Prop :=
  ContinuousOn w Ω ∧ ∀ x : ℂ, ∀ r : ℝ, 0 < r → closedBall x r ⊆ Ω → circleAverage w x r ≤ w x

/-- An under shape for wall data `g`: continuous on the closed region, subharmonic inside,
and at most `g` on the wall. -/
def IsUnderShape (Ω : Set ℂ) (g : ℂ → ℝ) (v : ℂ → ℝ) : Prop :=
  ContinuousOn v (closure Ω) ∧ IsSubharmonicOn v Ω ∧ ∀ p ∈ frontier Ω, v p ≤ g p

/-- An over shape for wall data `g`: continuous on the closed region, superharmonic inside,
and at least `g` on the wall. -/
def IsOverShape (Ω : Set ℂ) (g : ℂ → ℝ) (w : ℂ → ℝ) : Prop :=
  ContinuousOn w (closure Ω) ∧ IsSuperharmonicOn w Ω ∧ ∀ p ∈ frontier Ω, g p ≤ w p

/-- Perron's function: at each point, the least upper bound of the values of all under shapes. -/
noncomputable def perron (Ω : Set ℂ) (g : ℂ → ℝ) (x : ℂ) : ℝ :=
  sSup ((fun v : ℂ → ℝ => v x) '' {v | IsUnderShape Ω g v})

/-- A barrier at the wall point `p`: superharmonic inside, continuous on the closed region,
`0` at `p` and positive at every other point of the closed region. -/
def HasBarrier (Ω : Set ℂ) (p : ℂ) : Prop :=
  ∃ b : ℂ → ℝ, ContinuousOn b (closure Ω) ∧ IsSuperharmonicOn b Ω ∧ b p = 0 ∧
    ∀ x ∈ closure Ω, x ≠ p → 0 < b x

lemma avg_lt_of_le_of_lt (f : ℂ → ℝ) (c : ℂ) {r : ℝ} (hr : 0 < r) (M : ℝ)
    (hf : ContinuousOn f (sphere c r)) (hle : ∀ z ∈ sphere c r, f z ≤ M)
    (hlt : f (c + r) < M) : circleAverage f c r < M := by
  rw [circleAverage_def, smul_eq_mul]
  have h2pi : 0 < 2 * π := by positivity
  have hmem : ∀ θ, circleMap c r θ ∈ sphere c r := fun θ => circleMap_mem_sphere c hr.le θ
  have hcont : Continuous (fun θ => f (circleMap c r θ)) :=
    hf.comp_continuous (continuous_circleMap c r) hmem
  have key := intervalIntegral.integral_lt_integral_of_continuousOn_of_le_of_exists_lt h2pi
    hcont.continuousOn (continuousOn_const (c := M)) (fun θ _ => hle _ (hmem θ))
    ⟨0, ⟨le_refl _, h2pi.le⟩, by simpa [circleMap] using hlt⟩
  rw [intervalIntegral.integral_const, smul_eq_mul, sub_zero] at key
  calc (2 * π)⁻¹ * ∫ θ in 0..2 * π, f (circleMap c r θ) < (2 * π)⁻¹ * (2 * π * M) := by
        gcongr
    _ = M := by field_simp

lemma max_principle (U : Set ℂ) (hU : IsOpen U) (hb : Bornology.IsBounded U) (w : ℂ → ℝ)
    (hw : ContinuousOn w (closure U))
    (hloc : ∀ y ∈ U, ∃ s > 0, closedBall y s ⊆ U ∧ w y ≤ circleAverage w y s)
    (hfr : ∀ p ∈ frontier U, w p ≤ 0) : ∀ x ∈ U, w x ≤ 0 := by
  intro x hx
  by_contra hcon
  push Not at hcon
  have hK : IsCompact (closure U) := hb.isCompact_closure
  obtain ⟨m, hm, hmax⟩ := hK.exists_isMaxOn ⟨x, subset_closure hx⟩ hw
  have hKc : IsCompact (closure U ∩ w ⁻¹' {w m}) :=
    hK.of_isClosed_subset (hw.preimage_isClosed_of_isClosed isClosed_closure isClosed_singleton)
      Set.inter_subset_left
  obtain ⟨z, hz, hzmax⟩ := hKc.exists_isMaxOn ⟨m, hm, rfl⟩ Complex.continuous_re.continuousOn
  have hwz : w z = w m := hz.2
  have hMpos : 0 < w m := lt_of_lt_of_le hcon (hmax (subset_closure hx))
  have hzU : z ∈ U := by
    by_contra hzU
    have : z ∈ frontier U := by rw [hU.frontier_eq]; exact ⟨hz.1, hzU⟩
    have := hfr z this
    linarith
  obtain ⟨s, hs, hball, hle⟩ := hloc z hzU
  have hsph : sphere z s ⊆ closure U :=
    sphere_subset_closedBall.trans (hball.trans subset_closure)
  have hlt : circleAverage w z s < w m := by
    apply avg_lt_of_le_of_lt w z hs (w m) (hw.mono hsph) (fun y hy => hmax (hsph hy))
    have hmem : z + (s : ℂ) ∈ closure U := hsph (by simp [abs_of_pos hs])
    have h' : w (z + (s : ℂ)) ≤ w m := hmax hmem
    rcases h'.lt_or_eq with h | h
    · exact h
    · exfalso
      have := hzmax ⟨hmem, h⟩
      simp at this
      linarith
  linarith

def LocSub (w : ℂ → ℝ) (U : Set ℂ) : Prop :=
  ∀ y ∈ U, ∀ᶠ s in 𝓝[>] (0 : ℝ), w y ≤ circleAverage w y s

def LocSuper (w : ℂ → ℝ) (U : Set ℂ) : Prop :=
  ∀ y ∈ U, ∀ᶠ s in 𝓝[>] (0 : ℝ), circleAverage w y s ≤ w y

lemma eventually_closedBall_subset {U : Set ℂ} (hU : IsOpen U) {y : ℂ} (hy : y ∈ U) :
    ∀ᶠ s in 𝓝[>] (0 : ℝ), closedBall y s ⊆ U := by
  obtain ⟨ε, hε, hball⟩ := Metric.isOpen_iff.1 hU y hy
  filter_upwards [Ioo_mem_nhdsGT hε] with s hs
  exact (closedBall_subset_ball hs.2).trans hball

lemma locSub_exists {U : Set ℂ} (hU : IsOpen U) {w : ℂ → ℝ} (h : LocSub w U) :
    ∀ y ∈ U, ∃ s > 0, closedBall y s ⊆ U ∧ w y ≤ circleAverage w y s := by
  intro y hy
  obtain ⟨s, h1, h2, h3⟩ :=
    ((h y hy).and ((eventually_closedBall_subset hU hy).and self_mem_nhdsWithin)).exists
  exact ⟨s, h3, h2, h1⟩

lemma IsSubharmonicOn.locSub {v : ℂ → ℝ} {U : Set ℂ} (hU : IsOpen U) (hv : IsSubharmonicOn v U) :
    LocSub v U := by
  intro y hy
  filter_upwards [eventually_closedBall_subset hU hy, self_mem_nhdsWithin] with s hs hpos
  exact hv.2 y s hpos hs

lemma IsSuperharmonicOn.locSuper {v : ℂ → ℝ} {U : Set ℂ} (hU : IsOpen U)
    (hv : IsSuperharmonicOn v U) : LocSuper v U := by
  intro y hy
  filter_upwards [eventually_closedBall_subset hU hy, self_mem_nhdsWithin] with s hs hpos
  exact hv.2 y s hpos hs

lemma harmonic_avg_eq {u : ℂ → ℝ} {U : Set ℂ} (hu : HarmonicOnNhd u U) {y : ℂ} {s : ℝ}
    (hs : 0 < s) (hball : closedBall y s ⊆ U) : circleAverage u y s = u y := by
  apply InnerProductSpace.HarmonicOnNhd.circleAverage_eq
  rw [abs_of_pos hs]
  exact hu.mono hball

lemma harmonic_locSuper {u : ℂ → ℝ} {U : Set ℂ} (hU : IsOpen U) (hu : HarmonicOnNhd u U) :
    LocSuper u U := by
  intro y hy
  filter_upwards [eventually_closedBall_subset hU hy, self_mem_nhdsWithin] with s hs hpos
  exact (harmonic_avg_eq hu hpos hs).le

lemma harmonic_locSub {u : ℂ → ℝ} {U : Set ℂ} (hU : IsOpen U) (hu : HarmonicOnNhd u U) :
    LocSub u U := by
  intro y hy
  filter_upwards [eventually_closedBall_subset hU hy, self_mem_nhdsWithin] with s hs hpos
  exact (harmonic_avg_eq hu hpos hs).ge

lemma locSub_sub {U : Set ℂ} (hU : IsOpen U) {v w : ℂ → ℝ} (hv : ContinuousOn v U)
    (hw : ContinuousOn w U) (h1 : LocSub v U) (h2 : LocSuper w U) :
    LocSub (fun z => v z - w z) U := by
  intro y hy
  filter_upwards [h1 y hy, h2 y hy, eventually_closedBall_subset hU hy, self_mem_nhdsWithin]
    with s h1 h2 hs hpos
  have hsph : sphere y s ⊆ U := sphere_subset_closedBall.trans hs
  rw [circleAverage_fun_sub (ContinuousOn.circleIntegrable hpos.le (hv.mono hsph))
    (ContinuousOn.circleIntegrable hpos.le (hw.mono hsph))]
  linarith

lemma compare (U : Set ℂ) (hU : IsOpen U) (hb : Bornology.IsBounded U) (v w : ℂ → ℝ)
    (hv : ContinuousOn v (closure U)) (hw : ContinuousOn w (closure U))
    (h1 : LocSub v U) (h2 : LocSuper w U) (hfr : ∀ p ∈ frontier U, v p ≤ w p) :
    ∀ x ∈ U, v x ≤ w x := by
  intro x hx
  have := max_principle U hU hb (fun z => v z - w z) (hv.sub hw)
    (locSub_exists hU (locSub_sub hU (hv.mono subset_closure) (hw.mono subset_closure) h1 h2))
    (fun p hp => sub_nonpos.2 (hfr p hp)) x hx
  exact sub_nonpos.1 this

lemma const_locSuper (a : ℝ) (U : Set ℂ) : LocSuper (fun _ => a) U :=
  fun _ _ => Eventually.of_forall fun s => (circleAverage_const a _ s).le

lemma const_subharmonic (a : ℝ) (U : Set ℂ) : IsSubharmonicOn (fun _ => a) U :=
  ⟨continuousOn_const, fun x r _ _ => (circleAverage_const a x r).ge⟩

lemma under_le_bound {Ω : Set ℂ} (hΩ : IsOpen Ω) (hbdd : Bornology.IsBounded Ω) {g : ℂ → ℝ}
    {M : ℝ} (hM : ∀ p ∈ frontier Ω, |g p| ≤ M) {v : ℂ → ℝ} (hv : IsUnderShape Ω g v) :
    ∀ x ∈ Ω, v x ≤ M :=
  compare Ω hΩ hbdd v (fun _ => M) hv.1 continuousOn_const (hv.2.1.locSub hΩ)
    (const_locSuper M Ω) (fun p hp => (hv.2.2 p hp).trans ((le_abs_self _).trans (hM p hp)))

lemma const_under {Ω : Set ℂ} {g : ℂ → ℝ} {M : ℝ} (hM : ∀ p ∈ frontier Ω, |g p| ≤ M) :
    IsUnderShape Ω g (fun _ => -M) :=
  ⟨continuousOn_const, const_subharmonic _ _, fun p hp => by
    have := hM p hp; rw [abs_le] at this; linarith⟩

lemma perron_bddAbove {Ω : Set ℂ} (hΩ : IsOpen Ω) (hbdd : Bornology.IsBounded Ω) {g : ℂ → ℝ}
    {M : ℝ} (hM : ∀ p ∈ frontier Ω, |g p| ≤ M) {x : ℂ} (hx : x ∈ Ω) :
    BddAbove ((fun v : ℂ → ℝ => v x) '' {v | IsUnderShape Ω g v}) := by
  refine ⟨M, ?_⟩
  rintro _ ⟨v, hv, rfl⟩
  exact under_le_bound hΩ hbdd hM hv x hx

lemma perron_nonempty {Ω : Set ℂ} {g : ℂ → ℝ} {M : ℝ} (hM : ∀ p ∈ frontier Ω, |g p| ≤ M)
    (x : ℂ) : ((fun v : ℂ → ℝ => v x) '' {v | IsUnderShape Ω g v}).Nonempty :=
  ⟨_, ⟨_, const_under hM, rfl⟩⟩

lemma le_perron {Ω : Set ℂ} (hΩ : IsOpen Ω) (hbdd : Bornology.IsBounded Ω) {g : ℂ → ℝ}
    {M : ℝ} (hM : ∀ p ∈ frontier Ω, |g p| ≤ M) {x : ℂ} (hx : x ∈ Ω) {v : ℂ → ℝ}
    (hv : IsUnderShape Ω g v) : v x ≤ perron Ω g x :=
  le_csSup (perron_bddAbove hΩ hbdd hM hx) ⟨v, hv, rfl⟩

lemma perron_le_of {Ω : Set ℂ} {g : ℂ → ℝ} {M : ℝ} (hM : ∀ p ∈ frontier Ω, |g p| ≤ M)
    {x : ℂ} {a : ℝ} (h : ∀ v, IsUnderShape Ω g v → v x ≤ a) : perron Ω g x ≤ a :=
  csSup_le (perron_nonempty hM x) (by rintro _ ⟨v, hv, rfl⟩; exact h v hv)

lemma trapped_aux (Ω : Set ℂ) (hΩ : IsOpen Ω)
    (hbdd : Bornology.IsBounded Ω) (g : ℂ → ℝ) (hg : ∃ M : ℝ, ∀ p ∈ frontier Ω, |g p| ≤ M)
    (v w : ℂ → ℝ) (hv : IsUnderShape Ω g v) (hw : IsOverShape Ω g w) :
    ∀ x ∈ Ω, v x ≤ perron Ω g x ∧ perron Ω g x ≤ w x := by
  obtain ⟨M, hM⟩ := hg
  intro x hx
  refine ⟨le_perron hΩ hbdd hM hx hv, perron_le_of hM fun u hu => ?_⟩
  exact compare Ω hΩ hbdd u w hu.1 hw.1 (hu.2.1.locSub hΩ) (hw.2.1.locSuper hΩ)
    (fun p hp => (hu.2.2 p hp).trans (hw.2.2 p hp)) x hx

lemma stays_under_aux (Ω : Set ℂ) (hΩ : IsOpen Ω)
    (hbdd : Bornology.IsBounded Ω) (v u : ℂ → ℝ) (hv : ContinuousOn v (closure Ω))
    (hvs : IsSubharmonicOn v Ω) (hu : ContinuousOn u (closure Ω)) (huh : HarmonicOnNhd u Ω)
    (hle : ∀ p ∈ frontier Ω, v p ≤ u p) :
    ∀ x ∈ Ω, v x ≤ u x :=
  compare Ω hΩ hbdd v u hv hu (hvs.locSub hΩ) (harmonic_locSuper hΩ huh) hle


/-- The Poisson integral of `g` over the circle of centre `c` and radius `r`. -/
noncomputable def PI (c : ℂ) (r : ℝ) (g : ℂ → ℝ) (w : ℂ) : ℝ :=
  circleAverage (poissonKernel c w • g) c r

lemma pk_nonneg {c w z : ℂ} {r : ℝ} (hw : w ∈ ball c r) (hz : z ∈ sphere c r) :
    0 ≤ poissonKernel c w z := by
  rw [poissonKernel_def]
  rw [mem_sphere_iff_norm] at hz
  rw [mem_ball_iff_norm] at hw
  apply div_nonneg _ (sq_nonneg _)
  rw [hz, sub_nonneg]
  exact pow_le_pow_left₀ (norm_nonneg _) hw.le 2

lemma pk_le {c w z : ℂ} {r : ℝ} (hw : w ∈ ball c r) (hz : z ∈ sphere c r) :
    poissonKernel c w z ≤ (r + ‖w - c‖) / (r - ‖w - c‖) := by
  have := re_herglotzRieszKernel_le hz hw
  rw [poissonKernel_eq_re_herglotzRieszKernel]
  simpa [herglotzRieszKernel_def] using this

lemma pk_cont {c w : ℂ} {r : ℝ} (hr : 0 < r) (hw : w ∈ ball c r) :
    ContinuousOn (poissonKernel c w) (sphere c r) := by
  rw [poissonKernel_eq_re_herglotzRieszKernel]
  have hw' : w ∉ sphere c |r| := by
    rw [abs_of_pos hr]
    intro h
    rw [mem_sphere] at h
    rw [mem_ball] at hw
    linarith
  have := continuousOn_herglotzRieszKernel_sphere hw'
  rw [abs_of_pos hr] at this
  exact Complex.continuous_re.comp_continuousOn this

lemma pk_avg {c w : ℂ} {r : ℝ} (hw : w ∈ ball c r) :
    circleAverage (poissonKernel c w) c r = 1 := by
  have := HarmonicContOnCl.circleAverage_poissonKernel_smul
    (harmonicContOnCl_const (c := (1 : ℝ)) (s := ball c r)) hw
  convert this using 2
  funext z
  simp

lemma PI_center {c : ℂ} {r : ℝ} (hr : 0 < r) (g : ℂ → ℝ) :
    PI c r g c = circleAverage g c r := by
  unfold PI
  apply circleAverage_congr_sphere
  intro z hz
  rw [abs_of_pos hr, mem_sphere_iff_norm] at hz
  have hz0 : ‖z - c‖ ≠ 0 := by rw [hz]; exact hr.ne'
  simp [poissonKernel_def, hz0]

lemma PI_integrable {c w : ℂ} {r : ℝ} (hr : 0 < r) (hw : w ∈ ball c r) {g : ℂ → ℝ}
    (hg : CircleIntegrable g c r) : CircleIntegrable (poissonKernel c w • g) c r :=
  hg.continuousOn_smul (by rw [abs_of_pos hr]; exact pk_cont hr hw)

lemma PI_mono {c w : ℂ} {r : ℝ} (hr : 0 < r) (hw : w ∈ ball c r) {g g' : ℂ → ℝ}
    (hg : CircleIntegrable g c r) (hg' : CircleIntegrable g' c r)
    (hle : ∀ z ∈ sphere c r, g z ≤ g' z) : PI c r g w ≤ PI c r g' w := by
  apply circleAverage_mono (PI_integrable hr hw hg) (PI_integrable hr hw hg')
  intro z hz
  rw [abs_of_pos hr] at hz
  simp only [Pi.smul_apply, smul_eq_mul]
  exact mul_le_mul_of_nonneg_left (hle z hz) (pk_nonneg hw hz)

lemma PI_sub {c w : ℂ} {r : ℝ} (hr : 0 < r) (hw : w ∈ ball c r) {g g' : ℂ → ℝ}
    (hg : CircleIntegrable g c r) (hg' : CircleIntegrable g' c r) :
    PI c r (fun z => g' z - g z) w = PI c r g' w - PI c r g w := by
  unfold PI
  rw [← circleAverage_sub (PI_integrable hr hw hg') (PI_integrable hr hw hg)]
  congr 1
  funext z
  simp [mul_sub]

lemma PI_le_avg {c w : ℂ} {r : ℝ} (hr : 0 < r) (hw : w ∈ ball c r) {d : ℂ → ℝ}
    (hd : CircleIntegrable d c r) (hd0 : ∀ z ∈ sphere c r, 0 ≤ d z) :
    PI c r d w ≤ (r + ‖w - c‖) / (r - ‖w - c‖) * circleAverage d c r := by
  unfold PI
  rw [← smul_eq_mul, ← circleAverage_fun_smul]
  apply circleAverage_mono (PI_integrable hr hw hd) (hd.const_smul)
  intro z hz
  rw [abs_of_pos hr] at hz
  simp only [Pi.smul_apply, smul_eq_mul]
  exact mul_le_mul_of_nonneg_right (pk_le hw hz) (hd0 z hz)

lemma PI_harmonic {c : ℂ} {r : ℝ} (hr : 0 < r) {g : ℂ → ℝ} (hg : CircleIntegrable g c r) :
    HarmonicOnNhd (PI c r g) (ball c r) := by
  set G : ℂ → ℝ := fun ζ => g (ζ + c) with hGdef
  have hG : CircleIntegrable G 0 r := by
    unfold CircleIntegrable at hg ⊢
    convert hg using 2 with θ
    simp [G, circleMap, add_comm]
  have hGc : CircleIntegrable (fun ζ => ((G ζ : ℝ) : ℂ)) 0 r := by
    simp only [CircleIntegrable, intervalIntegrable_iff] at hG ⊢
    exact Complex.ofRealCLM.integrable_comp hG
  set F : ℂ → ℂ := fun u => circleAverage (fun ζ ↦ herglotzRieszKernel 0 u ζ • ((G ζ : ℝ) : ℂ)) 0 r
  have hF := analyticOnNhd_circleAverage_herglotzRieszKernel_smul hGc
  have hnot : ∀ w ∈ ball c r, w - c ∉ sphere (0 : ℂ) |r| := by
    intro w hw h
    rw [abs_of_pos hr, mem_sphere_iff_norm, sub_zero] at h
    rw [mem_ball_iff_norm] at hw
    linarith
  have heq : ∀ w ∈ ball c r, PI c r g w = (F (w - c)).re := by
    intro w hw
    rw [re_circleAverage_herglotzRieszKernel_smul hG (hnot w hw), PI,
      ← circleAverage_map_add_const]
    congr 1
    funext ζ
    simp only [smul_eq_mul, G]
    rw [poissonKernel_eq_re_herglotzRieszKernel]
    simp only [Pi.mul_apply, Function.comp_apply, herglotzRieszKernel_add_const]
  intro w hw
  rw [harmonicAt_congr_nhds (f₂ := fun w => (F (w - c)).re)]
  · apply AnalyticAt.harmonicAt_re
    exact AnalyticAt.comp (f := fun w' : ℂ => w' - c) (x := w) (hF (w - c) (hnot w hw))
      (analyticAt_id.sub analyticAt_const)
  · filter_upwards [isOpen_ball.mem_nhds hw] with w' hw'
    exact heq w' hw'

lemma PI_tendsto {c : ℂ} {r : ℝ} (hr : 0 < r) {g : ℂ → ℝ} (hg : ContinuousOn g (sphere c r))
    {ζ : ℂ} (hζ : ζ ∈ sphere c r) : Tendsto (PI c r g) (𝓝[ball c r] ζ) (𝓝 (g ζ)) := by
  rw [Metric.tendsto_nhdsWithin_nhds]
  intro ε hε
  obtain ⟨K, hK⟩ := (isCompact_sphere c r).exists_bound_of_continuousOn hg
  have hK0 : 0 ≤ K := (norm_nonneg _).trans (hK ζ hζ)
  obtain ⟨η, hη, hgη⟩ := Metric.continuousOn_iff.1 hg ζ hζ (ε / 2) (by linarith)
  set A := 16 * K * r / η ^ 2 with hAdef
  have hA : 0 ≤ A := by positivity
  refine ⟨min (η / 2) (ε / (2 * (A + 1))), by positivity, ?_⟩
  intro w hw hwd
  have hwd1 : dist w ζ < η / 2 := lt_of_lt_of_le hwd (min_le_left _ _)
  have hwd2 : dist w ζ < ε / (2 * (A + 1)) := lt_of_lt_of_le hwd (min_le_right _ _)
  have hpk := pk_cont hr hw
  have hpt : ∀ z ∈ sphere c r,
      poissonKernel c w z * |g z - g ζ| ≤ ε / 2 * poissonKernel c w z + A * dist w ζ := by
    intro z hz
    have hP := pk_nonneg hw hz
    have hd0 : 0 ≤ dist w ζ := dist_nonneg
    by_cases h : dist z ζ < η
    · have h1 : |g z - g ζ| ≤ ε / 2 := by
        have := hgη z hz h
        rw [Real.dist_eq] at this
        exact this.le
      have := mul_le_mul_of_nonneg_left h1 hP
      nlinarith
    · push Not at h
      have hzr : ‖z - c‖ = r := mem_sphere_iff_norm.1 hz
      have hwr : ‖w - c‖ < r := mem_ball_iff_norm.1 hw
      have hD : η / 2 ≤ ‖z - w‖ := by
        have := dist_triangle z w ζ
        rw [dist_eq_norm, dist_eq_norm, dist_eq_norm] at this
        rw [dist_eq_norm] at h hwd1
        linarith
      have hrd : r - ‖w - c‖ ≤ dist w ζ := by
        have h1 : ‖ζ - c‖ = r := mem_sphere_iff_norm.1 hζ
        have h2 := norm_sub_le_norm_sub_add_norm_sub ζ w c
        rw [dist_comm, dist_eq_norm]
        linarith
      have hnum : r ^ 2 - ‖w - c‖ ^ 2 ≤ 2 * r * dist w ζ := by
        have : r ^ 2 - ‖w - c‖ ^ 2 = (r - ‖w - c‖) * (r + ‖w - c‖) := by ring
        rw [this]
        have h3 : r + ‖w - c‖ ≤ 2 * r := by linarith
        have h4 : 0 ≤ r - ‖w - c‖ := by linarith
        calc (r - ‖w - c‖) * (r + ‖w - c‖) ≤ dist w ζ * (2 * r) := by
              apply mul_le_mul hrd h3 (by positivity) hd0
          _ = 2 * r * dist w ζ := by ring
      have hP' : poissonKernel c w z ≤ 2 * r * dist w ζ / (η / 2) ^ 2 := by
        rw [poissonKernel_def, hzr, sub_sub_sub_cancel_right]
        have hnn : 0 ≤ r ^ 2 - ‖w - c‖ ^ 2 := by nlinarith [norm_nonneg (w - c)]
        calc (r ^ 2 - ‖w - c‖ ^ 2) / ‖z - w‖ ^ 2 ≤ (r ^ 2 - ‖w - c‖ ^ 2) / (η / 2) ^ 2 := by
              apply div_le_div_of_nonneg_left hnn (by positivity)
              exact pow_le_pow_left₀ (by positivity) hD 2
          _ ≤ 2 * r * dist w ζ / (η / 2) ^ 2 := by gcongr
      have hgd : |g z - g ζ| ≤ 2 * K := by
        have h1 := hK z hz
        have h2 := hK ζ hζ
        rw [Real.norm_eq_abs] at h1 h2
        calc |g z - g ζ| ≤ |g z| + |g ζ| := abs_sub _ _
          _ ≤ 2 * K := by linarith
      have : poissonKernel c w z * |g z - g ζ| ≤ 2 * r * dist w ζ / (η / 2) ^ 2 * (2 * K) :=
        mul_le_mul hP' hgd (abs_nonneg _) (by positivity)
      have hAe : 2 * r * dist w ζ / (η / 2) ^ 2 * (2 * K) = A * dist w ζ := by
        rw [hAdef]; field_simp; ring
      nlinarith
  have hid : PI c r g w - g ζ =
      circleAverage (fun z => poissonKernel c w z * (g z - g ζ)) c r := by
    have hfun : (fun z => poissonKernel c w z * (g z - g ζ)) =
        fun z => (poissonKernel c w • g) z - g ζ • poissonKernel c w z := by
      funext z; simp only [Pi.mul_apply, smul_eq_mul]; ring
    rw [hfun, circleAverage_fun_sub, circleAverage_fun_smul, pk_avg hw]
    · simp [PI]
    · apply ContinuousOn.circleIntegrable hr.le
      show ContinuousOn (fun z => poissonKernel c w z * g z) _
      exact hpk.mul hg
    · apply ContinuousOn.circleIntegrable hr.le
      show ContinuousOn (fun z => g ζ * poissonKernel c w z) _
      exact continuousOn_const.mul hpk
  rw [Real.dist_eq, hid]
  have hint1 : CircleIntegrable (|fun z => poissonKernel c w z * (g z - g ζ)|) c r := by
    apply ContinuousOn.circleIntegrable hr.le
    exact (hpk.mul (hg.sub continuousOn_const)).abs
  have hint2 : CircleIntegrable (fun z => ε / 2 * poissonKernel c w z + A * dist w ζ) c r := by
    apply ContinuousOn.circleIntegrable hr.le
    exact (continuousOn_const.mul hpk).add continuousOn_const
  calc |circleAverage (fun z => poissonKernel c w z * (g z - g ζ)) c r|
      ≤ circleAverage (|fun z => poissonKernel c w z * (g z - g ζ)|) c r :=
        abs_circleAverage_le_circleAverage_abs
    _ ≤ circleAverage (fun z => ε / 2 * poissonKernel c w z + A * dist w ζ) c r := by
        apply circleAverage_mono hint1 hint2
        intro z hz
        rw [abs_of_pos hr] at hz
        simp only [Pi.abs_apply, abs_mul, abs_of_nonneg (pk_nonneg hw hz)]
        exact hpt z hz
    _ = ε / 2 * 1 + A * dist w ζ := by
        have e1 : circleAverage (fun z => ε / 2 * poissonKernel c w z) c r = ε / 2 := by
          rw [show (fun z => ε / 2 * poissonKernel c w z) = fun z => (ε / 2) • poissonKernel c w z
            from rfl, circleAverage_fun_smul, pk_avg hw, smul_eq_mul, mul_one]
        rw [circleAverage_fun_add, e1, circleAverage_const]
        · ring
        · exact (ContinuousOn.circleIntegrable hr.le hpk).const_smul
        · exact circleIntegrable_const _ _ _
    _ < ε := by
        have : A * dist w ζ ≤ (A + 1) * dist w ζ := by nlinarith [dist_nonneg (x := w) (y := ζ)]
        have h2 : (A + 1) * dist w ζ < (A + 1) * (ε / (2 * (A + 1))) :=
          mul_lt_mul_of_pos_left hwd2 (by linarith)
        have h3 : (A + 1) * (ε / (2 * (A + 1))) = ε / 2 := by field_simp
        linarith

lemma PI_tendsto_seq {c w : ℂ} {r : ℝ} (hr : 0 < r) (hw : w ∈ ball c r) {gs : ℕ → ℂ → ℝ}
    {h : ℂ → ℝ} {K : ℝ} (hgs : ∀ n, ContinuousOn (gs n) (sphere c r))
    (hK : ∀ n, ∀ z ∈ sphere c r, |gs n z| ≤ K)
    (hlim : ∀ z ∈ sphere c r, Tendsto (fun n => gs n z) atTop (𝓝 (h z))) :
    Tendsto (fun n => PI c r (gs n) w) atTop (𝓝 (PI c r h w)) := by
  unfold PI
  simp only [circleAverage_def]
  apply Tendsto.const_smul
  have hmem : ∀ θ, circleMap c r θ ∈ sphere c r := fun θ => circleMap_mem_sphere c hr.le θ
  apply intervalIntegral.tendsto_integral_filter_of_dominated_convergence
    (fun _ => (r + ‖w - c‖) / (r - ‖w - c‖) * K)
  · filter_upwards with n
    apply Continuous.aestronglyMeasurable
    show Continuous (fun θ => poissonKernel c w (circleMap c r θ) * gs n (circleMap c r θ))
    exact ((pk_cont hr hw).mul (hgs n)).comp_continuous (continuous_circleMap c r) hmem
  · filter_upwards with n
    filter_upwards with θ _
    simp only [smul_eq_mul, Pi.mul_apply, Real.norm_eq_abs, abs_mul,
      abs_of_nonneg (pk_nonneg hw (hmem θ))]
    have hK0 : 0 ≤ K := (abs_nonneg _).trans (hK n _ (hmem θ))
    exact mul_le_mul (pk_le hw (hmem θ)) (hK n _ (hmem θ)) (abs_nonneg _)
      ((pk_nonneg hw (hmem θ)).trans (pk_le hw (hmem θ)))
  · exact intervalIntegrable_const
  · filter_upwards with θ _
    simp only [smul_eq_mul, Pi.mul_apply]
    exact (hlim _ (hmem θ)).const_mul _


open Classical in
/-- Replace `v` inside the disc by the Poisson integral of its values on the circle. -/
noncomputable def lift (c : ℂ) (r : ℝ) (v : ℂ → ℝ) (z : ℂ) : ℝ :=
  if z ∈ ball c r then PI c r v z else v z

lemma lift_of_mem {c z : ℂ} {r : ℝ} {v : ℂ → ℝ} (hz : z ∈ ball c r) :
    lift c r v z = PI c r v z := by simp [lift, hz]

lemma lift_of_not_mem {c z : ℂ} {r : ℝ} {v : ℂ → ℝ} (hz : z ∉ ball c r) :
    lift c r v z = v z := by simp [lift, hz]

lemma lift_harmonic {c : ℂ} {r : ℝ} (hr : 0 < r) {v : ℂ → ℝ} (hv : CircleIntegrable v c r) :
    HarmonicOnNhd (lift c r v) (ball c r) := by
  intro z hz
  rw [harmonicAt_congr_nhds (f₂ := PI c r v)]
  · exact PI_harmonic hr hv z hz
  · filter_upwards [isOpen_ball.mem_nhds hz] with w hw
    exact lift_of_mem hw

lemma lift_continuousOn {c : ℂ} {r : ℝ} (hr : 0 < r) {v : ℂ → ℝ} {S : Set ℂ}
    (hv : ContinuousOn v S) (hS : sphere c r ⊆ S) : ContinuousOn (lift c r v) S := by
  have hvs : ContinuousOn v (sphere c r) := hv.mono hS
  have hint : CircleIntegrable v c r := ContinuousOn.circleIntegrable hr.le hvs
  intro z hz
  by_cases hzb : z ∈ ball c r
  · exact ((lift_harmonic hr hint z hzb).1.continuousAt).continuousWithinAt
  by_cases hzc : z ∈ closedBall c r
  · -- z on the circle
    have hzs : z ∈ sphere c r := by
      rw [mem_closedBall] at hzc
      rw [mem_ball] at hzb
      rw [mem_sphere]
      linarith
    have h1 : ContinuousWithinAt (lift c r v) (ball c r) z := by
      unfold ContinuousWithinAt
      rw [lift_of_not_mem hzb]
      apply (PI_tendsto hr hvs hzs).congr'
      filter_upwards [self_mem_nhdsWithin] with w hw
      exact (lift_of_mem hw).symm
    have h2 : ContinuousWithinAt (lift c r v) (S \ ball c r) z := by
      apply ((hv z hz).mono Set.sdiff_subset).congr
      · intro w hw
        exact lift_of_not_mem hw.2
      · exact lift_of_not_mem hzb
    apply (h1.union h2).mono
    intro w hw
    by_cases hwb : w ∈ ball c r
    · exact Or.inl hwb
    · exact Or.inr ⟨hw, hwb⟩
  · apply (hv z hz).congr_of_eventuallyEq
    · have : (closedBall c r)ᶜ ∈ 𝓝 z := isClosed_closedBall.isOpen_compl.mem_nhds hzc
      filter_upwards [nhdsWithin_le_nhds this] with w hw
      exact lift_of_not_mem (fun h => hw (ball_subset_closedBall h))
    · exact lift_of_not_mem hzb

lemma le_lift {c : ℂ} {r : ℝ} (hr : 0 < r) {v : ℂ → ℝ}
    (hv : ContinuousOn v (closedBall c r)) (hloc : LocSub v (ball c r)) :
    ∀ z, v z ≤ lift c r v z := by
  intro z
  by_cases hz : z ∈ ball c r
  · have hint : CircleIntegrable v c r :=
      ContinuousOn.circleIntegrable hr.le (hv.mono sphere_subset_closedBall)
    have hcl : closure (ball c r) = closedBall c r := closure_ball c hr.ne'
    refine compare (ball c r) isOpen_ball isBounded_ball v (lift c r v) (hcl ▸ hv)
      (hcl ▸ lift_continuousOn hr hv sphere_subset_closedBall) hloc
      (harmonic_locSuper isOpen_ball (lift_harmonic hr hint)) ?_ z hz
    intro p hp
    rw [frontier_ball c hr.ne'] at hp
    rw [lift_of_not_mem]
    rw [mem_sphere] at hp
    rw [mem_ball]
    linarith
  · rw [lift_of_not_mem hz]

lemma le_avg_of_locSub {y : ℂ} {ρ : ℝ} (hρ : 0 < ρ) {w : ℂ → ℝ}
    (hw : ContinuousOn w (closedBall y ρ)) (hloc : LocSub w (ball y ρ)) :
    w y ≤ circleAverage w y ρ := by
  have h := le_lift hρ hw hloc y
  rwa [lift_of_mem (mem_ball_self hρ), PI_center hρ] at h

lemma lift_mono {c : ℂ} {r : ℝ} (hr : 0 < r) {v v' : ℂ → ℝ}
    (hv : ContinuousOn v (sphere c r)) (hv' : ContinuousOn v' (sphere c r))
    (hle : ∀ z, v z ≤ v' z) : ∀ z, lift c r v z ≤ lift c r v' z := by
  intro z
  by_cases hz : z ∈ ball c r
  · rw [lift_of_mem hz, lift_of_mem hz]
    exact PI_mono hr hz (ContinuousOn.circleIntegrable hr.le hv)
      (ContinuousOn.circleIntegrable hr.le hv') (fun z _ => hle z)
  · rw [lift_of_not_mem hz, lift_of_not_mem hz]
    exact hle z

lemma lift_under {Ω : Set ℂ} (hΩ : IsOpen Ω) {g : ℂ → ℝ} {v : ℂ → ℝ}
    (hv : IsUnderShape Ω g v) {c : ℂ} {r : ℝ} (hr : 0 < r) (hB : closedBall c r ⊆ Ω) :
    IsUnderShape Ω g (lift c r v) := by
  have hsph : sphere c r ⊆ closure Ω := sphere_subset_closedBall.trans (hB.trans subset_closure)
  have hcont : ContinuousOn (lift c r v) (closure Ω) := lift_continuousOn hr hv.1 hsph
  have hvB : ContinuousOn v (closedBall c r) := hv.1.mono (hB.trans subset_closure)
  have hle : ∀ z, v z ≤ lift c r v z :=
    le_lift hr hvB (fun y hy => hv.2.1.locSub hΩ y (hB (ball_subset_closedBall hy)))
  have hint : CircleIntegrable v c r :=
    ContinuousOn.circleIntegrable hr.le (hvB.mono sphere_subset_closedBall)
  have hloc : LocSub (lift c r v) Ω := by
    intro y hy
    by_cases hyb : y ∈ ball c r
    · exact harmonic_locSub isOpen_ball (lift_harmonic hr hint) y hyb
    by_cases hyc : y ∈ closedBall c r
    · filter_upwards [eventually_closedBall_subset hΩ hy, self_mem_nhdsWithin] with s hs hpos
      have hsph' : sphere y s ⊆ closure Ω := sphere_subset_closedBall.trans (hs.trans subset_closure)
      rw [lift_of_not_mem hyb]
      calc v y ≤ circleAverage v y s := hv.2.1.2 y s hpos hs
        _ ≤ circleAverage (lift c r v) y s := by
          apply circleAverage_mono (ContinuousOn.circleIntegrable hpos.le (hv.1.mono hsph'))
            (ContinuousOn.circleIntegrable hpos.le (hcont.mono hsph'))
          intro z _
          exact hle z
    · have hU : IsOpen (Ω \ closedBall c r) := hΩ.sdiff isClosed_closedBall
      filter_upwards [eventually_closedBall_subset hU ⟨hy, hyc⟩, self_mem_nhdsWithin]
        with s hs hpos
      rw [lift_of_not_mem hyb]
      have heq : circleAverage (lift c r v) y s = circleAverage v y s := by
        apply circleAverage_congr_sphere
        intro z hz
        rw [abs_of_pos hpos] at hz
        apply lift_of_not_mem
        intro hzb
        exact (hs (sphere_subset_closedBall hz)).2 (ball_subset_closedBall hzb)
      rw [heq]
      exact hv.2.1.2 y s hpos (hs.trans Set.sdiff_subset)
  refine ⟨hcont, ⟨hcont.mono subset_closure, fun y ρ hρ hball => ?_⟩, fun p hp => ?_⟩
  · apply le_avg_of_locSub hρ (hcont.mono (hball.trans subset_closure))
    intro z hz
    exact hloc z (hball (ball_subset_closedBall hz))
  · have hpb : p ∉ ball c r := by
      intro h
      rw [hΩ.frontier_eq] at hp
      exact hp.2 (hB (ball_subset_closedBall h))
    rw [lift_of_not_mem hpb]
    exact hv.2.2 p hp

lemma max_under {Ω : Set ℂ} {g : ℂ → ℝ} {v w : ℂ → ℝ} (hv : IsUnderShape Ω g v)
    (hw : IsUnderShape Ω g w) : IsUnderShape Ω g (fun z => max (v z) (w z)) := by
  refine ⟨ContinuousOn.sup hv.1 hw.1, ⟨ContinuousOn.sup hv.2.1.1 hw.2.1.1, fun x r hr hball => ?_⟩,
    fun p hp => max_le (hv.2.2 p hp) (hw.2.2 p hp)⟩
  have hsph : sphere x r ⊆ Ω := sphere_subset_closedBall.trans hball
  have hm : CircleIntegrable (fun z => max (v z) (w z)) x r :=
    ContinuousOn.circleIntegrable hr.le ((ContinuousOn.sup hv.2.1.1 hw.2.1.1).mono hsph)
  apply max_le
  · calc v x ≤ circleAverage v x r := hv.2.1.2 x r hr hball
      _ ≤ _ := circleAverage_mono (ContinuousOn.circleIntegrable hr.le (ContinuousOn.mono hv.2.1.1 hsph)) hm
          (fun z _ => le_max_left _ _)
  · calc w x ≤ circleAverage w x r := hw.2.1.2 x r hr hball
      _ ≤ _ := circleAverage_mono (ContinuousOn.circleIntegrable hr.le (ContinuousOn.mono hw.2.1.1 hsph)) hm
          (fun z _ => le_max_right _ _)


/-- Running maximum of a base function and a sequence of functions. -/
noncomputable def accum (base : ℂ → ℝ) (f : ℕ → ℂ → ℝ) : ℕ → ℂ → ℝ
  | 0 => fun z => max (base z) (f 0 z)
  | n + 1 => fun z => max (accum base f n z) (f (n + 1) z)

lemma accum_under {Ω : Set ℂ} {g : ℂ → ℝ} {base : ℂ → ℝ} {f : ℕ → ℂ → ℝ}
    (hb : IsUnderShape Ω g base) (hf : ∀ n, IsUnderShape Ω g (f n)) :
    ∀ n, IsUnderShape Ω g (accum base f n) := by
  intro n
  induction n with
  | zero => exact max_under hb (hf 0)
  | succ n ih => exact max_under ih (hf (n + 1))

lemma accum_le_succ (base : ℂ → ℝ) (f : ℕ → ℂ → ℝ) (n : ℕ) (z : ℂ) :
    accum base f n z ≤ accum base f (n + 1) z := le_max_left _ _

lemma base_le_accum (base : ℂ → ℝ) (f : ℕ → ℂ → ℝ) (n : ℕ) (z : ℂ) :
    base z ≤ accum base f n z := by
  induction n with
  | zero => exact le_max_left _ _
  | succ n ih => exact ih.trans (accum_le_succ base f n z)

lemma f_le_accum (base : ℂ → ℝ) (f : ℕ → ℂ → ℝ) (n : ℕ) (z : ℂ) :
    f n z ≤ accum base f n z := by
  cases n with
  | zero => exact le_max_right _ _
  | succ n => exact le_max_right _ _

lemma accum_mono_f (base : ℂ → ℝ) {f f' : ℕ → ℂ → ℝ} (h : ∀ n z, f n z ≤ f' n z) (n : ℕ)
    (z : ℂ) : accum base f n z ≤ accum base f' n z := by
  induction n with
  | zero => exact max_le_max le_rfl (h 0 z)
  | succ n ih => exact max_le_max ih (h (n + 1) z)

lemma circleIntegrable_of_lim {c : ℂ} {r : ℝ} (hr : 0 < r) {gs : ℕ → ℂ → ℝ} {h : ℂ → ℝ}
    {K : ℝ} (hgs : ∀ n, ContinuousOn (gs n) (sphere c r))
    (hK : ∀ n, ∀ z ∈ sphere c r, |gs n z| ≤ K)
    (hlim : ∀ z ∈ sphere c r, Tendsto (fun n => gs n z) atTop (𝓝 (h z))) :
    CircleIntegrable h c r := by
  have hmem : ∀ θ, circleMap c r θ ∈ sphere c r := fun θ => circleMap_mem_sphere c hr.le θ
  unfold CircleIntegrable
  apply (intervalIntegrable_const (c := K)).mono_fun'
  · apply aestronglyMeasurable_of_tendsto_ae atTop (f := fun n θ => gs n (circleMap c r θ))
    · intro n
      exact ((hgs n).comp_continuous (continuous_circleMap c r) hmem).aestronglyMeasurable
    · exact MeasureTheory.ae_of_all _ fun θ => hlim _ (hmem θ)
  · refine MeasureTheory.ae_of_all _ fun θ => ?_
    simp only [Real.norm_eq_abs]
    exact le_of_tendsto' (hlim _ (hmem θ)).abs (fun n => hK n _ (hmem θ))

lemma perron_harmonicAt (Ω : Set ℂ) (hΩ : IsOpen Ω) (hbdd : Bornology.IsBounded Ω)
    (g : ℂ → ℝ) (M : ℝ) (hM : ∀ p ∈ frontier Ω, |g p| ≤ M) (x0 : ℂ) (hx0 : x0 ∈ Ω) :
    HarmonicAt (perron Ω g) x0 := by
  obtain ⟨ε, hε, hεb⟩ := Metric.isOpen_iff.1 hΩ x0 hx0
  set r := ε / 2 with hrdef
  have hr : 0 < r := by positivity
  have hB : closedBall x0 r ⊆ Ω := (closedBall_subset_ball (by linarith : r < ε)).trans hεb
  have hBall : ball x0 r ⊆ Ω := ball_subset_closedBall.trans hB
  have hsphΩ : sphere x0 r ⊆ Ω := sphere_subset_closedBall.trans hB
  have hx0b : x0 ∈ ball x0 r := mem_ball_self hr
  have hchoice : ∀ (y : ℂ) (n : ℕ), ∃ v, IsUnderShape Ω g v ∧
      (y ∈ Ω → perron Ω g y - 1 / ((n : ℝ) + 1) < v y) := by
    intro y n
    by_cases hy : y ∈ Ω
    · have hpos : (0 : ℝ) < 1 / ((n : ℝ) + 1) := by positivity
      obtain ⟨_, ⟨v, hv, rfl⟩, hlt⟩ := exists_lt_of_lt_csSup (perron_nonempty hM y)
        (show perron Ω g y - 1 / ((n : ℝ) + 1) < perron Ω g y by linarith)
      exact ⟨v, hv, fun _ => hlt⟩
    · exact ⟨_, const_under hM, fun h => absurd h hy⟩
  choose u hu hulow using hchoice
  set base : ℂ → ℝ := fun _ => -M with hbase
  set fs : ℂ → ℕ → ℂ → ℝ := fun y n z => max (u x0 n z) (u y n z) with hfs
  set s : ℂ → ℕ → ℂ → ℝ := fun y n => lift x0 r (accum base (fs y) n) with hsdef
  have hfs_under : ∀ y n, IsUnderShape Ω g (fs y n) := fun y n => max_under (hu x0 n) (hu y n)
  have hacc_under : ∀ y n, IsUnderShape Ω g (accum base (fs y) n) :=
    fun y => accum_under (const_under hM) (hfs_under y)
  have hs_under : ∀ y n, IsUnderShape Ω g (s y n) :=
    fun y n => lift_under hΩ (hacc_under y n) hr hB
  have hacc_cont : ∀ y n, ContinuousOn (accum base (fs y) n) (sphere x0 r) :=
    fun y n => (hacc_under y n).1.mono (hsphΩ.trans subset_closure)
  have hacc_le_s : ∀ y n z, accum base (fs y) n z ≤ s y n z := fun y n =>
    le_lift hr ((hacc_under y n).1.mono (hB.trans subset_closure))
      (fun z hz => (hacc_under y n).2.1.locSub hΩ z (hBall hz))
  have hs_mono : ∀ y z, Monotone (fun n => s y n z) := by
    intro y z
    apply monotone_nat_of_le_succ
    intro n
    exact lift_mono hr (hacc_cont y n) (hacc_cont y (n + 1))
      (fun z => accum_le_succ base (fs y) n z) z
  have hs_le_M : ∀ y n z, z ∈ Ω → s y n z ≤ M :=
    fun y n => under_le_bound hΩ hbdd hM (hs_under y n)
  have hs_ge : ∀ y n z, -M ≤ s y n z :=
    fun y n z => (base_le_accum base (fs y) n z).trans (hacc_le_s y n z)
  have hs_le_perron : ∀ y n z, z ∈ Ω → s y n z ≤ perron Ω g z :=
    fun y n z hz => le_perron hΩ hbdd hM hz (hs_under y n)
  have hs_x0_le : ∀ y n z, s x0 n z ≤ s y n z := by
    intro y n z
    exact lift_mono hr (hacc_cont x0 n) (hacc_cont y n)
      (accum_mono_f base (f := fs x0) (f' := fs y)
        (fun k w => max_le (le_max_left _ _) (le_max_left _ _)) n) z
  have hs_cont : ∀ y n, ContinuousOn (s y n) (sphere x0 r) :=
    fun y n => (hs_under y n).1.mono (hsphΩ.trans subset_closure)
  set h : ℂ → ℂ → ℝ := fun y ζ => ⨆ n, s y n ζ with hhdef
  have hbdd_s : ∀ y ζ, ζ ∈ Ω → BddAbove (Set.range fun n => s y n ζ) := by
    intro y ζ hζ
    refine ⟨M, ?_⟩
    rintro _ ⟨n, rfl⟩
    exact hs_le_M y n ζ hζ
  have hlim : ∀ y ζ, ζ ∈ Ω → Tendsto (fun n => s y n ζ) atTop (𝓝 (h y ζ)) :=
    fun y ζ hζ => tendsto_atTop_ciSup (hs_mono y ζ) (hbdd_s y ζ hζ)
  have habs : ∀ y n ζ, ζ ∈ Ω → |s y n ζ| ≤ M :=
    fun y n ζ hζ => abs_le.2 ⟨hs_ge y n ζ, hs_le_M y n ζ hζ⟩
  have hint_h : ∀ y, CircleIntegrable (h y) x0 r := fun y =>
    circleIntegrable_of_lim hr (hs_cont y) (fun n ζ hζ => habs y n ζ (hsphΩ hζ))
      (fun ζ hζ => hlim y ζ (hsphΩ hζ))
  have hV : ∀ y z, z ∈ ball x0 r →
      Tendsto (fun n => s y n z) atTop (𝓝 (PI x0 r (h y) z)) := by
    intro y z hz
    have := PI_tendsto_seq hr hz (hs_cont y) (fun n ζ hζ => habs y n ζ (hsphΩ hζ))
      (fun ζ hζ => hlim y ζ (hsphΩ hζ))
    refine this.congr (fun n => ?_)
    show PI x0 r (s y n) z = s y n z
    rw [hsdef]
    simp only
    rw [lift_of_mem hz]
    unfold PI
    apply circleAverage_congr_sphere
    intro ζ hζ
    rw [abs_of_pos hr] at hζ
    have hζb : ζ ∉ ball x0 r := by
      rw [mem_sphere] at hζ
      rw [mem_ball]
      linarith
    show poissonKernel x0 z ζ • lift x0 r (accum base (fs y) n) ζ =
      poissonKernel x0 z ζ • accum base (fs y) n ζ
    rw [lift_of_not_mem hζb]
  have hV_le : ∀ y z, z ∈ ball x0 r → PI x0 r (h y) z ≤ perron Ω g z := fun y z hz =>
    le_of_tendsto' (hV y z hz) (fun n => hs_le_perron y n z (hBall hz))
  have hlow : Tendsto (fun n : ℕ => perron Ω g x0 - 1 / ((n : ℝ) + 1)) atTop
      (𝓝 (perron Ω g x0)) := by
    have h := (tendsto_const_nhds (x := perron Ω g x0)).sub
      (tendsto_one_div_add_atTop_nhds_zero_nat (𝕜 := ℝ))
    rw [sub_zero] at h
    exact h
  have hV_x0 : ∀ y, PI x0 r (h y) x0 = perron Ω g x0 := by
    intro y
    apply le_antisymm (hV_le y x0 hx0b)
    apply le_of_tendsto_of_tendsto hlow (hV y x0 hx0b)
    filter_upwards with n
    exact (hulow x0 n hx0).le.trans ((le_max_left _ _).trans
      ((f_le_accum base (fs y) n x0).trans (hacc_le_s y n x0)))
  have hV_ge : ∀ y, y ∈ ball x0 r → perron Ω g y ≤ PI x0 r (h y) y := by
    intro y hy
    have hlow' : Tendsto (fun n : ℕ => perron Ω g y - 1 / ((n : ℝ) + 1)) atTop
        (𝓝 (perron Ω g y)) := by
      have h := (tendsto_const_nhds (x := perron Ω g y)).sub
        (tendsto_one_div_add_atTop_nhds_zero_nat (𝕜 := ℝ))
      rw [sub_zero] at h
      exact h
    apply le_of_tendsto_of_tendsto hlow' (hV y y hy)
    filter_upwards with n
    exact (hulow y n (hBall hy)).le.trans ((le_max_right _ _).trans
      ((f_le_accum base (fs y) n y).trans (hacc_le_s y n y)))
  have hh_le : ∀ y ζ, ζ ∈ sphere x0 r → h x0 ζ ≤ h y ζ := fun y ζ hζ =>
    ciSup_mono (hbdd_s y ζ (hsphΩ hζ)) (fun n => hs_x0_le y n ζ)
  have hVeq : ∀ y z, z ∈ ball x0 r → PI x0 r (h y) z = PI x0 r (h x0) z := by
    intro y z hz
    apply le_antisymm _ (PI_mono hr hz (hint_h x0) (hint_h y) (hh_le y))
    have hd := PI_sub hr hz (hint_h x0) (hint_h y)
    have hdint : CircleIntegrable (fun ζ => h y ζ - h x0 ζ) x0 r := (hint_h y).sub (hint_h x0)
    have hup := PI_le_avg hr hz hdint (fun ζ hζ => sub_nonneg.2 (hh_le y ζ hζ))
    have havg : circleAverage (fun ζ => h y ζ - h x0 ζ) x0 r = 0 := by
      rw [circleAverage_fun_sub (hint_h y) (hint_h x0), ← PI_center hr, ← PI_center hr,
        hV_x0, hV_x0, sub_self]
    rw [havg, mul_zero, hd] at hup
    linarith
  have heq : perron Ω g =ᶠ[𝓝 x0] PI x0 r (h x0) := by
    filter_upwards [isOpen_ball.mem_nhds hx0b] with y hy
    exact le_antisymm ((hV_ge y hy).trans (hVeq y y hy).le) (hV_le x0 y hy)
  exact (harmonicAt_congr_nhds heq).2 (PI_harmonic hr (hint_h x0) x0 hx0b)

lemma affine_shapes {Ω : Set ℂ} {b : ℂ → ℝ} (hbs : IsSuperharmonicOn b Ω) (a k : ℝ)
    (hk : 0 ≤ k) :
    IsSubharmonicOn (fun x => a - k * b x) Ω ∧ IsSuperharmonicOn (fun x => a + k * b x) Ω := by
  have havg : ∀ x r, 0 < r → closedBall x r ⊆ Ω →
      circleAverage (fun z => k * b z) x r = k * circleAverage b x r := by
    intro x r _ _
    rw [show (fun z => k * b z) = fun z => k • b z from rfl, circleAverage_fun_smul, smul_eq_mul]
  have hint : ∀ x r, 0 < r → closedBall x r ⊆ Ω → CircleIntegrable (fun z => k * b z) x r :=
    fun x r hr hball => ContinuousOn.circleIntegrable hr.le
      (continuousOn_const.mul (hbs.1.mono (sphere_subset_closedBall.trans hball)))
  refine ⟨⟨continuousOn_const.sub (continuousOn_const.mul hbs.1), fun x r hr hball => ?_⟩,
    ⟨continuousOn_const.add (continuousOn_const.mul hbs.1), fun x r hr hball => ?_⟩⟩
  · rw [circleAverage_fun_sub (circleIntegrable_const _ _ _) (hint x r hr hball),
      circleAverage_const, havg x r hr hball]
    have := mul_le_mul_of_nonneg_left (hbs.2 x r hr hball) hk
    linarith
  · rw [circleAverage_fun_add (circleIntegrable_const _ _ _) (hint x r hr hball),
      circleAverage_const, havg x r hr hball]
    have := mul_le_mul_of_nonneg_left (hbs.2 x r hr hball) hk
    linarith

lemma barrier_tendsto (Ω : Set ℂ) (hΩ : IsOpen Ω) (hbdd : Bornology.IsBounded Ω)
    (g : ℂ → ℝ) (M : ℝ) (hM : ∀ p ∈ frontier Ω, |g p| ≤ M) (p : ℂ) (hp : p ∈ frontier Ω)
    (hgp : ContinuousWithinAt g (frontier Ω) p) (hbar : HasBarrier Ω p) :
    Tendsto (perron Ω g) (𝓝[Ω] p) (𝓝 (g p)) := by
  obtain ⟨b, hbc, hbs, hbp, hbpos⟩ := hbar
  rw [Metric.tendsto_nhdsWithin_nhds]
  intro ε hε
  obtain ⟨η, hη, hgη⟩ := Metric.continuousWithinAt_iff.1 hgp (ε / 2) (by linarith)
  have hpcl : p ∈ closure Ω := frontier_subset_closure hp
  have hb0 : ∀ x ∈ closure Ω, 0 ≤ b x := by
    intro x hx
    by_cases hxp : x = p
    · rw [hxp, hbp]
    · exact (hbpos x hx hxp).le
  obtain ⟨m, hm, hmb⟩ : ∃ m > 0, ∀ x ∈ closure Ω, η ≤ dist x p → m ≤ b x := by
    have hKc : IsCompact (closure Ω ∩ {x | η ≤ dist x p}) :=
      hbdd.isCompact_closure.inter_right
        (isClosed_le continuous_const (continuous_id.dist continuous_const))
    rcases (closure Ω ∩ {x | η ≤ dist x p}).eq_empty_or_nonempty with hK | hK
    · refine ⟨1, one_pos, fun x hx hxd => ?_⟩
      exfalso
      have : x ∈ closure Ω ∩ {x | η ≤ dist x p} := ⟨hx, hxd⟩
      rw [hK] at this
      exact this
    · obtain ⟨x1, hx1, hmin⟩ := hKc.exists_isMinOn hK (hbc.mono Set.inter_subset_left)
      refine ⟨b x1, hbpos x1 hx1.1 ?_, fun x hx hxd => hmin ⟨hx, hxd⟩⟩
      intro h
      have := hx1.2
      simp only [Set.mem_ofPred_eq, h, dist_self] at this
      linarith
  have hM0 : 0 ≤ M := (abs_nonneg _).trans (hM p hp)
  set k := 2 * M / m with hkdef
  have hk : 0 ≤ k := by positivity
  have hkm : k * m = 2 * M := by rw [hkdef]; field_simp
  have hgpM := abs_le.1 (hM p hp)
  obtain ⟨hsub, hsup⟩ := affine_shapes hbs (g p - ε / 2) k hk
  obtain ⟨-, hsup'⟩ := affine_shapes hbs (g p + ε / 2) k hk
  have hv : IsUnderShape Ω g (fun x => (g p - ε / 2) - k * b x) := by
    refine ⟨continuousOn_const.sub (continuousOn_const.mul hbc), hsub, fun q hq => ?_⟩
    have hqcl : q ∈ closure Ω := frontier_subset_closure hq
    have hgqM := abs_le.1 (hM q hq)
    by_cases hqd : dist q p < η
    · have := hgη hq hqd
      rw [Real.dist_eq, abs_lt] at this
      have := mul_nonneg hk (hb0 q hqcl)
      linarith
    · push Not at hqd
      have := mul_le_mul_of_nonneg_left (hmb q hqcl hqd) hk
      linarith
  have hw : IsOverShape Ω g (fun x => (g p + ε / 2) + k * b x) := by
    refine ⟨continuousOn_const.add (continuousOn_const.mul hbc), hsup', fun q hq => ?_⟩
    have hqcl : q ∈ closure Ω := frontier_subset_closure hq
    have hgqM := abs_le.1 (hM q hq)
    by_cases hqd : dist q p < η
    · have := hgη hq hqd
      rw [Real.dist_eq, abs_lt] at this
      have := mul_nonneg hk (hb0 q hqcl)
      linarith
    · push Not at hqd
      have := mul_le_mul_of_nonneg_left (hmb q hqcl hqd) hk
      linarith
  obtain ⟨δ, hδ, hbδ⟩ := Metric.continuousWithinAt_iff.1 (hbc p hpcl) (ε / (2 * (k + 1)))
    (by positivity)
  refine ⟨δ, hδ, fun x hx hxd => ?_⟩
  have htr := trapped_aux Ω hΩ hbdd g ⟨M, hM⟩ _ _ hv hw x hx
  have hbx : b x < ε / (2 * (k + 1)) := by
    have := hbδ (subset_closure hx) hxd
    rw [hbp, Real.dist_eq, sub_zero] at this
    exact (le_abs_self _).trans_lt this
  have hbx0 := hb0 x (subset_closure hx)
  have hkb : k * b x < ε / 2 := by
    have h1 : k * b x ≤ (k + 1) * b x := by nlinarith
    have h2 : (k + 1) * b x < (k + 1) * (ε / (2 * (k + 1))) :=
      mul_lt_mul_of_pos_left hbx (by linarith)
    have h3 : (k + 1) * (ε / (2 * (k + 1))) = ε / 2 := by field_simp
    linarith
  rw [Real.dist_eq, abs_lt]
  constructor <;> linarith [htr.1, htr.2, mul_nonneg hk hbx0]

#print axioms avg_lt_of_le_of_lt
#print axioms max_principle
#print axioms eventually_closedBall_subset
#print axioms locSub_exists
#print axioms IsSubharmonicOn.locSub
#print axioms IsSuperharmonicOn.locSuper
#print axioms harmonic_avg_eq
#print axioms harmonic_locSuper
#print axioms harmonic_locSub
#print axioms locSub_sub
#print axioms compare
#print axioms const_locSuper
#print axioms const_subharmonic
#print axioms under_le_bound
#print axioms const_under
#print axioms perron_bddAbove
#print axioms perron_nonempty
#print axioms le_perron
#print axioms perron_le_of
#print axioms trapped_aux
#print axioms stays_under_aux
#print axioms pk_nonneg
#print axioms pk_le
#print axioms pk_cont
#print axioms pk_avg
#print axioms PI_center
#print axioms PI_integrable
#print axioms PI_mono
#print axioms PI_sub
#print axioms PI_le_avg
#print axioms PI_harmonic
#print axioms PI_tendsto
#print axioms PI_tendsto_seq
#print axioms lift_of_mem
#print axioms lift_of_not_mem
#print axioms lift_harmonic
#print axioms lift_continuousOn
#print axioms le_lift
#print axioms le_avg_of_locSub
#print axioms lift_mono
#print axioms lift_under
#print axioms max_under
#print axioms accum_under
#print axioms accum_le_succ
#print axioms base_le_accum
#print axioms f_le_accum
#print axioms accum_mono_f
#print axioms circleIntegrable_of_lim
#print axioms perron_harmonicAt
#print axioms affine_shapes
#print axioms barrier_tendsto

/-- Perron's theorem (the card's main claim). On a bounded region of the plane, with bounded wall
voltages `g` and a barrier at every wall point, the top of all under shapes is harmonic inside,
and at every wall point where `g` is continuous along the wall it tends to the wall voltage. -/
theorem perron_top_of_under_shapes_solves_dirichlet (Ω : Set ℂ) (hΩ : IsOpen Ω)
    (hbdd : Bornology.IsBounded Ω) (g : ℂ → ℝ) (hg : ∃ M : ℝ, ∀ p ∈ frontier Ω, |g p| ≤ M)
    (hbar : ∀ p ∈ frontier Ω, HasBarrier Ω p) :
    HarmonicOnNhd (perron Ω g) Ω ∧
      ∀ p ∈ frontier Ω, ContinuousWithinAt g (frontier Ω) p →
        Tendsto (perron Ω g) (𝓝[Ω] p) (𝓝 (g p)) := by
  obtain ⟨M, hM⟩ := hg
  exact ⟨fun x hx => perron_harmonicAt Ω hΩ hbdd g M hM x hx,
    fun p hp hgp => barrier_tendsto Ω hΩ hbdd g M hM p hp hgp (hbar p hp)⟩

/-- Step 1: an under shape stays under. If `v` is subharmonic in a bounded region, `u` is harmonic
there, both are continuous on the closed region, and `v ≤ u` on the wall, then `v ≤ u` inside. -/
theorem under_shape_stays_under_harmonic (Ω : Set ℂ) (hΩ : IsOpen Ω)
    (hbdd : Bornology.IsBounded Ω) (v u : ℂ → ℝ) (hv : ContinuousOn v (closure Ω))
    (hvs : IsSubharmonicOn v Ω) (hu : ContinuousOn u (closure Ω)) (huh : HarmonicOnNhd u Ω)
    (hle : ∀ p ∈ frontier Ω, v p ≤ u p) :
    ∀ x ∈ Ω, v x ≤ u x := by
  exact stays_under_aux Ω hΩ hbdd v u hv hvs hu huh hle

/-- The trap: on a bounded region with bounded wall voltages, Perron's function lies above every
under shape and below every over shape. -/
theorem perron_trapped_between_under_and_over (Ω : Set ℂ) (hΩ : IsOpen Ω)
    (hbdd : Bornology.IsBounded Ω) (g : ℂ → ℝ) (hg : ∃ M : ℝ, ∀ p ∈ frontier Ω, |g p| ≤ M)
    (v w : ℂ → ℝ) (hv : IsUnderShape Ω g v) (hw : IsOverShape Ω g w) :
    ∀ x ∈ Ω, v x ≤ perron Ω g x ∧ perron Ω g x ≤ w x := by
  exact trapped_aux Ω hΩ hbdd g hg v w hv hw

/-- The flat-floored box: the lid's 100 V turned to each of the four walls adds to 100 V
everywhere, so the centre takes a quarter of it, 25 V. -/
example : (4 : ℕ) * 25 = 100 := by norm_num
example : (100 : ℚ) / 4 = 25 := by norm_num

#print axioms perron_top_of_under_shapes_solves_dirichlet
#print axioms under_shape_stays_under_harmonic
#print axioms perron_trapped_between_under_and_over

end Perron
