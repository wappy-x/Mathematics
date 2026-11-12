-- Spectral methods: for a continuous periodic start whose Fourier coefficients have a finite total size, the FFT's computed coefficient of mode k is the sum of the exact coefficients of the modes k + mN, the spectral heat solve on N points is off at every grid point by at most twice the total size of the modes with |k| ≥ N/2, and each coefficient of a function with a continuous derivative is that derivative's coefficient divided by i q_k.
import Mathlib.Analysis.Fourier.AddCircle
import Mathlib.Data.Nat.Log
import Mathlib.Data.Int.Interval
import Mathlib.Tactic.NormNum

-- `open scoped Real` makes `π` mean `Real.pi`. The earlier draft lacked it, so `π` became a
-- free variable that could be 0, and all three statements were false.
open Complex
open scoped Real

theorem fft_series_hasSum (L : ℝ) (hL : 0 < L) (f : ℝ → ℂ) (hper : Function.Periodic f L)
    (hcont : Continuous f) (hsum : Summable fun n : ℤ => ‖fourierCoeffOn hL f n‖)
    (x : ℝ) (hx : x ∈ Set.Ico 0 L) :
    HasSum (fun n : ℤ => fourierCoeffOn hL f n * Complex.exp (2 * π * I * n * x / L)) (f x) := by
  have hT : Fact (0 < L - 0) := ⟨by linarith⟩
  have h0 : f 0 = f (0 + (L - 0)) := by
    have := hper 0; simp only [zero_add] at this; simp [this]
  let F : C(AddCircle (L - 0), ℂ) :=
    ⟨AddCircle.liftIoc (L - 0) 0 f, AddCircle.liftIoc_continuous h0 hcont.continuousOn⟩
  have hc : ∀ n, fourierCoeff F n = fourierCoeffOn hL f n := fun n => rfl
  have hs : Summable (fourierCoeff F) := by
    have : fourierCoeff F = fourierCoeffOn hL f := funext hc
    rw [this]; exact hsum.of_norm
  have key := has_pointwise_sum_fourier_series_of_summable hs (x : AddCircle (L - 0))
  have hF : F (x : AddCircle (L - 0)) = f x := by
    show AddCircle.liftIoc (L - 0) 0 f x = f x
    rw [AddCircle.liftIoc_eq_liftIco h0, AddCircle.liftIco_coe_apply]
    simpa using hx
  rw [hF] at key
  convert key using 2 with n
  rw [hc, fourier_coe_apply, smul_eq_mul]
  simp

theorem fft_grid_sum (N : ℕ) (hN : 0 < N) (d : ℤ) :
    (1 / (N : ℂ)) * ∑ i : Fin N, Complex.exp (2 * π * I * d * ((i : ℕ) : ℂ) / N) =
      if (N : ℤ) ∣ d then 1 else 0 := by
  have hN' : (N : ℂ) ≠ 0 := by exact_mod_cast hN.ne'
  have hpi : (2 * π * I : ℂ) ≠ 0 := by simp [Real.pi_ne_zero, Complex.I_ne_zero]
  set ω := Complex.exp (2 * π * I * d / N) with hω
  have hpow : ∀ i : ℕ, Complex.exp (2 * π * I * d * (i : ℂ) / N) = ω ^ i := by
    intro i; rw [hω, ← Complex.exp_nat_mul]; congr 1; ring
  rw [Fin.sum_univ_eq_sum_range (fun i : ℕ => Complex.exp (2 * π * I * d * (i : ℂ) / N)) N]
  simp_rw [hpow]
  split_ifs with h
  · obtain ⟨e, he⟩ := h
    have : ω = 1 := by
      rw [hω, he]; push_cast
      rw [show 2 * π * I * (N * e) / N = (e : ℂ) * (2 * π * I) by field_simp]
      exact Complex.exp_int_mul_two_pi_mul_I e
    simp [this]
    field_simp
  · have h1 : ω ≠ 1 := by
      intro h1
      rw [hω, Complex.exp_eq_one_iff] at h1
      obtain ⟨m, hm⟩ := h1
      apply h
      refine ⟨m, ?_⟩
      rw [div_eq_iff hN'] at hm
      have h3 : (2 * π * I) * (d : ℂ) = (2 * π * I) * ((N : ℂ) * m) := by
        linear_combination hm
      have h4 := mul_left_cancel₀ hpi h3
      exact_mod_cast h4
    have h2 : ω ^ N = 1 := by
      rw [hω, ← Complex.exp_nat_mul,
        show (N : ℂ) * (2 * π * I * d / N) = (d : ℂ) * (2 * π * I) by field_simp]
      exact Complex.exp_int_mul_two_pi_mul_I d
    rw [geom_sum_eq h1, h2]; simp

theorem fft_alias_hasSum (L : ℝ) (hL : 0 < L)
    (f : ℝ → ℂ) (hper : Function.Periodic f L) (hcont : Continuous f)
    (hsum : Summable fun n : ℤ => ‖fourierCoeffOn hL f n‖)
    (N : ℕ) (hN : 0 < N) (k : ℤ) :
    HasSum (fun n : ℤ => if (N : ℤ) ∣ n - k then fourierCoeffOn hL f n else 0)
      ((1 / (N : ℂ)) * ∑ i : Fin N,
        f ((i : ℕ) * L / N) * Complex.exp (-(I * (2 * π * k / L) * ((i : ℕ) * L / N)))) := by
  have hN' : (N : ℂ) ≠ 0 := by exact_mod_cast hN.ne'
  have hL' : (L : ℂ) ≠ 0 := by exact_mod_cast hL.ne'
  have hx : ∀ i : Fin N, ((i : ℕ) * L / N : ℝ) ∈ Set.Ico 0 L := by
    intro i
    have hNr : (0 : ℝ) < N := by exact_mod_cast hN
    have hi : ((i : ℕ) : ℝ) < N := by exact_mod_cast i.isLt
    constructor
    · positivity
    · rw [div_lt_iff₀ hNr]; nlinarith
  have h : ∀ i ∈ (Finset.univ : Finset (Fin N)), HasSum
      (fun n : ℤ => fourierCoeffOn hL f n *
        Complex.exp (2 * π * I * n * (((i : ℕ) * L / N : ℝ) : ℂ) / L) *
        Complex.exp (-(I * (2 * π * k / L) * ((i : ℕ) * L / N))))
      (f ((i : ℕ) * L / N) * Complex.exp (-(I * (2 * π * k / L) * ((i : ℕ) * L / N)))) :=
    fun i _ => (fft_series_hasSum L hL f hper hcont hsum _ (hx i)).mul_right _
  have key := (hasSum_sum h).mul_left (1 / (N : ℂ))
  convert key using 1
  funext n
  have hterm : ∀ i : Fin N, fourierCoeffOn hL f n *
        Complex.exp (2 * π * I * n * (((i : ℕ) * L / N : ℝ) : ℂ) / L) *
        Complex.exp (-(I * (2 * π * k / L) * ((i : ℕ) * L / N))) =
      fourierCoeffOn hL f n * Complex.exp (2 * π * I * ((n - k : ℤ) : ℂ) * ((i : ℕ) : ℂ) / N) := by
    intro i
    rw [mul_assoc, ← Complex.exp_add]
    congr 2
    push_cast
    field_simp
    ring
  simp_rw [hterm, ← Finset.mul_sum]
  rw [mul_left_comm, fft_grid_sum N hN]
  split_ifs <;> simp

#print axioms fft_series_hasSum
#print axioms fft_grid_sum
#print axioms fft_alias_hasSum

/-- **The spectral heat solve is off by at most twice the fast modes.** Let the ring be L > 0
metres round, and let the start f be continuous and periodic, f(x + L) = f(x), with exact
Fourier coefficients c_k = (1/L) ∫₀ᴸ f(x) e^(−i q_k x) dx, q_k = 2πk/L, whose sizes |c_k| have a
finite total. Take an even number N of grid points x_j = jL/N, the computed coefficients
ĉ_k = (1/N) ∑_j f(x_j) e^(−i q_k x_j), a diffusivity α ≥ 0, a time t ≥ 0 and the fade factors
g_k = e^(−α q_k² t). The spectral solution at grid point x_j is
u_j(t) = ∑ ĉ_k g_k e^(i q_k x_j) over −N/2 < k ≤ N/2, and the exact series is
u(x_j, t) = ∑ c_k g_k e^(i q_k x_j) over every whole number k. Then
|u_j(t) − u(x_j, t)| ≤ E_N = 2 ∑ |c_k| over |k| ≥ N/2. -/
theorem spectral_heat_error_le_twice_fast_modes
    (L α t : ℝ) (hL : 0 < L) (hα : 0 ≤ α) (ht : 0 ≤ t)
    (f : ℝ → ℂ) (hper : Function.Periodic f L) (hcont : Continuous f)
    (hsum : Summable fun n : ℤ => ‖fourierCoeffOn hL f n‖)
    (N : ℕ) (hEven : Even N) (j : Fin N) :
    let c : ℤ → ℂ := fourierCoeffOn hL f
    let q : ℤ → ℝ := fun k => 2 * π * k / L
    let x : ℕ → ℝ := fun i => i * L / N
    let chat : ℤ → ℂ := fun k =>
      (1 / (N : ℂ)) * ∑ i : Fin N, f (x i) * Complex.exp (-(I * q k * x i))
    let g : ℤ → ℝ := fun k => Real.exp (-α * q k ^ 2 * t)
    let uSpectral : ℂ := ∑ k ∈ Finset.Ioc (-((N : ℤ) / 2)) ((N : ℤ) / 2),
      chat k * g k * Complex.exp (I * q k * x j)
    let uExact : ℂ := ∑' n : ℤ, c n * g n * Complex.exp (I * q n * x j)
    ‖uSpectral - uExact‖ ≤ 2 * ∑' n : ℤ, if (N : ℤ) / 2 ≤ |n| then ‖c n‖ else 0 := by
  intro c q x chat g uSpectral uExact
  have hN : 0 < N := Nat.pos_of_ne_zero (fun h => by subst h; exact j.elim0)
  obtain ⟨r0, hr0⟩ := hEven
  set M : ℤ := (N : ℤ) / 2 with hM
  have hNM : (N : ℤ) = 2 * M := by omega
  have hMpos : 0 < M := by omega
  set B : Finset ℤ := Finset.Ioc (-M) M with hB
  -- the folded mode
  let r : ℤ → ℤ := fun n => n - N * ((n + M - 1) / N)
  have hrB : ∀ n, r n ∈ B := by
    intro n
    have h1 := Int.emod_add_mul_ediv (n + M - 1) N
    have h2 := Int.emod_nonneg (n + M - 1) (by omega : (N : ℤ) ≠ 0)
    have h3 := Int.emod_lt_of_pos (n + M - 1) (by omega : (0 : ℤ) < N)
    simp only [r, hB, Finset.mem_Ioc]
    generalize (n + M - 1) % N = e at h1 h2 h3
    generalize (N : ℤ) * ((n + M - 1) / N) = Q at h1 ⊢
    omega
  have hrdvd : ∀ n, (N : ℤ) ∣ n - r n := fun n => ⟨(n + M - 1) / N, by simp only [r]; ring⟩
  have huniq : ∀ a ∈ B, ∀ b ∈ B, (N : ℤ) ∣ a - b → a = b := by
    intro a ha b hb hab
    simp only [hB, Finset.mem_Ioc] at ha hb
    have := Int.eq_zero_of_abs_lt_dvd hab (by rw [abs_lt]; constructor <;> omega)
    omega
  have hiff : ∀ n, ∀ k ∈ B, (N : ℤ) ∣ n - k ↔ r n = k := by
    intro n k hk
    constructor
    · intro h
      apply huniq _ (hrB n) _ hk
      have := dvd_sub h (hrdvd n)
      convert this using 1; ring
    · rintro rfl; exact hrdvd n
  have hrself : ∀ n ∈ B, r n = n := fun n hn => (hiff n n hn).1 (by simp)
  -- weights
  let w : ℤ → ℂ := fun n => (g n : ℂ) * Complex.exp (I * q n * x j)
  have hw : ∀ n, ‖w n‖ ≤ 1 := by
    intro n
    simp only [w, norm_mul]
    rw [show I * ((q n : ℝ) : ℂ) * ((x j : ℝ) : ℂ) = ((q n * x j : ℝ) : ℂ) * I by push_cast; ring,
      Complex.norm_exp_ofReal_mul_I, mul_one, Complex.norm_real, Real.norm_eq_abs,
      abs_of_pos (Real.exp_pos _)]
    apply Real.exp_le_one_iff.mpr
    have : 0 ≤ α * q n ^ 2 * t := by positivity
    linarith
  -- Step A
  have hA : ∀ k, HasSum (fun n : ℤ => if (N : ℤ) ∣ n - k then c n else 0) (chat k) := by
    intro k
    have := fft_alias_hasSum L hL f hper hcont hsum N hN k
    convert this using 1
    simp only [chat, q, x]
    push_cast
    rfl
  -- Step B
  have hBsum : HasSum (fun n => c n * w (r n)) (∑ k ∈ B, chat k * w k) := by
    have := hasSum_sum (fun k (_ : k ∈ B) => (hA k).mul_right (w k))
    convert this using 1
    funext n
    rw [Finset.sum_congr rfl (g := fun k => if r n = k then c n * w k else 0)]
    · rw [Finset.sum_ite_eq, ite_eq_left (hrB n)]
    · intro k hk
      by_cases h : r n = k
      · rw [ite_eq_left h, ite_eq_left ((hiff n k hk).2 h)]
      · rw [ite_eq_right h, ite_eq_right (fun h' => h ((hiff n k hk).1 h')), zero_mul]
  have hSpec : uSpectral = ∑ k ∈ B, chat k * w k := by
    simp only [uSpectral, w, hB, hM]
    refine Finset.sum_congr rfl (fun k _ => by ring)
  have hcs : Summable fun n => c n * w n :=
    Summable.of_norm_bounded hsum (fun n => by
      rw [norm_mul]; exact mul_le_of_le_one_right (norm_nonneg _) (hw n))
  have hExact : uExact = ∑' n, c n * w n := by
    simp only [uExact, w]
    exact tsum_congr (fun n => by ring)
  have hdiff : HasSum (fun n => c n * w (r n) - c n * w n) (uSpectral - uExact) := by
    rw [hSpec, hExact]; exact hBsum.sub hcs.hasSum
  -- bound
  have hbound : ∀ n, ‖c n * w (r n) - c n * w n‖ ≤
      2 * (if M ≤ |n| then ‖c n‖ else 0) := by
    intro n
    by_cases hn : n ∈ B
    · rw [hrself n hn, sub_self, norm_zero]
      have : 0 ≤ (if M ≤ |n| then ‖c n‖ else 0) := by split_ifs <;> simp
      linarith
    · have hMn : M ≤ |n| := by
        simp only [hB, Finset.mem_Ioc, not_and_or, not_lt, not_le] at hn
        rw [le_abs]
        omega
      rw [ite_eq_left hMn, ← mul_sub, norm_mul]
      have : ‖w (r n) - w n‖ ≤ 2 := by
        calc ‖w (r n) - w n‖ ≤ ‖w (r n)‖ + ‖w n‖ := norm_sub_le _ _
          _ ≤ 1 + 1 := add_le_add (hw _) (hw _)
          _ = 2 := by norm_num
      nlinarith [norm_nonneg (c n)]
  have hfast : Summable fun n : ℤ => if M ≤ |n| then ‖c n‖ else 0 :=
    Summable.of_nonneg_of_le (fun n => by split_ifs <;> positivity)
      (fun n => by split_ifs <;> first | exact le_rfl | exact norm_nonneg _) hsum
  have hnormsum : Summable fun n => ‖c n * w (r n) - c n * w n‖ :=
    Summable.of_nonneg_of_le (fun n => norm_nonneg _) hbound (hfast.mul_left 2)
  rw [← hdiff.tsum_eq]
  calc ‖∑' n, (c n * w (r n) - c n * w n)‖ ≤ ∑' n, ‖c n * w (r n) - c n * w n‖ :=
        norm_tsum_le_tsum_norm hnormsum
    _ ≤ ∑' n, 2 * (if M ≤ |n| then ‖c n‖ else 0) :=
        Summable.tsum_le_tsum hbound hnormsum (hfast.mul_left 2)
    _ = 2 * ∑' n : ℤ, (if M ≤ |n| then ‖c n‖ else 0) := tsum_mul_left

/-- **Aliasing: the FFT files every fast mode under a slow one.** Let the ring be L > 0 metres
round, and let f be continuous and periodic, f(x + L) = f(x), with exact Fourier coefficients
c_k whose sizes have a finite total. On N ≥ 1 evenly spaced points x_j = jL/N the computed
coefficient ĉ_k = (1/N) ∑_j f(x_j) e^(−i q_k x_j), q_k = 2πk/L, is the sum of the exact
coefficients of all the modes N apart from k: ĉ_k = ∑ c_(k + mN) over every whole number m. -/
theorem computed_coeff_eq_sum_of_aliases
    (L : ℝ) (hL : 0 < L)
    (f : ℝ → ℂ) (hper : Function.Periodic f L) (hcont : Continuous f)
    (hsum : Summable fun n : ℤ => ‖fourierCoeffOn hL f n‖)
    (N : ℕ) (hN : 0 < N) (k : ℤ) :
    (1 / (N : ℂ)) * ∑ i : Fin N,
        f ((i : ℕ) * L / N) * Complex.exp (-(I * (2 * π * k / L) * ((i : ℕ) * L / N))) =
      ∑' m : ℤ, fourierCoeffOn hL f (k + m * N) := by
  have key := fft_alias_hasSum L hL f hper hcont hsum N hN k
  have hinj : Function.Injective (fun m : ℤ => k + m * N) := by
    intro a b hab
    have hN0 : (N : ℤ) ≠ 0 := by exact_mod_cast hN.ne'
    have : a * N = b * N := by simpa using hab
    exact mul_right_cancel₀ hN0 this
  rw [← hinj.hasSum_iff] at key
  · refine (HasSum.tsum_eq ?_).symm
    convert key using 1
    funext m
    simp
  · intro n hn
    split_ifs with h
    · obtain ⟨m, hm⟩ := h
      exact absurd ⟨m, by simp only; linarith⟩ hn
    · rfl

/-- **Each continuous derivative divides the coefficient by i q_k.** Let the ring be L > 0
metres round, and let f be periodic, f(x + L) = f(x), with a slope f'(x) at every point that is
continuous round the ring. Then for every mode k ≠ 0, with q_k = 2πk/L, the exact coefficient of
f is the coefficient of f' divided by i q_k: c_k[f] = c_k[f'] / (i q_k). -/
theorem fourier_coeff_eq_deriv_coeff_div
    (L : ℝ) (hL : 0 < L)
    (f f' : ℝ → ℂ) (hper : Function.Periodic f L)
    (hderiv : ∀ x, HasDerivAt f (f' x) x) (hcont : Continuous f')
    (k : ℤ) (hk : k ≠ 0) :
    fourierCoeffOn hL f k = fourierCoeffOn hL f' k / (I * (2 * π * k / L)) := by
  rw [fourierCoeffOn_of_hasDerivAt hL hk (fun x _ => hderiv x) (hcont.intervalIntegrable _ _)]
  have h1 : f L - f 0 = 0 := by have := hper 0; simp only [zero_add] at this; rw [this, sub_self]
  rw [h1]
  have hL' : (L : ℂ) ≠ 0 := by exact_mod_cast hL.ne'
  have hk' : (k : ℂ) ≠ 0 := by exact_mod_cast hk
  have hpi : (π : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
  push_cast
  field_simp
  ring

-- Cost at N = 32: the FFT's (N/2) log2 N = 16 · 5 = 80 complex multiplications,
-- against N^2 = 1024 for the direct sum.
example : (32 / 2) * Nat.log 2 32 = 80 ∧ 32 * 32 = 1024 := by decide
-- The band the 32-point grid keeps, −16 < k ≤ 16, that is k from −15 to 16, holds 32 modes.
example : (Finset.Ioc (-16 : ℤ) 16).card = 32 := by decide
-- At N = 32, FFT slot 31 holds mode 31 − 32 = −1: the two modes differ by a multiple of N.
example : (31 : ℤ) ≡ -1 [ZMOD 32] := by decide
-- The finite-difference comparison: 25 steps of 24 s reach 600 s, and
-- r = αΔt/h² = (12/1000000) · 24 · 32² = 294912/1000000.
example : 25 * 24 = 600 ∧ (12 / 1000000 : ℚ) * 24 * 32 ^ 2 = 294912 / 1000000 := by norm_num

#print axioms spectral_heat_error_le_twice_fast_modes
#print axioms computed_coeff_eq_sum_of_aliases
#print axioms fourier_coeff_eq_deriv_coeff_div
