extends Node3D

func initialize(_vector):
	$Dummy/RootNode/Skeleton3D.physical_bones_start_simulation()
	
func _on_ragdoll_timer_timeout():
	queue_free()
