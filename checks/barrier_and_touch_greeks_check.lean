-- Greeks at the wall: differentiating the mirror price V(S) = G(S) - (H/S)^(2λ) G(H²/S) in spot and in volatility gives exactly the card's delta, gamma and vega lines.
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.SpecialFunctions.Log.Deriv

open Real

theorem barrier_mirror_hasDerivAt (c x : ℝ) (hx : x ≠ 0) :
    HasDerivAt (fun y => c / y) (-(c / x) / x) x := by
  have := (hasDerivAt_inv hx).const_mul c
  convert this using 1
  · funext y; simp [div_eq_mul_inv]
  · field_simp

theorem barrier_weight_hasDerivAt (H p x : ℝ) (hH : 0 < H) (hx : 0 < x) :
    HasDerivAt (fun y => (H / y) ^ p) (-(p * (H / x) ^ p) / x) x := by
  have h1 := (barrier_mirror_hasDerivAt H x hx.ne').rpow_const (p := p)
    (Or.inl (div_pos hH hx).ne')
  convert h1 using 1
  rw [rpow_sub_one (div_pos hH hx).ne']
  field_simp

#print axioms barrier_mirror_hasDerivAt
#print axioms barrier_weight_hasDerivAt

/-- Barrier delta: if the barrier price is the mirror formula
`V(S) = G(S) - w G(m)` with weight `w = (H/S)^(2λ)` and mirror spot `m = H²/S`,
then its delta is the plain delta plus the term from the moving weight plus the
weighted mirror delta: `Δ = G'(S) + 2λ w G(m)/S + w m G'(m)/S`.
Here `lam` stands for the card's `λ`; the identity holds for every real `λ`. -/
theorem barrier_delta_eq_plain_minus_mirror
    (G G' : ℝ → ℝ) (H lam S : ℝ) (hH : 0 < H) (hS : 0 < S)
    (hGS : HasDerivAt G (G' S) S)
    (hGm : HasDerivAt G (G' (H ^ 2 / S)) (H ^ 2 / S)) :
    HasDerivAt (fun x => G x - (H / x) ^ (2 * lam) * G (H ^ 2 / x))
      (G' S + 2 * lam * (H / S) ^ (2 * lam) * G (H ^ 2 / S) / S
        + (H / S) ^ (2 * lam) * (H ^ 2 / S) * G' (H ^ 2 / S) / S) S := by
  have hw := barrier_weight_hasDerivAt H (2 * lam) S hH hS
  have hm : HasDerivAt (fun x => G (H ^ 2 / x)) (G' (H ^ 2 / S) * (-(H ^ 2 / S) / S)) S :=
    hGm.comp S (barrier_mirror_hasDerivAt (H ^ 2) S hS.ne')
  convert hGS.sub (hw.mul hm) using 1
  ring

/-- Barrier gamma: differentiating the delta line once more in spot gives
`Γ = G''(S) - 2λ(2λ+1) w G(m)/S² - (4λ+2) w m G'(m)/S² - w m² G''(m)/S²`,
with `w = (H/S)^(2λ)` and `m = H²/S`. -/
theorem barrier_gamma_line
    (G G' G'' : ℝ → ℝ) (H lam S : ℝ) (hH : 0 < H) (hS : 0 < S)
    (hGS : HasDerivAt G (G' S) S)
    (hGm : HasDerivAt G (G' (H ^ 2 / S)) (H ^ 2 / S))
    (hG'S : HasDerivAt G' (G'' S) S)
    (hG'm : HasDerivAt G' (G'' (H ^ 2 / S)) (H ^ 2 / S)) :
    HasDerivAt
      (fun x => G' x + 2 * lam * (H / x) ^ (2 * lam) * G (H ^ 2 / x) / x
        + (H / x) ^ (2 * lam) * (H ^ 2 / x) * G' (H ^ 2 / x) / x)
      (G'' S - 2 * lam * (2 * lam + 1) * (H / S) ^ (2 * lam) * G (H ^ 2 / S) / S ^ 2
        - (4 * lam + 2) * (H / S) ^ (2 * lam) * (H ^ 2 / S) * G' (H ^ 2 / S) / S ^ 2
        - (H / S) ^ (2 * lam) * (H ^ 2 / S) ^ 2 * G'' (H ^ 2 / S) / S ^ 2) S := by
  have hw := barrier_weight_hasDerivAt H (2 * lam) S hH hS
  have hmm := barrier_mirror_hasDerivAt (H ^ 2) S hS.ne'
  have hm : HasDerivAt (fun x => G (H ^ 2 / x)) (G' (H ^ 2 / S) * (-(H ^ 2 / S) / S)) S :=
    hGm.comp S hmm
  have hm' : HasDerivAt (fun x => G' (H ^ 2 / x)) (G'' (H ^ 2 / S) * (-(H ^ 2 / S) / S)) S :=
    hG'm.comp S hmm
  have t2 : HasDerivAt (fun x => 2 * lam * (H / x) ^ (2 * lam) * G (H ^ 2 / x) / x) _ S :=
    ((hw.const_mul (2 * lam)).mul hm).div (hasDerivAt_id' S) hS.ne'
  have t3 : HasDerivAt (fun x => (H / x) ^ (2 * lam) * (H ^ 2 / x) * G' (H ^ 2 / x) / x) _ S :=
    ((hw.mul hmm).mul hm').div (hasDerivAt_id' S) hS.ne'
  convert (hG'S.add t2).add t3 using 1
  simp only [Pi.mul_apply]
  generalize (H / S) ^ (2 * lam) = w
  field_simp
  ring

/-- Barrier vega: with `λ(σ) = (r_d - r_f - σ²/2)/σ²`, only `G` and the weight
`w = (H/S)^(2λ)` depend on volatility (the mirror spot `H²/S` does not), and
`vega = ∂σ G(S) + 4 ln(H/S)(r_d - r_f)/σ³ · w G(m) - w ∂σ G(m)`.
`G x s` is the cut-off price from spot `x` at volatility `s`. -/
theorem barrier_vega_line
    (G : ℝ → ℝ → ℝ) (H S rd rf σ a b : ℝ) (hH : 0 < H) (hS : 0 < S) (hσ : 0 < σ)
    (hGS : HasDerivAt (fun s => G S s) a σ)
    (hGm : HasDerivAt (fun s => G (H ^ 2 / S) s) b σ) :
    HasDerivAt
      (fun s => G S s - (H / S) ^ (2 * ((rd - rf - s ^ 2 / 2) / s ^ 2)) * G (H ^ 2 / S) s)
      (a + 4 * Real.log (H / S) * (rd - rf) / σ ^ 3
            * (H / S) ^ (2 * ((rd - rf - σ ^ 2 / 2) / σ ^ 2)) * G (H ^ 2 / S) σ
        - (H / S) ^ (2 * ((rd - rf - σ ^ 2 / 2) / σ ^ 2)) * b) σ := by
  have hnum : HasDerivAt (fun s : ℝ => rd - rf - s ^ 2 / 2) (-σ) σ := by
    have := ((hasDerivAt_pow 2 σ).div_const 2).const_sub (rd - rf)
    convert this using 1; simp
  have hden : HasDerivAt (fun s : ℝ => s ^ 2) (2 * σ) σ := by
    simpa using hasDerivAt_pow 2 σ
  have hlam : HasDerivAt (fun s : ℝ => 2 * ((rd - rf - s ^ 2 / 2) / s ^ 2))
      (-(4 * (rd - rf)) / σ ^ 3) σ := by
    have := (hnum.div hden (pow_pos hσ 2).ne').const_mul 2
    convert this using 1
    field_simp
    ring
  have hw := hlam.const_rpow (a := H / S) (div_pos hH hS)
  convert hGS.sub (hw.mul hGm) using 1
  generalize (H / S) ^ (2 * ((rd - rf - σ ^ 2 / 2) / σ ^ 2)) = w
  field_simp
  ring

-- Worked example, exact fractions: r_d = 5/100, r_f = 3/100, σ = 1/10 give λ = 3/2.
example : ((5 : ℚ) / 100 - 3 / 100 - (1 / 10) ^ 2 / 2) / (1 / 10) ^ 2 = 3 / 2 := by norm_num
-- Mirror spot at spot 119/100 with wall 6/5: m = 1.44/1.19 = 144/119.
example : ((6 : ℚ) / 5) ^ 2 / (119 / 100) = 144 / 119 := by norm_num
-- Mirror weight with 2λ = 3: w = (1.20/1.19)^3 = 1728000/1685159.
example : ((6 : ℚ) / 5 / (119 / 100)) ^ 3 = 1728000 / 1685159 := by norm_num

#print axioms barrier_delta_eq_plain_minus_mirror
#print axioms barrier_gamma_line
#print axioms barrier_vega_line
