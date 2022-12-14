using Snowflake
using Test

@testset "push_pop_gate" begin
    c = QuantumCircuit(qubit_count = 2, bit_count = 0)
    print(c)
    push_gate!(c, [hadamard(1)])
    @test length(c.pipeline) == 1


    push_gate!(c, [control_x(1, 2)])
    @test length(c.pipeline) == 2
    pop_gate!(c)
    @test length(c.pipeline) == 1

    push_gate!(c, control_x(1, 2))
    @test length(c.pipeline) == 2

    plot_histogram(c,100)
    plot_bloch_sphere(c)

    print(c)
end

@testset "print_circuit" begin
    c = QuantumCircuit(qubit_count = 2, bit_count = 0)
    for i = 1:50
        push_gate!(c, [control_x(1, 2)])
    end
    print(c)

    c = QuantumCircuit(qubit_count = 10, bit_count = 0)
    push_gate!(c, [control_x(9, 10)])
    print(c)
end


@testset "bellstate" begin

    Ψ_up = spin_up()
    Ψ_down = spin_down()

    Ψ_p = (1.0 / sqrt(2.0)) * (Ψ_up + Ψ_down)
    Ψ_m = (1.0 / sqrt(2.0)) * (Ψ_up - Ψ_down)
    c = QuantumCircuit(qubit_count = 2, bit_count = 0)
    push_gate!(c, [hadamard(1)])
    push_gate!(c, [control_x(1, 2)])
    ψ = simulate(c)
    @test ψ ≈ 1 / sqrt(2.0) * (kron(Ψ_up, Ψ_up) + kron(Ψ_down, Ψ_down))

    readings = simulate_shots(c, 101)
    @test ("00" in readings)
    @test ("11" in readings)
    @test ~("10" in readings)
    @test ~("01" in readings)
end

@testset "phase_kickback" begin

    Ψ_up = spin_up()
    Ψ_down = spin_down()

    Ψ_p = (1.0 / sqrt(2.0)) * (Ψ_up + Ψ_down)
    Ψ_m = (1.0 / sqrt(2.0)) * (Ψ_up - Ψ_down)


    c = QuantumCircuit(qubit_count = 2, bit_count = 0)

    push_gate!(c, [hadamard(1), sigma_x(2)])
    push_gate!(c, [hadamard(2)])
    push_gate!(c, [control_x(1, 2)])
    ψ = simulate(c)

    @test ψ ≈ kron(Ψ_m, Ψ_m)
end

@testset "throw_if_gate_outside_circuit" begin
    c = QuantumCircuit(qubit_count = 2, bit_count = 0)
    @test_throws DomainError push_gate!(c, control_x(1, 3))
end

@testset "get_gate_counts" begin
    c = QuantumCircuit(qubit_count = 2, bit_count = 0)
    push_gate!(c, [sigma_x(1), sigma_x(2)])
    push_gate!(c, control_x(1, 2))
    push_gate!(c, sigma_x(2))
    gate_counts = get_gate_counts(c)
    @test gate_counts == Dict("cx"=>1, "x"=>3)

    num_gates = get_num_gates(c)
    @test num_gates == 4

    depth = get_depth(c)
    @test depth == 3
end
