# to install the library
using Pkg; Pkg.add("Agents")
using Agents, Random

# Rules definition.
# The rules of Conway's game of life are defined based on four numbers: Death, Survival, Reproduction, Overpopulation, grouped as (D, S, R, O) 
# Cells die if the number of their living neighbors is <D or >O, survive if the number of their living neighbors is ≤S, come to life if their living 
# neighbors are ≥R and ≤O.
# D = 2: Una célula viva morirá si tiene menos de 2 vecinos vivos.
# S = 3: Una célula viva sobrevivirá si tiene 2 o 3 vecinos vivos (ya que ≤3 incluye 2 y 3).
# R = 3: Una célula muerta nacerá si tiene exactamente 3 vecinos vivos.
#O = 3: Una célula viva morirá si tiene más de 3 vecinos vivos.
rules = (2, 3, 3, 3) # (D, S, R, O)

# El agente automaton representa una celula en la cuadricula 2D del automata celular
@agent struct Automaton(GridAgent{2}) end

# The following function builds a 2D cellular automaton given some rules. dims is a tuple of integers determining the width and height of the grid environment. 
# metric specifies how to measure distances in the space, and in our example it actually decides whether cells connect to their diagonal neighbors or not. 
#  :chebyshev includes diagonal, :manhattan does not.
# Initially the cells are dead. 
function build_model(rules::Tuple;
        alive_probability = 0.2,
        dims = (200, 200), metric = :chebyshev, seed = 1342
        # 100 x 100 la cuadricula, metric para medir distancias, seed genera numeros aleatorios para cada celular y si ese numero es mayor que alive_probability 
        # entonces la celula esta viva y si es menor esta muerta
  )
    space = GridSpaceSingle(dims; metric) # Se crea el espacio de la cuadricula 2D con las dimensiones dadas y como se mediran las distancias
    properties = Dict(:rules => rules) # Se crea un diccionario asi => Dict(:rules => (2, 3, 3, 3))
    status = zeros(Bool, dims) # Se crea un matriz/cuadricula de 100x100 llenos de false
    # 100x100 Matrix of Bool:
    # false  false  false  ...  false
    # false  false  false  ...  false
    # false  false  false  ...  false
    # ...   ...    ...   ...  ...
    # false  false  false  ...  false
    new_status = zeros(Bool, dims) # Se crea un matriz/cuadricula de 100x100 llenos de false igual que status 

    properties = (; rules, status, new_status) # Ahora properties contrine(:rules => (2, 3, 3, 3), :status => status, :new_status => new_status)
    # StandardABM acepta varios argumentos, pero los mas importantes son el tipo de agente y el espacio en el que se moveran los agentes.
    # y asi crea el modelo de automata celular
    model = StandardABM(
        Automaton, # Tipo de agente
        space; # Espacio de la cuadricula
        properties, # Propiedades del modelo
        model_step! = game_of_life_step!, # Funcion que se ejecutara en cada paso de la simulacion para actualizar el estado del modelo
        # model_step es una funcion que se llamará en cada paso de la simulación. El ! es para indicar que la función modificará el estado del modelo.
        # game_of_life_step! esta funcion va actualizar el estado del modelo en cada paso de la simulacion
        rng = MersenneTwister(seed), # Generador de numeros aleatorios
        container = Vector # El tipo de contenedor que se usará para almacenar los agentes va a ser un vector
    )
    # Aqui lo que hace es coloca true o false en la cuadricula dependiendo del seed en cada celular
    for pos in positions(model)
        if rand(abmrng(model)) < alive_probability
            status[pos...] = true
        end
    end
    return model
end

# En cada paso de la simulación, cada célula se actualiza según las reglas del juego de la vida de Conway.
function game_of_life_step!(model)
    # First, get the new statuses
    new_status = model.new_status # Se obtiene el nuevo estado del modelo
    status = model.status # Se obtiene el estado actual del modelo
    # @inbounds es omite la verificación de límites de matriz en tiempo de ejecución para que el código se ejecute más rápido
    # siempre y cuando se garantice que no se accederá a elementos fuera de los límites de la matriz.
    @inbounds for pos in positions(model) # Se recorre cada posicion de la cuadricula
        n = alive_neighbors(pos, model) # alive_neighbors cuenta el número de células vecinas vivas

        # Una célula viva sobrevivirá si tiene 2 o 3 vecinos vivos (ya que ≤3 incluye 2 y 3).
        if status[pos...] == true && model.rules[1] ≤ n ≤ model.rules[4]
            new_status[pos...] = true
        # Una célula muerta nacerá si tiene exactamente 3 vecinos vivos
        elseif status[pos...] == false && model.rules[3] ≤ n ≤ model.rules[4]
            new_status[pos...] = true
         # Una célula viva morirá si tiene más de 3 vecinos vivos o si tiene menos de 2 vecinos vivos.
        else
            new_status[pos...] = false
        end
    end
    # Aqui se copian ambos estados para reiniciar en cada paso
    status .= new_status
    return
end

# pos es la posición de la célula en la cuadrícula/matriz
function alive_neighbors(pos, model) # cuenta el número de células vecinas vivas
    c = 0
    # @inbounds for near_pos in nearby_positions((2, 2), model)
    @inbounds for near_pos in nearby_positions(pos, model)
        # Cuenta el número de células vecinas vivas alrededor de la célula en la posición pos
        if model.status[near_pos...] == true
            c += 1
        end
    end
    return c
end


# Finally!
# let's run the whole thing
model = build_model(rules)

# This generates a video of the simulation, and saves it
Pkg.add("CairoMakie")
using CairoMakie

plotkwargs = (
    add_colorbar = true, # Se añade una barra de color para mostrar el rango de colores
    heatarray = :status, # Se utiliza esta linea para obtener el estado de cada celula en la cuadricula y mostrarlo en la grafica
    heatkwargs = (
        colorrange = (0, 1),
        colormap = cgrad([:red, :green]; categorical = true), # Se coloca true para que sean colores categoricos mientras que false para que sean continuos y se haga como un gradiente
    ),
)

abmvideo(
    "M1. Actividad Conway's Game of Life.mp4",
    model;
    title = "M1. Actividad Conway's Game of Life",
    framerate = 10,
    frames = 60,
    plotkwargs...,
)