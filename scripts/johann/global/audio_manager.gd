extends Node

func play_audio(index:int):
	for i in range(len(get_children())):
		if index == i:
			if not get_child(i).playing:
				get_child(i).play()
		else:
			get_child(i).stop()
	
