-- The Black-Scholes equation: an option hedged with Δ shares is riskless and earns the bank rate, whatever the share's real growth μ, exactly when Δ = V_S and V_t + (r - q) S V_S + ½ σ² S² V_SS = r V, and the call, the put and a prepaid share less a loan all obey that equation before expiry.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.ContDiff.Basic

open Real MeasureTheory ProbabilityTheory

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- The cash-side distance to the strike with `τ` years of life left:
`d₂ = (ln(S/K) + (r - q - σ²/2) τ) / (σ√τ)`; the share-side distance is `d₁ = d₂ + σ√τ`. -/
noncomputable def bsD2 (S K r q σ τ : ℝ) : ℝ :=
  (log (S / K) + (r - q - σ ^ 2 / 2) * τ) / (σ * √τ)

/-- The Black-Scholes call's worth at share price `S` and calendar date `t`, expiry `T`:
`S e^(-q(T - t)) N(d₁) - K e^(-r(T - t)) N(d₂)`. -/
noncomputable def bsCall (K r q σ T S t : ℝ) : ℝ :=
  S * exp (-q * (T - t)) * stdNormalCDF (bsD2 S K r q σ (T - t) + σ * √(T - t))
    - K * exp (-r * (T - t)) * stdNormalCDF (bsD2 S K r q σ (T - t))

/-- The Black-Scholes put's worth at share price `S` and calendar date `t`, expiry `T`:
`K e^(-r(T - t)) N(-d₂) - S e^(-q(T - t)) N(-d₁)`. -/
noncomputable def bsPut (K r q σ T S t : ℝ) : ℝ :=
  K * exp (-r * (T - t)) * stdNormalCDF (-bsD2 S K r q σ (T - t))
    - S * exp (-q * (T - t)) * stdNormalCDF (-(bsD2 S K r q σ (T - t) + σ * √(T - t)))

/-- The card's equation at share price `S` and date `t`, for a worth `V(S, t)`:
`∂V/∂t + (r - q) S ∂V/∂S + ½ σ² S² ∂²V/∂S² = r V`, each slope taken with the other variable
held still. -/
def ObeysBlackScholes (V : ℝ → ℝ → ℝ) (r q σ S t : ℝ) : Prop :=
  deriv (fun u => V S u) t
      + (r - q) * S * deriv (fun x => V x t) S
      + 1 / 2 * σ ^ 2 * S ^ 2 * deriv (fun x => deriv (fun y => V y t) x) S
    = r * V S t

noncomputable def bsPhi (x : ℝ) : ℝ := (√(2 * π))⁻¹ * exp (-x ^ 2 / 2)

lemma gaussianPDFReal_zero_one_eq : gaussianPDFReal 0 1 = bsPhi := by
  funext x
  simp [gaussianPDFReal, bsPhi]

lemma stdNormalCDF_eq_integral (x : ℝ) :
    stdNormalCDF x = ∫ y in Set.Iic x, bsPhi y := by
  rw [stdNormalCDF, cdf_eq_real, measureReal_def,
    gaussianReal_apply_eq_integral _ one_ne_zero, ENNReal.toReal_ofReal,
    gaussianPDFReal_zero_one_eq]
  exact setIntegral_nonneg measurableSet_Iic (fun y _ => gaussianPDFReal_nonneg _ _ _)

lemma continuous_bsPhi : Continuous bsPhi := by
  unfold bsPhi; fun_prop

lemma stdNormalCDF_eq_add (x : ℝ) :
    stdNormalCDF x = stdNormalCDF 0 + ∫ y in (0:ℝ)..x, bsPhi y := by
  have hi : Integrable bsPhi := by
    rw [← gaussianPDFReal_zero_one_eq]; exact integrable_gaussianPDFReal _ _
  rw [← intervalIntegral.integral_Iic_sub_Iic hi.integrableOn hi.integrableOn,
    stdNormalCDF_eq_integral, stdNormalCDF_eq_integral]
  ring

lemma hasDerivAt_stdNormalCDF (x : ℝ) : HasDerivAt stdNormalCDF (bsPhi x) x := by
  have h := (continuous_bsPhi.integral_hasStrictDerivAt 0 x).hasDerivAt.const_add
    (stdNormalCDF 0)
  have he : stdNormalCDF = fun x => stdNormalCDF 0 + ∫ y in (0:ℝ)..x, bsPhi y :=
    funext stdNormalCDF_eq_add
  rw [he]; exact h

lemma bsPhi_neg (x : ℝ) : bsPhi (-x) = bsPhi x := by simp [bsPhi]

lemma stdNormalCDF_neg (x : ℝ) : stdNormalCDF (-x) = 1 - stdNormalCDF x := by
  set g : ℝ → ℝ := fun x => stdNormalCDF (-x) + stdNormalCDF x with hg
  have hd : ∀ x, HasDerivAt g 0 x := by
    intro x
    have h1 := (hasDerivAt_stdNormalCDF (-x)).comp x (hasDerivAt_neg x)
    have h2 : HasDerivAt g (bsPhi (-x) * -1 + bsPhi x) x := h1.add (hasDerivAt_stdNormalCDF x)
    convert h2 using 1
    rw [bsPhi_neg]; ring
  have hconst : ∀ y, g y = g 0 := fun y =>
    is_const_of_deriv_eq_zero (fun z => (hd z).differentiableAt) (fun z => (hd z).deriv) y 0
  have hlim : Filter.Tendsto g Filter.atTop (nhds (0 + 1)) := by
    have h1 : Filter.Tendsto (fun x => stdNormalCDF (-x)) Filter.atTop (nhds 0) :=
      (tendsto_cdf_atBot (μ := gaussianReal 0 1)).comp Filter.tendsto_neg_atTop_atBot
    exact h1.add (tendsto_cdf_atTop (μ := gaussianReal 0 1))
  have hlim2 : Filter.Tendsto g Filter.atTop (nhds (g 0)) := by
    have : g = fun _ => g 0 := funext hconst
    rw [this]; exact tendsto_const_nhds
  have := tendsto_nhds_unique hlim2 hlim
  have h3 := hconst x
  simp only [hg] at h3 this
  linarith

lemma bs_phi_identity (S K r q σ τ : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hτ : 0 < τ) :
    S * exp (-q * τ) * bsPhi (bsD2 S K r q σ τ + σ * √τ)
      = K * exp (-r * τ) * bsPhi (bsD2 S K r q σ τ) := by
  have hs : 0 < √τ := Real.sqrt_pos.mpr hτ
  have hs2 : √τ ^ 2 = τ := Real.sq_sqrt hτ.le
  have hd : bsD2 S K r q σ τ * (σ * √τ) = log S - log K + (r - q - σ ^ 2 / 2) * τ := by
    unfold bsD2
    rw [Real.log_div hS.ne' hK.ne']
    field_simp
  set d := bsD2 S K r q σ τ
  unfold bsPhi
  have hexp : exp (log S) * exp (-q * τ) * exp (-(d + σ * √τ) ^ 2 / 2)
      = exp (log K) * exp (-r * τ) * exp (-d ^ 2 / 2) := by
    rw [← Real.exp_add, ← Real.exp_add, ← Real.exp_add, ← Real.exp_add]
    congr 1
    linear_combination (-1 : ℝ) * hd - σ ^ 2 / 2 * hs2
  rw [Real.exp_log hS, Real.exp_log hK] at hexp
  linear_combination (√(2 * π))⁻¹ * hexp

lemma hasDerivAt_bsD2_S (K r q σ τ x : ℝ) (hx : x ≠ 0) (hK : K ≠ 0) :
    HasDerivAt (fun x => bsD2 x K r q σ τ) ((1 / K) / (x / K) / (σ * √τ)) x := by
  have h := ((((hasDerivAt_id x).div_const K).log (div_ne_zero hx hK)).add_const
    ((r - q - σ ^ 2 / 2) * τ)).div_const (σ * √τ)
  exact h

lemma hasDerivAt_bsCall_S (K r q σ T t x : ℝ) (hK : 0 < K) (hσ : 0 < σ) (hx : 0 < x)
    (ht : t < T) :
    HasDerivAt (fun x => bsCall K r q σ T x t)
      (exp (-q * (T - t)) * stdNormalCDF (bsD2 x K r q σ (T - t) + σ * √(T - t))) x := by
  have hτ : 0 < T - t := by linarith
  have hd2 := hasDerivAt_bsD2_S K r q σ (T - t) x hx.ne' hK.ne'
  have hd1 := hd2.add_const (σ * √(T - t))
  have hN1 := (hasDerivAt_stdNormalCDF _).comp x hd1
  have hN2 := (hasDerivAt_stdNormalCDF _).comp x hd2
  have h := (((hasDerivAt_id x).mul_const (exp (-q * (T - t)))).mul hN1).sub
    (hN2.const_mul (K * exp (-r * (T - t))))
  have hid := bs_phi_identity x K r q σ (T - t) hx hK hσ hτ
  convert h using 1
  · rfl
  simp only [id, Function.comp_apply]
  linear_combination (-((1 / K) / (x / K) / (σ * √(T - t)))) * hid

lemma hasDerivAt_bsCall_SS (K r q σ T t S : ℝ) (hK : 0 < K) (hS : 0 < S) :
    HasDerivAt (fun x => exp (-q * (T - t)) * stdNormalCDF (bsD2 x K r q σ (T - t) + σ * √(T - t)))
      (exp (-q * (T - t)) * (bsPhi (bsD2 S K r q σ (T - t) + σ * √(T - t))
        * ((1 / K) / (S / K) / (σ * √(T - t))))) S := by
  have hS' : S ≠ 0 := hS.ne'
  have hd1 := (hasDerivAt_bsD2_S K r q σ (T - t) S hS' hK.ne').add_const (σ * √(T - t))
  exact ((hasDerivAt_stdNormalCDF _).comp S hd1).const_mul _

lemma hasDerivAt_bsCall_t (K r q σ T t S : ℝ) (hK : 0 < K) (hσ : 0 < σ) (hS : 0 < S)
    (ht : t < T) :
    HasDerivAt (fun u => bsCall K r q σ T S u)
      (q * S * exp (-q * (T - t)) * stdNormalCDF (bsD2 S K r q σ (T - t) + σ * √(T - t))
        - r * K * exp (-r * (T - t)) * stdNormalCDF (bsD2 S K r q σ (T - t))
        - S * exp (-q * (T - t)) * bsPhi (bsD2 S K r q σ (T - t) + σ * √(T - t))
          * σ / (2 * √(T - t))) t := by
  have hτ : 0 < T - t := by linarith
  have hτ' : T - t ≠ 0 := hτ.ne'
  have hs : 0 < √(T - t) := Real.sqrt_pos.mpr hτ
  have hT : HasDerivAt (fun u : ℝ => T - u) (-1) t := (hasDerivAt_id t).const_sub T
  have hsq : HasDerivAt (fun u : ℝ => √(T - u)) (-1 / (2 * √(T - t))) t := hT.sqrt hτ'
  have hnum : HasDerivAt (fun u : ℝ => log (S / K) + (r - q - σ ^ 2 / 2) * (T - u))
      ((r - q - σ ^ 2 / 2) * -1) t := (hT.const_mul _).const_add _
  have hden : HasDerivAt (fun u : ℝ => σ * √(T - u)) (σ * (-1 / (2 * √(T - t)))) t :=
    hsq.const_mul σ
  obtain ⟨D2, hd2⟩ : ∃ D2, HasDerivAt (fun u => bsD2 S K r q σ (T - u)) D2 t :=
    ⟨_, hnum.div hden (by positivity)⟩
  have hd1 := hd2.add hden
  have hN1 := (hasDerivAt_stdNormalCDF _).comp t hd1
  have hN2 := (hasDerivAt_stdNormalCDF _).comp t hd2
  have he1 : HasDerivAt (fun u : ℝ => exp (-q * (T - u))) (exp (-q * (T - t)) * (-q * -1)) t :=
    (hT.const_mul (-q)).exp
  have he2 : HasDerivAt (fun u : ℝ => exp (-r * (T - u))) (exp (-r * (T - t)) * (-r * -1)) t :=
    (hT.const_mul (-r)).exp
  have h := ((he1.const_mul S).mul hN1).sub ((he2.const_mul K).mul hN2)
  have hid := bs_phi_identity S K r q σ (T - t) hS hK hσ hτ
  convert h using 1
  · rfl
  simp only [Function.comp_apply, Pi.add_apply]
  linear_combination (-D2) * hid

lemma hasDerivAt_prepaid_t (K r q T t S : ℝ) :
    HasDerivAt (fun u => S * exp (-q * (T - u)) - K * exp (-r * (T - u)))
      (q * S * exp (-q * (T - t)) - r * K * exp (-r * (T - t))) t := by
  have hT : HasDerivAt (fun u : ℝ => T - u) (-1) t := (hasDerivAt_id t).const_sub T
  have h := (((hT.const_mul (-q)).exp).const_mul S).sub (((hT.const_mul (-r)).exp).const_mul K)
  convert h using 1
  ring

lemma hasDerivAt_prepaid_S (K r q T t x : ℝ) :
    HasDerivAt (fun x => x * exp (-q * (T - t)) - K * exp (-r * (T - t)))
      (exp (-q * (T - t))) x := by
  have h := ((hasDerivAt_id x).mul_const (exp (-q * (T - t)))).sub_const
    (K * exp (-r * (T - t)))
  convert h using 1 <;> simp

lemma bsPut_eq (K r q σ T : ℝ) :
    bsPut K r q σ T = fun x u => bsCall K r q σ T x u
      - (x * exp (-q * (T - u)) - K * exp (-r * (T - u))) := by
  funext x u
  unfold bsPut bsCall
  rw [stdNormalCDF_neg, stdNormalCDF_neg]
  ring

#print axioms gaussianPDFReal_zero_one_eq
#print axioms stdNormalCDF_eq_integral
#print axioms continuous_bsPhi
#print axioms stdNormalCDF_eq_add
#print axioms hasDerivAt_stdNormalCDF
#print axioms bsPhi_neg
#print axioms stdNormalCDF_neg
#print axioms bs_phi_identity
#print axioms hasDerivAt_bsD2_S
#print axioms hasDerivAt_bsCall_S
#print axioms hasDerivAt_bsCall_SS
#print axioms hasDerivAt_bsCall_t
#print axioms hasDerivAt_prepaid_t
#print axioms hasDerivAt_prepaid_S
#print axioms bsPut_eq

/-- **The Black-Scholes equation** (The formula; Why it works, Steps 1 to 4). The share follows
geometric Brownian motion `dS = μ S dt + σ S dW` with real growth `μ`, volatility `σ > 0`, and a
steady dividend yield `q`; the bank rate `r` holds still. The claim's worth `V(S, t)` has smooth
slopes near today's price `S > 0` and date `t`, strictly before expiry `T`. Hold one claim and
short `Δ` shares, `Δ` held fixed across the instant. By Itô's lemma the book `V - Δ S` changes by
`drift · dt + shock · dW`, with shock `σ S (∂V/∂S - Δ)` and drift
`∂V/∂t + μ S ∂V/∂S + ½ σ² S² ∂²V/∂S² - μ S Δ - q S Δ` (the last term is the dividend owed on the
borrowed shares). Then, for every `μ`: the book is riskless and earns exactly the bank rate on its
own value precisely when `Δ = ∂V/∂S` and `V` obeys
`∂V/∂t + (r - q) S ∂V/∂S + ½ σ² S² ∂²V/∂S² = r V`. The real growth `μ` is absent from the answer. -/
theorem hedged_option_earns_bank_rate_iff_black_scholes_equation
    (V : ℝ → ℝ → ℝ) (S t T r q σ μ Δ : ℝ) (hS : 0 < S) (hσ : 0 < σ) (ht : t < T)
    (hV : ContDiffAt ℝ 2 (fun p : ℝ × ℝ => V p.1 p.2) (S, t)) :
    let Vt := deriv (fun u => V S u) t
    let VS := deriv (fun x => V x t) S
    let VSS := deriv (fun x => deriv (fun y => V y t) x) S
    let shock := σ * S * (VS - Δ)
    let drift := Vt + μ * S * VS + 1 / 2 * σ ^ 2 * S ^ 2 * VSS - μ * S * Δ - q * S * Δ
    (shock = 0 ∧ drift = r * (V S t - Δ * S)) ↔
      (Δ = VS ∧ ObeysBlackScholes V r q σ S t) := by
  intro Vt VS VSS shock drift
  have hσS : σ * S ≠ 0 := by positivity
  unfold ObeysBlackScholes
  constructor
  · rintro ⟨h1, h2⟩
    have hΔ : Δ = VS := by
      have h1' : σ * S * (VS - Δ) = 0 := h1
      rcases mul_eq_zero.mp h1' with h | h
      · exact absurd h hσS
      · linarith
    refine ⟨hΔ, ?_⟩
    have h2' : Vt + μ * S * VS + 1 / 2 * σ ^ 2 * S ^ 2 * VSS - μ * S * Δ - q * S * Δ
        = r * (V S t - Δ * S) := h2
    rw [hΔ] at h2'
    show Vt + (r - q) * S * VS + 1 / 2 * σ ^ 2 * S ^ 2 * VSS = r * V S t
    linear_combination h2'
  · rintro ⟨hΔ, h⟩
    have h' : Vt + (r - q) * S * VS + 1 / 2 * σ ^ 2 * S ^ 2 * VSS = r * V S t := h
    refine ⟨?_, ?_⟩
    · show σ * S * (VS - Δ) = 0
      rw [hΔ]; ring
    · show Vt + μ * S * VS + 1 / 2 * σ ^ 2 * S ^ 2 * VSS - μ * S * Δ - q * S * Δ
        = r * (V S t - Δ * S)
      rw [hΔ]
      linear_combination h'

/-- **The call and the put both obey it** (Code, roads one and two). With strike `K > 0`,
volatility `σ > 0`, any bank rate `r` and dividend yield `q`: at every share price `S > 0` and
every date `t` strictly before expiry `T`, the Black-Scholes call
`S e^(-q(T - t)) N(d₁) - K e^(-r(T - t)) N(d₂)` and put
`K e^(-r(T - t)) N(-d₂) - S e^(-q(T - t)) N(-d₁)` each satisfy
`∂V/∂t + (r - q) S ∂V/∂S + ½ σ² S² ∂²V/∂S² = r V`. -/
theorem black_scholes_call_and_put_obey_equation
    (K r q σ T S t : ℝ) (hK : 0 < K) (hσ : 0 < σ) (hS : 0 < S) (ht : t < T) :
    ObeysBlackScholes (bsCall K r q σ T) r q σ S t ∧
      ObeysBlackScholes (bsPut K r q σ T) r q σ S t := by
  have hτ : 0 < T - t := by linarith
  have hs : 0 < √(T - t) := Real.sqrt_pos.mpr hτ
  have heq : (fun x => deriv (fun y => bsCall K r q σ T y t) x) =ᶠ[nhds S]
      (fun x => exp (-q * (T - t)) * stdNormalCDF (bsD2 x K r q σ (T - t) + σ * √(T - t))) := by
    filter_upwards [Ioi_mem_nhds hS] with x hx
    exact (hasDerivAt_bsCall_S K r q σ T t x hK hσ hx ht).deriv
  have hSS := hasDerivAt_bsCall_SS K r q σ T t S hK hS
  have hSt := hasDerivAt_bsCall_t K r q σ T t S hK hσ hS ht
  have hS1 := hasDerivAt_bsCall_S K r q σ T t S hK hσ hS ht
  constructor
  · unfold ObeysBlackScholes
    rw [hSt.deriv, hS1.deriv, heq.deriv_eq, hSS.deriv]
    unfold bsCall
    generalize exp (-q * (T - t)) = e1
    generalize exp (-r * (T - t)) = e2
    generalize stdNormalCDF (bsD2 S K r q σ (T - t) + σ * √(T - t)) = N1
    generalize stdNormalCDF (bsD2 S K r q σ (T - t)) = N2
    generalize bsPhi (bsD2 S K r q σ (T - t) + σ * √(T - t)) = p1
    generalize √(T - t) = s at hs
    field_simp
    ring
  · rw [bsPut_eq]
    unfold ObeysBlackScholes
    beta_reduce
    have heq' : (fun x => deriv (fun y => bsCall K r q σ T y t
          - (y * exp (-q * (T - t)) - K * exp (-r * (T - t)))) x) =ᶠ[nhds S]
        (fun x => exp (-q * (T - t)) * stdNormalCDF (bsD2 x K r q σ (T - t) + σ * √(T - t))
          - exp (-q * (T - t))) := by
      filter_upwards [Ioi_mem_nhds hS] with x hx
      exact ((hasDerivAt_bsCall_S K r q σ T t x hK hσ hx ht).sub
        (hasDerivAt_prepaid_S K r q T t x)).deriv
    have hPt : HasDerivAt (fun u => bsCall K r q σ T S u
        - (S * exp (-q * (T - u)) - K * exp (-r * (T - u)))) _ t :=
      hSt.sub (hasDerivAt_prepaid_t K r q T t S)
    have hPS : HasDerivAt (fun x => bsCall K r q σ T x t
        - (x * exp (-q * (T - t)) - K * exp (-r * (T - t)))) _ S :=
      hS1.sub (hasDerivAt_prepaid_S K r q T t S)
    have hPSS : HasDerivAt (fun x => exp (-q * (T - t))
        * stdNormalCDF (bsD2 x K r q σ (T - t) + σ * √(T - t)) - exp (-q * (T - t))) _ S :=
      hSS.sub_const _
    rw [hPt.deriv, hPS.deriv, heq'.deriv_eq, hPSS.deriv]
    unfold bsCall
    generalize exp (-q * (T - t)) = e1
    generalize exp (-r * (T - t)) = e2
    generalize stdNormalCDF (bsD2 S K r q σ (T - t) + σ * √(T - t)) = N1
    generalize stdNormalCDF (bsD2 S K r q σ (T - t)) = N2
    generalize bsPhi (bsD2 S K r q σ (T - t) + σ * √(T - t)) = p1
    generalize √(T - t) = s at hs
    field_simp
    ring

/-- **The equation does not know the payoff** (Step 4; Code, road two). A prepaid share less a
loan, `V(S, t) = S e^(-q(T - t)) - K e^(-r(T - t))`, a claim with no bend at all, obeys
`∂V/∂t + (r - q) S ∂V/∂S + ½ σ² S² ∂²V/∂S² = r V` at every share price `S` and every date `t`. -/
theorem prepaid_share_less_loan_obeys_equation (K r q σ T S t : ℝ) :
    ObeysBlackScholes (fun x u => x * exp (-q * (T - u)) - K * exp (-r * (T - u))) r q σ S t := by
  unfold ObeysBlackScholes
  beta_reduce
  have h2 : (fun x => deriv (fun y => y * exp (-q * (T - t)) - K * exp (-r * (T - t))) x)
      = fun _ => exp (-q * (T - t)) := funext fun x => (hasDerivAt_prepaid_S K r q T t x).deriv
  rw [(hasDerivAt_prepaid_t K r q T t S).deriv, (hasDerivAt_prepaid_S K r q T t S).deriv, h2,
    deriv_const]
  ring

-- House market: S = K = 100, r = 5/100, q = 2/100, σ = 1/5, one year to run.
-- The carry's factor (r - q) S = 0.03 × 100 = 3.
example : ((5 : ℚ) / 100 - 2 / 100) * 100 = 3 := by norm_num
-- The bend's factor ½ σ² S² = 0.5 × 0.04 × 10000 = 200.
example : (1 / 2 : ℚ) * (1 / 5) ^ 2 * 100 ^ 2 = 200 := by norm_num
-- B, the carry: 0.03 × 100 × 0.586851 = 1.760553.
example : ((5 : ℚ) / 100 - 2 / 100) * 100 * (586851 / 1000000) = 1760553 / 1000000 := by norm_num
-- Left side A + B + C: -5.089319 + 1.760553 + 3.790116 = 0.461350.
example : (-5089319 : ℚ) / 1000000 + 1760553 / 1000000 + 3790116 / 1000000
    = 461350 / 1000000 := by norm_num
-- The desk's reading: clock plus bend, -5.089319 + 3.790116 = -1.299203.
example : (-5089319 : ℚ) / 1000000 + 3790116 / 1000000 = -1299203 / 1000000 := by norm_num
-- The shares hand back q S Δ = 0.02 × 100 × 0.586851 = 1.173702.
example : (2 : ℚ) / 100 * 100 * (586851 / 1000000) = 1173702 / 1000000 := by norm_num
-- Clock taken the wrong way round leaves twice theta: 2 × 5.089319 = 10.178638.
example : (2 : ℚ) * (5089319 / 1000000) = 10178638 / 1000000 := by norm_num
-- Chart at $100: -5.09 + 3.79 + 1.76 = 0.46.
example : (-509 : ℚ) / 100 + 379 / 100 + 176 / 100 = 46 / 100 := by norm_num
-- Cents a trading day, 12 months left: -2.02 + 1.50 + 0.70 = 0.18.
example : (-202 : ℚ) / 100 + 150 / 100 + 70 / 100 = 18 / 100 := by norm_num
-- 3 months left: -3.69 + 3.13 + 0.65 = 0.09.
example : (-369 : ℚ) / 100 + 313 / 100 + 65 / 100 = 9 / 100 := by norm_num
-- 1 month left: -6.04 + 5.46 + 0.63 = 0.05.
example : (-604 : ℚ) / 100 + 546 / 100 + 63 / 100 = 5 / 100 := by norm_num
-- Step 4: the two share-slope terms collect, -q S V_S + r S V_S = (r - q) S V_S.
example (r q S VS : ℚ) : -q * S * VS + r * S * VS = (r - q) * S * VS := by ring

#print axioms hedged_option_earns_bank_rate_iff_black_scholes_equation
#print axioms black_scholes_call_and_put_obey_equation
#print axioms prepaid_share_less_loan_obeys_equation
