-- Limit superior and inferior: for a bounded real sequence the tail sups and tail infs settle at the limsup and liminf, these are the largest and smallest subsequential limits, the sequence has limit L exactly when both equal L, and a real power series has radius one over the limsup of the n-th roots of its coefficients.
import Mathlib.Order.LiminfLimsup
import Mathlib.Topology.Order.LiminfLimsup
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Analysis.Analytic.RadiusLiminf
import Mathlib.Analysis.Analytic.OfScalars
import Mathlib.Analysis.SpecialFunctions.Pow.NNReal
import Mathlib.Tactic.NormNum

open Filter Finset
open scoped Topology ENNReal

/-- **Ceiling, floor and subsequential limits.** Let `a` be a bounded real sequence.
The tail sup `s N = sup {a n : n ≥ N}` heads for the limsup and the tail inf
`i N = inf {a n : n ≥ N}` heads for the liminf. The limsup is the largest subsequential
limit: some subsequence heads exactly to it, and no subsequence heads higher. The liminf
is the smallest subsequential limit: some subsequence heads exactly to it, and no
subsequence heads lower. -/
theorem limsup_liminf_largest_smallest_subsequential_limits (a : ℕ → ℝ)
    (hab : BddAbove (Set.range a)) (hbb : BddBelow (Set.range a)) :
    Tendsto (fun N => sSup (a '' Set.Ici N)) atTop (𝓝 (limsup a atTop)) ∧
    Tendsto (fun N => sInf (a '' Set.Ici N)) atTop (𝓝 (liminf a atTop)) ∧
    (∃ φ : ℕ → ℕ, StrictMono φ ∧ Tendsto (a ∘ φ) atTop (𝓝 (limsup a atTop))) ∧
    (∀ (φ : ℕ → ℕ) (x : ℝ), StrictMono φ → Tendsto (a ∘ φ) atTop (𝓝 x) →
      x ≤ limsup a atTop) ∧
    (∃ φ : ℕ → ℕ, StrictMono φ ∧ Tendsto (a ∘ φ) atTop (𝓝 (liminf a atTop))) ∧
    (∀ (φ : ℕ → ℕ) (x : ℝ), StrictMono φ → Tendsto (a ∘ φ) atTop (𝓝 x) →
      liminf a atTop ≤ x) := by
  have hU : atTop.IsBoundedUnder (· ≤ ·) a := hab.isBoundedUnder_of_range
  have hL : atTop.IsBoundedUnder (· ≥ ·) a := hbb.isBoundedUnder_of_range
  have hUc : atTop.IsCoboundedUnder (· ≤ ·) a := hL.isCoboundedUnder_le
  have hLc : atTop.IsCoboundedUnder (· ≥ ·) a := hU.isCoboundedUnder_ge
  have hclus : ∀ y : ℝ, (∀ ε > 0, ∃ᶠ n in atTop, y - ε < a n ∧ a n < y + ε) →
      ∃ φ : ℕ → ℕ, StrictMono φ ∧ Tendsto (a ∘ φ) atTop (𝓝 y) := by
    intro y hy
    apply MapClusterPt.tendsto_subseq
    rw [mapClusterPt_iff_frequently]
    intro s hs
    obtain ⟨ε, hε, hball⟩ := Metric.mem_nhds_iff.1 hs
    refine (hy ε hε).mono fun n hn => hball ?_
    rw [Metric.mem_ball, Real.dist_eq, abs_sub_lt_iff]
    constructor <;> linarith [hn.1, hn.2]
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩
  · rw [tendsto_order]
    constructor
    · intro y hy
      have hf := frequently_lt_of_lt_limsup hUc hy
      rw [frequently_atTop] at hf
      refine Eventually.of_forall fun N => ?_
      obtain ⟨n, hn, hyn⟩ := hf N
      exact hyn.trans_le (le_csSup (hab.mono (Set.image_subset_range _ _)) ⟨n, hn, rfl⟩)
    · intro y hy
      obtain ⟨b, hb1, hb2⟩ := exists_between hy
      have h := eventually_lt_of_limsup_lt hb1 hU
      rw [eventually_atTop] at h
      obtain ⟨N0, hN0⟩ := h
      filter_upwards [eventually_ge_atTop N0] with N hN
      refine lt_of_le_of_lt (csSup_le ⟨a N, N, le_refl N, rfl⟩ ?_) hb2
      rintro _ ⟨n, hn, rfl⟩
      exact (hN0 n (hN.trans hn)).le
  · rw [tendsto_order]
    constructor
    · intro y hy
      obtain ⟨b, hb1, hb2⟩ := exists_between hy
      have h := eventually_lt_of_lt_liminf hb2 hL
      rw [eventually_atTop] at h
      obtain ⟨N0, hN0⟩ := h
      filter_upwards [eventually_ge_atTop N0] with N hN
      refine lt_of_lt_of_le hb1 (le_csInf ⟨a N, N, le_refl N, rfl⟩ ?_)
      rintro _ ⟨n, hn, rfl⟩
      exact (hN0 n (hN.trans hn)).le
    · intro y hy
      have hf := frequently_lt_of_liminf_lt hLc hy
      rw [frequently_atTop] at hf
      refine Eventually.of_forall fun N => ?_
      obtain ⟨n, hn, hyn⟩ := hf N
      exact (csInf_le (hbb.mono (Set.image_subset_range _ _)) ⟨n, hn, rfl⟩).trans_lt hyn
  · apply hclus
    intro ε hε
    exact (frequently_lt_of_lt_limsup hUc (sub_lt_self _ hε)).and_eventually
      (eventually_lt_of_limsup_lt (lt_add_of_pos_right _ hε) hU)
  · intro φ x hφ hx
    by_contra h
    rw [not_le] at h
    obtain ⟨b, hb1, hb2⟩ := exists_between h
    have h2 := hφ.tendsto_atTop.eventually (eventually_lt_of_limsup_lt hb1 hU)
    have h3 := hx.eventually (lt_mem_nhds hb2)
    obtain ⟨n, hn1, hn2⟩ := (h2.and h3).exists
    exact lt_asymm hn1 hn2
  · apply hclus
    intro ε hε
    exact ((frequently_lt_of_liminf_lt hLc (lt_add_of_pos_right _ hε)).and_eventually
      (eventually_lt_of_lt_liminf (sub_lt_self _ hε) hL)).mono fun n hn => ⟨hn.2, hn.1⟩
  · intro φ x hφ hx
    by_contra h
    rw [not_le] at h
    obtain ⟨b, hb1, hb2⟩ := exists_between h
    have h2 := hφ.tendsto_atTop.eventually (eventually_lt_of_lt_liminf hb2 hL)
    have h3 := hx.eventually (gt_mem_nhds hb1)
    obtain ⟨n, hn1, hn2⟩ := (h2.and h3).exists
    exact lt_asymm hn1 hn2

/-- **A limit exists exactly when ceiling and floor meet.** A bounded real sequence
heads for `L` exactly when its limsup and its liminf are both `L`. -/
theorem tendsto_iff_limsup_eq_liminf (a : ℕ → ℝ) (L : ℝ)
    (hab : BddAbove (Set.range a)) (hbb : BddBelow (Set.range a)) :
    Tendsto a atTop (𝓝 L) ↔ limsup a atTop = L ∧ liminf a atTop = L := by
  have hU : atTop.IsBoundedUnder (· ≤ ·) a := hab.isBoundedUnder_of_range
  have hL : atTop.IsBoundedUnder (· ≥ ·) a := hbb.isBoundedUnder_of_range
  constructor
  · intro h
    exact ⟨h.limsup_eq, h.liminf_eq⟩
  · rintro ⟨h1, h2⟩
    exact tendsto_of_liminf_eq_limsup h2 h1 hU hL

/-- **Cauchy–Hadamard on the real line.** For the real power series `∑ c n * x ^ n`,
let `R` be one over the limsup of the n-th roots `|c n|^(1/n)`, reading `1/0` as no edge
and `1/∞` as radius 0. Then `R` is the series' radius of convergence: the running totals
have a limit for every `|x| < R`, and have no limit for any `|x| > R`. The edge
`|x| = R` is left open. -/
theorem cauchy_hadamard_radius (c : ℕ → ℝ) (R : ℝ≥0∞)
    (hR : R = (limsup (fun n : ℕ => (‖c n‖₊ : ℝ≥0∞) ^ ((n : ℝ)⁻¹)) atTop)⁻¹) :
    (FormalMultilinearSeries.ofScalars ℝ c).radius = R ∧
    (∀ x : ℝ, (‖x‖₊ : ℝ≥0∞) < R →
      ∃ S : ℝ, Tendsto (fun N => ∑ n ∈ range N, c n * x ^ n) atTop (𝓝 S)) ∧
    (∀ x : ℝ, R < (‖x‖₊ : ℝ≥0∞) →
      ¬ ∃ S : ℝ, Tendsto (fun N => ∑ n ∈ range N, c n * x ^ n) atTop (𝓝 S)) := by
  set p := FormalMultilinearSeries.ofScalars ℝ c with hp
  have hnorm : ∀ n, ‖p n‖ = ‖c n‖ := fun n => FormalMultilinearSeries.ofScalars_norm ℝ c n
  have hnnorm : ∀ n, ‖p n‖₊ = ‖c n‖₊ := fun n => by
    ext
    simp only [coe_nnnorm]
    exact hnorm n
  have hrad : p.radius = R := by
    have h := p.radius_inv_eq_limsup
    have hfun : (fun n : ℕ => ((‖p n‖₊ ^ (1 / (n : ℝ)) : NNReal) : ℝ≥0∞)) =
        fun n : ℕ => (‖c n‖₊ : ℝ≥0∞) ^ ((n : ℝ)⁻¹) := by
      funext n
      rw [hnnorm, ENNReal.coe_rpow_of_nonneg _ (by positivity : (0 : ℝ) ≤ 1 / (n : ℝ)), one_div]
    rw [hfun] at h
    rw [hR, ← h, inv_inv]
  refine ⟨hrad, ?_, ?_⟩
  · intro x hx
    rw [← hrad] at hx
    have hs := p.summable_norm_mul_pow hx
    have hs' : Summable (fun n => c n * x ^ n) := by
      refine Summable.of_norm ?_
      refine hs.congr fun n => ?_
      rw [norm_mul, norm_pow, hnorm, coe_nnnorm]
    exact ⟨_, hs'.hasSum.tendsto_sum_nat⟩
  · rintro x hx ⟨S, hS⟩
    have hterm : Tendsto (fun n => c n * x ^ n) atTop (𝓝 0) := by
      have := (hS.comp (tendsto_add_atTop_nat 1)).sub hS
      rw [sub_self] at this
      refine this.congr fun n => ?_
      simp [Function.comp, Finset.sum_range_succ]
    obtain ⟨C, hC⟩ := isBounded_iff_forall_norm_le.1 (Metric.isBounded_range_of_tendsto _ hterm)
    have hle : (‖x‖₊ : ℝ≥0∞) ≤ p.radius := by
      refine p.le_radius_of_bound C fun n => ?_
      have := hC _ ⟨n, rfl⟩
      rw [norm_mul, norm_pow] at this
      rw [hnorm, coe_nnnorm]
      exact this
    rw [hrad] at hle
    exact absurd hx (not_lt.2 hle)

-- Exceptions above 1.01: the even places n = 2 to 98, which number 49.
example : ((Finset.Icc 2 98).filter Even).card = 49 := by decide

-- Readings below -0.99 in the window up to 4000: the odd places 101 to 3999, which number 1950.
set_option maxRecDepth 100000 in
example : ((Finset.Icc 101 3999).filter Odd).card = 1950 := by decide

-- The coefficient ratios for c n = (2 + (-1)^n)^n swing: c 11 / c 10 = 1/3^10 and c 12 / c 11 = 3^12.
example : ((2 + (-1 : ℚ) ^ 11) ^ 11) / ((2 + (-1 : ℚ) ^ 10) ^ 10) = 1 / 59049 := by norm_num
example : ((2 + (-1 : ℚ) ^ 12) ^ 12) / ((2 + (-1 : ℚ) ^ 11) ^ 11) = 531441 := by norm_num

-- The series at x = 3/10, split into two geometric series: 1/(1 - 81/100) + (3/10)/(1 - 9/100).
example : (1 : ℚ) / (1 - 81 / 100) + (3 / 10) / (1 - 9 / 100) = 9670 / 1729 := by norm_num

#print axioms limsup_liminf_largest_smallest_subsequential_limits
#print axioms tendsto_iff_limsup_eq_liminf
#print axioms cauchy_hadamard_radius
