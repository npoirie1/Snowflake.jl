using Snowflake
using Test


@testset "apply_gate" begin
    ψ_0 = fock(0,2)
    ψ_0_to_update = fock(0,2)
    ψ_1 = fock(1,2)

    apply_gate!(ψ_0_to_update, hadamard(1))
    @test ψ_0_to_update ≈ 1/2^.5*(ψ_0+ψ_1)

    @test_throws DomainError apply_gate!(ψ_0_to_update, hadamard(2))

    non_qubit_ket = Ket([1.0, 0.0, 0.0])
    @test_throws DomainError apply_gate!(non_qubit_ket, hadamard(1))

    transformed_ψ_1 = hadamard(1)*ψ_1
    @test ψ_1 ≈ fock(1,2)
    @test transformed_ψ_1 ≈ 1/2^.5*(ψ_0-ψ_1)
end


@testset "gate_set" begin
    H = hadamard(1)
    @test H.instruction_symbol == "h"
    @test H.display_symbol == ["H"]
    @test get_operator(H) ≈ hadamard()
    @test get_inverse(H) == H

    println(H)

    X = sigma_x(1)
    @test X.instruction_symbol == "x"
    @test X.display_symbol == ["X"]
    @test get_operator(X) ≈ sigma_x()
    @test get_inverse(X) == X

    Y = sigma_y(1)
    @test Y.instruction_symbol == "y"
    @test Y.display_symbol == ["Y"]
    @test get_operator(Y) ≈ sigma_y()
    @test get_inverse(Y) == Y

    Z = sigma_z(1)
    @test Z.instruction_symbol == "z"
    @test Z.display_symbol == ["Z"]
    @test get_operator(Z) ≈ sigma_z()
    @test get_inverse(Z) == Z

    CX = control_x(1, 2)
    @test CX.instruction_symbol == "cx"
    @test get_operator(CX) ≈ control_x()
    @test get_inverse(CX) == CX

    CZ = control_z(1, 2)
    @test CZ.instruction_symbol == "cz"
    @test get_operator(CZ) ≈ control_z()
    @test get_inverse(CZ) == CZ

    CCX = toffoli(1, 2, 3)
    @test CCX.instruction_symbol == "ccx"
    @test CCX*fock(6,8) ≈ fock(7,8)
    @test CCX*fock(2,8) ≈ fock(2,8)
    @test CCX*fock(4,8) ≈ fock(4,8)
    @test toffoli(3, 1, 2)*fock(5,8) ≈ fock(7,8)
    @test get_inverse(CCX) == CCX

    ψ_0 = fock(0,2)
    ψ_1 = fock(1,2)

    S = phase(1)
    @test S.instruction_symbol == "s"
    @test S*ψ_0 ≈ ψ_0
    @test S*ψ_1 ≈ im*ψ_1

    T = pi_8(1)
    @test T.instruction_symbol == "t"
    @test T*ψ_0 ≈ ψ_0
    @test T*ψ_1 ≈ exp(im*pi/4.0)*ψ_1

    x90 = x_90(1)
    @test x90.instruction_symbol == "x_90"
    @test x90*ψ_0 ≈  rotation_x(1, pi/2)*ψ_0
    @test x90*ψ_1 ≈ rotation_x(1, pi/2)*ψ_1

    r = rotation(1, pi/2, pi/2)
    @test r.instruction_symbol == "r"
    @test r*ψ_0 ≈ 1/2^.5*(ψ_0+ψ_1)
    @test r*ψ_1 ≈ 1/2^.5*(-ψ_0+ψ_1)

    println(r)

    rx = rotation_x(1, pi/2)
    @test rx.instruction_symbol == "rx"
    @test rx*ψ_0 ≈ 1/2^.5*(ψ_0-im*ψ_1)
    @test rx*ψ_1 ≈ 1/2^.5*(-im*ψ_0+ψ_1)

    ry = rotation_y(1, -pi/2)
    @test ry.instruction_symbol == "ry"
    @test ry*ψ_0 ≈ 1/2^.5*(ψ_0-ψ_1)
    @test ry*ψ_1 ≈ 1/2^.5*(ψ_0+ψ_1)

    rz = rotation_z(1, pi/2)
    @test rz.instruction_symbol == "rz"
    @test rz*Ket([1/2^.5; 1/2^.5]) ≈ Ket([0.5-im*0.5; 0.5+im*0.5])
    @test rz*ψ_0 ≈ Ket([1/2^.5-im/2^.5; 0])

    p = phase_shift(1, pi/4)
    @test p.instruction_symbol == "p"
    @test p*Ket([1/2^.5; 1/2^.5]) ≈ Ket([1/2^.5, exp(im*pi/4)/2^.5])

    u = universal(1, pi/2, -pi/2, pi/2)
    @test u.instruction_symbol == "u"
    @test u*ψ_0 ≈ 1/2^.5*(ψ_0-im*ψ_1)
    @test u*ψ_1 ≈ 1/2^.5*(-im*ψ_0+ψ_1)
end

@testset "adjoint_gates" begin
    initial_state_10 = Ket([0, 0, 1, 0])
    @test iswap(1, 2)*(iswap_dagger(1, 2)*initial_state_10) ≈ initial_state_10
    @test iswap_dagger(1, 2).instruction_symbol == "iswap_dag"

    initial_state_1 = Ket([0, 1])
    @test pi_8_dagger(1)*(pi_8(1)*initial_state_1) ≈ initial_state_1
    @test pi_8_dagger(1).instruction_symbol == "t_dag"

    @test phase_dagger(1)*(phase(1)*initial_state_1) ≈ initial_state_1
    @test phase_dagger(1).instruction_symbol == "s_dag"
end

@testset "get_inverse" begin
    cnot = control_x(1, 2)
    inverse_cnot = get_inverse(cnot)
    @test get_operator(cnot)*get_operator(inverse_cnot) ≈ kron(eye(), eye())
    @test inverse_cnot.instruction_symbol == "cx"

    rx = rotation_x(1, pi/3)
    inverse_rx = get_inverse(rx)
    @test get_operator(rx)*get_operator(inverse_rx) ≈ eye()
    @test rx.parameters[1] ≈ -inverse_rx.parameters[1]

    ry = rotation_y(1, pi/3)
    inverse_ry = get_inverse(ry)
    @test get_operator(ry)*get_operator(inverse_ry) ≈ eye()
    @test ry.parameters[1] ≈ -inverse_ry.parameters[1]

    rz = rotation_z(1, pi/3)
    inverse_rz = get_inverse(rz)
    @test get_operator(rz)*get_operator(inverse_rz) ≈ eye()
    @test rz.parameters[1] ≈ -inverse_rz.parameters[1]

    p = phase_shift(1, pi/3)
    inverse_p = get_inverse(p)
    @test get_operator(p)*get_operator(inverse_p) ≈ eye()
    @test p.parameters[1] ≈ -inverse_p.parameters[1]

    x_90_gate = x_90(1)
    inverse_x_90 = get_inverse(x_90_gate)
    @test get_operator(x_90_gate)*get_operator(inverse_x_90) ≈ eye()
    @test inverse_x_90.instruction_symbol == "rx"
    @test inverse_x_90.parameters[1] ≈ -pi/2

    s = phase(1)
    inverse_s = get_inverse(s)
    @test get_operator(s)*get_operator(inverse_s) ≈ eye()
    @test inverse_s.instruction_symbol == "s_dag"

    s_dag = phase_dagger(1)
    inverse_s_dag = get_inverse(s_dag)
    @test get_operator(s_dag)*get_operator(inverse_s_dag) ≈ eye()
    @test inverse_s_dag.instruction_symbol == "s"

    t = pi_8(1)
    inverse_t = get_inverse(t)
    @test get_operator(t)*get_operator(inverse_t) ≈ eye()
    @test inverse_t.instruction_symbol == "t_dag"

    t_dag = pi_8_dagger(1)
    inverse_t_dag = get_inverse(t_dag)
    @test get_operator(t_dag)*get_operator(inverse_t_dag) ≈ eye()
    @test inverse_t_dag.instruction_symbol == "t"

    iswap_gate = iswap(1, 2)
    inverse_iswap = get_inverse(iswap_gate)
    @test get_operator(iswap_gate)*get_operator(inverse_iswap) ≈ kron(eye(), eye())
    @test inverse_iswap.instruction_symbol == "iswap_dag"

    iswap_dag = iswap_dagger(1, 2)
    inverse_iswap_dag = get_inverse(iswap_dag)
    @test get_operator(iswap_dag)*get_operator(inverse_iswap_dag) ≈ kron(eye(), eye())
    @test inverse_iswap_dag.instruction_symbol == "iswap"

    r = rotation(1, pi/2, -pi/3)
    inverse_r = get_inverse(r)
    @test get_operator(r)*get_operator(inverse_r) ≈ eye()
    @test inverse_r.parameters[1] ≈ -r.parameters[1]
    @test inverse_r.parameters[2] ≈ r.parameters[2]

    u = universal(1, pi/2, -pi/3, pi/4)
    inverse_u = get_inverse(u)
    @test get_operator(u)*get_operator(inverse_u) ≈ eye()
    @test inverse_u.parameters[1] ≈ -u.parameters[1]
    @test inverse_u.parameters[2] ≈ -u.parameters[3]
    @test inverse_u.parameters[3] ≈ -u.parameters[2]

    struct UnknownGate <: Gate
        instruction_symbol::String
    end
    
    Snowflake.get_operator(gate::UnknownGate) = Operator([1 2; 3 4])

    unknown_gate = UnknownGate("na")
    @test_throws ErrorException get_inverse(unknown_gate)

    struct UnknownHermitianGate <: Gate
        instruction_symbol::String
    end
    
    Snowflake.get_operator(gate::UnknownHermitianGate) = Operator([1 im; -im 1])

    unknown_hermitian_gate = UnknownHermitianGate("na")
    @test get_inverse(unknown_hermitian_gate) == unknown_hermitian_gate
end


@testset "gate_set_exceptions" begin
    @test_throws DomainError control_x(1, 1)
end


@testset "ladder_operators" begin
    ψ_0 = fock(0,2)
    ψ_1 = fock(1,2)

    @test sigma_p()*ψ_1 ≈ ψ_0
    @test sigma_m()*ψ_0 ≈ ψ_1
end


@testset "tensor_product_single_qubit_gate" begin


    Ψ1_0 = fock(0, 2) # |0> for qubit_1
    Ψ1_1 = fock(1, 2) # |1> for qubit_1
    Ψ2_0 = fock(0, 2) # |0> for qubit_2
    Ψ2_1 = fock(1, 2) # |0> for qubit_2
    ψ_init = kron(Ψ1_0, Ψ2_0)

    U = kron(sigma_x(), eye())
    @test U * ψ_init ≈ kron(Ψ1_1, Ψ2_0)

    U = kron(eye(), sigma_x())
    @test U * ψ_init ≈ kron(Ψ1_0, Ψ2_1)

    U = kron(sigma_x(), sigma_x())
    @test U * ψ_init ≈ kron(Ψ1_1, Ψ2_1)

end

@testset "show_gate_without_operator" begin
    struct UnknownGateWithoutOperator <: Gate
        instruction_symbol::String
        target::Vector{Int}
        parameters::Vector{Int}
    end

    unknown_gate = UnknownGateWithoutOperator("na", [1], [])
    println(unknown_gate)
end

@testset "isapprox" begin
    @test control_x(1,2) ≈ control_x(1,2)
    @test !(iswap(1,2) ≈ control_x(1,2))
    @test !(control_x(1,2) ≈ control_x(2,1))
    @test !(rotation(1, pi, pi/2) ≈ rotation(1, 0, pi/2))
end

@testset "copy" begin
    cnot_1_2 = control_x(1, 2)
    target_qubits = [2,1]
    cnot_2_1_copy = copy(cnot_1_2, target_qubits)
    @test cnot_2_1_copy ≈ control_x(2, 1)

    theta = pi
    phi = pi/2
    rotation_1 = rotation(1, theta, phi)
    rotation_1_copy = copy(rotation_1)
    @test rotation_1 ≈ rotation_1_copy
end

@testset "std_gates" begin
    std_gates = ["x", "y", "z", "s", "t", "i", "h", "cx", "cz", "iswap", "ccx"]
    for gate in std_gates
        @test gate in keys(STD_GATES)
    end
end

@testset "pauli_gates" begin
    pauli_gates = ["x", "y", "z", "i"]
    for gate in pauli_gates
        @test gate in keys(STD_GATES)
    end
end
