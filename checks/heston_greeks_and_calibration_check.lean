-- Heston Greeks and calibration: the doubling rule makes delta equal to e^(-qT) P1 and ties gamma to the strike curvature, and two share-price derivatives of the integrand's factor bring down -(u^2 + 1/4)/S^2.
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Complex.RealDeriv

open Complex

/-- Helper: derivative of `s ↦ (c s)^w` for positive `c` and `s`. -/
lemma heston_cpow_scaled_hasDerivAt (c s : ℝ) (w : ℂ) (hc : 0 < c) (hs : 0 < s) :
    HasDerivAt (fun t : ℝ => (((c * t : ℝ)) : ℂ) ^ w)
      (w * (((c * s : ℝ)) : ℂ) ^ (w - 1) * c) s := by
  have h : HasDerivAt (fun z : ℂ => (c : ℂ) * z) (c : ℂ) (s : ℂ) := by
    simpa using (hasDerivAt_id (s : ℂ)).const_mul (c : ℂ)
  have hmem : (fun z : ℂ => (c : ℂ) * z) (s : ℂ) ∈ slitPlane := by
    have : (fun z : ℂ => (c : ℂ) * z) (s : ℂ) = ((c * s : ℝ) : ℂ) := by push_cast; rfl
    rw [this]
    exact ofReal_mem_slitPlane.2 (mul_pos hc hs)
  have h2 := (h.cpow_const (c := w) hmem).comp_ofReal
  convert h2 using 1
  · funext t; push_cast; rfl
  · push_cast; rfl

#print axioms heston_cpow_scaled_hasDerivAt

/-- The doubling rule gives delta. Let `C S K` be a call's price as a function of the share
price `S` and the strike `K`. Suppose multiplying share price and strike by one positive
factor `a` multiplies the price by `a` (Heston's variance ignores the share price), the price
is differentiable in `(S, K)`, the price has Heston's form `S e^{-qT} P1 - K e^{-rT} P2`,
and the strike derivative is minus the discounted cash probability, `-e^{-rT} P2`.
Then delta, the derivative in the share price, is `e^{-qT} P1`. -/
theorem heston_delta_eq_discounted_P1
    (C : ℝ → ℝ → ℝ) (S K T r q P1 P2 : ℝ) (hS : 0 < S) (hK : 0 < K)
    (hhom : ∀ a s k : ℝ, 0 < a → 0 < s → 0 < k → C (a * s) (a * k) = a * C s k)
    (hdiff : DifferentiableAt ℝ (fun p : ℝ × ℝ => C p.1 p.2) (S, K))
    (hform : C S K = S * Real.exp (-q * T) * P1 - K * Real.exp (-r * T) * P2)
    (hstrike : HasDerivAt (fun k => C S k) (-(Real.exp (-r * T) * P2)) K) :
    HasDerivAt (fun s => C s K) (Real.exp (-q * T) * P1) S := by
  set L := fderiv ℝ (fun p : ℝ × ℝ => C p.1 p.2) (S, K) with hL
  have hF : HasFDerivAt (fun p : ℝ × ℝ => C p.1 p.2) L (S, K) := hdiff.hasFDerivAt
  -- partial derivative in the share price
  have hs : HasDerivAt (fun s => C s K) (L (1, 0)) S := by
    have h0 : HasDerivAt (fun s : ℝ => (s, K)) ((1 : ℝ), (0 : ℝ)) S :=
      (hasDerivAt_id S).prodMk (hasDerivAt_const S K)
    exact hF.comp_hasDerivAt S h0
  -- partial derivative in the strike
  have hk : HasDerivAt (fun k => C S k) (L (0, 1)) K := by
    have h0 : HasDerivAt (fun k : ℝ => (S, k)) ((0 : ℝ), (1 : ℝ)) K :=
      (hasDerivAt_const K S).prodMk (hasDerivAt_id K)
    exact hF.comp_hasDerivAt K h0
  have hk' : L (0, 1) = -(Real.exp (-r * T) * P2) := hk.unique hstrike
  -- Euler's relation from the doubling rule
  have hscale : HasDerivAt (fun a : ℝ => C (a * S) (a * K)) (L (S, K)) 1 := by
    have h0 : HasDerivAt (fun a : ℝ => (a * S, a * K)) (S, K) 1 := by
      have h1 := ((hasDerivAt_id (1:ℝ)).mul_const S).prodMk ((hasDerivAt_id (1:ℝ)).mul_const K)
      simpa using h1
    have hF1 : HasFDerivAt (fun p : ℝ × ℝ => C p.1 p.2) L ((1:ℝ) * S, (1:ℝ) * K) := by
      simpa using hF
    have := hF1.comp_hasDerivAt (1:ℝ) h0
    simpa [Function.comp_def] using this
  have hscale' : HasDerivAt (fun a : ℝ => C (a * S) (a * K)) (C S K) 1 := by
    have h1 : HasDerivAt (fun a : ℝ => a * C S K) (C S K) 1 := by
      simpa using (hasDerivAt_id (1:ℝ)).mul_const (C S K)
    apply h1.congr_of_eventuallyEq
    filter_upwards [Ioi_mem_nhds (show (0:ℝ) < 1 by norm_num)] with a ha
    exact hhom a S K ha hS hK
  have heuler : L (S, K) = C S K := hscale.unique hscale'
  have hsplit : ((S, K) : ℝ × ℝ) = S • ((1 : ℝ), (0 : ℝ)) + K • ((0 : ℝ), (1 : ℝ)) := by
    ext <;> simp
  rw [hsplit, map_add, map_smul, map_smul, hk', hform] at heuler
  simp only [smul_eq_mul] at heuler
  have : L (1, 0) = Real.exp (-q * T) * P1 := by
    have h2 : S * (L (1, 0) - Real.exp (-q * T) * P1) = 0 := by linarith
    rcases mul_eq_zero.1 h2 with h | h
    · exact absurd h hS.ne'
    · linarith
  rw [← this]
  exact hs

/-- The doubling rule gives gamma. If the call price `C S K` is twice continuously
differentiable for positive share price and strike, and scaling both by `a > 0` scales the
price by `a`, then `S^2 Γ = K^2 ∂²C/∂K²`: the share-price curvature (gamma) times `S^2`
equals the strike curvature times `K^2`. -/
theorem heston_gamma_eq_strike_curvature
    (C : ℝ → ℝ → ℝ)
    (hhom : ∀ a s k : ℝ, 0 < a → 0 < s → 0 < k → C (a * s) (a * k) = a * C s k)
    (hsmooth : ContDiffOn ℝ 2 (fun p : ℝ × ℝ => C p.1 p.2) {p | 0 < p.1 ∧ 0 < p.2})
    (S K : ℝ) (hS : 0 < S) (hK : 0 < K) :
    S ^ 2 * deriv (fun s => deriv (fun s' => C s' K) s) S
      = K ^ 2 * deriv (fun k => deriv (fun k' => C S k') k) K := by
  set g : ℝ → ℝ := fun x => C 1 x with hgdef
  have hg : ContDiffOn ℝ 2 g (Set.Ioi 0) := by
    have hpair : ContDiffOn ℝ 2 (fun x : ℝ => ((1 : ℝ), x)) (Set.Ioi 0) :=
      (contDiff_const.prodMk contDiff_id).contDiffOn
    have := hsmooth.comp hpair (fun x hx => ⟨one_pos, hx⟩)
    simpa [Function.comp_def] using this
  have hg1 : ∀ x : ℝ, 0 < x → HasDerivAt g (deriv g x) x := by
    intro x hx
    have := (hg.differentiableOn (by norm_num)) x hx
    exact (this.differentiableAt (Ioi_mem_nhds hx)).hasDerivAt
  have hg' : ContDiffOn ℝ 1 (deriv g) (Set.Ioi 0) :=
    hg.deriv_of_isOpen isOpen_Ioi (by norm_num)
  have hg2 : ∀ x : ℝ, 0 < x → HasDerivAt (deriv g) (deriv (deriv g) x) x := by
    intro x hx
    have := (hg'.differentiableOn (by norm_num)) x hx
    exact (this.differentiableAt (Ioi_mem_nhds hx)).hasDerivAt
  have hrep : ∀ s k : ℝ, 0 < s → 0 < k → C s k = s * g (k / s) := by
    intro s k hs hk
    have := hhom s 1 (k / s) hs one_pos (div_pos hk hs)
    rwa [mul_one, mul_div_cancel₀ _ hs.ne'] at this
  -- share-price side
  have hdiv : ∀ s : ℝ, 0 < s → HasDerivAt (fun s' : ℝ => K / s') (-K / s ^ 2) s := by
    intro s hs
    have := (hasDerivAt_inv hs.ne').const_mul K
    convert this using 1
    · funext t; ring
    · ring
  have hD1 : ∀ s : ℝ, 0 < s →
      HasDerivAt (fun s' => C s' K) (g (K / s) - K / s * deriv g (K / s)) s := by
    intro s hs
    have h : HasDerivAt (fun s' => s' * g (K / s'))
        (1 * g (K / s) + s * (deriv g (K / s) * (-K / s ^ 2))) s :=
      (hasDerivAt_id s).mul ((hg1 (K / s) (div_pos hK hs)).comp s (hdiv s hs))
    have h' : HasDerivAt (fun s' => C s' K)
        (1 * g (K / s) + s * (deriv g (K / s) * (-K / s ^ 2))) s := by
      apply h.congr_of_eventuallyEq
      filter_upwards [Ioi_mem_nhds hs] with t ht
      exact hrep t K ht hK
    convert h' using 1
    field_simp
    ring
  have hSS : deriv (fun s => deriv (fun s' => C s' K) s) S
      = K ^ 2 / S ^ 3 * deriv (deriv g) (K / S) := by
    have hev : (fun s => deriv (fun s' => C s' K) s)
        =ᶠ[nhds S] fun s => g (K / s) - K / s * deriv g (K / s) := by
      filter_upwards [Ioi_mem_nhds hS] with s hs
      exact (hD1 s hs).deriv
    rw [hev.deriv_eq]
    have hA := (hg1 (K / S) (div_pos hK hS)).comp S (hdiv S hS)
    have hB := (hdiv S hS).mul ((hg2 (K / S) (div_pos hK hS)).comp S (hdiv S hS))
    have h : HasDerivAt (fun s => g (K / s) - K / s * deriv g (K / s))
        (deriv g (K / S) * (-K / S ^ 2) -
          (-K / S ^ 2 * deriv g (K / S) + K / S * (deriv (deriv g) (K / S) * (-K / S ^ 2)))) S :=
      hA.sub hB
    rw [h.deriv]
    field_simp
    ring
  -- strike side
  have hdivk : ∀ k : ℝ, HasDerivAt (fun k' : ℝ => k' / S) (1 / S) k := by
    intro k
    simpa using (hasDerivAt_id k).div_const S
  have hD2 : ∀ k : ℝ, 0 < k → HasDerivAt (fun k' => C S k') (deriv g (k / S)) k := by
    intro k hk
    have h := ((hg1 (k / S) (div_pos hk hS)).comp k (hdivk k)).const_mul S
    have h' : HasDerivAt (fun k' => C S k') (S * (deriv g (k / S) * (1 / S))) k := by
      apply h.congr_of_eventuallyEq
      filter_upwards [Ioi_mem_nhds hk] with t ht
      simp only [Function.comp_apply]
      exact hrep S t hS ht
    convert h' using 1
    field_simp
  have hKK : deriv (fun k => deriv (fun k' => C S k') k) K
      = deriv (deriv g) (K / S) / S := by
    have hev : (fun k => deriv (fun k' => C S k') k)
        =ᶠ[nhds K] fun k => deriv g (k / S) := by
      filter_upwards [Ioi_mem_nhds hK] with k hk
      exact (hD2 k hk).deriv
    rw [hev.deriv_eq]
    have h := (hg2 (K / S) (div_pos hK hS)).comp K (hdivk K)
    rw [show (fun k => deriv g (k / S)) = (deriv g ∘ fun k' => k' / S) from rfl, h.deriv]
    field_simp
  rw [hSS, hKK]
  field_simp

/-- Gamma's integrand is the fingerprint and its wave alone. The share price enters the
Lewis integrand through the factor `F^(1/2 + iu)` with `F = c S` a fixed positive multiple
of `S`. Differentiating that factor twice in `S` multiplies it by
`(1/2 + iu)(-1/2 + iu)/S^2 = -(u^2 + 1/4)/S^2`, which cancels the integral's denominator. -/
theorem heston_gamma_factor_second_deriv (c S u : ℝ) (hc : 0 < c) (hS : 0 < S) :
    deriv (deriv (fun s : ℝ => (((c * s : ℝ)) : ℂ) ^ ((1 / 2 : ℂ) + u * I))) S
      = -(((u : ℂ) ^ 2 + 1 / 4) / (S : ℂ) ^ 2)
          * (((c * S : ℝ)) : ℂ) ^ ((1 / 2 : ℂ) + u * I) := by
  set w : ℂ := (1 / 2 : ℂ) + u * I with hw
  have hev : deriv (fun s : ℝ => (((c * s : ℝ)) : ℂ) ^ w)
      =ᶠ[nhds S] fun s => w * (((c * s : ℝ)) : ℂ) ^ (w - 1) * c := by
    filter_upwards [Ioi_mem_nhds hS] with s hs
    exact (heston_cpow_scaled_hasDerivAt c s w hc hs).deriv
  rw [hev.deriv_eq]
  have h1 := ((heston_cpow_scaled_hasDerivAt c S (w - 1) hc hS).const_mul w).mul_const (c : ℂ)
  rw [h1.deriv]
  have hne : (((c * S : ℝ)) : ℂ) ≠ 0 := by
    exact_mod_cast (mul_pos hc hS).ne'
  have hS0 : (S : ℂ) ≠ 0 := by exact_mod_cast hS.ne'
  have hc0 : (c : ℂ) ≠ 0 := by exact_mod_cast hc.ne'
  have hsub : (((c * S : ℝ)) : ℂ) ^ (w - 1 - 1) = (((c * S : ℝ)) : ℂ) ^ w / (((c * S : ℝ)) : ℂ) ^ (2:ℕ) := by
    rw [show w - 1 - 1 = w - (2:ℕ) by push_cast; ring, cpow_sub _ _ hne, cpow_natCast]
  rw [hsub]
  have hww : w * (w - 1) = -((u : ℂ) ^ 2 + 1 / 4) := by
    rw [hw]; ring_nf; rw [I_sq]; ring
  set X : ℂ := (((c * S : ℝ)) : ℂ) ^ w
  have hX2 : (((c * S : ℝ)) : ℂ) ^ (2:ℕ) = (c:ℂ)^2 * (S:ℂ)^2 := by push_cast; ring
  rw [hX2, show w * ((w - 1) * (X / ((c:ℂ)^2 * (S:ℂ)^2)) * (c:ℂ)) * (c:ℂ)
      = (w * (w - 1)) * (X * (c:ℂ)^2 / ((c:ℂ)^2 * (S:ℂ)^2)) by ring, hww]
  field_simp

-- The card's whole-number count: 3 expiries times 7 strikes is 21 quotes.
example : 3 * 7 = 21 := by norm_num

#print axioms heston_delta_eq_discounted_P1
#print axioms heston_gamma_eq_strike_curvature
#print axioms heston_gamma_factor_second_deriv
