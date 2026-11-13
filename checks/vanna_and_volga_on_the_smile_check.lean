-- Vanna and volga: in the Garman–Kohlhagen model vega's slope in spot is -e^(-r_f T) φ(d1) d2 / σ and its slope in vol is vega d1 d2 / σ, a put shares the call's vega, vanna and volga, and with symmetric wings the straddle has no volga, the risk reversal no vega, and the vega-neutral butterfly carries volga alone.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open MeasureTheory ProbabilityTheory Real

/-! The model: `N(x)` is Mathlib's `cdf (gaussianReal 0 1) x`, the area under the standard
bell curve to the left of `x`, and `φ(x)` is Mathlib's `gaussianPDFReal 0 1 x`, its height.
Spot `S` (dollars per euro), strike `K`, dollar rate `rd`, euro rate `rf`, volatility `σ`,
years `T`. `d1 = (log (S / K) + (rd - rf + σ² / 2) T) / (σ √T)` and `d2 = d1 - σ √T`.
Call `C = S e^(-rf T) N(d1) - K e^(-rd T) N(d2)`; put `P = K e^(-rd T) N(-d2) - S e^(-rf T) N(-d1)`.
Vega `V = S e^(-rf T) φ(d1) √T`. Vanna is the slope of vega in `S`, volga its slope in `σ`,
every other input (strike, rates, time) held fixed. -/

/-- Helper: N(-y) + N(y) = 1 for the standard normal cdf. -/
lemma std_cdf_neg_add (y : ℝ) :
    cdf (gaussianReal 0 1) (-y) + cdf (gaussianReal 0 1) y = 1 := by
  have hmap : (gaussianReal (0:ℝ) 1).map (fun x ↦ -x) = gaussianReal 0 1 := by
    rw [gaussianReal_map_neg, neg_zero]
  rw [cdf_eq_real, cdf_eq_real]
  have h1 : (gaussianReal (0:ℝ) 1).real (Set.Iic (-y)) = (gaussianReal (0:ℝ) 1).real (Set.Ici y) := by
    conv_lhs => rw [← hmap]
    rw [map_measureReal_apply (by fun_prop) measurableSet_Iic]
    congr 1
    ext x; simp
  have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  rw [h1, measureReal_congr Ioi_ae_eq_Ici.symm]
  rw [add_comm, ← measureReal_union (Set.disjoint_left.mpr fun x hx hx' => by simp_all; linarith) measurableSet_Ioi]
  simp

#print axioms std_cdf_neg_add

lemma std_pdf_neg (x : ℝ) : gaussianPDFReal 0 1 (-x) = gaussianPDFReal 0 1 x := by
  simp [gaussianPDFReal]

#print axioms std_pdf_neg

lemma std_pdf_hasDerivAt (x : ℝ) :
    HasDerivAt (gaussianPDFReal 0 1) (-x * gaussianPDFReal 0 1 x) x := by
  have e : gaussianPDFReal 0 1 = fun x : ℝ => (√(2 * π))⁻¹ * rexp (-x ^ 2 / 2) := by
    rw [gaussianPDFReal_def]; ext y; simp
  rw [e]
  have h : HasDerivAt (fun x : ℝ => -x ^ 2 / 2) (-x) x := by
    have := ((hasDerivAt_id x).pow 2).neg.div_const 2
    convert this using 1
    · ext y; simp
    · simp; ring
  convert (h.exp).const_mul (√(2 * π))⁻¹ using 1
  ring

#print axioms std_pdf_hasDerivAt

/-- Vanna and volga (the formula, Steps 0 to 3): with a positive spot and strike, positive
volatility and positive time, Garman–Kohlhagen vega `V = S e^(-rf T) φ(d1) √T`, seen as a
function of spot alone, has slope `-e^(-rf T) φ(d1) d2 / σ` at `S` (vanna); seen as a
function of volatility alone, it has slope `V d1 d2 / σ` at `σ` (volga). -/
theorem vanna_and_volga_are_the_slopes_of_vega
    (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    let d1 : ℝ → ℝ → ℝ := fun x s => (log (x / K) + (rd - rf + s ^ 2 / 2) * T) / (s * √T)
    let V : ℝ → ℝ → ℝ := fun x s => x * exp (-(rf * T)) * gaussianPDFReal 0 1 (d1 x s) * √T
    HasDerivAt (fun x : ℝ => V x σ)
        (-(exp (-(rf * T)) * gaussianPDFReal 0 1 (d1 S σ) * ((d1 S σ - σ * √T) / σ))) S ∧
      HasDerivAt (fun s : ℝ => V S s) (V S σ * d1 S σ * (d1 S σ - σ * √T) / σ) σ := by
  obtain ⟨t, ht, rfl⟩ : ∃ t, 0 < t ∧ T = t ^ 2 :=
    ⟨√T, Real.sqrt_pos.2 hT, (Real.sq_sqrt hT.le).symm⟩
  have hst : √(t ^ 2) = t := Real.sqrt_sq ht.le
  intro d1 V
  simp only [d1, V, hst]
  constructor
  · have h1 : HasDerivAt (fun x => (log (x / K) + (rd - rf + σ ^ 2 / 2) * t ^ 2) / (σ * t))
        ((1 / K) / (S / K) / (σ * t)) S :=
      ((((hasDerivAt_id' S).div_const K).log (by positivity)).add_const _).div_const _
    have h2 := (std_pdf_hasDerivAt _).comp S h1
    have h3 := (((hasDerivAt_id' S).mul_const (exp (-(rf * t ^ 2)))).mul h2).mul_const t
    refine h3.congr_deriv ?_
    simp only [Function.comp]
    generalize gaussianPDFReal 0 1 _ = p
    field_simp
    ring
  · have hn : HasDerivAt (fun s => log (S / K) + (rd - rf + s ^ 2 / 2) * t ^ 2)
        (σ * t ^ 2) σ := by
      have := ((((hasDerivAt_pow 2 σ).div_const 2).const_add (rd - rf)).mul_const
        (t ^ 2)).const_add (log (S / K))
      convert this using 1
      push_cast; ring
    have h1 := hn.div ((hasDerivAt_id' σ).mul_const t) (by positivity)
    have h2 := (std_pdf_hasDerivAt _).comp σ h1
    have h3 := (h2.const_mul (S * exp (-(rf * t ^ 2)))).mul_const t
    refine h3.congr_deriv ?_
    simp only [Pi.div_apply]
    generalize gaussianPDFReal 0 1 _ = p
    generalize log (S / K) + (rd - rf + σ ^ 2 / 2) * t ^ 2 = N
    field_simp
    ring

/-- A call and a put share all three (Step 4): with a positive spot and strike, positive
volatility and positive time, the Garman–Kohlhagen put and call at the same strike have the
same vega (slope in `σ`), the same vanna (slope of vega in `S`) and the same volga (slope of
vega in `σ`), because put-call parity makes their difference free of `σ`. -/
theorem put_shares_call_vega_vanna_and_volga
    (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    let d1 : ℝ → ℝ → ℝ := fun x s => (log (x / K) + (rd - rf + s ^ 2 / 2) * T) / (s * √T)
    let C : ℝ → ℝ → ℝ := fun x s =>
      x * exp (-(rf * T)) * cdf (gaussianReal 0 1) (d1 x s) -
        K * exp (-(rd * T)) * cdf (gaussianReal 0 1) (d1 x s - s * √T)
    let P : ℝ → ℝ → ℝ := fun x s =>
      K * exp (-(rd * T)) * cdf (gaussianReal 0 1) (-(d1 x s - s * √T)) -
        x * exp (-(rf * T)) * cdf (gaussianReal 0 1) (-(d1 x s))
    deriv (fun s : ℝ => P S s) σ = deriv (fun s : ℝ => C S s) σ ∧
      deriv (fun x : ℝ => deriv (fun s : ℝ => P x s) σ) S =
        deriv (fun x : ℝ => deriv (fun s : ℝ => C x s) σ) S ∧
      deriv (deriv fun s : ℝ => P S s) σ = deriv (deriv fun s : ℝ => C S s) σ := by
  intro d1 C P
  have key : ∀ x s, P x s = C x s + (K * exp (-(rd * T)) - x * exp (-(rf * T))) := by
    intro x s
    have h1 := std_cdf_neg_add (d1 x s)
    have h2 := std_cdf_neg_add (d1 x s - s * √T)
    simp only [P, C]
    linear_combination (K * exp (-(rd * T))) * h2 - x * exp (-(rf * T)) * h1
  have hd : ∀ x, deriv (fun s => P x s) = deriv (fun s => C x s) := by
    intro x
    funext s
    simp only [key]
    exact deriv_add_const _
  refine ⟨by rw [hd], by simp only [hd], by rw [hd]⟩

/-- The three trades with symmetric wings (Step 6): with a positive spot, positive volatility
and positive time, take every leg at the one vol `σ`, the ATM strike where `d1 = 0`, and wing
strikes where `d1 = -a` (call wing) and `d1 = +a` (put wing), for any distance `a` (the
25-delta wings are the case `e^(-rf T) N(-a) = 1/4`). Writing `V_a = S e^(-rf T) φ(a) √T`:
the ATM straddle has no volga and vanna equal to its vega over spot; the risk reversal
(call wing minus put wing) has no vega, vanna `2 e^(-rf T) φ(a) a / σ` and volga
`2 V_a a √T`; and the butterfly that buys both wings and sells `w` straddles, with `w` chosen
to cancel vega, has no vega, no vanna and volga `2 V_a a² / σ`. -/
theorem risk_reversal_trades_vanna_and_butterfly_trades_volga
    (S rd rf σ T a : ℝ) (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T) :
    let d1 : ℝ → ℝ := fun k => (log (S / k) + (rd - rf + σ ^ 2 / 2) * T) / (σ * √T)
    let vega : ℝ → ℝ := fun k => S * exp (-(rf * T)) * gaussianPDFReal 0 1 (d1 k) * √T
    let vanna : ℝ → ℝ := fun k =>
      -(exp (-(rf * T)) * gaussianPDFReal 0 1 (d1 k) * ((d1 k - σ * √T) / σ))
    let volga : ℝ → ℝ := fun k => vega k * d1 k * (d1 k - σ * √T) / σ
    let F : ℝ := S * exp ((rd - rf) * T)
    let Katm : ℝ := F * exp (σ ^ 2 * T / 2)
    let Kc : ℝ := F * exp (a * σ * √T + σ ^ 2 * T / 2)
    let Kp : ℝ := F * exp (-(a * σ * √T) + σ ^ 2 * T / 2)
    let Va : ℝ := S * exp (-(rf * T)) * gaussianPDFReal 0 1 a * √T
    let w : ℝ := (vega Kc + vega Kp) / (2 * vega Katm)
    -- ATM straddle: two legs at `Katm`
    (2 * vanna Katm = 2 * vega Katm / S ∧ 2 * volga Katm = 0) ∧
      -- risk reversal: call wing minus put wing
      (vega Kc - vega Kp = 0 ∧
        vanna Kc - vanna Kp = 2 * exp (-(rf * T)) * gaussianPDFReal 0 1 a * a / σ ∧
        volga Kc - volga Kp = 2 * Va * a * √T) ∧
      -- vega-neutral butterfly: both wings minus `w` straddles
      ((vega Kc + vega Kp) - w * (2 * vega Katm) = 0 ∧
        (vanna Kc + vanna Kp) - w * (2 * vanna Katm) = 0 ∧
        (volga Kc + volga Kp) - w * (2 * volga Katm) = 2 * Va * a ^ 2 / σ) := by
  obtain ⟨t, ht, rfl⟩ : ∃ t, 0 < t ∧ T = t ^ 2 :=
    ⟨√T, Real.sqrt_pos.2 hT, (Real.sq_sqrt hT.le).symm⟩
  have hst : √(t ^ 2) = t := Real.sqrt_sq ht.le
  intro d1 vega vanna volga F Katm Kc Kp Va w
  have hd : ∀ u, d1 (F * exp (u + σ ^ 2 * t ^ 2 / 2)) = -u / (σ * t) := by
    intro u
    simp only [d1, F, hst]
    rw [log_div hS.ne' (by positivity), log_mul (by positivity) (by positivity),
      log_mul hS.ne' (by positivity), log_exp, log_exp]
    ring
  have e0 : d1 Katm = 0 := by
    have := hd 0
    simp only [zero_add, neg_zero, zero_div] at this
    exact this
  have ec : d1 Kc = -a := by
    rw [show Kc = F * exp (a * σ * √(t ^ 2) + σ ^ 2 * t ^ 2 / 2) from rfl, hd, hst]
    field_simp
  have ep : d1 Kp = a := by
    rw [show Kp = F * exp (-(a * σ * √(t ^ 2)) + σ ^ 2 * t ^ 2 / 2) from rfl, hd, hst]
    field_simp
  have h0 := gaussianPDFReal_pos 0 1 0 one_ne_zero
  simp only [w, Va, volga, vanna, vega, e0, ec, ep, std_pdf_neg, hst]
  refine ⟨⟨?_, ?_⟩, ⟨?_, ?_, ?_⟩, ⟨?_, ?_, ?_⟩⟩
  all_goals field_simp
  all_goals ring

/-! The card's worked example in exact fractions: S = K = 1.10 = 11/10, rd = 5/100,
rf = 3/100, σ = 1/10, T = 1. -/

-- d1 = (ln 1 + (0.02 + 0.005)) / 0.10 = 0.25.
example :
    (log ((11 / 10 : ℝ) / (11 / 10)) + (5 / 100 - 3 / 100 + (1 / 10) ^ 2 / 2) * 1) /
        (1 / 10 * √1) = 1 / 4 := by
  norm_num

-- d2 = d1 - σ √T = 0.25 - 0.10 = 0.15.
example : (1 / 4 : ℝ) - 1 / 10 * √1 = 3 / 20 := by norm_num

-- The vanna factor d2 / σ = 0.15 / 0.10 = 1.5.
example : ((3 : ℚ) / 20) / (1 / 10) = 3 / 2 := by norm_num

-- The volga factor d1 d2 / σ = 0.25 × 0.15 / 0.10 = 0.375.
example : ((1 : ℚ) / 4) * (3 / 20) / (1 / 10) = 3 / 8 := by norm_num

-- The pillar vols: put wing ATM + BF - RR/2 = 10.75%, call wing ATM + BF + RR/2 = 9.75%.
example : ((10 : ℚ) / 100 + 25 / 10000 - (-1 / 100) / 2 = 1075 / 10000) ∧
    ((10 : ℚ) / 100 + 25 / 10000 + (-1 / 100) / 2 = 975 / 10000) := by
  norm_num

#print axioms vanna_and_volga_are_the_slopes_of_vega
#print axioms put_shares_call_vega_vanna_and_volga
#print axioms risk_reversal_trades_vanna_and_butterfly_trades_volga
