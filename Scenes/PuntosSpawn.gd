extends Node3D

@export var tipos_basura: Array[PackedScene]
@export var cantidad_a_generar: int = 5

func _ready() -> void:
	call_deferred("generar_basura_aleatoria")

func generar_basura_aleatoria() -> void:
	if tipos_basura.is_empty() or get_child_count() == 0:
		print("Faltan basuras en el Inspector o no hay puntos Marker3D hijos.")
		return

	var lista_puntos: Array = get_children()
	lista_puntos.shuffle()

	var limite: int = mini(cantidad_a_generar, lista_puntos.size())

	for i in range(limite):
		var punto_elegido: Marker3D = lista_puntos[i]
		var escena_basura: PackedScene = tipos_basura.pick_random()
		var basura_instancia = escena_basura.instantiate()
		
		# Agregamos la basura dentro del punto Marker3D
		punto_elegido.call_deferred("add_child", basura_instancia)
